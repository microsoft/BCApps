// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

/// <summary>
/// Codeunit Shpfy GQL Detatch Variant Img. (ID 30410) implements Interface Shpfy IGraphQL.
/// </summary>
codeunit 30410 "Shpfy GQL Detach Variant Img." implements "Shpfy IGraphQL"
{

    /// <summary>
    /// GetGraphQL.
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    procedure GetGraphQL(): Text
    begin
        exit('{"query": "mutation { productVariantDetachMedia( productId: \"gid://shopify/Product/{{ProductId}}\", variantMedia: [ { mediaIds: [\"gid://shopify/MediaImage/{{ImageId}}\"], variantId: \"gid://shopify/ProductVariant/{{VariantId}}\" } ] ) { product { id } userErrors { code field message } } }"}');
    end;

    procedure GetExpectedCost(): Integer
    begin
        exit(10);
    end;
}
