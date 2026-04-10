codeunit 134187 "WF Demo General Journal Batch"
{
    EventSubscriberInstance = Manual;
    Permissions = TableData "Approval Entry" = rimd;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Workflow] [Approval]
    end;

    var
        Assert: Codeunit Assert;
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWorkflow: Codeunit "Library - Workflow";
        WorkflowSetup: Codeunit "Workflow Setup";
        DialogTok: Label 'Dialog';
        ApprovalRequestExistsErr: Label 'An approval request already exists.';
        LibraryJobQueue: Codeunit "Library - Job Queue";
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure DirectApproverApprovesRequest()
    var
        ApprovalEntry: Record "Approval Entry";
        ApproverUserSetup: Record "User Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        RequestorUserSetup: Record "User Setup";
        Workflow: Record Workflow;
    begin
        // [SCENARIO] Approve a pending request to approve a journal batch
        // [GIVEN] Journal batch with one line
        // [GIVEN] Approval entry exists for the journal batch
        // [WHEN] Direct approver clicks the Approve action
        // [THEN] Approval entry is approved
        Initialize();

        // Setup
        CreateDirectApprovalEnabledWorkflow(Workflow);
        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);

        // Exercise
        Commit();
        SendApprovalRequestForGeneralJournal(GenJournalBatch.Name);

        // Verify
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalBatch.RecordId);
        VerifyOpenApprovalEntry(ApprovalEntry, ApproverUserSetup, RequestorUserSetup);

        // Setup
        AssignApprovalEntry(ApprovalEntry, RequestorUserSetup);

        // Exercise
        Approve(ApprovalEntry);

        // Verify
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalBatch.RecordId);
        VerifyApprovalEntryIsApproved(ApprovalEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure DirectApproverRejectsRequest()
    var
        ApprovalEntry: Record "Approval Entry";
        ApproverUserSetup: Record "User Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        RequestorUserSetup: Record "User Setup";
        Workflow: Record Workflow;
        NotificationEntry: Record "Notification Entry";
    begin
        // [SCENARIO] Reject a pending request to approve a journal batch
        // [GIVEN] Journal batch with one line
        // [GIVEN] Approval entry exists for the journal batch
        // [WHEN] Direct approver clicks the Reject action
        // [THEN] Approval entry is rejected
        // [THEN] "Send" + "Rejected" notification entries created
        Initialize();

        // Setup
        CreateDirectApprovalEnabledWorkflow(Workflow);
        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);

        // Exercise
        Commit();
        SendApprovalRequestForGeneralJournal(GenJournalBatch.Name);
        RunNotificationEntryDispatcher();

        // Verify
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalBatch.RecordId);
        VerifyOpenApprovalEntry(ApprovalEntry, ApproverUserSetup, RequestorUserSetup);

        // Setup
        AssignApprovalEntry(ApprovalEntry, RequestorUserSetup);

        // Exercise
        Reject(ApprovalEntry);

        // Verify
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalBatch.RecordId);
        VerifyApprovalEntryIsRejected(ApprovalEntry);

        NotificationEntry.Init();
        NotificationEntry.SetRange("Triggered By Record", ApprovalEntry.RecordId);
        Assert.RecordCount(NotificationEntry, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure DirectApproverDelegatesRequest()
    var
        ApprovalEntry: Record "Approval Entry";
        ApproverUserSetup: Record "User Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        RequestorUserSetup: Record "User Setup";
        SubstituteUserSetup: Record "User Setup";
        Workflow: Record Workflow;
    begin
        // [SCENARIO] Delegate a request to approve a journal batch
        // [GIVEN] Journal batch with one line
        // [GIVEN] Approval entry exists for the journal batch
        // [WHEN] Direct approver clicks the Delegate action
        // [THEN] Approval entry is delegated to the substitute
        Initialize();

        // Setup
        CreateDirectApprovalEnabledWorkflow(Workflow);
        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);

        // Exercise
        Commit();
        SendApprovalRequestForGeneralJournal(GenJournalBatch.Name);

        // Verify
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalBatch.RecordId);
        VerifyOpenApprovalEntry(ApprovalEntry, ApproverUserSetup, RequestorUserSetup);

        // Setup
        AssignApprovalEntry(ApprovalEntry, RequestorUserSetup);
        LibraryDocumentApprovals.CreateMockupUserSetup(SubstituteUserSetup);
        LibraryDocumentApprovals.SetSubstitute(RequestorUserSetup, SubstituteUserSetup);

        // Exercise
        Delegate(ApprovalEntry);

        // Verify
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalBatch.RecordId);
        VerifyOpenApprovalEntry(ApprovalEntry, SubstituteUserSetup, ApproverUserSetup);

        // Setup
        AssignApprovalEntry(ApprovalEntry, RequestorUserSetup);

        // Exercise
        Approve(ApprovalEntry);

        // Verify
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalBatch.RecordId);
        VerifyApprovalEntryIsApproved(ApprovalEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure RequestorCancelsRequestToDirectApprover()
    var
        ApprovalEntry: Record "Approval Entry";
        ApproverUserSetup: Record "User Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        RequestorUserSetup: Record "User Setup";
        Workflow: Record Workflow;
    begin
        // [SCENARIO] Cancel a pending request to approve a journal batch
        // [GIVEN] Journal batch with line
        // [GIVEN] Approval entry exists for the journal batch
        // [WHEN] Requestor clicks the Cancel action
        // [THEN] Approval entry is canceled
        Initialize();

        // Setup
        CreateDirectApprovalEnabledWorkflow(Workflow);
        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);
        CheckUserCanCancelTheApprovalRequestForAGeneralJnlBatch(GenJournalBatch, false);

        // Exercise
        Commit();
        SendApprovalRequestForGeneralJournal(GenJournalBatch.Name);

        // Verify
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalBatch.RecordId);
        VerifyOpenApprovalEntry(ApprovalEntry, ApproverUserSetup, RequestorUserSetup);
        CheckUserCanCancelTheApprovalRequestForAGeneralJnlBatch(GenJournalBatch, true);

        // Exercise
        CancelApprovalRequestForGeneralJournal(GenJournalBatch.Name);

        // Verify
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalBatch.RecordId);
        VerifyApprovalEntryIsCancelled(ApprovalEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure RequestorCancelsCashReceiptRequestToDirectApprover()
    var
        ApprovalEntry: Record "Approval Entry";
        ApproverUserSetup: Record "User Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        RequestorUserSetup: Record "User Setup";
        Workflow: Record Workflow;
    begin
        // [SCENARIO] Cancel a pending request to approve a journal batch
        // [GIVEN] Journal batch with line
        // [GIVEN] Approval entry exists for the journal batch
        // [WHEN] Requestor clicks the Cancel action
        // [THEN] Approval entry is canceled
        Initialize();

        // Setup
        CreateDirectApprovalEnabledWorkflow(Workflow);
        CreateCashReceiptJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);
        CheckUserCanCancelTheApprovalRequestForACashReceiptJnlBatch(GenJournalBatch, false);

        // Exercise
        Commit();
        SendApprovalRequestForCashReceipt(GenJournalBatch.Name);

        // Verify
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalBatch.RecordId);
        VerifyOpenApprovalEntry(ApprovalEntry, ApproverUserSetup, RequestorUserSetup);
        CheckUserCanCancelTheApprovalRequestForACashReceiptJnlBatch(GenJournalBatch, true);

        // Exercise
        CancelApprovalRequestForCashReceipt(GenJournalBatch.Name);

        // Verify
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalBatch.RecordId);
        VerifyApprovalEntryIsCancelled(ApprovalEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure RequestorCancelsPaymentRequestToDirectApprover()
    var
        ApprovalEntry: Record "Approval Entry";
        ApproverUserSetup: Record "User Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        RequestorUserSetup: Record "User Setup";
        Workflow: Record Workflow;
    begin
        // [SCENARIO] Cancel a pending request to approve a journal batch
        // [GIVEN] Journal batch with line
        // [GIVEN] Approval entry exists for the journal batch
        // [WHEN] Requestor clicks the Cancel action
        // [THEN] Approval entry is canceled
        Initialize();

        // Setup
        CreateDirectApprovalEnabledWorkflow(Workflow);
        CreatePaymentJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);
        CheckUserCanCancelTheApprovalRequestForAPaymentJnlBatch(GenJournalBatch, false);

        // Exercise
        Commit();
        SendApprovalRequestForPaymentJournal(GenJournalBatch.Name);

        // Verify
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalBatch.RecordId);
        VerifyOpenApprovalEntry(ApprovalEntry, ApproverUserSetup, RequestorUserSetup);
        CheckUserCanCancelTheApprovalRequestForAPaymentJnlBatch(GenJournalBatch, true);

        // Exercise
        CancelApprovalRequestForPaymentJournal(GenJournalBatch.Name);

        // Verify
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalBatch.RecordId);
        VerifyApprovalEntryIsCancelled(ApprovalEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure DirectApproverApprovesRequestWithComment()
    var
        ApprovalEntry: Record "Approval Entry";
        ApproverUserSetup: Record "User Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        RequestorUserSetup: Record "User Setup";
        Workflow: Record Workflow;
    begin
        // [SCENARIO] Approve a pending request to approve a journal batch
        // [GIVEN] Journal batch with one line
        // [GIVEN] Approval entry exists for the journal batch
        // [WHEN] Direct approver clicks the Approve action
        // [THEN] Approval entry is approved
        Initialize();

        // Setup
        CreateDirectApprovalEnabledWorkflow(Workflow);
        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);
        CheckCommentsForDocumentOnGeneralJournalPage(GenJournalBatch, 0, false);

        // Exercise
        Commit();
        SendApprovalRequestForGeneralJournal(GenJournalBatch.Name);

        // Verify
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalBatch.RecordId);
        VerifyOpenApprovalEntry(ApprovalEntry, ApproverUserSetup, RequestorUserSetup);

        // Setup
        AssignApprovalEntry(ApprovalEntry, RequestorUserSetup);
        CheckCommentsForDocumentOnGeneralJournalPage(GenJournalBatch, 0, true);
        CheckCommentsForDocumentOnApprovalEntriesPage(ApprovalEntry, 1);
        CheckCommentsForDocumentOnRequestsToApprovePage(ApprovalEntry, 1);
        // Exercise
        Approve(ApprovalEntry);

        // Verify
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalBatch.RecordId);
        VerifyApprovalEntryIsApproved(ApprovalEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure DirectApproverApprovesCashReceiptRequestWithComment()
    var
        ApprovalEntry: Record "Approval Entry";
        ApproverUserSetup: Record "User Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        RequestorUserSetup: Record "User Setup";
        Workflow: Record Workflow;
    begin
        // [SCENARIO] Approve a pending request to approve a journal batch
        // [GIVEN] Journal batch with one line
        // [GIVEN] Approval entry exists for the journal batch
        // [WHEN] Direct approver clicks the Approve action
        // [THEN] Approval entry is approved
        Initialize();

        // Setup
        CreateDirectApprovalEnabledWorkflow(Workflow);
        CreateCashReceiptJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);
        CheckCommentsForDocumentOnCashReceiptPage(GenJournalBatch, 0, false);

        // Exercise
        Commit();
        SendApprovalRequestForCashReceipt(GenJournalBatch.Name);
        CheckCommentsForDocumentOnCashReceiptPage(GenJournalBatch, 0, true);

        // Verify
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalBatch.RecordId);
        VerifyOpenApprovalEntry(ApprovalEntry, ApproverUserSetup, RequestorUserSetup);

        // Setup
        AssignApprovalEntry(ApprovalEntry, RequestorUserSetup);
        CheckCommentsForDocumentOnCashReceiptPage(GenJournalBatch, 1, true);
        CheckCommentsForDocumentOnApprovalEntriesPage(ApprovalEntry, 1);
        CheckCommentsForDocumentOnRequestsToApprovePage(ApprovalEntry, 1);

        // Exercise
        Approve(ApprovalEntry);

        // Verify
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalBatch.RecordId);
        VerifyApprovalEntryIsApproved(ApprovalEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure DirectApproverApprovesPaymentRequestWithComment()
    var
        ApprovalEntry: Record "Approval Entry";
        ApproverUserSetup: Record "User Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        RequestorUserSetup: Record "User Setup";
        Workflow: Record Workflow;
    begin
        // [SCENARIO] Approve a pending request to approve a journal batch
        // [GIVEN] Journal batch with one line
        // [GIVEN] Approval entry exists for the journal batch
        // [WHEN] Direct approver clicks the Approve action
        // [THEN] Approval entry is approved
        Initialize();

        // Setup
        CreateDirectApprovalEnabledWorkflow(Workflow);
        CreatePaymentJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);
        CheckCommentsForDocumentOnPaymentPage(GenJournalBatch, 0, false);

        // Exercise
        Commit();
        SendApprovalRequestForPaymentJournal(GenJournalBatch.Name);
        CheckCommentsForDocumentOnPaymentPage(GenJournalBatch, 0, true);

        // Verify
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalBatch.RecordId);
        VerifyOpenApprovalEntry(ApprovalEntry, ApproverUserSetup, RequestorUserSetup);

        // Setup
        AssignApprovalEntry(ApprovalEntry, RequestorUserSetup);
        CheckCommentsForDocumentOnPaymentPage(GenJournalBatch, 1, true);
        CheckCommentsForDocumentOnApprovalEntriesPage(ApprovalEntry, 1);
        CheckCommentsForDocumentOnRequestsToApprovePage(ApprovalEntry, 1);

        // Exercise
        Approve(ApprovalEntry);

        // Verify
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalBatch.RecordId);
        VerifyApprovalEntryIsApproved(ApprovalEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure DirectApproverApprovesFilteredRequest()
    var
        ApprovalEntry: Record "Approval Entry";
        GenJournalBatch: Record "Gen. Journal Batch";
        ApproverUserSetup: Record "User Setup";
        RequestorUserSetup: Record "User Setup";
        Workflow: Record Workflow;
    begin
        // [SCENARIO] Approve a pending request to approve a journal batch
        // [GIVEN] Journal batch with one or more lines
        // [GIVEN] Subset of the lines are included in the request
        // [GIVEN] Approval entry exists for the journal batch
        // [WHEN] Direct approver clicks the Approve action
        // [THEN] Approval entry is approved
        Initialize();

        // Setup
        CreateDirectApprovalEnabledWorkflow(Workflow);
        CreateJournalBatchWithMultipleJournalLines(GenJournalBatch);
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);

        // Exercise
        Commit();
        SendFilteredApprovalRequest(GenJournalBatch.Name);

        // Verify
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalBatch.RecordId);
        VerifyOpenApprovalEntry(ApprovalEntry, ApproverUserSetup, RequestorUserSetup);

        // Setup
        AssignApprovalEntry(ApprovalEntry, RequestorUserSetup);

        // Exercise
        Approve(ApprovalEntry);

        // Verify
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalBatch.RecordId);
        VerifyApprovalEntryIsApproved(ApprovalEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure DirectApproverRejectsFilteredRequest()
    var
        ApprovalEntry: Record "Approval Entry";
        GenJournalBatch: Record "Gen. Journal Batch";
        ApproverUserSetup: Record "User Setup";
        RequestorUserSetup: Record "User Setup";
        Workflow: Record Workflow;
    begin
        // [SCENARIO] Reject a pending request to approve a journal batch
        // [GIVEN] Journal batch with one or more lines
        // [GIVEN] Subset of the lines are included in the request
        // [GIVEN] Approval entry exists for the journal batch
        // [WHEN] Direct approver clicks the Reject action
        // [THEN] Approval entry is rejected
        Initialize();

        // Setup
        CreateDirectApprovalEnabledWorkflow(Workflow);
        CreateJournalBatchWithMultipleJournalLines(GenJournalBatch);
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);

        // Exercise
        Commit();
        SendFilteredApprovalRequest(GenJournalBatch.Name);

        // Verify
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalBatch.RecordId);
        VerifyOpenApprovalEntry(ApprovalEntry, ApproverUserSetup, RequestorUserSetup);

        // Setup
        AssignApprovalEntry(ApprovalEntry, RequestorUserSetup);

        // Exercise
        Reject(ApprovalEntry);

        // Verify
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalBatch.RecordId);
        VerifyApprovalEntryIsRejected(ApprovalEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure DirectApproverDelegatesFilteredRequest()
    var
        ApprovalEntry: Record "Approval Entry";
        GenJournalBatch: Record "Gen. Journal Batch";
        ApproverUserSetup: Record "User Setup";
        RequestorUserSetup: Record "User Setup";
        SubstituteUserSetup: Record "User Setup";
        Workflow: Record Workflow;
    begin
        // [SCENARIO] Delegate a request to approve a journal batch
        // [GIVEN] Journal batch with one or more lines
        // [GIVEN] Subset of the lines are included in the request
        // [GIVEN] Approval entry exists for the journal batch
        // [WHEN] Direct approver clicks the Delegat action
        // [THEN] Approval entry is delegated to the substitute
        Initialize();

        // Setup
        CreateDirectApprovalEnabledWorkflow(Workflow);
        CreateJournalBatchWithMultipleJournalLines(GenJournalBatch);
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);

        // Exercise
        Commit();
        SendFilteredApprovalRequest(GenJournalBatch.Name);

        // Verify
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalBatch.RecordId);
        VerifyOpenApprovalEntry(ApprovalEntry, ApproverUserSetup, RequestorUserSetup);

        // Setup
        AssignApprovalEntry(ApprovalEntry, RequestorUserSetup);
        LibraryDocumentApprovals.CreateMockupUserSetup(SubstituteUserSetup);
        LibraryDocumentApprovals.SetSubstitute(RequestorUserSetup, SubstituteUserSetup);

        // Exercise
        Delegate(ApprovalEntry);

        // Verify
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalBatch.RecordId);
        VerifyOpenApprovalEntry(ApprovalEntry, SubstituteUserSetup, ApproverUserSetup);

        // Setup
        AssignApprovalEntry(ApprovalEntry, RequestorUserSetup);

        // Exercise
        Approve(ApprovalEntry);

        // Verify
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalBatch.RecordId);
        VerifyApprovalEntryIsApproved(ApprovalEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure RequestorCancelsFilteredRequestToDirectApprover()
    var
        ApprovalEntry: Record "Approval Entry";
        GenJournalBatch: Record "Gen. Journal Batch";
        ApproverUserSetup: Record "User Setup";
        RequestorUserSetup: Record "User Setup";
        Workflow: Record Workflow;
    begin
        // [SCENARIO] Cancel a pending request to approve a journal batch
        // [GIVEN] Journal batch with one or more lines
        // [GIVEN] Subset of the lines are included in the request
        // [GIVEN] Approval entry exists for the journal batch
        // [WHEN] Requestor clicks the Cancel action
        // [THEN] Approval entry is canceled
        Initialize();

        // Setup
        CreateDirectApprovalEnabledWorkflow(Workflow);
        CreateJournalBatchWithMultipleJournalLines(GenJournalBatch);
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);
        CheckUserCanCancelTheApprovalRequestForAGeneralJnlBatch(GenJournalBatch, false);

        // Exercise
        Commit();
        SendFilteredApprovalRequest(GenJournalBatch.Name);

        // Verify
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalBatch.RecordId);
        VerifyOpenApprovalEntry(ApprovalEntry, ApproverUserSetup, RequestorUserSetup);
        CheckUserCanCancelTheApprovalRequestForAGeneralJnlBatch(GenJournalBatch, true);

        // Exercise
        CancelApprovalRequestForGeneralJournal(GenJournalBatch.Name);

        // Verify
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalBatch.RecordId);
        VerifyApprovalEntryIsCancelled(ApprovalEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApprovalActionsVisibilityOnGeneralJournal()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Workflow: Record Workflow;
        ApproverUserSetup: Record "User Setup";
        RequestorUserSetup: Record "User Setup";
        GeneralJournal: TestPage "General Journal";
    begin
        // [SCENARIO] Visibility of approval actions on a journal batch
        Initialize();
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);

        // [GIVEN] Journal batch with one or more lines
        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        // [GIVEN] Workflow is disabled
        CreateDirectApprovalWorkflow(Workflow);

        // [WHEN] User opens the journal batch
        Commit();
        GeneralJournal.OpenEdit();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);

        // [THEN] Approval actions?
        Assert.IsFalse(GeneralJournal.SendApprovalRequestJournalBatch.Enabled(), 'Send should be disabled');
        Assert.IsFalse(GeneralJournal.CancelApprovalRequestJournalBatch.Enabled(), 'Cancel should be disabled');
        Assert.IsFalse(GeneralJournal.SendApprovalRequestJournalLine.Enabled(), 'SendLine should be disabled');
        Assert.IsFalse(GeneralJournal.CancelApprovalRequestJournalLine.Enabled(), 'CancelLine should be disabled');
        Assert.IsFalse(GeneralJournal.Approve.Visible(), '');
        Assert.IsFalse(GeneralJournal.Reject.Visible(), '');
        Assert.IsFalse(GeneralJournal.Delegate.Visible(), '');

        // [THEN] Close the journal
        GeneralJournal.Close();

        // [GIVEN] Workflow is enabled
        EnableWorkflow(Workflow);

        // [WHEN] Approval entry exists for the batch
        CreateOpenApprovalEntryForCurrentUser(GenJournalBatch.RecordId);

        // [WHEN] User opens the journal batch
        Commit();
        GeneralJournal.OpenEdit();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);

        // [THEN] Approval actions?
        Assert.IsFalse(GeneralJournal.SendApprovalRequestJournalBatch.Enabled(), 'Send should be disabled');
        Assert.IsTrue(GeneralJournal.CancelApprovalRequestJournalBatch.Enabled(), 'Cancel should be enabled');
        Assert.IsFalse(GeneralJournal.SendApprovalRequestJournalLine.Enabled(), 'SendLine should be disabled');
        Assert.IsFalse(GeneralJournal.CancelApprovalRequestJournalLine.Enabled(), 'CancelLine should be disabled');
        Assert.IsTrue(GeneralJournal.Approve.Visible(), '');
        Assert.IsTrue(GeneralJournal.Reject.Visible(), '');
        Assert.IsTrue(GeneralJournal.Delegate.Visible(), '');

        // [THEN] Close the journal
        GeneralJournal.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApprovalActionsVisibilityOnPaymentJournal()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Workflow: Record Workflow;
        ApproverUserSetup: Record "User Setup";
        RequestorUserSetup: Record "User Setup";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [SCENARIO] Visibility of approval actions on a journal batch
        Initialize();

        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);

        // [GIVEN] Journal batch with one or more lines
        CreatePaymentJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        // [GIVEN] Workflow is disabled
        CreateDirectApprovalWorkflow(Workflow);

        // [WHEN] User opens the journal batch
        Commit();
        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);

        // [THEN] Approval actions?
        Assert.IsTrue(PaymentJournal.SendApprovalRequestJournalBatch.Enabled(), 'Send should be enabled');
        Assert.IsFalse(PaymentJournal.CancelApprovalRequestJournalBatch.Enabled(), 'Cancel should be disabled');
        Assert.IsTrue(PaymentJournal.SendApprovalRequestJournalLine.Enabled(), 'SendLine should be enabled');
        Assert.IsFalse(PaymentJournal.CancelApprovalRequestJournalLine.Enabled(), 'CancelLine should be disabled');
        Assert.IsFalse(PaymentJournal.Approve.Visible(), '');
        Assert.IsFalse(PaymentJournal.Reject.Visible(), '');
        Assert.IsFalse(PaymentJournal.Delegate.Visible(), '');

        // [THEN] Close the journal
        PaymentJournal.Close();

        // [GIVEN] Workflow is enabled
        EnableWorkflow(Workflow);

        // [WHEN] Approval entry exists for the batch
        CreateOpenApprovalEntryForCurrentUser(GenJournalBatch.RecordId);

        // [WHEN] User opens the journal batch
        Commit();
        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);

        // [THEN] Approval actions?
        Assert.IsFalse(PaymentJournal.SendApprovalRequestJournalBatch.Enabled(), 'Send should be disabled');
        Assert.IsTrue(PaymentJournal.CancelApprovalRequestJournalBatch.Enabled(), 'Cancel should be enabled');
        Assert.IsFalse(PaymentJournal.SendApprovalRequestJournalLine.Enabled(), 'SendLine should be disabled');
        Assert.IsFalse(PaymentJournal.CancelApprovalRequestJournalLine.Enabled(), 'CancelLine should be disabled');
        Assert.IsTrue(PaymentJournal.Approve.Visible(), '');
        Assert.IsTrue(PaymentJournal.Reject.Visible(), '');
        Assert.IsTrue(PaymentJournal.Delegate.Visible(), '');

        // [THEN] Close the journal
        PaymentJournal.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApprovalActionsVisibilityOnCashReceiptJournal()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Workflow: Record Workflow;
        ApproverUserSetup: Record "User Setup";
        RequestorUserSetup: Record "User Setup";
        CashReceiptJournal: TestPage "Cash Receipt Journal";
    begin
        // [SCENARIO] Visibility of approval actions on a journal batch
        Initialize();

        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);

        // [GIVEN] Journal batch with one or more lines
        CreateCashReceiptJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        // [GIVEN] Workflow is disabled
        CreateDirectApprovalWorkflow(Workflow);

        // [WHEN] User opens the journal batch
        Commit();
        CashReceiptJournal.OpenEdit();
        CashReceiptJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);

        // [THEN] Approval actions?
        Assert.IsTrue(CashReceiptJournal.SendApprovalRequestJournalBatch.Enabled(), 'Send should be enabled');
        Assert.IsFalse(CashReceiptJournal.CancelApprovalRequestJournalBatch.Enabled(), 'Cancel should be disabled');
        Assert.IsTrue(CashReceiptJournal.SendApprovalRequestJournalLine.Enabled(), 'SendLine should be enabled');
        Assert.IsFalse(CashReceiptJournal.CancelApprovalRequestJournalLine.Enabled(), 'CancelLine should be disabled');
        Assert.IsFalse(CashReceiptJournal.Approve.Visible(), '');
        Assert.IsFalse(CashReceiptJournal.Reject.Visible(), '');
        Assert.IsFalse(CashReceiptJournal.Delegate.Visible(), '');

        // [THEN] Close the journal
        CashReceiptJournal.Close();

        // [GIVEN] Workflow is enabled
        EnableWorkflow(Workflow);

        // [WHEN] Approval entry exists for the batch
        CreateOpenApprovalEntryForCurrentUser(GenJournalBatch.RecordId);

        // [WHEN] User opens the journal batch
        Commit();
        CashReceiptJournal.OpenEdit();
        CashReceiptJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);

        // [THEN] Approval actions?
        Assert.IsFalse(CashReceiptJournal.SendApprovalRequestJournalBatch.Enabled(), 'Send should be disabled');
        Assert.IsTrue(CashReceiptJournal.CancelApprovalRequestJournalBatch.Enabled(), 'Cancel should be enabled');
        Assert.IsFalse(CashReceiptJournal.SendApprovalRequestJournalLine.Enabled(), 'SendLine should be disabled');
        Assert.IsFalse(CashReceiptJournal.CancelApprovalRequestJournalLine.Enabled(), 'CancelLine should be disabled');
        Assert.IsTrue(CashReceiptJournal.Approve.Visible(), '');
        Assert.IsTrue(CashReceiptJournal.Reject.Visible(), '');
        Assert.IsTrue(CashReceiptJournal.Delegate.Visible(), '');

        // [THEN] Close the journal
        CashReceiptJournal.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TrySendJournalBatchApprovalRequestWhenOpenBatchEntryExists()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Workflow: Record Workflow;
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        // [SCENARIO 377072] Stan cannot send Approval Request for Journal Batch when another Open Approval Request for the Batch already exists
        Initialize();

        // [GIVEN] "Gen. Journal Batch" "B" with Gen. Journal Line "L"
        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        // [GIVEN] Workflow is enabled
        CreateDirectApprovalWorkflow(Workflow);
        EnableWorkflow(Workflow);

        // [GIVEN] Open Approval Request for Gen. Journal Batch "B"
        CreateOpenApprovalEntryForCurrentUser(GenJournalBatch.RecordId);

        asserterror ApprovalsMgmt.TrySendJournalBatchApprovalRequest(GenJournalLine);

        // [THEN] Error thrown: An approval request already exists.
        Assert.ExpectedErrorCode(DialogTok);
        Assert.ExpectedError(ApprovalRequestExistsErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TrySendJournalBatchApprovalRequestWhenOpenLineEntryExists()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Workflow: Record Workflow;
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        // [SCENARIO 377072] Stan cannot send Approval Request for Journal Batch when another Open Approval Request for Journal Line from the Batch already exists
        Initialize();

        // [GIVEN] "Gen. Journal Batch" "B" with Gen. Journal Line "L"
        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        // [GIVEN] Workflow is enabled
        CreateDirectApprovalWorkflow(Workflow);
        EnableWorkflow(Workflow);

        // [GIVEN] Open Approval Request for Gen. Journal Line "L"
        CreateOpenApprovalEntryForCurrentUser(GenJournalLine.RecordId);

        // [WHEN] Send approval request for batch "B"
        asserterror ApprovalsMgmt.TrySendJournalBatchApprovalRequest(GenJournalLine);

        // [THEN] Error thrown: An approval request already exists.
        Assert.ExpectedErrorCode(DialogTok);
        Assert.ExpectedError(ApprovalRequestExistsErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TrySendJournalBatchApprovalRequestWhenNoEntryExists()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Workflow: Record Workflow;
        ApproverUserSetup: Record "User Setup";
        RequestorUserSetup: Record "User Setup";
        ApprovalEntry: Record "Approval Entry";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        // [SCENARIO 377072] Stan can send Approval Request for Journal Batch when Batch and Line requests do not exist
        Initialize();

        // [GIVEN] Journal batch with one or more lines
        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        // [GIVEN] Workflow is enabled
        CreateDirectApprovalWorkflow(Workflow);
        EnableWorkflow(Workflow);

        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);

        // [WHEN] Send Approval Request
        ApprovalsMgmt.TrySendJournalBatchApprovalRequest(GenJournalLine);

        // [THEN] Approval Entry created
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalBatch.RecordId);
        VerifyOpenApprovalEntry(ApprovalEntry, ApproverUserSetup, RequestorUserSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WorkflowInstanceQueryWithoutInstance()
    var
        Workflow: Record Workflow;
        WorkflowInstance: Query "Workflow Instance";
    begin
        // [SCENARIO 381194] "Workflow Instance" query when there are no instances

        // [GIVEN] Workflow templates reinitiated
        LibraryWorkflow.DeleteAllExistingWorkflows();
        WorkflowSetup.InitWorkflow();

        // [GIVEN] Workflow = "X" without steps and instances
        LibraryWorkflow.CreateWorkflow(Workflow);

        // [WHEN] Look at Workflow = "X" in "Workflow Instance" query
        WorkflowInstance.SetRange(Code, Workflow.Code);
        WorkflowInstance.Open();

        // [THEN] Query is empty
        Assert.IsFalse(WorkflowInstance.Read(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WorkflowDefinitionQueryWithoutSteps()
    var
        Workflow: Record Workflow;
        WorkflowDefinition: Query "Workflow Definition";
    begin
        // [SCENARIO 381194] "Workflow Definition" query when there are no steps

        // [GIVEN] Workflow templates reinitiated
        LibraryWorkflow.DeleteAllExistingWorkflows();
        WorkflowSetup.InitWorkflow();

        // [GIVEN] Workflow = "X" without steps and instances
        LibraryWorkflow.CreateWorkflow(Workflow);

        // [WHEN] Look at Workflow = "X" in "Workflow Definition" query
        WorkflowDefinition.SetRange(Code, Workflow.Code);
        WorkflowDefinition.Open();

        // [THEN] Query is empty
        Assert.IsFalse(WorkflowDefinition.Read(), '');
    end;

    local procedure Initialize()
    var
        Workflow: Record Workflow;
        UserSetup: Record "User Setup";
        GenJournalTemplate: Record "Gen. Journal Template";
        NotificationSetup: Record "Notification Setup";
        NotificationEntry: Record "Notification Entry";
        ApprovalEntry: Record "Approval Entry";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryApplicationArea.EnableFoundationSetup();
        LibraryVariableStorage.Clear();
        Workflow.ModifyAll(Enabled, false, true);
        UserSetup.DeleteAll();
        GenJournalTemplate.DeleteAll();
        NotificationSetup.DeleteAll();
        NotificationEntry.DeleteAll();
        ApprovalEntry.DeleteAll();

        if IsInitialized then
            exit;

        IsInitialized := true;
        BindSubscription(LibraryJobQueue);
    end;

    local procedure CreateApprovalSetup(var ApproverUserSetup: Record "User Setup"; var RequestorUserSetup: Record "User Setup")
    var
        NotificationSetup: Record "Notification Setup";
    begin
        LibraryDocumentApprovals.CreateOrFindUserSetup(RequestorUserSetup, UserId);
        LibraryDocumentApprovals.CreateMockupUserSetup(ApproverUserSetup);
        LibraryDocumentApprovals.SetApprover(RequestorUserSetup, ApproverUserSetup);

        LibraryWorkflow.CreateNotificationSetup(
          NotificationSetup, UserId,
          NotificationSetup."Notification Type"::Approval,
          NotificationSetup."Notification Method"::Note);
    end;

    local procedure CreateDirectApprovalWorkflow(var Workflow: Record Workflow)
    begin
        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.GeneralJournalBatchApprovalWorkflowCode());
    end;

    local procedure CreateDirectApprovalEnabledWorkflow(var Workflow: Record Workflow)
    begin
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.GeneralJournalBatchApprovalWorkflowCode());
    end;

    local procedure EnableWorkflow(var Workflow: Record Workflow)
    begin
        Workflow.Validate(Enabled, true);
        Workflow.Modify(true);
    end;

    local procedure CreateJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; JournalTemplateName: Code[10])
    begin
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, JournalTemplateName);
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"G/L Account");
        GenJournalBatch.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNoWithDirectPosting());
        GenJournalBatch.Modify(true);
    end;

    local procedure CreateGeneralJournalBatchWithOneJournalLine(var GenJournalBatch: Record "Gen. Journal Batch"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        CreateJournalBatch(GenJournalBatch, LibraryERM.SelectGenJnlTemplate());

        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
          LibraryRandom.RandDec(100, 2));
    end;

    local procedure CreatePaymentJournalBatchWithOneJournalLine(var GenJournalBatch: Record "Gen. Journal Batch"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        CreateJournalBatch(GenJournalBatch, LibraryERM.SelectGenJnlTemplate());
        CreateJournalBatch(GenJournalBatch, LibraryPurchase.SelectPmtJnlTemplate());

        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
          LibraryRandom.RandDec(100, 2));
    end;

    local procedure CreateCashReceiptJournalBatchWithOneJournalLine(var GenJournalBatch: Record "Gen. Journal Batch"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        CreateJournalBatch(GenJournalBatch, LibraryERM.SelectGenJnlTemplate());
        CreateJournalBatch(GenJournalBatch, LibrarySales.SelectCashReceiptJnlTemplate());

        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
          LibraryRandom.RandDec(100, 2));
    end;

    local procedure CreateJournalBatchWithMultipleJournalLines(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalLine1: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        GenJournalLine3: Record "Gen. Journal Line";
    begin
        CreateJournalBatch(GenJournalBatch, LibraryERM.SelectGenJnlTemplate());

        LibraryERM.CreateGeneralJnlLine(GenJournalLine1, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine1."Document Type"::Invoice, GenJournalLine1."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
          LibraryRandom.RandDec(100, 2));
        LibraryERM.CreateGeneralJnlLine(GenJournalLine2, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine2."Document Type"::Invoice, GenJournalLine2."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
          LibraryRandom.RandDec(100, 2));
        LibraryERM.CreateGeneralJnlLine(GenJournalLine3, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine3."Document Type"::Invoice, GenJournalLine3."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
          LibraryRandom.RandDec(100, 2));
    end;

    local procedure CreateOpenApprovalEntryForCurrentUser(RecordID: RecordID)
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        ApprovalEntry.Init();
        ApprovalEntry."Document Type" := ApprovalEntry."Document Type"::" ";
        ApprovalEntry."Document No." := '';
        ApprovalEntry."Table ID" := RecordID.TableNo;
        ApprovalEntry."Record ID to Approve" := RecordID;
        ApprovalEntry."Sender ID" := UserId;
        ApprovalEntry."Approver ID" := UserId;
        ApprovalEntry.Status := ApprovalEntry.Status::Open;
        ApprovalEntry."Sequence No." := 1;
        ApprovalEntry.Insert();
    end;

    local procedure SendApprovalRequestForGeneralJournal(GenJournalBatchName: Code[20])
    var
        GeneralJournal: TestPage "General Journal";
    begin
        GeneralJournal.OpenView();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatchName);
        GeneralJournal.SendApprovalRequestJournalBatch.Invoke();
    end;

    local procedure SendApprovalRequestForCashReceipt(GenJournalBatchName: Code[20])
    var
        CashReceiptJournal: TestPage "Cash Receipt Journal";
    begin
        CashReceiptJournal.OpenView();
        CashReceiptJournal.CurrentJnlBatchName.SetValue(GenJournalBatchName);
        CashReceiptJournal.SendApprovalRequestJournalBatch.Invoke();
    end;

    local procedure SendApprovalRequestForPaymentJournal(GenJournalBatchName: Code[20])
    var
        PaymentJournal: TestPage "Payment Journal";
    begin
        PaymentJournal.OpenView();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalBatchName);
        PaymentJournal.SendApprovalRequestJournalBatch.Invoke();
    end;

    local procedure SendFilteredApprovalRequest(GenJournalBatchName: Code[20])
    var
        GeneralJournal: TestPage "General Journal";
    begin
        GeneralJournal.OpenView();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatchName);
        GeneralJournal.FILTER.SetFilter("Line No.", '20000'); // 2nd line
        GeneralJournal.SendApprovalRequestJournalBatch.Invoke();
    end;

    local procedure CancelApprovalRequestForGeneralJournal(GenJournalBatchName: Code[20])
    var
        GeneralJournal: TestPage "General Journal";
    begin
        GeneralJournal.OpenView();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatchName);
        GeneralJournal.CancelApprovalRequestJournalBatch.Invoke();
    end;

    local procedure CancelApprovalRequestForCashReceipt(GenJournalBatchName: Code[20])
    var
        CashReceiptJournal: TestPage "Cash Receipt Journal";
    begin
        CashReceiptJournal.OpenView();
        CashReceiptJournal.CurrentJnlBatchName.SetValue(GenJournalBatchName);
        CashReceiptJournal.CancelApprovalRequestJournalBatch.Invoke();
    end;

    local procedure CancelApprovalRequestForPaymentJournal(GenJournalBatchName: Code[20])
    var
        PaymentJournal: TestPage "Payment Journal";
    begin
        PaymentJournal.OpenView();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalBatchName);
        PaymentJournal.CancelApprovalRequestJournalBatch.Invoke();
    end;

    local procedure AssignApprovalEntry(var ApprovalEntry: Record "Approval Entry"; UserSetup: Record "User Setup")
    begin
        ApprovalEntry."Approver ID" := UserSetup."User ID";
        ApprovalEntry."Sender ID" := UserSetup."Approver ID";
        ApprovalEntry.Modify();
    end;

    local procedure Approve(var ApprovalEntry: Record "Approval Entry")
    var
        RequeststoApprove: TestPage "Requests to Approve";
    begin
        RequeststoApprove.OpenView();
        RequeststoApprove.GotoRecord(ApprovalEntry);
        RequeststoApprove.Approve.Invoke();
    end;

    local procedure Reject(var ApprovalEntry: Record "Approval Entry")
    var
        GeneralJournal: TestPage "General Journal";
        RequeststoApprove: TestPage "Requests to Approve";
    begin
        RequeststoApprove.OpenView();
        RequeststoApprove.GotoRecord(ApprovalEntry);
        GeneralJournal.Trap();
        RequeststoApprove.Record.Invoke();
        GeneralJournal.Reject.Invoke();
    end;

    local procedure Delegate(var ApprovalEntry: Record "Approval Entry")
    var
        GeneralJournal: TestPage "General Journal";
        RequeststoApprove: TestPage "Requests to Approve";
    begin
        RequeststoApprove.OpenView();
        RequeststoApprove.GotoRecord(ApprovalEntry);
        GeneralJournal.Trap();
        RequeststoApprove.Record.Invoke();
        GeneralJournal.Delegate.Invoke();
    end;

    local procedure RunNotificationEntryDispatcher()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"Notification Entry Dispatcher");
        JobQueueEntry.FindFirst();
        CODEUNIT.Run(CODEUNIT::"Notification Entry Dispatcher", JobQueueEntry);
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

    local procedure VerifyOpenApprovalEntry(var ApprovalEntry: Record "Approval Entry"; ApproverUserSetup: Record "User Setup"; RequestorUserSetup: Record "User Setup")
    begin
        Assert.RecordCount(ApprovalEntry, 1);
        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, RequestorUserSetup."User ID");
        VerifyApprovalEntryApproverID(ApprovalEntry, ApproverUserSetup."User ID");
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    local procedure CheckUserCanCancelTheApprovalRequestForAGeneralJnlBatch(GenJournalBatch: Record "Gen. Journal Batch"; CancelActionExpectedEnabled: Boolean)
    var
        GeneralJournal: TestPage "General Journal";
    begin
        GeneralJournal.OpenView();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        Assert.AreEqual(CancelActionExpectedEnabled, GeneralJournal.CancelApprovalRequestJournalBatch.Enabled(),
          'Wrong state for the Cancel action');
        GeneralJournal.Close();
    end;

    local procedure CheckUserCanCancelTheApprovalRequestForAPaymentJnlBatch(GenJournalBatch: Record "Gen. Journal Batch"; CancelActionExpectedEnabled: Boolean)
    var
        PaymentJournal: TestPage "Payment Journal";
    begin
        PaymentJournal.OpenView();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        Assert.AreEqual(CancelActionExpectedEnabled, PaymentJournal.CancelApprovalRequestJournalBatch.Enabled(),
          'Wrong state for the Cancel action');
        PaymentJournal.Close();
    end;

    local procedure CheckUserCanCancelTheApprovalRequestForACashReceiptJnlBatch(GenJournalBatch: Record "Gen. Journal Batch"; CancelActionExpectedEnabled: Boolean)
    var
        CashReceiptJournal: TestPage "Cash Receipt Journal";
    begin
        CashReceiptJournal.OpenView();
        CashReceiptJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        Assert.AreEqual(CancelActionExpectedEnabled, CashReceiptJournal.CancelApprovalRequestJournalBatch.Enabled(),
          'Wrong state for the Cancel action');
        CashReceiptJournal.Close();
    end;

    local procedure CheckCommentsForDocumentOnGeneralJournalPage(GenJournalBatch: Record "Gen. Journal Batch"; NumberOfExpectedComments: Integer; CommentActionIsVisible: Boolean)
    var
        ApprovalComments: TestPage "Approval Comments";
        GeneralJournal: TestPage "General Journal";
        NumberOfComments: Integer;
    begin
        ApprovalComments.Trap();

        GeneralJournal.OpenView();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);

        Assert.AreEqual(CommentActionIsVisible, GeneralJournal.Comments.Visible(), 'The Comments action has the wrong visibility');

        if CommentActionIsVisible then begin
            GeneralJournal.Comments.Invoke();
            if ApprovalComments.First() then
                repeat
                    NumberOfComments += 1;
                until ApprovalComments.Next();
            Assert.AreEqual(NumberOfExpectedComments, NumberOfComments, 'The page contains the wrong number of comments');

            ApprovalComments.Comment.SetValue('Test Comment' + Format(NumberOfExpectedComments));
            ApprovalComments.Next();
            ApprovalComments.Close();
        end;

        GeneralJournal.Close();
    end;

    local procedure CheckCommentsForDocumentOnCashReceiptPage(GenJournalBatch: Record "Gen. Journal Batch"; NumberOfExpectedComments: Integer; CommentActionIsVisible: Boolean)
    var
        ApprovalComments: TestPage "Approval Comments";
        CashReceiptJournal: TestPage "Cash Receipt Journal";
        NumberOfComments: Integer;
    begin
        ApprovalComments.Trap();

        CashReceiptJournal.OpenView();
        CashReceiptJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);

        Assert.AreEqual(CommentActionIsVisible, CashReceiptJournal.Comment.Visible(), 'The Comments action has the wrong visibility');

        if CommentActionIsVisible then begin
            CashReceiptJournal.Comment.Invoke();
            if ApprovalComments.First() then
                repeat
                    NumberOfComments += 1;
                until ApprovalComments.Next();
            Assert.AreEqual(NumberOfExpectedComments, NumberOfComments, 'The page contains the wrong number of comments');

            ApprovalComments.Comment.SetValue('Test Comment' + Format(NumberOfExpectedComments));
            ApprovalComments.Next();
            ApprovalComments.Close();
        end;

        CashReceiptJournal.Close();
    end;

    local procedure CheckCommentsForDocumentOnPaymentPage(GenJournalBatch: Record "Gen. Journal Batch"; NumberOfExpectedComments: Integer; CommentActionIsVisible: Boolean)
    var
        ApprovalComments: TestPage "Approval Comments";
        PaymentJournal: TestPage "Payment Journal";
        NumberOfComments: Integer;
    begin
        ApprovalComments.Trap();

        PaymentJournal.OpenView();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);

        Assert.AreEqual(CommentActionIsVisible, PaymentJournal.Comment.Visible(), 'The Comments action has the wrong visibility');

        if CommentActionIsVisible then begin
            PaymentJournal.Comment.Invoke();
            if ApprovalComments.First() then
                repeat
                    NumberOfComments += 1;
                until ApprovalComments.Next();
            Assert.AreEqual(NumberOfExpectedComments, NumberOfComments, 'The page contains the wrong number of comments');

            ApprovalComments.Comment.SetValue('Test Comment' + Format(NumberOfExpectedComments));
            ApprovalComments.Next();
            ApprovalComments.Close();
        end;

        PaymentJournal.Close();
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
}

