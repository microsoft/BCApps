// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.ExpenseAgent;
using System.Environment;

page 7076 "Expense Agent Status"
{
    PageType = Card;
    SourceTable = "Expense Agent Status";
    SourceTableTemporary = true;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Expense Agent Status';
    Editable = false;

    layout
    {
        area(content)
        {
            group(General)
            {
                field(AgentTask; AgentTaskStatus())
                {
                    Caption = 'Agent Task Status';
                    ToolTip = 'Specifies whether the agent task is running or not.';
                }
                field(RecoverTask; AgentRecoveryTaskStatus())
                {
                    Caption = 'Recovery Task Status';
                    ToolTip = 'Specifies whether the recovery task is scheduled or not.';
                }
                field("Last Sync At"; Rec."Last Sync At")
                {
                }
                field("Last Notif. Run At"; Rec."Last Notif. Run At")
                {
                }
                field(JobStatus; Rec."Scheduler Task Status")
                {
                }
                field(JobError; Rec."Scheduler Task Error Message")
                {
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(LogEntries)
            {
                Caption = 'Scheduler Task Log';
                ToolTip = 'Show the history of task execution.';
                Image = Log;
                RunObject = page "EA Scheduler Tasks";
            }
            action(OutboxEmails)
            {
                Caption = 'Outbox Emails';
                ToolTip = 'Show the emails queued for delivery by the agent and their delivery status.';
                Image = Email;
                RunObject = page "EA Outbox Emails";
            }
            action(Schedule)
            {
                Caption = 'Start agent tasks';
                ToolTip = 'Starts the agent background task';
                Image = Start;

                trigger OnAction()
                var
                    ExpenseAgentSetup: Record "Expense Agent Setup";
                    EAAgentScheduler: Codeunit "EA Agent Scheduler";
                begin
                    ExpenseAgentSetup.Get();
                    if not ExpenseAgentSetup."Enable Agent" then
                        Error(AgentNotEnabledErr);
                    EAAgentScheduler.ScheduleAgent(ExpenseAgentSetup);
                    RefreshTempTable();
                end;
            }
            action(Stop)
            {
                Caption = 'Stop agent tasks';
                ToolTip = 'Cancels the agent background tasks';
                Image = Stop;

                trigger OnAction()
                var
                    EAAgentScheduler: Codeunit "EA Agent Scheduler";
                begin
                    EAAgentScheduler.RemoveAgentTasks();
                    RefreshTempTable();
                end;
            }
        }
        area(Promoted)
        {
            actionref(LogEntriesPro; LogEntries) { }
            actionref(OutboxEmailsPro; OutboxEmails) { }
            actionref(SchedulePro; Schedule) { }
            actionref(StopPro; Stop) { }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    begin
        RefreshTempTable();
        exit(Rec.Find(Which));
    end;

    var
        NotRunningTxt: Label 'Task is not scheduled';
        TaskIsPausedTxt: Label 'Task is paused';
        TaskScheduledToRunAtTxt: Label 'Task will run after %1', Comment = '%1 is a time';
        AgentNotEnabledErr: Label 'The Expense Agent is not enabled.';

    local procedure RefreshTempTable()
    var
        ExpenseAgentStatus: Record "Expense Agent Status";
    begin
        if Rec.Delete() then;
        if not ExpenseAgentStatus.Get() then
            ExpenseAgentStatus.Init();
        Rec := ExpenseAgentStatus;
        if Rec.Insert() then;
    end;

    local procedure AgentTaskStatus(): Text
    begin
        exit(TaskStatus(Rec."Agent Task ID"));
    end;

    local procedure AgentRecoveryTaskStatus(): Text
    begin
        exit(TaskStatus(Rec."Agent Recovery Task ID"));
    end;

    local procedure TaskStatus(TaskID: Guid): Text
    var
        ScheduledTask: Record "Scheduled Task";
    begin
        if IsNullGuid(TaskID) then
            exit(NotRunningTxt);
        if not ScheduledTask.Get(TaskID) then
            exit(NotRunningTxt);
        if not ScheduledTask."Is Ready" then
            exit(TaskIsPausedTxt);
        exit(StrSubstNo(TaskScheduledToRunAtTxt, ScheduledTask."Not Before"));
    end;
}
