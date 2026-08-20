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

    /// <remarks>
    /// This seeds the shipped parts only. Assigning them to body layouts is not wired up here yet: it waits on the
    /// platform change that resolves a body layout from a plain layout name. Whoever adds that step has to add a new
    /// dated tag in Upgrade Tag Definitions as well - databases upgraded in the meantime already carry the tag below,
    /// so the guard would otherwise skip the pass and the assignment would never run on them.
    /// </remarks>
    trigger OnUpgradePerDatabase()
    var
        CompositeReportPartsMgt: Codeunit "Composite Report Parts Mgt.";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetCompositeReportPartsUpgradeTag()) then
            exit;

        if CompositeReportPartsMgt.SeedDefaultParts() then
            UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetCompositeReportPartsUpgradeTag());
    end;
}
