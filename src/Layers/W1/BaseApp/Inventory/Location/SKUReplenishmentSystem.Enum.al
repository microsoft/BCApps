// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Location;

enum 5421 "SKU Replenishment System"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Purchase") { Caption = 'Purchase'; }
    value(1; "Prod. Order") { Caption = 'Prod. Order'; }
    value(2; "Transfer") { Caption = 'Transfer'; }
    value(3; "Assembly") { Caption = 'Assembly'; }
}
