// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation.Test;

using Microsoft.DataMigration.BC14Reimplementation;
using Microsoft.DataMigration.BC14Reimplementation.HistoricalData;

codeunit 148917 "BC14 OldItemLedgMigr Tests"
{
    // [FEATURE] [BC14 Old Item Ledger Entry Migrator]

    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    var
        Assert: Codeunit Assert;
        IsHandledFlag: Boolean;

    [Test]
    procedure TestGetDisplayName_ReturnsExpectedLabel()
    var
        BC14OldItemLedgerMigr: Codeunit "BC14 Old Item Ledger Migr.";
    begin
        Assert.AreEqual('Old Item Ledger Entry Migrator', BC14OldItemLedgerMigr.GetDisplayName(), 'Unexpected display name.');
    end;

    [Test]
    procedure TestIsEnabled_InventoryModuleDisabled_ReturnsFalse()
    var
        BC14OldItemLedgerMigr: Codeunit "BC14 Old Item Ledger Migr.";
    begin
        // [SCENARIO] The migrator opts out when the inventory module is disabled.
        Initialize();
        SetInventoryModule(false);
        InsertItemLedgerEntry(1, 'ITEM-001');

        Assert.IsFalse(BC14OldItemLedgerMigr.IsEnabled(), 'IsEnabled should be false when inventory module disabled.');
    end;

    [Test]
    procedure TestIsEnabled_BufferEmpty_ReturnsFalse()
    var
        BC14OldItemLedgerMigr: Codeunit "BC14 Old Item Ledger Migr.";
    begin
        // [SCENARIO] With no item ledger entries there is nothing to archive.
        Initialize();
        SetInventoryModule(true);

        Assert.IsFalse(BC14OldItemLedgerMigr.IsEnabled(), 'IsEnabled should be false when buffer is empty.');
    end;

    [Test]
    procedure TestIsEnabled_InventoryEnabledAndBufferHasRecords_ReturnsTrue()
    var
        BC14OldItemLedgerMigr: Codeunit "BC14 Old Item Ledger Migr.";
    begin
        // [SCENARIO] The migrator is enabled when inventory is on and there are entries to archive.
        Initialize();
        SetInventoryModule(true);
        InsertItemLedgerEntry(2, 'ITEM-002');

        Assert.IsTrue(BC14OldItemLedgerMigr.IsEnabled(), 'IsEnabled should be true.');
    end;

    [Test]
    procedure TestGetRemainingPercentage_NoRecords_ReturnsZero()
    var
        BC14OldItemLedgerMigr: Codeunit "BC14 Old Item Ledger Migr.";
    begin
        Initialize();
        Assert.AreEqual(0, BC14OldItemLedgerMigr.GetRemainingPercentage(), 'Expected 0% remaining when buffer empty.');
    end;

    [Test]
    procedure TestMigrate_HandledByEvent_ReturnsTrue()
    var
        BC14OldItemLedgerMigr: Codeunit "BC14 Old Item Ledger Migr.";
    begin
        // [SCENARIO] When OnMigrateOldItemLedgerEntries sets IsMigrated, Migrate exits true without transfer.
        Initialize();
        IsHandledFlag := true;
        BindSubscription(this);

        Assert.IsTrue(BC14OldItemLedgerMigr.Migrate(), 'Migrate should return true when handled by event.');

        UnbindSubscription(this);
    end;

    [Test]
    procedure TestMigrate_FallbackPath_ArchivesAllEntriesWithCostSummedAndMigratedOnStamped()
    var
        BC14OldItemLedgEntry: Record "BC14 Old Item Ledg. Entry";
        BC14OldItemLedgerMigr: Codeunit "BC14 Old Item Ledger Migr.";
    begin
        // [SCENARIO] The archive-only migrator copies every item ledger entry read-only, summing
        //            each entry's actual cost from its value entries and stamping Migrated On.
        Initialize();
        SetInventoryModule(true);
        InsertItemLedgerEntry(10, 'ITEM-010');
        InsertItemLedgerEntry(11, 'ITEM-011');
        InsertValueEntry(100, 10, 250);
        InsertValueEntry(101, 10, 150); // ILE 10 total actual cost = 400
        InsertValueEntry(102, 11, 75);  // ILE 11 total actual cost = 75

        Assert.IsTrue(BC14OldItemLedgerMigr.Migrate(), 'Migrate should succeed via the AL fallback path.');

        // [THEN] Every entry is archived with the summed cost and a Migrated On stamp
        Assert.AreEqual(2, BC14OldItemLedgEntry.Count(), 'All item ledger entries should be archived.');

        BC14OldItemLedgEntry.Get(10);
        Assert.AreEqual(400, BC14OldItemLedgEntry."Cost Amount (Actual)", 'Cost should be summed from value entries for entry 10.');
        Assert.AreNotEqual(0DT, BC14OldItemLedgEntry."Migrated On", 'Migrated On should be stamped.');

        BC14OldItemLedgEntry.Get(11);
        Assert.AreEqual(75, BC14OldItemLedgEntry."Cost Amount (Actual)", 'Cost should be summed from value entries for entry 11.');
    end;

    local procedure Initialize()
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        BC14ItemLedgerEntry: Record "BC14 Item Ledger Entry";
        BC14ValueEntry: Record "BC14 Value Entry";
        BC14OldItemLedgEntry: Record "BC14 Old Item Ledg. Entry";
    begin
        BC14ItemLedgerEntry.DeleteAll();
        BC14ValueEntry.DeleteAll();
        BC14OldItemLedgEntry.DeleteAll();
        BC14CompanySettings.DeleteAll();
    end;

    local procedure SetInventoryModule(Enabled: Boolean)
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        CurrentCompanyName: Text;
    begin
        CurrentCompanyName := CompanyName();
        if not BC14CompanySettings.Get(CurrentCompanyName) then begin
            BC14CompanySettings.Init();
            BC14CompanySettings.Name := CopyStr(CurrentCompanyName, 1, MaxStrLen(BC14CompanySettings.Name));
            BC14CompanySettings.Insert();
        end;
        BC14CompanySettings."Migrate Inventory Module" := Enabled;
        BC14CompanySettings.Modify();
    end;

    local procedure InsertItemLedgerEntry(EntryNo: Integer; ItemNo: Code[20])
    var
        BC14ItemLedgerEntry: Record "BC14 Item Ledger Entry";
    begin
        BC14ItemLedgerEntry.Init();
        BC14ItemLedgerEntry."Entry No." := EntryNo;
        BC14ItemLedgerEntry."Item No." := ItemNo;
        BC14ItemLedgerEntry."Posting Date" := WorkDate();
        BC14ItemLedgerEntry."Document No." := 'IDOC-' + Format(EntryNo);
        BC14ItemLedgerEntry.Quantity := 10;
        BC14ItemLedgerEntry."Remaining Quantity" := 10;
        BC14ItemLedgerEntry.Open := true;
        BC14ItemLedgerEntry.Insert();
    end;

    local procedure InsertValueEntry(EntryNo: Integer; ItemLedgerEntryNo: Integer; CostAmountActual: Decimal)
    var
        BC14ValueEntry: Record "BC14 Value Entry";
    begin
        BC14ValueEntry.Init();
        BC14ValueEntry."Entry No." := EntryNo;
        BC14ValueEntry."Item Ledger Entry No." := ItemLedgerEntryNo;
        BC14ValueEntry."Cost Amount (Actual)" := CostAmountActual;
        BC14ValueEntry.Insert();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"BC14 Old Item Ledger Migr.", 'OnMigrateOldItemLedgerEntries', '', false, false)]
    local procedure OnMigrateSubscriber(var IsMigrated: Boolean)
    begin
        IsMigrated := IsHandledFlag;
    end;
}
