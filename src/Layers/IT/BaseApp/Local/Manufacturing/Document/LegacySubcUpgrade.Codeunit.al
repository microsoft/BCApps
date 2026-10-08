#if not CLEAN28
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Setup;

using Microsoft.Manufacturing.WorkCenter;
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
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetLegacySubcontractingUpgradeTag()) then
            exit;

        ManufacturingSetup.SetLoadFields("Legacy Subcontracting");
        if ManufacturingSetup.Get() then
            if not ManufacturingSetup."Legacy Subcontracting" then
                if LegacySubcFeatureHandler.DatabaseHasLegacySubcontractingData() or SubcontractorWorkCentersExist() then begin
                    ManufacturingSetup."Legacy Subcontracting" := true;
                    ManufacturingSetup.Modify();
                end;

        RefreshApplicationAreaSetup();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetLegacySubcontractingUpgradeTag());
    end;

    local procedure SubcontractorWorkCentersExist(): Boolean
    var
        WorkCenter: Record "Work Center";
    begin
        WorkCenter.SetFilter("Subcontractor No.", '<>%1', '');
        exit(not WorkCenter.IsEmpty());
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
