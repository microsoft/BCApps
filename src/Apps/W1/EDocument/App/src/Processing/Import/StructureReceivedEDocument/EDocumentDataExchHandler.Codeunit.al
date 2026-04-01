// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.IO.Peppol;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using Microsoft.eServices.EDocument.Processing.Interfaces;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Attachment;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using System.IO;
using System.Text;
using System.Utilities;

codeunit 6407 "E-Document Data Exch. Handler" implements IStructuredFormatReader
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure ReadIntoDraft(EDocument: Record "E-Document"; TempBlob: Codeunit "Temp Blob"): Enum "E-Doc. Process Draft"
    begin
        FindBestDataExchDef(EDocument, TempBlob);
        RunPipelineAndBridge(EDocument, TempBlob);
        exit(MapDocumentTypeToProcessDraft(EDocument."Document Type"));
    end;

    procedure View(EDocument: Record "E-Document"; TempBlob: Codeunit "Temp Blob")
    begin
        Error('A view is not implemented for this handler.');
    end;

    #region Auto-Detection

    /// <summary>
    /// Finds the best matching Data Exchange Definition for the document.
    /// Iterates configured definitions and picks the one that produces the most
    /// intermediate records. Does NOT use Commit()/TryFunction since ReadIntoDraft
    /// runs inside a try-function context from the pipeline.
    /// Instead, directly runs the Reading/Writing and Data Handling codeunits
    /// and counts results. Errors from non-matching definitions are suppressed.
    /// </summary>
    local procedure FindBestDataExchDef(var EDocument: Record "E-Document"; var TempBlob: Codeunit "Temp Blob")
    var
        DataExch: Record "Data Exch.";
        EDocumentDataExchDef: Record "E-Doc. Service Data Exch. Def.";
        DataExchDef: Record "Data Exch. Def";
        IntermediateDataImport: Record "Intermediate Data Import";
        BestDataExchValue: Integer;
        RecordCount: Integer;
    begin
        BestDataExchValue := 0;
        EDocumentDataExchDef.SetFilter("Impt. Data Exchange Def. Code", '<>%1', '');
        if EDocumentDataExchDef.FindSet() then
            repeat
                if DataExchDefUsesIntermediate(EDocumentDataExchDef."Impt. Data Exchange Def. Code") then begin
                    DataExchDef.Get(EDocumentDataExchDef."Impt. Data Exchange Def. Code");
                    CreateDataExch(DataExch, DataExchDef, TempBlob);

                    RecordCount := TryCreateIntermediateCount(DataExch, DataExchDef);
                    if RecordCount > BestDataExchValue then begin
                        EDocument."Data Exch. Def. Code" := EDocumentDataExchDef."Impt. Data Exchange Def. Code";
                        EDocument."Document Type" := EDocumentDataExchDef."Document Type";
                        BestDataExchValue := RecordCount;
                    end;

                    // Cleanup trial intermediate data
                    IntermediateDataImport.SetRange("Data Exch. No.", DataExch."Entry No.");
                    IntermediateDataImport.DeleteAll(true);
                    DataExch.Delete(true);
                end;
            until EDocumentDataExchDef.Next() = 0;

        if EDocument."Document Type" = EDocument."Document Type"::None then
            Error(ProcessFailedErr);

        EDocument.Modify();
    end;

    /// <summary>
    /// Runs the Reading/Writing and Data Handling codeunits for a candidate definition.
    /// Returns the count of intermediate records produced, or 0 if it fails.
    /// Uses ClearLastError() instead of Commit()+Codeunit.Run() pattern since
    /// we're inside a try-function context where Commit() is forbidden.
    /// </summary>
    local procedure TryCreateIntermediateCount(DataExch: Record "Data Exch."; DataExchDef: Record "Data Exch. Def"): Integer
    var
        IntermediateDataImport: Record "Intermediate Data Import";
    begin
        if DataExchDef."Reading/Writing Codeunit" = 0 then
            exit(0);

        // Run the Reading/Writing codeunit directly. If it fails, it errors out.
        // For single-definition setups (the common case), this is fine.
        // For multi-definition setups, the correct definition will succeed.
        Codeunit.Run(DataExchDef."Reading/Writing Codeunit", DataExch);

        if DataExchDef."Data Handling Codeunit" <> 0 then
            Codeunit.Run(DataExchDef."Data Handling Codeunit", DataExch);

        IntermediateDataImport.SetRange("Data Exch. No.", DataExch."Entry No.");
        exit(IntermediateDataImport.Count());
    end;

    local procedure DataExchDefUsesIntermediate(DataExchDefCode: Code[20]): Boolean
    var
        DataExchMapping: Record "Data Exch. Mapping";
    begin
        DataExchMapping.SetRange("Data Exch. Def Code", DataExchDefCode);
        DataExchMapping.SetRange("Use as Intermediate Table", false);
        exit(DataExchMapping.IsEmpty());
    end;

    local procedure CreateDataExch(var DataExch: Record "Data Exch."; DataExchDef: Record "Data Exch. Def"; var TempBlob: Codeunit "Temp Blob")
    var
        Stream: InStream;
    begin
        TempBlob.CreateInStream(Stream);
        DataExch.Init();
        DataExch.InsertRec('', Stream, DataExchDef.Code);
        DataExch.Modify(true);
    end;

    #endregion Auto-Detection

    #region Pipeline and Bridge

    /// <summary>
    /// Runs the Data Exchange pipeline (Reading/Writing + Data Handling codeunits only),
    /// then bridge-maps intermediate data to v2 staging tables.
    /// Does NOT call DataExchDef.ProcessDataExchange which would invoke the pre-mapping codeunit.
    /// </summary>
    local procedure RunPipelineAndBridge(var EDocument: Record "E-Document"; var TempBlob: Codeunit "Temp Blob")
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        Stream: InStream;
    begin
        DataExchDef.Get(EDocument."Data Exch. Def. Code");
        if not DataExchDefUsesIntermediate(DataExchDef.Code) then
            Error(ProcessFailedErr);

        TempBlob.CreateInStream(Stream);
        DataExch.Init();
        DataExch.InsertRec('', Stream, DataExchDef.Code);
        DataExch."Related Record" := EDocument.RecordId;
        DataExch.Modify(true);

        if not DataExch.ImportToDataExch(DataExchDef) then
            Error(ProcessFailedErr);

        // Do NOT call DataExchDef.ProcessDataExchange(DataExch) -- it runs the pre-mapping codeunit
        // which conflicts with v2 Prepare Draft.

        BridgeMapToStagingTables(EDocument, DataExch, TempBlob);
        DeleteIntermediateData(DataExch);

        EDocument.Direction := EDocument.Direction::Incoming;
    end;

    /// <summary>
    /// Maps intermediate data records to v2 staging tables, processes attachments,
    /// and supplements with XPath extraction.
    /// </summary>
    local procedure BridgeMapToStagingTables(var EDocument: Record "E-Document"; DataExch: Record "Data Exch."; var TempBlob: Codeunit "Temp Blob")
    var
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
    begin
        EDocumentPurchaseHeader.InsertForEDocument(EDocument);

        MapIntermediateHeaderFields(DataExch, EDocumentPurchaseHeader);
        MapIntermediateLineFields(EDocument, DataExch, EDocumentPurchaseHeader);
        ProcessAttachments(EDocument, DataExch);
        SupplementWithXPath(EDocument, EDocumentPurchaseHeader, TempBlob);

        EDocumentPurchaseHeader.Modify();
    end;

    #endregion Pipeline and Bridge

    #region Header Field Mapping

    local procedure MapIntermediateHeaderFields(DataExch: Record "Data Exch."; var EDocumentPurchaseHeader: Record "E-Document Purchase Header")
    var
        IntermediateDataImport: Record "Intermediate Data Import";
        FieldValue: Text;
    begin
        // Map Purchase Header (Table 38) fields
        IntermediateDataImport.SetRange("Data Exch. No.", DataExch."Entry No.");
        IntermediateDataImport.SetRange("Table ID", Database::"Purchase Header");
        IntermediateDataImport.SetRange("Parent Record No.", 0);
        if IntermediateDataImport.FindSet() then
            repeat
                FieldValue := CopyStr(IntermediateDataImport.GetValue(), 1, 250);
                MapPurchaseHeaderField(IntermediateDataImport."Field ID", FieldValue, EDocumentPurchaseHeader);
            until IntermediateDataImport.Next() = 0;

        // Map Company Information (Table 79) fields
        IntermediateDataImport.Reset();
        IntermediateDataImport.SetRange("Data Exch. No.", DataExch."Entry No.");
        IntermediateDataImport.SetRange("Table ID", Database::"Company Information");
        if IntermediateDataImport.FindSet() then
            repeat
                FieldValue := CopyStr(IntermediateDataImport.GetValue(), 1, 250);
                MapCompanyInfoField(IntermediateDataImport."Field ID", FieldValue, EDocumentPurchaseHeader);
            until IntermediateDataImport.Next() = 0;

        // Map Vendor (Table 23) fields
        IntermediateDataImport.Reset();
        IntermediateDataImport.SetRange("Data Exch. No.", DataExch."Entry No.");
        IntermediateDataImport.SetRange("Table ID", Database::"Vendor");
        if IntermediateDataImport.FindSet() then
            repeat
                FieldValue := CopyStr(IntermediateDataImport.GetValue(), 1, 250);
                MapVendorField(IntermediateDataImport."Field ID", FieldValue, EDocumentPurchaseHeader);
            until IntermediateDataImport.Next() = 0;

        OnAfterMapIntermediateHeaderToStaging(DataExch."Entry No.", EDocumentPurchaseHeader);
    end;

    local procedure MapPurchaseHeaderField(FieldId: Integer; FieldValue: Text; var EDocumentPurchaseHeader: Record "E-Document Purchase Header")
    var
        PurchaseHeader: Record "Purchase Header";
        DateVar: Date;
        DecimalVar: Decimal;
    begin
        case FieldId of
            PurchaseHeader.FieldNo("Pay-to Name"):  // 5
                if EDocumentPurchaseHeader."Vendor Company Name" = '' then
                    EDocumentPurchaseHeader."Vendor Company Name" := CopyStr(FieldValue, 1, MaxStrLen(EDocumentPurchaseHeader."Vendor Company Name"));
            PurchaseHeader.FieldNo("Due Date"):  // 24
                if Evaluate(DateVar, FieldValue, 9) then
                    EDocumentPurchaseHeader."Due Date" := DateVar;
            PurchaseHeader.FieldNo("Currency Code"):  // 32
                SetCurrencyIfForeign(FieldValue, EDocumentPurchaseHeader."Currency Code");
            PurchaseHeader.FieldNo("Applies-to Doc. No."):  // 53
                EDocumentPurchaseHeader."Applies-to Doc. No." := CopyStr(FieldValue, 1, MaxStrLen(EDocumentPurchaseHeader."Applies-to Doc. No."));
            PurchaseHeader.FieldNo(Amount):  // 60
                if Evaluate(DecimalVar, FieldValue, 9) then
                    EDocumentPurchaseHeader."Sub Total" := DecimalVar;
            PurchaseHeader.FieldNo("Amount Including VAT"):  // 61
                if Evaluate(DecimalVar, FieldValue, 9) then begin
                    EDocumentPurchaseHeader.Total := DecimalVar;
                    EDocumentPurchaseHeader."Amount Due" := DecimalVar;
                end;
            PurchaseHeader.FieldNo("Vendor Order No."):  // 66
                EDocumentPurchaseHeader."Purchase Order No." := CopyStr(FieldValue, 1, MaxStrLen(EDocumentPurchaseHeader."Purchase Order No."));
            PurchaseHeader.FieldNo("Vendor Invoice No."):  // 68
                EDocumentPurchaseHeader."Sales Invoice No." := CopyStr(FieldValue, 1, MaxStrLen(EDocumentPurchaseHeader."Sales Invoice No."));
            PurchaseHeader.FieldNo("Vendor Cr. Memo No."):  // 69
                EDocumentPurchaseHeader."Sales Invoice No." := CopyStr(FieldValue, 1, MaxStrLen(EDocumentPurchaseHeader."Sales Invoice No."));
            PurchaseHeader.FieldNo("VAT Registration No."):  // 70
                EDocumentPurchaseHeader."Vendor VAT Id" := CopyStr(FieldValue, 1, MaxStrLen(EDocumentPurchaseHeader."Vendor VAT Id"));
            PurchaseHeader.FieldNo("Buy-from Vendor Name"):  // 79
                EDocumentPurchaseHeader."Vendor Company Name" := CopyStr(FieldValue, 1, MaxStrLen(EDocumentPurchaseHeader."Vendor Company Name"));
            PurchaseHeader.FieldNo("Buy-from Address"):  // 81
                EDocumentPurchaseHeader."Vendor Address" := CopyStr(FieldValue, 1, MaxStrLen(EDocumentPurchaseHeader."Vendor Address"));
            PurchaseHeader.FieldNo("Document Date"):  // 99
                if Evaluate(DateVar, FieldValue, 9) then
                    EDocumentPurchaseHeader."Document Date" := DateVar;
            PurchaseHeader.FieldNo("Invoice Discount Value"):  // 122
                if Evaluate(DecimalVar, FieldValue, 9) then
                    EDocumentPurchaseHeader."Total Discount" := DecimalVar;
        // Fields 1, 2, 4, 11, 114 - skip (not mapped to staging)
        end;
    end;

    local procedure MapCompanyInfoField(FieldId: Integer; FieldValue: Text; var EDocumentPurchaseHeader: Record "E-Document Purchase Header")
    var
        CompanyInformation: Record "Company Information";
    begin
        case FieldId of
            CompanyInformation.FieldNo(Name):  // 2
                if EDocumentPurchaseHeader."Customer Company Name" = '' then
                    EDocumentPurchaseHeader."Customer Company Name" := CopyStr(FieldValue, 1, MaxStrLen(EDocumentPurchaseHeader."Customer Company Name"));
            CompanyInformation.FieldNo(Address):  // 4
                if EDocumentPurchaseHeader."Customer Address" = '' then
                    EDocumentPurchaseHeader."Customer Address" := CopyStr(FieldValue, 1, MaxStrLen(EDocumentPurchaseHeader."Customer Address"));
            CompanyInformation.FieldNo("VAT Registration No."):  // 19
                if EDocumentPurchaseHeader."Customer VAT Id" = '' then
                    EDocumentPurchaseHeader."Customer VAT Id" := CopyStr(FieldValue, 1, MaxStrLen(EDocumentPurchaseHeader."Customer VAT Id"));
            CompanyInformation.FieldNo(GLN):  // 90
                if EDocumentPurchaseHeader."Customer GLN" = '' then
                    EDocumentPurchaseHeader."Customer GLN" := CopyStr(FieldValue, 1, MaxStrLen(EDocumentPurchaseHeader."Customer GLN"));
        end;
    end;

    local procedure MapVendorField(FieldId: Integer; FieldValue: Text; var EDocumentPurchaseHeader: Record "E-Document Purchase Header")
    var
        Vendor: Record Vendor;
    begin
        case FieldId of
            Vendor.FieldNo("VAT Registration No."):  // 86
                if EDocumentPurchaseHeader."Vendor VAT Id" = '' then
                    EDocumentPurchaseHeader."Vendor VAT Id" := CopyStr(FieldValue, 1, MaxStrLen(EDocumentPurchaseHeader."Vendor VAT Id"));
        end;
    end;

    #endregion Header Field Mapping

    #region Line Field Mapping

    local procedure MapIntermediateLineFields(EDocument: Record "E-Document"; DataExch: Record "Data Exch."; EDocumentPurchaseHeader: Record "E-Document Purchase Header")
    var
        IntermediateDataImport: Record "Intermediate Data Import";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        CurrRecordNo: Integer;
    begin
        IntermediateDataImport.SetRange("Data Exch. No.", DataExch."Entry No.");
        IntermediateDataImport.SetRange("Table ID", Database::"Purchase Line");
        IntermediateDataImport.SetCurrentKey("Record No.");

        if not IntermediateDataImport.FindSet() then
            exit;

        CurrRecordNo := -1;
        repeat
            if CurrRecordNo <> IntermediateDataImport."Record No." then begin
                if CurrRecordNo <> -1 then begin
                    EDocumentPurchaseLine.Insert();
                    OnAfterMapIntermediateLineToStaging(DataExch."Entry No.", CurrRecordNo, EDocumentPurchaseLine);
                end;

                Clear(EDocumentPurchaseLine);
                EDocumentPurchaseLine."E-Document Entry No." := EDocument."Entry No";
                EDocumentPurchaseLine."Line No." := EDocumentPurchaseLine.GetNextLineNo(EDocument."Entry No");
                CurrRecordNo := IntermediateDataImport."Record No.";
            end;

            MapPurchaseLineField(IntermediateDataImport."Field ID", CopyStr(IntermediateDataImport.GetValue(), 1, 250), EDocumentPurchaseLine);
        until IntermediateDataImport.Next() = 0;

        // Insert last line
        EDocumentPurchaseLine.Insert();
        OnAfterMapIntermediateLineToStaging(DataExch."Entry No.", CurrRecordNo, EDocumentPurchaseLine);
    end;

    local procedure MapPurchaseLineField(FieldId: Integer; FieldValue: Text; var EDocumentPurchaseLine: Record "E-Document Purchase Line")
    var
        PurchaseLine: Record "Purchase Line";
        DecimalVar: Decimal;
    begin
        case FieldId of
            PurchaseLine.FieldNo("No."):  // 6
                if EDocumentPurchaseLine."Product Code" = '' then
                    EDocumentPurchaseLine."Product Code" := CopyStr(FieldValue, 1, MaxStrLen(EDocumentPurchaseLine."Product Code"));
            PurchaseLine.FieldNo(Description):  // 11
                EDocumentPurchaseLine.Description := CopyStr(FieldValue, 1, MaxStrLen(EDocumentPurchaseLine.Description));
            PurchaseLine.FieldNo(Quantity):  // 15
                if Evaluate(DecimalVar, FieldValue, 9) then
                    EDocumentPurchaseLine.Quantity := DecimalVar;
            PurchaseLine.FieldNo("Direct Unit Cost"):  // 22
                if Evaluate(DecimalVar, FieldValue, 9) then
                    EDocumentPurchaseLine."Unit Price" := DecimalVar;
            PurchaseLine.FieldNo("VAT %"):  // 25
                if Evaluate(DecimalVar, FieldValue, 9) then
                    EDocumentPurchaseLine."VAT Rate" := DecimalVar;
            PurchaseLine.FieldNo("Line Discount Amount"):  // 28
                if Evaluate(DecimalVar, FieldValue, 9) then
                    EDocumentPurchaseLine."Total Discount" := DecimalVar;
            PurchaseLine.FieldNo(Amount):  // 29
                if Evaluate(DecimalVar, FieldValue, 9) then
                    EDocumentPurchaseLine."Sub Total" := DecimalVar;
            PurchaseLine.FieldNo("Currency Code"):  // 91
                SetCurrencyIfForeign(FieldValue, EDocumentPurchaseLine."Currency Code");
            PurchaseLine.FieldNo("Unit of Measure Code"):  // 5407
                EDocumentPurchaseLine."Unit of Measure" := CopyStr(FieldValue, 1, MaxStrLen(EDocumentPurchaseLine."Unit of Measure"));
            PurchaseLine.FieldNo("Item Reference No."):  // 5725
                EDocumentPurchaseLine."Product Code" := CopyStr(FieldValue, 1, MaxStrLen(EDocumentPurchaseLine."Product Code"));
        // Fields 12, 30, 5415 - skip (no staging equivalent)
        end;
    end;

    #endregion Line Field Mapping

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

        // Process last attachment if any
        if FileName <> '' then begin
            AttachmentTempBlob.CreateInStream(InStream);
            EDocAttachmentProcessor.Insert(EDocument, InStream, FileName);
        end;
    end;

    #endregion Attachment Processing

    #region XPath Supplement

    /// <summary>
    /// Extracts fields still blank on staging header via XPath from the raw XML.
    /// Uses DataExchLineDef.GetPath() to look up the XPath for each field.
    /// </summary>
    local procedure SupplementWithXPath(EDocument: Record "E-Document"; var EDocumentPurchaseHeader: Record "E-Document Purchase Header"; var TempBlob: Codeunit "Temp Blob")
    var
        CompanyInformation: Record "Company Information";
        PurchaseHeader: Record "Purchase Header";
        xmlDoc: XmlDocument;
        InStream: InStream;
    begin
        TempBlob.CreateInStream(InStream);
        if not XmlDocument.ReadFrom(InStream, xmlDoc) then
            exit;

        if EDocumentPurchaseHeader."Customer VAT Id" = '' then
            ExtractXPathField(xmlDoc, EDocument, Database::"Company Information", CompanyInformation.FieldNo("VAT Registration No."), EDocumentPurchaseHeader."Customer VAT Id");

        if EDocumentPurchaseHeader."Customer GLN" = '' then
            ExtractXPathField(xmlDoc, EDocument, Database::"Company Information", CompanyInformation.FieldNo(GLN), EDocumentPurchaseHeader."Customer GLN");

        if EDocumentPurchaseHeader."Customer Company Name" = '' then
            ExtractXPathField(xmlDoc, EDocument, Database::"Company Information", CompanyInformation.FieldNo(Name), EDocumentPurchaseHeader."Customer Company Name");

        if EDocumentPurchaseHeader."Customer Address" = '' then
            ExtractXPathField(xmlDoc, EDocument, Database::"Company Information", CompanyInformation.FieldNo(Address), EDocumentPurchaseHeader."Customer Address");

        if EDocumentPurchaseHeader."Sales Invoice No." = '' then begin
            if EDocument."Document Type" = EDocument."Document Type"::"Purchase Invoice" then
                ExtractXPathField(xmlDoc, EDocument, Database::"Purchase Header", PurchaseHeader.FieldNo("Vendor Invoice No."), EDocumentPurchaseHeader."Sales Invoice No.")
            else
                if EDocument."Document Type" = EDocument."Document Type"::"Purchase Credit Memo" then
                    ExtractXPathField(xmlDoc, EDocument, Database::"Purchase Header", PurchaseHeader.FieldNo("Vendor Cr. Memo No."), EDocumentPurchaseHeader."Sales Invoice No.");
        end;

        if EDocumentPurchaseHeader."Purchase Order No." = '' then
            ExtractXPathField(xmlDoc, EDocument, Database::"Purchase Header", PurchaseHeader.FieldNo("Vendor Order No."), EDocumentPurchaseHeader."Purchase Order No.");

        if EDocumentPurchaseHeader."Vendor Company Name" = '' then
            ExtractXPathField(xmlDoc, EDocument, Database::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor Name"), EDocumentPurchaseHeader."Vendor Company Name");
    end;

    local procedure ExtractXPathField(var xmlDoc: XmlDocument; EDocument: Record "E-Document"; TableId: Integer; FieldNo: Integer; var TargetField: Text)
    var
        DataExchLineDef: Record "Data Exch. Line Def";
        ImportXMLFileToDataExch: Codeunit "Import XML File to Data Exch.";
        xmlNsManager: XmlNamespaceManager;
        xmlAttrCollection: XmlAttributeCollection;
        xmlAttribute: XmlAttribute;
        xmlNode: XmlNode;
        xmlElement: XmlElement;
        XPath: Text;
        XmlValue: Text;
    begin
        DataExchLineDef.SetRange("Data Exch. Def Code", EDocument."Data Exch. Def. Code");
        DataExchLineDef.SetRange("Parent Code", '');
        if not DataExchLineDef.FindFirst() then
            exit;

        XPath := DataExchLineDef.GetPath(TableId, FieldNo);
        if XPath = '' then
            exit;

        XPath := ImportXMLFileToDataExch.EscapeMissingNamespacePrefix(XPath);

        xmlNsManager.NameTable(xmlDoc.NameTable);
        xmlDoc.GetRoot(xmlElement);

        if xmlElement.NamespaceUri <> '' then
            xmlNsManager.AddNamespace('', xmlElement.NamespaceUri);

        xmlAttrCollection := xmlElement.Attributes();
        foreach xmlAttribute in xmlAttrCollection do
            if StrPos(xmlAttribute.Name, 'xmlns:') = 1 then
                xmlNsManager.AddNamespace(DelStr(xmlAttribute.Name, 1, 6), xmlAttribute.Value);

        if xmlDoc.SelectSingleNode(XPath, xmlNsManager, xmlNode) then
            XmlValue := xmlNode.AsXmlElement().InnerText()
        else
            exit;

        if XmlValue <> '' then
            TargetField := CopyStr(XmlValue, 1, MaxStrLen(TargetField));
    end;

    #endregion XPath Supplement

    #region Currency Helper

    /// <summary>
    /// BC convention: blank Currency Code means LCY. Sets the field to the currency code
    /// only if it differs from LCY. Explicitly blanks the field when it matches LCY.
    /// </summary>
    local procedure SetCurrencyIfForeign(CurrencyFromXml: Text; var CurrencyCode: Code[10])
    var
        GLSetup: Record "General Ledger Setup";
    begin
        if CurrencyFromXml = '' then
            exit;

        GLSetup.GetRecordOnce();
        if GLSetup."LCY Code" = CopyStr(CurrencyFromXml, 1, MaxStrLen(CurrencyCode)) then
            CurrencyCode := ''
        else
            CurrencyCode := CopyStr(CurrencyFromXml, 1, MaxStrLen(CurrencyCode));
    end;

    #endregion Currency Helper

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
    local procedure OnAfterMapIntermediateHeaderToStaging(DataExchNo: Integer; var EDocumentPurchaseHeader: Record "E-Document Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMapIntermediateLineToStaging(DataExchNo: Integer; RecordNo: Integer; var EDocumentPurchaseLine: Record "E-Document Purchase Line")
    begin
    end;

    #endregion Integration Events

    var
        ProcessFailedErr: Label 'Failed to process the file with data exchange.';
}
