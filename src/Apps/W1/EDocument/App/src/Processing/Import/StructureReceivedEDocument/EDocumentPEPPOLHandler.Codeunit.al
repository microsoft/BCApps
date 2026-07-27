// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Format;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using Microsoft.EServices.EDocument.Processing.Import.Sales;
using Microsoft.eServices.EDocument.Processing.Interfaces;
using System.Utilities;

/// <summary>
/// Reads PEPPOL BIS 3.0 Invoice, CreditNote, and Order XML into v2 import draft staging tables.
/// This codeunit orchestrates *what* to parse and in what order.
/// Reusable extraction logic lives in "E-Document PEPPOL Utility".
/// Spec reference: https://docs.peppol.eu/poacc/billing/3.0/syntax/ubl-invoice/tree/
///                 https://docs.peppol.eu/poacc/billing/3.0/syntax/ubl-creditnote/tree/
///                 https://docs.peppol.eu/poacc/upgrade-3/syntax/Order/tree/
/// </summary>
codeunit 6173 "E-Document PEPPOL Handler" implements IStructuredFormatReader
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        PeppolUtility: Codeunit "E-Document PEPPOL Utility";
        BillingReferenceEmptyTelemetryTxt: Label 'CreditNote BillingReference is empty - no originating invoice reference found.', Locked = true;
        UnsupportedRootElementErr: Label 'Unsupported XML root element: %1. Only Invoice, CreditNote, and Order are supported.', Comment = '%1 = XML root element name';

    procedure ReadIntoDraft(EDocument: Record "E-Document"; TempBlob: Codeunit "Temp Blob"): Enum "E-Doc. Process Draft"
    var
        DocStream: InStream;
        PeppolXML: XmlDocument;
        XmlNamespaces: XmlNamespaceManager;
        RootElement: XmlElement;
        OrderNamespaceLbl: Label 'urn:oasis:names:specification:ubl:schema:xsd:Order-2', Locked = true;
    begin
        TempBlob.CreateInStream(DocStream, TextEncoding::UTF8);
        XmlDocument.ReadFrom(DocStream, PeppolXML);
        PeppolUtility.InitializePEPPOL3Namespaces(XmlNamespaces);
        XmlNamespaces.AddNamespace('order', OrderNamespaceLbl);

        PeppolXML.GetRoot(RootElement);

        EDocument.Direction := EDocument.Direction::Incoming;

        case UpperCase(RootElement.LocalName()) of
            'INVOICE':
                exit(ProcessInvoice(EDocument, PeppolXML, XmlNamespaces));
            'CREDITNOTE':
                exit(ProcessCreditNote(EDocument, PeppolXML, XmlNamespaces));
            'ORDER':
                exit(ProcessOrder(EDocument, PeppolXML, XmlNamespaces));
            else
                Error(UnsupportedRootElementErr, RootElement.LocalName());
        end;
    end;

    local procedure ProcessInvoice(EDocument: Record "E-Document"; PeppolXML: XmlDocument; XmlNamespaces: XmlNamespaceManager): Enum "E-Doc. Process Draft"
    var
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
    begin
        EDocumentPurchaseHeader.InsertForEDocument(EDocument);
        PopulateInvoiceHeader(PeppolXML, XmlNamespaces, EDocumentPurchaseHeader);
        InsertPurchaseLines(PeppolXML, XmlNamespaces, EDocumentPurchaseHeader."E-Document Entry No.", '/inv:Invoice/cac:InvoiceLine', 'cac:InvoiceLine', 'cbc:InvoicedQuantity');
        InsertAllowanceChargeLines(PeppolXML, XmlNamespaces, EDocumentPurchaseHeader."E-Document Entry No.", '/inv:Invoice');
        InsertDocumentAttachments(EDocument, PeppolXML, XmlNamespaces, '/inv:Invoice');
        EDocumentPurchaseHeader.Modify();
        exit(Enum::"E-Doc. Process Draft"::"Purchase Invoice");
    end;

    local procedure ProcessCreditNote(EDocument: Record "E-Document"; PeppolXML: XmlDocument; XmlNamespaces: XmlNamespaceManager): Enum "E-Doc. Process Draft"
    var
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
    begin
        EDocumentPurchaseHeader.InsertForEDocument(EDocument);
        PopulateCreditMemoHeader(PeppolXML, XmlNamespaces, EDocumentPurchaseHeader);
        InsertPurchaseLines(PeppolXML, XmlNamespaces, EDocumentPurchaseHeader."E-Document Entry No.", '/cre:CreditNote/cac:CreditNoteLine', 'cac:CreditNoteLine', 'cbc:CreditedQuantity');
        InsertAllowanceChargeLines(PeppolXML, XmlNamespaces, EDocumentPurchaseHeader."E-Document Entry No.", '/cre:CreditNote');
        InsertDocumentAttachments(EDocument, PeppolXML, XmlNamespaces, '/cre:CreditNote');
        EDocumentPurchaseHeader.Modify();
        exit(Enum::"E-Doc. Process Draft"::"Purchase Credit Memo");
    end;

    local procedure ProcessOrder(EDocument: Record "E-Document"; PeppolXML: XmlDocument; XmlNamespaces: XmlNamespaceManager): Enum "E-Doc. Process Draft"
    var
        EDocSalesHeader: Record "E-Document Sales Header";
        XmlNode: XmlNode;
    begin
        EDocSalesHeader.InsertForEDocument(EDocument);
        PopulateSalesOrderHeader(PeppolXML, XmlNamespaces, EDocSalesHeader);
        InsertSalesOrderLines(EDocSalesHeader."E-Document Entry No.", PeppolXML, XmlNamespaces);
        InsertSalesAllowanceChargeLines(PeppolXML, XmlNamespaces, EDocSalesHeader."E-Document Entry No.");
        if not PeppolXML.SelectSingleNode('/order:Order/cac:AnticipatedMonetaryTotal', XmlNamespaces, XmlNode) then
            ComputeSalesTotalsFromLines(EDocSalesHeader);
        InsertDocumentAttachments(EDocument, PeppolXML, XmlNamespaces, '/order:Order');
        EDocSalesHeader.Modify();
        exit(Enum::"E-Doc. Process Draft"::"Sales Order");
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
            Header."Applies-to Ext. Invoice No." := CopyStr(Value, 1, MaxStrLen(Header."Applies-to Ext. Invoice No."));
        if Header."Applies-to Ext. Invoice No." = '' then
            Session.LogMessage('0000SNJ', BillingReferenceEmptyTelemetryTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', 'E-Document');
    end;

    #endregion Header Orchestration

    #region Sales Order Header

    local procedure PopulateSalesOrderHeader(PeppolXML: XmlDocument; XmlNamespaces: XmlNamespaceManager; var Header: Record "E-Document Sales Header")
    var
        Value: Text;
        RootPath: Text;
    begin
        RootPath := '/order:Order';

        if PeppolUtility.TryGetStringValue(PeppolXML, XmlNamespaces, RootPath + '/cbc:ID', Value) then
            Header."Buyer Order No." := CopyStr(Value, 1, MaxStrLen(Header."Buyer Order No."));
        if PeppolUtility.TryGetStringValue(PeppolXML, XmlNamespaces, RootPath + '/cbc:SalesOrderID', Value) then
            Header."Seller Sales Order No." := CopyStr(Value, 1, MaxStrLen(Header."Seller Sales Order No."));
        if PeppolUtility.TryGetStringValue(PeppolXML, XmlNamespaces, RootPath + '/cbc:OrderTypeCode', Value) then
            Header."Order Type Code" := CopyStr(Value, 1, MaxStrLen(Header."Order Type Code"));

        PeppolUtility.SetDateValueInField(PeppolXML, XmlNamespaces, RootPath + '/cbc:IssueDate', Header."Document Date");
        // First cac:Delivery block StartDate; SelectSingleNode returns first match in document order
        PeppolUtility.SetDateValueInField(PeppolXML, XmlNamespaces, RootPath + '/cac:Delivery/cac:RequestedDeliveryPeriod/cbc:StartDate', Header."Requested Delivery Date");

        if PeppolUtility.TryGetStringValue(PeppolXML, XmlNamespaces, RootPath + '/cbc:DocumentCurrencyCode', Value) then
            PeppolUtility.SetCurrencyIfForeign(Value, Header."Currency Code");
        if PeppolUtility.TryGetStringValue(PeppolXML, XmlNamespaces, RootPath + '/cbc:CustomerReference', Value) then
            Header."Customer Reference" := CopyStr(Value, 1, MaxStrLen(Header."Customer Reference"));
        if PeppolUtility.TryGetStringValue(PeppolXML, XmlNamespaces, RootPath + '/cbc:Note', Value) then
            Header.Note := CopyStr(Value, 1, MaxStrLen(Header.Note));

        PopulateBuyerParty(PeppolXML, XmlNamespaces, RootPath, Header);
        PopulateSellerParty(PeppolXML, XmlNamespaces, RootPath, Header);
        PopulateOriginatorParty(PeppolXML, XmlNamespaces, RootPath, Header);
        PopulateAccountingCustomerParty(PeppolXML, XmlNamespaces, RootPath, Header);

        // AnticipatedMonetaryTotal is 0..1 — amounts stay 0 when absent; fallback computed after lines
        PeppolUtility.SetNumberValueInField(PeppolXML, XmlNamespaces, RootPath + '/cac:AnticipatedMonetaryTotal/cbc:LineExtensionAmount', Header."Sub Total");
        PeppolUtility.SetNumberValueInField(PeppolXML, XmlNamespaces, RootPath + '/cac:AnticipatedMonetaryTotal/cbc:AllowanceTotalAmount', Header."Total Discount");
        PeppolUtility.SetNumberValueInField(PeppolXML, XmlNamespaces, RootPath + '/cac:AnticipatedMonetaryTotal/cbc:PayableAmount', Header.Total);
        PeppolUtility.SetNumberValueInField(PeppolXML, XmlNamespaces, RootPath + '/cac:TaxTotal/cbc:TaxAmount', Header."Total VAT");
    end;

    local procedure PopulateBuyerParty(PeppolXML: XmlDocument; XmlNamespaces: XmlNamespaceManager; RootPath: Text; var Header: Record "E-Document Sales Header")
    var
        XmlNode: XmlNode;
        Value: Text;
        PartyPath: Text;
    begin
        PartyPath := RootPath + '/cac:BuyerCustomerParty/cac:Party';

        if PeppolUtility.TryGetStringValue(PeppolXML, XmlNamespaces, PartyPath + '/cac:PartyName/cbc:Name', Value) then
            Header."Buyer Company Name" := CopyStr(Value, 1, MaxStrLen(Header."Buyer Company Name"));
        if Header."Buyer Company Name" = '' then
            if PeppolUtility.TryGetStringValue(PeppolXML, XmlNamespaces, PartyPath + '/cac:PartyLegalEntity/cbc:RegistrationName', Value) then
                Header."Buyer Company Name" := CopyStr(Value, 1, MaxStrLen(Header."Buyer Company Name"));

        if PeppolUtility.TryGetStringValue(PeppolXML, XmlNamespaces, PartyPath + '/cac:PartyLegalEntity/cbc:CompanyID', Value) then
            Header."Buyer Company Id" := CopyStr(Value, 1, MaxStrLen(Header."Buyer Company Id"));
        if PeppolUtility.TryGetStringValue(PeppolXML, XmlNamespaces, PartyPath + '/cac:PartyTaxScheme/cbc:CompanyID', Value) then
            Header."Buyer VAT Id" := CopyStr(Value, 1, MaxStrLen(Header."Buyer VAT Id"));
        if PeppolUtility.TryGetStringValue(PeppolXML, XmlNamespaces, PartyPath + '/cac:PostalAddress/cbc:StreetName', Value) then
            Header."Buyer Address" := CopyStr(Value, 1, MaxStrLen(Header."Buyer Address"));
        if PeppolUtility.TryGetStringValue(PeppolXML, XmlNamespaces, PartyPath + '/cac:Contact/cbc:Name', Value) then
            Header."Buyer Address Recipient" := CopyStr(Value, 1, MaxStrLen(Header."Buyer Address Recipient"));

        if PeppolXML.SelectSingleNode(PartyPath + '/cbc:EndpointID/@schemeID', XmlNamespaces, XmlNode) then
            if XmlNode.AsXmlAttribute().Value() = '0088' then
                if PeppolUtility.TryGetStringValue(PeppolXML, XmlNamespaces, PartyPath + '/cbc:EndpointID', Value) then
                    Header."Buyer GLN" := CopyStr(Value, 1, MaxStrLen(Header."Buyer GLN"));
    end;

    local procedure PopulateSellerParty(PeppolXML: XmlDocument; XmlNamespaces: XmlNamespaceManager; RootPath: Text; var Header: Record "E-Document Sales Header")
    var
        XmlNode: XmlNode;
        Value: Text;
        PartyPath: Text;
    begin
        PartyPath := RootPath + '/cac:SellerSupplierParty/cac:Party';

        if PeppolUtility.TryGetStringValue(PeppolXML, XmlNamespaces, PartyPath + '/cac:PartyName/cbc:Name', Value) then
            Header."Seller Company Name" := CopyStr(Value, 1, MaxStrLen(Header."Seller Company Name"));
        if Header."Seller Company Name" = '' then
            if PeppolUtility.TryGetStringValue(PeppolXML, XmlNamespaces, PartyPath + '/cac:PartyLegalEntity/cbc:RegistrationName', Value) then
                Header."Seller Company Name" := CopyStr(Value, 1, MaxStrLen(Header."Seller Company Name"));

        if PeppolUtility.TryGetStringValue(PeppolXML, XmlNamespaces, PartyPath + '/cac:PartyTaxScheme/cbc:CompanyID', Value) then
            Header."Seller VAT Id" := CopyStr(Value, 1, MaxStrLen(Header."Seller VAT Id"));
        if PeppolUtility.TryGetStringValue(PeppolXML, XmlNamespaces, PartyPath + '/cac:PostalAddress/cbc:StreetName', Value) then
            Header."Seller Address" := CopyStr(Value, 1, MaxStrLen(Header."Seller Address"));
        if PeppolUtility.TryGetStringValue(PeppolXML, XmlNamespaces, PartyPath + '/cac:Contact/cbc:Name', Value) then
            Header."Seller Address Recipient" := CopyStr(Value, 1, MaxStrLen(Header."Seller Address Recipient"));

        if PeppolXML.SelectSingleNode(PartyPath + '/cbc:EndpointID/@schemeID', XmlNamespaces, XmlNode) then
            if XmlNode.AsXmlAttribute().Value() = '0088' then
                if PeppolUtility.TryGetStringValue(PeppolXML, XmlNamespaces, PartyPath + '/cbc:EndpointID', Value) then
                    Header."Seller GLN" := CopyStr(Value, 1, MaxStrLen(Header."Seller GLN"));
    end;

    local procedure PopulateOriginatorParty(PeppolXML: XmlDocument; XmlNamespaces: XmlNamespaceManager; RootPath: Text; var Header: Record "E-Document Sales Header")
    var
        Value: Text;
        PartyPath: Text;
    begin
        PartyPath := RootPath + '/cac:OriginatorCustomerParty/cac:Party';

        if PeppolUtility.TryGetStringValue(PeppolXML, XmlNamespaces, PartyPath + '/cac:PartyName/cbc:Name', Value) then
            Header."Originator Company Name" := CopyStr(Value, 1, MaxStrLen(Header."Originator Company Name"));
        if Header."Originator Company Name" = '' then
            if PeppolUtility.TryGetStringValue(PeppolXML, XmlNamespaces, PartyPath + '/cac:PartyLegalEntity/cbc:RegistrationName', Value) then
                Header."Originator Company Name" := CopyStr(Value, 1, MaxStrLen(Header."Originator Company Name"));
    end;

    local procedure PopulateAccountingCustomerParty(PeppolXML: XmlDocument; XmlNamespaces: XmlNamespaceManager; RootPath: Text; var Header: Record "E-Document Sales Header")
    var
        Value: Text;
        PartyPath: Text;
    begin
        PartyPath := RootPath + '/cac:AccountingCustomerParty/cac:Party';

        if PeppolUtility.TryGetStringValue(PeppolXML, XmlNamespaces, PartyPath + '/cac:PartyName/cbc:Name', Value) then
            Header."Accounting Customer Name" := CopyStr(Value, 1, MaxStrLen(Header."Accounting Customer Name"));
        if Header."Accounting Customer Name" = '' then
            if PeppolUtility.TryGetStringValue(PeppolXML, XmlNamespaces, PartyPath + '/cac:PartyLegalEntity/cbc:RegistrationName', Value) then
                Header."Accounting Customer Name" := CopyStr(Value, 1, MaxStrLen(Header."Accounting Customer Name"));
    end;

    local procedure ComputeSalesTotalsFromLines(var Header: Record "E-Document Sales Header")
    var
        EDocSalesLine: Record "E-Document Sales Line";
    begin
        EDocSalesLine.SetRange("E-Document Entry No.", Header."E-Document Entry No.");
        if EDocSalesLine.FindSet() then
            repeat
                Header."Sub Total" += EDocSalesLine."Line Extension Amount";
            until EDocSalesLine.Next() = 0;
        Header.Total := Header."Sub Total" + Header."Total VAT";
    end;

    #endregion Sales Order Header

    #region Sales Order Lines

    local procedure InsertSalesOrderLines(EDocumentEntryNo: Integer; PeppolXML: XmlDocument; XmlNamespaces: XmlNamespaceManager)
    var
        EDocSalesLine: Record "E-Document Sales Line";
        OrderLineNodes: XmlNodeList;
        OrderLineNode: XmlNode;
        LineItemXML: XmlDocument;
        i: Integer;
    begin
        if not PeppolXML.SelectNodes('/order:Order/cac:OrderLine/cac:LineItem', XmlNamespaces, OrderLineNodes) then
            exit;

        for i := 1 to OrderLineNodes.Count do begin
            Clear(EDocSalesLine);
            EDocSalesLine.Validate("E-Document Entry No.", EDocumentEntryNo);
            EDocSalesLine."Line No." := EDocSalesLine.GetNextLineNo(EDocumentEntryNo);
            OrderLineNodes.Get(i, OrderLineNode);
            LineItemXML.ReplaceNodes(OrderLineNode);
            PopulateSalesLine(LineItemXML, XmlNamespaces, EDocSalesLine);
            EDocSalesLine.Insert();
        end;
    end;

    local procedure PopulateSalesLine(LineItemXML: XmlDocument; XmlNamespaces: XmlNamespaceManager; var Line: Record "E-Document Sales Line")
    var
        AllowanceNodes: XmlNodeList;
        AllowanceNode: XmlNode;
        AllowanceXML: XmlDocument;
        AllowanceIndicator: Text;
        AllowanceAmount: Decimal;
        Value: Text;
        i: Integer;
    begin
        if PeppolUtility.TryGetStringValue(LineItemXML, XmlNamespaces, 'cac:LineItem/cbc:ID', Value) then
            Line."External Line Id" := CopyStr(Value, 1, MaxStrLen(Line."External Line Id"));

        PeppolUtility.SetNumberValueInField(LineItemXML, XmlNamespaces, 'cac:LineItem/cbc:Quantity', Line.Quantity);
        if PeppolUtility.TryGetStringValue(LineItemXML, XmlNamespaces, 'cac:LineItem/cbc:Quantity/@unitCode', Value) then
            Line."Unit of Measure" := CopyStr(Value, 1, MaxStrLen(Line."Unit of Measure"));

        PeppolUtility.SetNumberValueInField(LineItemXML, XmlNamespaces, 'cac:LineItem/cbc:LineExtensionAmount', Line."Line Extension Amount");
        PeppolUtility.SetNumberValueInField(LineItemXML, XmlNamespaces, 'cac:LineItem/cac:Price/cbc:PriceAmount', Line."Unit Price");

        if PeppolUtility.TryGetStringValue(LineItemXML, XmlNamespaces, 'cac:LineItem/cac:Item/cbc:Name', Value) then
            Line.Description := CopyStr(Value, 1, MaxStrLen(Line.Description));
        if Line.Description = '' then
            if PeppolUtility.TryGetStringValue(LineItemXML, XmlNamespaces, 'cac:LineItem/cac:Item/cbc:Description', Value) then
                Line.Description := CopyStr(Value, 1, MaxStrLen(Line.Description));

        if PeppolUtility.TryGetStringValue(LineItemXML, XmlNamespaces, 'cac:LineItem/cac:Item/cac:SellersItemIdentification/cbc:ID', Value) then
            Line."Seller Item Id" := CopyStr(Value, 1, MaxStrLen(Line."Seller Item Id"));
        if PeppolUtility.TryGetStringValue(LineItemXML, XmlNamespaces, 'cac:LineItem/cac:Item/cac:BuyersItemIdentification/cbc:ID', Value) then
            Line."Buyer Item Id" := CopyStr(Value, 1, MaxStrLen(Line."Buyer Item Id"));
        if PeppolUtility.TryGetStringValue(LineItemXML, XmlNamespaces, 'cac:LineItem/cac:Item/cac:StandardItemIdentification/cbc:ID', Value) then
            Line."Standard Item Id" := CopyStr(Value, 1, MaxStrLen(Line."Standard Item Id"));

        if not PeppolUtility.TryGetStringValue(LineItemXML, XmlNamespaces, 'cac:LineItem/cac:Item/cac:ClassifiedTaxCategory/cbc:Percent', Value) or (Value = '') then
            PeppolUtility.SetNumberValueInField(LineItemXML, XmlNamespaces, 'cac:LineItem/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cbc:Percent', Line."VAT Rate")
        else
            Evaluate(Line."VAT Rate", Value, 9);

        if LineItemXML.SelectNodes('cac:LineItem/cac:AllowanceCharge', XmlNamespaces, AllowanceNodes) then
            for i := 1 to AllowanceNodes.Count do begin
                AllowanceAmount := 0;
                AllowanceNodes.Get(i, AllowanceNode);
                AllowanceXML.ReplaceNodes(AllowanceNode);
                if PeppolUtility.TryGetStringValue(AllowanceXML, XmlNamespaces, 'cac:AllowanceCharge/cbc:ChargeIndicator', AllowanceIndicator) then
                    if UpperCase(AllowanceIndicator) = 'FALSE' then begin
                        PeppolUtility.SetNumberValueInField(AllowanceXML, XmlNamespaces, 'cac:AllowanceCharge/cbc:Amount', AllowanceAmount);
                        Line."Line Discount Amount" += AllowanceAmount;
                    end;
                    // Line-level charges (ChargeIndicator = TRUE) are intentionally not captured here.
                    // Document-level charges are promoted to separate staging lines via InsertSalesAllowanceChargeLines.
                    // PEPPOL line-level surcharges are out of scope for this implementation.
            end;

        if PeppolUtility.TryGetStringValue(LineItemXML, XmlNamespaces, 'cac:LineItem/cbc:LineExtensionAmount/@currencyID', Value) then
            PeppolUtility.SetCurrencyIfForeign(Value, Line."Currency Code");

        PeppolUtility.SetDateValueInField(LineItemXML, XmlNamespaces, 'cac:LineItem/cac:Delivery/cac:RequestedDeliveryPeriod/cbc:StartDate', Line."Requested Delivery Date");
    end;

    local procedure InsertSalesAllowanceChargeLines(PeppolXML: XmlDocument; XmlNamespaces: XmlNamespaceManager; EDocumentEntryNo: Integer)
    var
        ChargeXML: XmlDocument;
        ChargeNodes: XmlNodeList;
        ChargeNode: XmlNode;
        ChargeIndicator: Text;
        i: Integer;
    begin
        if not PeppolXML.SelectNodes('/order:Order/cac:AllowanceCharge', XmlNamespaces, ChargeNodes) then
            exit;

        for i := 1 to ChargeNodes.Count do begin
            ChargeNodes.Get(i, ChargeNode);
            ChargeXML.ReplaceNodes(ChargeNode);

            if PeppolUtility.TryGetStringValue(ChargeXML, XmlNamespaces, 'cac:AllowanceCharge/cbc:ChargeIndicator', ChargeIndicator) then
                if UpperCase(ChargeIndicator) = 'TRUE' then
                    InsertSingleSalesChargeLine(ChargeXML, XmlNamespaces, EDocumentEntryNo);
        end;
    end;

    local procedure InsertSingleSalesChargeLine(ChargeXML: XmlDocument; XmlNamespaces: XmlNamespaceManager; EDocumentEntryNo: Integer)
    var
        EDocSalesLine: Record "E-Document Sales Line";
        ChargeAmount: Decimal;
        Value: Text;
        CurrencyCode: Text;
    begin
        Clear(EDocSalesLine);
        EDocSalesLine.Validate("E-Document Entry No.", EDocumentEntryNo);
        EDocSalesLine."Line No." := EDocSalesLine.GetNextLineNo(EDocumentEntryNo);
        EDocSalesLine.Quantity := 1;

        PeppolUtility.SetNumberValueInField(ChargeXML, XmlNamespaces, 'cac:AllowanceCharge/cbc:Amount', ChargeAmount);
        EDocSalesLine."Unit Price" := ChargeAmount;
        EDocSalesLine."Line Extension Amount" := ChargeAmount;

        if PeppolUtility.TryGetStringValue(ChargeXML, XmlNamespaces, 'cac:AllowanceCharge/cbc:AllowanceChargeReason', Value) then
            EDocSalesLine.Description := CopyStr(Value, 1, MaxStrLen(EDocSalesLine.Description));

        PeppolUtility.SetNumberValueInField(ChargeXML, XmlNamespaces, 'cac:AllowanceCharge/cac:TaxCategory/cbc:Percent', EDocSalesLine."VAT Rate");

        if PeppolUtility.TryGetStringValue(ChargeXML, XmlNamespaces, 'cac:AllowanceCharge/cbc:Amount/@currencyID', CurrencyCode) then
            PeppolUtility.SetCurrencyIfForeign(CurrencyCode, EDocSalesLine."Currency Code");

        EDocSalesLine.Insert();
    end;

    #endregion Sales Order Lines

    #region Purchase Line Orchestration

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

    #endregion Purchase Line Orchestration

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
