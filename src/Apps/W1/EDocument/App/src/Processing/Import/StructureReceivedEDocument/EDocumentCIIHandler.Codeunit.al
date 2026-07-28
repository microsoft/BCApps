// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Format;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using Microsoft.eServices.EDocument.Processing.Interfaces;
using Microsoft.Purchases.Vendor;
using System.IO;
using System.Utilities;

/// <summary>
/// Reads UN/CEFACT Cross Industry Invoice (CII) documents into the v2 import draft staging tables.
/// CII is the syntax used by the hybrid PDF/A-3 formats ZUGFeRD (DE) and Factur-X (FR), and the blob
/// handed to this reader may therefore be either the plain CII XML or the PDF/A-3 container that
/// embeds it.
/// Spec reference: https://unece.org/trade/uncefact/xml-schemas
/// </summary>
codeunit 6410 "E-Document CII Handler" implements IStructuredFormatReader
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        GlobalEmbeddedBlob: Codeunit "Temp Blob";
        RsmNamespaceTok: Label 'urn:un:unece:uncefact:data:standard:CrossIndustryInvoice:100', Locked = true;
        RamNamespaceTok: Label 'urn:un:unece:uncefact:data:standard:ReusableAggregateBusinessInformationEntity:100', Locked = true;
        UdtNamespaceTok: Label 'urn:un:unece:uncefact:data:standard:UnqualifiedDataType:100', Locked = true;
        CrossIndustryInvoiceTok: Label 'CROSSINDUSTRYINVOICE', Locked = true;
        NotValidXmlErr: Label 'The received document could not be read as XML.';
        UnsupportedRootElementErr: Label 'Unsupported XML root element: %1. Only CrossIndustryInvoice is supported.', Comment = '%1 = XML root element name';
        UnsupportedTypeCodeErr: Label 'Unsupported document type code %1. Only invoice and credit memo type codes are supported.', Comment = '%1 = UNCL1001 document type code';

    /// <summary>
    /// Reads a Cross Industry Invoice document and converts it into a draft purchase document.
    /// </summary>
    /// <param name="EDocument">The E-Document record that contains the document metadata and information.</param>
    /// <param name="TempBlob">A temporary blob containing either the CII XML or the PDF/A-3 file that embeds it.</param>
    /// <returns>The draft preparation implementation that should process the created draft.</returns>
    procedure ReadIntoDraft(EDocument: Record "E-Document"; TempBlob: Codeunit "Temp Blob"): Enum "E-Doc. Process Draft"
    var
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        CIIXml: XmlDocument;
        XmlNamespaces: XmlNamespaceManager;
        RootElement: XmlElement;
        ProcessDraft: Enum "E-Doc. Process Draft";
        TypeCode: Text;
    begin
        CIIXml := GetCIIDocument(TempBlob, XmlNamespaces);
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
    procedure View(EDocument: Record "E-Document"; TempBlob: Codeunit "Temp Blob")
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

    /// <summary>
    /// Reads the CII XML from a blob that is either the plain CII XML or a PDF/A-3 container embedding it.
    /// </summary>
    /// <param name="TempBlob">The blob to read.</param>
    /// <param name="XmlNamespaces">Returns a namespace manager initialized with the CII namespace prefixes.</param>
    /// <returns>The CII XML document.</returns>
    procedure GetCIIDocument(TempBlob: Codeunit "Temp Blob"; var XmlNamespaces: XmlNamespaceManager) CIIXml: XmlDocument
    var
        CIIBlob: Codeunit "Temp Blob";
    begin
        CIIBlob := ExtractCIIXml(TempBlob);
        if not XmlDocument.ReadFrom(CIIBlob.CreateInStream(TextEncoding::UTF8), CIIXml) then
            Error(NotValidXmlErr);
        InitializeCIINamespaces(XmlNamespaces);
    end;

    /// <summary>
    /// Extracts the embedded CII XML from a PDF/A-3 container. If the blob is not a PDF, or the PDF does
    /// not embed an attachment, the blob is returned unchanged so that plain CII XML is supported too.
    /// </summary>
    /// <param name="TempBlob">The blob to extract from.</param>
    /// <returns>A blob containing the CII XML.</returns>
    procedure ExtractCIIXml(TempBlob: Codeunit "Temp Blob"): Codeunit "Temp Blob"
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
        NoEmbeddedEInvoiceErr: Label 'The PDF does not contain an embedded e-invoice.', Locked = true;
    begin
        Clear(GlobalEmbeddedBlob);
        if not PDFDocument.GetDocumentAttachmentStream(PdfInStream, GlobalEmbeddedBlob) then
            Error(NoEmbeddedEInvoiceErr);
    end;

    /// <summary>
    /// Initializes the namespace manager with the rsm, ram and udt prefixes used by CII documents.
    /// </summary>
    /// <param name="XmlNamespaces">The namespace manager to initialize.</param>
    procedure InitializeCIINamespaces(var XmlNamespaces: XmlNamespaceManager)
    begin
        XmlNamespaces.AddNamespace('rsm', RsmNamespaceTok);
        XmlNamespaces.AddNamespace('ram', RamNamespaceTok);
        XmlNamespaces.AddNamespace('udt', UdtNamespaceTok);
    end;

    /// <summary>
    /// Determines whether a UNCL1001 document type code identifies an invoice.
    /// </summary>
    /// <param name="TypeCode">The UNCL1001 document type code.</param>
    /// <returns>True if the code identifies an invoice.</returns>
    procedure IsInvoiceTypeCode(TypeCode: Text): Boolean
    begin
        case TypeCode of
            '80', '82', '84', '130', '202', '203', '204', '211', '295', '325', '326', '380', '383', '384', '385', '386', '387', '388', '389', '390', '393', '394', '395', '456', '457', '527', '575', '623', '633', '751', '780', '875', '876', '877', '935':
                exit(true);
        end;

        exit(false);
    end;

    /// <summary>
    /// Determines whether a UNCL1001 document type code identifies a credit memo.
    /// </summary>
    /// <param name="TypeCode">The UNCL1001 document type code.</param>
    /// <returns>True if the code identifies a credit memo.</returns>
    procedure IsCreditMemoTypeCode(TypeCode: Text): Boolean
    begin
        case TypeCode of
            '81', '83', '261', '262', '296', '308', '381', '396', '420', '458', '532':
                exit(true);
        end;

        exit(false);
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

    local procedure PopulateHeader(CIIXml: XmlDocument; XmlNamespaces: XmlNamespaceManager; var Header: Record "E-Document Purchase Header")
    var
        AgreementPathTok: Label '//rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement', Locked = true;
        SettlementPathTok: Label '//rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement', Locked = true;
    begin
        PopulateDocumentInfo(CIIXml, XmlNamespaces, AgreementPathTok, Header);
        PopulateSupplierInfo(CIIXml, XmlNamespaces, AgreementPathTok, Header);
        PopulateCustomerInfo(CIIXml, XmlNamespaces, AgreementPathTok, Header);
        PopulateAmountsAndDates(CIIXml, XmlNamespaces, SettlementPathTok, Header);
        Header."[BC] Vendor No." := FindVendor(Header);
    end;

    local procedure PopulateDocumentInfo(CIIXml: XmlDocument; XmlNamespaces: XmlNamespaceManager; AgreementPath: Text; var Header: Record "E-Document Purchase Header")
    var
        Value: Text;
    begin
        Value := GetNodeValue(CIIXml, XmlNamespaces, '//rsm:ExchangedDocument/ram:ID');
        Header."Sales Invoice No." := CopyStr(Value, 1, MaxStrLen(Header."Sales Invoice No."));

        Value := GetNodeValue(CIIXml, XmlNamespaces, AgreementPath + '/ram:BuyerOrderReferencedDocument/ram:IssuerAssignedID');
        Header."Purchase Order No." := CopyStr(Value, 1, MaxStrLen(Header."Purchase Order No."));

        Value := GetNodeValue(CIIXml, XmlNamespaces, AgreementPath + '/ram:BuyerReference');
        Header."Buyer Reference" := CopyStr(Value, 1, MaxStrLen(Header."Buyer Reference"));

        Value := GetNodeValue(CIIXml, XmlNamespaces, '//rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:InvoiceReferencedDocument/ram:IssuerAssignedID');
        Header."Applies-to Ext. Invoice No." := CopyStr(Value, 1, MaxStrLen(Header."Applies-to Ext. Invoice No."));
    end;

    local procedure PopulateSupplierInfo(CIIXml: XmlDocument; XmlNamespaces: XmlNamespaceManager; AgreementPath: Text; var Header: Record "E-Document Purchase Header")
    var
        BasePath: Text;
    begin
        BasePath := AgreementPath + '/ram:SellerTradeParty';
        Header."Vendor Company Name" := CopyStr(GetNodeValue(CIIXml, XmlNamespaces, BasePath + '/ram:Name'), 1, MaxStrLen(Header."Vendor Company Name"));
        Header."Vendor Address" := CopyStr(GetNodeValue(CIIXml, XmlNamespaces, BasePath + '/ram:PostalTradeAddress/ram:LineOne'), 1, MaxStrLen(Header."Vendor Address"));
        Header."Vendor Address Recipient" := CopyStr(GetNodeValue(CIIXml, XmlNamespaces, BasePath + '/ram:PostalTradeAddress/ram:LineTwo'), 1, MaxStrLen(Header."Vendor Address Recipient"));
        Header."Vendor Contact Name" := CopyStr(GetNodeValue(CIIXml, XmlNamespaces, BasePath + '/ram:DefinedTradeContact/ram:PersonName'), 1, MaxStrLen(Header."Vendor Contact Name"));
        Header."Vendor VAT Id" := CopyStr(GetVATRegistrationNo(CIIXml, XmlNamespaces, BasePath), 1, MaxStrLen(Header."Vendor VAT Id"));
        Header."Vendor GLN" := CopyStr(GetNodeValue(CIIXml, XmlNamespaces, BasePath + '/ram:GlobalID'), 1, MaxStrLen(Header."Vendor GLN"));
        Header."Vendor External Id" := CopyStr(GetNodeValue(CIIXml, XmlNamespaces, BasePath + '/ram:ID'), 1, MaxStrLen(Header."Vendor External Id"));
    end;

    local procedure PopulateCustomerInfo(CIIXml: XmlDocument; XmlNamespaces: XmlNamespaceManager; AgreementPath: Text; var Header: Record "E-Document Purchase Header")
    var
        BasePath: Text;
    begin
        BasePath := AgreementPath + '/ram:BuyerTradeParty';
        Header."Customer Company Name" := CopyStr(GetNodeValue(CIIXml, XmlNamespaces, BasePath + '/ram:Name'), 1, MaxStrLen(Header."Customer Company Name"));
        Header."Customer Company Id" := CopyStr(GetNodeValue(CIIXml, XmlNamespaces, BasePath + '/ram:ID'), 1, MaxStrLen(Header."Customer Company Id"));
        Header."Customer Address" := CopyStr(GetNodeValue(CIIXml, XmlNamespaces, BasePath + '/ram:PostalTradeAddress/ram:LineOne'), 1, MaxStrLen(Header."Customer Address"));
        Header."Customer Address Recipient" := CopyStr(GetNodeValue(CIIXml, XmlNamespaces, BasePath + '/ram:PostalTradeAddress/ram:LineTwo'), 1, MaxStrLen(Header."Customer Address Recipient"));
        Header."Customer VAT Id" := CopyStr(GetVATRegistrationNo(CIIXml, XmlNamespaces, BasePath), 1, MaxStrLen(Header."Customer VAT Id"));
        Header."Customer GLN" := CopyStr(GetNodeValue(CIIXml, XmlNamespaces, BasePath + '/ram:GlobalID'), 1, MaxStrLen(Header."Customer GLN"));
    end;

    local procedure PopulateAmountsAndDates(CIIXml: XmlDocument; XmlNamespaces: XmlNamespaceManager; SettlementPath: Text; var Header: Record "E-Document Purchase Header")
    var
        SummationPath: Text;
    begin
        SummationPath := SettlementPath + '/ram:SpecifiedTradeSettlementHeaderMonetarySummation';
        Header."Document Date" := ReadDate(GetNodeValue(CIIXml, XmlNamespaces, '//rsm:ExchangedDocument/ram:IssueDateTime/udt:DateTimeString'));
        Header."Invoice Date" := Header."Document Date";
        Header."Due Date" := ReadDate(GetNodeValue(CIIXml, XmlNamespaces, SettlementPath + '/ram:SpecifiedTradePaymentTerms/ram:DueDateDateTime/udt:DateTimeString'));
        Header."Sub Total" := ReadDecimal(GetNodeValue(CIIXml, XmlNamespaces, SummationPath + '/ram:TaxBasisTotalAmount'));
        Header."Total Discount" := ReadDecimal(GetNodeValue(CIIXml, XmlNamespaces, SummationPath + '/ram:AllowanceTotalAmount'));
        Header.Total := ReadDecimal(GetNodeValue(CIIXml, XmlNamespaces, SummationPath + '/ram:GrandTotalAmount'));
        Header."Amount Due" := ReadDecimal(GetNodeValue(CIIXml, XmlNamespaces, SummationPath + '/ram:DuePayableAmount'));
        Header."Total VAT" := ReadDecimal(GetNodeValue(CIIXml, XmlNamespaces, SummationPath + '/ram:TaxTotalAmount'));
        if Header."Total VAT" = 0 then
            Header."Total VAT" := Header.Total - Header."Sub Total";
        SetCurrencyIfForeign(GetNodeValue(CIIXml, XmlNamespaces, SettlementPath + '/ram:InvoiceCurrencyCode'), Header."Currency Code");
    end;

    local procedure GetVATRegistrationNo(CIIXml: XmlDocument; XmlNamespaces: XmlNamespaceManager; PartyPath: Text) Value: Text
    begin
        // Scheme VA identifies the VAT registration number, other schemes identify e.g. the tax number (FC)
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
        LinePathTok: Label 'ram:IncludedSupplyChainTradeLineItem', Locked = true;
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
        Line."Unit of Measure" := CopyStr(GetAttributeValue(LineXml, XmlNamespaces, LinePathTok + '/ram:SpecifiedLineTradeDelivery/ram:BilledQuantity', 'unitCode'), 1, MaxStrLen(Line."Unit of Measure"));
        Line."Unit Price" := ReadDecimal(GetNodeValue(LineXml, XmlNamespaces, LinePathTok + '/ram:SpecifiedLineTradeAgreement/ram:NetPriceProductTradePrice/ram:ChargeAmount'));
        Line."Sub Total" := ReadDecimal(GetNodeValue(LineXml, XmlNamespaces, LinePathTok + '/ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeSettlementLineMonetarySummation/ram:LineTotalAmount'));
        Line."VAT Rate" := ReadDecimal(GetNodeValue(LineXml, XmlNamespaces, LinePathTok + '/ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax/ram:RateApplicablePercent'));
        SetCurrencyIfForeign(GetAttributeValue(LineXml, XmlNamespaces, LinePathTok + '/ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeSettlementLineMonetarySummation/ram:LineTotalAmount', 'currencyID'), Line."Currency Code");
    end;

    #endregion Lines

    #region Xml helpers

    local procedure GetNodeValue(XmlDoc: XmlDocument; XmlNamespaces: XmlNamespaceManager; Path: Text): Text
    var
        PeppolUtility: Codeunit "E-Document PEPPOL Utility";
    begin
        exit(PeppolUtility.GetNodeValue(XmlDoc, XmlNamespaces, Path));
    end;

    local procedure GetAttributeValue(XmlDoc: XmlDocument; XmlNamespaces: XmlNamespaceManager; Path: Text; AttributeName: Text): Text
    begin
        exit(GetNodeValue(XmlDoc, XmlNamespaces, Path + '/@' + AttributeName));
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
        // CII dates use format 102: YYYYMMDD
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

    local procedure SetCurrencyIfForeign(CurrencyFromXml: Text; var CurrencyCode: Code[10])
    var
        PeppolUtility: Codeunit "E-Document PEPPOL Utility";
    begin
        PeppolUtility.SetCurrencyIfForeign(CurrencyFromXml, CurrencyCode);
    end;

    #endregion Xml helpers
}
