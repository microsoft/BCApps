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
        AgentTaskStep: Record "Agent Task Step";
    begin
        AgentTaskStep.SetRange("Task ID", AgentTask."ID");
        AgentTaskStep.ReadIsolation := IsolationLevel::ReadCommitted;
        exit(AgentTaskStep.Count());
    end;

    procedure GetDetailsForAgentTaskStep(var AgentTaskStep: Record "Agent Task Step"): Text
    var
        ContentInStream: InStream;
        ContentText: Text;
    begin
        AgentTaskStep.CalcFields(Details);
        AgentTaskStep.Details.CreateInStream(ContentInStream, GetDefaultEncoding());
        ContentInStream.Read(ContentText);
        exit(ContentText);
    end;

    procedure ShowTaskSteps(var AgentTask: Record "Agent Task")
    var
        AgentTaskStep: Record "Agent Task Step";
    begin
        AgentTaskStep.SetRange("Task ID", AgentTask.ID);
        Page.Run(Page::"Agent Task Step List", AgentTaskStep);
    end;

    procedure CreateTask(AgentSecurityID: Guid; TaskTitle: Text[150]; ExternalId: Text[2048]; var NewAgentTask: Record "Agent Task")
    begin
        Clear(NewAgentTask);
        NewAgentTask."Agent User Security ID" := AgentSecurityID;
        NewAgentTask.Title := TaskTitle;
        NewAgentTask."Created By" := UserSecurityId();
        NewAgentTask."Needs Attention" := false;
        NewAgentTask.Status := NewAgentTask.Status::Paused;
        NewAgentTask."External ID" := ExternalId;
        NewAgentTask.Insert();
        StartTaskIfPossible(NewAgentTask);
    end;

    procedure CreateTaskMessage(From: Text[250]; MessageText: Text; var CurrentAgentTask: Record "Agent Task")
    begin
        CreateTaskMessage(From, MessageText, '', CurrentAgentTask);
    end;

    procedure CreateTaskMessage(From: Text[250]; MessageText: Text; ExternalMessageId: Text[2048]; var CurrentAgentTask: Record "Agent Task")
    var
        AgentTask: Record "Agent Task";
        AgentTaskMessage: Record "Agent Task Message";
    begin
        if MessageText = '' then
            Error(MessageTextMustBeProvidedErr);

        if not AgentTask.Get(CurrentAgentTask.RecordId) then begin
            AgentTask."Agent User Security ID" := CurrentAgentTask."Agent User Security ID";
            AgentTask."Created By" := UserSecurityId();
            AgentTask."Needs Attention" := false;
            AgentTask.Status := AgentTask.Status::Paused;
            AgentTask.Title := CurrentAgentTask.Title;
            AgentTask."External ID" := CurrentAgentTask."External ID";
            AgentTask.Insert();
        end;

        AgentTaskMessage."Task ID" := AgentTask.ID;
        AgentTaskMessage."Type" := AgentTaskMessage."Type"::Input;
        AgentTaskMessage."External ID" := ExternalMessageId;
        AgentTaskMessage.From := From;
        AgentTaskMessage.Insert();

        SetMessageText(AgentTaskMessage, MessageText);
        StartTaskIfPossible(AgentTask);
    end;

    procedure CreateUserInterventionTaskStep(UserInterventionRequestStep: Record "Agent Task Step")
    begin
        CreateUserInterventionTaskStep(UserInterventionRequestStep, '', -1);
    end;

    procedure CreateUserInterventionTaskStep(UserInterventionRequestStep: Record "Agent Task Step"; UserInput: Text)
    begin
        CreateUserInterventionTaskStep(UserInterventionRequestStep, UserInput, -1);
    end;

    procedure CreateUserInterventionTaskStep(UserInterventionRequestStep: Record "Agent Task Step"; SelectedSuggestionId: Integer)
    begin
        CreateUserInterventionTaskStep(UserInterventionRequestStep, '', SelectedSuggestionId);
    end;

    procedure CreateUserInterventionTaskStep(UserInterventionRequestStep: Record "Agent Task Step"; UserInput: Text; SelectedSuggestionId: Integer)
    var
        AgentTask: Record "Agent Task";
        AgentTaskStep: Record "Agent Task Step";
        DetailsOutStream: OutStream;
        DetailsJson: JsonObject;
    begin
        AgentTask.Get(UserInterventionRequestStep."Task ID");

        AgentTaskStep."Task ID" := AgentTask.ID;
        AgentTaskStep."Type" := AgentTaskStep."Type"::"User Intervention";
        AgentTaskStep.Description := 'User intervention';
        DetailsJson.Add('interventionRequestStepNumber', UserInterventionRequestStep."Step Number");
        if UserInput <> '' then
            DetailsJson.Add('userInput', UserInput);
        if SelectedSuggestionId >= 0 then
            DetailsJson.Add('selectedSuggestionId', SelectedSuggestionId);
        AgentTaskStep.CalcFields(Details);
        Clear(AgentTaskStep.Details);
        AgentTaskStep.Details.CreateOutStream(DetailsOutStream, GetDefaultEncoding());
        DetailsJson.WriteTo(DetailsOutStream);
        AgentTaskStep.Insert();
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

    local procedure StartTaskIfPossible(var AgentTask: Record "Agent Task")
    begin
        // Only change the status if the task is in a status where it can be started again.
        // If the task is running, we should not change the state, as platform will pickup a new message automatically.
        if ((AgentTask.Status = AgentTask.Status::Paused) or (AgentTask.Status = AgentTask.Status::Completed)) then begin
            AgentTask.Status := AgentTask.Status::Ready;
            AgentTask.Modify(true);
        end;
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