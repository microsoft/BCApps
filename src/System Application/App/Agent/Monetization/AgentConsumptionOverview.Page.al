// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

using System.Agents.Troubleshooting;

/// <summary>
/// This page is showing Copilot credit consumption per agent or per agent task
/// </summary>
page 4333 "Agent Consumption Overview"
{
    PageType = Worksheet;
    ApplicationArea = All;
    SourceTable = "Agent Task Consumption";
    Caption = 'Agent consumption overview';
    InherentEntitlements = X;
    InherentPermissions = X;
    SourceTableView = sorting("Consumption Timestamp") order(descending);
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Filters)
            {
                ShowCaption = false;
                Visible = ShowFilters;
                field(StartDateControl; StartDate)
                {
                    ApplicationArea = All;
                    Caption = 'Start date';
                    ToolTip = 'Specifies the start date for filtering the consumption data.';

                    trigger OnValidate()
                    begin
                        UpdateDateRange(StartDate, EndDate);
                        CurrPage.Update(false);
                    end;
                }
                field(EndDateControl; EndDate)
                {
                    ApplicationArea = All;
                    Caption = 'End date';
                    ToolTip = 'Specifies the end date for filtering the consumption data.';

                    trigger OnValidate()
                    begin
                        UpdateDateRange(StartDate, EndDate);
                        CurrPage.Update(false);
                    end;
                }
            }
            repeater(GroupName)
            {
                Editable = false;
                field(ConsumptionDateTime; Rec."Consumption Timestamp")
                {
                    Caption = 'Created at';
                    ToolTip = 'Specifies the date and time when the consumption was created.';
                }
                field(Credits; Rec."Copilot Credits")
                {
                    AutoFormatType = 0;
                    DecimalPlaces = 0 : 2;
                    Caption = 'Copilot credits';
                }
                field("Company Name"; Rec."Company Name")
                {
                    Visible = false;
                    Caption = 'Company name';
                }
                field(Agent; Rec."Feature Name")
                {
                    Caption = 'Resource name';
                    ToolTip = 'Specifies the name of the resource that consumed the credits. This is typically the type of the agent that performed the operation.';
                }
                field(UserName; Rec."Agent User Display Name")
                {
                    Caption = 'User name';
                    ToolTip = 'Specifies the name of the user who performed the operation.';
                }
                field(Operation; Rec."Actions")
                {
                    Caption = 'Actions';
                }
                field(Description; DescriptionTxt)
                {
                    Caption = 'Description';
                    ToolTip = 'Specifies the description of the operation';
                }
                field(CopilotStudioFeature; Rec."Copilot Studio Feature Display Name")
                {
                    Caption = 'Copilot Studio feature';
                }
                field("Agent Task ID"; Rec."Task ID")
                {
                    Caption = 'Agent task ID';
                    Enabled = not FilteredToTask;
                    ExtendedDatatype = Task;

                    trigger OnDrillDown()
                    begin
                        DrillDownToAgentTaskConsumption();
                    end;
                }
            }
            group(TotalsFooterOuterGroup)
            {
                Visible = TotalsVisible;
                ShowCaption = false;
                grid(TotalsFooterGroup)
                {
                    ShowCaption = false;
                    Editable = false;
                    GridLayout = columns;

                    grid(TotalLinesGroup)
                    {
                        Caption = 'Entries';
                        GridLayout = Columns;

                        group(DescriptionGroup)
                        {
                            ShowCaption = false;

                            field(ConsumptionCaption; ConsumptionCaption)
                            {
                                Caption = 'Consumption overview for';
                                Editable = false;
                                Style = Strong;
                                ToolTip = 'Specifies for what the consumption data is displayed.';
                            }
                            group(DateRangeGroup)
                            {
                                ShowCaption = false;
                                Visible = not FilteredToTask;

                                field(DateRange; DateRangeTxt)
                                {
                                    Caption = 'Date range';
                                    Editable = false;
                                    ToolTip = 'Specifies the date range for the consumption data.';
                                }
                            }
                            group(TotalEntriesTaskGroup)
                            {
                                ShowCaption = false;
                                Visible = FilteredToTask;

                                field(TotalEntriesTask; TotalEntriesCount)
                                {
                                    Caption = 'Number of entries';
                                    Editable = false;
                                    ToolTip = 'Specifies the total number of entries.';
                                }
                            }
                        }
                        group(TotalCopilotCreditsGroup)
                        {
                            ShowCaption = false;
                            Visible = not FilteredToTask;

                            field(TotalEntries; TotalEntriesCount)
                            {
                                Caption = 'Number of entries';
                                Editable = false;
                                ToolTip = 'Specifies the total number of entries.';
                            }

                            field(TotalCopilotCredits; TotalEntriesCopilotCredits)
                            {
                                Caption = 'Total Copilot credits';
                                AutoFormatType = 0;
                                DecimalPlaces = 0 : 2;
                                Editable = false;
                                ToolTip = 'Specifies the total number of Copilot credits consumed.';
                            }
                        }
                        group(TotalTaskConsumedCreditsGroup)
                        {
                            ShowCaption = false;
                            field(TaskName; TaskNameTxt)
                            {
                                Caption = 'Task';
                                Editable = false;
                                ToolTip = 'Specifies the title of the agent task.';

                                trigger OnDrillDown()
                                begin
                                    DrillDownToAgentTask();
                                end;
                            }
                            group(TaskTotalCredits)
                            {
                                ShowCaption = false;

                                field(TotalTaskCredits; TotalTaskConsumedCredits)
                                {
                                    AutoFormatType = 0;
                                    DecimalPlaces = 0 : 2;
                                    Caption = 'Total task Copilot credits';
                                    Editable = false;
                                    ToolTip = 'Specifies the total number of Copilot credits consumed by the agent task.';

                                    trigger OnDrillDown()
                                    begin
                                        DrillDownToAgentTaskConsumption();
                                    end;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(PreviousMonth)
            {
                Visible = ShowFilters;
                ApplicationArea = All;
                Caption = 'Previous month';
                ToolTip = 'Move the date range filter to the previous month.';
                Image = PreviousSet;
                trigger OnAction()
                begin
                    StartDate := CalcDate('<-1M-CM>', StartDate);
                    EndDate := CalcDate('<CM>', StartDate);
                    UpdateDateRange(StartDate, EndDate);
                    Clear(TaskNameTxt);
                    Clear(TotalTaskConsumedCredits);
                    CurrPage.Update(false);
                end;
            }
            action(NextMonth)
            {
                Visible = ShowFilters;
                ApplicationArea = All;
                Caption = 'Next month';
                ToolTip = 'Move the date range filter to the next month.';
                Image = NextSet;
                trigger OnAction()
                begin
                    if EndDate >= CalcDate('<CM>', Today()) then begin
                        Message(TheEndDateIsTodayMsg);
                        exit;
                    end;

                    StartDate := CalcDate('<+1M-CM>', StartDate);
                    EndDate := CalcDate('<CM>', StartDate);
                    if EndDate > Today() then
                        EndDate := Today();

                    UpdateDateRange(StartDate, EndDate);
                    CurrPage.Update(false);
                end;
            }
            action(CurrentMonth)
            {
                Visible = ShowFilters;
                ApplicationArea = All;
                Caption = 'Current month';
                ToolTip = 'Move the date range filter to the current month.';
                Image = Calendar;

                trigger OnAction()
                begin
                    SetDateRangeFilters();
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(PreviousMonth_Promoted; PreviousMonth)
                {
                }
                actionref(NextMonth_Promoted; NextMonth)
                {
                }
                actionref(CurrentMonth_Promoted; CurrentMonth)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        ValidateAgentAccessControl();
        SetDateRangeFilters();
        OnGetTotalsVisible(TotalsVisible, FilteredToTask);
    end;

    trigger OnAfterGetRecord()
    begin
        UpdateRowValues();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateAgentTaskName();
        UpdateTheDescriptionAndTotalsVisibility();
        UpdateTotals();
    end;

    local procedure UpdateRowValues()
    var
        DescriptionInStream: InStream;
    begin
        Rec.CalcFields(Description, "Agent User Display Name", "Task Title");
        Rec.Description.CreateInStream(DescriptionInStream, TextEncoding::UTF8);
        DescriptionInStream.ReadText(DescriptionTxt);
    end;

    local procedure UpdateAgentTaskName()
    begin
        TaskNameTxt := StrSubstNo(AgentTaskNameTxt, Rec."Task Id", Rec."Task Title");
    end;

    local procedure UpdateTotals()
    var
        AgentTaskConsumption: Record "Agent Task Consumption";
    begin
        if not TotalsVisible then
            exit;

        TotalEntriesCount := Rec.Count();
        AgentTaskConsumption.Copy(Rec);
        AgentTaskConsumption.CalcSums("Copilot Credits");
        TotalEntriesCopilotCredits := AgentTaskConsumption."Copilot Credits";

        AgentTaskConsumption.Copy(Rec);
        AgentTaskConsumption.SetRange("Task Id", Rec."Task ID");
        AgentTaskConsumption.CalcSums("Copilot Credits");
        TotalTaskConsumedCredits := AgentTaskConsumption."Copilot Credits";
    end;

    local procedure UpdateTheDescriptionAndTotalsVisibility()
    begin
        TotalsVisible := true;
        FilteredToTask := false;
        ShowFilters := true;

        if (Rec.GetFilter("Agent User Security Id") = '') and (Rec.GetFilter("Task Id") = '') then begin
            ChangedDateRangeFilters := false;
            ConsumptionCaption := EverythingTok;
            TotalsVisible := false;
            FilteredToTask := false;
            exit;
        end;

        if Rec.GetFilter("Task Id") <> '' then begin
            ConsumptionCaption := TaskNameTxt;
            FilteredToTask := true;
            ShowFilters := false;
            ClearDateRangeFilters();
            exit;
        end;

        if Rec.GetFilter("Agent User Security Id") <> '' then begin
            ConsumptionCaption := Rec."Agent User Display Name";
            FilteredToTask := false;
            exit;
        end;
    end;

    local procedure SetDateRangeFilters()
    begin
        if ChangedDateRangeFilters then
            exit;

        if Rec.GetFilter("Task Id") = '' then begin
            EndDate := Today();
            StartDate := CalcDate(StartDateTok, Today());
            UpdateDateRange(StartDate, EndDate);
            DateRangeTxt := Format(StartDate) + ' - ' + Format(EndDate);
        end;
    end;

    local procedure ClearDateRangeFilters()
    begin
        Rec.SetRange("Consumption Timestamp");
        Clear(StartDate);
        Clear(EndDate);
    end;

    local procedure UpdateDateRange(NewStartDate: Date; NewEndDate: Date)
    begin
        StartDate := NewStartDate;
        EndDate := NewEndDate;

        Rec.SetRange("Consumption Timestamp", CreateDateTime(StartDate, 0T), CreateDateTime(EndDate, 235959.999T));
    end;

    local procedure DrillDownToAgentTask()
    var
        AgentTaskLogEntry: Record "Agent Task Log Entry";
    begin
        AgentTaskLogEntry.SetRange("Task ID", Rec."Task ID");
        Page.Run(Page::"Agent Task Log Entry List", AgentTaskLogEntry)
    end;

    local procedure DrillDownToAgentTaskConsumption()
    var
        AgentConsumptionOverview: Codeunit "Agent Consumption Overview";
    begin
        AgentConsumptionOverview.OpenAgentTaskConsumptionOverview(Rec."Task ID");
    end;

    /// <summary>
    /// Validate the current user has access to the agent and task specified in the record filters.
    /// The goal is to avoid showing an empty page for the main known scenarios by raising an error.
    /// For more complex filters, or scenarios without filters, a notification is raised to explain
    /// that only data they have access to is reported.
    /// </summary>
    local procedure ValidateAgentAccessControl()
    var
        AgentTask: Record "Agent Task";
        AgentSystemPermissions: Codeunit "Agent System Permissions";
        AgentUserSecurityId: Guid;
        TaskId: BigInteger;
    begin
        RecallNonAdminDisclaimerNotification();

        if AgentSystemPermissions.CurrentUserHasCanManageAllAgentsPermission() then
            exit;

        // There is a filter on a specific agent user security, check that the user has access to this agent.
        if Rec.GetFilter("Agent User Security Id") <> '' then begin
            if Evaluate(AgentUserSecurityId, Rec.GetFilter("Agent User Security Id")) then
                if not AgentSystemPermissions.CurrentUserCanUseAgent(AgentUserSecurityId) then
                    Error(YouDoNotHaveAccessToTheAgentErr);
            exit;
        end;

        // There is a filter on a specific task ID, check that the user has access to this task.
        if Rec.GetFilter("Task Id") <> '' then begin
            if Evaluate(TaskId, Rec.GetFilter("Task Id")) then
                if not AgentTask.Get(TaskId) then
                    Error(YouDoNotHaveAccessToTheAgentErr)
                else
                    if not AgentSystemPermissions.CurrentUserCanUseAgent(AgentTask."Agent User Security ID") then
                        Error(YouDoNotHaveAccessToTheAgentErr);
            exit;
        end;

        // For cases with no filters or with complex filters, the user will see data for the agents they have access to.
        SendNonAdminDisclaimerNotification();
    end;

    local procedure RecallNonAdminDisclaimerNotification()
    var
        NonAdminNotification: Notification;
    begin
        NonAdminNotification.Id := GetNonAdminDisclaimerNotificationId();
        NonAdminNotification.Recall();
    end;

    local procedure SendNonAdminDisclaimerNotification()
    var
        AgentSystemPermissions: Codeunit "Agent System Permissions";
        NonAdminNotification: Notification;
    begin
        if AgentSystemPermissions.CurrentUserHasCanManageAllAgentsInAllCompaniesPermission() then
            exit;

        NonAdminNotification.Message := NonAdminDisclaimerMsg;
        NonAdminNotification.Scope := NotificationScope::LocalScope;
        NonAdminNotification.Send();
    end;

    local procedure GetNonAdminDisclaimerNotificationId(): Text
    begin
        exit('b9234f5f-3e6b-437a-9f34-acdb9bf9fb8f');
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetTotalsVisible(var TotalsVisible: Boolean; var AgentTaskTotalsVisible: Boolean)
    begin
    end;

    var
        ChangedDateRangeFilters: Boolean;
        StartDate: Date;
        EndDate: Date;
        DescriptionTxt: Text;
        TotalEntriesCount: Integer;
        TaskNameTxt: Text;
        FilteredToTask: Boolean;
        TotalEntriesCopilotCredits: Decimal;
        TotalTaskConsumedCredits: Decimal;
        ConsumptionCaption: Text;
        DateRangeTxt: Text;
        ShowFilters: Boolean;
        TotalsVisible: Boolean;
        EverythingTok: Label 'Everything';
        AgentTaskNameTxt: Label 'Task #%1 - %2', Comment = '%1 - ID of the agent task, %2 - Title of the agent task';
        TheEndDateIsTodayMsg: Label 'The end date is already set to today. You cannot move the date range filter further.';
        NonAdminDisclaimerMsg: Label 'Consumption data is limited to agents you have access to. To view data for all agents, contact a user with the Agent Admin role in all companies.';
        YouDoNotHaveAccessToTheAgentErr: Label 'You do not have permission to view consumption data for this agent.';
        StartDateTok: Label '<-CM>', Locked = true;
}