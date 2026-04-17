// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Integration.Shopify;
using Microsoft.Sales.History;
using System.TestLibraries.Utilities;

codeunit 139606 "Shpfy Shipping Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;
    TestHttpRequestPolicy = BlockOutboundRequests;

    var
        Shop: Record "Shpfy Shop";
        Any: Codeunit Any;
        LibraryAssert: Codeunit "Library Assert";
        InitializeTest: Codeunit "Shpfy Initialize Test";
        IsInitialized: Boolean;

    [Test]
    procedure UnitTestExportShipment()
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        OrderLine: Record "Shpfy Order Line";
        FulfillmentOrderHeader: Record "Shpfy FulFillment Order Header";
        ExportShipments: Codeunit "Shpfy Export Shipments";
        ShippingHelper: Codeunit "Shpfy Shipping Helper";
        DeliveryMethodType: Enum "Shpfy Delivery Method Type";
        FulfillmentRequest: Text;
        FulfillmentRequests: List of [Text];
        AssignedFulfillmentOrderIds: Dictionary of [BigInteger, Code[20]];
        ShopifyOrderId: BigInteger;
        LocationId: BigInteger;
        QuantityLbl: Label 'quantity: %1', Comment = '%1 - quantity', Locked = true;
    begin
        // [SCENARIO] Export a Sales Shipment record into a Json token that contains the shipping info
        // [GIVEN] A random Sales Shipment, a random LocationId, a random Shop
        Initialize();
        LocationId := Any.IntegerInRange(10000, 99999);
        DeliveryMethodType := DeliveryMethodType::Shipping;
        ShopifyOrderId := ShippingHelper.CreateRandomShopifyOrder(LocationId, DeliveryMethodType);
        FulfillmentOrderHeader := ShippingHelper.CreateShopifyFulfillmentOrder(ShopifyOrderId, DeliveryMethodType);
        ShippingHelper.CreateRandomSalesShipment(SalesShipmentHeader, ShopifyOrderId);

        // [WHEN] Invoke the function CreateFulfillmentRequest()
        FulfillmentRequests := ExportShipments.CreateFulfillmentOrderRequest(SalesShipmentHeader, Shop, AssignedFulfillmentOrderIds);

        // [THEN] We must find the correct fulfilment data in the json token
        LibraryAssert.AreEqual(1, FulfillmentRequests.Count, 'FulfillmentRequest count check');
        FulfillmentRequests.Get(1, FulfillmentRequest);
        LibraryAssert.IsTrue(FulfillmentRequest.Contains(Format(FulfillmentOrderHeader."Shopify Fulfillment Order Id")), 'Fulfillmentorder Id Check');
        LibraryAssert.IsTrue(FulfillmentRequest.Contains(SalesShipmentHeader."Package Tracking No."), 'tracking number check');

        // [THEN] We must find the fulfilment lines in the json token
        OrderLine.SetRange("Shopify Order Id", ShopifyOrderId);
        OrderLine.FindFirst();
#pragma warning disable AA0210
        SalesShipmentLine.SetRange("Shpfy Order Line Id", OrderLine."Line Id");
