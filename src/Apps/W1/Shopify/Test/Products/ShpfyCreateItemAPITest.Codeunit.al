// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Integration.Shopify;
using System.TestLibraries.Utilities;
using System.Utilities;

codeunit 139544 "Shpfy Create Item API Test"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestHttpRequestPolicy = BlockOutboundRequests;
    EventSubscriberInstance = Manual;

    var
        LibraryAssert: Codeunit "Library Assert";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        OutboundHttpRequests: Codeunit "Library - Variable Storage";
        ShpfyCreateItemAPITest: Codeunit "Shpfy Create Item API Test";
        IsInitialized: Boolean;
        ShopCode: Code[20];
        ProductId: BigInteger;
        VariantId: BigInteger;
        CreateItemErr: Label 'Item not created', Locked = true;
        UnexpectedAPICallsErr: Label 'More than expected API calls to Shopify detected.';
        ShopifyShopUrlTok: Label 'admin\/api\/.+\/graphql.json', Locked = true;

    trigger OnRun()
    begin
        this.IsInitialized := false;
    end;

    [Test]
    [HandlerFunctions('GetProductsHttpHandler')]
    procedure UnitTestErrorClearOnSuccessfulItemCreation()
    var
        Shop: Record "Shpfy Shop";
        Product: Record "Shpfy Product";
        ShopifyVariant: Record "Shpfy Variant";
        ProductInitTest: Codeunit "Shpfy Product Init Test";
        CreateItem: Codeunit "Shpfy Create Item";
        EmptyGuid: Guid;
    begin
        this.Initialize();

        // [SCENARIO] Clear error on Shopify Product when Item from a Shopify Product creation is successful.

        // [GIVEN] Register Expected Outbound API Requests.
        this.RegExpectedOutboundHttpRequestsForGetProducts();

        // [GIVEN] A Shopify variant record of a standard shopify product. (The variant record always exists, even if the products don't have any variants.)
        Shop.Get(this.ShopCode);
        ShopifyVariant := ProductInitTest.CreateStandardProduct(Shop);
        this.ProductId := ShopifyVariant."Product Id";
        this.VariantId := ShopifyVariant."Id";

        // [GIVEN] A Shopify product record has error logged.
        Product.Get(ShopifyVariant."Product Id");
        Product."Has Error" := true;
        Product."Error Message" := this.CreateItemErr;
        Product.Modify(false);

        // [WHEN] Invoke ShpfyCreateItem.CreateItemFromShopifyProduct to create items from Shopify product.
        CreateItem.CreateItemFromShopifyProduct(Product);

        // [THEN] On the "Shpfy Product" record, the field "Item SystemId" must be filled.
        Product.Get(ShopifyVariant."Product Id");
        this.LibraryAssert.AreNotEqual(Product."Item SystemId", EmptyGuid, '"Item SystemId" value must not be empty');

        // [THEN] On the "Shpfy Product" record, the field "Has Error" must have value false.
        this.LibraryAssert.IsFalse(Product."Has Error", '"Has Error" value must be false');

        // [THEN] On the "Shpfy Product" record, the field "Error Message" must be empty.
        this.LibraryAssert.AreEqual(Product."Error Message", '', '"Error Message" value must be empty');
    end;

    [Test]
    [HandlerFunctions('GetProductsHttpHandler')]
    procedure UnitTestLogErrorOnUnsuccessfulItemCreation()
    var
        Shop: Record "Shpfy Shop";
        Product: Record "Shpfy Product";
        ShopifyVariant: Record "Shpfy Variant";
        ProductInitTest: Codeunit "Shpfy Product Init Test";
        CreateItem: Codeunit "Shpfy Create Item";
        EmptyGuid: Guid;
    begin
        this.Initialize();

        // [SCENARIO] Inserts error on Shopify Product when Item from a Shopify Product creation is unsuccessful.

        // [GIVEN] Register Expected Outbound API Requests.
        this.RegExpectedOutboundHttpRequestsForGetProducts();

        // [GIVEN] A Shopify variant record of a standard shopify product. (The variant record always exists, even if the products don't have any variants.)
        Shop.Get(this.ShopCode);
        ShopifyVariant := ProductInitTest.CreateStandardProduct(Shop);
        this.ProductId := ShopifyVariant."Product Id";
        this.VariantId := ShopifyVariant."Id";

        // [WHEN] Invoke ShpfyCreateItem.CreateItemFromShopifyProduct to unsuccessfully create item from Shopify product.
        Product.Get(ShopifyVariant."Product Id");
        BindSubscription(this.ShpfyCreateItemAPITest);
        CreateItem.CreateItemFromShopifyProduct(Product);
        UnbindSubscription(this.ShpfyCreateItemAPITest);

        // [THEN] On the "Shpfy Product" record, the field "Item SystemId" must be empty.
        Product.Get(ShopifyVariant."Product Id");
        this.LibraryAssert.AreEqual(Product."Item SystemId", EmptyGuid, '"Item SystemId" value must be empty');

        // [THEN] On the "Shpfy Product" record, the field "Has Error" must have value true.
        this.LibraryAssert.IsTrue(Product."Has Error", '"Has Error" value must be true');

        // [THEN] On the "Shpfy Product" record, the field "Error Message" must be filled.
        this.LibraryAssert.IsTrue(Product."Error Message".contains(this.CreateItemErr), '"Error Message" must contain error text');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Product Events", OnBeforeCreateItem, '', true, false)]
    local procedure OnBeforeCreateItem()
    begin
        Error(this.CreateItemErr);
    end;

    [HttpClientHandler]
    internal procedure GetProductsHttpHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    var
        Regex: Codeunit Regex;
        ProductResponseTok: Label 'Products/ProductDetailsResponse.txt', Locked = true;
        ProductVariantsResponseTok: Label 'Products/ProductVariantsResponse.txt', Locked = true;
        ProductVariantResponseTok: Label 'Products/ProductVariantDetailsResponse.txt', Locked = true;
    begin
        if not Regex.IsMatch(Request.Path, this.ShopifyShopUrlTok) then
            exit(true);

        case this.OutboundHttpRequests.Length() of
            3:
                this.LoadResourceIntoHttpResponse(ProductResponseTok, Response);
            2:
                this.LoadProductVariantsHttpResponse(ProductVariantsResponseTok, Response);
            1:
                this.LoadProductVariantHttpResponse(ProductVariantResponseTok, Response);
            0:
                Error(this.UnexpectedAPICallsErr);
        end;
        exit(false);
    end;

    local procedure Initialize()
    var
        Shop: Record "Shpfy Shop";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        InitializeTest: Codeunit "Shpfy Initialize Test";
        AccessToken: SecretText;
    begin
        this.LibraryTestInitialize.OnTestInitialize(Codeunit::"Shpfy Create Item API Test");
        ClearLastError();
        this.OutboundHttpRequests.Clear();
        if this.IsInitialized then
            exit;

        this.LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Shpfy Create Item API Test");

        this.LibraryRandom.Init();

        this.IsInitialized := true;
        Commit();

        // Creating Shopify Shop
        Shop := InitializeTest.CreateShop();
        Shop."Auto Create Unknown Items" := true;
        Shop.Modify(false);

        this.ShopCode := Shop.Code;
        // Disable Event Mocking 
        CommunicationMgt.SetTestInProgress(false);
        //Register Shopify Access Token
        AccessToken := this.LibraryRandom.RandText(20);
        InitializeTest.RegisterAccessTokenForShop(Shop.GetStoreName(), AccessToken);

        this.LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Shpfy Create Item API Test");
    end;

    local procedure RegExpectedOutboundHttpRequestsForGetProducts()
    begin
        this.OutboundHttpRequests.Enqueue('GQL Get Product Details');
        this.OutboundHttpRequests.Enqueue('GQL Get Product Variants');
        this.OutboundHttpRequests.Enqueue('GQL Get Product Variant Details');
    end;

    local procedure LoadResourceIntoHttpResponse(ResourceText: Text; var Response: TestHttpResponseMessage)
    begin
        Response.Content.WriteFrom(NavApp.GetResourceAsText(ResourceText, TextEncoding::UTF8));
        this.OutboundHttpRequests.DequeueText();
    end;

    local procedure LoadProductVariantHttpResponse(ResourceText: Text; var Response: TestHttpResponseMessage)
    var
        ResultTxt: Text;
    begin
        ResultTxt := NavApp.GetResourceAsText(ResourceText, TextEncoding::UTF8);
        ResultTxt := ResultTxt.Replace('{{ProductId}}', this.ProductId.ToText());
        Response.Content.WriteFrom(ResultTxt);
        this.OutboundHttpRequests.DequeueText();
    end;

    local procedure LoadProductVariantsHttpResponse(ResourceText: Text; var Response: TestHttpResponseMessage)
    var
        ResultTxt: Text;
    begin
        ResultTxt := NavApp.GetResourceAsText(ResourceText, TextEncoding::UTF8);
        ResultTxt := ResultTxt.Replace('{{ProductId}}', this.ProductId.ToText());
        ResultTxt := ResultTxt.Replace('{{VariantId}}', this.VariantId.ToText());
        Response.Content.WriteFrom(ResultTxt);
        this.OutboundHttpRequests.DequeueText();
    end;
}
