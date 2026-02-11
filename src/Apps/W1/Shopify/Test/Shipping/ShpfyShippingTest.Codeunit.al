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

    local procedure Initialize()
    var
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
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

        CommunicationMgt.SetTestInProgress(false);

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
