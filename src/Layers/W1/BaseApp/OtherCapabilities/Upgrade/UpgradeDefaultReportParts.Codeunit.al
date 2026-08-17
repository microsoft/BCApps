// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Upgrade;

using Microsoft.Foundation.Reporting;

/// <summary>
/// Re-seeds the Composite Layout header/footer and theme parts that ship with the Base Application on every
/// upgrade, so newly shipped parts appear and changed layout files take effect.
/// </summary>
/// <remarks>
/// Deliberately not guarded by an upgrade tag: the seeding is an upsert of the files shipped with this version,
/// and it has to run again whenever one of those files changes. The parts are global (Company Name = ''), so
/// this runs per database rather than per company.
/// </remarks>
codeunit 104064 "Upgrade Default Report Parts"
{
    Subtype = Upgrade;
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnUpgradePerDatabase()
    var
        DefaultReportPartsMgt: Codeunit "Default Report Parts Mgt.";
    begin
        DefaultReportPartsMgt.SeedDefaultParts();
    end;
}
