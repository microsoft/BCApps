// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

enum 9211 "Item Analysis Show Type"
{
    AssignmentCompatibility = true;
    Extensible = false;

    value(0; "Actual Amounts") { Caption = 'Actual Amounts'; }
    value(1; "Budgeted Amounts") { Caption = 'Budgeted Amounts'; }
    value(2; "Variance") { Caption = 'Variance'; }
    value(3; "Variance%") { Caption = 'Variance %'; }
    value(4; "Index%") { Caption = 'Index %'; }
}
