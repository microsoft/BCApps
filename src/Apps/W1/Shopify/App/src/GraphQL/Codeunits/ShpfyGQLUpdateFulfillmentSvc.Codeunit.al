// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

/// <summary>
/// Codeunit Shpfy GQL UpdateFulfillmentSvc (ID 30410).
/// Implements the IGraphQL interface for updating Shopify fulfillment service using GraphQL.
/// </summary>
codeunit 30410 "Shpfy GQL UpdateFulfillmentSvc" implements "Shpfy IGraphQL"
{
    Access = Internal;

    /// <summary>
    /// GetGraphQL.
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    internal procedure GetGraphQL(): Text
    begin
        exit('{"query": "mutation { fulfillmentServiceUpdate( id: \"gid://shopify/FulfillmentService/{{Id}}\" callbackUrl: \"{{CallbackUrl}}\" ) { userErrors { field message } fulfillmentService { callbackUrl } } }"}');
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