codeunit 134203 "Document Approval - Documents"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Workflow] [Approval] [UI]
    end;

    var
        Assert: Codeunit Assert;
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibraryService: Codeunit "Library - Service";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PurchaseBlanketOrderCommentFactbox()
    var
        ApprovalEntry: Record "Approval Entry";
        PurchHeader: Record "Purchase Header";
        UserSetup: Record "User Setup";
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
    begin
        // [SCENARIO 4] Approve from a Purchase Blanket Order
        // [GIVEN] Purchase Blanket Order and a request for approval.
        // [WHEN] Approval Request invoked from the the purchase Blanket Order page.
        // [THEN] The Purchase Blanket Order is approved.

        // Setup
        EnableAllApprovalsWorkflows();
        SetupPurchApproval(ApprovalEntry, PurchHeader, UserSetup, PurchHeader."Document Type"::"Blanket Order");

        // Exercise
        AddComment(
          ApprovalEntry, PurchHeader.RecordId, LibraryUtility.GenerateRandomCode(ApprovalEntry.FieldNo(Comment), DATABASE::"Approval Entry"));

        // Verify
        BlanketPurchaseOrder.OpenView();
        BlanketPurchaseOrder.GotoRecord(PurchHeader);
        Assert.AreEqual(ApprovalEntry."Sender ID", BlanketPurchaseOrder.Control5."Sender ID".Value, '');
        Assert.AreEqual(ApprovalEntry."Due Date", BlanketPurchaseOrder.Control5."Due Date".AsDate(), '');
        Assert.AreEqual(GetFirstApprovalComment(ApprovalEntry), BlanketPurchaseOrder.Control5.Comment.Value, '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoCommentFactbox()
    var
        ApprovalEntry: Record "Approval Entry";
        PurchHeader: Record "Purchase Header";
        UserSetup: Record "User Setup";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // [SCENARIO 8] Approve from a Purchase Credit Memo
        // [GIVEN] Purchase Document and a request for approval.
        // [WHEN] Approval Request invoked from the the purchase Document page.
        // [THEN] The Purchase Document is approved.

        // Setup
        EnableAllApprovalsWorkflows();
        SetupPurchApproval(ApprovalEntry, PurchHeader, UserSetup, PurchHeader."Document Type"::"Credit Memo");

        // Exercise
        AddComment(
          ApprovalEntry, PurchHeader.RecordId, LibraryUtility.GenerateRandomCode(ApprovalEntry.FieldNo(Comment), DATABASE::"Approval Entry"));

        // Verify
        PurchaseCreditMemo.OpenView();
        PurchaseCreditMemo.GotoRecord(PurchHeader);

        if HasOpenApprovalEntriesForCurrentUser(PurchHeader.RecordId) then begin
            Assert.AreEqual(ApprovalEntry."Sender ID", PurchaseCreditMemo.Control15."Sender ID".Value, '');
            Assert.AreEqual(ApprovalEntry."Due Date", PurchaseCreditMemo.Control15."Due Date".AsDate(), '');
            Assert.AreEqual(GetFirstApprovalComment(ApprovalEntry), PurchaseCreditMemo.Control15.Comment.Value, '');
        end;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceCommentFactbox()
    var
        ApprovalEntry: Record "Approval Entry";
        PurchHeader: Record "Purchase Header";
        UserSetup: Record "User Setup";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [SCENARIO 12] Approve from a Purchase Invoice
        // [GIVEN] Purchase Invoice and a request for approval.
        // [WHEN] Approval Request invoked from the the purchase invoice page.
        // [THEN] The Purchase Invoice is approved.

        // Setup
        EnableAllApprovalsWorkflows();
        SetupPurchApproval(ApprovalEntry, PurchHeader, UserSetup, PurchHeader."Document Type"::Invoice);

        // Exercise
        AddComment(
          ApprovalEntry, PurchHeader.RecordId, LibraryUtility.GenerateRandomCode(ApprovalEntry.FieldNo(Comment), DATABASE::"Approval Entry"));

        // Verify
        PurchaseInvoice.OpenView();
        PurchaseInvoice.GotoRecord(PurchHeader);

        if HasOpenApprovalEntriesForCurrentUser(PurchHeader.RecordId) then begin
            Assert.AreEqual(ApprovalEntry."Sender ID", PurchaseInvoice.Control27."Sender ID".Value, '');
            Assert.AreEqual(ApprovalEntry."Due Date", PurchaseInvoice.Control27."Due Date".AsDate(), '');
            Assert.AreEqual(GetFirstApprovalComment(ApprovalEntry), PurchaseInvoice.Control27.Comment.Value, '');
        end;
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PurchaseOrderCommentFactbox()
    var
        ApprovalEntry: Record "Approval Entry";
        PurchHeader: Record "Purchase Header";
        UserSetup: Record "User Setup";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO 16] Approve from a Purchase Order
        // [GIVEN] Purchase Document and a request for approval.
        // [WHEN] Approval Request invoked from the the purchase Document page.
        // [THEN] The Purchase Document is approved.

        // Setup
        EnableAllApprovalsWorkflows();
        SetupPurchApproval(ApprovalEntry, PurchHeader, UserSetup, PurchHeader."Document Type"::Order);

        // Exercise
        AddComment(
          ApprovalEntry, PurchHeader.RecordId, LibraryUtility.GenerateRandomCode(ApprovalEntry.FieldNo(Comment), DATABASE::"Approval Entry"));

        // Verify
        PurchaseOrder.OpenView();
        PurchaseOrder.GotoRecord(PurchHeader);
        Assert.AreEqual(ApprovalEntry."Sender ID", PurchaseOrder.Control23."Sender ID".Value, '');
        Assert.AreEqual(ApprovalEntry."Due Date", PurchaseOrder.Control23."Due Date".AsDate(), '');
        Assert.AreEqual(GetFirstApprovalComment(ApprovalEntry), PurchaseOrder.Control23.Comment.Value, '');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PurchaseQuoteCommentFactbox()
    var
        ApprovalEntry: Record "Approval Entry";
        PurchHeader: Record "Purchase Header";
        UserSetup: Record "User Setup";
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        // [SCENARIO 20] Approve from a Purchase Quote
        // [GIVEN] Purchase Document and a request for approval.
        // [WHEN] Approval Request invoked from the the purchase Document page.
        // [THEN] The Purchase Document is approved.

        // Setup
        EnableAllApprovalsWorkflows();
        SetupPurchApproval(ApprovalEntry, PurchHeader, UserSetup, PurchHeader."Document Type"::Quote);

        // Exercise
        AddComment(
          ApprovalEntry, PurchHeader.RecordId, LibraryUtility.GenerateRandomCode(ApprovalEntry.FieldNo(Comment), DATABASE::"Approval Entry"));

        // Verify
        PurchaseQuote.OpenView();
        PurchaseQuote.GotoRecord(PurchHeader);
        Assert.AreEqual(ApprovalEntry."Sender ID", PurchaseQuote.Control13."Sender ID".Value, '');
        Assert.AreEqual(ApprovalEntry."Due Date", PurchaseQuote.Control13."Due Date".AsDate(), '');
        Assert.AreEqual(GetFirstApprovalComment(ApprovalEntry), PurchaseQuote.Control13.Comment.Value, '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PurchaseReturnOrderCommentFactbox()
    var
        ApprovalEntry: Record "Approval Entry";
        PurchHeader: Record "Purchase Header";
        UserSetup: Record "User Setup";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        // [SCENARIO 24] Approve from a Purchase Return Order
        // [GIVEN] Purchase Document and a request for approval.
        // [WHEN] Approval Request invoked from the the purchase Document page.
        // [THEN] The Purchase Document is approved.

        // Setup
        EnableAllApprovalsWorkflows();
        SetupPurchApproval(ApprovalEntry, PurchHeader, UserSetup, PurchHeader."Document Type"::"Return Order");

        // Exercise
        AddComment(
          ApprovalEntry, PurchHeader.RecordId, LibraryUtility.GenerateRandomCode(ApprovalEntry.FieldNo(Comment), DATABASE::"Approval Entry"));

        // Verify
        PurchaseReturnOrder.OpenView();
        PurchaseReturnOrder.GotoRecord(PurchHeader);

        if HasOpenApprovalEntriesForCurrentUser(PurchHeader.RecordId) then begin
            Assert.AreEqual(ApprovalEntry."Sender ID", PurchaseReturnOrder.Control21."Sender ID".Value, '');
            Assert.AreEqual(ApprovalEntry."Due Date", PurchaseReturnOrder.Control21."Due Date".AsDate(), '');
            Assert.AreEqual(GetFirstApprovalComment(ApprovalEntry), PurchaseReturnOrder.Control21.Comment.Value, '');
        end;
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SalesBlanketOrderCommentFactbox()
    var
        ApprovalEntry: Record "Approval Entry";
        SalesHeader: Record "Sales Header";
        UserSetup: Record "User Setup";
        BlanketSalesOrder: TestPage "Blanket Sales Order";
    begin
        // [SCENARIO 28] Approve from a Sales Blanket Order
        // [GIVEN] Sales Blanket Order and a request for approval.
        // [WHEN] Approval Request invoked from the the Sales Blanket Order page.
        // [THEN] The Purchase Blanket Order is approved.

        // Setup
        EnableAllApprovalsWorkflows();
        SetupSalesApproval(ApprovalEntry, SalesHeader, UserSetup, SalesHeader."Document Type"::"Blanket Order");

        // Exercise
        AddComment(
          ApprovalEntry, SalesHeader.RecordId, LibraryUtility.GenerateRandomCode(ApprovalEntry.FieldNo(Comment), DATABASE::"Approval Entry"));

        // Verify
        BlanketSalesOrder.OpenView();
        BlanketSalesOrder.GotoRecord(SalesHeader);
        Assert.AreEqual(ApprovalEntry."Sender ID", BlanketSalesOrder.Control13."Sender ID".Value, '');
        Assert.AreEqual(ApprovalEntry."Due Date", BlanketSalesOrder.Control13."Due Date".AsDate(), '');
        Assert.AreEqual(GetFirstApprovalComment(ApprovalEntry), BlanketSalesOrder.Control13.Comment.Value, '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SalesCreditMemoCommentFactbox()
    var
        ApprovalEntry: Record "Approval Entry";
        SalesHeader: Record "Sales Header";
        UserSetup: Record "User Setup";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [SCENARIO 32] Approve from a Sales Credit Memo
        // [GIVEN] Sales Document and a request for approval.
        // [WHEN] Approval Request invoked from the the Sales Document page.
        // [THEN] The Purchase Document is approved.

        // Setup
        EnableAllApprovalsWorkflows();
        SetupSalesApproval(ApprovalEntry, SalesHeader, UserSetup, SalesHeader."Document Type"::"Credit Memo");

        // Exercise
        AddComment(
          ApprovalEntry, SalesHeader.RecordId, LibraryUtility.GenerateRandomCode(ApprovalEntry.FieldNo(Comment), DATABASE::"Approval Entry"));

        // Verify
        SalesCreditMemo.OpenView();
        SalesCreditMemo.GotoRecord(SalesHeader);

        if HasOpenApprovalEntriesForCurrentUser(SalesHeader.RecordId) then begin
            Assert.AreEqual(ApprovalEntry."Sender ID", SalesCreditMemo.Control19."Sender ID".Value, '');
            Assert.AreEqual(ApprovalEntry."Due Date", SalesCreditMemo.Control19."Due Date".AsDate(), '');
            Assert.AreEqual(GetFirstApprovalComment(ApprovalEntry), SalesCreditMemo.Control19.Comment.Value, '');
        end;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SalesInvoiceCommentFactbox()
    var
        ApprovalEntry: Record "Approval Entry";
        SalesHeader: Record "Sales Header";
        UserSetup: Record "User Setup";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [SCENARIO 36] Approve from a Sales Invoice
        // [GIVEN] Sales Invoice and a request for approval.
        // [WHEN] Approval Request invoked from the the Sales invoice page.
        // [THEN] The Purchase Invoice is approved.

        // Setup
        EnableAllApprovalsWorkflows();
        SetupSalesApproval(ApprovalEntry, SalesHeader, UserSetup, SalesHeader."Document Type"::Invoice);

        // Exercise
        AddComment(
          ApprovalEntry, SalesHeader.RecordId, LibraryUtility.GenerateRandomCode(ApprovalEntry.FieldNo(Comment), DATABASE::"Approval Entry"));

        // Verify
        SalesInvoice.OpenView();
        SalesInvoice.GotoRecord(SalesHeader);

        if HasOpenApprovalEntriesForCurrentUser(SalesHeader.RecordId) then begin
            Assert.AreEqual(ApprovalEntry."Sender ID", SalesInvoice.Control31."Sender ID".Value, '');
            Assert.AreEqual(ApprovalEntry."Due Date", SalesInvoice.Control31."Due Date".AsDate(), '');
            Assert.AreEqual(GetFirstApprovalComment(ApprovalEntry), SalesInvoice.Control31.Comment.Value, '');
        end;
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SalesOrderCommentFactbox()
    var
        ApprovalEntry: Record "Approval Entry";
        SalesHeader: Record "Sales Header";
        UserSetup: Record "User Setup";
        SalesOrder: TestPage "Sales Order";
    begin
        // [SCENARIO 40] Approve from a Sales Order
        // [GIVEN] Sales Document and a request for approval.
        // [WHEN] Approval Request invoked from the the Sales Document page.
        // [THEN] The Purchase Document is approved.

        // Setup
        EnableAllApprovalsWorkflows();
        SetupSalesApproval(ApprovalEntry, SalesHeader, UserSetup, SalesHeader."Document Type"::Order);

        // Exercise
        AddComment(
          ApprovalEntry, SalesHeader.RecordId, LibraryUtility.GenerateRandomCode(ApprovalEntry.FieldNo(Comment), DATABASE::"Approval Entry"));

        // Verify
        SalesOrder.OpenView();
        SalesOrder.GotoRecord(SalesHeader);
        Assert.AreEqual(ApprovalEntry."Sender ID", SalesOrder.Control35."Sender ID".Value, '');
        Assert.AreEqual(ApprovalEntry."Due Date", SalesOrder.Control35."Due Date".AsDate(), '');
        Assert.AreEqual(GetFirstApprovalComment(ApprovalEntry), SalesOrder.Control35.Comment.Value, '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SalesQuoteCommentFactbox()
    var
        ApprovalEntry: Record "Approval Entry";
        SalesHeader: Record "Sales Header";
        UserSetup: Record "User Setup";
        SalesQuote: TestPage "Sales Quote";
    begin
        // [SCENARIO 44] Approve from a Sales Quote
        // [GIVEN] Sales Document and a request for approval.
        // [WHEN] Approval Request invoked from the the Sales Document page.
        // [THEN] The Purchase Document is approved.

        // Setup
        EnableAllApprovalsWorkflows();
        SetupSalesApproval(ApprovalEntry, SalesHeader, UserSetup, SalesHeader."Document Type"::Quote);

        // Exercise
        AddComment(
          ApprovalEntry, SalesHeader.RecordId, LibraryUtility.GenerateRandomCode(ApprovalEntry.FieldNo(Comment), DATABASE::"Approval Entry"));

        // Verify
        SalesQuote.OpenView();
        SalesQuote.GotoRecord(SalesHeader);

        if HasOpenApprovalEntriesForCurrentUser(SalesHeader.RecordId) then begin
            Assert.AreEqual(ApprovalEntry."Sender ID", SalesQuote.Control11."Sender ID".Value, '');
            Assert.AreEqual(ApprovalEntry."Due Date", SalesQuote.Control11."Due Date".AsDate(), '');
            Assert.AreEqual(GetFirstApprovalComment(ApprovalEntry), SalesQuote.Control11.Comment.Value, '');
        end;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SalesReturnOrderCommentFactbox()
    var
        ApprovalEntry: Record "Approval Entry";
        SalesHeader: Record "Sales Header";
        UserSetup: Record "User Setup";
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        // [SCENARIO 48] Approve from a Sales Return Order
        // [GIVEN] Sales Document and a request for approval.
        // [WHEN] Approval Request invoked from the the Sales Document page.
        // [THEN] The Purchase Document is approved.

        // Setup
        EnableAllApprovalsWorkflows();
        SetupSalesApproval(ApprovalEntry, SalesHeader, UserSetup, SalesHeader."Document Type"::"Return Order");

        // Exercise
        AddComment(
          ApprovalEntry, SalesHeader.RecordId, LibraryUtility.GenerateRandomCode(ApprovalEntry.FieldNo(Comment), DATABASE::"Approval Entry"));

        // Verify
        SalesReturnOrder.OpenView();
        SalesReturnOrder.GotoRecord(SalesHeader);

        if HasOpenApprovalEntriesForCurrentUser(SalesHeader.RecordId) then begin
            Assert.AreEqual(ApprovalEntry."Sender ID", SalesReturnOrder.Control19."Sender ID".Value, '');
            Assert.AreEqual(ApprovalEntry."Due Date", SalesReturnOrder.Control19."Due Date".AsDate(), '');
            Assert.AreEqual(GetFirstApprovalComment(ApprovalEntry), SalesReturnOrder.Control19.Comment.Value, '');
        end;
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithPrepaymentApproval()
    var
        ApprovalEntry: Record "Approval Entry";
        PurchaseHeader: Record "Purchase Header";
        UserSetup: Record "User Setup";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        // [FEATURE] [Approval Request] [Purchases] [Prepayment]
        // [SCENARIO 379881] Purchase Order with not invoiced prepayment can be approved
        Initialize();

        // [GIVEN] Approvals are set for the current User
        EnableAllApprovalsWorkflows();
        SetupPurchApproval(ApprovalEntry, PurchaseHeader, UserSetup, PurchaseHeader."Document Type"::Order);

        // [GIVEN] Create Purchase Order with prepayment
        CreatePurchaseDocumentWithPrepayment(PurchaseHeader, UserSetup."Salespers./Purch. Code");

        // [GIVEN] Send Approval Request (status is changed to "Pending Approval")
        ApprovalsMgmt.OnSendPurchaseDocForApproval(PurchaseHeader);

        // [WHEN] Approve the Request
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(PurchaseHeader.RecordId);
        ApprovalsMgmt.ApproveRecordApprovalRequest(PurchaseHeader.RecordId);

        // [THEN] The Purchase Order status is changed to "Pending Prepayment"
        PurchaseHeader.Find();
        PurchaseHeader.TestField(Status, PurchaseHeader.Status::"Pending Prepayment");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SalesOrderWithPrepaymentApproval()
    var
        ApprovalEntry: Record "Approval Entry";
        SalesHeader: Record "Sales Header";
        UserSetup: Record "User Setup";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        // [FEATURE] [Approval Request] [Sales] [Prepayment]
        // [SCENARIO 379881] Sales Order with not invoiced prepayment can be approved
        Initialize();

        // [GIVEN] Approvals are set for the current User
        EnableAllApprovalsWorkflows();
        SetupSalesApproval(ApprovalEntry, SalesHeader, UserSetup, SalesHeader."Document Type"::Order);

        // [GIVEN] Create Sales Order with prepayment
        CreateSalesDocumentWithPrepayment(SalesHeader, UserSetup."Salespers./Purch. Code");

        // [GIVEN] Send Approval Request (status is changed to "Pending Approval")
        ApprovalsMgmt.OnSendSalesDocForApproval(SalesHeader);

        // [WHEN] Approve the Request
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(SalesHeader.RecordId);
        ApprovalsMgmt.ApproveRecordApprovalRequest(SalesHeader.RecordId);

        // [THEN] The Sales Order status is changed to "Pending Prepayment"
        SalesHeader.Find();
        SalesHeader.TestField(Status, SalesHeader.Status::"Pending Prepayment");

        DeleteSalesVATSetup(SalesHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesOrderWithApprovalComment()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ApprovalCommentLine: Record "Approval Comment Line";
        SalesRecordID: RecordID;
    begin
        // [FEATURE] [UT] [Approval Comment] [Sales] [Post Document]
        // [SCENARIO 381208] Delete approval comments for Sales Order when post it
        Initialize();
        LibraryERMCountryData.CreateVATData();

        // [GIVEN] Sales Order with Approval Entry and Comment
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo(),
          LibraryInventory.CreateItemNo(), LibraryRandom.RandDec(10, 2), '', WorkDate());
        SalesRecordID := SalesHeader.RecordId;
        MockApprovalEntryWithComment(ApprovalCommentLine, SalesRecordID);

        // [WHEN] Post Sales Order
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Approval Comments for Source Order are deleted
        Assert.RecordIsEmpty(ApprovalCommentLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderWithApprovalComment()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ApprovalCommentLine: Record "Approval Comment Line";
        PurchaseRecordID: RecordID;
    begin
        // [FEATURE] [UT] [Approval Comment] [Purchase] [Post Document]
        // [SCENARIO 381208] Delete approval comments for Sales Order when post it
        Initialize();

        // [GIVEN] Purchase Order with Approval Entry and Comment
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo(),
          LibraryInventory.CreateItemNo(), LibraryRandom.RandDec(10, 2), '', WorkDate());
        PurchaseRecordID := PurchaseHeader.RecordId;
        MockApprovalEntryWithComment(ApprovalCommentLine, PurchaseRecordID);

        // [WHEN] Post Purchase Order
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Approval Comments for Source Order are deleted
        Assert.RecordIsEmpty(ApprovalCommentLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopySalesQuotetoOrderWithApprovalComment()
    var
        SalesHeader: Record "Sales Header";
        ApprovalCommentLine: Record "Approval Comment Line";
        QuoteRecordID: RecordID;
    begin
        // [FEATURE] [UT] [Approval Comment] [Sales] [Copy Document]
        // [SCENARIO 381208] Delete approval comments when copy Sales Quote into Sales Order
        Initialize();

        // [GIVEN] Sales Quote with Approval Entry and Comment
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, LibrarySales.CreateCustomerNo());

        QuoteRecordID := SalesHeader.RecordId;
        MockApprovalEntryWithComment(ApprovalCommentLine, QuoteRecordID);

        // [WHEN] Copy Sales Quote to Sales Order
        LibrarySales.QuoteMakeOrder(SalesHeader);

        // [THEN] Approval Comments for Quote are deleted
        Assert.RecordIsEmpty(ApprovalCommentLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyPurchQuotetoOrderWithApprovalComment()
    var
        PurchaseHeader: Record "Purchase Header";
        ApprovalCommentLine: Record "Approval Comment Line";
        QuoteRecordID: RecordID;
    begin
        // [FEATURE] [UT] [Approval Comment] [Purchase] [Copy Document]
        // [SCENARIO 381208] Delete approval comments when copy Purchase Quote into Purchase Order
        Initialize();

        // [GIVEN] Purchase Quote with Approval Entry and Comment
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Quote, LibraryPurchase.CreateVendorNo());
        QuoteRecordID := PurchaseHeader.RecordId;
        MockApprovalEntryWithComment(ApprovalCommentLine, QuoteRecordID);

        // [WHEN] Copy Purchase Quote to Purchase Order
        LibraryPurchase.QuoteMakeOrder(PurchaseHeader);

        // [THEN] Approval Comments for Quote are deleted
        Assert.RecordIsEmpty(ApprovalCommentLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyServiceQuotetoOrderWithApprovalComment()
    var
        ServiceHeader: Record "Service Header";
        ApprovalCommentLine: Record "Approval Comment Line";
        QuoteRecordID: RecordID;
    begin
        // [FEATURE] [UT] [Approval Comment] [Service] [Copy Document]
        // [SCENARIO 381208] Delete approval comments when copy Service Quote into Service Order
        Initialize();

        // [GIVEN] Service Quote with Approval Entry and Comment
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Quote, LibrarySales.CreateCustomerNo());
        QuoteRecordID := ServiceHeader.RecordId;
        MockApprovalEntryWithComment(ApprovalCommentLine, QuoteRecordID);

        // [WHEN] Copy Service Quote to Service Order
        CODEUNIT.Run(CODEUNIT::"Service-Quote to Order", ServiceHeader);

        // [THEN] Approval Comments for Quote are deleted
        Assert.RecordIsEmpty(ApprovalCommentLine);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PurchaseOrderApprovalFactbox()
    var
        PurchaseHeader: Record "Purchase Header";
        ApprovalEntry: Record "Approval Entry";
        ApprovalFactBox: Page "Approval FactBox";
    begin
        // [FEATURE] [UT] [Approval FactBox] [Purchase] [Order]
        // [SCENARIO 382318] The Purchase Order approval factbox shows last entry if you have several approval entries
        Initialize();

        // [GIVEN] Purchase Order with two approval entrires - first Open and second Rejected
        CreatePurchaseDocWithTwoApprovalEntries(PurchaseHeader, PurchaseHeader."Document Type"::Order);

        // [WHEN] Run Approval FactBox subpage from Purchase Order record
        ApprovalFactBox.UpdateApprovalEntriesFromSourceRecord(PurchaseHeader.RecordId);
        ApprovalFactBox.GetRecord(ApprovalEntry);

        // [THEN] Status in FactBox is shown as Rejected (set from second record)
        ApprovalEntry.TestField("Record ID to Approve", PurchaseHeader.RecordId);
        ApprovalEntry.TestField(Status, ApprovalEntry.Status::Rejected);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PurchaseQuoteApprovalFactbox()
    var
        PurchaseHeader: Record "Purchase Header";
        ApprovalEntry: Record "Approval Entry";
        ApprovalFactBox: Page "Approval FactBox";
    begin
        // [FEATURE] [UT] [Approval FactBox] [Purchase] [Quote]
        // [SCENARIO 382318] The Purchase Quote approval factbox shows last entry if you have several approval entries
        Initialize();

        // [GIVEN] Purchase Quote with two approval entrires - first Open and second Rejected
        CreatePurchaseDocWithTwoApprovalEntries(PurchaseHeader, PurchaseHeader."Document Type"::Quote);

        // [WHEN] Run Approval FactBox subpage from Purchase Order record
        ApprovalFactBox.UpdateApprovalEntriesFromSourceRecord(PurchaseHeader.RecordId);
        ApprovalFactBox.GetRecord(ApprovalEntry);

        // [THEN] Status in FactBox is shown as Rejected (set from second record)
        ApprovalEntry.TestField("Record ID to Approve", PurchaseHeader.RecordId);
        ApprovalEntry.TestField(Status, ApprovalEntry.Status::Rejected);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure BlanketPurchaseOrderApprovalFactbox()
    var
        PurchaseHeader: Record "Purchase Header";
        ApprovalEntry: Record "Approval Entry";
        ApprovalFactBox: Page "Approval FactBox";
    begin
        // [FEATURE] [UT] [Approval FactBox] [Purchase] [Blanket Order]
        // [SCENARIO 382318] The Blanket Purchase Order approval factbox shows last entry if you have several approval entries
        Initialize();

        // [GIVEN] Blanket Purchase Order with two approval entrires - first Open and second Rejected
        CreatePurchaseDocWithTwoApprovalEntries(PurchaseHeader, PurchaseHeader."Document Type"::"Blanket Order");

        // [WHEN] Run Approval FactBox subpage from Blanket Purchase Order record
        ApprovalFactBox.UpdateApprovalEntriesFromSourceRecord(PurchaseHeader.RecordId);
        ApprovalFactBox.GetRecord(ApprovalEntry);

        // [THEN] Status in FactBox is shown as Rejected (set from second record)
        ApprovalEntry.TestField("Record ID to Approve", PurchaseHeader.RecordId);
        ApprovalEntry.TestField(Status, ApprovalEntry.Status::Rejected);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PurchaseInvioceApprovalFactbox()
    var
        PurchaseHeader: Record "Purchase Header";
        ApprovalEntry: Record "Approval Entry";
        ApprovalFactBox: Page "Approval FactBox";
    begin
        // [FEATURE] [UT] [Approval FactBox] [Purchase] [Invoice]
        // [SCENARIO 382318] The Purchase Invioce approval factbox shows last entry if you have several approval entries
        Initialize();

        // [GIVEN] Purchase Invoice with two approval entrires - first Open and second Rejected
        CreatePurchaseDocWithTwoApprovalEntries(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);

        // [WHEN] Run Approval FactBox subpage from Purchase Invoice record
        ApprovalFactBox.UpdateApprovalEntriesFromSourceRecord(PurchaseHeader.RecordId);
        ApprovalFactBox.GetRecord(ApprovalEntry);

        // [THEN] Status in FactBox is shown as Rejected (set from second record)
        ApprovalEntry.TestField("Record ID to Approve", PurchaseHeader.RecordId);
        ApprovalEntry.TestField(Status, ApprovalEntry.Status::Rejected);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoApprovalFactbox()
    var
        PurchaseHeader: Record "Purchase Header";
        ApprovalEntry: Record "Approval Entry";
        ApprovalFactBox: Page "Approval FactBox";
    begin
        // [FEATURE] [UT] [Approval FactBox] [Purchase] [Credit Memo]
        // [SCENARIO 382318] The Purchase Credit Memo approval factbox shows last entry if you have several approval entries
        Initialize();

        // [GIVEN] Purchase Credit Memo with two approval entrires - first Open and second Rejected
        CreatePurchaseDocWithTwoApprovalEntries(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo");

        // [WHEN] Run Approval FactBox subpage from Purchase Credit Memo record
        ApprovalFactBox.UpdateApprovalEntriesFromSourceRecord(PurchaseHeader.RecordId);
        ApprovalFactBox.GetRecord(ApprovalEntry);

        // [THEN] Status in FactBox is shown as Rejected (set from second record)
        ApprovalEntry.TestField("Record ID to Approve", PurchaseHeader.RecordId);
        ApprovalEntry.TestField(Status, ApprovalEntry.Status::Rejected);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PurchaseReturnOrderApprovalFactbox()
    var
        PurchaseHeader: Record "Purchase Header";
        ApprovalEntry: Record "Approval Entry";
        ApprovalFactBox: Page "Approval FactBox";
    begin
        // [FEATURE] [UT] [Approval FactBox] [Purchase] [Return Order]
        // [SCENARIO 382318] The Purchase Return Order approval factbox shows last entry if you have several approval entries
        Initialize();

        // [GIVEN] Purchase Return Order with two approval entrires - first Open and second Rejected
        CreatePurchaseDocWithTwoApprovalEntries(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order");

        // [WHEN] Run Approval FactBox subpage from Purchase Return Order record
        ApprovalFactBox.UpdateApprovalEntriesFromSourceRecord(PurchaseHeader.RecordId);
        ApprovalFactBox.GetRecord(ApprovalEntry);

        // [THEN] Status in FactBox is shown as Rejected (set from second record)
        ApprovalEntry.TestField("Record ID to Approve", PurchaseHeader.RecordId);
        ApprovalEntry.TestField(Status, ApprovalEntry.Status::Rejected);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SalesOrderApprovalFactbox()
    var
        SalesHeader: Record "Sales Header";
        ApprovalEntry: Record "Approval Entry";
        ApprovalFactBox: Page "Approval FactBox";
    begin
        // [FEATURE] [UT] [Approval FactBox] [Sales] [Order]
        // [SCENARIO 382318] The approval factbox shows last entry if you have several approval entries
        Initialize();

        // [GIVEN] Sales Order with two approval entrires - first Open and second Rejected
        CreateSalesDocWithTwoApprovalEntries(SalesHeader, SalesHeader."Document Type"::Order);

        // [WHEN] Run Approval FactBox subpage from Sales Order record
        ApprovalFactBox.UpdateApprovalEntriesFromSourceRecord(SalesHeader.RecordId);
        ApprovalFactBox.GetRecord(ApprovalEntry);

        // [THEN] Status in FactBox is shown as Rejected (set from second record)
        ApprovalEntry.TestField("Record ID to Approve", SalesHeader.RecordId);
        ApprovalEntry.TestField(Status, ApprovalEntry.Status::Rejected);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SalesQuoteApprovalFactbox()
    var
        SalesHeader: Record "Sales Header";
        ApprovalEntry: Record "Approval Entry";
        ApprovalFactBox: Page "Approval FactBox";
    begin
        // [FEATURE] [UT] [Approval FactBox] [Sales] [Quote]
        // [SCENARIO 382318] The approval factbox shows last entry if you have several approval entries
        Initialize();

        // [GIVEN] Sales Quote with two approval entrires - first Open and second Rejected
        CreateSalesDocWithTwoApprovalEntries(SalesHeader, SalesHeader."Document Type"::Quote);

        // [WHEN] Run Approval FactBox subpage from Sales Quote record
        ApprovalFactBox.UpdateApprovalEntriesFromSourceRecord(SalesHeader.RecordId);
        ApprovalFactBox.GetRecord(ApprovalEntry);

        // [THEN] Status in FactBox is shown as Rejected (set from second record)
        ApprovalEntry.TestField("Record ID to Approve", SalesHeader.RecordId);
        ApprovalEntry.TestField(Status, ApprovalEntry.Status::Rejected);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure BlanketSalesOrderApprovalFactbox()
    var
        SalesHeader: Record "Sales Header";
        ApprovalEntry: Record "Approval Entry";
        ApprovalFactBox: Page "Approval FactBox";
    begin
        // [FEATURE] [UT] [Approval FactBox] [Sales] [Blanket Order]
        // [SCENARIO 382318] The approval factbox shows last entry if you have several approval entries
        Initialize();

        // [GIVEN] Blanket Sales Order with two approval entrires - first Open and second Rejected
        CreateSalesDocWithTwoApprovalEntries(SalesHeader, SalesHeader."Document Type"::"Blanket Order");

        // [WHEN] Run Approval FactBox subpage from Blanket Sales Order record
        ApprovalFactBox.UpdateApprovalEntriesFromSourceRecord(SalesHeader.RecordId);
        ApprovalFactBox.GetRecord(ApprovalEntry);

        // [THEN] Status in FactBox is shown as Rejected (set from second record)
        ApprovalEntry.TestField("Record ID to Approve", SalesHeader.RecordId);
        ApprovalEntry.TestField(Status, ApprovalEntry.Status::Rejected);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SalesInvioiceApprovalFactbox()
    var
        SalesHeader: Record "Sales Header";
        ApprovalEntry: Record "Approval Entry";
        ApprovalFactBox: Page "Approval FactBox";
    begin
        // [FEATURE] [UT] [Approval FactBox] [Sales] [Invoice]
        // [SCENARIO 382318] The approval factbox shows last entry if you have several approval entries
        Initialize();

        // [GIVEN] Sales Invioice with two approval entrires - first Open and second Rejected
        CreateSalesDocWithTwoApprovalEntries(SalesHeader, SalesHeader."Document Type"::Invoice);

        // [WHEN] Run Approval FactBox subpage from Sales Invioice record
        ApprovalFactBox.UpdateApprovalEntriesFromSourceRecord(SalesHeader.RecordId);
        ApprovalFactBox.GetRecord(ApprovalEntry);

        // [THEN] Status in FactBox is shown as Rejected (set from second record)
        ApprovalEntry.TestField("Record ID to Approve", SalesHeader.RecordId);
        ApprovalEntry.TestField(Status, ApprovalEntry.Status::Rejected);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SalesCreditMemoApprovalFactbox()
    var
        SalesHeader: Record "Sales Header";
        ApprovalEntry: Record "Approval Entry";
        ApprovalFactBox: Page "Approval FactBox";
    begin
        // [FEATURE] [UT] [Approval FactBox] [Sales] [Credit Memo]
        // [SCENARIO 382318] The Sales Credit Memo approval factbox shows last entry if you have several approval entries
        Initialize();

        // [GIVEN] Sales Credit Memo with two approval entrires - first Open and second Rejected
        CreateSalesDocWithTwoApprovalEntries(SalesHeader, SalesHeader."Document Type"::"Credit Memo");

        // [WHEN] Run Approval FactBox subpage from Sales Credit Memo record
        ApprovalFactBox.UpdateApprovalEntriesFromSourceRecord(SalesHeader.RecordId);
        ApprovalFactBox.GetRecord(ApprovalEntry);

        // [THEN] Status in FactBox is shown as Rejected (set from second record)
        ApprovalEntry.TestField("Record ID to Approve", SalesHeader.RecordId);
        ApprovalEntry.TestField(Status, ApprovalEntry.Status::Rejected);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SalesReturnOrderApprovalFactbox()
    var
        SalesHeader: Record "Sales Header";
        ApprovalEntry: Record "Approval Entry";
        ApprovalFactBox: Page "Approval FactBox";
    begin
        // [FEATURE] [UT] [Approval FactBox] [Sales] [Return Order]
        // [SCENARIO 382318] The Sales Return Order approval factbox shows last entry if you have several approval entries
        Initialize();

        // [GIVEN] Sales Return Order with two approval entrires - first Open and second Rejected
        CreateSalesDocWithTwoApprovalEntries(SalesHeader, SalesHeader."Document Type"::"Return Order");

        // [WHEN] Run Approval FactBox subpage from Sales Return Order record
        ApprovalFactBox.UpdateApprovalEntriesFromSourceRecord(SalesHeader.RecordId);
        ApprovalFactBox.GetRecord(ApprovalEntry);

        // [THEN] Status in FactBox is shown as Rejected (set from second record)
        ApprovalEntry.TestField("Record ID to Approve", SalesHeader.RecordId);
        ApprovalEntry.TestField(Status, ApprovalEntry.Status::Rejected);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ApprovalFactboxWithoutEntries()
    var
        SalesHeader: Record "Sales Header";
        ApprovalEntry: Record "Approval Entry";
        ApprovalFactBox: Page "Approval FactBox";
    begin
        // [FEATURE] [UT] [Approval FactBox]
        // [SCENARIO 382318] The approval factbox is Empty if you haven't associated approval entries
        Initialize();

        // [GIVEN] Sales Order without Approvals
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, LibrarySales.CreateCustomerNo());

        // [WHEN] Run Approval FactBox subpage from Sales Order
        ApprovalFactBox.UpdateApprovalEntriesFromSourceRecord(SalesHeader.RecordId);

        // [THEN] Approval FactBox subpage has no records
        ApprovalFactBox.GetRecord(ApprovalEntry);
        asserterror ApprovalEntry.Find();
        Assert.AssertRecordNotFound();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ApprovalFactboxSenderAsApprover()
    var
        SalesHeader: Record "Sales Header";
        ApprovalEntry: Record "Approval Entry";
        UserSetup: Record "User Setup";
        ApprovalFactBox: Page "Approval FactBox";
    begin
        // [FEATURE] [UT] [Approval FactBox]
        // [SCENARIO 382318] The approval factbox is Empty if Sender is equal to Approver
        Initialize();

        // [GIVEN] Sales Order with Approval Entry Sender equal Approval Entry Approver
        SetupDocumentApprovals(UserSetup, '');
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        MockApprovalEntry(
          SalesHeader."Document Type"::Order, SalesHeader."No.", SalesHeader.RecordId, ApprovalEntry.Status::Open,
          UserSetup."User ID", UserSetup."User ID");

        // [WHEN] Run Approval FactBox subpage from Sales Order
        ApprovalFactBox.UpdateApprovalEntriesFromSourceRecord(SalesHeader.RecordId);

        // [THEN] Approval FactBox subpage has no records
        ApprovalFactBox.GetRecord(ApprovalEntry);
        asserterror ApprovalEntry.Find();
        Assert.AssertRecordNotFound();
    end;

    [Test]
    procedure CreateNonWindowsUserUT()
    var
        User: Record User;
        AccessControl: Record "Access Control";
        UserName: Code[50];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 375285] Run CreateNonWindowsUser() of codeunit Library - Document Approvals.

        // [GIVEN] A SUPER user with Windows authentification type is created to avoid an error: "You must assign at least one user the SUPER permission set".
        LibraryDocumentApprovals.CreateUser(LibraryUtility.GenerateGUID(), UserId());

        // [WHEN] Run CreateNonWindowsUser() function of codeunit Library - Document Approvals.
        UserName := LibraryUtility.GenerateGUID();
        LibraryDocumentApprovals.CreateNonWindowsUser(UserName);

        // [THEN] A non-windows user is created. The user has SUPER permission set assigned.
        User.SetRange("User Name", UserName);
        User.FindFirst();
        User.TestField("User Security ID");
        User.TestField("Windows Security ID", '');

        AccessControl.SetRange("User Security ID", User."User Security ID");
        AccessControl.FindFirst();
        AccessControl.TestField("Role ID", 'SUPER');
        AccessControl.TestField("Company Name", '');
        AccessControl.TestField(Scope, AccessControl.Scope::System);

        // Tear down
        User.Delete();
        User.SetRange("User Name", UserId());
        User.DeleteAll();
    end;

    local procedure CreatePurchDocument(var PurchHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type")
    var
        PurchLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandDecInRange(5, 10, 2));
        CreateGeneralPostingSetupWithGroups(GeneralPostingSetup);
        LibraryPurchase.CreatePurchHeader(
            PurchHeader, DocumentType, LibraryPurchase.CreateVendorWithBusPostingGroups(GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group"));
        LibraryPurchase.CreatePurchaseLine(
            PurchLine, PurchHeader, PurchLine.Type::Item,
            CreateItemNoWithPostingSetup(GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group"), LibraryRandom.RandDecInRange(10, 20, 2));

        VendorPostingGroup.Get(PurchHeader."Vendor Posting Group");
        UpdateProdPostingGroupsOnInvRoundingAccount(VendorPostingGroup.GetInvRoundingAccount(), GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
    end;

    local procedure CreatePurchDocumentWithPurchaserCode(var PurchHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; PurchaserCode: Code[20])
    begin
        CreatePurchDocument(PurchHeader, DocumentType);
        PurchHeader.Validate("Purchaser Code", PurchaserCode);
        PurchHeader.Modify(true);
    end;

    local procedure CreatePurchaseDocumentWithPrepayment(var PurchaseHeader: Record "Purchase Header"; PurchaserCode: Code[20])
    var
        LineGLAccount: Record "G/L Account";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreatePrepaymentVATSetup(LineGLAccount, "Tax Calculation Type"::"Normal VAT");
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Gen. Bus. Posting Group", LineGLAccount."Gen. Bus. Posting Group");
        Vendor.Validate("VAT Bus. Posting Group", LineGLAccount."VAT Bus. Posting Group");
        Vendor.Modify(true);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        PurchaseHeader.Validate("Purchaser Code", PurchaserCode);
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LineGLAccount."No.", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 1000, 2));
        PurchaseLine.Validate("Prepayment %", LibraryRandom.RandIntInRange(10, 90));
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseDocWithTwoApprovalEntries(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type")
    var
        UserSetup: Record "User Setup";
    begin
        SetupDocumentApprovals(UserSetup, '');
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, LibraryPurchase.CreateVendorNo());
        MockApprovalEntry(
          DocumentType, PurchaseHeader."No.", PurchaseHeader.RecordId, "Approval Status"::Open, UserSetup."User ID", '');
        MockApprovalEntry(
          DocumentType, PurchaseHeader."No.", PurchaseHeader.RecordId, "Approval Status"::Rejected, UserSetup."User ID", '');
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type")
    var
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandDecInRange(5, 10, 2));
        CreateGeneralPostingSetupWithGroups(GeneralPostingSetup);
        LibrarySales.CreateSalesHeader(
            SalesHeader, DocumentType, LibrarySales.CreateCustomerWithBusPostingGroups(GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group"));
        LibrarySales.CreateSalesLine(
            SalesLine, SalesHeader, SalesLine.Type::Item,
            CreateItemNoWithPostingSetup(GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group"), LibraryRandom.RandDecInRange(10, 20, 2));

        CustomerPostingGroup.Get(SalesHeader."Customer Posting Group");
        UpdateProdPostingGroupsOnInvRoundingAccount(CustomerPostingGroup.GetInvRoundingAccount(), GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
    end;

    local procedure CreateSalesDocumentWithSalespersonCode(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; SalespersonCode: Code[20])
    begin
        CreateSalesDocument(SalesHeader, DocumentType);
        SalesHeader.Validate("Salesperson Code", SalespersonCode);
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesDocumentWithPrepayment(var SalesHeader: Record "Sales Header"; SalespersonCode: Code[20])
    var
        Customer: Record Customer;
        LineGLAccount: Record "G/L Account";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreatePrepaymentVATSetup(LineGLAccount, "Tax Calculation Type"::"Normal VAT");
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Gen. Bus. Posting Group", LineGLAccount."Gen. Bus. Posting Group");
        Customer.Validate("VAT Bus. Posting Group", LineGLAccount."VAT Bus. Posting Group");
        Customer.Modify(true);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader.Validate("Salesperson Code", SalespersonCode);
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LineGLAccount."No.", LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(10, 1000, 2));
        SalesLine.Validate("Prepayment %", LibraryRandom.RandIntInRange(10, 90));
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesDocWithTwoApprovalEntries(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type")
    var
        UserSetup: Record "User Setup";
    begin
        SetupDocumentApprovals(UserSetup, '');
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, LibrarySales.CreateCustomerNo());
        MockApprovalEntry(
          DocumentType, SalesHeader."No.", SalesHeader.RecordId, "Approval Status"::Open, UserSetup."User ID", '');
        MockApprovalEntry(
          DocumentType, SalesHeader."No.", SalesHeader.RecordId, "Approval Status"::Rejected, UserSetup."User ID", '');
    end;

    local procedure CreateGeneralPostingSetupWithGroups(var GeneralPostingSetup: Record "General Posting Setup")
    var
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        LibraryERM.CreateGenBusPostingGroup(GenBusinessPostingGroup);
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, GenBusinessPostingGroup.Code, GenProductPostingGroup.Code);
    end;

    local procedure CreateItemNoWithPostingSetup(GenProdPostingGroup: Code[20]; VATProductPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
        InventoryPostingGroup: Record "Inventory Posting Group";
    begin
        LibraryInventory.CreateInventoryPostingGroup(InventoryPostingGroup);
        LibraryInventory.CreateItemWithPostingSetup(Item, GenProdPostingGroup, VATProductPostingGroup);
        Item.Validate("Inventory Posting Group", InventoryPostingGroup.Code);
        Item.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 200, 2));
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure DeleteSalesVATSetup(DocumentNo: Code[20])
    var
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.FindFirst();
        VATPostingSetup.SetRange("VAT Bus. Posting Group", SalesLine."VAT Bus. Posting Group");
        VATPostingSetup.SetRange("VAT Prod. Posting Group", SalesLine."VAT Prod. Posting Group");
        VATPostingSetup.DeleteAll();
    end;

    local procedure CreateUser(var User: Record User; WindowsUserName: Text[208])
    var
        UserName: Code[50];
    begin
        UserName := GenerateUserName();
        LibraryDocumentApprovals.CreateUser(UserName, WindowsUserName);
        LibraryDocumentApprovals.GetUser(User, WindowsUserName)
    end;

    local procedure GenerateUserName() UserName: Code[50]
    var
        User: Record User;
    begin
        repeat
            UserName :=
              CopyStr(LibraryUtility.GenerateRandomCode(User.FieldNo("User Name"), DATABASE::User),
                1, LibraryUtility.GetFieldLength(DATABASE::User, User.FieldNo("User Name")));
            User.SetRange("User Name", UserName);
        until User.IsEmpty();
    end;

    local procedure GetApprovalEntries(var ApprovalEntry: Record "Approval Entry"; TableID: Integer; DocumentType: Enum "Approval Document Type"; DocumentNo: Code[20])
    begin
        ApprovalEntry.SetRange("Table ID", TableID);
        ApprovalEntry.SetRange("Document Type", DocumentType);
        ApprovalEntry.SetRange("Document No.", DocumentNo);
        ApprovalEntry.FindSet();
    end;

    local procedure SetApprovalAdmin(ApprovalAdministrator: Code[50])
    var
        UserSetup: Record "User Setup";
    begin
        UserSetup.Get(ApprovalAdministrator);
        UserSetup."Approval Administrator" := true;
        UserSetup.Modify();
    end;

    local procedure SetupDocumentApprovals(var UserSetup: Record "User Setup"; Substitute: Code[50])
    begin
        SetupUsers(UserSetup, Substitute, false, false, false, 0, 0, 0);
        SetApprovalAdmin(UserSetup."Approver ID");
        Clear(ApprovalsMgmt);
    end;

    local procedure SetupUsers(var RequestorUserSetup: Record "User Setup"; Substitute: Code[50]; UnlimitedSalesApproval: Boolean; UnlimitedPurchaseApproval: Boolean; UnlimitedRequestApproval: Boolean; SalesAmountApprovalLimit: Integer; PurchaseAmountApprovalLimit: Integer; RequestAmountApprovalLimit: Integer)
    var
        ApproverUserSetup: Record "User Setup";
        RequestorUser: Record User;
    begin
        LibraryDocumentApprovals.CreateMockupUserSetup(ApproverUserSetup);
        UpdateSubstitute(ApproverUserSetup, Substitute);

        if LibraryDocumentApprovals.UserExists(UserId) then
            LibraryDocumentApprovals.GetUserSetup(RequestorUserSetup, UserId)
        else begin
            CreateUser(RequestorUser, UserId);
            LibraryDocumentApprovals.CreateUserSetup(RequestorUserSetup, RequestorUser."User Name", ApproverUserSetup."User ID");
            LibraryDocumentApprovals.UpdateApprovalLimits(RequestorUserSetup, UnlimitedSalesApproval, UnlimitedPurchaseApproval,
              UnlimitedRequestApproval, SalesAmountApprovalLimit, PurchaseAmountApprovalLimit, RequestAmountApprovalLimit);
        end;
    end;

    local procedure SetupPurchApproval(var ApprovalEntry: Record "Approval Entry"; var PurchHeader: Record "Purchase Header"; var UserSetup: Record "User Setup"; DocumentType: Enum "Purchase Document Type")
    begin
        Initialize();

        // Pre-Setup
        if UserSetup."User ID" = '' then
            SetupDocumentApprovals(UserSetup, '');

        // Setup
        CreatePurchDocumentWithPurchaserCode(PurchHeader, DocumentType, UserSetup."Salespers./Purch. Code");
        ApprovalsMgmt.OnSendPurchaseDocForApproval(PurchHeader);
        UpdateApprovalEntryWithTempUser(UserSetup, DATABASE::"Purchase Header", DocumentType, PurchHeader."No.");
        GetApproval(ApprovalEntry, DATABASE::"Purchase Header", DocumentType, PurchHeader."No.");
    end;

    local procedure SetupSalesApproval(var ApprovalEntry: Record "Approval Entry"; var SalesHeader: Record "Sales Header"; var UserSetup: Record "User Setup"; DocumentType: Enum "Sales Document Type")
    begin
        Initialize();

        // Pre-Setup
        if UserSetup."User ID" = '' then
            SetupDocumentApprovals(UserSetup, '');

        // Setup
        CreateSalesDocumentWithSalespersonCode(SalesHeader, DocumentType, UserSetup."Salespers./Purch. Code");
        ApprovalsMgmt.OnSendSalesDocForApproval(SalesHeader);
        UpdateApprovalEntryWithTempUser(UserSetup, DATABASE::"Sales Header", DocumentType, SalesHeader."No.");
        GetApproval(ApprovalEntry, DATABASE::"Sales Header", DocumentType, SalesHeader."No.");
    end;

    local procedure UpdateApprovalEntryWithTempUser(UserSetup: Record "User Setup"; TableID: Integer; DocumentType: Enum "Approval Document Type"; DocumentNo: Code[20])
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        GetApprovalEntries(ApprovalEntry, TableID, DocumentType, DocumentNo);
        ApprovalEntry.ModifyAll("Sender ID", UserSetup."Approver ID", true);
        ApprovalEntry.ModifyAll("Approver ID", UserSetup."User ID", true);
    end;

    local procedure UpdateSubstitute(var UserSetup: Record "User Setup"; Substitute: Code[50])
    begin
        UserSetup.Validate(Substitute, Substitute);
        UserSetup.Modify(true);
    end;

    local procedure UpdateProdPostingGroupsOnInvRoundingAccount(InvRoundingAccountCode: Code[20]; GenProdPostingGroupCode: Code[20]; VATProdPostingGroupCode: Code[20])
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get(InvRoundingAccountCode);
        GLAccount.Validate("Gen. Prod. Posting Group", GenProdPostingGroupCode);
        GLAccount.Validate("VAT Prod. Posting Group", VATProdPostingGroupCode);
        GLAccount.Modify(true);
    end;

    local procedure GetApproval(var ApprovalEntry: Record "Approval Entry"; TableID: Integer; DocumentType: Enum "Approval Document Type"; DocumentNo: Code[20])
    begin
        ApprovalEntry.SetRange("Table ID", TableID);
        ApprovalEntry.SetRange("Document Type", DocumentType);
        ApprovalEntry.SetRange("Document No.", DocumentNo);
        ApprovalEntry.FindFirst();
    end;

    local procedure MockApprovalEntry(SrcDocType: Enum "Approval Document Type"; SrcDocNo: Code[20]; SourceRecordID: RecordID; DestinationStatus: Enum "Approval Status"; SenderID: Code[50]; ApproverID: Code[50])
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        ApprovalEntry.Init();
        ApprovalEntry."Table ID" := SourceRecordID.TableNo;
        ApprovalEntry."Document Type" := SrcDocType;
        ApprovalEntry."Document No." := SrcDocNo;
        ApprovalEntry."Record ID to Approve" := SourceRecordID;
        ApprovalEntry.Status := DestinationStatus;
        ApprovalEntry."Sender ID" := SenderID;
        ApprovalEntry."Approver ID" := ApproverID;
        ApprovalEntry.Insert();
    end;

    local procedure MockApprovalEntryWithComment(var ApprovalCommentLine: Record "Approval Comment Line"; SourceRecordID: RecordID)
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        ApprovalEntry.Init();
        ApprovalEntry.Validate("Table ID", SourceRecordID.TableNo);
        ApprovalEntry.Validate("Record ID to Approve", SourceRecordID);
        ApprovalEntry.Insert(true);

        AddComment(ApprovalEntry, SourceRecordID, LibraryUtility.GenerateGUID());
        ApprovalCommentLine.SetRange("Record ID to Approve", SourceRecordID);
        Assert.RecordIsNotEmpty(ApprovalCommentLine);
    end;

    local procedure AddComment(ApprovalEntry: Record "Approval Entry"; SourceRecordID: RecordID; Comment: Text[80])
    var
        ApprovalCommentLine: Record "Approval Comment Line";
    begin
        ApprovalCommentLine.Init();
        ApprovalCommentLine."Table ID" := ApprovalEntry."Table ID";
        ApprovalCommentLine."Document Type" := ApprovalEntry."Document Type";
        ApprovalCommentLine."Document No." := ApprovalEntry."Document No.";
        ApprovalCommentLine."Record ID to Approve" := SourceRecordID;
        ApprovalCommentLine."Workflow Step Instance ID" := ApprovalEntry."Workflow Step Instance ID";
        ApprovalCommentLine."User ID" := UserId;
        ApprovalCommentLine.Comment := Comment;
        ApprovalCommentLine.Insert();
    end;

    local procedure GetFirstApprovalComment(ApprovalEntry: Record "Approval Entry"): Text
    var
        ApprovalCommentLine: Record "Approval Comment Line";
    begin
        ApprovalCommentLine.SetRange("Table ID", ApprovalEntry."Table ID");
        ApprovalCommentLine.SetRange("Document Type", ApprovalEntry."Document Type");
        ApprovalCommentLine.SetRange("Document No.", ApprovalEntry."Document No.");
        ApprovalCommentLine.FindFirst();
        exit(ApprovalCommentLine.Comment);
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateVATData();
        BindSubscription(LibraryJobQueue);
        IsInitialized := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Dummy message handler.
    end;

    local procedure EnableAllApprovalsWorkflows()
    var
        Workflow: Record Workflow;
        ActualWorkflow: Record Workflow;
        UserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        LibraryDocumentApprovals.CreateMockupUserSetup(UserSetup);
        Workflow.SetFilter(Code, StrSubstNo('<>%1&<>%2&<>%3&<>%4&<>%5',
            WorkflowSetup.GetWorkflowTemplateCode(WorkflowSetup.PurchaseInvoiceWorkflowCode()),
            WorkflowSetup.GetWorkflowTemplateCode(WorkflowSetup.SalesInvoiceCreditLimitApprovalWorkflowCode()),
            WorkflowSetup.GetWorkflowTemplateCode(WorkflowSetup.SalesOrderCreditLimitApprovalWorkflowCode()),
            WorkflowSetup.GetWorkflowTemplateCode(WorkflowSetup.ItemUnitPriceChangeApprovalWorkflowCode()),
            WorkflowSetup.GetWorkflowTemplateCode(WorkflowSetup.IncomingDocumentOCRWorkflowCode())));
        Workflow.SetRange(Template, true);
        Workflow.FindSet();
        repeat
            LibraryWorkflow.CopyWorkflow(ActualWorkflow, Workflow.Code);
            if Workflow.Code = WorkflowSetup.GetWorkflowTemplateCode(WorkflowSetup.PurchaseBlanketOrderApprovalWorkflowCode()) then
                CreateWorkflowUserGroupForWorkflow(UserSetup, ActualWorkflow.Code);
            if Workflow.Code = WorkflowSetup.GetWorkflowTemplateCode(WorkflowSetup.IncomingDocumentApprovalWorkflowCode()) then
                CreateWorkflowUserGroupForWorkflow(UserSetup, ActualWorkflow.Code);
            if Workflow.Code = WorkflowSetup.GetWorkflowTemplateCode(WorkflowSetup.SalesBlanketOrderApprovalWorkflowCode()) then
                CreateWorkflowUserGroupForWorkflow(UserSetup, ActualWorkflow.Code);
            if Workflow.Code = WorkflowSetup.GetWorkflowTemplateCode(WorkflowSetup.CustomerCreditLimitChangeApprovalWorkflowCode()) then
                CreateWorkflowUserGroupForWorkflow(UserSetup, ActualWorkflow.Code);
            if Workflow.Code = WorkflowSetup.GetWorkflowTemplateCode(WorkflowSetup.ItemUnitPriceChangeApprovalWorkflowCode()) then
                CreateWorkflowUserGroupForWorkflow(UserSetup, ActualWorkflow.Code);
            AddUserForNotifications(ActualWorkflow.Code, UserSetup."User ID");
            ActualWorkflow.Validate(Enabled, true);
            ActualWorkflow.Modify(true);
        until Workflow.Next() = 0;
    end;

    local procedure AddUserForNotifications(WorkflowCode: Code[20]; UserID: Code[50])
    var
        WorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        WorkflowStep.SetRange("Workflow Code", WorkflowCode);
        WorkflowStep.SetRange("Function Name", WorkflowResponseHandling.CreateNotificationEntryCode());
        if WorkflowStep.FindFirst() then
            if WorkflowStepArgument.Get(WorkflowStep.Argument) then begin
                WorkflowStepArgument."Notification User ID" := UserID;
                WorkflowStepArgument.Modify(true);
            end;
    end;

    local procedure CreateWorkflowUserGroupForWorkflow(UserSetup: Record "User Setup"; WorkflowCode: Code[20])
    var
        WorkflowUserGroup: Record "Workflow User Group";
    begin
        WorkflowUserGroup.Code := LibraryUtility.GenerateRandomCode(WorkflowUserGroup.FieldNo(Code), DATABASE::"Workflow User Group");
        WorkflowUserGroup.Description := CopyStr(LibraryUtility.GenerateRandomText(50), 1, 50);
        WorkflowUserGroup.Insert(true);

        LibraryDocumentApprovals.CreateWorkflowUserGroupMember(WorkflowUserGroup.Code, UserSetup."User ID", 1);

        LibraryWorkflow.SetWorkflowGroupApprover(WorkflowCode, WorkflowUserGroup.Code);

        AddUserForNotifications(WorkflowCode, UserSetup."User ID");
    end;

    local procedure HasOpenApprovalEntriesForCurrentUser(RecID: RecordId): Boolean
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        exit(ApprovalsMgmt.HasOpenApprovalEntriesForCurrentUser(RecID));
    end;
}

