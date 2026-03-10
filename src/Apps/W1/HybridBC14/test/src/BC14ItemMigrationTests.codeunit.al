// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration.BC14;
using Microsoft.Inventory.Item;

codeunit 148150 "BC14 Item Migration Tests"
{
    // [FEATURE] [BC14 Cloud Migration Item Upgrade]

    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure TestItemMigrationTransfersAllFields()
    var
        BC14Item: Record "BC14 Item";
        Item: Record Item;
        BC14ItemMigrator: Codeunit "BC14 Item Migrator";
    begin
        // [SCENARIO] All standard fields are correctly migrated from BC14 Item buffer to Item table.

        // [GIVEN] A complete Item record exists in the buffer table
        CleanupTestData();
        EnableInventoryModule();

        BC14Item.Init();
        BC14Item."No." := 'ITEM-TEST-001';
        BC14Item.Description := 'Test Migration Item';
        BC14Item.Type := 0; // Inventory
        BC14Item."Base Unit of Measure" := 'PCS';
        BC14Item."Unit Price" := 99.99;
        BC14Item."Standard Cost" := 50.00;
        BC14Item."Unit Cost" := 45.00;
        BC14Item.Blocked := false;
        BC14Item."Inventory Posting Group" := 'RESALE';
        BC14Item."Costing Method" := 0; // FIFO
        BC14Item."Net Weight" := 1.5;
        BC14Item."Unit Volume" := 0.25;
        BC14Item.Insert();

        // [WHEN] The Item Migrator runs the migration
        BC14ItemMigrator.MigrateItem(BC14Item);

        // [THEN] Migration succeeds and all field values in the Item table match the buffer
        Assert.IsTrue(Item.Get('ITEM-TEST-001'), 'Item record should exist after migration');

        Assert.AreEqual('Test Migration Item', Item.Description, 'Description should match');
        Assert.AreEqual(Enum::"Item Type"::Inventory, Item.Type, 'Type should be Inventory');
        Assert.AreEqual('PCS', Item."Base Unit of Measure", 'Base Unit of Measure should match');
        Assert.AreEqual(99.99, Item."Unit Price", 'Unit Price should match');
        Assert.AreEqual(50.00, Item."Standard Cost", 'Standard Cost should match');
        Assert.AreEqual(45.00, Item."Unit Cost", 'Unit Cost should match');
        Assert.AreEqual(false, Item.Blocked, 'Blocked should match');
        Assert.AreEqual('RESALE', Item."Inventory Posting Group", 'Inventory Posting Group should match');
        Assert.AreEqual(Enum::"Costing Method"::FIFO, Item."Costing Method", 'Costing Method should be FIFO');
        Assert.AreEqual(1.5, Item."Net Weight", 'Net Weight should match');
        Assert.AreEqual(0.25, Item."Unit Volume", 'Unit Volume should match');
    end;

    [Test]
    procedure TestItemMigrationMultipleItems()
    var
        BC14Item: Record "BC14 Item";
        Item: Record Item;
        BC14ItemMigrator: Codeunit "BC14 Item Migrator";
    begin
        // [SCENARIO] Multiple items in the buffer table are all migrated successfully.

        // [GIVEN] 3 Item records exist in the buffer table
        CleanupTestData();
        EnableInventoryModule();

        InsertBC14Item('ITEM-A', 'Item Alpha', 25.00, 10.00);
        InsertBC14Item('ITEM-B', 'Item Beta', 50.00, 20.00);
        InsertBC14Item('ITEM-C', 'Item Gamma', 75.00, 30.00);

        // [WHEN] The Item Migrator runs the migration for each item
        BC14Item.FindSet();
        repeat
            BC14ItemMigrator.MigrateItem(BC14Item);
        until BC14Item.Next() = 0;

        // [THEN] All 3 records are migrated successfully

        Assert.IsTrue(Item.Get('ITEM-A'), 'Item A should exist after migration');
        Assert.AreEqual('Item Alpha', Item.Description, 'Item A Description should match');
        Assert.AreEqual(25.00, Item."Unit Price", 'Item A Unit Price should match');

        Assert.IsTrue(Item.Get('ITEM-B'), 'Item B should exist after migration');
        Assert.AreEqual('Item Beta', Item.Description, 'Item B Description should match');
        Assert.AreEqual(50.00, Item."Unit Price", 'Item B Unit Price should match');

        Assert.IsTrue(Item.Get('ITEM-C'), 'Item C should exist after migration');
        Assert.AreEqual('Item Gamma', Item.Description, 'Item C Description should match');
        Assert.AreEqual(75.00, Item."Unit Price", 'Item C Unit Price should match');
    end;

    [Test]
    procedure TestItemMigrationUpdatesExistingItem()
    var
        BC14Item: Record "BC14 Item";
        Item: Record Item;
        BC14ItemMigrator: Codeunit "BC14 Item Migrator";
    begin
        // [SCENARIO] If an Item with the same No. already exists, migration should update it rather than insert a duplicate.

        // [GIVEN] An Item record already exists in the Item table
        CleanupTestData();
        EnableInventoryModule();

        Item.Init();
        Item."No." := 'ITEM-EXISTING';
        Item.Description := 'Old Description';
        Item."Unit Price" := 10.00;
        Item.Insert();

        // [GIVEN] The buffer table has a record with the same No. but different field values
        BC14Item.Init();
        BC14Item."No." := 'ITEM-EXISTING';
        BC14Item.Description := 'Updated Description';
        BC14Item."Unit Price" := 88.88;
        BC14Item."Unit Cost" := 44.44;
        BC14Item.Insert();

        // [WHEN] The Item Migrator runs the migration
        BC14ItemMigrator.MigrateItem(BC14Item);

        // [THEN] The existing record is updated
        Item.Get('ITEM-EXISTING');
        Assert.AreEqual('Updated Description', Item.Description, 'Description should be updated');
        Assert.AreEqual(88.88, Item."Unit Price", 'Unit Price should be updated');
        Assert.AreEqual(44.44, Item."Unit Cost", 'Unit Cost should be updated');
    end;

    [Test]
    procedure TestItemMigrationSkippedWhenModuleDisabled()
    var
        BC14Item: Record "BC14 Item";
        Item: Record Item;
        BC14CompanyAdditionalSettings: Record "BC14CompanyAdditionalSettings";
        BC14ItemMigrator: Codeunit "BC14 Item Migrator";
        MigrateResult: Boolean;
    begin
        // [SCENARIO] Item migration is skipped when the Inventory module is disabled.

        // [GIVEN] The Inventory module is disabled
        CleanupTestData();
        BC14CompanyAdditionalSettings.DeleteAll();
        BC14CompanyAdditionalSettings.GetSingleInstance();
        BC14CompanyAdditionalSettings.Validate("Migrate Inventory Module", false);
        BC14CompanyAdditionalSettings.Modify();

        // [GIVEN] The buffer table contains data
        InsertBC14Item('ITEM-SKIP', 'Should Not Migrate', 100.00, 50.00);

        // [WHEN] The Item Migrator runs the migration
        MigrateResult := BC14ItemMigrator.Migrate(false);

        // [THEN] Migrate returns true (skipped, not failed) and no Item record is created
        Assert.IsTrue(MigrateResult, 'Migrate should return true when module is disabled (skipped)');
        Assert.IsFalse(Item.Get('ITEM-SKIP'), 'Item should not exist when inventory module is disabled');
    end;

    [Test]
    procedure TestItemMigrationRecordCount()
    var
        BC14ItemMigrator: Codeunit "BC14 Item Migrator";
    begin
        // [SCENARIO] GetRecordCount returns the number of records in the buffer table.

        // [GIVEN] 2 records exist in the buffer table
        CleanupTestData();

        InsertBC14Item('ITEM-CNT-1', 'Count Item 1', 10.00, 5.00);
        InsertBC14Item('ITEM-CNT-2', 'Count Item 2', 20.00, 10.00);

        // [THEN] GetRecordCount should return 2
        Assert.AreEqual(2, BC14ItemMigrator.GetRecordCount(), 'GetRecordCount should return the number of BC14 Item records');
    end;

    [Test]
    procedure TestItemMigratorIsEnabledByDefault()
    var
        BC14CompanyAdditionalSettings: Record "BC14CompanyAdditionalSettings";
        BC14ItemMigrator: Codeunit "BC14 Item Migrator";
    begin
        // [SCENARIO] The Item Migrator is enabled by default.

        // [GIVEN] Default settings are used
        BC14CompanyAdditionalSettings.DeleteAll();

        // [THEN] IsEnabled should return true
        Assert.IsTrue(BC14ItemMigrator.IsEnabled(), 'Item Migrator should be enabled by default');
    end;

    [Test]
    procedure TestItemMigratorName()
    var
        BC14ItemMigrator: Codeunit "BC14 Item Migrator";
    begin
        // [SCENARIO] GetName returns the correct migrator name.

        // [THEN] The name should be 'Item Migrator'
        Assert.AreEqual('Item Migrator', BC14ItemMigrator.GetName(), 'Migrator name should be Item Migrator');
    end;

    local procedure CleanupTestData()
    var
        BC14Item: Record "BC14 Item";
        Item: Record Item;
    begin
        BC14Item.DeleteAll();

        Item.SetFilter("No.", 'ITEM-*');
        Item.DeleteAll();
    end;

    local procedure EnableInventoryModule()
    var
        BC14CompanyAdditionalSettings: Record "BC14CompanyAdditionalSettings";
    begin
        BC14CompanyAdditionalSettings.DeleteAll();
        BC14CompanyAdditionalSettings.GetSingleInstance();
        BC14CompanyAdditionalSettings.Validate("Migrate Inventory Module", true);
        BC14CompanyAdditionalSettings.Modify();
    end;

    local procedure InsertBC14Item(ItemNo: Code[20]; ItemDescription: Text[100]; UnitPrice: Decimal; UnitCost: Decimal)
    var
        BC14Item: Record "BC14 Item";
    begin
        BC14Item.Init();
        BC14Item."No." := ItemNo;
        BC14Item.Description := ItemDescription;
        BC14Item."Unit Price" := UnitPrice;
        BC14Item."Unit Cost" := UnitCost;
        BC14Item.Insert();
    end;
}