#pragma warning restore AA0210
        SalesShipmentLine.FindFirst();
        LibraryAssert.IsTrue(FulfillmentRequest.Contains(StrSubstNo(QuantityLbl, SalesShipmentLine.Quantity)), 'quantity check');
    end;

    [Test]
    procedure UnitTestExportShipment250Lines()
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        FulfillmentOrderHeader: Record "Shpfy FulFillment Order Header";
        ExportShipments: Codeunit "Shpfy Export Shipments";
        ShippingHelper: Codeunit "Shpfy Shipping Helper";
        DeliveryMethodType: Enum "Shpfy Delivery Method Type";
        FulfillmentRequest: Text;
        FulfillmentRequests: List of [Text];
        AssignedFulfillmentOrderIds: Dictionary of [BigInteger, Code[20]];
        ShopifyOrderId: BigInteger;
        LocationId: BigInteger;
    begin
        // [SCENARIO] Export a Sales Shipment with more than 250 lines creates two fulfillment requests
        // [GIVEN] A random Sales Shipment, a random LocationId, a random Shop
        Initialize();
        LocationId := Any.IntegerInRange(10000, 99999);
        DeliveryMethodType := DeliveryMethodType::Shipping;
        ShopifyOrderId := ShippingHelper.CreateRandomShopifyOrder(LocationId, DeliveryMethodType);
        ShippingHelper.CreateOrderLines(ShopifyOrderId, LocationId, DeliveryMethodType, 300);
        FulfillmentOrderHeader := ShippingHelper.CreateShopifyFulfillmentOrder(ShopifyOrderId, DeliveryMethodType);
        ShippingHelper.CreateRandomSalesShipment(SalesShipmentHeader, ShopifyOrderId);

        // [WHEN] Invoke the function CreateFulfillmentRequest()
        FulfillmentRequests := ExportShipments.CreateFulfillmentOrderRequest(SalesShipmentHeader, Shop, AssignedFulfillmentOrderIds);

        // [THEN] We must find the correct fulfilment data in the json token
        LibraryAssert.AreEqual(2, FulfillmentRequests.Count(), 'FulfillmentRequest count check');
        foreach FulfillmentRequest in FulfillmentRequests do begin
            LibraryAssert.IsTrue(FulfillmentRequest.Contains(Format(FulfillmentOrderHeader."Shopify Fulfillment Order Id")), 'Fulfillmentorder Id Check');
            LibraryAssert.IsTrue(FulfillmentRequest.Contains(SalesShipmentHeader."Package Tracking No."), 'tracking number check');
        end;
    end;

    [Test]
    [HandlerFunctions('HttpSubmitHandler')]
    procedure UnitTestExportFulfillmentServiceShipment()
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        OrderLine: Record "Shpfy Order Line";
        FulfillmentOrderHeader: Record "Shpfy FulFillment Order Header";
        ExportShipments: Codeunit "Shpfy Export Shipments";
        ShippingHelper: Codeunit "Shpfy Shipping Helper";
        DeliveryMethodType: Enum "Shpfy Delivery Method Type";
        FulfillmentRequest: Text;
        FulfillmentRequests: List of [Text];
        AssignedFulfillmentOrderIds: Dictionary of [BigInteger, Code[20]];
        ShopifyOrderId: BigInteger;
        LocationId: BigInteger;
        QuantityLbl: Label 'quantity: %1', Comment = '%1 - quantity', Locked = true;
    begin
        // [SCENARIO] Export a Sales Shipment record into a Json token that contains the shipping info
        // [GIVEN] A random Sales Shipment, a random LocationId, a random Shop
        Initialize();
        LocationId := Any.IntegerInRange(10000, 99999);
        DeliveryMethodType := DeliveryMethodType::Shipping;
        ShopifyOrderId := ShippingHelper.CreateRandomShopifyOrder(LocationId, DeliveryMethodType);
        FulfillmentOrderHeader := ShippingHelper.CreateShopifyFulfillmentOrder(ShopifyOrderId, DeliveryMethodType);
        ShippingHelper.CreateRandomSalesShipment(SalesShipmentHeader, ShopifyOrderId);
        AssignedFulfillmentOrderIds.Add(FulfillmentOrderHeader."Shopify Fulfillment Order Id", Shop.Code);
        FulfillmentOrderHeader.Status := 'OPEN';
        FulfillmentOrderHeader."Request Status" := FulfillmentOrderHeader."Request Status"::Submitted;
        FulfillmentOrderHeader.Modify();

        // [WHEN] Invoke the function CreateFulfillmentRequest()
        FulfillmentRequests := ExportShipments.CreateFulfillmentOrderRequest(SalesShipmentHeader, Shop, AssignedFulfillmentOrderIds);

        // [THEN] We must find the correct fulfilment data in the json token
        LibraryAssert.AreEqual(1, FulfillmentRequests.Count, 'FulfillmentRequest count check');
        FulfillmentRequests.Get(1, FulfillmentRequest);
        LibraryAssert.IsTrue(FulfillmentRequest.Contains(Format(FulfillmentOrderHeader."Shopify Fulfillment Order Id")), 'Fulfillmentorder Id Check');
        LibraryAssert.IsTrue(FulfillmentRequest.Contains(SalesShipmentHeader."Package Tracking No."), 'tracking number check');
        LibraryAssert.IsTrue(AssignedFulfillmentOrderIds.Count() = 0, 'Assigned Fulfillment Order Ids count check');

        // [THEN] We must find the fulfilment lines in the json token
        OrderLine.SetRange("Shopify Order Id", ShopifyOrderId);
        OrderLine.FindFirst();
#pragma warning disable AA0210
        SalesShipmentLine.SetRange("Shpfy Order Line Id", OrderLine."Line Id");
