// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

/// <summary>
/// This codeunit is used to create an agent task.
/// </summary>
codeunit 4310 "Agent Task Builder Impl."
{
    InherentEntitlements = X;
    InherentPermissions = X;
    Access = Internal;

    var
        GlobalAgentTaskMessageBuilder: Codeunit "Agent Task Message Builder";
        MessageSet: Boolean;
        GlobalAgentUserSecurityId: Guid;
        GlobalTaskTitle: Text[150];
        GlobalExternalID: Text[2048];

    /// <summary>
    /// Check if a task exists for the given agent user and conversation
    /// </summary>
    /// <param name="AgentUserSecurityID">The user security ID of the agent.</param>
    /// <param name="ConversationId">The conversation ID to check.</param>
    /// <returns>This instance of the Agent Task Builder.</returns>
    [Scope('OnPrem')]
    procedure Initialize(NewAgentUserSecurityId: Guid; NewTaskTitle: Text[150]): codeunit "Agent Task Builder Impl."
    begin
        GlobalAgentUserSecurityId := NewAgentUserSecurityId;
        GlobalTaskTitle := NewTaskTitle;
        exit(this);
    end;

    /// <summary>
    /// Create a new task for the agent.
    /// </summary>
    /// <param name="SetTaskStatusToReady">
    /// Specifies if the task status should be set to ready after creation. 
    /// </param>
    /// <returns>
    /// Agent task that was created
    /// </returns>
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

    /// <summary>
    /// Get the agent task message that was created.
    /// </summary>
    /// <returns>
    /// The agent task message that was created.
    /// </returns>
    [Scope('OnPrem')]
    procedure GetAgentTaskMessageCreated(): Record "Agent Task Message"
    begin
        exit(GlobalAgentTaskMessageBuilder.GetAgentTaskMessage());
    end;

    /// <summary>
    /// Set the external ID of the task.
    /// </summary>
    /// <param name="ExternalId">The external ID of the task. This field is used to connect to external systems, like Message ID for emails.</param>
    /// <returns>This instance of the Agent Task Builder.</returns>
    [Scope('OnPrem')]
    procedure SetExternalId(ExternalId: Text[2048]): codeunit "Agent Task Builder Impl."
    begin
        GlobalExternalID := ExternalId;
        exit(this);
    end;

    /// <summary>
    /// Add a task message to the task.
    /// Only a single message can be added to the task.
    /// </summary>
    /// <param name="From">The sender of the message.</param>
    /// <param name="MessageText">The message text.</param>
    /// <param name="AgentTaskMessageBuilder">The agent task message builder.</param>
    /// <returns>This instance of the Agent Task Builder.</returns>
    [Scope('OnPrem')]
    procedure AddTaskMessage(From: Text[250]; MessageText: Text): codeunit "Agent Task Builder Impl."
    begin
        GlobalAgentTaskMessageBuilder.Initialize(From, MessageText);
        exit(this);
    end;

    /// <summary>
    /// Add a task message to the task.
    /// Only a single message can be added to the task.
    /// </summary>
    /// <param name="AgentTaskMessageBuilder">The agent task message builder.</param>
    /// <returns>This instance of the Agent Task Builder.</returns>
    [Scope('OnPrem')]
    procedure AddTaskMessage(var AgentTaskMessageBuilder: Codeunit "Agent Task Message Builder"): codeunit "Agent Task Builder Impl."
    begin
        GlobalAgentTaskMessageBuilder := AgentTaskMessageBuilder;
        MessageSet := true;
        exit(this);
    end;

    /// <summary>
    /// Get the agent task message builder.
    /// </summary>
    /// <returns>The agent task message builder.</returns>
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