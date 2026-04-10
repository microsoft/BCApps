codeunit 134892 "Purch. Batch Document Posting"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Purchase]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryPurchase: Codeunit "Library - Purchase";
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
        PurchaseHeader: array[3] of Record "Purchase Header";
        PurchaseHeaderUI: Record "Purchase Header";
        PurchaseInvoices: TestPage "Purchase Invoices";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] Cassie can post selected invoice from Purchase Invoices page
        Initialize();

        // [GIVEN] Invoices "X", "Y" and "Z" for with Amount = 100 each
        // [GIVEN] Cassie selects invoice "Y" on Purchase Invoices page and calls "Post Selected" action
        // [WHEN] Cassie confirms she wants to post 1 out 3 invoices
        // [THEN] "Y" posted and system shows message 'Batch successfully completed.'
        // [THEN] Invoices "X" and "Z" remain unposted
        CreateThreeDocuments(
          PurchaseHeader, PurchaseHeaderUI, PurchaseHeader[1]."Document Type"::Invoice, LibraryRandom.RandIntInRange(10, 20));

        PurchaseInvoices.Trap();
        PAGE.Run(PAGE::"Purchase Invoices", PurchaseHeaderUI);

        LibraryVariableStorage.Enqueue(
          StrSubstNo(DoYouWantToPostQst, LowerCase(Format(PurchaseHeader[1]."Document Type"))));
        InvokePostSelectedInvoices(PurchaseInvoices, PurchaseHeader[2]);

        VerifyTwoOfThreeDocumentsUnposted(PurchaseHeaderUI, PurchaseHeader);

        VerifyInvoicePosted(PurchaseHeader[2]);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostSelectedCreditMemo()
    var
        PurchaseHeader: array[3] of Record "Purchase Header";
        PurchaseHeaderUI: Record "Purchase Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchaseCreditMemos: TestPage "Purchase Credit Memos";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] Cassie can post selected credit memo from Purchase Credit Memos page
        Initialize();

        // [GIVEN] Credit Memos "X", "Y" and "Z" for with Amount = 100 each
        // [GIVEN] Cassie selects credit memo "Y" on Purchase Credit Memos page and calls "Post Selected" action
        // [WHEN] Cassie confirms she wants to post 1 out 3 credit memos
        // [THEN] "Y" posted and system shows message 'Batch successfully completed.'
        // [THEN] Credit Memos "X" and "Z" remain unposted
        CreateThreeDocuments(
          PurchaseHeader, PurchaseHeaderUI, PurchaseHeader[1]."Document Type"::"Credit Memo", LibraryRandom.RandIntInRange(10, 20));

        PurchaseCreditMemos.Trap();
        PAGE.Run(PAGE::"Purchase Credit Memos", PurchaseHeaderUI);

        LibraryVariableStorage.Enqueue(
          StrSubstNo(DoYouWantToPostQst, LowerCase(Format(PurchaseHeader[1]."Document Type"))));
        InvokePostSelectedCreditMemos(PurchaseCreditMemos, PurchaseHeader[2]);

        VerifyTwoOfThreeDocumentsUnposted(PurchaseHeaderUI, PurchaseHeader);

        PurchCrMemoHdr.SetRange("Buy-from Vendor No.", PurchaseHeader[2]."Buy-from Vendor No.");
        Assert.RecordCount(PurchCrMemoHdr, 1);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostStrMenuHandler')]
    [Scope('OnPrem')]
    procedure PostSelectedOrder()
    var
        PurchaseHeader: array[3] of Record "Purchase Header";
        PurchaseHeaderUI: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchaseOrderList: TestPage "Purchase Order List";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] Cassie can post selected order from Purchase Order List page
        Initialize();

        // [GIVEN] Orders "X", "Y" and "Z" for with Amount = 100 each
        // [GIVEN] Cassie selects order "Y" on Purchase Order List page and calls "Post Selected" action
        // [WHEN] Cassie confirms she wants to post 1 out 3 orders
        // [THEN] "Y" posted and system shows message 'Batch successfully completed.'
        // [THEN] Orders "X" and "Z" remain unposted
        CreateThreeDocuments(
          PurchaseHeader, PurchaseHeaderUI, PurchaseHeader[1]."Document Type"::Order, LibraryRandom.RandIntInRange(10, 20));

        PurchaseOrderList.Trap();
        PAGE.Run(PAGE::"Purchase Order List", PurchaseHeaderUI);

        LibraryVariableStorage.Enqueue(3); // Receive and Invoice menu choice
        InvokePostSelectedOrders(PurchaseOrderList, PurchaseHeader[2]);

        VerifyTwoOfThreeDocumentsUnposted(PurchaseHeaderUI, PurchaseHeader);

        PurchInvHeader.SetRange("Buy-from Vendor No.", PurchaseHeader[2]."Buy-from Vendor No.");
        Assert.RecordCount(PurchInvHeader, 1);
        PurchRcptHeader.SetRange("Buy-from Vendor No.", PurchaseHeader[2]."Buy-from Vendor No.");
        Assert.RecordCount(PurchRcptHeader, 1);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostStrMenuHandler')]
    [Scope('OnPrem')]
    procedure PostSelectedReturnOrder()
    var
        PurchaseHeader: array[3] of Record "Purchase Header";
        PurchaseHeaderUI: Record "Purchase Header";
        ReturnShipmentHeader: Record "Return Shipment Header";
        PurchaseReturnOrderList: TestPage "Purchase Return Order List";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] Cassie can post selected return order from Purchase Reutrn Order List page
        Initialize();

        // [GIVEN] Return orders "X", "Y" and "Z" with Amount = 100 each
        // [GIVEN] Cassie selects return order "Y" on Purchase Return Order List page and calls "Post Selected" action
        // [WHEN] Cassie confirms she wants to post 1 out 3 return orders
        // [THEN] "Y" posted and system shows message 'Batch successfully completed.'
        // [THEN] Return orders "X" and "Z" remain unposted
        CreateThreeDocuments(
          PurchaseHeader, PurchaseHeaderUI, PurchaseHeader[1]."Document Type"::"Return Order", LibraryRandom.RandIntInRange(10, 20));

        PurchaseReturnOrderList.Trap();
        PAGE.Run(PAGE::"Purchase Return Order List", PurchaseHeaderUI);

        LibraryVariableStorage.Enqueue(3); // Receive and Invoice menu choice
        InvokePostSelectedReturnOrders(PurchaseReturnOrderList, PurchaseHeader[2]);

        VerifyTwoOfThreeDocumentsUnposted(PurchaseHeaderUI, PurchaseHeader);

        ReturnShipmentHeader.SetRange("Buy-from Vendor No.", PurchaseHeader[2]."Buy-from Vendor No.");
        Assert.RecordCount(ReturnShipmentHeader, 1);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ErrorMessagesPagePurchasePostBatchMgtRunWithUIPostsFilteredOutRecords()
    var
        PurchaseHeader: array[3] of Record "Purchase Header";
        PurchaseHeaderCreated: Record "Purchase Header";
        PurchaseHeaderToPost: Record "Purchase Header";
        PurchaseBatchPostMgt: Codeunit "Purchase Batch Post Mgt.";
        ErrorMessages: TestPage "Error Messages";
        ErrorCount: Integer;
    begin
        // [SCENARIO] Cassie can't post selected invoices with 0 amounts and gets error message pages with wrong documents
        Initialize();
        LibraryPurchase.SetPostWithJobQueue(false);

        // [GIVEN] Invoices "X", "Y" and "Z" for with Amount = 0 each
        // [GIVEN] Cassie selects "X" and "Y" invoices to post
        // [WHEN] Cassie confirms she wants to post 2 out 3 invoices
        // [THEN] "X", "Y" and "Z" are not posted and system shows messages 'One or more of the documents could not be posted.'
        // [THEN] Error Messages page opened with 2 entries.
        CreateThreeDocuments(
          PurchaseHeader, PurchaseHeaderCreated, PurchaseHeader[1]."Document Type"::Invoice, 0);

        MarkDocumentsToPost(PurchaseHeaderToPost, PurchaseHeader, PurchaseHeaderCreated);

        LibraryVariableStorage.Enqueue(ReadyToPostTwoInvoicesQst);

        ErrorMessages.Trap();
        PurchaseBatchPostMgt.RunWithUI(PurchaseHeaderToPost, PurchaseHeaderCreated.Count, ReadyToPostInvoicesTemplateTok);

        repeat
            ErrorCount += 1;
            ErrorMessages.Description.AssertEquals(DocumentErrorsMgt.GetNothingToPostErrorMsg());
        until not ErrorMessages.Next();

        Assert.AreEqual(PurchaseHeaderToPost.Count, ErrorCount, 'Unexpected error count');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchasePostBatchMgtRunWithUIPostsFilteredOutRecordsBackground()
    var
        PurchaseHeader: array[3] of Record "Purchase Header";
        PurchaseHeaderCreated: Record "Purchase Header";
        PurchaseHeaderToPost: Record "Purchase Header";
        PurchaseBatchPostMgt: Codeunit "Purchase Batch Post Mgt.";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        // [SCENARIO] Cassie can post selected only invoices in background
        Initialize();
        LibraryPurchase.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // [GIVEN] Invoices "X", "Y" and "Z" for with Amount = 100 each
        // [GIVEN] Cassie selects "X" and "Y" invoices to post
        // [WHEN] Cassie confirms she wants to post 2 out 3 invoices
        // [THEN] "X" and "Y" posted and system shows message 'Batch successfully completed.'
        // [THEN] "Z" remains unposted
        CreateThreeDocuments(
          PurchaseHeader, PurchaseHeaderCreated, PurchaseHeader[1]."Document Type"::Invoice, LibraryRandom.RandIntInRange(10, 20));

        MarkDocumentsToPost(PurchaseHeaderToPost, PurchaseHeader, PurchaseHeaderCreated);

        LibraryVariableStorage.Enqueue(ReadyToPostTwoInvoicesQst);
        LibraryVariableStorage.Enqueue(BatchCompletedMsg);
        PurchaseBatchPostMgt.RunWithUI(PurchaseHeaderToPost, PurchaseHeaderCreated.Count, ReadyToPostInvoicesTemplateTok);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader[1].RecordId);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader[2].RecordId);

        VerifyInvoicePosted(PurchaseHeader[1]);
        VerifyInvoicePosted(PurchaseHeader[2]);
        VerifyInvoiceUnposted(PurchaseHeader[3]);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ErrorOnPostSelectedInvoice()
    var
        PurchaseHeader: array[3] of Record "Purchase Header";
        PurchaseHeaderUI: Record "Purchase Header";
        PurchaseInvoices: TestPage "Purchase Invoices";
        ErrorMessagesPage: TestPage "Error Messages";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] Cassie can see posting errors after batch posting from Purchase Invoices page
        Initialize();

        // [GIVEN] Invoices "X", "Y" and "Z" for with Amount = 0 each
        // [GIVEN] Cassie selects invoice "Y" on Purchase Invoices page and call "Post Selected" action
        // [WHEN] Cassie confirms she wants to post 1 out 3 invoices
        // [THEN] System shows page "Error Messages" with the line 'There is nothing to post' for "Y"
        // [THEN] Invoices "X", "Y" and "Z" remain unposted
        CreateThreeDocuments(PurchaseHeader, PurchaseHeaderUI, PurchaseHeader[1]."Document Type"::Invoice, 0);

        PurchaseInvoices.Trap();
        PAGE.Run(PAGE::"Purchase Invoices", PurchaseHeaderUI);

        LibraryVariableStorage.Enqueue(ConfirmZeroQuantityPostingMsg);
        LibraryVariableStorage.Enqueue(
          StrSubstNo(DoYouWantToPostQst, LowerCase(Format(PurchaseHeader[1]."Document Type"))));
        ErrorMessagesPage.Trap();
        InvokePostSelectedInvoices(PurchaseInvoices, PurchaseHeader[2]);

        ErrorMessagesPage.Description.AssertEquals(DocumentErrorsMgt.GetNothingToPostErrorMsg());
        ErrorMessagesPage.Context.AssertEquals(Format(PurchaseHeader[2].RecordId));

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ErrorOnPostSelectedCreditMemo()
    var
        PurchaseHeader: array[3] of Record "Purchase Header";
        PurchaseHeaderUI: Record "Purchase Header";
        PurchaseCreditMemos: TestPage "Purchase Credit Memos";
        ErrorMessagesPage: TestPage "Error Messages";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] Cassie can see posting errors after batch posting from Purchase Credit Memos page
        Initialize();

        // [GIVEN] Credit Memos "X", "Y" and "Z" for with Amount = 0 each
        // [GIVEN] Cassie selects credit memo "Y" on Purchase Credit Memos page and call "Post Selected" action
        // [WHEN] Cassie confirms she wants to post 1 out 3 credit memos
        // [THEN] System shows page "Error Messages" with the line 'There is nothing to post' for "Y"
        // [THEN] Credit memos "X", "Y" and "Z" remain unposted
        CreateThreeDocuments(PurchaseHeader, PurchaseHeaderUI, PurchaseHeader[1]."Document Type"::"Credit Memo", 0);

        PurchaseCreditMemos.Trap();
        PAGE.Run(PAGE::"Purchase Credit Memos", PurchaseHeaderUI);

        LibraryVariableStorage.Enqueue(ConfirmZeroQuantityPostingMsg);
        LibraryVariableStorage.Enqueue(
          StrSubstNo(DoYouWantToPostQst, LowerCase(Format(PurchaseHeader[1]."Document Type"))));
        ErrorMessagesPage.Trap();
        InvokePostSelectedCreditMemos(PurchaseCreditMemos, PurchaseHeader[2]);

        ErrorMessagesPage.Description.AssertEquals(DocumentErrorsMgt.GetNothingToPostErrorMsg());
        ErrorMessagesPage.Context.AssertEquals(Format(PurchaseHeader[2].RecordId));

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostStrMenuHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ErrorOnPostSelectedOrder()
    var
        PurchaseHeader: array[3] of Record "Purchase Header";
        PurchaseHeaderUI: Record "Purchase Header";
        PurchaseOrderList: TestPage "Purchase Order List";
        ErrorMessagesPage: TestPage "Error Messages";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] Cassie can see posting errors after batch posting from Purchase Order List page
        Initialize();

        // [GIVEN] Orders "X", "Y" and "Z" for with Amount = 0 each
        // [GIVEN] Cassie selects order "Y" on Purchase Order List page and call "Post Selected" action
        // [WHEN] Cassie confirms she wants to post 1 out 3 orders
        // [THEN] System shows page "Error Messages" with the line 'There is nothing to post' for "Y"
        // [THEN] Orders "X", "Y" and "Z" remain unposted
        CreateThreeDocuments(PurchaseHeader, PurchaseHeaderUI, PurchaseHeader[1]."Document Type"::Order, 0);

        PurchaseOrderList.Trap();
        PAGE.Run(PAGE::"Purchase Order List", PurchaseHeaderUI);

        LibraryVariableStorage.Enqueue(ConfirmZeroQuantityPostingMsg);
        LibraryVariableStorage.Enqueue(3); // Receive and Invoice menu choice
        ErrorMessagesPage.Trap();
        InvokePostSelectedOrders(PurchaseOrderList, PurchaseHeader[2]);

        ErrorMessagesPage.Description.AssertEquals(DocumentErrorsMgt.GetNothingToPostErrorMsg());
        ErrorMessagesPage.Context.AssertEquals(Format(PurchaseHeader[2].RecordId));

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostStrMenuHandler')]
    [Scope('OnPrem')]
    procedure ErrorOnPostSelectedReturnOrder()
    var
        PurchaseHeader: array[3] of Record "Purchase Header";
        PurchaseHeaderUI: Record "Purchase Header";
        PurchaseReturnOrderList: TestPage "Purchase Return Order List";
        ErrorMessagesPage: TestPage "Error Messages";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] Cassie can see posting errors after batch posting from Purchase Return Order List page
        Initialize();

        // [GIVEN] Return orders "X", "Y" and "Z" for with Amount = 0 each
        // [GIVEN] Cassie selects order "Y" on Purchase Return Order List page and call "Post Selected" action
        // [WHEN] Cassie confirms she wants to post 1 out 3 return orders
        // [THEN] System shows page "Error Messages" with the line 'There is nothing to post' for "Y"
        // [THEN] Return orders "X", "Y" and "Z" remain unposted
        CreateThreeDocuments(PurchaseHeader, PurchaseHeaderUI, PurchaseHeader[1]."Document Type"::"Return Order", 0);

        PurchaseReturnOrderList.Trap();
        PAGE.Run(PAGE::"Purchase Return Order List", PurchaseHeaderUI);

        LibraryVariableStorage.Enqueue(3); // Receive and Invoice menu choice
        ErrorMessagesPage.Trap();
        InvokePostSelectedReturnOrders(PurchaseReturnOrderList, PurchaseHeader[2]);

        ErrorMessagesPage.Description.AssertEquals(DocumentErrorsMgt.GetNothingToPostErrorMsg());
        ErrorMessagesPage.Context.AssertEquals(Format(PurchaseHeader[2].RecordId));

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleaseSelectedOrders()
    var
        PurchaseHeader: array[3] of Record "Purchase Header";
        PurchaseHeaderUI: Record "Purchase Header";
        PurchaseOrderList: TestPage "Purchase Order List";
    begin
        // [SCENARIO] Cassie can release selected order from Purchase Order List page
        Initialize();

        // [GIVEN] Orders "X", "Y" and "Z" for Vendor "C" with Amount = 100 each
        // [GIVEN] Cassie selects order "Y" on Purchase Order List page and calls "Release" action
        // [WHEN] Cassie confirms she wants to release 1 out 3 orders
        // [THEN] Orders "X" and "Z" remain unreleased
        // [THEN] Order "Y" is released
        CreateThreeDocuments(
          PurchaseHeader, PurchaseHeaderUI, PurchaseHeader[1]."Document Type"::Order, LibraryRandom.RandIntInRange(10, 20));

        PurchaseOrderList.Trap();
        PAGE.Run(PAGE::"Purchase Order List", PurchaseHeaderUI);

        InvokeReleaseSelectedOrders(PurchaseOrderList, PurchaseHeader[2]);

        VerifyPurchaseDocumentStatus(PurchaseHeader[1], PurchaseHeader[1].Status::Open);
        VerifyPurchaseDocumentStatus(PurchaseHeader[2], PurchaseHeader[2].Status::Released);
        VerifyPurchaseDocumentStatus(PurchaseHeader[3], PurchaseHeader[3].Status::Open);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReopenSelectedOrders()
    var
        PurchaseHeader: array[3] of Record "Purchase Header";
        PurchaseHeaderUI: Record "Purchase Header";
        PurchaseOrderList: TestPage "Purchase Order List";
    begin
        // [SCENARIO] Cassie can release selected order from Purchase Order List page
        Initialize();

        // [GIVEN] Orders "X", "Y" and "Z" for Vendor "C" with Amount = 100 each
        // [GIVEN] Orders "X", "Y" and "Z" for Vendor "C" with are all released
        // [GIVEN] Cassie selects order "Y" on Purchase Order List page and calls "Reopen" action
        // [WHEN] Cassie confirms she wants to reopen 1 out 3 orders
        // [THEN] Orders "X" and "Z" remain released
        // [THEN] Order "Y" is reopened
        CreateThreeDocuments(
          PurchaseHeader, PurchaseHeaderUI, PurchaseHeader[1]."Document Type"::Order, LibraryRandom.RandIntInRange(10, 20));

        PurchaseOrderList.Trap();
        PAGE.Run(PAGE::"Purchase Order List", PurchaseHeaderUI);

        InvokeReleaseSelectedOrders(PurchaseOrderList, PurchaseHeader[1]);
        InvokeReleaseSelectedOrders(PurchaseOrderList, PurchaseHeader[2]);
        InvokeReleaseSelectedOrders(PurchaseOrderList, PurchaseHeader[3]);

        InvokeReopenSelectedOrders(PurchaseOrderList, PurchaseHeader[2]);

        VerifyPurchaseDocumentStatus(PurchaseHeader[1], PurchaseHeader[1].Status::Released);
        VerifyPurchaseDocumentStatus(PurchaseHeader[2], PurchaseHeader[2].Status::Open);
        VerifyPurchaseDocumentStatus(PurchaseHeader[3], PurchaseHeader[3].Status::Released);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleaseSelectedInvoices()
    var
        PurchaseHeader: array[3] of Record "Purchase Header";
        PurchaseHeaderUI: Record "Purchase Header";
        PurchaseInvoices: TestPage "Purchase Invoices";
    begin
        // [SCENARIO] Cassie can release selected invoice from Purchase Invoice List page
        Initialize();

        // [GIVEN] Invoices "X", "Y" and "Z" for Customer "C" with Amount = 100 each
        // [GIVEN] Cassie selects invoice "Y" on Purchase Order List page and calls "Release" action
        // [WHEN] Cassie confirms she wants to release 1 out 3 invoices
        // [THEN] Invoices "X" and "Z" remain unreleased
        // [THEN] Invoice "Y" is released
        CreateThreeDocuments(
          PurchaseHeader, PurchaseHeaderUI, PurchaseHeader[1]."Document Type"::Invoice, LibraryRandom.RandIntInRange(10, 20));

        PurchaseInvoices.Trap();
        PAGE.Run(PAGE::"Purchase Invoices", PurchaseHeaderUI);

        InvokeReleaseSelectedInvoices(PurchaseInvoices, PurchaseHeader[2]);

        VerifyPurchaseDocumentStatus(PurchaseHeader[1], PurchaseHeader[1].Status::Open);
        VerifyPurchaseDocumentStatus(PurchaseHeader[2], PurchaseHeader[2].Status::Released);
        VerifyPurchaseDocumentStatus(PurchaseHeader[3], PurchaseHeader[3].Status::Open);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReopenSelectedInvoices()
    var
        PurchaseHeader: array[3] of Record "Purchase Header";
        PurchaseHeaderUI: Record "Purchase Header";
        PurchaseInvoices: TestPage "Purchase Invoices";
    begin
        // [SCENARIO] Cassie can release selected invoice from Purchase Invoice List page
        Initialize();

        // [GIVEN] Invoices "X", "Y" and "Z" for Customer "C" with Amount = 100 each
        // [GIVEN] Invoices "X", "Y" and "Z" for Customer "C" with are all released
        // [GIVEN] Cassie selects invoice "Y" on Purchase Invoice List page and calls "Reopen" action
        // [WHEN] Cassie confirms she wants to reopen 1 out 3 invoices
        // [THEN] Invoices "X" and "Z" remain released
        // [THEN] Invoice "Y" is reopened
        CreateThreeDocuments(
          PurchaseHeader, PurchaseHeaderUI, PurchaseHeader[1]."Document Type"::Invoice, LibraryRandom.RandIntInRange(10, 20));

        PurchaseInvoices.Trap();
        PAGE.Run(PAGE::"Purchase Invoices", PurchaseHeaderUI);

        InvokeReleaseSelectedInvoices(PurchaseInvoices, PurchaseHeader[1]);
        InvokeReleaseSelectedInvoices(PurchaseInvoices, PurchaseHeader[2]);
        InvokeReleaseSelectedInvoices(PurchaseInvoices, PurchaseHeader[3]);

        InvokeReopenSelectedInvoices(PurchaseInvoices, PurchaseHeader[2]);

        VerifyPurchaseDocumentStatus(PurchaseHeader[1], PurchaseHeader[1].Status::Released);
        VerifyPurchaseDocumentStatus(PurchaseHeader[2], PurchaseHeader[2].Status::Open);
        VerifyPurchaseDocumentStatus(PurchaseHeader[3], PurchaseHeader[3].Status::Released);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleaseSelectedCreditMemos()
    var
        PurchaseHeader: array[3] of Record "Purchase Header";
        PurchaseHeaderUI: Record "Purchase Header";
        PurchaseCreditMemos: TestPage "Purchase Credit Memos";
    begin
        // [SCENARIO] Cassie can release selected credit memo from Purchase Credit Memos page
        Initialize();

        // [GIVEN] Credit Memos "X", "Y" and "Z" for Customer "C" with Amount = 100 each
        // [GIVEN] Cassie selects credit memo "Y" on Purchase Credit Memos page and calls "Release" action
        // [WHEN] Cassie confirms she wants to release 1 out 3 credit memos
        // [THEN] Credit Memos "X" and "Z" remain unreleased
        // [THEN] Credit Memo "Y" is released
        CreateThreeDocuments(
          PurchaseHeader, PurchaseHeaderUI, PurchaseHeader[1]."Document Type"::"Credit Memo", LibraryRandom.RandIntInRange(10, 20));

        PurchaseCreditMemos.Trap();
        PAGE.Run(PAGE::"Purchase Credit Memos", PurchaseHeaderUI);

        InvokeReleaseSelectedCreditMemos(PurchaseCreditMemos, PurchaseHeader[2]);

        VerifyPurchaseDocumentStatus(PurchaseHeader[1], PurchaseHeader[1].Status::Open);
        VerifyPurchaseDocumentStatus(PurchaseHeader[2], PurchaseHeader[2].Status::Released);
        VerifyPurchaseDocumentStatus(PurchaseHeader[3], PurchaseHeader[3].Status::Open);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReopenSelectedCreditMemos()
    var
        PurchaseHeader: array[3] of Record "Purchase Header";
        PurchaseHeaderUI: Record "Purchase Header";
        PurchaseCreditMemos: TestPage "Purchase Credit Memos";
    begin
        // [SCENARIO] Cassie can release selected credit memo from Purchase Credit Memos page
        Initialize();

        // [GIVEN] Credit Memos "X", "Y" and "Z" for Customer "C" with Amount = 100 each
        // [GIVEN] Credit Memos "X", "Y" and "Z" for Customer "C" with are all released
        // [GIVEN] Cassie selects order "Y" on Credit Memos page and calls "Reopen" action
        // [WHEN] Cassie confirms she wants to reopen 1 out 3 credit memos
        // [THEN] Credit Memos "X" and "Z" remain released
        // [THEN] Credit Memo "Y" is reopened
        CreateThreeDocuments(
          PurchaseHeader, PurchaseHeaderUI, PurchaseHeader[1]."Document Type"::"Credit Memo", LibraryRandom.RandIntInRange(10, 20));

        PurchaseCreditMemos.Trap();
        PAGE.Run(PAGE::"Purchase Credit Memos", PurchaseHeaderUI);

        InvokeReleaseSelectedCreditMemos(PurchaseCreditMemos, PurchaseHeader[1]);
        InvokeReleaseSelectedCreditMemos(PurchaseCreditMemos, PurchaseHeader[2]);
        InvokeReleaseSelectedCreditMemos(PurchaseCreditMemos, PurchaseHeader[3]);

        InvokeReopenSelectedCreditMemos(PurchaseCreditMemos, PurchaseHeader[2]);

        VerifyPurchaseDocumentStatus(PurchaseHeader[1], PurchaseHeader[1].Status::Released);
        VerifyPurchaseDocumentStatus(PurchaseHeader[2], PurchaseHeader[2].Status::Open);
        VerifyPurchaseDocumentStatus(PurchaseHeader[3], PurchaseHeader[3].Status::Released);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleaseSelectedReturnOrders()
    var
        PurchaseHeader: array[3] of Record "Purchase Header";
        PurchaseHeaderUI: Record "Purchase Header";
        PurchaseReturnOrderList: TestPage "Purchase Return Order List";
    begin
        // [SCENARIO] Cassie can release selected return order from Purchase Return Order List page
        Initialize();

        // [GIVEN] Return Orders "X", "Y" and "Z" for Customer "C" with Amount = 100 each
        // [GIVEN] Cassie selects return order "Y" on Purchase Return Order List page and calls "Release" action
        // [WHEN] Cassie confirms she wants to release 1 out 3 return orders
        // [THEN] Return Orders "X" and "Z" remain unreleased
        // [THEN] Return Order "Y" is released
        CreateThreeDocuments(
          PurchaseHeader, PurchaseHeaderUI, PurchaseHeader[1]."Document Type"::"Return Order", LibraryRandom.RandIntInRange(10, 20));

        PurchaseReturnOrderList.Trap();
        PAGE.Run(PAGE::"Purchase Return Order List", PurchaseHeaderUI);

        InvokeReleaseSelectedReturnOrders(PurchaseReturnOrderList, PurchaseHeader[2]);

        VerifyPurchaseDocumentStatus(PurchaseHeader[1], PurchaseHeader[1].Status::Open);
        VerifyPurchaseDocumentStatus(PurchaseHeader[2], PurchaseHeader[2].Status::Released);
        VerifyPurchaseDocumentStatus(PurchaseHeader[3], PurchaseHeader[3].Status::Open);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReopenSelectedReturnOrders()
    var
        PurchaseHeader: array[3] of Record "Purchase Header";
        PurchaseHeaderUI: Record "Purchase Header";
        PurchaseReturnOrderList: TestPage "Purchase Return Order List";
    begin
        // [SCENARIO] Cassie can release selected return order from Purchase Return Order List page
        Initialize();

        // [GIVEN] Return Orders "X", "Y" and "Z" for Customer "C" with Amount = 100 each
        // [GIVEN] Return Orders "X", "Y" and "Z" for Customer "C" with are all released
        // [GIVEN] Cassie selects order "Y" on Purchase Return Order List page and calls "Reopen" action
        // [WHEN] Cassie confirms she wants to reopen 1 out 3 return orders
        // [THEN] Return Orders "X" and "Z" remain released
        // [THEN] Return Order "Y" is reopened
        CreateThreeDocuments(
          PurchaseHeader, PurchaseHeaderUI, PurchaseHeader[1]."Document Type"::"Return Order", LibraryRandom.RandIntInRange(10, 20));

        PurchaseReturnOrderList.Trap();
        PAGE.Run(PAGE::"Purchase Return Order List", PurchaseHeaderUI);

        InvokeReleaseSelectedReturnOrders(PurchaseReturnOrderList, PurchaseHeader[1]);
        InvokeReleaseSelectedReturnOrders(PurchaseReturnOrderList, PurchaseHeader[2]);
        InvokeReleaseSelectedReturnOrders(PurchaseReturnOrderList, PurchaseHeader[3]);

        InvokeReopenSelectedReturnOrders(PurchaseReturnOrderList, PurchaseHeader[2]);

        VerifyPurchaseDocumentStatus(PurchaseHeader[1], PurchaseHeader[1].Status::Released);
        VerifyPurchaseDocumentStatus(PurchaseHeader[2], PurchaseHeader[2].Status::Open);
        VerifyPurchaseDocumentStatus(PurchaseHeader[3], PurchaseHeader[3].Status::Released);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleaseSelectedBlanketOrders()
    var
        PurchaseHeader: array[3] of Record "Purchase Header";
        PurchaseHeaderUI: Record "Purchase Header";
        BlanketPurchaseOrders: TestPage "Blanket Purchase Orders";
    begin
        // [SCENARIO] Cassie can release selected blanket order from Blanket Purchase Orders page
        Initialize();

        // [GIVEN] Blanket Orders "X", "Y" and "Z" for Customer "C" with Amount = 100 each
        // [GIVEN] Cassie selects blanket order "Y" on Blanket Purchase Orders page and calls "Release" action
        // [WHEN] Cassie confirms she wants to release 1 out 3 blanket orders
        // [THEN] Blanket Orders "X" and "Z" remain unreleased
        // [THEN] Blanket Order "Y" is released
        CreateThreeDocuments(
          PurchaseHeader, PurchaseHeaderUI, PurchaseHeader[1]."Document Type"::"Blanket Order", LibraryRandom.RandIntInRange(10, 20));

        BlanketPurchaseOrders.Trap();
        PAGE.Run(PAGE::"Blanket Purchase Orders", PurchaseHeaderUI);

        InvokeReleaseSelectedBlanketOrders(BlanketPurchaseOrders, PurchaseHeader[2]);

        VerifyPurchaseDocumentStatus(PurchaseHeader[1], PurchaseHeader[1].Status::Open);
        VerifyPurchaseDocumentStatus(PurchaseHeader[2], PurchaseHeader[2].Status::Released);
        VerifyPurchaseDocumentStatus(PurchaseHeader[3], PurchaseHeader[3].Status::Open);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReopenSelectedBlanketOrders()
    var
        PurchaseHeader: array[3] of Record "Purchase Header";
        PurchaseHeaderUI: Record "Purchase Header";
        BlanketPurchaseOrders: TestPage "Blanket Purchase Orders";
    begin
        // [SCENARIO] Cassie can release selected blanket order from Blanket Purchase Orders page
        Initialize();

        // [GIVEN] Blanket Orders "X", "Y" and "Z" for Customer "C" with Amount = 100 each
        // [GIVEN] Blanket Orders "X", "Y" and "Z" for Customer "C" with are all released
        // [GIVEN] Cassie selects blanket order "Y" on Blanket Purchase Orders page and calls "Reopen" action
        // [WHEN] Cassie confirms she wants to reopen 1 out 3 blanket  orders
        // [THEN] Blanket Orders "X" and "Z" remain released
        // [THEN] Blanket Order "Y" is reopened
        CreateThreeDocuments(
          PurchaseHeader, PurchaseHeaderUI, PurchaseHeader[1]."Document Type"::"Blanket Order", LibraryRandom.RandIntInRange(10, 20));

        BlanketPurchaseOrders.Trap();
        PAGE.Run(PAGE::"Blanket Purchase Orders", PurchaseHeaderUI);

        InvokeReleaseSelectedBlanketOrders(BlanketPurchaseOrders, PurchaseHeader[1]);
        InvokeReleaseSelectedBlanketOrders(BlanketPurchaseOrders, PurchaseHeader[2]);
        InvokeReleaseSelectedBlanketOrders(BlanketPurchaseOrders, PurchaseHeader[3]);

        InvokeReopenSelectedBlanketOrders(BlanketPurchaseOrders, PurchaseHeader[2]);

        VerifyPurchaseDocumentStatus(PurchaseHeader[1], PurchaseHeader[1].Status::Released);
        VerifyPurchaseDocumentStatus(PurchaseHeader[2], PurchaseHeader[2].Status::Open);
        VerifyPurchaseDocumentStatus(PurchaseHeader[3], PurchaseHeader[3].Status::Released);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Purch. Batch Document Posting");
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Purch. Batch Document Posting");

        LibraryPurchase.SetReturnOrderNoSeriesInSetup();
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibraryApplicationArea.DisableApplicationAreaSetup();

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Purch. Batch Document Posting");
    end;

    local procedure CreateThreeDocuments(var PurchaseHeader: array[3] of Record "Purchase Header"; var PurchaseHeaderUI: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
        Index: Integer;
    begin
        for Index := 1 to ArrayLen(PurchaseHeader) do
            LibraryPurchase.CreatePurchaseDocumentWithItem(
              PurchaseHeader[Index], PurchaseLine, DocumentType, LibraryPurchase.CreateVendorNo(), '', Quantity, '', 0D);

        PurchaseHeaderUI.SetFilter("No.", '%1|%2|%3', PurchaseHeader[1]."No.", PurchaseHeader[2]."No.", PurchaseHeader[3]."No.");
        PurchaseHeaderUI.SetRange("Document Type", DocumentType);
    end;

    local procedure InvokePostSelectedInvoices(var PurchaseInvoices: TestPage "Purchase Invoices"; PurchaseHeaderToPost: Record "Purchase Header")
    begin
        PurchaseInvoices.GotoRecord(PurchaseHeaderToPost);
        PurchaseInvoices.PostSelected.Invoke();
    end;

    local procedure InvokePostSelectedCreditMemos(var PurchaseCreditMemos: TestPage "Purchase Credit Memos"; PurchaseHeaderToPost: Record "Purchase Header")
    begin
        PurchaseCreditMemos.GotoRecord(PurchaseHeaderToPost);
        PurchaseCreditMemos.Post.Invoke();
    end;

    local procedure InvokePostSelectedOrders(var PurchaseOrderList: TestPage "Purchase Order List"; PurchaseHeaderToPost: Record "Purchase Header")
    begin
        PurchaseOrderList.GotoRecord(PurchaseHeaderToPost);
        PurchaseOrderList.Post.Invoke();
    end;

    local procedure InvokeReleaseSelectedOrders(var PurchaseOrderList: TestPage "Purchase Order List"; PurchaseHeaderToRelease: Record "Purchase Header")
    begin
        PurchaseOrderList.GotoRecord(PurchaseHeaderToRelease);
        PurchaseOrderList.Release.Invoke();
    end;

    local procedure InvokeReopenSelectedOrders(var PurchaseOrderList: TestPage "Purchase Order List"; PurchaseHeaderToReopen: Record "Purchase Header")
    begin
        PurchaseOrderList.GotoRecord(PurchaseHeaderToReopen);
        PurchaseOrderList.Reopen.Invoke();
    end;

    local procedure InvokeReleaseSelectedInvoices(var PurchaseInvoices: TestPage "Purchase Invoices"; PurchaseHeaderToRelease: Record "Purchase Header")
    begin
        PurchaseInvoices.GotoRecord(PurchaseHeaderToRelease);
        PurchaseInvoices.Release.Invoke();
    end;

    local procedure InvokeReopenSelectedInvoices(var PurchaseInvoices: TestPage "Purchase Invoices"; PurchaseHeaderToReopen: Record "Purchase Header")
    begin
        PurchaseInvoices.GotoRecord(PurchaseHeaderToReopen);
        PurchaseInvoices."Reopen".Invoke();
    end;

    local procedure InvokeReleaseSelectedCreditMemos(var PurchaseCreditMemos: TestPage "Purchase Credit Memos"; PurchaseHeaderToRelease: Record "Purchase Header")
    begin
        PurchaseCreditMemos.GotoRecord(PurchaseHeaderToRelease);
        PurchaseCreditMemos."Release".Invoke();
    end;

    local procedure InvokeReopenSelectedCreditMemos(var PurchaseCreditMemos: TestPage "Purchase Credit Memos"; PurchaseHeaderToReopen: Record "Purchase Header")
    begin
        PurchaseCreditMemos.GotoRecord(PurchaseHeaderToReopen);
        PurchaseCreditMemos."Reopen".Invoke();
    end;

    local procedure InvokePostSelectedReturnOrders(var PurchaseReturnOrderList: TestPage "Purchase Return Order List"; PurchaseHeaderToPost: Record "Purchase Header")
    begin
        PurchaseReturnOrderList.GotoRecord(PurchaseHeaderToPost);
        PurchaseReturnOrderList.Post.Invoke();
    end;

    local procedure InvokeReleaseSelectedReturnOrders(var PurchaseReturnOrderList: TestPage "Purchase Return Order List"; PurchaseHeaderToRelease: Record "Purchase Header")
    begin
        PurchaseReturnOrderList.GotoRecord(PurchaseHeaderToRelease);
        PurchaseReturnOrderList.Release.Invoke();
    end;

    local procedure InvokeReopenSelectedReturnOrders(var PurchaseReturnOrderList: TestPage "Purchase Return Order List"; PurchaseHeaderToReopen: Record "Purchase Header")
    begin
        PurchaseReturnOrderList.GotoRecord(PurchaseHeaderToReopen);
        PurchaseReturnOrderList.Reopen.Invoke();
    end;

    local procedure InvokeReleaseSelectedBlanketOrders(var BlanketPurchaseOrders: TestPage "Blanket Purchase Orders"; PurchaseHeaderToRelease: Record "Purchase Header")
    begin
        BlanketPurchaseOrders.GotoRecord(PurchaseHeaderToRelease);
        BlanketPurchaseOrders."Release".Invoke();
    end;

    local procedure InvokeReopenSelectedBlanketOrders(var BlanketPurchaseOrders: TestPage "Blanket Purchase Orders"; PurchaseHeaderToReopen: Record "Purchase Header")
    begin
        BlanketPurchaseOrders.GotoRecord(PurchaseHeaderToReopen);
        BlanketPurchaseOrders."Reopen".Invoke();
    end;

    local procedure MarkDocumentsToPost(var PurchaseHeaderToPost: Record "Purchase Header"; var PurchaseHeader: array[3] of Record "Purchase Header"; var PurchaseHeaderCreated: Record "Purchase Header")
    begin
        PurchaseHeaderToPost.CopyFilters(PurchaseHeaderCreated);
        PurchaseHeaderToPost.Get(PurchaseHeader[1]."Document Type", PurchaseHeader[1]."No.");
        PurchaseHeaderToPost.Mark(true);
        PurchaseHeaderToPost.Get(PurchaseHeader[2]."Document Type", PurchaseHeader[2]."No.");
        PurchaseHeaderToPost.Mark(true);
        // to be sure the only filtered documents are posted
        PurchaseHeaderToPost.Get(PurchaseHeader[3]."Document Type", PurchaseHeader[3]."No.");
        PurchaseHeaderToPost.MarkedOnly(true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Question);
        Reply := true; // precal forces to set any value to VAR parameter
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

    local procedure VerifyTwoOfThreeDocumentsUnposted(var PurchaseHeaderUI: Record "Purchase Header"; var PurchaseHeader: array[3] of Record "Purchase Header")
    begin
        Assert.RecordCount(PurchaseHeaderUI, ArrayLen(PurchaseHeader) - 1);
        PurchaseHeaderUI.FindFirst();
        PurchaseHeaderUI.TestField("No.", PurchaseHeader[1]."No.");
        PurchaseHeaderUI.Next();
        PurchaseHeaderUI.TestField("No.", PurchaseHeader[3]."No.");
    end;

    local procedure VerifyInvoicePosted(var PurchaseHeader: Record "Purchase Header")
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        Assert.RecordCount(PurchInvHeader, 1);
        Assert.IsFalse(PurchaseHeader.Find(), '');
    end;

    local procedure VerifyInvoiceUnposted(var PurchaseHeader: Record "Purchase Header")
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        Assert.RecordCount(PurchInvHeader, 0);
        Assert.IsTrue(PurchaseHeader.Find(), '');
    end;

    local procedure VerifyPurchaseDocumentStatus(var PurchaseHeader: Record "Purchase Header"; ExpectedStatus: Enum "Purchase Document Status")
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        Assert.RecordCount(PurchInvHeader, 0);
        PurchaseHeader.Find();
        PurchaseHeader.TestField(Status, ExpectedStatus);
    end;
}

