// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft;

using Microsoft.Foundation.Reporting;
using Microsoft.Upgrade;

codeunit 5000 "BaseApp Install"
{
    SubType = Install;
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnInstallAppPerCompany()
    begin
        AddWordTemplateTables();
    end;

    trigger OnInstallAppPerDatabase()
    begin
        SeedDefaultReportParts();
    end;

    local procedure SeedDefaultReportParts()
    var
        CompositeReportPartsMgt: Codeunit "Composite Report Parts Mgt.";
        CompositeLayoutAssignMgt: Codeunit "Composite Layout Assign. Mgt.";
    begin
        // The parts are global (Company Name = ''), so seeding once per database is enough. Assigning has to come
        // after, because each assignment resolves its part in the pool by name.
        CompositeReportPartsMgt.SeedDefaultParts();
        CompositeLayoutAssignMgt.AssignDefaultParts();
    end;

    local procedure AddWordTemplateTables()
    var
        UpgradeBaseApp: Codeunit "Upgrade - BaseApp";
    begin
        UpgradeBaseApp.UpgradeWordTemplateTables();
    end;
}