// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

codeunit 4313 "Agent Session Impl."
{
    InherentEntitlements = X;
    InherentPermissions = X;

    internal procedure IsAgentSession(var ActiveAgentMetadataProvider: Enum "Agent Metadata Provider"): Boolean
    var
        AgentType: Integer;
        AgentALFunctions: DotNet AgentALFunctions;
    begin
        if not GuiAllowed() then
            exit(false);

        AgentType := AgentALFunctions.GetSessionAgentMetadataProviderType();
        if AgentType < 0 then
            exit(false);

        ActiveAgentMetadataProvider := "Agent Metadata Provider".FromInteger(AgentType);
        exit(true);
    end;

    internal procedure GetCurrentSessionAgentTaskId(): Integer
    var
        AgentALFunctions: DotNet AgentALFunctions;
    begin
        exit(AgentALFunctions.GetSessionAgentTaskId());
    end;

}