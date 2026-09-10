// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

using System.AI;

codeunit 8358 "MCP Copilot Cap. Reg."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        MCPLearnMoreLbl: Label 'https://go.microsoft.com/fwlink/?linkid=2300000', Locked = true;

    /// <summary>
    /// Registers the MCP server capability so it appears on the Copilot &amp; agent capabilities page
    /// and is governed by the standard Activate/Deactivate flow.
    /// </summary>
    internal procedure RegisterMCPCapability()
    var
        CopilotCapability: Codeunit "Copilot Capability";
    begin
        if CopilotCapability.IsCapabilityRegistered(Enum::"Copilot Capability"::"MCP Server") then
            exit;

        CopilotCapability.RegisterCapability(
            Enum::"Copilot Capability"::"MCP Server",
            Enum::"Copilot Availability"::"Generally Available",
            Enum::"Copilot Billing Type"::"Not Billed",
            MCPLearnMoreLbl);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Copilot AI Capabilities", 'OnRegisterCopilotCapability', '', false, false)]
    local procedure OnRegisterCopilotCapability()
    begin
        RegisterMCPCapability();
    end;
}
