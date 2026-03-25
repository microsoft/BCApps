// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

codeunit 4317 "Agent System Permissions"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    /// <summary>
    /// Gets whether the current user has permissions to see all consumption data.
    /// </summary>
    /// <returns>True if the user has permissions to see all consumption data, false otherwise.</returns>
    procedure CurrentUserCanSeeConsumptionData(): Boolean
    begin
        exit(AgentSystemPermissionsImpl.CurrentUserCanSeeConsumptionData());
    end;

    /// <summary>
    /// Gets whether the current user has permissions to manage all agents.
    /// </summary>
    /// <returns>True if the user has permissions to manage all agents, false otherwise.</returns>
    [Scope('OnPrem')]
    procedure CurrentUserHasCanManageAllAgentsPermission(): Boolean
    begin
        exit(AgentSystemPermissionsImpl.CurrentUserHasCanManageAllAgentsPermission());
    end;

    /// <summary>
    /// Gets whether the current user has permissions to troubleshoot the execution of agent tasks.
    /// </summary>
    /// <returns>True if the user has troubleshoot permissions, false otherwise.</returns>
    [Scope('OnPrem')]
    procedure CurrentUserHasTroubleshootAllAgents(): Boolean
    begin
        exit(AgentSystemPermissionsImpl.CurrentUserHasTroubleshootAllAgents());
    end;

    /// <summary>
    /// Gets whether the current user has permissions to create custom agents.
    /// </summary>
    /// <returns>True if the user has create permissions, false otherwise.</returns>
    [Scope('OnPrem')]
    procedure CurrentUserHasCanCreateCustomAgent(): Boolean
    begin
        exit(AgentSystemPermissionsImpl.CurrentUserHasCanCreateCustomAgent());
    end;

    var
        AgentSystemPermissionsImpl: Codeunit "Agent System Permissions Impl.";
}