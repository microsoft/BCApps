// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

enum 5440 "Reordering Policy"
{
    Extensible = true;
    AssignmentCompatibility = true;
    value(0; " ") { Caption = ' '; }
    value(1; "Fixed Reorder Qty.") { Caption = 'Fixed Reorder Qty.'; }
    value(2; "Maximum Qty.") { Caption = 'Maximum Qty.'; }
    value(3; "Order") { Caption = 'Order'; }
    value(4; "Lot-for-Lot") { Caption = 'Lot-for-Lot'; }
}
