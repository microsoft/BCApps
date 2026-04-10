codeunit 134173 "WF Demo Sales RtOrder Approval"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Workflow] [Approval] [Sales] [Return Order]
    end;

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryRandom: Codeunit "Library - Random";
        DocCannotBeReleasedErr: Label 'This document can only be released when the approval process is complete.';
        DocCannotBePostedErr: Label '%1 %2 must be approved and released before you can perform this action.', Comment = '%1 = SalesHeader."Document Type", %2 = SalesHeader."No."';
        UnexpectedNoOfApprovalEntriesErr: Label 'Unexpected number of approval entries found.';
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        NoWorkflowEnabledErr: Label 'No approval workflow for this record type is enabled.';
        ApprovalRequestSendMsg: Label 'An approval request has been sent.';
        RecordIsRestrictedErr: Label 'You cannot use %1 for this action.', Comment = '%1=Record Id';
        ApprovalShouldBeHandledErr: Label 'The approval process must be cancelled or completed to reopen this document.';
        LibraryJobQueue: Codeunit "Library - Job Queue";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure CannotPostSalesReturnOrder()
    var
        Workflow: Record Workflow;
        SalesHeader: Record "Sales Header";
        WorkflowSetup: Codeunit "Workflow Setup";
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        // [SCENARIO] The user cannot post a Sales ReturnOrder when the approval workflow is enabled and the Sales ReturnOrder is not approved and released.
        // [GIVEN] There is a Sales ReturnOrder that is not approved and released.
        // [GIVEN] The approval workflow for puchase ReturnOrders is enabled.
        // [WHEN] The user wants to Post the Sales ReturnOrder.
        // [THEN] The user will get an error that he cannot post a Sales ReturnOrder that is not approved and released.

        // Setup
        Initialize();

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesReturnOrderApprovalWorkflowCode());

        CreateSalesReturnOrder(SalesHeader);

        // Exercise
        SalesReturnOrder.OpenView();
        SalesReturnOrder.GotoRecord(SalesHeader);
        asserterror SalesReturnOrder.Post.Invoke();

        // Verify
        Assert.ExpectedError(StrSubstNo(DocCannotBePostedErr, SalesHeader."Document Type", SalesHeader."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotReleaseSalesReturnOrder()
    var
        Workflow: Record Workflow;
        SalesHeader: Record "Sales Header";
        WorkflowSetup: Codeunit "Workflow Setup";
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        // [SCENARIO] The user cannot release a Sales ReturnOrder when the approval workflow is enabled and the Sales ReturnOrder is not approved.
        // [GIVEN] There is a Sales ReturnOrder that is not approved.
        // [GIVEN] The approval workflow for puchase ReturnOrders is enabled.
        // [WHEN] The user wants to Release the Sales ReturnOrder.
        // [THEN] The user will get an error that he cannot release a Sales ReturnOrder that is not approved.

        // Setup
        Initialize();

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesReturnOrderApprovalWorkflowCode());

        CreateSalesReturnOrder(SalesHeader);

        // Exercise
        SalesReturnOrder.OpenView();
        SalesReturnOrder.GotoRecord(SalesHeader);
        asserterror SalesReturnOrder.Release.Invoke();

        // Verify
        Assert.ExpectedError(DocCannotBeReleasedErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CannotReleaseSalesReturnOrderApprovalIsPending()
    var
        Workflow: Record Workflow;
        SalesHeader: Record "Sales Header";
        IntermediateApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        // [SCENARIO] The user cannot release a sales returnorder when the approval workflow is enabled and the sales returnorder is pending approval.
        // [GIVEN] There is a sales returnorder that is sent for approval.
        // [GIVEN] The approval workflow for sales returnorders is enabled.
        // [WHEN] The user wants to Release the sales returnorder.
        // [THEN] The user will get an error that he cannot release the sales returnorder that is not approved.

        // Setup
        Initialize();
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesReturnOrderApprovalWorkflowCode());

        // Setup - Create 3 approval usersetups
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        // Setup - Create Sales Person code for sales returnorder
        CreateSalesReturnOrderWithLine(SalesHeader, LibraryRandom.RandInt(5000));

        // Setup - Update  Code
        SetSalesDocSalespersonCode(SalesHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        // Excercise - Open sales returnorder card and sent it for approval
        SendSalesReturnOrderForApproval(SalesHeader);

        // Verify - Sales returnorder status is set to Pending Approval
        VerifySalesReturnOrderIsPendingApproval(SalesHeader);

        // Exercise
        Commit();
        SalesReturnOrder.OpenView();
        SalesReturnOrder.GotoRecord(SalesHeader);
        asserterror SalesReturnOrder.Release.Invoke();

        // Verify
        Assert.ExpectedError(StrSubstNo(RecordIsRestrictedErr, Format(SalesHeader.RecordId, 0, 1)));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CannotReopenSalesReturnOrderApprovalIsPending()
    var
        Workflow: Record Workflow;
        SalesHeader: Record "Sales Header";
        IntermediateApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        // [SCENARIO] The user cannot release a sales returnorder when the approval workflow is enabled and the sales returnorder is pending approval.
        // [GIVEN] There is a sales returnorder that is sent for approval.
        // [GIVEN] The approval workflow for sales returnorders is enabled.
        // [WHEN] The user wants to Reopen the sales returnorder.
        // [THEN] The user will get an error that he cannot reopen the sales returnorder.

        // Setup
        Initialize();
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesReturnOrderApprovalWorkflowCode());

        // Setup - Create 3 approval usersetups
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        // Setup - Create sales returnorder
        CreateSalesReturnOrderWithLine(SalesHeader, LibraryRandom.RandInt(5000));

        // Setup - Update Sales person Code
        SetSalesDocSalespersonCode(SalesHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        // Excercise - Open sales returnorder card and sent it for approval
        SendSalesReturnOrderForApproval(SalesHeader);

        // Verify - Sales returnorder status is set to Pending Approval
        VerifySalesReturnOrderIsPendingApproval(SalesHeader);

        // Exercise
        SalesReturnOrder.OpenView();
        SalesReturnOrder.GotoRecord(SalesHeader);
        asserterror SalesReturnOrder.Reopen.Invoke();

        // Verify
        Assert.ExpectedError(ApprovalShouldBeHandledErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesReturnOrderApprovalWorkflowOnApprovePath()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        SalesHeader: Record "Sales Header";
        IntermediateApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [SCENARIO] This test verifies E2E scenario for the Sales ReturnOrder approval workflow on approval path.
        // [GIVEN] Sales ReturnOrder Approval Workflow that has Salesperson as the approver and No Limit as the limit type.
        // [WHEN] Sales ReturnOrder is sent for approval.
        // [THEN] Approval Request is created for the Salesperson.
        // [WHEN] Salesperson approves the approval request.
        // [THEN] Sales ReturnOrder is released.

        Initialize();
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesReturnOrderApprovalWorkflowCode());

        // Setup - Create 3 approval usersetups
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        // Setup - Create Sales ReturnOrder
        CreateSalesReturnOrderWithLine(SalesHeader, LibraryRandom.RandInt(5000));

        // Setup - Update Salesperson Code
        SetSalesDocSalespersonCode(SalesHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        // Excercise - Open Sales ReturnOrder card and sent it for approval
        SendSalesReturnOrderForApproval(SalesHeader);

        // Verify - Sales ReturnOrder status is set to Pending Approval
        VerifySalesReturnOrderIsPendingApproval(SalesHeader);

        // Verify - Approval requests and their data
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
        Assert.AreEqual(1, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, UserId);
        VerifyApprovalEntryApproverID(ApprovalEntry, IntermediateApproverUserSetup."User ID");

        // Setup - Assign the approval entry to current user so that it can be approved
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(SalesHeader.RecordId);

        // Excercise - Open Sales ReturnOrder card and approve the approval request
        ApproveSalesReturnOrder(SalesHeader);

        // Verify - Approval requests and their data
        VerifySalesReturnOrderIsReleased(SalesHeader);
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
        VerifyApprovalEntryIsApproved(ApprovalEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesReturnOrderApprovalWorkflowOnRejectionPath()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        SalesHeader: Record "Sales Header";
        IntermediateApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [SCENARIO] This test verifies E2E scenario for the Sales ReturnOrder approval workflow on rejection path.
        // [GIVEN] Sales ReturnOrder Approval Workflow that has Salesperson as the approver and No Limit as the limit type.
        // [WHEN] Sales ReturnOrder is sent for approval.
        // [THEN] Approval Request is created for the Salesperson.
        // [WHEN] Salesperson rejects the approval request.
        // [THEN] Sales ReturnOrder is reopened and approval entries are marked as rejected.

        Initialize();
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesReturnOrderApprovalWorkflowCode());

        // Setup - Create 3 approval usersetups
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        // Setup - Create Sales ReturnOrder
        CreateSalesReturnOrderWithLine(SalesHeader, LibraryRandom.RandInt(5000));

        // Setup - Update Salesperson Code
        SetSalesDocSalespersonCode(SalesHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        // Excercise - Open Sales ReturnOrder card and sent it for approval
        SendSalesReturnOrderForApproval(SalesHeader);

        // Verify - Sales ReturnOrder status is set to Pending Approval
        VerifySalesReturnOrderIsPendingApproval(SalesHeader);

        // Verify - Approval requests and their data
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
        Assert.AreEqual(1, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, UserId);
        VerifyApprovalEntryApproverID(ApprovalEntry, IntermediateApproverUserSetup."User ID");

        // Assign the approval entry to current user so that it can be approved
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(SalesHeader.RecordId);

        // Excercise - Open Sales ReturnOrder card and reject the approval request
        RejectSalesReturnOrder(SalesHeader);

        // Verify - Approval requests and their data
        VerifySalesReturnOrderIsOpen(SalesHeader);
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
        VerifyApprovalEntryIsRejected(ApprovalEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesReturnOrderApprovalWorkflowOnDelegationPath()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        SalesHeader: Record "Sales Header";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [SCENARIO] This test verifies E2E scenario for the Sales ReturnOrder approval workflow on delegation path.
        // [GIVEN] Sales ReturnOrder Approval Workflow that has Salesperson as the approver and No Limit as the limit type.
        // [WHEN] Sales ReturnOrder is sent for approval.
        // [THEN] Approval Request is created for the Salesperson.
        // [WHEN] Salesperson delegates the approval request.
        // [THEN] Approval request is assigned to the substitute.
        // [WHEN] Approval Request is approved.
        // [THEN] Sales ReturnOrder is released.

        Initialize();
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesReturnOrderApprovalWorkflowCode());

        // Setup - Create 3 usersetups
        LibraryDocumentApprovals.CreateOrFindUserSetup(CurrentUserSetup, UserId);
        LibraryDocumentApprovals.CreateMockupUserSetup(IntermediateApproverUserSetup);
        LibraryDocumentApprovals.CreateMockupUserSetup(FinalApproverUserSetup);

        // Setup - Chain of approvers
        LibraryDocumentApprovals.SetApprover(CurrentUserSetup, IntermediateApproverUserSetup);
        LibraryDocumentApprovals.SetApprover(IntermediateApproverUserSetup, FinalApproverUserSetup);
        LibraryDocumentApprovals.SetSubstitute(CurrentUserSetup, FinalApproverUserSetup);

        // Setup - Create Sales ReturnOrder
        CreateSalesReturnOrderWithLine(SalesHeader, LibraryRandom.RandInt(5000));

        // Setup - Update Salesperson Code
        SetSalesDocSalespersonCode(SalesHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        // Excercise - Open Sales ReturnOrder card and sent it for approval
        SendSalesReturnOrderForApproval(SalesHeader);

        // Verify - Sales ReturnOrder status is set to Pending Approval
        VerifySalesReturnOrderIsPendingApproval(SalesHeader);

        // Verify - Approval requests and their data
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
        Assert.AreEqual(1, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, CurrentUserSetup."User ID");
        VerifyApprovalEntryApproverID(ApprovalEntry, IntermediateApproverUserSetup."User ID");

        // Assign the approval entry to current user so that it can be approved
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(SalesHeader.RecordId);

        // Excercise - Open Sales ReturnOrder card and delgate the approval request
        DelegateSalesReturnOrder(SalesHeader);

        // Verify - Approval requests and their data
        VerifySalesReturnOrderIsPendingApproval(SalesHeader);
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntryApproverID(ApprovalEntry, FinalApproverUserSetup."User ID");

        // Assign the approval entry to current user so that it can be approved
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(SalesHeader.RecordId);

        // Excercise - Open Sales ReturnOrder card and approve the approval request
        ApproveSalesReturnOrder(SalesHeader);

        // Verify - Approval requests and their data
        VerifySalesReturnOrderIsReleased(SalesHeader);
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
        VerifyApprovalEntryIsApproved(ApprovalEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesReturnOrderApprovalWorkflowOnCancellationPath()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        SalesHeader: Record "Sales Header";
        IntermediateApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [SCENARIO] This test verifies E2E scenario for the Sales ReturnOrder approval workflow on cancellation path.
        // [GIVEN] Sales ReturnOrder Approval Workflow that has Salesperson as the approver and No Limit as the limit type.
        // [WHEN] Sales ReturnOrder is sent for approval.
        // [THEN] Approval Request is created for the Salesperson.
        // [WHEN] Sender cancels the approval request.
        // [THEN] Sales ReturnOrder is opend and approval requests are marked as cancelled.

        Initialize();
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesReturnOrderApprovalWorkflowCode());

        // Setup - Create 3 approval usersetups
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        // Setup - Create Sales ReturnOrder
        CreateSalesReturnOrderWithLine(SalesHeader, LibraryRandom.RandInt(5000));

        // Setup - Update Salesperson Code
        SetSalesDocSalespersonCode(SalesHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        // Excercise - Open Sales ReturnOrder card and sent it for approval
        SendSalesReturnOrderForApproval(SalesHeader);

        // Verify - Sales ReturnOrder status is set to Pending Approval
        VerifySalesReturnOrderIsPendingApproval(SalesHeader);

        // Verify - Approval requests and their data
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
        Assert.AreEqual(1, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, UserId);
        VerifyApprovalEntryApproverID(ApprovalEntry, IntermediateApproverUserSetup."User ID");

        // Excercise - Open Sales ReturnOrder card and cancel the approval request
        CancelSalesReturnOrder(SalesHeader);

        // Verify - Approval requests and their data
        VerifySalesReturnOrderIsOpen(SalesHeader);
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
        VerifyApprovalEntryIsCancelled(ApprovalEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandlerValidateMessage')]
    [Scope('OnPrem')]
    procedure SalesReturnOrderApprovalActionsVisibilityOnCardTest()
    var
        SalesHeader: Record "Sales Header";
        Workflow: Record Workflow;
        ApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        // [SCENARIO 3] Approval action availability.
        // [GIVEN] SalesHeader approval disabled.
        Initialize();

        // [WHEN] SalesHeader card is opened.
        CreateSalesReturnOrder(SalesHeader);
        Commit();
        SalesReturnOrder.OpenEdit();
        SalesReturnOrder.GotoRecord(SalesHeader);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(SalesReturnOrder.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(SalesReturnOrder.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should NOT be enabled');

        // [WHEN] Send Approval Request is pushed.
        asserterror SalesReturnOrder.SendApprovalRequest.Invoke();

        // [THEN] Error is displayed.
        Assert.ExpectedError(NoWorkflowEnabledErr);

        // Cleanup
        SalesReturnOrder.Close();

        // [GIVEN] SalesHeader approval enabled.
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesReturnOrderApprovalWorkflowCode());

        // [WHEN] SalesHeader card is opened.
        SalesReturnOrder.OpenEdit();
        SalesReturnOrder.GotoRecord(SalesHeader);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(SalesReturnOrder.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(SalesReturnOrder.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');
        Assert.IsFalse(SalesReturnOrder.Approve.Visible(), 'Approve should NOT be visible');
        Assert.IsFalse(SalesReturnOrder.Reject.Visible(), 'Reject should NOT be visible');
        Assert.IsFalse(SalesReturnOrder.Delegate.Visible(), 'Delegate should NOT be visible');
        SalesReturnOrder.Close();

        // [GIVEN] Approval exist on SalesHeader.
        LibraryDocumentApprovals.SetupUsersForApprovals(ApproverUserSetup);
        SetSalesDocSalespersonCode(SalesHeader, ApproverUserSetup."Salespers./Purch. Code");
        SalesReturnOrder.OpenEdit();
        SalesReturnOrder.GotoRecord(SalesHeader);

        // [WHEN] SalesHeader send for approval.
        LibraryVariableStorage.Enqueue(ApprovalRequestSendMsg);
        SalesReturnOrder.SendApprovalRequest.Invoke();

        // [THEN] Only Send is enabled.
        Assert.IsFalse(SalesReturnOrder.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be disabled');
        Assert.IsTrue(SalesReturnOrder.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be enabled');

        // Clenup
        SalesReturnOrder.Close();

        // Setup the approval so it can be approve by current user
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(SalesHeader.RecordId);

        // [WHEN] SalesHeader card is opened.
        SalesReturnOrder.OpenEdit();
        SalesReturnOrder.GotoRecord(SalesHeader);

        // [THEN] Approval action are shown.
        Assert.IsTrue(SalesReturnOrder.Approve.Visible(), 'Approva should be visible');
        Assert.IsTrue(SalesReturnOrder.Reject.Visible(), 'Reject should be visible');
        Assert.IsTrue(SalesReturnOrder.Delegate.Visible(), 'Delegate should be visible');
    end;

    [Test]
    [HandlerFunctions('MessageHandlerValidateMessage')]
    [Scope('OnPrem')]
    procedure SalesReturnOrderApprovalActionsVisibilityOnListTest()
    var
        SalesHeader: Record "Sales Header";
        Workflow: Record Workflow;
        ApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
        SalesReturnOrderList: TestPage "Sales Return Order List";
    begin
        // [SCENARIO 3] Approval action availability.
        // [GIVEN] SalesHeader approval disabled.
        Initialize();

        // [WHEN] SalesHeader card is opened.
        CreateSalesReturnOrder(SalesHeader);
        Commit();
        SalesReturnOrderList.OpenEdit();
        SalesReturnOrderList.GotoRecord(SalesHeader);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(SalesReturnOrderList.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(SalesReturnOrderList.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');

        // [WHEN] Send Approval Request is pushed.
        asserterror SalesReturnOrderList.SendApprovalRequest.Invoke();

        // [THEN] Error is displayed.
        Assert.ExpectedError(NoWorkflowEnabledErr);

        // Cleanup
        SalesReturnOrderList.Close();

        // [GIVEN] SalesHeader approval enabled.
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesReturnOrderApprovalWorkflowCode());

        // [WHEN] SalesHeader card is opened.
        SalesReturnOrderList.OpenEdit();
        SalesReturnOrderList.GotoRecord(SalesHeader);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(SalesReturnOrderList.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(SalesReturnOrderList.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');
        SalesReturnOrderList.Close();

        // [GIVEN] Approval exist on SalesHeader.
        LibraryDocumentApprovals.SetupUsersForApprovals(ApproverUserSetup);
        SetSalesDocSalespersonCode(SalesHeader, ApproverUserSetup."Salespers./Purch. Code");
        SalesReturnOrderList.OpenEdit();
        SalesReturnOrderList.GotoRecord(SalesHeader);

        // [WHEN] SalesHeader send for approval.
        LibraryVariableStorage.Enqueue(ApprovalRequestSendMsg);
        SalesReturnOrderList.SendApprovalRequest.Invoke();

        // [THEN] Only Send is enabled.
        Assert.IsFalse(SalesReturnOrderList.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be disabled');
        Assert.IsTrue(SalesReturnOrderList.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be enabled');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesReturnOrderApprovalWorkflowApprovePathAddComments()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        SalesHeader: Record "Sales Header";
        IntermediateApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [SCENARIO] This test verifies E2E scenario for the Sales return order approval workflow on approval path and adds a comment for each step.
        // [GIVEN] Sales Return Order Approval Workflow that has Salesperson as the approver and No Limit as the limit type.
        // [WHEN] Sales Return Order is sent for approval.
        // [THEN] Approval Request is created for the Salesperson and the user can add a comment.
        // [WHEN] Salesperson approves the approval request.
        // [THEN] Sales Return Order is released.

        Initialize();

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesReturnOrderApprovalWorkflowCode());

        // Setup - Create 3 approval usersetups
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        // Setup - Create Sales Return Order
        CreateSalesReturnOrderWithLine(SalesHeader, LibraryRandom.RandInt(5000));

        // Setup - Update Salesperson Code
        SetSalesDocSalespersonCode(SalesHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        CheckCommentsForDocumentOnDocumentCard(SalesHeader, 0, false);

        // Excercise - Open Sales Return Order card and sent it for approval
        SendSalesReturnOrderForApproval(SalesHeader);

        CheckCommentsForDocumentOnDocumentCard(SalesHeader, 0, false);

        // Verify - Sales Return Order status is set to Pending Approval
        VerifySalesReturnOrderIsPendingApproval(SalesHeader);

        // Verify - Approval requests and their data
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
        Assert.AreEqual(1, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, UserId);
        VerifyApprovalEntryApproverID(ApprovalEntry, IntermediateApproverUserSetup."User ID");

        // Setup - Assign the approval entry to current user so that it can be approved
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(SalesHeader.RecordId);

        CheckCommentsForDocumentOnDocumentCard(SalesHeader, 0, true);
        CheckCommentsForDocumentOnRequestsToApprovePage(ApprovalEntry, 1);

        // Excercise - Open Sales Return Order card and approve the approval request
        ApproveSalesReturnOrder(SalesHeader);

        // Verify - Approval requests and their data
        VerifySalesReturnOrderIsReleased(SalesHeader);
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
        VerifyApprovalEntryIsApproved(ApprovalEntry);
        CheckCommentsForDocumentOnApprovalEntriesPage(ApprovalEntry, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesReturnOrderApprovalWorkflowTestUserCanCancel()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        SalesHeader: Record "Sales Header";
        IntermediateApproverUserSetup: Record "User Setup";
        UserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [SCENARIO] This test verifies E2E scenario for the Sales Return Order approval workflow on cancellation path and whether a user can cancel the workflow or not.
        // [GIVEN] Sales Return Order Approval Workflow that has Salesperson as the approver and No Limit as the limit type.
        // [WHEN] Sales Return Order is sent for approval.
        // [THEN] Approval Request is created for the Salesperson and user can cancel the request.
        // [WHEN] Next approver opens the document.
        // [THEN] The user can only cancel the request if he is an approval administrator.

        Initialize();

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesReturnOrderApprovalWorkflowCode());

        // Setup - Create 3 approval usersetups
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        // Setup - Create Sales Return Order
        CreateSalesReturnOrderWithLine(SalesHeader, LibraryRandom.RandInt(5000));

        // Setup - Update Salesperson Code
        SetSalesDocSalespersonCode(SalesHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        // Excercise - Open Sales Return Order card and sent it for approval
        SendSalesReturnOrderForApproval(SalesHeader);

        // Verify - User can cancel the approval request
        CheckUserCanCancelTheApprovalRequest(SalesHeader, true);

        // Verify - Sales Return Order status is set to Pending Approval
        VerifySalesReturnOrderIsPendingApproval(SalesHeader);

        // Verify - Approval requests and their data
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
        Assert.AreEqual(1, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, UserId);
        VerifyApprovalEntryApproverID(ApprovalEntry, IntermediateApproverUserSetup."User ID");

        // Setup - Assign the approval entry to current user so that it can be approved
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(SalesHeader.RecordId);

        // Verify - User Cannot cancel the approval request
        CheckUserCanCancelTheApprovalRequest(SalesHeader, false);

        // Setup
        LibraryDocumentApprovals.CreateOrFindUserSetup(UserSetup, UserId);
        LibraryDocumentApprovals.SetAdministrator(UserSetup);

        // Verify - User can cancel the approval request
        CheckUserCanCancelTheApprovalRequest(SalesHeader, true);

        // Excercise - Open Sales Return Order card and cancel the approval request
        CancelSalesReturnOrder(SalesHeader);

        // Verify - Approval requests and their data
        VerifySalesReturnOrderIsOpen(SalesHeader);
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
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
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"WF Demo Sales RtOrder Approval");
        LibraryVariableStorage.Clear();
        UserSetup.DeleteAll();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryWorkflow.DisableAllWorkflows();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"WF Demo Sales RtOrder Approval");
        IsInitialized := true;
        BindSubscription(LibraryJobQueue);
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"WF Demo Sales RtOrder Approval");
    end;

    local procedure CreateSalesReturnOrder(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, '', LibraryRandom.RandInt(100));
    end;

    local procedure CreateSalesReturnOrderWithLine(var SalesHeader: Record "Sales Header"; Amount: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, '', 1);
        SalesLine.Validate("Unit Price", Amount);
        SalesLine.Modify(true);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Dummy message handler.
    end;

    local procedure SendSalesReturnOrderForApproval(var SalesHeader: Record "Sales Header")
    var
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        SalesReturnOrder.OpenView();
        SalesReturnOrder.GotoRecord(SalesHeader);
        SalesReturnOrder.SendApprovalRequest.Invoke();
        SalesReturnOrder.Close();
    end;

    local procedure RegetSalesDocument(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.SetRecFilter();
        SalesHeader.FindFirst();
    end;

    local procedure VerifySalesReturnOrderIsReleased(var SalesHeader: Record "Sales Header")
    begin
        RegetSalesDocument(SalesHeader);
        SalesHeader.TestField(Status, SalesHeader.Status::Released);
    end;

    local procedure VerifySalesReturnOrderIsOpen(var SalesHeader: Record "Sales Header")
    begin
        RegetSalesDocument(SalesHeader);
        SalesHeader.TestField(Status, SalesHeader.Status::Open);
    end;

    local procedure VerifySalesReturnOrderIsPendingApproval(var SalesHeader: Record "Sales Header")
    begin
        RegetSalesDocument(SalesHeader);
        SalesHeader.TestField(Status, SalesHeader.Status::"Pending Approval");
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

    local procedure ApproveSalesReturnOrder(var SalesHeader: Record "Sales Header")
    var
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        SalesReturnOrder.OpenView();
        SalesReturnOrder.GotoRecord(SalesHeader);
        SalesReturnOrder.Approve.Invoke();
        SalesReturnOrder.Close();
    end;

    local procedure RejectSalesReturnOrder(var SalesHeader: Record "Sales Header")
    var
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        SalesReturnOrder.OpenView();
        SalesReturnOrder.GotoRecord(SalesHeader);
        SalesReturnOrder.Reject.Invoke();
        SalesReturnOrder.Close();
    end;

    local procedure DelegateSalesReturnOrder(var SalesHeader: Record "Sales Header")
    var
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        SalesReturnOrder.OpenView();
        SalesReturnOrder.GotoRecord(SalesHeader);
        SalesReturnOrder.Delegate.Invoke();
        SalesReturnOrder.Close();
    end;

    local procedure CancelSalesReturnOrder(var SalesHeader: Record "Sales Header")
    var
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        SalesReturnOrder.OpenView();
        SalesReturnOrder.GotoRecord(SalesHeader);
        SalesReturnOrder.CancelApprovalRequest.Invoke();
        SalesReturnOrder.Close();
    end;

    local procedure SetSalesDocSalespersonCode(SalesHeader: Record "Sales Header"; SalespersonCode: Code[20])
    begin
        SalesHeader.Validate("Salesperson Code", SalespersonCode);
        SalesHeader.Modify(true);
    end;

    local procedure CheckCommentsForDocumentOnDocumentCard(SalesHeader: Record "Sales Header"; NumberOfExpectedComments: Integer; CommentActionIsVisible: Boolean)
    var
        ApprovalComments: TestPage "Approval Comments";
        SalesReturnOrder: TestPage "Sales Return Order";
        NumberOfComments: Integer;
    begin
        ApprovalComments.Trap();

        SalesReturnOrder.OpenView();
        SalesReturnOrder.GotoRecord(SalesHeader);

        Assert.AreEqual(CommentActionIsVisible, SalesReturnOrder.Comment.Visible(), 'The Comments action has the wrong visibility');

        if CommentActionIsVisible then begin
            SalesReturnOrder.Comment.Invoke();
            if ApprovalComments.First() then
                repeat
                    NumberOfComments += 1;
                until ApprovalComments.Next();
            Assert.AreEqual(NumberOfExpectedComments, NumberOfComments, 'The page contains the wrong number of comments');

            ApprovalComments.Comment.SetValue('Test Comment' + Format(NumberOfExpectedComments));
            ApprovalComments.Next();
            ApprovalComments.Close();
        end;

        SalesReturnOrder.Close();
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

    local procedure CheckUserCanCancelTheApprovalRequest(SalesHeader: Record "Sales Header"; CancelActionExpectedEnabled: Boolean)
    var
        SalesReturnOrder: TestPage "Sales Return Order";
        SalesReturnOrderList: TestPage "Sales Return Order List";
    begin
        SalesReturnOrder.OpenView();
        SalesReturnOrder.GotoRecord(SalesHeader);
        Assert.AreEqual(CancelActionExpectedEnabled, SalesReturnOrder.CancelApprovalRequest.Enabled(),
          'Wrong state for the Cancel action');
        SalesReturnOrder.Close();

        SalesReturnOrderList.OpenView();
        SalesReturnOrderList.GotoRecord(SalesHeader);
        Assert.AreEqual(CancelActionExpectedEnabled, SalesReturnOrderList.CancelApprovalRequest.Enabled(),
          'Wrong state for the Cancel action');
        SalesReturnOrderList.Close();
    end;
}

