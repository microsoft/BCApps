// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExternalStorage.DocumentAttachments;

using Microsoft.Foundation.Attachment;

codeunit 8757 "DA Internal Cleanup Finalize"
{
    Access = Internal;
    TableNo = "DA Internal Cleanup Entry";
    InherentPermissions = X;
    InherentEntitlements = X;
    Permissions = tabledata "DA Internal Cleanup Entry" = rm;

    trigger OnRun()
    var
        CurrentEntry: Record "DA Internal Cleanup Entry";
        DocumentAttachment: Record "Document Attachment";
        Setup: Record "DA External Storage Setup";
        CleanupManagement: Codeunit "DA Internal Cleanup Mgt.";
        Reason: Text;
        BindingMatches: Boolean;
    begin
        Rec.TestField("Last Verified At");
        Rec.TestField("Retrieved Bytes");
        Rec.TestField("Attempt Attachment Version");
        Rec.TestField("Attempt Setup Version");
        BindingMatches := CleanupManagement.CheckBinding(Rec, DocumentAttachment, Setup, true, Reason);

        CurrentEntry.ReadIsolation(IsolationLevel::UpdLock);
        if not CurrentEntry.Get(Rec."Attachment System ID") then
            exit;
        if (CurrentEntry.Status <> CurrentEntry.Status::"In Progress") or
           (CurrentEntry."Lease Token" <> Rec."Lease Token") or
           (CurrentEntry."Upload Generation" <> Rec."Upload Generation")
        then
            exit;
        if (CurrentEntry."Lease Expires At" <= CurrentDateTime()) or
           (Rec."Last Verified At" > CurrentDateTime()) or
           (Rec."Last Verified At" < CurrentEntry."Lease Expires At" - 1800000) or
           (DocumentAttachment.SystemRowVersion <> Rec."Attempt Attachment Version") or
           (Setup.SystemRowVersion <> Rec."Attempt Setup Version") or
           (Rec."Request Environment Hash" <> Rec."Source Environment Hash") or
           ((CurrentEntry.Origin = CurrentEntry.Origin::Automatic) and not Setup."Automatic Verified Cleanup")
        then begin
            BindingMatches := false;
            Reason := StateChangedErr;
        end;
        if not BindingMatches then begin
            CurrentEntry.Status := CurrentEntry.Status::Blocked;
            CurrentEntry.Outcome := 'StateChanged';
            CurrentEntry."Last Error" := CopyStr(Reason, 1, MaxStrLen(CurrentEntry."Last Error"));
        end else begin
            CurrentEntry."Last Verified At" := Rec."Last Verified At";
            CurrentEntry."Retrieved Bytes" := Rec."Retrieved Bytes";
            CleanupManagement.BlockInternalRelease(CurrentEntry);
            exit;
        end;
        Clear(CurrentEntry."Lease Token");
        Clear(CurrentEntry."Lease Expires At");
        CurrentEntry.Modify();
    end;

    var
        StateChangedErr: Label 'The attachment, policy, or cleanup attempt changed after readback. Internal content has been retained.';
}
