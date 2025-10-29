// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

/// <summary>
/// Codeunit Shpfy GQL NextCatalogMarkets (ID 30403).
/// Implements the IGraphQL interface for retrieving Shopify catalog markets using GraphQL.
/// </summary>
codeunit 30403 "Shpfy GQL NextCatalogMarkets" implements "Shpfy IGraphQL"
{
    Access = Internal;

    /// <summary>
    /// GetGraphQL.
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    internal procedure GetGraphQL(): Text
    begin
        exit('{"query": "{ catalog (id: \"gid://shopify/Catalog/{{CatalogId}}\") { id title ... on MarketCatalog { markets(first: 5, after:\"{{After}}\") { pageInfo { hasNextPage } edges { cursor node { id name }}}}}}"}');
    end;

    /// <summary>
    /// GetExpectedCost.
    /// </summary>
    /// <returns>Return value of type Integer.</returns>
    internal procedure GetExpectedCost(): Integer
    begin
        exit(27);
    end;
}
