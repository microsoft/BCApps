// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExternalStorage.DocumentAttachments;

using Microsoft.Foundation.Attachment;
using System.ExternalFileStorage;
using System.Threading;
using System.Utilities;

codeunit 8756 "DA Internal Cleanup Worker"
{
    Access = Internal;
    TableNo = "Job Queue Entry";
    InherentPermissions = X;
    InherentEntitlements = X;
    Permissions = tabledata "DA Internal Cleanup Entry" = rm,
                  tabledata "DA External Storage Setup" = r,
                  tabledata "Document Attachment" = r,
                  tabledata "Job Queue Entry" = rm;

    trigger OnRun()
    var
        Setup: Record "DA External Storage Setup";
        ManualWork: Record "DA Internal Cleanup Entry";
    begin
        ProcessPending();
        Setup.Get();
        if not Setup."Automatic Verified Cleanup" then begin
            ManualWork.SetFilter(Origin, '%1|%2', ManualWork.Origin::Move, ManualWork.Origin::"Delete from Internal");
            ManualWork.SetFilter(Status, '%1|%2|%3', ManualWork.Status::Pending, ManualWork.Status::"In Progress", ManualWork.Status::"Retry Due");
            if ManualWork.IsEmpty() then begin
                Rec."Recurring Job" := false;
                Rec.Modify();
            end;
        end;
    end;

    procedure ProcessPending()
    var
        Setup: Record "DA External Storage Setup";
        Candidate: Record "DA Internal Cleanup Entry";
        Attempt: Record "DA Internal Cleanup Entry";
        Telemetry: Codeunit "DA Feature Telemetry";
        StartedAt: DateTime;
        ProcessedCount: Integer;
    begin
        Setup.Get();
        Setup.TestField(Enabled, true);
        Setup.TestField("Cleanup Batch Size");
        Setup.TestField("Cleanup Run Minutes");
        if (Setup."Cleanup Batch Size" < 1) or (Setup."Cleanup Batch Size" > 1000) or
           (Setup."Cleanup Run Minutes" < 1) or (Setup."Cleanup Run Minutes" > 60)
        then
            Error(InvalidLimitsErr);
        StartedAt := CurrentDateTime();
        RecoverExpiredLeases(Setup."Cleanup Batch Size");
        Commit();
        while (ProcessedCount < Setup."Cleanup Batch Size") and
              (CurrentDateTime() - StartedAt < Setup."Cleanup Run Minutes" * 60000)
        do begin
            Candidate.Reset();
            Candidate.SetCurrentKey("Next Attempt At", Status, "Attachment System ID");
            Candidate.SetFilter(Status, '%1|%2', Candidate.Status::Pending, Candidate.Status::"Retry Due");
            Candidate.SetFilter("Next Attempt At", '<=%1', CurrentDateTime());
            Candidate.SetFilter(Origin, '<>%1', Candidate.Origin::Copy);
            if not Setup."Automatic Verified Cleanup" then
                Candidate.SetFilter(Origin, '<>%1&<>%2', Candidate.Origin::Copy, Candidate.Origin::Automatic);
            if not Candidate.FindFirst() then
                break;
            ProcessedCount += 1;
            if Claim(Candidate."Attachment System ID", Attempt) then
                ProcessAttempt(Attempt);
            Commit();
        end;
        Telemetry.LogInternalCleanupBatch(ProcessedCount);
    end;

    local procedure Claim(AttachmentSystemId: Guid; var Attempt: Record "DA Internal Cleanup Entry"): Boolean
    begin
        Attempt.ReadIsolation(IsolationLevel::UpdLock);
        if not Attempt.Get(AttachmentSystemId) then
            exit(false);
        if not (Attempt.Status in [Attempt.Status::Pending, Attempt.Status::"Retry Due"]) then
            exit(false);
        if Attempt."Next Attempt At" > CurrentDateTime() then
            exit(false);
        if Attempt."Attempt Count" >= 5 then begin
            Attempt.Status := Attempt.Status::Blocked;
            Attempt.Outcome := 'AttemptLimit';
            Attempt."Last Error" := AttemptLimitErr;
            Attempt.Modify();
            exit(false);
        end;
        Attempt.Status := Attempt.Status::"In Progress";
        Attempt."Attempt Count" += 1;
        Attempt."Lease Token" := CreateGuid();
        Attempt."Lease Expires At" := CurrentDateTime() + 1800000;
        Clear(Attempt."Last Verified At");
        Clear(Attempt."Retrieved Bytes");
        Clear(Attempt."Attempt Attachment Version");
        Clear(Attempt."Attempt Setup Version");
        Attempt.Modify();
        Commit(); // Only the queue claim is locked; no attachment locks or network calls precede this boundary.
        exit(true);
    end;

    local procedure ProcessAttempt(var Attempt: Record "DA Internal Cleanup Entry")
    var
        DocumentAttachment: Record "Document Attachment";
        Setup: Record "DA External Storage Setup";
        CleanupManagement: Codeunit "DA Internal Cleanup Mgt.";
        Telemetry: Codeunit "DA Feature Telemetry";
        Reason: Text;
    begin
        if not DocumentAttachment.GetBySystemId(Attempt."Attachment System ID") then begin
            CleanupManagement.CancelCleanup(Attempt."Attachment System ID");
            exit;
        end;
        if not CleanupManagement.CheckBinding(Attempt, DocumentAttachment, Setup, false, Reason) then begin
            RecordFailure(Attempt, false, 'BindingChanged', Reason);
            exit;
        end;
        if (Attempt.Origin = Attempt.Origin::Automatic) and not Setup."Automatic Verified Cleanup" then begin
            RecordFailure(Attempt, false, 'PolicyChanged', PolicyChangedErr);
            exit;
        end;
        Attempt."Attempt Attachment Version" := DocumentAttachment.SystemRowVersion;
        Attempt."Attempt Setup Version" := Setup.SystemRowVersion;
        Commit();
        ClearLastError();
        if not Readback(Attempt, Attempt."Retrieved Bytes") then begin
            RecordFailure(Attempt, true, 'ReadbackFailed', GetLastErrorText(true));
            exit;
        end;
        Attempt."Last Verified At" := CurrentDateTime();
        OnAfterReadback(Attempt."Attachment System ID");
        Commit();
        ClearLastError();
        if not Codeunit.Run(Codeunit::"DA Internal Cleanup Finalize", Attempt) then begin
            RecordFailure(Attempt, true, 'CleanupFailed', GetLastErrorText(true));
            exit;
        end;
        if Attempt.Get(Attempt."Attachment System ID") then
            Telemetry.LogInternalCleanup(Attempt);
    end;

    [TryFunction]
    local procedure Readback(Attempt: Record "DA Internal Cleanup Entry"; var RetrievedBytes: BigInteger)
    var
        Account: Record "File Account" temporary;
        ExternalFileStorage: Codeunit "External File Storage";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        OutStream: OutStream;
    begin
        Account."Account Id" := Attempt."Account ID";
        Account.Connector := Attempt.Connector;
        CheckDestination(Attempt, Account);
        ExternalFileStorage.Initialize(Account);
        if not ExternalFileStorage.GetFile(Attempt."External File Path", InStream) then
            Error('%1', GetLastErrorText(true));
        TempBlob.CreateOutStream(OutStream);
        CopyStream(OutStream, InStream);
        if not TempBlob.HasValue() then
            Error(EmptyReadbackErr);
        RetrievedBytes := TempBlob.Length();
        CheckDestination(Attempt, Account);
    end;

    local procedure CheckDestination(Attempt: Record "DA Internal Cleanup Entry"; Account: Record "File Account" temporary)
    var
        ExternalFileStorage: Codeunit "External File Storage";
        Fingerprint: Text[64];
        Generation: BigInteger;
    begin
        if not ExternalFileStorage.GetDestinationContext(Account, false, Fingerprint, Generation) then
            Error('%1', GetLastErrorText(true));
        if (Fingerprint <> Attempt."Destination Fingerprint") or (Generation <> Attempt."Account Generation") then
            Error(DestinationChangedErr);
    end;

    local procedure RecordFailure(Attempt: Record "DA Internal Cleanup Entry"; Retryable: Boolean; Outcome: Text; ErrorText: Text)
    var
        Entry: Record "DA Internal Cleanup Entry";
        Telemetry: Codeunit "DA Feature Telemetry";
        Delay: Integer;
    begin
        Entry.ReadIsolation(IsolationLevel::UpdLock);
        if not Entry.Get(Attempt."Attachment System ID") then
            exit;
        if (Entry.Status <> Entry.Status::"In Progress") or (Entry."Lease Token" <> Attempt."Lease Token") then
            exit;
        Entry.Status := Entry.Status::Blocked;
        if Retryable and (Entry."Attempt Count" < 5) then begin
            case Entry."Attempt Count" of
                1:
                    Delay := 900000;
                2:
                    Delay := 3600000;
                3:
                    Delay := 14400000;
                4:
                    Delay := 86400000;
            end;
            Entry.Status := Entry.Status::"Retry Due";
            Entry."Next Attempt At" := CurrentDateTime() + Delay;
        end;
        Entry.Outcome := CopyStr(Outcome, 1, MaxStrLen(Entry.Outcome));
        if ErrorText = '' then
            ErrorText := ValidationFailedErr;
        Entry."Last Error" := CopyStr(ErrorText, 1, MaxStrLen(Entry."Last Error"));
        Clear(Entry."Lease Token");
        Clear(Entry."Lease Expires At");
        Entry.Modify();
        Telemetry.LogInternalCleanup(Entry);
    end;

    local procedure RecoverExpiredLeases(MaxRecords: Integer)
    var
        Candidate: Record "DA Internal Cleanup Entry";
        Entry: Record "DA Internal Cleanup Entry";
        Count: Integer;
    begin
        Candidate.SetCurrentKey(Status, "Lease Expires At", "Attachment System ID");
        Candidate.SetRange(Status, Candidate.Status::"In Progress");
        Candidate.SetFilter("Lease Expires At", '<=%1', CurrentDateTime());
        Entry.ReadIsolation(IsolationLevel::UpdLock);
        if Candidate.FindSet() then
            repeat
                if Entry.Get(Candidate."Attachment System ID") then
                    if (Entry.Status = Entry.Status::"In Progress") and (Entry."Lease Expires At" <= CurrentDateTime()) then begin
                        Entry.Status := Entry.Status::"Retry Due";
                        Entry."Next Attempt At" := CurrentDateTime();
                        Entry.Outcome := 'LeaseExpired';
                        Clear(Entry."Lease Token");
                        Clear(Entry."Lease Expires At");
                        Entry.Modify();
                    end;
                Count += 1;
                if Count >= MaxRecords then
                    exit;
            until Candidate.Next() = 0;
    end;

    [InternalEvent(false)]
    local procedure OnAfterReadback(AttachmentSystemId: Guid)
    begin
    end;

    var
        AttemptLimitErr: Label 'The cleanup attempt limit was reached. Internal content and the external reference have been retained.';
        EmptyReadbackErr: Label 'External retrieval returned no content. Internal content has been retained.';
        DestinationChangedErr: Label 'The storage destination configuration changed during validation. Internal content has been retained.';
        PolicyChangedErr: Label 'Automatic internal cleanup was disabled. Internal content has been retained.';
        InvalidLimitsErr: Label 'Cleanup limits must be finite: batch size 1 through 1000 and run budget 1 through 60 minutes.';
        ValidationFailedErr: Label 'External retrieval or internal cleanup validation failed. Internal content and the external reference have been retained.';
}
