// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Integration.Shopify;
using Microsoft.Inventory.Item;
using System.TestLibraries.Utilities;

codeunit 139632 "Shpfy Create Item Variant Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;
    TestHttpRequestPolicy = BlockOutboundRequests;

    var
        Shop: Record "Shpfy Shop";
        Any: Codeunit Any;
        LibraryAssert: Codeunit "Library Assert";
        OutboundHttpRequests: Codeunit "Library - Variable Storage";
        InitializeTest: Codeunit "Shpfy Initialize Test";
        IsInitialized: Boolean;
        NewVariantId: BigInteger;
        MultipleOptions: Boolean;
        OptionName: Text;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    [Test]
    [HandlerFunctions('CreateItemVariantHttpHandler')]
    procedure UnitTestCreateVariantFromItem()
    var
        Item: Record Item;
        ParentItem: Record "Item";
        ShpfyVariant: Record "Shpfy Variant";
        ShpfyProduct: Record "Shpfy Product";
        ShpfyProductInitTest: Codeunit "Shpfy Product Init Test";
        CreateItemAsVariant: Codeunit "Shpfy Create Item As Variant";
        ParentProductId: BigInteger;
        VariantId: BigInteger;
    begin
        // [SCENARIO] Create a variant from a given item
        Initialize();
        MultipleOptions := false;
        OptionName := '';

        // [GIVEN] Parent Item
        ParentItem := ShpfyProductInitTest.CreateItem(Shop."Item Templ. Code", Any.DecimalInRange(10, 100, 2), Any.DecimalInRange(100, 500, 2));
        // [GIVEN] Shopify product
        ParentProductId := CreateShopifyProduct(ParentItem.SystemId);
        // [GIVEN] Item
        Item := ShpfyProductInitTest.CreateItem(Shop."Item Templ. Code", Any.DecimalInRange(10, 100, 2), Any.DecimalInRange(100, 500, 2));

        // [GIVEN] Register Expected Outbound API Requests.
        OutboundHttpRequests.Clear();
        OutboundHttpRequests.Enqueue('GetOptions');
        OutboundHttpRequests.Enqueue('ProductOptionUpdate');
        OutboundHttpRequests.Enqueue('CreateVariant');

        // [WHEN] Invoke CreateItemAsVariant.CreateVariantFromItem
        CreateItemAsVariant.SetParentProduct(ParentProductId);
        CreateItemAsVariant.CheckProductAndShopSettings();
        CreateItemAsVariant.CreateVariantFromItem(Item);
        VariantId := NewVariantId;

        // [THEN] Variant is created
        LibraryAssert.IsTrue(ShpfyVariant.Get(VariantId), 'Variant not created');
        LibraryAssert.AreEqual(Item."No.", ShpfyVariant.Title, 'Title not set');
        LibraryAssert.AreEqual(Item."No.", ShpfyVariant."Option 1 Value", 'Option 1 Value not set');
        LibraryAssert.AreEqual('Variant', ShpfyVariant."Option 1 Name", 'Option 1 Name not set');
        LibraryAssert.AreEqual(ParentProductId, ShpfyVariant."Product Id", 'Parent product not set');
        LibraryAssert.IsTrue(ShpfyProduct.Get(ParentProductId), 'Parent product not found');
        LibraryAssert.IsTrue(ShpfyProduct."Has Variants", 'Has Variants not set');
    end;

    [Test]
    [HandlerFunctions('CreateItemVariantHttpHandler')]
    procedure UnitTestCreateVariantFromItemWithNonDefaultOption()
    var
        Item: Record Item;
        ParentItem: Record "Item";
        ShpfyVariant: Record "Shpfy Variant";
        ShpfyProduct: Record "Shpfy Product";
        ShpfyProductInitTest: Codeunit "Shpfy Product Init Test";
        CreateItemAsVariant: Codeunit "Shpfy Create Item As Variant";
        ParentProductId: BigInteger;
        VariantId: BigInteger;
    begin
        // [SCENARIO] Create a variant from a given item
        Initialize();
        MultipleOptions := false;

        // [GIVEN] Parent Item
        ParentItem := ShpfyProductInitTest.CreateItem(Shop."Item Templ. Code", Any.DecimalInRange(10, 100, 2), Any.DecimalInRange(100, 500, 2));
        // [GIVEN] Shopify product
        ParentProductId := CreateShopifyProduct(ParentItem.SystemId);
        // [GIVEN] Item
        Item := ShpfyProductInitTest.CreateItem(Shop."Item Templ. Code", Any.DecimalInRange(10, 100, 2), Any.DecimalInRange(100, 500, 2));
        // [GIVEN] Non default option for the product in Shopify
        OptionName := Any.AlphabeticText(10);

        // [GIVEN] Register Expected Outbound API Requests.
        OutboundHttpRequests.Clear();
        OutboundHttpRequests.Enqueue('GetOptions');
        OutboundHttpRequests.Enqueue('CreateVariant');

        // [WHEN] Invoke CreateItemAsVariant.CreateVariantFromItem
        CreateItemAsVariant.SetParentProduct(ParentProductId);
        CreateItemAsVariant.CheckProductAndShopSettings();
        CreateItemAsVariant.CreateVariantFromItem(Item);
        VariantId := NewVariantId;

        // [THEN] Variant is created
        LibraryAssert.IsTrue(ShpfyVariant.Get(VariantId), 'Variant not created');
        LibraryAssert.AreEqual(Item."No.", ShpfyVariant.Title, 'Title not set');
        LibraryAssert.AreEqual(Item."No.", ShpfyVariant."Option 1 Value", 'Option 1 Value not set');
        LibraryAssert.AreEqual(OptionName, ShpfyVariant."Option 1 Name", 'Option 1 Name not set');
        LibraryAssert.AreEqual(ParentProductId, ShpfyVariant."Product Id", 'Parent product not set');
        LibraryAssert.IsTrue(ShpfyProduct.Get(ParentProductId), 'Parent product not found');
        LibraryAssert.IsTrue(ShpfyProduct."Has Variants", 'Has Variants not set');
    end;

    [Test]
    [HandlerFunctions('CreateItemVariantHttpHandler')]
    procedure UnitTestGetProductOptions()
    var
        Item: Record "Item";
        ShpfyProductInitTest: Codeunit "Shpfy Product Init Test";
        ProductAPI: Codeunit "Shpfy Product API";
        ProductId: BigInteger;
        Options: Dictionary of [Text, Text];
    begin
        // [SCENARIO] Get product options for a given shopify product
        Initialize();
        MultipleOptions := false;
        OptionName := '';

        // [GIVEN] Item
        Item := ShpfyProductInitTest.CreateItem(Shop."Item Templ. Code", Any.DecimalInRange(10, 100, 2), Any.DecimalInRange(100, 500, 2));
        // [GIVEN] Shopify product
        ProductId := Any.IntegerInRange(10000, 99999);

        // [GIVEN] Register Expected Outbound API Requests.
        OutboundHttpRequests.Clear();
        OutboundHttpRequests.Enqueue('GetOptions');

        // [WHEN] Invoke ProductAPI.GetProductOptions
        Options := ProductAPI.GetProductOptions(ProductId);

        // [THEN] Options are returned
        LibraryAssert.AreEqual(1, Options.Count(), 'Options not returned');
    end;

    [Test]
    [HandlerFunctions('CreateItemVariantHttpHandler')]
    procedure UnitTestCreateVariantFromProductWithMultipleOptions()
    var
        Item: Record "Item";
        ShpfyProductInitTest: Codeunit "Shpfy Product Init Test";
        CreateItemAsVariant: Codeunit "Shpfy Create Item As Variant";
        ProductId: BigInteger;
    begin
        // [SCENARIO] Create a variant from a product with multiple options
        Initialize();
        OptionName := '';

        // [GIVEN] Item
        Item := ShpfyProductInitTest.CreateItem(Shop."Item Templ. Code", Any.DecimalInRange(10, 100, 2), Any.DecimalInRange(100, 500, 2));
        // [GIVEN] Shopify product
        ProductId := CreateShopifyProduct(Item.SystemId);

        // [GIVEN] Multiple options for the product in Shopify
        MultipleOptions := true;

        // [GIVEN] Register Expected Outbound API Requests.
        OutboundHttpRequests.Clear();
        OutboundHttpRequests.Enqueue('GetOptions');

        // [WHEN] Invoke ProductAPI.CheckProductAndShopSettings
        CreateItemAsVariant.SetParentProduct(ProductId);
        asserterror CreateItemAsVariant.CheckProductAndShopSettings();

        // [THEN] Error is thrown
        LibraryAssert.ExpectedError('The product has more than one option. Items cannot be added as variants to a product with multiple options.');
    end;

    [Test]
    procedure UnitTestCreateVariantFromSameItem()
    var
        Item: Record "Item";
        ShpfyVariant: Record "Shpfy Variant";
        ShpfyProductInitTest: Codeunit "Shpfy Product Init Test";
        CreateItemAsVariant: Codeunit "Shpfy Create Item As Variant";
        ParentProductId: BigInteger;
        VariantId: BigInteger;
    begin
        // [SCENARIO] Create a variant from a given item for the same item
        Initialize();
        MultipleOptions := false;
        OptionName := '';

        // [GIVEN] Item
        Item := ShpfyProductInitTest.CreateItem(Shop."Item Templ. Code", Any.DecimalInRange(10, 100, 2), Any.DecimalInRange(100, 500, 2));
        // [GIVEN] Shopify product
        ParentProductId := CreateShopifyProduct(Item.SystemId);

        // [GIVEN] No API calls expected - same item should be skipped immediately
        OutboundHttpRequests.Clear();
        NewVariantId := 0;

        // [WHEN] Invoke CreateItemAsVariant.CreateVariantFromItem
        CreateItemAsVariant.SetParentProduct(ParentProductId);
        CreateItemAsVariant.CreateVariantFromItem(Item);
        VariantId := NewVariantId;

        // [THEN] Variant is not created
        LibraryAssert.IsFalse(ShpfyVariant.Get(VariantId), 'Variant created');
    end;

    [HttpClientHandler]
    internal procedure CreateItemVariantHttpHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    var
        DefaultVariantId: BigInteger;
        RequestType: Text;
        BodyTxt: Text;
    begin
        if not InitializeTest.VerifyRequestUrl(Request.Path, Shop."Shopify URL") then
            exit(true);

        if OutboundHttpRequests.Length() = 0 then
            exit(false);

        DefaultVariantId := Any.IntegerInRange(100000, 999999);
        RequestType := OutboundHttpRequests.DequeueText();
        case RequestType of
            'CreateVariant':
                begin
                    Any.SetDefaultSeed();
                    NewVariantId := Any.IntegerInRange(100000, 999999);
                    BodyTxt := NavApp.GetResourceAsText('Products/CreatedVariantResponse.txt', TextEncoding::UTF8);
                    Response.Content.WriteFrom(StrSubstNo(BodyTxt, NewVariantId));
                end;
            'GetOptions':
                if MultipleOptions then begin
                    BodyTxt := NavApp.GetResourceAsText('Products/ProductMultipleOptionsResponse.txt', TextEncoding::UTF8);
                    Response.Content.WriteFrom(BodyTxt);
                end else begin
                    if OptionName = '' then
                        OptionName := 'Title';
                    BodyTxt := NavApp.GetResourceAsText('Products/ProductOptionsResponse.txt', TextEncoding::UTF8);
                    Response.Content.WriteFrom(StrSubstNo(BodyTxt, OptionName));
                end;
            'GetVariants':
                begin
                    BodyTxt := NavApp.GetResourceAsText('Products/DefaultVariantResponse.txt', TextEncoding::UTF8);
                    Response.Content.WriteFrom(StrSubstNo(BodyTxt, DefaultVariantId));
                end;
            'ProductOptionUpdate':
                Response.Content.WriteFrom('{}');
        end;
        exit(false);
    end;

    local procedure Initialize()
    var
        AccessToken: SecretText;
    begin
        Any.SetDefaultSeed();
        if IsInitialized then
            exit;
        Shop := InitializeTest.CreateShop();
        AccessToken := Any.AlphanumericText(20);
        InitializeTest.RegisterAccessTokenForShop(Shop.GetStoreName(), AccessToken);
        Commit();
        IsInitialized := true;
    end;

    local procedure CreateShopifyProduct(SystemId: Guid): BigInteger
    var
        ShopifyProduct: Record "Shpfy Product";
    begin
        ShopifyProduct.Init();
        ShopifyProduct.Id := Any.IntegerInRange(10000, 99999);
        ShopifyProduct."Shop Code" := Shop."Code";
        ShopifyProduct."Item SystemId" := SystemId;
        ShopifyProduct.Insert(true);
        exit(ShopifyProduct."Id");
    end;
}
