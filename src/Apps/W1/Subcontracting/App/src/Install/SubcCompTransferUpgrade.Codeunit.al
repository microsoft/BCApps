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
                if ItemLedgerEntry.TryGetSubcontractorComponentTransfer(ComponentAtSubcontractor) then begin
                    if ItemLedgerEntry."Subc. Component at Subcontr." <> ComponentAtSubcontractor then begin
                        ItemLedgerEntry."Subc. Component at Subcontr." := ComponentAtSubcontractor;
                        ItemLedgerEntry.Modify();
                    end;
                end else
                    Session.LogMessage(
                        '0000W1S',
                        StrSubstNo(SkippedComponentTransferMsg, ItemLedgerEntry."Entry No.", ItemLedgerEntry."Document Type", ItemLedgerEntry."Document No."),
                        Verbosity::Warning,
                        DataClassification::CustomerContent,
                        TelemetryScope::ExtensionPublisher,
                        'Category',
                        SubcontractingUpgradeCategoryLbl);
            until ItemLedgerEntry.Next() = 0;
    end;

    var
        SkippedComponentTransferMsg: Label 'Skipped the subcontractor component transfer migration for item ledger entry %1 because posted %2 %3 is missing or unsupported.', Comment = '%1 = item ledger entry number, %2 = document type, %3 = document number', Locked = true;
        SubcontractingUpgradeCategoryLbl: Label 'Subcontracting Upgrade', Locked = true;
}
