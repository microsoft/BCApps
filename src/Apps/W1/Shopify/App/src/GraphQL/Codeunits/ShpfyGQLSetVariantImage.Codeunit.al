// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;


/// <summary>
/// Codeunit Shpfy GQL SetVariantImage (ID 30414) implements Interface Shpfy IGraphQL.
/// </summary>
codeunit 30454 "Shpfy GQL SetVariantImage" implements "Shpfy IGraphQL"
{
    Access = Internal;

    /// <summary>
    /// GetGraphQL.
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    internal procedure GetGraphQL(): Text
    begin
        exit('{"query": "mutation { productVariantsBulkUpdate(productId: \"gid://shopify/Product/{{ProductId}}\" variants: {id: \"gid://shopify/ProductVariant/{{VariantId}}\" mediaId: \"gid://shopify/MediaImage/{{ImageId}}\"}) { userErrors { code field message } productVariants { media(first: 1){ edges { node { id }}}}}} "}');
    end;

    /// <summary>
    /// GetExpectedCost.
    /// </summary>
    /// <returns>Return value of type Integer.</returns>
    internal procedure GetExpectedCost(): Integer
    begin
        exit(10);
    end;
}
