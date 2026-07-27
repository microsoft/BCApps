// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;
using Microsoft.Inventory.Item;

/// <summary>
/// Provides functionality for managing Shopify products.
/// </summary>
codeunit 30234 "Shpfy Product"
{
    Access = Public;

    var
        SyncProducts: Codeunit "Shpfy Sync Products";
        ProductExport: Codeunit "Shpfy Product Export";

    /// <summary>
    /// Adds the specified item to the specified Shopify shop.
    /// </summary>
    /// <param name="Item">The item record to be added.</param>
    /// <param name="ShopifyShop">The Shopify shop record where the item will be added.</param>
    procedure AddItemToShopify(Item: Record Item; ShopifyShop: Record "Shpfy Shop")
    begin
        SyncProducts.AddItemToShopify(Item, ShopifyShop);
    end;

    /// <summary>
    /// Confirms whether the specified item should be added to a Shopify shop, prompting for shop selection when more than one mapped shop is available.
    /// </summary>
    /// <param name="Item">The item record to be added.</param>
    /// <param name="ShopifyShop">Returns the Shopify shop the item will be added to.</param>
    /// <returns>True if adding the item was confirmed; otherwise, false.</returns>
    procedure ConfirmAddItemToShopify(Item: Record Item; var ShopifyShop: Record "Shpfy Shop"): Boolean
    begin
        exit(SyncProducts.ConfirmAddItemToShopify(Item, ShopifyShop));
    end;

    /// <summary>
    /// Checks whether the item's attributes are compatible with Shopify product options for the specified shop.
    /// </summary>
    /// <param name="Item">The item record to be checked.</param>
    /// <param name="ShopifyShop">The Shopify shop record the item will be added to.</param>
    /// <returns>True if the item's attributes are compatible with product options; otherwise, false.</returns>
    procedure CheckItemAttributesCompatibleForProductOptions(Item: Record Item; ShopifyShop: Record "Shpfy Shop"): Boolean
    begin
        ProductExport.SetShop(ShopifyShop);
        exit(ProductExport.CheckItemAttributesCompatibleForProductOptions(Item));
    end;

    /// <summary>
    /// Retrieves the product URL for the specified Shopify Variant.
    /// </summary>
    /// <param name="ShopifyVariant">The Shopify variant record.</param>
    /// <returns>The product URL for the specified Shopify variant.</returns>
    procedure GetProductUrl(var ShopifyVariant: Record "Shpfy Variant"): Text
    begin
        exit(SyncProducts.GetProductUrl(ShopifyVariant));
    end;

    /// <summary>
    /// Retrieves the product URL for the specified item in the specified Shopify shop.
    /// </summary>
    /// <param name="Item">The item record.</param>
    /// <param name="ShopCode">The Shopify shop code.</param>
    /// <returns>The product URL for the specified item.</returns>
    procedure GetProductUrl(Item: Record Item; ShopCode: Code[20]): Text
    begin
        exit(SyncProducts.GetProductUrl(Item, ShopCode));
    end;

    /// <summary>
    /// Retrieves and display the overview of products for the specified Shopify Variant.
    /// </summary>
    /// <param name="ShopifyVariant">The Shopify variant record.</param>
    procedure GetProductsOverview(var ShopifyVariant: Record "Shpfy Variant")
    begin
        SyncProducts.GetProductsOverview(ShopifyVariant);
    end;
}
