// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft;

using Microsoft.Foundation.Reporting;
using Microsoft.Upgrade;
using System.Upgrade;

codeunit 5000 "BaseApp Install"
{
    SubType = Install;
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnInstallAppPerCompany()
    begin
        AddWordTemplateTables();
    end;

    trigger OnInstallAppPerDatabase()
    begin
        SeedDefaultReportParts();
    end;

    local procedure SeedDefaultReportParts()
    var
        CompositeReportPartsMgt: Codeunit "Composite Report Parts Mgt.";
        //CompositeLayoutAssignMgt: Codeunit "Composite Layout Assign. Mgt.";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        CompositeReportPartsMgt.SeedDefaultParts();
        // Assignment is disabled until the platform change it depends on ships. Re-enable this line together with the
        // declaration above, and keep it in step with the upgrade codeunit.
        //CompositeLayoutAssignMgt.AssignDefaultParts();

        if not UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetCompositeReportPartsUpgradeTag()) then
            UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetCompositeReportPartsUpgradeTag());
    end;

    local procedure AddWordTemplateTables()
    var
        UpgradeBaseApp: Codeunit "Upgrade - BaseApp";
    begin
        UpgradeBaseApp.UpgradeWordTemplateTables();
    end;
}