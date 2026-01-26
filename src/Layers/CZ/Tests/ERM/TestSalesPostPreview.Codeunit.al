codeunit 134763 "Test Sales Post Preview"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Post Preview] [Sales]
    end;

    var
        Assert: Codeunit Assert;
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryTrees: Codeunit "Library - Trees";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryPmtDiscSetup: Codeunit "Library - Pmt Disc Setup";
        LibraryJournals: Codeunit "Library - Journals";
        IsInitialized: Boolean;
        SalesHeaderPostingNo: Code[20];
        DocumentNos: Dictionary of [Text, Text];
        NoRecordsErr: Label 'There are no preview records to show.';
        WrongPostPreviewErr: Label 'Expected empty error from Preview. Actual error: ';
        RecordRestrictedTxt: Label 'You cannot use %1 for this action.', Comment = '%1 You cannot use Customer 10000 for this action.';
        InvalidSubscriberTypeErr: label 'Invalid Subscriber type. The type must be CODEUNIT.';
        TotalInvoiceAmountNegativeErr: Label 'The total amount for the invoice must be 0 or greater.';

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesInvoicePreview()
    var
        SalesHeader: Record "Sales Header";
        SalesPostYesNo: Codeunit "Sales-Post (Yes/No)";
        TestSalesPostPreview: Codeunit "Test Sales Post Preview";
        GLPostingPreview: TestPage "G/L Posting Preview";
        CustomerEntriesPreview: TestPage "Cust. Ledg. Entries Preview";
        AmountToVerify: Decimal;
        ExpectedQuantity: Decimal;
    begin
        // [SCENARIO] Posting preview of Sales Invoice opens G/L Posting Preview with the navigatable entries to be posted.
        Initialize();
        AmountToVerify := LibraryRandom.RandInt(500);
        ExpectedQuantity := LibraryRandom.RandInt(10);

        CreateSalesRecord(SalesHeader, AmountToVerify, ExpectedQuantity, SalesHeader."Document Type"::Invoice);
        BindSubscription(TestSalesPostPreview);

        // Execute
        GLPostingPreview.Trap();
        asserterror SalesPostYesNo.Preview(SalesHeader);
        Assert.AreEqual('', GetLastErrorText, WrongPostPreviewErr + GetLastErrorText);
        GLPostingPreviewHandler(GLPostingPreview);
        CustomerEntriesPreview.Trap();
        GLPostingPreview.FILTER.SetFilter("Table ID", Format(DATABASE::"Cust. Ledger Entry"));
        GLPostingPreview.Show.Invoke();
        CustEntriesPreviewHandler(CustomerEntriesPreview, SalesHeader."Document Type"::Invoice);

        GLPostingPreview.OK().Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesOrderPreview()
    var
        SalesHeader: Record "Sales Header";
        SalesPostYesNo: Codeunit "Sales-Post (Yes/No)";
        TestSalesPostPreview: Codeunit "Test Sales Post Preview";
        GLPostingPreview: TestPage "G/L Posting Preview";
        CustomerEntriesPreview: TestPage "Cust. Ledg. Entries Preview";
        AmountToVerify: Decimal;
        ExpectedQuantity: Decimal;
    begin
        // [SCENARIO] Posting preview of Sales Order opens G/L Posting Preview with the navigatable entries to be posted.
        Initialize();
        AmountToVerify := LibraryRandom.RandInt(500);
        ExpectedQuantity := LibraryRandom.RandInt(10);

        CreateSalesRecord(SalesHeader, AmountToVerify, ExpectedQuantity, SalesHeader."Document Type"::Order);
        BindSubscription(TestSalesPostPreview);

        // Execute

        GLPostingPreview.Trap();
        asserterror SalesPostYesNo.Preview(SalesHeader);
        Assert.AreEqual('', GetLastErrorText, WrongPostPreviewErr + GetLastErrorText);
        GLPostingPreviewHandler(GLPostingPreview);
        // Verify
        CustomerEntriesPreview.Trap();
        GLPostingPreview.FILTER.SetFilter("Table ID", Format(DATABASE::"Cust. Ledger Entry"));
        GLPostingPreview.Show.Invoke();
        CustEntriesPreviewHandler(CustomerEntriesPreview, SalesHeader."Document Type"::Invoice);

        GLPostingPreview.OK().Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceTryPreview()
    var
        SalesHeader: Record "Sales Header";
        SalesPostYesNo: Codeunit "Sales-Post (Yes/No)";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        ErrorMessageMgt: codeunit "Error Message Management";
        PostingPreviewEventHandler: Codeunit "Posting Preview Event Handler";
        RecRef: RecordRef;
        ErrorMsg: Text[250];
        AmountToVerify: Decimal;
        ExpectedQuantity: Decimal;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Run posting preview engine with success
        Initialize();
        // [GIVEN] the valid Sales Invoice with one line
        AmountToVerify := LibraryRandom.RandInt(500);
        ExpectedQuantity := LibraryRandom.RandInt(10);
        CreateSalesRecord(SalesHeader, AmountToVerify, ExpectedQuantity, SalesHeader."Document Type"::Invoice);

        // [WHEN] Run TryPreview()
        BindSubscription(SalesPostYesNo);
        GenJnlPostPreview.SetContext(SalesPostYesNo, SalesHeader);
        Assert.IsFalse(GenJnlPostPreview.Run(), 'Preview.Run returned true');

        // [THEN] Preview has not failed
        Assert.IsTrue(GenJnlPostPreview.IsSuccess(), 'preview has failed');
        // [THEN] PostingPreviewEventHandler gives access to temp buffers: CLE and G/L Entries.
        GenJnlPostPreview.GetPreviewHandler(PostingPreviewEventHandler);
        PostingPreviewEventHandler.GetEntries(Database::"Cust. Ledger Entry", RecRef);
        Assert.RecordCount(RecRef, 1);
        PostingPreviewEventHandler.GetEntries(Database::"G/L Entry", RecRef);
        Assert.RecordCount(RecRef, 3);
        // [THEN] No error message found
        Assert.AreEqual(0, ErrorMessageMgt.GetLastError(ErrorMsg), 'Errors found');
        // Cleanup
        asserterror Error('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceTryPreviewMissingContext()
    var
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Run posting preview engine if context is missing
        Initialize();

        // [WHEN] Run TryPreview() without context
        Commit();
        Assert.IsFalse(GenJnlPostPreview.Run(), 'Preview.Run returned true');

        // [THEN] Preview has failed: 'Invalid Subscriber Type'
        Assert.IsFalse(GenJnlPostPreview.IsSuccess(), 'preview has not failed');
        Assert.ExpectedError(InvalidSubscriberTypeErr);

        // Cleanup
        asserterror Error('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceTryPreviewWithFailure()
    var
        SalesHeader: Record "Sales Header";
        SalesPostYesNo: Codeunit "Sales-Post (Yes/No)";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        ErrorMessageMgt: codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        PostingPreviewEventHandler: Codeunit "Posting Preview Event Handler";
        RecRef: RecordRef;
        ErrorMsg: Text[250];
        AmountToVerify: Decimal;
        ExpectedQuantity: Decimal;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Run posting preview engine if error occurs
        Initialize();
        // [GIVEN] the valid Sales Invoice with one line, where amount is negative
        AmountToVerify := -LibraryRandom.RandInt(500);
        ExpectedQuantity := LibraryRandom.RandInt(10);
        CreateSalesRecord(SalesHeader, AmountToVerify, ExpectedQuantity, SalesHeader."Document Type"::Invoice);

        // [WHEN] Run TryPreview()
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        BindSubscription(SalesPostYesNo);
        GenJnlPostPreview.SetContext(SalesPostYesNo, SalesHeader);
        Assert.IsFalse(GenJnlPostPreview.Run(), 'Preview.Run returned true');

        // [THEN] Preview has failed
        Assert.IsFalse(GenJnlPostPreview.IsSuccess(), 'preview has not failed');
        // [THEN] PostingPreviewEventHandler gives access to temp buffers: CLE and G/L Entries
        GenJnlPostPreview.GetPreviewHandler(PostingPreviewEventHandler);
        PostingPreviewEventHandler.GetEntries(Database::"Cust. Ledger Entry", RecRef);
        Assert.RecordIsEmpty(RecRef);
        PostingPreviewEventHandler.GetEntries(Database::"G/L Entry", RecRef);
        // TFS 423695 the error arrises in "Sales-Post".CheckTotalInvoiceAmount(...)
        Assert.RecordIsEmpty(RecRef);
        // [THEN] Error message found: "Amount must be positive"
        Assert.IsTrue(ErrorMessageMgt.IsActive(), 'ErroMsgMgt inactive');
        Assert.AreNotEqual(0, ErrorMessageMgt.GetLastError(ErrorMsg), 'Errors not found');
        Assert.ExpectedMessage(TotalInvoiceAmountNegativeErr, ErrorMsg);
        // Cleanup
        asserterror Error('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceOpensPreview()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoice: TestPage "Sales Invoice";
        GLPostingPreview: TestPage "G/L Posting Preview";
        AmountToVerify: Decimal;
        ExpectedQuantity: Decimal;
    begin
        // [SCENARIO] Preview action on Sales Invoice page runs posting preview engine
        Initialize();
        LibraryERM.SetEnableDataCheck(false);

        AmountToVerify := LibraryRandom.RandInt(500);
        ExpectedQuantity := LibraryRandom.RandInt(10);

        CreateSalesRecord(SalesHeader, AmountToVerify, ExpectedQuantity, SalesHeader."Document Type"::Invoice);

        SalesInvoice.Trap();
        PAGE.Run(PAGE::"Sales Invoice", SalesHeader);

        GLPostingPreview.Trap();
        SalesInvoice.Preview.Invoke();

        if not GLPostingPreview.First() then
            Error(NoRecordsErr);
        GLPostingPreview.OK().Invoke();

        // Cleanup
        LibraryERM.SetEnableDataCheck(true);
        asserterror Error('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceListOpensPreview()
    var
        SalesHeader: Record "Sales Header";
        GLPostingPreview: TestPage "G/L Posting Preview";
        SalesInvoiceList: TestPage "Sales Invoice List";
        AmountToVerify: Decimal;
        ExpectedQuantity: Decimal;
    begin
        // [SCENARIO] Preview action on Sales Invoice List page runs posting preview engine
        Initialize();
        AmountToVerify := LibraryRandom.RandInt(500);
        ExpectedQuantity := LibraryRandom.RandInt(10);

        CreateSalesRecord(SalesHeader, AmountToVerify, ExpectedQuantity, SalesHeader."Document Type"::Invoice);

        SalesInvoiceList.Trap();
        PAGE.Run(PAGE::"Sales Invoice List", SalesHeader);

        GLPostingPreview.Trap();
        SalesInvoiceList.Preview.Invoke();

        if not GLPostingPreview.First() then
            Error(NoRecordsErr);
        GLPostingPreview.OK().Invoke();

        // Cleanup
        asserterror Error('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderOpensPreview()
    var
        SalesHeader: Record "Sales Header";
        GLPostingPreview: TestPage "G/L Posting Preview";
        SalesOrder: TestPage "Sales Order";
        AmountToVerify: Decimal;
        ExpectedQuantity: Decimal;
    begin
        // [SCENARIO] Preview action on Sales Order page runs posting preview engine
        Initialize();
        LibraryERM.SetEnableDataCheck(false);

        AmountToVerify := LibraryRandom.RandInt(500);
        ExpectedQuantity := LibraryRandom.RandInt(10);

        CreateSalesRecord(SalesHeader, AmountToVerify, ExpectedQuantity, SalesHeader."Document Type"::Order);

        SalesOrder.Trap();
        PAGE.Run(PAGE::"Sales Order", SalesHeader);

        GLPostingPreview.Trap();
        SalesOrder.PreviewPosting.Invoke();

        if not GLPostingPreview.First() then
            Error(NoRecordsErr);
        GLPostingPreview.OK().Invoke();

        // Cleanup
        LibraryERM.SetEnableDataCheck(true);
        asserterror Error('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderListOpensPreview()
    var
        SalesHeader: Record "Sales Header";
        GLPostingPreview: TestPage "G/L Posting Preview";
        SalesOrderList: TestPage "Sales Order List";
        AmountToVerify: Decimal;
        ExpectedQuantity: Decimal;
    begin
        // [SCENARIO] Preview action on Sales Order List page runs posting preview engine
        Initialize();
        AmountToVerify := LibraryRandom.RandInt(500);
        ExpectedQuantity := LibraryRandom.RandInt(10);

        CreateSalesRecord(SalesHeader, AmountToVerify, ExpectedQuantity, SalesHeader."Document Type"::Order);

        SalesOrderList.Trap();
        PAGE.Run(PAGE::"Sales Order List", SalesHeader);

        GLPostingPreview.Trap();
        SalesOrderList."Preview Posting".Invoke();

        if not GLPostingPreview.First() then
            Error(NoRecordsErr);
        GLPostingPreview.OK().Invoke();

        // Cleanup
        asserterror Error('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesReturnOpensPreview()
    var
        SalesHeader: Record "Sales Header";
        GLPostingPreview: TestPage "G/L Posting Preview";
        SalesReturnOrder: TestPage "Sales Return Order";
        AmountToVerify: Decimal;
        ExpectedQuantity: Decimal;
    begin
        // [SCENARIO] Preview action on Sales Return Order page runs posting preview engine
        Initialize();
        LibraryERM.SetEnableDataCheck(false);

        AmountToVerify := LibraryRandom.RandInt(500);
        ExpectedQuantity := LibraryRandom.RandInt(10);

        CreateSalesRecord(SalesHeader, AmountToVerify, ExpectedQuantity, SalesHeader."Document Type"::"Return Order");

        SalesReturnOrder.Trap();
        PAGE.Run(PAGE::"Sales Return Order", SalesHeader);

        GLPostingPreview.Trap();
        SalesReturnOrder."Preview Posting".Invoke(); // Preview

        if not GLPostingPreview.First() then
            Error(NoRecordsErr);
        GLPostingPreview.OK().Invoke();

        // Cleanup
        LibraryERM.SetEnableDataCheck(true);
        asserterror Error('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesReturnListOpensPreview()
    var
        SalesHeader: Record "Sales Header";
        GLPostingPreview: TestPage "G/L Posting Preview";
        SalesReturnOrderList: TestPage "Sales Return Order List";
        AmountToVerify: Decimal;
        ExpectedQuantity: Decimal;
    begin
        // [SCENARIO] Preview action on Sales Return Order List page runs posting preview engine
        Initialize();
        AmountToVerify := LibraryRandom.RandInt(500);
        ExpectedQuantity := LibraryRandom.RandInt(10);

        CreateSalesRecord(SalesHeader, AmountToVerify, ExpectedQuantity, SalesHeader."Document Type"::"Return Order");

        SalesReturnOrderList.Trap();
        PAGE.Run(PAGE::"Sales Return Order List", SalesHeader);

        GLPostingPreview.Trap();
        SalesReturnOrderList."Preview Posting".Invoke(); // Preview

        if not GLPostingPreview.First() then
            Error(NoRecordsErr);
        GLPostingPreview.OK().Invoke();

        // Cleanup
        asserterror Error('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoOpensPreview()
    var
        SalesHeader: Record "Sales Header";
        GLPostingPreview: TestPage "G/L Posting Preview";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        AmountToVerify: Decimal;
        ExpectedQuantity: Decimal;
    begin
        // [SCENARIO] Preview action on Sales Credit Memo page runs posting preview engine
        Initialize();
        LibraryERM.SetEnableDataCheck(false);

        AmountToVerify := LibraryRandom.RandInt(500);
        ExpectedQuantity := LibraryRandom.RandInt(10);

        CreateSalesRecord(SalesHeader, AmountToVerify, ExpectedQuantity, SalesHeader."Document Type"::"Credit Memo");

        SalesCreditMemo.Trap();
        PAGE.Run(PAGE::"Sales Credit Memo", SalesHeader);

        GLPostingPreview.Trap();
        SalesCreditMemo."Preview Posting".Invoke(); // Preview

        if not GLPostingPreview.First() then
            Error(NoRecordsErr);
        GLPostingPreview.OK().Invoke();

        // Cleanup
        LibraryERM.SetEnableDataCheck(true);
        asserterror Error('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoListOpensPreview()
    var
        SalesHeader: Record "Sales Header";
        GLPostingPreview: TestPage "G/L Posting Preview";
        SalesCreditMemos: TestPage "Sales Credit Memos";
        AmountToVerify: Decimal;
        ExpectedQuantity: Decimal;
    begin
        // [SCENARIO] Preview action on Sales Credit Memo Lists page runs posting preview engine
        Initialize();
        AmountToVerify := LibraryRandom.RandInt(500);
        ExpectedQuantity := LibraryRandom.RandInt(10);

        CreateSalesRecord(SalesHeader, AmountToVerify, ExpectedQuantity, SalesHeader."Document Type"::"Credit Memo");

        SalesCreditMemos.Trap();
        PAGE.Run(PAGE::"Sales Credit Memos", SalesHeader);

        GLPostingPreview.Trap();
        SalesCreditMemos."Preview Posting".Invoke(); // Preview

        if not GLPostingPreview.First() then
            Error(NoRecordsErr);
        GLPostingPreview.OK().Invoke();

        // Cleanup
        asserterror Error('');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestSalesInvoicePreviewWorksWithApprovals()
    var
        SalesHeader: Record "Sales Header";
        RestrictedRecord: Record "Restricted Record";
        SalesPostYesNo: Codeunit "Sales-Post (Yes/No)";
        RecordRestrictionMgt: Codeunit "Record Restriction Mgt.";
        GLPostingPreview: TestPage "G/L Posting Preview";
        AmountToVerify: Decimal;
        ExpectedQuantity: Decimal;
        ExpectedErrorMessage: Text;
        ActualErrorMessage: Text;
    begin
        // [SCENARIO] Preview action on Sales Invoice should work even if Invoice is under Approval Workflow.
        Initialize();
        AmountToVerify := LibraryRandom.RandInt(500);
        ExpectedQuantity := LibraryRandom.RandInt(10);

        // [GIVEN] Sales Invoice that is under an approval workflow.
        CreateSalesRecord(SalesHeader, AmountToVerify, ExpectedQuantity, SalesHeader."Document Type"::Invoice);
        RecordRestrictionMgt.RestrictRecordUsage(SalesHeader, '');
        Commit();
        RestrictedRecord.SetRange("Record ID", SalesHeader.RecordId);
        Assert.IsTrue(RestrictedRecord.FindFirst(), 'Missing RestrictedRecord');

        // [WHEN] Preview is executed
        GLPostingPreview.Trap();
        asserterror SalesPostYesNo.Preview(SalesHeader);
        // [THEN] GETLASTERRORTEXT should be null
        Assert.AreEqual('', GetLastErrorText, 'Expected empty error from Preview. Actual error: ' + GetLastErrorText);
        GLPostingPreview.Close();

        ClearLastError();
        Clear(SalesPostYesNo);

        ExpectedErrorMessage := StrSubstNo(RecordRestrictedTxt,
            Format(Format(RestrictedRecord."Record ID", 0, 1)));

        // [WHEN] Post is executed.
        asserterror SalesPostYesNo.Run(SalesHeader);
        // [THEN] GETLASTERRORTEXT should be non-null
        ActualErrorMessage := CopyStr(GetLastErrorText, 1, StrLen(ExpectedErrorMessage));
        Assert.AreEqual(ExpectedErrorMessage, ActualErrorMessage, 'Unexpected error message.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartialShippedSalesOrderOpensPreview()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPostYesNo: Codeunit "Sales-Post (Yes/No)";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [SCENARIO 376432] Preview action should work for partial shipped Sales Order

        Initialize();

        // [GIVEN] "Calc. Inv. Discount" is enabled in Sales & Receivables Setup
        LibrarySales.SetCalcInvDiscount(true);

        // [GIVEN] Partial shipped Sales Order
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandIntInRange(2, 10));
        SalesLine.Validate("Qty. to Ship", LibraryRandom.RandIntInRange(1, SalesLine.Quantity));
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [WHEN] Open Post Preview
        GLPostingPreview.Trap();
        asserterror SalesPostYesNo.Preview(SalesHeader);

        // [THEN] Preview is open
        Assert.AreEqual('', GetLastErrorText, WrongPostPreviewErr + GetLastErrorText); // If preview was prepared successfully, it throws an empty error to roll the transaction back
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestPartialSalesOrderPreview()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Location: Record Location;
        SalesPostYesNo: Codeunit "Sales-Post (Yes/No)";
        GLPostingPreview: TestPage "G/L Posting Preview";
        ItemNo: Code[20];
    begin
        // [SCENARIO 378536] Preview action can be opened for Sales Order with FIFO Item, if was before posted partially several times.
        Initialize();

        // [GIVEN] Inventory Setup: Automatic Cost Posting = TRUE, Expected Cost Posting = TRUE
        LibraryInventory.SetAutomaticCostPosting(true);
        LibraryInventory.SetExpectedCostPosting(true);
        LibraryInventory.UpdateInventoryPostingSetup(Location);

        // [GIVEN] Item with Lot Tracking and Costing Method FIFO
        ItemNo := CreateItemWithFIFO();
        CreateAndPostItemJournalLine(ItemNo, LibraryRandom.RandDecInRange(10, 20, 2));

        // [GIVEN] Create Sales Order, Ship and Invoice partially
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandIntInRange(5, 10));
        PostPartialQuantity(SalesHeader, true);

        // [GIVEN] Ship Sales Order again partially
        PostPartialQuantity(SalesHeader, false);

        // [WHEN] Open Post Preview
        GLPostingPreview.Trap();
        asserterror SalesPostYesNo.Preview(SalesHeader);

        // [THEN] Preview is open
        Assert.AreEqual('', GetLastErrorText, WrongPostPreviewErr + GetLastErrorText);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOnPostPreviewOrderWithBlockedCustomer()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        SalesPostYesNo: Codeunit "Sales-Post (Yes/No)";
        ErrorMessagesPage: TestPage "Error Messages";
    begin
        // [SCENARIO 221818] Preview posting does not hide actual error when posting sales document for blocked customer
        Initialize();

        // [GIVEN] Sales Order with Customer "X" has Blocked = " "
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandIntInRange(2, 10));

        // [GIVEN] Customer "X" has Blocked = "All"
        Customer.Blocked := Customer.Blocked::All;
        Customer.Modify(true);
        Commit();

        // [WHEN] Try Preview Posting for Sales Order
        ErrorMessagesPage.Trap();
        asserterror SalesPostYesNo.Preview(SalesHeader);

        // [THEN] Error: "You cannot post this type of document when Customer X is blocked with type All"
        Assert.ExpectedError('');
        Assert.ExpectedMessage(
          'You cannot post this type of document when Customer ' + Customer."No." + ' is blocked with type All',
          ErrorMessagesPage.Description.Value);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOnPostPreviewOrderWithPrivacyBlockedCustomer()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        SalesPostYesNo: Codeunit "Sales-Post (Yes/No)";
        ErrorMessagesPage: TestPage "Error Messages";
    begin
        // [SCENARIO 221818] Preview posting does not hide actual error when posting sales document for Privacy Blocked customer
        Initialize();

        // [GIVEN] Sales Order with Customer "X" is PrivacyBlocked
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandIntInRange(2, 10));

        // [GIVEN] Customer "X" is PrivacyBlocked
        Customer.Validate("Privacy Blocked", true);
        Customer.Modify(true);
        Commit();

        // [WHEN] Try Preview Posting for Sales Order
        ErrorMessagesPage.Trap();
        asserterror SalesPostYesNo.Preview(SalesHeader);

        // [THEN] Error: "You cannot post this type of document when Customer X is blocked for privacy"
        Assert.ExpectedError('');
        Assert.ExpectedMessage(
          'You cannot post this type of document when Customer ' + Customer."No." + ' is blocked for privacy.',
          ErrorMessagesPage.Description.Value);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderWithCalcInvAndDiscPreview()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPostYesNo: Codeunit "Sales-Post (Yes/No)";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [FEATURE] [Order]
        // [SCENARIO 263954] Stan can see posting preview of released sales order when "Calc. Inv. and Pmt. Discount" is set in setup.
        // [GIVEN] "Calc. Inv. and Pmt. Discount" = TRUE in "Sales & Receivable Setup"
        LibrarySales.SetCalcInvDiscount(true);
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order,
          '', '', LibraryRandom.RandIntInRange(5, 10), '', WorkDate());
        SalesHeader.Modify(true);
        Commit();

        // [WHEN] Stan calls "Post Preview" from invoice
        GLPostingPreview.Trap();
        asserterror SalesPostYesNo.Preview(SalesHeader);
        Assert.ExpectedError('');

        // [THEN] Posting preview page opens without errors.
        GLPostingPreview.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderWithCalcInvAndDiscPreviewPartialInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPostYesNo: Codeunit "Sales-Post (Yes/No)";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [FEATURE] [Order]
        // [SCENARIO 263954] Stan can see posting preview of released sales order when "Calc. Inv. and Pmt. Discount" is set in setup.
        // [GIVEN] "Calc. Inv. and Pmt. Discount" = TRUE in "Sales & Receivable Setup"
        // [GIVEN] "Qty. to Invoice" = 90, "Quantity" = 100
        LibrarySales.SetCalcInvDiscount(true);
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order,
          '', '', LibraryRandom.RandIntInRange(5, 10), '', WorkDate());

        SalesLine.Validate("Qty. to Invoice", SalesLine.Quantity / 3);
        SalesLine.Modify(true);

        LibrarySales.ReleaseSalesDocument(SalesHeader);
        Commit();

        // [WHEN] Stan calls "Post Preview" from invoice
        GLPostingPreview.Trap();
        asserterror SalesPostYesNo.Preview(SalesHeader);
        Assert.ExpectedError('');

        // [THEN] Posting preview page opens without errors.
        GLPostingPreview.Close();
    end;

    [Test]
    [HandlerFunctions('GLPostingPreviewPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PmtDiscToleranceConsidersOnPostingPreview()
    var
        ApplyUnapplyParameters: Record "Apply Unapply Parameters";
        ApplyingCustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
        InvNo: Code[20];
        PmtNo: Code[20];
    begin
        // [FEATURE] [Payment Discount] [Payment Discount Tolerance]
        // [SCENARIO 277573] Payment Discount Tolerance considers when preview application of payment to invoice

        Initialize();
        if Confirm('') then; // test instability caused by the confirmation dialog's reliance on the working date.

        // [GIVEN] Posted payment and invoice with possible payment discount tolerance
        LibraryPmtDiscSetup.SetPmtDiscGracePeriodByText(Format(LibraryRandom.RandIntInRange(3, 10)) + 'D');
        PostPaidInvWithPmtDiscTol(InvNo, PmtNo);
        FindEntriesAndSetAppliesToID(ApplyingCustLedgerEntry, CustLedgerEntry, InvNo, PmtNo);
        Commit();
        LibraryVariableStorage.Enqueue(DATABASE::"Detailed Cust. Ledg. Entry");

        // [WHEN] Preview application of payment to invoice
        ApplyUnapplyParameters."Document No." := ApplyingCustLedgerEntry."Document No.";
        ApplyUnapplyParameters."Posting Date" := CustEntryApplyPostedEntries.GetApplicationDate(ApplyingCustLedgerEntry);
        asserterror CustEntryApplyPostedEntries.PreviewApply(ApplyingCustLedgerEntry, ApplyUnapplyParameters);

        // [THEN] Three entries expected in "G/L Posting Preview" page for table "Detailed Customer Ledger Entry"
        // [THEN] Payment Discount Tolerance and two applications (invoice -> payment and payment -> invoice)
        // Verification done in DtldCustLedgEntryPageHandler
        Assert.AreEqual(3, LibraryVariableStorage.DequeueInteger(), '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssembleToOrderReleaseOrderPostingPreview()
    var
        Item: Record Item;
        SalesOrderLine: Record "Sales Line";
        SalesOrderHeader: Record "Sales Header";
        SalesPostYesNo: Codeunit "Sales-Post (Yes/No)";
        GLPostingPreview: TestPage "G/L Posting Preview";
        SupplyType: Option Inventory,Purchase,"Prod. Order";
    begin
        // [FEATURE] [Assemble-to-Order] [Assembly]
        // [SCENARIO 309585] Can't post-preview released Sales Order with ATO Item
        Initialize();

        // [GIVEN] Created an Item with "Assembly Policy"="Assemble-to-Order" and its Assembly List
        LibraryAssembly.CreateItem(Item, Item."Costing Method"::Standard, Item."Replenishment System"::Assembly, '', '');
        Item.Validate("Assembly Policy", Item."Assembly Policy"::"Assemble-to-Order");
        Item.Modify(true);
        LibraryAssembly.CreateAssemblyList(Item."Costing Method", Item."No.", true, 1, 0, 0, 1, '', '');
        LibraryTrees.CreateMixedTree(Item, Item."Replenishment System"::Assembly, Item."Costing Method", 1, 1, 1);
        LibraryTrees.CreateSupply(Item."No.", '', '', WorkDate(), SupplyType::Inventory, 10);

        // [GIVEN] Created and released Sales Order with ATO Item
        LibrarySales.CreateSalesDocumentWithItem(SalesOrderHeader, SalesOrderLine, SalesOrderHeader."Document Type"::Order,
          LibrarySales.CreateCustomerNo(), Item."No.", LibraryRandom.RandInt(10), '', 0D);
        LibrarySales.ReleaseSalesDocument(SalesOrderHeader);
        Commit();

        // [WHEN] Call "Post Preview" from order
        GLPostingPreview.Trap();
        asserterror SalesPostYesNo.Preview(SalesOrderHeader);
        Assert.ExpectedError('');

        // [THEN] Posting preview page opens without errors
        GLPostingPreview.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustLedgerEntryIsClosedInPostingPreview()
    var
        PaymentMethod: Record "Payment Method";
        SalesHeader: Record "Sales Header";
        SalesPostYesNo: Codeunit "Sales-Post (Yes/No)";
        GLPostingPreview: TestPage "G/L Posting Preview";
        CustomerEntriesPreview: TestPage "Cust. Ledg. Entries Preview";
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 328755] Invoice Cust. Ledger Entry is Closed in Posting Preview when Sales Invoice has "Payment Method Code" with Bal. Account No. filled.
        Initialize();

        // [GIVEN] Sales Invoice has "Payment Method Code" with Bal. Account No. filled.
        LibraryInventory.CreatePaymentMethod(PaymentMethod);
        PaymentMethod.Validate("Bal. Account Type", PaymentMethod."Bal. Account Type"::"G/L Account");
        PaymentMethod.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());
        PaymentMethod.Modify(true);
        CreateSalesRecord(SalesHeader, LibraryRandom.RandInt(500), LibraryRandom.RandInt(10), SalesHeader."Document Type"::Invoice);
        SalesHeader.Validate("Payment Method Code", PaymentMethod.Code);
        SalesHeader.Modify(true);
        Commit();

        // [WHEN] Cust. Ledger Entries Preview is opened from Posting Preview of Sales Invoice.
        GLPostingPreview.Trap();
        asserterror SalesPostYesNo.Preview(SalesHeader);
        CustomerEntriesPreview.Trap();
        GLPostingPreview.FILTER.SetFilter("Table ID", Format(DATABASE::"Cust. Ledger Entry"));
        GLPostingPreview.Show.Invoke();

        // [THEN] Cust. Vendor Ledger Entry with "Document Type" = Invoice has Open = False.
        CustomerEntriesPreview.FILTER.SetFilter("Document Type", Format(SalesHeader."Document Type"::Invoice));
        CustomerEntriesPreview.Open.AssertEquals(false);
        CustomerEntriesPreview.OK().Invoke();
        GLPostingPreview.OK().Invoke();
    end;

    [Test]
    procedure PreviewSalesInvoiceWithInvDisc()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoice: TestPage "Sales Invoice";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [FEATURE] [Invoice] [UI]
        // [SCENARIO 379797] Stan can preview posting of Sales Invoice when invoice discount is specified for the invoice
        Initialize();

        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
          '', '', LibraryRandom.RandIntInRange(5, 10), '', WorkDate());
        SalesHeader.Modify(true);
        Commit();

        GLPostingPreview.Trap();

        SalesInvoice.OpenEdit();
        SalesInvoice.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesInvoice.SalesLines."Invoice Discount Amount".SetValue(SalesLine."Line Amount" / 10);
        Commit();
        SalesInvoice.Preview.Invoke();

        GLPostingPreview.Close();
    end;

    [Test]
    procedure PreviewSalesInvoiceWithInvDiscAndPriceInclVAT()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoice: TestPage "Sales Invoice";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [FEATURE] [Invoice] [UI] [Price Including VAT]
        // [SCENARIO 379797] Stan can preview posting of Sales Invoice when invoice discount is specified for the invoice having "Price Including VAT" = TRUE
        Initialize();

        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        SalesHeader.Validate("Prices Including VAT", true);
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandDecInRange(10, 20, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(10, 20, 2));
        SalesLine.Validate("VAT %", LibraryRandom.RandIntInRange(10, 20));
        SalesLine.Modify(true);

        Commit();

        GLPostingPreview.Trap();

        SalesInvoice.OpenEdit();
        SalesInvoice.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesInvoice.SalesLines."Invoice Discount Amount".SetValue(SalesLine."Line Amount" / 10);
        Commit();
        SalesInvoice.Preview.Invoke();

        GLPostingPreview.Close();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatisticsModalPageHandler,VATAmountLinesModalPageHandler')]
    procedure PostSalesOrderAfterUpdatingVATAmtonVATAmtLine()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        VATAmount: Decimal;
    begin
        // [FEATURE] [VAT Difference] [UI] [Statistics] [Order]
        // [SCENARIO] System can post Sales Order with zero amount line and with the specified VAT difference.

        // [GIVEN]
        Initialize();
        LibrarySales.SetAllowVATDifference(true);
        LibraryERM.SetMaxVATDifferenceAllowed(LibraryRandom.RandDecInRange(5, 10, 2));
        LibrarySales.CreateCustomer(Customer);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(
          SalesLine[1], SalesHeader, SalesLine[1].Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandDecInRange(10, 20, 2));
        SalesLine[1].Validate("Unit Price", LibraryRandom.RandDecInRange(10, 20, 2));
        SalesLine[1].Validate("VAT %", LibraryRandom.RandIntInRange(10, 20));
        SalesLine[1].Modify(true);

        LibrarySales.CreateSalesLine(
          SalesLine[2], SalesHeader, SalesLine[2].Type::Item, SalesLine[1]."No.", -(SalesLine[1].Quantity + 1));
        SalesLine[2].Validate("Unit Price", SalesLine[1]."Unit Price");
        SalesLine[1].Validate("VAT %", SalesLine[1]."VAT %");
        SalesLine[2].Validate("Qty. to Ship", 0);
        SalesLine[2].Modify(true);

        VATAmount := Round((SalesLine[1].Amount * SalesLine[1]."VAT %" / 100) + LibraryRandom.RandDecInRange(2, 4, 2), 2);
        LibraryVariableStorage.Enqueue(VATAmount);
        OpenSalesOrderStatisticsPage(SalesHeader."No.");

        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        VATPostingSetup.Get(SalesLine[1]."VAT Bus. Posting Group", SalesLine[1]."VAT Prod. Posting Group");
        VerifyAmountOnGLEntry(DocumentNo, VATPostingSetup."Sales VAT Account", -VATAmount);
    end;
#endif
    [Test]
    [HandlerFunctions('SalesOrderStatisticsPageHandler,VATAmountLinesPageHandler')]
    procedure PostSalesOrderAfterUpdatingVATAmtonVATAmtLineNM()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        VATAmount: Decimal;
    begin
        // [FEATURE] [VAT Difference] [UI] [Statistics] [Order]
        // [SCENARIO] System can post Sales Order with zero amount line and with the specified VAT difference.

        // [GIVEN]
        Initialize();
        LibrarySales.SetAllowVATDifference(true);
        LibraryERM.SetMaxVATDifferenceAllowed(LibraryRandom.RandDecInRange(5, 10, 2));
        LibrarySales.CreateCustomer(Customer);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(
          SalesLine[1], SalesHeader, SalesLine[1].Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandDecInRange(10, 20, 2));
        SalesLine[1].Validate("Unit Price", LibraryRandom.RandDecInRange(10, 20, 2));
        SalesLine[1].Validate("VAT %", LibraryRandom.RandIntInRange(10, 20));
        SalesLine[1].Modify(true);

        LibrarySales.CreateSalesLine(
          SalesLine[2], SalesHeader, SalesLine[2].Type::Item, SalesLine[1]."No.", -(SalesLine[1].Quantity + 1));
        SalesLine[2].Validate("Unit Price", SalesLine[1]."Unit Price");
        SalesLine[1].Validate("VAT %", SalesLine[1]."VAT %");
        SalesLine[2].Validate("Qty. to Ship", 0);
        SalesLine[2].Modify(true);

        VATAmount := Round((SalesLine[1].Amount * SalesLine[1]."VAT %" / 100) + LibraryRandom.RandDecInRange(2, 4, 2), 2);
        LibraryVariableStorage.Enqueue(VATAmount);
        OpenSalesOrderStatisticsPageNM(SalesHeader."No.");

        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        VATPostingSetup.Get(SalesLine[1]."VAT Bus. Posting Group", SalesLine[1]."VAT Prod. Posting Group");
        VerifyAmountOnGLEntry(DocumentNo, VATPostingSetup."Sales VAT Account", -VATAmount);
    end;

    [Test]
    procedure PreviewSalesInvoiceWithSameInvoiceAndPostingInvoiceNos()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TestSalesPostPreview: Codeunit "Test Sales Post Preview";
        SalesPostYesNo: Codeunit "Sales-Post (Yes/No)";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 406700] "Posting No." on sales header is not populated on preview posting.
        Initialize();
        BindSubscription(TestSalesPostPreview);

        // [GIVEN] Create sales invoice
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
          '', '', LibraryRandom.RandIntInRange(5, 10), '', WorkDate());
        SalesHeader.Modify(true);
        Commit();

        // [WHEN] Run posting preview
        GLPostingPreview.Trap();
        asserterror SalesPostYesNo.Preview(SalesHeader);
        GLPostingPreview.Close();

        // [THEN] Sales Header "Posting No." = <blank>
        Assert.AreEqual('', TestSalesPostPreview.GetSalesHeaderPostingNo(), '');
    end;

    [Test]
    [HandlerFunctions('GetShipmentLinesHandler')]
    procedure PreviewSalesInvoiceCreditMemoWithNegativeShipmentLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ShippedSalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesPostYesNo: Codeunit "Sales-Post (Yes/No)";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        CustomerNo: Code[20];
        ItemNo: Code[20];
        DocumentNo: Code[20];
        UnitPrice: Integer;
        Quantity: Integer;
    begin
        // [SCENARIO 423695] Posting preview for Sales Invoice and Sales Cr. Memo must be success when there is shipment line with negative Quantity.
        Initialize();

        // [GIVEN] Shipped sales order with sales line with negative sales line
        CustomerNo := LibrarySales.CreateCustomerNo();
        ItemNo := LibraryInventory.CreateItemNo();
        UnitPrice := LibraryRandom.RandIntInRange(10, 100);
        Quantity := LibraryRandom.RandIntInRange(1, 10);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item,
            ItemNo, -Quantity);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [GIVEN] Sales Invoice with negative shipped line and positive line
        Clear(SalesHeader);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        Clear(SalesLine);
        ShippedSalesLine."Document Type" := SalesHeader."Document Type"::Invoice;
        ShippedSalesLine."Document No." := SalesHeader."No.";
        LibrarySales.GetShipmentLines(ShippedSalesLine);
        Clear(SalesLine);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item,
            ItemNo, Quantity);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
        Commit();

        // [GIVEN] Posting preview has not failed
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        BindSubscription(SalesPostYesNo);
        GenJnlPostPreview.SetContext(SalesPostYesNo, SalesHeader);
        Assert.IsFalse(GenJnlPostPreview.Run(), 'Preview.Run returned true');
        Assert.IsTrue(GenJnlPostPreview.IsSuccess(), 'Preview has failed');

        // [GIVEN] Post sales invoice
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Create corrective Cr. memo
        Clear(SalesHeader);
        SalesInvoiceHeader.Get(DocumentNo);
        CorrectPostedSalesInvoice.CreateCreditMemoCopyDocument(SalesInvoiceHeader, SalesHeader);
        SalesHeader."Applies-to Doc. No." := '';
        SalesHeader.Modify();
        Commit();

        // [WHEN] Run Posting preview for Cr. memo
        Clear(ErrorMessageMgt);
        Clear(GenJnlPostPreview);
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        Clear(SalesPostYesNo);
        GenJnlPostPreview.SetContext(SalesPostYesNo, SalesHeader);
        Assert.IsFalse(GenJnlPostPreview.Run(), 'Preview.Run returned true');

        // [THEN] Posting preview has not failed
        Assert.IsTrue(GenJnlPostPreview.IsSuccess(), 'Preview has failed');
    end;

    [Test]
    procedure ShippingNoOnSalesOrderIsNotAssignedOnPostingPreview()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPostYesNo: Codeunit "Sales-Post (Yes/No)";
        TestSalesPostPreview: Codeunit "Test Sales Post Preview";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [SCENARIO 581285] Shipping No. on Sales Order is not assigned during Posting Preview.
        Initialize();

        BindSubscription(TestSalesPostPreview);

        // [GIVEN] Sales Order with Shipping No. = ''.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '',
          LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10), '', WorkDate());
        SalesHeader.Validate("Shipping No.", '');
        SalesHeader.Modify(true);
        Commit();

        // [WHEN] Run posting preview.
        GLPostingPreview.Trap();
        asserterror SalesPostYesNo.Preview(SalesHeader);
        GLPostingPreview.Close();

        // [THEN] Sales Header "Shipping No." remains ''.
        Assert.AreEqual('', TestSalesPostPreview.GetDocumentNos().Get('Shipping No.'), '');

        UnBindSubscription(TestSalesPostPreview);
    end;

    [Test]
    procedure PostingNoOnSalesOrderIsNotAssignedOnPostingPreview()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPostYesNo: Codeunit "Sales-Post (Yes/No)";
        TestSalesPostPreview: Codeunit "Test Sales Post Preview";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [SCENARIO 581285] Posting No. on Sales Order is not assigned during Posting Preview.
        Initialize();

        BindSubscription(TestSalesPostPreview);

        // [GIVEN] Sales Order with Posting No. = ''.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '',
          LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10), '', WorkDate());
        SalesHeader.Validate("Posting No.", '');
        SalesHeader.Modify(true);
        Commit();

        // [WHEN] Run posting preview.
        GLPostingPreview.Trap();
        asserterror SalesPostYesNo.Preview(SalesHeader);
        GLPostingPreview.Close();

        // [THEN] Sales Header "Posting No." = ''.
        Assert.AreEqual('', TestSalesPostPreview.GetDocumentNos().Get('Posting No.'), '');

        UnBindSubscription(TestSalesPostPreview);
    end;

    [Test]
    procedure PostingNoOnSalesInvoiceIsNotAssignedOnPostingPreview()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPostYesNo: Codeunit "Sales-Post (Yes/No)";
        TestSalesPostPreview: Codeunit "Test Sales Post Preview";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [SCENARIO 581285] Posting No. on Sales Invoice is not assigned during Posting Preview.
        Initialize();

        BindSubscription(TestSalesPostPreview);

        // [GIVEN] Sales Invoice with Posting No. = ''.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, '',
          LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10), '', WorkDate());
        SalesHeader.Validate("Posting No.", '');
        SalesHeader.Modify(true);
        Commit();

        // [WHEN] Run posting preview.
        GLPostingPreview.Trap();
        asserterror SalesPostYesNo.Preview(SalesHeader);
        GLPostingPreview.Close();

        // [THEN] Sales Header "Posting No." = ''.
        Assert.AreEqual('', TestSalesPostPreview.GetDocumentNos().Get('Posting No.'), '');

        UnBindSubscription(TestSalesPostPreview);
    end;

    [Test]
    procedure PostingNoOnSalesCreditMemoIsNotAssignedOnPostingPreview()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPostYesNo: Codeunit "Sales-Post (Yes/No)";
        TestSalesPostPreview: Codeunit "Test Sales Post Preview";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [SCENARIO 581285] Posting No. on Sales Credit Memo is not assigned during Posting Preview.
        Initialize();

        BindSubscription(TestSalesPostPreview);

        // [GIVEN] Sales Credit Memo with Posting No. = ''.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::"Credit Memo", '',
          LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10), '', WorkDate());
        SalesHeader.Validate("Posting No.", '');
        SalesHeader.Modify(true);
        Commit();

        // [WHEN] Run posting preview.
        GLPostingPreview.Trap();
        asserterror SalesPostYesNo.Preview(SalesHeader);
        GLPostingPreview.Close();

        // [THEN] Sales Header "Posting No." = ''.
        Assert.AreEqual('', TestSalesPostPreview.GetDocumentNos().Get('Posting No.'), '');

        UnBindSubscription(TestSalesPostPreview);
    end;

    [Test]
    procedure ReturnReceiptNoOnSalesReturnOrderIsNotAssignedOnPostingPreview()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPostYesNo: Codeunit "Sales-Post (Yes/No)";
        TestSalesPostPreview: Codeunit "Test Sales Post Preview";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [SCENARIO 581285] Return Receipt No. on Sales Return Order is not assigned during Posting Preview.
        Initialize();

        BindSubscription(TestSalesPostPreview);

        // [GIVEN] Sales Return Order with Return Receipt No. = ''.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", '',
          LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10), '', WorkDate());
        SalesHeader.Validate("Return Receipt No.", '');
        SalesHeader.Modify(true);
        Commit();

        // [WHEN] Run posting preview.
        GLPostingPreview.Trap();
        asserterror SalesPostYesNo.Preview(SalesHeader);
        GLPostingPreview.Close();

        // [THEN] Sales Header "Return Receipt No." = ''.
        Assert.AreEqual('', TestSalesPostPreview.GetDocumentNos().Get('Return Receipt No.'), '');

        UnBindSubscription(TestSalesPostPreview);
    end;

    [Test]
    procedure PostedShipmentNoStartsWithAsterisksOnPostingPreview()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPostYesNo: Codeunit "Sales-Post (Yes/No)";
        TestSalesPostPreview: Codeunit "Test Sales Post Preview";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [SCENARIO 581285] Posted Shipment No. starts with '***' during Posting Preview.
        Initialize();

        BindSubscription(TestSalesPostPreview);

        // [GIVEN] Sales Order.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '',
          LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10), '', WorkDate());
        Commit();

        // [WHEN] Run posting preview.
        GLPostingPreview.Trap();
        asserterror SalesPostYesNo.Preview(SalesHeader);
        GLPostingPreview.Close();

        // [THEN] Posted Shipment No. starts with '***'.
        Assert.IsTrue(TestSalesPostPreview.GetDocumentNos().Get('Posted Shipment No.').StartsWith('***'), '');

        UnBindSubscription(TestSalesPostPreview);
    end;

    [Test]
    procedure PostedInvoiceNoStartsWithAsterisksOnPostingPreview()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPostYesNo: Codeunit "Sales-Post (Yes/No)";
        TestSalesPostPreview: Codeunit "Test Sales Post Preview";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [SCENARIO 581285] Posted Invoice No. starts with '***' during Posting Preview.
        Initialize();

        BindSubscription(TestSalesPostPreview);

        // [GIVEN] Sales Invoice.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, '',
          LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10), '', WorkDate());
        Commit();

        // [WHEN] Run posting preview.
        GLPostingPreview.Trap();
        asserterror SalesPostYesNo.Preview(SalesHeader);
        GLPostingPreview.Close();

        // [THEN] Posted Invoice No. starts with '***'.
        Assert.IsTrue(TestSalesPostPreview.GetDocumentNos().Get('Posted Invoice No.').StartsWith('***'), '');

        UnBindSubscription(TestSalesPostPreview);
    end;

    [Test]
    procedure PostedCrMemoNoStartsWithAsterisksOnPostingPreview()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPostYesNo: Codeunit "Sales-Post (Yes/No)";
        TestSalesPostPreview: Codeunit "Test Sales Post Preview";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [SCENARIO 581285] Posted Cr.Memo No. starts with '***' during Posting Preview.
        Initialize();

        BindSubscription(TestSalesPostPreview);

        // [GIVEN] Sales Credit Memo.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::"Credit Memo", '',
          LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10), '', WorkDate());
        Commit();

        // [WHEN] Run posting preview.
        GLPostingPreview.Trap();
        asserterror SalesPostYesNo.Preview(SalesHeader);
        GLPostingPreview.Close();

        // [THEN] Posted Cr.Memo No. starts with '***'.
        Assert.IsTrue(TestSalesPostPreview.GetDocumentNos().Get('Posted Cr.Memo No.').StartsWith('***'), '');

        UnBindSubscription(TestSalesPostPreview);
    end;

    [Test]
    procedure PostedReturnReceiptNoStartsWithAsterisksOnPostingPreview()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPostYesNo: Codeunit "Sales-Post (Yes/No)";
        TestSalesPostPreview: Codeunit "Test Sales Post Preview";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [SCENARIO 581285] Posted Return Receipt No. starts with '***' during Posting Preview.
        Initialize();

        BindSubscription(TestSalesPostPreview);

        // [GIVEN] Sales Return Order.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", '',
          LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10), '', WorkDate());
        Commit();

        // [WHEN] Run posting preview.
        GLPostingPreview.Trap();
        asserterror SalesPostYesNo.Preview(SalesHeader);
        GLPostingPreview.Close();

        // [THEN] Posted Return Receipt No. starts with '***'.
        Assert.IsTrue(TestSalesPostPreview.GetDocumentNos().Get('Posted Return Receipt No.').StartsWith('***'), '');

        UnBindSubscription(TestSalesPostPreview);
    end;

    [Test]
    procedure PreviewPostingTokInPostingNoFieldsIsReset()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPostYesNo: Codeunit "Sales-Post (Yes/No)";
        TestSalesPostPreview: Codeunit "Test Sales Post Preview";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [SCENARIO 581285] Preview Posting Token in Shipping No., Posting No., Return Receipt No. fields is reset and not transferred to Last Shipping No., Last Posting No., and Last Return Receipt No. during Posting Preview.
        Initialize();

        BindSubscription(TestSalesPostPreview);

        // [GIVEN] Sales Order.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '',
          LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10), '', WorkDate());
        SalesHeader."Shipping No." := '***123456';
        SalesHeader."Posting No." := '***234567';
        SalesHeader."Return Receipt No." := '***345678';
        SalesHeader.Modify(true);
        Commit();

        // [WHEN] Run posting preview.
        GLPostingPreview.Trap();
        asserterror SalesPostYesNo.Preview(SalesHeader);
        GLPostingPreview.Close();

        // [THEN] Preview Posting Token in fields is reset.
        Assert.AreEqual('', TestSalesPostPreview.GetDocumentNos().Get('Shipping No.'), '');
        Assert.AreEqual('', TestSalesPostPreview.GetDocumentNos().Get('Posting No.'), '');
        Assert.AreEqual('', TestSalesPostPreview.GetDocumentNos().Get('Return Receipt No.'), '');

        // [AND] Last Shipping No., Last Posting No., and Last Return Receipt No. are not set.
        Assert.AreEqual('', TestSalesPostPreview.GetDocumentNos().Get('Last Shipping No.'), '');
        Assert.AreEqual('', TestSalesPostPreview.GetDocumentNos().Get('Last Posting No.'), '');
        Assert.AreEqual('', TestSalesPostPreview.GetDocumentNos().Get('Last Return Receipt No.'), '');

        UnBindSubscription(TestSalesPostPreview);
    end;

    local procedure Initialize()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Test Sales Post Preview");
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Test Sales Post Preview");
        IsInitialized := true;

        LibraryERMCountryData.UpdatePrepaymentAccounts();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Return Order Nos.", LibraryERM.CreateNoSeriesCode());
        SalesReceivablesSetup.Validate("Posted Return Receipt Nos.", LibraryERM.CreateNoSeriesCode());
        SalesReceivablesSetup.Modify(true);

        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        LibrarySetupStorage.SaveSalesSetup();
        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");
        LibrarySetupStorage.SaveGeneralLedgerSetup();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Test Sales Post Preview");
    end;

    local procedure CreateSalesRecord(var SalesHeader: Record "Sales Header"; ItemCost: Decimal; Quantity: Decimal; DocumentType: Enum "Sales Document Type")
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        RecordExportBuffer: Record "Record Export Buffer";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, Customer."No.");

        VATPostingSetup.SetRange("VAT Bus. Posting Group", Customer."VAT Bus. Posting Group");
        VATPostingSetup.SetRange("VAT Prod. Posting Group", Item."VAT Prod. Posting Group");
        if not VATPostingSetup.FindFirst() then
            LibraryERM.CreateVATPostingSetup(VATPostingSetup, Customer."VAT Bus. Posting Group", Item."VAT Prod. Posting Group");

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Quantity);
        SalesLine."Unit Price" := ItemCost;
        SalesLine."Line Amount" := Quantity * SalesLine."Unit Price";
        SalesLine."Amount Including VAT" := SalesLine."Line Amount";
        SalesLine.Modify();

        RecordExportBuffer.DeleteAll();
        RecordExportBuffer.Init();
        RecordExportBuffer.RecordID := SalesHeader.RecordId;
        RecordExportBuffer.Insert();

        Commit();
    end;

    local procedure CreateAndPostItemJournalLine(ItemNo: Code[20]; Quantity: Decimal)
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        SelectItemJournalBatch(ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::Purchase, ItemNo, Quantity);
        ItemJournalLine.Validate("Unit Amount", LibraryRandom.RandDecInRange(10, 100, 2));
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateItemWithFIFO(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", Item."Costing Method"::FIFO);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure FindEntriesAndSetAppliesToID(var ApplyingCustLedgerEntry: Record "Cust. Ledger Entry"; var CustLedgerEntry: Record "Cust. Ledger Entry"; InvNo: Code[20]; PmtNo: Code[20])
    begin
        LibraryERM.FindCustomerLedgerEntry(
          ApplyingCustLedgerEntry, ApplyingCustLedgerEntry."Document Type"::Payment, PmtNo);
        ApplyingCustLedgerEntry.CalcFields("Remaining Amount");
        LibraryERM.SetApplyCustomerEntry(ApplyingCustLedgerEntry, ApplyingCustLedgerEntry."Remaining Amount");
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, InvNo);
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    local procedure OpenSalesOrderStatisticsPage(OrderNo: Code[20])
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", OrderNo);
        SalesOrder.Statistics.Invoke();
        SalesOrder.Close();
    end;
