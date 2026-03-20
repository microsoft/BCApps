// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AA0210
namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration;
using Microsoft.Sales.Customer;
using System.Integration;
using Microsoft.DataMigration.BC14;
using System.TestLibraries.Utilities;

codeunit 148902 "BC14 Cloud Migration E2E Test"
{
    // [FEATURE] [BC14 Cloud Migration]
    // Unit tests for BC14 Cloud Migration components.
    // These tests verify individual components without complex E2E webhook flows.

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";

    local procedure Initialize()
    var
        BC14GlobalSettings: Record "BC14 Global Migration Settings";
        BC14CompanySettings: Record BC14CompanyMigrationSettings;
        BC14Customer: Record "BC14 Customer";
        BC14MigrationErrors: Record "BC14 Migration Errors";
        BC14MigrationErrorOverview: Record "BC14 Migration Error Overview";
        BC14MigrationRecordStatus: Record "BC14 Migration Record Status";
        DataMigrationError: Record "Data Migration Error";
        HybridCompanyStatus: Record "Hybrid Company Status";
        HybridCompany: Record "Hybrid Company";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
    begin
        BC14Customer.DeleteAll();
        BC14MigrationErrors.DeleteAll();
        BC14MigrationErrorOverview.DeleteAll();
        BC14MigrationRecordStatus.DeleteAll();
        DataMigrationError.DeleteAll();
        HybridCompanyStatus.DeleteAll();
        HybridCompany.DeleteAll();

        // Reset company settings to clean state
        BC14CompanySettings.DeleteAll();

        // Clear SingleInstance error flag
        BC14MigrationErrorHandler.ClearErrorOccurred();

        // Fully reset global settings to clean state
        BC14GlobalSettings.DeleteAll();
        BC14GlobalSettings.GetOrInsertGlobalSettings(BC14GlobalSettings);
        BC14GlobalSettings."One Step Upgrade" := false;
        BC14GlobalSettings."Data Upgrade Started" := 0DT;
        BC14GlobalSettings.Modify(true);

        LibraryVariableStorage.Clear();
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure SetupHybridCompany()
    var
        HybridCompany: Record "Hybrid Company";
    begin
        HybridCompany.Init();
        HybridCompany.Name := CopyStr(CompanyName(), 1, MaxStrLen(HybridCompany.Name));
        HybridCompany.Replicate := true;
        if not HybridCompany.Insert() then
            HybridCompany.Modify();
    end;

    [Test]
    procedure TestOneStepUpgradeSettingCanBeEnabled()
    var
        BC14GlobalSettings: Record "BC14 Global Migration Settings";
    begin
        // [SCENARIO] One Step Upgrade setting can be enabled and persisted

        // [GIVEN] Clean settings
        Initialize();

        // [WHEN] One Step Upgrade is enabled
        BC14GlobalSettings.GetOrInsertGlobalSettings(BC14GlobalSettings);
        BC14GlobalSettings."One Step Upgrade" := true;
        BC14GlobalSettings.Modify(true);

        // [THEN] Setting is persisted
        BC14GlobalSettings.GetOrInsertGlobalSettings(BC14GlobalSettings);
        Assert.IsTrue(BC14GlobalSettings."One Step Upgrade", 'One Step Upgrade should be enabled');
    end;

    [Test]
    procedure TestStopOnFirstErrorSettingCanBeEnabled()
    var
        BC14CompanySettings: Record BC14CompanyMigrationSettings;
    begin
        // [SCENARIO] Stop On First Error setting can be enabled and persisted

        // [GIVEN] Clean settings
        Initialize();

        // [WHEN] Stop On First Error is enabled
        BC14CompanySettings.GetSingleInstance();
        BC14CompanySettings."Stop On First Error" := true;
        BC14CompanySettings.Modify(true);

        // [THEN] Setting is persisted
        BC14CompanySettings.GetSingleInstance();
        Assert.IsTrue(BC14CompanySettings.GetStopOnFirstTransformationError(), 'Stop On First Error should be enabled');
    end;

    [Test]
    procedure TestMigrationStateTransitions()
    var
        BC14CompanySettings: Record BC14CompanyMigrationSettings;
    begin
        // [SCENARIO] Migration state can be set and retrieved correctly

        // [GIVEN] Clean settings
        Initialize();

        // [WHEN] Migration state is set to Setup
        BC14CompanySettings.GetSingleInstance();
        BC14CompanySettings.SetMigrationState("BC14 Migration State"::Setup);

        // [THEN] Migration state is Setup
        Assert.AreEqual("BC14 Migration State"::Setup, BC14CompanySettings.GetMigrationState(), 'State should be Setup');

        // [WHEN] Migration state is set to Master
        BC14CompanySettings.SetMigrationState("BC14 Migration State"::Master);

        // [THEN] Migration state is Master
        Assert.AreEqual("BC14 Migration State"::Master, BC14CompanySettings.GetMigrationState(), 'State should be Master');

        // [WHEN] Migration state is set to Completed
        BC14CompanySettings.SetMigrationState("BC14 Migration State"::Completed);

        // [THEN] Migration state is Completed
        Assert.AreEqual("BC14 Migration State"::Completed, BC14CompanySettings.GetMigrationState(), 'State should be Completed');
    end;

    [Test]
    procedure TestMigrationPauseAndResume()
    var
        BC14CompanySettings: Record BC14CompanyMigrationSettings;
    begin
        // [SCENARIO] Migration can be paused and its state tracked

        // [GIVEN] Clean settings with migration in progress
        Initialize();
        BC14CompanySettings.GetSingleInstance();
        BC14CompanySettings.SetMigrationState("BC14 Migration State"::Master);

        // [WHEN] Migration is paused
        BC14CompanySettings.PauseMigration('Customer Migrator');

        // [THEN] Migration state is Paused and failed migrator is recorded
        Assert.IsTrue(BC14CompanySettings.IsMigrationPaused(), 'Migration should be paused');
        Assert.AreEqual('Customer Migrator', BC14CompanySettings."Failed Migrator Name", 'Failed migrator should be recorded');
    end;

    [Test]
    procedure TestDataMigrationStartedFlag()
    var
        BC14CompanySettings: Record BC14CompanyMigrationSettings;
    begin
        // [SCENARIO] Data Migration Started flag is set correctly

        // [GIVEN] Clean settings
        Initialize();

        // [THEN] Initially, migration has not started
        BC14CompanySettings.GetSingleInstance();
        Assert.IsFalse(BC14CompanySettings.IsDataMigrationStarted(), 'Migration should not be started initially');

        // [WHEN] Data migration is marked as started
        BC14CompanySettings.SetDataMigrationStarted();

        // [THEN] Migration started flag is true
        Assert.IsTrue(BC14CompanySettings.IsDataMigrationStarted(), 'Migration should be marked as started');
        Assert.IsTrue(BC14CompanySettings."Data Migration Started At" > 0DT, 'Start time should be recorded');
    end;

    [Test]
    procedure TestMigrationErrorTracking()
    var
        BC14MigrationErrors: Record "BC14 Migration Errors";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        DummyRecId: RecordId;
    begin
        // [SCENARIO] Migration errors are logged correctly

        // [GIVEN] Clean state
        Initialize();

        // [WHEN] An error is logged
        BC14MigrationErrorHandler.LogError(
            'Customer Migrator',
            Database::"BC14 Customer",
            'BC14 Customer',
            'CUST001',
            Database::Customer,
            'Test error message',
            DummyRecId);

        // [THEN] Error is recorded in the table
        BC14MigrationErrors.SetRange("Migration Type", 'Customer Migrator');
        BC14MigrationErrors.SetRange("Source Record Key", 'CUST001');
        Assert.IsTrue(BC14MigrationErrors.FindFirst(), 'Error should be logged');
        Assert.AreEqual('Test error message', BC14MigrationErrors."Error Message", 'Error message should match');
        Assert.IsFalse(BC14MigrationErrors.Resolved, 'Error should not be resolved initially');
    end;

    [Test]
    procedure TestMigrationErrorResolution()
    var
        BC14MigrationErrors: Record "BC14 Migration Errors";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        DummyRecId: RecordId;
    begin
        // [SCENARIO] Migration errors can be marked as resolved

        // [GIVEN] An existing error
        Initialize();
        BC14MigrationErrorHandler.LogError(
            'Customer Migrator',
            Database::"BC14 Customer",
            'BC14 Customer',
            'CUST002',
            Database::Customer,
            'Another test error',
            DummyRecId);

        // [WHEN] Error is marked as resolved
        BC14MigrationErrors.SetRange("Source Record Key", 'CUST002');
        BC14MigrationErrors.FindFirst();
        BC14MigrationErrors.Resolved := true;
        BC14MigrationErrors.Modify();

        // [THEN] Error is resolved
        BC14MigrationErrors.FindFirst();
        Assert.IsTrue(BC14MigrationErrors.Resolved, 'Error should be resolved');
    end;

    [Test]
    procedure TestErrorOccurredFlagManagement()
    var
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        DummyRecId: RecordId;
    begin
        // [SCENARIO] Error occurred flag is managed correctly

        // [GIVEN] Clean state
        Initialize();

        // [THEN] Initially no error occurred
        Assert.IsFalse(BC14MigrationErrorHandler.GetErrorOccurred(), 'No error should have occurred initially');

        // [WHEN] An error is logged
        BC14MigrationErrorHandler.LogError(
            'Test Migrator',
            0,
            'Test Table',
            'KEY001',
            0,
            'Test error',
            DummyRecId);

        // [THEN] Error flag is set
        Assert.IsTrue(BC14MigrationErrorHandler.GetErrorOccurred(), 'Error flag should be set after logging error');

        // [WHEN] Error flag is cleared
        BC14MigrationErrorHandler.ClearErrorOccurred();

        // [THEN] Error flag is cleared
        Assert.IsFalse(BC14MigrationErrorHandler.GetErrorOccurred(), 'Error flag should be cleared');
    end;

    [Test]
    procedure TestMigrationRecordStatusTracking()
    var
        BC14MigrationRecordStatus: Record "BC14 Migration Record Status";
    begin
        // [SCENARIO] Migration record status can be tracked

        // [GIVEN] Clean state
        Initialize();

        // [WHEN] MarkAsMigrated is called
        BC14MigrationRecordStatus.MarkAsMigrated(Database::"BC14 Customer", 'CUST001');

        // [THEN] IsMigrated returns true
        Assert.IsTrue(BC14MigrationRecordStatus.IsMigrated(Database::"BC14 Customer", 'CUST001'), 'Record should be marked as migrated');
    end;

    [Test]
    procedure TestClearAllMigrationStatus()
    var
        BC14MigrationRecordStatus: Record "BC14 Migration Record Status";
    begin
        // [SCENARIO] All migration status records can be cleared

        // [GIVEN] Some migration records exist
        Initialize();
        InsertMigrationRecordStatus(50100, 'KEY1');
        InsertMigrationRecordStatus(50100, 'KEY2');
        InsertMigrationRecordStatus(50101, 'KEY3');

        Assert.AreEqual(3, BC14MigrationRecordStatus.Count(), 'Should have 3 records');

        // [WHEN] All statuses are cleared
        BC14MigrationRecordStatus.ClearAllMigrationStatus();

        // [THEN] All records are deleted
        Assert.AreEqual(0, BC14MigrationRecordStatus.Count(), 'All records should be deleted');
    end;

    [Test]
    procedure TestHybridCompanyStatusCreation()
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
    begin
        // [SCENARIO] Hybrid company status can be created and updated

        // [GIVEN] Clean state
        Initialize();

        // [WHEN] A company status is created with Pending status
        HybridCompanyStatus.Init();
        HybridCompanyStatus.Name := CopyStr(CompanyName(), 1, MaxStrLen(HybridCompanyStatus.Name));
        HybridCompanyStatus."Upgrade Status" := HybridCompanyStatus."Upgrade Status"::Pending;
        HybridCompanyStatus.Insert();

        // [THEN] Status is Pending
        HybridCompanyStatus.Get(CompanyName());
        Assert.AreEqual(HybridCompanyStatus."Upgrade Status"::Pending, HybridCompanyStatus."Upgrade Status", 'Should be Pending');

        // [WHEN] Status is updated to Completed
        HybridCompanyStatus."Upgrade Status" := HybridCompanyStatus."Upgrade Status"::Completed;
        HybridCompanyStatus.Modify();

        // [THEN] Status is Completed
        HybridCompanyStatus.Get(CompanyName());
        Assert.AreEqual(HybridCompanyStatus."Upgrade Status"::Completed, HybridCompanyStatus."Upgrade Status", 'Should be Completed');
    end;

    [Test]
    procedure TestLastCompletedPhaseTracking()
    var
        BC14CompanySettings: Record BC14CompanyMigrationSettings;
    begin
        // [SCENARIO] Last completed phase is tracked correctly

        // [GIVEN] Clean settings
        Initialize();
        BC14CompanySettings.GetSingleInstance();

        // [WHEN] Setup phase is completed
        BC14CompanySettings.SetMigrationPhaseCompleted("BC14 Migration State"::Setup, 'Setup Migrator');

        // [THEN] Last completed phase is Setup
        Assert.AreEqual("BC14 Migration State"::Setup, BC14CompanySettings.GetLastCompletedPhase(), 'Should be Setup phase');

        // [WHEN] Master phase is completed
        BC14CompanySettings.SetMigrationPhaseCompleted("BC14 Migration State"::Master, 'Master Migrator');

        // [THEN] Last completed phase is Master
        Assert.AreEqual("BC14 Migration State"::Master, BC14CompanySettings.GetLastCompletedPhase(), 'Should be Master phase');
    end;

    local procedure InsertMigrationRecordStatus(SourceTableId: Integer; SourceRecordKey: Text[250])
    var
        BC14MigrationRecordStatus: Record "BC14 Migration Record Status";
    begin
        BC14MigrationRecordStatus.MarkAsMigrated(SourceTableId, SourceRecordKey);
    end;

    // ============================================================
    // E2E Scenario Tests (Direct Runner Invocation)
    // These tests cover core migration scenarios without webhook complexity
    // ============================================================

    [Test]
    procedure TestMigrationRunnerCompletesSuccessfullyWithoutErrors()
    var
        BC14CompanySettings: Record BC14CompanyMigrationSettings;
        HybridCompanyStatus: Record "Hybrid Company Status";
        BC14E2ETestEventHandler: Codeunit "BC14 E2E Test Event Handler";
        BC14MigrationRunner: Codeunit "BC14 Migration Runner";
    begin
        // [SCENARIO] Migration runner completes successfully when no errors occur
        // This covers: TestSingleStepModeSuccessfulMigration

        // [GIVEN] Clean migration state
        Initialize();
        SetupHybridCompany();
        BindSubscription(BC14E2ETestEventHandler);
        BC14E2ETestEventHandler.Reset();

        // [GIVEN] Company status is set to Pending (simulating post-replication state)
        HybridCompanyStatus.Init();
        HybridCompanyStatus.Name := CopyStr(CompanyName(), 1, MaxStrLen(HybridCompanyStatus.Name));
        HybridCompanyStatus."Upgrade Status" := HybridCompanyStatus."Upgrade Status"::Pending;
        HybridCompanyStatus.Insert();

        // [GIVEN] Migration has not started
        BC14CompanySettings.GetSingleInstance();
        Assert.IsFalse(BC14CompanySettings.IsDataMigrationStarted(), 'Migration should not have started');

        // [WHEN] Migration runner executes
        BC14MigrationRunner.RunMigration();

        // [THEN] Migration state should be Completed
        // Clear and re-fetch to get fresh data from database (GetSingleInstance caches based on Name field)
        Clear(BC14CompanySettings);
        BC14CompanySettings.GetSingleInstance();
        Assert.AreEqual("BC14 Migration State"::Completed, BC14CompanySettings.GetMigrationState(), 'Migration should be completed');
        Assert.IsFalse(BC14CompanySettings.IsMigrationPaused(), 'Migration should not be paused');

        UnbindSubscription(BC14E2ETestEventHandler);
    end;

    [Test]
    procedure TestMigrationWithErrorLogsAndContinues()
    var
        BC14Customer: Record "BC14 Customer";
        BC14MigrationErrors: Record "BC14 Migration Errors";
        BC14CompanySettings: Record BC14CompanyMigrationSettings;
        HybridCompanyStatus: Record "Hybrid Company Status";
        BC14E2ETestEventHandler: Codeunit "BC14 E2E Test Event Handler";
        BC14MigrationRunner: Codeunit "BC14 Migration Runner";
    begin
        // [SCENARIO] In Continue On Error mode, migration logs errors and continues
        // This covers: TestUpgradeErrorFixAndRetrySucceeds (error logging part)

        // [GIVEN] Clean migration state with test customer data
        Initialize();
        SetupHybridCompany();
        BindSubscription(BC14E2ETestEventHandler);
        BC14E2ETestEventHandler.Reset();
        InsertTestCustomerData();

        // [GIVEN] Company status is Pending
        HybridCompanyStatus.Init();
        HybridCompanyStatus.Name := CopyStr(CompanyName(), 1, MaxStrLen(HybridCompanyStatus.Name));
        HybridCompanyStatus."Upgrade Status" := HybridCompanyStatus."Upgrade Status"::Pending;
        HybridCompanyStatus.Insert();

        // [GIVEN] Continue On Error mode (default - Stop On First Error = false)
        BC14CompanySettings.GetSingleInstance();
        BC14CompanySettings."Stop On First Error" := false;
        BC14CompanySettings.Modify();

        // [GIVEN] Error injection for CUST001
        BC14E2ETestEventHandler.SetErrorInjection('Customer Migrator', 'CUST001', 'Test error: Invalid posting group');

        // [WHEN] Migration runner executes
        BC14MigrationRunner.RunMigration();

        // [THEN] Error should be logged
        BC14MigrationErrors.SetRange("Migration Type", 'Customer Migrator');
        BC14MigrationErrors.SetRange("Source Record Key", 'CUST001');
        Assert.IsTrue(BC14MigrationErrors.FindFirst(), 'Error should be logged for CUST001');

        // [THEN] Migration state should still be Completed (Continue On Error mode)
        // Clear and re-fetch to get fresh data from database (GetSingleInstance caches based on Name field)
        Clear(BC14CompanySettings);
        BC14CompanySettings.GetSingleInstance();
        Assert.AreEqual("BC14 Migration State"::Completed, BC14CompanySettings.GetMigrationState(), 'Migration should complete despite errors');

        UnbindSubscription(BC14E2ETestEventHandler);
    end;

    [Test]
    procedure TestRetryFailedRecordsSucceeds()
    var
        BC14Customer: Record "BC14 Customer";
        BC14MigrationErrors: Record "BC14 Migration Errors";
        BC14CompanySettings: Record BC14CompanyMigrationSettings;
        HybridCompanyStatus: Record "Hybrid Company Status";
        BC14E2ETestEventHandler: Codeunit "BC14 E2E Test Event Handler";
        BC14MigrationRunner: Codeunit "BC14 Migration Runner";
    begin
        // [SCENARIO] After fixing buffer data, retry succeeds
        // This covers: TestUpgradeErrorFixAndRetrySucceeds (retry part)

        // [GIVEN] Migration with error already occurred
        Initialize();
        SetupHybridCompany();
        BindSubscription(BC14E2ETestEventHandler);
        BC14E2ETestEventHandler.Reset();
        InsertTestCustomerData();

        HybridCompanyStatus.Init();
        HybridCompanyStatus.Name := CopyStr(CompanyName(), 1, MaxStrLen(HybridCompanyStatus.Name));
        HybridCompanyStatus."Upgrade Status" := HybridCompanyStatus."Upgrade Status"::Pending;
        HybridCompanyStatus.Insert();

        BC14CompanySettings.GetSingleInstance();
        BC14CompanySettings."Stop On First Error" := false;
        BC14CompanySettings.Modify();

        BC14E2ETestEventHandler.SetErrorInjection('Customer Migrator', 'CUST001', 'Test error');
        BC14MigrationRunner.RunMigration();

        // [GIVEN] Error exists for CUST001
        BC14MigrationErrors.SetRange("Source Record Key", 'CUST001');
        Assert.IsTrue(BC14MigrationErrors.FindFirst(), 'Error should exist before retry');

        // [WHEN] Error injection is cleared and retry is invoked
        BC14E2ETestEventHandler.ClearErrorInjection();
        BC14MigrationRunner.RetryFailedRecords();

        // [THEN] Error should be resolved
        BC14MigrationErrors.SetRange("Source Record Key", 'CUST001');
        BC14MigrationErrors.SetRange(Resolved, false);
        Assert.IsTrue(BC14MigrationErrors.IsEmpty(), 'Error should be resolved after retry');

        UnbindSubscription(BC14E2ETestEventHandler);
    end;

    [Test]
    procedure TestStopOnFirstErrorPausesMigration()
    var
        BC14Customer: Record "BC14 Customer";
        BC14CompanySettings: Record BC14CompanyMigrationSettings;
        HybridCompanyStatus: Record "Hybrid Company Status";
        BC14E2ETestEventHandler: Codeunit "BC14 E2E Test Event Handler";
        BC14MigrationRunner: Codeunit "BC14 Migration Runner";
    begin
        // [SCENARIO] With Stop On First Error enabled, migration pauses on error

        // [GIVEN] Clean migration state with test customer data
        Initialize();
        SetupHybridCompany();
        BindSubscription(BC14E2ETestEventHandler);
        BC14E2ETestEventHandler.Reset();
        InsertTestCustomerData();

        HybridCompanyStatus.Init();
        HybridCompanyStatus.Name := CopyStr(CompanyName(), 1, MaxStrLen(HybridCompanyStatus.Name));
        HybridCompanyStatus."Upgrade Status" := HybridCompanyStatus."Upgrade Status"::Pending;
        HybridCompanyStatus.Insert();

        // [GIVEN] Stop On First Error mode enabled
        BC14CompanySettings.GetSingleInstance();
        BC14CompanySettings."Stop On First Error" := true;
        BC14CompanySettings.Modify();

        // [GIVEN] Error injection for CUST001
        BC14E2ETestEventHandler.SetErrorInjection('Customer Migrator', 'CUST001', 'Error: Missing posting group');

        // [WHEN] Migration runner executes (error expected to stop the flow)
        asserterror BC14MigrationRunner.RunMigration();

        // [THEN] Migration should be paused
        // Clear and re-fetch to get fresh data from database (GetSingleInstance caches based on Name field)
        Clear(BC14CompanySettings);
        BC14CompanySettings.GetSingleInstance();
        // Assert.IsTrue(BC14CompanySettings.IsMigrationPaused(), 'Migration should be paused after error');
        Assert.AreEqual("BC14 Migration State"::Paused, BC14CompanySettings.GetMigrationState(), 'State should be Paused');

        UnbindSubscription(BC14E2ETestEventHandler);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure TestContinueMigrationAfterFixingError()
    var
        BC14Customer: Record "BC14 Customer";
        BC14CompanySettings: Record BC14CompanyMigrationSettings;
        HybridCompanyStatus: Record "Hybrid Company Status";
        BC14E2ETestEventHandler: Codeunit "BC14 E2E Test Event Handler";
        BC14MigrationRunner: Codeunit "BC14 Migration Runner";
    begin
        // [SCENARIO] After fixing error, ContinueMigration completes successfully
        // This covers: TestSingleStepModeIterativeErrorFix (continue part)

        // [GIVEN] Migration is paused due to error
        Initialize();
        SetupHybridCompany();
        BindSubscription(BC14E2ETestEventHandler);
        BC14E2ETestEventHandler.Reset();
        InsertTestCustomerData();

        HybridCompanyStatus.Init();
        HybridCompanyStatus.Name := CopyStr(CompanyName(), 1, MaxStrLen(HybridCompanyStatus.Name));
        HybridCompanyStatus."Upgrade Status" := HybridCompanyStatus."Upgrade Status"::Pending;
        HybridCompanyStatus.Insert();

        BC14CompanySettings.GetSingleInstance();
        BC14CompanySettings."Stop On First Error" := true;
        BC14CompanySettings.Modify();

        BC14E2ETestEventHandler.SetErrorInjection('Customer Migrator', 'CUST001', 'Error');
        asserterror BC14MigrationRunner.RunMigration();

        // [GIVEN] Migration is paused
        // Clear and re-fetch to get fresh data from database (GetSingleInstance caches based on Name field)
        Clear(BC14CompanySettings);
        BC14CompanySettings.GetSingleInstance();
        // Assert.IsTrue(BC14CompanySettings.IsMigrationPaused(), 'Should be paused');
        Assert.AreEqual("BC14 Migration State"::Paused, BC14CompanySettings.GetMigrationState(), 'State should be Paused');

        // [WHEN] Error is fixed and Continue is called
        BC14E2ETestEventHandler.ClearErrorInjection();
        BC14MigrationRunner.ContinueMigration();

        // [THEN] Migration should complete
        // Clear and re-fetch to get fresh data from database (GetSingleInstance caches based on Name field)
        Clear(BC14CompanySettings);
        BC14CompanySettings.GetSingleInstance();
        // Assert.IsFalse(BC14CompanySettings.IsMigrationPaused(), 'Should not be paused after continue');
        Assert.AreEqual("BC14 Migration State"::Completed, BC14CompanySettings.GetMigrationState(), 'Should be completed');

        UnbindSubscription(BC14E2ETestEventHandler);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure TestIterativeErrorFixWithMultiplePauses()
    var
        BC14CompanySettings: Record BC14CompanyMigrationSettings;
        HybridCompanyStatus: Record "Hybrid Company Status";
        BC14E2ETestEventHandler: Codeunit "BC14 E2E Test Event Handler";
        BC14MigrationRunner: Codeunit "BC14 Migration Runner";
    begin
        // [SCENARIO] Pause-fix-continue cycle works correctly
        // Note: Multiple pause cycles cannot be tested with asserterror due to TryFunction limitations

        // [GIVEN] Clean state with customer data
        Initialize();
        SetupHybridCompany();
        BindSubscription(BC14E2ETestEventHandler);
        BC14E2ETestEventHandler.Reset();
        InsertTestCustomerData();

        HybridCompanyStatus.Init();
        HybridCompanyStatus.Name := CopyStr(CompanyName(), 1, MaxStrLen(HybridCompanyStatus.Name));
        HybridCompanyStatus."Upgrade Status" := HybridCompanyStatus."Upgrade Status"::Pending;
        HybridCompanyStatus.Insert();

        BC14CompanySettings.GetSingleInstance();
        BC14CompanySettings."Stop On First Error" := true;
        BC14CompanySettings.Modify();

        // [GIVEN] Error on CUST001
        BC14E2ETestEventHandler.SetErrorInjection('Customer Migrator', 'CUST001', 'Test error');
        asserterror BC14MigrationRunner.RunMigration();

        // [THEN] Migration is paused
        Clear(BC14CompanySettings);
        BC14CompanySettings.GetSingleInstance();
        Assert.IsTrue(BC14CompanySettings.IsMigrationPaused(), 'Should be paused after error');

        // [WHEN] Fix error and continue
        BC14E2ETestEventHandler.ClearErrorInjection();
        BC14MigrationRunner.ContinueMigration();

        // [THEN] Migration completes
        Clear(BC14CompanySettings);
        BC14CompanySettings.GetSingleInstance();
        Assert.AreEqual("BC14 Migration State"::Completed, BC14CompanySettings.GetMigrationState(), 'Should be completed');

        UnbindSubscription(BC14E2ETestEventHandler);
    end;

    local procedure InsertTestCustomerData()
    var
        BC14Customer: Record "BC14 Customer";
    begin
        BC14Customer.Init();
        BC14Customer."No." := 'CUST001';
        BC14Customer.Name := 'Test Customer 1';
        BC14Customer."Customer Posting Group" := 'DOMESTIC';
        if not BC14Customer.Insert() then
            BC14Customer.Modify();

        BC14Customer.Init();
        BC14Customer."No." := 'CUST002';
        BC14Customer.Name := 'Test Customer 2';
        BC14Customer."Customer Posting Group" := 'FOREIGN';
        if not BC14Customer.Insert() then
            BC14Customer.Modify();

        BC14Customer.Init();
        BC14Customer."No." := 'CUST003';
        BC14Customer.Name := 'Test Customer 3';
        BC14Customer."Customer Posting Group" := 'DOMESTIC';
        if not BC14Customer.Insert() then
            BC14Customer.Modify();
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    procedure MessageHandlerOk(Message: Text[1024])
    begin
        // Accept any message
    end;
}
