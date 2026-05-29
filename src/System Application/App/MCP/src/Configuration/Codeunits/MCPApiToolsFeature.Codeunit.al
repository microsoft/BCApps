// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

codeunit 8369 "MCP API Tools Feature" implements "MCP Feature Handler"
{
    Access = Internal;

    procedure SetActive(ConfigId: Guid; Active: Boolean)
    begin
        // PLATFORM-PENDING: persist activation once MCP Configuration exposes the API Tools boolean:
        //   MCPConfiguration: Record "MCP Configuration";
        //   if not MCPConfiguration.GetBySystemId(ConfigId) then exit;
        //   MCPConfiguration."<Enable API Tools field>" := Active;
        //   MCPConfiguration.Modify(true);
    end;

    procedure IsActive(ConfigId: Guid): Boolean
    begin
        // PLATFORM-PENDING: read the API Tools boolean from MCP Configuration once it exists:
        //   if MCPConfiguration.GetBySystemId(ConfigId) then exit(MCPConfiguration."<Enable API Tools field>");
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

    var
        DescriptionLbl: Label 'Exposes the API Tools list on this configuration so the admin can curate which API pages and queries the MCP client can reach. Dynamic Tool Mode requires this feature to be enabled.';
}
