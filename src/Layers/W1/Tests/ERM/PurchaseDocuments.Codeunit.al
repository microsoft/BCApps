codeunit 134099 "Purchase Documents"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Purchase]
    end;

    var
        RefVendorLedgerEntry: Record "Vendor Ledger Entry";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryTimeSheet: Codeunit "Library - Time Sheet";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryNonDeductibleVAT: Codeunit "Library - NonDeductible VAT";
        Assert: Codeunit Assert;
        PurchaseAlreadyExistsTxt: Label 'Purchase %1 %2 already exists for this vendor.', Comment = '%1 = Document Type; %2 = Document No.';
        IsInitialized: Boolean;
        WrongReportInvokedErr: Label 'Wrong report invoked.';
        ZeroQuantityInLineErr: Label 'One or more document lines with a value in the No. field do not have a quantity specified.';
        PurchLinesNotUpdatedMsg: Label 'You have changed %1 on the purchase header, but it has not been changed on the existing purchase lines.', Comment = 'You have changed Posting Date on the purchase header, but it has not been changed on the existing purchase lines.';
        PurchLinesNotUpdatedDateMsg: Label 'You have changed the %1 on the purchase header, which might affect the prices and discounts on the purchase lines.';
        ReviewLinesManuallyMsg: Label 'You should review the lines and manually update prices and discounts if needed.';
        AffectExchangeRateMsg: Label 'The change may affect the exchange rate that is used for price calculation on the purchase lines.';
        SplitMessageTxt: Label '%1\%2', Comment = 'Some message text 1.\Some message text 2.', Locked = true;
        UpdateManuallyMsg: Label 'You must update the existing purchase lines manually.';
        ConfirmZeroQuantityPostingMsg: Label 'One or more document lines with a value in the No. field do not have a quantity specified. \Do you want to continue?';
        PostedPurchaseInvoiceNotFoundLbl: Label 'Posted Purchase Invoice %1 not found', Comment = '%1 = Posted Purchase Invoice No.';
        DocAmountFieldVisibleErr: Label 'The field %1 should be visible on the purchase invoice page.', Comment = '%1 = Field Caption';

    [Test]
    [HandlerFunctions('RecallNotificationHandler,SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure VendorInvoiceNoNotificationForInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        PurchaseInvoice: TestPage "Purchase Invoice";
        ExternalDocumentNo: Code[35];
        VendorNo: Code[20];
    begin
        // [FEATURE] [External Document No.] [UI]
        // [SCENARIO 223191] Notification appears in the purchase invoice page in case of Vendor Invoice No. already used for another invoice
        Initialize();
        LibraryERM.SetEnableDataCheck(false);

        // [GIVEN] Enable "Show purchase document with same external document number already exists" Notification
        EnableShowExternalDocAlreadyExistNotification();

        // [GIVEN] Create and post purchase invoice with Vendor Invoice No. = XXX
        CreatePostPurchDocWithExternalDocNo(
          ExternalDocumentNo, VendorNo, PurchaseHeader."Document Type"::Invoice, PurchaseHeader);

        // [GIVEN] Create new invoice and open it in the Purchase Invoice page
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchaseHeader);

        // [WHEN] Vendor Invoice No. field is being filled in by XXX value
        PurchaseInvoice."Vendor Invoice No.".SetValue(ExternalDocumentNo);

        // [THEN] Notification "Purchase Invoice XXX already exists for this vendor" appears
        VerifyNotificationData(
          ExternalDocumentNo, GetLastVendorLedgerEntryNo(VendorNo), RefVendorLedgerEntry."Document Type"::Invoice);

        NotificationLifecycleMgt.RecallAllNotifications();
        LibraryERM.SetEnableDataCheck(true);
    end;

    [Test]
    [HandlerFunctions('RecallNotificationHandler,SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure VendorInvoiceNoNotificationForOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        PurchaseOrder: TestPage "Purchase Order";
        ExternalDocumentNo: Code[35];
        VendorNo: Code[20];
    begin
        // [FEATURE] [External Document No.] [UI]
        // [SCENARIO 223191] Notification appears it the purchase order page in case of Vendor Invoice No. already used for another invoice
        Initialize();
        LibraryERM.SetEnableDataCheck(false);

        // [GIVEN] Enable "Show purchase document with same external document number already exists" Notification
        EnableShowExternalDocAlreadyExistNotification();

        // [GIVEN] Create and post purchase order with Vendor Invoice No. = XXX
        CreatePostPurchDocWithExternalDocNo(
          ExternalDocumentNo, VendorNo, PurchaseHeader."Document Type"::Order, PurchaseHeader);

        // [GIVEN] Create new order and open it in the Purchase Order page
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);

        // [WHEN] Vendor Invoice No. field is being filled in by XXX value
        PurchaseOrder."Vendor Invoice No.".SetValue(ExternalDocumentNo);

        // [THEN] Notification "Purchase Invoice XXX already exists for this vendor" appears
        VerifyNotificationData(
          ExternalDocumentNo, GetLastVendorLedgerEntryNo(VendorNo), RefVendorLedgerEntry."Document Type"::Invoice);

        NotificationLifecycleMgt.RecallAllNotifications();
        LibraryERM.SetEnableDataCheck(true);
    end;

    [Test]
    [HandlerFunctions('RecallNotificationHandler,SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure VendorCrMemoNoNotificationForCreditMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        ExternalDocumentNo: Code[35];
        VendorNo: Code[20];
    begin
        // [FEATURE] [External Document No.] [UI]
        // [SCENARIO 223191] Notification appears it the purchase credit memo page in case of Vendor Cr. Memo No. already used for another credit memo
        Initialize();
        LibraryERM.SetEnableDataCheck(false);

        // [GIVEN] Enable "Show purchase document with same external document number already exists" Notification
        EnableShowExternalDocAlreadyExistNotification();

        // [GIVEN] Create and post purchase credit memo with Vendor Cr. Memo No. = XXX
        CreatePostPurchDocWithExternalDocNo(
          ExternalDocumentNo, VendorNo, PurchaseHeader."Document Type"::"Credit Memo", PurchaseHeader);

        // [GIVEN] Create new credit memo and open it in the Purchase Credit Memo page
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VendorNo);
        PurchaseCreditMemo.OpenEdit();
        PurchaseCreditMemo.GotoRecord(PurchaseHeader);

        // [WHEN] Vendor Cr. Memo No. field is being filled in by XXX value
        PurchaseCreditMemo."Vendor Cr. Memo No.".SetValue(ExternalDocumentNo);

        // [THEN] Notification "Purchase Credit Memo XXX already exists for this vendor" appears
        VerifyNotificationData(
          ExternalDocumentNo, GetLastVendorLedgerEntryNo(VendorNo), RefVendorLedgerEntry."Document Type"::"Credit Memo");

        NotificationLifecycleMgt.RecallAllNotifications();
        LibraryERM.SetEnableDataCheck(true);
    end;

    [Test]
    [HandlerFunctions('RecallNotificationHandler,SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure VendorCrMemoNoNotificationForReturnOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
        ExternalDocumentNo: Code[35];
        VendorNo: Code[20];
    begin
        // [FEATURE] [External Document No.] [UI]
        // [SCENARIO 223191] Notification appears it the purchase return order page in case of Vendor Cr. Memo No. already used for another return order
        Initialize();
        LibraryERM.SetEnableDataCheck(false);
        UpdateNoSeriesOnPurchaseSetup();

        // [GIVEN] Enable "Show purchase document with same external document number already exists" Notification
        EnableShowExternalDocAlreadyExistNotification();

        // [GIVEN] Create and post purchase return order with Vendor Cr. Memo No. = XXX
        CreatePostPurchDocWithExternalDocNo(
          ExternalDocumentNo, VendorNo, PurchaseHeader."Document Type"::"Return Order", PurchaseHeader);

        // [GIVEN] Create new return order and open it in the Purchase Return Order page
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", VendorNo);
        PurchaseReturnOrder.OpenEdit();
        PurchaseReturnOrder.GotoRecord(PurchaseHeader);

        // [WHEN] Vendor Cr. Memo No. field is being filled in by XXX value
        PurchaseReturnOrder."Vendor Cr. Memo No.".SetValue(ExternalDocumentNo);

        // [THEN] Notification "Purchase Credit Memo XXX already exists for this vendor" appears
        VerifyNotificationData(
          ExternalDocumentNo, GetLastVendorLedgerEntryNo(VendorNo), RefVendorLedgerEntry."Document Type"::"Credit Memo");

        NotificationLifecycleMgt.RecallAllNotifications();
        LibraryERM.SetEnableDataCheck(true);
    end;

    [Test]
    [HandlerFunctions('RecallNotificationHandler,SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure VendorInvoiceNoNotificationNoMyNotifications()
    var
        PurchaseHeader: Record "Purchase Header";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        PurchaseInvoice: TestPage "Purchase Invoice";
        ExternalDocumentNo: Code[35];
        VendorNo: Code[20];
    begin
        // [FEATURE] [External Document No.] [UI]
        // [SCENARIO 300997] Notification appears it the purchase invoice page in case of Vendor Invoice No. already used for another invoice when there are no My Notification records
        Initialize();
        LibraryERM.SetEnableDataCheck(false);

        // [GIVEN] Delete all My Notification records
        ClearMyNotification();

        // [GIVEN] Create and post purchase invoice with Vendor Invoice No. = XXX
        CreatePostPurchDocWithExternalDocNo(
          ExternalDocumentNo, VendorNo, PurchaseHeader."Document Type"::Invoice, PurchaseHeader);

        // [GIVEN] Create new invoice and open it in the Purchase Invoice page
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchaseHeader);

        // [WHEN] Vendor Invoice No. field is being filled in by XXX value
        PurchaseInvoice."Vendor Invoice No.".SetValue(ExternalDocumentNo);

        // [THEN] Notification "Purchase Invoice XXX already exists for this vendor" appears
        VerifyNotificationData(
          ExternalDocumentNo, GetLastVendorLedgerEntryNo(VendorNo), RefVendorLedgerEntry."Document Type"::Invoice);

        NotificationLifecycleMgt.RecallAllNotifications();
        LibraryERM.SetEnableDataCheck(true);
    end;

    [Test]
    [HandlerFunctions('RecallNotificationHandler,SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure VendorCrMemoNoNotificationForCreditMemoNoMyNotifications()
    var
        PurchaseHeader: Record "Purchase Header";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        ExternalDocumentNo: Code[35];
        VendorNo: Code[20];
    begin
        // [FEATURE] [External Document No.] [UI]
        // [SCENARIO 300997] Notification appears it the purchase credit memo page in case of Vendor Cr. Memo No. already used for another credit memo when there are no My Notification records
        Initialize();
        LibraryERM.SetEnableDataCheck(false);

        // [GIVEN] Delete all My Notification records
        ClearMyNotification();

        // [GIVEN] Enable "Show purchase document with same external document number already exists" Notification
        EnableShowExternalDocAlreadyExistNotification();

        // [GIVEN] Create and post purchase credit memo with Vendor Cr. Memo No. = XXX
        CreatePostPurchDocWithExternalDocNo(
          ExternalDocumentNo, VendorNo, PurchaseHeader."Document Type"::"Credit Memo", PurchaseHeader);

        // [GIVEN] Create new credit memo and open it in the Purchase Credit Memo page
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VendorNo);
        PurchaseCreditMemo.OpenEdit();
        PurchaseCreditMemo.GotoRecord(PurchaseHeader);

        // [WHEN] Vendor Cr. Memo No. field is being filled in by XXX value
        PurchaseCreditMemo."Vendor Cr. Memo No.".SetValue(ExternalDocumentNo);

        // [THEN] Notification "Purchase Credit Memo XXX already exists for this vendor" appears
        VerifyNotificationData(
          ExternalDocumentNo, GetLastVendorLedgerEntryNo(VendorNo), RefVendorLedgerEntry."Document Type"::"Credit Memo");

        NotificationLifecycleMgt.RecallAllNotifications();
        LibraryERM.SetEnableDataCheck(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdatePurchLinesByNo_UT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 252750] Purchase Lines can be updated using the PurchHeader.UpdatePurchLinesByNo method.
        Initialize();

        CreatePurchaseOrderWithLineTypeItem(PurchaseHeader, PurchaseLine);
        PurchaseHeader."Expected Receipt Date" := LibraryRandom.RandDateFrom(WorkDate(), 100);
        PurchaseHeader.Modify(true);
        PurchaseHeader.UpdatePurchLinesByFieldNo(PurchaseHeader.FieldNo("Expected Receipt Date"), false);

        PurchaseLine.Find();
        PurchaseLine.TestField("Expected Receipt Date", PurchaseHeader."Expected Receipt Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdatePurchLines_UT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 252750] Purchase Lines can be updated using the PurchHeader.UpdatePurchLines method.
        Initialize();

        CreatePurchaseOrderWithLineTypeItem(PurchaseHeader, PurchaseLine);
        PurchaseHeader."Expected Receipt Date" := LibraryRandom.RandDateFrom(WorkDate(), 100);
        PurchaseHeader.Modify(true);
        PurchaseHeader.UpdatePurchLines(PurchaseHeader.FieldCaption("Expected Receipt Date"), false);

        PurchaseLine.Find();
        PurchaseLine.TestField("Expected Receipt Date", PurchaseHeader."Expected Receipt Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure COD351_InsertPurchaseCreditMemoWithExistingLines()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO 261555] COD351.DefaultPurchaseDocuments handle "Purchase Header".INSERT event only when "RunTrigger" is TRUE
        Initialize();

        VerifyTransactionTypeWhenInsertPurchaseDocument(PurchaseHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure COD351_InsertPurchaseReturnOrderWithExistingLines()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Return Order]
        // [SCENARIO 261555] COD351.DefaultPurchaseDcouments handle "Purchase Header".INSERT event only when "RunTrigger" is TRUE
        Initialize();

        VerifyTransactionTypeWhenInsertPurchaseDocument(PurchaseHeader."Document Type"::"Return Order");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure COD351_InsertPurchaseInvoiceWithExistingLines()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 261555] COD351.DefaultPurchaseDcouments handle "Purchase Header".INSERT event only when "RunTrigger" is TRUE
        Initialize();

        VerifyTransactionTypeWhenInsertPurchaseDocument(PurchaseHeader."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure COD351_InsertPurchaseOrderWithExistingLines()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Order]
        // [SCENARIO 261555] COD351.DefaultPurchaseDcouments handle "Purchase Header".INSERT event only when "RunTrigger" is TRUE
        Initialize();

        VerifyTransactionTypeWhenInsertPurchaseDocument(PurchaseHeader."Document Type"::Order);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure PostPurchaseInvoiceCardWithBlankQuantityIsFoundationFALSE()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [FEATURE] [Invoice] [UI]
        // [SCENARIO 266493] Stan can post purchase invoice having line with zero quantity from card page when foundation setup is disabled
        Initialize();

        CreatePurchaseDocumentWithTwoLinesSecondLineQuantityZero(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);
        Commit();

        PurchaseInvoice.OpenView();
        PurchaseInvoice.GotoRecord(PurchaseHeader);
        PurchaseInvoice.Post.Invoke();

        asserterror PurchaseHeader.Find();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure PostPurchaseInvoiceListWithBlankQuantityIsFoundationFALSE()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoices: TestPage "Purchase Invoices";
    begin
        // [FEATURE] [Invoice] [UI]
        // [SCENARIO 266493] Stan can post purchase invoice having line with zero quantity from list page when foundation setup is disabled
        Initialize();

        CreatePurchaseDocumentWithTwoLinesSecondLineQuantityZero(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);
        Commit();

        PurchaseInvoices.OpenView();
        PurchaseInvoices.GotoRecord(PurchaseHeader);
        PurchaseInvoices.PostSelected.Invoke();

        asserterror PurchaseHeader.Find();
    end;

    [Test]
    [HandlerFunctions('PurchaseQuoteRequestPageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure PrintPurchaseQuoteCardWithBlankQuantityIsFoundationFALSE()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        // [FEATURE] [Quote] [UI]
        // [SCENARIO 266493] Stan can print purchase quote having line with zero quantity from card page when foundation setup is disabled
        Initialize();

        CreatePurchaseDocumentWithTwoLinesSecondLineQuantityZero(PurchaseHeader, PurchaseHeader."Document Type"::Quote);
        Commit();

        PurchaseQuote.OpenView();
        PurchaseQuote.GotoRecord(PurchaseHeader);
        PurchaseQuote.Print.Invoke();

        PurchaseHeader.Find();

        Assert.AreEqual(REPORT::"Purchase - Quote", LibraryVariableStorage.DequeueInteger(), WrongReportInvokedErr);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PurchaseQuoteRequestPageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure PrintPurchaseQuoteListWithBlankQuantityIsFoundationFALSE()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseQuotes: TestPage "Purchase Quotes";
    begin
        // [FEATURE] [Quote] [UI]
        // [SCENARIO 266493] Stan can print purchase quote having line with zero quantity from list page when foundation setup is disabled
        Initialize();

        CreatePurchaseDocumentWithTwoLinesSecondLineQuantityZero(PurchaseHeader, PurchaseHeader."Document Type"::Quote);
        Commit();

        PurchaseQuotes.OpenView();
        PurchaseQuotes.GotoRecord(PurchaseHeader);
        PurchaseQuotes.Print.Invoke();

        PurchaseHeader.Find();

        Assert.AreEqual(REPORT::"Purchase - Quote", LibraryVariableStorage.DequeueInteger(), WrongReportInvokedErr);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostOrderStrMenuHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderCardWithBlankQuantityIsFoundationFALSE()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [Order] [UI]
        // [SCENARIO 266493] Stan can post purchase order having line with zero quantity from card page when foundation setup is disabled
        Initialize();

        CreatePurchaseDocumentWithTwoLinesSecondLineQuantityZero(PurchaseHeader, PurchaseHeader."Document Type"::Order);
        Commit();

        LibraryVariableStorage.Enqueue(ConfirmZeroQuantityPostingMsg);
        LibraryVariableStorage.Enqueue(true);

        PurchaseOrder.OpenView();
        PurchaseOrder.GotoRecord(PurchaseHeader);
        PurchaseOrder.Post.Invoke();

        PurchaseHeader.Find();
    end;

    [Test]
    [HandlerFunctions('PostOrderStrMenuHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderListWithBlankQuantityIsFoundationFALSE()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrderList: TestPage "Purchase Order List";
    begin
        // [FEATURE] [Order] [UI]
        // [SCENARIO 266493] Stan can post purchase order having line with zero quantity from list page when foundation setup is disabled
        Initialize();

        CreatePurchaseDocumentWithTwoLinesSecondLineQuantityZero(PurchaseHeader, PurchaseHeader."Document Type"::Order);
        Commit();

        LibraryVariableStorage.Enqueue(ConfirmZeroQuantityPostingMsg);
        LibraryVariableStorage.Enqueue(true);

        PurchaseOrderList.OpenView();
        PurchaseOrderList.GotoRecord(PurchaseHeader);
        PurchaseOrderList.Post.Invoke();

        PurchaseHeader.Find();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure PostPurchaseCreditMemoCardWithBlankQuantityIsFoundationFALSE()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // [FEATURE] [Credit Memo] [UI]
        // [SCENARIO 266493] Stan can post purchase credit memo having line with zero quantity from card page when foundation setup is disabled
        Initialize();

        CreatePurchaseDocumentWithTwoLinesSecondLineQuantityZero(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo");
        Commit();

        PurchaseCreditMemo.OpenView();
        PurchaseCreditMemo.GotoRecord(PurchaseHeader);
        PurchaseCreditMemo.Post.Invoke();

        asserterror PurchaseHeader.Find();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure PostPurchaseCreditMemoListWithBlankQuantityIsFoundationFALSE()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseCreditMemos: TestPage "Purchase Credit Memos";
    begin
        // [FEATURE] [Credit Memo] [UI]
        // [SCENARIO 266493] Stan can post purchase credit memo having line with zero quantity from list page when foundation setup is disabled
        Initialize();

        CreatePurchaseDocumentWithTwoLinesSecondLineQuantityZero(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo");
        Commit();

        PurchaseCreditMemos.OpenView();
        PurchaseCreditMemos.GotoRecord(PurchaseHeader);
        PurchaseCreditMemos.Post.Invoke();

        asserterror PurchaseHeader.Find();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseInvoiceCardWithBlankQuantityIsFoundationTRUE()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [FEATURE] [Invoice] [UI] [Application Area]
        // [SCENARIO 266493] Stan can post purchase invoice having line with zero quantity from card page when foundation setup is enabled
        Initialize();
        LibraryApplicationArea.EnableFoundationSetup();

        CreatePurchaseDocumentWithTwoLinesSecondLineQuantityZero(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);
        Commit();

        PurchaseInvoice.OpenView();
        PurchaseInvoice.GotoRecord(PurchaseHeader);
        asserterror PurchaseInvoice.Post.Invoke();

        Assert.ExpectedError(ZeroQuantityInLineErr);

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseReturnOrderCardWithBlankQuantity()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        // [FEATURE] [Invoice] [UI] [Application Area]
        // [SCENARIO 266493] Stan can post purchase Return Order having line with zero quantity from card page when foundation setup is enabled
        Initialize();

        CreatePurchaseDocumentWithTwoLinesSecondLineQuantityZero(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order");
        Commit();

        LibraryVariableStorage.Enqueue(ConfirmZeroQuantityPostingMsg);
        LibraryVariableStorage.Enqueue(false);

        PurchaseReturnOrder.OpenView();
        PurchaseReturnOrder.GotoRecord(PurchaseHeader);
        asserterror PurchaseReturnOrder.Post.Invoke();

        Assert.ExpectedError(ZeroQuantityInLineErr);

    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseInvoiceListWithBlankQuantityIsFoundationTRUE()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoices: TestPage "Purchase Invoices";
    begin
        // [FEATURE] [Invoice] [UI] [Application Area]
        // [SCENARIO 266493] Stan can post purchase invoice having line with zero quantity from list page when foundation setup is enabled
        Initialize();
        LibraryApplicationArea.EnableFoundationSetup();

        CreatePurchaseDocumentWithTwoLinesSecondLineQuantityZero(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);
        Commit();

        PurchaseInvoices.OpenView();
        PurchaseInvoices.GotoRecord(PurchaseHeader);
        asserterror PurchaseInvoices.PostSelected.Invoke();

        Assert.ExpectedError(ZeroQuantityInLineErr);

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrintPurchaseQuoteCardWithBlankQuantityIsFoundationTRUE()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        // [FEATURE] [Quote] [UI] [Application Area]
        // [SCENARIO 266493] Stan can print purchase quote having line with zero quantity from card page when foundation setup is enabled
        Initialize();
        LibraryApplicationArea.EnableFoundationSetup();

        CreatePurchaseDocumentWithTwoLinesSecondLineQuantityZero(PurchaseHeader, PurchaseHeader."Document Type"::Quote);
        Commit();

        PurchaseQuote.OpenView();
        PurchaseQuote.GotoRecord(PurchaseHeader);
        asserterror PurchaseQuote.Print.Invoke();

        Assert.ExpectedError(ZeroQuantityInLineErr);

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrintPurchaseQuoteListWithBlankQuantityIsFoundationTRUE()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseQuotes: TestPage "Purchase Quotes";
    begin
        // [FEATURE] [Quote] [UI] [Application Area]
        // [SCENARIO 266493] Stan can print purchase quote having line with zero quantity from list page when foundation setup is enabled
        Initialize();
        LibraryApplicationArea.EnableFoundationSetup();

        CreatePurchaseDocumentWithTwoLinesSecondLineQuantityZero(PurchaseHeader, PurchaseHeader."Document Type"::Quote);
        Commit();

        PurchaseQuotes.OpenView();
        PurchaseQuotes.GotoRecord(PurchaseHeader);
        asserterror PurchaseQuotes.Print.Invoke();

        Assert.ExpectedError(ZeroQuantityInLineErr);

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderCardWithBlankQuantityIsFoundationTRUE()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [Order] [UI] [Application Area]
        // [SCENARIO 266493] Stan can post purchase order having line with zero quantity from card page when foundation setup is enabled
        Initialize();
        LibraryApplicationArea.EnableFoundationSetup();

        CreatePurchaseDocumentWithTwoLinesSecondLineQuantityZero(PurchaseHeader, PurchaseHeader."Document Type"::Order);
        Commit();

        PurchaseOrder.OpenView();
        PurchaseOrder.GotoRecord(PurchaseHeader);
        asserterror PurchaseOrder.Post.Invoke();

        Assert.ExpectedError(ZeroQuantityInLineErr);

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderListWithBlankQuantityIsFoundationTRUE()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrderList: TestPage "Purchase Order List";
    begin
        // [FEATURE] [Order] [UI] [Application Area]
        // [SCENARIO 266493] Stan can post purchase order having line with zero quantity from list page when foundation setup is enabled
        Initialize();
        LibraryApplicationArea.EnableFoundationSetup();

        CreatePurchaseDocumentWithTwoLinesSecondLineQuantityZero(PurchaseHeader, PurchaseHeader."Document Type"::Order);
        Commit();

        LibraryVariableStorage.Enqueue(ConfirmZeroQuantityPostingMsg);
        LibraryVariableStorage.Enqueue(false);

        PurchaseOrderList.OpenView();
        PurchaseOrderList.GotoRecord(PurchaseHeader);
        asserterror PurchaseOrderList.Post.Invoke();

        Assert.ExpectedError(ConfirmZeroQuantityPostingMsg);

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseCreditMemoCardWithBlankQuantityIsFoundationTRUE()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // [FEATURE] [Credit Memo] [UI] [Application Area]
        // [SCENARIO 266493] Stan can post purchase credit memo having line with zero quantity from card page when foundation setup is enabled
        Initialize();
        LibraryApplicationArea.EnableFoundationSetup();

        CreatePurchaseDocumentWithTwoLinesSecondLineQuantityZero(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo");
        Commit();

        PurchaseCreditMemo.OpenView();
        PurchaseCreditMemo.GotoRecord(PurchaseHeader);
        asserterror PurchaseCreditMemo.Post.Invoke();

        Assert.ExpectedError(ZeroQuantityInLineErr);

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseCreditMemoListWithBlankQuantityIsFoundationTRUE()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseCreditMemos: TestPage "Purchase Credit Memos";
    begin
        // [FEATURE] [Credit Memo] [UI] [Application Area]
        // [SCENARIO 266493] Stan can post purchase credit memo having line with zero quantity from list page when foundation setup is enabled
        Initialize();
        LibraryApplicationArea.EnableFoundationSetup();

        CreatePurchaseDocumentWithTwoLinesSecondLineQuantityZero(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo");
        Commit();

        PurchaseCreditMemos.OpenView();
        PurchaseCreditMemos.GotoRecord(PurchaseHeader);
        asserterror PurchaseCreditMemos.Post.Invoke();

        Assert.ExpectedError(ZeroQuantityInLineErr);

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [HandlerFunctions('MessageCaptureHandler')]
    [Scope('OnPrem')]
    procedure WarningMessageWhenPostingDateIsUpdatedWithoutCurrency()
    var
        PurchaseHeader: Record "Purchase Header";
        MessageText: Text;
    begin
        // [FEATURE] [UT] [Message] [FCY]
        // [SCENARIO 282342] Warning message that Purchase Lines were not updated do not include currency related text when currency is not used
        Initialize();

        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);

        PurchaseHeader.Validate("Posting Date", WorkDate() + 1);

        MessageText := StrSubstNo(PurchLinesNotUpdatedDateMsg, PurchaseHeader.FieldCaption("Posting Date"));
        MessageText := StrSubstNo(SplitMessageTxt, MessageText, ReviewLinesManuallyMsg);

        // A message is captured by MessageCaptureHandler
        Assert.ExpectedMessage(MessageText, LibraryVariableStorage.DequeueText());

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageCaptureHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure WarningMessageWhenPostingDateIsUpdatedWithCurrency()
    var
        PurchaseHeader: Record "Purchase Header";
        Currency: Record Currency;
        MessageText: Text;
    begin
        // [FEATURE] [UT] [Message] [FCY]
        // [SCENARIO 282342] Warning message that Purchase Lines were not updated including currency related text when currency is applied
        Initialize();

        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateExchangeRate(Currency.Code, WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        PurchaseHeader.Validate("Currency Code", Currency.Code);
        PurchaseHeader.Validate("Posting Date", WorkDate() + 1);

        // A message is captured by MessageCaptureHandler
        MessageText := StrSubstNo(PurchLinesNotUpdatedDateMsg, PurchaseHeader.FieldCaption("Posting Date"));
        MessageText := StrSubstNo(SplitMessageTxt, MessageText, AffectExchangeRateMsg);
        MessageText := StrSubstNo(SplitMessageTxt, MessageText, ReviewLinesManuallyMsg);
        Assert.ExpectedMessage(MessageText, LibraryVariableStorage.DequeueText());

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageCaptureHandler')]
    [Scope('OnPrem')]
    procedure WarningMessageWhenLanguageCodeIsUpdated()
    var
        PurchaseHeader: Record "Purchase Header";
        MessageText: Text;
    begin
        // [FEATURE] [UT] [Message]
        // [SCENARIO 282342] Warning message that Purchase Lines were not updated including text for manual update
        Initialize();

        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        PurchaseHeader.Validate("Language Code", LibraryERM.GetAnyLanguageDifferentFromCurrent());

        MessageText := StrSubstNo(PurchLinesNotUpdatedMsg, PurchaseHeader.FieldCaption("Language Code"));
        MessageText := StrSubstNo(SplitMessageTxt, MessageText, UpdateManuallyMsg);

        Assert.ExpectedMessage(MessageText, LibraryVariableStorage.DequeueText());

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure PurchaserCodeClearedOnChangedVendorWithoutPurchaser()
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        LibrarySales: Codeunit "Library - Sales";
    begin
        // [FEATURE] [Salesperson Code]
        // [SCENARIO 297510] "Purchaser Code" cleared when "Buy-from Vendor No." changed to Vendor with blank "Purchaser Code"
        Initialize();

        // [GIVEN] Purchaser "SP01"
        LibrarySales.CreateSalesperson(SalespersonPurchaser);

        // [GIVEN] Vendor "V01" with "Purchaser Code" = "SP01"
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Purchaser Code", SalespersonPurchaser.Code);
        Vendor.Modify(true);

        // [GIVEN] Purchase Order Created for Vendor "V01"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        PurchaseHeader.TestField("Purchaser Code", SalespersonPurchaser.Code);

        // [GIVEN] Vendor "V02" with blank "Purchaser Code"
        LibraryPurchase.CreateVendor(Vendor);

        // [WHEN] Set "Buy-from Vendor No." = "CU02" on Purchase Order
        PurchaseHeader.Validate("Buy-from Vendor No.", Vendor."No.");

        // [THEN] "Purchaser Code" cleared on Purchase Order
        PurchaseHeader.TestField("Purchaser Code", '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure PurchaserCodeUpdatedOnChangedVendorWithPurchaser()
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        LibrarySales: Codeunit "Library - Sales";
    begin
        // [FEATURE] [Salesperson Code]
        // [SCENARIO 297510] "Purchaser Code" updated when "Buy-from Vendor No." changed to Vendor with non-blank "Purchaser Code"
        Initialize();

        // [GIVEN] Purchaser "SP01"
        LibrarySales.CreateSalesperson(SalespersonPurchaser);

        // [GIVEN] Vendor "V01" with blank "Purchaser Code"
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Purchase Order Created for Vendor "V01"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");

        // [GIVEN] Vendor "V02" with blank "Purchaser Code"
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Purchaser Code", SalespersonPurchaser.Code);
        Vendor.Modify(true);

        // [WHEN] Set "Buy-from Vendor No." = "CU02" on Purchase Order
        PurchaseHeader.Validate("Buy-from Vendor No.", Vendor."No.");

        // [THEN] "Purchaser Code" updated on Purchase Order
        PurchaseHeader.TestField("Purchaser Code", SalespersonPurchaser.Code);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure PurchaserCodeUpdatedFromUserSetupWhenVendorWithPurchaser()
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        UserSetup: Record "User Setup";
        LibrarySales: Codeunit "Library - Sales";
    begin
        // [FEATURE] [Salesperson Code]
        // [SCENARIO 297510] Vendor with blank "Purchaser Code" and Purchaser Code empty - use Purchaser from UserSetup
        Initialize();

        // [GIVEN] Purchaser "SP01"
        LibrarySales.CreateSalesperson(SalespersonPurchaser);

        // [GIVEN] User Setup with Salesperson Code
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        UserSetup.Validate("Salespers./Purch. Code", SalespersonPurchaser.Code);
        UserSetup.Modify(true);

        // [GIVEN] Purchase Order Created for Vendor "V01"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");

        // [GIVEN] Vendor "V01" with blank "Purchaser Code"
        LibraryPurchase.CreateVendor(Vendor);

        // [WHEN] Set "Buy-from Vendor No." = "CU02" on Purchase Order
        PurchaseHeader.Validate("Buy-from Vendor No.", Vendor."No.");

        // [THEN] "Purchaser Code" updated on Purchase Order
        PurchaseHeader.TestField("Purchaser Code", SalespersonPurchaser.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderDateOnPurchaseDocumentIsInitializedWithWorkDate()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocType: Enum "Purchase Document Type";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 327504] Order Date on purchase documents is initialized with WORKDATE. This is required to pick the current purchase price.
        Initialize();

        for DocType := PurchaseHeader."Document Type"::Quote to PurchaseHeader."Document Type"::"Return Order" do begin
            Clear(PurchaseHeader);
            CreatePurchaseDocument(PurchaseHeader, DocType, '');

            PurchaseHeader.TestField("Order Date", WorkDate());

            LibraryPurchase.FindFirstPurchLine(PurchaseLine, PurchaseHeader);
            PurchaseLine.TestField("Order Date", WorkDate());
        end;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure PurchaserCodeUpdatedFromVendorWithSalesperson()
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        UserSetup: Record "User Setup";
        LibrarySales: Codeunit "Library - Sales";
    begin
        // [FEATURE] [Salesperson Code]
        // [SCENARIO 297510] Vendor with "Purchaser Code" but UserSetup Purchaser Code empty - updated from Vendor
        Initialize();

        // [GIVEN] Purchaser "SP01"
        LibrarySales.CreateSalesperson(SalespersonPurchaser);

        // [GIVEN] User Setup without Salesperson Code
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        UserSetup.Validate("Salespers./Purch. Code", '');
        UserSetup.Modify(true);

        // [GIVEN] Purchase Order Created for Vendor "V01"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");

        // [GIVEN] Vendor "V02" with blank "Purchaser Code"
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Purchaser Code", SalespersonPurchaser.Code);
        Vendor.Modify(true);

        // [WHEN] Set "Buy-from Vendor No." = "CU02" on Purchase Order
        PurchaseHeader.Validate("Buy-from Vendor No.", Vendor."No.");

        // [THEN] "Purchaser Code" updated on Purchase Order
        PurchaseHeader.TestField("Purchaser Code", SalespersonPurchaser.Code);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure PurchaserCodeUpdatedFromUserSetupWhenChangingToVendorWithoutSalesperson()
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: array[2] of Record Vendor;
        SalespersonPurchaser: array[2] of Record "Salesperson/Purchaser";
        UserSetup: Record "User Setup";
        LibrarySales: Codeunit "Library - Sales";
    begin
        // [FEATURE] [Salesperson Code]
        // [SCENARIO ] Customer with blank "Salesperson Code" and Salesperson Code empty - use Salesperson from UserSetup.
        Initialize();

        // [GIVEN] Purchasers "SP01" and "SP02".
        LibrarySales.CreateSalesperson(SalespersonPurchaser[1]);
        LibrarySales.CreateSalesperson(SalespersonPurchaser[2]);

        // [GIVEN] Customer "CU01" with "Salesperson Code" = "SP01".
        LibraryPurchase.CreateVendor(Vendor[1]);
        Vendor[1].Validate("Purchaser Code", SalespersonPurchaser[1].Code);
        Vendor[1].Modify(true);

        // [GIVEN] Vendor "CU02" with blank "Purchaser Code".
        LibraryPurchase.CreateVendor(Vendor[2]);

        // [GIVEN] User Setup with Purchaser Code "SP02.
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        UserSetup.Validate("Salespers./Purch. Code", SalespersonPurchaser[2].Code);
        UserSetup.Modify(true);

        // [GIVEN] Purchase Order created for Vendor with Purchaser Code "SP01".
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor[1]."No.");

        // [WHEN] "Pay-to Vendor No." is changed to Vendor "CU02" in Purchase Order.
        PurchaseHeader.Validate("Pay-to Vendor No.", Vendor[2]."No.");

        // [THEN] Purchase Order has Salesperson Code "SP02".
        PurchaseHeader.TestField("Purchaser Code", SalespersonPurchaser[2].Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocationCodeOnInsert()
    var
        VendorWithLocation: Record Vendor;
        VendorWithoutLocation: Record Vendor;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Location]
        // [SCENARIO 333156] Location Code is not reset on record insertion
        Initialize();

        // [GIVEN] Vendor "V1" with blank "Location Code"
        LibraryPurchase.CreateVendorWithLocationCode(VendorWithoutLocation, '');

        // [GIVEN] Vendor "V2" with "Location Code" = "WHITE" and "Pay-to Vendor No." = "V1"
        LibraryWarehouse.CreateLocation(Location);
        LibraryPurchase.CreateVendorWithLocationCode(VendorWithLocation, Location.Code);
        VendorWithLocation.Validate("Pay-to Vendor No.", VendorWithoutLocation."No.");
        VendorWithLocation.Modify(true);

        // [GIVEN] New Purchase Order with "Buy-from Vendor No." set to "V2"
        PurchaseHeader.Init();
        PurchaseHeader.Validate("Buy-from Vendor No.", VendorWithLocation."No.");

        // [WHEN] Insert Purchase Order
        PurchaseHeader.Insert(true);

        // [THEN] "Location Code" = "WHITE" on the Purchase Order
        PurchaseHeader.TestField("Location Code", Location.Code);
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentPurchModalPageHandler')]
    procedure GetReceiptLinesWithItemChargeNormalOrder()
    var
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLineItem: Record "Purchase Line";
        PurchaseLineChargeItem: Record "Purchase Line";
        QtyToAssign: Decimal;
    begin
        // [FEATURE] [Get Receipt Lines] [Order] [Invoice] [Item Charge]
        // [SCENARIO 385039] "Get Receipt Lines" ignores the order of given receipt lines when it creates invoice with Item Charge
        Initialize();

        // [GIVEN] Purchase order with item and charge item for the vendor "X"
        // [GIVEN] "Qty. To Assign" = 3 in sales lines with charge item
        QtyToAssign := LibraryRandom.RandIntInRange(3, 10);

        CreatePurchaseOrderWithItemAndChargeItem(PurchaseHeaderOrder, PurchaseLineItem, PurchaseLineChargeItem, QtyToAssign);

        Commit();

        // [GIVEN] Purchase order shipped only
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, false);

        VerifyQtyToAssignInDocumentLineForChargeItem(PurchaseHeaderOrder, PurchaseLineChargeItem."No.", QtyToAssign);

        // [GIVEN] Purchase invoice for vendor "X"
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeaderInvoice, PurchaseHeaderOrder."Document Type"::Invoice, PurchaseHeaderOrder."Buy-from Vendor No.");

        // [WHEN] Call "Get Receipt Lines" with reversed order
        GetReceiptLinesWithOrder(PurchaseHeaderOrder, PurchaseHeaderInvoice, true);

        // [THEN] Charge Item line inserted with "Qty. To Assign" = 3
        VerifyQtyToAssignInDocumentLineForChargeItem(PurchaseHeaderInvoice, PurchaseLineChargeItem."No.", QtyToAssign);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentPurchModalPageHandler')]
    procedure GetReceiptLinesWithItemChargeReversedOrder()
    var
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLineItem: Record "Purchase Line";
        PurchaseLineChargeItem: Record "Purchase Line";
        QtyToAssign: Decimal;
    begin
        // [FEATURE] [Get Receipt Lines] [Order] [Invoice] [Item Charge]
        // [SCENARIO 385039] "Get Receipt Lines" ignores the order of given receipt lines when it creates invoice with Item Charge
        Initialize();

        // [GIVEN] Purchase order with item and charge item for the vendor "X"
        // [GIVEN] "Qty. To Assign" = 3 in sales lines with charge item
        QtyToAssign := LibraryRandom.RandIntInRange(3, 10);

        CreatePurchaseOrderWithItemAndChargeItem(PurchaseHeaderOrder, PurchaseLineItem, PurchaseLineChargeItem, QtyToAssign);

        Commit();

        // [GIVEN] Purchase order shipped only
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, false);

        VerifyQtyToAssignInDocumentLineForChargeItem(PurchaseHeaderOrder, PurchaseLineChargeItem."No.", QtyToAssign);

        // [GIVEN] Purchase invoice for vendor "X"
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeaderInvoice, PurchaseHeaderOrder."Document Type"::Invoice, PurchaseHeaderOrder."Buy-from Vendor No.");

        // [WHEN] Call "Get Receipt Lines" with reversed order
        GetReceiptLinesWithOrder(PurchaseHeaderOrder, PurchaseHeaderInvoice, false);

        // [THEN] Charge Item line inserted with "Qty. To Assign" = 3
        VerifyQtyToAssignInDocumentLineForChargeItem(PurchaseHeaderInvoice, PurchaseLineChargeItem."No.", QtyToAssign);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentPurchModalPageHandler')]
    procedure GetReceiptLinesWithItemChargeFirstNormalOrder()
    var
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLineItem: Record "Purchase Line";
        PurchaseLineChargeItem: Record "Purchase Line";
        QtyToAssign: Decimal;
    begin
        // [FEATURE] [Get Receipt Lines] [Order] [Invoice] [Item Charge]
        // [SCENARIO 385039] "Get Receipt Lines" ignores the order of given receipt lines when it creates invoice with Item Charge
        Initialize();

        // [GIVEN] Purchase order with charge item and item for the vendor "X"
        // [GIVEN] "Qty. To Assign" = 3 in sales line with charge item
        QtyToAssign := LibraryRandom.RandIntInRange(3, 10);

        CreatePurchaseOrderWithChargeItemAndItem(PurchaseHeaderOrder, PurchaseLineItem, PurchaseLineChargeItem, QtyToAssign);

        Commit();

        // [GIVEN] Purchase order shipped only
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, false);

        VerifyQtyToAssignInDocumentLineForChargeItem(PurchaseHeaderOrder, PurchaseLineChargeItem."No.", QtyToAssign);

        // [GIVEN] Purchase invoice for vendor "X"
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeaderInvoice, PurchaseHeaderOrder."Document Type"::Invoice, PurchaseHeaderOrder."Buy-from Vendor No.");

        // [WHEN] Call "Get Receipt Lines" with reversed order
        GetReceiptLinesWithOrder(PurchaseHeaderOrder, PurchaseHeaderInvoice, true);

        // [THEN] Charge Item line inserted with "Qty. To Assign" = 3
        VerifyQtyToAssignInDocumentLineForChargeItem(PurchaseHeaderInvoice, PurchaseLineChargeItem."No.", QtyToAssign);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentPurchModalPageHandler')]
    procedure GetReceiptLinesWithItemChargeFirstReversedOrder()
    var
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLineItem: Record "Purchase Line";
        PurchaseLineChargeItem: Record "Purchase Line";
        QtyToAssign: Decimal;
    begin
        // [FEATURE] [Get Receipt Lines] [Order] [Invoice] [Item Charge]
        // [SCENARIO 385039] "Get Receipt Lines" ignores the order of given receipt lines when it creates invoice with Item Charge
        Initialize();

        // [GIVEN] Purchase order with charge item and item for the vendor "X"
        // [GIVEN] "Qty. To Assign" = 3 in sales line with charge item
        QtyToAssign := LibraryRandom.RandIntInRange(3, 10);

        CreatePurchaseOrderWithChargeItemAndItem(PurchaseHeaderOrder, PurchaseLineItem, PurchaseLineChargeItem, QtyToAssign);

        Commit();

        // [GIVEN] Purchase order shipped only
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, false);

        VerifyQtyToAssignInDocumentLineForChargeItem(PurchaseHeaderOrder, PurchaseLineChargeItem."No.", QtyToAssign);

        // [GIVEN] Purchase invoice for vendor "X"
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeaderInvoice, PurchaseHeaderOrder."Document Type"::Invoice, PurchaseHeaderOrder."Buy-from Vendor No.");

        // [WHEN] Call "Get Receipt Lines" with reversed order
        GetReceiptLinesWithOrder(PurchaseHeaderOrder, PurchaseHeaderInvoice, false);

        // [THEN] Charge Item line inserted with "Qty. To Assign" = 3
        VerifyQtyToAssignInDocumentLineForChargeItem(PurchaseHeaderInvoice, PurchaseLineChargeItem."No.", QtyToAssign);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentPurchModalPageHandler,MessageHandler')]
    procedure GetReceiptLinesFromEmptyFilteredRecord()
    var
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLineItem: Record "Purchase Line";
        PurchaseLineChargeItem: Record "Purchase Line";
        PurchaseLineInvoice: Record "Purchase Line";
        QtyToAssign: Decimal;
    begin
        // [FEATURE] [Get Receipt Lines] [Order] [Invoice] [Item Charge] [FCY]
        // [SCENARIO 385039] "Get Receipt Lines" does not insert lines into invoice when invoice's currency differs from receipt's currency
        Initialize();

        QtyToAssign := LibraryRandom.RandIntInRange(3, 10);

        CreatePurchaseOrderWithChargeItemAndItem(PurchaseHeaderOrder, PurchaseLineItem, PurchaseLineChargeItem, QtyToAssign);

        Commit();

        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, false);

        VerifyQtyToAssignInDocumentLineForChargeItem(PurchaseHeaderOrder, PurchaseLineChargeItem."No.", QtyToAssign);

        LibraryPurchase.CreatePurchHeader(
          PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, PurchaseHeaderOrder."Sell-to Customer No.");
        PurchaseHeaderInvoice.Validate("Currency Code", LibraryERM.CreateCurrencyWithRandomExchRates());
        PurchaseHeaderInvoice.Modify(true);

        GetReceiptLinesWithOrder(PurchaseHeaderOrder, PurchaseHeaderInvoice, false);

        PurchaseLineInvoice.SetRange("Document Type", PurchaseHeaderInvoice."Document Type");
        PurchaseLineInvoice.SetRange("Document No.", PurchaseHeaderInvoice."No.");
        Assert.RecordIsEmpty(PurchaseLineInvoice);
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentPurchModalPageHandler,ConfirmHandlerTrue')]
    procedure GetReceiptLinesWithItemCharge_Receipt_UndoReceipt_Receipt()
    var
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLineItem: Record "Purchase Line";
        PurchaseLineChargeItem: Record "Purchase Line";
        QtyToAssign: Decimal;
    begin
        // [FEATURE] [Get Receipt Lines] [Order] [Invoice] [Item Charge]
        // [SCENARIO 385039] "Get Receipt Lines" doesn't pull item charge assignment from undone receipt lines
        Initialize();

        QtyToAssign := LibraryRandom.RandIntInRange(3, 10);

        CreatePurchaseOrderWithChargeItemAndItem(PurchaseHeaderOrder, PurchaseLineItem, PurchaseLineChargeItem, QtyToAssign);

        Commit();

        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, false);

        VerifyQtyToAssignInDocumentLineForChargeItem(PurchaseHeaderOrder, PurchaseLineChargeItem."No.", QtyToAssign);

        UndoReceipt(PurchaseHeaderOrder);

        VerifyQtyToAssignInDocumentLineForChargeItem(PurchaseHeaderOrder, PurchaseLineChargeItem."No.", QtyToAssign);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, false);

        VerifyQtyToAssignInDocumentLineForChargeItem(PurchaseHeaderOrder, PurchaseLineChargeItem."No.", QtyToAssign);

        LibraryPurchase.CreatePurchHeader(
          PurchaseHeaderInvoice, PurchaseHeaderOrder."Document Type"::Invoice, PurchaseHeaderOrder."Buy-from Vendor No.");

        GetReceiptLinesWithOrder(PurchaseHeaderOrder, PurchaseHeaderInvoice, false);

        VerifyQtyToAssignInDocumentLineForChargeItem(PurchaseHeaderInvoice, PurchaseLineChargeItem."No.", QtyToAssign);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderDefaultLineType_Empty_UT()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseLineType: Enum "Purchase Line Type";
    begin
        // [SCENARIO 326906] Purchase order line "Type" = "Document Default Line Type" from purchase setup when InitType()
        Initialize();

        // [GIVEN] Purchases & payables setup "Document Default Line Type" = " "
        PurchaseLineType := PurchaseLineType::" ";
        SetDocumentDefaultLineType(PurchaseLineType);

        // [WHEN] Init purchase line type
        InitPurchaseLineType(PurchaseLine);

        // [THEN] Purchase order line "Type" = "Document Default Line Type"
        VerifyPurchaseLineType(PurchaseLine, PurchaseLineType);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderDefaultLineType_ChargeItem_UT()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseLineType: Enum "Purchase Line Type";
    begin
        // [SCENARIO 326906] Purchase order line "Type" = "Document Default Line Type" from purchase setup when InitType()
        Initialize();

        // [GIVEN] Purchases & payables setup "Document Default Line Type" = "Charge (Item)"
        PurchaseLineType := PurchaseLineType::"Charge (Item)";
        SetDocumentDefaultLineType(PurchaseLineType);

        // [WHEN] Init purchase line type
        InitPurchaseLineType(PurchaseLine);

        // [THEN] Purchase order line "Type" = "Document Default Line Type"
        VerifyPurchaseLineType(PurchaseLine, PurchaseLineType);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderDefaultLineType_FixedAsset_UT()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseLineType: Enum "Purchase Line Type";
    begin
        // [SCENARIO 326906] Purchase order line "Type" = "Document Default Line Type" from purchase setup when InitType()
        Initialize();

        // [GIVEN] Purchases & payables setup "Document Default Line Type" = "Fixed Asset"
        PurchaseLineType := PurchaseLineType::"Fixed Asset";
        SetDocumentDefaultLineType(PurchaseLineType);

        // [WHEN] Init purchase line type
        InitPurchaseLineType(PurchaseLine);

        // [THEN] Purchase order line "Type" = "Document Default Line Type"
        VerifyPurchaseLineType(PurchaseLine, PurchaseLineType);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderDefaultLineType_GLAccount_UT()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseLineType: Enum "Purchase Line Type";
    begin
        // [SCENARIO 326906] Purchase order line "Type" = "Document Default Line Type" from purchase setup when InitType()
        Initialize();

        // [GIVEN] Purchases & payables setup "Document Default Line Type" = "G/L Account"
        PurchaseLineType := PurchaseLineType::"G/L Account";
        SetDocumentDefaultLineType(PurchaseLineType);

        // [WHEN] Init purchase line type
        InitPurchaseLineType(PurchaseLine);

        // [THEN] Purchase order line "Type" = "Document Default Line Type"
        VerifyPurchaseLineType(PurchaseLine, PurchaseLineType);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderDefaultLineType_Item_UT()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseLineType: Enum "Purchase Line Type";
    begin
        // [SCENARIO 326906] Purchase order line "Type" = "Document Default Line Type" from purchase setup when InitType()
        Initialize();

        // [GIVEN] Purchases & payables setup "Document Default Line Type" = Item
        PurchaseLineType := PurchaseLineType::Item;
        SetDocumentDefaultLineType(PurchaseLineType);

        // [WHEN] Init purchase line type
        InitPurchaseLineType(PurchaseLine);

        // [THEN] Purchase order line "Type" = "Document Default Line Type"
        VerifyPurchaseLineType(PurchaseLine, PurchaseLineType);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderDefaultLineType_Resource_UT()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseLineType: Enum "Purchase Line Type";
    begin
        // [SCENARIO 326906] Purchase order line "Type" = "Document Default Line Type" from purchase setup when InitType()
        Initialize();

        // [GIVEN] Purchases & payables setup "Document Default Line Type" = Resource
        PurchaseLineType := PurchaseLineType::Resource;
        SetDocumentDefaultLineType(PurchaseLineType);

        // [WHEN] Init purchase line type
        InitPurchaseLineType(PurchaseLine);

        // [THEN] Purchase order line "Type" = "Document Default Line Type"
        VerifyPurchaseLineType(PurchaseLine, PurchaseLineType);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    procedure UpdateContactInfoAfterChangeBuyfromContactNoinPurchaseOrderByValidatePageField()
    var
        Vendor: Record Vendor;
        Contact: Record Contact;
        Contact2: Record Contact;
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 414694] When user change Buy-from Contact No. in Purchase Order card then contact info must be updated 
        Initialize();

        // [GIVEN] Vendor with two contacts
        // [GIVEN] First contact "C1" with phone = "111111111", mobile phone = "222222222" and email = "contact1@mail.com"
        // [GIVEN] Second contact "C2" with phone = "333333333", mobile phone = "444444444" and email = "contact2@mail.com"
        LibraryMarketing.CreateContactWithVendor(Contact, Vendor);
        UpdateContactInfo(Contact, '111111111', '222222222', 'contact1@mail.com');
        Contact.Modify(true);
        Vendor.Validate("Primary Contact No.", Contact."No.");
        Vendor.Modify(true);
        LibraryMarketing.CreatePersonContact(Contact2);
        UpdateContactInfo(Contact2, '333333333', '444444444', 'contact2@mail.com');
        Contact2.Validate("Company No.", Contact."Company No.");
        Contact2.Modify(true);

        // [GIVEN] Purchase Order with "Buy-from Contact No." = "C1"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        PurchaseOrder.Trap();
        Page.Run(Page::"Purchase Order", PurchaseHeader);

        // [WHEN] User set "Buy-from Contact No." = "C2" by validate page field
        PurchaseOrder."Buy-from Contact No.".SetValue(Contact2."No.");

        // [THEN] "Purchase Order"."Phone No." = "333333333"
        PurchaseOrder.BuyFromContactPhoneNo.AssertEquals(Contact2."Phone No.");

        // [THEN] "Purchase Order"."Mobile Phone No." = "444444444"
        PurchaseOrder.BuyFromContactMobilePhoneNo.AssertEquals(Contact2."Mobile Phone No.");

        // [THEN] "Purchase Order"."Email" = "contact2@mail.com"
        PurchaseOrder.BuyFromContactEmail.AssertEquals(Contact2."E-Mail");
    end;

    [Test]
    [HandlerFunctions('ContactListPageHandler,ConfirmHandlerTrue')]
    procedure UpdateContactInfoAfterChangeBuyfromContactNoinPurchaseOrderCardByLookup()
    var
        Vendor: Record Vendor;
        Contact: Record Contact;
        Contact2: Record Contact;
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] When user change Buy-from Contact No. in Purchase Order then contact info must be updated
        Initialize();

        // [GIVEN] Vendor with two contacts
        // [GIVEN] First contact "C1" with phone = "111111111", mobile phone = "222222222" and email = "contact1@mail.com"
        // [GIVEN] Second contact "C2" with phone = "333333333", mobile phone = "444444444" and email = "contact2@mail.com"
        LibraryMarketing.CreateContactWithVendor(Contact, Vendor);
        UpdateContactInfo(Contact, '111111111', '222222222', 'contact1@mail.com');
        Contact.Modify(true);
        Vendor.Validate("Primary Contact No.", Contact."No.");
        Vendor.Modify(true);
        LibraryMarketing.CreatePersonContact(Contact2);
        UpdateContactInfo(Contact2, '333333333', '444444444', 'contact2@mail.com');
        Contact2.Validate("Company No.", Contact."Company No.");
        Contact2.Modify(true);

        // [GIVEN] Purchase Order with "Buy-from Contact No." = "C1"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        PurchaseOrder.Trap();
        Page.Run(Page::"Purchase Order", PurchaseHeader);

        // [WHEN] User set "Buy-from Contact No." = "C2" by validate page field
        LibraryVariableStorage.Enqueue(Contact2."No.");
        PurchaseOrder."Buy-from Contact No.".Lookup();

        // [THEN] "Purchase Order"."Phone No." = "333333333"
        PurchaseOrder.BuyFromContactPhoneNo.AssertEquals(Contact2."Phone No.");

        // [THEN] "Purchase Order"."Mobile Phone No." = "444444444"
        PurchaseOrder.BuyFromContactMobilePhoneNo.AssertEquals(Contact2."Mobile Phone No.");

        // [THEN] "Purchase Order"."Email" = "contact2@mail.com"
        PurchaseOrder.BuyFromContactEmail.AssertEquals(Contact2."E-Mail");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ContactListPageHandler,ConfirmHandlerCount')]
    procedure PurchaseOrderContactChangeLookupBilltoContactAskedOnce()
    var
        Vendor: Record Vendor;
        Contact: Record Contact;
        Contact2: Record Contact;
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] When user change Buy-from Contact No. in Purchase Order then contact info must be updated
        Initialize();

        // [GIVEN] Vendor with two contacts
        // [GIVEN] First contact "C1" with phone = "111111111", mobile phone = "222222222" and email = "contact1@mail.com"
        // [GIVEN] Second contact "C2" with phone = "333333333", mobile phone = "444444444" and email = "contact2@mail.com"
        LibraryMarketing.CreateContactWithVendor(Contact, Vendor);
        UpdateContactInfo(Contact, '111111111', '222222222', 'contact1@mail.com');
        Contact.Modify(true);
        Vendor.Validate("Primary Contact No.", Contact."No.");
        Vendor.Modify(true);
        LibraryMarketing.CreatePersonContact(Contact2);
        UpdateContactInfo(Contact2, '333333333', '444444444', 'contact2@mail.com');
        Contact2.Validate("Company No.", Contact."Company No.");
        Contact2.Modify(true);

        // [GIVEN] Purchase Order with "Buy-from Contact No." = "C1"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        PurchaseOrder.Trap();
        Page.Run(Page::"Purchase Order", PurchaseHeader);

        // [WHEN] User set "Buy-from Contact No." = "C2" by validate page field
        LibraryVariableStorage.Enqueue(Contact2."No.");
        LibraryVariableStorage.Enqueue(true);  // true for "Do you want to change Sell-to Contact No.?"
        LibraryVariableStorage.Enqueue(0);     // init value for count of confirmation handlers
        LibraryVariableStorage.Enqueue(false); // false for "Do you want to change Bill-to Contact No.?"
        PurchaseOrder."Buy-from Contact No.".Lookup();

        // [THEN] "Purchase Order"."Phone No." = "333333333"
        PurchaseOrder.BuyFromContactPhoneNo.AssertEquals(Contact2."Phone No.");

        // [THEN] "Purchase Order"."Mobile Phone No." = "444444444"
        PurchaseOrder.BuyFromContactMobilePhoneNo.AssertEquals(Contact2."Mobile Phone No.");

        // [THEN] "Purchase Order"."Email" = "contact2@mail.com"
        PurchaseOrder.BuyFromContactEmail.AssertEquals(Contact2."E-Mail");

        // [THEN] Number of confirmation questions = 2
        Assert.AreEqual(2, LibraryVariableStorage.DequeueInteger(), 'Number of confirmations is incorrect');
    end;

    [Test]
    procedure S465057_WhenPromisedReceiptDateIsRemovedPlannedReceiptDateIsSetToRequestedReceiptDate()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase Order] [Planned Receipt Date] [Promised Receipt Date]
        // [SCENARIO 465057] When "Promised Receipt Date" is removed "Planned Receipt Date" is set to "Requested Receipt Date".
        Initialize();

        // [GIVEN] Create Purchase Order with Item in line.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), 1);

        // [WHEN] Set "Requested Receipt Date" in Purchase Order.
        PurchaseHeader.Validate("Requested Receipt Date", WorkDate() + 10);
        PurchaseHeader.Modify(true);

        // [THEN] Verify "Planned Receipt Date" in Purchase Line is equal to "Requested Receipt Date" in Purchase Header.
        PurchaseLine.GetBySystemId(PurchaseLine.SystemId);
        PurchaseLine.TestField("Requested Receipt Date", PurchaseHeader."Requested Receipt Date");
        PurchaseLine.TestField("Planned Receipt Date", PurchaseLine."Requested Receipt Date");

        // [WHEN] Set "Promised Receipt Date" in Purchase Order.
        PurchaseHeader.Validate("Promised Receipt Date", WorkDate() + 15);
        PurchaseHeader.Modify(true);

        // [THEN] Verify "Planned Receipt Date" in Purchase Line is equal to "Promised Receipt Date" in Purchase Header.
        PurchaseLine.GetBySystemId(PurchaseLine.SystemId);
        PurchaseLine.TestField("Promised Receipt Date", PurchaseHeader."Promised Receipt Date");
        PurchaseLine.TestField("Planned Receipt Date", PurchaseLine."Promised Receipt Date");

        // [WHEN] Remove "Promised Receipt Date" in Purchase Order.
        PurchaseHeader.Validate("Promised Receipt Date", 0D);
        PurchaseHeader.Modify(true);

        // [THEN] Verify "Planned Receipt Date" in Purchase Line is equal to "Requested Receipt Date" in Purchase Header.
        PurchaseLine.GetBySystemId(PurchaseLine.SystemId);
        PurchaseLine.TestField("Requested Receipt Date", PurchaseHeader."Requested Receipt Date");
        PurchaseLine.TestField("Planned Receipt Date", PurchaseLine."Requested Receipt Date");
    end;

    [Test]
    procedure PurchaseInvoiceCheckDocTotalAmountsVATAmountHigherThenDocAmountInclVAT()
    var
        PurchasePayablesSetup: Record "Purchases & Payables Setup";
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Check Doc. Total Amounts]
        // [SCENARIO] When on Purchase Invoice "VAT Amount" is higher than "Document Amount (Incl. VAT)" then error is shown
        Initialize();

        // [GIVEN] Enable "Check Doc. Total Amounts" in Purchases & Payables Setup
        PurchasePayablesSetup.Get();
        PurchasePayablesSetup."Check Doc. Total Amounts" := true;
        PurchasePayablesSetup.Modify(true);

        // [GIVEN] Create Purchase Invoice
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);

        // [WHEN] Doc. Amount Incl VAT is set
        PurchaseHeader.Validate("Doc. Amount Incl. VAT", LibraryRandom.RandDec(1000, 0));
        PurchaseHeader.Modify();

        // [THEN] Error is shown
        asserterror PurchaseHeader.Validate("Doc. Amount VAT", PurchaseHeader."Doc. Amount Incl. VAT" + LibraryRandom.RandDec(10, 0));
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseInvoiceStatisticsUpdateVATAmountModalPageHandler')]
    procedure PurchaseInvoiceCheckDocTotalAmountsVATInVATDifference()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoicePage: TestPage "Purchase Invoice";
        DirectUnitCost: Decimal;
        MaxAllowedVATDifference: Decimal;
    begin
        // [FEATURE] [Check Doc. Total Amounts]
        // [SCENARIO] When on Purchase Invoice "VAT Amount" is higher then sum of lines then error is shown
        Initialize();

        // [GIVEN] Allow VAT Difference
        MaxAllowedVATDifference := 1;
        LibraryERM.SetMaxVATDifferenceAllowed(MaxAllowedVATDifference);
        LibraryPurchase.SetAllowVATDifference(true);

        // [GIVEN] Create Purchase Invoice
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());

        // [GIVEN] Create Purchase Line
        DirectUnitCost := LibraryRandom.RandDecInRange(1, 100, 2);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), 1);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);

        // [GIVEN] VAT Amount Increased on Statistics page
        LibraryVariableStorage.Enqueue(MaxAllowedVATDifference / 3);
        PurchaseInvoicePage.OpenEdit();
        PurchaseInvoicePage.Filter.SetFilter("No.", PurchaseHeader."No.");
        PurchaseInvoicePage.Statistics.Invoke();
        PurchaseInvoicePage.Close();
        Commit();

        // [GIVEN] Set Doc. Amount Incl. VAT
        PurchaseHeader.CalcFields("Amount Including VAT", Amount);
        PurchaseHeader.Validate("Doc. Amount Incl. VAT", PurchaseHeader."Amount Including VAT");
        PurchaseHeader.Modify();

        // [WHEN] Set Doc Amount VAT
        PurchaseHeader.Validate("Doc. Amount VAT",
            (PurchaseHeader."Amount Including VAT" - PurchaseHeader.Amount)
            + MaxAllowedVATDifference / 3);

        // [THEN] Nothing is happen
        Assert.IsTrue(PurchaseHeader."Doc. Amount Incl. VAT" > PurchaseHeader."Doc. Amount VAT", 'Doc. Amount VAT is higher then Doc. Amount Incl. VAT');
    end;
