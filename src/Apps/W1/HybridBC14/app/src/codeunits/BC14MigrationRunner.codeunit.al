// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;

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
        CannotContinueNotPausedErr: Label 'Migration is not paused. Use Run Migration to start a new migration.';
        CurrentMigratorName: Text[100];

    procedure RunMigration()
    var
        BC14CompanyAdditionalSettings: Record "BC14CompanyAdditionalSettings";
        BC14HelperFunctions: Codeunit "BC14 Helper Functions";
        GlobalExecutionPolicy: Codeunit "BC14 Global Execution Policy";
        ExecutionPolicy: Interface "I BC14 Migrator Execution Policy";
        StopOnFirstError: Boolean;
        CanProceed: Boolean;
        ValidationErrorMessage: Text;
    begin
        // Pre-migration validation hook - allows extensions to validate before migration starts
        CanProceed := true;
        ValidationErrorMessage := '';
        OnValidateBeforeMigration(CanProceed, ValidationErrorMessage);
        if not CanProceed then begin
            Session.LogMessage('0000ROA', StrSubstNo(ValidationFailedLbl, ValidationErrorMessage), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14HelperFunctions.GetTelemetryCategory());
            Error(ValidationErrorMessage);
        end;

        BC14CompanyAdditionalSettings.GetSingleInstance();

        // Mark migration as started to block future replications
        BC14CompanyAdditionalSettings.SetDataMigrationStarted();
        BC14CompanyAdditionalSettings.SetMigrationState("BC14 Migration State"::Setup);

        StopOnFirstError := BC14CompanyAdditionalSettings.GetStopOnFirstTransformationError();

        if StopOnFirstError then
            Session.LogMessage('0000ROB', StopOnFirstErrorEnabledLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14HelperFunctions.GetTelemetryCategory())
        else
            Session.LogMessage('0000ROC', ContinueOnErrorEnabledLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14HelperFunctions.GetTelemetryCategory());

        Session.LogMessage('0000ROD', StrSubstNo(MigrationStartedMsg, CompanyName()), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14HelperFunctions.GetTelemetryCategory());

        // Run migrations in order: Setup -> Master -> Transactions -> Historical -> Posting
        ExecutionPolicy := GlobalExecutionPolicy;
        RunMigrationFromPhase("BC14 Migration State"::Setup, StopOnFirstError, '', ExecutionPolicy);
    end;

    /// <summary>
    /// Continues a paused migration from where it stopped.
    /// Call this after fixing errors when Stop On First Error is enabled.
    /// </summary>
    procedure ContinueMigration()
    var
        BC14CompanyAdditionalSettings: Record "BC14CompanyAdditionalSettings";
        BC14HelperFunctions: Codeunit "BC14 Helper Functions";
        StepExecutionPolicy: Codeunit "BC14 Step Execution Policy";
        ExecutionPolicy: Interface "I BC14 Migrator Execution Policy";
        LastCompletedPhase: Enum "BC14 Migration State";
        ResumePhase: Enum "BC14 Migration State";
        StopOnFirstError: Boolean;
        FailedMigratorName: Text[100];
    begin
        BC14CompanyAdditionalSettings.GetSingleInstance();

        if not BC14CompanyAdditionalSettings.IsMigrationPaused() then
            Error(CannotContinueNotPausedErr);

        StopOnFirstError := BC14CompanyAdditionalSettings.GetStopOnFirstTransformationError();
        LastCompletedPhase := BC14CompanyAdditionalSettings.GetLastCompletedPhase();
        FailedMigratorName := BC14CompanyAdditionalSettings.GetFailedMigratorName();

        ResumePhase := ResolveResumePhase(FailedMigratorName, LastCompletedPhase);

        Session.LogMessage('0000ROK', StrSubstNo(MigrationResumedMsg, CompanyName(), Format(ResumePhase)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14HelperFunctions.GetTelemetryCategory());

        BC14CompanyAdditionalSettings.SetMigrationState(ResumePhase);
        ExecutionPolicy := StepExecutionPolicy;
        RunMigrationFromPhase(ResumePhase, StopOnFirstError, FailedMigratorName, ExecutionPolicy);
    end;

    local procedure RunMigrationFromPhase(StartPhase: Enum "BC14 Migration State"; StopOnFirstError: Boolean; ResumeFromMigratorName: Text[100]; ExecutionPolicy: Interface "I BC14 Migrator Execution Policy")
    var
        BC14CompanyAdditionalSettings: Record "BC14CompanyAdditionalSettings";
        BC14HelperFunctions: Codeunit "BC14 Helper Functions";
        TotalErrors: Integer;
    begin
        if StartPhase = "BC14 Migration State"::Completed then
            exit;

        if not ExecuteMigrationPhase(StartPhase, "BC14 Migration State"::Setup, StopOnFirstError, ResumeFromMigratorName, ExecutionPolicy) then
            exit;

        if not ExecuteMigrationPhase(StartPhase, "BC14 Migration State"::Master, StopOnFirstError, ResumeFromMigratorName, ExecutionPolicy) then
            exit;

        if not ExecuteMigrationPhase(StartPhase, "BC14 Migration State"::Transaction, StopOnFirstError, ResumeFromMigratorName, ExecutionPolicy) then
            exit;

        if not ExecuteMigrationPhase(StartPhase, "BC14 Migration State"::Historical, StopOnFirstError, ResumeFromMigratorName, ExecutionPolicy) then
            exit;

        // Post all migration journal batches (unless skipped)
        BC14CompanyAdditionalSettings.SetMigrationState("BC14 Migration State"::Posting);
        PostMigrationJournals();

        // Mark migration as completed
        BC14CompanyAdditionalSettings.SetMigrationState("BC14 Migration State"::Completed);
        BC14CompanyAdditionalSettings.SetMigrationPhaseCompleted("BC14 Migration State"::Completed, '');

        TotalErrors := GetTotalErrorCount();
        Session.LogMessage('0000ROE', StrSubstNo(MigrationCompletedMsg, CompanyName(), TotalErrors), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14HelperFunctions.GetTelemetryCategory());
    end;

    local procedure ResolveResumePhase(FailedMigratorName: Text[100]; LastCompletedPhase: Enum "BC14 Migration State"): Enum "BC14 Migration State"
    var
        ResumePhase: Enum "BC14 Migration State";
    begin
        // Resume from the failed migrator's phase when possible; this avoids replaying unrelated phases.
        ResumePhase := GetMigratorPhase(FailedMigratorName);
        if ResumePhase <> "BC14 Migration State"::NotStarted then
            exit(ResumePhase);

        case LastCompletedPhase of
            "BC14 Migration State"::NotStarted:
                exit("BC14 Migration State"::Setup);
            "BC14 Migration State"::Setup:
                exit("BC14 Migration State"::Setup);
            "BC14 Migration State"::Master:
                exit("BC14 Migration State"::Master);
            "BC14 Migration State"::Transaction:
                exit("BC14 Migration State"::Transaction);
            "BC14 Migration State"::Historical:
                exit("BC14 Migration State"::Historical);
            "BC14 Migration State"::Posting:
                exit("BC14 Migration State"::Posting);
            "BC14 Migration State"::Paused:
                exit("BC14 Migration State"::Setup);
            "BC14 Migration State"::Completed:
                exit("BC14 Migration State"::Completed);
            else
                exit("BC14 Migration State"::Setup);
        end;
    end;

    local procedure ExecuteMigrationPhase(StartPhase: Enum "BC14 Migration State"; Phase: Enum "BC14 Migration State"; StopOnFirstError: Boolean; ResumeFromMigratorName: Text[100]; ExecutionPolicy: Interface "I BC14 Migrator Execution Policy"): Boolean
    var
        BC14CompanyAdditionalSettings: Record "BC14CompanyAdditionalSettings";
        BC14HelperFunctions: Codeunit "BC14 Helper Functions";
        PhaseResumeMigratorName: Text[100];
        PhaseStepNo: Integer;
        PhaseSuccess: Boolean;
    begin
        if StartPhase.AsInteger() > Phase.AsInteger() then
            exit(true);

        BC14CompanyAdditionalSettings.SetMigrationState(Phase);

        PhaseResumeMigratorName := '';
        if StartPhase = Phase then
            PhaseResumeMigratorName := ResumeFromMigratorName;
        ExecutionPolicy.Initialize(PhaseResumeMigratorName);

        PhaseSuccess := RunPhaseMigrators(Phase, StopOnFirstError, ExecutionPolicy);
        if (not PhaseSuccess) and StopOnFirstError then begin
            BC14CompanyAdditionalSettings.PauseMigration(CurrentMigratorName);
            Message(MigrationPausedMsg, CompanyName(), CurrentMigratorName);
            exit(false);
        end;

        PhaseStepNo := Phase.AsInteger();
        BC14CompanyAdditionalSettings.SetMigrationPhaseCompleted(Phase, '');
        Session.LogMessage('0000ROL', StrSubstNo(MigrationPhaseCompletedLbl, Format(PhaseStepNo)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14HelperFunctions.GetTelemetryCategory(), 'StepNo', Format(PhaseStepNo));
        exit(true);
    end;

    local procedure RunPhaseMigrators(Phase: Enum "BC14 Migration State"; StopOnFirstError: Boolean; ExecutionPolicy: Interface "I BC14 Migrator Execution Policy"): Boolean
    begin
        case Phase of
            "BC14 Migration State"::Setup:
                exit(RunSetupMigrations(StopOnFirstError, ExecutionPolicy));
            "BC14 Migration State"::Master:
                exit(RunMasterMigrations(StopOnFirstError, ExecutionPolicy));
            "BC14 Migration State"::Transaction:
                exit(RunTransactionMigrations(StopOnFirstError, ExecutionPolicy));
            "BC14 Migration State"::Historical:
                exit(RunHistoricalMigrations(StopOnFirstError, ExecutionPolicy));
            else
                exit(true);
        end;
    end;

    local procedure RunSetupMigrations(StopOnFirstError: Boolean; ExecutionPolicy: Interface "I BC14 Migrator Execution Policy"): Boolean
    var
        BC14CompanyAdditionalSettings: Record "BC14CompanyAdditionalSettings";
        SetupMigratorEnum: Enum "BC14 Setup Migrator";
        SetupMigrator: Interface "ISetupMigrator";
        MigratorIndex: Integer;
        Success: Boolean;
        MigratorSuccess: Boolean;
        SkipMigrator: Boolean;
    begin
        Success := true;

        // Iterate through all registered setup migrators
        foreach MigratorIndex in "BC14 Setup Migrator".Ordinals() do begin
            SetupMigratorEnum := "BC14 Setup Migrator".FromInteger(MigratorIndex);
            SetupMigrator := SetupMigratorEnum;

            if SetupMigrator.IsEnabled() then begin
                SkipMigrator := false;
                CurrentMigratorName := CopyStr(SetupMigrator.GetName(), 1, MaxStrLen(CurrentMigratorName));

                if not ExecutionPolicy.ShouldRunMigrator(CurrentMigratorName) then
                    continue;

                OnBeforeRunMigrator(SetupMigrator.GetName(), SkipMigrator);
                if SkipMigrator then
                    continue;

                MigratorSuccess := SetupMigrator.Migrate(StopOnFirstError);
                OnAfterRunMigrator(SetupMigrator.GetName(), MigratorSuccess, 0);

                if MigratorSuccess then
                    BC14CompanyAdditionalSettings.SetMigrationPhaseCompleted("BC14 Migration State"::Setup, CurrentMigratorName);

                if not MigratorSuccess then begin
                    Success := false;
                    if StopOnFirstError then
                        exit(false);
                end;
            end;
        end;

        // Allow extensions to add their own setup migrators
        OnRunSetupMigrations(StopOnFirstError);
        exit(Success);
    end;

    local procedure RunMasterMigrations(StopOnFirstError: Boolean; ExecutionPolicy: Interface "I BC14 Migrator Execution Policy"): Boolean
    var
        BC14CompanyAdditionalSettings: Record "BC14CompanyAdditionalSettings";
        MasterMigratorEnum: Enum "BC14 Master Migrator";
        MasterMigrator: Interface "IMasterMigrator";
        MigratorIndex: Integer;
        Success: Boolean;
        MigratorSuccess: Boolean;
        SkipMigrator: Boolean;
        RecordCount: Integer;
    begin
        Success := true;

        // Iterate through all registered master migrators
        foreach MigratorIndex in "BC14 Master Migrator".Ordinals() do begin
            MasterMigratorEnum := "BC14 Master Migrator".FromInteger(MigratorIndex);
            MasterMigrator := MasterMigratorEnum;

            if MasterMigrator.IsEnabled() then begin
                SkipMigrator := false;
                CurrentMigratorName := CopyStr(MasterMigrator.GetName(), 1, MaxStrLen(CurrentMigratorName));

                if not ExecutionPolicy.ShouldRunMigrator(CurrentMigratorName) then
                    continue;

                OnBeforeRunMigrator(MasterMigrator.GetName(), SkipMigrator);
                if SkipMigrator then
                    continue;

                RecordCount := MasterMigrator.GetRecordCount();
                MigratorSuccess := MasterMigrator.Migrate(StopOnFirstError);
                OnAfterRunMigrator(MasterMigrator.GetName(), MigratorSuccess, RecordCount);

                if MigratorSuccess then
                    BC14CompanyAdditionalSettings.SetMigrationPhaseCompleted("BC14 Migration State"::Master, CurrentMigratorName);

                if not MigratorSuccess then begin
                    Success := false;
                    if StopOnFirstError then
                        exit(false);
                end;
            end;
        end;

        // Allow extensions to add their own master migrators
        OnRunMasterMigrations(StopOnFirstError);
        exit(Success);
    end;

    local procedure RunTransactionMigrations(StopOnFirstError: Boolean; ExecutionPolicy: Interface "I BC14 Migrator Execution Policy"): Boolean
    var
        BC14CompanyAdditionalSettings: Record "BC14CompanyAdditionalSettings";
        TransactionMigratorEnum: Enum "BC14 Transaction Migrator";
        TransactionMigrator: Interface "ITransactionMigrator";
        MigratorIndex: Integer;
        Success: Boolean;
        MigratorSuccess: Boolean;
        SkipMigrator: Boolean;
        RecordCount: Integer;
    begin
        Success := true;

        // Iterate through all registered transaction migrators
        foreach MigratorIndex in "BC14 Transaction Migrator".Ordinals() do begin
            TransactionMigratorEnum := "BC14 Transaction Migrator".FromInteger(MigratorIndex);
            TransactionMigrator := TransactionMigratorEnum;

            if TransactionMigrator.IsEnabled() then begin
                SkipMigrator := false;
                CurrentMigratorName := CopyStr(TransactionMigrator.GetName(), 1, MaxStrLen(CurrentMigratorName));

                if not ExecutionPolicy.ShouldRunMigrator(CurrentMigratorName) then
                    continue;

                OnBeforeRunMigrator(TransactionMigrator.GetName(), SkipMigrator);
                if SkipMigrator then
                    continue;

                RecordCount := TransactionMigrator.GetRecordCount();
                MigratorSuccess := TransactionMigrator.Migrate(StopOnFirstError);
                OnAfterRunMigrator(TransactionMigrator.GetName(), MigratorSuccess, RecordCount);

                if MigratorSuccess then
                    BC14CompanyAdditionalSettings.SetMigrationPhaseCompleted("BC14 Migration State"::Transaction, CurrentMigratorName);

                if not MigratorSuccess then begin
                    Success := false;
                    if StopOnFirstError then
                        exit(false);
                end;
            end;
        end;

        // Allow extensions to add their own transaction migrators
        OnRunTransactionMigrations(StopOnFirstError);
        exit(Success);
    end;

    local procedure RunHistoricalMigrations(StopOnFirstError: Boolean; ExecutionPolicy: Interface "I BC14 Migrator Execution Policy"): Boolean
    var
        BC14CompanyAdditionalSettings: Record "BC14CompanyAdditionalSettings";
        HistoricalMigratorEnum: Enum "BC14 Historical Migrator";
        HistoricalMigrator: Interface "IHistoricalMigrator";
        MigratorIndex: Integer;
        Success: Boolean;
        MigratorSuccess: Boolean;
        SkipMigrator: Boolean;
        RecordCount: Integer;
    begin
        Success := true;

        // Iterate through all registered historical migrators
        foreach MigratorIndex in "BC14 Historical Migrator".Ordinals() do begin
            HistoricalMigratorEnum := "BC14 Historical Migrator".FromInteger(MigratorIndex);
            HistoricalMigrator := HistoricalMigratorEnum;

            if HistoricalMigrator.IsEnabled() then begin
                SkipMigrator := false;
                CurrentMigratorName := CopyStr(HistoricalMigrator.GetName(), 1, MaxStrLen(CurrentMigratorName));

                if not ExecutionPolicy.ShouldRunMigrator(CurrentMigratorName) then
                    continue;

                OnBeforeRunMigrator(HistoricalMigrator.GetName(), SkipMigrator);
                if SkipMigrator then
                    continue;

                RecordCount := HistoricalMigrator.GetRecordCount();
                MigratorSuccess := HistoricalMigrator.Migrate(StopOnFirstError);
                OnAfterRunMigrator(HistoricalMigrator.GetName(), MigratorSuccess, RecordCount);

                if MigratorSuccess then
                    BC14CompanyAdditionalSettings.SetMigrationPhaseCompleted("BC14 Migration State"::Historical, CurrentMigratorName);

                if not MigratorSuccess then begin
                    Success := false;
                    if StopOnFirstError then
                        exit(false);
                end;
            end;
        end;

        // Allow extensions to add their own historical migrators
        OnRunHistoricalMigrations(StopOnFirstError);
        exit(Success);
    end;

    procedure RetryFailedRecords()
    var
        BC14MigrationErrors: Record "BC14 Migration Errors";
        BC14CompanyAdditionalSettings: Record "BC14CompanyAdditionalSettings";
        StopOnFirstError: Boolean;
        TableIdsToRetry: List of [Integer];
        TableId: Integer;
    begin
        BC14CompanyAdditionalSettings.GetSingleInstance();
        StopOnFirstError := BC14CompanyAdditionalSettings.GetStopOnFirstTransformationError();

        // Find all distinct Source Table IDs that have records scheduled for retry
        BC14MigrationErrors.SetRange("Company Name", CompanyName());
        BC14MigrationErrors.SetRange("Scheduled For Retry", true);
        BC14MigrationErrors.SetRange("Resolved", false);
        if BC14MigrationErrors.FindSet() then
            repeat
                if not TableIdsToRetry.Contains(BC14MigrationErrors."Source Table ID") then
                    TableIdsToRetry.Add(BC14MigrationErrors."Source Table ID");
            until BC14MigrationErrors.Next() = 0;

        // Retry only the migrators that have pending errors
        foreach TableId in TableIdsToRetry do
            RetryFailedRecordsForTable(TableId, StopOnFirstError);

        // Allow extensions to add their own retry logic
        OnRetryFailedRecords(StopOnFirstError);
    end;

    local procedure RetryFailedRecordsForTable(SourceTableId: Integer; StopOnFirstError: Boolean)
    var
        BC14CustomerMigrator: Codeunit "BC14 Customer Migrator";
        BC14VendorMigrator: Codeunit "BC14 Vendor Migrator";
        BC14ItemMigrator: Codeunit "BC14 Item Migrator";
        BC14GLAccountMigrator: Codeunit "BC14 GL Account Migrator";
        BC14GLEntryMigrator: Codeunit "BC14 G/L Entry Migrator";
    begin
        case SourceTableId of
            Database::"BC14 Customer":
                BC14CustomerMigrator.RetryFailedRecords(StopOnFirstError);
            Database::"BC14 Vendor":
                BC14VendorMigrator.RetryFailedRecords(StopOnFirstError);
            Database::"BC14 Item":
                BC14ItemMigrator.RetryFailedRecords(StopOnFirstError);
            Database::"BC14 G/L Account":
                BC14GLAccountMigrator.RetryFailedRecords(StopOnFirstError);
            Database::"BC14 G/L Entry":
                BC14GLEntryMigrator.RetryFailedRecords(StopOnFirstError);
        end;
    end;

    procedure GetTotalErrorCount(): Integer
    var
        BC14MigrationErrors: Record "BC14 Migration Errors";
    begin
        BC14MigrationErrors.SetRange("Company Name", CompanyName());
        BC14MigrationErrors.SetRange("Resolved", false);
        exit(BC14MigrationErrors.Count());
    end;

    /// <summary>
    /// Posts all migration journal batches.
    /// Provides events for extensions to add custom logic before/after posting.
    /// </summary>
    procedure PostMigrationJournals()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        BC14CompanyAdditionalSettings: Record "BC14CompanyAdditionalSettings";
        BC14HelperFunctions: Codeunit "BC14 Helper Functions";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        TemplateName: Code[10];
        SkipPosting: Boolean;
        BatchCount: Integer;
        CleanedLinesCount: Integer;
    begin
        BC14CompanyAdditionalSettings.GetSingleInstance();
        SkipPosting := BC14CompanyAdditionalSettings.GetSkipPostingJournalBatches();

        // Allow extensions to add their own journal lines before posting
        OnBeforePostMigrationJournals(SkipPosting);

        if SkipPosting then begin
            Session.LogMessage('0000ROF', PostMigrationJournalsSkippedLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14HelperFunctions.GetTelemetryCategory());
            exit;
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

        // Temporarily enable Direct Posting on ALL G/L Accounts to allow migration posting
        EnableDirectPostingOnAllAccounts();

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
                        ClearLastError();
                    end else
                        BatchCount += 1;
            until GenJournalBatch.Next() = 0;

        Session.LogMessage('0000ROI', StrSubstNo(PostMigrationJournalsCompletedLbl, BatchCount), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14HelperFunctions.GetTelemetryCategory());

        // Allow extensions to run custom logic after posting
        OnAfterPostMigrationJournals(BatchCount);
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
    local procedure OnRunSetupMigrations(StopOnFirstError: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunMasterMigrations(StopOnFirstError: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunTransactionMigrations(StopOnFirstError: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunHistoricalMigrations(StopOnFirstError: Boolean)
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

    local procedure GetMigratorPhase(MigratorName: Text[100]): Enum "BC14 Migration State"
    var
        SetupMigratorEnum: Enum "BC14 Setup Migrator";
        SetupMigrator: Interface "ISetupMigrator";
        MasterMigratorEnum: Enum "BC14 Master Migrator";
        MasterMigrator: Interface "IMasterMigrator";
        TransactionMigratorEnum: Enum "BC14 Transaction Migrator";
        TransactionMigrator: Interface "ITransactionMigrator";
        HistoricalMigratorEnum: Enum "BC14 Historical Migrator";
        HistoricalMigrator: Interface "IHistoricalMigrator";
        MigratorIndex: Integer;
        MigratorNameToCheck: Text[100];
    begin
        if MigratorName = '' then
            exit("BC14 Migration State"::NotStarted);

        MigratorNameToCheck := LowerCase(MigratorName);

        foreach MigratorIndex in "BC14 Setup Migrator".Ordinals() do begin
            SetupMigratorEnum := "BC14 Setup Migrator".FromInteger(MigratorIndex);
            SetupMigrator := SetupMigratorEnum;
            if LowerCase(CopyStr(SetupMigrator.GetName(), 1, MaxStrLen(MigratorNameToCheck))) = MigratorNameToCheck then
                exit("BC14 Migration State"::Setup);
        end;

        foreach MigratorIndex in "BC14 Master Migrator".Ordinals() do begin
            MasterMigratorEnum := "BC14 Master Migrator".FromInteger(MigratorIndex);
            MasterMigrator := MasterMigratorEnum;
            if LowerCase(CopyStr(MasterMigrator.GetName(), 1, MaxStrLen(MigratorNameToCheck))) = MigratorNameToCheck then
                exit("BC14 Migration State"::Master);
        end;

        foreach MigratorIndex in "BC14 Transaction Migrator".Ordinals() do begin
            TransactionMigratorEnum := "BC14 Transaction Migrator".FromInteger(MigratorIndex);
            TransactionMigrator := TransactionMigratorEnum;
            if LowerCase(CopyStr(TransactionMigrator.GetName(), 1, MaxStrLen(MigratorNameToCheck))) = MigratorNameToCheck then
                exit("BC14 Migration State"::Transaction);
        end;

        foreach MigratorIndex in "BC14 Historical Migrator".Ordinals() do begin
            HistoricalMigratorEnum := "BC14 Historical Migrator".FromInteger(MigratorIndex);
            HistoricalMigrator := HistoricalMigratorEnum;
            if LowerCase(CopyStr(HistoricalMigrator.GetName(), 1, MaxStrLen(MigratorNameToCheck))) = MigratorNameToCheck then
                exit("BC14 Migration State"::Historical);
        end;

        exit("BC14 Migration State"::NotStarted);
    end;
}
