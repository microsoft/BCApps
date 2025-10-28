// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

using System.Environment;
using System.Upgrade;

codeunit 7776 "Copilot Capability Upgrade"
{
    Subtype = Upgrade;
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnUpgradePerDatabase()
    var
        CopilotCapabilityInstall: Codeunit "Copilot Capability Install";
        CopilotCapability: Codeunit "Copilot Capability";
        EnvironmentInformation: Codeunit "Environment Information";
        UpgradeTag: Codeunit "Upgrade Tag";
        AnalyzeListLearnMoreLbl: Label 'https://go.microsoft.com/fwlink/?linkid=2252783', Locked = true;
    begin
        if EnvironmentInformation.IsSaaSInfrastructure() then begin
            CopilotCapabilityInstall.RegisterCapabilities();

            if CopilotCapability.IsCapabilityRegistered(Enum::"Copilot Capability"::"Analyze List") and not UpgradeTag.HasUpgradeTag(GetRegisterAnalyzeListCopilotGACapabilityUpgradeTag()) then begin
                CopilotCapability.ModifyCapability(Enum::"Copilot Capability"::"Analyze List", Enum::"Copilot Availability"::"Generally Available", Enum::"Copilot Billing Type"::"Not Billed", AnalyzeListLearnMoreLbl);
                UpgradeTag.SetUpgradeTag(GetRegisterAnalyzeListCopilotGACapabilityUpgradeTag());
            end;
        end;
    end;

    procedure GetRegisterAnalyzeListCopilotGACapabilityUpgradeTag(): Text[250]
    begin
        exit('MS-571288-RegisterAnalyzeListCopilotGACapability-20250908');
    end;
}