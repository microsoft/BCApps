// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Requisition;

pageextension 99000860 "Mfg. Planning Wksh. Line List" extends "Planning Worksheet Line List"
{
    layout
    {
        addafter(Quantity)
        {
            field("Scrap %"; Rec."Scrap %")
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies the percentage of the item that you expect to be scrapped in the production process.';
                Visible = false;
            }
        }
        addafter("Ending Date")
        {
            field("Production BOM No."; Rec."Production BOM No.")
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies the production BOM number for this production order.';
                Visible = false;
            }
            field("Routing No."; Rec."Routing No.")
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies the routing number.';
                Visible = false;
            }
        }
    }
}