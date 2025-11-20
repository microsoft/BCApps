// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

using System.Environment.Consumption;
using System.Security.AccessControl;

page 4333 "Agent Consumption Overview"
{
    PageType = Worksheet;
    ApplicationArea = All;
    SourceTable = "User AI Consumption Data";
    Caption = 'Agent consumption overview';
    InherentEntitlements = X;
    InherentPermissions = X;
    SourceTableView = sorting("Consumption DateTime") order(descending);
    Permissions = tabledata User = r;
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
                field(StartDate; StartDate)
                {
                    ApplicationArea = All;
                    Caption = 'Start date';
                    ToolTip = 'Specifies the start date for filtering the consumption data.';

                    trigger OnValidate()
                    begin
                        UpdateDateRange(StartDate, EndDate);
                    end;
                }
                field(EndDate; EndDate)
                {
                    ApplicationArea = All;
                    Caption = 'End date';
                    ToolTip = 'Specifies the end date for filtering the consumption data.';

                    trigger OnValidate()
                    begin
                        UpdateDateRange(StartDate, EndDate);
                    end;
                }
            }
            repeater(GroupName)
            {
                Editable = false;
                field(ConsumptionDateTime; Rec."Consumption DateTime")
                {
                    Caption = 'Created at';
                    ToolTip = 'Specifies the date and time when the consumption was created.';
                }
                field(Credits; Rec."Copilot Credits")
                {
                    AutoFormatType = 0;
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
                field(UserName; UserName)
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
                field(CopilotStudioFeature; Rec."Copilot Studio Feature")
                {
                    Caption = 'Copilot Studio feature';
                }
                field("Agent Task ID"; Rec."Agent Task ID")
                {
                    Caption = 'Agent task ID';
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
                                Caption = 'Consumption for';
                                ShowCaption = false;
                                Editable = false;
                                Style = Strong;
                                ToolTip = 'Shows for what the consumption data is displayed.';
                            }
                            field(DateRange; DateRangeTxt)
                            {
                                Caption = 'Date range';
                                Visible = AgentTaskTotalsVisible;
                                Editable = false;
                                ToolTip = 'Specifies the date range for the consumption data.';
                            }
                            field(TotalEntriesTask; TotalEntriesCount)
                            {
                                Visible = not AgentTaskTotalsVisible;
                                Caption = 'Number of entries';
                                Editable = false;
                                ToolTip = 'Specifies the total number of entries.';
                            }
                        }
                        group(TotalCopilotCreditsGroup)
                        {
                            ShowCaption = false;
                            field(TotalEntries; TotalEntriesCount)
                            {
                                Caption = 'Number of entries';
                                Visible = AgentTaskTotalsVisible;
                                Editable = false;
                                ToolTip = 'Specifies the total number of entries.';
                            }
                            group(TotalCopilotCreditsFieldGroup)
                            {
                                Visible = AgentTaskTotalsVisible;
                                ShowCaption = false;
                                field(TotalCopilotCredits; TotalEntriesCopilotCredits)
                                {
                                    Caption = 'Total Copilot credits';
                                    Editable = false;
                                    ToolTip = 'Specifies the total number of Copilot credits consumed.';
                                }
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
                                var
                                    AgentTask: Record "Agent Task";
                                begin
                                    if AgentTask.Get(Rec."Agent Task Id") then
                                        Page.Run(Page::"Agent Task Details", AgentTask)
                                    else
                                        Message(CannotFindTaskMsg);
                                end;
                            }
                            group(TaskTotalCredits)
                            {
                                ShowCaption = false;

                                field(TotalTaskCredits; TotalTaskConsumedCredits)
                                {
                                    Caption = 'Total task Copilot credits';
                                    Editable = false;
                                    ToolTip = 'Specifies the total number of Copilot credits consumed by the agent task.';

                                    trigger OnDrillDown()
                                    var
                                        UserAIConsumptionData: Record "User AI Consumption Data";
                                    begin
                                        UserAIConsumptionData.SetRange("Agent Task Id", Rec."Agent Task ID");
                                        Page.Run(Page::"Agent Consumption Overview", UserAIConsumptionData);
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
                ApplicationArea = All;
                Caption = 'Previous month';
                ToolTip = 'Move the date range filter to the previous month.';
                Image = PreviousSet;
                trigger OnAction()
                begin
                    EndDate := CalcDate('<-1M>', EndDate);
                    StartDate := CalcDate('<-1M>', EndDate);
                    UpdateDateRange(StartDate, EndDate);
                end;
            }
            action(NextMonth)
            {
                ApplicationArea = All;
                Caption = 'Next month';
                ToolTip = 'Move the date range filter to the next month.';
                Image = NextSet;
                trigger OnAction()
                begin
                    if EndDate = Today() then begin
                        Message(TheEndDateIsTodayMsg);
                        exit;
                    end;

                    EndDate := CalcDate('<+1M>', StartDate);
                    if EndDate > Today() then
                        EndDate := Today();

                    StartDate := CalcDate('<-1M>', EndDate);
                    UpdateDateRange(StartDate, EndDate);
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
            }
        }
    }

    trigger OnOpenPage()
    var
        AgentImpl: Codeunit "Agent Impl.";
    begin
        if not AgentImpl.CanShowMonetizationData() then
            Error(YourNotAuthorizedToViewMonetizationDataErr);

        UpdateTheDescriptionAndTotalsVisibility();
        OnGetTotalsVisible(TotalsVisible, AgentTaskTotalsVisible);
    end;

    trigger OnAfterGetRecord()
    var
        User: Record User;
        DescriptionInStream: InStream;
    begin
        Rec.CalcFields(Description);
        Rec.Description.CreateInStream(DescriptionInStream, TextEncoding::UTF8);
        DescriptionInStream.ReadText(DescriptionTxt);
        if User.Get(Rec."User Id") then
            UserName := User."User Name";
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateTheDescriptionAndTotalsVisibility();
        UpdateTotals();
    end;

    local procedure UpdateTotals()
    var
        AgentTask: Record "Agent Task";
        UserAIConsumptionData: Record "User AI Consumption Data";
    begin
        if not TotalsVisible then
            exit;

        TotalEntriesCount := Rec.Count();
        if AgentTask.Get(Rec."Agent Task ID") then
            TaskNameTxt := StrSubstNo(AgentTaskNameTxt, AgentTask.ID, AgentTask.Title);

        UserAIConsumptionData.Copy(Rec);
        UserAIConsumptionData.CalcSums("Copilot Credits");
        TotalEntriesCopilotCredits := UserAIConsumptionData."Copilot Credits";

        UserAIConsumptionData.Copy(Rec);
        UserAIConsumptionData.SetRange("Agent Task Id", Rec."Agent Task ID");
        UserAIConsumptionData.CalcSums("Copilot Credits");
        TotalTaskConsumedCredits := UserAIConsumptionData."Copilot Credits";
    end;

    local procedure UpdateTheDescriptionAndTotalsVisibility()
    begin
        TotalsVisible := true;
        AgentTaskTotalsVisible := true;
        ShowFilters := true;

        if (Rec.GetFilter("User Id") = '') and (Rec.GetFilter("Agent Task Id") = '') then begin
            SetDateRangeFilters();
            ConsumptionCaption := AgentConsumptionOverviewCaptionTxt;
            TotalsVisible := false;
            AgentTaskTotalsVisible := false;
            exit;
        end;
        if Rec.GetFilter("Agent Task Id") <> '' then begin
            ConsumptionCaption := AgentConsumptionOverviewCaptionTxt + ' - ' + TaskNameTxt;
            ClearDateRangeFilters();
            AgentTaskTotalsVisible := false;
            ShowFilters := false;
            exit;
        end;

        if Rec.GetFilter("User Id") <> '' then begin
            ConsumptionCaption := AgentConsumptionOverviewCaptionTxt + ' - ' + StrSubstNo(AgentNameTok, UserName);
            SetDateRangeFilters();
            exit;
        end;
    end;

    local procedure SetDateRangeFilters()
    begin
        if Rec.GetFilter("Agent Task Id") = '' then begin
            EndDate := Today();
            StartDate := CalcDate('<-CM>', Today());
            UpdateDateRange(StartDate, EndDate);
            DateRangeTxt := Format(StartDate) + ' - ' + Format(EndDate);
        end;
    end;

    local procedure ClearDateRangeFilters()
    begin
        Rec.SetRange("Consumption DateTime");
        Clear(StartDate);
        Clear(EndDate);
    end;

    local procedure UpdateDateRange(NewStartDate: Date; NewEndDate: Date)
    begin
        StartDate := NewStartDate;
        EndDate := NewEndDate;

        Rec.SetRange("Consumption DateTime", CreateDateTime(StartDate, 0T), CreateDateTime(EndDate, 235959.999T));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetTotalsVisible(var TotalsVisible: Boolean; var AgentTaskTotalsVisible: Boolean)
    begin
    end;

    var
        StartDate: Date;
        EndDate: Date;
        DescriptionTxt: Text;
        UserName: Text[80];
        TotalEntriesCount: Integer;
        TaskNameTxt: Text;
        AgentTaskTotalsVisible: Boolean;
        TotalsVisible: Boolean;
        TotalEntriesCopilotCredits: Decimal;
        TotalTaskConsumedCredits: Decimal;
        ConsumptionCaption: Text;
        DateRangeTxt: Text;
        ShowFilters: Boolean;
        AgentTaskNameTxt: Label 'Task %1 - %2', Comment = '%1 - ID of the agent task, %2 - Title of the agent task';
        YourNotAuthorizedToViewMonetizationDataErr: Label 'You are missing the required permissions to view monetization data.';
        AgentConsumptionOverviewCaptionTxt: Label 'Agent consumption overview';
        AgentNameTok: Label 'Agent %1', Comment = '%1 - Name of the agent user';
        CannotFindTaskMsg: Label 'Cannot find the agent task. It is possible that the task has been deleted.';
        TheEndDateIsTodayMsg: Label 'The end date is already set to today. You cannot move the date range filter further.';
}