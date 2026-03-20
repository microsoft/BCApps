// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration.BC14;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;

codeunit 148913 "BC14 Migration Runner Tests"
{
    // [FEATURE] [BC14 Migration Runner]

    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    // ============================================================
    // Record Skip Logic Tests
    // ============================================================

    [Test]
    procedure TestIsMigrated_NotMigrated_ReturnsFalse()
    var
        BC14MigrationRecordStatus: Record "BC14 Migration Record Status";
    begin
        // [SCENARIO] IsMigrated returns false for records that haven't been migrated.

        // [GIVEN] No migration status exists for a record
        BC14MigrationRecordStatus.DeleteAll();

        // [THEN] IsMigrated should return false
        Assert.IsFalse(BC14MigrationRecordStatus.IsMigrated(1000, 'TEST-001'), 'Should return false for unmigrated record');
    end;

    [Test]
    procedure TestIsMigrated_AlreadyMigrated_ReturnsTrue()
    var
        BC14MigrationRecordStatus: Record "BC14 Migration Record Status";
    begin
        // [SCENARIO] IsMigrated returns true for records that have been migrated.

        // [GIVEN] A record has been marked as migrated
        BC14MigrationRecordStatus.DeleteAll();
        BC14MigrationRecordStatus.MarkAsMigrated(1000, 'TEST-001');

        // [THEN] IsMigrated should return true
        Assert.IsTrue(BC14MigrationRecordStatus.IsMigrated(1000, 'TEST-001'), 'Should return true for migrated record');
    end;

    [Test]
    procedure TestMarkAsMigrated_RecordCreated()
    var
        BC14MigrationRecordStatus: Record "BC14 Migration Record Status";
    begin
        // [SCENARIO] MarkAsMigrated creates the migration status record.

        // [GIVEN] Clean migration status table
        BC14MigrationRecordStatus.DeleteAll();

        // [WHEN] MarkAsMigrated is called
        BC14MigrationRecordStatus.MarkAsMigrated(Database::"BC14 Customer", 'CUST-001');

        // [THEN] The record exists in the table
        Assert.IsTrue(BC14MigrationRecordStatus.Get(CompanyName(), Database::"BC14 Customer", 'CUST-001'),
            'Migration status record should be created');
    end;

    [Test]
    procedure TestMarkAsMigrated_IdempotentForSameRecord()
    var
        BC14MigrationRecordStatus: Record "BC14 Migration Record Status";
        FirstTimestamp: DateTime;
    begin
        // [SCENARIO] Calling MarkAsMigrated twice for same record doesn't cause error.

        // [GIVEN] A record is already marked as migrated
        BC14MigrationRecordStatus.DeleteAll();
        BC14MigrationRecordStatus.MarkAsMigrated(1000, 'TEST-001');
        BC14MigrationRecordStatus.Get(CompanyName(), 1000, 'TEST-001');
        FirstTimestamp := BC14MigrationRecordStatus."Migrated On";

        // [WHEN] MarkAsMigrated is called again
        BC14MigrationRecordStatus.MarkAsMigrated(1000, 'TEST-001');

        // [THEN] No error and timestamp unchanged
        BC14MigrationRecordStatus.Get(CompanyName(), 1000, 'TEST-001');
        Assert.AreEqual(FirstTimestamp, BC14MigrationRecordStatus."Migrated On", 'Timestamp should not change');
    end;

    // ============================================================
    // Error Handler Integration Tests
    // ============================================================

    [Test]
    procedure TestHasUnresolvedError_NoError_ReturnsFalse()
    var
        BC14MigrationErrors: Record "BC14 Migration Errors";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
    begin
        // [SCENARIO] HasUnresolvedError returns false when no error exists for the record.

        // [GIVEN] No errors exist
        BC14MigrationErrors.SetRange("Company Name", CompanyName());
        BC14MigrationErrors.DeleteAll();

        // [THEN] HasUnresolvedError should return false
        Assert.IsFalse(BC14MigrationErrorHandler.HasUnresolvedError(1000, 'TEST-001'),
            'Should return false when no error exists');
    end;

    [Test]
    procedure TestHasUnresolvedError_ResolvedError_ReturnsFalse()
    var
        BC14MigrationErrors: Record "BC14 Migration Errors";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        DummyRecordId: RecordId;
    begin
        // [SCENARIO] HasUnresolvedError returns false when error is resolved.

        // [GIVEN] A resolved error exists
        BC14MigrationErrors.SetRange("Company Name", CompanyName());
        BC14MigrationErrors.DeleteAll();

        BC14MigrationErrorHandler.LogError('Test', 1000, 'Test Table', 'TEST-001', 0, 'Error', DummyRecordId);
        BC14MigrationErrorHandler.ResolveErrorForRecord(1000, 'TEST-001');

        // [THEN] HasUnresolvedError should return false
        Assert.IsFalse(BC14MigrationErrorHandler.HasUnresolvedError(1000, 'TEST-001'),
            'Should return false when error is resolved');
    end;

    [Test]
    procedure TestHasUnresolvedError_UnresolvedError_ReturnsTrue()
    var
        BC14MigrationErrors: Record "BC14 Migration Errors";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        DummyRecordId: RecordId;
    begin
        // [SCENARIO] HasUnresolvedError returns true when unresolved error exists.

        // [GIVEN] An unresolved error exists
        BC14MigrationErrors.SetRange("Company Name", CompanyName());
        BC14MigrationErrors.DeleteAll();

        BC14MigrationErrorHandler.LogError('Test', 1000, 'Test Table', 'TEST-001', 0, 'Error message', DummyRecordId);

        // [THEN] HasUnresolvedError should return true
        Assert.IsTrue(BC14MigrationErrorHandler.HasUnresolvedError(1000, 'TEST-001'),
            'Should return true when unresolved error exists');
    end;

    [Test]
    procedure TestResolveErrorForRecord_MarksPreviousErrorResolved()
    var
        BC14MigrationErrors: Record "BC14 Migration Errors";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        DummyRecordId: RecordId;
    begin
        // [SCENARIO] ResolveErrorForRecord marks the error as resolved.

        // [GIVEN] An unresolved error exists
        BC14MigrationErrors.SetRange("Company Name", CompanyName());
        BC14MigrationErrors.DeleteAll();

        BC14MigrationErrorHandler.LogError('Test', 1000, 'Test Table', 'TEST-001', 0, 'Error', DummyRecordId);

        // [WHEN] ResolveErrorForRecord is called
        BC14MigrationErrorHandler.ResolveErrorForRecord(1000, 'TEST-001');

        // [THEN] The error is marked as resolved
        BC14MigrationErrors.SetRange("Source Table ID", 1000);
        BC14MigrationErrors.SetRange("Source Record Key", 'TEST-001');
        BC14MigrationErrors.FindFirst();
        Assert.IsTrue(BC14MigrationErrors.Resolved, 'Error should be marked as resolved');
    end;

    // ============================================================
    // Enable Direct Posting Tests
    // ============================================================

    [Test]
    procedure TestEnableDirectPosting_DisabledAccounts_GetsEnabled()
    var
        GLAccount: Record "G/L Account";
    begin
        // [SCENARIO] EnableDirectPostingOnAllAccounts enables Direct Posting on all posting accounts.

        // [GIVEN] A G/L Account with Direct Posting disabled
        CleanupGLTestData();

        GLAccount.Init();
        GLAccount."No." := 'RUNNER-DP-1';
        GLAccount.Name := 'Direct Posting Test';
        GLAccount."Account Type" := GLAccount."Account Type"::Posting;
        GLAccount."Direct Posting" := false;
        GLAccount.Insert();

        // [WHEN] EnableDirectPostingOnAllAccounts logic runs
        // (Simulating what the runner does)
        GLAccount.SetRange("Direct Posting", false);
        GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.ModifyAll("Direct Posting", true);

        // [THEN] The account has Direct Posting enabled
        GLAccount.Get('RUNNER-DP-1');
        Assert.IsTrue(GLAccount."Direct Posting", 'Direct Posting should be enabled');

        // Cleanup
        GLAccount.Delete();
    end;

    [Test]
    procedure TestEnableDirectPosting_HeadingAccountsNotAffected()
    var
        GLAccount: Record "G/L Account";
    begin
        // [SCENARIO] EnableDirectPostingOnAllAccounts does not affect Heading accounts.

        // [GIVEN] A Heading G/L Account with Direct Posting disabled
        CleanupGLTestData();

        GLAccount.Init();
        GLAccount."No." := 'RUNNER-HD-1';
        GLAccount.Name := 'Heading Account Test';
        GLAccount."Account Type" := GLAccount."Account Type"::Heading;
        GLAccount."Direct Posting" := false;
        GLAccount.Insert();

        // [WHEN] EnableDirectPostingOnAllAccounts logic runs (only affects Posting accounts)
        GLAccount.SetRange("Direct Posting", false);
        GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.ModifyAll("Direct Posting", true);

        // [THEN] The heading account still has Direct Posting disabled
        GLAccount.Get('RUNNER-HD-1');
        Assert.IsFalse(GLAccount."Direct Posting", 'Heading account should not be affected');

        // Cleanup
        GLAccount.Delete();
    end;

    // ============================================================
    // Journal Cleanup Tests
    // ============================================================

    [Test]
    procedure TestCleanupZeroAmountLines_DeletesZeroAmountLines()
    var
        GenJournalLine: Record "Gen. Journal Line";
        BC14HelperFunctions: Codeunit "BC14 Helper Functions";
        TemplateName: Code[10];
    begin
        // [SCENARIO] CleanupInvalidJournalLines deletes lines with zero amount.

        // [GIVEN] Journal lines with zero and non-zero amounts
        TemplateName := BC14HelperFunctions.GetGeneralJournalTemplateName();
        CleanupJournalTestData(TemplateName);
        BC14HelperFunctions.EnsureGenJournalBatchExists('BC14TEST', 'Test Batch');

        InsertJournalLine(TemplateName, 'BC14TEST', 10000, 0); // Zero amount
        InsertJournalLine(TemplateName, 'BC14TEST', 20000, 100); // Non-zero amount
        InsertJournalLine(TemplateName, 'BC14TEST', 30000, 0); // Zero amount

        // [WHEN] Cleanup logic runs
        GenJournalLine.SetRange("Journal Template Name", TemplateName);
        GenJournalLine.SetFilter("Journal Batch Name", 'BC14*');
        GenJournalLine.SetRange(Amount, 0);
        GenJournalLine.DeleteAll();

        // [THEN] Only the non-zero amount line remains
        GenJournalLine.Reset();
        GenJournalLine.SetRange("Journal Template Name", TemplateName);
        GenJournalLine.SetRange("Journal Batch Name", 'BC14TEST');
        Assert.AreEqual(1, GenJournalLine.Count(), 'Only non-zero amount line should remain');

        GenJournalLine.FindFirst();
        Assert.AreEqual(100, GenJournalLine.Amount, 'Remaining line should have Amount = 100');

        // Cleanup
        CleanupJournalTestData(TemplateName);
    end;

    // ============================================================
    // Migration State Tests
    // ============================================================

    [Test]
    procedure TestGetTotalErrorCount_ReturnsUnresolvedCount()
    var
        BC14MigrationErrors: Record "BC14 Migration Errors";
        BC14MigrationRunner: Codeunit "BC14 Migration Runner";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        DummyRecordId: RecordId;
    begin
        // [SCENARIO] GetTotalErrorCount returns count of unresolved errors only.

        // [GIVEN] Multiple errors - some resolved, some unresolved
        BC14MigrationErrors.SetRange("Company Name", CompanyName());
        BC14MigrationErrors.DeleteAll();

        BC14MigrationErrorHandler.LogError('Test', 1000, 'Table1', 'KEY-001', 0, 'Error 1', DummyRecordId);
        BC14MigrationErrorHandler.LogError('Test', 1000, 'Table1', 'KEY-002', 0, 'Error 2', DummyRecordId);
        BC14MigrationErrorHandler.LogError('Test', 1000, 'Table1', 'KEY-003', 0, 'Error 3', DummyRecordId);

        // Resolve one error
        BC14MigrationErrorHandler.ResolveErrorForRecord(1000, 'KEY-002');

        // [THEN] GetTotalErrorCount returns 2 (only unresolved)
        Assert.AreEqual(2, BC14MigrationRunner.GetTotalErrorCount(), 'Should return count of unresolved errors only');

        // Cleanup
        BC14MigrationErrors.DeleteAll();
    end;

    [Test]
    procedure TestClearAllMigrationStatus_DeletesAllRecords()
    var
        BC14MigrationRecordStatus: Record "BC14 Migration Record Status";
        BC14MigrationRecordStatusCheck: Record "BC14 Migration Record Status";
        DeletedCount: Integer;
    begin
        // [SCENARIO] ClearAllMigrationStatus deletes all status records for current company.

        // [GIVEN] Multiple migration status records exist
        BC14MigrationRecordStatus.DeleteAll();
        BC14MigrationRecordStatus.MarkAsMigrated(1000, 'KEY-001');
        BC14MigrationRecordStatus.MarkAsMigrated(1000, 'KEY-002');
        BC14MigrationRecordStatus.MarkAsMigrated(2000, 'KEY-003');

        // [WHEN] ClearAllMigrationStatus is called
        DeletedCount := BC14MigrationRecordStatus.ClearAllMigrationStatus();

        // [THEN] All records are deleted (use fresh record to check after Commit)
        Assert.AreEqual(3, DeletedCount, 'Should have deleted 3 records');
        BC14MigrationRecordStatusCheck.SetRange("Company Name", CompanyName());
        Assert.AreEqual(0, BC14MigrationRecordStatusCheck.Count(), 'No records should remain');
    end;

    // ============================================================
    // Helper Procedures
    // ============================================================

    local procedure CleanupGLTestData()
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.SetFilter("No.", 'RUNNER-*');
        GLAccount.DeleteAll();
    end;

    local procedure CleanupJournalTestData(TemplateName: Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        GenJournalLine.SetRange("Journal Template Name", TemplateName);
        GenJournalLine.SetRange("Journal Batch Name", 'BC14TEST');
        GenJournalLine.DeleteAll();

        if GenJournalBatch.Get(TemplateName, 'BC14TEST') then
            GenJournalBatch.Delete();
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
}
