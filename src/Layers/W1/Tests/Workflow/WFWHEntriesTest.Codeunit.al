codeunit 134218 "WFWH Entries Test"
{
    EventSubscriberInstance = StaticAutomatic;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Workflow] [Webhook] [Entries]
    end;

    var
        WorkflowWebhookSubscription: Record "Workflow Webhook Subscription";
        WorkflowWebhookNotification: Record "Workflow Webhook Notification";
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
        Assert: Codeunit Assert;
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        MockOnFindTaskSchedulerAllowed: Codeunit MockOnFindTaskSchedulerAllowed;
        MockOnPostNotificationRequest: Codeunit MockOnPostNotificationRequest;
        MockOnFetchInitParams: Codeunit MockOnFetchInitParams;
        WorkflowWebhookEntries: TestPage "Workflow Webhook Entries";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure WhenSwitchingRows_ResubmitActionMustChange()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Setup
        Initialize();
        CreateSubscription();
        MockOnPostNotificationRequest.SetReturnType('ErrorReceived');
        CreateSalesOrderAndSendForApproval(SalesHeader, LibraryRandom.RandIntInRange(5000, 10000));
        MockOnPostNotificationRequest.SetReturnType('NoErrorReceived');
        CreateSalesOrderAndSendForApproval(SalesHeader, LibraryRandom.RandIntInRange(5000, 10000));

        // Exercise
        WorkflowWebhookEntries.OpenView();
        WorkflowWebhookEntries.First();

        // Verify
        Assert.AreEqual(true, WorkflowWebhookEntries.Resubmit.Enabled(), 'Resubmit button must be enabled.');
        WorkflowWebhookEntries.Next();
        Assert.AreEqual(false, WorkflowWebhookEntries.Resubmit.Enabled(), 'Resubmit button must be disabled.');

        // Cleanup
        WorkflowWebhookEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhenResubmittedSuccessfully_ResubmitActionMustBeDisabled()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Setup
        Initialize();
        CreateSubscription();
        MockOnPostNotificationRequest.SetReturnType('ErrorReceived');
        CreateSalesOrderAndSendForApproval(SalesHeader, LibraryRandom.RandIntInRange(5000, 10000));

        // Exercise
        WorkflowWebhookEntries.OpenView();
        WorkflowWebhookEntries.First();
        Assert.AreEqual(true, WorkflowWebhookEntries.Resubmit.Enabled(), 'Resubmit button must be enabled.');
        MockOnPostNotificationRequest.SetReturnType('NoErrorReceived');
        WorkflowWebhookEntries.Resubmit.Invoke();
        Commit();

        // Verify
        Assert.AreEqual(false, WorkflowWebhookEntries.Resubmit.Enabled(), 'Resubmit button must be disabled.');

        // Cleanup
        WorkflowWebhookEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhenNotificationRecordDoesNotExist_NotificationStatusMustBeBlank()
    var
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
        Guid1: Guid;
        Guid2: Guid;
    begin
        // Setup
        Guid1 := CreateGuid();
        Guid2 := CreateGuid();

        WorkflowWebhookEntry.DeleteAll();
        WorkflowWebhookEntry.Init();
        WorkflowWebhookEntry."Workflow Step Instance ID" := Guid1;
        WorkflowWebhookEntry.Response := WorkflowWebhookEntry.Response::Pending;
        WorkflowWebhookEntry.Insert();
        Commit();
        Clear(WorkflowWebhookEntry);
        WorkflowWebhookEntry.Init();
        WorkflowWebhookEntry."Workflow Step Instance ID" := Guid2;
        WorkflowWebhookEntry.Response := WorkflowWebhookEntry.Response::Pending;
        WorkflowWebhookEntry.Insert();
        Commit();
        WorkflowWebhookNotification.DeleteAll();
        WorkflowWebhookNotification.Init();
        WorkflowWebhookNotification."Workflow Step Instance ID" := Guid1;
        WorkflowWebhookNotification.Status := WorkflowWebhookNotification.Status::Sent;
        WorkflowWebhookNotification.Insert();
        Commit();
        // Exercise
        WorkflowWebhookEntries.OpenView();
        WorkflowWebhookEntries.First();
        Assert.AreEqual('Sent',
          WorkflowWebhookEntries.NotificationStatusText.Value, 'Notification status must be sent.');
        WorkflowWebhookEntries.Next();
        // Verify
        Assert.AreEqual('',
          WorkflowWebhookEntries.NotificationStatusText.Value, 'Notification status must be blank.');

        // Cleanup
        WorkflowWebhookEntries.Close();
    end;

    [Normal]
    local procedure CreateSubscription()
    var
        StreamOutObj: OutStream;
    begin
        // Create Subscription that will create workflow definition
        WorkflowWebhookSubscription.Init();
        WorkflowWebhookSubscription."Client Type" := 'Flow';
        WorkflowWebhookSubscription."Client Id" := CreateGuid();
        WorkflowWebhookSubscription."Event Code" := WorkflowEventHandling.RunWorkflowOnSendSalesDocForApprovalCode();
        WorkflowWebhookSubscription.Insert(true);
        Clear(WorkflowWebhookSubscription.Conditions);
        WorkflowWebhookSubscription.Conditions.CreateOutStream(StreamOutObj);
        StreamOutObj.WriteText('eyJIZWFkZXJDb25kaXRpb25zIjpbeyJOYW1lIjoiZG9jdW1lbnRUeXBlIiwiVmFsdWUiOiJPcmRlciJ9L' +
          'HsiTmFtZSI6InN0YXR1cyIsIlZhbHVlIjoiT3BlbiJ9LHsiTmFtZSI6ImFtb3VudCIsIlZhbHVlIjoiPjAifV19');
        Clear(WorkflowWebhookSubscription."Notification Url");
        WorkflowWebhookSubscription."Notification Url".CreateOutStream(StreamOutObj);
        StreamOutObj.WriteText('http://www.bingabc.com');
        WorkflowWebhookSubscription.Modify(true);
    end;

    local procedure Initialize()
    var
        UserSetup: Record "User Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"WFWH Entries Test");
        LibraryVariableStorage.Clear();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateVATPostingSetup();
        UserSetup.DeleteAll();
        LibraryWorkflow.DeleteAllExistingWorkflows();
        WorkflowWebhookEntry.DeleteAll();
        WorkflowWebhookNotification.DeleteAll();
        WorkflowWebhookSubscription.DeleteAll();
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"WFWH Entries Test");
        isInitialized := true;
        UnbindSubscription(LibraryJobQueue);
        BindSubscription(LibraryJobQueue);
        UnbindSubscription(MockOnPostNotificationRequest);
        BindSubscription(MockOnPostNotificationRequest);
        UnbindSubscription(MockOnFindTaskSchedulerAllowed);
        BindSubscription(MockOnFindTaskSchedulerAllowed);
        UnbindSubscription(MockOnFetchInitParams);
        BindSubscription(MockOnFetchInitParams);
        LibraryWorkflow.DeleteAllExistingWorkflows();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"WFWH Entries Test");
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; Amount: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, '', 1);
        SalesLine.Validate("Unit Price", Amount);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrderAndSendForApproval(var SalesHeader: Record "Sales Header"; Amount: Decimal)
    begin
        CreateSalesOrder(SalesHeader, Amount);
        SalesOrderPageSendForApproval(SalesHeader);
    end;

    local procedure SalesOrderPageSendForApproval(var SalesHeader: Record "Sales Header")
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenView();
        SalesOrder.GotoRecord(SalesHeader);
        SalesOrder.SendApprovalRequest.Invoke();
        SalesOrder.Close();
    end;
}

