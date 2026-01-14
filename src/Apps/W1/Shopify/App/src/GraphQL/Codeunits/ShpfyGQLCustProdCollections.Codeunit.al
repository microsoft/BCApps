// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

codeunit 30415 "Shpfy GQL CustProdCollections" implements "Shpfy IGraphQL"
{
    Access = Internal;

    internal procedure GetGraphQL(): Text
    begin
        exit('{"query": "{collections(first:25, query:\"collection_type:custom\") { pageInfo{hasNextPage} edges{ cursor node{ id title } } } }"}');
    end;

    internal procedure GetExpectedCost(): Integer
    begin
        exit(8);
    end;
}