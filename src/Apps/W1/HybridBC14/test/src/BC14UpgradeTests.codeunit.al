// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration.BC14;

codeunit 148144 "BC14 Upgrade Tests"
{
    // [FEATURE] [BC14 Cloud Migration Upgrade]

    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure TestDefaultUpgradeSettings()
    var
        BC14UpgradeSettings: Record "BC14 Upgrade Settings";
    begin
        // [SCENARIO] Upgrade settings are initialized with correct default values.

        // [GIVEN] No upgrade settings exist
        if BC14UpgradeSettings.Get() then
            BC14UpgradeSettings.Delete();

        // [WHEN] GetOrInsertBC14UpgradeSettings is called
        BC14UpgradeSettings.GetOrInsertBC14UpgradeSettings(BC14UpgradeSettings);

        // [THEN] Default values are set correctly
        Assert.AreEqual(true, BC14UpgradeSettings."Collect All Errors", 'Collect All Errors - Should default to true');
        Assert.AreEqual(true, BC14UpgradeSettings."One Step Upgrade", 'One Step Upgrade - Should default to true');
        Assert.AreEqual(0DT, BC14UpgradeSettings."Data Upgrade Started", 'Data Upgrade Started - Should be empty initially');
        Assert.AreEqual(0DT, BC14UpgradeSettings."Replication Completed", 'Replication Completed - Should be empty initially');
        Assert.AreEqual(false, BC14UpgradeSettings."Migration In Progress", 'Migration In Progress - Should default to false');
    end;

    [Test]
    procedure TestGetOrInsertIsIdempotent()
    var
        BC14UpgradeSettings: Record "BC14 Upgrade Settings";
    begin
        // [SCENARIO] Calling GetOrInsertBC14UpgradeSettings multiple times does not create duplicate records.

        // [GIVEN] No upgrade settings exist
        if BC14UpgradeSettings.Get() then
            BC14UpgradeSettings.Delete();

        // [WHEN] GetOrInsertBC14UpgradeSettings is called twice
        BC14UpgradeSettings.GetOrInsertBC14UpgradeSettings(BC14UpgradeSettings);
        BC14UpgradeSettings."Collect All Errors" := false;
        BC14UpgradeSettings.Modify();

        // [THEN] The second call returns the existing record, not a new one
        Clear(BC14UpgradeSettings);
        BC14UpgradeSettings.GetOrInsertBC14UpgradeSettings(BC14UpgradeSettings);
        Assert.AreEqual(false, BC14UpgradeSettings."Collect All Errors", 'Second call should return the modified record, not create a new one');
    end;

    [Test]
    procedure TestSetMigrationInProgress()
    var
        BC14UpgradeSettings: Record "BC14 Upgrade Settings";
    begin
        // [SCENARIO] SetMigrationInProgress correctly updates the flag.

        // [GIVEN] Upgrade settings are initialized
        if BC14UpgradeSettings.Get() then
            BC14UpgradeSettings.Delete();
        BC14UpgradeSettings.GetOrInsertBC14UpgradeSettings(BC14UpgradeSettings);

        // [THEN] Migration In Progress should be false initially
        Assert.AreEqual(false, BC14UpgradeSettings."Migration In Progress", 'Migration In Progress - Should be false initially');

        // [WHEN] SetMigrationInProgress is called with true
        BC14UpgradeSettings.SetMigrationInProgress(true);

        // [THEN] Migration In Progress should be true
        Clear(BC14UpgradeSettings);
        BC14UpgradeSettings.Get();
        Assert.AreEqual(true, BC14UpgradeSettings."Migration In Progress", 'Migration In Progress - Should be true after enabling');

        // [WHEN] SetMigrationInProgress is called with false
        BC14UpgradeSettings.SetMigrationInProgress(false);

        // [THEN] Migration In Progress should be false again
        Clear(BC14UpgradeSettings);
        BC14UpgradeSettings.Get();
        Assert.AreEqual(false, BC14UpgradeSettings."Migration In Progress", 'Migration In Progress - Should be false after disabling');
    end;

    [Test]
    procedure TestUpgradeDelayIsCorrect()
    var
        BC14UpgradeSettings: Record "BC14 Upgrade Settings";
        ExpectedDelay: Duration;
    begin
        // [SCENARIO] The upgrade delay is set to the expected default value.

        // [GIVEN] A fresh upgrade settings record
        if BC14UpgradeSettings.Get() then
            BC14UpgradeSettings.Delete();
        BC14UpgradeSettings.GetOrInsertBC14UpgradeSettings(BC14UpgradeSettings);

        // [THEN] The delay should be 30 seconds
        ExpectedDelay := 30 * 1000;
        Assert.AreEqual(ExpectedDelay, BC14UpgradeSettings.GetUpgradeDelay(), 'Upgrade delay should be 30 seconds');
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
        BC14UpgradeSettings: Record "BC14 Upgrade Settings";
        CustomDelay: Duration;
    begin
        // [SCENARIO] When One Step Upgrade is enabled with a custom delay, both settings are persisted together.

        // [GIVEN] Upgrade settings are initialized
        if BC14UpgradeSettings.Get() then
            BC14UpgradeSettings.Delete();
        BC14UpgradeSettings.GetOrInsertBC14UpgradeSettings(BC14UpgradeSettings);

        // [WHEN] One Step Upgrade is enabled and a custom delay is set
        BC14UpgradeSettings."One Step Upgrade" := true;
        CustomDelay := 45 * 1000;
        BC14UpgradeSettings."One Step Upgrade Delay" := CustomDelay;
        BC14UpgradeSettings.Modify();

        // [THEN] Both settings are persisted correctly
        Clear(BC14UpgradeSettings);
        BC14UpgradeSettings.Get();
        Assert.AreEqual(true, BC14UpgradeSettings."One Step Upgrade", 'One Step Upgrade should be enabled');
        Assert.AreEqual(CustomDelay, BC14UpgradeSettings."One Step Upgrade Delay", 'Custom delay should be persisted');
    end;

    [Test]
    procedure TestUpgradeSettingsFullLifecycle()
    var
        BC14UpgradeSettings: Record "BC14 Upgrade Settings";
        ReplicationTimestamp: DateTime;
        UpgradeTimestamp: DateTime;
    begin
        // [SCENARIO] Full upgrade lifecycle: replication completes, upgrade starts, upgrade finishes.

        // [GIVEN] Upgrade settings are initialized with defaults
        if BC14UpgradeSettings.Get() then
            BC14UpgradeSettings.Delete();
        BC14UpgradeSettings.GetOrInsertBC14UpgradeSettings(BC14UpgradeSettings);
        BC14UpgradeSettings."Replication Completed" := 0DT;
        BC14UpgradeSettings."Data Upgrade Started" := 0DT;
        BC14UpgradeSettings.SetMigrationInProgress(false);
        BC14UpgradeSettings.Get();
        BC14UpgradeSettings.Modify();

        // [THEN] Initial state is clean
        Assert.AreEqual(false, BC14UpgradeSettings."Migration In Progress", 'Migration should not be in progress initially');

        // [WHEN] Replication completes
        ReplicationTimestamp := CreateDateTime(Today(), 100000T);
        BC14UpgradeSettings."Replication Completed" := ReplicationTimestamp;
        BC14UpgradeSettings.Modify();

        // [WHEN] Data upgrade starts
        BC14UpgradeSettings.SetMigrationInProgress(true);
        UpgradeTimestamp := CreateDateTime(Today(), 110000T);
        BC14UpgradeSettings.Get();
        BC14UpgradeSettings."Data Upgrade Started" := UpgradeTimestamp;
        BC14UpgradeSettings.Modify();

        // [THEN] All timestamps and flags are set correctly mid-upgrade
        Clear(BC14UpgradeSettings);
        BC14UpgradeSettings.Get();
        Assert.AreEqual(ReplicationTimestamp, BC14UpgradeSettings."Replication Completed", 'Replication timestamp should be preserved');
        Assert.AreEqual(UpgradeTimestamp, BC14UpgradeSettings."Data Upgrade Started", 'Upgrade start timestamp should be set');
        Assert.AreEqual(true, BC14UpgradeSettings."Migration In Progress", 'Migration should be in progress');

        // [WHEN] Upgrade finishes
        BC14UpgradeSettings.SetMigrationInProgress(false);

        // [THEN] Migration is no longer in progress, timestamps remain
        Clear(BC14UpgradeSettings);
        BC14UpgradeSettings.Get();
        Assert.AreEqual(false, BC14UpgradeSettings."Migration In Progress", 'Migration should be complete');
        Assert.AreEqual(ReplicationTimestamp, BC14UpgradeSettings."Replication Completed", 'Replication timestamp should still be preserved');
        Assert.AreEqual(UpgradeTimestamp, BC14UpgradeSettings."Data Upgrade Started", 'Upgrade start timestamp should still be preserved');
    end;

    [Test]
    procedure TestGetUpgradeDelayReturnsDefaultWhenOneStepDisabled()
    var
        BC14UpgradeSettings: Record "BC14 Upgrade Settings";
        DefaultDelay: Duration;
        CustomDelay: Duration;
    begin
        // [SCENARIO] GetUpgradeDelay returns the default delay when One Step Upgrade is disabled, regardless of custom delay value.

        // [GIVEN] Upgrade settings with custom delay
        if BC14UpgradeSettings.Get() then
            BC14UpgradeSettings.Delete();
        BC14UpgradeSettings.GetOrInsertBC14UpgradeSettings(BC14UpgradeSettings);
        DefaultDelay := BC14UpgradeSettings.GetUpgradeDelay();

        CustomDelay := 90 * 1000;
        BC14UpgradeSettings."One Step Upgrade Delay" := CustomDelay;
        BC14UpgradeSettings.Modify();

        // [WHEN] One Step Upgrade is disabled
        BC14UpgradeSettings."One Step Upgrade" := false;
        BC14UpgradeSettings.Modify();

        // [THEN] The default upgrade delay from GetUpgradeDelay is unchanged
        Clear(BC14UpgradeSettings);
        BC14UpgradeSettings.Get();
        Assert.AreEqual(false, BC14UpgradeSettings."One Step Upgrade", 'One Step Upgrade should be disabled');
        Assert.AreEqual(DefaultDelay, BC14UpgradeSettings.GetUpgradeDelay(), 'GetUpgradeDelay should return default delay');
        Assert.AreEqual(CustomDelay, BC14UpgradeSettings."One Step Upgrade Delay", 'Custom delay should still be stored');
    end;
}
