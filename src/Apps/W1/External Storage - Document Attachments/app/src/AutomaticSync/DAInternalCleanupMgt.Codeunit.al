// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExternalStorage.DocumentAttachments;

using Microsoft.Foundation.Attachment;
using System.Environment;
using System.ExternalFileStorage;
using System.Threading;

codeunit 8759 "DA Internal Cleanup Mgt."
{
    Access = Internal;
    InherentPermissions = X;
    InherentEntitlements = X;
    Permissions = tabledata "DA Internal Cleanup Entry" = rimd,
                  tabledata "DA External Storage Setup" = rm,
                  tabledata "Document Attachment" = r,
                  tabledata "Tenant Media" = r;

    procedure StoreUpload(DocumentAttachment: Record "Document Attachment"; var Upload: Record "DA Internal Cleanup Entry")
    var
        Existing: Record "DA Internal Cleanup Entry";
    begin
        Upload."Attachment System ID" := DocumentAttachment.SystemId;
        Upload."Upload Generation" := CreateGuid();
        Upload."External File Path" := DocumentAttachment."External File Path";
        Upload."External Upload Date" := DocumentAttachment."External Upload Date";
        Upload."Source Environment Hash" := DocumentAttachment."Source Environment Hash";
        if not Upload."Provenance Valid" then begin
            Upload.Status := Upload.Status::Blocked;
            Upload.Outcome := 'UploadBindingUnavailable';
        end;
        if Existing.Get(Upload."Attachment System ID") then begin
            Upload.SystemId := Existing.SystemId;
            Upload.Modify();
        end else
            Upload.Insert();
    end;

    procedure RequestCleanup(DocumentAttachment: Record "Document Attachment"; Origin: Enum "DA Internal Cleanup Origin"): Boolean
    var
        Entry: Record "DA Internal Cleanup Entry";
        CurrentAttachment: Record "Document Attachment";
        Setup: Record "DA External Storage Setup";
        ExternalStorageImpl: Codeunit "DA External Storage Impl.";
        Telemetry: Codeunit "DA Feature Telemetry";
        Reason: Text;
    begin
        if DocumentAttachment.IsTemporary() or IsNullGuid(DocumentAttachment.SystemId) then
            exit(false);
        if Origin = Origin::Copy then
            exit(false);

        CurrentAttachment.ReadIsolation(IsolationLevel::UpdLock);
        if not CurrentAttachment.GetBySystemId(DocumentAttachment.SystemId) then
            exit(false);
        Entry.ReadIsolation(IsolationLevel::UpdLock);
        if not Entry.Get(DocumentAttachment.SystemId) then begin
            Entry.Init();
            Entry."Attachment System ID" := DocumentAttachment.SystemId;
            Entry."External File Path" := DocumentAttachment."External File Path";
            Entry."External Upload Date" := DocumentAttachment."External Upload Date";
            Entry."Source Environment Hash" := DocumentAttachment."Source Environment Hash";
            Entry.Origin := Origin;
            Entry.Status := Entry.Status::Blocked;
            Entry.Outcome := 'NoUploadProvenance';
            Entry."Last Error" := NoProvenanceErr;
            Entry.Insert();
            Telemetry.LogInternalCleanup(Entry);
            exit(false);
        end;

        if not CheckBinding(Entry, CurrentAttachment, Setup, false, Reason) then begin
            Entry.Status := Entry.Status::Blocked;
            Entry.Outcome := 'BindingChanged';
            Entry."Last Error" := CopyStr(Reason, 1, MaxStrLen(Entry."Last Error"));
            Clear(Entry."Lease Token");
            Entry.Modify();
            Telemetry.LogInternalCleanup(Entry);
            exit(false);
        end;
        if (Origin = Origin::Automatic) and not Setup."Automatic Verified Cleanup" then
            exit(false);
        Entry.Origin := Origin;
        Entry."Requested At" := CurrentDateTime();
        Entry."Request Environment Hash" := ExternalStorageImpl.GetCurrentEnvironmentHash();
        BlockInternalRelease(Entry);
        exit(false);
    end;

    procedure BlockInternalRelease(var Entry: Record "DA Internal Cleanup Entry")
    var
        Telemetry: Codeunit "DA Feature Telemetry";
    begin
        Entry.Status := Entry.Status::Blocked;
        Entry.Outcome := 'InternalReleaseUnsupported';
        Entry."Last Error" := GetInternalReleaseBlockedReason();
        Clear(Entry."Lease Token");
        Clear(Entry."Lease Expires At");
        Clear(Entry."Next Attempt At");
        Entry.Modify();
        Telemetry.LogInternalCleanup(Entry);
    end;

    procedure GetInternalReleaseBlockedReason(): Text
    begin
        exit(InternalReleaseBlockedErr);
    end;

    procedure CancelCleanup(AttachmentSystemId: Guid)
    begin
        CancelEntry(AttachmentSystemId, false);
    end;

    procedure InvalidateProvenance(AttachmentSystemId: Guid)
    begin
        CancelEntry(AttachmentSystemId, true);
    end;

    local procedure CancelEntry(AttachmentSystemId: Guid; InvalidateUpload: Boolean)
    var
        Entry: Record "DA Internal Cleanup Entry";
        Telemetry: Codeunit "DA Feature Telemetry";
    begin
        Entry.ReadIsolation(IsolationLevel::UpdLock);
        if not Entry.Get(AttachmentSystemId) then
            exit;
        Entry.Status := Entry.Status::Cancelled;
        Entry.Outcome := 'Cancelled';
        if InvalidateUpload then begin
            Entry."Provenance Valid" := false;
            Entry.Outcome := 'ProvenanceInvalidated';
        end;
        Clear(Entry."Lease Token");
        Clear(Entry."Lease Expires At");
        Entry.Modify();
        Telemetry.LogInternalCleanup(Entry);
    end;

    procedure CheckBinding(Entry: Record "DA Internal Cleanup Entry"; var DocumentAttachment: Record "Document Attachment"; var Setup: Record "DA External Storage Setup"; LockRecords: Boolean; var Reason: Text): Boolean
    var
        TenantMedia: Record "Tenant Media";
        TempAccount: Record "File Account" temporary;
        ExternalFileStorage: Codeunit "External File Storage";
        ExternalStorageImpl: Codeunit "DA External Storage Impl.";
        FileScenario: Codeunit "File Scenario";
        Fingerprint: Text[64];
        Generation: BigInteger;
    begin
        Reason := BindingChangedErr;
        if not Entry."Provenance Valid" then begin
            Reason := NoProvenanceErr;
            exit(false);
        end;
        // Request producers already hold attachment locks. Do not invert that ordering with a queue lock.
        if LockRecords then begin
            DocumentAttachment.ReadIsolation(IsolationLevel::UpdLock);
            Setup.ReadIsolation(IsolationLevel::UpdLock);
            TenantMedia.ReadIsolation(IsolationLevel::UpdLock);
        end;
        if not DocumentAttachment.GetBySystemId(Entry."Attachment System ID") then begin
            Reason := AttachmentMissingErr;
            exit(false);
        end;
        if not Setup.Get() then
            exit(false);
        if not Setup.Enabled then
            exit(false);
        if DocumentAttachment.IsTemporary() or DocumentAttachment."Skip Delete On Copy" then begin
            Reason := OwnershipErr;
            exit(false);
        end;
        if (Entry."Source Environment Hash" = '') or
           (Entry."Source Environment Hash" <> ExternalStorageImpl.GetCurrentEnvironmentHash()) or
           (DocumentAttachment."Source Environment Hash" <> Entry."Source Environment Hash")
        then begin
            Reason := OwnershipErr;
            exit(false);
        end;
        if not DocumentAttachment."Stored Internally" or not DocumentAttachment."Stored Externally" then
            exit(false);
        if (Entry."External File Path" = '') or
           (DocumentAttachment."External File Path" <> Entry."External File Path") or
           (DocumentAttachment."External Upload Date" <> Entry."External Upload Date")
        then
            exit(false);
        if not DocumentAttachment."Document Reference ID".HasValue() then
            exit(false);
        if DocumentAttachment."Document Reference ID".MediaId() <> Entry."Source Media ID" then
            exit(false);
        if not TenantMedia.Get(Entry."Source Media ID") then
            exit(false);
        if TenantMedia.SystemRowVersion <> Entry."Source Media Version" then
            exit(false);
        TempAccount."Account Id" := Entry."Account ID";
        TempAccount.Connector := Entry.Connector;
        if not FileScenario.IsSpecificFileAccountAssigned(Enum::"File Scenario"::"Doc. Attach. - External Storage", TempAccount, LockRecords) then
            exit(false);
        ClearLastError();
        if not ExternalFileStorage.GetDestinationContext(TempAccount, LockRecords, Fingerprint, Generation) then begin
            Reason := GetLastErrorText(true);
            exit(false);
        end;
        if (Fingerprint <> Entry."Destination Fingerprint") or (Generation <> Entry."Account Generation") then begin
            Reason := ConfigurationChangedErr;
            exit(false);
        end;
        exit(true);
    end;

    procedure ScheduleCleanup(var Setup: Record "DA External Storage Setup")
    var
        LockedSetup: Record "DA External Storage Setup";
        Job: Record "Job Queue Entry";
        JobQueueManagement: Codeunit "Job Queue Management";
        NewJob: Boolean;
    begin
        LockedSetup.ReadIsolation(IsolationLevel::UpdLock);
        LockedSetup.Get();
        Setup.TestField(Enabled, true);
        Setup.TestField("Cleanup Batch Size");
        Setup.TestField("Cleanup Run Minutes");
        if not Job.WritePermission() then
            Error(SchedulingPermissionErr);
        if not IsNullGuid(Setup."Cleanup Job Queue Entry ID") then
            if Job.Get(Setup."Cleanup Job Queue Entry ID") then
                if (Job."Object Type to Run" <> Job."Object Type to Run"::Codeunit) or
                   (Job."Object ID to Run" <> Codeunit::"DA Internal Cleanup Worker")
                then
                    Clear(Job);

        if IsNullGuid(Job.ID) then begin
            Job.Reset();
            Job.SetRange("Object Type to Run", Job."Object Type to Run"::Codeunit);
            Job.SetRange("Object ID to Run", Codeunit::"DA Internal Cleanup Worker");
            if not Job.FindFirst() then begin
                Job.Init();
                Job."Object Type to Run" := Job."Object Type to Run"::Codeunit;
                Job."Object ID to Run" := Codeunit::"DA Internal Cleanup Worker";
                Job."No. of Minutes between Runs" := 15;
                JobQueueManagement.CreateJobQueueEntry(Job);
                NewJob := not IsNullGuid(Job.ID);
                if not NewJob then
                    Job.FindFirst();
            end;
        end;
        Setup."Cleanup Job Queue Entry ID" := Job.ID;
        if NewJob then begin
            Job.Description := CleanupDescriptionLbl;
            Job."Job Queue Category Code" := 'DA-CLEANUP';
            Job."Notify On Success" := false;
            Job.Modify();
            Codeunit.Run(Codeunit::"Job Queue - Enqueue", Job);
        end else
            if not (Job.Status in [Job.Status::Ready, Job.Status::"In Process", Job.Status::Waiting]) then
                Message(WorkerNotRunningMsg);
    end;

    var
        NoProvenanceErr: Label 'No verified upload provenance is available. Internal content and the existing external reference have been retained.';
        BindingChangedErr: Label 'The attachment, internal source, or external storage binding has changed. Internal content has been retained.';
        ConfigurationChangedErr: Label 'The storage account configuration has changed since upload. Retrying does not rebind the uploaded file to a different configuration.';
        OwnershipErr: Label 'Cleanup is not authorized for a copied attachment or a file owned by another environment or company.';
        AttachmentMissingErr: Label 'The attachment no longer exists.';
        SchedulingPermissionErr: Label 'Cleanup requests have been retained, but you do not have permission to schedule the cleanup worker. Ask a job queue administrator to schedule it.';
        WorkerNotRunningMsg: Label 'Cleanup requests have been retained. The cleanup job is on hold or in error; a job queue administrator must restart it.';
        CleanupDescriptionLbl: Label 'Validate pending attachments without releasing internal references';
        InternalReleaseBlockedErr: Label 'Internal cleanup is blocked because no supported globally owner-preserving media release operation is available. Internal references and content are retained, including after successful external readback. No database storage is reclaimed.';
}
