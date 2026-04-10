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
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Dimension 1 Value Code"; Rec."Dimension 1 Value Code")
                {
                    ApplicationArea = Dimensions;
                }
                field("Dimension 2 Value Code"; Rec."Dimension 2 Value Code")
                {
                    ApplicationArea = Dimensions;
                }
                field("Dimension 3 Value Code"; Rec."Dimension 3 Value Code")
                {
                    ApplicationArea = Dimensions;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Sales Amount"; Rec."Sales Amount")
                {
                    ApplicationArea = Basic, Suite;

                    trigger OnDrillDown()
                    begin
                        DrillDown();
                    end;
                }
                field("Cost Amount"; Rec."Cost Amount")
                {
                    ApplicationArea = Basic, Suite;

                    trigger OnDrillDown()
                    begin
                        DrillDown();
                    end;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Basic, Suite;

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

