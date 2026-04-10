codeunit 134183 "WF Demo Purch BOrder Approvals"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Workflow] [Approval] [Purchase] [Blanket Order]
    end;

    var
        DocCannotBeReleasedErr: Label 'This document can only be released when the approval process is complete.';
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        UnexpectedNoOfApprovalEntriesErr: Label 'Unexpected number of approval entries found.';
        LibraryWorkflow: Codeunit "Library - Workflow";
        NoWorkflowEnabledErr: Label 'No approval workflow for this record type is enabled.';
        ApprovalRequestSendMsg: Label 'An approval request has been sent.';
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        RecordIsRestrictedErr: Label 'You cannot use %1 for this action.', Comment = '%1=Record Id';
        ApprovalShouldBeHandledErr: Label 'The approval process must be cancelled or completed to reopen this document.';
        LibraryJobQueue: Codeunit "Library - Job Queue";
        IsInitialized: Boolean;

    local procedure Initialize()
    var
        UserSetup: Record "User Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"WF Demo Purch BOrder Approvals");
        LibraryVariableStorage.Clear();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryWorkflow.DisableAllWorkflows();
        UserSetup.DeleteAll();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"WF Demo Purch BOrder Approvals");
        IsInitialized := true;
        BindSubscription(LibraryJobQueue);
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"WF Demo Purch BOrder Approvals");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotReleasePurchaseBlanketOrder()
    var
        Workflow: Record Workflow;
        PurchaseHeader: Record "Purchase Header";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
        BlanketPurchaseOrders: TestPage "Blanket Purchase Orders";
    begin
        // [SCENARIO] The user cannot release a purchase blanket order when the approval workflow is enabled and the purchase banket order is not approved.
        // [GIVEN] There is a purchase blanket order that is not approved.
        // [GIVEN] The approval workflow for puchase blanket order is enabled.
        // [WHEN] The user wants to Release the purchase blanket order.
        // [THEN] The user will get an error that he cannot release a purchase blanket order that is not approved.

        // Setup
        Initialize();
        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.PurchaseBlanketOrderApprovalWorkflowCode());

        // Setup - Create 3 user setups, create workflow user group and set the group for the workflow
        LibraryDocumentApprovals.CreateUserSetupsAndGroupOfApproversForWorkflow(
          Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);
        LibraryWorkflow.EnableWorkflow(Workflow);

        CreatePurchDocument(PurchaseHeader, LibraryRandom.RandIntInRange(5000, 10000));

        // Exercise
        BlanketPurchaseOrders.OpenView();
        BlanketPurchaseOrders.GotoRecord(PurchaseHeader);
        asserterror BlanketPurchaseOrders.Release.Invoke();

        // Verify
        Assert.ExpectedError(DocCannotBeReleasedErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CannotReleasePurchaseBlanketOrderApprovalIsPending()
    var
        Workflow: Record Workflow;
        PurchHeader: Record "Purchase Header";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
    begin
        // [SCENARIO] The user cannot release a blanket purchase order when the approval workflow is enabled and the blanket purchase order is pending approval.
        // [GIVEN] There is a blanket purchase order that is sent for approval.
        // [GIVEN] The approval workflow for blanket purchase orders is enabled.
        // [WHEN] The user wants to Release the blanket purchase order.
        // [THEN] The user will get an error that he cannot release the blanket purchase order that is not approved.

        // Setup
        Initialize();
        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.PurchaseBlanketOrderApprovalWorkflowCode());

        // Setup - Create 3 user setups, create workflow user group and set the group for the workflow
        LibraryDocumentApprovals.CreateUserSetupsAndGroupOfApproversForWorkflow(
          Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);
        LibraryWorkflow.EnableWorkflow(Workflow);

        // Setup - Create blanket purchase order
        CreatePurchDocument(PurchHeader, LibraryRandom.RandIntInRange(5000, 10000));

        // Excercise - Open blanket Purchase order card and sent it for approval
        SendBlanketPurchaseOrderForApproval(PurchHeader);

        // Verify - blanket purchase order status is set to Pending Approval
        VerifyPurchaseDocumentStatus(PurchHeader, PurchHeader.Status::"Pending Approval");

        // Exercise
        Commit();
        BlanketPurchaseOrder.OpenView();
        BlanketPurchaseOrder.GotoRecord(PurchHeader);
        asserterror BlanketPurchaseOrder.Release.Invoke();

        // Verify
        Assert.ExpectedError(StrSubstNo(RecordIsRestrictedErr, Format(PurchHeader.RecordId, 0, 1)));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CannotReopenPurchaseBlanketOrderApprovalIsPending()
    var
        Workflow: Record Workflow;
        PurchHeader: Record "Purchase Header";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
    begin
        // [SCENARIO] The user cannot release a blanket purchase order when the approval workflow is enabled and the blanket purchase order is pending approval.
        // [GIVEN] There is a blanket purchase order that is sent for approval.
        // [GIVEN] The approval workflow for blanket purchase orders is enabled.
        // [WHEN] The user wants to Reopen the blanket purchase order.
        // [THEN] The user will get an error that he cannot reopen the blanket purchase order.

        // Setup
        Initialize();

        SendDocForApproval(Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup, PurchHeader);

        // Verify - blanket purchase order status is set to Pending Approval
        VerifyPurchaseDocumentStatus(PurchHeader, PurchHeader.Status::"Pending Approval");

        // Exercise
        BlanketPurchaseOrder.OpenView();
        BlanketPurchaseOrder.GotoRecord(PurchHeader);
        asserterror BlanketPurchaseOrder.Reopen.Invoke();

        // Verify
        Assert.ExpectedError(ApprovalShouldBeHandledErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestBlanketPurchaseOrderApprovalWorkflow()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        PurchHeader: Record "Purchase Header";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
    begin
        // [SCENARIO 1] Test that the Blanket Purchase Order Approval Workflow approval path works with a group of 3 users.
        // [GIVEN] The Blanket Purchase Order Approval Workflow is enabled.
        // [WHEN] A user sends the purchase order for approval and all users in the group of approvals approve the document.
        // [THEN] The blanket purchase order is approved and released.

        Initialize();

        SendDocForApproval(Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup, PurchHeader);

        // Verify - blanket purchase order status is set to Pending Approval
        VerifyPurchaseDocumentStatus(PurchHeader, PurchHeader.Status::"Pending Approval");

        // Verify - Approval requests and their data
        VerifyApprovalRequests(PurchHeader, 3, CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          IntermediateApproverUserSetup."User ID", FinalApproverUserSetup."User ID", ApprovalEntry.Status::Approved,
          ApprovalEntry.Status::Open, ApprovalEntry.Status::Created);

        // Excercise - Set the approverid to USERID so that it can be approved
        UpdateApprovalEntryWithTempUser(CurrentUserSetup, PurchHeader);

        // Excercise - Open blanket Purchae order card and approve the approval request
        ApproveBlanketPurchaseOrder(PurchHeader);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(PurchHeader, 3, CurrentUserSetup."Approver ID", CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          CurrentUserSetup."User ID", ApprovalEntry.Status::Approved, ApprovalEntry.Status::Approved, ApprovalEntry.Status::Open);

        // Excercise - Set the approverid to USERID so that it can be approved
        ApproveBlanketPurchaseOrder(PurchHeader);

        // Verify - blanket purchase order is approved and released
        VerifyPurchaseDocumentStatus(PurchHeader, PurchHeader.Status::Released);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(PurchHeader, 3, CurrentUserSetup."Approver ID", CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          CurrentUserSetup."User ID", ApprovalEntry.Status::Approved, ApprovalEntry.Status::Approved, ApprovalEntry.Status::Approved);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestBlanketPurchaseOrderApprovalWorkflowRejectionPathLastApprover()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        PurchHeader: Record "Purchase Header";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
    begin
        // [SCENARIO 2] Test that the Blanket Purchase Order Approval Workflow rejection path works with a group of 3 users.
        // [GIVEN] The Blanket Purchase Order Approval Workflow is enabled.
        // [WHEN] A user sends the blanket purchase order for approval, the first approver approves it and last approver rejects it.
        // [THEN] The blanket purchase order is rejected and open.

        Initialize();

        SendDocForApproval(Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup, PurchHeader);

        // Verify - Blanket Purchase order status is set to Pending Approval
        VerifyPurchaseDocumentStatus(PurchHeader, PurchHeader.Status::"Pending Approval");

        // Verify - Approval requests and their data
        VerifyApprovalRequests(PurchHeader, 3, CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          IntermediateApproverUserSetup."User ID", FinalApproverUserSetup."User ID", ApprovalEntry.Status::Approved,
          ApprovalEntry.Status::Open, ApprovalEntry.Status::Created);

        // Excercise - Set the approverid to USERID so that it can be approved
        UpdateApprovalEntryWithTempUser(CurrentUserSetup, PurchHeader);

        // Excercise - Open Blanket Purchae order card and approve the approval request
        ApproveBlanketPurchaseOrder(PurchHeader);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(PurchHeader, 3, CurrentUserSetup."Approver ID", CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          CurrentUserSetup."User ID", ApprovalEntry.Status::Approved, ApprovalEntry.Status::Approved, ApprovalEntry.Status::Open);

        // Excercise - Set the approverid to USERID so that it can be rejected
        RejectBlanketPurchaseOrder(PurchHeader);

        // Verify - Blanket Purchase Order is rejected and open
        VerifyPurchaseDocumentStatus(PurchHeader, PurchHeader.Status::Open);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(PurchHeader, 3, CurrentUserSetup."Approver ID", CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          CurrentUserSetup."User ID", ApprovalEntry.Status::Rejected, ApprovalEntry.Status::Rejected, ApprovalEntry.Status::Rejected);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestBlanketPurchaseOrderApprovalWorkflowRejectionPathFirstApprover()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        PurchHeader: Record "Purchase Header";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
    begin
        // [SCENARIO 3] Test that the Blanket Purchase Order Approval Workflow rejection path works with a group of 3 users.
        // [GIVEN] The Blanket Purchase Order Approval Workflow is enabled.
        // [WHEN] A user sends the Blanket purchase order for approval and the first approver rejects it.
        // [THEN] The Blanket purchase order is rejected and open.

        Initialize();

        SendDocForApproval(Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup, PurchHeader);

        // Verify - Blanket Purchase Order status is set to Pending Approval
        VerifyPurchaseDocumentStatus(PurchHeader, PurchHeader.Status::"Pending Approval");

        // Verify - Approval requests and their data
        VerifyApprovalRequests(PurchHeader, 3, CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          IntermediateApproverUserSetup."User ID", FinalApproverUserSetup."User ID", ApprovalEntry.Status::Approved,
          ApprovalEntry.Status::Open, ApprovalEntry.Status::Created);

        // Excercise - Set the approverid to USERID so that it can be approved
        UpdateApprovalEntryWithTempUser(CurrentUserSetup, PurchHeader);

        // Excercise - reject the Blanket Purchase Order
        RejectBlanketPurchaseOrder(PurchHeader);

        // Verify - Blanket Purchase Order is rejected and open
        VerifyPurchaseDocumentStatus(PurchHeader, PurchHeader.Status::Open);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(PurchHeader, 3, CurrentUserSetup."Approver ID", CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          CurrentUserSetup."User ID", ApprovalEntry.Status::Rejected, ApprovalEntry.Status::Rejected, ApprovalEntry.Status::Rejected);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestBlanketPurchaseOrderApprovalWorkflowCancelationPath()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        PurchHeader: Record "Purchase Header";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
    begin
        // [SCENARIO 5] Test that the Blanket Purchase Order Approval Workflow cancelation path works.
        // [GIVEN] The Blanket Purchase Order Approval Workflow is enabled.
        // [WHEN] A user sends the Blanket purchase order for approval and then the user cancels it.
        // [THEN] The Blanket purchase order is canceled and open.

        Initialize();

        SendDocForApproval(Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup, PurchHeader);

        // Verify - Purchase invoice status is set to Pending Approval
        VerifyPurchaseDocumentStatus(PurchHeader, PurchHeader.Status::"Pending Approval");

        // Verify - Approval requests and their data
        VerifyApprovalRequests(PurchHeader, 3, CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          IntermediateApproverUserSetup."User ID", FinalApproverUserSetup."User ID", ApprovalEntry.Status::Approved,
          ApprovalEntry.Status::Open, ApprovalEntry.Status::Created);

        // Excercise - Cancel the Blanket Purchase order
        CancelBlanketPurchaseOrder(PurchHeader);

        // Verify - Blanket Purcahse Order is canceled and open
        VerifyPurchaseDocumentStatus(PurchHeader, PurchHeader.Status::Open);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(PurchHeader, 3, CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          IntermediateApproverUserSetup."User ID", FinalApproverUserSetup."User ID", ApprovalEntry.Status::Canceled,
          ApprovalEntry.Status::Canceled, ApprovalEntry.Status::Canceled);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestBlanketPurchaseOrderApprovalWorkflowDelegationPath()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        PurchHeader: Record "Purchase Header";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
    begin
        // [SCENARIO 6] Test that the Blanket Purchase Order Approval Workflow delegation path works with a group of 3 users and one delegate.
        // [GIVEN] The Blanket Purchase Order Approval Workflow is enabled.
        // [WHEN] A user sends the purchase order for approval and the second user delegates the approval to the 3rd user and the last user approves it.
        // [THEN] The Blanket purchase order is approved and released.

        Initialize();

        SendDocForApproval(Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup, PurchHeader);

        LibraryDocumentApprovals.SetSubstitute(CurrentUserSetup, FinalApproverUserSetup);

        // Verify - Blanket Purchase Order status is set to Pending Approval
        VerifyPurchaseDocumentStatus(PurchHeader, PurchHeader.Status::"Pending Approval");

        // Verify - Approval requests and their data
        VerifyApprovalRequests(PurchHeader, 3, CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          IntermediateApproverUserSetup."User ID", FinalApproverUserSetup."User ID", ApprovalEntry.Status::Approved,
          ApprovalEntry.Status::Open, ApprovalEntry.Status::Created);

        // Excercise - Set the approverid to USERID so that it can be approved
        UpdateApprovalEntryWithTempUser(CurrentUserSetup, PurchHeader);

        // Excercise - Open Blanket Purchae order card and approve the approval request
        ApproveBlanketPurchaseOrder(PurchHeader);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(PurchHeader, 3, CurrentUserSetup."Approver ID", CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          CurrentUserSetup."User ID", ApprovalEntry.Status::Approved, ApprovalEntry.Status::Approved, ApprovalEntry.Status::Open);

        // Excercise - Delegate the Blanket purchase order
        DelegateBlanketPurchaseOrder(PurchHeader);

        // Exercise - Set the approver id
        UpdateApprovalEntryWithTempUser(CurrentUserSetup, PurchHeader);

        // Exercise - Approve the Blanket purchase order
        ApproveBlanketPurchaseOrder(PurchHeader);

        // Verify - Blanket Purchase Order is approved and released
        VerifyPurchaseDocumentStatus(PurchHeader, PurchHeader.Status::Released);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(PurchHeader, 3, CurrentUserSetup."Approver ID", CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          CurrentUserSetup."User ID", ApprovalEntry.Status::Approved, ApprovalEntry.Status::Approved, ApprovalEntry.Status::Approved);
    end;

    [Test]
    [HandlerFunctions('MessageHandlerValidateMessage')]
    [Scope('OnPrem')]
    procedure TestBlanketPurchaseOrderApprovalActionsVisibilityOnCardTest()
    var
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        PurchHeader: Record "Purchase Header";
        Workflow: Record Workflow;
        WorkflowSetup: Codeunit "Workflow Setup";
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
    begin
        // [SCENARIO 3] Approval action availability.
        // [GIVEN] Purchase Header approval disabled.
        Initialize();

        // [WHEN] Purchase Header card is opened.
        CreatePurchDocument(PurchHeader, LibraryRandom.RandIntInRange(5000, 10000));
        Commit();
        BlanketPurchaseOrder.OpenEdit();
        BlanketPurchaseOrder.GotoRecord(PurchHeader);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(BlanketPurchaseOrder.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(BlanketPurchaseOrder.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should NOT be enabled');

        // [WHEN] Send Approval Request is pushed.
        asserterror BlanketPurchaseOrder.SendApprovalRequest.Invoke();

        // [THEN] Error is displayed.
        Assert.ExpectedError(NoWorkflowEnabledErr);

        // Cleanup
        BlanketPurchaseOrder.Close();

        // [GIVEN] PurchHeader approval enabled.
        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.PurchaseBlanketOrderApprovalWorkflowCode());
        LibraryDocumentApprovals.CreateUserSetupsAndGroupOfApproversForWorkflow(
          Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);
        LibraryWorkflow.EnableWorkflow(Workflow);

        // [WHEN] PurchHeader card is opened.
        BlanketPurchaseOrder.OpenEdit();
        BlanketPurchaseOrder.GotoRecord(PurchHeader);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(BlanketPurchaseOrder.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(BlanketPurchaseOrder.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');
        Assert.IsFalse(BlanketPurchaseOrder.Approve.Visible(), 'Approve should NOT be visible');
        Assert.IsFalse(BlanketPurchaseOrder.Reject.Visible(), 'Reject should NOT be visible');
        Assert.IsFalse(BlanketPurchaseOrder.Delegate.Visible(), 'Delegate should NOT be visible');
        BlanketPurchaseOrder.Close();

        // [GIVEN] Approval exist on PurchHeader.
        BlanketPurchaseOrder.OpenEdit();
        BlanketPurchaseOrder.GotoRecord(PurchHeader);

        // [WHEN] PurchHeader send for approval.
        LibraryVariableStorage.Enqueue(ApprovalRequestSendMsg);
        BlanketPurchaseOrder.SendApprovalRequest.Invoke();

        // [THEN] Only Send is enabled.
        Assert.IsFalse(BlanketPurchaseOrder.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be disabled');
        Assert.IsTrue(BlanketPurchaseOrder.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be enabled');

        // Clenup
        BlanketPurchaseOrder.Close();

        // Setup the approval so it can be approve by current user
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(PurchHeader.RecordId);

        // [WHEN] PurchHeader card is opened.
        BlanketPurchaseOrder.OpenEdit();
        BlanketPurchaseOrder.GotoRecord(PurchHeader);

        // [THEN] Approval action are shown.
        Assert.IsTrue(BlanketPurchaseOrder.Approve.Visible(), 'Approve should be visible');
        Assert.IsTrue(BlanketPurchaseOrder.Reject.Visible(), 'Reject should be visible');
        Assert.IsTrue(BlanketPurchaseOrder.Delegate.Visible(), 'Delegate should be visible');
    end;

    [Test]
    [HandlerFunctions('MessageHandlerValidateMessage')]
    [Scope('OnPrem')]
    procedure TestBlanketPurchaseOrderApprovalActionsVisibilityOnListTest()
    var
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        PurchHeader: Record "Purchase Header";
        Workflow: Record Workflow;
        WorkflowSetup: Codeunit "Workflow Setup";
        BlanketPurchaseOrders: TestPage "Blanket Purchase Orders";
    begin
        // [SCENARIO 3] Approval action availability.
        // [GIVEN] PurchHeader approval disabled.
        Initialize();

        // [WHEN] PurchHeader card is opened.
        CreatePurchDocument(PurchHeader, LibraryRandom.RandIntInRange(5000, 10000));
        Commit();
        BlanketPurchaseOrders.OpenEdit();
        BlanketPurchaseOrders.GotoRecord(PurchHeader);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(BlanketPurchaseOrders.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(BlanketPurchaseOrders.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');

        // [WHEN] Send Approval Request is pushed.
        asserterror BlanketPurchaseOrders.SendApprovalRequest.Invoke();

        // [THEN] Error is displayed.
        Assert.ExpectedError(NoWorkflowEnabledErr);

        // Cleanup
        BlanketPurchaseOrders.Close();

        // [GIVEN] PurchHeader approval enabled.
        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.PurchaseBlanketOrderApprovalWorkflowCode());
        LibraryDocumentApprovals.CreateUserSetupsAndGroupOfApproversForWorkflow(
          Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);
        LibraryWorkflow.EnableWorkflow(Workflow);

        // [WHEN] PurchHeader card is opened.
        BlanketPurchaseOrders.OpenEdit();
        BlanketPurchaseOrders.GotoRecord(PurchHeader);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(BlanketPurchaseOrders.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(BlanketPurchaseOrders.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');
        BlanketPurchaseOrders.Close();

        // [GIVEN] Approval exist on PurchHeader.
        BlanketPurchaseOrders.OpenEdit();
        BlanketPurchaseOrders.GotoRecord(PurchHeader);

        // [WHEN] PurchHeader send for approval.
        LibraryVariableStorage.Enqueue(ApprovalRequestSendMsg);
        BlanketPurchaseOrders.SendApprovalRequest.Invoke();

        // [THEN] Only Send is enabled.
        Assert.IsFalse(BlanketPurchaseOrders.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be disabled');
        Assert.IsTrue(BlanketPurchaseOrders.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be enabled');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure BlanketPurchaseOrderApprovalWorkflowApprovePathAddComments()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        PurchaseHeader: Record "Purchase Header";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
    begin
        // [SCENARIO] This test verifies E2E scenario for the Purchase Blanket Order approval workflow on approval path and adds a comment for each step.
        // [GIVEN] Purchase Blanket Order Approval Workflow that has Purchaser as the approver and No Limit as the limit type.
        // [WHEN] Purchase Blanket Order is sent for approval.
        // [THEN] Approval Request is created for the Purchaser and the user can add a comment.
        // [WHEN] Purchaser approves the approval request.
        // [THEN] Purchase Blanket Order is released.

        Initialize();

        SendDocForApproval(Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup, PurchaseHeader);

        CheckCommentsForDocumentOnDocumentCard(PurchaseHeader, 0, false);

        // Verify - Purchase Blanket Order status is set to Pending Approval
        VerifyPurchaseDocumentStatus(PurchaseHeader, PurchaseHeader.Status::"Pending Approval");

        // Verify - Approval requests and their data
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchaseHeader.RecordId);
        Assert.AreEqual(3, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        ApprovalEntry.Next();
        VerifyApprovalEntry(ApprovalEntry, CurrentUserSetup."User ID", IntermediateApproverUserSetup."User ID",
          ApprovalEntry.Status::Open);

        // Setup - Assign the approval entry to current user so that it can be approved
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(PurchaseHeader.RecordId);

        CheckCommentsForDocumentOnDocumentCard(PurchaseHeader, 0, true);
        CheckCommentsForDocumentOnRequestsToApprovePage(ApprovalEntry, 1);

        // Excercise - Open Purchase Blanket Order card and approve the approval request
        ApproveBlanketPurchaseOrder(PurchaseHeader);

        // Verify - Approval requests and their data
        VerifyPurchaseDocumentStatus(PurchaseHeader, PurchaseHeader.Status::"Pending Approval");
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchaseHeader.RecordId);
        VerifyApprovalEntry(ApprovalEntry, IntermediateApproverUserSetup."Approver ID", UserId, ApprovalEntry.Status::Approved);
        CheckCommentsForDocumentOnApprovalEntriesPage(ApprovalEntry, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure BlanketPurchaseOrderApprovalWorkflowTestUserCanCancel()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        PurchaseHeader: Record "Purchase Header";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
    begin
        // [SCENARIO] This test verifies E2E scenario for the Purchase Blanket Order approval workflow on cancellation path and whether a user can cancel the workflow or not.
        // [GIVEN] Purchase Blanket Order Approval Workflow that has Purchaser as the approver and No Limit as the limit type.
        // [WHEN] Purchase Blanket Order is sent for approval.
        // [THEN] Approval Request is created for the Purchaser and user can cancel the request.
        // [WHEN] Next approver opens the document.
        // [THEN] The user can only cancel the request if he is an approval administrator.

        Initialize();

        SendDocForApproval(Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup, PurchaseHeader);

        // Verify - User can cancel the approval request
        CheckUserCanCancelTheApprovalRequest(PurchaseHeader, true);

        // Verify - Purchase Blanket Order status is set to Pending Approval
        VerifyPurchaseDocumentStatus(PurchaseHeader, PurchaseHeader.Status::"Pending Approval");

        // Verify - Approval requests and their data
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchaseHeader.RecordId);
        Assert.AreEqual(3, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        ApprovalEntry.Next();
        VerifyApprovalEntry(ApprovalEntry, CurrentUserSetup."User ID", IntermediateApproverUserSetup."User ID",
          ApprovalEntry.Status::Open);

        // Setup - Assign the approval entry to current user so that it can be approved
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(PurchaseHeader.RecordId);

        // Verify - User Cannot cancel the approval request
        CheckUserCanCancelTheApprovalRequest(PurchaseHeader, false);

        LibraryDocumentApprovals.SetAdministrator(CurrentUserSetup);

        // Verify - User can cancel the approval request
        CheckUserCanCancelTheApprovalRequest(PurchaseHeader, true);

        // Excercise - Open Purchase Blanket Order card and cancel the approval request
        CancelBlanketPurchaseOrder(PurchaseHeader);

        // Verify - Approval requests and their data
        VerifyPurchaseDocumentStatus(PurchaseHeader, PurchaseHeader.Status::Open);
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchaseHeader.RecordId);
        VerifyApprovalEntry(ApprovalEntry, IntermediateApproverUserSetup."Approver ID", UserId, ApprovalEntry.Status::Canceled);
    end;

    local procedure SendDocForApproval(var Workflow: Record Workflow; var CurrentUserSetup: Record "User Setup"; var IntermediateApproverUserSetup: Record "User Setup"; var FinalApproverUserSetup: Record "User Setup"; var PurchaseHeader: Record "Purchase Header")
    var
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.PurchaseBlanketOrderApprovalWorkflowCode());

        // Setup - Create 3 user setups, create workflow user group and set the group for the workflow
        LibraryDocumentApprovals.CreateUserSetupsAndGroupOfApproversForWorkflow(
          Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);
        LibraryWorkflow.EnableWorkflow(Workflow);

        // Setup - Create blanket purchase order
        CreatePurchDocument(PurchaseHeader, LibraryRandom.RandIntInRange(5000, 10000));

        // Excercise - Open blanket Purchase order card and sent it for approval
        SendBlanketPurchaseOrderForApproval(PurchaseHeader);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandlerValidateMessage(Message: Text[1024])
    var
        Variant: Variant;
    begin
        LibraryVariableStorage.Dequeue(Variant);
        Assert.ExpectedMessage(Variant, Message)
    end;

    local procedure CreatePurchDocument(var PurchHeader: Record "Purchase Header"; Amount: Decimal)
    var
        PurchLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::"Blanket Order", '');
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::Item, '', 1);
        PurchLine.Validate("Direct Unit Cost", Amount);
        PurchLine.Modify(true);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Dummy message handler.
    end;

    local procedure SendBlanketPurchaseOrderForApproval(var PurchaseHeader: Record "Purchase Header")
    var
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
    begin
        BlanketPurchaseOrder.OpenView();
        BlanketPurchaseOrder.GotoRecord(PurchaseHeader);
        BlanketPurchaseOrder.SendApprovalRequest.Invoke();
        BlanketPurchaseOrder.Close();
    end;

    local procedure ApproveBlanketPurchaseOrder(var PurchaseHeader: Record "Purchase Header")
    var
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
    begin
        BlanketPurchaseOrder.OpenView();
        BlanketPurchaseOrder.GotoRecord(PurchaseHeader);
        BlanketPurchaseOrder.Approve.Invoke();
        BlanketPurchaseOrder.Close();
    end;

    local procedure RejectBlanketPurchaseOrder(var PurchaseHeader: Record "Purchase Header")
    var
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
    begin
        BlanketPurchaseOrder.OpenView();
        BlanketPurchaseOrder.GotoRecord(PurchaseHeader);
        BlanketPurchaseOrder.Reject.Invoke();
        BlanketPurchaseOrder.Close();
    end;

    local procedure CancelBlanketPurchaseOrder(var PurchaseHeader: Record "Purchase Header")
    var
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
    begin
        BlanketPurchaseOrder.OpenView();
        BlanketPurchaseOrder.GotoRecord(PurchaseHeader);
        BlanketPurchaseOrder.CancelApprovalRequest.Invoke();
        BlanketPurchaseOrder.Close();
    end;

    local procedure DelegateBlanketPurchaseOrder(var PurchaseHeader: Record "Purchase Header")
    var
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
    begin
        BlanketPurchaseOrder.OpenView();
        BlanketPurchaseOrder.GotoRecord(PurchaseHeader);
        BlanketPurchaseOrder.Delegate.Invoke();
        BlanketPurchaseOrder.Close();
    end;

    local procedure UpdateApprovalEntryWithTempUser(UserSetup: Record "User Setup"; PurchHeader: Record "Purchase Header")
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchHeader.RecordId);
        ApprovalEntry.ModifyAll("Sender ID", UserSetup."Approver ID", true);
        ApprovalEntry.ModifyAll("Approver ID", UserSetup."User ID", true);
    end;

    local procedure VerifyPurchaseDocumentStatus(var PurchaseHeader: Record "Purchase Header"; Status: Enum "Purchase Document Status")
    begin
        PurchaseHeader.SetRecFilter();
        PurchaseHeader.FindFirst();
        PurchaseHeader.TestField(Status, Status);
    end;

    local procedure VerifyApprovalEntry(ApprovalEntry: Record "Approval Entry"; SenderId: Code[50]; ApproverId: Code[50]; Status: Enum "Approval Status")
    begin
        ApprovalEntry.TestField("Sender ID", SenderId);
        ApprovalEntry.TestField("Approver ID", ApproverId);
        ApprovalEntry.TestField(Status, Status);
    end;

    local procedure VerifyApprovalRequests(PurchaseHeader: Record "Purchase Header"; ExpectedNumberOfApprovalEntries: Integer; SenderUserID: Code[50]; ApproverUserID1: Code[50]; ApproverUserID2: Code[50]; ApproverUserID3: Code[50]; Status1: Enum "Approval Status"; Status2: Enum "Approval Status"; Status3: Enum "Approval Status")
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchaseHeader.RecordId);
        Assert.AreEqual(ExpectedNumberOfApprovalEntries, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        VerifyApprovalEntry(ApprovalEntry, SenderUserID, ApproverUserID1, Status1);
        ApprovalEntry.Next();
        VerifyApprovalEntry(ApprovalEntry, SenderUserID, ApproverUserID2, Status2);
        ApprovalEntry.Next();
        VerifyApprovalEntry(ApprovalEntry, SenderUserID, ApproverUserID3, Status3);
    end;

    local procedure CheckCommentsForDocumentOnDocumentCard(PurchaseHeader: Record "Purchase Header"; NumberOfExpectedComments: Integer; CommentActionIsVisible: Boolean)
    var
        ApprovalComments: TestPage "Approval Comments";
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
        NumberOfComments: Integer;
    begin
        ApprovalComments.Trap();

        BlanketPurchaseOrder.OpenView();
        BlanketPurchaseOrder.GotoRecord(PurchaseHeader);

        Assert.AreEqual(CommentActionIsVisible, BlanketPurchaseOrder.Comment.Visible(), 'The Comments action has the wrong visibility');

        if CommentActionIsVisible then begin
            BlanketPurchaseOrder.Comment.Invoke();
            if ApprovalComments.First() then
                repeat
                    NumberOfComments += 1;
                until ApprovalComments.Next();
            Assert.AreEqual(NumberOfExpectedComments, NumberOfComments, 'The page contains the wrong number of comments');

            ApprovalComments.Comment.SetValue('Test Comment' + Format(NumberOfExpectedComments));
            ApprovalComments.Next();
            ApprovalComments.Close();
        end;

        BlanketPurchaseOrder.Close();
    end;

    local procedure CheckCommentsForDocumentOnApprovalEntriesPage(ApprovalEntry: Record "Approval Entry"; NumberOfExpectedComments: Integer)
    var
        ApprovalComments: TestPage "Approval Comments";
        ApprovalEntries: TestPage "Approval Entries";
        NumberOfComments: Integer;
    begin
        ApprovalComments.Trap();

        ApprovalEntries.OpenView();
        ApprovalEntries.GotoRecord(ApprovalEntry);

        ApprovalEntries.Comments.Invoke();
        if ApprovalComments.First() then
            repeat
                NumberOfComments += 1;
            until ApprovalComments.Next();
        Assert.AreEqual(NumberOfExpectedComments, NumberOfComments, 'The page contains the wrong number of comments');

        ApprovalComments.Close();

        ApprovalEntries.Close();
    end;

    local procedure CheckCommentsForDocumentOnRequestsToApprovePage(ApprovalEntry: Record "Approval Entry"; NumberOfExpectedComments: Integer)
    var
        ApprovalComments: TestPage "Approval Comments";
        RequeststoApprove: TestPage "Requests to Approve";
        NumberOfComments: Integer;
    begin
        ApprovalComments.Trap();

        RequeststoApprove.OpenView();
        RequeststoApprove.GotoRecord(ApprovalEntry);

        RequeststoApprove.Comments.Invoke();
        if ApprovalComments.First() then
            repeat
                NumberOfComments += 1;
            until ApprovalComments.Next();
        Assert.AreEqual(NumberOfExpectedComments, NumberOfComments, 'The page contains the wrong number of comments');

        ApprovalComments.Close();

        RequeststoApprove.Close();
    end;

    local procedure CheckUserCanCancelTheApprovalRequest(PurchaseHeader: Record "Purchase Header"; CancelActionExpectedEnabled: Boolean)
    var
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
        BlanketPurchaseOrders: TestPage "Blanket Purchase Orders";
    begin
        BlanketPurchaseOrder.OpenView();
        BlanketPurchaseOrder.GotoRecord(PurchaseHeader);
        Assert.AreEqual(CancelActionExpectedEnabled, BlanketPurchaseOrder.CancelApprovalRequest.Enabled(),
          'Wrong state for the Cancel action');
        BlanketPurchaseOrder.Close();

        BlanketPurchaseOrders.OpenView();
        BlanketPurchaseOrders.GotoRecord(PurchaseHeader);
        Assert.AreEqual(CancelActionExpectedEnabled, BlanketPurchaseOrders.CancelApprovalRequest.Enabled(),
          'Wrong state for the Cancel action');
        BlanketPurchaseOrders.Close();
    end;
}

