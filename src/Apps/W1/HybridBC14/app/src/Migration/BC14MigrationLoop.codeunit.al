// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using System.Integration;

/// <summary>
/// Shared per-record migration loop used by individual migrators. Centralizes the
/// "iterate source buffer, invoke per-record codeunit, log success/error, honor
/// stop-on-first-error" pattern so each migrator only has to declare its source
/// RecordRef, key field, and per-record codeunit.
/// </summary>
codeunit 46855 "BC14 Migration Loop"
{
    Access = Internal;

    /// <summary>
    /// Runs the standard per-record migration loop over the supplied source RecordRef.
    /// Caller is responsible for opening and (optionally) filtering the RecordRef.
    /// The loop terminates early when Stop-On-First-Transformation-Error is enabled and
    /// a record fails; otherwise it processes all records and returns the aggregate
    /// success flag (false if any record failed).
    /// </summary>
    /// <param name="MigratorName">Display name used in error logs.</param>
    /// <param name="SourceRecord">A Variant wrapping the source Record. Caller may apply
    /// filters on the underlying record before passing it in; the helper preserves and uses
    /// those filters when iterating.</param>
    /// <param name="KeyFieldNo">Field number whose value uniquely identifies the record
    /// and is persisted as the idempotency key. Pass 0 to use the RecordId as the key
    /// (use this only for tables with composite/multi-field primary keys).</param>
    /// <param name="MigratorCodeunitId">Per-record codeunit. Must declare TableNo equal
    /// to the source record's table.</param>
    /// <returns>True if every record migrated successfully; false if any failed.</returns>
    procedure RunRecordLoop(MigratorName: Text[250]; var SourceRecord: Variant; KeyFieldNo: Integer; MigratorCodeunitId: Integer): Boolean
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        BC14RecordTracker: Codeunit "BC14 Migration Record Tracker";
        BC14Telemetry: Codeunit "BC14 Telemetry";
        RetryRecordId: RecordId;
        SourceRecRef: RecordRef;
        FailedRecordIds: List of [RecordId];
        SourceTableId: Integer;
        SourceTableName: Text[250];
        AggregateSuccess: Boolean;
        TotalCount: Integer;
        SuccessCount: Integer;
        FailureCount: Integer;
        StopOnFirstError: Boolean;
        JumpedToFailure: Boolean;
        RetryFromErrorLog: Boolean;
        EarlyExit: Boolean;
    begin
        AggregateSuccess := true;
        SourceRecRef.GetTable(SourceRecord);
        SourceTableId := SourceRecRef.Number;
        SourceTableName := BC14RecordTracker.GetTableNameById(SourceTableId);
        TotalCount := SourceRecRef.Count();

        BC14CompanySettings.GetSingleInstance();
        StopOnFirstError := BC14CompanySettings.GetStopOnFirstTransformationError();
        if not StopOnFirstError then
            RetryFromErrorLog := CollectFailedRecordIds(SourceTableId, FailedRecordIds);

        Session.LogMessage('0000TX6', StrSubstNo(LoopStartedLbl, MigratorName, SourceTableName, TotalCount, StopOnFirstError, JumpedToFailure, RetryFromErrorLog, FailedRecordIds.Count()), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());

        case true of
            StopOnFirstError:
                if PositionAtSavedFailure(SourceRecRef, SourceTableId, JumpedToFailure) then
                    repeat
                        if not ProcessOneRecord(MigratorName, MigratorCodeunitId, KeyFieldNo, SourceTableId, SourceTableName, SourceRecRef, SourceRecord, BC14RecordTracker, SuccessCount, FailureCount, AggregateSuccess, EarlyExit) then
                            break;
                    until SourceRecRef.Next() = 0;
            RetryFromErrorLog:
                foreach RetryRecordId in FailedRecordIds do
                    if SourceRecRef.Get(RetryRecordId) then
                        if not ProcessOneRecord(MigratorName, MigratorCodeunitId, KeyFieldNo, SourceTableId, SourceTableName, SourceRecRef, SourceRecord, BC14RecordTracker, SuccessCount, FailureCount, AggregateSuccess, EarlyExit) then
                            break;
            else
                if SourceRecRef.FindSet() then
                    repeat
                        if not ProcessOneRecord(MigratorName, MigratorCodeunitId, KeyFieldNo, SourceTableId, SourceTableName, SourceRecRef, SourceRecord, BC14RecordTracker, SuccessCount, FailureCount, AggregateSuccess, EarlyExit) then
                            break;
                    until SourceRecRef.Next() = 0;
        end;

        Session.LogMessage('0000TZ1', StrSubstNo(LoopCompletedLbl, MigratorName, SourceTableName, TotalCount, SuccessCount, FailureCount, StopOnFirstError, RetryFromErrorLog, EarlyExit), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());

        exit(AggregateSuccess);
    end;

    local procedure ProcessOneRecord(MigratorName: Text[250]; MigratorCodeunitId: Integer; KeyFieldNo: Integer; SourceTableId: Integer; SourceTableName: Text[250]; var SourceRecRef: RecordRef; var SourceRecord: Variant; var BC14RecordTracker: Codeunit "BC14 Migration Record Tracker"; var SuccessCount: Integer; var FailureCount: Integer; var AggregateSuccess: Boolean; var EarlyExit: Boolean): Boolean
    var
        RecordKey: Text[250];
        RunSuccess: Boolean;
        MigratorSuccess: Boolean;
    begin
        SourceRecRef.SetTable(SourceRecord);
        RecordKey := GetRecordKey(SourceRecRef, KeyFieldNo);
        Commit();
        RunSuccess := Codeunit.Run(MigratorCodeunitId, SourceRecord);
        if not BC14RecordTracker.LogMigrateResult(
            MigratorName, SourceTableId, SourceTableName,
            RecordKey, SourceRecRef.RecordId,
            RunSuccess, MigratorSuccess)
        then begin
            FailureCount += 1;
            AggregateSuccess := false;
            EarlyExit := true;
            exit(false);
        end;
        if MigratorSuccess then
            SuccessCount += 1
        else begin
            FailureCount += 1;
            AggregateSuccess := false;
        end;
        exit(true);
    end;

    local procedure CollectFailedRecordIds(SourceTableId: Integer; var FailedRecordIds: List of [RecordId]): Boolean
    var
        DataMigrationError: Record "Data Migration Error";
    begin
        DataMigrationError.SetRange("Source Table ID", SourceTableId);
        DataMigrationError.SetRange("Error Dismissed", false);
        if not DataMigrationError.FindSet() then
            exit(false);
        repeat
            if Format(DataMigrationError."Source Staging Table Record ID") <> '' then
                FailedRecordIds.Add(DataMigrationError."Source Staging Table Record ID");
        until DataMigrationError.Next() = 0;
        exit(FailedRecordIds.Count() > 0);
    end;

    var
        LoopStartedLbl: Label 'Business Central 14 migration loop started. Migrator=%1, Source=%2, TotalRecords=%3, StopOnFirstError=%4, JumpedToFailure=%5, RetryFromErrorLog=%6, RetryCount=%7.', Locked = true, Comment = '%1 = Migrator name, %2 = Source table name, %3 = Total record count, %4 = Stop-on-first-error mode flag, %5 = Whether the stop-mode rerun jumped to a previously saved failure record, %6 = Whether continue-mode is iterating only previously failed records from the error log, %7 = Number of failed records being retried in continue mode';
        LoopCompletedLbl: Label 'Business Central 14 migration loop completed. Migrator=%1, Source=%2, Total=%3, Succeeded=%4, Failed=%5, StopOnFirstError=%6, RetryFromErrorLog=%7, EarlyExit=%8.', Locked = true, Comment = '%1 = Migrator name, %2 = Source table name, %3 = Total, %4 = Success count, %5 = Failure count, %6 = Stop-on-first-error mode flag, %7 = Whether continue-mode iterated only previously failed records from the error log, %8 = Early exit flag';

    local procedure GetRecordKey(var SourceRecRef: RecordRef; KeyFieldNo: Integer): Text[250]
    var
        KeyFieldRef: FieldRef;
    begin
        if KeyFieldNo = 0 then
            exit(CopyStr(Format(SourceRecRef.RecordId), 1, 250));
        KeyFieldRef := SourceRecRef.Field(KeyFieldNo);
        exit(CopyStr(Format(KeyFieldRef.Value), 1, 250));
    end;

    local procedure PositionAtSavedFailure(var SourceRecRef: RecordRef; SourceTableId: Integer; var JumpedToFailure: Boolean): Boolean
    var
        DataMigrationError: Record "Data Migration Error";
    begin
        JumpedToFailure := false;
        DataMigrationError.SetRange("Source Table ID", SourceTableId);
        DataMigrationError.SetRange("Error Dismissed", false);
        if not DataMigrationError.FindLast() then
            exit(SourceRecRef.FindSet());
        if Format(DataMigrationError."Source Staging Table Record ID") = '' then
            exit(SourceRecRef.FindSet());
        if not SourceRecRef.Get(DataMigrationError."Source Staging Table Record ID") then
            exit(SourceRecRef.FindSet());
        JumpedToFailure := true;
        exit(true);
    end;
}
