// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Upgrade;

using Microsoft.Manufacturing.Setup;
using System.Upgrade;

codeunit 104063 "Upg. - Default. Calc. Based On"
{
    Subtype = Upgrade;

    trigger OnUpgradePerCompany()
    begin
        UpdateDefaultCalcBasedOn();
    end;

    local procedure UpdateDefaultCalcBasedOn()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetDefaultConsCalcBasedOnUpgradeTag()) then
            exit;

        if ManufacturingSetup.Get() then begin
            ManufacturingSetup."Default Consum. Calc. Based on" := ManufacturingSetup."Default Consum. Calc. Based on"::"Expected Output";
            ManufacturingSetup.Modify();
        end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetDefaultConsCalcBasedOnUpgradeTag());
    end;
}