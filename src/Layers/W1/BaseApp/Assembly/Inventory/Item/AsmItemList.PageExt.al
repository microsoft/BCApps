// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

using Microsoft.Assembly.Reports;

pageextension 905 "Asm. Item List" extends "Item List"
{
    actions
    {
        addbefore("Inventory - Sales Back Orders")
        {
            action("Assemble to Order - Sales")
            {
                ApplicationArea = Assembly;
                Caption = 'Assemble to Order - Sales';
                Image = "Report";
                RunObject = Report "Assemble to Order - Sales";
                ToolTip = 'View key sales figures for assembly components that may be sold either as part of assembly items in assemble-to-order sales or as separate items directly from inventory. Use this report to analyze the quantity, cost, sales, and profit figures of assembly components to support decisions, such as whether to price a kit differently or to stop or start using a particular item in assemblies.';
            }
        }
    }
}