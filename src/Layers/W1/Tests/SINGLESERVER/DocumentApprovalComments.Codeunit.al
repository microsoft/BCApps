codeunit 134201 "Document Approval - Comments"
{
    EventSubscriberInstance = Manual;
    Permissions = TableData "Approval Entry" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Approval] [Comments]
    end;

    var
        Assert: Codeunit Assert;
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        WrongNumberOfApprovalEntriesMsg: Label 'Wrong number of Approval Entries.';
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibraryIncomingDocuments: Codeunit "Library - Incoming Documents";
        LibraryERM: Codeunit "Library - ERM";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        IsInitialized: Boolean;
        FactBoxRecordExistErr: Label 'Approval Comment Factbox should be empty';
        FactBoxRecordDoesntExistErr: Label 'Approval Comment Factbox should not be empty';
        ApprovalCommentsFilterErr: Label 'Approval Comments filter expected.';
        ApprovalCommentsNoFilterErr: Label 'Approval Comments filter is not expected.';

    [Test]
    [Scope('OnPrem')]
    procedure CheckCommentsActionDoesNotWorkForEmptyPage()
    var
        RequeststoApprove: TestPage "Requests to Approve";
        ApprovalEntries: TestPage "Approval Entries";
        ApprovalComments: TestPage "Approval Comments";
        ApprovalRequestEntries: TestPage "Approval Request Entries";
    begin
        ApprovalComments.Trap();

        RequeststoApprove.OpenView();
        RequeststoApprove.Comments.Invoke();
        RequeststoApprove.Close();

        asserterror ApprovalComments.Close(); // The Comments page was not opened
        Assert.ExpectedError('The TestPage is not open.');

        ApprovalComments.Trap();

        ApprovalEntries.OpenView();
        ApprovalEntries.Comments.Invoke();
        ApprovalEntries.Close();

        asserterror ApprovalComments.Close(); // The Comments page was not opened
        Assert.ExpectedError('The TestPage is not open.');

        ApprovalComments.Trap();

        ApprovalRequestEntries.OpenView();
        ApprovalRequestEntries.Comments.Invoke();
        ApprovalRequestEntries.Close();

        asserterror ApprovalComments.Close(); // The Comments page was not opened
        Assert.ExpectedError('The TestPage is not open.');
    end;

    [Test]
    [HandlerFunctions('ApprovalCommentsHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure InsertApprovalComments()
    var
        ApprovalEntry: Record "Approval Entry";
        ApprovalEntriesPage: TestPage "Approval Entries";
        EmptyGUID: Guid;
    begin
        Initialize();

        // Setup
        DeleteApprovalEntryAndComments();
        CreateApprovalEntryWithPurchInvoice(ApprovalEntry, EmptyGUID);

        // Execute
        ApprovalEntriesPage.OpenView();
        ApprovalEntriesPage.GotoRecord(ApprovalEntry);
        ApprovalEntriesPage.Comments.Invoke();

        // Validate
        VerifyApprovalCommentLineExist(ApprovalEntry);
    end;

    [Test]
    [HandlerFunctions('ApprovalCommentsHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure InsertTwoApprovalCommentsForTwoEntries()
    var
        ApprovalEntry: Record "Approval Entry";
        ApprovalEntry2: Record "Approval Entry";
        ApprovalEntriesPage: TestPage "Approval Entries";
        EmptyGUID: Guid;
    begin
        Initialize();

        // Setup
        DeleteApprovalEntryAndComments();
        CreateApprovalEntryWithPurchInvoice(ApprovalEntry, EmptyGUID);
        CreateApprovalEntryWithPurchInvoice(ApprovalEntry2, EmptyGUID);

        // Execute
        ApprovalEntriesPage.OpenView();
        ApprovalEntriesPage.GotoRecord(ApprovalEntry);
        ApprovalEntriesPage.Comments.Invoke();
        ApprovalEntriesPage.GotoRecord(ApprovalEntry2);
        ApprovalEntriesPage.Comments.Invoke();

        // Validate
        VerifyApprovalCommentLineExist(ApprovalEntry);
        VerifyApprovalCommentLineExist(ApprovalEntry2);
    end;

    [Test]
    [HandlerFunctions('ApprovalCommentsHandler')]
    [Scope('OnPrem')]
    procedure InsertRejectionComments()
    var
        ApprovalEntry: Record "Approval Entry";
        ApprovalEntriesPage: TestPage "Requests to Approve";
        WorkflowInstanceID: Guid;
    begin
        Initialize();

        // Setup
        DeleteApprovalEntryAndComments();
        WorkflowInstanceID := EnableRejectionComments();
        CreateApprovalEntryWithPurchInvoice(ApprovalEntry, WorkflowInstanceID);

        // Execute
        Commit();
        ApprovalEntriesPage.OpenView();
        ApprovalEntriesPage.GotoRecord(ApprovalEntry);
        ApprovalEntriesPage.Reject.Invoke();

        // Validate
        VerifyApprovalCommentLineExist(ApprovalEntry);
        ApprovalEntry.FindFirst();
        ApprovalEntry.TestField(Status, ApprovalEntry.Status::Rejected);

        // Tear Down
        DeleteApprovalEntryAndComments();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYesNoForUsers,MessageHandler,ApprovalCommentsHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure InsertApprovalCommentsForPurchBlanketOrder()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        InsertApprovalCommentsForPurchDocument(PurchaseHeader."Document Type"::"Blanket Order");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYesNoForUsers,MessageHandler,ApprovalCommentsHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure InsertApprovalCommentsForPurchCreditMemo()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        InsertApprovalCommentsForPurchDocument(PurchaseHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYesNoForUsers,MessageHandler,ApprovalCommentsHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure InsertApprovalCommentsForPurchInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        InsertApprovalCommentsForPurchDocument(PurchaseHeader."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYesNoForUsers,MessageHandler,ApprovalCommentsHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure InsertApprovalCommentsForPurchOrder()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        InsertApprovalCommentsForPurchDocument(PurchaseHeader."Document Type"::Order);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYesNoForUsers,MessageHandler,ApprovalCommentsHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure InsertApprovalCommentsForPurchReturnOrder()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        InsertApprovalCommentsForPurchDocument(PurchaseHeader."Document Type"::"Return Order");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYesNoForUsers,MessageHandler,ApprovalCommentsHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure InsertApprovalCommentsForPurchQuote()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        InsertApprovalCommentsForPurchDocument(PurchaseHeader."Document Type"::Quote);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYesNoForUsers,MessageHandler,ApprovalCommentsHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure InsertApprovalCommentsForSalesBlanketOrder()
    var
        SalesHeader: Record "Sales Header";
    begin
        InsertApprovalCommentsForSalesDocument(SalesHeader."Document Type"::"Blanket Order");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYesNoForUsers,MessageHandler,ApprovalCommentsHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure InsertApprovalCommentsForSalesCreditMemo()
    var
        SalesHeader: Record "Sales Header";
    begin
        InsertApprovalCommentsForSalesDocument(SalesHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYesNoForUsers,MessageHandler,ApprovalCommentsHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure InsertApprovalCommentsForSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
    begin
        InsertApprovalCommentsForSalesDocument(SalesHeader."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYesNoForUsers,MessageHandler,ApprovalCommentsHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure InsertApprovalCommentsForSalesOrder()
    var
        SalesHeader: Record "Sales Header";
    begin
        InsertApprovalCommentsForSalesDocument(SalesHeader."Document Type"::Order);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYesNoForUsers,MessageHandler,ApprovalCommentsHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure InsertApprovalCommentsForSalesReturnOrder()
    var
        SalesHeader: Record "Sales Header";
    begin
        InsertApprovalCommentsForSalesDocument(SalesHeader."Document Type"::"Return Order");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYesNoForUsers,MessageHandler,ApprovalCommentsHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure InsertApprovalCommentsForSalesQuote()
    var
        SalesHeader: Record "Sales Header";
    begin
        InsertApprovalCommentsForSalesDocument(SalesHeader."Document Type"::Quote);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYesNoForUsers,MessageHandler,ApprovalCommentsHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RejectRequestForSalesBlanketOrderWithComments()
    var
        SalesHeader: Record "Sales Header";
    begin
        RejectRequestForSalesDocumentWithComments(SalesHeader."Document Type"::"Blanket Order");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYesNoForUsers,MessageHandler,ApprovalCommentsHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RejectRequestForSalesCreditMemoWithComments()
    var
        SalesHeader: Record "Sales Header";
    begin
        RejectRequestForSalesDocumentWithComments(SalesHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYesNoForUsers,MessageHandler,ApprovalCommentsHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RejectRequestForSalesInvoiceWithComments()
    var
        SalesHeader: Record "Sales Header";
    begin
        RejectRequestForSalesDocumentWithComments(SalesHeader."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYesNoForUsers,MessageHandler,ApprovalCommentsHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RejectRequestForSalesOrderWithComments()
    var
        SalesHeader: Record "Sales Header";
    begin
        RejectRequestForSalesDocumentWithComments(SalesHeader."Document Type"::Order);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYesNoForUsers,MessageHandler,ApprovalCommentsHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RejectRequestForSalesReturnOrderWithComments()
    var
        SalesHeader: Record "Sales Header";
    begin
        RejectRequestForSalesDocumentWithComments(SalesHeader."Document Type"::"Return Order");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYesNoForUsers,MessageHandler,ApprovalCommentsHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RejectRequestForSalesQuoteWithComments()
    var
        SalesHeader: Record "Sales Header";
    begin
        RejectRequestForSalesDocumentWithComments(SalesHeader."Document Type"::Quote);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYesNoForUsers,MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CheckApprovalEntryWithStatusApprovedForSales()
    var
        Workflow: Record Workflow;
        WorkflowStepArgument: Record "Workflow Step Argument";
        SalesHeader: Record "Sales Header";
        UserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        BlankDateFormula: DateFormula;
    begin
        // Verify Approval Entry with Approver ID when approval type is approver for Sales.

        // Setup: Setup Document Approval for Approval Type as Approver.
        Initialize();
        SetupUsers(UserSetup);
        SetApprovalAdmin(UserSetup."Approver ID");
        WorkflowSetup.InsertSalesDocumentApprovalWorkflowSteps(
            Workflow, SalesHeader."Document Type"::Order,
            WorkflowStepArgument."Approver Type"::Approver, WorkflowStepArgument."Approver Limit Type"::"Approver Chain",
            '', BlankDateFormula);
        Workflow.Validate(Template, false);
        Workflow.Validate(Enabled, true);
        Workflow.Modify(true);

        CreateSalesDocumentWithSalespersonCode(SalesHeader,
          SalesHeader."Document Type"::Order, UserSetup."Salespers./Purch. Code");

        // Exercise: Send Sales Appoval Request.
        ApprovalsMgmt.OnSendSalesDocForApproval(SalesHeader);

        // Verify: Verifing Approval Entry status Approved.
        VerifyApprovalEntry(DATABASE::"Sales Header", SalesHeader."Document Type"::Order,
          SalesHeader."No.", UserSetup."User ID");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYesNoForUsers,MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CheckApprovalEntryWithStatusApprovedForPurchase()
    var
        Workflow: Record Workflow;
        WorkflowStepArgument: Record "Workflow Step Argument";
        PurchaseHeader: Record "Purchase Header";
        UserSetup: Record "User Setup";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        WorkflowSetup: Codeunit "Workflow Setup";
        BlankDateFormula: DateFormula;
    begin
        // Verify Approval Entry with Approver ID when approval type is approver for Purchase.

        // Setup: Setup Document Approval for Approval Type as Approver.
        Initialize();
        SetupUsers(UserSetup);
        SetApprovalAdmin(UserSetup."Approver ID");
        WorkflowSetup.InsertPurchaseDocumentApprovalWorkflowSteps(
            Workflow, PurchaseHeader."Document Type"::Order,
            WorkflowStepArgument."Approver Type"::Approver, WorkflowStepArgument."Approver Limit Type"::"Approver Chain",
            '', BlankDateFormula);
        Workflow.Validate(Template, false);
        Workflow.Validate(Enabled, true);
        Workflow.Modify(true);

        CreatePurchDocumentWithPurchaserCode(PurchaseHeader, PurchaseHeader."Document Type"::Order,
          UserSetup."Salespers./Purch. Code");

        // Exercise: Send Purchase Appoval Request.
        ApprovalsMgmt.OnSendPurchaseDocForApproval(PurchaseHeader);

        // Verify: Verifing Approval Entry status Approved.
        VerifyApprovalEntry(DATABASE::"Purchase Header", PurchaseHeader."Document Type"::Order,
          PurchaseHeader."No.", UserSetup."User ID");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeletePostedApprovalCommentEntry()
    var
        DummyPostedApprovalCommentLine: Record "Posted Approval Comment Line";
        SalesHeader: Record "Sales Header";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        PostedRecordID: RecordID;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 380752] Deletion of posted approval entry deletes linked posted approval comment entries
        Initialize();

        // [GIVEN] Posted approval entry with comment entries
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        PostedRecordID := SalesHeader.RecordId;
        MockPostedApprovalCommentLine(PostedRecordID);
        MockPostedApprovalCommentLine(PostedRecordID);

        // [WHEN] Delete posted approval entry
        ApprovalsMgmt.DeletePostedApprovalEntries(SalesHeader.RecordId);

        // [THEN] Posted approval comment entries are deleted
        DummyPostedApprovalCommentLine.SetRange("Table ID", PostedRecordID.TableNo);
        DummyPostedApprovalCommentLine.SetRange("Posted Record ID", PostedRecordID);
        Assert.RecordIsEmpty(DummyPostedApprovalCommentLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApproverReadsSenderCommentFromPurchaseOrderCard()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
        ApprovalComments: TestPage "Approval Comments";
        Comment: Text;
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 380753] Approver can read Sender's approval comment from Purchase Order card
        Initialize();
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Order;
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type", LibraryPurchase.CreateVendorNo());

        // [GIVEN] Sender creates an approval request with a comment for Purchase Order
        Comment := MockApprovalEntryWithComment(PurchaseHeader.RecordId);
        // [GIVEN] Approver opens approving record's card (Purchase Order) from Request To Approve page
        PurchaseOrder.OpenView();
        PurchaseOrder.GotoRecord(PurchaseHeader);

        // [WHEN] Approver invokes "Comments" from "Approve" action group on Purchase Order
        ApprovalComments.Trap();
        PurchaseOrder.Comment.Invoke();

        // [THEN] Approver reads Sender's comment
        ApprovalComments.Comment.AssertEquals(Comment);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApproverReadsSenderCommentFromSalesOrderCard()
    var
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
        ApprovalComments: TestPage "Approval Comments";
        Comment: Text;
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 380753] Approver can read Sender's approval comment from Sales Order card
        Initialize();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Order;
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type", LibrarySales.CreateCustomerNo());

        // [GIVEN] Sender creates an approval request with a comment for Sales Order
        Comment := MockApprovalEntryWithComment(SalesHeader.RecordId);
        // [GIVEN] Approver opens approving record's card (Sales Order) from Request To Approve page
        SalesOrder.OpenView();
        SalesOrder.GotoRecord(SalesHeader);

        // [WHEN] Approver invokes "Comments" from "Approve" action group on Sales Order
        ApprovalComments.Trap();
        SalesOrder.Comment.Invoke();

        // [THEN] Approver reads Sender's comment
        ApprovalComments.Comment.AssertEquals(Comment);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApprovalCommentFromIncomingDoc()
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentPage: TestPage "Incoming Document";
        ApprovalComments: TestPage "Approval Comments";
        Comment: Text;
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 381208] Approval Comments from Incoming Documents page are filtered on Record ID
        Initialize();
        LibraryIncomingDocuments.InitIncomingDocuments();
        LibraryIncomingDocuments.CreateNewIncomingDocument(IncomingDocument);

        // [GIVEN] Sender creates an approval request with a comment for Incoming Document
        Comment := MockApprovalEntryWithComment(IncomingDocument.RecordId);

        // [GIVEN] Approver opens approving record's card (Incoming Document) from Request To Approve page
        IncomingDocumentPage.OpenView();
        IncomingDocumentPage.GotoRecord(IncomingDocument);

        // [WHEN] Approver invokes "Comments" from "Approve" action group on Incoming Documents page
        ApprovalComments.Trap();
        IncomingDocumentPage.Comment.Invoke();

        // [THEN] Approver reads comments filtered on current record
        ApprovalComments.Comment.AssertEquals(Comment);
    end;

    [Test]
    [HandlerFunctions('TemplateSelectHandler')]
    [Scope('OnPrem')]
    procedure ApprovalCommentFromGenJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
        ApprovalComments: TestPage "Approval Comments";
        Comment: Text;
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 381208] Approval Comments from Gen. Journal page are filtered on Record ID
        Initialize();
        CreateGenJournalLine(GenJournalLine, PAGE::"General Journal", "Gen. Journal Template Type"::General);
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");

        // [GIVEN] Sender creates an approval request with a comment for General Journal Line
        Comment := MockApprovalEntryWithComment(GenJournalLine.RecordId);

        // [GIVEN] Approver opens approving record's card (General Journal) from Request To Approve page
        GeneralJournal.OpenView();
        GeneralJournal.GotoRecord(GenJournalLine);

        // [WHEN] Approver invokes "Comments" from "Approve" action group on Gen. Journal page
        ApprovalComments.Trap();
        GeneralJournal.Comments.Invoke();

        // [THEN] Approver reads comments filtered on current record
        ApprovalComments.First();
        ApprovalComments.Comment.AssertEquals(Comment);
    end;

    [Test]
    [HandlerFunctions('TemplateSelectHandler')]
    [Scope('OnPrem')]
    procedure ApprovalCommentFromCashReceipt()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CashReceiptJournal: TestPage "Cash Receipt Journal";
        ApprovalComments: TestPage "Approval Comments";
        Comment: Text;
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 381208] Approval Comments from Cash Receipt Journal page are filtered on Record ID
        Initialize();
        CreateGenJournalLine(
          GenJournalLine, PAGE::"Cash Receipt Journal", "Gen. Journal Template Type"::"Cash Receipts");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");

        // [GIVEN] Sender creates an approval request with a comment for General Journal Line
        Comment := MockApprovalEntryWithComment(GenJournalLine.RecordId);

        // [GIVEN] Approver opens approving record's card (Cash Receipt) from Request To Approve page
        CashReceiptJournal.OpenEdit();
        CashReceiptJournal.GotoRecord(GenJournalLine);

        // [WHEN] Approver invokes "Comments" from "Approve" action group on Cash Receipt page
        ApprovalComments.Trap();
        CashReceiptJournal.Comment.Invoke();

        // [THEN] Approver reads comments filtered on current record
        ApprovalComments.Comment.AssertEquals(Comment);
    end;

    [Test]
    [HandlerFunctions('TemplateSelectHandler')]
    [Scope('OnPrem')]
    procedure ApprovalCommentFromPaymentJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentJournal: TestPage "Payment Journal";
        ApprovalComments: TestPage "Approval Comments";
        Comment: Text;
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 381208] Approval Comments from Payment page are filtered on Record ID
        Initialize();
        CreateGenJournalLine(
          GenJournalLine, PAGE::"Payment Journal", "Gen. Journal Template Type"::Payments);
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");

        // [GIVEN] Sender creates an approval request with a comment for General Journal Line
        Comment := MockApprovalEntryWithComment(GenJournalLine.RecordId);

        // [GIVEN] Approver opens approving record's card (Payment Journal) from Request To Approve page
        PaymentJournal.OpenView();
        PaymentJournal.GotoRecord(GenJournalLine);

        // [WHEN] Approver invokes "Comments" from "Approve" action group on Payment Journal
        ApprovalComments.Trap();
        PaymentJournal.Comment.Invoke();

        // [THEN] Approver reads comments filtered on current record
        ApprovalComments.Comment.AssertEquals(Comment);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApprovalCommentFromSalesReturnOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesReturnOrder: TestPage "Sales Return Order";
        ApprovalComments: TestPage "Approval Comments";
        Comment: Text;
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 381208] Approval Comments from Sales Return Order card are filtered on Record ID
        Initialize();
        SalesHeader."Document Type" := SalesHeader."Document Type"::"Return Order";
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type", LibrarySales.CreateCustomerNo());

        // [GIVEN] Sender creates an approval request with a comment for Incoming Document
        Comment := MockApprovalEntryWithComment(SalesHeader.RecordId);

        // [GIVEN] Approver opens approving record's card (Sales Return order) from Request To Approve page
        SalesReturnOrder.OpenView();
        SalesReturnOrder.GotoRecord(SalesHeader);

        // [WHEN] Approver invokes "Comments" from "Approve" action group on Sales Order
        ApprovalComments.Trap();
        SalesReturnOrder.Comment.Invoke();

        // [THEN] Approver reads comments filtered on current record
        ApprovalComments.Comment.AssertEquals(Comment);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApprovalCommentFromPurchaseReturnOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
        ApprovalComments: TestPage "Approval Comments";
        Comment: Text;
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 381208] Approval Comments from Purchase Return Order card are filtered on Record ID
        Initialize();
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::"Return Order";
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type", LibraryPurchase.CreateVendorNo());

        // [GIVEN] Sender creates an approval request with a comment for Purchase Return Order card
        Comment := MockApprovalEntryWithComment(PurchaseHeader.RecordId);

        // [GIVEN] Approver opens approving record's card (Purchase Return Order) from Request To Approve page
        PurchaseReturnOrder.OpenView();
        PurchaseReturnOrder.GotoRecord(PurchaseHeader);

        // [WHEN] Approver invokes "Comments" from "Approve" action group on Purchase Return Order
        ApprovalComments.Trap();
        PurchaseReturnOrder.Comment.Invoke();

        // [THEN] Approver reads comments filtered on current record
        ApprovalComments.Comment.AssertEquals(Comment);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteApprovalCommentWhenGenJournalLineDeleted()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ApprovalCommentLine: Record "Approval Comment Line";
        RecordIDToApprove: RecordID;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 381885] Approval Comments should be deleted when delete Gen. Journal Line.
        Initialize();
        CreateGenJournalLine(GenJournalLine, PAGE::"General Journal", "Gen. Journal Template Type"::General);

        // [GIVEN] Sender creates an approval request with a comment for General Journal Line
        RecordIDToApprove := GenJournalLine.RecordId;
        MockApprovalEntryWithComment(RecordIDToApprove);

        // [WHEN] Delete Gen. Journal Line
        GenJournalLine.Delete();

        // [THEN] Approval Comments should be deleted
        ApprovalCommentLine.SetRange("Record ID to Approve", RecordIDToApprove);
        Assert.RecordIsEmpty(ApprovalCommentLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteApprovalCommentWhenCustomerDeleted()
    var
        Customer: Record Customer;
        ApprovalCommentLine: Record "Approval Comment Line";
        RecordIDToApprove: RecordID;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 381885] Approval Comments should be deleted when delete Customer.
        Initialize();
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Sender creates an approval request with a comment for Customer
        RecordIDToApprove := Customer.RecordId;
        MockApprovalEntryWithComment(RecordIDToApprove);

        // [WHEN] Delete Customer
        Customer.Delete();

        // [THEN] Approval Comments should be deleted
        ApprovalCommentLine.SetRange("Record ID to Approve", RecordIDToApprove);
        Assert.RecordIsEmpty(ApprovalCommentLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteApprovalCommentWhenVendorDeleted()
    var
        Vendor: Record Vendor;
        ApprovalCommentLine: Record "Approval Comment Line";
        RecordIDToApprove: RecordID;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 381885] Approval Comments should be deleted when delete Vendor.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Sender creates an approval request with a comment for Vendor
        RecordIDToApprove := Vendor.RecordId;
        MockApprovalEntryWithComment(RecordIDToApprove);

        // [WHEN] Delete Vendor
        Vendor.Delete();

        // [THEN] Approval Comments should be deleted
        ApprovalCommentLine.SetRange("Record ID to Approve", RecordIDToApprove);
        Assert.RecordIsEmpty(ApprovalCommentLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteApprovalCommentWhenItemDeleted()
    var
        Item: Record Item;
        ApprovalCommentLine: Record "Approval Comment Line";
        RecordIDToApprove: RecordID;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 381885] Approval Comments should be deleted when delete Item.
        Initialize();
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Sender creates an approval request with a comment for Item
        RecordIDToApprove := Item.RecordId;
        MockApprovalEntryWithComment(RecordIDToApprove);

        // [WHEN] Delete Item
        Item.Delete();

        // [THEN] Approval Comments should be deleted
        ApprovalCommentLine.SetRange("Record ID to Approve", RecordIDToApprove);
        Assert.RecordIsEmpty(ApprovalCommentLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteApprovalCommentWhenGenJournalBatchDeleted()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        ApprovalCommentLine: Record "Approval Comment Line";
        RecordIDToApprove: RecordID;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 381885] Approval Comments should be deleted when delete Gen. Journal Batch.
        Initialize();
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        // [GIVEN] Sender creates an approval request with a comment for General Journal Batch
        RecordIDToApprove := GenJournalBatch.RecordId;
        MockApprovalEntryWithComment(RecordIDToApprove);

        // [WHEN] Delete Gen. Journal Batch
        GenJournalBatch.Delete();

        // [THEN] Approval Comments should be deleted
        ApprovalCommentLine.SetRange("Record ID to Approve", RecordIDToApprove);
        Assert.RecordIsEmpty(ApprovalCommentLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApprovalCommentFactBoxWhenCommentExist()
    var
        SalesHeader: Record "Sales Header";
        ApprovalEntry: Record "Approval Entry";
        ApprovalCommentsFactBox: Page "Approval Comments FactBox";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 382035] Approval Comment Factbox is not empty when Approval Comment with RecordID exist
        Initialize();
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');

        // [GIVEN] Approval Entry with comment for Sales Order
        MockApprovalEntryWithComment(SalesHeader.RecordId);

        // [WHEN] Select Approval Entry on "Requests to Approve" Page
        ApprovalEntry.SetRange("Record ID to Approve", SalesHeader.RecordId);
        ApprovalEntry.FindFirst();

        // [THEN] Approval Comment Factbox is not empty
        Assert.IsTrue(ApprovalCommentsFactBox.SetFilterFromApprovalEntry(ApprovalEntry), FactBoxRecordDoesntExistErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApprovalCommentFactBoxWhenCommentNotExist()
    var
        SalesHeader1: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        ApprovalEntry: Record "Approval Entry";
        ApprovalCommentsFactBox: Page "Approval Comments FactBox";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 382035] Approval Comment Factbox is empty when Approval Comment with RecordID doesn't exist
        Initialize();

        // [GIVEN] Approval Entry with comment for Sales Order "SO1"
        LibrarySales.CreateSalesHeader(SalesHeader1, SalesHeader1."Document Type"::Order, '');
        MockApprovalEntryWithComment(SalesHeader1.RecordId);

        // [GIVEN] Approval Entry without comment for Sales Order "SO2"
        LibrarySales.CreateSalesHeader(SalesHeader2, SalesHeader2."Document Type"::Order, '');
        MockApprovalEntry(SalesHeader2.RecordId);

        // [WHEN] Select Approval Entry for "SO2" on "Requests to Approve" Page
        ApprovalEntry.SetRange("Record ID to Approve", SalesHeader2.RecordId);
        ApprovalEntry.FindFirst();

        // [THEN] Approval Comment Factbox is empty
        Assert.IsFalse(ApprovalCommentsFactBox.SetFilterFromApprovalEntry(ApprovalEntry), FactBoxRecordExistErr);
    end;

    [Test]
    [HandlerFunctions('ApprovalCommentsHandler')]
    [Scope('OnPrem')]
    procedure ApprovalCommentCreatedForSelectedStepInstanceOnly()
    var
        ApprovalEntry: array[2] of Record "Approval Entry";
        PurchaseHeader: Record "Purchase Header";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 218295] Approval Comment is added for selected Approval Entry with specific WorkflowStepInstanceID, not for the first one.
        Initialize();
        DeleteApprovalEntryAndComments();

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '');
        CreateApprovalEntry(ApprovalEntry[1], CreateGuid(), PurchaseHeader.RecordId, ApprovalEntry[1].Status::Rejected);
        CreateApprovalEntry(ApprovalEntry[2], CreateGuid(), PurchaseHeader.RecordId, ApprovalEntry[2].Status::Open);

        ApprovalsMgmt.GetApprovalCommentForWorkflowStepInstanceID(ApprovalEntry[2], ApprovalEntry[2]."Workflow Step Instance ID");

        VerifyApprovalCommentLineNotExistForStepID(ApprovalEntry[1]);
        VerifyApprovalCommentLineExistForStepID(ApprovalEntry[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApprovalCommentForPurchDocumentForOpenApprovalEntry()
    var
        PurchaseHeader: Record "Purchase Header";
        ApprovalEntry: array[2] of Record "Approval Entry";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        ApprovalComments: TestPage "Approval Comments";
        Comment: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 218295] Approval Comment for the Purchase Document is opened for Open Approval Entry, not for the first one.
        Initialize();
        DeleteApprovalEntryAndComments();

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '');

        CreateApprovalEntry(ApprovalEntry[1], CreateGuid(), PurchaseHeader.RecordId, ApprovalEntry[1].Status::Rejected);
        CreateApprovalEntry(ApprovalEntry[2], CreateGuid(), PurchaseHeader.RecordId, ApprovalEntry[2].Status::Open);

        MockApprovalComment(PurchaseHeader.RecordId, ApprovalEntry[1]."Workflow Step Instance ID");
        Comment := MockApprovalComment(PurchaseHeader.RecordId, ApprovalEntry[2]."Workflow Step Instance ID");

        ApprovalComments.Trap();
        ApprovalsMgmt.GetApprovalComment(PurchaseHeader);
        ApprovalComments.Last();
        ApprovalComments.Comment.AssertEquals(Comment);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllApprovalCommentsVisibleWhenOpenedFromDocument()
    var
        PurchaseHeader: Record "Purchase Header";
        ApprovalEntry: array[2] of Record "Approval Entry";
        PurchaseInvoice: TestPage "Purchase Invoice";
        ApprovalComments: TestPage "Approval Comments";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 218295] Approval Comments opened from Document shows all Approval Comments for the selected Document No.
        Initialize();
        DeleteApprovalEntryAndComments();

        // [GIVEN] Purchase Invoice "PI" with two Approval Entries "AE1" and "AE2" for "PI".
        // [GIVEN] "AE1" = Rejected, "AE2" = Open.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '');
        CreateApprovalEntry(ApprovalEntry[1], CreateGuid(), PurchaseHeader.RecordId, ApprovalEntry[1].Status::Rejected);
        CreateApprovalEntry(ApprovalEntry[2], CreateGuid(), PurchaseHeader.RecordId, ApprovalEntry[2].Status::Open);

        // [GIVEN] Two Approval Comment Lines for "AE1" and "AE2".
        MockApprovalComment(PurchaseHeader.RecordId, ApprovalEntry[1]."Workflow Step Instance ID");
        MockApprovalComment(PurchaseHeader.RecordId, ApprovalEntry[2]."Workflow Step Instance ID");

        // [WHEN] "PI" is opened and Approval Comments page is invoked.
        ApprovalComments.Trap();
        PurchaseInvoice.OpenView();
        PurchaseInvoice.GotoRecord(PurchaseHeader);
        PurchaseInvoice.Comment.Invoke();

        // [THEN] All Approval Commment Lines are visible for the "PI".
        // [THEN] Approval Comment Lines are not filtered by the Workflow Step Instance ID.
        Assert.AreEqual(
          Format(DATABASE::"Purchase Header"), ApprovalComments.FILTER.GetFilter("Table ID"), ApprovalCommentsFilterErr);
        Assert.AreEqual(
          Format(PurchaseHeader.RecordId), ApprovalComments.FILTER.GetFilter("Record ID to Approve"), ApprovalCommentsFilterErr);
        Assert.AreEqual(
          '', ApprovalComments.FILTER.GetFilter("Workflow Step Instance ID"), ApprovalCommentsNoFilterErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllApprovalCommentsVisibleWhenOpenedFromApprovalEntry()
    var
        PurchaseHeader: Record "Purchase Header";
        ApprovalEntry: array[2] of Record "Approval Entry";
        ApprovalEntries: TestPage "Approval Entries";
        ApprovalComments: TestPage "Approval Comments";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 218295] Approval Comments opened from Approval Entries Page shows all Approval Comments for the selected Document No.
        Initialize();
        DeleteApprovalEntryAndComments();

        // [GIVEN] Purchase Invoice "PI" with two Approval Entries "AE1" and "AE2" for "PI".
        // [GIVEN] "AE1" = Rejected, "AE2" = Open.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '');
        CreateApprovalEntry(ApprovalEntry[1], CreateGuid(), PurchaseHeader.RecordId, ApprovalEntry[1].Status::Rejected);
        CreateApprovalEntry(ApprovalEntry[2], CreateGuid(), PurchaseHeader.RecordId, ApprovalEntry[2].Status::Open);

        // [GIVEN] Two Approval Comment Lines for "AE1" and "AE2".
        MockApprovalComment(PurchaseHeader.RecordId, ApprovalEntry[1]."Workflow Step Instance ID");
        MockApprovalComment(PurchaseHeader.RecordId, ApprovalEntry[2]."Workflow Step Instance ID");

        // [WHEN] Approval Comments Page is opened from Approval Entries Page for "AE1".
        ApprovalComments.Trap();
        ApprovalEntries.OpenView();
        ApprovalEntries.Last();
        ApprovalEntries.Comments.Invoke();

        // [THEN] All Approval Commment Lines are visible for the "PI".
        // [THEN] Approval Comment Lines are not filtered by the Workflow Step Instance ID.
        Assert.AreEqual(
          Format(ApprovalEntry[2]."Table ID"), ApprovalComments.FILTER.GetFilter("Table ID"), ApprovalCommentsFilterErr);
        Assert.AreEqual(
          Format(ApprovalEntry[2]."Record ID to Approve"),
          ApprovalComments.FILTER.GetFilter("Record ID to Approve"), ApprovalCommentsFilterErr);
        Assert.AreEqual(
          '', ApprovalComments.FILTER.GetFilter("Workflow Step Instance ID"), ApprovalCommentsNoFilterErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApprovalCommentIsAddedForOpenApprovalEntry()
    var
        PurchaseHeader: Record "Purchase Header";
        ApprovalEntry: array[2] of Record "Approval Entry";
        ApprovalCommentLine: Record "Approval Comment Line";
        PurchaseInvoice: TestPage "Purchase Invoice";
        ApprovalComments: TestPage "Approval Comments";
        Comment: Text[80];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 218295] Approval Comment is added to an Open Approval Entry when invoked from Document.
        Initialize();
        DeleteApprovalEntryAndComments();

        // [GIVEN] Purchase Invoice "PI" with two Approval Entries "AE1" and "AE2" for "PI".
        // [GIVEN] "AE1" = Rejected, "AE2" = Open.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '');
        CreateApprovalEntry(ApprovalEntry[1], CreateGuid(), PurchaseHeader.RecordId, ApprovalEntry[1].Status::Rejected);
        CreateApprovalEntry(ApprovalEntry[2], CreateGuid(), PurchaseHeader.RecordId, ApprovalEntry[2].Status::Open);

        // [GIVEN] Approval Comment Line for "AE1".
        MockApprovalComment(PurchaseHeader.RecordId, ApprovalEntry[1]."Workflow Step Instance ID");
        Comment := LibraryUtility.GenerateGUID();

        // [GIVEN] "PI" is opened, Approval Comments page is invoked.
        ApprovalComments.Trap();
        PurchaseInvoice.OpenView();
        PurchaseInvoice.GotoRecord(PurchaseHeader);
        PurchaseInvoice.Comment.Invoke();

        // [WHEN] A new Approval Comment Line is added.
        ApprovalComments.New();
        ApprovalComments.Comment.SetValue := Comment;
        ApprovalComments.Close();

        // [THEN] Approval Comment Line is added for "PI" and for "AE2".
        FilterApprovalCommentLinesForStepID(ApprovalCommentLine, ApprovalEntry[2]);
        ApprovalCommentLine.SetRange(Comment, Comment);
        Assert.RecordIsNotEmpty(ApprovalCommentLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApprovalCommentIsAddedForSelectedApprovalEntry()
    var
        PurchaseHeader: Record "Purchase Header";
        ApprovalEntry: array[2] of Record "Approval Entry";
        ApprovalCommentLine: Record "Approval Comment Line";
        ApprovalEntries: TestPage "Approval Entries";
        ApprovalComments: TestPage "Approval Comments";
        Comment: Text[80];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 218295] Approval Comment is added for selected Approval Entry when invoked from Approval Entries Page.
        Initialize();
        DeleteApprovalEntryAndComments();

        // [GIVEN] Purchase Invoice "PI" with two Approval Entries "AE1" and "AE2" for "PI".
        // [GIVEN] "AE1" = Rejected, "AE2" = Cancelled.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '');
        CreateApprovalEntry(ApprovalEntry[1], CreateGuid(), PurchaseHeader.RecordId, ApprovalEntry[1].Status::Rejected);
        CreateApprovalEntry(ApprovalEntry[2], CreateGuid(), PurchaseHeader.RecordId, ApprovalEntry[2].Status::Canceled);

        // [GIVEN] Approval Comment Line for "AE1".
        MockApprovalComment(PurchaseHeader.RecordId, ApprovalEntry[1]."Workflow Step Instance ID");
        Comment := LibraryUtility.GenerateGUID();

        // [GIVEN] Approval Entries Page is opened for "AE2", Approval Comments is invoked.
        ApprovalComments.Trap();
        ApprovalEntries.OpenView();
        ApprovalEntries.FILTER.SetFilter(Status, Format(ApprovalEntry[2].Status::Canceled));
        ApprovalEntries.First();
        ApprovalEntries.Comments.Invoke();

        // [WHEN] A new Approval Comment Line is added.
        ApprovalComments.New();
        ApprovalComments.Comment.SetValue := Comment;
        ApprovalComments.Close();

        // [THEN] Approval Comment Line is added for "PI" and for "AE2".
        FilterApprovalCommentLinesForStepID(ApprovalCommentLine, ApprovalEntry[2]);
        ApprovalCommentLine.SetRange(Comment, Comment);
        Assert.RecordIsNotEmpty(ApprovalCommentLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApprovalCommentIsMovedToPostedApprovalCommentLineWhenDocumentIsPosted()
    var
        SalesHeader: Record "Sales Header";
        PostedApprovalCommentLine: Record "Posted Approval Comment Line";
        PostedDocNo: Code[20];
        Comment: Text;
    begin
        // [SCENARIO 225225] Approval comment for Sales Invoice is moved to "Posted Approval Comment Line" table when Sales Invoice is posted.
        Initialize();

        // [GIVEN] Sales Invoice "SI".
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice);

        // [GIVEN] Approval Entry with comment for "SI".
        Comment := MockApprovalEntryWithComment(SalesHeader.RecordId);

        // [WHEN] "SI" is posted.
        PostedDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Approval Comment is moved to "Posted Approval Comment Line" table.
        PostedApprovalCommentLine.SetRange("Document No.", PostedDocNo);
        PostedApprovalCommentLine.SetRange("Table ID", DATABASE::"Sales Invoice Header");
        PostedApprovalCommentLine.FindFirst();
        PostedApprovalCommentLine.TestField(Comment, Comment);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYesNoForUsers,MessageHandler,ApprovalCommentsModalHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ApprovalCommentCreatedFromPendingApprovalFactBoxShouldHaveNonZeroGUID()
    var
        Workflow: Record "Workflow";
        WorkflowStepArgument: Record "Workflow Step Argument";
        PurchaseHeader: Record "Purchase Header";
        UserSetup: Record "User Setup";
        ApprovalCommentLine: Record "Approval Comment Line";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        WorkflowSetup: Codeunit "Workflow Setup";
        PurchaseOrder: TestPage "Purchase Order";
        BlankDateFormula: DateFormula;
    begin
        // [SCENARIO 326154] Approval comment for Purchase Document should be saved when created from Pending Approval FactBox
        Initialize();
        SetupUsers(UserSetup);
        SetApprovalAdmin(UserSetup."Approver ID");
        LibraryWorkflow.DeleteAllExistingWorkflows();
        WorkflowSetup.InsertPurchaseDocumentApprovalWorkflowSteps(
            Workflow, PurchaseHeader."Document Type"::Order,
            WorkflowStepArgument."Approver Type"::"Salesperson/Purchaser",
            WorkflowStepArgument."Approver Limit Type"::"Approver Chain", '', BlankDateFormula);
        Workflow.Validate(Template, false);
        Workflow.Validate(Enabled, true);
        Workflow.Modify(true);

        // [GIVEN] Purchase Order pending for approval
        CreatePurchDocumentWithPurchaserCode(PurchaseHeader, PurchaseHeader."Document Type"::Order, UserSetup."Salespers./Purch. Code");
        ApprovalsMgmt.OnSendPurchaseDocForApproval(PurchaseHeader);
        UpdateApprovalEntryWithTempUser(UserSetup, Database::"Purchase Header", PurchaseHeader."Document Type"::Order, PurchaseHeader."No.");

        // [GIVEN] Approver opens approving record's card (Purchase Order)        
        PurchaseOrder.OpenView();
        PurchaseOrder.GoToRecord(PurchaseHeader);

        // [WHEN] Approval Comment created from Pending Approval FactBox
        PurchaseOrder.Control23.Comment.DrillDown();

        // [THEN] Approval Comment Line created with non-zero Workflow Step Instance ID
        ApprovalCommentLine.SetRange("Record ID to Approve", PurchaseHeader.RecordId);
        ApprovalCommentLine.FindFirst();
        Assert.IsFalse(
            IsNullGuid(ApprovalCommentLine."Workflow Step Instance ID"),
            'Workflow Step Instance ID has wrong value');
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;
        IsInitialized := true;
        BindSubscription(LibraryJobQueue);
    end;

    local procedure AddApprovalComments(DocumentNo: Code[20])
    var
        ApprovalEntries: TestPage "Approval Entries";
    begin
        ApprovalEntries.OpenView();
        ApprovalEntries.FILTER.SetFilter("Document No.", DocumentNo);
        ApprovalEntries.Comments.Invoke();
    end;

    local procedure CreateApprovalEntry(var ApprovalEntry: Record "Approval Entry"; WorkflowInstanceID: Guid; RecID: RecordID; EntryStatus: Enum "Approval Status")
    begin
        ApprovalEntry.Init();
        ApprovalEntry.Validate("Table ID", DATABASE::"Purchase Header");
        ApprovalEntry.Validate("Sequence No.", LibraryRandom.RandInt(100));
        ApprovalEntry."Approver ID" := UserId;
        ApprovalEntry.Status := EntryStatus;
        ApprovalEntry."Record ID to Approve" := RecID;
        ApprovalEntry."Workflow Step Instance ID" := WorkflowInstanceID;
        ApprovalEntry.Insert(true);
    end;

    local procedure CreateApprovalEntryWithPurchInvoice(var ApprovalEntry: Record "Approval Entry"; WorkflowInstanceID: Guid)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '');
        CreateApprovalEntry(ApprovalEntry, WorkflowInstanceID, PurchaseHeader.RecordId, ApprovalEntry.Status::Open);
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; PageID: Integer; TemplateType: Enum "Gen. Journal Template Type")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, TemplateType,
          GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), LibraryRandom.RandDec(100, 2));
        GenJournalTemplate.Validate("Page ID", PageID);
        GenJournalTemplate.Validate(Type, TemplateType);
        GenJournalTemplate.Modify(true);
    end;

    local procedure CreatePurchDocument(var PurchHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type")
    var
        PurchLine: Record "Purchase Line";
        Item: Record Item;
        Vendor: Record Vendor;
    begin
        FindVendor(Vendor);
        FindItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchHeader, DocumentType, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
    end;

    local procedure CreatePurchDocumentWithPurchaserCode(var PurchHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; PurchaserCode: Code[20])
    begin
        CreatePurchDocument(PurchHeader, DocumentType);
        PurchHeader.Validate("Purchaser Code", PurchaserCode);
        PurchHeader.Modify(true);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type")
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        FindCustomer(Customer);
        FindItem(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
    end;

    local procedure CreateSalesDocumentWithSalespersonCode(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; SalespersonCode: Code[20])
    begin
        CreateSalesDocument(SalesHeader, DocumentType);
        SalesHeader.Validate("Salesperson Code", SalespersonCode);
        SalesHeader.Modify(true);
    end;

    local procedure CreateUser(var User: Record User; WindowsUserName: Text[208])
    var
        UserName: Code[50];
    begin
        UserName :=
          CopyStr(LibraryUtility.GenerateRandomCode(User.FieldNo("User Name"), DATABASE::User),
            1, LibraryUtility.GetFieldLength(DATABASE::User, User.FieldNo("User Name")));
        LibraryDocumentApprovals.CreateUser(UserName, WindowsUserName);
        LibraryDocumentApprovals.GetUser(User, WindowsUserName)
    end;

    local procedure MockPostedApprovalCommentLine(PostedRecordID: RecordID)
    var
        PostedApprovalCommentLine: Record "Posted Approval Comment Line";
    begin
        PostedApprovalCommentLine.Init();
        PostedApprovalCommentLine."Entry No." := LibraryUtility.GetNewRecNo(PostedApprovalCommentLine, PostedApprovalCommentLine.FieldNo("Entry No."));
        PostedApprovalCommentLine."Table ID" := PostedRecordID.TableNo;
        PostedApprovalCommentLine."Posted Record ID" := PostedRecordID;
        PostedApprovalCommentLine.Insert();
    end;

    local procedure MockApprovalEntry(RecordIDToApprove: RecordID)
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        ApprovalEntry.Init();
        ApprovalEntry."Entry No." := LibraryUtility.GetNewRecNo(ApprovalEntry, ApprovalEntry.FieldNo("Entry No."));
        ApprovalEntry."Sender ID" := LibraryUtility.GenerateGUID();
        ApprovalEntry."Approver ID" := UserId;
        ApprovalEntry."Table ID" := RecordIDToApprove.TableNo;
        ApprovalEntry."Record ID to Approve" := RecordIDToApprove;
        ApprovalEntry.Status := ApprovalEntry.Status::Open;
        ApprovalEntry.Insert();
    end;

    local procedure MockApprovalEntryWithComment(RecordIDToApprove: RecordID): Text
    var
        BlankGUID: Guid;
    begin
        MockApprovalEntry(RecordIDToApprove);
        exit(MockApprovalComment(RecordIDToApprove, BlankGUID));
    end;

    local procedure MockApprovalComment(RecordIDToApprove: RecordID; WorkflowStepInstanceID: Guid): Text
    var
        ApprovalCommentLine: Record "Approval Comment Line";
    begin
        ApprovalCommentLine.Init();
        ApprovalCommentLine.SetRange("Table ID", RecordIDToApprove.TableNo);
        ApprovalCommentLine.SetRange("Record ID to Approve", RecordIDToApprove);
        ApprovalCommentLine."Workflow Step Instance ID" := WorkflowStepInstanceID;
        ApprovalCommentLine.Comment := LibraryUtility.GenerateGUID();
        ApprovalCommentLine.Insert(true);
        exit(ApprovalCommentLine.Comment);
    end;

    local procedure DeleteApprovalEntryAndComments()
    var
        ApprovalEntry: Record "Approval Entry";
        ApprovalCommentLine: Record "Approval Comment Line";
    begin
        ApprovalEntry.DeleteAll();
        ApprovalCommentLine.DeleteAll();
    end;

    local procedure GetApprovalEntries(var ApprovalEntry: Record "Approval Entry"; TableID: Integer; DocumentType: Enum "Approval Document Type"; DocumentNo: Code[20])
    begin
        ApprovalEntry.SetRange("Table ID", TableID);
        ApprovalEntry.SetRange("Document Type", DocumentType);
        ApprovalEntry.SetRange("Document No.", DocumentNo);
        ApprovalEntry.FindSet();
    end;

    local procedure InsertApprovalCommentsForPurchDocument(DocumentType: Enum "Purchase Document Type")
    var
        UserSetup: Record "User Setup";
        PurchHeader: Record "Purchase Header";
        ApprovalEntry: Record "Approval Entry";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        // Pre-Setup
        Initialize();
        SetupDocumentApprovals(UserSetup, DATABASE::"Purchase Header", DocumentType);

        // Setup
        CreatePurchDocumentWithPurchaserCode(PurchHeader, DocumentType, UserSetup."Salespers./Purch. Code");
        ApprovalsMgmt.OnSendPurchaseDocForApproval(PurchHeader);
        UpdateApprovalEntryWithTempUser(UserSetup, DATABASE::"Purchase Header", DocumentType, PurchHeader."No.");

        // Exercise
        AddApprovalComments(PurchHeader."No.");

        // Verify
        GetApprovalEntries(ApprovalEntry, DATABASE::"Purchase Header", DocumentType, PurchHeader."No.");
        VerifyApprovalCommentLineExist(ApprovalEntry);
    end;

    local procedure InsertApprovalCommentsForSalesDocument(DocumentType: Enum "Sales Document Type")
    var
        UserSetup: Record "User Setup";
        SalesHeader: Record "Sales Header";
        ApprovalEntry: Record "Approval Entry";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        // Pre-Setup
        Initialize();
        SetupDocumentApprovals(UserSetup, DATABASE::"Sales Header", DocumentType);

        // Setup
        CreateSalesDocumentWithSalespersonCode(SalesHeader, DocumentType, UserSetup."Salespers./Purch. Code");
        ApprovalsMgmt.OnSendSalesDocForApproval(SalesHeader);
        UpdateApprovalEntryWithTempUser(UserSetup, DATABASE::"Sales Header", DocumentType, SalesHeader."No.");

        // Exercise
        AddApprovalComments(SalesHeader."No.");

        // Verify
        GetApprovalEntries(ApprovalEntry, DATABASE::"Sales Header", DocumentType, SalesHeader."No.");
        VerifyApprovalCommentLineExist(ApprovalEntry);
    end;

    local procedure RejectApprovalRequest(DocumentNo: Code[20])
    var
        ApprovalEntries: TestPage "Requests to Approve";
    begin
        ApprovalEntries.OpenView();
        ApprovalEntries.FILTER.SetFilter("Document No.", DocumentNo);
        ApprovalEntries.Reject.Invoke();
    end;

    local procedure RejectRequestForSalesDocumentWithComments(DocumentType: Enum "Sales Document Type")
    var
        ApprovalEntry: Record "Approval Entry";
        SalesHeader: Record "Sales Header";
        UserSetup: Record "User Setup";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        // Pre-Setup
        Initialize();
        SetupDocumentApprovals(UserSetup, DATABASE::"Sales Header", DocumentType);

        // Setup
        CreateSalesDocumentWithSalespersonCode(SalesHeader, DocumentType, UserSetup."Salespers./Purch. Code");
        ApprovalsMgmt.OnSendSalesDocForApproval(SalesHeader);
        UpdateApprovalEntryWithTempUser(UserSetup, DATABASE::"Sales Header", DocumentType, SalesHeader."No.");

        // Exercise
        RejectApprovalRequest(SalesHeader."No.");

        // Verify
        GetApprovalEntries(ApprovalEntry, DATABASE::"Sales Header", DocumentType, SalesHeader."No.");
        VerifyApprovalCommentLineExist(ApprovalEntry);
        VerifyRejectedApprovalEntries(ApprovalEntry, UserSetup);
        SalesHeader.Get(DocumentType, SalesHeader."No.");
        SalesHeader.TestField(Status, SalesHeader.Status::Open);
    end;

    local procedure SetApprovalAdmin(ApprovalAdministrator: Code[50])
    var
        UserSetup: Record "User Setup";
    begin
        UserSetup.Get(ApprovalAdministrator);
        UserSetup."Approval Administrator" := true;
        UserSetup.Modify();
    end;

    local procedure SetupApprovalWorkflows(TableNo: Integer; DocumentType: Enum "Approval Document Type")
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
        Workflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        WorkflowSetup: Codeunit "Workflow Setup";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        BlankDateFormula: DateFormula;
    begin
        LibraryWorkflow.DeleteAllExistingWorkflows();

        case TableNo of
            DATABASE::"Purchase Header":
                begin
                    WorkflowSetup.InsertPurchaseDocumentApprovalWorkflowSteps(
                        Workflow, DocumentType,
                        WorkflowStepArgument."Approver Type"::"Salesperson/Purchaser",
                        WorkflowStepArgument."Approver Limit Type"::"Approver Chain", '', BlankDateFormula);
                    Workflow.Validate(Template, false);
                    Workflow.Modify(true);
                    Workflow.InsertAfterFunctionName(WorkflowEventHandling.RunWorkflowOnSendPurchaseDocForApprovalCode(),
                      WorkflowResponseHandling.GetApprovalCommentCode(), false, WorkflowStep.Type::Response);
                end;
            DATABASE::"Sales Header":
                begin
                    WorkflowSetup.InsertSalesDocumentApprovalWorkflowSteps(
                        Workflow, DocumentType,
                        WorkflowStepArgument."Approver Type"::"Salesperson/Purchaser",
                        WorkflowStepArgument."Approver Limit Type"::"Approver Chain", '', BlankDateFormula);
                    Workflow.Validate(Template, false);
                    Workflow.Modify(true);
                    Workflow.InsertAfterFunctionName(WorkflowEventHandling.RunWorkflowOnSendSalesDocForApprovalCode(),
                      WorkflowResponseHandling.GetApprovalCommentCode(), false, WorkflowStep.Type::Response);
                end;
        end;

        Workflow.Validate(Enabled, true);
        Workflow.Modify(true);
    end;

    local procedure SetupDocumentApprovals(var UserSetup: Record "User Setup"; TableNo: Integer; DocumentType: Enum "Approval Document Type")
    begin
        SetupUsers(UserSetup);
        SetApprovalAdmin(UserSetup."Approver ID");
        SetupApprovalWorkflows(TableNo, DocumentType);
    end;

    local procedure SetupUsers(var RequestorUserSetup: Record "User Setup")
    var
        ApproverUserSetup: Record "User Setup";
        RequestorUser: Record User;
    begin
        LibraryDocumentApprovals.CreateMockupUserSetup(ApproverUserSetup);

        if LibraryDocumentApprovals.UserExists(UserId) then
            LibraryDocumentApprovals.GetUser(RequestorUser, UserId)
        else
            CreateUser(RequestorUser, UserId);

        if LibraryDocumentApprovals.GetUserSetup(RequestorUserSetup, UserId) then
            LibraryDocumentApprovals.DeleteUserSetup(RequestorUserSetup, UserId);

        LibraryDocumentApprovals.CreateUserSetup(RequestorUserSetup, RequestorUser."User Name", ApproverUserSetup."User ID");
        LibraryDocumentApprovals.UpdateApprovalLimits(RequestorUserSetup, false, false, false, 0, 0, 0);
    end;

    local procedure UpdateApprovalEntryWithTempUser(UserSetup: Record "User Setup"; TableID: Integer; DocumentType: Enum "Approval Document Type"; DocumentNo: Code[20])
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        GetApprovalEntries(ApprovalEntry, TableID, DocumentType, DocumentNo);
        ApprovalEntry.ModifyAll("Sender ID", UserSetup."Approver ID", true);
        ApprovalEntry.ModifyAll("Approver ID", UserSetup."User ID", true);
    end;

    local procedure EnableRejectionComments(): Guid
    var
        Workflow: Record Workflow;
        WorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        EntryPointStepID: Integer;
    begin
        LibraryWorkflow.DeleteAllExistingWorkflows();
        LibraryWorkflow.CreateWorkflow(Workflow);
        EntryPointStepID :=
          LibraryWorkflow.InsertEntryPointEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnRejectApprovalRequestCode());
        LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.GetApprovalCommentCode(), EntryPointStepID);
        Workflow.Enabled := true;
        Workflow.Modify();
        Workflow.CreateInstance(WorkflowStepInstance);
        WorkflowStepInstance.FindFirst();
        WorkflowStepInstance.Status := WorkflowStepInstance.Status::Active;
        WorkflowStepInstance.Modify();
        exit(WorkflowStepInstance.ID);
    end;

    local procedure ValidateApprovalEntry(var ApprovalEntry: Record "Approval Entry"; SequenceNo: Integer; SenderID: Code[50]; SalespersonPurchCode: Code[20]; ApproverID: Code[50])
    begin
        ApprovalEntry.TestField("Sequence No.", SequenceNo);
        ApprovalEntry.TestField("Sender ID", SenderID);
        ApprovalEntry.TestField("Salespers./Purch. Code", SalespersonPurchCode);
        ApprovalEntry.TestField("Approver ID", ApproverID);
        ApprovalEntry.TestField(Status, ApprovalEntry.Status::Rejected);
        ApprovalEntry.TestField("Approval Type", ApprovalEntry."Approval Type"::"Sales Pers./Purchaser");
    end;

    local procedure VerifyApprovalCommentLineExist(var ApprovalEntry: Record "Approval Entry")
    var
        ApprovalCommentLine: Record "Approval Comment Line";
    begin
        ApprovalCommentLine.SetRange("Table ID", ApprovalEntry."Table ID");
        ApprovalCommentLine.SetRange("Record ID to Approve", ApprovalEntry."Record ID to Approve");
        ApprovalCommentLine.FindFirst();
    end;

    local procedure FilterApprovalCommentLinesForStepID(var ApprovalCommentLine: Record "Approval Comment Line"; ApprovalEntry: Record "Approval Entry")
    begin
        ApprovalCommentLine.SetRange("Table ID", ApprovalEntry."Table ID");
        ApprovalCommentLine.SetRange("Record ID to Approve", ApprovalEntry."Record ID to Approve");
        ApprovalCommentLine.SetRange("Workflow Step Instance ID", ApprovalEntry."Workflow Step Instance ID");
    end;

    local procedure VerifyApprovalCommentLineExistForStepID(ApprovalEntry: Record "Approval Entry")
    var
        ApprovalCommentLine: Record "Approval Comment Line";
    begin
        FilterApprovalCommentLinesForStepID(ApprovalCommentLine, ApprovalEntry);
        Assert.RecordIsNotEmpty(ApprovalCommentLine);
    end;

    local procedure VerifyApprovalCommentLineNotExistForStepID(ApprovalEntry: Record "Approval Entry")
    var
        ApprovalCommentLine: Record "Approval Comment Line";
    begin
        FilterApprovalCommentLinesForStepID(ApprovalCommentLine, ApprovalEntry);
        Assert.RecordIsEmpty(ApprovalCommentLine);
    end;

    local procedure VerifyRejectedApprovalEntries(var ApprovalEntry: Record "Approval Entry"; UserSetup: Record "User Setup")
    begin
        ValidateApprovalEntry(ApprovalEntry, 1, UserSetup."Approver ID", UserSetup."Salespers./Purch. Code", UserSetup."User ID");
        ApprovalEntry.Next();
        ValidateApprovalEntry(ApprovalEntry, 2, UserSetup."Approver ID", UserSetup."Salespers./Purch. Code", UserSetup."User ID");
        Assert.AreEqual(0, ApprovalEntry.Next(), WrongNumberOfApprovalEntriesMsg);
    end;

    local procedure VerifyApprovalEntry(TableNo: Integer; DocumentType: Enum "Approval Document Type"; DocumentNo: Code[20]; ApproverID: Code[50])
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Approved);
        GetApprovalEntries(ApprovalEntry, TableNo, DocumentType, DocumentNo);
        ApprovalEntry.TestField("Approver ID", ApproverID);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ApprovalCommentsHandler(var ApprovalComments: TestPage "Approval Comments")
    begin
        ApprovalComments.Comment.SetValue(LibraryUtility.GenerateGUID());
        ApprovalComments.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApprovalCommentsModalHandler(var ApprovalComments: TestPage "Approval Comments")
    begin
        ApprovalComments.Comment.SetValue(LibraryUtility.GenerateGUID());
        ApprovalComments.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TemplateSelectHandler(var GeneralJournalTemplateList: TestPage "General Journal Template List")
    begin
        GeneralJournalTemplateList.FILTER.SetFilter(Name, LibraryVariableStorage.DequeueText());
        GeneralJournalTemplateList.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYesNoForUsers(Question: Text[1024]; var Reply: Boolean)
    var
        User: Record User;
    begin
        Reply := not User.IsEmpty();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Dummy message handler.
    end;

    local procedure FindCustomer(var Customer: Record Customer)
    begin
        // Filter Customer so that errors are not generated due to mandatory fields.
        Customer.SetFilter("Customer Posting Group", '<>''''');
        Customer.SetFilter("Gen. Bus. Posting Group", '<>''''');
        Customer.SetFilter("Payment Terms Code", '<>''''');
        Customer.SetRange(Blocked, Customer.Blocked::" ");
        // For Complete Shipping Advice, partial shipments are disallowed, hence select Partial.
        Customer.SetRange("Shipping Advice", Customer."Shipping Advice"::Partial);
        Customer.FindFirst();
    end;

    local procedure FindItem(var Item: Record Item)
    begin
        // Filter Item so that errors are not generated due to mandatory fields or Item Tracking.
        Item.SetFilter("Inventory Posting Group", '<>''''');
        Item.SetFilter("Gen. Prod. Posting Group", '<>''''');
        Item.SetRange("Item Tracking Code", '');
        Item.SetRange(Blocked, false);
        Item.SetFilter("Unit Price", '<>0');
        Item.SetFilter(Reserve, '<>%1', Item.Reserve::Always);
        Item.FindFirst();
    end;

    local procedure FindVendor(var Vendor: Record Vendor)
    begin
        // Filter Vendor so that errors are not generated due to mandatory fields.
        Vendor.SetFilter("Vendor Posting Group", '<>''''');
        Vendor.SetFilter("Gen. Bus. Posting Group", '<>''''');
        Vendor.SetRange(Blocked, Vendor.Blocked::" ");
        Vendor.FindFirst();
    end;
}

