// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Ledger;
using System.Upgrade;

codeunit 20509 "Subc. Comp. Transfer Upgrade"
{
    Subtype = Upgrade;
    Permissions = tabledata "Item Ledger Entry" = rm;

    trigger OnUpgradePerCompany()
    begin
        UpgradeComponentTransfers();
    end;

    internal procedure UpgradeComponentTransfers()
    var
        SubcUpgradeTagDefExt: Codeunit "Subc. Upgrade Tag Def. Ext.";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(SubcUpgradeTagDefExt.GetComponentTransferUpgradeTag()) then
            exit;

        MigrateComponentTransfers();

        UpgradeTag.SetUpgradeTag(SubcUpgradeTagDefExt.GetComponentTransferUpgradeTag());
    end;

    internal procedure MigrateComponentTransfers()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ComponentAtSubcontractor: Boolean;
    begin
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Transfer);
        ItemLedgerEntry.SetFilter("Subc. Prod. Order No.", '<>%1', '');
        ItemLedgerEntry.SetFilter("Subc. Prod. Order Line No.", '<>0');
        ItemLedgerEntry.SetFilter("Prod. Order Comp. Line No.", '<>0');
        if ItemLedgerEntry.FindSet(true) then
            repeat
                ComponentAtSubcontractor := ItemLedgerEntry.IsSubcontractorComponentTransfer();
                if ItemLedgerEntry."Subc. Component at Subcontr." <> ComponentAtSubcontractor then begin
                    ItemLedgerEntry."Subc. Component at Subcontr." := ComponentAtSubcontractor;
                    ItemLedgerEntry.Modify();
                end;
            until ItemLedgerEntry.Next() = 0;
    end;
}