#pragma warning restore AA0210
        SalesShipmentLine.FindFirst();
        LibraryAssert.IsTrue(FulfillmentRequest.Contains(StrSubstNo(QuantityLbl, SalesShipmentLine.Quantity)), 'quantity check');
    end;

    [Test]
    procedure UnitTestExportShipmentThirdParty()
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        FulfillmentOrderHeader: Record "Shpfy FulFillment Order Header";
        ExportShipments: Codeunit "Shpfy Export Shipments";
        ShippingHelper: Codeunit "Shpfy Shipping Helper";
        DeliveryMethodType: Enum "Shpfy Delivery Method Type";
        FulfillmentRequests: List of [Text];
        AssignedFulfillmentOrderIds: Dictionary of [BigInteger, Code[20]];
        ShopifyOrderId: BigInteger;
        LocationId: BigInteger;
    begin
        // [SCENARIO] Export a Sales Shipment record into a Json token that contains the shipping info for a third-party fulfillment service
        // [GIVEN] A random Sales Shipment, a random LocationId for a third-party fulfillment location, a random Shop
        Initialize();
        LocationId := Any.IntegerInRange(10000, 99999);
        CreateThirdPartyFulfillmentLocation(Shop, LocationId);
        DeliveryMethodType := DeliveryMethodType::Shipping;
        ShopifyOrderId := ShippingHelper.CreateRandomShopifyOrder(LocationId, DeliveryMethodType);
        FulfillmentOrderHeader := ShippingHelper.CreateShopifyFulfillmentOrder(ShopifyOrderId, DeliveryMethodType);
        ShippingHelper.CreateRandomSalesShipment(SalesShipmentHeader, ShopifyOrderId);

        // [WHEN] Invoke the function CreateFulfillmentOrderRequest()
        FulfillmentRequests := ExportShipments.CreateFulfillmentOrderRequest(SalesShipmentHeader, Shop, AssignedFulfillmentOrderIds);

        // [THEN] We must find no fulfilment data in the json token as the location is for a third-party fulfillment service
        LibraryAssert.AreEqual(0, FulfillmentRequests.Count, 'FulfillmentRequest count check');
    end;

    [Test]
    procedure UnitTestExportShipmentMultipleLocations()
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        OrderHeader: Record "Shpfy Order Header";
        FulfillmentOrderHeaderA: Record "Shpfy FulFillment Order Header";
        FulfillmentOrderHeaderB: Record "Shpfy FulFillment Order Header";
        ExportShipments: Codeunit "Shpfy Export Shipments";
        ShippingHelper: Codeunit "Shpfy Shipping Helper";
        DeliveryMethodType: Enum "Shpfy Delivery Method Type";
        FulfillmentRequest: Text;
        FulfillmentRequests: List of [Text];
        AssignedFulfillmentOrderIds: Dictionary of [BigInteger, Code[20]];
        ShopifyOrderId: BigInteger;
        LocationIdA: BigInteger;
        LocationIdB: BigInteger;
        LineItemId: BigInteger;
        VariantId: BigInteger;
        ProductId: BigInteger;
    begin
        // [SCENARIO] A shipment spanning two Shopify locations must produce separate fulfillment requests per location
        // [GIVEN] One item (qty 17) split across two locations: 10 at Location A, 7 at Location B
        Initialize();
        Any.SetDefaultSeed();
        LocationIdA := Any.IntegerInRange(10000, 49999);
        LocationIdB := Any.IntegerInRange(50000, 99999);
        DeliveryMethodType := DeliveryMethodType::Shipping;
        LineItemId := Any.IntegerInRange(10000, 99999);
        VariantId := Any.IntegerInRange(10000, 99999);
        ProductId := Any.IntegerInRange(10000, 99999);

        Clear(OrderHeader);
        ShopifyOrderId := Any.IntegerInRange(10000, 99999);
        OrderHeader."Shopify Order Id" := ShopifyOrderId;
        OrderHeader.Insert();

        // Same item split across two locations with different quantities
        ShippingHelper.CreateOrderLine(ShopifyOrderId, LocationIdA, DeliveryMethodType, LineItemId, VariantId, ProductId, 10);
        ShippingHelper.CreateOrderLine(ShopifyOrderId, LocationIdB, DeliveryMethodType, LineItemId + 1, VariantId, ProductId, 7);

        // Create fulfillment orders per location
        FulfillmentOrderHeaderA := ShippingHelper.CreateShopifyFulfillmentOrderForLocation(ShopifyOrderId, LocationIdA, DeliveryMethodType);
        FulfillmentOrderHeaderB := ShippingHelper.CreateShopifyFulfillmentOrderForLocation(ShopifyOrderId, LocationIdB, DeliveryMethodType);

        // [GIVEN] A shipment of qty 9 that spans both locations (needs items from both fulfillment orders)
        Clear(SalesShipmentHeader);
        SalesShipmentHeader."No." := CopyStr(Any.AlphanumericText(MaxStrLen(SalesShipmentHeader."No.")), 1, MaxStrLen(SalesShipmentHeader."No."));
        SalesShipmentHeader."Shpfy Order Id" := ShopifyOrderId;
        SalesShipmentHeader."Package Tracking No." := CopyStr(Any.AlphanumericText(MaxStrLen(SalesShipmentHeader."Package Tracking No.")), 1, MaxStrLen(SalesShipmentHeader."Package Tracking No."));
        SalesShipmentHeader.Insert();

        // Shipment line for item at Location A: ship 5 out of 10
        ShippingHelper.CreateSalesShipmentLine(SalesShipmentHeader."No.", LineItemId, 5, 10000);
        // Shipment line for item at Location B: ship 4 out of 7
        ShippingHelper.CreateSalesShipmentLine(SalesShipmentHeader."No.", LineItemId + 1, 4, 20000);

        // [WHEN] Invoke the function CreateFulfillmentOrderRequest()
        FulfillmentRequests := ExportShipments.CreateFulfillmentOrderRequest(SalesShipmentHeader, Shop, AssignedFulfillmentOrderIds);

        // [THEN] Two separate requests are created, one per location
        LibraryAssert.AreEqual(2, FulfillmentRequests.Count, 'Should produce two fulfillment requests, one per location');

        // [THEN] First request contains only Location A's fulfillment order
        FulfillmentRequests.Get(1, FulfillmentRequest);
        LibraryAssert.IsTrue(FulfillmentRequest.Contains(Format(FulfillmentOrderHeaderA."Shopify Fulfillment Order Id")), 'First request should contain Location A fulfillment order');
        LibraryAssert.IsFalse(FulfillmentRequest.Contains(Format(FulfillmentOrderHeaderB."Shopify Fulfillment Order Id")), 'First request should not contain Location B fulfillment order');

        // [THEN] Second request contains only Location B's fulfillment order
        FulfillmentRequests.Get(2, FulfillmentRequest);
        LibraryAssert.IsTrue(FulfillmentRequest.Contains(Format(FulfillmentOrderHeaderB."Shopify Fulfillment Order Id")), 'Second request should contain Location B fulfillment order');
        LibraryAssert.IsFalse(FulfillmentRequest.Contains(Format(FulfillmentOrderHeaderA."Shopify Fulfillment Order Id")), 'Second request should not contain Location A fulfillment order');
    end;

    local procedure Initialize()
    var
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        AccessToken: SecretText;
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Shpfy Shipping Test");
        ClearLastError();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Shpfy Shipping Test");

        LibraryRandom.Init();

        Any.SetDefaultSeed();

        IsInitialized := true;
        Commit();

        // Creating Shopify Shop
        Shop := InitializeTest.CreateShop();

        //Register Shopify Access Token
        AccessToken := LibraryRandom.RandText(20);
        InitializeTest.RegisterAccessTokenForShop(Shop.GetStoreName(), AccessToken);

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Shpfy Shipping Test");
    end;

    local procedure CreateThirdPartyFulfillmentLocation(ShopifyShop: Record "Shpfy Shop"; LocationId: BigInteger)
    var
        ShopLocation: Record "Shpfy Shop Location";
    begin
        ShopLocation."Shop Code" := ShopifyShop.Code;
        ShopLocation.Id := LocationId;
        ShopLocation.Name := 'Third-Party Fulfillment Service';
        ShopLocation."Is Fulfillment Service" := true;
        ShopLocation.Insert();
    end;

    [HttpClientHandler]
    internal procedure HttpSubmitHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        if not InitializeTest.VerifyRequestUrl(Request.Path, Shop."Shopify URL") then
            exit(true);

        Response.Content.WriteFrom(NavApp.GetResourceAsText('Shipping/FulfillmentOrderAcceptResponse.txt', TextEncoding::UTF8));
        exit(false); // Prevents actual HTTP call
    end;
}
