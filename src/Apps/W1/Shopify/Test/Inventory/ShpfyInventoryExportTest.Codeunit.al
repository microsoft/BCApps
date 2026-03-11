// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Integration.Shopify;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using System.TestLibraries.Utilities;

/// <summary>
/// Codeunit Shpfy Inventory Export Test (ID 139501).
/// Tests for inventory export functionality including idempotency and retry logic.
/// </summary>
codeunit 139594 "Shpfy Inventory Export Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var
        Any: Codeunit Any;
        LibraryAssert: Codeunit "Library Assert";
        LibraryInventory: Codeunit "Library - Inventory";
        IsInitialized: Boolean;
        NextId: BigInteger;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;
        IsInitialized := true;
        Codeunit.Run(Codeunit::"Shpfy Initialize Test");
    end;

    [Test]
    procedure UnitTestExportStockSuccess()
    var
        Shop: Record "Shpfy Shop";
        ShopLocation: Record "Shpfy Shop Location";
        Item: Record Item;
        ShopifyProduct: Record "Shpfy Product";
        ShopInventory: Record "Shpfy Shop Inventory";
        InventorySubscriber: Codeunit "Shpfy Inventory Subscriber";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        InventoryAPI: Codeunit "Shpfy Inventory API";
        StockCalculate: Enum "Shpfy Stock Calculation";
    begin
        // [SCENARIO] Export stock successfully updates inventory in Shopify
        // [GIVEN] A ShopInventory record with stock different from Shopify stock
        Initialize();

        Shop := CommunicationMgt.GetShopRecord();
        CreateShopLocation(ShopLocation, Shop.Code, StockCalculate::"Projected Available Balance Today");
        CreateItem(Item);
        UpdateItemInventory(Item, 10);
        CreateShopifyProduct(ShopifyProduct, ShopInventory, Item.SystemId, Shop.Code, ShopLocation.Id);
        ShopInventory."Shopify Stock" := 5; // Different from calculated stock to trigger export
        ShopInventory.Modify();

        // [GIVEN] The inventory subscriber is configured to return success
        BindSubscription(InventorySubscriber);
        InventorySubscriber.SetRetryScenario(Enum::"Shpfy Inventory Retry Scenario"::Success);
        InventoryAPI.SetShop(Shop.Code);

        // [WHEN] ExportStock is called
        ShopInventory.SetRange("Shop Code", Shop.Code);
        ShopInventory.SetRange("Variant Id", ShopInventory."Variant Id");
        InventoryAPI.ExportStock(ShopInventory);

        // [THEN] The mutation was executed successfully (verified by subscriber not throwing error)
        UnbindSubscription(InventorySubscriber);
    end;

    [Test]
    procedure UnitTestExportStockRetryOnIdempotencyConcurrentRequest()
    var
        Shop: Record "Shpfy Shop";
        ShopLocation: Record "Shpfy Shop Location";
        Item: Record Item;
        ShopifyProduct: Record "Shpfy Product";
        ShopInventory: Record "Shpfy Shop Inventory";
        InventorySubscriber: Codeunit "Shpfy Inventory Subscriber";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        InventoryAPI: Codeunit "Shpfy Inventory API";
        StockCalculate: Enum "Shpfy Stock Calculation";
    begin
        // [SCENARIO] Export stock retries on IDEMPOTENCY_CONCURRENT_REQUEST error
        // [GIVEN] A ShopInventory record with stock different from Shopify stock
        Initialize();

        Shop := CommunicationMgt.GetShopRecord();
        CreateShopLocation(ShopLocation, Shop.Code, StockCalculate::"Projected Available Balance Today");
        CreateItem(Item);
        UpdateItemInventory(Item, 15);
        CreateShopifyProduct(ShopifyProduct, ShopInventory, Item.SystemId, Shop.Code, ShopLocation.Id);
        ShopInventory."Shopify Stock" := 5;
        ShopInventory.Modify();

        // [GIVEN] The inventory subscriber is configured to fail once with IDEMPOTENCY_CONCURRENT_REQUEST then succeed
        BindSubscription(InventorySubscriber);
        InventorySubscriber.SetRetryScenario(Enum::"Shpfy Inventory Retry Scenario"::FailOnceThenSucceed);
        InventorySubscriber.SetErrorCode('IDEMPOTENCY_CONCURRENT_REQUEST');
        InventoryAPI.SetShop(Shop.Code);

        // [WHEN] ExportStock is called
        ShopInventory.SetRange("Shop Code", Shop.Code);
        ShopInventory.SetRange("Variant Id", ShopInventory."Variant Id");
        InventoryAPI.ExportStock(ShopInventory);

        // [THEN] The mutation was retried and succeeded (2 calls total)
        LibraryAssert.AreEqual(2, InventorySubscriber.GetCallCount(), 'Expected 2 GraphQL calls (1 failure + 1 retry success)');

        UnbindSubscription(InventorySubscriber);
    end;

    [Test]
    procedure UnitTestExportStockRetryOnChangeFromQuantityStale()
    var
        Shop: Record "Shpfy Shop";
        ShopLocation: Record "Shpfy Shop Location";
        Item: Record Item;
        ShopifyProduct: Record "Shpfy Product";
        ShopInventory: Record "Shpfy Shop Inventory";
        InventorySubscriber: Codeunit "Shpfy Inventory Subscriber";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        InventoryAPI: Codeunit "Shpfy Inventory API";
        StockCalculate: Enum "Shpfy Stock Calculation";
    begin
        // [SCENARIO] Export stock retries on CHANGE_FROM_QUANTITY_STALE error
        // [GIVEN] A ShopInventory record with stock different from Shopify stock
        Initialize();

        Shop := CommunicationMgt.GetShopRecord();
        CreateShopLocation(ShopLocation, Shop.Code, StockCalculate::"Projected Available Balance Today");
        CreateItem(Item);
        UpdateItemInventory(Item, 20);
        CreateShopifyProduct(ShopifyProduct, ShopInventory, Item.SystemId, Shop.Code, ShopLocation.Id);
        ShopInventory."Shopify Stock" := 10;
        ShopInventory.Modify();

        // [GIVEN] The inventory subscriber is configured to fail once with CHANGE_FROM_QUANTITY_STALE then succeed
        BindSubscription(InventorySubscriber);
        InventorySubscriber.SetRetryScenario(Enum::"Shpfy Inventory Retry Scenario"::FailOnceThenSucceed);
        InventorySubscriber.SetErrorCode('CHANGE_FROM_QUANTITY_STALE');
        InventoryAPI.SetShop(Shop.Code);

        // [WHEN] ExportStock is called
        ShopInventory.SetRange("Shop Code", Shop.Code);
        ShopInventory.SetRange("Variant Id", ShopInventory."Variant Id");
        InventoryAPI.ExportStock(ShopInventory);

        // [THEN] The mutation was retried and succeeded (2 calls total)
        LibraryAssert.AreEqual(2, InventorySubscriber.GetCallCount(), 'Expected 2 GraphQL calls (1 failure + 1 retry success)');

        UnbindSubscription(InventorySubscriber);
    end;

    [Test]
    procedure UnitTestExportStockLogsSkippedRecordAfterMaxRetries()
    var
        Shop: Record "Shpfy Shop";
        ShopLocation: Record "Shpfy Shop Location";
        Item: Record Item;
        ShopifyProduct: Record "Shpfy Product";
        ShopInventory: Record "Shpfy Shop Inventory";
        SkippedRecord: Record "Shpfy Skipped Record";
        InventorySubscriber: Codeunit "Shpfy Inventory Subscriber";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        InventoryAPI: Codeunit "Shpfy Inventory API";
        StockCalculate: Enum "Shpfy Stock Calculation";
        SkippedCountBefore: Integer;
        SkippedCountAfter: Integer;
    begin
        // [SCENARIO] Export stock logs skipped record when max retries exceeded
        // [GIVEN] A ShopInventory record with stock different from Shopify stock
        Initialize();

        Shop := CommunicationMgt.GetShopRecord();
        CreateShopLocation(ShopLocation, Shop.Code, StockCalculate::"Projected Available Balance Today");
        CreateItem(Item);
        UpdateItemInventory(Item, 25);
        CreateShopifyProduct(ShopifyProduct, ShopInventory, Item.SystemId, Shop.Code, ShopLocation.Id);
        ShopInventory."Shopify Stock" := 15;
        ShopInventory.Modify();

        // [GIVEN] Count of skipped records before export
        SkippedCountBefore := SkippedRecord.Count();

        // [GIVEN] The inventory subscriber is configured to always fail with concurrency error
        BindSubscription(InventorySubscriber);
        InventorySubscriber.SetRetryScenario(Enum::"Shpfy Inventory Retry Scenario"::AlwaysFail);
        InventorySubscriber.SetErrorCode('IDEMPOTENCY_CONCURRENT_REQUEST');
        InventoryAPI.SetShop(Shop.Code);

        // [WHEN] ExportStock is called
        ShopInventory.SetRange("Shop Code", Shop.Code);
        ShopInventory.SetRange("Variant Id", ShopInventory."Variant Id");
        InventoryAPI.ExportStock(ShopInventory);

        // [THEN] A skipped record was logged
        SkippedCountAfter := SkippedRecord.Count();
        LibraryAssert.IsTrue(SkippedCountAfter > SkippedCountBefore, 'Expected a skipped record to be logged after max retries');

        // [THEN] The mutation was retried max times (4 calls: 1 initial + 3 retry)
        LibraryAssert.AreEqual(4, InventorySubscriber.GetCallCount(), 'Expected 4 GraphQL calls (1 initial + 3 retry)');

        UnbindSubscription(InventorySubscriber);
    end;

    [Test]
    procedure UnitTestCalcStockIncludesChangeFromQuantityNull()
    var
        Shop: Record "Shpfy Shop";
        ShopLocation: Record "Shpfy Shop Location";
        Item: Record Item;
        ShopifyProduct: Record "Shpfy Product";
        ShopInventory: Record "Shpfy Shop Inventory";
        InventorySubscriber: Codeunit "Shpfy Inventory Subscriber";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        InventoryAPI: Codeunit "Shpfy Inventory API";
        StockCalculate: Enum "Shpfy Stock Calculation";
        LastGraphQLRequest: Text;
    begin
        // [SCENARIO] CalcStock includes changeFromQuantity: null in the GraphQL mutation
        // [GIVEN] A ShopInventory record with stock different from Shopify stock
        Initialize();

        Shop := CommunicationMgt.GetShopRecord();
        CreateShopLocation(ShopLocation, Shop.Code, StockCalculate::"Projected Available Balance Today");
        CreateItem(Item);
        UpdateItemInventory(Item, 30);
        CreateShopifyProduct(ShopifyProduct, ShopInventory, Item.SystemId, Shop.Code, ShopLocation.Id);
        ShopInventory."Shopify Stock" := 20;
        ShopInventory.Modify();

        // [GIVEN] The inventory subscriber captures the GraphQL request
        BindSubscription(InventorySubscriber);
        InventorySubscriber.SetRetryScenario(Enum::"Shpfy Inventory Retry Scenario"::Success);
        InventoryAPI.SetShop(Shop.Code);

        // [WHEN] ExportStock is called
        ShopInventory.SetRange("Shop Code", Shop.Code);
        ShopInventory.SetRange("Variant Id", ShopInventory."Variant Id");
        InventoryAPI.ExportStock(ShopInventory);

        // [THEN] The GraphQL request contains changeFromQuantity: null
        LastGraphQLRequest := InventorySubscriber.GetLastGraphQLRequest();
        LibraryAssert.IsTrue(LastGraphQLRequest.Contains('"changeFromQuantity":null'), 'Expected changeFromQuantity: null in GraphQL request');

        UnbindSubscription(InventorySubscriber);
    end;

    [Test]
    procedure UnitTestIdempotencyKeyIsGenerated()
    var
        Shop: Record "Shpfy Shop";
        ShopLocation: Record "Shpfy Shop Location";
        Item: Record Item;
        ShopifyProduct: Record "Shpfy Product";
        ShopInventory: Record "Shpfy Shop Inventory";
        InventorySubscriber: Codeunit "Shpfy Inventory Subscriber";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        InventoryAPI: Codeunit "Shpfy Inventory API";
        StockCalculate: Enum "Shpfy Stock Calculation";
        LastGraphQLRequest: Text;
    begin
        // [SCENARIO] Idempotency key is generated and included in the GraphQL mutation
        // [GIVEN] A ShopInventory record with stock different from Shopify stock
        Initialize();

        Shop := CommunicationMgt.GetShopRecord();
        CreateShopLocation(ShopLocation, Shop.Code, StockCalculate::"Projected Available Balance Today");
        CreateItem(Item);
        UpdateItemInventory(Item, 35);
        CreateShopifyProduct(ShopifyProduct, ShopInventory, Item.SystemId, Shop.Code, ShopLocation.Id);
        ShopInventory."Shopify Stock" := 25;
        ShopInventory.Modify();

        // [GIVEN] The inventory subscriber captures the GraphQL request
        BindSubscription(InventorySubscriber);
        InventorySubscriber.SetRetryScenario(Enum::"Shpfy Inventory Retry Scenario"::Success);
        InventoryAPI.SetShop(Shop.Code);

        // [WHEN] ExportStock is called
        ShopInventory.SetRange("Shop Code", Shop.Code);
        ShopInventory.SetRange("Variant Id", ShopInventory."Variant Id");
        InventoryAPI.ExportStock(ShopInventory);

        // [THEN] The GraphQL request contains @idempotent directive with a GUID key
        LastGraphQLRequest := InventorySubscriber.GetLastGraphQLRequest();
        LibraryAssert.IsTrue(LastGraphQLRequest.Contains('@idempotent(key:'), 'Expected @idempotent directive in GraphQL request');

        UnbindSubscription(InventorySubscriber);
    end;

    local procedure CreateItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItemWithoutVAT(Item);
    end;

    local procedure CreateShopifyProduct(var ShopifyProduct: Record "Shpfy Product"; var ShopInventory: Record "Shpfy Shop Inventory"; ItemSystemId: Guid; ShopCode: Code[20]; ShopLocationId: BigInteger)
    var
        ShopifyVariant: Record "Shpfy Variant";
        ProductId: BigInteger;
        VariantId: BigInteger;
        InventoryItemId: BigInteger;
    begin
        ProductId := GetNextId();
        VariantId := GetNextId();
        InventoryItemId := GetNextId();

        ShopifyProduct.Init();
        ShopifyProduct.Id := ProductId;
        ShopifyProduct."Item SystemId" := ItemSystemId;
        ShopifyProduct."Shop Code" := ShopCode;
        ShopifyProduct.Insert();

        ShopifyVariant.Init();
        ShopifyVariant.Id := VariantId;
        ShopifyVariant."Product Id" := ShopifyProduct.Id;
        ShopifyVariant."Item SystemId" := ItemSystemId;
        ShopifyVariant."Shop Code" := ShopCode;
        ShopifyVariant.Insert();

        ShopInventory.Init();
        ShopInventory."Inventory Item Id" := InventoryItemId;
        ShopInventory."Shop Code" := ShopCode;
        ShopInventory."Location Id" := ShopLocationId;
        ShopInventory."Product Id" := ShopifyProduct.Id;
        ShopInventory."Variant Id" := ShopifyVariant.Id;
        ShopInventory.Insert();
    end;

    local procedure GetNextId(): BigInteger
    begin
        NextId += 1;
        exit(NextId);
    end;

    local procedure CreateShopLocation(var ShopLocation: Record "Shpfy Shop Location"; ShopCode: Code[20]; StockCalculation: Enum "Shpfy Stock Calculation")
    begin
        ShopLocation.SetRange("Shop Code", ShopCode);
        ShopLocation.SetRange(Active, true);
        if ShopLocation.FindFirst() then begin
            ShopLocation."Stock Calculation" := StockCalculation;
            ShopLocation."Default Product Location" := true;
            ShopLocation.Modify();
            exit;
        end;

        ShopLocation.Init();
        ShopLocation."Shop Code" := ShopCode;
        ShopLocation.Id := Any.IntegerInRange(10000, 999999);
        ShopLocation."Stock Calculation" := StockCalculation;
        ShopLocation.Active := true;
        ShopLocation."Default Product Location" := true;
        ShopLocation.Insert();
    end;

    local procedure UpdateItemInventory(Item: Record Item; Qty: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', Qty);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;
}
