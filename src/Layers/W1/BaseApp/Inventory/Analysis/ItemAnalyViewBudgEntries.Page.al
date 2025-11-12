// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

page 7154 "Item Analy. View Budg. Entries"
{
    Caption = 'Analysis View Budget Entries';
    DataCaptionFields = "Analysis View Code";
    Editable = false;
    PageType = List;
    SourceTable = "Item Analysis View Budg. Entry";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Budget Name"; Rec."Budget Name")
                {
                    ApplicationArea = ItemBudget;
                    ToolTip = 'Specifies the name of the budget that the analysis view budget entries are linked to.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code of the location to which the analysis view budget entry was posted.';
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the item that the analysis view budget entry is linked to.';
                }
                field("Dimension 1 Value Code"; Rec."Dimension 1 Value Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the dimension value you selected for the analysis view dimension that you defined as Dimension 1 on the analysis view card.';
                }
                field("Dimension 2 Value Code"; Rec."Dimension 2 Value Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies which dimension value you have selected for the analysis view dimension that you defined as Dimension 2 on the analysis view card.';
                }
                field("Dimension 3 Value Code"; Rec."Dimension 3 Value Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies which dimension value you have selected for the analysis view dimension that you defined as Dimension 1 on the analysis view card.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date on which the item budget entries in an analysis view budget entry were posted.';
                }
                field("Sales Amount"; Rec."Sales Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the item budget entry sales amount included in an analysis view budget entry.';

                    trigger OnDrillDown()
                    begin
                        DrillDown();
                    end;
                }
                field("Cost Amount"; Rec."Cost Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the item budget entry cost amount included in an analysis view budget entry.';

                    trigger OnDrillDown()
                    begin
                        DrillDown();
                    end;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the item budget entry quantity included in an analysis view budget entry.';

                    trigger OnDrillDown()
                    begin
                        DrillDown();
                    end;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        if Rec."Analysis View Code" <> xRec."Analysis View Code" then;
    end;

    local procedure DrillDown()
    var
        ItemBudgetEntry: Record "Item Budget Entry";
    begin
        ItemBudgetEntry.SetRange("Entry No.", Rec."Entry No.");
        PAGE.RunModal(0, ItemBudgetEntry);
    end;
}

