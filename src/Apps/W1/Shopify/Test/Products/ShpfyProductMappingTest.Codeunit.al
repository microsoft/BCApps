// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Integration.Shopify;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using System.TestLibraries.Utilities;

codeunit 139604 "Shpfy Product Mapping Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var
        LibraryAssert: Codeunit "Library Assert";
        ProductUrlTok: Label 'https://test.myshopify.com/products/test-product', Locked = true;

    [Test]
    procedure UnitTestFindMappingWithNoSKUMapping()
    var
        Item: Record Item;
        ItemReference: Record "Item Reference";
        Shop: Record "Shpfy Shop";
        ShopifyProduct: Record "Shpfy Product";
        ShopifyVariant: Record "Shpfy Variant";
        InitializeTest: Codeunit "Shpfy Initialize Test";
        ProductInitTest: Codeunit "Shpfy Product Init Test";
        ProductMapping: Codeunit "Shpfy Product Mapping";
        Barcode: Code[50];
    begin
        // [SCENARIO] Shopify product to an item and with the SKU empty.
        // [SCENARIO] Because there is no SKU mapping, it will try to find the mapping based on the bar code field on the Shopify Variant record.
        Shop := InitializeTest.CreateShop();
        Shop."SKU Mapping" := "Shpfy SKU Mapping"::" ";
        Shop.Modify();
        Item := ProductInitTest.CreateItem();
        ItemReference.SetRange("Item No.", Item."No.");
        ItemReference.SetRange("Reference Type", "Item Reference Type"::"Bar Code");
        if ItemReference.FindFirst() then
            BarCode := ItemReference."Reference No.";

        // [GIVEN] A Shopify Product Record
        // [GIVEN] A Shopify Variant record that belongs to the Shopify Product record and has the same barcode of that from the item record.
        ShopifyVariant := ProductInitTest.CreateStandardProduct(Shop);
        ShopifyVariant.Barcode := Barcode;
        ShopifyVariant.Modify();
        ShopifyProduct.Get(ShopifyVariant."Product Id");

        // [WHEN] Invoke ProductMapping.FindMapping(ShopifyProduct, ShopifyVariant)
        ProductMapping.FindMapping(ShopifyProduct, ShopifyVariant);

        // [THEN] ShopifyVariant."Item SystemId" = Item.SystemId
        LibraryAssert.AreEqual(Item.SystemId, ShopifyVariant."Item SystemId", 'ShopifyVariant."Item SystemId" = Item.SystemId');

        // [THEN] ShopifyProduct."Item SystemId"= Item.SystemId
        LibraryAssert.AreEqual(Item.SystemId, ShopifyProduct."Item SystemId", 'ShopifyProduct."Item SystemId"= Item.SystemId');
    end;

    [Test]
    procedure UnitTestFindMappingWithSKUMappedToItemNo()
    var
        Item: Record Item;
        Shop: Record "Shpfy Shop";
        ShopifyProduct: Record "Shpfy Product";
        ShopifyVariant: Record "Shpfy Variant";
        InitializeTest: Codeunit "Shpfy Initialize Test";
        ProductInitTest: Codeunit "Shpfy Product Init Test";
        ProductMapping: Codeunit "Shpfy Product Mapping";
    begin
        // [SCENARIO] Shopify product to an item and with the SKU mapped to Item No.
        // [SCENARIO] Because there is no SKU mapping, it will try to find the mapping based on the bar code field on the Shopify Variant record.
        Shop := InitializeTest.CreateShop();
        Shop."SKU Mapping" := "Shpfy SKU Mapping"::"Item No.";
        Shop.Modify();
        Item := ProductInitTest.CreateItem();
        ShopifyVariant := ProductInitTest.CreateStandardProduct(Shop);
        ShopifyVariant.SKU := Item."No.";
        ShopifyVariant.Modify();
        ShopifyProduct.Get(ShopifyVariant."Product Id");

        // [GIVEN] A Shopify Product Record
        // [GIVEN] A Shopify Variant record that belongs to the Shopify Product record and has SKU filled in with the item no.
        ProductMapping.FindMapping(ShopifyProduct, ShopifyVariant);

        // [THEN] ShopifyVariant."Item SystemId" = Item.SystemId
        LibraryAssert.AreEqual(Item.SystemId, ShopifyVariant."Item SystemId", 'ShopifyVariant."Item SystemId" = Item.SystemId');

        // [THEN] ShopifyProduct."Item SystemId"= Item.SystemId
        LibraryAssert.AreEqual(Item.SystemId, ShopifyProduct."Item SystemId", 'ShopifyProduct."Item SystemId"= Item.SystemId');
    end;

    [Test]
    procedure UnitTestFindMappingWithSKUMappedToVariantCode()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        Shop: Record "Shpfy Shop";
        ShopifyProduct: Record "Shpfy Product";
        ShopifyVariant: Record "Shpfy Variant";
        InitializeTest: Codeunit "Shpfy Initialize Test";
        ProductInitTest: Codeunit "Shpfy Product Init Test";
        ProductMapping: Codeunit "Shpfy Product Mapping";
    begin
        // [SCENARIO] Shopify product to an item and with the SKU mapped to Variant Code.
        // [SCENARIO] Because there is no SKU mapping, it will try to find the mapping based on the bar code field on the Shopify Variant record.
        Shop := InitializeTest.CreateShop();
        Shop."SKU Mapping" := "Shpfy SKU Mapping"::"Variant Code";
        Shop.Modify();
        Item := ProductInitTest.CreateItem(true);
        ItemVariant.SetRange("Item No.", Item."No.");
        ItemVariant.FindFirst();
        ShopifyVariant := ProductInitTest.CreateStandardProduct(Shop);
        ShopifyVariant.SKU := ItemVariant.Code;
        ShopifyVariant.Modify();
        ShopifyProduct.Get(ShopifyVariant."Product Id");

        // [GIVEN] A Shopify Product Record
        // [GIVEN] A Shopify Variant record that belongs to the Shopify Product record and has SKU filled in with the variant code of a variant of item.
        ProductMapping.FindMapping(ShopifyProduct, ShopifyVariant);

        // [THEN] ShopifyVariant."Item SystemId" = Item.SystemId
        LibraryAssert.AreEqual(Item.SystemId, ShopifyVariant."Item SystemId", 'ShopifyVariant."Item SystemId" = Item.SystemId');

        // [THEN] ShopifyVariant."Item Variant SystemId" = ItemVariant.SystemId
        LibraryAssert.AreEqual(ItemVariant.SystemId, ShopifyVariant."Item Variant SystemId", 'ShopifyVariant."Item Variant SystemId" = ItemVariant.SystemId');

        // [THEN] ShopifyProduct."Item SystemId"= Item.SystemId
        LibraryAssert.AreEqual(Item.SystemId, ShopifyProduct."Item SystemId", 'ShopifyProduct."Item SystemId"= Item.SystemId');
    end;

    [Test]
    procedure UnitTestFindMappingWithSKUMappedToItemNoAndVariantCode()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        Shop: Record "Shpfy Shop";
        ShopifyProduct: Record "Shpfy Product";
        ShopifyVariant: Record "Shpfy Variant";
        InitializeTest: Codeunit "Shpfy Initialize Test";
        ProductInitTest: Codeunit "Shpfy Product Init Test";
        ProductMapping: Codeunit "Shpfy Product Mapping";
    begin
        // [SCENARIO] Shopify product to an item and with the SKU mapped to Item No. + Variant Code.
        // [SCENARIO] Because there is no SKU mapping, it will try to find the mapping based on the bar code field on the Shopify Variant record.
        Shop := InitializeTest.CreateShop();
        Shop."SKU Mapping" := "Shpfy SKU Mapping"::"Item No. + Variant Code";
        Shop.Modify();
        Item := ProductInitTest.CreateItem(true);
        ItemVariant.SetRange("Item No.", Item."No.");
        ItemVariant.FindFirst();
        ShopifyVariant := ProductInitTest.CreateStandardProduct(Shop);
        ShopifyVariant.SKU := Item."No." + Shop."SKU Field Separator" + ItemVariant.Code;
        ShopifyVariant.Modify();
        ShopifyProduct.Get(ShopifyVariant."Product Id");

        // [GIVEN] A Shopify Product Record
        // [GIVEN] A Shopify Variant record that belongs to the Shopify Product record and has SKU filled in with the item.no. + variant code of a variant of item.
        ProductMapping.FindMapping(ShopifyProduct, ShopifyVariant);

        // [THEN] ShopifyVariant."Item SystemId" = Item.SystemId
        LibraryAssert.AreEqual(Item.SystemId, ShopifyVariant."Item SystemId", 'ShopifyVariant."Item SystemId" = Item.SystemId');

        // [THEN] ShopifyVariant."Item Variant SystemId" = ItemVariant.SystemId
        LibraryAssert.AreEqual(ItemVariant.SystemId, ShopifyVariant."Item Variant SystemId", 'ShopifyVariant."Item Variant SystemId" = ItemVariant.SystemId');

        // [THEN] ShopifyProduct."Item SystemId"= Item.SystemId
        LibraryAssert.AreEqual(Item.SystemId, ShopifyProduct."Item SystemId", 'ShopifyProduct."Item SystemId"= Item.SystemId');
    end;

    [Test]
    procedure UnitTestFindMappingWithSKUMappedToVendorItemNo()
    var
        Item: Record Item;
        Shop: Record "Shpfy Shop";
        ShopifyProduct: Record "Shpfy Product";
        ShopifyVariant: Record "Shpfy Variant";
        InitializeTest: Codeunit "Shpfy Initialize Test";
        ProductInitTest: Codeunit "Shpfy Product Init Test";
        ProductMapping: Codeunit "Shpfy Product Mapping";
    begin
        // [SCENARIO] Shopify product to an item and with the SKU mapped to Vendor Item No.
        // [SCENARIO] Because there is no SKU mapping, it will try to find the mapping based on the vendor and SKU field.
        Shop := InitializeTest.CreateShop();
        Shop."SKU Mapping" := "Shpfy SKU Mapping"::"Vendor Item No.";
        Shop.Modify();
        Item := ProductInitTest.CreateItem();
        ShopifyVariant := ProductInitTest.CreateStandardProduct(Shop);
        ShopifyVariant.SKU := Item."Vendor Item No.";
        ShopifyVariant.Modify();
        ShopifyProduct.Get(ShopifyVariant."Product Id");
        ShopifyProduct.Vendor := Item."Vendor No.";
        ShopifyProduct.Modify();

        // [GIVEN] A Shopify Product Record
        // [GIVEN] A Shopify Variant record that belongs to the Shopify Product record and has SKU filled in with the vendor item no.
        ProductMapping.FindMapping(ShopifyProduct, ShopifyVariant);

        // [THEN] ShopifyVariant."Item SystemId" = Item.SystemId
        LibraryAssert.AreEqual(Item.SystemId, ShopifyVariant."Item SystemId", 'ShopifyVariant."Item SystemId" = Item.SystemId');

        // [THEN] ShopifyProduct."Item SystemId"= Item.SystemId
        LibraryAssert.AreEqual(Item.SystemId, ShopifyProduct."Item SystemId", 'ShopifyProduct."Item SystemId"= Item.SystemId');
    end;

    [Test]
    procedure UnitTestFindMappingWithSKUMappedToBarCode()
    var
        Item: Record Item;
        ItemReference: Record "Item Reference";
        Shop: Record "Shpfy Shop";
        ShopifyProduct: Record "Shpfy Product";
        ShopifyVariant: Record "Shpfy Variant";
        InitializeTest: Codeunit "Shpfy Initialize Test";
        ProductInitTest: Codeunit "Shpfy Product Init Test";
        ProductMapping: Codeunit "Shpfy Product Mapping";
        Barcode: Code[50];
    begin
        // [SCENARIO] Shopify product to an item and with the SKU empty.
        // [SCENARIO] Because there is no SKU mapping, it will try to find the mapping based on the bar code in the SKU field on the Shopify Variant record.
        Shop := InitializeTest.CreateShop();
        Shop."SKU Mapping" := "Shpfy SKU Mapping"::"Bar Code";
        Shop.Modify();
        Item := ProductInitTest.CreateItem();
        ItemReference.SetRange("Item No.", Item."No.");
        ItemReference.SetRange("Reference Type", "Item Reference Type"::"Bar Code");
        if ItemReference.FindFirst() then
            BarCode := ItemReference."Reference No.";

        // [GIVEN] A Shopify Product Record
        // [GIVEN] A Shopify Variant record that belongs to the Shopify Product record and has the same barcode of that from the item record.
        ShopifyVariant := ProductInitTest.CreateStandardProduct(Shop);
        ShopifyVariant.SKU := Barcode;
        ShopifyVariant.Modify();
        ShopifyProduct.Get(ShopifyVariant."Product Id");

        // [WHEN] Invoke ProductMapping.FindMapping(ShopifyProduct, ShopifyVariant)
        ProductMapping.FindMapping(ShopifyProduct, ShopifyVariant);

        // [THEN] ShopifyVariant."Item SystemId" = Item.SystemId
        LibraryAssert.AreEqual(Item.SystemId, ShopifyVariant."Item SystemId", 'ShopifyVariant."Item SystemId" = Item.SystemId');

        // [THEN] ShopifyProduct."Item SystemId"= Item.SystemId
        LibraryAssert.AreEqual(Item.SystemId, ShopifyProduct."Item SystemId", 'ShopifyProduct."Item SystemId"= Item.SystemId');
    end;

    [Test]
    procedure UnitTestFindMappingByBarcodeDisabled()
    var
        Item: Record Item;
        ItemReference: Record "Item Reference";
        Shop: Record "Shpfy Shop";
        ShopifyProduct: Record "Shpfy Product";
        ShopifyVariant: Record "Shpfy Variant";
        InitializeTest: Codeunit "Shpfy Initialize Test";
        ProductInitTest: Codeunit "Shpfy Product Init Test";
        ProductMapping: Codeunit "Shpfy Product Mapping";
        EmptyGuid: Guid;
        Barcode: Code[50];
    begin
        // [SCENARIO] When "Find Mapping by Barcode" is disabled on the shop, the barcode fallback should not run.
        // [SCENARIO] Even if the variant has a barcode matching an Item Reference, no mapping should be made.
        Shop := InitializeTest.CreateShop();
        Shop."SKU Mapping" := "Shpfy SKU Mapping"::" ";
        Shop."Find Mapping by Barcode" := false;
        Shop.Modify();
        Item := ProductInitTest.CreateItem();
        ItemReference.SetRange("Item No.", Item."No.");
        ItemReference.SetRange("Reference Type", "Item Reference Type"::"Bar Code");
        if ItemReference.FindFirst() then
            BarCode := ItemReference."Reference No.";

        // [GIVEN] A Shopify Product Record
        // [GIVEN] A Shopify Variant record that belongs to the Shopify Product record and has the same barcode of that from the item record.
        ShopifyVariant := ProductInitTest.CreateStandardProduct(Shop);
        ShopifyVariant.Barcode := Barcode;
        ShopifyVariant.Modify();
        ShopifyProduct.Get(ShopifyVariant."Product Id");

        // [WHEN] Invoke ProductMapping.FindMapping(ShopifyProduct, ShopifyVariant)
        ProductMapping.FindMapping(ShopifyProduct, ShopifyVariant);

        // [THEN] ShopifyVariant."Item SystemId" should be empty (no mapping made)
        LibraryAssert.AreEqual(EmptyGuid, ShopifyVariant."Item SystemId", 'ShopifyVariant."Item SystemId" should be empty when barcode fallback is disabled');

        // [THEN] ShopifyProduct."Item SystemId" should be empty (no mapping made)
        LibraryAssert.AreEqual(EmptyGuid, ShopifyProduct."Item SystemId", 'ShopifyProduct."Item SystemId" should be empty when barcode fallback is disabled');
    end;

    [Test]
    procedure UnitTestGetProductUrlForItemFromFacade()
    var
        Item: Record Item;
        Shop: Record "Shpfy Shop";
        ShopifyProduct: Record "Shpfy Product";
        ShopifyVariant: Record "Shpfy Variant";
        InitializeTest: Codeunit "Shpfy Initialize Test";
        ProductInitTest: Codeunit "Shpfy Product Init Test";
        ShopifyProductMgt: Codeunit "Shpfy Product";
        ActualUrl: Text;
    begin
        // [SCENARIO] The "Shpfy Product" facade returns the Shopify product URL for an item in a shop.

        // [GIVEN] A shop with a Shopify product linked to an item and holding a URL
        Shop := InitializeTest.CreateShop();
        Item := ProductInitTest.CreateItem();
        ShopifyVariant := ProductInitTest.CreateStandardProduct(Shop);
        ShopifyProduct.Get(ShopifyVariant."Product Id");
        ShopifyProduct."Item SystemId" := Item.SystemId;
        ShopifyProduct.URL := ProductUrlTok;
        ShopifyProduct.Modify();

        // [WHEN] Get the product URL through the facade
        ActualUrl := ShopifyProductMgt.GetProductUrl(Item, Shop.Code);

        // [THEN] The facade returns the product's URL
        LibraryAssert.AreEqual(ProductUrlTok, ActualUrl, 'The facade should return the Shopify product URL for the item.');
    end;

    [Test]
    procedure ShowProductActionDisabledWhenVariantMissingOnItemCard()
    var
        Item: Record Item;
        ItemCard: TestPage "Item Card";
    begin
        // [SCENARIO] A mapped product has no Shopify variant linked to the item.
        CreateMappedProductWithoutVariant(Item);

        // [WHEN] The item card is opened.
        ItemCard.OpenEdit();
        ItemCard.GoToRecord(Item);

        // [THEN] The action to show the product in Shopify is disabled.
        LibraryAssert.IsFalse(ItemCard."Show product in Shopify".Enabled(), 'The action should be disabled when no Shopify variant is linked to the item.');
    end;

    [Test]
    procedure ShowProductActionDisabledWhenVariantMissingOnItemList()
    var
        Item: Record Item;
        ItemList: TestPage "Item List";
    begin
        // [SCENARIO] A mapped product has no Shopify variant linked to the item.
        CreateMappedProductWithoutVariant(Item);

        // [WHEN] The item list is opened.
        ItemList.OpenView();
        ItemList.GoToRecord(Item);

        // [THEN] The action to show the product in Shopify is disabled.
        LibraryAssert.IsFalse(ItemList."Show product in Shopify".Enabled(), 'The action should be disabled when no Shopify variant is linked to the item.');
    end;

    [Test]
    procedure GetProductsOverviewShowsClearErrorWhenVariantMissing()
    var
        Item: Record Item;
        ShopifyVariant: Record "Shpfy Variant";
        ShopifyProductMgt: Codeunit "Shpfy Product";
    begin
        // [SCENARIO] Product navigation starts after the linked Shopify variant has been deleted.
        CreateMappedProductWithoutVariant(Item);
        ShopifyVariant.SetRange("Item SystemId", Item.SystemId);

        // [WHEN] The product overview is requested.
        asserterror ShopifyProductMgt.GetProductsOverview(ShopifyVariant);

        // [THEN] A clear mapping error is shown.
        LibraryAssert.ExpectedError('No Shopify product variant is linked to this item. Synchronize products with Shopify, refresh the page, and try again.');
    end;

    local procedure CreateMappedProductWithoutVariant(var Item: Record Item)
    var
        Shop: Record "Shpfy Shop";
        ShopifyProduct: Record "Shpfy Product";
        ShopifyVariant: Record "Shpfy Variant";
        InitializeTest: Codeunit "Shpfy Initialize Test";
        ProductInitTest: Codeunit "Shpfy Product Init Test";
    begin
        Shop := InitializeTest.CreateShop();
        Item := ProductInitTest.CreateItem();
        ShopifyVariant := ProductInitTest.CreateStandardProduct(Shop);
        ShopifyProduct.Get(ShopifyVariant."Product Id");
        ShopifyProduct."Item SystemId" := Item.SystemId;
        ShopifyProduct.Modify();
        ShopifyVariant."Item SystemId" := Item.SystemId;
        ShopifyVariant.Modify();
        ShopifyVariant.Delete();
    end;
}
