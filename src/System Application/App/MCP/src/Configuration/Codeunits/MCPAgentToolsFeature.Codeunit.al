// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

codeunit 8376 "MCP Agent Tools Feature" implements "MCP Server Features"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure SetActive(ConfigId: Guid; Active: Boolean)
    var
        MCPConfigImplementation: Codeunit "MCP Config Implementation";
    begin
        MCPConfigImplementation.EnableAgents(ConfigId, Active);
    end;

    procedure IsActive(ConfigId: Guid): Boolean
    var
        MCPConfigImplementation: Codeunit "MCP Config Implementation";
    begin
        exit(MCPConfigImplementation.IsAgentsEnabled(ConfigId));
    end;

    procedure HasSettings(): Boolean
    begin
        exit(false);
    end;

    procedure OpenSettings(ConfigId: Guid)
    begin
    end;

    procedure Description(): Text[500]
    begin
        exit(DescriptionLbl);
    end;

    procedure LoadSystemTools(var MCPSystemTool: Record "MCP System Tool")
    begin
        InsertTool(MCPSystemTool, 'bc_agents_list', ListAgentsDescriptionLbl);
        InsertTool(MCPSystemTool, 'bc_agents_invoke', InvokeAgentDescriptionLbl);
    end;

    procedure TryGetParentFeature(var ParentFeature: Enum "MCP Server Feature"): Boolean
    begin
        exit(false);
    end;

    local procedure InsertTool(var MCPSystemTool: Record "MCP System Tool"; ToolName: Text[100]; ToolDescription: Text[250])
    begin
        MCPSystemTool."Server Feature" := MCPSystemTool."Server Feature"::"Agent Tools";
        MCPSystemTool."Tool Name" := ToolName;
        MCPSystemTool."Tool Description" := ToolDescription;
        MCPSystemTool.Insert();
    end;

    var
        DescriptionLbl: Label 'Exposes tools to list configured Business Central agents and the reserved agent invocation tool.';
        ListAgentsDescriptionLbl: Label 'Lists Business Central specialized agents. Invoke or ask questions to the agent using the bc_agents_invoke tool.';
        InvokeAgentDescriptionLbl: Label 'Reserved for invoking a Business Central agent. This tool is not implemented and always returns an error without creating a task.';
}
