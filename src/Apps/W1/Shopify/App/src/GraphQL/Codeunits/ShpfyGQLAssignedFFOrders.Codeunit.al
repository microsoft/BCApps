// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

/// <summary>
/// Codeunit Shpfy GQL AssignedFFOrders (ID 30410).
/// Implements the IGraphQL interface for retrieving assigned fulfillment orders using GraphQL.
/// </summary>
codeunit 30412 "Shpfy GQL AssignedFFOrders" implements "Shpfy IGraphQL"
{
    Access = Internal;

    /// <summary>
    /// GetGraphQL.
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    internal procedure GetGraphQL(): Text
    begin
        exit('{"query":"{ assignedFulfillmentOrders(assignmentStatus: FULFILLMENT_REQUESTED, first: 25) { pageInfo { hasNextPage } edges { cursor node { id status requestStatus }}}}"}');
    end;

    /// <summary>
    /// GetExpectedCost.
    /// </summary>
    /// <returns>Return value of type Integer.</returns>
    internal procedure GetExpectedCost(): Integer
    begin
        exit(8);
    end;
}
