// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using Microsoft.eServices.EDocument.Processing.Interfaces;
using Microsoft.Purchases.Vendor;
using System.Utilities;

/// <summary>
/// Reads Peppol BIS 3.0 FR documents into the v2 import draft staging tables.
/// The format is standard UBL, extended with the French party identifiers (SIRET/SIREN) that the
/// outbound side injects, so those are mapped back on import.
/// Spec reference: https://docs.peppol.eu/poacc/billing/3.0/syntax/ubl-invoice/tree/
/// </summary>
codeunit 10985 "E-Doc. Peppol BIS 3.0 FR Hdlr" implements IStructuredFormatReader
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        CommonAggregateComponentsTok: Label 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2', Locked = true;
        CommonBasicComponentsTok: Label 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2', Locked = true;
        InvoiceNamespaceTok: Label 'urn:oasis:names:specification:ubl:schema:xsd:Invoice-2', Locked = true;
        CreditNoteNamespaceTok: Label 'urn:oasis:names:specification:ubl:schema:xsd:CreditNote-2', Locked = true;
        InvoiceLineTok: Label 'cac:InvoiceLine', Locked = true;
        CreditNoteLineTok: Label 'cac:CreditNoteLine', Locked = true;
        SchemeIDGLNTok: Label '0088', Locked = true;
        SchemeIDVATTok: Label '9957', Locked = true;
        NotValidXmlErr: Label 'The received document could not be read as XML.';
        UnsupportedRootElementErr: Label 'Unsupported XML root element: %1. Only Invoice and CreditNote are supported.', Comment = '%1 = XML root element name';

    /// <summary>
    /// Reads a Peppol BIS 3.0 FR XML document and converts it into a draft purchase document.
    /// </summary>
    /// <param name="EDocument">The E-Document record that contains the document metadata and information.</param>
    /// <param name="TempBlob">A temporary blob containing the XML document stream to be processed.</param>
    /// <returns>The draft preparation implementation that should process the created draft.</returns>
    internal procedure ReadIntoDraft(EDocument: Record "E-Document"; TempBlob: Codeunit "Temp Blob"): Enum "E-Doc. Process Draft"
    var
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        PeppolXml: XmlDocument;
        XmlNamespaces: XmlNamespaceManager;
        RootElement: XmlElement;
        ProcessDraft: Enum "E-Doc. Process Draft";
        DocumentPath: Text;
        LineElementName: Text;
    begin
        if not XmlDocument.ReadFrom(TempBlob.CreateInStream(TextEncoding::UTF8), PeppolXml) then
            Error(NotValidXmlErr);

        XmlNamespaces.AddNamespace('cac', CommonAggregateComponentsTok);
        XmlNamespaces.AddNamespace('cbc', CommonBasicComponentsTok);
        XmlNamespaces.AddNamespace('inv', InvoiceNamespaceTok);
        XmlNamespaces.AddNamespace('cn', CreditNoteNamespaceTok);

        PeppolXml.GetRoot(RootElement);
        case UpperCase(RootElement.LocalName()) of
            'INVOICE':
                begin
                    DocumentPath := '/inv:Invoice';
                    LineElementName := InvoiceLineTok;
                    ProcessDraft := Enum::"E-Doc. Process Draft"::"Purchase Invoice";
                end;
            'CREDITNOTE':
                begin
                    DocumentPath := '/cn:CreditNote';
                    LineElementName := CreditNoteLineTok;
                    ProcessDraft := Enum::"E-Doc. Process Draft"::"Purchase Credit Memo";
                end;
            else
                Error(UnsupportedRootElementErr, RootElement.LocalName());
        end;

        EDocument.Direction := EDocument.Direction::Incoming;
        ResetDraft(EDocument);
        EDocumentPurchaseHeader.InsertForEDocument(EDocument);
        PopulateHeader(PeppolXml, XmlNamespaces, DocumentPath, EDocumentPurchaseHeader);
        InsertPurchaseLines(PeppolXml, XmlNamespaces, DocumentPath, LineElementName, EDocumentPurchaseHeader."E-Document Entry No.");
        EDocumentPurchaseHeader.Modify(false);
        exit(ProcessDraft);
    end;

    /// <summary>
    /// Displays a readable view of the purchase information that was extracted from the document.
    /// </summary>
    /// <param name="EDocument">The E-Document record that contains the document to be displayed.</param>
    /// <param name="TempBlob">A temporary blob containing the document data. Not used by this implementation.</param>
    internal procedure View(EDocument: Record "E-Document"; TempBlob: Codeunit "Temp Blob")
    var
        EDocPurchaseHeader: Record "E-Document Purchase Header";
        EDocPurchaseLine: Record "E-Document Purchase Line";
        TempEDocPurchaseHeader: Record "E-Document Purchase Header" temporary;
        TempEDocPurchaseLine: Record "E-Document Purchase Line" temporary;
        EDocReadablePurchaseDoc: Page "E-Doc. Readable Purchase Doc.";
    begin
        EDocPurchaseHeader.GetFromEDocument(EDocument);
        TempEDocPurchaseHeader := EDocPurchaseHeader;
        TempEDocPurchaseHeader.Insert();

        EDocPurchaseLine.SetRange("E-Document Entry No.", EDocPurchaseHeader."E-Document Entry No.");
        if EDocPurchaseLine.FindSet() then
            repeat
                TempEDocPurchaseLine := EDocPurchaseLine;
                TempEDocPurchaseLine.Insert();
            until EDocPurchaseLine.Next() = 0;

        EDocReadablePurchaseDoc.SetBuffer(TempEDocPurchaseHeader, TempEDocPurchaseLine);
        EDocReadablePurchaseDoc.Run();
    end;

    #region Header

    local procedure ResetDraft(EDocument: Record "E-Document")
    var
        EDocPurchaseHeader: Record "E-Document Purchase Header";
        EDocPurchaseLine: Record "E-Document Purchase Line";
    begin
        EDocPurchaseHeader.SetRange("E-Document Entry No.", EDocument."Entry No");
        EDocPurchaseHeader.DeleteAll();
        EDocPurchaseLine.SetRange("E-Document Entry No.", EDocument."Entry No");
        EDocPurchaseLine.DeleteAll();
    end;

    local procedure PopulateHeader(PeppolXml: XmlDocument; XmlNamespaces: XmlNamespaceManager; DocumentPath: Text; var Header: Record "E-Document Purchase Header")
    var
        EDocumentXMLHelper: Codeunit "E-Document PEPPOL Utility";
    begin
