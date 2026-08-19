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
/// Seeding only. The parts are not assigned to any layout here: the platform validates a Tenant Report Layout Cfg row
/// against the layout it names, and an error in an upgrade or install trigger rolls the whole publish back. Assign the
/// shipped designs from the Report themes and header-footer setup page instead.
/// </remarks>
codeunit 104064 "Upgrade Composite Report Parts"
{
    Subtype = Upgrade;
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnUpgradePerDatabase()
    var
        CompositeReportPartsMgt: Codeunit "Composite Report Parts Mgt.";
    begin
        CompositeReportPartsMgt.SeedDefaultParts();
    end;
}
