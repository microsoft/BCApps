// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration.BC14;
using Microsoft.Sales.Customer;

codeunit 148915 "BC14 Settings Tests"
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
        BC14CompanyMigrationSettings: Record "BC14CompanyMigrationSettings";
    begin
        // [SCENARIO] Settings are initialized with correct default values for a new BC14 migration.

        // [GIVEN] Some records are created in the settings table
        BC14TestHelperFunctions.CreateSettingsTableEntries();

        // [THEN] The settings are initialized with the correct default values
        Clear(BC14CompanyMigrationSettings);
        BC14CompanyMigrationSettings.Get('Company 1');

        Assert.AreEqual('Company 1', BC14CompanyMigrationSettings.Name, 'Incorrect company settings found');
        Assert.AreEqual(true, BC14CompanyMigrationSettings."Migrate GL Module", 'Migrate GL Module - Incorrect default value');
        Assert.AreEqual(true, BC14CompanyMigrationSettings."Migrate Receivables Module", 'Migrate Receivables Module - Incorrect default value');
        Assert.AreEqual(true, BC14CompanyMigrationSettings."Migrate Payables Module", 'Migrate Payables Module - Incorrect default value');
        Assert.AreEqual(true, BC14CompanyMigrationSettings."Migrate Inventory Module", 'Migrate Inventory Module - Incorrect default value');
        Assert.AreEqual(false, BC14CompanyMigrationSettings."Data Migration Started", 'Data Migration Started - Incorrect default value');
        Assert.AreEqual(false, BC14CompanyMigrationSettings."Skip Posting Journal Batches", 'Skip Posting Journal Batches - Incorrect default value');
        Assert.AreEqual(false, BC14CompanyMigrationSettings.ProcessesAreRunning, 'ProcessesAreRunning - Incorrect default value');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestGLModuleCanBeDisabled()
    var
        BC14CompanyMigrationSettings: Record "BC14CompanyMigrationSettings";
    begin
        // [SCENARIO] The GL Module setting can be independently disabled.

        // [GIVEN] Some records are created in the settings table with all settings enabled
        BC14TestHelperFunctions.CreateSettingsTableEntries();

        // [WHEN] The GL module setting is disabled
        Clear(BC14CompanyMigrationSettings);
        BC14CompanyMigrationSettings.Get('Company 2');
        BC14CompanyMigrationSettings.Validate("Migrate GL Module", false);
        BC14CompanyMigrationSettings.Modify();

        // [THEN] The GL Module is disabled but other modules remain enabled
        Assert.AreEqual(false, BC14CompanyMigrationSettings."Migrate GL Module", 'Migrate GL Module - Should be disabled');
        Assert.AreEqual(true, BC14CompanyMigrationSettings."Migrate Receivables Module", 'Migrate Receivables Module - Should remain enabled');
        Assert.AreEqual(true, BC14CompanyMigrationSettings."Migrate Payables Module", 'Migrate Payables Module - Should remain enabled');
        Assert.AreEqual(true, BC14CompanyMigrationSettings."Migrate Inventory Module", 'Migrate Inventory Module - Should remain enabled');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestReceivablesModuleCanBeDisabled()
    var
        BC14CompanyMigrationSettings: Record "BC14CompanyMigrationSettings";
    begin
        // [SCENARIO] The Receivables Module setting can be independently disabled.

        // [GIVEN] Some records are created in the settings table with all settings enabled
        BC14TestHelperFunctions.CreateSettingsTableEntries();

        // [WHEN] The Receivables module setting is disabled
        Clear(BC14CompanyMigrationSettings);
        BC14CompanyMigrationSettings.Get('Company 2');
        BC14CompanyMigrationSettings.Validate("Migrate Receivables Module", false);
        BC14CompanyMigrationSettings.Modify();

        // [THEN] The Receivables Module is disabled but other modules remain enabled
        Assert.AreEqual(true, BC14CompanyMigrationSettings."Migrate GL Module", 'Migrate GL Module - Should remain enabled');
        Assert.AreEqual(false, BC14CompanyMigrationSettings."Migrate Receivables Module", 'Migrate Receivables Module - Should be disabled');
        Assert.AreEqual(true, BC14CompanyMigrationSettings."Migrate Payables Module", 'Migrate Payables Module - Should remain enabled');
        Assert.AreEqual(true, BC14CompanyMigrationSettings."Migrate Inventory Module", 'Migrate Inventory Module - Should remain enabled');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestPayablesModuleCanBeDisabled()
    var
        BC14CompanyMigrationSettings: Record "BC14CompanyMigrationSettings";
    begin
        // [SCENARIO] The Payables Module setting can be independently disabled.

        // [GIVEN] Some records are created in the settings table with all settings enabled
        BC14TestHelperFunctions.CreateSettingsTableEntries();

        // [WHEN] The Payables module setting is disabled
        Clear(BC14CompanyMigrationSettings);
        BC14CompanyMigrationSettings.Get('Company 2');
        BC14CompanyMigrationSettings.Validate("Migrate Payables Module", false);
        BC14CompanyMigrationSettings.Modify();

        // [THEN] The Payables Module is disabled but other modules remain enabled
        Assert.AreEqual(true, BC14CompanyMigrationSettings."Migrate GL Module", 'Migrate GL Module - Should remain enabled');
        Assert.AreEqual(true, BC14CompanyMigrationSettings."Migrate Receivables Module", 'Migrate Receivables Module - Should remain enabled');
        Assert.AreEqual(false, BC14CompanyMigrationSettings."Migrate Payables Module", 'Migrate Payables Module - Should be disabled');
        Assert.AreEqual(true, BC14CompanyMigrationSettings."Migrate Inventory Module", 'Migrate Inventory Module - Should remain enabled');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestInventoryModuleCanBeDisabled()
    var
        BC14CompanyMigrationSettings: Record "BC14CompanyMigrationSettings";
    begin
        // [SCENARIO] The Inventory Module setting can be independently disabled.

        // [GIVEN] Some records are created in the settings table with all settings enabled
        BC14TestHelperFunctions.CreateSettingsTableEntries();

        // [WHEN] The Inventory module setting is disabled
        Clear(BC14CompanyMigrationSettings);
        BC14CompanyMigrationSettings.Get('Company 2');
        BC14CompanyMigrationSettings.Validate("Migrate Inventory Module", false);
        BC14CompanyMigrationSettings.Modify();

        // [THEN] The Inventory Module is disabled but other modules remain enabled
        Assert.AreEqual(true, BC14CompanyMigrationSettings."Migrate GL Module", 'Migrate GL Module - Should remain enabled');
        Assert.AreEqual(true, BC14CompanyMigrationSettings."Migrate Receivables Module", 'Migrate Receivables Module - Should remain enabled');
        Assert.AreEqual(true, BC14CompanyMigrationSettings."Migrate Payables Module", 'Migrate Payables Module - Should remain enabled');
        Assert.AreEqual(false, BC14CompanyMigrationSettings."Migrate Inventory Module", 'Migrate Inventory Module - Should be disabled');
    end;

    [Test]
    procedure TestAllModulesCanBeDisabled()
    var
        BC14CompanyMigrationSettings: Record "BC14CompanyMigrationSettings";
    begin
        // [SCENARIO] All modules can be disabled simultaneously.

        // [GIVEN] Settings are created with all modules enabled
        BC14TestHelperFunctions.CreateSettingsTableEntries();

        // [WHEN] All module settings are disabled
        Clear(BC14CompanyMigrationSettings);
        BC14CompanyMigrationSettings.Get('Company 2');
        BC14CompanyMigrationSettings.Validate("Migrate GL Module", false);
        BC14CompanyMigrationSettings.Validate("Migrate Receivables Module", false);
        BC14CompanyMigrationSettings.Validate("Migrate Payables Module", false);
        BC14CompanyMigrationSettings.Validate("Migrate Inventory Module", false);
        BC14CompanyMigrationSettings.Modify();

        // [THEN] All modules are disabled
        Assert.AreEqual(false, BC14CompanyMigrationSettings."Migrate GL Module", 'Migrate GL Module - Should be disabled');
        Assert.AreEqual(false, BC14CompanyMigrationSettings."Migrate Receivables Module", 'Migrate Receivables Module - Should be disabled');
        Assert.AreEqual(false, BC14CompanyMigrationSettings."Migrate Payables Module", 'Migrate Payables Module - Should be disabled');
        Assert.AreEqual(false, BC14CompanyMigrationSettings."Migrate Inventory Module", 'Migrate Inventory Module - Should be disabled');
    end;

    [Test]
    procedure TestGetSingleInstanceCreatesRecordIfNotExists()
    var
        BC14CompanyMigrationSettings: Record "BC14CompanyMigrationSettings";
    begin
        // [SCENARIO] GetSingleInstance creates a record if it does not exist.

        // [GIVEN] No records exist for the current company
        BC14CompanyMigrationSettings.DeleteAll();

        // [WHEN] GetSingleInstance is called
        BC14CompanyMigrationSettings.GetSingleInstance();

        // [THEN] A record is created for the current company with default values
        Assert.AreEqual(CompanyName(), BC14CompanyMigrationSettings.Name, 'Record should be created for the current company');
        Assert.AreEqual(true, BC14CompanyMigrationSettings."Migrate GL Module", 'Migrate GL Module - Should have default true');
        Assert.AreEqual(true, BC14CompanyMigrationSettings."Migrate Receivables Module", 'Migrate Receivables Module - Should have default true');
        Assert.AreEqual(true, BC14CompanyMigrationSettings."Migrate Payables Module", 'Migrate Payables Module - Should have default true');
        Assert.AreEqual(true, BC14CompanyMigrationSettings."Migrate Inventory Module", 'Migrate Inventory Module - Should have default true');
    end;

    [Test]
    procedure TestModuleEnabledHelperFunctions()
    var
        BC14CompanyMigrationSettings: Record "BC14CompanyMigrationSettings";
    begin
        // [SCENARIO] Helper functions correctly return module enabled status.

        // [GIVEN] Settings are created with default values
        BC14CompanyMigrationSettings.DeleteAll();

        // [WHEN] Helper functions are called
        // [THEN] All modules should be enabled by default
        Assert.AreEqual(true, BC14CompanyMigrationSettings.GetGLModuleEnabled(), 'GetGLModuleEnabled - Should return true');
        Assert.AreEqual(true, BC14CompanyMigrationSettings.GetReceivablesModuleEnabled(), 'GetReceivablesModuleEnabled - Should return true');
        Assert.AreEqual(true, BC14CompanyMigrationSettings.GetPayablesModuleEnabled(), 'GetPayablesModuleEnabled - Should return true');
        Assert.AreEqual(true, BC14CompanyMigrationSettings.GetInventoryModuleEnabled(), 'GetInventoryModuleEnabled - Should return true');
    end;

    [Test]
    procedure TestModuleEnabledHelperFunctionsWhenDisabled()
    var
        BC14CompanyMigrationSettings: Record "BC14CompanyMigrationSettings";
    begin
        // [SCENARIO] Helper functions correctly return false when modules are disabled.

        // [GIVEN] Settings are created and all modules are disabled
        BC14CompanyMigrationSettings.DeleteAll();
        BC14CompanyMigrationSettings.GetSingleInstance();
        BC14CompanyMigrationSettings.Validate("Migrate GL Module", false);
        BC14CompanyMigrationSettings.Validate("Migrate Receivables Module", false);
        BC14CompanyMigrationSettings.Validate("Migrate Payables Module", false);
        BC14CompanyMigrationSettings.Validate("Migrate Inventory Module", false);
        BC14CompanyMigrationSettings.Modify();

        // [WHEN] Helper functions are called after disabling
        // Need to re-read from DB through helper functions (which call GetSingleInstance)
        Clear(BC14CompanyMigrationSettings);

        // [THEN] All modules should be disabled
        Assert.AreEqual(false, BC14CompanyMigrationSettings.GetGLModuleEnabled(), 'GetGLModuleEnabled - Should return false');
        Assert.AreEqual(false, BC14CompanyMigrationSettings.GetReceivablesModuleEnabled(), 'GetReceivablesModuleEnabled - Should return false');
        Assert.AreEqual(false, BC14CompanyMigrationSettings.GetPayablesModuleEnabled(), 'GetPayablesModuleEnabled - Should return false');
        Assert.AreEqual(false, BC14CompanyMigrationSettings.GetInventoryModuleEnabled(), 'GetInventoryModuleEnabled - Should return false');
    end;

    [Test]
    procedure TestDataMigrationStartedFlag()
    var
        BC14CompanyMigrationSettings: Record "BC14CompanyMigrationSettings";
    begin
        // [SCENARIO] Data Migration Started flag works correctly.

        // [GIVEN] Settings are created for the current company
        BC14CompanyMigrationSettings.DeleteAll();
        BC14CompanyMigrationSettings.GetSingleInstance();

        // [THEN] Data Migration Started should be false initially
        Assert.AreEqual(false, BC14CompanyMigrationSettings.IsDataMigrationStarted(), 'IsDataMigrationStarted - Should be false initially');

        // [WHEN] SetDataMigrationStarted is called
        BC14CompanyMigrationSettings.SetDataMigrationStarted();

        // [THEN] Data Migration Started should be true, with a timestamp
        Clear(BC14CompanyMigrationSettings);
        BC14CompanyMigrationSettings.GetSingleInstance();
        Assert.AreEqual(true, BC14CompanyMigrationSettings.IsDataMigrationStarted(), 'IsDataMigrationStarted - Should be true after SetDataMigrationStarted');
        Assert.AreNotEqual(0DT, BC14CompanyMigrationSettings."Data Migration Started At", 'Data Migration Started At - Should have a timestamp');
    end;

    [Test]
    procedure TestSetDataMigrationStartedIsIdempotent()
    var
        BC14CompanyMigrationSettings: Record "BC14CompanyMigrationSettings";
        FirstTimestamp: DateTime;
    begin
        // [SCENARIO] Calling SetDataMigrationStarted multiple times does not update the timestamp.

        // [GIVEN] Settings are created and migration is started
        BC14CompanyMigrationSettings.DeleteAll();
        BC14CompanyMigrationSettings.GetSingleInstance();
        BC14CompanyMigrationSettings.SetDataMigrationStarted();

        // Record the first timestamp
        Clear(BC14CompanyMigrationSettings);
        BC14CompanyMigrationSettings.GetSingleInstance();
        FirstTimestamp := BC14CompanyMigrationSettings."Data Migration Started At";

        // [WHEN] SetDataMigrationStarted is called again
        BC14CompanyMigrationSettings.SetDataMigrationStarted();

        // [THEN] The timestamp should not change (idempotent)
        Clear(BC14CompanyMigrationSettings);
        BC14CompanyMigrationSettings.GetSingleInstance();
        Assert.AreEqual(FirstTimestamp, BC14CompanyMigrationSettings."Data Migration Started At", 'Data Migration Started At - Should not change on second call');
    end;

    [Test]
    procedure TestSkipPostingJournalBatchesSetting()
    var
        BC14CompanyMigrationSettings: Record "BC14CompanyMigrationSettings";
    begin
        // [SCENARIO] Skip Posting Journal Batches setting works correctly.

        // [GIVEN] Settings are created for the current company
        BC14CompanyMigrationSettings.DeleteAll();
        BC14CompanyMigrationSettings.GetSingleInstance();

        // [THEN] Skip Posting should be false initially
        Assert.AreEqual(false, BC14CompanyMigrationSettings.GetSkipPostingJournalBatches(), 'GetSkipPostingJournalBatches - Should be false initially');

        // [WHEN] Skip Posting is enabled
        BC14CompanyMigrationSettings.Validate("Skip Posting Journal Batches", true);
        BC14CompanyMigrationSettings.Modify();

        // [THEN] Skip Posting should be true
        Clear(BC14CompanyMigrationSettings);
        Assert.AreEqual(true, BC14CompanyMigrationSettings.GetSkipPostingJournalBatches(), 'GetSkipPostingJournalBatches - Should be true after enabling');
    end;

    [Test]
    procedure TestThirdCompanyHasDefaultSettings()
    var
        BC14CompanyMigrationSettings: Record "BC14CompanyMigrationSettings";
    begin
        // [SCENARIO] A third company that was not explicitly configured has default settings.

        // [GIVEN] Settings entries are created
        BC14TestHelperFunctions.CreateSettingsTableEntries();

        // [WHEN] Reading Company 3 settings (not explicitly configured beyond insert)
        BC14CompanyMigrationSettings.Get('Company 3');

        // [THEN] It should have default values (InitValue = true for modules, false for flags)
        Assert.AreEqual('Company 3', BC14CompanyMigrationSettings.Name, 'Incorrect company settings found');
        Assert.AreEqual(true, BC14CompanyMigrationSettings."Migrate GL Module", 'Migrate GL Module - Should have default true');
        Assert.AreEqual(true, BC14CompanyMigrationSettings."Migrate Receivables Module", 'Migrate Receivables Module - Should have default true');
        Assert.AreEqual(true, BC14CompanyMigrationSettings."Migrate Payables Module", 'Migrate Payables Module - Should have default true');
        Assert.AreEqual(true, BC14CompanyMigrationSettings."Migrate Inventory Module", 'Migrate Inventory Module - Should have default true');
        Assert.AreEqual(false, BC14CompanyMigrationSettings."Data Migration Started", 'Data Migration Started - Should have default false');
        Assert.AreEqual(false, BC14CompanyMigrationSettings."Skip Posting Journal Batches", 'Skip Posting Journal Batches - Should have default false');
    end;

    [Test]
    procedure TestStopOnFirstErrorDefaultValue()
    var
        BC14CompanyMigrationSettings: Record "BC14CompanyMigrationSettings";
    begin
        // [SCENARIO] Stop On First Error setting has correct default value.

        // [GIVEN] Settings are created for the current company
        BC14CompanyMigrationSettings.DeleteAll();
        BC14CompanyMigrationSettings.GetSingleInstance();

        // [THEN] Stop On First Error should be false initially (default behavior is continue on error)
        Assert.AreEqual(false, BC14CompanyMigrationSettings."Stop On First Error", 'Stop On First Error - Should be false by default');
        Assert.AreEqual(false, BC14CompanyMigrationSettings.GetStopOnFirstTransformationError(), 'GetStopOnFirstTransformationError - Should return false by default');
    end;

    [Test]
    procedure TestStopOnFirstErrorCanBeEnabled()
    var
        BC14CompanyMigrationSettings: Record "BC14CompanyMigrationSettings";
    begin
        // [SCENARIO] Stop On First Error setting can be enabled.

        // [GIVEN] Settings are created for the current company with default values
        BC14CompanyMigrationSettings.DeleteAll();
        BC14CompanyMigrationSettings.GetSingleInstance();

        // [WHEN] Stop On First Error is enabled
        BC14CompanyMigrationSettings.Validate("Stop On First Error", true);
        BC14CompanyMigrationSettings.Modify();

        // [THEN] Stop On First Error should be true
        Clear(BC14CompanyMigrationSettings);
        Assert.AreEqual(true, BC14CompanyMigrationSettings.GetStopOnFirstTransformationError(), 'GetStopOnFirstTransformationError - Should return true after enabling');
    end;

    [Test]
    procedure TestStopOnFirstErrorCanBeDisabled()
    var
        BC14CompanyMigrationSettings: Record "BC14CompanyMigrationSettings";
    begin
        // [SCENARIO] Stop On First Error setting can be disabled after being enabled.

        // [GIVEN] Settings are created with Stop On First Error enabled
        BC14CompanyMigrationSettings.DeleteAll();
        BC14CompanyMigrationSettings.GetSingleInstance();
        BC14CompanyMigrationSettings.Validate("Stop On First Error", true);
        BC14CompanyMigrationSettings.Modify();

        // Verify it's enabled
        Clear(BC14CompanyMigrationSettings);
        Assert.AreEqual(true, BC14CompanyMigrationSettings.GetStopOnFirstTransformationError(), 'GetStopOnFirstTransformationError - Should be true');

        // [WHEN] Stop On First Error is disabled
        BC14CompanyMigrationSettings.GetSingleInstance();
        BC14CompanyMigrationSettings.Validate("Stop On First Error", false);
        BC14CompanyMigrationSettings.Modify();

        // [THEN] Stop On First Error should be false
        Clear(BC14CompanyMigrationSettings);
        Assert.AreEqual(false, BC14CompanyMigrationSettings.GetStopOnFirstTransformationError(), 'GetStopOnFirstTransformationError - Should return false after disabling');
    end;

    [Test]
    procedure TestStopOnFirstErrorIndependentOfOtherSettings()
    var
        BC14CompanyMigrationSettings: Record "BC14CompanyMigrationSettings";
    begin
        // [SCENARIO] Stop On First Error setting is independent of module settings.

        // [GIVEN] Settings are created with all modules enabled and Stop On First Error enabled
        BC14CompanyMigrationSettings.DeleteAll();
        BC14CompanyMigrationSettings.GetSingleInstance();
        BC14CompanyMigrationSettings.Validate("Stop On First Error", true);
        BC14CompanyMigrationSettings.Modify();

        // [WHEN] All module settings are disabled
        BC14CompanyMigrationSettings.Validate("Migrate GL Module", false);
        BC14CompanyMigrationSettings.Validate("Migrate Receivables Module", false);
        BC14CompanyMigrationSettings.Validate("Migrate Payables Module", false);
        BC14CompanyMigrationSettings.Validate("Migrate Inventory Module", false);
        BC14CompanyMigrationSettings.Modify();

        // [THEN] Stop On First Error should remain true (independent of module settings)
        Clear(BC14CompanyMigrationSettings);
        Assert.AreEqual(true, BC14CompanyMigrationSettings.GetStopOnFirstTransformationError(), 'GetStopOnFirstTransformationError - Should remain true after disabling modules');
        Assert.AreEqual(false, BC14CompanyMigrationSettings.GetGLModuleEnabled(), 'GetGLModuleEnabled - Should be false');
        Assert.AreEqual(false, BC14CompanyMigrationSettings.GetReceivablesModuleEnabled(), 'GetReceivablesModuleEnabled - Should be false');
    end;

    [Test]
    procedure TestStopOnFirstErrorWithSkipPostingCombination()
    var
        BC14CompanyMigrationSettings: Record "BC14CompanyMigrationSettings";
    begin
        // [SCENARIO] Stop On First Error and Skip Posting Journal Batches can be set independently.

        // [GIVEN] Settings are created for the current company
        BC14CompanyMigrationSettings.DeleteAll();
        BC14CompanyMigrationSettings.GetSingleInstance();

        // [WHEN] Both settings are enabled
        BC14CompanyMigrationSettings.Validate("Stop On First Error", true);
        BC14CompanyMigrationSettings.Validate("Skip Posting Journal Batches", true);
        BC14CompanyMigrationSettings.Modify();

        // [THEN] Both settings should be true independently
        Clear(BC14CompanyMigrationSettings);
        Assert.AreEqual(true, BC14CompanyMigrationSettings.GetStopOnFirstTransformationError(), 'GetStopOnFirstTransformationError - Should be true');
        Assert.AreEqual(true, BC14CompanyMigrationSettings.GetSkipPostingJournalBatches(), 'GetSkipPostingJournalBatches - Should be true');
    end;

    [Test]
    procedure TestMigrationStateDefaultValue()
    var
        BC14CompanyMigrationSettings: Record "BC14CompanyMigrationSettings";
    begin
        // [SCENARIO] Migration State has correct default value.

        // [GIVEN] Settings are created for the current company
        BC14CompanyMigrationSettings.DeleteAll();
        BC14CompanyMigrationSettings.GetSingleInstance();

        // [THEN] Migration State should be NotStarted by default
        Assert.AreEqual("BC14 Migration State"::NotStarted, BC14CompanyMigrationSettings."Migration State", 'Migration State - Should be NotStarted by default');
        Assert.AreEqual("BC14 Migration State"::NotStarted, BC14CompanyMigrationSettings.GetMigrationState(), 'GetMigrationState - Should return NotStarted');
        Assert.AreEqual(false, BC14CompanyMigrationSettings.IsMigrationPaused(), 'IsMigrationPaused - Should be false initially');
    end;

    [Test]
    procedure TestPauseMigration()
    var
        BC14CompanyMigrationSettings: Record "BC14CompanyMigrationSettings";
    begin
        // [SCENARIO] PauseMigration correctly sets the migration state and failed migrator info.

        // [GIVEN] Settings are created for the current company
        BC14CompanyMigrationSettings.DeleteAll();
        BC14CompanyMigrationSettings.GetSingleInstance();

        // [WHEN] PauseMigration is called with a migrator name
        BC14CompanyMigrationSettings.PauseMigration('G/L Account Migrator');

        // [THEN] Migration state should be Paused with correct info
        Clear(BC14CompanyMigrationSettings);
        BC14CompanyMigrationSettings.GetSingleInstance();
        Assert.AreEqual("BC14 Migration State"::Paused, BC14CompanyMigrationSettings."Migration State", 'Migration State - Should be Paused');
        Assert.AreEqual(true, BC14CompanyMigrationSettings.IsMigrationPaused(), 'IsMigrationPaused - Should be true');
        Assert.AreEqual('G/L Account Migrator', BC14CompanyMigrationSettings."Failed Migrator Name", 'Failed Migrator Name - Should match');
        Assert.AreNotEqual(0DT, BC14CompanyMigrationSettings."Migration Paused At", 'Migration Paused At - Should have timestamp');
    end;

    [Test]
    procedure TestSetMigrationPhaseCompleted()
    var
        BC14CompanyMigrationSettings: Record "BC14CompanyMigrationSettings";
    begin
        // [SCENARIO] SetMigrationPhaseCompleted correctly tracks completed phases.

        // [GIVEN] Settings are created for the current company
        BC14CompanyMigrationSettings.DeleteAll();
        BC14CompanyMigrationSettings.GetSingleInstance();

        // [WHEN] Setup phase is marked as completed
        BC14CompanyMigrationSettings.SetMigrationPhaseCompleted("BC14 Migration State"::Setup, 'Dimension Migrator');

        // [THEN] Last completed phase should be Setup
        Clear(BC14CompanyMigrationSettings);
        BC14CompanyMigrationSettings.GetSingleInstance();
        Assert.AreEqual("BC14 Migration State"::Setup, BC14CompanyMigrationSettings."Last Completed Phase", 'Last Completed Phase - Should be Setup');
        Assert.AreEqual("BC14 Migration State"::Setup, BC14CompanyMigrationSettings.GetLastCompletedPhase(), 'GetLastCompletedPhase - Should return Setup');
        Assert.AreEqual('Dimension Migrator', BC14CompanyMigrationSettings."Last Completed Migrator", 'Last Completed Migrator - Should match');
    end;

    [Test]
    procedure TestResetMigrationProgress()
    var
        BC14CompanyMigrationSettings: Record "BC14CompanyMigrationSettings";
    begin
        // [SCENARIO] ResetMigrationProgress clears all migration-related fields.

        // [GIVEN] Settings are created with migration in progress and paused
        BC14CompanyMigrationSettings.DeleteAll();
        BC14CompanyMigrationSettings.GetSingleInstance();
        BC14CompanyMigrationSettings.SetDataMigrationStarted();
        BC14CompanyMigrationSettings.SetMigrationState("BC14 Migration State"::Master);
        BC14CompanyMigrationSettings.SetMigrationPhaseCompleted("BC14 Migration State"::Setup, 'Dimension Migrator');
        BC14CompanyMigrationSettings.PauseMigration('Customer Migrator');

        // Verify paused state
        Clear(BC14CompanyMigrationSettings);
        BC14CompanyMigrationSettings.GetSingleInstance();
        Assert.AreEqual(true, BC14CompanyMigrationSettings.IsMigrationPaused(), 'Pre-check: Should be paused');
        Assert.AreEqual(true, BC14CompanyMigrationSettings."Data Migration Started", 'Pre-check: Data Migration Started should be true');

        // [WHEN] ResetMigrationProgress is called
        BC14CompanyMigrationSettings.ResetMigrationProgress();

        // [THEN] All migration-related fields should be cleared
        Clear(BC14CompanyMigrationSettings);
        BC14CompanyMigrationSettings.GetSingleInstance();
        Assert.AreEqual("BC14 Migration State"::NotStarted, BC14CompanyMigrationSettings."Migration State", 'Migration State - Should be NotStarted');
        Assert.AreEqual("BC14 Migration State"::NotStarted, BC14CompanyMigrationSettings."Last Completed Phase", 'Last Completed Phase - Should be NotStarted');
        Assert.AreEqual('', BC14CompanyMigrationSettings."Last Completed Migrator", 'Last Completed Migrator - Should be empty');
        Assert.AreEqual(0DT, BC14CompanyMigrationSettings."Migration Paused At", 'Migration Paused At - Should be cleared');
        Assert.AreEqual('', BC14CompanyMigrationSettings."Failed Migrator Name", 'Failed Migrator Name - Should be empty');
        Assert.AreEqual(false, BC14CompanyMigrationSettings."Data Migration Started", 'Data Migration Started - Should be false');
        Assert.AreEqual(0DT, BC14CompanyMigrationSettings."Data Migration Started At", 'Data Migration Started At - Should be cleared');
    end;

    [Test]
    procedure TestPauseFixContinueWorkflow()
    var
        BC14CompanyMigrationSettings: Record "BC14CompanyMigrationSettings";
        BC14MigrationErrors: Record "BC14 Migration Errors";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        DummyRecordRef: RecordRef;
        DummyRecId: RecordId;
    begin
        // [SCENARIO] Full workflow: Migration pauses on error, user fixes it, then continues.
        // This tests the complete pause -> fix -> continue flow.

        // [GIVEN] Settings with Stop On First Error enabled
        BC14CompanyMigrationSettings.DeleteAll();
        BC14MigrationErrors.DeleteAll();

        BC14CompanyMigrationSettings.GetSingleInstance();
        BC14CompanyMigrationSettings.Validate("Stop On First Error", true);
        BC14CompanyMigrationSettings.Modify();

        // Simulate migration started and Setup phase completed
        BC14CompanyMigrationSettings.SetDataMigrationStarted();
        BC14CompanyMigrationSettings.SetMigrationState("BC14 Migration State"::Master);
        BC14CompanyMigrationSettings.SetMigrationPhaseCompleted("BC14 Migration State"::Setup, '');

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
        BC14CompanyMigrationSettings.PauseMigration('Customer Migrator');

        // [THEN] Migration should be paused
        Clear(BC14CompanyMigrationSettings);
        BC14CompanyMigrationSettings.GetSingleInstance();
        Assert.AreEqual(true, BC14CompanyMigrationSettings.IsMigrationPaused(), 'Should be paused after error');
        Assert.AreEqual('Customer Migrator', BC14CompanyMigrationSettings."Failed Migrator Name", 'Failed migrator should be Customer Migrator');
        Assert.AreEqual("BC14 Migration State"::Setup, BC14CompanyMigrationSettings.GetLastCompletedPhase(), 'Last completed phase should be Setup');

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
        Clear(BC14CompanyMigrationSettings);
        Assert.AreEqual(true, BC14CompanyMigrationSettings.IsMigrationPaused(), 'Should still be paused until ContinueMigration is called');
        Assert.AreEqual("BC14 Migration State"::Setup, BC14CompanyMigrationSettings.GetLastCompletedPhase(), 'Should resume from after Setup phase');
    end;

    [Test]
    procedure TestMigrationStateTransitions()
    var
        BC14CompanyMigrationSettings: Record "BC14CompanyMigrationSettings";
    begin
        // [SCENARIO] Migration state can transition through all phases correctly.

        // [GIVEN] Settings are created for the current company
        BC14CompanyMigrationSettings.DeleteAll();
        BC14CompanyMigrationSettings.GetSingleInstance();

        // [THEN] Initial state should be NotStarted
        Assert.AreEqual("BC14 Migration State"::NotStarted, BC14CompanyMigrationSettings.GetMigrationState(), 'Initial state should be NotStarted');

        // [WHEN] Migration progresses through phases
        BC14CompanyMigrationSettings.SetMigrationState("BC14 Migration State"::Setup);
        Assert.AreEqual("BC14 Migration State"::Setup, BC14CompanyMigrationSettings.GetMigrationState(), 'State should be Setup');

        BC14CompanyMigrationSettings.SetMigrationState("BC14 Migration State"::Master);
        Assert.AreEqual("BC14 Migration State"::Master, BC14CompanyMigrationSettings.GetMigrationState(), 'State should be Master');

        BC14CompanyMigrationSettings.SetMigrationState("BC14 Migration State"::Transaction);
        Assert.AreEqual("BC14 Migration State"::Transaction, BC14CompanyMigrationSettings.GetMigrationState(), 'State should be Transaction');

        BC14CompanyMigrationSettings.SetMigrationState("BC14 Migration State"::Historical);
        Assert.AreEqual("BC14 Migration State"::Historical, BC14CompanyMigrationSettings.GetMigrationState(), 'State should be Historical');

        BC14CompanyMigrationSettings.SetMigrationState("BC14 Migration State"::Posting);
        Assert.AreEqual("BC14 Migration State"::Posting, BC14CompanyMigrationSettings.GetMigrationState(), 'State should be Posting');

        BC14CompanyMigrationSettings.SetMigrationState("BC14 Migration State"::Completed);
        Assert.AreEqual("BC14 Migration State"::Completed, BC14CompanyMigrationSettings.GetMigrationState(), 'State should be Completed');
    end;

    [Test]
    procedure TestCannotContinueWhenNotPaused()
    var
        BC14CompanyMigrationSettings: Record "BC14CompanyMigrationSettings";
    begin
        // [SCENARIO] IsMigrationPaused returns false when migration is not paused.

        // [GIVEN] Settings are created with migration in progress (not paused)
        BC14CompanyMigrationSettings.DeleteAll();
        BC14CompanyMigrationSettings.GetSingleInstance();
        BC14CompanyMigrationSettings.SetMigrationState("BC14 Migration State"::Master);

        // [THEN] IsMigrationPaused should return false
        Assert.AreEqual(false, BC14CompanyMigrationSettings.IsMigrationPaused(), 'Should not be paused when state is Master');

        // [WHEN] State is NotStarted
        BC14CompanyMigrationSettings.SetMigrationState("BC14 Migration State"::NotStarted);

        // [THEN] IsMigrationPaused should still return false
        Assert.AreEqual(false, BC14CompanyMigrationSettings.IsMigrationPaused(), 'Should not be paused when state is NotStarted');

        // [WHEN] State is Completed
        BC14CompanyMigrationSettings.SetMigrationState("BC14 Migration State"::Completed);

        // [THEN] IsMigrationPaused should still return false
        Assert.AreEqual(false, BC14CompanyMigrationSettings.IsMigrationPaused(), 'Should not be paused when state is Completed');
    end;
}