#pragma warning disable AA0139 // false positive: overflow handled by SetStringValueInField
        EDocumentXMLHelper.SetStringValueInField(PeppolXml, XmlNamespaces, DocumentPath + '/cbc:ID', MaxStrLen(Header."Sales Invoice No."), Header."Sales Invoice No.");
        EDocumentXMLHelper.SetStringValueInField(PeppolXml, XmlNamespaces, DocumentPath + '/cac:OrderReference/cbc:ID', MaxStrLen(Header."Purchase Order No."), Header."Purchase Order No.");
        EDocumentXMLHelper.SetStringValueInField(PeppolXml, XmlNamespaces, DocumentPath + '/cac:BillingReference/cac:InvoiceDocumentReference/cbc:ID', MaxStrLen(Header."Vendor Invoice No."), Header."Vendor Invoice No.");
#pragma warning restore AA0139
        EDocumentXMLHelper.SetDateValueInField(PeppolXml, XmlNamespaces, DocumentPath + '/cbc:IssueDate', Header."Document Date");
        EDocumentXMLHelper.SetDateValueInField(PeppolXml, XmlNamespaces, DocumentPath + '/cbc:DueDate', Header."Due Date");
        Header."Invoice Date" := Header."Document Date";
        EDocumentXMLHelper.SetCurrencyValueInField(PeppolXml, XmlNamespaces, DocumentPath + '/cbc:DocumentCurrencyCode', MaxStrLen(Header."Currency Code"), Header."Currency Code");
        EDocumentXMLHelper.SetNumberValueInField(PeppolXml, XmlNamespaces, DocumentPath + '/cac:LegalMonetaryTotal/cbc:TaxExclusiveAmount', Header."Sub Total");
        EDocumentXMLHelper.SetNumberValueInField(PeppolXml, XmlNamespaces, DocumentPath + '/cac:LegalMonetaryTotal/cbc:AllowanceTotalAmount', Header."Total Discount");
        EDocumentXMLHelper.SetNumberValueInField(PeppolXml, XmlNamespaces, DocumentPath + '/cac:LegalMonetaryTotal/cbc:TaxInclusiveAmount', Header.Total);
        EDocumentXMLHelper.SetNumberValueInField(PeppolXml, XmlNamespaces, DocumentPath + '/cac:LegalMonetaryTotal/cbc:PayableAmount', Header."Amount Due");
        Header."Total VAT" := Header.Total - Header."Sub Total" - Header."Total Discount";

        PopulateSupplierInfo(PeppolXml, XmlNamespaces, DocumentPath, Header);
        PopulateCustomerInfo(PeppolXml, XmlNamespaces, DocumentPath, Header);
        Header."[BC] Vendor No." := FindVendor(Header);
    end;

    local procedure PopulateSupplierInfo(PeppolXml: XmlDocument; XmlNamespaces: XmlNamespaceManager; DocumentPath: Text; var Header: Record "E-Document Purchase Header")
    var
        EDocumentXMLHelper: Codeunit "E-Document PEPPOL Utility";
        BasePath: Text;
    begin
        BasePath := DocumentPath + '/cac:AccountingSupplierParty/cac:Party';
