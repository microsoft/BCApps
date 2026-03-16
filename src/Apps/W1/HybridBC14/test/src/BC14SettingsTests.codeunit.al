// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration.BC14;
using Microsoft.Sales.Customer;

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

    [Test]
    procedure TestStopOnFirstErrorDefaultValue()
    var
        BC14CompanyAdditionalSettings: Record "BC14CompanyAdditionalSettings";
    begin
        // [SCENARIO] Stop On First Error setting has correct default value.

        // [GIVEN] Settings are created for the current company
        BC14CompanyAdditionalSettings.DeleteAll();
        BC14CompanyAdditionalSettings.GetSingleInstance();

        // [THEN] Stop On First Error should be false initially (default behavior is continue on error)
        Assert.AreEqual(false, BC14CompanyAdditionalSettings."Stop On First Error", 'Stop On First Error - Should be false by default');
        Assert.AreEqual(false, BC14CompanyAdditionalSettings.GetStopOnFirstTransformationError(), 'GetStopOnFirstTransformationError - Should return false by default');
    end;

    [Test]
    procedure TestStopOnFirstErrorCanBeEnabled()
    var
        BC14CompanyAdditionalSettings: Record "BC14CompanyAdditionalSettings";
    begin
        // [SCENARIO] Stop On First Error setting can be enabled.

        // [GIVEN] Settings are created for the current company with default values
        BC14CompanyAdditionalSettings.DeleteAll();
        BC14CompanyAdditionalSettings.GetSingleInstance();

        // [WHEN] Stop On First Error is enabled
        BC14CompanyAdditionalSettings.Validate("Stop On First Error", true);
        BC14CompanyAdditionalSettings.Modify();

        // [THEN] Stop On First Error should be true
        Clear(BC14CompanyAdditionalSettings);
        Assert.AreEqual(true, BC14CompanyAdditionalSettings.GetStopOnFirstTransformationError(), 'GetStopOnFirstTransformationError - Should return true after enabling');
    end;

    [Test]
    procedure TestStopOnFirstErrorCanBeDisabled()
    var
        BC14CompanyAdditionalSettings: Record "BC14CompanyAdditionalSettings";
    begin
        // [SCENARIO] Stop On First Error setting can be disabled after being enabled.

        // [GIVEN] Settings are created with Stop On First Error enabled
        BC14CompanyAdditionalSettings.DeleteAll();
        BC14CompanyAdditionalSettings.GetSingleInstance();
        BC14CompanyAdditionalSettings.Validate("Stop On First Error", true);
        BC14CompanyAdditionalSettings.Modify();

        // Verify it's enabled
        Clear(BC14CompanyAdditionalSettings);
        Assert.AreEqual(true, BC14CompanyAdditionalSettings.GetStopOnFirstTransformationError(), 'GetStopOnFirstTransformationError - Should be true');

        // [WHEN] Stop On First Error is disabled
        BC14CompanyAdditionalSettings.GetSingleInstance();
        BC14CompanyAdditionalSettings.Validate("Stop On First Error", false);
        BC14CompanyAdditionalSettings.Modify();

        // [THEN] Stop On First Error should be false
        Clear(BC14CompanyAdditionalSettings);
        Assert.AreEqual(false, BC14CompanyAdditionalSettings.GetStopOnFirstTransformationError(), 'GetStopOnFirstTransformationError - Should return false after disabling');
    end;

    [Test]
    procedure TestStopOnFirstErrorIndependentOfOtherSettings()
    var
        BC14CompanyAdditionalSettings: Record "BC14CompanyAdditionalSettings";
    begin
        // [SCENARIO] Stop On First Error setting is independent of module settings.

        // [GIVEN] Settings are created with all modules enabled and Stop On First Error enabled
        BC14CompanyAdditionalSettings.DeleteAll();
        BC14CompanyAdditionalSettings.GetSingleInstance();
        BC14CompanyAdditionalSettings.Validate("Stop On First Error", true);
        BC14CompanyAdditionalSettings.Modify();

        // [WHEN] All module settings are disabled
        BC14CompanyAdditionalSettings.Validate("Migrate GL Module", false);
        BC14CompanyAdditionalSettings.Validate("Migrate Receivables Module", false);
        BC14CompanyAdditionalSettings.Validate("Migrate Payables Module", false);
        BC14CompanyAdditionalSettings.Validate("Migrate Inventory Module", false);
        BC14CompanyAdditionalSettings.Modify();

        // [THEN] Stop On First Error should remain true (independent of module settings)
        Clear(BC14CompanyAdditionalSettings);
        Assert.AreEqual(true, BC14CompanyAdditionalSettings.GetStopOnFirstTransformationError(), 'GetStopOnFirstTransformationError - Should remain true after disabling modules');
        Assert.AreEqual(false, BC14CompanyAdditionalSettings.GetGLModuleEnabled(), 'GetGLModuleEnabled - Should be false');
        Assert.AreEqual(false, BC14CompanyAdditionalSettings.GetReceivablesModuleEnabled(), 'GetReceivablesModuleEnabled - Should be false');
    end;

    [Test]
    procedure TestStopOnFirstErrorWithSkipPostingCombination()
    var
        BC14CompanyAdditionalSettings: Record "BC14CompanyAdditionalSettings";
    begin
        // [SCENARIO] Stop On First Error and Skip Posting Journal Batches can be set independently.

        // [GIVEN] Settings are created for the current company
        BC14CompanyAdditionalSettings.DeleteAll();
        BC14CompanyAdditionalSettings.GetSingleInstance();

        // [WHEN] Both settings are enabled
        BC14CompanyAdditionalSettings.Validate("Stop On First Error", true);
        BC14CompanyAdditionalSettings.Validate("Skip Posting Journal Batches", true);
        BC14CompanyAdditionalSettings.Modify();

        // [THEN] Both settings should be true independently
        Clear(BC14CompanyAdditionalSettings);
        Assert.AreEqual(true, BC14CompanyAdditionalSettings.GetStopOnFirstTransformationError(), 'GetStopOnFirstTransformationError - Should be true');
        Assert.AreEqual(true, BC14CompanyAdditionalSettings.GetSkipPostingJournalBatches(), 'GetSkipPostingJournalBatches - Should be true');
    end;

    [Test]
    procedure TestMigrationStateDefaultValue()
    var
        BC14CompanyAdditionalSettings: Record "BC14CompanyAdditionalSettings";
    begin
        // [SCENARIO] Migration State has correct default value.

        // [GIVEN] Settings are created for the current company
        BC14CompanyAdditionalSettings.DeleteAll();
        BC14CompanyAdditionalSettings.GetSingleInstance();

        // [THEN] Migration State should be NotStarted by default
        Assert.AreEqual("BC14 Migration State"::NotStarted, BC14CompanyAdditionalSettings."Migration State", 'Migration State - Should be NotStarted by default');
        Assert.AreEqual("BC14 Migration State"::NotStarted, BC14CompanyAdditionalSettings.GetMigrationState(), 'GetMigrationState - Should return NotStarted');
        Assert.AreEqual(false, BC14CompanyAdditionalSettings.IsMigrationPaused(), 'IsMigrationPaused - Should be false initially');
    end;

    [Test]
    procedure TestPauseMigration()
    var
        BC14CompanyAdditionalSettings: Record "BC14CompanyAdditionalSettings";
    begin
        // [SCENARIO] PauseMigration correctly sets the migration state and failed migrator info.

        // [GIVEN] Settings are created for the current company
        BC14CompanyAdditionalSettings.DeleteAll();
        BC14CompanyAdditionalSettings.GetSingleInstance();

        // [WHEN] PauseMigration is called with a migrator name
        BC14CompanyAdditionalSettings.PauseMigration('G/L Account Migrator');

        // [THEN] Migration state should be Paused with correct info
        Clear(BC14CompanyAdditionalSettings);
        BC14CompanyAdditionalSettings.GetSingleInstance();
        Assert.AreEqual("BC14 Migration State"::Paused, BC14CompanyAdditionalSettings."Migration State", 'Migration State - Should be Paused');
        Assert.AreEqual(true, BC14CompanyAdditionalSettings.IsMigrationPaused(), 'IsMigrationPaused - Should be true');
        Assert.AreEqual('G/L Account Migrator', BC14CompanyAdditionalSettings."Failed Migrator Name", 'Failed Migrator Name - Should match');
        Assert.AreNotEqual(0DT, BC14CompanyAdditionalSettings."Migration Paused At", 'Migration Paused At - Should have timestamp');
    end;

    [Test]
    procedure TestSetMigrationPhaseCompleted()
    var
        BC14CompanyAdditionalSettings: Record "BC14CompanyAdditionalSettings";
    begin
        // [SCENARIO] SetMigrationPhaseCompleted correctly tracks completed phases.

        // [GIVEN] Settings are created for the current company
        BC14CompanyAdditionalSettings.DeleteAll();
        BC14CompanyAdditionalSettings.GetSingleInstance();

        // [WHEN] Setup phase is marked as completed
        BC14CompanyAdditionalSettings.SetMigrationPhaseCompleted("BC14 Migration State"::Setup, 'Dimension Migrator');

        // [THEN] Last completed phase should be Setup
        Clear(BC14CompanyAdditionalSettings);
        BC14CompanyAdditionalSettings.GetSingleInstance();
        Assert.AreEqual("BC14 Migration State"::Setup, BC14CompanyAdditionalSettings."Last Completed Phase", 'Last Completed Phase - Should be Setup');
        Assert.AreEqual("BC14 Migration State"::Setup, BC14CompanyAdditionalSettings.GetLastCompletedPhase(), 'GetLastCompletedPhase - Should return Setup');
        Assert.AreEqual('Dimension Migrator', BC14CompanyAdditionalSettings."Last Completed Migrator", 'Last Completed Migrator - Should match');
    end;

    [Test]
    procedure TestResetMigrationProgress()
    var
        BC14CompanyAdditionalSettings: Record "BC14CompanyAdditionalSettings";
    begin
        // [SCENARIO] ResetMigrationProgress clears all migration-related fields.

        // [GIVEN] Settings are created with migration in progress and paused
        BC14CompanyAdditionalSettings.DeleteAll();
        BC14CompanyAdditionalSettings.GetSingleInstance();
        BC14CompanyAdditionalSettings.SetDataMigrationStarted();
        BC14CompanyAdditionalSettings.SetMigrationState("BC14 Migration State"::Master);
        BC14CompanyAdditionalSettings.SetMigrationPhaseCompleted("BC14 Migration State"::Setup, 'Dimension Migrator');
        BC14CompanyAdditionalSettings.PauseMigration('Customer Migrator');

        // Verify paused state
        Clear(BC14CompanyAdditionalSettings);
        BC14CompanyAdditionalSettings.GetSingleInstance();
        Assert.AreEqual(true, BC14CompanyAdditionalSettings.IsMigrationPaused(), 'Pre-check: Should be paused');
        Assert.AreEqual(true, BC14CompanyAdditionalSettings."Data Migration Started", 'Pre-check: Data Migration Started should be true');

        // [WHEN] ResetMigrationProgress is called
        BC14CompanyAdditionalSettings.ResetMigrationProgress();

        // [THEN] All migration-related fields should be cleared
        Clear(BC14CompanyAdditionalSettings);
        BC14CompanyAdditionalSettings.GetSingleInstance();
        Assert.AreEqual("BC14 Migration State"::NotStarted, BC14CompanyAdditionalSettings."Migration State", 'Migration State - Should be NotStarted');
        Assert.AreEqual("BC14 Migration State"::NotStarted, BC14CompanyAdditionalSettings."Last Completed Phase", 'Last Completed Phase - Should be NotStarted');
        Assert.AreEqual('', BC14CompanyAdditionalSettings."Last Completed Migrator", 'Last Completed Migrator - Should be empty');
        Assert.AreEqual(0DT, BC14CompanyAdditionalSettings."Migration Paused At", 'Migration Paused At - Should be cleared');
        Assert.AreEqual('', BC14CompanyAdditionalSettings."Failed Migrator Name", 'Failed Migrator Name - Should be empty');
        Assert.AreEqual(false, BC14CompanyAdditionalSettings."Data Migration Started", 'Data Migration Started - Should be false');
        Assert.AreEqual(0DT, BC14CompanyAdditionalSettings."Data Migration Started At", 'Data Migration Started At - Should be cleared');
    end;

    [Test]
    procedure TestPauseFixContinueWorkflow()
    var
        BC14CompanyAdditionalSettings: Record "BC14CompanyAdditionalSettings";
        BC14MigrationErrors: Record "BC14 Migration Errors";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        DummyRecordRef: RecordRef;
        DummyRecId: RecordId;
    begin
        // [SCENARIO] Full workflow: Migration pauses on error, user fixes it, then continues.
        // This tests the complete pause -> fix -> continue flow.

        // [GIVEN] Settings with Stop On First Error enabled
        BC14CompanyAdditionalSettings.DeleteAll();
        BC14MigrationErrors.DeleteAll();

        BC14CompanyAdditionalSettings.GetSingleInstance();
        BC14CompanyAdditionalSettings.Validate("Stop On First Error", true);
        BC14CompanyAdditionalSettings.Modify();

        // Simulate migration started and Setup phase completed
        BC14CompanyAdditionalSettings.SetDataMigrationStarted();
        BC14CompanyAdditionalSettings.SetMigrationState("BC14 Migration State"::Master);
        BC14CompanyAdditionalSettings.SetMigrationPhaseCompleted("BC14 Migration State"::Setup, '');

        // [WHEN] An error occurs during Master migration
        DummyRecordRef.Open(Database::"BC14 Migration Errors");
        DummyRecId := DummyRecordRef.RecordId;
        DummyRecordRef.Close();

        BC14MigrationErrorHandler.LogError(
            'Customer Migrator',
            Database::"BC14 Customer",
            'BC14 Customer',
            'No.=C001',
            Database::Customer,
            'Name cannot be empty',
            DummyRecId
        );

        // Simulate migration pausing due to error
        BC14CompanyAdditionalSettings.PauseMigration('Customer Migrator');

        // [THEN] Migration should be paused
        Clear(BC14CompanyAdditionalSettings);
        BC14CompanyAdditionalSettings.GetSingleInstance();
        Assert.AreEqual(true, BC14CompanyAdditionalSettings.IsMigrationPaused(), 'Should be paused after error');
        Assert.AreEqual('Customer Migrator', BC14CompanyAdditionalSettings."Failed Migrator Name", 'Failed migrator should be Customer Migrator');
        Assert.AreEqual("BC14 Migration State"::Setup, BC14CompanyAdditionalSettings.GetLastCompletedPhase(), 'Last completed phase should be Setup');

        // [WHEN] User fixes the error (unblocks the record)
        BC14MigrationErrors.FindFirst();
        BC14MigrationErrors.UnblockForRetry('Fixed: Added customer name');

        // [THEN] Error should be unblocked and scheduled for retry
        BC14MigrationErrors.Get(BC14MigrationErrors.Id);
        Assert.AreEqual(false, BC14MigrationErrors."Resolved", 'Error should not be resolved yet');
        Assert.AreEqual(true, BC14MigrationErrors."Scheduled For Retry", 'Error should be scheduled for retry');
        Assert.AreEqual('Fixed: Added customer name', BC14MigrationErrors."Resolution Notes", 'Resolution notes should match');

        // [WHEN] User continues migration (simulated - just verify state would allow it)
        // Note: Actually calling ContinueMigration would require full migrator setup.
        // Here we just verify the state is correct for continuing.

        // [THEN] Migration state should allow continuation
        Clear(BC14CompanyAdditionalSettings);
        Assert.AreEqual(true, BC14CompanyAdditionalSettings.IsMigrationPaused(), 'Should still be paused until ContinueMigration is called');
        Assert.AreEqual("BC14 Migration State"::Setup, BC14CompanyAdditionalSettings.GetLastCompletedPhase(), 'Should resume from after Setup phase');
    end;

    [Test]
    procedure TestMigrationStateTransitions()
    var
        BC14CompanyAdditionalSettings: Record "BC14CompanyAdditionalSettings";
    begin
        // [SCENARIO] Migration state can transition through all phases correctly.

        // [GIVEN] Settings are created for the current company
        BC14CompanyAdditionalSettings.DeleteAll();
        BC14CompanyAdditionalSettings.GetSingleInstance();

        // [THEN] Initial state should be NotStarted
        Assert.AreEqual("BC14 Migration State"::NotStarted, BC14CompanyAdditionalSettings.GetMigrationState(), 'Initial state should be NotStarted');

        // [WHEN] Migration progresses through phases
        BC14CompanyAdditionalSettings.SetMigrationState("BC14 Migration State"::Setup);
        Assert.AreEqual("BC14 Migration State"::Setup, BC14CompanyAdditionalSettings.GetMigrationState(), 'State should be Setup');

        BC14CompanyAdditionalSettings.SetMigrationState("BC14 Migration State"::Master);
        Assert.AreEqual("BC14 Migration State"::Master, BC14CompanyAdditionalSettings.GetMigrationState(), 'State should be Master');

        BC14CompanyAdditionalSettings.SetMigrationState("BC14 Migration State"::Transaction);
        Assert.AreEqual("BC14 Migration State"::Transaction, BC14CompanyAdditionalSettings.GetMigrationState(), 'State should be Transaction');

        BC14CompanyAdditionalSettings.SetMigrationState("BC14 Migration State"::Historical);
        Assert.AreEqual("BC14 Migration State"::Historical, BC14CompanyAdditionalSettings.GetMigrationState(), 'State should be Historical');

        BC14CompanyAdditionalSettings.SetMigrationState("BC14 Migration State"::Posting);
        Assert.AreEqual("BC14 Migration State"::Posting, BC14CompanyAdditionalSettings.GetMigrationState(), 'State should be Posting');

        BC14CompanyAdditionalSettings.SetMigrationState("BC14 Migration State"::Completed);
        Assert.AreEqual("BC14 Migration State"::Completed, BC14CompanyAdditionalSettings.GetMigrationState(), 'State should be Completed');
    end;

    [Test]
    procedure TestCannotContinueWhenNotPaused()
    var
        BC14CompanyAdditionalSettings: Record "BC14CompanyAdditionalSettings";
    begin
        // [SCENARIO] IsMigrationPaused returns false when migration is not paused.

        // [GIVEN] Settings are created with migration in progress (not paused)
        BC14CompanyAdditionalSettings.DeleteAll();
        BC14CompanyAdditionalSettings.GetSingleInstance();
        BC14CompanyAdditionalSettings.SetMigrationState("BC14 Migration State"::Master);

        // [THEN] IsMigrationPaused should return false
        Assert.AreEqual(false, BC14CompanyAdditionalSettings.IsMigrationPaused(), 'Should not be paused when state is Master');

        // [WHEN] State is NotStarted
        BC14CompanyAdditionalSettings.SetMigrationState("BC14 Migration State"::NotStarted);

        // [THEN] IsMigrationPaused should still return false
        Assert.AreEqual(false, BC14CompanyAdditionalSettings.IsMigrationPaused(), 'Should not be paused when state is NotStarted');

        // [WHEN] State is Completed
        BC14CompanyAdditionalSettings.SetMigrationState("BC14 Migration State"::Completed);

        // [THEN] IsMigrationPaused should still return false
        Assert.AreEqual(false, BC14CompanyAdditionalSettings.IsMigrationPaused(), 'Should not be paused when state is Completed');
    end;
}
