// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

codeunit 4312 "Agent Session"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    /// <summary>
    /// Checks if the current session is an agent session.
    /// </summary>
    /// <param name="ActiveAgentMetadataProvider">Returns the type of the active agent</param>
    /// <returns>
    /// True if the current session is an agent session, false otherwise.
    /// </returns>
    [Scope('OnPrem')]
    procedure IsAgentSession(var ActiveAgentMetadataProvider: Enum "Agent Metadata Provider"): Boolean
    var
        AgentUtilities: Codeunit "Agent Utilities";
    begin
        exit(AgentUtilities.IsAgentSession(ActiveAgentMetadataProvider));
    end;

    /// <summary>
    /// Get the agent task ID related to the current session, if any, -1 otherwise.
    /// </summary>
    /// <returns>The agent task ID, if any, -1 otherwise.</returns>
    [Scope('OnPrem')]
    procedure GetCurrentSessionAgentTaskId(): BigInteger
    var
        AgentUtilities: Codeunit "Agent Utilities";
    begin
        exit(AgentUtilities.GetCurrentSessionAgentTaskId());
    end;

    /// <summary>
    /// Returns true if the current session is an agent session for the specified agent type.
    /// </summary>
    /// <param name="AgentMetadataProvider">The agent type</param>
    /// <returns>True if the current session is an agent session for the specified agent type, false otherwise.</returns>
    procedure IsAgentSessionOfType(AgentMetadataProvider: Enum "Agent Metadata Provider"): Boolean
    var
        ActiveAgentMetadataProvider: Enum "Agent Metadata Provider";
    begin
        if not IsAgentSession(ActiveAgentMetadataProvider) then
            exit(false);

        if ActiveAgentMetadataProvider <> AgentMetadataProvider then
            exit(false);

        exit(true);
    end;

    /// <summary>
    /// Returns true if the current session is an agent session for the specified agent type and user ID.
    /// </summary>
    /// <param name="AgentMetadataProvider">The agent type</param>
    /// <param name="AgentUserId">The agent user ID</param>
    /// <returns>True if both match, false otherwise.</returns>
    procedure IsAgentSession(AgentMetadataProvider: Enum "Agent Metadata Provider"; AgentUserId: Guid): Boolean
    var
        ActiveAgentMetadataProvider: Enum "Agent Metadata Provider";
    begin
        if not IsAgentSession(ActiveAgentMetadataProvider) then
            exit(false);

        if ActiveAgentMetadataProvider <> AgentMetadataProvider then
            exit(false);

        if AgentUserId <> UserId() then
            exit(false);

        exit(true);
    end;
}