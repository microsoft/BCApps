#if not CLEAN29
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Setup;

using Microsoft.Upgrade;
using System.Upgrade;

codeunit 99008503 "Legacy Subc. Install"
{
    Subtype = Install;
    ObsoleteReason = 'Legacy Subcontracting is being deprecated. This codeunit will be removed in a future release. Please use the "Disable Legacy Subcontracting" action in Manufacturing Setup to disable the feature and migrate to the new subcontracting app.';
    ObsoleteTag = '29.0';
    ObsoleteState = Pending;

    trigger OnInstallAppPerCompany()
    begin
        SetLegacySubcontractingFeatureOnInstall();
    end;

    local procedure SetLegacySubcontractingFeatureOnInstall()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        LegacySubcFeatureHandler: Codeunit "Legacy Subc. Feature Handler";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        HasLegacySubcontractingData: Boolean;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetLegacySubcontractingUpgradeTag()) then
            exit;

        ManufacturingSetup.SetLoadFields("Legacy Subcontracting");
        if ManufacturingSetup.Get() then begin
            HasLegacySubcontractingData := LegacySubcFeatureHandler.DatabaseHasLegacySubcontractingData();
            if ManufacturingSetup."Legacy Subcontracting" <> HasLegacySubcontractingData then begin
                ManufacturingSetup."Legacy Subcontracting" := HasLegacySubcontractingData;
                ManufacturingSetup.Modify();
            end;
        end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetLegacySubcontractingUpgradeTag());
    end;
}
#endif
