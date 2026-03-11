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
    /// Gets whether the current user has permissions to manage all agents.
    /// </summary>
    /// <returns>True if the user has permissions to manage all agents, false otherwise.</returns>
    [Scope('OnPrem')]
    procedure CurrentUserHasCanManageAllAgentsPermission(): Boolean
    begin
        exit("Agent System Permissions Impl.".CurrentUserHasCanManageAllAgentsPermission());
    end;

    /// <summary>
    /// Gets whether the current user has permissions to troubleshoot the execution of agent tasks.
    /// </summary>
    /// <returns>True if the user has troubleshoot permissions, false otherwise.</returns>
    [Scope('OnPrem')]
    procedure CurrentUserHasTroubleshootAllAgents(): Boolean
    begin
        exit("Agent System Permissions Impl.".CurrentUserHasTroubleshootAllAgents());
    end;

    /// <summary>
    /// Gets whether the current user has permissions to create custom agents.
    /// </summary>
    /// <returns>True if the user has create permissions, false otherwise.</returns>
    [Scope('OnPrem')]
    procedure CurrentUserHasCanCreateCustomAgent(): Boolean
    begin
        exit("Agent System Permissions Impl.".CurrentUserHasCanCreateCustomAgent());
    end;

    var
        "Agent System Permissions Impl.": Codeunit "Agent System Permissions Impl.";
}