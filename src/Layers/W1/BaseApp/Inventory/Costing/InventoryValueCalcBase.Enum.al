// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

enum 5899 "Inventory Value Calc. Base"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Last Direct Unit Cost") { Caption = 'Last Direct Unit Cost'; }
    value(2; "Standard Cost - Assembly List") { Caption = 'Standard Cost - Assembly List'; }
    value(3; "Standard Cost - Manufacturing") { Caption = 'Standard Cost - Manufacturing'; }
}
