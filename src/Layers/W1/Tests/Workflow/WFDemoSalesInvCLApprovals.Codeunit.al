codeunit 134176 "WF Demo SalesInv CL Approvals"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Workflow] [Approval] [Sales] [Invoice]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
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
        LibraryJobQueue: Codeunit "Library - Job Queue";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure CannotPostSalesInvoice()
    var
        Workflow: Record Workflow;
        SalesHeader: Record "Sales Header";
        WorkflowSetup: Codeunit "Workflow Setup";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [SCENARIO] The user cannot post a Sales invoice when the credit limit approval workflow is enabled and the Sales invoice is not approved and released.
        // [GIVEN] There is a Sales invoice that is not approved and released.
        // [GIVEN] The credit limit approval workflow for sales invoices is enabled.
        // [WHEN] The user wants to Post the Sales invoice.
        // [THEN] The user will get an error that he cannot post a Sales invoice that is not approved and released.

        // Setup
        Initialize();
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesInvoiceCreditLimitApprovalWorkflowCode());

        LibrarySales.CreateSalesInvoice(SalesHeader);

        // Exercise
        SalesInvoice.OpenView();
        SalesInvoice.GotoRecord(SalesHeader);
        asserterror SalesInvoice.Post.Invoke();

        // Verify
        Assert.ExpectedError(StrSubstNo(DocCannotBePostedErr, SalesHeader."Document Type", SalesHeader."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotReleaseSalesInvoice()
    var
        Workflow: Record Workflow;
        SalesHeader: Record "Sales Header";
        WorkflowSetup: Codeunit "Workflow Setup";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [SCENARIO] The user cannot release a Sales invoice when the credit limit approval workflow is enabled and the Sales invoice is not approved.
        // [GIVEN] There is a Sales invoice that is not approved.
        // [GIVEN] The credit limit approval workflow for sales invoices is enabled.
        // [WHEN] The user wants to Release the Sales invoice.
        // [THEN] The user will get an error that he cannot release a Sales invoice that is not approved.

        // Setup
        Initialize();
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesInvoiceCreditLimitApprovalWorkflowCode());

        LibrarySales.CreateSalesInvoice(SalesHeader);

        // Exercise
        SalesInvoice.OpenView();
        SalesInvoice.GotoRecord(SalesHeader);
        asserterror SalesInvoice.Release.Invoke();

        // Verify
        Assert.ExpectedError(DocCannotBeReleasedErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceApprovalWorkflowOnApprovePath()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        SalesHeader: Record "Sales Header";
        IntermediateApproverUserSetup: Record "User Setup";
        LineAmount: Integer;
    begin
        // [SCENARIO] This test verifies E2E scenario for the Sales invoice approval workflow on approval path.
        // [GIVEN] Sales Invoice Approval Workflow that has Salesperson as the approver and No Limit as the limit type.
        // [WHEN] Sales Invoice is sent for approval.
        // [THEN] Approval Request is created for the Salesperson.
        // [WHEN] Salesperson approves the approval request.
        // [THEN] Sales Invoice is released.

        Initialize();

        SendDocForApproval(Workflow, SalesHeader, IntermediateApproverUserSetup, LineAmount);

        // Verify - Sales invoice status is set to Pending Approval
        VerifySalesInvIsPendingApproval(SalesHeader);

        // Verify - Approval requests and their data
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
        Assert.AreEqual(1, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, UserId);
        VerifyApprovalEntryApproverID(ApprovalEntry, IntermediateApproverUserSetup."User ID");

        // Setup - Assign the approval entry to current user so that it can be approved
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(SalesHeader.RecordId);

        // Excercise - Open Sales invoice card and approve the approval request
        ApproveSalesInvoice(SalesHeader);

        // Verify - Approval requests and their data
        VerifySalesInvIsReleased(SalesHeader);
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
        VerifyApprovalEntryIsApproved(ApprovalEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceApprovalWorkflowOnRejectionPath()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        SalesHeader: Record "Sales Header";
        IntermediateApproverUserSetup: Record "User Setup";
        LineAmount: Integer;
    begin
        // [SCENARIO] This test verifies E2E scenario for the Sales invoice approval workflow on rejection path.
        // [GIVEN] Sales Invoice Approval Workflow that has Salesperson as the approver and No Limit as the limit type.
        // [WHEN] Sales Invoice is sent for approval.
        // [THEN] Approval Request is created for the Salesperson.
        // [WHEN] Salesperson rejects the approval request.
        // [THEN] Sales Invoice is reopened and approval entries are marked as rejected.

        Initialize();

        SendDocForApproval(Workflow, SalesHeader, IntermediateApproverUserSetup, LineAmount);

        // Verify - Sales invoice status is set to Pending Approval
        VerifySalesInvIsPendingApproval(SalesHeader);

        // Verify - Approval requests and their data
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
        Assert.AreEqual(1, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, UserId);
        VerifyApprovalEntryApproverID(ApprovalEntry, IntermediateApproverUserSetup."User ID");

        // Assign the approval entry to current user so that it can be approved
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(SalesHeader.RecordId);

        // Excercise - Open Sales invoice card and reject the approval request
        RejectSalesInvoice(SalesHeader);

        // Verify - Approval requests and their data
        VerifySalesInvIsOpen(SalesHeader);
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
        VerifyApprovalEntryIsRejected(ApprovalEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceApprovalWorkflowOnDelegationPath()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        SalesHeader: Record "Sales Header";
        IntermediateApproverUserSetup: Record "User Setup";
        LineAmount: Integer;
    begin
        // [SCENARIO] This test verifies E2E scenario for the Sales invoice approval workflow on delegation path.
        // [GIVEN] Sales Invoice Approval Workflow that has Salesperson as the approver and No Limit as the limit type.
        // [WHEN] Sales Invoice is sent for approval.
        // [THEN] Approval Request is created for the Salesperson.
        // [WHEN] Salesperson delegates the approval request.
        // [THEN] Approval request is assigned to the substitute.
        // [WHEN] Approval Request is approved.
        // [THEN] Sales Invoice is released.

        Initialize();

        SendDocForApproval(Workflow, SalesHeader, IntermediateApproverUserSetup, LineAmount);

        // Verify - Sales invoice status is set to Pending Approval
        VerifySalesInvIsPendingApproval(SalesHeader);

        // Verify - Approval requests and their data
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
        Assert.AreEqual(1, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, UserId);
        VerifyApprovalEntryApproverID(ApprovalEntry, IntermediateApproverUserSetup."User ID");

        // Assign the approval entry to current user so that it can be approved
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(SalesHeader.RecordId);

        // Excercise - Open Sales invoice card and delgate the approval request
        DelegateSalesInvoice(SalesHeader);

        // Verify - Approval requests and their data
        VerifySalesInvIsPendingApproval(SalesHeader);
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntryApproverID(ApprovalEntry, IntermediateApproverUserSetup."Approver ID");

        // Assign the approval entry to current user so that it can be approved
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(SalesHeader.RecordId);

        // Excercise - Open Sales invoice card and approve the approval request
        ApproveSalesInvoice(SalesHeader);

        // Verify - Approval requests and their data
        VerifySalesInvIsReleased(SalesHeader);
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
        VerifyApprovalEntryIsApproved(ApprovalEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceApprovalWorkflowOnCancellationPath()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        SalesHeader: Record "Sales Header";
        IntermediateApproverUserSetup: Record "User Setup";
        LineAmount: Integer;
    begin
        // [SCENARIO] This test verifies E2E scenario for the Sales invoice approval workflow on cancellation path.
        // [GIVEN] Sales Invoice Approval Workflow that has Salesperson as the approver and No Limit as the limit type.
        // [WHEN] Sales Invoice is sent for approval.
        // [THEN] Approval Request is created for the Salesperson.
        // [WHEN] Sender cancels the approval request.
        // [THEN] Sales Invoice is opend and approval requests are marked as cancelled.

        Initialize();

        SendDocForApproval(Workflow, SalesHeader, IntermediateApproverUserSetup, LineAmount);

        // Verify - Sales invoice status is set to Pending Approval
        VerifySalesInvIsPendingApproval(SalesHeader);

        // Verify - Approval requests and their data
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
        Assert.AreEqual(1, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, UserId);
        VerifyApprovalEntryApproverID(ApprovalEntry, IntermediateApproverUserSetup."User ID");

        // Excercise - Open Sales invoice card and cancel the approval request
        CancelSalesInvoice(SalesHeader);

        // Verify - Approval requests and their data
        VerifySalesInvIsOpen(SalesHeader);
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
        VerifyApprovalEntryIsCancelled(ApprovalEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceApprovalWorkflowOnAutoApprovalPath()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        SalesHeader: Record "Sales Header";
        CurrentUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
        LineAmount: Integer;
    begin
        // [SCENARIO] This test verifies E2E scenario for the Sales invoice approval workflow on auto-approval path.
        // [GIVEN] Sales Invoice Credit Limit Approval Workflow .
        // [WHEN] Sales Invoice is sent for approval.
        // [THEN] An approval entry is created and approved automatically.
        // [THEN] Sales Invoice is released.

        Initialize();

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesInvoiceCreditLimitApprovalWorkflowCode());

        // Setup - Create 3 usersetups
        LibraryDocumentApprovals.CreateOrFindUserSetup(CurrentUserSetup, UserId);

        // Setup - Create Sales invoice
        LineAmount := LibraryRandom.RandInt(5000);
        CreateSalesInvWithLine(SalesHeader, LineAmount);

        // Setup - Set Customer Credit Limit lower than Sales Invoice total amount
        SetCustomerCreditLimit(SalesHeader, LineAmount * 10);

        // Excercise - Open Sales invoice card and sent it for approval
        SendSalesInvoiceForApproval(SalesHeader);

        // Verify - Approval requests and their data
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
        Assert.AreEqual(1, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        VerifyApprovalEntryIsApproved(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, CurrentUserSetup."User ID");
        VerifyApprovalEntryApproverID(ApprovalEntry, CurrentUserSetup."User ID");
    end;

    [Test]
    [HandlerFunctions('MessageHandlerValidateMessage')]
    [Scope('OnPrem')]
    procedure TestSalesInvoiceApprovalActionsVisibilityOnCard()
    var
        SalesHeader: Record "Sales Header";
        Workflow: Record Workflow;
        ApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
        SalesInvoice: TestPage "Sales Invoice";
        LineAmount: Decimal;
    begin
        // [SCENARIO 3] Approval action availability.
        // [GIVEN] SalesHeader approval disabled.
        Initialize();

        // [WHEN] SalesHeader card is opened.
        LineAmount := LibraryRandom.RandInt(5000);
        CreateSalesInvWithLine(SalesHeader, LineAmount);
        SetCustomerCreditLimit(SalesHeader, LineAmount / 10);
        Commit();
        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(SalesInvoice.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(SalesInvoice.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should NOT be enabled');

        // [WHEN] Send Approval Request is pushed.
        asserterror SalesInvoice.SendApprovalRequest.Invoke();

        // [THEN] Error is displayed.
        Assert.ExpectedError(NoWorkflowEnabledErr);

        // Cleanup
        SalesInvoice.Close();

        // [GIVEN] SalesHeader approval enabled.
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesInvoiceCreditLimitApprovalWorkflowCode());

        // [WHEN] SalesHeader card is opened.
        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(SalesInvoice.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(SalesInvoice.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');
        Assert.IsFalse(SalesInvoice.Approve.Visible(), 'Approve should NOT be visible');
        Assert.IsFalse(SalesInvoice.Reject.Visible(), 'Reject should NOT be visible');
        Assert.IsFalse(SalesInvoice.Delegate.Visible(), 'Delegate should NOT be visible');
        SalesInvoice.Close();

        // [GIVEN] Approval exist on SalesHeader.
        LibraryDocumentApprovals.SetupUsersForApprovals(ApproverUserSetup);
        SetSalesDocSalespersonCode(SalesHeader, ApproverUserSetup."Salespers./Purch. Code");
        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);

        // [WHEN] SalesHeader send for approval.
        LibraryVariableStorage.Enqueue(ApprovalRequestSendMsg);
        SalesInvoice.SendApprovalRequest.Invoke();

        // [THEN] Only Send is enabled.
        Assert.IsFalse(SalesInvoice.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be disabled');
        Assert.IsTrue(SalesInvoice.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be enabled');

        // Clenup
        SalesInvoice.Close();

        // Setup the approval so it can be approve by current user
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(SalesHeader.RecordId);

        // [WHEN] SalesHeader card is opened.
        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);

        // [THEN] Approval action are shown.
        Assert.IsTrue(SalesInvoice.Approve.Visible(), 'Approva should be visible');
        Assert.IsTrue(SalesInvoice.Reject.Visible(), 'Reject should be visible');
        Assert.IsTrue(SalesInvoice.Delegate.Visible(), 'Delegate should be visible');
    end;

    [Test]
    [HandlerFunctions('MessageHandlerValidateMessage')]
    [Scope('OnPrem')]
    procedure TestSalesInvoiceApprovalActionsVisibilityOnList()
    var
        SalesHeader: Record "Sales Header";
        Workflow: Record Workflow;
        ApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
        SalesInvoiceList: TestPage "Sales Invoice List";
        LineAmount: Decimal;
    begin
        // [SCENARIO 3] Approval action availability.
        // [GIVEN] SalesHeader approval disabled.
        Initialize();

        // [WHEN] SalesHeader card is opened.
        LineAmount := LibraryRandom.RandInt(5000);
        CreateSalesInvWithLine(SalesHeader, LineAmount);
        SetCustomerCreditLimit(SalesHeader, LineAmount / 10);
        Commit();
        SalesInvoiceList.OpenEdit();
        SalesInvoiceList.GotoRecord(SalesHeader);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(SalesInvoiceList.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(SalesInvoiceList.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');

        // [WHEN] Send Approval Request is pushed.
        asserterror SalesInvoiceList.SendApprovalRequest.Invoke();

        // [THEN] Error is displayed.
        Assert.ExpectedError(NoWorkflowEnabledErr);

        // Cleanup
        SalesInvoiceList.Close();

        // [GIVEN] SalesHeader approval enabled.
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesInvoiceCreditLimitApprovalWorkflowCode());

        // [WHEN] SalesHeader card is opened.
        SalesInvoiceList.OpenEdit();
        SalesInvoiceList.GotoRecord(SalesHeader);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(SalesInvoiceList.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(SalesInvoiceList.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');
        SalesInvoiceList.Close();

        // [GIVEN] Approval exist on SalesHeader.
        LibraryDocumentApprovals.SetupUsersForApprovals(ApproverUserSetup);
        SetSalesDocSalespersonCode(SalesHeader, ApproverUserSetup."Salespers./Purch. Code");
        SalesInvoiceList.OpenEdit();
        SalesInvoiceList.GotoRecord(SalesHeader);

        // [WHEN] SalesHeader send for approval.
        LibraryVariableStorage.Enqueue(ApprovalRequestSendMsg);
        SalesInvoiceList.SendApprovalRequest.Invoke();

        // [THEN] Only Send is enabled.
        Assert.IsFalse(SalesInvoiceList.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be disabled');
        Assert.IsTrue(SalesInvoiceList.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be enabled');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceApprovalWorkflowApprovePathAddComments()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        SalesHeader: Record "Sales Header";
        IntermediateApproverUserSetup: Record "User Setup";
        LineAmount: Integer;
    begin
        // [SCENARIO] This test verifies E2E scenario for the Sales invoice approval workflow on approval path and adds a comment for each step.
        // [GIVEN] Sales Invoice Approval Workflow that has Salesperson as the approver and No Limit as the limit type.
        // [WHEN] Sales Invoice is sent for approval.
        // [THEN] Approval Request is created for the Salesperson and the user can add a comment.
        // [WHEN] Salesperson approves the approval request.
        // [THEN] Sales Invoice is released.

        Initialize();

        SendDocForApproval(Workflow, SalesHeader, IntermediateApproverUserSetup, LineAmount);

        CheckCommentsForDocumentOnDocumentCard(SalesHeader, 0, false);

        // Verify - Sales invoice status is set to Pending Approval
        VerifySalesInvIsPendingApproval(SalesHeader);

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
        ApproveSalesInvoice(SalesHeader);

        // Verify - Approval requests and their data
        VerifySalesInvIsReleased(SalesHeader);
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
        VerifyApprovalEntryIsApproved(ApprovalEntry);
        CheckCommentsForDocumentOnApprovalEntriesPage(ApprovalEntry, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceApprovalWorkflowTestUserCanCancel()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        SalesHeader: Record "Sales Header";
        IntermediateApproverUserSetup: Record "User Setup";
        UserSetup: Record "User Setup";
        LineAmount: Integer;
    begin
        // [SCENARIO] This test verifies E2E scenario for the Sales invoice approval workflow on cancellation path and whether a user can cancel the workflow or not.
        // [GIVEN] Sales Invoice Approval Workflow that has Salesperson as the approver and No Limit as the limit type.
        // [WHEN] Sales Invoice is sent for approval.
        // [THEN] Approval Request is created for the Salesperson and user can cancel the request.
        // [WHEN] Next approver opens the document.
        // [THEN] The user can only cancel the request if he is an approval administrator.

        Initialize();

        SendDocForApproval(Workflow, SalesHeader, IntermediateApproverUserSetup, LineAmount);

        // Verify - User can cancel the approval request
        CheckUserCanCancelTheApprovalRequest(SalesHeader, true);

        // Verify - Sales invoice status is set to Pending Approval
        VerifySalesInvIsPendingApproval(SalesHeader);

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
        CancelSalesInvoice(SalesHeader);

        // Verify - Approval requests and their data
        VerifySalesInvIsOpen(SalesHeader);
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
        VerifyApprovalEntryIsCancelled(ApprovalEntry);
    end;

    local procedure SendDocForApproval(var Workflow: Record Workflow; var SalesHeader: Record "Sales Header"; var IntermediateApproverUserSetup: Record "User Setup"; var LineAmount: Integer)
    var
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesInvoiceCreditLimitApprovalWorkflowCode());

        // Setup - Create 3 approval usersetups
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        // Setup - Create Sales invoice
        LineAmount := LibraryRandom.RandInt(5000);
        CreateSalesInvWithLine(SalesHeader, LineAmount);

        // Setup - Update Salesperson Code
        SetSalesDocSalespersonCode(SalesHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        // Setup - Set Customer Credit Limit lower than Sales Invoice total amount
        SetCustomerCreditLimit(SalesHeader, LineAmount / 10);

        // Excercise - Open Sales invoice card and sent it for approval
        SendSalesInvoiceForApproval(SalesHeader);
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
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"WF Demo SalesInv CL Approvals");
        LibraryVariableStorage.Clear();
        UserSetup.DeleteAll();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryWorkflow.DisableAllWorkflows();
        if IsInitialized then
            exit;
        IsInitialized := true;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"WF Demo SalesInv CL Approvals");
        BindSubscription(LibraryJobQueue);
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"WF Demo SalesInv CL Approvals");
    end;

    local procedure CreateSalesInvWithLine(var SalesHeader: Record "Sales Header"; Amount: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, '');
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

    local procedure SendSalesInvoiceForApproval(var SalesHeader: Record "Sales Header")
    var
        SalesInvoice: TestPage "Sales Invoice";
    begin
        SalesInvoice.OpenView();
        SalesInvoice.GotoRecord(SalesHeader);
        SalesInvoice.SendApprovalRequest.Invoke();
        SalesInvoice.Close();
    end;

    local procedure RegetSalesDocument(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.SetRecFilter();
        SalesHeader.FindFirst();
    end;

    local procedure VerifySalesInvIsReleased(var SalesHeader: Record "Sales Header")
    begin
        RegetSalesDocument(SalesHeader);
        SalesHeader.TestField(Status, SalesHeader.Status::Released);
    end;

    local procedure VerifySalesInvIsOpen(var SalesHeader: Record "Sales Header")
    begin
        RegetSalesDocument(SalesHeader);
        SalesHeader.TestField(Status, SalesHeader.Status::Open);
    end;

    local procedure VerifySalesInvIsPendingApproval(var SalesHeader: Record "Sales Header")
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

    local procedure ApproveSalesInvoice(var SalesHeader: Record "Sales Header")
    var
        SalesInvoice: TestPage "Sales Invoice";
    begin
        SalesInvoice.OpenView();
        SalesInvoice.GotoRecord(SalesHeader);
        SalesInvoice.Approve.Invoke();
        SalesInvoice.Close();
    end;

    local procedure RejectSalesInvoice(var SalesHeader: Record "Sales Header")
    var
        SalesInvoice: TestPage "Sales Invoice";
    begin
        SalesInvoice.OpenView();
        SalesInvoice.GotoRecord(SalesHeader);
        SalesInvoice.Reject.Invoke();
        SalesInvoice.Close();
    end;

    local procedure DelegateSalesInvoice(var SalesHeader: Record "Sales Header")
    var
        SalesInvoice: TestPage "Sales Invoice";
    begin
        SalesInvoice.OpenView();
        SalesInvoice.GotoRecord(SalesHeader);
        SalesInvoice.Delegate.Invoke();
        SalesInvoice.Close();
    end;

    local procedure CancelSalesInvoice(var SalesHeader: Record "Sales Header")
    var
        SalesInvoice: TestPage "Sales Invoice";
    begin
        SalesInvoice.OpenView();
        SalesInvoice.GotoRecord(SalesHeader);
        SalesInvoice.CancelApprovalRequest.Invoke();
        SalesInvoice.Close();
    end;

    local procedure SetSalesDocSalespersonCode(SalesHeader: Record "Sales Header"; SalespersonCode: Code[20])
    begin
        SalesHeader.Validate("Salesperson Code", SalespersonCode);
        SalesHeader.Modify(true);
    end;

    local procedure SetCustomerCreditLimit(SalesHeader: Record "Sales Header"; CreditLimit: Decimal)
    var
        Customer: Record Customer;
    begin
        if not Customer.Get(SalesHeader."Bill-to Customer No.") then
            Customer.Get(SalesHeader."Sell-to Customer No.");

        Customer."Credit Limit (LCY)" := CreditLimit;
        Customer.Modify(true);
    end;

    local procedure CheckCommentsForDocumentOnDocumentCard(SalesHeader: Record "Sales Header"; NumberOfExpectedComments: Integer; CommentActionIsVisible: Boolean)
    var
        ApprovalComments: TestPage "Approval Comments";
        SalesInvoice: TestPage "Sales Invoice";
        NumberOfComments: Integer;
    begin
        ApprovalComments.Trap();

        SalesInvoice.OpenView();
        SalesInvoice.GotoRecord(SalesHeader);

        Assert.AreEqual(CommentActionIsVisible, SalesInvoice.Comment.Visible(), 'The Comments action has the wrong visibility');

        if CommentActionIsVisible then begin
            SalesInvoice.Comment.Invoke();
            if ApprovalComments.First() then
                repeat
                    NumberOfComments += 1;
                until ApprovalComments.Next();
            Assert.AreEqual(NumberOfExpectedComments, NumberOfComments, 'The page contains the wrong number of comments');

            ApprovalComments.Comment.SetValue('Test Comment' + Format(NumberOfExpectedComments));
            ApprovalComments.Next();
            ApprovalComments.Close();
        end;

        SalesInvoice.Close();
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
        SalesInvoice: TestPage "Sales Invoice";
        SalesInvoiceList: TestPage "Sales Invoice List";
    begin
        SalesInvoice.OpenView();
        SalesInvoice.GotoRecord(SalesHeader);
        Assert.AreEqual(CancelActionExpectedEnabled, SalesInvoice.CancelApprovalRequest.Enabled(), 'Wrong state for the Cancel action');
        SalesInvoice.Close();

        SalesInvoiceList.OpenView();
        SalesInvoiceList.GotoRecord(SalesHeader);
        Assert.AreEqual(CancelActionExpectedEnabled, SalesInvoiceList.CancelApprovalRequest.Enabled(), 'Wrong state for the Cancel action');
        SalesInvoiceList.Close();
    end;
}

