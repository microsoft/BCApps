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
    procedure GetCurrentSessionAgentTaskId(): BigInteger
    var
        AgentUtilities: Codeunit "Agent Utilities";
    begin
        exit(AgentUtilities.GetCurrentSessionAgentTaskId());
    end;
}