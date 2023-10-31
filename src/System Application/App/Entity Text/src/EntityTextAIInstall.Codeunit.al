// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Text;

using System.AI;
using System.Environment;
using System.Upgrade;

codeunit 2014 "Entity Text AI Install"
{
    Subtype = Install;
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnInstallAppPerDatabase()
    begin
        RegisterCapability();
    end;

    local procedure RegisterCapability()
    var
        CopilotCapability: Codeunit "Copilot Capability";
        EntityTextUpgrade: Codeunit "Entity Text AI Upgrade";
        EnvironmentInformation: Codeunit "Environment Information";
        UpgradeTag: Codeunit "Upgrade Tag";
        LearnMoreUrlTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2226375', Locked = true;
    begin
        if not UpgradeTag.HasUpgradeTag(EntityTextUpgrade.GetRegisterMarketingTextCapabilityTag(), '') then begin
            if EnvironmentInformation.IsSaaSInfrastructure() then
                if not CopilotCapability.IsCapabilityRegistered(Enum::"Copilot Capability"::"Entity Text") then
                    CopilotCapability.RegisterCapability(Enum::"Copilot Capability"::"Entity Text", Enum::"Copilot Availability"::"Generally Available", LearnMoreUrlTxt);

            UpgradeTag.SetDatabaseUpgradeTag(EntityTextUpgrade.GetRegisterMarketingTextCapabilityTag());
        end;
    end;
}