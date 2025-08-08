// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

/// <summary>
/// Codeunit Shpfy GQL Market Catalogs (ID 30404).
/// Implements the IGraphQL interface for retrieving Shopify market catalogs using GraphQL.
/// </summary>
codeunit 30404 "Shpfy GQL Market Catalogs" implements "Shpfy IGraphQL"
{
    Access = Internal;

    /// <summary>
    /// GetGraphQL.
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    internal procedure GetGraphQL(): Text
    begin
        exit('{"query": "{ catalogs (first:25, type: MARKET, query: \"status:ACTIVE\"){ pageInfo{ hasNextPage } edges { cursor node { id title priceList { currency }}}}}"}');
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