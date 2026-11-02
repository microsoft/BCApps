// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

codeunit 8377 "MCP Config Empty" implements "MCP Config Warning"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        EmptyConfigurationWarningLbl: Label 'This configuration does not expose any usable tools.';
        EmptyConfigurationFixLbl: Label 'Configure API tools, enable read-only discovery in Dynamic Tool Mode settings, enable Data Query Tools, or configure Agent Tools.';

    procedure CheckForWarnings(ConfigId: Guid; var MCPConfigWarning: Record "MCP Config Warning"; var EntryNo: Integer)
    var
        MCPConfiguration: Record "MCP Configuration";
    begin
        MCPConfiguration.GetBySystemId(ConfigId);
        if MCPConfiguration.EnableAlQueryTools then
            exit;

        if MCPConfiguration.EnableApiTools then begin
            if MCPConfiguration.EnableDynamicToolMode and MCPConfiguration.DiscoverReadOnlyObjects then
                exit;
            if HasAPITools(ConfigId) then
                exit;
        end;

        if MCPConfiguration.EnableAgents then
            if HasAgentTools(ConfigId) then
                exit;

        MCPConfigWarning.Init();
        MCPConfigWarning."Entry No." := EntryNo;
        MCPConfigWarning."Config Id" := ConfigId;
        MCPConfigWarning."Warning Type" := MCPConfigWarning."Warning Type"::"Empty Configuration";
        MCPConfigWarning.Insert();
        EntryNo += 1;
    end;

    procedure WarningMessage(MCPConfigWarning: Record "MCP Config Warning"): Text
    begin
        exit(EmptyConfigurationWarningLbl);
    end;

    procedure RecommendedAction(MCPConfigWarning: Record "MCP Config Warning"): Text
    begin
        exit(EmptyConfigurationFixLbl);
    end;

    procedure ApplyRecommendedAction(var MCPConfigWarning: Record "MCP Config Warning")
    var
        MCPConfiguration: Record "MCP Configuration";
    begin
        MCPConfiguration.GetBySystemId(MCPConfigWarning."Config Id");
        Page.Run(Page::"MCP Config Card", MCPConfiguration);
    end;

    local procedure HasAPITools(ConfigId: Guid): Boolean
    var
        MCPConfigurationTool: Record "MCP Configuration Tool";
    begin
        MCPConfigurationTool.SetRange(ID, ConfigId);
        exit(not MCPConfigurationTool.IsEmpty());
    end;

    local procedure HasAgentTools(ConfigId: Guid): Boolean
    var
        MCPConfigurationAgent: Record "MCP Configuration Agent";
    begin
        MCPConfigurationAgent.SetRange(ID, ConfigId);
        exit(not MCPConfigurationAgent.IsEmpty());
    end;
}
