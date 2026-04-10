codeunit 134182 "WF Demo Purch Rtrn Order Appr."
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Workflow] [Approval] [Purchase] [Return Order]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryRandom: Codeunit "Library - Random";
        DocCannotBeReleasedErr: Label 'This document can only be released when the approval process is complete.';
        DocCannotBePostedErr: Label '%1 %2 must be approved and released before you can perform this action.', Comment = '%1 = PurchHeader."Document Type", %2 = PurchHeader."No."';
        UnexpectedNoOfApprovalEntriesErr: Label 'Unexpected number of approval entries found.';
        LibraryWorkflow: Codeunit "Library - Workflow";
        NoWorkflowEnabledErr: Label 'No approval workflow for this record type is enabled.';
        ApprovalRequestSendMsg: Label 'An approval request has been sent.';
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        RecordIsRestrictedErr: Label 'You cannot use %1 for this action.', Comment = '%1=Record Id';
        ApprovalShouldBeHandledErr: Label 'The approval process must be cancelled or completed to reopen this document.';
        LibraryJobQueue: Codeunit "Library - Job Queue";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure CannotPostPurchaseReturnOrder()
    var
        Workflow: Record Workflow;
        PurchaseHeader: Record "Purchase Header";
        WorkflowSetup: Codeunit "Workflow Setup";
        PurchaseReturnOrderList: TestPage "Purchase Return Order List";
    begin
        // [SCENARIO] The user cannot post a purchase return order when the approval workflow is enabled and the purchase return order is not approved.
        // [GIVEN] There is a purchase return order that is not approved.
        // [GIVEN] The approval workflow for puchase return order is enabled.
        // [WHEN] The user wants to Post the purchase return order.
        // [THEN] The user will get an error that he cannot post a purchase return order that is not approved.

        // Setup
        Initialize();

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseReturnOrderApprovalWorkflowCode());

        CreatePurchaseReturnOrder(PurchaseHeader);

        // Exercise
        PurchaseReturnOrderList.OpenView();
        PurchaseReturnOrderList.GotoRecord(PurchaseHeader);
        asserterror PurchaseReturnOrderList.Post.Invoke();

        // Verify
        Assert.ExpectedError(StrSubstNo(DocCannotBePostedErr, PurchaseHeader."Document Type", PurchaseHeader."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotReleasePurchaseReturnOrder()
    var
        Workflow: Record Workflow;
        PurchaseHeader: Record "Purchase Header";
        WorkflowSetup: Codeunit "Workflow Setup";
        PurchaseReturnOrderList: TestPage "Purchase Return Order List";
    begin
        // [SCENARIO] The user cannot release a purchase return order when the approval workflow is enabled and the purchase return order is not approved.
        // [GIVEN] There is a purchase return order that is not approved.
        // [GIVEN] The approval workflow for puchase return order is enabled.
        // [WHEN] The user wants to Release the purchase return order.
        // [THEN] The user will get an error that he cannot release a purchase return order that is not approved.

        // Setup
        Initialize();

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseReturnOrderApprovalWorkflowCode());

        CreatePurchaseReturnOrder(PurchaseHeader);

        // Exercise
        PurchaseReturnOrderList.OpenView();
        PurchaseReturnOrderList.GotoRecord(PurchaseHeader);
        asserterror PurchaseReturnOrderList.Release.Invoke();

        // Verify
        Assert.ExpectedError(DocCannotBeReleasedErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CannotReleasePurchaseReturnOrderApprovalIsPending()
    var
        Workflow: Record Workflow;
        PurchaseHeader: Record "Purchase Header";
        IntermediateApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        // [SCENARIO] The user cannot release a purchase return order when the approval workflow is enabled and the purchase return order is pending approval.
        // [GIVEN] There is a purchase return order that is sent for approval.
        // [GIVEN] The approval workflow for puchase return orders is enabled.
        // [WHEN] The user wants to Release the purchase return order.
        // [THEN] The user will get an error that he cannot release the purchase return order that is not approved.

        // Setup
        Initialize();
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseReturnOrderApprovalWorkflowCode());

        // Setup - Create 3 approval usersetups
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        // Setup - Create purchase return order
        CreatePurchReturnOrderWithLine(PurchaseHeader, LibraryRandom.RandInt(5000));

        // Setup - Update Purchaser Code
        SetPurchDocPurchaserCode(PurchaseHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        // Excercise - Open Purchase return order card and sent it for approval
        SendPurchaseReturnOrderForApproval(PurchaseHeader);

        // Verify - Purchase return order status is set to Pending Approval
        VerifyPurchaseReturnOrderIsPendingApproval(PurchaseHeader);

        // Exercise
        Commit();
        PurchaseReturnOrder.OpenView();
        PurchaseReturnOrder.GotoRecord(PurchaseHeader);
        asserterror PurchaseReturnOrder."Re&lease".Invoke();

        // Verify
        Assert.ExpectedError(StrSubstNo(RecordIsRestrictedErr, Format(PurchaseHeader.RecordId, 0, 1)));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CannotReopenPurchaseReturnOrderApprovalIsPending()
    var
        Workflow: Record Workflow;
        PurchaseHeader: Record "Purchase Header";
        IntermediateApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        // [SCENARIO] The user cannot release a purchase return order when the approval workflow is enabled and the purchase return order is pending approval.
        // [GIVEN] There is a purchase return order that is sent for approval.
        // [GIVEN] The approval workflow for puchase return orders is enabled.
        // [WHEN] The user wants to Reopen the purchase return order.
        // [THEN] The user will get an error that he cannot reopen the purchase return order.

        // Setup
        Initialize();
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseReturnOrderApprovalWorkflowCode());

        // Setup - Create 3 approval usersetups
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        // Setup - Create purchase return order
        CreatePurchReturnOrderWithLine(PurchaseHeader, LibraryRandom.RandInt(5000));

        // Setup - Update Purchaser Code
        SetPurchDocPurchaserCode(PurchaseHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        // Excercise - Open Purchase return order card and sent it for approval
        SendPurchaseReturnOrderForApproval(PurchaseHeader);

        // Verify - Purchase return order status is set to Pending Approval
        VerifyPurchaseReturnOrderIsPendingApproval(PurchaseHeader);

        // Exercise
        PurchaseReturnOrder.OpenView();
        PurchaseReturnOrder.GotoRecord(PurchaseHeader);
        asserterror PurchaseReturnOrder.Reopen.Invoke();

        // Verify
        Assert.ExpectedError(ApprovalShouldBeHandledErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseReturnOrderApprovalWorkflowOnApprovePath()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        PurchHeader: Record "Purchase Header";
        IntermediateApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [SCENARIO] This test verifies E2E scenario for the purchase return order approval workflow on approval path.
        // [GIVEN] Purchase return order Approval Workflow that has Purchaser as the approver and No Limit as the limit type.
        // [WHEN] Purchase return order is sent for approval.
        // [THEN] Approval Request is created for the purchaser.
        // [WHEN] Purchaser approves the approval request.
        // [THEN] Purchase return order is released.

        Initialize();

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseReturnOrderApprovalWorkflowCode());

        // Setup - Create 3 usersetups
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        // Setup - Create purchase return order
        CreatePurchReturnOrderWithLine(PurchHeader, LibraryRandom.RandInt(5000));

        // Setup - Update Purchaser Code
        SetPurchDocPurchaserCode(PurchHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        // Excercise - Open Purchase return order card and sent it for approval
        SendPurchaseReturnOrderForApproval(PurchHeader);

        // Verify - Purchase return order status is set to Pending Approval
        VerifyPurchaseReturnOrderIsPendingApproval(PurchHeader);

        // Verify - Approval requests and their data
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchHeader.RecordId);
        Assert.AreEqual(1, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, UserId);
        VerifyApprovalEntryApproverID(ApprovalEntry, IntermediateApproverUserSetup."User ID");

        // Setup - Assign the approval entry to current user so that it can be approved
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(PurchHeader.RecordId);

        // Excercise - Open Purchae return order card and approve the approval request
        ApprovePurchaseReturnOrder(PurchHeader);

        // Verify - Approval requests and their data
        VerifyPurchaseReturnOrderIsReleased(PurchHeader);
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchHeader.RecordId);
        VerifyApprovalEntryIsApproved(ApprovalEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseReturnOrderApprovalWorkflowOnRejectionPath()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        PurchHeader: Record "Purchase Header";
        IntermediateApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [SCENARIO] This test verifies E2E scenario for the purchase return order approval workflow on rejection path.
        // [GIVEN] Purchase return order Approval Workflow that has Purchaser as the approver and No Limit as the limit type.
        // [WHEN] Purchase return order is sent for approval.
        // [THEN] Approval Request is created for the purchaser.
        // [WHEN] Purchaser rejects the approval request.
        // [THEN] Purchase return order is reopened and approval entries are marked as rejected.

        Initialize();

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseReturnOrderApprovalWorkflowCode());

        // Setup - Create 3 usersetups
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        // Setup - Create purchase return order
        CreatePurchReturnOrderWithLine(PurchHeader, LibraryRandom.RandInt(5000));

        // Setup - Update Purchaser Code
        SetPurchDocPurchaserCode(PurchHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        // Excercise - Open Purchase return order card and sent it for approval
        SendPurchaseReturnOrderForApproval(PurchHeader);

        // Verify - Purchase return order status is set to Pending Approval
        VerifyPurchaseReturnOrderIsPendingApproval(PurchHeader);

        // Verify - Approval requests and their data
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchHeader.RecordId);
        Assert.AreEqual(1, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, UserId);
        VerifyApprovalEntryApproverID(ApprovalEntry, IntermediateApproverUserSetup."User ID");

        // Assign the approval entry to current user so that it can be approved
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(PurchHeader.RecordId);

        // Excercise - Open Purchae return order card and reject the approval request
        RejectPurchaseReturnOrder(PurchHeader);

        // Verify - Approval requests and their data
        VerifyPurchaseReturnOrderIsOpen(PurchHeader);
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchHeader.RecordId);
        VerifyApprovalEntryIsRejected(ApprovalEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseReturnOrderApprovalWorkflowOnDelegationPath()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        PurchHeader: Record "Purchase Header";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [SCENARIO] This test verifies E2E scenario for the purchase return order approval workflow on delegation path.
        // [GIVEN] Purchase return order Approval Workflow that has Purchaser as the approver and No Limit as the limit type.
        // [WHEN] Purchase return order is sent for approval.
        // [THEN] Approval Request is created for the purchaser.
        // [WHEN] Purchaser delegates the approval request.
        // [THEN] Approval request is assigned to the substitute.
        // [WHEN] Approval Request is approved.
        // [THEN] Purchase return order is released.

        Initialize();

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseReturnOrderApprovalWorkflowCode());

        // Setup - Create 3 usersetups
        LibraryDocumentApprovals.CreateOrFindUserSetup(CurrentUserSetup, UserId);
        LibraryDocumentApprovals.CreateMockupUserSetup(IntermediateApproverUserSetup);
        LibraryDocumentApprovals.CreateMockupUserSetup(FinalApproverUserSetup);

        // Setup - Chain of approvers
        LibraryDocumentApprovals.SetApprover(CurrentUserSetup, IntermediateApproverUserSetup);
        LibraryDocumentApprovals.SetApprover(IntermediateApproverUserSetup, FinalApproverUserSetup);
        LibraryDocumentApprovals.SetSubstitute(CurrentUserSetup, FinalApproverUserSetup);

        // Setup - Create purchase return order
        CreatePurchReturnOrderWithLine(PurchHeader, LibraryRandom.RandInt(5000));

        // Setup - Update Purchaser Code
        SetPurchDocPurchaserCode(PurchHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        // Excercise - Open Purchase return order card and sent it for approval
        SendPurchaseReturnOrderForApproval(PurchHeader);

        // Verify - Purchase return order status is set to Pending Approval
        VerifyPurchaseReturnOrderIsPendingApproval(PurchHeader);

        // Verify - Approval requests and their data
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchHeader.RecordId);
        Assert.AreEqual(1, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, CurrentUserSetup."User ID");
        VerifyApprovalEntryApproverID(ApprovalEntry, IntermediateApproverUserSetup."User ID");

        // Assign the approval entry to current user so that it can be approved
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(PurchHeader.RecordId);

        // Excercise - Open Purchae return order card and delgate the approval request
        DelegatePurchaseReturnOrder(PurchHeader);

        // Verify - Approval requests and their data
        VerifyPurchaseReturnOrderIsPendingApproval(PurchHeader);
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchHeader.RecordId);
        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntryApproverID(ApprovalEntry, FinalApproverUserSetup."User ID");

        // Assign the approval entry to current user so that it can be approved
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(PurchHeader.RecordId);

        // Excercise - Open Purchae return order card and approve the approval request
        ApprovePurchaseReturnOrder(PurchHeader);

        // Verify - Approval requests and their data
        VerifyPurchaseReturnOrderIsReleased(PurchHeader);
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchHeader.RecordId);
        VerifyApprovalEntryIsApproved(ApprovalEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseReturnOrderApprovalWorkflowOnCancellationPath()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        PurchHeader: Record "Purchase Header";
        IntermediateApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [SCENARIO] This test verifies E2E scenario for the purchase return order approval workflow on cancellation path.
        // [GIVEN] Purchase return order Approval Workflow that has Purchaser as the approver and No Limit as the limit type.
        // [WHEN] Purchase return order is sent for approval.
        // [THEN] Approval Request is created for the purchaser.
        // [WHEN] Sender cancels the approval request.
        // [THEN] Purchase return order is opend and approval requests are marked as cancelled.

        Initialize();

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseReturnOrderApprovalWorkflowCode());

        // Setup - Create 3 usersetups
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        // Setup - Create purchase return order
        CreatePurchReturnOrderWithLine(PurchHeader, LibraryRandom.RandInt(5000));

        // Setup - Update Purchaser Code
        SetPurchDocPurchaserCode(PurchHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        // Excercise - Open Purchase return order card and sent it for approval
        SendPurchaseReturnOrderForApproval(PurchHeader);

        // Verify - Purchase return order status is set to Pending Approval
        VerifyPurchaseReturnOrderIsPendingApproval(PurchHeader);

        // Verify - Approval requests and their data
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchHeader.RecordId);
        Assert.AreEqual(1, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, UserId);
        VerifyApprovalEntryApproverID(ApprovalEntry, IntermediateApproverUserSetup."User ID");

        // Excercise - Open Purchae return order card and approve the approval request
        CancelPurchaseReturnOrder(PurchHeader);

        // Verify - Approval requests and their data
        VerifyPurchaseReturnOrderIsOpen(PurchHeader);
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchHeader.RecordId);
        VerifyApprovalEntryIsCancelled(ApprovalEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandlerValidateMessage')]
    [Scope('OnPrem')]
    procedure PurchaseReturnOrderApprovalActionsVisibilityOnCardTest()
    var
        PurchHeader: Record "Purchase Header";
        Workflow: Record Workflow;
        ApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        // [SCENARIO 3] Approval action availability.
        // [GIVEN] Purchase Header approval disabled.
        Initialize();

        // [WHEN] Purchase Header card is opened.
        CreatePurchaseReturnOrder(PurchHeader);
        Commit();
        PurchaseReturnOrder.OpenEdit();
        PurchaseReturnOrder.GotoRecord(PurchHeader);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(PurchaseReturnOrder.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(PurchaseReturnOrder.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should NOT be enabled');

        // [WHEN] Send Approval Request is pushed.
        asserterror PurchaseReturnOrder.SendApprovalRequest.Invoke();

        // [THEN] Error is displayed.
        Assert.ExpectedError(NoWorkflowEnabledErr);

        // Cleanup
        PurchaseReturnOrder.Close();

        // [GIVEN] PurchHeader approval enabled.
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseReturnOrderApprovalWorkflowCode());

        // [WHEN] PurchHeader card is opened.
        PurchaseReturnOrder.OpenEdit();
        PurchaseReturnOrder.GotoRecord(PurchHeader);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(PurchaseReturnOrder.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(PurchaseReturnOrder.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');
        Assert.IsFalse(PurchaseReturnOrder.Approve.Visible(), 'Approve should NOT be visible');
        Assert.IsFalse(PurchaseReturnOrder.Reject.Visible(), 'Reject should NOT be visible');
        Assert.IsFalse(PurchaseReturnOrder.Delegate.Visible(), 'Delegate should NOT be visible');
        PurchaseReturnOrder.Close();

        // [GIVEN] Approval exist on PurchHeader.
        LibraryDocumentApprovals.SetupUsersForApprovals(ApproverUserSetup);
        SetPurchDocPurchaserCode(PurchHeader, ApproverUserSetup."Salespers./Purch. Code");
        PurchaseReturnOrder.OpenEdit();
        PurchaseReturnOrder.GotoRecord(PurchHeader);

        // [WHEN] PurchHeader send for approval.
        LibraryVariableStorage.Enqueue(ApprovalRequestSendMsg);
        PurchaseReturnOrder.SendApprovalRequest.Invoke();

        // [THEN] Only Send is enabled.
        Assert.IsFalse(PurchaseReturnOrder.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be disabled');
        Assert.IsTrue(PurchaseReturnOrder.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be enabled');

        // Clenup
        PurchaseReturnOrder.Close();

        // Setup the approval so it can be approve by current user
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(PurchHeader.RecordId);

        // [WHEN] PurchHeader card is opened.
        PurchaseReturnOrder.OpenEdit();
        PurchaseReturnOrder.GotoRecord(PurchHeader);

        // [THEN] Approval action are shown.
        Assert.IsTrue(PurchaseReturnOrder.Approve.Visible(), 'Approve should be visible');
        Assert.IsTrue(PurchaseReturnOrder.Reject.Visible(), 'Reject should be visible');
        Assert.IsTrue(PurchaseReturnOrder.Delegate.Visible(), 'Delegate should be visible');
    end;

    [Test]
    [HandlerFunctions('MessageHandlerValidateMessage')]
    [Scope('OnPrem')]
    procedure PurchaseReturnOrderApprovalActionsVisibilityOnListTest()
    var
        PurchHeader: Record "Purchase Header";
        Workflow: Record Workflow;
        ApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
        PurchaseReturnOrderList: TestPage "Purchase Return Order List";
    begin
        // [SCENARIO 3] Approval action availability.
        // [GIVEN] PurchHeader approval disabled.
        Initialize();

        // [WHEN] PurchHeader card is opened.
        CreatePurchaseReturnOrder(PurchHeader);
        Commit();
        PurchaseReturnOrderList.OpenEdit();
        PurchaseReturnOrderList.GotoRecord(PurchHeader);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(PurchaseReturnOrderList.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(PurchaseReturnOrderList.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');

        // [WHEN] Send Approval Request is pushed.
        asserterror PurchaseReturnOrderList.SendApprovalRequest.Invoke();

        // [THEN] Error is displayed.
        Assert.ExpectedError(NoWorkflowEnabledErr);

        // Cleanup
        PurchaseReturnOrderList.Close();

        // [GIVEN] PurchHeader approval enabled.
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseReturnOrderApprovalWorkflowCode());

        // [WHEN] PurchHeader card is opened.
        PurchaseReturnOrderList.OpenEdit();
        PurchaseReturnOrderList.GotoRecord(PurchHeader);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(PurchaseReturnOrderList.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(PurchaseReturnOrderList.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');
        PurchaseReturnOrderList.Close();

        // [GIVEN] Approval exist on PurchHeader.
        LibraryDocumentApprovals.SetupUsersForApprovals(ApproverUserSetup);
        SetPurchDocPurchaserCode(PurchHeader, ApproverUserSetup."Salespers./Purch. Code");
        PurchaseReturnOrderList.OpenEdit();
        PurchaseReturnOrderList.GotoRecord(PurchHeader);

        // [WHEN] PurchHeader send for approval.
        LibraryVariableStorage.Enqueue(ApprovalRequestSendMsg);
        PurchaseReturnOrderList.SendApprovalRequest.Invoke();

        // [THEN] Only Send is enabled.
        Assert.IsFalse(PurchaseReturnOrderList.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be disabled');
        Assert.IsTrue(PurchaseReturnOrderList.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be enabled');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseReturnOrderApprovalWorkflowApprovePathAddComments()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        PurchaseHeader: Record "Purchase Header";
        IntermediateApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [SCENARIO] This test verifies E2E scenario for the Purchase Return Order approval workflow on approval path and adds a comment for each step.
        // [GIVEN] Purchase Return Order Approval Workflow that has Purchaser as the approver and No Limit as the limit type.
        // [WHEN] Purchase Return Order is sent for approval.
        // [THEN] Approval Request is created for the Purchaser and the user can add a comment.
        // [WHEN] Purchaser approves the approval request.
        // [THEN] Purchase Return Order is released.

        Initialize();

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseReturnOrderApprovalWorkflowCode());

        // Setup - Create 3 approval usersetups
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        // Setup - Create Purchase Return Order
        CreatePurchReturnOrderWithLine(PurchaseHeader, LibraryRandom.RandInt(5000));

        // Setup - Update Purchaser Code
        SetPurchDocPurchaserCode(PurchaseHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        CheckCommentsForDocumentOnDocumentCard(PurchaseHeader, 0, false);

        // Excercise - Open Purchase Return Order card and sent it for approval
        SendPurchaseReturnOrderForApproval(PurchaseHeader);

        CheckCommentsForDocumentOnDocumentCard(PurchaseHeader, 0, false);

        // Verify - Purchase Return Order status is set to Pending Approval
        VerifyPurchaseReturnOrderIsPendingApproval(PurchaseHeader);

        // Verify - Approval requests and their data
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchaseHeader.RecordId);
        Assert.AreEqual(1, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, UserId);
        VerifyApprovalEntryApproverID(ApprovalEntry, IntermediateApproverUserSetup."User ID");

        // Setup - Assign the approval entry to current user so that it can be approved
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(PurchaseHeader.RecordId);

        CheckCommentsForDocumentOnDocumentCard(PurchaseHeader, 0, true);
        CheckCommentsForDocumentOnRequestsToApprovePage(ApprovalEntry, 1);

        // Excercise - Open Purchase Return Order card and approve the approval request
        ApprovePurchaseReturnOrder(PurchaseHeader);

        // Verify - Approval requests and their data
        VerifyPurchaseReturnOrderIsReleased(PurchaseHeader);
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchaseHeader.RecordId);
        VerifyApprovalEntryIsApproved(ApprovalEntry);
        CheckCommentsForDocumentOnApprovalEntriesPage(ApprovalEntry, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseReturnOrderApprovalWorkflowTestUserCanCancel()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        PurchaseHeader: Record "Purchase Header";
        IntermediateApproverUserSetup: Record "User Setup";
        UserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [SCENARIO] This test verifies E2E scenario for the Purchase Return Order approval workflow on cancellation path and whether a user can cancel the workflow or not.
        // [GIVEN] Purchase Return Order Approval Workflow that has Purchaser as the approver and No Limit as the limit type.
        // [WHEN] Purchase Return Order is sent for approval.
        // [THEN] Approval Request is created for the Purchaser and user can cancel the request.
        // [WHEN] Next approver opens the document.
        // [THEN] The user can only cancel the request if he is an approval administrator.

        Initialize();

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseReturnOrderApprovalWorkflowCode());

        // Setup - Create 3 approval usersetups
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        // Setup - Create Purchase Return Order
        CreatePurchReturnOrderWithLine(PurchaseHeader, LibraryRandom.RandInt(5000));

        // Setup - Update Purchaser Code
        SetPurchDocPurchaserCode(PurchaseHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        // Excercise - Open Purchase Return Order card and sent it for approval
        SendPurchaseReturnOrderForApproval(PurchaseHeader);

        // Verify - User can cancel the approval request
        CheckUserCanCancelTheApprovalRequest(PurchaseHeader, true);

        // Verify - Purchase Return Order status is set to Pending Approval
        VerifyPurchaseReturnOrderIsPendingApproval(PurchaseHeader);

        // Verify - Approval requests and their data
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchaseHeader.RecordId);
        Assert.AreEqual(1, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, UserId);
        VerifyApprovalEntryApproverID(ApprovalEntry, IntermediateApproverUserSetup."User ID");

        // Setup - Assign the approval entry to current user so that it can be approved
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(PurchaseHeader.RecordId);

        // Verify - User Cannot cancel the approval request
        CheckUserCanCancelTheApprovalRequest(PurchaseHeader, false);

        // Setup
        LibraryDocumentApprovals.CreateOrFindUserSetup(UserSetup, UserId);
        LibraryDocumentApprovals.SetAdministrator(UserSetup);

        // Verify - User can cancel the approval request
        CheckUserCanCancelTheApprovalRequest(PurchaseHeader, true);

        // Excercise - Open Purchase Return Order card and cancel the approval request
        CancelPurchaseReturnOrder(PurchaseHeader);

        // Verify - Approval requests and their data
        VerifyPurchaseReturnOrderIsOpen(PurchaseHeader);
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchaseHeader.RecordId);
        VerifyApprovalEntryIsCancelled(ApprovalEntry);
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

    local procedure Initialize()
    var
        UserSetup: Record "User Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"WF Demo Purch Rtrn Order Appr.");
        LibraryVariableStorage.Clear();
        UserSetup.DeleteAll();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryWorkflow.DisableAllWorkflows();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"WF Demo Purch Rtrn Order Appr.");
        IsInitialized := true;
        BindSubscription(LibraryJobQueue);
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"WF Demo Purch Rtrn Order Appr.");
    end;

    local procedure CreatePurchaseReturnOrder(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, '', LibraryRandom.RandInt(100));
    end;

    local procedure CreatePurchReturnOrderWithLine(var PurchHeader: Record "Purchase Header"; Amount: Decimal)
    var
        PurchLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::"Return Order", '');
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

    local procedure SendPurchaseReturnOrderForApproval(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        PurchaseReturnOrder.OpenView();
        PurchaseReturnOrder.GotoRecord(PurchaseHeader);
        PurchaseReturnOrder.SendApprovalRequest.Invoke();
        PurchaseReturnOrder.Close();
    end;

    local procedure RegetPurchaseDocument(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.SetRecFilter();
        PurchaseHeader.FindFirst();
    end;

    local procedure VerifyPurchaseReturnOrderIsReleased(var PurchaseHeader: Record "Purchase Header")
    begin
        RegetPurchaseDocument(PurchaseHeader);
        PurchaseHeader.TestField(Status, PurchaseHeader.Status::Released);
    end;

    local procedure VerifyPurchaseReturnOrderIsOpen(var PurchaseHeader: Record "Purchase Header")
    begin
        RegetPurchaseDocument(PurchaseHeader);
        PurchaseHeader.TestField(Status, PurchaseHeader.Status::Open);
    end;

    local procedure VerifyPurchaseReturnOrderIsPendingApproval(var PurchaseHeader: Record "Purchase Header")
    begin
        RegetPurchaseDocument(PurchaseHeader);
        PurchaseHeader.TestField(Status, PurchaseHeader.Status::"Pending Approval");
    end;

    local procedure VerifyApprovalEntryIsApproved(ApprovalEntry: Record "Approval Entry")
    begin
        ApprovalEntry.TestField(Status, ApprovalEntry.Status::Approved);
    end;

    local procedure VerifyApprovalEntryIsOpen(ApprovalEntry: Record "Approval Entry")
    begin
        ApprovalEntry.TestField(Status, ApprovalEntry.Status::Open);
    end;

    local procedure VerifyApprovalEntryIsRejected(ApprovalEntry: Record "Approval Entry")
    begin
        ApprovalEntry.TestField(Status, ApprovalEntry.Status::Rejected);
    end;

    local procedure VerifyApprovalEntryIsCancelled(ApprovalEntry: Record "Approval Entry")
    begin
        ApprovalEntry.TestField(Status, ApprovalEntry.Status::Canceled);
    end;

    local procedure VerifyApprovalEntrySenderID(ApprovalEntry: Record "Approval Entry"; SenderId: Code[50])
    begin
        ApprovalEntry.TestField("Sender ID", SenderId);
    end;

    local procedure VerifyApprovalEntryApproverID(ApprovalEntry: Record "Approval Entry"; ApproverId: Code[50])
    begin
        ApprovalEntry.TestField("Approver ID", ApproverId);
    end;

    local procedure ApprovePurchaseReturnOrder(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        PurchaseReturnOrder.OpenView();
        PurchaseReturnOrder.GotoRecord(PurchaseHeader);
        PurchaseReturnOrder.Approve.Invoke();
        PurchaseReturnOrder.Close();
    end;

    local procedure RejectPurchaseReturnOrder(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        PurchaseReturnOrder.OpenView();
        PurchaseReturnOrder.GotoRecord(PurchaseHeader);
        PurchaseReturnOrder.Reject.Invoke();
        PurchaseReturnOrder.Close();
    end;

    local procedure DelegatePurchaseReturnOrder(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        PurchaseReturnOrder.OpenView();
        PurchaseReturnOrder.GotoRecord(PurchaseHeader);
        PurchaseReturnOrder.Delegate.Invoke();
        PurchaseReturnOrder.Close();
    end;

    local procedure CancelPurchaseReturnOrder(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        PurchaseReturnOrder.OpenView();
        PurchaseReturnOrder.GotoRecord(PurchaseHeader);
        PurchaseReturnOrder.CancelApprovalRequest.Invoke();
        PurchaseReturnOrder.Close();
    end;

    local procedure SetPurchDocPurchaserCode(PurchaseHeader: Record "Purchase Header"; PurchaserCode: Code[20])
    begin
        PurchaseHeader.Validate("Purchaser Code", PurchaserCode);
        PurchaseHeader.Modify(true);
    end;

    local procedure CheckCommentsForDocumentOnDocumentCard(PurchaseHeader: Record "Purchase Header"; NumberOfExpectedComments: Integer; CommentActionIsVisible: Boolean)
    var
        ApprovalComments: TestPage "Approval Comments";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
        NumberOfComments: Integer;
    begin
        ApprovalComments.Trap();

        PurchaseReturnOrder.OpenView();
        PurchaseReturnOrder.GotoRecord(PurchaseHeader);

        Assert.AreEqual(CommentActionIsVisible, PurchaseReturnOrder.Comment.Visible(), 'The Comments action has the wrong visibility');

        if CommentActionIsVisible then begin
            PurchaseReturnOrder.Comment.Invoke();
            if ApprovalComments.First() then
                repeat
                    NumberOfComments += 1;
                until ApprovalComments.Next();
            Assert.AreEqual(NumberOfExpectedComments, NumberOfComments, 'The page contains the wrong number of comments');

            ApprovalComments.Comment.SetValue('Test Comment' + Format(NumberOfExpectedComments));
            ApprovalComments.Next();
            ApprovalComments.Close();
        end;

        PurchaseReturnOrder.Close();
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
        PurchaseReturnOrder: TestPage "Purchase Return Order";
        PurchaseReturnOrderList: TestPage "Purchase Return Order List";
    begin
        PurchaseReturnOrder.OpenView();
        PurchaseReturnOrder.GotoRecord(PurchaseHeader);
        Assert.AreEqual(CancelActionExpectedEnabled, PurchaseReturnOrder.CancelApprovalRequest.Enabled(),
          'Wrong state for the Cancel action');
        PurchaseReturnOrder.Close();

        PurchaseReturnOrderList.OpenView();
        PurchaseReturnOrderList.GotoRecord(PurchaseHeader);
        Assert.AreEqual(CancelActionExpectedEnabled, PurchaseReturnOrderList.CancelApprovalRequest.Enabled(),
          'Wrong state for the Cancel action');
        PurchaseReturnOrderList.Close();
    end;
}

