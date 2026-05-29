// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

codeunit 8368 "MCP AL Query Tools Feature" implements "MCP Server Features"
{
    Access = Internal;

    procedure SetActive(ConfigId: Guid; Active: Boolean)
    var
        MCPConfigImplementation: Codeunit "MCP Config Implementation";
    begin
        MCPConfigImplementation.EnableALQueryTools(ConfigId, Active);
    end;

    procedure IsActive(ConfigId: Guid): Boolean
    begin
        // PLATFORM-PENDING: read the AL Query Tools boolean from MCP Configuration once it exists:
        //   if MCPConfiguration.GetBySystemId(ConfigId) then exit(MCPConfiguration."<Enable AL Query Tools field>");
        exit(false);
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
        // MOCK: hardcoded preview of the AL Query system tools. Replace with a real MCP Utilities
        // call (mirroring GetSystemToolsInDynamicMode) once the platform exposes the catalog.
        InsertTool(MCPSystemTool, 'compile_al_query', 'Compile an AL query string and return diagnostics.');
        InsertTool(MCPSystemTool, 'run_al_query', 'Execute a previously compiled AL query and return the result set.');
    end;

    local procedure InsertTool(var MCPSystemTool: Record "MCP System Tool"; ToolName: Text[100]; ToolDescription: Text[250])
    begin
        MCPSystemTool."Server Feature" := MCPSystemTool."Server Feature"::"AL Query Tools";
        MCPSystemTool."Tool Name" := ToolName;
        MCPSystemTool."Tool Description" := ToolDescription;
        MCPSystemTool.Insert();
    end;

    var
        DescriptionLbl: Label 'Adds system tools that compile and run AL query code submitted by the client on demand, letting agents author ad-hoc joins and aggregates that no pre-defined API query covers. API queries and API pages added to Available APIs are exposed independently and are not affected by this feature.';
}
