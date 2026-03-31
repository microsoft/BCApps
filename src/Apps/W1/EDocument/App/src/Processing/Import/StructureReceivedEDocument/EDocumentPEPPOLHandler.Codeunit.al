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
using System.Utilities;

codeunit 6173 "E-Document PEPPOL Handler" implements IStructuredFormatReader
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        XmlHelper: Codeunit "E-Document XML Helper";

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
        XmlHelper.InitializePEPPOLNamespaces(XmlNamespaces);

        PeppolXML.GetRoot(RootElement);
        case UpperCase(RootElement.LocalName()) of
            'INVOICE':
                begin
                    PopulatePurchaseInvoiceHeader(PeppolXML, XmlNamespaces, EDocumentPurchaseHeader);
                    InsertPurchaseLines(PeppolXML, XmlNamespaces, EDocumentPurchaseHeader."E-Document Entry No.", '/inv:Invoice/cac:InvoiceLine', 'cac:InvoiceLine', 'cbc:InvoicedQuantity');
                end;
            'CREDITNOTE':
                begin
                    PopulatePurchaseCreditMemoHeader(PeppolXML, XmlNamespaces, EDocumentPurchaseHeader);
                    InsertPurchaseLines(PeppolXML, XmlNamespaces, EDocumentPurchaseHeader."E-Document Entry No.", '/cre:CreditNote/cac:CreditNoteLine', 'cac:CreditNoteLine', 'cbc:CreditedQuantity');
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
        PopulateAmountsAndDates(PeppolXML, XmlNamespaces, '/inv:Invoice', Header);
        PopulateCurrency(PeppolXML, XmlNamespaces, '/inv:Invoice', Header);
    end;

    local procedure PopulatePurchaseCreditMemoHeader(PeppolXML: XmlDocument; XmlNamespaces: XmlNamespaceManager; var Header: Record "E-Document Purchase Header")
    begin
        PopulateCreditNoteDocumentInfo(PeppolXML, XmlNamespaces, Header);
        PopulateSupplierInfo(PeppolXML, XmlNamespaces, '/cre:CreditNote', Header);
        PopulateCustomerInfo(PeppolXML, XmlNamespaces, '/cre:CreditNote', Header);
        PopulateAmountsAndDates(PeppolXML, XmlNamespaces, '/cre:CreditNote', Header);
        PopulateCurrency(PeppolXML, XmlNamespaces, '/cre:CreditNote', Header);
    end;

    local procedure PopulateInvoiceDocumentInfo(PeppolXML: XmlDocument; XmlNamespaces: XmlNamespaceManager; var Header: Record "E-Document Purchase Header")
    var
        Value: Text;
    begin
        if XmlHelper.TryGetStringValue(PeppolXML, XmlNamespaces, '/inv:Invoice/cbc:ID', Value) then
            Header."Sales Invoice No." := CopyStr(Value, 1, MaxStrLen(Header."Sales Invoice No."));
        if XmlHelper.TryGetStringValue(PeppolXML, XmlNamespaces, '/inv:Invoice/cac:OrderReference/cbc:ID', Value) then
            Header."Purchase Order No." := CopyStr(Value, 1, MaxStrLen(Header."Purchase Order No."));
    end;

    local procedure PopulateCreditNoteDocumentInfo(PeppolXML: XmlDocument; XmlNamespaces: XmlNamespaceManager; var Header: Record "E-Document Purchase Header")
    var
        Value: Text;
    begin
        if XmlHelper.TryGetStringValue(PeppolXML, XmlNamespaces, '/cre:CreditNote/cbc:ID', Value) then
            Header."Sales Invoice No." := CopyStr(Value, 1, MaxStrLen(Header."Sales Invoice No."));
        if XmlHelper.TryGetStringValue(PeppolXML, XmlNamespaces, '/cre:CreditNote/cac:OrderReference/cbc:ID', Value) then
            Header."Purchase Order No." := CopyStr(Value, 1, MaxStrLen(Header."Purchase Order No."));
        if XmlHelper.TryGetStringValue(PeppolXML, XmlNamespaces, '/cre:CreditNote/cac:BillingReference/cac:InvoiceDocumentReference/cbc:ID', Value) then
            Header."Applies-to Doc. No." := CopyStr(Value, 1, MaxStrLen(Header."Applies-to Doc. No."));
        if Header."Applies-to Doc. No." = '' then
            Session.LogMessage('', BillingReferenceEmptyTelemetryTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', 'E-Document');
    end;

    local procedure PopulateSupplierInfo(PeppolXML: XmlDocument; XmlNamespaces: XmlNamespaceManager; RootPath: Text; var Header: Record "E-Document Purchase Header")
    var
        XmlNode: XmlNode;
        Value: Text;
    begin
        if XmlHelper.TryGetStringValue(PeppolXML, XmlNamespaces, RootPath + '/cac:AccountingSupplierParty/cac:Party/cac:PartyName/cbc:Name', Value) then
            Header."Vendor Company Name" := CopyStr(Value, 1, MaxStrLen(Header."Vendor Company Name"));
        // PayeeParty is used when the Payee is different from the Seller. Otherwise, it will not be shown in the XML.
        if XmlHelper.TryGetStringValue(PeppolXML, XmlNamespaces, RootPath + '/cac:PayeeParty/cac:PartyName/cbc:Name', Value) then
            Header."Vendor Company Name" := CopyStr(Value, 1, MaxStrLen(Header."Vendor Company Name"));
        if XmlHelper.TryGetStringValue(PeppolXML, XmlNamespaces, RootPath + '/cac:AccountingSupplierParty/cac:Party/cac:Contact/cbc:Name', Value) then
            Header."Vendor Contact Name" := CopyStr(Value, 1, MaxStrLen(Header."Vendor Contact Name"));
        if XmlHelper.TryGetStringValue(PeppolXML, XmlNamespaces, RootPath + '/cac:AccountingSupplierParty/cac:Party/cac:PostalAddress/cbc:StreetName', Value) then
            Header."Vendor Address" := CopyStr(Value, 1, MaxStrLen(Header."Vendor Address"));
        if XmlHelper.TryGetStringValue(PeppolXML, XmlNamespaces, RootPath + '/cac:AccountingSupplierParty/cac:Party/cac:PartyTaxScheme/cbc:CompanyID', Value) then
            Header."Vendor VAT Id" := CopyStr(Value, 1, MaxStrLen(Header."Vendor VAT Id"));
        if XmlHelper.TryGetStringValue(PeppolXML, XmlNamespaces, RootPath + '/cac:PayeeParty/cac:PartyLegalEntity/cbc:CompanyID', Value) then
            Header."Vendor VAT Id" := CopyStr(Value, 1, MaxStrLen(Header."Vendor VAT Id"));

        // Vendor GLN: only populate when EndpointID schemeID = 0088
        if PeppolXML.SelectSingleNode(RootPath + '/cac:AccountingSupplierParty/cac:Party/cbc:EndpointID/@schemeID', XmlNamespaces, XmlNode) then
            if XmlNode.AsXmlAttribute().Value() = '0088' then
                if XmlHelper.TryGetStringValue(PeppolXML, XmlNamespaces, RootPath + '/cac:AccountingSupplierParty/cac:Party/cbc:EndpointID', Value) then
                    Header."Vendor GLN" := CopyStr(Value, 1, MaxStrLen(Header."Vendor GLN"));
    end;

    local procedure PopulateCustomerInfo(PeppolXML: XmlDocument; XmlNamespaces: XmlNamespaceManager; RootPath: Text; var Header: Record "E-Document Purchase Header")
    var
        Value: Text;
    begin
        if XmlHelper.TryGetStringValue(PeppolXML, XmlNamespaces, RootPath + '/cac:AccountingCustomerParty/cac:Party/cac:PartyName/cbc:Name', Value) then
            Header."Customer Company Name" := CopyStr(Value, 1, MaxStrLen(Header."Customer Company Name"));
        if XmlHelper.TryGetStringValue(PeppolXML, XmlNamespaces, RootPath + '/cac:AccountingCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:CompanyID', Value) then
            Header."Customer VAT Id" := CopyStr(Value, 1, MaxStrLen(Header."Customer VAT Id"));
        if XmlHelper.TryGetStringValue(PeppolXML, XmlNamespaces, RootPath + '/cac:AccountingCustomerParty/cac:Party/cac:PartyTaxScheme/cbc:CompanyID', Value) then
            Header."Customer VAT Id" := CopyStr(Value, 1, MaxStrLen(Header."Customer VAT Id"));
        if XmlHelper.TryGetStringValue(PeppolXML, XmlNamespaces, RootPath + '/cac:AccountingCustomerParty/cac:Party/cac:PostalAddress/cbc:StreetName', Value) then
            Header."Customer Address" := CopyStr(Value, 1, MaxStrLen(Header."Customer Address"));
        if XmlHelper.TryGetStringValue(PeppolXML, XmlNamespaces, RootPath + '/cac:AccountingCustomerParty/cac:Party/cbc:EndpointID', Value) then
            Header."Customer GLN" := CopyStr(Value, 1, MaxStrLen(Header."Customer GLN"));
        if XmlHelper.TryGetStringValue(PeppolXML, XmlNamespaces, RootPath + '/cac:AccountingCustomerParty/cac:Party/cbc:EndpointID/@schemeID', Value) then
            Header."Customer Company Id" := CopyStr(Value, 1, MaxStrLen(Header."Customer Company Id"));
    end;

    local procedure PopulateAmountsAndDates(PeppolXML: XmlDocument; XmlNamespaces: XmlNamespaceManager; RootPath: Text; var Header: Record "E-Document Purchase Header")
    begin
        XmlHelper.SetNumberValueInField(PeppolXML, XmlNamespaces, RootPath + '/cac:LegalMonetaryTotal/cbc:PayableAmount', Header.Total);
        XmlHelper.SetNumberValueInField(PeppolXML, XmlNamespaces, RootPath + '/cac:LegalMonetaryTotal/cbc:TaxExclusiveAmount', Header."Sub Total");
        XmlHelper.SetNumberValueInField(PeppolXML, XmlNamespaces, RootPath + '/cac:LegalMonetaryTotal/cbc:AllowanceTotalAmount', Header."Total Discount");
        Header."Total VAT" := Header."Total" - Header."Sub Total" - Header."Total Discount";

        XmlHelper.SetDateValueInField(PeppolXML, XmlNamespaces, RootPath + '/cbc:DueDate', Header."Due Date");
        XmlHelper.SetDateValueInField(PeppolXML, XmlNamespaces, RootPath + '/cbc:IssueDate', Header."Document Date");
    end;

    local procedure PopulateCurrency(PeppolXML: XmlDocument; XmlNamespaces: XmlNamespaceManager; RootPath: Text; var Header: Record "E-Document Purchase Header")
    var
        DocumentCurrencyCode: Text;
    begin
        if XmlHelper.TryGetStringValue(PeppolXML, XmlNamespaces, RootPath + '/cbc:DocumentCurrencyCode', DocumentCurrencyCode) then
            SetCurrencyIfForeign(DocumentCurrencyCode, Header."Currency Code");
    end;

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
        XmlHelper.SetNumberValueInField(LineXML, XmlNamespaces, LineElementName + '/' + QuantityElementName, Line.Quantity);
        if XmlHelper.TryGetStringValue(LineXML, XmlNamespaces, LineElementName + '/' + QuantityElementName + '/@unitCode', Value) then
            Line."Unit of Measure" := CopyStr(Value, 1, MaxStrLen(Line."Unit of Measure"));
        XmlHelper.SetNumberValueInField(LineXML, XmlNamespaces, LineElementName + '/cbc:LineExtensionAmount', Line."Sub Total");
        XmlHelper.SetNumberValueInField(LineXML, XmlNamespaces, LineElementName + '/cac:AllowanceCharge/cbc:Amount', Line."Total Discount");
        if XmlHelper.TryGetStringValue(LineXML, XmlNamespaces, LineElementName + '/cbc:Note', Value) then
            Line.Description := CopyStr(Value, 1, MaxStrLen(Line.Description));
        if XmlHelper.TryGetStringValue(LineXML, XmlNamespaces, LineElementName + '/cac:Item/cbc:Name', Value) then
            Line.Description := CopyStr(Value, 1, MaxStrLen(Line.Description));
        if XmlHelper.TryGetStringValue(LineXML, XmlNamespaces, LineElementName + '/cac:Item/cbc:Description', Value) then
            Line.Description := CopyStr(Value, 1, MaxStrLen(Line.Description));
        if XmlHelper.TryGetStringValue(LineXML, XmlNamespaces, LineElementName + '/cac:Item/cac:SellersItemIdentification/cbc:ID', Value) then
            Line."Product Code" := CopyStr(Value, 1, MaxStrLen(Line."Product Code"));
        if XmlHelper.TryGetStringValue(LineXML, XmlNamespaces, LineElementName + '/cac:Item/cac:StandardItemIdentification/cbc:ID', Value) then
            Line."Product Code" := CopyStr(Value, 1, MaxStrLen(Line."Product Code"));
        XmlHelper.SetNumberValueInField(LineXML, XmlNamespaces, LineElementName + '/cac:Item/cac:ClassifiedTaxCategory/cbc:Percent', Line."VAT Rate");
        XmlHelper.SetNumberValueInField(LineXML, XmlNamespaces, LineElementName + '/cac:Price/cbc:PriceAmount', Line."Unit Price");
        PopulateCurrencyForLine(LineXML, XmlNamespaces, Line, LineElementName);
    end;

    local procedure PopulateCurrencyForLine(LineXML: XmlDocument; XmlNamespaces: XmlNamespaceManager; var Line: Record "E-Document Purchase Line"; LineElementName: Text)
    var
        LineCurrencyCode: Text;
    begin
        if XmlHelper.TryGetStringValue(LineXML, XmlNamespaces, LineElementName + '/cbc:LineExtensionAmount/@currencyID', LineCurrencyCode) then
            SetCurrencyIfForeign(LineCurrencyCode, Line."Currency Code");
    end;

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
