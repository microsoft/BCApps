// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Transfer;

enum 5747 "Transfer Routes Show"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "In-Transit Code") { Caption = 'In-Transit Code'; }
    value(1; "Shipping Agent Code") { Caption = 'Shipping Agent Code'; }
    value(2; "Shipping Agent Service Code") { Caption = 'Shipping Agent Service Code'; }
}
