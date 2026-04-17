// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

using System.AI;
using System.Environment;
using System.Upgrade;

/// <summary>
/// Registers the Copilot capability used by Performance Center and upgrade tags.
/// </summary>
codeunit 5486 "Perf. Center Installer"
{
    Subtype = Install;
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnInstallAppPerDatabase()
    begin
        RegisterCapability();
        SetUpgradeTags();
    end;

    local procedure RegisterCapability()
    var
        CopilotCapability: Codeunit "Copilot Capability";
        EnvironmentInformation: Codeunit "Environment Information";
        LearnMoreUrlTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2103698', Locked = true;
    begin
        if not EnvironmentInformation.IsSaaSInfrastructure() then
            exit;
        if CopilotCapability.IsCapabilityRegistered(Enum::"Copilot Capability"::"Performance Center") then
            exit;
        CopilotCapability.RegisterCapability(
            Enum::"Copilot Capability"::"Performance Center",
            Enum::"Copilot Availability"::Preview,
            Enum::"Copilot Billing Type"::"Not Billed",
            LearnMoreUrlTxt);
    end;

    local procedure SetUpgradeTags()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag(GetInstalledTag()) then
            UpgradeTag.SetUpgradeTag(GetInstalledTag());
    end;

    local procedure GetInstalledTag(): Code[250]
    begin
        exit('MS-PerfCenter-Installed-20260417');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", OnGetPerDatabaseUpgradeTags, '', false, false)]
    local procedure RegisterPerDatabaseTags(var PerDatabaseUpgradeTags: List of [Code[250]])
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag(GetInstalledTag()) then
            PerDatabaseUpgradeTags.Add(GetInstalledTag());
    end;

    [EventSubscriber(ObjectType::Page, Page::"Copilot AI Capabilities", 'OnRegisterCopilotCapability', '', false, false)]
    local procedure OnRegisterCopilotCapability()
    begin
        RegisterCapability();
    end;
}
