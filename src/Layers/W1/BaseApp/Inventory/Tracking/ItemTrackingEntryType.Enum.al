// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

enum 6566 "Item Tracking Entry Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "None") { Caption = 'None'; }
    value(1; "Lot No.") { Caption = 'Lot No.'; }
    value(2; "Lot and Serial No.") { Caption = 'Lot and Serial No.'; }
    value(3; "Serial No.") { Caption = 'Serial No.'; }
    value(4; "Package No.") { Caption = 'Package No.'; }
    value(5; "Lot and Package No.") { Caption = 'Lot and Package No.'; }
    value(6; "Serial and Package No.") { Caption = 'Serial and Package No.'; }
    value(7; "Lot and Serial and Package No.") { Caption = 'Lot and Serial and Package No.'; }
}
