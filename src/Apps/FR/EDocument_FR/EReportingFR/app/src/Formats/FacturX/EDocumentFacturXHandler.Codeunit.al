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
using System.IO;
using System.Utilities;

/// <summary>
/// Reads Factur-X FR documents into the v2 import draft staging tables.
/// Factur-X is a PDF/A-3 container that embeds the invoice as UN/CEFACT Cross Industry Invoice (CII)
/// XML. This codeunit therefore covers both the Structure stage (lifting the CII XML out of the PDF)
/// and the Read into Draft stage (parsing the CII XML), and it accepts either the PDF/A-3 container
/// or the plain CII XML.
/// Spec reference: https://fnfe-mpe.org/factur-x/
/// </summary>
codeunit 10986 "E-Document Factur-X Handler" implements IStructuredFormatReader, IStructureReceivedEDocument, IStructuredDataType
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        GlobalEmbeddedBlob: Codeunit "Temp Blob";
        StructuredData: Text;
        CrossIndustryInvoiceTok: Label 'CROSSINDUSTRYINVOICE', Locked = true;
        RsmNamespaceTok: Label 'urn:un:unece:uncefact:data:standard:CrossIndustryInvoice:100', Locked = true;
        RamNamespaceTok: Label 'urn:un:unece:uncefact:data:standard:ReusableAggregateBusinessInformationEntity:100', Locked = true;
        UdtNamespaceTok: Label 'urn:un:unece:uncefact:data:standard:UnqualifiedDataType:100', Locked = true;
        AgreementPathTok: Label '//rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement', Locked = true;
        SettlementPathTok: Label '//rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement', Locked = true;
        LinePathTok: Label 'ram:IncludedSupplyChainTradeLineItem', Locked = true;
        NotValidXmlErr: Label 'The received document could not be read as XML.';
        NoEmbeddedInvoiceErr: Label 'The PDF file does not contain an embedded Factur-X invoice.';
        UnsupportedRootElementErr: Label 'Unsupported XML root element: %1. Only CrossIndustryInvoice is supported.', Comment = '%1 = XML root element name';
        UnsupportedTypeCodeErr: Label 'Unsupported document type code %1. Only invoice and credit memo type codes are supported.', Comment = '%1 = UNCL1001 document type code';

    #region Read into draft

    /// <summary>
    /// Reads a Factur-X document and converts it into a draft purchase document.
    /// </summary>
    /// <param name="EDocument">The E-Document record that contains the document metadata and information.</param>
    /// <param name="TempBlob">A temporary blob containing the Factur-X PDF/A-3 file or its CII XML.</param>
    /// <returns>The draft preparation implementation that should process the created draft.</returns>
    internal procedure ReadIntoDraft(EDocument: Record "E-Document"; TempBlob: Codeunit "Temp Blob"): Enum "E-Doc. Process Draft"
    var
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        CIIXml: XmlDocument;
        XmlNamespaces: XmlNamespaceManager;
        RootElement: XmlElement;
        ProcessDraft: Enum "E-Doc. Process Draft";
        TypeCode: Text;
    begin
        CIIXml := ReadCIIDocument(TempBlob, XmlNamespaces);
        CIIXml.GetRoot(RootElement);
        if UpperCase(RootElement.LocalName()) <> CrossIndustryInvoiceTok then
            Error(UnsupportedRootElementErr, RootElement.LocalName());

        TypeCode := GetNodeValue(CIIXml, XmlNamespaces, '//rsm:ExchangedDocument/ram:TypeCode');
        case true of
            IsInvoiceTypeCode(TypeCode):
                ProcessDraft := Enum::"E-Doc. Process Draft"::"Purchase Invoice";
            IsCreditMemoTypeCode(TypeCode):
                ProcessDraft := Enum::"E-Doc. Process Draft"::"Purchase Credit Memo";
            else
                Error(UnsupportedTypeCodeErr, TypeCode);
        end;

        EDocument.Direction := EDocument.Direction::Incoming;
        ResetDraft(EDocument);
        EDocumentPurchaseHeader.InsertForEDocument(EDocument);
        PopulateHeader(CIIXml, XmlNamespaces, EDocumentPurchaseHeader);
        InsertPurchaseLines(CIIXml, XmlNamespaces, EDocumentPurchaseHeader."E-Document Entry No.");
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

    #endregion Read into draft

    #region Structure received document

    /// <summary>
    /// Lifts the embedded CII XML out of the Factur-X PDF/A-3 container so that the draft is built from
    /// the exact data the vendor sent instead of from the rendered page.
    /// </summary>
    /// <param name="EDocumentDataStorage">The data storage entry that holds the received file.</param>
    /// <returns>The structured data that the Read into Draft stage consumes.</returns>
    internal procedure StructureReceivedEDocument(EDocumentDataStorage: Record "E-Doc. Data Storage"): Interface IStructuredDataType
    var
        CIIXml: XmlDocument;
        XmlNamespaces: XmlNamespaceManager;
    begin
        CIIXml := ReadCIIDocument(GetSourceBlob(EDocumentDataStorage), XmlNamespaces);
        CIIXml.WriteTo(StructuredData);
        if StructuredData = '' then
            Error(NoEmbeddedInvoiceErr);
        exit(this);
    end;

    local procedure GetSourceBlob(EDocumentDataStorage: Record "E-Doc. Data Storage") SourceBlob: Codeunit "Temp Blob"
    begin
        EDocumentDataStorage.CalcFields("Data Storage");
        SourceBlob.FromRecord(EDocumentDataStorage, EDocumentDataStorage.FieldNo("Data Storage"));
    end;

    internal procedure GetFileFormat(): Enum "E-Doc. File Format"
    begin
        exit("E-Doc. File Format"::XML);
    end;

    internal procedure GetContent(): Text
    begin
        exit(StructuredData);
    end;

    internal procedure GetReadIntoDraftImpl(): Enum "E-Doc. Read into Draft"
    begin
        exit("E-Doc. Read into Draft"::"Factur-X FR");
    end;

    #endregion Structure received document

    #region CII document access

    local procedure ReadCIIDocument(TempBlob: Codeunit "Temp Blob"; var XmlNamespaces: XmlNamespaceManager) CIIXml: XmlDocument
    var
        CIIBlob: Codeunit "Temp Blob";
    begin
        CIIBlob := ExtractCIIXml(TempBlob);
        if not XmlDocument.ReadFrom(CIIBlob.CreateInStream(TextEncoding::UTF8), CIIXml) then
            Error(NotValidXmlErr);

        XmlNamespaces.AddNamespace('rsm', RsmNamespaceTok);
        XmlNamespaces.AddNamespace('ram', RamNamespaceTok);
        XmlNamespaces.AddNamespace('udt', UdtNamespaceTok);
    end;

    /// <summary>
    /// Returns the embedded CII XML of a PDF/A-3 container. When the blob is not a PDF, or the PDF does
    /// not embed an attachment, the blob is returned unchanged so that plain CII XML is supported too.
    /// </summary>
    local procedure ExtractCIIXml(TempBlob: Codeunit "Temp Blob"): Codeunit "Temp Blob"
    var
        PdfInStream: InStream;
    begin
        TempBlob.CreateInStream(PdfInStream);
        if TryGetEmbeddedAttachment(PdfInStream) then
            exit(GlobalEmbeddedBlob);
        exit(TempBlob);
    end;

    [TryFunction]
    local procedure TryGetEmbeddedAttachment(PdfInStream: InStream)
    var
        PDFDocument: Codeunit "PDF Document";
    begin
        Clear(GlobalEmbeddedBlob);
        if not PDFDocument.GetDocumentAttachmentStream(PdfInStream, GlobalEmbeddedBlob) then
            Error(NoEmbeddedInvoiceErr);
    end;

    #endregion CII document access

    #region Document type codes

    local procedure IsInvoiceTypeCode(TypeCode: Text): Boolean
    begin
        case TypeCode of
            '80', '82', '84', '130', '202', '203', '204', '211', '295', '325', '326', '380', '383', '384', '385', '386', '387', '388', '389', '390', '393', '394', '395', '456', '457', '527', '575', '623', '633', '751', '780', '875', '876', '877', '935':
                exit(true);
        end;

        exit(false);
    end;

    local procedure IsCreditMemoTypeCode(TypeCode: Text): Boolean
    begin
        case TypeCode of
            '81', '83', '261', '262', '296', '308', '381', '396', '420', '458', '532':
                exit(true);
        end;

        exit(false);
    end;

    #endregion Document type codes

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

    local procedure PopulateHeader(CIIXml: XmlDocument; XmlNamespaces: XmlNamespaceManager; var Header: Record "E-Document Purchase Header")
    begin
        PopulateDocumentInfo(CIIXml, XmlNamespaces, Header);
        PopulateSupplierInfo(CIIXml, XmlNamespaces, Header);
        PopulateCustomerInfo(CIIXml, XmlNamespaces, Header);
        PopulateAmountsAndDates(CIIXml, XmlNamespaces, Header);
        Header."[BC] Vendor No." := FindVendor(Header);
    end;

    local procedure PopulateDocumentInfo(CIIXml: XmlDocument; XmlNamespaces: XmlNamespaceManager; var Header: Record "E-Document Purchase Header")
    begin
        Header."Sales Invoice No." := CopyStr(GetNodeValue(CIIXml, XmlNamespaces, '//rsm:ExchangedDocument/ram:ID'), 1, MaxStrLen(Header."Sales Invoice No."));
        Header."Purchase Order No." := CopyStr(GetNodeValue(CIIXml, XmlNamespaces, AgreementPathTok + '/ram:BuyerOrderReferencedDocument/ram:IssuerAssignedID'), 1, MaxStrLen(Header."Purchase Order No."));
        Header."Vendor Invoice No." := CopyStr(GetNodeValue(CIIXml, XmlNamespaces, SettlementPathTok + '/ram:InvoiceReferencedDocument/ram:IssuerAssignedID'), 1, MaxStrLen(Header."Vendor Invoice No."));
    end;

    local procedure PopulateSupplierInfo(CIIXml: XmlDocument; XmlNamespaces: XmlNamespaceManager; var Header: Record "E-Document Purchase Header")
    var
        BasePath: Text;
    begin
        BasePath := AgreementPathTok + '/ram:SellerTradeParty';
        Header."Vendor Company Name" := CopyStr(GetNodeValue(CIIXml, XmlNamespaces, BasePath + '/ram:Name'), 1, MaxStrLen(Header."Vendor Company Name"));
        Header."Vendor Address" := CopyStr(GetNodeValue(CIIXml, XmlNamespaces, BasePath + '/ram:PostalTradeAddress/ram:LineOne'), 1, MaxStrLen(Header."Vendor Address"));
        Header."Vendor Address Recipient" := CopyStr(GetNodeValue(CIIXml, XmlNamespaces, BasePath + '/ram:PostalTradeAddress/ram:LineTwo'), 1, MaxStrLen(Header."Vendor Address Recipient"));
        Header."Vendor Contact Name" := CopyStr(GetNodeValue(CIIXml, XmlNamespaces, BasePath + '/ram:DefinedTradeContact/ram:PersonName'), 1, MaxStrLen(Header."Vendor Contact Name"));
        Header."Vendor VAT Id" := CopyStr(GetVATRegistrationNo(CIIXml, XmlNamespaces, BasePath), 1, MaxStrLen(Header."Vendor VAT Id"));
        Header."Vendor GLN" := CopyStr(GetNodeValue(CIIXml, XmlNamespaces, BasePath + '/ram:GlobalID'), 1, MaxStrLen(Header."Vendor GLN"));
        Header."Vendor External Id" := CopyStr(GetNodeValue(CIIXml, XmlNamespaces, BasePath + '/ram:ID'), 1, MaxStrLen(Header."Vendor External Id"));
    end;

    local procedure PopulateCustomerInfo(CIIXml: XmlDocument; XmlNamespaces: XmlNamespaceManager; var Header: Record "E-Document Purchase Header")
    var
        BasePath: Text;
    begin
        BasePath := AgreementPathTok + '/ram:BuyerTradeParty';
        Header."Customer Company Name" := CopyStr(GetNodeValue(CIIXml, XmlNamespaces, BasePath + '/ram:Name'), 1, MaxStrLen(Header."Customer Company Name"));
        Header."Customer Company Id" := CopyStr(GetNodeValue(CIIXml, XmlNamespaces, BasePath + '/ram:ID'), 1, MaxStrLen(Header."Customer Company Id"));
        Header."Customer Address" := CopyStr(GetNodeValue(CIIXml, XmlNamespaces, BasePath + '/ram:PostalTradeAddress/ram:LineOne'), 1, MaxStrLen(Header."Customer Address"));
        Header."Customer Address Recipient" := CopyStr(GetNodeValue(CIIXml, XmlNamespaces, BasePath + '/ram:PostalTradeAddress/ram:LineTwo'), 1, MaxStrLen(Header."Customer Address Recipient"));
        Header."Customer VAT Id" := CopyStr(GetVATRegistrationNo(CIIXml, XmlNamespaces, BasePath), 1, MaxStrLen(Header."Customer VAT Id"));
        Header."Customer GLN" := CopyStr(GetNodeValue(CIIXml, XmlNamespaces, BasePath + '/ram:GlobalID'), 1, MaxStrLen(Header."Customer GLN"));
    end;

    local procedure PopulateAmountsAndDates(CIIXml: XmlDocument; XmlNamespaces: XmlNamespaceManager; var Header: Record "E-Document Purchase Header")
    var
        EDocumentXMLHelper: Codeunit "E-Document PEPPOL Utility";
        SummationPath: Text;
    begin
        SummationPath := SettlementPathTok + '/ram:SpecifiedTradeSettlementHeaderMonetarySummation';
        Header."Document Date" := ReadDate(GetNodeValue(CIIXml, XmlNamespaces, '//rsm:ExchangedDocument/ram:IssueDateTime/udt:DateTimeString'));
        Header."Invoice Date" := Header."Document Date";
        Header."Due Date" := ReadDate(GetNodeValue(CIIXml, XmlNamespaces, SettlementPathTok + '/ram:SpecifiedTradePaymentTerms/ram:DueDateDateTime/udt:DateTimeString'));
        Header."Sub Total" := ReadDecimal(GetNodeValue(CIIXml, XmlNamespaces, SummationPath + '/ram:TaxBasisTotalAmount'));
        Header."Total Discount" := ReadDecimal(GetNodeValue(CIIXml, XmlNamespaces, SummationPath + '/ram:AllowanceTotalAmount'));
        Header.Total := ReadDecimal(GetNodeValue(CIIXml, XmlNamespaces, SummationPath + '/ram:GrandTotalAmount'));
        Header."Amount Due" := ReadDecimal(GetNodeValue(CIIXml, XmlNamespaces, SummationPath + '/ram:DuePayableAmount'));
        Header."Total VAT" := ReadDecimal(GetNodeValue(CIIXml, XmlNamespaces, SummationPath + '/ram:TaxTotalAmount'));
        if Header."Total VAT" = 0 then
            Header."Total VAT" := Header.Total - Header."Sub Total";
        EDocumentXMLHelper.SetCurrencyIfForeign(GetNodeValue(CIIXml, XmlNamespaces, SettlementPathTok + '/ram:InvoiceCurrencyCode'), Header."Currency Code");
    end;

    local procedure GetVATRegistrationNo(CIIXml: XmlDocument; XmlNamespaces: XmlNamespaceManager; PartyPath: Text) Value: Text
    begin
        // Scheme VA identifies the VAT registration number, other schemes identify e.g. the SIRET number (FC)
        Value := GetNodeValue(CIIXml, XmlNamespaces, PartyPath + '/ram:SpecifiedTaxRegistration/ram:ID[@schemeID=''VA'']');
        if Value = '' then
            Value := GetNodeValue(CIIXml, XmlNamespaces, PartyPath + '/ram:SpecifiedTaxRegistration/ram:ID');
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

    local procedure InsertPurchaseLines(CIIXml: XmlDocument; XmlNamespaces: XmlNamespaceManager; EDocumentEntryNo: Integer)
    var
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        LineNodes: XmlNodeList;
        LineNode: XmlNode;
        LineXml: XmlDocument;
    begin
        if not CIIXml.SelectNodes('//rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem', XmlNamespaces, LineNodes) then
            exit;

        foreach LineNode in LineNodes do begin
            Clear(EDocumentPurchaseLine);
            EDocumentPurchaseLine.Validate("E-Document Entry No.", EDocumentEntryNo);
            EDocumentPurchaseLine."Line No." := EDocumentPurchaseLine.GetNextLineNo(EDocumentEntryNo);
            Clear(LineXml);
            LineXml := XmlDocument.Create();
            LineXml.Add(LineNode.AsXmlElement());
            PopulatePurchaseLine(LineXml, XmlNamespaces, EDocumentPurchaseLine);
            EDocumentPurchaseLine.Insert(false);
        end;
    end;

    local procedure PopulatePurchaseLine(LineXml: XmlDocument; XmlNamespaces: XmlNamespaceManager; var Line: Record "E-Document Purchase Line")
    var
        EDocumentXMLHelper: Codeunit "E-Document PEPPOL Utility";
        Value: Text;
    begin
        Line.Description := CopyStr(GetNodeValue(LineXml, XmlNamespaces, LinePathTok + '/ram:SpecifiedTradeProduct/ram:Name'), 1, MaxStrLen(Line.Description));

        Value := GetNodeValue(LineXml, XmlNamespaces, LinePathTok + '/ram:SpecifiedTradeProduct/ram:SellerAssignedID');
        if Value = '' then
            Value := GetNodeValue(LineXml, XmlNamespaces, LinePathTok + '/ram:SpecifiedTradeProduct/ram:GlobalID');
        if Value = '' then
            Value := GetNodeValue(LineXml, XmlNamespaces, LinePathTok + '/ram:AssociatedDocumentLineDocument/ram:LineID');
        Line."Product Code" := CopyStr(Value, 1, MaxStrLen(Line."Product Code"));

        Line.Quantity := ReadDecimal(GetNodeValue(LineXml, XmlNamespaces, LinePathTok + '/ram:SpecifiedLineTradeDelivery/ram:BilledQuantity'));
        Line."Unit of Measure" := CopyStr(GetNodeValue(LineXml, XmlNamespaces, LinePathTok + '/ram:SpecifiedLineTradeDelivery/ram:BilledQuantity/@unitCode'), 1, MaxStrLen(Line."Unit of Measure"));
        Line."Unit Price" := ReadDecimal(GetNodeValue(LineXml, XmlNamespaces, LinePathTok + '/ram:SpecifiedLineTradeAgreement/ram:NetPriceProductTradePrice/ram:ChargeAmount'));
        Line."Sub Total" := ReadDecimal(GetNodeValue(LineXml, XmlNamespaces, LinePathTok + '/ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeSettlementLineMonetarySummation/ram:LineTotalAmount'));
        Line."VAT Rate" := ReadDecimal(GetNodeValue(LineXml, XmlNamespaces, LinePathTok + '/ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax/ram:RateApplicablePercent'));
        EDocumentXMLHelper.SetCurrencyIfForeign(GetNodeValue(LineXml, XmlNamespaces, LinePathTok + '/ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeSettlementLineMonetarySummation/ram:LineTotalAmount/@currencyID'), Line."Currency Code");
    end;

    #endregion Lines

    #region Value helpers

    local procedure GetNodeValue(XmlDoc: XmlDocument; XmlNamespaces: XmlNamespaceManager; Path: Text): Text
    var
        EDocumentXMLHelper: Codeunit "E-Document PEPPOL Utility";
    begin
        exit(EDocumentXMLHelper.GetNodeValue(XmlDoc, XmlNamespaces, Path));
    end;

    local procedure ReadDecimal(Value: Text) DecimalValue: Decimal
    begin
        if Value = '' then
            exit(0);
        if not Evaluate(DecimalValue, Value, 9) then
            exit(0);
    end;

    local procedure ReadDate(Value: Text) DateValue: Date
    var
        Year: Integer;
        Month: Integer;
        Day: Integer;
    begin
        // CII dates use date format 102: YYYYMMDD
        if StrLen(Value) <> 8 then begin
            if Evaluate(DateValue, Value, 9) then
                exit(DateValue);
            exit(0D);
        end;
        if not Evaluate(Year, CopyStr(Value, 1, 4)) then
            exit(0D);
        if not Evaluate(Month, CopyStr(Value, 5, 2)) then
            exit(0D);
        if not Evaluate(Day, CopyStr(Value, 7, 2)) then
            exit(0D);
        exit(DMY2Date(Day, Month, Year));
    end;

    #endregion Value helpers
}
