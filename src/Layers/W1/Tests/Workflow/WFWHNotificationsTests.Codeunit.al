codeunit 134217 "WFWH Notifications Tests"
{
    Permissions = TableData "Workflow Webhook Notification" = rimd;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Workflow] [Webhook] [Notification]
    end;

    var
        WorkflowWebhookNotificationTable: Record "Workflow Webhook Notification";
        WorkflowWebhookNotification: Codeunit "Workflow Webhook Notification";
        Assert: Codeunit Assert;
        MockOnPostNotificationRequest: Codeunit MockOnPostNotificationRequest;
        WorkflowStepInstanceID: Guid;
        RetryCount: Integer;
        EmptyText: Text;

    [Test]
    [Scope('OnPrem')]
    procedure WhenErrorReceived_StatusMustBeFailed()
    begin
        Initialize('ErrorReceived');
        WorkflowWebhookNotification.SendNotification(CreateGuid(), WorkflowStepInstanceID, 'abc', '');
        FindNotificationRecord();
        Assert.AreEqual(WorkflowWebhookNotificationTable.Status,
          WorkflowWebhookNotificationTable.Status::Failed, 'The notification status must be failed.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultipleRetries_OnlyOneRecordMustExist()
    begin
        Initialize('ErrorReceived');
        WorkflowWebhookNotification.SendNotification(CreateGuid(), WorkflowStepInstanceID, 'abc', '');
        WorkflowWebhookNotificationTable.SetCurrentKey("Workflow Step Instance ID");
        WorkflowWebhookNotificationTable.SetRange("Workflow Step Instance ID", WorkflowStepInstanceID);
        Assert.AreEqual(WorkflowWebhookNotificationTable.Count, 1, 'There must be just one record for given WorkflowStepInstanceID');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhenNoErrorReceived_StatusMustBeSent()
    begin
        Initialize('NoErrorReceived');
        WorkflowWebhookNotification.SendNotification(CreateGuid(), WorkflowStepInstanceID, 'abc', '');
        FindNotificationRecord();
        Assert.AreEqual(WorkflowWebhookNotificationTable.Status, WorkflowWebhookNotificationTable.Status::Sent,
          'The notification status must be sent.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhenDataIDIsNull_ThrowError()
    var
        TmpGuid: Guid;
    begin
        WorkflowWebhookNotification.Initialize(RetryCount, 1);
        TmpGuid := CreateGuid();
        Clear(TmpGuid);
        asserterror WorkflowWebhookNotification.SendNotification(TmpGuid, CreateGuid(), 'dd', '');
        Assert.AreEqual(GetLastErrorText, 'DataID cannot be null.', 'Invalid error message.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhenWorkflowStepInstanceIDIsNull_ThrowError()
    var
        TmpGuid: Guid;
    begin
        WorkflowWebhookNotification.Initialize(RetryCount, 1);
        TmpGuid := CreateGuid();
        Clear(TmpGuid);
        asserterror WorkflowWebhookNotification.SendNotification(CreateGuid(), TmpGuid, 'dd', '');
        Assert.AreEqual(GetLastErrorText, 'WorkflowStepInstanceID cannot be null.', 'Invalid error message.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhenNotificationUrlIsNull_ThrowError()
    begin
        WorkflowWebhookNotification.Initialize(RetryCount, 1);
        asserterror WorkflowWebhookNotification.SendNotification(CreateGuid(), CreateGuid(), '', '');
        Assert.AreEqual(GetLastErrorText, 'NotificationUrl cannot be empty.', 'Invalid error message.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhenErrorReceived_ErrorFieldsMustNotBeBlank()
    begin
        Initialize('ErrorReceived');
        WorkflowWebhookNotification.SendNotification(CreateGuid(), WorkflowStepInstanceID, 'abc', '');
        FindNotificationRecord();
        Assert.AreNotEqual(EmptyText, WorkflowWebhookNotificationTable.GetErrorDetails(), 'The error details must not be emtpy.');
        Assert.AreEqual('abc', WorkflowWebhookNotificationTable."Error Message", 'The error message must not be emtpy.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhenErrorThanSuccessReceived_StatusMustBeSuccess()
    begin
        Initialize('ErrorSuccess');
        WorkflowWebhookNotification.SendNotification(CreateGuid(), WorkflowStepInstanceID, 'abc', '');
        FindNotificationRecord();
        Assert.AreEqual(WorkflowWebhookNotificationTable.Status, WorkflowWebhookNotificationTable.Status::Sent,
          'The notification status must be sent.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhenDotNetException_StatusMustBeFail()
    begin
        Initialize('DotNetException');
        WorkflowWebhookNotification.SendNotification(CreateGuid(), WorkflowStepInstanceID, 'abc', '');
        FindNotificationRecord();
        Assert.AreEqual(WorkflowWebhookNotificationTable.Status, WorkflowWebhookNotificationTable.Status::Failed,
          'The notification status must be failed.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhenWebException_Retry()
    begin
        Initialize('WebException');
        WorkflowWebhookNotification.SendNotification(CreateGuid(), WorkflowStepInstanceID, 'abc', '');
        FindNotificationRecord();
        Assert.AreEqual(WorkflowWebhookNotificationTable.Status, WorkflowWebhookNotificationTable.Status::Sent,
          'The notification status must be sent.');
        Assert.AreEqual(EmptyText, WorkflowWebhookNotificationTable."Error Message",
          'The error message must be emtpy.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetGetErrorDetails()
    begin
        Initialize(EmptyText);
        WorkflowWebhookNotificationTable.Init();
        WorkflowWebhookNotificationTable."Workflow Step Instance ID" := WorkflowStepInstanceID;
        WorkflowWebhookNotificationTable.SetErrorDetails('asdf');
        WorkflowWebhookNotificationTable.Insert(true);
        FindNotificationRecord();
        Assert.AreEqual(WorkflowWebhookNotificationTable.GetErrorDetails(), 'asdf', 'Invalid error details');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure When400AndWorkflowTriggerIsNotEnabled_DoNotRetry()
    begin
        Assert.IsFalse(WorkflowWebhookNotification.ShouldRetry(400, 'WorkflowTriggerIsNotEnabled'), 'Retry not required.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure When404AndWorkflowNotFound_DoNotRetry()
    begin
        Assert.IsFalse(WorkflowWebhookNotification.ShouldRetry(404, 'WorkflowNotFound'), 'Retry not required.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure When404AndWorkflowTriggerVersionNotFound_DoNotRetry()
    begin
        Assert.IsFalse(WorkflowWebhookNotification.ShouldRetry(404, 'WorkflowTriggerVersionNotFound'), 'Retry not required.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure When400AndOther_AllowRetry()
    begin
        Assert.IsTrue(WorkflowWebhookNotification.ShouldRetry(400, 'othererror'), 'Retry required.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure When404AndOther_AllowRetry()
    begin
        Assert.IsTrue(WorkflowWebhookNotification.ShouldRetry(404, 'othererror'), 'Retry required.');
    end;

    [Normal]
    local procedure Initialize(ReturnType: Text)
    begin
        RetryCount := 2;
        EmptyText := '';
        WorkflowWebhookNotification.Initialize(RetryCount, 1);
        WorkflowWebhookNotificationTable.DeleteAll();
        WorkflowStepInstanceID := '{BE62A3E0-0518-498D-A27D-023E2736E9E1}';
        UnbindSubscription(MockOnPostNotificationRequest);
        BindSubscription(MockOnPostNotificationRequest);
        MockOnPostNotificationRequest.SetReturnType(ReturnType);
    end;

    [Normal]
    local procedure FindNotificationRecord()
    begin
        WorkflowWebhookNotificationTable.SetCurrentKey("Workflow Step Instance ID");
        WorkflowWebhookNotificationTable.SetRange("Workflow Step Instance ID", WorkflowStepInstanceID);
        WorkflowWebhookNotificationTable.FindFirst();
    end;
}

