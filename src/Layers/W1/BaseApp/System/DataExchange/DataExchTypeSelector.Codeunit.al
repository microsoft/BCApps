namespace System.IO;

using Microsoft.EServices.EDocument;

codeunit 1215 "Data Exch. Type Selector"
{
    Permissions = TableData "Data Exch." = rimd;
    TableNo = "Incoming Document Attachment";

    trigger OnRun()
    var
        BestDataExchCode: Code[20];
    begin
        if Rec.Type <> Rec.Type::XML then
            Error(InvalidTypeErr);

        CheckContentHasValue(Rec);

        BestDataExchCode := FindDataExchType(Rec);

        SetResult(Rec."Incoming Document Entry No.", BestDataExchCode);
    end;

    var
        InvalidTypeErr: Label 'The attachment is not an XML document.';
        AttachmentEmptyErr: Label 'The attachment does not contain any data.';

    local procedure FindDataExchType(IncomingDocumentAttachment: Record "Incoming Document Attachment"): Code[20]
    var
        DataExch: Record "Data Exch.";
        DataExchangeType: Record "Data Exchange Type";
        DataExchDef: Record "Data Exch. Def";
        IntermediateDataImport: Record "Intermediate Data Import";
        BestDataExchCode: Code[20];
        BestDataExchValue: Integer;
    begin
        BestDataExchValue := 0;
        if DataExchangeType.FindSet() then
            repeat
                if DataExchDefUsesIntermediate(DataExchangeType."Data Exch. Def. Code") then begin
                    DataExchDef.Get(DataExchangeType."Data Exch. Def. Code");
                    CreateDataExch(DataExch, DataExchDef, IncomingDocumentAttachment);
                    // Create Intermediate table records for each Data Exchange Type
                    if TryCreateIntermediate(DataExch, DataExchDef) then begin
                        IntermediateDataImport.SetRange("Data Exch. No.", DataExch."Entry No.");

                        // Update best result if this one is better
                        if IntermediateDataImport.Count > BestDataExchValue then begin
                            BestDataExchCode := DataExchDef.Code;
                            BestDataExchValue := IntermediateDataImport.Count();
                        end;

                        IntermediateDataImport.DeleteAll(true); // cleanup
                    end;
                    DataExch.Delete(true); // cleanup
                end;
            until DataExchangeType.Next() = 0;

        exit(BestDataExchCode);
    end;

    local procedure CreateDataExch(var DataExch: Record "Data Exch."; DataExchDef: Record "Data Exch. Def"; IncomingDocumentAttachment: Record "Incoming Document Attachment")
    var
        Stream: InStream;
    begin
        IncomingDocumentAttachment.Content.CreateInStream(Stream);

        DataExch.Init();
        DataExch.InsertRec(IncomingDocumentAttachment.Name, Stream, DataExchDef.Code);
        DataExch.Validate("Incoming Entry No.", IncomingDocumentAttachment."Incoming Document Entry No.");
        DataExch.Modify(true);
    end;

    local procedure TryCreateIntermediate(DataExch: Record "Data Exch."; DataExchDef: Record "Data Exch. Def"): Boolean
    begin
        Commit();
        if DataExchDef."Reading/Writing Codeunit" <> 0 then begin
            if not CODEUNIT.Run(DataExchDef."Reading/Writing Codeunit", DataExch) then
                exit(false);

            if DataExchDef."Data Handling Codeunit" <> 0 then
                if not CODEUNIT.Run(DataExchDef."Data Handling Codeunit", DataExch) then
                    exit(false);
            exit(true);
        end;
        exit(false);
    end;

    local procedure SetResult(IncomingDocCode: Integer; DataExchTypeCode: Code[20])
    var
        DataExchangeType: Record "Data Exchange Type";
        IncomingDocument: Record "Incoming Document";
    begin
        if DataExchTypeCode = '' then
            exit;

        DataExchangeType.SetRange("Data Exch. Def. Code", DataExchTypeCode);
        DataExchangeType.FindFirst();

        IncomingDocument.Get(IncomingDocCode);
        IncomingDocument.Validate("Data Exchange Type", DataExchangeType.Code);
        IncomingDocument.Modify(true);
    end;

    local procedure CheckContentHasValue(var IncomingDocumentAttachment: Record "Incoming Document Attachment")
    var
        LiveIncomingDocumentAttachment: Record "Incoming Document Attachment";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckContentHasValue(IncomingDocumentAttachment, IsHandled);
        if IsHandled then
            exit;

        // Is the data already loaded or is it in the db?
        LiveIncomingDocumentAttachment := IncomingDocumentAttachment;
        LiveIncomingDocumentAttachment.CalcFields(Content);
        if LiveIncomingDocumentAttachment.Content.HasValue() then
            IncomingDocumentAttachment.CalcFields(Content);

        if not IncomingDocumentAttachment.Content.HasValue() then
            Error(AttachmentEmptyErr);
    end;

    local procedure DataExchDefUsesIntermediate(DataExchDefCode: Code[20]): Boolean
    var
        DataExchMapping: Record "Data Exch. Mapping";
    begin
        // Ensure that the data exch def uses the intermediate table so we don't just start inserting data into the db.
        DataExchMapping.SetRange("Data Exch. Def Code", DataExchDefCode);
        DataExchMapping.SetRange("Use as Intermediate Table", false);
        exit(not DataExchMapping.FindFirst());
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckContentHasValue(var IncomingDocumentAttachment: Record "Incoming Document Attachment"; var IsHandled: Boolean)
    begin
    end;
}

