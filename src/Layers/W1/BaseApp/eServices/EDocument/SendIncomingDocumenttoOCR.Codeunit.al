// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using System.Automation;

codeunit 133 "Send Incoming Document to OCR"
{
    TableNo = "Incoming Document";

    trigger OnRun()
    begin
        SendDocToOCR(Rec);
    end;

    var
        OCRWhenApprovalIsCompleteErr: Label 'The document can only be sent to the OCR service when the approval process is complete.';
        NoOcrAttachmentErr: Label 'There is no attachment of type PDF or Image.';
        NoAttachmentMarkedForOcrErr: Label 'You must select an attachment for use for OCR.';
        ShowMessages: Boolean;
        CannotRemoveFromJobQueueTxt: Label 'The document cannot be removed from queue since it is already sent.';
        CannotSendDocumentTxt: Label 'The document cannot be sent to the OCR service because its status is %1.', Comment = '%1 Status of the document for example: New, Released, Posted, Created, Rejected...';
        CannotScheduleDocumentTxt: Label 'The document cannot be scheduled for sending to the OCR service because its status is %1.', Comment = '%1 Status of the document for example: New, Released, Posted, Created, Rejected...';
        RemovedFromJobQueueTxt: Label 'The document was successfully removed from Job Queue.';
        DocumentHasBeenScheduledTxt: Label 'The document has been scheduled for sending to the OCR service.';
        DoYouWantToSetupOCRQst: Label 'The OCR service is not enabled.\\Do you want to open the OCR Service Setup window?';
        OCRServiceNotEnabledErr: Label 'The OCR service is not enabled.';

    [Scope('OnPrem')]
    procedure SendToJobQueue(var IncomingDocument: Record "Incoming Document")
    begin
        if not VerifySendToOCR(IncomingDocument, CannotScheduleDocumentTxt) then
            exit;

        IncomingDocument.TestField("OCR Status", IncomingDocument."OCR Status"::" ");
        IncomingDocument."OCR Status" := IncomingDocument."OCR Status"::Ready;
        IncomingDocument.Modify();

        CODEUNIT.Run(CODEUNIT::"Release Incoming Document", IncomingDocument);
        ShowMessage(DocumentHasBeenScheduledTxt);
        OnAfterIncomingDocReadyForOCR(IncomingDocument);
    end;

    procedure RemoveFromJobQueue(var IncomingDocument: Record "Incoming Document")
    var
        ReleaseIncomingDocument: Codeunit "Release Incoming Document";
    begin
        if IncomingDocument."OCR Status" <> IncomingDocument."OCR Status"::Ready then begin
            ShowMessage(CannotRemoveFromJobQueueTxt);
            exit;
        end;

        IncomingDocument."OCR Status" := IncomingDocument."OCR Status"::" ";
        ReleaseIncomingDocument.Reopen(IncomingDocument);
        IncomingDocument.Modify();
        ShowMessage(RemovedFromJobQueueTxt);
    end;

    [Scope('OnPrem')]
    procedure SendDocToOCR(var IncomingDocument: Record "Incoming Document")
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        OCRServiceSetup: Record "OCR Service Setup";
    begin
        OCRServiceSetup.Get();
        if not OCRServiceSetup.Enabled then begin
            if not Confirm(DoYouWantToSetupOCRQst) then
                exit;
            PAGE.RunModal(PAGE::"OCR Service Setup", OCRServiceSetup);
            if not OCRServiceSetup.Enabled then
                Error(OCRServiceNotEnabledErr);
        end;

        if not VerifySendToOCR(IncomingDocument, CannotSendDocumentTxt) then
            exit;

        UpdateIncomingDocumentAttachmentForOCR(IncomingDocument);

        case IncomingDocument."OCR Status" of
            IncomingDocument."OCR Status"::" ":
                IncomingDocument."OCR Status" := IncomingDocument."OCR Status"::Ready;
            IncomingDocument."OCR Status"::Ready:
                ;
            else
                exit;
        end;

        CODEUNIT.Run(CODEUNIT::"Release Incoming Document", IncomingDocument);

        IncomingDocument.LockTable();
        IncomingDocument.Find();
        // Check OCR Status due to it could be changed by another user in the meantime
        if IncomingDocument."OCR Status" = IncomingDocument."OCR Status"::Ready then begin
            IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");
            IncomingDocumentAttachment.SetRange("Use for OCR", true);
            if not IncomingDocumentAttachment.FindFirst() then
                Error(NoAttachmentMarkedForOcrErr);
            IncomingDocumentAttachment.SendToOCR();
            IncomingDocument."OCR Status" := IncomingDocument."OCR Status"::Sent;
            IncomingDocument.Modify();
        end;
        Commit();
        OnAfterIncomingDocSentToOCR(IncomingDocument);
    end;

    procedure ScheduleJobQueueReceive()
    var
        OCRServiceSetup: Record "OCR Service Setup";
    begin
        OCRServiceSetup.ScheduleJobQueueReceive();
    end;

    [Scope('OnPrem')]
    procedure RetrieveDocFromOCR(var IncomingDocument: Record "Incoming Document")
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        OCRServiceMgt: Codeunit "OCR Service Mgt.";
        OCRStatus: Integer;
    begin
        if not (IncomingDocument."OCR Status" in [IncomingDocument."OCR Status"::Sent, IncomingDocument."OCR Status"::"Awaiting Verification"]) then
            IncomingDocument.TestField("OCR Status", IncomingDocument."OCR Status"::Sent);

        IncomingDocument.CheckNotCreated();
        IncomingDocument.LockTable();
        IncomingDocument.Find();
        IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");
        IncomingDocumentAttachment.SetRange("Use for OCR", true);
        if IncomingDocumentAttachment.FindFirst() then begin
            OCRStatus := OCRServiceMgt.GetDocumentForAttachment(IncomingDocumentAttachment);
            if not (OCRStatus in [IncomingDocument."OCR Status"::Success, IncomingDocument."OCR Status"::Error, IncomingDocument."OCR Status"::"Awaiting Verification"]) then
                Error('');
        end;

        IncomingDocument.Find();

        case OCRStatus of
            IncomingDocument."OCR Status"::Success:
                SetStatusToReceived(IncomingDocument);
            IncomingDocument."OCR Status"::"Awaiting Verification":
                SetStatusToVerify(IncomingDocument);
            IncomingDocument."OCR Status"::Error:
                SetStatusToFailed(IncomingDocument);
        end;
    end;

    procedure SetStatusToReceived(var IncomingDocument: Record "Incoming Document")
    begin
        IncomingDocument.Find();
        if (IncomingDocument."OCR Status" = IncomingDocument."OCR Status"::Success) and IncomingDocument."OCR Process Finished" then
            exit;

        IncomingDocument."OCR Status" := IncomingDocument."OCR Status"::Success;
        IncomingDocument."OCR Process Finished" := true;
        IncomingDocument.Modify();
        Commit();

        OnAfterIncomingDocReceivedFromOCR(IncomingDocument);
    end;

    procedure SetStatusToFailed(var IncomingDocument: Record "Incoming Document")
    begin
        IncomingDocument.Find();
        IncomingDocument."OCR Status" := IncomingDocument."OCR Status"::Error;
        IncomingDocument."OCR Process Finished" := true;
        IncomingDocument.Modify();
        Commit();

        OnAfterIncomingDocReceivedFromOCR(IncomingDocument);
    end;

    procedure SetStatusToVerify(var IncomingDocument: Record "Incoming Document")
    begin
        IncomingDocument.Find();
        IncomingDocument."OCR Status" := IncomingDocument."OCR Status"::"Awaiting Verification";
        IncomingDocument.Modify();
        Commit();
    end;

    procedure TrySendToOCR(var IncomingDocument: Record "Incoming Document"): Boolean
    begin
        exit(CODEUNIT.Run(CODEUNIT::"Send Incoming Document to OCR", IncomingDocument));
    end;

    procedure TryRetrieveFromOCR(var IncomingDocument: Record "Incoming Document"): Boolean
    begin
        exit(CODEUNIT.Run(CODEUNIT::"Retrieve Document From OCR", IncomingDocument));
    end;

    local procedure VerifySendToOCR(var IncomingDocument: Record "Incoming Document"; ErrorMessage: Text): Boolean
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        IncomingDocument.TestField(Posted, false);
        IncomingDocument.CheckNotCreated();

        if not (IncomingDocument.Status in [IncomingDocument.Status::New, IncomingDocument.Status::Released, IncomingDocument.Status::"Pending Approval"]) then begin
            ShowMessage(StrSubstNo(ErrorMessage, Format(IncomingDocument.Status)));
            exit(false);
        end;

        if IncomingDocument."OCR Status" in [IncomingDocument."OCR Status"::Sent, IncomingDocument."OCR Status"::Success, IncomingDocument."OCR Status"::"Awaiting Verification"] then begin
            ShowMessage(StrSubstNo(ErrorMessage, Format(IncomingDocument."OCR Status")));
            exit(false);
        end;

        IncomingDocument.OnCheckIncomingDocSetForOCRRestrictions();

        if ApprovalsMgmt.IsIncomingDocApprovalsWorkflowEnabled(IncomingDocument) and (IncomingDocument.Status = IncomingDocument.Status::New) then
            Error(OCRWhenApprovalIsCompleteErr);

        UpdateIncomingDocumentAttachmentForOCR(IncomingDocument);

        exit(true);
    end;

    local procedure UpdateIncomingDocumentAttachmentForOCR(var IncomingDocument: Record "Incoming Document")
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
    begin
        IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");
        IncomingDocumentAttachment.SetFilter(Type, '%1|%2', IncomingDocumentAttachment.Type::PDF, IncomingDocumentAttachment.Type::Image);
        if IncomingDocumentAttachment.IsEmpty() then
            Error(NoOcrAttachmentErr);
        IncomingDocument.TestField(IncomingDocument."OCR Service Doc. Template Code");
        IncomingDocumentAttachment.SetRange("Use for OCR", true);
        if IncomingDocumentAttachment.IsEmpty() then begin
            IncomingDocumentAttachment.SetRange("Use for OCR");
            IncomingDocumentAttachment.SetRange("Main Attachment", true);
            IncomingDocumentAttachment.FindFirst();
            IncomingDocumentAttachment."Use for OCR" := true;
            IncomingDocumentAttachment.Modify();
        end;
    end;

    procedure SetShowMessages(NewShowMessages: Boolean)
    begin
        ShowMessages := NewShowMessages;
    end;

    local procedure ShowMessage(MessageText: Text)
    begin
        if ShowMessages then
            Message(MessageText);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIncomingDocReadyForOCR(var IncomingDocument: Record "Incoming Document")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIncomingDocSentToOCR(var IncomingDocument: Record "Incoming Document")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIncomingDocReceivedFromOCR(var IncomingDocument: Record "Incoming Document")
    begin
    end;
}

