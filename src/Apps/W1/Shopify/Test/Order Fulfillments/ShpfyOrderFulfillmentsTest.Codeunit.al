// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Integration.Shopify;
using System.TestLibraries.Utilities;

/// <summary>
/// Codeunit Shpfy Order Fulfillments Test (ID 139578).
/// </summary>
codeunit 139578 "Shpfy Order Fulfillments Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Any: Codeunit Any;
        LibraryAssert: Codeunit "Library Assert";

    [Test]
    procedure UnitTestImportFulfillment()
    var
        Orderfulfillment: Record "Shpfy Order Fulfillment";
        OrderFulfillments: Codeunit "Shpfy Order Fulfillments";
        Id: BigInteger;
        OrderId: BigInteger;
        JFulfillment: JsonToken;
        TrackingNo: Text[20];
    begin
        // [SCENARIO] Extract the data out json token that contains a fulfillment info into the "Shpfy Order Fulfillment" record.
        // [GIVEN] A random Generated Fufilment that has not been delivered yet (deliveredAt is null)
        Id := Any.IntegerInRange(10000, 99999);
        OrderId := Any.IntegerInRange(10000, 99999);
        TrackingNo := CopyStr(Any.AlphabeticText(MaxStrLen(TrackingNo)), 1, MaxStrLen(TrackingNo));
        JFulfillment := GetRandomFullFilmentAsJsonToken(Id, TrackingNo, 0DT);

        // [WHEN] Invoke the function ImportFulfillment(JFulfillment)
        OrderFulfillments.ImportFulfillment(OrderId, JFulfillment);

        // [THEN] We must find the "Shpfy Order Fufillment" record with the same id
        LibraryAssert.IsTrue(Orderfulfillment.Get(Id), 'Get "Shpfy Order Fufillment" record');

        // [THEN] TrackingNo = ShpfyOrderfulfillment."Tracking Number"
        LibraryAssert.AreEqual(TrackingNo, Orderfulfillment."Tracking Number", 'Tracking number check');

        // [THEN] "Delivered At" stays blank when Shopify has not set deliveredAt yet
        LibraryAssert.AreEqual(0DT, Orderfulfillment."Delivered At", 'Delivered At should be blank when not delivered');
    end;

    [Test]
    procedure UnitTestImportFulfillmentSetsDeliveredAt()
    var
        Orderfulfillment: Record "Shpfy Order Fulfillment";
        OrderFulfillments: Codeunit "Shpfy Order Fulfillments";
        Id: BigInteger;
        OrderId: BigInteger;
        DeliveredAt: DateTime;
        JFulfillment: JsonToken;
        TrackingNo: Text[20];
    begin
        // [SCENARIO] deliveredAt from Shopify is parsed into the "Delivered At" field on import.
        // [GIVEN] A random generated fulfillment that has already been delivered
        Id := Any.IntegerInRange(10000, 99999);
        OrderId := Any.IntegerInRange(10000, 99999);
        TrackingNo := CopyStr(Any.AlphabeticText(MaxStrLen(TrackingNo)), 1, MaxStrLen(TrackingNo));
        DeliveredAt := CreateDateTime(Today - 1, Time);
        JFulfillment := GetRandomFullFilmentAsJsonToken(Id, TrackingNo, DeliveredAt);

        // [WHEN] Invoke the function ImportFulfillment(JFulfillment)
        OrderFulfillments.ImportFulfillment(OrderId, JFulfillment);

        // [THEN] "Delivered At" matches the deliveredAt value from Shopify
        LibraryAssert.IsTrue(Orderfulfillment.Get(Id), 'Get "Shpfy Order Fufillment" record');
        LibraryAssert.AreEqual(DeliveredAt, Orderfulfillment."Delivered At", 'Delivered At check');
    end;

    [Test]
    procedure UnitTestImportFulfillmentUpdatesDeliveredAtOnReimport()
    var
        Orderfulfillment: Record "Shpfy Order Fulfillment";
        OrderFulfillments: Codeunit "Shpfy Order Fulfillments";
        Id: BigInteger;
        OrderId: BigInteger;
        DeliveredAt: DateTime;
        JFulfillment: JsonToken;
        TrackingNo: Text[20];
    begin
        // [SCENARIO] Re-importing an existing fulfillment (e.g. after a full order re-sync) picks up
        // a deliveredAt value that Shopify only populated after the fulfillment was first created.
        // [GIVEN] A fulfillment that was already imported without a deliveredAt value
        Id := Any.IntegerInRange(10000, 99999);
        OrderId := Any.IntegerInRange(10000, 99999);
        TrackingNo := CopyStr(Any.AlphabeticText(MaxStrLen(TrackingNo)), 1, MaxStrLen(TrackingNo));
        JFulfillment := GetRandomFullFilmentAsJsonToken(Id, TrackingNo, 0DT);
        OrderFulfillments.ImportFulfillment(OrderId, JFulfillment);
        Orderfulfillment.Get(Id);
        LibraryAssert.AreEqual(0DT, Orderfulfillment."Delivered At", 'Delivered At should be blank before delivery');

        // [WHEN] The same fulfillment is re-imported after Shopify has since set deliveredAt
        DeliveredAt := CreateDateTime(Today, Time);
        JFulfillment := GetRandomFullFilmentAsJsonToken(Id, TrackingNo, DeliveredAt);
        OrderFulfillments.ImportFulfillment(OrderId, JFulfillment);

        // [THEN] "Delivered At" is updated on the existing record
        Orderfulfillment.Get(Id);
        LibraryAssert.AreEqual(DeliveredAt, Orderfulfillment."Delivered At", 'Delivered At should be updated on re-import');
    end;

    local procedure GetRandomFullFilmentAsJsonToken(id: BigInteger; TrackingNo: Text; DeliveredAt: DateTime): JsonToken
    var
        JFulfillment: JsonObject;
        JLocation: JsonObject;
        JService: JsonObject;
        JTrackingInfo: JsonObject;
        JTrackingInfos: JsonArray;
        JArray: JsonArray;
        JNull: JsonValue;
        TrackingUrlTxt: Label 'https://www.trackingcompany.com?no=%1', Comment = '%1 = TrackingNo', Locked = true;
    begin
        JNull.SetValueToNull();
        JLocation.Add('legacyResourceId', Any.IntegerInRange(1000000, 9999999));
        JService.Add('serviceName', 'Manual');
        JService.Add('type', 'MANUAL');
        JService.Add('shippingMethods', JArray);
        JTrackingInfo.Add('number', TrackingNo);
        JTrackingInfo.Add('url', StrSubstNo(TrackingUrlTxt, TrackingNo));
        JTrackingInfo.Add('company', 'TrackingCompany');
        JTrackingInfos.Add(JTrackingInfo);

        JFulfillment.Add('legacyResourceId', id);
        JFulfillment.Add('name', Any.AlphabeticText(5));
        JFulfillment.Add('createdAt', Format(CurrentDateTime - 1, 0, 9));
        JFulfillment.Add('updatedAt', CurrentDateTime);
        if DeliveredAt = 0DT then
            JFulfillment.Add('deliveredAt', JNull)
        else
            JFulfillment.Add('deliveredAt', Format(DeliveredAt, 0, 9));
        JFulfillment.Add('displayStatus', 'FULFILLED');
        JFulfillment.Add('estimatedDeliveryAt', JNull);
        JFulfillment.Add('status', 'SUCCESS');
        JFulfillment.Add('totalQuantity', 1);
        JFulfillment.Add('trackingInfo', JTrackingInfos);
        JFulfillment.Add('service', JService);
        JFulfillment.Add('fulfillmentLineItems', GetFulfillmentLineItems());
        exit(JFulfillment.AsToken());
    end;

    local procedure GetFulfillmentLineItems() JFulfilmentLineItems: JsonObject

    begin
        JFulfilmentLineItems.Add('pageInfo', GetPageInfo());
        JFulfilmentLineItems.Add('nodes', GetFulfillmentLineItemsNodes());
    end;

    local procedure GetPageInfo() JPageInfo: JsonObject
    begin
        JPageInfo.Add('endCursor', Any.AlphanumericText(36));
        JPageInfo.Add('hasNextPage', false);
    end;

    local procedure GetFulfillmentLineItemsNodes() JNodes: JsonArray;
    begin
        JNodes.Add(GetFulfillmentLineItemsNode());
    end;

    local procedure GetFulfillmentLineItemsNode() JNode: JsonObject;
    var
        JLineItem: JsonObject;
        GidFulfillmentLneItemLbl: Label 'gid://shopify/FulfillmentLineItem/%1', Locked = true, Comment = '%1 = Filfillment Line Item Id';
        GidLineItemLbl: Label 'gid://shopify/LineItem/%1', Locked = true, Comment = '%1 = Line Item Id';
    begin
        JLineItem.Add('id', StrSubstNo(GidLineItemLbl, Any.IntegerInRange(100000, 999999)));
        JNode.Add('id', StrSubstNo(GidFulfillmentLneItemLbl, Any.IntegerInRange(100000, 999999)));
        JNode.Add('quantity', 1);
        JNode.Add('originalTotalSet', AddPriceSet(Any.DecimalInRange(50, 1000, 2)));
        JNode.Add('lineItem', JLineItem);
    end;

    local procedure AddPriceSet(Price: Decimal) JSet: JsonObject
    var
        JShopMoney: JsonObject;
        JPresentManey: JsonObject;
    begin
        JShopMoney.Add('amount', Format(Price, 0, 9));
        JSet.Add('shopMoney', JShopMoney);
        JPresentManey.Add('amount', Format(Price, 0, 9));
        JSet.Add('presentmentMoney', JPresentManey);
    end;
}