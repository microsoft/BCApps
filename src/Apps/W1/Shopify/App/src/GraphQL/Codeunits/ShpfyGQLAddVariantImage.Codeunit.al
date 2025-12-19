// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;


/// <summary>
/// Codeunit Shpfy GQL AddVariantImage (ID 30409) implements Interface Shpfy IGraphQL.
/// </summary>
codeunit 30452 "Shpfy GQL AddVariantImage" implements "Shpfy IGraphQL"
{
    Access = Internal;

    /// <summary>
    /// GetGraphQL.
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    internal procedure GetGraphQL(): Text
    begin
        exit('{"query": "mutation { productVariantsBulkUpdate(productId: \"gid://shopify/Product/{{ProductId}}\" variants: {id: \"gid://shopify/ProductVariant/{{VariantId}}\" mediaSrc: \"{{ResourceUrl}}\"} media: {mediaContentType: IMAGE originalSource: \"{{ResourceUrl}}\"}) { userErrors { code field message } productVariants { media(first: 1){ edges { node { id }}}}}} "}');
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
