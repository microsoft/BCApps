// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Integration.Shopify;
using Microsoft.Inventory.Item;
using System.TestLibraries.Utilities;

codeunit 139616 "Shpfy Product Export 7622 Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var
        Shop: Record "Shpfy Shop";
        Any: Codeunit Any;
        LibraryAssert: Codeunit "Library Assert";
        ShpfyInitializeTest: Codeunit "Shpfy Initialize Test";
        ProductInitTest: Codeunit "Shpfy Product Init Test";
        IsInitialized: Boolean;

    [Test]
    procedure UnitTestProductExportDoesNotCreateUnmappedVariantsFromChildItem()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        ChildItemVariantMapped: Record "Item Variant";
        ChildItemVariantUnmapped: Record "Item Variant";
        ShopifyProduct: Record "Shpfy Product";
        ShopifyVariant: Record "Shpfy Variant";
        ProductExport: Codeunit "Shpfy Product Export";
        ProductExportIssue7622Sub: Codeunit "Shpfy Product Export 7622 Sub";
    begin
        // [SCENARIO] Product Export must not create additional Shopify variants
        // [SCENARIO] for unmapped child-item variants when a child item was added as Shopify variant.
        Initialize();

        // [GIVEN] A parent item (without BC variants) and a child item with two BC variants.
        ParentItem := ProductInitTest.CreateItem(Shop."Item Templ. Code", Any.DecimalInRange(10, 100, 2), Any.DecimalInRange(100, 500, 2), false);
        ChildItem := ProductInitTest.CreateItem(Shop."Item Templ. Code", Any.DecimalInRange(10, 100, 2), Any.DecimalInRange(100, 500, 2), false);
        ChildItemVariantMapped := CreateItemVariant(ChildItem, 'MAP');
        ChildItemVariantUnmapped := CreateItemVariant(ChildItem, 'UNMAPPED');

        // [GIVEN] A Shopify product mapped to the parent item and one existing Shopify variant
        // [GIVEN] mapped to only one child item variant.
        ShopifyProduct := CreateShopifyProduct(ParentItem.SystemId);
        ShopifyVariant := CreateMappedShopifyVariant(ShopifyProduct.Id, ChildItem.SystemId, ChildItemVariantMapped.SystemId);

        // [WHEN] Product export runs for the shop.
        ProductExportIssue7622Sub.ResetCounters();
        BindSubscription(ProductExportIssue7622Sub);
        ProductExport.SetShop(Shop);
        Shop.SetRange(Code, Shop.Code);
        ProductExport.Run(Shop);
        UnbindSubscription(ProductExportIssue7622Sub);

        // [THEN] No new Shopify variant is created for the unmapped child item variant.
        LibraryAssert.AreEqual(0, ProductExportIssue7622Sub.GetProductVariantCreateCount(), 'Unexpected Shopify variant create call occurred for an unmapped child item variant.');

        ShopifyVariant.Reset();
        ShopifyVariant.SetRange("Product Id", ShopifyProduct.Id);
        ShopifyVariant.SetRange("Item SystemId", ChildItem.SystemId);
        ShopifyVariant.SetRange("Item Variant SystemId", ChildItemVariantUnmapped.SystemId);
        LibraryAssert.IsTrue(ShopifyVariant.IsEmpty(), 'Unexpected Shopify variant record created for unmapped child item variant.');
    end;

    local procedure Initialize()
    begin
        Any.SetDefaultSeed();
        if IsInitialized then
            exit;

        Shop := ShpfyInitializeTest.CreateShop();
        Shop."Can Update Shopify Products" := true;
        Shop."Product Metafields To Shopify" := false;
        Shop.Modify();
        Commit();

        IsInitialized := true;
    end;

    local procedure CreateItemVariant(Item: Record Item; VariantCodePrefix: Text): Record "Item Variant"
    var
        ItemVariant: Record "Item Variant";
    begin
        ItemVariant.Init();
        ItemVariant.Validate("Item No.", Item."No.");
        ItemVariant.Code := CopyStr(VariantCodePrefix + Any.AlphabeticText(5), 1, MaxStrLen(ItemVariant.Code));
        ItemVariant.Description := CopyStr(Any.AlphabeticText(20), 1, MaxStrLen(ItemVariant.Description));
        ItemVariant.Insert();
        exit(ItemVariant);
    end;

    local procedure CreateShopifyProduct(ItemSystemId: Guid): Record "Shpfy Product"
    var
        ShopifyProduct: Record "Shpfy Product";
    begin
        ShopifyProduct.Init();
        ShopifyProduct.Id := Any.IntegerInRange(10000, 99999);
        ShopifyProduct."Shop Code" := Shop.Code;
        ShopifyProduct."Item SystemId" := ItemSystemId;
        ShopifyProduct.Title := CopyStr(Any.AlphabeticText(20), 1, MaxStrLen(ShopifyProduct.Title));
        ShopifyProduct.Insert();
        exit(ShopifyProduct);
    end;

    local procedure CreateMappedShopifyVariant(ProductId: BigInteger; ItemSystemId: Guid; ItemVariantSystemId: Guid): Record "Shpfy Variant"
    var
        ShopifyVariant: Record "Shpfy Variant";
    begin
        ShopifyVariant.Init();
        ShopifyVariant.Id := Any.IntegerInRange(100000, 999999);
        ShopifyVariant."Shop Code" := Shop.Code;
        ShopifyVariant."Product Id" := ProductId;
        ShopifyVariant."Item SystemId" := ItemSystemId;
        ShopifyVariant."Item Variant SystemId" := ItemVariantSystemId;
        ShopifyVariant."Option 1 Name" := 'Variant';
        ShopifyVariant."Option 1 Value" := CopyStr(Any.AlphabeticText(10), 1, MaxStrLen(ShopifyVariant."Option 1 Value"));
        ShopifyVariant.Title := CopyStr(Any.AlphabeticText(20), 1, MaxStrLen(ShopifyVariant.Title));
        ShopifyVariant.Insert();
        exit(ShopifyVariant);
    end;
}
