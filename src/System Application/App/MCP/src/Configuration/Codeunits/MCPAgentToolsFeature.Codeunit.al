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
    var
        MCPUtilities: Codeunit "MCP Utilities";
        SystemTools: Dictionary of [Text, Text];
        ToolName: Text;
    begin
        SystemTools := MCPUtilities.GetSystemToolsInAgents();
        foreach ToolName in SystemTools.Keys() do
            InsertTool(MCPSystemTool, CopyStr(ToolName, 1, MaxStrLen(MCPSystemTool."Tool Name")), CopyStr(SystemTools.Get(ToolName), 1, MaxStrLen(MCPSystemTool."Tool Description")));
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
        DescriptionLbl: Label 'Exposes system tools that let clients discover and invoke the Business Central agents added to Available Agents.';
}
