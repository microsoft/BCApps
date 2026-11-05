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
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(GetDefaultPatternsUpgradeTag()) then
            exit;

        ReportFilenameDefaults.InitializeSetup(false);
        UpgradeTag.SetUpgradeTag(GetDefaultPatternsUpgradeTag());
    end;

    internal procedure GetDefaultPatternsUpgradeTag(): Code[250]
    begin
        exit('MS-658065-ReportFilenameDefaults-20261105');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure RegisterPerCompanyUpgradeTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetDefaultPatternsUpgradeTag());
    end;
}
