// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

using System.Agents;

codeunit 8377 "MCP Config Invalid Agent" implements "MCP Config Warning"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        MCPConfigAgentTool: Record "MCP Config Agent Tool";
        InvalidAgentWarningLbl: Label 'The configured agent is missing, inactive, or not published by a user or third party.';
        InvalidAgentFixLbl: Label 'Remove the agent from the MCP configuration.';

    procedure CheckForWarnings(ConfigId: Guid; var MCPConfigWarning: Record "MCP Config Warning"; var EntryNo: Integer)
    var
        Agent: Record Agent;
        MCPConfigImplementation: Codeunit "MCP Config Implementation";
    begin
        MCPConfigAgentTool.SetRange(ID, ConfigId);
        if MCPConfigAgentTool.FindSet() then
            repeat
                if not Agent.Get(MCPConfigAgentTool."Agent User Security ID") or not MCPConfigImplementation.IsAgentEligible(Agent) then begin
                    MCPConfigWarning."Entry No." := EntryNo;
                    MCPConfigWarning."Config Id" := ConfigId;
                    MCPConfigWarning."Tool Id" := MCPConfigAgentTool.SystemId;
                    MCPConfigWarning."Warning Type" := MCPConfigWarning."Warning Type"::"Invalid Agent";
                    MCPConfigWarning.Insert();
                    EntryNo += 1;
                end;
            until MCPConfigAgentTool.Next() = 0;
    end;

    procedure WarningMessage(MCPConfigWarning: Record "MCP Config Warning"): Text
    begin
        exit(InvalidAgentWarningLbl);
    end;

    procedure RecommendedAction(MCPConfigWarning: Record "MCP Config Warning"): Text
    begin
        exit(InvalidAgentFixLbl);
    end;

    procedure ApplyRecommendedAction(var MCPConfigWarning: Record "MCP Config Warning")
    begin
        if MCPConfigAgentTool.GetBySystemId(MCPConfigWarning."Tool Id") then
            MCPConfigAgentTool.Delete();
        MCPConfigWarning.Delete();
    end;
}
