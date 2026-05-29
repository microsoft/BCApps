// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

codeunit 8368 "MCP AL Query Tools Feature" implements "MCP Feature Handler"
{
    Access = Internal;

    procedure SetActive(ConfigId: Guid; Active: Boolean)
    begin
        // PLATFORM-PENDING: persist activation once MCP Configuration exposes the AL Query Tools boolean:
        //   MCPConfiguration: Record "MCP Configuration";
        //   if not MCPConfiguration.GetBySystemId(ConfigId) then exit;
        //   MCPConfiguration."<Enable AL Query Tools field>" := Active;
        //   MCPConfiguration.Modify(true);
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

    var
        DescriptionLbl: Label 'Adds system tools that compile and run AL query code submitted by the client on demand, letting agents author ad-hoc joins and aggregates that no pre-defined API query covers. API queries and API pages added to Available APIs are exposed independently and are not affected by this feature.';
}
