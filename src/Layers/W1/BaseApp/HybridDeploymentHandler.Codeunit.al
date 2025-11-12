// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Environment;

codeunit 6061 "Hybrid Deployment Handler"
{
    Permissions = TableData "Hybrid Deployment Setup" = rimd;
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        DotNet_HybridDeployment: Codeunit DotNet_HybridDeployment;
        SourceProduct: Text;
        StartingCreateIntegrationRuntimeMsg: Label 'Starting Create Integration Runtime', Locked = true;
        StartingEnableReplicationMsg: Label 'Starting Enable Replication', Locked = true;
        StartingDisableReplicationMsg: Label 'Starting Disable Replication', Locked = true;
        StartingRunReplicationMsg: Label 'Starting Run Replication', Locked = true;
        StartingRunUpgradeMsg: Label 'Starting Run Upgrade', Locked = true;
        CloudMigrationTok: Label 'CloudMigration', Locked = true;

    local procedure CanHandle(): Boolean
    var
        HybridDeploymentSetup: Record "Hybrid Deployment Setup";
    begin
        if not HybridDeploymentSetup.Get() then begin
            HybridDeploymentSetup.Init();
            HybridDeploymentSetup.Insert();
        end;

        exit(HybridDeploymentSetup."Handler Codeunit ID" = CODEUNIT::"Hybrid Deployment Handler");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Hybrid Deployment", 'OnCreateIntegrationRuntime', '', false, false)]
    local procedure HandleCreateIntegrationRuntime(var InstanceId: Text)
    begin
        if not CanHandle() then
            exit;

        Session.LogMessage('0000EUS', StartingCreateIntegrationRuntimeMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CloudMigrationTok);
        InstanceId := DotNet_HybridDeployment.CreateIntegrationRuntime(SourceProduct);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Hybrid Deployment", 'OnDisableReplication', '', false, false)]
    local procedure HandleDisableReplication(var InstanceId: Text)
    begin
        if not CanHandle() then
            exit;

        Session.LogMessage('0000EUT', StartingDisableReplicationMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CloudMigrationTok);

        InstanceId := DotNet_HybridDeployment.DisableReplication(SourceProduct);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Hybrid Deployment", 'OnDisableDataLakeMigration', '', false, false)]
    local procedure HandleDisableDataLakeMigration(var InstanceId: Text)
    begin
        if not CanHandle() then
            exit;

        InstanceId := DotNet_HybridDeployment.DisableDataLakeMigration(SourceProduct);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Hybrid Deployment", 'OnEnableReplication', '', false, false)]
    local procedure HandleEnableReplication(OnPremiseConnectionString: Text; DatabaseType: Text; IntegrationRuntimeName: Text; NotificationUrl: Text; ClientState: Text; SubscriptionId: Text; ServiceNotificationUrl: Text; ServiceClientState: Text; ServiceSubscriptionId: Text; var InstanceId: Text)
    begin
        if not CanHandle() then
            exit;

        Session.LogMessage('0000EUU', StartingEnableReplicationMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CloudMigrationTok);

        InstanceId :=
          DotNet_HybridDeployment.EnableReplication(
            SourceProduct, OnPremiseConnectionString, DatabaseType, IntegrationRuntimeName, NotificationUrl, ClientState, SubscriptionId,
            ServiceNotificationUrl, ServiceClientState, ServiceSubscriptionId);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Hybrid Deployment", 'OnGetIntegrationRuntimeKeys', '', false, false)]
    local procedure HandleGetIntegrationRuntimeKeys(var InstanceId: Text)
    begin
        if not CanHandle() then
            exit;

        InstanceId := DotNet_HybridDeployment.GetIntegrationRuntimeKey(SourceProduct);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Hybrid Deployment", 'OnGetReplicationRunStatus', '', false, false)]
    local procedure HandleGetReplicationRunStatus(var InstanceId: Text; RunId: Text)
    begin
        if not CanHandle() then
            exit;

        InstanceId := DotNet_HybridDeployment.GetReplicationRunStatus(SourceProduct, RunId);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Hybrid Deployment", 'OnGetRequestStatus', '', false, false)]
    local procedure HandleGetRequestStatus(InstanceId: Text; var JsonOutput: Text; var Status: Text)
    begin
        if not CanHandle() then
            exit;

        Status := DotNet_HybridDeployment.GetRequestStatus(InstanceId, JsonOutput);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Hybrid Deployment", 'OnGetVersionInformation', '', false, false)]
    local procedure HandleGetVersionInformation(var InstanceId: Text)
    begin
        if not CanHandle() then
            exit;

        InstanceId := DotNet_HybridDeployment.GetVersionInformation(SourceProduct);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Hybrid Deployment", 'OnInitialize', '', false, false)]
    local procedure HandleInitialize(SourceProductId: Text)
    begin
        if not CanHandle() then
            exit;

        SourceProduct := SourceProductId;
        DotNet_HybridDeployment.Initialize();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Hybrid Deployment", 'OnInitiateDataLakeMigration', '', false, false)]
    local procedure HandleInitiateDataLakeMigration(var InstanceId: Text; StorageAccountName: Text; StorageAccountKey: Text)
    begin
        if not CanHandle() then
            exit;

        InstanceId := DotNet_HybridDeployment.InitiateDataLakeMigration(SourceProduct, StorageAccountName, StorageAccountKey);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Hybrid Deployment", 'OnPrepareTablesForReplication', '', false, false)]
    local procedure HandlePrepareTables()
    var
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        if not CanHandle() then
            exit;

        if EnvironmentInfo.IsSaaS() then
            exit;

        DotNet_HybridDeployment.PrepareTablesForReplication();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Hybrid Deployment", 'OnRegenerateIntegrationRuntimeKeys', '', false, false)]
    local procedure HandleRegenerateIntegrationRuntimeKeys(var InstanceId: Text)
    begin
        if not CanHandle() then
            exit;

        InstanceId := DotNet_HybridDeployment.RegenerateIntegrationRuntimeKey(SourceProduct);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Hybrid Deployment", 'OnRunReplication', '', false, false)]
    local procedure HandleRunReplication(var InstanceId: Text; ReplicationType: Integer)
    begin
        if not CanHandle() then
            exit;

        Session.LogMessage('0000EUV', StartingRunReplicationMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CloudMigrationTok);

        InstanceId := DotNet_HybridDeployment.RunReplication(SourceProduct, ReplicationType)
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Hybrid Deployment", 'OnRunUpgrade', '', false, false)]
    local procedure HandleRunUpgrade(var InstanceId: Text)
    begin
        if not CanHandle() then
            exit;

        Session.LogMessage('0000EUW', StartingRunUpgradeMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CloudMigrationTok);
        InstanceId := DotNet_HybridDeployment.RunUpgrade(SourceProduct)
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Hybrid Deployment", 'OnSetReplicationSchedule', '', false, false)]
    local procedure HandleSetReplicationSchedule(ReplicationFrequency: Text; DaysToRun: Text; TimeToRun: Time; Activate: Boolean; var InstanceId: Text)
    begin
        if not CanHandle() then
            exit;

        InstanceId := DotNet_HybridDeployment.SetReplicationSchedule(SourceProduct, ReplicationFrequency, DaysToRun, TimeToRun, Activate);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Hybrid Deployment", 'OnStartDataUpgrade', '', false, false)]
    local procedure HandleStartDataUpgrade()
    begin
        if not CanHandle() then
            exit;

        DotNet_HybridDeployment.StartDataUpgrade();
    end;
}

