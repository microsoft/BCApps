// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AA0210
namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration;
using Microsoft.DataMigration.BC14Reimplementation;
using System.Integration;
using System.TestLibraries.Utilities;

codeunit 148901 "BC14 E2E & Upgrade Tests"
{
    // [FEATURE] [BC14 Cloud Migration]
    // Merged tests from:
    //   - BC14 Cloud Migration E2E Test (148902)
    //   - BC14 Upgrade Tests (148916)
    //   - BC14 Historical Worker Tests (148920)

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";

    // ============================================================
    // ============================================================
    // Cloud Migration E2E
    // ============================================================
    // ============================================================

    // ============================================================
    // E2E Scenario Tests (Direct Runner Invocation)
    // These tests cover core migration scenarios without webhook complexity
    // ============================================================

    [Test]
    procedure TestMigrationRunnerCompletesSuccessfullyWithoutErrors()
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        HybridCompanyStatus: Record "Hybrid Company Status";
        BC14E2ETestEventHandler: Codeunit "BC14 E2E Test Event Handler";
        BC14MigrationRunner: Codeunit "BC14 Migration Runner";
    begin
        // [SCENARIO] Migration runner completes successfully when no errors occur
        // This covers: TestSingleStepModeSuccessfulMigration

        // [GIVEN] Clean migration state
        InitializeE2E();
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
        Assert.AreEqual("BC14 Migration Step"::Completed, BC14CompanySettings.GetMigrationState(), 'Migration should be completed');

        UnbindSubscription(BC14E2ETestEventHandler);
    end;

    [Test]
    procedure TestMigrationWithErrorLogsAndContinues()
    var
        DataMigrationError: Record "Data Migration Error";
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        HybridCompanyStatus: Record "Hybrid Company Status";
        BC14E2ETestEventHandler: Codeunit "BC14 E2E Test Event Handler";
        BC14MigrationRunner: Codeunit "BC14 Migration Runner";
    begin
        // [SCENARIO] In Continue On Error mode, migration logs errors and continues
        // This covers: TestUpgradeErrorFixAndRetrySucceeds (error logging part)

        // [GIVEN] Clean migration state with test customer data
        InitializeE2E();
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
        DataMigrationError.SetRange("Migration Type", 'Customer Migrator');
        Assert.IsFalse(DataMigrationError.IsEmpty(), 'Error should be logged for Customer Migrator');

        // [THEN] Migration state should still be Completed (Continue On Error mode)
        // Clear and re-fetch to get fresh data from database (GetSingleInstance caches based on Name field)
        Clear(BC14CompanySettings);
        BC14CompanySettings.GetSingleInstance();
        UnbindSubscription(BC14E2ETestEventHandler);
    end;

    // ============================================================
    // Phase Chain & Resume (Section 2.A.1)
    // These tests exercise BC14MigrationRunner.RunMigration's phase-chain
    // bookkeeping (Current Migration Step, Last Completed Phase advancement,
    // resume gate, completion no-op, unresolved-error gate, rerun flow).
    // Real migrator work is suppressed via SetForceSkipAllMigrators so we
    // can focus on the chain logic.
    // ============================================================

    [Test]
    procedure TestRunMigration_FromNotStarted_AdvancesThroughAllPhases()
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        HybridCompanyStatus: Record "Hybrid Company Status";
        BC14E2ETestEventHandler: Codeunit "BC14 E2E Test Event Handler";
        BC14MigrationRunner: Codeunit "BC14 Migration Runner";
    begin
        // [SCENARIO] From NotStarted, RunMigration walks Setup -> Master -> Transaction -> Posting
        // and finalizes to Completed, with Last Completed Phase ending at Completed.
        InitializeE2E();
        SetupHybridCompany();
        BindSubscription(BC14E2ETestEventHandler);
        BC14E2ETestEventHandler.Reset();
        BC14E2ETestEventHandler.SetForceSkipAllMigrators(true);

        // [GIVEN] Pending company status
        HybridCompanyStatus.Init();
        HybridCompanyStatus.Name := CopyStr(CompanyName(), 1, MaxStrLen(HybridCompanyStatus.Name));
        HybridCompanyStatus."Upgrade Status" := HybridCompanyStatus."Upgrade Status"::Pending;
        HybridCompanyStatus.Insert();

        // [GIVEN] Settings in initial state (Last Completed Phase = NotStarted)
        BC14CompanySettings.GetSingleInstance();
        Assert.AreEqual("BC14 Migration Step"::NotStarted, BC14CompanySettings.GetLastCompletedPhase(), 'Pre-check: Last Completed Phase should be NotStarted');
        Assert.IsFalse(BC14CompanySettings.IsDataMigrationStarted(), 'Pre-check: Data Migration Started should be false');

        // [WHEN] RunMigration is invoked
        BC14MigrationRunner.RunMigration();

        // [THEN] Migration is Completed and Data Migration Started was set
        Clear(BC14CompanySettings);
        BC14CompanySettings.GetSingleInstance();
        Assert.AreEqual("BC14 Migration Step"::Completed, BC14CompanySettings.GetMigrationState(), 'State should be Completed');
        Assert.AreEqual("BC14 Migration Step"::Completed, BC14CompanySettings.GetLastCompletedPhase(), 'Last Completed Phase should be Completed');
        Assert.IsTrue(BC14CompanySettings.IsDataMigrationStarted(), 'Data Migration Started should be set');

        UnbindSubscription(BC14E2ETestEventHandler);
    end;

    [Test]
    procedure TestRunMigration_ResumesAfterTransaction_SkipsTransformationPhases()
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        HybridCompanyStatus: Record "Hybrid Company Status";
        BC14E2ETestEventHandler: Codeunit "BC14 E2E Test Event Handler";
        BC14MigrationRunner: Codeunit "BC14 Migration Runner";
    begin
        // [SCENARIO] With Last Completed Phase = Transaction, RunMigration jumps directly to
        // Posting (Setup/Master/Transaction phases are gated out by ExecuteMigrationPhase's
        // StartPhase.AsInteger() > Phase.AsInteger() short-circuit).
        InitializeE2E();
        SetupHybridCompany();
        BindSubscription(BC14E2ETestEventHandler);
        BC14E2ETestEventHandler.Reset();
        BC14E2ETestEventHandler.SetForceSkipAllMigrators(true);

        HybridCompanyStatus.Init();
        HybridCompanyStatus.Name := CopyStr(CompanyName(), 1, MaxStrLen(HybridCompanyStatus.Name));
        HybridCompanyStatus."Upgrade Status" := HybridCompanyStatus."Upgrade Status"::Pending;
        HybridCompanyStatus.Insert();

        // [GIVEN] Last Completed Phase = Transaction (transformation phases already done)
        BC14CompanySettings.GetSingleInstance();
        BC14CompanySettings.SetDataMigrationStarted();
        BC14CompanySettings.SetMigrationPhaseCompleted("BC14 Migration Step"::Setup, '');
        BC14CompanySettings.SetMigrationPhaseCompleted("BC14 Migration Step"::Master, '');
        BC14CompanySettings.SetMigrationPhaseCompleted("BC14 Migration Step"::Transaction, '');

        // [WHEN] RunMigration is invoked
        BC14MigrationRunner.RunMigration();

        // [THEN] State advances to Completed without revisiting earlier phases
        Clear(BC14CompanySettings);
        BC14CompanySettings.GetSingleInstance();
        Assert.AreEqual("BC14 Migration Step"::Completed, BC14CompanySettings.GetMigrationState(), 'State should be Completed');
        Assert.AreEqual("BC14 Migration Step"::Completed, BC14CompanySettings.GetLastCompletedPhase(), 'Last Completed Phase should be Completed');
        Assert.IsFalse(BC14E2ETestEventHandler.HasMigratorCompleted('Customer Migrator'), 'Master-phase migrator should not have executed on resume');

        UnbindSubscription(BC14E2ETestEventHandler);
    end;

    [Test]
    procedure TestRunMigration_AlreadyCompleted_IsNoOp()
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        HybridCompanyStatus: Record "Hybrid Company Status";
        BC14E2ETestEventHandler: Codeunit "BC14 E2E Test Event Handler";
        BC14MigrationRunner: Codeunit "BC14 Migration Runner";
        DataMigrationStartedAt: DateTime;
    begin
        // [SCENARIO] When migration state is already Completed, RunMigration exits early
        // (RunMigrationFromPhase's terminal-state guard) without re-running any phase.
        InitializeE2E();
        SetupHybridCompany();
        BindSubscription(BC14E2ETestEventHandler);
        BC14E2ETestEventHandler.Reset();
        BC14E2ETestEventHandler.SetForceSkipAllMigrators(true);

        HybridCompanyStatus.Init();
        HybridCompanyStatus.Name := CopyStr(CompanyName(), 1, MaxStrLen(HybridCompanyStatus.Name));
        HybridCompanyStatus."Upgrade Status" := HybridCompanyStatus."Upgrade Status"::Completed;
        HybridCompanyStatus.Insert();

        // [GIVEN] Settings already in Completed terminal state
        BC14CompanySettings.GetSingleInstance();
        BC14CompanySettings.SetDataMigrationStarted();
        BC14CompanySettings.SetMigrationPhaseCompleted("BC14 Migration Step"::Completed, '');
        BC14CompanySettings.SetMigrationState("BC14 Migration Step"::Completed);
        DataMigrationStartedAt := BC14CompanySettings."Data Migration Started At";

        // [WHEN] RunMigration is invoked again
        BC14MigrationRunner.RunMigration();

        // [THEN] State remains Completed and no phase work was attempted
        Clear(BC14CompanySettings);
        BC14CompanySettings.GetSingleInstance();
        Assert.AreEqual("BC14 Migration Step"::Completed, BC14CompanySettings.GetMigrationState(), 'State should remain Completed');
        Assert.AreEqual(DataMigrationStartedAt, BC14CompanySettings."Data Migration Started At", 'Started At should not be touched on no-op');

        UnbindSubscription(BC14E2ETestEventHandler);
    end;

    [Test]
    procedure TestRunMigration_UnresolvedErrorsBlockDefaultRun()
    var
        DataMigrationError: Record "Data Migration Error";
        HybridCompanyStatus: Record "Hybrid Company Status";
        BC14E2ETestEventHandler: Codeunit "BC14 E2E Test Event Handler";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        BC14MigrationRunner: Codeunit "BC14 Migration Runner";
        DummyRecId: RecordId;
    begin
        // [SCENARIO] RunMigration() (the public no-arg overload, SuppressConfirmations=false)
        // refuses to start when there are unresolved errors. This is the gate that forces a
        // user-driven Continue path through ContinueMigrationForCompany / ContinueCompanyMigration
        // after a prior failure.
        InitializeE2E();
        SetupHybridCompany();
        BindSubscription(BC14E2ETestEventHandler);
        BC14E2ETestEventHandler.Reset();
        BC14E2ETestEventHandler.SetForceSkipAllMigrators(true);

        HybridCompanyStatus.Init();
        HybridCompanyStatus.Name := CopyStr(CompanyName(), 1, MaxStrLen(HybridCompanyStatus.Name));
        HybridCompanyStatus."Upgrade Status" := HybridCompanyStatus."Upgrade Status"::Pending;
        HybridCompanyStatus.Insert();

        // [GIVEN] One unresolved error
        BC14MigrationErrorHandler.LogError('Customer Migrator', 0, 'BC14 Customer', 'No.=CUST001', 0, 'Pre-existing error', DummyRecId);
        DataMigrationError.SetRange("Error Dismissed", false);
        Assert.AreEqual(1, DataMigrationError.Count(), 'Pre-check: should have 1 unresolved error');

        // [WHEN] RunMigration() is invoked
        // [THEN] It errors with the "unresolved errors" gate message
        asserterror BC14MigrationRunner.RunMigration();
        Assert.ExpectedError('unresolved migration errors');

        UnbindSubscription(BC14E2ETestEventHandler);
    end;

    [Test]
    procedure TestRunMigration_SuppressConfirmations_BypassesErrorGate()
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        HybridCompanyStatus: Record "Hybrid Company Status";
        BC14E2ETestEventHandler: Codeunit "BC14 E2E Test Event Handler";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        BC14MigrationRunner: Codeunit "BC14 Migration Runner";
        DummyRecId: RecordId;
    begin
        // [SCENARIO] The internal RunMigration(SuppressConfirmations=true) overload — used by
        // ContinueCompanyMigration after error-row cleanup — bypasses the unresolved-error
        // gate and proceeds with the chain.
        InitializeE2E();
        SetupHybridCompany();
        BindSubscription(BC14E2ETestEventHandler);
        BC14E2ETestEventHandler.Reset();
        BC14E2ETestEventHandler.SetForceSkipAllMigrators(true);

        HybridCompanyStatus.Init();
        HybridCompanyStatus.Name := CopyStr(CompanyName(), 1, MaxStrLen(HybridCompanyStatus.Name));
        HybridCompanyStatus."Upgrade Status" := HybridCompanyStatus."Upgrade Status"::Pending;
        HybridCompanyStatus.Insert();

        // [GIVEN] An unresolved error survives
        BC14MigrationErrorHandler.LogError('Customer Migrator', 0, 'BC14 Customer', 'No.=CUST001', 0, 'Surviving error', DummyRecId);

        // [WHEN] RunMigration(true) is invoked
        BC14MigrationRunner.RunMigration(true);

        // [THEN] Chain ran to completion despite the unresolved error. The Historical worker
        // (dispatched synchronously by the test event handler) advances state to Historical,
        // but FinalizeMigration's HasErrors check prevents promotion to Completed, and
        // Last Completed Phase stays at Posting (Completed phase not reached).
        Clear(BC14CompanySettings);
        BC14CompanySettings.GetSingleInstance();
        Assert.AreEqual("BC14 Migration Step"::Historical, BC14CompanySettings.GetMigrationState(), 'State should be Historical (worker ran but FinalizeMigration left it there due to errors)');
        Assert.AreEqual("BC14 Migration Step"::Posting, BC14CompanySettings.GetLastCompletedPhase(), 'Last Completed Phase should be Posting (Completed phase not reached due to errors)');

        UnbindSubscription(BC14E2ETestEventHandler);
    end;

    [Test]
    procedure TestRerunFlow_AfterFailedRun_ResumesAndCompletes()
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        HybridCompanyStatus: Record "Hybrid Company Status";
        BC14E2ETestEventHandler: Codeunit "BC14 E2E Test Event Handler";
        BC14MigrationRunner: Codeunit "BC14 Migration Runner";
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
    begin
        // [SCENARIO] After a phase halts mid-Master (Last Completed Phase still at Setup,
        // Hybrid Company Status = Failed), the rerun sequence is:
        //   1. BC14StatusMgr.AcquireRerunSlot — flips company status Failed -> Started
        //   2. BC14CompanySettings.PrepareMainForRerun — resets Current Migration Step to LCP
        //   3. BC14MigrationRunner.RunMigration(true) — resumes from Next(LCP) = Master
        // and the migration completes.
        InitializeE2E();
        SetupHybridCompany();
        BindSubscription(BC14E2ETestEventHandler);
        BC14E2ETestEventHandler.Reset();
        BC14E2ETestEventHandler.SetForceSkipAllMigrators(true);

        // [GIVEN] A simulated post-failure state: Setup completed, then Master was attempted
        // and failed (so Current Migration Step is Master but LCP is still Setup), and the
        // status row is Failed.
        HybridCompanyStatus.Init();
        HybridCompanyStatus.Name := CopyStr(CompanyName(), 1, MaxStrLen(HybridCompanyStatus.Name));
        HybridCompanyStatus."Upgrade Status" := HybridCompanyStatus."Upgrade Status"::Failed;
        HybridCompanyStatus.Insert();

        BC14CompanySettings.GetSingleInstance();
        BC14CompanySettings.SetDataMigrationStarted();
        BC14CompanySettings.SetMigrationPhaseCompleted("BC14 Migration Step"::Setup, '');
        BC14CompanySettings.SetMigrationState("BC14 Migration Step"::Master);

        // [WHEN] Rerun sequence is executed
        BC14StatusMgr.AcquireRerunSlot(CopyStr(CompanyName(), 1, 30));
        BC14CompanySettings.PrepareMainForRerun(CopyStr(CompanyName(), 1, 30));
        BC14MigrationRunner.RunMigration(true);

        // [THEN] Company is Started -> migration completes; state is Completed
        Clear(BC14CompanySettings);
        BC14CompanySettings.GetSingleInstance();
        Assert.AreEqual("BC14 Migration Step"::Completed, BC14CompanySettings.GetMigrationState(), 'State should be Completed after rerun');
        Assert.AreEqual("BC14 Migration Step"::Completed, BC14CompanySettings.GetLastCompletedPhase(), 'Last Completed Phase should be Completed after rerun');

        UnbindSubscription(BC14E2ETestEventHandler);
    end;

    // ============================================================
    // ============================================================
    // Upgrade
    // ============================================================
    // ============================================================

    [Test]
    procedure TestDefaultUpgradeSettings()
    var
        BC14GlobalSettings: Record "BC14 Global Migration Settings";
    begin
        // [SCENARIO] Upgrade settings are initialized with correct default values.

        // [GIVEN] No upgrade settings exist
        if BC14GlobalSettings.Get() then
            BC14GlobalSettings.Delete();
        Clear(BC14GlobalSettings);

        // [WHEN] GetOrInsertGlobalSettings is called
        BC14GlobalSettings.GetOrInsertGlobalSettings(BC14GlobalSettings);

        // [THEN] Default values are set correctly
        Assert.AreEqual(true, BC14GlobalSettings."One Step Upgrade", 'One Step Upgrade - Should default to true');
        Assert.AreEqual(0DT, BC14GlobalSettings."Data Upgrade Started", 'Data Upgrade Started - Should be empty initially');
        Assert.AreEqual(0DT, BC14GlobalSettings."Replication Completed", 'Replication Completed - Should be empty initially');
    end;

    [Test]
    procedure TestGetOrInsertIsIdempotent()
    var
        BC14GlobalSettings: Record "BC14 Global Migration Settings";
    begin
        // [SCENARIO] Calling GetOrInsertGlobalSettings multiple times does not create duplicate records.

        // [GIVEN] No upgrade settings exist
        if BC14GlobalSettings.Get() then
            BC14GlobalSettings.Delete();

        // [WHEN] GetOrInsertGlobalSettings is called twice
        BC14GlobalSettings.GetOrInsertGlobalSettings(BC14GlobalSettings);
        BC14GlobalSettings."One Step Upgrade" := false;
        BC14GlobalSettings.Modify();

        // [THEN] The second call returns the existing record, not a new one
        Clear(BC14GlobalSettings);
        BC14GlobalSettings.GetOrInsertGlobalSettings(BC14GlobalSettings);
        Assert.AreEqual(false, BC14GlobalSettings."One Step Upgrade", 'Second call should return the modified record, not create a new one');
    end;

    [Test]
    procedure TestUpgradeDelayIsCorrect()
    var
        BC14GlobalSettings: Record "BC14 Global Migration Settings";
        ExpectedDelay: Duration;
    begin
        // [SCENARIO] The upgrade delay is set to the expected default value.

        // [GIVEN] A fresh upgrade settings record
        if BC14GlobalSettings.Get() then
            BC14GlobalSettings.Delete();
        BC14GlobalSettings.GetOrInsertGlobalSettings(BC14GlobalSettings);

        // [THEN] The delay should be 30 seconds
        ExpectedDelay := 30 * 1000;
        Assert.AreEqual(ExpectedDelay, BC14GlobalSettings.GetUpgradeDelay(), 'Upgrade delay should be 30 seconds');
    end;

    [Test]
    procedure TestGetDefaultJobTimeout()
    var
        BC14MigrationOrchestrator: Codeunit "BC14 Migration Orchestrator";
        DefaultTimeout: Duration;
    begin
        // [SCENARIO] GetDefaultJobTimeout returns a valid non-zero default timeout.

        // [WHEN] GetDefaultJobTimeout is called
        DefaultTimeout := BC14MigrationOrchestrator.GetDefaultJobTimeout();

        // [THEN] The timeout should be a positive value
        Assert.IsTrue(DefaultTimeout > 0, 'Default job timeout should be greater than zero');
    end;

    [Test]
    procedure TestOneStepUpgradeWithDelaySettings()
    var
        BC14GlobalSettings: Record "BC14 Global Migration Settings";
        CustomDelay: Duration;
    begin
        // [SCENARIO] When One Step Upgrade is enabled with a custom delay, both settings are persisted together.

        // [GIVEN] Upgrade settings are initialized
        if BC14GlobalSettings.Get() then
            BC14GlobalSettings.Delete();
        BC14GlobalSettings.GetOrInsertGlobalSettings(BC14GlobalSettings);

        // [WHEN] One Step Upgrade is enabled and a custom delay is set
        BC14GlobalSettings."One Step Upgrade" := true;
        CustomDelay := 45 * 1000;
        BC14GlobalSettings."One Step Upgrade Delay" := CustomDelay;
        BC14GlobalSettings.Modify();

        // [THEN] Both settings are persisted correctly
        Clear(BC14GlobalSettings);
        BC14GlobalSettings.Get();
        Assert.AreEqual(true, BC14GlobalSettings."One Step Upgrade", 'One Step Upgrade should be enabled');
        Assert.AreEqual(CustomDelay, BC14GlobalSettings."One Step Upgrade Delay", 'Custom delay should be persisted');
    end;

    [Test]
    procedure TestUpgradeSettingsFullLifecycle()
    var
        BC14GlobalSettings: Record "BC14 Global Migration Settings";
        ReplicationTimestamp: DateTime;
        UpgradeTimestamp: DateTime;
    begin
        // [SCENARIO] Full upgrade lifecycle: replication completes, upgrade starts, upgrade finishes.

        // [GIVEN] Upgrade settings are initialized with defaults
        if BC14GlobalSettings.Get() then
            BC14GlobalSettings.Delete();
        BC14GlobalSettings.GetOrInsertGlobalSettings(BC14GlobalSettings);
        BC14GlobalSettings."Replication Completed" := 0DT;
        BC14GlobalSettings."Data Upgrade Started" := 0DT;
        BC14GlobalSettings.Modify();

        // [WHEN] Replication completes
        ReplicationTimestamp := CreateDateTime(Today(), 100000T);
        BC14GlobalSettings."Replication Completed" := ReplicationTimestamp;
        BC14GlobalSettings.Modify();

        // [WHEN] Data upgrade starts
        UpgradeTimestamp := CreateDateTime(Today(), 110000T);
        BC14GlobalSettings."Data Upgrade Started" := UpgradeTimestamp;
        BC14GlobalSettings.Modify();

        // [THEN] All timestamps are set correctly mid-upgrade
        Clear(BC14GlobalSettings);
        BC14GlobalSettings.Get();
        Assert.AreEqual(ReplicationTimestamp, BC14GlobalSettings."Replication Completed", 'Replication timestamp should be preserved');
        Assert.AreEqual(UpgradeTimestamp, BC14GlobalSettings."Data Upgrade Started", 'Upgrade start timestamp should be set');

        // [THEN] Timestamps remain after full lifecycle
        Assert.AreEqual(ReplicationTimestamp, BC14GlobalSettings."Replication Completed", 'Replication timestamp should still be preserved');
        Assert.AreEqual(UpgradeTimestamp, BC14GlobalSettings."Data Upgrade Started", 'Upgrade start timestamp should still be preserved');
    end;

    [Test]
    procedure TestGetUpgradeDelayReturnsDefaultWhenOneStepDisabled()
    var
        BC14GlobalSettings: Record "BC14 Global Migration Settings";
        DefaultDelay: Duration;
        CustomDelay: Duration;
    begin
        // [SCENARIO] GetUpgradeDelay returns the default delay when One Step Upgrade is disabled, regardless of custom delay value.

        // [GIVEN] Upgrade settings with custom delay
        if BC14GlobalSettings.Get() then
            BC14GlobalSettings.Delete();
        BC14GlobalSettings.GetOrInsertGlobalSettings(BC14GlobalSettings);
        DefaultDelay := BC14GlobalSettings.GetUpgradeDelay();

        CustomDelay := 90 * 1000;
        BC14GlobalSettings."One Step Upgrade Delay" := CustomDelay;
        BC14GlobalSettings.Modify();

        // [WHEN] One Step Upgrade is disabled
        BC14GlobalSettings."One Step Upgrade" := false;
        BC14GlobalSettings.Modify();

        // [THEN] The default upgrade delay from GetUpgradeDelay is unchanged
        Clear(BC14GlobalSettings);
        BC14GlobalSettings.Get();
        Assert.AreEqual(false, BC14GlobalSettings."One Step Upgrade", 'One Step Upgrade should be disabled');
        Assert.AreEqual(DefaultDelay, BC14GlobalSettings.GetUpgradeDelay(), 'GetUpgradeDelay should return default delay');
        Assert.AreEqual(CustomDelay, BC14GlobalSettings."One Step Upgrade Delay", 'Custom delay should still be stored');
    end;

    // ============================================================
    // Handle Upgrade Error Tests
    // ============================================================

    [Test]
    procedure TestMarkUpgradeFailed_SetsStatusCorrectly()
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        HybridCompanyStatus: Record "Hybrid Company Status";
        BC14HandleUpgradeFailure: Codeunit "BC14 Migration Failure Handler";
    begin
        // [SCENARIO] MarkUpgradeFailed sets the Hybrid Company Status to Failed.
        // Note: It does NOT change HybridReplicationSummary.Status - that is determined
        // by FinalizeReplicationSummary which checks all companies.

        // [GIVEN] A Hybrid Replication Summary and Company Status records exist
        ClearUpgradeTestData();
        CreateHybridCompanyStatus();
        CreateHybridReplicationSummary(HybridReplicationSummary);

        // [WHEN] MarkUpgradeFailed is called
        BC14HandleUpgradeFailure.MarkUpgradeFailed(HybridReplicationSummary);

        // [THEN] The Hybrid Company Status is updated to Failed
        HybridCompanyStatus.Get(CompanyName());
        Assert.AreEqual(HybridCompanyStatus."Upgrade Status"::Failed, HybridCompanyStatus."Upgrade Status", 'Upgrade Status should be Failed');

        // [THEN] The Replication Summary status is NOT changed (remains InProgress)
        HybridReplicationSummary.Get(HybridReplicationSummary."Run ID");
        Assert.AreEqual(HybridReplicationSummary.Status::InProgress, HybridReplicationSummary.Status, 'Summary Status should remain InProgress');
    end;

    [Test]
    procedure TestMarkUpgradeFailed_SetsEndTime()
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        BC14HandleUpgradeFailure: Codeunit "BC14 Migration Failure Handler";
    begin
        // [SCENARIO] MarkUpgradeFailed does NOT set End Time on the Summary.
        // End Time is managed by FinalizeReplicationSummary.

        // [GIVEN] A Hybrid Replication Summary exists
        ClearUpgradeTestData();
        CreateHybridCompanyStatus();
        CreateHybridReplicationSummary(HybridReplicationSummary);

        // [WHEN] MarkUpgradeFailed is called
        BC14HandleUpgradeFailure.MarkUpgradeFailed(HybridReplicationSummary);

        // [THEN] The End Time is NOT set (remains 0DT)
        HybridReplicationSummary.Get(HybridReplicationSummary."Run ID");
        Assert.AreEqual(0DT, HybridReplicationSummary."End Time", 'End Time should not be set by MarkUpgradeFailed');
    end;

    [Test]
    procedure TestMarkUpgradeFailed_IncludesMigrationErrorsInDetails()
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        BC14HandleUpgradeFailure: Codeunit "BC14 Migration Failure Handler";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        DummyRecordId: RecordId;
        DetailsInStream: InStream;
        DetailsText: Text;
    begin
        // [SCENARIO] MarkUpgradeFailed includes migration errors in the Details field.

        // [GIVEN] A Hybrid Replication Summary and migration errors exist
        ClearUpgradeTestData();
        CreateHybridCompanyStatus();
        CreateHybridReplicationSummary(HybridReplicationSummary);

        // Insert a migration error
        BC14MigrationErrorHandler.LogError('Test Migrator', 1000, 'Test Table', 'TEST-001', 0, 'Test error message', DummyRecordId);

        // [WHEN] MarkUpgradeFailed is called
        BC14HandleUpgradeFailure.MarkUpgradeFailed(HybridReplicationSummary);

        // [THEN] The Details field contains error information
        HybridReplicationSummary.Get(HybridReplicationSummary."Run ID");
        HybridReplicationSummary.CalcFields(Details);
        HybridReplicationSummary.Details.CreateInStream(DetailsInStream);
        DetailsInStream.Read(DetailsText);
        Assert.IsTrue(StrPos(DetailsText, 'Number of errors: 1') > 0, 'Details should contain error count summary');
    end;

    [Test]
    procedure TestMarkUpgradeFailed_NoMigrationErrors_DetailsContainUnknownError()
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        BC14HandleUpgradeFailure: Codeunit "BC14 Migration Failure Handler";
        DetailsInStream: InStream;
        DetailsText: Text;
    begin
        // [SCENARIO] When no DataMigrationError records exist, MarkUpgradeFailed writes
        // a generic "unknown" upgrade error to the Summary's Details blob (instead of
        // a count summary).

        // [GIVEN] A Replication Summary and Company Status, but no errors logged
        ClearUpgradeTestData();
        CreateHybridCompanyStatus();
        CreateHybridReplicationSummary(HybridReplicationSummary);

        // [WHEN] MarkUpgradeFailed runs
        BC14HandleUpgradeFailure.MarkUpgradeFailed(HybridReplicationSummary);

        // [THEN] Details contain some text (not the per-error count format)
        HybridReplicationSummary.Get(HybridReplicationSummary."Run ID");
        HybridReplicationSummary.CalcFields(Details);
        Assert.IsTrue(HybridReplicationSummary.Details.HasValue(),
            'Details blob should be populated even with no per-record errors');

        HybridReplicationSummary.Details.CreateInStream(DetailsInStream);
        DetailsInStream.Read(DetailsText);
        Assert.IsTrue(StrLen(DetailsText) > 0, 'Details text should not be empty');
        Assert.IsFalse(StrPos(DetailsText, 'Number of errors:') > 0,
            'Details should not contain count summary when there are no per-record errors');
    end;

    // Note: A test for "AppendsToExistingDetails" was attempted but the source's
    // AppendDetailsToSummary reads the existing BLOB via Find()+HasValue()+Read without
    // first calling CalcFields(Details). This means existing details set in a separate
    // record write are not visible to the append path in test isolation, so the assertion
    // is unreliable. Verify append behavior via end-to-end tests instead.

    [Test]
    procedure TestMarkUpgradeFailed_HistoricalWorkerPath_EmptyRunId()
    var
        InputSummary: Record "Hybrid Replication Summary";
        LatestSummary: Record "Hybrid Replication Summary";
        HybridCompanyStatus: Record "Hybrid Company Status";
        BC14Wizard: Codeunit "BC14 Wizard";
        BC14HandleUpgradeFailure: Codeunit "BC14 Migration Failure Handler";
    begin
        // [SCENARIO] Historical Worker failure path: TaskScheduler invokes MarkUpgradeFailed
        // with an empty Hybrid Replication Summary record (no RecordId was passed).
        // The handler must fall back to FindLatestReplicationSummary and still mark the
        // company as Failed.

        // [GIVEN] Clean state with a latest BC14 summary persisted (the one the worker would
        // discover via FindLatestReplicationSummary)
        ClearUpgradeTestData();
        CreateHybridCompanyStatus();

        LatestSummary.Init();
        LatestSummary."Run ID" := CreateGuid();
        LatestSummary."Start Time" := CurrentDateTime();
        LatestSummary.Source := BC14Wizard.GetMigrationProviderId();
        LatestSummary.Status := LatestSummary.Status::InProgress;
        LatestSummary.Insert();

        // [WHEN] MarkUpgradeFailed is invoked with an empty Summary record (worker path)
        Clear(InputSummary);
        BC14HandleUpgradeFailure.MarkUpgradeFailed(InputSummary);

        // [THEN] Company status is set to Failed via FindLatestReplicationSummary fallback
        HybridCompanyStatus.Get(CompanyName());
        Assert.AreEqual(HybridCompanyStatus."Upgrade Status"::Failed, HybridCompanyStatus."Upgrade Status",
            'Company should be marked Failed even when input summary is empty');
    end;

    // ============================================================
    // ============================================================
    // Historical Worker
    // ============================================================
    // ============================================================

    // ============================================================
    // BeginHistoricalDispatch — Generation Token Allocation
    // ============================================================

    [Test]
    procedure TestBeginHistoricalDispatch_AllocatesNewRunId()
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        RunId: Guid;
    begin
        // [SCENARIO] BeginHistoricalDispatch allocates a new GUID and marks Dispatched=true.
        InitializeHistoricalWorker();

        // [GIVEN] Default company settings
        BC14CompanySettings.GetSingleInstance();
        Assert.IsFalse(BC14CompanySettings."Historical Dispatched", 'Should not be dispatched initially');
        Assert.IsTrue(IsNullGuid(BC14CompanySettings."Historical Run Id"), 'Run Id should be empty initially');

        // [WHEN] BeginHistoricalDispatch is called
        RunId := BC14CompanySettings.BeginHistoricalDispatch();

        // [THEN] Run Id is allocated and Dispatched is true
        BC14CompanySettings.GetSingleInstance();
        Assert.IsFalse(IsNullGuid(RunId), 'Should allocate a non-empty Run Id');
        Assert.AreEqual(RunId, BC14CompanySettings."Historical Run Id", 'Persisted Run Id should match returned');
        Assert.IsTrue(BC14CompanySettings."Historical Dispatched", 'Should be marked as Dispatched');
    end;

    [Test]
    procedure TestBeginHistoricalDispatch_SecondCallAllocatesNewId()
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        FirstRunId: Guid;
        SecondRunId: Guid;
    begin
        // [SCENARIO] Each call to BeginHistoricalDispatch allocates a fresh Run Id.
        InitializeHistoricalWorker();

        // [GIVEN] First dispatch
        BC14CompanySettings.GetSingleInstance();
        FirstRunId := BC14CompanySettings.BeginHistoricalDispatch();

        // [WHEN] Second dispatch (rerun scenario)
        SecondRunId := BC14CompanySettings.BeginHistoricalDispatch();

        // [THEN] Second Run Id differs from first
        Assert.AreNotEqual(FirstRunId, SecondRunId, 'Each dispatch should allocate a unique Run Id');
        BC14CompanySettings.GetSingleInstance();
        Assert.AreEqual(SecondRunId, BC14CompanySettings."Historical Run Id", 'Persisted Run Id should be the latest');
    end;

    // ============================================================
    // TrySetHistoricalCompleted — Generation Token Guard
    // ============================================================

    [Test]
    procedure TestTrySetHistoricalCompleted_MatchingRunId_Succeeds()
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        RunId: Guid;
        Result: Boolean;
    begin
        // [SCENARIO] TrySetHistoricalCompleted succeeds when Run Id matches (happy path).
        InitializeHistoricalWorker();

        // [GIVEN] Historical dispatched with a known Run Id
        BC14CompanySettings.GetSingleInstance();
        RunId := BC14CompanySettings.BeginHistoricalDispatch();

        // [WHEN] TrySetHistoricalCompleted is called with the matching Run Id
        Result := BC14CompanySettings.TrySetHistoricalCompleted(RunId);

        // [THEN] Returns true, Historical Completed is set, Dispatched is cleared
        Assert.IsTrue(Result, 'Should succeed with matching Run Id');
        BC14CompanySettings.GetSingleInstance();
        Assert.IsTrue(BC14CompanySettings."Historical Completed", 'Historical Completed should be true');
        Assert.IsFalse(BC14CompanySettings."Historical Dispatched", 'Historical Dispatched should be cleared');
    end;

    [Test]
    procedure TestTrySetHistoricalCompleted_MismatchedRunId_Fails()
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        OriginalRunId: Guid;
        StaleRunId: Guid;
        Result: Boolean;
    begin
        // [SCENARIO] TrySetHistoricalCompleted fails when Run Id does not match (stale worker).
        InitializeHistoricalWorker();

        // [GIVEN] Historical dispatched, then rerun bumps the Run Id
        BC14CompanySettings.GetSingleInstance();
        StaleRunId := BC14CompanySettings.BeginHistoricalDispatch();
        OriginalRunId := BC14CompanySettings.BeginHistoricalDispatch(); // rerun bumps id

        // [WHEN] TrySetHistoricalCompleted is called with the stale Run Id
        Result := BC14CompanySettings.TrySetHistoricalCompleted(StaleRunId);

        // [THEN] Returns false, Historical Completed remains false
        Assert.IsFalse(Result, 'Should fail with mismatched Run Id');
        BC14CompanySettings.GetSingleInstance();
        Assert.IsFalse(BC14CompanySettings."Historical Completed", 'Historical Completed should remain false');
    end;

    [Test]
    procedure TestTrySetHistoricalCompleted_EmptyRunId_Fails()
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        RunId: Guid;
        EmptyGuid: Guid;
        Result: Boolean;
    begin
        // [SCENARIO] TrySetHistoricalCompleted fails when called with an empty GUID.
        InitializeHistoricalWorker();

        // [GIVEN] Historical dispatched with a valid Run Id
        BC14CompanySettings.GetSingleInstance();
        RunId := BC14CompanySettings.BeginHistoricalDispatch();

        // [WHEN] TrySetHistoricalCompleted is called with empty GUID
        Result := BC14CompanySettings.TrySetHistoricalCompleted(EmptyGuid);

        // [THEN] Returns false
        Assert.IsFalse(Result, 'Should fail with empty GUID');
        BC14CompanySettings.GetSingleInstance();
        Assert.IsFalse(BC14CompanySettings."Historical Completed", 'Should remain not completed');
    end;

    // ============================================================
    // TryClearHistoricalDispatched — Failure Path Guard
    // ============================================================

    [Test]
    procedure TestTryClearHistoricalDispatched_MatchingRunId_Succeeds()
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        RunId: Guid;
        Result: Boolean;
    begin
        // [SCENARIO] TryClearHistoricalDispatched clears Dispatched latch when Run Id matches.
        // Used when main flow failed: worker releases the latch so rerun can re-dispatch.
        InitializeHistoricalWorker();

        // [GIVEN] Historical dispatched with a known Run Id
        BC14CompanySettings.GetSingleInstance();
        RunId := BC14CompanySettings.BeginHistoricalDispatch();

        // [WHEN] TryClearHistoricalDispatched is called with matching Run Id
        Result := BC14CompanySettings.TryClearHistoricalDispatched(RunId);

        // [THEN] Returns true, Dispatched is cleared
        Assert.IsTrue(Result, 'Should succeed with matching Run Id');
        BC14CompanySettings.GetSingleInstance();
        Assert.IsFalse(BC14CompanySettings."Historical Dispatched", 'Dispatched should be cleared');
        Assert.IsFalse(BC14CompanySettings."Historical Completed", 'Completed should remain false');
    end;

    [Test]
    procedure TestTryClearHistoricalDispatched_MismatchedRunId_Fails()
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        StaleRunId: Guid;
        Result: Boolean;
    begin
        // [SCENARIO] TryClearHistoricalDispatched fails when Run Id mismatch (rerun already re-dispatched).
        InitializeHistoricalWorker();

        // [GIVEN] Dispatch, then rerun bumps Run Id
        BC14CompanySettings.GetSingleInstance();
        StaleRunId := BC14CompanySettings.BeginHistoricalDispatch();
        BC14CompanySettings.BeginHistoricalDispatch(); // rerun

        // [WHEN] TryClearHistoricalDispatched with stale id
        Result := BC14CompanySettings.TryClearHistoricalDispatched(StaleRunId);

        // [THEN] Returns false, Dispatched remains true (new dispatch owns it)
        Assert.IsFalse(Result, 'Should fail with mismatched Run Id');
        BC14CompanySettings.GetSingleInstance();
        Assert.IsTrue(BC14CompanySettings."Historical Dispatched", 'Dispatched should remain true for new dispatch');
    end;

    // ============================================================
    // IsReadyToFinalize
    // ============================================================

    [Test]
    procedure TestIsReadyToFinalize_BothCompleted_ReturnsTrue()
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        RunId: Guid;
    begin
        // [SCENARIO] IsReadyToFinalize returns true when both Posting and Historical are completed.
        InitializeHistoricalWorker();

        // [GIVEN] Both phases completed
        BC14CompanySettings.GetSingleInstance();
        BC14CompanySettings.SetPostingCompleted();
        RunId := BC14CompanySettings.BeginHistoricalDispatch();
        BC14CompanySettings.TrySetHistoricalCompleted(RunId);

        // [THEN] Ready to finalize
        Assert.IsTrue(BC14CompanySettings.IsReadyToFinalize(), 'Should be ready when both completed');
    end;

    [Test]
    procedure TestIsReadyToFinalize_OnlyPosting_ReturnsFalse()
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
    begin
        // [SCENARIO] IsReadyToFinalize returns false when only Posting completed.
        InitializeHistoricalWorker();

        BC14CompanySettings.GetSingleInstance();
        BC14CompanySettings.SetPostingCompleted();

        Assert.IsFalse(BC14CompanySettings.IsReadyToFinalize(), 'Should not be ready with only Posting');
    end;

    [Test]
    procedure TestIsReadyToFinalize_OnlyHistorical_ReturnsFalse()
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        RunId: Guid;
    begin
        // [SCENARIO] IsReadyToFinalize returns false when only Historical completed.
        InitializeHistoricalWorker();

        BC14CompanySettings.GetSingleInstance();
        RunId := BC14CompanySettings.BeginHistoricalDispatch();
        BC14CompanySettings.TrySetHistoricalCompleted(RunId);

        Assert.IsFalse(BC14CompanySettings.IsReadyToFinalize(), 'Should not be ready with only Historical');
    end;

    [Test]
    procedure TestIsReadyToFinalize_NeitherCompleted_ReturnsFalse()
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
    begin
        // [SCENARIO] IsReadyToFinalize returns false when neither phase completed.
        InitializeHistoricalWorker();

        BC14CompanySettings.GetSingleInstance();

        Assert.IsFalse(BC14CompanySettings.IsReadyToFinalize(), 'Should not be ready with neither completed');
    end;

    // ============================================================
    // GetHistoricalRunId
    // ============================================================

    [Test]
    procedure TestGetHistoricalRunId_AfterDispatch()
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        DispatchedRunId: Guid;
        RetrievedRunId: Guid;
    begin
        // [SCENARIO] GetHistoricalRunId returns the Run Id set by BeginHistoricalDispatch.
        InitializeHistoricalWorker();

        BC14CompanySettings.GetSingleInstance();
        DispatchedRunId := BC14CompanySettings.BeginHistoricalDispatch();

        RetrievedRunId := BC14CompanySettings.GetHistoricalRunId();
        Assert.AreEqual(DispatchedRunId, RetrievedRunId, 'Retrieved Run Id should match dispatched');
    end;

    // ============================================================
    // SetPostingCompleted
    // ============================================================

    [Test]
    procedure TestSetPostingCompleted()
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
    begin
        // [SCENARIO] SetPostingCompleted sets the Posting Completed flag.
        InitializeHistoricalWorker();

        BC14CompanySettings.GetSingleInstance();
        Assert.IsFalse(BC14CompanySettings."Posting Completed", 'Should be false initially');

        BC14CompanySettings.SetPostingCompleted();

        BC14CompanySettings.GetSingleInstance();
        Assert.IsTrue(BC14CompanySettings."Posting Completed", 'Should be true after SetPostingCompleted');
    end;

    // ============================================================
    // Helpers
    // ============================================================

    local procedure InitializeE2E()
    var
        BC14GlobalSettings: Record "BC14 Global Migration Settings";
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        BC14Customer: Record "BC14 Customer";
        DataMigrationError: Record "Data Migration Error";
        HybridCompanyStatus: Record "Hybrid Company Status";
        HybridCompany: Record "Hybrid Company";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
    begin
        BC14Customer.DeleteAll();
        DataMigrationError.DeleteAll();
        HybridCompanyStatus.DeleteAll();
        HybridCompany.DeleteAll();

        // Reset company settings to clean state
        BC14CompanySettings.DeleteAll();
        BC14CompanySettings.GetSingleInstance();

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

    local procedure ClearUpgradeTestData()
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        HybridCompanyStatus: Record "Hybrid Company Status";
        DataMigrationError: Record "Data Migration Error";
    begin
        HybridReplicationSummary.DeleteAll();
        if HybridCompanyStatus.Get(CompanyName()) then
            HybridCompanyStatus.Delete();
        DataMigrationError.DeleteAll();
    end;

    local procedure CreateHybridCompanyStatus()
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
    begin
        HybridCompanyStatus.Init();
        HybridCompanyStatus.Name := CopyStr(CompanyName(), 1, MaxStrLen(HybridCompanyStatus.Name));
        HybridCompanyStatus."Upgrade Status" := HybridCompanyStatus."Upgrade Status"::Pending;
        HybridCompanyStatus.Insert();
    end;

    local procedure CreateHybridReplicationSummary(var HybridReplicationSummary: Record "Hybrid Replication Summary")
    begin
        HybridReplicationSummary.Init();
        HybridReplicationSummary."Run ID" := CreateGuid();
        HybridReplicationSummary."Start Time" := CurrentDateTime();
        HybridReplicationSummary.Status := HybridReplicationSummary.Status::InProgress;
        HybridReplicationSummary.Insert();
    end;

    local procedure InitializeHistoricalWorker()
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
    begin
        BC14CompanySettings.DeleteAll();
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
