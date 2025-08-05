// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

page 4300 "Agent Task List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Agent Task";
    Caption = 'Agent Tasks (Preview)';
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    AdditionalSearchTerms = 'Agent Tasks, Agent Task, Agent, Agent Log, Agent Logs';
    SourceTableView = sorting("Last Log Entry Timestamp") order(descending);
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            repeater(AgentConversations)
            {
                field(TaskID; Rec.ID)
                {
                    Caption = 'Task ID';
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
                field(ID; Rec.ID)
                {
                    Caption = 'ID';
                    trigger OnDrillDown()
                    begin
                        ShowTaskMessages();
                    end;
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
                }
                field(CreatedByID; Rec."Created By")
                {
                    Visible = false;
                }
                field(AgentUserSecurityID; Rec."Agent User Security ID")
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

                trigger OnAction()
                var
                    AgentTaskImpl: Codeunit "Agent Task Impl.";
                begin
                    AgentTaskImpl.StopTask(Rec, Rec."Status"::"Stopped by User", true);
                    CurrPage.Update(false);
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

    trigger OnAfterGetRecord()
    begin
        UpdateControls();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateControls();
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

    var
        NumberOfStepsDone: Integer;
        TaskSelected: Boolean;
}