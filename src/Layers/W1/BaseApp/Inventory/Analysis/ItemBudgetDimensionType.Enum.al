// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

enum 9238 "Item Budget Dimension Type"
{
    AssignmentCompatibility = true;
    Extensible = false;

    value(0; "Item") { Caption = 'Item'; }
    value(1; "Customer") { Caption = 'Customer'; }
    value(2; "Vendor") { Caption = 'Vendor'; }
    value(3; "Period") { Caption = 'Period'; }
    value(4; "Location") { Caption = 'Location'; }
    value(5; "Global Dimension 1") { Caption = 'Global Dimension 1'; }
    value(6; "Global Dimension 2") { Caption = 'Global Dimension 2'; }
    value(7; "Budget Dimension 1") { Caption = 'Budget Dimension 1'; }
    value(8; "Budget Dimension 2") { Caption = 'Budget Dimension 2'; }
    value(9; "Budget Dimension 3") { Caption = 'Budget Dimension 3'; }
    value(10; "Budget Dimension 4") { Caption = 'Budget Dimension 4'; }
    value(99; "Undefined") { Caption = 'Undefined'; }
}
