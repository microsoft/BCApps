// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

using System.Agents.TaskPane;

page 4300 "Agent Task List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Agent Task";
    Caption = 'Agent Tasks', Comment = 'Agent Tasks in this page should be translated as Tasks that AI agents were assigned.';
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    AdditionalSearchTerms = 'Agent Tasks, Agent Task, Agent, Agent Log, Agent Logs';
    SourceTableView = sorting("Last Log Entry Timestamp") order(descending);
    InherentEntitlements = X;
    InherentPermissions = X;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(AgentConversations)
            {
                field(TaskID; Rec.ID)
                {
                    Caption = 'Task ID';
                    Editable = false;
                    ExtendedDatatype = Task;

                    trigger OnDrillDown()
                    var
                        TaskPane: Codeunit "Task Pane";
                    begin
                        TaskPane.ShowTask(Rec);
                    end;
                }
                field(Title; Rec.Title)
                {
                    Caption = 'Title';
                }
                field(LastLogEntryTimestamp; Rec."Last Log Entry Timestamp")
                {
                    Caption = 'Last Updated';
                }
                field(LastLogEntryId; Rec."Last Log Entry ID")
                {
                }
                field(Status; Rec.Status)
                {
                    Caption = 'Status';
                    ToolTip = 'Specifies the status of the agent task.';
                }
                field(NeedsAttention; Rec."Needs Attention")
                {
                    Caption = 'Needs Attention';
                    ToolTip = 'Specifies whether the task needs attention.';
                }
                field(CreatedAt; Rec.SystemCreatedAt)
                {
                    Caption = 'Created at';
                    ToolTip = 'Specifies the date and time when the agent task was created.';
                }
                field(NumberOfStepsDone; NumberOfStepsDone)
                {
                    Caption = 'Steps Done';
                    ToolTip = 'Specifies the number of steps that have been done for the specific task.';

                    trigger OnDrillDown()
                    var
                        AgentTaskImpl: Codeunit "Agent Task Impl.";
                    begin
                        AgentTaskImpl.ShowTaskLogEntries(Rec);
                    end;
                }
                field("Created By"; Rec."Created By Full Name")
                {
                    Caption = 'Created by';
                    Tooltip = 'Specifies the full name of the user that created the agent task.';
                }
                field("Agent Display Name"; Rec."Agent Display Name")
                {
                    Caption = 'Agent';
                    ToolTip = 'Specifies the agent that is associated with the task.';

                    trigger OnDrillDown()
                    var
                        TaskPane: Codeunit "Task Pane";
                    begin
                        TaskPane.ShowAgent(Rec."Agent User Security ID");
                    end;
                }
                field(AgentSubstate; Rec."Agent Substate")
                {
                    Caption = 'Agent Substate';
                    ToolTip = 'Specifies whether the agent that owns the task is archived.';
                    Editable = false;
                    Visible = ShouldShowAllAgents;
                }
                field(TaskArchived; Rec.Archived)
                {
                    Caption = 'Archived';
                    ToolTip = 'Specifies whether the task is archived.';
                }
                field(CreatedByID; Rec."Created By")
                {
                    Visible = false;
                }
                field(AgentUserSecurityID; Rec."Agent User Security ID")
                {
                    Visible = false;
                }
                field(Credits; ConsumedCredits)
                {
                    Caption = 'Copilot credits';
                    ToolTip = 'Specifies the number of Copilot credits consumed by the agent task.';
                    AutoFormatType = 0;
                    DecimalPlaces = 0 : 2;

                    trigger OnDrillDown()
                    var
                        AgentConsumptionOverview: Codeunit "Agent Consumption Overview";
                    begin
                        AgentConsumptionOverview.OpenAgentTaskConsumptionOverview(Rec.ID);
                    end;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(ViewTaskMessage)
            {
                ApplicationArea = All;
                Caption = 'View messages';
                ToolTip = 'Show messages for the selected task.';
                Enabled = TaskSelected;
                Image = ShowList;

                trigger OnAction()
                begin
                    ShowTaskMessages();
                end;
            }
            action(ViewTaskLogEntries)
            {
                ApplicationArea = All;
                Caption = 'View log entries';
                ToolTip = 'Show log entries for the selected task.';
                Enabled = TaskSelected;
                Image = TaskList;
                Scope = Repeater;

                trigger OnAction()
                var
                    AgentTaskImpl: Codeunit "Agent Task Impl.";
                begin
                    AgentTaskImpl.ShowTaskLogEntries(Rec);
                end;
            }
            action(Stop)
            {
                ApplicationArea = All;
                Caption = 'Stop';
                ToolTip = 'Stop the selected task.';
                Enabled = TaskSelected;
                Image = Stop;
                Scope = Repeater;

                trigger OnAction()
                var
                    AgentTaskImpl: Codeunit "Agent Task Impl.";
                begin
                    AgentTaskImpl.StopTask(Rec.ID, Rec."Status"::"Stopped by User", true);
                    CurrPage.Update(false);
                end;
            }
            action(Archive)
            {
                ApplicationArea = All;
                Caption = 'Archive';
                ToolTip = 'Archive the selected tasks.';
                Enabled = TaskSelected;
                Image = Archive;
                Scope = Repeater;

                trigger OnAction()
                var
                    SelectedAgentTask: Record "Agent Task";
                    AgentTaskImpl: Codeunit "Agent Task Impl.";
                    SelectedCount: Integer;
                    UserConfirm: Boolean;
                begin
                    CurrPage.SetSelectionFilter(SelectedAgentTask);
                    SelectedCount := SelectedAgentTask.Count();
                    if SelectedCount = 0 then
                        exit;

                    if SelectedCount > 1 then
                        if not Confirm(AreYouSureThatYouWantToArchiveTheTasksQst, false, SelectedCount) then
                            exit;

                    UserConfirm := SelectedCount = 1; // Only confirm from the ArchiveTask call when there is one task, otherwise we have already confirmed with the user.
                    if SelectedAgentTask.FindSet() then
                        repeat
                            AgentTaskImpl.ArchiveTask(SelectedAgentTask.ID, UserConfirm);
                        until SelectedAgentTask.Next() = 0;

                    CurrPage.Update(false);
                end;
            }
            action(ShowAllAgents)
            {
                ApplicationArea = All;
                Caption = 'Show all agents';
                ToolTip = 'Show tasks from all agents, including agents that have been archived.';
                Image = RemoveFilterLines;
                Visible = not ShouldShowAllAgents;

                trigger OnAction()
                begin
                    ShouldShowAllAgents := true;
                    SetAgentSubstateFilter();
                end;
            }
            action(ShowActiveAgents)
            {
                ApplicationArea = All;
                Caption = 'Show active agents';
                ToolTip = 'Show only tasks from active agents that have not been archived.';
                Image = FilterLines;
                Visible = ShouldShowAllAgents;

                trigger OnAction()
                begin
                    ShouldShowAllAgents := false;
                    SetAgentSubstateFilter();
                end;
            }
        }

        area(Navigation)
        {
            action(AgentSetup)
            {
                Caption = 'Agent setup';
                ToolTip = 'Opens the agent card page for the agent who has been assigned the selected task.';
                Image = Setup;
                Enabled = TaskSelected;

                RunObject = page "Agent Card";
                RunPageLink = "User Security ID" = field("Agent User Security ID");
            }
        }

        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(ViewTaskMessage_Promoted; ViewTaskMessage)
                {
                }
                actionref(ViewTaskLogEntries_Promoted; ViewTaskLogEntries)
                {
                }
            }
        }
    }

    views
    {
        view(Archived)
        {
            Caption = 'Archived';
            Filters = where(Archived = const(true));
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetRange(Archived, false);
        ShouldShowAllAgents := false;
        SetAgentSubstateFilter();
    end;

    trigger OnAfterGetRecord()
    begin
        UpdateControls();
        CalculateTaskConsumedCredits();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateControls();
        CalculateTaskConsumedCredits();
    end;

    local procedure CalculateTaskConsumedCredits()
    var
        AgentConsumptionOverview: Codeunit "Agent Consumption Overview";
    begin
        ConsumedCredits := AgentConsumptionOverview.GetCopilotCreditsConsumed(Rec.ID);
    end;

    local procedure UpdateControls()
    var
        AgentTaskImpl: Codeunit "Agent Task Impl.";
    begin
        NumberOfStepsDone := AgentTaskImpl.GetStepsDoneCount(Rec);
        TaskSelected := Rec.ID <> 0;
    end;

    local procedure ShowTaskMessages()
    var
        AgentTaskMessage: Record "Agent Task Message";
    begin
        AgentTaskMessage.SetRange("Task ID", Rec.ID);
        Page.Run(Page::"Agent Task Message List", AgentTaskMessage);
    end;

    local procedure SetAgentSubstateFilter()
    begin
        if ShouldShowAllAgents then
            Rec.SetRange("Agent Substate")
        else
            // "Agent Substate" is a FlowField of the agent, filtered in-memory to hide archived tasks by default.
            Rec.SetRange("Agent Substate", Rec."Agent Substate"::None);
        CurrPage.Update(false);
    end;

    var
        NumberOfStepsDone: Integer;
        TaskSelected: Boolean;
        ConsumedCredits: Decimal;
        ShouldShowAllAgents: Boolean;
        AreYouSureThatYouWantToArchiveTheTasksQst: Label 'Are you sure that you want to archive the %1 selected tasks?', Comment = '%1 = number of selected tasks';
}