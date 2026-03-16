// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration;
using Microsoft.DataMigration.BC14;
using System.Security.AccessControl;
using System.TestLibraries.Environment;
codeunit 148151 "BC14 Wizard Tests"
{
    // [FEATURE] [BC14 Cloud Migration Wizard]

    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        BC14TestHelperFunctions: Codeunit "BC14 Helper Function Tests";

    [Test]
    procedure TestGetMigrationProviderId()
    var
        BC14Wizard: Codeunit "BC14 Wizard";
    begin
        // [SCENARIO] GetMigrationProviderId returns the expected provider ID.

        // [THEN] The provider ID is correct
        Assert.AreEqual('50150-BC14Re-Implementation', BC14Wizard.GetMigrationProviderId(), 'Migration Provider ID is incorrect');
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
        BC14CompanyAdditionalSettings: Record "BC14CompanyAdditionalSettings";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        PermissionManager: Codeunit "Permission Manager";
    begin
        // [SCENARIO] Processes are not running by default.

        // [GIVEN] BC14 is set up, and company settings are reset
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        PermissionManager.SetTestabilityIntelligentCloud(true);
        BC14TestHelperFunctions.CreateStandardSetupRecords();
        BC14CompanyAdditionalSettings.DeleteAll();

        // [WHEN] A new company settings record is created
        BC14CompanyAdditionalSettings.GetSingleInstance();

        // [THEN] ProcessesAreRunning should be false
        Assert.AreEqual(false, BC14CompanyAdditionalSettings.ProcessesAreRunning, 'ProcessesAreRunning should default to false');
    end;

    [Test]
    procedure TestCleanupMigrationData()
    var
        BC14CompanyAdditionalSettings: Record "BC14CompanyAdditionalSettings";
        BC14UpgradeSettings: Record "BC14 Upgrade Settings";
        BC14MigrationErrorOverview: Record "BC14 Migration Error Overview";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        PermissionManager: Codeunit "Permission Manager";
    begin
        // [SCENARIO] CleanupMigrationData clears all BC14 migration-related data.

        // [GIVEN] BC14 migration is set up with data
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        PermissionManager.SetTestabilityIntelligentCloud(true);
        BC14TestHelperFunctions.CreateStandardSetupRecords();
        BC14TestHelperFunctions.CreateConfigurationSettings();

        Assert.IsFalse(BC14CompanyAdditionalSettings.IsEmpty(), 'BC14CompanyAdditionalSettings should have data before cleanup');

        // [WHEN] CleanupMigrationData is called
        BC14TestHelperFunctions.CleanupMigrationData();

        // [THEN] All BC14 migration data is cleared
        Assert.IsTrue(BC14CompanyAdditionalSettings.IsEmpty(), 'BC14CompanyAdditionalSettings should be empty after cleanup');
        Assert.IsTrue(BC14MigrationErrorOverview.IsEmpty(), 'BC14 Migration Error Overview should be empty after cleanup');
        Assert.IsFalse(BC14UpgradeSettings.Get(), 'BC14 Upgrade Settings should not exist after cleanup');
    end;
}
