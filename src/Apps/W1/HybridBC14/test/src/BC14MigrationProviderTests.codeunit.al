// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration;
using Microsoft.DataMigration.BC14;

codeunit 148148 "BC14 Migration Provider Tests"
{
    // [FEATURE] [BC14 Cloud Migration Provider / Table Mapping]

    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure TestReplicationTableMappingsAreCreated()
    var
        ReplicationMapping: Record "Replication Table Mapping";
        HybridCompany: Record "Hybrid Company";
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        // [SCENARIO] Replication table mappings are created for all replicated companies.

        // [GIVEN] A company is marked for replication
        HybridCompany.DeleteAll();
        ReplicationMapping.DeleteAll();

        HybridCompany.Init();
        HybridCompany.Name := CopyStr(CompanyName(), 1, MaxStrLen(HybridCompany.Name));
        HybridCompany."Display Name" := HybridCompany.Name;
        HybridCompany.Replicate := true;
        HybridCompany.Insert();

        // [WHEN] SetupReplicationTableMappings is called
        BC14MigrationSetup.SetupReplicationTableMappings();

        // [THEN] Mappings are created for master, transaction, and historical tables
        // Master Data: Customer, Item, Vendor, G/L Account
        // Transaction: G/L Entry
        // Historical: Sales Invoice Header, Sales Invoice Line
        // Per-database: Tenant Media
        // Total per-company = 7, per-database = 1
        ReplicationMapping.SetFilter("Company Name", '<>''''');
        Assert.AreEqual(7, ReplicationMapping.Count(), 'Should have 7 per-company replication mappings (4 master + 1 transaction + 2 historical)');

        ReplicationMapping.SetRange("Company Name", '');
        Assert.AreEqual(1, ReplicationMapping.Count(), 'Should have 1 per-database replication mapping (Tenant Media)');
    end;

    [Test]
    procedure TestSetupTableMappingsAreCreated()
    var
        ReplicationMapping: Record "Replication Table Mapping";
        HybridCompany: Record "Hybrid Company";
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        // [SCENARIO] Migration setup table mappings are created for all replicated companies.

        // [GIVEN] A company is marked for replication
        HybridCompany.DeleteAll();
        ReplicationMapping.DeleteAll();

        HybridCompany.Init();
        HybridCompany.Name := CopyStr(CompanyName(), 1, MaxStrLen(HybridCompany.Name));
        HybridCompany."Display Name" := HybridCompany.Name;
        HybridCompany.Replicate := true;
        HybridCompany.Insert();

        // [WHEN] SetupMigrationSetupTableMappings is called
        BC14MigrationSetup.SetupMigrationSetupTableMappings();

        // [THEN] Mappings are created for setup tables
        // Setup: Dimension, Dimension Value, Payment TerMicrosoft, Payment Method, Currency, Currency Exchange Rate, Accounting Period
        ReplicationMapping.SetFilter("Company Name", '<>''''');
        Assert.AreEqual(7, ReplicationMapping.Count(), 'Should have 7 per-company setup mappings');
    end;

    [Test]
    procedure TestMappingsCreatedForMultipleCompanies()
    var
        ReplicationMapping: Record "Replication Table Mapping";
        HybridCompany: Record "Hybrid Company";
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        // [SCENARIO] Table mappings are created for multiple replicated companies.

        // [GIVEN] Two companies are marked for replication
        HybridCompany.DeleteAll();
        ReplicationMapping.DeleteAll();

        HybridCompany.Init();
        HybridCompany.Name := 'Company A';
        HybridCompany."Display Name" := HybridCompany.Name;
        HybridCompany.Replicate := true;
        HybridCompany.Insert();

        HybridCompany.Init();
        HybridCompany.Name := 'Company B';
        HybridCompany."Display Name" := HybridCompany.Name;
        HybridCompany.Replicate := true;
        HybridCompany.Insert();

        // [WHEN] SetupReplicationTableMappings is called
        BC14MigrationSetup.SetupReplicationTableMappings();

        // [THEN] Each company gets its own mappings (7 per company + 1 per-database)
        ReplicationMapping.SetRange("Company Name", 'Company A');
        Assert.AreEqual(7, ReplicationMapping.Count(), 'Company A should have 7 replication mappings');

        ReplicationMapping.SetRange("Company Name", 'Company B');
        Assert.AreEqual(7, ReplicationMapping.Count(), 'Company B should have 7 replication mappings');
    end;

    [Test]
    procedure TestNonReplicatedCompaniesAreSkipped()
    var
        ReplicationMapping: Record "Replication Table Mapping";
        HybridCompany: Record "Hybrid Company";
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        // [SCENARIO] Companies not marked for replication are skipped.

        // [GIVEN] One company is replicated, one is not
        HybridCompany.DeleteAll();
        ReplicationMapping.DeleteAll();

        HybridCompany.Init();
        HybridCompany.Name := 'ReplicateMe';
        HybridCompany."Display Name" := HybridCompany.Name;
        HybridCompany.Replicate := true;
        HybridCompany.Insert();

        HybridCompany.Init();
        HybridCompany.Name := 'SkipMe';
        HybridCompany."Display Name" := HybridCompany.Name;
        HybridCompany.Replicate := false;
        HybridCompany.Insert();

        // [WHEN] SetupReplicationTableMappings is called
        BC14MigrationSetup.SetupReplicationTableMappings();

        // [THEN] Only the replicated company has mappings
        ReplicationMapping.SetRange("Company Name", 'ReplicateMe');
        Assert.AreEqual(7, ReplicationMapping.Count(), 'ReplicateMe should have 7 mappings');

        ReplicationMapping.SetRange("Company Name", 'SkipMe');
        Assert.AreEqual(0, ReplicationMapping.Count(), 'SkipMe should have 0 mappings');
    end;

    [Test]
    procedure TestMigrationProviderDisplayName()
    var
        BC14MigrationProvider: Codeunit "BC14 Migration Provider";
    begin
        // [SCENARIO] The migration provider returns the correct display name.

        // [THEN] The display name should be 'Business Central 14 Re-implementation'
        Assert.AreEqual('Business Central 14 Re-implementation', BC14MigrationProvider.GetDisplayName(), 'Display name should match the expected value');
    end;

    [Test]
    procedure TestMigrationProviderDescription()
    var
        BC14MigrationProvider: Codeunit "BC14 Migration Provider";
        Description: Text;
    begin
        // [SCENARIO] The migration provider returns a meaningful description.

        // [WHEN] GetDescription is called
        Description := BC14MigrationProvider.GetDescription();

        // [THEN] The description is not empty and contains key terms
        Assert.AreNotEqual('', Description, 'Description should not be empty');
        Assert.IsTrue(Description.Contains('Business Central 14'), 'Description should mention Business Central 14');
        Assert.IsTrue(Description.Contains('re-implementation'), 'Description should mention re-implementation');
    end;

    [Test]
    procedure TestMigrationProviderAppId()
    var
        BC14MigrationProvider: Codeunit "BC14 Migration Provider";
        AppId: Guid;
        ExpectedAppId: Guid;
    begin
        // [SCENARIO] The migration provider returns the correct AppId.

        // [WHEN] GetAppId is called
        AppId := BC14MigrationProvider.GetAppId();

        // [THEN] The AppId matches the BC14 Reimplementation Tool app ID
        Evaluate(ExpectedAppId, '2363a2b7-1018-4976-a32a-c77338dc9f16');
        Assert.AreEqual(ExpectedAppId, AppId, 'AppId should match the BC14 Reimplementation Tool app ID');
    end;

    [Test]
    procedure TestShowConfigureMigrationTablesMappingStep()
    var
        BC14MigrationProvider: Codeunit "BC14 Migration Provider";
    begin
        // [SCENARIO] ShowConfigureMigrationTablesMappingStep returns false for BC14.

        // [THEN] The step should not be shown
        Assert.IsFalse(BC14MigrationProvider.ShowConfigureMigrationTablesMappingStep(), 'Should not show configure migration tables mapping step');
    end;
}