#pragma warning disable AA0139 // false positive: overflow handled by SetStringValueInField
        EDocumentXMLHelper.SetStringValueInField(PeppolXml, XmlNamespaces, BasePath + '/cac:PartyLegalEntity/cbc:RegistrationName', MaxStrLen(Header."Vendor Company Name"), Header."Vendor Company Name");
        EDocumentXMLHelper.SetStringValueInField(PeppolXml, XmlNamespaces, BasePath + '/cac:PartyName/cbc:Name', MaxStrLen(Header."Vendor Company Name"), Header."Vendor Company Name");
        EDocumentXMLHelper.SetStringValueInField(PeppolXml, XmlNamespaces, BasePath + '/cac:PostalAddress/cbc:StreetName', MaxStrLen(Header."Vendor Address"), Header."Vendor Address");
        EDocumentXMLHelper.SetStringValueInField(PeppolXml, XmlNamespaces, BasePath + '/cac:PostalAddress/cbc:AdditionalStreetName', MaxStrLen(Header."Vendor Address Recipient"), Header."Vendor Address Recipient");
        EDocumentXMLHelper.SetStringValueInField(PeppolXml, XmlNamespaces, BasePath + '/cac:PartyTaxScheme/cbc:CompanyID', MaxStrLen(Header."Vendor VAT Id"), Header."Vendor VAT Id");
        EDocumentXMLHelper.SetStringValueInField(PeppolXml, XmlNamespaces, BasePath + '/cac:Contact/cbc:Name', MaxStrLen(Header."Vendor Contact Name"), Header."Vendor Contact Name");
        // The French export injects the SIRET as PartyIdentification, so it is mapped back as the external vendor id
        EDocumentXMLHelper.SetStringValueInField(PeppolXml, XmlNamespaces, BasePath + '/cac:PartyIdentification/cbc:ID', MaxStrLen(Header."Vendor External Id"), Header."Vendor External Id");
#pragma warning restore AA0139
        ApplyEndpointID(PeppolXml, XmlNamespaces, BasePath, Header."Vendor GLN", Header."Vendor VAT Id");
    end;

    local procedure PopulateCustomerInfo(PeppolXml: XmlDocument; XmlNamespaces: XmlNamespaceManager; DocumentPath: Text; var Header: Record "E-Document Purchase Header")
    var
        EDocumentXMLHelper: Codeunit "E-Document PEPPOL Utility";
        BasePath: Text;
    begin
        BasePath := DocumentPath + '/cac:AccountingCustomerParty/cac:Party';
