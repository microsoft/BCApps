// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item.Substitution;

using System.AI;
using System.Upgrade;

codeunit 7332 "Create Product Info. Upgrade"
{
    Access = Internal;
    Subtype = Upgrade;
    InherentPermissions = X;
    InherentEntitlements = X;

    trigger OnUpgradePerDatabase()
    begin
        UnregisterCapability();
    end;

    local procedure UnregisterCapability()
    var
        CopilotCapability: Codeunit "Copilot Capability";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(GetUnregisterCreateProductInfoCapabilityTag()) then
            exit;
        if CopilotCapability.IsCapabilityRegistered(Enum::"Copilot Capability"::"Create Product Information") then
            CopilotCapability.UnregisterCapability(Enum::"Copilot Capability"::"Create Product Information");

        UpgradeTag.SetUpgradeTag(GetUnregisterCreateProductInfoCapabilityTag());
    end;

    local procedure GetUnregisterCreateProductInfoCapabilityTag(): Code[250]
    begin
        exit('MS-659006-UnregisterCreateProductInfoCapability-20261112');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", OnGetPerDatabaseUpgradeTags, '', false, false)]
    local procedure RegisterPerDatabaseUpgradeTags(var PerDatabaseUpgradeTags: List of [Code[250]])
    begin
        PerDatabaseUpgradeTags.Add(GetUnregisterCreateProductInfoCapabilityTag());
    end;
}