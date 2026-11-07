// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol.Response;

using System.Utilities;

/// <summary>
/// Builds a PEPPOL BIS 28 Ordering (transaction T76) Order Response for an inbound Sales Order.
/// Populate the response with SetHeader, SetNote, SetSellerParty, SetBuyerParty and SetPromisedDeliveryDate, add response
/// lines with AddLine followed by the SetLine* procedures that apply to the line just added, then call Build to serialize it.
/// Build completes the response and resets the builder, so the same instance can build the next response from scratch.
/// Only primitives are accepted, so the builder has no dependency on E-Document tables.
/// </summary>
codeunit 37209 "PEPPOL Order Resp. Builder"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        DocumentCurrencyCode: Code[10];
        OrderResponseCode: Code[10];
        HeaderPromisedDeliveryDate: Date;
        ResponseIssueDate: Date;
        OrderLines: JsonArray;
        CacNamespaceTxt: Label 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2', Locked = true;
        CbcNamespaceTxt: Label 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2', Locked = true;
        CustomizationIdTxt: Label 'urn:fdc:peppol.eu:poacc:trns:order_response:3', Locked = true;
        DateFormatTxt: Label '<Year4>-<Month,2>-<Day,2>', Locked = true;
        NoLineAddedErr: Label 'Add a response line with AddLine before setting line values.', Locked = true;
        ProfileIdTxt: Label 'urn:fdc:peppol.eu:poacc:bis:ordering:3', Locked = true;
        RootNamespaceTxt: Label 'urn:oasis:names:specification:ubl:schema:xsd:OrderResponse-2', Locked = true;
        BuyerEndpointId: Text;
        BuyerEndpointSchemeId: Text;
        BuyerPartyName: Text;
        ResponseNote: Text;
        OrderReferenceId: Text;
        ResponseId: Text;
        SalesOrderId: Text;
        SellerEndpointId: Text;
        SellerEndpointSchemeId: Text;
        SellerPartyName: Text;

    /// <summary>
    /// Sets the document level data of the Order Response.
    /// </summary>
    /// <param name="NewResponseId">The business identifier of the response (cbc:ID), for example the seller's sales order number.</param>
    /// <param name="NewSalesOrderId">The seller's sales order number (cbc:SalesOrderID). Omitted when empty.</param>
    /// <param name="NewOrderReferenceId">The buyer's order number the response refers to (cac:OrderReference/cbc:ID).</param>
    /// <param name="NewResponseCode">The UNCL4343 OrderResponseCode (AB = Acknowledged, AP = Accepted, CA = Conditionally accepted, RE = Rejected).</param>
    /// <param name="NewDocumentCurrencyCode">The ISO 4217 currency of the response (cbc:DocumentCurrencyCode), also used for line prices.</param>
    /// <param name="NewIssueDate">The issue date of the response. Today is used when empty.</param>
    procedure SetHeader(NewResponseId: Text; NewSalesOrderId: Text; NewOrderReferenceId: Text; NewResponseCode: Code[10]; NewDocumentCurrencyCode: Code[10]; NewIssueDate: Date)
    begin
        ResponseId := NewResponseId;
        SalesOrderId := NewSalesOrderId;
        OrderReferenceId := NewOrderReferenceId;
        OrderResponseCode := NewResponseCode;
        DocumentCurrencyCode := NewDocumentCurrencyCode;
        ResponseIssueDate := NewIssueDate;
    end;

    /// <summary>
    /// Sets the seller party (cac:SellerSupplierParty) of the Order Response.
    /// </summary>
    /// <param name="EndpointId">The electronic address of the seller (cbc:EndpointID).</param>
    /// <param name="EndpointSchemeId">The EAS code of the electronic address (cbc:EndpointID/@schemeID), for example 0088 for GLN.</param>
    /// <param name="Name">The legal registration name of the seller.</param>
    procedure SetSellerParty(EndpointId: Text; EndpointSchemeId: Text; Name: Text)
    begin
        SellerEndpointId := EndpointId;
        SellerEndpointSchemeId := EndpointSchemeId;
        SellerPartyName := Name;
    end;

    /// <summary>
    /// Sets the buyer party (cac:BuyerCustomerParty) of the Order Response.
    /// </summary>
    /// <param name="EndpointId">The electronic address of the buyer (cbc:EndpointID).</param>
    /// <param name="EndpointSchemeId">The EAS code of the electronic address (cbc:EndpointID/@schemeID), for example 0088 for GLN.</param>
    /// <param name="Name">The legal registration name of the buyer.</param>
    procedure SetBuyerParty(EndpointId: Text; EndpointSchemeId: Text; Name: Text)
    begin
        BuyerEndpointId := EndpointId;
        BuyerEndpointSchemeId := EndpointSchemeId;
        BuyerPartyName := Name;
    end;

    /// <summary>
    /// Sets the delivery date promised by the seller for the whole order (cac:Delivery/cac:PromisedDeliveryPeriod).
    /// </summary>
    procedure SetPromisedDeliveryDate(PromisedDeliveryDate: Date)
    begin
        HeaderPromisedDeliveryDate := PromisedDeliveryDate;
    end;

    /// <summary>
    /// Sets the clarification of the seller's decision (cbc:Note), for example changes that cannot be expressed as response lines.
    /// Omitted when empty.
    /// </summary>
    procedure SetNote(Note: Text)
    begin
        ResponseNote := Note;
    end;

    /// <summary>
    /// Adds a response line (cac:OrderLine). The SetLine* procedures apply to the line added last.
    /// </summary>
    /// <param name="OrderLineId">The identifier of the order line the response line refers to.</param>
    /// <param name="LineStatusCode">The UNCL1229 line status code (3 = Changed, 5 = Accepted without amendment, 7 = Not accepted, 42 = Already delivered).</param>
    /// <param name="ItemName">The name of the ordered item (cac:Item/cbc:Name). The line identifier is used when empty, as the name is mandatory.</param>
    procedure AddLine(OrderLineId: Text; LineStatusCode: Code[10]; ItemName: Text)
    begin
        AddLine(OrderLineId, OrderLineId, LineStatusCode, ItemName);
    end;

    /// <summary>
    /// Adds a response line (cac:OrderLine) whose identifier differs from the order line it refers to, for example a line
    /// the seller added (status 1) for part of an order line. The SetLine* procedures apply to the line added last.
    /// </summary>
    /// <param name="ResponseLineId">The identifier of the response line (cac:LineItem/cbc:ID), unique within the response (PEPPOL-T76-R003).</param>
    /// <param name="OrderLineId">The identifier of the order line the response line refers to (cac:OrderLineReference/cbc:LineID).</param>
    /// <param name="LineStatusCode">The UNCL1229 line status code (1 = Added, 3 = Changed, 5 = Accepted without amendment, 7 = Not accepted).</param>
    /// <param name="ItemName">The name of the item (cac:Item/cbc:Name). The response line identifier is used when empty, as the name is mandatory.</param>
    procedure AddLine(ResponseLineId: Text; OrderLineId: Text; LineStatusCode: Code[10]; ItemName: Text)
    var
        OrderLine: JsonObject;
    begin
        OrderLine.Add('id', ResponseLineId);
        OrderLine.Add('orderLineId', OrderLineId);
        OrderLine.Add('status', LineStatusCode);
        if ItemName = '' then
            ItemName := ResponseLineId;
        OrderLine.Add('itemName', ItemName);
        OrderLines.Add(OrderLine);
    end;

    /// <summary>
    /// Sets the quantity the seller will deliver (cbc:Quantity) on the line added last.
    /// </summary>
    /// <param name="Quantity">The quantity that will be delivered.</param>
    /// <param name="UnitCode">The UN/ECE Rec 20 unit code of the quantity. The quantity is omitted when empty, as the unit code is mandatory.</param>
    procedure SetLineQuantity(Quantity: Decimal; UnitCode: Text)
    begin
        SetCurrentLineValue('quantity', Quantity);
        SetCurrentLineValue('unitCode', UnitCode);
    end;

    /// <summary>
    /// Sets the quantity the seller will deliver at a later time (cbc:MaximumBackorderQuantity) on the line added last.
    /// Use 0 when the remaining ordered quantity will not be delivered. Written only together with the line quantity.
    /// </summary>
    procedure SetLineMaximumBackorderQuantity(MaximumBackorderQuantity: Decimal)
    begin
        SetCurrentLineValue('maximumBackorderQuantity', MaximumBackorderQuantity);
    end;

    /// <summary>
    /// Sets the delivery date promised by the seller (cac:Delivery/cac:PromisedDeliveryPeriod) on the line added last.
    /// </summary>
    procedure SetLinePromisedDeliveryDate(PromisedDeliveryDate: Date)
    begin
        SetCurrentLineValue('promisedDeliveryDate', PromisedDeliveryDate);
    end;

    /// <summary>
    /// Sets the net unit price confirmed by the seller (cac:Price/cbc:PriceAmount) on the line added last, in the document currency.
    /// </summary>
    procedure SetLinePrice(PriceAmount: Decimal)
    begin
        SetCurrentLineValue('priceAmount', PriceAmount);
    end;

    /// <summary>
    /// Sets the buyer's and seller's item identifiers (cac:Item) on the line added last. Empty identifiers are omitted.
    /// </summary>
    procedure SetLineItemIdentification(BuyersItemId: Text; SellersItemId: Text)
    begin
        SetCurrentLineValue('buyersItemId', BuyersItemId);
        SetCurrentLineValue('sellersItemId', SellersItemId);
    end;

    /// <summary>
    /// Serializes the Order Response populated through the setter procedures into TempBlob, then resets the builder
    /// so that no lines or header data carry over into the next response built with the same instance.
    /// </summary>
    procedure Build(var TempBlob: Codeunit "Temp Blob")
    var
        OutStr: OutStream;
        XmlDoc: XmlDocument;
    begin
        XmlDoc := XmlDocument.Create();
        XmlDoc.SetDeclaration(XmlDeclaration.Create('1.0', 'UTF-8', 'no'));
        XmlDoc.Add(BuildOrderResponse());

        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
        XmlDoc.WriteTo(OutStr);

        ClearAll();
    end;

    /// <summary>
    /// Generates an Order Response without currency, endpoint or line information using primitive parameters.
    /// Writes the result into TempBlob. Use the setter procedures and Build(TempBlob) to produce a complete response.
    /// </summary>
    /// <param name="ResponseCode">The UNCL4343 OrderResponseCode used on the wire (e.g. AB = Acknowledged, AP = Accepted, RE = Rejected).</param>
    procedure Build(EDocEntryNo: Integer; BuyerOrderNo: Code[20]; SellerName: Text[100]; BuyerName: Text[100]; ResponseCode: Code[10]; var TempBlob: Codeunit "Temp Blob")
    var
        OrderRefId: Text;
    begin
        OrderRefId := BuyerOrderNo;
        if OrderRefId = '' then
            OrderRefId := Format(EDocEntryNo);
        SetHeader(OrderRefId, '', OrderRefId, ResponseCode, '', 0D);
        SetSellerParty('', '', SellerName);
        SetBuyerParty('', '', BuyerName);
        Build(TempBlob);
    end;

    local procedure SetCurrentLineValue(Name: Text; Value: JsonValue)
    var
        NoLineAddedErrorInfo: ErrorInfo;
        OrderLine: JsonObject;
        OrderLineToken: JsonToken;
    begin
        if not OrderLines.Get(OrderLines.Count() - 1, OrderLineToken) then begin
            NoLineAddedErrorInfo.ErrorType := ErrorType::Internal;
            NoLineAddedErrorInfo.Message := NoLineAddedErr;
            Error(NoLineAddedErrorInfo);
        end;
        OrderLine := OrderLineToken.AsObject();
        if OrderLine.Contains(Name) then
            OrderLine.Replace(Name, Value)
        else
            OrderLine.Add(Name, Value);
    end;

    local procedure SetCurrentLineValue(Name: Text; Value: Decimal)
    var
        JValue: JsonValue;
    begin
        JValue.SetValue(Value);
        SetCurrentLineValue(Name, JValue);
    end;

    local procedure SetCurrentLineValue(Name: Text; Value: Text)
    var
        JValue: JsonValue;
    begin
        JValue.SetValue(Value);
        SetCurrentLineValue(Name, JValue);
    end;

    local procedure SetCurrentLineValue(Name: Text; Value: Date)
    var
        JValue: JsonValue;
    begin
        JValue.SetValue(Value);
        SetCurrentLineValue(Name, JValue);
    end;

    local procedure BuildOrderResponse() RootNode: XmlElement
    var
        IssueDate: Date;
        OrderLineToken: JsonToken;
    begin
        RootNode := XmlElement.Create('OrderResponse', RootNamespaceTxt);
        RootNode.Add(XmlAttribute.CreateNamespaceDeclaration('cac', CacNamespaceTxt));
        RootNode.Add(XmlAttribute.CreateNamespaceDeclaration('cbc', CbcNamespaceTxt));

        RootNode.Add(CbcElement('CustomizationID', CustomizationIdTxt));
        RootNode.Add(CbcElement('ProfileID', ProfileIdTxt));
        RootNode.Add(CbcElement('ID', ResponseId));
        if SalesOrderId <> '' then
            RootNode.Add(CbcElement('SalesOrderID', SalesOrderId));

        IssueDate := ResponseIssueDate;
        if IssueDate = 0D then
            IssueDate := Today();
        RootNode.Add(CbcElement('IssueDate', FormatDate(IssueDate)));
        RootNode.Add(CbcElement('OrderResponseCode', OrderResponseCode));
        if ResponseNote <> '' then
            RootNode.Add(CbcElement('Note', ResponseNote));
        // PEPPOL-COMMON-R001: no empty elements, so a missing currency is left out rather than written empty
        if DocumentCurrencyCode <> '' then
            RootNode.Add(CbcElement('DocumentCurrencyCode', DocumentCurrencyCode));

        // PEPPOL-T76-B01202: cac:OrderReference may only carry cbc:ID
        RootNode.Add(BuildOrderReference());
        RootNode.Add(BuildParty('SellerSupplierParty', SellerEndpointId, SellerEndpointSchemeId, SellerPartyName));
        RootNode.Add(BuildParty('BuyerCustomerParty', BuyerEndpointId, BuyerEndpointSchemeId, BuyerPartyName));

        if HeaderPromisedDeliveryDate <> 0D then
            RootNode.Add(BuildDelivery(HeaderPromisedDeliveryDate));

        foreach OrderLineToken in OrderLines do
            RootNode.Add(BuildOrderLine(OrderLineToken.AsObject()));
    end;

    local procedure BuildOrderReference() Node: XmlElement
    begin
        Node := CacElement('OrderReference');
        Node.Add(CbcElement('ID', OrderReferenceId));
    end;

    local procedure BuildParty(PartyRoleName: Text; EndpointId: Text; EndpointSchemeId: Text; PartyName: Text) RoleNode: XmlElement
    var
        EndpointNode: XmlElement;
        PartyLegalEntityNode: XmlElement;
        PartyNode: XmlElement;
    begin
        RoleNode := CacElement(PartyRoleName);
        PartyNode := CacElement('Party');

        if EndpointId <> '' then begin
            EndpointNode := CbcElement('EndpointID', EndpointId);
            if EndpointSchemeId <> '' then
                EndpointNode.SetAttribute('schemeID', EndpointSchemeId);
            PartyNode.Add(EndpointNode);
        end;

        if PartyName <> '' then begin
            PartyLegalEntityNode := CacElement('PartyLegalEntity');
            PartyLegalEntityNode.Add(CbcElement('RegistrationName', PartyName));
            PartyNode.Add(PartyLegalEntityNode);
        end;

        RoleNode.Add(PartyNode);
    end;

    local procedure BuildDelivery(DeliveryDate: Date) DeliveryNode: XmlElement
    var
        PeriodNode: XmlElement;
    begin
        DeliveryNode := CacElement('Delivery');
        PeriodNode := CacElement('PromisedDeliveryPeriod');
        PeriodNode.Add(CbcElement('StartDate', FormatDate(DeliveryDate)));
        PeriodNode.Add(CbcElement('EndDate', FormatDate(DeliveryDate)));
        DeliveryNode.Add(PeriodNode);
    end;

    local procedure BuildOrderLine(OrderLine: JsonObject) OrderLineNode: XmlElement
    var
        OrderLineId: Text;
        UnitCode: Text;
        LineItemNode: XmlElement;
        OrderLineReferenceNode: XmlElement;
        PriceAmountNode: XmlElement;
        PriceNode: XmlElement;
    begin
        OrderLineId := OrderLine.GetText('orderLineId');
        if OrderLine.Contains('unitCode') then
            UnitCode := OrderLine.GetText('unitCode');

        OrderLineNode := CacElement('OrderLine');
        LineItemNode := CacElement('LineItem');
        LineItemNode.Add(CbcElement('ID', OrderLine.GetText('id')));
        LineItemNode.Add(CbcElement('LineStatusCode', OrderLine.GetText('status')));

        // unitCode is mandatory on both quantities (PEPPOL-T76-B04301)
        if UnitCode <> '' then begin
            LineItemNode.Add(QuantityElement('Quantity', OrderLine.GetDecimal('quantity'), UnitCode));
            if OrderLine.Contains('maximumBackorderQuantity') then
                LineItemNode.Add(QuantityElement('MaximumBackorderQuantity', OrderLine.GetDecimal('maximumBackorderQuantity'), UnitCode));
        end;

        if OrderLine.Contains('promisedDeliveryDate') then
            LineItemNode.Add(BuildDelivery(OrderLine.GetDate('promisedDeliveryDate')));

        if OrderLine.Contains('priceAmount') then begin
            PriceNode := CacElement('Price');
            PriceAmountNode := CbcElement('PriceAmount', Format(OrderLine.GetDecimal('priceAmount'), 0, 9));
            if DocumentCurrencyCode <> '' then
                PriceAmountNode.SetAttribute('currencyID', DocumentCurrencyCode);
            PriceNode.Add(PriceAmountNode);
            LineItemNode.Add(PriceNode);
        end;

        LineItemNode.Add(BuildItem(OrderLine));
        OrderLineNode.Add(LineItemNode);

        OrderLineReferenceNode := CacElement('OrderLineReference');
        OrderLineReferenceNode.Add(CbcElement('LineID', OrderLineId));
        OrderLineNode.Add(OrderLineReferenceNode);
    end;

    local procedure BuildItem(OrderLine: JsonObject) ItemNode: XmlElement
    begin
        // cac:Item and cbc:Name are mandatory on every response line (PEPPOL-T76-B03903, PEPPOL-T76-B05701)
        ItemNode := CacElement('Item');
        ItemNode.Add(CbcElement('Name', OrderLine.GetText('itemName')));
        AddItemIdentification(ItemNode, 'BuyersItemIdentification', OrderLine, 'buyersItemId');
        AddItemIdentification(ItemNode, 'SellersItemIdentification', OrderLine, 'sellersItemId');
    end;

    local procedure AddItemIdentification(ItemNode: XmlElement; ElementName: Text; OrderLine: JsonObject; KeyName: Text)
    var
        ItemId: Text;
        IdentificationNode: XmlElement;
    begin
        if not OrderLine.Contains(KeyName) then
            exit;
        ItemId := OrderLine.GetText(KeyName);
        if ItemId = '' then
            exit;
        IdentificationNode := CacElement(ElementName);
        IdentificationNode.Add(CbcElement('ID', ItemId));
        ItemNode.Add(IdentificationNode);
    end;

    local procedure QuantityElement(Name: Text; Quantity: Decimal; UnitCode: Text) QuantityNode: XmlElement
    begin
        QuantityNode := CbcElement(Name, Format(Quantity, 0, 9));
        QuantityNode.SetAttribute('unitCode', UnitCode);
    end;

    local procedure CacElement(Name: Text): XmlElement
    begin
        exit(XmlElement.Create(Name, CacNamespaceTxt));
    end;

    local procedure CbcElement(Name: Text; Value: Text): XmlElement
    begin
        exit(XmlElement.Create(Name, CbcNamespaceTxt, Value));
    end;

    local procedure FormatDate(Value: Date): Text
    begin
        exit(Format(Value, 0, DateFormatTxt));
    end;
}
