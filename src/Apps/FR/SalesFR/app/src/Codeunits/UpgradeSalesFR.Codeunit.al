#if CLEAN30
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.SalesFR;

using System.Upgrade;

codeunit 10809 "Upgrade Sales FR"
{
    Access = Internal;
    Subtype = Upgrade;

    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgTagSalesFR: Codeunit "Upg. Tag Sales FR";

    trigger OnUpgradePerCompany()
    var
        SalesFRReportLayouts: Codeunit "Sales FR Report Layouts";
        CurrentModuleInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(CurrentModuleInfo);
        if CurrentModuleInfo.AppVersion().Major() < 31 then
            exit;

        UpgradeSalesFR();
        SalesFRReportLayouts.SetDefaultReportLayouts();
    end;

    local procedure UpgradeSalesFR()
    var
        SalesFRHelperProcedures: Codeunit "Sales FR Helper Procedures";
    begin
        if UpgradeTag.HasUpgradeTag(UpgTagSalesFR.GetSalesFRUpgradeTag()) then
            exit;

        SalesFRHelperProcedures.TransferSalesFRFields();

        UpgradeTag.SetUpgradeTag(UpgTagSalesFR.GetSalesFRUpgradeTag());
    end;
}
#endif
