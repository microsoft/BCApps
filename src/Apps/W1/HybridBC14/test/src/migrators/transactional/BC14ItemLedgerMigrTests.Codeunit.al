// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration.BC14Reimplementation;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;

codeunit 148918 "BC14 ItemLedgerMigr Tests"
{
    // [FEATURE] [BC14 Cloud Migration Item Ledger Entry]

    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        JournalBatchNameTxt: Label 'BC14IT0001', Locked = true;

    [Test]
    procedure TestGetDisplayName()
    var
        BC14ItemLedgerMigrator: Codeunit "BC14 Item Ledger Migrator";
    begin
        // [SCENARIO] GetDisplayName returns the item ledger migrator name.
        Assert.AreEqual('Item Ledger Entry Migrator', BC14ItemLedgerMigrator.GetDisplayName(), 'Unexpected display name.');
    end;

    [Test]
    procedure TestIsEnabled_InventoryModuleDisabled_ReturnsFalse()
    var
        BC14ItemLedgerMigrator: Codeunit "BC14 Item Ledger Migrator";
    begin
        // [SCENARIO] The migrator opts out when the inventory module is disabled.
        SetInventoryModule(false);
        Assert.IsFalse(BC14ItemLedgerMigrator.IsEnabled(), 'IsEnabled should be false when inventory module disabled.');
    end;

    [Test]
    procedure TestIsEnabled_InventoryModuleEnabled_ReturnsTrue()
    var
        BC14ItemLedgerMigrator: Codeunit "BC14 Item Ledger Migrator";
    begin
        // [SCENARIO] The migrator is enabled when the inventory module is enabled.
        SetInventoryModule(true);
        Assert.IsTrue(BC14ItemLedgerMigrator.IsEnabled(), 'IsEnabled should be true when inventory module enabled.');
    end;

    [Test]
    procedure TestCreateItemJournalLine_OpenEntry_StagesPositiveAdjustment()
    var
        ItemJournalLine: Record "Item Journal Line";
        BC14ItemLedgerEntry: Record "BC14 Item Ledger Entry";
        BC14ItemLedgerMigrator: Codeunit "BC14 Item Ledger Migrator";
    begin
        // [SCENARIO] An open item ledger entry is staged as a positive-adjustment item journal line
        //            whose quantity is the remaining quantity and whose unit cost is the entry's
        //            actual cost spread over its original quantity.
        CleanupTestData();
        SetInventoryModule(true);
        CreateItem('ITEM-001');
        CreateLocation('MAIN');
        BC14ItemLedgerMigrator.EnsureBatchExists(JournalBatchNameTxt, 'BC14 Item Ledger Migration');

        // Original qty 10 at total cost 250 => unit cost 25; remaining 10 still on hand.
        InsertItemLedgerEntry(1, 'ITEM-001', 'MAIN', 10, 10, 250);

        // [WHEN] The migrator stages the entry
        BC14ItemLedgerEntry.Get(1);
        BC14ItemLedgerMigrator.CreateItemJournalLine(BC14ItemLedgerEntry);

        // [THEN] A positive-adjustment line rebuilds the remaining on-hand quantity and value
        ItemJournalLine.SetRange("Journal Template Name", BC14ItemLedgerMigrator.GetTemplateName());
        ItemJournalLine.SetRange("Journal Batch Name", JournalBatchNameTxt);
        Assert.IsTrue(ItemJournalLine.FindFirst(), 'Item journal line should be created.');
        Assert.AreEqual(ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemJournalLine."Entry Type", 'Entry Type should be Positive Adjmt.');
        Assert.AreEqual('ITEM-001', ItemJournalLine."Item No.", 'Item No. should be the migrated item.');
        Assert.AreEqual(10, ItemJournalLine.Quantity, 'Quantity should equal the remaining quantity.');
        Assert.AreEqual(25, ItemJournalLine."Unit Cost", 'Unit Cost should equal cost amount / original quantity.');
        Assert.AreEqual('MAIN', ItemJournalLine."Location Code", 'Location Code should be carried over.');
    end;

    [Test]
    procedure TestCreateItemJournalLine_ZeroRemaining_IsSkipped()
    var
        ItemJournalLine: Record "Item Journal Line";
        BC14ItemLedgerEntry: Record "BC14 Item Ledger Entry";
        BC14ItemLedgerMigrator: Codeunit "BC14 Item Ledger Migrator";
    begin
        // [SCENARIO] A fully-consumed inbound entry (remaining quantity 0) is not staged.
        CleanupTestData();
        SetInventoryModule(true);
        CreateItem('ITEM-002');
        CreateLocation('MAIN');
        BC14ItemLedgerMigrator.EnsureBatchExists(JournalBatchNameTxt, 'BC14 Item Ledger Migration');

        InsertItemLedgerEntry(2, 'ITEM-002', 'MAIN', 10, 0, 250);

        // [WHEN] The migrator processes the entry
        BC14ItemLedgerEntry.Get(2);
        BC14ItemLedgerMigrator.CreateItemJournalLine(BC14ItemLedgerEntry);

        // [THEN] No journal line is created
        ItemJournalLine.SetRange("Journal Template Name", BC14ItemLedgerMigrator.GetTemplateName());
        ItemJournalLine.SetRange("Journal Batch Name", JournalBatchNameTxt);
        Assert.IsTrue(ItemJournalLine.IsEmpty(), 'Entry with no remaining quantity should not produce a journal line.');
    end;

    [Test]
    procedure TestCreateItemJournalLine_Idempotent_DoesNotDuplicate()
    var
        ItemJournalLine: Record "Item Journal Line";
        BC14ItemLedgerEntry: Record "BC14 Item Ledger Entry";
        BC14ItemLedgerMigrator: Codeunit "BC14 Item Ledger Migrator";
    begin
        // [SCENARIO] Re-running the migrator for the same entry does not create a duplicate line.
        CleanupTestData();
        SetInventoryModule(true);
        CreateItem('ITEM-003');
        CreateLocation('MAIN');
        BC14ItemLedgerMigrator.EnsureBatchExists(JournalBatchNameTxt, 'BC14 Item Ledger Migration');

        InsertItemLedgerEntry(3, 'ITEM-003', 'MAIN', 5, 5, 100);

        // [WHEN] The migrator runs twice for the same entry
        BC14ItemLedgerEntry.Get(3);
        BC14ItemLedgerMigrator.CreateItemJournalLine(BC14ItemLedgerEntry);
        BC14ItemLedgerMigrator.CreateItemJournalLine(BC14ItemLedgerEntry);

        // [THEN] Only one journal line exists
        ItemJournalLine.SetRange("Journal Template Name", BC14ItemLedgerMigrator.GetTemplateName());
        ItemJournalLine.SetRange("Journal Batch Name", JournalBatchNameTxt);
        Assert.AreEqual(1, ItemJournalLine.Count(), 'Re-running should not duplicate the journal line.');
    end;

    local procedure CleanupTestData()
    var
        BC14ItemLedgerEntry: Record "BC14 Item Ledger Entry";
        BC14ValueEntry: Record "BC14 Value Entry";
        ItemJournalLine: Record "Item Journal Line";
        Item: Record Item;
        Location: Record Location;
    begin
        BC14ItemLedgerEntry.DeleteAll();
        BC14ValueEntry.DeleteAll();
        ItemJournalLine.SetRange("Journal Batch Name", JournalBatchNameTxt);
        ItemJournalLine.DeleteAll();
        Item.SetFilter("No.", 'ITEM-*');
        Item.DeleteAll();
        Location.SetFilter(Code, 'MAIN');
        Location.DeleteAll();
    end;

    local procedure SetInventoryModule(Enabled: Boolean)
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
    begin
        BC14CompanySettings.DeleteAll();
        BC14CompanySettings.GetSingleInstance();
        BC14CompanySettings.Validate("Migrate Inventory Module", Enabled);
        BC14CompanySettings.Modify();
    end;

    local procedure CreateItem(ItemNo: Code[20])
    var
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        if not UnitOfMeasure.Get('PCS') then begin
            UnitOfMeasure.Init();
            UnitOfMeasure.Code := 'PCS';
            UnitOfMeasure.Insert();
        end;

        if not Item.Get(ItemNo) then begin
            Item.Init();
            Item."No." := ItemNo;
            Item."Base Unit of Measure" := 'PCS';
            Item.Insert();
        end;

        if not ItemUnitOfMeasure.Get(ItemNo, 'PCS') then begin
            ItemUnitOfMeasure.Init();
            ItemUnitOfMeasure."Item No." := ItemNo;
            ItemUnitOfMeasure.Code := 'PCS';
            ItemUnitOfMeasure."Qty. per Unit of Measure" := 1;
            ItemUnitOfMeasure.Insert();
        end;
    end;

    local procedure CreateLocation(LocationCode: Code[10])
    var
        Location: Record Location;
    begin
        if Location.Get(LocationCode) then
            exit;
        Location.Init();
        Location.Code := LocationCode;
        Location.Insert();
    end;

    local procedure InsertItemLedgerEntry(EntryNo: Integer; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; RemainingQuantity: Decimal; CostAmount: Decimal)
    var
        BC14ItemLedgerEntry: Record "BC14 Item Ledger Entry";
        BC14ValueEntry: Record "BC14 Value Entry";
    begin
        BC14ItemLedgerEntry.Init();
        BC14ItemLedgerEntry."Entry No." := EntryNo;
        BC14ItemLedgerEntry."Item No." := ItemNo;
        BC14ItemLedgerEntry."Posting Date" := WorkDate();
        BC14ItemLedgerEntry."Entry Type" := BC14ItemLedgerEntry."Entry Type"::"Positive Adjmt.";
        BC14ItemLedgerEntry."Document No." := CopyStr('IDOC-' + Format(EntryNo), 1, 20);
        BC14ItemLedgerEntry."Location Code" := LocationCode;
        BC14ItemLedgerEntry.Quantity := Quantity;
        BC14ItemLedgerEntry."Remaining Quantity" := RemainingQuantity;
        BC14ItemLedgerEntry.Open := true;
        BC14ItemLedgerEntry."Journal Batch Name" := JournalBatchNameTxt;
        BC14ItemLedgerEntry.Insert();

        if CostAmount <> 0 then begin
            BC14ValueEntry.Init();
            BC14ValueEntry."Entry No." := EntryNo;
            BC14ValueEntry."Item Ledger Entry No." := EntryNo;
            BC14ValueEntry."Item Ledger Entry Quantity" := Quantity;
            BC14ValueEntry."Cost Amount (Actual)" := CostAmount;
            BC14ValueEntry.Insert();
        end;
    end;
}
