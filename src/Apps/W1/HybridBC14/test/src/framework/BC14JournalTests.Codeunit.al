// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration;
using Microsoft.DataMigration.BC14Reimplementation;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using System.Integration;

codeunit 148904 "BC14 Journal Tests"
{
    // [FEATURE] [BC14 Cloud Migration Journal]
    // Merged from:
    //   - BC14 Jnl. Post Action Tests        (was 148921)
    //   - BC14 Journal Management Tests      (was 148907)
    //   - BC14 Balance Warning Tests         (was 148926)
    //   - BC14 OldGLEntryMigr Tests          (was 148923)

    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    // ============================================================
    // Journal Post Action
    // ============================================================

    [Test]
    procedure TestGetDisplayName_JnlPostAction()
    var
        BC14JournalPostAction: Codeunit "BC14 Journal Post Action";
    begin
        // [SCENARIO] GetDisplayName returns the correct action name.
        Assert.AreEqual('Journal Post', BC14JournalPostAction.GetDisplayName(), 'Display name should be Journal Post');
    end;

    [Test]
    procedure TestIsEnabled_WhenPostingNotCompleted()
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        BC14JournalPostAction: Codeunit "BC14 Journal Post Action";
    begin
        // [SCENARIO] IsEnabled returns true when Posting has not been completed yet.
        InitializeJnlPostAction();

        // [GIVEN] Default settings (Posting Completed = false)
        BC14CompanySettings.GetSingleInstance();
        Assert.IsFalse(BC14CompanySettings."Posting Completed", 'Posting should not be completed initially');

        // [THEN] Action is enabled
        Assert.IsTrue(BC14JournalPostAction.IsEnabled(), 'Should be enabled when posting not completed');
    end;

    [Test]
    procedure TestIsEnabled_WhenPostingCompleted_ReturnsFalse()
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        BC14JournalPostAction: Codeunit "BC14 Journal Post Action";
    begin
        // [SCENARIO] IsEnabled returns false when Posting has already been completed.
        InitializeJnlPostAction();

        // [GIVEN] Posting already completed
        BC14CompanySettings.GetSingleInstance();
        BC14CompanySettings.SetPostingCompleted();

        // [THEN] Action is disabled
        Assert.IsFalse(BC14JournalPostAction.IsEnabled(), 'Should be disabled when posting completed');
    end;

    [Test]
    procedure TestExecute_SkipPostingEnabled_ReturnsTrue()
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        BC14JournalPostAction: Codeunit "BC14 Journal Post Action";
        Result: Boolean;
    begin
        // [SCENARIO] Execute returns true (success) when Skip Posting is enabled, without posting anything.
        InitializeJnlPostAction();

        // [GIVEN] Skip Posting Journal Batches is enabled
        BC14CompanySettings.GetSingleInstance();
        BC14CompanySettings."Skip Posting Journal Batches" := true;
        BC14CompanySettings.Modify();

        // [WHEN] Execute is called
        Result := BC14JournalPostAction.RunAction();

        // [THEN] Returns true (skipped = success)
        Assert.IsTrue(Result, 'Should return true when posting is skipped');
    end;

    [Test]
    procedure TestCleanupInvalidJournalLines_RemovesZeroAmountLines()
    var
        GenJournalLine: Record "Gen. Journal Line";
        BC14JournalMgmt: Codeunit "BC14 Journal Management";
        BC14JournalPostAction: Codeunit "BC14 Journal Post Action";
        TemplateName: Code[10];
        CleanedCount: Integer;
    begin
        // [SCENARIO] CleanupInvalidJournalLines removes zero-amount lines from BC14 batches
        // and leaves non-zero lines untouched.
        InitializeJnlPostAction();

        // [GIVEN] A BC14 batch with mixed zero and non-zero amount lines
        TemplateName := BC14JournalMgmt.GetTemplateName();
        BC14JournalMgmt.EnsureBatchExists('BC14GL', 'Test Batch');

        InsertJournalLine(TemplateName, 'BC14GL', 10000, 0);     // zero - should be cleaned
        InsertJournalLine(TemplateName, 'BC14GL', 20000, 100);   // non-zero - should remain
        InsertJournalLine(TemplateName, 'BC14GL', 30000, 0);     // zero - should be cleaned

        // [WHEN] CleanupInvalidJournalLines is called directly
        CleanedCount := BC14JournalPostAction.CleanupInvalidJournalLines(TemplateName);

        // [THEN] Two zero-amount lines were cleaned
        Assert.AreEqual(2, CleanedCount, 'Two zero-amount lines should have been cleaned');

        // [THEN] Only the non-zero line remains
        GenJournalLine.SetRange("Journal Template Name", TemplateName);
        GenJournalLine.SetRange("Journal Batch Name", 'BC14GL');
        Assert.AreEqual(1, GenJournalLine.Count(), 'Should have 1 line remaining after cleanup');
        GenJournalLine.FindFirst();
        Assert.AreEqual(100, GenJournalLine.Amount, 'Remaining line should have Amount = 100');
    end;

    [Test]
    procedure TestCleanupInvalidJournalLines_OnlyAffectsBC14Batches()
    var
        GenJournalLine: Record "Gen. Journal Line";
        BC14JournalMgmt: Codeunit "BC14 Journal Management";
        BC14JournalPostAction: Codeunit "BC14 Journal Post Action";
        TemplateName: Code[10];
    begin
        // [SCENARIO] CleanupInvalidJournalLines only deletes lines whose batch name starts with 'BC14'.
        InitializeJnlPostAction();

        // [GIVEN] One BC14 batch and one non-BC14 batch, both with zero-amount lines
        TemplateName := BC14JournalMgmt.GetTemplateName();
        BC14JournalMgmt.EnsureBatchExists('BC14GL', 'Migration Batch');
        BC14JournalMgmt.EnsureBatchExists('OTHER', 'Other Batch');

        InsertJournalLine(TemplateName, 'BC14GL', 10000, 0);
        InsertJournalLine(TemplateName, 'OTHER', 10000, 0);

        // [WHEN] CleanupInvalidJournalLines is called
        BC14JournalPostAction.CleanupInvalidJournalLines(TemplateName);

        // [THEN] Non-BC14 batch lines are untouched
        GenJournalLine.SetRange("Journal Template Name", TemplateName);
        GenJournalLine.SetRange("Journal Batch Name", 'OTHER');
        Assert.AreEqual(1, GenJournalLine.Count(), 'Non-BC14 batch zero-amount lines should not be cleaned');
    end;

    [Test]
    procedure TestExecute_OnlyProcessesBC14Batches()
    var
        GenJournalLine: Record "Gen. Journal Line";
        BC14JournalMgmt: Codeunit "BC14 Journal Management";
        BC14JournalPostAction: Codeunit "BC14 Journal Post Action";
        TemplateName: Code[10];
    begin
        // [SCENARIO] Execute only processes journal batches whose name starts with 'BC14'.
        InitializeJnlPostAction();

        // [GIVEN] Two batches: one BC14, one non-BC14
        TemplateName := BC14JournalMgmt.GetTemplateName();
        BC14JournalMgmt.EnsureBatchExists('BC14GL', 'Migration Batch');
        BC14JournalMgmt.EnsureBatchExists('OTHER', 'Other Batch');

        InsertJournalLine(TemplateName, 'BC14GL', 10000, 0);   // BC14 batch - zero amount, will be cleaned
        InsertJournalLine(TemplateName, 'OTHER', 10000, 500);  // non-BC14 batch - should be untouched

        // [WHEN] Execute is called
        BC14JournalPostAction.RunAction();

        // [THEN] non-BC14 batch lines are untouched
        GenJournalLine.SetRange("Journal Template Name", TemplateName);
        GenJournalLine.SetRange("Journal Batch Name", 'OTHER');
        Assert.AreEqual(1, GenJournalLine.Count(), 'Non-BC14 batch lines should remain untouched');
    end;

    [Test]
    procedure TestExecute_NoBatches_ReturnsTrue()
    var
        BC14JournalPostAction: Codeunit "BC14 Journal Post Action";
        Result: Boolean;
    begin
        // [SCENARIO] Execute returns true when no BC14 journal batches exist.
        InitializeJnlPostAction();

        // [GIVEN] No BC14 batches
        // [WHEN] Execute is called
        Result := BC14JournalPostAction.RunAction();

        // [THEN] Returns true (nothing to post = success)
        Assert.IsTrue(Result, 'Should return true when no batches exist');
    end;

    [Test]
    procedure TestExecute_AllZeroAmountLines_ReturnsTrue()
    var
        BC14JournalMgmt: Codeunit "BC14 Journal Management";
        BC14JournalPostAction: Codeunit "BC14 Journal Post Action";
        TemplateName: Code[10];
        Result: Boolean;
    begin
        // [SCENARIO] Execute returns true when all lines are zero-amount (cleaned up before posting).
        InitializeJnlPostAction();

        // [GIVEN] A batch with only zero-amount lines
        TemplateName := BC14JournalMgmt.GetTemplateName();
        BC14JournalMgmt.EnsureBatchExists('BC14GL', 'Test');
        InsertJournalLine(TemplateName, 'BC14GL', 10000, 0);
        InsertJournalLine(TemplateName, 'BC14GL', 20000, 0);

        // [WHEN] Execute is called
        Result := BC14JournalPostAction.RunAction();

        // [THEN] Returns true (all cleaned, nothing to post)
        Assert.IsTrue(Result, 'Should return true when all lines are zero-amount');
    end;

    // ============================================================
    // Journal Management
    // ============================================================

    [Test]
    procedure TestGetTemplateName()
    var
        BC14JournalMgmt: Codeunit "BC14 Journal Management";
        TemplateName: Code[10];
    begin
        // [SCENARIO] GetTemplateName returns a valid template name.

        // [WHEN] GetTemplateName is called
        TemplateName := BC14JournalMgmt.GetTemplateName();

        // [THEN] A non-empty template name is returned
        Assert.AreNotEqual('', TemplateName, 'General Journal Template Name should not be empty');
    end;

    [Test]
    procedure TestEnsureBatchExists()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        BC14JournalMgmt: Codeunit "BC14 Journal Management";
        TemplateName: Code[10];
        BatchName: Code[10];
    begin
        // [SCENARIO] EnsureBatchExists creates a batch if it doesn't exist.

        // [GIVEN] A template name
        TemplateName := BC14JournalMgmt.GetTemplateName();
        BatchName := 'BC14TEST';

        // Remove batch if it exists
        if GenJournalBatch.Get(TemplateName, BatchName) then
            GenJournalBatch.Delete();

        // [WHEN] EnsureBatchExists is called
        BC14JournalMgmt.EnsureBatchExists(BatchName, 'Test Migration Batch');

        // [THEN] The batch exists with the correct values
        Assert.IsTrue(GenJournalBatch.Get(TemplateName, BatchName), 'Journal batch should exist after calling EnsureBatchExists');
        Assert.AreEqual('Test Migration Batch', GenJournalBatch.Description, 'Batch description should match');
    end;

    [Test]
    procedure TestEnsureBatchExistsIsIdempotent()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        BC14JournalMgmt: Codeunit "BC14 Journal Management";
        TemplateName: Code[10];
        BatchName: Code[10];
    begin
        // [SCENARIO] Calling EnsureBatchExists multiple times does not fail.

        // [GIVEN] A batch that already exists
        TemplateName := BC14JournalMgmt.GetTemplateName();
        BatchName := 'BC14TEST';

        BC14JournalMgmt.EnsureBatchExists(BatchName, 'Test Migration Batch');

        // [WHEN] EnsureBatchExists is called again
        BC14JournalMgmt.EnsureBatchExists(BatchName, 'Test Migration Batch');

        // [THEN] No error occurs and the batch still exists
        Assert.IsTrue(GenJournalBatch.Get(TemplateName, BatchName), 'Journal batch should still exist');
    end;

    // ============================================================
    // Balance Warning
    // ============================================================

    [Test]
    procedure TestGetDisplayName_BalanceWarning()
    var
        BC14BalanceWarning: Codeunit "BC14 Balance Warning";
    begin
        // [SCENARIO] GetDisplayName returns 'Balance Warning'.
        Assert.AreEqual('Balance Warning', BC14BalanceWarning.GetDisplayName(), 'Display name mismatch');
    end;

    [Test]
    procedure TestIsEnabled_AlwaysTrue()
    var
        BC14BalanceWarning: Codeunit "BC14 Balance Warning";
    begin
        // [SCENARIO] IsEnabled is always true (the warning runs unconditionally).
        Assert.IsTrue(BC14BalanceWarning.IsEnabled(), 'IsEnabled should always be true');
    end;

    [Test]
    procedure TestGetWarningCount_NoMismatches_ReturnsZero()
    var
        BC14BalanceWarning: Codeunit "BC14 Balance Warning";
    begin
        // [SCENARIO] GetWarningCount returns 0 when no balance-mismatch warnings exist.
        InitializeBalanceWarning();
        Assert.AreEqual(0, BC14BalanceWarning.GetWarningCount(), 'Should return 0 with no warnings');
    end;

    [Test]
    procedure TestCheckWarning_NoMismatches_ReturnsFalse()
    var
        BC14BalanceWarning: Codeunit "BC14 Balance Warning";
    begin
        // [SCENARIO] CheckWarning returns false when GetWarningCount = 0.
        InitializeBalanceWarning();
        Assert.IsFalse(BC14BalanceWarning.CheckWarning(), 'Should return false with no warnings');
    end;

    [Test]
    procedure TestExecute_BalanceMismatch_WarningInserted()
    var
        GLAccount: Record "G/L Account";
        CloudMigrationWarning: Record "Cloud Migration Warning";
        BC14BalanceWarning: Codeunit "BC14 Balance Warning";
    begin
        // [SCENARIO] Execute inserts a Cloud Migration Warning when source balance does not
        // match the BC Online balance for at least one G/L account.
        InitializeBalanceWarning();

        // [GIVEN] A posting GL Account with no entries in BC Online (balance = 0) but a
        // non-zero balance in the BC14 source buffer (debit 500, credit 0 → +500)
        GLAccount.Init();
        GLAccount."No." := 'BW-MISMATCH-1';
        GLAccount.Name := 'Mismatch Account';
        GLAccount."Account Type" := GLAccount."Account Type"::Posting;
        GLAccount.Insert();

        InsertBC14Entry('BW-MISMATCH-1', 500, 0);

        // [WHEN] Execute runs
        BC14BalanceWarning.Execute();

        // [THEN] A warning is created in the Cloud Migration Warning table
        CloudMigrationWarning.SetRange("Warning Type", CloudMigrationWarning."Warning Type"::"BC14 Balance Mismatch");
        Assert.IsFalse(CloudMigrationWarning.IsEmpty(), 'A balance-mismatch warning should be inserted');
    end;

    [Test]
    procedure TestExecute_ClearsExistingWarningsBeforeReevaluating()
    var
        GLAccount: Record "G/L Account";
        CloudMigrationWarning: Record "Cloud Migration Warning";
        BC14BalanceWarning: Codeunit "BC14 Balance Warning";
        WarningCountAfterFirstRun: Integer;
    begin
        // [SCENARIO] Execute clears prior balance-mismatch warnings before re-evaluating,
        // so repeated invocations do not accumulate stale warnings.
        InitializeBalanceWarning();

        // [GIVEN] A mismatched account causes a warning to be inserted
        GLAccount.Init();
        GLAccount."No." := 'BW-CLEAR-1';
        GLAccount.Name := 'Clear Test';
        GLAccount."Account Type" := GLAccount."Account Type"::Posting;
        GLAccount.Insert();
        InsertBC14Entry('BW-CLEAR-1', 200, 0);

        BC14BalanceWarning.Execute();
        CloudMigrationWarning.SetRange("Warning Type", CloudMigrationWarning."Warning Type"::"BC14 Balance Mismatch");
        WarningCountAfterFirstRun := CloudMigrationWarning.Count();
        Assert.IsTrue(WarningCountAfterFirstRun >= 1, 'First run should create at least one warning');

        // [WHEN] Execute is called a second time with the same data
        BC14BalanceWarning.Execute();

        // [THEN] Total warnings did not grow (existing were cleared, then re-evaluated)
        CloudMigrationWarning.SetRange("Warning Type", CloudMigrationWarning."Warning Type"::"BC14 Balance Mismatch");
        Assert.AreEqual(WarningCountAfterFirstRun, CloudMigrationWarning.Count(),
            'Repeated Execute should not accumulate stale warnings');
    end;

    // ============================================================
    // Old G/L Entry Migration
    // ============================================================

    [Test]
    procedure TestGetDisplayName_ReturnsExpectedLabel()
    var
        BC14OldGLEntryMigr: Codeunit "BC14 Old G/L Entry Migr.";
    begin
        InitializeOldGLEntryMigr();
        Assert.AreEqual('Old G/L Entry Migrator', BC14OldGLEntryMigr.GetDisplayName(), 'Display name should match the migrator label');
    end;

    [Test]
    procedure TestIsEnabled_GLModuleDisabled_ReturnsFalse()
    var
        BC14OldGLEntryMigr: Codeunit "BC14 Old G/L Entry Migr.";
    begin
        // [GIVEN] GL module disabled, cutoff date set, buffer has entries
        InitializeOldGLEntryMigr();
        SetGLModuleEnabled(false);
        SetHistoricalCutoffDate(DMY2Date(1, 1, 2024));
        InsertGLEntry(1, DMY2Date(1, 6, 2023));

        // [WHEN] IsEnabled is checked
        // [THEN] Returns false because GL module is disabled
        Assert.IsFalse(BC14OldGLEntryMigr.IsEnabled(), 'IsEnabled should return false when GL module is disabled');
    end;

    [Test]
    procedure TestIsEnabled_NoCutoffDate_ReturnsFalse()
    var
        BC14OldGLEntryMigr: Codeunit "BC14 Old G/L Entry Migr.";
    begin
        // [GIVEN] GL module enabled, no cutoff date (0D), buffer has entries
        InitializeOldGLEntryMigr();
        SetHistoricalCutoffDate(0D);
        InsertGLEntry(1, DMY2Date(1, 6, 2023));

        // [WHEN] IsEnabled is checked
        // [THEN] Returns false because no cutoff means transaction phase handles everything
        Assert.IsFalse(BC14OldGLEntryMigr.IsEnabled(), 'IsEnabled should return false when no cutoff date is configured');
    end;

    [Test]
    procedure TestIsEnabled_NoBufferEntries_ReturnsFalse()
    var
        BC14OldGLEntryMigr: Codeunit "BC14 Old G/L Entry Migr.";
    begin
        // [GIVEN] GL module enabled, cutoff date set, no buffer entries
        InitializeOldGLEntryMigr();
        SetHistoricalCutoffDate(DMY2Date(1, 1, 2024));

        // [WHEN] IsEnabled is checked
        // [THEN] Returns false because there is nothing to migrate
        Assert.IsFalse(BC14OldGLEntryMigr.IsEnabled(), 'IsEnabled should return false when buffer is empty');
    end;

    [Test]
    procedure TestIsEnabled_AllConditionsMet_ReturnsTrue()
    var
        BC14OldGLEntryMigr: Codeunit "BC14 Old G/L Entry Migr.";
    begin
        // [GIVEN] GL module enabled, cutoff date set, buffer has at least one entry
        InitializeOldGLEntryMigr();
        SetHistoricalCutoffDate(DMY2Date(1, 1, 2024));
        InsertGLEntry(1, DMY2Date(1, 6, 2023));

        // [WHEN] IsEnabled is checked
        // [THEN] Returns true
        Assert.IsTrue(BC14OldGLEntryMigr.IsEnabled(), 'IsEnabled should return true when all conditions are met');
    end;

    [Test]
    procedure TestGetRemainingPercentage_NoBufferEntries_ReturnsZero()
    var
        BC14OldGLEntryMigr: Codeunit "BC14 Old G/L Entry Migr.";
    begin
        // [GIVEN] Cutoff date set, no entries to migrate
        InitializeOldGLEntryMigr();
        SetHistoricalCutoffDate(DMY2Date(1, 1, 2024));

        // [WHEN] GetRemainingPercentage is queried
        // [THEN] Returns 0 because TotalCount = 0
        Assert.AreEqual(0, BC14OldGLEntryMigr.GetRemainingPercentage(), 'Remaining percentage should be 0 when buffer has no rows');
    end;

    [Test]
    procedure TestGetRemainingPercentage_BufferFullAndArchiveEmpty_Returns100()
    var
        BC14OldGLEntryMigr: Codeunit "BC14 Old G/L Entry Migr.";
    begin
        // [GIVEN] Cutoff date set, multiple entries pre-cutoff, archive empty
        InitializeOldGLEntryMigr();
        SetHistoricalCutoffDate(DMY2Date(1, 1, 2024));
        InsertGLEntry(1, DMY2Date(1, 1, 2023));
        InsertGLEntry(2, DMY2Date(2, 1, 2023));
        InsertGLEntry(3, DMY2Date(3, 1, 2023));

        // [WHEN] GetRemainingPercentage is queried
        // [THEN] Returns 100 because none of the entries have been archived yet
        Assert.AreEqual(100, BC14OldGLEntryMigr.GetRemainingPercentage(), 'Remaining percentage should be 100 when nothing has been archived');
    end;

    [Test]
    procedure TestGetRemainingPercentage_CutoffFilterExcludesPostCutoffEntries()
    var
        BC14OldGLEntryMigr: Codeunit "BC14 Old G/L Entry Migr.";
    begin
        // [GIVEN] Cutoff date 2024-01-01, two entries pre-cutoff, two entries on/after cutoff
        InitializeOldGLEntryMigr();
        SetHistoricalCutoffDate(DMY2Date(1, 1, 2024));
        InsertGLEntry(1, DMY2Date(1, 1, 2023));   // pre-cutoff (counts)
        InsertGLEntry(2, DMY2Date(31, 12, 2023)); // pre-cutoff (counts)
        InsertGLEntry(3, DMY2Date(1, 1, 2024));   // on cutoff (excluded)
        InsertGLEntry(4, DMY2Date(15, 6, 2024));  // post-cutoff (excluded)

        // [WHEN] GetRemainingPercentage is queried, archive still empty
        // [THEN] Returns 100 because only the two pre-cutoff entries are counted as remaining
        // (and 2/2 are still unarchived). This proves the cutoff filter is applied symmetrically
        // to TotalCount.
        Assert.AreEqual(100, BC14OldGLEntryMigr.GetRemainingPercentage(), 'Cutoff filter should exclude entries on or after the cutoff date');
    end;

    // ============================================================
    // Helpers - Journal Post Action
    // ============================================================

    local procedure InitializeJnlPostAction()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        DataMigrationError: Record "Data Migration Error";
    begin
        // Clean up BC14 journal data
        GenJournalLine.SetFilter("Journal Template Name", 'BC14*');
        if not GenJournalLine.IsEmpty() then
            GenJournalLine.DeleteAll();
        GenJournalLine.Reset();
        GenJournalLine.SetRange("Journal Template Name", 'BC14MIG');
        if not GenJournalLine.IsEmpty() then
            GenJournalLine.DeleteAll();

        GenJournalBatch.SetRange("Journal Template Name", 'BC14MIG');
        if not GenJournalBatch.IsEmpty() then
            GenJournalBatch.DeleteAll();

        if GenJournalTemplate.Get('BC14MIG') then
            GenJournalTemplate.Delete();

        BC14CompanySettings.DeleteAll();

        // Clean up migration errors logged by previous test runs of the post action,
        // so failure-isolation assertions count only errors from the current scenario.
        DataMigrationError.SetFilter("Migration Type", 'Journal Posting -*');
        if not DataMigrationError.IsEmpty() then
            DataMigrationError.DeleteAll();
    end;

    local procedure InsertJournalLine(TemplateName: Code[10]; BatchName: Code[10]; LineNo: Integer; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.Init();
        GenJournalLine."Journal Template Name" := TemplateName;
        GenJournalLine."Journal Batch Name" := BatchName;
        GenJournalLine."Line No." := LineNo;
        GenJournalLine.Amount := Amount;
        GenJournalLine."Posting Date" := WorkDate();
        GenJournalLine.Insert();
    end;

    // ============================================================
    // Helpers - Balance Warning
    // ============================================================

    local procedure InitializeBalanceWarning()
    var
        CloudMigrationWarning: Record "Cloud Migration Warning";
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        BC14GLEntry: Record "BC14 G/L Entry";
        GLAccount: Record "G/L Account";
    begin
        CloudMigrationWarning.SetRange("Warning Type", CloudMigrationWarning."Warning Type"::"BC14 Balance Mismatch");
        CloudMigrationWarning.DeleteAll();
        HybridReplicationSummary.DeleteAll();
        BC14GLEntry.SetFilter("G/L Account No.", 'BW-*');
        BC14GLEntry.DeleteAll();
        GLAccount.SetFilter("No.", 'BW-*');
        GLAccount.DeleteAll();
    end;

    local procedure InsertBC14Entry(GLAccountNo: Code[20]; DebitAmount: Decimal; CreditAmount: Decimal)
    var
        BC14GLEntry: Record "BC14 G/L Entry";
        NextEntryNo: Integer;
    begin
        BC14GLEntry.SetCurrentKey("Entry No.");
        if BC14GLEntry.FindLast() then
            NextEntryNo := BC14GLEntry."Entry No." + 1
        else
            NextEntryNo := 1;

        BC14GLEntry.Init();
        BC14GLEntry."Entry No." := NextEntryNo;
        BC14GLEntry."G/L Account No." := GLAccountNo;
        BC14GLEntry."Debit Amount" := DebitAmount;
        BC14GLEntry."Credit Amount" := CreditAmount;
        BC14GLEntry."Posting Date" := WorkDate();
        BC14GLEntry.Insert();
    end;

    // ============================================================
    // Helpers - Old G/L Entry Migration
    // ============================================================

    local procedure InitializeOldGLEntryMigr()
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        BC14GlobalSettings: Record "BC14 Global Migration Settings";
        BC14GLEntry: Record "BC14 G/L Entry";
    begin
        BC14CompanySettings.DeleteAll();
        BC14GlobalSettings.DeleteAll();
        BC14GLEntry.DeleteAll();

        BC14CompanySettings.Init();
        BC14CompanySettings.Name := CopyStr(CompanyName(), 1, MaxStrLen(BC14CompanySettings.Name));
        BC14CompanySettings."Migrate GL Module" := true;
        BC14CompanySettings.Insert();
    end;

    local procedure SetGLModuleEnabled(Enabled: Boolean)
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
    begin
        BC14CompanySettings.GetSingleInstance();
        BC14CompanySettings."Migrate GL Module" := Enabled;
        BC14CompanySettings.Modify();
    end;

    local procedure SetHistoricalCutoffDate(CutoffDate: Date)
    var
        BC14CompanyInfo: Record BC14CompanyMigrationInfo;
    begin
        if not BC14CompanyInfo.Get('') then begin
            BC14CompanyInfo.Init();
            BC14CompanyInfo.Name := '';
            BC14CompanyInfo.Insert();
        end;
        BC14CompanyInfo."Historical Cutoff Date" := CutoffDate;
        BC14CompanyInfo.Modify();
    end;

    local procedure InsertGLEntry(EntryNo: Integer; PostingDate: Date)
    var
        BC14GLEntry: Record "BC14 G/L Entry";
    begin
        BC14GLEntry.Init();
        BC14GLEntry."Entry No." := EntryNo;
        BC14GLEntry."Posting Date" := PostingDate;
        BC14GLEntry."G/L Account No." := '10000';
        BC14GLEntry.Amount := 100;
        BC14GLEntry.Insert();
    end;
}
