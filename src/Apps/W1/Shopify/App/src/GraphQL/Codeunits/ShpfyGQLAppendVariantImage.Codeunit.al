// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

/// <summary>
/// Codeunit Shpfy GQL Append Variant Image (ID 30407) implements Interface Shpfy IGraphQL.
/// </summary>
codeunit 30407 "Shpfy GQL Append Variant Image" implements "Shpfy IGraphQL"
{
    procedure GetGraphQL(): Text
    begin
        exit('{"query": "mutation { productVariantAppendMedia( productId: \"gid://shopify/Product/{{ProductId}}\", variantMedia: [ { mediaIds: [\"gid://shopify/MediaImage/{{ImageId}}\"], variantId: \"gid://shopify/ProductVariant/{{VariantId}}\" } ] ) { userErrors { code field message } } }"}');
    end;

    procedure GetExpectedCost(): Integer
    begin
        exit(10);
    end;
}
