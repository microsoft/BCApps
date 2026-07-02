// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation.Test;

using Microsoft.DataMigration.BC14Reimplementation;
using Microsoft.DataMigration.BC14Reimplementation.HistoricalData;

codeunit 148914 "BC14 OldGLEntryMigr Tests"
{
    // [FEATURE] [BC14 Old G/L Entry Migrator]

    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    var
        Assert: Codeunit Assert;
        IsHandledFlag: Boolean;

    [Test]
    procedure TestGetDisplayName_ReturnsExpectedLabel()
    var
        BC14OldGLEntryMigr: Codeunit "BC14 Old G/L Entry Migr.";
    begin
        Assert.AreEqual('Old G/L Entry Migrator', BC14OldGLEntryMigr.GetDisplayName(), 'Unexpected display name.');
    end;

    [Test]
    procedure TestIsEnabled_GLModuleDisabled_ReturnsFalse()
    var
        BC14OldGLEntryMigr: Codeunit "BC14 Old G/L Entry Migr.";
    begin
        Initialize();
        SetGLEnabledAndCutoff(false, WorkDate());
        InsertGLEntry(1, WorkDate() - 1);

        Assert.IsFalse(BC14OldGLEntryMigr.IsEnabled(), 'IsEnabled should return false when GL module disabled.');
    end;

    [Test]
    procedure TestIsEnabled_NoCutoff_ReturnsFalse()
    var
        BC14OldGLEntryMigr: Codeunit "BC14 Old G/L Entry Migr.";
    begin
        // [SCENARIO] Without a cutoff configured the transaction phase re-posts every entry; the
        // archive has nothing to add and the migrator must opt out.
        Initialize();
        SetGLEnabledAndCutoff(true, 0D);
        InsertGLEntry(2, WorkDate() - 1);

        Assert.IsFalse(BC14OldGLEntryMigr.IsEnabled(), 'IsEnabled should return false when cutoff is not configured.');
    end;

    [Test]
    procedure TestIsEnabled_BufferEmpty_ReturnsFalse()
    var
        BC14OldGLEntryMigr: Codeunit "BC14 Old G/L Entry Migr.";
    begin
        Initialize();
        SetGLEnabledAndCutoff(true, WorkDate());

        Assert.IsFalse(BC14OldGLEntryMigr.IsEnabled(), 'IsEnabled should return false when buffer is empty.');
    end;

    [Test]
    procedure TestIsEnabled_GLEnabledCutoffSetAndBufferHasRecords_ReturnsTrue()
    var
        BC14OldGLEntryMigr: Codeunit "BC14 Old G/L Entry Migr.";
    begin
        Initialize();
        SetGLEnabledAndCutoff(true, WorkDate());
        InsertGLEntry(3, WorkDate() - 1);

        Assert.IsTrue(BC14OldGLEntryMigr.IsEnabled(), 'IsEnabled should return true.');
    end;

    [Test]
    procedure TestGetRemainingPercentage_NoRecords_ReturnsZero()
    var
        BC14OldGLEntryMigr: Codeunit "BC14 Old G/L Entry Migr.";
    begin
        Initialize();

        Assert.AreEqual(0, BC14OldGLEntryMigr.GetRemainingPercentage(), 'Expected 0% remaining when buffer empty.');
    end;

    [Test]
    procedure TestGetRemainingPercentage_WithRecordsBeforeCutoff_Returns100()
    var
        BC14OldGLEntryMigr: Codeunit "BC14 Old G/L Entry Migr.";
    begin
        Initialize();
        SetGLEnabledAndCutoff(true, WorkDate());
        InsertGLEntry(4, WorkDate() - 1);
        InsertGLEntry(5, WorkDate() - 2);

        Assert.AreEqual(100, BC14OldGLEntryMigr.GetRemainingPercentage(), 'Expected 100% remaining when nothing archived.');
    end;

    [Test]
    procedure TestMigrate_HandledByEvent_ReturnsTrue()
    var
        BC14OldGLEntryMigr: Codeunit "BC14 Old G/L Entry Migr.";
    begin
        // [SCENARIO] When OnMigrateOldGLEntries sets IsMigrated, Migrate exits true without performing transfer.
        Initialize();
        IsHandledFlag := true;
        BindSubscription(this);

        Assert.IsTrue(BC14OldGLEntryMigr.Migrate(), 'Migrate should return true when handled by event.');

        UnbindSubscription(this);
    end;

    [Test]
    procedure TestMigrate_FallbackPath_CopiesOnlyEntriesBeforeCutoffWithMigratedOnStamped()
    var
        BC14OldGLEntry: Record "BC14 Old G/L Entry";
        BC14OldGLEntryMigr: Codeunit "BC14 Old G/L Entry Migr.";
        Cutoff: Date;
    begin
        // [SCENARIO] Outside Intelligent Cloud migration scope DataTransfer is rejected, so the
        // migrator must fall back to a per-record TransferFields copy filtered by cutoff date.
        // The test session has IC disabled by default, so calling Migrate exercises that
        // fallback path end-to-end.
        Initialize();
        Cutoff := WorkDate();
        SetGLEnabledAndCutoff(true, Cutoff);
        InsertGLEntry(10, Cutoff - 2);
        InsertGLEntry(11, Cutoff - 1);
        InsertGLEntry(12, Cutoff);     // on cutoff - excluded by '<' filter
        InsertGLEntry(13, Cutoff + 1); // after cutoff - excluded

        Assert.IsTrue(BC14OldGLEntryMigr.Migrate(), 'Migrate should succeed via the AL fallback path when IC is disabled.');

        Assert.AreEqual(2, BC14OldGLEntry.Count(), 'Only entries with posting date strictly before cutoff should be archived.');
        BC14OldGLEntry.FindFirst();
        Assert.AreNotEqual(0DT, BC14OldGLEntry."Migrated On", 'Migrated On should be stamped by the fallback path.');
    end;

    local procedure Initialize()
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        BC14GLEntry: Record "BC14 G/L Entry";
        BC14OldGLEntry: Record "BC14 Old G/L Entry";
    begin
        BC14GLEntry.DeleteAll();
        BC14OldGLEntry.DeleteAll();
        BC14CompanySettings.DeleteAll();
    end;

    local procedure SetGLEnabledAndCutoff(Enabled: Boolean; Cutoff: Date)
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        CurrentCompanyName: Text;
    begin
        // GL module enabled flag lives on the per-company row.
        CurrentCompanyName := CompanyName();
        if not BC14CompanySettings.Get(CurrentCompanyName) then begin
            BC14CompanySettings.Init();
            BC14CompanySettings.Name := CopyStr(CurrentCompanyName, 1, MaxStrLen(BC14CompanySettings.Name));
            BC14CompanySettings.Insert();
        end;
        BC14CompanySettings."Migrate GL Module" := Enabled;
        BC14CompanySettings.Modify();

        // Cutoff date lives on the template row (Name = '').
        if not BC14CompanySettings.Get('') then begin
            BC14CompanySettings.Init();
            BC14CompanySettings.Name := '';
            BC14CompanySettings.Insert();
        end;
        BC14CompanySettings."Historical Cutoff Date" := Cutoff;
        BC14CompanySettings.Modify();
    end;

    local procedure InsertGLEntry(EntryNo: Integer; PostingDate: Date)
    var
        BC14GLEntry: Record "BC14 G/L Entry";
    begin
        BC14GLEntry.Init();
        BC14GLEntry."Entry No." := EntryNo;
        BC14GLEntry."Posting Date" := PostingDate;
        BC14GLEntry.Insert();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"BC14 Old G/L Entry Migr.", 'OnMigrateOldGLEntries', '', false, false)]
    local procedure OnMigrateSubscriber(var IsMigrated: Boolean)
    begin
        IsMigrated := IsHandledFlag;
    end;
}
