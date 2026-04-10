namespace System.Integration;
using Microsoft.Finance.GeneralLedger.Account;

codeunit 6101 "Data Migration Status Facade"
{

    trigger OnRun()
    begin
    end;

    procedure InitStatusLine(MigrationType: Text[250]; DestinationTableId: Integer; TotalNumber: Integer; StagingTableId: Integer; MigrationCodeunitId: Integer)
    var
        DataMigrationStatus: Record "Data Migration Status";
    begin
        if TotalNumber = 0 then
            exit;

        if DataMigrationStatus.Get(MigrationType, DestinationTableId) then
            DataMigrationStatus.Delete();

        DataMigrationStatus.Init();
        DataMigrationStatus.Validate("Migration Type", MigrationType);
        DataMigrationStatus.Validate("Destination Table ID", DestinationTableId);
        DataMigrationStatus.Validate("Total Number", TotalNumber);
        DataMigrationStatus.Validate("Migrated Number", 0);
        DataMigrationStatus.Validate("Progress Percent", 0);
        DataMigrationStatus.Validate(Status, DataMigrationStatus.Status::Pending);
        DataMigrationStatus.Validate("Source Staging Table ID", StagingTableId);
        DataMigrationStatus.Validate("Migration Codeunit To Run", MigrationCodeunitId);
        DataMigrationStatus.Insert();
    end;

    procedure IncrementMigratedRecordCount(MigrationType: Text[250]; DestinationTableId: Integer; MigratedEntities: Integer)
    var
        DataMigrationStatus: Record "Data Migration Status";
    begin
        DataMigrationStatus.Get(MigrationType, DestinationTableId);

        DataMigrationStatus.Validate("Migrated Number", DataMigrationStatus."Migrated Number" + MigratedEntities);
        DataMigrationStatus.Modify(true);
    end;

    procedure UpdateLineStatus(MigrationType: Text[250]; DestinationTableId: Integer; Status: Option)
    var
        DataMigrationStatus: Record "Data Migration Status";
    begin
        DataMigrationStatus.Get(MigrationType, DestinationTableId);

        DataMigrationStatus.Validate(Status, Status);
        DataMigrationStatus.Modify(true);
    end;

    procedure IgnoreErrors(MigrationType: Text[250]; DestinationTableId: Integer; ErrorCountToIgnore: Integer)
    var
        DataMigrationStatus: Record "Data Migration Status";
    begin
        DataMigrationStatus.Get(MigrationType, DestinationTableId);

        DataMigrationStatus.Validate("Total Number", DataMigrationStatus."Total Number" - ErrorCountToIgnore);
        DataMigrationStatus.CalcFields("Error Count");
        if DataMigrationStatus."Error Count" = 0 then
            DataMigrationStatus.Status := DataMigrationStatus.Status::Completed;
        DataMigrationStatus.Modify(true);
        if DataMigrationStatus."Total Number" = 0 then
            DataMigrationStatus.Delete(true);
    end;

    procedure HasMigratedChartOfAccounts(DataMigrationParameters: Record "Data Migration Parameters"): Boolean
    var
        DataMigrationStatus: Record "Data Migration Status";
    begin
        DataMigrationStatus.SetRange("Migration Type", DataMigrationParameters."Migration Type");
        DataMigrationStatus.SetRange("Destination Table ID", DATABASE::"G/L Account");
        exit(not DataMigrationStatus.IsEmpty);
    end;

    procedure RegisterErrorNoStagingTablesCase(MigrationType: Text[250]; DestinationTableId: Integer; ErrorMessage: Text[250])
    var
        DataMigrationError: Record "Data Migration Error";
    begin
        DataMigrationError.CreateEntryNoStagingTableWithMessage(MigrationType, DestinationTableId, ErrorMessage);
    end;
}

