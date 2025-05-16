// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

/// <summary>
/// This codeunit is used to create an agent task message.
/// </summary>
codeunit 4316 "Agent Task Message Builder"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        AgentTaskMsgBuilderImpl: Codeunit "Agent Task Msg. Builder Impl.";

    /// <summary>
    /// Check if a task exists for the given agent user and conversation
    /// </summary>
    /// <param name="AgentUserSecurityID">The user security ID of the agent.</param>
    /// <param name="ConversationId">The conversation ID to check.</param>
    /// <returns>This instance of the Agent Task Message Builder.</returns>
    [Scope('OnPrem')]
    procedure Initialize(From: Text[250]; MessageText: Text): codeunit "Agent Task Message Builder"
    begin
        AgentTaskMsgBuilderImpl.Initialize(From, MessageText);
        exit(this);
    end;

    /// <summary>
    /// Set the external ID of the task.    
    /// </summary>
    /// <param name="RequiresReview">Specifies if the user needs to review and approve message before agent starts processing the task. The default value is true.</param>
    /// <returns>This instance of the Agent Task Message Builder.</returns>
    [Scope('OnPrem')]
    procedure SetRequiresReview(RequiresReview: Boolean): codeunit "Agent Task Message Builder"
    begin
        AgentTaskMsgBuilderImpl.SetRequiresReview(RequiresReview);
        exit(this);
    end;

    /// <summary>
    /// Set the external ID of the task.
    /// </summary>
    /// <param name="ExternalId">The external ID of the task. This field is used to connect to external systems, like Message ID for emails.</param>
    /// <returns>This instance of the Agent Task Message Builder.</returns>
    [Scope('OnPrem')]
    procedure SetMessageExternalID(ExternalId: Text[2048]): codeunit "Agent Task Message Builder"
    begin
        AgentTaskMsgBuilderImpl.SetMessageExternalID(ExternalId);
        exit(this);
    end;

    /// <summary>
    /// Set the message text of the task.
    /// </summary>
    /// <param name="ParentAgentTask">The agent task to set the message text to.</param>
    /// <returns>This instance of the Agent Task Message Builder.</returns>
    [Scope('OnPrem')]
    procedure SetAgentTask(ParentAgentTask: Record "Agent Task"): codeunit "Agent Task Message Builder"
    begin
        AgentTaskMsgBuilderImpl.SetAgentTask(ParentAgentTask);
        exit(this);
    end;

    /// <summary>
    /// Sets if the task should be started after the message is created. 
    /// Default value is true.
    /// </summary>
    /// <param name="StartAgentTask">If the task should be started after the message is created.</param>
    /// <returns>This instance of the Agent Task Message Builder.</returns>
    procedure SetStartAgentTask(StartAgentTask: Boolean): codeunit "Agent Task Message Builder"
    begin
        AgentTaskMsgBuilderImpl.SetStartAgentTask(StartAgentTask);
        exit(this);
    end;

    /// <summary>
    /// Set the message text of the task.
    /// </summary>
    /// <param name="ParentAgentTask">The agent task to set the message text to.</param>
    /// <returns>This instance of the Agent Task Message Builder.</returns>
    [Scope('OnPrem')]
    procedure SetAgentTask(ParentAgentTaskID: BigInteger): codeunit "Agent Task Message Builder"
    begin
        AgentTaskMsgBuilderImpl.SetAgentTask(ParentAgentTaskID);
        exit(this);
    end;

    /// <summary>
    /// Creates the task message.
    /// </summary>
    /// <returns>
    /// The created task message.
    /// </returns>
    [Scope('OnPrem')]
    procedure Create(): Record "Agent Task Message"
    begin
        exit(AgentTaskMsgBuilderImpl.Create());
    end;

    /// <summary>
    /// Get the agent task message.
    /// </summary>
    /// <returns>
    /// The agent task message that was created.
    /// </returns>
    procedure GetAgentTaskMessage(): Record "Agent Task Message"
    begin
        AgentTaskMsgBuilderImpl.Create();
        exit(AgentTaskMsgBuilderImpl.GetAgentTaskMessage());
    end;

    /// <summary>
    /// Attach a file to the task message.
    /// The file will be attached when the message is created.
    /// It is possible to attach multiple files to the message.
    /// </summary>
    /// <param name="FileName">The name of the file to attach.</param>
    /// <param name="FileMIMEType">The MIME type of the file to attach.</param>
    /// <param name="InStream">The stream of the file to attach.</param>
    /// <returns>This instance of the Agent Task Message Builder.</returns>
    [Scope('OnPrem')]
    procedure AddAttachment(FileName: Text[250]; FileMIMEType: Text[100]; InStream: InStream): codeunit "Agent Task Message Builder"
    begin
        AgentTaskMsgBuilderImpl.AddAttachment(FileName, FileMIMEType, InStream);
        exit(this);
    end;
}