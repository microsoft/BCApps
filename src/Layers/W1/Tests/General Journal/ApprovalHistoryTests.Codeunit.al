codeunit 134323 "Approval History Tests"
{
    EventSubscriberInstance = Manual;
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
        LibraryWorkflow: Codeunit "Library - Workflow";
        WorkflowSetup: Codeunit "Workflow Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        LibraryUtility: Codeunit "Library - Utility";
        IsInitialized: Boolean;

    local procedure Initialize()
    var
        Workflow: Record Workflow;
        UserSetup: Record "User Setup";
        GenJournalTemplate: Record "Gen. Journal Template";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryApplicationArea.EnableFoundationSetup();
        Workflow.ModifyAll(Enabled, false, true);
        UserSetup.DeleteAll();
        LibraryERMCountryData.CreateVATData();
        GenJournalTemplate.DeleteAll();
        if IsInitialized then
            exit;

        IsInitialized := true;
        BindSubscription(LibraryJobQueue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostGenJnlLineApprovalsForCustomer()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO] An approved gen. jnl. line that is posted together with its approvals.
        // [GIVEN] An approved general journal line.
        // [WHEN] The gen. jnl line is posted.
        // [THEN] The approval entries and comments are posted as well.

        Initialize();

        // Setup
        ExecuteApprovalWorkflowForJournalLine(GenJournalLine, GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo());

        // Exercise.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify.
        VerifyCustLedgerEntryPostedApprovals(GenJournalLine);
        VerifyApprovalEntriesAreDeleted(GenJournalLine.RecordId);
        VerifyApprovalCommentsAreDeleted(GenJournalLine.RecordId);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostGenJnlLineApprovalsForVendor()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO] An approved gen. jnl. line that is posted together with its approvals.
        // [GIVEN] An approved general journal line.
        // [WHEN] The gen. jnl line is posted.
        // [THEN] The approval entries and comments are posted as well.

        Initialize();

        // Setup
        ExecuteApprovalWorkflowForJournalLine(GenJournalLine, GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo());

        // Exercise.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify.
        VerifyVendorLedgerEntryPostedApprovals(GenJournalLine);
        VerifyApprovalEntriesAreDeleted(GenJournalLine.RecordId);
        VerifyApprovalCommentsAreDeleted(GenJournalLine.RecordId);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostGenJnlLineApprovalsForBankAccount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
    begin
        // [SCENARIO] An approved gen. jnl. line that is posted together with its approvals.
        // [GIVEN] An approved general journal line.
        // [WHEN] The gen. jnl line is posted.
        // [THEN] The approval entries and comments are posted as well.

        Initialize();

        // Setup
        LibraryERM.CreateBankAccount(BankAccount);
        ExecuteApprovalWorkflowForJournalLine(GenJournalLine, GenJournalLine."Account Type"::"Bank Account", BankAccount."No.");

        // Exercise.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify.
        VerifyBankLedgerEntryPostedApprovals(GenJournalLine);
        VerifyApprovalEntriesAreDeleted(GenJournalLine.RecordId);
        VerifyApprovalCommentsAreDeleted(GenJournalLine.RecordId);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostGenJnlLineApprovalsForFixedAsset()
    var
        GenJournalLine: Record "Gen. Journal Line";
        FixedAsset: Record "Fixed Asset";
    begin
        // [SCENARIO] An approved gen. jnl. line that is posted together with its approvals.
        // [GIVEN] An approved general journal line.
        // [WHEN] The gen. jnl line is posted.
        // [THEN] The approval entries and comments are posted as well.

        Initialize();

        // Setup
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        ExecuteApprovalWorkflowForJournalLine(GenJournalLine, GenJournalLine."Account Type"::"Fixed Asset", FixedAsset."No.");

        // Exercise.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify.
        VerifyGLEntryPostedApprovals(GenJournalLine);
        VerifyApprovalEntriesAreDeleted(GenJournalLine.RecordId);
        VerifyApprovalCommentsAreDeleted(GenJournalLine.RecordId);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostGenJnlLineApprovalsForGLAccount()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO] An approved gen. jnl. line that is posted together with its approvals.
        // [GIVEN] An approved general journal line.
        // [WHEN] The gen. jnl line is posted.
        // [THEN] The approval entries and comments are posted as well.

        Initialize();

        // Setup
        ExecuteApprovalWorkflowForJournalLine(GenJournalLine, GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo());

        // Exercise.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify.
        VerifyGLEntryPostedApprovals(GenJournalLine);
        VerifyApprovalEntriesAreDeleted(GenJournalLine.RecordId);
        VerifyApprovalCommentsAreDeleted(GenJournalLine.RecordId);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostGenJnlBatchApprovals()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // [SCENARIO] An approved gen. jnl. batch that is posted together with its approvals.
        // [GIVEN] An approved general journal batch.
        // [WHEN] The gen. jnl batch is posted.
        // [THEN] The approval entries and comments are posted as well.

        Initialize();

        // Setup
        ExecuteApprovalWorkflowForJournalBatch(GenJournalLine);
        GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");

        // Exercise.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify.
        VerifyBatchPostedApprovals(GenJournalBatch.Name);
        VerifyApprovalEntriesAreDeleted(GenJournalBatch.RecordId);
        VerifyApprovalCommentsAreDeleted(GenJournalBatch.RecordId);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LinksShouldCopyFromApprovalEntryToPostedApprovalEntry()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        Workflow: Record Workflow;
        ApprovalUserSetup: Record "User Setup";
        ApprovalEntry: Record "Approval Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PostedApprovalEntry: Record "Posted Approval Entry";
        RecordLink: Record "Record Link";
        LinkId: Integer;
    begin
        // [SCENARIO 415640] Links should copy from approval entry to posted approval entry
        Initialize();

        // [GIVEN] General Journal Line, Approval Entry with Link
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.GeneralJournalLineApprovalWorkflowCode());
        CreateGeneralJournalBatchWithJournalLine(
            GenJournalBatch, GenJournalLine, GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo());

        Commit();
        SendApprovalRequestForLine(GenJournalLine."Journal Batch Name");
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalLine.RecordId);
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(GenJournalLine.RecordId);

        LinkId := LibraryUtility.CreateRecordLink(ApprovalEntry);

        // [WHEN] Approval Entry is approved and General Journal Line posted
        ApproveApprovalRequest(ApprovalEntry);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Posted Approval Entry has Link
        CustLedgerEntry.SetRange("Document Type", GenJournalLine."Document Type");
        CustLedgerEntry.SetRange("Document No.", GenJournalLine."Document No.");
        CustLedgerEntry.FindFirst();
        LibraryDocumentApprovals.GetPostedApprovalEntries(PostedApprovalEntry, CustLedgerEntry.RecordId);
        PostedApprovalEntry.FindFirst();
        RecordLink.SetRange("Record ID", PostedApprovalEntry.RecordId);
        Assert.RecordIsNotEmpty(RecordLink);
    end;

    local procedure ExecuteApprovalWorkflowForJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20])
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        GenJournalBatch: Record "Gen. Journal Batch";
        ApprovalUserSetup: Record "User Setup";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FAPostingGroup: Record "FA Posting Group";
    begin
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.GeneralJournalLineApprovalWorkflowCode());
        CreateGeneralJournalBatchWithJournalLine(GenJournalBatch, GenJournalLine, AccountType, AccountNo);

        if AccountType = GenJournalLine."Account Type"::Vendor then
            GenJournalLine.Validate(Amount, -GenJournalLine.Amount);

        if AccountType = GenJournalLine."Account Type"::"Fixed Asset" then begin
            LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
            DepreciationBook."G/L Integration - Maintenance" := true;
            DepreciationBook.Modify();
            LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, AccountNo, DepreciationBook.Code);
            LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
            FADepreciationBook."FA Posting Group" := FAPostingGroup.Code;
            FADepreciationBook.Modify();
            GenJournalLine.Validate("FA Posting Type", GenJournalLine."FA Posting Type"::Maintenance);
            GenJournalLine.Validate("Depreciation Book Code", DepreciationBook.Code);
        end;
        GenJournalLine.Modify();

        Commit();
        SendApprovalRequestForLine(GenJournalLine."Journal Batch Name");
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalLine.RecordId);
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(GenJournalLine.RecordId);
        AddApprovalComment(ApprovalEntry);
        ApproveApprovalRequest(ApprovalEntry);
    end;

    local procedure ExecuteApprovalWorkflowForJournalBatch(var GenJournalLine: Record "Gen. Journal Line")
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        GenJournalBatch: Record "Gen. Journal Batch";
        ApprovalUserSetup: Record "User Setup";
    begin
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.GeneralJournalBatchApprovalWorkflowCode());
        CreateGeneralJournalBatchWithJournalLine(GenJournalBatch, GenJournalLine, GenJournalLine."Account Type"::Customer,
          LibrarySales.CreateCustomerNo());
        Commit();
        SendApprovalRequestForBatch(GenJournalLine."Journal Batch Name");
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalBatch.RecordId);
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(GenJournalBatch.RecordId);
        AddApprovalComment(ApprovalEntry);
        ApproveApprovalRequest(ApprovalEntry);
    end;

    local procedure CreateJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; JournalTemplateName: Code[10]; BalAccountType: Enum "Gen. Journal Account Type"; BalAccountNo: Code[20])
    begin
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, JournalTemplateName);
        GenJournalBatch.Validate("Bal. Account Type", BalAccountType);
        GenJournalBatch.Validate("Bal. Account No.", BalAccountNo);
        GenJournalBatch.Modify(true);
    end;

    local procedure CreateGeneralJournalBatchWithJournalLine(var GenJournalBatch: Record "Gen. Journal Batch"; var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20])
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        CreateJournalBatch(GenJournalBatch,
          LibraryERM.SelectGenJnlTemplate(), GenJournalBatch."Bal. Account Type"::"Bank Account", BankAccount."No.");

        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Invoice, AccountType, AccountNo, LibraryRandom.RandDecInRange(10000, 50000, 2));
    end;

    local procedure SendApprovalRequestForLine(GenJournalBatchName: Code[20])
    var
        GeneralJournal: TestPage "General Journal";
    begin
        GeneralJournal.OpenView();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatchName);
        GeneralJournal.SendApprovalRequestJournalLine.Invoke();
    end;

    local procedure SendApprovalRequestForBatch(GenJournalBatchName: Code[20])
    var
        GeneralJournal: TestPage "General Journal";
    begin
        GeneralJournal.OpenView();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatchName);
        GeneralJournal.SendApprovalRequestJournalBatch.Invoke();
    end;

    local procedure ApproveApprovalRequest(var ApprovalEntry: Record "Approval Entry")
    var
        RequeststoApprove: TestPage "Requests to Approve";
    begin
        RequeststoApprove.OpenView();
        RequeststoApprove.GotoRecord(ApprovalEntry);
        RequeststoApprove.Approve.Invoke();
    end;

    local procedure VerifyCustLedgerEntryPostedApprovals(GenJournalLine: Record "Gen. Journal Line")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PostedApprovalEntry: Record "Posted Approval Entry";
        PostedApprovalCommentLine: Record "Posted Approval Comment Line";
    begin
        CustLedgerEntry.SetRange("Document Type", GenJournalLine."Document Type");
        CustLedgerEntry.SetRange("Document No.", GenJournalLine."Document No.");
        CustLedgerEntry.FindFirst();

        LibraryDocumentApprovals.GetPostedApprovalEntries(PostedApprovalEntry, CustLedgerEntry.RecordId);
        Assert.AreEqual(1, PostedApprovalEntry.Count, 'Unexpected posted approval entries.');

        LibraryDocumentApprovals.GetPostedApprovalComments(PostedApprovalCommentLine, CustLedgerEntry.RecordId);
        Assert.AreEqual(1, PostedApprovalCommentLine.Count, 'Unexpected posted approval comments.');
    end;

    local procedure VerifyVendorLedgerEntryPostedApprovals(GenJournalLine: Record "Gen. Journal Line")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PostedApprovalEntry: Record "Posted Approval Entry";
        PostedApprovalCommentLine: Record "Posted Approval Comment Line";
    begin
        VendorLedgerEntry.SetRange("Document Type", GenJournalLine."Document Type");
        VendorLedgerEntry.SetRange("Document No.", GenJournalLine."Document No.");
        VendorLedgerEntry.FindFirst();

        LibraryDocumentApprovals.GetPostedApprovalEntries(PostedApprovalEntry, VendorLedgerEntry.RecordId);
        Assert.AreEqual(1, PostedApprovalEntry.Count, 'Unexpected posted approval entries.');

        LibraryDocumentApprovals.GetPostedApprovalComments(PostedApprovalCommentLine, VendorLedgerEntry.RecordId);
        Assert.AreEqual(1, PostedApprovalCommentLine.Count, 'Unexpected posted approval comments.');
    end;

    local procedure VerifyBankLedgerEntryPostedApprovals(GenJournalLine: Record "Gen. Journal Line")
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        PostedApprovalEntry: Record "Posted Approval Entry";
        PostedApprovalCommentLine: Record "Posted Approval Comment Line";
    begin
        BankAccountLedgerEntry.SetRange("Document Type", GenJournalLine."Document Type");
        BankAccountLedgerEntry.SetRange("Document No.", GenJournalLine."Document No.");
        BankAccountLedgerEntry.FindFirst();

        LibraryDocumentApprovals.GetPostedApprovalEntries(PostedApprovalEntry, BankAccountLedgerEntry.RecordId);
        Assert.AreEqual(1, PostedApprovalEntry.Count, 'Unexpected posted approval entries.');

        LibraryDocumentApprovals.GetPostedApprovalComments(PostedApprovalCommentLine, BankAccountLedgerEntry.RecordId);
        Assert.AreEqual(1, PostedApprovalCommentLine.Count, 'Unexpected posted approval comments.');
    end;

    local procedure VerifyGLEntryPostedApprovals(GenJournalLine: Record "Gen. Journal Line")
    var
        GLEntry: Record "G/L Entry";
        PostedApprovalEntry: Record "Posted Approval Entry";
        PostedApprovalCommentLine: Record "Posted Approval Comment Line";
    begin
        GLEntry.SetRange("Document Type", GenJournalLine."Document Type");
        GLEntry.SetRange("Document No.", GenJournalLine."Document No.");
        GLEntry.FindFirst();

        LibraryDocumentApprovals.GetPostedApprovalEntries(PostedApprovalEntry, GLEntry.RecordId);
        Assert.AreEqual(1, PostedApprovalEntry.Count, 'Unexpected posted approval entries.');

        LibraryDocumentApprovals.GetPostedApprovalComments(PostedApprovalCommentLine, GLEntry.RecordId);
        Assert.AreEqual(1, PostedApprovalCommentLine.Count, 'Unexpected posted approval comments.');
    end;

    local procedure VerifyBatchPostedApprovals(GenJournalBatchName: Code[10])
    var
        GLRegister: Record "G/L Register";
        PostedApprovalEntry: Record "Posted Approval Entry";
        PostedApprovalCommentLine: Record "Posted Approval Comment Line";
    begin
        GLRegister.SetRange("Journal Batch Name", GenJournalBatchName);
        GLRegister.FindLast();

        LibraryDocumentApprovals.GetPostedApprovalEntries(PostedApprovalEntry, GLRegister.RecordId);
        Assert.AreEqual(1, PostedApprovalEntry.Count, 'Unexpected posted approval entries.');

        LibraryDocumentApprovals.GetPostedApprovalComments(PostedApprovalCommentLine, GLRegister.RecordId);
        Assert.AreEqual(1, PostedApprovalCommentLine.Count, 'Unexpected posted approval comments.');
    end;

    local procedure VerifyApprovalEntriesAreDeleted(RecordIDToApprove: RecordID)
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        ApprovalEntry.SetRange("Record ID to Approve", RecordIDToApprove);
        Assert.IsTrue(ApprovalEntry.IsEmpty, 'There should be no approval entries after posting.');
    end;

    local procedure VerifyApprovalCommentsAreDeleted(RecordIDToApprove: RecordID)
    var
        ApprovalCommentLine: Record "Approval Comment Line";
    begin
        ApprovalCommentLine.SetRange("Record ID to Approve", RecordIDToApprove);
        Assert.IsTrue(ApprovalCommentLine.IsEmpty, 'There should be no approval comments after posting.');
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
        ApprovalCommentLine.SetRange("Table ID", ApprovalEntry."Table ID");
        ApprovalCommentLine.SetRange("Record ID to Approve", ApprovalEntry."Record ID to Approve");
        ApprovalCommentLine.SetRange("Workflow Step Instance ID", ApprovalEntry."Workflow Step Instance ID");
        ApprovalCommentLine.Insert(true);
    end;
}

