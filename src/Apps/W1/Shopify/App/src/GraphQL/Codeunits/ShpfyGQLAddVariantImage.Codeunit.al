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

    internal procedure GetGraphQL(): Text
    begin
        exit('{"query": "mutation { productVariantsBulkUpdate(productId: \"gid://shopify/Product/{{ProductId}}\" variants: {id: \"gid://shopify/ProductVariant/{{VariantId}}\" mediaSrc: \"{{ResourceUrl}}\"} media: {mediaContentType: IMAGE originalSource: \"{{ResourceUrl}}\"}) { userErrors { code field message } productVariants { media(first: 1){ edges { node { id }}}}}} "}');
    end;

    internal procedure GetExpectedCost(): Integer
    begin
        exit(10);
    end;
}
