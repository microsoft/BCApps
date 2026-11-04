// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Finance.Currency;
using Microsoft.Finance.SalesTax;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.NoSeries;
using Microsoft.Integration.Shopify;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.Setup;
using System.TestLibraries.Utilities;
using System.Threading;

codeunit 139608 "Shpfy Orders API Test"
{
    Subtype = Test;
    TestType = Uncategorized;
    TestPermissions = Disabled;
    TestHttpRequestPolicy = BlockOutboundRequests;
    EventSubscriberInstance = Manual;

    var
        Shop: Record "Shpfy Shop";
        LibraryAssert: Codeunit "Library Assert";
        LibraryRandom: Codeunit "Library - Random";
        InitializeTest: Codeunit "Shpfy Initialize Test";
        HttpResponses: Codeunit "Library - Variable Storage";
        ShpfyOrdersAPITest: Codeunit "Shpfy Orders API Test";
        Any: Codeunit Any;
        CompanyLocationId: BigInteger;
        IsInitialized: Boolean;
        PlanRefreshExpected: Boolean;
        PlanRefreshCallCount: Integer;
        OrdersToImportChannelLiableMismatchTxt: Label 'Orders to import Channel Liable Taxes mismatch when %1.', Locked = true;
        OrderLevelTaxLineExpectedTxt: Label 'An order-level tax line should exist when %1.', Locked = true;
        ChannelLiableFlagMismatchTxt: Label 'Channel Liable flag mismatch when %1.', Locked = true;
        OrderHeaderChannelLiableMismatchTxt: Label 'Order header Channel Liable Taxes mismatch when %1.', Locked = true;
        DowngradedPlanShopResponseTok: Label '{"data":{"shop":{"name":"Test","plan":{"publicDisplayName":"Basic Shopify","partnerDevelopment":false,"shopifyPlus":false},"weightUnit":"KILOGRAMS"}},"extensions":{"cost":{"requestedQueryCost":1,"actualQueryCost":1,"throttleStatus":{"maximumAvailable":2000.0,"currentlyAvailable":1999,"restoreRate":100.0}}}}', Locked = true;

    [Test]
    procedure UnitTestExtractShopifyOrdersToImport()
    var
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
    [HandlerFunctions('OrdersAPIHttpHandler')]
    procedure UnitTestImportShopifyOrder()
    var
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
    [HandlerFunctions('OrdersAPIHttpHandler')]
    procedure UnitTestImportShopifyOrderStoresRetailLocation()
    var
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
    [HandlerFunctions('OrdersAPIHttpHandler')]
    procedure UnitTestImportB2BShopifyOrder()
    var
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
    [HandlerFunctions('OrdersAPIHttpHandler')]
    procedure UnitTestDoMappingsOnAShopifyOrder()
    var
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
    [HandlerFunctions('OrdersAPIHttpHandler')]
    procedure UnitTestDoMappingsOnAB2BShopifyOrder()
    var
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
    [HandlerFunctions('OrdersAPIHttpHandler')]
    procedure UnitTestDoMappingsOnAB2BShopifyOrderImportLocation()
    var
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
        CompanyLocationId := OrderHeader."Company Location Id";

        // [GIVEN] Register Expected Outbound API Requests.


        // [WHEN] ShpfyOrderMapping.DoMapping(ShpfyOrderHeader)
        OrderMapping.DoMapping(OrderHeader);

        // [THEN] Company Location must be mapped correctly
        CompanyLocation.Get(OrderHeader."Company Location Id");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure Completeness_AllApplicableGapsAndFallback()
    var
        TempCases: Record "Shpfy Order Header" temporary;
        ActualIssues: Dictionary of [BigInteger, Text];
        ExpectedIssues: Dictionary of [BigInteger, Text];
        MappingResults: Dictionary of [BigInteger, Boolean];
    begin
        // [SCENARIO] Mapping collects every unresolved customer, item and required account gap after applying existing fallback rules.
        // Resolved values are excluded, each unmapped ordinary or exchange item retains its Shopify line identity,
        // and mapping succeeds only when no required value remains missing.
        this.Initialize();

        // [GIVEN] Five cases cover customer fallback, inapplicable accounts and combined gaps exceeding the persisted error capacity.
        this.PrepareCompletenessCases(TempCases, ExpectedIssues);

        // [WHEN] Mapping runs for each prepared order.
        this.CollectCompletenessResults(TempCases, ActualIssues, MappingResults);

        // [THEN] The collected issues and persisted customer mappings match the expected outcomes.
        this.VerifyCompletenessCases(TempCases, ExpectedIssues, ActualIssues, MappingResults);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure Completeness_ExecutionPathsAndErrorOwnership()
    var
        Cases: Dictionary of [Text, BigInteger];
        Outcomes: JsonArray;
    begin
        // [SCENARIO] Find Mappings updates and clears only mapping-owned errors, leaving unrelated errors untouched.
        // Correcting only the customers retains the error flag and the remaining item and account diagnostics until all mappings are complete.
        this.Initialize();

        // [GIVEN] Two incomplete orders with a mapping-owned error and an unrelated active error.
        this.PrepareMappingEntryPaths(Cases);

        // [WHEN] Find Mappings runs before correction, after customer correction and after complete correction.
        this.ExerciseMappingEntryPaths(Cases, Outcomes);

        // [THEN] Only the mapping-owned error is updated and cleared; neither order has a sales document.
        this.VerifyMappingOutcomes(Outcomes, 5);
    end;

    [Test]
    [HandlerFunctions('OrdersAPIHttpHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure Completeness_AutomaticUpdateFailurePersistsMappingError()
    var
        ImportLines: JsonArray;
        ImportOrder: JsonObject;
        OrderId: BigInteger;
    begin
        // [SCENARIO] Importing an existing order as Update persists all unresolved mapping details even when automatic document creation is enabled.
        // The order remains unprocessed, no sales document or document link is created, and the import queue entry is removed.
        this.Initialize();

        // [GIVEN] An incomplete order staged for Update in a shop with automatic order creation enabled.
        OrderId := this.PrepareAutomaticUpdateOrder(ImportOrder, ImportLines);

        // [WHEN] The synchronization report imports the updated order and checks its mappings.
        this.RunMappingImport();

        // [THEN] The timestamped mapping error and error flag are persisted without processing the order or creating a document.
        this.VerifyAutomaticUpdateError(OrderId, this.ExpectedMappingDetails(OrderId, true), true, false, false);
    end;

    [Test]
    [HandlerFunctions('OrdersAPIHttpHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure Completeness_AutomaticUpdateRecoveryClearsMappingError()
    var
        ImportLines: JsonArray;
        ImportOrder: JsonObject;
        OrderId: BigInteger;
    begin
        // [SCENARIO] A successful automatic Update removes only the mapping-owned diagnostic left by a previous incomplete import.
        this.Initialize();

        // [GIVEN] An incomplete automatic Update has persisted its mapping error.
        OrderId := this.PrepareAutomaticUpdateOrder(ImportOrder, ImportLines);
        this.RunMappingImport();

        // [WHEN] The mappings are corrected and the order is automatically imported as Update again.
        this.CorrectMappingOrder(OrderId);
        this.RunMappingUpdate(OrderId, ImportOrder, ImportLines);

        // [THEN] The successful mapping clears its owned error without processing or creating a document for an Update import.
        this.VerifyAutomaticUpdateError(OrderId, '', false, false, false);
    end;

    [Test]
    [HandlerFunctions('OrdersAPIHttpHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure Completeness_AutomaticUpdatePreservesOrderStateError()
    var
        ImportLines: JsonArray;
        ImportOrder: JsonObject;
        MappingConflictLbl: Label 'Processed-order conflict. Preserve the entire original diagnostic.';
        OrderId: BigInteger;
    begin
        // [SCENARIO] Updating an already processed order with incomplete mappings must not replace an active order-state conflict.
        // Both error flags and the original conflict message remain unchanged, and no sales order or invoice number is assigned.
        this.Initialize();

        // [GIVEN] An imported order marked processed with an active order-state conflict and unresolved mappings.
        OrderId := this.PrepareProcessedOrderStateError(ImportOrder, ImportLines);

        // [WHEN] The same order is staged as Update and imported again.
        this.RunMappingUpdate(OrderId, ImportOrder, ImportLines);

        // [THEN] Mapping failure preserves the original conflict and both flags without assigning document numbers.
        this.VerifyAutomaticUpdateError(OrderId, MappingConflictLbl, false, true, true);
    end;

    [Test]
    [HandlerFunctions('OrdersAPIHttpHandler,MappingConfirmHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure Completeness_RetryAfterMappingCorrection()
    var
        JobQueueEntry: Record "Job Queue Entry";
        ImportLines: JsonArray;
        ImportOrder: JsonObject;
        OrderId: BigInteger;
        Outcomes: JsonArray;
    begin
        // [SCENARIO] Repeated scheduled, manual and batch attempts remain retryable while mappings are incomplete.
        // Each failure leaves the order unprocessed without a document; correcting the mappings allows one document to be created.
        // Further processing does not create duplicates.
        this.Initialize();

        // [GIVEN] An incomplete staged order and a job queue report entry with mocked Shopify responses.
        OrderId := this.PrepareMappingRetry(JobQueueEntry, ImportOrder, ImportLines);

        // [WHEN] Scheduled report, manual and batch processing repeat before and after mapping correction.
        this.ExerciseMappingRetries(OrderId, JobQueueEntry, ImportOrder, ImportLines, Outcomes);

        // [THEN] Incomplete attempts retain their mapping error, and corrected attempts create one document without duplicates.
        this.VerifyMappingOutcomes(Outcomes, 8);
    end;

    [Test]
    [HandlerFunctions('OrdersAPIHttpHandler')]
    procedure UnitTestImportShopifyOrderAndCreateSalesDocument()
    var
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
    [HandlerFunctions('OrdersAPIHttpHandler')]
    procedure UnitTestImportB2BShopifyOrderAndCreateSalesDocument()
    var
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
    [HandlerFunctions('OrdersAPIHttpHandler')]
    procedure UnitTestCreateSalesDocumentTaxPriorityCode()
    var
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
    [HandlerFunctions('OrdersAPIHttpHandler')]
    procedure UnitTestCreateSalesDocumentTaxPriorityName()
    var
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
    [HandlerFunctions('OrdersAPIHttpHandler')]
    procedure UnitTestCreateSalesDocumentTaxPriorityEmpty()
    var
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
    [HandlerFunctions('OrdersAPIHttpHandler')]
    procedure UnitTestCreateSalesDocumentTaxLiable()
    var
        OrderHeader: Record "Shpfy Order Header";
        SalesHeader: Record "Sales Header";
        TaxArea: Record "Tax Area";
        ShopifyTaxArea: Record "Shpfy Tax Area";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        ImportOrder: Codeunit "Shpfy Import Order";
        ProcessOrders: Codeunit "Shpfy Process Orders";
        OrderHandlingHelper: Codeunit "Shpfy Order Handling Helper";
    begin
        // [SCENARIO] Tax Liable from Shpfy Tax Area flows to the sales document
        Initialize();

        // [GIVEN] Shopify Shop
        Shop := CommunicationMgt.GetShopRecord();
        Shop."Tax Area Priority" := Shop."Tax Area Priority"::"Ship-to -> Sell-to -> Bill-to";
        Shop."County Source" := Shop."County Source"::"Code";
        if not Shop.Modify() then
            Shop.Insert();
        ImportOrder.SetShop(Shop.Code);

        // [GIVEN] Shopify Tax Area with Tax Liable = true
        CreateTaxArea(TaxArea, ShopifyTaxArea, Shop);

        // [GIVEN] Order imported and mapped
        OrderHandlingHelper.ImportShopifyOrder(Shop, OrderHeader, ImportOrder, false);
        OrderHeader."Ship-to City" := ShopifyTaxArea.County;
        OrderHeader."Ship-to Country/Region Code" := ShopifyTaxArea."Country/Region Code";
        OrderHeader."Ship-to County" := ShopifyTaxArea."County Code";
        OrderHeader.Modify();
        Commit();

        // [WHEN] Order is processed
        ProcessOrders.ProcessShopifyOrder(OrderHeader);
        OrderHeader.GetBySystemId(OrderHeader.SystemId);

        // [THEN] Sales document has Tax Area Code and Tax Liable
        SalesHeader.SetRange("Shpfy Order Id", OrderHeader."Shopify Order Id");
        LibraryAssert.IsTrue(SalesHeader.FindLast(), 'Sales document is created from Shopify order');
        LibraryAssert.AreEqual(SalesHeader."Tax Area Code", TaxArea.Code, 'Tax Area Code is set');
        LibraryAssert.IsTrue(SalesHeader."Tax Liable", 'Tax Liable must be true when Tax Area has Tax Liable');
    end;

    [Test]
    [HandlerFunctions('OrdersAPIHttpHandler')]
    procedure UnitTestCreateSalesDocumentTaxExempt()
    var
        OrderHeader: Record "Shpfy Order Header";
        SalesHeader: Record "Sales Header";
        TaxArea: Record "Tax Area";
        ShopifyTaxArea: Record "Shpfy Tax Area";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        ImportOrder: Codeunit "Shpfy Import Order";
        ProcessOrders: Codeunit "Shpfy Process Orders";
        OrderHandlingHelper: Codeunit "Shpfy Order Handling Helper";
    begin
        // [SCENARIO] Tax Exempt order gets Tax Area Code but Tax Liable stays false
        Initialize();

        // [GIVEN] Shopify Shop
        Shop := CommunicationMgt.GetShopRecord();
        Shop."Tax Area Priority" := Shop."Tax Area Priority"::"Ship-to -> Sell-to -> Bill-to";
        Shop."County Source" := Shop."County Source"::"Code";
        if not Shop.Modify() then
            Shop.Insert();
        ImportOrder.SetShop(Shop.Code);

        // [GIVEN] Shopify Tax Area with Tax Liable = true
        CreateTaxArea(TaxArea, ShopifyTaxArea, Shop);

        // [GIVEN] Order imported with Tax Exempt = true
        OrderHandlingHelper.ImportShopifyOrder(Shop, OrderHeader, ImportOrder, false);
        OrderHeader."Ship-to City" := ShopifyTaxArea.County;
        OrderHeader."Ship-to Country/Region Code" := ShopifyTaxArea."Country/Region Code";
        OrderHeader."Ship-to County" := ShopifyTaxArea."County Code";
        OrderHeader."Tax Exempt" := true;
        OrderHeader.Modify();
        Commit();

        // [WHEN] Order is processed
        ProcessOrders.ProcessShopifyOrder(OrderHeader);
        OrderHeader.GetBySystemId(OrderHeader.SystemId);

        // [THEN] Sales document has Tax Area Code but Tax Liable = false
        SalesHeader.SetRange("Shpfy Order Id", OrderHeader."Shopify Order Id");
        LibraryAssert.IsTrue(SalesHeader.FindLast(), 'Sales document is created from Shopify order');
        LibraryAssert.AreEqual(SalesHeader."Tax Area Code", TaxArea.Code, 'Tax Area Code is set even for tax exempt orders');
        LibraryAssert.IsFalse(SalesHeader."Tax Liable", 'Tax Liable must be false when order is Tax Exempt');
    end;

    [Test]
    [HandlerFunctions('OrdersAPIHttpHandler')]
    procedure UnitTestCreateSalesDocumentReserve()
    var
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
    [HandlerFunctions('OrdersAPIHttpHandler')]
    procedure UnitTestImportShopifyOrderHighRisk()
    var
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
    [HandlerFunctions('OrdersAPIHttpHandler')]
    procedure UnitTestImportShopifyOrderLowRisk()
    var
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
    [HandlerFunctions('OrdersAPIHttpHandler')]
    procedure UnitTestImportShopifyOrderDueDate()
    var
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
    [HandlerFunctions('OrdersAPIHttpHandler')]
    procedure UnitTestCreateSalesDocumentWithPresentmentCurrency()
    var
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

        // [THEN] Currency handling is stored on the processed order
        OrderHeader.Get(OrderHeader."Shopify Order Id");
        LibraryAssert.AreEqual(
            Enum::"Shpfy Currency Handling"::"Presentment Currency",
            OrderHeader."Processed Currency Handling",
            'Processed currency handling should match the shop setting');
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
    [HandlerFunctions('OrdersAPIHttpHandler')]
    procedure UnitTestImportShopifyOrderAndCreateSalesDocumentDueDate()
    var
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
    [HandlerFunctions('OrdersAPIHttpHandler')]
    procedure UnitTestImportFulfilledShopifyOrderAndCreateSalesDocument()
    var
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
    [HandlerFunctions('OrdersAPIHttpHandler')]
    procedure ChannelLiableFlagMissingDefaultsToFalse()
    var
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
    [HandlerFunctions('OrdersAPIHttpHandler')]
    procedure ChannelLiableFlagTrueIsImported()
    var
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
    [HandlerFunctions('OrdersAPIHttpHandler')]
    procedure ChannelLiableFlagFalseIsImported()
    var
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
    [HandlerFunctions('OrdersAPIHttpHandler')]
    procedure ChannelLiableFlagNullDefaultsToFalse()
    var
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

    [Test]
    [HandlerFunctions('OrdersAPIHttpHandler')]
    procedure UnitTestImportOrderPropagatesUseShopifyOrderNo()
    var
        OrderHeader: Record "Shpfy Order Header";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        ImportOrder: Codeunit "Shpfy Import Order";
        OrderHandlingHelper: Codeunit "Shpfy Order Handling Helper";
    begin
        // [SCENARIO] When Shop."Use Shopify Order No." is true, importing an order propagates the setting to OrderHeader.
        Initialize();

        // [GIVEN] Shopify Shop with "Use Shopify Order No." enabled
        Shop := CommunicationMgt.GetShopRecord();
        Shop."Customer Mapping Type" := "Shpfy Customer Mapping"::"By EMail/Phone";
        Shop."Use Shopify Order No." := true;
        if not Shop.Modify() then
            Shop.Insert();
        ImportOrder.SetShop(Shop.Code);

        // [WHEN] Shopify order is imported
        OrderHandlingHelper.ImportShopifyOrder(Shop, OrderHeader, ImportOrder, false);

        // [THEN] OrderHeader."Use Shopify Order No." = true
        LibraryAssert.IsTrue(OrderHeader."Use Shopify Order No.", 'OrderHeader."Use Shopify Order No." should be true when Shop setting is enabled');
    end;

    [Test]
    [HandlerFunctions('OrdersAPIHttpHandler')]
    procedure UnitTestImportOrderPropagatesUseShopifyOrderNoDisabled()
    var
        OrderHeader: Record "Shpfy Order Header";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        ImportOrder: Codeunit "Shpfy Import Order";
        OrderHandlingHelper: Codeunit "Shpfy Order Handling Helper";
    begin
        // [SCENARIO] When Shop."Use Shopify Order No." is false, importing an order propagates the setting to OrderHeader.
        Initialize();

        // [GIVEN] Shopify Shop with "Use Shopify Order No." disabled
        Shop := CommunicationMgt.GetShopRecord();
        Shop."Customer Mapping Type" := "Shpfy Customer Mapping"::"By EMail/Phone";
        Shop."Use Shopify Order No." := false;
        if not Shop.Modify() then
            Shop.Insert();
        ImportOrder.SetShop(Shop.Code);

        // [WHEN] Shopify order is imported
        OrderHandlingHelper.ImportShopifyOrder(Shop, OrderHeader, ImportOrder, false);

        // [THEN] OrderHeader."Use Shopify Order No." = false
        LibraryAssert.IsFalse(OrderHeader."Use Shopify Order No.", 'OrderHeader."Use Shopify Order No." should be false when Shop setting is disabled');
    end;

    [Test]
    [HandlerFunctions('OrdersAPIHttpHandler')]
    procedure UnitTestCreateSalesOrderWithShopifyOrderNo()
    var
        OrderHeader: Record "Shpfy Order Header";
        SalesHeader: Record "Sales Header";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        ImportOrder: Codeunit "Shpfy Import Order";
        ProcessOrders: Codeunit "Shpfy Process Orders";
        OrderHandlingHelper: Codeunit "Shpfy Order Handling Helper";
    begin
        // [SCENARIO] When "Use Shopify Order No." is enabled, the created Sales Order uses the Shopify order number as its document number.
        Initialize();

        // [GIVEN] Shopify Shop
        Shop := CommunicationMgt.GetShopRecord();
        Shop."Customer Mapping Type" := "Shpfy Customer Mapping"::"By EMail/Phone";
        if not Shop.Modify() then
            Shop.Insert();
        ImportOrder.SetShop(Shop.Code);

        // [GIVEN] Sales Order number series allows manual entry
        SetManualNosOnOrderNoSeries();

        // [GIVEN] Imported Shopify order with "Use Shopify Order No." enabled
        OrderHandlingHelper.ImportShopifyOrder(Shop, OrderHeader, ImportOrder, false);
        OrderHeader."Use Shopify Order No." := true;
        OrderHeader.Modify();
        Commit();

        // [WHEN] Order is processed
        ProcessOrders.ProcessShopifyOrder(OrderHeader);
        OrderHeader.GetBySystemId(OrderHeader.SystemId);

        // [THEN] Sales document is created with Shopify Order No. as document number
        SalesHeader.SetRange("Shpfy Order Id", OrderHeader."Shopify Order Id");
        LibraryAssert.IsTrue(SalesHeader.FindLast(), 'Sales document is created from Shopify order');
        LibraryAssert.AreEqual(OrderHeader."Shopify Order No.", SalesHeader."No.", 'Sales document number should equal Shopify Order No.');
    end;

    [Test]
    [HandlerFunctions('OrdersAPIHttpHandler')]
    procedure UnitTestCreateSalesOrderWithoutShopifyOrderNo()
    var
        OrderHeader: Record "Shpfy Order Header";
        SalesHeader: Record "Sales Header";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        ImportOrder: Codeunit "Shpfy Import Order";
        ProcessOrders: Codeunit "Shpfy Process Orders";
        OrderHandlingHelper: Codeunit "Shpfy Order Handling Helper";
    begin
        // [SCENARIO] When "Use Shopify Order No." is disabled, the created Sales Order uses the standard number series.
        Initialize();

        // [GIVEN] Shopify Shop
        Shop := CommunicationMgt.GetShopRecord();
        Shop."Customer Mapping Type" := "Shpfy Customer Mapping"::"By EMail/Phone";
        if not Shop.Modify() then
            Shop.Insert();
        ImportOrder.SetShop(Shop.Code);

        // [GIVEN] Imported Shopify order with "Use Shopify Order No." disabled
        OrderHandlingHelper.ImportShopifyOrder(Shop, OrderHeader, ImportOrder, false);
        OrderHeader."Use Shopify Order No." := false;
        OrderHeader.Modify();
        Commit();

        // [WHEN] Order is processed
        ProcessOrders.ProcessShopifyOrder(OrderHeader);
        OrderHeader.GetBySystemId(OrderHeader.SystemId);

        // [THEN] Sales document is created with a number from the number series, not the Shopify Order No.
        SalesHeader.SetRange("Shpfy Order Id", OrderHeader."Shopify Order Id");
        LibraryAssert.IsTrue(SalesHeader.FindLast(), 'Sales document is created from Shopify order');
        LibraryAssert.AreNotEqual(OrderHeader."Shopify Order No.", SalesHeader."No.", 'Sales document number should not equal Shopify Order No. when feature is disabled');
    end;

    [Test]
    [HandlerFunctions('OrdersAPIHttpHandler')]
    procedure UnitTestCreateSalesOrderWithShopifyOrderNoInvalidChar()
    var
        OrderHeader: Record "Shpfy Order Header";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        ImportOrder: Codeunit "Shpfy Import Order";
        ProcessOrders: Codeunit "Shpfy Process Orders";
        OrderHandlingHelper: Codeunit "Shpfy Order Handling Helper";
    begin
        // [SCENARIO] When "Use Shopify Order No." is enabled and the Shopify Order No. starts with "@", processing fails with an error.
        Initialize();

        // [GIVEN] Shopify Shop
        Shop := CommunicationMgt.GetShopRecord();
        Shop."Customer Mapping Type" := "Shpfy Customer Mapping"::"By EMail/Phone";
        if not Shop.Modify() then
            Shop.Insert();
        ImportOrder.SetShop(Shop.Code);

        // [GIVEN] Sales Order number series allows manual entry
        SetManualNosOnOrderNoSeries();

        // [GIVEN] Imported Shopify order with invalid Shopify Order No. starting with "@"
        OrderHandlingHelper.ImportShopifyOrder(Shop, OrderHeader, ImportOrder, false);
        OrderHeader."Use Shopify Order No." := true;
        OrderHeader."Shopify Order No." := '@INVALID123';
        OrderHeader.Modify();
        Commit();

        // [WHEN] Order is processed
        ProcessOrders.ProcessShopifyOrder(OrderHeader);
        OrderHeader.GetBySystemId(OrderHeader.SystemId);

        // [THEN] Order has an error because Shopify Order No. starts with "@"
        LibraryAssert.IsTrue(OrderHeader."Has Error", 'Order should have an error when Shopify Order No. starts with @');
        LibraryAssert.IsTrue(OrderHeader."Error Message".Contains('@'), 'Error message should mention the invalid character @');
    end;

    [Test]
    [HandlerFunctions('OrdersAPIHttpHandler')]
    procedure UnitTestCreateSalesInvoiceWithShopifyOrderNo()
    var
        OrderHeader: Record "Shpfy Order Header";
        SalesHeader: Record "Sales Header";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        ImportOrder: Codeunit "Shpfy Import Order";
        ProcessOrders: Codeunit "Shpfy Process Orders";
        OrderHandlingHelper: Codeunit "Shpfy Order Handling Helper";
    begin
        // [SCENARIO] When "Use Shopify Order No." is enabled and a fulfilled order creates an invoice, the Sales Invoice uses the Shopify order number.
        Initialize();

        // [GIVEN] Shopify Shop with "Create Invoices From Orders" enabled
        Shop := CommunicationMgt.GetShopRecord();
        Shop."Customer Mapping Type" := "Shpfy Customer Mapping"::"By EMail/Phone";
        Shop."Create Invoices From Orders" := true;
        if not Shop.Modify() then
            Shop.Insert();
        ImportOrder.SetShop(Shop.Code);

        // [GIVEN] Sales Invoice number series allows manual entry
        SetManualNosOnInvoiceNoSeries();

        // [GIVEN] Imported fulfilled Shopify order with "Use Shopify Order No." enabled
        OrderHandlingHelper.ImportShopifyOrder(Shop, OrderHeader, ImportOrder, false);
        OrderHeader."Use Shopify Order No." := true;
        OrderHeader."Fulfillment Status" := "Shpfy Order Fulfill. Status"::Fulfilled;
        OrderHeader.Modify();
        Commit();

        // [WHEN] Order is processed
        ProcessOrders.ProcessShopifyOrder(OrderHeader);
        OrderHeader.GetBySystemId(OrderHeader.SystemId);

        // [THEN] Sales Invoice is created with the Shopify Order No. as document number
        SalesHeader.SetRange("Shpfy Order Id", OrderHeader."Shopify Order Id");
        LibraryAssert.IsTrue(SalesHeader.FindLast(), 'Sales document is created from Shopify order');
        LibraryAssert.AreEqual(SalesHeader."Document Type", SalesHeader."Document Type"::Invoice, 'Sales document should be an Invoice for fulfilled orders');
        LibraryAssert.AreEqual(OrderHeader."Shopify Order No.", SalesHeader."No.", 'Sales Invoice number should equal Shopify Order No.');
    end;

    [Test]
    procedure UnitTestTipFlagNotPropagatedToSubsequentOrderLines()
    var
        OrderLine: Record "Shpfy Order Line";
        ImportOrder: Codeunit "Shpfy Import Order";
        JOrderLines: JsonArray;
        JEmptyArray: JsonArray;
        JTipLine: JsonObject;
        JRegularLine: JsonObject;
        JNull: JsonValue;
        GidLbl: Label 'gid://shopify/LineItem/%1', Locked = true, Comment = '%1 = Line Id';
        OrderId: BigInteger;
        TipLineId: BigInteger;
        RegularLineId: BigInteger;
    begin
        // [SCENARIO] When an order contains a Tip line followed by a regular line, the Tip flag must not carry over to the regular line.
        Initialize();

        OrderId := LibraryRandom.RandIntInRange(100000, 999999);
        TipLineId := LibraryRandom.RandIntInRange(10000, 49999);
        RegularLineId := LibraryRandom.RandIntInRange(50000, 99999);

        // [GIVEN] A Tip order line in JSON form
        JNull.SetValueToNull();
        JTipLine.Add('id', StrSubstNo(GidLbl, TipLineId));
        JTipLine.Add('name', 'Tip');
        JTipLine.Add('product', JNull);
        JTipLine.Add('discountAllocations', JEmptyArray);

        // [GIVEN] A regular order line in JSON form that follows the Tip line
        JRegularLine.Add('id', StrSubstNo(GidLbl, RegularLineId));
        JRegularLine.Add('name', 'Product');
        JRegularLine.Add('discountAllocations', JEmptyArray);

        JOrderLines.Add(JTipLine);
        JOrderLines.Add(JRegularLine);

        // [WHEN] Order lines are imported from the JSON array
        ImportOrder.ImportCreateAndUpdateOrderLinesFromMock(OrderId, JOrderLines);
        Commit();

        // [THEN] The Tip line has the Tip flag set to true
        LibraryAssert.IsTrue(OrderLine.Get(OrderId, TipLineId), 'Tip order line must exist');
        LibraryAssert.IsTrue(OrderLine.Tip, 'Tip flag must be set on the Tip order line');

        // [THEN] The regular line does not have the Tip flag carried over from the previous Tip line
        LibraryAssert.IsTrue(OrderLine.Get(OrderId, RegularLineId), 'Regular order line must exist');
        LibraryAssert.IsFalse(OrderLine.Tip, 'Tip flag must not be propagated to the subsequent regular order line');
    end;

    [Test]
    [HandlerFunctions('OrdersAPIHttpHandler')]
    procedure TestGetShopSettingsClearsStaleAdvancedShopifyPlanFlag()
    var
        LocalShop: Record "Shpfy Shop";
    begin
        // [SCENARIO] Bug 635878: when the merchant downgrades from a Plus/Advanced plan to a
        // standard plan, Shop.GetShopSettings() must clear the cached "Advanced Shopify Plan"
        // flag based on the live response from Shopify so the order GraphQL query stops
        // requesting the staffMember field (which would otherwise fail with ACCESS_DENIED).
        Initialize();

        // [GIVEN] Shop has a stale "Advanced Shopify Plan" flag set to true
        LocalShop.Get(Shop.Code);
        LocalShop."Advanced Shopify Plan" := true;
        LocalShop.Modify(false);

        // [GIVEN] The HTTP handler is primed to return a downgraded-plan response
        PlanRefreshExpected := true;

        // [WHEN] GetShopSettings is called
        LocalShop.GetShopSettings();

        // [THEN] The Advanced Shopify Plan flag is cleared based on the live response
        LibraryAssert.IsFalse(LocalShop."Advanced Shopify Plan", 'Stale Advanced Shopify Plan flag should be refreshed to false after plan downgrade.');
        LibraryAssert.AreEqual(1, PlanRefreshCallCount, 'GetShopSettings should issue exactly one plan-refresh query.');
    end;

    [Test]
    [HandlerFunctions('OrdersAPIHttpHandler')]
    procedure TestSyncOrdersFromShopifyReportRefreshesAdvancedShopifyPlanFlag()
    var
        ShopFilter: Record "Shpfy Shop";
        OrdersToImport: Record "Shpfy Orders to Import";
        SyncOrdersFromShopify: Report "Shpfy Sync Orders from Shopify";
    begin
        // [SCENARIO] Bug 635878: the bulk "Sync Orders from Shopify" report must refresh
        // the cached "Advanced Shopify Plan" flag before importing orders, so a plan
        // downgrade does not leave the connector requesting the staffMember field that
        // the new plan can no longer grant access to.
        Initialize();

        // [GIVEN] Shop has a stale "Advanced Shopify Plan" flag set to true
        Shop.Get(Shop.Code);
        Shop."Advanced Shopify Plan" := true;
        Shop."Auto Create Orders" := false;
        Shop.Modify(false);
        Commit();

        // [GIVEN] No orders are queued so the report only exercises the Shop dataitem trigger
        OrdersToImport.SetRange("Shop Code", Shop.Code);
        OrdersToImport.DeleteAll(false);

        // [GIVEN] The HTTP handler is primed to return a downgraded-plan response
        PlanRefreshExpected := true;

        // [WHEN] The "Sync Orders from Shopify" report runs against this shop
        ShopFilter.SetRange(Code, Shop.Code);
        SyncOrdersFromShopify.SetTableView(ShopFilter);
        SyncOrdersFromShopify.UseRequestPage(false);
        SyncOrdersFromShopify.Run();

        // [THEN] The Advanced Shopify Plan flag is refreshed on the persisted Shop record
        Shop.Get(Shop.Code);
        LibraryAssert.IsFalse(Shop."Advanced Shopify Plan", 'Bulk sync report should refresh Advanced Shopify Plan flag before importing orders.');
        LibraryAssert.AreEqual(1, PlanRefreshCallCount, 'Bulk sync report should issue exactly one plan-refresh query.');
    end;

    [Test]
    [HandlerFunctions('OrdersAPIHttpHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure TestAutoCreateOrderStoresCurrencyHandlingUsedForSalesDocument()
    var
        OrderHeader: Record "Shpfy Order Header";
        OrdersToImport: Record "Shpfy Orders to Import";
        SalesHeader: Record "Sales Header";
        ShopFilter: Record "Shpfy Shop";
        SyncOrdersFromShopify: Report "Shpfy Sync Orders from Shopify";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        OrderHandlingHelper: Codeunit "Shpfy Order Handling Helper";
        JShopifyOrder: JsonObject;
        JShopifyLineItems: JsonArray;
        EntryNo: Integer;
        OrderId: BigInteger;
    begin
        Initialize();

        Shop := CommunicationMgt.GetShopRecord();
        Shop."Auto Create Orders" := true;
        Shop."Currency Handling" := "Shpfy Currency Handling"::"Presentment Currency";
        Shop.Modify(false);

        JShopifyOrder := OrderHandlingHelper.CreateShopifyOrderAsJson(Shop, OrdersToImport, JShopifyLineItems, false);
        EntryNo := OrdersToImport."Entry No.";
        OrderId := OrdersToImport.Id;
        OrdersToImport.Reset();
        OrdersToImport.SetFilter("Entry No.", '<>%1', EntryNo);
        OrdersToImport.DeleteAll(false);
        EnqueueAutoCreateOrderResponses(JShopifyOrder, JShopifyLineItems);
        Commit();

        ShopFilter.SetRange(Code, Shop.Code);
        SyncOrdersFromShopify.SetTableView(ShopFilter);
        SyncOrdersFromShopify.UseRequestPage(false);
        BindSubscription(ShpfyOrdersAPITest);
        SyncOrdersFromShopify.Run();
        UnbindSubscription(ShpfyOrdersAPITest);
        HttpResponses.AssertEmpty();

        OrderHeader.Get(OrderId);
        LibraryAssert.IsTrue(OrderHeader.Processed, 'Shopify order should be processed automatically');
        LibraryAssert.AreEqual(
            Enum::"Shpfy Currency Handling"::"Shop Currency",
            OrderHeader."Processed Currency Handling",
            'Automatically processed order should store the currency handling used for the sales document');
        SalesHeader.SetRange("Shpfy Order Id", OrderId);
        LibraryAssert.IsTrue(SalesHeader.FindFirst(), 'Sales document should be created automatically');
        LibraryAssert.AreEqual(Shop."Currency Code", SalesHeader."Currency Code", 'Sales document should use the shop currency');

        Shop.Get(Shop.Code);
        Shop."Auto Create Orders" := false;
        Shop."Currency Handling" := "Shpfy Currency Handling"::"Shop Currency";
        Shop.Modify(false);
    end;

    local procedure PrepareCompletenessCases(var TempCases: Record "Shpfy Order Header" temporary; var ExpectedIssues: Dictionary of [BigInteger, Text])
    var
        Customer: Record Customer;
        CustomerTemplate: Record "Shpfy Customer Template";
        OrderHeader: Record "Shpfy Order Header";
        OrderLine: Record "Shpfy Order Line";
        Index: Integer;
        IssueText: Text;
        MappingBillToTok: Label 'BillToCustomer', Locked = true;
        MappingGiftCardTok: Label 'GiftCardAccount', Locked = true;
        MappingItemTok: Label 'ItemLine:%1', Locked = true, Comment = '%1 = Shopify line id';
        MappingSellToTok: Label 'SellToCustomer', Locked = true;
        MappingTipTok: Label 'TipAccount', Locked = true;
        OrderId: BigInteger;
    begin
        this.AddCompletenessCase(TempCases, ExpectedIssues, false, true, false, false);

        OrderId := this.AddCompletenessCase(TempCases, ExpectedIssues, false, false, false, false);
        OrderLine.SetRange("Shopify Order Id", OrderId);
        OrderLine.DeleteAll(false);
        OrderLine.Reset();
        this.Shop."Tip Account" := '';
        this.Shop."Sold Gift Card Account" := '';
        this.Shop.Modify(false);

        Customer := this.InitializeTest.GetDummyCustomer();
        OrderId := this.AddCompletenessCase(TempCases, ExpectedIssues, true, true, false, false);
        this.Shop."Default Customer No." := Customer."No.";
        this.Shop.Modify(false);
        ExpectedIssues.Set(OrderId, '');

        OrderId := this.AddCompletenessCase(TempCases, ExpectedIssues, true, true, false, false);
        OrderHeader.Get(OrderId);
        CustomerTemplate."Shop Code" := this.Shop.Code;
        CustomerTemplate."Country/Region Code" := OrderHeader."Ship-to Country/Region Code";
        CustomerTemplate."Default Customer No." := Customer."No.";
        CustomerTemplate.Insert(false);
        ExpectedIssues.Set(OrderId, '');

        OrderId := this.AddCompletenessCase(TempCases, ExpectedIssues, true, true, true, true);
        IssueText := MappingSellToTok + '|' + MappingBillToTok + '|';
        for Index := 1 to 160 do begin
            this.CreateUnmappedItemLine(OrderId, OrderId * 1000 + Index, Index = 160);
            IssueText += StrSubstNo(MappingItemTok, Format(OrderId * 1000 + Index, 0, 9)) + '|';
        end;
        OrderLine.Get(OrderId, OrderId * 10 + 3);
        OrderLine.Rename(OrderId, OrderId * 1000 + 161);
        OrderLine.Get(OrderId, OrderId * 10 + 4);
        OrderLine.Rename(OrderId, OrderId * 1000 + 162);
        OrderLine.Init();
        OrderLine."Shopify Order Id" := OrderId;
        OrderLine."Line Id" := OrderId * 1000 + 163;
        OrderLine.Tip := true;
        OrderLine.Insert(false);
        OrderLine.Init();
        OrderLine."Shopify Order Id" := OrderId;
        OrderLine."Line Id" := OrderId * 1000 + 164;
        OrderLine."Gift Card" := true;
        OrderLine.Insert(false);
        ExpectedIssues.Set(OrderId, IssueText + MappingTipTok + '|' + MappingGiftCardTok + '|');
    end;

    local procedure AddCompletenessCase(var TempCases: Record "Shpfy Order Header" temporary; var ExpectedIssues: Dictionary of [BigInteger, Text]; MissingSellTo: Boolean; MissingBillTo: Boolean; MissingTip: Boolean; MissingGiftCard: Boolean): BigInteger
    var
        Customer: Record Customer;
        OrderHeader: Record "Shpfy Order Header";
        IssueText: Text;
        MappingBillToTok: Label 'BillToCustomer', Locked = true;
        MappingGiftCardTok: Label 'GiftCardAccount', Locked = true;
        MappingSellToTok: Label 'SellToCustomer', Locked = true;
        MappingTipTok: Label 'TipAccount', Locked = true;
    begin
        this.Shop := this.CreateIncompleteMappingShop();
        this.Shop.Validate(Code, CopyStr(this.Any.AlphabeticText(20), 1, MaxStrLen(this.Shop.Code)));
        this.Shop.Insert(false);
        this.CreateIncompleteMappingOrder(OrderHeader);
        Customer := this.InitializeTest.GetDummyCustomer();
        if not MissingSellTo then
            OrderHeader."Sell-to Customer No." := Customer."No.";
        if not MissingBillTo then
            OrderHeader."Bill-to Customer No." := Customer."No.";
        OrderHeader.Modify(false);
        if MissingSellTo then
            IssueText += MappingSellToTok + '|';
        if MissingBillTo and MissingSellTo then
            IssueText += MappingBillToTok + '|';
        if MissingTip then
            IssueText += MappingTipTok + '|'
        else
            this.Shop."Tip Account" := this.Shop."Refund Account";
        if MissingGiftCard then
            IssueText += MappingGiftCardTok + '|'
        else
            this.Shop."Sold Gift Card Account" := this.Shop."Refund Account";
        this.Shop.Modify(false);

        TempCases := OrderHeader;
        TempCases.Insert();
        ExpectedIssues.Add(OrderHeader."Shopify Order Id", IssueText);
        exit(OrderHeader."Shopify Order Id");
    end;

    local procedure CollectCompletenessResults(var TempCases: Record "Shpfy Order Header" temporary; var ActualIssues: Dictionary of [BigInteger, Text]; var MappingResults: Dictionary of [BigInteger, Boolean])
    var
        OrderHeader: Record "Shpfy Order Header";
        OrderMapping: Codeunit "Shpfy Order Mapping";
        Actual: Text;
        Issue: Text;
        Issues: List of [Text];
    begin
        if TempCases.FindSet() then
            repeat
                OrderHeader.Get(TempCases."Shopify Order Id");
                MappingResults.Add(OrderHeader."Shopify Order Id", OrderMapping.DoMappingWithIssues(OrderHeader, Issues, "Shpfy Mapping Execution Mode"::Mapping));
                Actual := '';
                foreach Issue in Issues do
                    Actual += Issue + '|';
                ActualIssues.Add(OrderHeader."Shopify Order Id", Actual);
            until TempCases.Next() = 0;
    end;

    local procedure VerifyCompletenessCases(var TempCases: Record "Shpfy Order Header" temporary; ExpectedIssues: Dictionary of [BigInteger, Text]; ActualIssues: Dictionary of [BigInteger, Text]; MappingResults: Dictionary of [BigInteger, Boolean])
    var
        CustomerTemplate: Record "Shpfy Customer Template";
        OrderHeader: Record "Shpfy Order Header";
        OrderMapping: Codeunit "Shpfy Order Mapping";
        Actual: Text;
        Expected: Text;
        ExpectedItemIssue: Text;
        ExpectedStoredErrorBody: Text;
        Issue: Text;
        Issues: List of [Text];
        ItemErrorPosition: Integer;
        ItemLineId: Text;
        ItemLineIssuePrefixTok: Label 'ItemLine:', Locked = true;
        LongestResult: Integer;
        MappingCasesMismatchErr: Label 'Every prepared mapping case must be executed.';
        MappingCollectionSizeErr: Label 'The collected issue list must exceed the existing error capacity without dropping later issues.';
        MappingCustomerMismatchErr: Label 'Order %1 must retain the customer selected by the existing mapping rules.', Comment = '%1 = Shopify order id';
        MappingErrorContentErr: Label 'The stored mapping error must retain the first 2048 characters, including a partial final issue.';
        MappingErrorLengthErr: Label 'The stored mapping error must be truncated to the field capacity.';
        MappingErrorPosition: Integer;
        MappingIssuesMismatchErr: Label 'Order %1 must retain every unresolved issue in discovery order.', Comment = '%1 = Shopify order id';
        MappingItemIssueLbl: Label 'Item No. is missing on Shopify order line %1.', Comment = '%1 = Shopify order line ID';
        MappingItemTokenExposureErr: Label 'Internal item-line issue tokens must not be shown to the user.';
        MappingItemWordingErr: Label 'Item-line issues must be rendered with their Shopify line ID.';
        MappingPrefixTok: Label 'Not everything can be mapped.', Locked = true;
        MappingResultMismatchErr: Label 'Order %1 mapping result must agree with its unresolved issues.', Comment = '%1 = Shopify order id';
        OrderId: BigInteger;
        PreviousItemErrorPosition: Integer;
        RenderedError: Text;
        StoredErrorBody: Text;
    begin
        LongestResult := 0;
        this.LibraryAssert.AreEqual(5, TempCases.Count(), MappingCasesMismatchErr);
        this.LibraryAssert.AreEqual(TempCases.Count(), ExpectedIssues.Count(), MappingCasesMismatchErr);
        this.LibraryAssert.AreEqual(TempCases.Count(), ActualIssues.Count(), MappingCasesMismatchErr);
        this.LibraryAssert.AreEqual(TempCases.Count(), MappingResults.Count(), MappingCasesMismatchErr);
        if TempCases.FindSet() then
            repeat
                OrderId := TempCases."Shopify Order Id";
                OrderHeader.Get(OrderId);
                this.Shop.Get(OrderHeader."Shop Code");
                Actual := ActualIssues.Get(OrderId);
                Expected := ExpectedIssues.Get(OrderId);
                this.LibraryAssert.AreEqual(Expected, Actual, StrSubstNo(MappingIssuesMismatchErr, OrderId));
                this.LibraryAssert.AreEqual(Expected = '', MappingResults.Get(OrderId), StrSubstNo(MappingResultMismatchErr, OrderId));
                if StrLen(Actual) > LongestResult then
                    LongestResult := StrLen(Actual);
                if TempCases."Sell-to Customer No." <> '' then
                    this.LibraryAssert.AreEqual(TempCases."Sell-to Customer No.", OrderHeader."Sell-to Customer No.", StrSubstNo(MappingCustomerMismatchErr, OrderId));
                if TempCases."Bill-to Customer No." <> '' then
                    this.LibraryAssert.AreEqual(TempCases."Bill-to Customer No.", OrderHeader."Bill-to Customer No.", StrSubstNo(MappingCustomerMismatchErr, OrderId));
                if (TempCases."Bill-to Customer No." = '') and (TempCases."Sell-to Customer No." <> '') then
                    this.LibraryAssert.AreEqual(TempCases."Sell-to Customer No.", OrderHeader."Bill-to Customer No.", StrSubstNo(MappingCustomerMismatchErr, OrderId));
                if this.Shop."Default Customer No." <> '' then begin
                    this.LibraryAssert.AreEqual(this.Shop."Default Customer No.", OrderHeader."Sell-to Customer No.", StrSubstNo(MappingCustomerMismatchErr, OrderId));
                    this.LibraryAssert.AreEqual(this.Shop."Default Customer No.", OrderHeader."Bill-to Customer No.", StrSubstNo(MappingCustomerMismatchErr, OrderId));
                end;
                if CustomerTemplate.Get(this.Shop.Code, OrderHeader."Ship-to Country/Region Code") then begin
                    this.LibraryAssert.AreEqual(CustomerTemplate."Default Customer No.", OrderHeader."Sell-to Customer No.", StrSubstNo(MappingCustomerMismatchErr, OrderId));
                    this.LibraryAssert.AreEqual(CustomerTemplate."Default Customer No.", OrderHeader."Bill-to Customer No.", StrSubstNo(MappingCustomerMismatchErr, OrderId));
                end;
                Issues := Actual.Split('|');
                RenderedError := OrderMapping.GetMappingErrorMessage(Issues);
                PreviousItemErrorPosition := 0;
                foreach Issue in Issues do
                    if Issue.StartsWith(ItemLineIssuePrefixTok) then begin
                        ItemLineId := CopyStr(Issue, StrLen(ItemLineIssuePrefixTok) + 1);
                        ExpectedItemIssue := StrSubstNo(MappingItemIssueLbl, ItemLineId);
                        ItemErrorPosition := StrPos(RenderedError, ExpectedItemIssue);
                        this.LibraryAssert.IsTrue(ItemErrorPosition > PreviousItemErrorPosition, MappingItemWordingErr);
                        PreviousItemErrorPosition := ItemErrorPosition;
                    end;
                this.LibraryAssert.IsFalse(RenderedError.Contains(ItemLineIssuePrefixTok), MappingItemTokenExposureErr);
                if StrLen(RenderedError) > MaxStrLen(OrderHeader."Error Message") then begin
                    OrderMapping.SetMappingError(OrderHeader, Issues);
                    OrderHeader.Get(OrderId);
                    MappingErrorPosition := StrPos(OrderHeader."Error Message", MappingPrefixTok);
                    StoredErrorBody := CopyStr(OrderHeader."Error Message", MappingErrorPosition);
                    ExpectedStoredErrorBody := CopyStr(RenderedError, 1, MaxStrLen(OrderHeader."Error Message") - MappingErrorPosition + 1);
                    this.LibraryAssert.AreEqual(MaxStrLen(OrderHeader."Error Message"), StrLen(OrderHeader."Error Message"), MappingErrorLengthErr);
                    this.LibraryAssert.AreEqual(ExpectedStoredErrorBody, StoredErrorBody, MappingErrorContentErr);
                end;
            until TempCases.Next() = 0;
        this.LibraryAssert.IsTrue(LongestResult > MaxStrLen(OrderHeader."Error Message"), MappingCollectionSizeErr);
    end;

    local procedure PrepareMappingEntryPaths(var Cases: Dictionary of [Text, BigInteger])
    var
        OrderHeader: Record "Shpfy Order Header";
        CaseName: Text;
        CaseNames: List of [Text];
        MappingPrefixTok: Label 'Not everything can be mapped.', Locked = true;
        MappingUnrelatedLbl: Label 'Unrelated active error. Not everything can be mapped. Preserve the entire original diagnostic.';
    begin
        this.Shop := this.CreateIncompleteMappingShop();
        CaseNames.Add('Mapping');
        CaseNames.Add('Unrelated');
        foreach CaseName in CaseNames do begin
            this.Shop.Validate(Code, CopyStr(this.Any.AlphabeticText(20), 1, MaxStrLen(this.Shop.Code)));
            this.Shop.Insert(false);
            this.CreateIncompleteMappingOrder(OrderHeader);
            this.CreateUnmappedItemLine(OrderHeader."Shopify Order Id", OrderHeader."Shopify Order Id" * 10 + 1, false);
            this.CreateUnmappedItemLine(OrderHeader."Shopify Order Id", OrderHeader."Shopify Order Id" * 10 + 5, true);
            case CaseName of
                'Mapping':
                    this.SetOrderError(OrderHeader, MappingPrefixTok + ' ' + this.LibraryRandom.RandText(30));
                'Unrelated':
                    this.SetOrderError(OrderHeader, MappingUnrelatedLbl);
            end;
            Cases.Add(CaseName, OrderHeader."Shopify Order Id");
        end;
    end;

    local procedure ExerciseMappingEntryPaths(Cases: Dictionary of [Text, BigInteger]; var Outcomes: JsonArray)
    var
        Customer: Record Customer;
        OrderHeader: Record "Shpfy Order Header";
        CaseName: Text;
        ExpectedError: Text;
        MappingGiftCardDetailLbl: Label 'Sold Gift Card Account must have a value in Shopify Shop.';
        MappingItemMissingLbl: Label 'Item No. is missing on Shopify order line %1.', Comment = '%1 = Shopify order line ID';
        MappingPrefixTok: Label 'Not everything can be mapped.', Locked = true;
        MappingTipDetailLbl: Label 'Tip Account must have a value in Shopify Shop.';
        MappingUnrelatedLbl: Label 'Unrelated active error. Not everything can be mapped. Preserve the entire original diagnostic.';
        RemainingError: TextBuilder;
    begin
        foreach CaseName in Cases.Keys() do begin
            this.RunMappingPath(Cases.Get(CaseName), CaseName);
            ExpectedError := this.ExpectedMappingDetails(Cases.Get(CaseName), true);
            if CaseName = 'Unrelated' then
                ExpectedError := MappingUnrelatedLbl;
            this.CaptureMappingOutcome(Cases.Get(CaseName), ExpectedError, CaseName = 'Mapping', false, false, 0, Outcomes);
        end;

        OrderHeader.Get(Cases.Get('Mapping'));
        Customer := this.InitializeTest.GetDummyCustomer();
        OrderHeader."Sell-to Customer No." := Customer."No.";
        OrderHeader."Bill-to Customer No." := Customer."No.";
        OrderHeader.Modify(false);
        this.RunMappingPath(OrderHeader."Shopify Order Id", 'Mapping');
        RemainingError.AppendLine(MappingPrefixTok);
        RemainingError.AppendLine(StrSubstNo(MappingItemMissingLbl, Format(OrderHeader."Shopify Order Id" * 10 + 1, 0, 9)));
        RemainingError.AppendLine(MappingTipDetailLbl);
        RemainingError.AppendLine(MappingGiftCardDetailLbl);
        RemainingError.AppendLine(StrSubstNo(MappingItemMissingLbl, Format(OrderHeader."Shopify Order Id" * 10 + 5, 0, 9)));
        this.CaptureMappingOutcome(OrderHeader."Shopify Order Id", RemainingError.ToText(), true, false, false, 0, Outcomes);
        foreach CaseName in Cases.Keys() do begin
            this.CorrectMappingOrder(Cases.Get(CaseName));
            this.RunMappingPath(Cases.Get(CaseName), CaseName);
            ExpectedError := '';
            if CaseName = 'Unrelated' then
                ExpectedError := MappingUnrelatedLbl;
            this.CaptureMappingOutcome(Cases.Get(CaseName), ExpectedError, false, false, false, 0, Outcomes);
        end;
    end;

    local procedure RunMappingPath(OrderId: BigInteger; Path: Text)
    var
        OrderHeader: Record "Shpfy Order Header";
        ProcessOrders: Codeunit "Shpfy Process Orders";
        OrderPage: TestPage "Shpfy Order";
    begin
        OrderHeader.Get(OrderId);
        this.Shop.Get(OrderHeader."Shop Code");
        Commit();
        if Path = 'Batch' then begin
            OrderHeader.SetRange("Shop Code", this.Shop.Code);
            ProcessOrders.SetShop(this.Shop);
            ProcessOrders.ProcessShopifyOrders(OrderHeader);
        end else begin
            OrderPage.OpenEdit();
            OrderPage.GoToRecord(OrderHeader);
            if Path = 'Manual' then
                OrderPage.CreateSalesDocument.Invoke()
            else
                OrderPage.FindMappings.Invoke();
            OrderPage.Close();
        end;
    end;

    local procedure PrepareAutomaticUpdateOrder(var ImportOrder: JsonObject; var ImportLines: JsonArray): BigInteger
    var
        OrdersToImport: Record "Shpfy Orders to Import";
        MappingStagedOrderErr: Label 'The incomplete order must be staged before its import action can be updated.';
        OrderId: BigInteger;
    begin
        this.Shop := this.CreateIncompleteMappingShop();
        this.Shop.Modify(false);
        this.SetAutomaticOrderCreation(true);
        OrderId := this.PrepareIncompleteOrderImport(true, ImportOrder, ImportLines);
        OrdersToImport.SetRange("Shop Id", this.Shop."Shop Id");
        OrdersToImport.SetRange(Id, OrderId);
        this.LibraryAssert.IsTrue(OrdersToImport.FindFirst(), MappingStagedOrderErr);
        OrdersToImport."Import Action" := OrdersToImport."Import Action"::Update;
        OrdersToImport.Modify(false);
        exit(OrderId);
    end;

    local procedure VerifyAutomaticUpdateError(OrderId: BigInteger; ExpectedError: Text; Timestamped: Boolean; ExpectedOrderStateError: Boolean; ExpectedProcessed: Boolean)
    var
        Outcomes: JsonArray;
    begin
        this.CaptureMappingOutcome(OrderId, ExpectedError, Timestamped, ExpectedOrderStateError, ExpectedProcessed, 0, Outcomes);
        this.VerifyMappingOutcomes(Outcomes, 1);
    end;

    local procedure PrepareProcessedOrderStateError(var ImportOrder: JsonObject; var ImportLines: JsonArray) OrderId: BigInteger
    var
        OrderHeader: Record "Shpfy Order Header";
        MappingConflictLbl: Label 'Processed-order conflict. Preserve the entire original diagnostic.';
    begin
        this.Shop := this.CreateIncompleteMappingShop();
        this.Shop.Modify(false);
        this.SetAutomaticOrderCreation(true);
        OrderId := this.PrepareIncompleteOrderImport(true, ImportOrder, ImportLines);
        this.RunMappingImport();
        OrderHeader.Get(OrderId);
        OrderHeader.Processed := true;
        OrderHeader."Has Order State Error" := true;
        OrderHeader."Has Error" := true;
        OrderHeader."Error Message" := MappingConflictLbl;
        OrderHeader.Modify(false);
        exit(OrderId);
    end;

    local procedure RunMappingUpdate(OrderId: BigInteger; ImportOrder: JsonObject; ImportLines: JsonArray)
    var
        OrdersToImport: Record "Shpfy Orders to Import";
        MappingStagedOrderErr: Label 'The incomplete order must be staged before its import action can be updated.';
    begin
        this.RestageMappingOrder(OrderId, ImportOrder, ImportLines);
        OrdersToImport.SetRange("Shop Id", this.Shop."Shop Id");
        OrdersToImport.SetRange(Id, OrderId);
        this.LibraryAssert.IsTrue(OrdersToImport.FindFirst(), MappingStagedOrderErr);
        OrdersToImport."Import Action" := OrdersToImport."Import Action"::Update;
        OrdersToImport.Modify(false);
        this.RunMappingImport();
    end;

    local procedure CorrectMappingOrder(OrderId: BigInteger)
    var
        Customer: Record Customer;
        Item: Record Item;
        OrderHeader: Record "Shpfy Order Header";
        OrderLine: Record "Shpfy Order Line";
        Variant: Record "Shpfy Variant";
    begin
        Customer := this.InitializeTest.GetDummyCustomer();
        OrderHeader.Get(OrderId);
        OrderHeader."Sell-to Customer No." := Customer."No.";
        OrderHeader."Bill-to Customer No." := Customer."No.";
        OrderHeader."Sell-to Country/Region Code" := Customer."Country/Region Code";
        OrderHeader."Bill-to Country/Region Code" := Customer."Country/Region Code";
        OrderHeader."Ship-to Country/Region Code" := Customer."Country/Region Code";
        OrderHeader.Modify(false);
        this.Shop.Get(OrderHeader."Shop Code");
        this.Shop."Tip Account" := this.Shop."Refund Account";
        this.Shop."Sold Gift Card Account" := this.Shop."Refund Account";
        this.Shop."Auto Release Sales Orders" := false;
        this.Shop."Create Invoices From Orders" := false;
        this.Shop.Modify(false);
        Item := this.InitializeTest.GetDummyItem();
        OrderLine.SetRange("Shopify Order Id", OrderId);
        OrderLine.SetRange(Tip, false);
        OrderLine.SetRange("Gift Card", false);
        OrderLine.SetLoadFields("Shopify Variant Id");
        if OrderLine.FindSet() then
            repeat
                Variant.Get(OrderLine."Shopify Variant Id");
                Variant."Item SystemId" := Item.SystemId;
                Variant.Modify(false);
            until OrderLine.Next() = 0;
        Commit();
    end;

    local procedure ExpectedMappingDetails(OrderId: BigInteger; IncludeAccounts: Boolean): Text
    var
        Builder: TextBuilder;
        MappingBillToDetailLbl: Label 'Bill-to Customer No. is missing.';
        MappingGiftCardDetailLbl: Label 'Sold Gift Card Account must have a value in Shopify Shop.';
        MappingItemMissingLbl: Label 'Item No. is missing on Shopify order line %1.', Comment = '%1 = Shopify order line ID';
        MappingPrefixTok: Label 'Not everything can be mapped.', Locked = true;
        MappingSellToDetailLbl: Label 'Sell-to Customer No. is missing.';
        MappingTipDetailLbl: Label 'Tip Account must have a value in Shopify Shop.';
    begin
        Builder.AppendLine(MappingPrefixTok);
        Builder.AppendLine(MappingSellToDetailLbl);
        Builder.AppendLine(MappingBillToDetailLbl);
        Builder.AppendLine(StrSubstNo(MappingItemMissingLbl, Format(OrderId * 10 + 1, 0, 9)));
        if IncludeAccounts then begin
            Builder.AppendLine(MappingTipDetailLbl);
            Builder.AppendLine(MappingGiftCardDetailLbl);
        end;
        Builder.AppendLine(StrSubstNo(MappingItemMissingLbl, Format(OrderId * 10 + 5, 0, 9)));
        exit(Builder.ToText());
    end;

    local procedure ExpectedProcessingMappingDetails(OrderId: BigInteger; IncludeAccounts: Boolean): Text
    var
        LineBreak: Text[2];
    begin
        // GetLastErrorText preserves the runtime's backslash line separators.
        LineBreak := '  ';
        LineBreak[1] := 13;
        LineBreak[2] := 10;
        exit(this.ExpectedMappingDetails(OrderId, IncludeAccounts).Replace(LineBreak, '\'));
    end;

    local procedure CaptureMappingOutcome(OrderId: BigInteger; ExpectedError: Text; Timestamped: Boolean; ExpectedOrderStateError: Boolean; ExpectedProcessed: Boolean; ExpectedDocumentCount: Integer; var Outcomes: JsonArray)
    var
        DocumentLink: Record "Shpfy Doc. Link To Doc.";
        OrderHeader: Record "Shpfy Order Header";
        OrdersToImport: Record "Shpfy Orders to Import";
        SalesHeader: Record "Sales Header";
        Outcome: JsonObject;
    begin
        OrderHeader.SetLoadFields("Error Message", "Has Error", "Has Order State Error", Processed, "Sales Order No.", "Sales Invoice No.");
        OrderHeader.Get(OrderId);
        SalesHeader.SetRange("Shpfy Order Id", OrderId);
        DocumentLink.SetRange("Shopify Document Type", DocumentLink."Shopify Document Type"::"Shopify Shop Order");
        DocumentLink.SetRange("Shopify Document Id", OrderId);
        OrdersToImport.SetRange(Id, OrderId);
        Outcome.Add('orderId', OrderId);
        Outcome.Add('error', OrderHeader."Error Message");
        Outcome.Add('hasError', OrderHeader."Has Error");
        Outcome.Add('hasOrderStateError', OrderHeader."Has Order State Error");
        Outcome.Add('processed', OrderHeader.Processed);
        Outcome.Add('documents', SalesHeader.Count());
        Outcome.Add('links', DocumentLink.Count());
        Outcome.Add('staged', OrdersToImport.Count());
        Outcome.Add('salesOrderNo', OrderHeader."Sales Order No.");
        Outcome.Add('salesInvoiceNo', OrderHeader."Sales Invoice No.");
        Outcome.Add('expectedError', ExpectedError);
        Outcome.Add('timestamped', Timestamped);
        Outcome.Add('expectedOrderStateError', ExpectedOrderStateError);
        Outcome.Add('expectedProcessed', ExpectedProcessed);
        Outcome.Add('expectedDocuments', ExpectedDocumentCount);
        Outcomes.Add(Outcome);
    end;

    local procedure VerifyMappingOutcomes(Outcomes: JsonArray; ExpectedCount: Integer)
    var
        ActualError: Text;
        ErrorMessage: Text;
        ErrorTime: Time;
        ExpectedError: Text;
        MappingConflictPreservationErr: Label 'An active processed-order conflict must retain its order-state error flag.';
        MappingDocumentCountErr: Label 'An incomplete order must have no sales document; a corrected order must have exactly one.';
        MappingDocumentLinkErr: Label 'Failed processing must not leave sales document numbers or document links.';
        MappingErrorFlagErr: Label 'The persisted error flag must match the execution outcome.';
        MappingErrorMessageErr: Label 'Order %1 must retain the whole owned error. Expected: <%2>. Actual: <%3>.', Comment = '%1 = Shopify order id, %2 = expected error text, %3 = actual error text';
        MappingOutcomeCountErr: Label 'Every execution path and recovery attempt must be observed.';
        MappingProcessedErr: Label 'Only a successfully corrected order may be marked processed.';
        MappingRetryQueueErr: Label 'A successfully imported order must leave the staging queue even when mapping is incomplete.';
        MappingTimestampErr: Label 'The mapping error must start with a session-formatted time.';
        Outcome: JsonObject;
        OutcomeToken: JsonToken;
    begin
        this.HttpResponses.AssertEmpty();
        this.LibraryAssert.AreEqual(ExpectedCount, Outcomes.Count(), MappingOutcomeCountErr);
        foreach OutcomeToken in Outcomes do begin
            Outcome := OutcomeToken.AsObject();
            ExpectedError := Outcome.GetText('expectedError');
            ActualError := Outcome.GetText('error');
            ErrorMessage := StrSubstNo(MappingErrorMessageErr, Outcome.GetBigInteger('orderId'), ExpectedError, ActualError);
            this.LibraryAssert.AreEqual(ExpectedError <> '', Outcome.GetBoolean('hasError'), MappingErrorFlagErr + ' ' + ErrorMessage);
            this.LibraryAssert.AreEqual(Outcome.GetBoolean('expectedOrderStateError'), Outcome.GetBoolean('hasOrderStateError'), MappingConflictPreservationErr);
            if Outcome.GetBoolean('timestamped') then begin
                this.LibraryAssert.IsTrue(ActualError.EndsWith(ExpectedError), ErrorMessage);
                this.LibraryAssert.IsTrue(StrLen(ActualError) > StrLen(ExpectedError), ErrorMessage);
                this.LibraryAssert.IsTrue(Evaluate(ErrorTime, CopyStr(ActualError, 1, StrLen(ActualError) - StrLen(ExpectedError) - 1)), MappingTimestampErr);
                this.LibraryAssert.AreEqual(Format(ErrorTime), CopyStr(ActualError, 1, StrLen(ActualError) - StrLen(ExpectedError) - 1), MappingTimestampErr);
            end else
                this.LibraryAssert.AreEqual(ExpectedError, ActualError, ErrorMessage);
            this.LibraryAssert.AreEqual(Outcome.GetBoolean('expectedProcessed'), Outcome.GetBoolean('processed'), MappingProcessedErr);
            this.LibraryAssert.AreEqual(Outcome.GetInteger('expectedDocuments'), Outcome.GetInteger('documents'), MappingDocumentCountErr);
            this.LibraryAssert.AreEqual(Outcome.GetInteger('expectedDocuments'), Outcome.GetInteger('links'), MappingDocumentLinkErr);
            this.LibraryAssert.AreEqual(0, Outcome.GetInteger('staged'), MappingRetryQueueErr);
            if Outcome.GetInteger('expectedDocuments') = 0 then begin
                this.LibraryAssert.AreEqual('', Outcome.GetText('salesOrderNo'), MappingDocumentLinkErr);
                this.LibraryAssert.AreEqual('', Outcome.GetText('salesInvoiceNo'), MappingDocumentLinkErr);
            end;
        end;
    end;

    local procedure RunMappingImport()
    var
        ShopFilter: Record "Shpfy Shop";
        SyncOrders: Report "Shpfy Sync Orders from Shopify";
    begin
        ShopFilter.SetRange(Code, this.Shop.Code);
        SyncOrders.SetTableView(ShopFilter);
        SyncOrders.UseRequestPage(false);
        Commit();
        SyncOrders.Run();
    end;

    local procedure PrepareMappingRetry(var JobQueueEntry: Record "Job Queue Entry"; var ImportOrder: JsonObject; var ImportLines: JsonArray): BigInteger
    var
        ShopFilter: Record "Shpfy Shop";
        MappingJobParametersTok: Label '<?xml version="1.0" standalone="yes"?><ReportParameters name="Sync Orders from Shopify" id="30104"><DataItems><DataItem name="Shop">%1</DataItem><DataItem name="OrdersToImport">VERSION(1) SORTING(Field1)</DataItem></DataItems></ReportParameters>', Locked = true, Comment = '%1 = Shop record view';
        OrderId: BigInteger;
    begin
        this.Shop := this.CreateIncompleteMappingShop();
        this.Shop.Modify(false);
        this.SetAutomaticOrderCreation(true);
        OrderId := this.PrepareIncompleteOrderImport(true, ImportOrder, ImportLines);
        JobQueueEntry.ID := CreateGuid();
        JobQueueEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(JobQueueEntry."User ID"));
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Report;
        JobQueueEntry."Object ID to Run" := Report::"Shpfy Sync Orders from Shopify";
        JobQueueEntry."Report Output Type" := JobQueueEntry."Report Output Type"::"None (Processing only)";
        JobQueueEntry."Notify On Success" := true;
        JobQueueEntry.Insert(false);
        ShopFilter.SetRange(Code, this.Shop.Code);
        JobQueueEntry.SetXmlContent(StrSubstNo(MappingJobParametersTok, ShopFilter.GetView()));
        Commit();
        exit(OrderId);
    end;

    local procedure ExerciseMappingRetries(OrderId: BigInteger; var JobQueueEntry: Record "Job Queue Entry"; ImportOrder: JsonObject; ImportLines: JsonArray; var Outcomes: JsonArray)
    var
        JobQueueStartReport: Codeunit "Job Queue Start Report";
        Index: Integer;
    begin
        JobQueueStartReport.Run(JobQueueEntry);
        this.CaptureMappingOutcome(OrderId, this.ExpectedMappingDetails(OrderId, true), true, false, false, 0, Outcomes);
        this.RestageMappingOrder(OrderId, ImportOrder, ImportLines);
        Clear(JobQueueStartReport);
        JobQueueStartReport.Run(JobQueueEntry);
        this.CaptureMappingOutcome(OrderId, this.ExpectedMappingDetails(OrderId, true), true, false, false, 0, Outcomes);
        for Index := 1 to 2 do begin
            this.RunMappingPath(OrderId, 'Manual');
            this.CaptureMappingOutcome(OrderId, this.ExpectedProcessingMappingDetails(OrderId, true), true, false, false, 0, Outcomes);
            this.RunMappingPath(OrderId, 'Batch');
            this.CaptureMappingOutcome(OrderId, this.ExpectedProcessingMappingDetails(OrderId, true), true, false, false, 0, Outcomes);
        end;

        this.CorrectMappingOrder(OrderId);
        this.RunMappingPath(OrderId, 'Batch');
        this.CaptureMappingOutcome(OrderId, '', false, false, true, 1, Outcomes);
        this.RunMappingPath(OrderId, 'Batch');
        this.CaptureMappingOutcome(OrderId, '', false, false, true, 1, Outcomes);
    end;

    local procedure RestageMappingOrder(OrderId: BigInteger; ImportOrder: JsonObject; ImportLines: JsonArray)
    var
        OrderHeader: Record "Shpfy Order Header";
        OrdersToImport: Record "Shpfy Orders to Import";
    begin
        OrderHeader.Get(OrderId);
        this.Shop.Get(OrderHeader."Shop Code");
        OrdersToImport."Shop Id" := this.Shop."Shop Id";
        OrdersToImport."Shop Code" := this.Shop.Code;
        OrdersToImport.Id := OrderId;
        OrdersToImport."Import Action" := OrdersToImport."Import Action"::New;
        OrdersToImport.Insert(false);
        this.EnqueueAutoCreateOrderResponses(ImportOrder, ImportLines);
        this.EnqueueMappingExchangeResponse(OrderId);
        Commit();
    end;

    local procedure EnqueueMappingExchangeResponse(OrderId: BigInteger)
    var
        ExchangeResponseTok: Label '{"data":{"order":{"returns":{"nodes":[{"exchangeLineItems":{"nodes":[{"lineItems":[{"id":"gid://shopify/LineItem/%1"}]}]}}],"pageInfo":{"hasNextPage":false}}}}}', Locked = true, Comment = '%1 = Shopify exchange line item ID';
    begin
        this.HttpResponses.Enqueue(StrSubstNo(ExchangeResponseTok, OrderId * 10 + 5));
    end;

    [ConfirmHandler]
    internal procedure MappingConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    local procedure SetOrderError(var OrderHeader: Record "Shpfy Order Header"; ErrorMessage: Text)
    begin
        OrderHeader."Has Error" := true;
        OrderHeader."Error Message" := CopyStr(ErrorMessage, 1, MaxStrLen(OrderHeader."Error Message"));
        OrderHeader.Modify(false);
    end;

    local procedure SetAutomaticOrderCreation(Enabled: Boolean)
    begin
        this.Shop.Get(this.Shop.Code);
        this.Shop."Auto Create Orders" := Enabled;
        this.Shop.Modify(false);
    end;

    local procedure CreateMappingImportFixture(var OrdersToImport: Record "Shpfy Orders to Import"; var JOrder: JsonObject; var JLines: JsonArray)
    var
        Item: Record Item;
        Product: Record "Shpfy Product";
        Variant: Record "Shpfy Variant";
        OrderHandlingHelper: Codeunit "Shpfy Order Handling Helper";
        OrdersAPI: Codeunit "Shpfy Orders API";
        Address: JsonObject;
        ContactDetails: JsonObject;
        Cursor: Text;
        Customer: JsonObject;
        Line: JsonObject;
        Money: JsonObject;
        Node: JsonToken;
        OrdersResponse: JsonObject;
        PriceSet: JsonObject;
        ProductJson: JsonObject;
        TaxLine: JsonObject;
        TaxLines: JsonArray;
        VariantJson: JsonObject;
        LineIdTok: Label 'gid://shopify/LineItem/%1', Locked = true, Comment = '%1 = Shopify line item ID';
    begin
        OrdersResponse := OrderHandlingHelper.GetOrdersToImport(false);
        OrdersToImport.SetRange("Shop Id", this.Shop."Shop Id");
        OrdersToImport.DeleteAll(false);
        OrdersAPI.ExtractShopifyOrdersToImport(this.Shop, OrdersResponse, Cursor);
        OrdersToImport.SetRange("Shop Id", this.Shop."Shop Id");
        OrdersToImport.FindFirst();
        OrdersToImport."Order Amount" := 110;
        OrdersToImport.Modify(false);
        OrdersResponse.GetObject('data').GetObject('orders').GetArray('edges').Get(0, Node);
        JOrder := Node.AsObject().GetObject('node');
        JOrder.Replace('legacyResourceId', OrdersToImport.Id);
        JOrder.Replace('name', OrdersToImport."Order No.");
        JOrder.Add('confirmed', true);
        JOrder.Add('email', '');
        JOrder.Add('phone', '');
        Customer.Add('legacyResourceId', 0);
        Customer.Add('firstName', 'Mapping');
        Customer.Add('lastName', 'Test');
        ContactDetails.Add('emailAddress', '');
        Customer.Add('defaultEmailAddress', ContactDetails);
        Clear(ContactDetails);
        ContactDetails.Add('phoneNumber', '');
        Customer.Add('defaultPhoneNumber', ContactDetails);
        JOrder.Add('customer', Customer);
        Address.Add('firstName', 'Mapping');
        Address.Add('lastName', 'Test');
        JOrder.Add('displayAddress', Address);
        JOrder.Add('shippingAddress', Address);
        JOrder.Add('billingAddress', Address);
        JOrder.Add('currencyCode', OrdersToImport."Currency Code");
        JOrder.Add('presentmentCurrencyCode', OrdersToImport."Currency Code");
        JOrder.Add('taxesIncluded', true);
        Money.Add('amount', '110');
        Money.Add('currencyCode', OrdersToImport."Currency Code");
        PriceSet.Add('shopMoney', Money);
        PriceSet.Add('presentmentMoney', Money);
        JOrder.Replace('totalPriceSet', PriceSet);
        JOrder.Add('currentTotalPriceSet', PriceSet);
        JOrder.Add('subtotalPriceSet', PriceSet);
        JOrder.Add('currentSubtotalPriceSet', PriceSet);
        Money.Replace('amount', 10);
        PriceSet.Replace('shopMoney', Money);
        PriceSet.Replace('presentmentMoney', Money);
        JOrder.Add('totalTaxSet', PriceSet);
        JOrder.Add('currentTotalTaxSet', PriceSet);
        TaxLine.Add('title', 'VAT');
        TaxLine.Add('rate', 0.1);
        TaxLine.Add('priceSet', PriceSet);
        TaxLines.Add(TaxLine);
        JOrder.Add('taxLines', TaxLines);

        Item := this.InitializeTest.GetDummyItem();
        Product.Id := OrdersToImport.Id * 1000;
        Product."Shop Code" := this.Shop.Code;
        Product.Title := Item.Description;
        Product."Item SystemId" := Item.SystemId;
        Product.Insert(false);
        Variant.Id := Product.Id;
        Variant."Product Id" := Product.Id;
        Variant."Shop Code" := this.Shop.Code;
        Variant."Item SystemId" := Item.SystemId;
        Variant.Insert(false);
        ProductJson.Add('legacyResourceId', Product.Id);
        ProductJson.Add('isGiftCard', false);
        VariantJson.Add('legacyResourceId', Variant.Id);
        Line.ReadFrom('{"quantity":1,"currentQuantity":1,"fulfillableQuantity":1,"taxable":true,"requiresShipping":true,"variantTitle":"","customAttributes":[],"discountAllocations":[]}');
        Line.Add('id', StrSubstNo(LineIdTok, OrdersToImport.Id * 10 + 1));
        Line.Add('name', Item.Description);
        Line.Add('title', Item.Description);
        Line.Add('product', ProductJson);
        Line.Add('variant', VariantJson);
        Money.Replace('amount', 110);
        PriceSet.Replace('shopMoney', Money);
        PriceSet.Replace('presentmentMoney', Money);
        Line.Add('originalUnitPriceSet', PriceSet);
        Line.Add('taxLines', TaxLines);
        Clear(JLines);
        JLines.Add(Line);
    end;

    local procedure PrepareIncompleteOrderImport(IncludeItemGaps: Boolean; var JShopifyOrder: JsonObject; var JShopifyLineItems: JsonArray) OrderId: BigInteger
    var
        OrdersToImport: Record "Shpfy Orders to Import";
        RegisteredStore: Record "Shpfy Registered Store New";
        Variant: Record "Shpfy Variant";
        AuthenticationMgt: Codeunit "Shpfy Authentication Mgt.";
        EntryNo: Integer;
        JDefaultEmailAddress: JsonObject;
        JDefaultPhoneNumber: JsonObject;
        JShopifyCustomer: JsonObject;
        Line: JsonObject;
        LineId: BigInteger;
        LineToken: JsonToken;
        UnmappedCustomerId: BigInteger;
        UnmappedEmail: Text;
        UnmappedPhone: Text;
        LineIdTok: Label 'gid://shopify/LineItem/%1', Locked = true, Comment = '%1 = Shopify line item ID';
    begin
        this.CreateMappingImportFixture(OrdersToImport, JShopifyOrder, JShopifyLineItems);
        UnmappedCustomerId := this.LibraryRandom.RandIntInRange(10000000, 99999999);
        UnmappedEmail := 'unmapped-' + Format(UnmappedCustomerId) + '@example.com';
        UnmappedPhone := StrSubstNo('+1%1', UnmappedCustomerId);
        JShopifyOrder.Remove('email');
        JShopifyOrder.Add('email', UnmappedEmail);
        JShopifyOrder.Remove('phone');
        JShopifyOrder.Add('phone', UnmappedPhone);
        JShopifyCustomer := JShopifyOrder.GetObject('customer');
        JShopifyCustomer.Remove('legacyResourceId');
        JShopifyCustomer.Add('legacyResourceId', UnmappedCustomerId);
        JDefaultEmailAddress := JShopifyCustomer.GetObject('defaultEmailAddress');
        JDefaultEmailAddress.Remove('emailAddress');
        JDefaultEmailAddress.Add('emailAddress', UnmappedEmail);
        JShopifyCustomer.Remove('defaultEmailAddress');
        JShopifyCustomer.Add('defaultEmailAddress', JDefaultEmailAddress);
        JDefaultPhoneNumber := JShopifyCustomer.GetObject('defaultPhoneNumber');
        JDefaultPhoneNumber.Remove('phoneNumber');
        JDefaultPhoneNumber.Add('phoneNumber', UnmappedPhone);
        JShopifyCustomer.Remove('defaultPhoneNumber');
        JShopifyCustomer.Add('defaultPhoneNumber', JDefaultPhoneNumber);
        JShopifyOrder.Remove('customer');
        JShopifyOrder.Add('customer', JShopifyCustomer);
        EntryNo := OrdersToImport."Entry No.";
        OrderId := OrdersToImport.Id;
        if IncludeItemGaps then begin
            JShopifyLineItems.Get(0, LineToken);
            Line := LineToken.AsObject();
            LineId := OrderId * 10 + 1;
            Line.Replace('id', StrSubstNo(LineIdTok, LineId));
            Variant.Get(Line.GetObject('variant').GetBigInteger('legacyResourceId'));
            Variant."Item SystemId" := CreateGuid();
            Variant.Modify(false);
            JShopifyLineItems.Set(0, Line);
            Line := Line.Clone().AsObject();
            Line.Replace('id', StrSubstNo(LineIdTok, OrderId * 10 + 5));
            JShopifyLineItems.Add(Line);
            this.AddMappingAccountImportLines(OrderId, Line, JShopifyLineItems);
            JShopifyOrder.Add('returnStatus', 'RETURNED');
            this.Shop."Return and Refund Process" := this.Shop."Return and Refund Process"::"Import Only";
            this.Shop.Modify(false);
        end;
        OrdersToImport.Reset();
        OrdersToImport.SetRange("Shop Id", this.Shop."Shop Id");
        OrdersToImport.SetFilter("Entry No.", '<>%1', EntryNo);
        OrdersToImport.DeleteAll(false);
        this.EnqueueAutoCreateOrderResponses(JShopifyOrder, JShopifyLineItems);
        if IncludeItemGaps then
            this.EnqueueMappingExchangeResponse(OrderId);
        RegisteredStore.Get(this.Shop.GetStoreName());
        RegisteredStore."Requested Scope" := AuthenticationMgt.GetScope();
        RegisteredStore."Actual Scope" := AuthenticationMgt.GetScope();
        RegisteredStore.Modify(false);
        Commit();
    end;

    local procedure AddMappingAccountImportLines(OrderId: BigInteger; Line: JsonObject; var Lines: JsonArray)
    var
        EmptyLines: JsonArray;
        Money: JsonObject;
        NullValue: JsonValue;
        PriceSet: JsonObject;
        LineIdTok: Label 'gid://shopify/LineItem/%1', Locked = true, Comment = '%1 = Shopify line item ID';
    begin
        Line := Line.Clone().AsObject();
        NullValue.SetValueToNull();
        Money.Add('amount', '0');
        PriceSet.Add('shopMoney', Money);
        PriceSet.Add('presentmentMoney', Money);
        Line.Replace('originalUnitPriceSet', PriceSet);
        Line.Replace('taxLines', EmptyLines);
        Line.Replace('product', NullValue);
        Line.Replace('name', 'Tip');
        Line.Replace('id', StrSubstNo(LineIdTok, OrderId * 10 + 3));
        Lines.Add(Line);
        Line := Line.Clone().AsObject();
        Line.Replace('name', 'Gift card');
        Line.Add('isGiftCard', true);
        Line.Replace('id', StrSubstNo(LineIdTok, OrderId * 10 + 4));
        Lines.Add(Line);
    end;

    local procedure CreateTaxArea(var TaxArea: Record "Tax Area"; var ShopifyTaxArea: Record "Shpfy Tax Area"; ShopParam: Record "Shpfy Shop")
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
        ShopifyCustomerTemplate."Shop Code" := ShopParam.Code;
        ShopifyCustomerTemplate."Country/Region Code" := CountryRegionCode;
        if ShopifyCustomerTemplate.Insert() then;
        ShopifyTaxArea."Country/Region Code" := CountryRegionCode;
        ShopifyTaxArea."County Code" := CountyCode;
        ShopifyTaxArea.County := County;
        ShopifyTaxArea."Tax Area Code" := CountyCode;
        ShopifyTaxArea."Tax Liable" := true;
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
        ShopParam: Record "Shpfy Shop";
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
        OrderHeader."Shop Code" := ShopParam.Code;
        OrderHeader."Presentment Currency Code" := PresentmentCurrencyCode;
        OrderHeader."Presentment Total Amount" := PresentmentAmount;
        OrderHeader."Total Amount" := Amount;

        OrderHeader."Shopify Order Id" := LibraryRandom.RandIntInRange(100000, 999999);
        OrderHeader.Insert(false);

        ShopifyVariant."Item SystemId" := Item.SystemId;
        ShopifyVariant.Id := LibraryRandom.RandIntInRange(100000, 999999);
        ShopifyVariant."Shop Code" := ShopParam.Code;
        ShopifyVariant.Insert(false);
        OrderLine."Shopify Order Id" := OrderHeader."Shopify Order Id";
        OrderLine."Shopify Variant Id" := ShopifyVariant.Id;
        OrderLine."Unit Price" := Amount;
        OrderLine."Presentment Unit Price" := PresentmentAmount;
        OrderLine.Quantity := 1;
        OrderLine.Insert(false);
    end;

    local procedure CreateShopifyCustomer(ShopParam: Record "Shpfy Shop"; var ShopifyCustomer: Record "Shpfy Customer")
    var
        Customer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateCustomer(Customer);
        ShopifyCustomer.Id := LibraryRandom.RandIntInRange(100000, 999999);
        ShopifyCustomer."Customer SystemId" := Customer.SystemId;
        ShopifyCustomer."Shop Id" := ShopParam."Shop Id";
        ShopifyCustomer.Insert(false);
    end;

    local procedure CreateIncompleteMappingShop(): Record "Shpfy Shop"
    var
        ShopLcl: Record "Shpfy Shop";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
    begin
        ShopLcl := CommunicationMgt.GetShopRecord();
        ShopLcl.Validate("Customer Import From Shopify", ShopLcl."Customer Import From Shopify"::None);
        ShopLcl.Validate("Auto Create Unknown Customers", false);
        ShopLcl.Validate("Customer Mapping Type", "Shpfy Customer Mapping"::DefaultCustomer);
        ShopLcl.Validate("Default Customer No.", '');
        ShopLcl.Validate("Tip Account", '');
        ShopLcl.Validate("Sold Gift Card Account", '');
        exit(ShopLcl);
    end;

    local procedure CreateIncompleteMappingOrder(var OrderHeader: Record "Shpfy Order Header")
    var
        OrderLine: Record "Shpfy Order Line";
        OrderId: BigInteger;
    begin
        OrderHeader.Reset();
        repeat
            OrderId := this.LibraryRandom.RandIntInRange(100000, 999999);
        until not OrderHeader.Get(OrderId);

        OrderHeader.Init();
        OrderHeader."Shopify Order Id" := OrderId;
        OrderHeader."Shop Code" := this.Shop.Code;
        OrderHeader."Sell-to Customer Name" := 'Unmapped test customer';
        OrderHeader."Bill-to Name" := 'Unmapped test customer';
        OrderHeader."Ship-to Country/Region Code" := CopyStr(this.LibraryRandom.RandText(MaxStrLen(OrderHeader."Ship-to Country/Region Code")), 1, MaxStrLen(OrderHeader."Ship-to Country/Region Code"));
        OrderHeader."Customer Id" := this.LibraryRandom.RandIntInRange(100000, 999999);
        OrderHeader.Insert(false);

        OrderLine.Init();
        OrderLine."Shopify Order Id" := OrderHeader."Shopify Order Id";
        OrderLine."Line Id" := OrderHeader."Shopify Order Id" * 10 + 3;
        OrderLine.Tip := true;
        OrderLine.Quantity := 1;
        OrderLine.Insert(false);

        OrderLine.Init();
        OrderLine."Shopify Order Id" := OrderHeader."Shopify Order Id";
        OrderLine."Line Id" := OrderHeader."Shopify Order Id" * 10 + 4;
        OrderLine."Gift Card" := true;
        OrderLine.Quantity := 1;
        OrderLine.Insert(false);
    end;

    local procedure CreateUnmappedItemLine(OrderId: BigInteger; LineId: BigInteger; IsExchangeItem: Boolean)
    var
        OrderLine: Record "Shpfy Order Line";
        ShopifyVariant: Record "Shpfy Variant";
    begin
        ShopifyVariant.Init();
        ShopifyVariant.Id := LineId;
        ShopifyVariant."Shop Code" := this.Shop.Code;
        ShopifyVariant."Item SystemId" := CreateGuid();
        ShopifyVariant.Insert(false);

        OrderLine.Init();
        OrderLine."Shopify Order Id" := OrderId;
        OrderLine."Line Id" := LineId;
        OrderLine."Shopify Variant Id" := LineId;
        OrderLine."Is Exchange Item" := IsExchangeItem;
        OrderLine.Quantity := 1;
        OrderLine.Insert(false);
    end;

    local procedure Initialize()
    var
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        AccessToken: SecretText;
    begin
        // Reset per-test mock state so a previous test's assertion failure cannot leak
        // the plan-refresh flag into the next test and corrupt unrelated HTTP calls.
        PlanRefreshExpected := false;
        PlanRefreshCallCount := 0;
        HttpResponses.Clear();
        if IsInitialized then
            exit;

        Codeunit.Run(Codeunit::"Shpfy Initialize Test");
        Shop := CommunicationMgt.GetShopRecord();

        AccessToken := LibraryRandom.RandText(20);
        InitializeTest.RegisterAccessTokenForShop(Shop.GetStoreName(), AccessToken);

        IsInitialized := true;
    end;

    [HttpClientHandler]
    internal procedure OrdersAPIHttpHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    var
        Body: Text;
    begin
        if not InitializeTest.VerifyRequestUrl(Request.Path, Shop."Shopify URL") then
            exit(true);
        if HttpResponses.Length() > 0 then begin
            Response.Content.WriteFrom(HttpResponses.DequeueText());
            exit(false);
        end;
        if PlanRefreshExpected and (PlanRefreshCallCount = 0) then begin
            PlanRefreshCallCount += 1;
            Response.Content.WriteFrom(DowngradedPlanShopResponseTok);
            exit(false);
        end;
        if CompanyLocationId <> 0 then begin
            Body := NavApp.GetResourceAsText('Order Handling/CompanyLocationResult.txt', TextEncoding::UTF8);
            Response.Content.WriteFrom(Body.Replace('{{LocationId}}', Format(CompanyLocationId)));
            CompanyLocationId := 0;
        end else
            Response.Content.WriteFrom('{"data":{}}');
        exit(false);
    end;

    local procedure EnqueueAutoCreateOrderResponses(JShopifyOrder: JsonObject; JShopifyLineItems: JsonArray)
    var
        HeaderData: JsonObject;
        HeaderResponse: JsonObject;
        LineData: JsonObject;
        LineItems: JsonObject;
        LineOrder: JsonObject;
        LinePageInfo: JsonObject;
        LineResponse: JsonObject;
    begin
        HttpResponses.Enqueue(DowngradedPlanShopResponseTok);
        HttpResponses.Enqueue('{"data":{}}');

        HeaderData.Add('order', JShopifyOrder);
        HeaderResponse.Add('data', HeaderData);
        HttpResponses.Enqueue(Format(HeaderResponse));

        LinePageInfo.Add('hasNextPage', false);
        LinePageInfo.Add('endCursor', '');
        LineItems.Add('pageInfo', LinePageInfo);
        LineItems.Add('nodes', JShopifyLineItems);
        LineOrder.Add('lineItems', LineItems);
        LineData.Add('order', LineOrder);
        LineResponse.Add('data', LineData);
        HttpResponses.Enqueue(Format(LineResponse));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Order Events", OnBeforeProcessSalesDocument, '', false, false)]
    local procedure ChangeCurrencyHandlingOnBeforeProcessSalesDocument(var ShopifyOrderHeader: Record "Shpfy Order Header")
    var
        ShopToUpdate: Record "Shpfy Shop";
    begin
        ShopToUpdate.Get(ShopifyOrderHeader."Shop Code");
        ShopToUpdate."Currency Handling" := "Shpfy Currency Handling"::"Shop Currency";
        ShopToUpdate.Modify(false);
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

    local procedure SetManualNosOnOrderNoSeries()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        NoSeries: Record "No. Series";
    begin
        SalesReceivablesSetup.Get();
        if NoSeries.Get(SalesReceivablesSetup."Order Nos.") then begin
            NoSeries."Manual Nos." := true;
            NoSeries.Modify();
        end;
    end;

    local procedure SetManualNosOnInvoiceNoSeries()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        NoSeries: Record "No. Series";
    begin
        SalesReceivablesSetup.Get();
        if NoSeries.Get(SalesReceivablesSetup."Invoice Nos.") then begin
            NoSeries."Manual Nos." := true;
            NoSeries.Modify();
        end;
    end;
}
