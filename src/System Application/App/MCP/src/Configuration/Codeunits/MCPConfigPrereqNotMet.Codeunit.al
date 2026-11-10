// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

using System.AI;

codeunit 8379 "MCP Config Prereq Not Met" implements "MCP Config Warning"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        ChatCapabilityDisabledWarningLbl: Label 'Chat Tools are enabled, but the Chat capability is not active.';
        ChatCapabilityDisabledFixLbl: Label 'Activate the Chat capability and approve its required privacy notices on the Copilot & agent capabilities page, or disable Chat Tools for this configuration.';

    procedure CheckForWarnings(ConfigId: Guid; var MCPConfigWarning: Record "MCP Config Warning"; var EntryNo: Integer)
    var
        MCPConfiguration: Record "MCP Configuration";
        CopilotCapability: Codeunit "Copilot Capability";
        CurrentModuleInfo: ModuleInfo;
    begin
        MCPConfiguration.GetBySystemId(ConfigId);
        if not MCPConfiguration.EnableChatTools then
            exit;

        NavApp.GetCurrentModuleInfo(CurrentModuleInfo);
        if CopilotCapability.IsCapabilityActive(Enum::"Copilot Capability"::Chat, CurrentModuleInfo.Id()) then
            exit;

        MCPConfigWarning.Init();
        MCPConfigWarning."Entry No." := EntryNo;
        MCPConfigWarning."Config Id" := ConfigId;
        MCPConfigWarning."Warning Type" := MCPConfigWarning."Warning Type"::"Prerequisite Not Met";
        MCPConfigWarning.Insert();
        EntryNo += 1;
    end;

    procedure WarningMessage(MCPConfigWarning: Record "MCP Config Warning"): Text
    begin
        exit(ChatCapabilityDisabledWarningLbl);
    end;

    procedure RecommendedAction(MCPConfigWarning: Record "MCP Config Warning"): Text
    begin
        exit(ChatCapabilityDisabledFixLbl);
    end;

    procedure ApplyRecommendedAction(var MCPConfigWarning: Record "MCP Config Warning")
    begin
        Page.Run(Page::"Copilot AI Capabilities");
    end;
}
