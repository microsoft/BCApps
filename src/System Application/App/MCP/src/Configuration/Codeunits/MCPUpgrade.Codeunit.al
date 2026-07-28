// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

using System.Reflection;
using System.Upgrade;

codeunit 8356 "MCP Upgrade"
{
    Subtype = Upgrade;
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnUpgradePerDatabase()
    begin
        UpgradeMCPAPIToolVersion();
        UpgradeMCPSystemDefaultAsDefault();
        EnableApiToolsOnExistingConfigurations();
        UpgradeRegisterMCPCapability();
    end;

    internal procedure UpgradeMCPAPIToolVersion()
    var
        MCPConfigurationTool: Record "MCP Configuration Tool";
        PageMetadata: Record "Page Metadata";
        MCPConfigImplementation: Codeunit "MCP Config Implementation";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasDatabaseUpgradeTag(GetMCPAPIToolVersionUpgradeTag()) then
            exit;

        MCPConfigurationTool.SetRange("API Version", '');
        if MCPConfigurationTool.FindSet() then
            repeat
                if not PageMetadata.Get(MCPConfigurationTool."Object ID") then
                    continue;

                if PageMetadata.PageType <> PageMetadata.PageType::API then
                    continue;

                MCPConfigurationTool."API Version" := MCPConfigImplementation.GetHighestAPIPageVersion(PageMetadata);
                MCPConfigurationTool.Modify();
            until MCPConfigurationTool.Next() = 0;

        UpgradeTag.SetUpgradeTag(GetMCPAPIToolVersionUpgradeTag());
    end;

    internal procedure UpgradeMCPSystemDefaultAsDefault()
    var
        MCPConfiguration: Record "MCP Configuration";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasDatabaseUpgradeTag(GetMCPSystemDefaultAsDefaultUpgradeTag()) then
            exit;

        if MCPConfiguration.Get('') then begin
            MCPConfiguration.Default := true;
            MCPConfiguration.Modify();
        end;

        UpgradeTag.SetUpgradeTag(GetMCPSystemDefaultAsDefaultUpgradeTag());
    end;

    internal procedure EnableApiToolsOnExistingConfigurations()
    var
        MCPConfiguration: Record "MCP Configuration";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasDatabaseUpgradeTag(GetMCPEnableApiToolsUpgradeTag()) then
            exit;

        MCPConfiguration.ModifyAll(EnableApiTools, true);

        UpgradeTag.SetUpgradeTag(GetMCPEnableApiToolsUpgradeTag());
    end;

    internal procedure UpgradeRegisterMCPCapability()
    var
        MCPCopilotCapReg: Codeunit "MCP Copilot Cap. Reg.";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasDatabaseUpgradeTag(GetRegisterMCPCapabilityUpgradeTag()) then
            exit;

        MCPCopilotCapReg.RegisterMCPCapability();

        UpgradeTag.SetUpgradeTag(GetRegisterMCPCapabilityUpgradeTag());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", OnGetPerDatabaseUpgradeTags, '', false, false)]
    local procedure RegisterUpgradeTags(var PerDatabaseUpgradeTags: List of [Code[250]])
    begin
        PerDatabaseUpgradeTags.Add(GetMCPAPIToolVersionUpgradeTag());
        PerDatabaseUpgradeTags.Add(GetMCPSystemDefaultAsDefaultUpgradeTag());
        PerDatabaseUpgradeTags.Add(GetMCPEnableApiToolsUpgradeTag());
        PerDatabaseUpgradeTags.Add(GetRegisterMCPCapabilityUpgradeTag());
    end;

    local procedure GetMCPAPIToolVersionUpgradeTag(): Text[250]
    begin
        exit('MS-619475-MCPAPIToolVersion-20260126');
    end;

    local procedure GetMCPSystemDefaultAsDefaultUpgradeTag(): Text[250]
    begin
        exit('MS-612454-MCPSystemDefaultAsDefault-20260216');
    end;

    local procedure GetMCPEnableApiToolsUpgradeTag(): Text[250]
    begin
        exit('MS-631012-MCPEnableApiTools-20260603');
    end;

    local procedure GetRegisterMCPCapabilityUpgradeTag(): Text[250]
    begin
        exit('MS-641612-RegisterMCPCapability-20260612');
    end;
}