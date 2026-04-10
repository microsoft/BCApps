codeunit 134181 "WF Demo Purch CrMemo Approvals"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Workflow] [Approval] [Purchase] [Credit Memo]
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
        LibraryWorkflow: Codeunit "Library - Workflow";
        NoWorkflowEnabledErr: Label 'No approval workflow for this record type is enabled.';
        ApprovalRequestSendMsg: Label 'An approval request has been sent.';
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        RecordIsRestrictedErr: Label 'You cannot use %1 for this action.', Comment = '%1=Record Id';
        ApprovalShouldBeHandledErr: Label 'The approval process must be cancelled or completed to reopen this document.';
        UnexpectedNoOfApprovalEntriesErr: Label 'Unexpected number of approval entries found.';
        LibraryJobQueue: Codeunit "Library - Job Queue";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure CannotPostPurchaseCreditMemo()
    var
        Workflow: Record Workflow;
        PurchaseHeader: Record "Purchase Header";
        WorkflowSetup: Codeunit "Workflow Setup";
        PurchaseCreditMemos: TestPage "Purchase Credit Memos";
    begin
        // [SCENARIO] The user cannot post a purchase credit memo when the approval workflow is enabled and the purchase credit memo is not approved.
        // [GIVEN] There is a purchase credit memo that is not approved.
        // [GIVEN] The approval workflow for puchase credit memo is enabled.
        // [WHEN] The user wants to Post the purchase credit memo.
        // [THEN] The user will get an error that he cannot post a purchase credit memo that is not approved.

        // Setup
        Initialize();

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseCreditMemoApprovalWorkflowCode());

        CreatePurchaseCreditMemo(PurchaseHeader);

        // Exercise
        PurchaseCreditMemos.OpenView();
        PurchaseCreditMemos.GotoRecord(PurchaseHeader);
        asserterror PurchaseCreditMemos.Post.Invoke();

        // Verify
        Assert.ExpectedError(StrSubstNo(DocCannotBePostedErr, PurchaseHeader."Document Type", PurchaseHeader."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotReleasePurchaseCreditMemo()
    var
        Workflow: Record Workflow;
        PurchaseHeader: Record "Purchase Header";
        WorkflowSetup: Codeunit "Workflow Setup";
        PurchaseCreditMemos: TestPage "Purchase Credit Memos";
    begin
        // [SCENARIO] The user cannot release a purchase credit memo when the approval workflow is enabled and the purchase credit memo is not approved.
        // [GIVEN] There is a purchase credit memo that is not approved.
        // [GIVEN] The approval workflow for puchase credit memo is enabled.
        // [WHEN] The user wants to Release the purchase credit memo.
        // [THEN] The user will get an error that he cannot release a purchase credit memo that is not approved.

        // Setup
        Initialize();

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseCreditMemoApprovalWorkflowCode());

        CreatePurchaseCreditMemo(PurchaseHeader);

        // Exercise
        PurchaseCreditMemos.OpenView();
        PurchaseCreditMemos.GotoRecord(PurchaseHeader);
        asserterror PurchaseCreditMemos.Release.Invoke();

        // Verify
        Assert.ExpectedError(DocCannotBeReleasedErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CannotReleasePurchaseCreditMemoApprovalIsPending()
    var
        Workflow: Record Workflow;
        PurchaseHeader: Record "Purchase Header";
        IntermediateApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // [SCENARIO] The user cannot release a purchase credit memo when the approval workflow is enabled and the purchase credit memo is pending approval.
        // [GIVEN] There is a purchase credit memo that is sent for approval.
        // [GIVEN] The approval workflow for puchase credit memos is enabled.
        // [WHEN] The user wants to Release the purchase credit memo.
        // [THEN] The user will get an error that he cannot release the purchase credit memo that is not approved.

        // Setup
        Initialize();
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseCreditMemoApprovalWorkflowCode());

        // Setup - Create 3 approval usersetups
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        // Setup - Create purchase credit memo
        CreatePurchCrMemoWithLine(PurchaseHeader, LibraryRandom.RandInt(5000));

        // Setup - Update Purchaser Code
        SetPurchDocPurchaserCode(PurchaseHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        // Excercise - Open Purchase credit memo card and sent it for approval
        SendPurchaseCrMemoForApproval(PurchaseHeader);

        // Verify - Purchase credit memo status is set to Pending Approval
        VerifyPurchaseCrMemoIsPendingApproval(PurchaseHeader);

        // Exercise
        Commit();
        PurchaseCreditMemo.OpenView();
        PurchaseCreditMemo.GotoRecord(PurchaseHeader);
        asserterror PurchaseCreditMemo.Release.Invoke();

        // Verify
        Assert.ExpectedError(StrSubstNo(RecordIsRestrictedErr, Format(PurchaseHeader.RecordId, 0, 1)));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CannotReopenPurchaseCreditMemoApprovalIsPending()
    var
        Workflow: Record Workflow;
        PurchaseHeader: Record "Purchase Header";
        IntermediateApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // [SCENARIO] The user cannot release a purchase credit memo when the approval workflow is enabled and the purchase credit memo is pending approval.
        // [GIVEN] There is a purchase credit memo that is sent for approval.
        // [GIVEN] The approval workflow for puchase credit memos is enabled.
        // [WHEN] The user wants to Reopen the purchase credit memo.
        // [THEN] The user will get an error that he cannot reopen the purchase credit memo.

        // Setup
        Initialize();
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseCreditMemoApprovalWorkflowCode());

        // Setup - Create 3 approval usersetups
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        // Setup - Create purchase credit memo
        CreatePurchCrMemoWithLine(PurchaseHeader, LibraryRandom.RandInt(5000));

        // Setup - Update Purchaser Code
        SetPurchDocPurchaserCode(PurchaseHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        // Excercise - Open Purchase credit memo card and sent it for approval
        SendPurchaseCrMemoForApproval(PurchaseHeader);

        // Verify - Purchase credit memo status is set to Pending Approval
        VerifyPurchaseCrMemoIsPendingApproval(PurchaseHeader);

        // Exercise
        PurchaseCreditMemo.OpenView();
        PurchaseCreditMemo.GotoRecord(PurchaseHeader);
        asserterror PurchaseCreditMemo.Reopen.Invoke();

        // Verify
        Assert.ExpectedError(ApprovalShouldBeHandledErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoApprovalWorkflowOnApprovePath()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        PurchHeader: Record "Purchase Header";
        IntermediateApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [SCENARIO] This test verifies E2E scenario for the purchase credit memo approval workflow on approval path.
        // [GIVEN] Purchase credit memo Approval Workflow that has Purchaser as the IntermediateApprover and No Limit as the limit type.
        // [WHEN] Purchase credit memo is sent for approval.
        // [THEN] Approval Request is created for the purchaser.
        // [WHEN] Purchaser approves the approval request.
        // [THEN] Purchase credit memo is released.

        Initialize();

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseCreditMemoApprovalWorkflowCode());

        // Setup - Create 3 usersetups
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        // Setup - Create purchase credit memo
        CreatePurchCrMemoWithLine(PurchHeader, LibraryRandom.RandInt(5000));

        // Setup - Update Purchaser Code
        SetPurchDocPurchaserCode(PurchHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        // Excercise - Open Purchase credit memo card and sent it for approval
        SendPurchaseCrMemoForApproval(PurchHeader);

        // Verify - Purchase credit memo status is set to Pending Approval
        VerifyPurchaseCrMemoIsPendingApproval(PurchHeader);

        // Verify - Approval requests and their data
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchHeader.RecordId);
        Assert.AreEqual(1, ApprovalEntry.Count, 'Unexpected number of approval entries found');

        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, UserId);
        VerifyApprovalEntryApproverID(ApprovalEntry, IntermediateApproverUserSetup."User ID");

        // Setup - Assign the approval entry to current user so that it can be approved
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(PurchHeader.RecordId);

        // Excercise - Open Purchae credit memo card and approve the approval request
        ApprovePurchaseCrMemo(PurchHeader);

        // Verify - Approval requests and their data
        VerifyPurchaseCrMemoIsReleased(PurchHeader);
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchHeader.RecordId);
        VerifyApprovalEntryIsApproved(ApprovalEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoApprovalWorkflowOnRejectionPath()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        PurchHeader: Record "Purchase Header";
        IntermediateApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [SCENARIO] This test verifies E2E scenario for the purchase credit memo approval workflow on rejection path.
        // [GIVEN] Purchase credit memo Approval Workflow that has Purchaser as the IntermediateApprover and No Limit as the limit type.
        // [WHEN] Purchase credit memo is sent for approval.
        // [THEN] Approval Request is created for the purchaser.
        // [WHEN] Purchaser rejects the approval request.
        // [THEN] Purchase credit memo is reopened and approval entries are marked as rejected.

        Initialize();

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseCreditMemoApprovalWorkflowCode());

        // Setup - Create 3 usersetups
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        // Setup - Create purchase credit memo
        CreatePurchCrMemoWithLine(PurchHeader, LibraryRandom.RandInt(5000));

        // Setup - Update Purchaser Code
        SetPurchDocPurchaserCode(PurchHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        // Excercise - Open Purchase credit memo card and sent it for approval
        SendPurchaseCrMemoForApproval(PurchHeader);

        // Verify - Purchase credit memo status is set to Pending Approval
        VerifyPurchaseCrMemoIsPendingApproval(PurchHeader);

        // Verify - Approval requests and their data
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchHeader.RecordId);
        Assert.AreEqual(1, ApprovalEntry.Count, 'Unexpected number of approval entries found');

        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, UserId);
        VerifyApprovalEntryApproverID(ApprovalEntry, IntermediateApproverUserSetup."User ID");

        // Assign the approval entry to current user so that it can be approved
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(PurchHeader.RecordId);

        // Excercise - Open Purchae credit memo card and reject the approval request
        RejectPurchaseCrMemo(PurchHeader);

        // Verify - Approval requests and their data
        VerifyPurchaseCrMemoIsOpen(PurchHeader);
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchHeader.RecordId);
        VerifyApprovalEntryIsRejected(ApprovalEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoApprovalWorkflowOnDelegationPath()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        PurchHeader: Record "Purchase Header";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [SCENARIO] This test verifies E2E scenario for the purchase credit memo approval workflow on delegation path.
        // [GIVEN] Purchase credit memo Approval Workflow that has Purchaser as the IntermediateApprover and No Limit as the limit type.
        // [WHEN] Purchase credit memo is sent for approval.
        // [THEN] Approval Request is created for the purchaser.
        // [WHEN] Purchaser delegates the approval request.
        // [THEN] Approval request is assigned to the substitute.
        // [WHEN] Approval Request is approved.
        // [THEN] Purchase credit memo is released.

        Initialize();

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseCreditMemoApprovalWorkflowCode());

        // Setup - Create 3 usersetups
        LibraryDocumentApprovals.CreateOrFindUserSetup(CurrentUserSetup, UserId);
        LibraryDocumentApprovals.CreateMockupUserSetup(IntermediateApproverUserSetup);
        LibraryDocumentApprovals.CreateMockupUserSetup(FinalApproverUserSetup);

        // Setup - Chain of IntermediateApprovers
        LibraryDocumentApprovals.SetApprover(CurrentUserSetup, IntermediateApproverUserSetup);
        LibraryDocumentApprovals.SetApprover(IntermediateApproverUserSetup, FinalApproverUserSetup);
        LibraryDocumentApprovals.SetSubstitute(CurrentUserSetup, FinalApproverUserSetup);

        // Setup - Create purchase credit memo
        CreatePurchCrMemoWithLine(PurchHeader, LibraryRandom.RandInt(5000));

        // Setup - Update Purchaser Code
        SetPurchDocPurchaserCode(PurchHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        // Excercise - Open Purchase credit memo card and sent it for approval
        SendPurchaseCrMemoForApproval(PurchHeader);

        // Verify - Purchase credit memo status is set to Pending Approval
        VerifyPurchaseCrMemoIsPendingApproval(PurchHeader);

        // Verify - Approval requests and their data
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchHeader.RecordId);
        Assert.AreEqual(1, ApprovalEntry.Count, 'Unexpected number of approval entries found');

        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, CurrentUserSetup."User ID");
        VerifyApprovalEntryApproverID(ApprovalEntry, IntermediateApproverUserSetup."User ID");

        // Assign the approval entry to current user so that it can be approved
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(PurchHeader.RecordId);

        // Excercise - Open Purchae credit memo card and delgate the approval request
        DelegatePurchaseCrMemo(PurchHeader);

        // Verify - Approval requests and their data
        VerifyPurchaseCrMemoIsPendingApproval(PurchHeader);
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchHeader.RecordId);
        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntryApproverID(ApprovalEntry, FinalApproverUserSetup."User ID");

        // Assign the approval entry to current user so that it can be approved
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(PurchHeader.RecordId);

        // Excercise - Open Purchae credit memo card and approve the approval request
        ApprovePurchaseCrMemo(PurchHeader);

        // Verify - Approval requests and their data
        VerifyPurchaseCrMemoIsReleased(PurchHeader);
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchHeader.RecordId);
        VerifyApprovalEntryIsApproved(ApprovalEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoApprovalWorkflowOnCancellationPath()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        PurchHeader: Record "Purchase Header";
        IntermediateApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [SCENARIO] This test verifies E2E scenario for the purchase credit memo approval workflow on cancellation path.
        // [GIVEN] Purchase credit memo Approval Workflow that has Purchaser as the IntermediateApprover and No Limit as the limit type.
        // [WHEN] Purchase credit memo is sent for approval.
        // [THEN] Approval Request is created for the purchaser.
        // [WHEN] Sender cancels the approval request.
        // [THEN] Purchase credit memo is opend and approval requests are marked as cancelled.

        Initialize();

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseCreditMemoApprovalWorkflowCode());

        // Setup - Create 3 usersetups
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        // Setup - Create purchase credit memo
        CreatePurchCrMemoWithLine(PurchHeader, LibraryRandom.RandInt(5000));

        // Setup - Update Purchaser Code
        SetPurchDocPurchaserCode(PurchHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        // Excercise - Open Purchase credit memo card and sent it for approval
        SendPurchaseCrMemoForApproval(PurchHeader);

        // Verify - Purchase credit memo status is set to Pending Approval
        VerifyPurchaseCrMemoIsPendingApproval(PurchHeader);

        // Verify - Approval requests and their data
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchHeader.RecordId);
        Assert.AreEqual(1, ApprovalEntry.Count, 'Unexpected number of approval entries found');

        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, UserId);
        VerifyApprovalEntryApproverID(ApprovalEntry, IntermediateApproverUserSetup."User ID");

        // Excercise - Open Purchae credit memo card and approve the approval request
        CancelPurchaseCrMemo(PurchHeader);

        // Verify - Approval requests and their data
        VerifyPurchaseCrMemoIsOpen(PurchHeader);
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchHeader.RecordId);
        VerifyApprovalEntryIsCancelled(ApprovalEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandlerValidateMessage')]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoApprovalActionsVisibilityOnCardTest()
    var
        PurchHeader: Record "Purchase Header";
        Workflow: Record Workflow;
        ApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // [SCENARIO 3] Approval action availability.
        // [GIVEN] Purchase Header approval disabled.
        Initialize();

        // [WHEN] Purchase Header card is opened.
        CreatePurchaseCreditMemo(PurchHeader);
        Commit();
        PurchaseCreditMemo.OpenEdit();
        PurchaseCreditMemo.GotoRecord(PurchHeader);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(PurchaseCreditMemo.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(PurchaseCreditMemo.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should NOT be enabled');

        // [WHEN] Send Approval Request is pushed.
        asserterror PurchaseCreditMemo.SendApprovalRequest.Invoke();

        // [THEN] Error is displayed.
        Assert.ExpectedError(NoWorkflowEnabledErr);

        // Cleanup
        PurchaseCreditMemo.Close();

        // [GIVEN] PurchHeader approval enabled.
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseCreditMemoApprovalWorkflowCode());

        // [WHEN] PurchHeader card is opened.
        PurchaseCreditMemo.OpenEdit();
        PurchaseCreditMemo.GotoRecord(PurchHeader);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(PurchaseCreditMemo.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(PurchaseCreditMemo.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');
        Assert.IsFalse(PurchaseCreditMemo.Approve.Visible(), 'Approve should NOT be visible');
        Assert.IsFalse(PurchaseCreditMemo.Reject.Visible(), 'Reject should NOT be visible');
        Assert.IsFalse(PurchaseCreditMemo.Delegate.Visible(), 'Delegate should NOT be visible');
        PurchaseCreditMemo.Close();

        // [GIVEN] Approval exist on PurchHeader.
        LibraryDocumentApprovals.SetupUsersForApprovals(ApproverUserSetup);
        SetPurchDocPurchaserCode(PurchHeader, ApproverUserSetup."Salespers./Purch. Code");
        PurchaseCreditMemo.OpenEdit();
        PurchaseCreditMemo.GotoRecord(PurchHeader);

        // [WHEN] PurchHeader send for approval.
        LibraryVariableStorage.Enqueue(ApprovalRequestSendMsg);
        PurchaseCreditMemo.SendApprovalRequest.Invoke();

        // [THEN] Only Send is enabled.
        Assert.IsFalse(PurchaseCreditMemo.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be disabled');
        Assert.IsTrue(PurchaseCreditMemo.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be enabled');

        // Clenup
        PurchaseCreditMemo.Close();

        // Setup the approval so it can be approve by current user
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(PurchHeader.RecordId);

        // [WHEN] PurchHeader card is opened.
        PurchaseCreditMemo.OpenEdit();
        PurchaseCreditMemo.GotoRecord(PurchHeader);

        // [THEN] Approval action are shown.
        Assert.IsTrue(PurchaseCreditMemo.Approve.Visible(), 'Approve should be visible');
        Assert.IsTrue(PurchaseCreditMemo.Reject.Visible(), 'Reject should be visible');
        Assert.IsTrue(PurchaseCreditMemo.Delegate.Visible(), 'Delegate should be visible');
    end;

    [Test]
    [HandlerFunctions('MessageHandlerValidateMessage')]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoApprovalActionsVisibilityOnListTest()
    var
        PurchHeader: Record "Purchase Header";
        Workflow: Record Workflow;
        ApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
        PurchaseCreditMemos: TestPage "Purchase Credit Memos";
    begin
        // [SCENARIO 3] Approval action availability.
        // [GIVEN] PurchHeader approval disabled.
        Initialize();

        // [WHEN] PurchHeader card is opened.
        CreatePurchaseCreditMemo(PurchHeader);
        Commit();
        PurchaseCreditMemos.OpenEdit();
        PurchaseCreditMemos.GotoRecord(PurchHeader);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(PurchaseCreditMemos.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(PurchaseCreditMemos.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');

        // [WHEN] Send Approval Request is pushed.
        asserterror PurchaseCreditMemos.SendApprovalRequest.Invoke();

        // [THEN] Error is displayed.
        Assert.ExpectedError(NoWorkflowEnabledErr);

        // Cleanup
        PurchaseCreditMemos.Close();

        // [GIVEN] PurchHeader approval enabled.
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseCreditMemoApprovalWorkflowCode());

        // [WHEN] PurchHeader card is opened.
        PurchaseCreditMemos.OpenEdit();
        PurchaseCreditMemos.GotoRecord(PurchHeader);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(PurchaseCreditMemos.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(PurchaseCreditMemos.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');
        PurchaseCreditMemos.Close();

        // [GIVEN] Approval exist on PurchHeader.
        LibraryDocumentApprovals.SetupUsersForApprovals(ApproverUserSetup);
        SetPurchDocPurchaserCode(PurchHeader, ApproverUserSetup."Salespers./Purch. Code");
        PurchaseCreditMemos.OpenEdit();
        PurchaseCreditMemos.GotoRecord(PurchHeader);

        // [WHEN] PurchHeader send for approval.
        LibraryVariableStorage.Enqueue(ApprovalRequestSendMsg);
        PurchaseCreditMemos.SendApprovalRequest.Invoke();

        // [THEN] Only Send is enabled.
        Assert.IsFalse(PurchaseCreditMemos.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be disabled');
        Assert.IsTrue(PurchaseCreditMemos.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be enabled');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoApprovalWorkflowApprovePathAddComments()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        PurchaseHeader: Record "Purchase Header";
        IntermediateApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [SCENARIO] This test verifies E2E scenario for the Purchase Credit Memo approval workflow on approval path and adds a comment for each step.
        // [GIVEN] Purchase Credit Memo Approval Workflow that has Purchaser as the approver and No Limit as the limit type.
        // [WHEN] Purchase Credit Memo is sent for approval.
        // [THEN] Approval Request is created for the Purchaser and the user can add a comment.
        // [WHEN] Purchaser approves the approval request.
        // [THEN] Purchase Credit Memo is released.

        Initialize();

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseCreditMemoApprovalWorkflowCode());

        // Setup - Create 3 approval usersetups
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        // Setup - Create Purchase Credit Memo
        CreatePurchCrMemoWithLine(PurchaseHeader, LibraryRandom.RandInt(5000));

        // Setup - Update Purchaser Code
        SetPurchDocPurchaserCode(PurchaseHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        CheckCommentsForDocumentOnDocumentCard(PurchaseHeader, 0, false);

        // Excercise - Open Purchase Credit Memo card and sent it for approval
        SendPurchaseCrMemoForApproval(PurchaseHeader);

        CheckCommentsForDocumentOnDocumentCard(PurchaseHeader, 0, false);

        // Verify - Purchase Credit Memo status is set to Pending Approval
        VerifyPurchaseCrMemoIsPendingApproval(PurchaseHeader);

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

        // Excercise - Open Purchase Credit Memo card and approve the approval request
        ApprovePurchaseCrMemo(PurchaseHeader);

        // Verify - Approval requests and their data
        VerifyPurchaseCrMemoIsReleased(PurchaseHeader);
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchaseHeader.RecordId);
        VerifyApprovalEntryIsApproved(ApprovalEntry);
        CheckCommentsForDocumentOnApprovalEntriesPage(ApprovalEntry, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoApprovalWorkflowTestUserCanCancel()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        PurchaseHeader: Record "Purchase Header";
        IntermediateApproverUserSetup: Record "User Setup";
        UserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [SCENARIO] This test verifies E2E scenario for the Purchase Credit Memo approval workflow on cancellation path and whether a user can cancel the workflow or not.
        // [GIVEN] Purchase Credit Memo Approval Workflow that has Purchaser as the approver and No Limit as the limit type.
        // [WHEN] Purchase Credit Memo is sent for approval.
        // [THEN] Approval Request is created for the Purchaser and user can cancel the request.
        // [WHEN] Next approver opens the document.
        // [THEN] The user can only cancel the request if he is an approval administrator.

        Initialize();

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseCreditMemoApprovalWorkflowCode());

        // Setup - Create 3 approval usersetups
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        // Setup - Create Purchase Credit Memo
        CreatePurchCrMemoWithLine(PurchaseHeader, LibraryRandom.RandInt(5000));

        // Setup - Update Purchaser Code
        SetPurchDocPurchaserCode(PurchaseHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        // Excercise - Open Purchase Credit Memo card and sent it for approval
        SendPurchaseCrMemoForApproval(PurchaseHeader);

        // Verify - User can cancel the approval request
        CheckUserCanCancelTheApprovalRequest(PurchaseHeader, true);

        // Verify - Purchase Credit Memo status is set to Pending Approval
        VerifyPurchaseCrMemoIsPendingApproval(PurchaseHeader);

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

        // Excercise - Open Purchase Credit Memo card and cancel the approval request
        CancelPurchaseCrMemo(PurchaseHeader);

        // Verify - Approval requests and their data
        VerifyPurchaseCrMemoIsOpen(PurchaseHeader);
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
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"WF Demo Purch CrMemo Approvals");
        LibraryVariableStorage.Clear();
        UserSetup.DeleteAll();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryWorkflow.DisableAllWorkflows();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"WF Demo Purch CrMemo Approvals");
        IsInitialized := true;
        BindSubscription(LibraryJobQueue);
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"WF Demo Purch CrMemo Approvals");
    end;

    local procedure CreatePurchaseCreditMemo(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, '', LibraryRandom.RandInt(100));
    end;

    local procedure CreatePurchCrMemoWithLine(var PurchHeader: Record "Purchase Header"; Amount: Decimal)
    var
        PurchLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::"Credit Memo", '');
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

    local procedure SendPurchaseCrMemoForApproval(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        PurchaseCreditMemo.OpenView();
        PurchaseCreditMemo.GotoRecord(PurchaseHeader);
        PurchaseCreditMemo.SendApprovalRequest.Invoke();
        PurchaseCreditMemo.Close();
    end;

    local procedure RegetPurchaseDocument(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.SetRecFilter();
        PurchaseHeader.FindFirst();
    end;

    local procedure VerifyPurchaseCrMemoIsReleased(var PurchaseHeader: Record "Purchase Header")
    begin
        RegetPurchaseDocument(PurchaseHeader);
        PurchaseHeader.TestField(Status, PurchaseHeader.Status::Released);
    end;

    local procedure VerifyPurchaseCrMemoIsOpen(var PurchaseHeader: Record "Purchase Header")
    begin
        RegetPurchaseDocument(PurchaseHeader);
        PurchaseHeader.TestField(Status, PurchaseHeader.Status::Open);
    end;

    local procedure VerifyPurchaseCrMemoIsPendingApproval(var PurchaseHeader: Record "Purchase Header")
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

    local procedure ApprovePurchaseCrMemo(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        PurchaseCreditMemo.OpenView();
        PurchaseCreditMemo.GotoRecord(PurchaseHeader);
        PurchaseCreditMemo.Approve.Invoke();
        PurchaseCreditMemo.Close();
    end;

    local procedure RejectPurchaseCrMemo(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        PurchaseCreditMemo.OpenView();
        PurchaseCreditMemo.GotoRecord(PurchaseHeader);
        PurchaseCreditMemo.Reject.Invoke();
        PurchaseCreditMemo.Close();
    end;

    local procedure DelegatePurchaseCrMemo(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        PurchaseCreditMemo.OpenView();
        PurchaseCreditMemo.GotoRecord(PurchaseHeader);
        PurchaseCreditMemo.Delegate.Invoke();
        PurchaseCreditMemo.Close();
    end;

    local procedure CancelPurchaseCrMemo(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        PurchaseCreditMemo.OpenView();
        PurchaseCreditMemo.GotoRecord(PurchaseHeader);
        PurchaseCreditMemo.CancelApprovalRequest.Invoke();
        PurchaseCreditMemo.Close();
    end;

    local procedure SetPurchDocPurchaserCode(PurchaseHeader: Record "Purchase Header"; PurchaserCode: Code[20])
    begin
        PurchaseHeader.Validate("Purchaser Code", PurchaserCode);
        PurchaseHeader.Modify(true);
    end;

    local procedure CheckCommentsForDocumentOnDocumentCard(PurchaseHeader: Record "Purchase Header"; NumberOfExpectedComments: Integer; CommentActionIsVisible: Boolean)
    var
        ApprovalComments: TestPage "Approval Comments";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        NumberOfComments: Integer;
    begin
        ApprovalComments.Trap();

        PurchaseCreditMemo.OpenView();
        PurchaseCreditMemo.GotoRecord(PurchaseHeader);

        Assert.AreEqual(CommentActionIsVisible, PurchaseCreditMemo.Comment.Visible(), 'The Comments action has the wrong visibility');

        if CommentActionIsVisible then begin
            PurchaseCreditMemo.Comment.Invoke();
            if ApprovalComments.First() then
                repeat
                    NumberOfComments += 1;
                until ApprovalComments.Next();
            Assert.AreEqual(NumberOfExpectedComments, NumberOfComments, 'The page contains the wrong number of comments');

            ApprovalComments.Comment.SetValue('Test Comment' + Format(NumberOfExpectedComments));
            ApprovalComments.Next();
            ApprovalComments.Close();
        end;

        PurchaseCreditMemo.Close();
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
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        PurchaseCreditMemos: TestPage "Purchase Credit Memos";
    begin
        PurchaseCreditMemo.OpenView();
        PurchaseCreditMemo.GotoRecord(PurchaseHeader);
        Assert.AreEqual(CancelActionExpectedEnabled, PurchaseCreditMemo.CancelApprovalRequest.Enabled(),
          'Wrong state for the Cancel action');
        PurchaseCreditMemo.Close();

        PurchaseCreditMemos.OpenView();
        PurchaseCreditMemos.GotoRecord(PurchaseHeader);
        Assert.AreEqual(CancelActionExpectedEnabled, PurchaseCreditMemos.CancelApprovalRequest.Enabled(),
          'Wrong state for the Cancel action');
        PurchaseCreditMemos.Close();
    end;
}

