// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

/// <summary>
/// Codeunit Shpfy GQL AcceptFFRequest (ID 30412).
/// Implements the IGraphQL interface for accepting Shopify fulfillment requests using GraphQL.
/// </summary>
codeunit 30414 "Shpfy GQL AcceptFFRequest" implements "Shpfy IGraphQL"
{
    Access = Internal;

    /// <summary>
    /// GetGraphQL.
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    internal procedure GetGraphQL(): Text
    begin
        exit('{"query":"mutation { fulfillmentOrderAcceptFulfillmentRequest(id: \"gid://shopify/FulfillmentOrder/{{FulfillmentOrderId}}\") { fulfillmentOrder { id requestStatus } userErrors { field message }}}"}');
    end;

    /// <summary>
    /// GetExpectedCost.
    /// </summary>
    /// <returns>Return value of type Integer.</returns>
    internal procedure GetExpectedCost(): Integer
    begin
        exit(10);
    end;
}
