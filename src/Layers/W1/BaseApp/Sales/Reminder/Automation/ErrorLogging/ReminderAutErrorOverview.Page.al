// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

page 6759 "Reminder Aut. Error Overview"
{
    PageType = List;
    SourceTable = "Reminder Automation Error";
    SourceTableView = sorting(Id) order(descending);
    Editable = false;
    ModifyAllowed = false;
    InsertAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(ReminderRunId; Rec."Run Id")
                {
                    ApplicationArea = All;
                    Caption = 'Run Id';
                    ToolTip = 'Specifies the id of the reminder action job that caused the error.';
                }
                field(ReminderActionId; Rec.ReminderActionId)
                {
                    ApplicationArea = All;
                    Caption = 'Action Id';
                    ToolTip = 'Specifies the id of the reminder action that caused the error.';
                }
                field(ErrorMessage; Rec."Error Text Short")
                {
                    ApplicationArea = All;
                    Caption = 'Error';
                    ToolTip = 'Specifies the error message. Invoke the error message to see the full error message.';

                    trigger OnDrillDown()
                    var
                        FullMesage: Text;
                        NewLine: Text;
                    begin
                        NewLine[1] := 10;
                        FullMesage := Rec.GetErrorMessage() + NewLine + Rec.GetErrorCallstack();
                        Message(FullMesage);
                    end;
                }
                field(CreatedAd; Rec.SystemCreatedAt)
                {
                    ApplicationArea = All;
                    Caption = 'Created at';
                    ToolTip = 'Specifies the date and time when the error was created.';
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(Dismiss)
            {
                ApplicationArea = All;
                Caption = 'Dismiss error';
                Image = Approval;
                ToolTip = 'Dismisses the error. The error will not be shown in the overview anymore. If you want to see the error again, you can use the "Show all" action.';

                trigger OnAction()
                begin
                    CurrPage.SetSelectionFilter(Rec);
                    Rec.ModifyAll(Dismissed, true, true);
                    CurrPage.Update(false);
                end;
            }
            action(ShowAll)
            {
                ApplicationArea = All;
                Caption = 'Show all';
                Image = AllLines;
                ToolTip = 'Shows all errors, including the dismissed errors.';

                trigger OnAction()
                begin
                    Rec.SetRange(Dismissed);
                    CurrPage.Update(false);
                end;
            }
            action(HideDismissed)
            {
                ApplicationArea = All;
                Caption = 'Hide dismissed';
                Image = FilterLines;
                ToolTip = 'Hides all dismissed errors. If you want to see the dismissed errors again, you can use the "Show all" action.';

                trigger OnAction()
                begin
                    Rec.SetRange(Dismissed, false);
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(Dismiss_Promoted; Dismiss)
                {
                }
                actionref(ShowAll_Promoted; ShowAll)
                {
                }
                actionref(HideDismissed_Promoted; HideDismissed)
                {
                }
            }
        }
    }
}