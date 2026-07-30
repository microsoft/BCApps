// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Integration.Shopify;
using Microsoft.Inventory.Intrastat;
using Microsoft.Inventory.Item;
using System.TestLibraries.Utilities;

codeunit 139552 "Shpfy Create Item API Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;
    TestHttpRequestPolicy = BlockOutboundRequests;
    EventSubscriberInstance = Manual;

    var
        Shop: Record "Shpfy Shop";
        LibraryAssert: Codeunit "Library Assert";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        OutboundHttpRequests: Codeunit "Library - Variable Storage";
        ShpfyCreateItemAPITest: Codeunit "Shpfy Create Item API Test";
        InitializeTest: Codeunit "Shpfy Initialize Test";
        IsInitialized: Boolean;
        ProductId: BigInteger;
        VariantId: BigInteger;
        CreateItemErr: Label 'Item not created', Locked = true;
        UnexpectedAPICallsErr: Label 'More than expected API calls to Shopify detected.';
        AutoCreateUnknownItemsDisabledErr: Label 'Auto Create Unknown Item must be enabled and an Item Template must be selected for the shop.';

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    [Test]
    [HandlerFunctions('GetProductsHttpHandler')]
    procedure UnitTestErrorClearOnSuccessfulItemCreation()
    var
        Product: Record "Shpfy Product";
        ShopifyVariant: Record "Shpfy Variant";
        ProductInitTest: Codeunit "Shpfy Product Init Test";
        CreateItem: Codeunit "Shpfy Create Item";
        EmptyGuid: Guid;
    begin
        Initialize();

        // [SCENARIO] Clear error on Shopify Product when Item from a Shopify Product creation is successful.

        // [GIVEN] Register Expected Outbound API Requests.
        RegExpectedOutboundHttpRequestsForGetProducts();

        // [GIVEN] A Shopify variant record of a standard shopify product. (The variant record always exists, even if the products don't have any variants.)
        ShopifyVariant := ProductInitTest.CreateStandardProduct(Shop);
        ProductId := ShopifyVariant."Product Id";
        VariantId := ShopifyVariant."Id";

        // [GIVEN] A Shopify product record has error logged.
        Product.Get(ShopifyVariant."Product Id");
        Product."Has Error" := true;
        Product."Error Message" := CreateItemErr;
        Product.Modify(false);

        // [WHEN] Invoke ShpfyCreateItem.CreateItemFromShopifyProduct to create items from Shopify product.
        CreateItem.CreateItemFromShopifyProduct(Product);

        // [THEN] On the "Shpfy Product" record, the field "Item SystemId" must be filled.
        Product.Get(ShopifyVariant."Product Id");
        LibraryAssert.AreNotEqual(Product."Item SystemId", EmptyGuid, '"Item SystemId" value must not be empty');

        // [THEN] On the "Shpfy Product" record, the field "Has Error" must have value false.
        LibraryAssert.IsFalse(Product."Has Error", '"Has Error" value must be false');

        // [THEN] On the "Shpfy Product" record, the field "Error Message" must be empty.
        LibraryAssert.AreEqual(Product."Error Message", '', '"Error Message" value must be empty');
    end;

    [Test]
    [HandlerFunctions('GetProductsHttpHandler')]
    procedure UnitTestLogErrorOnUnsuccessfulItemCreation()
    var
        Product: Record "Shpfy Product";
        ShopifyVariant: Record "Shpfy Variant";
        ProductInitTest: Codeunit "Shpfy Product Init Test";
        CreateItem: Codeunit "Shpfy Create Item";
        EmptyGuid: Guid;
    begin
        Initialize();

        // [SCENARIO] Inserts error on Shopify Product when Item from a Shopify Product creation is unsuccessful.

        // [GIVEN] Register Expected Outbound API Requests.
        RegExpectedOutboundHttpRequestsForGetProducts();

        // [GIVEN] A Shopify variant record of a standard shopify product. (The variant record always exists, even if the products don't have any variants.)
        ShopifyVariant := ProductInitTest.CreateStandardProduct(Shop);
        ProductId := ShopifyVariant."Product Id";
        VariantId := ShopifyVariant."Id";

        // [WHEN] Invoke ShpfyCreateItem.CreateItemFromShopifyProduct to unsuccessfully create item from Shopify product.
        Product.Get(ShopifyVariant."Product Id");
        BindSubscription(ShpfyCreateItemAPITest);
        CreateItem.CreateItemFromShopifyProduct(Product);
        UnbindSubscription(ShpfyCreateItemAPITest);

        // [THEN] On the "Shpfy Product" record, the field "Item SystemId" must be empty.
        Product.Get(ShopifyVariant."Product Id");
        LibraryAssert.AreEqual(Product."Item SystemId", EmptyGuid, '"Item SystemId" value must be empty');

        // [THEN] On the "Shpfy Product" record, the field "Has Error" must have value true.
        LibraryAssert.IsTrue(Product."Has Error", '"Has Error" value must be true');

        // [THEN] On the "Shpfy Product" record, the field "Error Message" must be filled.
        LibraryAssert.IsTrue(Product."Error Message".contains(CreateItemErr), '"Error Message" must contain error text');
    end;

    [Test]
    [HandlerFunctions('GetProductsHttpHandler')]
    procedure UnitTestLogErrorOnSetttingDisabledItemCreation()
    var
        Product: Record "Shpfy Product";
        ShopifyVariant: Record "Shpfy Variant";
        ProductInitTest: Codeunit "Shpfy Product Init Test";
        CreateItem: Codeunit "Shpfy Create Item";
        EmptyGuid: Guid;
    begin
        Initialize();

        // [SCENARIO] Inserts error on Shopify Product when Item from a Shopify Product creation is unsuccessful.

        // [GIVEN] Register Expected Outbound API Requests.
        RegExpectedOutboundHttpRequestsForGetProducts();
        Shop."Auto Create Unknown Items" := false;
        Shop.Modify(false);

        // [GIVEN] A Shopify variant record of a standard shopify product. (The variant record always exists, even if the products don't have any variants.)
        ShopifyVariant := ProductInitTest.CreateStandardProduct(Shop);
        ProductId := ShopifyVariant."Product Id";
        VariantId := ShopifyVariant."Id";

        // [WHEN] Invoke ShpfyCreateItem.CreateItemFromShopifyProduct to unsuccessfully create item from Shopify product.
        Product.Get(ShopifyVariant."Product Id");
        CreateItem.CreateItemFromShopifyProduct(Product);

        // [THEN] On the "Shpfy Product" record, the field "Item SystemId" must be empty.
        Product.Get(ShopifyVariant."Product Id");
        LibraryAssert.AreEqual(Product."Item SystemId", EmptyGuid, '"Item SystemId" value must be empty');

        // [THEN] On the "Shpfy Product" record, the field "Has Error" must have value true.
        LibraryAssert.IsTrue(Product."Has Error", '"Has Error" value must be true');

        // [THEN] On the "Shpfy Product" record, the field "Error Message" must be filled.
        LibraryAssert.IsTrue(Product."Error Message".contains(AutoCreateUnknownItemsDisabledErr), '"Error Message" must contain error text');
    end;

    [Test]
    [HandlerFunctions('GetProductsHttpHandler')]
    procedure UnitTestImportProductSyncsHSCodeAndCountryOfOrigin()
    var
        Product: Record "Shpfy Product";
        Item: Record Item;
        ShopifyVariant: Record "Shpfy Variant";
        ProductInitTest: Codeunit "Shpfy Product Init Test";
        CreateItem: Codeunit "Shpfy Create Item";
    begin
        Initialize();

        // [SCENARIO 642046] Importing a product from Shopify imports the HS code (Tariff No.) and Country/Region of Origin onto the Shopify variant and the created item, matching a BC Tariff Number even though Shopify returns the code without separators.

        // [GIVEN] A shop with "Sync HS Code and Country" enabled.
        Shop."Auto Create Unknown Items" := true;
        Shop."Sync HS Code and Country" := true;
        Shop.Modify(false);

        // [GIVEN] A BC Tariff Number stored with a separator, matching the digits Shopify returns ("610443").
        CreateTariffNumber('6104.43');

        // [GIVEN] Register Expected Outbound API Requests.
        RegExpectedOutboundHttpRequestsForGetProducts();

        // [GIVEN] A Shopify variant record of a standard shopify product. (The variant record always exists, even if the products don't have any variants.)
        ShopifyVariant := ProductInitTest.CreateStandardProduct(Shop);
        ProductId := ShopifyVariant."Product Id";
        VariantId := ShopifyVariant."Id";

        // [WHEN] Invoke ShpfyCreateItem.CreateItemFromShopifyProduct to import the product details and create the item.
        Product.Get(ShopifyVariant."Product Id");
        CreateItem.CreateItemFromShopifyProduct(Product);

        // [THEN] The Shopify variant mirrors the separator-less HS code and the Country/Region of Origin Code from Shopify.
        ShopifyVariant.Get(VariantId);
        LibraryAssert.AreEqual('610443', ShopifyVariant."Tariff No.", 'Variant "Tariff No." must mirror the separator-less HS code from Shopify.');
        LibraryAssert.AreEqual('US', ShopifyVariant."Country/Region of Origin Code", 'Variant "Country/Region of Origin Code" must be imported from Shopify.');

        // [THEN] The created item is matched to the BC Tariff Number stored with a separator.
        Product.Get(ShopifyVariant."Product Id");
        LibraryAssert.IsTrue(Item.GetBySystemId(Product."Item SystemId"), 'Get Item');
        LibraryAssert.AreEqual('6104.43', Item."Tariff No.", 'Item "Tariff No." must match the BC Tariff Number.');
    end;

    local procedure CreateTariffNumber(No: Code[20])
    var
        TariffNumber: Record "Tariff Number";
    begin
        if not TariffNumber.Get(No) then begin
            TariffNumber.Init();
            TariffNumber."No." := No;
            TariffNumber.Insert();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Product Events", OnBeforeCreateItem, '', true, false)]
    local procedure OnBeforeCreateItem()
    begin
        Error(CreateItemErr);
    end;

    [HttpClientHandler]
    internal procedure GetProductsHttpHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    var
        ProductResponseTok: Label 'Products/ProductDetailsResponse.txt', Locked = true;
        ProductVariantsResponseTok: Label 'Products/ProductVariantsResponse.txt', Locked = true;
        ProductVariantResponseTok: Label 'Products/ProductVariantDetailsResponse.txt', Locked = true;
    begin
        if not InitializeTest.VerifyRequestUrl(Request.Path, Shop."Shopify URL") then
            exit(true);

        case OutboundHttpRequests.Length() of
            3:
                LoadResourceIntoHttpResponse(ProductResponseTok, Response);
            2:
                LoadProductVariantsHttpResponse(ProductVariantsResponseTok, Response);
            1:
                LoadProductVariantHttpResponse(ProductVariantResponseTok, Response);
            0:
                Error(UnexpectedAPICallsErr);
        end;
        exit(false);
    end;

    local procedure Initialize()
    var
        AccessToken: SecretText;
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Shpfy Create Item API Test");
        ClearLastError();
        OutboundHttpRequests.Clear();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Shpfy Create Item API Test");

        LibraryRandom.Init();

        IsInitialized := true;
        Commit();

        // Creating Shopify Shop
        Shop := InitializeTest.CreateShop();
        Shop."Auto Create Unknown Items" := true;
        Shop.Modify(false);

        //Register Shopify Access Token
        AccessToken := LibraryRandom.RandText(20);
        InitializeTest.RegisterAccessTokenForShop(Shop.GetStoreName(), AccessToken);

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Shpfy Create Item API Test");
    end;

    local procedure RegExpectedOutboundHttpRequestsForGetProducts()
    begin
        OutboundHttpRequests.Enqueue('GQL Get Product Details');
        OutboundHttpRequests.Enqueue('GQL Get Product Variants');
        OutboundHttpRequests.Enqueue('GQL Get Product Variant Details');
    end;

    local procedure LoadResourceIntoHttpResponse(ResourceText: Text; var Response: TestHttpResponseMessage)
    begin
        Response.Content.WriteFrom(NavApp.GetResourceAsText(ResourceText, TextEncoding::UTF8));
        OutboundHttpRequests.DequeueText();
    end;

    local procedure LoadProductVariantHttpResponse(ResourceText: Text; var Response: TestHttpResponseMessage)
    var
        ResultTxt: Text;
    begin
        ResultTxt := NavApp.GetResourceAsText(ResourceText, TextEncoding::UTF8);
        ResultTxt := ResultTxt.Replace('{{ProductId}}', ProductId.ToText());
        Response.Content.WriteFrom(ResultTxt);
        OutboundHttpRequests.DequeueText();
    end;

    local procedure LoadProductVariantsHttpResponse(ResourceText: Text; var Response: TestHttpResponseMessage)
    var
        ResultTxt: Text;
    begin
        ResultTxt := NavApp.GetResourceAsText(ResourceText, TextEncoding::UTF8);
        ResultTxt := ResultTxt.Replace('{{ProductId}}', ProductId.ToText());
        ResultTxt := ResultTxt.Replace('{{VariantId}}', VariantId.ToText());
        Response.Content.WriteFrom(ResultTxt);
        OutboundHttpRequests.DequeueText();
    end;
}
