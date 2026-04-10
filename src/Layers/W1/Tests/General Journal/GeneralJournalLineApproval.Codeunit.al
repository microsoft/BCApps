codeunit 134322 "General Journal Line Approval"
{
    EventSubscriberInstance = Manual;
    Permissions = TableData "Approval Entry" = imd;
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
        LibraryPaymentExport: Codeunit "Library - Payment Export";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWorkflow: Codeunit "Library - Workflow";
        WorkflowSetup: Codeunit "Workflow Setup";
        HasErrorsErr: Label 'Payment Export Format';
        NoApprovalCommentExistsErr: Label 'There is no approval comment for this approval entry.';
        RecordNotFoundErr: Label '%1 was not found.', Comment = 'Gen. Journal Line was not found.';
        RestrictionRecordFoundErr: Label 'Restricted Record for %1 was found.', Comment = 'Restricted Record for Gen. Journal Line: GENERAL,GUAAAAABEE,20000 was found.';
        RestrictionRecordNotFoundErr: Label 'Restricted Record for %1 was not found.', Comment = 'Restricted Record for Gen. Journal Line: GENERAL,GUAAAAABEE,20000 was not found.';
        RecordRestrictedErr: Label 'You cannot use %1 for this action.', Comment = 'You cannot use Customer 10000 for this action.';
        UnexpectedNoOfApprovalEntriesErr: Label 'Unexpected number of approval entries found.';
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        IsInitialized: Boolean;
        JournalLineNotApprovedCheckErr: Label 'You cannot use Gen. Journal Line: %1,%2,%3 for this action.\\The restriction was imposed because the line requires approval.';
        JournalBatchNotApprovedCheckErr: Label 'You cannot use Gen. Journal Line: %1,%2,%3 for this action.\\The restriction was imposed because the journal batch requires approval.';
        PreventDeleteRecordWithOpenApprovalEntryForSenderMsg: Label 'You can''t delete a record that has open approval entries. To delete a record, you need to Cancel approval request first.';
        ImposedRestrictionLbl: Label 'Imposed restriction';

    [Test]
    [Scope('OnPrem')]
    procedure DeleteAfterSendingRequest()
    var
        ApprovalEntry: Record "Approval Entry";
        ApproverUserSetup: Record "User Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        RequestorUserSetup: Record "User Setup";
        Workflow: Record Workflow;
    begin
        // [SCENARIO] Delete the line after sending an approval request will cancel the approval request and delete the approval entries.
        // [GIVEN] Journal batch with one line.
        // [GIVEN] Approval entries exist for one line.
        // [WHEN] The user deletes the line.
        // [THEN] Approval request is canceled and the approval entries are deleted.

        Initialize();

        // Setup
        CreateDirectApprovalEnabledWorkflow(Workflow);

        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        LibraryDocumentApprovals.CreateOrFindUserSetup(RequestorUserSetup, UserId);
        LibraryDocumentApprovals.CreateMockupUserSetup(ApproverUserSetup);
        LibraryDocumentApprovals.SetApprover(RequestorUserSetup, ApproverUserSetup);

        // Exercise
        Commit();
        SendApprovalRequest(GenJournalLine."Journal Batch Name");
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalLine.RecordId);
        AddApprovalComment(ApprovalEntry);

        // Verify
        Assert.AreEqual(1, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);
        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, RequestorUserSetup."User ID");
        VerifyApprovalEntryApproverID(ApprovalEntry, ApproverUserSetup."User ID");
        Assert.IsTrue(ApprovalCommentExists(ApprovalEntry), NoApprovalCommentExistsErr);

        // Exercise
        asserterror GenJournalLine.Delete(true);
        Assert.ExpectedError(PreventDeleteRecordWithOpenApprovalEntryForSenderMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RenameAfterSendingRequest()
    var
        ApprovalEntry: Record "Approval Entry";
        ApproverUserSetup: Record "User Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        RequestorUserSetup: Record "User Setup";
        Workflow: Record Workflow;
    begin
        // [SCENARIO] Rename the line after sending an approval request will change the approval entries to point to the new record.
        // [GIVEN] Journal batch with one line.
        // [GIVEN] Approval entries exist for one line.
        // [WHEN] The user renames the line.
        // [THEN] Approval entries are changed to point to the new record.

        Initialize();

        // Setup
        CreateDirectApprovalEnabledWorkflow(Workflow);

        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        LibraryDocumentApprovals.CreateOrFindUserSetup(RequestorUserSetup, UserId);
        LibraryDocumentApprovals.CreateMockupUserSetup(ApproverUserSetup);
        LibraryDocumentApprovals.SetApprover(RequestorUserSetup, ApproverUserSetup);

        // Exercise
        Commit();
        SendApprovalRequest(GenJournalLine."Journal Batch Name");
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalLine.RecordId);
        AddApprovalComment(ApprovalEntry);

        // Verify
        Assert.AreEqual(1, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, RequestorUserSetup."User ID");
        VerifyApprovalEntryApproverID(ApprovalEntry, ApproverUserSetup."User ID");
        Assert.IsTrue(ApprovalCommentExists(ApprovalEntry), NoApprovalCommentExistsErr);

        // Exercise
        GenJournalLine.Rename(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No." + 1);

        // Verify
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalLine.RecordId);
        Assert.AreEqual(1, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, RequestorUserSetup."User ID");
        VerifyApprovalEntryApproverID(ApprovalEntry, ApproverUserSetup."User ID");
        Assert.IsTrue(ApprovalCommentExists(ApprovalEntry), NoApprovalCommentExistsErr);
    end;

    [Test]
    [HandlerFunctions('ApprovalEntriesEmptyPageHandler')]
    [Scope('OnPrem')]
    procedure ShowApprovalEntriesEmptyPage()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Workflow: Record Workflow;
    begin
        // [SCENARIO] Display the approval entries page listing no approval entries
        // [GIVEN] Journal batch with one or more journal lines
        // [GIVEN] Approval entry exists for the journal batch
        // [GIVEN] No approval entries exist for the journal lines
        // [WHEN] Click the Approvals action
        // [WHEN] Select batch on the STRMENU dialog
        // [THEN] Empty page pops up

        Initialize();

        // Setup
        CreateDirectApprovalEnabledWorkflow(Workflow);

        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        // Exercise
        Commit();
        LibraryVariableStorage.Enqueue(GenJournalLine);
        ShowApprovalEntries(GenJournalLine."Journal Batch Name");

        // Verify
        // PageHandler verifies record
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ApprovalEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure ShowApprovalEntriesPage()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Workflow: Record Workflow;
    begin
        // [SCENARIO] Display the related approval entries
        // [GIVEN] Journal batch with one or more journal lines
        // [GIVEN] Approval entry does not exist for the journal batch
        // [GIVEN] Approval entries exist for one or more journal lines
        // [WHEN] Click the Approvals action
        // [WHEN] Select batch on the STRMENU dialog
        // [THEN] Page displays the journal batch approval entries

        Initialize();

        // Setup
        CreateDirectApprovalEnabledWorkflow(Workflow);

        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        CreateJournalLineOpenApprovalEntryForCurrentUser(GenJournalLine);

        // Exercise
        Commit();
        LibraryVariableStorage.Enqueue(GenJournalLine);
        ShowApprovalEntries(GenJournalLine."Journal Batch Name");

        // Verify
        // PageHandler verifies record
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChainOfApproversApproveRequest()
    var
        ApprovalEntry: Record "Approval Entry";
        FinalApproverUserSetup: Record "User Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        IntermediateApproverUserSetup: Record "User Setup";
        RequestorUserSetup: Record "User Setup";
        Workflow: Record Workflow;
    begin
        // [SCENARIO] Approve a pending request to approve journal lines
        // [GIVEN] Journal batch with one line
        // [GIVEN] Approval entries exist for one line
        // [WHEN] Approvers in the chain click the Approve action
        // [THEN] Approval entry is approved

        Initialize();

        // Setup
        CreateApprovalChainEnabledWorkflow(Workflow);

        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        LibraryDocumentApprovals.SetupUsersForApprovalsWithLimits(
          RequestorUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);

        // Exercise
        Commit();
        SendApprovalRequest(GenJournalLine."Journal Batch Name");

        // Verify
        VerifyChainApprovalEntriesAfterSendingForApproval(GenJournalLine.RecordId,
          RequestorUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);

        // Setup
        UpdateApprovalEntryWithCurrUser(ApprovalEntry, GenJournalLine.RecordId);

        // Exercise
        ApprovalEntry.Next();
        Approve(ApprovalEntry);

        // Verify
        VerifyChainApprovalEntriesAfterIntermediateApproval(GenJournalLine.RecordId, RequestorUserSetup, IntermediateApproverUserSetup);

        // Setup
        Clear(ApprovalEntry);
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalLine.RecordId);

        // Exercise
        ApprovalEntry.FindLast();
        Approve(ApprovalEntry);

        // Verify
        VerifyChainApprovalEntriesAfterFinalApproval(GenJournalLine.RecordId, RequestorUserSetup, IntermediateApproverUserSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChainOfApproversApproveFilteredRequest()
    var
        ApprovalEntry: Record "Approval Entry";
        FinalApproverUserSetup: Record "User Setup";
        GenJournalLine: Record "Gen. Journal Line";
        IntermediateApproverUserSetup: Record "User Setup";
        RequestorUserSetup: Record "User Setup";
        Workflow: Record Workflow;
    begin
        // [SCENARIO] Approve a pending request to approve journal lines
        // [GIVEN] Journal batch with one or more lines
        // [GIVEN] Subset of the lines are included in the request
        // [GIVEN] Approval entries exist for one line
        // [WHEN] Chain of approvers click the Approve action
        // [THEN] Approval entry is approved

        Initialize();

        // Setup
        CreateApprovalChainEnabledWorkflow(Workflow);

        CreateJournalBatchWithMultipleJournalLines(GenJournalLine);

        LibraryDocumentApprovals.SetupUsersForApprovalsWithLimits(
          RequestorUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);

        // Exercise
        Commit();
        SendFilteredApprovalRequest(GenJournalLine."Journal Batch Name", GenJournalLine."Line No.");

        // Verify
        VerifyChainApprovalEntriesAfterSendingForApproval(GenJournalLine.RecordId,
          RequestorUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);

        // Setup
        UpdateApprovalEntryWithCurrUser(ApprovalEntry, GenJournalLine.RecordId);

        // Exercise
        ApprovalEntry.Next();
        Approve(ApprovalEntry);

        // Verify
        VerifyChainApprovalEntriesAfterIntermediateApproval(GenJournalLine.RecordId, RequestorUserSetup, IntermediateApproverUserSetup);

        // Setup
        Clear(ApprovalEntry);
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalLine.RecordId);

        // Exercise
        ApprovalEntry.FindLast();
        Approve(ApprovalEntry);

        // Verify
        VerifyChainApprovalEntriesAfterFinalApproval(GenJournalLine.RecordId, RequestorUserSetup, IntermediateApproverUserSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChainOfApproversForCustomerAccountType()
    var
        ApprovalEntry: Record "Approval Entry";
        FinalApproverUserSetup: Record "User Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        IntermediateApproverUserSetup: Record "User Setup";
        RequestorUserSetup: Record "User Setup";
        Workflow: Record Workflow;
    begin
        // [SCENARIO] Request approval of a Customer journal line
        // [GIVEN] Journal batch with one line
        // [WHEN] Requestor clicks Send for Approval
        // [THEN] Approval entries are created for the chain of approvers

        Initialize();

        // Setup
        CreateApprovalChainEnabledWorkflow(Workflow);

        CreateGeneralJournalBatchWithOneCustomJournalLine(GenJournalBatch, GenJournalLine,
          GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
          GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting());

        LibraryDocumentApprovals.SetupUsersForApprovalsWithLimits(
          RequestorUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);

        // Exercise
        Commit();
        SendApprovalRequest(GenJournalLine."Journal Batch Name");

        // Verify
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalLine.RecordId);
        Assert.AreEqual(3, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChainOfApproversForCustomerBalAccountType()
    var
        ApprovalEntry: Record "Approval Entry";
        FinalApproverUserSetup: Record "User Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        IntermediateApproverUserSetup: Record "User Setup";
        RequestorUserSetup: Record "User Setup";
        Workflow: Record Workflow;
    begin
        // [SCENARIO] Request approval of a Customer journal line
        // [GIVEN] Journal batch with one line
        // [WHEN] Requestor clicks Send for Approval
        // [THEN] Approval entries are created for the chain of approvers

        Initialize();

        // Setup
        CreateApprovalChainEnabledWorkflow(Workflow);

        CreateGeneralJournalBatchWithOneCustomJournalLine(GenJournalBatch, GenJournalLine,
          GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(),
          GenJournalLine."Bal. Account Type"::Customer, LibrarySales.CreateCustomerNo());

        LibraryDocumentApprovals.SetupUsersForApprovalsWithLimits(
          RequestorUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);

        // Exercise
        Commit();
        SendApprovalRequest(GenJournalLine."Journal Batch Name");

        // Verify
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalLine.RecordId);
        Assert.AreEqual(3, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChainOfApproversForVendorAccountType()
    var
        ApprovalEntry: Record "Approval Entry";
        FinalApproverUserSetup: Record "User Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        IntermediateApproverUserSetup: Record "User Setup";
        RequestorUserSetup: Record "User Setup";
        Workflow: Record Workflow;
    begin
        // [SCENARIO] Request approval of a Vendor journal line for Vendor Account Type
        // [GIVEN] Journal batch with one line
        // [WHEN] Requestor clicks Send for Approval
        // [THEN] Approval entries are created for the chain of approvers

        Initialize();

        // Setup
        CreateApprovalChainEnabledWorkflow(Workflow);

        CreateGeneralJournalBatchWithOneCustomJournalLine(GenJournalBatch, GenJournalLine,
          GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(),
          GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting());

        LibraryDocumentApprovals.SetupUsersForApprovalsWithLimits(
          RequestorUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);

        // Exercise
        Commit();
        SendApprovalRequest(GenJournalLine."Journal Batch Name");

        // Verify
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalLine.RecordId);
        Assert.AreEqual(3, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChainOfApproversForVendorBalAccountType()
    var
        ApprovalEntry: Record "Approval Entry";
        FinalApproverUserSetup: Record "User Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        IntermediateApproverUserSetup: Record "User Setup";
        RequestorUserSetup: Record "User Setup";
        Workflow: Record Workflow;
    begin
        // [SCENARIO] Request approval of a Vendor journal line for Vendor Bal. Account Type
        // [GIVEN] Journal batch with one line
        // [WHEN] Requestor clicks Send for Approval
        // [THEN] Approval entries are created for the chain of approvers

        Initialize();

        // Setup
        CreateApprovalChainEnabledWorkflow(Workflow);

        CreateGeneralJournalBatchWithOneCustomJournalLine(GenJournalBatch, GenJournalLine,
          GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(),
          GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo());

        LibraryDocumentApprovals.SetupUsersForApprovalsWithLimits(
          RequestorUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);

        // Exercise
        Commit();
        SendApprovalRequest(GenJournalLine."Journal Batch Name");

        // Verify
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalLine.RecordId);
        Assert.AreEqual(3, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChainOfApproversForBankAccountType()
    var
        ApprovalEntry: Record "Approval Entry";
        BankAccount: Record "Bank Account";
        FinalApproverUserSetup: Record "User Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        IntermediateApproverUserSetup: Record "User Setup";
        RequestorUserSetup: Record "User Setup";
        Workflow: Record Workflow;
    begin
        // [SCENARIO] Request approval of a Bank journal line
        // [GIVEN] Journal batch with one line
        // [WHEN] Requestor clicks Send for Approval
        // [THEN] Approval entries are created for the chain of approvers

        Initialize();

        // Setup
        CreateApprovalChainEnabledWorkflow(Workflow);

        LibraryERM.CreateBankAccount(BankAccount);
        CreateGeneralJournalBatchWithOneCustomJournalLine(GenJournalBatch, GenJournalLine,
          GenJournalLine."Account Type"::"Bank Account", BankAccount."No.",
          GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting());

        LibraryDocumentApprovals.SetupUsersForApprovalsWithLimits(
          RequestorUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);

        // Exercise
        Commit();
        SendApprovalRequest(GenJournalLine."Journal Batch Name");

        // Verify
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalLine.RecordId);
        Assert.AreEqual(1, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChainOfApproversForBankBalAccountType()
    var
        ApprovalEntry: Record "Approval Entry";
        BankAccount: Record "Bank Account";
        FinalApproverUserSetup: Record "User Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        IntermediateApproverUserSetup: Record "User Setup";
        RequestorUserSetup: Record "User Setup";
        Workflow: Record Workflow;
    begin
        // [SCENARIO] Request approval of a Bank journal line
        // [GIVEN] Journal batch with one line
        // [WHEN] Requestor clicks Send for Approval
        // [THEN] Approval entries are created for the chain of approvers

        Initialize();

        // Setup
        CreateApprovalChainEnabledWorkflow(Workflow);

        LibraryERM.CreateBankAccount(BankAccount);
        CreateGeneralJournalBatchWithOneCustomJournalLine(GenJournalBatch, GenJournalLine,
          GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(),
          GenJournalLine."Account Type"::"Bank Account", BankAccount."No.");

        LibraryDocumentApprovals.SetupUsersForApprovalsWithLimits(
          RequestorUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);

        // Exercise
        Commit();
        SendApprovalRequest(GenJournalLine."Journal Batch Name");

        // Verify
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalLine.RecordId);
        Assert.AreEqual(2, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendGenJnlLineForApprovalRestrictsUsage()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        Workflow: Record Workflow;
        ApprovalUserSetup: Record "User Setup";
    begin
        // [SCENARIO] A newly created gen. jnl. line that is sent for approval cannot be posted.
        // [GIVEN] A new general journal line.
        // [WHEN] The user sends an approval request from the journal line.
        // [THEN] The general journal line cannot be posted.

        Initialize();

        // Setup
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);

        CreateDirectApprovalEnabledWorkflow(Workflow);

        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        // Exercise.
        Commit();
        SendApprovalRequest(GenJournalLine."Journal Batch Name");

        // Verify.
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);
        Assert.ExpectedError(StrSubstNo(RecordRestrictedErr, Format(GenJournalLine.RecordId, 0, 1)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InsertTempGenJnlLineDoesNotRestrictUsage()
    var
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        Workflow: Record Workflow;
        ApprovalUserSetup: Record "User Setup";
    begin
        // [SCENARIO] A temporary gen. jnl. line does not get restrictions.
        // [GIVEN] A new general journal line.
        // [WHEN] The temporary genral journal line is inserted.
        // [THEN] There is no restriction added.

        Initialize();

        // Setup
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);
        CreateDirectApprovalEnabledWorkflow(Workflow);
        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);
        GenJournalLine.Delete();
        VerifyRestrictionRecordNotExisting(GenJournalLine.RecordId);

        // Exercise.
        TempGenJournalLine := GenJournalLine;
        TempGenJournalLine.Insert();

        // Verify.
        VerifyRestrictionRecordNotExisting(TempGenJournalLine.RecordId);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CancelGenJnlLineForApprovalDoesNotAllowsUsage()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        Workflow: Record Workflow;
        ApprovalUserSetup: Record "User Setup";
    begin
        // [SCENARIO] A newly created gen. jnl. line that has a canceled approval can be posted.
        // [GIVEN] A new general journal line.
        // [WHEN] The user sends an approval request from the journal line.
        // [WHEN] The user cancels the approval.
        // [THEN] The general journal line is still restricted and cannot be posted.

        Initialize();

        // Setup
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);

        CreateDirectApprovalEnabledWorkflow(Workflow);

        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        Commit();
        SendApprovalRequest(GenJournalLine."Journal Batch Name");

        // Exercise.
        CancelApprovalRequest(GenJournalLine."Journal Batch Name");

        // Verify.
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);
        Assert.ExpectedError(StrSubstNo(RecordRestrictedErr, Format(GenJournalLine.RecordId, 0, 1)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApproveGenJnlLineForApprovalAllowsUsage()
    var
        ApprovalEntry: Record "Approval Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        Workflow: Record Workflow;
        ApprovalUserSetup: Record "User Setup";
        RequestorUserSetup: Record "User Setup";
    begin
        // [SCENARIO] A newly created gen. jnl. line that is approved can be posted.
        // [GIVEN] A new general journal line.
        // [WHEN] The user sends an approval request from the journal line.
        // [WHEN] The user approves the line.
        // [THEN] The general journal line can be posted.

        Initialize();

        // Setup
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);

        CreateDirectApprovalEnabledWorkflow(Workflow);

        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        Commit();
        SendApprovalRequest(GenJournalLine."Journal Batch Name");

        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalLine.RecordId);

        RequestorUserSetup.Get(UserId);
        AssignApprovalEntry(ApprovalEntry, RequestorUserSetup);

        // Exercise.
        Approve(ApprovalEntry);

        // Verify.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RestrictGenJournalLinePostingAfterInsertWithApprovalEnabled()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        Workflow: Record Workflow;
    begin
        // [SCENARIO] Restrict posting of journal lines
        // [GIVEN] Journal batch with one or more journal lines
        // [GIVEN] Approval workflow is enabled
        // [WHEN] New journal line is added
        // [WHEN] Post journal lines
        // [THEN] New journal line is restricted
        // [THEN] New journal line cannot be posted

        Initialize();

        // Setup
        CreateDirectApprovalWorkflow(Workflow);

        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        EnableWorkflow(Workflow);

        // Exercise
        LibraryERM.CreateGeneralJnlLine(GenJournalLine2, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine2."Document Type"::Invoice, GenJournalLine2."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
          LibraryRandom.RandDec(100, 2));

        // Verify
        VerifyRestrictionRecordNotExisting(GenJournalLine.RecordId);
        VerifyRestrictionRecordExists(GenJournalLine2.RecordId);

        // Exercise
        Commit();
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify
        Assert.ExpectedError(StrSubstNo(RecordRestrictedErr, Format(GenJournalLine2.RecordId, 0, 1)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RestrictGenJournalLinePostingAfterInsertWithApprovalDisabled()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        Workflow: Record Workflow;
    begin
        // [SCENARIO] Restrict posting of journal lines
        // [GIVEN] Journal batch with one or more journal lines
        // [GIVEN] Approval workflow is disabled
        // [WHEN] New journal line is added
        // [WHEN] Post journal lines
        // [THEN] Journal batch is posted

        Initialize();

        // Setup
        CreateDirectApprovalWorkflow(Workflow);

        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        // Exercise
        LibraryERM.CreateGeneralJnlLine(GenJournalLine2, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine2."Document Type"::Invoice, GenJournalLine2."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
          LibraryRandom.RandDec(100, 2));

        // Verify
        VerifyRestrictionRecordNotExisting(GenJournalLine.RecordId);
        VerifyRestrictionRecordNotExisting(GenJournalLine2.RecordId);

        // Exercise
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify
        VerifyCustomerLedgerEntryExists(GenJournalLine);
        VerifyCustomerLedgerEntryExists(GenJournalLine2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RestrictGenJournalLinePostingAfterInsertForSystemCreatedEntry()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        Workflow: Record Workflow;
    begin
        // [SCENARIO] Restrict posting of journal lines
        // [GIVEN] Journal batch with one or more journal lines
        // [GIVEN] Approval workflow is enabled
        // [WHEN] New journal line is added
        // [WHEN] New journal line is marked as a System-Created Entry
        // [THEN] New journal line is not restricted

        Initialize();

        // Setup
        CreateDirectApprovalWorkflow(Workflow);

        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        EnableWorkflow(Workflow);

        // Exercise
        GenJournalLine2.Init();
        GenJournalLine2."Journal Template Name" := GenJournalBatch."Journal Template Name";
        GenJournalLine2."Journal Batch Name" := GenJournalBatch.Name;
        GenJournalLine2."Line No." := 20000;
        GenJournalLine2."System-Created Entry" := true;
        GenJournalLine2.Insert();

        // Verify: No error.
        GenJournalLine2.OnCheckGenJournalLinePrintCheckRestrictions();
    end;


    [Test]
    [Scope('OnPrem')]
    procedure RestrictGenJournalLineExportingAfterInsertWithBatchApprovalDisabled()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        Workflow: Record Workflow;
    begin
        // [SCENARIO] Restrict exporting of payment journal lines
        // [GIVEN] Journal batch with one or more journal lines
        // [GIVEN] Journal line approval workflow is enabled
        // [GIVEN] Journal batch approval workflow is disabled
        // [WHEN] New journal line is added
        // [WHEN] Exporting journal lines
        // [THEN] New journal line is not restricted
        // [THEN] New journal line can be exported

        Initialize();

        // Setup
        CreateDirectApprovalEnabledWorkflow(Workflow);

        CreateJournalBatchWithBankBalancingAccount(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
          LibraryRandom.RandDec(100, 2));

        // Exercise
        LibraryERM.CreateGeneralJnlLine(GenJournalLine2, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine2."Document Type"::Invoice, GenJournalLine2."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
          LibraryRandom.RandDec(100, 2));

        // Verify
        VerifyRestrictionRecordNotExisting(GenJournalBatch.RecordId);
        VerifyRestrictionRecordExists(GenJournalLine.RecordId);
        VerifyRestrictionRecordExists(GenJournalLine2.RecordId);

        // Exercise
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        asserterror GenJournalLine.ExportPaymentFile();

        // Verify
        Assert.ExpectedError(HasErrorsErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RestrictGenJournalLineExportingAfterInsertForSystemCreatedEntry()
    var
        BatchWorkflow: Record Workflow;
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        LineWorkflow: Record Workflow;
    begin
        // [SCENARIO] Restrict exporting of payment journal lines
        // [GIVEN] Journal batch with one or more journal lines
        // [GIVEN] Journal line approval workflow is enabled
        // [GIVEN] Journal batch approval workflow is enabled
        // [WHEN] New journal line is added
        // [WHEN] New journal line is marked as a System-Created Entry
        // [THEN] New journal line is restricted

        Initialize();

        // Setup
        CreateDirectApprovalEnabledWorkflow(LineWorkflow);
        CreateJournalBatchDirectApprovalEnabledWorkflow(BatchWorkflow);

        CreateJournalBatchWithBankBalancingAccount(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
          LibraryRandom.RandDec(100, 2));

        // Exercise
        LibraryERM.CreateGeneralJnlLine(GenJournalLine2, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine2."Document Type"::Invoice, GenJournalLine2."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
          LibraryRandom.RandDec(100, 2));
        GenJournalLine2."System-Created Entry" := true;
        GenJournalLine2.Modify();

        // Verify
        VerifyRestrictionRecordExists(GenJournalLine.RecordId);
        VerifyRestrictionRecordExists(GenJournalLine2.RecordId);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RestrictGenJournalLineCheckPrintingAfterInsertWithApprovalEnabled()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Workflow: Record Workflow;
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [SCENARIO] Restrict printing checks for journal lines
        // [GIVEN] Journal batch with one or more journal lines
        // [GIVEN] Approval workflow is enabled
        // [WHEN] Computer Check is selected as a bank payment type
        // [WHEN] Journal line is printed
        // [THEN] New journal line is restricted
        // [THEN] Check cannot be printed

        Initialize();

        // Setup
        CreateDirectApprovalEnabledWorkflow(Workflow);
        CreatePmtJnlBatchWithOneInvoiceLineForAccTypeCustomer(GenJournalBatch, GenJournalLine);

        // Exercise
        GenJournalLine."Bank Payment Type" := GenJournalLine."Bank Payment Type"::"Computer Check";
        GenJournalLine.Modify();

        // Verify
        VerifyRestrictionRecordExists(GenJournalLine.RecordId);

        // Exercise
        Commit();
        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        asserterror PaymentJournal.PrintCheck.Invoke();

        // Verify
        Assert.ExpectedError(StrSubstNo(RecordRestrictedErr, Format(GenJournalLine.RecordId, 0, 1)));
    end;

    [Test]
    [HandlerFunctions('CheckRequestPageHandler')]
    [Scope('OnPrem')]
    procedure RestrictGenJournalLineCheckPrintingAfterInsertWithApprovalDisabled()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Workflow: Record Workflow;
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [SCENARIO] Restrict printing checks for journal lines
        // [GIVEN] Journal batch with one or more journal lines
        // [GIVEN] Approval workflow is enabled
        // [WHEN] Computer Check is selected as a bank payment type
        // [WHEN] Journal line is printed
        // [THEN] New journal line is not restricted
        // [THEN] Check can be printed

        Initialize();

        // Setup
        CreateDirectApprovalWorkflow(Workflow);

        CreatePmtJnlBatchWithOneInvoiceLineForAccTypeCustomer(GenJournalBatch, GenJournalLine);

        // Exercise
        GenJournalLine."Bank Payment Type" := GenJournalLine."Bank Payment Type"::"Computer Check";
        GenJournalLine.Modify();

        // Verify
        VerifyRestrictionRecordNotExisting(GenJournalLine.RecordId);

        // Exercise
        Commit();
        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        PaymentJournal.PrintCheck.Invoke();
        PaymentJournal.Close();

        // Verify
        // RequestPageHandler
    end;

    [Test]
    [HandlerFunctions('CheckRequestPageHandler')]
    [Scope('OnPrem')]
    procedure RestrictGenJournalLineCheckPrintingAfterInsertWithSystemCreatedEntry()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Workflow: Record Workflow;
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [SCENARIO] Restrict printing checks for journal lines
        // [GIVEN] Journal batch with one or more system created journal lines
        // [GIVEN] Approval workflow is enabled
        // [WHEN] Computer Check is selected as a bank payment type
        // [WHEN] Journal line is printed
        // [THEN] New journal line is not restricted
        // [THEN] Check can be printed

        Initialize();

        // Setup
        CreateDirectApprovalEnabledWorkflow(Workflow);

        CreateJournalBatch(GenJournalBatch, LibraryPurchase.SelectPmtJnlTemplate(),
          GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting());

        // Exercise
        GenJournalLine."Journal Template Name" := GenJournalBatch."Journal Template Name";
        GenJournalLine."Journal Batch Name" := GenJournalBatch.Name;
        GenJournalLine."Line No." := 10000;
        GenJournalLine."Bank Payment Type" := GenJournalLine."Bank Payment Type"::"Computer Check";
        GenJournalLine."System-Created Entry" := true;
        GenJournalLine.Insert();

        // Verify
        VerifyRestrictionRecordNotExisting(GenJournalLine.RecordId);

        // Exercise
        Commit();
        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        PaymentJournal.PrintCheck.Invoke();
        PaymentJournal.Close();

        // Verify
        // RequestPageHandler
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckLedgerEntryBeforeInsertCheckGenJournalLineCheckPrintingRestrictions()
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        CheckMgt: Codeunit CheckManagement;
        RecordRestrictionMgt: Codeunit "Record Restriction Mgt.";
    begin
        // [SCENARIO] Restrict printing checks for journal lines
        // [GIVEN] Journal batch with one or more journal lines
        // [GIVEN] Journal line is restricted
        // [WHEN] Check ledger entry is created
        // [THEN] Check ledger entry cannot be inserted

        Initialize();

        // Setup
        CreatePmtJnlBatchWithOneInvoiceLineForAccTypeCustomer(GenJournalBatch, GenJournalLine);

        RecordRestrictionMgt.RestrictRecordUsage(GenJournalLine, CheckLedgerEntry.TableCaption());

        // Exercise
        Commit();
        CheckLedgerEntry.Init();
        asserterror CheckMgt.InsertCheck(CheckLedgerEntry, GenJournalLine.RecordId);

        // Verify
        Assert.ExpectedError(StrSubstNo(RecordRestrictedErr, Format(GenJournalLine.RecordId, 0, 1)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckLedgerEntryBeforeModifyCheckGenJournalLineCheckPrintingRestrictions()
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        CheckMgt: Codeunit CheckManagement;
        RecordRestrictionMgt: Codeunit "Record Restriction Mgt.";
    begin
        // [SCENARIO] Restrict printing checks for journal lines
        // [GIVEN] Journal batch with one or more journal lines
        // [GIVEN] Check ledger entry related to journal line
        // [WHEN] Journal line is restricted
        // [WHEN] Check ledger entry is changed
        // [THEN] Check ledger entry cannot be modified

        Initialize();

        // Setup
        CreatePmtJnlBatchWithOneInvoiceLineForAccTypeCustomer(GenJournalBatch, GenJournalLine);

        CheckLedgerEntry.Init();
        CheckMgt.InsertCheck(CheckLedgerEntry, GenJournalLine.RecordId);

        RecordRestrictionMgt.RestrictRecordUsage(GenJournalLine, CheckLedgerEntry.TableCaption());

        // Exercise
        Commit();
        asserterror CheckLedgerEntry.Modify();

        // Verify
        Assert.ExpectedError(StrSubstNo(RecordRestrictedErr, Format(GenJournalLine.RecordId, 0, 1)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RemoveGenJournalLineCheckPrintingRestrictionAfterModify()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Workflow: Record Workflow;
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [SCENARIO] Restrict printing checks for journal lines
        // [GIVEN] Journal batch with one or more journal lines
        // [GIVEN] Approval workflow is enabled
        // [WHEN] Computer Check is selected as a bank payment type
        // [WHEN] Journal line is printed
        // [THEN] New journal line is restricted
        // [THEN] Check cannot be printed

        Initialize();

        // Setup
        CreateDirectApprovalWorkflow(Workflow);
        CreatePmtJnlBatchWithOneInvoiceLineForAccTypeCustomer(GenJournalBatch, GenJournalLine);
        GenJournalLine."Bank Payment Type" := GenJournalLine."Bank Payment Type"::"Computer Check";
        GenJournalLine.Modify();
        EnableWorkflow(Workflow);

        // Verify
        VerifyRestrictionRecordNotExisting(GenJournalLine.RecordId);

        // Exercise
        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalLine."Journal Batch Name");
        PaymentJournal."Bank Payment Type".SetValue(GenJournalLine."Bank Payment Type"::" ");
        PaymentJournal.OK().Invoke();

        // Verify
        VerifyRestrictionRecordExists(GenJournalLine.RecordId);
    end;

    [Test]
    [HandlerFunctions('PrintCheckRequestPageHandler')]
    [Scope('OnPrem')]
    procedure GenJournalLineNoRestrictionAfterCheckPrinted()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Workflow: Record Workflow;
        RequestorUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        ApprovalEntry: Record "Approval Entry";
        GLRegister: Record "G/L Register";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [SCENARIO] Restrict journal lines check printing and posting
        // [GIVEN] Journal batch with one or more journal lines
        // [GIVEN] Approval workflow is enabled
        // [WHEN] Computer Check is selected as a bank payment type
        // [WHEN] Journal line is approved
        // [WHEN] Journal line check is printed
        // [THEN] Journal line can be posted with no further approval needed

        Initialize();

        // Setup: Approvals workflow
        CreateDirectApprovalEnabledWorkflow(Workflow);
        LibraryDocumentApprovals.SetupUsersForApprovalsWithLimits(
          RequestorUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);

        // Setup: Journal Line
        CreatePmtJnlBatchWithOneInvoiceLineForAccTypeCustomer(GenJournalBatch, GenJournalLine);
        GenJournalLine."Bank Payment Type" := GenJournalLine."Bank Payment Type"::"Computer Check";
        GenJournalLine.Modify();

        // Verify
        VerifyRestrictionRecordExists(GenJournalLine.RecordId);

        // Setup: Approve the journal line.
        Commit();
        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalLine."Journal Batch Name");
        PaymentJournal.SendApprovalRequestJournalLine.Invoke();

        UpdateApprovalEntryWithCurrUser(ApprovalEntry, GenJournalLine.RecordId);

        ApprovalEntry.FindFirst();
        Approve(ApprovalEntry);

        // Exercise: Print the check.
        Commit();
        LibraryVariableStorage.Enqueue(GenJournalLine."Bal. Account No.");
        PaymentJournal.PrintCheck.Invoke();

        // Verify
        VerifyRestrictionRecordNotExisting(GenJournalLine.RecordId);

        // Exercise: No error when posting.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify
        GLRegister.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GLRegister.FindLast();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LineWorkflowStatusFactboxBecomesVisibleWhenSentOnApproval()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        Workflow: Record Workflow;
        ApprovalUserSetup: Record "User Setup";
        GeneralJournal: TestPage "General Journal";
    begin
        // [SCENARIO] Line workflow status factbox becomes visible when the line is sent for approval
        // [GIVEN] Journal batch with one or more journal lines
        // [WHEN] Click the Send Approval Request action on line
        // [THEN] Line workflow status factbox becomes visible.

        Initialize();

        // Setup
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);

        CreateDirectApprovalEnabledWorkflow(Workflow);

        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        Commit();
        GeneralJournal.OpenView();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);

        Assert.IsFalse(GeneralJournal.WorkflowStatusBatch.WorkflowDescription.Visible(), 'Batch workflow Status factbox is not hidden');
        Assert.IsFalse(GeneralJournal.WorkflowStatusLine.WorkflowDescription.Visible(), 'Line workflow Status factbox is not hidden');

        // Exercise.
        GeneralJournal.SendApprovalRequestJournalLine.Invoke();

        // Verify.
        Assert.IsFalse(GeneralJournal.WorkflowStatusBatch.WorkflowDescription.Visible(), 'Batch workflow Status factbox is not hidden');
        Assert.IsTrue(GeneralJournal.WorkflowStatusLine.WorkflowDescription.Visible(), 'Line workflow Status factbox is hidden');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure LineWorkflowStatusFactboxBecomesNotVisibleWhenCancelApproval()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        Workflow: Record Workflow;
        ApprovalUserSetup: Record "User Setup";
        GeneralJournal: TestPage "General Journal";
    begin
        // [SCENARIO 209184] Line workflow status factbox becomes not visible when the approval is cancelled

        Initialize();

        // [GIVEN] Journal batch with one or more journal lines
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);

        CreateDirectApprovalEnabledWorkflow(Workflow);

        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        // [GIVEN] Approval request sent
        Commit();
        GeneralJournal.OpenView();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        GeneralJournal.SendApprovalRequestJournalLine.Invoke();

        // [WHEN] Click the Cancel Approval Request action
        GeneralJournal.CancelApprovalRequestJournalLine.Invoke();

        // [THEN] Line workflow status factbox becomes not visible.
        Assert.IsFalse(GeneralJournal.WorkflowStatusBatch.WorkflowDescription.Visible(), 'Batch workflow Status factbox is not hidden');
        Assert.IsFalse(GeneralJournal.WorkflowStatusLine.WorkflowDescription.Visible(), 'Line workflow Status factbox is not hidden');
    end;

    [Test]
    [HandlerFunctions('MessageHandler,PrintCheckRequestWithOneCheckPerVendorPageHandler')]
    [Scope('OnPrem')]
    procedure RestrictedRecordIsNotCreatedForCheckPrintedJournalLine()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 235046] Payment Journal Line created as result of Check Print is not restricted record when General Journal Batch Approval Workflow is enabled.
        Initialize();

        // [GIVEN] General Journal Batch Approval Workflow is enabled for direct approvers.
        // [GIVEN] Approval User Setup with direct approvers.
        SetupGenJnlBatchApprovalWorkflowWithUsers();

        // [GIVEN] Payment Journal Batch "Batch" with a Payment Line "PL" to Vendor.
        CreatePmtJnlBatchWithOnePaymentLineForAccTypeVendor(
          GenJournalBatch, GenJournalLine, GenJournalLine."Bank Payment Type"::"Computer Check");

        // [GIVEN] "Batch" is send for approval and approved.
        SendAndApprovePaymentJournalBatch(GenJournalLine, GenJournalBatch.RecordId);

        Commit();

        // [WHEN] A Check is printed for "PL" with "One Check per Vendor per Document No." option.
        LibraryVariableStorage.Enqueue(GenJournalBatch."Bal. Account No.");
        LibraryVariableStorage.Enqueue(true);
        PrintCheckForPaymentJournalLine(GenJournalLine, GenJournalLine."Bal. Account Type"::"G/L Account");

        // [THEN] A new Payment Line "PL-check" is created for Check.
        VerifyPaymentJournalLineCreatedforCheck(GenJournalLine, GenJournalBatch."Bal. Account No.");

        // [THEN] No restricted record is created for "PL-check"
        VerifyRestrictionRecordNotExisting(GenJournalLine.RecordId);

        // [THEN] "Batch" is posted.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        VerifyVendorLedgerEntryExistsWithExternalDocNo(GenJournalLine);
    end;

    [Test]
    [HandlerFunctions('PrintCheckRequestWithOneCheckPerVendorPageHandler')]
    [Scope('OnPrem')]
    procedure PmtJnlBatchPostedWithPrintCheck()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 235046] Payment Journal Batch Line created with Check Printed posted while no Approval Workflows enabled.
        Initialize();

        // [GIVEN] Payment Journal Batch "Batch" with a Payment Line "PL" to Vendor.
        CreatePmtJnlBatchWithOnePaymentLineForAccTypeVendor(
          GenJournalBatch, GenJournalLine, GenJournalLine."Bank Payment Type"::"Computer Check");
        Commit();

        // [WHEN] A Check is printed for "PL" without "One Check per Vendor per Document No." option.
        LibraryVariableStorage.Enqueue(GenJournalBatch."Bal. Account No.");
        LibraryVariableStorage.Enqueue(false);
        PrintCheckForPaymentJournalLine(GenJournalLine, GenJournalLine."Bal. Account Type"::"Bank Account");

        // [THEN] "Check Printed" is set for "PL".
        GenJournalLine.Find();
        GenJournalLine.TestField("Check Printed", true);

        // [THEN] "Batch" is posted.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        VerifyVendorLedgerEntryExists(GenJournalLine);
    end;

    [Test]
    [HandlerFunctions('PrintCheckRequestWithOneCheckPerVendorPageHandler')]
    [Scope('OnPrem')]
    procedure PmtJnlBatchPostedWithPrintCheckAndOneCheckPerVendorOption()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 235046] Payment Journal Batch Line created with Check Printed with "One Check Per Vendor" option posted while no Approval Workflows enabled.
        Initialize();

        // [GIVEN] Payment Journal Batch "Batch" with a Payment Line "PL" to Vendor.
        CreatePmtJnlBatchWithOnePaymentLineForAccTypeVendor(
          GenJournalBatch, GenJournalLine, GenJournalLine."Bank Payment Type"::"Computer Check");

        Commit();

        // [WHEN] A Check is printed for "PL" with "One Check per Vendor per Document No." option.
        LibraryVariableStorage.Enqueue(GenJournalBatch."Bal. Account No.");
        LibraryVariableStorage.Enqueue(true);
        PrintCheckForPaymentJournalLine(GenJournalLine, GenJournalLine."Bal. Account Type"::"G/L Account");

        // [THEN] A new Payment Line "PL-check" is created for Check.
        VerifyPaymentJournalLineCreatedforCheck(GenJournalLine, GenJournalBatch."Bal. Account No.");

        // [THEN] "Batch" is posted.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        VerifyVendorLedgerEntryExistsWithExternalDocNo(GenJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtJnlBatchMustBeApprovedToPrintCheck()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        RestrictedRecord: Record "Restricted Record";
    begin
        // [SCENARIO 235046] Payment Journal Batch must be approved before print the check.
        Initialize();

        // [GIVEN] General Journal Batch Approval Workflow is enabled for direct approvers.
        // [GIVEN] Approval User Setup with direct approvers.
        SetupGenJnlBatchApprovalWorkflowWithUsers();

        // [GIVEN] Payment Journal Batch "Batch" with a Payment Line "PL" to Vendor.
        // [GIVEN] "Batch" is not approved.
        CreatePmtJnlBatchWithOnePaymentLineForAccTypeVendor(
          GenJournalBatch, GenJournalLine, GenJournalLine."Bank Payment Type"::"Computer Check");

        Commit();

        // [WHEN] Check Print is called for "Batch" with "One Check per Vendor per Document No." option.
        LibraryVariableStorage.Enqueue(GenJournalBatch."Bal. Account No.");
        LibraryVariableStorage.Enqueue(true);
        asserterror PrintCheckForPaymentJournalLine(GenJournalLine, GenJournalLine."Bal. Account Type"::"G/L Account");

        // [THEN] Check cannot be printed with error invoked: "You cannot use Gen. Journal Line: %1,%2,%3 for this action.\\The restriction was imposed because the journal batch requires approval."
        Assert.ExpectedError(
          StrSubstNo(
            JournalBatchNotApprovedCheckErr,
            GenJournalLine."Journal Template Name",
            GenJournalLine."Journal Batch Name",
            Format(GenJournalLine."Line No.")));

        // [THEN] Restricted Record for "PL" exists.
        RestrictedRecord.SetRange("Record ID", GenJournalLine.RecordId);
        Assert.RecordIsNotEmpty(RestrictedRecord);
    end;

    [Test]
    [HandlerFunctions('PrintCheckRequestWithOneCheckPerVendorPageHandler')]
    [Scope('OnPrem')]
    procedure RestrictCheckPrintWhenNotAllGenJnlLinesWereApprovedWithOneCheckPerVendorOption()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: array[2] of Record "Gen. Journal Line";
    begin
        // [SCENARIO 235046] With General Journal Line Approval Workflow enabled, all Payment Journal Lines must be approved to print Check with "One Check Per Vendor" option from Payment Journal.
        Initialize();

        // [GIVEN] General Journal Line Approval Workflow is enabled for direct approvers.
        // [GIVEN] Approval User Setup with direct approvers.
        SetupGenJnlLineApprovalWorkflowWithUsers();

        // [GIVEN] Payment Journal Batch with two Payment Lines "PL1" and "PL2" to Vendor, both with Document No. = "DOC".
        CreatePmtJnlBatchWithTwoPaymentLinesForAccTypeVendor(GenJournalBatch, GenJournalLine);

        // [GIVEN] "PL1" is send for approval and approved.
        SendAndApprovePaymentJournalLine(GenJournalLine[1], GenJournalLine[1].RecordId);
        Commit();

        // [WHEN] Print Check for "PL1" with "One Check per Vendor per Document No." option.
        LibraryVariableStorage.Enqueue(GenJournalBatch."Bal. Account No.");
        LibraryVariableStorage.Enqueue(true);
        asserterror PrintCheckForPaymentJournalLine(GenJournalLine[1], GenJournalLine[1]."Bal. Account Type"::"G/L Account");

        // [THEN] Check cannot be printed with error invoked: "You cannot use Gen. Journal Line: %1,%2,%3 for this action.\\The restriction was imposed because the line requires approval."
        Assert.ExpectedError(
          StrSubstNo(
            JournalLineNotApprovedCheckErr,
            GenJournalLine[2]."Journal Template Name",
            GenJournalLine[2]."Journal Batch Name",
            Format(GenJournalLine[2]."Line No.")));
    end;

    [Test]
    [HandlerFunctions('PrintCheckRequestWithOneCheckPerVendorPageHandler')]
    [Scope('OnPrem')]
    procedure RestrictCheckPrintWhenNotAllGenJnlLinesWereApprovedWithoutOneCheckPerVendorOption()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: array[2] of Record "Gen. Journal Line";
    begin
        // [SCENARIO 235046] With General Journal Line Approval Workflow enabled, all Payment Journal Lines must be approved to print Check without "One Check Per Vendor" option from Payment Journal.
        Initialize();

        // [GIVEN] General Journal Line Approval Workflow is enabled for direct approvers.
        // [GIVEN] Approval User Setup with direct approvers.
        SetupGenJnlLineApprovalWorkflowWithUsers();

        // [GIVEN] Payment Journal Batch with two Payment Lines "PL1" and "PL2" to Vendor, both with Document No. = "DOC".
        CreatePmtJnlBatchWithTwoPaymentLinesForAccTypeVendor(GenJournalBatch, GenJournalLine);

        // [GIVEN] "PL1" is send for approval and approved.
        SendAndApprovePaymentJournalLine(GenJournalLine[1], GenJournalLine[1].RecordId);
        Commit();

        // [WHEN] Print Check for "PL1" without "One Check per Vendor per Document No." option.
        LibraryVariableStorage.Enqueue(GenJournalBatch."Bal. Account No.");
        LibraryVariableStorage.Enqueue(false);
        asserterror PrintCheckForPaymentJournalLine(GenJournalLine[1], GenJournalLine[1]."Bal. Account Type"::"G/L Account");

        // [THEN] Check cannot be printed with error invoked: "You cannot use Gen. Journal Line: %1,%2,%3 for this action.\\The restriction was imposed because the line requires approval."
        Assert.ExpectedError(
          StrSubstNo(
            JournalLineNotApprovedCheckErr,
            GenJournalLine[2]."Journal Template Name",
            GenJournalLine[2]."Journal Batch Name",
            Format(GenJournalLine[2]."Line No.")));
    end;

    [Test]
    procedure GenJournalLineApprovalRequestIsApprovedForPurchaserAndFirstQualifiedApprover()
    var
        RequestorUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Vendor: Record Vendor;
        Workflow: Record Workflow;
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        ApprovalEntry: Record "Approval Entry";
    begin
        // [SCENARIO 481473] Gen. Journal Line Approval Request is automatically approved for Purchaser approver type and first qualified approver limit type
        Initialize();

        // [GIVEN] Approval setup with users and approval limits       
        LibraryDocumentApprovals.SetupUsersForApprovalsWithLimits(
            RequestorUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);
        RequestorUserSetup."Purchase Amount Approval Limit" := 1000;
        RequestorUserSetup.Modify(true);

        // [GIVEN] Approval workflow where "Approver Type" = "Salesperson/Purchaser"
        CreateSalesPersonFirstQualifiedApprovalEnabledWorkflow(Workflow, WorkflowSetup.GeneralJournalLineApprovalWorkflowCode());

        // [GIVEN] Create Vendor with "Purchaser Code" = "X"
        LibraryPurchase.CreateVendor(Vendor);
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        Vendor.Validate("Purchaser Code", SalespersonPurchaser.Code);
        Vendor.Modify(true);

        // [GIVEN] Update Purchaser for user A
        RequestorUserSetup.Validate("Salespers./Purch. Code", SalespersonPurchaser.Code);
        RequestorUserSetup.Modify(true);

        // [GIVEN] Create Gen. Journal Batch with one Gen. Journal Line
        CreateJournalBatch(GenJournalBatch, LibraryERM.SelectGenJnlTemplate(), GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting());
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::Vendor, Vendor."No.", LibraryRandom.RandDecInRange(10, 100, 2));

        // [WHEN] Send approval request for Gen. Journal Line
        SendApprovalRequest(GenJournalLine."Journal Batch Name");

        // [THEN] Verify that Gen. Journal Line is approved
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalLine.RecordId);
        Assert.AreEqual(ApprovalEntry.Status, ApprovalEntry.Status::Approved, '');
    end;

    [Test]
    procedure GenJournalLineApprovalRequestIsSentForPaymentDocTypeAndGLAccountForApprovalChainLimitType()
    var
        RequestorUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        Workflow: Record Workflow;
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        ApprovalEntry: Record "Approval Entry";
    begin
        // [SCENARIO 479546] Gen. Journal Line Approval Request is sent for Payment Doc. Type and G/L Account for Approval Chain limit type
        Initialize();

        // [GIVEN] Approval setup with users and approval limits       
        LibraryDocumentApprovals.SetupUsersForApprovalsWithLimits(
            RequestorUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);
        RequestorUserSetup."Request Amount Approval Limit" := 10;
        RequestorUserSetup.Modify(true);

        // [GIVEN] Approval workflow where "Approver Type" = "Approver"
        CreateApprovalChainEnabledWorkflow(Workflow);

        // [GIVEN] Create Gen. Journal Batch with one Gen. Journal Line
        CreateJournalBatch(GenJournalBatch, LibraryERM.SelectGenJnlTemplate(), GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting());
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::"Payment", GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(), LibraryRandom.RandDecInRange(10, 100, 2));

        // [WHEN] Send approval request for Gen. Journal Line
        SendApprovalRequest(GenJournalLine."Journal Batch Name");

        // [THEN] Verify that Gen. Journal Line is sent
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalLine.RecordId);
        ApprovalEntry.FindLast();
        Assert.AreEqual(ApprovalEntry.Status, ApprovalEntry.Status::Open, '');
    end;

    [Test]
    procedure ShowImposedRestrictionLineApprovalStatusIfUserModifyGenJournalLineForApprovedApprovalRequest()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Workflow: Record Workflow;
        ApprovalUserSetup: Record "User Setup";
        GeneralJournal: TestPage "General Journal";
        ApprovalStatus: Enum "Approval Status";
    begin
        // [SCENARIO 498314] Show imposed restriction line status if user modifies Gen. Journal Line for approved approval request 
        Initialize();
        GenJournalTemplate.DeleteAll();

        // [GIVEN] Enable Gen. Journal Batch Approval Workflow
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);
        CreateDirectApprovalEnabledWorkflow(Workflow);

        // [GIVEN] Create Gen. Journal Line
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(),
          GenJournalLine."Document Type"::" ", LibraryRandom.RandDec(100, 2));

        // [GIVEN] Create Approval Entry for Gen. Journal Line with a status Approved
        GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");
        CreateApprovalEntryForCurrentUser(GenJournalLine.RecordId, ApprovalStatus::Approved);

        // [WHEN] Modify a Gen. Journal Line
        GenJournalLine.Validate(Amount, LibraryRandom.RandDec(100, 2));
        GenJournalLine.Modify(true);

        // [THEN] Verify result
        GeneralJournal.OpenView();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        Assert.AreEqual(ImposedRestrictionLbl, GeneralJournal.GenJnlLineApprovalStatus.Value, 'Imposed restriction is not shown');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure RenumberMultipleGenjnlLineHasRestrictedRecord()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: array[3] of Record "Gen. Journal Line";
        Workflow: Record Workflow;
        ApprovalUserSetup: Record "User Setup";
        GeneralJournal: TestPage "General Journal";
    begin
        // [SCENARIO 539249] After renumbering doc numbers on the General Journal Lines approval workflow. Restricted Entry created for all General Journal Line
        Initialize();

        // [GIVEN] Delete All the General Journal Template
        GenJournalTemplate.DeleteAll();

        // [GIVEN] Enable Gen. Journal Batch Approval Workflow
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);
        CreateDirectApprovalEnabledWorkflow(Workflow);

        // [GIVEN] Create multipe Gen. Journal Line
        CreateMultipleGenJnlLine(GenJournalLine);

        // [GIVEN] Create Approval Entry for Gen. Journal Line with a status Approved
        GenJournalBatch.Get(GenJournalLine[1]."Journal Template Name", GenJournalLine[1]."Journal Batch Name");
        CreateMultipleApprovalEntry(GenJournalLine);

        // [WHEN] Renumber the document
        GeneralJournal.OpenView();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        GeneralJournal."Renumber Document Numbers".Invoke();
        GeneralJournal.Close();

        // [THEN] Verify: Restrictd record created for all the General Journal Line.
        VerifyMultipleRestrictionRecordExists(GenJournalLine);
    end;

    local procedure Initialize()
    var
        Workflow: Record Workflow;
        UserSetup: Record "User Setup";
        GenJournalTemplate: Record "Gen. Journal Template";
        ApprovalEntry: Record "Approval Entry";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryApplicationArea.EnableFoundationSetup();
        LibraryVariableStorage.Clear();

        Workflow.ModifyAll(Enabled, false, true);
        UserSetup.DeleteAll();

        GenJournalTemplate.DeleteAll();
        ApprovalEntry.DeleteAll();
        if IsInitialized then
            exit;

        IsInitialized := true;
        BindSubscription(LibraryJobQueue);
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
    end;

    local procedure CreateDirectApprovalWorkflow(var Workflow: Record Workflow)
    begin
        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.GeneralJournalLineApprovalWorkflowCode());
    end;

    local procedure CreateDirectApprovalEnabledWorkflow(var Workflow: Record Workflow)
    begin
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.GeneralJournalLineApprovalWorkflowCode());
    end;

    local procedure CreateApprovalChainEnabledWorkflow(var Workflow: Record Workflow)
    begin
        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.GeneralJournalLineApprovalWorkflowCode());
        LibraryWorkflow.SetWorkflowChainApprover(Workflow.Code);
        EnableWorkflow(Workflow);
    end;

    local procedure CreateJournalBatchDirectApprovalEnabledWorkflow(var Workflow: Record Workflow)
    begin
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.GeneralJournalBatchApprovalWorkflowCode());
    end;

    local procedure EnableWorkflow(var Workflow: Record Workflow)
    begin
        Workflow.Validate(Enabled, true);
        Workflow.Modify(true);
    end;

    local procedure CreateJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; JournalTemplateName: Code[10]; BalAccountType: Enum "Gen. Journal Account Type"; BalAccountNo: Code[20])
    begin
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, JournalTemplateName);
        GenJournalBatch.Validate("Bal. Account Type", BalAccountType);
        GenJournalBatch.Validate("Bal. Account No.", BalAccountNo);
        GenJournalBatch.Modify(true);
    end;

    local procedure CreateJournalBatchWithBankBalancingAccount(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryPaymentExport.CreateBankAccount(BankAccount);
        CreateJournalBatch(GenJournalBatch,
          LibraryERM.SelectGenJnlTemplate(), GenJournalBatch."Bal. Account Type"::"Bank Account", BankAccount."No.");
    end;

    local procedure CreateGeneralJournalBatchWithOneJournalLine(var GenJournalBatch: Record "Gen. Journal Batch"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        CreateGeneralJournalBatchWithOneCustomJournalLine(GenJournalBatch, GenJournalLine,
          GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
          GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting());
    end;

    local procedure CreateGeneralJournalBatchWithOneCustomJournalLine(var GenJournalBatch: Record "Gen. Journal Batch"; var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20];
                                                                                                                                                                                         BalAccountType: Enum "Gen. Journal Account Type";
                                                                                                                                                                                         BalAccountNo: Code[20])
    begin
        CreateJournalBatch(GenJournalBatch, LibraryERM.SelectGenJnlTemplate(), BalAccountType, BalAccountNo);

        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
GenJournalLine."Document Type"::Invoice, AccountType, AccountNo, LibraryRandom.RandDecInRange(10000, 50000, 2));
    end;

    local procedure CreatePmtJnlBatchWithOneInvoiceLineForAccTypeCustomer(var GenJournalBatch: Record "Gen. Journal Batch"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        CreatePaymentJournalBatchWithOneJournalLine(
          GenJournalBatch, GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo());
    end;

    local procedure CreatePmtJnlBatchWithOnePaymentLineForAccTypeVendor(var GenJournalBatch: Record "Gen. Journal Batch"; var GenJournalLine: Record "Gen. Journal Line"; BankPaymentType: Enum "Bank Payment Type")
    begin
        CreatePaymentJournalBatchWithOneJournalLine(
          GenJournalBatch, GenJournalLine, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo());
        GenJournalLine."Bank Payment Type" := BankPaymentType;
        GenJournalLine.Modify();
    end;

    local procedure CreatePmtJnlBatchWithTwoPaymentLinesForAccTypeVendor(var GenJournalBatch: Record "Gen. Journal Batch"; var GenJournalLine: array[2] of Record "Gen. Journal Line")
    begin
        CreatePaymentJournalBatchWithOneJournalLine(
          GenJournalBatch, GenJournalLine[1], GenJournalLine[1]."Document Type"::Payment,
          GenJournalLine[1]."Account Type"::Vendor, LibraryPurchase.CreateVendorNo());

        GenJournalLine[1]."Bank Payment Type" := GenJournalLine[1]."Bank Payment Type"::"Computer Check";
        GenJournalLine[1].Modify();

        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine[2], GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine[2]."Document Type"::Payment, GenJournalLine[2]."Account Type"::Vendor,
          GenJournalLine[1]."Account No.", LibraryRandom.RandDec(100, 2));

        GenJournalLine[2]."Document No." := GenJournalLine[1]."Document No.";
        GenJournalLine[2]."Bank Payment Type" := GenJournalLine[2]."Bank Payment Type"::"Computer Check";
        GenJournalLine[2].Modify();
    end;

    local procedure CreatePaymentJournalBatchWithOneJournalLine(var GenJournalBatch: Record "Gen. Journal Batch"; var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type";
                                                                                                                                                                                    AccountNo: Code[20])
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount."Last Check No." := Format(1);
        BankAccount.Modify();

        CreateJournalBatch(GenJournalBatch, LibraryERM.SelectGenJnlTemplate(),
          GenJournalLine."Bal. Account Type"::"Bank Account", BankAccount."No.");
        CreateJournalBatch(GenJournalBatch, LibraryPurchase.SelectPmtJnlTemplate(),
          GenJournalLine."Bal. Account Type"::"Bank Account", BankAccount."No.");

        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          DocumentType, AccountType, AccountNo, LibraryRandom.RandDec(100, 2));
    end;

    local procedure CreateJournalBatchWithMultipleJournalLines(var GenJournalLine2: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine1: Record "Gen. Journal Line";
        GenJournalLine3: Record "Gen. Journal Line";
    begin
        CreateJournalBatch(GenJournalBatch, LibraryERM.SelectGenJnlTemplate(),
          GenJournalBatch."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting());

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
        ApprovalEntry."Approver ID" := UserId;
        ApprovalEntry.Status := ApprovalEntry.Status::Open;
        ApprovalEntry."Sequence No." := 1;
        ApprovalEntry.Insert();
    end;

    local procedure PrintCheckForPaymentJournalLine(GenJournalLine: Record "Gen. Journal Line"; BalAccountType: Enum "Gen. Journal Account Type")
    var
        DocumentPrint: Codeunit "Document-Print";
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        DocumentPrint.PrintCheck(GenJournalLine);
        GenJournalLine.ModifyAll("Bal. Account Type", BalAccountType, false);
    end;

    local procedure SendApprovalRequest(GenJournalBatchName: Code[20])
    var
        GeneralJournal: TestPage "General Journal";
    begin
        GeneralJournal.OpenView();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatchName);
        GeneralJournal.SendApprovalRequestJournalLine.Invoke();
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

    local procedure SendAndApprovePaymentJournalBatch(GenJournalLine: Record "Gen. Journal Line"; RecID: RecordID)
    var
        ApprovalEntry: Record "Approval Entry";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        ApprovalsMgmt.TrySendJournalBatchApprovalRequest(GenJournalLine);
        UpdateApprovalEntryWithCurrUser(ApprovalEntry, RecID);
        Approve(ApprovalEntry);
    end;

    local procedure SendAndApprovePaymentJournalLine(var GenJournalLine: Record "Gen. Journal Line"; RecID: RecordID)
    var
        ApprovalEntry: Record "Approval Entry";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        GenJournalLine.SetRecFilter();
        ApprovalsMgmt.TrySendJournalLineApprovalRequests(GenJournalLine);
        UpdateApprovalEntryWithCurrUser(ApprovalEntry, RecID);
        Approve(ApprovalEntry);
    end;

    local procedure CancelApprovalRequest(GenJournalBatchName: Code[20])
    var
        GeneralJournal: TestPage "General Journal";
    begin
        GeneralJournal.OpenView();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatchName);
        GeneralJournal.CancelApprovalRequestJournalLine.Invoke();
    end;

    local procedure SetupGenJnlBatchApprovalWorkflowWithUsers()
    var
        UserSetup: Record "User Setup";
        Workflow: Record Workflow;
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.GeneralJournalBatchApprovalWorkflowCode());
        LibraryDocumentApprovals.SetupUsersForApprovals(UserSetup);
    end;

    local procedure SetupGenJnlLineApprovalWorkflowWithUsers()
    var
        UserSetup: Record "User Setup";
        Workflow: Record Workflow;
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.GeneralJournalLineApprovalWorkflowCode());
        LibraryDocumentApprovals.SetupUsersForApprovals(UserSetup);
    end;

    local procedure ShowApprovalEntries(GenJournalBatchName: Code[20])
    var
        GeneralJournal: TestPage "General Journal";
    begin
        GeneralJournal.OpenView();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatchName);
        GeneralJournal.Approvals.Invoke();
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

    local procedure UpdateApprovalEntryWithCurrUser(var ApprovalEntry: Record "Approval Entry"; RecID: RecordID)
    begin
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, RecID);
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(RecID);
    end;

    local procedure VerifyApprovalEntryIsApproved(ApprovalEntry: Record "Approval Entry")
    begin
        ApprovalEntry.TestField(Status, ApprovalEntry.Status::Approved);
    end;

    local procedure VerifyApprovalEntryIsOpen(ApprovalEntry: Record "Approval Entry")
    begin
        ApprovalEntry.TestField(Status, ApprovalEntry.Status::Open);
    end;

    local procedure VerifyApprovalEntryIsCreated(ApprovalEntry: Record "Approval Entry")
    begin
        ApprovalEntry.TestField(Status, ApprovalEntry.Status::Created);
    end;

    local procedure VerifyApprovalEntrySenderID(ApprovalEntry: Record "Approval Entry"; SenderId: Code[50])
    begin
        ApprovalEntry.TestField("Sender ID", SenderId);
    end;

    local procedure VerifyApprovalEntryApproverID(ApprovalEntry: Record "Approval Entry"; ApproverId: Code[50])
    begin
        ApprovalEntry.TestField("Approver ID", ApproverId);
    end;

    local procedure VerifyChainApprovalEntriesAfterSendingForApproval(RecordID: RecordID; RequestorUserSetup: Record "User Setup"; IntermediateApproverUserSetup: Record "User Setup"; FinalApproverUserSetup: Record "User Setup")
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, RecordID);
        Assert.AreEqual(3, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        VerifyApprovalEntryIsApproved(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, RequestorUserSetup."User ID");
        VerifyApprovalEntryApproverID(ApprovalEntry, RequestorUserSetup."User ID");

        ApprovalEntry.Next();
        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, RequestorUserSetup."User ID");
        VerifyApprovalEntryApproverID(ApprovalEntry, IntermediateApproverUserSetup."User ID");

        ApprovalEntry.Next();
        VerifyApprovalEntryIsCreated(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, RequestorUserSetup."User ID");
        VerifyApprovalEntryApproverID(ApprovalEntry, FinalApproverUserSetup."User ID");
    end;

    local procedure VerifyChainApprovalEntriesAfterIntermediateApproval(RecordID: RecordID; RequestorUserSetup: Record "User Setup"; IntermediateApproverUserSetup: Record "User Setup")
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, RecordID);
        Assert.AreEqual(3, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        VerifyApprovalEntryIsApproved(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, IntermediateApproverUserSetup."User ID");
        VerifyApprovalEntryApproverID(ApprovalEntry, RequestorUserSetup."User ID");

        ApprovalEntry.Next();
        VerifyApprovalEntryIsApproved(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, IntermediateApproverUserSetup."User ID");
        VerifyApprovalEntryApproverID(ApprovalEntry, RequestorUserSetup."User ID");

        ApprovalEntry.Next();
        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, IntermediateApproverUserSetup."User ID");
        VerifyApprovalEntryApproverID(ApprovalEntry, RequestorUserSetup."User ID");
    end;

    local procedure VerifyChainApprovalEntriesAfterFinalApproval(RecordID: RecordID; RequestorUserSetup: Record "User Setup"; IntermediateApproverUserSetup: Record "User Setup")
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, RecordID);
        Assert.AreEqual(3, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        VerifyApprovalEntryIsApproved(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, IntermediateApproverUserSetup."User ID");
        VerifyApprovalEntryApproverID(ApprovalEntry, RequestorUserSetup."User ID");

        ApprovalEntry.Next();
        VerifyApprovalEntryIsApproved(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, IntermediateApproverUserSetup."User ID");
        VerifyApprovalEntryApproverID(ApprovalEntry, RequestorUserSetup."User ID");

        ApprovalEntry.Next();
        VerifyApprovalEntryIsApproved(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, IntermediateApproverUserSetup."User ID");
        VerifyApprovalEntryApproverID(ApprovalEntry, RequestorUserSetup."User ID");
    end;

    local procedure VerifyPaymentJournalLineCreatedforCheck(GenJournalLine: Record "Gen. Journal Line"; BalAccountNo: Code[20])
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJournalLine.FindLast();
        GenJournalLine.TestField("Account Type", GenJournalLine."Account Type"::"Bank Account");
        GenJournalLine.TestField("Account No.", BalAccountNo);
    end;

    local procedure VerifyRestrictionRecordExists(RecID: RecordID)
    var
        RestrictedRecord: Record "Restricted Record";
    begin
        RestrictedRecord.SetRange("Record ID", RecID);
        Assert.IsFalse(RestrictedRecord.IsEmpty, StrSubstNo(RestrictionRecordNotFoundErr, RecID));
    end;

    local procedure VerifyRestrictionRecordNotExisting(RecID: RecordID)
    var
        RestrictedRecord: Record "Restricted Record";
    begin
        RestrictedRecord.SetRange("Record ID", RecID);
        Assert.IsTrue(RestrictedRecord.IsEmpty, StrSubstNo(RestrictionRecordFoundErr, RecID));
    end;

    local procedure VerifyCustomerLedgerEntryExists(GenJournalLine: Record "Gen. Journal Line")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");
        CustLedgerEntry.SetRange("Customer No.", GenJournalLine."Account No.");
        CustLedgerEntry.SetRange(Open, true);
        Assert.IsFalse(CustLedgerEntry.IsEmpty, StrSubstNo(RecordNotFoundErr, CustLedgerEntry.TableCaption()));
    end;

    local procedure VerifyVendorLedgerEntryExists(GenJournalLine: Record "Gen. Journal Line")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");
        VendorLedgerEntry.SetRange("Vendor No.", GenJournalLine."Account No.");
        VendorLedgerEntry.SetRange(Open, true);
        Assert.IsFalse(VendorLedgerEntry.IsEmpty, StrSubstNo(RecordNotFoundErr, VendorLedgerEntry.TableCaption()));
    end;

    local procedure VerifyVendorLedgerEntryExistsWithExternalDocNo(GenJournalLine: Record "Gen. Journal Line")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Document Type", GenJournalLine."Document Type");
        VendorLedgerEntry.SetRange("External Document No.", GenJournalLine."Document No.");
        VendorLedgerEntry.SetRange("Vendor No.", GenJournalLine."Account No.");
        VendorLedgerEntry.SetRange(Open, true);
        Assert.IsFalse(VendorLedgerEntry.IsEmpty, StrSubstNo(RecordNotFoundErr, VendorLedgerEntry.TableCaption()));
    end;

    local procedure CreateSalesPersonFirstQualifiedApprovalEnabledWorkflow(var Workflow: Record Workflow; WorkflowCode: Code[17])
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        CreateCustomApproverTypeWorkflow(
          Workflow, WorkflowStepArgument."Approver Limit Type"::"First Qualified Approver", WorkflowCode);
        FindWorkflowStepArgument(Workflow, WorkflowStepArgument);
        WorkflowStepArgument.Validate("Approver Type", WorkflowStepArgument."Approver Type"::"Salesperson/Purchaser");
        WorkflowStepArgument.Modify(true);
        EnableWorkflow(Workflow);
    end;

    local procedure CreateCustomApproverTypeWorkflow(var Workflow: Record Workflow; ApproverLimitType: Enum "Workflow Approver Limit Type"; WorkflowCode: Code[17])
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowCode);
        FindWorkflowStepArgument(Workflow, WorkflowStepArgument);
        WorkflowStepArgument.Validate("Approver Limit Type", ApproverLimitType);
        WorkflowStepArgument.Modify(true);
    end;

    local procedure FindWorkflowStepArgument(Workflow: Record Workflow; var WorkflowStepArgument: Record "Workflow Step Argument")
    var
        WorkflowStep: Record "Workflow Step";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        WorkflowStep.SetRange("Workflow Code", Workflow.Code);
        WorkflowStep.SetRange(Type, WorkflowStep.Type::Response);
        WorkflowStep.SetRange("Function Name", WorkflowResponseHandling.CreateApprovalRequestsCode());
        WorkflowStep.FindFirst();
        WorkflowStepArgument.Get(WorkflowStep.Argument);
    end;

    local procedure CreateApprovalEntryForCurrentUser(RecordID: RecordID; ApprovalStatus: Enum "Approval Status")
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        ApprovalEntry.Init();
        ApprovalEntry."Document Type" := ApprovalEntry."Document Type"::" ";
        ApprovalEntry."Document No." := '';
        ApprovalEntry."Table ID" := RecordID.TableNo;
        ApprovalEntry."Record ID to Approve" := RecordID;
        ApprovalEntry."Approver ID" := UserId;
        ApprovalEntry.Status := ApprovalStatus;
        ApprovalEntry."Sequence No." := 1;
        ApprovalEntry.Insert();
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20];
                                                                                                              DocumentType: Enum "Gen. Journal Document Type";
                                                                                                              Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType, AccountType, AccountNo, Amount);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ApprovalEntriesEmptyPageHandler(var ApprovalEntries: TestPage "Approval Entries")
    var
        Variant: Variant;
    begin
        LibraryVariableStorage.Dequeue(Variant);
        Assert.IsFalse(ApprovalEntries.First(), 'The page is not empty');
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ApprovalEntriesPageHandler(var ApprovalEntries: TestPage "Approval Entries")
    var
        GenJournalLine: Record "Gen. Journal Line";
        Variant: Variant;
    begin
        LibraryVariableStorage.Dequeue(Variant);
        GenJournalLine := Variant;

        Assert.IsTrue(ApprovalEntries.First(), 'The page is empty');
        ApprovalEntries.RecordIDText.AssertEquals(Format(GenJournalLine.RecordId, 0, 1));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CheckRequestPageHandler(var Check: TestRequestPage Check)
    begin
        Check.Cancel().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    local procedure AddApprovalComment(ApprovalEntry: Record "Approval Entry")
    var
        ApprovalCommentLine: Record "Approval Comment Line";
    begin
        ApprovalCommentLine.Init();
        ApprovalCommentLine."Table ID" := ApprovalEntry."Table ID";
        ApprovalCommentLine."Document Type" := ApprovalEntry."Document Type";
        ApprovalCommentLine."Document No." := ApprovalEntry."Document No.";
        ApprovalCommentLine."Record ID to Approve" := ApprovalEntry."Record ID to Approve";
        ApprovalCommentLine.Comment := 'Test';
        ApprovalCommentLine.Insert();
    end;

    local procedure ApprovalCommentExists(ApprovalEntry: Record "Approval Entry"): Boolean
    var
        ApprovalCommentLine: Record "Approval Comment Line";
    begin
        ApprovalCommentLine.SetRange("Table ID", ApprovalEntry."Table ID");
        ApprovalCommentLine.SetRange("Document Type", ApprovalEntry."Document Type");
        ApprovalCommentLine.SetRange("Document No.", ApprovalEntry."Document No.");
        ApprovalCommentLine.SetRange("Record ID to Approve", ApprovalEntry."Record ID to Approve");
        exit(ApprovalCommentLine.FindFirst())
    end;

    local procedure CreateMultipleGenJnlLine(var GenJnlLine: array[3] of Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        i: Integer;
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        for i := 1 to ArrayLen(GenJnlLine) do begin
            LibraryERM.CreateGeneralJnlLine(
                GenJnlLine[i],
                GenJournalBatch."Journal Template Name",
                GenJournalBatch.Name,
                GenJnlLine[i]."Account Type"::"G/L Account",
                GenJnlLine[i]."Document Type"::" ",
                LibraryERM.CreateGLAccountNo(),
                LibraryRandom.RandDec(100, 2));
            GenJnlLine[i].Validate("Document No.", Format(GenJnlLine[i]."Line No."));
            GenJnlLine[i].Modify();
        end;
    end;

    local procedure CreateMultipleApprovalEntry(GenJnlLine: array[3] of Record "Gen. Journal Line")
    var
        ApprovalStatus: Enum "Approval Status";
        i: Integer;
    begin
        for i := 1 to ArrayLen(GenJnlLine) do
            CreateApprovalEntryForCurrentUser(GenJnlLine[1].RecordId, ApprovalStatus::Approved);
    end;

    local procedure VerifyMultipleRestrictionRecordExists(var GenJnlLine: array[3] of Record "Gen. Journal Line")
    var
        i: Integer;
    begin
        for i := 1 to ArrayLen(GenJnlLine) do
            VerifyRestrictionRecordExists(GenJnlLine[i].RecordId);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PrintCheckRequestPageHandler(var Check: TestRequestPage Check)
    var
        BankAccNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(BankAccNo);
        Check.BankAccount.SetValue(BankAccNo);
        Check.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PrintCheckRequestWithOneCheckPerVendorPageHandler(var Check: TestRequestPage Check)
    begin
        Check.BankAccount.SetValue(LibraryVariableStorage.DequeueText());
        Check.OneCheckPerVendorPerDocumentNo.SetValue(LibraryVariableStorage.DequeueBoolean());
        Check.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(QuestionText: Text[1024]; var Relpy: Boolean)
    begin
        Relpy := true;
    end;

}

