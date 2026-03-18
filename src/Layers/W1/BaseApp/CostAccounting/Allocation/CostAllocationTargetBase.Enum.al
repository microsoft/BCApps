// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CostAccounting.Allocation;

enum 1117 "Cost Allocation Target Base"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Static") { Caption = 'Static'; }
    value(1; "G/L Entries") { Caption = 'G/L Entries'; }
    value(2; "G/L Budget Entries") { Caption = 'G/L Budget Entries'; }
    value(3; "Cost Type Entries") { Caption = 'Cost Type Entries'; }
    value(4; "Cost Budget Entries") { Caption = 'Cost Budget Entries'; }
    value(9; "No of Employees") { Caption = 'No of Employees'; }
    value(11; "Items Sold (Qty.)") { Caption = 'Items Sold (Qty.)'; }
    value(12; "Items Purchased (Qty.)") { Caption = 'Items Purchased (Qty.)'; }
    value(13; "Items Sold (Amount)") { Caption = 'Items Sold (Amount)'; }
    value(14; "Items Purchased (Amount)") { Caption = 'Items Purchased (Amount)'; }
}
