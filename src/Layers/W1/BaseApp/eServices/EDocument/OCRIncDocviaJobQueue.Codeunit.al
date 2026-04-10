// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using System.Threading;

codeunit 137 "OCR Inc. Doc. via Job Queue"
{
    Permissions = TableData "Job Queue Entry" = rimd;
    TableNo = "Job Queue Entry";

    trigger OnRun()
    var
        IncomingDocument: Record "Incoming Document";
        SendIncomingDocumentToOCR: Codeunit "Send Incoming Document to OCR";
        RecRef: RecordRef;
    begin
        Rec.TestField("Record ID to Process");
        RecRef.Get(Rec."Record ID to Process");
        RecRef.SetTable(IncomingDocument);
        IncomingDocument.Find();
        SetJobQueueStatus(IncomingDocument, IncomingDocument."Job Queue Status"::Processing);

        case IncomingDocument."OCR Status" of
            IncomingDocument."OCR Status"::Ready:
                if not SendIncomingDocumentToOCR.TrySendToOCR(IncomingDocument) then begin
                    SetJobQueueStatus(IncomingDocument, IncomingDocument."Job Queue Status"::Error);
                    Error(GetLastErrorText);
                end;
            IncomingDocument."OCR Status"::Sent, IncomingDocument."OCR Status"::"Awaiting Verification":
                if not (SendIncomingDocumentToOCR.TryRetrieveFromOCR(IncomingDocument) and
                        (IncomingDocument."OCR Status" = IncomingDocument."OCR Status"::Success))
                then begin
                    SetJobQueueStatus(IncomingDocument, IncomingDocument."Job Queue Status"::Processing);
                    Error(GetLastErrorText);
                end;
        end;

        SetJobQueueStatus(IncomingDocument, IncomingDocument."Job Queue Status"::" ");
    end;

    var
        OCRSendReceiveDescriptionTxt: Label 'OCR Incoming Document No. %1.', Comment = '%1 = document type, %2 = document number. Example: Post Purchase Order 1234.';
        IncomingDocumentScheduledMsg: Label 'Incoming Document No. %1 has been scheduled for OCR.', Comment = '%1=document type, %2=number, e.g. Order 123  or Invoice 234.';
        WrongJobQueueStatusErr: Label 'Incoming Document No. %1 cannot be processed because it has already been scheduled for OCR. Choose the Remove from Job Queue action to reset the job queue status and then OCR again.', Comment = '%1 = document type, %2 = document number. Example: Purchase Order 1234 or Invoice 1234.';

    local procedure SetJobQueueStatus(var IncomingDocument: Record "Incoming Document"; NewStatus: Enum "Inc. Doc. Job Queue Status")
    begin
        IncomingDocument.LockTable();
        if IncomingDocument.Find() then begin
            IncomingDocument."Job Queue Status" := NewStatus;
            IncomingDocument.Modify();
            Commit();
        end;
    end;

    procedure EnqueueIncomingDoc(var IncomingDocument: Record "Incoming Document")
    begin
        if not (IncomingDocument."Job Queue Status" in [IncomingDocument."Job Queue Status"::" ", IncomingDocument."Job Queue Status"::Error]) then
            Error(WrongJobQueueStatusErr, IncomingDocument."Entry No.");
        if IncomingDocument.Status = IncomingDocument.Status::New then
            CODEUNIT.Run(CODEUNIT::"Release Incoming Document", IncomingDocument);

        IncomingDocument."Job Queue Status" := IncomingDocument."Job Queue Status"::Scheduled;
        IncomingDocument."Job Queue Entry ID" := EnqueueJobEntry(IncomingDocument);
        IncomingDocument.Modify();
        Message(IncomingDocumentScheduledMsg, IncomingDocument."Entry No.");
    end;

    local procedure EnqueueJobEntry(IncomingDocument: Record "Incoming Document"): Guid
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := CODEUNIT::"OCR Inc. Doc. via Job Queue";
        JobQueueEntry."Record ID to Process" := IncomingDocument.RecordId;
        // Set Timeout to prevent the Job Queue from hanging (eg. as a result of a printer dialog).
        JobQueueEntry."Maximum No. of Attempts to Run" := 10;
        JobQueueEntry."Rerun Delay (sec.)" := 5;
        JobQueueEntry.Description :=
          CopyStr(StrSubstNo(OCRSendReceiveDescriptionTxt, IncomingDocument."Entry No."), 1, MaxStrLen(JobQueueEntry.Description));
        JobQueueEntry."Notify On Success" := true;
        CODEUNIT.Run(CODEUNIT::"Job Queue - Enqueue", JobQueueEntry);
        exit(JobQueueEntry.ID);
    end;

    procedure CancelQueueEntry(var IncomingDocument: Record "Incoming Document")
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if IncomingDocument."Job Queue Status" = IncomingDocument."Job Queue Status"::" " then
            exit;
        if not IsNullGuid(IncomingDocument."Job Queue Entry ID") then
            JobQueueEntry.SetRange(ID, IncomingDocument."Job Queue Entry ID");
        JobQueueEntry.SetRange("Record ID to Process", IncomingDocument.RecordId);
        if not JobQueueEntry.IsEmpty() then
            JobQueueEntry.DeleteAll(true);
        IncomingDocument."Job Queue Status" := IncomingDocument."Job Queue Status"::" ";
        IncomingDocument.Modify();
    end;
}

