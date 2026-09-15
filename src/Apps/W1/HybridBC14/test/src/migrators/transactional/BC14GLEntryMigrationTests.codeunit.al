// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration.BC14Reimplementation;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;

codeunit 148903 "BC14 GL Entry Migration Tests"
{
    // [FEATURE] [BC14 Cloud Migration GL Entry Upgrade]

    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        JournalBatchNameTxt: Label 'BC14GL', Locked = true;

    [Test]
    procedure TestGLEntryMigrationCreatesJournalLine()
    var
        BC14GLEntry: Record "BC14 G/L Entry";
        GenJournalLine: Record "Gen. Journal Line";
        BC14JournalMgmt: Codeunit "BC14 Journal Management";
        BC14GLEntryMigrator: Codeunit "BC14 G/L Entry Migrator";
    begin
        // [SCENARIO] G/L Entry migration creates a journal line with correct field values.

        // [GIVEN] A G/L Account exists and a G/L Entry exists in the buffer table
        CleanupTestData();
        EnableGLModule();
        CreateGLAccount('GLACC-TEST', 'Test Account');
        BC14JournalMgmt.EnsureBatchExists(JournalBatchNameTxt, 'BC14 G/L Entry Migration');

        BC14GLEntry.Init();
        BC14GLEntry."Entry No." := 1;
        BC14GLEntry."G/L Account No." := 'GLACC-TEST';
        BC14GLEntry."Posting Date" := WorkDate();
        BC14GLEntry."Document No." := 'DOC-001';
        BC14GLEntry.Description := 'Test Entry';
        BC14GLEntry.Amount := 1000;
        BC14GLEntry."Journal Batch Name" := JournalBatchNameTxt;
        BC14GLEntry.Insert();

        // [WHEN] The G/L Entry Migrator runs the migration
        BC14GLEntryMigrator.CreateJournalLine(BC14GLEntry);

        // [THEN] A journal line is created with correct values
        GenJournalLine.SetRange("Journal Batch Name", JournalBatchNameTxt);
        GenJournalLine.SetRange("Account No.", 'GLACC-TEST');
        Assert.IsTrue(GenJournalLine.FindFirst(), 'Journal line should be created');

        Assert.AreEqual(GenJournalLine."Account Type"::"G/L Account", GenJournalLine."Account Type", 'Account Type should be G/L Account');
        Assert.AreEqual('GLACC-TEST', GenJournalLine."Account No.", 'Account No. should match');
        Assert.AreEqual(WorkDate(), GenJournalLine."Posting Date", 'Posting Date should match');
        Assert.AreEqual('DOC-001', GenJournalLine."Document No.", 'Document No. should match');
        Assert.AreEqual('Test Entry', GenJournalLine.Description, 'Description should match');
        Assert.AreEqual(1000, GenJournalLine.Amount, 'Amount should match');
    end;

    [Test]
    procedure TestGLEntryMigrationMultipleEntries()
    var
        BC14GLEntry: Record "BC14 G/L Entry";
        GenJournalLine: Record "Gen. Journal Line";
        BC14JournalMgmt: Codeunit "BC14 Journal Management";
        BC14GLEntryMigrator: Codeunit "BC14 G/L Entry Migrator";
    begin
        // [SCENARIO] Multiple G/L entries in the buffer table all create journal lines.

        // [GIVEN] 3 G/L Entry records exist in the buffer table
        CleanupTestData();
        EnableGLModule();
        CreateGLAccount('GLACC-MULTI', 'Multi Account');
        BC14JournalMgmt.EnsureBatchExists(JournalBatchNameTxt, 'BC14 G/L Entry Migration');

        InsertBC14GLEntry(1, 'GLACC-MULTI', 500, 'Entry 1');
        InsertBC14GLEntry(2, 'GLACC-MULTI', 300, 'Entry 2');
        InsertBC14GLEntry(3, 'GLACC-MULTI', 200, 'Entry 3');

        // [WHEN] The G/L Entry Migrator runs the migration for each entry
        BC14GLEntry.FindSet();
        repeat
            BC14GLEntryMigrator.CreateJournalLine(BC14GLEntry);
        until BC14GLEntry.Next() = 0;

        // [THEN] 3 journal lines are created
        GenJournalLine.SetRange("Journal Batch Name", JournalBatchNameTxt);
        GenJournalLine.SetRange("Account No.", 'GLACC-MULTI');
        Assert.AreEqual(3, GenJournalLine.Count(), 'Should have 3 journal lines');
    end;

    [Test]
    procedure TestGLEntryMigratorIsDisabledWhenModuleDisabled()
    var
        BC14CompanyMigrationInfo: Record "BC14CompanyMigrationInfo";
        BC14GLEntryMigrator: Codeunit "BC14 G/L Entry Migrator";
    begin
        // [SCENARIO] G/L Entry Migrator reports disabled when the GL module is disabled.

        // [GIVEN] The GL module is disabled
        BC14CompanyMigrationInfo.DeleteAll();
        BC14CompanyMigrationInfo.GetSingleInstance();
        BC14CompanyMigrationInfo.Validate("Migrate GL Module", false);
        BC14CompanyMigrationInfo.Modify();

        // [THEN] IsEnabled should return false
        Assert.IsFalse(BC14GLEntryMigrator.IsEnabled(), 'GL Entry Migrator should be disabled when GL module is disabled');
    end;

    [Test]
    procedure TestGLEntryMigratorIsEnabledByDefault()
    var
        BC14CompanyMigrationInfo: Record "BC14CompanyMigrationInfo";
        BC14GLEntryMigrator: Codeunit "BC14 G/L Entry Migrator";
    begin
        // [SCENARIO] The G/L Entry Migrator is enabled by default.

        // [GIVEN] Default settings are used
        BC14CompanyMigrationInfo.DeleteAll();

        // [THEN] IsEnabled should return true
        Assert.IsTrue(BC14GLEntryMigrator.IsEnabled(), 'GL Entry Migrator should be enabled by default');
    end;

    [Test]
    procedure TestGLEntryMigratorName()
    var
        BC14GLEntryMigrator: Codeunit "BC14 G/L Entry Migrator";
    begin
        // [SCENARIO] GetDisplayName returns the correct migrator name.

        // [THEN] The name should be 'G/L Entry Migrator'
        Assert.AreEqual('G/L Entry Migrator', BC14GLEntryMigrator.GetDisplayName(), 'Migrator display name should be G/L Entry Migrator');
    end;

    [Test]
    procedure TestGLEntryMigratorGetRemainingPercentage()
    var
        BC14GLEntryMigrator: Codeunit "BC14 G/L Entry Migrator";
    begin
        // [SCENARIO] GetRemainingPercentage returns a valid percentage.

        // [GIVEN] No migration has been performed
        CleanupTestData();

        // [THEN] Remaining percentage should be a valid value
        Assert.IsTrue(BC14GLEntryMigrator.GetRemainingPercentage() >= 0, 'Remaining percentage should be >= 0');
    end;

    [Test]
    procedure TestGLEntryMigrationRecordCountFilterZeroAmounts()
    var
        BC14GLEntry: Record "BC14 G/L Entry";
    begin
        // [SCENARIO] Buffer table count excludes zero-amount entries when filtered.

        // [GIVEN] 2 records with non-zero amounts and 1 record with zero amount exist in the buffer table
        CleanupTestData();
        CreateGLAccount('GLACC-CNT', 'Count Account');

        InsertBC14GLEntry(1, 'GLACC-CNT', 500, 'Non-zero 1');
        InsertBC14GLEntry(2, 'GLACC-CNT', 0, 'Zero amount');
        InsertBC14GLEntry(3, 'GLACC-CNT', 300, 'Non-zero 2');

        // [THEN] Filtering out zero amounts should return 2
        BC14GLEntry.SetFilter(Amount, '<>%1', 0);
        Assert.AreEqual(2, BC14GLEntry.Count(), 'Count should return 2 (excluding zero-amount entry)');
    end;

    [Test]
    procedure TestGLEntryMigrationNegativeAmount()
    var
        BC14GLEntry: Record "BC14 G/L Entry";
        GenJournalLine: Record "Gen. Journal Line";
        BC14JournalMgmt: Codeunit "BC14 Journal Management";
        BC14GLEntryMigrator: Codeunit "BC14 G/L Entry Migrator";
    begin
        // [SCENARIO] G/L Entry with negative amount is correctly migrated.

        // [GIVEN] A G/L Entry with negative Amount exists in the buffer table
        CleanupTestData();
        EnableGLModule();
        CreateGLAccount('GLACC-NEG', 'Negative Account');
        BC14JournalMgmt.EnsureBatchExists(JournalBatchNameTxt, 'BC14 G/L Entry Migration');

        BC14GLEntry.Init();
        BC14GLEntry."Entry No." := 100;
        BC14GLEntry."G/L Account No." := 'GLACC-NEG';
        BC14GLEntry."Posting Date" := WorkDate();
        BC14GLEntry."Document No." := 'DOC-NEG';
        BC14GLEntry.Amount := -1500;
        BC14GLEntry."Journal Batch Name" := JournalBatchNameTxt;
        BC14GLEntry.Insert();

        // [WHEN] The G/L Entry Migrator runs the migration
        BC14GLEntryMigrator.CreateJournalLine(BC14GLEntry);

        // [THEN] Journal line has negative amount
        GenJournalLine.SetRange("Journal Batch Name", JournalBatchNameTxt);
        GenJournalLine.SetRange("Document No.", 'DOC-NEG');
        Assert.IsTrue(GenJournalLine.FindFirst(), 'Journal line should be created');
        Assert.AreEqual(-1500, GenJournalLine.Amount, 'Amount should be negative');
    end;

    [Test]
    procedure TestGLEntryMigrationWithDimensions()
    var
        BC14GLEntry: Record "BC14 G/L Entry";
        GenJournalLine: Record "Gen. Journal Line";
        BC14JournalMgmt: Codeunit "BC14 Journal Management";
        BC14GLEntryMigrator: Codeunit "BC14 G/L Entry Migrator";
    begin
        // [SCENARIO] G/L Entry with dimension codes is correctly migrated.

        // [GIVEN] A G/L Entry with dimension codes exists in the buffer table
        CleanupTestData();
        EnableGLModule();
        CreateGLAccount('GLACC-DIM', 'Dimension Account');
        BC14JournalMgmt.EnsureBatchExists(JournalBatchNameTxt, 'BC14 G/L Entry Migration');

        BC14GLEntry.Init();
        BC14GLEntry."Entry No." := 200;
        BC14GLEntry."G/L Account No." := 'GLACC-DIM';
        BC14GLEntry."Posting Date" := WorkDate();
        BC14GLEntry."Document No." := 'DOC-DIM';
        BC14GLEntry.Amount := 500;
        BC14GLEntry."Global Dimension 1 Code" := 'DEPT-001';
        BC14GLEntry."Global Dimension 2 Code" := 'PROJ-001';
        BC14GLEntry."Journal Batch Name" := JournalBatchNameTxt;
        BC14GLEntry.Insert();

        // [WHEN] The G/L Entry Migrator runs the migration
        BC14GLEntryMigrator.CreateJournalLine(BC14GLEntry);

        // [THEN] Journal line has dimension codes
        GenJournalLine.SetRange("Journal Batch Name", JournalBatchNameTxt);
        GenJournalLine.SetRange("Document No.", 'DOC-DIM');
        Assert.IsTrue(GenJournalLine.FindFirst(), 'Journal line should be created');
        Assert.AreEqual('DEPT-001', GenJournalLine."Shortcut Dimension 1 Code", 'Global Dimension 1 should match');
        Assert.AreEqual('PROJ-001', GenJournalLine."Shortcut Dimension 2 Code", 'Global Dimension 2 should match');
    end;

    [Test]
    procedure TestGLEntryMigrationWithExternalDocNo()
    var
        BC14GLEntry: Record "BC14 G/L Entry";
        GenJournalLine: Record "Gen. Journal Line";
        BC14JournalMgmt: Codeunit "BC14 Journal Management";
        BC14GLEntryMigrator: Codeunit "BC14 G/L Entry Migrator";
    begin
        // [SCENARIO] G/L Entry with External Document No. is correctly migrated.

        // [GIVEN] A G/L Entry with External Document No. exists in the buffer table
        CleanupTestData();
        EnableGLModule();
        CreateGLAccount('GLACC-EXT', 'External Account');
        BC14JournalMgmt.EnsureBatchExists(JournalBatchNameTxt, 'BC14 G/L Entry Migration');

        BC14GLEntry.Init();
        BC14GLEntry."Entry No." := 300;
        BC14GLEntry."G/L Account No." := 'GLACC-EXT';
        BC14GLEntry."Posting Date" := WorkDate();
        BC14GLEntry."Document No." := 'DOC-EXT';
        BC14GLEntry.Amount := 750;
        BC14GLEntry."External Document No." := 'EXT-12345';
        BC14GLEntry."Journal Batch Name" := JournalBatchNameTxt;
        BC14GLEntry.Insert();

        // [WHEN] The G/L Entry Migrator runs the migration
        BC14GLEntryMigrator.CreateJournalLine(BC14GLEntry);

        // [THEN] Journal line has External Document No.
        GenJournalLine.SetRange("Journal Batch Name", JournalBatchNameTxt);
        GenJournalLine.SetRange("Document No.", 'DOC-EXT');
        Assert.IsTrue(GenJournalLine.FindFirst(), 'Journal line should be created');
        Assert.AreEqual('EXT-12345', GenJournalLine."External Document No.", 'External Document No. should match');
    end;

    [Test]
    procedure TestGLEntryMigrationLineNumberIncrementing()
    var
        BC14GLEntry: Record "BC14 G/L Entry";
        GenJournalLine: Record "Gen. Journal Line";
        BC14JournalMgmt: Codeunit "BC14 Journal Management";
        BC14GLEntryMigrator: Codeunit "BC14 G/L Entry Migrator";
        ExpectedLineNo: Integer;
    begin
        // [SCENARIO] Each migrated journal line carries the source entry number as its Line No.
        //            (Production code assigns LineNo := EntryNo directly; no 10000 scaling.)

        // [GIVEN] Multiple G/L Entry records exist in the buffer table
        CleanupTestData();
        EnableGLModule();
        CreateGLAccount('GLACC-LINE', 'Line Number Account');
        BC14JournalMgmt.EnsureBatchExists(JournalBatchNameTxt, 'BC14 G/L Entry Migration');

        InsertBC14GLEntry(10000, 'GLACC-LINE', 100, 'Line 1');
        InsertBC14GLEntry(20000, 'GLACC-LINE', 200, 'Line 2');
        InsertBC14GLEntry(30000, 'GLACC-LINE', 300, 'Line 3');

        // [WHEN] The G/L Entry Migrator runs the migration for each entry
        BC14GLEntry.FindSet();
        repeat
            BC14GLEntryMigrator.CreateJournalLine(BC14GLEntry);
        until BC14GLEntry.Next() = 0;

        // [THEN] Journal line numbers mirror the source entry numbers (10000, 20000, 30000)
        GenJournalLine.SetRange("Journal Batch Name", JournalBatchNameTxt);
        GenJournalLine.SetRange("Account No.", 'GLACC-LINE');
        GenJournalLine.FindSet();

        ExpectedLineNo := 10000;
        repeat
            Assert.AreEqual(ExpectedLineNo, GenJournalLine."Line No.", 'Line No. should mirror source Entry No.');
            ExpectedLineNo += 10000;
        until GenJournalLine.Next() = 0;
    end;

    local procedure CleanupTestData()
    var
        BC14GLEntry: Record "BC14 G/L Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
    begin
        BC14GLEntry.DeleteAll();

        GenJournalLine.SetRange("Journal Batch Name", JournalBatchNameTxt);
        GenJournalLine.DeleteAll();

        GLAccount.SetFilter("No.", 'GLACC-*');
        GLAccount.DeleteAll();
    end;

    local procedure EnableGLModule()
    var
        BC14CompanyMigrationInfo: Record "BC14CompanyMigrationInfo";
    begin
        BC14CompanyMigrationInfo.DeleteAll();
        BC14CompanyMigrationInfo.GetSingleInstance();
        BC14CompanyMigrationInfo.Validate("Migrate GL Module", true);
        BC14CompanyMigrationInfo.Modify();
    end;

    local procedure CreateGLAccount(AccountNo: Code[20]; AccountName: Text[100])
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Init();
        GLAccount."No." := AccountNo;
        GLAccount.Name := AccountName;
        GLAccount."Account Type" := GLAccount."Account Type"::Posting;
        GLAccount."Direct Posting" := true;
        GLAccount.Insert();
    end;

    local procedure InsertBC14GLEntry(EntryNo: Integer; AccountNo: Code[20]; Amount: Decimal; Description: Text[100])
    var
        BC14GLEntry: Record "BC14 G/L Entry";
    begin
        BC14GLEntry.Init();
        BC14GLEntry."Entry No." := EntryNo;
        BC14GLEntry."G/L Account No." := AccountNo;
        BC14GLEntry."Posting Date" := WorkDate();
        BC14GLEntry."Document No." := 'DOC-' + Format(EntryNo);
        BC14GLEntry.Description := Description;
        BC14GLEntry.Amount := Amount;
        BC14GLEntry."Journal Batch Name" := JournalBatchNameTxt;
        BC14GLEntry.Insert();
    end;
}
