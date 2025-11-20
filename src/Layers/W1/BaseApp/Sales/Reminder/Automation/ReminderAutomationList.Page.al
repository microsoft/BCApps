// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;
using System.Telemetry;

page 6753 "Reminder Automation List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Reminders Automation';
    SourceTable = "Reminder Action Group";
    CardPageId = "Reminder Automation Card";
    ModifyAllowed = false;
    Editable = false;
    InsertAllowed = false;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                Editable = false;
                ShowCaption = false;
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    Caption = 'Code';
                    ToolTip = 'Specifies a code that identifies a reminder action group.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Description';
                    ToolTip = 'Specifies a description of the reminder action group.';
                }
                field(Status; StatusTxt)
                {
                    ApplicationArea = All;
                    Caption = 'Status';
                    ToolTip = 'Specifies the status of the reminder action group.';
                    Editable = false;
                }
                field(NextStartDate; NextStartDateTxt)
                {
                    Editable = false;
                    ApplicationArea = All;
                    Caption = 'Expected start';
                    ToolTip = 'Specifies the expected start date and time of the reminder action group.';
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(Start)
            {
                ApplicationArea = All;
                Caption = 'Start';
                ToolTip = 'Start the backround job that will perform the actions defined.';
                Image = Start;

                trigger OnAction()
                begin
                    Rec.VerifyDefinition();
                    Rec.ScheduleAutomationJob(Rec);
                end;
            }
            action(Pause)
            {
                ApplicationArea = All;
                Caption = 'Pause';
                ToolTip = 'Pause the backround job.';
                Image = Pause;
                trigger OnAction()
                begin
                    Rec.PauseJobQueueEntry();
                end;
            }
            action(Refresh)
            {
                ApplicationArea = All;
                Caption = 'Refresh';
                ToolTip = 'Refresh the status.';

                Image = Refresh;
                trigger OnAction()
                begin
                    CurrPage.Update();
                end;
            }

            action(LogEntries)
            {
                ApplicationArea = All;
                Caption = 'Log Entries';
                ToolTip = 'See the history and log entries for the reminder actions.';

                Image = EntriesList;
                trigger OnAction()
                begin
                    Rec.ShowHistory();
                end;
            }
            action(Reminders)
            {
                ApplicationArea = Suite;
                Caption = 'Reminders';
                RunObject = page "Reminder List";
                Image = Reminder;
                Tooltip = 'Open the Reminders page.';
            }
            action(IssuedReminders)
            {
                ApplicationArea = Suite;
                Caption = 'Issued Reminders';
                Image = OrderReminder;
                RunObject = page "Issued Reminder List";
                Tooltip = 'Open the Issued Reminders page.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(Start_Promoted; Start)
                {
                }
                actionref(Pause_Promoted; Pause)
                {
                }
                actionref(Refresh_Promoted; Refresh)
                {
                }
                actionref(LogEntries_Promoted; LogEntries)
                {
                }
                group(RemindersGroup)
                {
                    ShowAs = SplitButton;
                    actionref(Reminders_Promoted; Reminders)
                    {
                    }
                    actionref(IssuedReminders_Promoted; IssuedReminders)
                    {
                    }
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Rec.GetStatus(StatusTxt, ErrorMessage);
        NextStartDateTxt := Rec.GetNextStartDate()
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Rec.GetStatus(StatusTxt, ErrorMessage);
        NextStartDateTxt := Rec.GetNextStartDate();
    end;

    trigger OnOpenPage()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        FeatureTelemetry.LogUptake('0000MK1', Rec.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Discovered)
    end;

    var
        ErrorMessage: Text;
        NextStartDateTxt: Text;
        StatusTxt: Text;
}
