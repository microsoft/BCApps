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

/// <summary>
/// Reads PEPPOL BIS 3.0 Invoice and CreditNote XML into v2 import draft staging tables.
/// This codeunit orchestrates *what* to parse and in what order.
/// Reusable extraction logic lives in "E-Document PEPPOL Utility".
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
        BillingReferenceEmptyTelemetryTxt: Label 'CreditNote BillingReference is empty - no originating invoice reference found.', Locked = true;

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
                    PopulateInvoiceHeader(PeppolXML, XmlNamespaces, EDocumentPurchaseHeader);
                    InsertPurchaseLines(PeppolXML, XmlNamespaces, EDocumentPurchaseHeader."E-Document Entry No.", '/inv:Invoice/cac:InvoiceLine', 'cac:InvoiceLine', 'cbc:InvoicedQuantity');
                    InsertAllowanceChargeLines(PeppolXML, XmlNamespaces, EDocumentPurchaseHeader."E-Document Entry No.", '/inv:Invoice');
                    InsertDocumentAttachments(EDocument, PeppolXML, XmlNamespaces, '/inv:Invoice');
                end;
            'CREDITNOTE':
                begin
                    PopulateCreditMemoHeader(PeppolXML, XmlNamespaces, EDocumentPurchaseHeader);
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

    #region Header Orchestration

    local procedure PopulateInvoiceHeader(PeppolXML: XmlDocument; XmlNamespaces: XmlNamespaceManager; var Header: Record "E-Document Purchase Header")
    begin
        PopulateInvoiceDocumentInfo(PeppolXML, XmlNamespaces, Header);
        PeppolUtility.PopulateSupplierInfo(PeppolXML, XmlNamespaces, '/inv:Invoice', Header);
        PeppolUtility.PopulateCustomerInfo(PeppolXML, XmlNamespaces, '/inv:Invoice', Header);
        // Per PEPPOL BIS 3.0: Invoice has DueDate as a direct child element
        PeppolUtility.PopulateAmountsAndDates(PeppolXML, XmlNamespaces, '/inv:Invoice', '/inv:Invoice/cbc:DueDate', Header);
        PeppolUtility.PopulateCurrency(PeppolXML, XmlNamespaces, '/inv:Invoice', Header);
    end;

    local procedure PopulateCreditMemoHeader(PeppolXML: XmlDocument; XmlNamespaces: XmlNamespaceManager; var Header: Record "E-Document Purchase Header")
    begin
        PopulateCreditNoteDocumentInfo(PeppolXML, XmlNamespaces, Header);
        PeppolUtility.PopulateSupplierInfo(PeppolXML, XmlNamespaces, '/cre:CreditNote', Header);
        PeppolUtility.PopulateCustomerInfo(PeppolXML, XmlNamespaces, '/cre:CreditNote', Header);
        // Per PEPPOL BIS 3.0: CreditNote has no top-level DueDate; it is under PaymentMeans.
        // Spec ref: https://docs.peppol.eu/poacc/billing/3.0/syntax/ubl-creditnote/cac-PaymentMeans/cbc-PaymentDueDate/
        PeppolUtility.PopulateAmountsAndDates(PeppolXML, XmlNamespaces, '/cre:CreditNote', '/cre:CreditNote/cac:PaymentMeans/cbc:PaymentDueDate', Header);
        PeppolUtility.PopulateCurrency(PeppolXML, XmlNamespaces, '/cre:CreditNote', Header);
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
            Header."Vendor Invoice No." := CopyStr(Value, 1, MaxStrLen(Header."Vendor Invoice No."));
        if Header."Vendor Invoice No." = '' then
            Session.LogMessage('0000SNJ', BillingReferenceEmptyTelemetryTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', 'E-Document');
    end;

    #endregion Header Orchestration

    #region Line Orchestration

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
            PeppolUtility.PopulatePurchaseLine(NewLineXML, XmlNamespaces, EDocumentPurchaseLine, LineElementName, QuantityElementName);
            EDocumentPurchaseLine.Insert();
        end;
    end;

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
            PeppolUtility.SetCurrencyIfForeign(CurrencyCode, EDocumentPurchaseLine."Currency Code");

        EDocumentPurchaseLine.Insert();
    end;

    #endregion Line Orchestration

    #region Attachment Orchestration

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
            PeppolUtility.ExtractAttachment(EDocument, AttachmentXML, XmlNamespaces);
        end;
    end;

    #endregion Attachment Orchestration

    procedure View(EDocument: Record "E-Document"; TempBlob: Codeunit "Temp Blob")
    begin
        Error('A view is not implemented for this handler.');
    end;

}
