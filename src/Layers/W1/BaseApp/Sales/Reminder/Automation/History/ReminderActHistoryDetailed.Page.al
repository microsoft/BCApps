// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

page 6758 "Reminder Act. History Detailed"
{
    PageType = Document;
    ApplicationArea = All;
    SourceTable = "Reminder Action Group Log";
    ModifyAllowed = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    DataCaptionExpression = PageCaptionGlobal;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(RunId; Rec."Run Id")
                {
                    ApplicationArea = All;
                    Caption = 'Run Id';
                    ToolTip = 'Specifies the identifier of the run.';
                }
                field(ReminderActionGroup; Rec."Reminder Action Group ID")
                {
                    ApplicationArea = All;
                    Caption = 'Reminder Action Group';
                    ToolTip = 'Specifies the reminder action group.';
                }
                group(StartedCompletedGroup)
                {
                    ShowCaption = false;
                    field("Started On"; Rec."Started On")
                    {
                        ApplicationArea = All;
                        Caption = 'Started on';
                        ToolTip = 'Specifies when the job was started.';
                    }
                    field("Completed On"; Rec."Completed On")
                    {
                        ApplicationArea = All;
                        Caption = 'Completed on';
                        ToolTip = 'Specifies when the job was completed.';
                    }
                }
                group(NumberOfErrorsGroup)
                {
                    Visible = NumberOfErrors > 0;
                    ShowCaption = false;

                    field(NumberOfErrors; NumberOfErrors)
                    {
                        ApplicationArea = All;
                        Caption = 'Number of errors';
                        Editable = false;
                        ToolTip = 'Specifies the number of errors that occurred during the run.';
                        Style = Unfavorable;
                        StyleExpr = NumberOfErrors > 0;

                        trigger OnDrillDown()
                        var
                            ReminderAutomationError: Record "Reminder Automation Error";
                        begin
                            Rec.GetActiveErrors(ReminderAutomationError);
                            Page.Run(Page::"Reminder Aut. Error Overview", ReminderAutomationError);
                        end;
                    }
                }
            }

            part(ReminderActHistoryLog; "Reminder Act. History Log")
            {
                ApplicationArea = All;
                Caption = 'Action log';
                SubPageLink = "Reminder Action Group ID" = field("Reminder Action Group ID"), "Run Id" = field("Run Id");
                UpdatePropagation = Both;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        PageCaptionGlobal := StrSubstNo(CaptionLbl, Rec."Reminder Action Group ID", Rec."Run Id");
        NumberOfErrors := Rec.GetNumberOfActiveErrors();
    end;

    var
        PageCaptionGlobal: Text;
        NumberOfErrors: Integer;
        CaptionLbl: Label '%1 - Run Id %2', Comment = '%1 - Code of the action group, %2 - number, e.g. CREATE REMINDERS FOR DOMESTIC CUSTOMERS - Run Id 22';
}