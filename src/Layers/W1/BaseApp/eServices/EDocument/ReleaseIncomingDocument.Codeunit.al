// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using System.Automation;

codeunit 132 "Release Incoming Document"
{
    TableNo = "Incoming Document";
    Permissions = TableData "Incoming Document" = rm;

    trigger OnRun()
    begin
        if Rec.Status = Rec.Status::Released then
            exit;
        if Rec.Status in [Rec.Status::Created, Rec.Status::Posted] then
            Error(CanReleasedIfStatusErr, Rec.Status::"Pending Approval", Rec.Status::New, Rec.Status::Failed);

        Rec.OnCheckIncomingDocReleaseRestrictions();

        Rec.TestField(Posted, false);

        if not Rec.IsADocumentAttached() then
            Error(NothingToReleaseErr, Rec."Entry No.");

        Rec.Status := Rec.Status::Released;
        Rec.Released := true;
        Rec."Released Date-Time" := CurrentDateTime;
        Rec."Released By User ID" := UserSecurityId();

        Rec.Modify(true);

        OnAfterReleaseIncomingDoc(Rec);
    end;

    var
        NothingToReleaseErr: Label 'There is nothing to release for the incoming document number %1.', Comment = '%1 = Incoming Document Entry No';
        DocReleasedWhenApprovedErr: Label 'This document can only be released when the approval process is complete.';
        CancelOrCompleteToReopenDocErr: Label 'The approval process must be cancelled or completed to reopen this document.';
#pragma warning disable AA0470
        CanReleasedIfStatusErr: Label 'It is only possible to release the document when the status is %1, %2 or %3.', Comment = '%1 = status released, %2 = status pending approval';
#pragma warning restore AA0470

    procedure Reopen(var IncomingDocument: Record "Incoming Document")
    var
        RelatedRecord: Variant;
    begin
        if IncomingDocument.Status = IncomingDocument.Status::New then
            exit;
        ClearReleaseFields(IncomingDocument);

        if not ((IncomingDocument.Status = IncomingDocument.Status::Created) and (IncomingDocument.GetRecord(RelatedRecord))) then
            IncomingDocument.Status := IncomingDocument.Status::New;

        IncomingDocument.Modify(true);
    end;

    procedure Reject(var IncomingDocument: Record "Incoming Document")
    begin
        IncomingDocument.TestField(Posted, false);

        ClearReleaseFields(IncomingDocument);
        IncomingDocument.Status := IncomingDocument.Status::Rejected;

        IncomingDocument.Modify(true);
    end;

    procedure Fail(var IncomingDocument: Record "Incoming Document")
    begin
        if IncomingDocument.Status = IncomingDocument.Status::Failed then
            exit;

        IncomingDocument.Status := IncomingDocument.Status::Failed;

        IncomingDocument.Modify(true);
        Commit();

        OnAfterCreateDocFromIncomingDocFail(IncomingDocument);
    end;

    procedure Create(var IncomingDocument: Record "Incoming Document")
    begin
        if IncomingDocument.Status = IncomingDocument.Status::Created then
            exit;

        IncomingDocument.Status := IncomingDocument.Status::Created;

        IncomingDocument.Modify(true);
        Commit();
        OnAfterCreateDocFromIncomingDocSuccess(IncomingDocument);
    end;

    [Scope('OnPrem')]
    procedure PerformManualRelease(var IncomingDocument: Record "Incoming Document")
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        if ApprovalsMgmt.IsIncomingDocApprovalsWorkflowEnabled(IncomingDocument) and
           (IncomingDocument.Status = IncomingDocument.Status::New)
        then
            Error(DocReleasedWhenApprovedErr);

        CODEUNIT.Run(CODEUNIT::"Release Incoming Document", IncomingDocument);
    end;

    procedure PerformManualReopen(var IncomingDocument: Record "Incoming Document")
    begin
        if IncomingDocument.Status = IncomingDocument.Status::"Pending Approval" then
            Error(CancelOrCompleteToReopenDocErr);

        Reopen(IncomingDocument);
    end;

    procedure PerformManualReject(var IncomingDocument: Record "Incoming Document")
    begin
        if IncomingDocument.Status = IncomingDocument.Status::"Pending Approval" then
            Error(CancelOrCompleteToReopenDocErr);

        Reject(IncomingDocument);
    end;

    local procedure ClearReleaseFields(var IncomingDocument: Record "Incoming Document")
    begin
        IncomingDocument.Released := false;
        IncomingDocument."Released Date-Time" := 0DT;
        Clear(IncomingDocument."Released By User ID");
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterReleaseIncomingDoc(var IncomingDocument: Record "Incoming Document")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterCreateDocFromIncomingDocSuccess(var IncomingDocument: Record "Incoming Document")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterCreateDocFromIncomingDocFail(var IncomingDocument: Record "Incoming Document")
    begin
    end;
}

