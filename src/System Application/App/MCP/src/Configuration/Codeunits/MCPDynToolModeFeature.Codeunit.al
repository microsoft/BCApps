// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

codeunit 8370 "MCP Dyn. Tool Mode Feature" implements "MCP Feature Handler"
{
    Access = Internal;

    procedure SetActive(ConfigId: Guid; Active: Boolean)
    var
        MCPConfiguration: Record "MCP Configuration";
        APIToolsHandler: Interface "MCP Feature Handler";
    begin
        if Active then begin
            APIToolsHandler := "MCP Server Feature"::"API Tools";
            if not APIToolsHandler.IsActive(ConfigId) then
                Error(APIToolsRequiredForDynamicErr);
        end;
        if not MCPConfiguration.GetBySystemId(ConfigId) then
            exit;
        MCPConfiguration.EnableDynamicToolMode := Active;
        if not Active then
            MCPConfiguration.DiscoverReadOnlyObjects := false;
        MCPConfiguration.Modify(true);
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

    var
        APIToolsRequiredForDynamicErr: Label 'API Tools must be enabled before Dynamic Tool Mode can be enabled.';
        DescriptionLbl: Label 'Exposes system tools that let clients search, describe, and invoke the API tools added to Available APIs without each tool being surfaced as its own tool. When inactive, every API tool in Available APIs is exposed directly to clients as its own MCP tool (Static Mode).';
}
