// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration.BC14;
using Microsoft.Sales.Customer;

codeunit 148903 "BC14 Customer Migration Tests"
{
    // [FEATURE] [BC14 Cloud Migration Customer Upgrade]

    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure TestCustomerMigrationTransfersAllFields()
    var
        BC14Customer: Record "BC14 Customer";
        Customer: Record Customer;
        BC14CustomerMigrator: Codeunit "BC14 Customer Migrator";
    begin
        // [SCENARIO] All standard fields are correctly migrated from BC14 Customer buffer to Customer table.

        // [GIVEN] A complete Customer record exists in the buffer table
        CleanupTestData();
        EnableReceivablesModule();

        BC14Customer.Init();
        BC14Customer."No." := 'CUST-TEST-001';
        BC14Customer.Name := 'Test Customer';
        BC14Customer.Address := '123 Main Street';
        BC14Customer."Address 2" := 'Suite 100';
        BC14Customer.City := 'Seattle';
        BC14Customer."Phone No." := '555-1234';
        BC14Customer."Credit Limit (LCY)" := 10000;
        BC14Customer.Insert();

        // [WHEN] The Customer Migrator runs the migration
        BC14CustomerMigrator.MigrateCustomer(BC14Customer);

        // [THEN] Migration succeeds and all field values in the Customer table match the buffer
        Assert.IsTrue(Customer.Get('CUST-TEST-001'), 'Customer record should exist after migration');

        Assert.AreEqual('Test Customer', Customer.Name, 'Name should match');
        Assert.AreEqual('123 Main Street', Customer.Address, 'Address should match');
        Assert.AreEqual('Suite 100', Customer."Address 2", 'Address 2 should match');
        Assert.AreEqual('Seattle', Customer.City, 'City should match');
        Assert.AreEqual('555-1234', Customer."Phone No.", 'Phone No. should match');
        Assert.AreEqual(10000, Customer."Credit Limit (LCY)", 'Credit Limit (LCY) should match');
    end;

    [Test]
    procedure TestCustomerMigrationMultipleCustomers()
    var
        BC14Customer: Record "BC14 Customer";
        Customer: Record Customer;
        BC14CustomerMigrator: Codeunit "BC14 Customer Migrator";
    begin
        // [SCENARIO] Multiple customers in the buffer table are all migrated successfully.

        // [GIVEN] 3 Customer records exist in the buffer table
        CleanupTestData();
        EnableReceivablesModule();

        InsertBC14Customer('CUST-A', 'Customer Alpha', '100 Alpha Rd', 10000);
        InsertBC14Customer('CUST-B', 'Customer Beta', '200 Beta Ave', 20000);
        InsertBC14Customer('CUST-C', 'Customer Gamma', '300 Gamma Blvd', 30000);

        // [WHEN] The Customer Migrator runs the migration for each customer
        BC14Customer.FindSet();
        repeat
            BC14CustomerMigrator.MigrateCustomer(BC14Customer);
        until BC14Customer.Next() = 0;

        // [THEN] All 3 records are migrated successfully
        Assert.IsTrue(Customer.Get('CUST-A'), 'Customer A should exist after migration');
        Assert.AreEqual('Customer Alpha', Customer.Name, 'Customer A Name should match');
        Assert.AreEqual(10000, Customer."Credit Limit (LCY)", 'Customer A Credit Limit should match');

        Assert.IsTrue(Customer.Get('CUST-B'), 'Customer B should exist after migration');
        Assert.AreEqual('Customer Beta', Customer.Name, 'Customer B Name should match');
        Assert.AreEqual(20000, Customer."Credit Limit (LCY)", 'Customer B Credit Limit should match');

        Assert.IsTrue(Customer.Get('CUST-C'), 'Customer C should exist after migration');
        Assert.AreEqual('Customer Gamma', Customer.Name, 'Customer C Name should match');
        Assert.AreEqual(30000, Customer."Credit Limit (LCY)", 'Customer C Credit Limit should match');
    end;

    [Test]
    procedure TestCustomerMigrationUpdatesExistingCustomer()
    var
        BC14Customer: Record "BC14 Customer";
        Customer: Record Customer;
        BC14CustomerMigrator: Codeunit "BC14 Customer Migrator";
    begin
        // [SCENARIO] If a Customer with the same No. already exists, migration should update it rather than insert a duplicate.

        // [GIVEN] A Customer record already exists in the Customer table
        CleanupTestData();
        EnableReceivablesModule();

        Customer.Init();
        Customer."No." := 'CUST-EXISTING';
        Customer.Name := 'Old Name';
        Customer."Credit Limit (LCY)" := 1000;
        Customer.Insert();

        // [GIVEN] The buffer table has a record with the same No. but different field values
        BC14Customer.Init();
        BC14Customer."No." := 'CUST-EXISTING';
        BC14Customer.Name := 'Updated Name';
        BC14Customer."Credit Limit (LCY)" := 5000;
        BC14Customer.Insert();

        // [WHEN] The Customer Migrator runs the migration
        BC14CustomerMigrator.MigrateCustomer(BC14Customer);

        // [THEN] The existing record is updated
        Customer.Get('CUST-EXISTING');
        Assert.AreEqual('Updated Name', Customer.Name, 'Name should be updated');
        Assert.AreEqual(5000, Customer."Credit Limit (LCY)", 'Credit Limit should be updated');
    end;

    [Test]
    procedure TestCustomerMigratorIsDisabledWhenModuleDisabled()
    var
        BC14CompanyMigrationSettings: Record "BC14CompanyMigrationSettings";
        BC14CustomerMigrator: Codeunit "BC14 Customer Migrator";
    begin
        // [SCENARIO] Customer Migrator reports disabled when the Receivables module is disabled.

        // [GIVEN] The Receivables module is disabled
        BC14CompanyMigrationSettings.DeleteAll();
        BC14CompanyMigrationSettings.GetSingleInstance();
        BC14CompanyMigrationSettings.Validate("Migrate Receivables Module", false);
        BC14CompanyMigrationSettings.Modify();

        // [THEN] IsEnabled should return false
        Assert.IsFalse(BC14CustomerMigrator.IsEnabled(), 'Customer Migrator should be disabled when Receivables module is disabled');
    end;

    [Test]
    procedure TestCustomerMigrationRecordCount()
    var
        BC14CustomerMigrator: Codeunit "BC14 Customer Migrator";
    begin
        // [SCENARIO] GetRecordCount returns the number of records in the buffer table.

        // [GIVEN] 2 records exist in the buffer table
        CleanupTestData();

        InsertBC14Customer('CUST-CNT-1', 'Count Customer 1', 'Address 1', 1000);
        InsertBC14Customer('CUST-CNT-2', 'Count Customer 2', 'Address 2', 2000);

        // [THEN] GetRecordCount should return 2
        Assert.AreEqual(2, BC14CustomerMigrator.GetRecordCount(), 'GetRecordCount should return the number of BC14 Customer records');
    end;

    [Test]
    procedure TestCustomerMigratorIsEnabledByDefault()
    var
        BC14CompanyMigrationSettings: Record "BC14CompanyMigrationSettings";
        BC14CustomerMigrator: Codeunit "BC14 Customer Migrator";
    begin
        // [SCENARIO] The Customer Migrator is enabled by default.

        // [GIVEN] Default settings are used
        BC14CompanyMigrationSettings.DeleteAll();

        // [THEN] IsEnabled should return true
        Assert.IsTrue(BC14CustomerMigrator.IsEnabled(), 'Customer Migrator should be enabled by default');
    end;

    [Test]
    procedure TestCustomerMigratorName()
    var
        BC14CustomerMigrator: Codeunit "BC14 Customer Migrator";
    begin
        // [SCENARIO] GetName returns the correct migrator name.

        // [THEN] The name should be 'Customer Migrator'
        Assert.AreEqual('Customer Migrator', BC14CustomerMigrator.GetName(), 'Migrator name should be Customer Migrator');
    end;

    [Test]
    procedure TestCustomerMigratorSourceTableId()
    var
        BC14CustomerMigrator: Codeunit "BC14 Customer Migrator";
    begin
        // [SCENARIO] GetSourceTableId returns the correct buffer table ID.

        // [THEN] The source table ID should be BC14 Customer
        Assert.AreEqual(Database::"BC14 Customer", BC14CustomerMigrator.GetSourceTableId(), 'Source table ID should be BC14 Customer');
    end;

    [Test]
    procedure TestCustomerMigratorGetSourceRecordKey()
    var
        BC14Customer: Record "BC14 Customer";
        BC14CustomerMigrator: Codeunit "BC14 Customer Migrator";
        SourceRecordRef: RecordRef;
    begin
        // [SCENARIO] GetSourceRecordKey returns the Customer No. as the record key.

        // [GIVEN] A customer exists in the buffer table
        CleanupTestData();
        InsertBC14Customer('CUST-KEY-TEST', 'Test Customer', 'Test Address', 1000);

        // [WHEN] GetSourceRecordKey is called
        BC14Customer.Get('CUST-KEY-TEST');
        SourceRecordRef.GetTable(BC14Customer);

        // [THEN] The record key is the Customer No.
        Assert.AreEqual('CUST-KEY-TEST', BC14CustomerMigrator.GetSourceRecordKey(SourceRecordRef), 'Record key should be the Customer No.');
        SourceRecordRef.Close();
    end;

    [Test]
    procedure TestCustomerMigrationBlockedCustomer()
    var
        BC14Customer: Record "BC14 Customer";
        Customer: Record Customer;
        BC14CustomerMigrator: Codeunit "BC14 Customer Migrator";
    begin
        // [SCENARIO] Blocked status is correctly migrated.

        // [GIVEN] A blocked Customer record exists in the buffer table
        CleanupTestData();
        EnableReceivablesModule();

        BC14Customer.Init();
        BC14Customer."No." := 'CUST-BLOCKED';
        BC14Customer.Name := 'Blocked Customer';
        BC14Customer.Blocked := BC14Customer.Blocked::All;
        BC14Customer.Insert();

        // [WHEN] The Customer Migrator runs the migration
        BC14CustomerMigrator.MigrateCustomer(BC14Customer);

        // [THEN] The blocked status is preserved
        Assert.IsTrue(Customer.Get('CUST-BLOCKED'), 'Customer record should exist after migration');
        Assert.AreEqual(Customer.Blocked::All, Customer.Blocked, 'Blocked status should be All');
    end;

    local procedure CleanupTestData()
    var
        BC14Customer: Record "BC14 Customer";
        Customer: Record Customer;
    begin
        BC14Customer.DeleteAll();

        Customer.SetFilter("No.", 'CUST-*');
        Customer.DeleteAll();
    end;

    local procedure EnableReceivablesModule()
    var
        BC14CompanyMigrationSettings: Record "BC14CompanyMigrationSettings";
    begin
        BC14CompanyMigrationSettings.DeleteAll();
        BC14CompanyMigrationSettings.GetSingleInstance();
        BC14CompanyMigrationSettings.Validate("Migrate Receivables Module", true);
        BC14CompanyMigrationSettings.Modify();
    end;

    local procedure InsertBC14Customer(CustomerNo: Code[20]; CustomerName: Text[100]; CustomerAddress: Text[100]; CreditLimit: Decimal)
    var
        BC14Customer: Record "BC14 Customer";
    begin
        BC14Customer.Init();
        BC14Customer."No." := CustomerNo;
        BC14Customer.Name := CustomerName;
        BC14Customer.Address := CustomerAddress;
        BC14Customer."Credit Limit (LCY)" := CreditLimit;
        BC14Customer.Insert();
    end;
}
