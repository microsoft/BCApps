// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

codeunit 148012 "C5 Telemetry Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        C5MigrationTypeTxt: Label 'C5 2012', Locked = true;

    trigger OnRun()
    begin
        // [FEATURE] [C5 Data Migration] [Telemetry]
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CompletedMigrationIsDetected()
    var
        DataMigrationStatus: Record "Data Migration Status";
        C5Telemetry: Codeunit "C5 Telemetry";
        MigrationDateTime: DateTime;
    begin
        // [GIVEN] A completed C5 migration
        DeleteMigrationStatus();
        CreateMigrationStatus(Database::Customer, DataMigrationStatus.Status::Completed);
        CreateMigrationStatus(Database::Vendor, DataMigrationStatus.Status::Completed);

        // [WHEN] Checking for a completed migration
        // [THEN] The migration is detected and has a completion time
        Assert.IsTrue(C5Telemetry.GetCompletedMigrationDateTime(MigrationDateTime), 'The completed C5 migration was not detected.');
        Assert.AreNotEqual(0DT, MigrationDateTime, 'The migration completion time was not returned.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IncompleteMigrationIsNotDetectedAsCompleted()
    var
        DataMigrationStatus: Record "Data Migration Status";
        C5Telemetry: Codeunit "C5 Telemetry";
        MigrationDateTime: DateTime;
    begin
        // [GIVEN] A C5 migration with a failed entity
        DeleteMigrationStatus();
        CreateMigrationStatus(Database::Customer, DataMigrationStatus.Status::Completed);
        CreateMigrationStatus(Database::Vendor, DataMigrationStatus.Status::Failed);

        // [WHEN] Checking for a completed migration
        // [THEN] The migration is not detected as completed
        Assert.IsFalse(C5Telemetry.GetCompletedMigrationDateTime(MigrationDateTime), 'The failed C5 migration was detected as completed.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MissingMigrationIsNotDetectedAsCompleted()
    var
        C5Telemetry: Codeunit "C5 Telemetry";
        MigrationDateTime: DateTime;
    begin
        // [GIVEN] No C5 migration status
        DeleteMigrationStatus();

        // [WHEN] Checking for a completed migration
        // [THEN] No migration is detected
        Assert.IsFalse(C5Telemetry.GetCompletedMigrationDateTime(MigrationDateTime), 'A C5 migration was detected without migration status records.');
    end;

    local procedure CreateMigrationStatus(DestinationTableId: Integer; Status: Option)
    var
        DataMigrationStatus: Record "Data Migration Status";
    begin
        DataMigrationStatus.Init();
        DataMigrationStatus."Migration Type" := C5MigrationTypeTxt;
        DataMigrationStatus."Destination Table ID" := DestinationTableId;
        DataMigrationStatus.Status := Status;
        DataMigrationStatus.Insert();
    end;

    local procedure DeleteMigrationStatus()
    var
        DataMigrationStatus: Record "Data Migration Status";
    begin
        DataMigrationStatus.SetRange("Migration Type", C5MigrationTypeTxt);
        DataMigrationStatus.DeleteAll();
    end;
}
