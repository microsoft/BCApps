// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

/// <summary>
/// Codeunit Shpfy GQL CompLocation (ID 30406).
/// Implements the IGraphQL interface for retrieving Shopify company location using GraphQL.
/// </summary>
codeunit 30406 "Shpfy GQL CompLocation" implements "Shpfy IGraphQL"
{
    Access = Internal;

    /// <summary>
    /// GetGraphQL.
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    internal procedure GetGraphQL(): Text
    begin
        exit('{"query": "{ companyLocation(id: \"gid://shopify/CompanyLocation/{{LocationId}}\") { id name billingAddress { address1 address2 city countryCode phone province recipient zip zoneCode } buyerExperienceConfiguration { paymentTermsTemplate { id } } taxRegistrationId } }"}');
    end;

    /// <summary>
    /// GetExpectedCost.
    /// </summary>
    /// <returns>Return value of type Integer.</returns>
    internal procedure GetExpectedCost(): Integer
    begin
        exit(4);
    end;
}