// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Integration.Shopify;
using Microsoft.Inventory.Item;
using System.TestLibraries.Utilities;

/// <summary>
/// Codeunit Shpfy Variant Option1Name Test (ID 139649).
/// Tests for issue #7724: a new BC variant exported to a Shopify-origin product must reuse the
/// option name that product already has in Shopify instead of the hardcoded default.
///
/// These tests deliberately start from a blank variant record, because that is what the create
/// path does: CreateProductVariant clears a temporary Shpfy Variant and only gets a Product Id
/// later, inside AddProductVariant. The product to resolve against is therefore passed in.
/// </summary>
codeunit 139649 "Shpfy Variant Option1Name Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;
    TestHttpRequestPolicy = BlockOutboundRequests;

    var
        Shop: Record "Shpfy Shop";
        Any: Codeunit Any;
        InitializeTest: Codeunit "Shpfy Initialize Test";
        LibraryAssert: Codeunit "Library Assert";
        LibraryInventory: Codeunit "Library - Inventory";
        IsInitialized: Boolean;
        DefaultOption1NameTok: Label 'Variant', Locked = true;
        ShopifyOption1NameTok: Label 'Size', Locked = true;
        OtherOption1NameTok: Label 'Colour', Locked = true;
        UoMOptionNameTok: Label 'Unit of Measure', Locked = true;
        Option1NameMismatchErr: Label 'Unexpected Option 1 Name.';
        Option1ValueMismatchErr: Label 'Unexpected Option 1 Value.';

    [Test]
    procedure UnitTestCreateVariantInheritsOption1NameFromShopifyProduct()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ShopifyProduct: Record "Shpfy Product";
        ExistingVariant: Record "Shpfy Variant";
        TempNewVariant: Record "Shpfy Variant" temporary;
        ProductExport: Codeunit "Shpfy Product Export";
    begin
        // [SCENARIO 7724] A product imported from Shopify already uses option name 'Size'. Exporting a
        // new BC item variant must send 'Size', not the default, or Shopify rejects the mutation.
        Initialize();

        // [GIVEN] An item with a variant, mapped to a Shopify product whose variants use 'Size'
        CreateItemWithVariant(Item, ItemVariant);
        CreateShopifyProduct(ShopifyProduct, Item.SystemId);
        CreateShopifyVariant(ExistingVariant, ShopifyProduct, Item.SystemId, ShopifyOption1NameTok, 'Test');

        // [WHEN] The create path fills in a blank variant for that product
        ProductExport.SetShop(Shop);
        ProductExport.FillInProductVariantData(TempNewVariant, Item, ItemVariant, ShopifyProduct.Id);

        // [THEN] The variant carries Shopify's option name and the BC variant code as its value
        LibraryAssert.AreEqual(ShopifyOption1NameTok, TempNewVariant."Option 1 Name", Option1NameMismatchErr);
        LibraryAssert.AreEqual(Format(ItemVariant.Code), TempNewVariant."Option 1 Value", Option1ValueMismatchErr);
    end;

    [Test]
    procedure UnitTestCreateVariantWithUoMInheritsOption1NameFromShopifyProduct()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ShopifyProduct: Record "Shpfy Product";
        ExistingVariant: Record "Shpfy Variant";
        TempNewVariant: Record "Shpfy Variant" temporary;
        ShopWithUoMAsVariant: Record "Shpfy Shop";
        ProductExport: Codeunit "Shpfy Product Export";
    begin
        // [SCENARIO 7724] The same applies when units of measure are maintained as Shopify variants,
        // where option 1 holds the item variant and option 2 holds the unit of measure.
        Initialize();

        // [GIVEN] An item with a variant and a unit of measure, on a shop that syncs UoM as variant
        CreateItemWithVariant(Item, ItemVariant);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 1);
        ShopWithUoMAsVariant := Shop;
        ShopWithUoMAsVariant."Option Name for UoM" := CopyStr(UoMOptionNameTok, 1, MaxStrLen(ShopWithUoMAsVariant."Option Name for UoM"));

        // [GIVEN] A Shopify product whose variants use 'Size'
        CreateShopifyProduct(ShopifyProduct, Item.SystemId);
        CreateShopifyVariant(ExistingVariant, ShopifyProduct, Item.SystemId, ShopifyOption1NameTok, 'Test');

        // [WHEN] The create path fills in a blank variant for that product
        ProductExport.SetShop(ShopWithUoMAsVariant);
        ProductExport.FillInProductVariantData(TempNewVariant, Item, ItemVariant, ItemUnitOfMeasure, ShopifyProduct.Id);

        // [THEN] Option 1 carries Shopify's option name, option 2 still carries the unit of measure
        LibraryAssert.AreEqual(ShopifyOption1NameTok, TempNewVariant."Option 1 Name", Option1NameMismatchErr);
        LibraryAssert.AreEqual(Format(ItemVariant.Code), TempNewVariant."Option 1 Value", Option1ValueMismatchErr);
        LibraryAssert.AreEqual(UoMOptionNameTok, TempNewVariant."Option 2 Name", 'Unexpected Option 2 Name.');
        LibraryAssert.AreEqual(Format(ItemUnitOfMeasure.Code), TempNewVariant."Option 2 Value", 'Unexpected Option 2 Value.');
    end;

    [Test]
    procedure UnitTestCreateVariantWithoutProductContextUsesDefaultOption1Name()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ShopifyProduct: Record "Shpfy Product";
        ExistingVariant: Record "Shpfy Variant";
        TempNewVariant: Record "Shpfy Variant" temporary;
        ProductExport: Codeunit "Shpfy Product Export";
    begin
        // [SCENARIO 7724] A blank variant carries no Product Id, so without the product passed in there
        // is nothing to resolve against. This pins why the create path must supply it explicitly.
        Initialize();

        // [GIVEN] An item with a variant, mapped to a Shopify product whose variants use 'Size'
        CreateItemWithVariant(Item, ItemVariant);
        CreateShopifyProduct(ShopifyProduct, Item.SystemId);
        CreateShopifyVariant(ExistingVariant, ShopifyProduct, Item.SystemId, ShopifyOption1NameTok, 'Test');

        // [WHEN] A blank variant is filled in without naming the product it belongs to
        ProductExport.SetShop(Shop);
        ProductExport.FillInProductVariantData(TempNewVariant, Item, ItemVariant);

        // [THEN] The default option name is used
        LibraryAssert.AreEqual(DefaultOption1NameTok, TempNewVariant."Option 1 Name", Option1NameMismatchErr);
        LibraryAssert.AreEqual(Format(ItemVariant.Code), TempNewVariant."Option 1 Value", Option1ValueMismatchErr);
    end;

    [Test]
    procedure UnitTestCreateVariantForBCOriginProductUsesDefaultOption1Name()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ShopifyProduct: Record "Shpfy Product";
        ExistingVariant: Record "Shpfy Variant";
        TempNewVariant: Record "Shpfy Variant" temporary;
        ProductExport: Codeunit "Shpfy Product Export";
    begin
        // [SCENARIO 7724] Products that originated in BC already use the default name on every variant,
        // so nothing should change for them.
        Initialize();

        // [GIVEN] A Shopify product whose existing variants use the default option name
        CreateItemWithVariant(Item, ItemVariant);
        CreateShopifyProduct(ShopifyProduct, Item.SystemId);
        CreateShopifyVariant(ExistingVariant, ShopifyProduct, Item.SystemId, DefaultOption1NameTok, 'VAR1');

        // [WHEN] The create path fills in a blank variant for that product
        ProductExport.SetShop(Shop);
        ProductExport.FillInProductVariantData(TempNewVariant, Item, ItemVariant, ShopifyProduct.Id);

        // [THEN] The default option name is kept
        LibraryAssert.AreEqual(DefaultOption1NameTok, TempNewVariant."Option 1 Name", Option1NameMismatchErr);
        LibraryAssert.AreEqual(Format(ItemVariant.Code), TempNewVariant."Option 1 Value", Option1ValueMismatchErr);
    end;

    [Test]
    procedure UnitTestCreateVariantForProductWithoutVariantsUsesDefaultOption1Name()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ShopifyProduct: Record "Shpfy Product";
        TempNewVariant: Record "Shpfy Variant" temporary;
        ProductExport: Codeunit "Shpfy Product Export";
    begin
        // [SCENARIO 7724] With no existing variants there is no Shopify option metadata to inherit.
        Initialize();

        // [GIVEN] A Shopify product with no variants recorded in BC
        CreateItemWithVariant(Item, ItemVariant);
        CreateShopifyProduct(ShopifyProduct, Item.SystemId);

        // [WHEN] The create path fills in a blank variant for that product
        ProductExport.SetShop(Shop);
        ProductExport.FillInProductVariantData(TempNewVariant, Item, ItemVariant, ShopifyProduct.Id);

        // [THEN] The default option name is used
        LibraryAssert.AreEqual(DefaultOption1NameTok, TempNewVariant."Option 1 Name", Option1NameMismatchErr);
        LibraryAssert.AreEqual(Format(ItemVariant.Code), TempNewVariant."Option 1 Value", Option1ValueMismatchErr);
    end;

    [Test]
    procedure UnitTestCreateVariantWithAmbiguousOption1NamesUsesDefaultOption1Name()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ShopifyProduct: Record "Shpfy Product";
        FirstVariant: Record "Shpfy Variant";
        SecondVariant: Record "Shpfy Variant";
        TempNewVariant: Record "Shpfy Variant" temporary;
        ProductExport: Codeunit "Shpfy Product Export";
    begin
        // [SCENARIO 7724] A Shopify product has one name per option slot. Conflicting names mean the
        // stored metadata cannot be trusted, so fall back rather than guess.
        Initialize();

        // [GIVEN] A Shopify product whose variants disagree about the option 1 name
        CreateItemWithVariant(Item, ItemVariant);
        CreateShopifyProduct(ShopifyProduct, Item.SystemId);
        CreateShopifyVariant(FirstVariant, ShopifyProduct, Item.SystemId, ShopifyOption1NameTok, 'Test');
        CreateShopifyVariant(SecondVariant, ShopifyProduct, Item.SystemId, OtherOption1NameTok, 'Red');

        // [WHEN] The create path fills in a blank variant for that product
        ProductExport.SetShop(Shop);
        ProductExport.FillInProductVariantData(TempNewVariant, Item, ItemVariant, ShopifyProduct.Id);

        // [THEN] The default option name is used
        LibraryAssert.AreEqual(DefaultOption1NameTok, TempNewVariant."Option 1 Name", Option1NameMismatchErr);
        LibraryAssert.AreEqual(Format(ItemVariant.Code), TempNewVariant."Option 1 Value", Option1ValueMismatchErr);
    end;

    [Test]
    procedure UnitTestCreateVariantIgnoresOption1NameFromAnotherShop()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ShopifyProduct: Record "Shpfy Product";
        OtherShopVariant: Record "Shpfy Variant";
        TempNewVariant: Record "Shpfy Variant" temporary;
        ProductExport: Codeunit "Shpfy Product Export";
        OtherShopCode: Code[20];
    begin
        // [SCENARIO 7724] Option metadata belongs to the shop it was imported into.
        Initialize();

        // [GIVEN] A Shopify product whose only variant with 'Size' belongs to a different shop
        CreateItemWithVariant(Item, ItemVariant);
        CreateShopifyProduct(ShopifyProduct, Item.SystemId);
        CreateShopifyVariant(OtherShopVariant, ShopifyProduct, Item.SystemId, ShopifyOption1NameTok, 'Test');
        OtherShopCode := CopyStr(Any.AlphanumericText(MaxStrLen(OtherShopVariant."Shop Code")), 1, MaxStrLen(OtherShopVariant."Shop Code"));
        LibraryAssert.AreNotEqual(Shop.Code, OtherShopCode, 'The second shop code must differ from the shop under test.');
        OtherShopVariant."Shop Code" := OtherShopCode;
        OtherShopVariant.Modify(false);

        // [WHEN] The create path fills in a blank variant for that product
        ProductExport.SetShop(Shop);
        ProductExport.FillInProductVariantData(TempNewVariant, Item, ItemVariant, ShopifyProduct.Id);

        // [THEN] The other shop's option name is not used
        LibraryAssert.AreEqual(DefaultOption1NameTok, TempNewVariant."Option 1 Name", Option1NameMismatchErr);
    end;

    [Test]
    procedure UnitTestCreateVariantIgnoresUoMOptionNameAsShopifyMetadata()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ShopifyProduct: Record "Shpfy Product";
        ExistingVariant: Record "Shpfy Variant";
        TempNewVariant: Record "Shpfy Variant" temporary;
        ShopWithUoMAsVariant: Record "Shpfy Shop";
        ProductExport: Codeunit "Shpfy Product Export";
    begin
        // [SCENARIO 7724] The unit of measure option name is generated by BC, so it is not Shopify
        // metadata and must not be inherited by an item variant.
        Initialize();

        // [GIVEN] A shop that names its UoM option, and a product whose variants use that name
        CreateItemWithVariant(Item, ItemVariant);
        ShopWithUoMAsVariant := Shop;
        ShopWithUoMAsVariant."Option Name for UoM" := CopyStr(UoMOptionNameTok, 1, MaxStrLen(ShopWithUoMAsVariant."Option Name for UoM"));
        CreateShopifyProduct(ShopifyProduct, Item.SystemId);
        CreateShopifyVariant(ExistingVariant, ShopifyProduct, Item.SystemId, UoMOptionNameTok, 'PCS');

        // [WHEN] The create path fills in a blank variant for that product
        ProductExport.SetShop(ShopWithUoMAsVariant);
        ProductExport.FillInProductVariantData(TempNewVariant, Item, ItemVariant, ShopifyProduct.Id);

        // [THEN] The default option name is used
        LibraryAssert.AreEqual(DefaultOption1NameTok, TempNewVariant."Option 1 Name", Option1NameMismatchErr);
    end;

    [Test]
    procedure UnitTestCreateVariantResolvesOption1NamePerProduct()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        FirstProduct: Record "Shpfy Product";
        SecondProduct: Record "Shpfy Product";
        FirstExistingVariant: Record "Shpfy Variant";
        SecondExistingVariant: Record "Shpfy Variant";
        TempFirstNewVariant: Record "Shpfy Variant" temporary;
        TempSecondNewVariant: Record "Shpfy Variant" temporary;
        ProductExport: Codeunit "Shpfy Product Export";
    begin
        // [SCENARIO 7724] One export run covers many products, so a resolved name must not leak from
        // one product to the next.
        Initialize();

        // [GIVEN] Two Shopify products using different option names
        CreateItemWithVariant(Item, ItemVariant);
        CreateShopifyProduct(FirstProduct, Item.SystemId);
        CreateShopifyVariant(FirstExistingVariant, FirstProduct, Item.SystemId, ShopifyOption1NameTok, 'Test');
        CreateShopifyProduct(SecondProduct, Item.SystemId);
        CreateShopifyVariant(SecondExistingVariant, SecondProduct, Item.SystemId, OtherOption1NameTok, 'Red');

        // [WHEN] Both products get a new variant from the same export
        ProductExport.SetShop(Shop);
        ProductExport.FillInProductVariantData(TempFirstNewVariant, Item, ItemVariant, FirstProduct.Id);
        ProductExport.FillInProductVariantData(TempSecondNewVariant, Item, ItemVariant, SecondProduct.Id);

        // [THEN] Each variant gets its own product's option name
        LibraryAssert.AreEqual(ShopifyOption1NameTok, TempFirstNewVariant."Option 1 Name", Option1NameMismatchErr);
        LibraryAssert.AreEqual(OtherOption1NameTok, TempSecondNewVariant."Option 1 Name", Option1NameMismatchErr);
    end;

    [Test]
    procedure UnitTestUpdateVariantKeepsExistingOption1NameAndValue()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ShopifyProduct: Record "Shpfy Product";
        ExistingVariant: Record "Shpfy Variant";
        ProductExport: Codeunit "Shpfy Product Export";
    begin
        // [SCENARIO 7724] Updating a variant that already carries Shopify's option name and value must
        // leave both alone, as it did before the fix.
        Initialize();

        // [GIVEN] An existing variant carrying 'Colour' / 'Red' from Shopify
        CreateItemWithVariant(Item, ItemVariant);
        CreateShopifyProduct(ShopifyProduct, Item.SystemId);
        CreateShopifyVariant(ExistingVariant, ShopifyProduct, Item.SystemId, OtherOption1NameTok, 'Red');

        // [WHEN] The update path fills in that existing variant
        ProductExport.SetShop(Shop);
        ProductExport.FillInProductVariantData(ExistingVariant, Item, ItemVariant);

        // [THEN] Neither the option name nor the option value is overwritten
        LibraryAssert.AreEqual(OtherOption1NameTok, ExistingVariant."Option 1 Name", Option1NameMismatchErr);
        LibraryAssert.AreEqual('Red', ExistingVariant."Option 1 Value", Option1ValueMismatchErr);
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        IsInitialized := true;
        Shop := InitializeTest.CreateShop();
        Commit();
    end;

    local procedure CreateItemWithVariant(var Item: Record Item; var ItemVariant: Record "Item Variant")
    var
        ProductInitTest: Codeunit "Shpfy Product Init Test";
    begin
        Item := ProductInitTest.CreateItem();

        ItemVariant.Init();
        ItemVariant.Validate("Item No.", Item."No.");
        ItemVariant.Code := CopyStr(Item."No." + 'V1', 1, MaxStrLen(ItemVariant.Code));
        ItemVariant.Description := 'Test Variant';
        ItemVariant.Insert(true);
    end;

    local procedure CreateShopifyProduct(var ShopifyProduct: Record "Shpfy Product"; ItemSystemId: Guid)
    begin
        Clear(ShopifyProduct);
        ShopifyProduct.Init();
        ShopifyProduct.Id := NextProductId();
        ShopifyProduct."Item SystemId" := ItemSystemId;
        ShopifyProduct."Shop Code" := Shop.Code;
        ShopifyProduct."Has Variants" := true;
        ShopifyProduct.Insert(false);
    end;

    local procedure CreateShopifyVariant(var ShopifyVariant: Record "Shpfy Variant"; ShopifyProduct: Record "Shpfy Product"; ItemSystemId: Guid; Option1Name: Text; Option1Value: Text)
    begin
        Clear(ShopifyVariant);
        ShopifyVariant.Init();
        ShopifyVariant.Id := NextVariantId();
        ShopifyVariant."Product Id" := ShopifyProduct.Id;
        ShopifyVariant."Item SystemId" := ItemSystemId;
        ShopifyVariant."Shop Code" := Shop.Code;
        ShopifyVariant."Option 1 Name" := CopyStr(Option1Name, 1, MaxStrLen(ShopifyVariant."Option 1 Name"));
        ShopifyVariant."Option 1 Value" := CopyStr(Option1Value, 1, MaxStrLen(ShopifyVariant."Option 1 Value"));
        ShopifyVariant.Insert(false);
    end;

    local procedure NextProductId(): BigInteger
    var
        ShopifyProduct: Record "Shpfy Product";
        ProductId: BigInteger;
    begin
        repeat
            ProductId := Any.IntegerInRange(100000, 999999);
        until not ShopifyProduct.Get(ProductId);
        exit(ProductId);
    end;

    local procedure NextVariantId(): BigInteger
    var
        ShopifyVariant: Record "Shpfy Variant";
        VariantId: BigInteger;
    begin
        repeat
            VariantId := Any.IntegerInRange(100000, 999999);
        until not ShopifyVariant.Get(VariantId);
        exit(VariantId);
    end;
}
