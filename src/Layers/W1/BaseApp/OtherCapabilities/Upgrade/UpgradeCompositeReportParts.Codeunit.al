// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Upgrade;

using Microsoft.Foundation.Reporting;
using System.Environment;
using System.Environment.Configuration;
using System.Upgrade;

/// <summary>
/// Upgrade code to seed shipped Composite Report Layout themes and header/footer parts.
/// Seeds during database upgrade and on company open for new tenants provisioned from a
/// pre-built database image where BaseApp is installed but OnInstallAppPerDatabase may not have run.
/// </summary>
codeunit 104067 "Upgrade Composite Report Parts"
{
    Subtype = Upgrade;
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnUpgradePerDatabase()
    begin
        RunUpgrade();
    end;

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", 'OnAfterInitialization', '', false, false)]
    local procedure OnCompanyOpen()
    begin
        SeedDefaultReportPartsIfMissing();
    end;

    internal procedure RunUpgrade()
    var
        CompositeReportPartsMgt: Codeunit "Composite Report Parts Mgt.";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasDatabaseUpgradeTag(UpgradeTagDefinitions.GetCompositeReportPartsUpgradeTag()) then
            exit;

        CompositeReportPartsMgt.SeedDefaultParts();
        UpgradeTag.SetDatabaseUpgradeTag(UpgradeTagDefinitions.GetCompositeReportPartsUpgradeTag());
    end;

    internal procedure SeedShippedParts()
    var
        CompositeReportPartsMgt: Codeunit "Composite Report Parts Mgt.";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        CompositeReportPartsMgt.SeedDefaultParts();
        UpgradeTag.SetDatabaseUpgradeTag(UpgradeTagDefinitions.GetCompositeReportPartsUpgradeTag());
    end;

    local procedure SeedDefaultReportPartsIfMissing()
    var
        TenantReportLayout: Record "Tenant Report Layout";
        CompositeReportPartsMgt: Codeunit "Composite Report Parts Mgt.";
        CompositeLayoutLookupHelper: Codeunit "Composite Layout Lookup Helper";
    begin
        // Exit gracefully if no write permissions - OnCompanyOpen should not fail due to permissions
        if not TenantReportLayout.WritePermission() then
            exit;

        // Exit if parts already exist
        if PartAlreadySeeded(CompositeLayoutLookupHelper.GetTenantReportDefaultsReportID(), CompositeReportPartsMgt.GetShippedPartAppId()) then
            exit;

        // Seed the parts using the standard seeding procedure
        CompositeReportPartsMgt.SeedDefaultParts();
    end;

    local procedure PartAlreadySeeded(ReportID: Integer; AppId: Guid): Boolean
    var
        TenantReportLayout: Record "Tenant Report Layout";
    begin
        TenantReportLayout.SetRange("Report ID", ReportID);
        TenantReportLayout.SetRange("App ID", AppId);
        exit(not TenantReportLayout.IsEmpty());
    end;
}
