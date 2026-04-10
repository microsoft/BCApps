// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

enum 6565 "Item Tracking Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Serial No.") { Caption = 'Serial No.'; }
    value(1; "Lot No.") { Caption = 'Lot No.'; }
    value(2; "Package No.") { Caption = 'Package No.'; }
}
