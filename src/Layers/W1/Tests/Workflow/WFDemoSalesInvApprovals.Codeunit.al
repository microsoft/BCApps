codeunit 134170 "WF Demo Sales Inv. Approvals"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Workflow] [Approval] [Sales] [Invoice]
    end;

    var
        Workflow: Record Workflow;
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
        PostRestrictionErr: Label 'You cannot use %1 for this action.', Comment = 'You cannot use Sales Header 10000 for this action.';
        RecordIsRestrictedErr: Label 'You cannot use %1 for this action.', Comment = '%1=Record Id';
        ApprovalShouldBeHandledErr: Label 'The approval process must be cancelled or completed to reopen this document.';
        InvoiceDiscExpectedErr: Label 'Validation error for Field: Invoice Disc. Pct.,  Message = Status must be equal to Open  in Sales Header: Document Type=Invoice, No.=%1. Current value is Pending Approval';
        LibraryJobQueue: Codeunit "Library - Job Queue";
        WorkflowSetup: Codeunit "Workflow Setup";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure CannotReleaseSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        WorkflowSetup: Codeunit "Workflow Setup";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [SCENARIO] The user cannot release a Sales invoice when the approval workflow is enabled and the Sales invoice is not approved.
        // [GIVEN] There is a Sales invoice that is not approved.
        // [GIVEN] The approval workflow for puchase invoices is enabled.
        // [WHEN] The user wants to Release the Sales invoice.
        // [THEN] The user will get an error that he cannot release a Sales invoice that is not approved.

        // Setup
        Initialize();

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesInvoiceApprovalWorkflowCode());

        LibrarySales.CreateSalesInvoice(SalesHeader);

        // Exercise
        SalesInvoice.OpenView();
        SalesInvoice.GotoRecord(SalesHeader);
        asserterror SalesInvoice.Release.Invoke();

        // Verify
        Assert.ExpectedError(DocCannotBeReleasedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotPostSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        WorkflowSetup: Codeunit "Workflow Setup";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [SCENARIO] The user cannot post a Sales invoice when the approval workflow is enabled and the Sales invoice is not approved and released.
        // [GIVEN] There is a Sales invoice that is not approved and released.
        // [GIVEN] The approval workflow for puchase invoices is enabled.
        // [WHEN] The user wants to Post the Sales invoice.
        // [THEN] The user will get an error that he cannot post a Sales invoice that is not approved and released.

        // Setup
        Initialize();

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesInvoiceApprovalWorkflowCode());

        LibrarySales.CreateSalesInvoice(SalesHeader);

        // Exercise
        SalesInvoice.OpenView();
        SalesInvoice.GotoRecord(SalesHeader);
        asserterror SalesInvoice.Post.Invoke();

        // Verify
        Assert.ExpectedError(StrSubstNo(DocCannotBePostedErr, SalesHeader."Document Type", SalesHeader."No."));
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure SalesInvoiceCannotBePostedWhenDocIsPendingApproval()
    var
        ApprovalEntry: Record "Approval Entry";
        SalesHeader: Record "Sales Header";
        CurrentUserSetup: Record "User Setup";
        ApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
        ErrorMessagesPage: TestPage "Error Messages";
    begin
        // [SCENARIO] This test that an user cannot post a Sales Invoice after it was sent for approval.
        Initialize();

        // [GIVEN] Sales Invoice Approval Workflow that has Approver code as the approver and Direct Approver as the limit type.
        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.SalesInvoiceApprovalWorkflowCode());
        LibraryWorkflow.SetWorkflowDirectApprover(Workflow.Code);
        LibraryWorkflow.EnableWorkflow(Workflow);

        // Setup - Create 2 usersetups
        LibraryDocumentApprovals.CreateOrFindUserSetup(CurrentUserSetup, UserId);
        LibraryDocumentApprovals.CreateMockupUserSetup(ApproverUserSetup);

        // Setup - Direct approver
        LibraryDocumentApprovals.SetApprover(CurrentUserSetup, ApproverUserSetup);

        // Setup - Create Sales invoice
        CreateSalesInvWithLine(SalesHeader, LibraryRandom.RandInt(5000));

        // Setup - Update Salesperson Code
        SetSalesDocSalespersonCode(SalesHeader, ApproverUserSetup."Salespers./Purch. Code");

        // [WHEN] Sales Invoice is sent for approval.
        SendSalesInvoiceForApproval(SalesHeader);

        // Verify - Sales invoice status is set to Pending Approval
        VerifySalesInvIsPendingApproval(SalesHeader);

        // [THEN] Approval Request is created for the Approver.
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
        Assert.AreEqual(1, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, CurrentUserSetup."User ID");
        VerifyApprovalEntryApproverID(ApprovalEntry, ApproverUserSetup."User ID");

        // [WHEN] The user wants to post the Sales Invoice.
        Commit();
        ErrorMessagesPage.Trap();
        PostSalesInvoice(SalesHeader);

        // [THEN] The error message list is shown to the user and the Sales Invoice is not posted.
        Assert.ExpectedMessage(
          StrSubstNo(PostRestrictionErr, Format(SalesHeader.RecordId, 0, 1)),
          ErrorMessagesPage.Description.Value);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CannotReleaseSalesInvoiceApprovalIsPending()
    var
        Workflow: Record Workflow;
        SalesHeader: Record "Sales Header";
        IntermediateApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [SCENARIO] The user cannot release a sales invoice when the approval workflow is enabled and the sales invoice is pending approval.
        // [GIVEN] There is a sales invoice that is sent for approval.
        // [GIVEN] The approval workflow for sales invoices is enabled.
        // [WHEN] The user wants to Release the sales invoice.
        // [THEN] The user will get an error that he cannot release the sales invoice that is not approved.

        // Setup
        Initialize();
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesInvoiceApprovalWorkflowCode());

        // Setup - Create 3 approval usersetups
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        // Setup - Create Sales Person code for sales invoice
        CreateSalesInvWithLine(SalesHeader, LibraryRandom.RandInt(5000));

        // Setup - Update  Code
        SetSalesDocSalespersonCode(SalesHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        // Excercise - Open sales invoice card and sent it for approval
        SendSalesInvoiceForApproval(SalesHeader);

        // Verify - Sales invoice status is set to Pending Approval
        VerifySalesInvIsPendingApproval(SalesHeader);

        // Exercise
        Commit();
        SalesInvoice.OpenView();
        SalesInvoice.GotoRecord(SalesHeader);
        asserterror SalesInvoice.Release.Invoke();

        // Verify
        Assert.ExpectedError(StrSubstNo(RecordIsRestrictedErr, Format(SalesHeader.RecordId, 0, 1)));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CannotReopenSalesInvoiceApprovalIsPending()
    var
        Workflow: Record Workflow;
        SalesHeader: Record "Sales Header";
        IntermediateApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [SCENARIO] The user cannot release a sales invoice when the approval workflow is enabled and the sales invoice is pending approval.
        // [GIVEN] There is a sales invoice that is sent for approval.
        // [GIVEN] The approval workflow for sales invoices is enabled.
        // [WHEN] The user wants to Reopen the sales invoice.
        // [THEN] The user will get an error that he cannot reopen the sales invoice.

        // Setup
        Initialize();
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesInvoiceApprovalWorkflowCode());

        // Setup - Create 3 approval usersetups
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        // Setup - Create sales invoice
        CreateSalesInvWithLine(SalesHeader, LibraryRandom.RandInt(5000));

        // Setup - Update Sales person Code
        SetSalesDocSalespersonCode(SalesHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        // Excercise - Open sales invoice card and sent it for approval
        SendSalesInvoiceForApproval(SalesHeader);

        // Verify - Sales invoice status is set to Pending Approval
        VerifySalesInvIsPendingApproval(SalesHeader);

        // Exercise
        SalesInvoice.OpenView();
        SalesInvoice.GotoRecord(SalesHeader);
        asserterror SalesInvoice.Reopen.Invoke();

        // Verify
        Assert.ExpectedError(ApprovalShouldBeHandledErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceApprovalWorkflowOnApprovePath()
    var
        ApprovalEntry: Record "Approval Entry";
        SalesHeader: Record "Sales Header";
        IntermediateApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [SCENARIO] This test verifies E2E scenario for the Sales invoice approval workflow on approval path.
        // [GIVEN] Sales Invoice Approval Workflow that has Salesperson as the approver and No Limit as the limit type.
        // [WHEN] Sales Invoice is sent for approval.
        // [THEN] Approval Request is created for the Salesperson.
        // [WHEN] Salesperson approves the approval request.
        // [THEN] Sales Invoice is released.

        Initialize();

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesInvoiceApprovalWorkflowCode());

        // Setup - Create 3 approval usersetups
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        // Setup - Create Sales invoice
        CreateSalesInvWithLine(SalesHeader, LibraryRandom.RandInt(5000));

        // Setup - Update Salesperson Code
        SetSalesDocSalespersonCode(SalesHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        // Excercise - Open Sales invoice card and sent it for approval
        SendSalesInvoiceForApproval(SalesHeader);

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
        ApprovalEntry: Record "Approval Entry";
        SalesHeader: Record "Sales Header";
        IntermediateApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [SCENARIO] This test verifies E2E scenario for the Sales invoice approval workflow on rejection path.
        // [GIVEN] Sales Invoice Approval Workflow that has Salesperson as the approver and No Limit as the limit type.
        // [WHEN] Sales Invoice is sent for approval.
        // [THEN] Approval Request is created for the Salesperson.
        // [WHEN] Salesperson rejects the approval request.
        // [THEN] Sales Invoice is reopened and approval entries are marked as rejected.

        Initialize();

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesInvoiceApprovalWorkflowCode());

        // Setup - Create 3 approval usersetups
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        // Setup - Create Sales invoice
        CreateSalesInvWithLine(SalesHeader, LibraryRandom.RandInt(5000));

        // Setup - Update Salesperson Code
        SetSalesDocSalespersonCode(SalesHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        // Excercise - Open Sales invoice card and sent it for approval
        SendSalesInvoiceForApproval(SalesHeader);

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
        ApprovalEntry: Record "Approval Entry";
        SalesHeader: Record "Sales Header";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
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

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesInvoiceApprovalWorkflowCode());

        // Setup - Create 3 usersetups
        LibraryDocumentApprovals.CreateOrFindUserSetup(CurrentUserSetup, UserId);
        LibraryDocumentApprovals.CreateMockupUserSetup(IntermediateApproverUserSetup);
        LibraryDocumentApprovals.CreateMockupUserSetup(FinalApproverUserSetup);

        // Setup - Chain of approvers
        LibraryDocumentApprovals.SetApprover(CurrentUserSetup, IntermediateApproverUserSetup);
        LibraryDocumentApprovals.SetApprover(IntermediateApproverUserSetup, FinalApproverUserSetup);
        LibraryDocumentApprovals.SetSubstitute(CurrentUserSetup, FinalApproverUserSetup);

        // Setup - Create Sales invoice
        CreateSalesInvWithLine(SalesHeader, LibraryRandom.RandInt(5000));

        // Setup - Update Salesperson Code
        SetSalesDocSalespersonCode(SalesHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        // Excercise - Open Sales invoice card and sent it for approval
        SendSalesInvoiceForApproval(SalesHeader);

        // Verify - Sales invoice status is set to Pending Approval
        VerifySalesInvIsPendingApproval(SalesHeader);

        // Verify - Approval requests and their data
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
        Assert.AreEqual(1, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, CurrentUserSetup."User ID");
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
        VerifyApprovalEntryApproverID(ApprovalEntry, FinalApproverUserSetup."User ID");

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
        ApprovalEntry: Record "Approval Entry";
        SalesHeader: Record "Sales Header";
        IntermediateApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [SCENARIO] This test verifies E2E scenario for the Sales invoice approval workflow on cancellation path.
        // [GIVEN] Sales Invoice Approval Workflow that has Salesperson as the approver and No Limit as the limit type.
        // [WHEN] Sales Invoice is sent for approval.
        // [THEN] Approval Request is created for the Salesperson.
        // [WHEN] Sender cancels the approval request.
        // [THEN] Sales Invoice is opend and approval requests are marked as cancelled.

        Initialize();

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesInvoiceApprovalWorkflowCode());

        // Setup - Create 3 approval usersetups
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        // Setup - Create Sales invoice
        CreateSalesInvWithLine(SalesHeader, LibraryRandom.RandInt(5000));

        // Setup - Update Salesperson Code
        SetSalesDocSalespersonCode(SalesHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        // Excercise - Open Sales invoice card and sent it for approval
        SendSalesInvoiceForApproval(SalesHeader);

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
    [HandlerFunctions('MessageHandlerValidateMessage')]
    [Scope('OnPrem')]
    procedure SalesInvoiceApprovalActionsVisibilityOnCardTest()
    var
        SalesHeader: Record "Sales Header";
        Workflow: Record Workflow;
        ApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [SCENARIO 3] Approval action availability.
        // [GIVEN] SalesHeader approval disabled.
        Initialize();

        // [WHEN] SalesHeader card is opened.
        LibrarySales.CreateSalesInvoice(SalesHeader);
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
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesInvoiceApprovalWorkflowCode());

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

        // [THEN] Only Cancel is enabled.
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
    procedure SalesInvoiceApprovalActionsVisibilityOnListTest()
    var
        SalesHeader: Record "Sales Header";
        Workflow: Record Workflow;
        ApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
        SalesInvoiceList: TestPage "Sales Invoice List";
    begin
        // [SCENARIO 3] Approval action availability.
        // [GIVEN] SalesHeader approval disabled.
        Initialize();

        // [WHEN] SalesHeader card is opened.
        LibrarySales.CreateSalesInvoice(SalesHeader);
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
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesInvoiceApprovalWorkflowCode());

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
        ApprovalEntry: Record "Approval Entry";
        SalesHeader: Record "Sales Header";
        IntermediateApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [SCENARIO] This test verifies E2E scenario for the Sales invoice approval workflow on approval path and adds a comment for each step.
        // [GIVEN] Sales Invoice Approval Workflow that has Salesperson as the approver and No Limit as the limit type.
        // [WHEN] Sales Invoice is sent for approval.
        // [THEN] Approval Request is created for the Salesperson and the user can add a comment.
        // [WHEN] Salesperson approves the approval request.
        // [THEN] Sales Invoice is released.

        Initialize();

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesInvoiceApprovalWorkflowCode());

        // Setup - Create 3 approval usersetups
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        // Setup - Create Sales invoice
        CreateSalesInvWithLine(SalesHeader, LibraryRandom.RandInt(5000));

        // Setup - Update Salesperson Code
        SetSalesDocSalespersonCode(SalesHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        CheckCommentsForDocumentOnDocumentCard(SalesHeader, 0, false);

        // Excercise - Open Sales invoice card and sent it for approval
        SendSalesInvoiceForApproval(SalesHeader);

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

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesInvoiceApprovalWorkflowCode());

        // Setup - Create 3 approval usersetups
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        // Setup - Create Sales invoice
        CreateSalesInvWithLine(SalesHeader, LibraryRandom.RandInt(5000));

        // Setup - Update Salesperson Code
        SetSalesDocSalespersonCode(SalesHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        // Excercise - Open Sales invoice card and sent it for approval
        SendSalesInvoiceForApproval(SalesHeader);

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

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithoutLinesCannotBeSentForAproval()
    var
        SalesHeader: Record "Sales Header";
        Workflow: Record Workflow;
        WorkflowSetup: Codeunit "Workflow Setup";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [SCENARIO] Approval action possible
        // [GIVEN] SalesHeader with no lines.
        Initialize();
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, '');
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesInvoiceApprovalWorkflowCode());

        Commit();
        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);

        // [WHEN] Send Approval Request is pushed.
        asserterror SalesInvoice.SendApprovalRequest.Invoke();

        // [THEN] Error is displayed.
        Assert.ExpectedError(NoWorkflowEnabledErr);

        // Cleanup
        SalesInvoice.Close();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CannotPostSalesInvoiceWhileSalesInvoiceCreditLimitApprovalWorkflowIsInProgress()
    var
        SalesHeader: Record "Sales Header";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        // [SCENARIO 271614] One cannot post Sales Invoice while Sales Invoice Credit Limit Approval Workflow was instantinated.
        Initialize();

        // [GIVEN] User with direct approver.
        // [GIVEN] Sales Invoice Credit Limit Approval workflow enabled.
        PrepareSalesInvoiceCreditLimitWorkflowWithUsers();

        // [GIVEN] Customer with credit limit = 1
        // [GIVEN] Sales Invoice with a line with Amount = 100.
        CreateCustomerWithCreditLimitWithSalesInvoice(SalesHeader);

        // [GIVEN] Sales Invoice is sent for approval.
        ApprovalsMgmt.CheckSalesApprovalPossible(SalesHeader);
        ApprovalsMgmt.OnSendSalesDocForApproval(SalesHeader);
        SalesHeader.Find();
        SalesHeader.TestField(Status, SalesHeader.Status::"Pending Approval");

        // [WHEN] Post Sales Invoice before approval request is approved/cancelled/rejected.
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Sales Invoice cannot be posted
        Assert.ExpectedError(StrSubstNo(PostRestrictionErr, Format(SalesHeader.RecordId, 0, 1)));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceAfterSalesInvoiceCreditLimitWorkflowIsCompleted()
    var
        SalesHeader: Record "Sales Header";
        ApprovalEntry: Record "Approval Entry";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        RestrictedRecord: Record "Restricted Record";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        // [SCENARIO 271614] One can post Sales Invoice after Sales Invoice Credit Limit Approval Workflow was completed.
        Initialize();
        RestrictedRecord.DeleteAll();

        // [GIVEN] User with direct approver.
        // [GIVEN] Sales Invoice Credit Limit Approval Workflow.
        PrepareSalesInvoiceCreditLimitWorkflowWithUsers();

        // [GIVEN] Customer with credit limit = 1.
        // [GIVEN] Sales Invoice with a line with Amount = 100.
        CreateCustomerWithCreditLimitWithSalesInvoice(SalesHeader);

        // [GIVEN] Sales Invoice is sent for approval.
        ApprovalsMgmt.OnSendSalesDocForApproval(SalesHeader);

        // [GIVEN] Sales Invoice is approved.
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(SalesHeader.RecordId);
        ApprovalsMgmt.ApproveRecordApprovalRequest(SalesHeader.RecordId);
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
        ApprovalEntry.TestField(Status, ApprovalEntry.Status::Approved);

        // [WHEN] Post Sales Invoice.
        SalesHeader.Find();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Sales Invoice is posted.
        SalesInvoiceHeader.SetRange("Pre-Assigned No.", SalesHeader."No.");
        Assert.RecordIsNotEmpty(SalesInvoiceHeader);

        // [THEN] There are no restricted records.
        Assert.RecordIsEmpty(RestrictedRecord);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure CheckSalesInvoiceDiscountFieldDisableifSalesInvoiceWorkflowIsEnabled()
    var
        ApprovalEntry: Record "Approval Entry";
        ApproverUserSetup: Record "User Setup";
        CurrentUserSetup: Record "User Setup";
        SalesHeader: Record "Sales Header";
        Workflow: Record Workflow;
        SalesInvoicePage: TestPage "Sales Invoice";
        ErrorText: Text;
    begin
        // [SCENARIO 578451] Invoice Discount can be modified without restrictions after sending the 
        // approval request and with Pending Approval status in the document.
        Initialize();

        // [GIVEN] Create User Setup.
        CreateUserSetupWithAdminApproval();

        // [GIVEN] Sales Invoice Approval Workflow that has Approver code as the approver and Direct Approver as the limit type.
        clear(WorkflowSetup);
        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.SalesInvoiceApprovalWorkflowCode());
        LibraryWorkflow.SetWorkflowChainApprover(Workflow.Code);
        LibraryWorkflow.EnableWorkflow(Workflow);

        // [GIVEN] Setup - Create 2 usersetups
        LibraryDocumentApprovals.CreateOrFindUserSetup(CurrentUserSetup, UserId());
        LibraryDocumentApprovals.CreateMockupUserSetup(ApproverUserSetup);

        // [GIVEN] Setup - Direct approver
        LibraryDocumentApprovals.SetApprover(CurrentUserSetup, ApproverUserSetup);

        // [GIVEN] Setup - Create Sales invoice
        CreateSalesInvWithLine(SalesHeader, LibraryRandom.RandInt(5000));

        // [WHEN] Sales Invoice is sent for approval.
        SendSalesInvoiceForApproval(SalesHeader);

        // [WHEN] Verify - Sales invoice status is set to Pending Approval
        VerifySalesInvIsPendingApproval(SalesHeader);

        // [THEN] Approval Request is created for the Approver.
        GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
        Assert.AreEqual(1, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        // [THEN] Verify Approval Entry is Open, Verify Approval Entry SenderID, Verify Approval Entry ApproverID.
        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, CurrentUserSetup."User ID");
        VerifyApprovalEntryApproverID(ApprovalEntry, ApproverUserSetup."User ID");

        // [THEN] Verify ExpectedError.
        SalesInvoicePage.OpenEdit();
        SalesInvoicePage.FILTER.SetFilter("No.", SalesHeader."No.");
        asserterror SalesInvoicePage.SalesLines."Invoice Disc. Pct.".Value(Format(10));
        ErrorText := GetLastErrorText();
        assert.Equal(StrSubstNo(InvoiceDiscExpectedErr, SalesHeader."No."), ErrorText);
    end;

    local procedure Initialize()
    var
        UserSetup: Record "User Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"WF Demo Sales Inv. Approvals");
        LibraryVariableStorage.Clear();
        UserSetup.DeleteAll();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryWorkflow.DisableAllWorkflows();
        Commit();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"WF Demo Sales Inv. Approvals");
        IsInitialized := true;
        BindSubscription(LibraryJobQueue);
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"WF Demo Sales Inv. Approvals");
    end;

    local procedure CreateCustomerWithCreditLimitWithSalesInvoice(var SalesHeader: Record "Sales Header")
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Credit Limit (LCY)", LibraryRandom.RandInt(3));
        Customer.Modify(true);
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader, Customer."No.");
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

    local procedure PostSalesInvoice(var SalesHeader: Record "Sales Header")
    var
        SalesInvoice: TestPage "Sales Invoice";
    begin
        SalesInvoice.OpenView();
        SalesInvoice.GotoRecord(SalesHeader);
        SalesInvoice.Post.Invoke();
        SalesInvoice.Close();
    end;

    local procedure PrepareSalesInvoiceCreditLimitWorkflowWithUsers()
    var
        UserSetup: Record "User Setup";
        Workflow: Record Workflow;
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        LibraryDocumentApprovals.SetupUserWithApprover(UserSetup);

        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.SalesInvoiceCreditLimitApprovalWorkflowCode());
        LibraryWorkflow.SetWorkflowDirectApprover(Workflow.Code);
        LibraryWorkflow.EnableWorkflow(Workflow);
    end;

    local procedure RegetSalesDocument(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.SetRecFilter();
        SalesHeader.FindFirst();
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

    local procedure GetApprovalEntries(var ApprovalEntry: Record "Approval Entry"; RecordID: RecordID)
    begin
        ApprovalEntry.SetRange("Record ID to Approve", RecordID);
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Open);
        ApprovalEntry.FindSet();
    end;

    local procedure CreateUserSetupWithAdminApproval()
    var
        UserSetup: Record "User Setup";
    begin
        if Not UserSetup.Get(UserId()) then
            LibraryDocumentApprovals.CreateUserSetupWithEmail(UserSetup, CopyStr(UserId(), 1, 50), '', CopyStr(RandomEmail(), 1, MaxStrLen(UserSetup."E-Mail")));
        UserSetup."Approval Administrator" := true;
        UserSetup.Modify(true);
    end;

    local procedure RandomEmail(): Text[250]
    begin
        exit(StrSubstNo('%1@contoso.com', CreateGuid()));
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandlerValidateMessage(Message: Text[1024])
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Message)
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Qustion: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Dummy message handler.
    end;
}

