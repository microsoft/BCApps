// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using Microsoft.eServices.EDocument.Processing.Interfaces;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Attachment;
using System.IO;
using System.Reflection;
using System.Text;
using System.Utilities;

codeunit 6407 "E-Doc. PEPPOL DX Handler" implements IStructuredFormatReader
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure ReadIntoDraft(EDocument: Record "E-Document"; TempBlob: Codeunit "Temp Blob"): Enum "E-Doc. Process Draft"
    var
        BestDefCode: Code[20];
        BestDocType: Enum "E-Document Type";
    begin
        FindBestDataExchDef(TempBlob, BestDefCode, BestDocType);
        RunPipelineAndBridge(EDocument, TempBlob, BestDefCode);
        exit(MapDocumentTypeToProcessDraft(BestDocType));
    end;

    procedure View(EDocument: Record "E-Document"; TempBlob: Codeunit "Temp Blob")
    begin
        Error('A view is not implemented for this handler.');
    end;

    #region Auto-Detection

    /// <summary>
    /// Determines the v2 Data Exchange Definition code by matching the document's
    /// XML root namespace against known PEPPOL BIS 3.0 namespaces.
    /// </summary>
    local procedure FindBestDataExchDef(var TempBlob: Codeunit "Temp Blob"; var BestDefCode: Code[20]; var BestDocType: Enum "E-Document Type")
    var
        DataExchDef: Record "Data Exch. Def";
        DocumentNamespace: Text;
    begin
        DocumentNamespace := GetDocumentRootNamespace(TempBlob);

        case DocumentNamespace of
            InvoiceNamespaceTxt:
                begin
                    BestDefCode := InvoiceDefCodeTok;
                    BestDocType := "E-Document Type"::"Purchase Invoice";
                end;
            CreditNoteNamespaceTxt:
                begin
                    BestDefCode := CreditMemoDefCodeTok;
                    BestDocType := "E-Document Type"::"Purchase Credit Memo";
                end;
            else
                Error(ProcessFailedErr);
        end;

        if not DataExchDef.Get(BestDefCode) then
            Error(ProcessFailedErr);
    end;

    local procedure GetDocumentRootNamespace(var TempBlob: Codeunit "Temp Blob"): Text
    var
        XmlDoc: XmlDocument;
        RootElement: XmlElement;
        Stream: InStream;
    begin
        TempBlob.CreateInStream(Stream);
        if not XmlDocument.ReadFrom(Stream, XmlDoc) then
            exit('');
        XmlDoc.GetRoot(RootElement);
        exit(RootElement.NamespaceUri());
    end;

    #endregion Auto-Detection

    #region Pipeline and Bridge

    /// <summary>
    /// Runs the full Data Exchange pipeline via ProcessDataExchange, then
    /// bridge-maps intermediate data to v2 staging tables.
    /// The v2 definitions target staging tables (6100/6101) directly and have
    /// no pre-mapping codeunit — conformant with the Data Exchange framework.
    /// </summary>
    local procedure RunPipelineAndBridge(EDocument: Record "E-Document"; var TempBlob: Codeunit "Temp Blob"; DataExchDefCode: Code[20])
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        Stream: InStream;
    begin
        DataExchDef.Get(DataExchDefCode);

        TempBlob.CreateInStream(Stream);
        DataExch.Init();
        DataExch.InsertRec('', Stream, DataExchDef.Code);
        DataExch."Related Record" := EDocument.RecordId;
        DataExch.Modify(true);

        DataExchDef.ProcessDataExchange(DataExch);

        BridgeToStagingTables(EDocument, DataExch);
        DeleteIntermediateData(DataExch);
    end;

    local procedure BridgeToStagingTables(EDocument: Record "E-Document"; DataExch: Record "Data Exch.")
    var
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
    begin
        EDocumentPurchaseHeader.InsertForEDocument(EDocument);

        MapIntermediateToHeader(DataExch, EDocumentPurchaseHeader);
        PostProcessHeader(EDocumentPurchaseHeader);
        EDocumentPurchaseHeader.Modify();

        MapIntermediateToLines(EDocument, DataExch);
        ProcessAttachments(EDocument, DataExch);

        OnAfterBridgeToStagingTables(DataExch."Entry No.", EDocumentPurchaseHeader);
    end;

    #endregion Pipeline and Bridge

    #region Header Mapping

    /// <summary>
    /// Reads intermediate data targeting table 6100 (E-Document Purchase Header)
    /// and assigns values to the staging record using the configured field mappings.
    /// </summary>
    local procedure MapIntermediateToHeader(DataExch: Record "Data Exch."; var EDocumentPurchaseHeader: Record "E-Document Purchase Header")
    var
        IntermediateDataImport: Record "Intermediate Data Import";
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        FieldValue: Text;
    begin
        IntermediateDataImport.SetRange("Data Exch. No.", DataExch."Entry No.");
        IntermediateDataImport.SetRange("Table ID", Database::"E-Document Purchase Header");
        IntermediateDataImport.SetRange("Parent Record No.", 0);
        if not IntermediateDataImport.FindSet() then
            exit;

        RecordRef.GetTable(EDocumentPurchaseHeader);
        repeat
            if RecordRef.FieldExist(IntermediateDataImport."Field ID") then begin
                FieldRef := RecordRef.Field(IntermediateDataImport."Field ID");
                FieldValue := CopyStr(IntermediateDataImport.GetValue(), 1, GetFieldMaxLength(FieldRef));
                if FieldValue <> '' then
                    AssignFieldValue(FieldRef, FieldValue);
            end;
        until IntermediateDataImport.Next() = 0;
        RecordRef.SetTable(EDocumentPurchaseHeader);
    end;

    /// <summary>
    /// Post-processes header fields that cannot be handled by Data Exchange alone:
    /// - Total VAT: calculated from Total - Sub Total - Total Discount
    /// - Amount Due: copied from Total
    /// - Currency Code: LCY-blank convention
    /// </summary>
    local procedure PostProcessHeader(var EDocumentPurchaseHeader: Record "E-Document Purchase Header")
    begin
        EDocumentPurchaseHeader."Total VAT" := EDocumentPurchaseHeader.Total - EDocumentPurchaseHeader."Sub Total" - EDocumentPurchaseHeader."Total Discount";
        EDocumentPurchaseHeader."Amount Due" := EDocumentPurchaseHeader.Total;
        ApplyLCYBlankConvention(EDocumentPurchaseHeader."Currency Code");
    end;

    #endregion Header Mapping

    #region Line Mapping

    /// <summary>
    /// Reads intermediate data targeting table 6101 (E-Document Purchase Line)
    /// and creates staging line records. Each distinct Record No. in intermediate
    /// data becomes a separate staging line.
    /// </summary>
    local procedure MapIntermediateToLines(EDocument: Record "E-Document"; DataExch: Record "Data Exch.")
    var
        IntermediateDataImport: Record "Intermediate Data Import";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        FieldValue: Text;
        CurrRecordNo: Integer;
    begin
        IntermediateDataImport.SetRange("Data Exch. No.", DataExch."Entry No.");
        IntermediateDataImport.SetRange("Table ID", Database::"E-Document Purchase Line");
        IntermediateDataImport.SetCurrentKey("Record No.");

        if not IntermediateDataImport.FindSet() then
            exit;

        CurrRecordNo := -1;
        repeat
            if CurrRecordNo <> IntermediateDataImport."Record No." then begin
                if CurrRecordNo <> -1 then begin
                    RecordRef.SetTable(EDocumentPurchaseLine);
                    PostProcessLine(EDocumentPurchaseLine);
                    EDocumentPurchaseLine.Insert();
                    OnAfterMapLineToStaging(DataExch."Entry No.", CurrRecordNo, EDocumentPurchaseLine);
                end;

                Clear(EDocumentPurchaseLine);
                EDocumentPurchaseLine."E-Document Entry No." := EDocument."Entry No";
                EDocumentPurchaseLine."Line No." := EDocumentPurchaseLine.GetNextLineNo(EDocument."Entry No");
                RecordRef.GetTable(EDocumentPurchaseLine);
                CurrRecordNo := IntermediateDataImport."Record No.";
            end;

            if RecordRef.FieldExist(IntermediateDataImport."Field ID") then begin
                FieldRef := RecordRef.Field(IntermediateDataImport."Field ID");
                FieldValue := CopyStr(IntermediateDataImport.GetValue(), 1, GetFieldMaxLength(FieldRef));
                if FieldValue <> '' then
                    AssignFieldValue(FieldRef, FieldValue);
                RecordRef.SetTable(EDocumentPurchaseLine);
                RecordRef.GetTable(EDocumentPurchaseLine);
            end;
        until IntermediateDataImport.Next() = 0;

        // Insert last line
        RecordRef.SetTable(EDocumentPurchaseLine);
        PostProcessLine(EDocumentPurchaseLine);
        EDocumentPurchaseLine.Insert();
        OnAfterMapLineToStaging(DataExch."Entry No.", CurrRecordNo, EDocumentPurchaseLine);
    end;

    local procedure PostProcessLine(var EDocumentPurchaseLine: Record "E-Document Purchase Line")
    begin
        ApplyLCYBlankConvention(EDocumentPurchaseLine."Currency Code");
    end;

    #endregion Line Mapping

    #region Attachment Processing

    local procedure ProcessAttachments(EDocument: Record "E-Document"; DataExch: Record "Data Exch.")
    var
        DocumentAttachment: Record "Document Attachment";
        IntermediateDataImport: Record "Intermediate Data Import";
        EDocAttachmentProcessor: Codeunit "E-Doc. Attachment Processor";
        AttachmentTempBlob: Codeunit "Temp Blob";
        Base64Convert: Codeunit "Base64 Convert";
        InStream: InStream;
        OutStream: OutStream;
        FileName: Text;
        Base64Data: Text;
        CurrRecordNo: Integer;
    begin
        IntermediateDataImport.SetRange("Data Exch. No.", DataExch."Entry No.");
        IntermediateDataImport.SetRange("Table ID", Database::"Document Attachment");
        IntermediateDataImport.SetCurrentKey("Record No.");

        if not IntermediateDataImport.FindSet() then
            exit;

        CurrRecordNo := -1;
        repeat
            if CurrRecordNo <> IntermediateDataImport."Record No." then begin
                if CurrRecordNo <> -1 then
                    if FileName <> '' then begin
                        AttachmentTempBlob.CreateInStream(InStream);
                        EDocAttachmentProcessor.Insert(EDocument, InStream, FileName);
                        FileName := '';
                    end;
                CurrRecordNo := IntermediateDataImport."Record No.";
            end;

            case IntermediateDataImport."Field ID" of
                DocumentAttachment.FieldNo("File Name"):
                    FileName := IntermediateDataImport.Value;
                DocumentAttachment.FieldNo("Document Reference ID"):
                    begin
                        IntermediateDataImport.CalcFields("Value BLOB");
                        Base64Data := IntermediateDataImport.GetValue();
                        AttachmentTempBlob.CreateOutStream(OutStream);
                        Base64Convert.FromBase64(Base64Data, OutStream);
                    end;
            end;
        until IntermediateDataImport.Next() = 0;

        if FileName <> '' then begin
            AttachmentTempBlob.CreateInStream(InStream);
            EDocAttachmentProcessor.Insert(EDocument, InStream, FileName);
        end;
    end;

    #endregion Attachment Processing

    #region Field Value Helpers

    local procedure AssignFieldValue(var FieldRef: FieldRef; FieldValue: Text)
    var
        DateVar: Date;
        DecimalVar: Decimal;
    begin
        case FieldRef.Type of
            FieldType::Text, FieldType::Code:
                FieldRef.Value := CopyStr(FieldValue, 1, FieldRef.Length);
            FieldType::Date:
                if Evaluate(DateVar, FieldValue, 9) then
                    FieldRef.Value := DateVar;
            FieldType::Decimal:
                if Evaluate(DecimalVar, FieldValue, 9) then
                    FieldRef.Value := DecimalVar;
        end;
    end;

    local procedure GetFieldMaxLength(FieldRef: FieldRef): Integer
    begin
        if FieldRef.Type in [FieldType::Text, FieldType::Code] then
            exit(FieldRef.Length);
        exit(250);
    end;

    /// <summary>
    /// BC convention: blank Currency Code means LCY. Blanks the field when it matches LCY.
    /// </summary>
    local procedure ApplyLCYBlankConvention(var CurrencyCode: Code[10])
    var
        GLSetup: Record "General Ledger Setup";
    begin
        if CurrencyCode = '' then
            exit;

        GLSetup.GetRecordOnce();
        if GLSetup."LCY Code" = CurrencyCode then
            CurrencyCode := '';
    end;

    #endregion Field Value Helpers

    #region Document Type Mapping

    local procedure MapDocumentTypeToProcessDraft(DocumentType: Enum "E-Document Type"): Enum "E-Doc. Process Draft"
    begin
        case DocumentType of
            DocumentType::"Purchase Invoice":
                exit(Enum::"E-Doc. Process Draft"::"Purchase Invoice");
            DocumentType::"Purchase Credit Memo":
                exit(Enum::"E-Doc. Process Draft"::"Purchase Credit Memo");
            else
                exit(Enum::"E-Doc. Process Draft"::"Purchase Invoice");
        end;
    end;

    #endregion Document Type Mapping

    #region Cleanup

    local procedure DeleteIntermediateData(DataExch: Record "Data Exch.")
    var
        DataExchField: Record "Data Exch. Field";
        IntermediateDataImport: Record "Intermediate Data Import";
    begin
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        DataExchField.DeleteAll();
        IntermediateDataImport.SetRange("Data Exch. No.", DataExch."Entry No.");
        IntermediateDataImport.DeleteAll();
    end;

    #endregion Cleanup

    #region Integration Events

    [IntegrationEvent(false, false)]
    local procedure OnAfterBridgeToStagingTables(DataExchNo: Integer; var EDocumentPurchaseHeader: Record "E-Document Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMapLineToStaging(DataExchNo: Integer; RecordNo: Integer; var EDocumentPurchaseLine: Record "E-Document Purchase Line")
    begin
    end;

    #endregion Integration Events

    var
        InvoiceDefCodeTok: Label 'EDOCPEPPOLINVIMPV2', Locked = true;
        CreditMemoDefCodeTok: Label 'EDOCPEPPOLCRMEMOIMPV2', Locked = true;
        InvoiceNamespaceTxt: Label 'urn:oasis:names:specification:ubl:schema:xsd:Invoice-2', Locked = true;
        CreditNoteNamespaceTxt: Label 'urn:oasis:names:specification:ubl:schema:xsd:CreditNote-2', Locked = true;
        ProcessFailedErr: Label 'Failed to process the file with data exchange.';
}
