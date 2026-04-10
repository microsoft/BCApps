codeunit 134171 "WF Demo Sales CrMemo Approvals"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Workflow] [Approval] [Sales] [Credit Memo]
    end;

    var
        Workflow: Record Workflow;
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
    procedure CannotPostSalesCreditMemo()
    var
        SalesHeader: Record "Sales Header";
        WorkflowSetup: Codeunit "Workflow Setup";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [SCENARIO] The user cannot post a Sales CreditMemo when the approval workflow is enabled and the Sales CreditMemo is not approved and released.
        // [GIVEN] There is a Sales CreditMemo that is not approved and released.
        // [GIVEN] The approval workflow for puchase CreditMemos is enabled.
        // [WHEN] The user wants to Post the Sales CreditMemo.
        // [THEN] The user will get an error that he cannot post a Sales CreditMemo that is not approved and released.

        // Setup
        Initialize();

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesCreditMemoApprovalWorkflowCode());

        CreateSalesCreditMemo(SalesHeader);

        // Exercise
        SalesCreditMemo.OpenView();
        SalesCreditMemo.GotoRecord(SalesHeader);
        asserterror SalesCreditMemo.Post.Invoke();

        // Verify
        Assert.ExpectedError(StrSubstNo(DocCannotBePostedErr, SalesHeader."Document Type", SalesHeader."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotReleaseSalesCreditMemo()
    var
        Workflow: Record Workflow;
        SalesHeader: Record "Sales Header";
        WorkflowSetup: Codeunit "Workflow Setup";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [SCENARIO] The user cannot release a Sales CreditMemo when the approval workflow is enabled and the Sales CreditMemo is not approved.
        // [GIVEN] There is a Sales CreditMemo that is not approved.
        // [GIVEN] The approval workflow for puchase CreditMemos is enabled.
        // [WHEN] The user wants to Release the Sales CreditMemo.
        // [THEN] The user will get an error that he cannot release a Sales CreditMemo that is not approved.

        // Setup
        Initialize();

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesCreditMemoApprovalWorkflowCode());

        CreateSalesCreditMemo(SalesHeader);

        // Exercise
        SalesCreditMemo.OpenView();
        SalesCreditMemo.GotoRecord(SalesHeader);
        asserterror SalesCreditMemo.Release.Invoke();

        // Verify
        Assert.ExpectedError(DocCannotBeReleasedErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CannotReleaseSalesCreditMemoApprovalIsPending()
    var
        Workflow: Record Workflow;
        SalesHeader: Record "Sales Header";
        IntermediateApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [SCENARIO] The user cannot release a sales creditmemo when the approval workflow is enabled and the sales creditmemo is pending approval.
        // [GIVEN] There is a sales creditmemo that is sent for approval.
        // [GIVEN] The approval workflow for sales creditmemos is enabled.
        // [WHEN] The user wants to Release the sales creditmemo.
        // [THEN] The user will get an error that he cannot release the sales creditmemo that is not approved.

        // Setup
        Initialize();
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesCreditMemoApprovalWorkflowCode());

        // Setup - Create 3 approval usersetups
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        // Setup - Create Sales Person code for sales creditmemo
        CreateSalesCreditMemoWithLine(SalesHeader, LibraryRandom.RandInt(5000));

        // Setup - Update  Code
        SetSalesDocSalespersonCode(SalesHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        // Excercise - Open sales invoice card and sent it for approval
        SendSalesCreditMemoForApproval(SalesHeader);

        // Verify - Sales invoice status is set to Pending Approval
        VerifySalesCreditMemoIsPendingApproval(SalesHeader);

        // Exercise
        Commit();
        SalesCreditMemo.OpenView();
        SalesCreditMemo.GotoRecord(SalesHeader);
        asserterror SalesCreditMemo.Release.Invoke();

        // Verify
        Assert.ExpectedError(StrSubstNo(RecordIsRestrictedErr, Format(SalesHeader.RecordId, 0, 1)));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CannotReopenSalesCreditMemoApprovalIsPending()
    var
        Workflow: Record Workflow;
        SalesHeader: Record "Sales Header";
        IntermediateApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [SCENARIO] The user cannot release a sales invoice when the approval workflow is enabled and the sales invoice is pending approval.
        // [GIVEN] There is a sales invoice that is sent for approval.
        // [GIVEN] The approval workflow for sales invoices is enabled.
        // [WHEN] The user wants to Reopen the sales invoice.
        // [THEN] The user will get an error that he cannot reopen the sales invoice.

        // Setup
        Initialize();
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesCreditMemoApprovalWorkflowCode());

        // Setup - Create 3 approval usersetups
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        // Setup - Create sales invoice
        CreateSalesCreditMemoWithLine(SalesHeader, LibraryRandom.RandInt(5000));

        // Setup - Update Sales person Code
        SetSalesDocSalespersonCode(SalesHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        // Excercise - Open sales invoice card and sent it for approval
        SendSalesCreditMemoForApproval(SalesHeader);

        // Verify - Sales invoice status is set to Pending Approval
        VerifySalesCreditMemoIsPendingApproval(SalesHeader);

        // Exercise
        SalesCreditMemo.OpenView();
        SalesCreditMemo.GotoRecord(SalesHeader);
        asserterror SalesCreditMemo.Reopen.Invoke();

        // Verify
        Assert.ExpectedError(ApprovalShouldBeHandledErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesCreditMemoApprovalWorkflowOnApprovePath()
    var
        ApprovalEntry: Record "Approval Entry";
        SalesHeader: Record "Sales Header";
        IntermediateApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [SCENARIO] This test verifies E2E scenario for the Sales CreditMemo approval workflow on approval path.
        // [GIVEN] Sales CreditMemo Approval Workflow that has Salesperson as the approver and No Limit as the limit type.
        // [WHEN] Sales CreditMemo is sent for approval.
        // [THEN] Approval Request is created for the Salesperson.
        // [WHEN] Salesperson approves the approval request.
        // [THEN] Sales CreditMemo is released.

        Initialize();

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesCreditMemoApprovalWorkflowCode());

        // Setup - Create 3 approval usersetups
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        // Setup - Create Sales CreditMemo
        CreateSalesCreditMemoWithLine(SalesHeader, LibraryRandom.RandInt(5000));

        // Setup - Update Salesperson Code
        SetSalesDocSalespersonCode(SalesHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        // Excercise - Open Sales CreditMemo card and sent it for approval
        SendSalesCreditMemoForApproval(SalesHeader);

        // Verify - Sales CreditMemo status is set to Pending Approval
        VerifySalesCreditMemoIsPendingApproval(SalesHeader);

        // Verify - Approval requests and their data
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
        Assert.AreEqual(1, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, UserId);
        VerifyApprovalEntryApproverID(ApprovalEntry, IntermediateApproverUserSetup."User ID");

        // Setup - Assign the approval entry to current user so that it can be approved
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(SalesHeader.RecordId);

        // Excercise - Open Sales CreditMemo card and approve the approval request
        ApproveSalesCreditMemo(SalesHeader);

        // Verify - Approval requests and their data
        VerifySalesCreditMemoIsReleased(SalesHeader);
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
        VerifyApprovalEntryIsApproved(ApprovalEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesCreditMemoApprovalWorkflowOnRejectionPath()
    var
        ApprovalEntry: Record "Approval Entry";
        SalesHeader: Record "Sales Header";
        IntermediateApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [SCENARIO] This test verifies E2E scenario for the Sales CreditMemo approval workflow on rejection path.
        // [GIVEN] Sales CreditMemo Approval Workflow that has Salesperson as the approver and No Limit as the limit type.
        // [WHEN] Sales CreditMemo is sent for approval.
        // [THEN] Approval Request is created for the Salesperson.
        // [WHEN] Salesperson rejects the approval request.
        // [THEN] Sales CreditMemo is reopened and approval entries are marked as rejected.

        Initialize();

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesCreditMemoApprovalWorkflowCode());

        // Setup - Create 3 approval usersetups
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        // Setup - Create Sales CreditMemo
        CreateSalesCreditMemoWithLine(SalesHeader, LibraryRandom.RandInt(5000));

        // Setup - Update Salesperson Code
        SetSalesDocSalespersonCode(SalesHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        // Excercise - Open Sales CreditMemo card and sent it for approval
        SendSalesCreditMemoForApproval(SalesHeader);

        // Verify - Sales CreditMemo status is set to Pending Approval
        VerifySalesCreditMemoIsPendingApproval(SalesHeader);

        // Verify - Approval requests and their data
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
        Assert.AreEqual(1, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, UserId);
        VerifyApprovalEntryApproverID(ApprovalEntry, IntermediateApproverUserSetup."User ID");

        // Assign the approval entry to current user so that it can be approved
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(SalesHeader.RecordId);

        // Excercise - Open Sales CreditMemo card and reject the approval request
        RejectSalesCreditMemo(SalesHeader);

        // Verify - Approval requests and their data
        VerifySalesCreditMemoIsOpen(SalesHeader);
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
        VerifyApprovalEntryIsRejected(ApprovalEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesCreditMemoApprovalWorkflowOnDelegationPath()
    var
        ApprovalEntry: Record "Approval Entry";
        SalesHeader: Record "Sales Header";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [SCENARIO] This test verifies E2E scenario for the Sales CreditMemo approval workflow on delegation path.
        // [GIVEN] Sales CreditMemo Approval Workflow that has Salesperson as the approver and No Limit as the limit type.
        // [WHEN] Sales CreditMemo is sent for approval.
        // [THEN] Approval Request is created for the Salesperson.
        // [WHEN] Salesperson delegates the approval request.
        // [THEN] Approval request is assigned to the substitute.
        // [WHEN] Approval Request is approved.
        // [THEN] Sales CreditMemo is released.
        Initialize();

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesCreditMemoApprovalWorkflowCode());

        // Setup - Create 3 usersetups
        LibraryDocumentApprovals.CreateOrFindUserSetup(CurrentUserSetup, UserId);
        LibraryDocumentApprovals.CreateMockupUserSetup(IntermediateApproverUserSetup);
        LibraryDocumentApprovals.CreateMockupUserSetup(FinalApproverUserSetup);

        // Setup - Chain of approvers
        LibraryDocumentApprovals.SetApprover(CurrentUserSetup, IntermediateApproverUserSetup);
        LibraryDocumentApprovals.SetApprover(IntermediateApproverUserSetup, FinalApproverUserSetup);
        LibraryDocumentApprovals.SetSubstitute(CurrentUserSetup, FinalApproverUserSetup);

        // Setup - Create Sales CreditMemo
        CreateSalesCreditMemoWithLine(SalesHeader, LibraryRandom.RandInt(5000));

        // Setup - Update Salesperson Code
        SetSalesDocSalespersonCode(SalesHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        // Excercise - Open Sales CreditMemo card and sent it for approval
        SendSalesCreditMemoForApproval(SalesHeader);

        // Verify - Sales CreditMemo status is set to Pending Approval
        VerifySalesCreditMemoIsPendingApproval(SalesHeader);

        // Verify - Approval requests and their data
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
        Assert.AreEqual(1, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, UserId);
        VerifyApprovalEntryApproverID(ApprovalEntry, IntermediateApproverUserSetup."User ID");

        // Assign the approval entry to current user so that it can be approved
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(SalesHeader.RecordId);

        // Excercise - Open Sales CreditMemo card and delgate the approval request
        DelegateSalesCreditMemo(SalesHeader);

        // Verify - Approval requests and their data
        VerifySalesCreditMemoIsPendingApproval(SalesHeader);
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntryApproverID(ApprovalEntry, FinalApproverUserSetup."User ID");

        // Assign the approval entry to current user so that it can be approved
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(SalesHeader.RecordId);

        // Excercise - Open Sales CreditMemo card and approve the approval request
        ApproveSalesCreditMemo(SalesHeader);

        // Verify - Approval requests and their data
        VerifySalesCreditMemoIsReleased(SalesHeader);
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
        VerifyApprovalEntryIsApproved(ApprovalEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesCreditMemoApprovalWorkflowOnCancellationPath()
    var
        ApprovalEntry: Record "Approval Entry";
        SalesHeader: Record "Sales Header";
        IntermediateApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [SCENARIO] This test verifies E2E scenario for the Sales CreditMemo approval workflow on cancellation path.
        // [GIVEN] Sales CreditMemo Approval Workflow that has Salesperson as the approver and No Limit as the limit type.
        // [WHEN] Sales CreditMemo is sent for approval.
        // [THEN] Approval Request is created for the Salesperson.
        // [WHEN] Sender cancels the approval request.
        // [THEN] Sales CreditMemo is opend and approval requests are marked as cancelled.
        Initialize();

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesCreditMemoApprovalWorkflowCode());

        // Setup - Create 3 approval usersetups
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        // Setup - Create Sales CreditMemo
        CreateSalesCreditMemoWithLine(SalesHeader, LibraryRandom.RandInt(5000));

        // Setup - Update Salesperson Code
        SetSalesDocSalespersonCode(SalesHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        // Excercise - Open Sales CreditMemo card and sent it for approval
        SendSalesCreditMemoForApproval(SalesHeader);

        // Verify - Sales CreditMemo status is set to Pending Approval
        VerifySalesCreditMemoIsPendingApproval(SalesHeader);

        // Verify - Approval requests and their data
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
        Assert.AreEqual(1, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, UserId);
        VerifyApprovalEntryApproverID(ApprovalEntry, IntermediateApproverUserSetup."User ID");

        // Excercise - Open Sales CreditMemo card and cancel the approval request
        CancelSalesCreditMemo(SalesHeader);

        // Verify - Approval requests and their data
        VerifySalesCreditMemoIsOpen(SalesHeader);
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
        VerifyApprovalEntryIsCancelled(ApprovalEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandlerValidateMessage')]
    [Scope('OnPrem')]
    procedure SalesCreditMemoApprovalActionsVisibilityOnCardTest()
    var
        SalesHeader: Record "Sales Header";
        Workflow: Record Workflow;
        ApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [SCENARIO 3] Approval action availability.
        // [GIVEN] SalesHeader approval disabled.
        Initialize();

        // [WHEN] SalesHeader card is opened.
        CreateSalesCreditMemo(SalesHeader);
        Commit();
        SalesCreditMemo.OpenEdit();
        SalesCreditMemo.GotoRecord(SalesHeader);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(SalesCreditMemo.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(SalesCreditMemo.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should NOT be enabled');

        // [WHEN] Send Approval Request is pushed.
        asserterror SalesCreditMemo.SendApprovalRequest.Invoke();

        // [THEN] Error is displayed.
        Assert.ExpectedError(NoWorkflowEnabledErr);

        // Cleanup
        SalesCreditMemo.Close();

        // [GIVEN] SalesHeader approval enabled.
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesCreditMemoApprovalWorkflowCode());

        // [WHEN] SalesHeader card is opened.
        SalesCreditMemo.OpenEdit();
        SalesCreditMemo.GotoRecord(SalesHeader);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(SalesCreditMemo.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(SalesCreditMemo.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');
        Assert.IsFalse(SalesCreditMemo.Approve.Visible(), 'Approve should NOT be visible');
        Assert.IsFalse(SalesCreditMemo.Reject.Visible(), 'Reject should NOT be visible');
        Assert.IsFalse(SalesCreditMemo.Delegate.Visible(), 'Delegate should NOT be visible');
        SalesCreditMemo.Close();

        // [GIVEN] Approval exist on SalesHeader.
        LibraryDocumentApprovals.SetupUsersForApprovals(ApproverUserSetup);
        SetSalesDocSalespersonCode(SalesHeader, ApproverUserSetup."Salespers./Purch. Code");
        SalesCreditMemo.OpenEdit();
        SalesCreditMemo.GotoRecord(SalesHeader);

        // [WHEN] SalesHeader send for approval.
        LibraryVariableStorage.Enqueue(ApprovalRequestSendMsg);
        SalesCreditMemo.SendApprovalRequest.Invoke();

        // [THEN] Only Send is enabled.
        Assert.IsFalse(SalesCreditMemo.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be disabled');
        Assert.IsTrue(SalesCreditMemo.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be enabled');

        // Clenup
        SalesCreditMemo.Close();

        // Setup the approval so it can be approve by current user
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(SalesHeader.RecordId);

        // [WHEN] SalesHeader card is opened.
        SalesCreditMemo.OpenEdit();
        SalesCreditMemo.GotoRecord(SalesHeader);

        // [THEN] Approval action are shown.
        Assert.IsTrue(SalesCreditMemo.Approve.Visible(), 'Approva should be visible');
        Assert.IsTrue(SalesCreditMemo.Reject.Visible(), 'Reject should be visible');
        Assert.IsTrue(SalesCreditMemo.Delegate.Visible(), 'Delegate should be visible');
    end;

    [Test]
    [HandlerFunctions('MessageHandlerValidateMessage')]
    [Scope('OnPrem')]
    procedure SalesCreditMemoApprovalActionsVisibilityOnListTest()
    var
        SalesHeader: Record "Sales Header";
        Workflow: Record Workflow;
        ApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
        SalesCreditMemos: TestPage "Sales Credit Memos";
    begin
        // [SCENARIO 3] Approval action availability.
        // [GIVEN] SalesHeader approval disabled.
        Initialize();

        // [WHEN] SalesHeader card is opened.
        CreateSalesCreditMemo(SalesHeader);
        Commit();
        SalesCreditMemos.OpenEdit();
        SalesCreditMemos.GotoRecord(SalesHeader);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(SalesCreditMemos.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(SalesCreditMemos.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');

        // [WHEN] Send Approval Request is pushed.
        asserterror SalesCreditMemos.SendApprovalRequest.Invoke();

        // [THEN] Error is displayed.
        Assert.ExpectedError(NoWorkflowEnabledErr);

        // Cleanup
        SalesCreditMemos.Close();

        // [GIVEN] SalesHeader approval enabled.
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesCreditMemoApprovalWorkflowCode());

        // [WHEN] SalesHeader card is opened.
        SalesCreditMemos.OpenEdit();
        SalesCreditMemos.GotoRecord(SalesHeader);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(SalesCreditMemos.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(SalesCreditMemos.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');
        SalesCreditMemos.Close();

        // [GIVEN] Approval exist on SalesHeader.
        LibraryDocumentApprovals.SetupUsersForApprovals(ApproverUserSetup);
        SetSalesDocSalespersonCode(SalesHeader, ApproverUserSetup."Salespers./Purch. Code");
        SalesCreditMemos.OpenEdit();
        SalesCreditMemos.GotoRecord(SalesHeader);

        // [WHEN] SalesHeader send for approval.
        LibraryVariableStorage.Enqueue(ApprovalRequestSendMsg);
        SalesCreditMemos.SendApprovalRequest.Invoke();

        // [THEN] Only Send is enabled.
        Assert.IsFalse(SalesCreditMemos.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be disabled');
        Assert.IsTrue(SalesCreditMemos.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be enabled');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesCreditMemoApprovalWorkflowApprovePathAddComments()
    var
        ApprovalEntry: Record "Approval Entry";
        SalesHeader: Record "Sales Header";
        IntermediateApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [SCENARIO] This test verifies E2E scenario for the Sales credit memo approval workflow on approval path and adds a comment for each step.
        // [GIVEN] Sales Credit Memo Approval Workflow that has Salesperson as the approver and No Limit as the limit type.
        // [WHEN] Sales Credit Memo is sent for approval.
        // [THEN] Approval Request is created for the Salesperson and the user can add a comment.
        // [WHEN] Salesperson approves the approval request.
        // [THEN] Sales Credit Memo is released.

        Initialize();

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesCreditMemoApprovalWorkflowCode());

        // Setup - Create 3 approval usersetups
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        // Setup - Create Sales invoice
        CreateSalesCreditMemoWithLine(SalesHeader, LibraryRandom.RandInt(5000));

        // Setup - Update Salesperson Code
        SetSalesDocSalespersonCode(SalesHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        CheckCommentsForDocumentOnDocumentCard(SalesHeader, 0, false);

        // Excercise - Open Sales invoice card and sent it for approval
        SendSalesCreditMemoForApproval(SalesHeader);

        CheckCommentsForDocumentOnDocumentCard(SalesHeader, 0, false);

        // Verify - Sales invoice status is set to Pending Approval
        VerifySalesCreditMemoIsPendingApproval(SalesHeader);

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

        // Excercise - Open Sales invoice card and approve the approval request
        ApproveSalesCreditMemo(SalesHeader);

        // Verify - Approval requests and their data
        VerifySalesCreditMemoIsReleased(SalesHeader);
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
        VerifyApprovalEntryIsApproved(ApprovalEntry);
        CheckCommentsForDocumentOnApprovalEntriesPage(ApprovalEntry, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesCreditMemoApprovalWorkflowTestUserCanCancel()
    var
        ApprovalEntry: Record "Approval Entry";
        SalesHeader: Record "Sales Header";
        IntermediateApproverUserSetup: Record "User Setup";
        UserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [SCENARIO] This test verifies E2E scenario for the Sales invoice approval workflow on cancellation path and whether a user can cancel the workflow or not.
        // [GIVEN] Sales Invoice Approval Workflow that has Salesperson as the approver and No Limit as the limit type.
        // [WHEN] Sales Invoice is sent for approval.
        // [THEN] Approval Request is created for the Salesperson and user can cancel the request.
        // [WHEN] Next approver opens the document.
        // [THEN] The user can only cancel the request if he is an approval administrator.

        Initialize();

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesCreditMemoApprovalWorkflowCode());

        // Setup - Create 3 approval usersetups
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        // Setup - Create Sales invoice
        CreateSalesCreditMemoWithLine(SalesHeader, LibraryRandom.RandInt(5000));

        // Setup - Update Salesperson Code
        SetSalesDocSalespersonCode(SalesHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        // Excercise - Open Sales invoice card and sent it for approval
        SendSalesCreditMemoForApproval(SalesHeader);

        // Verify - User can cancel the approval request
        CheckUserCanCancelTheApprovalRequest(SalesHeader, true);

        // Verify - Sales invoice status is set to Pending Approval
        VerifySalesCreditMemoIsPendingApproval(SalesHeader);

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

        // Excercise - Open Sales invoice card and cancel the approval request
        CancelSalesCreditMemo(SalesHeader);

        // Verify - Approval requests and their data
        VerifySalesCreditMemoIsOpen(SalesHeader);
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
        LibraryTestInitialize.OnTestInitialize(Codeunit::"WF Demo Sales CrMemo Approvals");
        LibraryVariableStorage.Clear();
        UserSetup.DeleteAll();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryWorkflow.DisableAllWorkflows();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"WF Demo Sales CrMemo Approvals");
        IsInitialized := true;
        BindSubscription(LibraryJobQueue);
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"WF Demo Sales CrMemo Approvals");
    end;

    local procedure CreateSalesCreditMemo(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, '', LibraryRandom.RandInt(100));
    end;

    local procedure CreateSalesCreditMemoWithLine(var SalesHeader: Record "Sales Header"; Amount: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", '');
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

    local procedure SendSalesCreditMemoForApproval(var SalesHeader: Record "Sales Header")
    var
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        SalesCreditMemo.OpenView();
        SalesCreditMemo.GotoRecord(SalesHeader);
        SalesCreditMemo.SendApprovalRequest.Invoke();
        SalesCreditMemo.Close();
    end;

    local procedure RegetSalesDocument(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.SetRecFilter();
        SalesHeader.FindFirst();
    end;

    local procedure VerifySalesCreditMemoIsReleased(var SalesHeader: Record "Sales Header")
    begin
        RegetSalesDocument(SalesHeader);
        SalesHeader.TestField(Status, SalesHeader.Status::Released);
    end;

    local procedure VerifySalesCreditMemoIsOpen(var SalesHeader: Record "Sales Header")
    begin
        RegetSalesDocument(SalesHeader);
        SalesHeader.TestField(Status, SalesHeader.Status::Open);
    end;

    local procedure VerifySalesCreditMemoIsPendingApproval(var SalesHeader: Record "Sales Header")
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

    local procedure ApproveSalesCreditMemo(var SalesHeader: Record "Sales Header")
    var
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        SalesCreditMemo.OpenView();
        SalesCreditMemo.GotoRecord(SalesHeader);
        SalesCreditMemo.Approve.Invoke();
        SalesCreditMemo.Close();
    end;

    local procedure RejectSalesCreditMemo(var SalesHeader: Record "Sales Header")
    var
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        SalesCreditMemo.OpenView();
        SalesCreditMemo.GotoRecord(SalesHeader);
        SalesCreditMemo.Reject.Invoke();
        SalesCreditMemo.Close();
    end;

    local procedure DelegateSalesCreditMemo(var SalesHeader: Record "Sales Header")
    var
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        SalesCreditMemo.OpenView();
        SalesCreditMemo.GotoRecord(SalesHeader);
        SalesCreditMemo.Delegate.Invoke();
        SalesCreditMemo.Close();
    end;

    local procedure CancelSalesCreditMemo(var SalesHeader: Record "Sales Header")
    var
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        SalesCreditMemo.OpenView();
        SalesCreditMemo.GotoRecord(SalesHeader);
        SalesCreditMemo.CancelApprovalRequest.Invoke();
        SalesCreditMemo.Close();
    end;

    local procedure SetSalesDocSalespersonCode(SalesHeader: Record "Sales Header"; SalespersonCode: Code[20])
    begin
        SalesHeader.Validate("Salesperson Code", SalespersonCode);
        SalesHeader.Modify(true);
    end;

    local procedure CheckCommentsForDocumentOnDocumentCard(SalesHeader: Record "Sales Header"; NumberOfExpectedComments: Integer; CommentActionIsVisible: Boolean)
    var
        ApprovalComments: TestPage "Approval Comments";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        NumberOfComments: Integer;
    begin
        ApprovalComments.Trap();

        SalesCreditMemo.OpenView();
        SalesCreditMemo.GotoRecord(SalesHeader);

        Assert.AreEqual(CommentActionIsVisible, SalesCreditMemo.Comment.Visible(), 'The Comments action has the wrong visibility');

        if CommentActionIsVisible then begin
            SalesCreditMemo.Comment.Invoke();
            if ApprovalComments.First() then
                repeat
                    NumberOfComments += 1;
                until ApprovalComments.Next();
            Assert.AreEqual(NumberOfExpectedComments, NumberOfComments, 'The page contains the wrong number of comments');

            ApprovalComments.Comment.SetValue('Test Comment' + Format(NumberOfExpectedComments));
            ApprovalComments.Next();
            ApprovalComments.Close();
        end;

        SalesCreditMemo.Close();
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
        SalesCreditMemo: TestPage "Sales Credit Memo";
        SalesCreditMemos: TestPage "Sales Credit Memos";
    begin
        SalesCreditMemo.OpenView();
        SalesCreditMemo.GotoRecord(SalesHeader);
        Assert.AreEqual(CancelActionExpectedEnabled, SalesCreditMemo.CancelApprovalRequest.Enabled(), 'Wrong state for the Cancel action');
        SalesCreditMemo.Close();

        SalesCreditMemos.OpenView();
        SalesCreditMemos.GotoRecord(SalesHeader);
        Assert.AreEqual(CancelActionExpectedEnabled, SalesCreditMemos.CancelApprovalRequest.Enabled(), 'Wrong state for the Cancel action');
        SalesCreditMemos.Close();
    end;
}

