// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Foundation.Address;
using Microsoft.Foundation.UOM;
using Microsoft.Integration.Shopify;
using Microsoft.Inventory.Intrastat;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using System.TestLibraries.Utilities;

/// <summary>
/// Codeunit Shpfy Create Item Test (ID 139567).
/// </summary>
codeunit 139567 "Shpfy Create Item Test"
{
    Subtype = Test;
    TestType = Uncategorized;
    TestPermissions = Disabled;

    var
        LibraryAssert: Codeunit "Library Assert";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    procedure UnitTestCreateItemSKUIsItemNo()
    var
        Item: Record Item;
        Shop: Record "Shpfy Shop";
        ShopifyProduct: Record "Shpfy Product";
        ShopifyVariant: Record "Shpfy Variant";
        ItemTempl: Record "Item Templ.";
        ProductInitTest: Codeunit "Shpfy Product Init Test";
        InitializeTest: Codeunit "Shpfy Initialize Test";
    begin
        // [SCENARIO] Create a Item from a Shopify Product with the SKU value containing the Item No.

        // [GIVEN] The Shop with the setting "SKU Mapping" = "Item No.";
        Shop := InitializeTest.CreateShop();
        Shop."SKU Mapping" := "Shpfy SKU Mapping"::"Item No.";
        Shop.Modify();

        // [GIVEN] A Shopify variant record of a standard shopify product. (The variant record always exists, even if the products don't have any variants.)
        ShopifyVariant := ProductInitTest.CreateStandardProduct(Shop);
        ShopifyVariant.SetRecFilter();

        // [WHEN] Executing the report "Shpfy Create Item" with the "Shpfy Variant" Record.
        Codeunit.Run(Codeunit::"Shpfy Create Item", ShopifyVariant);

        // [THEN] On the "Shpfy Variant" record, the field "Item SystemId" must be field in and the Item record must exist.
        LibraryAssert.IsFalse(IsNullGuid(ShopifyVariant."Item SystemId"), 'Item SystemId <> NullGuid');
        LibraryAssert.IsTrue(Item.GetBySystemId(ShopifyVariant."Item SystemId"), 'Get Item');

        // [THEN] On the "Shpfy Variant" record, the field "ITem Variant SystemId" must be a null guid value.
        LibraryAssert.IsTrue(IsNullGuid(ShopifyVariant."Item Variant SystemId"), 'Item Variant System Id = NullGuid');

        // [THEN] Check Item fields
        ShopifyProduct.Get(ShopifyVariant."Product Id");
        LibraryAssert.AreEqual(ShopifyVariant.SKU.ToUpper(), Item."No.", 'Item."No." = SKU');
        LibraryAssert.AreEqual(CopyStr(ShopifyProduct.Title, 1, MaxStrLen(Item.Description)), Item.Description, 'Description');
        LibraryAssert.AreEqual(ShopifyVariant."Unit Cost", Item."Unit Cost", 'Unit Cost');
        LibraryAssert.AreEqual(ShopifyVariant.Price, Item."Unit Price", 'Unit Price');
        ItemTempl.Get(Shop."Item Templ. Code");
        LibraryAssert.AreEqual(ItemTempl."Costing Method", Item."Costing Method", 'Item."Costing Method" = ItemTempl."Costing Method"');
    end;

    [Test]
    procedure UnitTestCreateItemSKUIsItemNoFromProductWithMultiVariants()
    var
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemTempl: Record "Item Templ.";
        Shop: Record "Shpfy Shop";
        ShopifyProduct: Record "Shpfy Product";
        ShopifyVariant: Record "Shpfy Variant";
        ProductInitTest: Codeunit "Shpfy Product Init Test";
        InitializeTest: Codeunit "Shpfy Initialize Test";
    begin
        // [SCENARIO] Create a Items from a Shopify Product with multi variants and the SKU value containing the Item No.

        // [GIVEN] The Shop with the setting "SKU Mapping" = "Item No.";
        Shop := InitializeTest.CreateShop();
        Shop."SKU Mapping" := "Shpfy SKU Mapping"::"Item No.";
        Shop.Modify();

        // [GIVEN] Item template with unit of measure
        ItemTempl.Get(Shop."Item Templ. Code");
        UnitOfMeasure.Code := CopyStr(LibraryRandom.RandText(MaxStrLen(UnitOfMeasure.Code)), 1, MaxStrLen(UnitOfMeasure.Code));
        UnitOfMeasure.Insert();
        ItemTempl."Base Unit of Measure" := UnitOfMeasure.Code;
        ItemTempl.Modify();

        // [GIVEN] A Shopify variant record of a standard shopify product. (The variant record always exists, even if the products don't have any variants.)
        ShopifyVariant := ProductInitTest.CreateProductWithMultiVariants(Shop);

        // [WHEN] Executing the report "Shpfy Create Item" for each record of the "Shpfy Variant" Records filtered on "Product Id".
        ShopifyVariant.SetRange("Product Id", ShopifyVariant."Product Id");
        if ShopifyVariant.FindSet(false) then
            repeat
                Codeunit.Run(Codeunit::"Shpfy Create Item", ShopifyVariant);

                // [THEN] On the "Shpfy Variant" record, the field "Item SystemId" must be field in and the Item record must exist.
                LibraryAssert.IsFalse(IsNullGuid(ShopifyVariant."Item SystemId"), 'Item SystemId <> NullGuid');
                LibraryAssert.IsTrue(Item.GetBySystemId(ShopifyVariant."Item SystemId"), 'Get Item');

                // [THEN] On the "Shpfy Variant" record, the field "ITem Variant SystemId" must be a null guid value.
                LibraryAssert.IsTrue(IsNullGuid(ShopifyVariant."Item Variant SystemId"), 'Item Variant System Id = NullGuid');

                // [THEN] Check Item fields
                ShopifyProduct.Get(ShopifyVariant."Product Id");
                LibraryAssert.AreEqual(ShopifyVariant.SKU.ToUpper(), Item."No.", 'Item."No." = SKU');
                LibraryAssert.AreEqual(CopyStr(ShopifyProduct.Title, 1, MaxStrLen(Item.Description)), Item.Description, 'Description');
                LibraryAssert.AreEqual(ShopifyVariant."Unit Cost", Item."Unit Cost", 'Unit Cost');
                LibraryAssert.AreEqual(ShopifyVariant.Price, Item."Unit Price", 'Unit Price');

                // [THEN] Check Item unit of measure
                LibraryAssert.AreEqual(ItemTempl."Base Unit of Measure", Item."Base Unit of Measure", 'Item."Base Unit of Measure" = ItemTempl."Base Unit of Measure"');
                ItemUnitOfMeasure.SetRange("Item No.", Item."No.");
                LibraryAssert.RecordIsNotEmpty(ItemUnitOfMeasure);
            until ShopifyVariant.Next() = 0;
    end;

    [Test]
    procedure UnitTestCreateItemSKUIsItemNoAndVariantCode()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        Shop: Record "Shpfy Shop";
        ShopifyProduct: Record "Shpfy Product";
        ShopifyVariant: Record "Shpfy Variant";
        ProductInitTest: Codeunit "Shpfy Product Init Test";
        InitializeTest: Codeunit "Shpfy Initialize Test";
    begin
        // [SCENARIO] Create a Item from a Shopify Product with the SKU value containing the Item No and Variant Code.

        // [GIVEN] The Shop with the setting "SKU Mapping" = "Item No. + Variant code";
        Shop := InitializeTest.CreateShop();
        Shop."SKU Mapping" := "Shpfy SKU Mapping"::"Item No. + Variant Code";
        Shop.Modify();

        // [GIVEN] A Shopify variant record of a standard shopify product. (The variant record always exists, even if the products don't have any variants.)
        ShopifyVariant := ProductInitTest.CreateProductWithVariantCode(Shop);
        ShopifyVariant.SetRecFilter();

        // [WHEN] Executing the report "Shpfy Create Item" with the "Shpfy Variant" Record.
        Codeunit.Run(Codeunit::"Shpfy Create Item", ShopifyVariant);

        // [THEN] On the "Shpfy Variant" record, the field "Item SystemId" must be filled in and the Item record must exist.
        LibraryAssert.IsFalse(IsNullGuid(ShopifyVariant."Item SystemId"), 'Item SystemId <> NullGuid');
        LibraryAssert.IsTrue(Item.GetBySystemId(ShopifyVariant."Item SystemId"), 'Get Item');

        // [THEN] On the "Shpfy Variant" record, the field "ITem Variant SystemId" filled in and then "Item Variant" record must exist..
        LibraryAssert.IsFalse(IsNullGuid(ShopifyVariant."Item Variant SystemId"), 'Item Variant System Id <> NullGuid');
        LibraryAssert.IsTrue(ItemVariant.GetBySystemId(ShopifyVariant."Item Variant SystemId"), 'Get Item Variant');

        // [THEN] Check Item fields
        ShopifyProduct.Get(ShopifyVariant."Product Id");
        LibraryAssert.AreEqual(ShopifyVariant.SKU.ToUpper().Split(Shop."SKU Field Separator").Get(1), Item."No.", 'Item."No." = SKU.Spilt(Shop."SKU Field Separator")[1]');
        LibraryAssert.AreEqual(CopyStr(ShopifyProduct.Title, 1, MaxStrLen(Item.Description)), Item.Description, 'Description');
        LibraryAssert.AreEqual(ShopifyVariant."Unit Cost", Item."Unit Cost", 'Unit Cost');
        LibraryAssert.AreEqual(ShopifyVariant.Price, Item."Unit Price", 'Unit Price');

        // [THEN] The 'Item Variant".Code must be equal to the variant part of the SKU.
        LibraryAssert.AreEqual(ShopifyVariant.SKU.ToUpper().Split(Shop."SKU Field Separator").Get(2), ItemVariant.Code, '"Item Variant".Code." = SKU.Spilt(Shop."SKU Field Separator")[2]');
    end;

    [Test]
    procedure UnitTestCreateItemSKUIsItemNoAndVariantCodeFromProductWithMultiVariants()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        Shop: Record "Shpfy Shop";
        ShopifyProduct: Record "Shpfy Product";
        ShopifyVariant: Record "Shpfy Variant";
        ProductInitTest: Codeunit "Shpfy Product Init Test";
        InitializeTest: Codeunit "Shpfy Initialize Test";
        FirstVariant: Boolean;
    begin
        // [SCENARIO] Create a Item from a Shopify Product with the SKU value containing the Item No and Variant Code.

        // [GIVEN] The Shop with the setting "SKU Mapping" = "Item No. + Variant Code";
        Shop := InitializeTest.CreateShop();
        Shop."SKU Mapping" := "Shpfy SKU Mapping"::"Item No. + Variant Code";
        Shop.Modify();

        // [GIVEN] A Shopify variant record of a standard shopify product. (The variant record always exists, even if the products don't have any variants.)
        ShopifyVariant := ProductInitTest.CreateProductWithMultiVariants(Shop);
        ShopifyVariant.SetRecFilter();

        // [WHEN] Executing the report "Shpfy Create Item" for each record of the "Shpfy Variant" Records filtered on "Product Id".
        ShopifyVariant.SetRange("Product Id", ShopifyVariant."Product Id");
        if ShopifyVariant.FindSet(false) then begin
            FirstVariant := true;
            repeat
                Codeunit.Run(Codeunit::"Shpfy Create Item", ShopifyVariant);

                // [THEN] On the "Shpfy Variant" record, the field "Item SystemId" must be filled in and the Item record must exist.
                LibraryAssert.IsFalse(IsNullGuid(ShopifyVariant."Item SystemId"), 'Item SystemId <> NullGuid');
                LibraryAssert.IsTrue(Item.GetBySystemId(ShopifyVariant."Item SystemId"), 'Get Item');

                // [THEN] On the "Shpfy Variant" record, the field "ITem Variant SystemId" filled in and then "Item Variant" record must exist..
                LibraryAssert.IsFalse(IsNullGuid(ShopifyVariant."Item Variant SystemId"), 'Item Variant System Id <> NullGuid');
                LibraryAssert.IsTrue(ItemVariant.GetBySystemId(ShopifyVariant."Item Variant SystemId"), 'Get Item Variant');

                // [THEN] Check Item fields
                ShopifyProduct.Get(ShopifyVariant."Product Id");
                LibraryAssert.AreEqual(ShopifyVariant.SKU.ToUpper().Split(Shop."SKU Field Separator").Get(1), Item."No.", 'Item."No." = SKU.Spilt(Shop."SKU Field Separator")[1]');
                LibraryAssert.AreEqual(CopyStr(ShopifyProduct.Title, 1, MaxStrLen(Item.Description)), Item.Description, 'Description');
                if FirstVariant then begin
                    LibraryAssert.AreEqual(ShopifyVariant."Unit Cost", Item."Unit Cost", 'Unit Cost');
                    LibraryAssert.AreEqual(ShopifyVariant.Price, Item."Unit Price", 'Unit Price');
                end;

                // [THEN] The 'Item Variant".Code must be equal to the variant part of the SKU.
                LibraryAssert.AreEqual(ShopifyVariant.SKU.ToUpper().Split(Shop."SKU Field Separator").Get(2), ItemVariant.Code, '"Item Variant".Code." = SKU.Spilt(Shop."SKU Field Separator")[2]');
            until ShopifyVariant.Next() = 0;
        end;
    end;

    [Test]
    procedure UnitTestCreateItemSKUIsVariantCode()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        Shop: Record "Shpfy Shop";
        ShopifyProduct: Record "Shpfy Product";
        ShopifyVariant: Record "Shpfy Variant";
        ProductInitTest: Codeunit "Shpfy Product Init Test";
        InitializeTest: Codeunit "Shpfy Initialize Test";
    begin
        // [SCENARIO] Create a Item from a Shopify Product with the SKU value containing the Variant Code.

        // [GIVEN] The Shop with the setting "SKU Mapping" = "Variant Code";
        Shop := InitializeTest.CreateShop();
        Shop."SKU Mapping" := "Shpfy SKU Mapping"::"Variant Code";
        Shop.Modify();

        // [GIVEN] A Shopify variant record of a standard shopify product. (The variant record always exists, even if the products don't have any variants.)
        ShopifyVariant := ProductInitTest.CreateProductWithVariantCode(Shop);
        ShopifyVariant.SetRecFilter();

        // [WHEN] Executing the report "Shpfy Create Item" with the "Shpfy Variant" Record.
        Codeunit.Run(Codeunit::"Shpfy Create Item", ShopifyVariant);

        // [THEN] On the "Shpfy Variant" record, the field "Item SystemId" must be filled in and the Item record must exist.
        LibraryAssert.IsFalse(IsNullGuid(ShopifyVariant."Item SystemId"), 'Item SystemId <> NullGuid');
        LibraryAssert.IsTrue(Item.GetBySystemId(ShopifyVariant."Item SystemId"), 'Get Item');

        // [THEN] On the "Shpfy Variant" record, the field "ITem Variant SystemId" filled in and then "Item Variant" record must exist..
        LibraryAssert.IsFalse(IsNullGuid(ShopifyVariant."Item Variant SystemId"), 'Item Variant System Id <> NullGuid');
        LibraryAssert.IsTrue(ItemVariant.GetBySystemId(ShopifyVariant."Item Variant SystemId"), 'Get Item Variant');

        // [THEN] Check Item fields
        ShopifyProduct.Get(ShopifyVariant."Product Id");
        LibraryAssert.AreEqual(CopyStr(ShopifyProduct.Title, 1, MaxStrLen(Item.Description)), Item.Description, 'Description');
        LibraryAssert.AreEqual(ShopifyVariant."Unit Cost", Item."Unit Cost", 'Unit Cost');
        LibraryAssert.AreEqual(ShopifyVariant.Price, Item."Unit Price", 'Unit Price');

        // [THEN] The 'Item Variant".Code must be equal to the SKU.
        LibraryAssert.AreEqual(ShopifyVariant.SKU.ToUpper(), ItemVariant.Code, '"Item Variant".Code" = SKU');
    end;

    [Test]
    procedure UnitTestCreateItemSKUIsVariantCodeFromProductWithMultiVariants()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        Shop: Record "Shpfy Shop";
        ShopifyProduct: Record "Shpfy Product";
        ShopifyVariant: Record "Shpfy Variant";
        ProductInitTest: Codeunit "Shpfy Product Init Test";
        InitializeTest: Codeunit "Shpfy Initialize Test";
    begin
        // [SCENARIO] Create a Item from a Shopify Product with the SKU value containing the  Variant Code.

        // [GIVEN] The Shop with the setting "SKU Mapping" = "Variant Code";
        Shop := InitializeTest.CreateShop();
        Shop."SKU Mapping" := "Shpfy SKU Mapping"::"Variant Code";
        Shop.Modify();

        // [GIVEN] A Shopify variant record of a standard shopify product. (The variant record always exists, even if the products don't have any variants.)
        ShopifyVariant := ProductInitTest.CreateProductWithMultiVariants(Shop);
        ShopifyVariant.SetRecFilter();

        // [WHEN] Executing the report "Shpfy Create Item" for each record of the "Shpfy Variant" Records filtered on "Product Id".
        ShopifyVariant.SetRange("Product Id", ShopifyVariant."Product Id");
        if ShopifyVariant.FindSet(false) then
            repeat
                Codeunit.Run(Codeunit::"Shpfy Create Item", ShopifyVariant);

                // [THEN] On the "Shpfy Variant" record, the field "Item SystemId" must be filled in and the Item record must exist.
                LibraryAssert.IsFalse(IsNullGuid(ShopifyVariant."Item SystemId"), 'Item SystemId <> NullGuid');
                LibraryAssert.IsTrue(Item.GetBySystemId(ShopifyVariant."Item SystemId"), 'Get Item');

                // [THEN] On the "Shpfy Variant" record, the field "ITem Variant SystemId" filled in and then "Item Variant" record must exist..
                LibraryAssert.IsFalse(IsNullGuid(ShopifyVariant."Item Variant SystemId"), 'Item Variant System Id <> NullGuid');
                LibraryAssert.IsTrue(ItemVariant.GetBySystemId(ShopifyVariant."Item Variant SystemId"), 'Get Item Variant');

                // [THEN] Check Item fields
                ShopifyProduct.Get(ShopifyVariant."Product Id");
                LibraryAssert.AreEqual(CopyStr(ShopifyProduct.Title, 1, MaxStrLen(Item.Description)), Item.Description, 'Description');

                // [THEN] The 'Item Variant".Code must be equal to the SKU.
                LibraryAssert.AreEqual(ShopifyVariant.SKU.ToUpper(), ItemVariant.Code, '"Item Variant".Code" = SKU');
            until ShopifyVariant.Next() = 0;
    end;

    [Test]
    procedure UnitTestCreateItemSKUIsVendorItemNo()
    var
        Item: Record Item;
        ShopifyProduct: Record "Shpfy Product";
        Shop: Record "Shpfy Shop";
        ShopifyVariant: Record "Shpfy Variant";
        ItemReference: Record "Item Reference";
        InitializeTest: Codeunit "Shpfy Initialize Test";
        ProductInitTest: Codeunit "Shpfy Product Init Test";
    begin
        // [SCENARIO] Create a Item from a Shopify Product with the SKU value containing the Vendor Item No.

        // [GIVEN] The Shop with the setting "SKU Mapping" = "Vendor Item No.";
        Shop := InitializeTest.CreateShop();
        Shop."SKU Mapping" := "Shpfy SKU Mapping"::"Vendor Item No.";
        Shop.Modify();

        // [GIVEN] A Shopify variant record of a standard shopify product. (The variant record always exists, even if the products don't have any variants.)
        ShopifyVariant := ProductInitTest.CreateStandardProduct(Shop);
        ShopifyVariant.SetRecFilter();

        // [WHEN] Executing the report "Shpfy Create Item" with the "Shpfy Variant" Record.
        Codeunit.Run(Codeunit::"Shpfy Create Item", ShopifyVariant);

        // [THEN] On the "Shpfy Variant" record, the field "Item SystemId" must be filled in and the Item record must exist.
        LibraryAssert.IsFalse(IsNullGuid(ShopifyVariant."Item SystemId"), 'Item SystemId <> NullGuid');
        LibraryAssert.IsTrue(Item.GetBySystemId(ShopifyVariant."Item SystemId"), 'Get Item');

        // [THEN] Check Item fields
        ShopifyProduct.Get(ShopifyVariant."Product Id");
        LibraryAssert.AreEqual(CopyStr(ShopifyProduct.Title, 1, MaxStrLen(Item.Description)), Item.Description, 'Description');
        LibraryAssert.AreEqual(ShopifyVariant."Unit Cost", Item."Unit Cost", 'Unit Cost');
        LibraryAssert.AreEqual(ShopifyVariant.Price, Item."Unit Price", 'Unit Price');

        // [THEN] Check Vendor Item Reference exsist
        ItemReference.SetRange("Item No.", Item."No.");
        ItemReference.SetRange("Reference Type", "Item Reference Type"::Vendor);
        ItemReference.SetRange("Reference Type No.", Item."Vendor No.");
        ItemReference.SetRange("Reference No.", ShopifyVariant.SKU);
        LibraryAssert.RecordIsNotEmpty(ItemReference);
    end;

    [Test]
    procedure UnitTestCreateItemSKUIsVendorItemFromProductWithMultiVariants()
    var
        Item: Record Item;
        Shop: Record "Shpfy Shop";
        ShopifyProduct: Record "Shpfy Product";
        ShopifyVariant: Record "Shpfy Variant";
        ItemReference: Record "Item Reference";
        ProductInitTest: Codeunit "Shpfy Product Init Test";
        InitializeTest: Codeunit "Shpfy Initialize Test";
    begin
        // [SCENARIO] Create a Item from a Shopify Product with the SKU value containing the  Vendor Item No.

        // [GIVEN] The Shop with the setting "SKU Mapping" = "Vendor Item No.";
        Shop := InitializeTest.CreateShop();
        Shop."SKU Mapping" := "Shpfy SKU Mapping"::"Vendor Item No.";
        Shop.Modify();

        // [GIVEN] A Shopify variant record of a standard shopify product. (The variant record always exists, even if the products don't have any variants.)
        ShopifyVariant := ProductInitTest.CreateProductWithMultiVariants(Shop);
        ShopifyVariant.SetRecFilter();

        // [WHEN] Executing the report "Shpfy Create Item" for each record of the "Shpfy Variant" Records filtered on "Product Id".
        ShopifyVariant.SetRange("Product Id", ShopifyVariant."Product Id");
        if ShopifyVariant.FindSet(false) then
            repeat
                Codeunit.Run(Codeunit::"Shpfy Create Item", ShopifyVariant);

                // [THEN] On the "Shpfy Variant" record, the field "Item SystemId" must be filled in and the Item record must exist.
                LibraryAssert.IsFalse(IsNullGuid(ShopifyVariant."Item SystemId"), 'Item SystemId <> NullGuid');
                LibraryAssert.IsTrue(Item.GetBySystemId(ShopifyVariant."Item SystemId"), 'Get Item');

                // [THEN] Check Item fields
                ShopifyProduct.Get(ShopifyVariant."Product Id");
                LibraryAssert.AreEqual(CopyStr(ShopifyProduct.Title, 1, MaxStrLen(Item.Description)), Item.Description, 'Description');
                LibraryAssert.AreEqual(ShopifyVariant."Unit Cost", Item."Unit Cost", 'Unit Cost');
                LibraryAssert.AreEqual(ShopifyVariant.Price, Item."Unit Price", 'Unit Price');

                // [THEN] Check Vendor Item Reference exsist
                ItemReference.SetRange("Item No.", Item."No.");
                ItemReference.SetRange("Reference Type", "Item Reference Type"::Vendor);
                ItemReference.SetRange("Reference Type No.", Item."Vendor No.");
                ItemReference.SetRange("Reference No.", ShopifyVariant.SKU);
                LibraryAssert.RecordIsNotEmpty(ItemReference);
            until ShopifyVariant.Next() = 0;
    end;

    [Test]
    procedure UnitTestCreateItemSKUIsBarcode()
    var
        Item: Record Item;
        ShopifyProduct: Record "Shpfy Product";
        Shop: Record "Shpfy Shop";
        ShopifyVariant: Record "Shpfy Variant";
        ItemReference: Record "Item Reference";
        InitializeTest: Codeunit "Shpfy Initialize Test";
        ProductInitTest: Codeunit "Shpfy Product Init Test";
    begin
        // [SCENARIO] Create a Item from a Shopify Product with the SKU value containing the Bar Code.

        // [GIVEN] The Shop with the setting "SKU Mapping" = "Bar Code";
        Shop := InitializeTest.CreateShop();
        Shop."SKU Mapping" := "Shpfy SKU Mapping"::"Bar Code";
        Shop.Modify();

        // [GIVEN] A Shopify variant record of a standard shopify product. (The variant record always exists, even if the products don't have any variants.)
        ShopifyVariant := ProductInitTest.CreateStandardProduct(Shop);
        ShopifyVariant.SetRecFilter();

        // [WHEN] Executing the report "Shpfy Create Item" with the "Shpfy Variant" Record.
        Codeunit.Run(Codeunit::"Shpfy Create Item", ShopifyVariant);

        // [THEN] On the "Shpfy Variant" record, the field "Item SystemId" must be filled in and the Item record must exist.
        LibraryAssert.IsFalse(IsNullGuid(ShopifyVariant."Item SystemId"), 'Item SystemId <> NullGuid');
        LibraryAssert.IsTrue(Item.GetBySystemId(ShopifyVariant."Item SystemId"), 'Get Item');

        // [THEN] Check Item fields
        ShopifyProduct.Get(ShopifyVariant."Product Id");
        LibraryAssert.AreEqual(CopyStr(ShopifyProduct.Title, 1, MaxStrLen(Item.Description)), Item.Description, 'Description');
        LibraryAssert.AreEqual(ShopifyVariant."Unit Cost", Item."Unit Cost", 'Unit Cost');
        LibraryAssert.AreEqual(ShopifyVariant.Price, Item."Unit Price", 'Unit Price');

        // [THEN] Check Vendor Item Reference exsist
        ItemReference.SetRange("Item No.", Item."No.");
        ItemReference.SetRange("Reference Type", "Item Reference Type"::"Bar Code");
        ItemReference.SetRange("Reference Type No.", '');
        ItemReference.SetRange("Reference No.", ShopifyVariant.SKU);
        LibraryAssert.RecordIsNotEmpty(ItemReference);
    end;

    [Test]
    procedure UnitTestCreateItemSKUIsBarcodeFromProductWithMultiVariants()
    var
        Item: Record Item;
        Shop: Record "Shpfy Shop";
        ShopifyProduct: Record "Shpfy Product";
        ShopifyVariant: Record "Shpfy Variant";
        ItemReference: Record "Item Reference";
        ProductInitTest: Codeunit "Shpfy Product Init Test";
        InitializeTest: Codeunit "Shpfy Initialize Test";
    begin
        // [SCENARIO] Create a Item from a Shopify Product with the SKU value containing the  Bar Code.

        // [GIVEN] The Shop with the setting "SKU Mapping" = "Bar Code";
        Shop := InitializeTest.CreateShop();
        Shop."SKU Mapping" := "Shpfy SKU Mapping"::"Bar Code";
        Shop.Modify();

        // [GIVEN] A Shopify variant record of a standard shopify product. (The variant record always exists, even if the products don't have any variants.)
        ShopifyVariant := ProductInitTest.CreateProductWithMultiVariants(Shop);
        ShopifyVariant.SetRecFilter();

        // [WHEN] Executing the report "Shpfy Create Item" for each record of the "Shpfy Variant" Records filtered on "Product Id".
        ShopifyVariant.SetRange("Product Id", ShopifyVariant."Product Id");
        if ShopifyVariant.FindSet(false) then
            repeat
                Codeunit.Run(Codeunit::"Shpfy Create Item", ShopifyVariant);

                // [THEN] On the "Shpfy Variant" record, the field "Item SystemId" must be filled in and the Item record must exist.
                LibraryAssert.IsFalse(IsNullGuid(ShopifyVariant."Item SystemId"), 'Item SystemId <> NullGuid');
                LibraryAssert.IsTrue(Item.GetBySystemId(ShopifyVariant."Item SystemId"), 'Get Item');

                // [THEN] Check Item fields
                ShopifyProduct.Get(ShopifyVariant."Product Id");
                LibraryAssert.AreEqual(CopyStr(ShopifyProduct.Title, 1, MaxStrLen(Item.Description)), Item.Description, 'Description');
                LibraryAssert.AreEqual(ShopifyVariant."Unit Cost", Item."Unit Cost", 'Unit Cost');
                LibraryAssert.AreEqual(ShopifyVariant.Price, Item."Unit Price", 'Unit Price');

                // [THEN] Check Vendor Item Reference exsist
                ItemReference.SetRange("Item No.", Item."No.");
                ItemReference.SetRange("Reference Type", "Item Reference Type"::"Bar Code");
                ItemReference.SetRange("Reference Type No.", '');
                ItemReference.SetRange("Reference No.", ShopifyVariant.SKU);
                LibraryAssert.RecordIsNotEmpty(ItemReference);
            until ShopifyVariant.Next() = 0;
    end;

    [Test]
    procedure UnitTestCreateItemFCYToLCYConversion()
    var
        Item: Record Item;
        Shop: Record "Shpfy Shop";
        ShopifyVariant: Record "Shpfy Variant";
        ProductInitTest: Codeunit "Shpfy Product Init Test";
        InitializeTest: Codeunit "Shpfy Initialize Test";
    begin
        // [SCENARIO] Create a Item from a Shopify Product with the SKU value containing the Item No.

        // [GIVEN] The Shop with the setting "SKU Mapping" = "Item No.";
        Shop := InitializeTest.CreateShop();
        Shop."SKU Mapping" := "Shpfy SKU Mapping"::"Item No.";
        Shop."Currency Code" := CreateCurrencyAndExchangeRate(2, 2);
        Shop.Modify();

        // [GIVEN] A Shopify variant record of a standard shopify product. (The variant record always exists, even if the products don't have any variants.)
        ShopifyVariant := ProductInitTest.CreateStandardProduct(Shop);
        ShopifyVariant.Price := 10;
        ShopifyVariant."Unit Cost" := 6;
        ShopifyVariant.Modify();
        ShopifyVariant.SetRecFilter();

        // [WHEN] Executing the report "Shpfy Create Item" with the "Shpfy Variant" Record.
        Codeunit.Run(Codeunit::"Shpfy Create Item", ShopifyVariant);

        // [THEN] Check Item fields
        LibraryAssert.IsTrue(Item.GetBySystemId(ShopifyVariant."Item SystemId"), 'Get Item');
        LibraryAssert.AreNearlyEqual(ShopifyVariant."Unit Cost" / 2, Item."Unit Cost", 0.1, 'Unit Cost');
        LibraryAssert.AreNearlyEqual(ShopifyVariant.Price / 2, Item."Unit Price", 0.1, 'Unit Price');
    end;

    [Test]
    procedure UnitTestCreateItemSyncsHSCodeAndCountryOfOrigin()
    var
        Item: Record Item;
        CountryRegion: Record "Country/Region";
        Shop: Record "Shpfy Shop";
        ShopifyVariant: Record "Shpfy Variant";
        ProductInitTest: Codeunit "Shpfy Product Init Test";
        InitializeTest: Codeunit "Shpfy Initialize Test";
        TariffNo: Code[20];
    begin
        // [SCENARIO 642046] Importing a Shopify product populates the item's Tariff No. and Country/Region of Origin Code when HS/Country sync is enabled.

        // [GIVEN] A shop with "Sync HS Code and Country" enabled and "SKU Mapping" = "Item No.".
        Shop := InitializeTest.CreateShop();
        Shop."SKU Mapping" := "Shpfy SKU Mapping"::"Item No.";
        Shop."Sync HS Code and Country" := true;
        Shop.Modify();

        // [GIVEN] A Country/Region with an ISO Code that differs from its code.
        CountryRegion := CreateCountryRegionWithISOCode();

        // [GIVEN] A Tariff Number that already exists in Business Central.
        TariffNo := CreateTariffNumber();

        // [GIVEN] A Shopify variant with the Tariff No. and the ISO country code of origin.
        ShopifyVariant := ProductInitTest.CreateStandardProduct(Shop);
        ShopifyVariant."Tariff No." := TariffNo;
        ShopifyVariant."Country/Region of Origin Code" := CountryRegion."ISO Code";
        ShopifyVariant.Modify();
        ShopifyVariant.SetRecFilter();

        // [WHEN] Executing the codeunit "Shpfy Create Item" with the "Shpfy Variant" record.
        Codeunit.Run(Codeunit::"Shpfy Create Item", ShopifyVariant);

        // [THEN] The created item has the Tariff No. from the Shopify variant.
        LibraryAssert.IsTrue(Item.GetBySystemId(ShopifyVariant."Item SystemId"), 'Get Item');
        LibraryAssert.AreEqual(TariffNo, Item."Tariff No.", 'Item."Tariff No." should match the Shopify variant Tariff No.');

        // [THEN] The created item has the Country/Region of Origin Code resolved from the Shopify ISO code.
        LibraryAssert.AreEqual(CountryRegion.Code, Item."Country/Region of Origin Code", 'Item."Country/Region of Origin Code" should be resolved from the ISO code.');
    end;

    [Test]
    procedure UnitTestCreateItemSkipsHSCodeAndCountryWhenSyncDisabled()
    var
        Item: Record Item;
        Shop: Record "Shpfy Shop";
        ShopifyVariant: Record "Shpfy Variant";
        ProductInitTest: Codeunit "Shpfy Product Init Test";
        InitializeTest: Codeunit "Shpfy Initialize Test";
    begin
        // [SCENARIO 642046] Importing a Shopify product does not populate the item's Tariff No. and Country/Region of Origin Code when HS/Country sync is disabled.

        // [GIVEN] A shop with "Sync HS Code and Country" disabled and "SKU Mapping" = "Item No.".
        Shop := InitializeTest.CreateShop();
        Shop."SKU Mapping" := "Shpfy SKU Mapping"::"Item No.";
        Shop."Sync HS Code and Country" := false;
        Shop.Modify();

        // [GIVEN] A Shopify variant with a Tariff No. and country code of origin.
        ShopifyVariant := ProductInitTest.CreateStandardProduct(Shop);
        ShopifyVariant."Tariff No." := '6104.43';
        ShopifyVariant."Country/Region of Origin Code" := 'US';
        ShopifyVariant.Modify();
        ShopifyVariant.SetRecFilter();

        // [WHEN] Executing the codeunit "Shpfy Create Item" with the "Shpfy Variant" record.
        Codeunit.Run(Codeunit::"Shpfy Create Item", ShopifyVariant);

        // [THEN] The created item has no Tariff No. and no Country/Region of Origin Code.
        LibraryAssert.IsTrue(Item.GetBySystemId(ShopifyVariant."Item SystemId"), 'Get Item');
        LibraryAssert.AreEqual('', Item."Tariff No.", 'Item."Tariff No." should be empty when sync is disabled.');
        LibraryAssert.AreEqual('', Item."Country/Region of Origin Code", 'Item."Country/Region of Origin Code" should be empty when sync is disabled.');
    end;

    [Test]
    procedure UnitTestCreateItemSkipsTariffNoWhenNotInBC()
    var
        Item: Record Item;
        TariffNumber: Record "Tariff Number";
        Shop: Record "Shpfy Shop";
        ShopifyVariant: Record "Shpfy Variant";
        ProductInitTest: Codeunit "Shpfy Product Init Test";
        InitializeTest: Codeunit "Shpfy Initialize Test";
        UnknownTariffNo: Code[20];
    begin
        // [SCENARIO 642046] Importing a Shopify product does not populate the item's Tariff No. when the tariff number does not exist in Business Central.

        // [GIVEN] A shop with "Sync HS Code and Country" enabled and "SKU Mapping" = "Item No.".
        Shop := InitializeTest.CreateShop();
        Shop."SKU Mapping" := "Shpfy SKU Mapping"::"Item No.";
        Shop."Sync HS Code and Country" := true;
        Shop.Modify();

        // [GIVEN] A tariff number that does not exist in Business Central.
        UnknownTariffNo := CopyStr(LibraryRandom.RandText(MaxStrLen(UnknownTariffNo)), 1, MaxStrLen(UnknownTariffNo));
        if TariffNumber.Get(UnknownTariffNo) then
            TariffNumber.Delete();

        // [GIVEN] A Shopify variant with that Tariff No.
        ShopifyVariant := ProductInitTest.CreateStandardProduct(Shop);
        ShopifyVariant."Tariff No." := UnknownTariffNo;
        ShopifyVariant.Modify();
        ShopifyVariant.SetRecFilter();

        // [WHEN] Executing the codeunit "Shpfy Create Item" with the "Shpfy Variant" record.
        Codeunit.Run(Codeunit::"Shpfy Create Item", ShopifyVariant);

        // [THEN] The created item has no Tariff No. and no new Tariff Number was created.
        LibraryAssert.IsTrue(Item.GetBySystemId(ShopifyVariant."Item SystemId"), 'Get Item');
        LibraryAssert.AreEqual('', Item."Tariff No.", 'Item."Tariff No." should be empty when the tariff does not exist in BC.');
        LibraryAssert.IsFalse(TariffNumber.Get(UnknownTariffNo), 'No Tariff Number should be created in BC.');
    end;

    [Test]
    procedure UnitTestCreateItemMatchesTariffNoWithoutSeparators()
    var
        Item: Record Item;
        TariffNumber: Record "Tariff Number";
        Shop: Record "Shpfy Shop";
        ShopifyVariant: Record "Shpfy Variant";
        ProductInitTest: Codeunit "Shpfy Product Init Test";
        InitializeTest: Codeunit "Shpfy Initialize Test";
        DottedTariffNo: Code[20];
        DigitsTariffNo: Code[20];
    begin
        // [SCENARIO 642046] Shopify returns the HS code without separators, so the item must still match a BC Tariff Number that is stored with separators.

        // [GIVEN] A shop with "Sync HS Code and Country" enabled and "SKU Mapping" = "Item No.".
        Shop := InitializeTest.CreateShop();
        Shop."SKU Mapping" := "Shpfy SKU Mapping"::"Item No.";
        Shop."Sync HS Code and Country" := true;
        Shop.Modify();

        // [GIVEN] A BC Tariff Number stored with a separator (e.g. "6104.43").
        DottedTariffNo := CreateDottedTariffNumber();
        DigitsTariffNo := CopyStr(DelChr(DottedTariffNo, '=', '.'), 1, MaxStrLen(DigitsTariffNo));

        // [GIVEN] A Shopify variant whose HS code has no separators, as Shopify returns it (e.g. "610443").
        ShopifyVariant := ProductInitTest.CreateStandardProduct(Shop);
        ShopifyVariant."Tariff No." := DigitsTariffNo;
        ShopifyVariant.Modify();
        ShopifyVariant.SetRecFilter();

        // [WHEN] Executing the codeunit "Shpfy Create Item" with the "Shpfy Variant" record.
        Codeunit.Run(Codeunit::"Shpfy Create Item", ShopifyVariant);

        // [THEN] The created item is assigned the BC Tariff Number stored with the separator.
        LibraryAssert.IsTrue(Item.GetBySystemId(ShopifyVariant."Item SystemId"), 'Get Item');
        LibraryAssert.AreEqual(DottedTariffNo, Item."Tariff No.", 'Item should match the BC Tariff Number stored with a separator.');

        // [THEN] No extra Tariff Number was created for the separator-less value.
        LibraryAssert.IsFalse(TariffNumber.Get(DigitsTariffNo), 'No Tariff Number should be created for the separator-less value.');
    end;

    [Test]
    procedure UnitTestUpdateItemSyncsHSCodeAndCountryOfOrigin()
    var
        Item: Record Item;
        CountryRegion: Record "Country/Region";
        Shop: Record "Shpfy Shop";
        ShopifyVariant: Record "Shpfy Variant";
        ProductInitTest: Codeunit "Shpfy Product Init Test";
        InitializeTest: Codeunit "Shpfy Initialize Test";
        TariffNo: Code[20];
    begin
        // [SCENARIO 642046] Updating an existing item from Shopify refreshes the Tariff No. and Country/Region of Origin Code when HS/Country sync is enabled.

        // [GIVEN] A shop with "Sync HS Code and Country" enabled and "SKU Mapping" = "Item No.".
        Shop := InitializeTest.CreateShop();
        Shop."SKU Mapping" := "Shpfy SKU Mapping"::"Item No.";
        Shop."Sync HS Code and Country" := true;
        Shop.Modify();

        // [GIVEN] A Country/Region and a Tariff Number that exist in Business Central.
        CountryRegion := CreateCountryRegionWithISOCode();
        TariffNo := CreateTariffNumber();

        // [GIVEN] A Shopify variant already imported as a BC item (initially without HS code/country).
        ShopifyVariant := ProductInitTest.CreateStandardProduct(Shop);
        ShopifyVariant.SetRecFilter();
        Codeunit.Run(Codeunit::"Shpfy Create Item", ShopifyVariant);
        ShopifyVariant.Get(ShopifyVariant.Id);
        LibraryAssert.IsTrue(Item.GetBySystemId(ShopifyVariant."Item SystemId"), 'Get Item');

        // [GIVEN] Shopify now reports a Tariff No. and country of origin on the variant.
        ShopifyVariant."Tariff No." := TariffNo;
        ShopifyVariant."Country/Region of Origin Code" := CountryRegion."ISO Code";
        ShopifyVariant.Modify();
        ShopifyVariant.SetRecFilter();

        // [WHEN] Executing the codeunit "Shpfy Update Item" with the "Shpfy Variant" record.
        Codeunit.Run(Codeunit::"Shpfy Update Item", ShopifyVariant);

        // [THEN] The item's Tariff No. and Country/Region of Origin Code are updated from Shopify.
        Item.GetBySystemId(ShopifyVariant."Item SystemId");
        LibraryAssert.AreEqual(TariffNo, Item."Tariff No.", 'Item."Tariff No." should be updated from Shopify.');
        LibraryAssert.AreEqual(CountryRegion.Code, Item."Country/Region of Origin Code", 'Item."Country/Region of Origin Code" should be updated from Shopify.');
    end;

    [Test]
    procedure UnitTestUpdateItemKeepsExistingTariffWhenShopifyValueNotInBC()
    var
        Item: Record Item;
        TariffNumber: Record "Tariff Number";
        Shop: Record "Shpfy Shop";
        ShopifyVariant: Record "Shpfy Variant";
        ProductInitTest: Codeunit "Shpfy Product Init Test";
        InitializeTest: Codeunit "Shpfy Initialize Test";
        ExistingTariffNo: Code[20];
        UnknownTariffNo: Code[20];
    begin
        // [SCENARIO 642046] Updating an item from Shopify does not clear an existing Tariff No. when the Shopify value does not exist in Business Central.

        // [GIVEN] A shop with "Sync HS Code and Country" enabled and "SKU Mapping" = "Item No.".
        Shop := InitializeTest.CreateShop();
        Shop."SKU Mapping" := "Shpfy SKU Mapping"::"Item No.";
        Shop."Sync HS Code and Country" := true;
        Shop.Modify();

        // [GIVEN] A tariff number that exists in BC and one that does not.
        ExistingTariffNo := CreateTariffNumber();
        UnknownTariffNo := CopyStr(LibraryRandom.RandText(MaxStrLen(UnknownTariffNo)), 1, MaxStrLen(UnknownTariffNo));
        if TariffNumber.Get(UnknownTariffNo) then
            TariffNumber.Delete();

        // [GIVEN] A Shopify variant imported as a BC item that already has the existing Tariff No.
        ShopifyVariant := ProductInitTest.CreateStandardProduct(Shop);
        ShopifyVariant."Tariff No." := ExistingTariffNo;
        ShopifyVariant.Modify();
        ShopifyVariant.SetRecFilter();
        Codeunit.Run(Codeunit::"Shpfy Create Item", ShopifyVariant);
        ShopifyVariant.Get(ShopifyVariant.Id);
        Item.GetBySystemId(ShopifyVariant."Item SystemId");
        LibraryAssert.AreEqual(ExistingTariffNo, Item."Tariff No.", 'Precondition: item has the existing Tariff No.');

        // [GIVEN] Shopify now reports a Tariff No. that does not exist in BC.
        ShopifyVariant."Tariff No." := UnknownTariffNo;
        ShopifyVariant.Modify();
        ShopifyVariant.SetRecFilter();

        // [WHEN] Executing the codeunit "Shpfy Update Item" with the "Shpfy Variant" record.
        Codeunit.Run(Codeunit::"Shpfy Update Item", ShopifyVariant);

        // [THEN] The existing Tariff No. on the item is preserved (not wiped by the unmapped value).
        Item.GetBySystemId(ShopifyVariant."Item SystemId");
        LibraryAssert.AreEqual(ExistingTariffNo, Item."Tariff No.", 'Existing Tariff No. must be preserved when the Shopify value is not in BC.');
    end;

    local procedure CreateCountryRegionWithISOCode() CountryRegion: Record "Country/Region"
    var
        ExistingCountryRegion: Record "Country/Region";
        ISOCode: Code[2];
    begin
        // Generate an ISO code that is neither an existing ISO Code nor an existing Country/Region code,
        // so that "Shpfy Process Order".GetCountryCode resolves it through the ISO Code reverse lookup.
        repeat
            ISOCode := CopyStr(LibraryRandom.RandText(MaxStrLen(ISOCode)), 1, MaxStrLen(ISOCode));
            ExistingCountryRegion.SetRange("ISO Code", ISOCode);
        until (ISOCode <> '') and ExistingCountryRegion.IsEmpty() and (not ExistingCountryRegion.Get(ISOCode));

        CountryRegion.Init();
        CountryRegion.Code := CopyStr(LibraryRandom.RandText(MaxStrLen(CountryRegion.Code)), 1, MaxStrLen(CountryRegion.Code));
        CountryRegion."ISO Code" := ISOCode;
        CountryRegion.Insert();
    end;

    local procedure CreateTariffNumber() TariffNo: Code[20]
    var
        TariffNumber: Record "Tariff Number";
    begin
        TariffNo := CopyStr(LibraryRandom.RandText(MaxStrLen(TariffNo)), 1, MaxStrLen(TariffNo));
        if not TariffNumber.Get(TariffNo) then begin
            TariffNumber.Init();
            TariffNumber."No." := TariffNo;
            TariffNumber.Insert();
        end;
    end;

    local procedure CreateDottedTariffNumber() DottedTariffNo: Code[20]
    var
        TariffNumber: Record "Tariff Number";
        Digits: Text;
    begin
        // Build a "NNNN.NN" tariff whose separated and separator-less forms are both free, so digit matching is unambiguous.
        repeat
            Digits := Format(LibraryRandom.RandIntInRange(100000, 999999));
            DottedTariffNo := CopyStr(CopyStr(Digits, 1, 4) + '.' + CopyStr(Digits, 5, 2), 1, MaxStrLen(DottedTariffNo));
        until (not TariffNumber.Get(DottedTariffNo)) and (not TariffNumber.Get(CopyStr(Digits, 1, MaxStrLen(TariffNumber."No."))));

        TariffNumber.Init();
        TariffNumber."No." := DottedTariffNo;
        TariffNumber.Insert();
    end;

    local procedure CreateCurrencyAndExchangeRate(ExchangeRateAmount: Decimal; AdjustmentExchangeRateAmount: Decimal): Code[10]
    begin
        exit(LibraryERM.CreateCurrencyWithExchangeRate(WorkDate() - 1, ExchangeRateAmount, AdjustmentExchangeRateAmount));
    end;
}
