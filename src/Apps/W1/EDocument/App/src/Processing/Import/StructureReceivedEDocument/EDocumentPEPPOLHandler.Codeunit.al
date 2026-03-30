// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Format;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using Microsoft.eServices.EDocument.Processing.Interfaces;
using System.Utilities;

codeunit 6173 "E-Document PEPPOL Handler" implements IStructuredFormatReader
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure ReadIntoDraft(EDocument: Record "E-Document"; TempBlob: Codeunit "Temp Blob"): Enum "E-Doc. Process Draft"
    var
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentXMLHelper: Codeunit "E-Document XML Helper";
        DocStream: InStream;
        PeppolXML: XmlDocument;
        XmlNamespaces: XmlNamespaceManager;
        XmlElement: XmlElement;
        CreditNoteNotSupportedLbl: Label 'Credit notes are not supported';
    begin
        EDocumentPurchaseHeader.InsertForEDocument(EDocument);

        TempBlob.CreateInStream(DocStream, TextEncoding::UTF8);
        XmlDocument.ReadFrom(DocStream, PeppolXML);
        EDocumentXMLHelper.InitializePEPPOLNamespaces(XmlNamespaces);

        PeppolXML.GetRoot(XmlElement);
        case UpperCase(XmlElement.LocalName()) of
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

    local procedure PopulatePurchaseInvoiceHeader(PeppolXML: XmlDocument; XmlNamespaces: XmlNamespaceManager; var EDocumentPurchaseHeader: Record "E-Document Purchase Header")
    var
        EDocumentXMLHelper: Codeunit "E-Document XML Helper";
        XMLNode: XmlNode;
    begin
        EDocumentXMLHelper.SetStringValueInField(PeppolXML, XMLNamespaces, '/inv:Invoice/cbc:ID', MaxStrLen(EDocumentPurchaseHeader."Sales Invoice No."), EDocumentPurchaseHeader."Sales Invoice No.");
        EDocumentXMLHelper.SetStringValueInField(PeppolXML, XMLNamespaces, '/inv:Invoice/cac:OrderReference/cbc:ID', MaxStrLen(EDocumentPurchaseHeader."Purchase Order No."), EDocumentPurchaseHeader."Purchase Order No.");
        EDocumentXMLHelper.SetStringValueInField(PeppolXML, XMLNamespaces, '/inv:Invoice/cac:AccountingSupplierParty/cac:Party/cac:PartyName/cbc:Name', MaxStrLen(EDocumentPurchaseHeader."Vendor Company Name"), EDocumentPurchaseHeader."Vendor Company Name");
        // Line below, using PayeeParty, shall be used when the Payee is different from the Seller. Otherwise, it will not be shown in the XML.
        EDocumentXMLHelper.SetStringValueInField(PeppolXML, XMLNamespaces, '/inv:Invoice/cac:PayeeParty/cac:PartyName/cbc:Name', MaxStrLen(EDocumentPurchaseHeader."Vendor Company Name"), EDocumentPurchaseHeader."Vendor Company Name");
        EDocumentXMLHelper.SetNumberValueInField(PeppolXML, XMLNamespaces, '/inv:Invoice/cac:LegalMonetaryTotal/cbc:AllowanceTotalAmount', EDocumentPurchaseHeader."Total Discount");
        EDocumentXMLHelper.SetNumberValueInField(PeppolXML, XMLNamespaces, '/inv:Invoice/cac:LegalMonetaryTotal/cbc:PayableAmount', EDocumentPurchaseHeader."Amount Due");
        EDocumentXMLHelper.SetNumberValueInField(PeppolXML, XMLNamespaces, '/inv:Invoice/cac:LegalMonetaryTotal/cbc:PayableAmount', EDocumentPurchaseHeader.Total);
        EDocumentXMLHelper.SetStringValueInField(PeppolXML, XMLNamespaces, '/inv:Invoice/cac:AccountingSupplierParty/cac:Party/cac:Contact/cbc:Name', MaxStrLen(EDocumentPurchaseHeader."Vendor Contact Name"), EDocumentPurchaseHeader."Vendor Contact Name");
        EDocumentXMLHelper.SetStringValueInField(PeppolXML, XMLNamespaces, '/inv:Invoice/cac:AccountingSupplierParty/cac:Party/cac:PostalAddress/cbc:StreetName', MaxStrLen(EDocumentPurchaseHeader."Vendor Address"), EDocumentPurchaseHeader."Vendor Address");
        EDocumentXMLHelper.SetStringValueInField(PeppolXML, XMLNamespaces, '/inv:Invoice/cac:AccountingCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:CompanyID', MaxStrLen(EDocumentPurchaseHeader."Customer VAT Id"), EDocumentPurchaseHeader."Customer VAT Id");
        // Line below, using PayeeParty, shall be used when the Payee is different from the Seller. Otherwise, it will not be shown in the XML.
        EDocumentXMLHelper.SetStringValueInField(PeppolXML, XMLNamespaces, '/inv:Invoice/cac:PayeeParty/cac:PartyLegalEntity/cbc:CompanyID', MaxStrLen(EDocumentPurchaseHeader."Vendor VAT Id"), EDocumentPurchaseHeader."Vendor VAT Id");
        EDocumentXMLHelper.SetNumberValueInField(PeppolXML, XMLNamespaces, '/inv:Invoice/cac:LegalMonetaryTotal/cbc:TaxExclusiveAmount', EDocumentPurchaseHeader."Sub Total");
        EDocumentPurchaseHeader."Total VAT" := EDocumentPurchaseHeader."Total" - EDocumentPurchaseHeader."Sub Total" - EDocumentPurchaseHeader."Total Discount";
        EDocumentXMLHelper.SetDateValueInField(PeppolXML, XMLNamespaces, '/inv:Invoice/cbc:DueDate', EDocumentPurchaseHeader."Due Date");
        EDocumentXMLHelper.SetDateValueInField(PeppolXML, XMLNamespaces, '/inv:Invoice/cbc:IssueDate', EDocumentPurchaseHeader."Document Date");
        EDocumentXMLHelper.SetStringValueInField(PeppolXML, XmlNamespaces, '/inv:Invoice/cac:AccountingSupplierParty/cac:Party/cac:PartyTaxScheme/cbc:CompanyID', MaxStrLen(EDocumentPurchaseHeader."Vendor VAT Id"), EDocumentPurchaseHeader."Vendor VAT Id");
        EDocumentXMLHelper.SetCurrencyValueInField(PeppolXML, XmlNamespaces, '/inv:Invoice/cbc:DocumentCurrencyCode', MaxStrLen(EDocumentPurchaseHeader."Currency Code"), EDocumentPurchaseHeader."Currency Code");
        EDocumentXMLHelper.SetStringValueInField(PeppolXML, XmlNamespaces, '/inv:Invoice/cac:AccountingCustomerParty/cac:Party/cac:PartyName/cbc:Name', MaxStrLen(EDocumentPurchaseHeader."Customer Company Name"), EDocumentPurchaseHeader."Customer Company Name");
        EDocumentXMLHelper.SetStringValueInField(PeppolXML, XmlNamespaces, '/inv:Invoice/cac:AccountingCustomerParty/cac:Party/cac:PartyTaxScheme/cbc:CompanyID', MaxStrLen(EDocumentPurchaseHeader."Customer VAT Id"), EDocumentPurchaseHeader."Customer VAT Id");
        EDocumentXMLHelper.SetStringValueInField(PeppolXML, XmlNamespaces, '/inv:Invoice/cac:AccountingCustomerParty/cac:Party/cac:PostalAddress/cbc:StreetName', MaxStrLen(EDocumentPurchaseHeader."Customer Address"), EDocumentPurchaseHeader."Customer Address");
        EDocumentXMLHelper.SetStringValueInField(PeppolXML, XmlNamespaces, '/inv:Invoice/cac:AccountingCustomerParty/cac:Party/cbc:EndpointID', MaxStrLen(EDocumentPurchaseHeader."Customer GLN"), EDocumentPurchaseHeader."Customer GLN");
        EDocumentXMLHelper.SetStringValueInField(PeppolXML, XmlNamespaces, '/inv:Invoice/cac:AccountingCustomerParty/cac:Party/cbc:EndpointID/@schemeID', MaxStrLen(EDocumentPurchaseHeader."Customer Company Id"), EDocumentPurchaseHeader."Customer Company Id");

        if PeppolXML.SelectSingleNode('/inv:Invoice/cac:AccountingSupplierParty/cac:Party/cbc:EndpointID/@schemeID', XmlNamespaces, XMLNode) then
            if XMLNode.AsXmlAttribute().Value() = '0088' then // GLN
                EDocumentXMLHelper.SetStringValueInField(PeppolXML, XmlNamespaces, '/inv:Invoice/cac:AccountingSupplierParty/cac:Party/cbc:EndpointID', MaxStrLen(EDocumentPurchaseHeader."Vendor GLN"), EDocumentPurchaseHeader."Vendor GLN");
    end;

    local procedure PopulateEDocumentPurchaseLine(LineXML: XmlDocument; XmlNamespaces: XmlNamespaceManager; var EDocumentPurchaseLine: Record "E-Document Purchase Line")
    var
        EDocumentXMLHelper: Codeunit "E-Document XML Helper";
    begin
        EDocumentXMLHelper.SetNumberValueInField(LineXML, XMLNamespaces, 'cac:InvoiceLine/cbc:InvoicedQuantity', EDocumentPurchaseLine.Quantity);
        EDocumentXMLHelper.SetStringValueInField(LineXML, XMLNamespaces, 'cac:InvoiceLine/cbc:InvoicedQuantity/@unitCode', MaxStrLen(EDocumentPurchaseLine."Unit of Measure"), EDocumentPurchaseLine."Unit of Measure");
        EDocumentXMLHelper.SetNumberValueInField(LineXML, XMLNamespaces, 'cac:InvoiceLine/cbc:LineExtensionAmount', EDocumentPurchaseLine."Sub Total");
        EDocumentXMLHelper.SetCurrencyValueInField(LineXML, XmlNamespaces, 'cac:InvoiceLine/cbc:LineExtensionAmount/@currencyID', MaxStrLen(EDocumentPurchaseLine."Currency Code"), EDocumentPurchaseLine."Currency Code");
        EDocumentXMLHelper.SetNumberValueInField(LineXML, XMLNamespaces, 'cac:InvoiceLine/cac:AllowanceCharge/cbc:Amount', EDocumentPurchaseLine."Total Discount");
        EDocumentXMLHelper.SetStringValueInField(LineXML, XMLNamespaces, 'cac:InvoiceLine/cbc:Note', MaxStrLen(EDocumentPurchaseLine.Description), EDocumentPurchaseLine.Description);
        EDocumentXMLHelper.SetStringValueInField(LineXML, XMLNamespaces, 'cac:InvoiceLine/cac:Item/cbc:Name', MaxStrLen(EDocumentPurchaseLine.Description), EDocumentPurchaseLine.Description);
        EDocumentXMLHelper.SetStringValueInField(LineXML, XMLNamespaces, 'cac:InvoiceLine/cac:Item/cbc:Description', MaxStrLen(EDocumentPurchaseLine.Description), EDocumentPurchaseLine.Description);
        EDocumentXMLHelper.SetStringValueInField(LineXML, XMLNamespaces, 'cac:InvoiceLine/cac:Item/cac:SellersItemIdentification/cbc:ID', MaxStrLen(EDocumentPurchaseLine."Product Code"), EDocumentPurchaseLine."Product Code");
        EDocumentXMLHelper.SetStringValueInField(LineXML, XMLNamespaces, 'cac:InvoiceLine/cac:Item/cac:StandardItemIdentification/cbc:ID', MaxStrLen(EDocumentPurchaseLine."Product Code"), EDocumentPurchaseLine."Product Code");
        EDocumentXMLHelper.SetNumberValueInField(LineXML, XMLNamespaces, 'cac:InvoiceLine/cac:Item/cac:ClassifiedTaxCategory/cbc:Percent', EDocumentPurchaseLine."VAT Rate");
        EDocumentXMLHelper.SetNumberValueInField(LineXML, XMLNamespaces, 'cac:InvoiceLine/cac:Price/cbc:PriceAmount', EDocumentPurchaseLine."Unit Price");
    end;

    procedure View(EDocument: Record "E-Document"; TempBlob: Codeunit "Temp Blob")
    begin
        Error('A view is not implemented for this handler.');
    end;
}
