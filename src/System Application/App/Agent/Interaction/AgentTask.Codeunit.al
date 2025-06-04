// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

codeunit 4303 "Agent Task"
{
    InherentEntitlements = X;
    InherentPermissions = X;

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

    /// <summary>
    /// Create a new task message for the given agent user and conversation.
    /// If task does not exist, it will be created.
    /// </summary>
    /// <param name="From">Specifies from address.</param>
    /// <param name="MessageText">The message text for the task.</param>
    /// <param name="CurrentAgentTask">Current Agent Task to which the message will be added.</param>
    [Scope('OnPrem')]
    procedure CreateTaskMessage(From: Text[250]; MessageText: Text; ExternalMessageId: Text[2048]; var CurrentAgentTask: Record "Agent Task")
    var
        AgentTaskImpl: Codeunit "Agent Task Impl.";
    begin
        AgentTaskImpl.CreateTaskMessage(From, MessageText, ExternalMessageId, CurrentAgentTask);
    end;

    /// <summary>
    /// Create a new task  for the given agent user. No message is added to the task.
    /// </summary>
    /// <param name="AgentSecurityID">The security ID of the agent to create the task for.</param>
    /// <param name="TaskTitle">The title of the task.</param>
    /// <param name="ExternalId">The external ID of the task. This field is used to connect to external systems, like Message ID for emails.</param>
    /// <param name="NewAgentTask">The new agent task record that was created.</param>
    [Scope('OnPrem')]
    procedure CreateTaskWithoutMessage(AgentSecurityID: Guid; TaskTitle: Text[150]; ExternalId: Text[2048]; var NewAgentTask: Record "Agent Task")
    var
        AgentTaskImpl: Codeunit "Agent Task Impl.";
    begin
        AgentTaskImpl.CreateTask(AgentSecurityID, TaskTitle, ExternalId, NewAgentTask);
    end;
}