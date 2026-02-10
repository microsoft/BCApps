// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

codeunit 30102 "Shpfy GQL Modify Inventory" implements "Shpfy IGraphQL"
{
    procedure GetGraphQL(): Text
    begin
        exit('{"query":"mutation inventorySetQuantities($input: InventorySetQuantitiesInput!) { inventorySetQuantities(input: $input) @idempotent(key: \"{{IdempotencyKey}}\") { inventoryAdjustmentGroup { id } userErrors { field message code }}}","variables":{"input":{"name":"on_hand","reason":"correction","quantities":[]}}}');
    end;

    procedure GetExpectedCost(): Integer
    begin
        exit(10);
    end;
}