// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

codeunit 30277 "Shpfy GQL NextMarketShipMeth" implements "Shpfy IGraphQL"
{
    Access = Internal;

    procedure GetGraphQL(): Text
    begin
        exit('{"query":"{ markets(first: 25, after: \"{{After}}\") { pageInfo { hasNextPage } edges { cursor node { delivery { shipping { isEnabled optionDefinitions(first: 50, active: true) { edges { node { isActive ... on DeliveryFlatRateOptionDefinition { name } ... on DeliveryValueBasedOptionDefinition { name } ... on DeliveryWeightBasedOptionDefinition { name } } } } } } } } } }"}');
    end;

    procedure GetExpectedCost(): Integer
    begin
        exit(74);
    end;
}
