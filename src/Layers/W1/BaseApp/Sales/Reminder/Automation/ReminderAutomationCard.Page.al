// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using System.Threading;
using System.Telemetry;

page 6752 "Reminder Automation Card"
{
    PageType = Card;
    Caption = 'Reminder Automation';
    SourceTable = "Reminder Action Group";
    CardPageId = "Reminder Automation Card";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    NotBlank = true;
                    Caption = 'Code';
                    ToolTip = 'Specifies a unique code for the reminder action group.';

                    trigger OnValidate()
                    begin
                        if Rec.Code <> '' then
                            CurrPage.ReminderActionsPart.Page.EnableActions();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Description';
                    ToolTip = 'Specifies a description for the reminder action group.';
                    MultiLine = true;
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = All;
                    Caption = 'Blocked';
                    ToolTip = 'Specifies whether the reminder action group is blocked. Blocked reminder action groups cannot be used in the system.';
                }
                field(ReminderTerms; ReminderTermsText)
                {
                    ApplicationArea = All;
                    Caption = 'Reminder Terms Filter';
                    ToolTip = 'Specifies the reminder terms that can be used by this reminder action group. This filter is always used, regardless of the action specific filters.';
                    Editable = false;
                    trigger OnAssistEdit()
                    var
                        SelectRemTermsAutomation: Page "Select Rem. Terms Automation";
                    begin
                        SelectRemTermsAutomation.LookupMode := true;
                        SelectRemTermsAutomation.SetNewReminderTermsSelectionFilter(ReminderTermsText);
                        if not (SelectRemTermsAutomation.RunModal() in [Action::LookupOK, Action::OK]) then
                            exit;

                        ReminderTermsText := SelectRemTermsAutomation.GetReminderTermsSelectionFilter();
                        Rec.SetReminderTermsSelectionFilter(ReminderTermsText);
                        CurrPage.Update(false);
                    end;
                }
                field(Status; StatusTxt)
                {
                    ApplicationArea = All;
                    Caption = 'Status';
                    ToolTip = 'Specifies the status of the reminder action group.';
                    Editable = false;
                }
                group(ErrorMessageGroup)
                {
                    Visible = ErrorMessageVisible;
                    ShowCaption = false;

                    field(ErrorMessage; ErrorMessage)
                    {
                        Editable = false;
                        Style = Attention;
                        ApplicationArea = All;
                        Caption = 'Error Message';
                        ToolTip = 'Specifies the error message that has stopped the automation job from running. For specific error messages you need to open the details card.';

                        trigger OnDrillDown()
                        begin
                            Message(ErrorMessage);
                        end;
                    }
                }
                group(ErrorNumbersGroup)
                {
                    Visible = NumberOfActiveErrorsVisible;
                    ShowCaption = false;

                    field(NumberOfActiveErrors; NumberOfActiveErrors)
                    {
                        ApplicationArea = All;
                        Caption = 'Number of errors';
                        ToolTip = 'Specifies the number of errors that occurred when running the reminder action group.';
                        Editable = false;
                        Style = Unfavorable;
                        StyleExpr = NumberOfActiveErrors > 0;

                        trigger OnDrillDown()
                        var
                            ReminderAutomationError: Record "Reminder Automation Error";
                        begin
                            Rec.GetActiveErrors(ReminderAutomationError);
                            Page.Run(Page::"Reminder Aut. Error Overview", ReminderAutomationError);
                        end;
                    }
                }
                group(NextStartDateGroup)
                {
                    Visible = NextStartDateTxt <> '';
                    ShowCaption = false;

                    field(NextStartDate; NextStartDateTxt)
                    {
                        Editable = false;
                        ApplicationArea = All;
                        Caption = 'Expected start';
                        ToolTip = 'Specifies the expected start date and time of the next automation job. The job should start at the specified time or shortly after. If the job does not start, you need to check the job queue entries.';
                    }
                }
                group(LastRunStatusGroup)
                {
                    ShowCaption = false;
                    Visible = LastRunStatusVisible;

                    field(LastRunStatus; LastRunStatus)
                    {
                        ApplicationArea = All;
                        Caption = 'Last run';
                        Editable = false;
                        ToolTip = 'Specifies the status of the last automation job.';

                        trigger OnDrillDown()
                        begin
                            Rec.ShowHistory();
                        end;
                    }
                }
            }
            group(SchedulingGroup)
            {
                Caption = 'Scheduling';

                field(RunOn; Rec.Schedule)
                {
                    ApplicationArea = All;
                    Caption = 'Cadence';
                    ToolTip = 'Specifies the cadence of the automation job. The cadence determines how often the automation job is run.';

                    trigger OnValidate()
                    begin
                        Rec.PauseJobQueueEntry();
                        CurrPage.Update(true);
                    end;
                }
                group(SchedulingParameters)
                {
                    Visible = Rec.Schedule <> Rec.Schedule::Manual;
                    ShowCaption = false;

                    group(StartDate)
                    {
                        ShowCaption = false;
                        field("Start Date"; Rec."Start DateTime")
                        {
                            ApplicationArea = All;
                            Caption = 'Start Date';
                            ToolTip = 'Specifies the date and time when the automation job is started for the first time.';
                        }
                        group(NextSchedule)
                        {
                            ShowCaption = false;
                            Visible = Rec.Schedule = Rec.Schedule::"Custom schedule";
                            field("Next Run Date Formula"; Rec."Next Run Date Formula")
                            {
                                ApplicationArea = All;
                                Caption = 'Next Run Date formula';
                                ToolTip = 'Specifies the formula that is used to calculate the date and time when the automation job is run next time.';
                            }
                        }
                    }
                }
            }
            part(ReminderActionsPart; "Reminder Actions Part")
            {
                ApplicationArea = All;
                Caption = 'Actions';
                SubPageLink = "Reminder Action Group Code" = field(Code);
                UpdatePropagation = Both;
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
                    RefreshGlobals();
                    CurrPage.Update();
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
                    RefreshGlobals();
                    CurrPage.Update();
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
                    RefreshGlobals();
                    CurrPage.Update();
                end;
            }

            action(LogEntries)
            {
                ApplicationArea = All;
                Caption = 'Log entries';
                ToolTip = 'See the history and log entries for the reminder actions.';

                Image = EntriesList;
                trigger OnAction()
                begin
                    Rec.ShowHistory();
                end;
            }
            action(ViewJobQueueEntry)
            {
                ApplicationArea = All;
                Caption = 'Job queue entry';
                ToolTip = 'Access the job queue entry.';
                Image = Job;

                trigger OnAction()
                var
                    JobQueueEntry: Record "Job Queue Entry";
                begin
                    if not Rec.GetJobQueueEntry(JobQueueEntry) then
                        Error(CannotFindJobQueueEntryErr);

                    Page.RunModal(Page::"Job Queue Entries", JobQueueEntry);
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
        RefreshGlobals();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        RefreshGlobals();
        if Rec.Code <> '' then
            CurrPage.ReminderActionsPart.Page.EnableActions();
    end;

    trigger OnOpenPage()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        FeatureTelemetry.LogUptake('0000MK0', Rec.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Discovered)
    end;

    local procedure RefreshGlobals()
    begin
        Rec.GetStatus(StatusTxt, ErrorMessage);
        NextStartDateTxt := Rec.GetNextStartDate();
        ReminderTermsText := Rec.GetReminderTermsSelectionFilter();
        LastRunStatus := Rec.GetLastRunStatusText();
        LastRunStatusVisible := ((LastRunStatus <> '') and (not Rec.InProgress()));
        ErrorMessageVisible := ((ErrorMessage <> '') and (not Rec.InProgress()));
        NumberOfActiveErrors := Rec.GetNumberOfActiveErrors();
        NumberOfActiveErrorsVisible := (NumberOfActiveErrors > 0);
    end;

    var
        LastRunStatusVisible: Boolean;
        ErrorMessageVisible: Boolean;
        NumberOfActiveErrorsVisible: Boolean;
        StatusTxt: Text;
        ErrorMessage: Text;
        NextStartDateTxt: Text;
        ReminderTermsText: Text;
        LastRunStatus: Text;
        NumberOfActiveErrors: Integer;
        CannotFindJobQueueEntryErr: Label 'Cannot find job queue entry for the automaiton group';
}