#endif
    local procedure OpenSalesOrderStatisticsPageNM(OrderNo: Code[20])
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", OrderNo);
        SalesOrder.SalesOrderStatistics.Invoke();
        SalesOrder.Close();
    end;

    local procedure PostPartialQuantity(var SalesHeader: Record "Sales Header"; Invoice: Boolean)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        SalesLine.Validate("Qty. to Ship", 1); // specific value needed for test
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, Invoice);
    end;

    local procedure PostPaidInvWithPmtDiscTol(var InvNo: Code[20]; var PmtNo: Code[20])
    var
        PaymentTerms: Record "Payment Terms";
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        PmtDiscTol: Decimal;
        InvoiceAmount: Decimal;
        PmtAmount: Decimal;
    begin
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, false);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Terms Code", PaymentTerms.Code);
        Customer.Modify(true);

        PmtDiscTol := PaymentTerms."Discount %" / LibraryRandom.RandDec(3, 5);
        InvoiceAmount := LibraryRandom.RandDec(100, 2);
        PmtAmount := Round(InvoiceAmount * PmtDiscTol / 100 - InvoiceAmount);

        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, Customer."No.", InvoiceAmount);
        InvNo := GenJournalLine."Document No.";
        LibraryJournals.CreateGenJournalLine(
          GenJournalLine, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, Customer."No.",
          GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), PmtAmount);
        GenJournalLine.Validate("Posting Date", CalcDate(PaymentTerms."Discount Date Calculation", WorkDate()) + 1); // date after "Pmt. Disc. Posting Date"
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        PmtNo := GenJournalLine."Document No.";
    end;

    local procedure SelectItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(
          ItemJournalBatch, ItemJournalTemplate.Type::Item, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure ThrowErrorSalesHeaderOnBeforeDeleteEvent(var Rec: Record "Sales Header"; RunTrigger: Boolean)
    var
        RecordExportBuffer: Record "Record Export Buffer";
        RecRef: RecordRef;
    begin
        Assert.RecordIsNotEmpty(RecordExportBuffer);
        RecRef.GetTable(Rec);
        if not RecRef.IsTemporary then begin
            RecordExportBuffer.SetRange(RecordID, Rec.RecordId);
            Assert.RecordIsEmpty(RecordExportBuffer);
        end;
    end;

    local procedure VerifyAmountOnGLEntry(DocumentNo: Code[20]; GLAccountNo: Code[20]; ExpectedAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();

        GLEntry.TestField(Amount, ExpectedAmount);
    end;

    local procedure GLPostingPreviewHandler(var GLPostingPreview: TestPage "G/L Posting Preview")
    var
        GLEntry: Record "G/L Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        VATEntry: Record "VAT Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        ValueEntry: Record "Value Entry";
    begin
        GLPostingPreview.First();
        VerifyGLPostingPreviewLine(GLPostingPreview, GLEntry.TableCaption(), 3);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, CustLedgerEntry.TableCaption(), 1);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, ItemLedgerEntry.TableCaption(), 1);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, VATEntry.TableCaption(), 1);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, DetailedCustLedgEntry.TableCaption(), 1);

        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, ValueEntry.TableCaption(), 1);
    end;

    local procedure CustEntriesPreviewHandler(var CustomerEntriesPreview: TestPage "Cust. Ledg. Entries Preview"; EntryType: Enum "Gen. Journal Document Type")
    begin
        CustomerEntriesPreview.First();
        Assert.AreEqual(EntryType, CustomerEntriesPreview."Document Type".AsInteger(), 'Unexpected DocumentType in CustomerEntriesPreview');
        CustomerEntriesPreview.OK().Invoke();
    end;

    local procedure VerifyGLPostingPreviewLine(GLPostingPreview: TestPage "G/L Posting Preview"; TableName: Text; ExpectedEntryCount: Integer)
    begin
        Assert.AreEqual(TableName, GLPostingPreview."Table Name".Value, StrSubstNo('A record for Table Name %1 was not found.', TableName));
        Assert.AreEqual(ExpectedEntryCount, GLPostingPreview."No. of Records".AsInteger(),
          StrSubstNo('Table Name %1 Unexpected number of records.', TableName));
    end;

    procedure GetSalesHeaderPostingNo(): Code[20]
    begin
        exit(SalesHeaderPostingNo);
    end;

    procedure GetDocumentNos(): Dictionary of [Text, Text]
    begin
        exit(DocumentNos);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterUpdatePostingNos', '', false, false)]
    local procedure OnAfterUpdatePostingNos(var SalesHeader: Record "Sales Header"; CommitIsSuppressed: Boolean)
    begin
        SalesHeaderPostingNo := SalesHeader."Posting No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterFinalizePostingOnBeforeCommit', '', false, false)]
    local procedure CheckSalesDocumentsBeforeCommit(var SalesHeader: Record "Sales Header";
                                                    var SalesShipmentHeader: Record "Sales Shipment Header";
                                                    var SalesInvoiceHeader: Record "Sales Invoice Header";
                                                    var SalesCrMemoHeader: Record "Sales Cr.Memo Header";
                                                    var ReturnReceiptHeader: Record "Return Receipt Header")
    begin
        Clear(DocumentNos);
        DocumentNos.Add('Shipping No.', SalesHeader."Shipping No.");
        DocumentNos.Add('Posting No.', SalesHeader."Posting No.");
        DocumentNos.Add('Return Receipt No.', SalesHeader."Return Receipt No.");
        DocumentNos.Add('Last Shipping No.', SalesHeader."Last Shipping No.");
        DocumentNos.Add('Last Posting No.', SalesHeader."Last Posting No.");
        DocumentNos.Add('Last Return Receipt No.', SalesHeader."Last Return Receipt No.");
        DocumentNos.Add('Posted Shipment No.', SalesShipmentHeader."No.");
        DocumentNos.Add('Posted Invoice No.', SalesInvoiceHeader."No.");
        DocumentNos.Add('Posted Cr.Memo No.', SalesCrMemoHeader."No.");
        DocumentNos.Add('Posted Return Receipt No.', ReturnReceiptHeader."No.");
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure GLPostingPreviewPageHandler(var GLPostingPreview: TestPage "G/L Posting Preview")
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DetCustLedgEntrPreview: TestPage "Det. Cust. Ledg. Entr. Preview";
    begin
        GLPostingPreview.FILTER.SetFilter("Table ID", Format(LibraryVariableStorage.DequeueInteger()));
        LibraryVariableStorage.Enqueue(GLPostingPreview."No. of Records".Value);
        DetCustLedgEntrPreview.Trap();
        GLPostingPreview."No. of Records".DrillDown();
        DetCustLedgEntrPreview.FILTER.SetFilter("Entry Type", Format(DetailedCustLedgEntry."Entry Type"::"Payment Discount Tolerance"));
        Assert.IsTrue(
          DetCustLedgEntrPreview.Amount.AsDecimal() <> 0, 'Payment Discount Tolerance does not exist');
        DetCustLedgEntrPreview.FILTER.SetFilter("Entry Type", Format(DetailedCustLedgEntry."Entry Type"::Application));
        Assert.IsTrue(
          DetCustLedgEntrPreview.Amount.AsDecimal() <> 0, 'Application does not exist');
        DetCustLedgEntrPreview.Next();
        Assert.IsTrue(
          DetCustLedgEntrPreview.Amount.AsDecimal() <> 0, 'Application does not exist');
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [ModalPageHandler]
    procedure SalesOrderStatisticsModalPageHandler(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    begin
        SalesOrderStatistics.NoOfVATLines_Invoicing.DrillDown();
    end;

    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [ModalPageHandler]
    procedure VATAmountLinesModalPageHandler(var VATAmountLines: TestPage "VAT Amount Lines")
    begin
        VATAmountLines."VAT Amount".SetValue(LibraryVariableStorage.DequeueDecimal());
        VATAmountLines.OK().Invoke();
    end;
#endif
    [PageHandler]
    procedure SalesOrderStatisticsPageHandler(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    begin
        SalesOrderStatistics.NoOfVATLines_Invoicing.DrillDown();
    end;

    [ModalPageHandler]
    procedure VATAmountLinesPageHandler(var VATAmountLines: TestPage "VAT Amount Lines")
    begin
        VATAmountLines."VAT Amount".SetValue(LibraryVariableStorage.DequeueDecimal());
        VATAmountLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetShipmentLinesHandler(var GetShipmentLines: TestPage "Get Shipment Lines")
    begin
        GetShipmentLines.OK().Invoke();
    end;
}

