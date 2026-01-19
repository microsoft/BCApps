// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

/// <summary>
/// Codeunit Shpfy GQL GetVariantImage (ID 30411) implements Interface Shpfy IGraphQL.
/// </summary>
codeunit 30453 "Shpfy GQL GetVariantImage" implements "Shpfy IGraphQL"
{
    Access = Internal;

    internal procedure GetGraphQL(): Text
    begin
        exit('{"query":"{ productVariant(id: \"gid://shopify/ProductVariant/{{VariantId}}\") { media(first:1) { edges {node { id }}}}}"}');
    end;

    internal procedure GetExpectedCost(): Integer
    begin
        exit(4);
    end;
}
