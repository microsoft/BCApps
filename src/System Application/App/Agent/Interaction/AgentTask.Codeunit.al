// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

#pragma warning disable AS0130, PTE0025 // The object conflicts with a platform codeunit which will be renamed.
codeunit 4303 "Agent Task"
#pragma warning restore AS0130, PTE0025
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
    /// Set the status of the task to ready if the task is in the state that it can be started again.
    /// The agent task will be be picked up for processing shortly after updating the status.
    /// </summary>
    /// <param name="AgentTask">The agent task to set to ready.</param>
    /// <returns>The agent task with the status set to ready.</returns>
    [Scope('OnPrem')]
    procedure SetStatusToReady(AgentTask: Record "Agent Task")
    var
        AgentTaskImpl: Codeunit "Agent Task Impl.";
    begin
        AgentTaskImpl.SetTaskStatusToReadyIfPossible(AgentTask);
    end;

    /// <summary>
    /// Checks if the task can be set to ready and started again.
    /// </summary>
    /// <param name="AgentTask">The agent task to check.</param>
    /// <returns>True if agent task can be set to ready, false otherwise</returns>
#pragma warning disable AS0022
    [Scope('OnPrem')]
    procedure CanSetStatusToReady(AgentTask: Record "Agent Task"): Boolean
#pragma warning restore AS0022
    var
        AgentTaskImpl: Codeunit "Agent Task Impl.";
    begin
        exit(AgentTaskImpl.CanAgentTaskBeSetToReady(AgentTask));
    end;
}