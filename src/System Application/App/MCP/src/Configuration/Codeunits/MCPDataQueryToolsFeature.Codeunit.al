// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

codeunit 8368 "MCP Data Query Tools Feature" implements "MCP Server Features"
{
    Access = Internal;

    procedure SetActive(ConfigId: Guid; Active: Boolean)
    var
        MCPConfigImplementation: Codeunit "MCP Config Implementation";
    begin
        MCPConfigImplementation.EnableDataQueryTools(ConfigId, Active);
    end;

    procedure IsActive(ConfigId: Guid): Boolean
    var
        MCPConfigImplementation: Codeunit "MCP Config Implementation";
    begin
        exit(MCPConfigImplementation.IsDataQueryToolsEnabled(ConfigId));
    end;

    procedure HasSettings(): Boolean
    begin
        exit(false);
    end;

    procedure OpenSettings(ConfigId: Guid)
    begin
        // No configurable settings.
    end;

    procedure Description(): Text[500]
    begin
        exit(DescriptionLbl);
    end;

    procedure LoadSystemTools(var MCPSystemTool: Record "MCP System Tool")
    begin
        // MOCK (PLATFORM-PENDING, BC-Platform PR #44811): hardcoded preview of the Data Query Tools system
        // tools. When #44811 ships "MCP Utilities".GetSystemToolsInDataQuery(), delete this procedure and
        // uncomment the productionized version below (mirrors the Dynamic Tool Mode handler).
        InsertTool(MCPSystemTool, 'compile_al_query', 'Compile an AL query string and return diagnostics.');
        InsertTool(MCPSystemTool, 'run_al_query', 'Execute a previously compiled AL query and return the result set.');
    end;

    // PLATFORM-PENDING (BC-Platform PR #44811): productionized replacement for LoadSystemTools above.
    // procedure LoadSystemTools(var MCPSystemTool: Record "MCP System Tool")
    // var
    //     MCPUtilities: Codeunit "MCP Utilities";
    //     SystemTools: Dictionary of [Text, Text];
    //     ToolName: Text;
    // begin
    //     SystemTools := MCPUtilities.GetSystemToolsInDataQuery();
    //     foreach ToolName in SystemTools.Keys() do
    //         InsertTool(MCPSystemTool, CopyStr(ToolName, 1, MaxStrLen(MCPSystemTool."Tool Name")), CopyStr(SystemTools.Get(ToolName), 1, MaxStrLen(MCPSystemTool."Tool Description")));
    // end;

    procedure TryGetParentFeature(var ParentFeature: Enum "MCP Server Feature"): Boolean
    begin
        exit(false);
    end;

    local procedure InsertTool(var MCPSystemTool: Record "MCP System Tool"; ToolName: Text[100]; ToolDescription: Text[250])
    begin
        MCPSystemTool."Server Feature" := MCPSystemTool."Server Feature"::"Data Query Tools";
        MCPSystemTool."Tool Name" := ToolName;
        MCPSystemTool."Tool Description" := ToolDescription;
        MCPSystemTool.Insert();
    end;

    var
        DescriptionLbl: Label 'Adds system tools that compile and run data query code submitted by the client on demand, letting agents author ad-hoc joins and aggregates that no pre-defined API query covers. API queries and API pages added to Available APIs are exposed independently and are not affected by this feature.';
}
