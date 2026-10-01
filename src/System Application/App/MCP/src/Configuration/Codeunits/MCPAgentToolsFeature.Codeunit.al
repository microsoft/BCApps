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
    SingleInstance = true;

    procedure SetActive(ConfigId: Guid; Active: Boolean)
    begin
        if ActiveByConfig.ContainsKey(ConfigId) then
            ActiveByConfig.Set(ConfigId, Active)
        else
            ActiveByConfig.Add(ConfigId, Active);
    end;

    procedure IsActive(ConfigId: Guid): Boolean
    var
        Active: Boolean;
    begin
        if not ActiveByConfig.Get(ConfigId, Active) then
            exit(false);

        exit(Active);
    end;

    internal procedure ResetActiveState(ConfigId: Guid)
    begin
        ActiveByConfig.Remove(ConfigId);
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
        InsertTool(MCPSystemTool, 'lookup_agents', LookupAgentsDescriptionLbl);
        InsertTool(MCPSystemTool, 'invoke_agent', InvokeAgentDescriptionLbl);
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
        ActiveByConfig: Dictionary of [Guid, Boolean];
        DescriptionLbl: Label 'Exposes tools to discover and invoke agents selected in Available Agents. Agent invocation is in preview and may incur billable AI consumption.';
        LookupAgentsDescriptionLbl: Label 'Discovers agents selected in Available Agents.';
        InvokeAgentDescriptionLbl: Label 'Invokes an agent selected in Available Agents and may incur billable AI consumption while in preview.';
}
