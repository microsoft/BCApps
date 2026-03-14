// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;

using Microsoft.DataMigration;
using System.Environment;
using System.Integration;
using System.Text;

codeunit 50162 "BC14 Management"
{
    var
        UpdateStatusOnHybridReplicationCompletedMsg: Label 'Updating status on BC14 migration completed.', Locked = true;
        BC14CloudMigrationReplicationErrorsMsg: Label 'Errors occurred during BC14 Cloud Migration. Error message: %1.', Locked = true;
        OneStepUpgradeStartingLbl: Label 'Starting One Step Upgrade', Locked = true;
        OneStepUpgradeDisabledLbl: Label 'One Step Upgrade is disabled in settings. Skipping automatic upgrade.', Locked = true;
        OneStepUpgradeAbortedFailedTablesLbl: Label 'One Step Upgrade aborted: %1 tables failed during replication.', Locked = true;
        OneStepUpgradePendingCompaniesLbl: Label 'One Step Upgrade: Found %1 pending companies to upgrade.', Locked = true;
        OneStepUpgradeNoPendingCompaniesLbl: Label 'One Step Upgrade: No pending companies found to upgrade.', Locked = true;
        OneStepUpgradeSchedulingLbl: Label 'One Step Upgrade: Scheduling upgrade for company %1.', Locked = true;
        UpgradeWasScheduledMsg: Label 'Upgrade was successfully scheduled';
        AllCompaniesAlreadyUpgradedErr: Label 'All replicated companies have already been upgraded. No further upgrade is needed. If you want to re-migrate, delete the companies and run replication again.';
        CannotUseDataMigrationOverviewMsg: Label 'It is not possible to use the Data Migration Overview page to fix the errors that occurred during BC14 Cloud Migration, it is will not be possible to start the Data Upgrade again. Investigate the issue and after fixing the issue, delete the failed companies and migrate them again.';
        DataMigrationAlreadyStartedErr: Label 'Data migration has already started for company %1 on %2. Additional replication is not allowed. You must delete this company and replicate it again to start a new migration.', Comment = '%1 = Company Name, %2 = DateTime';
        NoPendingCompaniesErr: Label 'There are no companies with Pending upgrade status. Run the replication first or check if companies have already been upgraded.';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Hybrid Cloud Management", 'OnHandleRunReplication', '', false, false)]
    local procedure BlockReplicationIfMigrationStarted(var Handled: Boolean; var RunId: Text; ReplicationType: Option)
    var
        BC14CompanyAdditionalSettings: Record "BC14CompanyAdditionalSettings";
        HybridCompany: Record "Hybrid Company";
        BC14Wizard: Codeunit "BC14 Wizard";
    begin
        if Handled then
            exit;

        if not BC14Wizard.GetBC14MigrationEnabled() then
            exit;

        // Check all companies that are selected for replication
        HybridCompany.SetRange(Replicate, true);
        if HybridCompany.FindSet() then
            repeat
                if BC14CompanyAdditionalSettings.Get(HybridCompany.Name) then
                    if BC14CompanyAdditionalSettings."Data Migration Started" then
                        Error(DataMigrationAlreadyStartedErr, HybridCompany.Name, BC14CompanyAdditionalSettings."Data Migration Started At");
            until HybridCompany.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Hybrid Cloud Management", 'OnReplicationRunCompleted', '', false, false)]
    local procedure HandleBC14OnReplicationRunCompleted(RunId: Text[50]; SubscriptionId: Text; NotificationText: Text)
    var
        BC14Wizard: Codeunit "BC14 Wizard";
        HybridCloudManagement: Codeunit "Hybrid Cloud Management";
    begin
        if not HybridCloudManagement.CanHandleNotification(SubscriptionId, BC14Wizard.GetMigrationProviderId()) then
            exit;

        UpdateStatusOnHybridReplicationCompleted(RunId, NotificationText);
        HandleInitializationOfBC14Synchronization(RunId, SubscriptionId, NotificationText);

        Commit(); // Ensure HybridCompanyStatus records are committed before TriggerUpgrade

        TriggerUpgradeIfOneStepEnabled(RunId);
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
        if not (BC14Wizard.GetBC14MigrationEnabled()) then
            exit;
        Message(CannotUseDataMigrationOverviewMsg);
    end;

    local procedure TriggerUpgradeIfOneStepEnabled(RunId: Text[50])
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
        HybridReplicationDetail: Record "Hybrid Replication Detail";
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        BC14UpgradeSettings: Record "BC14 Upgrade Settings";
        BC14HelperFunctions: Codeunit "BC14 Helper Functions";
        FailedTableCount: Integer;
        PendingCompanyCount: Integer;
    begin
        Session.LogMessage('0000ROK', OneStepUpgradeStartingLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14HelperFunctions.GetTelemetryCategory());

        BC14UpgradeSettings.GetOrInsertBC14UpgradeSettings(BC14UpgradeSettings);
        if not BC14UpgradeSettings."One Step Upgrade" then begin
            Session.LogMessage('0000ROL', OneStepUpgradeDisabledLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14HelperFunctions.GetTelemetryCategory());
            exit;
        end;

        // Check for failed tables - if any, abort upgrade
        HybridReplicationDetail.ReadIsolation := IsolationLevel::ReadUncommitted;
        HybridReplicationDetail.SetRange("Run ID", RunId);
        HybridReplicationDetail.SetRange(Status, HybridReplicationDetail.Status::Failed);
        FailedTableCount := HybridReplicationDetail.Count();
        if FailedTableCount > 0 then begin
            Session.LogMessage('0000ROM', StrSubstNo(OneStepUpgradeAbortedFailedTablesLbl, FailedTableCount), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14HelperFunctions.GetTelemetryCategory());
            exit;
        end;

        // Find pending companies to upgrade
        HybridCompanyStatus.SetFilter(Name, '<>''''');
        HybridCompanyStatus.SetRange("Upgrade Status", HybridCompanyStatus."Upgrade Status"::Pending);
        PendingCompanyCount := HybridCompanyStatus.Count();
        Session.LogMessage('0000RON', StrSubstNo(OneStepUpgradePendingCompaniesLbl, PendingCompanyCount), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14HelperFunctions.GetTelemetryCategory());

        if HybridCompanyStatus.FindFirst() then begin
            HybridReplicationSummary.Get(RunId);
            HybridReplicationSummary.Status := HybridReplicationSummary.Status::UpgradeInProgress;
            HybridReplicationSummary.Modify();
            Commit(); // Ensure status is saved before scheduling task
            Session.LogMessage('0000ROO', StrSubstNo(OneStepUpgradeSchedulingLbl, HybridCompanyStatus.Name), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14HelperFunctions.GetTelemetryCategory());
            InvokeCompanyUpgrade(HybridReplicationSummary, HybridCompanyStatus.Name, BC14UpgradeSettings."One Step Upgrade Delay");
        end else
            Session.LogMessage('0000ROP', OneStepUpgradeNoPendingCompaniesLbl, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14HelperFunctions.GetTelemetryCategory());
    end;

    local procedure UpdateStatusOnHybridReplicationCompleted(RunId: Text[50]; NotificationText: Text)
    var
        HybridReplicationDetail: Record "Hybrid Replication Detail";
        HybridMessageManagement: Codeunit "Hybrid Message Management";
        JsonManagement: Codeunit "JSON Management";
        JsonManagement2: Codeunit "JSON Management";
        BC14HelperFunctions: Codeunit "BC14 Helper Functions";
        ErrorCode: Text;
        ErrorMessage: Text;
        Errors: Text;
        IncrementalTable: Text;
        IncrementalTableCount: Integer;
        Value: Text;
        i: Integer;
        j: Integer;
    begin
        Session.LogMessage('0000ROQ', UpdateStatusOnHybridReplicationCompletedMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14HelperFunctions.GetTelemetryCategory());
        // Get table information, iterate through and create detail records for each
        for j := 1 to 2 do begin
            JsonManagement.InitializeObject(NotificationText);

            // Wrapping these in if/then pairs to ensure backward-compatibility
            if j = 1 then
                if (not JsonManagement.GetArrayPropertyValueAsStringByName('IncrementalTables', Value)) then exit;
            if j = 2 then
                if (not JsonManagement.GetArrayPropertyValueAsStringByName('BC14HistoryTables', Value)) then exit;
            JsonManagement.InitializeCollection(Value);
            IncrementalTableCount := JsonManagement.GetCollectionCount();

            for i := 0 to IncrementalTableCount - 1 do begin
                JsonManagement.GetObjectFromCollectionByIndex(IncrementalTable, i);
                JsonManagement.InitializeObject(IncrementalTable);

                HybridReplicationDetail.Init();
                HybridReplicationDetail."Run ID" := RunId;
                JsonManagement.GetStringPropertyValueByName('TableName', Value);
                HybridReplicationDetail."Table Name" := CopyStr(Value, 1, 250);

                JsonManagement.GetStringPropertyValueByName('CompanyName', Value);
                HybridReplicationDetail."Company Name" := CopyStr(Value, 1, 250);

                HybridReplicationDetail.Status := HybridReplicationDetail.Status::Successful;
                if JsonManagement.GetStringPropertyValueByName('Errors', Errors) and Errors.StartsWith('[') then begin
                    JsonManagement2.InitializeCollection(Errors);
                    if JsonManagement2.GetCollectionCount() > 0 then begin
                        JsonManagement2.GetObjectFromCollectionByIndex(Value, 0);
                        JsonManagement2.InitializeObject(Value);
                        JsonManagement2.GetStringPropertyValueByName('Code', ErrorCode);
                        JsonManagement2.GetStringPropertyValueByName('Message', ErrorMessage);
                    end;
                end else begin
                    JsonManagement.GetStringPropertyValueByName('ErrorMessage', ErrorMessage);
                    JsonManagement.GetStringPropertyValueByName('ErrorCode', ErrorCode);
                end;

                if (ErrorMessage <> '') or (ErrorCode <> '') then begin
                    HybridReplicationDetail.Status := HybridReplicationDetail.Status::Failed;
                    ErrorMessage := HybridMessageManagement.ResolveMessageCode(CopyStr(ErrorCode, 1, 10), ErrorMessage);
                    HybridReplicationDetail."Error Message" := CopyStr(ErrorMessage, 1, 2048);
                    HybridReplicationDetail."Error Code" := CopyStr(ErrorCode, 1, 10);
                    Session.LogMessage('0000ROR', StrSubstNo(BC14CloudMigrationReplicationErrorsMsg, ErrorMessage), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14HelperFunctions.GetTelemetryCategory());
                end;

                HybridReplicationDetail.Insert();
            end;
        end;
    end;

    local procedure HandleInitializationOfBC14Synchronization(RunId: Text[50]; SubscriptionId: Text; NotificationText: Text)
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        HybridCompanyStatus: Record "Hybrid Company Status";
        HybridCloudManagement: Codeunit "Hybrid Cloud Management";
    begin
        // Do not process migration data for a diagnostic run since there should be none
        if HybridReplicationSummary.Get(RunId) and (HybridReplicationSummary.ReplicationType = HybridReplicationSummary.ReplicationType::Diagnostic) then
            exit;

        // Always set upgrade pending after replication completes (regardless of ServiceType)
        // This ensures One Step Upgrade can find pending companies
        HybridCloudManagement.SetUpgradePendingOnReplicationRunCompleted(RunId, SubscriptionId, NotificationText);

        // Remove PerDatabase company status, it is not applicable for BC14
        if HybridCompanyStatus.Get('') then
            HybridCompanyStatus.Delete();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Hybrid Cloud Management", 'OnInvokeDataUpgrade', '', false, false)]
    local procedure InvokeDataUpgrade(var HybridReplicationSummary: Record "Hybrid Replication Summary"; var Handled: Boolean)
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
        HybridCompany: Record "Hybrid Company";
        BC14UpgradeSettings: Record "BC14 Upgrade Settings";
        BC14Wizard: Codeunit "BC14 Wizard";
        ReplicatedCompanyCount: Integer;
        CompletedCompanyCount: Integer;
    begin
        if Handled then
            exit;

        if not BC14Wizard.GetBC14MigrationEnabled() then
            exit;

        // Check if there are any pending companies
        HybridCompanyStatus.SetRange("Upgrade Status", HybridCompanyStatus."Upgrade Status"::Pending);
        if HybridCompanyStatus.IsEmpty() then begin
            // No pending companies - check the actual status of replicated companies
            HybridCompany.SetRange(Replicate, true);
            ReplicatedCompanyCount := HybridCompany.Count();

            if ReplicatedCompanyCount = 0 then
                Error(NoPendingCompaniesErr);

            // Count companies that are already completed
            HybridCompanyStatus.Reset();
            HybridCompanyStatus.SetRange("Upgrade Status", HybridCompanyStatus."Upgrade Status"::Completed);
            CompletedCompanyCount := HybridCompanyStatus.Count();

            // All replicated companies are already completed - upgrade is done
            if CompletedCompanyCount >= ReplicatedCompanyCount then
                Error(AllCompaniesAlreadyUpgradedErr);

            // Some companies are not Pending and not Completed
            // This typically happens when:
            // 1. Replication just completed (with One Step Upgrade disabled) and HybridCompanyStatus records may not exist yet
            // 2. A previous upgrade was interrupted
            // Automatically set these companies to Pending and proceed with upgrade
            if HybridCompany.FindSet() then
                repeat
                    if not HybridCompanyStatus.Get(HybridCompany.Name) then begin
                        // Record doesn't exist - create it with Pending status
                        HybridCompanyStatus.Init();
                        HybridCompanyStatus.Name := HybridCompany.Name;
                        HybridCompanyStatus."Upgrade Status" := HybridCompanyStatus."Upgrade Status"::Pending;
                        HybridCompanyStatus.Insert();
                    end else
                        if HybridCompanyStatus."Upgrade Status" <> HybridCompanyStatus."Upgrade Status"::Completed then begin
                            // Record exists but not Completed - set to Pending for upgrade
                            HybridCompanyStatus."Upgrade Status" := HybridCompanyStatus."Upgrade Status"::Pending;
                            HybridCompanyStatus.Modify();
                        end;
                until HybridCompany.Next() = 0;
            Commit();
        end;

        // Find first pending company to upgrade
        HybridCompanyStatus.Reset();
        HybridCompanyStatus.SetRange("Upgrade Status", HybridCompanyStatus."Upgrade Status"::Pending);
        if not HybridCompanyStatus.FindFirst() then
            Error(NoPendingCompaniesErr);

        // Reset the summary for manual upgrade - set new start time, clear end time and details
        HybridReplicationSummary.Status := HybridReplicationSummary.Status::UpgradeInProgress;
        HybridReplicationSummary."Start Time" := CurrentDateTime();
        HybridReplicationSummary."End Time" := 0DT;
        Clear(HybridReplicationSummary.Details);
        HybridReplicationSummary.Modify();
        Commit();

        BC14UpgradeSettings.GetOrInsertBC14UpgradeSettings(BC14UpgradeSettings);
        BC14UpgradeSettings."Data Upgrade Started" := CurrentDateTime();
        BC14UpgradeSettings.Modify();

        InvokeCompanyUpgrade(HybridReplicationSummary, HybridCompanyStatus.Name);
        Handled := true;

        if GuiAllowed() then
            Message(UpgradeWasScheduledMsg);
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

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Hybrid Cloud Management", 'OnIsUpgradeSupported', '', false, false)]
    local procedure OnIsUpgradeSupported(var UpgradeSupported: Boolean)
    var
        BC14Wizard: Codeunit "BC14 Wizard";
    begin
        if BC14Wizard.GetBC14MigrationEnabled() then
            UpgradeSupported := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Hybrid Cloud Management", 'OnIsCloudMigrationCompleted', '', false, false)]
    local procedure HandleOnIsCloudMigrationCompleted(SourceProduct: Text; var CloudMigrationCompleted: Boolean)
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
        HybridCompany: Record "Hybrid Company";
        BC14Wizard: Codeunit "BC14 Wizard";
        CompletedCount: Integer;
        ReplicatedCount: Integer;
    begin
        if not BC14Wizard.GetBC14MigrationEnabled() then
            exit;

        // Cloud migration is only completed when ALL replicated companies have Upgrade Status = Completed
        HybridCompany.SetRange(Replicate, true);
        ReplicatedCount := HybridCompany.Count();

        HybridCompanyStatus.SetRange("Upgrade Status", HybridCompanyStatus."Upgrade Status"::Completed);
        CompletedCount := HybridCompanyStatus.Count();

        // Migration is NOT complete if there are replicated companies that haven't been upgraded
        if ReplicatedCount > CompletedCount then
            CloudMigrationCompleted := false;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Cloud Migration Management", 'CheckNewUISupported', '', false, false)]
    local procedure HandleCheckNewUISupported()
    begin
        // BC14 Cloud migration now supports the new UI
    end;

    internal procedure InvokeCompanyUpgrade(var HybridReplicationSummary: Record "Hybrid Replication Summary"; CompanyName: Text[50])
    begin
        InvokeCompanyUpgrade(HybridReplicationSummary, CompanyName, GetMinimalDelayDuration());
    end;

    internal procedure InvokeCompanyUpgrade(var HybridReplicationSummary: Record "Hybrid Replication Summary"; CompanyName: Text[50]; DelayUpgrade: Duration)
    var
        CreateSession: Boolean;
        SessionID: Integer;
    begin
        CreateSession := true;
        OnCreateSessionForUpgrade(CreateSession);
        if not CreateSession then begin
            Codeunit.Run(Codeunit::"BC14 Cloud Migration", HybridReplicationSummary);
            exit;
        end;

        if DelayUpgrade = 0 then
            DelayUpgrade := GetMinimalDelayDuration();

        if TaskScheduler.CanCreateTask() then
            TaskScheduler.CreateTask(
                Codeunit::"BC14 Cloud Migration", Codeunit::"BC14 Handle Upgrade Error", true, CompanyName, CurrentDateTime() + DelayUpgrade, HybridReplicationSummary.RecordId, GetDefaultJobTimeout())
        else
            Session.StartSession(SessionID, Codeunit::"BC14 Cloud Migration", CompanyName, HybridReplicationSummary, GetDefaultJobTimeout());
    end;

    internal procedure GetDefaultJobTimeout(): Duration
    begin
        exit(48 * 60 * 60 * 1000); // 48 hours
    end;

    local procedure GetMinimalDelayDuration(): Duration
    begin
        exit(5000);
    end;

    [InternalEvent(false)]
    local procedure OnCreateSessionForUpgrade(var CreateSession: Boolean)
    begin
    end;
}
