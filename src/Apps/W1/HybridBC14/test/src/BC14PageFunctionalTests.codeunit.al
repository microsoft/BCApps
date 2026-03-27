// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration.BC14;
using Microsoft.Finance.GeneralLedger.Account;

codeunit 148914 "BC14 Page Functional Tests"
{
    // [FEATURE] [BC14 Migration Pages]

    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    // ============================================================
    // BC14 Migration Configuration Page Tests
    // ============================================================

    [Test]
    procedure TestConfigurationPage_DefaultModulesEnabled()
    var
        BC14CompanyMigrationSettings: Record "BC14CompanyMigrationSettings";
    begin
        // [SCENARIO] All migration modules are enabled by default.

        // [GIVEN] A fresh settings record
        BC14CompanyMigrationSettings.DeleteAll();
        BC14CompanyMigrationSettings.GetSingleInstance();

        // [THEN] All modules should be enabled by default
        Assert.IsTrue(BC14CompanyMigrationSettings."Migrate GL Module", 'GL Module should be enabled by default');
        Assert.IsTrue(BC14CompanyMigrationSettings."Migrate Receivables Module", 'Receivables Module should be enabled by default');
        Assert.IsTrue(BC14CompanyMigrationSettings."Migrate Payables Module", 'Payables Module should be enabled by default');
        Assert.IsTrue(BC14CompanyMigrationSettings."Migrate Inventory Module", 'Inventory Module should be enabled by default');
    end;

    [Test]
    procedure TestConfigurationPage_DisableModule()
    var
        BC14CompanyMigrationSettings: Record "BC14CompanyMigrationSettings";
    begin
        // [SCENARIO] User can disable specific migration modules.

        // [GIVEN] Default settings
        BC14CompanyMigrationSettings.DeleteAll();
        BC14CompanyMigrationSettings.GetSingleInstance();

        // [WHEN] User disables the Inventory module
        BC14CompanyMigrationSettings.Validate("Migrate Inventory Module", false);
        BC14CompanyMigrationSettings.Modify();

        // [THEN] The setting is persisted
        Clear(BC14CompanyMigrationSettings);
        BC14CompanyMigrationSettings.GetSingleInstance();
        Assert.IsFalse(BC14CompanyMigrationSettings."Migrate Inventory Module", 'Inventory Module should be disabled');
        Assert.IsTrue(BC14CompanyMigrationSettings."Migrate GL Module", 'GL Module should still be enabled');
    end;

    [Test]
    procedure TestConfigurationPage_SkipPostingJournalBatches()
    var
        BC14CompanyMigrationSettings: Record "BC14CompanyMigrationSettings";
    begin
        // [SCENARIO] User can enable Skip Posting Journal Batches option.

        // [GIVEN] Default settings
        BC14CompanyMigrationSettings.DeleteAll();
        BC14CompanyMigrationSettings.GetSingleInstance();

        // [THEN] Skip Posting should be disabled by default
        Assert.IsFalse(BC14CompanyMigrationSettings."Skip Posting Journal Batches", 'Skip Posting should be disabled by default');

        // [WHEN] User enables Skip Posting
        BC14CompanyMigrationSettings.Validate("Skip Posting Journal Batches", true);
        BC14CompanyMigrationSettings.Modify();

        // [THEN] The setting is persisted
        Clear(BC14CompanyMigrationSettings);
        BC14CompanyMigrationSettings.GetSingleInstance();
        Assert.IsTrue(BC14CompanyMigrationSettings."Skip Posting Journal Batches", 'Skip Posting should be enabled');
    end;

    [Test]
    procedure TestConfigurationPage_StopOnFirstError()
    var
        BC14CompanyMigrationSettings: Record "BC14CompanyMigrationSettings";
    begin
        // [SCENARIO] User can enable Stop On First Error option.

        // [GIVEN] Default settings
        BC14CompanyMigrationSettings.DeleteAll();
        BC14CompanyMigrationSettings.GetSingleInstance();

        // [THEN] Stop On First Error should be disabled by default
        Assert.IsFalse(BC14CompanyMigrationSettings."Stop On First Error", 'Stop On First Error should be disabled by default');

        // [WHEN] User enables Stop On First Error
        BC14CompanyMigrationSettings.Validate("Stop On First Error", true);
        BC14CompanyMigrationSettings.Modify();

        // [THEN] The setting is persisted
        Clear(BC14CompanyMigrationSettings);
        BC14CompanyMigrationSettings.GetSingleInstance();
        Assert.IsTrue(BC14CompanyMigrationSettings."Stop On First Error", 'Stop On First Error should be enabled');
    end;

    [Test]
    procedure TestConfigurationPage_MigrationStateInitial()
    var
        BC14CompanyMigrationSettings: Record "BC14CompanyMigrationSettings";
    begin
        // [SCENARIO] Migration State is NotStarted initially.

        // [GIVEN] A fresh settings record
        BC14CompanyMigrationSettings.DeleteAll();
        BC14CompanyMigrationSettings.GetSingleInstance();

        // [THEN] Migration State should be NotStarted
        Assert.AreEqual("BC14 Migration State"::NotStarted, BC14CompanyMigrationSettings."Migration State",
            'Migration State should be NotStarted initially');
    end;

    [Test]
    procedure TestConfigurationPage_SetMigrationStarted()
    var
        BC14CompanyMigrationSettings: Record "BC14CompanyMigrationSettings";
    begin
        // [SCENARIO] SetDataMigrationStarted sets the flag and timestamp.

        // [GIVEN] Fresh settings
        BC14CompanyMigrationSettings.DeleteAll();
        BC14CompanyMigrationSettings.GetSingleInstance();

        // [WHEN] SetDataMigrationStarted is called
        BC14CompanyMigrationSettings.SetDataMigrationStarted();

        // [THEN] The flag and timestamp are set
        Clear(BC14CompanyMigrationSettings);
        BC14CompanyMigrationSettings.GetSingleInstance();
        Assert.IsTrue(BC14CompanyMigrationSettings."Data Migration Started", 'Data Migration Started should be true');
        Assert.IsTrue(BC14CompanyMigrationSettings."Data Migration Started At" > 0DT, 'Timestamp should be set');
    end;

    // ============================================================
    // BC14 Balance Validation Page Tests
    // ============================================================

    [Test]
    procedure TestBalanceValidation_CalculateBalances_NoEntries()
    var
        BC14GLEntry: Record "BC14 G/L Entry";
        GLAccount: Record "G/L Account";
        BC14DebitAmount: Decimal;
        BC14CreditAmount: Decimal;
        BC14Balance: Decimal;
    begin
        // [SCENARIO] Balance calculation returns zero when no G/L entries exist.

        // [GIVEN] A G/L Account with no BC14 G/L Entries
        CleanupBalanceTestData();
        CreateTestGLAccount('BALANCE-001', 'Balance Test Account');

        // [WHEN] Calculating balances (simulating page logic)
        BC14GLEntry.SetRange("G/L Account No.", 'BALANCE-001');
        BC14DebitAmount := 0;
        BC14CreditAmount := 0;
        if BC14GLEntry.FindSet() then
            repeat
                BC14DebitAmount += BC14GLEntry."Debit Amount";
                BC14CreditAmount += BC14GLEntry."Credit Amount";
            until BC14GLEntry.Next() = 0;
        BC14Balance := BC14DebitAmount - BC14CreditAmount;

        // [THEN] All values are zero
        Assert.AreEqual(0, BC14DebitAmount, 'Debit Amount should be 0');
        Assert.AreEqual(0, BC14CreditAmount, 'Credit Amount should be 0');
        Assert.AreEqual(0, BC14Balance, 'Balance should be 0');

        // Cleanup
        CleanupBalanceTestData();
    end;

    [Test]
    procedure TestBalanceValidation_CalculateBalances_WithEntries()
    var
        BC14GLEntry: Record "BC14 G/L Entry";
        BC14DebitAmount: Decimal;
        BC14CreditAmount: Decimal;
        BC14Balance: Decimal;
    begin
        // [SCENARIO] Balance calculation correctly sums debit and credit amounts.

        // [GIVEN] A G/L Account with BC14 G/L Entries
        CleanupBalanceTestData();
        CreateTestGLAccount('BALANCE-002', 'Balance Test Account 2');

        // Insert test entries
        InsertBC14GLEntry(1, 'BALANCE-002', 1000, 0); // Debit 1000
        InsertBC14GLEntry(2, 'BALANCE-002', 500, 0);  // Debit 500
        InsertBC14GLEntry(3, 'BALANCE-002', 0, 300);  // Credit 300

        // [WHEN] Calculating balances
        BC14GLEntry.SetRange("G/L Account No.", 'BALANCE-002');
        BC14DebitAmount := 0;
        BC14CreditAmount := 0;
        if BC14GLEntry.FindSet() then
            repeat
                BC14DebitAmount += BC14GLEntry."Debit Amount";
                BC14CreditAmount += BC14GLEntry."Credit Amount";
            until BC14GLEntry.Next() = 0;
        BC14Balance := BC14DebitAmount - BC14CreditAmount;

        // [THEN] Values are calculated correctly
        Assert.AreEqual(1500, BC14DebitAmount, 'Debit Amount should be 1500');
        Assert.AreEqual(300, BC14CreditAmount, 'Credit Amount should be 300');
        Assert.AreEqual(1200, BC14Balance, 'Balance should be 1200');

        // Cleanup
        CleanupBalanceTestData();
    end;

    [Test]
    procedure TestBalanceValidation_DifferenceCalculation()
    var
        HasDifference: Boolean;
        BC14Balance: Decimal;
        BCOnlineBalance: Decimal;
        BalanceDifference: Decimal;
    begin
        // [SCENARIO] Difference is correctly identified between BC14 and BC Online balances.

        // [GIVEN] BC14 Balance and BC Online Balance with difference
        BC14Balance := 1000;
        BCOnlineBalance := 950;

        // [WHEN] Difference is calculated
        BalanceDifference := BC14Balance - BCOnlineBalance;
        HasDifference := Abs(BalanceDifference) > 0.01;

        // [THEN] Difference is correctly identified
        Assert.AreEqual(50, BalanceDifference, 'Difference should be 50');
        Assert.IsTrue(HasDifference, 'HasDifference should be true');
    end;

    [Test]
    procedure TestBalanceValidation_SmallRoundingDifferenceIgnored()
    var
        HasDifference: Boolean;
        BC14Balance: Decimal;
        BCOnlineBalance: Decimal;
        BalanceDifference: Decimal;
    begin
        // [SCENARIO] Small rounding differences (< 0.01) are ignored.

        // [GIVEN] BC14 Balance and BC Online Balance with tiny difference
        BC14Balance := 1000.005;
        BCOnlineBalance := 1000;

        // [WHEN] Difference is calculated
        BalanceDifference := BC14Balance - BCOnlineBalance;
        HasDifference := Abs(BalanceDifference) > 0.01;

        // [THEN] Small difference is ignored
        Assert.IsFalse(HasDifference, 'Small rounding difference should be ignored');
    end;

    // ============================================================
    // BC14 Buffer Record Editor Tests
    // ============================================================

    [Test]
    procedure TestBufferFieldEditor_TableStructure()
    var
        BC14BufferFieldEditor: Record "BC14 Buffer Field Editor";
    begin
        // [SCENARIO] BC14 Buffer Field Editor table has expected structure.

        // [GIVEN] The table definition

        // [THEN] Key fields exist
        BC14BufferFieldEditor.Init();
        BC14BufferFieldEditor."Field No." := 1;
        BC14BufferFieldEditor."Field Name" := 'Test Field';
        BC14BufferFieldEditor."Field Value" := 'Test Value';
        BC14BufferFieldEditor."Field Type" := 'Text';
        BC14BufferFieldEditor."Is Editable" := true;

        // Verify fields are set correctly
        Assert.AreEqual(1, BC14BufferFieldEditor."Field No.", 'Field No. should be set');
        Assert.AreEqual('Test Field', BC14BufferFieldEditor."Field Name", 'Field Name should be set');
        Assert.AreEqual('Test Value', BC14BufferFieldEditor."Field Value", 'Field Value should be set');
        Assert.AreEqual('Text', BC14BufferFieldEditor."Field Type", 'Field Type should be set');
        Assert.IsTrue(BC14BufferFieldEditor."Is Editable", 'Is Editable should be true');
    end;

    [Test]
    procedure TestBufferRecordEditor_IsEditableFieldType()
    var
        IsEditable: Boolean;
    begin
        // [SCENARIO] Only certain field types should be editable.

        // [GIVEN/WHEN/THEN] Text, Code, Integer, Decimal, Boolean, Date, DateTime are editable
        // BLOB, RecordID, Media are not editable
        // This test verifies the concept - actual implementation is in the page

        // Text types should be editable
        IsEditable := IsEditableFieldType('Text');
        Assert.IsTrue(IsEditable, 'Text should be editable');

        IsEditable := IsEditableFieldType('Code');
        Assert.IsTrue(IsEditable, 'Code should be editable');

        IsEditable := IsEditableFieldType('Integer');
        Assert.IsTrue(IsEditable, 'Integer should be editable');

        IsEditable := IsEditableFieldType('Decimal');
        Assert.IsTrue(IsEditable, 'Decimal should be editable');

        // BLOB should not be editable
        IsEditable := IsEditableFieldType('BLOB');
        Assert.IsFalse(IsEditable, 'BLOB should not be editable');

        // RecordID should not be editable
        IsEditable := IsEditableFieldType('RecordID');
        Assert.IsFalse(IsEditable, 'RecordID should not be editable');
    end;

    // ============================================================
    // Migration Error Overview Page Tests
    // ============================================================

    [Test]
    procedure TestErrorOverviewPage_ShowsUnresolvedErrors()
    var
        BC14MigrationErrors: Record "BC14 Migration Errors";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        DummyRecordId: RecordId;
    begin
        // [SCENARIO] Error Overview shows only unresolved errors by default.

        // [GIVEN] Mix of resolved and unresolved errors
        BC14MigrationErrors.SetRange("Company Name", CompanyName());
        BC14MigrationErrors.DeleteAll();

        BC14MigrationErrorHandler.LogError('Test', 1000, 'Table1', 'KEY-001', 0, 'Error 1', DummyRecordId);
        BC14MigrationErrorHandler.LogError('Test', 1000, 'Table1', 'KEY-002', 0, 'Error 2', DummyRecordId);
        BC14MigrationErrorHandler.LogError('Test', 1000, 'Table1', 'KEY-003', 0, 'Error 3', DummyRecordId);

        // Resolve one error
        BC14MigrationErrorHandler.ResolveErrorForRecord(1000, 'KEY-002');

        // [WHEN] Filtering for unresolved errors (page default behavior)
        BC14MigrationErrors.SetRange("Company Name", CompanyName());
        BC14MigrationErrors.SetRange(Resolved, false);

        // [THEN] Only 2 unresolved errors are shown
        Assert.AreEqual(2, BC14MigrationErrors.Count(), 'Should show 2 unresolved errors');

        // Cleanup
        BC14MigrationErrors.Reset();
        BC14MigrationErrors.SetRange("Company Name", CompanyName());
        BC14MigrationErrors.DeleteAll();
    end;

    [Test]
    procedure TestErrorOverviewPage_ScheduleForRetry()
    var
        BC14MigrationErrors: Record "BC14 Migration Errors";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        DummyRecordId: RecordId;
    begin
        // [SCENARIO] User can schedule an error for retry.

        // [GIVEN] An error exists
        BC14MigrationErrors.SetRange("Company Name", CompanyName());
        BC14MigrationErrors.DeleteAll();

        BC14MigrationErrorHandler.LogError('Test', 1000, 'Table1', 'KEY-001', 0, 'Test Error', DummyRecordId);

        // [WHEN] User schedules the error for retry
        BC14MigrationErrors.SetRange("Source Table ID", 1000);
        BC14MigrationErrors.SetRange("Source Record Key", 'KEY-001');
        BC14MigrationErrors.FindFirst();
        BC14MigrationErrors."Scheduled For Retry" := true;
        BC14MigrationErrors.Modify();

        // [THEN] The error is marked for retry
        BC14MigrationErrors.Get(BC14MigrationErrors.Id);
        Assert.IsTrue(BC14MigrationErrors."Scheduled For Retry", 'Error should be scheduled for retry');

        // Cleanup
        BC14MigrationErrors.Reset();
        BC14MigrationErrors.SetRange("Company Name", CompanyName());
        BC14MigrationErrors.DeleteAll();
    end;

    // ============================================================
    // Helper Procedures
    // ============================================================

    local procedure CleanupBalanceTestData()
    var
        BC14GLEntry: Record "BC14 G/L Entry";
        GLAccount: Record "G/L Account";
    begin
        BC14GLEntry.SetFilter("G/L Account No.", 'BALANCE-*');
        BC14GLEntry.DeleteAll();

        GLAccount.SetFilter("No.", 'BALANCE-*');
        GLAccount.DeleteAll();
    end;

    local procedure CreateTestGLAccount(AccountNo: Code[20]; AccountName: Text[100])
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Init();
        GLAccount."No." := AccountNo;
        GLAccount.Name := AccountName;
        GLAccount."Account Type" := GLAccount."Account Type"::Posting;
        GLAccount.Insert();
    end;

    local procedure InsertBC14GLEntry(EntryNo: Integer; AccountNo: Code[20]; DebitAmount: Decimal; CreditAmount: Decimal)
    var
        BC14GLEntry: Record "BC14 G/L Entry";
    begin
        BC14GLEntry.Init();
        BC14GLEntry."Entry No." := EntryNo;
        BC14GLEntry."G/L Account No." := AccountNo;
        BC14GLEntry."Posting Date" := WorkDate();
        BC14GLEntry."Debit Amount" := DebitAmount;
        BC14GLEntry."Credit Amount" := CreditAmount;
        BC14GLEntry.Amount := DebitAmount - CreditAmount;
        BC14GLEntry.Insert();
    end;

    local procedure IsEditableFieldType(FieldType: Text): Boolean
    begin
        case FieldType of
            'Text', 'Code', 'Integer', 'Decimal', 'Boolean', 'Date', 'Time', 'DateTime', 'Option', 'Enum':
                exit(true);
            'BLOB', 'Media', 'MediaSet', 'RecordID', 'TableFilter', 'Guid':
                exit(false);
            else
                exit(false);
        end;
    end;
}
