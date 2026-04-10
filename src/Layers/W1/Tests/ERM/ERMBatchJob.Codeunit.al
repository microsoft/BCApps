codeunit 134900 "ERM Batch Job"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [ERM]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        isInitialized: Boolean;
        AmountErr: Label 'Amount must be %1.', Comment = '%1=Value';
        ApprovalPendingErr: Label 'Cannot post %1 document no. %2 of type %3 because it is pending approval.';
        ApprovalWorkflowErr: Label 'Cannot post %1 document no. %2 of type %3 due to the approval workflow.';
        SalesHeaderErr: Label 'You cannot delete the order line because it is associated with purchase order';
        ShipToNameErr: Label 'The %1 field on the purchase order %2 must be the same as on sales order %3.', Comment = '%1=Field;%2=Value;%3=Value;';
        DropShipWithShipToAddress2Err: Label 'Sales Order of Drop Shipment with different Ship-To-Address 2 should be carried to seperate orders.';
        SpecOrderWithShipToAddress2Err: Label 'Sales Order of Special order with different Ship-To-Address 2 should be carried to the same orders, because its shipment is grouped by Location Code.';
        SpecOrderWithSameLocationCodeErr: Label 'Sales Order of Special order with the same Location Code should be carried to the same orders.';
        SpecOrderWithDifferentLocationCodeErr: Label 'Sales Order of Special order with different Location Code should be carried to seperate orders.';
        ILEAmounValueErr: Label 'Wrong value "Item Ledger Entry" field %1.', Comment = '%1=Value';
        SelectionRef: Option "All fields","Selected fields";
        UnpaidPrepaymentErr: Label 'There are unpaid prepayment invoices related to the document';
        NoOfPicksCreatedMsg: Label 'Number of Invt. Pick activities created';
        YouCannotChangeErr: Label 'You cannot change Buy-from Vendor No. because the order is associated with one or more sales orders.';
        NotificationMsg: Label 'An error or warning occured during operation Batch processing of %1 records.', Comment = '%1 - table name';
        NotPaidPrepaymentErr: Label 'There are unpaid prepayment invoices related to the document of type Order with the number %1.';
        NotPaidPurchPrepaymentErr: Label 'There are unpaid prepayment invoices that are related to the document of type Order with the number %1.';
        DefaultSalesCategoryCodeLbl: Label 'SALESBCKGR';
        DefaultPurchCategoryCodeLbl: Label 'PURCHBCKGR';

    [Test]
    [Scope('OnPrem')]
    procedure DeleteInvdBlanketSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Delete Documents] [Blanket Order] [Sales]
        // [SCENARIO] Test Batch Report Delete Invalid Blanket Sales Orders.

        // [GIVEN] Create Blanket Sales Order, Make Sales Order from Blanket Order and Post as Ship and Invoice.
        Initialize();
        LibrarySales.SetStockoutWarning(false);
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::"Blanket Order");
        LibrarySales.BlanketSalesOrderMakeOrder(SalesHeader);
        SalesLine.SetRange("Blanket Order No.", SalesLine."Document No.");
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.FindFirst();
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Delete Invalid Sales Blanket Order.
        DeleteSalesBlanketOrder(SalesHeader, SalesLine."Blanket Order No.");

        // [THEN] Verify Invalid Sales Blanket Order deleted.
        Assert.RecordIsEmpty(SalesHeader);
    end;

    [Test]
    [HandlerFunctions('ModalFormHandler')]
    [Scope('OnPrem')]
    procedure DeleteInvoicedSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceSubform: Page "Sales Invoice Subform";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Delete Documents] [Order] [Sales]
        // [SCENARIO] Test whether the "Delete Invoiced Sales Orders" batch job delete Sales Order which is shipped and Invoiced.

        // [GIVEN] Create Sales Order, Post Sales Order as Invoice.
        Initialize();
        LibrarySales.SetStockoutWarning(false);
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        DocumentNo := SalesHeader."No.";
        LibraryVariableStorage.Enqueue(DocumentNo);

        // Create Invoice for Posted Shipment Line.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, SalesHeader."Bill-to Customer No.");
        SalesLine.Validate("Document Type", SalesLine."Document Type"::Invoice);
        SalesLine.Validate("Document No.", SalesHeader."No.");
        SalesLine.Validate("Sell-to Customer No.", SalesHeader."Bill-to Customer No.");
        SalesInvoiceSubform.SetTableView(SalesLine);
        SalesInvoiceSubform.SetRecord(SalesLine);
        SalesInvoiceSubform.GetShipment();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Run Delete Invoiced Sales Order Batch report for above Order, that is already Ship and Invoice.
        DeleteInvoiceSalesOrder(SalesHeader, DocumentNo);

        // [THEN] Verify Invoiced Sales Order deleted.
        Assert.RecordIsEmpty(SalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteInvdBlanketPurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Delete Documents] [Blanket Order] [Purchase]
        // [SCENARIO] Test Batch Report Delete Invalid Blanket Purchase Orders.

        // [GIVEN] Create Blanket Purchase Order, Make Purchase Order from Blanket Order and Post as Receive and Invoice.
        Initialize();
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Blanket Order", LibraryPurchase.CreateVendorNo());
        LibraryPurchase.BlanketPurchaseOrderMakeOrder(PurchaseHeader);
        ModifyPurchaseHeader(PurchaseHeader, PurchaseLine, PurchaseHeader."No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Delete Invalid Purchase Blanket Order.
        DeleteBlanketPurchaseOrder(PurchaseHeader, PurchaseHeader."Document Type", PurchaseLine."Blanket Order No.");

        // [THEN] Verify Invalid Purchase Blanket Order deleted.
        Assert.RecordIsEmpty(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateInvoiceAndReminder()
    var
        ReminderLevel: Record "Reminder Level";
        GenJournalLine: Record "Gen. Journal Line";
        InterestAmount: Decimal;
        TotalDays: Integer;
    begin
        // [FEATURE] [Reminder]
        // [SCENARIO] Run Create Reminders Batch Job and Check Interest Amount after Post Invoice from General Journal Line.

        // [GIVEN] Create Reminder, General Journal Line with Random Amount and Post it. Find Interest Amount.
        Initialize();
        CreateReminderTerms(ReminderLevel);
        CreateAndPostGenJournalLine(
          GenJournalLine, CreateCustomer(ReminderLevel."Reminder Terms Code"), '', LibraryRandom.RandDec(100, 2));
        TotalDays :=
          CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>',
            CalcDate(ReminderLevel."Grace Period", GenJournalLine."Posting Date")) - GenJournalLine."Posting Date";
        InterestAmount := FindInterestAmount(GenJournalLine."Account No.", TotalDays, GenJournalLine.Amount);

        // [WHEN] Create Reminder by Create Reminders Batch Job.
        CreateReminder(GenJournalLine, ReminderLevel."Grace Period");

        // [THEN] Verify Interest Amount on Created Reminder Line after Run batch job.
        VerifyReminderLine(GenJournalLine."Document No.", InterestAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateIssueFinanceChargeMemo()
    var
        FinanceChargeMemoNo: Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [Finance Charge Memo]
        // [SCENARIO] Run Issue Finance Charge Memo Batch Job on Created Finance Charge Memo and Check Amount on that.

        // [GIVEN] Create Finance Charge Memo.
        Initialize();
        Amount := CreateFinanceChargeDocument(FinanceChargeMemoNo);

        // [WHEN] Issue Created Finance Charge Memo.
        IssueFinanceChargeMemo(FinanceChargeMemoNo);

        // [THEN] Verify Amount After issue Finance Charge Memo.
        VerifyIssuedFinanceChargeMemo(FinanceChargeMemoNo, Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateFinanceChargeMemo()
    var
        FinanceChargeMemoLine: Record "Finance Charge Memo Line";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Finance Charge Memo]
        // [SCENARIO] Run Create Finance Charge Memo Batch Job on Posted General Line and Verify it.

        // [GIVEN] Create Customer and General Journal Line and Post it.
        Initialize();
        CreateAndPostGenJnlDocument(GenJournalLine);

        // [WHEN] Run Create Finance Charge Memo batch Job on Posted General Journal Line.
        CreateFinanceCharge(GenJournalLine."Account No.");

        // [THEN] Verify Finance Charge Memo Line after Running Batch Job.
        FinanceChargeMemoLine.Init();
        FinanceChargeMemoLine.SetRange("Document No.", GenJournalLine."Document No.");
        Assert.RecordIsNotEmpty(FinanceChargeMemoLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestFinanceChargeMemo()
    var
        FinanceChargeTerms: Record "Finance Charge Terms";
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Finance Charge Memo] [Suggest]
        // [SCENARIO] Run Suggest Finance Charge Memo Line Batch Job on Posted General Line and Verify it.

        // [GIVEN] Create Customer, General Journal Line and Post it and Create Finance Charge Memo Header.
        Initialize();
        CreateAndPostGenJnlDocument(GenJournalLine);
        LibraryERM.CreateFinanceChargeMemoHeader(FinanceChargeMemoHeader, GenJournalLine."Account No.");
        FinanceChargeMemoHeader.Validate("Document Date", FindFinanceChargeTerms(FinanceChargeTerms, GenJournalLine."Account No."));
        FinanceChargeMemoHeader.Modify(true);

        // [WHEN] Run Suggest Finance Charge Memo batch job on Create Finance Charge Memo Header.
        SuggestFinChargeMemoLine(FinanceChargeMemoHeader."No.");

        // [THEN] Verify Finance Charge Memo Line after Running Suggest Finance Charge Memo Line batch job.
        VerifyFinanceChargeMemoLine(GenJournalLine."Document No.", GenJournalLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyDocumentOnSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
    begin
        // [FEATURE] [Copy Document] [Sales]
        // [SCENARIO] Check Sales Invoice Line when Copy Document has been done from Sales Order.

        // [GIVEN] Set Stock Out Warning False, Create Sales Order and Release it and Create Sales Invoice Header.
        Initialize();
        LibrarySales.SetStockoutWarning(false);
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibrarySales.CreateSalesHeader(SalesHeader2, SalesHeader2."Document Type"::Invoice, SalesHeader."Sell-to Customer No.");

        // [WHEN] Run Copy Sales Document for Created Sales Order on Created Sales Invoice.
        SalesCopyDocument(SalesHeader2, SalesHeader."No.", "Sales Document Type From"::Order);

        // [THEN] Verify Copied Values on Sales Invoice.
        SalesLine2.SetRange("Document Type", SalesHeader2."Document Type");
        SalesLine2.SetRange("Document No.", SalesHeader2."No.");
        SalesLine2.FindFirst();
        SalesLine2.TestField("No.", SalesLine."No.");
        SalesLine2.TestField("Unit Price", SalesLine."Unit Price");

        // Tear Down: Delete Created Sales Invoice.
        SalesHeader2.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyDocumentOnPurchInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine2: Record "Purchase Line";
    begin
        // [FEATURE] [Copy Document] [Purchase]
        // [SCENARIO] Check Purchase Invoice Line when Copy Document has been done from Purchase Order.

        // [GIVEN] Create Purchase Order and Release it and Create Sales Invoice Header.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader2, PurchaseHeader2."Document Type"::Invoice, PurchaseHeader."Buy-from Vendor No.");

        // [WHEN] Run Copy Purchase Document for Created Purchase Order.
        PurchaseCopyDocument(PurchaseHeader2, PurchaseHeader."No.", "Purchase Document Type From"::Order);

        // [THEN] Verify Copied Values on Purchase Invoice.
        PurchaseLine2.SetRange("Document Type", PurchaseHeader2."Document Type");
        PurchaseLine2.SetRange("Document No.", PurchaseHeader2."No.");
        PurchaseLine2.FindFirst();
        PurchaseLine2.TestField("No.", PurchaseLine."No.");
        PurchaseLine2.TestField("Direct Unit Cost", PurchaseLine."Direct Unit Cost");

        // Tear Down: Delete Created Purchase Invoice and Set Default Values for Stock Out Warning.
        PurchaseHeader2.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyDocumentOnSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        NoSeries: Codeunit "No. Series";
        PostedDocumentNo: Code[20];
    begin
        // [FEATURE] [Copy Document] [Sales]
        // [SCENARIO] Check Sales Order Copy Document Error On Release.

        // [GIVEN] Set Stock Out Warning False, Create and Post Sales Invoice, Create Sales Order and Release it.
        Initialize();
        LibrarySales.SetStockoutWarning(false);
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice);
        PostedDocumentNo := NoSeries.PeekNextNo(SalesHeader."Posting No. Series");
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        CreateSalesDocument(SalesHeader2, SalesLine2, SalesHeader2."Document Type"::Order);
        LibrarySales.ReleaseSalesDocument(SalesHeader2);

        // [WHEN] Run Copy Sales Document for Posted Sales Invoice on Sales Order.
        asserterror SalesCopyDocument(SalesHeader2, PostedDocumentNo, "Sales Document Type From"::"Posted Invoice");

        // [THEN] Verify Copy Document Error on Sales Order When Order is Released.
        Assert.ExpectedTestFieldError(SalesHeader.FieldCaption(Status), Format(SalesHeader.Status::Open));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyDocumentOnPurchOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine2: Record "Purchase Line";
        NoSeries: Codeunit "No. Series";
        PostedDocumentNo: Code[20];
    begin
        // [FEATURE] [Copy Document] [Purchase]
        // [SCENARIO] Check Purchase Order Copy Document Error On Release.

        // [GIVEN] Create And Post Purchase Invoice and Create Purchase Order, Release it.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        PostedDocumentNo := NoSeries.PeekNextNo(PurchaseHeader."Posting No. Series");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        CreatePurchaseDocument(PurchaseHeader2, PurchaseLine2, PurchaseHeader2."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader2);

        // [WHEN] Run Copy Purchase Document for Posted Purchase Invoice on Purchase Order.
        asserterror PurchaseCopyDocument(PurchaseHeader2, PostedDocumentNo, "Purchase Document Type From"::"Posted Invoice");

        // [THEN] Verify Copy Document Error on Purchase Order When Order is Released.
        Assert.ExpectedTestFieldError(PurchaseHeader.FieldCaption(Status), Format(PurchaseHeader.Status::Open));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSalesOrdersReport()
    var
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Requisition] [Get Sales Orders]
        // [SCENARIO] Test Requisition Line after running the Get Sales Orders Batch Job.

        // 1. Setup: Create Sales Order with Drop Shipment True on Sales Line.
        Initialize();
        CreateSalesOrderDropShipment(SalesLine);

        // 2. Exercise: Run the Get Sales Orders Batch Job.
        RunGetSalesOrders(SalesLine);

        // 3. Verify: Verify Requisition Line values as Purchase Line values.
        VerifyRequisitionLine(SalesLine);
    end;

    [Test]
    [HandlerFunctions('SourceDocumentsPageHandler')]
    [Scope('OnPrem')]
    procedure GetSourceDocumentsReport()
    var
        PurchaseLine: Record "Purchase Line";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseEmployee: Record "Warehouse Employee";
        GetSourceDocInbound: Codeunit "Get Source Doc. Inbound";
    begin
        // [FEATURE] [SCM] [Warehouse] [Receipt] [Get Source Documents]
        // [SCENARIO] Test Warehouse Receipt Line after running the Get Source Documents Batch Job.

        // 1. Setup: Create Location with Require Receive True, Warehouse Employee for the Location, Purchase Order for same Location and
        // Release it.
        Initialize();
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, CreateLocationRequireReceive(), true);
        CreateAndReleasePurchaseOrder(PurchaseLine, WarehouseEmployee."Location Code");
        LibraryVariableStorage.Enqueue(PurchaseLine."Document No.");

        // 2. Exercise: Create Warehouse Receipt Header and run Get Source Documents.
        CreateWarehouseReceiptHeader(WarehouseReceiptHeader, WarehouseEmployee."Location Code");
        GetSourceDocInbound.GetSingleInboundDoc(WarehouseReceiptHeader);

        // 3. Verify: Verify Warehouse Receipt Line values as Purchase Line values.
        VerifyWarehouseReceiptLine(PurchaseLine, WarehouseReceiptHeader."No.");

        // 4. Tear Down: Set Default False for Warehouse Employee.
        WarehouseEmployee.Validate(Default, false);
        WarehouseEmployee.Modify(true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostSalesOrderReplaceDate()
    var
        Customer: array[2] of Record Customer;
        Item: Record Item;
        SalesHeader: array[2] of Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        PostingDate: Date;
        Index: Integer;
    begin
        // [FEATURE] [Batch Post] [Order] [Sales]
        // [SCENARIO 334500] Create and post two Sales Orders using Batch Post Sales Order and check dates on posted Sales Invoices.

        // 1. Setup: Find Item and Create Customer.
        Initialize();
        LibrarySales.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        LibraryInventory.CreateItem(Item);

        // 2. Exercise: Create Sales Order, release and Post Batch Post Sales.
        for Index := 1 to ArrayLen(SalesHeader) do begin
            LibrarySales.CreateCustomer(Customer[Index]);
            LibrarySales.CreateSalesHeader(SalesHeader[Index], SalesHeader[Index]."Document Type"::Order, Customer[Index]."No.");
            // Use Random Quantity because value is not important.
            LibrarySales.CreateSalesLine(
            SalesLine, SalesHeader[Index], SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));
            LibrarySales.ReleaseSalesDocument(SalesHeader[Index]);
            Commit();
        end;

        PostingDate :=
          CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());  // Use Random because value is not important.
        SalesPostBatch(SalesHeader, PostingDate, true, true);

        for Index := 1 to ArrayLen(SalesHeader) do
            LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader[Index].RecordId);

        // 3. Verify: Verify Sales Invoice have correct Posting Date and Document Date.
        for Index := 1 to ArrayLen(SalesHeader) do begin
            SalesInvoiceHeader.SetRange("Sell-to Customer No.", SalesHeader[Index]."Sell-to Customer No.");
            SalesInvoiceHeader.FindFirst();
            SalesInvoiceHeader.TestField("Posting Date", PostingDate);
            SalesInvoiceHeader.TestField("Document Date", PostingDate);
        end;
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostPurchOrderReceive()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        NoSeries: Codeunit "No. Series";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Batch Post] [Order] [Purchase]
        // [SCENARIO] Check Batch Post Purchase Order Report with Receive TRUE.

        // Setup.
        Initialize();
        LibraryPurchase.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        DocumentNo := NoSeries.PeekNextNo(PurchaseHeader."Receiving No. Series");

        // [WHEN] Run Batch Post Purchase Order with Receive.
        RunBatchPostPurchaseOrders(PurchaseHeader."No.", true, false, 0D, false, false, false);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader.RecordId);

        // [THEN] Verify Purchase Receipt Lines Fields after Run Batch Post Purchase Order Report.
        PurchRcptLine.Get(DocumentNo, PurchaseLine."Line No.");
        PurchRcptLine.TestField(Quantity, PurchaseLine.Quantity);
        PurchRcptLine.TestField("No.", PurchaseLine."No.");
        PurchRcptLine.TestField("Direct Unit Cost", PurchaseLine."Direct Unit Cost");
        PurchRcptLine.TestField("Buy-from Vendor No.", PurchaseLine."Buy-from Vendor No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostPurchOrderInvoice()
    begin
        // [FEATURE] [Batch Post] [Purchase]
        // [SCENARIO] Check Batch Post Purchase Order Report with Blank Posting Date.
        Initialize();
        BatchPostPurchOrderWithDate(0D);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostPurchOrderPostDate()
    begin
        // [FEATURE] [Batch Post] [Order] [Purchase]
        // [SCENARIO] Check Batch Post Purchase Order Report with Work Date.
        Initialize();
        BatchPostPurchOrderWithDate(WorkDate());
    end;

    local procedure BatchPostPurchOrderWithDate(PostingDate: Date)
    var
        PurchInvLine: Record "Purch. Inv. Line";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Batch Post] [Order] [Purchase]
        // Setup.
        DocumentNo := CreateAndGetPurchaseDocumentNo(PurchaseLine, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // [WHEN] Run Batch Post Purchase Order with Receive and Invoice.
        LibraryPurchase.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        RunBatchPostPurchaseOrders(PurchaseLine."Document No.", true, true, PostingDate, false, false, false);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader.RecordId);

        // [THEN] Verify Posted Purchase Invoice Line with Difference Field's Value.
        PurchInvLine.Get(DocumentNo, PurchaseLine."Line No.");
        PurchInvLine.TestField(Quantity, PurchaseLine.Quantity);
        PurchInvLine.TestField("No.", PurchaseLine."No.");
        PurchInvLine.TestField("Direct Unit Cost", PurchaseLine."Direct Unit Cost");
        PurchInvLine.TestField("Buy-from Vendor No.", PurchaseLine."Buy-from Vendor No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostPurchOrderRepPostDate()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseHeader: array[2] of Record "Purchase Header";
        PostingDate: Date;
        Index: Integer;
    begin
        // [FEATURE] [Batch Post] [Order] [Replace Posting Date] [Purchase]
        // [SCENARIO] Check Batch Post Purchase Order Report with Replace Posting Date Option.

        // Create Purchase Order and Run Batch Post Purchase Order Report with Replace Posting Date TRUE.
        Initialize();
        PostingDate := LibraryRandom.RandDate(5) + 1;
        SetupBatchPostPurchaseOrders(PurchaseHeader, PostingDate, true, false);

        // [THEN] Verify Posting Date on Posted Purchase Invoice Header.
        for Index := 1 to ArrayLen(PurchaseHeader) do begin
            PurchInvHeader.SetRange("Buy-from Vendor No.", PurchaseHeader[Index]."Buy-from Vendor No.");
            PurchInvHeader.FindFirst();
            PurchInvHeader.TestField("Posting Date", PostingDate);
            PurchInvHeader.TestField("Document Date", WorkDate());
        end;
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostPurchOrdeRepDocDate()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseHeader: array[2] of Record "Purchase Header";
        PostingDate: Date;
        Index: Integer;
    begin
        // [FEATURE] [Batch Post] [Order] [Replace Posting Date] [Purchase]
        // [SCENARIO] Check Batch Post Purchase Order Report with Replace Document Date Option.

        // Create Purchase Order and Run Batch Post Purchase Order Report with Replace Document Date TRUE.
        Initialize();
        PostingDate := LibraryRandom.RandDate(5) + 1;
        SetupBatchPostPurchaseOrders(PurchaseHeader, PostingDate, false, true);

        // [THEN] Verify Document Date on Posted Purchase Invoice Header.
        for Index := 1 to ArrayLen(PurchaseHeader) do begin
            PurchInvHeader.SetRange("Buy-from Vendor No.", PurchaseHeader[Index]."Buy-from Vendor No.");
            PurchInvHeader.FindFirst();
            PurchInvHeader.TestField("Posting Date", WorkDate());
            PurchInvHeader.TestField("Document Date", PostingDate);
        end;
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostPurchOrderInvDisc()
    var
        PurchaseLine: Record "Purchase Line";
        PurchInvLine: Record "Purch. Inv. Line";
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
        PurchaseHeader: Record "Purchase Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        DocumentNo: Code[20];
        InvDiscountAmount: Decimal;
    begin
        // [FEATURE] [Batch Post] [Order] [Invoice Discount] [Purchase]
        // [SCENARIO] Check Batch Post Purchase Order Report with Invoice Discount Option.

        // [GIVEN] Create and Post Purchase Order with Invoice Discount Option.
        Initialize();
        LibraryPurchase.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        SetupInvoiceDiscount(VendorInvoiceDisc);
        DocumentNo := CreateAndGetPurchaseDocumentNo(PurchaseLine, VendorInvoiceDisc.Code);
        InvDiscountAmount := Round(PurchaseLine."Line Amount" * VendorInvoiceDisc."Discount %" / 100);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // [WHEN] Run Batch Post Purchase Order with Receive, Invoice and Invoice Discount.
        RunBatchPostPurchaseOrders(PurchaseLine."Document No.", true, true, WorkDate(), false, false, true);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader.RecordId);

        // [THEN] Verify Invoice Discount on Posted Purchase Invoice Line.
        PurchInvLine.Get(DocumentNo, PurchaseLine."Line No.");
        PurchInvLine.TestField("Inv. Discount Amount", InvDiscountAmount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,DateCompressGenLedgerHandler,DimensionSelectionHandler')]
    [Scope('OnPrem')]
    procedure DateCompressGeneralLedgerBatch()
    var
        GLRegister: Record "G/L Register";
        GLEntry: Record "G/L Entry";
        JournalBatchName: Code[10];
    begin
        // [FEATURE] [Date Compress] [General Ledger]
        // [SCENARIO] Test and verify Date Compress General Ledger Report functionality.

        // 1. Setup: Create and Post General Journal Lines.
        Initialize();
        JournalBatchName := CreateAndPostGenJournalLines();

        // 2. Exercise: Find G/L Register. Run Date Compress General Ledger Report.
        FindGLRegister(GLRegister, JournalBatchName);
        REPORT.Run(REPORT::"Date Compress General Ledger");

        // 3. Verify: G/L Entry must be deleted after running the Date Compress General Ledger Report.
        GLEntry.Init();
        GLEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        Assert.RecordIsEmpty(GLEntry);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,DateCompressGenLedgerHandler,DimensionSelectionHandler')]
    [Scope('OnPrem')]
    procedure DeleteEmptyGLRegistersBatch()
    var
        GLRegister: Record "G/L Register";
        JournalBatchName: Code[10];
    begin
        // [FEATURE] [G/L Register]
        // [SCENARIO] Test and verify Delete Empty G/L Registers Report functionality.

        // 1. Setup: Create and Post General Journal Lines. Run Date Compress General Ledger Report.
        Initialize();
        JournalBatchName := CreateAndPostGenJournalLines();
        REPORT.Run(REPORT::"Date Compress General Ledger");

        // 2. Exercise: Run Delete Empty G/L Registers Report.
        RunDeleteEmptyGLRegisters();

        // 3. Verify: G/L Register must be deleted after running the Delete Empty G/L Registers Report.
        GLRegister.Init();
        GLRegister.SetRange("Journal Batch Name", JournalBatchName);
        Assert.RecordIsEmpty(GLRegister);
    end;

    [Test]
    [HandlerFunctions('CopyGeneralPostingSetupHandlerWithQueue,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure CopyGeneralPostingSetupWithAllFields()
    var
        GeneralPostingSetupDestination: Record "General Posting Setup";
        GeneralPostingSetupSource: Record "General Posting Setup";
    begin
        // [FEATURE] [Copy General Posting Setup]
        // [SCENARIO 362396] Test and verify functionality of Copy General Posting Setup with copy Option as All fields.

        // [GIVEN] Filled General Posting Setup.
        Initialize();
        CreateGeneralPostingSetup(GeneralPostingSetupSource);
        LibraryERM.SetGeneralPostingSetupPrepAccounts(GeneralPostingSetupSource);
        FillGenPostingSetup(GeneralPostingSetupSource);

        // [GIVEN] Empty General Posting Setup.
        CreateGeneralPostingSetup(GeneralPostingSetupDestination);

        // [WHEN] Run Copy General Posting Setup.
        LibraryVariableStorage.Enqueue(GeneralPostingSetupSource."Gen. Bus. Posting Group");
        LibraryVariableStorage.Enqueue(GeneralPostingSetupSource."Gen. Prod. Posting Group");
        RunCopyGeneralPostingSetup(GeneralPostingSetupDestination);

        // [THEN] Following Setup fields are copied: "Sales Pmt. Tol. Debit Acc.","Sales Pmt. Tol. Credit Acc.",
        // "Purch. Pmt. Tol. Debit Acc.","Purch. Pmt. Tol. Credit Acc.","Sales Prepayments Account",
        // "Purch. Prepayments Account"
        VerifyValuesOnGenPostingSetupAllFields(
              GeneralPostingSetupDestination, GeneralPostingSetupSource."Sales Account", GeneralPostingSetupSource."Sales Pmt. Tol. Debit Acc.", GeneralPostingSetupSource."Sales Pmt. Tol. Credit Acc.",
              GeneralPostingSetupSource."Purch. Pmt. Tol. Debit Acc.", GeneralPostingSetupSource."Purch. Pmt. Tol. Credit Acc.", GeneralPostingSetupSource."Sales Prepayments Account",
              GeneralPostingSetupSource."Purch. Prepayments Account");
    end;

    [Test]
    [HandlerFunctions('CopyGeneralPostingSetupHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure CopyGeneralPostingSetupWithSelectedFields()
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        // [FEATURE] [Copy General Posting Setup]
        // [SCENARIO] Test and verify functionality of Copy General Posting Setup with copy Option as Selected fields.

        // 1. Setup: Create General Posting Setup.
        Initialize();
        CreateGeneralPostingSetup(GeneralPostingSetup);

        // 2. Exercise: Run Copy General Posting Setup with global variables for CopyGeneralPostingSetupHandler.
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(false);
        RunCopyGeneralPostingSetup(GeneralPostingSetup);

        // 3. Verify: Verify that the Setup is correctly copied.
        VerifyValuesOnGenPostingSetupSelectedFields(GeneralPostingSetup, '', '', '');
    end;

    [Test]
    [HandlerFunctions('CopyVATPostingSetupHandlerWithQueue,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure CopyVATPostingSetupWithAllFields()
    var
        VATPostingSetupDestination: Record "VAT Posting Setup";
        VATPostingSetupSource: Record "VAT Posting Setup";
    begin
        // [FEATURE] [Copy VAT Posting Setup]
        // [SCENARIO 362396] Test and verify functionality of Copy VAT Posting Setup with copy Option as All fields.

        // [GIVEN] VAT Posting Setup with "VAT Identifier" = 'Z'
        Initialize();
        CreateVATPostingSetup(VATPostingSetupSource);
        CreateVATPostingSetup(VATPostingSetupDestination);
        UpdateVATIdentifierForVATpostingSetup(VATPostingSetupSource);

        // [WHEN] Run Copy VAT Posting Setup
        LibraryVariableStorage.Enqueue(VATPostingSetupSource."VAT Bus. Posting Group");
        LibraryVariableStorage.Enqueue(VATPostingSetupSource."VAT Prod. Posting Group");
        RunCopyVATPostingSetup(VATPostingSetupDestination);

        // [THEN] New VAT Posting Setup contains "VAT Identifier" = 'Z'
        VerifyValuesOnVATPostingSetup(VATPostingSetupDestination, VATPostingSetupSource."VAT Identifier");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReminderWithAmountRoundingPrecisionOnCurrency()
    var
        ReminderLevel: Record "Reminder Level";
        GenJournalLine: Record "Gen. Journal Line";
        Currency: Record Currency;
        IssuedReminderHeader: Record "Issued Reminder Header";
    begin
        // [FEATURE] [Reminder]
        // [SCENARIO] Validate "Amount Rounding Precision" on Currency of Issued Reminder after create Reminder with Currency.

        // [GIVEN] Find and Update Currency, Create and post General Journal Line, Create Reminder.
        Initialize();
        FindAndUpdateCurrency(Currency);
        CreateReminderTerms(ReminderLevel);
        CreateAndPostGenJournalLine(
          GenJournalLine, CreateCustomer(ReminderLevel."Reminder Terms Code"), Currency.Code, LibraryRandom.RandDec(100, 2));
        CreateReminder(GenJournalLine, ReminderLevel."Grace Period");

        // [WHEN] Issue Reminder.
        IssueReminder(GenJournalLine."Account No.");

        // [THEN] Verify Amount Rounding Precision on Currency of Issued Reminder.
        FindIssuedReminder(IssuedReminderHeader, GenJournalLine."Account No.");
        VerifyCurrencyOnIssuedReminder(IssuedReminderHeader."Currency Code", Currency."Amount Rounding Precision");
    end;

    [Test]
    [HandlerFunctions('BatchPostSalesOrderRequestPageHandler,SentNotificationHandler')]
    [Scope('OnPrem')]
    procedure RunSalesBatchJob()
    var
        LineGLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        ErrorMessagesPage: TestPage "Error Messages";
        SalesHeaderNo: Code[20];
        OrderCounter: Integer;
    begin
        // [FEATURE] [Batch Post] [Order] [Sales]
        // [SCENARIO] Verify Message Populated after running Batch Sales Order.

        // [GIVEN] Create and Post Sales Orders.
        Initialize();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        SetCheckPrepmtWhenPostingSales(true);
        LibrarySales.CreatePrepaymentVATSetup(LineGLAccount, "Tax Calculation Type"::"Normal VAT");
        for OrderCounter := 1 to LibraryRandom.RandIntInRange(2, 5) do
            SalesHeaderNo := CreateAndPostSalesOrderWithPrepayment(LineGLAccount);

        // [WHEN] Post Sales Batch.
        ErrorMessagesPage.Trap();
        RunPostBatchSalesOrder(SalesHeaderNo);

        // [THEN] Notification: 'An error occured during operation: batch processing of Sales Header records.'
        Assert.ExpectedMessage(
          StrSubstNo(NotificationMsg, SalesHeader.TableCaption()), LibraryVariableStorage.DequeueText()); // from SentNotificationHandler
        LibraryVariableStorage.AssertEmpty();
        Clear(SalesHeader);
        LibraryNotificationMgt.RecallNotificationsForRecord(SalesHeader);
        // [THEN] On "Details" action - Error Messages page is open, where Description is 'NotPaidPrepaymentErr'
        ErrorMessagesPage.Description.AssertEquals(StrSubstNo(NotPaidPrepaymentErr, SalesHeaderNo));

        // TearDown.
        RemovePrepmtVATSetup(LineGLAccount);
    end;

    [Test]
    [HandlerFunctions('SentNotificationHandler')]
    [Scope('OnPrem')]
    procedure RunPurchaseBatchJob()
    var
        LineGLAccount: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        ErrorMessagesPage: TestPage "Error Messages";
        PurchaseHeaderNo: Code[20];
        OrderCounter: Integer;
    begin
        // [FEATURE] [Batch Post] [Order] [Purchase]
        // [GIVEN] Create and Post Purchase Orders.
        Initialize();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        SetCheckPrepmtWhenPostingPurchase(true);
        LibraryPurchase.CreatePrepaymentVATSetup(LineGLAccount, "Tax Calculation Type"::"Normal VAT");
        for OrderCounter := 1 to LibraryRandom.RandIntInRange(2, 5) do
            PurchaseHeaderNo := CreateAndPostPurchaseOrderWithPrepayment(LineGLAccount);

        // [WHEN] Post Purchase Batch.
        ErrorMessagesPage.Trap();
        RunBatchPostPurchaseOrders(PurchaseHeaderNo, true, true, WorkDate(), false, false, false);

        // [THEN] Notification: 'An error occured during operation: batch processing of Purchase Header records.'
        Assert.ExpectedMessage(
          StrSubstNo(NotificationMsg, PurchaseHeader.TableCaption()), LibraryVariableStorage.DequeueText()); // from SentNotificationHandler
        LibraryVariableStorage.AssertEmpty();
        Clear(PurchaseHeader);
        LibraryNotificationMgt.RecallNotificationsForRecord(PurchaseHeader);
        // [THEN] On "Details" action - Error Messages page is open, where Description is 'NotPaidPrepaymentErr'
        ErrorMessagesPage.Description.AssertEquals(StrSubstNo(NotPaidPurchPrepaymentErr, PurchaseHeaderNo));

        // TearDown.
        RemovePrepmtVATSetup(LineGLAccount);
    end;

    [Test]
    [HandlerFunctions('SalesListPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseLineWithSalesPurchasingCode()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeaderNo: Code[20];
    begin
        // [FEATURE] [Special Order] [Purchase]
        // [SCENARIO] Verify Purchase Line exist with Purchasing Code and Special Order After Get Special Orders.

        // [GIVEN] Create and Update Sales Order with Purchasing Code.
        Initialize();
        CreateAndUpdatePurchasingCodeOnSalesDocument(SalesHeader, SalesLine);

        // [WHEN] Create Purchase Order.Update Sell to Customer on Purchase Header and Get Sales Order for Special Order For Sales Order.
        PurchaseHeaderNo := CreatePurchaseOrderAndGetSpecialOrder(SalesHeader."Sell-to Customer No.");

        // [THEN] Verify Purchasing Code and Spacial Order on Purchase Line same as Sales line.
        VerifyPurchasingCodeAndSpecialOrderOnPurchaseLine(SalesLine, PurchaseHeaderNo);
    end;

    [Test]
    [HandlerFunctions('SalesListPageHandler,GetShipmentLinesPageHandler')]
    [Scope('OnPrem')]
    procedure DeleteSalesOrderAfterGetShipmentLines()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales] [Shipment] [Get Shipment Lines] [Special Order]
        // [SCENARIO 381247] Stan can delete fully shipped Sales Order tied with Special Order when it is fully Invoiced by another document
        // [GIVEN] Sales order "SO" marked as "Special Order" and linked to purchase order "PO"
        // [GIVEN] "PO" partially received and not invoiced
        // [GIVEN] "SO" shipped fully
        // [GIVEN] Sales invoice "SI" created from shipped "SO" using "Get Shipment Lines"
        // [GIVEN] "SI" fully invoiced
        // [WHEN] Delete "SO"
        // [THEN] Error thrown "You cannot delete the order line because it is associated with purchase order"
        Initialize();
        CreateAndUpdatePurchasingCodeOnSalesDocument(SalesHeader, SalesLine);
        CreatePurchaseOrderAndGetSpecialOrder(SalesHeader."Sell-to Customer No.");
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        CreateAndPostSalesInvoiceUsingGetShipmentLines(SalesHeader."Sell-to Customer No.");

        asserterror SalesHeader.Delete(true);

        Assert.ExpectedError(SalesHeaderErr);
    end;

    [Test]
    [HandlerFunctions('SalesListPageHandler,GetShipmentLinesPageHandler,DeleteInvoicedSalesOrdersHandler')]
    [Scope('OnPrem')]
    procedure DeletePurchaseOrderAfterRunningDeleteInvoicedSalesOrders()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderNo: Code[20];
    begin
        // [FEATURE] [Get Shipment Lines] [Special Order] [Sales]
        // [SCENARIO] Purchase Order can be deleted after running Delete Invoiced Sales Orders Report.

        // [GIVEN] Create Purchase Order and Sales Invoice With Get Shipment Lines.
        Initialize();
        CreateAndUpdatePurchasingCodeOnSalesDocument(SalesHeader, SalesLine);
        PurchaseHeaderNo := CreatePurchaseOrderAndGetSpecialOrder(SalesHeader."Sell-to Customer No.");
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        CreateAndPostSalesInvoiceUsingGetShipmentLines(SalesHeader."Sell-to Customer No.");
        RunDeleteInvoicedSalesOrdersReport(SalesHeader."Document Type", SalesHeader."No.");

        // [WHEN] Delete Purchase Order after running Delete Invoiced Sales Orders report.
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, PurchaseHeaderNo);
        PurchaseHeader.Delete(true);

        // [THEN] Verify Purchase Order deleted.
        asserterror PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, PurchaseHeaderNo);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,BatchPostSalesReturnOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure SalesRetOrdWithBatchPostAsReceive()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReturnReceiptLine: Record "Return Receipt Line";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        // [FEATURE] [Batch Post] [Return Order] [Sales]
        // [SCENARIO] Verify Posted Sales Return Order using Batch Post as Receive.

        // [GIVEN] Create Sales Return Order.
        Initialize();
        LibrarySales.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order");

        // [WHEN] Post Sales Return Order with Batch Post as Receive.
        RunBatchPostSalesReturnOrdersReport(SalesHeader."No.", true, false);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader.RecordId);

        // [THEN] Verify Return Receipt Line.
        ReturnReceiptLine.SetRange("Return Order No.", SalesHeader."No.");
        ReturnReceiptLine.FindFirst();
        ReturnReceiptLine.TestField("No.", SalesLine."No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,BatchPostSalesReturnOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure SalesRetOrdWithBatchPostAsReceiveAndInv()
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        // [FEATURE] [Batch Post] [Return Order] [Sales]
        // [SCENARIO] Verify Posted Sales Return Order using Batch Post as Receive and Invoice.

        // [GIVEN] Create Sales Return Order.
        Initialize();
        LibrarySales.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order");

        // [WHEN] Post Sales Return Order with Batch Post as Receive and Invoice.
        RunBatchPostSalesReturnOrdersReport(SalesHeader."No.", true, true);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader.RecordId);

        // [THEN] Verify Sales Credit Memo Line.
        SalesCrMemoLine.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesCrMemoLine.FindFirst();
        SalesCrMemoLine.TestField("No.", SalesLine."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReqWkshGetSalesOrderAndCarryOutActionMsg()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine1: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchHeader1: Record "Purchase Header";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        Location: Record Location;
    begin
        // [FEATURE] [Special Order] [Drop Shipment] [Carry Out] [Purchase]
        // [GIVEN] Create Sales Order with Special Order Line And Drop Shipment Line.
        Initialize();
        CreateSalesOrderWithSpecialOrderAndDropShipment(SalesHeader);
        UpdateShipToAddressOnSalesHeader(SalesHeader);
        CreateReqWkshTemplateName(RequisitionWkshName, ReqWkshTemplate);

        // [WHEN] Run Carry Out Action Msg. - Req. batch job.
        // Special order and drop shipment lines should be carried to seperate orders.
        SelectSalesLineWithSpecialOrder(SalesLine, SalesHeader);
        GetSpecialOrderOnReqWksht(SalesLine, RequisitionLine, RequisitionWkshName.Name, ReqWkshTemplate.Name);
        SelectSalesLineWithDropShipment(SalesLine1, SalesHeader);
        GetDropShipmentOnReqWksht(SalesLine1, RequisitionLine, RequisitionWkshName.Name, ReqWkshTemplate.Name);
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, WorkDate(), WorkDate(), WorkDate(), WorkDate(), '');

        // [THEN] Verify Purchasing Code, Ship-to Name, Ship-to Address, Ship-to Phone No. on 1st Purchase Order.
        GetPurchHeader(PurchHeader, SalesLine."No.");
        VerifyPurchasingCodeAndSpecialOrderOnPurchaseLine(SalesLine, PurchHeader."No.");
        Location.Get(SalesHeader."Location Code");
        VerifyPurchShippingDetails(PurchHeader, Location.Name, Location.Address);
        VerifyPurchShippingContactDetails(PurchHeader, Location."Phone No.");

        // [THEN] Verify Purchasing Code, Ship-to Name, Ship-to Address and Ship-to Phone No. on 2nd Purchase Order.
        GetPurchHeader(PurchHeader1, SalesLine1."No.");
        VerifyPurchasingCodeAndDropShipmentOnPurchLine(SalesLine1, PurchHeader1."No.");
        VerifyPurchShippingDetails(PurchHeader1, SalesHeader."Ship-to Name", SalesHeader."Ship-to Address");
        VerifyPurchShippingContactDetails(PurchHeader1, SalesHeader."Ship-to Phone No.");
    end;

    [Test]
    [HandlerFunctions('SalesListPageHandler')]
    [Scope('OnPrem')]
    procedure PurchOrderRunGetSpecialOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        Location: Record Location;
        DistIntegration: Codeunit "Dist. Integration";
    begin
        // [FEATURE] [Special Order] [Drop Shipment] [Sales]
        // [GIVEN] Create Sales Order with Special Order Line And Drop Shipment Line.
        Initialize();
        CreateSalesOrderWithSpecialOrderAndDropShipment(SalesHeader);

        // [WHEN] Create Purchase Order. Get Special Order then Get Drop Shipment.
        CreatePurchHeader(PurchHeader, SalesHeader."Sell-to Customer No.", '');
        DistIntegration.GetSpecialOrders(PurchHeader);
        Commit();
        asserterror LibraryPurchase.GetDropShipment(PurchHeader);

        // [THEN] Verify Error message.
        Assert.ExpectedError(StrSubstNo(ShipToNameErr, PurchHeader.FieldCaption("Ship-to Name"), PurchHeader."No.", SalesHeader."No."));

        // [THEN] Verify Purchasing Code, Ship-to Name, Ship-to Address and Ship-to Phone on Purchase Order with Special Order.
        SelectSalesLineWithSpecialOrder(SalesLine, SalesHeader);
        VerifyPurchasingCodeAndSpecialOrderOnPurchaseLine(SalesLine, PurchHeader."No.");
        Location.Get(SalesHeader."Location Code");
        VerifyPurchShippingDetails(PurchHeader, Location.Name, Location.Address);
        VerifyPurchShippingContactDetails(PurchHeader, Location."Phone No.");
    end;

    [Test]
    [HandlerFunctions('SalesListPageHandler')]
    [Scope('OnPrem')]
    procedure PurchOrderRunGetDropShipment()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        DistIntegration: Codeunit "Dist. Integration";
    begin
        // [FEATURE] [Special Order] [Drop Shipment] [Purchase]
        // [GIVEN] Create Sales Order with Special Order Line And Drop Shipment Line.
        Initialize();
        CreateSalesOrderWithSpecialOrderAndDropShipment(SalesHeader);
        UpdateShipToAddressOnSalesHeader(SalesHeader);

        // [WHEN] Create Purchase Order. Get Drop Shipment then Get Special Order.
        CreatePurchHeader(PurchHeader, SalesHeader."Sell-to Customer No.", '');
        LibraryPurchase.GetDropShipment(PurchHeader);
        Commit();
        asserterror DistIntegration.GetSpecialOrders(PurchHeader);

        // [THEN] Verify Error Message.
        Assert.ExpectedError(StrSubstNo(ShipToNameErr, PurchHeader.FieldCaption("Ship-to Name"), PurchHeader."No.", SalesHeader."No."));

        // [THEN] Verify Purchasing Code, Ship-to Name, Ship-to Address and Ship-to Phone on Purchase Order with Drop Shipment.
        SelectSalesLineWithDropShipment(SalesLine, SalesHeader);
        VerifyPurchasingCodeAndDropShipmentOnPurchLine(SalesLine, PurchHeader."No.");
        VerifyPurchShippingDetails(PurchHeader, SalesHeader."Ship-to Name", SalesHeader."Ship-to Address");
        VerifyPurchShippingContactDetails(PurchHeader, SalesHeader."Ship-to Phone No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReqWkshGetDropShipWithMultipleAddressAndCarryOutActionMsg()
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchHeader2: Record "Purchase Header";
    begin
        // [FEATURE] [Drop Shipment] [Carry Out] [Purchase]
        // [GIVEN] Create two Sales Orders of Drop Shipment with Multiple Address..
        Initialize();
        GeneralSetupForReqwkshGetSalesOrder(SalesHeader, SalesHeader2, SalesLine, SalesLine2, false); // FALSE for Drop Shipment
        ModifySalesHeaderWithMultipleAddress(SalesHeader2); // Set up value in Ship-To-Address 2

        // [WHEN] Run Carry Out Action Msg. - Req. batch job.
        CarryOutActionMsgOnReqWkshForDropShipmentBatch(SalesHeader, SalesHeader2, SalesLine, SalesLine2);

        // [THEN] Verify two Purchase Orders have been created.
        // Drop Shipment lines with different Ship-To-Address 2 should be carried to seperate orders.
        GetPurchHeader(PurchHeader, SalesLine."No.");
        GetPurchHeader(PurchHeader2, SalesLine2."No.");
        Assert.AreNotEqual(PurchHeader."No.", PurchHeader2."No.", DropShipWithShipToAddress2Err);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReqWkshGetSpecOrderWithMultipleAddressAndCarryOutActionMsg()
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchHeader2: Record "Purchase Header";
    begin
        // [FEATURE] [Special Order] [Carry Out] [Purchase]
        // [GIVEN] Create two Sales Orders of Special Order with Multiple Address.
        Initialize();
        GeneralSetupForReqwkshGetSalesOrder(SalesHeader, SalesHeader2, SalesLine, SalesLine2, true); // TRUE for Special Order
        ModifySalesHeaderWithMultipleAddress(SalesHeader2);  // Set up value in Ship-To-Address 2

        // [WHEN] Run Carry Out Action Msg. - Req. batch job.
        CarryOutActionMsgOnReqWkshForSpecialOrder(SalesHeader, SalesHeader2, SalesLine, SalesLine2);

        // [THEN] Verify one Purchase Order have been created.
        // Special order lines with different Ship-To-Address 2 should be carried to the same orders, because its shipment is grouped by Location Code.
        GetPurchHeader(PurchHeader, SalesLine."No.");
        GetPurchHeader(PurchHeader2, SalesLine2."No.");
        Assert.AreEqual(PurchHeader."No.", PurchHeader2."No.", SpecOrderWithShipToAddress2Err);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReqWkshGetSpecOrderAndCarryOutActionMsg()
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchHeader2: Record "Purchase Header";
    begin
        // [FEATURE] [Special Order] [Carry Out] [Purchase]
        // [GIVEN] Create two Sales Orders of Special Order with same Location Code.
        Initialize();
        GeneralSetupForReqwkshGetSalesOrder(SalesHeader, SalesHeader2, SalesLine, SalesLine2, true); // TRUE for Special Order

        // [WHEN] Run Carry Out Action Msg. - Req. batch job.
        CarryOutActionMsgOnReqWkshForSpecialOrder(SalesHeader, SalesHeader2, SalesLine, SalesLine2);

        // [THEN] Verify one Purchase Order have been created.
        // Special order lines with same Location Code should be carried to the same orders.
        GetPurchHeader(PurchHeader, SalesLine."No.");
        GetPurchHeader(PurchHeader2, SalesLine2."No.");
        Assert.AreEqual(PurchHeader."No.", PurchHeader2."No.", SpecOrderWithSameLocationCodeErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ReqWkshGetSpecOrderWithDifferentLocationAndCarryOutActionMsg()
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchHeader2: Record "Purchase Header";
    begin
        // [FEATURE] [Special Order] [Carry Out] [Purchase]
        // [GIVEN] Create two Sales Orders of Special Order  with different Location Code.
        Initialize();
        GeneralSetupForReqwkshGetSalesOrder(SalesHeader, SalesHeader2, SalesLine, SalesLine2, true); // TRUE for Special Order
        ModifySalesOrderWithLocationCode(SalesHeader2, SalesLine2); // set up Location Code of null.

        // [WHEN] Run Carry Out Action Msg. - Req. batch job.
        CarryOutActionMsgOnReqWkshForSpecialOrder(SalesHeader, SalesHeader2, SalesLine, SalesLine2);

        // [THEN] Verify two Purchase Orders have been created.
        // Special order lines with different Location Code should be carried to seperate orders.
        GetPurchHeader(PurchHeader, SalesLine."No.");
        GetPurchHeader(PurchHeader2, SalesLine2."No.");
        Assert.AreNotEqual(PurchHeader."No.", PurchHeader2."No.", SpecOrderWithDifferentLocationCodeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReqWkshGetDropShipWithCustomAddressAndCarryOutActionMsg()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Drop Shipment] [Carry Out] [Purchase]
        // [SCENARIO 258017] Address fields are copied to Purchase Order from drop shipment sales with custom address
        Initialize();

        // [GIVEN] Sales Order of Drop Shipment
        CreateSalesOrderWithPurchasingCode(
          SalesHeader, SalesLine, LibrarySales.CreateCustomerNo(), CreatePurchasingCodeWithDropShipment(), LibraryPurchase.CreateVendorNo());

        // [GIVEN] 'Ship-to' fields updated on Sales Order:
        // [GIVEN] Address, Address 2, Post Code, City, Contact, County, Country/Region and Phone No.
        UpdateShipToAddressOnSalesHeader(SalesHeader);

        // [WHEN] Run Carry Out Action Msg. - Req. batch job.
        CarryOutActionMsgOnReqWkshForDropShipment(SalesHeader, SalesLine);

        // [THEN] Purchase Order created with 'Ship-to' fields matching to values from Sales Order
        GetPurchHeader(PurchaseHeader, SalesLine."No.");
        VerifyPurchHeaderAddress(PurchaseHeader, SalesHeader);
    end;

    [Test]
    [HandlerFunctions('SalesListPageHandler')]
    [Scope('OnPrem')]
    procedure DropShipmentWithShipToCodeAndSalesOrderPost()
    var
        SalesHeader: Record "Sales Header";
        PurchHeader: Record "Purchase Header";
        ItemNo: Code[20];
        CountryCode: Code[10];
    begin
        // [FEATURE] [Drop Shipment] [Sales]
        Initialize();

        CreateSalesAndPurchOrdersWithDropShipmentAndCountryCode(SalesHeader, PurchHeader, ItemNo, CountryCode);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        VerifyShipmentItemLedgerEntry(ItemNo, CountryCode);
    end;

    [Test]
    [HandlerFunctions('SalesListPageHandler')]
    [Scope('OnPrem')]
    procedure DropShipmentWithShipToCodeAndPurchOrderPost()
    var
        SalesHeader: Record "Sales Header";
        PurchHeader: Record "Purchase Header";
        ItemNo: Code[20];
        CountryCode: Code[10];
    begin
        // [FEATURE] [Drop Shipment] [Purchase]
        Initialize();

        CreateSalesAndPurchOrdersWithDropShipmentAndCountryCode(SalesHeader, PurchHeader, ItemNo, CountryCode);
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, false);

        VerifyShipmentItemLedgerEntry(ItemNo, CountryCode);
    end;

    [Test]
    [HandlerFunctions('GetShipmentLinesPageHandler,DeleteInvoicedSalesOrdersHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure DeleteAssemblyOrderAutomaticallyAfterRunningDeleteInvoicedSalesOrders()
    var
        AssemblyItem: Record Item;
        SalesHeader: Record "Sales Header";
        AssemblyHeader: Record "Assembly Header";
        AssemblyHeaderNo: Code[20];
    begin
        // [FEATURE] [Delete Documents] [Order] [Sales]
        // [SCENARIO] Verify Assembly Order can be deleted automatically after running Delete Invoiced Sales Orders Report.

        // [GIVEN] Create Assembly ATO Item with component. Create and post Sales Order as ship.
        // Create and post Sales Invoice by Get Shipment Lines.
        Initialize();
        CreateAssemblyItemWithComponent(
          AssemblyItem, AssemblyItem."Assembly Policy"::"Assemble-to-Order", LibraryRandom.RandInt(5));
        AssemblyHeaderNo := CreateAndPostSalesOrder(SalesHeader, AssemblyItem."No.", true, false);
        CreateAndPostSalesInvoiceUsingGetShipmentLines(SalesHeader."Sell-to Customer No.");

        // [WHEN] Run report Delete Invoiced Sales Orders.
        RunDeleteInvoicedSalesOrdersReport(SalesHeader."Document Type", SalesHeader."No.");

        // [THEN] Verify Assembly Order is deleted.
        AssemblyHeader.SetRange("Document Type", AssemblyHeader."Document Type"::Order);
        AssemblyHeader.SetRange("No.", AssemblyHeaderNo);
        Assert.RecordIsEmpty(AssemblyHeader);
    end;

    [Test]
    [HandlerFunctions('SalesListPageHandler')]
    [Scope('OnPrem')]
    procedure DropShipmentPurchOrderPartialPost()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        ItemNo: Code[20];
        CountryCode: Code[10];
        QtyToReceive: Decimal;
        ExpAmount: Decimal;
    begin
        // [FEATURE] [Drop Shipment] [Purchase]
        // [SCENARIO] Verify ILE amount after partial posting Purchase Order in case of Drop Shipment
        Initialize();

        CreateSalesAndPurchOrdersWithDropShipmentAndCountryCode(SalesHeader, PurchHeader, ItemNo, CountryCode);

        SelectSalesLineWithDropShipment(SalesLine, SalesHeader);
        QtyToReceive := LibraryRandom.RandDec(SalesLine.Quantity div 1, 2);
        UpdatePurchLineQtyToReceive(PurchHeader."No.", QtyToReceive);

        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, false);

        ExpAmount := Round(SalesLine.Amount * QtyToReceive / SalesLine.Quantity);
        VerifyPartialDropShipmentSalesILE(ItemNo, ExpAmount);
    end;

    [Test]
    [HandlerFunctions('SalesListPageHandler')]
    [Scope('OnPrem')]
    procedure DropShipmentSalesOrderPartialPost()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ItemNo: Code[20];
        CountryCode: Code[10];
        QtyToShip: Decimal;
        ExpAmount: Decimal;
    begin
        // [FEATURE] [Drop Shipment] [Purchase]
        // [SCENARIO] Verify ILE amount after partial posting Sales Order in case of Drop Shipment
        Initialize();

        CreateSalesAndPurchOrdersWithDropShipmentAndCountryCode(SalesHeader, PurchHeader, ItemNo, CountryCode);

        SelectSalesLineWithDropShipment(SalesLine, SalesHeader);
        QtyToShip := LibraryRandom.RandDec(SalesLine.Quantity div 1, 2);
        UpdateSalesLineQtyToShip(SalesHeader."No.", QtyToShip);

        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        FindPurchLine(PurchLine, PurchHeader."No.");
        ExpAmount := Round(PurchLine.Amount * QtyToShip / PurchLine.Quantity);

        VerifyPartialDropShipmentPurchaseILE(ItemNo, ExpAmount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure DropShipmentSalesOrderFCYPurchOrderLCY()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        ValueEntry: Record "Value Entry";
    begin
        // [FEATURE] [Drop Shipment] [Purchase]
        // [SCENARIO 375430] Amounts should be recalculated to LCY in Value Entries when post Purchase Order for FCY Sales Order with Drop Shipment
        Initialize();
        ExecuteUIHandlers();

        // [GIVEN] Currency 'HUF' has exch. rates: 3 on 01.07; 4 on 05.07
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate(
          "Currency Code",
          LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDecInRange(10, 20, 2), 1));
        Customer.Modify(true);
        LibraryERM.CreateExchangeRate(Customer."Currency Code", WorkDate() + 1, LibraryRandom.RandDecInRange(10, 20, 2), 1);

        // [GIVEN] Sales Order in 'HUF' with "Posting Date" = 01.07, "Drop Shipment" = Yes; "Line Discount Amount" = 2.00, Amount = 300.00
        CreateSalesOrderWithPurchasingCode(
          SalesHeader, SalesLine,
          Customer."No.", CreatePurchasingCodeWithDropShipment(), LibraryPurchase.CreateVendorNo());
        SalesLine.Validate("Line Discount %", LibraryRandom.RandInt(3));
        SalesLine.Modify(true);

        // [GIVEN] Created a Purchase Order without Currency with Requisition Worksheet
        CarryOutActionMsgOnReqWkshForDropShipment(SalesHeader, SalesLine);
        GetPurchHeader(PurchHeader, SalesLine."No.");
        PurchHeader.Validate("Posting Date", WorkDate() + 1);
        PurchHeader.Modify(true);

        // [WHEN] Purchase Order is posted (received) on 05.07
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, false);

        // [THEN] 'Sale' Value Entry is posted, where "Sales Amount (Expected)" is 100.00 (300.00 / 3); "Discount Amount" is 0.67 (2,00 / 3)
        ValueEntry.SetRange("Item No.", SalesLine."No.");
        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::Sale);
        ValueEntry.FindFirst();
        ValueEntry.TestField(
          "Sales Amount (Expected)",
          Round(LibraryERM.ConvertCurrency(SalesLine.Amount, Customer."Currency Code", '', WorkDate())));
        ValueEntry.TestField(
          "Discount Amount",
          -Round(LibraryERM.ConvertCurrency(SalesLine."Line Discount Amount", Customer."Currency Code", '', WorkDate())));
    end;

    [Test]
    [HandlerFunctions('SalesListPageHandler')]
    [Scope('OnPrem')]
    procedure DropShipmentCopyLinksOnPostingReceiptShipment()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchasingCode: Code[10];
        ItemNo: Code[20];
        SalesLink: Text;
        PurchaseLink: Text;
    begin
        // [FEATURE] [Drop Shipment] [Sales] [Purchase]
        // [SCENARIO 380611] Links from Sales Orders are copied to Sales Shipment, Links from Purchase Order are copied to Purchase Receipt when post drop shipment
        Initialize();

        // [GIVEN] "Copy Comments Order" set to Yes on Purch/Sales Setup
        UpdateCopyCommentsOnSalesPurchaseSetup();

        // [GIVEN] Sales Order has "Item1" with Quantity = 3, "Qty.to Ship" = 3, "Item2" with Quantity = 5, "Qty.to Ship" = 0
        PurchasingCode := CreatePurchasingCodeWithDropShipment();
        CreateSalesOrderWithPurchasingCode(
          SalesHeader, SalesLine, LibrarySales.CreateCustomerNo(), PurchasingCode, LibraryPurchase.CreateVendorNo());
        ItemNo := SalesLine."No.";
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandDecInRange(10, 20, 2));
        SalesLine.Validate("Purchasing Code", PurchasingCode);
        SalesLine.Validate("Qty. to Ship", 0);
        SalesLine.Modify(true);

        // [GIVEN] Record Link for Sales Order with value = "SalesLink"
        SalesLink := CreateRecordLink(SalesHeader);

        // [GIVEN] Purchase Order with lines from drop shipment Sales Order, "Item2" has "Qty. to Receive" = 0
        CreatePurchHeader(PurchHeader, SalesHeader."Sell-to Customer No.", SalesHeader."Ship-to Code");
        LibraryPurchase.GetDropShipment(PurchHeader);
        PurchaseLine.SetRange("Document No.", PurchHeader."No.");
        PurchaseLine.SetRange("No.", SalesLine."No.");
        PurchaseLine.FindFirst();
        PurchaseLine.Validate("Qty. to Receive", 0);
        PurchaseLine.Modify(true);

        // [GIVEN] Record Link for Purchase Order with value = "PurchLink"
        PurchaseLink := CreateRecordLink(PurchHeader);

        // [GIVEN] Posted Purchase Order created receipt and shipment documents for "Item1"
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, false);

        // [GIVEN] Updated "Item2" on Sales Line with "Qty.to Ship" = 5
        SalesHeader.Find();
        LibrarySales.ReopenSalesDocument(SalesHeader);
        SalesLine.Find();
        SalesLine.Validate("Qty. to Ship", SalesLine.Quantity);
        SalesLine.Modify(true);

        // [WHEN] Posted Sales Order created receipt and shipment documents for "Item2"
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [THEN] Posted Sales Shipments for "Item1" and "Item2" has Record Link with value "SalesLink"
        VerifyPostedSalesShipmentLink(SalesHeader."Sell-to Customer No.", ItemNo, SalesLink);
        VerifyPostedSalesShipmentLink(SalesHeader."Sell-to Customer No.", SalesLine."No.", SalesLink);

        // [THEN] Posted Purchase Receipts for "Item1" and "Item2" has Record Link with value "PurchLink"
        VerifyPostedPurchReceiptLink(PurchHeader."Buy-from Vendor No.", ItemNo, PurchaseLink);
        VerifyPostedPurchReceiptLink(PurchHeader."Buy-from Vendor No.", SalesLine."No.", PurchaseLink);
    end;

    [Test]
    [HandlerFunctions('SalesListPageHandler')]
    [Scope('OnPrem')]
    procedure ArchiveDropShipmentPurchOrder()
    var
        SalesHeader: Record "Sales Header";
        PurchHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase] [Sales] [Drop Shipment] [Document Archieve]
        // [SCENARIO 376804] Purchase Order should be archived when post Sales Order with Drop Shipment

        // [GIVEN] Sales Order and Purchase Order with "Drop Shipment"
        Initialize();
        LibraryPurchase.SetArchiveOrders(true);
        CreateSalesAndPurchOrdersWithDropShipment(SalesHeader, PurchHeader);

        // [WHEN] Post Sales Order
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [THEN] Purchase Order is archived
        VerifyPurchHeaderArchive(PurchHeader."Document Type", PurchHeader."No.");
    end;

    [Test]
    [HandlerFunctions('SalesListPageHandler')]
    [Scope('OnPrem')]
    procedure ArchieveDropShipmentSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        PurchHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Sales] [Purchase] [Drop Shipment] [Document Archieve]
        // [SCENARIO 376804] Sales Order should be archived when post Purchase Order with Drop Shipment

        // [GIVEN] Sales Order and Purchase Order with "Drop Shipment"
        Initialize();
        LibrarySales.SetArchiveOrders(true);
        CreateSalesAndPurchOrdersWithDropShipment(SalesHeader, PurchHeader);

        // [WHEN] Post Purchase Order
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, false);

        // [THEN] Sales Order is archived
        VerifySalesHeaderArchive(SalesHeader."Document Type", SalesHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ArchivePostedPurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase] [Archive]
        // [SCENARIO 378218] One archive copy should be created after posting of Purchase Order.
        Initialize();

        // [GIVEN] Set an archiving of Orders as True.
        LibraryPurchase.SetArchiveOrders(true);

        // [GIVEN] Create Purchase Order.
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', '', LibraryRandom.RandDec(10, 2), '', 0D);

        // [WHEN] Post Purchase Order.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] The archive copy of Purchase Order is created.
        VerifyArchiveOfPurchOrder(PurchaseHeader, 1); // [BUG 369983]
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoArchiveOfUnpostedPurchOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
    begin
        // [FEATURE] [Purchase] [Archive]
        // [SCENARIO 378218] The archive copy of Purchase Order should not be created after posting with error.
        Initialize();

        // [GIVEN] Set an archiving of Orders as True.
        LibraryPurchase.SetArchiveOrders(true);

        // [GIVEN] Create Item with empty "Base Unit of Measure".
        LibraryInventory.CreateItem(Item);
        Item.Validate("Base Unit of Measure", '');
        Item.Modify(true);

        // [GIVEN] Create Purchase Order.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        // [GIVEN] Create Purchase Line with empty "Unit of Measure".
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));

        // [WHEN] Post Purchase Order with error.
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        Assert.ExpectedError(PurchaseLine.FieldCaption("Unit of Measure Code"));

        // [THEN] The archive copy of Purchase Order is not created.
        VerifyArchiveOfPurchOrder(PurchaseHeader, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ArchivePostedSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales] [Archive]
        // [SCENARIO 378218] One archive copy should be created after posting of Sales Order.
        Initialize();

        // [GIVEN] Set an archiving of Orders as True.
        LibrarySales.SetArchiveOrders(true);

        // [GIVEN] Create Sales Order.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', '', LibraryRandom.RandDec(10, 2), '', 0D);

        // [WHEN] Post Sales Order.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The archive copy of Sales Order is created.
        VerifyArchiveOfSalesOrder(SalesHeader, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoArchiveOfUnpostedSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales] [Archive]
        // [SCENARIO 378218] The archive copy of Sales Order should not be created after posting with error.
        Initialize();

        // [GIVEN] Set an archiving of Orders as True.
        LibrarySales.SetArchiveOrders(true);
        // [GIVEN] Set "Ext. Doc. No. Mandatory" as True.
        LibrarySales.SetExtDocNo(true);

        // [GIVEN] Create Sales Order with empty "External Document No.".
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesHeader.Validate("External Document No.", '');
        SalesHeader.Modify(true);
        // [GIVEN] Create Sales Lines.
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, '', LibraryRandom.RandDec(10, 2));

        // [WHEN] Post Sales Order with error.
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);
        Assert.ExpectedError(SalesHeader.FieldCaption("External Document No."));

        // [THEN] The archive copy of Sales Order is not created.
        VerifyArchiveOfSalesOrder(SalesHeader, 0);
    end;

    [Test]
    [HandlerFunctions('ExpectedMessageHandler,CreatePickReportHandler')]
    [Scope('OnPrem')]
    procedure InventoryPickCreatedWhenPrepaymentPaid()
    var
        LineGLAccount: Record "G/L Account";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        LocationCode: Code[10];
        Qty: Decimal;
    begin
        // [FEATURE] [Sales] [Prepayment] [Inventory Pick]
        // [SCENARIO 379696] Invt. Pick should be created when "Check Prepmt. when Posting" is marked and Prepayment is paid.
        Initialize();

        // [GIVEN] "Check Prepmt. when Posting" is marked.
        Qty := LibraryRandom.RandInt(100);
        SetCheckPrepmtWhenPostingSales(true);
        CreatePostingSetup(LineGLAccount);
        // [GIVEN] Location with "Require Pick".
        LocationCode := CreateLocationRequirePick();
        // [GIVEN] Item with "VAT Prod. Posting Group" and Item Inventory in Location.
        CreateItemAndItemInventory(
          Item, LocationCode, Qty, LineGLAccount."Gen. Prod. Posting Group", LineGLAccount."VAT Prod. Posting Group");
        // [GIVEN] Create Sales Order for Item with unpaid Prepayment.
        CreateSalesOrderWithUnpaidPrepayment(SalesHeader, LineGLAccount, LocationCode, Item."No.", Qty);
        // [GIVEN] Create payment and release Sales Order.
        CreatePaymentAndReleaseSalesOrder(SalesHeader);
        Commit();

        // [WHEN] Create Inventory Pick
        LibraryVariableStorage.Enqueue(NoOfPicksCreatedMsg);
        SalesHeader.CreateInvtPutAwayPick();

        // [THEN] Message "Number of Invt. Pick activities created..." is appeared.
        RemovePrepmtVATSetup(LineGLAccount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InventoryPickNotCreatedWhenPrepaymentUnpaid()
    var
        LineGLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        LocationCode: Code[10];
        Qty: Decimal;
    begin
        // [FEATURE] [Sales] [Prepayment] [Inventory Pick]
        // [SCENARIO 379696] Invt. Pick should not be created when "Check Prepmt. when Posting" is marked and Prepayment is unpaid.
        Initialize();

        // [GIVEN] "Check Prepmt. when Posting" is marked.
        Qty := LibraryRandom.RandInt(100);
        SetCheckPrepmtWhenPostingSales(true);
        LibrarySales.CreatePrepaymentVATSetup(LineGLAccount, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        // [GIVEN] Location with "Require Pick".
        LocationCode := CreateLocationRequirePick();
        // [GIVEN] Item with "VAT Prod. Posting Group".
        LibraryInventory.CreateItemWithPostingSetup(
          Item, LineGLAccount."Gen. Prod. Posting Group", LineGLAccount."VAT Prod. Posting Group");
        // [GIVEN] Create Sales Order for Item with unpaid Prepayment.
        CreateSalesOrderWithUnpaidPrepayment(SalesHeader, LineGLAccount, LocationCode, Item."No.", Qty);

        // [WHEN] Create Inventory Pick
        asserterror SalesHeader.CreateInvtPutAwayPick();

        // [THEN] Error message "There are unpaid prepayment invoices related to the document..." is appeared.
        Assert.ExpectedError(UnpaidPrepaymentErr);
        RemovePrepmtVATSetup(LineGLAccount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhseShipmentCreatedWhenPrepaymentPaid()
    var
        LineGLAccount: Record "G/L Account";
        WarehouseEmployee: Record "Warehouse Employee";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        LocationCode: Code[10];
        Qty: Decimal;
    begin
        // [FEATURE] [Sales] [Prepayment] [Warehouse Shipment]
        // [SCENARIO 379696] Whse. Shipment should be created when "Check Prepmt. when Posting" is marked and Prepayment is paid.
        Initialize();

        // [GIVEN] "Check Prepmt. when Posting" is marked.
        Qty := LibraryRandom.RandInt(100);
        SetCheckPrepmtWhenPostingSales(true);
        CreatePostingSetup(LineGLAccount);
        // [GIVEN] Location with "Require Shipment".
        LocationCode := CreateLocationRequireShipment();
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationCode, true);
        // [GIVEN] Item with "VAT Prod. Posting Group" and Item Inventory in Location.
        CreateItemAndItemInventory(
          Item, LocationCode, Qty, LineGLAccount."Gen. Prod. Posting Group", LineGLAccount."VAT Prod. Posting Group");
        // [GIVEN] Create Sales Order for Item with unpaid Prepayment.
        CreateSalesOrderWithUnpaidPrepayment(SalesHeader, LineGLAccount, LocationCode, Item."No.", Qty);
        // [GIVEN] Create payment and release Sales Order.
        CreatePaymentAndReleaseSalesOrder(SalesHeader);

        // [WHEN] Create Warehouse Shipment
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [THEN] Warehouse Shipment Line with Item is created.
        VerifyWarehouseShipmentLine(SalesHeader."No.", Item."No.", Qty);
        RemovePrepmtVATSetup(LineGLAccount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhseShipmentNotCreatedWhenPrepaymentUnpaid()
    var
        LineGLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        LocationCode: Code[10];
        Qty: Decimal;
    begin
        // [FEATURE] [Sales] [Prepayment] [Warehouse Shipment]
        // [SCENARIO 379696] Whse. Shipment should not be created when "Check Prepmt. when Posting" is marked and Prepayment is unpaid.
        Initialize();

        // [GIVEN] "Check Prepmt. when Posting" is marked.
        Qty := LibraryRandom.RandInt(100);
        SetCheckPrepmtWhenPostingSales(true);
        LibrarySales.CreatePrepaymentVATSetup(LineGLAccount, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        // [GIVEN] Location with "Require Pick".
        LocationCode := CreateLocationRequireShipment();
        // [GIVEN] Item with "VAT Prod. Posting Group".
        LibraryInventory.CreateItemWithPostingSetup(
          Item, LineGLAccount."Gen. Prod. Posting Group", LineGLAccount."VAT Prod. Posting Group");
        // [GIVEN] Create Sales Order for Item with unpaid Prepayment.
        CreateSalesOrderWithUnpaidPrepayment(SalesHeader, LineGLAccount, LocationCode, Item."No.", Qty);

        // [WHEN] Create Warehouse Shipment
        asserterror LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [THEN] Error message "There are unpaid prepayment invoices related to the document..." is appeared.
        Assert.ExpectedError(UnpaidPrepaymentErr);
        RemovePrepmtVATSetup(LineGLAccount);
    end;

    [Test]
    [HandlerFunctions('SalesListPageHandler')]
    [Scope('OnPrem')]
    procedure ChangeBuyFromVendorNoOnPurchOrderWhenDropShipmentSalesOrderIsPosted()
    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase] [Sales] [Drop Shipment]
        // [SCENARIO 207985] "Buy-from Vendor No." should not be allowed to change in Purchase Order when Drop Sales Shipment is already posted
        Initialize();

        // [GIVEN] Sales Order with "Drop Shipment" for customer "C"
        // [GIVEN] Purchase Order for vendor "V" and "Sell to customer No." = "C" and drop shipment lines
        CreateSalesAndPurchOrdersWithDropShipment(SalesHeader, PurchaseHeader);

        // [GIVEN] Sales Shipment is posted
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [WHEN] Update "Buy-from Vendor No." from "V" to "W" on Purchase Order
        PurchaseHeader.Find();
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        asserterror PurchaseHeader.Validate("Buy-from Vendor No.", LibraryPurchase.CreateVendorNo());

        // [THEN] Error appeared 'You cannot change Buy-from Vendor No. because the order is associated with one or more sales orders.'
        Assert.ExpectedError(YouCannotChangeErr);
    end;

    [Test]
    [HandlerFunctions('SalesListPageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure DropShipmentPurchaseOrderApprovalRequiredToPostSalesOrder()
    var
        UserSetup: Record "User Setup";
        Workflow: Record Workflow;
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [FEATURE] [Purchase] [Drop Shipment] [Sales] [Workflow] [Approval]
        // [SCENARIO 261871] Purchase Order created for Drop Shipment must be approved before posting the Sales Order whereas Purchase Order Approval Workflow is enabled.
        Initialize();

        // [GIVEN] Vendor "V", Approval User Setup, enabled Purchase Order Approval workflow "WF".
        LibraryDocumentApprovals.SetupUserWithApprover(UserSetup);
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseOrderApprovalWorkflowCode());

        // [GIVEN] Sales Order "SO" and Purchase Order "PO" with "Drop Shipment".
        CreateSalesAndPurchOrdersWithDropShipment(SalesHeader, PurchaseHeader);
        Commit();

        // [WHEN] Post the "SO".
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Error is invoked from approval engine: "PO" must be approved.
        Assert.ExpectedError(
          StrSubstNo(
            'Purchase %1 %2 must be approved and released before you can perform this action.',
            PurchaseHeader."Document Type", PurchaseHeader."No."));

        // [THEN] "PO" Status still Open.
        PurchaseHeader.Find();
        PurchaseHeader.TestField(Status, PurchaseHeader.Status::Open);

        // Rollback
        RemoveWorkflow(Workflow);
    end;

    [Test]
    [HandlerFunctions('SalesListPageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure DropShipmentPurchaseOrderApprovalNotRequiredWhenPurchaseOrderReleased()
    var
        UserSetup: Record "User Setup";
        Workflow: Record Workflow;
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [FEATURE] [Purchase] [Drop Shipment] [Sales] [Workflow] [Approval]
        // [SCENARIO 261871] Sales Order with Drop Shipment can be posted while related Purchase Order is released and Purchase Order Approval Workflow is enabled.
        Initialize();

        // [GIVEN] Approval Users Setup.
        LibraryDocumentApprovals.SetupUserWithApprover(UserSetup);

        // [GIVEN] Sales Order "SO" and Purchase Order "PO" with "Drop Shipment".
        CreateSalesAndPurchOrdersWithDropShipment(SalesHeader, PurchaseHeader);

        // [GIVEN] "PO" is released: manually or during the Purchase Order Approval Workflow.
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [GIVEN] Purchase Order Approval workflow "WF" enabled.
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseOrderApprovalWorkflowCode());

        // [WHEN] Post the "SO".
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] "SO" is posted.
        SalesInvoiceHeader.SetRange("Order No.", SalesHeader."No.");
        Assert.RecordIsNotEmpty(SalesInvoiceHeader);

        // Rollback
        RemoveWorkflow(Workflow);
    end;

    [Test]
    [HandlerFunctions('SalesListPageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure DropShipmentSalesOrderApprovalRequiredToPostPurchaseOrderReceipt()
    var
        UserSetup: Record "User Setup";
        Workflow: Record Workflow;
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [FEATURE] [Purchase] [Drop Shipment] [Sales] [Workflow] [Approval]
        // [SCENARIO 261871] Sales Order created for Drop Shipment must be approved before posting receipt for the Purchase Order whereas Sales Order Approval Workflow is enabled.
        Initialize();

        // [GIVEN] Approval Users Setup, enabled Sales Order Approval workflow.
        LibraryDocumentApprovals.SetupUserWithApprover(UserSetup);
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesOrderApprovalWorkflowCode());

        // [GIVEN] Sales Order "SO" and Purchase Order "PO" with "Drop Shipment".
        CreateSalesAndPurchOrdersWithDropShipment(SalesHeader, PurchaseHeader);
        Commit();

        // [WHEN] Post Purchase Receipt for "PO".
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] Error is invoked from approval engine: "SO" must be approved and released.
        Assert.ExpectedError(
          StrSubstNo(
            'Sales %1 %2 must be approved and released before you can perform this action.',
            SalesHeader."Document Type", SalesHeader."No."));

        // [THEN] "SO" still has Status::Open
        SalesHeader.Find();
        SalesHeader.TestField(Status, SalesHeader.Status::Open);

        // Rollback
        RemoveWorkflow(Workflow);
    end;

    [Test]
    [HandlerFunctions('SalesListPageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure DropShipmentSalesOrderApprovalNotRequiredWhenSalesOrderReleased()
    var
        UserSetup: Record "User Setup";
        Workflow: Record Workflow;
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [FEATURE] [Purchase] [Drop Shipment] [Sales] [Workflow] [Approval]
        // [SCENARIO 261871] Receipt for Purchase Order with Drop Shipment can be posted while related Sales Order is released and Sales Order Approval Workflow is enabled.
        Initialize();

        // [GIVEN] Approval Users Setup.
        LibraryDocumentApprovals.SetupUserWithApprover(UserSetup);

        // [GIVEN] Sales Order "SO" and Purchase Order "PO" with "Drop Shipment".
        CreateSalesAndPurchOrdersWithDropShipment(SalesHeader, PurchaseHeader);

        // [GIVEN] "SO" is released: manually or during the Sales Order Approval Workflow.
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Enabled Sales Order Approval workflow "WF".
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesOrderApprovalWorkflowCode());

        // [WHEN] Post Purchase Receipt for "PO".
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] Receipt for "PO" has been posted.
        PurchRcptHeader.SetRange("Order No.", PurchaseHeader."No.");
        Assert.RecordIsNotEmpty(PurchRcptHeader);

        // Rollback
        RemoveWorkflow(Workflow);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostWhseReceiptWithOtherDateWhenPurchaseOrderIsApproved()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        WorkflowSetup: Codeunit "Workflow Setup";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        LocationCode: Code[10];
    begin
        // [FEATURE] [Purchase] [Purchase Order] [Warehouse Receipt] [Approval] [Posting Date]
        // [SCENARIO 275833] Warehouse Receipt created from Purchase Order can be posted with changed WORKDATE when Purchase Order has already passed Workflow approval.
        Initialize();

        // [GIVEN] Location for Receipts
        // [GIVEN] User has a Warehouse Employee setup for Location
        // [GIVEN] Approval Users Setup with Direct Approver
        // [GIVEN] Purchase Order Approval Workflow enabled
        LocationCode := CreateLocationWMSWithWhseEmployee(false, false, true, false);
        PrepareUserSetupAndCreateWorkflow(WorkflowSetup.PurchaseOrderApprovalWorkflowCode());

        // [GIVEN] Purchase Order created and send for approval
        CreatePurchaseDocumentWithLineLocation(PurchaseHeader, PurchaseHeader."Document Type"::Order, LocationCode);
        ApprovalsMgmt.OnSendPurchaseDocForApproval(PurchaseHeader);

        // [GIVEN] Purchase Order is approved
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(PurchaseHeader.RecordId);
        ApprovalsMgmt.ApproveRecordApprovalRequest(PurchaseHeader.RecordId);

        // [WHEN] Warehouse Receipt created from Purchase Order and posted with Posting Date = WorkDate() - 10 DAYS
        CreatePostWhseReceiptFromPOWithPostingDate(PurchaseHeader, WorkDate() - LibraryRandom.RandInt(10));

        // [THEN] Warehouse Receipt successfully posted
        PurchRcptHeader.SetRange("Order No.", PurchaseHeader."No.");
        Assert.RecordIsNotEmpty(PurchRcptHeader);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostWhseShipWithOtherDateWhenPurchaseReturnOrderIsApproved()
    var
        PurchaseHeader: Record "Purchase Header";
        ReturnShipmentHeader: Record "Return Shipment Header";
        WorkflowSetup: Codeunit "Workflow Setup";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        LocationCode: Code[10];
    begin
        // [FEATURE] [Purchase] [Purchase Return Order] [Warehouse Shipment] [Approval] [Posting Date]
        // [SCENARIO 275833] Warehouse Shipment created from Purchase Return Order can be posted with changed WORKDATE when Purchase Return Order has already passed Workflow approval.
        Initialize();

        // [GIVEN] Location for Shipments
        // [GIVEN] User has a Warehouse Employee setup for Location
        // [GIVEN] Approval Users Setup with Direct Approver
        // [GIVEN] Purchase Return Order Approval Workflow enabled for Approver Type = Approver
        LocationCode := CreateLocationWMSWithWhseEmployee(false, false, false, true);
        PrepareUserSetupAndCreateWorkflow(WorkflowSetup.PurchaseReturnOrderApprovalWorkflowCode());

        // [GIVEN] Purchase Return Order created and send for approval
        CreatePurchaseDocumentWithLineLocation(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", LocationCode);
        ApprovalsMgmt.OnSendPurchaseDocForApproval(PurchaseHeader);

        // [GIVEN] Purchase Return Order is approved
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(PurchaseHeader.RecordId);
        ApprovalsMgmt.ApproveRecordApprovalRequest(PurchaseHeader.RecordId);

        // [WHEN] Return Shipment created and posted with Posting Date = WorkDate() - 10 DAYS
        CreatePostWhseShipmentFromPROWithPostingDate(PurchaseHeader, WorkDate() - LibraryRandom.RandInt(10));

        // [THEN] Return Shipment successfully posted
        ReturnShipmentHeader.SetRange("Return Order No.", PurchaseHeader."No.");
        Assert.RecordIsNotEmpty(ReturnShipmentHeader);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostWhseShipWithOtherDateWhenSalesOrderIsApproved()
    var
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        WorkflowSetup: Codeunit "Workflow Setup";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        LocationCode: Code[10];
    begin
        // [FEATURE] [Sales] [Sales Order] [Warehouse Shipment] [Approval] [Posting Date]
        // [SCENARIO 275833] Warehouse Shipment created from Sales Order can be posted with changed WORKDATE when Sales Order has already passed Workflow approval.
        Initialize();

        // [GIVEN] Location for Shipment
        // [GIVEN] User has a Warehouse Employee setup for Location
        LocationCode := CreateLocationWMSWithWhseEmployee(false, false, false, true);

        // [GIVEN] Approval Users Setup with Direct Approver
        // [GIVEN] Sales Order Approval Workflow enabled for Direct Approver
        PrepareUserSetupAndCreateWorkflow(WorkflowSetup.SalesOrderApprovalWorkflowCode());

        // [GIVEN] Sales Order created and send for approval
        CreateSalesDocumentWithLineLocation(SalesHeader, SalesHeader."Document Type"::Order, LocationCode);
        ApprovalsMgmt.OnSendSalesDocForApproval(SalesHeader);

        // [GIVEN] Sales Order is approved
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(SalesHeader.RecordId);
        ApprovalsMgmt.ApproveRecordApprovalRequest(SalesHeader.RecordId);

        // [WHEN] Warehouse Shipment created and posted with Posting Date = WorkDate() - 10 DAYS
        CreatePostWhseShipmentFromSOWithPostingDate(SalesHeader, WorkDate() - LibraryRandom.RandInt(10));

        // [THEN] Warehouse Shipment successfully posted
        SalesShipmentHeader.SetRange("Order No.", SalesHeader."No.");
        Assert.RecordIsNotEmpty(SalesShipmentHeader);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostWhseReceiptWithOtherDateWhenSalesRetOrderIsApproved()
    var
        SalesHeader: Record "Sales Header";
        ReturnReceiptHeader: Record "Return Receipt Header";
        WorkflowSetup: Codeunit "Workflow Setup";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        LocationCode: Code[10];
    begin
        // [FEATURE] [Sales] [Sales Return Order] [Warehouse Receipt] [Approval] [Posting Date]
        // [SCENARIO 275833] Warehouse Receipt created from Sales Return Order can be posted with changed WORKDATE when Sales Return Order has already passed Workflow approval.
        Initialize();

        // [GIVEN] Location for Receipts
        // [GIVEN] User has a Warehouse Employee setup for Location
        // [GIVEN] Approval Users Setup with Direct Approver
        // [GIVEN] Sales Return Order Approval Workflow enabled for Direct Approver
        LocationCode := CreateLocationWMSWithWhseEmployee(false, false, true, false);
        PrepareUserSetupAndCreateWorkflow(WorkflowSetup.SalesReturnOrderApprovalWorkflowCode());

        // [GIVEN] Sales Return Order created and send for approval
        CreateSalesDocumentWithLineLocation(SalesHeader, SalesHeader."Document Type"::"Return Order", LocationCode);
        ApprovalsMgmt.OnSendSalesDocForApproval(SalesHeader);

        // [GIVEN] Sales Return Order is approved
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(SalesHeader.RecordId);
        ApprovalsMgmt.ApproveRecordApprovalRequest(SalesHeader.RecordId);

        // [WHEN] Warehouse Receipt created and posted with Posting Date = WorkDate() - 10 DAYS
        CreatePostWhseReceiptFromSROWithPostingDate(SalesHeader, WorkDate() - LibraryRandom.RandInt(10));

        // [THEN] Warehouse Receipt successfully posted
        ReturnReceiptHeader.SetRange("Return Order No.", SalesHeader."No.");
        Assert.RecordIsNotEmpty(ReturnReceiptHeader);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,CreateInvtPutAwayRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostInventoryPutAwayWithOtherDateWhenPurchaseOrderIsApproved()
    var
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        WorkflowSetup: Codeunit "Workflow Setup";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        LocationCode: Code[10];
    begin
        // [FEATURE] [Purchase] [Inventory Put-Away] [Posting Date] [Workflow]
        // [SCENARIO 303845] Warehouse Put-Away created from Purchase Order can be posted with changed Posting Date when Purchase Order has already passed Workflow approval.
        Initialize();

        // [GIVEN] Location for Inventory Put-Away
        // [GIVEN] Warehouse Employee setup for User and Location
        LocationCode := CreateLocationWMSWithWhseEmployee(true, false, false, false);

        // [GIVEN] Approval Users Setup with Direct Approver
        // [GIVEN] Purchase Order Approval Workflow enabled for Direct Approver
        PrepareUserSetupAndCreateWorkflow(WorkflowSetup.PurchaseOrderApprovalWorkflowCode());

        // [GIVEN] Purchase Order created with Posting Date = WORKDATE and send for approval
        CreatePurchaseDocumentWithLineLocation(PurchaseHeader, PurchaseHeader."Document Type"::Order, LocationCode);
        ApprovalsMgmt.OnSendPurchaseDocForApproval(PurchaseHeader);

        // [GIVEN] Purchase Order is approved
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(PurchaseHeader.RecordId);
        ApprovalsMgmt.ApproveRecordApprovalRequest(PurchaseHeader.RecordId);
        Commit();

        // [WHEN] Inventory Put-Away created and posted from Purchase Order with Posting Date = WorkDate() + 1
        PurchaseHeader.Find();
        PurchaseHeader.CreateInvtPutAwayPick();
        FindAndUpdateWhseActivityPostingDate(
          WarehouseActivityHeader, WarehouseActivityLine,
          DATABASE::"Purchase Line", PurchaseHeader."No.",
          WarehouseActivityHeader.Type::"Invt. Put-away", WorkDate() + 1);
        LibraryWarehouse.SetQtyToHandleWhseActivity(WarehouseActivityHeader, WarehouseActivityLine.Quantity);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [THEN] Inventory Put-Away posted
        VerifyItemLedgerEntryForItemLocationActivity(
          ItemLedgerEntry."Entry Type"::Purchase, LocationCode,
          WarehouseActivityLine."Item No.", WarehouseActivityLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,CreateInvtPickRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostInventoryPickWithOtherDateWhenSalesOrderIsApproved()
    var
        SalesHeader: Record "Sales Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        WorkflowSetup: Codeunit "Workflow Setup";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        LocationCode: Code[10];
    begin
        // [FEATURE] [Sales] [Inventory Pick] [Posting Date] [Workflow]
        // [SCENARIO 303845] Inventory Pick created from Sales Order can be posted with changed Posting Date when Sales Order has already passed Workflow approval.
        Initialize();

        // [GIVEN] Location for Inventory Pick
        // [GIVEN] Warehouse Employee setup for User and Location
        LocationCode := CreateLocationWMSWithWhseEmployee(false, true, false, false);

        // [GIVEN] Approval Users Setup with Direct Approver
        // [GIVEN] Sales Order Approval Workflow enabled for Direct Approver
        PrepareUserSetupAndCreateWorkflow(WorkflowSetup.SalesOrderApprovalWorkflowCode());

        // [GIVEN] Sales Order created with Posting Date = WORKDATE and send for approval
        CreateSalesDocumentWithLineLocation(SalesHeader, SalesHeader."Document Type"::Order, LocationCode);
        ApprovalsMgmt.OnSendSalesDocForApproval(SalesHeader);

        // [GIVEN] Sales Order is approved
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(SalesHeader.RecordId);
        ApprovalsMgmt.ApproveRecordApprovalRequest(SalesHeader.RecordId);
        Commit();

        // [WHEN] Inventory Pick created and posted from Sales Order with Posting Date = WorkDate() + 1
        SalesHeader.Find();
        SalesHeader.CreateInvtPutAwayPick();
        FindAndUpdateWhseActivityPostingDate(
          WarehouseActivityHeader, WarehouseActivityLine,
          DATABASE::"Sales Line", SalesHeader."No.",
          WarehouseActivityHeader.Type::"Invt. Pick", WorkDate() + 1);
        LibraryWarehouse.SetQtyToHandleWhseActivity(WarehouseActivityHeader, WarehouseActivityLine.Quantity);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [THEN] Inventory Pick posted
        VerifyItemLedgerEntryForItemLocationActivity(
          ItemLedgerEntry."Entry Type"::Sale, LocationCode,
          WarehouseActivityLine."Item No.", -WarehouseActivityLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostSalesOrdersWithEmptyCategoryCode()
    var
        SalesHeader: array[2] of Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        i: Integer;
        JobQueueEntryId: List of [Guid];
    begin
        // [FEATURE] [Batch Post] [Order] [Sales]
        // [SCENARIO] Job queue category code filled in job queue entry in the case of empty sales setup
        Initialize();
        LibrarySales.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // [GIVEN] Sales Orders
        for i := 1 to ArrayLen(SalesHeader) do
            CreateSalesDocument(SalesHeader[i], SalesLine, SalesHeader[1]."Document Type"::Order);

        // [GIVEN] "Job Queue Category Code" is empty in sales and receivables setup
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Job Queue Category Code", '');
        SalesReceivablesSetup.Modify(true);

        // [WHEN] Post Sales Orders with Batch Post as Ship and Invoice.
        SalesPostBatchShipInvoice(SalesHeader);
        for i := 1 to ArrayLen(SalesHeader) do
            JobQueueEntryId.Add(GetJobQueueEntryId(SalesHeader[i].RecordId));
        for i := 1 to ArrayLen(SalesHeader) do
            LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader[i].RecordId);

        // [THEN] Job Queue Category Code filled in job queue log entry
        // [THEN] 'SALESBCKGR' Job Category Code exists
        VerifySalesJobQueueCategoryCode(JobQueueEntryId);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostPurchaseOrdersWithEmptyCategoryCode()
    var
        PurchaseHeader: array[2] of Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        i: Integer;
        JobQueueEntryId: List of [Guid];
    begin
        // [FEATURE] [Batch Post] [Order] [Purchase]
        // [SCENARIO] Job queue category code filled in job queue entry in the case of empty purchase setup
        Initialize();
        LibraryPurchase.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // [GIVEN] Purchase Orders
        for i := 1 to ArrayLen(PurchaseHeader) do
            CreatePurchaseDocument(PurchaseHeader[i], PurchaseLine, PurchaseHeader[i]."Document Type"::Order, LibraryPurchase.CreateVendorNo());

        // [GIVEN] "Job Queue Category Code" is empty in purchases and payables setup
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Job Queue Category Code", '');
        PurchasesPayablesSetup.Modify(true);

        // [WHEN] Run Batch Post Purchase Order
        RunBatchPostPurchaseOrders(PurchaseHeader[1]."No." + '|' + PurchaseHeader[2]."No.", true, true, 0D, false, false, false);
        for i := 1 to ArrayLen(PurchaseHeader) do
            JobQueueEntryId.Add(GetJobQueueEntryId(PurchaseHeader[i].RecordId));
        for i := 1 to ArrayLen(PurchaseHeader) do
            LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader[i].RecordId);

        // [THEN] Job Queue Category Code filled in job queue log entry
        // [THEN] 'PURCHBCKGR' Job Category Code exists
        VerifyPurchaseJobQueueCategoryCode(JobQueueEntryId);
    end;

    [Test]
    [HandlerFunctions('SalesListPageHandler')]
    [Scope('OnPrem')]
    procedure PurchOrderGetDropShipWithCustomAddress()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Drop Shipment] [Purchase]
        // [SCENARIO 339552] Address fields are copied to Purchase Order from drop shipment sales with custom address
        Initialize();

        // [GIVEN] Sales Order of Drop Shipment for Customer "CU01"
        CreateSalesOrderWithPurchasingCode(
          SalesHeader, SalesLine, LibrarySales.CreateCustomerNo(), CreatePurchasingCodeWithDropShipment(), LibraryPurchase.CreateVendorNo());

        // [GIVEN] 'Ship-to' fields updated on Sales Order:
        // [GIVEN] Address, Address 2, Post Code, City, Contact, County, Country/Region and Phone No
        UpdateShipToAddressOnSalesHeader(SalesHeader);

        // [GIVEN] Create Purchase Header with "Sell-to Customer No." = "CU01"
        CreatePurchHeader(PurchaseHeader, SalesHeader."Sell-to Customer No.", '');

        // [WHEN] Get Drop Shipment for the Purchase Header
        LibraryPurchase.GetDropShipment(PurchaseHeader);

        // [THEN] Purchase Order updated with 'Ship-to' fields matching to values from Sales Order
        GetPurchHeader(PurchaseHeader, SalesLine."No.");
        VerifyPurchHeaderAddress(PurchaseHeader, SalesHeader);
    end;

    [Test]
    [HandlerFunctions('BatchPostSalesOrderRequestPageHandler,SentNotificationHandler')]
    [Scope('OnPrem')]
    procedure SalesBatchJobPendingApprovalError()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ErrorMessagesPage: TestPage "Error Messages";
    begin
        // [FEATURE] [Batch Post] [Sales]
        // [SCENARIO 372886] When batch posting order with Status = Pending Approval, error "Can not be posted because it is pending approval" is shown
        Initialize();

        // [GIVEN] Sales Order with Status = Pending approval
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);
        SalesHeader.Validate(Status, SalesHeader.Status::"Pending Approval");
        SalesHeader.Modify(true);

        // [WHEN] Post Sales Batch on this header
        ErrorMessagesPage.Trap();
        RunPostBatchSalesOrder(SalesHeader."No.");

        // [THEN] Notification: 'An error occured during operation: batch processing of Sales Header records.'
        Assert.ExpectedMessage(StrSubstNo(NotificationMsg, SalesHeader.TableCaption()), LibraryVariableStorage.DequeueText()); // from SentNotificationHandler
        LibraryVariableStorage.AssertEmpty();

        // [THEN] On "Details" action - Error Messages page is open, message is: "Can not be posted because it is pending approval"
        ErrorMessagesPage.Description.AssertEquals(StrSubstNo(ApprovalPendingErr, 'sales', SalesHeader."No.", SalesHeader."Document Type"));

        // Clean-up.
        Clear(SalesHeader);
        LibraryNotificationMgt.RecallNotificationsForRecord(SalesHeader);
    end;

    [Test]
    [HandlerFunctions('SentNotificationHandler')]
    [Scope('OnPrem')]
    procedure PurchaseBatchJobPendingApprovalError()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ErrorMessagesPage: TestPage "Error Messages";
    begin
        // [FEATURE] [Batch Post] [Purchase]
        // [GIVEN 372886] When batch posting order with Status = Pending Approval, error "Can not be posted because it is pending approval" is shown
        Initialize();

        // [GIVEN] Purchase Order with Status = Pending approval
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate(Status, PurchaseHeader.Status::"Pending Approval");
        PurchaseHeader.Modify(true);

        // [WHEN] Post Purchase Batch on this header
        ErrorMessagesPage.Trap();
        RunBatchPostPurchaseOrders(PurchaseHeader."No.", true, true, WorkDate(), false, false, false);

        // [THEN] Notification: 'An error occured during operation: batch processing of Purchase Header records.'
        Assert.ExpectedMessage(StrSubstNo(NotificationMsg, PurchaseHeader.TableCaption()), LibraryVariableStorage.DequeueText()); // from SentNotificationHandler
        LibraryVariableStorage.AssertEmpty();

        // [THEN] On "Details" action - Error Messages page is open, message is: "Can not be posted because it is pending approval"
        ErrorMessagesPage.Description.AssertEquals(StrSubstNo(ApprovalPendingErr, 'purchase', PurchaseHeader."No.", PurchaseHeader."Document Type"));

        // Clean-up
        Clear(PurchaseHeader);
        LibraryNotificationMgt.RecallNotificationsForRecord(PurchaseHeader);
    end;

    [Test]
    [HandlerFunctions('BatchPostSalesOrderRequestPageHandler,SentNotificationHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure SalesBatchJobApprovalWorkflowError()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ErrorMessagesPage: TestPage "Error Messages";
        Workflow: Record Workflow;
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [FEATURE] [Batch Post] [Sales] [Approval] [Workflow]
        // [SCENARIO 372886] When batch posting order while approval workflow is enabled, error "Can not be posted because of approval workflow restrictions" is shown
        Initialize();

        // [GIVEN] Approval workflow for Sales Orders is active
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesOrderApprovalWorkflowCode());

        // [GIVEN] Sales Order created
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);

        // [WHEN] Post Sales Batch on this header
        ErrorMessagesPage.Trap();
        RunPostBatchSalesOrder(SalesHeader."No.");

        // [THEN] Notification: 'An error occured during operation: batch processing of Sales Header records.'
        Assert.ExpectedMessage(StrSubstNo(NotificationMsg, SalesHeader.TableCaption()), LibraryVariableStorage.DequeueText()); // from SentNotificationHandler
        LibraryVariableStorage.AssertEmpty();

        // [THEN] On "Details" action - Error Messages page is open, message is: "Can not be posted because of approval workflow restrictions"
        ErrorMessagesPage.Description.AssertEquals(StrSubstNo(ApprovalWorkflowErr, 'sales', SalesHeader."No.", SalesHeader."Document Type"));

        // Clean-up.
        Clear(SalesHeader);
        LibraryNotificationMgt.RecallNotificationsForRecord(SalesHeader);
        RemoveWorkflow(Workflow);
    end;

    [Test]
    [HandlerFunctions('SentNotificationHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure PurchaseBatchJobApprovalWorkflowError()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ErrorMessagesPage: TestPage "Error Messages";
        Workflow: Record Workflow;
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [FEATURE] [Batch Post] [Purchase] [Approval] [Workflow]
        // [GIVEN 372886] When batch posting order while approval workflow is enabled, error "Can not be posted because of approval workflow restrictions" is shown
        Initialize();

        // [GIVEN] Approval workflow for Sales Orders is active
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseOrderApprovalWorkflowCode());

        // [GIVEN] Purchase Order created
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());

        // [WHEN] Post Purchase Batch on this header
        ErrorMessagesPage.Trap();
        RunBatchPostPurchaseOrders(PurchaseHeader."No.", true, true, WorkDate(), false, false, false);

        // [THEN] Notification: 'An error occured during operation: batch processing of Purchase Header records.'
        Assert.ExpectedMessage(StrSubstNo(NotificationMsg, PurchaseHeader.TableCaption()), LibraryVariableStorage.DequeueText()); // from SentNotificationHandler
        LibraryVariableStorage.AssertEmpty();

        // [THEN] On "Details" action - Error Messages page is open, message is: "Can not be posted because of approval workflow restrictions"
        ErrorMessagesPage.Description.AssertEquals(StrSubstNo(ApprovalWorkflowErr, 'purchase', PurchaseHeader."No.", PurchaseHeader."Document Type"));

        // Clean-up
        Clear(PurchaseHeader);
        LibraryNotificationMgt.RecallNotificationsForRecord(PurchaseHeader);
        RemoveWorkflow(Workflow);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostSalesOrderWithChangedDefaultBankAccountCode()
    var
        BankAccount: array[2] of Record "Bank Account";
        Currency: Record Currency;
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: array[2] of Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Index: Integer;
    begin
        // [FEATURE] [Batch Post] [Order] [Sales]
        // [SCENARIO 334500] Create and post two Sales Orders using Batch Post Sales Order and not default Bank Account Code

        // 1. Setup: Find Item and Create Customer.
        Initialize();

        Currency.Get(LibraryERM.CreateCurrencyWithRandomExchRates());

        // Create default bank account for new currency
        LibraryERM.CreateBankAccount(BankAccount[1]);
        BankAccount[1].Validate("Currency Code", Currency.Code);
        BankAccount[1]."Use as Default for Currency" := true;
        BankAccount[1].Modify();

        // Create second bank account for new currency
        LibraryERM.CreateBankAccount(BankAccount[2]);
        BankAccount[2].Validate("Currency Code", Currency.Code);
        BankAccount[2].Modify();

        LibraryInventory.CreateItem(Item);

        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", Currency.Code);
        Customer.Modify();

        // Create and post first sales order
        LibrarySales.CreateSalesHeader(SalesHeader[1], "Sales Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(
            SalesLine, SalesHeader[1], "Sales Line Type"::Item, Item."No.", LibraryRandom.RandDec(10, 2));
        // verify default bank account is set
        Assert.AreEqual(SalesHeader[1]."Company Bank Account Code", BankAccount[1]."No.", 'Default bank account code is not set');
        // Change default bank account and release and post as ship
        SalesHeader[1].Validate("Company Bank Account Code", BankAccount[2]."No.");
        SalesHeader[1].Modify();
        LibrarySales.ReleaseSalesDocument(SalesHeader[1]);
        LibrarySales.PostSalesDocument(SalesHeader[1], true, false);

        // Create and post second sales order
        LibrarySales.CreateSalesHeader(SalesHeader[2], "Sales Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(
            SalesLine, SalesHeader[2], SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));
        SalesHeader[2].Validate("Company Bank Account Code", BankAccount[2]."No.");
        SalesHeader[2].Modify();
        LibrarySales.ReleaseSalesDocument(SalesHeader[2]);
        LibrarySales.PostSalesDocument(SalesHeader[2], true, false);
        Commit();

        SalesPostBatch(SalesHeader, WorkDate(), false, true);

        // 3. Verify: Verify Sales Invoice have correct Company Bank Account Code.
        for Index := 1 to ArrayLen(SalesHeader) do begin
            SalesInvoiceHeader.SetRange("Sell-to Customer No.", SalesHeader[Index]."Sell-to Customer No.");
            SalesInvoiceHeader.SetRange("Currency Code", SalesHeader[Index]."Currency Code");
            SalesInvoiceHeader.FindFirst();
            SalesInvoiceHeader.TestField("Company Bank Account Code", SalesHeader[Index]."Company Bank Account Code");
        end;
    end;

    local procedure Initialize()
    var
        WarehouseEmployee: Record "Warehouse Employee";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Batch Job");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        LibraryWorkflow.DisableAllWorkflows();
        WarehouseEmployee.DeleteAll();
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Batch Job");

        SetGLSetupInvoiceRounding();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateLocalData();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Batch Job");
        BindSubscription(LibraryJobQueue);
    end;

    local procedure AddComponentInventory(var AssemblyHeader: Record "Assembly Header"; ItemNo: Code[20])
    begin
        AssemblyHeader.SetRange("Item No.", ItemNo);
        AssemblyHeader.FindFirst();
        LibraryAssembly.AddCompInventory(AssemblyHeader, WorkDate(), 0);
    end;

    local procedure CreateSalesAndPurchOrdersWithDropShipment(var SalesHeader: Record "Sales Header"; var PurchHeader: Record "Purchase Header")
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        CreateDropShipmentLine(SalesLine, SalesHeader);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        CreatePurchHeader(PurchHeader, SalesHeader."Sell-to Customer No.", '');
        LibraryPurchase.GetDropShipment(PurchHeader);
    end;

    local procedure CreateSalesAndPurchOrdersWithDropShipmentAndCountryCode(var SalesHeader: Record "Sales Header"; var PurchHeader: Record "Purchase Header"; var ItemNo: Code[20]; var CountryCode: Code[10])
    begin
        CreateSalesOrderWithDropShipAndShipToCode(SalesHeader, ItemNo, CountryCode);
        CreatePurchHeader(PurchHeader, SalesHeader."Sell-to Customer No.", SalesHeader."Ship-to Code");
        LibraryPurchase.GetDropShipment(PurchHeader);
    end;

    local procedure CreateAndPostGenJournalLines(): Code[10]
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // Create Fiscal Year, Close Fiscal Year, General Journal Batch. Create and Post General Journal Lines.
        LibraryFiscalYear.CreateClosedAccountingPeriods();
        CreateGeneralJournalBatch(GenJournalBatch);
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, LibraryFiscalYear.GetFirstPostingDate(true));
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch,
          CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', LibraryFiscalYear.GetFirstPostingDate(true)));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Journal Batch Name");
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Recurring, false);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; PostingDate: Date)
    var
        GLAccount: Record "G/L Account";
        GLAccount2: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGLAccount(GLAccount2);

        // Use Random for Amount value is not important.
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", GLAccount."No.", LibraryRandom.RandDec(100, 2));

        // Value of Document No. is not important.
        GenJournalLine.Validate("Document No.", GenJournalLine."Journal Batch Name" + Format(GenJournalLine."Line No."));
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", GLAccount2."No.");
        GenJournalLine.Modify(true);
    end;

    local procedure CreateGeneralPostingSetup(var GeneralPostingSetup: Record "General Posting Setup")
    var
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        LibraryERM.CreateGenBusPostingGroup(GenBusinessPostingGroup);
        LibraryERM.FindGenProductPostingGroup(GenProductPostingGroup);
        LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, GenBusinessPostingGroup.Code, GenProductPostingGroup.Code);
    end;

    local procedure CreateAndGetPurchaseDocumentNo(var PurchaseLine: Record "Purchase Line"; VendorNo: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        NoSeries: Codeunit "No. Series";
    begin
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, VendorNo);
        exit(NoSeries.PeekNextNo(PurchaseHeader."Posting No. Series"));
    end;

    local procedure CreateAndReleasePurchaseOrder(var PurchaseLine: Record "Purchase Line"; LocationCode: Code[10])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseHeader(PurchaseHeader);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, LocationCode);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateAndUpdatePurchasingCodeOnSalesDocument(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);
        SalesLine.Validate("Purchasing Code", CreatePurchasingCode());
        SalesLine.Modify(true);
    end;

    local procedure CreateAssemblyItemWithAssemblyPolicy(var AssemblyItem: Record Item; AssemblyPolicy: Enum "Assembly Policy")
    begin
        LibraryAssembly.CreateItem(AssemblyItem, AssemblyItem."Costing Method"::Standard,
          AssemblyItem."Replenishment System"::Assembly, '', '');
        AssemblyItem.Validate("Assembly Policy", AssemblyPolicy);
        AssemblyItem.Modify(true);
    end;

    local procedure CreateAssemblyItemWithComponent(var AssemblyItem: Record Item; AssemblyPolicy: Enum "Assembly Policy"; Quantity: Decimal)
    var
        BOMComponent: Record "BOM Component";
        ComponentItem: Record Item;
    begin
        CreateAssemblyItemWithAssemblyPolicy(AssemblyItem, AssemblyPolicy);
        LibraryAssembly.CreateItem(
          ComponentItem, ComponentItem."Costing Method"::Standard, ComponentItem."Replenishment System"::Purchase, '', '');
        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Item, ComponentItem."No.", AssemblyItem."No.", '', BOMComponent."Resource Usage Type", Quantity, true);
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandDec(1000, 2));
        Item.Validate("Last Direct Cost", LibraryRandom.RandDec(1000, 2));
        Item.Modify();
        exit(Item."No.");
    end;

    local procedure CreateItemAndItemInventory(var Item: Record Item; LocationCode: Code[10]; Qty: Decimal; GenProdPostingGroup: Code[20]; VATProdPostingGroup: Code[20])
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemWithPostingSetup(Item, GenProdPostingGroup, VATProdPostingGroup);
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Item, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name",
          ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Qty);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateItemWithVendNo(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        Item.Modify(true);
    end;

    local procedure CreateLocationWMSWithWhseEmployee(RequirePutAway: Boolean; RequirePick: Boolean; RequireReceive: Boolean; RequireShipment: Boolean): Code[10]
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateLocationWMS(Location, false, RequirePutAway, RequirePick, RequireReceive, RequireShipment);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
        exit(Location.Code);
    end;

    local procedure CreateLocationRequirePick(): Code[10]
    var
        Location: Record Location;
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Require Pick", true);
        Location.Modify(true);
        exit(Location.Code);
    end;

    local procedure CreateLocationRequireReceive(): Code[10]
    var
        Location: Record Location;
    begin
        LibraryWarehouse.CreateLocation(Location);
        Location.Validate("Require Receive", true);
        Location.Modify(true);
        exit(Location.Code);
    end;

    local procedure CreateLocationRequireShipment(): Code[10]
    var
        Location: Record Location;
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Require Shipment", true);
        Location.Modify(true);
        exit(Location.Code);
    end;

    local procedure CreatePaymentAndReleaseSalesOrder(var SalesHeader: Record "Sales Header")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        SalesHeader.CalcFields("Amount Including VAT");
        LibrarySales.CreatePaymentAndApplytoInvoice(
          GenJournalLine, SalesHeader."Sell-to Customer No.", SalesHeader."Last Prepayment No.", -SalesHeader."Amount Including VAT");
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreatePostingSetup(var LineGLAccount: Record "G/L Account")
    var
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibrarySales.CreatePrepaymentVATSetup(LineGLAccount, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, '', LineGLAccount."Gen. Prod. Posting Group");
        GeneralPostingSetup.Validate("Inventory Adjmt. Account", LibraryERM.CreateGLAccountNo());
        GeneralPostingSetup.Modify(true);
    end;

    local procedure CreatePurchasingCode(): Code[10]
    var
        Purchasing: Record Purchasing;
    begin
        LibraryPurchase.CreatePurchasingCode(Purchasing);
        Purchasing.Validate("Special Order", true);
        Purchasing.Modify(true);
        exit(Purchasing.Code);
    end;

    local procedure CreatePurchasingCodeWithDropShipment(): Code[10]
    var
        Purchasing: Record Purchasing;
    begin
        LibraryPurchase.CreatePurchasingCode(Purchasing);
        Purchasing.Validate("Drop Shipment", true);
        Purchasing.Modify(true);
        exit(Purchasing.Code);
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandDec(10, 2));
    end;

    local procedure CreatePurchaseDocumentWithLineLocation(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; LocationCode: Code[10])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, DocumentType, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.SetRecFilter();
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.FindFirst();
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
    end;

    local procedure CreatePurchHeader(var PurchHeader: Record "Purchase Header"; SellToCustomerNo: Code[20]; ShipToCode: Code[10])
    begin
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '');
        PurchHeader.Validate("Sell-to Customer No.", SellToCustomerNo);
        if ShipToCode <> '' then
            PurchHeader.Validate("Ship-to Code", ShipToCode);
        PurchHeader.Modify(true);
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; LocationCode: Code[10])
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandDec(10, 2));
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesDocumentWithLineLocation(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; LocationCode: Code[10])
    var
        SalesLine: Record "Sales Line";
        UserSetup: Record "User Setup";
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateSalesDocumentWithItem(SalesHeader, SalesLine, DocumentType, LibraryInventory.CreateItemNo());
        SalesHeader.SetRecFilter();
        UserSetup.Get(UserId);
        UserSetup.Get(UserSetup."Approver ID");
        SalesHeader.Validate("Salesperson Code", UserSetup."Salespers./Purch. Code");
        SalesHeader.Validate("Location Code", LocationCode);
        SalesHeader.Modify(true);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.FindFirst();
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);

        LibraryInventory.CreateItemJournalLineInItemTemplate(
          ItemJournalLine, SalesLine."No.", LocationCode, '', LibraryRandom.RandIntInRange(10, 20));
        LibraryInventory.PostItemJournalLine(
          ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateSalesOrderWithPurchasingCode(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; PurchasingCode: Code[10]; VendorNo: Code[20])
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Vendor No.", VendorNo);
        Item.Validate("Unit Price", LibraryRandom.RandDecInRange(10, 20, 2));
        Item.Modify(true);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDecInRange(10, 20, 2));
        SalesLine.Validate("Purchasing Code", PurchasingCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrderWithUnpaidPrepayment(var SalesHeader: Record "Sales Header"; LineGLAccount: Record "G/L Account"; LocationCode: Code[10]; ItemNo: Code[20]; Qty: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomerWithPrepayment(LineGLAccount));
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Qty);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(1000, 2));
        SalesLine.Modify(true);
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
    end;

    local procedure CreateDropShipmentLine(var SalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header")
    var
        Purchasing: Record Purchasing;
        Item: Record Item;
    begin
        CreateItemWithVendNo(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));
        LibraryPurchase.CreatePurchasingCode(Purchasing);
        Purchasing.Validate("Drop Shipment", true);
        Purchasing.Modify(true);
        SalesLine.Validate("Purchasing Code", Purchasing.Code);
        SalesLine.Modify(true);
    end;

    local procedure CreateSpecialOrderLine(var SalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header")
    var
        Purchasing: Record Purchasing;
        Item: Record Item;
    begin
        CreateItemWithVendNo(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));
        LibraryPurchase.CreatePurchasingCode(Purchasing);
        Purchasing.Validate("Special Order", true);
        Purchasing.Modify(true);
        SalesLine.Validate("Purchasing Code", Purchasing.Code);
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchaseOrderAndGetSpecialOrder(SellToCustomerNo: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        DistIntegration: Codeunit "Dist. Integration";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Vendor Invoice No.",
          CopyStr(
            LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("Vendor Invoice No."), DATABASE::"Purchase Header"), 1,
            LibraryUtility.GetFieldLength(DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Vendor Invoice No."))));
        PurchaseHeader.Validate("Sell-to Customer No.", SellToCustomerNo);
        PurchaseHeader.Modify(true);
        DistIntegration.GetSpecialOrders(PurchaseHeader);
        exit(PurchaseHeader."No.");
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type")
    begin
        CreateSalesDocumentWithItem(SalesHeader, SalesLine, DocumentType, CreateItem());
    end;

    local procedure CreateSalesDocumentWithItem(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; ItemNo: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandInt(10));
    end;

    local procedure CreateCustomer(ReminderTermsCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
        FinanceChargeTerms: Record "Finance Charge Terms";
    begin
        FinanceChargeTerms.SetFilter("Interest Rate", '<>0');
        FinanceChargeTerms.FindFirst();
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Reminder Terms Code", ReminderTermsCode);
        Customer.Validate("Fin. Charge Terms Code", FinanceChargeTerms.Code);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerWithAddress(var Customer: Record Customer; LocationCode: Code[10])
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Location Code", LocationCode);
        Customer.Validate(Address, 'Address: ' + Customer."No.");
        Customer.Modify(true);
    end;

    local procedure CreateFinanceChargeDocument(var FinanceChargeMemoNo: Code[20]): Decimal
    var
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        FinanceChargeMemoLine: Record "Finance Charge Memo Line";
    begin
        // Take Random Amount in Finance Charge Memo Line.
        LibraryERM.CreateFinanceChargeMemoHeader(FinanceChargeMemoHeader, CreateCustomer(''));
        LibraryERM.CreateFinanceChargeMemoLine(
          FinanceChargeMemoLine, FinanceChargeMemoHeader."No.", FinanceChargeMemoLine.Type::"G/L Account");
        FinanceChargeMemoLine.Validate("No.", CreateGLAccount());
        FinanceChargeMemoLine.Validate(Amount, LibraryRandom.RandInt(100));
        FinanceChargeMemoLine.Modify(true);
        FinanceChargeMemoNo := FinanceChargeMemoHeader."No.";
        exit(FinanceChargeMemoLine.Amount);
    end;

    local procedure CreateReminderTerms(var ReminderLevel: Record "Reminder Level")
    var
        ReminderTerms: Record "Reminder Terms";
    begin
        LibraryERM.CreateReminderTerms(ReminderTerms);
        CreateReminderLevel(ReminderLevel, ReminderTerms.Code);
    end;

    local procedure CreateReminderLevel(var ReminderLevel: Record "Reminder Level"; ReminderTermsCode: Code[10])
    begin
        // Take Random Grace Period and Additional Fee.
        LibraryERM.CreateReminderLevel(ReminderLevel, ReminderTermsCode);
        Evaluate(ReminderLevel."Grace Period", '<' + Format(LibraryRandom.RandInt(5)) + 'M>');
        ReminderLevel.Validate("Additional Fee (LCY)", LibraryRandom.RandInt(10));
        ReminderLevel.Validate("Calculate Interest", true);
        ReminderLevel.Modify(true);
    end;

    local procedure CreateAndPostGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; CustomerNo: Code[20]; CurrencyCode: Code[10]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, CustomerNo, Amount);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostGenJnlDocument(var GenJournalLine: Record "Gen. Journal Line")
    var
        CustomerNo: Code[20];
    begin
        CustomerNo := CreateCustomer('');
        CreateAndPostGenJournalLine(GenJournalLine, CustomerNo, '', CalculateAmountOverFinChargeMinimum(CustomerNo));
    end;

    local procedure CreateAndPostSalesOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Ship: Boolean; Invoice: Boolean): Code[20]
    var
        SalesLine: Record "Sales Line";
        AssemblyHeader: Record "Assembly Header";
    begin
        CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, ItemNo);
        AddComponentInventory(AssemblyHeader, ItemNo);
        LibrarySales.PostSalesDocument(SalesHeader, Ship, Invoice);
        exit(AssemblyHeader."No.");
    end;

    local procedure CreateReminder(GenJournalLine: Record "Gen. Journal Line"; GracePeriod: DateFormula)
    var
        Customer: Record Customer;
        CreateReminders: Report "Create Reminders";
        DocumentDate: Date;
    begin
        DocumentDate :=
          CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', CalcDate(GracePeriod, GenJournalLine."Posting Date"));
        Customer.SetRange("No.", GenJournalLine."Account No.");
        CreateReminders.SetTableView(Customer);
        CreateReminders.InitializeRequest(DocumentDate, DocumentDate, true, false, false);
        CreateReminders.UseRequestPage(false);
        CreateReminders.Run();
    end;

    local procedure CreateFinanceCharge(CustomerNo: Code[20])
    var
        Customer: Record Customer;
        FinanceChargeTerms: Record "Finance Charge Terms";
        CreateFinanceChargeMemos: Report "Create Finance Charge Memos";
    begin
        Customer.SetRange("No.", CustomerNo);
        CreateFinanceChargeMemos.InitializeRequest(WorkDate(), FindFinanceChargeTerms(FinanceChargeTerms, CustomerNo));
        CreateFinanceChargeMemos.SetTableView(Customer);
        CreateFinanceChargeMemos.UseRequestPage(false);
        CreateFinanceChargeMemos.Run();
    end;

    local procedure CreateSalesOrderDropShipment(var SalesLine: Record "Sales Line")
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');

        // Use Random because value is not important.
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Drop Shipment", true);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrderWithSpecialOrderAndDropShipment(var SalesHeader: Record "Sales Header")
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
    begin
        CreateCustomerWithAddress(Customer, CreateLocation());
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        CreateSpecialOrderLine(SalesLine, SalesHeader);
        CreateDropShipmentLine(SalesLine, SalesHeader);
    end;

    local procedure CreateAndPostSalesInvoiceUsingGetShipmentLines(CustomerNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesLine.Validate("Document Type", SalesHeader."Document Type");
        SalesLine.Validate("Document No.", SalesHeader."No.");
        LibrarySales.GetShipmentLines(SalesLine);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateWarehouseReceiptHeader(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; LocationCode: Code[10])
    begin
        LibraryWarehouse.CreateWarehouseReceiptHeader(WarehouseReceiptHeader);
        WarehouseReceiptHeader.Validate("Location Code", LocationCode);
        WarehouseReceiptHeader.Modify(true);
    end;

    local procedure CreatePostWhseReceiptFromPOWithPostingDate(var PurchaseHeader: Record "Purchase Header"; PostingDate: Date)
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        PurchaseHeader.Find();
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        WarehouseReceiptHeader.Get(
          LibraryWarehouse.FindWhseReceiptNoBySourceDoc(
            DATABASE::"Purchase Line", PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No."));
        WarehouseReceiptHeader.Validate("Posting Date", PostingDate);
        WarehouseReceiptHeader.Modify(true);
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
    end;

    local procedure CreatePostWhseShipmentFromPROWithPostingDate(PurchaseHeader: Record "Purchase Header"; PostingDate: Date)
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        PurchaseHeader.Find();
        LibraryWarehouse.CreateWhseShipmentFromPurchaseReturnOrder(PurchaseHeader);
        WarehouseShipmentHeader.Get(
          LibraryWarehouse.FindWhseShipmentNoBySourceDoc(
            DATABASE::"Purchase Line", PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No."));
        WarehouseShipmentHeader.Validate("Posting Date", PostingDate);
        WarehouseShipmentHeader.Modify(true);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);
    end;

    local procedure CreatePostWhseShipmentFromSOWithPostingDate(SalesHeader: Record "Sales Header"; PostingDate: Date)
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        SalesHeader.Find();
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        WarehouseShipmentHeader.Get(
          LibraryWarehouse.FindWhseShipmentNoBySourceDoc(
            DATABASE::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No."));
        WarehouseShipmentHeader.Validate("Posting Date", PostingDate);
        WarehouseShipmentHeader.Modify(true);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);
    end;

    local procedure CreatePostWhseReceiptFromSROWithPostingDate(SalesHeader: Record "Sales Header"; PostingDate: Date)
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        SalesHeader.Find();
        LibraryWarehouse.CreateWhseReceiptFromSalesReturnOrder(SalesHeader);
        WarehouseReceiptHeader.Get(
          LibraryWarehouse.FindWhseReceiptNoBySourceDoc(
            DATABASE::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No."));
        WarehouseReceiptHeader.Validate("Posting Date", PostingDate);
        WarehouseReceiptHeader.Modify(true);
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
    end;

    local procedure CreateAndPostSalesOrderWithPrepayment(LineGLAccount: Record "G/L Account"): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomerWithPrepayment(LineGLAccount));
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LineGLAccount."No.", LibraryRandom.RandInt(100));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(1000, 2));
        SalesLine.Modify(true);
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        exit(SalesHeader."No.");
    end;

    local procedure CreateAndPostPurchaseOrderWithPrepayment(LineGLAccount: Record "G/L Account"): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendorWithPrepayment(LineGLAccount));
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LineGLAccount."No.", LibraryRandom.RandInt(100));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(1000, 2));
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
        exit(PurchaseHeader."No.");
    end;

    local procedure CreateCustomerWithPrepayment(LineGLAccount: Record "G/L Account"): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Gen. Bus. Posting Group", LineGLAccount."Gen. Bus. Posting Group");
        Customer.Validate("VAT Bus. Posting Group", LineGLAccount."VAT Bus. Posting Group");
        Customer.Validate("Prepayment %", LibraryRandom.RandInt(50));
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        GenProductPostingGroup.SetFilter("Def. VAT Prod. Posting Group", '<>%1', '');
        GenProductPostingGroup.FindFirst();
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Posting Type", GLAccount."Gen. Posting Type"::Sale);
        GLAccount.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        GLAccount.Validate("Gen. Prod. Posting Group", GenProductPostingGroup.Code);
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateVendorWithPrepayment(LineGLAccount: Record "G/L Account"): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Gen. Bus. Posting Group", LineGLAccount."Gen. Bus. Posting Group");
        Vendor.Validate("VAT Bus. Posting Group", LineGLAccount."VAT Bus. Posting Group");
        Vendor.Validate("Prepayment %", LibraryRandom.RandInt(50));
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateReqWkshTemplateName(var RequisitionWkshName: Record "Requisition Wksh. Name"; var ReqWkshTemplate: Record "Req. Wksh. Template")
    begin
        ReqWkshTemplate.SetRange(Type, ReqWkshTemplate.Type::"Req.");
        ReqWkshTemplate.FindFirst();
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
    end;

    local procedure CreateSalesOrderWithDropShipAndShipToCode(var SalesHeader: Record "Sales Header"; var ItemNo: Code[20]; var CountryCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Ship-to Code", CreateShipToAddress(CountryCode, SalesHeader."Sell-to Customer No."));
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), 10 + LibraryRandom.RandDec(10, 2));
        ItemNo := SalesLine."No.";
        SalesLine.Validate("Drop Shipment", true);
        SalesLine.Modify(true);
    end;

    local procedure CreateShipToAddress(var CountryCode: Code[10]; CustNo: Code[20]): Code[10]
    var
        ShipToAddress: Record "Ship-to Address";
    begin
        CountryCode := CreateNewCountryCode();
        ShipToAddress.Init();
        ShipToAddress."Customer No." := CustNo;
        ShipToAddress.Code := LibraryUtility.GenerateRandomCode(ShipToAddress.FieldNo(Code), DATABASE::"Ship-to Address");
        ShipToAddress."Country/Region Code" := CountryCode;
        ShipToAddress.Insert();
        exit(ShipToAddress.Code);
    end;

    local procedure CreateNewCountryCode(): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.Init();
        CountryRegion.Code := LibraryUtility.GenerateRandomCode(CountryRegion.FieldNo(Code), DATABASE::"Country/Region");
        CountryRegion.Insert();
        exit(CountryRegion.Code);
    end;

    local procedure CalculateAmountOverFinChargeMinimum(CustomerNo: Code[20]): Decimal
    var
        FinanceChargeTerms: Record "Finance Charge Terms";
        BaseAmount: Decimal;
    begin
        FindFinanceChargeTerms(FinanceChargeTerms, CustomerNo);
        if FinanceChargeTerms."Interest Rate" <> 0 then
            BaseAmount := Round(FinanceChargeTerms."Minimum Amount (LCY)" / FinanceChargeTerms."Interest Rate" * 100);
        exit(BaseAmount + LibraryRandom.RandInt(100));
    end;

    local procedure CarryOutActionMsgOnReqWkshForDropShipmentBatch(SalesHeader: Record "Sales Header"; SalesHeader2: Record "Sales Header"; SalesLine: Record "Sales Line"; SalesLine2: Record "Sales Line")
    var
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        CreateReqWkshTemplateName(RequisitionWkshName, ReqWkshTemplate);
        GetSalesOrderForDropShipmentOnReqWksh(RequisitionLine, SalesHeader, SalesLine, RequisitionWkshName.Name, ReqWkshTemplate.Name);
        GetSalesOrderForDropShipmentOnReqWksh(RequisitionLine, SalesHeader2, SalesLine2, RequisitionWkshName.Name, ReqWkshTemplate.Name);
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, WorkDate(), WorkDate(), WorkDate(), WorkDate(), '');
    end;

    local procedure CarryOutActionMsgOnReqWkshForDropShipment(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line")
    var
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        CreateReqWkshTemplateName(RequisitionWkshName, ReqWkshTemplate);
        GetSalesOrderForDropShipmentOnReqWksh(RequisitionLine, SalesHeader, SalesLine, RequisitionWkshName.Name, ReqWkshTemplate.Name);
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, WorkDate(), WorkDate(), WorkDate(), WorkDate(), '');
    end;

    local procedure CarryOutActionMsgOnReqWkshForSpecialOrder(SalesHeader: Record "Sales Header"; SalesHeader2: Record "Sales Header"; SalesLine: Record "Sales Line"; SalesLine2: Record "Sales Line")
    var
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        CreateReqWkshTemplateName(RequisitionWkshName, ReqWkshTemplate);
        GetSalesOrderForSpecialOrderOnReqWksh(RequisitionLine, SalesHeader, SalesLine, RequisitionWkshName.Name, ReqWkshTemplate.Name);
        GetSalesOrderForSpecialOrderOnReqWksh(RequisitionLine, SalesHeader2, SalesLine2, RequisitionWkshName.Name, ReqWkshTemplate.Name);
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, WorkDate(), WorkDate(), WorkDate(), WorkDate(), '');
    end;

    local procedure DeleteBlanketPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; No: Code[20])
    var
        DeleteInvdBlnktPurchOrders: Report "Delete Invd Blnkt Purch Orders";
    begin
        PurchaseHeader.SetRange("Document Type", DocumentType);
        PurchaseHeader.SetRange("No.", No);
        DeleteInvdBlnktPurchOrders.SetTableView(PurchaseHeader);
        DeleteInvdBlnktPurchOrders.UseRequestPage(false);
        DeleteInvdBlnktPurchOrders.Run();
    end;

    local procedure DeleteSalesBlanketOrder(var SalesHeader: Record "Sales Header"; BlankedOrderNo: Code[20])
    var
        DeleteInvdBlnktSalesOrders: Report "Delete Invd Blnkt Sales Orders";
    begin
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::"Blanket Order");
        SalesHeader.SetRange("No.", BlankedOrderNo);
        DeleteInvdBlnktSalesOrders.SetTableView(SalesHeader);
        DeleteInvdBlnktSalesOrders.UseRequestPage(false);
        DeleteInvdBlnktSalesOrders.Run();
    end;

    local procedure DeleteInvoiceSalesOrder(var SalesHeader: Record "Sales Header"; DocumentNo: Code[20])
    var
        DeleteInvoicedSalesOrders: Report "Delete Invoiced Sales Orders";
    begin
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange("No.", DocumentNo);
        DeleteInvoicedSalesOrders.SetTableView(SalesHeader);
        DeleteInvoicedSalesOrders.UseRequestPage(false);
        DeleteInvoicedSalesOrders.Run();
    end;

    local procedure FindAndUpdateCurrency(var Currency: Record Currency)
    begin
        LibraryERM.FindCurrency(Currency);
        Currency.Validate("Amount Rounding Precision", LibraryRandom.RandDec(5, 2));  // Use random value for Amount Rounding Precision.
        Currency.Modify(true);
    end;

    local procedure FindInterestAmount(CustomerNo: Code[20]; TotalDays: Integer; Amount: Decimal): Decimal
    var
        FinanceChargeTerms: Record "Finance Charge Terms";
    begin
        FindFinanceChargeTerms(FinanceChargeTerms, CustomerNo);
        Amount := (Amount * FinanceChargeTerms."Interest Rate") / 100;
        exit((Amount * TotalDays) / FinanceChargeTerms."Interest Period (Days)");
    end;

    local procedure FindIssuedReminder(var IssuedReminderHeader: Record "Issued Reminder Header"; CustomerNo: Code[20])
    begin
        IssuedReminderHeader.SetRange("Customer No.", CustomerNo);
        IssuedReminderHeader.FindFirst();
    end;

    local procedure FindFinanceChargeTerms(var FinanceChargeTerms: Record "Finance Charge Terms"; CustomerNo: Code[20]): Date
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        FinanceChargeTerms.Get(Customer."Fin. Charge Terms Code");
        exit(CalcDate(FinanceChargeTerms."Grace Period", CalcDate(FinanceChargeTerms."Due Date Calculation", WorkDate())));
    end;

    local procedure FindRequisitionWkshName(var RequisitionWkshName: Record "Requisition Wksh. Name")
    begin
        RequisitionWkshName.SetRange("Template Type", RequisitionWkshName."Template Type"::"Req.");
        RequisitionWkshName.FindFirst();
    end;

    local procedure FindGLRegister(var GLRegister: Record "G/L Register"; JournalBatchName: Code[10]): Boolean
    begin
        GLRegister.SetRange("Journal Batch Name", JournalBatchName);
        exit(GLRegister.FindFirst())
    end;

    local procedure FindPurchLine(var PurchaseLine: Record "Purchase Line"; PurchHeaderNo: Code[20])
    begin
        PurchaseLine.SetRange("Document No.", PurchHeaderNo);
        PurchaseLine.FindFirst();
    end;

    local procedure FindWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceType: Integer; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    begin
        WarehouseActivityLine.SetRange("Source Type", SourceType);
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.FindFirst();
    end;

    local procedure FindAndUpdateWhseActivityPostingDate(var WarehouseActivityHeader: Record "Warehouse Activity Header"; var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceType: Integer; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type"; PostingDate: Date)
    begin
        FindWarehouseActivityLine(WarehouseActivityLine, SourceType, SourceNo, ActivityType);
        WarehouseActivityHeader.Get(ActivityType, WarehouseActivityLine."No.");
        WarehouseActivityHeader.Validate("Posting Date", PostingDate);
        WarehouseActivityHeader.Modify(true);
    end;

    local procedure GetPurchHeader(var PurchHeader: Record "Purchase Header"; No: Code[20])
    var
        PurchLine: Record "Purchase Line";
    begin
        PurchLine.Reset();
        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
        PurchLine.SetRange(Type, PurchLine.Type::Item);
        PurchLine.SetRange("No.", No);
        PurchLine.FindFirst();
        PurchHeader.Get(PurchLine."Document Type"::Order, PurchLine."Document No.");
    end;

    local procedure GetSpecialOrderOnReqWksht(var SalesLine: Record "Sales Line"; var RequisitionLine: Record "Requisition Line"; RequisitionWkshName: Code[10]; ReqWkshTemplate: Code[10])
    begin
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, ReqWkshTemplate, RequisitionWkshName);
        LibraryPlanning.GetSpecialOrder(RequisitionLine, SalesLine."No.");
    end;

    local procedure GetDropShipmentOnReqWksht(var SalesLine: Record "Sales Line"; var RequisitionLine: Record "Requisition Line"; RequisitionWkshName: Code[10]; ReqWkshTemplate: Code[10])
    var
        RetrieveDimensionsFrom: array[2] of Option Item,"Sales Line";
    begin
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, ReqWkshTemplate, RequisitionWkshName);
        LibraryPlanning.GetSalesOrders(SalesLine, RequisitionLine, RetrieveDimensionsFrom::"Sales Line");
    end;

    local procedure GetSalesOrderForDropShipmentOnReqWksh(var RequisitionLine: Record "Requisition Line"; SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; RequisitionWkshName: Code[10]; ReqWkshTemplateName: Code[10])
    begin
        SelectSalesLineWithDropShipment(SalesLine, SalesHeader);
        GetDropShipmentOnReqWksht(SalesLine, RequisitionLine, RequisitionWkshName, ReqWkshTemplateName);
    end;

    local procedure GetSalesOrderForSpecialOrderOnReqWksh(var RequisitionLine: Record "Requisition Line"; SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; RequisitionWkshName: Code[10]; ReqWkshTemplateName: Code[10])
    begin
        SelectSalesLineWithSpecialOrder(SalesLine, SalesHeader);
        GetSpecialOrderOnReqWksht(SalesLine, RequisitionLine, RequisitionWkshName, ReqWkshTemplateName);
    end;

    local procedure GeneralSetupForReqwkshGetSalesOrder(var SalesHeader: Record "Sales Header"; var SalesHeader2: Record "Sales Header"; var SalesLine: Record "Sales Line"; var SalesLine2: Record "Sales Line"; SpecialOrder: Boolean)
    var
        Customer: Record Customer;
        PurchasingCode: Code[10];
        VendorNo: Code[20];
    begin
        CreateCustomerWithAddress(Customer, CreateLocation());
        VendorNo := LibraryPurchase.CreateVendorNo();
        if SpecialOrder then
            PurchasingCode := CreatePurchasingCode()
        else
            PurchasingCode := CreatePurchasingCodeWithDropShipment();
        CreateSalesOrderWithPurchasingCode(SalesHeader, SalesLine, Customer."No.", PurchasingCode, VendorNo);
        CreateSalesOrderWithPurchasingCode(SalesHeader2, SalesLine2, Customer."No.", PurchasingCode, VendorNo);
    end;

    local procedure IssueFinanceChargeMemo(No: Code[20])
    var
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
    begin
        FinanceChargeMemoHeader.Get(No);
        LibraryERM.IssueFinanceChargeMemo(FinanceChargeMemoHeader);
    end;

    local procedure IssueReminder(CustomerNo: Code[20])
    var
        ReminderHeader: Record "Reminder Header";
        ReminderIssue: Codeunit "Reminder-Issue";
    begin
        ReminderHeader.SetRange("Customer No.", CustomerNo);
        ReminderHeader.FindFirst();
        ReminderIssue.Set(ReminderHeader, false, WorkDate());
        LibraryERM.RunReminderIssue(ReminderIssue);
    end;

    local procedure ModifyPurchaseHeader(var PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; VendorInvoiceNo: Code[20])
    begin
        PurchaseLine.SetRange("Blanket Order No.", PurchaseLine."Document No.");
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.FindFirst();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchaseHeader.Validate("Vendor Invoice No.", VendorInvoiceNo);
        PurchaseHeader.Modify(true);
    end;

    local procedure ModifySalesHeaderWithMultipleAddress(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.Validate("Ship-to Address 2", 'Address 2:' + SalesHeader."Sell-to Customer No.");
        SalesHeader.Modify(true);
    end;

    local procedure ModifySalesOrderWithLocationCode(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        SalesHeader.Validate("Location Code", '');
        SalesHeader.Modify(true);
        SalesLine.Validate("Location Code", '');
        SalesLine.Modify(true);
    end;

    local procedure PurchaseCopyDocument(PurchaseHeader: Record "Purchase Header"; DocumentNo: Code[20]; DocumentType: Enum "Purchase Document Type From")
    var
        CopyPurchaseDocument: Report "Copy Purchase Document";
    begin
        CopyPurchaseDocument.SetPurchHeader(PurchaseHeader);
        CopyPurchaseDocument.SetParameters(DocumentType, DocumentNo, true, false);
        CopyPurchaseDocument.UseRequestPage(false);
        CopyPurchaseDocument.Run();
    end;

    local procedure PrepareUserSetupAndCreateWorkflow(WorkflowCode: Code[17])
    var
        UserSetup: Record "User Setup";
        Workflow: Record Workflow;
    begin
        LibraryDocumentApprovals.SetupUserWithApprover(UserSetup);
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowCode);
        LibraryWorkflow.SetWorkflowDirectApprover(Workflow.Code);
    end;

    local procedure RunPostBatchSalesOrder(SalesHeaderNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        Commit();  // Commit is used to avoid Test failure.
        SalesHeader.SetRange("No.", SalesHeaderNo);
        REPORT.Run(REPORT::"Batch Post Sales Orders", true, false, SalesHeader);
    end;

    local procedure SetCheckPrepmtWhenPostingPurchase(CheckPrepmtwhenPosting: Boolean)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Check Prepmt. when Posting", CheckPrepmtwhenPosting);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure SetCheckPrepmtWhenPostingSales(CheckPrepmtwhenPosting: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Check Prepmt. when Posting", CheckPrepmtwhenPosting);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure RemovePrepmtVATSetup(GLAccount: Record "G/L Account")
    var
        GenPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.SetRange("VAT Bus. Posting Group", GLAccount."VAT Bus. Posting Group");
        VATPostingSetup.DeleteAll();
        GenPostingSetup.SetRange("Gen. Bus. Posting Group", GLAccount."Gen. Bus. Posting Group");
        GenPostingSetup.DeleteAll();
    end;

    local procedure RunBatchPostPurchaseOrders(DocNoFilter: Text; Receive: Boolean; Invoice: Boolean; PostingDate: Date; ReplacePostingDate: Boolean; ReplaceDocDate: Boolean; CalcInvDiscount: Boolean)
    var
        PurchaseHeaderToPost: Record "Purchase Header";
        BatchPostPurchaseOrders: Report "Batch Post Purchase Orders";
    begin
        Commit();
        PurchaseHeaderToPost.SetFilter("No.", DocNoFilter);
        BatchPostPurchaseOrders.SetTableView(PurchaseHeaderToPost);
        BatchPostPurchaseOrders.InitializeRequest(Receive, Invoice, PostingDate, PostingDate, ReplacePostingDate, ReplaceDocDate, ReplacePostingDate, CalcInvDiscount);
        BatchPostPurchaseOrders.UseRequestPage(false);
        BatchPostPurchaseOrders.Run();
    end;

    local procedure RunBatchPostSalesReturnOrdersReport(No: Code[20]; Receive: Boolean; Invoice: Boolean)
    var
        SalesHeader: Record "Sales Header";
        BatchPostSalesReturnOrders: Report "Batch Post Sales Return Orders";
    begin
        Commit();
        LibraryVariableStorage.Enqueue(Receive);
        LibraryVariableStorage.Enqueue(Invoice);
        SalesHeader.SetRange("No.", No);
        BatchPostSalesReturnOrders.SetTableView(SalesHeader);
        BatchPostSalesReturnOrders.UseRequestPage(true);
        BatchPostSalesReturnOrders.Run();
    end;

    local procedure RunGetSalesOrders(SalesLine: Record "Sales Line")
    var
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        GetSalesOrders: Report "Get Sales Orders";
        RetrieveDimensionsFrom: Option Item,"Sales Line";
    begin
        FindRequisitionWkshName(RequisitionWkshName);
        RequisitionLine.Init();
        RequisitionLine.Validate("Worksheet Template Name", RequisitionWkshName."Worksheet Template Name");
        RequisitionLine.Validate("Journal Batch Name", RequisitionWkshName.Name);

        SalesLine.SetRange("Document Type", SalesLine."Document Type");
        SalesLine.SetRange("Document No.", SalesLine."Document No.");
        GetSalesOrders.SetTableView(SalesLine);
        GetSalesOrders.SetReqWkshLine(RequisitionLine, 0);
        GetSalesOrders.InitializeRequest(RetrieveDimensionsFrom::"Sales Line");
        GetSalesOrders.UseRequestPage(false);
        GetSalesOrders.Run();
    end;

    local procedure RunDeleteEmptyGLRegisters()
    var
        DeleteEmptyGLRegisters: Report "Delete Empty G/L Registers";
    begin
        DeleteEmptyGLRegisters.UseRequestPage(false);
        DeleteEmptyGLRegisters.Run();
    end;

    local procedure RunDeleteInvoicedSalesOrdersReport(DocumentType: Enum "Sales Document Type"; SalesHeaderNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.SetRange("Document Type", DocumentType);
        SalesHeader.SetRange("No.", SalesHeaderNo);
        REPORT.Run(REPORT::"Delete Invoiced Sales Orders", true, false, SalesHeader);
    end;

    local procedure RunCopyGeneralPostingSetup(GeneralPostingSetup: Record "General Posting Setup")
    var
        CopyGeneralPostingSetup: Report "Copy - General Posting Setup";
    begin
        Commit();  // COMMIT required for batch report.
        CopyGeneralPostingSetup.SetGenPostingSetup(GeneralPostingSetup);
        CopyGeneralPostingSetup.Run();
    end;

    local procedure RunCopyVATPostingSetup(VATPostingSetup: Record "VAT Posting Setup")
    var
        CopyVATPostingSetup: Report "Copy - VAT Posting Setup";
    begin
        Commit();  // COMMIT required for batch report.
        CopyVATPostingSetup.SetVATSetup(VATPostingSetup);
        CopyVATPostingSetup.Run();
    end;

    local procedure SalesCopyDocument(SalesHeader: Record "Sales Header"; DocumentNo: Code[20]; DocumentType: Enum "Sales Document Type From")
    var
        CopySalesDocument: Report "Copy Sales Document";
    begin
        CopySalesDocument.SetSalesHeader(SalesHeader);
        CopySalesDocument.SetParameters(DocumentType, DocumentNo, true, false);
        CopySalesDocument.UseRequestPage(false);
        CopySalesDocument.Run();
    end;

    local procedure SetupInvoiceDiscount(var VendorInvoiceDisc: Record "Vendor Invoice Disc.")
    begin
        // Required Random Value for "Discount %" fields value is not important.
        LibraryERM.CreateInvDiscForVendor(VendorInvoiceDisc, LibraryPurchase.CreateVendorNo(), '', 0);
        VendorInvoiceDisc.Validate("Discount %", LibraryRandom.RandDec(10, 2));
        VendorInvoiceDisc.Modify(true);
    end;

    local procedure SalesPostBatch(var SalesHeader: array[2] of Record "Sales Header"; PostingDate: Date; Ship: Boolean; Invoice: Boolean)
    var
        SalesHeaderToPost: Record "Sales Header";
        BatchPostSalesOrders: Report "Batch Post Sales Orders";
    begin
        SalesHeaderToPost.SetRange("Document Type", SalesHeaderToPost."Document Type"::Order);
        SalesHeaderToPost.SetFilter("No.", '%1|%2', SalesHeader[1]."No.", SalesHeader[2]."No.");
        BatchPostSalesOrders.SetTableView(SalesHeaderToPost);
        BatchPostSalesOrders.UseRequestPage(false);
        BatchPostSalesOrders.InitializeRequest(Ship, Invoice, PostingDate, PostingDate, true, true, true, false);
        BatchPostSalesOrders.Run();
    end;

    local procedure SalesPostBatchShipInvoice(var SalesHeader: array[2] of Record "Sales Header")
    var
        SalesHeaderToPost: Record "Sales Header";
        BatchPostSalesOrders: Report "Batch Post Sales Orders";
    begin
        SalesHeaderToPost.SetRange("Document Type", SalesHeaderToPost."Document Type"::Order);
        SalesHeaderToPost.SetFilter("No.", '%1|%2', SalesHeader[1]."No.", SalesHeader[2]."No.");
        BatchPostSalesOrders.SetTableView(SalesHeaderToPost);
        BatchPostSalesOrders.UseRequestPage(false);
        BatchPostSalesOrders.InitializeRequest(true, true, 0D, 0D, false, false, false, false);
        BatchPostSalesOrders.Run();
    end;

    local procedure SelectSalesLineWithSpecialOrder(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetRange("Special Order", true);
        SalesLine.FindFirst();
    end;

    local procedure SelectSalesLineWithDropShipment(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetRange("Drop Shipment", true);
        SalesLine.FindFirst();
    end;

    local procedure SetupBatchPostPurchaseOrders(var PurchaseHeader: array[2] of Record "Purchase Header"; PostingDate: Date; ReplacePostingDate: Boolean; ReplaceDocumentDate: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        Index: Integer;
    begin
        // Setup: Create and Post Purchase Order.
        LibraryPurchase.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        for Index := 1 to ArrayLen(PurchaseHeader) do begin
            Clear(PurchaseLine);
            CreateAndGetPurchaseDocumentNo(PurchaseLine, LibraryPurchase.CreateVendorNo());
            PurchaseHeader[Index].Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

            // Exercise.
        end;

        RunBatchPostPurchaseOrders(
            StrSubstNo('%1|%2', PurchaseHeader[1]."No.", PurchaseHeader[2]."No."),
            true, true, PostingDate, ReplacePostingDate, ReplaceDocumentDate, false);

        for Index := 1 to ArrayLen(PurchaseHeader) do
            LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader[Index].RecordId);
    end;

    local procedure SuggestFinChargeMemoLine(FinanceChargeMemoHeaderNo: Code[20])
    var
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        SuggestFinChargeMemoLines: Report "Suggest Fin. Charge Memo Lines";
    begin
        FinanceChargeMemoHeader.SetRange("No.", FinanceChargeMemoHeaderNo);
        SuggestFinChargeMemoLines.SetTableView(FinanceChargeMemoHeader);
        SuggestFinChargeMemoLines.UseRequestPage(false);
        SuggestFinChargeMemoLines.Run();
    end;

    local procedure UpdatePurchLineQtyToReceive(PurchHeaderNo: Code[20]; QtyToReceive: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document No.", PurchHeaderNo);
        PurchaseLine.FindFirst();
        PurchaseLine.Validate("Qty. to Receive", QtyToReceive);
        PurchaseLine.Modify();
    end;

    local procedure UpdateSalesLineQtyToShip(SalesHeaderNo: Code[20]; QtyToShip: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document No.", SalesHeaderNo);
        SalesLine.FindFirst();
        SalesLine.Validate("Qty. to Ship", QtyToShip);
        SalesLine.Modify();
    end;

    local procedure FillGenPostingSetup(var GenPostingSetup: Record "General Posting Setup")
    begin
        GenPostingSetup."Sales Pmt. Tol. Debit Acc." := LibraryERM.CreateGLAccountNo();
        GenPostingSetup."Sales Pmt. Tol. Credit Acc." := LibraryERM.CreateGLAccountNo();
        GenPostingSetup."Purch. Pmt. Tol. Debit Acc." := LibraryERM.CreateGLAccountNo();
        GenPostingSetup."Purch. Pmt. Tol. Credit Acc." := LibraryERM.CreateGLAccountNo();
        GenPostingSetup.Modify();
    end;

    local procedure UpdateVATIdentifierForVATpostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATPostingSetup."VAT Identifier" := LibraryUtility.GenerateRandomCode(13, 325);
        VATPostingSetup.Modify();
    end;

    local procedure UpdateCopyCommentsOnSalesPurchaseSetup()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Copy Comments Order to Shpt." := true;
        SalesReceivablesSetup.Modify();
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Copy Comments Order to Receipt" := true;
        PurchasesPayablesSetup.Modify();
    end;

    local procedure UpdateShipToAddressOnSalesHeader(var SalesHeader: Record "Sales Header")
    var
        CountryRegion: Record "Country/Region";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        SalesHeader."Ship-to Address" := LibraryUtility.GenerateGUID();
        SalesHeader."Ship-to Address 2" := LibraryUtility.GenerateGUID();
        SalesHeader."Ship-to Post Code" := LibraryUtility.GenerateGUID();
        SalesHeader."Ship-to City" := LibraryUtility.GenerateGUID();
        SalesHeader."Ship-to Contact" := LibraryUtility.GenerateGUID();
        SalesHeader."Ship-to County" := LibraryUtility.GenerateGUID();
        SalesHeader."Ship-to Country/Region Code" := CountryRegion.Code;
        SalesHeader."Ship-to Phone No." := LibraryUtility.GenerateRandomPhoneNo();
        SalesHeader.Modify();
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    var
        VATBusPostingGroup: Record "VAT Business Posting Group";
        VATProdPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroup.Code, VATProdPostingGroup.Code);
    end;

    local procedure CreateLocation(): Code[10]
    var
        Location: Record Location;
    begin
        LibraryWarehouse.CreateLocation(Location);
        UpdateLocationContactDetails(Location);
        exit(Location.Code);
    end;

    local procedure UpdateLocationContactDetails(var Location: Record Location)
    begin
        Location."Phone No." := LibraryUtility.GenerateRandomPhoneNo();
        Location.Modify();
    end;

    local procedure CreateRecordLink(SourceRecord: Variant): Text[250]
    var
        RecordLink: Record "Record Link";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(SourceRecord);
        RecRef.AddLink(LibraryUtility.GenerateGUID());
        RecordLink.SetRange("Record ID", RecRef.RecordId);
        RecordLink.FindFirst();
        exit(RecordLink.URL1);
    end;

    local procedure RemoveWorkflow(Workflow: Record Workflow)
    begin
        Workflow.Validate(Enabled, false);
        Workflow.Modify(true);
        Workflow.Delete(true);
    end;

    local procedure SetGLSetupInvoiceRounding()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Inv. Rounding Precision (LCY)" := GeneralLedgerSetup."Amount Rounding Precision";
        GeneralLedgerSetup.Modify();
    end;

    local procedure VerifyCurrencyOnIssuedReminder(CurrencyCode: Code[10]; AmountRoundingPrecision: Decimal)
    var
        Currency: Record Currency;
    begin
        Currency.Get(CurrencyCode);
        Currency.TestField("Amount Rounding Precision", AmountRoundingPrecision);
    end;

    local procedure VerifyReminderLine(DocumentNo: Code[20]; Amount: Decimal)
    var
        ReminderLine: Record "Reminder Line";
        Assert: Codeunit Assert;
    begin
        ReminderLine.SetRange("Document No.", DocumentNo);
        ReminderLine.SetRange(Type, ReminderLine.Type::"Customer Ledger Entry");
        ReminderLine.FindFirst();
        Assert.AreNearlyEqual(Amount, ReminderLine.Amount, LibraryERM.GetAmountRoundingPrecision(), StrSubstNo(AmountErr, Amount));
    end;

    local procedure VerifyRequisitionLine(SalesLine: Record "Sales Line")
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", SalesLine."No.");
        RequisitionLine.FindFirst();
        RequisitionLine.TestField(Quantity, SalesLine.Quantity);
        RequisitionLine.TestField("Sales Order No.", SalesLine."Document No.");
        RequisitionLine.TestField("Sales Order Line No.", SalesLine."Line No.");
        RequisitionLine.TestField("Sell-to Customer No.", SalesLine."Sell-to Customer No.");
    end;

    local procedure VerifyIssuedFinanceChargeMemo(PreAssignedNo: Code[20]; Amount: Decimal)
    var
        IssuedFinChargeMemoLine: Record "Issued Fin. Charge Memo Line";
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
    begin
        IssuedFinChargeMemoHeader.SetRange("Pre-Assigned No.", PreAssignedNo);
        IssuedFinChargeMemoHeader.FindFirst();
        IssuedFinChargeMemoLine.SetRange("Finance Charge Memo No.", IssuedFinChargeMemoHeader."No.");
        IssuedFinChargeMemoLine.FindFirst();
        Assert.AreEqual(Amount, IssuedFinChargeMemoLine.Amount, StrSubstNo(AmountErr, Amount));
    end;

    local procedure VerifyFinanceChargeMemoLine(DocumentNo: Code[20]; RemainingAmount: Decimal)
    var
        FinanceChargeMemoLine: Record "Finance Charge Memo Line";
    begin
        FinanceChargeMemoLine.SetRange("Document No.", DocumentNo);
        FinanceChargeMemoLine.FindFirst();
        Assert.AreNearlyEqual(
          RemainingAmount, FinanceChargeMemoLine."Remaining Amount", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, RemainingAmount));
    end;

    local procedure VerifyPurchasingCodeAndSpecialOrderOnPurchaseLine(SalesLine: Record "Sales Line"; DocumentNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.SetRange("No.", SalesLine."No.");
        PurchaseLine.SetRange("Special Order Sales No.", SalesLine."Document No.");
        PurchaseLine.FindFirst();
        PurchaseLine.TestField("Purchasing Code", SalesLine."Purchasing Code");
        PurchaseLine.TestField("Special Order", SalesLine."Special Order");
    end;

    local procedure VerifyPurchasingCodeAndDropShipmentOnPurchLine(SalesLine: Record "Sales Line"; DocumentNo: Code[20])
    var
        PurchLine: Record "Purchase Line";
    begin
        PurchLine.SetRange("Document No.", DocumentNo);
        PurchLine.SetRange("No.", SalesLine."No.");
        PurchLine.SetRange("Sales Order No.", SalesLine."Document No.");
        PurchLine.FindFirst();
        PurchLine.TestField("Purchasing Code", SalesLine."Purchasing Code");
        PurchLine.TestField("Drop Shipment", SalesLine."Drop Shipment");
    end;

    local procedure VerifyWarehouseReceiptLine(PurchaseLine: Record "Purchase Line"; No: Code[20])
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        WarehouseReceiptLine.SetRange("No.", No);
        WarehouseReceiptLine.FindFirst();
        WarehouseReceiptLine.TestField("Source Document", WarehouseReceiptLine."Source Document"::"Purchase Order");
        WarehouseReceiptLine.TestField("Item No.", PurchaseLine."No.");
        WarehouseReceiptLine.TestField(Quantity, PurchaseLine.Quantity);
        WarehouseReceiptLine.TestField("Qty. to Receive", PurchaseLine.Quantity);
    end;

    local procedure VerifyWarehouseShipmentLine(SourceNo: Code[20]; ItemNo: Code[20]; Qty: Decimal)
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WarehouseShipmentLine.SetRange("Source Document", WarehouseShipmentLine."Source Document"::"Sales Order");
        WarehouseShipmentLine.SetRange("Source No.", SourceNo);
        WarehouseShipmentLine.FindFirst();
        WarehouseShipmentLine.TestField("Item No.", ItemNo);
        WarehouseShipmentLine.TestField(Quantity, Qty);
    end;

    local procedure VerifyValuesOnGenPostingSetupAllFields(GeneralPostingSetup: Record "General Posting Setup"; SalesAccount: Code[20]; SalesPmtTolDebitAcc: Code[20]; SalesPmtTolCreditAcc: Code[20]; PurchPmtTolDebitAcc: Code[20]; PurchPmtTolCreditAcc: Code[20]; SalesPrepaymentsAccount: Code[20]; PurchPrepaymentsAccount: Code[20])
    begin
        GeneralPostingSetup.Get(GeneralPostingSetup."Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        Assert.AreEqual(GeneralPostingSetup."Sales Account", SalesAccount, GeneralPostingSetup.FieldCaption("Sales Account"));
        Assert.AreEqual(GeneralPostingSetup."Sales Pmt. Tol. Debit Acc.", SalesPmtTolDebitAcc, GeneralPostingSetup.FieldCaption("Sales Pmt. Tol. Debit Acc."));
        Assert.AreEqual(GeneralPostingSetup."Sales Pmt. Tol. Credit Acc.", SalesPmtTolCreditAcc, GeneralPostingSetup.FieldCaption("Sales Pmt. Tol. Credit Acc."));
        Assert.AreEqual(GeneralPostingSetup."Purch. Pmt. Tol. Debit Acc.", PurchPmtTolDebitAcc, GeneralPostingSetup.FieldCaption("Purch. Pmt. Tol. Debit Acc."));
        Assert.AreEqual(GeneralPostingSetup."Purch. Pmt. Tol. Credit Acc.", PurchPmtTolCreditAcc, GeneralPostingSetup.FieldCaption("Purch. Pmt. Tol. Credit Acc."));
        Assert.AreEqual(GeneralPostingSetup."Sales Prepayments Account", SalesPrepaymentsAccount, GeneralPostingSetup.FieldCaption("Sales Prepayments Account"));
        Assert.AreEqual(GeneralPostingSetup."Purch. Prepayments Account", PurchPrepaymentsAccount, GeneralPostingSetup.FieldCaption("Purch. Prepayments Account"));
    end;

    local procedure VerifyValuesOnGenPostingSetupSelectedFields(GeneralPostingSetup: Record "General Posting Setup"; PurchAccount: Code[20]; COGSAccount: Code[20]; DirectCostAppliedAccount: Code[20])
    var
        GenPostingSetupSource: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(GeneralPostingSetup."Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GenPostingSetupSource.Get(LibraryVariableStorage.DequeueText(), LibraryVariableStorage.DequeueText());
        Assert.AreEqual(GeneralPostingSetup."Sales Account", GenPostingSetupSource."Sales Account", GeneralPostingSetup.FieldCaption("Sales Account"));
        Assert.AreEqual(GeneralPostingSetup."Purch. Account", PurchAccount, GeneralPostingSetup.FieldCaption("Purch. Account"));
        Assert.AreEqual(GeneralPostingSetup."COGS Account", COGSAccount, GeneralPostingSetup.FieldCaption("COGS Account"));
        Assert.AreEqual(GeneralPostingSetup."Direct Cost Applied Account", DirectCostAppliedAccount, GeneralPostingSetup.FieldCaption("Direct Cost Applied Account"));
    end;

    local procedure VerifyValuesOnVATPostingSetup(VATPostingSetup: Record "VAT Posting Setup"; VATIdentifier: Code[20])
    begin
        VATPostingSetup.Get(VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        VATPostingSetup.TestField("VAT Identifier", VATIdentifier);
    end;

    local procedure VerifyPurchShippingDetails(PurchHeader: Record "Purchase Header"; ShipToName: Text[100]; ShipToAddress: Text[100])
    begin
        PurchHeader.TestField("Ship-to Name", ShipToName);
        PurchHeader.TestField("Ship-to Address", ShipToAddress);
    end;

    local procedure VerifyPurchShippingContactDetails(PurchaseHeader: Record "Purchase Header"; ShipToPhoneNo: Text[30])
    begin
        Assert.AreEqual(ShipToPhoneNo, PurchaseHeader."Ship-to Phone No.", PurchaseHeader.FieldCaption("Ship-to Phone No."));
    end;

    local procedure VerifyShipmentItemLedgerEntry(ItemNo: Code[20]; CountryCode: Code[10])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Document Type", ItemLedgerEntry."Document Type"::"Sales Shipment");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindFirst();
        Assert.AreEqual(CountryCode, ItemLedgerEntry."Country/Region Code", '');
    end;

    local procedure VerifyPartialDropShipmentSalesILE(ItemNo: Code[20]; ExpAmount: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Document Type", ItemLedgerEntry."Document Type"::"Sales Shipment");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.CalcFields("Sales Amount (Expected)");
        Assert.AreEqual(
          ExpAmount, ItemLedgerEntry."Sales Amount (Expected)",
          StrSubstNo(ILEAmounValueErr, ItemLedgerEntry.FieldCaption("Sales Amount (Expected)")));
    end;

    local procedure VerifyPartialDropShipmentPurchaseILE(ItemNo: Code[20]; ExpAmount: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Document Type", ItemLedgerEntry."Document Type"::"Purchase Receipt");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.CalcFields("Purchase Amount (Expected)");
        Assert.AreEqual(
          ExpAmount, ItemLedgerEntry."Purchase Amount (Expected)",
          StrSubstNo(ILEAmounValueErr, ItemLedgerEntry.FieldCaption("Purchase Amount (Expected)")));
    end;

    local procedure VerifySalesHeaderArchive(DocumentType: Enum "Sales Document Type"; No: Code[20])
    var
        SalesHeaderArchive: Record "Sales Header Archive";
    begin
        SalesHeaderArchive.SetRange("Document Type", DocumentType);
        SalesHeaderArchive.SetRange("No.", No);
        SalesHeaderArchive.FindFirst();
    end;

    local procedure VerifyPurchHeaderArchive(DocumentType: Enum "Purchase Document Type"; No: Code[20])
    var
        PurchHeaderArchive: Record "Purchase Header Archive";
    begin
        PurchHeaderArchive.SetRange("Document Type", DocumentType);
        PurchHeaderArchive.SetRange("No.", No);
        PurchHeaderArchive.FindFirst();
    end;

    local procedure VerifyArchiveOfPurchOrder(PurchHeader: Record "Purchase Header"; ArchiveNumber: Integer)
    begin
        PurchHeader.CalcFields("No. of Archived Versions");
        PurchHeader.TestField("No. of Archived Versions", ArchiveNumber);
    end;

    local procedure VerifyArchiveOfSalesOrder(SalesHeader: Record "Sales Header"; ArchiveNumber: Integer)
    begin
        SalesHeader.CalcFields("No. of Archived Versions");
        SalesHeader.TestField("No. of Archived Versions", ArchiveNumber);
    end;

    local procedure VerifyPostedSalesShipmentLink(CustomerNo: Code[20]; ItemNo: Code[20]; Link: Text)
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        RecordLink: Record "Record Link";
    begin
        SalesShipmentLine.SetRange("Sell-to Customer No.", CustomerNo);
        SalesShipmentLine.SetRange("No.", ItemNo);
        SalesShipmentLine.SetFilter("Item Shpt. Entry No.", '<>0', 0);
        SalesShipmentLine.FindFirst();
        SalesShipmentHeader.Get(SalesShipmentLine."Document No.");
        RecordLink.SetRange("Record ID", SalesShipmentHeader.RecordId);
        RecordLink.FindFirst();
        RecordLink.TestField(URL1, Link);
    end;

    local procedure VerifyPostedPurchReceiptLink(VendorNo: Code[20]; ItemNo: Code[20]; Link: Text)
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        RecordLink: Record "Record Link";
    begin
        PurchRcptLine.SetRange("Buy-from Vendor No.", VendorNo);
        PurchRcptLine.SetRange("No.", ItemNo);
        PurchRcptLine.SetFilter("Item Rcpt. Entry No.", '<>0', 0);
        PurchRcptLine.FindFirst();
        PurchRcptHeader.Get(PurchRcptLine."Document No.");
        RecordLink.SetRange("Record ID", PurchRcptHeader.RecordId);
        RecordLink.FindFirst();
        RecordLink.TestField(URL1, Link);
    end;

    local procedure VerifyPurchHeaderAddress(PurchaseHeader: Record "Purchase Header"; SalesHeader: Record "Sales Header")
    begin
        PurchaseHeader.TestField("Ship-to Address", SalesHeader."Ship-to Address");
        PurchaseHeader.TestField("Ship-to Address 2", SalesHeader."Ship-to Address 2");
        PurchaseHeader.TestField("Ship-to Post Code", SalesHeader."Ship-to Post Code");
        PurchaseHeader.TestField("Ship-to City", SalesHeader."Ship-to City");
        PurchaseHeader.TestField("Ship-to Contact", SalesHeader."Ship-to Contact");
        PurchaseHeader.TestField("Ship-to County", SalesHeader."Ship-to County");
        PurchaseHeader.TestField("Ship-to Country/Region Code", SalesHeader."Ship-to Country/Region Code");
        PurchaseHeader.TestField("Ship-to Phone No.", SalesHeader."Ship-to Phone No.");
    end;

    local procedure VerifyItemLedgerEntryForItemLocationActivity(EntryType: Enum "Item Ledger Entry Type"; LocationCode: Code[10]; ItemNo: Code[20]; Qty: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.SetRange("Location Code", LocationCode);
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange(Quantity, Qty);
        Assert.RecordIsNotEmpty(ItemLedgerEntry);
    end;

    local procedure GetJobQueueEntryId(RecordIdToProcess: RecordId): Guid
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Record ID to Process", RecordIdToProcess);
        JobQueueEntry.FindFirst();
        exit(JobQueueEntry.ID);
    end;

    local procedure VerifySalesJobQueueCategoryCode(JobQueueEntryId: List of [Guid])
    var
        JobQueueCategory: Record "Job Queue Category";
        JobQueueLogEntry: Record "Job Queue Log Entry";
        InventorySetup: Record "Inventory Setup";
        i: Integer;
    begin
        if InventorySetup.UseLegacyPosting() then
            JobQueueCategory.Get(DefaultSalesCategoryCodeLbl)
        else
            JobQueueCategory.Code := ''; // already default, but just to document the intent

        for i := 1 to JobQueueEntryId.Count do begin
            JobQueueLogEntry.SetRange(ID, JobQueueEntryId.Get(i));
            JobQueueLogEntry.FindFirst();
            Assert.AreEqual(JobQueueLogEntry."Job Queue Category Code", JobQueueCategory.Code, 'Wrong job queue category code');
        end;
    end;

    local procedure VerifyPurchaseJobQueueCategoryCode(JobQueueEntryId: List of [Guid])
    var
        JobQueueCategory: Record "Job Queue Category";
        JobQueueLogEntry: Record "Job Queue Log Entry";
        i: Integer;
    begin
        JobQueueCategory.Get(DefaultPurchCategoryCodeLbl);

        for i := 1 to JobQueueEntryId.Count do begin
            JobQueueLogEntry.SetRange(ID, JobQueueEntryId.Get(i));
            JobQueueLogEntry.FindFirst();
            Assert.AreEqual(JobQueueLogEntry."Job Queue Category Code", JobQueueCategory.Code, 'Wrong job queue category code');
        end;
    end;

    local procedure ExecuteUIHandlers()
    begin
        if Confirm('') then;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BatchPostSalesOrderRequestPageHandler(var BatchPostSalesOrders: TestRequestPage "Batch Post Sales Orders")
    begin
        BatchPostSalesOrders.Ship.SetValue(true);
        BatchPostSalesOrders.Invoice.SetValue(true);
        BatchPostSalesOrders.PostingDate.SetValue(WorkDate());
        BatchPostSalesOrders.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BatchPostSalesReturnOrdersPageHandler(var BatchPostSalesReturnOrders: TestRequestPage "Batch Post Sales Return Orders")
    begin
        BatchPostSalesReturnOrders.ReceiveReq.SetValue(LibraryVariableStorage.DequeueBoolean());
        BatchPostSalesReturnOrders.InvReq.SetValue(LibraryVariableStorage.DequeueBoolean());
        BatchPostSalesReturnOrders.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreatePickReportHandler(var CreatePickReqPage: TestRequestPage "Create Invt Put-away/Pick/Mvmt")
    begin
        CreatePickReqPage.CInvtPick.SetValue(true);
        CreatePickReqPage.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure ExpectedMessageHandler(Message: Text[1024])
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);
        Assert.ExpectedMessage(ExpectedMessage, Message);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Message Handler.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalFormHandler(var GetShipmentLines: Page "Get Shipment Lines"; var Response: Action)
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        // Run Get Shipment Lines Form.
        SalesShipmentHeader.SetRange("Order No.", LibraryVariableStorage.DequeueText());
        SalesShipmentHeader.FindFirst();
        SalesShipmentLine.SetRange("Document No.", SalesShipmentHeader."No.");
        SalesShipmentLine.FindFirst();
        GetShipmentLines.SetTableView(SalesShipmentLine);
        GetShipmentLines.SetRecord(SalesShipmentLine);
        GetShipmentLines.CreateLines();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SourceDocumentsPageHandler(var SourceDocuments: Page "Source Documents"; var Response: Action)
    var
        WarehouseRequest: Record "Warehouse Request";
    begin
        WarehouseRequest.SetRange("Source Document", WarehouseRequest."Source Document"::"Purchase Order");
        WarehouseRequest.SetRange("Source No.", LibraryVariableStorage.DequeueText());
        WarehouseRequest.FindFirst();
        SourceDocuments.SetRecord(WarehouseRequest);
        Response := ACTION::LookupOK;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DateCompressGenLedgerHandler(var DateCompressGeneralLedger: TestRequestPage "Date Compress General Ledger")
    var
        DateComprRegister: Record "Date Compr. Register";
        DateCompression: Codeunit "Date Compression";
    begin
        // Perform Date Compression with Retain field is set to True.
        DateCompressGeneralLedger."EntrdDateComprReg.""Starting Date""".SetValue(LibraryFiscalYear.GetFirstPostingDate(true));
        DateCompressGeneralLedger.EndingDate.SetValue(DateCompression.CalcMaxEndDate());
        DateCompressGeneralLedger."EntrdDateComprReg.""Period Length""".SetValue(DateComprRegister."Period Length"::Week);
        DateCompressGeneralLedger."Retain[1]".SetValue(true);
        DateCompressGeneralLedger."Retain[2]".SetValue(true);
        DateCompressGeneralLedger."Retain[3]".SetValue(true);
        DateCompressGeneralLedger."Retain[4]".SetValue(true);
        DateCompressGeneralLedger."Retain[7]".SetValue(true);
        DateCompressGeneralLedger.RetainDimText.AssistEdit();
        DateCompressGeneralLedger.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DimensionSelectionHandler(var DimensionSelectionMultiple: TestPage "Dimension Selection-Multiple")
    begin
        // Set Dimension Selection Multiple for all the rows.
        DimensionSelectionMultiple.First();
        repeat
            DimensionSelectionMultiple.Selected.SetValue(true);
        until not DimensionSelectionMultiple.Next();
        DimensionSelectionMultiple.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CopyGeneralPostingSetupHandler(var CopyGeneralPostingSetup: TestRequestPage "Copy - General Posting Setup")
    var
        GenPostingSetupSource: Record "General Posting Setup";
    begin
        GenPostingSetupSource.SetFilter("Sales Account", '<>%1', '');
        GenPostingSetupSource.SetFilter("Purch. Account", '<>%1', '');
        GenPostingSetupSource.SetFilter("COGS Account", '<>%1', '');
        GenPostingSetupSource.SetFilter("Direct Cost Applied Account", '<>%1', '');
        LibraryERM.FindGeneralPostingSetup(GenPostingSetupSource);
        LibraryVariableStorage.Enqueue(GenPostingSetupSource."Gen. Bus. Posting Group");
        LibraryVariableStorage.Enqueue(GenPostingSetupSource."Gen. Prod. Posting Group");
        CopyGeneralPostingSetup.GenBusPostingGroup.SetValue(GenPostingSetupSource."Gen. Bus. Posting Group");
        CopyGeneralPostingSetup.GenProdPostingGroup.SetValue(GenPostingSetupSource."Gen. Prod. Posting Group");
        CopyGeneralPostingSetup.Copy.SetValue(SelectionRef::"Selected fields");
        CopyGeneralPostingSetup.SalesAccounts.SetValue(LibraryVariableStorage.DequeueBoolean());
        CopyGeneralPostingSetup.PurchaseAccounts.SetValue(LibraryVariableStorage.DequeueBoolean());
        CopyGeneralPostingSetup.InventoryAccounts.SetValue(LibraryVariableStorage.DequeueBoolean());
        CopyGeneralPostingSetup.ManufacturingAccounts.SetValue(LibraryVariableStorage.DequeueBoolean());
        CopyGeneralPostingSetup.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CopyGeneralPostingSetupHandlerWithQueue(var CopyGeneralPostingSetup: TestRequestPage "Copy - General Posting Setup")
    begin
        CopyGeneralPostingSetup.GenBusPostingGroup.SetValue(LibraryVariableStorage.DequeueText());
        CopyGeneralPostingSetup.GenProdPostingGroup.SetValue(LibraryVariableStorage.DequeueText());
        CopyGeneralPostingSetup.Copy.SetValue(SelectionRef::"All fields");
        CopyGeneralPostingSetup.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CopyVATPostingSetupHandlerWithQueue(var CopyVATPostingSetup: TestRequestPage "Copy - VAT Posting Setup")
    begin
        CopyVATPostingSetup.VATBusPostingGroup.SetValue(LibraryVariableStorage.DequeueText());
        CopyVATPostingSetup.VATProdPostingGroup.SetValue(LibraryVariableStorage.DequeueText());
        CopyVATPostingSetup.Copy.SetValue(SelectionRef::"All fields");

        CopyVATPostingSetup.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesListPageHandler(var SalesList: TestPage "Sales List")
    begin
        SalesList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetShipmentLinesPageHandler(var GetShipmentLines: TestPage "Get Shipment Lines")
    begin
        GetShipmentLines.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DeleteInvoicedSalesOrdersHandler(var DeleteInvoicedSalesOrders: TestRequestPage "Delete Invoiced Sales Orders")
    begin
        DeleteInvoicedSalesOrders.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreateInvtPutAwayRequestPageHandler(var CreateInvtPutawayPickMvmt: TestRequestPage "Create Invt Put-away/Pick/Mvmt")
    begin
        CreateInvtPutawayPickMvmt.CreateInventorytPutAway.SetValue(true);
        CreateInvtPutawayPickMvmt.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreateInvtPickRequestPageHandler(var CreateInvtPutawayPickMvmt: TestRequestPage "Create Invt Put-away/Pick/Mvmt")
    begin
        CreateInvtPutawayPickMvmt.CInvtPick.SetValue(true);
        CreateInvtPutawayPickMvmt.OK().Invoke();
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SentNotificationHandler(var Notification: Notification): Boolean
    var
        ErrorMessageMgt: Codeunit "Error Message Management";
    begin
        LibraryVariableStorage.Enqueue(Notification.Message);
        ErrorMessageMgt.ShowErrors(Notification); // simulate a click on notification's action
    end;
}

