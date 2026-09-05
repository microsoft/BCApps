// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExciseTaxes;

using Microsoft.Inventory.Item;
using System.Upgrade;

codeunit 7414 "Excise Tax Upgrade"
{
    Subtype = Upgrade;
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnUpgradePerCompany()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag(GetMultipleExciseTaxesPerItemUpgradeTag()) then begin
            MigrateItemExciseTaxSetup();
            UpgradeTag.SetUpgradeTag(GetMultipleExciseTaxesPerItemUpgradeTag());
        end;

#if not CLEANSCHEMA33
        if not UpgradeTag.HasUpgradeTag(GetExciseTaxRateTableUpgradeTag()) then begin
            MigrateExciseTaxRates();
            UpgradeTag.SetUpgradeTag(GetExciseTaxRateTableUpgradeTag());
        end;
#endif
    end;

#if not CLEANSCHEMA33
    local procedure MigrateExciseTaxRates()
    var
        ExciseTaxItemFARate: Record "Excise Tax Item/FA Rate";
        ExciseTaxRate: Record "Excise Tax Rate";
    begin
#pragma warning disable AL0432
        if not ExciseTaxItemFARate.FindSet() then
            exit;

        repeat
            if not ExciseTaxRate.Get(ExciseTaxItemFARate."Excise Tax Type Code", ExciseTaxItemFARate."Source Type", ExciseTaxItemFARate."Source No.", '', ExciseTaxItemFARate."Effective From Date") then begin
                ExciseTaxRate.Init();
                ExciseTaxRate.TransferFields(ExciseTaxItemFARate);
                ExciseTaxRate."Item Category Code" := '';
                ExciseTaxRate."Excise Calculation Type" := ExciseTaxRate."Excise Calculation Type"::"Specific per Unit";
                ExciseTaxRate."Excise Duty %" := 0;
                ExciseTaxRate.Insert();
            end;
        until ExciseTaxItemFARate.Next() = 0;
#pragma warning restore AL0432
    end;
#endif

    local procedure MigrateItemExciseTaxSetup()
    var
        Item: Record Item;
        ItemExciseTax: Record "Item Excise Tax";
    begin
#pragma warning disable AL0432
        Item.SetLoadFields("Excise Tax Type", "Quantity for Excise Tax", "Excise Unit of Measure Code");
        Item.SetFilter("Excise Tax Type", '<>%1', '');
        if Item.FindSet() then
            repeat
                if not ItemExciseTax.Get(Item."No.", Item."Excise Tax Type") then
                    CreateItemExciseTaxFromItem(Item);
            until Item.Next() = 0;
#pragma warning restore AL0432
    end;

    local procedure CreateItemExciseTaxFromItem(Item: Record Item)
    var
        ItemExciseTax: Record "Item Excise Tax";
        ExciseTaxType: Record "Excise Tax Type";
    begin
#pragma warning disable AL0432
        ItemExciseTax.Init();
        ItemExciseTax."Item No." := Item."No.";
        ItemExciseTax."Excise Tax Type Code" := Item."Excise Tax Type";

        ExciseTaxType.SetLoadFields(Description);
        if ExciseTaxType.Get(Item."Excise Tax Type") then
            ItemExciseTax."Excise Tax Type Description" := ExciseTaxType.Description;

        ItemExciseTax."Quantity for Excise Tax" := Item."Quantity for Excise Tax";
        ItemExciseTax."Excise Unit of Measure Code" := Item."Excise Unit of Measure Code";
        ItemExciseTax.Insert();
#pragma warning restore AL0432
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", OnGetPerCompanyUpgradeTags, '', false, false)]
    local procedure RegisterPerCompanyUpgradeTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetMultipleExciseTaxesPerItemUpgradeTag());
#if not CLEANSCHEMA33
        PerCompanyUpgradeTags.Add(GetExciseTaxRateTableUpgradeTag());
#endif
    end;

    local procedure GetMultipleExciseTaxesPerItemUpgradeTag(): Code[250]
    begin
        exit('MS-626127-MultipleExciseTaxesPerItem-20260727');
    end;

#if not CLEANSCHEMA33
    local procedure GetExciseTaxRateTableUpgradeTag(): Code[250]
    begin
        exit('MS-626305-ExciseTaxRate-20260902');
    end;
#endif
}