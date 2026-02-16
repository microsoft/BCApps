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

                MCPConfigurationTool."API Version" := MCPConfigImplementation.GetHighestAPIVersion(PageMetadata);
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

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", OnGetPerDatabaseUpgradeTags, '', false, false)]
    local procedure RegisterUpgradeTags(var PerDatabaseUpgradeTags: List of [Code[250]])
    begin
        PerDatabaseUpgradeTags.Add(GetMCPAPIToolVersionUpgradeTag());
        PerDatabaseUpgradeTags.Add(GetMCPSystemDefaultAsDefaultUpgradeTag());
    end;

    local procedure GetMCPAPIToolVersionUpgradeTag(): Text[250]
    begin
        exit('MS-619475-MCPAPIToolVersion-20260126');
    end;

    local procedure GetMCPSystemDefaultAsDefaultUpgradeTag(): Text[250]
    begin
        exit('MS-612454-MCPSystemDefaultAsDefault-20260216');
    end;
}