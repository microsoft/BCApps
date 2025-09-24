// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Shopify;

/// <summary>
/// Codeunit Shpfy GQL AddImageToProduct (ID 30406) implements Interface Shpfy IGraphQL.
/// </summary>
codeunit 30406 "Shpfy GQL AddImageToProduct" implements "Shpfy IGraphQL"
{
    Access = Internal;

    /// <summary>
    /// GetGraphQL.
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    procedure GetGraphQL(): Text
    begin
        exit('{"query": "mutation { productUpdate( product:{id: \"gid://shopify/Product/{{ProductId}}\"}, media: [ { originalSource: \"{{ResourceUrl}}\" mediaContentType: IMAGE } ]) { product { media(first: 1, reverse: true) { nodes{ id mediaErrors { code details message } } } } userErrors { field message } } }"}');
    end;

    /// <summary>
    /// GetExpectedCost.
    /// </summary>
    /// <returns>Return value of type Integer.</returns>
    procedure GetExpectedCost(): Integer
    begin
        exit(10);
    end;
}
