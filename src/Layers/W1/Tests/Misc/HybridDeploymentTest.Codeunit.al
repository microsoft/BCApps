codeunit 139065 "Hybrid Deployment Test"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Hybrid Deployment]
    end;

    var
        Assert: Codeunit Assert;
        ExpectedOutput: Text;
        ExpectedStatus: Text;
        FailedTxt: Label 'Failed';
        InstanceIdTxt: Label 'Dummy';
        ErrorCodeTxt: Label 'Test 1337';
        ErrorMessageTxt: Label 'Test Failure';
        FailedCreatingIRErr: Label 'Failed to create your integration runtime.';

    local procedure Initialize()
    var
        HybridDeploymentSetup: Record "Hybrid Deployment Setup";
    begin
        if not HybridDeploymentSetup.Get() then begin
            HybridDeploymentSetup.Init();
            HybridDeploymentSetup.Insert();
        end;
        HybridDeploymentSetup."Handler Codeunit ID" := CODEUNIT::"Hybrid Deployment Test";
        HybridDeploymentSetup.Modify();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateIntegrationRuntimeHandlesErrorCode()
    var
        HybridDeploymentTest: Codeunit "Hybrid Deployment Test";
        HybridDeployment: Codeunit "Hybrid Deployment";
        RuntimeName: Text;
        PrimaryKey: Text;
    begin
        // [SCENARIO 283542] Provide error codes/messages for Hybrid Replication Service errors.
        Initialize();

        // [GIVEN] The app requests a new Integration Runtime be created.
        HybridDeploymentTest.SetStatus(FailedTxt);
        HybridDeploymentTest.SetOutput(GenerateJsonFailureOutput(ErrorCodeTxt));
        BindSubscription(HybridDeploymentTest);

        // [WHEN] Hybrid Replication Service returns an error code.
        // [THEN] An error is thrown.
        asserterror HybridDeployment.CreateIntegrationRuntime(RuntimeName, PrimaryKey);
        // [THEN] An appropriate error message is provided.
        Assert.AreEqual(ErrorMessageTxt, GetLastErrorText, 'Unexpected error message');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmDialogNo')]
    procedure DisableReplicationHandlesErrorCode()
    var
        HybridDeploymentTest: Codeunit "Hybrid Deployment Test";
        HybridDeployment: Codeunit "Hybrid Deployment";
    begin
        // [SCENARIO 283542] Provide error codes/messages for Hybrid Replication Service errors.
        Initialize();

        // [GIVEN] The app requests replication be disabled.
        HybridDeploymentTest.SetStatus(FailedTxt);
        HybridDeploymentTest.SetOutput(GenerateJsonFailureOutput(ErrorCodeTxt));
        BindSubscription(HybridDeploymentTest);

        // [WHEN] Hybrid Replication Service returns an error code.
        // [THEN] An error is thrown.
        asserterror HybridDeployment.DisableReplication();
        // [THEN] An appropriate error message is provided.
        Assert.AreEqual(ErrorMessageTxt, GetLastErrorText, 'Unexpected error message');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnableReplicationHandlesErrorCode()
    var
        HybridDeploymentTest: Codeunit "Hybrid Deployment Test";
        HybridDeployment: Codeunit "Hybrid Deployment";
        DummyOnPremConnectionString: Text;
        DummyDatabaseConfiguration: Text;
        DummyRuntimeName: Text;
    begin
        // [SCENARIO 283542] Provide error codes/messages for Hybrid Replication Service errors.
        Initialize();

        // [GIVEN] The app requests replication be enabled.
        HybridDeploymentTest.SetStatus(FailedTxt);
        HybridDeploymentTest.SetOutput(GenerateJsonFailureOutput(ErrorCodeTxt));
        BindSubscription(HybridDeploymentTest);

        // [WHEN] Hybrid Replication Service returns an error code.
        // [THEN] An error is thrown.
        asserterror HybridDeployment.EnableReplication(DummyOnPremConnectionString, DummyDatabaseConfiguration, DummyRuntimeName);

        // [THEN] An appropriate error message is provided.
        Assert.AreEqual(ErrorMessageTxt, GetLastErrorText, 'Unexpected error message');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetIntegrationRuntimeKeysHandlesErrorCode()
    var
        HybridDeploymentTest: Codeunit "Hybrid Deployment Test";
        HybridDeployment: Codeunit "Hybrid Deployment";
        PrimaryKey: Text;
        SecondaryKey: Text;
    begin
        // [SCENARIO 283542] Provide error codes/messages for Hybrid Replication Service errors.
        Initialize();

        // [GIVEN] The app requests to get Integration Runtime keys.
        HybridDeploymentTest.SetStatus(FailedTxt);
        HybridDeploymentTest.SetOutput(GenerateJsonFailureOutput(ErrorCodeTxt));
        BindSubscription(HybridDeploymentTest);

        // [WHEN] Hybrid Replication Service returns an error code.
        // [THEN] An error is thrown.
        asserterror HybridDeployment.GetIntegrationRuntimeKeys(PrimaryKey, SecondaryKey);

        // [THEN] An appropriate error message is provided.
        Assert.AreEqual(ErrorMessageTxt, GetLastErrorText, 'Unexpected error message');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetReplicationRunErrorsHandlesErrorCode()
    var
        HybridDeploymentTest: Codeunit "Hybrid Deployment Test";
        HybridDeployment: Codeunit "Hybrid Deployment";
        DummyReplicationRunId: Text;
        ReplicationRunErrors: Text;
        ReplicationRunStatus: Text;
    begin
        // [SCENARIO 283542] Provide error codes/messages for Hybrid Replication Service errors.
        Initialize();

        // [GIVEN] The app requests to get replication run errors.
        HybridDeploymentTest.SetStatus(FailedTxt);
        HybridDeploymentTest.SetOutput(GenerateJsonFailureOutput(ErrorCodeTxt));
        BindSubscription(HybridDeploymentTest);

        // [WHEN] Hybrid Replication Service returns an error code.
        // [THEN] An error is thrown.
        asserterror HybridDeployment.GetReplicationRunStatus(DummyReplicationRunId, ReplicationRunStatus, ReplicationRunErrors);

        // [THEN] An appropriate error message is provided.
        Assert.AreEqual(ErrorMessageTxt, GetLastErrorText, 'Unexpected error message');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RegenerateIntegrationRuntimeKeysHandlesErrorCode()
    var
        HybridDeploymentTest: Codeunit "Hybrid Deployment Test";
        HybridDeployment: Codeunit "Hybrid Deployment";
        PrimaryKey: Text;
        SecondaryKey: Text;
    begin
        // [SCENARIO 283542] Provide error codes/messages for Hybrid Replication Service errors.
        Initialize();

        // [GIVEN] The app requests to regenerate Integration Runtime keys.
        HybridDeploymentTest.SetStatus(FailedTxt);
        HybridDeploymentTest.SetOutput(GenerateJsonFailureOutput(ErrorCodeTxt));
        BindSubscription(HybridDeploymentTest);

        // [WHEN] Hybrid Replication Service returns an error code.
        // [THEN] An error is thrown.
        asserterror HybridDeployment.RegenerateIntegrationRuntimeKeys(PrimaryKey, SecondaryKey);

        // [THEN] An appropriate error message is provided.
        Assert.AreEqual(ErrorMessageTxt, GetLastErrorText, 'Unexpected error message');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RunReplicationHandlesErrorCode()
    var
        HybridDeploymentTest: Codeunit "Hybrid Deployment Test";
        HybridDeployment: Codeunit "Hybrid Deployment";
        ReplicationRunId: Text;
    begin
        // [SCENARIO 283542] Provide error codes/messages for Hybrid Replication Service errors.
        Initialize();

        // [GIVEN] The app requests a manual replication run.
        HybridDeploymentTest.SetStatus(FailedTxt);
        HybridDeploymentTest.SetOutput(GenerateJsonFailureOutput(ErrorCodeTxt));
        BindSubscription(HybridDeploymentTest);

        // [WHEN] Hybrid Replication Service returns an error code.
        // [THEN] An error is thrown.
        asserterror HybridDeployment.RunReplication(ReplicationRunId, 0);

        // [THEN] An appropriate error message is provided.
        Assert.AreEqual(ErrorMessageTxt, GetLastErrorText, 'Unexpected error message');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetReplicationScheduleHandlesErrorCode()
    var
        HybridDeploymentTest: Codeunit "Hybrid Deployment Test";
        HybridDeployment: Codeunit "Hybrid Deployment";
        DummyReplicationFrequency: Text;
        DummyDaysToRun: Text;
        DummyTimeToRun: Time;
        DummyActivate: Boolean;
    begin
        // [SCENARIO 283542] Provide error codes/messages for Hybrid Replication Service errors.
        Initialize();

        // [GIVEN] The app requests a new replication schedule.
        HybridDeploymentTest.SetStatus(FailedTxt);
        HybridDeploymentTest.SetOutput(GenerateJsonFailureOutput(ErrorCodeTxt));
        BindSubscription(HybridDeploymentTest);

        // [WHEN] Hybrid Replication Service returns an error code.
        // [THEN] An error is thrown.
        asserterror HybridDeployment.SetReplicationSchedule(DummyReplicationFrequency, DummyDaysToRun, DummyTimeToRun, DummyActivate);
        // [THEN] An appropriate error message is provided.
        Assert.AreEqual(ErrorMessageTxt, GetLastErrorText, 'Unexpected error message');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReturnsGenericMessageOnFailureWithNoErrorMessage()
    var
        HybridDeploymentTest: Codeunit "Hybrid Deployment Test";
        HybridDeployment: Codeunit "Hybrid Deployment";
        RuntimeName: Text;
        PrimaryKey: Text;
    begin
        // [SCENARIO 283542] Provide error codes/messages for Hybrid Replication Service errors.
        Initialize();

        // [GIVEN] The app makes a request to Hybrid Replication Service.
        HybridDeploymentTest.SetStatus(FailedTxt);
        HybridDeploymentTest.SetOutput('nouwefnjowvdnjvdnjniu');
        BindSubscription(HybridDeploymentTest);

        // [WHEN] Hybrid Replication Service returns an unexpected error code.
        // [THEN] An error is thrown.
        asserterror HybridDeployment.CreateIntegrationRuntime(RuntimeName, PrimaryKey);
        // [THEN] An appropriate error message is provided.
        Assert.ExpectedError(FailedCreatingIRErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure HandlesEmptyInstanceId()
    var
        HybridDeploymentSetup: Record "Hybrid Deployment Setup";
        HybridDeployment: Codeunit "Hybrid Deployment";
        RunId: Text;
    begin
        // [SCENARIO 292002] If the request is not handled, throw an error.
        Initialize();

        // [GIVEN] No handler codeunit is set to handle the request.
        HybridDeploymentSetup.Get();
        HybridDeploymentSetup."Handler Codeunit ID" := 0;
        HybridDeploymentSetup.Modify();

        // [WHEN] A hybrid service request is attempted
        asserterror HybridDeployment.RunReplication(RunId, 0);

        // [THEN] An error is thrown
        Assert.AreEqual('', RunId, 'RunId should be empty');
    end;

    local procedure GenerateJsonFailureOutput(ErrorCode: Text) Output: Text
    begin
        Output := StrSubstNo('{ "ErrorCode": "%1" }', ErrorCode);
    end;

    [ConfirmHandler]
    procedure ConfirmDialogNo(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [Scope('OnPrem')]
    procedure SetOutput(NewOutput: Text)
    begin
        ExpectedOutput := NewOutput;
    end;

    [Scope('OnPrem')]
    procedure SetStatus(NewStatus: Text)
    begin
        ExpectedStatus := NewStatus;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Hybrid Deployment", 'OnCreateIntegrationRuntime', '', false, false)]
    local procedure OnCreateIntegrationRuntime(var InstanceId: Text)
    begin
        InstanceId := InstanceIdTxt;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Hybrid Deployment", 'OnDisableReplication', '', false, false)]
    local procedure OnDisableReplication(var InstanceId: Text)
    begin
        InstanceId := InstanceIdTxt;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Hybrid Deployment", 'OnEnableReplication', '', false, false)]
    local procedure OnEnableReplication(OnPremiseConnectionString: Text; DatabaseType: Text; IntegrationRuntimeName: Text; NotificationUrl: Text; ClientState: Text; SubscriptionId: Text; ServiceNotificationUrl: Text; ServiceClientState: Text; ServiceSubscriptionId: Text; var InstanceId: Text)
    begin
        InstanceId := InstanceIdTxt;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Hybrid Deployment", 'OnGetErrorMessage', '', false, false)]
    local procedure OnGetErrorMessage(ErrorCode: Text; var Message: Text)
    begin
        if ErrorCode = ErrorCodeTxt then
            Message := ErrorMessageTxt;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Hybrid Deployment", 'OnGetIntegrationRuntimeKeys', '', false, false)]
    local procedure OnGetIntegrationRuntimeKeys(var InstanceId: Text)
    begin
        InstanceId := InstanceIdTxt;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Hybrid Deployment", 'OnGetReplicationRunStatus', '', false, false)]
    local procedure OnGetReplicationRunStatus(var InstanceId: Text; RunId: Text)
    begin
        InstanceId := InstanceIdTxt;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Hybrid Deployment", 'OnGetRequestStatus', '', false, false)]
    local procedure OnGetRequestStatus(InstanceId: Text; var JsonOutput: Text; var Status: Text)
    begin
        if InstanceId <> InstanceIdTxt then
            exit;

        JsonOutput := ExpectedOutput;
        Status := ExpectedStatus;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Hybrid Deployment", 'OnRegenerateIntegrationRuntimeKeys', '', false, false)]
    local procedure OnRegenerateIntegrationRuntimeKeys(var InstanceId: Text)
    begin
        InstanceId := InstanceIdTxt;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Hybrid Deployment", 'OnRunReplication', '', false, false)]
    local procedure OnRunReplication(var InstanceId: Text)
    begin
        InstanceId := InstanceIdTxt;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Hybrid Deployment", 'OnSetReplicationSchedule', '', false, false)]
    local procedure OnSetReplicationSchedule(ReplicationFrequency: Text; DaysToRun: Text; TimeToRun: Time; Activate: Boolean; var InstanceId: Text)
    begin
        InstanceId := InstanceIdTxt;
    end;
}

