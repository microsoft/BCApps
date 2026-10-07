// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

/// <summary>
/// Runs all Historical migrators in a background session.
/// Dispatched by the Runner so the main migration flow can continue to Posting without waiting.
/// After all Historical migrators finish, this worker finalizes the migration status to Completed.
/// </summary>
codeunit 46864 "BC14 Historical Task Worker"
{
    Access = Internal;

    var
        BC14Telemetry: Codeunit "BC14 Telemetry";

    trigger OnRun()
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        BC14MigrationRunner: Codeunit "BC14 Migration Runner";
        BC14MigrationOrchestrator: Codeunit "BC14 Migration Orchestrator";
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
        WorkerRunId: Guid;
        AllSuccess: Boolean;
    begin
        Session.LogMessage('0000TTT', HistoricalAsyncStartedLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());

        // Snapshot the run id so a rerun (which bumps the id) can supersede this worker.
        WorkerRunId := BC14CompanySettings.GetHistoricalRunId();

        // A null run id means the dispatch row was never properly initialized (or was cleared
        // out-of-band). Without a valid id the TOCTOU guard in TrySetHistoricalCompleted would
        // wrongly match another null on the row, so refuse to run and let a fresh dispatch own
        // the state transition.
        if IsNullGuid(WorkerRunId) then begin
            Session.LogMessage('0000TXE', HistoricalNullRunIdMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());
            exit;
        end;

        Session.LogMessage('0000TXF', StrSubstNo(HistoricalWorkerContextLbl, CopyStr(CompanyName(), 1, 30), Format(WorkerRunId)), Verbosity::Normal, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());

        // Early-exit: if the main flow already failed for this company, do not run Historical migrations at all.
        if BC14StatusMgr.IsCompanyFailed(CopyStr(CompanyName(), 1, 30)) then begin
            if not BC14CompanySettings.TryClearHistoricalDispatched(WorkerRunId) then
                Session.LogMessage('0000TXG', HistoricalAbandonedMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory())
            else
                Commit();
            Session.LogMessage('0000TXH', HistoricalAbortedDueMainFailureMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());
            // This worker may be the last code path running for this company; flip the overall
            // Summary if every company is now in a terminal state. Idempotent / no-op otherwise.
            BC14MigrationOrchestrator.TryFinalizeOverallUpgrade();
            exit;
        end;

        BC14CompanySettings.SetMigrationState("BC14 Migration Step"::Historical);
        Commit();

        AllSuccess := BC14MigrationRunner.RunHistoricalMigrations();
        Session.LogMessage('0000TXI', StrSubstNo(HistoricalRunReturnedLbl, AllSuccess, CopyStr(CompanyName(), 1, 30), Format(WorkerRunId)), Verbosity::Normal, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());

        if not AllSuccess then begin
            if not HandleHistoricalFailure(WorkerRunId) then begin
                Session.LogMessage('0000TXJ', HistoricalAbandonedMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());
                BC14MigrationOrchestrator.TryFinalizeOverallUpgrade();
                exit;
            end;
            Session.LogMessage('0000TXK', StrSubstNo(HistoricalMarkedFailedLbl, CopyStr(CompanyName(), 1, 30), Format(WorkerRunId)), Verbosity::Warning, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());
            BC14MigrationOrchestrator.TryFinalizeOverallUpgrade();
            exit;
        end;

        if not BC14CompanySettings.TrySetHistoricalCompleted(WorkerRunId) then begin
            Session.LogMessage('0000TTW', HistoricalAbandonedMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());
            BC14MigrationOrchestrator.TryFinalizeOverallUpgrade();
            exit;
        end;
        Commit();
        Session.LogMessage('0000TXL', StrSubstNo(HistoricalMarkedCompletedLbl, CopyStr(CompanyName(), 1, 30), Format(WorkerRunId)), Verbosity::Normal, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());

        BC14MigrationRunner.TryFinalizeCompanyMigration();

        // If this was the last company to fully complete, finalize the overall status.
        BC14MigrationOrchestrator.TryFinalizeOverallUpgrade();

        Session.LogMessage('0000TTX', StrSubstNo(HistoricalAsyncCompletedLbl, AllSuccess), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());
    end;

    local procedure HandleHistoricalFailure(WorkerRunId: Guid): Boolean
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
    begin
        if not BC14CompanySettings.TryMarkHistoricalFailed(WorkerRunId, HistoricalDataIncompleteLbl) then begin
            Session.LogMessage('0000TXM', StrSubstNo(HistoricalFailureSupersededLbl, CopyStr(CompanyName(), 1, 30), Format(WorkerRunId)), Verbosity::Warning, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());
            exit(false);
        end;
        BC14StatusMgr.MarkCompanyFailed(CopyStr(CompanyName(), 1, 30), HistoricalDataIncompleteLbl);
        Session.LogMessage('0000TXN', StrSubstNo(CompanyMarkedFailedAfterHistoricalLbl, CopyStr(CompanyName(), 1, 30), Format(WorkerRunId)), Verbosity::Warning, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());
        Commit();
        exit(true);
    end;

    var
        HistoricalAsyncStartedLbl: Label 'Historical migration (async) started.', Locked = true;
        HistoricalAsyncCompletedLbl: Label 'Historical migration (async) completed. All success: %1', Locked = true, Comment = '%1 = All success';
        HistoricalAbandonedMsg: Label 'Historical worker abandoned: generation token changed (rerun superseded this worker).', Locked = true;
        HistoricalNullRunIdMsg: Label 'Historical worker exited: snapshot run id was a null guid (dispatch state not initialized).', Locked = true;
        HistoricalAbortedDueMainFailureMsg: Label 'Historical worker finished but main migration already failed for this company; skipping HistoricalCompleted to allow clean rerun.', Locked = true;
        HistoricalWorkerContextLbl: Label 'Historical worker context: company=%1, run id=%2.', Locked = true, Comment = '%1 = Company name, %2 = Historical run id';
        HistoricalRunReturnedLbl: Label 'Historical migrations returned. All success: %1, company=%2, run id=%3.', Locked = true, Comment = '%1 = All success, %2 = Company name, %3 = Historical run id';
        HistoricalMarkedCompletedLbl: Label 'Historical marked completed in settings table. company=%1, run id=%2.', Locked = true, Comment = '%1 = Company name, %2 = Historical run id';
        HistoricalMarkedFailedLbl: Label 'Historical marked failed in settings table (company is NOT marked failed). company=%1, run id=%2.', Locked = true, Comment = '%1 = Company name, %2 = Historical run id';
        HistoricalDataIncompleteLbl: Label 'One or more historical migrators reported errors; archive data may be incomplete.', Locked = true;
        HistoricalFailureSupersededLbl: Label 'Historical failure not recorded: run id mismatch (worker superseded by rerun). company=%1, run id=%2.', Locked = true, Comment = '%1 = Company name, %2 = Historical run id';
        CompanyMarkedFailedAfterHistoricalLbl: Label 'Hybrid Company Status transitioned to Failed after historical migration errors. company=%1, run id=%2.', Locked = true, Comment = '%1 = Company name, %2 = Historical run id';
}
