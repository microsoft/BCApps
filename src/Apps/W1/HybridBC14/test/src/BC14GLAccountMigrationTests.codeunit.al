// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration.BC14;
using Microsoft.Finance.GeneralLedger.Account;

codeunit 148905 "BC14 GL Account Mig. Tests"
{
    // [FEATURE] [BC14 Cloud Migration GL Account Upgrade]

    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure TestGLAccountMigrationTransfersAllFields()
    var
        BC14GLAccount: Record "BC14 G/L Account";
        GLAccount: Record "G/L Account";
        BC14GLAccountMigrator: Codeunit "BC14 GL Account Migrator";
    begin
        // [SCENARIO] All standard fields are correctly migrated from BC14 G/L Account buffer to G/L Account table.

        // [GIVEN] A complete G/L Account record exists in the buffer table
        CleanupTestData();
        EnableGLModule();

        BC14GLAccount.Init();
        BC14GLAccount."No." := 'GLACC-001';
        BC14GLAccount.Name := 'Test G/L Account';
        BC14GLAccount."Account Type" := "G/L Account Type"::Posting;
        BC14GLAccount."Income/Balance" := "G/L Account Report Type"::"Balance Sheet";
        BC14GLAccount.Blocked := false;
        BC14GLAccount."Direct Posting" := true;
        BC14GLAccount.Insert();

        // [WHEN] The G/L Account Migrator runs the migration
        BC14GLAccountMigrator.MigrateGLAccount(BC14GLAccount);

        // [THEN] Migration succeeds and all field values in the G/L Account table match the buffer
        Assert.IsTrue(GLAccount.Get('GLACC-001'), 'G/L Account record should exist after migration');

        Assert.AreEqual('Test G/L Account', GLAccount.Name, 'Name should match');
        Assert.AreEqual("G/L Account Type"::Posting, GLAccount."Account Type", 'Account Type should match');
        Assert.AreEqual("G/L Account Report Type"::"Balance Sheet", GLAccount."Income/Balance", 'Income/Balance should match');
        Assert.AreEqual(false, GLAccount.Blocked, 'Blocked should match');
        Assert.AreEqual(true, GLAccount."Direct Posting", 'Direct Posting should match');
    end;

    [Test]
    procedure TestGLAccountMigrationMultipleAccounts()
    var
        BC14GLAccount: Record "BC14 G/L Account";
        GLAccount: Record "G/L Account";
        BC14GLAccountMigrator: Codeunit "BC14 GL Account Migrator";
    begin
        // [SCENARIO] Multiple G/L Accounts in the buffer table are all migrated successfully.

        // [GIVEN] 3 G/L Account records exist in the buffer table
        CleanupTestData();
        EnableGLModule();

        InsertBC14GLAccount('GLACC-A', 'Account Alpha', "G/L Account Type"::Posting);
        InsertBC14GLAccount('GLACC-B', 'Account Beta', "G/L Account Type"::Posting);
        InsertBC14GLAccount('GLACC-C', 'Account Gamma', "G/L Account Type"::Posting);

        // [WHEN] The G/L Account Migrator runs the migration for each account
        BC14GLAccount.FindSet();
        repeat
            BC14GLAccountMigrator.MigrateGLAccount(BC14GLAccount);
        until BC14GLAccount.Next() = 0;

        // [THEN] All 3 records are migrated successfully
        Assert.IsTrue(GLAccount.Get('GLACC-A'), 'Account A should exist after migration');
        Assert.AreEqual('Account Alpha', GLAccount.Name, 'Account A Name should match');

        Assert.IsTrue(GLAccount.Get('GLACC-B'), 'Account B should exist after migration');
        Assert.AreEqual('Account Beta', GLAccount.Name, 'Account B Name should match');

        Assert.IsTrue(GLAccount.Get('GLACC-C'), 'Account C should exist after migration');
        Assert.AreEqual('Account Gamma', GLAccount.Name, 'Account C Name should match');
    end;

    [Test]
    procedure TestGLAccountMigrationUpdatesExistingAccount()
    var
        BC14GLAccount: Record "BC14 G/L Account";
        GLAccount: Record "G/L Account";
        BC14GLAccountMigrator: Codeunit "BC14 GL Account Migrator";
    begin
        // [SCENARIO] If a G/L Account with the same No. already exists, migration should update it rather than insert a duplicate.

        // [GIVEN] A G/L Account record already exists in the G/L Account table
        CleanupTestData();
        EnableGLModule();

        GLAccount.Init();
        GLAccount."No." := 'GLACC-EXIST';
        GLAccount.Name := 'Old Account Name';
        GLAccount.Insert();

        // [GIVEN] The buffer table has a record with the same No. but different field values
        BC14GLAccount.Init();
        BC14GLAccount."No." := 'GLACC-EXIST';
        BC14GLAccount.Name := 'Updated Account Name';
        BC14GLAccount."Account Type" := "G/L Account Type"::Posting;
        BC14GLAccount."Direct Posting" := true;
        BC14GLAccount.Insert();

        // [WHEN] The G/L Account Migrator runs the migration
        BC14GLAccountMigrator.MigrateGLAccount(BC14GLAccount);

        // [THEN] The existing record is updated
        GLAccount.Get('GLACC-EXIST');
        Assert.AreEqual('Updated Account Name', GLAccount.Name, 'Name should be updated');
        Assert.AreEqual(true, GLAccount."Direct Posting", 'Direct Posting should be updated');
    end;

    [Test]
    procedure TestGLAccountMigratorIsDisabledWhenModuleDisabled()
    var
        BC14CompanyMigrationSettings: Record "BC14CompanyMigrationSettings";
        BC14GLAccountMigrator: Codeunit "BC14 GL Account Migrator";
    begin
        // [SCENARIO] G/L Account Migrator reports disabled when the GL module is disabled.

        // [GIVEN] The GL module is disabled
        BC14CompanyMigrationSettings.DeleteAll();
        BC14CompanyMigrationSettings.GetSingleInstance();
        BC14CompanyMigrationSettings.Validate("Migrate GL Module", false);
        BC14CompanyMigrationSettings.Modify();

        // [THEN] IsEnabled should return false
        Assert.IsFalse(BC14GLAccountMigrator.IsEnabled(), 'GL Account Migrator should be disabled when GL module is disabled');
    end;

    [Test]
    procedure TestGLAccountMigrationRecordCount()
    var
        BC14GLAccountMigrator: Codeunit "BC14 GL Account Migrator";
    begin
        // [SCENARIO] GetRecordCount returns the number of records in the buffer table.

        // [GIVEN] 2 records exist in the buffer table
        CleanupTestData();

        InsertBC14GLAccount('GLACC-CNT1', 'Count Account 1', "G/L Account Type"::Posting);
        InsertBC14GLAccount('GLACC-CNT2', 'Count Account 2', "G/L Account Type"::Posting);

        // [THEN] GetRecordCount should return 2
        Assert.AreEqual(2, BC14GLAccountMigrator.GetRecordCount(), 'GetRecordCount should return the number of BC14 G/L Account records');
    end;

    [Test]
    procedure TestGLAccountMigratorIsEnabledByDefault()
    var
        BC14CompanyMigrationSettings: Record "BC14CompanyMigrationSettings";
        BC14GLAccountMigrator: Codeunit "BC14 GL Account Migrator";
    begin
        // [SCENARIO] The G/L Account Migrator is enabled by default.

        // [GIVEN] Default settings are used
        BC14CompanyMigrationSettings.DeleteAll();

        // [THEN] IsEnabled should return true
        Assert.IsTrue(BC14GLAccountMigrator.IsEnabled(), 'GL Account Migrator should be enabled by default');
    end;

    [Test]
    procedure TestGLAccountMigratorName()
    var
        BC14GLAccountMigrator: Codeunit "BC14 GL Account Migrator";
    begin
        // [SCENARIO] GetName returns the correct migrator name.

        // [THEN] The name should be 'G/L Account Migrator'
        Assert.AreEqual('G/L Account Migrator', BC14GLAccountMigrator.GetName(), 'Migrator name should be G/L Account Migrator');
    end;

    [Test]
    procedure TestGLAccountMigratorSourceTableId()
    var
        BC14GLAccountMigrator: Codeunit "BC14 GL Account Migrator";
    begin
        // [SCENARIO] GetSourceTableId returns the correct buffer table ID.

        // [THEN] The source table ID should be BC14 G/L Account
        Assert.AreEqual(Database::"BC14 G/L Account", BC14GLAccountMigrator.GetSourceTableId(), 'Source table ID should be BC14 G/L Account');
    end;

    [Test]
    procedure TestGLAccountMigratorGetSourceRecordKey()
    var
        BC14GLAccount: Record "BC14 G/L Account";
        BC14GLAccountMigrator: Codeunit "BC14 GL Account Migrator";
        SourceRecordRef: RecordRef;
    begin
        // [SCENARIO] GetSourceRecordKey returns the Account No. as the record key.

        // [GIVEN] A G/L Account exists in the buffer table
        CleanupTestData();
        InsertBC14GLAccount('GLACC-KEY', 'Test Account', "G/L Account Type"::Posting);

        // [WHEN] GetSourceRecordKey is called
        BC14GLAccount.Get('GLACC-KEY');
        SourceRecordRef.GetTable(BC14GLAccount);

        // [THEN] The record key is the Account No.
        Assert.AreEqual('GLACC-KEY', BC14GLAccountMigrator.GetSourceRecordKey(SourceRecordRef), 'Record key should be the Account No.');
        SourceRecordRef.Close();
    end;

    [Test]
    procedure TestGLAccountMigrationBlockedAccount()
    var
        BC14GLAccount: Record "BC14 G/L Account";
        GLAccount: Record "G/L Account";
        BC14GLAccountMigrator: Codeunit "BC14 GL Account Migrator";
    begin
        // [SCENARIO] Blocked status is correctly migrated.

        // [GIVEN] A blocked G/L Account record exists in the buffer table
        CleanupTestData();
        EnableGLModule();

        BC14GLAccount.Init();
        BC14GLAccount."No." := 'GLACC-BLOCK';
        BC14GLAccount.Name := 'Blocked Account';
        BC14GLAccount."Account Type" := "G/L Account Type"::Posting;
        BC14GLAccount.Blocked := true;
        BC14GLAccount.Insert();

        // [WHEN] The G/L Account Migrator runs the migration
        BC14GLAccountMigrator.MigrateGLAccount(BC14GLAccount);

        // [THEN] The blocked status is preserved
        Assert.IsTrue(GLAccount.Get('GLACC-BLOCK'), 'G/L Account record should exist after migration');
        Assert.IsTrue(GLAccount.Blocked, 'Blocked status should be true');
    end;

    [Test]
    procedure TestGLAccountMigrationHeadingAccount()
    var
        BC14GLAccount: Record "BC14 G/L Account";
        GLAccount: Record "G/L Account";
        BC14GLAccountMigrator: Codeunit "BC14 GL Account Migrator";
    begin
        // [SCENARIO] Heading account types are correctly migrated.

        // [GIVEN] A Heading G/L Account record exists in the buffer table
        CleanupTestData();
        EnableGLModule();

        BC14GLAccount.Init();
        BC14GLAccount."No." := 'GLACC-HEAD';
        BC14GLAccount.Name := 'Heading Account';
        BC14GLAccount."Account Type" := "G/L Account Type"::Heading;
        BC14GLAccount.Insert();

        // [WHEN] The G/L Account Migrator runs the migration
        BC14GLAccountMigrator.MigrateGLAccount(BC14GLAccount);

        // [THEN] The account type is preserved as Heading
        Assert.IsTrue(GLAccount.Get('GLACC-HEAD'), 'G/L Account record should exist after migration');
        Assert.AreEqual("G/L Account Type"::Heading, GLAccount."Account Type", 'Account Type should be Heading');
    end;

    [Test]
    procedure TestGLAccountMigrationIncomeStatement()
    var
        BC14GLAccount: Record "BC14 G/L Account";
        GLAccount: Record "G/L Account";
        BC14GLAccountMigrator: Codeunit "BC14 GL Account Migrator";
    begin
        // [SCENARIO] Income Statement accounts are correctly migrated.

        // [GIVEN] An Income Statement G/L Account record exists in the buffer table
        CleanupTestData();
        EnableGLModule();

        BC14GLAccount.Init();
        BC14GLAccount."No." := 'GLACC-INCM';
        BC14GLAccount.Name := 'Income Account';
        BC14GLAccount."Account Type" := "G/L Account Type"::Posting;
        BC14GLAccount."Income/Balance" := "G/L Account Report Type"::"Income Statement";
        BC14GLAccount.Insert();

        // [WHEN] The G/L Account Migrator runs the migration
        BC14GLAccountMigrator.MigrateGLAccount(BC14GLAccount);

        // [THEN] The Income/Balance setting is preserved
        Assert.IsTrue(GLAccount.Get('GLACC-INCM'), 'G/L Account record should exist after migration');
        Assert.AreEqual("G/L Account Report Type"::"Income Statement", GLAccount."Income/Balance", 'Income/Balance should be Income Statement');
    end;

    local procedure CleanupTestData()
    var
        BC14GLAccount: Record "BC14 G/L Account";
        GLAccount: Record "G/L Account";
    begin
        BC14GLAccount.DeleteAll();

        GLAccount.SetFilter("No.", 'GLACC-*');
        GLAccount.DeleteAll();
    end;

    local procedure EnableGLModule()
    var
        BC14CompanyMigrationSettings: Record "BC14CompanyMigrationSettings";
    begin
        BC14CompanyMigrationSettings.DeleteAll();
        BC14CompanyMigrationSettings.GetSingleInstance();
        BC14CompanyMigrationSettings.Validate("Migrate GL Module", true);
        BC14CompanyMigrationSettings.Modify();
    end;

    local procedure InsertBC14GLAccount(AccountNo: Code[20]; AccountName: Text[100]; AccountType: Enum "G/L Account Type")
    var
        BC14GLAccount: Record "BC14 G/L Account";
    begin
        BC14GLAccount.Init();
        BC14GLAccount."No." := AccountNo;
        BC14GLAccount.Name := AccountName;
        BC14GLAccount."Account Type" := AccountType;
        BC14GLAccount.Insert();
    end;
}
