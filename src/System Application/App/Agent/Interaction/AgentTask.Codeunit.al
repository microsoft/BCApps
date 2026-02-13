// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

using System.Environment;

codeunit 4303 "Agent Task"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    /// <summary>
    /// Check if a task exists for the given agent user and conversation
    /// </summary>
    /// <param name="AgentUserSecurityId">The user security ID of the agent.</param>
    /// <param name="ExternalId">The external ID to check.</param>
    /// <returns>True if task exists, false if not.</returns>
    procedure TaskExists(AgentUserSecurityId: Guid; ExternalId: Text): Boolean
    var
        AgentTaskImpl: Codeunit "Agent Task Impl.";
    begin
        FeatureAccessManagement.AgentTaskManagementPreviewEnabled(true);
        exit(AgentTaskImpl.TaskExists(AgentUserSecurityId, ExternalId));
    end;

    /// <summary>
    /// Get the task for the given agent user and external ID.
    /// </summary>
    /// <param name="AgentUserSecurityId">The agent user ID.</param>
    /// <param name="ExternalId">The external ID of the task.</param>
    /// <returns>A record with the given task.</returns>
    procedure GetTaskByExternalId(AgentUserSecurityId: Guid; ExternalId: Text): Record "Agent Task"
    var
        AgentTask: Record "Agent Task";
    begin
        FeatureAccessManagement.AgentTaskManagementPreviewEnabled(true);
        AgentTask.SetRange("Agent User Security ID", AgentUserSecurityId);
        AgentTask.SetRange("External ID", ExternalId);
        AgentTask.FindFirst();
        exit(AgentTask);
    end;

    /// <summary>
    /// Set the status of the task to ready if the task is in the state that it can be started again.
    /// The agent task will be be picked up for processing shortly after updating the status.
    /// </summary>
    /// <param name="AgentTask">The agent task to set to ready.</param>
    /// <returns>The agent task with the status set to ready.</returns>
    procedure SetStatusToReady(var AgentTask: Record "Agent Task")
    var
        AgentTaskImpl: Codeunit "Agent Task Impl.";
    begin
        FeatureAccessManagement.AgentTaskManagementPreviewEnabled(true);
        AgentTaskImpl.SetTaskStatusToReadyIfPossible(AgentTask);
    end;

    /// <summary>
    /// Checks if the task can be set to ready and started again.
    /// </summary>
    /// <param name="AgentTask">The agent task to check.</param>
    /// <returns>True if agent task can be set to ready, false otherwise</returns>
    procedure CanSetStatusToReady(AgentTask: Record "Agent Task"): Boolean
    var
        AgentTaskImpl: Codeunit "Agent Task Impl.";
    begin
        FeatureAccessManagement.AgentTaskManagementPreviewEnabled(true);
        exit(AgentTaskImpl.CanAgentTaskBeSetToReady(AgentTask));
    end;

    /// <summary>
    /// Stops the agent task.
    /// </summary>
    /// <param name="AgentTask">The agent task to stop.</param>
    /// <param name="UserConfirm">Whether to show a confirmation dialog to the user.</param>
    procedure StopTask(var AgentTask: Record "Agent Task"; UserConfirm: Boolean)
    var
        AgentTaskImpl: Codeunit "Agent Task Impl.";
        TaskStatus: Enum "Agent Task Status";
    begin
        FeatureAccessManagement.AgentTaskManagementPreviewEnabled(true);
        AgentTaskImpl.StopTask(AgentTask, TaskStatus::"Stopped by User", UserConfirm);
    end;

    /// <summary>
    /// Restarts the agent task by setting its status to ready.
    /// </summary>
    /// <param name="AgentTask">The agent task to restart.</param>
    /// <param name="UserConfirm">Whether to show a confirmation dialog to the user.</param>
    procedure RestartTask(var AgentTask: Record "Agent Task"; UserConfirm: Boolean)
    var
        AgentTaskImpl: Codeunit "Agent Task Impl.";
    begin
        FeatureAccessManagement.AgentTaskManagementPreviewEnabled(true);
        AgentTaskImpl.RestartTask(AgentTask, UserConfirm);
    end;

    /// <summary>
    /// Checks if the agent task is currently running.
    /// </summary>
    /// <param name="AgentTask">The agent task to check.</param>
    /// <returns>True if the task is running, false otherwise.</returns>
    procedure IsTaskRunning(var AgentTask: Record "Agent Task"): Boolean
    var
        AgentTaskImpl: Codeunit "Agent Task Impl.";
    begin
        FeatureAccessManagement.AgentTaskManagementPreviewEnabled(true);
        exit(AgentTaskImpl.IsTaskRunning(AgentTask));
    end;

    /// <summary>
    /// Checks if the agent task is completed.
    /// </summary>
    /// <param name="AgentTask">The agent task to check.</param>
    /// <returns>True if the task is completed, false otherwise.</returns>
    procedure IsTaskCompleted(var AgentTask: Record "Agent Task"): Boolean
    var
        AgentTaskImpl: Codeunit "Agent Task Impl.";
    begin
        FeatureAccessManagement.AgentTaskManagementPreviewEnabled(true);
        exit(AgentTaskImpl.IsTaskCompleted(AgentTask));
    end;

    /// <summary>
    /// Checks if the agent task is stopped (by user or system).
    /// </summary>
    /// <param name="AgentTask">The agent task to check.</param>
    /// <returns>True if the task is stopped, false otherwise.</returns>
    procedure IsTaskStopped(var AgentTask: Record "Agent Task"): Boolean
    var
        AgentTaskImpl: Codeunit "Agent Task Impl.";
    begin
        FeatureAccessManagement.AgentTaskManagementPreviewEnabled(true);
        exit(AgentTaskImpl.IsTaskStopped(AgentTask));
    end;

    var
        FeatureAccessManagement: Codeunit "Feature Access Management";

}