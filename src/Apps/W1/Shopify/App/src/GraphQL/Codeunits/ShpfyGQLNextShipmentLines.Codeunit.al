#if not CLEAN29
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

codeunit 30222 "Shpfy GQL NextShipmentLines"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced by .graphql resource files. Use "Shpfy GraphQL Queries".GetQueryWithCost() instead.';
    ObsoleteTag = '29.0';

    procedure GetGraphQL(): Text
    var
        GraphQLQueries: Codeunit "Shpfy GraphQL Queries";
        ExpectedCost: Integer;
    begin
        exit(GraphQLQueries.GetQueryWithCost(Enum::"Shpfy GraphQL Type"::Shipping_GetNextShipmentLines, ExpectedCost));
    end;

    procedure GetExpectedCost(): Integer
    var
        GraphQLQueries: Codeunit "Shpfy GraphQL Queries";
        ExpectedCost: Integer;
    begin
        GraphQLQueries.GetQueryWithCost(Enum::"Shpfy GraphQL Type"::Shipping_GetNextShipmentLines, ExpectedCost);
        exit(ExpectedCost);
    end;
}
#endif
