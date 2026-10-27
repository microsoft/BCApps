// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.SalesFR;

using System.Upgrade;

codeunit 10810 "Upg. Tag Sales FR"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure RegisterPerCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]])
    var
        CurrentModuleInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(CurrentModuleInfo);
        if CurrentModuleInfo.AppVersion().Major() < 31 then
            exit;

        PerCompanyUpgradeTags.Add(GetSalesFRUpgradeTag());
    end;

    internal procedure GetSalesFRUpgradeTag(): Code[250]
    begin
        exit('MS-615861-SalesFRUpgradeTag-20251222');
    end;

    internal procedure GetSalesFRReportLayoutsUpgradeTag(): Code[250]
    begin
        // Do not pre-register this tag; new companies still need their layout defaults initialized.
        exit('MS-615861-SalesFRReportLayouts-20261014');
    end;
}
