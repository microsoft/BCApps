// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Integration.Shopify;
using Microsoft.Inventory.Item;
using System.TestLibraries.Utilities;

codeunit 134247 "Shpfy Market Catalog API Test"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestHttpRequestPolicy = BlockOutboundRequests;
    TestType = IntegrationTest;

    var
        Shop: Record "Shpfy Shop";
        LibraryAssert: Codeunit "Library Assert";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        OutboundHttpRequests: Codeunit "Library - Variable Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        InitializeTest: Codeunit "Shpfy Initialize Test";
        IsInitialized: Boolean;
        UnexpectedAPICallsErr: Label 'More than expected API calls to Shopify detected.';

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    [Test]
    [HandlerFunctions('HttpSubmitHandler_GetMarketCatalogs')]
    procedure UnitTestExtractShopifyMarketCatalogs()
    var
        Catalog: Record "Shpfy Catalog";
        CatalogAPI: Codeunit "Shpfy Catalog API";
    begin
        Initialize();

        // [SCENARIO] Get Market Catalogs and linked markets from the Shopify.

        // [GIVEN] Market Catalogs and Linked Catalog Markets JResponses

        // [GIVEN] Register Expected Outbound API Requests
        RegExpectedOutboundHttpRequestsForGetMarketCatalogs();

        // [WHEN] Invoke CatalogAPI.GetMarketCatalogs to get Market Catalogs and linked markets
        CatalogAPI.SetShop(Shop);
        CatalogAPI.GetMarketCatalogs();

        // [THEN] Verify that market catalogs are created
        Catalog.SetRange("Catalog Type", Catalog."Catalog Type"::Market);
        Catalog.SetRange("Shop Code", Shop.Code);
        LibraryAssert.AreEqual(3, Catalog.Count(), 'Incorrect number of Market Catalogs has been created');

        // [THEN] Verify that all expected outbound HTTP requests were executed
        OutboundHttpRequests.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('HttpSubmitHandler_UpdateCatalogPrices')]
    procedure UnitTestSynchronizeMarketCatalogPrices()
    var
        Catalog: Record "Shpfy Catalog";
        SyncCatalogPrices: Codeunit "Shpfy Sync Catalog Prices";
    begin
        Initialize();

        // [SCENARIO] Synchronize Market Catalog Prices from the Business Central.

        // [GIVEN] Market Catalogs and Linked Catalog Markets JResponses

        // [GIVEN] Shopify Products and Pruduct Variants
        CreateProductsWithVariants(Shop);

        // [GIVEN] Create Market Catalog
        CreateMarketCatalog(Catalog, Shop);
        Catalog."Currency Code" := 'RSD';
        Catalog.Modify();

        // [GIVEN] Register Expected Outbound API Requests for Catalog Prices Synchronization
        RegExpectedOutboundHttpRequestsForSyncCatalogPrices();

        // [WHEN] Invoke CatalogAPI.SynchronizeMarketCatalogPrices to synchronize Market Catalog Prices
        SyncCatalogPrices.SetCatalogType("Shpfy Catalog Type"::Market);
        SyncCatalogPrices.SyncCatalogPrices(Catalog);

        // [THEN] Verify that all expected outbound HTTP requests were executed
        LibraryAssert.IsTrue(OutboundHttpRequests.Length() = 0, 'Not all Http requests were executed');
    end;

    [Test]
    [HandlerFunctions('HttpSubmitHandler_GetMarketCatalogs')]
    procedure UnitTestExtractShopifyMarketCatalogCurrency()
    var
        Catalog: Record "Shpfy Catalog";
        GeneralLedgerSetup: Record "General Ledger Setup";
        CatalogAPI: Codeunit "Shpfy Catalog API";
    begin
        Initialize();
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."LCY Code" := 'EUR';
        GeneralLedgerSetup.Modify();
        Catalog.DeleteAll();

        // [SCENARIO] Get Market Catalogs and linked markets from the Shopify.

        // [GIVEN] Market Catalogs and Linked Catalog Markets JResponses

        // [GIVEN] Register Expected Outbound API Requests
        RegExpectedOutboundHttpRequestsForGetMarketCatalogs();

        // [WHEN] Invoke CatalogAPI.GetMarketCatalogs to get Market Catalogs and linked markets
        CatalogAPI.SetShop(Shop);
        CatalogAPI.GetMarketCatalogs();

        // [THEN] Verify that market catalogs are created
        Catalog.SetRange("Catalog Type", Catalog."Catalog Type"::Market);
        Catalog.SetRange("Shop Code", Shop.Code);
        LibraryAssert.AreEqual(3, Catalog.Count(), 'Incorrect number of Market Catalogs has been created');

        // [THEN] Two catalogs with empty currency code (LCY), one with RSD
        Catalog.SetRange("Currency Code", '');
        LibraryAssert.AreEqual(2, Catalog.Count(), 'Incorrect number of Market Catalogs with empty currency code has been created');
        Catalog.SetRange("Currency Code", 'RSD');
        LibraryAssert.AreEqual(1, Catalog.Count(), 'Incorrect number of Market Catalogs with RSD currency code has been created');

        // [THEN] Verify that all expected outbound HTTP requests were executed
        OutboundHttpRequests.AssertEmpty();
    end;

    [HttpClientHandler]
    internal procedure HttpSubmitHandler_GetMarketCatalogs(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    var
        MarketCatalogsResponseTok: Label 'Catalogs/MarketCatalogResponse.txt', Locked = true;
        CatalogMarketsResponse1Tok: Label 'Catalogs/CatalogMarkets1.txt', Locked = true;
        CatalogMarketsResponse2Tok: Label 'Catalogs/CatalogMarkets2.txt', Locked = true;
        CatalogMarketsResponse3Tok: Label 'Catalogs/CatalogMarkets3.txt', Locked = true;
    begin
        if not InitializeTest.VerifyRequestUrl(Request.Path, Shop."Shopify URL") then
            exit(true);

        case OutboundHttpRequests.Length() of
            4:
                LoadResourceIntoHttpResponse(MarketCatalogsResponseTok, Response);
            3:
                LoadResourceIntoHttpResponse(CatalogMarketsResponse1Tok, Response);
            2:
                LoadResourceIntoHttpResponse(CatalogMarketsResponse2Tok, Response);
            1:
                LoadResourceIntoHttpResponse(CatalogMarketsResponse3Tok, Response);
            0:
                Error(UnexpectedAPICallsErr);
        end;
        exit(false);
    end;

    [HttpClientHandler]
    internal procedure HttpSubmitHandler_UpdateCatalogPrices(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    var
        CatalogProductsResponseTok: Label 'Catalogs/CatalogProducts.txt', Locked = true;
        CatalogPricesResponseTok: Label 'Catalogs/CatalogPrices.txt', Locked = true;
        CatalogPriceUpdateResponseTok: Label 'Catalogs/CatalogPricesUpdate.txt', Locked = true;
    begin
        if not InitializeTest.VerifyRequestUrl(Request.Path, Shop."Shopify URL") then
            exit(true);

        case OutboundHttpRequests.Length() of
            3:
                LoadCatalogProductsHttpResponse(CatalogProductsResponseTok, Response);
            2:
                LoadCatalogProductsPriceListHttpResponse(CatalogPricesResponseTok, Response);
            1:
                LoadResourceIntoHttpResponse(CatalogPriceUpdateResponseTok, Response);
            0:
                Error(UnexpectedAPICallsErr);
        end;
        exit(false);
    end;

    local procedure Initialize()
    var
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        AccessToken: SecretText;
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Shpfy Market Catalog API Test");
        ClearLastError();
        OutboundHttpRequests.Clear();
        LibraryVariableStorage.Clear();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Shpfy Market Catalog API Test");

        LibraryRandom.Init();

        IsInitialized := true;
        Commit();

        // Creating Shopify Shop
        Shop := InitializeTest.CreateShop();
        // Disable Event Mocking 
        CommunicationMgt.SetTestInProgress(false);
        //Register Shopify Access Token
        AccessToken := LibraryRandom.RandText(20);
        InitializeTest.RegisterAccessTokenForShop(Shop.GetStoreName(), AccessToken);

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Shpfy Market Catalog API Test");
    end;

    local procedure RegExpectedOutboundHttpRequestsForGetMarketCatalogs()
    begin
        OutboundHttpRequests.Enqueue('GQL Get Catalogs');
        OutboundHttpRequests.Enqueue('GQL Get Catalog Markets 1');
        OutboundHttpRequests.Enqueue('GQL Get Catalog Markets 2');
        OutboundHttpRequests.Enqueue('GQL Get Catalog Markets 3');
    end;

    local procedure RegExpectedOutboundHttpRequestsForSyncCatalogPrices()
    begin
        OutboundHttpRequests.Enqueue('GQL Get Catalog Products');
        OutboundHttpRequests.Enqueue('GQL Get Catalog Prices');
        OutboundHttpRequests.Enqueue('GQL Update Catalog Prices');
    end;

    local procedure LoadResourceIntoHttpResponse(ResourceText: Text; var Response: TestHttpResponseMessage)
    begin
        Response.Content.WriteFrom(NavApp.GetResourceAsText(ResourceText, TextEncoding::UTF8));
        OutboundHttpRequests.DequeueText();
    end;

    local procedure LoadCatalogProductsHttpResponse(ResourceText: Text; var Response: TestHttpResponseMessage)
    var
        ResultTxt: Text;
    begin
        ResultTxt := NavApp.GetResourceAsText(ResourceText, TextEncoding::UTF8);
        ResultTxt := ResultTxt.Replace('{{ProductId1}}', GetIdValueFromVariableStorage(1));
        ResultTxt := ResultTxt.Replace('{{ProductId2}}', GetIdValueFromVariableStorage(3));
        ResultTxt := ResultTxt.Replace('{{ProductId3}}', GetIdValueFromVariableStorage(5));
        Response.Content.WriteFrom(ResultTxt);
        OutboundHttpRequests.DequeueText();
    end;

    local procedure LoadCatalogProductsPriceListHttpResponse(ResourceText: Text; var Response: TestHttpResponseMessage)
    var
        ResultTxt: Text;
    begin
        ResultTxt := NavApp.GetResourceAsText(ResourceText, TextEncoding::UTF8);
        ResultTxt := ResultTxt.Replace('{{ProductId1}}', GetIdValueFromVariableStorage(1));
        ResultTxt := ResultTxt.Replace('{{ProductVariantId1}}', GetIdValueFromVariableStorage(2));
        ResultTxt := ResultTxt.Replace('{{ProductId2}}', GetIdValueFromVariableStorage(3));
        ResultTxt := ResultTxt.Replace('{{ProductVariantId2}}', GetIdValueFromVariableStorage(4));
        ResultTxt := ResultTxt.Replace('{{ProductId3}}', GetIdValueFromVariableStorage(5));
        ResultTxt := ResultTxt.Replace('{{ProductVariantId3}}', GetIdValueFromVariableStorage(6));
        Response.Content.WriteFrom(ResultTxt);
        OutboundHttpRequests.DequeueText();
    end;

    local procedure GetIdValueFromVariableStorage(Index: Integer): Text
    var
        IdValue: Variant;
    begin
        LibraryVariableStorage.Peek(IdValue, Index);
        exit(Format(IdValue));
    end;

    local procedure CreateMarketCatalog(var Catalog: Record "Shpfy Catalog"; ShopifyShop: Record "Shpfy Shop")
    var
        CatalogInitialize: Codeunit "Shpfy Catalog Initialize";
    begin
        Catalog := CatalogInitialize.CreateCatalog(Catalog."Catalog Type"::Market);
        Catalog."Shop Code" := ShopifyShop.Code;
        Catalog."Sync Prices" := true;
        Catalog.Modify(false);
    end;

    local procedure CreateProductsWithVariants(ShopifyShop: Record "Shpfy Shop")
    var
        ShopifyVariant: Record "Shpfy Variant";
        ProductInitTest: Codeunit "Shpfy Product Init Test";
        i: Integer;
    begin
        for i := 1 to 3 do begin
            ShopifyVariant := ProductInitTest.CreateStandardProduct(ShopifyShop);
            AssignItemToShopifyVariant(ShopifyVariant);
            LibraryVariableStorage.Enqueue(ShopifyVariant."Product Id");
            LibraryVariableStorage.Enqueue(ShopifyVariant."Id");
        end;
    end;

    local procedure AssignItemToShopifyVariant(var ShopifyVariant: Record "Shpfy Variant")
    var
        Item: Record Item;
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        if not Item.FindFirst() then
            LibraryInventory.CreateItem(Item);
        ShopifyVariant."Item SystemId" := Item.SystemId;
        ShopifyVariant.Modify(false);
    end;
}
