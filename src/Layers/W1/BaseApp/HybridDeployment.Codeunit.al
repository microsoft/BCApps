// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Environment;

using Microsoft.Foundation.Company;
using Microsoft.Upgrade;
using System.Integration;
using System.Text;
using System.Security.AccessControl;
using System.Upgrade;

codeunit 6060 "Hybrid Deployment"
{
    Permissions = TableData "Hybrid Deployment Setup" = rimd,
                  TableData "Intelligent Cloud" = rimd,
                  TableData "Intelligent Cloud Status" = rimd,
                  TableData "Webhook Subscription" = rimd;

    trigger OnRun()
    begin
    end;

    var
        SourceProduct: Text;
        FailedToProcessRequestErr: Label 'The request could not be processed due to an unexpected error.';
        FailedCreatingIRErr: Label 'Failed to create your integration runtime. Please try again later. If the problem continues, contact support.';
        FailedDisableReplicationErr: Label 'Failed to disable replication.';
        CloudMigrationFailedContinueTxt: Label 'The request to remove the integration runtime failed. \Do you want to continue with disabling the replication?\\Error:';
        CloudMigrationFailedContinueQst: Label '%1\%2', Locked = true, Comment = '%1 question to user, %2 error message';
        TelemetryContinuedWithMigrationMsg: Label 'Decided to continue with disabling the replication. Error: %1', Locked = true, Comment = '%1 error message';
        FailedDisableDataLakeMigrationErr: Label 'Failed to disable the Azure Data Lake migration.';
        FailedEnableReplicationErr: Label 'Failed to enable your replication. Make sure your integration runtime is successfully connected and try again.';
        FailedGettingStatusErr: Label 'Failed to retrieve the replication run status.';
        FailedGettingIRKeyErr: Label 'Failed to get your integration runtime key. Please try again.';
        FailedGettingVersionInformationErr: Label 'Failed to get the version information. Please try again.';
        FailedPreparingTablesErr: Label 'Failed to prepare tables for replication. See the help document for more information.';
        FailedDataLakeErr: Label 'Failed to start the Azure Data Lake Migration. Please try again.';
        FailedRegeneratingIRKeyErr: Label 'Failed to regenerate your integration runtime key. Please try again.';
        FailedRunReplicationErr: Label 'Failed to trigger replication. Please try again.';
        FailedRunUpgradeErr: Label 'Failed to trigger upgrade. Please try again.';
        FailedSetRepScheduleErr: Label 'Failed to set the replication schedule. Please try again.';
        CompletedTxt: Label 'Completed', Locked = true;
        FailedTxt: Label 'Failed', Locked = true;
        InvalidProductErr: Label 'The product specified in the request is invalid.';
        InvalidRunIdErr: Label 'The specified replication run could not be found.';
        InvalidTenantErr: Label 'The tenant specified in the request is invalid for the request.';
        InvalidIntegrationRuntimeNameErr: Label 'The integration runtime name specified is invalid.';
        NoIntegrationRuntimeErr: Label 'The tenant is not configured to use an integration runtime.';
        PrepareServersFailureErr: Label 'Failed to prepare the systems for replication.';
        ReplicationNotEnabledErr: Label 'Cannot perform the requested action because replication of data between on-premises and the cloud has not been set up. Please contact your administrator.';
        SelfHostedIRNotFoundErr: Label 'Could not find the self-hosted integration runtime. Please ensure the self-hosted integration runtime is running and connected.';
        ConnectionStringFailureErr: Label 'The connection string is invalid.';
        SqlTimeoutErr: Label 'The server timed out while attempting to connect to the specified SQL server.';
        TooManyReplicationRunsErr: Label 'Cannot start replication because a replication is currently in progress. Please try again at a later time.';
        NoAdfCapacityErr: Label 'The cloud migration service is temporarily unable to process your request. Please try again at a later time.';
        RaisingOnCanStartUpgradeForCompanyTxt: Label 'Raising OnCanStartUpgrade for company %1.', Locked = true;
        VerifyingIfUpgradeCanBeStartedMsg: Label 'Verifying if upgrade can be started. Target version %1.%2, current version %3.%4', Locked = true;
        CloudMigrationTok: Label 'CloudMigration', Locked = true;

    [Scope('OnPrem')]
    procedure Initialize(SourceProductId: Text)
    begin
        SourceProduct := SourceProductId;
        OnInitialize(SourceProductId);
    end;

    [Scope('OnPrem')]
    procedure CreateIntegrationRuntime(var RuntimeName: Text; var PrimaryKey: Text)
    var
        JSONManagement: Codeunit "JSON Management";
        InstanceId: Text;
        JsonOutput: Text;
    begin
        if not TryCreateIntegrationRuntime(InstanceId) then
            Error(FailedCreatingIRErr);

        RetryGetStatus(InstanceId, FailedCreatingIRErr, JsonOutput);

        JSONManagement.InitializeObject(JsonOutput);
        JSONManagement.GetStringPropertyValueByName('Name', RuntimeName);
        JSONManagement.GetStringPropertyValueByName('PrimaryKey', PrimaryKey);
    end;

    [Scope('OnPrem')]
    procedure DisableReplication()
    var
        InstanceId: Text;
        Output: Text;
        DisableReplicationFailed: Boolean;
    begin
        DisableReplicationFailed := not TryDisableReplication(InstanceId);
        if DisableReplicationFailed then begin
            Sleep(2000);
            DisableReplicationFailed := not TryDisableReplication(InstanceId);
        end;

        if DisableReplicationFailed then begin
            if not GuiAllowed() then
                Error(FailedDisableReplicationErr);

            if not Confirm(StrSubstNo(CloudMigrationFailedContinueQst, CloudMigrationFailedContinueTxt, GetLastErrorText())) then
                Error(FailedDisableReplicationErr);
        end;

        RetryGetStatus(InstanceId, FailedDisableReplicationErr, Output, true);

        EnableIntelligentCloud(false);

        OnAfterDisableReplication(InstanceId);
    end;

    [Scope('OnPrem')]
    procedure DisableDataLakeMigration()
    var
        InstanceId: Text;
        Output: Text;
    begin
        if not TryDisableDataLakeMigration(InstanceId) then
            Error(FailedDisableDataLakeMigrationErr);

        RetryGetStatus(InstanceId, FailedDisableDataLakeMigrationErr, Output);
    end;

    [Scope('OnPrem')]
    procedure EnableReplication(OnPremConnectionString: Text; DatabaseConfiguration: Text; IntegrationRuntimeName: Text)
    var
        PermissionManager: Codeunit "Permission Manager";
        NotificationUrl: Text;
        SubscriptionId: Text[150];
        ClientState: Text[50];
        InstanceId: Text;
        Output: Text;
        ServiceNotificationUrl: Text;
        ServiceSubscriptionId: Text[150];
        ServiceClientState: Text[50];
        Handled: Boolean;
    begin
        OnBeforeEnableReplication(
          SourceProduct, NotificationUrl, SubscriptionId, ClientState,
          ServiceNotificationUrl, ServiceSubscriptionId, ServiceClientState);

        if not TryEnableReplication(
             InstanceId, OnPremConnectionString, DatabaseConfiguration, IntegrationRuntimeName, NotificationUrl, ClientState,
             SubscriptionId, ServiceNotificationUrl, ServiceClientState, ServiceSubscriptionId)
        then
            Error(FailedEnableReplicationErr);

        RetryGetStatus(InstanceId, FailedEnableReplicationErr, Output);

        EnableIntelligentCloud(true);
        OnBeforeResetUsersToIntelligentCloudPermissions(Handled);
        if Handled then
            exit;

        PermissionManager.ResetUsersToIntelligentCloudPermissions();
    end;

    [Scope('OnPrem')]
    procedure GetIntegrationRuntimeKeys(var PrimaryKey: Text; var SecondaryKey: Text)
    var
        JSONManagement: Codeunit "JSON Management";
        InstanceId: Text;
        JsonOutput: Text;
    begin
        if not TryGetIntegrationRuntimeKeys(InstanceId) then
            Error(FailedGettingIRKeyErr);

        RetryGetStatus(InstanceId, FailedGettingIRKeyErr, JsonOutput);

        JSONManagement.InitializeObject(JsonOutput);
        JSONManagement.GetStringPropertyValueByName('PrimaryKey', PrimaryKey);
        JSONManagement.GetStringPropertyValueByName('SecondaryKey', SecondaryKey);
    end;

    [Scope('OnPrem')]
    procedure GetReplicationRunStatus(RunId: Text; var Status: Text; var Errors: Text)
    var
        JSONManagement: Codeunit "JSON Management";
        InstanceId: Text;
        JsonOutput: Text;
        TempError: Text;
        TempMessage: Text;
        i: Integer;
    begin
        if not TryGetReplicationRunStatus(InstanceId, RunId) then
            Error(FailedGettingStatusErr);

        RetryGetStatus(InstanceId, FailedGettingStatusErr, JsonOutput);

        JSONManagement.InitializeObject(JsonOutput);
        JSONManagement.GetStringPropertyValueByName('Status', Status);
        JSONManagement.GetStringPropertyValueByName('Errors', Errors);
        JSONManagement.InitializeObject(Errors);
        JSONManagement.GetArrayPropertyValueAsStringByName('$values', Errors);
        JSONManagement.InitializeCollection(Errors);

        Errors := '';
        for i := 0 to JSONManagement.GetCollectionCount() - 1 do begin
            JSONManagement.GetObjectFromCollectionByIndex(TempError, i);

            // Check if the error contains an error code and fetch the message
            TempMessage := GetErrorMessage(TempError);
            if TempMessage = '' then
                TempMessage := TempError;

            Errors += TempMessage + '\';
        end;
        Errors := DelChr(Errors, '>', '\');
    end;

    [Scope('OnPrem')]
    procedure GetRequestStatus(RequestTrackingId: Text; var JsonOutput: Text) Status: Text
    begin
        OnGetRequestStatus(RequestTrackingId, JsonOutput, Status);
    end;

    [Scope('OnPrem')]
    procedure GetVersionInformation(var DeployedVersion: Text; var LatestVersion: Text)
    var
        JSONManagement: Codeunit "JSON Management";
        InstanceId: Text;
        JsonOutput: Text;
    begin
        if not TryGetVersionInformation(InstanceId) then
            Error(FailedGettingVersionInformationErr);

        RetryGetStatus(InstanceId, FailedGettingVersionInformationErr, JsonOutput);

        JSONManagement.InitializeObject(JsonOutput);
        JSONManagement.GetStringPropertyValueByName('DeployedVersion', DeployedVersion);
        JSONManagement.GetStringPropertyValueByName('LatestVersion', LatestVersion);
    end;

    [Scope('OnPrem')]
    procedure InitiateDataLakeMigration(var RunId: Text; StorageAccountName: Text; StorageAccountKey: Text)
    var
        JSONManagement: Codeunit "JSON Management";
        InstanceId: Text;
        JsonOutput: Text;
    begin
        if not TryInitiateDataLakeMigration(InstanceId, StorageAccountName, StorageAccountKey) then
            Error(FailedDataLakeErr);

        RetryGetStatus(InstanceId, FailedDataLakeErr, JsonOutput);

        JSONManagement.InitializeObject(JsonOutput);
        JSONManagement.GetStringPropertyValueByName('RunId', RunId);
    end;

    [Scope('OnPrem')]
    procedure PrepareTablesForReplication()
    begin
        if not TryPrepareTablesForReplication() then
            Error(FailedPreparingTablesErr);
    end;

    [Scope('OnPrem')]
    procedure RegenerateIntegrationRuntimeKeys(var PrimaryKey: Text; var SecondaryKey: Text)
    var
        JSONManagement: Codeunit "JSON Management";
        InstanceId: Text;
        JsonOutput: Text;
    begin
        if not TryRegenerateIntegrationRuntimeKeys(InstanceId) then
            Error(FailedRegeneratingIRKeyErr);

        RetryGetStatus(InstanceId, FailedRegeneratingIRKeyErr, JsonOutput);

        JSONManagement.InitializeObject(JsonOutput);
        JSONManagement.GetStringPropertyValueByName('PrimaryKey', PrimaryKey);
        JSONManagement.GetStringPropertyValueByName('SecondaryKey', SecondaryKey);
    end;

    [Scope('OnPrem')]
    procedure ResetCloudData()
    var
        IntelligentCloudStatus: Record "Intelligent Cloud Status";
    begin
        IntelligentCloudStatus.ModifyAll("Synced Version", 0);
        Commit();
    end;

    [Scope('OnPrem')]
    procedure RunReplication(var RunId: Text; ReplicationType: Integer)
    var
        JSONManagement: Codeunit "JSON Management";
        InstanceId: Text;
        JsonOutput: Text;
    begin
        OnBeforeRunReplication();

        if not TryRunReplication(InstanceId, ReplicationType) then
            Error(FailedRunReplicationErr);

        RetryGetStatus(InstanceId, FailedRunReplicationErr, JsonOutput);

        JSONManagement.InitializeObject(JsonOutput);
        JSONManagement.GetStringPropertyValueByName('RunId', RunId);
    end;

    [Scope('OnPrem')]
    procedure StartDataUpgrade()
    begin
        OnStartDataUpgrade();
    end;

    [Scope('OnPrem')]
    procedure RunUpgrade()
    var
        InstanceId: Text;
        JsonOutput: Text;
    begin
        if not TryRunUpgrade(InstanceId) then
            Error(FailedRunUpgradeErr);

        RetryGetStatus(InstanceId, FailedRunUpgradeErr, JsonOutput);
    end;

    [Scope('OnPrem')]
    procedure SetReplicationSchedule(ReplicationFrequency: Text; DaysToRun: Text; TimeToRun: Time; Activate: Boolean)
    var
        InstanceId: Text;
        Output: Text;
    begin
        if not TrySetReplicationSchedule(InstanceId, ReplicationFrequency, DaysToRun, TimeToRun, Activate) then
            Error(FailedSetRepScheduleErr);

        RetryGetStatus(InstanceId, FailedSetRepScheduleErr, Output);
    end;

    procedure SanitizeCompanyBeforeUpgrade()
    var
        IntelligentCloud: Record "Intelligent Cloud";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.SanitizeCloudMigratedDataUpgradeTag()) then
            exit;

        if IntelligentCloud.Get() then
            SanitizeFields(CompanyName(), 0);

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.SanitizeCloudMigratedDataUpgradeTag());
    end;

    procedure SanitizeFields(NameOfCompany: Text; TableID: Integer)
    var
        ALCloudMigration: DotNet ALCloudMigration;
    begin
        if NameOfCompany = '' then begin
            ALCloudMigration.SanitizeFields(true);
            exit;
        end;

        if TableID = 0 then begin
            ALCloudMigration.SanitizeFields(true, NameOfCompany);
            exit;
        end;

        ALCloudMigration.SanitizeFields(true, NameOfCompany, TableID);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company-Initialize", 'OnCompanyInitialize', '', false, false)]
    local procedure HandleCompanyInit()
    var
        HybridDeploymentSetup: Record "Hybrid Deployment Setup";
    begin
        if not HybridDeploymentSetup.IsEmpty() then
            exit;

        HybridDeploymentSetup.Init();
        HybridDeploymentSetup.Insert();
    end;

    local procedure EnableIntelligentCloud(Enabled: Boolean)
    var
        IntelligentCloud: Record "Intelligent Cloud";
    begin
        if not IntelligentCloud.Get() then begin
            IntelligentCloud.Init();
            IntelligentCloud.Enabled := Enabled;
            IntelligentCloud.Insert();
        end else begin
            IntelligentCloud.Enabled := Enabled;
            IntelligentCloud.Modify();
        end;
    end;

    local procedure RetryGetStatus(InstanceId: Text; GenericErrorMessage: Text; var JsonOutput: Text)
    begin
        RetryGetStatus(InstanceId, GenericErrorMessage, JsonOutput, false);
    end;

    local procedure RetryGetStatus(InstanceId: Text; GenericErrorMessage: Text; var JsonOutput: Text; AllowContinue: Boolean)
    var
        Message: Text;
        Status: Text;
    begin
        if InstanceId = '' then
            exit;

        repeat
            Sleep(1000);
            Status := GetRequestStatus(InstanceId, JsonOutput);
        until ((Status = CompletedTxt) or (Status = FailedTxt));

        if Status = FailedTxt then begin
            Message := GetErrorMessage(JsonOutput, GenericErrorMessage);

            if AllowContinue and GuiAllowed() then
                if Confirm(StrSubstNo(CloudMigrationFailedContinueQst, CloudMigrationFailedContinueTxt, Message)) then begin
                    Session.LogMessage('0000E9N', StrSubstNo(TelemetryContinuedWithMigrationMsg, Message), Verbosity::Error, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', CloudMigrationTok);
                    exit;
                end;

            Error(Message);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateIntegrationRuntime(var InstanceId: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDisableDataLakeMigration(var InstanceId: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDisableReplication(var InstanceId: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDisableReplication(var InstanceId: Text);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeEnableReplication(ProductId: Text; var NotificationUrl: Text; var SubscriptionId: Text[150]; var ClientState: Text[50]; var ServiceNotificationUrl: Text; var ServiceSubscriptionId: Text[150]; var ServiceClientState: Text[50])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnEnableReplication(OnPremiseConnectionString: Text; DatabaseType: Text; IntegrationRuntimeName: Text; NotificationUrl: Text; ClientState: Text; SubscriptionId: Text; ServiceNotificationUrl: Text; ServiceClientState: Text; ServiceSubscriptionId: Text; var InstanceId: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetErrorMessage(ErrorCode: Text; var Message: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetIntegrationRuntimeKeys(var InstanceId: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetReplicationRunStatus(var InstanceId: Text; RunId: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetRequestStatus(InstanceId: Text; var JsonOutput: Text; var Status: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetVersionInformation(var InstanceId: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitialize(SourceProductId: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitiateDataLakeMigration(var InstanceId: Text; StorageAccountName: Text; StorageAccountKey: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareTablesForReplication()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRegenerateIntegrationRuntimeKeys(var InstanceId: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunReplication()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunReplication(var InstanceId: Text; ReplicationType: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunUpgrade(var InstanceId: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetReplicationSchedule(ReplicationFrequency: Text; DaysToRun: Text; TimeToRun: Time; Activate: Boolean; var InstanceId: Text)
    begin
    end;

    [TryFunction]
    local procedure TryCreateIntegrationRuntime(var InstanceId: Text)
    begin
        OnCreateIntegrationRuntime(InstanceId);
    end;

    [TryFunction]
    local procedure TryDisableDataLakeMigration(var InstanceId: Text)
    begin
        OnDisableDataLakeMigration(InstanceId);
    end;

    [TryFunction]
    local procedure TryDisableReplication(var InstanceId: Text)
    begin
        OnDisableReplication(InstanceId);
    end;

    [TryFunction]
    local procedure TryEnableReplication(var InstanceId: Text; OnPremConnectionString: Text; DatabaseConfiguration: Text; IntegrationRuntimeName: Text; NotificationUrl: Text; ClientState: Text; SubscriptionId: Text; ServiceNotificationUrl: Text; ServiceClientState: Text; ServiceSubscriptionId: Text)
    begin
        OnEnableReplication(
          OnPremConnectionString, DatabaseConfiguration, IntegrationRuntimeName, NotificationUrl, ClientState, SubscriptionId,
          ServiceNotificationUrl, ServiceClientState, ServiceSubscriptionId, InstanceId);
        ValidateInstanceId(InstanceId);
    end;

    [TryFunction]
    local procedure TryGetIntegrationRuntimeKeys(var InstanceId: Text)
    begin
        OnGetIntegrationRuntimeKeys(InstanceId);
        ValidateInstanceId(InstanceId);
    end;

    [TryFunction]
    local procedure TryGetReplicationRunStatus(var InstanceId: Text; RunId: Text)
    begin
        OnGetReplicationRunStatus(InstanceId, RunId);
        ValidateInstanceId(InstanceId);
    end;

    [TryFunction]
    local procedure TryGetVersionInformation(var InstanceId: Text)
    begin
        OnGetVersionInformation(InstanceId);
        ValidateInstanceId(InstanceId);
    end;

    [TryFunction]
    local procedure TryInitiateDataLakeMigration(var InstanceId: Text; StorageAccountName: Text; StorageAccountKey: Text)
    begin
        OnInitiateDataLakeMigration(InstanceId, StorageAccountName, StorageAccountKey);
        ValidateInstanceId(InstanceId);
    end;

    [TryFunction]
    local procedure TryPrepareTablesForReplication()
    begin
        OnPrepareTablesForReplication();
    end;

    [TryFunction]
    local procedure TryRegenerateIntegrationRuntimeKeys(var InstanceId: Text)
    begin
        OnRegenerateIntegrationRuntimeKeys(InstanceId);
        ValidateInstanceId(InstanceId);
    end;

    [TryFunction]
    local procedure TryRunReplication(var InstanceId: Text; ReplicationType: Integer)
    begin
        OnRunReplication(InstanceId, ReplicationType);
        ValidateInstanceId(InstanceId);
    end;

    [TryFunction]
    local procedure TryRunUpgrade(var InstanceId: Text)
    begin
        OnRunUpgrade(InstanceId);
        ValidateInstanceId(InstanceId);
    end;

    [TryFunction]
    local procedure TrySetReplicationSchedule(var InstanceId: Text; ReplicationFrequency: Text; DaysToRun: Text; TimeToRun: Time; Activate: Boolean)
    begin
        OnSetReplicationSchedule(ReplicationFrequency, DaysToRun, TimeToRun, Activate, InstanceId);
        ValidateInstanceId(InstanceId);
    end;

    [TryFunction]
    local procedure TryGetError(JsonOutput: Text; var ErrorCode: Text; var Message: Text)
    var
        JSONManagement: Codeunit "JSON Management";
    begin
        JSONManagement.InitializeObject(JsonOutput);
        JSONManagement.GetStringPropertyValueByName('ErrorCode', ErrorCode);
        JSONManagement.GetStringPropertyValueByName('Message', Message);
    end;

    local procedure GetErrorMessage(JsonOutput: Text) Message: Text
    begin
        Message := GetErrorMessage(JsonOutput, '');
    end;

    local procedure GetErrorMessage(JsonOutput: Text; GenericError: Text) Message: Text
    var
        ErrorCode: Text;
        ErrorMessage: Text;
    begin
        if not TryGetError(JsonOutput, ErrorCode, ErrorMessage) or ((ErrorCode = '') and (ErrorMessage = '')) then
            exit(GenericError);

        Session.LogMessage('00006NE', StrSubstNo('Error occurred in replication service.\n  Error Code: %1\n  Message: %2', ErrorCode, ErrorMessage), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CloudMigrationTok);

        // Check if a subscriber has a error message for the given code
        OnGetErrorMessage(ErrorCode, Message);

        if Message <> '' then
            exit;

        case ErrorCode of
            '52010':
                Message := InvalidProductErr;
            '52015':
                Message := InvalidRunIdErr;
            '52020':
                Message := InvalidTenantErr;
            '52030':
                Message := InvalidIntegrationRuntimeNameErr;
            '52040':
                Message := NoIntegrationRuntimeErr;
            '52050':
                Message := PrepareServersFailureErr;
            '52060':
                Message := ReplicationNotEnabledErr;
            '52071':
                Message := SelfHostedIRNotFoundErr;
            '52072':
                Message := ConnectionStringFailureErr;
            '52073':
                Message := SqlTimeoutErr;
            '52080':
                Message := TooManyReplicationRunsErr;
            '52090':
                Message := NoAdfCapacityErr;
            else
                Message := GenericError
        end;

        if Message = '' then
            Message := ErrorMessage
        else
            if ErrorMessage <> '' then
                Message += '\\' + ErrorMessage;
    end;

    local procedure ValidateInstanceId(InstanceId: Text)
    begin
        if InstanceId = '' then begin
            Session.LogMessage('00007HU', 'Received an empty response from the replication service.', Verbosity::Error, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', CloudMigrationTok);
            Error(FailedToProcessRequestErr);
        end;
    end;

    internal procedure VerifyCanStartUpgrade(CompanyName: Text): Boolean
    var
        IntelligentCloud: Record "Intelligent Cloud";
        CurrentModuleInfo: ModuleInfo;
        CanStartUpgrade: Boolean;
        Handled: Boolean;
        SkipVersionCheck: Boolean;
    begin
        if not IntelligentCloud.Get() then
            exit(true);

        if not IntelligentCloud.Enabled then
            exit(true);

        OnHandleVerifyCanStartUpgrade(CanStartUpgrade, Handled);
        if Handled then
            exit(CanStartUpgrade);

        NavApp.GetCurrentModuleInfo(CurrentModuleInfo);

        Session.LogMessage('0000IGD', StrSubstNo(VerifyingIfUpgradeCanBeStartedMsg, CurrentModuleInfo.AppVersion().Major, CurrentModuleInfo.AppVersion().Minor, CurrentModuleInfo.DataVersion().Major, CurrentModuleInfo.DataVersion().Minor), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CloudMigrationTok);

        // Skip HFes
        OnSkipMinorAndMajorVersionCheck(SkipVersionCheck);
        if not SkipVersionCheck then
            if (CurrentModuleInfo.AppVersion().Major = CurrentModuleInfo.DataVersion().Major) and (CurrentModuleInfo.AppVersion().Minor = CurrentModuleInfo.DataVersion().Minor) then
                exit(false);

        Session.LogMessage('0000IGE', StrSubstNo(RaisingOnCanStartUpgradeForCompanyTxt, CompanyName), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CloudMigrationTok);
        OnCanStartUpgrade(CompanyName);
        exit(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCanStartUpgrade(CompanyName: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnStartDataUpgrade()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHandleVerifyCanStartUpgrade(var CanStartUpgrade: Boolean; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSkipMinorAndMajorVersionCheck(var SkipVersionCheck: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeResetUsersToIntelligentCloudPermissions(var Handled: Boolean)
    begin
    end;
}

