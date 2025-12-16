// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

codeunit 8353 "MCP Config Missing Object" implements "MCP Config Warning"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        MCPConfigurationTool: Record "MCP Configuration Tool";
        MissingObjectWarningLbl: Label '%1 %2 referenced by this configuration no longer exists in the system.', Comment = '%1=Object type, %2=Object Id';
        MissingObjectFixLbl: Label 'Remove this tool from the configuration.';

    procedure WarningMessage(MCPConfigWarning: Record "MCP Config Warning"): Text
    begin
        if MCPConfigurationTool.GetBySystemId(MCPConfigWarning."Tool Id") then
            exit(StrSubstNo(MissingObjectWarningLbl, MCPConfigurationTool."Object Type", MCPConfigurationTool."Object Id"));
    end;

    procedure RecommendedAction(MCPConfigWarning: Record "MCP Config Warning"): Text
    begin
        exit(MissingObjectFixLbl);
    end;

    procedure ApplyRecommendedAction(var MCPConfigWarning: Record "MCP Config Warning")
    begin
        if MCPConfigurationTool.GetBySystemId(MCPConfigWarning."Tool Id") then
            MCPConfigurationTool.Delete();
        MCPConfigWarning.Delete();
    end;
}
