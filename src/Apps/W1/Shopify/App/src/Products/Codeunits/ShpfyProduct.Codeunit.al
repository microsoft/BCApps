// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

/// <summary>
/// Provides functionality for retrieving Shopify product information.
/// </summary>
codeunit 30234 "Shpfy Product"
{
    Access = Public;

    var
        SyncProducts: Codeunit "Shpfy Sync Products";

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
