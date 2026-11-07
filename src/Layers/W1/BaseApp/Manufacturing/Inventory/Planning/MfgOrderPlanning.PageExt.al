// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Requisition;

using Microsoft.Manufacturing.Routing;

pageextension 99000832 "Mfg. Order Planning" extends "Order Planning"
{
    actions
    {
        addafter(Components)
        {
            action("Ro&uting")
            {
                ApplicationArea = Planning;
                Caption = 'Ro&uting';
                Image = Route;
                RunObject = Page "Planning Routing";
                RunPageLink = "Worksheet Template Name" = field("Worksheet Template Name"),
                                "Worksheet Batch Name" = field("Journal Batch Name"),
                                "Worksheet Line No." = field("Line No.");
                ToolTip = 'View or edit the operations list of the parent item on the line.';
                ShortCutKey = 'Ctrl+Alt+R';
            }
        }
        addafter(Components_Promoted)
        {
            actionref("Ro&uting_Promoted"; "Ro&uting")
            {
            }
        }
    }
}