// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Finance.Currency;
using Microsoft.Finance.SalesTax;
using Microsoft.Foundation.Address;
using Microsoft.Integration.Shopify;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using System.TestLibraries.Utilities;

codeunit 139608 "Shpfy Orders API Test"
{
    Subtype = Test;
    TestType = Uncategorized;
    TestPermissions = Disabled;

    var
        LibraryAssert: Codeunit "Library Assert";
        LibraryRandom: Codeunit "Library - Random";
        OrdersAPISubscriber: Codeunit "Shpfy Orders API Subscriber";
        Any: Codeunit Any;
        OrdersToImportChannelLiableMismatchTxt: Label 'Orders to import Channel Liable Taxes mismatch when %1.', Locked = true;
        OrderLevelTaxLineExpectedTxt: Label 'An order-level tax line should exist when %1.', Locked = true;
        ChannelLiableFlagMismatchTxt: Label 'Channel Liable flag mismatch when %1.', Locked = true;
        OrderHeaderChannelLiableMismatchTxt: Label 'Order header Channel Liable Taxes mismatch when %1.', Locked = true;

    [Test]
    procedure UnitTestExtractShopifyOrdersToImport()
    var
        Shop: Record "Shpfy Shop";
        OrdersToImport: Record "Shpfy Orders to Import";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        OrderHandlingHelper: Codeunit "Shpfy Order Handling Helper";
        OrdersAPI: Codeunit "Shpfy Orders API";
        Cursor: Text;
        JOrdersToImport: JsonObject;
    begin
        // [SCENARIO] Create a randpom expected Json structure for the OrdersToImport and see of all orders are available in the "Shpfy Orders to Import" table.
        // [SCENARIO] At start we reset the "Shpfy Orders to Import" table so we can see how many record are added.
        Initialize();
        Clear(OrdersToImport);
        if not OrdersToImport.IsEmpty then
            OrdersToImport.DeleteAll();

        // [GIVEN] Shopify Shop
        Shop := CommunicationMgt.GetShopRecord();
        // [GIVEN] the orders to import as a json structure.
        JOrdersToImport := OrderHandlingHelper.GetOrdersToImport(false);
        // [GIVEN] the cursor text varable for retreiving the last cursor.

        // [WHEN] Execute ShpfyOrdersAPI.ExtractShopifyOrdersToImport
        OrdersAPI.ExtractShopifyOrdersToImport(Shop, JOrdersToImport, Cursor);
        // [THEN] The result must be true.
        LibraryAssert.IsTrue(OrdersAPI.ExtractShopifyOrdersToImport(Shop, JOrdersToImport, Cursor), 'Extracting orders must return true.');

        // [THEN] The last cursor must have lenght of 92 characters.
        LibraryAssert.AreEqual(92, StrLen(Cursor), 'The cursor has a lenght of 92 characters');

        // [THEN] The number of orders that where imported must be the same as in the table "Shpfy Order to Import".
        LibraryAssert.AreEqual(OrderHandlingHelper.CountOrdersToImport(JOrdersToImport), OrdersToImport.Count, 'All orders to import are in the "Shpfy Orders to Import" table');
    end;

    [Test]
    procedure UnitTestExtractB2BShopifyOrdersToImport()
    var
        Shop: Record "Shpfy Shop";
        OrdersToImport: Record "Shpfy Orders to Import";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        OrderHandlingHelper: Codeunit "Shpfy Order Handling Helper";
        OrdersAPI: Codeunit "Shpfy Orders API";
        Cursor: Text;
        JOrdersToImport: JsonObject;
    begin
        // [SCENARIO] Create a randpom expected Json structure for the OrdersToImport and see of all orders are available in the "Shpfy Orders to Import" table.
        // [SCENARIO] At start we reset the "Shpfy Orders to Import" table so we can see how many record are added.
        Initialize();
        Clear(OrdersToImport);
        if not OrdersToImport.IsEmpty then
            OrdersToImport.DeleteAll();

        // [GIVEN] Shopify Shop
        Shop := CommunicationMgt.GetShopRecord();
        // [GIVEN] the orders to import as a json structure.
        JOrdersToImport := OrderHandlingHelper.GetOrdersToImport(true);
        // [GIVEN] the cursor text varable for retreiving the last cursor.

        // [WHEN] Execute ShpfyOrdersAPI.ExtractShopifyOrdersToImport
        OrdersAPI.ExtractShopifyOrdersToImport(Shop, JOrdersToImport, Cursor);
        // [THEN] The result must be true.
        LibraryAssert.IsTrue(OrdersAPI.ExtractShopifyOrdersToImport(Shop, JOrdersToImport, Cursor), 'Extracting orders must return true.');

        // [THEN] The number of orders with Purchasing Entity = Company that where imported must be the same as in the table "Shpfy Order to Import".
        OrdersToImport.SetRange("Purchasing Entity", OrdersToImport."Purchasing Entity"::Company);
        LibraryAssert.AreEqual(OrderHandlingHelper.CountOrdersToImport(JOrdersToImport), OrdersToImport.Count, 'All orders to import are in the "Shpfy Orders to Import" table');
    end;

    [Test]
    procedure UnitTestImportShopifyOrder()
    var
        Shop: Record "Shpfy Shop";
        OrderHeader: Record "Shpfy Order Header";
        OrdersToImport: Record "Shpfy Orders to Import";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        ImportOrder: Codeunit "Shpfy Import Order";
        OrderHandlingHelper: Codeunit "Shpfy Order Handling Helper";
        JShopifyOrder: JsonObject;
        JShopifyLineItems: JsonArray;
    begin
        // [SCENARIO] Import a Shopify order from the "Shpfy Orders to Import" record.
        Initialize();

        // [GIVEN] Shopify Shop
        Shop := CommunicationMgt.GetShopRecord();
        Shop."Customer Mapping Type" := "Shpfy Customer Mapping"::"By EMail/Phone";
        if not Shop.Modify() then
            Shop.Insert();
        ImportOrder.SetShop(Shop.Code);

        // [GIVEN] the order to import as a json structure.
        JShopifyOrder := OrderHandlingHelper.CreateShopifyOrderAsJson(Shop, OrdersToImport, JShopifyLineItems, false);

        // [WHEN] ShpfyImportOrder.ImportOrder
        OrderHandlingHelper.ImportShopifyOrder(Shop, OrderHeader, OrdersToImport, ImportOrder, JShopifyOrder, JShopifyLineItems);

        // [THEN] ShpfyOrdersToImport.Id = ShpfyOrderHeader."Shopify Order Id"
        LibraryAssert.AreEqual(OrdersToImport.Id, OrderHeader."Shopify Order Id", 'ShpfyOrdersToImport.Id = ShpfyOrderHeader."Shopify Order Id"');

        // [THEN] ShpfyOrdersToImport."Order No." = ShpfyOrderHeader."Shopify Order No."
        LibraryAssert.AreEqual(OrdersToImport."Order No.", OrderHeader."Shopify Order No.", 'ShpfyOrdersToImport."Order No." = ShpfyOrderHeader."Shopify Order No."');

        // [THEN] ShpfyOrdersToImport."Order Amount" = ShpfyOrderHeader."Total Amount"
        LibraryAssert.AreEqual(OrdersToImport."Order Amount", OrderHeader."Total Amount", 'ShpfyOrdersToImport."Order Amount" = ShpfyOrderHeader."Total Amount"');
    end;

    [Test]
    procedure UnitTestImportShopifyOrderStoresRetailLocation()
    var
        Shop: Record "Shpfy Shop";
        OrderHeader: Record "Shpfy Order Header";
        OrdersToImport: Record "Shpfy Orders to Import";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        ImportOrder: Codeunit "Shpfy Import Order";
        OrderHandlingHelper: Codeunit "Shpfy Order Handling Helper";
        JShopifyOrder: JsonObject;
        JShopifyLineItems: JsonArray;
    begin
        // [SCENARIO] Retail location metadata is stored on the Shopify order header during import.
        Initialize();

        // [GIVEN] Shopify Shop
        Shop := CommunicationMgt.GetShopRecord();
        Shop."Customer Mapping Type" := "Shpfy Customer Mapping"::"By EMail/Phone";
        if not Shop.Modify() then
            Shop.Insert();
        ImportOrder.SetShop(Shop.Code);

        // [GIVEN] the order to import as a json structure containing retail location info.
        JShopifyOrder := OrderHandlingHelper.CreateShopifyOrderAsJson(Shop, OrdersToImport, JShopifyLineItems, false);

        // [WHEN] ShpfyImportOrder.ImportOrder
        OrderHandlingHelper.ImportShopifyOrder(Shop, OrderHeader, OrdersToImport, ImportOrder, JShopifyOrder, JShopifyLineItems);

        // [THEN] Retail location details are stored on the order header
        LibraryAssert.AreEqual(1234567890L, OrderHeader."Retail Location Id", 'Retail location id must be stored on the order header.');
        LibraryAssert.AreEqual('Retail Test Location', OrderHeader."Retail Location Name", 'Retail location name must be stored on the order header.');
    end;

    [Test]
    procedure UnitTestImportB2BShopifyOrder()
    var
        Shop: Record "Shpfy Shop";
        OrderHeader: Record "Shpfy Order Header";
        OrdersToImport: Record "Shpfy Orders to Import";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        ImportOrder: Codeunit "Shpfy Import Order";
        OrderHandlingHelper: Codeunit "Shpfy Order Handling Helper";
        JShopifyOrder: JsonObject;
        JShopifyLineItems: JsonArray;
    begin
        // [SCENARIO] Import a Shopify order from the "Shpfy Orders to Import" record.
        Initialize();

        // [GIVEN] Shopify Shop
        Shop := CommunicationMgt.GetShopRecord();
        Shop."Company Mapping Type" := "Shpfy Company Mapping"::"By EMail/Phone";
        if not Shop.Modify() then
            Shop.Insert();
        ImportOrder.SetShop(Shop.Code);

        // [GIVEN] the order to import as a json structure.
        JShopifyOrder := OrderHandlingHelper.CreateShopifyOrderAsJson(Shop, OrdersToImport, JShopifyLineItems, true);

        // [WHEN] ShpfyImportOrder.ImportOrder
        OrderHandlingHelper.ImportShopifyOrder(Shop, OrderHeader, OrdersToImport, ImportOrder, JShopifyOrder, JShopifyLineItems);

        // [THEN] ShpfyOrdersToImport.Id = ShpfyOrderHeader."Shopify Order Id"
        LibraryAssert.AreEqual(OrdersToImport.Id, OrderHeader."Shopify Order Id", 'ShpfyOrdersToImport.Id = ShpfyOrderHeader."Shopify Order Id"');

        // [THEN] ShpfyOrdersToImport."Order No." = ShpfyOrderHeader."Shopify Order No."
        LibraryAssert.AreEqual(OrdersToImport."Order No.", OrderHeader."Shopify Order No.", 'ShpfyOrdersToImport."Order No." = ShpfyOrderHeader."Shopify Order No."');

        // [THEN] ShpfyOrderHeader.B2B = true
        LibraryAssert.IsTrue(OrderHeader.B2B, 'ShpfyOrderHeader.B2B = true');

        // [THEN] ShpfyOrderHeader."Company Id" is not empty
        LibraryAssert.AreNotEqual(OrderHeader."Company Id", '', 'ShpfyOrderHeader."Company Id" is not empty');
    end;

    [Test]
    procedure UnitTestDoMappingsOnAShopifyOrder()
    var
        Shop: Record "Shpfy Shop";
        OrderHeader: Record "Shpfy Order Header";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        OrderMapping: Codeunit "Shpfy Order Mapping";
        ImportOrder: Codeunit "Shpfy Import Order";
        OrderHandlingHelper: Codeunit "Shpfy Order Handling Helper";
        Result: Boolean;
    begin
        // [SCENARIO] Creating a random Shopify Order and try to map customer and product data.
        // [SCENARIO] If everithing succeed the function will return true.
        Initialize();

        // [GIVEN] Shopify Shop
        Shop := CommunicationMgt.GetShopRecord();
        Shop."Customer Mapping Type" := "Shpfy Customer Mapping"::"By EMail/Phone";
        if not Shop.Modify() then
            Shop.Insert();
        ImportOrder.SetShop(Shop.Code);

        // [GIVEN] ShpfyImportOrder.ImportOrder
        OrderHandlingHelper.ImportShopifyOrder(Shop, OrderHeader, ImportOrder, false);

        // [WHEN] ShpfyOrderMapping.DoMapping(ShpfyOrderHeader)
        Result := OrderMapping.DoMapping(OrderHeader);

        // [THEN] The result must be true if everthing is mapped.
        LibraryAssert.IsTrue(Result, 'Order Mapping must succeed.');
    end;

    [Test]
    procedure UnitTestDoMappingsOnAB2BShopifyOrder()
    var
        Shop: Record "Shpfy Shop";
        OrderHeader: Record "Shpfy Order Header";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        OrderMapping: Codeunit "Shpfy Order Mapping";
        ImportOrder: Codeunit "Shpfy Import Order";
        OrderHandlingHelper: Codeunit "Shpfy Order Handling Helper";
        Result: Boolean;
    begin
        // [SCENARIO] Creating a random Shopify Order and try to map customer and product data.
        // [SCENARIO] If everithing succeed the function will return true.
        Initialize();

        // [GIVEN] Shopify Shop
        Shop := CommunicationMgt.GetShopRecord();
        Shop."Company Mapping Type" := "Shpfy Company Mapping"::"By EMail/Phone";
        if not Shop.Modify() then
            Shop.Insert();
        ImportOrder.SetShop(Shop.Code);

        // [GIVEN] ShpfyImportOrder.ImportOrder
        OrderHandlingHelper.ImportShopifyOrder(Shop, OrderHeader, ImportOrder, true);

        // [WHEN] ShpfyOrderMapping.DoMapping(ShpfyOrderHeader)
        Result := OrderMapping.DoMapping(OrderHeader);

        // [THEN] The result must be true if everthing is mapped.
        LibraryAssert.IsTrue(Result, 'Order Mapping must succeed.');
    end;

    [Test]
    procedure UnitTestDoMappingsOnAB2BShopifyOrderImportLocation()
    var
        Shop: Record "Shpfy Shop";
        OrderHeader: Record "Shpfy Order Header";
        CompanyLocation: Record "Shpfy Company Location";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        OrderMapping: Codeunit "Shpfy Order Mapping";
        ImportOrder: Codeunit "Shpfy Import Order";
        OrderHandlingHelper: Codeunit "Shpfy Order Handling Helper";
    begin
        // [SCENARIO] Creating a random Shopify Order and try to map customer and product data.
        // [SCENARIO] If everithing succeed the function will return true.
        Initialize();

        // [GIVEN] Shopify Shop
        Shop := CommunicationMgt.GetShopRecord();
        Shop."Company Mapping Type" := "Shpfy Company Mapping"::"By EMail/Phone";
        if not Shop.Modify() then
            Shop.Insert();
        ImportOrder.SetShop(Shop.Code);

        // [GIVEN] ShpfyImportOrder.ImportOrder
        OrderHandlingHelper.ImportShopifyOrder(Shop, OrderHeader, ImportOrder, true);
        OrderHeader."Company Location Id" := Any.IntegerInRange(100000, 999999);
        OrderHeader.Modify();
        OrdersAPISubscriber.SetLocationId(OrderHeader."Company Location Id");

        // [WHEN] ShpfyOrderMapping.DoMapping(ShpfyOrderHeader)
        OrderMapping.DoMapping(OrderHeader);

        // [THEN] Company Location must be mapped correctly
        CompanyLocation.Get(OrderHeader."Company Location Id");
    end;

    [Test]
    procedure UnitTestImportShopifyOrderAndCreateSalesDocument()
    var
        Shop: Record "Shpfy Shop";
        OrderHeader: Record "Shpfy Order Header";
        SalesHeader: Record "Sales Header";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        ImportOrder: Codeunit "Shpfy Import Order";
        ProcessOrders: Codeunit "Shpfy Process Orders";
        OrderHandlingHelper: Codeunit "Shpfy Order Handling Helper";
    begin
        // [SCENARIO] Creating a random Shopify Order and try to map customer and product data.
        // [SCENARIO] When the sales document is created, everything will be mapped and the sales document must exist.
        Initialize();

        // [GIVEN] Shopify Shop
        Shop := CommunicationMgt.GetShopRecord();
        Shop."Customer Mapping Type" := "Shpfy Customer Mapping"::"By EMail/Phone";
        if not Shop.Modify() then
            Shop.Insert();
        ImportOrder.SetShop(Shop.Code);

        // [GIVEN] ShpfyImportOrder.ImportOrder
        OrderHandlingHelper.ImportShopifyOrder(Shop, OrderHeader, ImportOrder, false);
        Commit();

        // [WHEN]
        ProcessOrders.ProcessShopifyOrder(OrderHeader);
        OrderHeader.GetBySystemId(OrderHeader.SystemId);

        // [THEN] Sales document is created from Shopify order
        SalesHeader.SetRange("Shpfy Order Id", OrderHeader."Shopify Order Id");
        LibraryAssert.IsTrue(SalesHeader.FindLast(), 'Sales document is created from Shopify order');

        case SalesHeader."Document Type" of
            "Sales Document Type"::Order:
                // [THEN] ShShpfyOrderHeader."Sales Order No." = SalesHeader."No."
                LibraryAssert.AreEqual(OrderHeader."Sales Order No.", SalesHeader."No.", 'ShpfyOrderHeader."Sales Order No." = SalesHeader."No."');
            "Sales document Type"::Invoice:
                // [THEN] ShShpfyOrderHeader."Sales Invoice No." = SalesHeader."No."
                LibraryAssert.AreEqual(OrderHeader."Sales Invoice No.", SalesHeader."No.", 'ShpfyOrderHeader."Sales Invoice No." = SalesHeader."No."');
            else
                Error('Invalid Document Type');
        end;
    end;

    [Test]
    procedure UnitTestImportB2BShopifyOrderAndCreateSalesDocument()
    var
        Shop: Record "Shpfy Shop";
        OrderHeader: Record "Shpfy Order Header";
        SalesHeader: Record "Sales Header";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        ImportOrder: Codeunit "Shpfy Import Order";
        ProcessOrders: Codeunit "Shpfy Process Orders";
        OrderHandlingHelper: Codeunit "Shpfy Order Handling Helper";
    begin
        // [SCENARIO] Creating a random Shopify Order and try to map customer and product data.
        // [SCENARIO] When the sales document is created, everything will be mapped and the sales document must exist.
        Initialize();

        // [GIVEN] Shopify Shop
        Shop := CommunicationMgt.GetShopRecord();
        Shop."Customer Mapping Type" := "Shpfy Customer Mapping"::"By EMail/Phone";
        if not Shop.Modify() then
            Shop.Insert();
        ImportOrder.SetShop(Shop.Code);

        // [GIVEN] ShpfyImportOrder.ImportOrder
        OrderHandlingHelper.ImportShopifyOrder(Shop, OrderHeader, ImportOrder, true);
        Commit();

        // [WHEN]
        ProcessOrders.ProcessShopifyOrder(OrderHeader);
        OrderHeader.GetBySystemId(OrderHeader.SystemId);

        // [THEN] Sales document is created from Shopify order
        SalesHeader.SetRange("Shpfy Order Id", OrderHeader."Shopify Order Id");
        LibraryAssert.IsTrue(SalesHeader.FindLast(), 'Sales document is created from Shopify order');

        case SalesHeader."Document Type" of
            "Sales Document Type"::Order:
                // [THEN] ShShpfyOrderHeader."Sales Order No." = SalesHeader."No."
                LibraryAssert.AreEqual(OrderHeader."Sales Order No.", SalesHeader."No.", 'ShpfyOrderHeader."Sales Order No." = SalesHeader."No."');
            "Sales document Type"::Invoice:
                // [THEN] ShShpfyOrderHeader."Sales Invoice No." = SalesHeader."No."
                LibraryAssert.AreEqual(OrderHeader."Sales Invoice No.", SalesHeader."No.", 'ShpfyOrderHeader."Sales Invoice No." = SalesHeader."No."');
            else
                Error('Invalid Document Type');
        end;
    end;

    [Test]
    procedure UnitTestCreateSalesDocumentTaxPriorityCode()
    var
        Shop: Record "Shpfy Shop";
        OrderHeader: Record "Shpfy Order Header";
        SalesHeader: Record "Sales Header";
        TaxArea: Record "Tax Area";
        ShopifyTaxArea: Record "Shpfy Tax Area";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        ImportOrder: Codeunit "Shpfy Import Order";
        ProcessOrders: Codeunit "Shpfy Process Orders";
        OrderHandlingHelper: Codeunit "Shpfy Order Handling Helper";
    begin
        // [SCENARIO] When the sales document is created, tax priority is taken from the shop.
        Initialize();

        // [GIVEN] Shopify Shop
        Shop := CommunicationMgt.GetShopRecord();
        Shop."Tax Area Priority" := Shop."Tax Area Priority"::"Ship-to -> Sell-to -> Bill-to";
        Shop."County Source" := Shop."County Source"::"Code";
        if not Shop.Modify() then
            Shop.Insert();
        ImportOrder.SetShop(Shop.Code);

        // [GIVEN] Shopify Tax Area and BC Tax Area
        CreateTaxArea(TaxArea, ShopifyTaxArea, Shop);

        // [GIVEN] ShpfyImportOrder.ImportOrder
        OrderHandlingHelper.ImportShopifyOrder(Shop, OrderHeader, ImportOrder, false);
        OrderHeader."Ship-to City" := ShopifyTaxArea.County;
        OrderHeader."Ship-to Country/Region Code" := ShopifyTaxArea."Country/Region Code";
        OrderHeader."Ship-to County" := ShopifyTaxArea."County Code";
        OrderHeader.Modify();
        Commit();

        // [WHEN] Order is processed
        ProcessOrders.ProcessShopifyOrder(OrderHeader);
        OrderHeader.GetBySystemId(OrderHeader.SystemId);

        // [THEN] Sales document is created from Shopify order with correct tax area
        SalesHeader.SetRange("Shpfy Order Id", OrderHeader."Shopify Order Id");
        LibraryAssert.IsTrue(SalesHeader.FindLast(), 'Sales document is created from Shopify order');
        LibraryAssert.AreEqual(SalesHeader."Tax Area Code", TaxArea.Code, 'Tax Area Code is taken from the ship-to address');
    end;

    [Test]
    procedure UnitTestCreateSalesDocumentTaxPriorityName()
    var
        Shop: Record "Shpfy Shop";
        OrderHeader: Record "Shpfy Order Header";
        SalesHeader: Record "Sales Header";
        TaxArea: Record "Tax Area";
        ShopifyTaxArea: Record "Shpfy Tax Area";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        ImportOrder: Codeunit "Shpfy Import Order";
        ProcessOrders: Codeunit "Shpfy Process Orders";
        OrderHandlingHelper: Codeunit "Shpfy Order Handling Helper";
    begin
        // [SCENARIO] When the sales document is created, tax priority is taken from the shop
        Initialize();

        // [GIVEN] Shopify Shop
        Shop := CommunicationMgt.GetShopRecord();
        Shop."Tax Area Priority" := Shop."Tax Area Priority"::"Sell-to -> Ship-to -> Bill-to";
        Shop."County Source" := Shop."County Source"::"Name";
        if not Shop.Modify() then
            Shop.Insert();
        ImportOrder.SetShop(Shop.Code);

        // [GIVEN] Shopify Tax Area and BC Tax Area
        CreateTaxArea(TaxArea, ShopifyTaxArea, Shop);

        // [GIVEN] ShpfyImportOrder.ImportOrder
        OrderHandlingHelper.ImportShopifyOrder(Shop, OrderHeader, ImportOrder, false);
        OrderHeader."Sell-to City" := ShopifyTaxArea.County;
        OrderHeader."Sell-to Country/Region Code" := ShopifyTaxArea."Country/Region Code";
        OrderHeader."Sell-to County" := CopyStr(ShopifyTaxArea.County, 1, MaxStrLen(OrderHeader."Sell-to County"));
        OrderHeader.Modify();
        Commit();

        // [WHEN] Order is processed
        ProcessOrders.ProcessShopifyOrder(OrderHeader);
        OrderHeader.GetBySystemId(OrderHeader.SystemId);

        // [THEN] Sales document is created from Shopify order with correct tax area
        SalesHeader.SetRange("Shpfy Order Id", OrderHeader."Shopify Order Id");
        LibraryAssert.IsTrue(SalesHeader.FindLast(), 'Sales document is created from Shopify order');
        LibraryAssert.AreEqual(SalesHeader."Tax Area Code", TaxArea.Code, 'Tax Area Code is taken from the sell-to address');
    end;

    [Test]
    procedure UnitTestCreateSalesDocumentTaxPriorityEmpty()
    var
        Shop: Record "Shpfy Shop";
        OrderHeader: Record "Shpfy Order Header";
        SalesHeader: Record "Sales Header";
        TaxArea: Record "Tax Area";
        ShopifyTaxArea: Record "Shpfy Tax Area";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        ImportOrder: Codeunit "Shpfy Import Order";
        ProcessOrders: Codeunit "Shpfy Process Orders";
        OrderHandlingHelper: Codeunit "Shpfy Order Handling Helper";
    begin
        // [SCENARIO] When the sales document is created, tax area is empty if there is no mapping
        Initialize();

        // [GIVEN] Shopify Shop
        Shop := CommunicationMgt.GetShopRecord();
        Shop."Tax Area Priority" := Shop."Tax Area Priority"::"Ship-to -> Sell-to -> Bill-to";
        Shop."County Source" := Shop."County Source"::"Code";
        if not Shop.Modify() then
            Shop.Insert();
        ImportOrder.SetShop(Shop.Code);

        // [GIVEN] Shopify Tax Area and BC Tax Area
        CreateTaxArea(TaxArea, ShopifyTaxArea, Shop);

        // [GIVEN] ShpfyImportOrder.ImportOrder
        OrderHandlingHelper.ImportShopifyOrder(Shop, OrderHeader, ImportOrder, false);
        OrderHeader."Ship-to City" := ShopifyTaxArea.County;
        OrderHeader."Ship-to Country/Region Code" := ShopifyTaxArea."Country/Region Code";
        OrderHeader."Ship-to County" := ShopifyTaxArea."County Code";
        OrderHeader.Modify();

        // [GIVEN] Delete tax area mapping
        ShopifyTaxArea.Delete();
        Commit();

        // [WHEN] Order is processed
        ProcessOrders.ProcessShopifyOrder(OrderHeader);
        OrderHeader.GetBySystemId(OrderHeader.SystemId);

        // [THEN] Sales document is created from Shopify order with correct tax area
        SalesHeader.SetRange("Shpfy Order Id", OrderHeader."Shopify Order Id");
        LibraryAssert.IsTrue(SalesHeader.FindLast(), 'Sales document is created from Shopify order');
        LibraryAssert.AreEqual(SalesHeader."Tax Area Code", '', 'Tax Area Code is empty');
    end;

    [Test]
    procedure UnitTestCreateSalesDocumentReserve()
    var
        Shop: Record "Shpfy Shop";
        OrderHeader: Record "Shpfy Order Header";
        OrderLine: Record "Shpfy Order Line";
        SalesHeader: Record "Sales Header";
        ShopifyCustomer: Record "Shpfy Customer";
        Customer: Record Customer;
        Item: Record Item;
        ShopifyVariant: Record "Shpfy Variant";
        SalesLine: Record "Sales Line";
        ItemJournalLine: Record "Item Journal Line";
        ProcessOrders: Codeunit "Shpfy Process Orders";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        OrderHeaderId: BigInteger;
    begin
        // [SCENARIO] If a customer has the reserve option set to always, the order line will be reserved
        Initialize();

        // [GIVEN] A Shopify sales order
        Shop := CommunicationMgt.GetShopRecord();
        LibrarySales.CreateCustomer(Customer);
        Customer.Reserve := Customer.Reserve::Always;
        Customer.Modify();

        ShopifyCustomer.Id := LibraryRandom.RandIntInRange(100000, 999999);
        ShopifyCustomer."Customer SystemId" := Customer.SystemId;
        ShopifyCustomer."Shop Id" := Shop."Shop Id";
        ShopifyCustomer.Insert();

        OrderHeader."Customer Id" := ShopifyCustomer.Id;
        OrderHeader."Shop Code" := Shop.Code;
        OrderHeader."Shopify Order Id" := LibraryRandom.RandIntInRange(100000, 999999);
        OrderHeaderId := OrderHeader."Shopify Order Id";
        OrderHeader.Insert();

        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', 10);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        ShopifyVariant."Item SystemId" := Item.SystemId;
        ShopifyVariant.Id := LibraryRandom.RandIntInRange(100000, 999999);
        ShopifyVariant."Shop Code" := Shop.Code;
        ShopifyVariant.Insert();
        OrderLine."Shopify Order Id" := OrderHeader."Shopify Order Id";
        OrderLine."Shopify Variant Id" := ShopifyVariant.Id;
        OrderLine.Quantity := 1;
        OrderLine.Insert();
        Commit();

        // [WHEN] Order is processed
        ProcessOrders.ProcessShopifyOrder(OrderHeader);

        // [THEN] Sales document is created from Shopify order and order line is reserved
        SalesHeader.SetRange("Shpfy Order Id", OrderHeaderId);
        LibraryAssert.IsTrue(SalesHeader.FindLast(), 'Sales document is created from Shopify order');
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("No.", Item."No.");
        SalesLine.FindFirst();
        SalesLine.CalcFields("Reserved Quantity");
        LibraryAssert.AreNotEqual(SalesLine."Reserved Quantity", 0, 'Order line is reserved');
    end;

    [Test]
    procedure UnitTestImportShopifyOrderHighRisk()
    var
        Shop: Record "Shpfy Shop";
        OrderHeader: Record "Shpfy Order Header";
        OrdersToImport: Record "Shpfy Orders to Import";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        ImportOrder: Codeunit "Shpfy Import Order";
        OrderHandlingHelper: Codeunit "Shpfy Order Handling Helper";
        RiskLevel: Enum "Shpfy Risk Level";
        JShopifyOrder: JsonObject;
        JShopifyLineItems: JsonArray;
    begin
        // [SCENARIO] Import a high risk Shopify order from the "Shpfy Orders to Import" record
        Initialize();

        // [GIVEN] Shopify Shop
        Shop := CommunicationMgt.GetShopRecord();
        Shop."Customer Mapping Type" := "Shpfy Customer Mapping"::"By EMail/Phone";
        if not Shop.Modify() then
            Shop.Insert();
        ImportOrder.SetShop(Shop.Code);

        // [GIVEN] the order to import as a json structure.
        JShopifyOrder := OrderHandlingHelper.CreateShopifyOrderAsJson(Shop, OrdersToImport, JShopifyLineItems, false);

        // [WHEN] ShpfyImportOrder.ImportOrder
        OrderHandlingHelper.ImportShopifyOrder(Shop, OrderHeader, OrdersToImport, ImportOrder, JShopifyOrder, JShopifyLineItems);
        CreateOrderRisk(OrderHeader."Shopify Order Id", RiskLevel::High);

        // [THEN] Order is high risk
        OrderHeader.CalcFields("High Risk");
        LibraryAssert.IsTrue(OrderHeader."High Risk", 'Order is high risk');
    end;

    [Test]
    procedure UnitTestImportShopifyOrderLowRisk()
    var
        Shop: Record "Shpfy Shop";
        OrderHeader: Record "Shpfy Order Header";
        OrdersToImport: Record "Shpfy Orders to Import";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        ImportOrder: Codeunit "Shpfy Import Order";
        OrderHandlingHelper: Codeunit "Shpfy Order Handling Helper";
        RiskLevel: Enum "Shpfy Risk Level";
        JShopifyOrder: JsonObject;
        JShopifyLineItems: JsonArray;
    begin
        // [SCENARIO] Import a low risk Shopify order from the "Shpfy Orders to Import" record
        Initialize();

        // [GIVEN] Shopify Shop
        Shop := CommunicationMgt.GetShopRecord();
        Shop."Customer Mapping Type" := "Shpfy Customer Mapping"::"By EMail/Phone";
        if not Shop.Modify() then
            Shop.Insert();
        ImportOrder.SetShop(Shop.Code);

        // [GIVEN] the order to import as a json structure.
        JShopifyOrder := OrderHandlingHelper.CreateShopifyOrderAsJson(Shop, OrdersToImport, JShopifyLineItems, false);

        // [WHEN] ShpfyImportOrder.ImportOrder
        OrderHandlingHelper.ImportShopifyOrder(Shop, OrderHeader, OrdersToImport, ImportOrder, JShopifyOrder, JShopifyLineItems);
        CreateOrderRisk(OrderHeader."Shopify Order Id", RiskLevel::Low);

        // [THEN] Order is high risk
        OrderHeader.CalcFields("High Risk");
        LibraryAssert.IsFalse(OrderHeader."High Risk", 'Order is not high risk');
    end;

    [Test]
    procedure UnitTestExtractShopifyOrdersToImportHighRisk()
    var
        Shop: Record "Shpfy Shop";
        OrdersToImport: Record "Shpfy Orders to Import";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        OrderHandlingHelper: Codeunit "Shpfy Order Handling Helper";
        OrdersAPI: Codeunit "Shpfy Orders API";
        Cursor: Text;
        JOrdersToImport: JsonObject;
        JOrder: JsonToken;
        JOrders: JsonArray;
        JAssessments: JsonArray;
        JAssessment: JsonToken;
    begin
        // [SCENARIO] Create a random expected Json structure for the OrdersToImport with high risk
        Initialize();
        Clear(OrdersToImport);
        if not OrdersToImport.IsEmpty then
            OrdersToImport.DeleteAll();

        // [GIVEN] Shopify Shop
        Shop := CommunicationMgt.GetShopRecord();
        // [GIVEN] the orders to import as a json structure.
        JOrdersToImport := OrderHandlingHelper.GetOrdersToImport(false);
        JOrdersToImport.GetObject('data').GetObject('orders').GetArray('edges').Get(0, JOrder);
        JAssessments := JOrder.AsObject().GetObject('node').GetObject('risk').GetArray('assessments');
        foreach JAssessment in JAssessments do
            JAssessment.AsObject().Replace('riskLevel', 'HIGH');
        JOrders.Add(JOrder);
        JOrdersToImport.GetObject('data').GetObject('orders').Replace('edges', JOrders);

        // [WHEN] Execute ShpfyOrdersAPI.ExtractShopifyOrdersToImport
        OrdersAPI.ExtractShopifyOrdersToImport(Shop, JOrdersToImport, Cursor);

        // [THEN] Order is high risk
        OrdersToImport.FindLast();
        LibraryAssert.IsTrue(OrdersToImport."High Risk", 'Order is high risk');
    end;

    [Test]
    procedure UnitTestExtractShopifyOrdersToImportLowRisk()
    var
        Shop: Record "Shpfy Shop";
        OrdersToImport: Record "Shpfy Orders to Import";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        OrderHandlingHelper: Codeunit "Shpfy Order Handling Helper";
        OrdersAPI: Codeunit "Shpfy Orders API";
        Cursor: Text;
        JOrdersToImport: JsonObject;
        JOrder: JsonToken;
        JOrders: JsonArray;
        JAssessments: JsonArray;
        JAssessment: JsonToken;
    begin
        // [SCENARIO] Create a random expected Json structure for the OrdersToImport with low risk
        Initialize();
        Clear(OrdersToImport);
        if not OrdersToImport.IsEmpty then
            OrdersToImport.DeleteAll();

        // [GIVEN] Shopify Shop
        Shop := CommunicationMgt.GetShopRecord();
        // [GIVEN] the orders to import as a json structure.
        JOrdersToImport := OrderHandlingHelper.GetOrdersToImport(false);
        JOrdersToImport.GetObject('data').GetObject('orders').GetArray('edges').Get(0, JOrder);
        JAssessments := JOrder.AsObject().GetObject('node').GetObject('risk').GetArray('assessments');
        foreach JAssessment in JAssessments do
            JAssessment.AsObject().Replace('riskLevel', 'LOW');
        JOrders.Add(JOrder);
        JOrdersToImport.GetObject('data').GetObject('orders').Replace('edges', JOrders);

        // [WHEN] Execute ShpfyOrdersAPI.ExtractShopifyOrdersToImport
        OrdersAPI.ExtractShopifyOrdersToImport(Shop, JOrdersToImport, Cursor);

        // [THEN] Order is high risk
        OrdersToImport.FindLast();
        LibraryAssert.IsFalse(OrdersToImport."High Risk", 'Order is not high risk');
    end;

    [Test]
    procedure UnitTestImportShopifyOrderDueDate()
    var
        Shop: Record "Shpfy Shop";
        OrderHeader: Record "Shpfy Order Header";
        OrdersToImport: Record "Shpfy Orders to Import";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        ImportOrder: Codeunit "Shpfy Import Order";
        OrderHandlingHelper: Codeunit "Shpfy Order Handling Helper";
        JShopifyOrder: JsonObject;
        JShopifyLineItems: JsonArray;
        DueDate: Date;
        DueDateTime: DateTime;
        TempTime: Text;
    begin
        // [SCENARIO] Import Shopify order from the "Shpfy Orders to Import" record with due date
        Initialize();

        // [GIVEN] Shopify Shop
        Shop := CommunicationMgt.GetShopRecord();
        Shop."Customer Mapping Type" := "Shpfy Customer Mapping"::"By EMail/Phone";
        if not Shop.Modify() then
            Shop.Insert();
        ImportOrder.SetShop(Shop.Code);

        // [GIVEN] Order to import as a json structure with payment terms
        JShopifyOrder := OrderHandlingHelper.CreateShopifyOrderAsJson(Shop, OrdersToImport, JShopifyLineItems, false);
        DueDate := LibraryRandom.RandDate(10);
        JShopifyOrder.Replace('paymentTerms', OrderHandlingHelper.CreatePaymentTermsAsJson(CreateDateTime(DueDate, 120000T)));

        // [WHEN] ShpfyImportOrder.ImportOrder
        OrderHandlingHelper.ImportShopifyOrder(Shop, OrderHeader, OrdersToImport, ImportOrder, JShopifyOrder, JShopifyLineItems);

        // [THEN] Due date is set
        TempTime := Format(CreateDateTime(DueDate, 120000T), 0, 9);
        Evaluate(DueDateTime, TempTime);
        LibraryAssert.AreEqual(OrderHeader."Due Date", DT2Date(DueDateTime), 'Due date is set');
    end;

    [Test]
    procedure UnitTestCreateSalesDocumentWithPresentmentCurrency()
    var
        Shop: Record "Shpfy Shop";
        OrderHeader: Record "Shpfy Order Header";
        SalesHeader: Record "Sales Header";
        ShopifyCustomer: Record "Shpfy Customer";
        Item: Record Item;
        SalesLine: Record "Sales Line";
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        ProcessOrders: Codeunit "Shpfy Process Orders";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        LibraryERM: Codeunit "Library - ERM";
        Amount: Decimal;
        PresentmentAmount: Decimal;
        PresentmentCurrencyCode: Code[10];
    begin
        // [SCENARIO] For shop with currency handling set to "Presentment Currency", the sales document is created with the presentment currency
        Initialize();

        // [GIVEN] Shop with currency handling set to "Presentment Currency"
        Shop := CommunicationMgt.GetShopRecord();
        Shop."Currency Handling" := Shop."Currency Handling"::"Presentment Currency";
        Shop.Modify(false);
        // [GIVEN] Presentment currency
        PresentmentCurrencyCode := LibraryERM.CreateCurrencyWithRounding();
        // [GIVEN] Amount and Presentment amount
        Amount := LibraryRandom.RandDec(999, 2);
        Currency.Get(PresentmentCurrencyCode);
        PresentmentAmount := Round(CurrencyExchangeRate.ExchangeAmtLCYToFCY(
                WorkDate(),
                PresentmentCurrencyCode,
                Amount,
                CurrencyExchangeRate.ExchangeRate(WorkDate(), PresentmentCurrencyCode)),
            Currency."Amount Rounding Precision");
        // [GIVEN] Customer
        CreateShopifyCustomer(Shop, ShopifyCustomer);
        // [GIVEN] Item
        CreateItem(Item, Amount);
        // [GIVEN] Shopify order
        CreatePresentmentShopifyOrder(
            Shop,
            OrderHeader,
            ShopifyCustomer,
            Item,
            Amount,
            PresentmentAmount,
            PresentmentCurrencyCode);

        Commit(); // Commit to make ProcessShopifyOrder Codeunit.Run() execution work

        // [WHEN] Order is processed
        ProcessOrders.ProcessShopifyOrder(OrderHeader);

        // [THEN] Sales document is created from Shopify order and order line is reserved
        SalesHeader.SetRange("Shpfy Order Id", OrderHeader."Shopify Order Id");
        LibraryAssert.IsTrue(SalesHeader.FindLast(), 'Sales document is created from Shopify order');
        LibraryAssert.AreEqual(SalesHeader."Currency Code", PresentmentCurrencyCode, 'Sales document is created with presentment currency');
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("No.", Item."No.");
        SalesLine.FindFirst();
        LibraryAssert.AreEqual(PresentmentAmount, SalesLine.Amount, 'Sales line amount should match presentment amount');
        // [THEN] Restore Shop currency handling
        Shop."Currency Handling" := Shop."Currency Handling"::"Shop Currency";
        Shop.Modify(false);
    end;

    [Test]
    procedure UnitTestImportShopifyOrderAndCreateSalesDocumentDueDate()
    var
        Shop: Record "Shpfy Shop";
        OrderHeader: Record "Shpfy Order Header";
        SalesHeader: Record "Sales Header";
        OrdersToImport: Record "Shpfy Orders to Import";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        ImportOrder: Codeunit "Shpfy Import Order";
        ProcessOrders: Codeunit "Shpfy Process Orders";
        OrderHandlingHelper: Codeunit "Shpfy Order Handling Helper";
        DueDate: Date;
        JShopifyOrder: JsonObject;
        JShopifyLineItems: JsonArray;
        TempTime: Text;
        DueDateTime: DateTime;
    begin
        // [SCENARIO] Creating a random Shopify Order and try to map customer and product data.
        // [SCENARIO] When the sales document is created, everything will be mapped and the sales document must exist.
        Initialize();

        // [GIVEN] Shopify Shop
        Shop := CommunicationMgt.GetShopRecord();
        Shop."Customer Mapping Type" := "Shpfy Customer Mapping"::"By EMail/Phone";
        if not Shop.Modify() then
            Shop.Insert();
        ImportOrder.SetShop(Shop.Code);

        // [GIVEN] ShpfyImportOrder.ImportOrder
        JShopifyOrder := OrderHandlingHelper.CreateShopifyOrderAsJson(Shop, OrdersToImport, JShopifyLineItems, false);
        DueDate := LibraryRandom.RandDate(10);
        JShopifyOrder.Replace('paymentTerms', OrderHandlingHelper.CreatePaymentTermsAsJson(CreateDateTime(DueDate, 120000T)));
        OrderHandlingHelper.ImportShopifyOrder(Shop, OrderHeader, OrdersToImport, ImportOrder, JShopifyOrder, JShopifyLineItems);
        Commit();

        // [WHEN] Order is processed
        ProcessOrders.ProcessShopifyOrder(OrderHeader);
        OrderHeader.GetBySystemId(OrderHeader.SystemId);

        // [THEN] Sales document is created from Shopify order with due date
        SalesHeader.SetRange("Shpfy Order Id", OrderHeader."Shopify Order Id");
        LibraryAssert.IsTrue(SalesHeader.FindLast(), 'Sales document is created from Shopify order');
        TempTime := Format(CreateDateTime(DueDate, 120000T), 0, 9);
        Evaluate(DueDateTime, TempTime);
        LibraryAssert.AreEqual(SalesHeader."Due Date", DT2Date(DueDateTime), 'Due date is set');
    end;

    [Test]
    procedure UnitTestImportFulfilledShopifyOrderAndCreateSalesDocument()
    var
        Shop: Record "Shpfy Shop";
        OrderHeader: Record "Shpfy Order Header";
        SalesHeader: Record "Sales Header";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        ImportOrder: Codeunit "Shpfy Import Order";
        ProcessOrders: Codeunit "Shpfy Process Orders";
        OrderHandlingHelper: Codeunit "Shpfy Order Handling Helper";
    begin
        // [SCENARIO] Creating a random fulfilled Shopify Order and try to map customer and product data.
        // [SCENARIO] When the sales document is created, everything will be mapped and the sales document must exist.
        Initialize();

        // [GIVEN] Shopify Shop
        Shop := CommunicationMgt.GetShopRecord();
        Shop."Customer Mapping Type" := "Shpfy Customer Mapping"::"By EMail/Phone";
        Shop."Create Invoices From Orders" := false;
        if not Shop.Modify() then
            Shop.Insert();
        ImportOrder.SetShop(Shop.Code);

        // [GIVEN] ShpfyImportOrder.ImportOrder
        OrderHandlingHelper.ImportShopifyOrder(Shop, OrderHeader, ImportOrder, false);
        Commit();

        // [WHEN] Order is processed
        ProcessOrders.ProcessShopifyOrder(OrderHeader);
        OrderHeader.GetBySystemId(OrderHeader.SystemId);

        // [THEN] Sales document is created from Shopify order
        SalesHeader.SetRange("Shpfy Order Id", OrderHeader."Shopify Order Id");
        LibraryAssert.IsTrue(SalesHeader.FindLast(), 'Sales document is created from Shopify order');
        LibraryAssert.AreEqual(SalesHeader."Document Type", SalesHeader."Document Type"::Order, 'Sales document is a sales order');
        LibraryAssert.AreEqual(OrderHeader."Sales Order No.", SalesHeader."No.", 'ShpfyOrderHeader."Sales Order No." = SalesHeader."No."');
    end;

    [Test]
    procedure ChannelLiableFlagMissingDefaultsToFalseOnOrdersToImport()
    var
        Shop: Record "Shpfy Shop";
        OrdersToImport: Record "Shpfy Orders to Import";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        OrdersAPI: Codeunit "Shpfy Orders API";
        OrderHandlingHelper: Codeunit "Shpfy Order Handling Helper";
        Cursor: Text;
        JOrdersToImport: JsonObject;
        ExpectedChannelLiable: Boolean;
        ScenarioName: Text;
        ChannelLiableScenario: Option Missing,TrueValue,FalseValue,NullValue;
    begin
        // [GIVEN] Shopify shop context and an orders-to-import payload missing taxLines.
        Initialize();
        Clear(OrdersToImport);
        if not OrdersToImport.IsEmpty then
            OrdersToImport.DeleteAll();

        Shop := CommunicationMgt.GetShopRecord();
        JOrdersToImport := OrderHandlingHelper.GetOrdersToImport(false);
        PrepareOrdersToImportChannelLiableScenario(ChannelLiableScenario::Missing, JOrdersToImport, ExpectedChannelLiable, ScenarioName);

        // [WHEN] Orders are extracted from Shopify.
        OrdersAPI.ExtractShopifyOrdersToImport(Shop, JOrdersToImport, Cursor);

        // [THEN] Channel Liable flag on the staging record defaults to false.
        OrdersToImport.Reset();
        LibraryAssert.IsTrue(OrdersToImport.FindLast(), 'Orders to import record is created');
        LibraryAssert.AreEqual(ExpectedChannelLiable, OrdersToImport."Channel Liable Taxes", StrSubstNo(OrdersToImportChannelLiableMismatchTxt, ScenarioName));
    end;

    [Test]
    procedure ChannelLiableFlagTrueIsStoredOnOrdersToImport()
    var
        Shop: Record "Shpfy Shop";
        OrdersToImport: Record "Shpfy Orders to Import";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        OrdersAPI: Codeunit "Shpfy Orders API";
        OrderHandlingHelper: Codeunit "Shpfy Order Handling Helper";
        Cursor: Text;
        JOrdersToImport: JsonObject;
        ExpectedChannelLiable: Boolean;
        ScenarioName: Text;
        ChannelLiableScenario: Option Missing,TrueValue,FalseValue,NullValue;
    begin
        // [GIVEN] Shopify shop context and an orders-to-import payload with channelLiable set to true.
        Initialize();
        Clear(OrdersToImport);
        if not OrdersToImport.IsEmpty then
            OrdersToImport.DeleteAll();

        Shop := CommunicationMgt.GetShopRecord();
        JOrdersToImport := OrderHandlingHelper.GetOrdersToImport(false);
        PrepareOrdersToImportChannelLiableScenario(ChannelLiableScenario::TrueValue, JOrdersToImport, ExpectedChannelLiable, ScenarioName);

        // [WHEN] Orders are extracted from Shopify.
        OrdersAPI.ExtractShopifyOrdersToImport(Shop, JOrdersToImport, Cursor);

        // [THEN] Channel Liable flag on the staging record is true.
        OrdersToImport.Reset();
        LibraryAssert.IsTrue(OrdersToImport.FindLast(), 'Orders to import record is created');
        LibraryAssert.AreEqual(ExpectedChannelLiable, OrdersToImport."Channel Liable Taxes", StrSubstNo(OrdersToImportChannelLiableMismatchTxt, ScenarioName));
    end;

    [Test]
    procedure ChannelLiableFlagFalseIsStoredOnOrdersToImport()
    var
        Shop: Record "Shpfy Shop";
        OrdersToImport: Record "Shpfy Orders to Import";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        OrdersAPI: Codeunit "Shpfy Orders API";
        OrderHandlingHelper: Codeunit "Shpfy Order Handling Helper";
        Cursor: Text;
        JOrdersToImport: JsonObject;
        ExpectedChannelLiable: Boolean;
        ScenarioName: Text;
        ChannelLiableScenario: Option Missing,TrueValue,FalseValue,NullValue;
    begin
        // [GIVEN] Shopify shop context and an orders-to-import payload with channelLiable set to false.
        Initialize();
        Clear(OrdersToImport);
        if not OrdersToImport.IsEmpty then
            OrdersToImport.DeleteAll();

        Shop := CommunicationMgt.GetShopRecord();
        JOrdersToImport := OrderHandlingHelper.GetOrdersToImport(false);
        PrepareOrdersToImportChannelLiableScenario(ChannelLiableScenario::FalseValue, JOrdersToImport, ExpectedChannelLiable, ScenarioName);

        // [WHEN] Orders are extracted from Shopify.
        OrdersAPI.ExtractShopifyOrdersToImport(Shop, JOrdersToImport, Cursor);

        // [THEN] Channel Liable flag on the staging record is false.
        OrdersToImport.Reset();
        LibraryAssert.IsTrue(OrdersToImport.FindLast(), 'Orders to import record is created');
        LibraryAssert.AreEqual(ExpectedChannelLiable, OrdersToImport."Channel Liable Taxes", StrSubstNo(OrdersToImportChannelLiableMismatchTxt, ScenarioName));
    end;

    [Test]
    procedure ChannelLiableFlagNullDefaultsToFalseOnOrdersToImport()
    var
        Shop: Record "Shpfy Shop";
        OrdersToImport: Record "Shpfy Orders to Import";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        OrdersAPI: Codeunit "Shpfy Orders API";
        OrderHandlingHelper: Codeunit "Shpfy Order Handling Helper";
        Cursor: Text;
        JOrdersToImport: JsonObject;
        ExpectedChannelLiable: Boolean;
        ScenarioName: Text;
        ChannelLiableScenario: Option Missing,TrueValue,FalseValue,NullValue;
    begin
        // [GIVEN] Shopify shop context and an orders-to-import payload with channelLiable provided as null.
        Initialize();
        Clear(OrdersToImport);
        if not OrdersToImport.IsEmpty then
            OrdersToImport.DeleteAll();

        Shop := CommunicationMgt.GetShopRecord();
        JOrdersToImport := OrderHandlingHelper.GetOrdersToImport(false);
        PrepareOrdersToImportChannelLiableScenario(ChannelLiableScenario::NullValue, JOrdersToImport, ExpectedChannelLiable, ScenarioName);

        // [WHEN] Orders are extracted from Shopify.
        OrdersAPI.ExtractShopifyOrdersToImport(Shop, JOrdersToImport, Cursor);

        // [THEN] Channel Liable flag on the staging record defaults to false.
        OrdersToImport.Reset();
        LibraryAssert.IsTrue(OrdersToImport.FindLast(), 'Orders to import record is created');
        LibraryAssert.AreEqual(ExpectedChannelLiable, OrdersToImport."Channel Liable Taxes", StrSubstNo(OrdersToImportChannelLiableMismatchTxt, ScenarioName));
    end;

    [Test]
    procedure ChannelLiableFlagMissingDefaultsToFalse()
    var
        Shop: Record "Shpfy Shop";
        OrderHeader: Record "Shpfy Order Header";
        OrdersToImport: Record "Shpfy Orders to Import";
        OrderTaxLine: Record "Shpfy Order Tax Line";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        ImportOrder: Codeunit "Shpfy Import Order";
        OrderHandlingHelper: Codeunit "Shpfy Order Handling Helper";
        JOrder: JsonObject;
        JLineItems: JsonArray;
        ExpectedChannelLiable: Boolean;
        ScenarioName: Text;
        OrderTaxLineFound: Boolean;
    begin
        // [GIVEN] Shopify shop context and an order JSON with the taxLines array removed.
        Initialize();

        Shop := CommunicationMgt.GetShopRecord();
        ImportOrder.SetShop(Shop.Code);

        JOrder := OrderHandlingHelper.CreateShopifyOrderAsJson(Shop, OrdersToImport, JLineItems, false);

        JOrder.Remove('taxLines');

        ExpectedChannelLiable := false;
        ScenarioName := 'missing taxLines';

        // [WHEN] Order is imported

        OrderHandlingHelper.ImportShopifyOrder(Shop, OrderHeader, OrdersToImport, ImportOrder, JOrder, JLineItems);

        // [THEN] Channel Liable in tax line and order header is set properly
        OrderTaxLine.Reset();
        OrderTaxLine.SetRange("Parent Id", OrderHeader."Shopify Order Id");

        OrderTaxLineFound := not OrderTaxLine.IsEmpty();
        LibraryAssert.IsFalse(OrderTaxLineFound, 'Order-level tax lines should not be created when taxLines array is missing.');

        OrderHeader.CalcFields("Channel Liable Taxes");
        LibraryAssert.AreEqual(ExpectedChannelLiable, OrderHeader."Channel Liable Taxes", StrSubstNo(OrderHeaderChannelLiableMismatchTxt, ScenarioName));
    end;

    [Test]
    procedure ChannelLiableFlagTrueIsImported()
    var
        Shop: Record "Shpfy Shop";
        OrderHeader: Record "Shpfy Order Header";
        OrdersToImport: Record "Shpfy Orders to Import";
        OrderTaxLine: Record "Shpfy Order Tax Line";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        ImportOrder: Codeunit "Shpfy Import Order";
        OrderHandlingHelper: Codeunit "Shpfy Order Handling Helper";
        JOrder: JsonObject;
        JLineItems: JsonArray;
        ExpectedHasRecord: Boolean;
        ExpectedChannelLiable: Boolean;
        ScenarioName: Text;
        OrderTaxLineFound: Boolean;
        ChannelLiableScenario: Option Missing,TrueValue,FalseValue,NullValue;
    begin
        // [GIVEN] Shopify shop context and an order JSON with channelLiable explicitly set to true.
        Initialize();

        Shop := CommunicationMgt.GetShopRecord();
        ImportOrder.SetShop(Shop.Code);

        JOrder := OrderHandlingHelper.CreateShopifyOrderAsJson(Shop, OrdersToImport, JLineItems, false);

        JOrder.Remove('taxLines');

        PrepareChannelLiableWithTaxLines(ChannelLiableScenario::TrueValue, JOrder, ExpectedHasRecord, ExpectedChannelLiable, ScenarioName);

        // [WHEN] Order is imported
        OrderHandlingHelper.ImportShopifyOrder(Shop, OrderHeader, OrdersToImport, ImportOrder, JOrder, JLineItems);

        // [THEN] Channel Liable in tax line and order header is set properly
        OrderTaxLine.Reset();
        OrderTaxLine.SetRange("Parent Id", OrderHeader."Shopify Order Id");

        OrderTaxLineFound := OrderTaxLine.FindFirst();
        if ExpectedHasRecord then begin
            LibraryAssert.IsTrue(OrderTaxLineFound, StrSubstNo(OrderLevelTaxLineExpectedTxt, ScenarioName));
            if OrderTaxLineFound then
                LibraryAssert.AreEqual(ExpectedChannelLiable, OrderTaxLine."Channel Liable", StrSubstNo(ChannelLiableFlagMismatchTxt, ScenarioName));
        end else
            LibraryAssert.IsFalse(OrderTaxLineFound, 'Order-level tax lines should not be created when taxLines array is missing.');

        OrderHeader.CalcFields("Channel Liable Taxes");
        LibraryAssert.AreEqual(ExpectedChannelLiable, OrderHeader."Channel Liable Taxes", StrSubstNo(OrderHeaderChannelLiableMismatchTxt, ScenarioName));
    end;

    [Test]
    procedure ChannelLiableFlagFalseIsImported()
    var
        Shop: Record "Shpfy Shop";
        OrderHeader: Record "Shpfy Order Header";
        OrdersToImport: Record "Shpfy Orders to Import";
        OrderTaxLine: Record "Shpfy Order Tax Line";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        ImportOrder: Codeunit "Shpfy Import Order";
        OrderHandlingHelper: Codeunit "Shpfy Order Handling Helper";
        JOrder: JsonObject;
        JLineItems: JsonArray;
        ExpectedHasRecord: Boolean;
        ExpectedChannelLiable: Boolean;
        ScenarioName: Text;
        OrderTaxLineFound: Boolean;
        ChannelLiableScenario: Option Missing,TrueValue,FalseValue,NullValue;
    begin
        // [GIVEN] Shopify shop context and an order JSON with channelLiable explicitly set to false.
        Initialize();

        Shop := CommunicationMgt.GetShopRecord();
        ImportOrder.SetShop(Shop.Code);

        JOrder := OrderHandlingHelper.CreateShopifyOrderAsJson(Shop, OrdersToImport, JLineItems, false);

        JOrder.Remove('taxLines');

        PrepareChannelLiableWithTaxLines(ChannelLiableScenario::FalseValue, JOrder, ExpectedHasRecord, ExpectedChannelLiable, ScenarioName);

        // [WHEN] Order is imported
        OrderHandlingHelper.ImportShopifyOrder(Shop, OrderHeader, OrdersToImport, ImportOrder, JOrder, JLineItems);

        // [THEN] Channel Liable in tax line and order header is set properly
        OrderTaxLine.Reset();
        OrderTaxLine.SetRange("Parent Id", OrderHeader."Shopify Order Id");

        OrderTaxLineFound := OrderTaxLine.FindFirst();
        if ExpectedHasRecord then begin
            LibraryAssert.IsTrue(OrderTaxLineFound, StrSubstNo(OrderLevelTaxLineExpectedTxt, ScenarioName));
            if OrderTaxLineFound then
                LibraryAssert.AreEqual(ExpectedChannelLiable, OrderTaxLine."Channel Liable", StrSubstNo(ChannelLiableFlagMismatchTxt, ScenarioName));
        end else
            LibraryAssert.IsFalse(OrderTaxLineFound, 'Order-level tax lines should not be created when taxLines array is missing.');

        OrderHeader.CalcFields("Channel Liable Taxes");
        LibraryAssert.AreEqual(ExpectedChannelLiable, OrderHeader."Channel Liable Taxes", StrSubstNo(OrderHeaderChannelLiableMismatchTxt, ScenarioName));
    end;

    [Test]
    procedure ChannelLiableFlagNullDefaultsToFalse()
    var
        Shop: Record "Shpfy Shop";
        OrderHeader: Record "Shpfy Order Header";
        OrdersToImport: Record "Shpfy Orders to Import";
        OrderTaxLine: Record "Shpfy Order Tax Line";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        ImportOrder: Codeunit "Shpfy Import Order";
        OrderHandlingHelper: Codeunit "Shpfy Order Handling Helper";
        JOrder: JsonObject;
        JLineItems: JsonArray;
        ExpectedHasRecord: Boolean;
        ExpectedChannelLiable: Boolean;
        ScenarioName: Text;
        OrderTaxLineFound: Boolean;
        ChannelLiableScenario: Option Missing,TrueValue,FalseValue,NullValue;
    begin
        // [GIVEN] Shopify shop context and an order JSON with channelLiable provided as null.
        Initialize();

        Shop := CommunicationMgt.GetShopRecord();
        ImportOrder.SetShop(Shop.Code);

        JOrder := OrderHandlingHelper.CreateShopifyOrderAsJson(Shop, OrdersToImport, JLineItems, false);

        JOrder.Remove('taxLines');

        PrepareChannelLiableWithTaxLines(ChannelLiableScenario::NullValue, JOrder, ExpectedHasRecord, ExpectedChannelLiable, ScenarioName);

        // [WHEN] Order is imported
        OrderHandlingHelper.ImportShopifyOrder(Shop, OrderHeader, OrdersToImport, ImportOrder, JOrder, JLineItems);

        // [THEN] Channel Liable in tax line and order header is set properly
        OrderTaxLine.Reset();
        OrderTaxLine.SetRange("Parent Id", OrderHeader."Shopify Order Id");

        OrderTaxLineFound := OrderTaxLine.FindFirst();
        if ExpectedHasRecord then begin
            LibraryAssert.IsTrue(OrderTaxLineFound, StrSubstNo(OrderLevelTaxLineExpectedTxt, ScenarioName));
            if OrderTaxLineFound then
                LibraryAssert.AreEqual(ExpectedChannelLiable, OrderTaxLine."Channel Liable", StrSubstNo(ChannelLiableFlagMismatchTxt, ScenarioName));
        end else
            LibraryAssert.IsFalse(OrderTaxLineFound, 'Order-level tax lines should not be created when taxLines array is missing.');

        OrderHeader.CalcFields("Channel Liable Taxes");
        LibraryAssert.AreEqual(ExpectedChannelLiable, OrderHeader."Channel Liable Taxes", StrSubstNo(OrderHeaderChannelLiableMismatchTxt, ScenarioName));
    end;

    local procedure CreateTaxArea(var TaxArea: Record "Tax Area"; var ShopifyTaxArea: Record "Shpfy Tax Area"; Shop: Record "Shpfy Shop")
    var
        ShopifyCustomerTemplate: Record "Shpfy Customer Template";
        CountryRegion: Record "Country/Region";
        CountryRegionCode: Code[20];
        CountyCode: Code[2];
        County: Text[30];
    begin
        CountryRegion.FindFirst();
        CountryRegionCode := CountryRegion.Code;
        Evaluate(CountyCode, Any.AlphabeticText(MaxStrLen(CountyCode)));
        County := CopyStr(Any.AlphabeticText(MaxStrLen(County)), 1, MaxStrLen(County));
        ShopifyCustomerTemplate."Shop Code" := Shop.Code;
        ShopifyCustomerTemplate."Country/Region Code" := CountryRegionCode;
        if ShopifyCustomerTemplate.Insert() then;
        ShopifyTaxArea."Country/Region Code" := CountryRegionCode;
        ShopifyTaxArea."County Code" := CountyCode;
        ShopifyTaxArea.County := County;
        ShopifyTaxArea."Tax Area Code" := CountyCode;
        if ShopifyTaxArea.Insert() then;
        TaxArea.Code := CountyCode;
        if TaxArea.Insert() then;
    end;

    local procedure CreateOrderRisk(ShopifyOrderId: BigInteger; RiskLevel: Enum "Shpfy Risk Level")
    var
        OrderRisk: Record "Shpfy Order Risk";
        LineNo: Integer;
    begin
        if OrderRisk.FindLast() then
            LineNo := OrderRisk."Line No." + 1
        else
            LineNo := 1;

        Clear(OrderRisk);
        OrderRisk."Order Id" := ShopifyOrderId;
        OrderRisk."Line No." := LineNo;
        OrderRisk.Level := RiskLevel;
        OrderRisk.Insert();
    end;

    local procedure CreateItem(var Item: Record Item; Amount: Decimal)
    var
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", Amount);
        Item.Validate("Last Direct Cost", Amount);
        Item.Modify(true);
    end;

    local procedure CreatePresentmentShopifyOrder(
        Shop: Record "Shpfy Shop";
        var OrderHeader: Record "Shpfy Order Header";
        ShopifyCustomer: Record "Shpfy Customer";
        Item: Record Item;
        Amount: Decimal;
        PresentmentAmount: Decimal;
        PresentmentCurrencyCode: Code[10])
    var
        OrderLine: Record "Shpfy Order Line";
        ShopifyVariant: Record "Shpfy Variant";
    begin
        OrderHeader."Customer Id" := ShopifyCustomer.Id;
        OrderHeader."Shop Code" := Shop.Code;
        OrderHeader."Presentment Currency Code" := PresentmentCurrencyCode;
        OrderHeader."Presentment Total Amount" := PresentmentAmount;
        OrderHeader."Total Amount" := Amount;

        OrderHeader."Shopify Order Id" := LibraryRandom.RandIntInRange(100000, 999999);
        OrderHeader.Insert(false);

        ShopifyVariant."Item SystemId" := Item.SystemId;
        ShopifyVariant.Id := LibraryRandom.RandIntInRange(100000, 999999);
        ShopifyVariant."Shop Code" := Shop.Code;
        ShopifyVariant.Insert(false);
        OrderLine."Shopify Order Id" := OrderHeader."Shopify Order Id";
        OrderLine."Shopify Variant Id" := ShopifyVariant.Id;
        OrderLine."Unit Price" := Amount;
        OrderLine."Presentment Unit Price" := PresentmentAmount;
        OrderLine.Quantity := 1;
        OrderLine.Insert(false);
    end;

    local procedure CreateShopifyCustomer(Shop: Record "Shpfy Shop"; var ShopifyCustomer: Record "Shpfy Customer")
    var
        Customer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateCustomer(Customer);
        ShopifyCustomer.Id := LibraryRandom.RandIntInRange(100000, 999999);
        ShopifyCustomer."Customer SystemId" := Customer.SystemId;
        ShopifyCustomer."Shop Id" := Shop."Shop Id";
        ShopifyCustomer.Insert(false);
    end;

    local procedure Initialize()
    begin
        Codeunit.Run(Codeunit::"Shpfy Initialize Test");
        if BindSubscription(OrdersAPISubscriber) then;
    end;

    local procedure PrepareOrdersToImportChannelLiableScenario(ChannelLiableScenario: Option Missing,TrueValue,FalseValue,NullValue; var JOrdersToImport: JsonObject; var ExpectedChannelLiable: Boolean; var ScenarioName: Text)
    var
        JOrder: JsonToken;
        JOrders: JsonArray;
        JNode: JsonObject;
        JTaxLines: JsonArray;
        JTaxLine: JsonObject;
        JNull: JsonValue;
    begin
        JOrdersToImport.GetObject('data').GetObject('orders').GetArray('edges').Get(0, JOrder);
        JNode := JOrder.AsObject().GetObject('node');

        if JNode.Contains('taxLines') then
            JNode.Remove('taxLines');

        Clear(JTaxLine);
        Clear(JTaxLines);

        case ChannelLiableScenario of
            ChannelLiableScenario::Missing:
                begin
                    ExpectedChannelLiable := false;
                    ScenarioName := 'missing taxLines';
                end;
            ChannelLiableScenario::TrueValue:
                begin
                    JTaxLine.Add('channelLiable', true);
                    JTaxLines.Add(JTaxLine);
                    JNode.Add('taxLines', JTaxLines);

                    ScenarioName := Format(ChannelLiableScenario);
                    ExpectedChannelLiable := true;
                end;
            ChannelLiableScenario::FalseValue:
                begin
                    JTaxLine.Add('channelLiable', false);
                    JTaxLines.Add(JTaxLine);
                    JNode.Add('taxLines', JTaxLines);

                    ScenarioName := Format(ChannelLiableScenario);
                    ExpectedChannelLiable := false;
                end;
            ChannelLiableScenario::NullValue:
                begin
                    JNull.SetValueToNull();
                    JTaxLine.Add('channelLiable', JNull);
                    JTaxLines.Add(JTaxLine);
                    JNode.Add('taxLines', JTaxLines);

                    ScenarioName := Format(ChannelLiableScenario);
                    ExpectedChannelLiable := false;
                end;
        end;

        Clear(JOrders);
        JOrders.Add(JOrder);
        JOrdersToImport.GetObject('data').GetObject('orders').Replace('edges', JOrders);
    end;

    local procedure PrepareChannelLiableWithTaxLines(ChannelLiableScenario: Option Missing,TrueValue,FalseValue,NullValue; var JOrder: JsonObject; var ExpectedHasRecord: Boolean; var ExpectedChannelLiable: Boolean; var ScenarioName: Text)
    var
        JTaxLines: JsonArray;
        JTaxLine: JsonObject;
        JPriceSet: JsonObject;
        JShopMoney: JsonObject;
        JPresentmentMoney: JsonObject;
        JNull: JsonValue;
    begin
        ExpectedHasRecord := true;
        ScenarioName := Format(ChannelLiableScenario);

        Clear(JTaxLine);
        Clear(JTaxLines);
        Clear(JPriceSet);
        Clear(JShopMoney);
        Clear(JPresentmentMoney);

        JTaxLine.Add('title', 'VAT');
        JTaxLine.Add('rate', 0.10);
        JTaxLine.Add('ratePercentage', 10);

        JShopMoney.Add('amount', '10');
        JPriceSet.Add('shopMoney', JShopMoney);

        JPresentmentMoney.Add('amount', '10');
        JPriceSet.Add('presentmentMoney', JPresentmentMoney);

        JTaxLine.Add('priceSet', JPriceSet);

        case ChannelLiableScenario of
            ChannelLiableScenario::TrueValue:
                begin
                    JTaxLine.Add('channelLiable', true);
                    ExpectedChannelLiable := true;
                end;
            ChannelLiableScenario::FalseValue:
                begin
                    JTaxLine.Add('channelLiable', false);
                    ExpectedChannelLiable := false;
                end;
            ChannelLiableScenario::NullValue:
                begin
                    JNull.SetValueToNull();
                    JTaxLine.Add('channelLiable', JNull);
                    ExpectedChannelLiable := false;
                end;
        end;

        JTaxLines.Add(JTaxLine);
        JOrder.Add('taxLines', JTaxLines);
    end;
}
