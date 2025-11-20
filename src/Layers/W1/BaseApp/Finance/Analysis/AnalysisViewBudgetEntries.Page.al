// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

using Microsoft.Finance.GeneralLedger.Budget;

page 559 "Analysis View Budget Entries"
{
    ApplicationArea = Dimensions;
    Caption = 'Analysis View Budget Entries';
    Editable = false;
    PageType = List;
    SourceTable = "Analysis View Budget Entry";
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Analysis View Code"; Rec."Analysis View Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the analysis view.';
                }
                field("Budget Name"; Rec."Budget Name")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the name of the budget that the analysis view budget entries are linked to.';
                }
                field("Business Unit Code"; Rec."Business Unit Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code for the business unit that the analysis view is based on.';
                }
                field("G/L Account No."; Rec."G/L Account No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of the account that the entry has been posted to.';
                }
                field("Dimension 1 Value Code"; Rec."Dimension 1 Value Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the dimension value you selected for the analysis view dimension that you defined as Dimension 1 on the analysis view card.';
                }
                field("Dimension 2 Value Code"; Rec."Dimension 2 Value Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the dimension value you selected for the analysis view dimension that you defined as Dimension 2 on the analysis view card.';
                }
                field("Dimension 3 Value Code"; Rec."Dimension 3 Value Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the dimension value you selected for the analysis view dimension that you defined as Dimension 3 on the analysis view card.';
                }
                field("Dimension 4 Value Code"; Rec."Dimension 4 Value Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the dimension value you selected for the analysis view dimension that you defined as Dimension 4 on the analysis view card.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the amount of the analysis view budget entry.';

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
        GLBudgetEntry: Record "G/L Budget Entry";
    begin
        GLBudgetEntry.SetRange("Entry No.", Rec."Entry No.");
        PAGE.RunModal(PAGE::"G/L Budget Entries", GLBudgetEntry);
    end;
}

