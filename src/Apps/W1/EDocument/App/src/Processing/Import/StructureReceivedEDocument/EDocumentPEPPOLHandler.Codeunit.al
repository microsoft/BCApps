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
    begin
        XmlHelper.SetStringValueInField(PeppolXML, XmlNamespaces, '/inv:Invoice/cbc:ID', MaxStrLen(Header."Sales Invoice No."), Header."Sales Invoice No.");
        XmlHelper.SetStringValueInField(PeppolXML, XmlNamespaces, '/inv:Invoice/cac:OrderReference/cbc:ID', MaxStrLen(Header."Purchase Order No."), Header."Purchase Order No.");
    end;

    local procedure PopulateSupplierInfo(PeppolXML: XmlDocument; XmlNamespaces: XmlNamespaceManager; var Header: Record "E-Document Purchase Header")
    var
        XmlNode: XmlNode;
    begin
        XmlHelper.SetStringValueInField(PeppolXML, XmlNamespaces, '/inv:Invoice/cac:AccountingSupplierParty/cac:Party/cac:PartyName/cbc:Name', MaxStrLen(Header."Vendor Company Name"), Header."Vendor Company Name");
        // PayeeParty is used when the Payee is different from the Seller. Otherwise, it will not be shown in the XML.
        XmlHelper.SetStringValueInField(PeppolXML, XmlNamespaces, '/inv:Invoice/cac:PayeeParty/cac:PartyName/cbc:Name', MaxStrLen(Header."Vendor Company Name"), Header."Vendor Company Name");
        XmlHelper.SetStringValueInField(PeppolXML, XmlNamespaces, '/inv:Invoice/cac:AccountingSupplierParty/cac:Party/cac:Contact/cbc:Name', MaxStrLen(Header."Vendor Contact Name"), Header."Vendor Contact Name");
        XmlHelper.SetStringValueInField(PeppolXML, XmlNamespaces, '/inv:Invoice/cac:AccountingSupplierParty/cac:Party/cac:PostalAddress/cbc:StreetName', MaxStrLen(Header."Vendor Address"), Header."Vendor Address");
        XmlHelper.SetStringValueInField(PeppolXML, XmlNamespaces, '/inv:Invoice/cac:AccountingSupplierParty/cac:Party/cac:PartyTaxScheme/cbc:CompanyID', MaxStrLen(Header."Vendor VAT Id"), Header."Vendor VAT Id");
        XmlHelper.SetStringValueInField(PeppolXML, XmlNamespaces, '/inv:Invoice/cac:PayeeParty/cac:PartyLegalEntity/cbc:CompanyID', MaxStrLen(Header."Vendor VAT Id"), Header."Vendor VAT Id");

        // Vendor GLN: only populate when EndpointID schemeID = 0088
        if PeppolXML.SelectSingleNode('/inv:Invoice/cac:AccountingSupplierParty/cac:Party/cbc:EndpointID/@schemeID', XmlNamespaces, XmlNode) then
            if XmlNode.AsXmlAttribute().Value() = '0088' then
                XmlHelper.SetStringValueInField(PeppolXML, XmlNamespaces, '/inv:Invoice/cac:AccountingSupplierParty/cac:Party/cbc:EndpointID', MaxStrLen(Header."Vendor GLN"), Header."Vendor GLN");
    end;

    local procedure PopulateCustomerInfo(PeppolXML: XmlDocument; XmlNamespaces: XmlNamespaceManager; var Header: Record "E-Document Purchase Header")
    begin
        XmlHelper.SetStringValueInField(PeppolXML, XmlNamespaces, '/inv:Invoice/cac:AccountingCustomerParty/cac:Party/cac:PartyName/cbc:Name', MaxStrLen(Header."Customer Company Name"), Header."Customer Company Name");
        XmlHelper.SetStringValueInField(PeppolXML, XmlNamespaces, '/inv:Invoice/cac:AccountingCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:CompanyID', MaxStrLen(Header."Customer VAT Id"), Header."Customer VAT Id");
        XmlHelper.SetStringValueInField(PeppolXML, XmlNamespaces, '/inv:Invoice/cac:AccountingCustomerParty/cac:Party/cac:PartyTaxScheme/cbc:CompanyID', MaxStrLen(Header."Customer VAT Id"), Header."Customer VAT Id");
        XmlHelper.SetStringValueInField(PeppolXML, XmlNamespaces, '/inv:Invoice/cac:AccountingCustomerParty/cac:Party/cac:PostalAddress/cbc:StreetName', MaxStrLen(Header."Customer Address"), Header."Customer Address");
        XmlHelper.SetStringValueInField(PeppolXML, XmlNamespaces, '/inv:Invoice/cac:AccountingCustomerParty/cac:Party/cbc:EndpointID', MaxStrLen(Header."Customer GLN"), Header."Customer GLN");
        XmlHelper.SetStringValueInField(PeppolXML, XmlNamespaces, '/inv:Invoice/cac:AccountingCustomerParty/cac:Party/cbc:EndpointID/@schemeID', MaxStrLen(Header."Customer Company Id"), Header."Customer Company Id");
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
        XmlHelper.SetStringValueInField(PeppolXML, XmlNamespaces, '/inv:Invoice/cbc:DocumentCurrencyCode', MaxStrLen(DocumentCurrencyCode), DocumentCurrencyCode);
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
    begin
        XmlHelper.SetNumberValueInField(LineXML, XmlNamespaces, 'cac:InvoiceLine/cbc:InvoicedQuantity', Line.Quantity);
        XmlHelper.SetStringValueInField(LineXML, XmlNamespaces, 'cac:InvoiceLine/cbc:InvoicedQuantity/@unitCode', MaxStrLen(Line."Unit of Measure"), Line."Unit of Measure");
        XmlHelper.SetNumberValueInField(LineXML, XmlNamespaces, 'cac:InvoiceLine/cbc:LineExtensionAmount', Line."Sub Total");
        XmlHelper.SetNumberValueInField(LineXML, XmlNamespaces, 'cac:InvoiceLine/cac:AllowanceCharge/cbc:Amount', Line."Total Discount");
        XmlHelper.SetStringValueInField(LineXML, XmlNamespaces, 'cac:InvoiceLine/cbc:Note', MaxStrLen(Line.Description), Line.Description);
        XmlHelper.SetStringValueInField(LineXML, XmlNamespaces, 'cac:InvoiceLine/cac:Item/cbc:Name', MaxStrLen(Line.Description), Line.Description);
        XmlHelper.SetStringValueInField(LineXML, XmlNamespaces, 'cac:InvoiceLine/cac:Item/cbc:Description', MaxStrLen(Line.Description), Line.Description);
        XmlHelper.SetStringValueInField(LineXML, XmlNamespaces, 'cac:InvoiceLine/cac:Item/cac:SellersItemIdentification/cbc:ID', MaxStrLen(Line."Product Code"), Line."Product Code");
        XmlHelper.SetStringValueInField(LineXML, XmlNamespaces, 'cac:InvoiceLine/cac:Item/cac:StandardItemIdentification/cbc:ID', MaxStrLen(Line."Product Code"), Line."Product Code");
        XmlHelper.SetNumberValueInField(LineXML, XmlNamespaces, 'cac:InvoiceLine/cac:Item/cac:ClassifiedTaxCategory/cbc:Percent', Line."VAT Rate");
        XmlHelper.SetNumberValueInField(LineXML, XmlNamespaces, 'cac:InvoiceLine/cac:Price/cbc:PriceAmount', Line."Unit Price");
        PopulateCurrencyForLine(LineXML, XmlNamespaces, Line);
    end;

    local procedure PopulateCurrencyForLine(LineXML: XmlDocument; XmlNamespaces: XmlNamespaceManager; var Line: Record "E-Document Purchase Line")
    var
        LineCurrencyCode: Text;
    begin
        XmlHelper.SetStringValueInField(LineXML, XmlNamespaces, 'cac:InvoiceLine/cbc:LineExtensionAmount/@currencyID', MaxStrLen(LineCurrencyCode), LineCurrencyCode);
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
