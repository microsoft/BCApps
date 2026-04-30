// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

codeunit 8355 "MCP Config Missing Read Tool" implements "MCP Config Warning"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        MCPConfigurationTool: Record "MCP Configuration Tool";
        MissingReadToolWarningLbl: Label '%1 (%2) has Allow Modify enabled but Allow Read is disabled.', Comment = '%1=Object type, %2=Object Id';
        MissingReadToolFixLbl: Label 'Enable Allow Read for this tool.';

    procedure CheckForWarnings(ConfigId: Guid; var TempMCPConfigWarning: Record "MCP Config Warning"; var EntryNo: Integer)
    begin
        MCPConfigurationTool.SetRange(ID, ConfigId);
        MCPConfigurationTool.SetRange("Allow Modify", true);
        MCPConfigurationTool.SetRange("Allow Read", false);
        if MCPConfigurationTool.FindSet() then
            repeat
                TempMCPConfigWarning."Entry No." := EntryNo;
                TempMCPConfigWarning."Config Id" := ConfigId;
                TempMCPConfigWarning."Tool Id" := MCPConfigurationTool.SystemId;
                TempMCPConfigWarning."Warning Type" := TempMCPConfigWarning."Warning Type"::"Missing Read Tool";
                TempMCPConfigWarning.Insert();
                EntryNo += 1;
            until MCPConfigurationTool.Next() = 0;
    end;

    procedure WarningMessage(TempMCPConfigWarning: Record "MCP Config Warning"): Text
    begin
        if MCPConfigurationTool.GetBySystemId(TempMCPConfigWarning."Tool Id") then
            exit(StrSubstNo(MissingReadToolWarningLbl, MCPConfigurationTool."Object Type", MCPConfigurationTool."Object ID"));
    end;

    procedure RecommendedAction(TempMCPConfigWarning: Record "MCP Config Warning"): Text
    begin
        exit(MissingReadToolFixLbl);
    end;

    procedure ApplyRecommendedAction(var TempMCPConfigWarning: Record "MCP Config Warning")
    begin
        if MCPConfigurationTool.GetBySystemId(TempMCPConfigWarning."Tool Id") then begin
            MCPConfigurationTool."Allow Read" := true;
            MCPConfigurationTool.Modify();
        end;
        TempMCPConfigWarning.Delete();
    end;
}
