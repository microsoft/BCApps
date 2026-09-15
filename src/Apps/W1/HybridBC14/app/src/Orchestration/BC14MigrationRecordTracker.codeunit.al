// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

codeunit 46852 "BC14 Migration Record Tracker"
{
    internal procedure LogMigrateResult(
        MigratorName: Text[250];
        SourceTableId: Integer;
        SourceTableName: Text[250];
        RecordKey: Text[250];
        SourceRecordId: RecordId;
        MigrateSucceeded: Boolean;
        var MigratorSuccess: Boolean): Boolean
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
    begin
        if not MigrateSucceeded then begin
            BC14MigrationErrorHandler.LogError(MigratorName, SourceTableId, SourceTableName, RecordKey, 0, CopyStr(GetLastErrorText(), 1, 2048), SourceRecordId);
            MigratorSuccess := false;
            // Must commit after each record because migrators use Codeunit.Run() with return value, which requires no open write transaction
            Commit();
            BC14CompanySettings.GetSingleInstance();
            if BC14CompanySettings.GetStopOnFirstTransformationError() then
                exit(false);
            ClearLastError();
        end else begin
            MigratorSuccess := true;
            if BC14MigrationErrorHandler.HasUnresolvedError(SourceTableId, RecordKey) then
                BC14MigrationErrorHandler.ResolveErrorForRecord(SourceTableId, RecordKey);
            // Must commit after each record because migrators use Codeunit.Run() with return value, which requires no open write transaction
            Commit();
        end;

        exit(true);
    end;

    internal procedure GetTableNameById(TableId: Integer): Text[250]
    var
        SourceRecordRef: RecordRef;
    begin
        SourceRecordRef.Open(TableId);
        exit(CopyStr(SourceRecordRef.Name, 1, 250));
    end;

    /// <summary>
    /// Placeholder for per-migrator progress reporting. Migrators that need a meaningful
    /// remaining-percentage value should compute it from their own source/target counts
    /// (see e.g. BC14 Item Migrator, BC14 Posted Sales Inv Migrator). This default
    /// returns 0 since by the time it is invoked the migrator has already returned
    /// from Migrate(), so "remaining" has no per-record meaning.
    /// </summary>
    internal procedure GetRemainingPercentage(SourceTableId: Integer; TotalRecordCount: Integer): Integer
    begin
        exit(0);
    end;
}
