#if CLEAN28
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.SalesFR;

using Microsoft.CRM.Contact;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
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
        CurrentModuleInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(CurrentModuleInfo);
        if CurrentModuleInfo.AppVersion().Major() < 31 then
            exit;

        UpgradeSalesFR();
    end;

    local procedure UpgradeSalesFR()
    var
        SalesFRHelperProcedures: Codeunit "Sales FR Helper Procedures";
    begin
        if UpgradeTag.HasUpgradeTag(UpgTagSalesFR.GetSalesFRUpgradeTag()) then
            exit;

        SalesFRHelperProcedures.TransferFields(Database::Customer, 10805, 10806); // 10805 - the existing field "SIREN No.", 10806 - the new field "SIREN No. FR";
        SalesFRHelperProcedures.TransferFields(Database::Contact, 10805, 10806); // 10805 - the existing field "SIREN No.", 10806 - the new field "SIREN No. FR";
        SalesFRHelperProcedures.TransferFields(Database::"Sales Header", 10801, 10802); // 10801 - the existing field "VAT Paid on Debits", 10802 - the new field "VAT Paid on Debits FR";
        SalesFRHelperProcedures.TransferFields(Database::"Sales Cr.Memo Header", 10801, 10802); // 10801 - the existing field "VAT Paid on Debits", 10802 - the new field "VAT Paid on Debits FR";
        SalesFRHelperProcedures.TransferFields(Database::"Sales Invoice Header", 10801, 10802); // 10801 - the existing field "VAT Paid on Debits", 10802 - the new field "VAT Paid on Debits FR";

        UpgradeTag.SetUpgradeTag(UpgTagSalesFR.GetSalesFRUpgradeTag());
    end;
}
#endif
