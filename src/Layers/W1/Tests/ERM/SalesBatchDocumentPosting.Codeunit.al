codeunit 134891 "Sales Batch Document Posting"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Sales] [UI]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        ReadyToPostInvoicesTemplateTok: Label 'The number of invoices that will be posted is %1. \Do you want to continue?';
        ReadyToPostTwoInvoicesQst: Label 'The number of invoices that will be posted is 2. \Do you want to continue?';
        LibraryRandom: Codeunit "Library - Random";
        BatchCompletedMsg: Label 'All of your selections were processed.';
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        IsInitialized: Boolean;
        DoYouWantToPostQst: Label 'Do you want to post the %1?';
        ConfirmZeroQuantityPostingMsg: Label 'One or more document lines with a value in the No. field do not have a quantity specified. \Do you want to continue?';

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostSelectedInvoice()
    var
        SalesHeader: array[3] of Record "Sales Header";
        SalesHeaderUI: Record "Sales Header";
        SalesInvoiceList: TestPage "Sales Invoice List";
    begin
        // [SCENARIO] Cassie can post selected invoice from Sales Invoice List page
        Initialize();

        // [GIVEN] Invoices "X", "Y" and "Z" for Customer "C" with Amount = 100 each
        // [GIVEN] Cassie selects invoice "Y" on Sales Invoice List page and calls "Post Selected" action
        // [WHEN] Cassie confirms she wants to post 1 out 3 invoices
        // [THEN] "Y" posted and system shows message 'Batch successfully completed.'
        // [THEN] Invoices "X" and "Z" remain unposted
        CreateThreeDocuments(
          SalesHeader, SalesHeaderUI, SalesHeader[1]."Document Type"::Invoice, LibraryRandom.RandIntInRange(10, 20));

        SalesInvoiceList.Trap();
        PAGE.Run(PAGE::"Sales Invoice List", SalesHeaderUI);

        LibraryVariableStorage.Enqueue(StrSubstNo(DoYouWantToPostQst, LowerCase(Format(SalesHeader[1]."Document Type"))));
        InvokePostSelectedInvoices(SalesInvoiceList, SalesHeader[2]);

        VerifyTwoOfThreeDocumentsUnposted(SalesHeaderUI, SalesHeader);

        VerifyInvoicePosted(SalesHeader[2]);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostSelectedCreditMemo()
    var
        SalesHeader: array[3] of Record "Sales Header";
        SalesHeaderUI: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCreditMemos: TestPage "Sales Credit Memos";
    begin
        // [SCENARIO] Cassie can post selected credit memo from Sales Credit Memos page
        Initialize();

        // [GIVEN] Credit Memos "X", "Y" and "Z" for Customer "C" with Amount = 100 each
        // [GIVEN] Cassie selects credit memo "Y" on Sales Credit Memos page and calls "Post Selected" action
        // [WHEN] Cassie confirms she wants to post 1 out 3 credit memos
        // [THEN] "Y" posted and system shows message 'Batch successfully completed.'
        // [THEN] Credit Memos "X" and "Z" remain unposted
        CreateThreeDocuments(
          SalesHeader, SalesHeaderUI, SalesHeader[1]."Document Type"::"Credit Memo", LibraryRandom.RandIntInRange(10, 20));

        SalesCreditMemos.Trap();
        PAGE.Run(PAGE::"Sales Credit Memos", SalesHeaderUI);

        LibraryVariableStorage.Enqueue(StrSubstNo(DoYouWantToPostQst, LowerCase(Format(SalesHeader[1]."Document Type"))));
        InvokePostSelectedCreditMemos(SalesCreditMemos, SalesHeader[2]);

        VerifyTwoOfThreeDocumentsUnposted(SalesHeaderUI, SalesHeader);

        SalesCrMemoHeader.SetRange("Sell-to Customer No.", SalesHeader[2]."Sell-to Customer No.");
        Assert.RecordCount(SalesCrMemoHeader, 1);
    end;

    [Test]
    [HandlerFunctions('PostStrMenuHandler')]
    [Scope('OnPrem')]
    procedure PostSelectedOrder()
    var
        SalesHeader: array[3] of Record "Sales Header";
        SalesHeaderUI: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesOrderList: TestPage "Sales Order List";
    begin
        // [SCENARIO] Cassie can post selected order from Sales Order List page
        Initialize();

        // [GIVEN] Orders "X", "Y" and "Z" for Customer "C" with Amount = 100 each
        // [GIVEN] Cassie selects order "Y" on Sales Order List page and calls "Post Selected" action
        // [WHEN] Cassie confirms she wants to post 1 out 3 orders
        // [THEN] "Y" posted and system shows message 'Batch successfully completed.'
        // [THEN] Orders "X" and "Z" remain unposted
        CreateThreeDocuments(
          SalesHeader, SalesHeaderUI, SalesHeader[1]."Document Type"::Order, LibraryRandom.RandIntInRange(10, 20));

        SalesOrderList.Trap();
        PAGE.Run(PAGE::"Sales Order List", SalesHeaderUI);

        LibraryVariableStorage.Enqueue(3); // Ship and Invoice menu choice
        InvokePostSelectedOrders(SalesOrderList, SalesHeader[2]);

        VerifyTwoOfThreeDocumentsUnposted(SalesHeaderUI, SalesHeader);

        SalesShipmentHeader.SetRange("Sell-to Customer No.", SalesHeader[2]."Sell-to Customer No.");
        Assert.RecordCount(SalesShipmentHeader, 1);
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", SalesHeader[2]."Sell-to Customer No.");
        Assert.RecordCount(SalesInvoiceHeader, 1);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostStrMenuHandler')]
    [Scope('OnPrem')]
    procedure PostSelectedReturnOrder()
    var
        SalesHeader: array[3] of Record "Sales Header";
        SalesHeaderUI: Record "Sales Header";
        ReturnReceiptHeader: Record "Return Receipt Header";
        SalesReturnOrderList: TestPage "Sales Return Order List";
    begin
        // [SCENARIO] Cassie can post selected return order from Sales Return Order List page
        Initialize();

        // [GIVEN] Return orders "X", "Y" and "Z" for Customer "C" with Amount = 100 each
        // [GIVEN] Cassie selects return order "Y" on Sales Return Order List page and calls "Post Selected" action
        // [WHEN] Cassie confirms she wants to post 1 out 3 return orders
        // [THEN] "Y" posted and system shows message 'Batch successfully completed.'
        // [THEN] Return orders "X" and "Z" remain unposted
        CreateThreeDocuments(
          SalesHeader, SalesHeaderUI, SalesHeader[1]."Document Type"::"Return Order", LibraryRandom.RandIntInRange(10, 20));

        SalesReturnOrderList.Trap();
        PAGE.Run(PAGE::"Sales Return Order List", SalesHeaderUI);

        LibraryVariableStorage.Enqueue(3); // Ship and Invoice menu choice
        InvokePostSelectedReturnOrders(SalesReturnOrderList, SalesHeader[2]);

        VerifyTwoOfThreeDocumentsUnposted(SalesHeaderUI, SalesHeader);

        ReturnReceiptHeader.SetRange("Sell-to Customer No.", SalesHeader[2]."Sell-to Customer No.");
        Assert.RecordCount(ReturnReceiptHeader, 1);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SimpleConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TwoOfThreeInvoicesPostedAsBatchWhileSecondFailed()
    var
        SalesHeader: array[3] of Record "Sales Header";
        SalesHeaderCreated: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesBatchPostMgt: Codeunit "Sales Batch Post Mgt.";
        ErrorMessages: TestPage "Error Messages";
        ErrorCount: Integer;
    begin
        // [SCENARIO] One of three invoices failed during batch posting does not stop other invoices to be posted.
        Initialize();
        LibrarySales.SetPostWithJobQueue(false);

        // [GIVEN] Invoices "X", "Y" and "Z" for Customer "C", with Amount = 0 each
        CreateThreeDocuments(
          SalesHeader, SalesHeaderCreated, SalesHeader[1]."Document Type"::Invoice, 1);
        // [GIVEN] Invoice 'Y' has "Quantity" = 0
        SalesLine.Get(SalesHeader[2]."Document Type", SalesHeader[2]."No.", 10000);
        SalesLine.Validate(Quantity, 0);
        SalesLine.Modify(true);

        // [WHEN] Post three invoices as a batch
        ErrorMessages.Trap();
        SalesBatchPostMgt.RunWithUI(SalesHeaderCreated, SalesHeaderCreated.Count, ReadyToPostInvoicesTemplateTok);

        // [THEN] Error message page for "Y" opened with one error line: 'There is nothing to post'
        repeat
            ErrorCount += 1;
            ErrorMessages.Description.AssertEquals(DocumentErrorsMgt.GetNothingToPostErrorMsg());
        until not ErrorMessages.Next();
        Assert.AreEqual(1, ErrorCount, 'Unexpected error count');

        // [THEN] 'X' and 'Z' are posted, 'Y' is not posted.
        Assert.IsFalse(SalesHeader[1].Find(), 'First invoice is not posted');
        Assert.IsTrue(SalesHeader[2].Find(), 'Second invoice is posted');
        Assert.IsFalse(SalesHeader[3].Find(), 'Third invoice is not posted');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ErrorMessagesPageSalesPostBatchMgtRunWithUIPostsFilteredOutRecords()
    var
        SalesHeader: array[3] of Record "Sales Header";
        SalesHeaderCreated: Record "Sales Header";
        SalesHeaderToPost: Record "Sales Header";
        SalesBatchPostMgt: Codeunit "Sales Batch Post Mgt.";
        ErrorMessages: TestPage "Error Messages";
        ErrorCount: Integer;
    begin
        // [SCENARIO] Cassie can't post selected invoices with 0 amounts and gets error message pages with wrong documents
        Initialize();
        LibrarySales.SetPostWithJobQueue(false);

        // [GIVEN] Invoices "X", "Y" and "Z" for Customer "C" with Amount = 0 each
        // [GIVEN] Cassie selects invoice "X" and "Z" invoices to post
        // [WHEN] Cassie confirms she wants to post 2 out 3 invoices
        // [THEN] "X", "Y" and "Z" are not posted and system shows message 'One or more of the documents could not be posted.'
        // [THEN] Error message page for "X" and "Y" opened
        CreateThreeDocuments(
          SalesHeader, SalesHeaderCreated, SalesHeader[1]."Document Type"::Invoice, 0);

        MarkDocumentsToPost(SalesHeaderToPost, SalesHeader, SalesHeaderCreated);

        LibraryVariableStorage.Enqueue(ReadyToPostTwoInvoicesQst);

        ErrorMessages.Trap();
        SalesBatchPostMgt.RunWithUI(SalesHeaderToPost, SalesHeaderCreated.Count, ReadyToPostInvoicesTemplateTok);

        repeat
            ErrorCount += 1;
            ErrorMessages.Description.AssertEquals(DocumentErrorsMgt.GetNothingToPostErrorMsg());
        until not ErrorMessages.Next();

        Assert.AreEqual(SalesHeaderToPost.Count, ErrorCount, 'Unexpected error count');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesPostBatchMgtRunWithUIPostsFilteredOutRecords()
    var
        SalesHeader: array[3] of Record "Sales Header";
        SalesHeaderCreated: Record "Sales Header";
        SalesHeaderToPost: Record "Sales Header";
        SalesBatchPostMgt: Codeunit "Sales Batch Post Mgt.";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        // [SCENARIO] Cassie can post selected only invoices in background
        Initialize();
        LibrarySales.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // [GIVEN] Invoices "X", "Y" and "Z" for Customer "C" with Amount = 100 each
        // [GIVEN] Cassie selects invoice "X" and "Y" invoices to post
        // [WHEN] Cassie confirms she wants to post 2 out 3 invoices
        // [THEN] "X" and "Y" posted and system shows message 'Batch successfully completed.'
        // [THEN] "Z" remains unposted
        CreateThreeDocuments(
          SalesHeader, SalesHeaderCreated, SalesHeader[1]."Document Type"::Invoice, LibraryRandom.RandIntInRange(10, 20));

        MarkDocumentsToPost(SalesHeaderToPost, SalesHeader, SalesHeaderCreated);

        LibraryVariableStorage.Enqueue(ReadyToPostTwoInvoicesQst);
        LibraryVariableStorage.Enqueue(BatchCompletedMsg);
        SalesBatchPostMgt.RunWithUI(SalesHeaderToPost, SalesHeaderCreated.Count, ReadyToPostInvoicesTemplateTok);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader[1].RecordId);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader[2].RecordId);

        VerifyInvoicePosted(SalesHeader[1]);
        VerifyInvoicePosted(SalesHeader[2]);
        VerifyInvoiceUnposted(SalesHeader[3]);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ErrorOnPostSelectedInvoice()
    var
        SalesHeader: array[3] of Record "Sales Header";
        SalesHeaderUI: Record "Sales Header";
        SalesInvoiceList: TestPage "Sales Invoice List";
        ErrorMessagesPage: TestPage "Error Messages";
    begin
        // [SCENARIO] Cassie can see posting errors after batch posting from Sales Invoice List page
        Initialize();

        // [GIVEN] Invoices "X", "Y" and "Z" for Customer "C" with Amount = 0 each
        // [GIVEN] Cassie selects invoice "Y" on Sales Invocie List page and call "Post Selected" action
        // [WHEN] Cassie confirms she wants to post 1 out 3 invoices
        // [THEN] System shows page "Error Messages" with the line 'There is nothing to post' for "Y"
        // [THEN] Invoices "X", "Y" and "Z" remain unposted
        CreateThreeDocuments(SalesHeader, SalesHeaderUI, SalesHeader[1]."Document Type"::Invoice, 0);

        SalesInvoiceList.Trap();
        PAGE.Run(PAGE::"Sales Invoice List", SalesHeaderUI);

        LibraryVariableStorage.Enqueue(ConfirmZeroQuantityPostingMsg);
        LibraryVariableStorage.Enqueue(StrSubstNo(DoYouWantToPostQst, LowerCase(Format(SalesHeader[1]."Document Type"))));
        ErrorMessagesPage.Trap();
        InvokePostSelectedInvoices(SalesInvoiceList, SalesHeader[2]);

        ErrorMessagesPage.Description.AssertEquals(DocumentErrorsMgt.GetNothingToPostErrorMsg());
        ErrorMessagesPage.Context.AssertEquals(Format(SalesHeader[2].RecordId));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ErrorOnPostSelectedCreditMemo()
    var
        SalesHeader: array[3] of Record "Sales Header";
        SalesHeaderUI: Record "Sales Header";
        SalesCreditMemos: TestPage "Sales Credit Memos";
        ErrorMessagesPage: TestPage "Error Messages";
    begin
        // [SCENARIO] Cassie can see posting errors after batch posting from Sales Credit Memos page
        Initialize();

        // [GIVEN] Credit Memos "X", "Y" and "Z" for Customer "C" with Amount = 0 each
        // [GIVEN] Cassie selects credit memo "Y" on Sales Credit Memos page and call "Post Selected" action
        // [WHEN] Cassie confirms she wants to post 1 out 3 credit memos
        // [THEN] System shows page "Error Messages" with the line 'There is nothing to post' for "Y"
        // [THEN] Credit memos "X", "Y" and "Z" remain unposted
        CreateThreeDocuments(SalesHeader, SalesHeaderUI, SalesHeader[1]."Document Type"::"Credit Memo", 0);

        SalesCreditMemos.Trap();
        PAGE.Run(PAGE::"Sales Credit Memos", SalesHeaderUI);

        LibraryVariableStorage.Enqueue(ConfirmZeroQuantityPostingMsg);
        LibraryVariableStorage.Enqueue(StrSubstNo(DoYouWantToPostQst, LowerCase(Format(SalesHeader[1]."Document Type"))));
        ErrorMessagesPage.Trap();
        InvokePostSelectedCreditMemos(SalesCreditMemos, SalesHeader[2]);

        ErrorMessagesPage.Description.AssertEquals(DocumentErrorsMgt.GetNothingToPostErrorMsg());
        ErrorMessagesPage.Context.AssertEquals(Format(SalesHeader[2].RecordId));
    end;

    [Test]
    [HandlerFunctions('PostStrMenuHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ErrorOnPostSelectedOrder()
    var
        SalesHeader: array[3] of Record "Sales Header";
        SalesHeaderUI: Record "Sales Header";
        SalesOrderList: TestPage "Sales Order List";
        ErrorMessagesPage: TestPage "Error Messages";
    begin
        // [SCENARIO] Cassie can see posting errors after batch posting from Sales Order List page
        Initialize();

        // [GIVEN] Orders "X", "Y" and "Z" for Customer "C" with Amount = 0 each
        // [GIVEN] Cassie selects order "Y" on Sales Order List page and call "Post Selected" action
        // [WHEN] Cassie confirms she wants to post 1 out 3 orders
        // [THEN] System shows page "Error Messages" with the line 'There is nothing to post' for "Y"
        // [THEN] Orders "X", "Y" and "Z" remain unposted
        CreateThreeDocuments(SalesHeader, SalesHeaderUI, SalesHeader[1]."Document Type"::Order, 0);

        SalesOrderList.Trap();
        PAGE.Run(PAGE::"Sales Order List", SalesHeaderUI);

        LibraryVariableStorage.Enqueue(ConfirmZeroQuantityPostingMsg);
        LibraryVariableStorage.Enqueue(3); // Ship and Invoice menu choice
        ErrorMessagesPage.Trap();
        InvokePostSelectedOrders(SalesOrderList, SalesHeader[2]);

        ErrorMessagesPage.Description.AssertEquals(DocumentErrorsMgt.GetNothingToPostErrorMsg());
        ErrorMessagesPage.Context.AssertEquals(Format(SalesHeader[2].RecordId));
    end;

    [Test]
    [HandlerFunctions('PostStrMenuHandler')]
    [Scope('OnPrem')]
    procedure ErrorOnPostSelectedReturnOrder()
    var
        SalesHeader: array[3] of Record "Sales Header";
        SalesHeaderUI: Record "Sales Header";
        SalesReturnOrderList: TestPage "Sales Return Order List";
        ErrorMessagesPage: TestPage "Error Messages";
    begin
        // [SCENARIO] Cassie can see posting errors after batch posting from Sales Return Order List page
        Initialize();

        // [GIVEN] Return Orders "X", "Y" and "Z" for Customer "C" with Amount = 0 each
        // [GIVEN] Cassie selects return order "Y" on Sales Return Order List page and call "Post Selected" action
        // [WHEN] Cassie confirms she wants to post 1 out 3 return orders
        // [THEN] System shows page "Error Messages" with the line 'There is nothing to post' for "Y"
        // [THEN] Return orders "X", "Y" and "Z" remain unposted
        CreateThreeDocuments(SalesHeader, SalesHeaderUI, SalesHeader[1]."Document Type"::"Return Order", 0);

        SalesReturnOrderList.Trap();
        PAGE.Run(PAGE::"Sales Return Order List", SalesHeaderUI);

        LibraryVariableStorage.Enqueue(3); // Ship and Invoice menu choice
        ErrorMessagesPage.Trap();
        InvokePostSelectedReturnOrders(SalesReturnOrderList, SalesHeader[2]);

        ErrorMessagesPage.Description.AssertEquals(DocumentErrorsMgt.GetNothingToPostErrorMsg());
        ErrorMessagesPage.Context.AssertEquals(Format(SalesHeader[2].RecordId));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleaseSelectedQuotes()
    var
        SalesHeader: array[3] of Record "Sales Header";
        SalesHeaderUI: Record "Sales Header";
        SalesQuotes: TestPage "Sales Quotes";
    begin
        // [SCENARIO] Cassie can release selected quote from Sales Quotes page
        Initialize();

        // [GIVEN] Quotes "X", "Y" and "Z" for Customer "C" with Amount = 100 each
        // [GIVEN] Cassie selects quote "Y" on Sales Quotes page and calls "Release" action
        // [WHEN] Cassie confirms she wants to release 1 out 3 quotes
        // [THEN] Quotes "X" and "Z" remain unreleased
        // [THEN] Quote "Y" is released
        CreateThreeDocuments(
          SalesHeader, SalesHeaderUI, SalesHeader[1]."Document Type"::Quote, LibraryRandom.RandIntInRange(10, 20));

        SalesQuotes.Trap();
        PAGE.Run(PAGE::"Sales Quotes", SalesHeaderUI);

        InvokeReleaseSelectedQuotes(SalesQuotes, SalesHeader[2]);

        VerifySaleDocumentStatus(SalesHeader[1], SalesHeader[1].Status::Open);
        VerifySaleDocumentStatus(SalesHeader[2], SalesHeader[2].Status::Released);
        VerifySaleDocumentStatus(SalesHeader[3], SalesHeader[3].Status::Open);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReopenSelectedQuotes()
    var
        SalesHeader: array[3] of Record "Sales Header";
        SalesHeaderUI: Record "Sales Header";
        SalesQuotes: TestPage "Sales Quotes";
    begin
        // [SCENARIO] Cassie can release selected uote from Sales Quotes page
        Initialize();

        // [GIVEN] Quotes "X", "Y" and "Z" for Customer "C" with Amount = 100 each
        // [GIVEN] Quotes "X", "Y" and "Z" for Customer "C" with are all released
        // [GIVEN] Cassie selects quote "Y" on Sales Quotes page and calls "Reopen" action
        // [WHEN] Cassie confirms she wants to reopen 1 out 3 quotes
        // [THEN] Quotes "X" and "Z" remain released
        // [THEN] Quote "Y" is reopened
        CreateThreeDocuments(
          SalesHeader, SalesHeaderUI, SalesHeader[1]."Document Type"::Quote, LibraryRandom.RandIntInRange(10, 20));

        SalesQuotes.Trap();
        PAGE.Run(PAGE::"Sales Quotes", SalesHeaderUI);

        InvokeReleaseSelectedQuotes(SalesQuotes, SalesHeader[1]);
        InvokeReleaseSelectedQuotes(SalesQuotes, SalesHeader[2]);
        InvokeReleaseSelectedQuotes(SalesQuotes, SalesHeader[3]);

        InvokeReopenSelectedQuotes(SalesQuotes, SalesHeader[2]);

        VerifySaleDocumentStatus(SalesHeader[1], SalesHeader[1].Status::Released);
        VerifySaleDocumentStatus(SalesHeader[2], SalesHeader[2].Status::Open);
        VerifySaleDocumentStatus(SalesHeader[3], SalesHeader[3].Status::Released);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleaseSelectedOrders()
    var
        SalesHeader: array[3] of Record "Sales Header";
        SalesHeaderUI: Record "Sales Header";
        SalesOrderList: TestPage "Sales Order List";
    begin
        // [SCENARIO] Cassie can release selected order from Sales Order List page
        Initialize();

        // [GIVEN] Orders "X", "Y" and "Z" for Customer "C" with Amount = 100 each
        // [GIVEN] Cassie selects order "Y" on Sales Order List page and calls "Release" action
        // [WHEN] Cassie confirms she wants to release 1 out 3 orders
        // [THEN] Orders "X" and "Z" remain unreleased
        // [THEN] Order "Y" is released
        CreateThreeDocuments(
          SalesHeader, SalesHeaderUI, SalesHeader[1]."Document Type"::Order, LibraryRandom.RandIntInRange(10, 20));

        SalesOrderList.Trap();
        PAGE.Run(PAGE::"Sales Order List", SalesHeaderUI);

        InvokeReleaseSelectedOrders(SalesOrderList, SalesHeader[2]);

        VerifySaleDocumentStatus(SalesHeader[1], SalesHeader[1].Status::Open);
        VerifySaleDocumentStatus(SalesHeader[2], SalesHeader[2].Status::Released);
        VerifySaleDocumentStatus(SalesHeader[3], SalesHeader[3].Status::Open);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReopenSelectedOrders()
    var
        SalesHeader: array[3] of Record "Sales Header";
        SalesHeaderUI: Record "Sales Header";
        SalesOrderList: TestPage "Sales Order List";
    begin
        // [SCENARIO] Cassie can release selected order from Sales Order List page
        Initialize();

        // [GIVEN] Orders "X", "Y" and "Z" for Customer "C" with Amount = 100 each
        // [GIVEN] Orders "X", "Y" and "Z" for Customer "C" with are all released
        // [GIVEN] Cassie selects order "Y" on Sales Order List page and calls "Reopen" action
        // [WHEN] Cassie confirms she wants to reopen 1 out 3 orders
        // [THEN] Orders "X" and "Z" remain released
        // [THEN] Order "Y" is reopened
        CreateThreeDocuments(
          SalesHeader, SalesHeaderUI, SalesHeader[1]."Document Type"::Order, LibraryRandom.RandIntInRange(10, 20));

        SalesOrderList.Trap();
        PAGE.Run(PAGE::"Sales Order List", SalesHeaderUI);

        InvokeReleaseSelectedOrders(SalesOrderList, SalesHeader[1]);
        InvokeReleaseSelectedOrders(SalesOrderList, SalesHeader[2]);
        InvokeReleaseSelectedOrders(SalesOrderList, SalesHeader[3]);

        InvokeReopenSelectedOrders(SalesOrderList, SalesHeader[2]);

        VerifySaleDocumentStatus(SalesHeader[1], SalesHeader[1].Status::Released);
        VerifySaleDocumentStatus(SalesHeader[2], SalesHeader[2].Status::Open);
        VerifySaleDocumentStatus(SalesHeader[3], SalesHeader[3].Status::Released);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleaseSelectedInvoices()
    var
        SalesHeader: array[3] of Record "Sales Header";
        SalesHeaderUI: Record "Sales Header";
        SalesInvoiceList: TestPage "Sales Invoice List";
    begin
        // [SCENARIO] Cassie can release selected invoice from Sales Invoice List page
        Initialize();

        // [GIVEN] Invoices "X", "Y" and "Z" for Customer "C" with Amount = 100 each
        // [GIVEN] Cassie selects invoice "Y" on Sales Order List page and calls "Release" action
        // [WHEN] Cassie confirms she wants to release 1 out 3 invoices
        // [THEN] Invoices "X" and "Z" remain unreleased
        // [THEN] Invoice "Y" is released
        CreateThreeDocuments(
          SalesHeader, SalesHeaderUI, SalesHeader[1]."Document Type"::Invoice, LibraryRandom.RandIntInRange(10, 20));

        SalesInvoiceList.Trap();
        PAGE.Run(PAGE::"Sales Invoice List", SalesHeaderUI);

        InvokeReleaseSelectedInvoices(SalesInvoiceList, SalesHeader[2]);

        VerifySaleDocumentStatus(SalesHeader[1], SalesHeader[1].Status::Open);
        VerifySaleDocumentStatus(SalesHeader[2], SalesHeader[2].Status::Released);
        VerifySaleDocumentStatus(SalesHeader[3], SalesHeader[3].Status::Open);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReopenSelectedInvoices()
    var
        SalesHeader: array[3] of Record "Sales Header";
        SalesHeaderUI: Record "Sales Header";
        SalesInvoiceList: TestPage "Sales Invoice List";
    begin
        // [SCENARIO] Cassie can release selected invoice from Sales Invoice List page
        Initialize();

        // [GIVEN] Invoices "X", "Y" and "Z" for Customer "C" with Amount = 100 each
        // [GIVEN] Invoices "X", "Y" and "Z" for Customer "C" with are all released
        // [GIVEN] Cassie selects invoice "Y" on Sales Invoice List page and calls "Reopen" action
        // [WHEN] Cassie confirms she wants to reopen 1 out 3 invoices
        // [THEN] Invoices "X" and "Z" remain released
        // [THEN] Invoice "Y" is reopened
        CreateThreeDocuments(
          SalesHeader, SalesHeaderUI, SalesHeader[1]."Document Type"::Invoice, LibraryRandom.RandIntInRange(10, 20));

        SalesInvoiceList.Trap();
        PAGE.Run(PAGE::"Sales Invoice List", SalesHeaderUI);

        InvokeReleaseSelectedInvoices(SalesInvoiceList, SalesHeader[1]);
        InvokeReleaseSelectedInvoices(SalesInvoiceList, SalesHeader[2]);
        InvokeReleaseSelectedInvoices(SalesInvoiceList, SalesHeader[3]);

        InvokeReopenSelectedInvoices(SalesInvoiceList, SalesHeader[2]);

        VerifySaleDocumentStatus(SalesHeader[1], SalesHeader[1].Status::Released);
        VerifySaleDocumentStatus(SalesHeader[2], SalesHeader[2].Status::Open);
        VerifySaleDocumentStatus(SalesHeader[3], SalesHeader[3].Status::Released);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleaseSelectedCreditMemos()
    var
        SalesHeader: array[3] of Record "Sales Header";
        SalesHeaderUI: Record "Sales Header";
        SalesCreditMemos: TestPage "Sales Credit Memos";
    begin
        // [SCENARIO] Cassie can release selected credit memo from Sales Credit Memos page
        Initialize();

        // [GIVEN] Credit Memos "X", "Y" and "Z" for Customer "C" with Amount = 100 each
        // [GIVEN] Cassie selects credit memo "Y" on Sales Credit Memos page and calls "Release" action
        // [WHEN] Cassie confirms she wants to release 1 out 3 credit memos
        // [THEN] Credit Memos "X" and "Z" remain unreleased
        // [THEN] Credit Memo "Y" is released
        CreateThreeDocuments(
          SalesHeader, SalesHeaderUI, SalesHeader[1]."Document Type"::"Credit Memo", LibraryRandom.RandIntInRange(10, 20));

        SalesCreditMemos.Trap();
        PAGE.Run(PAGE::"Sales Credit Memos", SalesHeaderUI);

        InvokeReleaseSelectedCreditMemos(SalesCreditMemos, SalesHeader[2]);

        VerifySaleDocumentStatus(SalesHeader[1], SalesHeader[1].Status::Open);
        VerifySaleDocumentStatus(SalesHeader[2], SalesHeader[2].Status::Released);
        VerifySaleDocumentStatus(SalesHeader[3], SalesHeader[3].Status::Open);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReopenSelectedCreditMemos()
    var
        SalesHeader: array[3] of Record "Sales Header";
        SalesHeaderUI: Record "Sales Header";
        SalesCreditMemos: TestPage "Sales Credit Memos";
    begin
        // [SCENARIO] Cassie can release selected credit memo from Sales Credit Memos page
        Initialize();

        // [GIVEN] Credit Memos "X", "Y" and "Z" for Customer "C" with Amount = 100 each
        // [GIVEN] Credit Memos "X", "Y" and "Z" for Customer "C" with are all released
        // [GIVEN] Cassie selects order "Y" on Credit Memos page and calls "Reopen" action
        // [WHEN] Cassie confirms she wants to reopen 1 out 3 credit memos
        // [THEN] Credit Memos "X" and "Z" remain released
        // [THEN] Credit Memo "Y" is reopened
        CreateThreeDocuments(
          SalesHeader, SalesHeaderUI, SalesHeader[1]."Document Type"::"Credit Memo", LibraryRandom.RandIntInRange(10, 20));

        SalesCreditMemos.Trap();
        PAGE.Run(PAGE::"Sales Credit Memos", SalesHeaderUI);

        InvokeReleaseSelectedCreditMemos(SalesCreditMemos, SalesHeader[1]);
        InvokeReleaseSelectedCreditMemos(SalesCreditMemos, SalesHeader[2]);
        InvokeReleaseSelectedCreditMemos(SalesCreditMemos, SalesHeader[3]);

        InvokeReopenSelectedCreditMemos(SalesCreditMemos, SalesHeader[2]);

        VerifySaleDocumentStatus(SalesHeader[1], SalesHeader[1].Status::Released);
        VerifySaleDocumentStatus(SalesHeader[2], SalesHeader[2].Status::Open);
        VerifySaleDocumentStatus(SalesHeader[3], SalesHeader[3].Status::Released);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleaseSelectedReturnOrders()
    var
        SalesHeader: array[3] of Record "Sales Header";
        SalesHeaderUI: Record "Sales Header";
        SalesReturnOrderList: TestPage "Sales Return Order List";
    begin
        // [SCENARIO] Cassie can release selected return order from Sales Return Order List page
        Initialize();

        // [GIVEN] Return Orders "X", "Y" and "Z" for Customer "C" with Amount = 100 each
        // [GIVEN] Cassie selects return order "Y" on Sales Return Order List page and calls "Release" action
        // [WHEN] Cassie confirms she wants to release 1 out 3 return orders
        // [THEN] Return Orders "X" and "Z" remain unreleased
        // [THEN] Return Order "Y" is released
        CreateThreeDocuments(
          SalesHeader, SalesHeaderUI, SalesHeader[1]."Document Type"::"Return Order", LibraryRandom.RandIntInRange(10, 20));

        SalesReturnOrderList.Trap();
        PAGE.Run(PAGE::"Sales Return Order List", SalesHeaderUI);

        InvokeReleaseSelectedReturnOrders(SalesReturnOrderList, SalesHeader[2]);

        VerifySaleDocumentStatus(SalesHeader[1], SalesHeader[1].Status::Open);
        VerifySaleDocumentStatus(SalesHeader[2], SalesHeader[2].Status::Released);
        VerifySaleDocumentStatus(SalesHeader[3], SalesHeader[3].Status::Open);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReopenSelectedReturnOrders()
    var
        SalesHeader: array[3] of Record "Sales Header";
        SalesHeaderUI: Record "Sales Header";
        SalesReturnOrderList: TestPage "Sales Return Order List";
    begin
        // [SCENARIO] Cassie can release selected return order from Sales Return Order List page
        Initialize();

        // [GIVEN] Return Orders "X", "Y" and "Z" for Customer "C" with Amount = 100 each
        // [GIVEN] Return Orders "X", "Y" and "Z" for Customer "C" with are all released
        // [GIVEN] Cassie selects order "Y" on Sales Return Order List page and calls "Reopen" action
        // [WHEN] Cassie confirms she wants to reopen 1 out 3 return orders
        // [THEN] Return Orders "X" and "Z" remain released
        // [THEN] Return Order "Y" is reopened
        CreateThreeDocuments(
          SalesHeader, SalesHeaderUI, SalesHeader[1]."Document Type"::"Return Order", LibraryRandom.RandIntInRange(10, 20));

        SalesReturnOrderList.Trap();
        PAGE.Run(PAGE::"Sales Return Order List", SalesHeaderUI);

        InvokeReleaseSelectedReturnOrders(SalesReturnOrderList, SalesHeader[1]);
        InvokeReleaseSelectedReturnOrders(SalesReturnOrderList, SalesHeader[2]);
        InvokeReleaseSelectedReturnOrders(SalesReturnOrderList, SalesHeader[3]);

        InvokeReopenSelectedReturnOrders(SalesReturnOrderList, SalesHeader[2]);

        VerifySaleDocumentStatus(SalesHeader[1], SalesHeader[1].Status::Released);
        VerifySaleDocumentStatus(SalesHeader[2], SalesHeader[2].Status::Open);
        VerifySaleDocumentStatus(SalesHeader[3], SalesHeader[3].Status::Released);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleaseSelectedBlanketOrders()
    var
        SalesHeader: array[3] of Record "Sales Header";
        SalesHeaderUI: Record "Sales Header";
        BlanketSalesOrders: TestPage "Blanket Sales Orders";
    begin
        // [SCENARIO] Cassie can release selected blanket order from Blanket Sales Orders page
        Initialize();

        // [GIVEN] Blanket Orders "X", "Y" and "Z" for Customer "C" with Amount = 100 each
        // [GIVEN] Cassie selects blanket order "Y" on Blanket Sales Orders page and calls "Release" action
        // [WHEN] Cassie confirms she wants to release 1 out 3 blanket orders
        // [THEN] Blanket Orders "X" and "Z" remain unreleased
        // [THEN] Blanket Order "Y" is released
        CreateThreeDocuments(
          SalesHeader, SalesHeaderUI, SalesHeader[1]."Document Type"::"Blanket Order", LibraryRandom.RandIntInRange(10, 20));

        BlanketSalesOrders.Trap();
        PAGE.Run(PAGE::"Blanket Sales Orders", SalesHeaderUI);

        InvokeReleaseSelectedBlanketOrders(BlanketSalesOrders, SalesHeader[2]);

        VerifySaleDocumentStatus(SalesHeader[1], SalesHeader[1].Status::Open);
        VerifySaleDocumentStatus(SalesHeader[2], SalesHeader[2].Status::Released);
        VerifySaleDocumentStatus(SalesHeader[3], SalesHeader[3].Status::Open);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReopenSelectedBlanketOrders()
    var
        SalesHeader: array[3] of Record "Sales Header";
        SalesHeaderUI: Record "Sales Header";
        BlanketSalesOrders: TestPage "Blanket Sales Orders";
    begin
        // [SCENARIO] Cassie can release selected blanket order from Blanket Sales Orders page
        Initialize();

        // [GIVEN] Blanket Orders "X", "Y" and "Z" for Customer "C" with Amount = 100 each
        // [GIVEN] Blanket Orders "X", "Y" and "Z" for Customer "C" with are all released
        // [GIVEN] Cassie selects blanket order "Y" on Blanket Sales Orders page and calls "Reopen" action
        // [WHEN] Cassie confirms she wants to reopen 1 out 3 blanket  orders
        // [THEN] Blanket Orders "X" and "Z" remain released
        // [THEN] Blanket Order "Y" is reopened
        CreateThreeDocuments(
          SalesHeader, SalesHeaderUI, SalesHeader[1]."Document Type"::"Blanket Order", LibraryRandom.RandIntInRange(10, 20));

        BlanketSalesOrders.Trap();
        PAGE.Run(PAGE::"Blanket Sales Orders", SalesHeaderUI);

        InvokeReleaseSelectedBlanketOrders(BlanketSalesOrders, SalesHeader[1]);
        InvokeReleaseSelectedBlanketOrders(BlanketSalesOrders, SalesHeader[2]);
        InvokeReleaseSelectedBlanketOrders(BlanketSalesOrders, SalesHeader[3]);

        InvokeReopenSelectedBlanketOrders(BlanketSalesOrders, SalesHeader[2]);

        VerifySaleDocumentStatus(SalesHeader[1], SalesHeader[1].Status::Released);
        VerifySaleDocumentStatus(SalesHeader[2], SalesHeader[2].Status::Open);
        VerifySaleDocumentStatus(SalesHeader[3], SalesHeader[3].Status::Released);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Sales Batch Document Posting");
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Sales Batch Document Posting");

        LibrarySales.SetReturnOrderNoSeriesInSetup();
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibraryApplicationArea.DisableApplicationAreaSetup();

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Sales Batch Document Posting");
    end;

    local procedure CreateThreeDocuments(var SalesHeader: array[3] of Record "Sales Header"; var SalesHeaderUI: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
        Index: Integer;
    begin
        for Index := 1 to ArrayLen(SalesHeader) do begin
            LibrarySales.CreateSalesDocumentWithItem(
              SalesHeader[Index], SalesLine, DocumentType, LibrarySales.CreateCustomerNo(), '', Quantity, '', 0D);
            SalesHeader[Index].CalcFields("Amount Including VAT");
        end;

        SalesHeaderUI.SetFilter("No.", '%1|%2|%3', SalesHeader[1]."No.", SalesHeader[2]."No.", SalesHeader[3]."No.");
        SalesHeaderUI.SetRange("Document Type", DocumentType);
    end;

    local procedure InvokePostSelectedInvoices(var SalesInvoiceList: TestPage "Sales Invoice List"; SalesHeaderToPost: Record "Sales Header")
    begin
        SalesInvoiceList.GotoRecord(SalesHeaderToPost);
        SalesInvoiceList.Post.Invoke();
    end;

    local procedure InvokePostSelectedCreditMemos(var SalesCreditMemos: TestPage "Sales Credit Memos"; SalesHeaderToPost: Record "Sales Header")
    begin
        SalesCreditMemos.GotoRecord(SalesHeaderToPost);
        SalesCreditMemos.Post.Invoke();
    end;

    local procedure InvokePostSelectedOrders(var SalesOrderList: TestPage "Sales Order List"; SalesHeaderToPost: Record "Sales Header")
    begin
        SalesOrderList.GotoRecord(SalesHeaderToPost);
        SalesOrderList.Post.Invoke();
    end;

    local procedure InvokeReleaseSelectedQuotes(var SalesQuotes: TestPage "Sales Quotes"; SalesHeaderToRelease: Record "Sales Header")
    begin
        SalesQuotes.GotoRecord(SalesHeaderToRelease);
        SalesQuotes.Release.Invoke();
    end;

    local procedure InvokeReopenSelectedQuotes(var SalesQuotes: TestPage "Sales Quotes"; SalesHeaderToReopen: Record "Sales Header")
    begin
        SalesQuotes.GotoRecord(SalesHeaderToReopen);
        SalesQuotes.Reopen.Invoke();
    end;

    local procedure InvokeReleaseSelectedOrders(var SalesOrderList: TestPage "Sales Order List"; SalesHeaderToRelease: Record "Sales Header")
    begin
        SalesOrderList.GotoRecord(SalesHeaderToRelease);
        SalesOrderList.Release.Invoke();
    end;

    local procedure InvokeReopenSelectedOrders(var SalesOrderList: TestPage "Sales Order List"; SalesHeaderToReopen: Record "Sales Header")
    begin
        SalesOrderList.GotoRecord(SalesHeaderToReopen);
        SalesOrderList.Reopen.Invoke();
    end;

    local procedure InvokeReleaseSelectedInvoices(var SalesInvoiceList: TestPage "Sales Invoice List"; SalesHeaderToRelease: Record "Sales Header")
    begin
        SalesInvoiceList.GotoRecord(SalesHeaderToRelease);
        SalesInvoiceList."Re&lease".Invoke();
    end;

    local procedure InvokeReopenSelectedInvoices(var SalesInvoiceList: TestPage "Sales Invoice List"; SalesHeaderToReopen: Record "Sales Header")
    begin
        SalesInvoiceList.GotoRecord(SalesHeaderToReopen);
        SalesInvoiceList."Re&open".Invoke();
    end;

    local procedure InvokeReleaseSelectedCreditMemos(var SalesCreditMemos: TestPage "Sales Credit Memos"; SalesHeaderToRelease: Record "Sales Header")
    begin
        SalesCreditMemos.GotoRecord(SalesHeaderToRelease);
        SalesCreditMemos."Re&lease".Invoke();
    end;

    local procedure InvokeReopenSelectedCreditMemos(var SalesCreditMemos: TestPage "Sales Credit Memos"; SalesHeaderToReopen: Record "Sales Header")
    begin
        SalesCreditMemos.GotoRecord(SalesHeaderToReopen);
        SalesCreditMemos."Re&open".Invoke();
    end;

    local procedure InvokePostSelectedReturnOrders(var SalesReturnOrderList: TestPage "Sales Return Order List"; SalesHeaderToPost: Record "Sales Header")
    begin
        SalesReturnOrderList.GotoRecord(SalesHeaderToPost);
        SalesReturnOrderList.Post.Invoke();
    end;

    local procedure InvokeReleaseSelectedReturnOrders(var SalesReturnOrderList: TestPage "Sales Return Order List"; SalesHeaderToRelease: Record "Sales Header")
    begin
        SalesReturnOrderList.GotoRecord(SalesHeaderToRelease);
        SalesReturnOrderList.Release.Invoke();
    end;

    local procedure InvokeReopenSelectedReturnOrders(var SalesReturnOrderList: TestPage "Sales Return Order List"; SalesHeaderToReopen: Record "Sales Header")
    begin
        SalesReturnOrderList.GotoRecord(SalesHeaderToReopen);
        SalesReturnOrderList.Reopen.Invoke();
    end;

    local procedure InvokeReleaseSelectedBlanketOrders(var BlanketSalesOrders: TestPage "Blanket Sales Orders"; SalesHeaderToRelease: Record "Sales Header")
    begin
        BlanketSalesOrders.GotoRecord(SalesHeaderToRelease);
        BlanketSalesOrders."Re&lease".Invoke();
    end;

    local procedure InvokeReopenSelectedBlanketOrders(var BlanketSalesOrders: TestPage "Blanket Sales Orders"; SalesHeaderToReopen: Record "Sales Header")
    begin
        BlanketSalesOrders.GotoRecord(SalesHeaderToReopen);
        BlanketSalesOrders."Re&open".Invoke();
    end;

    local procedure MarkDocumentsToPost(var SalesHeaderToPost: Record "Sales Header"; var SalesHeader: array[3] of Record "Sales Header"; var SalesHeaderCreated: Record "Sales Header")
    begin
        SalesHeaderToPost.CopyFilters(SalesHeaderCreated);
        SalesHeaderToPost.Get(SalesHeader[1]."Document Type", SalesHeader[1]."No.");
        SalesHeaderToPost.Mark(true);
        SalesHeaderToPost.Get(SalesHeader[2]."Document Type", SalesHeader[2]."No.");
        SalesHeaderToPost.Mark(true);
        // to be sure the only filtered documents are posted
        SalesHeaderToPost.Get(SalesHeader[3]."Document Type", SalesHeader[3]."No.");
        SalesHeaderToPost.MarkedOnly(true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Question);
        Reply := true; // precal forces to set any value to VAR parameter
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure SimpleConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(MessageText: Text[1024])
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), MessageText);
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure PostStrMenuHandler(Options: Text[1024]; var Choice: Integer; Instructions: Text[1024])
    begin
        Choice := LibraryVariableStorage.DequeueInteger();
    end;

    local procedure VerifyTwoOfThreeDocumentsUnposted(var SalesHeaderUI: Record "Sales Header"; var SalesHeader: array[3] of Record "Sales Header")
    begin
        Assert.RecordCount(SalesHeaderUI, ArrayLen(SalesHeader) - 1);
        SalesHeaderUI.FindFirst();
        SalesHeaderUI.TestField("No.", SalesHeader[1]."No.");
        SalesHeaderUI.Next();
        SalesHeaderUI.TestField("No.", SalesHeader[3]."No.");
    end;

    local procedure VerifyInvoicePosted(var SalesHeader: Record "Sales Header")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        Assert.RecordCount(SalesInvoiceHeader, 1);
        Assert.IsFalse(SalesHeader.Find(), '');
    end;

    local procedure VerifyInvoiceUnposted(var SalesHeader: Record "Sales Header")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        Assert.RecordCount(SalesInvoiceHeader, 0);
        Assert.IsTrue(SalesHeader.Find(), '');
    end;

    local procedure VerifySaleDocumentStatus(var SalesHeader: Record "Sales Header"; ExpectedStatus: Enum "Sales Document Status")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        Assert.RecordCount(SalesInvoiceHeader, 0);
        SalesHeader.Find();
        SalesHeader.TestField(Status, ExpectedStatus);
    end;
}

