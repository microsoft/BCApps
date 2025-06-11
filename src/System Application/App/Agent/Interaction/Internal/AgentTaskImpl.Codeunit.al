// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

using System.Integration;
using System.Environment;

codeunit 4300 "Agent Task Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure SetMessageText(var AgentTaskMessage: Record "Agent Task Message"; MessageText: Text)
    var
        ContentOutStream: OutStream;
    begin
        Clear(AgentTaskMessage.Content);
        AgentTaskMessage.Content.CreateOutStream(ContentOutStream, GetDefaultEncoding());
        ContentOutStream.Write(MessageText);
        AgentTaskMessage.Modify(true);
    end;

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
    begin
        if MessageText = '' then
            Error(MessageTextMustBeProvidedErr);

        AgentTaskMessage."Task ID" := CurrentAgentTask.ID;
        AgentTaskMessage."Type" := AgentTaskMessage."Type"::Input;
        AgentTaskMessage."External ID" := ExternalMessageId;
        AgentTaskMessage.From := From;
        AgentTaskMessage."Requires Review" := RequiresReview;
        AgentTaskMessage.Insert();

        SetMessageText(AgentTaskMessage, MessageText);
        exit(AgentTaskMessage);
    end;

    procedure CreateUserIntervention(UserInterventionRequestEntry: Record "Agent Task Log Entry")
    begin
        CreateUserIntervention(UserInterventionRequestEntry, '', -1);
    end;

    procedure CreateUserIntervention(UserInterventionRequestEntry: Record "Agent Task Log Entry"; UserInput: Text)
    begin
        CreateUserIntervention(UserInterventionRequestEntry, UserInput, -1);
    end;

    procedure CreateUserIntervention(UserInterventionRequestEntry: Record "Agent Task Log Entry"; SelectedSuggestionId: Integer)
    begin
        CreateUserIntervention(UserInterventionRequestEntry, '', SelectedSuggestionId);
    end;

    procedure CreateUserIntervention(UserInterventionRequestEntry: Record "Agent Task Log Entry"; UserInput: Text; SelectedSuggestionId: Text)
    var
        SelectedSuggestionIdInt: Integer;
    begin
        if SelectedSuggestionId <> '' then
            if Evaluate(SelectedSuggestionIdInt, SelectedSuggestionId) then begin
                CreateUserIntervention(UserInterventionRequestEntry, UserInput, SelectedSuggestionIdInt);
                exit;
            end
            else
                Session.LogMessage('0000PKA', StrSubstNo(InvalidSelectedSuggestionIdErr, SelectedSuggestionId), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);

        CreateUserIntervention(UserInterventionRequestEntry, UserInput);
    end;

    procedure CreateUserIntervention(UserInterventionRequestEntry: Record "Agent Task Log Entry"; UserInput: Text; SelectedSuggestionId: Integer)
    var
        AgentTask: Record "Agent Task";
        AgentALFunctions: DotNet AgentALFunctions;
        UserIntervention: DotNet "AgentTaskUserIntervention";
    begin
        AgentTask.Get(UserInterventionRequestEntry."Task ID");

        UserIntervention := UserIntervention.AgentTaskUserInterventionDetails();
        if UserInput <> '' then
            UserIntervention.UserInput := UserInput;
        if SelectedSuggestionId >= 0 then
            UserIntervention.SelectedSuggestionId := SelectedSuggestionId;
        AgentALFunctions.CreateAgentTaskUserIntervention(AgentTask."Agent User Security ID", AgentTask.ID, UserInterventionRequestEntry.ID, UserIntervention);
    end;

    procedure GetUserInterventionRequestDetails(UserInterventionRequestEntry: Record "Agent Task Log Entry"; var UserInterventionRequest: DotNet "AgentTaskUserInterventionRequest")
    var
        AgentTask: Record "Agent Task";
        AgentALFunctions: DotNet AgentALFunctions;
    begin
        AgentTask.Get(UserInterventionRequestEntry."Task ID");
        UserInterventionRequest := AgentALFunctions.GetAgentTaskUserInterventionRequest(AgentTask."Agent User Security ID", AgentTask.ID, UserInterventionRequestEntry.ID);
    end;

    procedure StopTask(var AgentTask: Record "Agent Task"; AgentTaskStatus: enum "Agent Task Status"; UserConfirm: Boolean)
    begin
        if ((AgentTask.Status = AgentTaskStatus) and (AgentTask."Needs Attention" = false)) then
            exit; // Task is already stopped and does not need attention.

        if UserConfirm then
            if not Confirm(AreYouSureThatYouWantToStopTheTaskQst) then
                exit;

        AgentTask.Status := AgentTaskStatus;
        AgentTask."Needs Attention" := false;
        AgentTask.Modify(true);
    end;

    procedure RestartTask(var AgentTask: Record "Agent Task"; UserConfirm: Boolean)
    begin
        if UserConfirm then
            if not Confirm(AreYouSureThatYouWantToRestartTheTaskQst) then
                exit;

        AgentTask."Needs Attention" := false;
        AgentTask.Status := AgentTask.Status::Ready;
        AgentTask.Modify(true);
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

    procedure SetTaskStatusToReadyIfPossible(var AgentTask: Record "Agent Task")
    begin
        // Only change the status if the task is in a status where it can be started again.
        // If the task is running, we should not change the state, as platform will pickup a new message automatically.
        if CanAgentTaskBeSetToReady(AgentTask) then begin
            AgentTask.Status := AgentTask.Status::Ready;
            AgentTask.Modify(true);
        end;
    end;

    procedure CanAgentTaskBeSetToReady(var AgentTask: Record "Agent Task"): Boolean
    begin
        exit((AgentTask.Status = AgentTask.Status::Paused) or (AgentTask.Status = AgentTask.Status::Completed));
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

    procedure GetSessionAgentTaskId(): BigInteger
    var
        AgentALFunctions: DotNet AgentALFunctions;
    begin
        exit(AgentALFunctions.GetSessionAgentTaskId());
    end;

    var
        MessageTextMustBeProvidedErr: Label 'You must provide a message text.';
        AreYouSureThatYouWantToRestartTheTaskQst: Label 'Are you sure that you want to restart the task?';
        AreYouSureThatYouWantToStopTheTaskQst: Label 'Are you sure that you want to stop the task?';
        InvalidSelectedSuggestionIdErr: Label 'Invalid SelectedSuggestionId: %1', Comment = '%1 - SelectedSuggestionId', Locked = true;
        CategoryTok: Label 'Agents', Locked = true;
}