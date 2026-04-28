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
    /// Gets whether the current user has permissions to manage all agents in all companies.
    /// </summary>
    /// <returns>True if the user has permissions to manage all agents in all companies, false otherwise.</returns>
    procedure CurrentUserHasCanManageAllAgentsInAllCompaniesPermission(): Boolean
    begin
        exit(AgentSystemPermissionsImpl.CurrentUserHasCanManageAllAgentsInAllCompaniesPermission());
    end;

    /// <summary>
    /// Gets whether the current user has permissions to manage all agents.
    /// </summary>
    /// <returns>True if the user has permissions to manage all agents, false otherwise.</returns>
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

    /// <summary>
    /// Gets whether the current user has permissions to use a specific agent.
    /// </summary>
    /// <param name="AgentUserSecurityId">The user security id associated with the agent.</param>
    /// <returns>True if the user has use permissions for the specified agent, false otherwise.</returns>
    [Scope('OnPrem')]
    procedure CurrentUserCanUseAgent(AgentUserSecurityId: Guid): Boolean
    begin
        exit(AgentSystemPermissionsImpl.CurrentUserCanUseAgent(AgentUserSecurityId));
    end;

    /// <summary>
    /// Gets whether the current user has permissions to manage a specific agent.
    /// </summary>
    /// <param name="AgentUserSecurityId">The user security id associated with the agent.</param>
    /// <returns>True if the user has manage permissions for the specified agent, false otherwise.</returns>
    [Scope('OnPrem')]
    procedure CurrentUserCanManageAgent(AgentUserSecurityId: Guid): Boolean
    begin
        exit(AgentSystemPermissionsImpl.CurrentUserCanManageAgent(AgentUserSecurityId));
    end;

    var
        AgentSystemPermissionsImpl: Codeunit "Agent System Permissions Impl.";
}