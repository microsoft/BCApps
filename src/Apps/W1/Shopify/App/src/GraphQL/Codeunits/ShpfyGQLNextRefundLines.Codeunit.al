#if not CLEAN29
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

codeunit 30232 "Shpfy GQL NextRefundLines"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced by .graphql resource files. Use "Shpfy GraphQL Queries".GetQueryWithCost() instead.';
    ObsoleteTag = '29.0';

    procedure GetGraphQL(): Text
    var
        GraphQLQueries: Codeunit "Shpfy GraphQL Queries";
        ExpectedCost: Integer;
    begin
        exit(GraphQLQueries.GetQueryWithCost(Enum::"Shpfy GraphQL Type"::Refunds_GetNextRefundLines, ExpectedCost));
    end;

    procedure GetExpectedCost(): Integer
    var
        GraphQLQueries: Codeunit "Shpfy GraphQL Queries";
        ExpectedCost: Integer;
    begin
        GraphQLQueries.GetQueryWithCost(Enum::"Shpfy GraphQL Type"::Refunds_GetNextRefundLines, ExpectedCost);
        exit(ExpectedCost);
    end;
}
#endif
