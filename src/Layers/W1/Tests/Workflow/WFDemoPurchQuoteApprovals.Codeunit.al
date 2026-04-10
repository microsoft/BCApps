codeunit 134184 "WF Demo Purch Quote Approvals"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Workflow] [Approval] [Purchase] [Quote]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        DocCannotBeMadeOrderErr: Label '%1 %2 must be approved and released before you can perform this action.', Comment = '%1 = PurchHeader."Document Type", %2 = PurchHeader."No."';
        DocCannotBeReleasedErr: Label 'This document can only be released when the approval process is complete.';
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
    procedure CannotMakeOrderOfPurchaseQuote()
    var
        Workflow: Record Workflow;
        PurchaseHeader: Record "Purchase Header";
        WorkflowSetup: Codeunit "Workflow Setup";
        PurchaseQuotes: TestPage "Purchase Quotes";
    begin
        // [SCENARIO 378153] The user cannot make an order of a purchase quote when the approval workflow is enabled and the purchase quote is not approved and released.
        // [GIVEN] There is a purchase quote that is not approved and released.
        // [GIVEN] The approval workflow for puchase quote is enabled.
        // [WHEN] The user wants to Make Order of the purchase quote.
        // [THEN] The user will get an error that he cannot make an order of a purchase quote that is not approved and released.

        // Setup
        Initialize();

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseQuoteApprovalWorkflowCode());

        CreatePurchaseQuote(PurchaseHeader);

        // Exercise
        PurchaseQuotes.OpenView();
        PurchaseQuotes.GotoRecord(PurchaseHeader);
        asserterror PurchaseQuotes.MakeOrder.Invoke();

        // Verify
        Assert.ExpectedError(StrSubstNo(DocCannotBeMadeOrderErr, PurchaseHeader."Document Type", PurchaseHeader."No."));
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure CannotMakeOrderOfPurchaseQuotePendingApproval()
    var
        Workflow: Record Workflow;
        PurchaseHeader: Record "Purchase Header";
        IntermediateApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
        PurchaseQuotes: TestPage "Purchase Quotes";
    begin
        // [SCENARIO 378153] The user cannot make an order of a purchase quote when the approval workflow is enabled and the purchase quote is not approved
        Initialize();

        // [GIVEN] The approval workflow for puchase quote is enabled.
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseQuoteApprovalWorkflowCode());
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        // [GIVEN] The purchase quote is created and sent to approval.
        CreatePurchaseQuote(PurchaseHeader);
        SendPurchaseQuoteForApproval(PurchaseHeader);

        // [WHEN] The user wants to Make Order of the purchase quote.
        PurchaseQuotes.OpenView();
        PurchaseQuotes.GotoRecord(PurchaseHeader);
        asserterror PurchaseQuotes.MakeOrder.Invoke();

        // [THEN] The user gets an error that he cannot use this action
        Assert.ExpectedError(StrSubstNo(RecordIsRestrictedErr, Format(PurchaseHeader.RecordId, 0, 1)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotReleasePurchaseQuote()
    var
        Workflow: Record Workflow;
        PurchaseHeader: Record "Purchase Header";
        WorkflowSetup: Codeunit "Workflow Setup";
        PurchaseQuotes: TestPage "Purchase Quotes";
    begin
        // [SCENARIO] The user cannot release a purchase quote when the approval workflow is enabled and the purchase quote is not approved.
        // [GIVEN] There is a purchase quote that is not approved.
        // [GIVEN] The approval workflow for puchase quote is enabled.
        // [WHEN] The user wants to Release the purchase quote.
        // [THEN] The user will get an error that he cannot release a purchase quote that is not approved.

        // Setup
        Initialize();

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseQuoteApprovalWorkflowCode());

        CreatePurchaseQuote(PurchaseHeader);

        // Exercise
        PurchaseQuotes.OpenView();
        PurchaseQuotes.GotoRecord(PurchaseHeader);
        asserterror PurchaseQuotes.Release.Invoke();

        // Verify
        Assert.ExpectedError(DocCannotBeReleasedErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CannotReleasePurchaseQuoteApprovalIsPending()
    var
        Workflow: Record Workflow;
        PurchaseHeader: Record "Purchase Header";
        IntermediateApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
        PurchaseQuote: TestPage "Purchase Quote";
        Minimum: Integer;
    begin
        // [SCENARIO] The user cannot release a purchase quote when the approval workflow is enabled and the purchase quote is pending approval.
        // [GIVEN] There is a purchase quote that is sent for approval.
        // [GIVEN] The approval workflow for puchase quotes is enabled.
        // [WHEN] The user wants to Release the purchase quote.
        // [THEN] The user will get an error that he cannot release the purchase quote that is not approved.

        // Setup
        Initialize();
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseQuoteApprovalWorkflowCode());

        // Setup - Create 3 approval usersetups
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        // Setup - Create purchase quote
        Minimum := IntermediateApproverUserSetup."Request Amount Approval Limit" + 1;
        CreatePurchQuoteWithLine(PurchaseHeader, LibraryRandom.RandIntInRange(Minimum, Minimum + 1000));

        // Setup - Update Purchaser Code
        SetPurchDocPurchaserCode(PurchaseHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        // Excercise - Open Purchase quote card and sent it for approval
        SendPurchaseQuoteForApproval(PurchaseHeader);

        // Verify - Purchase quote status is set to Pending Approval
        VerifyPurchaseQuoteIsPendingApproval(PurchaseHeader);

        // Exercise
        Commit();
        PurchaseQuote.OpenView();
        PurchaseQuote.GotoRecord(PurchaseHeader);
        asserterror PurchaseQuote.Release.Invoke();

        // Verify
        Assert.ExpectedError(StrSubstNo(RecordIsRestrictedErr, Format(PurchaseHeader.RecordId, 0, 1)));
    end;

    [Test]
    procedure CanRequestApprovalPurchaseQuoteWithNotifySender()
    var
        PurchaseHeader: Record "Purchase Header";
        WorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowStepArgument: Record "Workflow Step Argument";
        ApprovalEntry: Record "Approval Entry";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        Variant: Variant;
    begin
        // [SCENARIO] When ExecuteResponse is called with a purchase header as argument and setup to Create a notification entry code, no error is thrown.
        // [GIVEN] The approval workflow for purchase quotes is enabled.
        // [WHEN] The user wants to Release the purchase quote.
        // [THEN] The user will get an error that he cannot release the purchase quote that is not approved.

        // Setup
        Initialize();

        // [GIVEN] A purchase quote that should be approved
        CreatePurchaseQuote(PurchaseHeader);

        // [GIVEN] An approval for the purchase quote
        if ApprovalEntry.FindLast() then;
        ApprovalEntry."Entry No." += 1;
        ApprovalEntry."Record ID to Approve" := PurchaseHeader.RecordId;
        ApprovalEntry.Insert();

        // [GIVEN] A workflow step for sending a notification
        WorkflowStepArgument.ID := CreateGuid();
        WorkflowStepArgument."Notify Sender" := true;
        WorkflowStepArgument.Insert();

        WorkflowStepInstance.ID := CreateGuid();
        WorkflowStepInstance.Argument := WorkflowStepArgument.ID;
        WorkflowStepInstance."Function Name" := WorkflowResponseHandling.CreateNotificationEntryCode();
        WorkflowStepInstance.Insert();

        // [WHEN] Executing the notification step
        // [THEN] No error is thrown
        WorkflowResponseHandling.ExecuteResponse(Variant, WorkflowStepInstance, PurchaseHeader);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CannotReopenPurchaseQuoteApprovalIsPending()
    var
        Workflow: Record Workflow;
        PurchaseHeader: Record "Purchase Header";
        IntermediateApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
        PurchaseQuote: TestPage "Purchase Quote";
        Minimum: Integer;
    begin
        // [SCENARIO] The user cannot release a purchase quote when the approval workflow is enabled and the purchase quote is pending approval.
        // [GIVEN] There is a purchase quote that is sent for approval.
        // [GIVEN] The approval workflow for puchase quotes is enabled.
        // [WHEN] The user wants to Reopen the purchase quote.
        // [THEN] The user will get an error that he cannot reopen the purchase quote.

        // Setup
        Initialize();
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseQuoteApprovalWorkflowCode());

        // Setup - Create 3 approval usersetups
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        // Setup - Create purchase Quote
        Minimum := IntermediateApproverUserSetup."Request Amount Approval Limit" + 1;
        CreatePurchQuoteWithLine(PurchaseHeader, LibraryRandom.RandIntInRange(Minimum, Minimum + 1000));

        // Setup - Update Purchaser Code
        SetPurchDocPurchaserCode(PurchaseHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        // Excercise - Open Purchase quote card and sent it for approval
        SendPurchaseQuoteForApproval(PurchaseHeader);

        // Verify - Purchase quote status is set to Pending Approval
        VerifyPurchaseQuoteIsPendingApproval(PurchaseHeader);

        // Exercise
        PurchaseQuote.OpenView();
        PurchaseQuote.GotoRecord(PurchaseHeader);
        asserterror PurchaseQuote.Reopen.Invoke();

        // Verify
        Assert.ExpectedError(ApprovalShouldBeHandledErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseQuoteApprovalWorkflowOnApprovePath()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        ApprovalEntryToApprove: Record "Approval Entry";
        PurchHeader: Record "Purchase Header";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
    begin
        // [SCENARIO] This test verifies E2E scenario for the Purchase Quote approval workflow on approval path.
        // [GIVEN] Purchase Quote Approval Workflow that has approver and Approval Limit as the limit type.
        // [WHEN] Purchase Quote is sent for approval.
        // [THEN] Approval Request is created for the purchaser.
        // [WHEN] Interim and Final users approve the approval request.
        // [THEN] Purchase Quote is released.

        Initialize();

        SendDocForApproval(Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup, PurchHeader);

        // Verify - Purchase Quote status is set to Pending Approval
        VerifyPurchaseQuoteIsPendingApproval(PurchHeader);

        // Verify - Approval requests and their data
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchHeader.RecordId);
        Assert.AreEqual(3, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        CheckApprovalEntriesBeforeInterimAction(ApprovalEntryToApprove,
          ApprovalEntry, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);

        // Setup - Assign the approval entry to current user so that it can be approved
        AssignApprovalEntry(ApprovalEntryToApprove, CurrentUserSetup);

        // Excercise - Open Purchae quote card and approve the approval request
        ApprovePurchaseQuote(PurchHeader);

        // Verify - Approval requests and their data
        Clear(ApprovalEntry);
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchHeader.RecordId);
        Assert.AreEqual(3, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        CheckApprovalEntriesBeforeFinalAction(ApprovalEntryToApprove, ApprovalEntry, CurrentUserSetup, FinalApproverUserSetup);

        // Setup - Assign the approval entry to current user so that it can be approved
        AssignApprovalEntry(ApprovalEntryToApprove, CurrentUserSetup);

        // Excercise - Open Purchae quote card and approve the approval request
        ApprovePurchaseQuote(PurchHeader);

        // Verify - Approval requests and their data
        VerifyPurchaseQuoteIsReleased(PurchHeader);
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchHeader.RecordId);
        VerifyApprovalEntryIsApproved(ApprovalEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseQuoteApprovalWorkflowOnRejectionPath()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        ApprovalEntryToApprove: Record "Approval Entry";
        ApprovalEntryToReject: Record "Approval Entry";
        PurchHeader: Record "Purchase Header";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
    begin
        // [SCENARIO] This test verifies E2E scenario for the Purchase Quote approval workflow on rejection path.
        // [GIVEN] Purchase Quote Approval Workflow that has Purchaser as the approver and Approval Limit as the limit type.
        // [WHEN] Purchase Quote is sent for approval.
        // [THEN] Approval Request is created for the purchaser.
        // [WHEN] Interim user approves the approval request.
        // [WHEN] Final user rejects the approval request.
        // [THEN] Purchase Quote is reopened and approval entries are marked as rejected.

        Initialize();

        SendDocForApproval(Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup, PurchHeader);

        // Verify - Purchase Quote status is set to Pending Approval
        VerifyPurchaseQuoteIsPendingApproval(PurchHeader);

        // Verify - Approval requests and their data
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchHeader.RecordId);
        Assert.AreEqual(3, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        CheckApprovalEntriesBeforeInterimAction(ApprovalEntryToApprove,
          ApprovalEntry, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);

        // Setup - Assign the approval entry to current user so that it can be approved
        AssignApprovalEntry(ApprovalEntryToApprove, CurrentUserSetup);

        // Excercise - Open Purchae quote card and approve the approval request
        ApprovePurchaseQuote(PurchHeader);

        // Verify - Approval requests and their data
        Clear(ApprovalEntry);
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchHeader.RecordId);
        Assert.AreEqual(3, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        CheckApprovalEntriesBeforeFinalAction(ApprovalEntryToReject, ApprovalEntry, CurrentUserSetup, FinalApproverUserSetup);

        // Assign the approval entry to current user so that it can be rejected
        AssignApprovalEntry(ApprovalEntryToReject, CurrentUserSetup);

        // Excercise - Open Purchae quote card and reject the approval request
        RejectPurchaseQuote(PurchHeader);

        // Verify - Approval requests and their data
        VerifyPurchaseQuoteIsOpen(PurchHeader);
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchHeader.RecordId);
        VerifyApprovalEntryIsRejected(ApprovalEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseQuoteApprovalWorkflowOnDelegationPath()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        ApprovalEntryToApprove: Record "Approval Entry";
        ApprovalEntryToDelegate: Record "Approval Entry";
        PurchHeader: Record "Purchase Header";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
    begin
        // [SCENARIO] This test verifies E2E scenario for the Purchase Quote approval workflow on delegation path.
        // [GIVEN] Purchase Quote Approval Workflow that has Purchaser as the approver and Approval Limit as the limit type.
        // [WHEN] Purchase Quote is sent for approval.
        // [THEN] Approval Request is created for the purchaser.
        // [WHEN] Interim user delegates the approval request.
        // [THEN] Approval request is assigned to the substitute.
        // [WHEN] Final user approves the approval requests.
        // [THEN] Purchase Quote is released.

        Initialize();

        SendDocForApproval(Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup, PurchHeader);

        // Verify - Purchase Quote status is set to Pending Approval
        VerifyPurchaseQuoteIsPendingApproval(PurchHeader);

        // Verify - Approval requests and their data
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchHeader.RecordId);
        Assert.AreEqual(3, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        CheckApprovalEntriesBeforeInterimAction(ApprovalEntryToDelegate,
          ApprovalEntry, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);

        // Assign the approval entry to current user so that it can be delegated
        AssignApprovalEntry(ApprovalEntryToDelegate, CurrentUserSetup);

        // Excercise - Open Purchae quote card and delegate the approval request
        DelegatePurchaseQuote(PurchHeader);

        // Verify - Approval requests and their data
        VerifyPurchaseQuoteIsPendingApproval(PurchHeader);

        // Verify - Approval requests and their data
        Clear(ApprovalEntry);
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchHeader.RecordId);
        Assert.AreEqual(3, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        CheckApprovalEntriesAfterDelegation(ApprovalEntryToApprove, ApprovalEntry, CurrentUserSetup, FinalApproverUserSetup);

        // Assign the approval entry to current user so that it can be approved
        AssignApprovalEntry(ApprovalEntryToApprove, CurrentUserSetup);

        // Excercise - Open Purchae quote card and approve the approval request of the interim approver
        ApprovePurchaseQuote(PurchHeader);

        // Verify - Approval requests and their data
        Clear(ApprovalEntry);
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchHeader.RecordId);
        Assert.AreEqual(3, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        CheckApprovalEntriesBeforeFinalAction(ApprovalEntryToApprove, ApprovalEntry, CurrentUserSetup, FinalApproverUserSetup);

        // Setup - Assign the approval entry to current user so that it can be approved
        AssignApprovalEntry(ApprovalEntryToApprove, CurrentUserSetup);

        // Excercise - Open Purchae quote card and approve the approval request of the final approver
        ApprovePurchaseQuote(PurchHeader);

        // Verify - Approval requests and their data
        VerifyPurchaseQuoteIsReleased(PurchHeader);
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchHeader.RecordId);
        VerifyApprovalEntryIsApproved(ApprovalEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseQuoteApprovalWorkflowOnCancellationPath()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        ApprovalEntryToCancel: Record "Approval Entry";
        PurchHeader: Record "Purchase Header";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
    begin
        // [SCENARIO] This test verifies E2E scenario for the Purchase Quote approval workflow on cancellation path.
        // [GIVEN] Purchase Quote Approval Workflow that has Purchaser as the approver and Approval Limit as the limit type.
        // [WHEN] Purchase Quote is sent for approval.
        // [THEN] Approval Request is created for the purchaser.
        // [WHEN] Sender cancels the approval request.
        // [THEN] Purchase Quote is opend and approval requests are marked as cancelled.

        Initialize();

        SendDocForApproval(Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup, PurchHeader);

        // Verify - Purchase Quote status is set to Pending Approval
        VerifyPurchaseQuoteIsPendingApproval(PurchHeader);

        // Verify - Approval requests and their data
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchHeader.RecordId);
        Assert.AreEqual(3, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        CheckApprovalEntriesBeforeInterimAction(ApprovalEntryToCancel,
          ApprovalEntry, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);

        // Excercise - Open Purchae quote card and cancel the approval request
        CancelPurchaseQuote(PurchHeader);

        // Verify - Approval requests and their data
        VerifyPurchaseQuoteIsOpen(PurchHeader);
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchHeader.RecordId);
        VerifyApprovalEntryIsCancelled(ApprovalEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandlerValidateMessage')]
    [Scope('OnPrem')]
    procedure PurchaseQuoteApprovalActionsVisibilityOnCardTest()
    var
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        PurchHeader: Record "Purchase Header";
        Workflow: Record Workflow;
        WorkflowSetup: Codeunit "Workflow Setup";
        PurchaseQuote: TestPage "Purchase Quote";
        Minimum: Decimal;
    begin
        // [SCENARIO 3] Approval action availability.
        // [GIVEN] Purchase Header approval disabled.
        Initialize();
        CreateUserSetupsAndChainOfApprovers(CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);

        // [WHEN] Purchase Header card is opened.
        Minimum := IntermediateApproverUserSetup."Request Amount Approval Limit" + 1;
        CreatePurchQuoteWithLine(PurchHeader, LibraryRandom.RandIntInRange(Minimum, Minimum + 1000));
        SetPurchDocPurchaserCode(PurchHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");
        Commit();
        PurchaseQuote.OpenEdit();
        PurchaseQuote.GotoRecord(PurchHeader);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(PurchaseQuote.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(PurchaseQuote.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should NOT be enabled');

        // [WHEN] Send Approval Request is pushed.
        asserterror PurchaseQuote.SendApprovalRequest.Invoke();

        // [THEN] Error is displayed.
        Assert.ExpectedError(NoWorkflowEnabledErr);

        // Cleanup
        PurchaseQuote.Close();

        // [GIVEN] PurchHeader approval enabled.
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseQuoteApprovalWorkflowCode());

        // [WHEN] PurchHeader card is opened.
        PurchaseQuote.OpenEdit();
        PurchaseQuote.GotoRecord(PurchHeader);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(PurchaseQuote.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(PurchaseQuote.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');
        Assert.IsFalse(PurchaseQuote.Approve.Visible(), 'Approve should NOT be visible');
        Assert.IsFalse(PurchaseQuote.Reject.Visible(), 'Reject should NOT be visible');
        Assert.IsFalse(PurchaseQuote.Delegate.Visible(), 'Delegate should NOT be visible');
        PurchaseQuote.Close();

        // [GIVEN] Approval exist on PurchHeader.
        PurchaseQuote.OpenEdit();
        PurchaseQuote.GotoRecord(PurchHeader);

        // [WHEN] PurchHeader send for approval.
        LibraryVariableStorage.Enqueue(ApprovalRequestSendMsg);
        PurchaseQuote.SendApprovalRequest.Invoke();

        // [THEN] Only Send is enabled.
        Assert.IsFalse(PurchaseQuote.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be disabled');
        Assert.IsTrue(PurchaseQuote.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be enabled');

        // Clenup
        PurchaseQuote.Close();

        // Setup the approval so it can be approve by current user
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(PurchHeader.RecordId);

        // [WHEN] PurchHeader card is opened.
        PurchaseQuote.OpenEdit();
        PurchaseQuote.GotoRecord(PurchHeader);

        // [THEN] Approval action are shown.
        Assert.IsTrue(PurchaseQuote.Approve.Visible(), 'Approve should be visible');
        Assert.IsTrue(PurchaseQuote.Reject.Visible(), 'Reject should be visible');
        Assert.IsTrue(PurchaseQuote.Delegate.Visible(), 'Delegate should be visible');
    end;

    [Test]
    [HandlerFunctions('MessageHandlerValidateMessage')]
    [Scope('OnPrem')]
    procedure PurchaseQuoteApprovalActionsVisibilityOnListTest()
    var
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        PurchHeader: Record "Purchase Header";
        Workflow: Record Workflow;
        WorkflowSetup: Codeunit "Workflow Setup";
        PurchaseQuotes: TestPage "Purchase Quotes";
        Minimum: Decimal;
    begin
        // [SCENARIO 3] Approval action availability.
        // [GIVEN] PurchHeader approval disabled.
        Initialize();

        // [WHEN] PurchHeader card is opened.
        CreateUserSetupsAndChainOfApprovers(CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);
        Minimum := IntermediateApproverUserSetup."Request Amount Approval Limit" + 1;
        CreatePurchQuoteWithLine(PurchHeader, LibraryRandom.RandIntInRange(Minimum, Minimum + 1000));
        SetPurchDocPurchaserCode(PurchHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");
        Commit();
        PurchaseQuotes.OpenEdit();
        PurchaseQuotes.GotoRecord(PurchHeader);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(PurchaseQuotes.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(PurchaseQuotes.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');

        // [WHEN] Send Approval Request is pushed.
        asserterror PurchaseQuotes.SendApprovalRequest.Invoke();

        // [THEN] Error is displayed.
        Assert.ExpectedError(NoWorkflowEnabledErr);

        // Cleanup
        PurchaseQuotes.Close();

        // [GIVEN] PurchHeader approval enabled.
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseQuoteApprovalWorkflowCode());

        // [WHEN] PurchHeader card is opened.
        PurchaseQuotes.OpenEdit();
        PurchaseQuotes.GotoRecord(PurchHeader);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(PurchaseQuotes.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(PurchaseQuotes.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');
        PurchaseQuotes.Close();

        // [GIVEN] Approval exist on PurchHeader.
        PurchaseQuotes.OpenEdit();
        PurchaseQuotes.GotoRecord(PurchHeader);

        // [WHEN] PurchHeader send for approval.
        LibraryVariableStorage.Enqueue(ApprovalRequestSendMsg);
        PurchaseQuotes.SendApprovalRequest.Invoke();

        // [THEN] Only Send is enabled.
        Assert.IsFalse(PurchaseQuotes.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be disabled');
        Assert.IsTrue(PurchaseQuotes.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be enabled');
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerYes,PurchaseOrderHandler')]
    [Scope('OnPrem')]
    procedure PurchaseQuoteMakeOrderAfterApproval()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        ApprovalEntryToApprove: Record "Approval Entry";
        PurchHeader: Record "Purchase Header";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        PurchaseQuotes: TestPage "Purchase Quotes";
    begin
        // [SCENARIO] This test verifies E2E scenario for the Purchase Quote approval workflow on approval path.
        // [GIVEN] Purchase Quote Approval Workflow that has approver and Approval Limit as the limit type.
        // [WHEN] Purchase Quote is sent for approval.
        // [THEN] Approval Request is created for the purchaser.
        // [WHEN] Interim and Final users approve the approval request.
        // [THEN] Purchase Quote is released.
        // [WHEN] Make order is invoker
        // [THEN] No approval entries remain for the quote.

        Initialize();

        SendDocForApproval(Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup, PurchHeader);

        // Verify - Purchase Quote status is set to Pending Approval
        VerifyPurchaseQuoteIsPendingApproval(PurchHeader);

        // Verify - Approval requests and their data
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchHeader.RecordId);
        Assert.AreEqual(3, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        CheckApprovalEntriesBeforeInterimAction(ApprovalEntryToApprove,
          ApprovalEntry, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);

        // Setup - Assign the approval entry to current user so that it can be approved
        AssignApprovalEntry(ApprovalEntryToApprove, CurrentUserSetup);

        // Excercise - Open Purchae quote card and approve the approval request
        ApprovePurchaseQuote(PurchHeader);

        // Verify - Approval requests and their data
        Clear(ApprovalEntry);
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchHeader.RecordId);
        Assert.AreEqual(3, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        CheckApprovalEntriesBeforeFinalAction(ApprovalEntryToApprove, ApprovalEntry, CurrentUserSetup, FinalApproverUserSetup);

        // Setup - Assign the approval entry to current user so that it can be approved
        AssignApprovalEntry(ApprovalEntryToApprove, CurrentUserSetup);

        // Excercise - Open Purchae quote card and approve the approval request
        ApprovePurchaseQuote(PurchHeader);

        // Verify - Approval requests and their data
        VerifyPurchaseQuoteIsReleased(PurchHeader);
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchHeader.RecordId);
        VerifyApprovalEntryIsApproved(ApprovalEntry);

        // Exercise: Make order is allowed
        PurchaseQuotes.OpenView();
        PurchaseQuotes.GotoRecord(PurchHeader);
        PurchaseQuotes.MakeOrder.Invoke();

        // Verify: No approval entries remain
        ApprovalEntry.Reset();
        asserterror LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchHeader.RecordId);
        Assert.AssertNothingInsideFilter();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseQuoteApprovalWorkflowApprovePathAddComments()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        PurchaseHeader: Record "Purchase Header";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
    begin
        // [SCENARIO] This test verifies E2E scenario for the Purchase Quote approval workflow on approval path and adds a comment for each step.
        // [GIVEN] Purchase Quote Approval Workflow that has Purchaser as the approver and No Limit as the limit type.
        // [WHEN] Purchase Quote is sent for approval.
        // [THEN] Approval Request is created for the Purchaser and the user can add a comment.
        // [WHEN] Purchaser approves the approval request.
        // [THEN] Purchase Quote is released.

        Initialize();

        SendDocForApproval(Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup, PurchaseHeader);

        CheckCommentsForDocumentOnDocumentCard(PurchaseHeader, 0, false);

        // Verify - Purchase Quote status is set to Pending Approval
        VerifyPurchaseQuoteIsPendingApproval(PurchaseHeader);

        // Verify - Approval requests and their data
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchaseHeader.RecordId);
        Assert.AreEqual(3, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        ApprovalEntry.Next();
        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, UserId);
        VerifyApprovalEntryApproverID(ApprovalEntry, IntermediateApproverUserSetup."User ID");

        CheckCommentsForDocumentOnDocumentCard(PurchaseHeader, 0, false);

        // Setup - Assign the approval entry to current user so that it can be approved
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(PurchaseHeader.RecordId);

        CheckCommentsForDocumentOnDocumentCard(PurchaseHeader, 0, true);
        CheckCommentsForDocumentOnRequestsToApprovePage(ApprovalEntry, 1);

        // Excercise - Open Purchase Quote card and approve the approval request
        ApprovePurchaseQuote(PurchaseHeader);

        // Verify - Approval requests and their data
        VerifyPurchaseQuoteIsPendingApproval(PurchaseHeader);
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchaseHeader.RecordId);
        VerifyApprovalEntryIsApproved(ApprovalEntry);
        CheckCommentsForDocumentOnApprovalEntriesPage(ApprovalEntry, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseQuoteApprovalWorkflowTestUserCanCancel()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        PurchaseHeader: Record "Purchase Header";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
    begin
        // [SCENARIO] This test verifies E2E scenario for the Purchase Quote approval workflow on cancellation path and whether a user can cancel the workflow or not.
        // [GIVEN] Purchase Quote Approval Workflow that has Purchaser as the approver and No Limit as the limit type.
        // [WHEN] Purchase Quote is sent for approval.
        // [THEN] Approval Request is created for the Purchaser and user can cancel the request.
        // [WHEN] Next approver opens the document.
        // [THEN] The user can only cancel the request if he is an approval administrator.

        Initialize();

        SendDocForApproval(Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup, PurchaseHeader);

        // Verify - User can cancel the approval request
        CheckUserCanCancelTheApprovalRequest(PurchaseHeader, true);

        // Verify - Purchase Quote status is set to Pending Approval
        VerifyPurchaseQuoteIsPendingApproval(PurchaseHeader);

        // Verify - Approval requests and their data
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchaseHeader.RecordId);
        Assert.AreEqual(3, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        ApprovalEntry.Next();
        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, UserId);
        VerifyApprovalEntryApproverID(ApprovalEntry, IntermediateApproverUserSetup."User ID");

        // Setup - Assign the approval entry to current user so that it can be approved
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(PurchaseHeader.RecordId);

        // Verify - User Cannot cancel the approval request
        CheckUserCanCancelTheApprovalRequest(PurchaseHeader, false);

        LibraryDocumentApprovals.SetAdministrator(CurrentUserSetup);

        // Verify - User can cancel the approval request
        CheckUserCanCancelTheApprovalRequest(PurchaseHeader, true);

        // Excercise - Open Purchase Quote card and cancel the approval request
        CancelPurchaseQuote(PurchaseHeader);

        // Verify - Approval requests and their data
        VerifyPurchaseQuoteIsOpen(PurchaseHeader);
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchaseHeader.RecordId);
        VerifyApprovalEntryIsCancelled(ApprovalEntry);
    end;

    local procedure SendDocForApproval(var Workflow: Record Workflow; var CurrentUserSetup: Record "User Setup"; var IntermediateApproverUserSetup: Record "User Setup"; var FinalApproverUserSetup: Record "User Setup"; var PurchaseHeader: Record "Purchase Header")
    var
        WorkflowSetup: Codeunit "Workflow Setup";
        Minimum: Integer;
    begin
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseQuoteApprovalWorkflowCode());

        // Setup - Create 3 user setups, chain the users for approval, set purchase amount limits
        CreateUserSetupsAndChainOfApprovers(CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);

        // Setup - Create Purchase Quote
        Minimum := IntermediateApproverUserSetup."Request Amount Approval Limit" + 1;
        CreatePurchQuoteWithLine(PurchaseHeader, LibraryRandom.RandIntInRange(Minimum, Minimum + 1000));

        // Setup - Update Purchaser Code
        SetPurchDocPurchaserCode(PurchaseHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        // Excercise - Open Purchase Quote card and send it for approval
        SendPurchaseQuoteForApproval(PurchaseHeader);
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
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"WF Demo Purch Quote Approvals");
        LibraryVariableStorage.Clear();
        UserSetup.DeleteAll();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryWorkflow.DisableAllWorkflows();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"WF Demo Purch Quote Approvals");
        IsInitialized := true;
        BindSubscription(LibraryJobQueue);
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"WF Demo Purch Quote Approvals");
    end;

    local procedure RegetPurchaseDocument(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.SetRecFilter();
        PurchaseHeader.FindFirst();
    end;

    local procedure CreatePurchaseQuote(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Quote, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, '', LibraryRandom.RandInt(100));
    end;

    local procedure CreatePurchQuoteWithLine(var PurchHeader: Record "Purchase Header"; Amount: Decimal)
    var
        PurchLine: Record "Purchase Line";
        Item: Record Item;
        Vendor: Record Vendor;
        VATPostingSetup: Record "VAT Posting Setup";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        LibraryERM.FindZeroVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        LibraryPurchase.CreateVendor(Vendor);
        Vendor."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        Vendor.Modify();

        LibraryInventory.CreateItem(Item);
        Item."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        Item.Modify();

        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Quote, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::Item, Item."No.", 1);
        PurchLine.Validate("Direct Unit Cost", Amount);
        PurchLine.Modify(true);
    end;

    local procedure CreateUserSetupsAndChainOfApprovers(var CurrentUserSetup: Record "User Setup"; var IntermediateApproverUserSetup: Record "User Setup"; var FinalApproverUserSetup: Record "User Setup")
    begin
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        CurrentUserSetup.Get(UserId);
        SetRequestAmountApprovalLimits(CurrentUserSetup, LibraryRandom.RandIntInRange(1, 100));
        SetLimitedRequestApprovalLimits(CurrentUserSetup);

        SetRequestAmountApprovalLimits(IntermediateApproverUserSetup, LibraryRandom.RandIntInRange(101, 1000));
        SetLimitedRequestApprovalLimits(IntermediateApproverUserSetup);

        FinalApproverUserSetup.Get(IntermediateApproverUserSetup."Approver ID");
        SetRequestAmountApprovalLimits(FinalApproverUserSetup, 0);
        SetUnlimitedRequestApprovalLimits(FinalApproverUserSetup);
    end;

    local procedure SetRequestAmountApprovalLimits(var UserSetup: Record "User Setup"; PurchaseApprovalLimit: Integer)
    begin
        UserSetup."Request Amount Approval Limit" := PurchaseApprovalLimit;
        UserSetup.Modify(true);
    end;

    local procedure SetLimitedRequestApprovalLimits(var UserSetup: Record "User Setup")
    begin
        UserSetup."Unlimited Request Approval" := false;
        UserSetup.Modify(true);
    end;

    local procedure SetUnlimitedRequestApprovalLimits(var UserSetup: Record "User Setup")
    begin
        UserSetup."Unlimited Request Approval" := true;
        UserSetup.Modify(true);
    end;

    local procedure SetPurchDocPurchaserCode(PurchaseHeader: Record "Purchase Header"; PurchaserCode: Code[20])
    begin
        PurchaseHeader.Validate("Purchaser Code", PurchaserCode);
        PurchaseHeader.Modify(true);
    end;

    local procedure SendPurchaseQuoteForApproval(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        PurchaseQuote.OpenView();
        PurchaseQuote.GotoRecord(PurchaseHeader);
        PurchaseQuote.SendApprovalRequest.Invoke();
        PurchaseQuote.Close();
    end;

    local procedure VerifyPurchaseQuoteIsOpen(var PurchaseHeader: Record "Purchase Header")
    begin
        RegetPurchaseDocument(PurchaseHeader);
        PurchaseHeader.TestField(Status, PurchaseHeader.Status::Open);
    end;

    local procedure VerifyPurchaseQuoteIsPendingApproval(var PurchaseHeader: Record "Purchase Header")
    begin
        RegetPurchaseDocument(PurchaseHeader);
        PurchaseHeader.TestField(Status, PurchaseHeader.Status::"Pending Approval");
    end;

    local procedure VerifyPurchaseQuoteIsReleased(var PurchaseHeader: Record "Purchase Header")
    begin
        RegetPurchaseDocument(PurchaseHeader);
        PurchaseHeader.TestField(Status, PurchaseHeader.Status::Released);
    end;

    local procedure VerifyApprovalEntryIsApproved(ApprovalEntry: Record "Approval Entry")
    begin
        ApprovalEntry.TestField(Status, ApprovalEntry.Status::Approved);
    end;

    local procedure VerifyApprovalEntryIsCreated(ApprovalEntry: Record "Approval Entry")
    begin
        ApprovalEntry.TestField(Status, ApprovalEntry.Status::Created);
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

    local procedure CheckApprovalEntriesBeforeInterimAction(var ApprovalEntryToActOn: Record "Approval Entry"; ApprovalEntry: Record "Approval Entry"; CurrentUserSetup: Record "User Setup"; IntermediateApproverUserSetup: Record "User Setup"; FinalApproverUserSetup: Record "User Setup")
    begin
        VerifyApprovalEntryIsApproved(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, CurrentUserSetup."User ID");
        VerifyApprovalEntryApproverID(ApprovalEntry, CurrentUserSetup."User ID");

        ApprovalEntry.Next();
        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, CurrentUserSetup."User ID");
        VerifyApprovalEntryApproverID(ApprovalEntry, IntermediateApproverUserSetup."User ID");
        ApprovalEntryToActOn := ApprovalEntry;

        ApprovalEntry.Next();
        VerifyApprovalEntryIsCreated(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, CurrentUserSetup."User ID");
        VerifyApprovalEntryApproverID(ApprovalEntry, FinalApproverUserSetup."User ID");
    end;

    local procedure CheckApprovalEntriesBeforeFinalAction(var ApprovalEntryToActOn: Record "Approval Entry"; ApprovalEntry: Record "Approval Entry"; CurrentUserSetup: Record "User Setup"; FinalApproverUserSetup: Record "User Setup")
    begin
        VerifyApprovalEntryIsApproved(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, CurrentUserSetup."User ID");
        VerifyApprovalEntryApproverID(ApprovalEntry, CurrentUserSetup."User ID");

        ApprovalEntry.Next();
        VerifyApprovalEntryIsApproved(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, CurrentUserSetup."User ID");
        VerifyApprovalEntryApproverID(ApprovalEntry, CurrentUserSetup."User ID");

        ApprovalEntry.Next();
        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, CurrentUserSetup."User ID");
        VerifyApprovalEntryApproverID(ApprovalEntry, FinalApproverUserSetup."User ID");
        ApprovalEntryToActOn := ApprovalEntry;
    end;

    local procedure CheckApprovalEntriesAfterDelegation(var ApprovalEntryToActOn: Record "Approval Entry"; ApprovalEntry: Record "Approval Entry"; CurrentUserSetup: Record "User Setup"; FinalApproverUserSetup: Record "User Setup")
    begin
        VerifyApprovalEntryIsApproved(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, CurrentUserSetup."User ID");
        VerifyApprovalEntryApproverID(ApprovalEntry, CurrentUserSetup."User ID");

        ApprovalEntry.Next();
        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, CurrentUserSetup."User ID");
        VerifyApprovalEntryApproverID(ApprovalEntry, FinalApproverUserSetup."User ID");
        ApprovalEntryToActOn := ApprovalEntry;

        ApprovalEntry.Next();
        VerifyApprovalEntryIsCreated(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, CurrentUserSetup."User ID");
        VerifyApprovalEntryApproverID(ApprovalEntry, FinalApproverUserSetup."User ID");
    end;

    local procedure AssignApprovalEntry(var ApprovalEntry: Record "Approval Entry"; UserSetup: Record "User Setup")
    begin
        ApprovalEntry."Approver ID" := UserSetup."User ID";
        ApprovalEntry.Modify();
    end;

    local procedure ApprovePurchaseQuote(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        PurchaseQuote.OpenView();
        PurchaseQuote.GotoRecord(PurchaseHeader);
        PurchaseQuote.Approve.Invoke();
        PurchaseQuote.Close();
    end;

    local procedure RejectPurchaseQuote(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        PurchaseQuote.OpenView();
        PurchaseQuote.GotoRecord(PurchaseHeader);
        PurchaseQuote.Reject.Invoke();
        PurchaseQuote.Close();
    end;

    local procedure DelegatePurchaseQuote(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        PurchaseQuote.OpenView();
        PurchaseQuote.GotoRecord(PurchaseHeader);
        PurchaseQuote.Delegate.Invoke();
        PurchaseQuote.Close();
    end;

    local procedure CancelPurchaseQuote(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        PurchaseQuote.OpenView();
        PurchaseQuote.GotoRecord(PurchaseHeader);
        PurchaseQuote.CancelApprovalRequest.Invoke();
        PurchaseQuote.Close();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Dummy message handler.
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderHandler(var PurchaseOrder: TestPage "Purchase Order")
    begin
    end;

    local procedure CheckCommentsForDocumentOnDocumentCard(PurchaseHeader: Record "Purchase Header"; NumberOfExpectedComments: Integer; CommentActionIsVisible: Boolean)
    var
        ApprovalComments: TestPage "Approval Comments";
        PurchaseQuote: TestPage "Purchase Quote";
        NumberOfComments: Integer;
    begin
        ApprovalComments.Trap();

        PurchaseQuote.OpenView();
        PurchaseQuote.GotoRecord(PurchaseHeader);

        Assert.AreEqual(CommentActionIsVisible, PurchaseQuote.Comment.Visible(), 'The Comments action has the wrong visibility');

        if CommentActionIsVisible then begin
            PurchaseQuote.Comment.Invoke();
            if ApprovalComments.First() then
                repeat
                    NumberOfComments += 1;
                until ApprovalComments.Next();
            Assert.AreEqual(NumberOfExpectedComments, NumberOfComments, 'The page contains the wrong number of comments');

            ApprovalComments.Comment.SetValue('Test Comment' + Format(NumberOfExpectedComments));
            ApprovalComments.Next();
            ApprovalComments.Close();
        end;

        PurchaseQuote.Close();
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
        PurchaseQuote: TestPage "Purchase Quote";
        PurchaseQuotes: TestPage "Purchase Quotes";
    begin
        PurchaseQuote.OpenView();
        PurchaseQuote.GotoRecord(PurchaseHeader);
        Assert.AreEqual(CancelActionExpectedEnabled, PurchaseQuote.CancelApprovalRequest.Enabled(), 'Wrong state for the Cancel action');
        PurchaseQuote.Close();

        PurchaseQuotes.OpenView();
        PurchaseQuotes.GotoRecord(PurchaseHeader);
        Assert.AreEqual(CancelActionExpectedEnabled, PurchaseQuotes.CancelApprovalRequest.Enabled(), 'Wrong state for the Cancel action');
        PurchaseQuotes.Close();
    end;
}

