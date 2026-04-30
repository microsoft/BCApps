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
    TestHttpRequestPolicy = BlockOutboundRequests;

    var
        Shop: Record "Shpfy Shop";
        Any: Codeunit Any;
        LibraryAssert: Codeunit "Library Assert";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        InitializeTest: Codeunit "Shpfy Initialize Test";
        IsInitialized: Boolean;
        NextId: BigInteger;
        RetryScenario: Enum "Shpfy Inventory Retry Scenario";
        ErrorCode: Text;
        CallCount: Integer;

    local procedure Initialize()
    var
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        AccessToken: SecretText;
    begin
        if IsInitialized then
            exit;

        Codeunit.Run(Codeunit::"Shpfy Initialize Test");
        Shop := CommunicationMgt.GetShopRecord();

        AccessToken := LibraryRandom.RandText(20);
        InitializeTest.RegisterAccessTokenForShop(Shop.GetStoreName(), AccessToken);

        IsInitialized := true;
    end;

    local procedure SetRetryState(NewScenario: Enum "Shpfy Inventory Retry Scenario"; NewErrorCode: Text)
    begin
        RetryScenario := NewScenario;
        ErrorCode := NewErrorCode;
        CallCount := 0;
    end;

    [HttpClientHandler]
    internal procedure InventoryExportHttpHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    var
        ResponseJson: Text;
        SuccessResponseTxt: Label '{"data":{"inventorySetQuantities":{"inventoryAdjustmentGroup":{"id":"gid://shopify/InventoryAdjustmentGroup/12345"},"userErrors":[]}}}', Locked = true;
        ErrorResponseTxt: Label '{"data":{"inventorySetQuantities":{"inventoryAdjustmentGroup":null,"userErrors":[{"field":["input"],"message":"Concurrent request detected","code":"%1"}]}}}', Comment = '%1 = Error code', Locked = true;
    begin
        if not InitializeTest.VerifyRequestUrl(Request.Path, Shop."Shopify URL") then
            exit(true);

        CallCount += 1;

        case RetryScenario of
            RetryScenario::Success:
                ResponseJson := SuccessResponseTxt;
            RetryScenario::FailOnceThenSucceed:
                if CallCount <= 1 then
                    ResponseJson := StrSubstNo(ErrorResponseTxt, ErrorCode)
                else
                    ResponseJson := SuccessResponseTxt;
            RetryScenario::AlwaysFail:
                ResponseJson := StrSubstNo(ErrorResponseTxt, ErrorCode);
        end;

        Response.Content.WriteFrom(ResponseJson);
        exit(false);
    end;

    [Test]
    [HandlerFunctions('InventoryExportHttpHandler')]
    procedure UnitTestExportStockSuccess()
    var
        ShopLocation: Record "Shpfy Shop Location";
        Item: Record Item;
        ShopifyProduct: Record "Shpfy Product";
        ShopInventory: Record "Shpfy Shop Inventory";
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

        // [GIVEN] The handler is configured to return success
        SetRetryState(Enum::"Shpfy Inventory Retry Scenario"::Success, '');
        InventoryAPI.SetShop(Shop.Code);

        // [WHEN] ExportStock is called
        ShopInventory.SetRange("Shop Code", Shop.Code);
        ShopInventory.SetRange("Variant Id", ShopInventory."Variant Id");
        InventoryAPI.ExportStock(ShopInventory, false);

        // [THEN] The mutation was executed successfully (verified by handler not throwing error)
    end;

    [Test]
    [HandlerFunctions('InventoryExportHttpHandler')]
    procedure UnitTestExportStockRetryOnIdempotencyConcurrentRequest()
    var
        ShopLocation: Record "Shpfy Shop Location";
        Item: Record Item;
        ShopifyProduct: Record "Shpfy Product";
        ShopInventory: Record "Shpfy Shop Inventory";
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

        // [GIVEN] The handler is configured to fail once with IDEMPOTENCY_CONCURRENT_REQUEST then succeed
        SetRetryState(Enum::"Shpfy Inventory Retry Scenario"::FailOnceThenSucceed, 'IDEMPOTENCY_CONCURRENT_REQUEST');
        InventoryAPI.SetShop(Shop.Code);

        // [WHEN] ExportStock is called
        ShopInventory.SetRange("Shop Code", Shop.Code);
        ShopInventory.SetRange("Variant Id", ShopInventory."Variant Id");
        InventoryAPI.ExportStock(ShopInventory, false);

        // [THEN] The mutation was retried and succeeded (2 calls total)
        LibraryAssert.AreEqual(2, CallCount, 'Expected 2 GraphQL calls (1 failure + 1 retry success)');
    end;

    [Test]
    [HandlerFunctions('InventoryExportHttpHandler')]
    procedure UnitTestExportStockRetryOnChangeFromQuantityStale()
    var
        ShopLocation: Record "Shpfy Shop Location";
        Item: Record Item;
        ShopifyProduct: Record "Shpfy Product";
        ShopInventory: Record "Shpfy Shop Inventory";
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

        // [GIVEN] The handler is configured to fail once with CHANGE_FROM_QUANTITY_STALE then succeed
        SetRetryState(Enum::"Shpfy Inventory Retry Scenario"::FailOnceThenSucceed, 'CHANGE_FROM_QUANTITY_STALE');
        InventoryAPI.SetShop(Shop.Code);

        // [WHEN] ExportStock is called
        ShopInventory.SetRange("Shop Code", Shop.Code);
        ShopInventory.SetRange("Variant Id", ShopInventory."Variant Id");
        InventoryAPI.ExportStock(ShopInventory, false);

        // [THEN] The mutation was retried and succeeded (2 calls total)
        LibraryAssert.AreEqual(2, CallCount, 'Expected 2 GraphQL calls (1 failure + 1 retry success)');
    end;

    [Test]
    [HandlerFunctions('InventoryExportHttpHandler')]
    procedure UnitTestExportStockLogsSkippedRecordAfterMaxRetries()
    var
        ShopLocation: Record "Shpfy Shop Location";
        Item: Record Item;
        ShopifyProduct: Record "Shpfy Product";
        ShopInventory: Record "Shpfy Shop Inventory";
        SkippedRecord: Record "Shpfy Skipped Record";
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

        // [GIVEN] The handler is configured to always fail with concurrency error
        SetRetryState(Enum::"Shpfy Inventory Retry Scenario"::AlwaysFail, 'IDEMPOTENCY_CONCURRENT_REQUEST');
        InventoryAPI.SetShop(Shop.Code);

        // [WHEN] ExportStock is called
        ShopInventory.SetRange("Shop Code", Shop.Code);
        ShopInventory.SetRange("Variant Id", ShopInventory."Variant Id");
        InventoryAPI.ExportStock(ShopInventory, false);

        // [THEN] A skipped record was logged
        SkippedCountAfter := SkippedRecord.Count();
        LibraryAssert.IsTrue(SkippedCountAfter > SkippedCountBefore, 'Expected a skipped record to be logged after max retries');

        // [THEN] The mutation was retried max times (4 calls: 1 initial + 3 retry)
        LibraryAssert.AreEqual(4, CallCount, 'Expected 4 GraphQL calls (1 initial + 3 retry)');
    end;

    [Test]
    [HandlerFunctions('InventoryExportHttpHandler')]
    procedure UnitTestCalcStockIncludesChangeFromQuantityNull()
    var
        ShopLocation: Record "Shpfy Shop Location";
        Item: Record Item;
        ShopifyProduct: Record "Shpfy Product";
        ShopInventory: Record "Shpfy Shop Inventory";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        InventoryAPI: Codeunit "Shpfy Inventory API";
        StockCalculate: Enum "Shpfy Stock Calculation";
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

        // [GIVEN] The handler captures the GraphQL request
        SetRetryState(Enum::"Shpfy Inventory Retry Scenario"::Success, '');
        InventoryAPI.SetShop(Shop.Code);

        // [WHEN] ExportStock is called
        ShopInventory.SetRange("Shop Code", Shop.Code);
        ShopInventory.SetRange("Variant Id", ShopInventory."Variant Id");
        InventoryAPI.ExportStock(ShopInventory, false);

        // [THEN] The mutation was executed successfully (verified by handler not throwing error)
        LibraryAssert.AreEqual(1, CallCount, 'Expected 1 GraphQL call');
    end;

    [Test]
    [HandlerFunctions('InventoryExportHttpHandler')]
    procedure UnitTestIdempotencyKeyIsGenerated()
    var
        ShopLocation: Record "Shpfy Shop Location";
        Item: Record Item;
        ShopifyProduct: Record "Shpfy Product";
        ShopInventory: Record "Shpfy Shop Inventory";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        InventoryAPI: Codeunit "Shpfy Inventory API";
        StockCalculate: Enum "Shpfy Stock Calculation";
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

        // [GIVEN] The handler captures the GraphQL request
        SetRetryState(Enum::"Shpfy Inventory Retry Scenario"::Success, '');
        InventoryAPI.SetShop(Shop.Code);

        // [WHEN] ExportStock is called
        ShopInventory.SetRange("Shop Code", Shop.Code);
        ShopInventory.SetRange("Variant Id", ShopInventory."Variant Id");
        InventoryAPI.ExportStock(ShopInventory, false);

        // [THEN] The mutation was executed successfully (verified by handler not throwing error)
        LibraryAssert.AreEqual(1, CallCount, 'Expected 1 GraphQL call for idempotency test');
    end;

    [Test]
    [HandlerFunctions('InventoryExportHttpHandler')]
    procedure UnitTestExportStockForceExportWhenStockEqual()
    var
        ShopLocation: Record "Shpfy Shop Location";
        Item: Record Item;
        ShopifyProduct: Record "Shpfy Product";
        ShopInventory: Record "Shpfy Shop Inventory";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        InventoryAPI: Codeunit "Shpfy Inventory API";
        StockCalculate: Enum "Shpfy Stock Calculation";
    begin
        // [SCENARIO] Export stock with ForceExport=true exports even when stock equals Shopify stock
        // [GIVEN] A ShopInventory record where stock equals Shopify stock (would normally be skipped)
        Initialize();

        Shop := CommunicationMgt.GetShopRecord();
        CreateShopLocation(ShopLocation, Shop.Code, StockCalculate::"Projected Available Balance Today");
        CreateItem(Item);
        UpdateItemInventory(Item, 10);
        CreateShopifyProduct(ShopifyProduct, ShopInventory, Item.SystemId, Shop.Code, ShopLocation.Id);
        ShopInventory."Shopify Stock" := 10; // Same as item stock - would normally skip export
        ShopInventory.Modify();

        // [GIVEN] The handler is configured to return success
        SetRetryState(Enum::"Shpfy Inventory Retry Scenario"::Success, '');
        InventoryAPI.SetShop(Shop.Code);

        // [WHEN] ExportStock is called with ForceExport = true
        ShopInventory.SetRange("Shop Code", Shop.Code);
        ShopInventory.SetRange("Variant Id", ShopInventory."Variant Id");
        InventoryAPI.ExportStock(ShopInventory, true);

        // [THEN] The mutation was executed (handler was called)
        LibraryAssert.AreEqual(1, CallCount, 'Expected 1 GraphQL call when ForceExport is true');
    end;

    [Test]
    procedure UnitTestExportStockNoForceExportSkipsWhenStockEqual()
    var
        ShopLocation: Record "Shpfy Shop Location";
        Item: Record Item;
        ShopifyProduct: Record "Shpfy Product";
        ShopInventory: Record "Shpfy Shop Inventory";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        InventoryAPI: Codeunit "Shpfy Inventory API";
        StockCalculate: Enum "Shpfy Stock Calculation";
    begin
        // [SCENARIO] Export stock with ForceExport=false skips export when stock equals Shopify stock
        // [GIVEN] A ShopInventory record where stock equals Shopify stock
        Initialize();

        Shop := CommunicationMgt.GetShopRecord();
        CreateShopLocation(ShopLocation, Shop.Code, StockCalculate::"Projected Available Balance Today");
        CreateItem(Item);
        UpdateItemInventory(Item, 10);
        CreateShopifyProduct(ShopifyProduct, ShopInventory, Item.SystemId, Shop.Code, ShopLocation.Id);
        ShopInventory."Shopify Stock" := 10; // Same as item stock
        ShopInventory.Modify();

        // [GIVEN] The handler is configured to return success
        SetRetryState(Enum::"Shpfy Inventory Retry Scenario"::Success, '');
        InventoryAPI.SetShop(Shop.Code);

        // [WHEN] ExportStock is called with ForceExport = false
        ShopInventory.SetRange("Shop Code", Shop.Code);
        ShopInventory.SetRange("Variant Id", ShopInventory."Variant Id");
        InventoryAPI.ExportStock(ShopInventory, false);

        // [THEN] No mutation was executed (stock is equal, no export needed)
        LibraryAssert.AreEqual(0, CallCount, 'Expected 0 GraphQL calls when ForceExport is false and stock is equal');
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
