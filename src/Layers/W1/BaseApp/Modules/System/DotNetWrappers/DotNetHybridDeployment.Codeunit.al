namespace System.Environment;

using System;

codeunit 3030 DotNet_HybridDeployment
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
    end;

    var
        DotNetALHybridDeployManagement: DotNet ALHybridDeployManagement;

    [Scope('OnPrem')]
    procedure Initialize()
    begin
        DotNetALHybridDeployManagement := DotNetALHybridDeployManagement.ALHybridDeployManagement();
    end;

    [Scope('OnPrem')]
    procedure GetALHybridDeployManagement(var DotNetALHybridDeployManagement2: DotNet ALHybridDeployManagement)
    begin
        DotNetALHybridDeployManagement2 := DotNetALHybridDeployManagement;
    end;

    [Scope('OnPrem')]
    procedure SetALHybridDeployManagement(DotNetALHybridDeployManagement2: DotNet ALHybridDeployManagement)
    begin
        DotNetALHybridDeployManagement := DotNetALHybridDeployManagement2;
    end;

    [Scope('OnPrem')]
    procedure CreateIntegrationRuntime(SourceProduct: Text) InstanceId: Text
    begin
        InstanceId := DotNetALHybridDeployManagement.CreateIntegrationRuntime(SourceProduct);
    end;

    [Scope('OnPrem')]
    procedure DisableDataLakeMigration(SourceProduct: Text) InstanceId: Text
    begin
        InstanceId := DotNetALHybridDeployManagement.DisableDataLakeMigration(SourceProduct);
    end;

    [Scope('OnPrem')]
    procedure DisableReplication(SourceProduct: Text) InstanceId: Text
    begin
        InstanceId := DotNetALHybridDeployManagement.DisableReplication(SourceProduct);
    end;

    [Scope('OnPrem')]
    procedure EnableReplication(SourceProduct: Text; OnPremiseConnectionString: Text; DatabaseType: Text; IntegrationRuntimeName: Text; NotificationUrl: Text; ClientState: Text; SubscriptionId: Text; ServiceNotificationUrl: Text; ServiceClientState: Text; ServiceSubscriptionId: Text) InstanceId: Text
    begin
        InstanceId :=
          DotNetALHybridDeployManagement.EnableReplication(
            SourceProduct, OnPremiseConnectionString, DatabaseType, IntegrationRuntimeName, NotificationUrl, ClientState, SubscriptionId,
            ServiceNotificationUrl, ServiceClientState, ServiceSubscriptionId);
    end;

    [Scope('OnPrem')]
    procedure GetIntegrationRuntimeKey(SourceProduct: Text) InstanceId: Text
    begin
        InstanceId := DotNetALHybridDeployManagement.GetIntegrationRuntimeKey(SourceProduct);
    end;

    [Scope('OnPrem')]
    procedure GetReplicationRunStatus(SourceProduct: Text; RunId: Text) InstanceId: Text
    begin
        InstanceId := DotNetALHybridDeployManagement.GetReplicationRunStatus(SourceProduct, RunId);
    end;

    [Scope('OnPrem')]
    procedure GetRequestStatus(InstanceId: Text; var JsonOutput: Text) Status: Text
    var
        AlGetResponse: DotNet ALGetStatusResponse;
    begin
        AlGetResponse := DotNetALHybridDeployManagement.GetRequestStatus(InstanceId);
        JsonOutput := AlGetResponse.ResponseJson;
        Status := AlGetResponse.Status;
    end;

    [Scope('OnPrem')]
    procedure GetVersionInformation(SourceProduct: Text) InstanceId: Text
    begin
        InstanceId := DotNetALHybridDeployManagement.GetVersionInformation(SourceProduct);
    end;

    [Scope('OnPrem')]
    procedure InitiateDataLakeMigration(SourceProduct: Text; StorageAccountName: Text; StorageAccountKey: Text) InstanceId: Text
    begin
        InstanceId := DotNetALHybridDeployManagement.InitiateDataLakeMigration(SourceProduct, StorageAccountName, StorageAccountKey);
    end;

    [Scope('OnPrem')]
    procedure PrepareTablesForReplication()
    begin
        DotNetALHybridDeployManagement.PrepareTablesForReplication();
    end;

    [Scope('OnPrem')]
    procedure RegenerateIntegrationRuntimeKey(SourceProduct: Text) InstanceId: Text
    begin
        InstanceId := DotNetALHybridDeployManagement.RegenerateIntegrationRuntimeKey(SourceProduct);
    end;

    [Scope('OnPrem')]
    procedure RunReplication(SourceProduct: Text; ReplicationType: Integer) InstanceId: Text
    begin
        InstanceId := DotNetALHybridDeployManagement.RunReplication(SourceProduct, ReplicationType);
    end;

    [Scope('OnPrem')]
    procedure RunUpgrade(SourceProduct: Text) InstanceId: Text
    begin
        InstanceId := DotNetALHybridDeployManagement.RunUpgrade(SourceProduct);
    end;

    [Scope('OnPrem')]
    procedure SetReplicationSchedule(SourceProduct: Text; ReplicationFrequency: Text; DaysToRun: Text; TimeToRun: Time; Activate: Boolean) InstanceId: Text
    begin
        InstanceId :=
          DotNetALHybridDeployManagement.SetReplicationSchedule(
            SourceProduct, ReplicationFrequency, DaysToRun, CreateDateTime(Today, TimeToRun), Activate);
    end;

    [Scope('OnPrem')]
    procedure StartDataUpgrade()
    begin
        DotNetALHybridDeployManagement.StartDataUpgrade();
    end;
}

