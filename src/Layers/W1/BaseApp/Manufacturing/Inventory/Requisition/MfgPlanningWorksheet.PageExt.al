// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Requisition;

using Microsoft.Manufacturing.Routing;

pageextension 99000852 "Mfg. Planning Worksheet" extends "Planning Worksheet"
{
    layout
    {
        addafter("Description 2")
        {
            field("Production BOM No."; Rec."Production BOM No.")
            {
                ApplicationArea = Assembly;
                ToolTip = 'Specifies the production BOM number for this production order.';
                Visible = false;
            }
            field("Production BOM Version Code"; Rec."Production BOM Version Code")
            {
                ApplicationArea = Assembly;
                ToolTip = 'Specifies the version code of the BOM.';
                Visible = false;
            }
            field("Routing No."; Rec."Routing No.")
            {
                ApplicationArea = Planning;
                ToolTip = 'Specifies the routing number.';
                Visible = false;

                trigger OnValidate()
                begin
                    PlanningWkshManagement.GetDescriptionAndRcptName(Rec, ItemDescription, RoutingDescription);
                end;
            }
            field("Routing Version Code"; Rec."Routing Version Code")
            {
                ApplicationArea = Planning;
                ToolTip = 'Specifies the version code of the routing.';
                Visible = false;
            }
        }
    }
    actions
    {
        addafter(Components)
        {
            action("Ro&uting")
            {
                ApplicationArea = Manufacturing;
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
