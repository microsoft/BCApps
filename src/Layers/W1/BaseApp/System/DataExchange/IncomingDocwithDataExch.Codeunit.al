namespace System.IO;

using Microsoft.EServices.EDocument;
using System.Utilities;

codeunit 1216 "Incoming Doc. with Data. Exch."
{
    Permissions = TableData "Data Exch." = im;
    TableNo = "Incoming Document";

    trigger OnRun()
    begin
        ProcessWithDataExch(Rec);
        RollbackIfErrors(Rec);

        Rec.Get(Rec."Entry No.");
    end;

    var
        AttachmentErr: Label 'You must select a file.';
        AttachmentEmptyErr: Label 'The file is empty.';
        SourceErr: Label 'Failed to prepare the file for data exchange.';
        ProcessFailedErr: Label 'Failed to process the file with data exchange.';

    local procedure ProcessWithDataExch(IncomingDocument: Record "Incoming Document")
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchangeType: Record "Data Exchange Type";
    begin
        DataExch.Init();
        DataExchangeType.Get(IncomingDocument."Data Exchange Type");
        DataExchDef.Get(DataExchangeType."Data Exch. Def. Code");

        if not SetSourceForDataExch(IncomingDocument, DataExch, DataExchDef) then
            Error(SourceErr);

        DataExch."Related Record" := IncomingDocument.RecordId;
        if not DataExch.ImportToDataExch(DataExchDef) then
            Error(ProcessFailedErr);

        DataExchDef.ProcessDataExchange(DataExch);
    end;

    local procedure SetSourceForDataExch(IncomingDocument: Record "Incoming Document"; var DataExch: Record "Data Exch."; DataExchDef: Record "Data Exch. Def") Result: Boolean
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        Stream: InStream;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetSourceForDataExch(IncomingDocument, DataExch, DataExchDef, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if DataExchDef."Ext. Data Handling Codeunit" <> 0 then begin
            DataExch."Related Record" := IncomingDocument.RecordId;
            exit(DataExch.ImportFileContent(DataExchDef))
        end;

        // if no external data handling, use the attachments
        IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");
        IncomingDocumentAttachment.SetRange(Default, true);
        if not IncomingDocumentAttachment.FindFirst() then
            Error(AttachmentErr);

        IncomingDocumentAttachment.CalcFields(Content);
        if not IncomingDocumentAttachment.Content.HasValue() then
            Error(AttachmentEmptyErr);

        IncomingDocumentAttachment.Content.CreateInStream(Stream);
        DataExch.InsertRec(IncomingDocumentAttachment.Name, Stream, DataExchDef.Code);
        DataExch.Validate("Incoming Entry No.", IncomingDocument."Entry No.");
        DataExch.Modify(true);

        exit(true);
    end;

    local procedure RollbackIfErrors(var IncomingDocument: Record "Incoming Document")
    var
        ErrorMessage: Record "Error Message";
        TempErrorMessage: Record "Error Message" temporary;
    begin
        ErrorMessage.SetContext(IncomingDocument);
        if not ErrorMessage.HasErrors(false) then
            exit;

        // rollback if processing errors - preserve the errors
        ErrorMessage.SetRange("Context Record ID", IncomingDocument.RecordId);
        ErrorMessage.CopyToTemp(TempErrorMessage);
        IncomingDocument.SaveErrorMessages(TempErrorMessage);

        // force rollback (errors will be restored in IncomingDocument)
        Error('');
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetSourceForDataExch(IncomingDocument: Record "Incoming Document"; var DataExch: Record "Data Exch."; DataExchDef: Record "Data Exch. Def"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}

