// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Integration.Shopify;
using Microsoft.Inventory.Item;
using System.TestLibraries.Utilities;

/// <summary>
/// Tests for Issue #7724: Option 1 Name resolution in FillInProductVariantData.
/// </summary>
codeunit 139649 "Shpfy Variant Option1Name Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;
    TestHttpRequestPolicy = BlockOutboundRequests;

    var
        Shop: Record "Shpfy Shop";
        InitializeTest: Codeunit "Shpfy Initialize Test";
        LibraryAssert: Codeunit "Library Assert";
        IsInitialized: Boolean;

    [Test]
    procedure UnitTestOption1NameInheritedFromShopifyOriginProduct()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ShopifyProduct: Record "Shpfy Product";
        ExistingVariant: Record "Shpfy Variant";
        NewVariant: Record "Shpfy Variant";
        ProductExport: Codeunit "Shpfy Product Export";
    begin
        // [SCENARIO #7724] Shopify-origin product with one existing variant having Option 1 Name = 'Size'
        // -> new BC variant export inherits 'Size' and Option 1 Value = ItemVariant.Code.
        Initialize();

        // [GIVEN] An item with a variant
        CreateItem(Item);
        CreateItemVariant(Item, ItemVariant);

        // [GIVEN] A Shopify product with one existing variant carrying Option 1 Name = 'Size'
        CreateShopifyProduct(ShopifyProduct, Item.SystemId);
        CreateShopifyVariant(ExistingVariant, ShopifyProduct, Item.SystemId, 'Size', 'Test');

        // [GIVEN] A new blank Shpfy Variant for the same product (being created from BC)
        CreateBlankShopifyVariant(NewVariant, ShopifyProduct, Item.SystemId);

        // [WHEN] FillInProductVariantData is called
        ProductExport.SetShop(Shop);
        ProductExport.FillInProductVariantData(NewVariant, Item, ItemVariant);

        // [THEN] Option 1 Name is resolved to 'Size' (from existing Shopify variant)
        LibraryAssert.AreEqual('Size', NewVariant."Option 1 Name", 'Option 1 Name should be inherited from existing Shopify variant');

        // [THEN] Option 1 Value is set to ItemVariant.Code
        LibraryAssert.AreEqual(ItemVariant.Code, NewVariant."Option 1 Value", 'Option 1 Value should be set to ItemVariant.Code');
    end;

    [Test]
    procedure UnitTestOption1NameDefaultsToVariantForBCOriginProduct()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ShopifyProduct: Record "Shpfy Product";
        ExistingVariant: Record "Shpfy Variant";
        NewVariant: Record "Shpfy Variant";
        ProductExport: Codeunit "Shpfy Product Export";
    begin
        // [SCENARIO #7724] BC-origin product where existing variants already carry Option 1 Name = 'Variant'
        // -> new variant still defaults to 'Variant' (regression guard).
        Initialize();

        // [GIVEN] An item with a variant
        CreateItem(Item);
        CreateItemVariant(Item, ItemVariant);

        // [GIVEN] A Shopify product with an existing BC-origin variant (Option 1 Name = 'Variant')
        CreateShopifyProduct(ShopifyProduct, Item.SystemId);
        CreateShopifyVariant(ExistingVariant, ShopifyProduct, Item.SystemId, 'Variant', 'VAR1');

        // [GIVEN] A new blank Shpfy Variant for the same product
        CreateBlankShopifyVariant(NewVariant, ShopifyProduct, Item.SystemId);

        // [WHEN] FillInProductVariantData is called
        ProductExport.SetShop(Shop);
        ProductExport.FillInProductVariantData(NewVariant, Item, ItemVariant);

        // [THEN] Option 1 Name stays 'Variant'
        LibraryAssert.AreEqual('Variant', NewVariant."Option 1 Name", 'Option 1 Name should default to Variant for BC-origin products');

        // [THEN] Option 1 Value is set to ItemVariant.Code
        LibraryAssert.AreEqual(ItemVariant.Code, NewVariant."Option 1 Value", 'Option 1 Value should be set to ItemVariant.Code');
    end;

    [Test]
    procedure UnitTestOption1NameDefaultsToVariantWhenNoExistingVariants()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ShopifyProduct: Record "Shpfy Product";
        NewVariant: Record "Shpfy Variant";
        ProductExport: Codeunit "Shpfy Product Export";
    begin
        // [SCENARIO #7724] Product with no existing Shpfy Variant rows -> still defaults to 'Variant'.
        Initialize();

        // [GIVEN] An item with a variant
        CreateItem(Item);
        CreateItemVariant(Item, ItemVariant);

        // [GIVEN] A Shopify product with no existing variants in BC
        CreateShopifyProduct(ShopifyProduct, Item.SystemId);

        // [GIVEN] A new blank Shpfy Variant (only one in table for this product)
        CreateBlankShopifyVariant(NewVariant, ShopifyProduct, Item.SystemId);

        // [WHEN] FillInProductVariantData is called
        ProductExport.SetShop(Shop);
        ProductExport.FillInProductVariantData(NewVariant, Item, ItemVariant);

        // [THEN] Option 1 Name defaults to 'Variant'
        LibraryAssert.AreEqual('Variant', NewVariant."Option 1 Name", 'Option 1 Name should default to Variant when no existing variants exist');

        // [THEN] Option 1 Value is set to ItemVariant.Code
        LibraryAssert.AreEqual(ItemVariant.Code, NewVariant."Option 1 Value", 'Option 1 Value should be set to ItemVariant.Code');
    end;

    [Test]
    procedure UnitTestOption1NameDefaultsToVariantWhenAmbiguous()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ShopifyProduct: Record "Shpfy Product";
        ExistingVariant1: Record "Shpfy Variant";
        ExistingVariant2: Record "Shpfy Variant";
        NewVariant: Record "Shpfy Variant";
        ProductExport: Codeunit "Shpfy Product Export";
    begin
        // [SCENARIO #7724] Two existing variants with different Option 1 Names (ambiguous) -> falls back to 'Variant'.
        Initialize();

        // [GIVEN] An item with a variant
        CreateItem(Item);
        CreateItemVariant(Item, ItemVariant);

        // [GIVEN] A Shopify product with two existing variants having conflicting Option 1 Names
        CreateShopifyProduct(ShopifyProduct, Item.SystemId);
        CreateShopifyVariant(ExistingVariant1, ShopifyProduct, Item.SystemId, 'Color', 'Red');
        CreateShopifyVariant(ExistingVariant2, ShopifyProduct, Item.SystemId, 'Size', 'Large');

        // [GIVEN] A new blank Shpfy Variant for the same product
        CreateBlankShopifyVariant(NewVariant, ShopifyProduct, Item.SystemId);

        // [WHEN] FillInProductVariantData is called
        ProductExport.SetShop(Shop);
        ProductExport.FillInProductVariantData(NewVariant, Item, ItemVariant);

        // [THEN] Option 1 Name falls back to 'Variant' due to ambiguity
        LibraryAssert.AreEqual('Variant', NewVariant."Option 1 Name", 'Option 1 Name should fall back to Variant when existing variants have conflicting names');

        // [THEN] Option 1 Value is set to ItemVariant.Code
        LibraryAssert.AreEqual(ItemVariant.Code, NewVariant."Option 1 Value", 'Option 1 Value should be set to ItemVariant.Code');
    end;

    [Test]
    procedure UnitTestOption1NameAndValuePreservedOnUpdatePath()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ShopifyProduct: Record "Shpfy Product";
        ExistingVariant: Record "Shpfy Variant";
        ProductExport: Codeunit "Shpfy Product Export";
    begin
        // [SCENARIO #7724] Update path: existing Shpfy Variant with a custom Option 1 Name (e.g. 'Color')
        // -> name and value remain untouched after FillInProductVariantData.
        Initialize();

        // [GIVEN] An item with a variant
        CreateItem(Item);
        CreateItemVariant(Item, ItemVariant);

        // [GIVEN] A Shopify product with one fully-populated variant (already imported from Shopify)
        CreateShopifyProduct(ShopifyProduct, Item.SystemId);
        CreateShopifyVariant(ExistingVariant, ShopifyProduct, Item.SystemId, 'Color', 'Red');

        // [WHEN] FillInProductVariantData is called on the already-populated variant (update path)
        ProductExport.SetShop(Shop);
        ProductExport.FillInProductVariantData(ExistingVariant, Item, ItemVariant);

        // [THEN] Option 1 Name is NOT overwritten - it keeps 'Color'
        LibraryAssert.AreEqual('Color', ExistingVariant."Option 1 Name", 'Option 1 Name must not be overwritten on the update path');

        // [THEN] Option 1 Value is NOT overwritten - it keeps 'Red'
        LibraryAssert.AreEqual('Red', ExistingVariant."Option 1 Value", 'Option 1 Value must not be overwritten on the update path');
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        IsInitialized := true;
        Shop := InitializeTest.CreateShop();
        Commit();
    end;

    local procedure CreateItem(var Item: Record Item)
    var
        ProductInitTest: Codeunit "Shpfy Product Init Test";
    begin
        Item := ProductInitTest.CreateItem();
    end;

    local procedure CreateItemVariant(Item: Record Item; var ItemVariant: Record "Item Variant")
    begin
        ItemVariant.Init();
        ItemVariant.Validate("Item No.", Item."No.");
        ItemVariant.Code := CopyStr(Item."No." + 'V1', 1, MaxStrLen(ItemVariant.Code));
        ItemVariant.Description := 'Test Variant';
        ItemVariant.Insert(true);
    end;

    local procedure CreateShopifyProduct(var ShopifyProduct: Record "Shpfy Product"; ItemSystemId: Guid)
    begin
        ShopifyProduct.Init();
        ShopifyProduct.Id := Random(2147483647);
        ShopifyProduct."Item SystemId" := ItemSystemId;
        ShopifyProduct."Shop Code" := Shop.Code;
        ShopifyProduct."Has Variants" := true;
        ShopifyProduct.Insert(false);
    end;

    local procedure CreateShopifyVariant(var ShopifyVariant: Record "Shpfy Variant"; ShopifyProduct: Record "Shpfy Product"; ItemSystemId: Guid; Option1Name: Text[50]; Option1Value: Text[255])
    begin
        ShopifyVariant.Init();
        ShopifyVariant.Id := Random(2147483647);
        ShopifyVariant."Product Id" := ShopifyProduct.Id;
        ShopifyVariant."Item SystemId" := ItemSystemId;
        ShopifyVariant."Shop Code" := Shop.Code;
        ShopifyVariant."Option 1 Name" := Option1Name;
        ShopifyVariant."Option 1 Value" := CopyStr(Option1Value, 1, MaxStrLen(ShopifyVariant."Option 1 Value"));
        ShopifyVariant.Insert(false);
    end;

    local procedure CreateBlankShopifyVariant(var ShopifyVariant: Record "Shpfy Variant"; ShopifyProduct: Record "Shpfy Product"; ItemSystemId: Guid)
    begin
        ShopifyVariant.Init();
        ShopifyVariant.Id := Random(2147483647);
        ShopifyVariant."Product Id" := ShopifyProduct.Id;
        ShopifyVariant."Item SystemId" := ItemSystemId;
        ShopifyVariant."Shop Code" := Shop.Code;
        ShopifyVariant."Option 1 Name" := '';
        ShopifyVariant."Option 1 Value" := '';
        ShopifyVariant.Insert(false);
    end;
}
