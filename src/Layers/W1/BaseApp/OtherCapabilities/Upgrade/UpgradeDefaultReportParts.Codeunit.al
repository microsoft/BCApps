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
/// <remarks>
/// Deliberately not guarded by an upgrade tag: the seeding is an upsert of the files shipped with this version,
/// and it has to run again whenever one of those files changes. The parts are global (Company Name = ''), so
/// this runs per database rather than per company.
///
/// Running the assignment on every upgrade is safe for the same reason it needs no tag: it only fills in layouts
/// that have no header/footer yet, so it picks up newly shipped designs and newly installed reports without
/// touching a choice an administrator has made.
/// </remarks>
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

        // Assigning resolves each part in the pool by name, so it has to follow the seeding above.
        CompositeLayoutAssignMgt.AssignDefaultParts();
    end;
}
