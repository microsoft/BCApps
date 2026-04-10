// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Upgrade;

using System.Environment.Configuration;
using System.Upgrade;

codeunit 104053 "Upgrade Word Report Rendering"
{
    Subtype = Upgrade;

    trigger OnUpgradePerDatabase()
    var
        FeatureKey: Record "Feature Key";
        FeatureManagementFacade: Codeunit "Feature Management Facade";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinations: Codeunit "Upgrade Tag Definitions";
        PlatformRenderingInPlatformTxt: Label 'RenderWordReportsInPlatform', Locked = true;
    begin
        if not UpgradeTag.HasUpgradeTag(UpgradeTagDefinations.GetRenderWordReportsInPlatformFeatureKeyUpgradeTag()) then begin
            if FeatureKey.Get(PlatformRenderingInPlatformTxt) then
                if FeatureKey.Enabled = FeatureKey.Enabled::None then begin
                    FeatureKey.Enabled := FeatureKey.Enabled::"All Users";
                    FeatureKey.Modify();

                    FeatureManagementFacade.AfterValidateEnabled(FeatureKey);
                end;

            UpgradeTag.SetUpgradeTag(UpgradeTagDefinations.GetRenderWordReportsInPlatformFeatureKeyUpgradeTag());
        end;
    end;

}