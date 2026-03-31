// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Format;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using Microsoft.eServices.EDocument.Processing.Interfaces;
using Microsoft.Finance.GeneralLedger.Setup;
using System.Text;
using System.Utilities;

/// <summary>
/// Reads PEPPOL BIS 3.0 Invoice and CreditNote XML into v2 import draft staging tables.
/// Spec reference: https://docs.peppol.eu/poacc/billing/3.0/syntax/ubl-invoice/tree/
///                 https://docs.peppol.eu/poacc/billing/3.0/syntax/ubl-creditnote/tree/
/// </summary>
codeunit 6173 "E-Document PEPPOL Handler" implements IStructuredFormatReader
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        PeppolUtility: Codeunit "E-Document PEPPOL Utility";

    procedure ReadIntoDraft(EDocument: Record "E-Document"; TempBlob: Codeunit "Temp Blob"): Enum "E-Doc. Process Draft"
    var
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        DocStream: InStream;
        PeppolXML: XmlDocument;
        XmlNamespaces: XmlNamespaceManager;
        RootElement: XmlElement;
    begin
        EDocumentPurchaseHeader.InsertForEDocument(EDocument);

        TempBlob.CreateInStream(DocStream, TextEncoding::UTF8);
        XmlDocument.ReadFrom(DocStream, PeppolXML);
        PeppolUtility.InitializePEPPOL3Namespaces(XmlNamespaces);

        PeppolXML.GetRoot(RootElement);
        case UpperCase(RootElement.LocalName()) of
            'INVOICE':
                begin
                    PopulatePurchaseInvoiceHeader(PeppolXML, XmlNamespaces, EDocumentPurchaseHeader);
                    InsertPurchaseLines(PeppolXML, XmlNamespaces, EDocumentPurchaseHeader."E-Document Entry No.", '/inv:Invoice/cac:InvoiceLine', 'cac:InvoiceLine', 'cbc:InvoicedQuantity');
                    InsertAllowanceChargeLines(PeppolXML, XmlNamespaces, EDocumentPurchaseHeader."E-Document Entry No.", '/inv:Invoice');
                    InsertDocumentAttachments(EDocument, PeppolXML, XmlNamespaces, '/inv:Invoice');
                end;
            'CREDITNOTE':
                begin
                    PopulatePurchaseCreditMemoHeader(PeppolXML, XmlNamespaces, EDocumentPurchaseHeader);
                    InsertPurchaseLines(PeppolXML, XmlNamespaces, EDocumentPurchaseHeader."E-Document Entry No.", '/cre:CreditNote/cac:CreditNoteLine', 'cac:CreditNoteLine', 'cbc:CreditedQuantity');
                    InsertAllowanceChargeLines(PeppolXML, XmlNamespaces, EDocumentPurchaseHeader."E-Document Entry No.", '/cre:CreditNote');
                    InsertDocumentAttachments(EDocument, PeppolXML, XmlNamespaces, '/cre:CreditNote');
                end;
        end;
        EDocumentPurchaseHeader.Modify();
        EDocument.Direction := EDocument.Direction::Incoming;

        case UpperCase(RootElement.LocalName()) of
            'INVOICE':
                exit(Enum::"E-Doc. Process Draft"::"Purchase Invoice");
            'CREDITNOTE':
                exit(Enum::"E-Doc. Process Draft"::"Purchase Credit Memo");
            else
                exit(Enum::"E-Doc. Process Draft"::"Purchase Invoice");
        end;
    end;

    local procedure PopulatePurchaseInvoiceHeader(PeppolXML: XmlDocument; XmlNamespaces: XmlNamespaceManager; var Header: Record "E-Document Purchase Header")
    begin
        PopulateInvoiceDocumentInfo(PeppolXML, XmlNamespaces, Header);
        PopulateSupplierInfo(PeppolXML, XmlNamespaces, '/inv:Invoice', Header);
        PopulateCustomerInfo(PeppolXML, XmlNamespaces, '/inv:Invoice', Header);
        // Per PEPPOL BIS 3.0: Invoice has DueDate as a direct child element
        PopulateAmountsAndDates(PeppolXML, XmlNamespaces, '/inv:Invoice', '/inv:Invoice/cbc:DueDate', Header);
        PopulateCurrency(PeppolXML, XmlNamespaces, '/inv:Invoice', Header);
    end;

    local procedure PopulatePurchaseCreditMemoHeader(PeppolXML: XmlDocument; XmlNamespaces: XmlNamespaceManager; var Header: Record "E-Document Purchase Header")
    begin
        PopulateCreditNoteDocumentInfo(PeppolXML, XmlNamespaces, Header);
        PopulateSupplierInfo(PeppolXML, XmlNamespaces, '/cre:CreditNote', Header);
        PopulateCustomerInfo(PeppolXML, XmlNamespaces, '/cre:CreditNote', Header);
        // Per PEPPOL BIS 3.0: CreditNote has no top-level DueDate; it is under PaymentMeans.
        // Spec ref: https://docs.peppol.eu/poacc/billing/3.0/syntax/ubl-creditnote/cac-PaymentMeans/cbc-PaymentDueDate/
        PopulateAmountsAndDates(PeppolXML, XmlNamespaces, '/cre:CreditNote', '/cre:CreditNote/cac:PaymentMeans/cbc:PaymentDueDate', Header);
        PopulateCurrency(PeppolXML, XmlNamespaces, '/cre:CreditNote', Header);
    end;

    local procedure PopulateInvoiceDocumentInfo(PeppolXML: XmlDocument; XmlNamespaces: XmlNamespaceManager; var Header: Record "E-Document Purchase Header")
    var
        Value: Text;
    begin
        if PeppolUtility.TryGetStringValue(PeppolXML, XmlNamespaces, '/inv:Invoice/cbc:ID', Value) then
            Header."Sales Invoice No." := CopyStr(Value, 1, MaxStrLen(Header."Sales Invoice No."));
        if PeppolUtility.TryGetStringValue(PeppolXML, XmlNamespaces, '/inv:Invoice/cac:OrderReference/cbc:ID', Value) then
            Header."Purchase Order No." := CopyStr(Value, 1, MaxStrLen(Header."Purchase Order No."));
    end;

    local procedure PopulateCreditNoteDocumentInfo(PeppolXML: XmlDocument; XmlNamespaces: XmlNamespaceManager; var Header: Record "E-Document Purchase Header")
    var
        Value: Text;
    begin
        if PeppolUtility.TryGetStringValue(PeppolXML, XmlNamespaces, '/cre:CreditNote/cbc:ID', Value) then
            Header."Sales Invoice No." := CopyStr(Value, 1, MaxStrLen(Header."Sales Invoice No."));
        if PeppolUtility.TryGetStringValue(PeppolXML, XmlNamespaces, '/cre:CreditNote/cac:OrderReference/cbc:ID', Value) then
            Header."Purchase Order No." := CopyStr(Value, 1, MaxStrLen(Header."Purchase Order No."));
        if PeppolUtility.TryGetStringValue(PeppolXML, XmlNamespaces, '/cre:CreditNote/cac:BillingReference/cac:InvoiceDocumentReference/cbc:ID', Value) then
            Header."Applies-to Doc. No." := CopyStr(Value, 1, MaxStrLen(Header."Applies-to Doc. No."));
        if Header."Applies-to Doc. No." = '' then
            Session.LogMessage('', BillingReferenceEmptyTelemetryTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', 'E-Document');
    end;

    local procedure PopulateSupplierInfo(PeppolXML: XmlDocument; XmlNamespaces: XmlNamespaceManager; RootPath: Text; var Header: Record "E-Document Purchase Header")
    var
        XmlNode: XmlNode;
        Value: Text;
    begin
        if PeppolUtility.TryGetStringValue(PeppolXML, XmlNamespaces, RootPath + '/cac:AccountingSupplierParty/cac:Party/cac:PartyName/cbc:Name', Value) then
            Header."Vendor Company Name" := CopyStr(Value, 1, MaxStrLen(Header."Vendor Company Name"));
        // Per PEPPOL BIS 3.0: PayeeParty is used when the Payee is different from the Seller.
        if PeppolUtility.TryGetStringValue(PeppolXML, XmlNamespaces, RootPath + '/cac:PayeeParty/cac:PartyName/cbc:Name', Value) then
            Header."Vendor Company Name" := CopyStr(Value, 1, MaxStrLen(Header."Vendor Company Name"));
        if PeppolUtility.TryGetStringValue(PeppolXML, XmlNamespaces, RootPath + '/cac:AccountingSupplierParty/cac:Party/cac:Contact/cbc:Name', Value) then
            Header."Vendor Contact Name" := CopyStr(Value, 1, MaxStrLen(Header."Vendor Contact Name"));
        if PeppolUtility.TryGetStringValue(PeppolXML, XmlNamespaces, RootPath + '/cac:AccountingSupplierParty/cac:Party/cac:PostalAddress/cbc:StreetName', Value) then
            Header."Vendor Address" := CopyStr(Value, 1, MaxStrLen(Header."Vendor Address"));
        if PeppolUtility.TryGetStringValue(PeppolXML, XmlNamespaces, RootPath + '/cac:AccountingSupplierParty/cac:Party/cac:PartyTaxScheme/cbc:CompanyID', Value) then
            Header."Vendor VAT Id" := CopyStr(Value, 1, MaxStrLen(Header."Vendor VAT Id"));
        // Per PEPPOL BIS 3.0: PayeeParty/PartyLegalEntity/CompanyID is the Payee legal registration identifier.
        if PeppolUtility.TryGetStringValue(PeppolXML, XmlNamespaces, RootPath + '/cac:PayeeParty/cac:PartyLegalEntity/cbc:CompanyID', Value) then
            Header."Vendor VAT Id" := CopyStr(Value, 1, MaxStrLen(Header."Vendor VAT Id"));

        // Per PEPPOL BIS 3.0: EndpointID/@schemeID uses the EAS code list.
        // SchemeID 0088 = EAN Location Code (GLN). Only populate GLN for this scheme.
        if PeppolXML.SelectSingleNode(RootPath + '/cac:AccountingSupplierParty/cac:Party/cbc:EndpointID/@schemeID', XmlNamespaces, XmlNode) then
            if XmlNode.AsXmlAttribute().Value() = '0088' then
                if PeppolUtility.TryGetStringValue(PeppolXML, XmlNamespaces, RootPath + '/cac:AccountingSupplierParty/cac:Party/cbc:EndpointID', Value) then
                    Header."Vendor GLN" := CopyStr(Value, 1, MaxStrLen(Header."Vendor GLN"));
    end;

    local procedure PopulateCustomerInfo(PeppolXML: XmlDocument; XmlNamespaces: XmlNamespaceManager; RootPath: Text; var Header: Record "E-Document Purchase Header")
    var
        XmlNode: XmlNode;
        SchemeID: Text;
        EndpointValue: Text;
        Value: Text;
    begin
        if PeppolUtility.TryGetStringValue(PeppolXML, XmlNamespaces, RootPath + '/cac:AccountingCustomerParty/cac:Party/cac:PartyName/cbc:Name', Value) then
            Header."Customer Company Name" := CopyStr(Value, 1, MaxStrLen(Header."Customer Company Name"));
        if PeppolUtility.TryGetStringValue(PeppolXML, XmlNamespaces, RootPath + '/cac:AccountingCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:CompanyID', Value) then
            Header."Customer VAT Id" := CopyStr(Value, 1, MaxStrLen(Header."Customer VAT Id"));
        if PeppolUtility.TryGetStringValue(PeppolXML, XmlNamespaces, RootPath + '/cac:AccountingCustomerParty/cac:Party/cac:PartyTaxScheme/cbc:CompanyID', Value) then
            Header."Customer VAT Id" := CopyStr(Value, 1, MaxStrLen(Header."Customer VAT Id"));
        if PeppolUtility.TryGetStringValue(PeppolXML, XmlNamespaces, RootPath + '/cac:AccountingCustomerParty/cac:Party/cac:PostalAddress/cbc:StreetName', Value) then
            Header."Customer Address" := CopyStr(Value, 1, MaxStrLen(Header."Customer Address"));

        // Per PEPPOL BIS 3.0: EndpointID/@schemeID uses the EAS code list.
        // SchemeID 0088 = EAN Location Code (GLN). Only populate GLN for this scheme.
        // Customer Company Id stores the full electronic address identifier (schemeID:value).
        if PeppolUtility.TryGetStringValue(PeppolXML, XmlNamespaces, RootPath + '/cac:AccountingCustomerParty/cac:Party/cbc:EndpointID', EndpointValue) then begin
            if PeppolXML.SelectSingleNode(RootPath + '/cac:AccountingCustomerParty/cac:Party/cbc:EndpointID/@schemeID', XmlNamespaces, XmlNode) then
                SchemeID := XmlNode.AsXmlAttribute().Value();

            if SchemeID = '0088' then
                Header."Customer GLN" := CopyStr(EndpointValue, 1, MaxStrLen(Header."Customer GLN"));

            Header."Customer Company Id" := CopyStr(SchemeID + ':' + EndpointValue, 1, MaxStrLen(Header."Customer Company Id"));
        end;
    end;

    local procedure PopulateAmountsAndDates(PeppolXML: XmlDocument; XmlNamespaces: XmlNamespaceManager; RootPath: Text; DueDatePath: Text; var Header: Record "E-Document Purchase Header")
    begin
        PeppolUtility.SetNumberValueInField(PeppolXML, XmlNamespaces, RootPath + '/cac:LegalMonetaryTotal/cbc:PayableAmount', Header.Total);
        PeppolUtility.SetNumberValueInField(PeppolXML, XmlNamespaces, RootPath + '/cac:LegalMonetaryTotal/cbc:TaxExclusiveAmount', Header."Sub Total");
        PeppolUtility.SetNumberValueInField(PeppolXML, XmlNamespaces, RootPath + '/cac:LegalMonetaryTotal/cbc:AllowanceTotalAmount', Header."Total Discount");
        Header."Total VAT" := Header."Total" - Header."Sub Total" - Header."Total Discount";

        PeppolUtility.SetDateValueInField(PeppolXML, XmlNamespaces, DueDatePath, Header."Due Date");
        PeppolUtility.SetDateValueInField(PeppolXML, XmlNamespaces, RootPath + '/cbc:IssueDate', Header."Document Date");
    end;

    local procedure PopulateCurrency(PeppolXML: XmlDocument; XmlNamespaces: XmlNamespaceManager; RootPath: Text; var Header: Record "E-Document Purchase Header")
    var
        DocumentCurrencyCode: Text;
    begin
        if PeppolUtility.TryGetStringValue(PeppolXML, XmlNamespaces, RootPath + '/cbc:DocumentCurrencyCode', DocumentCurrencyCode) then
            SetCurrencyIfForeign(DocumentCurrencyCode, Header."Currency Code");
    end;

    #region Purchase Lines

    local procedure InsertPurchaseLines(PeppolXML: XmlDocument; XmlNamespaces: XmlNamespaceManager; EDocumentEntryNo: Integer; LineXPath: Text; LineElementName: Text; QuantityElementName: Text)
    var
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        NewLineXML: XmlDocument;
        LineXMLList: XmlNodeList;
        LineXMLNode: XmlNode;
        i: Integer;
    begin
        if not PeppolXML.SelectNodes(LineXPath, XmlNamespaces, LineXMLList) then
            exit;

        for i := 1 to LineXMLList.Count do begin
            Clear(EDocumentPurchaseLine);
            EDocumentPurchaseLine.Validate("E-Document Entry No.", EDocumentEntryNo);
            EDocumentPurchaseLine."Line No." := EDocumentPurchaseLine.GetNextLineNo(EDocumentEntryNo);
            LineXMLList.Get(i, LineXMLNode);
            NewLineXML.ReplaceNodes(LineXMLNode);
            PopulateEDocumentPurchaseLine(NewLineXML, XmlNamespaces, EDocumentPurchaseLine, LineElementName, QuantityElementName);
            EDocumentPurchaseLine.Insert();
        end;
    end;

    local procedure PopulateEDocumentPurchaseLine(LineXML: XmlDocument; XmlNamespaces: XmlNamespaceManager; var Line: Record "E-Document Purchase Line"; LineElementName: Text; QuantityElementName: Text)
    var
        Value: Text;
    begin
        PeppolUtility.SetNumberValueInField(LineXML, XmlNamespaces, LineElementName + '/' + QuantityElementName, Line.Quantity);
        if PeppolUtility.TryGetStringValue(LineXML, XmlNamespaces, LineElementName + '/' + QuantityElementName + '/@unitCode', Value) then
            Line."Unit of Measure" := CopyStr(Value, 1, MaxStrLen(Line."Unit of Measure"));
        PeppolUtility.SetNumberValueInField(LineXML, XmlNamespaces, LineElementName + '/cbc:LineExtensionAmount', Line."Sub Total");
        PeppolUtility.SetNumberValueInField(LineXML, XmlNamespaces, LineElementName + '/cac:AllowanceCharge/cbc:Amount', Line."Total Discount");

        // Per PEPPOL BIS 3.0: Item Name (1..1, mandatory) is the primary short product description.
        // Item Description (0..1) is an optional longer description that may exceed field capacity.
        // Line Note (0..1) is operational info, not a product description.
        // Priority: Name (always present per spec), fallback to Description if Name is absent.
        if PeppolUtility.TryGetStringValue(LineXML, XmlNamespaces, LineElementName + '/cac:Item/cbc:Name', Value) then
            Line.Description := CopyStr(Value, 1, MaxStrLen(Line.Description));
        if Line.Description = '' then
            if PeppolUtility.TryGetStringValue(LineXML, XmlNamespaces, LineElementName + '/cac:Item/cbc:Description', Value) then
                Line.Description := CopyStr(Value, 1, MaxStrLen(Line.Description));

        // Per PEPPOL BIS 3.0: SellersItemIdentification is the seller's internal product code.
        // StandardItemIdentification is a registered standard (e.g., GTIN via schemeID 0160).
        // StandardItemIdentification takes priority as the more universally recognized identifier.
        if PeppolUtility.TryGetStringValue(LineXML, XmlNamespaces, LineElementName + '/cac:Item/cac:SellersItemIdentification/cbc:ID', Value) then
            if Value <> '' then
                Line."Product Code" := CopyStr(Value, 1, MaxStrLen(Line."Product Code"));
        if PeppolUtility.TryGetStringValue(LineXML, XmlNamespaces, LineElementName + '/cac:Item/cac:StandardItemIdentification/cbc:ID', Value) then
            if Value <> '' then
                Line."Product Code" := CopyStr(Value, 1, MaxStrLen(Line."Product Code"));

        PeppolUtility.SetNumberValueInField(LineXML, XmlNamespaces, LineElementName + '/cac:Item/cac:ClassifiedTaxCategory/cbc:Percent', Line."VAT Rate");
        PeppolUtility.SetNumberValueInField(LineXML, XmlNamespaces, LineElementName + '/cac:Price/cbc:PriceAmount', Line."Unit Price");
        PopulateCurrencyForLine(LineXML, XmlNamespaces, Line, LineElementName);
    end;

    local procedure PopulateCurrencyForLine(LineXML: XmlDocument; XmlNamespaces: XmlNamespaceManager; var Line: Record "E-Document Purchase Line"; LineElementName: Text)
    var
        LineCurrencyCode: Text;
    begin
        if PeppolUtility.TryGetStringValue(LineXML, XmlNamespaces, LineElementName + '/cbc:LineExtensionAmount/@currencyID', LineCurrencyCode) then
            SetCurrencyIfForeign(LineCurrencyCode, Line."Currency Code");
    end;

    #endregion Purchase Lines

    #region Document-Level Allowance/Charge Lines

    /// <summary>
    /// Per PEPPOL BIS 3.0: Document-level AllowanceCharge (0..n) represents surcharges and allowances
    /// that apply to the entire document (e.g., shipping fees, early payment discounts).
    /// ChargeIndicator = true means a charge (surcharge/fee); false means an allowance (discount).
    /// Allowances are already captured in the header-level AllowanceTotalAmount.
    /// This method creates separate purchase lines for charges only.
    /// Spec ref: https://docs.peppol.eu/poacc/billing/3.0/syntax/ubl-invoice/cac-AllowanceCharge/
    /// </summary>
    local procedure InsertAllowanceChargeLines(PeppolXML: XmlDocument; XmlNamespaces: XmlNamespaceManager; EDocumentEntryNo: Integer; RootPath: Text)
    var
        ChargeXML: XmlDocument;
        ChargeNodes: XmlNodeList;
        ChargeNode: XmlNode;
        ChargeIndicator: Text;
        i: Integer;
    begin
        if not PeppolXML.SelectNodes(RootPath + '/cac:AllowanceCharge', XmlNamespaces, ChargeNodes) then
            exit;

        for i := 1 to ChargeNodes.Count do begin
            ChargeNodes.Get(i, ChargeNode);
            ChargeXML.ReplaceNodes(ChargeNode);

            if PeppolUtility.TryGetStringValue(ChargeXML, XmlNamespaces, 'cac:AllowanceCharge/cbc:ChargeIndicator', ChargeIndicator) then
                if UpperCase(ChargeIndicator) = 'TRUE' then
                    InsertSingleChargeLine(ChargeXML, XmlNamespaces, EDocumentEntryNo);
        end;
    end;

    local procedure InsertSingleChargeLine(ChargeXML: XmlDocument; XmlNamespaces: XmlNamespaceManager; EDocumentEntryNo: Integer)
    var
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        ChargeAmount: Decimal;
        Value: Text;
        CurrencyCode: Text;
    begin
        Clear(EDocumentPurchaseLine);
        EDocumentPurchaseLine.Validate("E-Document Entry No.", EDocumentEntryNo);
        EDocumentPurchaseLine."Line No." := EDocumentPurchaseLine.GetNextLineNo(EDocumentEntryNo);
        EDocumentPurchaseLine.Quantity := 1;

        PeppolUtility.SetNumberValueInField(ChargeXML, XmlNamespaces, 'cac:AllowanceCharge/cbc:Amount', ChargeAmount);
        EDocumentPurchaseLine."Unit Price" := ChargeAmount;
        EDocumentPurchaseLine."Sub Total" := ChargeAmount;

        if PeppolUtility.TryGetStringValue(ChargeXML, XmlNamespaces, 'cac:AllowanceCharge/cbc:AllowanceChargeReason', Value) then
            EDocumentPurchaseLine.Description := CopyStr(Value, 1, MaxStrLen(EDocumentPurchaseLine.Description));

        PeppolUtility.SetNumberValueInField(ChargeXML, XmlNamespaces, 'cac:AllowanceCharge/cac:TaxCategory/cbc:Percent', EDocumentPurchaseLine."VAT Rate");

        if PeppolUtility.TryGetStringValue(ChargeXML, XmlNamespaces, 'cac:AllowanceCharge/cbc:Amount/@currencyID', CurrencyCode) then
            SetCurrencyIfForeign(CurrencyCode, EDocumentPurchaseLine."Currency Code");

        EDocumentPurchaseLine.Insert();
    end;

    #endregion Document-Level Allowance/Charge Lines

    #region Document Attachments

    /// <summary>
    /// Per PEPPOL BIS 3.0: AdditionalDocumentReference (0..n) can contain embedded binary attachments
    /// (e.g., PDF copies, timesheets, delivery notes) encoded as base64 in EmbeddedDocumentBinaryObject.
    /// Spec ref: https://docs.peppol.eu/poacc/billing/3.0/syntax/ubl-invoice/cac-AdditionalDocumentReference/
    /// </summary>
    local procedure InsertDocumentAttachments(EDocument: Record "E-Document"; PeppolXML: XmlDocument; XmlNamespaces: XmlNamespaceManager; RootPath: Text)
    var
        AttachmentNodes: XmlNodeList;
        AttachmentNode: XmlNode;
        AttachmentXML: XmlDocument;
        i: Integer;
    begin
        if not PeppolXML.SelectNodes(RootPath + '/cac:AdditionalDocumentReference', XmlNamespaces, AttachmentNodes) then
            exit;

        for i := 1 to AttachmentNodes.Count do begin
            AttachmentNodes.Get(i, AttachmentNode);
            AttachmentXML.ReplaceNodes(AttachmentNode);
            InsertSingleAttachment(EDocument, AttachmentXML, XmlNamespaces);
        end;
    end;

    local procedure InsertSingleAttachment(EDocument: Record "E-Document"; AttachmentXML: XmlDocument; XmlNamespaces: XmlNamespaceManager)
    var
        EDocAttachmentProcessor: Codeunit "E-Doc. Attachment Processor";
        Base64Convert: Codeunit "Base64 Convert";
        AttachmentBlob: Codeunit "Temp Blob";
        InStream: InStream;
        OutStream: OutStream;
        Base64Content: Text;
        FileName: Text;
        MimeCode: Text;
        FileExtension: Text;
        ElementName: Text;
    begin
        ElementName := 'cac:AdditionalDocumentReference';

        // Only process references with embedded binary content; skip external URI references
        if not PeppolUtility.TryGetStringValue(AttachmentXML, XmlNamespaces, ElementName + '/cac:Attachment/cbc:EmbeddedDocumentBinaryObject', Base64Content) then
            exit;

        if Base64Content = '' then
            exit;

        // Per PEPPOL BIS 3.0: @filename is mandatory on EmbeddedDocumentBinaryObject
        if not PeppolUtility.TryGetStringValue(AttachmentXML, XmlNamespaces, ElementName + '/cac:Attachment/cbc:EmbeddedDocumentBinaryObject/@filename', FileName) then
            // Fallback to document reference ID if filename attribute is missing
            PeppolUtility.TryGetStringValue(AttachmentXML, XmlNamespaces, ElementName + '/cbc:ID', FileName);

        if FileName = '' then
            exit;

        // If filename has no extension, derive one from the mandatory @mimeCode attribute
        if not FileName.Contains('.') then
            if PeppolUtility.TryGetStringValue(AttachmentXML, XmlNamespaces, ElementName + '/cac:Attachment/cbc:EmbeddedDocumentBinaryObject/@mimeCode', MimeCode) then begin
                FileExtension := DetermineFileExtension(MimeCode);
                if FileExtension <> '' then
                    FileName := FileName + '.' + FileExtension;
            end;

        // Decode base64 content and save as attachment on the E-Document
        AttachmentBlob.CreateOutStream(OutStream);
        Base64Convert.FromBase64(Base64Content, OutStream);
        AttachmentBlob.CreateInStream(InStream);
        EDocAttachmentProcessor.Insert(EDocument, InStream, FileName);
    end;

    local procedure DetermineFileExtension(MimeCode: Text): Text
    begin
        case MimeCode of
            'image/jpeg':
                exit('jpeg');
            'image/png':
                exit('png');
            'application/pdf':
                exit('pdf');
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet':
                exit('xlsx');
            'application/vnd.oasis.opendocument.spreadsheet':
                exit('ods');
            'text/csv':
                exit('csv');
            else
                exit('');
        end;
    end;

    #endregion Document Attachments

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

    procedure View(EDocument: Record "E-Document"; TempBlob: Codeunit "Temp Blob")
    begin
        Error('A view is not implemented for this handler.');
    end;

    var
        BillingReferenceEmptyTelemetryTxt: Label 'CreditNote BillingReference is empty - no originating invoice reference found.', Locked = true;
}
