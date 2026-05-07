// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

using System.Agents.Troubleshooting;
using System.Environment;
using System.Environment.Consumption;
using System.Integration;

codeunit 4300 "Agent Task Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure GetStepsDoneCount(var AgentTask: Record "Agent Task"): Integer
    var
        AgentTaskLogEntry: Record "Agent Task Log Entry";
    begin
        AgentTaskLogEntry.SetRange("Task ID", AgentTask."ID");
        AgentTaskLogEntry.ReadIsolation := IsolationLevel::ReadCommitted;
        exit(AgentTaskLogEntry.Count());
    end;

    procedure GetDetailsForAgentTaskLogEntry(var AgentTaskLogEntry: Record "Agent Task Log Entry"): Text
    var
        ContentInStream: InStream;
        ContentText: Text;
    begin
        AgentTaskLogEntry.CalcFields(Details);
        AgentTaskLogEntry.Details.CreateInStream(ContentInStream, GetDefaultEncoding());
        ContentInStream.Read(ContentText);
        exit(ContentText);
    end;

    procedure ShowTaskLogEntries(var AgentTask: Record "Agent Task")
    var
        AgentTaskLogEntry: Record "Agent Task Log Entry";
    begin
        AgentTaskLogEntry.SetRange("Task ID", AgentTask.ID);
        Page.Run(Page::"Agent Task Log Entry List", AgentTaskLogEntry);
    end;

    procedure CreateTask(AgentUserSecurityID: Guid; TaskTitle: Text[150]; ExternalID: Text[2048]; var NewAgentTask: Record "Agent Task")
    begin
        NewAgentTask."Agent User Security ID" := AgentUserSecurityID;
        NewAgentTask."Created By" := UserSecurityId();
        NewAgentTask.Title := TaskTitle;
        NewAgentTask."Needs Attention" := false;
        NewAgentTask.Status := NewAgentTask.Status::Paused;
        NewAgentTask."External ID" := ExternalID;
        NewAgentTask.Insert();
    end;

    procedure AddMessage(From: Text[250]; MessageText: Text; ExternalMessageId: Text[2048]; var CurrentAgentTask: Record "Agent Task"; RequiresReview: Boolean): Record "Agent Task Message"
    var
        AgentTaskMessage: Record "Agent Task Message";
        AgentMessageImpl: Codeunit "Agent Message Impl.";
    begin
        if MessageText = '' then
            Error(MessageTextMustBeProvidedErr);

        AgentTaskMessage."Task ID" := CurrentAgentTask.ID;
        AgentTaskMessage."Type" := AgentTaskMessage."Type"::Input;
        AgentTaskMessage."External ID" := ExternalMessageId;
        AgentTaskMessage.From := From;
        AgentTaskMessage."Requires Review" := RequiresReview;
        AgentTaskMessage.Insert();

        AgentMessageImpl.UpdateText(AgentTaskMessage, MessageText);
        exit(AgentTaskMessage);
    end;

    procedure StopTask(AgentTaskID: BigInteger; AgentTaskStatus: enum "Agent Task Status"; UserConfirm: Boolean)
    var
        AgentTask: Record "Agent Task";
    begin
        AgentTask.ID := AgentTaskID;
        StopTask(AgentTask, AgentTaskStatus, UserConfirm);
    end;

    procedure StopTask(var AgentTask: Record "Agent Task"; AgentTaskStatus: enum "Agent Task Status"; UserConfirm: Boolean)
    var
        AgentTaskToModify: Record "Agent Task";
    begin
        AgentTaskToModify.Get(AgentTask.ID);
        if ((AgentTaskToModify.Status = AgentTaskStatus) and (AgentTaskToModify."Needs Attention" = false)) then
            exit; // Task is already stopped and does not need attention.

        if UserConfirm then
            if not Confirm(AreYouSureThatYouWantToStopTheTaskQst) then
                exit;

        AgentTaskToModify.Status := AgentTaskStatus;
        AgentTaskToModify."Needs Attention" := false;
        AgentTaskToModify.Modify(true);

        AgentTask.Status := AgentTaskToModify.Status;
        AgentTask."Needs Attention" := AgentTaskToModify."Needs Attention";
    end;

    procedure RestartTask(AgentTaskID: BigInteger; UserConfirm: Boolean)
    var
        AgentTask: Record "Agent Task";
    begin
        AgentTask.ID := AgentTaskID;
        RestartTask(AgentTask, UserConfirm);
    end;

    procedure RestartTask(var AgentTask: Record "Agent Task"; UserConfirm: Boolean)
    var
        AgentTaskToModify: Record "Agent Task";
    begin
        if UserConfirm then
            if not Confirm(AreYouSureThatYouWantToRestartTheTaskQst) then
                exit;

        AgentTaskToModify.Get(AgentTask.ID);
        AgentTaskToModify."Needs Attention" := false;
        AgentTaskToModify.Status := AgentTaskToModify.Status::Ready;
        AgentTaskToModify.Modify(true);

        AgentTask."Needs Attention" := AgentTaskToModify."Needs Attention";
        AgentTask.Status := AgentTaskToModify.Status;
    end;

    procedure TaskExists(AgentUserSecurityID: Guid; ConversationId: Text): Boolean
    var
        AgentTask: Record "Agent Task";
    begin
        AgentTask.SetRange("Agent User Security ID", AgentUserSecurityID);
        AgentTask.ReadIsolation(IsolationLevel::ReadCommitted);
        AgentTask.SetRange("External ID", ConversationId);
        exit(not AgentTask.IsEmpty());
    end;

    procedure GetDefaultEncoding(): TextEncoding
    begin
        exit(TextEncoding::UTF8);
    end;

    procedure SetTaskStatusToReadyIfPossible(AgentTaskID: BigInteger)
    var
        AgentTask: Record "Agent Task";
    begin
        AgentTask.ID := AgentTaskID;
        SetTaskStatusToReadyIfPossible(AgentTask);
    end;

    procedure SetTaskStatusToReadyIfPossible(var AgentTask: Record "Agent Task")
    var
        AgentTaskToModify: Record "Agent Task";
    begin
        // Only change the status if the task is in a status where it can be started again.
        // If the task is running, we should not change the state, as platform will pickup a new message automatically.
        if CanAgentTaskBeSetToReady(AgentTask) then begin
            AgentTaskToModify.Get(AgentTask.ID);
            AgentTaskToModify.Status := AgentTaskToModify.Status::Ready;
            AgentTaskToModify.Modify(true);
            AgentTask.Status := AgentTaskToModify.Status;
        end;
    end;

    procedure CanAgentTaskBeSetToReady(AgentTaskID: BigInteger): Boolean
    var
        AgentTask: Record "Agent Task";
    begin
        AgentTask.Get(AgentTaskID);
        exit(CanAgentTaskBeSetToReady(AgentTask));
    end;

    procedure CanAgentTaskBeSetToReady(var AgentTask: Record "Agent Task"): Boolean
    begin
        exit((AgentTask.Status = AgentTask.Status::Paused) or (AgentTask.Status = AgentTask.Status::Completed));
    end;

    procedure IsTaskRunning(AgentTaskID: BigInteger): Boolean
    var
        AgentTask: Record "Agent Task";
    begin
        AgentTask.Get(AgentTaskID);
        exit(IsTaskRunning(AgentTask));
    end;

    procedure IsTaskRunning(var AgentTask: Record "Agent Task"): Boolean
    begin
        exit(AgentTask.Status = AgentTask.Status::Running);
    end;

    procedure IsTaskCompleted(AgentTaskID: BigInteger): Boolean
    var
        AgentTask: Record "Agent Task";
    begin
        AgentTask.Get(AgentTaskID);
        exit(IsTaskCompleted(AgentTask));
    end;

    procedure IsTaskCompleted(var AgentTask: Record "Agent Task"): Boolean
    begin
        exit(AgentTask.Status = AgentTask.Status::Completed);
    end;

    procedure IsTaskStopped(AgentTaskID: BigInteger): Boolean
    var
        AgentTask: Record "Agent Task";
    begin
        AgentTask.Get(AgentTaskID);
        exit(IsTaskStopped(AgentTask));
    end;

    procedure IsTaskStopped(var AgentTask: Record "Agent Task"): Boolean
    begin
        exit((AgentTask.Status = AgentTask.Status::"Stopped by User") or (AgentTask.Status = AgentTask.Status::"Stopped by System"));
    end;

    procedure GetCopilotCreditsConsumed(AgentTaskID: BigInteger): Decimal
    var
        AgentTask: Record "Agent Task";
        UserAIConsumptionData: Record "User AI Consumption Data";
    begin
        if not AgentTask.Get(AgentTaskID) then
            exit(0);
        UserAIConsumptionData.SetRange("Agent Task Id", AgentTask.ID);
        UserAIConsumptionData.CalcSums("Copilot Credits");
        exit(UserAIConsumptionData."Copilot Credits");
    end;

    internal procedure TryGetAgentRecordFromTaskId(TaskId: Integer; var Agent: Record Agent): Boolean
    var
        AgentTask: Record "Agent Task";
    begin
        if AgentTask.Get(TaskId) then
            if Agent.Get(AgentTask."Agent User Security ID") then
                exit(true);

        exit(false);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", GetAgentTaskMessagePageId, '', true, true)]
    local procedure OnGetAgentTaskMessagePageId(var PageId: Integer)
    begin
        PageId := Page::"Agent Task Message Card";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", GetPageSummary, '', true, true)]
    local procedure OnGetGetPageSummary(PageId: Integer; Bookmark: Text; var Summary: Text)
    var
        PageSummaryParameters: Record "Page Summary Parameters";
        PageSummaryProvider: Codeunit "Page Summary Provider";
    begin
        if PageId = 0 then begin
            Summary := '';
            exit;
        end;

        PageSummaryParameters."Page ID" := PageId;
#pragma warning disable AA0139
        PageSummaryParameters.Bookmark := Bookmark;
#pragma warning restore AA0139
        PageSummaryParameters."Include Binary Data" := false;
        Summary := PageSummaryProvider.GetPageSummary(PageSummaryParameters);
    end;

    var
        MessageTextMustBeProvidedErr: Label 'You must provide a message text.';
        AreYouSureThatYouWantToRestartTheTaskQst: Label 'Are you sure that you want to restart the task?';
        AreYouSureThatYouWantToStopTheTaskQst: Label 'Are you sure that you want to stop the task?';
}