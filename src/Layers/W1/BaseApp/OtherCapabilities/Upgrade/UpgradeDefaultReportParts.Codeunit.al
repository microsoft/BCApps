// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Upgrade;

using Microsoft.Foundation.Reporting;

/// <summary>
/// Re-seeds the Composite Layout header/footer and theme parts that ship with the Base Application on every
/// upgrade, so newly shipped parts appear and changed layout files take effect, and assigns the shipped parts to
/// the body-only layouts that have none.
/// </summary>
codeunit 104064 "Upgrade Composite Report Parts"
{
    Subtype = Upgrade;
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnUpgradePerDatabase()
    var
        CompositeReportPartsMgt: Codeunit "Composite Report Parts Mgt.";
        CompositeLayoutAssignMgt: Codeunit "Composite Layout Assign. Mgt.";
    begin
        CompositeReportPartsMgt.SeedDefaultParts();

        CompositeLayoutAssignMgt.AssignDefaultParts();
    end;
}
