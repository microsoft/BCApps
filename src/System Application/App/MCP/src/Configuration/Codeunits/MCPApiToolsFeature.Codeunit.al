// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

codeunit 8369 "MCP API Tools Feature" implements "MCP Server Features"
{
    Access = Internal;

    procedure SetActive(ConfigId: Guid; Active: Boolean)
    var
        MCPConfigImplementation: Codeunit "MCP Config Implementation";
    begin
        MCPConfigImplementation.EnableAPITools(ConfigId, Active);
    end;

    procedure IsActive(ConfigId: Guid): Boolean
    var
        MCPConfigImplementation: Codeunit "MCP Config Implementation";
    begin
        exit(MCPConfigImplementation.IsAPIToolsEnabled(ConfigId));
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
        // API Tools exposes no system tools.
    end;

    procedure TryGetParentFeature(var ParentFeature: Enum "MCP Server Feature"): Boolean
    begin
        exit(false);
    end;

    var
        DescriptionLbl: Label 'Exposes the API Tools list on this configuration so the admin can curate which API pages and queries the MCP client can reach. Dynamic Tool Mode requires this feature to be enabled.';
}
