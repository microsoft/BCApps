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
    // without an assigned permission set carrying it, and the seeding must succeed regardless of the triggering
    // user's own permissions - hence the elevated tabledata permissions below.
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Tenant Report Layout" = rid;

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
        SeedShippedParts();
    end;

    internal procedure RunUpgrade()
    begin
        SeedShippedParts();
    end;

    internal procedure SeedShippedParts()
    var
        CompositeReportPartsMgt: Codeunit "Composite Report Parts Mgt.";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        // Cheap persisted guard shared by every entry point (install, upgrade and company open): a database that has
        // been seeded carries the upgrade tag and exits on this single read, keeping the seeding exactly-once.
        if UpgradeTag.HasDatabaseUpgradeTag(UpgradeTagDefinitions.GetCompositeReportPartsUpgradeTag()) then
            exit;

        CompositeReportPartsMgt.SeedDefaultParts();
        UpgradeTag.SetDatabaseUpgradeTag(UpgradeTagDefinitions.GetCompositeReportPartsUpgradeTag());
    end;
}
