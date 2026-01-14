// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

codeunit 30419 "Shpfy GQL NextGetFulfillments" implements "Shpfy IGraphQL"
{
    Access = Internal;

    internal procedure GetGraphQL(): Text
    begin
        exit('{"query": "{order (id: \"gid://shopify/Order/{{OrderId}}\") { fulfillmentOrders (first: 250, after:\"{{After}}\") { pageInfo { endCursor hasNextPage } nodes { id }}}}"}');
    end;

    internal procedure GetExpectedCost(): Integer
    begin
        exit(14);
    end;
}
