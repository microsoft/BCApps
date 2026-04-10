// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing.ActionMessage;

enum 5842 "Cost Adjmt. Action Msg. Type"
{
    Extensible = false;
    Caption = 'Cost Adjmt. Action Msg. Type';
    Access = Internal;

    value(0; " ")
    {
        Caption = '';
    }
    value(10; "Cost Adjustment Not Running")
    {
        Caption = 'Cost Adjustment Not Running';
    }
    value(20; "Cost Adjustment Running Long")
    {
        Caption = 'Cost Adjustment Running Long';
    }
    value(30; "Suboptimal Avg. Cost Settings")
    {
        Caption = 'Suboptimal Avg. Cost Settings';
    }
    value(40; "Inventory Periods Unused")
    {
        Caption = 'Inventory Periods Unused';
    }
    value(50; "Many Non-Adjusted Entry Points")
    {
        Caption = 'Many Non-Adjusted Entry Points';
    }
    value(60; "Many Non-Adjusted Orders")
    {
        Caption = 'Many Non-Adjusted Orders';
    }
    value(70; "Item Excluded from Cost Adjustment")
    {
        Caption = 'Item Excluded from Cost Adjustment';
    }
    value(100; "Data Discrepancy")
    {
        Caption = 'Data Discrepancy';
    }
}