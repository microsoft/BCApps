// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

enum 5420 "Item Replenishment System"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Purchase") { Caption = 'Purchase'; }
    value(1; "Prod. Order") { Caption = 'Prod. Order'; }
}
