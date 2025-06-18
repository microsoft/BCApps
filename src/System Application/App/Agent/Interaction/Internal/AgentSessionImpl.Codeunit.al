// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

codeunit 4313 "Agent Session Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure IsAgentSession(var ActiveAgentMetadataProvider: Enum "Agent Metadata Provider"): Boolean
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

    procedure BlockPageFromBeingOpenedByAgent()
    var
        AgentMetadataProvider: Enum "Agent Metadata Provider";
        ThisPageCannotBeOpenedByAnAgentErr: Label 'This page cannot be opened by an agent.', Locked = true;
    begin
        if IsAgentSession(AgentMetadataProvider) then
            Error(ThisPageCannotBeOpenedByAnAgentErr);
    end;

    procedure GetCurrentSessionAgentTaskId(): Integer
    var
        AgentALFunctions: DotNet AgentALFunctions;
    begin
        exit(AgentALFunctions.GetSessionAgentTaskId());
    end;
}