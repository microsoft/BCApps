// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration;
using Microsoft.DataMigration.BC14;

codeunit 148916 "BC14 Upgrade Tests"
{
    // [FEATURE] [BC14 Cloud Migration Upgrade]

    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure TestDefaultUpgradeSettings()
    var
        BC14GlobalSettings: Record "BC14 Global Migration Settings";
    begin
        // [SCENARIO] Upgrade settings are initialized with correct default values.

        // [GIVEN] No upgrade settings exist
        if BC14GlobalSettings.Get() then
            BC14GlobalSettings.Delete();

        // [WHEN] GetOrInsertGlobalSettings is called
        BC14GlobalSettings.GetOrInsertGlobalSettings(BC14GlobalSettings);

        // [THEN] Default values are set correctly
        Assert.AreEqual(true, BC14GlobalSettings."One Step Upgrade", 'One Step Upgrade - Should default to true');
        Assert.AreEqual(0DT, BC14GlobalSettings."Data Upgrade Started", 'Data Upgrade Started - Should be empty initially');
        Assert.AreEqual(0DT, BC14GlobalSettings."Replication Completed", 'Replication Completed - Should be empty initially');
        Assert.AreEqual(false, BC14GlobalSettings."Migration In Progress", 'Migration In Progress - Should default to false');
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
    procedure TestSetMigrationInProgress()
    var
        BC14GlobalSettings: Record "BC14 Global Migration Settings";
    begin
        // [SCENARIO] SetMigrationInProgress correctly updates the flag.

        // [GIVEN] Upgrade settings are initialized
        if BC14GlobalSettings.Get() then
            BC14GlobalSettings.Delete();
        BC14GlobalSettings.GetOrInsertGlobalSettings(BC14GlobalSettings);

        // [THEN] Migration In Progress should be false initially
        Assert.AreEqual(false, BC14GlobalSettings."Migration In Progress", 'Migration In Progress - Should be false initially');

        // [WHEN] SetMigrationInProgress is called with true
        BC14GlobalSettings.SetMigrationInProgress(true);

        // [THEN] Migration In Progress should be true
        Clear(BC14GlobalSettings);
        BC14GlobalSettings.Get();
        Assert.AreEqual(true, BC14GlobalSettings."Migration In Progress", 'Migration In Progress - Should be true after enabling');

        // [WHEN] SetMigrationInProgress is called with false
        BC14GlobalSettings.SetMigrationInProgress(false);

        // [THEN] Migration In Progress should be false again
        Clear(BC14GlobalSettings);
        BC14GlobalSettings.Get();
        Assert.AreEqual(false, BC14GlobalSettings."Migration In Progress", 'Migration In Progress - Should be false after disabling');
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
        BC14Management: Codeunit "BC14 Management";
        DefaultTimeout: Duration;
    begin
        // [SCENARIO] GetDefaultJobTimeout returns a valid non-zero default timeout.

        // [WHEN] GetDefaultJobTimeout is called
        DefaultTimeout := BC14Management.GetDefaultJobTimeout();

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
        BC14GlobalSettings.SetMigrationInProgress(false);
        BC14GlobalSettings.Get();
        BC14GlobalSettings.Modify();

        // [THEN] Initial state is clean
        Assert.AreEqual(false, BC14GlobalSettings."Migration In Progress", 'Migration should not be in progress initially');

        // [WHEN] Replication completes
        ReplicationTimestamp := CreateDateTime(Today(), 100000T);
        BC14GlobalSettings."Replication Completed" := ReplicationTimestamp;
        BC14GlobalSettings.Modify();

        // [WHEN] Data upgrade starts
        BC14GlobalSettings.SetMigrationInProgress(true);
        UpgradeTimestamp := CreateDateTime(Today(), 110000T);
        BC14GlobalSettings.Get();
        BC14GlobalSettings."Data Upgrade Started" := UpgradeTimestamp;
        BC14GlobalSettings.Modify();

        // [THEN] All timestamps and flags are set correctly mid-upgrade
        Clear(BC14GlobalSettings);
        BC14GlobalSettings.Get();
        Assert.AreEqual(ReplicationTimestamp, BC14GlobalSettings."Replication Completed", 'Replication timestamp should be preserved');
        Assert.AreEqual(UpgradeTimestamp, BC14GlobalSettings."Data Upgrade Started", 'Upgrade start timestamp should be set');
        Assert.AreEqual(true, BC14GlobalSettings."Migration In Progress", 'Migration should be in progress');

        // [WHEN] Upgrade finishes
        BC14GlobalSettings.SetMigrationInProgress(false);

        // [THEN] Migration is no longer in progress, timestamps remain
        Clear(BC14GlobalSettings);
        BC14GlobalSettings.Get();
        Assert.AreEqual(false, BC14GlobalSettings."Migration In Progress", 'Migration should be complete');
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
        BC14HandleUpgradeError: Codeunit "BC14 Handle Upgrade Error";
    begin
        // [SCENARIO] MarkUpgradeFailed sets the correct status on Hybrid Replication Summary and Hybrid Company Status.

        // [GIVEN] A Hybrid Replication Summary and Company Status records exist
        ClearUpgradeTestData();
        CreateHybridCompanyStatus();
        CreateHybridReplicationSummary(HybridReplicationSummary);

        // [WHEN] MarkUpgradeFailed is called
        BC14HandleUpgradeError.MarkUpgradeFailed(HybridReplicationSummary);

        // [THEN] The status is updated to UpgradeFailed
        HybridReplicationSummary.Get(HybridReplicationSummary."Run ID");
        Assert.AreEqual(HybridReplicationSummary.Status::UpgradeFailed, HybridReplicationSummary.Status, 'Status should be UpgradeFailed');

        HybridCompanyStatus.Get(CompanyName());
        Assert.AreEqual(HybridCompanyStatus."Upgrade Status"::Failed, HybridCompanyStatus."Upgrade Status", 'Upgrade Status should be Failed');
    end;

    [Test]
    procedure TestMarkUpgradeFailed_SetsEndTime()
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        BC14HandleUpgradeError: Codeunit "BC14 Handle Upgrade Error";
        BeforeTime: DateTime;
        AfterTime: DateTime;
    begin
        // [SCENARIO] MarkUpgradeFailed sets the End Time to current timestamp.

        // [GIVEN] A Hybrid Replication Summary exists
        ClearUpgradeTestData();
        CreateHybridCompanyStatus();
        CreateHybridReplicationSummary(HybridReplicationSummary);

        // [WHEN] MarkUpgradeFailed is called
        BeforeTime := CurrentDateTime();
        BC14HandleUpgradeError.MarkUpgradeFailed(HybridReplicationSummary);
        AfterTime := CurrentDateTime();

        // [THEN] The End Time is set to current timestamp
        HybridReplicationSummary.Get(HybridReplicationSummary."Run ID");
        Assert.IsTrue(HybridReplicationSummary."End Time" >= BeforeTime, 'End Time should be >= before time');
        Assert.IsTrue(HybridReplicationSummary."End Time" <= AfterTime, 'End Time should be <= after time');
    end;

    [Test]
    procedure TestMarkUpgradeFailed_IncludesMigrationErrorsInDetails()
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        BC14MigrationErrors: Record "BC14 Migration Errors";
        BC14HandleUpgradeError: Codeunit "BC14 Handle Upgrade Error";
        DetailsInStream: InStream;
        DetailsText: Text;
        DummyRecordId: RecordId;
    begin
        // [SCENARIO] MarkUpgradeFailed includes migration errors in the Details field.

        // [GIVEN] A Hybrid Replication Summary and migration errors exist
        ClearUpgradeTestData();
        CreateHybridCompanyStatus();
        CreateHybridReplicationSummary(HybridReplicationSummary);

        // Insert a migration error
        BC14MigrationErrors.Init();
        BC14MigrationErrors."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(BC14MigrationErrors."Company Name"));
        BC14MigrationErrors."Source Table ID" := 1000;
        BC14MigrationErrors."Source Table Name" := 'Test Table';
        BC14MigrationErrors."Source Record Key" := 'TEST-001';
        BC14MigrationErrors."Migration Type" := 'Test Migrator';
        BC14MigrationErrors."Error Message" := 'Test error message';
        BC14MigrationErrors."Resolved" := false;
        BC14MigrationErrors."Record Id" := DummyRecordId;
        BC14MigrationErrors.Insert();

        // [WHEN] MarkUpgradeFailed is called
        BC14HandleUpgradeError.MarkUpgradeFailed(HybridReplicationSummary);

        // [THEN] The Details field contains error information
        HybridReplicationSummary.Get(HybridReplicationSummary."Run ID");
        HybridReplicationSummary.CalcFields(Details);
        HybridReplicationSummary.Details.CreateInStream(DetailsInStream);
        DetailsInStream.Read(DetailsText);
        Assert.IsTrue(StrPos(DetailsText, 'Test error message') > 0, 'Details should contain error message');
    end;

    local procedure ClearUpgradeTestData()
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        HybridCompanyStatus: Record "Hybrid Company Status";
        BC14MigrationErrors: Record "BC14 Migration Errors";
    begin
        HybridReplicationSummary.DeleteAll();
        if HybridCompanyStatus.Get(CompanyName()) then
            HybridCompanyStatus.Delete();
        BC14MigrationErrors.SetRange("Company Name", CompanyName());
        BC14MigrationErrors.DeleteAll();
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
}
