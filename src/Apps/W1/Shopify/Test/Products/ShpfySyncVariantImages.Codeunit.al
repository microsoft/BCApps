// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Inventory.Item;
using System.TestLibraries.Utilities;
using Microsoft.Integration.Shopify;

codeunit 139540 "Shpfy Sync Variant Images"
{
    Subtype = Test;

    var
        Shop: Record "Shpfy Shop";
        Any: Codeunit Any;
        InitializeTest: Codeunit "Shpfy Initialize Test";
        Initialized: Boolean;

    trigger OnRun()
    begin
        Initialized := false;
    end;

    local procedure Initialize()
    begin
        Any.SetDefaultSeed();
        if Initialized then
            exit;
        Shop := InitializeTest.CreateShop();
        Initialized := true;
        Commit();
    end;

    [Test]
    procedure UnitTestImportVariantImageFromShopify()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ShopifyVariant: Record "Shpfy Variant";
        ShopifyProduct: Record "Shpfy Product";
        LibraryInventory: Codeunit "Library - Inventory";
        VariantAPI: Codeunit "Shpfy Variant API";
        SyncProductImage: Codeunit "Shpfy Sync Product Image";
    begin
        // [SCENARIO] Importing variant image from Shopify variant
        Initialize();

        // [GIVEN] Shop with setting to import images from shopify
        Shop."Sync Item Images" := Shop."Sync Item Images"::"From Shopify";
        Shop.Modify(false);

        // [GIVEN] Item with variant
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        // [GIVEN] Shopify product
        ShopifyProduct.Init();
        ShopifyProduct.Id := Any.IntegerInRange(1000000, 9999999);
        ShopifyProduct."Item No." := Item."No.";
        ShopifyProduct."Item SystemId" := Item.SystemId;
        ShopifyProduct."Shop Code" := Shop."Code";
        ShopifyProduct.Insert(false);

        // [GIVEN] Shopify variant
        ShopifyVariant.Init();
        ShopifyVariant.Id := Any.IntegerInRange(1000000, 9999999);
        ShopifyVariant."Product Id" := ShopifyProduct.Id;
        ShopifyVariant."Item No." := Item."No.";
        ShopifyVariant."Item SystemId" := Item.SystemId;
        ShopifyVariant."Item Variant SystemId" := ItemVariant.SystemId;
        ShopifyVariant."Shop Code" := Shop."Code";
        ShopifyVariant.Insert(false);

        // [WHEN] Execute sync product image
        SyncProductImage.Run(Shop);
    end;
}
