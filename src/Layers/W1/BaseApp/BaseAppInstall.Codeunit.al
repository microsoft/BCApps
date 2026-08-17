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
        DefaultReportPartsMgt: Codeunit "Default Report Parts Mgt.";
    begin
        // The header/footer and theme parts are global (Company Name = ''), so seeding once per database is enough.
        DefaultReportPartsMgt.SeedDefaultParts();
    end;

    local procedure AddWordTemplateTables()
    var
        UpgradeBaseApp: Codeunit "Upgrade - BaseApp";
    begin
        UpgradeBaseApp.UpgradeWordTemplateTables();
    end;
}