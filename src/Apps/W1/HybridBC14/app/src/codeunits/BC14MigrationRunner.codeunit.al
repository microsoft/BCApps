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

    procedure RunMigration()
    var
        BC14CompanyAdditionalSettings: Record "BC14CompanyAdditionalSettings";
        BC14HelperFunctions: Codeunit "BC14 Helper Functions";
        StopOnFirstError: Boolean;
        TotalErrors: Integer;
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

        StopOnFirstError := false; // First version: always continue on error

        if StopOnFirstError then
            Session.LogMessage('0000ROB', StopOnFirstErrorEnabledLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14HelperFunctions.GetTelemetryCategory())
        else
            Session.LogMessage('0000ROC', ContinueOnErrorEnabledLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14HelperFunctions.GetTelemetryCategory());

        Session.LogMessage('0000ROD', StrSubstNo(MigrationStartedMsg, CompanyName()), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14HelperFunctions.GetTelemetryCategory());

        // Run migrations in order: Setup -> Master -> Transactions
        // Note: Most setup data (Dimensions, Payment Terms) is replicated directly.
        // Use Setup Migrators only for setup data that requires transformation.
        if not RunSetupMigrations(StopOnFirstError) and StopOnFirstError then
            exit;

        if not RunMasterMigrations(StopOnFirstError) and StopOnFirstError then
            exit;

        if not RunTransactionMigrations(StopOnFirstError) and StopOnFirstError then
            exit;

        // Run historical data migrations (posted documents - no re-posting)
        if not RunHistoricalMigrations(StopOnFirstError) and StopOnFirstError then
            exit;

        // Post all migration journal batches (unless skipped)
        PostMigrationJournals();

        TotalErrors := GetTotalErrorCount();
        Session.LogMessage('0000ROE', StrSubstNo(MigrationCompletedMsg, CompanyName(), TotalErrors), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14HelperFunctions.GetTelemetryCategory());
    end;

    local procedure RunSetupMigrations(StopOnFirstError: Boolean): Boolean
    var
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
                OnBeforeRunMigrator(SetupMigrator.GetName(), SkipMigrator);
                if SkipMigrator then
                    continue;

                MigratorSuccess := SetupMigrator.Migrate(StopOnFirstError);
                OnAfterRunMigrator(SetupMigrator.GetName(), MigratorSuccess, 0);

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

    local procedure RunMasterMigrations(StopOnFirstError: Boolean): Boolean
    var
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
                OnBeforeRunMigrator(MasterMigrator.GetName(), SkipMigrator);
                if SkipMigrator then
                    continue;

                RecordCount := MasterMigrator.GetRecordCount();
                MigratorSuccess := MasterMigrator.Migrate(StopOnFirstError);
                OnAfterRunMigrator(MasterMigrator.GetName(), MigratorSuccess, RecordCount);

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

    local procedure RunTransactionMigrations(StopOnFirstError: Boolean): Boolean
    var
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
                OnBeforeRunMigrator(TransactionMigrator.GetName(), SkipMigrator);
                if SkipMigrator then
                    continue;

                RecordCount := TransactionMigrator.GetRecordCount();
                MigratorSuccess := TransactionMigrator.Migrate(StopOnFirstError);
                OnAfterRunMigrator(TransactionMigrator.GetName(), MigratorSuccess, RecordCount);

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

    local procedure RunHistoricalMigrations(StopOnFirstError: Boolean): Boolean
    var
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
                OnBeforeRunMigrator(HistoricalMigrator.GetName(), SkipMigrator);
                if SkipMigrator then
                    continue;

                RecordCount := HistoricalMigrator.GetRecordCount();
                MigratorSuccess := HistoricalMigrator.Migrate(StopOnFirstError);
                OnAfterRunMigrator(HistoricalMigrator.GetName(), MigratorSuccess, RecordCount);

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
        StopOnFirstError: Boolean;
    begin
        StopOnFirstError := false; // First version: always continue on error

        OnRetryFailedRecords(StopOnFirstError);
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
}
