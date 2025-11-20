// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

page 5816 "Inventory Adjmt. Entry Orders"
{
    PageType = List;
    ApplicationArea = Basic, Suite;
    SourceTable = "Inventory Adjmt. Entry (Order)";
    Caption = 'Inventory Adjmt. Entry Orders';
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("Order Type"; Rec."Order Type")
                {
                    Caption = 'Order Type';
                    ToolTip = 'Specifies which type of order that the entry was created in.';
                }
                field("Order No."; Rec."Order No.")
                {
                    Caption = 'Order No.';
                    ToolTip = 'Specifies the number of the order that the entry was created in.';
                }
                field("Order Line No."; Rec."Order Line No.")
                {
                    Caption = 'Order Line No.';
                    ToolTip = 'Specifies the line number of the order that the entry was created in.';
                }
                field("Item No."; Rec."Item No.")
                {
                    Caption = 'Item No.';
                    ToolTip = 'Specifies the item number.';
                }
                field("Is Finished"; Rec."Is Finished")
                {
                    Caption = 'Is Finished';
                    ToolTip = 'Specifies that the order is finished and that its cost will be adjusted.';
                }
                field("Completely Invoiced"; Rec."Completely Invoiced")
                {
                    Caption = 'Completely Invoiced';
                    ToolTip = 'Specifies whether the entry has been fully invoiced.';
                }
                field("Cost is Adjusted"; Rec."Cost is Adjusted")
                {
                    Caption = 'Cost is Adjusted';
                    ToolTip = 'Specifies whether the cost of the order has been adjusted.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Run)
            {
                Caption = 'Adjust cost for selected orders';
                Image = Start;
                ToolTip = 'Run the cost adjustment for the selected production and assembly orders.';

                trigger OnAction()
                var
                    InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
                begin
                    CurrPage.SetSelectionFilter(InventoryAdjmtEntryOrder);
                    Rec.RunCostAdjustment(InventoryAdjmtEntryOrder);
                end;
            }
        }
        area(Promoted)
        {
            actionref("Run_Promoted"; Run) { }
        }
    }
}
