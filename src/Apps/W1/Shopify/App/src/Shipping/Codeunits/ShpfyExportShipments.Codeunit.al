// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using Microsoft.Foundation.Shipping;
using Microsoft.Sales.History;

/// <summary>
/// Codeunit Shpfy Export Shipments (ID 30190).
/// </summary>
codeunit 30190 "Shpfy Export Shipments"
{
    Access = Internal;
    Permissions =
        tabledata "Sales Shipment Header" = rm,
        tabledata "Sales Shipment Line" = r,
        tabledata "Shipping Agent" = r;

    var
        ShopifyCommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        ShippingEvents: Codeunit "Shpfy Shipping Events";
        NoCorrespondingFulfillmentLinesLbl: Label 'No corresponding fulfillment lines found.';
        NoFulfillmentCreatedInShopifyLbl: Label 'Fulfillment was not created in Shopify.';

    /// <summary> 
    /// Create Shopify Fulfillment.
    /// </summary>
    /// <param name="SalesShipmentHeader">Parameter of type Record "Sales Shipment Header".</param>
    /// <param name="AssignedFulfillmentOrderIds">Parameter of type Dictionary of [BigInteger, Code[20]].</param>
    internal procedure CreateShopifyFulfillment(var SalesShipmentHeader: Record "Sales Shipment Header"; var AssignedFulfillmentOrderIds: Dictionary of [BigInteger, Code[20]]);
    var
        Shop: Record "Shpfy Shop";
        ShopifyOrderHeader: Record "Shpfy Order Header";
        OrderFulfillments: Codeunit "Shpfy Order Fulfillments";
        JsonHelper: Codeunit "Shpfy Json Helper";
        SkippedRecord: Codeunit "Shpfy Skipped Record";
        JFulfillment: JsonToken;
        JResponse: JsonToken;
        FulfillmentOrderRequest: Text;
        FulfillmentId: BigInteger;
        FulfillmentOrderRequests: List of [Text];
    begin
        if (SalesShipmentHeader."Shpfy Order Id" = 0) or (SalesShipmentHeader."Shpfy Fulfillment Id" <> 0) then
            exit;

        if not ShopifyOrderHeader.Get(SalesShipmentHeader."Shpfy Order Id") then
            exit;

        ShopifyCommunicationMgt.SetShop(ShopifyOrderHeader."Shop Code");
        Shop.Get(ShopifyOrderHeader."Shop Code");
        FulfillmentOrderRequests := CreateFulfillmentOrderRequest(SalesShipmentHeader, Shop, AssignedFulfillmentOrderIds);
        if FulfillmentOrderRequests.Count <> 0 then
            foreach FulfillmentOrderRequest in FulfillmentOrderRequests do begin
                JResponse := ShopifyCommunicationMgt.ExecuteGraphQL(FulfillmentOrderRequest);
                JFulfillment := JsonHelper.GetJsonToken(JResponse, 'data.fulfillmentCreate.fulfillment');
                if (JFulfillment.IsObject) then begin
                    FulfillmentId := OrderFulfillments.ImportFulfillment(SalesShipmentHeader."Shpfy Order Id", JFulfillment);
                    if SalesShipmentHeader."Shpfy Fulfillment Id" <> -1 then // partial fulfillment errors
                        SalesShipmentHeader."Shpfy Fulfillment Id" := FulfillmentId;
                end else begin
                    SkippedRecord.LogSkippedRecord(SalesShipmentHeader."Shpfy Order Id", SalesShipmentHeader.RecordId, NoFulfillmentCreatedInShopifyLbl, Shop);
                    SalesShipmentHeader."Shpfy Fulfillment Id" := -1;
                end;
            end
        else begin
            SkippedRecord.LogSkippedRecord(SalesShipmentHeader."Shpfy Order Id", SalesShipmentHeader.RecordId, NoCorrespondingFulfillmentLinesLbl, Shop);
            SalesShipmentHeader."Shpfy Fulfillment Id" := -1;
        end;
        SalesShipmentHeader.Modify(true);
    end;

    internal procedure CreateFulfillmentOrderRequest(SalesShipmentHeader: Record "Sales Shipment Header"; Shop: Record "Shpfy Shop"; var AssignedFulfillmentOrderIds: Dictionary of [BigInteger, Code[20]]) Requests: List of [Text];
    var
        SalesShipmentLine: Record "Sales Shipment Line";
        ShippingAgent: Record "Shipping Agent";
        FulfillmentOrderLine: Record "Shpfy FulFillment Order Line";
        TempFulfillmentOrderLine: Record "Shpfy FulFillment Order Line" temporary;
        TrackingCompany: Enum "Shpfy Tracking Companies";
        PrevFulfillmentOrderId: BigInteger;
        IsHandled: Boolean;
        EmptyFulfillment: Boolean;
        TrackingUrl: Text;
        GraphQueryStart: Text;
        GraphQuery: TextBuilder;
        LineCount: Integer;
        GraphQueries: List of [Text];
        UnfulfillableOrders: List of [BigInteger];
    begin
        Clear(PrevFulfillmentOrderId);

        SalesShipmentLine.Reset();
        SalesShipmentLine.SetRange("Document No.", SalesShipmentHeader."No.");
        SalesShipmentLine.SetRange(Type, SalesShipmentLine.Type::Item);
        SalesShipmentLine.SetFilter("Shpfy Order Line Id", '<>%1', 0);
        SalesShipmentLine.SetFilter(Quantity, '>%1', 0);
        if SalesShipmentLine.FindSet() then begin
            repeat
                FindFulfillmentOrderLines(SalesShipmentHeader, SalesShipmentLine, Shop, FulfillmentOrderLine, TempFulfillmentOrderLine, AssignedFulfillmentOrderIds);
            until SalesShipmentLine.Next() = 0;

            TempFulfillmentOrderLine.Reset();
            TempFulfillmentOrderLine.SetCurrentKey("Shopify Fulfillment Order Id");
            if TempFulfillmentOrderLine.FindSet() then begin
                GraphQuery.Append('{"query": "mutation {fulfillmentCreate( fulfillment: {');
                if GetNotifyCustomer(Shop, SalesShipmentHeader, TempFulfillmentOrderLine."Shopify Location Id") then
                    GraphQuery.Append('notifyCustomer: true, ')
                else
                    GraphQuery.Append('notifyCustomer: false, ');
                if SalesShipmentHeader."Package Tracking No." <> '' then begin
                    GraphQuery.Append('trackingInfo: {');
                    if SalesShipmentHeader."Shipping Agent Code" <> '' then begin
                        GraphQuery.Append('company: \"');
                        if ShippingAgent.Get(SalesShipmentHeader."Shipping Agent Code") then
                            if ShippingAgent."Shpfy Tracking Company" = ShippingAgent."Shpfy Tracking Company"::" " then begin
                                if ShippingAgent.Name = '' then
                                    GraphQuery.Append(ShippingAgent.Code)
                                else
                                    GraphQuery.Append(ShippingAgent.Name)
                            end else
                                GraphQuery.Append(TrackingCompany.Names.Get(TrackingCompany.Ordinals.IndexOf(ShippingAgent."Shpfy Tracking Company".AsInteger())));
                        GraphQuery.Append('\",');
                    end;

                    GraphQuery.Append('number: \"');
                    GraphQuery.Append(SalesShipmentHeader."Package Tracking No.");
                    GraphQuery.Append('\",');
                    ShippingEvents.OnBeforeRetrieveTrackingUrl(SalesShipmentHeader, TrackingUrl, IsHandled);
                    if not IsHandled then
                        if ShippingAgent."Internet Address" <> '' then
                            TrackingUrl := ShippingAgent.GetTrackingInternetAddr(SalesShipmentHeader."Package Tracking No.");

                    if TrackingUrl <> '' then begin
                        GraphQuery.Append('url: \"');
                        GraphQuery.Append(TrackingUrl);
                        GraphQuery.Append('\"');
                    end;

                    GraphQuery.Append('}');
                end;
                GraphQuery.Append('lineItemsByFulfillmentOrder: [');
                GraphQueryStart := GraphQuery.ToText();
                EmptyFulfillment := true;
                repeat
                    // Skip fulfillment orders that are assigned and not accepted
                    if AssignedFulfillmentOrderIds.ContainsKey(TempFulfillmentOrderLine."Shopify Fulfillment Order Id") then
                        continue;

                    if not CanFulfillOrder(TempFulfillmentOrderLine, Shop, UnfulfillableOrders) then
                        continue;

                    EmptyFulfillment := false;

                    if PrevFulfillmentOrderId <> TempFulfillmentOrderLine."Shopify Fulfillment Order Id" then begin
                        if PrevFulfillmentOrderId <> 0 then
                            GraphQuery.Append(']},');

                        GraphQuery.Append('{');
                        GraphQuery.Append('fulfillmentOrderId: \"gid://shopify/FulfillmentOrder/');
                        GraphQuery.Append(Format(TempFulfillmentOrderLine."Shopify Fulfillment Order Id"));
                        GraphQuery.Append('\",');
                        GraphQuery.Append('fulfillmentOrderLineItems: [');
                        PrevFulfillmentOrderId := TempFulfillmentOrderLine."Shopify Fulfillment Order Id";
                    end else
                        GraphQuery.Append(',');
                    GraphQuery.Append('{');
                    GraphQuery.Append('id: \"gid://shopify/FulfillmentOrderLineItem/');
                    GraphQuery.Append(Format(TempFulfillmentOrderLine."Shopify Fulfillm. Ord. Line Id"));
                    GraphQuery.Append('\",');
                    GraphQuery.Append('quantity: ');
                    GraphQuery.Append(Format(TempFulfillmentOrderLine."Quantity to Fulfill", 0, 9));
                    GraphQuery.Append('}');
                    LineCount += 1;
                    if LineCount = 250 then begin
                        LineCount := 0;
                        GraphQuery.Append(']}]})');
                        GraphQuery.Append('{fulfillment { legacyResourceId name createdAt updatedAt deliveredAt displayStatus estimatedDeliveryAt status totalQuantity location { legacyResourceId } trackingInfo { number url company } service { serviceName type } fulfillmentLineItems(first: 10) { pageInfo { endCursor hasNextPage } nodes { id quantity originalTotalSet { presentmentMoney { amount } shopMoney { amount }} lineItem { id isGiftCard }}}}, userErrors {field,message}}}"}');
                        GraphQueries.Add(GraphQuery.ToText());
                        GraphQuery.Clear();
                        GraphQuery.Append(GraphQueryStart);
                        Clear(PrevFulfillmentOrderId);
                    end;
                until TempFulfillmentOrderLine.Next() = 0;
                GraphQuery.Append(']}]})');
                GraphQuery.Append('{fulfillment { legacyResourceId name createdAt updatedAt deliveredAt displayStatus estimatedDeliveryAt status totalQuantity location { legacyResourceId } trackingInfo { number url company } service { serviceName type } fulfillmentLineItems(first: 10) { pageInfo { endCursor hasNextPage } nodes { id quantity originalTotalSet { presentmentMoney { amount } shopMoney { amount }} lineItem { id isGiftCard }}}}, userErrors {field,message}}}"}');
                if not EmptyFulfillment then
                    GraphQueries.Add(GraphQuery.ToText());
            end;
            exit(GraphQueries);
        end;
    end;

    local procedure FindFulfillmentOrderLines(SalesShipmentHeader: Record "Sales Shipment Header"; SalesShipmentLine: Record "Sales Shipment Line"; Shop: Record "Shpfy Shop"; var FulfillmentOrderLine: Record "Shpfy FulFillment Order Line"; var TempFulfillmentOrderLine: Record "Shpfy FulFillment Order Line" temporary; var AssignedFulfillmentOrderIds: Dictionary of [BigInteger, Code[20]])
    var
        RemainingQtyToFulfill: Decimal;
        QtyToFulfillOnLine: Decimal;
    begin
        FulfillmentOrderLine.Reset();
        FulfillmentOrderLine.SetRange("Shopify Order Id", SalesShipmentHeader."Shpfy Order Id");
        FulfillmentOrderLine.SetRange("Line Item Id", SalesShipmentLine."Shpfy Order Line Id");
        FulfillmentOrderLine.SetFilter("Fulfillment Status", '<>%1', 'CLOSED');
        FulfillmentOrderLine.SetFilter("Remaining Quantity", '>%1', 0);
        if not FulfillmentOrderLine.FindSet() then
            exit;

        RemainingQtyToFulfill := Round(SalesShipmentLine.Quantity, 1, '=');
        repeat
            if RemainingQtyToFulfill <= 0 then
                break;

            if FulfillmentOrderLine."Remaining Quantity" >= RemainingQtyToFulfill then
                QtyToFulfillOnLine := RemainingQtyToFulfill
            else
                QtyToFulfillOnLine := FulfillmentOrderLine."Remaining Quantity";

            FulfillmentOrderLine."Quantity to Fulfill" += QtyToFulfillOnLine;
            FulfillmentOrderLine."Remaining Quantity" -= QtyToFulfillOnLine;
            FulfillmentOrderLine.Modify();

            if TempFulfillmentOrderLine.Get(FulfillmentOrderLine."Shopify Fulfillment Order Id", FulfillmentOrderLine."Shopify Fulfillm. Ord. Line Id") then begin
                TempFulfillmentOrderLine."Quantity to Fulfill" += QtyToFulfillOnLine;
                TempFulfillmentOrderLine.Modify();
            end else begin
                TempFulfillmentOrderLine := FulfillmentOrderLine;
                TempFulfillmentOrderLine."Quantity to Fulfill" := QtyToFulfillOnLine;
                TempFulfillmentOrderLine.Insert();
            end;

            AcceptPendingFulfillmentRequests(Shop, FulfillmentOrderLine."Shopify Fulfillment Order Id", AssignedFulfillmentOrderIds);

            RemainingQtyToFulfill -= QtyToFulfillOnLine;
        until FulfillmentOrderLine.Next() = 0;
    end;

    local procedure CanFulfillOrder(FulfillmentOrderLine: Record "Shpfy FulFillment Order Line"; Shop: Record "Shpfy Shop"; var UnfulfillableOrders: List of [BigInteger]): Boolean
    var
        ShopLocation: Record "Shpfy Shop Location";
        SyncLocations: Codeunit "Shpfy Sync Shop Locations";
    begin
        if UnfulfillableOrders.Contains(FulfillmentOrderLine."Shopify Fulfillment Order Id") then
            exit(false);

        if not ShopLocation.Get(Shop.Code, FulfillmentOrderLine."Shopify Location Id") then
            exit(true);

        if not ShopLocation."Is Fulfillment Service" then
            exit(true);

        if ShopLocation.Name = SyncLocations.GetFulfillmentServiceName() then
            exit(true);

        UnfulfillableOrders.Add(FulfillmentOrderLine."Shopify Fulfillment Order Id");
        exit(false);
    end;

    local procedure GetNotifyCustomer(Shop: Record "Shpfy Shop"; SalesShipmmentHeader: Record "Sales Shipment Header"; LocationId: BigInteger): Boolean
    var
        IsHandled: Boolean;
        NotifyCustomer: Boolean;
    begin
        ShippingEvents.OnGetNotifyCustomer(SalesShipmmentHeader, LocationId, NotifyCustomer, IsHandled);
        if IsHandled then
            exit(NotifyCustomer)
        else
            exit(Shop."Send Shipping Confirmation");
    end;

    local procedure AcceptPendingFulfillmentRequests(Shop: Record "Shpfy Shop"; FulfillmentOrderId: BigInteger; var AssignedFulfillmentOrderIds: Dictionary of [BigInteger, Code[20]])
    var
        FulfillmentOrderHeader: Record "Shpfy FulFillment Order Header";
        FulfillmentOrdersAPI: Codeunit "Shpfy Fulfillment Orders API";
    begin
        // Check if this fulfillment order needs to be accepted and remove from dictionary
        if AssignedFulfillmentOrderIds.ContainsKey(FulfillmentOrderId) then
            if FulfillmentOrderHeader.Get(FulfillmentOrderId) then
                if (FulfillmentOrderHeader.Status = 'OPEN') and (FulfillmentOrderHeader."Request Status" = FulfillmentOrderHeader."Request Status"::SUBMITTED) then
                    if FulfillmentOrdersAPI.AcceptFulfillmentRequest(Shop, FulfillmentOrderHeader) then
                        AssignedFulfillmentOrderIds.Remove(FulfillmentOrderId);
    end;
}