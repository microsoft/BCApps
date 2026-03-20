// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;

using Microsoft.DataMigration;
using Microsoft.Utilities;

codeunit 50153 "BC14 Cloud Migration"
{
    TableNo = "Hybrid Replication Summary";

    trigger OnRun();
    var
        BC14CompanySettings: Record "BC14CompanyMigrationSettings";
        BC14Management: Codeunit "BC14 Management";
        BC14HelperFunctions: Codeunit "BC14 Helper Functions";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        BC14HandleUpgradeError: Codeunit "BC14 Handle Upgrade Error";
        Success: Boolean;
    begin
        // Update Start Time to reflect when this upgrade attempt started
        // Clear End Time when starting a new attempt
        Rec.Find();
        Rec."Start Time" := CurrentDateTime();
        Rec."End Time" := 0DT;
        Rec.Status := Rec.Status::UpgradeInProgress;
        Rec.Modify();
        Commit();

        BC14MigrationErrorHandler.ClearErrorOccurred();

        ClearLastError();
        OnUpgradeBC14Company(Success);

        if not Success then begin
            BC14HandleUpgradeError.MarkUpgradeFailed(Rec);
            BC14HelperFunctions.LogLastError();
            BC14MigrationErrorHandler.ClearErrorOccurred();
            Commit();

            // If Stop On First Error is enabled, don't chain to next company.
            // MarkUpgradeFailed already set the status correctly.
            // Do NOT call Error() here — it would trigger the TaskScheduler error handler
            // (BC14 Handle Upgrade Error) which calls MarkUpgradeFailed a second time,
            // overwriting the precise error details with a generic message.
            BC14CompanySettings.GetSingleInstance();
            if BC14CompanySettings.GetStopOnFirstTransformationError() then begin
                FinalizeReplicationSummary(Rec);
                exit;
            end;
        end;

        // Chain to next pending company — orchestration delegated to Management
        if BC14Management.TryChainToNextPendingCompany(Rec) then
            exit;

        // No more pending companies — finalize the overall run status
        FinalizeReplicationSummary(Rec);
    end;

    local procedure FinalizeReplicationSummary(var HybridReplicationSummary: Record "Hybrid Replication Summary")
    var
        BC14CompanySettings: Record "BC14CompanyMigrationSettings";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        BC14HandleUpgradeError: Codeunit "BC14 Handle Upgrade Error";
        BC14HelperFunctions: Codeunit "BC14 Helper Functions";
    begin
        if not HybridReplicationSummary.Find() then begin
            Session.LogMessage('0000RO0', ReplicationSummaryNotFoundMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14HelperFunctions.GetTelemetryCategory());
            exit;
        end;

        if HybridReplicationSummary.Status = HybridReplicationSummary.Status::UpgradeFailed then begin
            Session.LogMessage('0000RO1', UpgradeAlreadyFailedMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14HelperFunctions.GetTelemetryCategory());
            exit;
        end;

        if HybridReplicationSummary.Status = HybridReplicationSummary.Status::Failed then begin
            Session.LogMessage('0000RO2', ReplicationFailedMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14HelperFunctions.GetTelemetryCategory());
            exit;
        end;

        if BC14MigrationErrorHandler.ErrorOccurredDuringLastUpgrade() then begin
            BC14HandleUpgradeError.MarkUpgradeFailed(HybridReplicationSummary);
            exit;
        end;

        BC14CompanySettings.GetSingleInstance();
        if BC14CompanySettings.IsMigrationPaused() then begin
            HybridReplicationSummary.Status := HybridReplicationSummary.Status::UpgradeFailed;
            HybridReplicationSummary."End Time" := CurrentDateTime();
            HybridReplicationSummary.Modify();
            exit;
        end;

        HybridReplicationSummary.Status := HybridReplicationSummary.Status::Completed;
        HybridReplicationSummary."End Time" := CurrentDateTime();
        HybridReplicationSummary.Modify();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"BC14 Cloud Migration", 'OnUpgradeBC14Company', '', false, false)]
    local procedure HandleOnUpgradeBC14Company(var Success: Boolean)
    var
        BC14MigrationErrors: Record "BC14 Migration Errors";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        BC14HelperFunctions: Codeunit "BC14 Helper Functions";
        UnhandledErrorText: Text;
    begin
        ClearLastError();
        // Wrap in TryFunction to catch any unhandled errors that escape the Runner's
        // record-level TryFunction protection (e.g., errors in IsRecordMigrated, field length
        // mismatches, or unexpected runtime errors). Without this, such errors propagate to
        // the Hybrid framework and appear only in the Management page, but NOT in the
        // BC14 Migration Errors page — making them invisible to the user.
        if not TryUpgradeBC14Company() then begin
            UnhandledErrorText := GetLastErrorText();
            Session.LogMessage('0000ROV', StrSubstNo(UnhandledMigrationErrorLbl, UnhandledErrorText), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14HelperFunctions.GetTelemetryCategory());
            BC14MigrationErrorHandler.LogError('BC14 Cloud Migration', 0, '', '', 0, UnhandledErrorText, BC14MigrationErrors.RecordId);
            Success := false;
            exit;
        end;
        Success := not BC14MigrationErrorHandler.GetErrorOccurred();
    end;

    [TryFunction]
    local procedure TryUpgradeBC14Company()
    begin
        UpgradeBC14Company();
    end;

    /// <summary>
    /// Upgrades the current company from BC14 format to the current version.
    /// This procedure checks if the company setup is completed before initiating migration.
    /// </summary>
    /// <remarks>
    /// Prerequisites:
    /// - Company must exist in Assisted Company Setup Status
    /// - Company setup status must be Completed
    /// </remarks>
    internal procedure UpgradeBC14Company()
    var
        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
        HybridCompanyStatus: Record "Hybrid Company Status";
        BC14CompanySettings: Record "BC14CompanyMigrationSettings";
        BC14HelperFunctions: Codeunit "BC14 Helper Functions";
        SetupStatus: Enum "Company Setup Status";
        MigrationRan: Boolean;
    begin
        MigrationRan := false;
        if AssistedCompanySetupStatus.Get(CompanyName()) then begin
            SetupStatus := AssistedCompanySetupStatus.GetCompanySetupStatusValue(CopyStr(CompanyName(), 1, 30));
            if SetupStatus = SetupStatus::Completed then begin
                InitiateBC14Migration();
                MigrationRan := true;
            end else
                Session.LogMessage('0000RO3', CompanyFailedToMigrateMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14HelperFunctions.GetTelemetryCategory());
        end;

        Commit();

        // Don't mark as Completed if migration never ran (company setup not completed)
        if not MigrationRan then
            exit;

        // Only mark as Completed if migration is not paused
        BC14CompanySettings.GetSingleInstance();
        if BC14CompanySettings.IsMigrationPaused() then
            exit;  // Don't mark as Completed when paused - user needs to fix errors and continue

        if HybridCompanyStatus.Get(CompanyName) then begin
            HybridCompanyStatus."Upgrade Status" := HybridCompanyStatus."Upgrade Status"::Completed;
            HybridCompanyStatus.Modify();
        end;
    end;

    /// <summary>
    /// Initiates the BC14 migration process for the current company.
    /// Runs the complete migration pipeline: Setup -> Master -> Transactions -> Historical -> Post Journals.
    /// </summary>
    /// <remarks>
    /// This procedure:
    /// 1. Runs pre-migration cleanup
    /// 2. Adjusts GL Setup if needed
    /// 3. Creates pre-migration data (extension point)
    /// 4. Executes the migration runner
    /// 5. Creates post-migration data (extension point)
    /// 
    /// The procedure uses Commit() at specific points to ensure data consistency
    /// and allow for partial recovery in case of failures.
    /// </remarks>
    local procedure InitiateBC14Migration()
    var
        BC14CompanySettings: Record "BC14CompanyMigrationSettings";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        BC14HelperFunctions: Codeunit "BC14 Helper Functions";
        BC14MigrationRunner: Codeunit "BC14 Migration Runner";
    begin
        Session.LogMessage('0000RO4', InitiateMigrationMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14HelperFunctions.GetTelemetryCategory());

        BC14CompanySettings.GetSingleInstance();

        // If migration was already started (e.g., a previous run that partially completed or failed),
        // skip the one-time initialization steps and go straight to the Runner.
        // The Runner's own Pause/Resume and BC14MigrationRecordStatus logic will handle skipping
        // already-migrated records and resuming from the correct phase.
        if BC14CompanySettings.IsDataMigrationStarted() then begin
            if BC14CompanySettings.GetMigrationState() = "BC14 Migration State"::Completed then
                // In Continue On Error mode, state is Completed even if some records failed.
                // Only skip if there are truly no unresolved errors left.
                if not BC14MigrationErrorHandler.ErrorOccurredDuringLastUpgrade() then begin
                    Session.LogMessage('0000RO5', MigrationAlreadyStartedSkippingMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14HelperFunctions.GetTelemetryCategory());
                    exit;
                end;

            // Previous run did not complete — re-run the Runner to continue/retry
            Session.LogMessage('0000ROW', MigrationRerunMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14HelperFunctions.GetTelemetryCategory());
            BC14HelperFunctions.SetProcessesRunning(true);
            BC14MigrationRunner.RunMigration();
            BC14HelperFunctions.CreatePostMigrationData();
            BC14HelperFunctions.SetProcessesRunning(false);
            exit;
        end;

        SelectLatestVersion();
        BC14HelperFunctions.SetProcessesRunning(true);

        BC14HelperFunctions.RunPreMigrationCleanup();
        // Commit required: Persist cleanup before migration starts
        Commit();

        // Pre-migration data creation (extension point)
        if not BC14HelperFunctions.CreatePreMigrationData() then begin
            BC14HelperFunctions.LogLastError();
            BC14HelperFunctions.SetProcessesRunning(false);
            exit;
        end;
        // Commit required: Persist pre-migration data before main migration
        Commit();

        // Mark that data migration has started for this company
        BC14CompanySettings.GetSingleInstance();
        BC14CompanySettings.SetDataMigrationStarted();

        // Run the migration (Setup -> Master -> Transactions -> Historical -> Post Journals)
        Session.LogMessage('0000RO6', StartMigrationMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14HelperFunctions.GetTelemetryCategory());
        BC14MigrationRunner.RunMigration();

        // Post-migration data creation (extension point)
        BC14HelperFunctions.CreatePostMigrationData();

        BC14HelperFunctions.SetProcessesRunning(false);
    end;

    /// <summary>
    /// Integration event raised when upgrading a BC14 company.
    /// Subscribe to this event to provide custom upgrade logic or to extend the default upgrade behavior.
    /// </summary>
    /// <param name="Success">Set to false if the upgrade encountered errors. The default handler sets this based on error occurrence.</param>
    [IntegrationEvent(false, false, true)]
    internal procedure OnUpgradeBC14Company(var Success: Boolean)
    begin
    end;

    var
        CompanyFailedToMigrateMsg: Label 'Migration did not start because the company setup is still in process.', Locked = true;
        InitiateMigrationMsg: Label 'Initiating BC14 Migration for company.', Locked = true;
        MigrationAlreadyStartedSkippingMsg: Label 'Migration has already been started for this company. Skipping to prevent duplicate data.', Locked = true;
        MigrationRerunMsg: Label 'Previous migration did not complete. Re-running migration runner to continue/retry.', Locked = true;
        StartMigrationMsg: Label 'Starting BC14 data migration: Setup -> Master -> Transactions -> Historical -> Post Journals.', Locked = true;
        ReplicationSummaryNotFoundMsg: Label 'Hybrid Replication Summary record not found. Exiting upgrade process.', Locked = true;
        UpgradeAlreadyFailedMsg: Label 'Upgrade status is already UpgradeFailed. Skipping further processing.', Locked = true;
        ReplicationFailedMsg: Label 'Replication status is Failed. Skipping upgrade completion.', Locked = true;
        UnhandledMigrationErrorLbl: Label 'Unhandled migration error: %1', Locked = true, Comment = '%1 = Error message';

}
