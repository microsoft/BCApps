codeunit 144066 "ERM Batch POSTROUT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryRandom: Codeunit "Library - Random";
        ValueMustNotExistMsg: Label 'Value must not exist';
        DocumentDateErr: Label 'Document Date cannot be greater than Posting Date';
        NotificationBatchPurchHeaderMsg: Label 'An error or warning occured during operation Batch processing of Purchase Header records.';
        NotificationBatchSalesHeaderMsg: Label 'An error or warning occured during operation Batch processing of Sales Header records.';

    // [Test]
    [HandlerFunctions('BatchPostPurchCreditMemosRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostPurchCreditMemosWithHigherPostingDate()
    var
        PurchaseHeader: Record "Purchase Header";
        BuyFromVendorNo: Code[20];
        LastUsedSeriesDate: Date;
        PostingDate: Date;
    begin
        // [GIVEN] Create Purchase Credit Memo.
        Initialize();
        BuyFromVendorNo := CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo");
        LastUsedSeriesDate := GetLastUsedSeriesDate(PurchaseHeader."Operation Type");
        // [WHEN] Run Report Batch Post Purch. Credit Memos for Posting Date higher than Purchase Credit Memo Posting Date.
        PostingDate := CalcDate('<1D>', LastUsedSeriesDate);
        RunReportBatchPostPurchCreditMemos(BuyFromVendorNo, PostingDate);

        // [THEN] Verify Purchase Credit Memo Header is updated with Posting Date of report on its Posting Date and Operation Occurred Date.
        VerifyPurchCrMemoHeader(BuyFromVendorNo, PostingDate);
    end;

    // [Test]
    [HandlerFunctions('BatchPostPurchCreditMemosRequestPageHandler,MessageHandler,SendErrorNotificationHandler')]
    [Scope('OnPrem')]
    procedure BatchPostPurchCreditMemosWithSamePostingDate()
    var
        PurchaseHeader: Record "Purchase Header";
        LastUsedSeriesDate: Date;
        BuyFromVendorNo: Code[20];
    begin
        // [GIVEN] Create Purchase Credit Memo.
        Initialize();
        BuyFromVendorNo := CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo");
        LastUsedSeriesDate := GetLastUsedSeriesDate(PurchaseHeader."Operation Type");

        // [WHEN] Run Report Batch Post Purch. Credit Memos for Posting Date same as Purchase Credit Memo Posting Date.
        RunReportBatchPostPurchCreditMemos(BuyFromVendorNo, LastUsedSeriesDate);

        // [THEN] Notification: 'An error or warning occured during operation Batch processing of Purchase Header records.'
        VerifyPurchaseErrorNotification();

        // [THEN] Verify Purchase Credit Memo not posted successfully.
        VerifyPurchCrMemoHeaderNotExist(BuyFromVendorNo);
    end;

    // [Test]
    [HandlerFunctions('BatchPostPurchRetOrdersRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostPurchReturnOrdWithHigherPostingDate()
    var
        PurchaseHeader: Record "Purchase Header";
        BuyFromVendorNo: Code[20];
        PostingDate: Date;
        LastUsedSeriesDate: Date;
    begin
        // [GIVEN] Create Purchase Return Order.
        Initialize();
        BuyFromVendorNo := CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order");

        // [WHEN] Run Report Batch Post Purch. Ret. Orders for Posting Date higher than Purchase Return Order Posting Date.
        LastUsedSeriesDate := GetLastUsedSeriesDate(PurchaseHeader."Operation Type");
        PostingDate := CalcDate('<1D>', LastUsedSeriesDate);
        RunReportBatchPostPurchRetOrders(BuyFromVendorNo, PostingDate);

        // [THEN] Verify Purchase Credit Memo Header is updated with Posting Date of report on its Posting Date.
        VerifyPurchCrMemoHeader(BuyFromVendorNo, PostingDate);
    end;

    // [Test]
    [HandlerFunctions('BatchPostPurchRetOrdersRequestPageHandler,MessageHandler,SendErrorNotificationHandler')]
    [Scope('OnPrem')]
    procedure BatchPostPurchReturnOrdWithSamePostingDate()
    var
        PurchaseHeader: Record "Purchase Header";
        LastUsedSeriesDate: Date;
        BuyFromVendorNo: Code[20];
    begin
        // [GIVEN] Create Purchase Return Order.
        Initialize();
        BuyFromVendorNo := CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order");
        LastUsedSeriesDate := GetLastUsedSeriesDate(PurchaseHeader."Operation Type");

        // [WHEN] Run Report Batch Post Purch. Ret. Orders for Posting Date same as Purchase Return Order Posting Date.
        RunReportBatchPostPurchRetOrders(BuyFromVendorNo, LastUsedSeriesDate);

        // [THEN] Notification: 'An error or warning occured during operation Batch processing of Purchase Header records.'
        VerifyPurchaseErrorNotification();
        // [THEN] Verify Purchase Return Order not posted successfully.
        VerifyPurchCrMemoHeaderNotExist(BuyFromVendorNo);
    end;

    // [Test]
    [HandlerFunctions('BatchPostPurchaseOrdersRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostPurchOrdWithHigherPostingDate()
    var
        PurchaseHeader: Record "Purchase Header";
        BuyFromVendorNo: Code[20];
        LastUsedSeriesDate: Date;
        PostingDate: Date;
    begin
        // [GIVEN] Create Purchase Order.
        Initialize();
        BuyFromVendorNo := CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order);

        // [WHEN] Run Report Batch Post Purchase Orders for Posting Date higher than Purchase Order Posting Date.
        LastUsedSeriesDate := GetLastUsedSeriesDate(PurchaseHeader."Operation Type");
        PostingDate := CalcDate('<1D>', LastUsedSeriesDate);
        RunReportBatchPostPurchaseOrders(BuyFromVendorNo, PostingDate);

        // [THEN] Verify Purchase Invoice Header is updated with Posting Date of report on its Posting Date and Operation Occurred Date.
        VerifyPurchInvHeader(BuyFromVendorNo, PostingDate);
    end;

    // [Test]
    [HandlerFunctions('BatchPostPurchaseOrdersRequestPageHandler,MessageHandler,SendErrorNotificationHandler')]
    [Scope('OnPrem')]
    procedure BatchPostPurchOrdWithSamePostingDate()
    var
        PurchaseHeader: Record "Purchase Header";
        LastUsedSeriesDate: Date;
        BuyFromVendorNo: Code[20];
    begin
        // [GIVEN] Create Purchase Order.
        Initialize();
        BuyFromVendorNo := CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order);
        LastUsedSeriesDate := GetLastUsedSeriesDate(PurchaseHeader."Operation Type");

        // [WHEN] Run Report Batch Post Purchase Orders for Posting Date same as Purchase Order Posting Date.
        RunReportBatchPostPurchaseOrders(BuyFromVendorNo, LastUsedSeriesDate);

        // [THEN] Notification: 'An error or warning occured during operation Batch processing of Purchase Header records.'
        VerifyPurchaseErrorNotification();
        // [THEN] Verify Purchase Order not posted successfully.
        VerifyPurchInvHeaderNotExist(BuyFromVendorNo);
    end;

    // [Test]
    [HandlerFunctions('BatchPostPurchaseInvoicesRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostPurchInvWithHigherPostingDate()
    var
        PurchaseHeader: Record "Purchase Header";
        BuyFromVendorNo: Code[20];
        LastUsedSeriesDate: Date;
        PostingDate: Date;
    begin
        // [GIVEN] Create Purchase Invoice.
        Initialize();
        BuyFromVendorNo := CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);

        // [WHEN] Run Report Batch Post Purchase Invoices for Posting Date higher than Purchase Invoice Posting Date.
        LastUsedSeriesDate := GetLastUsedSeriesDate(PurchaseHeader."Operation Type");
        PostingDate := CalcDate('<1D>', LastUsedSeriesDate);
        RunReportBatchPostPurchaseInvoices(BuyFromVendorNo, PostingDate);

        // [THEN] Verify Purchase Invoice Header is updated with Posting Date of report on its Posting Date and Operation Occurred Date.
        VerifyPurchInvHeader(BuyFromVendorNo, PostingDate);
    end;

    // [Test]
    [HandlerFunctions('BatchPostPurchaseInvoicesRequestPageHandler,MessageHandler,SendErrorNotificationHandler')]
    [Scope('OnPrem')]
    procedure BatchPostPurchInvWithSamePostingDate()
    var
        PurchaseHeader: Record "Purchase Header";
        BuyFromVendorNo: Code[20];
        LastUsedSeriesDate: Date;
    begin
        // [GIVEN] Create Purchase Invoice.
        Initialize();
        BuyFromVendorNo := CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);
        LastUsedSeriesDate := GetLastUsedSeriesDate(PurchaseHeader."Operation Type");

        // [WHEN] Run Report Batch Post Purchase Invoices for Posting Date same as Purchase Invoice Posting Date.
        RunReportBatchPostPurchaseInvoices(BuyFromVendorNo, WorkDate());

        // [THEN] Notification: 'An error or warning occured during operation Batch processing of Purchase Header records.'
        VerifyPurchaseErrorNotification();
        // [THEN] Verify Purchase Invoice not posted successfully.
        VerifyPurchInvHeaderNotExist(BuyFromVendorNo);
    end;

    // [Test]
    [HandlerFunctions('BatchPostSalesCreditMemosRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostSalesCreditMemosWithHigherPostingDate()
    var
        SalesHeader: Record "Sales Header";
        SellToCustomerNo: Code[20];
        LastUsedSeriesDate: Date;
        PostingDate: Date;
    begin
        // [GIVEN] Create Sales Credit Memo.
        Initialize();
        SellToCustomerNo := CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::"Credit Memo");
        LastUsedSeriesDate := GetLastUsedSeriesDate(SalesHeader."Operation Type");
        PostingDate := CalcDate('<1D>', LastUsedSeriesDate);

        // [WHEN] Run Report Batch Post Sales Credit Memos for Posting Date higher than Sales Cr.Memo Posting Date.
        RunReportBatchPostSalesCreditMemos(SellToCustomerNo, PostingDate);

        // [THEN] Verify Sales Credit Memo Header is updated with Posting Date of report on its Posting Date and Operation Occurred Date.
        VerifySalesCrMemoHeader(SellToCustomerNo, PostingDate);
    end;

    // [Test]
    [HandlerFunctions('BatchPostSalesCreditMemosRequestPageHandler,MessageHandler,SendErrorNotificationHandler')]
    [Scope('OnPrem')]
    procedure BatchPostSalesCreditMemosWithSamePostingDate()
    var
        SalesHeader: Record "Sales Header";
        LastUsedSeriesDate: Date;
        SellToCustomerNo: Code[20];
    begin
        // [GIVEN] Create Sales Credit Memo.
        Initialize();
        SellToCustomerNo := CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::"Credit Memo");
        LastUsedSeriesDate := GetLastUsedSeriesDate(SalesHeader."Operation Type");

        // [WHEN] Run Report Batch Post Sales Credit Memos for Posting Date same as Sales Cr.Memo Posting Date.
        RunReportBatchPostSalesCreditMemos(SellToCustomerNo, LastUsedSeriesDate);

        // [THEN] Notification: 'An error or warning occured during operation Batch processing of Sales Header records.'
        VerifySalesErrorNotification();
        // [THEN] Verify Sales Credit Memo not posted successfully.
        VerifySalesCrMemoHeaderNotExist(SellToCustomerNo);
    end;

    // [Test]
    [HandlerFunctions('BatchPostSalesInvoicesRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostSalesInvWithHigherPostingDate()
    var
        SalesHeader: Record "Sales Header";
        SellToCustomerNo: Code[20];
        LastUsedSeriesDate: Date;
        PostingDate: Date;
    begin
        // [GIVEN] Create Sales Invoice.
        Initialize();
        SellToCustomerNo := CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice);
        LastUsedSeriesDate := GetLastUsedSeriesDate(SalesHeader."Operation Type");
        PostingDate := CalcDate('<1D>', LastUsedSeriesDate);

        // [WHEN] Run Report Batch Post Sales Invoices for Posting Date higher than Sales Invoice Posting Date.
        RunReportBatchPostSalesInvoices(SellToCustomerNo, PostingDate);

        // [THEN] Verify Sales Invoice Header is updated with Posting Date of report on its Posting Date and Operation Occurred Date.
        VerifySalesInvoiceHeader(SellToCustomerNo, PostingDate);
    end;

    // [Test]
    [HandlerFunctions('BatchPostSalesInvoicesRequestPageHandler,MessageHandler,SendErrorNotificationHandler')]
    [Scope('OnPrem')]
    procedure BatchPostSalesInvWithSamePostingDate()
    var
        SalesHeader: Record "Sales Header";
        SellToCustomerNo: Code[20];
        LastUsedSeriesDate: Date;
    begin
        // [GIVEN] Create Sales Invoice.
        Initialize();
        SellToCustomerNo := CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice);
        LastUsedSeriesDate := GetLastUsedSeriesDate(SalesHeader."Operation Type");

        // [WHEN] Run Report Batch Post Sales Invoices for Posting Date same as Sales Invoice Posting Date.
        RunReportBatchPostSalesInvoices(SellToCustomerNo, LastUsedSeriesDate);

        // [THEN] Notification: 'An error or warning occured during operation Batch processing of Sales Header records.'
        VerifySalesErrorNotification();
        // [THEN] Verify Sales Invoice not posted successfully.
        VerifySalesInvoiceHeaderNotExist(SellToCustomerNo);
    end;

    // [Test]
    [HandlerFunctions('BatchPostSalesReturnOrdersRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostSalesReturnOrdWithHigherPostingDate()
    var
        SalesHeader: Record "Sales Header";
        SellToCustomerNo: Code[20];
        LastUsedSeriesDate: Date;
        PostingDate: Date;
    begin
        // [GIVEN] Create Sales Return Order.
        Initialize();
        SellToCustomerNo := CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::"Return Order");
        LastUsedSeriesDate := GetLastUsedSeriesDate(SalesHeader."Operation Type");
        PostingDate := CalcDate('<1D>', LastUsedSeriesDate);

        // [WHEN] Run Report Batch Post Sales Return Orders for Posting Date higher than Sales Return Order Posting Date.
        RunReportBatchPostSalesReturnOrders(SellToCustomerNo, PostingDate);

        // [THEN] Verify Sales Credit Memo Header is updated with Posting Date of report on its Posting Date and Operation Occurred Date.
        VerifySalesCrMemoHeader(SellToCustomerNo, PostingDate);
    end;

    // [Test]
    [HandlerFunctions('BatchPostSalesReturnOrdersRequestPageHandler,MessageHandler,SendErrorNotificationHandler')]
    [Scope('OnPrem')]
    procedure BatchPostSalesReturnOrdWithSamePostingDate()
    var
        SalesHeader: Record "Sales Header";
        LastUsedSeriesDate: Date;
        SellToCustomerNo: Code[20];
    begin
        // [GIVEN] Create Sales Return Order.
        Initialize();
        SellToCustomerNo := CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::"Return Order");
        LastUsedSeriesDate := GetLastUsedSeriesDate(SalesHeader."Operation Type");

        // [WHEN] Run Report Batch Post Sales Return Orders for Posting Date same as Sales Return Order Posting Date.
        RunReportBatchPostSalesReturnOrders(SellToCustomerNo, LastUsedSeriesDate);

        // [THEN] Notification: 'An error or warning occured during operation Batch processing of Sales Header records.'
        VerifySalesErrorNotification();
        // [THEN] Verify Sales Return Order not posted successfully.
        VerifySalesCrMemoHeaderNotExist(SellToCustomerNo);
    end;

    // [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostSalesOrdWithHigherPostingDate()
    var
        SalesHeader: Record "Sales Header";
        SellToCustomerNo: Code[20];
        LastUsedSeriesDate: Date;
        PostingDate: Date;
    begin
        // [GIVEN] Create Sales Order.
        Initialize();
        SellToCustomerNo := CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Order);
        LastUsedSeriesDate := GetLastUsedSeriesDate(SalesHeader."Operation Type");
        PostingDate := CalcDate('<1D>', LastUsedSeriesDate);

        // [WHEN] Run Report Batch Post Sales Orders for Posting Date higher than Sales Order Posting Date.
        RunReportBatchPostSalesOrders(SellToCustomerNo, PostingDate);

        // [THEN] Verify Sales Invoice Header is updated with Posting Date of report on its Posting Date and Operation Occurred Date.
        VerifySalesInvoiceHeader(SellToCustomerNo, PostingDate);
    end;

    // [Test]
    [HandlerFunctions('SendErrorNotificationHandler')]
    [Scope('OnPrem')]
    procedure BatchPostSalesOrdWithSamePostingDate()
    var
        SalesHeader: Record "Sales Header";
        LastUsedSeriesDate: Date;
        SellToCustomerNo: Code[20];
    begin
        // [GIVEN] Create Sales Order.
        Initialize();
        SellToCustomerNo := CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Order);
        LastUsedSeriesDate := GetLastUsedSeriesDate(SalesHeader."Operation Type");

        // [WHEN] Run Report Batch Post Sales Orders for Posting Date same as Sales Order Posting Date.
        RunReportBatchPostSalesOrders(SellToCustomerNo, LastUsedSeriesDate);

        // [THEN] Notification: 'An error or warning occured during operation Batch processing of Sales Header records.'
        VerifySalesErrorNotification();
        // [THEN] Verify Sales Order not posted successfully.
        VerifySalesInvoiceHeaderNotExist(SellToCustomerNo);
    end;

    [Test]
    [HandlerFunctions('BatchPostServiceCreditMemosRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostServiceCreditMemosWithHigherPostingDate()
    var
        ServiceHeader: Record "Service Header";
        BillToCustomerNo: Code[20];
        PostingDate: Date;
    begin
        // [GIVEN] Create Service Credit Memo.
        Initialize();
        BillToCustomerNo := CreateServiceDocument(ServiceHeader."Document Type"::"Credit Memo");
        PostingDate := CalcDate('<1D>', WorkDate());

        // [WHEN] Run Report Batch Post Service Credit Memos for Posting Date higher than Service Cr.Memo Posting Date.
        RunReportBatchPostServiceCreditMemos(BillToCustomerNo, PostingDate);

        // [THEN] Verify Service Credit Memo Header is updated with Posting Date of report on its Posting Date and Operation Occurred Date.
        VerifyServiceCrMemoHeader(BillToCustomerNo, PostingDate);
    end;

    [Test]
    [HandlerFunctions('BatchPostServiceCreditMemosRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostServiceCreditMemosWithSamePostingDate()
    var
        ServiceHeader: Record "Service Header";
        BillToCustomerNo: Code[20];
    begin
        // [GIVEN] Create Service Credit Memo.
        Initialize();
        BillToCustomerNo := CreateServiceDocument(ServiceHeader."Document Type"::"Credit Memo");

        // [WHEN] Run Report Batch Post Service Credit Memos for Posting Date same as Service Cr.Memo Posting Date.
        RunReportBatchPostServiceCreditMemos(BillToCustomerNo, WorkDate());

        // [THEN] Verify Service Credit Memo not posted successfully.
        VerifyServiceCrMemoHeaderNotExist(BillToCustomerNo);
    end;

    [Test]
    [HandlerFunctions('BatchPostServiceInvoicesRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostServiceInvoiceWithHigherPostingDate()
    var
        ServiceHeader: Record "Service Header";
        BillToCustomerNo: Code[20];
        PostingDate: Date;
    begin
        // [GIVEN] Create Service Invoice.
        Initialize();
        BillToCustomerNo := CreateServiceDocument(ServiceHeader."Document Type"::Invoice);
        PostingDate := CalcDate('<1D>', WorkDate());

        // [WHEN] Run Report Batch Post Service Invoices for Posting Date higher than Service Invoice Posting Date.
        RunReportBatchPostServiceInvoices(BillToCustomerNo, PostingDate);

        // [THEN] Verify Service Invoice Header is updated with Posting Date of report on its Posting Date and Operation Occurred Date.
        VerifyServiceInvoiceHeader(BillToCustomerNo, PostingDate);
    end;

    [Test]
    [HandlerFunctions('BatchPostServiceInvoicesRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostServiceInvoiceWithSamePostingDate()
    var
        ServiceHeader: Record "Service Header";
        BillToCustomerNo: Code[20];
    begin
        // [GIVEN] Create Service Invoice.
        Initialize();
        BillToCustomerNo := CreateServiceDocument(ServiceHeader."Document Type"::Invoice);

        // [WHEN] Run Report Batch Post Service Invoices for Posting Date same as Service Invoice Posting Date.
        RunReportBatchPostServiceInvoices(BillToCustomerNo, WorkDate());

        // [THEN] Verify Service Invoice not posted successfully.
        VerifyServiceInvoiceHeaderNotExist(BillToCustomerNo);
    end;

    [Test]
    [HandlerFunctions('BatchPostServiceOrdersRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostServiceOrderWithSamePostingDate()
    var
        ServiceHeader: Record "Service Header";
        BillToCustomerNo: Code[20];
    begin
        // [GIVEN] Create Service Order.
        Initialize();
        BillToCustomerNo := CreateServiceDocument(ServiceHeader."Document Type"::Order);

        // [WHEN] Run Report Batch Post Service Orders for Posting Date same as Service Order Posting Date.
        RunReportBatchPostServiceOrders(BillToCustomerNo, WorkDate());

        // [THEN] Verify Service Order not posted successfully.
        VerifyServiceInvoiceHeaderNotExist(BillToCustomerNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlanketPurchOrderMakeOrderWithEarlierDocumentDate()
    var
        DocumentDate: Date;
    begin
        // [GIVEN] Create Blanket Purchase Order with Document Date earlier than Posting Date as WORKDATE.
        Initialize();
        DocumentDate := CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());  // Document Date earlier than Posting Date as WORKDATE.
        BlanketPurchOrderMakeOrderWithDocAndOperationOccurredDate(DocumentDate, DocumentDate);  // Document Date, Operation Occurred Date.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlanketPurchOrderMakeOrderWithHigherOperationOccurredDate()
    var
        OperationOccurredDate: Date;
    begin
        // [GIVEN] Create Blanket Purchase Order with Operation Occurred Date more than Posting Date as WORKDATE.
        Initialize();
        OperationOccurredDate := CalcDate('<1D>', WorkDate());  // Operation Occurred Date more than Posting Date as WORKDATE.
        BlanketPurchOrderMakeOrderWithDocAndOperationOccurredDate(WorkDate(), OperationOccurredDate);  // Document Date, Operation Occurred Date.
    end;

    local procedure BlanketPurchOrderMakeOrderWithDocAndOperationOccurredDate(DocumentDate: Date; OperationOccurredDate: Date)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [GIVEN] Blanket Purchase Order
        CreatePurchaseDocumentWithOperationAndDocumentDate(PurchaseHeader, PurchaseHeader."Document Type"::"Blanket Order", DocumentDate, OperationOccurredDate);

        // [WHEN] Create Purchase Order from Blanket Purchase Order
        LibraryPurchase.BlanketPurchaseOrderMakeOrder(PurchaseHeader);

        // [THEN] Purchase Order created with Operation Occurred Date equal to Posting Date and Document Date same as Document Date of Blanket Purchase Order
        VerifyPurchaseOrderOperationAndDocumentDate(PurchaseHeader."Buy-from Vendor No.", DocumentDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlanketPurchOrderMakeOrderWithHigherDocumentDateError()
    var
        PurchaseHeader: Record "Purchase Header";
        DocumentDate: Date;
    begin
        Initialize();
        // [GIVEN] Blanket Purchase with Order Document Date more than Posting Date as WORKDATE
        DocumentDate := CalcDate('<1D>', WorkDate());  // Document Date more than Posting Date as WORKDATE.
        CreatePurchaseDocumentWithOperationAndDocumentDate(
          PurchaseHeader, PurchaseHeader."Document Type"::"Blanket Order", DocumentDate, WorkDate());  // Operation Occurred Date - WORKDATE.

        // [WHEN] Create Purchase Order from Blanket Purchase Order.
        asserterror LibraryPurchase.BlanketPurchaseOrderMakeOrder(PurchaseHeader);

        // [THEN] Error: Document Date cannot be greater than Posting Date as WORKDATE.
        Assert.ExpectedError(DocumentDateErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchQuoteMakeOrderWithEarlierDocumentDate()
    var
        DocumentDate: Date;
    begin
        // [GIVEN] Create Purchase Quote with Document Date earlier than Posting Date as WORKDATE.
        Initialize();
        DocumentDate := CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());
        PurchQuoteMakeOrderWithDocAndOperationOccurredDate(DocumentDate, DocumentDate);  // Document Date, Operation Occurred Date.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchQuoteMakeOrderWithHigherOperationOccurredDate()
    var
        OperationOccurredDate: Date;
    begin
        // [GIVEN] Create Purchase Quote with Operation Occurred Date more than Posting Date as WORKDATE.
        Initialize();
        OperationOccurredDate := CalcDate('<1D>', WorkDate());
        PurchQuoteMakeOrderWithDocAndOperationOccurredDate(WorkDate(), OperationOccurredDate);  // Document Date, Operation Occurred Date.
    end;

    local procedure PurchQuoteMakeOrderWithDocAndOperationOccurredDate(DocumentDate: Date; OperationOccurredDate: Date)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrderHeader: Record "Purchase Header";
    begin
        // Create Purchase Quote.
        Initialize();
        CreatePurchaseDocumentWithOperationAndDocumentDate(
          PurchaseHeader, PurchaseHeader."Document Type"::Quote, DocumentDate, OperationOccurredDate);

        // [WHEN] Create Purchase Order from Purchase Quote.
        PurchaseOrderHeader.Get(
          PurchaseOrderHeader."Document Type"::Order, LibraryPurchase.QuoteMakeOrder(PurchaseHeader));

        // [THEN] Verify Purchase Order created with Operation Occurred Date equal to Posting Date and Document Date same as Document Date of Purchase Quote.
        PurchaseOrderHeader.TestField("Operation Occurred Date", WorkDate());
        PurchaseOrderHeader.TestField("Document Date", DocumentDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchQuoteMakeOrderWithHigherDocumentDateError()
    var
        PurchaseHeader: Record "Purchase Header";
        DocumentDate: Date;
    begin
        // [GIVEN] Create Purchase Quote with Document Date more than Posting Date as WORKDATE.
        Initialize();
        DocumentDate := CalcDate('<1D>', WorkDate());
        CreatePurchaseDocumentWithOperationAndDocumentDate(
          PurchaseHeader, PurchaseHeader."Document Type"::Quote, DocumentDate, WorkDate());  // Operation Occurred Date - WORKDATE.

        // [WHEN] Create Purchase Order from Purchase Quote.
        asserterror LibraryPurchase.QuoteMakeOrder(PurchaseHeader);

        // [THEN] Verify Error: Document Date cannot be greater than Posting Date as WORKDATE.
        Assert.ExpectedError(DocumentDateErr);
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure BlanketSalesOrderMakeOrderWithEarlierDocumentDate()
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        DocumentDate: Date;
    begin
        // [GIVEN] Create Blanket Sales Order with Document Date earlier than Posting Date as WORKDATE.
        Initialize();
        DocumentDate := CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());
        BlanketSalesOrderMakeOrderWithDocAndOperationOccurredDate(DocumentDate, DocumentDate);  // Document Date, Operation Occurred Date.
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure BlanketSalesOrderMakeOrderWithHigherOperationOccurredDate()
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        OperationOccurredDate: Date;
    begin
        // [GIVEN] Create Blanket Sales Order with Operation Occurred Date more than Posting Date as WORKDATE.
        Initialize();
        OperationOccurredDate := CalcDate('<1D>', WorkDate());
        BlanketSalesOrderMakeOrderWithDocAndOperationOccurredDate(WorkDate(), OperationOccurredDate);  // Document Date, Operation Occurred Date.
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    local procedure BlanketSalesOrderMakeOrderWithDocAndOperationOccurredDate(DocumentDate: Date; OperationOccurredDate: Date)
    var
        SalesHeader: Record "Sales Header";
    begin
        // [GIVEN] Blanket Sales Order
        CreateSalesDocumentWithOperationAndDocumentDate(
          SalesHeader, SalesHeader."Document Type"::"Blanket Order", DocumentDate, OperationOccurredDate);

        // [WHEN] Create Sales Order from Blanket Sales Order
        LibrarySales.BlanketSalesOrderMakeOrder(SalesHeader);

        // [THEN] Sales Order created with Operation Occurred Date equal to Posting Date and Document Date same as Document Date of Blanket Sales Order.
        VerifySalesOrderOperationAndDocumentDate(SalesHeader."Sell-to Customer No.", DocumentDate);
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure BlanketSalesOrderMakeOrderWithHigherDocumentDateError()
    var
        SalesHeader: Record "Sales Header";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        DocumentDate: Date;
    begin
        Initialize();
        // [GIVEN] Blanket Sales Order with Document Date more than Posting Date as WORKDATE
        DocumentDate := CalcDate('<1D>', WorkDate());
        CreateSalesDocumentWithOperationAndDocumentDate(
          SalesHeader, SalesHeader."Document Type"::"Blanket Order", DocumentDate, WorkDate());  // Operation Occurred Date - WORKDATE.

        // [WHEN] Create Sales Order from Blanket Sales Order
        asserterror LibrarySales.BlanketSalesOrderMakeOrder(SalesHeader);

        // [THEN] Error: Document Date cannot be greater than Posting Date as WORKDATE
        Assert.ExpectedError(DocumentDateErr);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderPageHandler,SendNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure SalesQuoteMakeOrderWithEarlierDocumentDate()
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        DocumentDate: Date;
    begin
        // [GIVEN] Create Sales Quote with Document Date earlier than Posting Date as WORKDATE.
        Initialize();
        DocumentDate := CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());
        SalesQuoteMakeOrderWithDocAndOperationOccurredDate(DocumentDate, DocumentDate);  // Document Date, Operation Occurred Date.
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderPageHandler,SendNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure SalesQuoteMakeOrderWithHigherOperationOccurredDate()
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        OperationOccurredDate: Date;
    begin
        // [GIVEN] Create Sales Quote with Operation Occurred Date more than Posting Date as WORKDATE.
        Initialize();
        OperationOccurredDate := CalcDate('<1D>', WorkDate());
        SalesQuoteMakeOrderWithDocAndOperationOccurredDate(WorkDate(), OperationOccurredDate);  // Document Date, Operation Occurred Date.
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    local procedure SalesQuoteMakeOrderWithDocAndOperationOccurredDate(DocumentDate: Date; OperationOccurredDate: Date)
    var
        SalesHeader: Record "Sales Header";
        SalesOrderHeader: Record "Sales Header";
    begin
        // Create Sales Quote.
        CreateSalesDocumentWithOperationAndDocumentDate(
          SalesHeader, SalesHeader."Document Type"::Quote, DocumentDate, OperationOccurredDate);

        // [WHEN] Create Sales Order from Sales Quote.
        CODEUNIT.Run(CODEUNIT::"Sales-Quote to Order (Yes/No)", SalesHeader);
        FindSalesHeader(SalesOrderHeader, SalesHeader."Sell-to Customer No.", SalesHeader."Document Type"::Order);

        // [THEN] Verify Sales Order created with Operation Occurred Date equal to Posting Date and Document Date same as Document Date of Sales Quote.
        SalesOrderHeader.TestField("Operation Occurred Date", WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesQuoteMakeOrderWithHigherDocumentDateError()
    var
        SalesHeader: Record "Sales Header";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        DocumentDate: Date;
    begin
        // [GIVEN] Create Sales Quote with Document Date more than Posting Date as WORKDATE.
        Initialize();
        DocumentDate := CalcDate('<1D>', WorkDate());
        CreateSalesDocumentWithOperationAndDocumentDate(
          SalesHeader, SalesHeader."Document Type"::Quote, DocumentDate, WorkDate());  // Operation Occurred Date - WORKDATE.

        // [WHEN] Create Sales Order from Sales Quote.
        asserterror LibrarySales.QuoteMakeOrder(SalesHeader);

        // [THEN] Verify Error: Document Date cannot be greater than Posting Date as WORKDATE.
        Assert.ExpectedError(DocumentDateErr);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('BatchPostServiceOrdersRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostServiceOrderWithHigherPostingDate()
    var
        ServiceHeader: Record "Service Header";
        BillToCustomerNo: Code[20];
        PostingDate: Date;
    begin
        // [GIVEN] Create Service Order, Service Item and update Service Item Line - Bill To Customer Number.
        Initialize();
        BillToCustomerNo := CreateServiceDocument(ServiceHeader."Document Type"::Order);
        CreateServiceItemAndUpdateServiceLine(BillToCustomerNo);
        PostingDate := CalcDate('<1D>', WorkDate());  // Posting Date higher than WORKDATE.

        // [WHEN] Run Report Batch Post Service Orders for Posting Date higher than Service Order Posting Date.
        RunReportBatchPostServiceOrders(BillToCustomerNo, PostingDate);  // Opens handler - BatchPostServiceOrdersRequestPageHandler.

        // [THEN] Verify Service Invoice Header is updated with Posting Date of report on its Posting Date and Operation Occurred Date.
        VerifyServiceInvoiceHeader(BillToCustomerNo, PostingDate);
    end;

    // [Test]
    [HandlerFunctions('BatchPostPurchaseInvoicesRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostPurchInvNoSeriesLinePurchWithHigherPostingDate()
    var
        PurchaseHeader: Record "Purchase Header";
        NoSeriesLine: Record "No. Series Line";
        BuyFromVendorNo: Code[20];
        NoSeriesCode: Code[20];
        PostingDate: Date;
    begin
        // [GIVEN] Create Purchase Invoice.
        Initialize();
        BuyFromVendorNo := CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);
        FindPurchaseHeader(PurchaseHeader, BuyFromVendorNo, PurchaseHeader."Document Type"::Invoice);
        NoSeriesCode := PurchaseHeader."Operation Type";
        PostingDate := CalcDate('<1D>', WorkDate());  // Posting Date higher than WORKDATE.

        // [WHEN] Run Report Batch Post Purchase Invoices for Posting Date higher than Purchase Invoice Posting Date.
        RunReportBatchPostPurchaseInvoices(BuyFromVendorNo, PostingDate);  // Opens handler - BatchPostPurchaseInvoicesRequestPageHandler.

        // [THEN] Verify Number Series Line Purchase - Last Date Used is updated with Posting date of Purchase Invoice.
        VerifyNoSeriesLine(NoSeriesLine, NoSeriesCode, PostingDate);

        // Teardown.
        UpdateNoSeriesLine(NoSeriesLine);
    end;

    [Test]
    [HandlerFunctions('BatchPostSalesInvoicesRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostSalesInvNoSeriesLineSalesWithHigherPostingDate()
    var
        SalesHeader: Record "Sales Header";
        NoSeriesLine: Record "No. Series Line";
        SellToCustomerNo: Code[20];
        NoSeriesCode: Code[20];
        PostingDate: Date;
    begin
        // [GIVEN] Create Sales Invoice.
        Initialize();
        SellToCustomerNo := CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice);
        FindSalesHeader(SalesHeader, SellToCustomerNo, SalesHeader."Document Type"::Invoice);
        NoSeriesCode := SalesHeader."Operation Type";
        PostingDate := CalcDate('<1D>', WorkDate());

        // [WHEN] Run Report Batch Post Sales Invoices for Posting Date higher than Sales Invoice Posting Date.
        RunReportBatchPostSalesInvoices(SellToCustomerNo, PostingDate);  // Opens handler - BatchPostSalesInvoicesRequestPageHandler.

        // [THEN] Verify Number Series Line Sales - Last Date Used is updated with Posting date of Sales Header.
        VerifyNoSeriesLine(NoSeriesLine, NoSeriesCode, PostingDate);

        // Teardown.
        UpdateNoSeriesLine(NoSeriesLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BatchPostSalesOrderPrepaymentWithHigherPostingDate()
    var
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
        PostingDate: Date;
        SellToCustomerNo: Code[20];
        OldSalesPrepaymentsAccount: Code[20];
    begin
        // [GIVEN] Create Sales Order, update Sales Prepayment Account, Sales Header Prepayment Percentage, Sales Line - VAT Posting Group.
        Initialize();
        LibraryERM.CreateGLAccount(GLAccount);
        OldSalesPrepaymentsAccount := UpdateVATPostingSetupSalesPrepaymentAccount(VATPostingSetup, GLAccount."No.");
        SellToCustomerNo := CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Order);
        PostingDate := CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate());  // Posting Date higher than WORKDATE.
        UpdateSalesHeaderPrepaymentPct(SellToCustomerNo, PostingDate);
        UpdateSalesLineVATPostingGroup(SalesHeader, VATPostingSetup, SellToCustomerNo);

        // Exercise.
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [THEN] Verify Sales Order is posted successfully.
        VerifySalesInvoiceHeader(SellToCustomerNo, PostingDate);

        // Teardown.
        UpdateVATPostingSetupSalesPrepaymentAccount(VATPostingSetup, OldSalesPrepaymentsAccount);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"): Code[20]
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseLine: Record "Purchase Line";
        NoSeries: Record "No. Series";
    begin
        NoSeries.SetFilter("No. Series Type", '%1|%2', NoSeries."No. Series Type"::Sales, NoSeries."No. Series Type"::Purchase);
        NoSeries.SetRange("Date Order", true);
        NoSeries.FindFirst();
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, Vendor."No.");
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Operation Type", NoSeries.Code);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(10, 2));  // Random value for Quantity.
        exit(Vendor."No.");
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"): Code[20]
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, Customer."No.");
        SalesHeader.Validate("Operation Type", FindSalesNoSeries());
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(10, 2));  // Random value for Quantity.
        exit(Customer."No.");
    end;

    local procedure CreateServiceDocument(DocumentType: Enum "Service Document Type"): Code[20]
    var
        Customer: Record Customer;
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, Customer."No.");
        ServiceHeader.Validate("Operation Type", FindSalesNoSeries());
        ServiceHeader.Validate("Posting Date", WorkDate());
        ServiceHeader.Modify(true);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItem(Item));
        ServiceLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));
        ServiceLine.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreatePurchaseDocumentWithOperationAndDocumentDate(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; DocumentDate: Date; OperationOccurredDate: Date)
    var
        BuyFromVendorNo: Code[20];
    begin
        BuyFromVendorNo := CreatePurchaseDocument(PurchaseHeader, DocumentType);
        PurchaseHeader.Validate("Operation Occurred Date", OperationOccurredDate);
        PurchaseHeader.Validate("Document Date", DocumentDate);
        PurchaseHeader.Modify(true);
    end;

    local procedure CreateSalesDocumentWithOperationAndDocumentDate(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; DocumentDate: Date; OperationOccurredDate: Date)
    var
        SellToCustomerNo: Code[20];
    begin
        SellToCustomerNo := CreateSalesDocument(SalesHeader, DocumentType);
        SalesHeader.Validate("Operation Occurred Date", OperationOccurredDate);
        SalesHeader.Validate("Document Date", DocumentDate);
        SalesHeader.Modify(true);
    end;

    local procedure CreateServiceItemAndUpdateServiceLine(BillToCustomerNo: Code[20])
    var
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        ServiceHeader.SetRange("Bill-to Customer No.", BillToCustomerNo);
        ServiceHeader.FindFirst();
        LibraryService.CreateServiceItem(ServiceItem, BillToCustomerNo);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        ServiceLine.SetRange("Bill-to Customer No.", BillToCustomerNo);
        ServiceLine.FindFirst();
        ServiceLine.Validate("Service Item No.", ServiceItem."No.");
        ServiceLine.Modify(true);
    end;

    local procedure GetLastUsedSeriesDate(SeriesNoCode: Code[20]): Date;
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        NoSeriesLine.SetRange("Series Code", SeriesNoCode);
        NoSeriesLine.FindLast();
        if NoSeriesLine."Last Date Used" = 0D then
            exit(WorkDate());
        exit(NoSeriesLine."Last Date Used");
    end;

    local procedure RunReportBatchPostPurchCreditMemos(VendorNo: Code[20]; PostingDate: Date)
    var
        PurchaseHeader: Record "Purchase Header";
        BatchPostPurchCreditMemos: Report "Batch Post Purch. Credit Memos";
    begin
        LibraryVariableStorage.Enqueue(PostingDate);  // Required inside BatchPostPurchCreditMemosRequestPageHandler.
        Commit();  // Commit required to Run report.
        Clear(BatchPostPurchCreditMemos);
        PurchaseHeader.SetRange("Buy-from Vendor No.", VendorNo);
        BatchPostPurchCreditMemos.SetTableView(PurchaseHeader);
        BatchPostPurchCreditMemos.Run();  // Opens handler - BatchPostPurchCreditMemosRequestPageHandler.
    end;

    local procedure RunReportBatchPostPurchRetOrders(VendorNo: Code[20]; PostingDate: Date)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryVariableStorage.Enqueue(PostingDate);  // Required inside BatchPostPurchRetOrdersRequestPageHandler.
        PurchaseHeader.SetRange("Buy-from Vendor No.", VendorNo);
        LibraryPurchase.RunBatchPostPurchaseReturnOrdersReport(PurchaseHeader)
    end;

    local procedure RunReportBatchPostPurchaseOrders(VendorNo: Code[20]; PostingDate: Date)
    var
        PurchaseHeader: Record "Purchase Header";
        BatchPostPurchaseOrders: Report "Batch Post Purchase Orders";
    begin
        LibraryVariableStorage.Enqueue(PostingDate);  // Required inside BatchPostPurchaseOrdersRequestPageHandler.
        Commit();  // Commit required to Run report.
        Clear(BatchPostPurchaseOrders);
        PurchaseHeader.SetRange("Buy-from Vendor No.", VendorNo);
        BatchPostPurchaseOrders.SetTableView(PurchaseHeader);
        BatchPostPurchaseOrders.Run();  // Opens handler - BatchPostPurchaseOrdersRequestPageHandler.
    end;

    local procedure RunReportBatchPostPurchaseInvoices(VendorNo: Code[20]; PostingDate: Date)
    var
        PurchaseHeader: Record "Purchase Header";
        BatchPostPurchaseInvoices: Report "Batch Post Purchase Invoices";
    begin
        LibraryVariableStorage.Enqueue(PostingDate);  // Required inside BatchPostPurchaseInvoicesRequestPageHandler.
        Commit();  // Commit required to Run report.
        Clear(BatchPostPurchaseInvoices);
        PurchaseHeader.SetRange("Buy-from Vendor No.", VendorNo);
        BatchPostPurchaseInvoices.SetTableView(PurchaseHeader);
        BatchPostPurchaseInvoices.Run();  // Opens handler - BatchPostPurchaseInvoicesRequestPageHandler.
    end;

    local procedure RunReportBatchPostSalesCreditMemos(SellToCustomerNo: Code[20]; PostingDate: Date)
    var
        SalesHeader: Record "Sales Header";
        BatchPostSalesCreditMemos: Report "Batch Post Sales Credit Memos";
    begin
        LibraryVariableStorage.Enqueue(PostingDate);  // Required inside BatchPostSalesCreditMemosRequestPageHandler.
        Commit();  // Commit required to Run report.
        Clear(BatchPostSalesCreditMemos);
        SalesHeader.SetRange("Sell-to Customer No.", SellToCustomerNo);
        BatchPostSalesCreditMemos.SetTableView(SalesHeader);
        BatchPostSalesCreditMemos.Run();  // Opens handler - BatchPostSalesCreditMemosRequestPageHandler.
    end;

    local procedure RunReportBatchPostSalesInvoices(SellToCustomerNo: Code[20]; PostingDate: Date)
    var
        SalesHeader: Record "Sales Header";
        BatchPostSalesInvoices: Report "Batch Post Sales Invoices";
    begin
        LibraryVariableStorage.Enqueue(PostingDate);  // Required inside BatchPostSalesInvoicesRequestPageHandler.
        Commit();  // Commit required to Run report.
        Clear(BatchPostSalesInvoices);
        SalesHeader.SetRange("Sell-to Customer No.", SellToCustomerNo);
        BatchPostSalesInvoices.SetTableView(SalesHeader);
        BatchPostSalesInvoices.Run();  // Opens handler - BatchPostSalesInvoicesRequestPageHandler.
    end;

    local procedure RunReportBatchPostSalesReturnOrders(SellToCustomerNo: Code[20]; PostingDate: Date)
    var
        SalesHeader: Record "Sales Header";
        BatchPostSalesReturnOrders: Report "Batch Post Sales Return Orders";
    begin
        LibraryVariableStorage.Enqueue(PostingDate);  // Required inside BatchPostSalesInvoicesRequestPageHandler.
        Commit();  // Commit required to Run report.
        Clear(BatchPostSalesReturnOrders);
        SalesHeader.SetRange("Sell-to Customer No.", SellToCustomerNo);
        BatchPostSalesReturnOrders.SetTableView(SalesHeader);
        BatchPostSalesReturnOrders.Run();  // Opens handler - BatchPostSalesInvoicesRequestPageHandler.
    end;

    local procedure RunReportBatchPostSalesOrders(SellToCustomerNo: Code[20]; PostingDate: Date)
    var
        SalesHeader: Record "Sales Header";
    begin
        Commit();  // Commit required to Run report.
        SalesHeader.SetRange("Sell-to Customer No.", SellToCustomerNo);
        LibrarySales.BatchPostSalesHeaders(
          SalesHeader, true, true, PostingDate, true, false, false);  // Ship, Invoice - TRUE, ReplacePostingDate - TRUE, ReplaceDocumentDate, CalcInvDiscount - FALSE
    end;

    local procedure RunReportBatchPostServiceCreditMemos(BillToCustomerNo: Code[20]; PostingDate: Date)
    var
        ServiceHeader: Record "Service Header";
        BatchPostServiceCrMemos: Report "Batch Post Service Cr. Memos";
    begin
        LibraryVariableStorage.Enqueue(PostingDate);  // Required inside BatchPostServiceCreditMemosRequestPageHandler.
        Commit();  // Commit required to Run report.
        Clear(BatchPostServiceCrMemos);
        ServiceHeader.SetRange("Bill-to Customer No.", BillToCustomerNo);
        BatchPostServiceCrMemos.SetTableView(ServiceHeader);
        BatchPostServiceCrMemos.Run();  // Opens handler - BatchPostServiceCreditMemosRequestPageHandler.
    end;

    local procedure RunReportBatchPostServiceInvoices(BillToCustomerNo: Code[20]; PostingDate: Date)
    var
        ServiceHeader: Record "Service Header";
        BatchPostServiceInvoices: Report "Batch Post Service Invoices";
    begin
        LibraryVariableStorage.Enqueue(PostingDate);  // Required inside BatchPostServiceInvoicesRequestPageHandler.
        Commit();  // Commit required to Run report.
        Clear(BatchPostServiceInvoices);
        ServiceHeader.SetRange("Bill-to Customer No.", BillToCustomerNo);
        BatchPostServiceInvoices.SetTableView(ServiceHeader);
        BatchPostServiceInvoices.Run();  // Opens handler - BatchPostServiceInvoicesRequestPageHandler.
    end;

    local procedure RunReportBatchPostServiceOrders(BillToCustomerNo: Code[20]; PostingDate: Date)
    var
        ServiceHeader: Record "Service Header";
        BatchPostServiceOrders: Report "Batch Post Service Orders";
    begin
        LibraryVariableStorage.Enqueue(PostingDate);  // Required inside BatchPostServiceOrdersRequestPageHandler.
        Commit();  // Commit required to Run report.
        Clear(BatchPostServiceOrders);
        ServiceHeader.SetRange("Bill-to Customer No.", BillToCustomerNo);
        BatchPostServiceOrders.SetTableView(ServiceHeader);
        BatchPostServiceOrders.Run();  // Opens handler - BatchPostServiceOrdersRequestPageHandler.
    end;

    local procedure FindPurchaseHeader(var PurchaseHeader: Record "Purchase Header"; BuyFromVendorNo: Code[20]; DocumentType: Enum "Purchase Document Type")
    begin
        PurchaseHeader.SetRange("Document Type", DocumentType);
        PurchaseHeader.SetRange("Buy-from Vendor No.", BuyFromVendorNo);
        PurchaseHeader.FindFirst();
    end;

    local procedure FindSalesHeader(var SalesHeader: Record "Sales Header"; SellToCustomerNo: Code[20]; DocumentType: Enum "Sales Document Type")
    begin
        SalesHeader.SetRange("Document Type", DocumentType);
        SalesHeader.SetRange("Sell-to Customer No.", SellToCustomerNo);
        SalesHeader.FindFirst();
    end;

    local procedure FindSalesNoSeries(): Code[20]
    var
        NoSeries: Record "No. Series";
    begin
        NoSeries.SetRange("No. Series Type", NoSeries."No. Series Type"::Sales);
        NoSeries.SetRange("Date Order", true);
        NoSeries.FindFirst();
        exit(NoSeries.Code);
    end;

    local procedure UpdateVATPostingSetupSalesPrepaymentAccount(var VATPostingSetup: Record "VAT Posting Setup"; SalesPrepaymentsAccount: Code[20]) OldSalesPrepaymentsAccount: Code[20]
    begin
        VATPostingSetup.FindFirst();
        OldSalesPrepaymentsAccount := VATPostingSetup."Sales Prepayments Account";
        VATPostingSetup.Validate("Sales Prepayments Account", SalesPrepaymentsAccount);
        VATPostingSetup.Modify(true);
    end;

    local procedure UpdateSalesHeaderPrepaymentPct(SellToCustomerNo: Code[20]; PostingDate: Date)
    var
        SalesHeader: Record "Sales Header";
    begin
        FindSalesHeader(SalesHeader, SellToCustomerNo, SalesHeader."Document Type"::Order);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Validate("Prepayment %", LibraryRandom.RandDec(10, 2));
        SalesHeader.Modify(true);
    end;

    local procedure UpdateSalesLineVATPostingGroup(var SalesHeader: Record "Sales Header"; VATPostingSetup: Record "VAT Posting Setup"; SellToCustomerNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        FindSalesHeader(SalesHeader, SellToCustomerNo, SalesHeader."Document Type"::Order);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        SalesLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        SalesLine.Modify(true);
    end;

    local procedure UpdateNoSeriesLine(NoSeriesLine: Record "No. Series Line")
    begin
        NoSeriesLine.Validate("Last Date Used", WorkDate());
        NoSeriesLine.Modify(true);
    end;

    local procedure VerifyPurchaseErrorNotification()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        Assert.ExpectedMessage(NotificationBatchPurchHeaderMsg, LibraryVariableStorage.DequeueText());
        LibraryNotificationMgt.RecallNotificationsForRecordID(PurchaseHeader.RecordId);
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure VerifySalesErrorNotification()
    var
        SalesHeader: Record "Sales Header";
    begin
        Assert.ExpectedMessage(NotificationBatchSalesHeaderMsg, LibraryVariableStorage.DequeueText());
        LibraryNotificationMgt.RecallNotificationsForRecordID(SalesHeader.RecordId);
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure VerifyPurchCrMemoHeader(BuyFromVendorNo: Code[20]; PostingDate: Date)
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        PurchCrMemoHdr.SetRange("Buy-from Vendor No.", BuyFromVendorNo);
        PurchCrMemoHdr.FindFirst();
        PurchCrMemoHdr.TestField("Posting Date", PostingDate);
        PurchCrMemoHdr.TestField("Document Date", WorkDate());
        PurchCrMemoHdr.TestField("Operation Occurred Date", PostingDate);
    end;

    local procedure VerifyPurchInvHeader(BuyFromVendorNo: Code[20]; PostingDate: Date)
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.SetRange("Buy-from Vendor No.", BuyFromVendorNo);
        PurchInvHeader.FindFirst();
        PurchInvHeader.TestField("Posting Date", PostingDate);
        PurchInvHeader.TestField("Document Date", WorkDate());
        PurchInvHeader.TestField("Operation Occurred Date", PostingDate);
    end;

    local procedure VerifySalesCrMemoHeader(SellToCustomerNo: Code[20]; PostingDate: Date)
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        SalesCrMemoHeader.SetRange("Sell-to Customer No.", SellToCustomerNo);
        SalesCrMemoHeader.FindFirst();
        SalesCrMemoHeader.TestField("Posting Date", PostingDate);
        SalesCrMemoHeader.TestField("Document Date", WorkDate());
        SalesCrMemoHeader.TestField("Operation Occurred date", PostingDate);
    end;

    local procedure VerifySalesInvoiceHeader(SellToCustomerNo: Code[20]; PostingDate: Date)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", SellToCustomerNo);
        SalesInvoiceHeader.FindFirst();
        SalesInvoiceHeader.TestField("Posting Date", PostingDate);
        SalesInvoiceHeader.TestField("Document Date", PostingDate);
        SalesInvoiceHeader.TestField("Operation Occurred Date", PostingDate);
    end;

    local procedure VerifyPurchCrMemoHeaderNotExist(BuyFromVendorNo: Code[20])
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        PurchCrMemoHdr.SetRange("Buy-from Vendor No.", BuyFromVendorNo);
        Assert.IsFalse(PurchCrMemoHdr.FindFirst(), ValueMustNotExistMsg);
    end;

    local procedure VerifyPurchInvHeaderNotExist(BuyFromVendorNo: Code[20])
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.SetRange("Buy-from Vendor No.", BuyFromVendorNo);
        Assert.IsFalse(PurchInvHeader.FindFirst(), ValueMustNotExistMsg);
    end;

    local procedure VerifySalesInvoiceHeaderNotExist(SellToCustomerNo: Code[20])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", SellToCustomerNo);
        Assert.IsFalse(SalesInvoiceHeader.FindFirst(), ValueMustNotExistMsg);
    end;

    local procedure VerifySalesCrMemoHeaderNotExist(SellToCustomerNo: Code[20])
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        SalesCrMemoHeader.SetRange("Sell-to Customer No.", SellToCustomerNo);
        Assert.IsFalse(SalesCrMemoHeader.FindFirst(), ValueMustNotExistMsg);
    end;

    local procedure VerifyServiceCrMemoHeader(BillToCustomerNo: Code[20]; PostingDate: Date)
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        ServiceCrMemoHeader.SetRange("Bill-to Customer No.", BillToCustomerNo);
        ServiceCrMemoHeader.FindFirst();
        ServiceCrMemoHeader.TestField("Posting Date", PostingDate);
        ServiceCrMemoHeader.TestField("Document Date", WorkDate());
        ServiceCrMemoHeader.TestField("Operation Occurred Date", PostingDate);
    end;

    local procedure VerifyServiceCrMemoHeaderNotExist(BillToCustomerNo: Code[20])
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        ServiceCrMemoHeader.SetRange("Bill-to Customer No.", BillToCustomerNo);
        Assert.IsFalse(ServiceCrMemoHeader.FindFirst(), ValueMustNotExistMsg);
    end;

    local procedure VerifyServiceInvoiceHeader(BillToCustomerNo: Code[20]; PostingDate: Date)
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        ServiceInvoiceHeader.SetRange("Bill-to Customer No.", BillToCustomerNo);
        ServiceInvoiceHeader.FindFirst();
        ServiceInvoiceHeader.TestField("Posting Date", PostingDate);
        ServiceInvoiceHeader.TestField("Document Date", WorkDate());
        ServiceInvoiceHeader.TestField("Operation Occurred Date", PostingDate);
    end;

    local procedure VerifyServiceInvoiceHeaderNotExist(BillToCustomerNo: Code[20])
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        ServiceInvoiceHeader.SetRange("Bill-to Customer No.", BillToCustomerNo);
        Assert.IsFalse(ServiceInvoiceHeader.FindFirst(), ValueMustNotExistMsg);
    end;

    local procedure VerifyPurchaseOrderOperationAndDocumentDate(BuyFromVendorNo: Code[20]; DocumentDate: Date)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        FindPurchaseHeader(PurchaseHeader, BuyFromVendorNo, PurchaseHeader."Document Type"::Order);
        PurchaseHeader.TestField("Operation Occurred Date", PurchaseHeader."Posting Date");
        PurchaseHeader.TestField("Document Date", DocumentDate);
    end;

    local procedure VerifySalesOrderOperationAndDocumentDate(SellToCustomerNo: Code[20]; DocumentDate: Date)
    var
        SalesHeader: Record "Sales Header";
    begin
        FindSalesHeader(SalesHeader, SellToCustomerNo, SalesHeader."Document Type"::Order);
        SalesHeader.TestField("Operation Occurred Date", SalesHeader."Posting Date");
        SalesHeader.TestField("Document Date", DocumentDate);
    end;

    local procedure VerifyNoSeriesLine(var NoSeriesLine: Record "No. Series Line"; NoSeriesCode: Code[20]; PostingDate: Date)
    begin
        NoSeriesLine.SetRange("Series Code", NoSeriesCode);
        NoSeriesLine.SetFilter("Starting Date", '<%1', WorkDate());
        NoSeriesLine.FindLast();
        NoSeriesLine.TestField("Last Date Used", PostingDate);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BatchPostPurchCreditMemosRequestPageHandler(var BatchPostPurchCreditMemos: TestRequestPage "Batch Post Purch. Credit Memos")
    var
        PostingDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(PostingDate);
        BatchPostPurchCreditMemos.PostingDate.SetValue(PostingDate);
        BatchPostPurchCreditMemos.ReplacePostingDate.SetValue(true);
        BatchPostPurchCreditMemos.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BatchPostPurchRetOrdersRequestPageHandler(var BatchPostPurchRetOrders: TestRequestPage "Batch Post Purch. Ret. Orders")
    var
        PostingDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(PostingDate);
        BatchPostPurchRetOrders.Ship.SetValue(true);
        BatchPostPurchRetOrders.Invoice.SetValue(true);
        BatchPostPurchRetOrders.PostingDate.SetValue(PostingDate);
        BatchPostPurchRetOrders.ReplacePostingDate.SetValue(true);
        BatchPostPurchRetOrders.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BatchPostPurchaseOrdersRequestPageHandler(var BatchPostPurchaseOrders: TestRequestPage "Batch Post Purchase Orders")
    var
        PostingDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(PostingDate);
        BatchPostPurchaseOrders.Receive.SetValue(true);
        BatchPostPurchaseOrders.Invoice.SetValue(true);
        BatchPostPurchaseOrders.PostingDate.SetValue(PostingDate);
        BatchPostPurchaseOrders.ReplacePostingDate.SetValue(true);
        BatchPostPurchaseOrders.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BatchPostPurchaseInvoicesRequestPageHandler(var BatchPostPurchaseInvoices: TestRequestPage "Batch Post Purchase Invoices")
    var
        PostingDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(PostingDate);
        BatchPostPurchaseInvoices.PostingDate.SetValue(PostingDate);
        BatchPostPurchaseInvoices.ReplacePostingDate.SetValue(true);
        BatchPostPurchaseInvoices.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BatchPostSalesCreditMemosRequestPageHandler(var BatchPostSalesCreditMemos: TestRequestPage "Batch Post Sales Credit Memos")
    var
        PostingDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(PostingDate);
        BatchPostSalesCreditMemos.PostingDate.SetValue(PostingDate);
        BatchPostSalesCreditMemos.ReplacePostingDate.SetValue(true);
        BatchPostSalesCreditMemos.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BatchPostSalesInvoicesRequestPageHandler(var BatchPostSalesInvoices: TestRequestPage "Batch Post Sales Invoices")
    var
        PostingDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(PostingDate);
        BatchPostSalesInvoices.PostingDate.SetValue(PostingDate);
        BatchPostSalesInvoices.ReplacePostingDate.SetValue(true);
        BatchPostSalesInvoices.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BatchPostSalesReturnOrdersRequestPageHandler(var BatchPostSalesReturnOrders: TestRequestPage "Batch Post Sales Return Orders")
    var
        PostingDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(PostingDate);
        BatchPostSalesReturnOrders.PostingDateReq.SetValue(PostingDate);
        BatchPostSalesReturnOrders.ReceiveReq.SetValue(true);
        BatchPostSalesReturnOrders.InvReq.SetValue(true);
        BatchPostSalesReturnOrders.ReplacePostingDate.SetValue(true);
        BatchPostSalesReturnOrders.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BatchPostServiceCreditMemosRequestPageHandler(var BatchPostServiceCrMemos: TestRequestPage "Batch Post Service Cr. Memos")
    var
        PostingDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(PostingDate);
        BatchPostServiceCrMemos.PostingDate.SetValue(PostingDate);
        BatchPostServiceCrMemos.ReplacePostingDate.SetValue(true);
        BatchPostServiceCrMemos.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BatchPostServiceInvoicesRequestPageHandler(var BatchPostServiceInvoices: TestRequestPage "Batch Post Service Invoices")
    var
        PostingDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(PostingDate);
        BatchPostServiceInvoices.PostingDate.SetValue(PostingDate);
        BatchPostServiceInvoices.ReplacePostingDate.SetValue(true);
        BatchPostServiceInvoices.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BatchPostServiceOrdersRequestPageHandler(var BatchPostServiceOrders: TestRequestPage "Batch Post Service Orders")
    var
        PostingDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(PostingDate);
        BatchPostServiceOrders.Ship.SetValue(true);
        BatchPostServiceOrders.Invoice.SetValue(true);
        BatchPostServiceOrders.PostingDate.SetValue(PostingDate);
        BatchPostServiceOrders.ReplacePostingDate_Option.SetValue(true);
        BatchPostServiceOrders.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text)
    begin
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure RecallNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendErrorNotificationHandler(var Notification: Notification): Boolean
    begin
        LibraryVariableStorage.Enqueue(Notification.Message);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderPageHandler(var SalesOrder: TestPage "Sales Order")
    begin
    end;
}

