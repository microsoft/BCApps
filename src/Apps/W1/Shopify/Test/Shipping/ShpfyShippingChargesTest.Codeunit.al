// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.Shipping;
using Microsoft.Integration.Shopify;
using Microsoft.Inventory.Item;
using Microsoft.Sales.Document;
using System.TestLibraries.Utilities;

codeunit 139546 "Shpfy Shipping Charges Test"
{
    Subtype = Test;
    TestType = Uncategorized;
    TestPermissions = Disabled;
    TestHttpRequestPolicy = BlockOutboundRequests;

    var
        ShipmentMethod: Record "Shipment Method";
        ShippingAgent: Record "Shipping Agent";
        ShippingAgentServices: Record "Shipping Agent Services";
        Shop: Record "Shpfy Shop";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryAssert: Codeunit "Library Assert";
        OutboundHttpRequests: Codeunit "Library - Variable Storage";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        InitializeTest: Codeunit "Shpfy Initialize Test";
        IsInitialized: Boolean;
        ShippingLineGIdTok: Label 'gid://shopify/ShippingLine/%1', Locked = true, Comment = '%1 = Shipping line id';

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    #region Test Methods
    [Test]
    [HandlerFunctions('ShippingChargesHttpHandler')]
    procedure UnitTestValidateShopifyOrderShippingAgentServiceMapping()
    var
        OrderHeader: Record "Shpfy Order Header";
        Item: Record Item;
        ShpfyShipmentMethodMapping: Record "Shpfy Shipment Method Mapping";
        OrderShippingCharges: Record "Shpfy Order Shipping Charges";
        OrderMapping: Codeunit "Shpfy Order Mapping";
        ImportOrder: Codeunit "Shpfy Import Order";
        ShippingChargesType: Enum "Sales Line Type";
    begin
        // [SCENARIO] Creating a random Shopify order and try to map shipping agent and service data from the Shopify shipment method mapping.
        Initialize();

        // [GIVEN] Shopify Shop
        Shop := CommunicationMgt.GetShopRecord();

        // [GIVEN] Shopify order is imported
        ImportOrder.SetShop(Shop.Code);
        ImportShopifyOrder(Shop, OrderHeader, ImportOrder, false);

        // [GIVEN] Order shipping charges are created for the Shopify order
        CreateOrderShippingCharges(OrderShippingCharges, OrderHeader."Shopify Order Id");

        // [GIVEN] Created shopify shipment method mapping from the shipping charges
        Item := InitializeTest.GetDummyItem();
        CreateShopifyShipmentMethodMapping(
            ShpfyShipmentMethodMapping,
            ShippingChargesType::Item,
            ShipmentMethod.Code,
            ShippingAgent.Code,
            ShippingAgentServices.Code,
            Item."No.",
            OrderShippingCharges.Title
        );

        // [GIVEN] Register Expected Outbound API Requests.
        OutboundHttpRequests.Clear();
        OutboundHttpRequests.Enqueue('Transactions');

        // [WHEN] Order mapping is done
        OrderMapping.DoMapping(OrderHeader);

        // [THEN] Order header is mapped with the correct shipping agent and service code
        LibraryAssert.AreEqual(ShpfyShipmentMethodMapping."Shipping Agent Code", OrderHeader."Shipping Agent Code", 'Shipping Agent Code must be correct');
        LibraryAssert.AreEqual(ShpfyShipmentMethodMapping."Shipping Agent Service Code", OrderHeader."Shipping Agent Service Code", 'Shipping Agent Service Code must be correct');
    end;

    [Test]
    [HandlerFunctions('ShippingChargesHttpHandler')]
    procedure UnitTestValidateSalesOrderShippingAgentServiceMapping()
    var
        OrderHeader: Record "Shpfy Order Header";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        OrderShippingCharges: Record "Shpfy Order Shipping Charges";
        ShpfyShipmentMethodMapping: Record "Shpfy Shipment Method Mapping";
        ProcessOrder: Codeunit "Shpfy Process Order";
        ImportOrder: Codeunit "Shpfy Import Order";
        ShippingChargesType: Enum "Sales Line Type";
    begin
        // [SCENARIO] Creating Sales document from a Shopify order and try to map shipping agent and service data.
        Initialize();

        // [GIVEN] Shopify shop
        Shop := CommunicationMgt.GetShopRecord();

        // [GIVEN] Shopify order is imported
        ImportOrder.SetShop(Shop.Code);
        ImportShopifyOrder(Shop, OrderHeader, ImportOrder, false);

        // [GIVEN] Order shipping charges are created for the Shopify order
        CreateOrderShippingCharges(OrderShippingCharges, OrderHeader."Shopify Order Id");

        // [GIVEN] Created shopify shipment method mapping from the shipping charges
        Item := InitializeTest.GetDummyItem();
        CreateShopifyShipmentMethodMapping(
            ShpfyShipmentMethodMapping,
            ShippingChargesType::Item,
            ShipmentMethod.Code,
            ShippingAgent.Code,
            ShippingAgentServices.Code,
            Item."No.",
            OrderShippingCharges.Title
        );

        // [GIVEN] Register Expected Outbound API Requests.
        OutboundHttpRequests.Clear();
        OutboundHttpRequests.Enqueue('Transactions');

        // [WHEN] Order is processed
        ProcessOrder.Run(OrderHeader);

        // [THEN] Sales document with correct shipping agent and service code is created.
        AssertSalesHeaderValues(OrderHeader, SalesHeader, ShpfyShipmentMethodMapping);
    end;

    [Test]
    [HandlerFunctions('ShippingChargesHttpHandler')]
    procedure UnitTestMapShippingChargesForEmptyType()
    var
        OrderHeader: Record "Shpfy Order Header";
        ShpfyShipmentMethodMapping: Record "Shpfy Shipment Method Mapping";
        OrderShippingCharges: Record "Shpfy Order Shipping Charges";
        ProcessOrder: Codeunit "Shpfy Process Order";
        ImportOrder: Codeunit "Shpfy Import Order";
        ShippingChargesType: Enum "Sales Line Type";
    begin
        // [SCENARIO] Create sales line from a Shopify order and try to map shipping charges account information when type is empty.
        Initialize();

        // [GIVEN] Shopify Shop
        Shop := CommunicationMgt.GetShopRecord();

        // [GIVEN] Shopify order is imported
        ImportOrder.SetShop(Shop.Code);
        ImportShopifyOrder(Shop, OrderHeader, ImportOrder, false);

        // [GIVEN] Order shipping charges are created for the Shopify order
        CreateOrderShippingCharges(OrderShippingCharges, OrderHeader."Shopify Order Id");

        // [GIVEN] Created shopify shipment method mapping from the shipping charges
        CreateShopifyShipmentMethodMapping(
            ShpfyShipmentMethodMapping,
            ShippingChargesType::" ",
            ShipmentMethod.Code,
            ShippingAgent.Code,
            ShippingAgentServices.Code,
            CopyStr(LibraryRandom.RandText(20), 1, 20),
            OrderShippingCharges.Title
        );

        // [GIVEN] Register Expected Outbound API Requests.
        OutboundHttpRequests.Clear();
        OutboundHttpRequests.Enqueue('Transactions');

        // [WHEN] Order is processed
        ProcessOrder.Run(OrderHeader);

        // [THEN] Sales line is created with the correct shipping charges account information
        AssertSalesLineValues(
            OrderShippingCharges,
            ShpfyShipmentMethodMapping,
            ShippingChargesType::"G/L Account",
            Shop."Shipping Charges Account"
        );
    end;

    [Test]
    [HandlerFunctions('ShippingChargesHttpHandler')]
    procedure UnitTestMapShippingChargesForItemType()
    var
        OrderHeader: Record "Shpfy Order Header";
        Item: Record Item;
        ShpfyShipmentMethodMapping: Record "Shpfy Shipment Method Mapping";
        OrderShippingCharges: Record "Shpfy Order Shipping Charges";
        ProcessOrder: Codeunit "Shpfy Process Order";
        ImportOrder: Codeunit "Shpfy Import Order";
        ShippingChargesType: Enum "Sales Line Type";
    begin
        // [SCENARIO] Create sales line from a Shopify order and try to map shipping charges account information when type is an item.
        Initialize();

        // [GIVEN] Shopify Shop
        Shop := CommunicationMgt.GetShopRecord();

        // [GIVEN] Shopify order is imported
        ImportOrder.SetShop(Shop.Code);
        ImportShopifyOrder(Shop, OrderHeader, ImportOrder, false);

        // [GIVEN] Order shipping charges are created for the Shopify order
        CreateOrderShippingCharges(OrderShippingCharges, OrderHeader."Shopify Order Id");

        // [GIVEN] Created shopify shipment method mapping from the shipping charges
        Item := InitializeTest.GetDummyItem();
        CreateShopifyShipmentMethodMapping(
            ShpfyShipmentMethodMapping,
            ShippingChargesType::Item,
            ShipmentMethod.Code,
            ShippingAgent.Code,
            ShippingAgentServices.Code,
            Item."No.",
            OrderShippingCharges.Title
        );

        // [GIVEN] Register Expected Outbound API Requests.
        OutboundHttpRequests.Clear();
        OutboundHttpRequests.Enqueue('Transactions');

        // [WHEN] Order is processed
        ProcessOrder.Run(OrderHeader);

        // [THEN] Sales line is created with the correct shipping charges account information
        AssertSalesLineValues(
            OrderShippingCharges,
            ShpfyShipmentMethodMapping,
            ShippingChargesType::Item,
            ShpfyShipmentMethodMapping."Shipping Charges No."
        );
    end;

    [Test]
    [HandlerFunctions('ShippingChargesHttpHandler')]
    procedure UnitTestMapShippingChargesForGLType()
    var
        OrderHeader: Record "Shpfy Order Header";
        GLAccount: Record "G/L Account";
        ShpfyShipmentMethodMapping: Record "Shpfy Shipment Method Mapping";
        OrderShippingCharges: Record "Shpfy Order Shipping Charges";
        ImportOrder: Codeunit "Shpfy Import Order";
        ProcessOrder: Codeunit "Shpfy Process Order";
        ShippingChargesType: Enum "Sales Line Type";
    begin
        // [SCENARIO] Create sales line from a Shopify order and try to map shipping charges account information when type is an gl account.
        Initialize();

        // [GIVEN] Shopify Shop
        Shop := CommunicationMgt.GetShopRecord();

        // [GIVEN] ShpfyImportOrder.ImportOrder
        ImportOrder.SetShop(Shop.Code);
        ImportShopifyOrder(Shop, OrderHeader, ImportOrder, false);

        // [GIVEN] Order shipping charges are created for the Shopify order
        CreateOrderShippingCharges(OrderShippingCharges, OrderHeader."Shopify Order Id");

        // [GIVEN] Created shopify shipment method mapping from the shipping charges
        CreateGLAccount(GLAccount);
        CreateShopifyShipmentMethodMapping(
            ShpfyShipmentMethodMapping,
            ShippingChargesType::"G/L Account",
            ShipmentMethod.Code,
            ShippingAgent.Code,
            ShippingAgentServices.Code,
            GLAccount."No.",
            OrderShippingCharges.Title
        );

        // [GIVEN] Register Expected Outbound API Requests.
        OutboundHttpRequests.Clear();
        OutboundHttpRequests.Enqueue('Transactions');

        // [WHEN] Order is processed
        ProcessOrder.Run(OrderHeader);

        // [THEN] Sales line is created with the correct shipping charges account information
        AssertSalesLineValues(
            OrderShippingCharges,
            ShpfyShipmentMethodMapping,
            ShippingChargesType::"G/L Account",
            ShpfyShipmentMethodMapping."Shipping Charges No."
        );
    end;

    [Test]
    [HandlerFunctions('ShippingChargesHttpHandler')]
    procedure UnitTestMapShippingChargesForItemChargeType()
    var
        OrderHeader: Record "Shpfy Order Header";
        ItemCharge: Record "Item Charge";
        ShpfyShipmentMethodMapping: Record "Shpfy Shipment Method Mapping";
        OrderShippingCharges: Record "Shpfy Order Shipping Charges";
        RefundGLAccount: Record "G/L Account";
        ImportOrder: Codeunit "Shpfy Import Order";
        ProcessOrder: Codeunit "Shpfy Process Order";
        ShippingChargesType: Enum "Sales Line Type";
    begin
        // [SCENARIO] Create sales line from a Shopify order and try to map shipping charges account information when type is an item charge.
        Initialize();

        // [GIVEN] Shopify Shop
        Shop := CommunicationMgt.GetShopRecord();

        // [GIVEN] ShpfyImportOrder.ImportOrder
        ImportOrder.SetShop(Shop.Code);
        ImportShopifyOrder(Shop, OrderHeader, ImportOrder, false);

        // [GIVEN] Order shipping charges are created for the Shopify order
        CreateOrderShippingCharges(OrderShippingCharges, OrderHeader."Shopify Order Id");

        // [GIVEN] Created Item Charge
        RefundGLAccount.Get(Shop."Refund Account");
        LibraryInventory.CreateItemCharge(ItemCharge);
        ItemCharge.Validate("VAT Prod. Posting Group", RefundGLAccount."VAT Prod. Posting Group");
        ItemCharge.Modify(true);

        // [GIVEN] Created shopify shipment method mapping from the shipping charges
        CreateShopifyShipmentMethodMapping(
            ShpfyShipmentMethodMapping,
            ShippingChargesType::"Charge (Item)",
            ShipmentMethod.Code,
            ShippingAgent.Code,
            ShippingAgentServices.Code,
            ItemCharge."No.",
            OrderShippingCharges.Title
        );

        // [GIVEN] Register Expected Outbound API Requests.
        OutboundHttpRequests.Clear();
        OutboundHttpRequests.Enqueue('Transactions');

        // [WHEN] Order is processed
        ProcessOrder.Run(OrderHeader);

        // [THEN] Sales line is created with the correct shipping charges account information
        AssertSalesLineValues(
            OrderShippingCharges,
            ShpfyShipmentMethodMapping,
            ShippingChargesType::"Charge (Item)",
            ShpfyShipmentMethodMapping."Shipping Charges No."
        );
    end;

    [Test]
    procedure UnitTestImportShippingTaxLineWithChannelLiableTrue()
    var
        OrderHeader: Record "Shpfy Order Header";
        OrderTaxLine: Record "Shpfy Order Tax Line";
        ShippingCharges: Codeunit "Shpfy Shipping Charges";
        JShippingLines: JsonArray;
        JTaxLines: JsonArray;
        ShippingLineId: BigInteger;
        ChannelLiableScenario: Option Missing,TrueValue,FalseValue,NullValue;
    begin
        // [SCENARIO] The tax line of a shipping line is persisted against the shipping charge with all values preserved and Channel Liable = true.
        Initialize();

        // [GIVEN] Shopify Shop and a Shopify order header
        Shop := CommunicationMgt.GetShopRecord();
        CreateOrderHeaderForShop(OrderHeader);

        // [GIVEN] A shipping line with a single tax line where channelLiable is true
        ShippingLineId := LibraryRandom.RandIntInRange(100000, 199999);
        Clear(JTaxLines);
        AddTaxLineToArray(JTaxLines, 'TAX1', ChannelLiableScenario::TrueValue);
        AddShippingLine(JShippingLines, ShippingLineId, JTaxLines);

        // [WHEN] Shipping cost infos are imported
        ShippingCharges.UpdateShippingCostInfos(OrderHeader, JShippingLines);

        // [THEN] A single tax line is stored against the shipping charge with all values preserved
        OrderTaxLine.SetRange("Parent Id", ShippingLineId);
        LibraryAssert.AreEqual(1, OrderTaxLine.Count(), 'Exactly one shipping tax line must be stored.');
        OrderTaxLine.FindFirst();
        LibraryAssert.AreEqual('TAX1', OrderTaxLine.Title, 'Shipping tax line title must be preserved.');
        LibraryAssert.AreEqual(0.1, OrderTaxLine.Rate, 'Shipping tax line rate must be preserved.');
        LibraryAssert.AreEqual(10, OrderTaxLine."Rate %", 'Shipping tax line rate percentage must be preserved.');
        LibraryAssert.AreEqual(5, OrderTaxLine.Amount, 'Shipping tax line shop amount must be preserved.');
        LibraryAssert.AreEqual(6, OrderTaxLine."Presentment Amount", 'Shipping tax line presentment amount must be preserved.');
        LibraryAssert.IsTrue(OrderTaxLine."Channel Liable", 'Shipping tax line Channel Liable must be true.');
    end;

    [Test]
    procedure UnitTestImportShippingTaxLineWithChannelLiableFalse()
    var
        ChannelLiableScenario: Option Missing,TrueValue,FalseValue,NullValue;
    begin
        // [SCENARIO] The Channel Liable flag of a shipping tax line is imported as false when explicitly set to false.
        VerifyShippingTaxLineChannelLiable(ChannelLiableScenario::FalseValue, false);
    end;

    [Test]
    procedure UnitTestImportShippingTaxLineWithChannelLiableNull()
    var
        ChannelLiableScenario: Option Missing,TrueValue,FalseValue,NullValue;
    begin
        // [SCENARIO] A null channelLiable on a shipping tax line defaults to false.
        VerifyShippingTaxLineChannelLiable(ChannelLiableScenario::NullValue, false);
    end;

    [Test]
    procedure UnitTestImportShippingTaxLineWithChannelLiableMissing()
    var
        ChannelLiableScenario: Option Missing,TrueValue,FalseValue,NullValue;
    begin
        // [SCENARIO] A missing channelLiable on a shipping tax line defaults to false.
        VerifyShippingTaxLineChannelLiable(ChannelLiableScenario::Missing, false);
    end;

    [Test]
    procedure UnitTestImportShippingTaxLinesForMultipleShippingLinesAreSeparated()
    var
        OrderHeader: Record "Shpfy Order Header";
        OrderTaxLine: Record "Shpfy Order Tax Line";
        ShippingCharges: Codeunit "Shpfy Shipping Charges";
        JShippingLines: JsonArray;
        JFirstTaxLines: JsonArray;
        JSecondTaxLines: JsonArray;
        FirstShippingLineId: BigInteger;
        SecondShippingLineId: BigInteger;
        ChannelLiableScenario: Option Missing,TrueValue,FalseValue,NullValue;
    begin
        // [SCENARIO] Tax lines of multiple shipping lines are kept separated per shipping charge.
        Initialize();

        // [GIVEN] Shopify Shop and a Shopify order header
        Shop := CommunicationMgt.GetShopRecord();
        CreateOrderHeaderForShop(OrderHeader);

        // [GIVEN] Two shipping lines: the first with two tax lines, the second with one
        FirstShippingLineId := LibraryRandom.RandIntInRange(200000, 299999);
        SecondShippingLineId := LibraryRandom.RandIntInRange(300000, 399999);

        AddTaxLineToArray(JFirstTaxLines, 'TAX1', ChannelLiableScenario::TrueValue);
        AddTaxLineToArray(JFirstTaxLines, 'TAX2', ChannelLiableScenario::FalseValue);
        AddShippingLine(JShippingLines, FirstShippingLineId, JFirstTaxLines);

        AddTaxLineToArray(JSecondTaxLines, 'TAX3', ChannelLiableScenario::TrueValue);
        AddShippingLine(JShippingLines, SecondShippingLineId, JSecondTaxLines);

        // [WHEN] Shipping cost infos are imported
        ShippingCharges.UpdateShippingCostInfos(OrderHeader, JShippingLines);

        // [THEN] Each shipping charge keeps its own tax lines
        OrderTaxLine.SetRange("Parent Id", FirstShippingLineId);
        LibraryAssert.AreEqual(2, OrderTaxLine.Count(), 'First shipping line must keep both tax lines.');
        OrderTaxLine.SetRange("Parent Id", SecondShippingLineId);
        LibraryAssert.AreEqual(1, OrderTaxLine.Count(), 'Second shipping line must keep its single tax line.');
    end;

    [Test]
    procedure UnitTestReimportShippingTaxLinesReplacesWithoutDuplicates()
    var
        OrderHeader: Record "Shpfy Order Header";
        OrderTaxLine: Record "Shpfy Order Tax Line";
        ShippingCharges: Codeunit "Shpfy Shipping Charges";
        JShippingLines: JsonArray;
        JTaxLines: JsonArray;
        ShippingLineId: BigInteger;
        ChannelLiableScenario: Option Missing,TrueValue,FalseValue,NullValue;
    begin
        // [SCENARIO] Reimporting the same shipping line replaces its tax lines without duplicates or stale rows.
        Initialize();

        // [GIVEN] Shopify Shop and a Shopify order header
        Shop := CommunicationMgt.GetShopRecord();
        CreateOrderHeaderForShop(OrderHeader);

        // [GIVEN] A shipping line with two tax lines is imported
        ShippingLineId := LibraryRandom.RandIntInRange(400000, 499999);
        Clear(JTaxLines);
        AddTaxLineToArray(JTaxLines, 'TAX1', ChannelLiableScenario::TrueValue);
        AddTaxLineToArray(JTaxLines, 'TAX2', ChannelLiableScenario::FalseValue);
        AddShippingLine(JShippingLines, ShippingLineId, JTaxLines);
        ShippingCharges.UpdateShippingCostInfos(OrderHeader, JShippingLines);

        OrderTaxLine.SetRange("Parent Id", ShippingLineId);
        LibraryAssert.AreEqual(2, OrderTaxLine.Count(), 'Two tax lines must be stored after the first import.');

        // [WHEN] The same shipping line is reimported with a single tax line
        Clear(JShippingLines);
        Clear(JTaxLines);
        AddTaxLineToArray(JTaxLines, 'TAX1', ChannelLiableScenario::TrueValue);
        AddShippingLine(JShippingLines, ShippingLineId, JTaxLines);
        ShippingCharges.UpdateShippingCostInfos(OrderHeader, JShippingLines);

        // [THEN] The stale tax line is removed and no duplicates remain
        OrderTaxLine.SetRange("Parent Id", ShippingLineId);
        LibraryAssert.AreEqual(1, OrderTaxLine.Count(), 'Reimport must replace the tax lines without duplicates or stale rows.');
        OrderTaxLine.FindFirst();
        LibraryAssert.AreEqual('TAX1', OrderTaxLine.Title, 'The remaining tax line must be the reimported one.');
    end;

    [Test]
    procedure UnitTestShippingTaxLinesRemovedWhenShippingLineRemoved()
    var
        OrderHeader: Record "Shpfy Order Header";
        OrderShippingCharges: Record "Shpfy Order Shipping Charges";
        OrderTaxLine: Record "Shpfy Order Tax Line";
        ShippingCharges: Codeunit "Shpfy Shipping Charges";
        JShippingLines: JsonArray;
        JFirstTaxLines: JsonArray;
        JSecondTaxLines: JsonArray;
        JReimportShippingLines: JsonArray;
        JReimportTaxLines: JsonArray;
        FirstShippingLineId: BigInteger;
        SecondShippingLineId: BigInteger;
        ChannelLiableScenario: Option Missing,TrueValue,FalseValue,NullValue;
    begin
        // [SCENARIO] When a shipping line is no longer returned by Shopify, its shipping charge and tax lines are removed.
        Initialize();

        // [GIVEN] Shopify Shop and a Shopify order header
        Shop := CommunicationMgt.GetShopRecord();
        CreateOrderHeaderForShop(OrderHeader);

        // [GIVEN] Two shipping lines, each with a tax line, are imported
        FirstShippingLineId := LibraryRandom.RandIntInRange(500000, 599999);
        SecondShippingLineId := LibraryRandom.RandIntInRange(600000, 699999);

        AddTaxLineToArray(JFirstTaxLines, 'TAX1', ChannelLiableScenario::TrueValue);
        AddShippingLine(JShippingLines, FirstShippingLineId, JFirstTaxLines);
        AddTaxLineToArray(JSecondTaxLines, 'TAX2', ChannelLiableScenario::FalseValue);
        AddShippingLine(JShippingLines, SecondShippingLineId, JSecondTaxLines);
        ShippingCharges.UpdateShippingCostInfos(OrderHeader, JShippingLines);

        // [WHEN] Only the first shipping line is returned on reimport
        AddTaxLineToArray(JReimportTaxLines, 'TAX1', ChannelLiableScenario::TrueValue);
        AddShippingLine(JReimportShippingLines, FirstShippingLineId, JReimportTaxLines);
        ShippingCharges.UpdateShippingCostInfos(OrderHeader, JReimportShippingLines);

        // [THEN] The removed shipping charge and its tax lines are deleted
        LibraryAssert.IsFalse(OrderShippingCharges.Get(SecondShippingLineId), 'The removed shipping charge must be deleted.');
        OrderTaxLine.SetRange("Parent Id", SecondShippingLineId);
        LibraryAssert.AreEqual(0, OrderTaxLine.Count(), 'Tax lines of the removed shipping line must be deleted.');
        OrderTaxLine.SetRange("Parent Id", FirstShippingLineId);
        LibraryAssert.AreEqual(1, OrderTaxLine.Count(), 'The remaining shipping line must keep its tax line.');
    end;
    #endregion

    [HttpClientHandler]
    internal procedure ShippingChargesHttpHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    var
        RequestType: Text;
        Body: Text;
    begin
        if not InitializeTest.VerifyRequestUrl(Request.Path, Shop."Shopify URL") then
            exit(true);

        if OutboundHttpRequests.Length() > 0 then begin
            RequestType := OutboundHttpRequests.DequeueText();
            case RequestType of
                'Transactions':
                    begin
                        Body := NavApp.GetResourceAsText('Order Handling/OrderTransactionResult.txt', TextEncoding::UTF8);
                        Response.Content.WriteFrom(Body);
                    end;
                'CompanyLocation':
                    begin
                        Body := NavApp.GetResourceAsText('Order Handling/CompanyLocationResult.txt', TextEncoding::UTF8);
                        Response.Content.WriteFrom(Body.Replace('{{LocationId}}', '0'));
                    end;
            end;
        end else
            Response.Content.WriteFrom('{"data":{}}');
        exit(false);
    end;

    #region Local Procedures
    local procedure Initialize()
    var
        ShippingTime: DateFormula;
        AccessToken: SecretText;
    begin
        if IsInitialized then
            exit;

        Codeunit.Run(Codeunit::"Shpfy Initialize Test");
        Shop := CommunicationMgt.GetShopRecord();

        AccessToken := LibraryRandom.RandText(20);
        InitializeTest.RegisterAccessTokenForShop(Shop.GetStoreName(), AccessToken);

        Evaluate(ShippingTime, '<1W>');
        CreateShipmentMethod(ShipmentMethod);
        LibraryInventory.CreateShippingAgent(ShippingAgent);
        LibraryInventory.CreateShippingAgentService(ShippingAgentServices, ShippingAgent.Code, ShippingTime);

        Commit();

        IsInitialized := true;
    end;

    local procedure CreateShopifyShipmentMethodMapping(
        var ShpfyShipmentMethodMapping: Record "Shpfy Shipment Method Mapping";
        ShippingChargesType: Enum "Sales Line Type";
        ShipmentMethodCode: Code[10];
        ShippingAgentCode: Code[10];
        ShippingAgentServiceCode: Code[10];
        ShippingChargesNo: Code[20];
        Name: Text[50]
    )
    begin
        ShpfyShipmentMethodMapping.Init();
        ShpfyShipmentMethodMapping."Shop Code" := Shop.Code;
        ShpfyShipmentMethodMapping.Name := Name;
        ShpfyShipmentMethodMapping."Shipment Method Code" := ShipmentMethodCode;
        ShpfyShipmentMethodMapping."Shipping Charges Type" := ShippingChargesType;
        ShpfyShipmentMethodMapping."Shipping Charges No." := ShippingChargesNo;
        ShpfyShipmentMethodMapping."Shipping Agent Code" := ShippingAgentCode;
        ShpfyShipmentMethodMapping."Shipping Agent Service Code" := ShippingAgentServiceCode;
        ShpfyShipmentMethodMapping.Insert(true);
    end;

    local procedure CreateShipmentMethod(LocalShipmentMethod: Record "Shipment Method")
    var
        LibraryUtility: Codeunit "Library - Utility";
    begin
        LocalShipmentMethod.Init();
        LocalShipmentMethod.Code := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(LocalShipmentMethod.Code)), 1, MaxStrLen(LocalShipmentMethod.Code));
        LocalShipmentMethod.Insert(true);
    end;

    local procedure ImportShopifyOrder(var ShopifyShop: Record "Shpfy Shop"; var OrderHeader: Record "Shpfy Order Header"; var OrdersToImport: Record "Shpfy Orders to Import"; var ImportOrder: Codeunit "Shpfy Import Order"; var JShopifyOrder: JsonObject; var JShopifyLineItems: JsonArray)
    begin
        ImportOrder.ImportCreateAndUpdateOrderHeaderFromMock(ShopifyShop.Code, OrdersToImport.Id, JShopifyOrder);
        ImportOrder.ImportCreateAndUpdateOrderLinesFromMock(OrdersToImport.Id, JShopifyLineItems);
        Commit();
        OrderHeader.Get(OrdersToImport.Id);
    end;

    local procedure ImportShopifyOrder(var ShopifyShop: Record "Shpfy Shop"; var OrderHeader: Record "Shpfy Order Header"; var ImportOrder: Codeunit "Shpfy Import Order"; B2B: Boolean)
    var
        OrdersToImport: Record "Shpfy Orders to Import";
        OrderHandlingHelper: Codeunit "Shpfy Order Handling Helper";
        JShopifyLineItems: JsonArray;
        JShopifyOrder: JsonObject;
    begin
        JShopifyOrder := OrderHandlingHelper.CreateShopifyOrderAsJson(ShopifyShop, OrdersToImport, JShopifyLineItems, B2B);
        ImportShopifyOrder(ShopifyShop, OrderHeader, OrdersToImport, ImportOrder, JShopifyOrder, JShopifyLineItems);
    end;

    local procedure CreateOrderShippingCharges(var OrderShippingCharges: Record "Shpfy Order Shipping Charges"; ShopifyOrderId: BigInteger)
    begin
        OrderShippingCharges.Init();
        OrderShippingCharges."Shopify Shipping Line Id" := LibraryRandom.RandInt(100000);
        OrderShippingCharges."Shopify Order Id" := ShopifyOrderId;
        OrderShippingCharges.Title := CopyStr(LibraryRandom.RandText(50), 1, MaxStrLen(OrderShippingCharges.Title));
        OrderShippingCharges.Amount := LibraryRandom.RandDec(10, 0);
        OrderShippingCharges.Insert(true);
    end;

    local procedure CreateOrderHeaderForShop(var OrderHeader: Record "Shpfy Order Header")
    begin
        Clear(OrderHeader);
        OrderHeader."Shopify Order Id" := LibraryRandom.RandIntInRange(700000, 999999);
        OrderHeader."Shop Code" := Shop.Code;
        OrderHeader.Insert();
    end;

    local procedure VerifyShippingTaxLineChannelLiable(ChannelLiableScenario: Option Missing,TrueValue,FalseValue,NullValue; ExpectedChannelLiable: Boolean)
    var
        OrderHeader: Record "Shpfy Order Header";
        OrderTaxLine: Record "Shpfy Order Tax Line";
        ShippingCharges: Codeunit "Shpfy Shipping Charges";
        JShippingLines: JsonArray;
        JTaxLines: JsonArray;
        ShippingLineId: BigInteger;
    begin
        Initialize();

        // [GIVEN] Shopify Shop and a Shopify order header
        Shop := CommunicationMgt.GetShopRecord();
        CreateOrderHeaderForShop(OrderHeader);

        // [GIVEN] A shipping line with a single tax line for the given channelLiable scenario
        ShippingLineId := LibraryRandom.RandIntInRange(100000, 199999);
        Clear(JTaxLines);
        AddTaxLineToArray(JTaxLines, 'TAX1', ChannelLiableScenario);
        AddShippingLine(JShippingLines, ShippingLineId, JTaxLines);

        // [WHEN] Shipping cost infos are imported
        ShippingCharges.UpdateShippingCostInfos(OrderHeader, JShippingLines);

        // [THEN] A tax line is stored with the expected Channel Liable value
        OrderTaxLine.SetRange("Parent Id", ShippingLineId);
        LibraryAssert.AreEqual(1, OrderTaxLine.Count(), 'Exactly one shipping tax line must be stored.');
        OrderTaxLine.FindFirst();
        LibraryAssert.AreEqual(ExpectedChannelLiable, OrderTaxLine."Channel Liable", 'Shipping tax line Channel Liable is not as expected.');
    end;

    local procedure AddShippingLine(var JShippingLines: JsonArray; ShippingLineId: BigInteger; JTaxLines: JsonArray)
    var
        JShippingLine: JsonObject;
        JPriceSet: JsonObject;
        JShopMoney: JsonObject;
        JPresentmentMoney: JsonObject;
    begin
        JShippingLine.Add('id', StrSubstNo(ShippingLineGIdTok, ShippingLineId));
        JShippingLine.Add('title', StrSubstNo('Shipping %1', ShippingLineId));
        JShippingLine.Add('code', 'STD');
        JShippingLine.Add('source', 'shopify');
        JShopMoney.Add('amount', '20');
        JPriceSet.Add('shopMoney', JShopMoney);
        JPresentmentMoney.Add('amount', '24');
        JPriceSet.Add('presentmentMoney', JPresentmentMoney);
        JShippingLine.Add('originalPriceSet', JPriceSet);
        JShippingLine.Add('taxLines', JTaxLines);
        JShippingLines.Add(JShippingLine);
    end;

    local procedure AddTaxLineToArray(var JTaxLines: JsonArray; Title: Text; ChannelLiableScenario: Option Missing,TrueValue,FalseValue,NullValue)
    var
        JTaxLine: JsonObject;
        JPriceSet: JsonObject;
        JShopMoney: JsonObject;
        JPresentmentMoney: JsonObject;
        JNull: JsonValue;
    begin
        JTaxLine.Add('title', Title);
        JTaxLine.Add('rate', 0.1);
        JTaxLine.Add('ratePercentage', 10);
        JShopMoney.Add('amount', '5');
        JPriceSet.Add('shopMoney', JShopMoney);
        JPresentmentMoney.Add('amount', '6');
        JPriceSet.Add('presentmentMoney', JPresentmentMoney);
        JTaxLine.Add('priceSet', JPriceSet);
        case ChannelLiableScenario of
            ChannelLiableScenario::TrueValue:
                JTaxLine.Add('channelLiable', true);
            ChannelLiableScenario::FalseValue:
                JTaxLine.Add('channelLiable', false);
            ChannelLiableScenario::NullValue:
                begin
                    JNull.SetValueToNull();
                    JTaxLine.Add('channelLiable', JNull);
                end;
        // Missing: channelLiable is intentionally not added
        end;
        JTaxLines.Add(JTaxLine);
    end;

    local procedure CreateGLAccount(var GLAccount: Record "G/L Account")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        LibraryERM: Codeunit "Library - ERM";
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup,
           VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandDecInDecimalRange(10, 25, 0));
        GLAccount.Get(LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, Enum::"General Posting Type"::Sale));
        GLAccount."Direct Posting" := true;

        InitializeTest.CreateVATPostingSetup(Shop."VAT Bus. Posting Group", GLAccount."VAT Prod. Posting Group");

        GLAccount.Modify(false);
    end;

    local procedure AssertSalesLineValues(
        OrderShippingCharges: Record "Shpfy Order Shipping Charges";
        ShpfyShipmentMethodMapping: Record "Shpfy Shipment Method Mapping";
        SalesLineType: Enum "Sales Line Type";
        ExpectedChargesAccountNo: Code[20]
    )
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        SalesHeader.SetRange("Shpfy Order Id", OrderShippingCharges."Shopify Order Id");
        LibraryAssert.IsTrue(SalesHeader.FindLast(), 'Sales document is not created from Shopify order');

        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLineType);
        SalesLine.SetRange(Description, OrderShippingCharges.Title);

        LibraryAssert.IsTrue(SalesLine.FindLast(), 'Sales line is not created from Shopify order');
        LibraryAssert.AreEqual(ExpectedChargesAccountNo, SalesLine."No.", 'Shipping Charges Account is not as expected');
        LibraryAssert.AreEqual(ShpfyShipmentMethodMapping."Shipping Agent Code", SalesLine."Shipping Agent Code", 'Shipping Agent Code is not as expected');
        LibraryAssert.AreEqual(ShpfyShipmentMethodMapping."Shipping Agent Service Code", SalesLine."Shipping Agent Service Code", 'Shipping Agent Service Code is not as expected');
    end;

    local procedure AssertSalesHeaderValues(
        OrderHeader: Record "Shpfy Order Header";
        SalesHeader: Record "Sales Header";
        ShpfyShipmentMethodMapping: Record "Shpfy Shipment Method Mapping"
    )
    begin
        SalesHeader.SetRange("Shpfy Order Id", OrderHeader."Shopify Order Id");
        LibraryAssert.IsTrue(SalesHeader.FindLast(), 'Sales document is not created from Shopify order');
        LibraryAssert.AreEqual(ShpfyShipmentMethodMapping."Shipping Agent Code", SalesHeader."Shipping Agent Code", 'Shipping Agent Code must be the same as in the shipment method mapping.');
        LibraryAssert.AreEqual(ShpfyShipmentMethodMapping."Shipping Agent Service Code", SalesHeader."Shipping Agent Service Code", 'Shipping Agent Service Code must be the same as in the shipment method mapping.');
    end;
    #endregion
}
