#if not CLEAN28
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Setup;

using Microsoft.Upgrade;
using System.Environment;
using System.Environment.Configuration;
using System.Upgrade;

codeunit 99008502 "Legacy Subc. Upgrade"
{
    Subtype = Upgrade;
    ObsoleteReason = 'Legacy Subcontracting will be discontinued, environments should move to the Subcontracting App.';
    ObsoleteState = Pending;
    ObsoleteTag = '28.0';

    trigger OnUpgradePerCompany()
    var
        HybridDeployment: Codeunit "Hybrid Deployment";
    begin
        if not HybridDeployment.VerifyCanStartUpgrade(CompanyName()) then
            exit;

        SetLegacySubcontractingFeatureOnUpgrade();
    end;

    local procedure SetLegacySubcontractingFeatureOnUpgrade()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        LegacySubcFeatureHandler: Codeunit "Legacy Subc. Feature Handler";
        HasLegacySubcontractingData: Boolean;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetLegacySubcontractingUpgradeTag()) then
            exit;

        ManufacturingSetup.SetLoadFields("Legacy Subcontracting");
        if ManufacturingSetup.Get() then begin
            HasLegacySubcontractingData := LegacySubcFeatureHandler.DatabaseHasLegacySubcontractingData();
            if not ManufacturingSetup."Legacy Subcontracting" and HasLegacySubcontractingData then begin
                ManufacturingSetup."Legacy Subcontracting" := true;
                ManufacturingSetup.Modify();
            end;
        end;

        RefreshApplicationAreaSetup();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetLegacySubcontractingUpgradeTag());
    end;

    local procedure RefreshApplicationAreaSetup()
    var
        ExperienceTierSetup: Record "Experience Tier Setup";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        ExperienceTier: Text;
    begin
        if ApplicationAreaMgmtFacade.GetExperienceTierCurrentCompany(ExperienceTier) then
            if ExperienceTier = ExperienceTierSetup.FieldCaption(Custom) then
                exit;

        ApplicationAreaMgmtFacade.RefreshExperienceTierCurrentCompany();
    end;
}
#endif
