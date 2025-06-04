// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

codeunit 4310 "Agent Task Builder Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        GlobalAgentTaskMessageBuilder: Codeunit "Agent Task Message Builder";
        MessageSet: Boolean;
        GlobalAgentUserSecurityId: Guid;
        GlobalTaskTitle: Text[150];
        GlobalExternalID: Text[2048];

    [Scope('OnPrem')]
    procedure Initialize(NewAgentUserSecurityId: Guid; NewTaskTitle: Text[150]): codeunit "Agent Task Builder Impl."
    begin
        GlobalAgentUserSecurityId := NewAgentUserSecurityId;
        GlobalTaskTitle := NewTaskTitle;
        exit(this);
    end;

    [Scope('OnPrem')]
    procedure Create(SetTaskStatusToReady: Boolean): Record "Agent Task"
    var
        AgentTaskRecord: Record "Agent Task";
        AgentTaskImpl: Codeunit "Agent Task Impl.";
    begin
        VerifyMandatoryFieldsSet();
        AgentTaskImpl.CreateTask(GlobalAgentUserSecurityId, GlobalTaskTitle, GlobalExternalID, AgentTaskRecord);
        if MessageSet then begin
            GlobalAgentTaskMessageBuilder.SetAgentTask(AgentTaskRecord);
            GlobalAgentTaskMessageBuilder.Create(false);
        end;

        if SetTaskStatusToReady then
            AgentTaskImpl.SetTaskStatusToReadyIfPossible(AgentTaskRecord);

        exit(AgentTaskRecord);
    end;

    [Scope('OnPrem')]
    procedure GetAgentTaskMessageCreated(): Record "Agent Task Message"
    begin
        exit(GlobalAgentTaskMessageBuilder.GetAgentTaskMessage());
    end;

    [Scope('OnPrem')]
    procedure SetExternalId(ExternalId: Text[2048]): codeunit "Agent Task Builder Impl."
    begin
        GlobalExternalID := ExternalId;
        exit(this);
    end;

    [Scope('OnPrem')]
    procedure AddTaskMessage(From: Text[250]; MessageText: Text): codeunit "Agent Task Builder Impl."
    begin
        GlobalAgentTaskMessageBuilder.Initialize(From, MessageText);
        exit(this);
    end;

    [Scope('OnPrem')]
    procedure AddTaskMessage(var AgentTaskMessageBuilder: Codeunit "Agent Task Message Builder"): codeunit "Agent Task Builder Impl."
    begin
        GlobalAgentTaskMessageBuilder := AgentTaskMessageBuilder;
        MessageSet := true;
        exit(this);
    end;

    [Scope('OnPrem')]
    procedure GetTaskMessageBuilder(): Codeunit "Agent Task Message Builder"
    begin
        exit(GlobalAgentTaskMessageBuilder);
    end;

    local procedure VerifyMandatoryFieldsSet()
    var
        Agent: Codeunit Agent;
        GlobalTitleMandatoryErr: Label 'Task title is mandatory. Please set the task title before creating task.';
        GlobalAgentUserSecurityIdMandatoryErr: Label 'Agent user security ID is mandatory. Please set the agent user security ID before creating task.';
        ActiveAgentDoesNotExistErr: Label 'Agent with user security ID %1 does not exist or is not active.', Comment = '%1 - Agent user security ID, value is a guid';
        CodingErrorInfo: ErrorInfo;
    begin
        if GlobalTaskTitle = '' then
            CodingErrorInfo.Message(GlobalTitleMandatoryErr);

        if IsNullGuid(GlobalAgentUserSecurityId) then
            CodingErrorInfo.Message(GlobalAgentUserSecurityIdMandatoryErr)
        else
            if not Agent.IsActive(GlobalAgentUserSecurityId) then
                CodingErrorInfo.Message(StrSubstNo(ActiveAgentDoesNotExistErr, GlobalAgentUserSecurityId));

        if CodingErrorInfo.Message = '' then
            exit;

        CodingErrorInfo.ErrorType := ErrorType::Internal;
        Error(CodingErrorInfo);
    end;
}