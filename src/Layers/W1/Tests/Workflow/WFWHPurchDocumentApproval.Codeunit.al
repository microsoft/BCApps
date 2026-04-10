codeunit 134215 "WFWH Purch. Document Approval"
{
    EventSubscriberInstance = Manual;
    Permissions = TableData "User Setup" = imd,
                  TableData "Workflow Webhook Entry" = imd;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Workflow] [Webhook] [Purchase] [Order] [Approval]
    end;

    var
        Assert: Codeunit Assert;
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        ApprovalShouldBeHandledErr: Label 'The approval process must be cancelled or completed to reopen this document.';
        DocCannotBeReleasedErr: Label 'This document can only be released when the approval process is complete.';
        DocCannotBePostedErr: Label '%1 %2 must be approved and released before you can perform this action.', Comment = '%1 = PurchaseHeader."Document Type", %2 = PurchaseHeader."No."';
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        UserCannotCancelErr: Label 'User %1 does not have the permission necessary to cancel the item.', Comment = '%1 = NAV USERID';
        UserCannotActErr: Label 'User %1 cannot act on this step. Make sure the user who created the webhook (%2) is the same who is trying to act.', Comment = '%1, %2 = two distinct NAV user IDs, for example "MEGANB" and "WILLIAMC"';
        BogusUserIdTxt: Label 'CONTOSO';
        RecordIsRestrictedErr: Label 'You cannot use %1 for this action.', Comment = '%1=Record Id';
        LibraryJobQueue: Codeunit "Library - Job Queue";
        MockOnFindTaskSchedulerAllowed: Codeunit MockOnFindTaskSchedulerAllowed;
        WebhookHelper: Codeunit "Webhook Helper";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        DynamicRequestPageParametersOpenPurchaseOrderTxt: Label '<?xml version="1.0" encoding="utf-8" standalone="yes"?><ReportParameters><DataItems><DataItem name="Purchase Header">SORTING(Field1,Field3) WHERE(Field1=1(1),Field120=1(0))</DataItem><DataItem name="Purchase Line">SORTING(Field1,Field3,Field4)</DataItem></DataItems></ReportParameters>', Locked = true;
        UnexpectedNoOfApprovalEntriesErr: Label 'Unexpected number of approval entries found.', Locked = true;

    local procedure Initialize()
    var
        UserSetup: Record "User Setup";
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"WFWH Purch. Document Approval");
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
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"WFWH Purch. Document Approval");
        IsInitialized := true;
        BindSubscription(LibraryJobQueue);
        BindSubscription(MockOnFindTaskSchedulerAllowed);
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"WFWH Purch. Document Approval");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotReleaseOpenPurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrderList: TestPage "Purchase Order List";
    begin
        // [SCENARIO] A user cannot release a purchase order when a webhook purchase document approval workflow is enabled and a purchase order is not approved.
        // [GIVEN] There is a purchase order that is not approved.
        // [GIVEN] A webhook purchase document approval workflow for a purchase order is enabled.
        // [WHEN] The user wants to release the purchase order.
        // [THEN] The user will get an error that an unapproved purchase order cannot be released.

        // Setup
        Initialize();

        CreateAndEnableOpenPurchaseOrderWorkflowDefinition(UserId);
        CreatePurchaseOrder(PurchaseHeader, LibraryRandom.RandIntInRange(5000, 10000));

        // Exercise
        PurchaseOrderList.OpenView();
        PurchaseOrderList.GotoRecord(PurchaseHeader);
        asserterror PurchaseOrderList.Release.Invoke();

        // Verify
        Assert.ExpectedError(DocCannotBeReleasedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotReleaseOpenPurchaseOrderIfApprovalIsPending()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrderList: TestPage "Purchase Order List";
    begin
        // [SCENARIO] A user cannot release a purchase order when a webhook purchase document approval workflow is enabled and a purchase order is pending approval.
        // [GIVEN] There is a purchase order that is sent for approval.
        // [GIVEN] A webhook purchase document approval workflow for a purchase order is enabled.
        // [WHEN] The user wants to release the purchase order.
        // [THEN] The user will get an error that an unapproved purchase order cannot be released.

        // Setup
        Initialize();

        CreateAndEnableOpenPurchaseOrderWorkflowDefinition(UserId);
        CreatePurchaseOrderAndSendForApproval(PurchaseHeader, LibraryRandom.RandIntInRange(5000, 10000));

        Commit();

        // Exercise
        PurchaseOrderList.OpenView();
        PurchaseOrderList.GotoRecord(PurchaseHeader);
        asserterror PurchaseOrderList.Release.Invoke();

        // Verify
        Assert.ExpectedError(StrSubstNo(RecordIsRestrictedErr, Format(PurchaseHeader.RecordId, 0, 1)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotReopenOpenPurchaseOrderIfApprovalIsPending()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrderList: TestPage "Purchase Order List";
    begin
        // [SCENARIO] A user cannot reopen a purchase order when a webhook purchase document approval workflow is enabled and a purchase order is pending approval.
        // [GIVEN] There is a purchase order that is sent for approval.
        // [GIVEN] A webhook purchase document approval workflow for a purchase order is enabled.
        // [WHEN] The user wants to reopen the purchase order.
        // [THEN] The user will get an error that an unapproved purchase order cannot be reopened.

        // Setup
        Initialize();

        CreateAndEnableOpenPurchaseOrderWorkflowDefinition(UserId);
        CreatePurchaseOrder(PurchaseHeader, LibraryRandom.RandIntInRange(5000, 10000));
        PurchaseOrderPageSendForApproval(PurchaseHeader);

        Commit();

        // Exercise
        PurchaseOrderList.OpenView();
        PurchaseOrderList.GotoRecord(PurchaseHeader);
        asserterror PurchaseOrderList.Reopen.Invoke();

        // Verify
        Assert.ExpectedError(ApprovalShouldBeHandledErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotPostOpenPurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrderList: TestPage "Purchase Order List";
    begin
        // [SCENARIO] A user cannot post a purchase order when a webhook purchase document approval workflow is enabled and a purchase order is not approved.
        // [GIVEN] There is a purchase order that is not approved.
        // [GIVEN] A webhook purchase document approval workflow for a purchase order is enabled.
        // [WHEN] The user wants to post the purchase order.
        // [THEN] The user will get an error that an unapproved purchase order cannot be posted.

        // Setup
        Initialize();

        CreateAndEnableOpenPurchaseOrderWorkflowDefinition(UserId);
        CreatePurchaseOrder(PurchaseHeader, LibraryRandom.RandIntInRange(5000, 10000));

        // Exercise
        PurchaseOrderList.OpenView();
        PurchaseOrderList.GotoRecord(PurchaseHeader);
        asserterror PurchaseOrderList.Post.Invoke();

        // Verify
        Assert.ExpectedError(StrSubstNo(DocCannotBePostedErr, PurchaseHeader."Document Type", PurchaseHeader."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureNecessaryTableRelationsAreSetup()
    var
        DummyPurchaseHeader: Record "Purchase Header";
        DummyPurchaseLine: Record "Purchase Line";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowTableRelation: Record "Workflow - Table Relation";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [SCENARIO] Ensure that the necessary webhook purchase document approval workflow table relations are setup.
        // [WHEN] Workflow setup is initialized.
        // [THEN] Workflow table relations for purchase order and workflow webhook entry exist.

        // Setup
        LibraryWorkflow.DeleteAllExistingWorkflows();

        // Excercise
        WorkflowSetup.InitWorkflow();

        // Verify
        WorkflowTableRelation.Get(
          DATABASE::"Purchase Header", DummyPurchaseHeader.FieldNo("Document Type"),
          DATABASE::"Purchase Line", DummyPurchaseLine.FieldNo("Document Type"));
        WorkflowTableRelation.Get(
          DATABASE::"Purchase Header", DummyPurchaseHeader.FieldNo("No."),
          DATABASE::"Purchase Line", DummyPurchaseLine.FieldNo("Document No."));
        WorkflowTableRelation.Get(
          DATABASE::"Purchase Header", DummyPurchaseHeader.FieldNo(SystemId),
          DATABASE::"Workflow Webhook Entry", DummyWorkflowWebhookEntry.FieldNo("Data ID"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureOpenPurchaseOrderApprovalWorkflowFunctionsCorrectlyWhenCancelled()
    var
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        PurchaseHeader: Record "Purchase Header";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook purchase document approval workflow 'cancellation' path works correctly.
        // [GIVEN] A webhook purchase document approval workflow for a purchase order is enabled.
        // [GIVEN] A purchase order is pending approval.
        // [WHEN] The webhook purchase document approval workflow receives a 'cancellation' response for the purchase order.
        // [THEN] The purchase order is cancelled and opened.

        // Setup
        Initialize();

        CreateAndEnableOpenPurchaseOrderWorkflowDefinition(UserId);
        CreatePurchaseOrder(PurchaseHeader, LibraryRandom.RandIntInRange(5000, 10000));
        PurchaseOrderPageSendForApproval(PurchaseHeader);

        Commit();

        // Exercise
        WorkflowWebhookManagement.CancelByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(PurchaseHeader.SystemId));

        // Verify
        VerifyWorkflowWebhookEntryResponse(PurchaseHeader.SystemId, DummyWorkflowWebhookEntry.Response::Cancel);
        VerifyPurchaseDocumentStatus(PurchaseHeader, PurchaseHeader.Status::Open);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureOpenPurchaseOrderApprovalWorkflowFunctionsCorrectlyWhenContinued()
    var
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        PurchaseHeader: Record "Purchase Header";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook purchase document approval workflow 'approval' path works correctly.
        // [GIVEN] A webhook purchase document approval workflow for a purchase order is enabled.
        // [GIVEN] A purchase order is pending approval.
        // [WHEN] The webhook purchase document approval workflow receives an 'approval' response for the purchase order.
        // [THEN] The purchase order is approved and released.

        // Setup
        Initialize();

        CreateAndEnableOpenPurchaseOrderWorkflowDefinition(UserId);
        CreatePurchaseOrder(PurchaseHeader, LibraryRandom.RandIntInRange(5000, 10000));
        PurchaseOrderPageSendForApproval(PurchaseHeader);
        MakeCurrentUserAnApprover();

        Commit();

        // Exercise
        WorkflowWebhookManagement.ContinueByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(PurchaseHeader.SystemId));

        // Verify
        VerifyWorkflowWebhookEntryResponse(PurchaseHeader.SystemId, DummyWorkflowWebhookEntry.Response::Continue);
        VerifyPurchaseDocumentStatus(PurchaseHeader, PurchaseHeader.Status::Released);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureOpenPurchaseOrderApprovalWorkflowFunctionsCorrectlyWhenRejected()
    var
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        PurchaseHeader: Record "Purchase Header";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook purchase document approval workflow 'rejection' path works correctly.
        // [GIVEN] A webhook purchase document approval workflow for a purchase order is enabled.
        // [GIVEN] A purchase order is pending approval.
        // [WHEN] The webhook purchase document approval workflow receives a 'rejection' response for the purchase order.
        // [THEN] The purchase order is rejected and opened.

        // Setup
        Initialize();

        CreateAndEnableOpenPurchaseOrderWorkflowDefinition(UserId);
        CreatePurchaseOrder(PurchaseHeader, LibraryRandom.RandIntInRange(5000, 10000));
        PurchaseOrderPageSendForApproval(PurchaseHeader);
        MakeCurrentUserAnApprover();

        Commit();

        // Exercise
        WorkflowWebhookManagement.RejectByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(PurchaseHeader.SystemId));

        // Verify
        VerifyWorkflowWebhookEntryResponse(PurchaseHeader.SystemId, DummyWorkflowWebhookEntry.Response::Reject);
        VerifyPurchaseDocumentStatus(PurchaseHeader, PurchaseHeader.Status::Open);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureOpenPurchaseOrderApprovalWorkflowFunctionsCorrectlyWithUnauthorizedCancellation()
    var
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        PurchaseHeader: Record "Purchase Header";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook purchase document approval workflow 'cancellation' path works correctly.
        // [GIVEN] A webhook purchase document approval workflow for a purchase order is enabled.
        // [GIVEN] A purchase order is pending approval.
        // [WHEN] The webhook purchase document approval workflow receives a 'cancellation' response from an
        // 'invalid user' for the purchase order.
        // [THEN] The purchase order is not cancelled.

        // Setup
        Initialize();

        CreateAndEnableOpenPurchaseOrderWorkflowDefinition(UserId);
        CreatePurchaseOrder(PurchaseHeader, LibraryRandom.RandIntInRange(5000, 10000));
        PurchaseOrderPageSendForApproval(PurchaseHeader);
        ChangeWorkflowWebhookEntryInitiatedBy(PurchaseHeader.SystemId, BogusUserIdTxt);

        Commit();

        // Exercise
        asserterror WorkflowWebhookManagement.CancelByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(PurchaseHeader.SystemId));

        // Verify
        Assert.ExpectedError(StrSubstNo(UserCannotCancelErr, UserId));
        VerifyWorkflowWebhookEntryResponse(PurchaseHeader.SystemId, DummyWorkflowWebhookEntry.Response::Pending);
        VerifyPurchaseDocumentStatus(PurchaseHeader, PurchaseHeader.Status::"Pending Approval");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureOpenPurchaseOrderApprovalWorkflowFunctionsCorrectlyWithUnauthorizedContinuation()
    var
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        PurchaseHeader: Record "Purchase Header";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook purchase document approval workflow 'approval' path works correctly.
        // [GIVEN] A webhook purchase document approval workflow for a purchase order is enabled.
        // [GIVEN] A purchase order is pending approval.
        // [WHEN] The webhook purchase document approval workflow receives an 'approval' response from an
        // 'invalid user' for the purchase order.
        // [THEN] The purchase order is not continued.

        // Setup
        Initialize();

        CreateAndEnableOpenPurchaseOrderWorkflowDefinition(BogusUserIdTxt);
        CreatePurchaseOrder(PurchaseHeader, LibraryRandom.RandIntInRange(5000, 10000));
        PurchaseOrderPageSendForApproval(PurchaseHeader);

        Commit();

        // Exercise
        asserterror WorkflowWebhookManagement.ContinueByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(PurchaseHeader.SystemId));

        // Verify
        Assert.ExpectedError(StrSubstNo(UserCannotActErr, UserId, BogusUserIdTxt));
        VerifyWorkflowWebhookEntryResponse(PurchaseHeader.SystemId, DummyWorkflowWebhookEntry.Response::Pending);
        VerifyPurchaseDocumentStatus(PurchaseHeader, PurchaseHeader.Status::"Pending Approval");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureOpenPurchaseOrderApprovalWorkflowFunctionsCorrectlyWithUnauthorizedRejection()
    var
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        PurchaseHeader: Record "Purchase Header";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook purchase document approval workflow 'rejection' path works correctly.
        // [GIVEN] A webhook purchase document approval workflow for a purchase order is enabled.
        // [GIVEN] A purchase order is pending approval.
        // [WHEN] The webhook purchase document approval workflow receives a 'rejection' response from an
        // 'invalid user' for the purchase order.
        // [THEN] The purchase order is not rejected.

        // Setup
        Initialize();

        CreateAndEnableOpenPurchaseOrderWorkflowDefinition(BogusUserIdTxt);
        CreatePurchaseOrder(PurchaseHeader, LibraryRandom.RandIntInRange(5000, 10000));
        PurchaseOrderPageSendForApproval(PurchaseHeader);

        Commit();

        // Exercise
        asserterror WorkflowWebhookManagement.RejectByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(PurchaseHeader.SystemId));

        // Verify
        Assert.ExpectedError(StrSubstNo(UserCannotActErr, UserId, BogusUserIdTxt));
        VerifyWorkflowWebhookEntryResponse(PurchaseHeader.SystemId, DummyWorkflowWebhookEntry.Response::Pending);
        VerifyPurchaseDocumentStatus(PurchaseHeader, PurchaseHeader.Status::"Pending Approval");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureOpenPurchaseOrderApprovalWorkflowFunctionsCorrectlyWhenPurchaseOrderIsDeleted()
    var
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        PurchaseHeader: Record "Purchase Header";
    begin
        // [SCENARIO] A user can delete a purchase docuemnt (order) and the existing approval requests will be canceled.
        // [GIVEN] A webhook purchase document approval workflow for a purchase order is enabled.
        // [GIVEN] A purchase order is pending approval.
        // [WHEN] The user deletes the purchase order.
        // [THEN] The exisiting approval requests are deleted and the purchase order is also deleted.

        // Setup
        Initialize();

        CreateAndEnableOpenPurchaseOrderWorkflowDefinition(UserId);
        CreatePurchaseOrder(PurchaseHeader, LibraryRandom.RandIntInRange(5000, 10000));
        PurchaseOrderPageSendForApproval(PurchaseHeader);

        Commit();

        // Verify
        Assert.AreEqual(1, DummyWorkflowWebhookEntry.Count, UnexpectedNoOfApprovalEntriesErr);
        VerifyWorkflowWebhookEntryResponse(PurchaseHeader.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // Exercise
        PurchaseHeader.Find(); // Purcahse document's status was modified so reread from database.
        PurchaseHeader.Delete(true);

        // Verify
        Assert.AreEqual(0, DummyWorkflowWebhookEntry.Count, UnexpectedNoOfApprovalEntriesErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ButtonStatusForPendingApprovalPurchaseOrderCard()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO] Approval actions are correctly enabled/disabled on Purchase Order Card page while Flow approval is pending.
        Initialize();

        // [GIVEN] Purchase Order record exists, with a Flow approval request already open.
        CreatePurchaseOrder(PurchaseHeader, LibraryRandom.RandIntInRange(5000, 10000));
        WebhookHelper.CreatePendingFlowApproval(PurchaseHeader.RecordId);

        // [WHEN] Purchase Order card is opened.
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);

        // [THEN] Cancel is enabled and Send is disabled.
        Assert.IsFalse(PurchaseOrder.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be disabled');
        Assert.IsTrue(PurchaseOrder.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be enabled');

        // Cleanup
        PurchaseOrder.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ButtonStatusForPendingFlowApprovalPurchaseOrderList()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrderList: TestPage "Purchase Order List";
    begin
        // [SCENARIO] Approval actions are correctly enabled/disabled on Purchase Order List page while Flow approval is pending.
        Initialize();

        // [GIVEN] Purchase Order record exists, with a Flow approval request already open.
        CreatePurchaseOrder(PurchaseHeader, LibraryRandom.RandIntInRange(5000, 10000));
        WebhookHelper.CreatePendingFlowApproval(PurchaseHeader.RecordId);

        // [WHEN] Purchase Order list is opened.
        PurchaseOrderList.OpenEdit();
        PurchaseOrderList.GotoRecord(PurchaseHeader);

        // [THEN] Cancel is enabled and Send is disabled.
        Assert.IsFalse(PurchaseOrderList.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be disabled');
        Assert.IsTrue(PurchaseOrderList.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be enabled');

        // Cleanup
        PurchaseOrderList.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ButtonStatusForPendingApprovalPurchaseInvoiceCard()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [SCENARIO] Approval actions are correctly enabled/disabled on Purchase Invoice Card page while Flow approval is pending.
        Initialize();

        // [GIVEN] Purchase Invoice record exists, with a Flow approval request already open.
        CreatePurchaseInvoice(PurchaseHeader, LibraryRandom.RandIntInRange(5000, 10000));
        WebhookHelper.CreatePendingFlowApproval(PurchaseHeader.RecordId);

        // [WHEN] Purchase Invoice card is opened.
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchaseHeader);

        // [THEN] Cancel is enabled and Send is disabled.
        Assert.IsFalse(PurchaseInvoice.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be disabled');
        Assert.IsTrue(PurchaseInvoice.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be enabled');

        // Cleanup
        PurchaseInvoice.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ButtonStatusForPendingFlowApprovalPurchaseInvoiceList()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoices: TestPage "Purchase Invoices";
    begin
        // [SCENARIO] Approval actions are correctly enabled/disabled on Purchase Invoice List page while Flow approval is pending.
        Initialize();

        // [GIVEN] Purchase Invoice record exists, with a Flow approval request already open.
        CreatePurchaseInvoice(PurchaseHeader, LibraryRandom.RandIntInRange(5000, 10000));
        WebhookHelper.CreatePendingFlowApproval(PurchaseHeader.RecordId);

        // [WHEN] Purchase Invoice list is opened.
        PurchaseInvoices.OpenEdit();
        PurchaseInvoices.GotoRecord(PurchaseHeader);

        // [THEN] Cancel is enabled and Send is disabled.
        Assert.IsFalse(PurchaseInvoices.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be disabled');
        Assert.IsTrue(PurchaseInvoices.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be enabled');

        // Cleanup
        PurchaseInvoices.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ButtonStatusForPendingApprovalPurchaseCreditMemoCard()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // [SCENARIO] Approval actions are correctly enabled/disabled on Purchase Credit Memo Card page while Flow approval is pending.
        Initialize();

        // [GIVEN] Purchase Credit Memo record exists, with a Flow approval request already open.
        CreatePurchaseCreditMemo(PurchaseHeader, LibraryRandom.RandIntInRange(5000, 10000));
        WebhookHelper.CreatePendingFlowApproval(PurchaseHeader.RecordId);

        // [WHEN] Purchase Credit Memo card is opened.
        PurchaseCreditMemo.OpenEdit();
        PurchaseCreditMemo.GotoRecord(PurchaseHeader);

        // [THEN] Cancel is enabled and Send is disabled.
        Assert.IsFalse(PurchaseCreditMemo.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be disabled');
        Assert.IsTrue(PurchaseCreditMemo.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be enabled');

        // Cleanup
        PurchaseCreditMemo.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ButtonStatusForPendingFlowApprovalPurchaseCreditMemoList()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseCreditMemos: TestPage "Purchase Credit Memos";
    begin
        // [SCENARIO] Approval actions are correctly enabled/disabled on Purchase Credit Memo List page while Flow approval is pending.
        Initialize();

        // [GIVEN] Purchase Credit Memo record exists, with a Flow approval request already open.
        CreatePurchaseCreditMemo(PurchaseHeader, LibraryRandom.RandIntInRange(5000, 10000));
        WebhookHelper.CreatePendingFlowApproval(PurchaseHeader.RecordId);

        // [WHEN] Purchase Credit Memo list is opened.
        PurchaseCreditMemos.OpenEdit();
        PurchaseCreditMemos.GotoRecord(PurchaseHeader);

        // [THEN] Cancel is enabled and Send is disabled.
        Assert.IsFalse(PurchaseCreditMemos.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be disabled');
        Assert.IsTrue(PurchaseCreditMemos.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be enabled');

        // Cleanup
        PurchaseCreditMemos.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelButtonWorksOnFlowApprovalPurchaseOrderCard()
    var
        PurchaseHeader: Record "Purchase Header";
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO] Clicking cancel action to cancel pending Flow approval on Purchase Order Card page
        Initialize();

        // [GIVEN] Purchase Order record exists, with a Flow approval request already open.
        CreatePurchaseOrder(PurchaseHeader, LibraryRandom.RandIntInRange(5000, 10000));
        WebhookHelper.CreatePendingFlowApproval(PurchaseHeader.RecordId);

        // [WHEN] Purchase Order card is opened and Cancel button is clicked.
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);
        PurchaseOrder.CancelApprovalRequest.Invoke();

        // [THEN] Workflow Webhook Entry record is cancelled
        WorkflowWebhookEntry.FindFirst();
        Assert.AreEqual(WorkflowWebhookEntry.Response::Cancel, WorkflowWebhookEntry.Response, 'Approval request should be cancelled.');

        // Cleanup
        PurchaseOrder.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelButtonWorksOnFlowApprovalPurchaseOrderList()
    var
        PurchaseHeader: Record "Purchase Header";
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
        PurchaseOrderList: TestPage "Purchase Order List";
    begin
        // [SCENARIO] Clicking cancel action to cancel pending Flow approval on Purchase Order List page
        Initialize();

        // [GIVEN] Purchase Order record exists, with a Flow approval request already open.
        CreatePurchaseOrder(PurchaseHeader, LibraryRandom.RandIntInRange(5000, 10000));
        WebhookHelper.CreatePendingFlowApproval(PurchaseHeader.RecordId);

        // [WHEN] Purchase Order list is opened and Cancel button is clicked.
        PurchaseOrderList.OpenEdit();
        PurchaseOrderList.GotoRecord(PurchaseHeader);
        PurchaseOrderList.CancelApprovalRequest.Invoke();

        // [THEN] Workflow Webhook Entry record is cancelled
        WorkflowWebhookEntry.FindFirst();
        Assert.AreEqual(WorkflowWebhookEntry.Response::Cancel, WorkflowWebhookEntry.Response, 'Approval request should be cancelled.');

        // Cleanup
        PurchaseOrderList.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelButtonWorksOnFlowApprovalPurchaseInvoiceCard()
    var
        PurchaseHeader: Record "Purchase Header";
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [SCENARIO] Clicking cancel action to cancel pending Flow approval on Purchase Invoice Card page
        Initialize();

        // [GIVEN] Purchase Invoice record exists, with a Flow approval request already open.
        CreatePurchaseInvoice(PurchaseHeader, LibraryRandom.RandIntInRange(5000, 10000));
        WebhookHelper.CreatePendingFlowApproval(PurchaseHeader.RecordId);

        // [WHEN] Purchase Invoice card is opened and Cancel button is clicked.
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchaseHeader);
        PurchaseInvoice.CancelApprovalRequest.Invoke();

        // [THEN] Workflow Webhook Entry record is cancelled
        WorkflowWebhookEntry.FindFirst();
        Assert.AreEqual(WorkflowWebhookEntry.Response::Cancel, WorkflowWebhookEntry.Response, 'Approval request should be cancelled.');

        // Cleanup
        PurchaseInvoice.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelButtonWorksOnFlowApprovalPurchaseInvoiceList()
    var
        PurchaseHeader: Record "Purchase Header";
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
        PurchaseInvoices: TestPage "Purchase Invoices";
    begin
        // [SCENARIO] Clicking cancel action to cancel pending Flow approval on Purchase Invoice List page
        Initialize();

        // [GIVEN] Purchase Invoice record exists, with a Flow approval request already open.
        CreatePurchaseInvoice(PurchaseHeader, LibraryRandom.RandIntInRange(5000, 10000));
        WebhookHelper.CreatePendingFlowApproval(PurchaseHeader.RecordId);

        // [WHEN] Purchase Invoice list is opened and Cancel button is clicked.
        PurchaseInvoices.OpenEdit();
        PurchaseInvoices.GotoRecord(PurchaseHeader);
        PurchaseInvoices.CancelApprovalRequest.Invoke();

        // [THEN] Workflow Webhook Entry record is cancelled
        WorkflowWebhookEntry.FindFirst();
        Assert.AreEqual(WorkflowWebhookEntry.Response::Cancel, WorkflowWebhookEntry.Response, 'Approval request should be cancelled.');

        // Cleanup
        PurchaseInvoices.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelButtonWorksOnFlowApprovalPurchaseCreditMemoCard()
    var
        PurchaseHeader: Record "Purchase Header";
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // [SCENARIO] Clicking cancel action to cancel pending Flow approval on Purchase Credit Memo Card page
        Initialize();

        // [GIVEN] Purchase Credit Memo record exists, with a Flow approval request already open.
        CreatePurchaseCreditMemo(PurchaseHeader, LibraryRandom.RandIntInRange(5000, 10000));
        WebhookHelper.CreatePendingFlowApproval(PurchaseHeader.RecordId);

        // [WHEN] Purchase Credit Memo card is opened and Cancel button is clicked.
        PurchaseCreditMemo.OpenEdit();
        PurchaseCreditMemo.GotoRecord(PurchaseHeader);
        PurchaseCreditMemo.CancelApprovalRequest.Invoke();

        // [THEN] Workflow Webhook Entry record is cancelled
        WorkflowWebhookEntry.FindFirst();
        Assert.AreEqual(WorkflowWebhookEntry.Response::Cancel, WorkflowWebhookEntry.Response, 'Approval request should be cancelled.');

        // Cleanup
        PurchaseCreditMemo.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelButtonWorksOnFlowApprovalPurchaseCreditMemoList()
    var
        PurchaseHeader: Record "Purchase Header";
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
        PurchaseCreditMemos: TestPage "Purchase Credit Memos";
    begin
        // [SCENARIO] Clicking cancel action to cancel pending Flow approval on Purchase Credit Memo List page
        Initialize();

        // [GIVEN] Purchase Credit Memo record exists, with a Flow approval request already open.
        CreatePurchaseCreditMemo(PurchaseHeader, LibraryRandom.RandIntInRange(5000, 10000));
        WebhookHelper.CreatePendingFlowApproval(PurchaseHeader.RecordId);

        // [WHEN] Purchase Credit Memo list is opened and Cancel button is clicked.
        PurchaseCreditMemos.OpenEdit();
        PurchaseCreditMemos.GotoRecord(PurchaseHeader);
        PurchaseCreditMemos.CancelApprovalRequest.Invoke();

        // [THEN] Workflow Webhook Entry record is cancelled
        WorkflowWebhookEntry.FindFirst();
        Assert.AreEqual(WorkflowWebhookEntry.Response::Cancel, WorkflowWebhookEntry.Response, 'Approval request should be cancelled.');

        // Cleanup
        PurchaseCreditMemos.Close();
    end;

    [Normal]
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

    local procedure CreateAndEnableOpenPurchaseOrderWorkflowDefinition(ResponseUserID: Code[50]): Code[20]
    var
        Workflow: Record Workflow;
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowWebhookSetup: Codeunit "Workflow Webhook Setup";
        WorkflowCode: Code[20];
    begin
        WorkflowCode := WorkflowWebhookSetup.CreateWorkflowDefinition(WorkflowEventHandling.RunWorkflowOnSendPurchaseDocForApprovalCode(),
            '', DynamicRequestPageParametersOpenPurchaseOrderTxt, ResponseUserID);
        Workflow.Get(WorkflowCode);
        LibraryWorkflow.EnableWorkflow(Workflow);
        exit(WorkflowCode);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; Amount: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, '', 1);
        PurchaseLine.Validate("Direct Unit Cost", Amount);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseInvoice(var PurchaseHeader: Record "Purchase Header"; Amount: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, '', 1);
        PurchaseLine.Validate("Direct Unit Cost", Amount);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseCreditMemo(var PurchaseHeader: Record "Purchase Header"; Amount: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, '', 1);
        PurchaseLine.Validate("Direct Unit Cost", Amount);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseOrderAndSendForApproval(var PurchaseHeader: Record "Purchase Header"; Amount: Decimal)
    begin
        CreatePurchaseOrder(PurchaseHeader, Amount);
        PurchaseOrderPageSendForApproval(PurchaseHeader);
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

    local procedure PurchaseOrderPageSendForApproval(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseOrderList: TestPage "Purchase Order List";
    begin
        PurchaseOrderList.OpenView();
        PurchaseOrderList.GotoRecord(PurchaseHeader);
        PurchaseOrderList.SendApprovalRequest.Invoke();
        PurchaseOrderList.Close();

        VerifyPurchaseDocumentStatus(PurchaseHeader, PurchaseHeader.Status::"Pending Approval");
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

    local procedure VerifyPurchaseDocumentStatus(PurchaseHeader: Record "Purchase Header"; Status: Enum "Purchase Document Status")
    begin
        PurchaseHeader.SetRecFilter();
        PurchaseHeader.FindFirst();
        PurchaseHeader.TestField(Status, Status);
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

