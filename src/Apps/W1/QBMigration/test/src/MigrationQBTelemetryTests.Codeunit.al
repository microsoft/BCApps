codeunit 139533 "MigrationQB Telemetry Tests"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        MigrationTypeTxt: Label 'QuickBooks', Locked = true;

    trigger OnRun()
    begin
        // [FEATURE] [QuickBooks Data Migration] [Telemetry]
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CompletedMigrationIsDetected()
    var
        DataMigrationStatus: Record "Data Migration Status";
        MigrationQBDashboardMgt: Codeunit "MigrationQB Dashboard Mgt";
        MigrationDateTime: DateTime;
    begin
        // [GIVEN] A completed QuickBooks migration
        DeleteMigrationStatus();
        CreateMigrationStatus(Database::Customer, DataMigrationStatus.Status::Completed);
        CreateMigrationStatus(Database::Vendor, DataMigrationStatus.Status::Completed);

        // [WHEN] Checking for a completed migration
        // [THEN] The migration is detected and has a completion time
        Assert.IsTrue(MigrationQBDashboardMgt.GetCompletedMigrationDateTime(MigrationDateTime), 'The completed QuickBooks migration was not detected.');
        Assert.AreNotEqual(0DT, MigrationDateTime, 'The migration completion time was not returned.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IncompleteMigrationIsNotDetectedAsCompleted()
    var
        DataMigrationStatus: Record "Data Migration Status";
        MigrationQBDashboardMgt: Codeunit "MigrationQB Dashboard Mgt";
        MigrationDateTime: DateTime;
    begin
        // [GIVEN] A QuickBooks migration with a failed entity
        DeleteMigrationStatus();
        CreateMigrationStatus(Database::Customer, DataMigrationStatus.Status::Completed);
        CreateMigrationStatus(Database::Vendor, DataMigrationStatus.Status::Failed);

        // [WHEN] Checking for a completed migration
        // [THEN] The migration is not detected as completed
        Assert.IsFalse(MigrationQBDashboardMgt.GetCompletedMigrationDateTime(MigrationDateTime), 'The failed QuickBooks migration was detected as completed.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MissingMigrationIsNotDetectedAsCompleted()
    var
        DataMigrationStatus: Record "Data Migration Status";
        MigrationQBDashboardMgt: Codeunit "MigrationQB Dashboard Mgt";
        MigrationDateTime: DateTime;
    begin
        // [GIVEN] No QuickBooks migration status
        DeleteMigrationStatus();

        // [WHEN] Checking for a completed migration
        // [THEN] No migration is detected
        Assert.IsFalse(MigrationQBDashboardMgt.GetCompletedMigrationDateTime(MigrationDateTime), 'A QuickBooks migration was detected without migration status records.');
    end;

    local procedure CreateMigrationStatus(DestinationTableId: Integer; Status: Option)
    var
        DataMigrationStatus: Record "Data Migration Status";
    begin
        DataMigrationStatus.Init();
        DataMigrationStatus."Migration Type" := MigrationTypeTxt;
        DataMigrationStatus."Destination Table ID" := DestinationTableId;
        DataMigrationStatus.Status := Status;
        DataMigrationStatus.Insert();
    end;

    local procedure DeleteMigrationStatus()
    var
        DataMigrationStatus: Record "Data Migration Status";
    begin
        DataMigrationStatus.SetRange("Migration Type", MigrationTypeTxt);
        DataMigrationStatus.DeleteAll();
    end;
}
