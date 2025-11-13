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
    /// Retrieves the product URL for the specified Shopify Variant.
    /// </summary>
    /// <param name="ShopifyVariant">The Shopify variant record.</param>
    /// <returns>The product URL for the specified Shopify variant.</returns>
    procedure GetProductUrl(var ShopifyVariant: Record "Shpfy Variant"): Text
    begin
        exit(SyncProducts.GetProductUrl(ShopifyVariant));
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
