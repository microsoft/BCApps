// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

using Microsoft.Finance.GeneralLedger.Budget;

/// <summary>
/// Displays analysis view budget entries with drill-down capabilities to underlying budget entries.
/// Provides read-only access to budget data consolidated by analysis view dimensions.
/// </summary>
/// <remarks>
/// Used for reviewing budget data within analysis view context.
/// Supports filtering by analysis view dimensions and budget name.
/// </remarks>
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
                }
                field("Budget Name"; Rec."Budget Name")
                {
                    ApplicationArea = Suite;
                }
                field("Business Unit Code"; Rec."Business Unit Code")
                {
                    ApplicationArea = Suite;
                }
                field("G/L Account No."; Rec."G/L Account No.")
                {
                    ApplicationArea = Suite;
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
                field("Dimension 4 Value Code"; Rec."Dimension 4 Value Code")
                {
                    ApplicationArea = Dimensions;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Suite;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Suite;

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

