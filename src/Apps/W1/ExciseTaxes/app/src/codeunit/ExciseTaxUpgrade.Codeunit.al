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
        if UpgradeTag.HasUpgradeTag(GetMultipleExciseTaxesPerItemUpgradeTag()) then
            exit;

        MigrateItemExciseTaxSetup();

        UpgradeTag.SetUpgradeTag(GetMultipleExciseTaxesPerItemUpgradeTag());
    end;

    local procedure MigrateItemExciseTaxSetup()
    var
        Item: Record Item;
        ItemExciseTax: Record "Item Excise Tax";
        ExciseTaxType: Record "Excise Tax Type";
    begin
#pragma warning disable AL0432
        Item.SetLoadFields("Excise Tax Type", "Quantity for Excise Tax", "Excise Unit of Measure Code");
        Item.SetFilter("Excise Tax Type", '<>%1', '');
        if Item.FindSet() then
            repeat
                if not ItemExciseTax.Get(Item."No.", Item."Excise Tax Type") then begin
                    ItemExciseTax.Init();
                    ItemExciseTax."Item No." := Item."No.";
                    ItemExciseTax."Excise Tax Type Code" := Item."Excise Tax Type";

                    if ExciseTaxType.Get(Item."Excise Tax Type") then
                        ItemExciseTax."Excise Tax Type Description" := ExciseTaxType.Description;

                    ItemExciseTax."Quantity for Excise Tax" := Item."Quantity for Excise Tax";
                    ItemExciseTax."Excise Unit of Measure Code" := Item."Excise Unit of Measure Code";
                    ItemExciseTax.Insert();
                end;
            until Item.Next() = 0;
#pragma warning restore AL0432
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", OnGetPerCompanyUpgradeTags, '', false, false)]
    local procedure RegisterPerCompanyUpgradeTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetMultipleExciseTaxesPerItemUpgradeTag());
    end;

    local procedure GetMultipleExciseTaxesPerItemUpgradeTag(): Code[250]
    begin
        exit('MS-626127-MultipleExciseTaxesPerItem-20260727');
    end;
}