#pragma warning disable AA0139 // false positive: overflow handled by SetStringValueInField
        EDocumentXMLHelper.SetStringValueInField(PeppolXml, XmlNamespaces, BasePath + '/cac:PartyLegalEntity/cbc:RegistrationName', MaxStrLen(Header."Customer Company Name"), Header."Customer Company Name");
        EDocumentXMLHelper.SetStringValueInField(PeppolXml, XmlNamespaces, BasePath + '/cac:PartyName/cbc:Name', MaxStrLen(Header."Customer Company Name"), Header."Customer Company Name");
        EDocumentXMLHelper.SetStringValueInField(PeppolXml, XmlNamespaces, BasePath + '/cac:PostalAddress/cbc:StreetName', MaxStrLen(Header."Customer Address"), Header."Customer Address");
        EDocumentXMLHelper.SetStringValueInField(PeppolXml, XmlNamespaces, BasePath + '/cac:PostalAddress/cbc:AdditionalStreetName', MaxStrLen(Header."Customer Address Recipient"), Header."Customer Address Recipient");
        EDocumentXMLHelper.SetStringValueInField(PeppolXml, XmlNamespaces, BasePath + '/cac:PartyTaxScheme/cbc:CompanyID', MaxStrLen(Header."Customer VAT Id"), Header."Customer VAT Id");
        // The French export injects the SIRET as PartyIdentification, so it is mapped back as the customer id
        EDocumentXMLHelper.SetStringValueInField(PeppolXml, XmlNamespaces, BasePath + '/cac:PartyIdentification/cbc:ID', MaxStrLen(Header."Customer Company Id"), Header."Customer Company Id");
#pragma warning restore AA0139
        ApplyEndpointID(PeppolXml, XmlNamespaces, BasePath, Header."Customer GLN", Header."Customer VAT Id");
    end;

    local procedure ApplyEndpointID(PeppolXml: XmlDocument; XmlNamespaces: XmlNamespaceManager; BasePath: Text; var GLN: Text[13]; var VATId: Text[100])
    var
        EDocumentXMLHelper: Codeunit "E-Document PEPPOL Utility";
        SchemeID: Text;
        EndpointID: Text;
    begin
        SchemeID := EDocumentXMLHelper.GetNodeValue(PeppolXml, XmlNamespaces, BasePath + '/cbc:EndpointID/@schemeID');
        if SchemeID = '' then
            exit;

        EndpointID := EDocumentXMLHelper.GetNodeValue(PeppolXml, XmlNamespaces, BasePath + '/cbc:EndpointID');
        case SchemeID of
            SchemeIDGLNTok:
                GLN := CopyStr(EndpointID, 1, MaxStrLen(GLN));
            SchemeIDVATTok:
                if VATId = '' then
                    VATId := CopyStr(EndpointID, 1, MaxStrLen(VATId));
        end;
    end;

    local procedure FindVendor(Header: Record "E-Document Purchase Header"): Code[20]
    var
        Vendor: Record Vendor;
        EDocumentImportHelper: Codeunit "E-Document Import Helper";
        VendorGLN: Code[13];
        VendorVATRegistrationNo: Text[20];
    begin
        VendorVATRegistrationNo := CopyStr(Header."Vendor VAT Id", 1, MaxStrLen(VendorVATRegistrationNo));
        if VendorVATRegistrationNo <> '' then begin
            Vendor.SetLoadFields("No.");
            Vendor.SetRange("VAT Registration No.", VendorVATRegistrationNo);
            if Vendor.FindFirst() then
                exit(Vendor."No.");
        end;

        VendorGLN := CopyStr(Header."Vendor GLN", 1, MaxStrLen(VendorGLN));
        if VendorGLN <> '' then begin
            Vendor.Reset();
            Vendor.SetLoadFields("No.");
            Vendor.SetRange(GLN, VendorGLN);
            if Vendor.FindFirst() then
                exit(Vendor."No.");
        end;

        exit(EDocumentImportHelper.FindVendorByNameAndAddress(Header."Vendor Company Name", Header."Vendor Address"));
    end;

    #endregion Header

    #region Lines

    local procedure InsertPurchaseLines(PeppolXml: XmlDocument; XmlNamespaces: XmlNamespaceManager; DocumentPath: Text; LineElementName: Text; EDocumentEntryNo: Integer)
    var
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        LineNodes: XmlNodeList;
        LineNode: XmlNode;
        LineXml: XmlDocument;
    begin
        if not PeppolXml.SelectNodes(DocumentPath + '/' + LineElementName, XmlNamespaces, LineNodes) then
            exit;

        foreach LineNode in LineNodes do begin
            Clear(EDocumentPurchaseLine);
            EDocumentPurchaseLine.Validate("E-Document Entry No.", EDocumentEntryNo);
            EDocumentPurchaseLine."Line No." := EDocumentPurchaseLine.GetNextLineNo(EDocumentEntryNo);
            Clear(LineXml);
            LineXml := XmlDocument.Create();
            LineXml.Add(LineNode.AsXmlElement());
            PopulatePurchaseLine(LineXml, XmlNamespaces, LineElementName, EDocumentPurchaseLine);
            EDocumentPurchaseLine.Insert(false);
        end;
    end;

    local procedure PopulatePurchaseLine(LineXml: XmlDocument; XmlNamespaces: XmlNamespaceManager; LineElementName: Text; var Line: Record "E-Document Purchase Line")
    var
        EDocumentXMLHelper: Codeunit "E-Document PEPPOL Utility";
        QuantityPath: Text;
    begin
        case LineElementName of
            InvoiceLineTok:
                QuantityPath := LineElementName + '/cbc:InvoicedQuantity';
            CreditNoteLineTok:
                QuantityPath := LineElementName + '/cbc:CreditedQuantity';
        end;

