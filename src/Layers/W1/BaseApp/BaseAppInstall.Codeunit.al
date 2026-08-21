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
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if not CompositeReportPartsMgt.SeedDefaultParts() then
            exit;

        if not UpgradeTag.HasDatabaseUpgradeTag(UpgradeTagDefinitions.GetCompositeReportPartsUpgradeTag()) then
            UpgradeTag.SetDatabaseUpgradeTag(UpgradeTagDefinitions.GetCompositeReportPartsUpgradeTag());
    end;

    local procedure AddWordTemplateTables()
    var
        UpgradeBaseApp: Codeunit "Upgrade - BaseApp";
    begin
        UpgradeBaseApp.UpgradeWordTemplateTables();
    end;
}