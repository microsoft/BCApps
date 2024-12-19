// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

page 4306 "Agent Tasks"
{
    PageType = ListPlus;
    ApplicationArea = All;
    SourceTable = "Agent Task Pane Entry";
    Caption = 'Agent Tasks';
    Editable = true;
    InsertAllowed = false;
    DeleteAllowed = false;
    Extensible = false;
    SourceTableView = sorting("Last Step Timestamp") order(descending);
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            repeater(AgentTasks)
            {
                Editable = false;
                field(TaskId; Rec."Task ID")
                {
                }
                field(TaskNeedsAttention; Rec."Needs Attention")
                {
                }
                field(TaskIndicator; Rec.Indicator)
                {
                }
                field(TaskStatus; Rec.Status)
                {
                }
                field(TaskHeader; Rec.Title)
                {
                    Caption = 'Header';
                    ToolTip = 'Specifies the header of the task.';
                }
                field(TaskSummary; TaskSummary)
                {
                    Caption = 'Summary';
                    ToolTip = 'Specifies the summary of the task.';
                }
                field(TaskStartedOn; Rec.SystemCreatedAt)
                {
                    Caption = 'Started On';
                    ToolTip = 'Specifies the date and time when the task was started.';
                }
                field(TaskLastStepCompletedOn; Rec."Last Step Timestamp")
                {
                    Caption = 'Last Step Completed On';
                }
                field(TaskStepType; Rec."Current Entry Type")
                {
                    Caption = 'Step Type';
                    ToolTip = 'Specifies the type of the last step.';
                }
            }
        }

        area(FactBoxes)
        {
            part(Timeline; "Agent Task Timeline")
            {
                SubPageLink = "Task ID" = field("Task ID");
                UpdatePropagation = Both;
                Editable = true;
            }

            part(Details; "Agent Task Details")
            {
                Provider = Timeline;
                SubPageLink = "Task ID" = field("Task ID"), "Timeline Entry ID" = field(ID);
                Editable = true;
            }
        }
    }
    actions
    {
        area(Processing)
        {
#pragma warning disable AW0005
            action(StopTask)
#pragma warning restore AW0005
            {
                Caption = 'Stop task';
                ToolTip = 'Stops the task.';
                Enabled = true;
                Scope = Repeater;
                trigger OnAction()
                var
                    AgentTask: Record "Agent Task";
                    AgentTaskImpl: Codeunit "Agent Task Impl.";
                begin
                    AgentTask.Get(Rec."Task ID");
                    AgentTaskImpl.StopTask(AgentTask, AgentTask."Status"::"Stopped by User", false);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetTaskDetails();
    end;

    local procedure SetTaskDetails()
    var
        InStream: InStream;
    begin
        // Clear old values
        Clear(TaskSummary);

        Rec.CalcFields("Summary");
        if Rec."Summary".HasValue() then begin
            Rec."Summary".CreateInStream(InStream);
            TaskSummary.Read(InStream);
        end;
    end;

    var
        TaskSummary: BigText;
}

