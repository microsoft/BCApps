// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Test.Agents;

using System.Agents;
using System.Environment.Configuration;

/// <summary>
/// Helper methods for Agent SDK testing.
/// </summary>
codeunit 133954 "Library Mock Agent"
{
    procedure GetOrCreateDefaultAgent(var AgentRecord: Record Agent; AgentUserName: Code[50]; DisplayName: Text[80]; Instructions: Text[2048]) AgentId: Guid
    var
        MockAgentSetup: Record "Mock Agent Setup";
        TempAgentAccessControl: Record "Agent Access Control" temporary;
        TempUserSettings: Record "User Settings" temporary;
        Agent: Codeunit Agent;
    begin
        AgentRecord.SetRange("Agent Metadata Provider", AgentRecord."Agent Metadata Provider"::"SDK Mock Agent");
        AgentRecord.SetFilter("User Name", AgentUserName);
        if AgentRecord.FindFirst() then
            exit(AgentRecord."User Security ID");

        AgentId := Agent.Create("Agent Metadata Provider"::"SDK Mock Agent", AgentUserName, DisplayName, TempAgentAccessControl);
        Agent.Activate(AgentId);

        MockAgentSetup."User Security ID" := AgentId;
        MockAgentSetup.Instructions := Instructions;
        MockAgentSetup.Insert();

        TempUserSettings."User Security ID" := AgentId;
        TempUserSettings."Locale ID" := 1033; // English - United States
        TempUserSettings."Language ID" := 1036; // French - France
        TempUserSettings."Time Zone" := 'Central Europe Standard Time';
        TempUserSettings.Insert();

        Agent.UpdateLocalizationSettings(AgentId, TempUserSettings);

        Commit(); // Commit for Access Control assignments to take effect.

        exit(AgentId);
    end;

    procedure DeleteAllAgents()
    var
        AgentRecord: Record Agent;
        MockAgentSetup: Record "Mock Agent Setup";
    begin
        AgentRecord.SetRange("Agent Metadata Provider", AgentRecord."Agent Metadata Provider"::"SDK Mock Agent");
        if AgentRecord.FindSet() then
            repeat
                if MockAgentSetup.Get(AgentRecord."User Security ID") then
                    MockAgentSetup.Delete();

                AgentRecord.Delete();
            until AgentRecord.Next() = 0;
    end;
}
