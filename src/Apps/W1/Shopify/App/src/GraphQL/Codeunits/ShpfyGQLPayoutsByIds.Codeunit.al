// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

codeunit 30420 "Shpfy GQL PayoutsByIds" implements "Shpfy IGraphQL"
{
    Access = Internal;

    procedure GetGraphQL(): Text
    begin
        exit('{"query":"{ shopifyPaymentsAccount { payouts(first: 200, query: \"id:{{IdFilter}}\") { nodes { id status } } } }"}');
    end;

    procedure GetExpectedCost(): Integer
    begin
        exit(13);
    end;
}
