codeunit 134221 "WFWH Customer Approval"
{
    EventSubscriberInstance = Manual;
    Permissions = TableData "User Setup" = imd,
                  TableData "Workflow Webhook Entry" = imd;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Approval] [Customer]
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        BogusUserIdTxt: Label 'Contoso';
        DynamicRequestPageParametersCustomerTxt: Label '<?xml version="1.0" encoding="utf-8" standalone="yes"?><ReportParameters><DataItems><DataItem name="Customer">VERSION(1) SORTING(Field1)</DataItem></DataItems></ReportParameters>', Locked = true;
        UnexpectedNoOfWorkflowStepInstancesErr: Label 'Unexpected number of workflow step instances found.';
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        RecordRestrictedErr: Label 'You cannot use %1 for this action.', Comment = 'You cannot use Customer 10000 for this action.';
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        MockOnFindTaskSchedulerAllowed: Codeunit MockOnFindTaskSchedulerAllowed;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure MakeCurrentUserAnApprover()
    var
        UserSetup: Record "User Setup";
    begin
        if not UserSetup.Get(BogusUserIdTxt) then begin
            UserSetup.Init();
            UserSetup."User ID" := BogusUserIdTxt;
            UserSetup."Approver ID" := UserId;
            UserSetup.Insert(true);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RemoveBogusUser()
    var
        UserSetup: Record "User Setup";
    begin
        if UserSetup.Get(BogusUserIdTxt) then
            UserSetup.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureNecessaryTableRelationsAreSetup()
    var
        DummyCustomer: Record Customer;
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowTableRelation: Record "Workflow - Table Relation";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [SCENARIO] Ensure that the necessary webhook customer approval workflow table relations are setup.
        // [WHEN] Workflow setup is initialized.
        // [THEN] Workflow table relations for customer and workflow webhook entry exist.

        // Setup
        LibraryWorkflow.DeleteAllExistingWorkflows();

        // Excercise
        WorkflowSetup.InitWorkflow();

        // Verify
        WorkflowTableRelation.Get(
          DATABASE::Customer, DummyCustomer.FieldNo(SystemId),
          DATABASE::"Workflow Webhook Entry", DummyWorkflowWebhookEntry.FieldNo("Data ID"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureNewCustomerCanBeSentForApproval()
    var
        Customer: Record Customer;
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
    begin
        // [SCENARIO] A user can send a newly created customer for approval.
        // [GIVEN] A new  Customer.
        // [WHEN] The user send an approval request from the customer.
        // [THEN] The Approval flow gets started.

        // Setup
        Initialize();
        CreateAndEnableCustomerWorkflowDefinition(UserId);

        // Exercise - New Customer
        LibrarySales.CreateCustomer(Customer);

        // Exercise - Send for approval
        SendApprovalRequestForCustomer(Customer);

        // Verify
        VerifyWorkflowWebhookEntryResponse(Customer.SystemId, DummyWorkflowWebhookEntry.Response::Pending);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureCustomerApprovalWorkflowFunctionsCorrectlyWhenContinued()
    var
        Customer: Record Customer;
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook customer approval workflow 'approval' path works correctly.
        // [GIVEN] A webhook customer approval workflow for a customer is enabled.
        // [GIVEN] A customer request is pending approval.
        // [WHEN] The webhook customer approval workflow receives an 'approval' response for the customer request.
        // [THEN] The customer request is approved.

        // Setup
        Initialize();
        CreateAndEnableCustomerWorkflowDefinition(UserId);
        MakeCurrentUserAnApprover();
        LibrarySales.CreateCustomer(Customer);

        // Setup - A approval
        SendApprovalRequestForCustomer(Customer);

        Commit();

        // Verify
        VerifyWorkflowWebhookEntryResponse(Customer.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // Exercise
        WorkflowWebhookManagement.ContinueByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(Customer.SystemId));

        // Verify
        VerifyWorkflowWebhookEntryResponse(Customer.SystemId, DummyWorkflowWebhookEntry.Response::Continue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureCustomerApprovalWorkflowFunctionsCorrectlyWhenCancelled()
    var
        Customer: Record Customer;
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook customer approval workflow 'cancellation' path works correctly.
        // [GIVEN] A webhook customer approval workflow for a customer is enabled.
        // [GIVEN] A customer request is pending approval.
        // [WHEN] The webhook customer approval workflow receives a 'cancellation' response for the customer request.
        // [THEN] The customer request is cancelled.

        // Setup
        Initialize();
        CreateAndEnableCustomerWorkflowDefinition(UserId);
        MakeCurrentUserAnApprover();
        LibrarySales.CreateCustomer(Customer);

        // Setup - A approval
        SendApprovalRequestForCustomer(Customer);

        Commit();

        // Verify
        VerifyWorkflowWebhookEntryResponse(Customer.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // Exercise
        WorkflowWebhookManagement.CancelByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(Customer.SystemId));

        // Verify
        VerifyWorkflowWebhookEntryResponse(Customer.SystemId, DummyWorkflowWebhookEntry.Response::Cancel);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureCustomerApprovalWorkflowFunctionsCorrectlyWhenRejected()
    var
        Customer: Record Customer;
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook customer approval workflow 'rejection' path works correctly.
        // [GIVEN] A webhook customer approval workflow for a customer is enabled.
        // [GIVEN] A customer request is pending approval.
        // [WHEN] The webhook customer approval workflow receives a 'rejection' response for the customer request.
        // [THEN] The customer request is rejected.

        // Setup
        Initialize();
        CreateAndEnableCustomerWorkflowDefinition(UserId);
        MakeCurrentUserAnApprover();
        LibrarySales.CreateCustomer(Customer);

        // Setup - A approval
        SendApprovalRequestForCustomer(Customer);

        Commit();

        // Verify
        VerifyWorkflowWebhookEntryResponse(Customer.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // Exercise
        WorkflowWebhookManagement.RejectByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(Customer.SystemId));

        // Verify
        VerifyWorkflowWebhookEntryResponse(Customer.SystemId, DummyWorkflowWebhookEntry.Response::Reject);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureCustomerApprovalWorkflowFunctionsCorrectlyWhenCustomerIsRenamed()
    var
        Customer: Record Customer;
        NewCustomer: Record Customer;
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] A user can rename a customer after they send it for approval and the approval requests
        // still points to the same record.
        // [GIVEN] Existing approval.
        // [WHEN] The user renames a customer.
        // [THEN] The approval entries are renamed to point to the same record.

        // Setup
        Initialize();
        CreateAndEnableCustomerWorkflowDefinition(UserId);
        MakeCurrentUserAnApprover();

        // Setup - an existing approval
        LibrarySales.CreateCustomer(Customer);
        SendApprovalRequestForCustomer(Customer);

        Commit();

        // Verify
        VerifyWorkflowWebhookEntryResponse(Customer.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // Exercise - Create a new customer and delete it to reuse the customer No.
        LibrarySales.CreateCustomer(NewCustomer);
        NewCustomer.Delete(true);
        Customer.Rename(NewCustomer."No.");

        // Verify - Request is approved since approval entry renamed to point to same record
        WorkflowWebhookManagement.ContinueByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(Customer.SystemId));
        VerifyWorkflowWebhookEntryResponse(Customer.SystemId, DummyWorkflowWebhookEntry.Response::Continue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureCustomerApprovalWorkflowFunctionsCorrectlyWhenCustomerIsDeleted()
    var
        Customer: Record Customer;
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowCode: Code[20];
    begin
        // [SCENARIO] A user can delete a customer and the existing approval requests will be canceled.
        // [GIVEN] Existing approval.
        // [WHEN] The user deletes the customer.
        // [THEN] The customer approval requests are canceled and then the customer is deleted.

        // Setup
        Initialize();
        WorkflowCode := CreateAndEnableCustomerWorkflowDefinition(UserId);
        MakeCurrentUserAnApprover();

        // Setup - an existing approval
        LibrarySales.CreateCustomer(Customer);
        SendApprovalRequestForCustomer(Customer);

        Commit();

        // Verify
        VerifyWorkflowWebhookEntryResponse(Customer.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // Exercise
        Customer.Delete(true);

        // Verify
        VerifyWorkflowWebhookEntryResponse(Customer.SystemId, DummyWorkflowWebhookEntry.Response::Cancel);
        WorkflowStepInstance.SetRange("Workflow Code", WorkflowCode);
        Assert.IsTrue(WorkflowStepInstance.IsEmpty, UnexpectedNoOfWorkflowStepInstancesErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotPostSalesDocumentUsingCustomerWithApprovalRequestPending()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO] A newly created customer that is sent for approval cannot be used.
        // [GIVEN] A new  Customer.
        // [WHEN] The user sends an approval request from the customer.
        // [THEN] Any sales document using the customer cannot be posted.

        // Setup
        Initialize();
        CreateAndEnableCustomerWorkflowDefinition(UserId);
        MakeCurrentUserAnApprover();
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, Customer."No.",
          LibraryInventory.CreateItemNo(), LibraryRandom.RandDec(100, 2), '', WorkDate());

        // Exercise.
        Commit();
        SendApprovalRequestForCustomer(Customer);

        // Verify.
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);
        Assert.ExpectedError(StrSubstNo(RecordRestrictedErr, Format(Customer.RecordId, 0, 1)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CanPostSalesDocumentUsingCustomerWithApprovalRequestCanceled()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] A newly created customer whose approval is canceled can be used.
        // [GIVEN] A new  Customer.
        // [WHEN] The user sends an approval request from the customer.
        // [WHEN] The user then cancels the request.
        // [THEN] Any sales document using the customer can be posted.

        // Setup
        Initialize();
        MakeCurrentUserAnApprover();
        CreateAndEnableCustomerWorkflowDefinition(UserId);

        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, Customer."No.",
          LibraryInventory.CreateItemNo(), LibraryRandom.RandDec(100, 2), '', WorkDate());

        SendApprovalRequestForCustomer(Customer);

        // Exercise.
        WorkflowWebhookManagement.CancelByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(Customer.SystemId));

        // Verify. No errors.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CanPostSalesDocumentUsingCustomerWithApprovalRequestApproved()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] A newly created customer that is approved can be used.
        // [GIVEN] A new  Customer.
        // [WHEN] The user sends an approval request from the customer.
        // [WHEN] The request is approved.
        // [THEN] Any sales document using the customer can be posted.

        // Setup
        Initialize();
        CreateAndEnableCustomerWorkflowDefinition(UserId);
        MakeCurrentUserAnApprover();

        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, Customer."No.",
          LibraryInventory.CreateItemNo(), LibraryRandom.RandDec(100, 2), '', WorkDate());

        SendApprovalRequestForCustomer(Customer);

        // LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(Customer.RECORDID);

        // Exercise.
        WorkflowWebhookManagement.ContinueByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(Customer.SystemId));

        // Verify. No errors.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ButtonStatusForPendingApprovalCustomerCard()
    var
        Customer: Record Customer;
        Workflow: Record Workflow;
        WorkflowSetup: Codeunit "Workflow Setup";
        WebhookHelper: Codeunit "Webhook Helper";
        CustomerCard: TestPage "Customer Card";
    begin
        // [SCENARIO] Approval actions are correctly enabled/disabled on Customer Card page while Flow approval is pending.
        Initialize();

        // [GIVEN] Customer record exists, with enabled workflow and a Flow approval request already open.
        LibrarySales.CreateCustomer(Customer);
        Commit();
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.CustomerWorkflowCode());
        WebhookHelper.CreatePendingFlowApproval(Customer.RecordId);

        // [WHEN] Customer card is opened.
        CustomerCard.OpenEdit();
        CustomerCard.GotoRecord(Customer);

        // [THEN] Cancel is enabled and Send is disabled.
        Assert.IsFalse(CustomerCard.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be disabled');
        Assert.IsTrue(CustomerCard.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be enabled');

        // Cleanup
        CustomerCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ButtonStatusForPendingFlowApprovalCustomerList()
    var
        Customer: Record Customer;
        Workflow: Record Workflow;
        WorkflowSetup: Codeunit "Workflow Setup";
        WebhookHelper: Codeunit "Webhook Helper";
        CustomerList: TestPage "Customer List";
    begin
        // [SCENARIO] Approval actions are correctly enabled/disabled on Customer List page while Flow approval is pending.
        Initialize();

        // [GIVEN] Customer record exists, with enabled workflow and a Flow approval request already open.
        LibrarySales.CreateCustomer(Customer);
        Commit();
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.CustomerWorkflowCode());
        WebhookHelper.CreatePendingFlowApproval(Customer.RecordId);

        // [WHEN] Customer list is opened.
        CustomerList.OpenEdit();
        CustomerList.GotoRecord(Customer);

        // [THEN] Cancel is enabled and Send is disabled.
        Assert.IsFalse(CustomerList.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be disabled');
        Assert.IsTrue(CustomerList.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be enabled');

        // Cleanup
        CustomerList.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelButtonWorksOnFlowApprovalCustomerCard()
    var
        Customer: Record Customer;
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WebhookHelper: Codeunit "Webhook Helper";
        CustomerCard: TestPage "Customer Card";
    begin
        // [SCENARIO] Clicking cancel action to cancel pending Flow approval on Customer Card page
        Initialize();

        // [GIVEN] Customer record exists, with a Flow approval request already open.
        LibrarySales.CreateCustomer(Customer);
        Commit();
        WebhookHelper.CreatePendingFlowApproval(Customer.RecordId);

        // [WHEN] Customer card is opened and Cancel button is clicked.
        CustomerCard.OpenEdit();
        CustomerCard.GotoRecord(Customer);
        CustomerCard.CancelApprovalRequest.Invoke();

        // [THEN] Workflow Webhook Entry record is cancelled
        WorkflowWebhookEntry.FindFirst();
        Assert.AreEqual(WorkflowWebhookEntry.Response::Cancel, WorkflowWebhookEntry.Response, 'Approval request should be cancelled.');

        // Cleanup
        CustomerCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelButtonWorksOnFlowApprovalCustomerList()
    var
        Customer: Record Customer;
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WebhookHelper: Codeunit "Webhook Helper";
        CustomerList: TestPage "Customer List";
    begin
        // [SCENARIO] Clicking cancel action to cancel pending Flow approval on Customer List page
        Initialize();

        // [GIVEN] Customer record exists, with a Flow approval request already open.
        LibrarySales.CreateCustomer(Customer);
        Commit();
        WebhookHelper.CreatePendingFlowApproval(Customer.RecordId);

        // [WHEN] Customer list is opened and Cancel button is clicked.
        CustomerList.OpenEdit();
        CustomerList.GotoRecord(Customer);
        CustomerList.CancelApprovalRequest.Invoke();

        // [THEN] Workflow Webhook Entry record is cancelled
        WorkflowWebhookEntry.FindFirst();
        Assert.AreEqual(WorkflowWebhookEntry.Response::Cancel, WorkflowWebhookEntry.Response, 'Approval request should be cancelled.');

        // Cleanup
        CustomerList.Close();
    end;

    local procedure Initialize()
    var
        ClearWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        UserSetup: Record "User Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"WFWH Customer Approval");
        LibraryVariableStorage.Clear();
        LibraryERMCountryData.CreateVATData();
        LibraryWorkflow.DisableAllWorkflows();
        UserSetup.DeleteAll();
        ClearWorkflowWebhookEntry.DeleteAll();
        RemoveBogusUser();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"WFWH Customer Approval");
        IsInitialized := true;
        BindSubscription(LibraryJobQueue);
        BindSubscription(MockOnFindTaskSchedulerAllowed);
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"WFWH Customer Approval");
    end;

    local procedure CreateAndEnableCustomerWorkflowDefinition(ResponseUserID: Code[50]): Code[20]
    var
        Workflow: Record Workflow;
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowWebhookSetup: Codeunit "Workflow Webhook Setup";
        WorkflowCode: Code[20];
    begin
        WorkflowCode :=
          WorkflowWebhookSetup.CreateWorkflowDefinition(WorkflowEventHandling.RunWorkflowOnSendCustomerForApprovalCode(),
            '', DynamicRequestPageParametersCustomerTxt, ResponseUserID);
        Workflow.Get(WorkflowCode);
        LibraryWorkflow.EnableWorkflow(Workflow);
        exit(WorkflowCode);
    end;

    local procedure GetPendingWorkflowStepInstanceIdFromDataId(Id: Guid): Guid
    var
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
    begin
        WorkflowWebhookEntry.Init();
        WorkflowWebhookEntry.SetFilter("Data ID", Id);
        WorkflowWebhookEntry.SetFilter(Response, '=%1', WorkflowWebhookEntry.Response::Pending);
        WorkflowWebhookEntry.FindFirst();

        exit(WorkflowWebhookEntry."Workflow Step Instance ID");
    end;

    local procedure SendApprovalRequestForCustomer(var Customer: Record Customer)
    var
        CustomerCard: TestPage "Customer Card";
    begin
        CustomerCard.OpenEdit();
        CustomerCard.GotoRecord(Customer);
        CustomerCard.SendApprovalRequest.Invoke();
        CustomerCard.Close();
    end;

    local procedure VerifyWorkflowWebhookEntryResponse(Id: Guid; ResponseArgument: Option)
    var
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
    begin
        WorkflowWebhookEntry.Init();
        WorkflowWebhookEntry.SetCurrentKey("Data ID");
        WorkflowWebhookEntry.SetRange("Data ID", Id);
        WorkflowWebhookEntry.FindFirst();

        WorkflowWebhookEntry.TestField(Response, ResponseArgument);
    end;
}

