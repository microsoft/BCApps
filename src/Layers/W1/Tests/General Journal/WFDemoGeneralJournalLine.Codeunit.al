codeunit 134188 "WF Demo General Journal Line"
{
    EventSubscriberInstance = Manual;
    Permissions = TableData "Approval Entry" = im;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Workflow] [Approval] [General Journal]
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
        LibraryJournals: Codeunit "Library - Journals";
        WorkflowSetup: Codeunit "Workflow Setup";
        UnexpectedNoOfApprovalEntriesErr: Label 'Unexpected number of approval entries found.';
        LibraryJobQueue: Codeunit "Library - Job Queue";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure CanSendApprovalRequestFor2IndependantLinePendingApproval()
    var
        ApprovalEntry: Record "Approval Entry";
        ApproverUserSetup: Record "User Setup";
        GenJournalLine: Record "Gen. Journal Line";
        RequestorUserSetup: Record "User Setup";
        Workflow: Record Workflow;
    begin
        // [SCENARIO] Send 2 lines for approval indepently
        // [GIVEN] Journal batch with Two line
        // [WHEN] Journal Line 1 send for approval
        // [WHEN] Journal Line 2 send for approval
        // [THEN] Two lines are send for approval

        Initialize();

        // Setup
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.GeneralJournalLineApprovalWorkflowCode());

        CreateJournalBatchWithMultipleJournalLines(GenJournalLine);

        LibraryDocumentApprovals.CreateOrFindUserSetup(RequestorUserSetup, UserId);
        LibraryDocumentApprovals.CreateMockupUserSetup(ApproverUserSetup);
        LibraryDocumentApprovals.SetApprover(RequestorUserSetup, ApproverUserSetup);

        // Exercise
        Commit();
        SendFilteredApprovalRequest(GenJournalLine."Journal Batch Name", GenJournalLine."Line No.");

        // Verify
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalLine.RecordId);
        Assert.AreEqual(1, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        // Exercise
        GenJournalLine.Next(-1);
        SendFilteredApprovalRequest(GenJournalLine."Journal Batch Name", GenJournalLine."Line No.");

        // Verify
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalLine.RecordId);
        Assert.AreEqual(1, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        // Teardown
        ApproverUserSetup.Delete();
        RequestorUserSetup.Delete();
    end;

    [Test]
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
        // [SCENARIO] Approve a pending request to approve journal lines
        // [GIVEN] Journal batch with one line
        // [GIVEN] Approval entries exist for one line
        // [WHEN] Direct approver clicks the Approve action
        // [THEN] Approval entry is approved

        Initialize();

        // Setup
        CreateDirectApprovalEnabledWorkflow(Workflow);

        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        LibraryDocumentApprovals.CreateOrFindUserSetup(RequestorUserSetup, UserId);
        LibraryDocumentApprovals.CreateMockupUserSetup(ApproverUserSetup);
        LibraryDocumentApprovals.SetApprover(RequestorUserSetup, ApproverUserSetup);

        // Exercise
        Commit();
        SendApprovalRequestForGeneralJournal(GenJournalLine."Journal Batch Name");

        // Verify
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalLine.RecordId);

        Assert.AreEqual(1, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, RequestorUserSetup."User ID");
        VerifyApprovalEntryApproverID(ApprovalEntry, ApproverUserSetup."User ID");

        // Setup
        AssignApprovalEntry(ApprovalEntry, RequestorUserSetup);

        // Exercise
        Approve(ApprovalEntry);

        // Verify
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalLine.RecordId);

        VerifyApprovalEntryIsApproved(ApprovalEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DirectApproverRejectsRequest()
    var
        ApprovalEntry: Record "Approval Entry";
        ApproverUserSetup: Record "User Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        RequestorUserSetup: Record "User Setup";
        Workflow: Record Workflow;
    begin
        // [SCENARIO] Reject a pending request to approve journal lines
        // [GIVEN] Journal batch with one line
        // [GIVEN] Approval entries exist for line
        // [WHEN] Direct approver clicks the Reject action
        // [THEN] Approval entry is rejected

        Initialize();

        // Setup
        CreateDirectApprovalEnabledWorkflow(Workflow);

        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        LibraryDocumentApprovals.CreateOrFindUserSetup(RequestorUserSetup, UserId);
        LibraryDocumentApprovals.CreateMockupUserSetup(ApproverUserSetup);
        LibraryDocumentApprovals.SetApprover(RequestorUserSetup, ApproverUserSetup);

        // Exercise
        Commit();
        SendApprovalRequestForGeneralJournal(GenJournalLine."Journal Batch Name");

        // Verify
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalLine.RecordId);

        Assert.AreEqual(1, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, RequestorUserSetup."User ID");
        VerifyApprovalEntryApproverID(ApprovalEntry, ApproverUserSetup."User ID");

        // Setup
        AssignApprovalEntry(ApprovalEntry, RequestorUserSetup);

        // Exercise
        Reject(ApprovalEntry);

        // Verify
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalLine.RecordId);

        VerifyApprovalEntryIsRejected(ApprovalEntry);
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
        // [SCENARIO] Delegate a request to approve journal lines
        // [GIVEN] Journal batch with one line
        // [GIVEN] Approval entries exist for one line
        // [WHEN] Direct approver clicks the Delegat action
        // [THEN] Approval entry is delegated to the substitute

        Initialize();

        // Setup
        CreateDirectApprovalEnabledWorkflow(Workflow);

        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        LibraryDocumentApprovals.CreateOrFindUserSetup(RequestorUserSetup, UserId);
        LibraryDocumentApprovals.CreateMockupUserSetup(ApproverUserSetup);
        LibraryDocumentApprovals.SetApprover(RequestorUserSetup, ApproverUserSetup);

        // Exercise
        Commit();
        SendApprovalRequestForGeneralJournal(GenJournalLine."Journal Batch Name");

        // Verify
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalLine.RecordId);

        Assert.AreEqual(1, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, RequestorUserSetup."User ID");
        VerifyApprovalEntryApproverID(ApprovalEntry, ApproverUserSetup."User ID");

        // Setup
        AssignApprovalEntry(ApprovalEntry, RequestorUserSetup);
        LibraryDocumentApprovals.CreateMockupUserSetup(SubstituteUserSetup);
        LibraryDocumentApprovals.SetSubstitute(RequestorUserSetup, SubstituteUserSetup);

        // Exercise
        Delegate(ApprovalEntry);

        // Verify
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalLine.RecordId);

        Assert.AreEqual(1, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, RequestorUserSetup."User ID");
        VerifyApprovalEntryApproverID(ApprovalEntry, SubstituteUserSetup."User ID");

        // Setup
        AssignApprovalEntry(ApprovalEntry, RequestorUserSetup);

        // Exercise
        Approve(ApprovalEntry);

        // Verify
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalLine.RecordId);

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
        // [SCENARIO] Cancel a pending request to approve journal lines
        // [GIVEN] Journal batch with one line
        // [GIVEN] Approval entries exist for one line
        // [WHEN] Requestor clicks the Cancel action
        // [THEN] Approval entry is canceled

        Initialize();

        // Setup
        CreateDirectApprovalEnabledWorkflow(Workflow);

        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        LibraryDocumentApprovals.CreateOrFindUserSetup(RequestorUserSetup, UserId);
        LibraryDocumentApprovals.CreateMockupUserSetup(ApproverUserSetup);
        LibraryDocumentApprovals.SetApprover(RequestorUserSetup, ApproverUserSetup);

        CheckUserCanCancelTheApprovalRequestForAGeneralJnlLine(GenJournalBatch, false);

        // Exercise
        Commit();
        SendApprovalRequestForGeneralJournal(GenJournalLine."Journal Batch Name");

        // Verify
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalLine.RecordId);

        Assert.AreEqual(1, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, RequestorUserSetup."User ID");
        VerifyApprovalEntryApproverID(ApprovalEntry, ApproverUserSetup."User ID");

        // Exercise
        CancelApprovalRequestForGeneralJournal(GenJournalLine."Journal Batch Name");

        // Verify
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalLine.RecordId);

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

        CheckUserCanCancelTheApprovalRequestForACashReceiptJnlLine(GenJournalBatch, false);

        // Exercise
        Commit();
        SendApprovalRequestForCashReceipt(GenJournalBatch.Name);

        // Verify
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalLine.RecordId);

        VerifyApprovalEntryIsOpen(ApprovalEntry);

        CheckUserCanCancelTheApprovalRequestForACashReceiptJnlLine(GenJournalBatch, true);

        // Exercise
        CancelApprovalRequestForCashReceipt(GenJournalBatch.Name);

        // Verify
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalLine.RecordId);

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

        CheckUserCanCancelTheApprovalRequestForAPaymentJnlLine(GenJournalBatch, false);

        // Exercise
        Commit();
        SendApprovalRequestForPaymentJournal(GenJournalBatch.Name);

        // Verify
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalLine.RecordId);

        VerifyApprovalEntryIsOpen(ApprovalEntry);

        CheckUserCanCancelTheApprovalRequestForAPaymentJnlLine(GenJournalBatch, true);

        // Exercise
        CancelApprovalRequestForPaymentJournal(GenJournalBatch.Name);

        // Verify
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalLine.RecordId);

        VerifyApprovalEntryIsCancelled(ApprovalEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure RequestorCancelsPurchaseRequestToDirectApprover()
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

        CreatePurchaseJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);

        CheckUserCanCancelTheApprovalRequestForAPurchaseJnlLine(GenJournalBatch, false);

        // Exercise
        Commit();
        SendApprovalRequestForPurchaseJournal(GenJournalBatch.Name);

        // Verify
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalLine.RecordId);

        VerifyApprovalEntryIsOpen(ApprovalEntry);

        CheckUserCanCancelTheApprovalRequestForAPurchaseJnlLine(GenJournalBatch, true);

        // Exercise
        CancelApprovalRequestForPurchaseJournal(GenJournalBatch.Name);

        // Verify
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalLine.RecordId);

        VerifyApprovalEntryIsCancelled(ApprovalEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure RequestorCancelsSalesRequestToDirectApprover()
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

        CreateSalesJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);

        CheckUserCanCancelTheApprovalRequestForASalesJnlLine(GenJournalBatch, false);

        // Exercise
        Commit();
        SendApprovalRequestForSalesJournal(GenJournalBatch.Name);

        // Verify
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalLine.RecordId);

        VerifyApprovalEntryIsOpen(ApprovalEntry);

        CheckUserCanCancelTheApprovalRequestForASalesJnlLine(GenJournalBatch, true);

        // Exercise
        CancelApprovalRequestForSalesJournal(GenJournalBatch.Name);

        // Verify
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalLine.RecordId);

        VerifyApprovalEntryIsCancelled(ApprovalEntry);
    end;

    [Test]
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

        CheckCommentsForDocumentOnGeneralJournalPage(GenJournalBatch, 0, true);

        // Verify
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalLine.RecordId);

        VerifyApprovalEntryIsOpen(ApprovalEntry);

        // Setup
        AssignApprovalEntry(ApprovalEntry, RequestorUserSetup);

        CheckCommentsForDocumentOnGeneralJournalPage(GenJournalBatch, 1, true);
        CheckCommentsForDocumentOnApprovalEntriesPage(ApprovalEntry, 1);
        CheckCommentsForDocumentOnRequestsToApprovePage(ApprovalEntry, 1);
        // Exercise
        Approve(ApprovalEntry);

        // Verify
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalLine.RecordId);

        VerifyApprovalEntryIsApproved(ApprovalEntry);
    end;

    [Test]
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
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalLine.RecordId);

        VerifyApprovalEntryIsOpen(ApprovalEntry);

        // Setup
        AssignApprovalEntry(ApprovalEntry, RequestorUserSetup);

        CheckCommentsForDocumentOnCashReceiptPage(GenJournalBatch, 1, true);
        CheckCommentsForDocumentOnApprovalEntriesPage(ApprovalEntry, 1);
        CheckCommentsForDocumentOnRequestsToApprovePage(ApprovalEntry, 1);

        // Exercise
        Approve(ApprovalEntry);

        // Verify
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalLine.RecordId);

        VerifyApprovalEntryIsApproved(ApprovalEntry);
    end;

    [Test]
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
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalLine.RecordId);

        VerifyApprovalEntryIsOpen(ApprovalEntry);

        // Setup
        AssignApprovalEntry(ApprovalEntry, RequestorUserSetup);

        CheckCommentsForDocumentOnPaymentPage(GenJournalBatch, 1, true);
        CheckCommentsForDocumentOnApprovalEntriesPage(ApprovalEntry, 1);
        CheckCommentsForDocumentOnRequestsToApprovePage(ApprovalEntry, 1);

        // Exercise
        Approve(ApprovalEntry);

        // Verify
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalLine.RecordId);

        VerifyApprovalEntryIsApproved(ApprovalEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DirectApproverApprovesPurchaseRequestWithComment()
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

        CreatePurchaseJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);

        CheckCommentsForDocumentOnPurchaseJournalPage(GenJournalBatch, 0, false);

        // Exercise
        Commit();
        SendApprovalRequestForPurchaseJournal(GenJournalBatch.Name);

        CheckCommentsForDocumentOnPurchaseJournalPage(GenJournalBatch, 0, true);

        // Verify
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalLine.RecordId);

        VerifyApprovalEntryIsOpen(ApprovalEntry);

        // Setup
        AssignApprovalEntry(ApprovalEntry, RequestorUserSetup);

        CheckCommentsForDocumentOnPurchaseJournalPage(GenJournalBatch, 1, true);
        CheckCommentsForDocumentOnApprovalEntriesPage(ApprovalEntry, 1);
        CheckCommentsForDocumentOnRequestsToApprovePage(ApprovalEntry, 1);

        // Exercise
        Approve(ApprovalEntry);

        // Verify
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalLine.RecordId);

        VerifyApprovalEntryIsApproved(ApprovalEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DirectApproverApprovesSalesRequestWithComment()
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

        CreateSalesJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);

        CheckCommentsForDocumentOnSalesJournalPage(GenJournalBatch, 0, false);

        // Exercise
        Commit();
        SendApprovalRequestForSalesJournal(GenJournalBatch.Name);

        CheckCommentsForDocumentOnSalesJournalPage(GenJournalBatch, 0, true);

        // Verify
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalLine.RecordId);

        VerifyApprovalEntryIsOpen(ApprovalEntry);

        // Setup
        AssignApprovalEntry(ApprovalEntry, RequestorUserSetup);

        CheckCommentsForDocumentOnSalesJournalPage(GenJournalBatch, 1, true);
        CheckCommentsForDocumentOnApprovalEntriesPage(ApprovalEntry, 1);
        CheckCommentsForDocumentOnRequestsToApprovePage(ApprovalEntry, 1);

        // Exercise
        Approve(ApprovalEntry);

        // Verify
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalLine.RecordId);

        VerifyApprovalEntryIsApproved(ApprovalEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DirectApproverApprovesFilteredRequest()
    var
        ApprovalEntry: Record "Approval Entry";
        GenJournalLine: Record "Gen. Journal Line";
        ApproverUserSetup: Record "User Setup";
        RequestorUserSetup: Record "User Setup";
        Workflow: Record Workflow;
    begin
        // [SCENARIO] Approve a pending request to approve journal lines
        // [GIVEN] Journal batch with one or more lines
        // [GIVEN] Subset of the lines are included in the request
        // [GIVEN] Approval entries exist for one line
        // [WHEN] Direct approver clicks the Approve action
        // [THEN] Approval entry is approved

        Initialize();

        // Setup
        CreateDirectApprovalEnabledWorkflow(Workflow);

        CreateJournalBatchWithMultipleJournalLines(GenJournalLine);

        LibraryDocumentApprovals.CreateOrFindUserSetup(RequestorUserSetup, UserId);
        LibraryDocumentApprovals.CreateMockupUserSetup(ApproverUserSetup);
        LibraryDocumentApprovals.SetApprover(RequestorUserSetup, ApproverUserSetup);

        // Exercise
        Commit();
        SendFilteredApprovalRequest(GenJournalLine."Journal Batch Name", GenJournalLine."Line No.");

        // Verify
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalLine.RecordId);

        Assert.AreEqual(1, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, RequestorUserSetup."User ID");
        VerifyApprovalEntryApproverID(ApprovalEntry, ApproverUserSetup."User ID");

        // Setup
        AssignApprovalEntry(ApprovalEntry, RequestorUserSetup);

        // Exercise
        Approve(ApprovalEntry);

        // Verify
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalLine.RecordId);

        VerifyApprovalEntryIsApproved(ApprovalEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DirectApproverRejectsFilteredRequest()
    var
        ApprovalEntry: Record "Approval Entry";
        GenJournalLine: Record "Gen. Journal Line";
        ApproverUserSetup: Record "User Setup";
        RequestorUserSetup: Record "User Setup";
        Workflow: Record Workflow;
    begin
        // [SCENARIO] Reject a pending request to approve journal lines
        // [GIVEN] Journal batch with one line
        // [GIVEN] Subset of the lines are included in the request
        // [GIVEN] Approval entries exist for line
        // [WHEN] Direct approver clicks the Reject action
        // [THEN] Approval entry is rejected

        Initialize();

        // Setup
        CreateDirectApprovalEnabledWorkflow(Workflow);

        CreateJournalBatchWithMultipleJournalLines(GenJournalLine);

        LibraryDocumentApprovals.CreateOrFindUserSetup(RequestorUserSetup, UserId);
        LibraryDocumentApprovals.CreateMockupUserSetup(ApproverUserSetup);
        LibraryDocumentApprovals.SetApprover(RequestorUserSetup, ApproverUserSetup);

        // Exercise
        Commit();
        SendFilteredApprovalRequest(GenJournalLine."Journal Batch Name", GenJournalLine."Line No.");

        // Verify
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalLine.RecordId);

        Assert.AreEqual(1, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, RequestorUserSetup."User ID");
        VerifyApprovalEntryApproverID(ApprovalEntry, ApproverUserSetup."User ID");

        // Setup
        AssignApprovalEntry(ApprovalEntry, RequestorUserSetup);

        // Exercise
        Reject(ApprovalEntry);

        // Verify
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalLine.RecordId);

        VerifyApprovalEntryIsRejected(ApprovalEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure DirectApproverDelegatesFilteredRequest()
    var
        ApprovalEntry: Record "Approval Entry";
        GenJournalLine: Record "Gen. Journal Line";
        ApproverUserSetup: Record "User Setup";
        RequestorUserSetup: Record "User Setup";
        SubstituteUserSetup: Record "User Setup";
        Workflow: Record Workflow;
    begin
        // [SCENARIO] Delegate a request to approve journal lines
        // [GIVEN] Journal batch with one or more lines
        // [GIVEN] Subset of the lines are included in the request
        // [GIVEN] Approval entries exist for one line
        // [WHEN] Direct approver clicks the Delegat action
        // [THEN] Approval entry is delegated to the substitute

        Initialize();

        // Setup
        CreateDirectApprovalEnabledWorkflow(Workflow);

        CreateJournalBatchWithMultipleJournalLines(GenJournalLine);

        LibraryDocumentApprovals.CreateOrFindUserSetup(RequestorUserSetup, UserId);
        LibraryDocumentApprovals.CreateMockupUserSetup(ApproverUserSetup);
        LibraryDocumentApprovals.SetApprover(RequestorUserSetup, ApproverUserSetup);

        // Exercise
        Commit();
        SendFilteredApprovalRequest(GenJournalLine."Journal Batch Name", GenJournalLine."Line No.");

        // Verify
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalLine.RecordId);

        Assert.AreEqual(1, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, RequestorUserSetup."User ID");
        VerifyApprovalEntryApproverID(ApprovalEntry, ApproverUserSetup."User ID");

        // Setup
        AssignApprovalEntry(ApprovalEntry, RequestorUserSetup);
        LibraryDocumentApprovals.CreateMockupUserSetup(SubstituteUserSetup);
        LibraryDocumentApprovals.SetSubstitute(RequestorUserSetup, SubstituteUserSetup);

        // Exercise
        Delegate(ApprovalEntry);

        // Verify
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalLine.RecordId);

        Assert.AreEqual(1, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, RequestorUserSetup."User ID");
        VerifyApprovalEntryApproverID(ApprovalEntry, SubstituteUserSetup."User ID");

        // Setup
        AssignApprovalEntry(ApprovalEntry, RequestorUserSetup);

        // Exercise
        Approve(ApprovalEntry);

        // Verify
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalLine.RecordId);

        VerifyApprovalEntryIsApproved(ApprovalEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure RequestorCancelsFilteredRequestToDirectApprover()
    var
        ApprovalEntry: Record "Approval Entry";
        GenJournalLine: Record "Gen. Journal Line";
        ApproverUserSetup: Record "User Setup";
        RequestorUserSetup: Record "User Setup";
        Workflow: Record Workflow;
    begin
        // [SCENARIO] Cancel a pending request to approve journal lines
        // [GIVEN] Journal batch with one or more lines
        // [GIVEN] Subset of the lines are included in the request
        // [GIVEN] Approval entries exist for one line
        // [WHEN] Requestor clicks the Cancel action
        // [THEN] Approval entry is canceled

        Initialize();

        // Setup
        CreateDirectApprovalEnabledWorkflow(Workflow);

        CreateJournalBatchWithMultipleJournalLines(GenJournalLine);

        LibraryDocumentApprovals.CreateOrFindUserSetup(RequestorUserSetup, UserId);
        LibraryDocumentApprovals.CreateMockupUserSetup(ApproverUserSetup);
        LibraryDocumentApprovals.SetApprover(RequestorUserSetup, ApproverUserSetup);

        // Exercise
        Commit();
        SendFilteredApprovalRequest(GenJournalLine."Journal Batch Name", GenJournalLine."Line No.");

        // Verify
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalLine.RecordId);

        Assert.AreEqual(1, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, RequestorUserSetup."User ID");
        VerifyApprovalEntryApproverID(ApprovalEntry, ApproverUserSetup."User ID");

        // Exercise
        CancelFilteredApprovalRequest(GenJournalLine."Journal Batch Name", GenJournalLine."Line No.");

        // Verify
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalLine.RecordId);

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
        Assert.IsFalse(GeneralJournal.SendApprovalRequestJournalLine.Enabled(), 'Send should be disabled');
        Assert.IsFalse(GeneralJournal.CancelApprovalRequestJournalLine.Enabled(), 'Send should be disabled');
        Assert.Isfalse(GeneralJournal.SendApprovalRequestJournalBatch.Enabled(), 'SendBatch should be disabled');
        Assert.IsFalse(GeneralJournal.CancelApprovalRequestJournalBatch.Enabled(), 'SendBatch should be disabled');
        Assert.IsFalse(GeneralJournal.Approve.Visible(), '');
        Assert.IsFalse(GeneralJournal.Reject.Visible(), '');
        Assert.IsFalse(GeneralJournal.Delegate.Visible(), '');

        // [THEN] Close the journal
        GeneralJournal.Close();

        // [GIVEN] Workflow is enabled
        EnableWorkflow(Workflow);

        // [WHEN] Approval entry exists for the batch
        CreateJournalLineOpenApprovalEntryForCurrentUser(GenJournalLine);

        // [WHEN] User opens the journal batch
        Commit();
        GeneralJournal.OpenEdit();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);

        // [THEN] Approval actions?
        Assert.IsFalse(GeneralJournal.SendApprovalRequestJournalLine.Enabled(), 'Send should be disabled');
        Assert.IsTrue(GeneralJournal.CancelApprovalRequestJournalLine.Enabled(), 'Send should be enabled');
        Assert.IsFalse(GeneralJournal.SendApprovalRequestJournalBatch.Enabled(), 'SendBatch should be disabled');
        Assert.IsFalse(GeneralJournal.CancelApprovalRequestJournalBatch.Enabled(), 'SendBatch should be disabled');
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
        Assert.IsTrue(PaymentJournal.SendApprovalRequestJournalLine.Enabled(), 'Send should be enabled');
        Assert.IsFalse(PaymentJournal.CancelApprovalRequestJournalLine.Enabled(), 'Send should be disabled');
        Assert.IsTrue(PaymentJournal.SendApprovalRequestJournalBatch.Enabled(), 'SendBatch should be enabled');
        Assert.IsFalse(PaymentJournal.CancelApprovalRequestJournalBatch.Enabled(), 'SendBatch should be disabled');
        Assert.IsFalse(PaymentJournal.Approve.Visible(), '');
        Assert.IsFalse(PaymentJournal.Reject.Visible(), '');
        Assert.IsFalse(PaymentJournal.Delegate.Visible(), '');

        // [THEN] Close the journal
        PaymentJournal.Close();

        // [GIVEN] Workflow is enabled
        EnableWorkflow(Workflow);

        // [WHEN] Approval entry exists for the batch
        CreateJournalLineOpenApprovalEntryForCurrentUser(GenJournalLine);

        // [WHEN] User opens the journal batch
        Commit();
        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);

        // [THEN] Approval actions?
        Assert.IsFalse(PaymentJournal.SendApprovalRequestJournalLine.Enabled(), 'Send should be disabled');
        Assert.IsTrue(PaymentJournal.CancelApprovalRequestJournalLine.Enabled(), 'Send should be enabled');
        Assert.IsFalse(PaymentJournal.SendApprovalRequestJournalBatch.Enabled(), 'SendBatch should be disabled');
        Assert.IsFalse(PaymentJournal.CancelApprovalRequestJournalBatch.Enabled(), 'SendBatch should be disabled');
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
        Assert.IsTrue(CashReceiptJournal.SendApprovalRequestJournalLine.Enabled(), 'Send should be enabled');
        Assert.IsFalse(CashReceiptJournal.CancelApprovalRequestJournalLine.Enabled(), 'Send should be disabled');
        Assert.IsTrue(CashReceiptJournal.SendApprovalRequestJournalBatch.Enabled(), 'SendBatch should be enabled');
        Assert.IsFalse(CashReceiptJournal.CancelApprovalRequestJournalBatch.Enabled(), 'SendBatch should be disabled');
        Assert.IsFalse(CashReceiptJournal.Approve.Visible(), '');
        Assert.IsFalse(CashReceiptJournal.Reject.Visible(), '');
        Assert.IsFalse(CashReceiptJournal.Delegate.Visible(), '');

        // [THEN] Close the journal
        CashReceiptJournal.Close();

        // [GIVEN] Workflow is enabled
        EnableWorkflow(Workflow);

        // [WHEN] Approval entry exists for the batch
        CreateJournalLineOpenApprovalEntryForCurrentUser(GenJournalLine);

        // [WHEN] User opens the journal batch
        Commit();
        CashReceiptJournal.OpenEdit();
        CashReceiptJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);

        // [THEN] Approval actions?
        Assert.IsFalse(CashReceiptJournal.SendApprovalRequestJournalLine.Enabled(), 'Send should be disabled');
        Assert.IsTrue(CashReceiptJournal.CancelApprovalRequestJournalLine.Enabled(), 'Send should be enabled');
        Assert.IsFalse(CashReceiptJournal.SendApprovalRequestJournalBatch.Enabled(), 'SendBatch should be disabled');
        Assert.IsFalse(CashReceiptJournal.CancelApprovalRequestJournalBatch.Enabled(), 'SendBatch should be disabled');
        Assert.IsTrue(CashReceiptJournal.Approve.Visible(), '');
        Assert.IsTrue(CashReceiptJournal.Reject.Visible(), '');
        Assert.IsTrue(CashReceiptJournal.Delegate.Visible(), '');

        // [THEN] Close the journal
        CashReceiptJournal.Close();
    end;

    [Test]
    procedure ApprovalActionsVisibilityOnPurchaseJournal()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Workflow: Record Workflow;
        ApproverUserSetup: Record "User Setup";
        RequestorUserSetup: Record "User Setup";
        PurchaseJournal: TestPage "Purchase Journal";
    begin
        // [SCENARIO] Visibility of approval actions on a journal batch
        Initialize();

        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);

        // [GIVEN] Journal batch with one or more lines
        CreatePurchaseJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        // [GIVEN] Workflow is disabled
        CreateDirectApprovalWorkflow(Workflow);

        // [WHEN] User opens the journal batch
        Commit();
        PurchaseJournal.OpenEdit();
        PurchaseJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);

        // [THEN] Approval actions?
        Assert.IsFalse(PurchaseJournal.SendApprovalRequestJournalLine.Enabled(), 'Send should be disabled');
        Assert.IsFalse(PurchaseJournal.CancelApprovalRequestJournalLine.Enabled(), 'Send should be disabled');
        Assert.IsFalse(PurchaseJournal.SendApprovalRequestJournalBatch.Enabled(), 'SendBatch should be disabled');
        Assert.IsFalse(PurchaseJournal.CancelApprovalRequestJournalBatch.Enabled(), 'SendBatch should be disabled');
        Assert.IsFalse(PurchaseJournal.Approve.Visible(), '');
        Assert.IsFalse(PurchaseJournal.Reject.Visible(), '');
        Assert.IsFalse(PurchaseJournal.Delegate.Visible(), '');

        // [THEN] Close the journal
        PurchaseJournal.Close();

        // [GIVEN] Workflow is enabled
        EnableWorkflow(Workflow);

        // [WHEN] Approval entry exists for the batch
        CreateJournalLineOpenApprovalEntryForCurrentUser(GenJournalLine);

        // [WHEN] User opens the journal batch
        Commit();
        PurchaseJournal.OpenEdit();
        PurchaseJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);

        // [THEN] Approval actions?
        Assert.IsFalse(PurchaseJournal.SendApprovalRequestJournalLine.Enabled(), 'Send should be disabled');
        Assert.IsTrue(PurchaseJournal.CancelApprovalRequestJournalLine.Enabled(), 'Send should be enabled');
        Assert.IsFalse(PurchaseJournal.SendApprovalRequestJournalBatch.Enabled(), 'SendBatch should be disabled');
        Assert.IsFalse(PurchaseJournal.CancelApprovalRequestJournalBatch.Enabled(), 'SendBatch should be disabled');
        Assert.IsTrue(PurchaseJournal.Approve.Visible(), '');
        Assert.IsTrue(PurchaseJournal.Reject.Visible(), '');
        Assert.IsTrue(PurchaseJournal.Delegate.Visible(), '');

        // [THEN] Close the journal
        PurchaseJournal.Close();
    end;

    [Test]
    procedure ApprovalActionsVisibilityOnSalesJournal()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Workflow: Record Workflow;
        ApproverUserSetup: Record "User Setup";
        RequestorUserSetup: Record "User Setup";
        SalesJournal: TestPage "Sales Journal";
    begin
        // [SCENARIO] Visibility of approval actions on a journal batch
        Initialize();

        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);

        // [GIVEN] Journal batch with one or more lines
        CreateSalesJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        // [GIVEN] Workflow is disabled
        CreateDirectApprovalWorkflow(Workflow);

        // [WHEN] User opens the journal batch
        Commit();
        SalesJournal.OpenEdit();
        SalesJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);

        // [THEN] Approval actions?
        Assert.IsFalse(SalesJournal.SendApprovalRequestJournalLine.Enabled(), 'Send should be disabled');
        Assert.IsFalse(SalesJournal.CancelApprovalRequestJournalLine.Enabled(), 'Send should be disabled');
        Assert.IsFalse(SalesJournal.SendApprovalRequestJournalBatch.Enabled(), 'SendBatch should be disabled');
        Assert.IsFalse(SalesJournal.CancelApprovalRequestJournalBatch.Enabled(), 'SendBatch should be disabled');
        Assert.IsFalse(SalesJournal.Approve.Visible(), '');
        Assert.IsFalse(SalesJournal.Reject.Visible(), '');
        Assert.IsFalse(SalesJournal.Delegate.Visible(), '');

        // [THEN] Close the journal
        SalesJournal.Close();

        // [GIVEN] Workflow is enabled
        EnableWorkflow(Workflow);

        // [WHEN] Approval entry exists for the batch
        CreateJournalLineOpenApprovalEntryForCurrentUser(GenJournalLine);

        // [WHEN] User opens the journal batch
        Commit();
        SalesJournal.OpenEdit();
        SalesJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);

        // [THEN] Approval actions?
        Assert.IsFalse(SalesJournal.SendApprovalRequestJournalLine.Enabled(), 'Send should be disabled');
        Assert.IsTrue(SalesJournal.CancelApprovalRequestJournalLine.Enabled(), 'Send should be enabled');
        Assert.IsFalse(SalesJournal.SendApprovalRequestJournalBatch.Enabled(), 'SendBatch should be disabled');
        Assert.IsFalse(SalesJournal.CancelApprovalRequestJournalBatch.Enabled(), 'SendBatch should be disabled');
        Assert.IsTrue(SalesJournal.Approve.Visible(), '');
        Assert.IsTrue(SalesJournal.Reject.Visible(), '');
        Assert.IsTrue(SalesJournal.Delegate.Visible(), '');

        // [THEN] Close the journal
        SalesJournal.Close();
    end;

    local procedure Initialize()
    var
        Workflow: Record Workflow;
        UserSetup: Record "User Setup";
        GenJournalTemplate: Record "Gen. Journal Template";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryApplicationArea.EnableFoundationSetup();
        LibraryVariableStorage.Clear();
        Workflow.ModifyAll(Enabled, false, true);
        UserSetup.DeleteAll();
        GenJournalTemplate.DeleteAll();
        if IsInitialized then
            exit;

        IsInitialized := true;
        BindSubscription(LibraryJobQueue);
    end;

    local procedure CreateApprovalSetup(var ApproverUserSetup: Record "User Setup"; var RequestorUserSetup: Record "User Setup")
    begin
        LibraryDocumentApprovals.CreateOrFindUserSetup(RequestorUserSetup, UserId);
        LibraryDocumentApprovals.CreateMockupUserSetup(ApproverUserSetup);
        LibraryDocumentApprovals.SetApprover(RequestorUserSetup, ApproverUserSetup);
    end;

    local procedure CreateDirectApprovalWorkflow(var Workflow: Record Workflow)
    begin
        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.GeneralJournalLineApprovalWorkflowCode());
    end;

    local procedure CreateDirectApprovalEnabledWorkflow(var Workflow: Record Workflow)
    begin
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.GeneralJournalLineApprovalWorkflowCode());
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
          LibraryRandom.RandDecInRange(10000, 50000, 2));
    end;

    local procedure CreatePaymentJournalBatchWithOneJournalLine(var GenJournalBatch: Record "Gen. Journal Batch"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        CreateJournalBatch(GenJournalBatch, LibraryERM.SelectGenJnlTemplate());
        CreateJournalBatch(GenJournalBatch, LibraryPurchase.SelectPmtJnlTemplate());

        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
          LibraryRandom.RandDecInRange(10000, 50000, 2));
    end;

    local procedure CreatePurchaseJournalBatchWithOneJournalLine(var GenJournalBatch: Record "Gen. Journal Batch"; var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        CreateJournalBatch(GenJournalBatch, LibraryERM.SelectGenJnlTemplate());
        CreateJournalBatch(GenJournalBatch, LibraryJournals.SelectGenJournalTemplate(GenJournalTemplate.Type::Purchases, Page::"Purchase Journal"));

        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(),
          LibraryRandom.RandDecInRange(10000, 50000, 2));
    end;

    local procedure CreateSalesJournalBatchWithOneJournalLine(var GenJournalBatch: Record "Gen. Journal Batch"; var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        CreateJournalBatch(GenJournalBatch, LibraryERM.SelectGenJnlTemplate());
        CreateJournalBatch(GenJournalBatch, LibraryJournals.SelectGenJournalTemplate(GenJournalTemplate.Type::Sales, Page::"Sales Journal"));

        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
          LibraryRandom.RandDecInRange(10000, 50000, 2));
    end;

    local procedure CreateCashReceiptJournalBatchWithOneJournalLine(var GenJournalBatch: Record "Gen. Journal Batch"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        CreateJournalBatch(GenJournalBatch, LibraryERM.SelectGenJnlTemplate());
        CreateJournalBatch(GenJournalBatch, LibrarySales.SelectCashReceiptJnlTemplate());

        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
          LibraryRandom.RandDecInRange(10000, 50000, 2));
    end;

    local procedure CreateJournalBatchWithMultipleJournalLines(var GenJournalLine2: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine1: Record "Gen. Journal Line";
        GenJournalLine3: Record "Gen. Journal Line";
    begin
        CreateJournalBatch(GenJournalBatch, LibraryERM.SelectGenJnlTemplate());

        LibraryERM.CreateGeneralJnlLine(GenJournalLine1, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine1."Document Type"::Invoice, GenJournalLine1."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
          LibraryRandom.RandDecInRange(10000, 50000, 2));
        LibraryERM.CreateGeneralJnlLine(GenJournalLine2, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine2."Document Type"::Invoice, GenJournalLine2."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
          LibraryRandom.RandDecInRange(10000, 50000, 2));
        LibraryERM.CreateGeneralJnlLine(GenJournalLine3, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine3."Document Type"::Invoice, GenJournalLine3."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
          LibraryRandom.RandDecInRange(10000, 50000, 2));
    end;

    local procedure CreateJournalLineOpenApprovalEntryForCurrentUser(GenJournalLine: Record "Gen. Journal Line")
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        ApprovalEntry.Init();
        ApprovalEntry."Document Type" := GenJournalLine."Document Type";
        ApprovalEntry."Document No." := GenJournalLine."Document No.";
        ApprovalEntry."Table ID" := DATABASE::"Gen. Journal Line";
        ApprovalEntry."Record ID to Approve" := GenJournalLine.RecordId;
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
        GeneralJournal.SendApprovalRequestJournalLine.Invoke();
    end;

    local procedure SendApprovalRequestForCashReceipt(GenJournalBatchName: Code[20])
    var
        CashReceiptJournal: TestPage "Cash Receipt Journal";
    begin
        CashReceiptJournal.OpenView();
        CashReceiptJournal.CurrentJnlBatchName.SetValue(GenJournalBatchName);
        CashReceiptJournal.SendApprovalRequestJournalLine.Invoke();
    end;

    local procedure SendApprovalRequestForPaymentJournal(GenJournalBatchName: Code[20])
    var
        PaymentJournal: TestPage "Payment Journal";
    begin
        PaymentJournal.OpenView();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalBatchName);
        PaymentJournal.SendApprovalRequestJournalLine.Invoke();
    end;

    local procedure SendApprovalRequestForPurchaseJournal(GenJournalBatchName: Code[20])
    var
        PurchaseJournal: TestPage "Purchase Journal";
    begin
        PurchaseJournal.OpenView();
        PurchaseJournal.CurrentJnlBatchName.SetValue(GenJournalBatchName);
        PurchaseJournal.SendApprovalRequestJournalLine.Invoke();
    end;

    local procedure SendApprovalRequestForSalesJournal(GenJournalBatchName: Code[20])
    var
        SalesJournal: TestPage "Sales Journal";
    begin
        SalesJournal.OpenView();
        SalesJournal.CurrentJnlBatchName.SetValue(GenJournalBatchName);
        SalesJournal.SendApprovalRequestJournalLine.Invoke();
    end;

    local procedure SendFilteredApprovalRequest(GenJournalBatchName: Code[20]; LineNo: Integer)
    var
        GeneralJournal: TestPage "General Journal";
    begin
        GeneralJournal.OpenView();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatchName);
        GeneralJournal.FILTER.SetFilter("Line No.", Format(LineNo));
        GeneralJournal.SendApprovalRequestJournalLine.Invoke();
    end;

    local procedure CancelApprovalRequestForGeneralJournal(GenJournalBatchName: Code[20])
    var
        GeneralJournal: TestPage "General Journal";
    begin
        GeneralJournal.OpenView();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatchName);
        GeneralJournal.CancelApprovalRequestJournalLine.Invoke();
    end;

    local procedure CancelApprovalRequestForCashReceipt(GenJournalBatchName: Code[20])
    var
        CashReceiptJournal: TestPage "Cash Receipt Journal";
    begin
        CashReceiptJournal.OpenView();
        CashReceiptJournal.CurrentJnlBatchName.SetValue(GenJournalBatchName);
        CashReceiptJournal.CancelApprovalRequestJournalLine.Invoke();
    end;

    local procedure CancelApprovalRequestForPaymentJournal(GenJournalBatchName: Code[20])
    var
        PaymentJournal: TestPage "Payment Journal";
    begin
        PaymentJournal.OpenView();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalBatchName);
        PaymentJournal.CancelApprovalRequestJournalLine.Invoke();
    end;

    local procedure CancelApprovalRequestForPurchaseJournal(GenJournalBatchName: Code[20])
    var
        PurchaseJournal: TestPage "Purchase Journal";
    begin
        PurchaseJournal.OpenView();
        PurchaseJournal.CurrentJnlBatchName.SetValue(GenJournalBatchName);
        PurchaseJournal.CancelApprovalRequestJournalLine.Invoke();
    end;

    local procedure CancelApprovalRequestForSalesJournal(GenJournalBatchName: Code[20])
    var
        SalesJournal: TestPage "Sales Journal";
    begin
        SalesJournal.OpenView();
        SalesJournal.CurrentJnlBatchName.SetValue(GenJournalBatchName);
        SalesJournal.CancelApprovalRequestJournalLine.Invoke();
    end;

    local procedure CancelFilteredApprovalRequest(GenJournalBatchName: Code[20]; LineNo: Integer)
    var
        GeneralJournal: TestPage "General Journal";
    begin
        GeneralJournal.OpenView();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatchName);
        GeneralJournal.FILTER.SetFilter("Line No.", Format(LineNo));
        GeneralJournal.CancelApprovalRequestJournalLine.Invoke();
    end;

    local procedure AssignApprovalEntry(var ApprovalEntry: Record "Approval Entry"; UserSetup: Record "User Setup")
    begin
        ApprovalEntry."Approver ID" := UserSetup."User ID";
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

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    local procedure CheckUserCanCancelTheApprovalRequestForAGeneralJnlLine(GenJournalBatch: Record "Gen. Journal Batch"; CancelActionExpectedEnabled: Boolean)
    var
        GeneralJournal: TestPage "General Journal";
    begin
        GeneralJournal.OpenView();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        Assert.AreEqual(CancelActionExpectedEnabled, GeneralJournal.CancelApprovalRequestJournalLine.Enabled(),
          'Wrong state for the Cancel action');
        GeneralJournal.Close();
    end;

    local procedure CheckUserCanCancelTheApprovalRequestForAPaymentJnlLine(GenJournalBatch: Record "Gen. Journal Batch"; CancelActionExpectedEnabled: Boolean)
    var
        PaymentJournal: TestPage "Payment Journal";
    begin
        PaymentJournal.OpenView();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        Assert.AreEqual(CancelActionExpectedEnabled, PaymentJournal.CancelApprovalRequestJournalLine.Enabled(),
          'Wrong state for the Cancel action');
        PaymentJournal.Close();
    end;

    local procedure CheckUserCanCancelTheApprovalRequestForAPurchaseJnlLine(GenJournalBatch: Record "Gen. Journal Batch"; CancelActionExpectedEnabled: Boolean)
    var
        PurchaseJournal: TestPage "Purchase Journal";
    begin
        PurchaseJournal.OpenView();
        PurchaseJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        Assert.AreEqual(CancelActionExpectedEnabled, PurchaseJournal.CancelApprovalRequestJournalLine.Enabled(),
          'Wrong state for the Cancel action');
        PurchaseJournal.Close();
    end;

    local procedure CheckUserCanCancelTheApprovalRequestForASalesJnlLine(GenJournalBatch: Record "Gen. Journal Batch"; CancelActionExpectedEnabled: Boolean)
    var
        SalesJournal: TestPage "Sales Journal";
    begin
        SalesJournal.OpenView();
        SalesJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        Assert.AreEqual(CancelActionExpectedEnabled, SalesJournal.CancelApprovalRequestJournalLine.Enabled(),
          'Wrong state for the Cancel action');
        SalesJournal.Close();
    end;

    local procedure CheckUserCanCancelTheApprovalRequestForACashReceiptJnlLine(GenJournalBatch: Record "Gen. Journal Batch"; CancelActionExpectedEnabled: Boolean)
    var
        CashReceiptJournal: TestPage "Cash Receipt Journal";
    begin
        CashReceiptJournal.OpenView();
        CashReceiptJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        Assert.AreEqual(CancelActionExpectedEnabled, CashReceiptJournal.CancelApprovalRequestJournalLine.Enabled(),
          'Wrong state for the Cancel action');
        CashReceiptJournal.Close();
    end;

    local procedure CheckCommentsForDocumentOnGeneralJournalPage(GenJournalBatch: Record "Gen. Journal Batch"; NumberOfExpectedComments: Integer; CommentActionIsVisible: Boolean)
    var
        ApprovalComments: TestPage "Approval Comments";
        GeneralJournalPage: TestPage "General Journal";
        NumberOfComments: Integer;
    begin
        ApprovalComments.Trap();

        GeneralJournalPage.OpenView();
        GeneralJournalPage.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);

        Assert.AreEqual(CommentActionIsVisible, GeneralJournalPage.Comments.Visible(), 'The Comments action has the wrong visibility');

        if CommentActionIsVisible then begin
            GeneralJournalPage.Comments.Invoke();
            if ApprovalComments.First() then
                repeat
                    NumberOfComments += 1;
                until ApprovalComments.Next();
            Assert.AreEqual(NumberOfExpectedComments, NumberOfComments, 'The page contains the wrong number of comments');

            ApprovalComments.Comment.SetValue('Test Comment' + Format(NumberOfExpectedComments));
            ApprovalComments.Next();
            ApprovalComments.Close();
        end;

        GeneralJournalPage.Close();
    end;

    local procedure CheckCommentsForDocumentOnCashReceiptPage(GenJournalBatch: Record "Gen. Journal Batch"; NumberOfExpectedComments: Integer; CommentActionIsVisible: Boolean)
    var
        ApprovalComments: TestPage "Approval Comments";
        CashReceiptJournalPage: TestPage "Cash Receipt Journal";
        NumberOfComments: Integer;
    begin
        ApprovalComments.Trap();

        CashReceiptJournalPage.OpenView();
        CashReceiptJournalPage.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);

        Assert.AreEqual(CommentActionIsVisible, CashReceiptJournalPage.Comment.Visible(), 'The Comments action has the wrong visibility');

        if CommentActionIsVisible then begin
            CashReceiptJournalPage.Comment.Invoke();
            if ApprovalComments.First() then
                repeat
                    NumberOfComments += 1;
                until ApprovalComments.Next();
            Assert.AreEqual(NumberOfExpectedComments, NumberOfComments, 'The page contains the wrong number of comments');

            ApprovalComments.Comment.SetValue('Test Comment' + Format(NumberOfExpectedComments));
            ApprovalComments.Next();
            ApprovalComments.Close();
        end;

        CashReceiptJournalPage.Close();
    end;

    local procedure CheckCommentsForDocumentOnPaymentPage(GenJournalBatch: Record "Gen. Journal Batch"; NumberOfExpectedComments: Integer; CommentActionIsVisible: Boolean)
    var
        ApprovalComments: TestPage "Approval Comments";
        PaymentJournalPage: TestPage "Payment Journal";
        NumberOfComments: Integer;
    begin
        PaymentJournalPage.OpenView();
        PaymentJournalPage.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);

        Assert.AreEqual(CommentActionIsVisible, PaymentJournalPage.Comment.Visible(), 'The Comments action has the wrong visibility');

        if CommentActionIsVisible then begin
            ApprovalComments.Trap();
            PaymentJournalPage.Comment.Invoke();
            if ApprovalComments.First() then
                repeat
                    NumberOfComments += 1;
                until ApprovalComments.Next();
            Assert.AreEqual(NumberOfExpectedComments, NumberOfComments, 'The page contains the wrong number of comments');

            ApprovalComments.Comment.SetValue('Test Comment' + Format(NumberOfExpectedComments));
            ApprovalComments.Next();
            ApprovalComments.Close();
        end;

        PaymentJournalPage.Close();
    end;

    local procedure CheckCommentsForDocumentOnPurchaseJournalPage(GenJournalBatch: Record "Gen. Journal Batch"; NumberOfExpectedComments: Integer; CommentActionIsVisible: Boolean)
    var
        ApprovalComments: TestPage "Approval Comments";
        PurchaseJournalPage: TestPage "Purchase Journal";
        NumberOfComments: Integer;
    begin
        PurchaseJournalPage.OpenView();
        PurchaseJournalPage.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);

        Assert.AreEqual(CommentActionIsVisible, PurchaseJournalPage.Comments.Visible(), 'The Comments action has the wrong visibility');

        if CommentActionIsVisible then begin
            ApprovalComments.Trap();
            PurchaseJournalPage.Comments.Invoke();
            if ApprovalComments.First() then
                repeat
                    NumberOfComments += 1;
                until ApprovalComments.Next();
            Assert.AreEqual(NumberOfExpectedComments, NumberOfComments, 'The page contains the wrong number of comments');

            ApprovalComments.Comment.SetValue('Test Comment' + Format(NumberOfExpectedComments));
            ApprovalComments.Next();
            ApprovalComments.Close();
        end;

        PurchaseJournalPage.Close();
    end;

    local procedure CheckCommentsForDocumentOnSalesJournalPage(GenJournalBatch: Record "Gen. Journal Batch"; NumberOfExpectedComments: Integer; CommentActionIsVisible: Boolean)
    var
        ApprovalComments: TestPage "Approval Comments";
        SalesJournalPage: TestPage "Sales Journal";
        NumberOfComments: Integer;
    begin
        SalesJournalPage.OpenView();
        SalesJournalPage.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);

        Assert.AreEqual(CommentActionIsVisible, SalesJournalPage.Comments.Visible(), 'The Comments action has the wrong visibility');

        if CommentActionIsVisible then begin
            ApprovalComments.Trap();
            SalesJournalPage.Comments.Invoke();
            if ApprovalComments.First() then
                repeat
                    NumberOfComments += 1;
                until ApprovalComments.Next();
            Assert.AreEqual(NumberOfExpectedComments, NumberOfComments, 'The page contains the wrong number of comments');

            ApprovalComments.Comment.SetValue('Test Comment' + Format(NumberOfExpectedComments));
            ApprovalComments.Next();
            ApprovalComments.Close();
        end;

        SalesJournalPage.Close();
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

