// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Upgrade;

using Microsoft.Foundation.Reporting;
using System.Upgrade;

/// <summary>
/// Seeds the shipped Composite Layout theme and header/footer parts once per upgrade tag, guarding at entry. The tag is
/// recorded only when every part was seeded, so a partial pass is retried by a later upgrade. Add a new dated tag
/// whenever the shipped layout files change, so the pass runs again and existing tenants receive them.
/// </summary>
codeunit 104064 "Upgrade Composite Report Parts"
{
    Access = Internal;
    Subtype = Upgrade;
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnUpgradePerDatabase()
    begin
        RunUpgrade();
    end;

    internal procedure RunUpgrade()
    var
        CompositeReportPartsMgt: Codeunit "Composite Report Parts Mgt.";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasDatabaseUpgradeTag(UpgradeTagDefinitions.GetCompositeReportPartsUpgradeTag()) then
            exit;

        RecordSeedOutcome(CompositeReportPartsMgt.SeedDefaultParts());
    end;

    internal procedure RecordSeedOutcome(AllPartsSeeded: Boolean)
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if not AllPartsSeeded then
            exit;

        UpgradeTag.SetDatabaseUpgradeTag(UpgradeTagDefinitions.GetCompositeReportPartsUpgradeTag());
    end;
}
