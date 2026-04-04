// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration.BC14;
using Microsoft.Purchases.Vendor;

codeunit 148917 "BC14 Vendor Migration Tests"
{
    // [FEATURE] [BC14 Cloud Migration Vendor Upgrade]

    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure TestVendorMigrationTransfersAllFields()
    var
        BC14Vendor: Record "BC14 Vendor";
        Vendor: Record Vendor;
        BC14VendorMigrator: Codeunit "BC14 Vendor Migrator";
    begin
        // [SCENARIO] All standard fields are correctly migrated from BC14 Vendor buffer to Vendor table.

        // [GIVEN] A complete Vendor record exists in the buffer table
        CleanupTestData();
        EnablePayablesModule();

        BC14Vendor.Init();
        BC14Vendor."No." := 'VEND-TEST-001';
        BC14Vendor.Name := 'Test Vendor';
        BC14Vendor.Address := '456 Vendor Ave';
        BC14Vendor."Address 2" := 'Floor 5';
        BC14Vendor.City := 'Redmond';
        BC14Vendor."Phone No." := '555-5678';
        BC14Vendor.Insert();

        // [WHEN] The Vendor Migrator runs the migration
        BC14VendorMigrator.MigrateVendor(BC14Vendor);

        // [THEN] Migration succeeds and all field values in the Vendor table match the buffer
        Assert.IsTrue(Vendor.Get('VEND-TEST-001'), 'Vendor record should exist after migration');

        Assert.AreEqual('Test Vendor', Vendor.Name, 'Name should match');
        Assert.AreEqual('456 Vendor Ave', Vendor.Address, 'Address should match');
        Assert.AreEqual('Floor 5', Vendor."Address 2", 'Address 2 should match');
        Assert.AreEqual('Redmond', Vendor.City, 'City should match');
        Assert.AreEqual('555-5678', Vendor."Phone No.", 'Phone No. should match');
    end;

    [Test]
    procedure TestVendorMigrationMultipleVendors()
    var
        BC14Vendor: Record "BC14 Vendor";
        Vendor: Record Vendor;
        BC14VendorMigrator: Codeunit "BC14 Vendor Migrator";
    begin
        // [SCENARIO] Multiple vendors in the buffer table are all migrated successfully.

        // [GIVEN] 3 Vendor records exist in the buffer table
        CleanupTestData();
        EnablePayablesModule();

        InsertBC14Vendor('VEND-A', 'Vendor Alpha', '100 Alpha St');
        InsertBC14Vendor('VEND-B', 'Vendor Beta', '200 Beta Blvd');
        InsertBC14Vendor('VEND-C', 'Vendor Gamma', '300 Gamma Way');

        // [WHEN] The Vendor Migrator runs the migration for each vendor
        BC14Vendor.FindSet();
        repeat
            BC14VendorMigrator.MigrateVendor(BC14Vendor);
        until BC14Vendor.Next() = 0;

        // [THEN] All 3 records are migrated successfully
        Assert.IsTrue(Vendor.Get('VEND-A'), 'Vendor A should exist after migration');
        Assert.AreEqual('Vendor Alpha', Vendor.Name, 'Vendor A Name should match');

        Assert.IsTrue(Vendor.Get('VEND-B'), 'Vendor B should exist after migration');
        Assert.AreEqual('Vendor Beta', Vendor.Name, 'Vendor B Name should match');

        Assert.IsTrue(Vendor.Get('VEND-C'), 'Vendor C should exist after migration');
        Assert.AreEqual('Vendor Gamma', Vendor.Name, 'Vendor C Name should match');
    end;

    [Test]
    procedure TestVendorMigrationUpdatesExistingVendor()
    var
        BC14Vendor: Record "BC14 Vendor";
        Vendor: Record Vendor;
        BC14VendorMigrator: Codeunit "BC14 Vendor Migrator";
    begin
        // [SCENARIO] If a Vendor with the same No. already exists, migration should update it rather than insert a duplicate.

        // [GIVEN] A Vendor record already exists in the Vendor table
        CleanupTestData();
        EnablePayablesModule();

        Vendor.Init();
        Vendor."No." := 'VEND-EXISTING';
        Vendor.Name := 'Old Vendor Name';
        Vendor.Insert();

        // [GIVEN] The buffer table has a record with the same No. but different field values
        BC14Vendor.Init();
        BC14Vendor."No." := 'VEND-EXISTING';
        BC14Vendor.Name := 'Updated Vendor Name';
        BC14Vendor.Address := 'New Address';
        BC14Vendor.Insert();

        // [WHEN] The Vendor Migrator runs the migration
        BC14VendorMigrator.MigrateVendor(BC14Vendor);

        // [THEN] The existing record is updated
        Vendor.Get('VEND-EXISTING');
        Assert.AreEqual('Updated Vendor Name', Vendor.Name, 'Name should be updated');
        Assert.AreEqual('New Address', Vendor.Address, 'Address should be updated');
    end;

    [Test]
    procedure TestVendorMigratorIsDisabledWhenModuleDisabled()
    var
        BC14CompanyMigrationSettings: Record "BC14CompanyMigrationSettings";
        BC14VendorMigrator: Codeunit "BC14 Vendor Migrator";
    begin
        // [SCENARIO] Vendor Migrator reports disabled when the Payables module is disabled.

        // [GIVEN] The Payables module is disabled
        BC14CompanyMigrationSettings.DeleteAll();
        BC14CompanyMigrationSettings.GetSingleInstance();
        BC14CompanyMigrationSettings.Validate("Migrate Payables Module", false);
        BC14CompanyMigrationSettings.Modify();

        // [THEN] IsEnabled should return false
        Assert.IsFalse(BC14VendorMigrator.IsEnabled(), 'Vendor Migrator should be disabled when Payables module is disabled');
    end;

    [Test]
    procedure TestVendorMigrationRecordCount()
    var
        BC14VendorMigrator: Codeunit "BC14 Vendor Migrator";
    begin
        // [SCENARIO] GetRecordCount returns the number of records in the buffer table.

        // [GIVEN] 2 records exist in the buffer table
        CleanupTestData();

        InsertBC14Vendor('VEND-CNT-1', 'Count Vendor 1', 'Address 1');
        InsertBC14Vendor('VEND-CNT-2', 'Count Vendor 2', 'Address 2');

        // [THEN] GetRecordCount should return 2
        Assert.AreEqual(2, BC14VendorMigrator.GetRecordCount(), 'GetRecordCount should return the number of BC14 Vendor records');
    end;

    [Test]
    procedure TestVendorMigratorIsEnabledByDefault()
    var
        BC14CompanyMigrationSettings: Record "BC14CompanyMigrationSettings";
        BC14VendorMigrator: Codeunit "BC14 Vendor Migrator";
    begin
        // [SCENARIO] The Vendor Migrator is enabled by default.

        // [GIVEN] Default settings are used
        BC14CompanyMigrationSettings.DeleteAll();

        // [THEN] IsEnabled should return true
        Assert.IsTrue(BC14VendorMigrator.IsEnabled(), 'Vendor Migrator should be enabled by default');
    end;

    [Test]
    procedure TestVendorMigratorName()
    var
        BC14VendorMigrator: Codeunit "BC14 Vendor Migrator";
    begin
        // [SCENARIO] GetName returns the correct migrator name.

        // [THEN] The name should be 'Vendor Migrator'
        Assert.AreEqual('Vendor Migrator', BC14VendorMigrator.GetName(), 'Migrator name should be Vendor Migrator');
    end;

    [Test]
    procedure TestVendorMigratorSourceTableId()
    var
        BC14VendorMigrator: Codeunit "BC14 Vendor Migrator";
    begin
        // [SCENARIO] GetSourceTableId returns the correct buffer table ID.

        // [THEN] The source table ID should be BC14 Vendor
        Assert.AreEqual(Database::"BC14 Vendor", BC14VendorMigrator.GetSourceTableId(), 'Source table ID should be BC14 Vendor');
    end;

    [Test]
    procedure TestVendorMigratorGetSourceRecordKey()
    var
        BC14Vendor: Record "BC14 Vendor";
        BC14VendorMigrator: Codeunit "BC14 Vendor Migrator";
        SourceRecordRef: RecordRef;
    begin
        // [SCENARIO] GetSourceRecordKey returns the Vendor No. as the record key.

        // [GIVEN] A vendor exists in the buffer table
        CleanupTestData();
        InsertBC14Vendor('VEND-KEY-TEST', 'Test Vendor', 'Test Address');

        // [WHEN] GetSourceRecordKey is called
        BC14Vendor.Get('VEND-KEY-TEST');
        SourceRecordRef.GetTable(BC14Vendor);

        // [THEN] The record key is the Vendor No.
        Assert.AreEqual('VEND-KEY-TEST', BC14VendorMigrator.GetSourceRecordKey(SourceRecordRef), 'Record key should be the Vendor No.');
        SourceRecordRef.Close();
    end;

    [Test]
    procedure TestVendorMigrationBlockedVendor()
    var
        BC14Vendor: Record "BC14 Vendor";
        Vendor: Record Vendor;
        BC14VendorMigrator: Codeunit "BC14 Vendor Migrator";
    begin
        // [SCENARIO] Blocked status is correctly migrated.

        // [GIVEN] A blocked Vendor record exists in the buffer table
        CleanupTestData();
        EnablePayablesModule();

        BC14Vendor.Init();
        BC14Vendor."No." := 'VEND-BLOCKED';
        BC14Vendor.Name := 'Blocked Vendor';
        BC14Vendor.Blocked := BC14Vendor.Blocked::All;
        BC14Vendor.Insert();

        // [WHEN] The Vendor Migrator runs the migration
        BC14VendorMigrator.MigrateVendor(BC14Vendor);

        // [THEN] The blocked status is preserved
        Assert.IsTrue(Vendor.Get('VEND-BLOCKED'), 'Vendor record should exist after migration');
        Assert.AreEqual(Vendor.Blocked::All, Vendor.Blocked, 'Blocked status should be All');
    end;

    local procedure CleanupTestData()
    var
        BC14Vendor: Record "BC14 Vendor";
        Vendor: Record Vendor;
    begin
        BC14Vendor.DeleteAll();

        Vendor.SetFilter("No.", 'VEND-*');
        Vendor.DeleteAll();
    end;

    local procedure EnablePayablesModule()
    var
        BC14CompanyMigrationSettings: Record "BC14CompanyMigrationSettings";
    begin
        BC14CompanyMigrationSettings.DeleteAll();
        BC14CompanyMigrationSettings.GetSingleInstance();
        BC14CompanyMigrationSettings.Validate("Migrate Payables Module", true);
        BC14CompanyMigrationSettings.Modify();
    end;

    local procedure InsertBC14Vendor(VendorNo: Code[20]; VendorName: Text[100]; VendorAddress: Text[100])
    var
        BC14Vendor: Record "BC14 Vendor";
    begin
        BC14Vendor.Init();
        BC14Vendor."No." := VendorNo;
        BC14Vendor.Name := VendorName;
        BC14Vendor.Address := VendorAddress;
        BC14Vendor.Insert();
    end;
}
