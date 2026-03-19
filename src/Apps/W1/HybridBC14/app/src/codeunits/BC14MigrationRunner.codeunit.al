// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;

using Microsoft.DataMigration;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;

codeunit 50175 "BC14 Migration Runner"
{
    var
        MigrationStartedMsg: Label 'Migration started for company %1.', Comment = '%1 = Company Name';
        MigrationCompletedMsg: Label 'Migration completed for company %1. Total errors: %2.', Comment = '%1 = Company Name, %2 = Error Count';
        MigrationPausedMsg: Label 'Migration paused for company %1 due to error in %2. Fix the error and use Continue Migration.', Comment = '%1 = Company Name, %2 = Migrator Name';
        MigrationResumedMsg: Label 'Migration resumed for company %1 from %2 phase.', Comment = '%1 = Company Name, %2 = Phase Name';
        StopOnFirstErrorEnabledLbl: Label 'Stop On First Error is enabled. Migration will halt on first error.', Locked = true;
        ContinueOnErrorEnabledLbl: Label 'Continue On Error is enabled. Migration will collect all errors.', Locked = true;
        CleanedInvalidJournalLinesLbl: Label 'Cleaned up %1 invalid journal lines (Amount = 0)', Locked = true, Comment = '%1 = Count';
        CleanedEmptyBalAccountLbl: Label 'Cleaned up %1 journal lines with empty Bal. Account No.', Locked = true, Comment = '%1 = Count';
        JournalPostingLbl: Label 'Journal Posting - %1', Locked = true, Comment = '%1 = Batch Name';
        JournalBatchInfoLbl: Label 'Template=%1, Batch=%2', Locked = true, Comment = '%1 = Template, %2 = Batch';
        PostMigrationJournalsCompletedLbl: Label 'PostMigrationJournals completed. Posted %1 batches.', Locked = true, Comment = '%1 = Count';
        EnabledDirectPostingLbl: Label 'Enabled Direct Posting on %1 G/L Accounts for migration', Locked = true, Comment = '%1 = Count';
        PostMigrationJournalsSkippedLbl: Label 'PostMigrationJournals skipped - Skip Posting enabled', Locked = true;
        ValidationFailedLbl: Label 'Pre-migration validation failed: %1', Locked = true, Comment = '%1 = Error message';
        MigrationPhaseCompletedLbl: Label 'Migration phase %1 completed.', Locked = true, Comment = '%1 = Phase Name';
        UnresolvedErrorsWarningMsg: Label 'There are %1 unresolved migration errors. These records will be retried.\Do you want to continue?', Comment = '%1 = Error count';
        MigrationRecordStatusCleanedUpLbl: Label 'Cleaned up BC14 Migration Record Status table: %1 records deleted.', Locked = true, Comment = '%1 = Count';
        CurrentMigratorName: Text[100];
        SuppressConfirmations: Boolean;
        SkipPostingOnRetry: Boolean;
        RecordsSinceLastCommit: Integer;
        CommitIntervalSize: Integer;

    procedure RunMigration()
    var
        BC14CompanySettings: Record "BC14CompanyMigrationSettings";
        BC14HelperFunctions: Codeunit "BC14 Helper Functions";
        LastCompletedPhase: Enum "BC14 Migration State";
        StartPhase: Enum "BC14 Migration State";
        StopOnFirstError: Boolean;
        CanProceed: Boolean;
        ValidationErrorMessage: Text;
        UnresolvedErrorCount: Integer;
    begin
        // Pre-migration validation hook - allows extensions to validate before migration starts
        CanProceed := true;
        ValidationErrorMessage := '';
        OnValidateBeforeMigration(CanProceed, ValidationErrorMessage);
        if not CanProceed then begin
            Session.LogMessage('0000ROA', StrSubstNo(ValidationFailedLbl, ValidationErrorMessage), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14HelperFunctions.GetTelemetryCategory());
            Error(ValidationErrorMessage);
        end;

        // Check for unresolved errors and warn user
        UnresolvedErrorCount := GetTotalErrorCount();
        if (UnresolvedErrorCount > 0) and (not SuppressConfirmations) then
            if not Confirm(UnresolvedErrorsWarningMsg, true, UnresolvedErrorCount) then
                exit;

        BC14CompanySettings.GetSingleInstance();
        StopOnFirstError := BC14CompanySettings.GetStopOnFirstTransformationError();
        LastCompletedPhase := BC14CompanySettings.GetLastCompletedPhase();

        // Determine start phase - resume from last completed or start fresh
        // Migrators handle their own record-level skipping, so we just need phase-level resume
        if BC14CompanySettings.IsMigrationPaused() then begin
            StartPhase := GetNextPhase(LastCompletedPhase);
            Session.LogMessage('0000ROK', StrSubstNo(MigrationResumedMsg, CompanyName(), Format(StartPhase)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14HelperFunctions.GetTelemetryCategory());
        end else begin
            BC14CompanySettings.SetDataMigrationStarted();
            StartPhase := "BC14 Migration State"::Setup;
            Session.LogMessage('0000ROD', StrSubstNo(MigrationStartedMsg, CompanyName()), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14HelperFunctions.GetTelemetryCategory());
        end;

        if StopOnFirstError then
            Session.LogMessage('0000ROB', StopOnFirstErrorEnabledLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14HelperFunctions.GetTelemetryCategory())
        else
            Session.LogMessage('0000ROC', ContinueOnErrorEnabledLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14HelperFunctions.GetTelemetryCategory());

        CommitIntervalSize := 1000;
        RecordsSinceLastCommit := 0;

        BC14CompanySettings.SetMigrationState(StartPhase);
        RunMigrationFromPhase(StartPhase, StopOnFirstError);
    end;

    local procedure GetNextPhase(CurrentPhase: Enum "BC14 Migration State"): Enum "BC14 Migration State"
    begin
        case CurrentPhase of
            "BC14 Migration State"::NotStarted,
            "BC14 Migration State"::Paused:
                exit("BC14 Migration State"::Setup);
            "BC14 Migration State"::Setup:
                exit("BC14 Migration State"::Master);
            "BC14 Migration State"::Master:
                exit("BC14 Migration State"::Transaction);
            "BC14 Migration State"::Transaction:
                exit("BC14 Migration State"::Historical);
            "BC14 Migration State"::Historical:
                exit("BC14 Migration State"::Posting);
            "BC14 Migration State"::Posting,
            "BC14 Migration State"::Completed:
                exit("BC14 Migration State"::Completed);
            else
                exit("BC14 Migration State"::Setup);
        end;
    end;

    /// <summary>
    /// Continues a paused migration from where it stopped.
    /// With record-level skip support, this is now equivalent to RunMigration.
    /// Kept for backward compatibility.
    /// </summary>
    procedure ContinueMigration()
    begin
        RunMigration();
    end;

    local procedure RunMigrationFromPhase(StartPhase: Enum "BC14 Migration State"; StopOnFirstError: Boolean)
    var
        BC14CompanySettings: Record "BC14CompanyMigrationSettings";
        BC14HelperFunctions: Codeunit "BC14 Helper Functions";
        TotalErrors: Integer;
        AllBatchesPosted: Boolean;
    begin
        if StartPhase = "BC14 Migration State"::Completed then
            exit;

        if not ExecuteMigrationPhase(StartPhase, "BC14 Migration State"::Setup, StopOnFirstError) then
            exit;

        if not ExecuteMigrationPhase(StartPhase, "BC14 Migration State"::Master, StopOnFirstError) then
            exit;

        // Enable Direct Posting on all G/L Accounts before Transaction phase.
        // Transaction migrators (e.g., G/L Entry) create journal lines that Validate "Account No.",
        // which checks Direct Posting. Must be enabled before journal lines are created, not just before posting.
        EnableDirectPostingOnAllAccounts();

        if not ExecuteMigrationPhase(StartPhase, "BC14 Migration State"::Transaction, StopOnFirstError) then
            exit;

        if not ExecuteMigrationPhase(StartPhase, "BC14 Migration State"::Historical, StopOnFirstError) then
            exit;

        // Skip posting if it was already completed in a previous run.
        // In Stop On First Error mode, posting may not have been reached, so it must still run.
        if SkipPostingOnRetry then begin
            BC14CompanySettings.SetMigrationState("BC14 Migration State"::Completed);
            BC14CompanySettings.SetMigrationPhaseCompleted("BC14 Migration State"::Completed, '');
            TotalErrors := GetTotalErrorCount();
            Session.LogMessage('0000ROE', StrSubstNo(MigrationCompletedMsg, CompanyName(), TotalErrors), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14HelperFunctions.GetTelemetryCategory());
            exit;
        end;

        // Post all migration journal batches (unless skipped)
        BC14CompanySettings.SetMigrationState("BC14 Migration State"::Posting);
        AllBatchesPosted := PostMigrationJournals();

        // Mark migration as completed
        BC14CompanySettings.SetMigrationState("BC14 Migration State"::Completed);

        // Only set LastCompletedPhase to Completed if all journal batches posted successfully.
        // If any batch failed, keep LastCompletedPhase at Historical so that RetryFailedRecords
        // will re-attempt posting (SkipPostingOnRetry will be false).
        // Also keep status records so rerun can correctly skip already-migrated records
        // and avoid creating duplicate journal lines.
        if AllBatchesPosted then begin
            BC14CompanySettings.SetMigrationPhaseCompleted("BC14 Migration State"::Completed, '');
            CleanupMigrationRecordStatus();
        end else
            BC14CompanySettings.SetMigrationPhaseCompleted("BC14 Migration State"::Historical, '');

        TotalErrors := GetTotalErrorCount();
        Session.LogMessage('0000ROE', StrSubstNo(MigrationCompletedMsg, CompanyName(), TotalErrors), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14HelperFunctions.GetTelemetryCategory());
    end;

    local procedure ExecuteMigrationPhase(StartPhase: Enum "BC14 Migration State"; Phase: Enum "BC14 Migration State"; StopOnFirstError: Boolean): Boolean
    var
        BC14CompanySettings: Record "BC14CompanyMigrationSettings";
        BC14HelperFunctions: Codeunit "BC14 Helper Functions";
        PhaseStepNo: Integer;
        PhaseSuccess: Boolean;
    begin
        if StartPhase.AsInteger() > Phase.AsInteger() then
            exit(true);

        BC14CompanySettings.SetMigrationState(Phase);

        PhaseSuccess := RunPhaseMigrators(Phase, StopOnFirstError);
        if (not PhaseSuccess) and StopOnFirstError then begin
            BC14CompanySettings.PauseMigration(CurrentMigratorName);
            if not SuppressConfirmations then
                Message(MigrationPausedMsg, CompanyName(), CurrentMigratorName);
            exit(false);
        end;

        PhaseStepNo := Phase.AsInteger();
        BC14CompanySettings.SetMigrationPhaseCompleted(Phase, '');
        Session.LogMessage('0000ROL', StrSubstNo(MigrationPhaseCompletedLbl, Format(PhaseStepNo)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14HelperFunctions.GetTelemetryCategory(), 'StepNo', Format(PhaseStepNo));
        exit(true);
    end;

    local procedure RunPhaseMigrators(Phase: Enum "BC14 Migration State"; StopOnFirstError: Boolean): Boolean
    begin
        case Phase of
            "BC14 Migration State"::Setup:
                exit(RunSetupMigrations(StopOnFirstError));
            "BC14 Migration State"::Master:
                exit(RunMasterMigrations(StopOnFirstError));
            "BC14 Migration State"::Transaction:
                exit(RunTransactionMigrations(StopOnFirstError));
            "BC14 Migration State"::Historical:
                exit(RunHistoricalMigrations(StopOnFirstError));
            else
                exit(true);
        end;
    end;

    /// <summary>
    /// Checks whether a record needs migration (not yet migrated or has unresolved error)
    /// and fires the OnBeforeMigrateRecord event. Caller should only call MigrateRecord if this returns true.
    /// </summary>
    local procedure ShouldMigrateRecord(
        MigratorName: Text[250];
        SourceTableId: Integer;
        var SourceRecordRef: RecordRef;
        RecordKey: Text[250]): Boolean
    var
        BC14MigrationRecordStatus: Record "BC14 Migration Record Status";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        HasUnresolvedError: Boolean;
        SkipRecord: Boolean;
    begin
        HasUnresolvedError := BC14MigrationErrorHandler.HasUnresolvedError(SourceTableId, RecordKey);
        if BC14MigrationRecordStatus.IsMigrated(SourceTableId, RecordKey) and (not HasUnresolvedError) then
            exit(false);

        SkipRecord := false;
        OnBeforeMigrateRecord(MigratorName, SourceRecordRef, SkipRecord);
        exit(not SkipRecord);
    end;

    /// <summary>
    /// Handles the result of MigrateRecord: logs errors or marks success, resolves previous errors.
    /// </summary>
    /// <returns>False if StopOnFirstError is true and migration failed (caller should exit loop).</returns>
    local procedure HandleMigrateResult(
        MigratorName: Text[250];
        SourceTableId: Integer;
        var SourceRecordRef: RecordRef;
        RecordKey: Text[250];
        MigrateSucceeded: Boolean;
        StopOnFirstError: Boolean;
        var MigratorSuccess: Boolean): Boolean
    var
        BC14MigrationRecordStatus: Record "BC14 Migration Record Status";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
    begin
        if not MigrateSucceeded then begin
            BC14MigrationErrorHandler.LogError(MigratorName, SourceTableId, SourceRecordRef.Name, RecordKey, 0, GetLastErrorText(), SourceRecordRef.RecordId);
            OnMigrateRecordFailed(MigratorName, SourceRecordRef, GetLastErrorText());
            MigratorSuccess := false;
            if StopOnFirstError then
                exit(false);
            ClearLastError();
        end else begin
            BC14MigrationRecordStatus.MarkAsMigrated(SourceTableId, RecordKey);
            if BC14MigrationErrorHandler.HasUnresolvedError(SourceTableId, RecordKey) then
                BC14MigrationErrorHandler.ResolveErrorForRecord(SourceTableId, RecordKey);
            OnAfterMigrateRecord(MigratorName, SourceRecordRef);
        end;

        // Periodic commit to avoid transaction log overflow and lock escalation on large datasets
        RecordsSinceLastCommit += 1;
        if RecordsSinceLastCommit >= CommitIntervalSize then begin
            Commit();
            RecordsSinceLastCommit := 0;
        end;

        exit(true);
    end;

    local procedure RunSetupMigrations(StopOnFirstError: Boolean): Boolean
    var
        BC14CompanySettings: Record "BC14CompanyMigrationSettings";
        SourceRecordRef: RecordRef;
        SetupMigratorEnum: Enum "BC14 Setup Migrator";
        SetupMigrator: Interface "ISetupMigrator";
        MigratorIndex: Integer;
        Success: Boolean;
        MigratorSuccess: Boolean;
        SkipMigrator: Boolean;
        SourceTableId: Integer;
        RecordKey: Text[250];
    begin
        Success := true;

        foreach MigratorIndex in "BC14 Setup Migrator".Ordinals() do begin
            SetupMigratorEnum := "BC14 Setup Migrator".FromInteger(MigratorIndex);
            SetupMigrator := SetupMigratorEnum;

            if SetupMigrator.IsEnabled() then begin
                SkipMigrator := false;
                CurrentMigratorName := CopyStr(SetupMigrator.GetName(), 1, MaxStrLen(CurrentMigratorName));

                OnBeforeRunMigrator(SetupMigrator.GetName(), SkipMigrator);
                if SkipMigrator then
                    continue;

                MigratorSuccess := true;
                SourceTableId := SetupMigrator.GetSourceTableId();
                if SourceTableId <> 0 then begin
                    SourceRecordRef.Open(SourceTableId);
                    SetupMigrator.InitializeSourceRecords(SourceRecordRef);

                    if SourceRecordRef.FindSet() then
                        repeat
                            RecordKey := SetupMigrator.GetSourceRecordKey(SourceRecordRef);
                            if ShouldMigrateRecord(SetupMigrator.GetName(), SourceTableId, SourceRecordRef, RecordKey) then
                                if not HandleMigrateResult(SetupMigrator.GetName(), SourceTableId, SourceRecordRef, RecordKey, SetupMigrator.MigrateRecord(SourceRecordRef), StopOnFirstError, MigratorSuccess) then begin
                                    SourceRecordRef.Close();
                                    exit(false);
                                end;
                        until SourceRecordRef.Next() = 0;
                    SourceRecordRef.Close();
                end;

                OnAfterRunMigrator(SetupMigrator.GetName(), MigratorSuccess, SetupMigrator.GetRecordCount());

                if MigratorSuccess then
                    BC14CompanySettings.SetMigrationPhaseCompleted("BC14 Migration State"::Setup, CurrentMigratorName);

                if not MigratorSuccess then
                    Success := false;
            end;
        end;

        OnRunSetupMigrations(StopOnFirstError, Success);
        exit(Success);
    end;

    local procedure RunMasterMigrations(StopOnFirstError: Boolean): Boolean
    var
        BC14CompanySettings: Record "BC14CompanyMigrationSettings";
        SourceRecordRef: RecordRef;
        MasterMigratorEnum: Enum "BC14 Master Migrator";
        MasterMigrator: Interface "IMasterMigrator";
        MigratorIndex: Integer;
        Success: Boolean;
        MigratorSuccess: Boolean;
        SkipMigrator: Boolean;
        SourceTableId: Integer;
        RecordKey: Text[250];
    begin
        Success := true;

        foreach MigratorIndex in "BC14 Master Migrator".Ordinals() do begin
            MasterMigratorEnum := "BC14 Master Migrator".FromInteger(MigratorIndex);
            MasterMigrator := MasterMigratorEnum;

            if MasterMigrator.IsEnabled() then begin
                SkipMigrator := false;
                CurrentMigratorName := CopyStr(MasterMigrator.GetName(), 1, MaxStrLen(CurrentMigratorName));

                OnBeforeRunMigrator(MasterMigrator.GetName(), SkipMigrator);
                if SkipMigrator then
                    continue;

                MigratorSuccess := true;
                SourceTableId := MasterMigrator.GetSourceTableId();
                SourceRecordRef.Open(SourceTableId);
                MasterMigrator.InitializeSourceRecords(SourceRecordRef);

                if SourceRecordRef.FindSet() then
                    repeat
                        RecordKey := MasterMigrator.GetSourceRecordKey(SourceRecordRef);
                        if ShouldMigrateRecord(MasterMigrator.GetName(), SourceTableId, SourceRecordRef, RecordKey) then
                            if not HandleMigrateResult(MasterMigrator.GetName(), SourceTableId, SourceRecordRef, RecordKey, MasterMigrator.MigrateRecord(SourceRecordRef), StopOnFirstError, MigratorSuccess) then begin
                                SourceRecordRef.Close();
                                exit(false);
                            end;
                    until SourceRecordRef.Next() = 0;
                SourceRecordRef.Close();

                OnAfterRunMigrator(MasterMigrator.GetName(), MigratorSuccess, MasterMigrator.GetRecordCount());

                if MigratorSuccess then
                    BC14CompanySettings.SetMigrationPhaseCompleted("BC14 Migration State"::Master, CurrentMigratorName);

                if not MigratorSuccess then
                    Success := false;
            end;
        end;

        OnRunMasterMigrations(StopOnFirstError, Success);
        exit(Success);
    end;

    local procedure RunTransactionMigrations(StopOnFirstError: Boolean): Boolean
    var
        BC14CompanySettings: Record "BC14CompanyMigrationSettings";
        SourceRecordRef: RecordRef;
        TransactionMigratorEnum: Enum "BC14 Transaction Migrator";
        TransactionMigrator: Interface "ITransactionMigrator";
        MigratorIndex: Integer;
        Success: Boolean;
        MigratorSuccess: Boolean;
        SkipMigrator: Boolean;
        SourceTableId: Integer;
        RecordKey: Text[250];
    begin
        Success := true;

        foreach MigratorIndex in "BC14 Transaction Migrator".Ordinals() do begin
            TransactionMigratorEnum := "BC14 Transaction Migrator".FromInteger(MigratorIndex);
            TransactionMigrator := TransactionMigratorEnum;

            if TransactionMigrator.IsEnabled() then begin
                SkipMigrator := false;
                CurrentMigratorName := CopyStr(TransactionMigrator.GetName(), 1, MaxStrLen(CurrentMigratorName));

                OnBeforeRunMigrator(TransactionMigrator.GetName(), SkipMigrator);
                if SkipMigrator then
                    continue;

                MigratorSuccess := true;
                SourceTableId := TransactionMigrator.GetSourceTableId();
                SourceRecordRef.Open(SourceTableId);
                TransactionMigrator.InitializeSourceRecords(SourceRecordRef);

                if SourceRecordRef.FindSet() then
                    repeat
                        RecordKey := TransactionMigrator.GetSourceRecordKey(SourceRecordRef);
                        if ShouldMigrateRecord(TransactionMigrator.GetName(), SourceTableId, SourceRecordRef, RecordKey) then
                            if not HandleMigrateResult(TransactionMigrator.GetName(), SourceTableId, SourceRecordRef, RecordKey, TransactionMigrator.MigrateRecord(SourceRecordRef), StopOnFirstError, MigratorSuccess) then begin
                                SourceRecordRef.Close();
                                exit(false);
                            end;
                    until SourceRecordRef.Next() = 0;
                SourceRecordRef.Close();

                OnAfterRunMigrator(TransactionMigrator.GetName(), MigratorSuccess, TransactionMigrator.GetRecordCount());

                if MigratorSuccess then
                    BC14CompanySettings.SetMigrationPhaseCompleted("BC14 Migration State"::Transaction, CurrentMigratorName);

                if not MigratorSuccess then
                    Success := false;
            end;
        end;

        OnRunTransactionMigrations(StopOnFirstError, Success);
        exit(Success);
    end;

    local procedure RunHistoricalMigrations(StopOnFirstError: Boolean): Boolean
    var
        BC14CompanySettings: Record "BC14CompanyMigrationSettings";
        SourceRecordRef: RecordRef;
        HistoricalMigratorEnum: Enum "BC14 Historical Migrator";
        HistoricalMigrator: Interface "IHistoricalMigrator";
        MigratorIndex: Integer;
        Success: Boolean;
        MigratorSuccess: Boolean;
        SkipMigrator: Boolean;
        SourceTableId: Integer;
        RecordKey: Text[250];
    begin
        Success := true;

        foreach MigratorIndex in "BC14 Historical Migrator".Ordinals() do begin
            HistoricalMigratorEnum := "BC14 Historical Migrator".FromInteger(MigratorIndex);
            HistoricalMigrator := HistoricalMigratorEnum;

            if HistoricalMigrator.IsEnabled() then begin
                SkipMigrator := false;
                CurrentMigratorName := CopyStr(HistoricalMigrator.GetName(), 1, MaxStrLen(CurrentMigratorName));

                OnBeforeRunMigrator(HistoricalMigrator.GetName(), SkipMigrator);
                if SkipMigrator then
                    continue;

                MigratorSuccess := true;
                SourceTableId := HistoricalMigrator.GetSourceTableId();
                SourceRecordRef.Open(SourceTableId);
                HistoricalMigrator.InitializeSourceRecords(SourceRecordRef);

                if SourceRecordRef.FindSet() then
                    repeat
                        RecordKey := HistoricalMigrator.GetSourceRecordKey(SourceRecordRef);
                        if ShouldMigrateRecord(HistoricalMigrator.GetName(), SourceTableId, SourceRecordRef, RecordKey) then
                            if not HandleMigrateResult(HistoricalMigrator.GetName(), SourceTableId, SourceRecordRef, RecordKey, HistoricalMigrator.MigrateRecord(SourceRecordRef), StopOnFirstError, MigratorSuccess) then begin
                                SourceRecordRef.Close();
                                exit(false);
                            end;
                    until SourceRecordRef.Next() = 0;
                SourceRecordRef.Close();

                OnAfterRunMigrator(HistoricalMigrator.GetName(), MigratorSuccess, HistoricalMigrator.GetRecordCount());

                if MigratorSuccess then
                    BC14CompanySettings.SetMigrationPhaseCompleted("BC14 Migration State"::Historical, CurrentMigratorName);

                if not MigratorSuccess then
                    Success := false;
            end;
        end;

        OnRunHistoricalMigrations(StopOnFirstError, Success);
        exit(Success);
    end;

    /// <summary>
    /// Retry failed records by re-running migration.
    /// With the runner-driven pattern, rerunning migration automatically skips already-migrated records.
    /// This procedure clears the "Scheduled For Retry" flag and relies on RunMigration's skip logic.
    /// </summary>
    procedure RetryFailedRecords()
    var
        BC14CompanySettings: Record "BC14CompanyMigrationSettings";
        BC14MigrationErrors: Record "BC14 Migration Errors";
    begin
        // Mark all "Scheduled For Retry" errors so they will be re-attempted
        // The runner will skip any records that already succeeded
        BC14MigrationErrors.SetRange("Company Name", CompanyName());
        BC14MigrationErrors.SetRange("Scheduled For Retry", true);
        BC14MigrationErrors.SetRange("Resolved", false);

        // Clear the error records scheduled for retry - they will be re-logged if they fail again
        BC14MigrationErrors.ModifyAll("Scheduled For Retry", false);

        // Allow extensions to add their own retry logic
        OnRetryFailedRecords(false);

        // Suppress confirmations during retry - the caller (error page) already confirmed.
        SuppressConfirmations := true;

        // Only skip posting if it was already completed in a previous run.
        // In Stop On First Error mode, posting may not have been reached yet and must still run.
        BC14CompanySettings.GetSingleInstance();
        SkipPostingOnRetry := BC14CompanySettings.GetLastCompletedPhase().AsInteger() >= "BC14 Migration State"::Posting.AsInteger();

        RunMigration();

        SkipPostingOnRetry := false;
        SuppressConfirmations := false;

        // Update Hybrid framework status so management page reflects the current state
        UpdateHybridStatusAfterRetry();
    end;

    procedure GetTotalErrorCount(): Integer
    var
        BC14MigrationErrors: Record "BC14 Migration Errors";
    begin
        BC14MigrationErrors.SetRange("Company Name", CompanyName());
        BC14MigrationErrors.SetRange("Resolved", false);
        exit(BC14MigrationErrors.Count());
    end;

    local procedure UpdateHybridStatusAfterRetry()
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        HybridCompanyStatus: Record "Hybrid Company Status";
        BC14Wizard: Codeunit "BC14 Wizard";
        UnresolvedErrors: Integer;
    begin
        UnresolvedErrors := GetTotalErrorCount();

        // Update HybridCompanyStatus for this company
        if HybridCompanyStatus.Get(CompanyName()) then begin
            if UnresolvedErrors = 0 then
                HybridCompanyStatus."Upgrade Status" := HybridCompanyStatus."Upgrade Status"::Completed
            else
                HybridCompanyStatus."Upgrade Status" := HybridCompanyStatus."Upgrade Status"::Failed;
            HybridCompanyStatus.Modify();
        end;

        // Update the latest HybridReplicationSummary
        HybridReplicationSummary.SetCurrentKey("Start Time");
        HybridReplicationSummary.Ascending(false);
        HybridReplicationSummary.SetRange(Source, BC14Wizard.GetMigrationProviderId());
        if HybridReplicationSummary.FindFirst() then begin
            if UnresolvedErrors = 0 then begin
                HybridReplicationSummary.Status := HybridReplicationSummary.Status::Completed;
                Clear(HybridReplicationSummary.Details);
            end else
                HybridReplicationSummary.Status := HybridReplicationSummary.Status::UpgradeFailed;
            HybridReplicationSummary."End Time" := CurrentDateTime();
            HybridReplicationSummary.Modify();
        end;
    end;

    local procedure CleanupMigrationRecordStatus()
    var
        BC14MigrationRecordStatus: Record "BC14 Migration Record Status";
        BC14HelperFunctions: Codeunit "BC14 Helper Functions";
        DeletedCount: Integer;
    begin
        // Clean up the migration progress tracking table after successful completion
        // This table can grow very large (e.g., millions of G/L Entries) and is only needed during migration
        DeletedCount := BC14MigrationRecordStatus.ClearAllMigrationStatus();
        Session.LogMessage('0000ROM', StrSubstNo(MigrationRecordStatusCleanedUpLbl, DeletedCount), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14HelperFunctions.GetTelemetryCategory());
    end;

    /// <summary>
    /// Posts all migration journal batches.
    /// Provides events for extensions to add custom logic before/after posting.
    /// </summary>
    procedure PostMigrationJournals(): Boolean
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        BC14CompanySettings: Record "BC14CompanyMigrationSettings";
        BC14HelperFunctions: Codeunit "BC14 Helper Functions";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        TemplateName: Code[10];
        SkipPosting: Boolean;
        BatchCount: Integer;
        FailedBatchCount: Integer;
        CleanedLinesCount: Integer;
    begin
        BC14CompanySettings.GetSingleInstance();
        SkipPosting := BC14CompanySettings.GetSkipPostingJournalBatches();

        // Allow extensions to add their own journal lines before posting
        OnBeforePostMigrationJournals(SkipPosting);

        if SkipPosting then begin
            Session.LogMessage('0000ROF', PostMigrationJournalsSkippedLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14HelperFunctions.GetTelemetryCategory());
            exit(true);
        end;

        TemplateName := BC14HelperFunctions.GetGeneralJournalTemplateName();

        // Clean up invalid journal lines before posting (Amount = 0)
        CleanedLinesCount := CleanupInvalidJournalLines(TemplateName);
        if CleanedLinesCount > 0 then
            Session.LogMessage('0000ROG', StrSubstNo(CleanedInvalidJournalLinesLbl, CleanedLinesCount), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14HelperFunctions.GetTelemetryCategory());

        // Clean up journal lines with empty Bal. Account No. (from previous failed runs)
        CleanedLinesCount := CleanupLinesWithEmptyBalAccount(TemplateName);
        if CleanedLinesCount > 0 then
            Session.LogMessage('0000ROH', StrSubstNo(CleanedEmptyBalAccountLbl, CleanedLinesCount), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14HelperFunctions.GetTelemetryCategory());


        // Find and post all BC14 migration batches
        GenJournalBatch.SetRange("Journal Template Name", TemplateName);
        GenJournalBatch.SetFilter(Name, 'BC14*'); // All BC14 migration batches
        if GenJournalBatch.FindSet() then
            repeat
                GenJournalLine.SetRange("Journal Template Name", TemplateName);
                GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
                if GenJournalLine.FindFirst() then
                    if not TryPostJournalBatch(GenJournalLine) then begin
                        // Log detailed error for posting failure
                        BC14MigrationErrorHandler.LogError(StrSubstNo(JournalPostingLbl, GenJournalBatch.Name), Database::"Gen. Journal Line", 'Gen. Journal Line', StrSubstNo(JournalBatchInfoLbl, TemplateName, GenJournalBatch.Name), Database::"Gen. Journal Line", GetLastErrorText(), GenJournalLine.RecordId);
                        FailedBatchCount += 1;
                        ClearLastError();
                    end else
                        BatchCount += 1;
            until GenJournalBatch.Next() = 0;

        Session.LogMessage('0000ROI', StrSubstNo(PostMigrationJournalsCompletedLbl, BatchCount), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14HelperFunctions.GetTelemetryCategory());

        // Allow extensions to run custom logic after posting
        OnAfterPostMigrationJournals(BatchCount);

        exit(FailedBatchCount = 0);
    end;

    [TryFunction]
    local procedure TryPostJournalBatch(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJnlPostBatch: Codeunit "Gen. Jnl.-Post Batch";
    begin
        GenJnlPostBatch.Run(GenJournalLine);
    end;

    local procedure CleanupInvalidJournalLines(TemplateName: Code[10]): Integer
    var
        GenJournalLine: Record "Gen. Journal Line";
        CleanedCount: Integer;
    begin
        GenJournalLine.SetRange("Journal Template Name", TemplateName);
        GenJournalLine.SetFilter("Journal Batch Name", 'BC14*');
        GenJournalLine.SetRange(Amount, 0);

        CleanedCount := GenJournalLine.Count();
        if CleanedCount > 0 then
            GenJournalLine.DeleteAll();

        exit(CleanedCount);
    end;

    local procedure CleanupLinesWithEmptyBalAccount(TemplateName: Code[10]): Integer
    var
        GenJournalLine: Record "Gen. Journal Line";
        CleanedCount: Integer;
    begin
        GenJournalLine.SetRange("Journal Template Name", TemplateName);
        GenJournalLine.SetFilter("Journal Batch Name", 'BC14CUST|BC14VEND'); // Only Customer/Vendor batches require Bal. Account
        GenJournalLine.SetRange("Bal. Account No.", '');

        CleanedCount := GenJournalLine.Count();
        if CleanedCount > 0 then
            GenJournalLine.DeleteAll();

        exit(CleanedCount);
    end;

    local procedure EnableDirectPostingOnAllAccounts()
    var
        GLAccount: Record "G/L Account";
        BC14HelperFunctions: Codeunit "BC14 Helper Functions";
        UpdatedCount: Integer;
    begin
        GLAccount.SetRange("Direct Posting", false);
        GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);
        UpdatedCount := GLAccount.Count();
        if UpdatedCount > 0 then begin
            GLAccount.ModifyAll("Direct Posting", true);
            Session.LogMessage('0000ROJ', StrSubstNo(EnabledDirectPostingLbl, UpdatedCount), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14HelperFunctions.GetTelemetryCategory());
        end;
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforePostMigrationJournals(var SkipPosting: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterPostMigrationJournals(BatchCount: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunSetupMigrations(StopOnFirstError: Boolean; var Success: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunMasterMigrations(StopOnFirstError: Boolean; var Success: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunTransactionMigrations(StopOnFirstError: Boolean; var Success: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunHistoricalMigrations(StopOnFirstError: Boolean; var Success: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRetryFailedRecords(StopOnFirstError: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before migration starts to allow validation.
    /// Subscribe to this event to perform custom validation before migration begins.
    /// Set CanProceed to false and provide an error message to prevent migration from starting.
    /// </summary>
    /// <param name="CanProceed">Set to false to prevent migration from starting.</param>
    /// <param name="ErrorMessage">Provide an error message explaining why migration cannot proceed.</param>
    [IntegrationEvent(false, false)]
    procedure OnValidateBeforeMigration(var CanProceed: Boolean; var ErrorMessage: Text)
    begin
    end;

    /// <summary>
    /// Integration event raised before migrating a specific entity type.
    /// Subscribe to perform pre-processing or to skip specific migrators.
    /// </summary>
    /// <param name="MigratorName">The name of the migrator about to run.</param>
    /// <param name="SkipMigrator">Set to true to skip this migrator.</param>
    [IntegrationEvent(false, false)]
    procedure OnBeforeRunMigrator(MigratorName: Text[250]; var SkipMigrator: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised after migrating a specific entity type.
    /// Subscribe to perform post-processing or logging.
    /// </summary>
    /// <param name="MigratorName">The name of the migrator that just completed.</param>
    /// <param name="Success">Whether the migrator completed successfully.</param>
    /// <param name="RecordCount">The number of records processed.</param>
    [IntegrationEvent(false, false)]
    procedure OnAfterRunMigrator(MigratorName: Text[250]; Success: Boolean; RecordCount: Integer)
    begin
    end;

    /// <summary>
    /// Integration event raised before migrating a single record.
    /// Subscribe to perform per-record pre-processing or to skip specific records.
    /// </summary>
    /// <param name="MigratorName">The name of the migrator processing this record.</param>
    /// <param name="SourceRecordRef">The source record about to be migrated.</param>
    /// <param name="SkipRecord">Set to true to skip this record.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeMigrateRecord(MigratorName: Text[250]; var SourceRecordRef: RecordRef; var SkipRecord: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised after successfully migrating a single record.
    /// Subscribe to perform per-record post-processing.
    /// </summary>
    /// <param name="MigratorName">The name of the migrator that processed this record.</param>
    /// <param name="SourceRecordRef">The source record that was migrated.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateRecord(MigratorName: Text[250]; var SourceRecordRef: RecordRef)
    begin
    end;

    /// <summary>
    /// Integration event raised when a record migration fails.
    /// Subscribe to perform custom error handling, notifications, or logging.
    /// </summary>
    /// <param name="MigratorName">The name of the migrator that failed.</param>
    /// <param name="SourceRecordRef">The source record that failed to migrate.</param>
    /// <param name="ErrorMessage">The error message from the failed migration attempt.</param>
    [IntegrationEvent(false, false)]
    local procedure OnMigrateRecordFailed(MigratorName: Text[250]; var SourceRecordRef: RecordRef; ErrorMessage: Text)
    begin
    end;
}
