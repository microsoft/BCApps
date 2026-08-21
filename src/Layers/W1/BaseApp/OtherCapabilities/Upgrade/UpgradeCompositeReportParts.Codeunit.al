// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Upgrade;

using Microsoft.Foundation.Reporting;
using System.Upgrade;

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
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasDatabaseUpgradeTag(UpgradeTagDefinitions.GetCompositeReportPartsUpgradeTag()) then
            exit;

        RecordSeedOutcome(CompositeReportPartsMgt.SeedDefaultParts());
    end;

    /// <summary>
    /// Records the seeding pass as done on this database, but only when every shipped part was written. A pass that
    /// skipped a part leaves the tag unset on purpose: the tag is what stops the pass from running again, so stamping it
    /// after a partial seed would leave the skipped parts missing for good. Unset, the next upgrade retries them.
    /// </summary>
    /// <param name="AllPartsSeeded">The result of the seeding pass.</param>
    /// <remarks>
    /// Internal rather than inlined in RunUpgrade so a test can drive the decision for a failed pass. Every shipped part
    /// is a resource of this app and the pass reports failure only when one of them cannot be written, so a seeding
    /// failure cannot be arranged from the outside. Call it only when the tag is known to be absent - RunUpgrade has
    /// already returned on it - since recording a tag that is already there is an error.
    /// </remarks>
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
