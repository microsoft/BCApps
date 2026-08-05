// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

codeunit 8370 "MCP Dyn. Tool Mode Feature" implements "MCP Server Features"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure SetActive(ConfigId: Guid; Active: Boolean)
    var
        MCPConfigImplementation: Codeunit "MCP Config Implementation";
    begin
        MCPConfigImplementation.EnableDynamicToolMode(ConfigId, Active);
    end;

    procedure IsActive(ConfigId: Guid): Boolean
    var
        MCPConfiguration: Record "MCP Configuration";
    begin
        if not MCPConfiguration.GetBySystemId(ConfigId) then
            exit(false);
        exit(MCPConfiguration.EnableDynamicToolMode);
    end;

    procedure HasSettings(): Boolean
    begin
        exit(true);
    end;

    procedure OpenSettings(ConfigId: Guid)
    var
        ServerFeatureSettings: Page "MCP Server Feature Settings";
    begin
        ServerFeatureSettings.SetContext(ConfigId, "MCP Server Feature"::"Dynamic Tool Mode");
        if ServerFeatureSettings.RunModal() = Action::OK then
            ServerFeatureSettings.SaveChanges();
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
        SystemTools := MCPUtilities.GetSystemToolsInDynamicMode();
        foreach ToolName in SystemTools.Keys() do
            InsertTool(MCPSystemTool, CopyStr(ToolName, 1, MaxStrLen(MCPSystemTool."Tool Name")), CopyStr(SystemTools.Get(ToolName), 1, MaxStrLen(MCPSystemTool."Tool Description")));
    end;

    procedure TryGetParentFeature(var ParentFeature: Enum "MCP Server Feature"): Boolean
    begin
        // Dynamic Tool Mode is a sub-feature of API Tools.
        ParentFeature := "MCP Server Feature"::"API Tools";
        exit(true);
    end;

    local procedure InsertTool(var MCPSystemTool: Record "MCP System Tool"; ToolName: Text[100]; ToolDescription: Text[250])
    begin
        MCPSystemTool."Server Feature" := MCPSystemTool."Server Feature"::"Dynamic Tool Mode";
        MCPSystemTool."Tool Name" := ToolName;
        MCPSystemTool."Tool Description" := ToolDescription;
        MCPSystemTool.Insert();
    end;

    var
        DescriptionLbl: Label 'Exposes system tools that let clients search, describe, and invoke the API tools added to Available APIs without each tool being surfaced as its own tool. When inactive, every API tool in Available APIs is exposed directly to clients as its own MCP tool (Static Mode).';
}
