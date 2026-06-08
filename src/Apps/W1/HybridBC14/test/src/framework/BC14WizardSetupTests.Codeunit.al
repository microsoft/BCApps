// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration;
using Microsoft.DataMigration.BC14Reimplementation;
using Microsoft.Sales.Customer;
using System.Integration;
using System.Security.AccessControl;
using System.TestLibraries.Environment;

codeunit 148908 "BC14 Wizard & Setup Tests"
{
    // [FEATURE] [BC14 Cloud Migration Wizard] [BC14 Cloud Migration Settings] [BC14 Wizard] [BC14 Cloud Migration Management Page Extension] [BC14 Cloud Migration Setup]

    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        BC14TestHelperFunctions: Codeunit "BC14 Helper Function Tests";
        MappingMissingErr: Label 'Mapping for %1 / %2 should exist', Comment = '%1 = company name, %2 = destination table';

    // ============================================================
    // BC14 Wizard Tests (from BC14WizardTests.codeunit.al)
    // ============================================================

    [Test]
    procedure TestGetMigrationProviderId()
    var
        BC14Wizard: Codeunit "BC14 Wizard";
    begin
        // [SCENARIO] GetMigrationProviderId returns the expected provider ID.

        // [THEN] The provider ID is correct
        Assert.AreEqual('46850-BusinessCentral14Re-Implementation', BC14Wizard.GetMigrationProviderId(), 'Migration Provider ID is incorrect');
    end;

    [Test]
    procedure TestBC14MigrationEnabledWhenSetup()
    var
        BC14Wizard: Codeunit "BC14 Wizard";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        PermissionManager: Codeunit "Permission Manager";
    begin
        // [SCENARIO] GetBC14MigrationEnabled returns true when BC14 is set up as the product.

        // [GIVEN] BC14 is configured as the product
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        PermissionManager.SetTestabilityIntelligentCloud(true);
        BC14TestHelperFunctions.CreateStandardSetupRecords();

        // [THEN] GetBC14MigrationEnabled should return true
        Assert.IsTrue(BC14Wizard.GetBC14MigrationEnabled(), 'BC14 Migration should be enabled');
    end;

    [Test]
    procedure TestBC14MigrationNotEnabledForOtherProducts()
    var
        IntelligentCloudSetup: Record "Intelligent Cloud Setup";
        BC14Wizard: Codeunit "BC14 Wizard";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        PermissionManager: Codeunit "Permission Manager";
    begin
        // [SCENARIO] GetBC14MigrationEnabled returns false when a different product is set up.

        // [GIVEN] A different product is configured
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        PermissionManager.SetTestabilityIntelligentCloud(true);
        BC14TestHelperFunctions.CreateStandardSetupRecords();

        IntelligentCloudSetup.Get();
        IntelligentCloudSetup."Product ID" := 'SomeOtherProduct';
        IntelligentCloudSetup.Modify();

        // [THEN] GetBC14MigrationEnabled should return false
        Assert.IsFalse(BC14Wizard.GetBC14MigrationEnabled(), 'BC14 Migration should not be enabled for other products');
    end;

    [Test]
    procedure TestBC14MigrationNotEnabledWithNoSetup()
    var
        IntelligentCloudSetup: Record "Intelligent Cloud Setup";
        BC14Wizard: Codeunit "BC14 Wizard";
    begin
        // [SCENARIO] GetBC14MigrationEnabled returns false when no setup exists.

        // [GIVEN] No Intelligent Cloud Setup record exists
        if IntelligentCloudSetup.Get() then
            IntelligentCloudSetup.Delete();

        // [THEN] GetBC14MigrationEnabled should return false
        Assert.IsFalse(BC14Wizard.GetBC14MigrationEnabled(), 'BC14 Migration should not be enabled without setup');
    end;

    [Test]
    procedure TestProcessesAreNotRunningByDefault()
    var
        BC14CompanyMigrationInfo: Record "BC14CompanyMigrationInfo";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        PermissionManager: Codeunit "Permission Manager";
    begin
        // [SCENARIO] Processes are not running by default.

        // [GIVEN] BC14 is set up, and company settings are reset
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        PermissionManager.SetTestabilityIntelligentCloud(true);
        BC14TestHelperFunctions.CreateStandardSetupRecords();
        BC14CompanyMigrationInfo.DeleteAll();

        // [WHEN] A new company settings record is created
        BC14CompanyMigrationInfo.GetSingleInstance();

        // [THEN] Data Migration Started should be false
        Assert.AreEqual(false, BC14CompanyMigrationInfo."Data Migration Started", 'Data Migration Started should default to false');
    end;

    [Test]
    procedure TestCleanupMigrationData()
    var
        BC14CompanyMigrationInfo: Record "BC14CompanyMigrationInfo";
        BC14GlobalSettings: Record "BC14 Global Migration Settings";
        DataMigrationError: Record "Data Migration Error";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        PermissionManager: Codeunit "Permission Manager";
    begin
        // [SCENARIO] CleanupMigrationData clears all BC14 migration-related data.

        // [GIVEN] BC14 migration is set up with data
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        PermissionManager.SetTestabilityIntelligentCloud(true);
        BC14TestHelperFunctions.CreateStandardSetupRecords();
        BC14TestHelperFunctions.CreateConfigurationSettings();

        Assert.IsFalse(BC14CompanyMigrationInfo.IsEmpty(), 'BC14CompanyMigrationInfo should have data before cleanup');

        // [WHEN] CleanupMigrationData is called
        BC14TestHelperFunctions.CleanupMigrationData();

        // [THEN] All BC14 migration data is cleared
        Assert.IsTrue(BC14CompanyMigrationInfo.IsEmpty(), 'BC14CompanyMigrationInfo should be empty after cleanup');
        Assert.IsTrue(DataMigrationError.IsEmpty(), 'Data Migration Error should be empty after cleanup');
        Assert.IsFalse(BC14GlobalSettings.Get(), 'BC14 Upgrade Settings should not exist after cleanup');
    end;

    // ============================================================
    // BC14 Settings Tests (from BC14SettingsTests.codeunit.al)
    // ============================================================

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestInitialSettingsDefaults()
    var
        BC14CompanyMigrationInfo: Record "BC14CompanyMigrationInfo";
    begin
        // [SCENARIO] Settings are initialized with correct default values for a new BC14 migration.

        // [GIVEN] Some records are created in the settings table
        BC14TestHelperFunctions.CreateSettingsTableEntries();

        // [THEN] The settings are initialized with the correct default values
        Clear(BC14CompanyMigrationInfo);
        BC14CompanyMigrationInfo.Get('Company 1');

        Assert.AreEqual('Company 1', BC14CompanyMigrationInfo.Name, 'Incorrect company settings found');
        Assert.AreEqual(true, BC14CompanyMigrationInfo."Migrate GL Module", 'Migrate GL Module - Incorrect default value');
        Assert.AreEqual(true, BC14CompanyMigrationInfo."Migrate Receivables Module", 'Migrate Receivables Module - Incorrect default value');
        Assert.AreEqual(true, BC14CompanyMigrationInfo."Migrate Payables Module", 'Migrate Payables Module - Incorrect default value');
        Assert.AreEqual(true, BC14CompanyMigrationInfo."Migrate Inventory Module", 'Migrate Inventory Module - Incorrect default value');
        Assert.AreEqual(false, BC14CompanyMigrationInfo."Data Migration Started", 'Data Migration Started - Incorrect default value');
        Assert.AreEqual(false, BC14CompanyMigrationInfo."Skip Posting Journal Batches", 'Skip Posting Journal Batches - Incorrect default value');
    end;

    [Test]
    procedure TestAllModulesCanBeDisabled()
    var
        BC14CompanyMigrationInfo: Record "BC14CompanyMigrationInfo";
    begin
        // [SCENARIO] All modules can be disabled simultaneously.

        // [GIVEN] Settings are created with all modules enabled
        BC14TestHelperFunctions.CreateSettingsTableEntries();

        // [WHEN] All module settings are disabled
        Clear(BC14CompanyMigrationInfo);
        BC14CompanyMigrationInfo.Get('Company 2');
        BC14CompanyMigrationInfo.Validate("Migrate GL Module", false);
        BC14CompanyMigrationInfo.Validate("Migrate Receivables Module", false);
        BC14CompanyMigrationInfo.Validate("Migrate Payables Module", false);
        BC14CompanyMigrationInfo.Validate("Migrate Inventory Module", false);
        BC14CompanyMigrationInfo.Modify();

        // [THEN] All modules are disabled
        Assert.AreEqual(false, BC14CompanyMigrationInfo."Migrate GL Module", 'Migrate GL Module - Should be disabled');
        Assert.AreEqual(false, BC14CompanyMigrationInfo."Migrate Receivables Module", 'Migrate Receivables Module - Should be disabled');
        Assert.AreEqual(false, BC14CompanyMigrationInfo."Migrate Payables Module", 'Migrate Payables Module - Should be disabled');
        Assert.AreEqual(false, BC14CompanyMigrationInfo."Migrate Inventory Module", 'Migrate Inventory Module - Should be disabled');
    end;

    [Test]
    procedure TestGetSingleInstanceCreatesRecordIfNotExists()
    var
        BC14CompanyMigrationInfo: Record "BC14CompanyMigrationInfo";
    begin
        // [SCENARIO] GetSingleInstance creates a record if it does not exist.

        // [GIVEN] No records exist for the current company
        BC14CompanyMigrationInfo.DeleteAll();

        // [WHEN] GetSingleInstance is called
        BC14CompanyMigrationInfo.GetSingleInstance();

        // [THEN] A record is created for the current company with default values
        Assert.AreEqual(CompanyName(), BC14CompanyMigrationInfo.Name, 'Record should be created for the current company');
        Assert.AreEqual(true, BC14CompanyMigrationInfo."Migrate GL Module", 'Migrate GL Module - Should have default true');
        Assert.AreEqual(true, BC14CompanyMigrationInfo."Migrate Receivables Module", 'Migrate Receivables Module - Should have default true');
        Assert.AreEqual(true, BC14CompanyMigrationInfo."Migrate Payables Module", 'Migrate Payables Module - Should have default true');
        Assert.AreEqual(true, BC14CompanyMigrationInfo."Migrate Inventory Module", 'Migrate Inventory Module - Should have default true');
    end;

    [Test]
    procedure TestModuleEnabledHelperFunctions()
    var
        BC14CompanyMigrationInfo: Record "BC14CompanyMigrationInfo";
    begin
        // [SCENARIO] Helper functions correctly return module enabled status.

        // [GIVEN] Settings are created with default values
        BC14CompanyMigrationInfo.DeleteAll();

        // [WHEN] Helper functions are called
        // [THEN] All modules should be enabled by default
        Assert.AreEqual(true, BC14CompanyMigrationInfo.GetGLModuleEnabled(), 'GetGLModuleEnabled - Should return true');
        Assert.AreEqual(true, BC14CompanyMigrationInfo.GetReceivablesModuleEnabled(), 'GetReceivablesModuleEnabled - Should return true');
        Assert.AreEqual(true, BC14CompanyMigrationInfo.GetPayablesModuleEnabled(), 'GetPayablesModuleEnabled - Should return true');
        Assert.AreEqual(true, BC14CompanyMigrationInfo.GetInventoryModuleEnabled(), 'GetInventoryModuleEnabled - Should return true');
    end;

    [Test]
    procedure TestModuleEnabledHelperFunctionsWhenDisabled()
    var
        BC14CompanyMigrationInfo: Record "BC14CompanyMigrationInfo";
    begin
        // [SCENARIO] Helper functions correctly return false when modules are disabled.

        // [GIVEN] Settings are created and all modules are disabled
        BC14CompanyMigrationInfo.DeleteAll();
        BC14CompanyMigrationInfo.GetSingleInstance();
        BC14CompanyMigrationInfo.Validate("Migrate GL Module", false);
        BC14CompanyMigrationInfo.Validate("Migrate Receivables Module", false);
        BC14CompanyMigrationInfo.Validate("Migrate Payables Module", false);
        BC14CompanyMigrationInfo.Validate("Migrate Inventory Module", false);
        BC14CompanyMigrationInfo.Modify();

        // [WHEN] Helper functions are called after disabling
        // Need to re-read from DB through helper functions (which call GetSingleInstance)
        Clear(BC14CompanyMigrationInfo);

        // [THEN] All modules should be disabled
        Assert.AreEqual(false, BC14CompanyMigrationInfo.GetGLModuleEnabled(), 'GetGLModuleEnabled - Should return false');
        Assert.AreEqual(false, BC14CompanyMigrationInfo.GetReceivablesModuleEnabled(), 'GetReceivablesModuleEnabled - Should return false');
        Assert.AreEqual(false, BC14CompanyMigrationInfo.GetPayablesModuleEnabled(), 'GetPayablesModuleEnabled - Should return false');
        Assert.AreEqual(false, BC14CompanyMigrationInfo.GetInventoryModuleEnabled(), 'GetInventoryModuleEnabled - Should return false');
    end;

    [Test]
    procedure TestDataMigrationStartedFlag()
    var
        BC14CompanyMigrationInfo: Record "BC14CompanyMigrationInfo";
    begin
        // [SCENARIO] Data Migration Started flag works correctly.

        // [GIVEN] Settings are created for the current company
        BC14CompanyMigrationInfo.DeleteAll();
        BC14CompanyMigrationInfo.GetSingleInstance();

        // [THEN] Data Migration Started should be false initially
        Assert.AreEqual(false, BC14CompanyMigrationInfo.IsDataMigrationStarted(), 'IsDataMigrationStarted - Should be false initially');

        // [WHEN] SetDataMigrationStarted is called
        BC14CompanyMigrationInfo.SetDataMigrationStarted();

        // [THEN] Data Migration Started should be true, with a timestamp
        Clear(BC14CompanyMigrationInfo);
        BC14CompanyMigrationInfo.GetSingleInstance();
        Assert.AreEqual(true, BC14CompanyMigrationInfo.IsDataMigrationStarted(), 'IsDataMigrationStarted - Should be true after SetDataMigrationStarted');
        Assert.AreNotEqual(0DT, BC14CompanyMigrationInfo."Data Migration Started At", 'Data Migration Started At - Should have a timestamp');
    end;

    [Test]
    procedure TestSetDataMigrationStartedIsIdempotent()
    var
        BC14CompanyMigrationInfo: Record "BC14CompanyMigrationInfo";
        FirstTimestamp: DateTime;
    begin
        // [SCENARIO] Calling SetDataMigrationStarted multiple times does not update the timestamp.

        // [GIVEN] Settings are created and migration is started
        BC14CompanyMigrationInfo.DeleteAll();
        BC14CompanyMigrationInfo.GetSingleInstance();
        BC14CompanyMigrationInfo.SetDataMigrationStarted();

        // Record the first timestamp
        Clear(BC14CompanyMigrationInfo);
        BC14CompanyMigrationInfo.GetSingleInstance();
        FirstTimestamp := BC14CompanyMigrationInfo."Data Migration Started At";

        // [WHEN] SetDataMigrationStarted is called again
        BC14CompanyMigrationInfo.SetDataMigrationStarted();

        // [THEN] The timestamp should not change (idempotent)
        Clear(BC14CompanyMigrationInfo);
        BC14CompanyMigrationInfo.GetSingleInstance();
        Assert.AreEqual(FirstTimestamp, BC14CompanyMigrationInfo."Data Migration Started At", 'Data Migration Started At - Should not change on second call');
    end;

    [Test]
    procedure TestSkipPostingJournalBatchesSetting()
    var
        BC14CompanyMigrationInfo: Record "BC14CompanyMigrationInfo";
    begin
        // [SCENARIO] Skip Posting Journal Batches setting works correctly.

        // [GIVEN] Settings are created for the current company
        BC14CompanyMigrationInfo.DeleteAll();
        BC14CompanyMigrationInfo.GetSingleInstance();

        // [THEN] Skip Posting should be false initially
        Assert.AreEqual(false, BC14CompanyMigrationInfo.GetSkipPostingJournalBatches(), 'GetSkipPostingJournalBatches - Should be false initially');

        // [WHEN] Skip Posting is enabled
        BC14CompanyMigrationInfo.Validate("Skip Posting Journal Batches", true);
        BC14CompanyMigrationInfo.Modify();

        // [THEN] Skip Posting should be true
        Clear(BC14CompanyMigrationInfo);
        Assert.AreEqual(true, BC14CompanyMigrationInfo.GetSkipPostingJournalBatches(), 'GetSkipPostingJournalBatches - Should be true after enabling');
    end;

    [Test]
    procedure TestThirdCompanyHasDefaultSettings()
    var
        BC14CompanyMigrationInfo: Record "BC14CompanyMigrationInfo";
    begin
        // [SCENARIO] A third company that was not explicitly configured has default settings.

        // [GIVEN] Settings entries are created
        BC14TestHelperFunctions.CreateSettingsTableEntries();

        // [WHEN] Reading Company 3 settings (not explicitly configured beyond insert)
        BC14CompanyMigrationInfo.Get('Company 3');

        // [THEN] It should have default values (InitValue = true for modules, false for flags)
        Assert.AreEqual('Company 3', BC14CompanyMigrationInfo.Name, 'Incorrect company settings found');
        Assert.AreEqual(true, BC14CompanyMigrationInfo."Migrate GL Module", 'Migrate GL Module - Should have default true');
        Assert.AreEqual(true, BC14CompanyMigrationInfo."Migrate Receivables Module", 'Migrate Receivables Module - Should have default true');
        Assert.AreEqual(true, BC14CompanyMigrationInfo."Migrate Payables Module", 'Migrate Payables Module - Should have default true');
        Assert.AreEqual(true, BC14CompanyMigrationInfo."Migrate Inventory Module", 'Migrate Inventory Module - Should have default true');
        Assert.AreEqual(false, BC14CompanyMigrationInfo."Data Migration Started", 'Data Migration Started - Should have default false');
        Assert.AreEqual(false, BC14CompanyMigrationInfo."Skip Posting Journal Batches", 'Skip Posting Journal Batches - Should have default false');
    end;

    [Test]
    procedure TestStopOnFirstErrorDefaultValue()
    var
        BC14CompanyMigrationInfo: Record "BC14CompanyMigrationInfo";
    begin
        // [SCENARIO] Stop On First Error setting has correct default value.

        // [GIVEN] Settings are created for the current company
        BC14CompanyMigrationInfo.DeleteAll();
        BC14CompanyMigrationInfo.GetSingleInstance();

        // [THEN] Stop On First Error should be false initially (default behavior is continue on error)
        Assert.AreEqual(false, BC14CompanyMigrationInfo."Stop On First Error", 'Stop On First Error - Should be false by default');
        Assert.AreEqual(false, BC14CompanyMigrationInfo.GetStopOnFirstTransformationError(), 'GetStopOnFirstTransformationError - Should return false by default');
    end;

    [Test]
    procedure TestStopOnFirstErrorIndependentOfOtherSettings()
    var
        BC14CompanyMigrationInfo: Record "BC14CompanyMigrationInfo";
    begin
        // [SCENARIO] Stop On First Error setting is independent of module settings.

        // [GIVEN] Settings are created with all modules enabled and Stop On First Error enabled
        BC14CompanyMigrationInfo.DeleteAll();
        BC14CompanyMigrationInfo.GetSingleInstance();
        BC14CompanyMigrationInfo.Validate("Stop On First Error", true);
        BC14CompanyMigrationInfo.Modify();

        // [WHEN] All module settings are disabled
        BC14CompanyMigrationInfo.Validate("Migrate GL Module", false);
        BC14CompanyMigrationInfo.Validate("Migrate Receivables Module", false);
        BC14CompanyMigrationInfo.Validate("Migrate Payables Module", false);
        BC14CompanyMigrationInfo.Validate("Migrate Inventory Module", false);
        BC14CompanyMigrationInfo.Modify();

        // [THEN] Stop On First Error should remain true (independent of module settings)
        Clear(BC14CompanyMigrationInfo);
        Assert.AreEqual(true, BC14CompanyMigrationInfo.GetStopOnFirstTransformationError(), 'GetStopOnFirstTransformationError - Should remain true after disabling modules');
        Assert.AreEqual(false, BC14CompanyMigrationInfo.GetGLModuleEnabled(), 'GetGLModuleEnabled - Should be false');
        Assert.AreEqual(false, BC14CompanyMigrationInfo.GetReceivablesModuleEnabled(), 'GetReceivablesModuleEnabled - Should be false');
    end;

    [Test]
    procedure TestStopOnFirstErrorWithSkipPostingCombination()
    var
        BC14CompanyMigrationInfo: Record "BC14CompanyMigrationInfo";
    begin
        // [SCENARIO] Stop On First Error and Skip Posting Journal Batches can be set independently.

        // [GIVEN] Settings are created for the current company
        BC14CompanyMigrationInfo.DeleteAll();
        BC14CompanyMigrationInfo.GetSingleInstance();

        // [WHEN] Both settings are enabled
        BC14CompanyMigrationInfo.Validate("Stop On First Error", true);
        BC14CompanyMigrationInfo.Validate("Skip Posting Journal Batches", true);
        BC14CompanyMigrationInfo.Modify();

        // [THEN] Both settings should be true independently
        Clear(BC14CompanyMigrationInfo);
        Assert.AreEqual(true, BC14CompanyMigrationInfo.GetStopOnFirstTransformationError(), 'GetStopOnFirstTransformationError - Should be true');
        Assert.AreEqual(true, BC14CompanyMigrationInfo.GetSkipPostingJournalBatches(), 'GetSkipPostingJournalBatches - Should be true');
    end;

    [Test]
    procedure TestMigrationStateDefaultValue()
    var
        BC14CompanyMigrationInfo: Record "BC14CompanyMigrationInfo";
    begin
        // [SCENARIO] Migration State has correct default value.

        // [GIVEN] Settings are created for the current company
        BC14CompanyMigrationInfo.DeleteAll();
        BC14CompanyMigrationInfo.GetSingleInstance();

        // [THEN] Migration State should be NotStarted by default
        Assert.AreEqual("BC14 Migration Step"::NotStarted, BC14CompanyMigrationInfo."Current Migration Step", 'Migration State - Should be NotStarted by default');
        Assert.AreEqual("BC14 Migration Step"::NotStarted, BC14CompanyMigrationInfo.GetMigrationState(), 'GetMigrationState - Should return NotStarted');
    end;

    [Test]
    procedure TestSetMigrationPhaseCompleted()
    var
        BC14CompanyMigrationInfo: Record "BC14CompanyMigrationInfo";
    begin
        // [SCENARIO] SetMigrationPhaseCompleted correctly tracks completed phases.

        // [GIVEN] Settings are created for the current company
        BC14CompanyMigrationInfo.DeleteAll();
        BC14CompanyMigrationInfo.GetSingleInstance();

        // [WHEN] Setup phase is marked as completed
        BC14CompanyMigrationInfo.SetMigrationPhaseCompleted("BC14 Migration Step"::Setup, 'Dimension Migrator');

        // [THEN] Last completed phase should be Setup
        Clear(BC14CompanyMigrationInfo);
        BC14CompanyMigrationInfo.GetSingleInstance();
        Assert.AreEqual("BC14 Migration Step"::Setup, BC14CompanyMigrationInfo."Last Completed Phase", 'Last Completed Phase - Should be Setup');
        Assert.AreEqual("BC14 Migration Step"::Setup, BC14CompanyMigrationInfo.GetLastCompletedPhase(), 'GetLastCompletedPhase - Should return Setup');
        Assert.AreEqual('Dimension Migrator', BC14CompanyMigrationInfo."Last Completed Migrator", 'Last Completed Migrator - Should match');
    end;

    [Test]
    procedure TestMigrationStateTransitions()
    var
        BC14CompanyMigrationInfo: Record "BC14CompanyMigrationInfo";
    begin
        // [SCENARIO] Migration state can transition through all phases correctly.

        // [GIVEN] Settings are created for the current company
        BC14CompanyMigrationInfo.DeleteAll();
        BC14CompanyMigrationInfo.GetSingleInstance();

        // [THEN] Initial state should be NotStarted
        Assert.AreEqual("BC14 Migration Step"::NotStarted, BC14CompanyMigrationInfo.GetMigrationState(), 'Initial state should be NotStarted');

        // [WHEN] Migration progresses through phases
        BC14CompanyMigrationInfo.SetMigrationState("BC14 Migration Step"::Setup);
        Assert.AreEqual("BC14 Migration Step"::Setup, BC14CompanyMigrationInfo.GetMigrationState(), 'State should be Setup');

        BC14CompanyMigrationInfo.SetMigrationState("BC14 Migration Step"::Master);
        Assert.AreEqual("BC14 Migration Step"::Master, BC14CompanyMigrationInfo.GetMigrationState(), 'State should be Master');

        BC14CompanyMigrationInfo.SetMigrationState("BC14 Migration Step"::Transaction);
        Assert.AreEqual("BC14 Migration Step"::Transaction, BC14CompanyMigrationInfo.GetMigrationState(), 'State should be Transaction');

        BC14CompanyMigrationInfo.SetMigrationState("BC14 Migration Step"::Historical);
        Assert.AreEqual("BC14 Migration Step"::Historical, BC14CompanyMigrationInfo.GetMigrationState(), 'State should be Historical');

        BC14CompanyMigrationInfo.SetMigrationState("BC14 Migration Step"::Posting);
        Assert.AreEqual("BC14 Migration Step"::Posting, BC14CompanyMigrationInfo.GetMigrationState(), 'State should be Posting');

        BC14CompanyMigrationInfo.SetMigrationState("BC14 Migration Step"::Completed);
        Assert.AreEqual("BC14 Migration Step"::Completed, BC14CompanyMigrationInfo.GetMigrationState(), 'State should be Completed');
    end;

    // ============================================================
    // BC14 Migration Setup Tests (from BC14MigrationSetupTests.Codeunit.al)
    // ------------------------------------------------------------
    // InsertPerCompanyMapping
    // ============================================================

    [Test]
    procedure TestInsertPerCompanyMapping_CreatesMapping()
    var
        ReplicationTableMapping: Record "Replication Table Mapping";
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        // [SCENARIO] InsertPerCompanyMapping creates a Replication Table Mapping record
        // bound to the given company and source/destination tables.
        Initialize();

        // [WHEN] A per-company mapping is inserted
        BC14MigrationSetup.InsertPerCompanyMapping('BC14ST-CO1', Database::Customer, Database::"BC14 Customer");

        // [THEN] A Replication Table Mapping record is created for the company and destination table
        ReplicationTableMapping.SetRange("Company Name", 'BC14ST-CO1');
        ReplicationTableMapping.SetRange("Table Name", 'BC14 Customer');
        Assert.IsFalse(ReplicationTableMapping.IsEmpty(), 'Mapping should be created for the company and destination table');
    end;

    [Test]
    procedure TestInsertPerCompanyMapping_Idempotent()
    var
        ReplicationTableMapping: Record "Replication Table Mapping";
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
        CountBefore: Integer;
        CountAfter: Integer;
    begin
        // [SCENARIO] Inserting the same per-company mapping twice does not create duplicates.
        Initialize();

        BC14MigrationSetup.InsertPerCompanyMapping('BC14ST-CO1', Database::Customer, Database::"BC14 Customer");
        ReplicationTableMapping.SetRange("Company Name", 'BC14ST-CO1');
        ReplicationTableMapping.SetRange("Table Name", 'BC14 Customer');
        CountBefore := ReplicationTableMapping.Count();

        // [WHEN] Inserted again
        BC14MigrationSetup.InsertPerCompanyMapping('BC14ST-CO1', Database::Customer, Database::"BC14 Customer");

        // [THEN] No duplicate is created
        CountAfter := ReplicationTableMapping.Count();
        Assert.AreEqual(CountBefore, CountAfter, 'Repeated InsertPerCompanyMapping should not create duplicates');
    end;

    // ============================================================
    // SetupReplicationTableMappings
    // ============================================================

    [Test]
    procedure TestSetupReplicationTableMappings_CreatesMappingsForReplicatedCompanies()
    var
        ReplicationTableMapping: Record "Replication Table Mapping";
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        // [SCENARIO] SetupReplicationTableMappings creates mappings for every replicated company
        // covering the core tables (Customer, Vendor, Item, G/L Account).
        Initialize();

        // [GIVEN] One replicated Hybrid Company
        InsertHybridCompany('BC14ST-CO1', true);

        // [WHEN] SetupReplicationTableMappings is run
        BC14MigrationSetup.SetupReplicationTableMappings();

        // [THEN] Master-data mappings for the replicated company exist
        AssertMappingExists('BC14ST-CO1', 'BC14 Customer');
        AssertMappingExists('BC14ST-CO1', 'BC14 Vendor');
        AssertMappingExists('BC14ST-CO1', 'BC14 Item');
        AssertMappingExists('BC14ST-CO1', 'BC14 G/L Account');

        // [THEN] At least one setup-phase mapping exists too (Dimension)
        ReplicationTableMapping.SetRange("Company Name", 'BC14ST-CO1');
        ReplicationTableMapping.SetRange("Table Name", 'BC14 Dimension');
        Assert.IsFalse(ReplicationTableMapping.IsEmpty(), 'Setup-phase Dimension mapping should also exist');
    end;

    [Test]
    procedure TestSetupReplicationTableMappings_SkipsNonReplicatedCompanies()
    var
        ReplicationTableMapping: Record "Replication Table Mapping";
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        // [SCENARIO] Companies with Replicate = false are NOT included in the table mapping.
        Initialize();

        // [GIVEN] One replicated and one non-replicated Hybrid Company
        InsertHybridCompany('BC14ST-CO1', true);
        InsertHybridCompany('BC14ST-NO', false);

        // [WHEN] SetupReplicationTableMappings is run
        BC14MigrationSetup.SetupReplicationTableMappings();

        // [THEN] Only the replicated company has mappings
        ReplicationTableMapping.SetRange("Company Name", 'BC14ST-NO');
        Assert.IsTrue(ReplicationTableMapping.IsEmpty(),
            'Non-replicated company should not have replication mappings');
    end;

    [Test]
    procedure TestSetupReplicationTableMappings_RunTwice_NoDuplicates()
    var
        ReplicationTableMapping: Record "Replication Table Mapping";
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
        CountBefore: Integer;
        CountAfter: Integer;
    begin
        // [SCENARIO] Running setup twice is safe: the platform's CreateReplicationMapping
        // is idempotent and the count of mappings does not change.
        Initialize();

        InsertHybridCompany('BC14ST-CO1', true);

        BC14MigrationSetup.SetupReplicationTableMappings();
        ReplicationTableMapping.SetRange("Company Name", 'BC14ST-CO1');
        CountBefore := ReplicationTableMapping.Count();

        // [WHEN] Setup is run a second time
        BC14MigrationSetup.SetupReplicationTableMappings();

        // [THEN] Mapping count is unchanged
        CountAfter := ReplicationTableMapping.Count();
        Assert.AreEqual(CountBefore, CountAfter, 'Re-running setup should not create duplicate mappings');
    end;

    // ============================================================
    // Local helpers
    // ============================================================

    local procedure Initialize()
    var
        HybridCompany: Record "Hybrid Company";
        ReplicationTableMapping: Record "Replication Table Mapping";
    begin
        HybridCompany.SetFilter(Name, 'BC14ST-*');
        HybridCompany.DeleteAll();
        ReplicationTableMapping.SetFilter("Company Name", 'BC14ST-*');
        ReplicationTableMapping.DeleteAll();
    end;

    local procedure InsertHybridCompany(CompanyNameValue: Text[50]; ReplicateValue: Boolean)
    var
        HybridCompany: Record "Hybrid Company";
    begin
        HybridCompany.Init();
        HybridCompany.Name := CompanyNameValue;
        HybridCompany.Replicate := ReplicateValue;
        HybridCompany.Insert();
    end;

    local procedure AssertMappingExists(CompanyNameValue: Text[30]; DestinationTableName: Text[128])
    var
        ReplicationTableMapping: Record "Replication Table Mapping";
    begin
        ReplicationTableMapping.SetRange("Company Name", CompanyNameValue);
        ReplicationTableMapping.SetRange("Table Name", DestinationTableName);
        Assert.IsFalse(ReplicationTableMapping.IsEmpty(),
            StrSubstNo(MappingMissingErr, CompanyNameValue, DestinationTableName));
    end;
}