#pragma warning disable AA0139 // false positive: overflow handled by SetStringValueInField
        EDocumentXMLHelper.SetStringValueInField(LineXml, XmlNamespaces, LineElementName + '/cac:Item/cbc:Name', MaxStrLen(Line.Description), Line.Description);
        EDocumentXMLHelper.SetStringValueInField(LineXml, XmlNamespaces, LineElementName + '/cbc:ID', MaxStrLen(Line."Product Code"), Line."Product Code");
        EDocumentXMLHelper.SetStringValueInField(LineXml, XmlNamespaces, LineElementName + '/cac:Item/cac:SellersItemIdentification/cbc:ID', MaxStrLen(Line."Product Code"), Line."Product Code");
        EDocumentXMLHelper.SetStringValueInField(LineXml, XmlNamespaces, LineElementName + '/cac:Item/cac:StandardItemIdentification/cbc:ID', MaxStrLen(Line."Product Code"), Line."Product Code");
        EDocumentXMLHelper.SetStringValueInField(LineXml, XmlNamespaces, QuantityPath + '/@unitCode', MaxStrLen(Line."Unit of Measure"), Line."Unit of Measure");
#pragma warning restore AA0139
        EDocumentXMLHelper.SetNumberValueInField(LineXml, XmlNamespaces, QuantityPath, Line.Quantity);
        EDocumentXMLHelper.SetNumberValueInField(LineXml, XmlNamespaces, LineElementName + '/cac:Price/cbc:PriceAmount', Line."Unit Price");
        EDocumentXMLHelper.SetNumberValueInField(LineXml, XmlNamespaces, LineElementName + '/cbc:LineExtensionAmount', Line."Sub Total");
        EDocumentXMLHelper.SetNumberValueInField(LineXml, XmlNamespaces, LineElementName + '/cac:AllowanceCharge/cbc:Amount', Line."Total Discount");
        EDocumentXMLHelper.SetNumberValueInField(LineXml, XmlNamespaces, LineElementName + '/cac:Item/cac:ClassifiedTaxCategory/cbc:Percent', Line."VAT Rate");
        EDocumentXMLHelper.SetCurrencyValueInField(LineXml, XmlNamespaces, LineElementName + '/cbc:LineExtensionAmount/@currencyID', MaxStrLen(Line."Currency Code"), Line."Currency Code");
    end;

    #endregion Lines
}
