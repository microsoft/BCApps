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
        CreditNoteNotSupportedLbl: Label 'Credit notes are not supported';
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
                    InsertPurchaseInvoiceLines(PeppolXML, XmlNamespaces, EDocumentPurchaseHeader."E-Document Entry No.");
                end;
            'CREDITNOTE':
                Error(CreditNoteNotSupportedLbl);
        end;
        EDocumentPurchaseHeader.Modify();
        EDocument.Direction := EDocument.Direction::Incoming;
        exit(Enum::"E-Doc. Process Draft"::"Purchase Document");
    end;

    local procedure PopulatePurchaseInvoiceHeader(PeppolXML: XmlDocument; XmlNamespaces: XmlNamespaceManager; var Header: Record "E-Document Purchase Header")
    begin
        PopulateDocumentInfo(PeppolXML, XmlNamespaces, Header);
        PopulateSupplierInfo(PeppolXML, XmlNamespaces, Header);
        PopulateCustomerInfo(PeppolXML, XmlNamespaces, Header);
        PopulateAmountsAndDates(PeppolXML, XmlNamespaces, Header);
        PopulateCurrency(PeppolXML, XmlNamespaces, Header);
    end;

    local procedure PopulateDocumentInfo(PeppolXML: XmlDocument; XmlNamespaces: XmlNamespaceManager; var Header: Record "E-Document Purchase Header")
    var
        Value: Text;
    begin
        if XmlHelper.TryGetStringValue(PeppolXML, XmlNamespaces, '/inv:Invoice/cbc:ID', Value) then
            Header."Sales Invoice No." := CopyStr(Value, 1, MaxStrLen(Header."Sales Invoice No."));
        if XmlHelper.TryGetStringValue(PeppolXML, XmlNamespaces, '/inv:Invoice/cac:OrderReference/cbc:ID', Value) then
            Header."Purchase Order No." := CopyStr(Value, 1, MaxStrLen(Header."Purchase Order No."));
    end;

    local procedure PopulateSupplierInfo(PeppolXML: XmlDocument; XmlNamespaces: XmlNamespaceManager; var Header: Record "E-Document Purchase Header")
    var
        XmlNode: XmlNode;
        Value: Text;
    begin
        if XmlHelper.TryGetStringValue(PeppolXML, XmlNamespaces, '/inv:Invoice/cac:AccountingSupplierParty/cac:Party/cac:PartyName/cbc:Name', Value) then
            Header."Vendor Company Name" := CopyStr(Value, 1, MaxStrLen(Header."Vendor Company Name"));
        // PayeeParty is used when the Payee is different from the Seller. Otherwise, it will not be shown in the XML.
        if XmlHelper.TryGetStringValue(PeppolXML, XmlNamespaces, '/inv:Invoice/cac:PayeeParty/cac:PartyName/cbc:Name', Value) then
            Header."Vendor Company Name" := CopyStr(Value, 1, MaxStrLen(Header."Vendor Company Name"));
        if XmlHelper.TryGetStringValue(PeppolXML, XmlNamespaces, '/inv:Invoice/cac:AccountingSupplierParty/cac:Party/cac:Contact/cbc:Name', Value) then
            Header."Vendor Contact Name" := CopyStr(Value, 1, MaxStrLen(Header."Vendor Contact Name"));
        if XmlHelper.TryGetStringValue(PeppolXML, XmlNamespaces, '/inv:Invoice/cac:AccountingSupplierParty/cac:Party/cac:PostalAddress/cbc:StreetName', Value) then
            Header."Vendor Address" := CopyStr(Value, 1, MaxStrLen(Header."Vendor Address"));
        if XmlHelper.TryGetStringValue(PeppolXML, XmlNamespaces, '/inv:Invoice/cac:AccountingSupplierParty/cac:Party/cac:PartyTaxScheme/cbc:CompanyID', Value) then
            Header."Vendor VAT Id" := CopyStr(Value, 1, MaxStrLen(Header."Vendor VAT Id"));
        if XmlHelper.TryGetStringValue(PeppolXML, XmlNamespaces, '/inv:Invoice/cac:PayeeParty/cac:PartyLegalEntity/cbc:CompanyID', Value) then
            Header."Vendor VAT Id" := CopyStr(Value, 1, MaxStrLen(Header."Vendor VAT Id"));

        // Vendor GLN: only populate when EndpointID schemeID = 0088
        if PeppolXML.SelectSingleNode('/inv:Invoice/cac:AccountingSupplierParty/cac:Party/cbc:EndpointID/@schemeID', XmlNamespaces, XmlNode) then
            if XmlNode.AsXmlAttribute().Value() = '0088' then
                if XmlHelper.TryGetStringValue(PeppolXML, XmlNamespaces, '/inv:Invoice/cac:AccountingSupplierParty/cac:Party/cbc:EndpointID', Value) then
                    Header."Vendor GLN" := CopyStr(Value, 1, MaxStrLen(Header."Vendor GLN"));
    end;

    local procedure PopulateCustomerInfo(PeppolXML: XmlDocument; XmlNamespaces: XmlNamespaceManager; var Header: Record "E-Document Purchase Header")
    var
        Value: Text;
    begin
        if XmlHelper.TryGetStringValue(PeppolXML, XmlNamespaces, '/inv:Invoice/cac:AccountingCustomerParty/cac:Party/cac:PartyName/cbc:Name', Value) then
            Header."Customer Company Name" := CopyStr(Value, 1, MaxStrLen(Header."Customer Company Name"));
        if XmlHelper.TryGetStringValue(PeppolXML, XmlNamespaces, '/inv:Invoice/cac:AccountingCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:CompanyID', Value) then
            Header."Customer VAT Id" := CopyStr(Value, 1, MaxStrLen(Header."Customer VAT Id"));
        if XmlHelper.TryGetStringValue(PeppolXML, XmlNamespaces, '/inv:Invoice/cac:AccountingCustomerParty/cac:Party/cac:PartyTaxScheme/cbc:CompanyID', Value) then
            Header."Customer VAT Id" := CopyStr(Value, 1, MaxStrLen(Header."Customer VAT Id"));
        if XmlHelper.TryGetStringValue(PeppolXML, XmlNamespaces, '/inv:Invoice/cac:AccountingCustomerParty/cac:Party/cac:PostalAddress/cbc:StreetName', Value) then
            Header."Customer Address" := CopyStr(Value, 1, MaxStrLen(Header."Customer Address"));
        if XmlHelper.TryGetStringValue(PeppolXML, XmlNamespaces, '/inv:Invoice/cac:AccountingCustomerParty/cac:Party/cbc:EndpointID', Value) then
            Header."Customer GLN" := CopyStr(Value, 1, MaxStrLen(Header."Customer GLN"));
        if XmlHelper.TryGetStringValue(PeppolXML, XmlNamespaces, '/inv:Invoice/cac:AccountingCustomerParty/cac:Party/cbc:EndpointID/@schemeID', Value) then
            Header."Customer Company Id" := CopyStr(Value, 1, MaxStrLen(Header."Customer Company Id"));
    end;

    local procedure PopulateAmountsAndDates(PeppolXML: XmlDocument; XmlNamespaces: XmlNamespaceManager; var Header: Record "E-Document Purchase Header")
    begin
        XmlHelper.SetNumberValueInField(PeppolXML, XmlNamespaces, '/inv:Invoice/cac:LegalMonetaryTotal/cbc:PayableAmount', Header.Total);
        XmlHelper.SetNumberValueInField(PeppolXML, XmlNamespaces, '/inv:Invoice/cac:LegalMonetaryTotal/cbc:TaxExclusiveAmount', Header."Sub Total");
        XmlHelper.SetNumberValueInField(PeppolXML, XmlNamespaces, '/inv:Invoice/cac:LegalMonetaryTotal/cbc:AllowanceTotalAmount', Header."Total Discount");
        Header."Total VAT" := Header."Total" - Header."Sub Total" - Header."Total Discount";

        XmlHelper.SetDateValueInField(PeppolXML, XmlNamespaces, '/inv:Invoice/cbc:DueDate', Header."Due Date");
        XmlHelper.SetDateValueInField(PeppolXML, XmlNamespaces, '/inv:Invoice/cbc:IssueDate', Header."Document Date");
    end;

    local procedure PopulateCurrency(PeppolXML: XmlDocument; XmlNamespaces: XmlNamespaceManager; var Header: Record "E-Document Purchase Header")
    var
        DocumentCurrencyCode: Text;
    begin
        if XmlHelper.TryGetStringValue(PeppolXML, XmlNamespaces, '/inv:Invoice/cbc:DocumentCurrencyCode', DocumentCurrencyCode) then
            SetCurrencyIfForeign(DocumentCurrencyCode, Header."Currency Code");
    end;

    local procedure InsertPurchaseInvoiceLines(PeppolXML: XmlDocument; XmlNamespaces: XmlNamespaceManager; EDocumentEntryNo: Integer)
    var
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        NewLineXML: XmlDocument;
        LineXMLList: XmlNodeList;
        LineXMLNode: XmlNode;
        i: Integer;
        InvoiceLinePathLbl: Label '/inv:Invoice/cac:InvoiceLine';
    begin
        if not PeppolXML.SelectNodes(InvoiceLinePathLbl, XmlNamespaces, LineXMLList) then
            exit;

        for i := 1 to LineXMLList.Count do begin
            Clear(EDocumentPurchaseLine);
            EDocumentPurchaseLine.Validate("E-Document Entry No.", EDocumentEntryNo);
            EDocumentPurchaseLine."Line No." := EDocumentPurchaseLine.GetNextLineNo(EDocumentEntryNo);
            LineXMLList.Get(i, LineXMLNode);
            NewLineXML.ReplaceNodes(LineXMLNode);
            PopulateEDocumentPurchaseLine(NewLineXML, XmlNamespaces, EDocumentPurchaseLine);
            EDocumentPurchaseLine.Insert();
        end;
    end;

    local procedure PopulateEDocumentPurchaseLine(LineXML: XmlDocument; XmlNamespaces: XmlNamespaceManager; var Line: Record "E-Document Purchase Line")
    var
        Value: Text;
    begin
        XmlHelper.SetNumberValueInField(LineXML, XmlNamespaces, 'cac:InvoiceLine/cbc:InvoicedQuantity', Line.Quantity);
        if XmlHelper.TryGetStringValue(LineXML, XmlNamespaces, 'cac:InvoiceLine/cbc:InvoicedQuantity/@unitCode', Value) then
            Line."Unit of Measure" := CopyStr(Value, 1, MaxStrLen(Line."Unit of Measure"));
        XmlHelper.SetNumberValueInField(LineXML, XmlNamespaces, 'cac:InvoiceLine/cbc:LineExtensionAmount', Line."Sub Total");
        XmlHelper.SetNumberValueInField(LineXML, XmlNamespaces, 'cac:InvoiceLine/cac:AllowanceCharge/cbc:Amount', Line."Total Discount");
        if XmlHelper.TryGetStringValue(LineXML, XmlNamespaces, 'cac:InvoiceLine/cbc:Note', Value) then
            Line.Description := CopyStr(Value, 1, MaxStrLen(Line.Description));
        if XmlHelper.TryGetStringValue(LineXML, XmlNamespaces, 'cac:InvoiceLine/cac:Item/cbc:Name', Value) then
            Line.Description := CopyStr(Value, 1, MaxStrLen(Line.Description));
        if XmlHelper.TryGetStringValue(LineXML, XmlNamespaces, 'cac:InvoiceLine/cac:Item/cbc:Description', Value) then
            Line.Description := CopyStr(Value, 1, MaxStrLen(Line.Description));
        if XmlHelper.TryGetStringValue(LineXML, XmlNamespaces, 'cac:InvoiceLine/cac:Item/cac:SellersItemIdentification/cbc:ID', Value) then
            Line."Product Code" := CopyStr(Value, 1, MaxStrLen(Line."Product Code"));
        if XmlHelper.TryGetStringValue(LineXML, XmlNamespaces, 'cac:InvoiceLine/cac:Item/cac:StandardItemIdentification/cbc:ID', Value) then
            Line."Product Code" := CopyStr(Value, 1, MaxStrLen(Line."Product Code"));
        XmlHelper.SetNumberValueInField(LineXML, XmlNamespaces, 'cac:InvoiceLine/cac:Item/cac:ClassifiedTaxCategory/cbc:Percent', Line."VAT Rate");
        XmlHelper.SetNumberValueInField(LineXML, XmlNamespaces, 'cac:InvoiceLine/cac:Price/cbc:PriceAmount', Line."Unit Price");
        PopulateCurrencyForLine(LineXML, XmlNamespaces, Line);
    end;

    local procedure PopulateCurrencyForLine(LineXML: XmlDocument; XmlNamespaces: XmlNamespaceManager; var Line: Record "E-Document Purchase Line")
    var
        LineCurrencyCode: Text;
    begin
        if XmlHelper.TryGetStringValue(LineXML, XmlNamespaces, 'cac:InvoiceLine/cbc:LineExtensionAmount/@currencyID', LineCurrencyCode) then
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
}
