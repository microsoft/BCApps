// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration.BC14;

codeunit 148142 "BC14 Settings Tests"
{
    // [FEATURE] [BC14 Cloud Migration Settings]

    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        BC14TestHelperFunctions: Codeunit "BC14 Helper Function Tests";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestInitialSettingsDefaults()
    var
        BC14CompanyAdditionalSettings: Record "BC14CompanyAdditionalSettings";
    begin
        // [SCENARIO] Settings are initialized with correct default values for a new BC14 migration.

        // [GIVEN] Some records are created in the settings table
        BC14TestHelperFunctions.CreateSettingsTableEntries();

        // [THEN] The settings are initialized with the correct default values
        Clear(BC14CompanyAdditionalSettings);
        BC14CompanyAdditionalSettings.Get('Company 1');

        Assert.AreEqual('Company 1', BC14CompanyAdditionalSettings.Name, 'Incorrect company settings found');
        Assert.AreEqual(true, BC14CompanyAdditionalSettings."Migrate GL Module", 'Migrate GL Module - Incorrect default value');
        Assert.AreEqual(true, BC14CompanyAdditionalSettings."Migrate Receivables Module", 'Migrate Receivables Module - Incorrect default value');
        Assert.AreEqual(true, BC14CompanyAdditionalSettings."Migrate Payables Module", 'Migrate Payables Module - Incorrect default value');
        Assert.AreEqual(true, BC14CompanyAdditionalSettings."Migrate Inventory Module", 'Migrate Inventory Module - Incorrect default value');
        Assert.AreEqual(false, BC14CompanyAdditionalSettings."Data Migration Started", 'Data Migration Started - Incorrect default value');
        Assert.AreEqual(false, BC14CompanyAdditionalSettings."Skip Posting Journal Batches", 'Skip Posting Journal Batches - Incorrect default value');
        Assert.AreEqual(false, BC14CompanyAdditionalSettings.ProcessesAreRunning, 'ProcessesAreRunning - Incorrect default value');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestGLModuleCanBeDisabled()
    var
        BC14CompanyAdditionalSettings: Record "BC14CompanyAdditionalSettings";
    begin
        // [SCENARIO] The GL Module setting can be independently disabled.

        // [GIVEN] Some records are created in the settings table with all settings enabled
        BC14TestHelperFunctions.CreateSettingsTableEntries();

        // [WHEN] The GL module setting is disabled
        Clear(BC14CompanyAdditionalSettings);
        BC14CompanyAdditionalSettings.Get('Company 2');
        BC14CompanyAdditionalSettings.Validate("Migrate GL Module", false);
        BC14CompanyAdditionalSettings.Modify();

        // [THEN] The GL Module is disabled but other modules remain enabled
        Assert.AreEqual(false, BC14CompanyAdditionalSettings."Migrate GL Module", 'Migrate GL Module - Should be disabled');
        Assert.AreEqual(true, BC14CompanyAdditionalSettings."Migrate Receivables Module", 'Migrate Receivables Module - Should remain enabled');
        Assert.AreEqual(true, BC14CompanyAdditionalSettings."Migrate Payables Module", 'Migrate Payables Module - Should remain enabled');
        Assert.AreEqual(true, BC14CompanyAdditionalSettings."Migrate Inventory Module", 'Migrate Inventory Module - Should remain enabled');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestReceivablesModuleCanBeDisabled()
    var
        BC14CompanyAdditionalSettings: Record "BC14CompanyAdditionalSettings";
    begin
        // [SCENARIO] The Receivables Module setting can be independently disabled.

        // [GIVEN] Some records are created in the settings table with all settings enabled
        BC14TestHelperFunctions.CreateSettingsTableEntries();

        // [WHEN] The Receivables module setting is disabled
        Clear(BC14CompanyAdditionalSettings);
        BC14CompanyAdditionalSettings.Get('Company 2');
        BC14CompanyAdditionalSettings.Validate("Migrate Receivables Module", false);
        BC14CompanyAdditionalSettings.Modify();

        // [THEN] The Receivables Module is disabled but other modules remain enabled
        Assert.AreEqual(true, BC14CompanyAdditionalSettings."Migrate GL Module", 'Migrate GL Module - Should remain enabled');
        Assert.AreEqual(false, BC14CompanyAdditionalSettings."Migrate Receivables Module", 'Migrate Receivables Module - Should be disabled');
        Assert.AreEqual(true, BC14CompanyAdditionalSettings."Migrate Payables Module", 'Migrate Payables Module - Should remain enabled');
        Assert.AreEqual(true, BC14CompanyAdditionalSettings."Migrate Inventory Module", 'Migrate Inventory Module - Should remain enabled');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestPayablesModuleCanBeDisabled()
    var
        BC14CompanyAdditionalSettings: Record "BC14CompanyAdditionalSettings";
    begin
        // [SCENARIO] The Payables Module setting can be independently disabled.

        // [GIVEN] Some records are created in the settings table with all settings enabled
        BC14TestHelperFunctions.CreateSettingsTableEntries();

        // [WHEN] The Payables module setting is disabled
        Clear(BC14CompanyAdditionalSettings);
        BC14CompanyAdditionalSettings.Get('Company 2');
        BC14CompanyAdditionalSettings.Validate("Migrate Payables Module", false);
        BC14CompanyAdditionalSettings.Modify();

        // [THEN] The Payables Module is disabled but other modules remain enabled
        Assert.AreEqual(true, BC14CompanyAdditionalSettings."Migrate GL Module", 'Migrate GL Module - Should remain enabled');
        Assert.AreEqual(true, BC14CompanyAdditionalSettings."Migrate Receivables Module", 'Migrate Receivables Module - Should remain enabled');
        Assert.AreEqual(false, BC14CompanyAdditionalSettings."Migrate Payables Module", 'Migrate Payables Module - Should be disabled');
        Assert.AreEqual(true, BC14CompanyAdditionalSettings."Migrate Inventory Module", 'Migrate Inventory Module - Should remain enabled');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestInventoryModuleCanBeDisabled()
    var
        BC14CompanyAdditionalSettings: Record "BC14CompanyAdditionalSettings";
    begin
        // [SCENARIO] The Inventory Module setting can be independently disabled.

        // [GIVEN] Some records are created in the settings table with all settings enabled
        BC14TestHelperFunctions.CreateSettingsTableEntries();

        // [WHEN] The Inventory module setting is disabled
        Clear(BC14CompanyAdditionalSettings);
        BC14CompanyAdditionalSettings.Get('Company 2');
        BC14CompanyAdditionalSettings.Validate("Migrate Inventory Module", false);
        BC14CompanyAdditionalSettings.Modify();

        // [THEN] The Inventory Module is disabled but other modules remain enabled
        Assert.AreEqual(true, BC14CompanyAdditionalSettings."Migrate GL Module", 'Migrate GL Module - Should remain enabled');
        Assert.AreEqual(true, BC14CompanyAdditionalSettings."Migrate Receivables Module", 'Migrate Receivables Module - Should remain enabled');
        Assert.AreEqual(true, BC14CompanyAdditionalSettings."Migrate Payables Module", 'Migrate Payables Module - Should remain enabled');
        Assert.AreEqual(false, BC14CompanyAdditionalSettings."Migrate Inventory Module", 'Migrate Inventory Module - Should be disabled');
    end;

    [Test]
    procedure TestAllModulesCanBeDisabled()
    var
        BC14CompanyAdditionalSettings: Record "BC14CompanyAdditionalSettings";
    begin
        // [SCENARIO] All modules can be disabled simultaneously.

        // [GIVEN] Settings are created with all modules enabled
        BC14TestHelperFunctions.CreateSettingsTableEntries();

        // [WHEN] All module settings are disabled
        Clear(BC14CompanyAdditionalSettings);
        BC14CompanyAdditionalSettings.Get('Company 2');
        BC14CompanyAdditionalSettings.Validate("Migrate GL Module", false);
        BC14CompanyAdditionalSettings.Validate("Migrate Receivables Module", false);
        BC14CompanyAdditionalSettings.Validate("Migrate Payables Module", false);
        BC14CompanyAdditionalSettings.Validate("Migrate Inventory Module", false);
        BC14CompanyAdditionalSettings.Modify();

        // [THEN] All modules are disabled
        Assert.AreEqual(false, BC14CompanyAdditionalSettings."Migrate GL Module", 'Migrate GL Module - Should be disabled');
        Assert.AreEqual(false, BC14CompanyAdditionalSettings."Migrate Receivables Module", 'Migrate Receivables Module - Should be disabled');
        Assert.AreEqual(false, BC14CompanyAdditionalSettings."Migrate Payables Module", 'Migrate Payables Module - Should be disabled');
        Assert.AreEqual(false, BC14CompanyAdditionalSettings."Migrate Inventory Module", 'Migrate Inventory Module - Should be disabled');
    end;

    [Test]
    procedure TestGetSingleInstanceCreatesRecordIfNotExists()
    var
        BC14CompanyAdditionalSettings: Record "BC14CompanyAdditionalSettings";
    begin
        // [SCENARIO] GetSingleInstance creates a record if it does not exist.

        // [GIVEN] No records exist for the current company
        BC14CompanyAdditionalSettings.DeleteAll();

        // [WHEN] GetSingleInstance is called
        BC14CompanyAdditionalSettings.GetSingleInstance();

        // [THEN] A record is created for the current company with default values
        Assert.AreEqual(CompanyName(), BC14CompanyAdditionalSettings.Name, 'Record should be created for the current company');
        Assert.AreEqual(true, BC14CompanyAdditionalSettings."Migrate GL Module", 'Migrate GL Module - Should have default true');
        Assert.AreEqual(true, BC14CompanyAdditionalSettings."Migrate Receivables Module", 'Migrate Receivables Module - Should have default true');
        Assert.AreEqual(true, BC14CompanyAdditionalSettings."Migrate Payables Module", 'Migrate Payables Module - Should have default true');
        Assert.AreEqual(true, BC14CompanyAdditionalSettings."Migrate Inventory Module", 'Migrate Inventory Module - Should have default true');
    end;

    [Test]
    procedure TestModuleEnabledHelperFunctions()
    var
        BC14CompanyAdditionalSettings: Record "BC14CompanyAdditionalSettings";
    begin
        // [SCENARIO] Helper functions correctly return module enabled status.

        // [GIVEN] Settings are created with default values
        BC14CompanyAdditionalSettings.DeleteAll();

        // [WHEN] Helper functions are called
        // [THEN] All modules should be enabled by default
        Assert.AreEqual(true, BC14CompanyAdditionalSettings.GetGLModuleEnabled(), 'GetGLModuleEnabled - Should return true');
        Assert.AreEqual(true, BC14CompanyAdditionalSettings.GetReceivablesModuleEnabled(), 'GetReceivablesModuleEnabled - Should return true');
        Assert.AreEqual(true, BC14CompanyAdditionalSettings.GetPayablesModuleEnabled(), 'GetPayablesModuleEnabled - Should return true');
        Assert.AreEqual(true, BC14CompanyAdditionalSettings.GetInventoryModuleEnabled(), 'GetInventoryModuleEnabled - Should return true');
    end;

    [Test]
    procedure TestModuleEnabledHelperFunctionsWhenDisabled()
    var
        BC14CompanyAdditionalSettings: Record "BC14CompanyAdditionalSettings";
    begin
        // [SCENARIO] Helper functions correctly return false when modules are disabled.

        // [GIVEN] Settings are created and all modules are disabled
        BC14CompanyAdditionalSettings.DeleteAll();
        BC14CompanyAdditionalSettings.GetSingleInstance();
        BC14CompanyAdditionalSettings.Validate("Migrate GL Module", false);
        BC14CompanyAdditionalSettings.Validate("Migrate Receivables Module", false);
        BC14CompanyAdditionalSettings.Validate("Migrate Payables Module", false);
        BC14CompanyAdditionalSettings.Validate("Migrate Inventory Module", false);
        BC14CompanyAdditionalSettings.Modify();

        // [WHEN] Helper functions are called after disabling
        // Need to re-read from DB through helper functions (which call GetSingleInstance)
        Clear(BC14CompanyAdditionalSettings);

        // [THEN] All modules should be disabled
        Assert.AreEqual(false, BC14CompanyAdditionalSettings.GetGLModuleEnabled(), 'GetGLModuleEnabled - Should return false');
        Assert.AreEqual(false, BC14CompanyAdditionalSettings.GetReceivablesModuleEnabled(), 'GetReceivablesModuleEnabled - Should return false');
        Assert.AreEqual(false, BC14CompanyAdditionalSettings.GetPayablesModuleEnabled(), 'GetPayablesModuleEnabled - Should return false');
        Assert.AreEqual(false, BC14CompanyAdditionalSettings.GetInventoryModuleEnabled(), 'GetInventoryModuleEnabled - Should return false');
    end;

    [Test]
    procedure TestDataMigrationStartedFlag()
    var
        BC14CompanyAdditionalSettings: Record "BC14CompanyAdditionalSettings";
    begin
        // [SCENARIO] Data Migration Started flag works correctly.

        // [GIVEN] Settings are created for the current company
        BC14CompanyAdditionalSettings.DeleteAll();
        BC14CompanyAdditionalSettings.GetSingleInstance();

        // [THEN] Data Migration Started should be false initially
        Assert.AreEqual(false, BC14CompanyAdditionalSettings.IsDataMigrationStarted(), 'IsDataMigrationStarted - Should be false initially');

        // [WHEN] SetDataMigrationStarted is called
        BC14CompanyAdditionalSettings.SetDataMigrationStarted();

        // [THEN] Data Migration Started should be true, with a timestamp
        Clear(BC14CompanyAdditionalSettings);
        BC14CompanyAdditionalSettings.GetSingleInstance();
        Assert.AreEqual(true, BC14CompanyAdditionalSettings.IsDataMigrationStarted(), 'IsDataMigrationStarted - Should be true after SetDataMigrationStarted');
        Assert.AreNotEqual(0DT, BC14CompanyAdditionalSettings."Data Migration Started At", 'Data Migration Started At - Should have a timestamp');
    end;

    [Test]
    procedure TestSetDataMigrationStartedIsIdempotent()
    var
        BC14CompanyAdditionalSettings: Record "BC14CompanyAdditionalSettings";
        FirstTimestamp: DateTime;
    begin
        // [SCENARIO] Calling SetDataMigrationStarted multiple times does not update the timestamp.

        // [GIVEN] Settings are created and migration is started
        BC14CompanyAdditionalSettings.DeleteAll();
        BC14CompanyAdditionalSettings.GetSingleInstance();
        BC14CompanyAdditionalSettings.SetDataMigrationStarted();

        // Record the first timestamp
        Clear(BC14CompanyAdditionalSettings);
        BC14CompanyAdditionalSettings.GetSingleInstance();
        FirstTimestamp := BC14CompanyAdditionalSettings."Data Migration Started At";

        // [WHEN] SetDataMigrationStarted is called again
        BC14CompanyAdditionalSettings.SetDataMigrationStarted();

        // [THEN] The timestamp should not change (idempotent)
        Clear(BC14CompanyAdditionalSettings);
        BC14CompanyAdditionalSettings.GetSingleInstance();
        Assert.AreEqual(FirstTimestamp, BC14CompanyAdditionalSettings."Data Migration Started At", 'Data Migration Started At - Should not change on second call');
    end;

    [Test]
    procedure TestSkipPostingJournalBatchesSetting()
    var
        BC14CompanyAdditionalSettings: Record "BC14CompanyAdditionalSettings";
    begin
        // [SCENARIO] Skip Posting Journal Batches setting works correctly.

        // [GIVEN] Settings are created for the current company
        BC14CompanyAdditionalSettings.DeleteAll();
        BC14CompanyAdditionalSettings.GetSingleInstance();

        // [THEN] Skip Posting should be false initially
        Assert.AreEqual(false, BC14CompanyAdditionalSettings.GetSkipPostingJournalBatches(), 'GetSkipPostingJournalBatches - Should be false initially');

        // [WHEN] Skip Posting is enabled
        BC14CompanyAdditionalSettings.Validate("Skip Posting Journal Batches", true);
        BC14CompanyAdditionalSettings.Modify();

        // [THEN] Skip Posting should be true
        Clear(BC14CompanyAdditionalSettings);
        Assert.AreEqual(true, BC14CompanyAdditionalSettings.GetSkipPostingJournalBatches(), 'GetSkipPostingJournalBatches - Should be true after enabling');
    end;

    [Test]
    procedure TestThirdCompanyHasDefaultSettings()
    var
        BC14CompanyAdditionalSettings: Record "BC14CompanyAdditionalSettings";
    begin
        // [SCENARIO] A third company that was not explicitly configured has default settings.

        // [GIVEN] Settings entries are created
        BC14TestHelperFunctions.CreateSettingsTableEntries();

        // [WHEN] Reading Company 3 settings (not explicitly configured beyond insert)
        BC14CompanyAdditionalSettings.Get('Company 3');

        // [THEN] It should have default values (InitValue = true for modules, false for flags)
        Assert.AreEqual('Company 3', BC14CompanyAdditionalSettings.Name, 'Incorrect company settings found');
        Assert.AreEqual(true, BC14CompanyAdditionalSettings."Migrate GL Module", 'Migrate GL Module - Should have default true');
        Assert.AreEqual(true, BC14CompanyAdditionalSettings."Migrate Receivables Module", 'Migrate Receivables Module - Should have default true');
        Assert.AreEqual(true, BC14CompanyAdditionalSettings."Migrate Payables Module", 'Migrate Payables Module - Should have default true');
        Assert.AreEqual(true, BC14CompanyAdditionalSettings."Migrate Inventory Module", 'Migrate Inventory Module - Should have default true');
        Assert.AreEqual(false, BC14CompanyAdditionalSettings."Data Migration Started", 'Data Migration Started - Should have default false');
        Assert.AreEqual(false, BC14CompanyAdditionalSettings."Skip Posting Journal Batches", 'Skip Posting Journal Batches - Should have default false');
    end;
}
