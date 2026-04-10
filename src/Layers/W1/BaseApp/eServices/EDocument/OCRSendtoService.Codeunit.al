// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using System.Threading;

codeunit 880 "OCR - Send to Service"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    begin
        SendAllReadyToOcr();
    end;

    var
        SendMsg: Label 'Sending to the OCR Service @1@@@@@@@@@@@@@@@@@@@.';
        SendDoneMsg: Label '%1 documents have been sent to the OCR service.', Comment = '%1 is a number, e.g. 1';

    [Scope('OnPrem')]
    procedure SendAllReadyToOcr()
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        TempIncomingDocumentAttachment: Record "Incoming Document Attachment" temporary;
        OCRServiceMgt: Codeunit "OCR Service Mgt.";
        IncDocAttsReadyforOCR: Query "Inc. Doc. Atts. Ready for OCR";
        Window: Dialog;
        NoOfDocuments: Integer;
        i: Integer;
    begin
        if not IncDocAttsReadyforOCR.Open() then
            exit;  // empty

        if GuiAllowed then
            Window.Open(SendMsg);

        // Find Document Count and lock records
        IncomingDocument.LockTable();
        IncomingDocumentAttachment.LockTable();
        while IncDocAttsReadyforOCR.Read() do begin
            NoOfDocuments += 1;
            IncomingDocumentAttachment.Get(IncDocAttsReadyforOCR.Incoming_Document_Entry_No, IncDocAttsReadyforOCR.Line_No);
            IncomingDocument.Get(IncomingDocumentAttachment."Incoming Document Entry No.");  // lock
            TempIncomingDocumentAttachment := IncomingDocumentAttachment;
            TempIncomingDocumentAttachment.Insert();
        end;
        IncDocAttsReadyforOCR.Close();
        // Release locks
        Commit();

        if NoOfDocuments = 0 then
            exit;

        OCRServiceMgt.StartUpload(NoOfDocuments);

        TempIncomingDocumentAttachment.FindSet();
        repeat
            if GuiAllowed then begin
                i += 1;
                Window.Update(1, 10000 * i div NoOfDocuments);
            end;
            IncomingDocument.Get(TempIncomingDocumentAttachment."Incoming Document Entry No.");
            IncomingDocument.SendToOCR(false);
        until TempIncomingDocumentAttachment.Next() = 0;

        Commit();

        if GuiAllowed then begin
            Window.Close();
            Message(SendDoneMsg, NoOfDocuments);
        end;
    end;
}