#endif

    [Test]
    [HandlerFunctions('PurchaseInvoiceStatisticsUpdateVATAmountPageHandler')]
    procedure PurchaseInvoiceCheckDocTotalAmountsVATInVATDiff()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoicePage: TestPage "Purchase Invoice";
        DirectUnitCost: Decimal;
        MaxAllowedVATDifference: Decimal;
    begin
        // [FEATURE] [Check Doc. Total Amounts]
        // [SCENARIO] When on Purchase Invoice "VAT Amount" is higher then sum of lines then error is shown
        Initialize();

        // [GIVEN] Allow VAT Difference
        MaxAllowedVATDifference := 1;
        LibraryERM.SetMaxVATDifferenceAllowed(MaxAllowedVATDifference);
        LibraryPurchase.SetAllowVATDifference(true);

        // [GIVEN] Create Purchase Invoice
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());

        // [GIVEN] Create Purchase Line
        DirectUnitCost := LibraryRandom.RandDecInRange(1, 100, 2);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), 1);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);

        // [GIVEN] VAT Amount Increased on Statistics page
        LibraryVariableStorage.Enqueue(MaxAllowedVATDifference / 3);
        PurchaseInvoicePage.OpenEdit();
        PurchaseInvoicePage.Filter.SetFilter("No.", PurchaseHeader."No.");
        PurchaseInvoicePage.PurchaseStatistics.Invoke();
        PurchaseInvoicePage.Close();
        Commit();

        // [GIVEN] Set Doc. Amount Incl. VAT
        PurchaseHeader.CalcFields("Amount Including VAT", Amount);
        PurchaseHeader.Validate("Doc. Amount Incl. VAT", PurchaseHeader."Amount Including VAT");
        PurchaseHeader.Modify();

        // [WHEN] Set Doc Amount VAT
        PurchaseHeader.Validate("Doc. Amount VAT",
            (PurchaseHeader."Amount Including VAT" - PurchaseHeader.Amount)
            + MaxAllowedVATDifference / 3);

        // [THEN] Nothing is happen
        Assert.IsTrue(PurchaseHeader."Doc. Amount Incl. VAT" > PurchaseHeader."Doc. Amount VAT", 'Doc. Amount VAT is higher then Doc. Amount Incl. VAT');
    end;

    [Test]
    procedure PurchaseInvoiceCheckDocTotalAmountsVATAmountSmallerThenDocAmountInclVAT()
    var
        PurchasePayablesSetup: Record "Purchases & Payables Setup";
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Check Doc. Total Amounts]
        // [SCENARIO] When on Purchase Invoice "VAT Amount" is smaller than "Document Amount (Incl. VAT)" nothing happens
        Initialize();

        // [GIVEN] Enable "Check Doc. Total Amounts" in Purchases & Payables Setup
        PurchasePayablesSetup.Get();
        PurchasePayablesSetup."Check Doc. Total Amounts" := true;
        PurchasePayablesSetup.Modify(true);

        // [GIVEN] Create Purchase Invoice
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);

        // [WHEN] Doc. Amount Incl. VAT is set
        PurchaseHeader.Validate("Doc. Amount Incl. VAT", LibraryRandom.RandDec(1000, 0));
        PurchaseHeader.Modify();

        // [THEN] Nothing has happen
        Assert.IsTrue(PurchaseHeader."Doc. Amount Incl. VAT" > PurchaseHeader."Doc. Amount VAT", 'Doc. Amount VAT is higher then Doc. Amount Incl. VAT');
    end;

    [Test]
    procedure PurchaseInvoiceCheckDocTotalAmountsVATAmountHigherThenLines()
    var
        PurchasePayablesSetup: Record "Purchases & Payables Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DirectUnitCost: Decimal;
    begin
        // [FEATURE] [Check Doc. Total Amounts]
        // [SCENARIO] When on Purchase Invoice "VAT Amount" is higher then sum of lines then error is shown
        Initialize();

        // [GIVEN] Enable "Check Doc. Total Amounts" in Purchases & Payables Setup
        PurchasePayablesSetup.Get();
        PurchasePayablesSetup."Check Doc. Total Amounts" := true;
        PurchasePayablesSetup.Modify(true);

        // [GIVEN] Create Purchase Invoice
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());

        // [GIVEN] Create Purchase Line
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), 1);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);

        // [WHEN] Set Doc. Amount Incl. VAT
        DirectUnitCost := LibraryRandom.RandDecInRange(1, 100, 2);
        PurchaseHeader.Validate("Doc. Amount Incl. VAT", DirectUnitCost);
        PurchaseHeader.Modify();

        // [THEN] An error is thrown when validating Doc. Amount VAT with a higher amount then the lines
        asserterror PurchaseHeader.Validate("Doc. Amount VAT", DirectUnitCost + LibraryRandom.RandDec(10, 0));
    end;

    [Test]
    procedure PurchaseInvoiceCheckDocTotalAmountsLinesDifferenceDocAmountInclVATOnPosting()
    var
        PurchasePayablesSetup: Record "Purchases & Payables Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ErrorMessage: Record "Error Message";
        ErrorMessages: TestPage "Error Messages";
        DirectUnitCost: Decimal;
    begin
        // [FEATURE] [Check Doc. Total Amounts]
        // [SCENARIO] When on Purchase Invoice "Doc. Amount Incl. VAT" is higher then sum of lines then error is shown
        Initialize();

        // [GIVEN] Enable "Check Doc. Total Amounts" in Purchases & Payables Setup
        PurchasePayablesSetup.Get();
        PurchasePayablesSetup."Check Doc. Total Amounts" := true;
        PurchasePayablesSetup.Modify(true);

        // [GIVEN] Create Purchase Invoice
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());

        // [GIVEN] Set Doc. Amount Incl. VAT and VAT Amount
        DirectUnitCost := LibraryRandom.RandDecInRange(1, 100, 2);
        PurchaseHeader.Validate("Doc. Amount Incl. VAT", DirectUnitCost + LibraryRandom.RandDec(5, 0));
        PurchaseHeader.Validate("Doc. Amount VAT", DirectUnitCost - LibraryRandom.RandDec(1, 0));
        PurchaseHeader.Modify();

        // [GIVEN] Create Purchase Line
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), 1);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);

        // [WHEN] Posting purchase invoice
        ErrorMessages.Trap();
        PurchaseHeader.SendToPosting(CODEUNIT::"Purch.-Post");

        // [THEN] Exactly one error is thrown
        ErrorMessage.SetRange("Context Record ID", PurchaseHeader.RecordId);
        Assert.RecordCount(ErrorMessage, 1);
    end;

    [Test]
    procedure PurchaseInvoiceCheckDocTotalAmountsLinesDifferenceDocAmountVATOnPosting()
    var
        PurchasePayablesSetup: Record "Purchases & Payables Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ErrorMessage: Record "Error Message";
        ErrorMessages: TestPage "Error Messages";
        DirectUnitCost: Decimal;
    begin
        // [FEATURE] [Check Doc. Total Amounts]
        // [SCENARIO] When on Purchase Invoice "VAT Amount" is higher then sum of lines then error is shown
        Initialize();

        // [GIVEN] Enable "Check Doc. Total Amounts" in Purchases & Payables Setup
        PurchasePayablesSetup.Get();
        PurchasePayablesSetup."Check Doc. Total Amounts" := true;
        PurchasePayablesSetup.Modify(true);

        // [GIVEN] Create Purchase Invoice
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());

        // [GIVEN] Set Doc. Amount Incl. VAT and VAT Amount
        DirectUnitCost := LibraryRandom.RandDecInRange(1, 100, 2);
        PurchaseHeader.Validate("Doc. Amount Incl. VAT", DirectUnitCost);
        PurchaseHeader.Validate("Doc. Amount VAT", DirectUnitCost - LibraryRandom.RandDec(1, 0));
        PurchaseHeader.Modify();

        // [GIVEN] Create Purchase Line
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), 1);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);

        // [WHEN] Posting purchase invoice
        ErrorMessages.Trap();
        PurchaseHeader.SendToPosting(CODEUNIT::"Purch.-Post");

        // [THEN] Exactly one error is thrown  
        ErrorMessage.SetRange("Context Record ID", PurchaseHeader.RecordId);
        Assert.RecordCount(ErrorMessage, 1);
    end;

    [Test]
    procedure NoInconsistencyErrorDuringPurchasePostingWithCurrency()
    var
        GLAccount: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        VATPostingSetup: array[2] of Record "VAT Posting Setup";
        CurrencyCode: Code[10];
        PostedPurchaseInvoiceNo: Code[20];
    begin
        // [SCENARIO 581968] No inconsistency error during the posting of a Purchase Invoice with Currencies, Normal VAT and Non deductible VAT due to rounding.
        Initialize();

        // [GIVEN] Currency with exchange rates
        CurrencyCode := SetupCurrencyWithExchRates581968();

        // [GIVEN] Create two VAT Posting Setup with Non-Deductible VAT
        CreateNormalAndNonDeductiblePostingSetup(VATPostingSetup, 100, LibraryRandom.RandIntInRange(27, 27));

        // [GIVEN] Create GL Account for direct posting
        GLAccount.Get(LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup[2], GLAccount."Gen. Posting Type"::Purchase));

        // [GIVEN] Create Purchase Header and update currency code
        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
            LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup[1]."VAT Bus. Posting Group"));
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Modify();

        // [GIVEN] Create Purchase Lines with G/L Account Type and has Non-Deductible VAT
        LibraryPurchase.CreatePurchaseLine(PurchaseLine[1], PurchaseHeader, PurchaseLine[1].Type::"G/L Account", GLAccount."No.", 1);
        PurchaseLine[1].Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(3938, 3938));
        PurchaseLine[1].Modify();

        // [GIVEN] Create Purchase Line with normal VAT
        LibraryPurchase.CreatePurchaseLine(PurchaseLine[2], PurchaseHeader, PurchaseLine[2].Type::"G/L Account", GLAccount."No.", 1);
        PurchaseLine[2].Validate("VAT Prod. Posting Group", VATPostingSetup[1]."VAT Prod. Posting Group");
        PurchaseLine[2].Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(56657, 56657));
        PurchaseLine[2].Modify();

        // [GIVEN] Set "Doc. Amount Incl. VAT" and "Doc. Amount VAT" in Purchase Header
        PurchaseHeader.CalcFields("Amount Including VAT", Amount);
        PurchaseHeader.Validate("Doc. Amount Incl. VAT", PurchaseHeader."Amount Including VAT");
        PurchaseHeader.Validate("Doc. Amount VAT", PurchaseHeader."Amount Including VAT" - PurchaseHeader.Amount);
        PurchaseHeader.Modify();

        // [WHEN] Post Purchase Invoice and no error occurs
        PostedPurchaseInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Verify Posted Purchase Invoice is created without any inconsistency error
        Assert.IsTrue(PurchInvHeader.Get(PostedPurchaseInvoiceNo), StrSubstNo(PostedPurchaseInvoiceNotFoundLbl, PostedPurchaseInvoiceNo));
    end;

    [Test]
    [HandlerFunctions('PurchaseInvoicePageHandler')]
    procedure DocAmountTotalFieldVisibleOnPurchaseInvoiceWhenCreatedViaVendorListPage()
    var
        Vendor: Record Vendor;
        VendorList: TestPage "Vendor List";
    begin
        // [SCENARIO 598788] Document Amount Total field is visible on Purchase Invoice when created via Vendor List Page.
        Initialize();

        // [GIVEN] Enable "Check Doc. Total Amounts" in Purchases & Payables Setup.
        EnableDocumentTotalInPurchasePayablesSetup(true);

        // [GIVEN] Create a Vendor.
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Open the Vendor List.
        VendorList.OpenEdit();
        VendorList.GotoRecord(Vendor);

        // [WHEN] Purchase Invoice is created from Vendor List.
        VendorList.NewPurchaseInvoice.Invoke();

        // [THEN] Verify "Doc. Amount Total" & "Doc. Amount Incl. VAT" field is visible on the Purchase Invoice page.
        VendorList.Close();
    end;

    [Test]
    [HandlerFunctions('PurchaseInvoicePageHandler')]
    procedure DocAmountTotalFieldVisibleOnPurchaseInvoiceWhenCreatedViaVendorCardPage()
    var
        Vendor: Record Vendor;
        VendorCard: TestPage "Vendor Card";
    begin
        // [SCENARIO 598788] Document Amount Total field is visible on Purchase Invoice when created via Vendor Card Page.
        Initialize();

        // [GIVEN] Enable "Check Doc. Total Amounts" in Purchases & Payables Setup.
        EnableDocumentTotalInPurchasePayablesSetup(true);

        // [GIVEN] Create a Vendor.
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Open the Vendor Card.
        VendorCard.OpenEdit();
        VendorCard.GotoRecord(Vendor);

        // [WHEN] Purchase Invoice is created from Vendor Card.
        VendorCard.NewPurchaseInvoice.Invoke();

        // [THEN] Verify "Doc. Amount Total" & "Doc. Amount Incl. VAT" field is visible on the Purchase Invoice page.
        VendorCard.Close();
    end;

    local procedure Initialize()
    var
        ReportSelections: Record "Report Selections";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Purchase Documents");

        LibraryApplicationArea.DisableApplicationAreaSetup();
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Purchase Documents");

        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        ReportSelections.SetRange(Usage, LibraryERMCountryData.GetReportSelectionsUsagePurchaseQuote());
        ReportSelections.ModifyAll("Report ID", REPORT::"Purchase - Quote");

        IsInitialized := true;

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Purchase Documents");
    end;

    local procedure ClearMyNotification()
    var
        MyNotifications: Record "My Notifications";
    begin
        MyNotifications.DeleteAll();
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithPurchSetup(), LibraryRandom.RandInt(10));
    end;

    local procedure CreatePurchaseOrderWithLineTypeItem(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
          LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
    end;

    local procedure CreatePostPurchDocWithExternalDocNo(var ExternalDocumentNo: Code[35]; var VendorNo: Code[20]; DocumentType: Enum "Purchase Document Type"; var PurchaseHeader: Record "Purchase Header")
    begin
        ExternalDocumentNo := LibraryUtility.GenerateGUID();
        VendorNo := LibraryPurchase.CreateVendorNo();
        CreatePurchaseDocument(PurchaseHeader, DocumentType, VendorNo);
        case DocumentType of
            PurchaseHeader."Document Type"::Invoice,
            PurchaseHeader."Document Type"::Order:
                PurchaseHeader."Vendor Invoice No." := ExternalDocumentNo;
            PurchaseHeader."Document Type"::"Credit Memo",
            PurchaseHeader."Document Type"::"Return Order":
                PurchaseHeader."Vendor Cr. Memo No." := ExternalDocumentNo;
        end;
        PurchaseHeader.Modify();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreatePurchaseDocumentWithTwoLinesSecondLineQuantityZero(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
          LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
          LibraryInventory.CreateItemNo(), 0);
        PurchaseHeader.SetRecFilter();
    end;

    local procedure CreatePurchaseOrderWithItemAndChargeItem(var PurchaseHeaderOrder: Record "Purchase Header"; var PurchaseLineItem: Record "Purchase Line"; var PurchaseLineChargeItem: Record "Purchase Line"; QtyToAssign: Decimal)
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeaderOrder, PurchaseHeaderOrder."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLineItem, PurchaseHeaderOrder, PurchaseLineItem.Type::Item, LibraryInventory.CreateItemNo(), QtyToAssign + 1);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLineChargeItem, PurchaseHeaderOrder,
          PurchaseLineChargeItem.Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo(), QtyToAssign);
        PurchaseLineChargeItem.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));
        PurchaseLineChargeItem.Modify(true);

        LibraryVariableStorage.Enqueue(QtyToAssign);
        PurchaseLineChargeItem.ShowItemChargeAssgnt();
        PurchaseLineChargeItem.Modify(true);

        Commit();

        PurchaseLineChargeItem.Find();
        PurchaseLineChargeItem.CalcFields("Qty. to Assign");
        PurchaseLineChargeItem.TestField("Qty. to Assign", QtyToAssign);
    end;

    local procedure CreatePurchaseOrderWithChargeItemAndItem(var PurchaseHeaderOrder: Record "Purchase Header"; var PurchaseLineItem: Record "Purchase Line"; var PurchaseLineChargeItem: Record "Purchase Line"; QtyToAssign: Decimal)
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeaderOrder, PurchaseHeaderOrder."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLineChargeItem, PurchaseHeaderOrder,
          PurchaseLineChargeItem.Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo(), QtyToAssign);
        PurchaseLineChargeItem.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));
        PurchaseLineChargeItem.Modify(true);

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLineItem, PurchaseHeaderOrder, PurchaseLineItem.Type::Item, LibraryInventory.CreateItemNo(), QtyToAssign + 1);

        LibraryVariableStorage.Enqueue(QtyToAssign);
        PurchaseLineChargeItem.ShowItemChargeAssgnt();
        PurchaseLineChargeItem.Modify(true);

        Commit();

        PurchaseLineChargeItem.Find();
        PurchaseLineChargeItem.CalcFields("Qty. to Assign");
        PurchaseLineChargeItem.TestField("Qty. to Assign", QtyToAssign);
    end;

    local procedure GetLastVendorLedgerEntryNo(VendorNo: Code[20]): Integer
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        if VendorLedgerEntry.FindLast() then;
        exit(VendorLedgerEntry."Entry No.");
    end;

    local procedure GetReceiptLinesWithOrder(PurchaseHeaderOrder: Record "Purchase Header"; PurchaseHeaderInvoice: Record "Purchase Header"; ReversedOrder: Boolean)
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
    begin
        PurchRcptLine.Ascending(ReversedOrder);
        PurchRcptLine.SetCurrentKey("Document No.", "Line No.");
        PurchRcptLine.SetRange("Order No.", PurchaseHeaderOrder."No.");

        PurchGetReceipt.SetPurchHeader(PurchaseHeaderInvoice);
        PurchGetReceipt.CreateInvLines(PurchRcptLine);
    end;

    local procedure EnableShowExternalDocAlreadyExistNotification()
    var
        PurchaseHeader: Record "Purchase Header";
        MyNotifications: Record "My Notifications";
    begin
        if MyNotifications.Get(UserId, PurchaseHeader.GetShowExternalDocAlreadyExistNotificationId()) then
            MyNotifications.Delete();
        PurchaseHeader.SetShowExternalDocAlreadyExistNotificationDefaultState(true);
    end;

    local procedure UpdateNoSeriesOnPurchaseSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Return Order Nos." := LibraryERM.CreateNoSeriesCode();
        PurchasesPayablesSetup."Posted Return Shpt. Nos." := LibraryERM.CreateNoSeriesCode();
        PurchasesPayablesSetup.Modify();
    end;

    local procedure UndoReceipt(PurchaseHeaderOrder: Record "Purchase Header")
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        PurchRcptLine.SetRange("Order No.", PurchaseHeaderOrder."No.");

        LibraryPurchase.UndoPurchaseReceiptLine(PurchRcptLine);
    end;

    local procedure SetDocumentDefaultLineType(PurchaseLineType: Enum "Purchase Line Type")
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Document Default Line Type" := PurchaseLineType;
        PurchasesPayablesSetup.Modify();
    end;

    local procedure InitPurchaseLineType(var PurchaseLine: Record "Purchase Line")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        PurchaseLine."Document Type" := PurchaseHeader."Document Type";
        PurchaseLine."Document No." := PurchaseHeader."No.";
        PurchaseLine.Type := PurchaseLine.GetDefaultLineType();
    end;

    local procedure UpdateContactInfo(var Contact: Record Contact; PhoneNo: Text[30]; MobilePhoneNo: Text[30]; Email: Text[80])
    begin
        Contact.Validate("Phone No.", PhoneNo);
        Contact.Validate("Mobile Phone No.", MobilePhoneNo);
        Contact.Validate("E-Mail", Email);
        Contact.Modify(true);
    end;

    local procedure VerifyTransactionTypeWhenInsertPurchaseDocument(DocumentType: Enum "Purchase Document Type")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, DocumentType, '',
          '', LibraryRandom.RandDecInRange(10, 20, 2), '', LibraryRandom.RandDate(10));

        PurchaseHeader.Delete();

        PurchaseHeader."Transaction Type" := '';
        PurchaseHeader.Insert();

        PurchaseHeader.TestField("Transaction Type", '');
    end;

    local procedure VerifyNotificationData(ExternalDocumentNo: Code[35]; VendorLedgerEntryNo: Integer; DocumentType: Enum "Gen. Journal Document Type")
    begin
        Assert.AreEqual(VendorLedgerEntryNo, LibraryVariableStorage.DequeueInteger(), 'Unexpected vendor ledger entry no.');
        Assert.AreEqual(
          StrSubstNo(PurchaseAlreadyExistsTxt, DocumentType, ExternalDocumentNo),
          LibraryVariableStorage.DequeueText(),
          'Unexpected Notification message');
    end;

    local procedure VerifyQtyToAssignInDocumentLineForChargeItem(PurchaseHeader: Record "Purchase Header"; ChargeItemNo: Code[20]; ExpectedQtyToAssign: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("No.", ChargeItemNo);

        PurchaseLine.FindFirst();
        PurchaseLine.CalcFields("Qty. to Assign");
        PurchaseLine.TestField("Qty. to Assign", ExpectedQtyToAssign);
    end;

    local procedure VerifyPurchaseLineType(PurchaseLine: Record "Purchase Line"; PurchaseLineType: Enum "Purchase Line Type")
    begin
        PurchaseLine.TestField(Type, PurchaseLineType);
    end;

    local procedure CreateNormalAndNonDeductiblePostingSetup(var VATPostingSetup: array[2] of Record "VAT Posting Setup"; NonDeductibleVATPct: Decimal; VATRate: Decimal)
    var
        VATProdPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryNonDeductibleVAT.CreateNonDeductibleNormalVATPostingSetup(VATPostingSetup[1]);
        VATPostingSetup[1].Validate("VAT %", 0);
        VATPostingSetup[1].Validate("Non-Deductible VAT %", NonDeductibleVATPct);
        VATPostingSetup[1].Modify();

        LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup[2], VATPostingSetup[1]."VAT Bus. Posting Group", VATProdPostingGroup.Code);
        VATPostingSetup[2].Validate("VAT Calculation Type", VATPostingSetup[2]."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup[2].Validate("VAT %", VATRate);
        VATPostingSetup[2].Validate("Sales VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup[2].Validate("Purchase VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup[2].Validate("Tax Category", 'S');
        VATPostingSetup[2].Modify();
    end;

    local procedure SetupCurrencyWithExchRates581968(): Code[10]
    var
        Currency: Record Currency;
        CurrExchRateAmount: Decimal;
        AdjustmentExchrateAmount: Decimal;
    begin
        LibraryERM.CreateCurrency(Currency);
        Currency.Validate("Realized Gains Acc.", LibraryERM.CreateGLAccountNo());
        Currency.Validate("Realized Losses Acc.", LibraryERM.CreateGLAccountNo());
        Currency.Modify(true);
        CurrExchRateAmount := 412.39;
        AdjustmentExchrateAmount := 12.39;
        LibraryERM.CreateExchangeRate(Currency.Code, WorkDate(), CurrExchRateAmount, AdjustmentExchrateAmount);
        exit(Currency.Code);
    end;

    local procedure EnableDocumentTotalInPurchasePayablesSetup(Enable: Boolean)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Check Doc. Total Amounts", Enable);
        PurchasesPayablesSetup.Modify(true);
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure RecallNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendNotificationHandler(var Notification: Notification): Boolean
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryVariableStorage.Enqueue(Notification.GetData(VendorLedgerEntry.FieldName("Entry No.")));
        LibraryVariableStorage.Enqueue(Notification.Message);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Message: Text[1024]; var Response: Boolean)
    begin
        Response := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerCount(Question: Text[1024]; var Reply: Boolean)
    begin
        if LibraryVariableStorage.Length() > 1 then
            Reply := LibraryVariableStorage.DequeueBoolean()
        else
            Reply := false;
        LibraryVariableStorage.Enqueue(LibraryVariableStorage.DequeueInteger() + 1);
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure PostOrderStrMenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 0;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseQuoteRequestPageHandler(var PurchaseQuote: TestRequestPage "Purchase - Quote")
    begin
        PurchaseQuote.Cancel().Invoke();
        LibraryVariableStorage.Enqueue(REPORT::"Purchase - Quote");
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageCaptureHandler(Message: Text[1024])
    begin
        LibraryVariableStorage.Enqueue(Message);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemChargeAssignmentPurchModalPageHandler(var ItemChargeAssignmentPurch: TestPage "Item Charge Assignment (Purch)")
    begin
        ItemChargeAssignmentPurch."Qty. to Assign".SetValue(LibraryVariableStorage.DequeueDecimal());
        ItemChargeAssignmentPurch.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ContactListPageHandler(var ContactList: TestPage "Contact List")
    begin
        ContactList.GotoKey(LibraryVariableStorage.DequeueText());
        ContactList.OK().Invoke();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceStatisticsUpdateVATAmountModalPageHandler(var PurchaseStatistics: TestPage "Purchase Statistics")
    begin
        PurchaseStatistics.SubForm.Last();
        PurchaseStatistics.SubForm."VAT Amount".SetValue(
          PurchaseStatistics.SubForm."VAT Amount".AsDecimal() + LibraryVariableStorage.DequeueDecimal()); // increase VAT amount with the given value.
    end;
#endif

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceStatisticsUpdateVATAmountPageHandler(var PurchaseStatistics: TestPage "Purchase Statistics")
    begin
        PurchaseStatistics.SubForm.Last();
        PurchaseStatistics.SubForm."VAT Amount".SetValue(
          PurchaseStatistics.SubForm."VAT Amount".AsDecimal() + LibraryVariableStorage.DequeueDecimal()); // increase VAT amount with the given value.
    end;

    [PageHandler]
    procedure PurchaseInvoicePageHandler(var PurchaseInvoice: TestPage "Purchase Invoice")
    begin
        Assert.IsTrue(PurchaseInvoice.DocAmountVAT.Visible(), StrSubstNo(DocAmountFieldVisibleErr, PurchaseInvoice.DocAmountVAT.Caption()));
        Assert.IsTrue(PurchaseInvoice.DocAmount.Visible(), StrSubstNo(DocAmountFieldVisibleErr, PurchaseInvoice.DocAmount.Caption()));
    end;
}
