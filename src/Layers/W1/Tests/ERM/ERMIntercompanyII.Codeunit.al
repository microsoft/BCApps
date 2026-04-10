codeunit 134152 "ERM Intercompany II"
{
    Permissions = TableData "Cust. Ledger Entry" = rimd,
                  TableData "Vendor Ledger Entry" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Intercompany]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryDimension: Codeunit "Library - Dimension";
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        APIMockEvents: Codeunit "API Mock Events";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        ValidationErr: Label '%1 must be %2 in %3.', Comment = '%1 = field name, %2 = field value, %3 = table name';
        SameICPartnerErr: Label 'The IC Partner Code %1 has been assigned to Customer %2.', Comment = '%1 = IC partner code, %2 = customer no.';
        BlockedErr: Label 'Vendor %1 is linked to a blocked IC Partner.', Comment = '%1 = Vendor no.';
        ICCustomerBlockedAllErr: Label 'You cannot create this type of document when Customer %1 is blocked', Comment = '%1 = Customer no.';
        DatesErr: Label '%1 of %2 must be equal to %3 of %4', Comment = '%1 = table name, %2 = date field, %3 = table name, %4 = date field';
        TableFieldErr: Label 'Wrong table field value: table "%1", field "%2".', Comment = '%1 = table name, %2 = field name';
        ReservationEntryNotExistErr: Label 'Reservation Entry doen''s exist.';
        NoGLEntryWithICPartnerCodeErr: Label 'G/L Entry with IC Partner Code is not created.';
        NoItemForCommonItemErr: Label 'There is no Item related to Common Item No. %1', Comment = '%1 = Common Item No value';
        WrongCompanyErr: Label 'The selected xml file contains data sent to IC Partner %1. Current company''s IC Partner Code is %2.', Comment = '%1 = IC partner code, %2 = IC partner code';
        ICPartnerCodeModifyErr: Label 'You cannot change the contents of the %1 field because this %2 has one or more open ledger entries.', Comment = '%1 = Field caption, %2 = Table caption';
        ItemTrackingDoesNotMatchDocLineErr: Label 'Item tracking does not match document line.';
        PostedInvoiceDuplicateQst: Label 'Posted invoice %1 already exists for order %2. To avoid duplicate postings, do not post order %2.\Do you still want to post order %2?', Comment = '%1 = Invoice No., %2 = Order No.';
        PostedInvoiceFromSameTransactionQst: Label 'Posted invoice %1 originates from the same IC transaction as invoice %2. To avoid duplicate postings, do not post invoice %2.\Do you still want to post invoice %2?', Comment = '%1 and %2 = Invoice No.';
        GLAccountDescriptionLbl: Label 'Custom GL Account description', Locked = true;
        ItemDescriptionLbl: Label 'Custom item description', Locked = true;
        DateLbl: Label '<%1D>', Locked = true;
        PostingDateErr: Label '%1 of %2 must be equal to blank', Comment = '%1 = date field, %2 = table name';

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ExportImportICTransaction()
    var
        ICInboxTransaction: Record "IC Inbox Transaction";
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        CustomerNo: Code[20];
        VendorNo: Code[20];
        ICPartnerCode: array[2] of Code[20];
        FileName: Text;
    begin
        // [FEATURE] [Import Transaction File]
        // [SCENARIO 375225] IC Transaction file should be imported when IC Partner Codes of two companies are different
        Initialize();
        BindSubscription(TestClientTypeSubscriber);
        TestClientTypeSubscriber.SetClientType(ClientType::Windows);

        // [GIVEN] Two Companies, where "IC Partner Code" are "A" and "B"
        // [GIVEN] IC Partner "A", where "Inbox Type" is "File Location"
        ICPartnerCode[1] := CreateICPartnerWithInboxTypeFileLocation();
        ICPartnerCode[2] := CreateICPartner();

        // [GIVEN] Company Information "B", where "IC Partner Code" = "B"
        SetCompanyICPartner(ICPartnerCode[2]);

        // [GIVEN] Customer and Vendor, where "IC Partner Code" is "A"
        VendorNo := CreateICVendor(ICPartnerCode[1]);
        CustomerNo := CreateICCustomer(ICPartnerCode[1]);

        LibraryLowerPermissions.SetIntercompanyPostingsEdit();
        LibraryLowerPermissions.AddO365Setup();
        LibraryLowerPermissions.AddPurchDocsPost();
        // [GIVEN] Post Sales Order and Purchase Order
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo, CreateItem());
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibraryLowerPermissions.AddSalesDocsPost();
        CreateSalesDocument(
          SalesHeader, SalesHeader."Document Type"::Order, CustomerNo, CreateItem());
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Send Outbox transactions (Sales and Purchase documents) to IC Partner "A" (save to a file)
        FileName := SendICTransaction(SalesHeader."No." + '|' + PurchaseHeader."No.");

        // [GIVEN] Switch to Company Information "A", where "IC Partner Code" = "A"
        SetCompanyICPartner(ICPartnerCode[1]);
        LibraryLowerPermissions.AddIntercompanyPostingsSetup();
        DeleteICPartner(ICPartnerCode[1]); // There should be no IC Partner for the Company itself

        // [GIVEN] Customer and Vendor, where "IC Partner Code" is "B"
        CreateICCustomer(ICPartnerCode[2]);
        CreateICVendor(ICPartnerCode[2]);

        // [WHEN] Import transaction file from IC Partner "B"
        ImportICTransactionFromFile(FileName);

        // [THEN] IC Inbox contains 2 transactions from IC Partner "B": Sales Document and Purchase Document.
        ICInboxTransaction.Reset();
        ICInboxTransaction.SetRange("IC Partner Code", ICPartnerCode[2]);
        ICInboxTransaction.SetRange("IC Source Type", ICInboxTransaction."IC Source Type"::"Sales Document");
        ICInboxTransaction.FindFirst();
        ICInboxTransaction.TestField("Document No.", PurchaseHeader."No.");
        ICInboxTransaction.SetRange("IC Source Type", ICInboxTransaction."IC Source Type"::"Purchase Document");
        ICInboxTransaction.FindFirst();
        ICInboxTransaction.TestField("Document No.", SalesHeader."No.");

        UnbindSubscription(TestClientTypeSubscriber);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ExportImportICTransactionToSameCompanyError()
    var
        PurchaseHeader: Record "Purchase Header";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        VendorNo: Code[20];
        ICPartnerCode: array[2] of Code[20];
        FileName: Text;
    begin
        // [FEATURE] [Import Transaction File]
        // [SCENARIO 375225] IC Transaction file should not be imported to Company with wrong IC Partner Code
        Initialize();
        BindSubscription(TestClientTypeSubscriber);
        TestClientTypeSubscriber.SetClientType(ClientType::Windows);

        // [GIVEN] IC Partner "A", where "Inbox Type" is "File Location"
        ICPartnerCode[1] := CreateICPartnerWithInboxTypeFileLocation();
        ICPartnerCode[2] := CreateICPartner();

        // [GIVEN] Company, where "IC Partner Code" is "B"
        SetCompanyICPartner(ICPartnerCode[2]);

        // [GIVEN] Vendor, where "IC Partner Code" is "A"
        VendorNo := CreateICVendor(ICPartnerCode[1]);

        LibraryLowerPermissions.SetIntercompanyPostingsEdit();
        LibraryLowerPermissions.AddO365Setup();
        LibraryLowerPermissions.AddPurchDocsPost();
        // [GIVEN] Post Purchase Order
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo, CreateItem());
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Send Outbox transactions (Purchase document) to IC Partner "A" (save to a file)
        FileName := SendICTransaction(PurchaseHeader."No.");

        // [WHEN] Import transaction file from IC Partner "B" to Company with IC Partner "A"
        asserterror ImportICTransactionFromFile(FileName);

        // [THEN] Error message: 'Data Sent to IC Partner "B". Current company's IC Partner Code "A"'
        Assert.ExpectedError(StrSubstNo(WrongCompanyErr, ICPartnerCode[1], ICPartnerCode[2]));

        UnbindSubscription(TestClientTypeSubscriber);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICPartnerUsedByAnotherCustomerError()
    begin
        // Check that error message appears while using same IC Partner Code on two different Customers.
        Initialize();
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddO365Setup();
        ICPartnerForCustomerAndVendorError(CreateICPartner());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SameICPartnerUsedByCustomerAndVendor()
    var
        Customer: Record Customer;
        ICPartnerCode: Code[20];
        CustomerNo: Code[20];
    begin
        // Check that same IC Partner Code can be used by a Customer and Vendor.

        // Setup.
        Initialize();
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddO365Setup();
        ICPartnerCode := CreateICPartner();
        CreateICVendor(ICPartnerCode);

        // Exercise: Create Customer and update same IC Partner Code to it.
        CustomerNo := CreateICCustomer(ICPartnerCode);

        // Verify: Verify that correct IC Partner updated on Customer.
        Customer.Get(CustomerNo);
        Customer.TestField("IC Partner Code", ICPartnerCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SameICPartnerUsedByCustomerAndVendorError()
    var
        ICPartnerCode: Code[20];
    begin
        // Check error message while updating same IC Partner Code on Customer that is already used for a Customer and Vendor.
        Initialize();
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddO365Setup();
        ICPartnerCode := CreateICPartner();
        CreateICVendor(ICPartnerCode);
        ICPartnerForCustomerAndVendorError(ICPartnerCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostICGeneralJournalLineWithAccountTypeAsICPartner()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ICGLAccount: Record "IC G/L Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        // Check IC Outbox Journal Entries after posting IC Journal Line with Account Type as IC Partner and used 1 for sign factor.

        Initialize();
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddO365Setup();
        CreateICGLAccount(ICGLAccount);

        CreateICJournalBatch(GenJournalBatch, GenJournalTemplate.Type::Intercompany);
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::"IC Partner",
          CreateICPartner(), GenJournalLine."Bal. Account Type"::"G/L Account", ICGLAccount."Map-to G/L Acc. No.", ICGLAccount."No.", 1);

        LibraryLowerPermissions.AddJournalsPost();
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();
        PostAndVerifyICGeneralJournalLine(GenJournalLine, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostICGeneralJournalLineWithBalanceAccountTypeAsICPartner()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ICGLAccount: Record "IC G/L Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        // Check IC Outbox Journal Entries after posting IC Journal Line with Bal. Account Type as IC Partner used -1 for sign factor.

        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddIntercompanyPostingsSetup();
        CreateICGLAccount(ICGLAccount);

        CreateICJournalBatch(GenJournalBatch, GenJournalTemplate.Type::Intercompany);
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::"G/L Account",
          ICGLAccount."Map-to G/L Acc. No.", GenJournalLine."Bal. Account Type"::"IC Partner", CreateICPartner(), ICGLAccount."No.", 1);

        LibraryLowerPermissions.AddIntercompanyPostingsEdit();
        LibraryLowerPermissions.AddJournalsPost();
        PostAndVerifyICGeneralJournalLine(GenJournalLine, -1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostGeneralJournalLineWithAccountTypeAsCustomer()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
        CustomerPostingGroup: Record "Customer Posting Group";
        CustomerNo: Code[20];
    begin
        // Check General Ledger Entries after posting a General Journal Line with Account type as Customer.

        // Setup: Create G/L Account, Customer and post an General Journal Line for Customer with IC Partner Code, used blank for IC Partner G/L Account No. and 1 for sign factor.
        Initialize();
        SelectGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateGLAccount(GLAccount);
        CustomerNo := CreateICCustomer(CreateICPartner());

        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::Customer, CustomerNo,
          GenJournalLine."Bal. Account Type"::"G/L Account", GLAccount."No.", '', 1);
        CustomerPostingGroup.Get(GenJournalLine."Posting Group");
        LibraryLowerPermissions.SetJournalsPost();
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();

        // Exercise: Post IC Journal Line.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify GL Entry.
        VerifyGLEntry(
          GenJournalLine."Document No.", GenJournalLine."IC Partner Code", GenJournalLine."Bal. Account No.", -GenJournalLine.Amount);
        VerifyGLEntry(
          GenJournalLine."Document No.", GenJournalLine."IC Partner Code", CustomerPostingGroup."Receivables Account",
          GenJournalLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostGeneralJournalLineWithBalanceAccountTypeAsCustomer()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
        CustomerPostingGroup: Record "Customer Posting Group";
        CustomerNo: Code[20];
    begin
        // Check General Ledger Entries after posting a General Journal Line with Bal. Account type as Customer.

        // Setup: Create G/L Account, Customer and post an General Journal Line for Customer with IC Partner Code, used blank for IC Partner G/L Account No. and -1 for sign factor.
        Initialize();
        SelectGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateGLAccount(GLAccount);
        CustomerNo := CreateICCustomer(CreateICPartner());

        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::"G/L Account", GLAccount."No.",
          GenJournalLine."Bal. Account Type"::Customer, CustomerNo, '', -1);
        CustomerPostingGroup.Get(GenJournalLine."Posting Group");
        LibraryLowerPermissions.SetJournalsPost();
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();

        // Exercise: Post IC Journal Line.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify GL Entry.
        VerifyGLEntry(GenJournalLine."Document No.", GenJournalLine."IC Partner Code", GenJournalLine."Account No.", GenJournalLine.Amount);
        VerifyGLEntry(
          GenJournalLine."Document No.", GenJournalLine."IC Partner Code", CustomerPostingGroup."Receivables Account",
          -GenJournalLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostGeneralJournalLineWithAccountTypeAsVendor()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
        VendorPostingGroup: Record "Vendor Posting Group";
        VendorNo: Code[20];
    begin
        // Check General Ledger Entries after posting a General Journal Line with Account Type Vendor.

        // Setup: Create G/L Account, Vendor and post an General Journal Line for Vendor with IC Partner Code, used blank for IC Partner G/L Account No. and -1 for sign factor.
        Initialize();
        SelectGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateGLAccount(GLAccount);
        VendorNo := CreateICVendor(CreateICPartner());

        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::Vendor, VendorNo,
          GenJournalLine."Bal. Account Type"::"G/L Account", GLAccount."No.", '', -1);
        VendorPostingGroup.Get(GenJournalLine."Posting Group");
        LibraryLowerPermissions.SetJournalsPost();
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();

        // Exercise: Post IC Journal Line.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify GL Entry.
        VerifyGLEntry(
          GenJournalLine."Document No.", GenJournalLine."IC Partner Code", GenJournalLine."Bal. Account No.", -GenJournalLine.Amount);
        VerifyGLEntry(
          GenJournalLine."Document No.", GenJournalLine."IC Partner Code", VendorPostingGroup."Payables Account", GenJournalLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostGeneralJournalLineWithBalanceAccountTypeAsVendor()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
        VendorPostingGroup: Record "Vendor Posting Group";
        VendorNo: Code[20];
    begin
        // Check General Ledger Entries after posting a General Journal Line with Bal. Account type as Vendor.

        // Setup: Create G/L Account, Vendor and post an General Journal Line for Vendor with IC Partner Code, used blank for IC Partner G/L Account No. and 1 for sign factor.
        Initialize();
        SelectGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateGLAccount(GLAccount);
        VendorNo := CreateICVendor(CreateICPartner());

        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::"G/L Account", GLAccount."No.",
          GenJournalLine."Bal. Account Type"::Vendor, VendorNo, '', 1);
        VendorPostingGroup.Get(GenJournalLine."Posting Group");
        LibraryLowerPermissions.SetJournalsPost();
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();

        // Exercise: Post IC Journal Line.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify GL Entry.
        VerifyGLEntry(GenJournalLine."Document No.", GenJournalLine."IC Partner Code", GenJournalLine."Account No.", GenJournalLine.Amount);
        VerifyGLEntry(
          GenJournalLine."Document No.", GenJournalLine."IC Partner Code", VendorPostingGroup."Payables Account", -GenJournalLine.Amount);
    end;

    [Test]
    [HandlerFunctions('ICOutboxSalesDocHandler')]
    [Scope('OnPrem')]
    procedure SalesLineExistenceAfterRenamingICPartnerCode()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICPartnerCode: Code[20];
        ItemNo: Code[20];
    begin
        // Check Sales Line existence in IC Outbox Transaction after renaming IC Partner Code.

        // Setup: Create Item, IC Customer, create and post Sales Order for Customer with random Quantity.
        Initialize();
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddO365Setup();
        ICPartnerCode := CreateICPartner();
        ItemNo := LibraryInventory.CreateItem(Item);  // Assigning value to global variable.
        LibraryVariableStorage.Enqueue(ItemNo);
        LibraryLowerPermissions.AddSalesDocsPost();
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateICCustomer(ICPartnerCode));
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandInt(10));
        LibraryVariableStorage.Enqueue(SalesLine.Quantity);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise: Rename IC Partner using Random Integer value.
        LibraryVariableStorage.Enqueue(RenameICPartner(ICPartnerCode));

        // Verify: Verify Sales Line in IC Outbox Transactions. Verification done in Page Handler.
        FindICOutboxTransaction(
          ICOutboxTransaction, SalesHeader."No.", ICOutboxTransaction."Document Type"::Order,
          ICOutboxTransaction."IC Source Type"::"Sales Document");
        ICOutboxTransaction.ShowDetails();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorWithUnblockedICPartner()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ICOutboxJnlLine: Record "IC Outbox Jnl. Line";
    begin
        // Check values on the IC Outbox Transaction for unblocked IC Partner and unblocked Vendor.

        // Setup: Create IC General Journal Line.
        Initialize();
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddO365Setup();
        CreateICGeneralJournalLine(GenJournalLine, GenJournalLine."Account Type"::Vendor, CreateICVendor(CreateICPartner()), -1);

        // Exercise.
        LibraryLowerPermissions.SetJournalsPost();
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify values on IC Outbox Transactions.
        VerifyICOutboxJournalLine(
          GenJournalLine."IC Partner Code", ICOutboxJnlLine."Account Type"::Vendor, GenJournalLine."Account No.",
          GenJournalLine."Document No.", GenJournalLine.Amount);

        // Tear Down: Delete newly created batch.
        DeleteGeneralJournalBatch(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICJournalLinePostAfterBlockingICPartner()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ICPartnerCode: Code[20];
    begin
        // Check error while posting IC General Journal Line for Blocked IC Partner and unblocked Vendor.

        // Setup: Create IC General Journal Line and block IC Partner after creating IC General Journal Line.
        Initialize();
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddO365Setup();
        ICPartnerCode := CreateICPartner();
        CreateICGeneralJournalLine(GenJournalLine, GenJournalLine."Account Type"::Vendor, CreateICVendor(ICPartnerCode), -1);
        BlockICPartner(ICPartnerCode);

        // Exercise.
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify Blocked IC Partner error message.
        Assert.ExpectedError(StrSubstNo(BlockedErr, GenJournalLine."Account No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICJournalLineErrorWithBlockedICPartner()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorNo: Code[20];
        ICPartnerCode: Code[20];
    begin
        // Check error while creating IC General Journal Line for Blocked IC Partner and unblocked Vendor.

        // Setup: Create and block IC Partner, create Vendor.
        Initialize();
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddO365Setup();
        ICPartnerCode := CreateICPartner();
        BlockICPartner(ICPartnerCode);
        VendorNo := CreateICVendor(ICPartnerCode);

        // Exercise.
        asserterror CreateICGeneralJournalLine(GenJournalLine, GenJournalLine."Account Type"::Vendor, VendorNo, -1);

        // Verify: Verify Blocked IC Partner error message.
        Assert.ExpectedError(StrSubstNo(BlockedErr, VendorNo));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICJournalLinePostAfterBlockingICGLAccount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ICGlAccount: Record "IC G/L Account";
    begin
        // Check error while posting IC General Journal Line for Blocked IC G/L Account.

        // Setup: Create IC General Journal Line and block the IC G/L Account.
        Initialize();
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddO365Setup();
        CreateICGeneralJournalLine(GenJournalLine, GenJournalLine."Account Type"::"IC Partner", CreateICPartner(), -1);
        BlockICGLAccount(GenJournalLine."IC Account No.");

        // Exercise.
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify IC G/L Account Blocked error message.
        Assert.ExpectedTestFieldError(ICGlAccount.FieldCaption(Blocked), Format(false));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesRetOrderMovedInICOutbox()
    var
        SalesHeader: Record "Sales Header";
        ICOutboxTransaction: Record "IC Outbox Transaction";
    begin
        // Verify Sales Return Order in IC Outbox Transactions after send it for IC with non IC Bill to Customer.
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyCustomerAddressNotificationId());
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyBillToCustomerAddressNotificationId());
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddO365Setup();
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();
        LibraryLowerPermissions.AddSalesDocsPost();
        SalesDocumentMovedInICOutbox(
          SalesHeader."Document Type"::"Return Order", CreateICCustomer(''), ICOutboxTransaction."Document Type"::"Return Order");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesCrMemoMovedInICOutbox()
    var
        SalesHeader: Record "Sales Header";
        ICOutboxTransaction: Record "IC Outbox Transaction";
    begin
        // Verify Sales Credit Memo in IC Outbox Transactions after send it for IC with IC Bill to Customer.
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyBillToCustomerAddressNotificationId());
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyCustomerAddressNotificationId());
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();
        LibraryLowerPermissions.AddSalesDocsPost();
        LibraryLowerPermissions.AddO365Setup();
        SalesDocumentMovedInICOutbox(
          SalesHeader."Document Type"::"Credit Memo", CreateICCustomer(CreateICPartner()),
          ICOutboxTransaction."Document Type"::"Credit Memo");
    end;

    local procedure SalesDocumentMovedInICOutbox(DocumentType: Enum "Sales Document Type"; BillToCustomerNo: Code[20]; DocumentType2: Enum "IC Transaction Document Type")
    var
        SalesHeader: Record "Sales Header";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICPartnerCode: Code[20];
    begin
        // Setup: Create IC Parter, create Sales Document, update Bill-to Customer No. and Send it for IC and post.
        Initialize();
        ICPartnerCode := CreateICPartner();
        CreateSalesDocument(SalesHeader, DocumentType, CreateICCustomer(ICPartnerCode), CreateItem());
        UpdateSalesDocument(SalesHeader, BillToCustomerNo);
        ICInboxOutboxMgt.SendSalesDoc(SalesHeader, false);

        // Exercise.
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // Verify: Verify Sales Document in IC Outbox Transactions.
        FindICOutboxTransaction(ICOutboxTransaction, SalesHeader."No.", DocumentType2, ICOutboxTransaction."IC Source Type"::"Sales Document");
        ICOutboxTransaction.TestField("IC Partner Code", ICPartnerCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOnPostSalesInvWithBlockedICPartner()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Verify error while post Sales Invoice with Customer which have blocked IC Partner.
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddSalesDocsPost();
        LibraryLowerPermissions.AddO365Setup();
        PostSalesDocumentWithBlockedICPartner(SalesHeader."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOnPostSalesRetOrderWithBlockedICPartner()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Verify error while post Sales Return Order with Customer which have blocked IC Partner.
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddO365Setup();
        LibraryLowerPermissions.AddSalesDocsPost();
        PostSalesDocumentWithBlockedICPartner(SalesHeader."Document Type"::"Return Order");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOnPostSalesOrderWithBlockedICPartner()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Verify error while post Sales Order with Customer which have blocked IC Partner.
        LibraryLowerPermissions.SetSalesDocsPost();
        LibraryLowerPermissions.AddIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddO365Setup();
        PostSalesDocumentWithBlockedICPartner(SalesHeader."Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOnPostSalesCrMemoWithBlockedICPartner()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Verify error while post Sales Credit Memo with Customer which have blocked IC Partner.
        LibraryLowerPermissions.SetSalesDocsPost();
        LibraryLowerPermissions.AddO365Setup();
        LibraryLowerPermissions.AddIntercompanyPostingsSetup();
        PostSalesDocumentWithBlockedICPartner(SalesHeader."Document Type"::"Credit Memo");
    end;

    local procedure PostSalesDocumentWithBlockedICPartner(DocumentType: Enum "Sales Document Type")
    var
        SalesHeader: Record "Sales Header";
        ICPartner: Record "IC Partner";
        ICPartnerCode: Code[20];
    begin
        // Setup: Create IC Parter, create Sales Document and block IC Partner.
        Initialize();
        ICPartnerCode := CreateICPartner();
        CreateSalesDocument(SalesHeader, DocumentType, CreateICCustomer(ICPartnerCode), CreateItem());
        BlockICPartner(ICPartnerCode);

        // Exercise.
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify error while post Sales Document with blocked IC Partner.
        Assert.ExpectedTestFieldError(ICPartner.FieldCaption(Blocked), Format(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostICGeneralJournalLineWithBlockedALL()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        ICGLAccount: Record "IC G/L Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        ICPartnerCode: Code[20];
    begin
        // Verify IC Outbox Journal Entries after posting IC Journal Line with Account Type as IC Partner which is attached on Customer and Vendor are Blocked with All.

        Initialize();
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddO365Setup();
        ICPartnerCode := CreateICPartner();
        CreateAndUpdateICCustomer(ICPartnerCode, Customer.Blocked::All);
        CreateAndUpdateICVendor(ICPartnerCode);
        CreateICGLAccount(ICGLAccount);

        CreateICJournalBatch(GenJournalBatch, GenJournalTemplate.Type::Intercompany);
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::"IC Partner",
          ICPartnerCode, GenJournalLine."Bal. Account Type"::"G/L Account", ICGLAccount."Map-to G/L Acc. No.", ICGLAccount."No.", 1);

        LibraryLowerPermissions.SetIntercompanyPostingsEdit();
        LibraryLowerPermissions.AddJournalsPost();
        PostAndVerifyICGeneralJournalLine(GenJournalLine, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostMultiICGeneralJournalLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ICGLAccount: Record "IC G/L Account";
        GLAccount: Record "G/L Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        ICOutboxJnlLine: Record "IC Outbox Jnl. Line";
        ICPartnerCode: Code[20];
        ICAccountNo: Code[20];
    begin
        // Verify IC Outbox Journal Entries after posting Multiple IC Journal Line with Account Type as IC Partner and GL Account with Document Type Invoice and blank respectively.

        // Setup: Create IC Partner, GL Account, IC GL Account, IC Gen. Journal Line with account type GL (Document Type is Invoice) and IC Partner (Document Type is blank).
        Initialize();
        ICPartnerCode := CreateICPartner();
        LibraryERM.CreateGLAccount(GLAccount);
        CreateICGLAccount(ICGLAccount);
        CreateICJournalBatch(GenJournalBatch, GenJournalTemplate.Type::Intercompany);

        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::"G/L Account", GLAccount."No.",
          GenJournalLine."Bal. Account Type"::"G/L Account", ICGLAccount."Map-to G/L Acc. No.", '', 1);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::"IC Partner", ICPartnerCode,
          GenJournalLine."Bal. Account Type"::"G/L Account", ICGLAccount."Map-to G/L Acc. No.", ICGLAccount."No.", 1);
        GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::" ");
        GenJournalLine.Modify(true);

        LibraryLowerPermissions.SetIntercompanyPostingsEdit();
        LibraryLowerPermissions.AddJournalsPost();

        // Exercise: Post IC Journal Line.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify IC Outbox Journal Entries after posting Multiple IC Journal Line.
        VerifyICOutboxJournalLine(
          GenJournalLine."IC Partner Code", ICOutboxJnlLine."Account Type"::"IC Partner", GenJournalLine."IC Partner Code",
          GenJournalLine."Document No.", GenJournalLine.Amount);
        ICAccountNo := GenJournalLine."IC Account No.";
        VerifyICOutboxJournalLine(
          GenJournalLine."IC Partner Code", ICOutboxJnlLine."Account Type"::"G/L Account", ICAccountNo,
          GenJournalLine."Document No.", -GenJournalLine.Amount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostPurchRetOrderWithOtherICVendor()
    begin
        // Verify Purchase Return Order in IC Outbox Transactions with other IC Pay-to Vendor.
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddO365Setup();
        LibraryLowerPermissions.AddPurchDocsPost();
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();
        PostPurchRetOrderWithICVendor(CreateICVendor(CreateICPartner()), true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchRetOrderWithSameICVendor()
    begin
        // Verify Purchase Return Order in IC Outbox Transactions with same IC Pay-to Vendor.
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();
        LibraryLowerPermissions.AddPurchDocsPost();
        LibraryLowerPermissions.AddO365Setup();
        PostPurchRetOrderWithICVendor('', false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostPurchRetOrderWithOtherNonICVendor()
    begin
        // Verify Purchase Return Order in IC Outbox Transactions with other Non IC Pay-to Vendor.
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddO365Setup();
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();
        LibraryLowerPermissions.AddPurchDocsPost();
        PostPurchRetOrderWithICVendor(CreateICVendor(''), true);
    end;

    local procedure PostPurchRetOrderWithICVendor(PayToVendorNo: Code[20]; OtherVendor: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
        ICPartnerCode: Code[20];
    begin
        // Setup: Create IC Partner, create Purchase Return Order, change Pay-to Vendor and send it to IC.
        Initialize();

        ICPartnerCode := CreateICPartner();
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", CreateICVendor(ICPartnerCode), CreateItem());
        if OtherVendor then
            UpdatePurchaseDocument(PurchaseHeader, PayToVendorNo);
        ICInboxOutboxMgt.SendPurchDoc(PurchaseHeader, false);

        // Exercise.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // Verify: Verify Purchase Return Order in IC Outbox Transactions.
        FindICOutboxTransaction(
          ICOutboxTransaction, PurchaseHeader."No.", ICOutboxTransaction."Document Type"::"Return Order",
          ICOutboxTransaction."IC Source Type"::"Purchase Document");
        ICOutboxTransaction.TestField("IC Partner Code", ICPartnerCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOnPostPurchCrMemoWithBlockedICPartner()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Verify error while post Purchase Credit Memo with blocked IC Partner.
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddO365Setup();
        LibraryLowerPermissions.AddPurchDocsPost();
        PostPurchDocumentWithBlockedICPartner(PurchaseHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOnPostPurchInvoiceWithBlockedICPartner()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Verify error while post Purchase Invoice with blocked IC Partner.
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddPurchDocsPost();
        LibraryLowerPermissions.AddO365Setup();
        PostPurchDocumentWithBlockedICPartner(PurchaseHeader."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchInvoiceWithDefaultICPartnerGLAccNo()
    var
        PurchaseHeader: Record "Purchase Header";
        GLAccount: Record "G/L Account";
        ICPartnerCode: Code[20];
        DocNo: Code[20];
    begin
        // [FEATURE] [IC Partner]
        // [SCENARIO 123601] Posting Purchase Invoice when Default IC Partner G/L Acc. No. is defined
        Initialize();

        // [GIVEN] G/L Account = 'X', IC G/L Account = 'Y', 'X'."Default IC Partner G/L Acc. No." = 'Y'
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddO365Setup();
        ICPartnerCode := CreateICPartner();
        CreateICGLAccountWithDefaultICPartnerGLAccNo(GLAccount);
        // [GIVEN] Purchase Invoice for "G/L Account X"
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();
        LibraryLowerPermissions.AddPurchDocsPost();
        CreatePurchInvWithGLAccount(PurchaseHeader, GLAccount, ICPartnerCode);

        // [WHEN] Purchase Invoice is posted
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] G/L Entry for "G/L Account X" is created, IC partner code is filled with created ICPartnerCode
        VerifyGLEntryWithBalAccTypeICPartner(DocNo, ICPartnerCode, GLAccount."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceWithDefaultICPartnerGLAccNo()
    var
        SalesHeader: Record "Sales Header";
        GLAccount: Record "G/L Account";
        ICPartnerCode: Code[20];
        DocNo: Code[20];
    begin
        // [FEATURE] [IC Partner]
        // [SCENARIO 123601] Posting Sales Invoice when Default IC Partner G/L Acc. No. is defined
        Initialize();

        // [GIVEN] G/L Account = 'X', IC G/L Account = 'Y', 'X'."Default IC Partner G/L Acc. No." = 'Y'
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddO365Setup();
        ICPartnerCode := CreateICPartner();
        CreateICGLAccountWithDefaultICPartnerGLAccNo(GLAccount);
        // [GIVEN] Sales Invoice for G/L Account 'X'
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();
        LibraryLowerPermissions.AddSalesDocsPost();
        CreateSalesInvWithGLAccount(SalesHeader, GLAccount, ICPartnerCode);

        // [WHEN] Sales Invoice is posted
        DocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] G/L Entry for "G/L Account X" is created, IC partner code is filled with created ICPartnerCode
        VerifyGLEntryWithBalAccTypeICPartner(DocNo, ICPartnerCode, GLAccount."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOnPostPurchOrderWithBlockedICPartner()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Verify error while post Purchase Order with blocked IC Partner.
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddPurchDocsPost();
        PostPurchDocumentWithBlockedICPartner(PurchaseHeader."Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOnPostPurchRetOrderWithBlockedICPartner()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Verify error while post Purchase Return Order with blocked IC Partner.
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddPurchDocsPost();
        LibraryLowerPermissions.AddIntercompanyPostingsSetup();
        PostPurchDocumentWithBlockedICPartner(PurchaseHeader."Document Type"::"Return Order");
    end;

    local procedure PostPurchDocumentWithBlockedICPartner(DocumentType: Enum "Purchase Document Type")
    var
        PurchaseHeader: Record "Purchase Header";
        ICPartner: Record "IC Partner";
        ICPartnerCode: Code[20];
    begin
        // Setup: Create IC Parter, create Purchase Document and blocked IC Partner.
        Initialize();
        ICPartnerCode := CreateICPartner();
        CreatePurchaseDocument(PurchaseHeader, DocumentType, CreateICVendor(ICPartnerCode), CreateItem());
        BlockICPartner(ICPartnerCode);

        // Exercise.
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify error while post Purchase Document with blocked IC Partner.
        Assert.ExpectedTestFieldError(ICPartner.FieldCaption(Blocked), Format(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOnICGenJournalLineWithBlockedCustomer()
    var
        Customer: Record Customer;
    begin
        // Verify error while create General Journal Line with Blocked All IC Customer.
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddO365Setup();
        LibraryLowerPermissions.AddJournalsPost();
        ICGenJournalLineWithBlockedCustomer(CreateAndUpdateICCustomer(CreateICPartner(), Customer.Blocked::All));
    end;

    local procedure ICGenJournalLineWithBlockedCustomer(ICCustomerNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Setup: Create General Journal Batch and create IC Customer with All Blocked.
        Initialize();
        CreateICJournalBatch(GenJournalBatch, GenJournalTemplate.Type::Intercompany);

        // Exercise.
        asserterror CreateGeneralJournalLine(
            GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::Customer, ICCustomerNo,
            GenJournalLine."Bal. Account Type"::"G/L Account", '', '', 1);  // Using 1 as a positive sign factor.

        // Verify: Verify error while create General Journal Line with Blocked All IC Customer.
        Assert.ExpectedError(StrSubstNo(ICCustomerBlockedAllErr, ICCustomerNo));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPartialSalesOrderWithICCustomer()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICPartnerCode: Code[20];
    begin
        // Verify Sales Order IC Outbox Transactions after post Sales Order with partial Quantity.

        // Setup: Create IC Parter, create Sales Order, update partial Quantity to Invoice in Sales Line.
        Initialize();
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddO365Setup();
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();
        LibraryLowerPermissions.AddSalesDocsPost();
        ICPartnerCode := CreateICPartner();
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, CreateICCustomer(ICPartnerCode), CreateItem());
        FindAndUpdateSalesLine(SalesLine, SalesHeader);  // Update partial Quantity on Qty. to Invoice.

        // Exercise.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify Sales Order IC Outbox Transactions after post Sales Order with partial Quantity.
        FindICOutboxTransaction(
          ICOutboxTransaction, SalesHeader."No.", ICOutboxTransaction."Document Type"::Order,
          ICOutboxTransaction."IC Source Type"::"Sales Document");
        ICOutboxTransaction.TestField("IC Partner Code", ICPartnerCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOnICGenJournalLineWithBlockedInvoice()
    var
        Customer: Record Customer;
    begin
        // Verify error while create General Journal Line with Blocked Invoice IC Customer.
        Initialize();

        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddJournalsPost();
        LibraryLowerPermissions.AddO365Setup();
        ICGenJournalLineWithBlockedCustomer(CreateAndUpdateICCustomer(CreateICPartner(), Customer.Blocked::Invoice));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostSalesRetOrderWithICBillToCustomer()
    var
        SalesHeader: Record "Sales Header";
        ICOutboxTransaction: Record "IC Outbox Transaction";
    begin
        // Verify Sales Return Order in IC Outbox Transactions after send it for IC with IC Bill to Customer.
        Initialize();

        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyBillToCustomerAddressNotificationId());
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyCustomerAddressNotificationId());
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddSalesDocsPost();
        LibraryLowerPermissions.AddO365Setup();
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();
        SalesDocumentMovedInICOutbox(
          SalesHeader."Document Type"::"Return Order", CreateICCustomer(CreateICPartner()),
          ICOutboxTransaction."Document Type"::"Return Order");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReceivedICSalesDocumenDeliveryDates()
    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
    begin
        Initialize();

        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddO365Setup();
        LibraryLowerPermissions.AddSalesDocsCreate();
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();
        LibraryLowerPermissions.AddPurchDocsCreate();
        CreateSendSalesDocumentReceivePurchaseDocument(SalesHeader, PurchaseHeader, false);
        VerifySentSalesDocumentDates(SalesHeader, PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReceivedICPurchaseDocumenReceiptDates()
    var
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
    begin
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddO365Setup();
        LibraryLowerPermissions.AddPurchDocsCreate();
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();
        LibraryLowerPermissions.AddSalesDocsCreate();
        CreateSendPurchaseDocumentReceiveSalesDocument(
          PurchaseHeader, SalesHeader, CreateItem(), LibraryRandom.RandIntInRange(10, 100), false);
        VerifySentPurchaseDocumentDates(PurchaseHeader, SalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReceivedICSalesDocumentDirectUnitCost()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify DirectUnitCost when sending SalesDoc
        Initialize();

        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();
        LibraryLowerPermissions.AddO365Setup();
        LibraryLowerPermissions.AddPurchDocsCreate();
        LibraryLowerPermissions.AddSalesDocsCreate();
        CreateSendSalesDocumentReceivePurchaseDocument(SalesHeader, PurchaseHeader, false);
        FindSalesLine(SalesLine, SalesHeader);
        FindPurchLine(PurchaseLine, PurchaseHeader);

        Assert.AreEqual(
          SalesLine."Unit Price",
          PurchaseLine."Direct Unit Cost",
          StrSubstNo(TableFieldErr, PurchaseLine.TableCaption(), PurchaseLine.FieldCaption("No.")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReceivedICPurchaseDocumentUnitPrice()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify UnitPrice when sending PurchDoc
        Initialize();

        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();
        LibraryLowerPermissions.AddSalesDocsCreate();
        LibraryLowerPermissions.AddO365Setup();
        LibraryLowerPermissions.AddPurchDocsCreate();
        CreateSendPurchaseDocumentReceiveSalesDocument(
          PurchaseHeader, SalesHeader, CreateItem(), LibraryRandom.RandIntInRange(10, 100), false);
        FindSalesLine(SalesLine, SalesHeader);
        FindPurchLine(PurchaseLine, PurchaseHeader);

        Assert.AreEqual(
          PurchaseLine."Direct Unit Cost",
          Round(SalesLine."Unit Price", 0.01),
          StrSubstNo(TableFieldErr, SalesLine.TableCaption(), SalesLine.FieldCaption("No.")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceRounding()
    var
        SalesHeader: Record "Sales Header";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICOutboxSalesLine: Record "IC Outbox Sales Line";
        DocumentNo: Code[20];
    begin
        // [SCENARIO 120476.1] Verify Sales Invoice rounding line is not transfered to IC Outbox
        Initialize();

        // [GIVEN] GLSetup with Invoice Rounding Presicion = 1
        LibraryERM.SetInvRoundingPrecisionLCY(1);

        // [GIVEN] Sales Invoice with Amount Incl. VAT = 0.9
        CreateRoundingSalesDoc(SalesHeader, SalesHeader."Document Type"::Invoice);

        // [WHEN] Post Sales Invoice
        LibraryLowerPermissions.SetIntercompanyPostingsEdit();
        LibraryLowerPermissions.AddSalesDocsPost();
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] There's no rounding line in IC Outbox Sales Invoice
        FindICOutboxTransaction(
          ICOutboxTransaction, DocumentNo, ICOutboxTransaction."Document Type"::Invoice,
          ICOutboxTransaction."IC Source Type"::"Sales Document");
        FindICOutboxSalesLine(
          ICOutboxSalesLine,
          ICOutboxTransaction."Transaction No.", DocumentNo, ICOutboxSalesLine."Document Type"::Invoice);
        ICOutboxSalesLine.FindLast();

        Assert.AreEqual(
          ICOutboxSalesLine."IC Partner Ref. Type"::Item,
          ICOutboxSalesLine."IC Partner Ref. Type",
          StrSubstNo(TableFieldErr, ICOutboxSalesLine.TableCaption(), ICOutboxSalesLine.FieldCaption("IC Partner Ref. Type")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoRounding()
    var
        SalesHeader: Record "Sales Header";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICOutboxSalesLine: Record "IC Outbox Sales Line";
        DocumentNo: Code[20];
    begin
        // [SCENARIO 120476.2] Verify Sales Credit Memo rounding line is not transfered to IC Outbox
        Initialize();

        // [GIVEN] GLSetup with Invoice Rounding Presicion = 1
        LibraryERM.SetInvRoundingPrecisionLCY(1);

        // [GIVEN] Sales Credit Memo with Amount Incl. VAT = 0.9
        CreateRoundingSalesDoc(SalesHeader, SalesHeader."Document Type"::"Credit Memo");

        // [WHEN] Post Sales Credit Memo
        LibraryLowerPermissions.SetIntercompanyPostingsEdit();
        LibraryLowerPermissions.AddSalesDocsPost();
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] There's no rounding line in IC Outbox Sales Credit Memo
        FindICOutboxTransaction(
          ICOutboxTransaction, DocumentNo, ICOutboxTransaction."Document Type"::"Credit Memo",
          ICOutboxTransaction."IC Source Type"::"Sales Document");
        FindICOutboxSalesLine(
          ICOutboxSalesLine,
          ICOutboxTransaction."Transaction No.", DocumentNo, ICOutboxSalesLine."Document Type"::"Credit Memo");
        ICOutboxSalesLine.FindLast();

        Assert.AreEqual(
          ICOutboxSalesLine."IC Partner Ref. Type"::Item,
          ICOutboxSalesLine."IC Partner Ref. Type",
          StrSubstNo(TableFieldErr, ICOutboxSalesLine.TableCaption(), ICOutboxSalesLine.FieldCaption("IC Partner Ref. Type")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostICSalesInvoiceWithEmptySalesLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICOutboxSalesLine: Record "IC Outbox Sales Line";
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        GLAccountNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 363243] IC Sales Line where Type = "G/L Account" and "No." is empty should not be put into IC Outbox during posting.
        Initialize();

        // [GIVEN] G/L Account and IC Customer
        CreateVATPostingSetup(VATPostingSetup);
        GLAccountNo := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale);

        // [GIVEN] Sales Invoice to IC Customer with two sales lines:
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Invoice,
          CreateICCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        // [GIVEN] First line, where "Type" = "G/L Account", "IC Partner Ref. Type" = "G/L Account"
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccountNo, LibraryRandom.RandInt(10));
        // [GIVEN] Second Sales Line where "Type" = "G/L Account", "No." = " ", "IC Partner Ref. Type" = " "
        CreateEmptySalesLine(SalesHeader, GLAccountNo);

        // [WHEN] Post Sales Invoice
        LibraryLowerPermissions.SetIntercompanyPostingsEdit();
        LibraryLowerPermissions.AddSalesDocsPost();
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] No line is created in IC Outbox Sales Line, where "IC Partner Ref. Type" = " "
        VerifyICOutboxSalesLine(
          DocumentNo, ICOutboxTransaction."Document Type"::Invoice, ICOutboxSalesLine."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostICCrMemoInvoiceWithEmptySalesLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICOutboxSalesLine: Record "IC Outbox Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        DocumentNo: Code[20];
        GLAccountNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 363243] IC Cr.Memo Line where Type = "G/L Account" and "No." is empty should not be put into IC Outbox during posting.
        Initialize();

        // [GIVEN] G/L Account and IC Customer
        CreateVATPostingSetup(VATPostingSetup);
        GLAccountNo := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale);

        // [GIVEN] Cr.Memo Invoice to IC Customer with two sales lines:
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::"Credit Memo",
          CreateICCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        // [GIVEN] First line, where "Type" = "G/L Account", "IC Partner Ref. Type" = "G/L Account"
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccountNo, LibraryRandom.RandInt(10));
        // [GIVEN] Second Sales Line where "Type" = "G/L Account", "No." = " ", "IC Partner Ref. Type" = " "
        CreateEmptySalesLine(SalesHeader, GLAccountNo);

        // [WHEN] Post Sales Cr.Memo Invoice
        LibraryLowerPermissions.SetIntercompanyPostingsEdit();
        LibraryLowerPermissions.AddSalesDocsPost();
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] No line is created in IC Outbox Sales Line, where "IC Partner Ref. Type" = " "
        VerifyICOutboxSalesLine(
          DocumentNo, ICOutboxTransaction."Document Type"::"Credit Memo", ICOutboxSalesLine."Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReceivedICSalesDocumentDirectUnitCostWithPricesInclVAT()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Prices Incl. VAT] [Sales]
        // [SCENARIO 371724] Received PurchaseLine."Direct Unit Cost" = sent SalesLine."Unit Price",  PurchaseLine."Line Amount" = SalesLine."Amount Including VAT" when sending Sales Order with "Prices Incl. VAT" = TRUE
        Initialize();

        // [GIVEN] Create Sales Order with "Prices Incl. VAT" = TRUE, "Unit Price" = 'X', "Amount Including VAT" = 'Y'. Send to IC Partner.
        // [WHEN] Receive IC Partner's Purchase Order
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddPurchDocsCreate();
        LibraryLowerPermissions.AddSalesDocsCreate();
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();
        LibraryLowerPermissions.AddO365Setup();
        CreateSendSalesDocumentReceivePurchaseDocument(SalesHeader, PurchaseHeader, true);

        // [THEN] Received PurchaseLine."Direct Unit Cost" = 'X'
        // [THEN] Received PurchaseLine."Line Amount" = 'Y'
        FindSalesLine(SalesLine, SalesHeader);
        FindPurchLine(PurchaseLine, PurchaseHeader);

        Assert.AreNearlyEqual(
          SalesLine."Unit Price",
          PurchaseLine."Direct Unit Cost",
          LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(TableFieldErr, PurchaseLine.TableCaption(), PurchaseLine.FieldCaption("No.")));

        Assert.AreEqual(SalesLine."Amount Including VAT", PurchaseLine."Line Amount", PurchaseLine.FieldCaption("Line Amount"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReceivedICPurchaseDocumentUnitPriceWithPricesInclVAT()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Prices Incl. VAT] [Purchase]
        // [SCENARIO 371724] Received SalesLine."Unit Price" = sent PurchaseLine."Direct Unit Cost",  SalesLine."Line Amount" = PurchaseLine."Amount Including VAT" when sending Purchase Order with "Prices Incl. VAT" = TRUE
        Initialize();

        // [GIVEN] Create Purchase Order with "Prices Incl. VAT" = TRUE, "Direct Unit Cost" = 'X', "Amount Including VAT" = 'Y'. Send to IC Partner.
        // [WHEN] Receive IC Partner's Sales Order
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddO365Setup();
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();
        LibraryLowerPermissions.AddSalesDocsCreate();
        LibraryLowerPermissions.AddPurchDocsCreate();
        CreateSendPurchaseDocumentReceiveSalesDocument(
          PurchaseHeader, SalesHeader, CreateItem(), LibraryRandom.RandIntInRange(10, 100), true);

        // [THEN] Received SalesLine."Unit Price" = 'X'
        // [THEN] Received SalesLine."Line Amount" = 'Y'
        FindSalesLine(SalesLine, SalesHeader);
        FindPurchLine(PurchaseLine, PurchaseHeader);

        Assert.AreNearlyEqual(
          PurchaseLine."Direct Unit Cost",
          SalesLine."Unit Price",
          LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(TableFieldErr, SalesLine.TableCaption(), SalesLine.FieldCaption("No.")));

        Assert.AreEqual(PurchaseLine."Amount Including VAT", SalesLine."Line Amount", SalesLine.FieldCaption("Line Amount"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReceivedICSalesDocumentDirectUnitCostWithPricesExclVAT()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Prices Excl. VAT] [Sales]
        // [SCENARIO 371724] Received PurchaseLine."Direct Unit Cost" = sent SalesLine."Unit Price",  PurchaseLine."Line Amount" = SalesLine."Line Amount" when sending Sales Order with "Prices Incl. VAT" = FALSE
        Initialize();

        // [GIVEN] Create Sales Order with "Prices Incl. VAT" = FALSE, "Unit Price" = 'X', "Line Amount" = 'Y'. Send to IC Partner.
        // [WHEN] Receive IC Partner's Purchase Order
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();
        LibraryLowerPermissions.AddPurchDocsCreate();
        LibraryLowerPermissions.AddSalesDocsCreate();
        LibraryLowerPermissions.AddO365Setup();
        CreateSendSalesDocumentReceivePurchaseDocument(SalesHeader, PurchaseHeader, false);

        // [THEN] Received PurchaseLine."Direct Unit Cost" = 'X'
        // [THEN] Received PurchaseLine."Line Amount" = 'Y'
        FindSalesLine(SalesLine, SalesHeader);
        FindPurchLine(PurchaseLine, PurchaseHeader);

        Assert.AreNearlyEqual(
          SalesLine."Unit Price",
          PurchaseLine."Direct Unit Cost",
          LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(TableFieldErr, PurchaseLine.TableCaption(), PurchaseLine.FieldCaption("No.")));

        Assert.AreEqual(SalesLine."Line Amount", PurchaseLine."Line Amount", PurchaseLine.FieldCaption("Line Amount"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReceivedICPurchaseDocumentUnitPriceWithPricesExclVAT()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Prices Excl. VAT] [Purchase]
        // [SCENARIO 371724] Received SalesLine."Unit Price" = sent PurchaseLine."Direct Unit Cost",  SalesLine."Line Amount" = PurchaseLine."Line Amount" when sending Purchase Order with "Prices Incl. VAT" = FALSE
        Initialize();

        // [GIVEN] Create Purchase Order with "Prices Incl. VAT" = FALSE, "Direct Unit Cost" = 'X', "Line Amount" = 'Y'. Send to IC Partner.
        // [WHEN] Receive IC Partner's Sales Order
        LibraryLowerPermissions.SetSalesDocsCreate();
        LibraryLowerPermissions.AddPurchDocsCreate();
        LibraryLowerPermissions.AddIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddO365Setup();
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();
        CreateSendPurchaseDocumentReceiveSalesDocument(
          PurchaseHeader, SalesHeader, CreateItem(), LibraryRandom.RandIntInRange(10, 100), false);

        // [THEN] Received SalesLine."Unit Price" = 'X'
        // [THEN] Received SalesLine."Line Amount" = 'Y'
        FindSalesLine(SalesLine, SalesHeader);
        FindPurchLine(PurchaseLine, PurchaseHeader);

        Assert.AreNearlyEqual(
          PurchaseLine."Direct Unit Cost",
          SalesLine."Unit Price",
          LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(TableFieldErr, SalesLine.TableCaption(), SalesLine.FieldCaption("No.")));

        Assert.AreEqual(PurchaseLine."Line Amount", SalesLine."Line Amount", SalesLine.FieldCaption("Line Amount"));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderInvoicedQtyAfterPostReceivedPurchInvoice()
    var
        OriginalPurchaseHeader: Record "Purchase Header";
        ReceivedPurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICInboxTransaction: Record "IC Inbox Transaction";
        ICInboxPurchaseHeader: Record "IC Inbox Purchase Header";
        ICPartnerCodeVendor: Code[20];
        SalesInvoiceNo: Code[20];
        VendorNo: Code[20];
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Purchases] [Sales] [Get Shipment Lines]
        // [SCENARIO 371939] Purchase Order get invoiced Quantity after posting of received Purchase Invoice
        Initialize();
        ICPartnerCodeVendor := CreateICPartner();
        VendorNo := CreateICVendor(ICPartnerCodeVendor);
        CustomerNo := CreateICCustomer(CreateICPartner());

        // [GIVEN] Create Purchase Order "PO" with Quantity = 'X'. Post Receipt.
        // [GIVEN] Create Sales Order ("External Document No." = "PO", Quantity = 'Y', where 'Y' < 'X'). Post Shipment "SS".
        LibraryLowerPermissions.SetIntercompanyPostingsEdit();
        LibraryLowerPermissions.AddSalesDocsPost();
        LibraryLowerPermissions.AddO365Setup();
        LibraryLowerPermissions.AddPurchDocsPost();
        CreatePostPurchReceiptCreatePostSalesShipment(
          OriginalPurchaseHeader, SalesHeader, VendorNo, CustomerNo, OriginalPurchaseHeader."Document Type"::Order);

        // [GIVEN] Create Sales Invoice. Use Get Shipment Lines from posted shipment "SS". Post Invoice "SI".
        SalesInvoiceNo := CreatePostSalesInvoiceWithGetShipmentLines(CustomerNo);

        // [GIVEN] Send Sales Invoice "SI". Receive Purchase Invoice "PI".
        SendICSalesInvoice(ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader, SalesInvoiceNo, ICPartnerCodeVendor);
        ReceiveICPurchaseInvoice(
          ReceivedPurchaseHeader, ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader, SalesInvoiceNo, VendorNo);

        // [WHEN] Post received Purchase Invoice "PI".
        LibraryPurchase.PostPurchaseDocument(ReceivedPurchaseHeader, true, true);

        // [THEN] Purchase Order "PO" line has "Quantity Invoiced" = 'Y'
        VerifyPurchLineInvoicedQty(SalesHeader, OriginalPurchaseHeader);
    end;

    [Test]
    procedure ReceivePurchaseInvoiceWithCustomDescriptionOnLines()
    var
        ReceivedPurchaseHeader: Record "Purchase Header";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICInboxTransaction: Record "IC Inbox Transaction";
        ICInboxPurchaseHeader: Record "IC Inbox Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        ItemNo: Code[20];
        SalesInvoiceNo: Code[20];
        VendorNo: Code[20];
        CustomerNo: Code[20];
    begin
        // [SCENARIO 504540] Description on created IC purchase invoice line is transferred from sales invoice line
        Initialize();

        // [GIVEN] Create VAT posting setup, customer, vendor, G/L account, item
        CreateICGLAccountWithVATPostingGroup(GLAccount, VATPostingSetup);
        VendorNo := CreateICVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group");
        CustomerNo := CreateICCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group");
        ItemNo := LibraryInventory.CreateItemNoWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group");

        // [GIVEN] Add permissions
        LibraryLowerPermissions.SetIntercompanyPostingsEdit();
        LibraryLowerPermissions.AddSalesDocsPost();
        LibraryLowerPermissions.AddO365Setup();
        LibraryLowerPermissions.AddPurchDocsPost();

        // [GIVEN] Create sales invoice with four lines where two lines are with custom description. Post sales invoice
        SalesInvoiceNo := CreateAndPostSalesInvoice(CustomerNo, GLAccount."No.", ItemNo);

        // [GIVEN] Send sales invoice to intercompany process
        SendICSalesInvoice(ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader, SalesInvoiceNo, GetICPartnerFromVendor(VendorNo));

        // [WHEN] Accept purchase invoice in partner company
        ReceiveICPurchaseInvoice(ReceivedPurchaseHeader, ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader, SalesInvoiceNo, VendorNo);

        // [THEN] Purchase invoice lines have the same description as sales invoice lines in partner company
        VerifyDescriptionOnPurchaseLines(ReceivedPurchaseHeader, SalesInvoiceNo);
    end;

    [Test]
    procedure ReceiveSalesInvoiceWithCustomDescriptionOnLines()
    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICInboxTransaction: Record "IC Inbox Transaction";
        ICInboxSalesHeader: Record "IC Inbox Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        PurchaseInvoiceNo: Code[20];
        CustomerNo: Code[20];
        VendorNo: Code[20];
        ItemNo: Code[20];
    begin
        // [SCENARIO 504540] Description on created IC sales invoice line is transferred from purchase invoice line
        Initialize();

        // [GIVEN] Create VAT posting setup, customer, vendor, G/L account, item
        CreateICGLAccountWithVATPostingGroup(GLAccount, VATPostingSetup);
        VendorNo := CreateICVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group");
        CustomerNo := CreateICCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group");
        ItemNo := LibraryInventory.CreateItemNoWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group");

        // [GIVEN] Add permissions
        LibraryLowerPermissions.SetIntercompanyPostingsEdit();
        LibraryLowerPermissions.AddSalesDocsPost();
        LibraryLowerPermissions.AddO365Setup();
        LibraryLowerPermissions.AddPurchDocsPost();

        // [GIVEN] Create purchase invoice with four lines where two lines are with custom description
        PurchaseInvoiceNo := CreatePurchaseInvoiceWithLines(PurchaseHeader, VendorNo, GLAccount."No.", ItemNo);

        //[GIVEN] Send purchase invoice to partner company
        SendICPurchaseDocument(PurchaseHeader, GetICPartnerFromCustomer(CustomerNo), ICOutboxTransaction, ICInboxTransaction, ICInboxSalesHeader);

        // [WHEN] Receive sales document from IC partner
        ReceiveICSalesInvoice(SalesHeader, ICOutboxTransaction, ICInboxTransaction, ICInboxSalesHeader, PurchaseHeader."No.", CustomerNo);

        // [THEN] Received sales lines have the same description as purchase invoice lines in partner company
        VerifyDescriptionOnSalesLines(SalesHeader, PurchaseInvoiceNo);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseReturnOrderInvoicedQtyAfterPostReceivedPurchCrMemo()
    var
        OriginalPurchaseHeader: Record "Purchase Header";
        ReceivedPurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICInboxTransaction: Record "IC Inbox Transaction";
        ICInboxPurchaseHeader: Record "IC Inbox Purchase Header";
        ICPartnerCodeVendor: Code[20];
        SalesCrMemoNo: Code[20];
        VendorNo: Code[20];
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Purchases] [Sales] [Get Return Receipt Lines]
        // [SCENARIO 371939] Purchase Return Order get invoiced Quantity after posting of received Purchase Credit Memo
        Initialize();
        ICPartnerCodeVendor := CreateICPartner();
        VendorNo := CreateICVendor(ICPartnerCodeVendor);
        CustomerNo := CreateICCustomer(CreateICPartner());

        // [GIVEN] Create Purchase Return Order"PRO" with Quantity = 'X'. Post Return Shipment.
        // [GIVEN] Create Sales Return Order ("External Document No." = "PRO", Quantity = 'Y', where 'Y' < 'X'). Post Return Receipt "SRR".
        LibraryLowerPermissions.SetIntercompanyPostingsEdit();
        LibraryLowerPermissions.AddPurchDocsPost();
        LibraryLowerPermissions.AddO365Setup();
        LibraryLowerPermissions.AddSalesDocsPost();

        CreatePostPurchReceiptCreatePostSalesShipment(
          OriginalPurchaseHeader, SalesHeader, VendorNo, CustomerNo, OriginalPurchaseHeader."Document Type"::"Return Order");

        // [GIVEN] Create Sales Credit Memo. Use Get Return Receipt Lines from posted return receipt "SRR". Post Credit Memo "SCRM".
        SalesCrMemoNo := CreatePostSalesCrMemoWithGetRetReceiptLines(CustomerNo);

        // [GIVEN] Send Sales Credit Memo "SCRM". Receive Purchase Credit Memo "PCRM".
        SendICSalesCrMemo(ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader, SalesCrMemoNo, ICPartnerCodeVendor);
        ReceiveICPurchaseCrMemo(
          ReceivedPurchaseHeader, ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader, SalesCrMemoNo, VendorNo);

        // [WHEN] Post received Purchase Credit Memo "PCRM".
        LibraryPurchase.PostPurchaseDocument(ReceivedPurchaseHeader, true, true);

        // [THEN] Purchase Retrun Order "PRO" line has "Quantity Invoiced" = 'Y'
        VerifyPurchLineInvoicedQty(SalesHeader, OriginalPurchaseHeader);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TwoPurchaseOrdersInvoicedQtyAfterPostReceivedPurchInvoice()
    var
        OriginalPurchaseHeader: array[2] of Record "Purchase Header";
        ReceivedPurchaseHeader: Record "Purchase Header";
        SalesHeader: array[2] of Record "Sales Header";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICInboxTransaction: Record "IC Inbox Transaction";
        ICInboxPurchaseHeader: Record "IC Inbox Purchase Header";
        ICPartnerCodeVendor: Code[20];
        VendorNo: Code[20];
        CustomerNo: Code[20];
        SalesInvoiceNo: Code[20];
        i: Integer;
    begin
        // [FEATURE] [Purchases] [Sales] [Get Shipment Lines]
        // [SCENARIO 371939] Two Purchase Orders get invoiced Quantity after posting of received Purchase Invoice
        Initialize();
        ICPartnerCodeVendor := CreateICPartner();
        VendorNo := CreateICVendor(ICPartnerCodeVendor);
        CustomerNo := CreateICCustomer(CreateICPartner());

        // [GIVEN] Create two Purchase Orders ["PO1";"PO2"] with Quantity = ["X1";"X2"]. Post two Receipts.
        // [GIVEN] Create two Sales Orders ("External Document No." = ["PO1";"PO2"], Quantity = ["Y1";"Y2"], where "Y1" < "X1", "Y2" < "X2"). Post two Shipments ["SS1";"SS2"].
        LibraryLowerPermissions.SetIntercompanyPostingsEdit();
        LibraryLowerPermissions.AddO365Setup();
        LibraryLowerPermissions.AddPurchDocsPost();
        LibraryLowerPermissions.AddSalesDocsPost();
        for i := 1 to 2 do
            CreatePostPurchReceiptCreatePostSalesShipment(
              OriginalPurchaseHeader[i], SalesHeader[i], VendorNo, CustomerNo, OriginalPurchaseHeader[i]."Document Type"::Order);

        // [GIVEN] Create Sales Invoice. Use Get Shipment Lines from two posted shipments: "SS1" and "SS2". Post Invoice "SI".
        SalesInvoiceNo :=
          CreatePostSalesInvoiceWithGetShipmentLines(CustomerNo);

        // [GIVEN] Send Sales Invoice "SI". Receive Purchase Invoice "PI".
        SendICSalesInvoice(ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader, SalesInvoiceNo, ICPartnerCodeVendor);
        ReceiveICPurchaseInvoice(
          ReceivedPurchaseHeader, ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader, SalesInvoiceNo, VendorNo);

        // [WHEN] Post received Purchase Invoice "PI".
        LibraryPurchase.PostPurchaseDocument(ReceivedPurchaseHeader, true, true);

        // [THEN] Purchase Order "PO1" line has "Quantity Invoiced" = "Y1"
        // [THEN] Purchase Order "PO2" line has "Quantity Invoiced" = "Y2"
        VerifyPurchLineInvoicedQty(SalesHeader[1], OriginalPurchaseHeader[1]);
        VerifyPurchLineInvoicedQty(SalesHeader[2], OriginalPurchaseHeader[2]);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TwoPurchaseReturnOrdersInvoicedQtyAfterPostReceivedPurchCrMemo()
    var
        OriginalPurchaseHeader: array[2] of Record "Purchase Header";
        ReceivedPurchaseHeader: Record "Purchase Header";
        SalesHeader: array[2] of Record "Sales Header";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICInboxTransaction: Record "IC Inbox Transaction";
        ICInboxPurchaseHeader: Record "IC Inbox Purchase Header";
        ICPartnerCodeVendor: Code[20];
        SalesCrMemoNo: Code[20];
        VendorNo: Code[20];
        CustomerNo: Code[20];
        i: Integer;
    begin
        // [FEATURE] [Purchases] [Sales] [Get Return Receipt Lines]
        // [SCENARIO 371939] Two Purchase Return Orders get invoiced Quantity after posting of received Purchase Credit Memo
        Initialize();
        ICPartnerCodeVendor := CreateICPartner();
        VendorNo := CreateICVendor(ICPartnerCodeVendor);
        CustomerNo := CreateICCustomer(CreateICPartner());

        // [GIVEN] Create two Purchase Return Orders ["PRO1";"PRO2"] with Quantity = ["X1";"X2"]. Post two Return Shipments.
        // [GIVEN] Create Sales Return Order ("External Document No." = ["PRO1";"PRO2"], Quantity = ["Y1";"Y2"], where "Y1" < "X1", "Y2" < "X2"). Post two Return Receipts ["SRR1";"SRR2"].
        LibraryLowerPermissions.SetIntercompanyPostingsEdit();
        LibraryLowerPermissions.AddPurchDocsPost();
        LibraryLowerPermissions.AddSalesDocsPost();
        LibraryLowerPermissions.AddO365Setup();
        for i := 1 to 2 do
            CreatePostPurchReceiptCreatePostSalesShipment(
              OriginalPurchaseHeader[i], SalesHeader[i], VendorNo, CustomerNo, OriginalPurchaseHeader[1]."Document Type"::"Return Order");

        // [GIVEN] Create Sales Credit Memo. Use Get Return Receipt Lines from two posted return receipt: "SRR1" and "SRR2". Post Credit Memo "SCRM".
        SalesCrMemoNo := CreatePostSalesCrMemoWithGetRetReceiptLines(CustomerNo);

        // [GIVEN] Send Sales Credit Memo "SCRM". Receive Purchase Credit Memo "PCRM".
        SendICSalesCrMemo(ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader, SalesCrMemoNo, ICPartnerCodeVendor);
        ReceiveICPurchaseCrMemo(
          ReceivedPurchaseHeader, ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader, SalesCrMemoNo, VendorNo);

        // [WHEN] Post received Purchase Credit Memo "PCRM".
        LibraryPurchase.PostPurchaseDocument(ReceivedPurchaseHeader, true, true);

        // [THEN] Purchase Order "PRO1" line has "Quantity Invoiced" = "Y1"
        // [THEN] Purchase Order "PRO2" line has "Quantity Invoiced" = "Y2"
        VerifyPurchLineInvoicedQty(SalesHeader[1], OriginalPurchaseHeader[1]);
        VerifyPurchLineInvoicedQty(SalesHeader[2], OriginalPurchaseHeader[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesDocErrorWhenItemWithEmptyCommonItemNo()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
    begin
        // [FEATURE] [Sales] [Common Item]
        // [SCENARIO 372241] Sales document error is shown when using item with empty "Common Item No." for IC Partner with Common Item Outbnd Type
        Initialize();

        // [GIVEN] Sales document for IC Partner with Common Item Outbnd Type
        // [WHEN] Validate Sales Line Item "No."='X', where 'X' - item with Item."Common Item No."=''
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddSalesDocsPost();
        LibraryLowerPermissions.AddO365Setup();
        asserterror CreateSalesDocument(
            SalesHeader, SalesHeader."Document Type"::Order,
            CreateICCustomer(CreateICPartnerWithCommonItemOutbndType()), CreateItem());

        // [THEN] Error occurs: "Common Item No." must be filled
        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError(Item.FieldCaption("Common Item No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchDocErrorWhenItemWithEmptyCommonItemNo()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
    begin
        // [FEATURE] [Purchases] [Common Item]
        // [SCENARIO 372241] Purchase document error is shown when using item with empty "Common Item No." for IC Partner with Common Item Outbnd Type
        Initialize();

        // [GIVEN] Purchase document for IC Partner with Common Item Outbnd Type
        // [WHEN] Validate Purchase Line Item "No."='X', where 'X' - item with Item."Common Item No."=''
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddPurchDocsPost();
        LibraryLowerPermissions.AddO365Setup();
        asserterror CreatePurchaseDocument(
            PurchaseHeader, PurchaseHeader."Document Type"::Order,
            CreateICVendor(CreateICPartnerWithCommonItemOutbndType()), CreateItem());

        // [THEN] Error occurs: "Common Item No." must be filled
        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError(Item.FieldCaption("Common Item No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OutboxSalesLineCommonItemNo()
    var
        SalesHeader: Record "Sales Header";
        ItemNo: Code[20];
        CommonItemNo: Code[20];
    begin
        // [FEATURE] [Sales] [Common Item]
        // [SCENARIO 372241] IC Outbox Sales Line has "IC Partner Reference"=Item."Common Item No." when send Sales document for IC Partner with Common Item Outbnd Type
        Initialize();
        ItemNo := CreateItem();
        CommonItemNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Sales document for IC Partner with Common Item Outbnd Type
        // [GIVEN] Sales Line Item "No."='X', where 'X' - item with Item."Common Item No."='Y'
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddSalesDocsPost();
        LibraryLowerPermissions.AddO365Setup();
        UpdateCommonItemNo(ItemNo, CommonItemNo);
        CreateSalesDocument(
          SalesHeader, SalesHeader."Document Type"::Order,
          CreateICCustomer(CreateICPartnerWithCommonItemOutbndType()), ItemNo);

        // [WHEN] Send Sales document to IC Partner
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();
        ICInboxOutboxMgt.SendSalesDoc(SalesHeader, false);

        // [THEN] "IC Outbox Sales Line"."IC Partner Reference" = 'Y'
        VerifyOutboxSalesLineCommonItem(SalesHeader."No.", CommonItemNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OutboxPurchLineCommonItemNo()
    var
        PurchaseHeader: Record "Purchase Header";
        ItemNo: Code[20];
        CommonItemNo: Code[20];
    begin
        // [FEATURE] [Purchases] [Common Item]
        // [SCENARIO 372241] IC Outbox Purchase Line has "IC Partner Reference"=Item."Common Item No." when send Purchase document for IC Partner with Common Item Outbnd Type
        Initialize();
        ItemNo := CreateItem();
        CommonItemNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Purchase document for IC Partner with Common Item Outbnd Type
        // [GIVEN] Purchase Line Item "No."='X', where 'X' - item with Item."Common Item No."='Y'
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddPurchDocsPost();
        LibraryLowerPermissions.AddO365Setup();
        UpdateCommonItemNo(ItemNo, CommonItemNo);
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseHeader."Document Type"::Order,
          CreateICVendor(CreateICPartnerWithCommonItemOutbndType()), ItemNo);

        // [WHEN] Send Purchase document to IC Partner
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();
        ICInboxOutboxMgt.SendPurchDoc(PurchaseHeader, false);

        // [THEN] "IC Outbox Purchase Line"."IC Partner Reference" = 'Y'
        VerifyOutboxPurchLineCommonItem(PurchaseHeader."No.", CommonItemNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReceivedPurchDocErrorWhenItemDoesntHaveCommonItemNo()
    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICInboxTransaction: Record "IC Inbox Transaction";
        ICInboxPurchaseHeader: Record "IC Inbox Purchase Header";
        ICPartnerCode: Code[20];
        VendorNo: Code[20];
        ItemNo: Code[20];
        CommonItemNo: Code[20];
    begin
        // [FEATURE] [Sales] [Purchases] [Common Item]
        // [SCENARIO 372241] Error occurs when receiving Purchase document from IC Partner with Common Item Outbnd Type and there is no Item related to the Common Item No.
        Initialize();
        ICPartnerCode := CreateICPartnerWithCommonItemOutbndType();
        VendorNo := CreateICVendor(ICPartnerCode);
        ItemNo := CreateItem();
        CommonItemNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Sales document for IC Partner with Common Item Outbnd Type
        // [GIVEN] Sales Line Item "No."='X', where 'X' - item with Item."Common Item No."='Y'
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddSalesDocsCreate();
        LibraryLowerPermissions.AddO365Setup();
        UpdateCommonItemNo(ItemNo, CommonItemNo);
        CreateSalesDocument(
          SalesHeader, SalesHeader."Document Type"::Order,
          CreateICCustomer(ICPartnerCode), ItemNo);

        // [GIVEN] Send Sales document to IC Partner
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();
        SendICSalesDocument(
          SalesHeader, ICPartnerCode, ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader);

        // [GIVEN] Clear "Common Item No." for all items on receiving side
        UpdateCommonItemNo(ItemNo, '');
        LibraryLowerPermissions.AddPurchDocsCreate();
        // [WHEN] Receive Purchase document from IC Partner
        asserterror ReceiveICPurchaseDocument(
            PurchaseHeader, SalesHeader, ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader, VendorNo);

        // [THEN] Error occurs: "There is no Item related to Common Item No. 'Y'"
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(NoItemForCommonItemErr, CommonItemNo));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReceivedSalesDocErrorWhenItemDoesntHaveCommonItemNo()
    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICInboxTransaction: Record "IC Inbox Transaction";
        ICInboxSalesHeader: Record "IC Inbox Sales Header";
        ICPartnerCode: Code[20];
        CustomerNo: Code[20];
        ItemNo: Code[20];
        CommonItemNo: Code[20];
    begin
        // [FEATURE] [Purchases] [Sales] [Common Item]
        // [SCENARIO 372241] Error occurs when receiving Sales document from IC Partner with Common Item Outbnd Type and there is no Item related to the Common Item No.
        Initialize();
        ICPartnerCode := CreateICPartnerWithCommonItemOutbndType();
        CustomerNo := CreateICCustomer(ICPartnerCode);
        ItemNo := CreateItem();
        CommonItemNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Purchase document for IC Partner with Common Item Outbnd Type
        // [GIVEN] Purchase Line Item "No."='X', where 'X' - item with Item."Common Item No."='Y'
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddPurchDocsCreate();
        LibraryLowerPermissions.AddO365Setup();
        UpdateCommonItemNo(ItemNo, CommonItemNo);
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseHeader."Document Type"::Order,
          CreateICVendor(ICPartnerCode), ItemNo);

        // [GIVEN] Send Purchase document to IC Partner
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();
        SendICPurchaseDocument(
          PurchaseHeader, ICPartnerCode, ICOutboxTransaction, ICInboxTransaction, ICInboxSalesHeader);

        // [GIVEN] Clear "Common Item No." for all items on receiving side
        UpdateCommonItemNo(ItemNo, '');

        // [WHEN] Receive Sales document from IC Partner
        LibraryLowerPermissions.AddSalesDocsCreate();
        asserterror ReceiveICSalesDocument(
            SalesHeader, PurchaseHeader, ICOutboxTransaction, ICInboxTransaction, ICInboxSalesHeader, CustomerNo);

        // [THEN] Error occurs: "There is no Item related to Common Item No. 'Y'"
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(NoItemForCommonItemErr, CommonItemNo));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReceivedPurchDocWithCommonItemNo()
    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICInboxTransaction: Record "IC Inbox Transaction";
        ICInboxPurchaseHeader: Record "IC Inbox Purchase Header";
        ICPartnerCode: Code[20];
        VendorNo: Code[20];
        ItemNo: Code[20];
        CommonItemNo: Code[20];
    begin
        // [FEATURE] [Sales] [Purchases] [Common Item]
        // [SCENARIO 372241] Received Purchase Line's Item has Common Item No. when using IC Partner with Common Item Outbnd Type
        Initialize();
        ICPartnerCode := CreateICPartnerWithCommonItemOutbndType();
        VendorNo := CreateICVendor(ICPartnerCode);
        ItemNo := CreateItem();
        CommonItemNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Sales document for IC Partner with Common Item Outbnd Type
        // [GIVEN] Sales Line Item "No."='X', where 'X' - item with Item."Common Item No."=Y
        // [GIVEN] Send Sales document to IC Partner
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddSalesDocsCreate();
        LibraryLowerPermissions.AddO365Setup();
        UpdateCommonItemNo(ItemNo, CommonItemNo);
        CreateSalesDocument(
          SalesHeader, SalesHeader."Document Type"::Order,
          CreateICCustomer(ICPartnerCode), ItemNo);
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();
        SendICSalesDocument(
          SalesHeader, ICPartnerCode, ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader);

        // [WHEN] Receive Purchase document from IC Partner
        LibraryLowerPermissions.AddPurchDocsCreate();
        ReceiveICPurchaseDocument(
          PurchaseHeader, SalesHeader, ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader, VendorNo);

        // [THEN] Received Purchase Line has Item with Item."Common Item No."='Y'
        FindPurchLine(PurchaseLine, PurchaseHeader);
        Assert.AreEqual(ItemNo, PurchaseLine."No.", PurchaseLine.FieldCaption("No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReceivedSalesDocWithCommonItemNo()
    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        SalesLine: Record "Sales Line";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICInboxTransaction: Record "IC Inbox Transaction";
        ICInboxSalesHeader: Record "IC Inbox Sales Header";
        ICPartnerCode: Code[20];
        CustomerNo: Code[20];
        ItemNo: Code[20];
        CommonItemNo: Code[20];
    begin
        // [FEATURE] [Purchases] [Sales] [Common Item]
        // [SCENARIO 372241] Received Sales Line's Item has Common Item No. when using IC Partner with Common Item Outbnd Type
        Initialize();
        ICPartnerCode := CreateICPartnerWithCommonItemOutbndType();
        CustomerNo := CreateICCustomer(ICPartnerCode);
        ItemNo := CreateItem();
        CommonItemNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Purchase document for IC Partner with Common Item Outbnd Type
        // [GIVEN] Purchase Line Item "No."='X', where 'X' - item with Item."Common Item No."=Y
        // [GIVEN] Send Purchase document to IC Partner
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddPurchDocsCreate();
        LibraryLowerPermissions.AddO365Setup();
        UpdateCommonItemNo(ItemNo, CommonItemNo);
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseHeader."Document Type"::Order,
          CreateICVendor(ICPartnerCode), ItemNo);
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();
        SendICPurchaseDocument(
          PurchaseHeader, ICPartnerCode, ICOutboxTransaction, ICInboxTransaction, ICInboxSalesHeader);

        // [WHEN] Receive Sales document from IC Partner
        LibraryLowerPermissions.AddSalesDocsCreate();
        ReceiveICSalesDocument(
          SalesHeader, PurchaseHeader, ICOutboxTransaction, ICInboxTransaction, ICInboxSalesHeader, CustomerNo);

        // [THEN] Received Purchase Line has Item with Item."Common Item No."='Y'
        FindSalesLine(SalesLine, SalesHeader);
        Assert.AreEqual(ItemNo, SalesLine."No.", SalesLine.FieldCaption("No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReceivedPurchDocWithInboxTypeFileLocation()
    var
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICInboxTransaction: Record "IC Inbox Transaction";
        ICInboxSalesHeader: Record "IC Inbox Sales Header";
        VendorNo: Code[20];
        CustomerNo: Code[20];
        ICPartnerCodeVendor: Code[20];
        ICPartnerCodeCustomer: Code[20];
    begin
        // [FEATURE] [Purchases] [Sales]
        // [SCENARIO 375057] Import IC Transaction file for IC Partner with Inbox Type = "File Location"
        Initialize();

        // [GIVEN] Vendor and Customer with IC Partner Code with Inbox Type = "File Location"
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddPurchDocsCreate();
        LibraryLowerPermissions.AddO365Setup();
        ICPartnerCodeVendor := CreateICPartnerWithInboxTypeFileLocation();
        VendorNo := CreateICVendor(ICPartnerCodeVendor);
        ICPartnerCodeCustomer := CreateICPartner();
        CustomerNo := CreateICCustomer(ICPartnerCodeCustomer);

        // [GIVEN] Company Information IC Partner Code = Vendor IC Partner Code
        SetCompanyICPartner(ICPartnerCodeVendor);

        // [GIVEN] Send Purchase document to IC Partner
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseHeader."Document Type"::Order,
          VendorNo, CreateItem());
        LibraryLowerPermissions.AddSalesDocsCreate();
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();
        SendICPurchaseDocument(
          PurchaseHeader, ICPartnerCodeCustomer, ICOutboxTransaction, ICInboxTransaction, ICInboxSalesHeader);

        // [WHEN] Receive Sales document from IC Partner
        ReceiveICSalesDocument(
          SalesHeader, PurchaseHeader, ICOutboxTransaction, ICInboxTransaction,
          ICInboxSalesHeader, CustomerNo);

        // [THEN] Sales Document is created
        Assert.IsTrue(
          SalesHeader.Get(SalesHeader."Document Type"::Order, SalesHeader."No."),
          SalesHeader.TableCaption());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICPartnerReferenceInPurchaseInvoiceLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GLAccount: Record "G/L Account";
        ICPartnerCode: Code[20];
    begin
        // [FEATURE] [UT] [Purchase]
        // [SCENARIO 375321] Validating Unit of Measure Code in Purchase Line job should not change IC Partner Reference

        // [GIVEN] Purchase Line where "No." is "G" and "IC Partner Reference" is 'X'
        LibraryLowerPermissions.SetIntercompanyPostingsEdit();
        LibraryLowerPermissions.AddPurchDocsCreate();
        LibraryLowerPermissions.AddO365Setup();
        LibraryLowerPermissions.AddIntercompanyPostingsSetup();
        ICPartnerCode := CreateICPartner();
        CreateICGLAccountWithDefaultICPartnerGLAccNo(GLAccount);
        CreatePurchInvWithGLAccount(PurchaseHeader, GLAccount, ICPartnerCode);
        PurchaseHeader."Send IC Document" := true;
        PurchaseHeader.Modify(true);

        // [WHEN] Validate Unit of Measure Code on Purchase Line
        FindPurchLine(PurchaseLine, PurchaseHeader);
        PurchaseLine.Validate("Unit of Measure Code");

        // [THEN] IC Partner Reference in Purchase Line is 'X'
        PurchaseLine.TestField("IC Partner Reference", GLAccount."Default IC Partner G/L Acc. No");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICPartnerReferenceInSalesInvoiceLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GLAccount: Record "G/L Account";
        ICPartnerCode: Code[20];
    begin
        // [FEATURE] [UT] [Sales]
        // [SCENARIO 375321] Validating Unit of Measure Code in Sales Line job should not change IC Partner Reference

        // [GIVEN] Sales Line where "No." is "G" and "IC Partner Reference" is 'X'
        LibraryLowerPermissions.SetIntercompanyPostingsEdit();
        LibraryLowerPermissions.AddSalesDocsCreate();
        LibraryLowerPermissions.AddO365Setup();
        LibraryLowerPermissions.AddIntercompanyPostingsSetup();
        ICPartnerCode := CreateICPartner();
        CreateICGLAccountWithDefaultICPartnerGLAccNo(GLAccount);
        CreateSalesInvWithGLAccount(SalesHeader, GLAccount, ICPartnerCode);
        SalesHeader."Bill-to IC Partner Code" := ICPartnerCode;
        SalesHeader."Send IC Document" := true;
        SalesHeader.Modify(true);

        // [WHEN] Validate Unit of Measure Code on Sales Line
        FindSalesLine(SalesLine, SalesHeader);
        SalesLine.Validate("Unit of Measure Code");

        // [THEN] IC Partner Reference in Sales Line is 'X'
        SalesLine.TestField("IC Partner Reference", GLAccount."Default IC Partner G/L Acc. No");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostReceivedPurchInvoiceAfterSentSalesInvoiceWithExternalDocNo()
    var
        ReceivedPurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICInboxTransaction: Record "IC Inbox Transaction";
        ICInboxPurchaseHeader: Record "IC Inbox Purchase Header";
        ICPartnerCodeVendor: Code[20];
        VendorNo: Code[20];
        CustomerNo: Code[20];
        SalesInvoiceNo: Code[20];
        PurchInvoiceNo: Code[20];
    begin
        // [FEATURE] [Purchases] [Sales]
        // [SCENARIO 378146] Received purchase invoice posted after sending sales invoice with external document number
        Initialize();
        ICPartnerCodeVendor := CreateICPartner();
        VendorNo := CreateICVendor(ICPartnerCodeVendor);
        CustomerNo := CreateICCustomer(CreateICPartner());

        // [GIVEN] Created and posted Sales Invoice "SI" with External Document No.
        CreateSalesDocument(
          SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo, CreateItem());
        UpdateSalesDocumentExternalDocumentNo(SalesHeader, ReceivedPurchaseHeader."No.");
        SalesInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Sent Sales Invoice "SI". Received Purchase Invoice "PI".
        LibraryLowerPermissions.SetIntercompanyPostingsEdit();
        LibraryLowerPermissions.AddPurchDocsPost();
        LibraryLowerPermissions.AddSalesDocsPost();
        SendICSalesInvoice(ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader, SalesInvoiceNo, ICPartnerCodeVendor);
        ReceiveICPurchaseInvoice(
          ReceivedPurchaseHeader, ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader, SalesInvoiceNo, VendorNo);

        // [WHEN] Post received Purchase Invoice "PI".
        PurchInvoiceNo := LibraryPurchase.PostPurchaseDocument(ReceivedPurchaseHeader, true, true);

        // [THEN] Document posted successfuly
        PurchInvHeader.Init();
        PurchInvHeader.SetRange("No.", PurchInvoiceNo);
        Assert.RecordIsNotEmpty(PurchInvHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostReceivedPurchCrMemoAfterSentSalesCrMemoWithExternalDocNo()
    var
        ReceivedPurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICInboxTransaction: Record "IC Inbox Transaction";
        ICInboxPurchaseHeader: Record "IC Inbox Purchase Header";
        ICPartnerCodeVendor: Code[20];
        VendorNo: Code[20];
        CustomerNo: Code[20];
        SalesCreditMemoNo: Code[20];
        PurchCreditMemoNo: Code[20];
    begin
        // [FEATURE] [Purchases] [Sales]
        // [SCENARIO 378146] Received purchase credit memo posted after sending sales credit memo with external document number
        Initialize();
        ICPartnerCodeVendor := CreateICPartner();
        VendorNo := CreateICVendor(ICPartnerCodeVendor);
        CustomerNo := CreateICCustomer(CreateICPartner());

        // [GIVEN] Created and posted Sales Credit Memo "SCM" with External Document No.
        CreateSalesDocument(
          SalesHeader, SalesHeader."Document Type"::"Credit Memo", CustomerNo, CreateItem());
        UpdateSalesDocumentExternalDocumentNo(SalesHeader, SalesHeader."No.");
        SalesCreditMemoNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Sent Credit Memo "SCM". Received Purchase Credit Memo "PCM".
        LibraryLowerPermissions.SetIntercompanyPostingsEdit();
        LibraryLowerPermissions.AddPurchDocsPost();
        LibraryLowerPermissions.AddSalesDocsPost();
        SendICSalesCrMemo(ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader, SalesCreditMemoNo, ICPartnerCodeVendor);
        ReceiveICPurchaseCrMemo(
          ReceivedPurchaseHeader, ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader, SalesCreditMemoNo, VendorNo);

        // [WHEN] Post received Purchase Credit Memo "PCM".
        PurchCreditMemoNo := LibraryPurchase.PostPurchaseDocument(ReceivedPurchaseHeader, true, true);

        // [THEN] Document posted successfuly
        PurchCrMemoHdr.Init();
        PurchCrMemoHdr.SetRange("No.", PurchCreditMemoNo);
        Assert.RecordIsNotEmpty(PurchCrMemoHdr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerICPartnerCodeUpdateWithOpenEntries()
    var
        Customer: Record Customer;
        ICPartnerCode: Code[20];
        PostingDate: Date;
    begin
        // [FEATURE] [UT] [Sales] [Intercompany] [Accounting Period]
        // [Scenario 378300] Update IC Partner Code of Customer with open entries within a fiscal year

        // [GIVEN] Set Customer and IC Partner
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddSalesDocsCreate();
        LibraryLowerPermissions.AddO365Setup();
        ICPartnerCode := CreateICPartner();
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Opened Customer Ledger Entry within current Accounting Period
        PostingDate := LibraryFiscalYear.IdentifyOpenAccountingPeriod();
        CreateCustLedgEntry(Customer."No.", PostingDate, true);

        // [WHEN] Validate IC Partner Code on Customer
        asserterror Customer.Validate("IC Partner Code", ICPartnerCode);

        // [THEN] Error occurs: You cannot change the contents of the IC Partner Code field because ...
        Assert.ExpectedError(StrSubstNo(ICPartnerCodeModifyErr, Customer.FieldCaption("IC Partner Code"), Customer.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ComfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure CustomerICPartnerCodeUpdateWithClosedEntries()
    var
        Customer: Record Customer;
        CustomerICPartnerCode: Code[20];
        ICPartnerCode: Code[20];
        PostingDate: Date;
    begin
        // [FEATURE] [UT] [Sales] [Intercompany] [Accounting Period]
        // [Scenario 378300] Update IC Partner Code of Customer with closed entries within a fiscal year

        // [GIVEN] Set Customer with IC Partner Code = 'X' and IC Partner
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddO365Setup();
        LibraryLowerPermissions.AddSalesDocsCreate();
        ICPartnerCode := CreateICPartner();
        LibrarySales.CreateCustomer(Customer);
        CustomerICPartnerCode := Customer."IC Partner Code";

        // [GIVEN] Closed Customer Ledger Entry within current Accounting Period
        PostingDate := LibraryFiscalYear.IdentifyOpenAccountingPeriod();
        CreateCustLedgEntry(Customer."No.", PostingDate, false);

        // [WHEN] Validate IC Partner Code on Customer with not confirmed question
        Customer.Validate("IC Partner Code", ICPartnerCode);

        // [THEN] Customer."IC Partner Code" = 'X'
        Customer.Find();
        Customer.TestField("IC Partner Code", CustomerICPartnerCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorICPartnerCodeUpdateWithOpenEntries()
    var
        Vendor: Record Vendor;
        ICPartnerCode: Code[20];
        PostingDate: Date;
    begin
        // [FEATURE] [UT] [Purchase] [Intercompany] [Accounting Period]
        // [Scenario 378300] Update IC Partner Code of Vendor with open entries within a fiscal year

        // [GIVEN] Set Vendor and IC Partner
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddO365Setup();
        LibraryLowerPermissions.AddPurchDocsPost();
        ICPartnerCode := CreateICPartner();
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Opened Vendor Ledger Entry within current Accounting Period
        PostingDate := LibraryFiscalYear.IdentifyOpenAccountingPeriod();
        CreateVendorLedgEntry(Vendor."No.", PostingDate, true);

        // [WHEN] Validate IC Partner Code of Vendor
        asserterror Vendor.Validate("IC Partner Code", ICPartnerCode);

        // [THEN] Error occurs: You cannot change the contents of the IC Partner Code field because ...
        Assert.ExpectedError(StrSubstNo(ICPartnerCodeModifyErr, Vendor.FieldCaption("IC Partner Code"), Vendor.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ComfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure VendorICPartnerCodeUpdateWithClosedEntries()
    var
        Vendor: Record Vendor;
        VendorICPartnerCode: Code[20];
        ICPartnerCode: Code[20];
        PostingDate: Date;
    begin
        // [FEATURE] [UT] [Purchase] [Intercompany] [Accounting Period]
        // [Scenario 378300] Update IC Partner Code of Vendor with closed entries within a fiscal year

        // [GIVEN] Set Customer with IC Partner Code = 'X' and IC Partner
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddPurchDocsPost();
        LibraryLowerPermissions.AddO365Setup();
        ICPartnerCode := CreateICPartner();
        LibraryPurchase.CreateVendor(Vendor);
        VendorICPartnerCode := Vendor."IC Partner Code";

        // [GIVEN] Closed Vendor Ledger Entry within current Accounting Period
        PostingDate := LibraryFiscalYear.IdentifyOpenAccountingPeriod();
        CreateVendorLedgEntry(Vendor."No.", PostingDate, false);

        // [WHEN] Validate IC Partner Code on Vendor with not confirmed question
        Vendor.Validate("IC Partner Code", ICPartnerCode);

        // [THEN] Vendor."IC Partner Code" = 'X'
        Vendor.Find();
        Vendor.TestField("IC Partner Code", VendorICPartnerCode);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostReceivedPurchInvoice_WideExternalDocNo_ConfirmAccept()
    var
        ICInboxTransaction: Record "IC Inbox Transaction";
    begin
        // [FEATURE] [Purchases]
        // [SCENARIO 379411] There is no error when accept Purchase Invoice in case of long "External Document No."

        Initialize();

        // [GIVEN] Sales Invoice with 35 char length of "External Document No."
        // [GIVEN] Post, send Sales Invoice. Receive Purchase Invoice
        // [GIVEN] Post Purchase Invoice
        LibraryLowerPermissions.SetIntercompanyPostingsEdit();
        LibraryLowerPermissions.AddO365Setup();
        LibraryLowerPermissions.AddPurchDocsPost();
        LibraryLowerPermissions.AddIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddSalesDocsPost();
        PostReceivedPurchInvoice_WideExternalDocNo(ICInboxTransaction);

        // [WHEN] Waiting confirm about about Transaction exists in Purch. Inv. Header
        ICInboxTransaction.Validate("Line Action", ICInboxTransaction."Line Action"::Accept);

        // [THEN] User choosed "Accept"
        Assert.AreEqual(ICInboxTransaction."Line Action", ICInboxTransaction."Line Action"::Accept, '');
    end;

    [Test]
    [HandlerFunctions('ComfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure PostReceivedPurchInvoice_WithWideExternalDocNo_ConfirmReject()
    var
        ICInboxTransaction: Record "IC Inbox Transaction";
    begin
        // [FEATURE] [Purchases]
        // [SCENARIO 379411] There is no error when reject Purchase Invoice in case of long "External Document No."

        Initialize();

        // [GIVEN] Sales Invoice with 35 char length of "External Document No."
        // [GIVEN] Post, send Sales Invoice. Receive Purchase Invoice
        // [GIVEN] Post received Purchase Invoice
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();
        LibraryLowerPermissions.AddO365Setup();
        LibraryLowerPermissions.AddSalesDocsPost();
        LibraryLowerPermissions.AddPurchDocsPost();
        PostReceivedPurchInvoice_WideExternalDocNo(ICInboxTransaction);

        // [WHEN] Waiting confirm about about Transaction exists in Purch. Inv. Header
        ICInboxTransaction.Validate("Line Action", ICInboxTransaction."Line Action"::Accept);

        // [THEN] User choosed "NotAccept"
        Assert.AreEqual(ICInboxTransaction."Line Action", ICInboxTransaction."Line Action"::"No Action", '');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ExportImportICTransaction_WideExternalDocumentNo_Message()
    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICInboxTransaction: Record "IC Inbox Transaction";
        ICInboxPurchaseHeader: Record "IC Inbox Purchase Header";
        ICPartnerVendorCode: Code[20];
        VendorNo: Code[20];
        CustomerNo: Code[20];
        SalesInvoiceNo: Code[20];
    begin
        // [FEATURE] [Purchases]
        // [SCENARIO 379411] Message is shown when receive Purchase Invoice the second time in case of long "External Document No."

        Initialize();

        CreatePartnerCustomerVendor(ICPartnerVendorCode, VendorNo, CustomerNo);
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo, CreateItem());

        // [GIVEN] Sales Invoice with 35 char length of "External Document No."
        LibraryLowerPermissions.SetSalesDocsPost();
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();
        UpdateSalesDocumentExternalDocumentNo(SalesHeader, GenerateExternalDocumentNo());

        // [GIVEN] Post, send Sales Invoice.
        SalesInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        LibraryLowerPermissions.AddPurchDocsPost();
        SendICSalesInvoice(ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader, SalesInvoiceNo, ICPartnerVendorCode);

        // [GIVEN] Receive Purchase Invoice
        ReceiveICPurchaseInvoice(
          PurchaseHeader, ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader, SalesInvoiceNo, VendorNo);

        // [GIVEN] Checking Your Reference of Purch. Header
        PurchaseHeader.TestField("Your Reference", SalesHeader."External Document No.");

        // [WHEN] Waiting confirm about about Transaction exists in Purch. Inv. Header
        ICInboxTransaction.Validate("Line Action", ICInboxTransaction."Line Action"::Accept);

        // [THEN] User choosed "Accept"
        Assert.AreEqual(ICInboxTransaction."Line Action", ICInboxTransaction."Line Action"::Accept, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICStatusNewAfterCopyOfSentPurchDoc()
    var
        PurchaseHeader: Record "Purchase Header";
        ToPurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchases]
        // [SCENARIO 379748] Purchase Document "IC Status" = "New" after copy of sent Purchase Document to IC Partner
        Initialize();

        // [GIVEN] Purchase document
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseHeader."Document Type"::Order,
          CreateICVendor(CreateICPartner()), CreateItem());

        // [GIVEN] Send Purchase document to IC Partner
        ICInboxOutboxMgt.SendPurchDoc(PurchaseHeader, false);

        // [GIVEN] A new Purchase Document
        LibraryPurchase.CreatePurchHeader(ToPurchaseHeader, ToPurchaseHeader."Document Type"::Order, CreateICVendor(CreateICPartner()));

        // [WHEN] Copy the sent document into new one
        LibraryLowerPermissions.SetPurchDocsPost();
        LibraryLowerPermissions.AddO365Setup();
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();
        CopyPurchaseDocument("Purchase Document Type From"::Order, PurchaseHeader, ToPurchaseHeader);

        // [THEN] New Purchase Document "IC Status" = "New"
        ToPurchaseHeader.Find();
        Assert.AreEqual(
          ToPurchaseHeader."IC Status",
          ToPurchaseHeader."IC Status"::New,
          StrSubstNo(TableFieldErr, ToPurchaseHeader.TableCaption(), ToPurchaseHeader.FieldCaption("IC Status")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlankPurchLineReceiptNoAfterSendSalesInvoiceFromGetShptLines()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICInboxTransaction: Record "IC Inbox Transaction";
        ICInboxPurchaseHeader: Record "IC Inbox Purchase Header";
        ICPartnerCode: Code[20];
        VendorNo: Code[20];
        CustomerNo: Code[20];
    begin
        // [SCENARIO 380888] Received Purchase "Receipt No." and "Receipt Line No." are blank after send Sales Invoice from get shipment lines
        Initialize();

        CreatePartnerCustomerVendor(ICPartnerCode, VendorNo, CustomerNo);

        // [GIVEN] Ship Sales Order
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo, LibraryInventory.CreateItemNo());
        LibrarySales.PostSalesDocument(SalesHeader, true, false); // ship, no invoice

        // [GIVEN] Get Sales Invoice from Shippment Lines then Post
        CreateSalesInvoiceWithGetShipmentLines(SalesInvoiceHeader, CustomerNo);
        SalesInvoiceHeader."No." := LibrarySales.PostSalesDocument(SalesInvoiceHeader, false, true); // No ship, invoice

        // [WHEN] Send Sales Invoice to IC Partner
        LibraryLowerPermissions.SetPurchDocsCreate();
        LibraryLowerPermissions.AddSalesDocsCreate();
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();
        SendICSalesDocument(
          SalesInvoiceHeader, ICPartnerCode, ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader);
        ReceiveICPurchaseDocument(
          PurchaseHeader, SalesInvoiceHeader, ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader, VendorNo);

        // [THEN] "Receipt No." and "Receipt Line No." of Purchase Document are to be blank.
        FindPurchLine(PurchaseLine, PurchaseHeader);
        PurchaseLine.TestField("Receipt No.", '');
        PurchaseLine.TestField("Receipt Line No.", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlankPurchLineReturnShipmentNoAfterSendSalesCrMemoFromGetReceiptLines()
    var
        SalesHeader: Record "Sales Header";
        SalesHeaderCrMemo: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICInboxTransaction: Record "IC Inbox Transaction";
        ICInboxPurchaseHeader: Record "IC Inbox Purchase Header";
        ICPartnerCode: Code[20];
        VendorNo: Code[20];
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 204189] Shipped purchase "Return Shipment No." and "Return Shipment Line No." fields should be blank after Sales Credit Memo created by Get Receipt Lines is sent.
        Initialize();
        CreatePartnerCustomerVendor(ICPartnerCode, VendorNo, CustomerNo);

        // [GIVEN] Sales Return Order is received.
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::"Return Order", CustomerNo, LibraryInventory.CreateItemNo());
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [GIVEN] Sales Credit Memo is created via Get Receipt Lines and posted.
        CreateSalesCrMemoWithGetRetReceiptLines(SalesHeaderCrMemo, CustomerNo);
        SalesHeaderCrMemo."No." := LibrarySales.PostSalesDocument(SalesHeaderCrMemo, false, true);

        // [WHEN] Send Sales Credit Memo to IC Partner and receive it as Purchase Credit Memo.
        LibraryLowerPermissions.SetSalesDocsCreate();
        LibraryLowerPermissions.AddPurchDocsCreate();
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();
        SendICSalesDocument(
          SalesHeaderCrMemo, ICPartnerCode, ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader);
        ReceiveICPurchaseDocument(
          PurchaseHeader, SalesHeaderCrMemo, ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader, VendorNo);

        // [THEN] "Return Shipment No." and "Return Shipment Line No." on the Purchase Credit Memo line are blank.
        FindPurchLine(PurchaseLine, PurchaseHeader);
        PurchaseLine.TestField("Return Shipment No.", '');
        PurchaseLine.TestField("Return Shipment Line No.", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LCYCodeFromGenLedgSetupIsNotAssignedToICOutboxSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        GeneralLedgerSetup: Record "General Ledger Setup";
        CustomerNo: Code[20];
        ICPartnerCode: array[2] of Code[20];
        InvNo: Code[20];
    begin
        // [FEATURE] [Sales] [Currency] [Invoice]
        // [SCENARIO 382323] Currency code is blank in IC Outbox Sales Header for Sales Order if "LCY Code" in General Ledger Setup is defined

        Initialize();

        // [GIVEN] LCY Code is 'X' in General Ledger Setup
        UpdateLCYCodeInGLSetup();

        // [GIVEN] Two Companies, where "IC Partner Code" are "A" and "B"
        // [GIVEN] IC Partner "A", where "Inbox Type" is "File Location"
        ICPartnerCode[1] := CreateICPartnerWithInboxTypeFileLocation();
        ICPartnerCode[2] := CreateICPartner();

        // [GIVEN] Company Information "B", where "IC Partner Code" = "B"
        SetCompanyICPartner(ICPartnerCode[2]);

        // [GIVEN] Customer with "IC Partner Code" is "A"
        CustomerNo := CreateICCustomer(ICPartnerCode[1]);

        // [WHEN] Post Sales Order
        LibraryLowerPermissions.SetSalesDocsPost();
        LibraryLowerPermissions.AddO365Setup();
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();
        CreateSalesDocument(
          SalesHeader, SalesHeader."Document Type"::Order, CustomerNo, CreateItem());
        InvNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        GeneralLedgerSetup.Get();

        // [THEN] IC Outbox Sales Header for Sales Order has blank "Currency Code"
        VerifyCurrencyCodeInICOutboxSalesHeader(ICPartnerCode[1], SalesHeader."No.", GeneralLedgerSetup."LCY Code");

        // [THEN] IC Outbox Sales Header for Posted Invoice has blank "Currency Code"
        VerifyCurrencyCodeInICOutboxSalesHeader(ICPartnerCode[1], InvNo, GeneralLedgerSetup."LCY Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LCYCodeFromGenLedgSetupIsNotAssignedToICOutboxSalesCrMemo()
    var
        SalesHeader: Record "Sales Header";
        GeneralLedgerSetup: Record "General Ledger Setup";
        CustomerNo: Code[20];
        ICPartnerCode: array[2] of Code[20];
        CrMemoNo: Code[20];
    begin
        // [FEATURE] [Sales] [Currency] [Credit Memo]
        // [SCENARIO 382323] Currency code is blank in IC Outbox Sales Header for Posted Credit Memo if "LCY Code" in General Ledger Setup is defined

        Initialize();

        // [GIVEN] LCY Code is 'X' in General Ledger Setup
        UpdateLCYCodeInGLSetup();

        // [GIVEN] Two Companies, where "IC Partner Code" are "A" and "B"
        // [GIVEN] IC Partner "A", where "Inbox Type" is "File Location"
        ICPartnerCode[1] := CreateICPartnerWithInboxTypeFileLocation();
        ICPartnerCode[2] := CreateICPartner();

        // [GIVEN] Company Information "B", where "IC Partner Code" = "B"
        SetCompanyICPartner(ICPartnerCode[2]);

        // [GIVEN] Customer with "IC Partner Code" is "A"
        CustomerNo := CreateICCustomer(ICPartnerCode[1]);

        // [WHEN] Post Sales Credit Memo
        LibraryLowerPermissions.SetSalesDocsPost();
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();
        LibraryLowerPermissions.AddO365Setup();
        CreateSalesDocument(
          SalesHeader, SalesHeader."Document Type"::"Credit Memo", CustomerNo, CreateItem());
        CrMemoNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        GeneralLedgerSetup.Get();
        // [THEN] IC Outbox Sales Header for Posted Sales Credit Memo has blank "Currency Code"
        VerifyCurrencyCodeInICOutboxSalesHeader(ICPartnerCode[1], CrMemoNo, GeneralLedgerSetup."LCY Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LCYCodeFromGenLedgSetupIsNotAssignedToICOutboxPurchOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        GeneralLedgerSetup: Record "General Ledger Setup";
        VendorNo: Code[20];
        ICPartnerCode: array[2] of Code[20];
    begin
        // [FEATURE] [Purchase] [Currency] [Order]
        // [SCENARIO 382323] Currency code is blank in IC Outbox Purchase Header for Purchase Order if "LCY Code" in General Ledger Setup is defined

        Initialize();

        // [GIVEN] LCY Code is 'X' in General Ledger Setup
        UpdateLCYCodeInGLSetup();

        // [GIVEN] Two Companies, where "IC Partner Code" are "A" and "B"
        // [GIVEN] IC Partner "A", where "Inbox Type" is "File Location"
        ICPartnerCode[1] := CreateICPartnerWithInboxTypeFileLocation();
        ICPartnerCode[2] := CreateICPartner();

        // [GIVEN] Company Information "B", where "IC Partner Code" = "B"
        SetCompanyICPartner(ICPartnerCode[2]);

        // [GIVEN] Vendor with "IC Partner Code" is "A"
        VendorNo := CreateICVendor(ICPartnerCode[1]);

        // [WHEN] Post Purchase Order
        LibraryLowerPermissions.SetPurchDocsPost();
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();
        LibraryLowerPermissions.AddO365Setup();
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo, CreateItem());
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        GeneralLedgerSetup.Get();

        // [THEN] IC Outbox Purchase Header has blank "Currency Code"
        VerifyCurrencyCodeInICOutboxPurchHeader(ICPartnerCode[1], PurchaseHeader."No.", GeneralLedgerSetup."LCY Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LCYCodeFromGenLedgSetupIsNotAssignedToICOutboxGenJnlLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ICOutboxJnlLine: Record "IC Outbox Jnl. Line";
        ICAccountNo: Code[20];
    begin
        // [FEATURE] [Currency] [General Journal]
        // [SCENARIO 382323] Currency code is blank in IC Outbox General Journal Line if "LCY Code" in General Ledger Setup is defined

        Initialize();

        // [GIVEN] LCY Code is 'X' in General Ledger Setup
        UpdateLCYCodeInGLSetup();

        // [GIVEN] General Journal Line for IC Partner with "IC Account No." as Balance Account
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddO365Setup();
        CreateICGeneralJournalLine(GenJournalLine, GenJournalLine."Account Type"::Customer, CreateICCustomer(CreateICPartner()), 1);

        // [WHEN] Post General Journal Line
        LibraryLowerPermissions.SetIntercompanyPostingsEdit();
        LibraryLowerPermissions.AddJournalsPost();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] IC Outbox General Journal Line for Customer has blank "Currency Code"
        FindICOutboxJournalLine(
          ICOutboxJnlLine, GenJournalLine."IC Partner Code", ICOutboxJnlLine."Account Type"::Customer,
          GenJournalLine."Account No.", GenJournalLine."Document No.");
        ICOutboxJnlLine.TestField("Currency Code", '');

        // [THEN] IC Outbox General Journal Line for "IC Account No." has blank "Currency Code"
        ICAccountNo := GenJournalLine."IC Account No.";
        FindICOutboxJournalLine(
          ICOutboxJnlLine, GenJournalLine."IC Partner Code", ICOutboxJnlLine."Account Type"::"G/L Account",
          ICAccountNo, GenJournalLine."Document No.");
        ICOutboxJnlLine.TestField("Currency Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipmentNoForSentSalesOrderIsFilledWithExternalDocNo()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PostedInvoiceNo: Code[20];
    begin
        // [FEATURE] [Sales] [Order]
        // [SCENARIO 204189] Posting the Sales Order should make IC Outbox Sales invoice line with "Shipment No." field populated with "External Document No." and "Shipment Line No." field equal to "Line No.".
        Initialize();

        // [GIVEN] Sales Order with External Document No. 'X' for IC Customer.
        CreateSalesDocumentWithExternalDocNoForICCustomer(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);

        // [WHEN] Post the Sales Order with Ship and Invoice option.
        LibraryLowerPermissions.SetSalesDocsPost();
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();
        PostedInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] IC Outbox Sales line with type = "Invoice" is created.
        // [THEN] "Shipment No." and "Shipment Line No." fields on the line are populated with 'X' and "Line No." respectively.
        VerifyShipmentReceiptNosInICOutboxSalesLine(
          PostedInvoiceNo, "IC Transaction Document Type"::Invoice, "IC Outbox Sales Document Type"::Invoice,
          CopyStr(SalesHeader."External Document No.", 1, 20), SalesLine."Line No.", '', 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReceiptReturnNoForSentSalesOrderIsFilledWithExternalDocNo()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PostedCrMemoNo: Code[20];
    begin
        // [FEATURE] [Sales] [Return Order]
        // [SCENARIO 204189] Posting the Sales Return Order should make IC Outbox Sales credit memo line with "Return Receipt No." field populated with "External Document No." and "Return Receipt Line No." field equal to "Line No.".
        Initialize();

        // [GIVEN] Sales Return Order with External Document No. 'X' for IC Customer.
        CreateSalesDocumentWithExternalDocNoForICCustomer(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order");

        // [WHEN] Post the Sales Return Order with Receive and Invoice option.
        LibraryLowerPermissions.SetSalesDocsPost();
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();
        PostedCrMemoNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] IC Outbox Sales line with type = "Credit Memo" is created.
        // [THEN] "Return Receipt No." and "Return Receipt Line No." fields on the line are populated with 'X' and "Line No." respectively.
        VerifyShipmentReceiptNosInICOutboxSalesLine(
          PostedCrMemoNo, "IC Transaction Document Type"::"Credit Memo", "IC Outbox Sales Document Type"::"Credit Memo",
          '', 0, CopyStr(SalesHeader."External Document No.", 1, 20), SalesLine."Line No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerValidateQuestion')]
    [Scope('OnPrem')]
    procedure PurchaseOrderToPurchaseInvoicePostBothOrderFirst()
    var
        InvoicePurchaseHeader: Record "Purchase Header";
        InvoicePurchaseLine: Record "Purchase Line";
        OrderPurchaseHeader: Record "Purchase Header";
        OrderPurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        VendorNo: Code[20];
        ItemNo: Code[20];
        Quantity: Decimal;
    begin
        // [FEATURE] [Intercompany]
        // [SCENARIO] Duplicate warning when attempting to post both purchase order and invoice from same IC transaction when purchase order is posted first.
        Initialize();

        // [GIVEN] No pre-existing posted purchase invoices
        PurchInvHeader.DeleteAll();

        // [GIVEN] A purchase order and a purchase invoice.
        ItemNo := LibraryInventory.CreateItemNo();
        VendorNo := CreateICVendor(CreateICPartner());
        Quantity := LibraryRandom.RandDec(100, 2);

        LibraryLowerPermissions.SetIntercompanyPostingsEdit();
        LibraryLowerPermissions.AddPurchDocsPost();
        LibraryPurchase.CreatePurchaseDocumentWithItem(InvoicePurchaseHeader, InvoicePurchaseLine,
          InvoicePurchaseHeader."Document Type"::Invoice, VendorNo, ItemNo, Quantity, '', WorkDate());
        LibraryPurchase.CreatePurchaseDocumentWithItem(OrderPurchaseHeader, OrderPurchaseLine,
          OrderPurchaseHeader."Document Type"::Order, VendorNo, ItemNo, Quantity, '', WorkDate());

        // [GIVEN] Purchase invoice was created like this Purchase Order (Company 1) Send-> Sales Order (Company 2) Post-> Purchase Invoice (Company 1)
        InvoicePurchaseHeader."Your Reference" := OrderPurchaseHeader."No.";
        InvoicePurchaseHeader."IC Direction" := InvoicePurchaseHeader."IC Direction"::Incoming;
        InvoicePurchaseHeader."Vendor Order No." :=
          LibraryUtility.GenerateRandomCodeWithLength(
            InvoicePurchaseHeader.FieldNo("Vendor Order No."), DATABASE::"Purchase Header",
            MaxStrLen(InvoicePurchaseHeader."Vendor Order No."));
        InvoicePurchaseHeader.Modify();

        // [WHEN] When posting the order and then the invoice.
        LibraryVariableStorage.Enqueue(PostedInvoiceFromSameTransactionQst);
        LibraryPurchase.PostPurchaseDocument(OrderPurchaseHeader, true, true);
        asserterror LibraryPurchase.PostPurchaseDocument(InvoicePurchaseHeader, true, true);

        // [THEN] The a confirm dialog will be shown, and if the user clicks no, the invoice is not posted
        Assert.RecordCount(PurchInvHeader, 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerValidateQuestion')]
    [Scope('OnPrem')]
    procedure PurchaseOrderToPurchaseInvoicePostBothInvoiceFirst()
    var
        InvoicePurchaseHeader: Record "Purchase Header";
        InvoicePurchaseLine: Record "Purchase Line";
        OrderPurchaseHeader: Record "Purchase Header";
        OrderPurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        VendorNo: Code[20];
        ItemNo: Code[20];
        Quantity: Decimal;
    begin
        // [FEATURE] [Intercompany]
        // [SCENARIO] Duplicate warning when attempting to post both purchase order and invoice from same IC transaction when purchase invoice is posted first.
        Initialize();

        // [GIVEN] No pre-existing posted purchase invoices
        PurchInvHeader.DeleteAll();

        // [GIVEN] A purchase order and a purchase invoice.
        ItemNo := LibraryInventory.CreateItemNo();
        VendorNo := CreateICVendor(CreateICPartner());
        Quantity := LibraryRandom.RandDec(100, 2);

        LibraryLowerPermissions.SetPurchDocsPost();
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();
        LibraryPurchase.CreatePurchaseDocumentWithItem(InvoicePurchaseHeader, InvoicePurchaseLine,
          InvoicePurchaseHeader."Document Type"::Invoice, VendorNo, ItemNo, Quantity, '', WorkDate());
        LibraryPurchase.CreatePurchaseDocumentWithItem(OrderPurchaseHeader, OrderPurchaseLine,
          OrderPurchaseHeader."Document Type"::Order, VendorNo, ItemNo, Quantity, '', WorkDate());

        // [GIVEN] Purchase invoice was created like this Purchase Order (Company 1) Send-> Sales Order (Company 2) Post-> Purchase Invoice (Company 1)
        InvoicePurchaseHeader."IC Direction" := InvoicePurchaseHeader."IC Direction"::Incoming;
        InvoicePurchaseHeader."Your Reference" := OrderPurchaseHeader."No.";
        InvoicePurchaseHeader."Vendor Order No." :=
          LibraryUtility.GenerateRandomCodeWithLength(
            InvoicePurchaseHeader.FieldNo("Vendor Order No."), DATABASE::"Purchase Header",
            MaxStrLen(InvoicePurchaseHeader."Vendor Order No."));
        InvoicePurchaseHeader.Modify();

        // [WHEN] When posting the invoice and then the order.
        LibraryVariableStorage.Enqueue(PostedInvoiceDuplicateQst);
        LibraryPurchase.PostPurchaseDocument(InvoicePurchaseHeader, true, true);
        asserterror LibraryPurchase.PostPurchaseDocument(OrderPurchaseHeader, true, true);

        // [THEN] The a confirm dialog will be shown, and if the user clicks no, the invoice is not posted
        Assert.RecordCount(PurchInvHeader, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TestPermissions(TestPermissions::Disabled)]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceWithReceiptAndItemTracking()
    var
        PurchaseHeaderToSend: Record "Purchase Header";
        PurchaseHeaderToInvoice: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICInboxTransaction: Record "IC Inbox Transaction";
        ICInboxPurchaseHeader: Record "IC Inbox Purchase Header";
        ItemEntryRelation: Record "Item Entry Relation";
        TrackingSpecification: Record "Tracking Specification";
        ICPartnerCodeVendor: Code[20];
        ReceiptNo: Code[20];
    begin
        // [SCENARIO 120476.3] Verify Reservation exists for received Purchase Invoice with related receipt and tracking
        Initialize();

        // [GIVEN] Create Purchase Order. Post Receipt.
        ReceiptNo :=
          CreatePostPurchaseReceiptForNewVendor(
            PurchaseHeaderToSend, PurchaseHeaderToSend."Document Type"::Order, ICPartnerCodeVendor);

        // [GIVEN] Simulate tracking for posted Purchase Receipt
        MockTrackingForItem(DATABASE::"Purch. Rcpt. Line", ReceiptNo);

        // [GIVEN] Mock send-receive purchase order
        MockSendReceivePurchDocument(PurchaseHeaderToSend, SalesHeader, ICPartnerCodeVendor, SalesHeader."Location Code");

        // [GIVEN] Create Sales Order. Send Sales Invoice.
        SendSalesDocumentGetICPurchaseHeader(
          SalesHeader, SalesHeader."Document Type"::Order,
          ICOutboxTransaction, ICInboxTransaction, ICPartnerCodeVendor, ICInboxPurchaseHeader);

        LibraryLowerPermissions.SetPurchDocsPost();
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();
        // [WHEN] Receive Purchase Invoice
        ReceiveICPurchaseDocument(
          PurchaseHeaderToInvoice, SalesHeader, ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader,
          PurchaseHeaderToSend."Buy-from Vendor No.");

        // [THEN] Received Purchase Invoice has related Receipt with Reservation entry
        VerifyReservationEntryExists(PurchaseHeaderToInvoice."Document Type".AsInteger(), PurchaseHeaderToInvoice."No.");
        FindPurchLine(PurchaseLine, PurchaseHeaderToInvoice);
        Assert.AreEqual(
          ReceiptNo,
          PurchaseLine."Receipt No.",
          StrSubstNo(TableFieldErr, PurchaseLine.TableCaption(), PurchaseLine.FieldCaption("Receipt No.")));

        // Cleanup
        LibraryLowerPermissions.SetOutsideO365Scope();
        ItemEntryRelation.DeleteAll();
        TrackingSpecification.DeleteAll();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TestPermissions(TestPermissions::Disabled)]
    [Scope('OnPrem')]
    procedure PurchaseCrMemoWithRetShipmentAndItemTracking()
    var
        PurchaseHeaderToSend: Record "Purchase Header";
        PurchaseHeaderToInvoice: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICInboxTransaction: Record "IC Inbox Transaction";
        ICInboxPurchaseHeader: Record "IC Inbox Purchase Header";
        ICPartnerCodeVendor: Code[20];
        ReturnShipmentNo: Code[20];
    begin
        // [SCENARIO 120476.4] Verify Reservation exists for received Purchase Credit Memo with related Return Shipment and tracking
        Initialize();

        // [GIVEN] Create Purchase Return Order. Post Receipt.
        ReturnShipmentNo :=
          CreatePostPurchaseReceiptForNewVendor(
            PurchaseHeaderToSend, PurchaseHeaderToSend."Document Type"::"Return Order", ICPartnerCodeVendor);

        // [GIVEN] Simulate tracking for posted Purchase Receipt
        MockTrackingForItem(DATABASE::"Return Shipment Line", ReturnShipmentNo);

        // [GIVEN] Mock send-receive purchase return order
        MockSendReceivePurchDocument(PurchaseHeaderToSend, SalesHeader, ICPartnerCodeVendor, SalesHeader."Location Code");

        // [GIVEN] Create Sales Return Order. Send Sales Credit Memo.
        SendSalesDocumentGetICPurchaseHeader(
          SalesHeader, SalesHeader."Document Type"::"Return Order",
          ICOutboxTransaction, ICInboxTransaction, ICPartnerCodeVendor, ICInboxPurchaseHeader);

        // [WHEN] Receive Purchase Credit Memo
        ReceiveICPurchaseDocument(
          PurchaseHeaderToInvoice, SalesHeader, ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader,
          PurchaseHeaderToSend."Buy-from Vendor No.");

        // [THEN] Received Purchase Credit Memo has related Return Shipment with Reservation entry
        VerifyReservationEntryExists(PurchaseHeaderToInvoice."Document Type".AsInteger(), PurchaseHeaderToInvoice."No.");
        FindPurchLine(PurchaseLine, PurchaseHeaderToInvoice);
        Assert.AreEqual(
          ReturnShipmentNo,
          PurchaseLine."Return Shipment No.",
          StrSubstNo(TableFieldErr, PurchaseLine.TableCaption(), PurchaseLine.FieldCaption("Return Shipment No.")));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TestPermissions(TestPermissions::Disabled)]
    [Scope('OnPrem')]
    procedure ItemTrackingQtyInPurchaseInvoiceReceivedFromSalesInvoiceWithGetShptLines()
    var
        PurchaseHeaderToSend: Record "Purchase Header";
        PurchaseHeaderToInvoice: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        SalesHeaderInvoice: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICInboxTransaction: Record "IC Inbox Transaction";
        ICInboxPurchaseHeader: Record "IC Inbox Purchase Header";
        ICPartnerCodeVendor: Code[20];
        ReceiptNo: Code[20];
        CustomerNo: Code[20];
        InvNo: Code[20];
    begin
        // [FEATURE] [Item Tracking]
        // [SCENARIO 210417] Purchase Invoice received from Sales Invoice after "Get Shipment Lines" action performed has correct quantity in Item Tracking

        Initialize();

        // [GIVEN] Receipt Purchase Order with Quantity = 100 and Item Tracking
        ReceiptNo :=
          CreatePostPurchaseReceiptForNewVendor(
            PurchaseHeaderToSend, PurchaseHeaderToSend."Document Type"::Order, ICPartnerCodeVendor);
        MockTrackingForItem(DATABASE::"Purch. Rcpt. Line", ReceiptNo);

        // [GIVEN] Send Purchase Order, receive Sales Order
        CustomerNo := CreateICCustomer(ICPartnerCodeVendor);
        SendPurchaseDocumentReceiveSalesDocument(PurchaseHeaderToSend, SalesHeader, ICPartnerCodeVendor, CustomerNo);

        // [GIVEN] Change Quantity of received Sales Order from 100 to 70
        DecreaseQtyInSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.");

        // [GIVEN] Ship Sales Order
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [GIVEN] Post Sales Invoice with shipment lines from shipped Sales Order
        CreateSalesInvoiceWithGetShipmentLines(SalesHeaderInvoice, CustomerNo);
        InvNo := LibrarySales.PostSalesDocument(SalesHeaderInvoice, true, true);

        // [GIVEN] Send Posted Sales Invoice
        SendICSalesInvoice(ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader, InvNo, ICPartnerCodeVendor);

        // [WHEN] Receive Purchase Invoice
        ReceiveICPurchaseInvoice(
          PurchaseHeaderToInvoice, ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader, InvNo,
          PurchaseHeaderToSend."Pay-to Vendor No.");

        // [THEN] Received Purchase Invoice has item tracking with Quantity = 70
        VerifyReservationEntryQty(PurchaseHeaderToInvoice."Document Type", PurchaseHeaderToInvoice."No.", SalesLine.Quantity);
    end;

    [Test]
    [TestPermissions(TestPermissions::Disabled)]
    [Scope('OnPrem')]
    procedure CheckAssemblyOrderAndSalesOrderForIntercompanyTransaction()
    var
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Qty: Decimal;
    begin
        // [FEATURE] [Intercompany] [Sales Order] [Assembly]
        // [SCENARIO 364376] Assembly Order with reservation should be created for Sales Order with Assembly Item created from an Intercompany Transaction
        Initialize();

        Qty := LibraryRandom.RandInt(100);
        CreateAssembledItem(Item);

        // [GIVEN] Create Purchase Order for Assembled Item with "Quantity" = "Q". Send to IC Partner.
        // [WHEN] Receive IC Partner's Sales Order
        CreateSendPurchaseDocumentReceiveSalesDocument(PurchaseHeader, SalesHeader, Item."No.", Qty, false);

        // [THEN] Assembly Order is created with "Quantity" = "Q". Sales Line Is created with "Reserved Quantity" = "Q"
        VerifyQuantityOnSalesLineAndAssemblyHeader(SalesHeader."No.", Qty);
        PurchaseHeader.DeleteAll();
        SalesHeader.DeleteAll();
        Item.DeleteAll();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchOrderWithGLAccLineForICVendor()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GLAccount: Record "G/L Account";
    begin
        // [FEATURE] [IC Partner] [Purchase] [G/L Account]
        // [SCENARIO 251711] IC Outbox Purchase Line has IC Partner Reference after Purchase Order with G/L Account Line posting.
        Initialize();
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddO365Setup();
        LibraryLowerPermissions.AddPurchDocsPost();
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();

        // [GIVEN] G/L Account with Default IC Partner G/L Account Number "ICAcc".
        CreateICGLAccountWithDefaultICPartnerGLAccNo(GLAccount);

        // [GIVEN] Purchase Order for IC Vendor.
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader,
          PurchaseHeader."Document Type"::Order,
          CreateICVendorWithVATBusPostingGroup(GLAccount."VAT Bus. Posting Group"));

        // [GIVEN] Purchase Line with G/L Account.
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccount."No.",
          LibraryRandom.RandDecInRange(100, 200, 2));

        // [WHEN] Post Purchase Order
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] IC Outbox Purchase Line has IC Partner Ref. Type = "G/L Account" and IC Partner Reference = "ICAcc".
        VerifyICOutboxPurchaseLineICPartnerReference(PurchaseHeader, PurchaseLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchOrderWithItemLineForICVendor()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [IC Partner] [Purchase] [Item]
        // [SCENARIO 251711] IC Outbox Purchase Line has IC Partner Reference after Purchase Order with Item Line posting.
        Initialize();
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddO365Setup();
        LibraryLowerPermissions.AddPurchDocsPost();
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();

        // [GIVEN] Purchase Order for IC Vendor.
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader,
          PurchaseHeader."Document Type"::Order,
          CreateICVendor(CreateICPartner()));

        // [GIVEN] Purchase Line with Item type.
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(),
          LibraryRandom.RandDecInRange(100, 200, 2));

        // [WHEN] Post Purchase Order
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] IC Outbox Purchase Line has IC Partner Ref. Type = "Item" and IC Partner Reference = IC Partner Code.
        VerifyICOutboxPurchaseLineICPartnerReference(PurchaseHeader, PurchaseLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReceivedPurchOrderWithGLAccLineForICVendor()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SendGLAccount: Record "G/L Account";
        ReceiveGLAccount: Record "G/L Account";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICInboxTransaction: Record "IC Inbox Transaction";
        ICInboxSalesHeader: Record "IC Inbox Sales Header";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [IC Partner] [Purchase] [Sales] [G/L Account]
        // [SCENARIO 255423] Sales Line "IC Partner Reference" = "Default IC Partner G/L Acc. No" after Purchase Order with G/L Account Line received.
        Initialize();
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddO365Setup();
        LibraryLowerPermissions.AddPurchDocsPost();
        LibraryLowerPermissions.AddSalesDocsCreate();
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();
        LibraryLowerPermissions.AddeRead();

        // [GIVEN] G/L Account 'X' with Default IC Partner G/L Account Number = 'Y'.
        // [GIVEN] G/L Account 'Y' with Default IC Partner G/L Account Number = 'X'.
        CreatePairOfSendReceiveGLAcc(SendGLAccount, ReceiveGLAccount);

        // [GIVEN] IC Customer.
        CustomerNo := CreateICCustomerWithVATBusPostingGroup(SendGLAccount."VAT Bus. Posting Group");

        // [GIVEN] Purchase Order for IC Vendor.
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader,
          PurchaseHeader."Document Type"::Order,
          CreateICVendorWithVATBusPostingGroup(SendGLAccount."VAT Bus. Posting Group"));

        // [GIVEN] Purchase Line with 'X', "Description 2" is 'A'
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", SendGLAccount."No.",
          LibraryRandom.RandDecInRange(100, 200, 2));
        PurchaseLine."Description 2" := LibraryUtility.GenerateGUID();
        PurchaseLine.Modify();

        // [GIVEN] Send Purchase Order.
        SendICPurchaseDocument(
          PurchaseHeader, GetICPartnerFromCustomer(CustomerNo), ICOutboxTransaction, ICInboxTransaction, ICInboxSalesHeader);

        // [WHEN] Receive Sales Order.
        ReceiveICSalesDocument(
          SalesHeader, PurchaseHeader, ICOutboxTransaction, ICInboxTransaction, ICInboxSalesHeader, CustomerNo);
        FindSalesLine(SalesLine, SalesHeader);

        // [THEN] Sales Line "No." = 'Y', "IC Partner Reference" = 'X', "Description 2" is 'A'
        SalesLine.TestField("No.", ReceiveGLAccount."No.");
        SalesLine.TestField("IC Partner Reference", ReceiveGLAccount."Default IC Partner G/L Acc. No");
        SalesLine.Testfield("Description 2", PurchaseLine."Description 2");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReceivedSalesOrderWithGLAccLineForICCustomer()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SendGLAccount: Record "G/L Account";
        ReceiveGLAccount: Record "G/L Account";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICInboxTransaction: Record "IC Inbox Transaction";
        ICInboxPurchaseHeader: Record "IC Inbox Purchase Header";
        VendorNo: Code[20];
    begin
        // [FEATURE] [IC Partner] [Purchase] [Sales] [G/L Account]
        // [SCENARIO 255423] Purchase Line "IC Partner Reference" = "Default IC Partner G/L Acc. No" after Sales Order with G/L Account Line received.
        Initialize();
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddO365Setup();
        LibraryLowerPermissions.AddPurchDocsCreate();
        LibraryLowerPermissions.AddSalesDocsPost();
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();
        LibraryLowerPermissions.AddeRead();

        // [GIVEN] G/L Account 'X' with Default IC Partner G/L Account Number = 'Y'.
        // [GIVEN] G/L Account 'Y' with Default IC Partner G/L Account Number = 'X'.
        CreatePairOfSendReceiveGLAcc(SendGLAccount, ReceiveGLAccount);

        // [GIVEN] IC Vendor.
        VendorNo := CreateICVendorWithVATBusPostingGroup(SendGLAccount."VAT Bus. Posting Group");

        // [GIVEN] Sales Order for IC Customer.
        LibrarySales.CreateSalesHeader(
          SalesHeader,
          SalesHeader."Document Type"::Order,
          CreateICCustomerWithVATBusPostingGroup(SendGLAccount."VAT Bus. Posting Group"));

        // [GIVEN] Sales Line with 'X', "Description 2" is 'A'
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", SendGLAccount."No.",
          LibraryRandom.RandDecInRange(100, 200, 2));
        SalesLine."Description 2" := LibraryUtility.GenerateGUID();
        SalesLine.Modify();

        // [GIVEN] Send Sales Order.
        SendICSalesDocument(
          SalesHeader, GetICPartnerFromVendor(VendorNo), ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader);

        // [WHEN] Receive Purchase Order.
        ReceiveICPurchaseDocument(
          PurchaseHeader, SalesHeader, ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader, VendorNo);
        FindPurchLine(PurchaseLine, PurchaseHeader);

        // [THEN] Purchase Line, where "No." = 'Y', "IC Partner Reference" = 'X', "Description 2" is 'A'
        PurchaseLine.TestField("No.", ReceiveGLAccount."No.");
        PurchaseLine.TestField("IC Partner Reference", ReceiveGLAccount."Default IC Partner G/L Acc. No");
        PurchaseLine.Testfield("Description 2", SalesLine."Description 2");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReceivedPurchOrderShipToCountryRegionCodeAndCounty()
    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICInboxTransaction: Record "IC Inbox Transaction";
        ICInboxPurchaseHeader: Record "IC Inbox Purchase Header";
        VendorNo: Code[20];
    begin
        // [SCENARIO 255051] IC received Purchase Header values in "Ship-to Country/Region Code" and "Ship-to County" are equal to IC sent Sales Header values "Ship-to Country/Region Code" and "Ship-to County"
        Initialize();
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddO365Setup();
        LibraryLowerPermissions.AddeRead();
        LibraryLowerPermissions.AddSalesDocsCreate();
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();

        // [GIVEN] Create Sales Order with "Ship-to Country/Region Code" = "CRC" and "Ship-to County" = "C" and send it to IC Partner
        CreateAndSendSalesOrderWithShipToCountryRegionAndCounty(
          SalesHeader, ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader, VendorNo);

        // [WHEN] Receive Purchase Order from IC Partner
        LibraryLowerPermissions.AddPurchDocsCreate();
        ReceiveICPurchaseDocument(
          PurchaseHeader, SalesHeader, ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader, VendorNo);

        // [THEN] Received Purchase Header has "Ship-to Country/Region Code" = "CRC" and "Ship-to County" = "C"
        PurchaseHeader.TestField("Ship-to Country/Region Code", SalesHeader."Ship-to Country/Region Code");
        PurchaseHeader.TestField("Ship-to County", SalesHeader."Ship-to County");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReceivedSalesOrderShipToCountryRegionCodeAndCounty()
    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICInboxTransaction: Record "IC Inbox Transaction";
        ICInboxSalesHeader: Record "IC Inbox Sales Header";
        CustNo: Code[20];
    begin
        // [SCENARIO 255051] IC received Sales Header values in "Ship-to Country/Region Code" and "Ship-to County" are equal to IC sent Purchase Header values "Ship-to Country/Region Code" and "Ship-to County"
        Initialize();
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddO365Setup();
        LibraryLowerPermissions.AddeRead();
        LibraryLowerPermissions.AddPurchDocsCreate();
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();

        // [GIVEN] Create Purchase Order with "Ship-to Country/Region Code" = "CRC" and "Ship-to County" = "C" and send it to IC Partner
        CreateAndSendPurchOrderWithShipToCountryRegionAndCounty(
          PurchaseHeader, ICOutboxTransaction, ICInboxTransaction, ICInboxSalesHeader, CustNo);

        // [WHEN] Receive Sales Order from IC Partner
        LibraryLowerPermissions.AddSalesDocsCreate();
        ReceiveICSalesDocument(
          SalesHeader, PurchaseHeader, ICOutboxTransaction, ICInboxTransaction, ICInboxSalesHeader, CustNo);

        // [THEN] Received Sales Header has "Ship-to Country/Region Code" = "CRC" and "Ship-to County" = "C"
        SalesHeader.TestField("Ship-to Country/Region Code", PurchaseHeader."Ship-to Country/Region Code");
        SalesHeader.TestField("Ship-to County", PurchaseHeader."Ship-to County");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure RecreatedICOutboxSalesHeaderShipToCountryRegionCodeAndCounty()
    var
        SalesHeader: Record "Sales Header";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        HandledICOutboxTrans: Record "Handled IC Outbox Trans.";
        ICOutboxSalesHeader: Record "IC Outbox Sales Header";
        ICInboxTransaction: Record "IC Inbox Transaction";
        ICInboxPurchaseHeader: Record "IC Inbox Purchase Header";
        VendorNo: Code[20];
    begin
        // [SCENARIO 255051] IC Outbox Sales Header values in "Ship-to Country/Region Code" and "Ship-to County" are populated when Outbox Transaction is recreated in codeunit ICInboxOutboxMgt
        Initialize();
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddO365Setup();
        LibraryLowerPermissions.AddSalesDocsCreate();
        LibraryLowerPermissions.AddeRead();
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();

        // [GIVEN] Create Sales Order with "Ship-to Country/Region Code" = "CRC" and "Ship-to County" = "C" and send it to IC Partner
        CreateAndSendSalesOrderWithShipToCountryRegionAndCounty(
          SalesHeader, ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader, VendorNo);
        ICInboxOutboxMgt.MoveOutboxTransToHandledOutbox(ICOutboxTransaction);

        // [WHEN] Recreate Outbox Transaction in codeunit ICInboxOutboxMgt
        HandledICOutboxTrans.Get(
          ICOutboxTransaction."Transaction No.", ICOutboxTransaction."IC Partner Code", ICOutboxTransaction."Transaction Source");
        ICInboxOutboxMgt.RecreateOutboxTransaction(HandledICOutboxTrans);

        // [THEN] Recreated IC Outbox Sales Header has "Ship-to Country/Region Code" = "CRC" and "Ship-to County" = "C"
        ICOutboxSalesHeader.Get(
          HandledICOutboxTrans."Transaction No.", HandledICOutboxTrans."IC Partner Code", HandledICOutboxTrans."Transaction Source");
        ICOutboxSalesHeader.TestField("Ship-to Country/Region Code", SalesHeader."Ship-to Country/Region Code");
        ICOutboxSalesHeader.TestField("Ship-to County", SalesHeader."Ship-to County");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure RecreatedICOutboxPurchHeaderShipToCountryRegionCodeAndCounty()
    var
        PurchaseHeader: Record "Purchase Header";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        HandledICOutboxTrans: Record "Handled IC Outbox Trans.";
        ICOutboxPurchaseHeader: Record "IC Outbox Purchase Header";
        DummyICInboxTransaction: Record "IC Inbox Transaction";
        DummyICInboxSalesHeader: Record "IC Inbox Sales Header";
        DummyCustNo: Code[20];
    begin
        // [SCENARIO 255051] IC Outbox Purchase Header values in  "Ship-to Country/Region Code" and "Ship-to County" are populated when Outbox Transaction is recreated in codeunit ICInboxOutboxMgt
        Initialize();
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddO365Setup();
        LibraryLowerPermissions.AddPurchDocsCreate();
        LibraryLowerPermissions.AddeRead();
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();

        // [GIVEN] Create Purchase Order with "Ship-to Country/Region Code" = "CRC" and "Ship-to County" = "C" and send it to IC Partner
        CreateAndSendPurchOrderWithShipToCountryRegionAndCounty(
          PurchaseHeader, ICOutboxTransaction, DummyICInboxTransaction, DummyICInboxSalesHeader, DummyCustNo);
        ICInboxOutboxMgt.MoveOutboxTransToHandledOutbox(ICOutboxTransaction);

        // [WHEN] Recreate Outbox Transaction in codeunit ICInboxOutboxMgt
        HandledICOutboxTrans.Get(
          ICOutboxTransaction."Transaction No.", ICOutboxTransaction."IC Partner Code", ICOutboxTransaction."Transaction Source");
        ICInboxOutboxMgt.RecreateOutboxTransaction(HandledICOutboxTrans);

        // [THEN] Recreated IC Outbox Purchase Header has "Ship-to Country/Region Code" = "CRC" and "Ship-to County" = "C"
        ICOutboxPurchaseHeader.Get(
          HandledICOutboxTrans."Transaction No.", HandledICOutboxTrans."IC Partner Code", HandledICOutboxTrans."Transaction Source");
        ICOutboxPurchaseHeader.TestField("Ship-to Country/Region Code", PurchaseHeader."Ship-to Country/Region Code");
        ICOutboxPurchaseHeader.TestField("Ship-to County", PurchaseHeader."Ship-to County");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure RecreatedICInboxSalesHeaderShipToCountryRegionCodeAndCounty()
    var
        ICInboxTransaction: Record "IC Inbox Transaction";
        HandledICInboxTrans: Record "Handled IC Inbox Trans.";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        ICInboxSalesHeader: Record "IC Inbox Sales Header";
        CustNo: Code[20];
    begin
        // [SCENARIO 255051] IC Inbox Sales Header values in  "Ship-to Country/Region Code" and "Ship-to County" are populated when Inbox Transaction is recreated in codeunit ICInboxOutboxMgt
        Initialize();
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddO365Setup();
        LibraryLowerPermissions.AddSalesDocsCreate();
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();
        LibraryLowerPermissions.AddPurchDocsCreate();
        LibraryLowerPermissions.AddeRead();

        // [GIVEN] IC Partner received Sales Order
        CreateAndSendPurchOrderWithShipToCountryRegionAndCounty(
          PurchaseHeader, ICOutboxTransaction, ICInboxTransaction, ICInboxSalesHeader, CustNo);

        ReceiveICSalesDocument(
          SalesHeader, PurchaseHeader, ICOutboxTransaction, ICInboxTransaction, ICInboxSalesHeader, CustNo);

        HandleICInboxTransaction(HandledICInboxTrans, ICInboxTransaction);
        ICInboxSalesHeader.Delete();

        // [WHEN] Recreate Inbox Transaction in codeunit ICInboxOutboxMgt
        ICInboxOutboxMgt.RecreateInboxTransaction(HandledICInboxTrans);

        // [THEN] Recreated IC Inbox Sales Header has "Ship-to Country/Region Code" = "CRC" and "Ship-to County" = "C"
        ICInboxSalesHeader.Get(
          HandledICInboxTrans."Transaction No.", HandledICInboxTrans."IC Partner Code", HandledICInboxTrans."Transaction Source");
        ICInboxSalesHeader.TestField("Ship-to Country/Region Code", PurchaseHeader."Ship-to Country/Region Code");
        ICInboxSalesHeader.TestField("Ship-to County", PurchaseHeader."Ship-to County");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure RecreatedICInboxPurchHeaderShipToCountryRegionCodeAndCounty()
    var
        ICInboxTransaction: Record "IC Inbox Transaction";
        HandledICInboxTrans: Record "Handled IC Inbox Trans.";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        ICInboxPurchaseHeader: Record "IC Inbox Purchase Header";
        VendorNo: Code[20];
    begin
        // [SCENARIO 255051] IC Inbox Purchase Header values in  "Ship-to Country/Region Code" and "Ship-to County" are populated when Inbox Transaction is recreated in codeunit ICInboxOutboxMgt
        Initialize();
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddO365Setup();
        LibraryLowerPermissions.AddSalesDocsCreate();
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();
        LibraryLowerPermissions.AddPurchDocsCreate();
        LibraryLowerPermissions.AddeRead();

        // [GIVEN] IC Partner received Purchase Order
        CreateAndSendSalesOrderWithShipToCountryRegionAndCounty(
          SalesHeader, ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader, VendorNo);

        ReceiveICPurchaseDocument(
          PurchaseHeader, SalesHeader, ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader, VendorNo);

        HandleICInboxTransaction(HandledICInboxTrans, ICInboxTransaction);
        ICInboxPurchaseHeader.Delete();

        // [WHEN] Recreate Inbox Transaction in codeunit ICInboxOutboxMgt
        ICInboxOutboxMgt.RecreateInboxTransaction(HandledICInboxTrans);

        // [THEN] Recreated IC Inbox Purchase Header has "Ship-to Country/Region Code" = "CRC" and "Ship-to County" = "C"
        ICInboxPurchaseHeader.Get(
          HandledICInboxTrans."Transaction No.", HandledICInboxTrans."IC Partner Code", HandledICInboxTrans."Transaction Source");
        ICInboxPurchaseHeader.TestField("Ship-to Country/Region Code", PurchaseHeader."Ship-to Country/Region Code");
        ICInboxPurchaseHeader.TestField("Ship-to County", PurchaseHeader."Ship-to County");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure HandledICInboxSalesHeaderShipToCountryRegionCodeAndCounty()
    var
        ICInboxSalesHeader: Record "IC Inbox Sales Header";
        HandledICInboxSalesHeader: Record "Handled IC Inbox Sales Header";
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
    begin
        // [SCENARIO 255051] Handled IC Inbox Sales Header values in "Ship-to Country/Region Code" and "Ship-to County" are populated when Sales Document is created in codeunit ICInboxOutboxMgt
        Initialize();
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddO365Setup();
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();
        LibraryLowerPermissions.AddSalesDocsCreate();
        LibraryLowerPermissions.AddeRead();

        // [GIVEN] Create IC Inbox Sales Header with "Ship-to Country/Region Code" = "CRC" and "Ship-to County" = "C"
        Customer.Get(CreateICCustomer(CreateICPartner()));
        MockICInboxSalesHeaderWithShipToCountryRegionAndCounty(ICInboxSalesHeader, Customer);

        // [WHEN] Create Sales Document in codeunit ICInboxOutboxMgt
        ICInboxOutboxMgt.CreateSalesDocument(ICInboxSalesHeader, true, WorkDate());

        // [THEN] Handled IC Inbox Sales Header has "Ship-to Country/Region Code" = "CRC" and "Ship-to County" = "C"
        HandledICInboxSalesHeader.SetRange("IC Partner Code", ICInboxSalesHeader."IC Partner Code");
        HandledICInboxSalesHeader.SetRange("Transaction Source", ICInboxSalesHeader."Transaction Source");
        HandledICInboxSalesHeader.FindFirst();
        HandledICInboxSalesHeader.TestField("Ship-to Country/Region Code", ICInboxSalesHeader."Ship-to Country/Region Code");
        HandledICInboxSalesHeader.TestField("Ship-to County", ICInboxSalesHeader."Ship-to County");

        // [THEN] Sales Header has "Ship-to Country/Region Code" = "CRC" and "Ship-to County" = "C"
        FindSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, ICInboxSalesHeader."Sell-to Customer No.");
        SalesHeader.TestField("Ship-to Country/Region Code", ICInboxSalesHeader."Ship-to Country/Region Code");
        SalesHeader.TestField("Ship-to County", ICInboxSalesHeader."Ship-to County");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure HandledICInboxPurchHeaderShipToCountryRegionCodeAndCounty()
    var
        HandledICInboxPurchHeader: Record "Handled IC Inbox Purch. Header";
        ICInboxPurchaseHeader: Record "IC Inbox Purchase Header";
        PurchaseHeader: Record "Purchase Header";
    begin
        // [SCENARIO 255051] Handled IC Inbox Purchase Header values in  "Ship-to Country/Region Code" and "Ship-to County" are populated when Purchase Document is created in codeunit ICInboxOutboxMgt
        Initialize();
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddO365Setup();
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();
        LibraryLowerPermissions.AddPurchDocsCreate();
        LibraryLowerPermissions.AddeRead();

        // [GIVEN] Create IC Inbox Purchase Header with "Ship-to Country/Region Code" = "CRC" and "Ship-to County" = "C"
        MockICInboxPurchHeaderWithShipToCountryRegionAndCounty(ICInboxPurchaseHeader);

        // [WHEN] Create Purchase Document in codeunit ICInboxOutboxMgt
        ICInboxOutboxMgt.CreatePurchDocument(ICInboxPurchaseHeader, true, WorkDate());

        // [THEN] Handled IC Inbox Purch. Header has "Ship-to Country/Region Code" = "CRC" and "Ship-to County" = "C"
        HandledICInboxPurchHeader.SetRange("IC Partner Code", ICInboxPurchaseHeader."IC Partner Code");
        HandledICInboxPurchHeader.SetRange("Transaction Source", ICInboxPurchaseHeader."Transaction Source");
        HandledICInboxPurchHeader.FindFirst();
        HandledICInboxPurchHeader.TestField("Ship-to Country/Region Code", ICInboxPurchaseHeader."Ship-to Country/Region Code");
        HandledICInboxPurchHeader.TestField("Ship-to County", ICInboxPurchaseHeader."Ship-to County");

        // [THEN] Purchase Header has "Ship-to Country/Region Code" = "CRC" and "Ship-to County" = "C"
        FindPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, ICInboxPurchaseHeader."Buy-from Vendor No.");
        PurchaseHeader.TestField("Ship-to Country/Region Code", ICInboxPurchaseHeader."Ship-to Country/Region Code");
        PurchaseHeader.TestField("Ship-to County", ICInboxPurchaseHeader."Ship-to County");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure HandledICOutboxSalesHeaderShipToCountryRegionCodeAndCounty()
    var
        SalesHeader: Record "Sales Header";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        DummyICInboxTransaction: Record "IC Inbox Transaction";
        DummyICInboxPurchaseHeader: Record "IC Inbox Purchase Header";
        HandledICOutboxSalesHeader: Record "Handled IC Outbox Sales Header";
        DummyVendorNo: Code[20];
    begin
        // [SCENARIO 255051] Handled IC Outbox Sales Header values in "Ship-to Country/Region Code" and "Ship-to County" are populated when Outbox Transaction is handled in codeunit ICInboxOutboxMgt
        Initialize();
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddO365Setup();
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();
        LibraryLowerPermissions.AddSalesDocsCreate();
        LibraryLowerPermissions.AddeRead();

        // [GIVEN] Create Sales Order with "Ship-to Country/Region Code" = "CRC" and "Ship-to County" = "C" and send to IC Partner
        CreateAndSendSalesOrderWithShipToCountryRegionAndCounty(
          SalesHeader, ICOutboxTransaction, DummyICInboxTransaction, DummyICInboxPurchaseHeader, DummyVendorNo);

        // [WHEN] Outbox Transaction is handled in codeunit ICInboxOutboxMgt
        ICInboxOutboxMgt.MoveOutboxTransToHandledOutbox(ICOutboxTransaction);

        // [THEN] Handled IC Inbox Sales Header has "Ship-to Country/Region Code" = "CRC" and "Ship-to County" = "C"
        HandledICOutboxSalesHeader.SetRange("Document Type", SalesHeader."Document Type");
        HandledICOutboxSalesHeader.SetRange("No.", SalesHeader."No.");
        HandledICOutboxSalesHeader.FindFirst();
        HandledICOutboxSalesHeader.TestField("Ship-to Country/Region Code", SalesHeader."Ship-to Country/Region Code");
        HandledICOutboxSalesHeader.TestField("Ship-to County", SalesHeader."Ship-to County");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure HandledICOutboxPurchHeaderShipToCountryRegionCodeAndCounty()
    var
        PurchaseHeader: Record "Purchase Header";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        DummyICInboxTransaction: Record "IC Inbox Transaction";
        DummyICInboxSalesHeader: Record "IC Inbox Sales Header";
        HandledICOutboxPurchHdr: Record "Handled IC Outbox Purch. Hdr";
        DummyCustNo: Code[20];
    begin
        // [SCENARIO 255051] Handled IC Outbox Purch. Hdr values in "Ship-to Country/Region Code" and "Ship-to County" are populated when Outbox Transaction is handled in codeunit ICInboxOutboxMgt
        Initialize();
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddO365Setup();
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();
        LibraryLowerPermissions.AddPurchDocsCreate();
        LibraryLowerPermissions.AddeRead();

        // [GIVEN] Create Purchase Order with "Ship-to Country/Region Code" = "CRC" and "Ship-to County" = "C" and send it to IC Partner
        CreateAndSendPurchOrderWithShipToCountryRegionAndCounty(
          PurchaseHeader, ICOutboxTransaction, DummyICInboxTransaction, DummyICInboxSalesHeader, DummyCustNo);

        // [WHEN] Outbox Transaction is handled in codeunit ICInboxOutboxMgt
        ICInboxOutboxMgt.MoveOutboxTransToHandledOutbox(ICOutboxTransaction);

        // [THEN] Handled IC Outbox Purch. Hdr has "Ship-to Country/Region Code" = "CRC" and "Ship-to County" = "C"
        HandledICOutboxPurchHdr.SetRange("Document Type", PurchaseHeader."Document Type");
        HandledICOutboxPurchHdr.SetRange("No.", PurchaseHeader."No.");
        HandledICOutboxPurchHdr.FindFirst();
        HandledICOutboxPurchHdr.TestField("Ship-to Country/Region Code", PurchaseHeader."Ship-to Country/Region Code");
        HandledICOutboxPurchHdr.TestField("Ship-to County", PurchaseHeader."Ship-to County");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [TestPermissions(TestPermissions::Disabled)]
    [Scope('OnPrem')]
    procedure SetItemTrackingInPurchInvoiceWithLinesMatchMultipleReceipts()
    var
        PurchaseHeaderToInvoice: Record "Purchase Header";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICInboxTransaction: Record "IC Inbox Transaction";
        ICInboxPurchaseHeader: Record "IC Inbox Purchase Header";
        ICPartnerCode: Code[20];
        InvoiceNo: Code[20];
        VendorNo: Code[20];
    begin
        // [FEATURE] [Item Tracking] [Purchase] [Invoice]
        // [SCENARIO 264389] Item tracking in purchase invoice received via IC matches item tracking in purchase receipt lines, same as if you had run Get Receipt Lines. The line order in receipt and invoice is the same.
        Initialize();

        // [GIVEN] Company "A":
        // [GIVEN] Create purchase order with one line for 5 pcs of lot-tracked item.
        // [GIVEN] Post the receipt in two steps - first 3 pcs of lot "L1", then 2 pcs of lot "L2".
        // [GIVEN] Send the purchase order to company "B".

        // [GIVEN] Company "B":
        // [GIVEN] Receive sales order for 5 pcs.
        // [GIVEN] Post the shipment in the same two steps - first 3 pcs, then 2 pcs.
        // [GIVEN] Create and post sales invoice using "Get Shipment Lines".
        ICPartnerCode := CreateICPartner();
        VendorNo := CreateICVendor(ICPartnerCode);
        CreateAndPostMultipleReceiptsWithTrackingAndPrepareInvoiceFromVendor(
          InvoiceNo, VendorNo, ICPartnerCode, '3,2', '3,2');

        // [GIVEN] Send the sales invoice to company "A".
        SendICSalesInvoice(
          ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader, InvoiceNo, ICPartnerCode);

        // [WHEN] Company "A": Receive the purchase invoice from the IC inbox.
        ReceiveICPurchaseInvoice(
          PurchaseHeaderToInvoice, ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader, InvoiceNo, VendorNo);

        // [THEN] Item tracking is assigned to purchase invoice lines: lot "L1" = 3 pcs, lot "L2" = 2 pcs.
        VerifyItemTrackingOnPurchaseLines(PurchaseHeaderToInvoice);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [TestPermissions(TestPermissions::Disabled)]
    [Scope('OnPrem')]
    procedure SetItemTrackingInPurchInvoiceWithLinesMismatchMultipleReceipts()
    var
        PurchaseHeaderToInvoice: Record "Purchase Header";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICInboxTransaction: Record "IC Inbox Transaction";
        ICInboxPurchaseHeader: Record "IC Inbox Purchase Header";
        ICPartnerCode: Code[20];
        InvoiceNo: Code[20];
        VendorNo: Code[20];
    begin
        // [FEATURE] [Item Tracking] [Purchase] [Invoice]
        // [SCENARIO 264389] Item tracking in purchase invoice received via IC matches item tracking in purchase receipt lines, same as if you had run Get Receipt Lines. The line order in receipt and invoice is different.
        Initialize();

        // [GIVEN] Company "A":
        // [GIVEN] Create purchase order with one line for 5 pcs of lot-tracked item.
        // [GIVEN] Post the receipt in two steps - first 3 pcs of lot "L1", then 2 pcs of lot "L2".
        // [GIVEN] Send the purchase order to company "B".

        // [GIVEN] Company "B":
        // [GIVEN] Receive sales order for 5 pcs.
        // [GIVEN] Post the shipment in reversed order - first 2 pcs, then 3 pcs.
        // [GIVEN] Create and post sales invoice using "Get Shipment Lines".
        ICPartnerCode := CreateICPartner();
        VendorNo := CreateICVendor(ICPartnerCode);
        CreateAndPostMultipleReceiptsWithTrackingAndPrepareInvoiceFromVendor(
          InvoiceNo, VendorNo, ICPartnerCode, '3,2', '2,3');

        // [GIVEN] Send the sales invoice to company "A".
        SendICSalesInvoice(
          ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader, InvoiceNo, ICPartnerCode);

        // [WHEN] Company "A": Receive the purchase invoice from the IC inbox.
        ReceiveICPurchaseInvoice(
          PurchaseHeaderToInvoice, ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader, InvoiceNo, VendorNo);

        // [THEN] Item tracking is assigned to purchase invoice lines: lot "L2" = 2 pcs, lot "L1" = 3 pcs.
        VerifyItemTrackingOnPurchaseLines(PurchaseHeaderToInvoice);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [TestPermissions(TestPermissions::Disabled)]
    [Scope('OnPrem')]
    procedure DoNotSetItemTrackingInPurchInvoiceWithQtyExceedingReceipts()
    var
        PurchaseHeaderToInvoice: Record "Purchase Header";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICInboxTransaction: Record "IC Inbox Transaction";
        ICInboxPurchaseHeader: Record "IC Inbox Purchase Header";
        ICPartnerCode: Code[20];
        InvoiceNo: Code[20];
        VendorNo: Code[20];
    begin
        // [FEATURE] [Item Tracking] [Purchase] [Invoice]
        // [SCENARIO 264389] Item tracking is not assigned on purchase invoice received via IC, if the quantity to invoice on the line is greater than quantity of any purchase receipts.
        Initialize();

        // [GIVEN] Company "A":
        // [GIVEN] Create purchase order with one line for 5 pcs of lot-tracked item.
        // [GIVEN] Post the receipt in two steps - first 3 pcs of lot "L1", then 2 pcs of lot "L2".
        // [GIVEN] Send the purchase order to company "B".

        // [GIVEN] Company "B":
        // [GIVEN] Receive sales order for 5 pcs.
        // [GIVEN] Post the shipment in the new order - first 4 pcs, then 1 pcs.
        // [GIVEN] Create and post sales invoice using "Get Shipment Lines".
        ICPartnerCode := CreateICPartner();
        VendorNo := CreateICVendor(ICPartnerCode);
        CreateAndPostMultipleReceiptsWithTrackingAndPrepareInvoiceFromVendor(
          InvoiceNo, VendorNo, ICPartnerCode, '3,2', '4,1');

        // [GIVEN] Send the sales invoice to company "A".
        SendICSalesInvoice(
          ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader, InvoiceNo, ICPartnerCode);

        // [WHEN] Company "A": Receive the purchase invoice from the IC inbox.
        ReceiveICPurchaseInvoice(
          PurchaseHeaderToInvoice, ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader, InvoiceNo, VendorNo);

        // [THEN] Purchase invoice line for 4 pcs has not been linked to any of the purchase receipts and has not been tracked.
        VerifyItemTrackingNotAssignedOnPurchaseLine(PurchaseHeaderToInvoice);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [TestPermissions(TestPermissions::Disabled)]
    [Scope('OnPrem')]
    procedure SetItemTrackingInPurchCrMemoWithLinesMatchMultipleReturnShipments()
    var
        PurchaseHeaderCrMemo: Record "Purchase Header";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICInboxTransaction: Record "IC Inbox Transaction";
        ICInboxPurchaseHeader: Record "IC Inbox Purchase Header";
        ICPartnerCode: Code[20];
        CreditMemoNo: Code[20];
        VendorNo: Code[20];
    begin
        // [FEATURE] [Item Tracking] [Purchase] [Credit Memo]
        // [SCENARIO 264389] Item tracking in purchase credit-memo received via IC matches item tracking in return shipment lines, same as if you had run Get Shipment Lines. The line order in shipment and credit-memo is the same.
        Initialize();

        // [GIVEN] Company "A":
        // [GIVEN] Create purchase return order with one line for 5 pcs of lot-tracked item.
        // [GIVEN] Post the shipment in two steps - first 3 pcs of lot "L1", then 2 pcs of lot "L2".
        // [GIVEN] Send the purchase return to company "B".

        // [GIVEN] Company "B":
        // [GIVEN] Receive sales return order for 5 pcs.
        // [GIVEN] Post the receipt in the same two steps - first 3 pcs, then 2 pcs.
        // [GIVEN] Create and post sales credit-memo using "Get Receipt Lines".
        ICPartnerCode := CreateICPartner();
        VendorNo := CreateICVendor(ICPartnerCode);
        CreateAndPostMultipleRetShipmentsWithTrackingAndPrepareInvoiceFromVendor(
          CreditMemoNo, VendorNo, ICPartnerCode, '3,2', '3,2');

        // [GIVEN] Send the sales credit-memo to company "A".
        SendICSalesCrMemo(
          ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader, CreditMemoNo, ICPartnerCode);

        // [WHEN] Company "A": Receive the purchase credit-memo from the IC inbox.
        ReceiveICPurchaseCrMemo(
          PurchaseHeaderCrMemo, ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader, CreditMemoNo, VendorNo);

        // [THEN] Item tracking is assigned to purchase credit-memo lines: lot "L1" = 3 pcs, lot "L2" = 2 pcs.
        VerifyItemTrackingOnPurchaseLines(PurchaseHeaderCrMemo);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [TestPermissions(TestPermissions::Disabled)]
    [Scope('OnPrem')]
    procedure SetItemTrackingInPurchCrMemoWithLinesMismatchMultipleReturnShipments()
    var
        PurchaseHeaderCrMemo: Record "Purchase Header";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICInboxTransaction: Record "IC Inbox Transaction";
        ICInboxPurchaseHeader: Record "IC Inbox Purchase Header";
        ICPartnerCode: Code[20];
        CreditMemoNo: Code[20];
        VendorNo: Code[20];
    begin
        // [FEATURE] [Item Tracking] [Purchase] [Credit Memo]
        // [SCENARIO 264389] Item tracking in purchase credit-memo received via IC matches item tracking in return shipment lines, same as if you had run Get Shipment Lines. The line order in shipment and credit-memo is different.
        Initialize();

        // [GIVEN] Company "A":
        // [GIVEN] Create purchase return order with one line for 5 pcs of lot-tracked item.
        // [GIVEN] Post the shipment in two steps - first 3 pcs of lot "L1", then 2 pcs of lot "L2".
        // [GIVEN] Send the purchase return to company "B".

        // [GIVEN] Company "B":
        // [GIVEN] Receive sales return order for 5 pcs.
        // [GIVEN] Post the receipt in reversed order - first 2 pcs, then 3 pcs.
        // [GIVEN] Create and post sales credit-memo using "Get Receipt Lines".
        ICPartnerCode := CreateICPartner();
        VendorNo := CreateICVendor(ICPartnerCode);
        CreateAndPostMultipleRetShipmentsWithTrackingAndPrepareInvoiceFromVendor(
          CreditMemoNo, VendorNo, ICPartnerCode, '3,2', '2,3');

        // [GIVEN] Send the sales credit-memo to company "A".
        SendICSalesCrMemo(
          ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader, CreditMemoNo, ICPartnerCode);

        // [WHEN] Company "A": Receive the purchase credit-memo from the IC inbox.
        ReceiveICPurchaseCrMemo(
          PurchaseHeaderCrMemo, ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader, CreditMemoNo, VendorNo);

        // [THEN] Item tracking is assigned to purchase credit-memo lines: lot "L2" = 2 pcs, lot "L1" = 3 pcs.
        VerifyItemTrackingOnPurchaseLines(PurchaseHeaderCrMemo);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [TestPermissions(TestPermissions::Disabled)]
    [Scope('OnPrem')]
    procedure DoNotSetItemTrackingInPurchCrMemoWithQtyExceedingReturnShipments()
    var
        PurchaseHeaderCrMemo: Record "Purchase Header";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICInboxTransaction: Record "IC Inbox Transaction";
        ICInboxPurchaseHeader: Record "IC Inbox Purchase Header";
        ICPartnerCode: Code[20];
        CreditMemoNo: Code[20];
        VendorNo: Code[20];
    begin
        // [FEATURE] [Item Tracking] [Purchase] [Credit Memo]
        // [SCENARIO 264389] Item tracking is not assigned on purchase credit-memo received via IC, if the quantity to invoice on the line is greater than quantity of any return shipments.
        Initialize();

        // [GIVEN] Company "A":
        // [GIVEN] Create purchase return order with one line for 5 pcs of lot-tracked item.
        // [GIVEN] Post the shipment in two steps - first 3 pcs of lot "L1", then 2 pcs of lot "L2".
        // [GIVEN] Send the purchase return to company "B".

        // [GIVEN] Company "B":
        // [GIVEN] Receive sales return order for 5 pcs.
        // [GIVEN] Post the receipt in the new order - first 4 pcs, then 1 pcs.
        // [GIVEN] Create and post sales credit-memo using "Get Receipt Lines".
        ICPartnerCode := CreateICPartner();
        VendorNo := CreateICVendor(ICPartnerCode);
        CreateAndPostMultipleRetShipmentsWithTrackingAndPrepareInvoiceFromVendor(
          CreditMemoNo, VendorNo, ICPartnerCode, '3,2', '4,1');

        // [GIVEN] Send the sales credit-memo to company "A".
        SendICSalesCrMemo(
          ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader, CreditMemoNo, ICPartnerCode);

        // [WHEN] Company "A": Receive the purchase credit-memo from the IC inbox.
        ReceiveICPurchaseCrMemo(
          PurchaseHeaderCrMemo, ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader, CreditMemoNo, VendorNo);

        // [THEN] Purchase credit-memo line for 4 pcs has not been linked to any of the return shipments.
        VerifyItemTrackingNotAssignedOnPurchaseLine(PurchaseHeaderCrMemo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICPartnerRefWhenPostReturnReceipt()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        // [FEATURE] [Purchase] [Receipt]
        // [SCENARIO 271063] "IC Partner Ref. Type" and "IC Partner Reference" are transferred from Purchase Line to Purchase Receipt Line when posting Purchase Order
        Initialize();

        // [GIVEN] Purchase Order for IC Vendor and Item "I"
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, CreateICVendor(CreateICPartner()),
          LibraryInventory.CreateItemNo(), LibraryRandom.RandDecInRange(10, 20, 2), '', WorkDate());

        // [WHEN] Post Purchase Order
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Purchase Receipt Line has "IC Partner Ref. Type" = Item and "IC Partner Reference" = "I"
        PurchRcptLine.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        PurchRcptLine.FindFirst();
        PurchRcptLine.TestField("IC Partner Ref. Type", PurchRcptLine."IC Partner Ref. Type"::Item);
        PurchRcptLine.TestField("IC Partner Reference", PurchaseLine."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICPartnerRefWhenPostReturnShipment()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        // [FEATURE] [Sales] [Shipment]
        // [SCENARIO 271063] "IC Partner Ref. Type" and "IC Partner Reference" are transferred from Sales Line to Sales Shipment Line when posting Sales Order
        Initialize();

        // [GIVEN] Sales Order for IC Customer and Item "I"
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, CreateICCustomer(CreateICPartner()),
          LibraryInventory.CreateItemNo(), LibraryRandom.RandDecInRange(10, 20, 2), '', WorkDate());

        // [WHEN] Post Purchase Order
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Purchase Receipt Line has "IC Partner Ref. Type" = Item and "IC Partner Reference" = "I"
        SalesShipmentLine.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesShipmentLine.FindFirst();
        SalesShipmentLine.TestField("IC Partner Ref. Type", SalesShipmentLine."IC Partner Ref. Type"::Item);
        SalesShipmentLine.TestField("IC Partner Reference", SalesLine."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICPartnerRefWhenCreatePurchReturnOrderFromPurchReceipt()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorNo: Code[20];
        ItemNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Receipt] [Return Order]
        // [SCENARIO 271063] "IC Partner Ref. Type" and "IC Partner Reference" are transferred from Purchase Receipt Line to Purchase Line when copying via Copy Document Mgt.
        Initialize();

        // [GIVEN] Purchase Order for IC Vendor and Item "I"
        VendorNo := CreateICVendor(CreateICPartner());
        ItemNo := LibraryInventory.CreateItemNo();
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, VendorNo, ItemNo, LibraryRandom.RandDecInRange(10, 20, 2),
          '', WorkDate());

        // [GIVEN] Posted Purchase Order
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Purchase Return Order
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", VendorNo);

        // [WHEN] Copy Purchase Line to Purchase Return Order from Purchase Receipt Line via Copy Document Mgt.
        CopyPurchaseLineFromPurchReceiptLine(PurchaseHeader, FindPurchReceiptByVendorNo(VendorNo));

        // [THEN] Purchase Line has "IC Partner Ref. Type" = Item and "IC Partner Reference" = "I"
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.FindFirst();
        PurchaseLine.TestField("IC Partner Ref. Type", PurchaseLine."IC Partner Ref. Type"::Item);
        PurchaseLine.TestField("IC Partner Reference", ItemNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICPartnerRefWhenCreateSalesReturnOrderFromSalesShipment()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustNo: Code[20];
        ItemNo: Code[20];
    begin
        // [FEATURE] [Sales] [Shipment] [Return Order]
        // [SCENARIO 271063] "IC Partner Ref. Type" and "IC Partner Reference" are transferred from Sales Shipment Line to Sales Line when copying via Copy Document Mgt.
        Initialize();

        // [GIVEN] Sales Order for IC Customer and Item "I"
        CustNo := CreateICCustomer(CreateICPartner());
        ItemNo := LibraryInventory.CreateItemNo();
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, CustNo, ItemNo, LibraryRandom.RandDecInRange(10, 20, 2),
          '', WorkDate());

        // [GIVEN] Posted Sales Order
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Sales Return Order
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", CustNo);

        // [WHEN] Copy Sales Line to Sales Return Order from Sales Shipment Line via Copy Document Mgt.
        CopySalesLineFromSalesShipmentLine(SalesHeader, FindSalesShipmentByCustNo(CustNo));

        // [THEN] Sales Line has "IC Partner Ref. Type" = Item and "IC Partner Reference" = "I"
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.FindFirst();
        SalesLine.TestField("IC Partner Ref. Type", SalesLine."IC Partner Ref. Type"::Item);
        SalesLine.TestField("IC Partner Reference", ItemNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimensionSetIDInheritsFromGenJnlLineWhenPostICSalesDoc()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ICPartnerNo: Code[20];
        CustomerNo: Code[20];
        InvNo: Code[20];
    begin
        // [FEATURE] [Sales] [Dimension]
        // [SCENARIO 280681] "Dimension Set ID" inherits from sales Line when post G/L Entry with IC Partner

        Initialize();

        // [GIVEN] Customer with default dimension set id 1000 which contains "Global Dimension 1 Code" = 'X', "Global Dimension 2 Code" = 'Y'
        CustomerNo := LibrarySales.CreateCustomerNo();
        UpdateCustomerWithDefaultGlobalDimensionSet(CustomerNo);

        LibraryLowerPermissions.SetSalesDocsPost();
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();
        LibraryLowerPermissions.AddIntercompanyPostingsSetup();

        // [GIVEN] Sales invoice with Customer
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), LibraryRandom.RandInt(10));

        // [GIVEN] Sales invoice line with "G/L Account No." = "Z" and IC information: "IC Partner No" = "C", "IC Partner Ref. Type" = "G/L Account", "IC Partner Reference" = "IC G/L Account"
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        ICPartnerNo := AddICInfoToSalesLine(SalesLine);

        // [WHEN] Post sales invoice
        InvNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] G/L Entry created with "G/L Account No." = "Z", "Bal. Account Type" = "IC Partner", "Bal. Account No." = "C", "Dimension Set ID" = 1000, "Global Dimension 1 Code" = 'X', "Global Dimension 2 Code" = 'Y'
        VerifyDimSetIDInICGLEntry(
          InvNo, SalesLine."No.", ICPartnerNo, SalesLine."Dimension Set ID",
          SalesLine."Shortcut Dimension 1 Code", SalesLine."Shortcut Dimension 2 Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimensionSetIDInheritsFromGenJnlLineWhenPostICPurchDoc()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ICPartnerNo: Code[20];
        VendorNo: Code[20];
        InvNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Dimension]
        // [SCENARIO 280681] "Dimension Set ID" inherits from purchase Line when post G/L Entry with IC Partner

        Initialize();

        // [GIVEN] Vendor with default dimension set id 1000 which contains "Global Dimension 1 Code" = 'X', "Global Dimension 2 Code" = 'Y'
        VendorNo := LibraryPurchase.CreateVendorNo();
        UpdateVendorWithDefaultGlobalDimensionSet(VendorNo);

        LibraryLowerPermissions.SetPurchDocsPost();
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();
        LibraryLowerPermissions.AddIntercompanyPostingsSetup();

        // [GIVEN] Purchase invoice with Vendor
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithPurchSetup(), LibraryRandom.RandInt(10));

        // [GIVEN] Purchase invoice line with "G/L Account No." = "Z" and IC information: "IC Partner No" = "C", "IC Partner Ref. Type" = "G/L Account", "IC Partner Reference" = "IC G/L Account"
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        ICPartnerNo := AddICInfoToPurchaseLine(PurchaseLine);

        // [WHEN] Post purchase invoice
        InvNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] G/L Entry created with "G/L Account No." = "Z", "Bal. Account Type" = "IC Partner", "Bal. Account No." = "C", "Dimension Set ID" = 1000, "Global Dimension 1 Code" = 'X', "Global Dimension 2 Code" = 'Y'
        VerifyDimSetIDInICGLEntry(
          InvNo, PurchaseLine."No.", ICPartnerNo, PurchaseLine."Dimension Set ID",
          PurchaseLine."Shortcut Dimension 1 Code", PurchaseLine."Shortcut Dimension 2 Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitPriceIsCopiedToSalesLineCreatedFromInbox()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Customer: Record Customer;
        ICInboxSalesHeader: Record "IC Inbox Sales Header";
        ICInboxSalesLine: Record "IC Inbox Sales Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemNo: array[2] of Code[20];
        UnitPrice: Decimal;
        Qty: Decimal;
        VAT: Decimal;
        AmtInclVAT: Decimal;
    begin
        // [FEATURE] [Sales] [Order]
        // [SCENARIO 297356] New sales order created from intercompany inbox gets the same unit prices as the sales document in the inbox.
        Initialize();

        UnitPrice := 41.62;
        VAT := 20;
        Qty := 1;
        AmtInclVAT := Qty * UnitPrice * (1 + VAT / 100); // 49.944

        // [GIVEN] VAT Posting Setup with VAT % = 20.
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", VAT);

        // [GIVEN] Two items "I1" and "I2" with the new VAT prod. posting group.
        // [GIVEN] Customer "C" with the new VAT bus. posting group.
        ItemNo[1] := LibraryInventory.CreateItemNoWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group");
        ItemNo[2] := LibraryInventory.CreateItemNoWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group");
        Customer.Get(CreateICCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));

        // [GIVEN] Intercompany inbox contains a sales document with customer "C" and two item lines.
        // [GIVEN] First line: Item = "I1", Unit Price = 41.62, VAT % = 20, Amount Including VAT = 49.95 (the precise amount value is 49.944, but on this line it is rounded up).
        // [GIVEN] Second line: Item = "I2", Unit Price = 41.62, VAT % = 20, Amount Including VAT = 49.94 (the precise amount value is 49.944, but on this line it is rounded down).
        MockICInboxSalesHeaderWithShipToCountryRegionAndCounty(ICInboxSalesHeader, Customer);
        MockICInboxSalesLine(
          ICInboxSalesLine, ICInboxSalesHeader, ItemNo[1], UnitPrice, Qty, Round(AmtInclVAT, LibraryERM.GetAmountRoundingPrecision(), '>'));
        ICInboxSalesLine.Validate("Unit of Measure Code", FindItemUnitOfMeasureCode(ItemNo[1]));
        ICInboxSalesLine.Modify(true);
        MockICInboxSalesLine(
          ICInboxSalesLine, ICInboxSalesHeader, ItemNo[2], UnitPrice, Qty, Round(AmtInclVAT, LibraryERM.GetAmountRoundingPrecision(), '<'));
        ICInboxSalesLine.Validate("Unit of Measure Code", FindItemUnitOfMeasureCode(ItemNo[2]));
        ICInboxSalesLine.Modify(true);

        // [WHEN] Create and release a new sales order from the intercompany inbox.
        ICInboxOutboxMgt.CreateSalesDocument(ICInboxSalesHeader, false, WorkDate());
        FindSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [THEN] The new sales order has two lines.
        // [THEN] The unit prices and amounts including VAT on the new sales lines precisely match the sales document's in IC inbox.
        SalesLine.SetRange("No.", ItemNo[1]);
        FindSalesLine(SalesLine, SalesHeader);
        SalesLine.TestField("Unit Price", UnitPrice);
        SalesLine.TestField("Amount Including VAT", Round(AmtInclVAT, LibraryERM.GetAmountRoundingPrecision(), '>'));

        SalesLine.SetRange("No.", ItemNo[2]);
        SalesLine.FindFirst();
        SalesLine.TestField("Unit Price", UnitPrice);
        SalesLine.TestField("Amount Including VAT", Round(AmtInclVAT, LibraryERM.GetAmountRoundingPrecision(), '<'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPriceIsNotOverriddenWhenSalesLineCreatedFromInbox()
    var
        SalesPrice: Record "Sales Price";
        Customer: Record Customer;
        ICInboxSalesHeader: Record "IC Inbox Sales Header";
        ICInboxSalesLine: Record "IC Inbox Sales Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemNo: Code[20];
        UnitPrice: Decimal;
        Qty: Decimal;
    begin
        // [FEATURE] [Sales] [Order] [Sales Price]
        // [SCENARIO 322680] Sales price on a sales order line created from intercompany inbox is not overridden by sales price settings in the receiving company.
        Initialize();
        UnitPrice := LibraryRandom.RandDec(100, 2);
        Qty := LibraryRandom.RandInt(10);

        // [GIVEN] Item "I", customer "C".
        // [GIVEN] The price on item "I" for customer "C" is set to 100 LCY.
        ItemNo := LibraryInventory.CreateItemNo();
        Customer.Get(CreateICCustomer(CreateICPartner()));
        LibrarySales.CreateSalesPrice(
          SalesPrice, ItemNo, SalesPrice."Sales Type"::Customer, Customer."No.", 0D, '', '', '', 0, UnitPrice * 2);

        // [GIVEN] Intercompany inbox contains a sales document for customer "C" and item "I".
        // [GIVEN] The unit price on the IC sales line is 50 LCY.
        MockICInboxSalesHeaderWithShipToCountryRegionAndCounty(ICInboxSalesHeader, Customer);
        MockICInboxSalesLine(ICInboxSalesLine, ICInboxSalesHeader, ItemNo, UnitPrice, Qty, Qty * UnitPrice);

        // [WHEN] Create a new sales order from the intercompany inbox.
        ICInboxOutboxMgt.CreateSalesDocument(ICInboxSalesHeader, false, WorkDate());
        FindSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");

        // [THEN] The unit price on the new sales order line is 50 LCY.
        FindSalesLine(SalesLine, SalesHeader);
        SalesLine.TestField("Unit Price", UnitPrice);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ReceivedICPurchaseDocumentLocationCode()
    var
        SalesHeader: Record "Sales Header";
        PurchaseHeaderToSend: Record "Purchase Header";
        PurchaseHeaderToInvoice: Record "Purchase Header";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICInboxTransaction: Record "IC Inbox Transaction";
        ICInboxPurchaseHeader: Record "IC Inbox Purchase Header";
        DocumentNo: Code[20];
        ICPartnerCodeVendor: Code[20];
        OldLocationMandatory: Boolean;
    begin
        Initialize();
        // [GIVEN] Location is mandatory in Inventory Setup
        OldLocationMandatory := SetupLocationMandatory(true);
        // [GIVEN] Posted Receipt from Purchase Order
        CreatePostPurchaseReceiptForNewVendor(PurchaseHeaderToSend, PurchaseHeaderToSend."Document Type"::Order, ICPartnerCodeVendor);

        // [GIVEN] Mock send-receive purchase document and use different sales document location
        MockSendReceivePurchDocument(PurchaseHeaderToSend, SalesHeader, ICPartnerCodeVendor, CreateLocation());

        // [GIVEN] Sent Sales Invoice as IC Inbox Purchase Document
        LibraryLowerPermissions.SetIntercompanyPostingsEdit();
        LibraryLowerPermissions.AddSalesDocsPost();
        LibraryLowerPermissions.AddO365Setup();
        SendSalesDocumentGetICPurchaseHeader(
          SalesHeader, SalesHeader."Document Type"::Order,
          ICOutboxTransaction, ICInboxTransaction, ICPartnerCodeVendor, ICInboxPurchaseHeader);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Purchase Invoice created from IC Inbox Purchase Document
        LibraryLowerPermissions.AddPurchDocsPost();
        ReceiveICPurchaseDocument(
          PurchaseHeaderToInvoice, SalesHeader, ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader,
          PurchaseHeaderToSend."Buy-from Vendor No.");
        UpdatePurchaseInvoice(PurchaseHeaderToInvoice, PurchaseHeaderToSend);
        // [WHEN] Received Purchase Invoice posted
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeaderToInvoice, false, true);
        // [THEN] No error occured and Location Code populated from posted receipt
        VerifyPostedPurchaseInvoiceLocation(DocumentNo, PurchaseHeaderToSend);

        // Tear down
        SetupLocationMandatory(OldLocationMandatory);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReceiveICSalesDocumentWithCurrencyEqualGLSetupLCYCode()
    var
        ICInboxTransaction: Record "IC Inbox Transaction";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICInboxPurchaseHeader: Record "IC Inbox Purchase Header";
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        ICOutboxSalesHeader: Record "IC Outbox Sales Header";
        ICPartner: Record "IC Partner";
        ICSetup: Record "IC Setup";
        Customer: Record Customer;
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
        ICPartnerVendorCode: Code[20];
    begin
        // [SCENARIO 416829] Intercompany Inbox Sales Document with Currency = GLSetup LCY Currency should be transferred to Purch Doc with empty currency
        Initialize();

        // [GIVEN] An IC Partner Code
        ICPartnerVendorCode := CreateICPartnerWithInbox();
        ICSetup.Get();
        ICSetup."Auto. Send Transactions" := false;
        ICSetup."IC Partner Code" := ICPartnerVendorCode;
        ICSetup.Modify();
        ICOutboxTransaction.DeleteAll();

        // [GIVEN] IC Partner with Vendor No.
        ICPartner.Get(ICPartnerVendorCode);
        ICPartner.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        ICPartner.Modify(true);

        // [GIVEN] Created Sales Invoice with empty Currency Code
        LibrarySales.CreateSalesInvoice(SalesHeader);
        SalesHeader.Validate("Sell-to IC Partner Code", ICPartnerVendorCode);
        SalesHeader.Validate("Send IC Document", true);
        SalesHeader.Modify(true);

        // [GIVEN] Set IC Partner Code for created Customer
        Customer.Get(SalesHeader."Sell-to Customer No.");
        Customer.Validate("IC Partner Code", ICPartnerVendorCode);
        Customer.Modify(true);

        // [GIVEN] Sales IC Sales Document
        ICInboxOutboxMgt.SendSalesDoc(SalesHeader, false);
        ICOutboxTransaction."Document Type" := ICOutboxTransaction."Document Type"::Invoice;
        ICOutboxSalesHeader."Document Type" := ICOutboxSalesHeader."Document Type"::Invoice;

        FindICOutboxTransaction(
          ICOutboxTransaction, SalesHeader."No.", ICOutboxTransaction."Document Type",
          ICOutboxTransaction."IC Source Type"::"Sales Document");
        FindICOutboxSalesHeader(
          ICOutboxSalesHeader, ICOutboxTransaction."Transaction No.",
          SalesHeader."No.", ICOutboxSalesHeader."Document Type");

        // [GIVEN] Receiving Company has General Ledger LCY Code = 'LCY'
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."LCY Code" := LibraryUtility.GenerateGUID();
        GeneralLedgerSetup.Modify();

        // [WHEN] Received document transferred to Receiving company
        ICInboxOutboxMgt.OutboxTransToInbox(ICOutboxTransaction, ICInboxTransaction, ICPartnerVendorCode);
        ICOutboxSalesHeader."Currency Code" := GeneralLedgerSetup."LCY Code";
        ICOutboxSalesHeader.Modify();
        ICInboxOutboxMgt.OutboxSalesHdrToInbox(ICInboxTransaction, ICOutboxSalesHeader, ICInboxPurchaseHeader);

        ReceiveICPurchaseInvoice(
          PurchaseHeader, ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader, SalesHeader."No.", ICPartner."Vendor No.");

        // [THEN] Created Purchase Document has Currency Code = ''
        PurchaseHeader.TestField("Currency Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReceiveICPurchDocumentWithCurrencyEqualGLSetupLCYCode()
    var
        ICInboxTransaction: Record "IC Inbox Transaction";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICInboxSalesHeader: Record "IC Inbox Sales Header";
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        ICOutboxPurchaseHeader: Record "IC Outbox Purchase Header";
        Vendor: Record Vendor;
        ICPartner: Record "IC Partner";
        ICSetup: Record "IC Setup";
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
        ICPartnerVendorCode: Code[20];
    begin
        // [SCENARIO 416829] Intercompany Inbox Purch Document with Currency = GLSetup LCY Currency should be transferred to Sales Doc with empty currency
        Initialize();

        // [GIVEN] An IC Partner Code
        ICPartnerVendorCode := CreateICPartnerWithInbox();

        ICSetup.Get();
        ICSetup."Auto. Send Transactions" := false;
        ICSetup."IC Partner Code" := ICPartnerVendorCode;
        ICSetup.Modify();
        ICOutboxTransaction.DeleteAll();

        // [GIVEN] IC Partner with Customer No.
        ICPartner.Get(ICPartnerVendorCode);
        ICPartner.Validate("Customer No.", LibrarySales.CreateCustomerNo());
        ICPartner.Modify(true);

        // [GIVEN] Created Purchase Invoice
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        PurchaseHeader.Validate("Buy-from IC Partner Code", ICPartnerVendorCode);
        PurchaseHeader.Validate("Send IC Document", true);
        PurchaseHeader.Modify(true);

        // [GIVEN] Set IC Partner Code for created Vendor
        Vendor.Get(PurchaseHeader."Buy-from Vendor No.");
        Vendor.Validate("IC Partner Code", ICPartnerVendorCode);
        Vendor.Modify(true);

        // [GIVEN] Sales IC Purchase Document
        ICInboxOutboxMgt.SendPurchDoc(PurchaseHeader, false);
        ICOutboxTransaction."Document Type" := ICOutboxTransaction."Document Type"::Invoice;
        ICOutboxPurchaseHeader."Document Type" := ICOutboxPurchaseHeader."Document Type"::Invoice;

        FindICOutboxTransaction(
          ICOutboxTransaction, PurchaseHeader."No.", ICOutboxTransaction."Document Type",
          ICOutboxTransaction."IC Source Type"::"Purchase Document");
        FindICOutboxPurchaseHeader(
          ICOutboxPurchaseHeader, ICOutboxTransaction."Transaction No.",
          PurchaseHeader."No.", ICOutboxPurchaseHeader."Document Type");

        // [GIVEN] Receiving Company has General Ledger LCY Code = 'LCY'
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."LCY Code" := LibraryUtility.GenerateGUID();
        GeneralLedgerSetup.Modify();

        // [WHEN] Received document transferred to Receiving company
        ICInboxOutboxMgt.OutboxTransToInbox(ICOutboxTransaction, ICInboxTransaction, ICPartnerVendorCode);
        ICOutboxPurchaseHeader."Currency Code" := GeneralLedgerSetup."LCY Code";
        ICOutboxPurchaseHeader.Modify();
        ICInboxOutboxMgt.OutboxPurchHdrToInbox(ICInboxTransaction, ICOutboxPurchaseHeader, ICInboxSalesHeader);

        // [THEN] Created Purchase Document has Currency Code = ''
        ReceiveICSalesInvoice(
          SalesHeader, ICOutboxTransaction, ICInboxTransaction, ICInboxSalesHeader, PurchaseHeader."No.", ICPartner."Customer No.");
        SalesHeader.TestField("Currency Code", '');
    end;

    [Test]
    procedure PostSalesInvoiceWithInvoiceDiscount()
    var
        ReceivedPurchaseHeader: Record "Purchase Header";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICInboxTransaction: Record "IC Inbox Transaction";
        ICInboxPurchaseHeader: Record "IC Inbox Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
        ItemNo: Code[20];
        SalesInvoiceNo: Code[20];
        VendorNo: Code[20];
        CustomerNo: Code[20];
    begin
        // [SCENARIO 502491] Invoice discount amount on created IC purchase invoice is transferred from sales invoice
        Initialize();

        // [GIVEN] Create VAT posting setup, customer, vendor, item for IC flow
        // [GIVEN] VAT posting setup "X", VAT bus. posting group = "XX", VAT prod. posting group = "XY", VAT  = 0
        // [GIVEN] Vendor "X", IC partner code = "Z", VAT bus. posting group = "XX"
        // [GIVEN] Customer "Y", IC partner code = "Z", VAT bus. posting group = "XX"
        // [GIVEN] Item "X", VAT prod. posting group = "XY"
        LibraryERM.CreateVATPostingSetupWithAccounts(
            VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 0);
        VendorNo := CreateICVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group");
        CustomerNo := CreateICCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group");
        ItemNo := LibraryInventory.CreateItemNoWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group");

        // [GIVEN] Add permissions
        LibraryLowerPermissions.SetIntercompanyPostingsEdit();
        LibraryLowerPermissions.AddSalesDocsPost();
        LibraryLowerPermissions.AddO365Setup();
        LibraryLowerPermissions.AddPurchDocsPost();

        // [GIVEN] Create sales invoice 1, invoice discount amount = 100, item = "X"
        // [GIVEN] Post sales invoice 1
        SalesInvoiceNo := CreateAndPostSalesInvoiceWithDiscount(CustomerNo, ItemNo);

        // [GIVEN] Send sales invoice 1 to intercompany process
        SendICSalesInvoice(ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader, SalesInvoiceNo, GetICPartnerFromVendor(VendorNo));

        // [WHEN] Accept purchase invoice 1 in partner company
        ReceiveICPurchaseInvoice(ReceivedPurchaseHeader, ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader, SalesInvoiceNo, VendorNo);

        // [THEN] Purchase invoice 1 has the same invoice discount amount as sales invoice 1 in partner company
        VerifyInvoiceDiscountOnPurchaseLine(ReceivedPurchaseHeader, SalesInvoiceNo, ItemNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATDifferenceOnReceivedSalesDocShouldBeIncludedOnPurchaseDocumentForICCustomer()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SendGLAccount: Record "G/L Account";
        ReceiveGLAccount: Record "G/L Account";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICInboxTransaction: Record "IC Inbox Transaction";
        ICInboxPurchaseHeader: Record "IC Inbox Purchase Header";
        MaxAllowedVATDifference: Decimal;
        VendorNo: Code[20];
    begin
        // [SCENARIO 524493] [All-E] When making intercompany invoices a VAT difference is included in the sales invoice
        Initialize();
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddO365Setup();
        LibraryLowerPermissions.AddPurchDocsCreate();
        LibraryLowerPermissions.AddSalesDocsPost();
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();
        LibraryLowerPermissions.AddeRead();

        // [GIVEN] "VAT Difference" is allowed in setup
        MaxAllowedVATDifference := LibraryRandom.RandIntInRange(5, 10);
        LibraryERM.SetMaxVATDifferenceAllowed(MaxAllowedVATDifference);
        LibrarySales.SetAllowVATDifference(true);

        // [GIVEN] G/L Account 'X' with Default IC Partner G/L Account Number = 'Y'.
        // [GIVEN] G/L Account 'Y' with Default IC Partner G/L Account Number = 'X'.
        CreatePairOfSendReceiveGLAcc(SendGLAccount, ReceiveGLAccount);

        // [GIVEN] IC Vendor.
        VendorNo := CreateICVendorWithVATBusPostingGroup(SendGLAccount."VAT Bus. Posting Group");

        // [GIVEN] Sales Order for IC Customer.
        LibrarySales.CreateSalesHeader(
          SalesHeader,
          SalesHeader."Document Type"::Order,
          CreateICCustomerWithVATBusPostingGroup(SendGLAccount."VAT Bus. Posting Group"));

        // [GIVEN] Sales Line with 'X', "Description 2" is 'A'
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", SendGLAccount."No.",
          LibraryRandom.RandDecInRange(100, 200, 2));
        SalesLine."Description 2" := LibraryUtility.GenerateGUID();
        SalesLine.Validate("VAT Difference", MaxAllowedVATDifference);
        SalesLine.Modify();

        // [GIVEN] Send Sales Order.
        SendICSalesDocument(
          SalesHeader, GetICPartnerFromVendor(VendorNo), ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader);

        // [WHEN] Receive Purchase Order.
        ReceiveICPurchaseDocument(
          PurchaseHeader, SalesHeader, ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader, VendorNo);
        FindPurchLine(PurchaseLine, PurchaseHeader);

        // [THEN] Verify VAT Difference on Purchase Line is Same as it was set on Sales Line
        PurchaseLine.TestField("VAT Difference", SalesLine."VAT Difference");
    end;

    local procedure Initialize()
    var
        ICSetup: Record "IC Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"ERM Intercompany II");
        if not ICSetup.Get() then begin
            ICSetup.Init();
            ICSetup.Insert();
        end;
        ICSetup."Auto. Send Transactions" := false;
        ICSetup.Modify();
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        Clear(ICInboxOutboxMgt);

        APIMockEvents.SetIsAPIEnabled(true);

        if IsInitialized then
            exit;
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        IsInitialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"IC Setup");

        BindSubscription(APIMockEvents);
    end;

    local procedure BlockICGLAccount(ICGLAccountNo: Code[20])
    var
        ICGLAccount: Record "IC G/L Account";
    begin
        ICGLAccount.Get(ICGLAccountNo);
        ICGLAccount.Validate(Blocked, true);
        ICGLAccount.Modify(true);
    end;

    local procedure BlockICPartner(ICPartnerCode: Code[20])
    var
        ICPartner: Record "IC Partner";
    begin
        ICPartner.Get(ICPartnerCode);
        ICPartner.Validate(Blocked, true);
        ICPartner.Modify(true);
    end;

    local procedure CopyPurchaseDocument(PurchaseDocType: Enum "Purchase Document Type From"; PurchaseHeader: Record "Purchase Header"; ToPurchaseHeader: Record "Purchase Header")
    var
        CopyPurchaseDocumentInto: Report "Copy Purchase Document";
    begin
        CopyPurchaseDocumentInto.SetParameters(PurchaseDocType, PurchaseHeader."No.", true, false);
        CopyPurchaseDocumentInto.SetPurchHeader(ToPurchaseHeader);
        CopyPurchaseDocumentInto.UseRequestPage(false);
        CopyPurchaseDocumentInto.RunModal();
    end;

    local procedure CopyPurchaseLineFromPurchReceiptLine(PurchaseHeader: Record "Purchase Header"; PurchReceiptDocNo: Code[20])
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        LinesNotCopied: Integer;
        MissingExCostRevLink: Boolean;
    begin
        PurchRcptLine.SetRange("Document No.", PurchReceiptDocNo);
        PurchRcptLine.FindFirst();
        CopyDocumentMgt.CopyPurchRcptLinesToDoc(PurchaseHeader, PurchRcptLine, LinesNotCopied, MissingExCostRevLink);
    end;

    local procedure CopySalesLineFromSalesShipmentLine(SalesHeader: Record "Sales Header"; SalesShipDocNo: Code[20])
    var
        SalesShipmentLine: Record "Sales Shipment Line";
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        LinesNotCopied: Integer;
        MissingExCostRevLink: Boolean;
    begin
        SalesShipmentLine.SetRange("Document No.", SalesShipDocNo);
        SalesShipmentLine.FindFirst();
        CopyDocumentMgt.CopySalesShptLinesToDoc(SalesHeader, SalesShipmentLine, LinesNotCopied, MissingExCostRevLink);
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(
          Item, LibraryRandom.RandDec(1000, 2), LibraryRandom.RandDec(1000, 2));
        exit(Item."No.");
    end;

    local procedure CreateTrackedItem(): Code[20]
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryInventory.CreateItemTrackingCode(ItemTrackingCode);
        LibraryInventory.CreateTrackedItem(Item, '', '', ItemTrackingCode.Code);
        exit(Item."No.");
    end;

    local procedure CreateItemReference(ItemNo: Code[20]; VariantCode: Code[10]; UnitOfMeasureCode: Code[10]; ReferenceType: Enum "Item Reference Type"; ReferenceTypeNo: Code[20]; ReferenceNo: Code[20]): Code[20]
    var
        ItemReference: Record "Item Reference";
    begin
        ItemReference.Init();
        ItemReference."Item No." := ItemNo;
        ItemReference."Variant Code" := VariantCode;
        ItemReference."Unit of Measure" := UnitOfMeasureCode;
        ItemReference."Reference Type" := ReferenceType;
        ItemReference."Reference Type No." := ReferenceTypeNo;
        ItemReference."Reference No." := ReferenceNo;
        ItemReference.Insert();
        exit(ReferenceNo);
    end;

    local procedure CreateAssembledItem(var Item: Record Item)
    begin
        LibraryAssembly.SetupAssemblyItem(
          Item, "Costing Method"::Standard, "Costing Method"::Standard, "Replenishment System"::Assembly,
          '', false, LibraryRandom.RandInt(5), LibraryRandom.RandInt(5),
          LibraryRandom.RandInt(5), LibraryRandom.RandInt(5));
        Item.Validate("Assembly Policy", Item."Assembly Policy"::"Assemble-to-Order");
        Item.Modify(true);
    end;

    local procedure CreateItemRefWithVariant(ItemNo: Code[20]; CustNo: Code[20]; VendNo: Code[20]): Code[20]
    var
        ItemVariant: Record "Item Variant";
        Item: Record Item;
        RefItemNo: Code[20];
    begin
        LibraryInventory.CreateItemVariant(ItemVariant, ItemNo);
        Item.Get(ItemNo);
        RefItemNo := LibraryInventory.CreateItemNo();
        CreateItemReference(
            ItemNo, ItemVariant.Code, Item."Base Unit of Measure", "Item Reference Type"::Vendor, VendNo, RefItemNo);
        CreateItemReference(
            ItemNo, ItemVariant.Code, Item."Base Unit of Measure", "Item Reference Type"::Customer, CustNo, RefItemNo);
        exit(RefItemNo);
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);
    end;

    local procedure CreateLocation(): Code[10]
    var
        Location: Record Location;
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        exit(Location.Code);
    end;

    local procedure CreateAndUpdateICCustomer(ICPartnerCode: Code[20]; Blocked: Enum "Customer Blocked"): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer.Get(CreateICCustomer(ICPartnerCode));
        Customer.Validate(Blocked, Blocked);
        Customer.Modify(true);
        exit(Customer."No.")
    end;

    local procedure CreateAndUpdateICVendor(ICPartnerCode: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(CreateICVendor(ICPartnerCode));
        Vendor.Validate(Blocked, Vendor.Blocked::All);
        Vendor.Modify(true);
        exit(Vendor."No.")
    end;

    local procedure CreateICGLAccount(var ICGLAccount: Record "IC G/L Account")
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateICGLAccount(ICGLAccount);
        ICGLAccount.Validate("Map-to G/L Acc. No.", GLAccount."No.");
        ICGLAccount.Modify(true);
    end;

    local procedure CreateICPartnerWithCommonItemOutbndType(): Code[20]
    var
        ICPartner: Record "IC Partner";
    begin
        ICPartner.Get(CreateICPartner());
        ICPartner.Validate("Outbound Sales Item No. Type", ICPartner."Outbound Sales Item No. Type"::"Common Item No.");
        ICPartner.Validate("Outbound Purch. Item No. Type", ICPartner."Outbound Purch. Item No. Type"::"Common Item No.");
        ICPartner.Modify();
        exit(ICPartner.Code);
    end;

    local procedure CreateICPartner(): Code[20]
    var
        ICPartner: Record "IC Partner";
    begin
        CreateICPartnerBase(ICPartner);
        ICPartner.Validate("Inbox Type", ICPartner."Inbox Type"::Database);
        ICPartner.Validate("Inbox Details", CompanyName);
        ICPartner.Modify(true);
        exit(ICPartner.Code);
    end;

    local procedure CreateICPartnerBase(var ICPartner: Record "IC Partner")
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateICPartner(ICPartner);
        ICPartner.Validate("Receivables Account", GLAccount."No.");
        LibraryERM.CreateGLAccount(GLAccount);
        ICPartner.Validate("Payables Account", GLAccount."No.");
    end;

    local procedure CreateICPartnerWithInboxTypeFileLocation(): Code[20]
    var
        ICPartner: Record "IC Partner";
        FileManagement: Codeunit "File Management";
        FileName: Text;
    begin
        CreateICPartnerBase(ICPartner);
        FileName := FileManagement.ServerTempFileName('');
        ICPartner.Validate("Inbox Type", ICPartner."Inbox Type"::"File Location");
        ICPartner.Validate("Inbox Details", FileManagement.GetDirectoryName(FileName));
        ICPartner.Modify(true);
        exit(ICPartner.Code);
    end;

    local procedure CreateICJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; Type: Enum "Gen. Journal Template Type")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, Type);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateICCustomer(ICPartnerCode: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("IC Partner Code", ICPartnerCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateICCustomerWithVATBusPostingGroup(VATBusPostingGroup: Code[20]): Code[20]
    var
        ICCustomer: Record Customer;
    begin
        ICCustomer.Get(CreateICCustomer(CreateICPartner()));
        ICCustomer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        ICCustomer.Modify(true);
        exit(ICCustomer."No.");
    end;

    local procedure CreateICVendor(ICPartnerCode: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("IC Partner Code", ICPartnerCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateICVendorWithVATBusPostingGroup(VATBusPostingGroup: Code[20]): Code[20]
    var
        ICVendor: Record Vendor;
    begin
        ICVendor.Get(CreateICVendor(CreateICPartner()));
        ICVendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        ICVendor.Modify(true);
        exit(ICVendor."No.");
    end;

    local procedure CreateCustomerWithVATBusPostingGroup(VATBusPostingGroupCode: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroupCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateICGLAccountWithDefaultICPartnerGLAccNo(var GLAccount: Record "G/L Account")
    var
        ICGLAccount: Record "IC G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.CreateICGLAccount(ICGLAccount);
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandDecInDecimalRange(10, 25, 0));
        GLAccount.Get(
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase));
        GLAccount.Validate("Default IC Partner G/L Acc. No", ICGLAccount."No.");
        GLAccount.Modify(true);
    end;

    local procedure CreateICGLAccountWithVATPostingGroup(var GLAccount: Record "G/L Account"; var VATPostingSetup: Record "VAT Posting Setup")
    var
        ICGLAccount: Record "IC G/L Account";
    begin
        LibraryERM.CreateICGLAccount(ICGLAccount);
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandDecInDecimalRange(10, 25, 0));
        GLAccount.Get(
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase));
        GLAccount.Validate("Default IC Partner G/L Acc. No", ICGLAccount."No.");
        GLAccount.Modify(true);
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; BalAccountType: Enum "Gen. Journal Account Type"; BalAccountNo: Code[20]; ICPartnerGLAccNo: Code[20]; SignFactor: Integer)
    begin
        // Take Random Amount.
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          AccountType, AccountNo, SignFactor * LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate("Bal. Account Type", BalAccountType);
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Validate("IC Account Type", "IC Journal Account Type"::"G/L Account");
        GenJournalLine.Validate("IC Account No.", ICPartnerGLAccNo);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateICGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal)
    var
        ICGLAccount: Record "IC G/L Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        CreateICGLAccount(ICGLAccount);
        CreateICJournalBatch(GenJournalBatch, GenJournalTemplate.Type::Intercompany);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, AccountType, AccountNo, GenJournalLine."Bal. Account Type"::"G/L Account",
          ICGLAccount."Map-to G/L Acc. No.", ICGLAccount."No.", Amount);
    end;

    local procedure CreatePartnerCustomerVendor(var ICPartnerCodeVendor: Code[20]; var VendorNo: Code[20]; var CustomerNo: Code[20])
    begin
        ICPartnerCodeVendor := CreateICPartner();
        VendorNo := CreateICVendor(ICPartnerCodeVendor);
        CustomerNo := CreateICCustomer(CreateICPartner());
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; ItemNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo,
          LibraryRandom.RandDecInRange(100, 200, 2));  // Using Random value for Quantity.
    end;

    local procedure CreatePurchaseInvoiceWithLines(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; GLAccountNo: Code[20]; ItemNo: Code[20]): Code[20]
    var
        PurchaseLine: array[4] of Record "Purchase Line";
        i: Integer;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, Enum::"Purchase Document Type"::Invoice, VendorNo);

        // Two lines where "Type" = "G/L Account"
        for i := 1 to 2 do
            LibraryPurchase.CreatePurchaseLine(PurchaseLine[i], PurchaseHeader, PurchaseLine[i].Type::"G/L Account", GLAccountNo, 1);

        //add custom description for second line
        PurchaseLine[2].Description := GLAccountDescriptionLbl;
        PurchaseLine[2].Modify();

        // Two Lines where "Type" = "Item"
        for i := 3 to 4 do
            LibraryPurchase.CreatePurchaseLine(PurchaseLine[i], PurchaseHeader, PurchaseLine[i].Type::Item, ItemNo, 1);

        //add custom description for fourth line
        PurchaseLine[4].Description := ItemDescriptionLbl;
        PurchaseLine[4].Modify();

        exit(PurchaseHeader."No.");
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; VATBusPostingGroup: Code[20]; GLAccountNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateICVendorWithVATBusPostingGroup(VATBusPostingGroup));
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccountNo, LibraryRandom.RandIntInRange(10, 100));
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; ItemNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandIntInRange(50, 100));  // Using Random value for Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; VATBusPostingGroup: Code[20]; GLAccountNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Order, CreateICCustomerWithVATBusPostingGroup(VATBusPostingGroup));
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccountNo, LibraryRandom.RandIntInRange(10, 100));
    end;

    local procedure CreateSalesDocumentWithDeliveryDates(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; var ICPartnerCode: Code[20]; var VendorNo: Code[20]; ItemRef: Boolean; PricesInclVAT: Boolean; OutboundType: Enum "IC Outb. Sales Item No. Type")
    var
        SalesLine: Record "Sales Line";
    begin
        ICPartnerCode := CreateICPartner();
        UpdateICPartnerWithOutboundType(ICPartnerCode, OutboundType);
        VendorNo := CreateICVendor(ICPartnerCode);

        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CreateICCustomer(ICPartnerCode));
        SalesHeader.Validate("Prices Including VAT", PricesInclVAT);
        SalesHeader.Modify();

        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandIntInRange(10, 100));

        SalesLine.Validate("Unit Price", SalesLine."Unit Price" + LibraryRandom.RandDec(1000, 2));
        if ItemRef then
            SalesLine.Validate(
              "Item Reference No.",
              CreateItemRefWithVariant(SalesLine."No.", SalesLine."Sell-to Customer No.", VendorNo));
        SalesLine.Modify(true);

        SalesHeader.Validate(
          "Requested Delivery Date",
          CalcDate(StrSubstNo(DateLbl, LibraryRandom.RandIntInRange(5, 10)), WorkDate()));
        SalesHeader.Validate(
          "Promised Delivery Date",
          CalcDate(StrSubstNo(DateLbl, LibraryRandom.RandIntInRange(1, 4)), WorkDate()));
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesDocumentWithExternalDocNoForICCustomer(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type")
    var
        ICPartnerCode: Code[20];
    begin
        ICPartnerCode := CreateICPartner();
        CreateSalesDocument(SalesHeader, DocumentType, CreateICCustomer(ICPartnerCode), CreateItem());
        UpdateSalesDocumentExternalDocumentNo(SalesHeader, LibraryUtility.GenerateGUID());
        FindSalesLine(SalesLine, SalesHeader);
    end;

    local procedure CreateRoundingSalesDoc(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type")
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CreateICCustomer(CreateICPartner()));
        SalesHeader.Validate("Prices Including VAT", true);
        SalesHeader.Modify();

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), 1);
        SalesLine.Validate("Unit Price", 0.9);
        SalesLine.Modify(true);
    end;

    local procedure CreateEmptySalesLine(SalesHeader: Record "Sales Header"; GLAccountNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccountNo, LibraryRandom.RandInt(10));
        SalesLine.Validate("No.", '');
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchaseDocumentWithReceiptDates(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; var ICPartnerCode: Code[20]; var CustomerNo: Code[20]; ItemNo: Code[20]; Qty: Decimal; ItemRef: Boolean; PricesInclVAT: Boolean; OutboundType: Enum "IC Outb. Sales Item No. Type")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        ICPartnerCode := CreateICPartner();
        UpdateICPartnerWithOutboundType(ICPartnerCode, OutboundType);
        CustomerNo := CreateICCustomer(ICPartnerCode);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, CreateICVendor(ICPartnerCode));
        PurchaseHeader.Validate("Prices Including VAT", PricesInclVAT);
        PurchaseHeader.Modify();

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Qty);

        PurchaseLine.Validate("Direct Unit Cost", PurchaseLine."Direct Unit Cost" + LibraryRandom.RandDec(1000, 2));
        if ItemRef then
            PurchaseLine.Validate(
              "Item Reference No.",
              CreateItemRefWithVariant(PurchaseLine."No.", CustomerNo, PurchaseLine."Buy-from Vendor No."));

        PurchaseLine.Modify(true);

        PurchaseHeader.Validate(
          "Requested Receipt Date",
          CalcDate(StrSubstNo(DateLbl, LibraryRandom.RandIntInRange(5, 10)), WorkDate()));
        PurchaseHeader.Validate(
          "Promised Receipt Date",
          CalcDate(StrSubstNo(DateLbl, LibraryRandom.RandIntInRange(1, 4)), WorkDate()));
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePostPurchaseReceipt(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]): Code[20]
    var
        ItemNo: Code[20];
    begin
        ItemNo := CreateItem();
        CreatePurchaseDocument(PurchaseHeader, DocumentType, VendorNo, ItemNo);
        UpdatePurchaseDocumentLocation(PurchaseHeader, CreateLocation());
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false));
    end;

    local procedure CreatePostPurchaseReceiptForNewVendor(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; var ICPartnerCodeVendor: Code[20]): Code[20]
    begin
        ICPartnerCodeVendor := CreateICPartner();
        exit(CreatePostPurchaseReceipt(PurchaseHeader, DocumentType, CreateICVendor(ICPartnerCodeVendor)));
    end;

    local procedure CreatePurchInvWithGLAccount(var PurchaseHeader: Record "Purchase Header"; GLAccount: Record "G/L Account"; ICPartnerCode: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Get(GLAccount."VAT Bus. Posting Group", GLAccount."VAT Prod. Posting Group");
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccount."No.",
          LibraryRandom.RandDecInRange(100, 200, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        UpdatePurchaseLineICPartnerInfo(
          PurchaseLine, ICPartnerCode, PurchaseLine."IC Partner Ref. Type"::"G/L Account",
          GLAccount."Default IC Partner G/L Acc. No");
    end;

    local procedure CreateSalesInvWithGLAccount(var SalesHeader: Record "Sales Header"; GLAccount: Record "G/L Account"; ICPartnerCode: Code[20])
    var
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Get(GLAccount."VAT Bus. Posting Group", GLAccount."VAT Prod. Posting Group");
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Invoice,
          CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccount."No.",
          LibraryRandom.RandDecInRange(100, 200, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        UpdateSalesLineICPartnerInfo(
          SalesLine, ICPartnerCode, SalesLine."IC Partner Ref. Type"::"G/L Account",
          GLAccount."Default IC Partner G/L Acc. No");
    end;

    local procedure CreateSalesInvoiceWithGetShipmentLines(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20])
    var
        SalesShipmentLine: Record "Sales Shipment Line";
        SalesGetShipment: Codeunit "Sales-Get Shipment";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesGetShipment.SetSalesHeader(SalesHeader);
        SalesShipmentLine.SetRange("Sell-to Customer No.", CustomerNo);
        SalesGetShipment.CreateInvLines(SalesShipmentLine);
    end;

    local procedure CreateSalesCrMemoWithGetRetReceiptLines(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20])
    var
        ReturnReceiptLine: Record "Return Receipt Line";
        SalesGetReturnReceipts: Codeunit "Sales-Get Return Receipts";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CustomerNo);
        SalesGetReturnReceipts.SetSalesHeader(SalesHeader);
        ReturnReceiptLine.SetRange("Sell-to Customer No.", CustomerNo);
        SalesGetReturnReceipts.CreateInvLines(ReturnReceiptLine);
    end;

    local procedure CreateSendSalesDocumentReceivePurchaseDocument(var SalesHeader: Record "Sales Header"; var PurchaseHeader: Record "Purchase Header"; PricesInclVAT: Boolean)
    var
        DummyICPartner: Record "IC Partner";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICInboxTransaction: Record "IC Inbox Transaction";
        ICInboxPurchaseHeader: Record "IC Inbox Purchase Header";
        ICPartnerCode: Code[20];
        VendorNo: Code[20];
    begin
        CreateSalesDocumentWithDeliveryDates(
          SalesHeader, SalesHeader."Document Type"::Order, ICPartnerCode, VendorNo, false, PricesInclVAT,
          DummyICPartner."Outbound Sales Item No. Type"::"Internal No.");
        SendICSalesDocument(
          SalesHeader, ICPartnerCode, ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader);
        ReceiveICPurchaseDocument(
          PurchaseHeader, SalesHeader, ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader, VendorNo);
    end;

    local procedure CreateSendPurchaseDocumentReceiveSalesDocument(var PurchaseHeader: Record "Purchase Header"; var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Qty: Decimal; PricesInclVAT: Boolean)
    var
        DummyICPartner: Record "IC Partner";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICInboxTransaction: Record "IC Inbox Transaction";
        ICInboxSalesHeader: Record "IC Inbox Sales Header";
        ICPartnerCode: Code[20];
        CustomerNo: Code[20];
    begin
        CreatePurchaseDocumentWithReceiptDates(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, ICPartnerCode, CustomerNo,
          ItemNo, Qty, false, PricesInclVAT,
          DummyICPartner."Outbound Purch. Item No. Type"::"Internal No.");
        SendICPurchaseDocument(
          PurchaseHeader, ICPartnerCode, ICOutboxTransaction, ICInboxTransaction, ICInboxSalesHeader);
        ReceiveICSalesDocument(
          SalesHeader, PurchaseHeader, ICOutboxTransaction, ICInboxTransaction, ICInboxSalesHeader, CustomerNo);
    end;

    local procedure CreateAndSendSalesOrderWithShipToCountryRegionAndCounty(var SalesHeader: Record "Sales Header"; var ICOutboxTransaction: Record "IC Outbox Transaction"; var ICInboxTransaction: Record "IC Inbox Transaction"; var ICInboxPurchaseHeader: Record "IC Inbox Purchase Header"; var VendorNo: Code[20])
    var
        SendGLAccount: Record "G/L Account";
    begin
        CreateGLAccount(SendGLAccount);
        VendorNo := CreateICVendorWithVATBusPostingGroup(SendGLAccount."VAT Bus. Posting Group");

        CreateSalesOrder(SalesHeader, SendGLAccount."VAT Bus. Posting Group", SendGLAccount."No.");
        ModifySalesHeaderShipToCountryRegionAndCounty(SalesHeader);

        SendICSalesDocument(
          SalesHeader, GetICPartnerFromVendor(VendorNo), ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader);
    end;

    local procedure CreateAndSendPurchOrderWithShipToCountryRegionAndCounty(var PurchaseHeader: Record "Purchase Header"; var ICOutboxTransaction: Record "IC Outbox Transaction"; var ICInboxTransaction: Record "IC Inbox Transaction"; var ICInboxSalesHeader: Record "IC Inbox Sales Header"; var CustNo: Code[20])
    var
        SendGLAccount: Record "G/L Account";
    begin
        CreateGLAccount(SendGLAccount);
        CustNo := CreateICCustomerWithVATBusPostingGroup(SendGLAccount."VAT Bus. Posting Group");

        CreatePurchaseOrder(PurchaseHeader, SendGLAccount."VAT Bus. Posting Group", SendGLAccount."No.");
        ModifyPurchHeaderShipToCountryRegionAndCounty(PurchaseHeader);

        SendICPurchaseDocument(
          PurchaseHeader, GetICPartnerFromCustomer(CustNo), ICOutboxTransaction, ICInboxTransaction, ICInboxSalesHeader);
    end;

    local procedure CreatePostPurchReceiptCreatePostSalesShipment(var PurchaseHeader: Record "Purchase Header"; var SalesHeader: Record "Sales Header"; VendorNo: Code[20]; CustomerNo: Code[20]; DocumentType: Enum "Purchase Document Type")
    var
        ItemNo: Code[20];
    begin
        ItemNo := CreateItem();
        CreatePurchaseDocument(PurchaseHeader, DocumentType, VendorNo, ItemNo);
        UpdatePurchaseDocumentLocation(PurchaseHeader, CreateLocation());
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        CreateSalesDocument(SalesHeader, DocumentType, CustomerNo, ItemNo);
        UpdateSalesDocumentLocation(SalesHeader, CreateLocation());
        UpdateSalesDocumentExternalDocumentNo(SalesHeader, PurchaseHeader."No.");
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
    end;

    local procedure CreateAndPostSalesInvoice(CustomerNo: Code[20]; GLAccountNo: Code[20]; ItemNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: array[4] of Record "Sales Line";
        i: Integer;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);

        // Two lines where "Type" = "G/L Account"
        for i := 1 to 2 do
            LibrarySales.CreateSalesLine(SalesLine[i], SalesHeader, SalesLine[i].Type::"G/L Account", GLAccountNo, 1);

        //add custom description for second line
        SalesLine[2].Description := GLAccountDescriptionLbl;
        SalesLine[2].Modify();

        // Two Lines where "Type" = "Item"
        for i := 3 to 4 do
            LibrarySales.CreateSalesLine(SalesLine[i], SalesHeader, SalesLine[i].Type::Item, ItemNo, 1);

        //add custom description for fourth line
        SalesLine[4].Description := ItemDescriptionLbl;
        SalesLine[4].Modify();

        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreatePostSalesInvoiceWithGetShipmentLines(CustomerNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesInvoiceWithGetShipmentLines(SalesHeader, CustomerNo);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreatePostSalesCrMemoWithGetRetReceiptLines(CustomerNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesCrMemoWithGetRetReceiptLines(SalesHeader, CustomerNo);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostMultipleReceiptsWithTrackingAndPrepareInvoiceFromVendor(var InvoiceNo: Code[20]; VendorNo: Code[20]; ICPartnerCode: Code[20]; QtysToReceive: Text; QtysToInvoice: Text)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemNo: Code[20];
        CustomerNo: Code[20];
        Qty: Decimal;
        i: Integer;
    begin
        ItemNo := CreateTrackedItem();
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, VendorNo, ItemNo, 5, '', WorkDate());

        for i := 1 to 2 do begin
            Evaluate(Qty, SelectStr(i, QtysToReceive));
            FindPurchLine(PurchaseLine, PurchaseHeader);
            PurchaseLine.Validate("Qty. to Receive", Qty);
            PurchaseLine.Modify(true);

            LibraryVariableStorage.Enqueue(Qty);
            PurchaseLine.OpenItemTrackingLines();

            LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        end;

        CustomerNo := CreateICCustomer(ICPartnerCode);
        SendPurchaseDocumentReceiveSalesDocument(PurchaseHeader, SalesHeader, ICPartnerCode, CustomerNo);

        for i := 1 to 2 do begin
            Evaluate(Qty, SelectStr(i, QtysToInvoice));
            FindSalesLine(SalesLine, SalesHeader);
            SalesLine.Validate("Qty. to Ship", Qty);
            SalesLine.Modify(true);

            LibrarySales.PostSalesDocument(SalesHeader, true, false);
        end;

        CreateSalesInvoiceWithGetShipmentLines(SalesHeader, CustomerNo);
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateAndPostMultipleRetShipmentsWithTrackingAndPrepareInvoiceFromVendor(var CreditMemoNo: Code[20]; VendorNo: Code[20]; ICPartnerCode: Code[20]; QtysToShip: Text; QtysToInvoice: Text)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemNo: Code[20];
        CustomerNo: Code[20];
        Qty: Decimal;
        i: Integer;
    begin
        ItemNo := CreateTrackedItem();
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Return Order", VendorNo, ItemNo, 5, '', WorkDate());

        for i := 1 to 2 do begin
            Evaluate(Qty, SelectStr(i, QtysToShip));
            FindPurchLine(PurchaseLine, PurchaseHeader);
            PurchaseLine.Validate("Return Qty. to Ship", Qty);
            PurchaseLine.Modify(true);

            LibraryVariableStorage.Enqueue(Qty);
            PurchaseLine.OpenItemTrackingLines();

            LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        end;

        CustomerNo := CreateICCustomer(ICPartnerCode);
        SendPurchaseDocumentReceiveSalesDocument(PurchaseHeader, SalesHeader, ICPartnerCode, CustomerNo);

        for i := 1 to 2 do begin
            Evaluate(Qty, SelectStr(i, QtysToInvoice));
            FindSalesLine(SalesLine, SalesHeader);
            SalesLine.Validate("Return Qty. to Receive", Qty);
            SalesLine.Modify(true);

            LibrarySales.PostSalesDocument(SalesHeader, true, false);
        end;

        CreateSalesCrMemoWithGetRetReceiptLines(SalesHeader, CustomerNo);
        CreditMemoNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateVendorLedgEntry(VendorNo: Code[20]; PostingDate: Date; IsOpen: Boolean)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        RecRef: RecordRef;
    begin
        VendorLedgerEntry.Init();
        RecRef.GetTable(VendorLedgerEntry);
        VendorLedgerEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, VendorLedgerEntry.FieldNo("Entry No."));
        VendorLedgerEntry."Posting Date" := PostingDate;
        VendorLedgerEntry."Vendor No." := VendorNo;
        VendorLedgerEntry.Open := IsOpen;
        VendorLedgerEntry.Insert();
    end;

    local procedure CreateCustLedgEntry(CustomerNo: Code[20]; PostingDate: Date; IsOpen: Boolean)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        RecRef: RecordRef;
    begin
        CustLedgerEntry.Init();
        RecRef.GetTable(CustLedgerEntry);
        CustLedgerEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, CustLedgerEntry.FieldNo("Entry No."));
        CustLedgerEntry."Posting Date" := PostingDate;
        CustLedgerEntry."Customer No." := CustomerNo;
        CustLedgerEntry.Open := IsOpen;
        CustLedgerEntry.Insert();
    end;

    local procedure CreateGLAccount(var GLAccount: Record "G/L Account")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        ICGLAccount: Record "IC G/L Account";
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandDecInDecimalRange(10, 25, 0));
        CreateICGLAccountWithVATPostingSetup(GLAccount, ICGLAccount, VATPostingSetup);
        UpdateGLAccountDefaultICPartnerGLAccNo(GLAccount, ICGLAccount."No.");
    end;

    local procedure CreatePairOfSendReceiveGLAcc(var SendGLAccount: Record "G/L Account"; var ReceiveGLAccount: Record "G/L Account")
    var
        SendICGLAccount: Record "IC G/L Account";
        ReceiveICGLAccount: Record "IC G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandDecInDecimalRange(10, 25, 0));

        CreateICGLAccountWithVATPostingSetup(SendGLAccount, SendICGLAccount, VATPostingSetup);
        CreateICGLAccountWithVATPostingSetup(ReceiveGLAccount, ReceiveICGLAccount, VATPostingSetup);

        UpdateGLAccountDefaultICPartnerGLAccNo(SendGLAccount, ReceiveICGLAccount."No.");
        UpdateGLAccountDefaultICPartnerGLAccNo(ReceiveGLAccount, SendICGLAccount."No.");
    end;

    local procedure CreateICGLAccountWithVATPostingSetup(var GLAccount: Record "G/L Account"; var ICGLAccount: Record "IC G/L Account"; VATPostingSetup: Record "VAT Posting Setup")
    begin
        GLAccount.Get(
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase));
        LibraryERM.CreateICGLAccount(ICGLAccount);
        ICGLAccount.Validate("Map-to G/L Acc. No.", GLAccount."No.");
        ICGLAccount.Modify(true);
    end;

    local procedure CreateICPartnerWithInbox(): Code[20]
    var
        ICPartner: Record "IC Partner";
    begin
        CreateICPartnerBase(ICPartner);
        ICPartner.Validate(Name, LibraryUtility.GenerateGUID());
        ICPartner.Validate("Inbox Type", ICPartner."Inbox Type"::"File Location");
        ICPartner.Validate("Inbox Details", CompanyName);
        ICPartner.Modify(true);
        exit(ICPartner.Code);
    end;

    local procedure MockICInboxSalesHeaderWithShipToCountryRegionAndCounty(var ICInboxSalesHeader: Record "IC Inbox Sales Header"; Customer: Record Customer)
    begin
        ICInboxSalesHeader.Init();
        ICInboxSalesHeader."IC Transaction No." :=
          LibraryUtility.GetNewRecNo(ICInboxSalesHeader, ICInboxSalesHeader.FieldNo("IC Transaction No."));
        ICInboxSalesHeader."IC Partner Code" := Customer."IC Partner Code";
        ICInboxSalesHeader."Transaction Source" := ICInboxSalesHeader."Transaction Source"::"Created by Partner";
        ICInboxSalesHeader."Document Type" := ICInboxSalesHeader."Document Type"::Order;
        ICInboxSalesHeader."Sell-to Customer No." := Customer."No.";
        ICInboxSalesHeader."Bill-to Customer No." := Customer."No.";
        ICInboxSalesHeader."Ship-to Country/Region Code" := LibraryUtility.GenerateGUID();
        ICInboxSalesHeader."Ship-to County" := PadStr(
            LibraryUtility.GenerateRandomText(MaxStrLen(ICInboxSalesHeader."Ship-to County")),
            MaxStrLen(ICInboxSalesHeader."Ship-to County"));
        ICInboxSalesHeader."Posting Date" := WorkDate();
        ICInboxSalesHeader.Insert();
    end;

    local procedure MockICInboxPurchHeaderWithShipToCountryRegionAndCounty(var ICInboxPurchaseHeader: Record "IC Inbox Purchase Header")
    var
        VendorNo: Code[20];
        ICPartnerCode: Code[20];
    begin
        ICPartnerCode := CreateICPartner();
        VendorNo := CreateICVendor(ICPartnerCode);
        ICInboxPurchaseHeader.Init();
        ICInboxPurchaseHeader."IC Transaction No." :=
          LibraryUtility.GetNewRecNo(ICInboxPurchaseHeader, ICInboxPurchaseHeader.FieldNo("IC Transaction No."));
        ICInboxPurchaseHeader."IC Partner Code" := ICPartnerCode;
        ICInboxPurchaseHeader."Transaction Source" := ICInboxPurchaseHeader."Transaction Source"::"Created by Partner";
        ICInboxPurchaseHeader."Document Type" := ICInboxPurchaseHeader."Document Type"::Order;
        ICInboxPurchaseHeader."Buy-from Vendor No." := VendorNo;
        ICInboxPurchaseHeader."Pay-to Vendor No." := VendorNo;
        ICInboxPurchaseHeader."Ship-to Country/Region Code" := LibraryUtility.GenerateGUID();
        ICInboxPurchaseHeader."Ship-to County" := PadStr(
            LibraryUtility.GenerateRandomText(MaxStrLen(ICInboxPurchaseHeader."Ship-to County")),
            MaxStrLen(ICInboxPurchaseHeader."Ship-to County"));
        ICInboxPurchaseHeader.Insert();
    end;

    local procedure MockICInboxSalesLine(var ICInboxSalesLine: Record "IC Inbox Sales Line"; ICInboxSalesHeader: Record "IC Inbox Sales Header"; ItemNo: Code[20]; UnitPrice: Decimal; Qty: Decimal; AmtInclVAT: Decimal)
    begin
        ICInboxSalesLine."IC Transaction No." := ICInboxSalesHeader."IC Transaction No.";
        ICInboxSalesLine."IC Partner Code" := ICInboxSalesHeader."IC Partner Code";
        ICInboxSalesLine."Transaction Source" := ICInboxSalesHeader."Transaction Source";
        ICInboxSalesLine."Document Type" := ICInboxSalesHeader."Document Type";
        ICInboxSalesLine."Line No." := LibraryUtility.GetNewRecNo(ICInboxSalesLine, ICInboxSalesLine.FieldNo("Line No."));
        ICInboxSalesLine."IC Partner Ref. Type" := ICInboxSalesLine."IC Partner Ref. Type"::Item;
        ICInboxSalesLine."IC Partner Reference" := ItemNo;
        ICInboxSalesLine."Unit Price" := UnitPrice;
        ICInboxSalesLine.Quantity := Qty;
        ICInboxSalesLine."Line Amount" := ICInboxSalesLine."Unit Price" * ICInboxSalesLine.Quantity;
        ICInboxSalesLine."VAT Base Amount" := ICInboxSalesLine."Unit Price" * ICInboxSalesLine.Quantity;
        ICInboxSalesLine."Amount Including VAT" := AmtInclVAT;
        ICInboxSalesLine.Insert();
    end;

    local procedure UpdateGLAccountDefaultICPartnerGLAccNo(var GLAccount: Record "G/L Account"; ICGLAccountNo: Code[20])
    begin
        GLAccount.Validate("Default IC Partner G/L Acc. No", ICGLAccountNo);
        GLAccount.Modify(true);
    end;

    local procedure GetICPartnerFromCustomer(CustomerNo: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        exit(Customer."IC Partner Code");
    end;

    local procedure GetICPartnerFromVendor(VendorNo: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        exit(Vendor."IC Partner Code");
    end;

    local procedure VerifyCurrencyCodeInICOutboxSalesHeader(ICPartnerCode: Code[20]; DocNo: Code[20]; CurrencyCode: Code[10])
    var
        ICOutboxSalesHeader: Record "IC Outbox Sales Header";
    begin
        ICOutboxSalesHeader.SetRange("IC Partner Code", ICPartnerCode);
        ICOutboxSalesHeader.SetRange("No.", DocNo);
        ICOutboxSalesHeader.FindFirst();
        ICOutboxSalesHeader.TestField("Currency Code", CurrencyCode);
    end;

    local procedure VerifyCurrencyCodeInICOutboxPurchHeader(ICPartnerCode: Code[20]; DocNo: Code[20]; CurrencyCode: Code[10])
    var
        ICOutboxPurchaseHeader: Record "IC Outbox Purchase Header";
    begin
        ICOutboxPurchaseHeader.SetRange("IC Partner Code", ICPartnerCode);
        ICOutboxPurchaseHeader.SetRange("No.", DocNo);
        ICOutboxPurchaseHeader.FindFirst();
        ICOutboxPurchaseHeader.TestField("Currency Code", CurrencyCode);
    end;

    local procedure VerifyShipmentReceiptNosInICOutboxSalesLine(PostedDocNo: Code[20]; ICOutboxTransDocType: Enum "IC Transaction Document Type"; ICOutboxSalesDocType: Enum "IC Outbox Sales Document Type"; ShipmentNo: Code[20]; ShipmentLineNo: Integer; ReturnReceiptNo: Code[20]; ReturnReceiptLineNo: Integer)
    var
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICOutboxSalesLine: Record "IC Outbox Sales Line";
    begin
        FindICOutboxTransaction(
          ICOutboxTransaction, PostedDocNo, ICOutboxTransDocType, ICOutboxTransaction."IC Source Type"::"Sales Document");
        FindICOutboxSalesLine(
          ICOutboxSalesLine, ICOutboxTransaction."Transaction No.", PostedDocNo, ICOutboxSalesDocType);

        ICOutboxSalesLine.TestField("Shipment No.", ShipmentNo);
        ICOutboxSalesLine.TestField("Shipment Line No.", ShipmentLineNo);
        ICOutboxSalesLine.TestField("Return Receipt No.", ReturnReceiptNo);
        ICOutboxSalesLine.TestField("Return Receipt Line No.", ReturnReceiptLineNo);
    end;

    local procedure DeleteICPartner(ICPartnerCode: Code[20])
    var
        ICPartner: Record "IC Partner";
    begin
        ICPartner.Get(ICPartnerCode);
        ICPartner.Delete();
    end;

    local procedure GenerateExternalDocumentNo(): Code[35]
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Init();
        exit(CopyStr(LibraryUtility.GenerateRandomText(
              MaxStrLen(SalesHeader."External Document No.")), 1, MaxStrLen(SalesHeader."External Document No.")));
    end;

    local procedure ImportICTransactionFromFile(FileName: Text)
    var
        ICInboxTransaction: Record "IC Inbox Transaction";
        ICInboxImport: Codeunit "IC Inbox Import";
    begin
        ICInboxImport.SetFileName(FileName);
        ICInboxImport.Run(ICInboxTransaction);
    end;

    local procedure MockTrackingForItem(SourceType: Integer; DocumentNo: Code[20])
    var
        TrackingSpecification: Record "Tracking Specification";
        ItemEntryRelation: Record "Item Entry Relation";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.FindLast();

        ItemEntryRelation.Init();
        ItemEntryRelation."Item Entry No." := ItemLedgerEntry."Entry No." + 10000;
        ItemEntryRelation."Source Type" := SourceType;
        ItemEntryRelation."Source ID" := DocumentNo;
        ItemEntryRelation."Source Ref. No." := 10000;
        ItemEntryRelation.Insert();

        TrackingSpecification.Init();
        TrackingSpecification."Entry No." := ItemEntryRelation."Item Entry No.";
        TrackingSpecification."Quantity (Base)" := LibraryRandom.RandDec(100, 2);
        TrackingSpecification.Insert();
    end;

    local procedure SendPurchaseDocumentReceiveSalesDocument(var PurchaseHeader: Record "Purchase Header"; var SalesHeader: Record "Sales Header"; ICPartnerCode: Code[20]; CustomerNo: Code[20])
    var
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICInboxTransaction: Record "IC Inbox Transaction";
        ICInboxSalesHeader: Record "IC Inbox Sales Header";
    begin
        SendICPurchaseDocument(
          PurchaseHeader, ICPartnerCode, ICOutboxTransaction, ICInboxTransaction, ICInboxSalesHeader);
        ReceiveICSalesDocument(
          SalesHeader, PurchaseHeader, ICOutboxTransaction, ICInboxTransaction, ICInboxSalesHeader, CustomerNo);
    end;

    local procedure SendICSalesInvoice(var ICOutboxTransaction: Record "IC Outbox Transaction"; var ICInboxTransaction: Record "IC Inbox Transaction"; var ICInboxPurchaseHeader: Record "IC Inbox Purchase Header"; SalesInvoiceNo: Code[20]; ICPartnerCode: Code[20])
    var
        ICOutboxSalesHeader: Record "IC Outbox Sales Header";
    begin
        ICOutboxTransaction."Document Type" := ICOutboxTransaction."Document Type"::Invoice;
        ICOutboxSalesHeader."Document Type" := ICOutboxSalesHeader."Document Type"::Invoice;
        OutboxICSalesDocument(
          ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader, ICOutboxSalesHeader, SalesInvoiceNo, ICPartnerCode);
    end;

    local procedure SendICSalesCrMemo(var ICOutboxTransaction: Record "IC Outbox Transaction"; var ICInboxTransaction: Record "IC Inbox Transaction"; var ICInboxPurchaseHeader: Record "IC Inbox Purchase Header"; SalesCrMemoNo: Code[20]; ICPartnerCode: Code[20])
    var
        ICOutboxSalesHeader: Record "IC Outbox Sales Header";
    begin
        ICOutboxTransaction."Document Type" := ICOutboxTransaction."Document Type"::"Credit Memo";
        ICOutboxSalesHeader."Document Type" := ICOutboxSalesHeader."Document Type"::"Credit Memo";
        OutboxICSalesDocument(
          ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader, ICOutboxSalesHeader, SalesCrMemoNo, ICPartnerCode);
    end;

    local procedure SendICSalesDocument(var SalesHeader: Record "Sales Header"; ICPartnerCode: Code[20]; var ICOutboxTransaction: Record "IC Outbox Transaction"; var ICInboxTransaction: Record "IC Inbox Transaction"; var ICInboxPurchaseHeader: Record "IC Inbox Purchase Header")
    var
        ICOutboxSalesHeader: Record "IC Outbox Sales Header";
    begin
        ICInboxOutboxMgt.SendSalesDoc(SalesHeader, false);
        ICOutboxTransaction."Document Type" := ConvertDocTypeToICOutboxTransaction(SalesHeader."Document Type");
        ICOutboxSalesHeader."Document Type" := SalesHeader."Document Type";
        OutboxICSalesDocument(
          ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader, ICOutboxSalesHeader, SalesHeader."No.", ICPartnerCode);
    end;

    local procedure OutboxICSalesDocument(var ICOutboxTransaction: Record "IC Outbox Transaction"; var ICInboxTransaction: Record "IC Inbox Transaction"; var ICInboxPurchaseHeader: Record "IC Inbox Purchase Header"; var ICOutboxSalesHeader: Record "IC Outbox Sales Header"; SalesDocumentNo: Code[20]; ICPartnerCode: Code[20])
    begin
        FindICOutboxTransaction(
          ICOutboxTransaction, SalesDocumentNo, ICOutboxTransaction."Document Type",
          ICOutboxTransaction."IC Source Type"::"Sales Document");
        FindICOutboxSalesHeader(
          ICOutboxSalesHeader, ICOutboxTransaction."Transaction No.",
          SalesDocumentNo, ICOutboxSalesHeader."Document Type");
        ICInboxOutboxMgt.OutboxTransToInbox(ICOutboxTransaction, ICInboxTransaction, ICPartnerCode);
        ICInboxOutboxMgt.OutboxSalesHdrToInbox(ICInboxTransaction, ICOutboxSalesHeader, ICInboxPurchaseHeader);
    end;

    local procedure ReceiveICPurchaseInvoice(var PurchaseHeader: Record "Purchase Header"; var ICOutboxTransaction: Record "IC Outbox Transaction"; var ICInboxTransaction: Record "IC Inbox Transaction"; var ICInboxPurchaseHeader: Record "IC Inbox Purchase Header"; SalesInvoiceNo: Code[20]; VendorNo: Code[20])
    var
        ICOutboxSalesLine: Record "IC Outbox Sales Line";
    begin
        ICInboxOutboxMgt.CreatePurchDocument(ICInboxPurchaseHeader, false, WorkDate());
        ICOutboxSalesLine."Document Type" := ICOutboxSalesLine."Document Type"::Invoice;
        InboxICPurchaseDocument(
          PurchaseHeader, ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader, ICOutboxSalesLine, SalesInvoiceNo, VendorNo);
    end;

    local procedure ReceiveICPurchaseCrMemo(var PurchaseHeader: Record "Purchase Header"; var ICOutboxTransaction: Record "IC Outbox Transaction"; var ICInboxTransaction: Record "IC Inbox Transaction"; var ICInboxPurchaseHeader: Record "IC Inbox Purchase Header"; SalesCrMemoNo: Code[20]; VendorNo: Code[20])
    var
        ICOutboxSalesLine: Record "IC Outbox Sales Line";
    begin
        ICInboxOutboxMgt.CreatePurchDocument(ICInboxPurchaseHeader, false, WorkDate());
        ICOutboxSalesLine."Document Type" := ICOutboxSalesLine."Document Type"::"Credit Memo";
        InboxICPurchaseDocument(
          PurchaseHeader, ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader, ICOutboxSalesLine, SalesCrMemoNo, VendorNo);
    end;

    local procedure ReceiveICSalesInvoice(var SalesHeader: Record "Sales Header"; var ICOutboxTransaction: Record "IC Outbox Transaction"; var ICInboxTransaction: Record "IC Inbox Transaction"; var ICInboxSalesHeader: Record "IC Inbox Sales Header"; PurchInvoiceNo: Code[20]; CustomerNo: Code[20])
    var
        ICOutboxPurchaseLine: Record "IC Outbox Purchase Line";
    begin
        ICInboxOutboxMgt.CreateSalesDocument(ICInboxSalesHeader, false, WorkDate());
        ICOutboxPurchaseLine."Document Type" := ICOutboxPurchaseLine."Document Type"::Invoice;
        InboxICSalesDocument(
          SalesHeader, ICOutboxTransaction, ICInboxTransaction, ICInboxSalesHeader, ICOutboxPurchaseLine, PurchInvoiceNo, CustomerNo);
    end;

    local procedure ReceiveICPurchaseDocument(var PurchaseHeader: Record "Purchase Header"; var SalesHeader: Record "Sales Header"; var ICOutboxTransaction: Record "IC Outbox Transaction"; var ICInboxTransaction: Record "IC Inbox Transaction"; var ICInboxPurchaseHeader: Record "IC Inbox Purchase Header"; VendorNo: Code[20])
    var
        ICOutboxSalesLine: Record "IC Outbox Sales Line";
    begin
        ICInboxOutboxMgt.CreatePurchDocument(ICInboxPurchaseHeader, false, WorkDate());
        ICOutboxSalesLine."Document Type" := ConvertDocTypeToICOutboxSalesLine(SalesHeader."Document Type");
        InboxICPurchaseDocument(
          PurchaseHeader, ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader, ICOutboxSalesLine, SalesHeader."No.", VendorNo);
    end;

    local procedure InboxICPurchaseDocument(var PurchaseHeader: Record "Purchase Header"; var ICOutboxTransaction: Record "IC Outbox Transaction"; var ICInboxTransaction: Record "IC Inbox Transaction"; var ICInboxPurchaseHeader: Record "IC Inbox Purchase Header"; var ICOutboxSalesLine: Record "IC Outbox Sales Line"; SalesDocumentNo: Code[20]; VendorNo: Code[20])
    var
        ICInboxPurchaseLine: Record "IC Inbox Purchase Line";
    begin
        FindPurchaseDocument(PurchaseHeader, ICInboxPurchaseHeader."Document Type", VendorNo);
        FindICOutboxSalesLine(
          ICOutboxSalesLine, ICOutboxTransaction."Transaction No.",
          SalesDocumentNo, ICOutboxSalesLine."Document Type");

        ICOutboxSalesLine.SetRecFilter();
        ICOutboxSalesLine.SetRange("Line No.");
        ICOutboxSalesLine.FindSet();
        repeat
            ICInboxOutboxMgt.OutboxSalesLineToInbox(ICInboxTransaction, ICOutboxSalesLine, ICInboxPurchaseLine);
            ICInboxOutboxMgt.CreatePurchLines(PurchaseHeader, ICInboxPurchaseLine);
        until ICOutboxSalesLine.Next() = 0;
    end;

    local procedure InboxICSalesDocument(var SalesHeader: Record "Sales Header"; var ICOutboxTransaction: Record "IC Outbox Transaction"; var ICInboxTransaction: Record "IC Inbox Transaction"; var ICInboxSalesHeader: Record "IC Inbox Sales Header"; var ICOutboxPurchaseLine: Record "IC Outbox Purchase Line"; PurchDocumentNo: Code[20]; CustomerNo: Code[20])
    var
        ICInboxSalesLine: Record "IC Inbox Sales Line";
    begin
        FindSalesDocument(SalesHeader, ICInboxSalesHeader."Document Type", CustomerNo);
        FindICOutboxPurchaseLine(
          ICOutboxPurchaseLine, ICOutboxTransaction."Transaction No.",
          PurchDocumentNo, ICOutboxPurchaseLine."Document Type");

        ICOutboxPurchaseLine.SetRecFilter();
        ICOutboxPurchaseLine.SetRange("Line No.");
        ICOutboxPurchaseLine.FindSet();
        repeat
            ICInboxOutboxMgt.OutboxPurchLineToInbox(ICInboxTransaction, ICOutboxPurchaseLine, ICInboxSalesLine);
            ICInboxOutboxMgt.CreateSalesLines(SalesHeader, ICInboxSalesLine);
        until ICOutboxPurchaseLine.Next() = 0;
    end;

    local procedure PostAndVerifyICGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; SignFactor: Integer)
    var
        ICOutboxJnlLine: Record "IC Outbox Jnl. Line";
        ICAccountNo: Code[20];
    begin
        // Exercise: Post IC Journal Line.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify G/L Account and IC Partner GL Account Entries in IC Outbox Journal Line.
        VerifyICOutboxJournalLine(
          GenJournalLine."IC Partner Code", ICOutboxJnlLine."Account Type"::"IC Partner", GenJournalLine."IC Partner Code",
          GenJournalLine."Document No.", SignFactor * GenJournalLine.Amount);
        ICAccountNo := GenJournalLine."IC Account No.";
        VerifyICOutboxJournalLine(
          GenJournalLine."IC Partner Code", ICOutboxJnlLine."Account Type"::"G/L Account", ICAccountNo,
          GenJournalLine."Document No.", SignFactor * -GenJournalLine.Amount);

        // Tear Down: Delete newly created batch.
        DeleteGeneralJournalBatch(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");
    end;

    local procedure SendSalesDocumentGetICPurchaseHeader(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; var ICOutboxTransaction: Record "IC Outbox Transaction"; var ICInboxTransaction: Record "IC Inbox Transaction"; ICPartnerCodeVendor: Code[20]; var ICInboxPurchaseHeader: Record "IC Inbox Purchase Header")
    begin
        SendICSalesDocument(SalesHeader, ICPartnerCodeVendor, ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader);

        ICInboxPurchaseHeader.Validate("Document Type", ConvertSalesDocTypeToICInboxPurchHeader(DocumentType));
        ICInboxPurchaseHeader.Modify(true);
    end;

    local procedure SendICPurchaseDocument(var PurchaseHeader: Record "Purchase Header"; ICPartnerCode: Code[20]; var ICOutboxTransaction: Record "IC Outbox Transaction"; var ICInboxTransaction: Record "IC Inbox Transaction"; var ICInboxSalesHeader: Record "IC Inbox Sales Header")
    var
        ICOutboxPurchaseHeader: Record "IC Outbox Purchase Header";
    begin
        ICInboxOutboxMgt.SendPurchDoc(PurchaseHeader, false);
        FindICOutboxTransaction(
          ICOutboxTransaction, PurchaseHeader."No.", ConvertDocTypeToICOutboxTransaction(PurchaseHeader."Document Type"),
          ICOutboxTransaction."IC Source Type"::"Purchase Document");
        FindICOutboxPurchaseHeader(
          ICOutboxPurchaseHeader, ICOutboxTransaction."Transaction No.",
          PurchaseHeader."No.", ConvertPurchDocTypeToICOutboxPurchHeader(PurchaseHeader."Document Type"));
        ICInboxOutboxMgt.OutboxTransToInbox(ICOutboxTransaction, ICInboxTransaction, ICPartnerCode);
        ICInboxOutboxMgt.OutboxPurchHdrToInbox(ICInboxTransaction, ICOutboxPurchaseHeader, ICInboxSalesHeader);
    end;

    local procedure SendICTransaction(DocumentNoFilter: Text) FileName: Text
    var
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICPartner: Record "IC Partner";
        FileManagement: Codeunit "File Management";
        FileNameLbl: Label '%1\%2_1_1.xml', Locked = true;
    begin
        ICOutboxTransaction.SetFilter("Document No.", DocumentNoFilter);
        ICOutboxTransaction.FindFirst();
        ICPartner.Get(ICOutboxTransaction."IC Partner Code");
        ICOutboxTransaction.ModifyAll("Line Action", ICOutboxTransaction."Line Action"::"Send to IC Partner");

        FileName := StrSubstNo(FileNameLbl, ICPartner."Inbox Details", ICPartner.Code);
        if FileManagement.ServerFileExists(FileName) then
            FileManagement.DeleteServerFile(FileName);

        CODEUNIT.Run(CODEUNIT::"IC Outbox Export", ICOutboxTransaction);
    end;

    local procedure SetCompanyICPartner(ICPartnerCode: Code[20])
    var
        ICSetup: Record "IC Setup";
    begin
        ICSetup.Get();
        ICSetup."IC Partner Code" := ICPartnerCode;
        ICSetup.Modify(true);
    end;

    local procedure ReceiveICSalesDocument(var SalesHeader: Record "Sales Header"; var PurchaseHeader: Record "Purchase Header"; var ICOutboxTransaction: Record "IC Outbox Transaction"; var ICInboxTransaction: Record "IC Inbox Transaction"; var ICInboxSalesHeader: Record "IC Inbox Sales Header"; CustomerNo: Code[20])
    var
        ICOutboxPurchaseLine: Record "IC Outbox Purchase Line";
        ICInboxSalesLine: Record "IC Inbox Sales Line";
    begin
        ICInboxOutboxMgt.CreateSalesDocument(ICInboxSalesHeader, false, WorkDate());
        FindSalesDocument(SalesHeader, PurchaseHeader."Document Type", CustomerNo);
        FindICOutboxPurchaseLine(
          ICOutboxPurchaseLine, ICOutboxTransaction."Transaction No.",
          PurchaseHeader."No.", ConvertPurchDocTypeToICOutboxPurchLine(PurchaseHeader."Document Type"));
        ICInboxOutboxMgt.OutboxPurchLineToInbox(ICInboxTransaction, ICOutboxPurchaseLine, ICInboxSalesLine);
        ICInboxOutboxMgt.CreateSalesLines(SalesHeader, ICInboxSalesLine);
    end;

    local procedure DeleteGeneralJournalBatch(JournalTemplateName: Code[10]; Description: Text[50])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        GenJournalBatch.SetRange("Journal Template Name", JournalTemplateName);
        GenJournalBatch.SetRange(Description, Description);
        GenJournalBatch.FindFirst();
        GenJournalBatch.Delete(true);
    end;

    local procedure FindICOutboxJournalLine(var ICOutboxJnlLine: Record "IC Outbox Jnl. Line"; ICPartnerCode: Code[20]; AccountType: Option; AccountNo: Code[20]; DocumentNo: Code[20])
    begin
        ICOutboxJnlLine.SetRange("Account Type", AccountType);
        ICOutboxJnlLine.SetRange("IC Partner Code", ICPartnerCode);
        ICOutboxJnlLine.SetRange("Account No.", AccountNo);
        ICOutboxJnlLine.SetRange("Document No.", DocumentNo);
        ICOutboxJnlLine.FindFirst();
    end;

    local procedure FindICOutboxTransaction(var ICOutboxTransaction: Record "IC Outbox Transaction"; DocumentNo: Code[20]; DocumentType: Enum "IC Transaction Document Type"; SourceType: Enum "IC Transaction Source Type")
    begin
        ICOutboxTransaction.SetRange("Document No.", DocumentNo);
        ICOutboxTransaction.SetRange("Document Type", DocumentType);
        ICOutboxTransaction.SetRange("IC Source Type", SourceType);
        ICOutboxTransaction.FindFirst();
    end;

    local procedure FindSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20])
    begin
        SalesHeader.SetRange("Document Type", DocumentType);
        SalesHeader.SetRange("IC Direction", SalesHeader."IC Direction"::Incoming);
        SalesHeader.SetRange("Sell-to Customer No.", CustomerNo);
        SalesHeader.FindFirst();
    end;

    local procedure FindPurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20])
    begin
        PurchaseHeader.SetRange("Document Type", DocumentType);
        PurchaseHeader.SetRange("IC Direction", PurchaseHeader."IC Direction"::Incoming);
        PurchaseHeader.SetRange("Buy-from Vendor No.", VendorNo);
        PurchaseHeader.FindFirst();
    end;

    local procedure FindICOutboxSalesHeader(var ICOutboxSalesHeader: Record "IC Outbox Sales Header"; TransactionNo: Integer; DocumentNo: Code[20]; DocumentType: Enum "IC Sales Document Type")
    begin
        ICOutboxSalesHeader.SetRange("IC Transaction No.", TransactionNo);
        ICOutboxSalesHeader.SetRange("No.", DocumentNo);
        ICOutboxSalesHeader.SetRange("Document Type", DocumentType);
        ICOutboxSalesHeader.FindFirst();
    end;

    local procedure FindICOutboxSalesLine(var ICOutboxSalesLine: Record "IC Outbox Sales Line"; TransactionNo: Integer; DocumentNo: Code[20]; DocumentType: Enum "IC Outbox Sales Document Type")
    begin
        ICOutboxSalesLine.SetRange("IC Transaction No.", TransactionNo);
        ICOutboxSalesLine.SetRange("Document No.", DocumentNo);
        ICOutboxSalesLine.SetRange("Document Type", DocumentType);
        ICOutboxSalesLine.FindFirst();
    end;

    local procedure FindSalesShipmentByCustNo(CustNo: Code[20]): Code[20]
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        SalesShipmentHeader.SetRange("Sell-to Customer No.", CustNo);
        SalesShipmentHeader.FindFirst();
        exit(SalesShipmentHeader."No.");
    end;

    local procedure FindICOutboxPurchaseHeader(var ICOutboxPurchaseHeader: Record "IC Outbox Purchase Header"; TransactionNo: Integer; DocumentNo: Code[20]; DocumentType: Enum "IC Purchase Document Type")
    begin
        ICOutboxPurchaseHeader.SetRange("IC Transaction No.", TransactionNo);
        ICOutboxPurchaseHeader.SetRange("No.", DocumentNo);
        ICOutboxPurchaseHeader.SetRange("Document Type", DocumentType);
        ICOutboxPurchaseHeader.FindFirst();
    end;

    local procedure FindICOutboxPurchaseLine(var ICOutboxPurchaseLine: Record "IC Outbox Purchase Line"; TransactionNo: Integer; DocumentNo: Code[20]; DocumentType: Enum "IC Outbox Purchase Document Type")
    begin
        ICOutboxPurchaseLine.SetRange("IC Transaction No.", TransactionNo);
        ICOutboxPurchaseLine.SetRange("Document No.", DocumentNo);
        ICOutboxPurchaseLine.SetRange("Document Type", DocumentType);
        ICOutboxPurchaseLine.FindFirst();
    end;

    local procedure FindPurchReceiptByVendorNo(VendorNo: Code[20]): Code[20]
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
    begin
        PurchRcptHeader.SetRange("Buy-from Vendor No.", VendorNo);
        PurchRcptHeader.FindFirst();
        exit(PurchRcptHeader."No.");
    end;

    local procedure FindAndUpdateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.FindFirst();
        SalesLine.Validate("Qty. to Invoice", SalesLine.Quantity / 2);  // Update partial Quantity.
        SalesLine.Modify(true);
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
    end;

    local procedure FindPurchLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetFilter(Type, '<>%1', PurchaseLine.Type::" ");
        PurchaseLine.FindFirst();
    end;

    local procedure FilterGLEntry(var GLEntry: Record "G/L Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; AccountNo: Code[20])
    begin
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", AccountNo);
    end;

    local procedure MockSendReceivePurchDocument(var PurchaseHeaderToSend: Record "Purchase Header"; var SalesHeader: Record "Sales Header"; ICPartnerCodeVendor: Code[20]; LocationCode: Code[10])
    var
        CustomerNo: Code[20];
    begin
        CustomerNo := CreateICCustomer(ICPartnerCodeVendor);
        SendPurchaseDocumentReceiveSalesDocument(PurchaseHeaderToSend, SalesHeader, ICPartnerCodeVendor, CustomerNo);
        UpdateSalesDocumentLocation(SalesHeader, LocationCode);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        case SalesHeader."Document Type" of
            SalesHeader."Document Type"::Order:
                CreateSalesInvoiceWithGetShipmentLines(SalesHeader, CustomerNo);
            SalesHeader."Document Type"::"Return Order":
                CreateSalesCrMemoWithGetRetReceiptLines(SalesHeader, CustomerNo);
        end;
    end;

    local procedure ICPartnerForCustomerAndVendorError(ICPartnerCode: Code[20])
    var
        CustomerNo: Code[20];
    begin
        // Setup: Create Customer with IC Partner Code.
        CustomerNo := CreateICCustomer(ICPartnerCode);

        // Exercise: Create another Customer and assign same IC Partner Code to it.
        asserterror CreateICCustomer(ICPartnerCode);

        // Verify: Verify error message for Customer.
        Assert.ExpectedError(
          StrSubstNo(SameICPartnerErr, ICPartnerCode, CustomerNo));
    end;

    local procedure PostReceivedPurchInvoice_WideExternalDocNo(var ICInboxTransaction: Record "IC Inbox Transaction")
    var
        ICInboxPurchaseHeader: Record "IC Inbox Purchase Header";
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICPartnerCodeVendor: Code[20];
        VendorNo: Code[20];
        CustomerNo: Code[20];
        SalesInvoiceNo: Code[20];
        PurchInvoiceNo: Code[20];
    begin
        // Created Partner, Vendor, Customer
        CreatePartnerCustomerVendor(ICPartnerCodeVendor, VendorNo, CustomerNo);

        // Created Sales Invoice
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo, CreateItem());

        // Sales Invoice with 35 char length of "External Document No."
        UpdateSalesDocumentExternalDocumentNo(SalesHeader, GenerateExternalDocumentNo());

        // Post, send Sales Invoice.
        SalesInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SendICSalesInvoice(ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader, SalesInvoiceNo, ICPartnerCodeVendor);

        // Receive Purchase Invoice
        ReceiveICPurchaseInvoice(
          PurchaseHeader, ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader, SalesInvoiceNo, VendorNo);

        // Post Purchase Invoice
        PurchInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        PurchInvHeader.Get(PurchInvoiceNo);

        // Checking Your Reference of Purch. Inv. Header
        PurchaseHeader.TestField("Your Reference", SalesHeader."External Document No.");
    end;

    local procedure RenameICPartner(ICPartnerCode: Code[20]): Code[20]
    var
        ICPartner: Record "IC Partner";
    begin
        ICPartner.Get(ICPartnerCode);
        ICPartner.Rename(ICPartnerCode + Format(LibraryRandom.RandInt(10)));  // Renaming IC Partner, value is not important.
        exit(ICPartner.Code);
    end;

    local procedure SetupLocationMandatory(LocationMandatory: Boolean) OldLocationMandatory: Boolean
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        OldLocationMandatory := InventorySetup."Location Mandatory";
        InventorySetup.Validate("Location Mandatory", LocationMandatory);
        InventorySetup.Modify(true);
    end;

    local procedure SelectGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        // Select General Journal Batch and clear General Journal Lines to make sure that no line exist before creating General Journal Lines.
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    local procedure ModifySalesHeaderShipToCountryRegionAndCounty(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader."Ship-to Country/Region Code" := LibraryUtility.GenerateGUID();
        SalesHeader."Ship-to County" := PadStr(
            LibraryUtility.GenerateRandomText(MaxStrLen(SalesHeader."Ship-to County")),
            MaxStrLen(SalesHeader."Ship-to County"));
        SalesHeader.Modify(true);
    end;

    local procedure ModifyPurchHeaderShipToCountryRegionAndCounty(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader."Ship-to Country/Region Code" := LibraryUtility.GenerateGUID();
        PurchaseHeader."Ship-to County" := PadStr(
            LibraryUtility.GenerateRandomText(MaxStrLen(PurchaseHeader."Ship-to County")),
            MaxStrLen(PurchaseHeader."Ship-to County"));
        PurchaseHeader.Modify(true);
    end;

    local procedure UpdatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; PayToVendorNo: Code[20])
    begin
        PurchaseHeader.Validate("Pay-to Vendor No.", PayToVendorNo);
        PurchaseHeader.Modify(true);
    end;

    local procedure UpdatePurchaseDocumentLocation(var PurchaseHeader: Record "Purchase Header"; LocationCode: Code[10])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseHeader.Validate("Location Code", LocationCode);
        PurchaseHeader.Modify(true);

        FindPurchLine(PurchaseLine, PurchaseHeader);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateSalesDocument(var SalesHeader: Record "Sales Header"; BillToCustomerNo: Code[20])
    begin
        SalesHeader.Validate("Bill-to Customer No.", BillToCustomerNo);
        SalesHeader.Validate("Send IC Document", true);
        SalesHeader.Modify(true);
    end;

    local procedure UpdateSalesDocumentLocation(var SalesHeader: Record "Sales Header"; LocationCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        SalesHeader.Validate("Location Code", LocationCode);
        SalesHeader.Modify(true);

        FindSalesLine(SalesLine, SalesHeader);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
    end;

    local procedure UpdateSalesDocumentExternalDocumentNo(var SalesHeader: Record "Sales Header"; ReferencedDocumentNo: Code[35])
    begin
        SalesHeader.Validate("External Document No.", ReferencedDocumentNo);
        SalesHeader.Modify(true);
    end;

    local procedure UpdatePurchaseInvoice(var PurchaseHeaderToInvoice: Record "Purchase Header"; var PurchaseHeaderToSend: Record "Purchase Header")
    var
        PurchaseLineToSend: Record "Purchase Line";
        PurchaseLineToInvoice: Record "Purchase Line";
    begin
        FindPurchLine(PurchaseLineToSend, PurchaseHeaderToSend);
        FindPurchLine(PurchaseLineToInvoice, PurchaseHeaderToInvoice);
        PurchaseLineToInvoice.Validate("Quantity Received", PurchaseLineToSend."Quantity Received");
        PurchaseLineToInvoice.Modify(true);

        PurchaseHeaderToInvoice.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeaderToInvoice.Modify(true);
    end;

    local procedure UpdatePurchaseLineICPartnerInfo(var PurchaseLine: Record "Purchase Line"; ICPartnerCode: Code[20]; ICPartnerRefType: Enum "IC Partner Reference Type"; ICGLAccountNo: Code[20])
    begin
        PurchaseLine.Validate("IC Partner Code", ICPartnerCode);
        PurchaseLine.Validate("IC Partner Ref. Type", ICPartnerRefType);
        PurchaseLine.Validate("IC Partner Reference", ICGLAccountNo);
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateSalesLineICPartnerInfo(var SalesLine: Record "Sales Line"; ICPartnerCode: Code[20]; ICPartnerRefType: Enum "IC Partner Reference Type"; ICGLAccountNo: Code[20])
    begin
        SalesLine.Validate("IC Partner Code", ICPartnerCode);
        SalesLine.Validate("IC Partner Ref. Type", ICPartnerRefType);
        SalesLine.Validate("IC Partner Reference", ICGLAccountNo);
        SalesLine.Modify(true);
    end;

    local procedure UpdateCommonItemNo(ItemNo: Code[20]; NewCommonItemNo: Code[20])
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        Item.Validate("Common Item No.", NewCommonItemNo);
        Item.Modify();
    end;

    local procedure UpdateICPartnerWithOutboundType(ICPartnerCode: Code[20]; OutboundType: Enum "IC Outb. Sales Item No. Type")
    var
        ICPartner: Record "IC Partner";
    begin
        ICPartner.Get(ICPartnerCode);
        ICPartner.Validate("Outbound Purch. Item No. Type", OutboundType);
        ICPartner.Validate("Outbound Sales Item No. Type", OutboundType);
        ICPartner.Modify(true);
    end;

    local procedure UpdateLCYCodeInGLSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."LCY Code" := LibraryUtility.GenerateGUID();
        GeneralLedgerSetup.Modify();
    end;

    local procedure UpdateCustomerWithDefaultGlobalDimensionSet(CustomerNo: Code[20])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        GeneralLedgerSetup.Get();
        LibraryDimension.CreateDimensionValue(DimensionValue, GeneralLedgerSetup."Global Dimension 1 Code");
        LibraryDimension.CreateDefaultDimensionCustomer(
          DefaultDimension, CustomerNo, DimensionValue."Dimension Code", DimensionValue.Code);
        LibraryDimension.CreateDimensionValue(DimensionValue, GeneralLedgerSetup."Global Dimension 2 Code");
        LibraryDimension.CreateDefaultDimensionCustomer(
          DefaultDimension, CustomerNo, DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    local procedure UpdateVendorWithDefaultGlobalDimensionSet(CustomerNo: Code[20])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        GeneralLedgerSetup.Get();
        LibraryDimension.CreateDimensionValue(DimensionValue, GeneralLedgerSetup."Global Dimension 1 Code");
        LibraryDimension.CreateDefaultDimensionVendor(
          DefaultDimension, CustomerNo, DimensionValue."Dimension Code", DimensionValue.Code);
        LibraryDimension.CreateDimensionValue(DimensionValue, GeneralLedgerSetup."Global Dimension 2 Code");
        LibraryDimension.CreateDefaultDimensionVendor(
          DefaultDimension, CustomerNo, DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    local procedure AddICInfoToSalesLine(var SalesLine: Record "Sales Line"): Code[20]
    var
        ICGLAccount: Record "IC G/L Account";
        ICPartnerNo: Code[20];
    begin
        LibraryERM.CreateICGLAccount(ICGLAccount);
        ICPartnerNo := CreateICPartner();
        UpdateSalesLineICPartnerInfo(
          SalesLine, ICPartnerNo, SalesLine."IC Partner Ref. Type"::"G/L Account", ICGLAccount."No.");
        exit(ICPartnerNo);
    end;

    local procedure AddICInfoToPurchaseLine(var PurchaseLine: Record "Purchase Line"): Code[20]
    var
        ICGLAccount: Record "IC G/L Account";
        ICPartnerNo: Code[20];
    begin
        LibraryERM.CreateICGLAccount(ICGLAccount);
        ICPartnerNo := CreateICPartner();
        UpdatePurchaseLineICPartnerInfo(
          PurchaseLine, ICPartnerNo, PurchaseLine."IC Partner Ref. Type"::"G/L Account", ICGLAccount."No.");
        exit(ICPartnerNo);
    end;

    local procedure DecreaseQtyInSalesLine(var SalesLine: Record "Sales Line"; DocType: Enum "Sales Document Type"; DocNo: Code[20])
    begin
        SalesLine.SetRange("Document Type", DocType);
        SalesLine.SetRange("Document No.", DocNo);
        SalesLine.FindFirst();
        SalesLine.Validate(Quantity, Round(SalesLine.Quantity / 3, 1));
        SalesLine.Modify(true);
    end;

    local procedure ConvertDocTypeToICOutboxTransaction(SourceDocumentType: Enum "Sales Document Type"): Enum "IC Transaction Document Type"
    var
        SalesHeader: Record "Sales Header";
        ICOutboxTransaction: Record "IC Outbox Transaction";
    begin
        case SourceDocumentType of
            SalesHeader."Document Type"::Invoice:
                exit(ICOutboxTransaction."Document Type"::Invoice);
            SalesHeader."Document Type"::Order:
                exit(ICOutboxTransaction."Document Type"::Order);
            SalesHeader."Document Type"::"Credit Memo":
                exit(ICOutboxTransaction."Document Type"::"Credit Memo");
            SalesHeader."Document Type"::"Return Order":
                exit(ICOutboxTransaction."Document Type"::"Return Order");
        end;
    end;

    local procedure ConvertDocTypeToICOutboxSalesLine(SourceDocumentType: Enum "Sales Document Type"): Enum "IC Outbox Sales Document Type"
    var
        SalesHeader: Record "Sales Header";
    begin
        case SourceDocumentType of
            SalesHeader."Document Type"::Invoice:
                exit("IC Outbox Sales Document Type"::Invoice);
            SalesHeader."Document Type"::Order:
                exit("IC Outbox Sales Document Type"::Order);
            SalesHeader."Document Type"::"Credit Memo":
                exit("IC Outbox Sales Document Type"::"Credit Memo");
            SalesHeader."Document Type"::"Return Order":
                exit("IC Outbox Sales Document Type"::"Return Order");
        end;
    end;

    local procedure ConvertSalesDocTypeToICInboxPurchHeader(SourceDocumentType: Enum "Sales Document Type"): Enum "IC Purchase Document Type"
    var
        SalesHeader: Record "Sales Header";
        ICInboxPurchaseHeader: Record "IC Inbox Purchase Header";
    begin
        case SourceDocumentType of
            SalesHeader."Document Type"::Order:
                exit(ICInboxPurchaseHeader."Document Type"::Invoice);
            SalesHeader."Document Type"::"Return Order":
                exit(ICInboxPurchaseHeader."Document Type"::"Credit Memo");
        end;
    end;

    local procedure ConvertPurchDocTypeToICOutboxPurchHeader(SourceDocumentType: Enum "Purchase Document Type"): Enum "IC Purchase Document Type"
    var
        PurchaseHeader: Record "Purchase Header";
        ICOutboxPurchaseHeader: Record "IC Outbox Purchase Header";
    begin
        case SourceDocumentType of
            PurchaseHeader."Document Type"::Invoice:
                exit(ICOutboxPurchaseHeader."Document Type"::Invoice);
            PurchaseHeader."Document Type"::Order:
                exit(ICOutboxPurchaseHeader."Document Type"::Order);
            PurchaseHeader."Document Type"::"Credit Memo":
                exit(ICOutboxPurchaseHeader."Document Type"::"Credit Memo");
            PurchaseHeader."Document Type"::"Return Order":
                exit(ICOutboxPurchaseHeader."Document Type"::"Return Order");
        end;
    end;

    local procedure ConvertPurchDocTypeToICOutboxPurchLine(SourceDocumentType: Enum "Purchase Document Type"): Enum "IC Outbox Purchase Document Type"
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        case SourceDocumentType of
            PurchaseHeader."Document Type"::Invoice:
                exit("IC Outbox Purchase Document Type"::Invoice);
            PurchaseHeader."Document Type"::Order:
                exit("IC Outbox Purchase Document Type"::Order);
            PurchaseHeader."Document Type"::"Credit Memo":
                exit("IC Outbox Purchase Document Type"::"Credit Memo");
            PurchaseHeader."Document Type"::"Return Order":
                exit("IC Outbox Purchase Document Type"::"Return Order");
        end;
    end;

    local procedure HandleICInboxTransaction(var HandledICInboxTrans: Record "Handled IC Inbox Trans."; var ICInboxTransaction: Record "IC Inbox Transaction")
    begin
        ICInboxOutboxMgt.CreateHandledInbox(ICInboxTransaction);

        HandledICInboxTrans.Get(
          ICInboxTransaction."Transaction No.", ICInboxTransaction."IC Partner Code", ICInboxTransaction."Transaction Source",
          ICInboxTransaction."Document Type");

        ICInboxTransaction.Delete();
    end;

    local procedure VerifyICOutboxJournalLine(ICPartnerCode: Code[20]; AccountType: Option; AccountNo: Code[20]; DocumentNo: Code[20]; Amount: Decimal)
    var
        ICOutboxJnlLine: Record "IC Outbox Jnl. Line";
    begin
        FindICOutboxJournalLine(ICOutboxJnlLine, ICPartnerCode, AccountType, AccountNo, DocumentNo);
        Assert.AreEqual(
          AccountNo, ICOutboxJnlLine."Account No.",
          StrSubstNo(
            ValidationErr, ICOutboxJnlLine.FieldCaption("Account No."), ICOutboxJnlLine."Account No.", ICOutboxJnlLine.TableCaption()));
        Assert.AreNearlyEqual(
          Amount, ICOutboxJnlLine.Amount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(ValidationErr, ICOutboxJnlLine.FieldCaption(Amount), ICOutboxJnlLine.Amount, ICOutboxJnlLine.TableCaption()));
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; ICPartnerCode: Code[20]; AccountNo: Code[20]; Amount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLEntry: Record "G/L Entry";
    begin
        GeneralLedgerSetup.Get();
        FilterGLEntry(GLEntry, GLEntry."Document Type"::Invoice, DocumentNo, AccountNo);
        GLEntry.FindFirst();
        GLEntry.TestField("IC Partner Code", ICPartnerCode);
        Assert.AreNearlyEqual(
          Amount, GLEntry.Amount, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(ValidationErr, GLEntry.FieldCaption(Amount), Amount, GLEntry.TableCaption()));
    end;

    local procedure VerifyDimSetIDInICGLEntry(DocumentNo: Code[20]; AccountNo: Code[20]; ICPartnerCode: Code[20]; DimSetID: Integer; ShortcutDimension1Code: Code[20]; ShortcutDimension2Code: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Bal. Account Type", GLEntry."Bal. Account Type"::"IC Partner");
        GLEntry.SetRange("Bal. Account No.", ICPartnerCode);
        FilterGLEntry(GLEntry, GLEntry."Document Type"::Invoice, DocumentNo, AccountNo);
        GLEntry.FindFirst();
        GLEntry.TestField("Dimension Set ID", DimSetID);
        GLEntry.TestField("Global Dimension 1 Code", ShortcutDimension1Code);
        GLEntry.TestField("Global Dimension 2 Code", ShortcutDimension2Code);
    end;

    local procedure VerifyQuantityOnSalesLineAndAssemblyHeader(SalesHeaderNo: Code[20]; Qty: Decimal)
    var
        SalesLine: Record "Sales Line";
        AssemblyHeader: Record "Assembly Header";
    begin
        SalesLine.SetRange("Document No.", SalesHeaderNo);
        SalesLine.FindFirst();
        SalesLine.CalcFields("Reserved Quantity");
        SalesLine.TestField("Reserved Quantity", Qty);

        AssemblyHeader.SetRange("Item No.", SalesLine."No.");
        AssemblyHeader.FindFirst();
        AssemblyHeader.TestField(Quantity, Qty);
    end;

    local procedure VerifyGLEntryWithBalAccTypeICPartner(DocumentNo: Code[20]; ICPartnerCode: Code[20]; AccountNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        FilterGLEntry(GLEntry, GLEntry."Document Type"::Invoice, DocumentNo, AccountNo);
        GLEntry.SetRange("Bal. Account Type", GLEntry."Bal. Account Type"::"IC Partner");
        GLEntry.SetRange("IC Partner Code", ICPartnerCode);
        Assert.IsFalse(GLEntry.IsEmpty, NoGLEntryWithICPartnerCodeErr);
    end;

    local procedure VerifySentSalesDocumentDates(SalesHeader: Record "Sales Header"; PurchaseHeader: Record "Purchase Header")
    begin
        Assert.AreEqual(
          SalesHeader."Requested Delivery Date",
          PurchaseHeader."Requested Receipt Date",
          StrSubstNo(
            DatesErr,
            PurchaseHeader.FieldCaption("Requested Receipt Date"),
            PurchaseHeader.TableName,
            SalesHeader.FieldCaption("Requested Delivery Date"),
            SalesHeader.TableName));

        Assert.AreEqual(
          SalesHeader."Promised Delivery Date",
          PurchaseHeader."Promised Receipt Date",
          StrSubstNo(
            DatesErr,
            PurchaseHeader.FieldCaption("Promised Receipt Date"),
            PurchaseHeader.TableName,
            SalesHeader.FieldCaption("Promised Delivery Date"),
            SalesHeader.TableName));
    end;

    local procedure VerifySentPurchaseDocumentDates(PurchaseHeader: Record "Purchase Header"; SalesHeader: Record "Sales Header")
    begin
        Assert.AreEqual(
          PurchaseHeader."Requested Receipt Date",
          SalesHeader."Requested Delivery Date",
          StrSubstNo(
            DatesErr,
            SalesHeader.FieldCaption("Requested Delivery Date"),
            SalesHeader.TableName,
            PurchaseHeader.FieldCaption("Requested Receipt Date"),
            PurchaseHeader.TableName
            ));

        Assert.AreEqual(
          PurchaseHeader."Promised Receipt Date",
          SalesHeader."Promised Delivery Date",
          StrSubstNo(
            DatesErr,
            SalesHeader.FieldCaption("Promised Delivery Date"),
            SalesHeader.TableName,
            PurchaseHeader.FieldCaption("Promised Receipt Date"),
            PurchaseHeader.TableName));
    end;

    local procedure VerifyPostedPurchaseInvoiceLocation(DocumentNo: Code[20]; var PurchaseHeader: Record "Purchase Header")
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        PurchInvLine.SetRange("Document No.", DocumentNo);
        PurchInvLine.SetFilter(Type, '<>%1', PurchInvLine.Type::" ");
        PurchInvLine.FindFirst();
        Assert.AreEqual(PurchInvLine."Location Code", PurchaseHeader."Location Code", 'Error location code');
    end;

    local procedure VerifyReservationEntryExists(DocumentType: Option; DocumentNo: Code[20])
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Source Subtype", DocumentType);
        ReservationEntry.SetRange("Source ID", DocumentNo);
        Assert.IsFalse(ReservationEntry.IsEmpty(), ReservationEntryNotExistErr);
    end;

    local procedure VerifyReservationEntryQty(DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20]; ExpectedQty: Decimal)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Source Subtype", DocumentType);
        ReservationEntry.SetRange("Source ID", DocumentNo);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField(Quantity, ExpectedQty);
    end;

    local procedure VerifyICOutboxSalesLine(DocumentNo: Code[20]; ICOutboxTransactionDocumentType: Enum "IC Transaction Document Type"; ICOutboxSalesLineDocumentType: Enum "IC Outbox Sales Document Type")
    var
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICOutboxSalesLine: Record "IC Outbox Sales Line";
    begin
        FindICOutboxTransaction(
          ICOutboxTransaction, DocumentNo, ICOutboxTransactionDocumentType,
          ICOutboxTransaction."IC Source Type"::"Sales Document");
        FindICOutboxSalesLine(
          ICOutboxSalesLine,
          ICOutboxTransaction."Transaction No.", DocumentNo, ICOutboxSalesLineDocumentType);
        ICOutboxSalesLine.SetRange("IC Partner Ref. Type", ICOutboxSalesLine."IC Partner Ref. Type"::"G/L Account");
        Assert.RecordCount(ICOutboxSalesLine, 1);
    end;

    local procedure VerifyPurchLineInvoicedQty(SalesHeader: Record "Sales Header"; PurchaseHeader: Record "Purchase Header")
    var
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
    begin
        FindPurchLine(PurchaseLine, PurchaseHeader);
        FindSalesLine(SalesLine, SalesHeader);
        Assert.AreEqual(
          SalesLine.Quantity, PurchaseLine."Quantity Invoiced", PurchaseLine.FieldCaption("Quantity Invoiced"));
    end;

    local procedure VerifyOutboxSalesLineCommonItem(DocumentNo: Code[20]; ExpectedCommonItemNo: Code[20])
    var
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICOutboxSalesLine: Record "IC Outbox Sales Line";
    begin
        FindICOutboxTransaction(
          ICOutboxTransaction, DocumentNo, ICOutboxTransaction."Document Type"::Order,
          ICOutboxTransaction."IC Source Type"::"Sales Document");
        FindICOutboxSalesLine(
          ICOutboxSalesLine, ICOutboxTransaction."Transaction No.",
          ICOutboxTransaction."Document No.", ICOutboxSalesLine."Document Type"::Order);
        Assert.AreEqual(ICOutboxSalesLine."IC Partner Ref. Type"::"Common Item No.", ICOutboxSalesLine."IC Partner Ref. Type", ICOutboxSalesLine.FieldCaption("IC Partner Ref. Type"));
        Assert.AreEqual(ExpectedCommonItemNo, ICOutboxSalesLine."IC Partner Reference", ICOutboxSalesLine.FieldCaption("IC Partner Reference"));
    end;

    local procedure VerifyOutboxPurchLineCommonItem(DocumentNo: Code[20]; ExpectedCommonItemNo: Code[20])
    var
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICOutboxPurchaseLine: Record "IC Outbox Purchase Line";
    begin
        FindICOutboxTransaction(
          ICOutboxTransaction, DocumentNo, ICOutboxTransaction."Document Type"::Order,
          ICOutboxTransaction."IC Source Type"::"Purchase Document");
        FindICOutboxPurchaseLine(
          ICOutboxPurchaseLine, ICOutboxTransaction."Transaction No.",
          ICOutboxTransaction."Document No.", ICOutboxPurchaseLine."Document Type"::Order);
        Assert.AreEqual(ICOutboxPurchaseLine."IC Partner Ref. Type"::"Common Item No.", ICOutboxPurchaseLine."IC Partner Ref. Type", ICOutboxPurchaseLine.FieldCaption("IC Partner Ref. Type"));
        Assert.AreEqual(ExpectedCommonItemNo, ICOutboxPurchaseLine."IC Partner Reference", ICOutboxPurchaseLine.FieldCaption("IC Partner Reference"));
    end;

    local procedure VerifyICOutboxPurchaseLineICPartnerReference(PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line")
    var
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICOutboxPurchaseLine: Record "IC Outbox Purchase Line";
    begin
        FindICOutboxTransaction(
          ICOutboxTransaction, PurchaseHeader."No.", ICOutboxTransaction."Document Type"::Order,
          ICOutboxTransaction."IC Source Type"::"Purchase Document");

        ICOutboxPurchaseLine.SetRange("IC Transaction No.", ICOutboxTransaction."Transaction No.");
        ICOutboxPurchaseLine.SetRange("IC Partner Code", ICOutboxTransaction."IC Partner Code");
        ICOutboxPurchaseLine.SetRange("Transaction Source", ICOutboxTransaction."Transaction Source");
        ICOutboxPurchaseLine.FindFirst();

        ICOutboxPurchaseLine.TestField("IC Partner Ref. Type", PurchaseLine."IC Partner Ref. Type");
        ICOutboxPurchaseLine.TestField("IC Partner Reference", PurchaseLine."IC Partner Reference");
    end;

    local procedure VerifyItemTrackingOnPurchaseLines(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        FindPurchLine(PurchaseLine, PurchaseHeader);
        repeat
            ReservationEntry.SetRange("Source Subtype", PurchaseLine."Document Type");
            ReservationEntry.SetRange("Source ID", PurchaseLine."Document No.");
            ReservationEntry.SetRange("Source Ref. No.", PurchaseLine."Line No.");
            ReservationEntry.FindFirst();
            Assert.AreEqual(PurchaseLine.Quantity, Abs(ReservationEntry.Quantity), ItemTrackingDoesNotMatchDocLineErr);
        until PurchaseLine.Next() = 0;
    end;

    local procedure VerifyItemTrackingNotAssignedOnPurchaseLine(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        FindPurchLine(PurchaseLine, PurchaseHeader);
        ReservationEntry.SetRange("Source Subtype", PurchaseLine."Document Type");
        ReservationEntry.SetRange("Source ID", PurchaseLine."Document No.");
        ReservationEntry.SetRange("Source Ref. No.", PurchaseLine."Line No.");
        Assert.RecordIsEmpty(ReservationEntry);
    end;

    local procedure VerifyDescriptionOnPurchaseLines(PurchaseHeader: Record "Purchase Header"; SalesInvoiceNo: Code[20])
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        PurchaseLine: Record "Purchase Line";
    begin
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceNo);
        if SalesInvoiceLine.IsEmpty() then
            exit;

        SalesInvoiceLine.SetLoadFields(Description);
        SalesInvoiceLine.FindSet();

        PurchaseLine.SetLoadFields(Description);
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        if PurchaseLine.FindSet() then
            repeat
                PurchaseLine.TestField(Description, SalesInvoiceLine.Description);
            until (PurchaseLine.Next() = 0) or (SalesInvoiceLine.Next() = 0);
    end;

    local procedure VerifyDescriptionOnSalesLines(SalesHeader: Record "Sales Header"; PurchaseInvoiceNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
    begin
        PurchaseLine.SetRange("Document No.", PurchaseInvoiceNo);
        if PurchaseLine.IsEmpty() then
            exit;

        PurchaseLine.SetLoadFields(Description);
        PurchaseLine.FindSet();

        SalesLine.SetLoadFields(Description);
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindSet() then
            repeat
                SalesLine.TestField(Description, PurchaseLine.Description);
            until (SalesLine.Next() = 0) or (PurchaseLine.Next() = 0);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines.New();
        ItemTrackingLines."Lot No.".SetValue(LibraryUtility.GenerateGUID());
        ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
        ItemTrackingLines.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Text: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ICOutboxSalesDocHandler(var ICOutboxSalesDoc: TestPage "IC Outbox Sales Doc.")
    begin
        ICOutboxSalesDoc.ICOutboxSalesLines."IC Partner Reference".AssertEquals(LibraryVariableStorage.DequeueText());
        ICOutboxSalesDoc.ICOutboxSalesLines.Quantity.AssertEquals(LibraryVariableStorage.DequeueDecimal());
        ICOutboxSalesDoc."IC Partner Code".AssertEquals(LibraryVariableStorage.DequeueText());
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ComfirmHandlerNo(Question: Text; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerValidateQuestion(Question: Text; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Question);
        Reply := false;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostICGeneralJournalLineWithPrivacyBlocked()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ICGLAccount: Record "IC G/L Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        ICPartnerCode: Code[20];
    begin
        // Verify IC Outbox Journal Entries after posting IC Journal Line with Account Type as IC Partner which is attached on Customer and Vendor are Privacy Blocked.

        Initialize();
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddO365Setup();
        ICPartnerCode := CreateICPartner();
        CreateAndUpdateICCustomerPrivacyBlocked(ICPartnerCode);
        CreateAndUpdateICVendorPrivacyBlocked(ICPartnerCode);
        CreateICGLAccount(ICGLAccount);

        CreateICJournalBatch(GenJournalBatch, GenJournalTemplate.Type::Intercompany);
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::"IC Partner",
          ICPartnerCode, GenJournalLine."Bal. Account Type"::"G/L Account", ICGLAccount."Map-to G/L Acc. No.", ICGLAccount."No.", 1);

        LibraryLowerPermissions.SetIntercompanyPostingsEdit();
        LibraryLowerPermissions.AddJournalsPost();
        PostAndVerifyICGeneralJournalLine(GenJournalLine, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOnICGenJournalLineWithPrivacyBlockedCustomer()
    begin
        // Verify error while create General Journal Line with Blocked All IC Customer.
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddO365Setup();
        LibraryLowerPermissions.AddJournalsPost();
        ICGenJournalLineWithBlockedCustomer(CreateAndUpdateICCustomerPrivacyBlocked(CreateICPartner()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseDocumentCreatedWithNoPostingDate()
    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        DefaultPostingDate: Enum "Default Posting Date";
    begin
        // [SCENARIO 562571] Intercompany Document is accepted when Default Posting Date is set to No Date on the Purchases & Payables setup.
        Initialize();
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddO365Setup();
        LibraryLowerPermissions.AddSalesDocsCreate();
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();
        LibraryLowerPermissions.AddPurchDocsCreate();

        // [GIVEN] Set Default Posting Date to No Date on Purchases & Payables Setup.
        UpdatePurchasePayablesSetup(DefaultPostingDate::"No Date");

        // [GIVEN] Set Default Posting Date to No Date on Sales & Receivables Setup.
        UpdateSalesReceivablesSetup(DefaultPostingDate::"No Date");

        // [WHEN] Create, Send Sales Document and Receive Purchase Document.
        CreateSendSalesDocumentReceivePurchaseDocumentWithNoPostingDate(SalesHeader, PurchaseHeader);

        // [THEN] Verify Purchase Document is created with No Posting Date.
        Assert.AreEqual(
               0D,
               PurchaseHeader."Posting Date",
               StrSubstNo(
                 PostingDateErr,
                 PurchaseHeader.FieldCaption("Posting Date"),
                 PurchaseHeader.TableName));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesDocumentCreatedWithNoPostingDate()
    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        DefaultPostingDate: Enum "Default Posting Date";
    begin
        // [SCENARIO 562571] Intercompany Document is accepted when Default Posting Date is set to No Date on the Sales & Receivables setup.
        Initialize();
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddO365Setup();
        LibraryLowerPermissions.AddSalesDocsCreate();
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();
        LibraryLowerPermissions.AddPurchDocsCreate();

        // [GIVEN] Set Default Posting Date to No Date on Purchases & Payables Setup.
        UpdatePurchasePayablesSetup(DefaultPostingDate::"No Date");

        // [GIVEN] Set Default Posting Date to No Date on Sales & Receivables Setup.
        UpdateSalesReceivablesSetup(DefaultPostingDate::"No Date");

        // [WHEN] Create, Send Purchase Document and Receive Sales Document.
        CreateSendPurchaseDocumentReceiveSalesDocumentWithNoPostingDate(PurchaseHeader, SalesHeader);

        // [THEN] Verify Sales Document is created with No Posting Date.
        Assert.AreEqual(
               0D,
               SalesHeader."Posting Date",
               StrSubstNo(
                 PostingDateErr,
                 SalesHeader.FieldCaption("Posting Date"),
                 SalesHeader.TableName));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendMultipleICPurchaseOrder()
    var
        PurchaseHeader: array[2] of Record "Purchase Header";
        PurchaseHeaderUI: Record "Purchase Header";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        Vendor: Record Vendor;
        ICPartnerCode: Code[20];
    begin
        // [SCENARIO 563725] Send intercompany purchase order with bulk selection.
        Initialize();
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddO365Setup();
        LibraryLowerPermissions.AddSalesDocsCreate();
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();
        LibraryLowerPermissions.AddPurchDocsCreate();

        // [GIVEN] Create IC Partner Code.
        ICPartnerCode := CreateICPartnerWithInbox();

        // [GIVEN] Create IC Vendor.
        Vendor.Get(CreateICVendor(ICPartnerCode));
        ICOutboxTransaction.DeleteAll();

        // [GIVEN] Create Two Purchase Order with IC Partner.
        CreatePurchaseDocument(PurchaseHeader[1], PurchaseHeader[1]."Document Type"::Order, Vendor."No.", CreateItem());
        CreatePurchaseDocument(PurchaseHeader[2], PurchaseHeader[2]."Document Type"::Order, Vendor."No.", CreateItem());

        // [WHEN] Send IC Purchase Orders.
        PurchaseHeaderUI.SetFilter("No.", '%1|%2', PurchaseHeader[1]."No.", PurchaseHeader[2]."No.");
        PurchaseHeaderUI.SendICPurchaseDoc(PurchaseHeaderUI);

        // [THEN] Verify Multiple Purchase Orders are sent.
        VerifyICOutboxTransaction(
            ICOutboxTransaction,
            ICOutboxTransaction."Document Type"::Order,
            PurchaseHeaderUI.GetFilter("No."),
            ICOutboxTransaction."IC Source Type"::"Purchase Document",
            PurchaseHeaderUI.Count,
            ICPartnerCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendMultipleICSalesOrder()
    var
        SalesHeader: array[2] of Record "Sales Header";
        SalesHeaderUI: Record "Sales Header";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        Customer: Record Customer;
        ICPartnerCode: Code[20];
    begin
        // [SCENARIO 563725] Send intercompany sales order with bulk selection.
        Initialize();
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddO365Setup();
        LibraryLowerPermissions.AddSalesDocsCreate();
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();
        LibraryLowerPermissions.AddPurchDocsCreate();

        // [GIVEN] Create IC Partner Code.
        ICPartnerCode := CreateICPartnerWithInbox();

        // [GIVEN] Create IC Customer.
        Customer.Get(CreateICCustomer(ICPartnerCode));
        ICOutboxTransaction.DeleteAll();

        // [GIVEN] Create Two Sales Order with IC Partner.
        CreateSalesDocument(SalesHeader[1], SalesHeader[1]."Document Type"::Order, Customer."No.", CreateItem());
        CreateSalesDocument(SalesHeader[2], SalesHeader[2]."Document Type"::Order, Customer."No.", CreateItem());

        // [WHEN] Send IC Sales Orders.
        SalesHeaderUI.SetFilter("No.", '%1|%2', SalesHeader[1]."No.", SalesHeader[2]."No.");
        SalesHeaderUI.SendICSalesDoc(SalesHeaderUI);

        // [THEN] Verify Multiple Sales Orders are sent.
        VerifyICOutboxTransaction(
            ICOutboxTransaction,
            ICOutboxTransaction."Document Type"::Order,
            SalesHeaderUI.GetFilter("No."),
            ICOutboxTransaction."IC Source Type"::"Sales Document",
            SalesHeaderUI.Count,
            ICPartnerCode);
    end;

    local procedure CreateAndUpdateICCustomerPrivacyBlocked(ICPartnerCode: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer.Get(CreateICCustomer(ICPartnerCode));
        Customer.Validate("Privacy Blocked", true);
        Customer.Modify(true);
        exit(Customer."No.")
    end;

    local procedure CreateAndUpdateICVendorPrivacyBlocked(ICPartnerCode: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(CreateICVendor(ICPartnerCode));
        Vendor.Validate("Privacy Blocked", true);
        Vendor.Modify(true);
        exit(Vendor."No.")
    end;

    local procedure CreateAndPostSalesInvoiceWithDiscount(CustomerNo: Code[20]; ItemNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
    begin
        LibrarySales.CreateSalesHeader(
                  SalesHeader, SalesHeader."Document Type"::Invoice,
                  CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandInt(10));
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(1000));
        SalesLine.Modify(true);
        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(SalesLine."Unit Price" / 2, SalesHeader);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure VerifyInvoiceDiscountOnPurchaseLine(ReceivedPurchaseHeader: Record "Purchase Header"; SalesInvoiceNo: Code[20]; ItemNo: Code[20])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PurchaseLine: Record "Purchase Line";
    begin
        SalesInvoiceHeader.SetAutoCalcFields(Amount, "Amount Including VAT", "Invoice Discount Amount");
        SalesInvoiceHeader.Get(SalesInvoiceNo);

        PurchaseLine := FindPurchaseLine(ReceivedPurchaseHeader, ItemNo);

        PurchaseLine.TestField(Amount, SalesInvoiceHeader.Amount);
        PurchaseLine.TestField("Amount Including VAT", SalesInvoiceHeader."Amount Including VAT");
        PurchaseLine.TestField("Inv. Discount Amount", SalesInvoiceHeader."Invoice Discount Amount");
    end;

    local procedure FindPurchaseLine(PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]) PurchaseLine: Record "Purchase Line"
    begin
        PurchaseLine.SetLoadFields(Amount, "Amount Including VAT", "Inv. Discount Amount");
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", ItemNo);
        PurchaseLine.FindFirst();
    end;

    local procedure FindItemUnitOfMeasureCode(ItemNo: Code[20]): Code[10]
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        exit(Item."Base Unit of Measure");
    end;

    local procedure UpdatePurchasePayablesSetup(DefaultPostingDate: Enum "Default Posting Date")
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Default Posting Date", DefaultPostingDate);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure UpdateSalesReceivablesSetup(DefaultPostingDate: Enum "Default Posting Date")
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Default Posting Date", DefaultPostingDate);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure CreateSendSalesDocumentReceivePurchaseDocumentWithNoPostingDate(var SalesHeader: Record "Sales Header"; var PurchaseHeader: Record "Purchase Header")
    var
        DummyICPartner: Record "IC Partner";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICInboxTransaction: Record "IC Inbox Transaction";
        ICInboxPurchaseHeader: Record "IC Inbox Purchase Header";
        ICPartnerCode: Code[20];
        VendorNo: Code[20];
    begin
        CreateSalesDocumentWithNoPostingDate(
            SalesHeader, SalesHeader."Document Type"::Order, ICPartnerCode, VendorNo, DummyICPartner."Outbound Sales Item No. Type"::"Internal No.");
        SendICSalesDocument(
            SalesHeader, ICPartnerCode, ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader);
        ReceiveICPurchaseDocumentWithNoPostingDate(
            PurchaseHeader, SalesHeader, ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader, VendorNo);
    end;

    local procedure CreateSalesDocumentWithNoPostingDate(
        var SalesHeader: Record "Sales Header";
        DocumentType: Enum "Sales Document Type";
        var ICPartnerCode: Code[20];
        var VendorNo: Code[20];
        OutboundType: Enum "IC Outb. Sales Item No. Type")
    var
        SalesLine: Record "Sales Line";
    begin
        ICPartnerCode := CreateICPartner();
        UpdateICPartnerWithOutboundType(ICPartnerCode, OutboundType);
        VendorNo := CreateICVendor(ICPartnerCode);

        LibrarySales.CreateSalesHeader(
            SalesHeader, DocumentType, CreateICCustomer(ICPartnerCode));
        LibrarySales.CreateSalesLine(
            SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandIntInRange(10, 100));
    end;

    local procedure ReceiveICPurchaseDocumentWithNoPostingDate(
        var PurchaseHeader: Record "Purchase Header"; var SalesHeader: Record "Sales Header";
        var ICOutboxTransaction: Record "IC Outbox Transaction"; var ICInboxTransaction: Record "IC Inbox Transaction";
        var ICInboxPurchaseHeader: Record "IC Inbox Purchase Header"; VendorNo: Code[20])
    var
        ICOutboxSalesLine: Record "IC Outbox Sales Line";
    begin
        ICInboxOutboxMgt.CreatePurchDocument(ICInboxPurchaseHeader, false, 0D);
        ICOutboxSalesLine."Document Type" := ConvertDocTypeToICOutboxSalesLine(SalesHeader."Document Type");
        InboxICPurchaseDocument(
            PurchaseHeader, ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader, ICOutboxSalesLine, SalesHeader."No.", VendorNo);
    end;

    local procedure CreateSendPurchaseDocumentReceiveSalesDocumentWithNoPostingDate(var PurchaseHeader: Record "Purchase Header"; var SalesHeader: Record "Sales Header")
    var
        DummyICPartner: Record "IC Partner";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICInboxTransaction: Record "IC Inbox Transaction";
        ICInboxSalesHeader: Record "IC Inbox Sales Header";
        ICPartnerCode: Code[20];
        CustomerNo: Code[20];
    begin
        CreatePurchaseDocumentWithNoPostingDates(
            PurchaseHeader, PurchaseHeader."Document Type"::Order, ICPartnerCode, CustomerNo, DummyICPartner."Outbound Purch. Item No. Type"::"Internal No.");
        SendICPurchaseDocument(
            PurchaseHeader, ICPartnerCode, ICOutboxTransaction, ICInboxTransaction, ICInboxSalesHeader);
        ReceiveICSalesDocumentWithNoPostingDate(
            SalesHeader, PurchaseHeader, ICOutboxTransaction, ICInboxTransaction, ICInboxSalesHeader, CustomerNo);
    end;

    local procedure CreatePurchaseDocumentWithNoPostingDates(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; var ICPartnerCode: Code[20]; var CustomerNo: Code[20]; OutboundType: Enum "IC Outb. Sales Item No. Type")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        ICPartnerCode := CreateICPartner();
        UpdateICPartnerWithOutboundType(ICPartnerCode, OutboundType);
        CustomerNo := CreateICCustomer(ICPartnerCode);

        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader, DocumentType, CreateICVendor(ICPartnerCode));
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandIntInRange(10, 100));
    end;

    local procedure ReceiveICSalesDocumentWithNoPostingDate(
        var SalesHeader: Record "Sales Header"; var PurchaseHeader: Record "Purchase Header";
        var ICOutboxTransaction: Record "IC Outbox Transaction"; var ICInboxTransaction: Record "IC Inbox Transaction";
        var ICInboxSalesHeader: Record "IC Inbox Sales Header"; CustomerNo: Code[20])
    var
        ICOutboxPurchaseLine: Record "IC Outbox Purchase Line";
    begin
        ICInboxOutboxMgt.CreateSalesDocument(ICInboxSalesHeader, false, 0D);
        ICOutboxPurchaseLine."Document Type" := ConvertPurchDocTypeToICOutboxPurchLine(PurchaseHeader."Document Type");
        InboxICSalesDocument(
            SalesHeader, ICOutboxTransaction, ICInboxTransaction, ICInboxSalesHeader, ICOutboxPurchaseLine, PurchaseHeader."No.", CustomerNo);
    end;

    local procedure VerifyICOutboxTransaction(
        var ICOutboxTransaction: Record "IC Outbox Transaction";
        DocumentType: Enum "IC Transaction Document Type";
        DocumentNo: Text;
        SourceType: Enum "IC Transaction Source Type";
        ExpectedCount: Integer;
        ICPartnerCode: Code[20])
    begin
        ICOutboxTransaction.SetFilter("Document No.", DocumentNo);
        ICOutboxTransaction.SetRange("Document Type", DocumentType);
        ICOutboxTransaction.SetRange("IC Source Type", SourceType);
        ICOutboxTransaction.SetRange("IC Partner Code", ICPartnerCode);
        Assert.RecordCount(ICOutboxTransaction, ExpectedCount);
    end;
}
