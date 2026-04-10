// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing.ActionMessage;

page 5842 "Cost Adjmt. Action Messages"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = ReportsAndAnalysis;
    SourceTable = "Cost Adjmt. Action Message";
    Caption = 'Cost Adjustment Action Messages';
    AdditionalSearchTerms = 'cost adjustment,signal,action message';
    InsertAllowed = false;
    ModifyAllowed = false;
    Extensible = false;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    Visible = false;
                }
                field(SystemCreatedAt; Rec.SystemCreatedAt)
                {
                    ToolTip = 'Specifies the date and time when the record was created.';
                }
                field("Next Check Date/Time"; Rec."Next Check Date/Time")
                {
                }
                field(Type; Rec.Type)
                {
                }
                field(Message; Rec.Message)
                {
                    Style = StrongAccent;
                    StyleExpr = Rec.Importance < 5;

                    trigger OnDrillDown()
                    begin
                        Rec.Navigate();
                    end;
                }
                field("Custom Dimensions"; Rec."Custom Dimensions")
                {
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action("Run Checks")
            {
                Caption = 'Run Checks';
                Image = Start;
                ToolTip = 'Run all tests to identify potential problems with the cost adjustment.';

                trigger OnAction()
                var
                    CostAdjmtSignals: Codeunit "Cost Adjmt. Signals";
                begin
                    CostAdjmtSignals.RunAllTests();
                    CurrPage.Update(false);
                end;
            }
            action(Snooze)
            {
                Caption = 'Snooze for 30 days';
                Image = Pause;
                Scope = Repeater;
                ToolTip = 'Ignore all action messages of the selected type for the next 30 days.';

                trigger OnAction()
                var
                    CostAdjmtActionMessage: Record "Cost Adjmt. Action Message";
                begin
                    CurrPage.SetSelectionFilter(CostAdjmtActionMessage);
                    if CostAdjmtActionMessage.FindSet() then
                        repeat
                            CostAdjmtActionMessage."Next Check Date/Time" := CreateDateTime(CurrentDateTime().Date() + 30, CurrentDateTime().Time());
                            CostAdjmtActionMessage.Modify();
                        until CostAdjmtActionMessage.Next() = 0;
                end;
            }
        }
        area(Promoted)
        {
            actionref("Run Checks_Promoted"; "Run Checks") { }
            actionref(Snooze_Promoted; Snooze) { }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetFilter("Next Check Date/Time", '>=%1', CurrentDateTime());
    end;
}