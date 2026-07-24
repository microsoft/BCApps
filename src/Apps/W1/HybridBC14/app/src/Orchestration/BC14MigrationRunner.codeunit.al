// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.DataMigration;
using System.Integration;

codeunit 46875 "BC14 Migration Runner"
{
    TableNo = "Hybrid Replication Summary";

    var
        BC14Telemetry: Codeunit "BC14 Telemetry";

    trigger OnRun()
    begin
        ContinueCompanyMigration();
    end;

    local procedure ContinueCompanyMigration()
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        DataMigrationError: Record "Data Migration Error";
        BC14MigrationFailureHandler: Codeunit "BC14 Migration Failure Handler";
        BC14MigrationOrchestrator: Codeunit "BC14 Migration Orchestrator";
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
        HasErrors: Boolean;
        HistoricalCompleted: Boolean;
    begin
        // Invalidate any leftover Historical Worker from the previous attempt.
        BC14CompanySettings.PrepareHistoricalForRerun(CopyStr(CompanyName(), 1, 30));

        // Clear stale "Unhandled Upgrade Error" rows (Source Table ID = 0) from the previous failed run. 
        DataMigrationError.Reset();
        DataMigrationError.SetRange("Source Table ID", 0);
        DataMigrationError.SetRange("Error Dismissed", false);
        if not DataMigrationError.IsEmpty() then
            DataMigrationError.DeleteAll(true);

        DataMigrationError.Reset();
        DataMigrationError.SetRange("Scheduled For Retry", true);
        DataMigrationError.SetRange("Error Dismissed", false);
        if not DataMigrationError.IsEmpty() then begin
            Session.LogMessage('0000TUT', ClearingScheduledForRetryLbl, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());
            DataMigrationError.ModifyAll("Scheduled For Retry", false);
        end;

        Commit();

        OnBeforeContinueMigration();

        RunMigration(true);

        HasErrors := GetTotalErrorCount() > 0;
        BC14CompanySettings.GetSingleInstance();
        HistoricalCompleted := BC14CompanySettings.IsReadyToFinalize();
        if BC14MigrationOrchestrator.FindLatestReplicationSummary(HybridReplicationSummary) then begin
            if HasErrors then begin
                BC14MigrationFailureHandler.MarkUpgradeFailed(HybridReplicationSummary);
                Commit();
            end;
            BC14StatusMgr.AfterCompanyMigrationCompleted(
                CopyStr(CompanyName(), 1, 30),
                HasErrors,
                HistoricalCompleted,
                HybridReplicationSummary);

            Commit();
            BC14MigrationOrchestrator.TryFinalizeOverallUpgrade();
        end;
    end;

    var
        MigrationStartedLbl: Label 'Migration started for company %1.', Locked = true, Comment = '%1 = Company Name';
        MigrationCompletedLbl: Label 'Migration completed for company %1. Total errors: %2.', Locked = true, Comment = '%1 = Company Name, %2 = Error Count';
        MigrationResumedLbl: Label 'Migration resumed for company %1 from %2 phase.', Locked = true, Comment = '%1 = Company Name, %2 = Phase Name';
        StopOnFirstErrorEnabledLbl: Label 'Stop On First Error is enabled. Migration will halt on first error.', Locked = true;
        ContinueOnErrorEnabledLbl: Label 'Continue On Error is enabled. Migration will collect all errors.', Locked = true;
        ValidationFailedLbl: Label 'Pre-migration validation failed: %1', Locked = true, Comment = '%1 = Error message';
        MigrationPhaseCompletedLbl: Label 'Migration phase %1 completed.', Locked = true, Comment = '%1 = Phase Name';
        UnresolvedErrorsWarningErr: Label 'There are %1 unresolved migration errors. Resolve or retry the errors before running migration again.', Comment = '%1 = Error count';
        HistoricalAsyncDispatchedLbl: Label 'Historical migration dispatched to background task.', Locked = true;
        HistoricalAlreadyCompletedLbl: Label 'Historical migration already completed. Skipping dispatch.', Locked = true;
        HistoricalAlreadyDispatchedLbl: Label 'Historical migration already dispatched and still running. Skipping duplicate dispatch.', Locked = true;
        HistoricalDisabledLbl: Label 'Historical record migration is disabled for this company. Marking Historical phase complete without dispatching.', Locked = true;
        UnexpectedPhaseLbl: Label 'Unexpected migration phase encountered: %1', Locked = true, Comment = '%1 = Phase';
        MigrationAlreadyCompletedLbl: Label 'RunMigrationFromPhase called with Completed phase. Migration already completed, skipping.', Locked = true;
        MigrationFinalizedLbl: Label 'Both Posting and Historical done. Migration finalized as Completed.', Locked = true;
        MigrationFailedFinalizedLbl: Label 'Migration finalized after failure: state set to Completed, validations skipped.', Locked = true;
        MigrationPhaseHaltedLbl: Label 'Migration halted at phase %1 for company %2. Company marked Failed so the operator can retry via Continue migration.', Locked = true, Comment = '%1 = Phase, %2 = Company Name';
        MigrationPhaseHaltedErrLbl: Label 'Migration halted at phase %1. Resolve the underlying errors and click Continue migration to retry.', Comment = '%1 = Phase';
        NoReplicationSummaryForRerunErr: Label 'Cannot rerun migration for company %1: no replication summary was found. Run replication first.', Comment = '%1 = Company Name';
        HistoricalDisabledForRerunErr: Label 'Cannot rerun historical migration for company %1: historical record migration is disabled for this company.', Comment = '%1 = Company Name';
        MainNotCompletedForHistoricalRerunErr: Label 'Cannot rerun historical migration for company %1 because its main migration has not completed yet. Use Continue migration to finish the upgrade first.', Comment = '%1 = Company Name';
        OnAfterPopulateSetupMigratorsTok: Label 'OnAfterPopulateSetupMigrators', Locked = true;
        OnAfterPopulateMasterMigratorsTok: Label 'OnAfterPopulateMasterMigrators', Locked = true;
        OnAfterPopulateTransactionMigratorsTok: Label 'OnAfterPopulateTransactionMigrators', Locked = true;
        OnAfterPopulateHistoricalMigratorsTok: Label 'OnAfterPopulateHistoricalMigrators', Locked = true;
        OnAfterPopulateActionsTok: Label 'OnAfterPopulateActions', Locked = true;
        OnAfterPopulateValidationsTok: Label 'OnAfterPopulateValidations', Locked = true;
        ClearingScheduledForRetryLbl: Label 'Clearing records marked as Scheduled For Retry before continuing migration.', Locked = true;
        CurrentMigratorName: Text[100];

    procedure RunMigration()
    begin
        RunMigration(false);
    end;

    internal procedure RunMigration(SuppressErrors: Boolean)
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        LastCompletedPhase: Enum "BC14 Migration Step";
        StartPhase: Enum "BC14 Migration Step";
        StopOnFirstError: Boolean;
        CanProceed: Boolean;
        ValidationErrorMessage: Text;
        UnresolvedErrorCount: Integer;
    begin
        CanProceed := true;
        ValidationErrorMessage := '';
        OnValidateBeforeMigration(CanProceed, ValidationErrorMessage);
        if not CanProceed then begin
            Session.LogMessage('0000TUN', StrSubstNo(ValidationFailedLbl, ValidationErrorMessage), Verbosity::Error, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());
            Error(ValidationErrorMessage);
        end;

        UnresolvedErrorCount := GetTotalErrorCount();
        if (UnresolvedErrorCount > 0) and (not SuppressErrors) then
            Error(UnresolvedErrorsWarningErr, UnresolvedErrorCount);

        BC14CompanySettings.GetSingleInstance();
        StopOnFirstError := BC14CompanySettings.GetStopOnFirstTransformationError();
        LastCompletedPhase := BC14CompanySettings.GetLastCompletedPhase();

        // Resume whenever at least one phase has been completed previously. This covers both
        // posting failure (Last Completed Phase rolled back to Transaction) and the case where
        // a transformation phase halted mid-run -- in both cases the next run picks up after
        // the last successful phase instead of restarting from Setup.
        if LastCompletedPhase <> "BC14 Migration Step"::NotStarted then begin
            StartPhase := GetNextPhase(LastCompletedPhase);
            Session.LogMessage('0000TUO', StrSubstNo(MigrationResumedLbl, CompanyName(), Format(StartPhase)), Verbosity::Normal, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());
        end else begin
            BC14CompanySettings.SetDataMigrationStarted();
            StartPhase := "BC14 Migration Step"::Setup;
            Session.LogMessage('0000TUP', StrSubstNo(MigrationStartedLbl, CompanyName()), Verbosity::Normal, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());
        end;

        if StopOnFirstError then
            Session.LogMessage('0000TUQ', StopOnFirstErrorEnabledLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory())
        else
            Session.LogMessage('0000TUR', ContinueOnErrorEnabledLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());

        RunMigrationFromPhase(StartPhase);
    end;

    local procedure GetNextPhase(CurrentPhase: Enum "BC14 Migration Step"): Enum "BC14 Migration Step"
    begin
        case CurrentPhase of
            "BC14 Migration Step"::NotStarted:
                exit("BC14 Migration Step"::Setup);
            "BC14 Migration Step"::Setup:
                exit("BC14 Migration Step"::Master);
            "BC14 Migration Step"::Master:
                exit("BC14 Migration Step"::Transaction);
            "BC14 Migration Step"::Transaction:
                exit("BC14 Migration Step"::Posting);
            "BC14 Migration Step"::Posting,
            "BC14 Migration Step"::Historical,
            "BC14 Migration Step"::Completed:
                exit("BC14 Migration Step"::Completed);
            else begin
                Session.LogMessage('0000TUS', StrSubstNo(UnexpectedPhaseLbl, Format(CurrentPhase)), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());
                exit("BC14 Migration Step"::Setup);
            end;
        end;
    end;

    procedure ContinueMigrationForCompany(TargetCompanyName: Text[30])
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        BC14MigrationOrchestrator: Codeunit "BC14 Migration Orchestrator";
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
        TaskRecordId: RecordId;
        SessionID: Integer;
        RunSynchronously: Boolean;
    begin
        BC14StatusMgr.AcquireRerunSlot(TargetCompanyName);
        BC14CompanySettings.PrepareMainForRerun(TargetCompanyName);
        BC14CompanySettings.PrepareHistoricalForRerun(TargetCompanyName);

        // Refuse to schedule a rerun without a Summary — the FailureHandler would otherwise
        // be unable to set Summary=UpgradeFailed if the rerun task crashes. Pulling the
        // Summary out of its terminal state also clears stale End Time on the page.
        if not BC14MigrationOrchestrator.FindLatestReplicationSummary(HybridReplicationSummary) then
            Error(NoReplicationSummaryForRerunErr, TargetCompanyName);
        BC14StatusMgr.SetSummaryInProgress(HybridReplicationSummary);
        TaskRecordId := HybridReplicationSummary.RecordId;
        Commit();

        BC14MigrationOrchestrator.RaiseOnBeforeScheduleTask(Codeunit::"BC14 Migration Runner", RunSynchronously);
        if RunSynchronously then
            Codeunit.Run(Codeunit::"BC14 Migration Runner")
        else
            if TaskScheduler.CanCreateTask() then
                TaskScheduler.CreateTask(
                    Codeunit::"BC14 Migration Runner", Codeunit::"BC14 Migration Failure Handler",
                    true, TargetCompanyName, CurrentDateTime(), TaskRecordId, BC14MigrationOrchestrator.GetDefaultJobTimeout())
            else
                Session.StartSession(SessionID, Codeunit::"BC14 Migration Runner", TargetCompanyName);
    end;

    internal procedure RerunHistoricalForCompany(TargetCompanyName: Text[30])
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        BC14MigrationOrchestrator: Codeunit "BC14 Migration Orchestrator";
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
        EmptyRecordId: RecordId;
        SessionID: Integer;
        RunSynchronously: Boolean;
    begin
        if not BC14CompanySettings.Get(TargetCompanyName) then
            Error(NoReplicationSummaryForRerunErr, TargetCompanyName);
        if not BC14CompanySettings."Migrate Historical Records" then
            Error(HistoricalDisabledForRerunErr, TargetCompanyName);
        if not BC14CompanySettings."Posting Completed" then
            Error(MainNotCompletedForHistoricalRerunErr, TargetCompanyName);

        BC14StatusMgr.AcquireRerunSlot(TargetCompanyName);

        if not BC14MigrationOrchestrator.FindLatestReplicationSummary(HybridReplicationSummary) then
            Error(NoReplicationSummaryForRerunErr, TargetCompanyName);
        BC14StatusMgr.SetSummaryInProgress(HybridReplicationSummary);

        BC14CompanySettings.RestartHistoricalDispatch(TargetCompanyName);
        Commit();

        BC14MigrationOrchestrator.RaiseOnBeforeScheduleTask(Codeunit::"BC14 Historical Task Worker", RunSynchronously);
        if RunSynchronously then begin
            Codeunit.Run(Codeunit::"BC14 Historical Task Worker");
            exit;
        end;

        if TaskScheduler.CanCreateTask() then
            TaskScheduler.CreateTask(
                Codeunit::"BC14 Historical Task Worker", Codeunit::"BC14 Migration Failure Handler",
                true, TargetCompanyName, CurrentDateTime(), EmptyRecordId, BC14MigrationOrchestrator.GetDefaultJobTimeout())
        else
            Session.StartSession(SessionID, Codeunit::"BC14 Historical Task Worker", TargetCompanyName);
    end;

    local procedure RunMigrationFromPhase(StartPhase: Enum "BC14 Migration Step")
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        TotalErrors: Integer;
    begin
        BC14CompanySettings.GetSingleInstance();
        if BC14CompanySettings.GetMigrationState() = "BC14 Migration Step"::Completed then begin
            Session.LogMessage('0000TUU', MigrationAlreadyCompletedLbl, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());
            exit;
        end;

        if not ExecuteMigrationPhase(StartPhase, "BC14 Migration Step"::Setup) then
            exit;

        if not ExecuteMigrationPhase(StartPhase, "BC14 Migration Step"::Master) then
            exit;

        if not ExecuteMigrationPhase(StartPhase, "BC14 Migration Step"::Transaction) then
            exit;

        // TODO: Posting and Historical will be dispatched as independent post-upgrade workers;
        // at that point this call marks the main pipeline done. For now the IsReadyToFinalize
        // gate keeps it a no-op and Historical Worker drives the real finalize.
        TryFinalizeCompanyMigration();

        ExecuteJournalPosting();

        DispatchHistoricalMigration();

        TotalErrors := GetTotalErrorCount();
        Session.LogMessage('0000TUV', StrSubstNo(MigrationCompletedLbl, CompanyName(), TotalErrors), Verbosity::Normal, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());
    end;

    local procedure ExecuteJournalPosting()
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
    begin
        BC14CompanySettings.GetSingleInstance();
        if BC14CompanySettings."Posting Completed" then
            exit;

        BC14CompanySettings.SetMigrationState("BC14 Migration Step"::Posting);
        Commit();
        if ExecutePostMigrationActions() then begin
            BC14CompanySettings.SetPostingCompleted();
            BC14CompanySettings.SetMigrationPhaseCompleted("BC14 Migration Step"::Posting, '');
        end;
    end;

    local procedure ExecutePostMigrationActions(): Boolean
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        ActionList: List of [Enum "BC14 Post Migration Action"];
        MigrationAction: Interface "BC14 Post Migration Action";
        ActionEnum: Enum "BC14 Post Migration Action";
        ActionSuccess: Boolean;
        Success: Boolean;
        SkipAction: Boolean;
        ActionName: Text[250];
        EnabledActionCount: Integer;
    begin
        PopulatePostMigrationActions(ActionList);

        EnabledActionCount := CountEnabledPostMigrationActions(ActionList);
        BC14CompanySettings.InitCurrentPhaseProgress(EnabledActionCount);

        Success := true;
        foreach ActionEnum in ActionList do begin
            MigrationAction := ActionEnum;

            if MigrationAction.IsEnabled() then begin
                SkipAction := false;
                ActionName := CopyStr(MigrationAction.GetDisplayName(), 1, MaxStrLen(ActionName));

                OnBeforeRunAction(ActionEnum, ActionName, SkipAction);
                if SkipAction then begin
                    BC14CompanySettings.IncrementCurrentPhaseProgress();
                    continue;
                end;

                Commit();
                ActionSuccess := MigrationAction.RunAction();

                OnAfterRunAction(ActionEnum, ActionName, ActionSuccess);

                BC14CompanySettings.IncrementCurrentPhaseProgress();

                if not ActionSuccess then
                    Success := false;
            end;
        end;

        exit(Success);
    end;

    local procedure PopulatePostMigrationActions(var ActionList: List of [Enum "BC14 Post Migration Action"])
    var
        NewActions: List of [Enum "BC14 Post Migration Action"];
        CountBefore: Integer;
        Changed: Boolean;
    begin
        ActionList.Add("BC14 Post Migration Action"::"Journal Post");

        CountBefore := ActionList.Count();
        OnAfterPopulateActions(ActionList, NewActions, Changed);
        if Changed then begin
            ActionList := NewActions;
            BC14Telemetry.LogSubscriberContribution(OnAfterPopulateActionsTok, CountBefore, ActionList.Count());
        end;
    end;

    local procedure CountEnabledPostMigrationActions(ActionList: List of [Enum "BC14 Post Migration Action"]): Integer
    var
        MigrationAction: Interface "BC14 Post Migration Action";
        ActionEnum: Enum "BC14 Post Migration Action";
        Count: Integer;
    begin
        foreach ActionEnum in ActionList do begin
            MigrationAction := ActionEnum;
            if MigrationAction.IsEnabled() then
                Count += 1;
        end;
        exit(Count);
    end;

    local procedure ExecuteMigrationPhase(StartPhase: Enum "BC14 Migration Step"; Phase: Enum "BC14 Migration Step"): Boolean
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
        PhaseStepNo: Integer;
        PhaseSuccess: Boolean;
    begin
        if StartPhase.AsInteger() > Phase.AsInteger() then
            exit(true);

        BC14CompanySettings.SetMigrationState(Phase);
        Commit(); // Must commit before RunMigrators because migrators use Codeunit.Run() with return value (try pattern), which is not allowed in write transactions

        PhaseSuccess := RunMigrators(Phase);

        if not PhaseSuccess then begin
            Session.LogMessage('0000TZ2', StrSubstNo(MigrationPhaseHaltedLbl, Format(Phase), CompanyName()), Verbosity::Warning, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());
            BC14StatusMgr.MarkCompanyFailed(CopyStr(CompanyName(), 1, 30), StrSubstNo(MigrationPhaseHaltedErrLbl, Format(Phase)));
            exit(false);
        end;

        PhaseStepNo := Phase.AsInteger();
        BC14CompanySettings.SetMigrationPhaseCompleted(Phase, '');
        Session.LogMessage('0000TUW', StrSubstNo(MigrationPhaseCompletedLbl, Format(PhaseStepNo)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory(), 'StepNo', Format(PhaseStepNo));
        exit(true);
    end;

    local procedure RunMigrators(Phase: Enum "BC14 Migration Step"): Boolean
    var
        Migrators: List of [Interface "BC14 Migrator"];
    begin
        case Phase of
            "BC14 Migration Step"::Setup:
                PopulateSetupMigrators(Migrators);
            "BC14 Migration Step"::Master:
                PopulateMasterMigrators(Migrators);
            "BC14 Migration Step"::Transaction:
                PopulateTransactionMigrators(Migrators);
            "BC14 Migration Step"::Historical:
                PopulateHistoricalMigrators(Migrators);
            else
                exit(true);
        end;

        exit(RunMigratorList(Migrators));
    end;

    local procedure RunMigratorList(Migrators: List of [Interface "BC14 Migrator"]): Boolean
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        Migrator: Interface "BC14 Migrator";
        Success: Boolean;
        MigratorSuccess: Boolean;
        SkipMigrator: Boolean;
        EnabledMigratorCount: Integer;
    begin
        Success := true;
        BC14CompanySettings.GetSingleInstance();
        EnabledMigratorCount := CountEnabledMigrators(Migrators);
        BC14CompanySettings.InitCurrentPhaseProgress(EnabledMigratorCount);
        foreach Migrator in Migrators do
            if Migrator.IsEnabled() then begin
                SkipMigrator := false;
                CurrentMigratorName := CopyStr(Migrator.GetDisplayName(), 1, MaxStrLen(CurrentMigratorName));

                OnBeforeRunMigrator(CurrentMigratorName, SkipMigrator);
                if SkipMigrator then begin
                    BC14CompanySettings.IncrementCurrentPhaseProgress();
                    continue;
                end;

                Commit(); // Migrators use Codeunit.Run() with return value internally, which requires no open write transaction
                MigratorSuccess := Migrator.Migrate();

                OnAfterRunMigrator(CurrentMigratorName, MigratorSuccess, Migrator.GetRemainingPercentage());

                if MigratorSuccess then
                    BC14CompanySettings.SetLastCompletedMigrator(CurrentMigratorName);

                BC14CompanySettings.IncrementCurrentPhaseProgress();

                if not MigratorSuccess then begin
                    Success := false;
                    break;
                end;
            end;

        exit(Success);
    end;

    local procedure CountEnabledMigrators(Migrators: List of [Interface "BC14 Migrator"]): Integer
    var
        Migrator: Interface "BC14 Migrator";
        Count: Integer;
    begin
        foreach Migrator in Migrators do
            if Migrator.IsEnabled() then
                Count += 1;
        exit(Count);
    end;

    local procedure PopulateSetupMigrators(var Migrators: List of [Interface "BC14 Migrator"])
    var
        MigratorEnums: List of [Enum "BC14 Setup Migrator"];
        NewMigrators: List of [Enum "BC14 Setup Migrator"];
        MigratorEnum: Enum "BC14 Setup Migrator";
        Migrator: Interface "BC14 Migrator";
        CountBefore: Integer;
        Changed: Boolean;
    begin
        // Order matters: foundational lookups first, then posting groups, then setups that reference them.
        MigratorEnums.Add("BC14 Setup Migrator"::"Country/Region");
        MigratorEnums.Add("BC14 Setup Migrator"::"Post Code");
        MigratorEnums.Add("BC14 Setup Migrator"::Language);
        MigratorEnums.Add("BC14 Setup Migrator"::"Unit of Measure");
        MigratorEnums.Add("BC14 Setup Migrator"::"Reason Code");
        MigratorEnums.Add("BC14 Setup Migrator"::"Source Code");
        MigratorEnums.Add("BC14 Setup Migrator"::"Shipment Method");
        MigratorEnums.Add("BC14 Setup Migrator"::Territory);
        MigratorEnums.Add("BC14 Setup Migrator"::"Salesperson/Purchaser");
        MigratorEnums.Add("BC14 Setup Migrator"::"Tariff Number");
        MigratorEnums.Add("BC14 Setup Migrator"::Location);
        MigratorEnums.Add("BC14 Setup Migrator"::"Item Tracking Code");
        MigratorEnums.Add("BC14 Setup Migrator"::"Item Category");
        MigratorEnums.Add("BC14 Setup Migrator"::"Item Attribute");
        MigratorEnums.Add("BC14 Setup Migrator"::"Item Attribute Value");
        MigratorEnums.Add("BC14 Setup Migrator"::"Gen. Bus. Posting Group");
        MigratorEnums.Add("BC14 Setup Migrator"::"Gen. Prod. Posting Group");
        MigratorEnums.Add("BC14 Setup Migrator"::"VAT Bus. Posting Group");
        MigratorEnums.Add("BC14 Setup Migrator"::"VAT Prod. Posting Group");
        MigratorEnums.Add("BC14 Setup Migrator"::"Customer Posting Group");
        MigratorEnums.Add("BC14 Setup Migrator"::"Vendor Posting Group");
        MigratorEnums.Add("BC14 Setup Migrator"::"Inventory Posting Group");
        MigratorEnums.Add("BC14 Setup Migrator"::"General Posting Setup");
        MigratorEnums.Add("BC14 Setup Migrator"::"VAT Posting Setup");
        MigratorEnums.Add("BC14 Setup Migrator"::"Payment Terms");
        MigratorEnums.Add("BC14 Setup Migrator"::"Payment Method");
        MigratorEnums.Add("BC14 Setup Migrator"::"Finance Charge Terms");
        MigratorEnums.Add("BC14 Setup Migrator"::"Reminder Terms");
        MigratorEnums.Add("BC14 Setup Migrator"::"Reminder Level");
        MigratorEnums.Add("BC14 Setup Migrator"::"Reminder Text");
        MigratorEnums.Add("BC14 Setup Migrator"::"No. Series");
        MigratorEnums.Add("BC14 Setup Migrator"::"No. Series Line");
        MigratorEnums.Add("BC14 Setup Migrator"::Dimension);
        MigratorEnums.Add("BC14 Setup Migrator"::"Dimension Value");
        MigratorEnums.Add("BC14 Setup Migrator"::Currency);
        MigratorEnums.Add("BC14 Setup Migrator"::"Currency Exchange Rate");
        MigratorEnums.Add("BC14 Setup Migrator"::"Accounting Period");
        MigratorEnums.Add("BC14 Setup Migrator"::"Customer Price Group");
        MigratorEnums.Add("BC14 Setup Migrator"::"Customer Discount Group");
        MigratorEnums.Add("BC14 Setup Migrator"::"Item Discount Group");

        CountBefore := MigratorEnums.Count();
        OnAfterPopulateSetupMigrators(MigratorEnums, NewMigrators, Changed);
        if Changed then begin
            MigratorEnums := NewMigrators;
            BC14Telemetry.LogSubscriberContribution(OnAfterPopulateSetupMigratorsTok, CountBefore, MigratorEnums.Count());
        end;

        foreach MigratorEnum in MigratorEnums do begin
            Migrator := MigratorEnum;
            Migrators.Add(Migrator);
        end;
    end;

    local procedure PopulateMasterMigrators(var Migrators: List of [Interface "BC14 Migrator"])
    var
        MigratorEnums: List of [Enum "BC14 Master Migrator"];
        NewMigrators: List of [Enum "BC14 Master Migrator"];
        MigratorEnum: Enum "BC14 Master Migrator";
        Migrator: Interface "BC14 Migrator";
        CountBefore: Integer;
        Changed: Boolean;
    begin
        // Order matters: parent entities before satellites that reference them.
        MigratorEnums.Add("BC14 Master Migrator"::"G/L Account");
        MigratorEnums.Add("BC14 Master Migrator"::Customer);
        MigratorEnums.Add("BC14 Master Migrator"::Vendor);
        MigratorEnums.Add("BC14 Master Migrator"::Item);
        MigratorEnums.Add("BC14 Master Migrator"::"Customer Bank Account");
        MigratorEnums.Add("BC14 Master Migrator"::"Vendor Bank Account");
        MigratorEnums.Add("BC14 Master Migrator"::"Ship-to Address");
        MigratorEnums.Add("BC14 Master Migrator"::Resource);
        MigratorEnums.Add("BC14 Master Migrator"::"BOM Component");

        CountBefore := MigratorEnums.Count();
        OnAfterPopulateMasterMigrators(MigratorEnums, NewMigrators, Changed);
        if Changed then begin
            MigratorEnums := NewMigrators;
            BC14Telemetry.LogSubscriberContribution(OnAfterPopulateMasterMigratorsTok, CountBefore, MigratorEnums.Count());
        end;

        foreach MigratorEnum in MigratorEnums do begin
            Migrator := MigratorEnum;
            Migrators.Add(Migrator);
        end;
    end;

    local procedure PopulateTransactionMigrators(var Migrators: List of [Interface "BC14 Migrator"])
    var
        MigratorEnums: List of [Enum "BC14 Transaction Migrator"];
        NewMigrators: List of [Enum "BC14 Transaction Migrator"];
        MigratorEnum: Enum "BC14 Transaction Migrator";
        Migrator: Interface "BC14 Migrator";
        CountBefore: Integer;
        Changed: Boolean;
    begin
        MigratorEnums.Add("BC14 Transaction Migrator"::"G/L Entries");
        MigratorEnums.Add("BC14 Transaction Migrator"::"Customer Ledger Entries");
        MigratorEnums.Add("BC14 Transaction Migrator"::"Vendor Ledger Entries");

        CountBefore := MigratorEnums.Count();
        OnAfterPopulateTransactionMigrators(MigratorEnums, NewMigrators, Changed);
        if Changed then begin
            MigratorEnums := NewMigrators;
            BC14Telemetry.LogSubscriberContribution(OnAfterPopulateTransactionMigratorsTok, CountBefore, MigratorEnums.Count());
        end;

        foreach MigratorEnum in MigratorEnums do begin
            Migrator := MigratorEnum;
            Migrators.Add(Migrator);
        end;
    end;

    local procedure PopulateHistoricalMigrators(var Migrators: List of [Interface "BC14 Migrator"])
    var
        MigratorEnums: List of [Enum "BC14 Historical Migrator"];
        NewMigrators: List of [Enum "BC14 Historical Migrator"];
        MigratorEnum: Enum "BC14 Historical Migrator";
        Migrator: Interface "BC14 Migrator";
        CountBefore: Integer;
        Changed: Boolean;
    begin
        MigratorEnums.Add("BC14 Historical Migrator"::"Posted Sales Invoice");
        MigratorEnums.Add("BC14 Historical Migrator"::"Old G/L Entry");
        MigratorEnums.Add("BC14 Historical Migrator"::"Old Customer Ledger Entry");
        MigratorEnums.Add("BC14 Historical Migrator"::"Old Vendor Ledger Entry");
        MigratorEnums.Add("BC14 Historical Migrator"::"Old Item Ledger Entry");

        CountBefore := MigratorEnums.Count();
        OnAfterPopulateHistoricalMigrators(MigratorEnums, NewMigrators, Changed);
        if Changed then begin
            MigratorEnums := NewMigrators;
            BC14Telemetry.LogSubscriberContribution(OnAfterPopulateHistoricalMigratorsTok, CountBefore, MigratorEnums.Count());
        end;

        foreach MigratorEnum in MigratorEnums do begin
            Migrator := MigratorEnum;
            Migrators.Add(Migrator);
        end;
    end;

    internal procedure RunHistoricalMigrations(): Boolean
    begin
        exit(RunMigrators("BC14 Migration Step"::Historical));
    end;

    procedure GetTotalErrorCount(): Integer
    var
        DataMigrationError: Record "Data Migration Error";
    begin
        DataMigrationError.SetRange("Error Dismissed", false);
        exit(DataMigrationError.Count());
    end;

    /// <summary>
    /// Dispatched to a background task so the main phase chain can continue to Posting in parallel.
    /// </summary>
    local procedure DispatchHistoricalMigration()
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        BC14MigrationOrchestrator: Codeunit "BC14 Migration Orchestrator";
        EmptyRecordId: RecordId;
        RunSynchronously: Boolean;
    begin
        BC14CompanySettings.ReadIsolation := IsolationLevel::UpdLock;
        BC14CompanySettings.GetSingleInstance();
        if BC14CompanySettings."Historical Completed" then begin
            Session.LogMessage('0000TUZ', HistoricalAlreadyCompletedLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());
            exit;
        end;

        if not BC14CompanySettings."Migrate Historical Records" then begin
            // Historical migration is opted out for this company. Mark it completed so the
            // IsReadyToFinalize gate can advance the company to Completed without spinning
            // up the worker.
            BC14CompanySettings.SetHistoricalCompleted();
            Commit();
            Session.LogMessage('0000TV2', HistoricalDisabledLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());
            TryFinalizeCompanyMigration();
            exit;
        end;

        if BC14CompanySettings."Historical Dispatched" then begin
            Session.LogMessage('0000TV0', HistoricalAlreadyDispatchedLbl, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());
            exit;
        end;

        BC14MigrationOrchestrator.RaiseOnBeforeScheduleTask(Codeunit::"BC14 Historical Task Worker", RunSynchronously);
        if RunSynchronously then begin
            BC14CompanySettings.BeginHistoricalDispatch();
            Commit();
            Codeunit.Run(Codeunit::"BC14 Historical Task Worker");
            exit;
        end;

        BC14CompanySettings.BeginHistoricalDispatch();

        Session.LogMessage('0000TV1', HistoricalAsyncDispatchedLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());
        if TaskScheduler.CanCreateTask() then begin
            TaskScheduler.CreateTask(
                Codeunit::"BC14 Historical Task Worker", Codeunit::"BC14 Migration Failure Handler",
                true, CopyStr(CompanyName(), 1, 30), CurrentDateTime(), EmptyRecordId, BC14MigrationOrchestrator.GetDefaultJobTimeout());
            Commit();
        end else begin
            // Session.StartSession has no failure codeunit, so a worker crash would leave
            // Historical Completed unset and the company permanently stuck. Run synchronously.
            Commit();
            Codeunit.Run(Codeunit::"BC14 Historical Task Worker");
        end;
    end;

    /// <summary>
    /// Gated company-level finalize: exits early if migration state is already Completed or
    /// if the company is not yet ready to finalize (Posting + Historical both done). Safe to
    /// call from any path that may have just advanced Posting or Historical — the gate makes
    /// it idempotent and order-independent across the sync RunMigrationFromPhase path and the
    /// async Historical Worker path.
    /// </summary>
    internal procedure TryFinalizeCompanyMigration()
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
        HasErrors: Boolean;
    begin
        BC14CompanySettings.ReadIsolation := IsolationLevel::UpdLock;
        BC14CompanySettings.GetSingleInstance();

        if BC14CompanySettings.GetMigrationState() = "BC14 Migration Step"::Completed then begin
            Commit();
            exit;
        end;

        if not BC14CompanySettings.IsReadyToFinalize() then begin
            Commit();
            exit;
        end;

        HasErrors := BC14MigrationErrorHandler.ErrorOccurredInCurrentCompany();

        if not HasErrors then begin
            BC14CompanySettings.SetMigrationState("BC14 Migration Step"::Completed);
            BC14CompanySettings.SetMigrationPhaseCompleted("BC14 Migration Step"::Completed, '');
        end;

        BC14StatusMgr.SetFinalCompanyStatus(
            CopyStr(CompanyName(), 1, 30),
            HasErrors);

        Commit();

        if not HasErrors then
            RunValidations();

        Session.LogMessage('0000TV3', MigrationFinalizedLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());
    end;

    /// <summary>
    /// Skips success-path validations (e.g. balance checks) — they are meaningless on failure.
    /// </summary>
    internal procedure FailMigration()
    begin
        // Intentionally do NOT mutate Migration State or Last Completed Phase here. The task
        // crashed mid-phase; leaving those fields untouched preserves the resume point so the
        // next Rerun picks up at the first phase that still has unresolved errors instead of
        // jumping past them. Hybrid Company Status is updated separately by MarkUpgradeFailed.
        Commit();

        Session.LogMessage('0000TXP', MigrationFailedFinalizedLbl, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());
    end;

    local procedure RunValidations()
    var
        ValidationList: List of [Enum "BC14 Migration Validation"];
        NewValidations: List of [Enum "BC14 Migration Validation"];
        Validation: Interface "BC14 Migration Validation";
        ValidationEnum: Enum "BC14 Migration Validation";
        CountBefore: Integer;
        Changed: Boolean;
    begin
        ValidationList.Add("BC14 Migration Validation"::"Balance Warning");

        CountBefore := ValidationList.Count();
        OnAfterPopulateValidations(ValidationList, NewValidations, Changed);
        if Changed then begin
            ValidationList := NewValidations;
            BC14Telemetry.LogSubscriberContribution(OnAfterPopulateValidationsTok, CountBefore, ValidationList.Count());
        end;

        foreach ValidationEnum in ValidationList do begin
            Validation := ValidationEnum;
            if Validation.IsEnabled() then
                Validation.Execute();
        end;
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeContinueMigration()
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
    /// Integration event raised after the default Setup-phase migrator list is populated.
    /// Leave <paramref name="NewMigrators"/> empty and <paramref name="Changed"/> false to
    /// accept the defaults, or populate <paramref name="NewMigrators"/> with the desired full
    /// list and set <paramref name="Changed"/> to true to replace the defaults entirely.
    /// Migrators are identified by their strongly-typed "BC14 Setup Migrator" enum value, so
    /// reorder/remove operations compile-time-check against typos.
    /// </summary>
    /// <param name="Migrators">The default Setup-phase migrator list (read-only).</param>
    /// <param name="NewMigrators">Replacement list to use when <paramref name="Changed"/> is true.</param>
    /// <param name="Changed">Set to true to replace the default list with <paramref name="NewMigrators"/>.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterPopulateSetupMigrators(Migrators: List of [Enum "BC14 Setup Migrator"]; var NewMigrators: List of [Enum "BC14 Setup Migrator"]; var Changed: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised after the default Master Data-phase migrator list is populated.
    /// See <see cref="OnAfterPopulateSetupMigrators"/> for replacement semantics.
    /// </summary>
    /// <param name="Migrators">The default Master-phase migrator list (read-only).</param>
    /// <param name="NewMigrators">Replacement list to use when <paramref name="Changed"/> is true.</param>
    /// <param name="Changed">Set to true to replace the default list with <paramref name="NewMigrators"/>.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterPopulateMasterMigrators(Migrators: List of [Enum "BC14 Master Migrator"]; var NewMigrators: List of [Enum "BC14 Master Migrator"]; var Changed: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised after the default Transaction-phase migrator list is populated.
    /// See <see cref="OnAfterPopulateSetupMigrators"/> for replacement semantics.
    /// </summary>
    /// <param name="Migrators">The default Transaction-phase migrator list (read-only).</param>
    /// <param name="NewMigrators">Replacement list to use when <paramref name="Changed"/> is true.</param>
    /// <param name="Changed">Set to true to replace the default list with <paramref name="NewMigrators"/>.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterPopulateTransactionMigrators(Migrators: List of [Enum "BC14 Transaction Migrator"]; var NewMigrators: List of [Enum "BC14 Transaction Migrator"]; var Changed: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised after the default Historical-phase migrator list is populated.
    /// See <see cref="OnAfterPopulateSetupMigrators"/> for replacement semantics.
    /// </summary>
    /// <param name="Migrators">The default Historical-phase migrator list (read-only).</param>
    /// <param name="NewMigrators">Replacement list to use when <paramref name="Changed"/> is true.</param>
    /// <param name="Changed">Set to true to replace the default list with <paramref name="NewMigrators"/>.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterPopulateHistoricalMigrators(Migrators: List of [Enum "BC14 Historical Migrator"]; var NewMigrators: List of [Enum "BC14 Historical Migrator"]; var Changed: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised after the default action list is populated.
    /// See <see cref="OnAfterPopulateSetupMigrators"/> for replacement semantics.
    /// </summary>
    /// <param name="ActionList">The default action list (read-only).</param>
    /// <param name="NewActions">Replacement list to use when <paramref name="Changed"/> is true.</param>
    /// <param name="Changed">Set to true to replace the default list with <paramref name="NewActions"/>.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterPopulateActions(ActionList: List of [Enum "BC14 Post Migration Action"]; var NewActions: List of [Enum "BC14 Post Migration Action"]; var Changed: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before migrating a specific entity type. Intended for
    /// observability (logging, telemetry) and bulk skip decisions. To target a specific
    /// migrator for skip/reorder/remove, subscribe to OnAfterPopulate&lt;Phase&gt;Migrators
    /// instead — that event exposes the strongly-typed phase enum.
    /// </summary>
    /// <param name="MigratorName">The display name of the migrator about to run.</param>
    /// <param name="SkipMigrator">Set to true to skip this migrator.</param>
    [IntegrationEvent(false, false)]
    procedure OnBeforeRunMigrator(MigratorName: Text[250]; var SkipMigrator: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised after migrating a specific entity type.
    /// Subscribe to perform post-processing or logging.
    /// </summary>
    /// <param name="MigratorName">The display name of the migrator that just completed.</param>
    /// <param name="Success">Whether the migrator completed successfully.</param>
    /// <param name="RemainingPercentage">The percentage of records remaining to migrate (100 = all remaining, 0 = all migrated).</param>
    [IntegrationEvent(false, false)]
    procedure OnAfterRunMigrator(MigratorName: Text[250]; Success: Boolean; RemainingPercentage: Integer)
    begin
    end;

    /// <summary>
    /// Integration event raised before executing a migration action.
    /// Subscribe to perform pre-processing or to skip specific actions.
    /// </summary>
    /// <param name="ActionId">The enum value identifying the action about to run.</param>
    /// <param name="ActionName">The display name of the action about to run.</param>
    /// <param name="SkipAction">Set to true to skip this action.</param>
    [IntegrationEvent(false, false)]
    procedure OnBeforeRunAction(ActionId: Enum "BC14 Post Migration Action"; ActionName: Text[250]; var SkipAction: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised after executing a migration action.
    /// Subscribe to perform post-processing or logging.
    /// </summary>
    /// <param name="ActionId">The enum value identifying the action that just completed.</param>
    /// <param name="ActionName">The display name of the action that just completed.</param>
    /// <param name="Success">Whether the action completed successfully.</param>
    [IntegrationEvent(false, false)]
    procedure OnAfterRunAction(ActionId: Enum "BC14 Post Migration Action"; ActionName: Text[250]; Success: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised after the default validation list is populated.
    /// See <see cref="OnAfterPopulateSetupMigrators"/> for replacement semantics.
    /// </summary>
    /// <param name="ValidationList">The default validation list (read-only).</param>
    /// <param name="NewValidations">Replacement list to use when <paramref name="Changed"/> is true.</param>
    /// <param name="Changed">Set to true to replace the default list with <paramref name="NewValidations"/>.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterPopulateValidations(ValidationList: List of [Enum "BC14 Migration Validation"]; var NewValidations: List of [Enum "BC14 Migration Validation"]; var Changed: Boolean)
    begin
    end;

}
