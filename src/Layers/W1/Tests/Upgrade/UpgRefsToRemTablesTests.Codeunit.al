codeunit 135973 "Upg Refs To Rem. Tables Tests"
{
    Subtype = Test;

    [Test]
    procedure ChangeLogSetupCleanUpTest()
    var
        ChangeLogSetupTable: Record "Change Log Setup (Table)";
        UpgradeStatus: Codeunit "Upgrade Status";
        Assert: Codeunit "Library Assert";
    begin
        if not UpgradeStatus.UpgradeTriggered() then
            exit;

        Assert.AreEqual(2, ChangeLogSetupTable.Count(), 'There are references to removed tables left.');

        ChangeLogSetupTable.FindSet();
        repeat
            Assert.IsTrue(ChangeLogSetupTable."Table No." in [Database::Customer, Database::Item], 'References to the removed tables have stayed.');
        until ChangeLogSetupTable.Next() = 0;
    end;

    [Test]
    procedure WhseActivityLineJobSourceIsUpgradedToJobPlanningLineOrderTest()
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        UpgradeStatus: Codeunit "Upgrade Status";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        Assert: Codeunit "Library Assert";
    begin
        if not UpgradeStatus.UpgradeTriggered() then
            exit;

        if UpgradeStatus.UpgradeTagPresentBeforeUpgrade(
            UpgradeTagDefinitions.GetWarehouseActivitySourceTypeForJobPlanningLineUpgradeTag())
        then
            exit;

        // [GIVEN] A legacy Warehouse Activity Line was seeded with Source Type = Job / Source Subtype = 0.
        WarehouseActivityLine.SetRange("No.", 'UPG-WHACT-J01');
        Assert.IsTrue(WarehouseActivityLine.FindFirst(), 'Seeded Warehouse Activity Line was not found after upgrade.');

        // [THEN] The upgrade sets Source Type = "Job Planning Line" and Source Subtype = Order.
        Assert.AreEqual(Database::"Job Planning Line", WarehouseActivityLine."Source Type",
            'Warehouse Activity Line Source Type was not upgraded to Job Planning Line.');
        Assert.AreEqual("Job Planning Line Status"::Order.AsInteger(), WarehouseActivityLine."Source Subtype",
            'Warehouse Activity Line Source Subtype was not upgraded to Order.');

        // [THEN] No stale legacy rows remain.
        WarehouseActivityLine.Reset();
        WarehouseActivityLine.SetRange("Source Type", Database::Job);
        WarehouseActivityLine.SetRange("Source Subtype", 0);
        Assert.IsTrue(WarehouseActivityLine.IsEmpty(),
            'Legacy Warehouse Activity Line rows (Source Type = Job, Source Subtype = 0) still exist after upgrade.');
    end;

    [Test]
    procedure WhseWorksheetLineJobSourceIsUpgradedToJobPlanningLineOrderTest()
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        UpgradeStatus: Codeunit "Upgrade Status";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        Assert: Codeunit "Library Assert";
    begin
        if not UpgradeStatus.UpgradeTriggered() then
            exit;

        if UpgradeStatus.UpgradeTagPresentBeforeUpgrade(
            UpgradeTagDefinitions.GetWarehouseActivitySourceTypeForJobPlanningLineUpgradeTag())
        then
            exit;

        // [GIVEN] A legacy Whse. Worksheet Line was seeded with Source Type = Job / Source Subtype = 0.
        WhseWorksheetLine.SetRange("Worksheet Template Name", 'UPGWHT');
        WhseWorksheetLine.SetRange(Name, 'UPGWSN');
        Assert.IsTrue(WhseWorksheetLine.FindFirst(), 'Seeded Whse. Worksheet Line was not found after upgrade.');

        // [THEN] The upgrade sets Source Type = "Job Planning Line" and Source Subtype = Order.
        Assert.AreEqual(Database::"Job Planning Line", WhseWorksheetLine."Source Type",
            'Whse. Worksheet Line Source Type was not upgraded to Job Planning Line.');
        Assert.AreEqual("Job Planning Line Status"::Order.AsInteger(), WhseWorksheetLine."Source Subtype",
            'Whse. Worksheet Line Source Subtype was not upgraded to Order.');

        // [THEN] No stale legacy rows remain.
        WhseWorksheetLine.Reset();
        WhseWorksheetLine.SetRange("Source Type", Database::Job);
        WhseWorksheetLine.SetRange("Source Subtype", 0);
        Assert.IsTrue(WhseWorksheetLine.IsEmpty(),
            'Legacy Whse. Worksheet Line rows (Source Type = Job, Source Subtype = 0) still exist after upgrade.');
    end;

    [Test]
    procedure WarehouseRequestJobSourceIsUpgradedToJobPlanningLineOrderTest()
    var
        WarehouseRequest: Record "Warehouse Request";
        UpgradeStatus: Codeunit "Upgrade Status";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        Assert: Codeunit "Library Assert";
    begin
        // Warehouse Request has Source Type / Source Subtype in its primary key, so the upgrade uses
        // Rename rather than DataTransfer. This test guards against a regression that would leave the row unchanged.
        if not UpgradeStatus.UpgradeTriggered() then
            exit;

        if UpgradeStatus.UpgradeTagPresentBeforeUpgrade(
            UpgradeTagDefinitions.GetWarehouseActivitySourceTypeForJobPlanningLineUpgradeTag())
        then
            exit;

        // [GIVEN] A legacy Warehouse Request was seeded with Source Type = Job / Source Subtype = 0 and Source No. = 'UPG-JOB-01'.
        // [THEN] The row is now retrievable using the new primary key values.
        Assert.IsTrue(
            WarehouseRequest.Get(WarehouseRequest.Type::Outbound, '', Database::"Job Planning Line", "Job Planning Line Status"::Order.AsInteger(), 'UPG-JOB-01'),
            'Warehouse Request row was not renamed to the Job Planning Line / Order primary key.');

        // [THEN] No stale legacy rows remain.
        WarehouseRequest.Reset();
        WarehouseRequest.SetRange("Source Type", Database::Job);
        WarehouseRequest.SetRange("Source Subtype", 0);
        Assert.IsTrue(WarehouseRequest.IsEmpty(),
            'Legacy Warehouse Request rows (Source Type = Job, Source Subtype = 0) still exist after upgrade.');
    end;
}