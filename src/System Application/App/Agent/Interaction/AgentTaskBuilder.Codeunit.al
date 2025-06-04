// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

/// <summary>
/// This codeunit is used to create an agent task.
/// </summary>
codeunit 4315 "Agent Task Builder"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        AgentTaskBuilderImpl: Codeunit "Agent Task Builder Impl.";

    /// <summary>
    /// Initialize the agent task builder with the mandatory parameters.
    /// </summary>
    /// <param name="AgentUserSecurityID">The user security ID of the agent.</param>
    /// <param name="ConversationId">The conversation ID to check.</param>
    /// <returns>This instance of the Agent Task Builder.</returns>
    [Scope('OnPrem')]
    procedure Initialize(NewAgentUserSecurityId: Guid; NewTaskTitle: Text[150]): codeunit "Agent Task Builder"
    begin
        AgentTaskBuilderImpl.Initialize(NewAgentUserSecurityId, NewTaskTitle);
        exit(this);
    end;

    /// <summary>
    /// Create a new task for the agent.
    /// </summary>
    /// <returns>
    /// Agent task that was created
    /// </returns>
    /// <remarks>
    /// The builder keeps the state, do not reuse the same instance of the builder to create multiple tasks. 
    /// </remarks>
    [Scope('OnPrem')]
    procedure Create(): Record "Agent Task"
    begin
        exit(AgentTaskBuilderImpl.Create(true));
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
    /// <remarks>
    /// The builder keeps the state, do not reuse the same instance of the builder to create multiple tasks. 
    /// </remarks>
    [Scope('OnPrem')]
    procedure Create(SetTaskStatusToReady: Boolean): Record "Agent Task"
    begin
        exit(AgentTaskBuilderImpl.Create(SetTaskStatusToReady));
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
        exit(AgentTaskBuilderImpl.GetAgentTaskMessageCreated());
    end;

    /// <summary>
    /// Set the external ID of the task.
    /// </summary>
    /// <param name="ExternalId">The external ID of the task. This field is used to connect to external systems, like Message ID for emails.</param>
    /// <returns>This instance of the Agent Task Builder.</returns>
    [Scope('OnPrem')]
    procedure SetExternalId(ExternalId: Text[2048]): codeunit "Agent Task Builder"
    begin
        AgentTaskBuilderImpl.SetExternalId(ExternalId);
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
    procedure AddTaskMessage(From: Text[250]; MessageText: Text): codeunit "Agent Task Builder"
    begin
        AgentTaskBuilderImpl.AddTaskMessage(From, MessageText);
        exit(this);
    end;

    /// <summary>
    /// Add a task message to the task.
    /// Only a single message can be added to the task.
    /// </summary>
    /// <param name="AgentTaskMessageBuilder">The agent task message builder.</param>
    /// <returns>This instance of the Agent Task Builder.</returns>
    [Scope('OnPrem')]
    procedure AddTaskMessage(var AgentTaskMessageBuilder: Codeunit "Agent Task Message Builder"): codeunit "Agent Task Builder"
    begin
        AgentTaskBuilderImpl.AddTaskMessage(AgentTaskMessageBuilder);
        exit(this);
    end;

    /// <summary>
    /// Get the agent task message builder.
    /// </summary>
    /// <returns>The agent task message builder.</returns>
    [Scope('OnPrem')]
    procedure GetTaskMessageBuilder(): Codeunit "Agent Task Message Builder"
    begin
        exit(AgentTaskBuilderImpl.GetTaskMessageBuilder());
    end;

    /// <summary>
    /// Check if a task exists for the given agent user and conversation
    /// </summary>
    /// <param name="AgentUserSecurityID">The user security ID of the agent.</param>
    /// <param name="ConversationId">The conversation ID to check.</param>
    /// <returns>True if task exists, false if not.</returns>
    [Scope('OnPrem')]
    procedure TaskExists(AgentUserSecurityId: Guid; ConversationId: Text): Boolean
    var
        AgentTaskImpl: Codeunit "Agent Task Impl.";
    begin
        exit(AgentTaskImpl.TaskExists(AgentUserSecurityId, ConversationId));
    end;
}