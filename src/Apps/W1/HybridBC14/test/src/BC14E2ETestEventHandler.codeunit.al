// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration.BC14;

codeunit 148904 "BC14 E2E Test Event Handler"
{
    EventSubscriberInstance = Manual;

    var
        InjectErrorOnMigrator: Text[250];
        InjectErrorOnRecordKey: Text[250];
        InjectErrorMessage: Text;
        ErrorInjectionEnabled: Boolean;
        SimulateSuccessOnRetry: Boolean;
        PreviouslyFailedRecords: List of [Text];
        MigratorCompletedList: List of [Text[250]];
        RecordsMigratedCount: Integer;
        RecordsFailedCount: Integer;

    trigger OnRun()
    begin
    end;

    /// <summary>
    /// Configures error injection for a specific migrator and record key.
    /// When the migration runner encounters this migrator/record, an error will be thrown.
    /// </summary>
    procedure SetErrorInjection(MigratorName: Text[250]; RecordKey: Text[250]; ErrorMessage: Text)
    begin
        InjectErrorOnMigrator := MigratorName;
        InjectErrorOnRecordKey := RecordKey;
        InjectErrorMessage := ErrorMessage;
        ErrorInjectionEnabled := true;
    end;

    /// <summary>
    /// Clears any configured error injection and enables success simulation for previously failed records.
    /// On retry, records that previously failed will be simulated as successful.
    /// </summary>
    procedure ClearErrorInjection()
    begin
        InjectErrorOnMigrator := '';
        InjectErrorOnRecordKey := '';
        InjectErrorMessage := '';
        ErrorInjectionEnabled := false;
        SimulateSuccessOnRetry := true; // Enable success simulation for retry
    end;

    /// <summary>
    /// Returns true if error injection is currently enabled.
    /// </summary>
    procedure IsErrorInjectionEnabled(): Boolean
    begin
        exit(ErrorInjectionEnabled);
    end;

    /// <summary>
    /// Resets all counters and state for a new test.
    /// </summary>
    procedure Reset()
    begin
        ClearErrorInjection();
        SimulateSuccessOnRetry := false;
        Clear(PreviouslyFailedRecords);
        Clear(MigratorCompletedList);
        RecordsMigratedCount := 0;
        RecordsFailedCount := 0;
    end;

    /// <summary>
    /// Returns the number of records that were successfully migrated.
    /// </summary>
    procedure GetRecordsMigratedCount(): Integer
    begin
        exit(RecordsMigratedCount);
    end;

    /// <summary>
    /// Returns the number of records that failed migration.
    /// </summary>
    procedure GetRecordsFailedCount(): Integer
    begin
        exit(RecordsFailedCount);
    end;

    /// <summary>
    /// Returns true if the specified migrator has completed.
    /// </summary>
    procedure HasMigratorCompleted(MigratorName: Text[250]): Boolean
    begin
        exit(MigratorCompletedList.Contains(MigratorName));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"BC14 Management", 'OnCreateSessionForUpgrade', '', false, false)]
    local procedure HandleOnCreateSessionForUpgrade(var CreateSession: Boolean)
    begin
        CreateSession := false;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"BC14 Migration Runner", 'OnBeforeMigrateRecord', '', false, false)]
    local procedure HandleOnBeforeMigrateRecord(MigratorName: Text[250]; var SourceRecordRef: RecordRef; var SkipRecord: Boolean)
    var
        BC14CompanySettings: Record BC14CompanyMigrationSettings;
        BC14MigrationRecordStatus: Record "BC14 Migration Record Status";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        RecordKey: Text[250];
        SourceTableName: Text[250];
        FailedRecordKey: Text;
    begin
        // Get the primary key of the record for matching
        RecordKey := CopyStr(Format(SourceRecordRef.Field(1).Value), 1, MaxStrLen(RecordKey));
        FailedRecordKey := MigratorName + ':' + RecordKey;

        // After migration is paused (Stop On First Error), skip all remaining records
        BC14CompanySettings.GetSingleInstance();
        if BC14CompanySettings.IsMigrationPaused() then begin
            SkipRecord := true;
            // Throw error to stop the migration loop entirely (state is already Paused)
            Error('Migration paused due to error');
        end;

        // On retry: simulate success for previously failed records
        if SimulateSuccessOnRetry and PreviouslyFailedRecords.Contains(FailedRecordKey) then begin
            // Mark as migrated
            BC14MigrationRecordStatus.MarkAsMigrated(SourceRecordRef.Number, RecordKey);
            // Resolve any previous error
            if BC14MigrationErrorHandler.HasUnresolvedError(SourceRecordRef.Number, RecordKey) then
                BC14MigrationErrorHandler.ResolveErrorForRecord(SourceRecordRef.Number, RecordKey);
            // Skip the actual migrator (we've simulated success)
            SkipRecord := true;
            RecordsMigratedCount += 1;
            PreviouslyFailedRecords.Remove(FailedRecordKey);
            exit;
        end;

        if not ErrorInjectionEnabled then
            exit;

        // Check if this is the record we want to fail
        if (MigratorName = InjectErrorOnMigrator) and
           ((InjectErrorOnRecordKey = '') or (RecordKey = InjectErrorOnRecordKey)) then begin
            // Track this record as failed for retry simulation
            if not PreviouslyFailedRecords.Contains(FailedRecordKey) then
                PreviouslyFailedRecords.Add(FailedRecordKey);

            // Log error instead of throwing - this simulates a migration failure
            SourceTableName := CopyStr(SourceRecordRef.Name, 1, MaxStrLen(SourceTableName));
            BC14MigrationErrorHandler.LogError(
                MigratorName,
                SourceRecordRef.Number,
                SourceTableName,
                RecordKey,
                0, // Destination table ID not known at this point
                InjectErrorMessage,
                SourceRecordRef.RecordId);

            // In Stop On First Error mode, we need to pause the migration
            if BC14CompanySettings.GetStopOnFirstTransformationError() then begin
                BC14CompanySettings.PauseMigration(MigratorName);
                // Commit before throwing error so asserterror doesn't roll back the pause/error state
                Commit();
                // Throw error to exit the migration loop (state is already Paused and committed)
                Error('Migration paused due to error');
            end;

            // Continue On Error mode: skip this record and continue
            SkipRecord := true;
            RecordsFailedCount += 1;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"BC14 Migration Runner", 'OnAfterMigrateRecord', '', false, false)]
    local procedure HandleOnAfterMigrateRecord(MigratorName: Text[250]; var SourceRecordRef: RecordRef)
    begin
        RecordsMigratedCount += 1;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"BC14 Migration Runner", 'OnMigrateRecordFailed', '', false, false)]
    local procedure HandleOnMigrateRecordFailed(MigratorName: Text[250]; var SourceRecordRef: RecordRef; ErrorMessage: Text)
    begin
        RecordsFailedCount += 1;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"BC14 Migration Runner", 'OnAfterRunMigrator', '', false, false)]
    local procedure HandleOnAfterRunMigrator(MigratorName: Text[250]; Success: Boolean; RecordCount: Integer)
    begin
        if not MigratorCompletedList.Contains(MigratorName) then
            MigratorCompletedList.Add(MigratorName);
    end;
}
