// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

using System.Environment;

codeunit 4300 "Agent Task Impl."
{
    Access = Internal;

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

    procedure StopTask(var AgentTask: Record "Agent Task"; AgentTaskStatus: enum "Agent Task Status"; UserConfirm: Boolean)
    begin
        if UserConfirm then
            if not Confirm(AreYouSureThatYouWantToStopTheTaskQst) then
                exit;

        AgentTask.Status := AgentTaskStatus;
        AgentTask.Modify(true);
    end;

    procedure CreateTaskMessage(MessageText: Text; ExternalMessageId: Text[2048]; var CurrentAgentTask: Record "Agent Task")
    var
        AgentTask: Record "Agent Task";
        AgentTaskMessage: Record "Agent Task Message";
    begin
        if MessageText = '' then
            Error(MessageTextMustBeProvidedErr);

        if not AgentTask.Get(CurrentAgentTask.RecordId) then begin
            AgentTask."Agent User Security ID" := CurrentAgentTask."Agent User Security ID";
            AgentTask."Created By" := UserSecurityId();
            AgentTask.Status := AgentTask.Status::Paused;
            AgentTask.Title := CurrentAgentTask.Title;
            AgentTask."External ID" := CurrentAgentTask."External ID";
            AgentTask.Insert();
        end;

        AgentTaskMessage."Task ID" := AgentTask.ID;
        AgentTaskMessage."Type" := AgentTaskMessage."Type"::Input;
        AgentTaskMessage."External ID" := ExternalMessageId;
        AgentTaskMessage.Insert();

        SetMessageText(AgentTaskMessage, MessageText);

        AgentTask.Status := AgentTask.Status::Ready;
        AgentTask.Modify(true);
    end;

    procedure GetMessageText(var AgentTaskMessage: Record "Agent Task Message"): Text
    var
        ContentInStream: InStream;
        ContentText: Text;
    begin
        AgentTaskMessage.CalcFields(Content);
        AgentTaskMessage.Content.CreateInStream(ContentInStream, GetDefaultEncoding());
        ContentInStream.Read(ContentText);
        exit(ContentText);
    end;

    procedure IsMessageEditable(var AgentTaskMessage: Record "Agent Task Message"): Boolean
    begin
        if AgentTaskMessage.Type <> AgentTaskMessage.Type::Output then
            exit(false);

        exit(AgentTaskMessage.Status = AgentTaskMessage.Status::Draft);
    end;

    procedure SetMessageText(var AgentTaskMessage: Record "Agent Task Message"; MessageText: Text)
    var
        ContentOutStream: OutStream;
    begin
        Clear(AgentTaskMessage.Content);
        AgentTaskMessage.Content.CreateOutStream(ContentOutStream, GetDefaultEncoding());
        ContentOutStream.Write(MessageText);
        AgentTaskMessage.Modify(true);
    end;

    procedure CreateUserInterventionTaskStep(UserInterventionRequestStep: Record "Agent Task Step"; UserInput: Text)
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
        if (UserInput <> '') then
            DetailsJson.Add('userInput', UserInput);
        AgentTaskStep.CalcFields(Details);
        Clear(AgentTaskStep.Details);
        AgentTaskStep.Details.CreateOutStream(DetailsOutStream, GetDefaultEncoding());
        DetailsJson.WriteTo(DetailsOutStream);
        AgentTaskStep.Insert();
    end;

    procedure UpdateAgentTaskMessageStatus(var AgentTaskMessage: Record "Agent Task Message"; Status: Option)
    begin
        AgentTaskMessage.Status := Status;
        AgentTaskMessage.Modify(true);
    end;

    procedure GetDefaultEncoding(): TextEncoding
    begin
        exit(TextEncoding::UTF8);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", GetAgentTaskMessagePageId, '', true, true)]
    local procedure OnGetAgentTaskMessagePageId(var PageId: Integer)
    begin
        PageId := Page::"Agent Task Message Card";
    end;

    var
        MessageTextMustBeProvidedErr: Label 'You must provide a message text.';
        AreYouSureThatYouWantToStopTheTaskQst: Label 'Are you sure that you want to stop the task?';
}