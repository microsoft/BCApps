// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.DataMigration;
using Microsoft.Utilities;
using System.Environment;
using System.Integration;

codeunit 46862 "BC14 Migration Orchestrator"
{

    var
        BC14Telemetry: Codeunit "BC14 Telemetry";
        UpdateStatusOnHybridReplicationCompletedMsg: Label 'Updating status on Business Central 14 migration completed.', Locked = true;
        BC14CloudMigrationReplicationErrorsMsg: Label 'Errors occurred during Business Central 14 Cloud Migration. Error message: %1.', Locked = true, Comment = '%1 = Error message';
        OneStepUpgradeStartingLbl: Label 'Starting One Step Upgrade', Locked = true;
        OneStepUpgradeTok: Label 'One Step Upgrade', Locked = true;
        OneStepUpgradeDisabledLbl: Label 'One Step Upgrade is disabled in settings. Skipping automatic upgrade.', Locked = true;
        OneStepUpgradeNoPendingCompaniesLbl: Label 'One Step Upgrade: No pending companies found to upgrade.', Locked = true;
        OneStepUpgradeNoDataReplicatedLbl: Label 'One Step Upgrade: No data was replicated in run %1. Skipping upgrade (setup run).', Locked = true, Comment = '%1 = Run ID';
        OneStepUpgradeCompanySetupPendingLbl: Label 'One Step Upgrade skipped: company setup is not yet completed. The upgrade will start automatically after the next replication, or you can start it manually once company setup is complete.';
        OneStepUpgradeSchedulingLbl: Label 'One Step Upgrade: Scheduling upgrade for company %1.', Locked = true, Comment = '%1 = Company Name';
        UpgradeWasScheduledMsg: Label 'Upgrade was successfully scheduled';
        AllCompaniesAlreadyUpgradedErr: Label 'All replicated companies have already been upgraded. No further upgrade is needed. If you want to re-migrate, delete the companies and run replication again.';
        CannotUseDataMigrationOverviewMsg: Label 'It is not possible to use the Data Migration Overview page to fix the errors that occurred during Business Central 14 Cloud Migration, it is will not be possible to start the Data Upgrade again. Investigate the issue and after fixing the issue, delete the failed companies and migrate them again.';
        DataMigrationAlreadyStartedErr: Label 'Data migration has already started for the following companies: %1. Additional replication is not allowed. You must delete these companies and replicate them again to start a new migration.', Comment = '%1 = Comma-separated list of company names';
        NoPendingCompaniesErr: Label 'There are no companies with Pending upgrade status. Run the replication first or check if companies have already been upgraded.';
        NoReplicationCompletedErr: Label 'Cannot start upgrade: No replication has been completed yet. Please run replication first before starting the upgrade.';
        ReplicationNotInValidStateErr: Label 'Cannot start upgrade: The replication status is "%1". Upgrade can only be started when replication status is "Upgrade Pending" or "Completed".', Comment = '%1 = Status';
        ReplicationTablesFailedErr: Label 'Cannot start upgrade: %1 tables failed during replication. Fix the replication errors before starting the upgrade.', Comment = '%1 = Number of failed tables';
        CompanySetupNotCompletedSkippingLbl: Label 'Skipping company %1: company setup is not completed yet.', Locked = true, Comment = '%1 = Company Name';
        CompanySetupNotCompletedUserMsg: Label 'Migration skipped: company setup is not yet completed. Open the Assisted Company Setup page (search ''Assisted Setup''), complete the setup wizard for this company, then re-run the migration.';
        CompanySetupPendingSchedulingLbl: Label 'No company has completed setup yet. Scheduling upgrade to start automatically when company creation completes.', Locked = true;
        MarkingAllCompaniesLbl: Label 'Marking all replicated companies as migration started.', Locked = true;
        OneStepUpgradeReentryLbl: Label 'One Step Upgrade: data migration already started for one or more companies. Skipping mark-started step and chaining to the next pending company.', Locked = true;
        CompaniesInUnexpectedStatusLbl: Label '%1 companies are in an unexpected upgrade status (not Pending and not Completed). The affected companies must be removed from the cloud tenant and re-created before the upgrade can be retried.', Locked = true, Comment = '%1 = Number of companies';
        CompaniesInUnexpectedStatusErr: Label 'Some companies are in an unexpected upgrade status (e.g. Failed or Started). To retry, remove the affected companies from the cloud tenant and run cloud migration again to re-create them.';
        OneStepUpgradeFailedLbl: Label 'One Step Upgrade scheduling failed in webhook: %1. The user can start the upgrade manually.', Locked = true, Comment = '%1 = Error text';
        InvokeUpgradeInProcessLbl: Label 'InvokeCompanyUpgrade: running upgrade in-process for company %1 (session creation suppressed by subscriber).', Locked = true, Comment = '%1 = Company Name';
        InvokeUpgradeScheduledTaskLbl: Label 'InvokeCompanyUpgrade: scheduled background task for company %1 with delay %2.', Locked = true, Comment = '%1 = Company Name, %2 = Delay duration';
        InvokeUpgradeStartSessionLbl: Label 'InvokeCompanyUpgrade: TaskScheduler unavailable; falling back to Session.StartSession for company %1.', Locked = true, Comment = '%1 = Company Name';
        InvokeUpgradeStartSessionFallbackMsg: Label 'The background task scheduler is busy. The upgrade will start in a separate session and may take a moment to begin.';

    #region Orchestrator

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Hybrid Cloud Management", 'OnInvokeDataUpgrade', '', false, false)]
    local procedure InvokeDataUpgrade(var HybridReplicationSummary: Record "Hybrid Replication Summary"; var Handled: Boolean)
    var
        BC14Wizard: Codeunit "BC14 Wizard";
    begin
        if Handled then
            exit;

        if not BC14Wizard.GetBC14MigrationEnabled() then
            exit;

        ValidateReplicationBeforeUpgrade(HybridReplicationSummary, true);
        EnsurePendingCompaniesExist();
        MarkUpgradeStarted(HybridReplicationSummary);
        DispatchNextReadyCompany(HybridReplicationSummary);
        Handled := true;

        if GuiAllowed() then
            Message(UpgradeWasScheduledMsg);
    end;

    local procedure EnsurePendingCompaniesExist()
    var
        HybridCompany: Record "Hybrid Company";
        HybridCompanyStatus: Record "Hybrid Company Status";
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
        ReplicatedCompanyCount: Integer;
        CompletedCompanyCount: Integer;
    begin
        BC14StatusMgr.FilterPendingCompanies(HybridCompanyStatus);
        if not HybridCompanyStatus.IsEmpty() then
            exit;

        HybridCompany.SetRange(Replicate, true);
        ReplicatedCompanyCount := HybridCompany.Count();
        if ReplicatedCompanyCount = 0 then
            Error(NoPendingCompaniesErr);

        CompletedCompanyCount := BC14StatusMgr.GetCompletedCompanyCount();
        if CompletedCompanyCount >= ReplicatedCompanyCount then
            Error(AllCompaniesAlreadyUpgradedErr);

        Session.LogMessage('0000TTY', StrSubstNo(CompaniesInUnexpectedStatusLbl, ReplicatedCompanyCount - CompletedCompanyCount), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());
        Error(CompaniesInUnexpectedStatusErr);
    end;

    local procedure MarkUpgradeStarted(var HybridReplicationSummary: Record "Hybrid Replication Summary")
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        BC14GlobalSettings: Record "BC14 Global Migration Settings";
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
    begin
        Session.LogMessage('0000TU0', MarkingAllCompaniesLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());
        BC14CompanySettings.SetDataMigrationStartedForAllCompanies();

        BC14StatusMgr.SetSummaryInProgress(HybridReplicationSummary);
        Commit();

        BC14GlobalSettings.GetOrInsertGlobalSettings(BC14GlobalSettings);
        BC14GlobalSettings."Data Upgrade Started" := CurrentDateTime();
        BC14GlobalSettings.Modify();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Data Migration Mgt.", 'OnBeforeStartMigration', '', false, false)]
    local procedure DisableNewSessionForBC14CloudMigration(var CheckExistingData: Boolean; var StartNewSession: Boolean)
    var
        BC14Wizard: Codeunit "BC14 Wizard";
    begin
        if not BC14Wizard.GetBC14MigrationEnabled() then
            exit;

        StartNewSession := false;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Hybrid Cloud Management", 'OnIsUpgradeSupported', '', false, false)]
    local procedure OnIsUpgradeSupported(var UpgradeSupported: Boolean)
    var
        BC14Wizard: Codeunit "BC14 Wizard";
    begin
        if BC14Wizard.GetBC14MigrationEnabled() then
            UpgradeSupported := true;
    end;

    internal procedure DispatchNextReadyCompany(var HybridReplicationSummary: Record "Hybrid Replication Summary")
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
        CompanyName: Text[30];
    begin
        BC14StatusMgr.FilterPendingCompanies(HybridCompanyStatus);
        if not HybridCompanyStatus.FindSet() then begin
            BC14StatusMgr.TryFinalizeOverallStatus(HybridReplicationSummary);
            exit;
        end;

        repeat
            CompanyName := CopyStr(HybridCompanyStatus.Name, 1, 30);
            if IsCompanySetupCompleted(CompanyName) then begin
                InvokeCompanyUpgrade(HybridReplicationSummary, CompanyName, GetMinimalDelayDuration());
                exit;
            end;
            Session.LogMessage('0000TU1', StrSubstNo(CompanySetupNotCompletedSkippingLbl, CompanyName), Verbosity::Normal, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());
            BC14StatusMgr.UpdateCompanyMessage(CompanyName, CompanySetupNotCompletedUserMsg);
        until HybridCompanyStatus.Next() = 0;
    end;

    internal procedure InvokeCompanyUpgrade(var HybridReplicationSummary: Record "Hybrid Replication Summary"; CompanyName: Text[50]; DelayUpgrade: Duration)
    var
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
        SessionID: Integer;
        RunSynchronously: Boolean;
    begin
        if DelayUpgrade = 0 then
            DelayUpgrade := GetMinimalDelayDuration();

        BC14StatusMgr.SetSummaryInProgress(HybridReplicationSummary);
        Commit();

        OnBeforeScheduleTask(Codeunit::"BC14 Company Upgrade Task", RunSynchronously);
        Commit();

        if RunSynchronously then begin
            Session.LogMessage('0000TXA', StrSubstNo(InvokeUpgradeInProcessLbl, CompanyName), Verbosity::Normal, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());
            Codeunit.Run(Codeunit::"BC14 Company Upgrade Task", HybridReplicationSummary);
            exit;
        end;

        if TaskScheduler.CanCreateTask() then begin
            Session.LogMessage('0000TXB', StrSubstNo(InvokeUpgradeScheduledTaskLbl, CompanyName, DelayUpgrade), Verbosity::Normal, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());
            TaskScheduler.CreateTask(
                Codeunit::"BC14 Company Upgrade Task", Codeunit::"BC14 Migration Failure Handler", true, CompanyName, CurrentDateTime() + DelayUpgrade, HybridReplicationSummary.RecordId, GetDefaultJobTimeout());
        end else begin
            Session.LogMessage('0000TXC', StrSubstNo(InvokeUpgradeStartSessionLbl, CompanyName), Verbosity::Warning, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());
            BC14StatusMgr.UpdateCompanyMessage(CopyStr(CompanyName, 1, 30), InvokeUpgradeStartSessionFallbackMsg);
            Session.StartSession(SessionID, Codeunit::"BC14 Company Upgrade Task", CompanyName, HybridReplicationSummary, GetDefaultJobTimeout());
        end;
    end;

    #endregion

    #region Management

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Hybrid Cloud Management", 'OnHandleRunReplication', '', false, false)]
    local procedure BlockReplicationIfMigrationStarted(var Handled: Boolean; var RunId: Text; ReplicationType: Option)
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        HybridCompany: Record "Hybrid Company";
        BC14Wizard: Codeunit "BC14 Wizard";
        CompanyNames: TextBuilder;
    begin
        if Handled then
            exit;

        if not BC14Wizard.GetBC14MigrationEnabled() then
            exit;

        HybridCompany.SetRange(Replicate, true);
        if HybridCompany.FindSet() then
            repeat
                if BC14CompanySettings.Get(HybridCompany.Name) then
                    if BC14CompanySettings."Data Migration Started" then begin
                        if CompanyNames.Length() > 0 then
                            CompanyNames.Append(', ');
                        CompanyNames.Append(HybridCompany.Name);
                    end;
            until HybridCompany.Next() = 0;

        if CompanyNames.Length() > 0 then
            Error(DataMigrationAlreadyStartedErr, CompanyNames.ToText());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Hybrid Cloud Management", 'OnReplicationRunCompleted', '', false, false)]
    local procedure HandleBC14OnReplicationRunCompleted(RunId: Text[50]; SubscriptionId: Text; NotificationText: Text)
    var
        BC14Wizard: Codeunit "BC14 Wizard";
        HybridCloudManagement: Codeunit "Hybrid Cloud Management";
        BC14UpgradeTrigger: Codeunit "BC14 Upgrade Trigger";
    begin
        if not HybridCloudManagement.CanHandleNotification(SubscriptionId, BC14Wizard.GetMigrationProviderId()) then
            exit;

        UpdateStatusOnHybridReplicationCompleted(RunId);
        HandleInitializationOfBC14Synchronization(RunId, SubscriptionId, NotificationText);

        Commit(); // Ensure HybridCompanyStatus records are committed before TriggerUpgrade

        // Webhook context: any unhandled exception bubbles up as HTTP 500 / pipeline 52100.
        BC14UpgradeTrigger.SetRunId(RunId);
        if not BC14UpgradeTrigger.Run() then
            Session.LogMessage('0000TUC', StrSubstNo(OneStepUpgradeFailedLbl, GetLastErrorText()), Verbosity::Error, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());
    end;

    [EventSubscriber(ObjectType::Page, Page::"Hybrid Cloud Setup Wizard", 'OnSkipShowLiveCompaniesWarning', '', false, false)]
    local procedure HandleSkipCompaniesWizard(var SkipShowLiveCompaniesWarning: Boolean)
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        BC14Wizard: Codeunit "BC14 Wizard";
    begin
        HybridReplicationSummary.SetRange(Source, BC14Wizard.GetMigrationProviderId());
        if HybridReplicationSummary.IsEmpty() then
            exit;

        HybridReplicationSummary.SetFilter(Source, '<>%1', BC14Wizard.GetMigrationProviderId());
        if not HybridReplicationSummary.IsEmpty() then
            exit;

        SkipShowLiveCompaniesWarning := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Hybrid Deployment", 'OnBeforeResetUsersToIntelligentCloudPermissions', '', false, false)]
    local procedure HandleBeforeResetUsersToIntelligentCloudPermissions(var Handled: Boolean)
    var
        BC14Wizard: Codeunit "BC14 Wizard";
    begin
        if not BC14Wizard.GetBC14MigrationEnabled() then
            exit;

        Handled := true;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Data Migration Overview", 'OnOpenPageEvent', '', false, false)]
    local procedure HandleDataMigrationOverviewOpen(var Rec: Record "Data Migration Status")
    var
        BC14Wizard: Codeunit "BC14 Wizard";
    begin
        if not BC14Wizard.GetBC14MigrationEnabled() then
            exit;
        // Inform-only guidance. We deliberately do NOT Error() here:
        //   - OnOpenPageEvent has no Handled flag, so an Error makes the page un-closable
        //     and breaks support engineers who routinely open this page during diagnostics.
        //   - The retry/fix workflow lives on the BC14 Migration Errors page; just point
        //     the user at it instead of blocking them.
        if GuiAllowed() then
            Message(CannotUseDataMigrationOverviewMsg);
    end;

    internal procedure TriggerUpgradeIfOneStepEnabled(RunId: Text[50])
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        HybridReplicationDetail: Record "Hybrid Replication Detail";
        HybridCompanyStatus: Record "Hybrid Company Status";
        BC14GlobalSettings: Record "BC14 Global Migration Settings";
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
        CompanyName: Text[30];
        FirstPendingCompany: Text[30];
    begin
        Session.LogMessage('0000TUD', OneStepUpgradeStartingLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());

        BC14GlobalSettings.GetOrInsertGlobalSettings(BC14GlobalSettings);
        if not BC14GlobalSettings."One Step Upgrade" then begin
            Session.LogMessage('0000TUE', OneStepUpgradeDisabledLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());
            exit;
        end;

        if not HybridReplicationSummary.Get(RunId) then
            exit;

        // A setup-phase run replicates no per-company data and therefore produces no
        // Hybrid Replication Detail rows. Guard against entering the upgrade flow in that
        // case (no companies are selected/created yet), mirroring the other migration tools.
        HybridReplicationDetail.SetRange("Run ID", RunId);
        if HybridReplicationDetail.IsEmpty() then begin
            Session.LogMessage('0000TXR', StrSubstNo(OneStepUpgradeNoDataReplicatedLbl, RunId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());
            exit;
        end;

        if not ValidateReplicationBeforeUpgrade(HybridReplicationSummary, false) then
            exit;

        BC14StatusMgr.FilterPendingCompanies(HybridCompanyStatus);
        if not HybridCompanyStatus.FindSet() then begin
            Session.LogMessage('0000TUF', OneStepUpgradeNoPendingCompaniesLbl, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());
            exit;
        end;

        if BC14CompanySettings.IsAnyCompanyDataMigrationStarted() then begin
            Session.LogMessage('0000TXD', OneStepUpgradeReentryLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());
            DispatchNextReadyCompany(HybridReplicationSummary);
            exit;
        end;

        FirstPendingCompany := CopyStr(HybridCompanyStatus.Name, 1, 30);
        repeat
            CompanyName := CopyStr(HybridCompanyStatus.Name, 1, 30);
            if IsCompanySetupCompleted(CompanyName) then begin
                Session.LogMessage('0000TUG', MarkingAllCompaniesLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());
                BC14CompanySettings.SetDataMigrationStartedForAllCompanies();
                Commit();

                Session.LogMessage('0000TUH', StrSubstNo(OneStepUpgradeSchedulingLbl, CompanyName), Verbosity::Normal, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());
                InvokeCompanyUpgrade(HybridReplicationSummary, CompanyName, BC14GlobalSettings."One Step Upgrade Delay");
                exit;
            end else begin
                Session.LogMessage('0000TUI', StrSubstNo(CompanySetupNotCompletedSkippingLbl, CompanyName), Verbosity::Normal, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());
                InsertReplicationWarning(RunId, CompanyName, OneStepUpgradeCompanySetupPendingLbl);
                BC14StatusMgr.UpdateCompanyMessage(CompanyName, CompanySetupNotCompletedUserMsg);
            end;
        until HybridCompanyStatus.Next() = 0;

        Session.LogMessage('0000TUJ', CompanySetupPendingSchedulingLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());
        BC14CompanySettings.SetDataMigrationStartedForAllCompanies();
        Commit();

        BC14StatusMgr.SetSummaryInProgress(HybridReplicationSummary);
        Commit();

        BC14GlobalSettings."Data Upgrade Started" := CurrentDateTime();
        BC14GlobalSettings.Modify();
        Commit();

        InvokeCompanyUpgrade(HybridReplicationSummary, FirstPendingCompany, BC14GlobalSettings."One Step Upgrade Delay");
    end;

    local procedure UpdateStatusOnHybridReplicationCompleted(RunId: Text[50])
    var
        HybridReplicationDetail: Record "Hybrid Replication Detail";
        HybridMessageManagement: Codeunit "Hybrid Message Management";
        ErrorMessage: Text;
    begin
        Session.LogMessage('0000TUK', UpdateStatusOnHybridReplicationCompletedMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());

        // As of 16.0, Hybrid Replication Detail records are inserted via the pipeline.
        // We only need to update failed records with translated error messages.
        HybridReplicationDetail.SetRange("Run ID", RunId);
        HybridReplicationDetail.SetRange(Status, HybridReplicationDetail.Status::Failed);
        if HybridReplicationDetail.FindSet() then
            repeat
                ErrorMessage := HybridMessageManagement.ResolveMessageCode(HybridReplicationDetail."Error Code", HybridReplicationDetail."Error Message");
                if ErrorMessage <> HybridReplicationDetail."Error Message" then begin
                    HybridReplicationDetail."Error Message" := CopyStr(ErrorMessage, 1, MaxStrLen(HybridReplicationDetail."Error Message"));
                    HybridReplicationDetail.Modify();
                end;
                Session.LogMessage('0000TUL', StrSubstNo(BC14CloudMigrationReplicationErrorsMsg, ErrorMessage), Verbosity::Warning, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());
            until HybridReplicationDetail.Next() = 0;
    end;

    local procedure HandleInitializationOfBC14Synchronization(RunId: Text[50]; SubscriptionId: Text; NotificationText: Text)
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        HybridCloudManagement: Codeunit "Hybrid Cloud Management";
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
    begin
        if HybridReplicationSummary.Get(RunId) and (HybridReplicationSummary.ReplicationType = HybridReplicationSummary.ReplicationType::Diagnostic) then
            exit;

        HybridCloudManagement.SetUpgradePendingOnReplicationRunCompleted(RunId, SubscriptionId, NotificationText);

        if BC14StatusMgr.PerDatabaseStatusExists() then
            BC14StatusMgr.MarkCompanyCompleted('');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Hybrid Cloud Management", 'OnHandleFixDataOnReplicationCompleted', '', false, false)]
    local procedure SkipDataRepair(var Handled: Boolean; var FixData: Boolean)
    var
        BC14Wizard: Codeunit "BC14 Wizard";
    begin
        if not BC14Wizard.GetBC14MigrationEnabled() then
            exit;

        Handled := true;
        FixData := false;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Hybrid Cloud Management", 'OnIsCloudMigrationCompleted', '', false, false)]
    local procedure HandleOnIsCloudMigrationCompleted(SourceProduct: Text; var CloudMigrationCompleted: Boolean)
    var
        HybridCompany: Record "Hybrid Company";
        BC14Wizard: Codeunit "BC14 Wizard";
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
        CompletedCount: Integer;
        ReplicatedCount: Integer;
    begin
        if not BC14Wizard.GetBC14MigrationEnabled() then
            exit;

        HybridCompany.SetRange(Replicate, true);
        ReplicatedCount := HybridCompany.Count();

        CompletedCount := BC14StatusMgr.GetCompletedCompanyCount();

        if (ReplicatedCount > 0) and (CompletedCount >= ReplicatedCount) then
            CloudMigrationCompleted := true
        else
            CloudMigrationCompleted := false;
    end;

    internal procedure GetDefaultJobTimeout(): Duration
    begin
        exit(48 * 60 * 60 * 1000); // 48 hours
    end;

    internal procedure ValidateReplicationBeforeUpgrade(var HybridReplicationSummary: Record "Hybrid Replication Summary"; ThrowError: Boolean): Boolean
    var
        CompletedReplicationSummary: Record "Hybrid Replication Summary";
        HybridReplicationDetail: Record "Hybrid Replication Detail";
        BC14Wizard: Codeunit "BC14 Wizard";
    begin
        if HybridReplicationSummary."Run ID" = '' then begin
            ReportValidationFailure(NoReplicationCompletedErr, ThrowError);
            exit(false);
        end;

        CompletedReplicationSummary.SetRange(Source, BC14Wizard.GetMigrationProviderId());
        CompletedReplicationSummary.SetFilter(Status, '%1|%2|%3',
            CompletedReplicationSummary.Status::Completed,
            CompletedReplicationSummary.Status::UpgradePending,
            CompletedReplicationSummary.Status::UpgradeInProgress);
        if CompletedReplicationSummary.IsEmpty() then begin
            ReportValidationFailure(NoReplicationCompletedErr, ThrowError);
            exit(false);
        end;

        if not (HybridReplicationSummary.Status in [
            HybridReplicationSummary.Status::UpgradePending,
            HybridReplicationSummary.Status::Completed,
            HybridReplicationSummary.Status::UpgradeFailed]) then begin
            ReportValidationFailure(StrSubstNo(ReplicationNotInValidStateErr, Format(HybridReplicationSummary.Status)), ThrowError);
            exit(false);
        end;

        HybridReplicationDetail.SetRange("Run ID", HybridReplicationSummary."Run ID");
        HybridReplicationDetail.SetRange(Status, HybridReplicationDetail.Status::Failed);
        if not HybridReplicationDetail.IsEmpty() then begin
            ReportValidationFailure(StrSubstNo(ReplicationTablesFailedErr, HybridReplicationDetail.Count()), ThrowError);
            exit(false);
        end;

        exit(true);
    end;

    /// <summary>
    /// Emits a warning to telemetry and, when invoked from an interactive path, raises it as
    /// an AL error. The background one-step trigger calls ValidateReplicationBeforeUpgrade
    /// with ThrowError=false and simply retries on the next replication completion, so we must
    /// not write to any user-visible field here.
    /// </summary>
    local procedure ReportValidationFailure(MessageText: Text; ThrowError: Boolean)
    begin
        Session.LogMessage('0000TU4', MessageText, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());

        if ThrowError then
            Error(MessageText);
    end;

    local procedure GetMinimalDelayDuration(): Duration
    begin
        exit(5000);
    end;

    local procedure InsertReplicationWarning(RunId: Text[50]; CompanyName: Text[250]; WarningMessage: Text)
    var
        HybridReplicationDetail: Record "Hybrid Replication Detail";
    begin
        HybridReplicationDetail."Run ID" := RunId;
        HybridReplicationDetail."Company Name" := CompanyName;
        HybridReplicationDetail."Table Name" := OneStepUpgradeTok;
        HybridReplicationDetail.Status := HybridReplicationDetail.Status::Warning;
        HybridReplicationDetail."Error Message" := CopyStr(WarningMessage, 1, MaxStrLen(HybridReplicationDetail."Error Message"));
        HybridReplicationDetail.Insert();
    end;

    internal procedure IsCompanySetupCompleted(CompanyNameToCheck: Text[50]): Boolean
    var
        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
        SetupStatus: Enum "Company Setup Status";
    begin
        if not AssistedCompanySetupStatus.Get(CompanyNameToCheck) then
            exit(false);

        SetupStatus := AssistedCompanySetupStatus.GetCompanySetupStatusValue(CopyStr(CompanyNameToCheck, 1, 30));
        exit(SetupStatus = SetupStatus::Completed);
    end;

    /// <summary>
    /// Called by Historical Task Workers after they finish.
    /// </summary>
    internal procedure TryFinalizeOverallUpgrade()
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
    begin
        if not FindLatestReplicationSummary(HybridReplicationSummary) then
            exit;

        BC14StatusMgr.TryFinalizeOverallStatus(HybridReplicationSummary);
    end;

    internal procedure FindLatestReplicationSummary(var HybridReplicationSummary: Record "Hybrid Replication Summary"): Boolean
    var
        BC14Wizard: Codeunit "BC14 Wizard";
    begin
        HybridReplicationSummary.SetCurrentKey("Start Time");
        HybridReplicationSummary.Ascending(false);
        HybridReplicationSummary.SetRange(Source, BC14Wizard.GetMigrationProviderId());
        exit(HybridReplicationSummary.FindFirst());
    end;

    internal procedure RaiseOnBeforeScheduleTask(CodeunitId: Integer; var RunSynchronously: Boolean)
    begin
        OnBeforeScheduleTask(CodeunitId, RunSynchronously);
    end;

    #endregion

    #region Events

    [IntegrationEvent(false, false)]
    internal procedure OnBeforeScheduleTask(CodeunitId: Integer; var RunSynchronously: Boolean)
    begin
    end;

    #endregion
}
