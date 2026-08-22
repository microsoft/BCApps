// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Upgrade;

using Microsoft.Foundation.Reporting;
using System.Upgrade;

/// <summary>
/// Seeds the shipped Composite Layout theme and header/footer parts on every upgrade, replacing whatever the shared
/// pool holds under those names. The tag is recorded once and does not gate the pass.
/// </summary>
codeunit 104064 "Upgrade Composite Report Parts"
{
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
    begin
        RecordSeedOutcome(CompositeReportPartsMgt.SeedDefaultParts());
    end;

    internal procedure RecordSeedOutcome(AllPartsSeeded: Boolean)
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if not AllPartsSeeded then
            exit;

        if UpgradeTag.HasDatabaseUpgradeTag(UpgradeTagDefinitions.GetCompositeReportPartsUpgradeTag()) then
            exit;

        UpgradeTag.SetDatabaseUpgradeTag(UpgradeTagDefinitions.GetCompositeReportPartsUpgradeTag());
    end;
}
