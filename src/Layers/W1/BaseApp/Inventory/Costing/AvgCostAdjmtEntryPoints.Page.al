// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

page 5815 "Avg. Cost Adjmt. Entry Points"
{
    PageType = List;
    ApplicationArea = Basic, Suite;
    SourceTable = "Avg. Cost Adjmt. Entry Point";
    Caption = 'Avg. Cost Adjmt. Entry Points';
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("Item No."; Rec."Item No.")
                {
                    Caption = 'Item No.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    Caption = 'Variant Code';
                }
                field("Location Code"; Rec."Location Code")
                {
                    Caption = 'Location Code';
                }
                field("Valuation Date"; Rec."Valuation Date")
                {
                    Caption = 'Valuation Date';
                }
                field("Cost Is Adjusted"; Rec."Cost Is Adjusted")
                {
                    Caption = 'Cost Is Adjusted';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action("Run Until Date")
            {
                Caption = 'Adjust cost until Valuation Date';
                Image = Start;
                ToolTip = 'Run the cost adjustment until the selected valuation date.';

                trigger OnAction()
                begin
                    Rec.RunCostAdjustmentUntilValuationDate();
                end;
            }
        }
        area(Promoted)
        {
            actionref("Run Until Date_Promoted"; "Run Until Date") { }
        }
    }
}
