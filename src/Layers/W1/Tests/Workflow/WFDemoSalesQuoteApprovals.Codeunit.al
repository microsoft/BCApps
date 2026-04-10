codeunit 134172 "WF Demo Sales Quote Approvals"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Workflow] [Approval] [Sales] [Quote]
    end;

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryERM: Codeunit "Library - ERM";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTemplates: Codeunit "Library - Templates";
        DocCannotBeMadeOrderErr: Label '%1 %2 must be approved and released before you can perform this action.', Comment = '%1 = PurchHeader."Document Type", %2 = PurchHeader."No."';
        DocCannotBeReleasedErr: Label 'This document can only be released when the approval process is complete.';
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
    procedure CannotMakeOrderOfSalesQuote()
    var
        Workflow: Record Workflow;
        SalesHeader: Record "Sales Header";
        WorkflowSetup: Codeunit "Workflow Setup";
        SalesQuotes: TestPage "Sales Quotes";
    begin
        // [SCENARIO] The user cannot make an order of a sales quote when the approval workflow is enabled and the sales quote is not approved and released.
        Initialize();

        // [GIVEN] The approval workflow for puchase quote is enabled.
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesQuoteApprovalWorkflowCode());

        // [GIVEN] There is a sales quote that is not approved and released.
        CreateSalesQuote(SalesHeader);

        // [WHEN] The user wants to Make Order of the sales quote.
        SalesQuotes.OpenView();
        SalesQuotes.GotoRecord(SalesHeader);
        asserterror SalesQuotes.MakeOrder.Invoke();

        // [THEN] The user will get an error that he cannot make an order of a sales quote that is not approved and released.
        Assert.ExpectedError(StrSubstNo(DocCannotBeMadeOrderErr, SalesHeader."Document Type", SalesHeader."No."));
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure CannotMakeOrderOfSalesQuotePendingApproval()
    var
        Workflow: Record Workflow;
        SalesHeader: Record "Sales Header";
        IntermediateApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
        SalesQuotes: TestPage "Sales Quotes";
    begin
        // [SCENARIO 378153] The user cannot make an order of a sales quote when the approval workflow is enabled and the sales quote is not approved
        Initialize();

        // [GIVEN] The approval workflow for puchase quote is enabled.
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesQuoteApprovalWorkflowCode());
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        // [GIVEN] The sales quote is created and sent to approval.
        CreateSalesQuote(SalesHeader);
        SetSalesDocSalespersonCode(SalesHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");
        SendSalesQuoteForApproval(SalesHeader);

        // [WHEN] The user wants to Make Order of the sales quote.
        SalesQuotes.OpenView();
        SalesQuotes.GotoRecord(SalesHeader);
        asserterror SalesQuotes.MakeOrder.Invoke();

        // [THEN] The user gets an error that he cannot use this action
        Assert.ExpectedError(StrSubstNo(RecordIsRestrictedErr, Format(SalesHeader.RecordId, 0, 1)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotReleaseSalesQuote()
    var
        Workflow: Record Workflow;
        SalesHeader: Record "Sales Header";
        WorkflowSetup: Codeunit "Workflow Setup";
        SalesQuote: TestPage "Sales Quote";
    begin
        // [SCENARIO] The user cannot release a Sales Quote when the approval workflow is enabled and the Sales Quote is not approved.
        // [GIVEN] There is a Sales Quote that is not approved.
        // [GIVEN] The approval workflow for puchase Quotes is enabled.
        // [WHEN] The user wants to Release the Sales Quote.
        // [THEN] The user will get an error that he cannot release a Sales Quote that is not approved.

        // Setup
        Initialize();
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesQuoteApprovalWorkflowCode());

        CreateSalesQuote(SalesHeader);

        // Exercise
        SalesQuote.OpenView();
        SalesQuote.GotoRecord(SalesHeader);
        asserterror SalesQuote.Release.Invoke();

        // Verify
        Assert.ExpectedError(DocCannotBeReleasedErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CannotReleaseSalesQuoteApprovalIsPending()
    var
        Workflow: Record Workflow;
        SalesHeader: Record "Sales Header";
        IntermediateApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
        SalesQuote: TestPage "Sales Quote";
    begin
        // [SCENARIO] The user cannot release a sales quote when the approval workflow is enabled and the sales quote is pending approval.
        // [GIVEN] There is a sales quote that is sent for approval.
        // [GIVEN] The approval workflow for sales quote is enabled.
        // [WHEN] The user wants to Release the sales quote.
        // [THEN] The user will get an error that he cannot release the sales quote that is not approved.

        // Setup
        Initialize();
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesQuoteApprovalWorkflowCode());

        // Setup - Create 3 approval usersetups
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        // Setup - Create Sales Person code for sales quote
        CreateSalesQuoteWithLine(SalesHeader, LibraryRandom.RandInt(5000));

        // Setup - Update  Code
        SetSalesDocSalespersonCode(SalesHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        // Excercise - Open sales quote card and sent it for approval
        SendSalesQuoteForApproval(SalesHeader);

        // Verify - Sales quote status is set to Pending Approval
        VerifySalesQuoteIsPendingApproval(SalesHeader);

        // Exercise
        Commit();
        SalesQuote.OpenView();
        SalesQuote.GotoRecord(SalesHeader);
        asserterror SalesQuote.Release.Invoke();

        // Verify
        Assert.ExpectedError(StrSubstNo(RecordIsRestrictedErr, Format(SalesHeader.RecordId, 0, 1)));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CannotReopenSalesQuoteApprovalIsPending()
    var
        Workflow: Record Workflow;
        SalesHeader: Record "Sales Header";
        IntermediateApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
        SalesQuote: TestPage "Sales Quote";
    begin
        // [SCENARIO] The user cannot release a sales quote when the approval workflow is enabled and the sales quote is pending approval.
        // [GIVEN] There is a sales quote that is sent for approval.
        // [GIVEN] The approval workflow for sales quote is enabled.
        // [WHEN] The user wants to Reopen the sales quote.
        // [THEN] The user will get an error that he cannot reopen the sales quote.

        // Setup
        Initialize();
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesQuoteApprovalWorkflowCode());

        // Setup - Create 3 approval usersetups
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        // Setup - Create sales quote
        CreateSalesQuoteWithLine(SalesHeader, LibraryRandom.RandInt(5000));

        // Setup - Update Sales person Code
        SetSalesDocSalespersonCode(SalesHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        // Excercise - Open sales quote card and sent it for approval
        SendSalesQuoteForApproval(SalesHeader);

        // Verify - Sales Quote status is set to Pending Approval
        VerifySalesQuoteIsPendingApproval(SalesHeader);

        // Exercise
        SalesQuote.OpenView();
        SalesQuote.GotoRecord(SalesHeader);
        asserterror SalesQuote.Reopen.Invoke();

        // Verify
        Assert.ExpectedError(ApprovalShouldBeHandledErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesQuoteApprovalWorkflowOnApprovePath()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        SalesHeader: Record "Sales Header";
        IntermediateApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [SCENARIO] This test verifies E2E scenario for the Sales Quote approval workflow on approval path.
        // [GIVEN] Sales Quote Approval Workflow that has Salesperson as the approver and No Limit as the limit type.
        // [WHEN] Sales Quote is sent for approval.
        // [THEN] Approval Request is created for the Salesperson.
        // [WHEN] Salesperson approves the approval request.
        // [THEN] Sales Quote is released.

        Initialize();

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesQuoteApprovalWorkflowCode());

        // Setup - Create 3 approval usersetups
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        // Setup - Create Sales Quote
        CreateSalesQuoteWithLine(SalesHeader, LibraryRandom.RandInt(5000));

        // Setup - Update Salesperson Code
        SetSalesDocSalespersonCode(SalesHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        // Excercise - Open Sales Quote card and sent it for approval
        SendSalesQuoteForApproval(SalesHeader);

        // Verify - Sales Quote status is set to Pending Approval
        VerifySalesQuoteIsPendingApproval(SalesHeader);

        // Verify - Approval requests and their data
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
        Assert.AreEqual(1, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, UserId);
        VerifyApprovalEntryApproverID(ApprovalEntry, IntermediateApproverUserSetup."User ID");

        // Setup - Assign the approval entry to current user so that it can be approved
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(SalesHeader.RecordId);

        // Excercise - Open Sales Quote card and approve the approval request
        ApproveSalesQuote(SalesHeader);

        // Verify - Approval requests and their data
        VerifySalesQuoteIsReleased(SalesHeader);
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
        VerifyApprovalEntryIsApproved(ApprovalEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesQuoteApprovalWorkflowOnRejectionPath()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        SalesHeader: Record "Sales Header";
        IntermediateApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [SCENARIO] This test verifies E2E scenario for the Sales Quote approval workflow on rejection path.
        // [GIVEN] Sales Quote Approval Workflow that has Salesperson as the approver and No Limit as the limit type.
        // [WHEN] Sales Quote is sent for approval.
        // [THEN] Approval Request is created for the Salesperson.
        // [WHEN] Salesperson rejects the approval request.
        // [THEN] Sales Quote is reopened and approval entries are marked as rejected.

        Initialize();
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesQuoteApprovalWorkflowCode());

        // Setup - Create 3 approval usersetups
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        // Setup - Create Sales Quote
        CreateSalesQuoteWithLine(SalesHeader, LibraryRandom.RandInt(5000));

        // Setup - Update Salesperson Code
        SetSalesDocSalespersonCode(SalesHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        // Excercise - Open Sales Quote card and sent it for approval
        SendSalesQuoteForApproval(SalesHeader);

        // Verify - Sales Quote status is set to Pending Approval
        VerifySalesQuoteIsPendingApproval(SalesHeader);

        // Verify - Approval requests and their data
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
        Assert.AreEqual(1, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, UserId);
        VerifyApprovalEntryApproverID(ApprovalEntry, IntermediateApproverUserSetup."User ID");

        // Assign the approval entry to current user so that it can be approved
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(SalesHeader.RecordId);

        // Excercise - Open Sales Quote card and reject the approval request
        RejectSalesQuote(SalesHeader);

        // Verify - Approval requests and their data
        VerifySalesQuoteIsOpen(SalesHeader);
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
        VerifyApprovalEntryIsRejected(ApprovalEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesQuoteApprovalWorkflowOnDelegationPath()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        SalesHeader: Record "Sales Header";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [SCENARIO] This test verifies E2E scenario for the Sales Quote approval workflow on delegation path.
        // [GIVEN] Sales Quote Approval Workflow that has Salesperson as the approver and No Limit as the limit type.
        // [WHEN] Sales Quote is sent for approval.
        // [THEN] Approval Request is created for the Salesperson.
        // [WHEN] Salesperson delegates the approval request.
        // [THEN] Approval request is assigned to the substitute.
        // [WHEN] Approval Request is approved.
        // [THEN] Sales Quote is released.

        Initialize();
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesQuoteApprovalWorkflowCode());

        // Setup - Create 3 usersetups
        LibraryDocumentApprovals.CreateOrFindUserSetup(CurrentUserSetup, UserId);
        LibraryDocumentApprovals.CreateMockupUserSetup(IntermediateApproverUserSetup);
        LibraryDocumentApprovals.CreateMockupUserSetup(FinalApproverUserSetup);

        // Setup - Chain of approvers
        LibraryDocumentApprovals.SetApprover(CurrentUserSetup, IntermediateApproverUserSetup);
        LibraryDocumentApprovals.SetApprover(IntermediateApproverUserSetup, FinalApproverUserSetup);
        LibraryDocumentApprovals.SetSubstitute(CurrentUserSetup, FinalApproverUserSetup);

        // Setup - Create Sales Quote
        CreateSalesQuoteWithLine(SalesHeader, LibraryRandom.RandInt(5000));

        // Setup - Update Salesperson Code
        SetSalesDocSalespersonCode(SalesHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        // Excercise - Open Sales Quote card and sent it for approval
        SendSalesQuoteForApproval(SalesHeader);

        // Verify - Sales Quote status is set to Pending Approval
        VerifySalesQuoteIsPendingApproval(SalesHeader);

        // Verify - Approval requests and their data
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
        Assert.AreEqual(1, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, CurrentUserSetup."User ID");
        VerifyApprovalEntryApproverID(ApprovalEntry, IntermediateApproverUserSetup."User ID");

        // Assign the approval entry to current user so that it can be approved
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(SalesHeader.RecordId);

        // Excercise - Open Sales Quote card and delgate the approval request
        DelegateSalesQuote(SalesHeader);

        // Verify - Approval requests and their data
        VerifySalesQuoteIsPendingApproval(SalesHeader);
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntryApproverID(ApprovalEntry, FinalApproverUserSetup."User ID");

        // Assign the approval entry to current user so that it can be approved
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(SalesHeader.RecordId);

        // Excercise - Open Sales Quote card and approve the approval request
        ApproveSalesQuote(SalesHeader);

        // Verify - Approval requests and their data
        VerifySalesQuoteIsReleased(SalesHeader);
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
        VerifyApprovalEntryIsApproved(ApprovalEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesQuoteApprovalWorkflowOnCancellationPath()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        SalesHeader: Record "Sales Header";
        IntermediateApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [SCENARIO] This test verifies E2E scenario for the Sales Quote approval workflow on cancellation path.
        // [GIVEN] Sales Quote Approval Workflow that has Salesperson as the approver and No Limit as the limit type.
        // [WHEN] Sales Quote is sent for approval.
        // [THEN] Approval Request is created for the Salesperson.
        // [WHEN] Sender cancels the approval request.
        // [THEN] Sales Quote is opend and approval requests are marked as cancelled.

        Initialize();
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesQuoteApprovalWorkflowCode());

        // Setup - Create 3 approval usersetups
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        // Setup - Create Sales Quote
        CreateSalesQuoteWithLine(SalesHeader, LibraryRandom.RandInt(5000));

        // Setup - Update Salesperson Code
        SetSalesDocSalespersonCode(SalesHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        // Excercise - Open Sales Quote card and sent it for approval
        SendSalesQuoteForApproval(SalesHeader);

        // Verify - Sales Quote status is set to Pending Approval
        VerifySalesQuoteIsPendingApproval(SalesHeader);

        // Verify - Approval requests and their data
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
        Assert.AreEqual(1, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, UserId);
        VerifyApprovalEntryApproverID(ApprovalEntry, IntermediateApproverUserSetup."User ID");

        // Excercise - Open Sales Quote card and cancel the approval request
        CancelSalesQuote(SalesHeader);

        // Verify - Approval requests and their data
        VerifySalesQuoteIsOpen(SalesHeader);
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
        VerifyApprovalEntryIsCancelled(ApprovalEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandlerValidateMessage')]
    [Scope('OnPrem')]
    procedure SalesQuoteApprovalActionsVisibilityOnCardTest()
    var
        SalesHeader: Record "Sales Header";
        Workflow: Record Workflow;
        ApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
        SalesQuote: TestPage "Sales Quote";
    begin
        // [SCENARIO 3] Approval action availability.
        // [GIVEN] SalesHeader approval disabled.
        Initialize();

        // [WHEN] SalesHeader card is opened.
        CreateSalesQuote(SalesHeader);
        Commit();
        SalesQuote.OpenEdit();
        SalesQuote.GotoRecord(SalesHeader);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(SalesQuote.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(SalesQuote.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should NOT be enabled');

        // [WHEN] Send Approval Request is pushed.
        asserterror SalesQuote.SendApprovalRequest.Invoke();

        // [THEN] Error is displayed.
        Assert.ExpectedError(NoWorkflowEnabledErr);

        // Cleanup
        SalesQuote.Close();

        // [GIVEN] SalesHeader approval enabled.
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesQuoteApprovalWorkflowCode());

        // [WHEN] SalesHeader card is opened.
        SalesQuote.OpenEdit();
        SalesQuote.GotoRecord(SalesHeader);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(SalesQuote.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(SalesQuote.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');
        Assert.IsFalse(SalesQuote.Approve.Visible(), 'Approve should NOT be visible');
        Assert.IsFalse(SalesQuote.Reject.Visible(), 'Reject should NOT be visible');
        Assert.IsFalse(SalesQuote.Delegate.Visible(), 'Delegate should NOT be visible');
        SalesQuote.Close();

        // [GIVEN] Approval exist on SalesHeader.
        LibraryDocumentApprovals.SetupUsersForApprovals(ApproverUserSetup);
        SetSalesDocSalespersonCode(SalesHeader, ApproverUserSetup."Salespers./Purch. Code");
        SalesQuote.OpenEdit();
        SalesQuote.GotoRecord(SalesHeader);

        // [WHEN] SalesHeader send for approval.
        LibraryVariableStorage.Enqueue(ApprovalRequestSendMsg);
        SalesQuote.SendApprovalRequest.Invoke();

        // [THEN] Only Send is enabled.
        Assert.IsFalse(SalesQuote.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be disabled');
        Assert.IsTrue(SalesQuote.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be enabled');

        // Clenup
        SalesQuote.Close();

        // Setup the approval so it can be approve by current user
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(SalesHeader.RecordId);

        // [WHEN] SalesHeader card is opened.
        SalesQuote.OpenEdit();
        SalesQuote.GotoRecord(SalesHeader);

        // [THEN] Approval action are shown.
        Assert.IsTrue(SalesQuote.Approve.Visible(), 'Approva should be visible');
        Assert.IsTrue(SalesQuote.Reject.Visible(), 'Reject should be visible');
        Assert.IsTrue(SalesQuote.Delegate.Visible(), 'Delegate should be visible');
    end;

    [Test]
    [HandlerFunctions('MessageHandlerValidateMessage')]
    [Scope('OnPrem')]
    procedure SalesQUoteApprovalActionsVisibilityOnListTest()
    var
        SalesHeader: Record "Sales Header";
        Workflow: Record Workflow;
        ApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
        SalesQuotes: TestPage "Sales Quotes";
    begin
        // [SCENARIO 3] Approval action availability.
        // [GIVEN] SalesHeader approval disabled.
        Initialize();

        // [WHEN] SalesHeader card is opened.
        CreateSalesQuote(SalesHeader);
        Commit();
        SalesQuotes.OpenEdit();
        SalesQuotes.GotoRecord(SalesHeader);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(SalesQuotes.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(SalesQuotes.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');

        // [WHEN] Send Approval Request is pushed.
        asserterror SalesQuotes.SendApprovalRequest.Invoke();

        // [THEN] Error is displayed.
        Assert.ExpectedError(NoWorkflowEnabledErr);

        // Cleanup
        SalesQuotes.Close();

        // [GIVEN] SalesHeader approval enabled.
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesQuoteApprovalWorkflowCode());

        // [WHEN] SalesHeader card is opened.
        SalesQuotes.OpenEdit();
        SalesQuotes.GotoRecord(SalesHeader);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(SalesQuotes.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(SalesQuotes.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');
        SalesQuotes.Close();

        // [GIVEN] Approval exist on SalesHeader.
        LibraryDocumentApprovals.SetupUsersForApprovals(ApproverUserSetup);
        SetSalesDocSalespersonCode(SalesHeader, ApproverUserSetup."Salespers./Purch. Code");
        SalesQuotes.OpenEdit();
        SalesQuotes.GotoRecord(SalesHeader);

        // [WHEN] SalesHeader send for approval.
        LibraryVariableStorage.Enqueue(ApprovalRequestSendMsg);
        SalesQuotes.SendApprovalRequest.Invoke();

        // [THEN] Only Send is enabled.
        Assert.IsFalse(SalesQuotes.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be disabled');
        Assert.IsTrue(SalesQuotes.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be enabled');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesQuoteApprovalWorkflowApprovePathAddComments()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        SalesHeader: Record "Sales Header";
        IntermediateApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [SCENARIO] This test verifies E2E scenario for the Sales quote approval workflow on approval path and adds a comment for each step.
        // [GIVEN] Sales Quote Approval Workflow that has Salesperson as the approver and No Limit as the limit type.
        // [WHEN] Sales Quote is sent for approval.
        // [THEN] Approval Request is created for the Salesperson and the user can add a comment.
        // [WHEN] Salesperson approves the approval request.
        // [THEN] Sales Quote is released.

        Initialize();

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesQuoteApprovalWorkflowCode());

        // Setup - Create 3 approval usersetups
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        // Setup - Create Sales Quote
        CreateSalesQuoteWithLine(SalesHeader, LibraryRandom.RandInt(5000));

        // Setup - Update Salesperson Code
        SetSalesDocSalespersonCode(SalesHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        CheckCommentsForDocumentOnDocumentCard(SalesHeader, 0, false);

        // Excercise - Open Sales Quote card and sent it for approval
        SendSalesQuoteForApproval(SalesHeader);

        CheckCommentsForDocumentOnDocumentCard(SalesHeader, 0, false);

        // Verify - Sales Quote status is set to Pending Approval
        VerifySalesQuoteIsPendingApproval(SalesHeader);

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

        // Excercise - Open Sales Quote card and approve the approval request
        ApproveSalesQuote(SalesHeader);

        // Verify - Approval requests and their data
        VerifySalesQuoteIsReleased(SalesHeader);
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
        VerifyApprovalEntryIsApproved(ApprovalEntry);
        CheckCommentsForDocumentOnApprovalEntriesPage(ApprovalEntry, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesQuoteApprovalWorkflowTestUserCanCancel()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        SalesHeader: Record "Sales Header";
        IntermediateApproverUserSetup: Record "User Setup";
        UserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [SCENARIO] This test verifies E2E scenario for the Sales Quote approval workflow on cancellation path and whether a user can cancel the workflow or not.
        // [GIVEN] Sales Quote Approval Workflow that has Salesperson as the approver and No Limit as the limit type.
        // [WHEN] Sales Quote is sent for approval.
        // [THEN] Approval Request is created for the Salesperson and user can cancel the request.
        // [WHEN] Next approver opens the document.
        // [THEN] The user can only cancel the request if he is an approval administrator.

        Initialize();

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesQuoteApprovalWorkflowCode());

        // Setup - Create 3 approval usersetups
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        // Setup - Create Sales Quote
        CreateSalesQuoteWithLine(SalesHeader, LibraryRandom.RandInt(5000));

        // Setup - Update Salesperson Code
        SetSalesDocSalespersonCode(SalesHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        // Excercise - Open Sales Quote card and sent it for approval
        SendSalesQuoteForApproval(SalesHeader);

        // Verify - User can cancel the approval request
        CheckUserCanCancelTheApprovalRequest(SalesHeader, true);

        // Verify - Sales Quote status is set to Pending Approval
        VerifySalesQuoteIsPendingApproval(SalesHeader);

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

        // Excercise - Open Sales Quote card and cancel the approval request
        CancelSalesQuote(SalesHeader);

        // Verify - Approval requests and their data
        VerifySalesQuoteIsOpen(SalesHeader);
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
        VerifyApprovalEntryIsCancelled(ApprovalEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesQuoteCustomerTemplateCheckAvailableCreditLimit()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [UT] [Credit Limit]
        // [SCENARIO 279695] Method "CheckAvailableCreditLimit" of table "Sales Header" returns 0 when customer not assigned
        Initialize();

        // [GIVEN] Contact created without customer
        // [GIVEN] Sales Quote created for the created contact with Customer Template Code assigned
        CreateSalesQuoteWithCustomerTemplateCode(SalesHeader);
        SalesHeader.TestField("Sell-to Customer No.", '');
        SalesHeader.TestField("Bill-to Customer No.", '');

        // [WHEN] Run CheckAvailableCreditLimit for the Sales Quote
        // [THEN] Return value = "0"
        Assert.AreEqual(0, SalesHeader.CheckAvailableCreditLimit(), 'Available credit limit should be 0');
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure CannotMakeInvoiceOfSalesQuotePendingApproval()
    var
        Workflow: Record Workflow;
        SalesHeader: Record "Sales Header";
        IntermediateApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
        SalesQuotes: TestPage "Sales Quotes";
    begin
        // [SCENARIO 405467] The user cannot make an invoice of a sales quote when the approval workflow is enabled and the sales quote is not approved
        Initialize();

        // [GIVEN] The approval workflow for sales quote is enabled.
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesQuoteApprovalWorkflowCode());
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        // [GIVEN] The sales quote is created and sent to approval.
        CreateSalesQuote(SalesHeader);
        SetSalesDocSalespersonCode(SalesHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");
        SendSalesQuoteForApproval(SalesHeader);

        // [WHEN] The user wants to Make Invoice of the sales quote.
        SalesQuotes.OpenView();
        SalesQuotes.GotoRecord(SalesHeader);
        asserterror SalesQuotes.MakeInvoice.Invoke();

        // [THEN] The user gets an error that he cannot use this action
        Assert.ExpectedError(StrSubstNo(RecordIsRestrictedErr, Format(SalesHeader.RecordId, 0, 1)));
    end;

    local procedure Initialize()
    var
        UserSetup: Record "User Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"WF Demo Sales Quote Approvals");
        LibraryVariableStorage.Clear();
        UserSetup.DeleteAll();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryWorkflow.DisableAllWorkflows();
        if IsInitialized then
            exit;
        IsInitialized := true;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"WF Demo Sales Quote Approvals");
        BindSubscription(LibraryJobQueue);
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"WF Demo Sales Quote Approvals");
        LibraryTemplates.EnableTemplatesFeature();
    end;

    local procedure CreateSalesQuote(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, '', LibraryRandom.RandInt(100));
    end;

    local procedure CreateSalesQuoteWithLine(var SalesHeader: Record "Sales Header"; Amount: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, '', 1);
        SalesLine.Validate("Unit Price", Amount);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesQuoteWithCustomerTemplateCode(var SalesHeader: Record "Sales Header")
    var
        CustomerTemplate: Record "Customer Templ.";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        CreateVATPostingSetup(VATPostingSetup);
        CreateCustomerTemplate(CustomerTemplate, VATPostingSetup."VAT Bus. Posting Group");
        CreateSalesHeaderWithContact2(SalesHeader, LibraryMarketing.CreateCompanyContactNo(), CustomerTemplate.Code);
        SalesHeader.Validate("Document Type", SalesHeader."Document Type"::Quote);
        SalesHeader.Modify(true);
        CreateSalesLineWithVATProdPostingGroup(SalesLine, SalesHeader, VATPostingSetup."VAT Prod. Posting Group", 1);
    end;

    local procedure CreateCustomerTemplate(var CustomerTemplate: Record "Customer Templ."; VATBusinessPostingGroupCode: Code[20])
    var
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        LibraryTemplates.CreateCustomerTemplate(CustomerTemplate);
        LibraryERM.CreateGenBusPostingGroup(GenBusinessPostingGroup);
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup);
        CustomerTemplate.Validate("Gen. Bus. Posting Group", GenBusinessPostingGroup.Code);
        CustomerTemplate.Validate("VAT Bus. Posting Group", VATBusinessPostingGroupCode);
        CustomerTemplate.Validate("Customer Posting Group", CustomerPostingGroup.Code);
        CustomerTemplate.Modify(true);
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);
    end;

    local procedure CreateSalesHeaderWithContact2(var SalesHeader: Record "Sales Header"; SellToContactNo: Code[20]; SellToCustomerTemplateCode: Code[20])
    begin
        SalesHeader.Init();
        SalesHeader.Insert(true);
        SalesHeader.Validate("Sell-to Customer Templ. Code", SellToCustomerTemplateCode);
        SalesHeader.Validate("Sell-to Contact No.", SellToContactNo);
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesLineWithVATProdPostingGroup(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; VATProdPostingGroupCode: Code[20]; Quantity: Integer)
    var
        No: Code[20];
    begin
        LibrarySales.CreateSalesLineSimple(SalesLine, SalesHeader);
        SalesLine.Validate(Type, SalesLine.Type::Item);
        No := LibraryInventory.CreateItemNoWithVATProdPostingGroup(VATProdPostingGroupCode);
        SalesLine.Validate("No.", No);
        SalesLine.Validate("Shipment Date", SalesHeader."Shipment Date");
        SalesLine.Validate(Quantity, Quantity);
        SalesLine.Modify(true);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Dummy message handler.
    end;

    local procedure SendSalesQuoteForApproval(var SalesHeader: Record "Sales Header")
    var
        SalesQuote: TestPage "Sales Quote";
    begin
        SalesQuote.OpenView();
        SalesQuote.GotoRecord(SalesHeader);
        SalesQuote.SendApprovalRequest.Invoke();
        SalesQuote.Close();
    end;

    local procedure RegetSalesDocument(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.SetRecFilter();
        SalesHeader.FindFirst();
    end;

    local procedure VerifySalesQuoteIsReleased(var SalesHeader: Record "Sales Header")
    begin
        RegetSalesDocument(SalesHeader);
        SalesHeader.TestField(Status, SalesHeader.Status::Released);
    end;

    local procedure VerifySalesQuoteIsOpen(var SalesHeader: Record "Sales Header")
    begin
        RegetSalesDocument(SalesHeader);
        SalesHeader.TestField(Status, SalesHeader.Status::Open);
    end;

    local procedure VerifySalesQuoteIsPendingApproval(var SalesHeader: Record "Sales Header")
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

    local procedure ApproveSalesQuote(var SalesHeader: Record "Sales Header")
    var
        SalesQuote: TestPage "Sales Quote";
    begin
        SalesQuote.OpenView();
        SalesQuote.GotoRecord(SalesHeader);
        SalesQuote.Approve.Invoke();
        SalesQuote.Close();
    end;

    local procedure RejectSalesQuote(var SalesHeader: Record "Sales Header")
    var
        SalesQuote: TestPage "Sales Quote";
    begin
        SalesQuote.OpenView();
        SalesQuote.GotoRecord(SalesHeader);
        SalesQuote.Reject.Invoke();
        SalesQuote.Close();
    end;

    local procedure DelegateSalesQuote(var SalesHeader: Record "Sales Header")
    var
        SalesQuote: TestPage "Sales Quote";
    begin
        SalesQuote.OpenView();
        SalesQuote.GotoRecord(SalesHeader);
        SalesQuote.Delegate.Invoke();
        SalesQuote.Close();
    end;

    local procedure CancelSalesQuote(var SalesHeader: Record "Sales Header")
    var
        SalesQuote: TestPage "Sales Quote";
    begin
        SalesQuote.OpenView();
        SalesQuote.GotoRecord(SalesHeader);
        SalesQuote.CancelApprovalRequest.Invoke();
        SalesQuote.Close();
    end;

    local procedure SetSalesDocSalespersonCode(SalesHeader: Record "Sales Header"; SalespersonCode: Code[20])
    begin
        SalesHeader.Validate("Salesperson Code", SalespersonCode);
        SalesHeader.Modify(true);
    end;

    local procedure CheckCommentsForDocumentOnDocumentCard(SalesHeader: Record "Sales Header"; NumberOfExpectedComments: Integer; CommentActionIsVisible: Boolean)
    var
        ApprovalComments: TestPage "Approval Comments";
        SalesQuote: TestPage "Sales Quote";
        NumberOfComments: Integer;
    begin
        ApprovalComments.Trap();

        SalesQuote.OpenView();
        SalesQuote.GotoRecord(SalesHeader);

        Assert.AreEqual(CommentActionIsVisible, SalesQuote.Comment.Visible(), 'The Comments action has the wrong visibility');

        if CommentActionIsVisible then begin
            SalesQuote.Comment.Invoke();
            if ApprovalComments.First() then
                repeat
                    NumberOfComments += 1;
                until ApprovalComments.Next();
            Assert.AreEqual(NumberOfExpectedComments, NumberOfComments, 'The page contains the wrong number of comments');

            ApprovalComments.Comment.SetValue('Test Comment' + Format(NumberOfExpectedComments));
            ApprovalComments.Next();
            ApprovalComments.Close();
        end;

        SalesQuote.Close();
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
        SalesQuote: TestPage "Sales Quote";
        SalesQuotes: TestPage "Sales Quotes";
    begin
        SalesQuote.OpenView();
        SalesQuote.GotoRecord(SalesHeader);
        Assert.AreEqual(CancelActionExpectedEnabled, SalesQuote.CancelApprovalRequest.Enabled(), 'Wrong state for the Cancel action');
        SalesQuote.Close();

        SalesQuotes.OpenView();
        SalesQuotes.GotoRecord(SalesHeader);
        Assert.AreEqual(CancelActionExpectedEnabled, SalesQuotes.CancelApprovalRequest.Enabled(), 'Wrong state for the Cancel action');
        SalesQuotes.Close();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandlerValidateMessage(Message: Text[1024])
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Message)
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

