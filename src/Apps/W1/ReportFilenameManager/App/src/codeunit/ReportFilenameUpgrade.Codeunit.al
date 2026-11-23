// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting.FileNaming;

using System.Upgrade;

codeunit 8145 "Report Filename Upgrade"
{
    Access = Internal;
    Subtype = Upgrade;
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnUpgradePerCompany()
    begin
        UpgradeDefaults();
    end;

    internal procedure UpgradeDefaults()
    var
        ReportFilenameDefaults: Codeunit "Report Filename Defaults";
    begin
        ReportFilenameDefaults.InitializeExistingCompany();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure RegisterPerCompanyUpgradeTags(var PerCompanyUpgradeTags: List of [Code[250]])
    var
        ReportFilenameDefaults: Codeunit "Report Filename Defaults";
    begin
        PerCompanyUpgradeTags.Add(ReportFilenameDefaults.GetDefaultPatternsUpgradeTag());
    end;
}
