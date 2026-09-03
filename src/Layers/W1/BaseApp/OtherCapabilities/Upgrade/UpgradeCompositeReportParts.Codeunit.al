// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Upgrade;

using Microsoft.Foundation.Reporting;
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
    // The OnAfterInitialization subscriber runs for every user at company open, so the codeunit must be executable
    // without an assigned permission set carrying it. The seeding itself stays gated by the write-permission check.
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

        EnsureCanSeedShippedParts();

        CompositeReportPartsMgt.SeedDefaultParts();
        UpgradeTag.SetDatabaseUpgradeTag(UpgradeTagDefinitions.GetCompositeReportPartsUpgradeTag());
    end;

    internal procedure SeedShippedParts()
    var
        CompositeReportPartsMgt: Codeunit "Composite Report Parts Mgt.";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasDatabaseUpgradeTag(UpgradeTagDefinitions.GetCompositeReportPartsUpgradeTag()) then
            exit;

        EnsureCanSeedShippedParts();

        CompositeReportPartsMgt.SeedDefaultParts();
        UpgradeTag.SetDatabaseUpgradeTag(UpgradeTagDefinitions.GetCompositeReportPartsUpgradeTag());
    end;

    local procedure EnsureCanSeedShippedParts()
    var
        TenantReportLayout: Record "Tenant Report Layout";
    begin
        if TenantReportLayout.WritePermission() then
            exit;

        Error(MissingTenantReportLayoutWritePermissionErr);
    end;

    local procedure SeedDefaultReportPartsIfMissing()
    var
        TenantReportLayout: Record "Tenant Report Layout";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        // Cheap persisted guard: a database that has been seeded carries the upgrade tag, so an already-seeded
        // database exits here instead of querying Tenant Report Layout on every company open.
        if UpgradeTag.HasDatabaseUpgradeTag(UpgradeTagDefinitions.GetCompositeReportPartsUpgradeTag()) then
            exit;

        // Exit gracefully if no write permissions - OnCompanyOpen should not fail due to permissions
        if not TenantReportLayout.WritePermission() then
            exit;

        // Route through SeedShippedParts so the full shipped set is seeded and the database upgrade tag is written,
        // keeping the seeding exactly-once across this path and OnUpgradePerDatabase.
        SeedShippedParts();
    end;

    var
        MissingTenantReportLayoutWritePermissionErr: Label 'You do not have permission to seed report parts.';
}
