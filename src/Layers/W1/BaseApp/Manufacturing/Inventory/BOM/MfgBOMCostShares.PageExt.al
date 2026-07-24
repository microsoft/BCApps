// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.BOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Reports;

pageextension 99000757 "Mfg. BOM Cost Shares" extends "BOM Cost Shares"
{
    layout
    {
        addafter("Lot Size")
        {
            field("Production BOM No."; Rec."Production BOM No.")
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies the number of the production BOM that the item represents.';
                Visible = false;
            }
            field("Routing No."; Rec."Routing No.")
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies the number of the item''s production order routing.';
                Visible = false;
            }
        }
    }
    actions
    {
        addlast(reporting)
        {
            action("Production Cost Shares")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Production Cost Shares';
                Image = "Report";
                ToolTip = 'This report contains data on how the costs of underlying items in the BOM roll up to the parent item. The information is organized according to the BOM structure to reflect at which levels the individual costs apply. Varying item levels are shown across several worksheets to obtain an overview or detailed view.';

                trigger OnAction()
                var
                    Item2: Record Item;
                begin
                    Item2.SetFilter("No.", ItemFilter);
                    Report.Run(Report::"Production Cost Shares", true, true, Item2);
                end;
            }
        }
        addlast(Category_Process)
        {
            actionref("Production Cost Shares_Promoted"; "Production Cost Shares")
            {
            }
        }
    }
}