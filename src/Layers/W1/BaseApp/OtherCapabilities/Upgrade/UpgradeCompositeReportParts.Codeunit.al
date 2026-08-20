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
    var
        CompositeReportPartsMgt: Codeunit "Composite Report Parts Mgt.";
        CompositeLayoutAssignMgt: Codeunit "Composite Layout Assign. Mgt.";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetCompositeReportPartsUpgradeTag()) then
            exit;

        CompositeReportPartsMgt.SeedDefaultParts();
        CompositeLayoutAssignMgt.AssignDefaultParts();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetCompositeReportPartsUpgradeTag());
    end;
}
