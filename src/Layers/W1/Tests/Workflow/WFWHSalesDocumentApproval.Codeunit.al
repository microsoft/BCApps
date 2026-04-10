codeunit 134216 "WFWH Sales Document Approval"
{
    EventSubscriberInstance = Manual;
    Permissions = TableData "User Setup" = imd,
                  TableData "Workflow Webhook Entry" = imd;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Workflow] [Webhook] [Sales] [Order] [Approval]
    end;

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        MockOnFindTaskSchedulerAllowed: Codeunit MockOnFindTaskSchedulerAllowed;
        ApprovalShouldBeHandledErr: Label 'The approval process must be cancelled or completed to reopen this document.';
        DocCannotBeReleasedErr: Label 'This document can only be released when the approval process is complete.';
        DocCannotBePostedErr: Label '%1 %2 must be approved and released before you can perform this action.', Comment = '%1 = SalesHeader."Document Type", %2 = SalesHeader."No."';
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        RecordIsRestrictedErr: Label 'You cannot use %1 for this action.', Comment = '%1=Record Id';
        LibraryJobQueue: Codeunit "Library - Job Queue";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        UserCannotCancelErr: Label 'User %1 does not have the permission necessary to cancel the item.', Comment = '%1 = NAV USERID';
        UserCannotActErr: Label 'User %1 cannot act on this step. Make sure the user who created the webhook (%2) is the same who is trying to act.', Comment = '%1, %2 = two distinct NAV user IDs, for example "MEGANB" and "WILLIAMC"';
        BogusUserIdTxt: Label 'CONTOSO';
        DynamicRequestPageParametersOpenSalesOrderTxt: Label '<?xml version="1.0" encoding="utf-8" standalone="yes"?><ReportParameters><DataItems><DataItem name="Sales Header">SORTING(Field1,Field3) WHERE(Field1=1(1),Field120=1(0))</DataItem><DataItem name="Sales Line">SORTING(Field1,Field3,Field4)</DataItem></DataItems></ReportParameters>', Locked = true;
        UnexpectedNoOfApprovalEntriesErr: Label 'Unexpected number of approval entries found.', Locked = true;

    local procedure Initialize()
    var
        UserSetup: Record "User Setup";
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"WFWH Sales Document Approval");
        LibraryVariableStorage.Clear();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateVATPostingSetup();
        UserSetup.DeleteAll();
        WorkflowWebhookEntry.DeleteAll();
        LibraryWorkflow.DisableAllWorkflows();
        RemoveBogusUser();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"WFWH Sales Document Approval");
        IsInitialized := true;
        BindSubscription(LibraryJobQueue);
        BindSubscription(MockOnFindTaskSchedulerAllowed);
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"WFWH Sales Document Approval");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotReleaseOpenSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
    begin
        // [SCENARIO] A user cannot release a sales order when a webhook sales document approval workflow is enabled and a sales order is not approved.
        // [GIVEN] There is a sales order that is not approved.
        // [GIVEN] A webhook sales document approval workflow for a sales order is enabled.
        // [WHEN] The user wants to release the sales order.
        // [THEN] The user will get an error that an unapproved sales order cannot be released.

        // Setup
        Initialize();

        CreateAndEnableOpenSalesOrderWorkflowDefinition(UserId);
        CreateSalesOrder(SalesHeader, LibraryRandom.RandIntInRange(5000, 10000));

        // Exercise
        SalesOrder.OpenView();
        SalesOrder.GotoRecord(SalesHeader);
        asserterror SalesOrder.Release.Invoke();

        // Verify
        Assert.ExpectedError(DocCannotBeReleasedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotReleaseOpenSalesOrderIfApprovalIsPending()
    var
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
    begin
        // [SCENARIO] A user cannot release a sales order when a webhook sales document approval workflow is enabled and a sales order is pending approval.
        // [GIVEN] There is a sales order that is sent for approval.
        // [GIVEN] A webhook sales document approval workflow for a sales order is enabled.
        // [WHEN] The user wants to release the sales order.
        // [THEN] The user will get an error that an unapproved sales order cannot be released.

        // Setup
        Initialize();

        CreateAndEnableOpenSalesOrderWorkflowDefinition(UserId);
        CreateSalesOrderAndSendForApproval(SalesHeader, LibraryRandom.RandIntInRange(5000, 10000));

        Commit();

        // Exercise
        SalesOrder.OpenView();
        SalesOrder.GotoRecord(SalesHeader);
        asserterror SalesOrder.Release.Invoke();

        // Verify
        Assert.ExpectedError(StrSubstNo(RecordIsRestrictedErr, Format(SalesHeader.RecordId, 0, 1)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotReopenOpenSalesOrderIfApprovalIsPending()
    var
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
    begin
        // [SCENARIO] A user cannot reopen a sales order when a webhook sales document approval workflow is enabled and a sales order is pending approval.
        // [GIVEN] There is a sales order that is sent for approval.
        // [GIVEN] A webhook sales document approval workflow for a sales order is enabled.
        // [WHEN] The user wants to reopen the sales order.
        // [THEN] The user will get an error that an unapproved sales order cannot be reopened.

        // Setup
        Initialize();

        CreateAndEnableOpenSalesOrderWorkflowDefinition(UserId);
        CreateSalesOrder(SalesHeader, LibraryRandom.RandIntInRange(5000, 10000));
        SalesOrderPageSendForApproval(SalesHeader);

        Commit();

        // Exercise
        SalesOrder.OpenView();
        SalesOrder.GotoRecord(SalesHeader);
        asserterror SalesOrder.Reopen.Invoke();

        // Verify
        Assert.ExpectedError(ApprovalShouldBeHandledErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotPostOpenSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
    begin
        // [SCENARIO] A user cannot post a sales order when a webhook sales document approval workflow is enabled and a sales order is not approved.
        // [GIVEN] There is a sales order that is not approved.
        // [GIVEN] A webhook sales document approval workflow for a sales order is enabled.
        // [WHEN] The user wants to post the sales order.
        // [THEN] The user will get an error that an unapproved sales order cannot be posted.

        // Setup
        Initialize();

        CreateAndEnableOpenSalesOrderWorkflowDefinition(UserId);
        CreateSalesOrder(SalesHeader, LibraryRandom.RandIntInRange(5000, 10000));

        // Exercise
        SalesOrder.OpenView();
        SalesOrder.GotoRecord(SalesHeader);
        asserterror SalesOrder.Post.Invoke();

        // Verify
        Assert.ExpectedError(StrSubstNo(DocCannotBePostedErr, SalesHeader."Document Type", SalesHeader."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureNecessaryTableRelationsAreSetup()
    var
        DummySalesHeader: Record "Sales Header";
        DummySalesLine: Record "Sales Line";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowTableRelation: Record "Workflow - Table Relation";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [SCENARIO] Ensure that the necessary webhook sales document approval workflow table relations are setup.
        // [WHEN] Workflow setup is initialized.
        // [THEN] Workflow table relations for sales order and workflow webhook entry exist.

        // Setup
        LibraryWorkflow.DeleteAllExistingWorkflows();

        // Excercise
        WorkflowSetup.InitWorkflow();

        // Verify
        WorkflowTableRelation.Get(
          DATABASE::"Sales Header", DummySalesHeader.FieldNo("Document Type"),
          DATABASE::"Sales Line", DummySalesLine.FieldNo("Document Type"));
        WorkflowTableRelation.Get(
          DATABASE::"Sales Header", DummySalesHeader.FieldNo("No."),
          DATABASE::"Sales Line", DummySalesLine.FieldNo("Document No."));
        WorkflowTableRelation.Get(
          DATABASE::"Sales Header", DummySalesHeader.FieldNo(SystemId),
          DATABASE::"Workflow Webhook Entry", DummyWorkflowWebhookEntry.FieldNo("Data ID"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureOpenSalesOrderApprovalWorkflowFunctionsCorrectlyWhenCancelled()
    var
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        SalesHeader: Record "Sales Header";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook sales document approval workflow 'cancellation' path works correctly.
        // [GIVEN] A webhook sales document approval workflow for a sales order is enabled.
        // [GIVEN] A sales order is pending approval.
        // [WHEN] The webhook sales document approval workflow receives a 'cancellation' response for the sales order.
        // [THEN] The sales order is cancelled and opened.

        // Setup
        Initialize();

        CreateAndEnableOpenSalesOrderWorkflowDefinition(UserId);
        CreateSalesOrder(SalesHeader, LibraryRandom.RandIntInRange(5000, 10000));
        SalesOrderPageSendForApproval(SalesHeader);

        Commit();

        // Exercise
        WorkflowWebhookManagement.CancelByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(SalesHeader.SystemId));

        // Verify
        VerifyWorkflowWebhookEntryResponse(SalesHeader.SystemId, DummyWorkflowWebhookEntry.Response::Cancel);
        VerifySalesDocumentStatus(SalesHeader, SalesHeader.Status::Open);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureOpenSalesOrderApprovalWorkflowFunctionsCorrectlyWhenContinued()
    var
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        SalesHeader: Record "Sales Header";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook sales document approval workflow 'approval' path works correctly.
        // [GIVEN] A webhook sales document approval workflow for a sales order is enabled.
        // [GIVEN] A sales order is pending approval.
        // [WHEN] The webhook sales document approval workflow receives an 'approval' response for the sales order.
        // [THEN] The sales order is approved and released.

        // Setup
        Initialize();

        CreateAndEnableOpenSalesOrderWorkflowDefinition(UserId);
        CreateSalesOrder(SalesHeader, LibraryRandom.RandIntInRange(5000, 10000));
        SalesOrderPageSendForApproval(SalesHeader);
        MakeCurrentUserAnApprover();

        Commit();

        // Exercise
        WorkflowWebhookManagement.ContinueByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(SalesHeader.SystemId));

        // Verify
        VerifyWorkflowWebhookEntryResponse(SalesHeader.SystemId, DummyWorkflowWebhookEntry.Response::Continue);
        VerifySalesDocumentStatus(SalesHeader, SalesHeader.Status::Released);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureOpenSalesOrderApprovalWorkflowFunctionsCorrectlyWhenRejected()
    var
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        SalesHeader: Record "Sales Header";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook sales document approval workflow 'rejection' path works correctly.
        // [GIVEN] A webhook sales document approval workflow for a sales order is enabled.
        // [GIVEN] A sales order is pending approval.
        // [WHEN] The webhook sales document approval workflow receives a 'rejection' response for the sales order.
        // [THEN] The sales order is rejected and opened.

        // Setup
        Initialize();

        CreateAndEnableOpenSalesOrderWorkflowDefinition(UserId);
        CreateSalesOrder(SalesHeader, LibraryRandom.RandIntInRange(5000, 10000));
        SalesOrderPageSendForApproval(SalesHeader);
        MakeCurrentUserAnApprover();

        Commit();

        // Exercise
        WorkflowWebhookManagement.RejectByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(SalesHeader.SystemId));

        // Verify
        VerifyWorkflowWebhookEntryResponse(SalesHeader.SystemId, DummyWorkflowWebhookEntry.Response::Reject);
        VerifySalesDocumentStatus(SalesHeader, SalesHeader.Status::Open);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureOpenSalesOrderApprovalWorkflowFunctionsCorrectlyWithUnauthorizedCancellation()
    var
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        SalesHeader: Record "Sales Header";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook sales document approval workflow 'cancellation' path works correctly.
        // [GIVEN] A webhook sales document approval workflow for a sales order is enabled.
        // [GIVEN] A sales order is pending approval.
        // [WHEN] The webhook sales document approval workflow receives a 'cancellation' response from an
        // 'invalid user' for the sales order.
        // [THEN] The sales order approval is not cancelled.

        // Setup
        Initialize();

        CreateAndEnableOpenSalesOrderWorkflowDefinition(UserId);
        CreateSalesOrder(SalesHeader, LibraryRandom.RandIntInRange(5000, 10000));
        SalesOrderPageSendForApproval(SalesHeader);
        ChangeWorkflowWebhookEntryInitiatedBy(SalesHeader.SystemId, BogusUserIdTxt);

        Commit();

        // Exercise
        asserterror WorkflowWebhookManagement.CancelByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(SalesHeader.SystemId));

        // Verify
        Assert.ExpectedError(StrSubstNo(UserCannotCancelErr, UserId));
        VerifyWorkflowWebhookEntryResponse(SalesHeader.SystemId, DummyWorkflowWebhookEntry.Response::Pending);
        VerifySalesDocumentStatus(SalesHeader, SalesHeader.Status::"Pending Approval");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureOpenSalesOrderApprovalWorkflowFunctionsCorrectlyWithUnauthorizedContinuation()
    var
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        SalesHeader: Record "Sales Header";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook sales document approval workflow 'approval' path works correctly.
        // [GIVEN] A webhook sales document approval workflow for a sales order is enabled.
        // [GIVEN] A sales order is pending approval.
        // [WHEN] The webhook sales document approval workflow receives an 'approval' response from an
        // 'invalid user' for the sales order.
        // [THEN] The sales order approval is not continued.

        // Setup
        Initialize();

        CreateAndEnableOpenSalesOrderWorkflowDefinition(BogusUserIdTxt);
        CreateSalesOrder(SalesHeader, LibraryRandom.RandIntInRange(5000, 10000));
        SalesOrderPageSendForApproval(SalesHeader);

        Commit();

        // Exercise
        asserterror WorkflowWebhookManagement.ContinueByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(SalesHeader.SystemId));

        // Verify
        Assert.ExpectedError(StrSubstNo(UserCannotActErr, UserId, BogusUserIdTxt));
        VerifyWorkflowWebhookEntryResponse(SalesHeader.SystemId, DummyWorkflowWebhookEntry.Response::Pending);
        VerifySalesDocumentStatus(SalesHeader, SalesHeader.Status::"Pending Approval");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureOpenSalesOrderApprovalWorkflowFunctionsCorrectlyWithUnauthorizedRejection()
    var
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        SalesHeader: Record "Sales Header";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook sales document approval workflow 'rejection' path works correctly.
        // [GIVEN] A webhook sales document approval workflow for a sales order is enabled.
        // [GIVEN] A sales order is pending approval.
        // [WHEN] The webhook sales document approval workflow receives a 'rejection' response from an
        // 'invalid user' for the sales order.
        // [THEN] The sales order approval is not rejected.

        // Setup
        Initialize();

        CreateAndEnableOpenSalesOrderWorkflowDefinition(BogusUserIdTxt);
        CreateSalesOrder(SalesHeader, LibraryRandom.RandIntInRange(5000, 10000));
        SalesOrderPageSendForApproval(SalesHeader);

        Commit();

        // Exercise
        asserterror WorkflowWebhookManagement.RejectByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(SalesHeader.SystemId));

        // Verify
        Assert.ExpectedError(StrSubstNo(UserCannotActErr, UserId, BogusUserIdTxt));
        VerifyWorkflowWebhookEntryResponse(SalesHeader.SystemId, DummyWorkflowWebhookEntry.Response::Pending);
        VerifySalesDocumentStatus(SalesHeader, SalesHeader.Status::"Pending Approval");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureOpenSalesOrderApprovalWorkflowFunctionsCorrectlyWhenSalesOrderIsDeleted()
    var
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        SalesHeader: Record "Sales Header";
    begin
        // [SCENARIO] A user can delete a sales docuemnt (order) and the existing approval requests will be canceled.
        // [GIVEN] A webhook sales document approval workflow for a sales order is enabled.
        // [GIVEN] A sales order is pending approval.
        // [WHEN] The user deletes the sales order.
        // [THEN] The exisiting approval requests are deleted and the sales order is also deleted.

        // Setup
        Initialize();

        CreateAndEnableOpenSalesOrderWorkflowDefinition(UserId);
        CreateSalesOrder(SalesHeader, LibraryRandom.RandIntInRange(5000, 10000));
        SalesOrderPageSendForApproval(SalesHeader);

        Commit();

        // Verify
        Assert.AreEqual(1, DummyWorkflowWebhookEntry.Count, UnexpectedNoOfApprovalEntriesErr);
        VerifyWorkflowWebhookEntryResponse(SalesHeader.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // Exercise
        SalesHeader.Find(); // Sales document's status was modified so reread from database.
        SalesHeader.Delete(true);

        // Verify
        Assert.AreEqual(0, DummyWorkflowWebhookEntry.Count, UnexpectedNoOfApprovalEntriesErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ButtonStatusForPendingApprovalSalesOrderCard()
    var
        SalesHeader: Record "Sales Header";
        WebhookHelper: Codeunit "Webhook Helper";
        SalesOrder: TestPage "Sales Order";
    begin
        // [SCENARIO] Approval actions are correctly enabled/disabled on Sales Order Card page while Flow approval is pending.
        Initialize();

        // [GIVEN] Sales Order record exists, with a Flow approval request already open.
        CreateSalesOrder(SalesHeader, LibraryRandom.RandIntInRange(5000, 10000));
        WebhookHelper.CreatePendingFlowApproval(SalesHeader.RecordId);

        // [WHEN] Sales Order card is opened.
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);

        // [THEN] Cancel is enabled and Send is disabled.
        Assert.IsFalse(SalesOrder.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be disabled');
        Assert.IsTrue(SalesOrder.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be enabled');

        // Cleanup
        SalesOrder.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ButtonStatusForPendingFlowApprovalSalesOrderList()
    var
        SalesHeader: Record "Sales Header";
        WebhookHelper: Codeunit "Webhook Helper";
        SalesOrderList: TestPage "Sales Order List";
    begin
        // [SCENARIO] Approval actions are correctly enabled/disabled on Sales Order List page while Flow approval is pending.
        Initialize();

        // [GIVEN] Sales Order record exists, with a Flow approval request already open.
        CreateSalesOrder(SalesHeader, LibraryRandom.RandIntInRange(5000, 10000));
        WebhookHelper.CreatePendingFlowApproval(SalesHeader.RecordId);

        // [WHEN] Sales Order list is opened.
        SalesOrderList.OpenEdit();
        SalesOrderList.GotoRecord(SalesHeader);

        // [THEN] Cancel is enabled and Send is disabled.
        Assert.IsFalse(SalesOrderList.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be disabled');
        Assert.IsTrue(SalesOrderList.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be enabled');

        // Cleanup
        SalesOrderList.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ButtonStatusForPendingApprovalSalesQuoteCard()
    var
        SalesHeader: Record "Sales Header";
        WebhookHelper: Codeunit "Webhook Helper";
        SalesQuote: TestPage "Sales Quote";
    begin
        // [SCENARIO] Approval actions are correctly enabled/disabled on Sales Quote Card page while Flow approval is pending.
        Initialize();

        // [GIVEN] Sales Quote record exists, with a Flow approval request already open.
        CreateSalesQuote(SalesHeader, LibraryRandom.RandIntInRange(5000, 10000));
        WebhookHelper.CreatePendingFlowApproval(SalesHeader.RecordId);

        // [WHEN] Sales Quote card is opened.
        SalesQuote.OpenEdit();
        SalesQuote.GotoRecord(SalesHeader);

        // [THEN] Cancel is enabled and Send is disabled.
        Assert.IsFalse(SalesQuote.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be disabled');
        Assert.IsTrue(SalesQuote.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be enabled');

        // Cleanup
        SalesQuote.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ButtonStatusForPendingFlowApprovalSalesQuoteList()
    var
        SalesHeader: Record "Sales Header";
        WebhookHelper: Codeunit "Webhook Helper";
        SalesQuotes: TestPage "Sales Quotes";
    begin
        // [SCENARIO] Approval actions are correctly enabled/disabled on Sales Quote List page while Flow approval is pending.
        Initialize();

        // [GIVEN] Sales Quote record exists, with a Flow approval request already open.
        CreateSalesQuote(SalesHeader, LibraryRandom.RandIntInRange(5000, 10000));
        WebhookHelper.CreatePendingFlowApproval(SalesHeader.RecordId);

        // [WHEN] Sales Quote list is opened.
        SalesQuotes.OpenEdit();
        SalesQuotes.GotoRecord(SalesHeader);

        // [THEN] Cancel is enabled and Send is disabled.
        Assert.IsFalse(SalesQuotes.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be disabled');
        Assert.IsTrue(SalesQuotes.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be enabled');

        // Cleanup
        SalesQuotes.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ButtonStatusForPendingApprovalSalesInvoiceCard()
    var
        SalesHeader: Record "Sales Header";
        WebhookHelper: Codeunit "Webhook Helper";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [SCENARIO] Approval actions are correctly enabled/disabled on Sales Invoice Card page while Flow approval is pending.
        Initialize();

        // [GIVEN] Sales Invoice record exists, with a Flow approval request already open.
        CreateSalesInvoice(SalesHeader, LibraryRandom.RandIntInRange(5000, 10000));
        WebhookHelper.CreatePendingFlowApproval(SalesHeader.RecordId);

        // [WHEN] Sales Invoice card is opened.
        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);

        // [THEN] Cancel is enabled and Send is disabled.
        Assert.IsFalse(SalesInvoice.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be disabled');
        Assert.IsTrue(SalesInvoice.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be enabled');

        // Cleanup
        SalesInvoice.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ButtonStatusForPendingFlowApprovalSalesInvoiceList()
    var
        SalesHeader: Record "Sales Header";
        WebhookHelper: Codeunit "Webhook Helper";
        SalesInvoiceList: TestPage "Sales Invoice List";
    begin
        // [SCENARIO] Approval actions are correctly enabled/disabled on Sales Invoice List page while Flow approval is pending.
        Initialize();

        // [GIVEN] Sales Invoice record exists, with a Flow approval request already open.
        CreateSalesInvoice(SalesHeader, LibraryRandom.RandIntInRange(5000, 10000));
        WebhookHelper.CreatePendingFlowApproval(SalesHeader.RecordId);

        // [WHEN] Sales Invoice list is opened.
        SalesInvoiceList.OpenEdit();
        SalesInvoiceList.GotoRecord(SalesHeader);

        // [THEN] Cancel is enabled and Send is disabled.
        Assert.IsFalse(SalesInvoiceList.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be disabled');
        Assert.IsTrue(SalesInvoiceList.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be enabled');

        // Cleanup
        SalesInvoiceList.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ButtonStatusForPendingApprovalSalesCreditMemoCard()
    var
        SalesHeader: Record "Sales Header";
        WebhookHelper: Codeunit "Webhook Helper";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [SCENARIO] Approval actions are correctly enabled/disabled on Sales Credit Memo Card page while Flow approval is pending.
        Initialize();

        // [GIVEN] Sales Credit Memo record exists, with a Flow approval request already open.
        CreateSalesCreditMemo(SalesHeader, LibraryRandom.RandIntInRange(5000, 10000));
        WebhookHelper.CreatePendingFlowApproval(SalesHeader.RecordId);

        // [WHEN] Sales Credit Memo card is opened.
        SalesCreditMemo.OpenEdit();
        SalesCreditMemo.GotoRecord(SalesHeader);

        // [THEN] Cancel is enabled and Send is disabled.
        Assert.IsFalse(SalesCreditMemo.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be disabled');
        Assert.IsTrue(SalesCreditMemo.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be enabled');

        // Cleanup
        SalesCreditMemo.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ButtonStatusForPendingFlowApprovalSalesCreditMemoList()
    var
        SalesHeader: Record "Sales Header";
        WebhookHelper: Codeunit "Webhook Helper";
        SalesCreditMemos: TestPage "Sales Credit Memos";
    begin
        // [SCENARIO] Approval actions are correctly enabled/disabled on Sales Credit Memo List page while Flow approval is pending.
        Initialize();

        // [GIVEN] Sales Credit Memo record exists, with a Flow approval request already open.
        CreateSalesCreditMemo(SalesHeader, LibraryRandom.RandIntInRange(5000, 10000));
        WebhookHelper.CreatePendingFlowApproval(SalesHeader.RecordId);

        // [WHEN] Sales Credit Memo list is opened.
        SalesCreditMemos.OpenEdit();
        SalesCreditMemos.GotoRecord(SalesHeader);

        // [THEN] Cancel is enabled and Send is disabled.
        Assert.IsFalse(SalesCreditMemos.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be disabled');
        Assert.IsTrue(SalesCreditMemos.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be enabled');

        // Cleanup
        SalesCreditMemos.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelButtonWorksOnFlowApprovalSalesOrderCard()
    var
        SalesHeader: Record "Sales Header";
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WebhookHelper: Codeunit "Webhook Helper";
        SalesOrder: TestPage "Sales Order";
    begin
        // [SCENARIO] Clicking cancel action to cancel pending Flow approval on Sales Order Card page
        Initialize();

        // [GIVEN] Sales Order record exists, with a Flow approval request already open.
        CreateSalesOrder(SalesHeader, LibraryRandom.RandIntInRange(5000, 10000));
        WebhookHelper.CreatePendingFlowApproval(SalesHeader.RecordId);

        // [WHEN] Sales Order card is opened and Cancel button is clicked.
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
        SalesOrder.CancelApprovalRequest.Invoke();

        // [THEN] Workflow Webhook Entry record is cancelled
        WorkflowWebhookEntry.FindFirst();
        Assert.AreEqual(WorkflowWebhookEntry.Response::Cancel, WorkflowWebhookEntry.Response, 'Approval request should be cancelled.');

        // Cleanup
        SalesOrder.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelButtonWorksOnFlowApprovalSalesOrderList()
    var
        SalesHeader: Record "Sales Header";
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WebhookHelper: Codeunit "Webhook Helper";
        SalesOrderList: TestPage "Sales Order List";
    begin
        // [SCENARIO] Clicking cancel action to cancel pending Flow approval on Sales Order List page
        Initialize();

        // [GIVEN] Sales Order record exists, with a Flow approval request already open.
        CreateSalesOrder(SalesHeader, LibraryRandom.RandIntInRange(5000, 10000));
        WebhookHelper.CreatePendingFlowApproval(SalesHeader.RecordId);

        // [WHEN] Sales Order list is opened and Cancel button is clicked.
        SalesOrderList.OpenEdit();
        SalesOrderList.GotoRecord(SalesHeader);
        SalesOrderList.CancelApprovalRequest.Invoke();

        // [THEN] Workflow Webhook Entry record is cancelled
        WorkflowWebhookEntry.FindFirst();
        Assert.AreEqual(WorkflowWebhookEntry.Response::Cancel, WorkflowWebhookEntry.Response, 'Approval request should be cancelled.');

        // Cleanup
        SalesOrderList.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelButtonWorksOnFlowApprovalSalesQuoteCard()
    var
        SalesHeader: Record "Sales Header";
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WebhookHelper: Codeunit "Webhook Helper";
        SalesQuote: TestPage "Sales Quote";
    begin
        // [SCENARIO] Clicking cancel action to cancel pending Flow approval on Sales Quote Card page
        Initialize();

        // [GIVEN] Sales Quote record exists, with a Flow approval request already open.
        CreateSalesQuote(SalesHeader, LibraryRandom.RandIntInRange(5000, 10000));
        WebhookHelper.CreatePendingFlowApproval(SalesHeader.RecordId);

        // [WHEN] Sales Quote card is opened and Cancel button is clicked.
        SalesQuote.OpenEdit();
        SalesQuote.GotoRecord(SalesHeader);
        SalesQuote.CancelApprovalRequest.Invoke();

        // [THEN] Workflow Webhook Entry record is cancelled
        WorkflowWebhookEntry.FindFirst();
        Assert.AreEqual(WorkflowWebhookEntry.Response::Cancel, WorkflowWebhookEntry.Response, 'Approval request should be cancelled.');

        // Cleanup
        SalesQuote.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelButtonWorksOnFlowApprovalSalesQuoteList()
    var
        SalesHeader: Record "Sales Header";
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WebhookHelper: Codeunit "Webhook Helper";
        SalesQuotes: TestPage "Sales Quotes";
    begin
        // [SCENARIO] Clicking cancel action to cancel pending Flow approval on Sales Quote List page
        Initialize();

        // [GIVEN] Sales Quote record exists, with a Flow approval request already open.
        CreateSalesQuote(SalesHeader, LibraryRandom.RandIntInRange(5000, 10000));
        WebhookHelper.CreatePendingFlowApproval(SalesHeader.RecordId);

        // [WHEN] Sales Quote list is opened and Cancel button is clicked.
        SalesQuotes.OpenEdit();
        SalesQuotes.GotoRecord(SalesHeader);
        SalesQuotes.CancelApprovalRequest.Invoke();

        // [THEN] Workflow Webhook Entry record is cancelled
        WorkflowWebhookEntry.FindFirst();
        Assert.AreEqual(WorkflowWebhookEntry.Response::Cancel, WorkflowWebhookEntry.Response, 'Approval request should be cancelled.');

        // Cleanup
        SalesQuotes.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelButtonWorksOnFlowApprovalSalesInvoiceCard()
    var
        SalesHeader: Record "Sales Header";
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WebhookHelper: Codeunit "Webhook Helper";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [SCENARIO] Clicking cancel action to cancel pending Flow approval on Sales Invoice Card page
        Initialize();

        // [GIVEN] Sales Invoice record exists, with a Flow approval request already open.
        CreateSalesInvoice(SalesHeader, LibraryRandom.RandIntInRange(5000, 10000));
        WebhookHelper.CreatePendingFlowApproval(SalesHeader.RecordId);

        // [WHEN] Sales Invoice card is opened and Cancel button is clicked.
        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);
        SalesInvoice.CancelApprovalRequest.Invoke();

        // [THEN] Workflow Webhook Entry record is cancelled
        WorkflowWebhookEntry.FindFirst();
        Assert.AreEqual(WorkflowWebhookEntry.Response::Cancel, WorkflowWebhookEntry.Response, 'Approval request should be cancelled.');

        // Cleanup
        SalesInvoice.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelButtonWorksOnFlowApprovalSalesInvoiceList()
    var
        SalesHeader: Record "Sales Header";
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WebhookHelper: Codeunit "Webhook Helper";
        SalesInvoiceList: TestPage "Sales Invoice List";
    begin
        // [SCENARIO] Clicking cancel action to cancel pending Flow approval on Sales Invoice List page
        Initialize();

        // [GIVEN] Sales Invoice record exists, with a Flow approval request already open.
        CreateSalesInvoice(SalesHeader, LibraryRandom.RandIntInRange(5000, 10000));
        WebhookHelper.CreatePendingFlowApproval(SalesHeader.RecordId);

        // [WHEN] Sales Invoice list is opened and Cancel button is clicked.
        SalesInvoiceList.OpenEdit();
        SalesInvoiceList.GotoRecord(SalesHeader);
        SalesInvoiceList.CancelApprovalRequest.Invoke();

        // [THEN] Workflow Webhook Entry record is cancelled
        WorkflowWebhookEntry.FindFirst();
        Assert.AreEqual(WorkflowWebhookEntry.Response::Cancel, WorkflowWebhookEntry.Response, 'Approval request should be cancelled.');

        // Cleanup
        SalesInvoiceList.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelButtonWorksOnFlowApprovalSalesCreditMemoCard()
    var
        SalesHeader: Record "Sales Header";
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WebhookHelper: Codeunit "Webhook Helper";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [SCENARIO] Clicking cancel action to cancel pending Flow approval on Sales Credit Memo Card page
        Initialize();

        // [GIVEN] Sales Credit Memo record exists, with a Flow approval request already open.
        CreateSalesCreditMemo(SalesHeader, LibraryRandom.RandIntInRange(5000, 10000));
        WebhookHelper.CreatePendingFlowApproval(SalesHeader.RecordId);

        // [WHEN] Sales Credit Memo card is opened and Cancel button is clicked.
        SalesCreditMemo.OpenEdit();
        SalesCreditMemo.GotoRecord(SalesHeader);
        SalesCreditMemo.CancelApprovalRequest.Invoke();

        // [THEN] Workflow Webhook Entry record is cancelled
        WorkflowWebhookEntry.FindFirst();
        Assert.AreEqual(WorkflowWebhookEntry.Response::Cancel, WorkflowWebhookEntry.Response, 'Approval request should be cancelled.');

        // Cleanup
        SalesCreditMemo.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelButtonWorksOnFlowApprovalSalesCreditMemoList()
    var
        SalesHeader: Record "Sales Header";
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WebhookHelper: Codeunit "Webhook Helper";
        SalesCreditMemos: TestPage "Sales Credit Memos";
    begin
        // [SCENARIO] Clicking cancel action to cancel pending Flow approval on Sales Credit Memo List page
        Initialize();

        // [GIVEN] Sales Credit Memo record exists, with a Flow approval request already open.
        CreateSalesCreditMemo(SalesHeader, LibraryRandom.RandIntInRange(5000, 10000));
        WebhookHelper.CreatePendingFlowApproval(SalesHeader.RecordId);

        // [WHEN] Sales Credit Memo list is opened and Cancel button is clicked.
        SalesCreditMemos.OpenEdit();
        SalesCreditMemos.GotoRecord(SalesHeader);
        SalesCreditMemos.CancelApprovalRequest.Invoke();

        // [THEN] Workflow Webhook Entry record is cancelled
        WorkflowWebhookEntry.FindFirst();
        Assert.AreEqual(WorkflowWebhookEntry.Response::Cancel, WorkflowWebhookEntry.Response, 'Approval request should be cancelled.');

        // Cleanup
        SalesCreditMemos.Close();
    end;

    local procedure ChangeWorkflowWebhookEntryInitiatedBy(Id: Guid; InitiatedByUserID: Code[50])
    var
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
    begin
        WorkflowWebhookEntry.Init();
        WorkflowWebhookEntry.SetCurrentKey("Data ID");
        WorkflowWebhookEntry.SetRange("Data ID", Id);
        WorkflowWebhookEntry.FindFirst();

        WorkflowWebhookEntry."Initiated By User ID" := InitiatedByUserID;
        WorkflowWebhookEntry.Modify();
    end;

    local procedure CreateAndEnableOpenSalesOrderWorkflowDefinition(ResponseUserID: Code[50]): Code[20]
    var
        Workflow: Record Workflow;
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowWebhookSetup: Codeunit "Workflow Webhook Setup";
        WorkflowCode: Code[20];
    begin
        WorkflowCode := WorkflowWebhookSetup.CreateWorkflowDefinition(WorkflowEventHandling.RunWorkflowOnSendSalesDocForApprovalCode(), '',
            DynamicRequestPageParametersOpenSalesOrderTxt, ResponseUserID);
        Workflow.Get(WorkflowCode);
        LibraryWorkflow.EnableWorkflow(Workflow);
        exit(WorkflowCode);
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

    local procedure CreateSalesQuote(var SalesHeader: Record "Sales Header"; Amount: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, '', 1);
        SalesLine.Validate("Unit Price", Amount);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesInvoice(var SalesHeader: Record "Sales Header"; Amount: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, '', 1);
        SalesLine.Validate("Unit Price", Amount);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesCreditMemo(var SalesHeader: Record "Sales Header"; Amount: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, '', 1);
        SalesLine.Validate("Unit Price", Amount);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrderAndSendForApproval(var SalesHeader: Record "Sales Header"; Amount: Decimal)
    begin
        CreateSalesOrder(SalesHeader, Amount);
        SalesOrderPageSendForApproval(SalesHeader);
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

    local procedure SalesOrderPageSendForApproval(var SalesHeader: Record "Sales Header")
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenView();
        SalesOrder.GotoRecord(SalesHeader);
        SalesOrder.SendApprovalRequest.Invoke();
        SalesOrder.Close();

        VerifySalesDocumentStatus(SalesHeader, SalesHeader.Status::"Pending Approval");
    end;

    local procedure VerifySalesDocumentStatus(SalesHeader: Record "Sales Header"; Status: Enum "Sales Document Status")
    begin
        SalesHeader.SetRecFilter();
        SalesHeader.FindFirst();
        SalesHeader.TestField(Status, Status);
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

