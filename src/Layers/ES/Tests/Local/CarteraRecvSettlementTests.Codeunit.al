codeunit 147536 "Cartera Recv. Settlement Tests"
{
    // // [FEATURE] [Cartera] [Sales] [Settlement]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryCarteraPayables: Codeunit "Library - Cartera Payables";
        LibraryCarteraReceivables: Codeunit "Library - Cartera Receivables";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryService: Codeunit "Library - Service";
        LibraryCarteraCommon: Codeunit "Library - Cartera Common";
        IsInitialized: Boolean;
        ConfirmPostingJournalLinesMsg: Label 'Do you want to post the journal lines?';
        BillGroupNotPrintedMsg: Label 'This %1 has not been printed. Do you want to continue?';
        UnexpectedMessageErr: Label 'Unexpected Message.';
        BankBillGroupPostedForDiscountMsg: Label 'Bank Bill Group %1 was successfully posted for discount.';
        BatchSettlementMsg: Label '%1 Documents in %2 Bill Groups totaling %3 (LCY) have been settled.';
        SuccessfullyPostedJournalLinesMsg: Label 'The journal lines were successfully posted.';
        PartialSettlementBillGroupMsg: Label '%1 receivable documents totaling %2 have been partially settled in Bill Group %3 by an amount of %4.';
        TotalSettlementBillGroupMsg: Label '%1 receivable documents totaling %2 have been settled.';
        UnexpectedNoOfRecordsErr: Label 'Unexpected number of records.';
        UnexpectedAmountErr: Label 'Unexpected amount.';
        UnexpectedDocStatusErr: Label 'Unexpected Document Status in Cust. Ledger Entries.';
        UnexpectedCarteraDocStatusErr: Label 'Unexpected Cartera Doc Status.';
        BankFactoringBillGroupPostedForCollectionMsg: Label 'Bank Bill Group %1 was successfully posted for factoring collection.';
        BillContainsUnrealizedVATErr: Label 'You can not redraw a bill when this contains Unrealized VAT.';
        LocalCurrencyCode: Code[10];

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostBillGroupTest()
    var
        BankAccount: Record "Bank Account";
        BillGroup: Record "Bill Group";
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PostedBillGroup: Record "Posted Bill Group";
        DocumentNo: Code[20];
    begin
        Initialize();

        // Pre-Setup
        PrePostBillGroupSetup(BankAccount, Customer);

        // Setup - Exercise
        DocumentNo := CreateAndPostBillGroup(Customer."No.", BankAccount."No.", BillGroup);

        // Pre-Verify
        LibraryCarteraReceivables.FindOpenCarteraDocCustomerLedgerEntries(CustLedgerEntry,
          Customer."No.", DocumentNo, CustLedgerEntry."Document Situation"::"Posted BG/PO", CustLedgerEntry."Document Type"::Bill);

        // Verify
        PostedBillGroup.SetRange("Bank Account No.", BankAccount."No.");
        PostedBillGroup.FindLast();
        Assert.AreEqual(CustLedgerEntry.Amount, PostedBillGroup.Amount, UnexpectedAmountErr);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,BillGroupDiscountPostedMessageHandler,SettlDocsPostedBillGroupsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TotalSettlementDifferentCustomers()
    var
        GLEntry: Record "G/L Entry";
        BillToCustomer: Record Customer;
        InvoiceToCustomer: Record Customer;
        BankAccount: Record "Bank Account";
        CustomerRating: Record "Customer Rating";
        SalesHeader: Record "Sales Header";
        PaymentMethod: Record "Payment Method";
        BillGroup: Record "Bill Group";
        CarteraDocBill: Record "Cartera Doc.";
        CarteraDocInvoice: Record "Cartera Doc.";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PostedBillGroup: Record "Posted Bill Group";
        CustomerPostingGroupBillTo: Record "Customer Posting Group";
        CustomerPostingGroupInvoiceTo: Record "Customer Posting Group";
        BGPostAndPrint: Codeunit "BG/PO-Post and Print";
        PostedBillGroupTestPage: TestPage "Posted Bill Groups";
        DocumentTypeBill: Code[20];
        DocumentTypeInvoice: Code[20];
        TotalAmountBill: Decimal;
        TotalAmountInvoice: Decimal;
    begin
        Initialize();
        // Create two customers
        // Customer 1
        PrePostBillGroupSetup(BankAccount, BillToCustomer);
        CustomerPostingGroupBillTo.Get(BillToCustomer."Customer Posting Group");

        // Customer 2 - Unrealized VAT
        PrePostBillGroupSetup(BankAccount, InvoiceToCustomer);
        CustomerPostingGroupInvoiceTo.Get(InvoiceToCustomer."Customer Posting Group");
        LibraryCarteraReceivables.CreateFactoringPaymentMethod(PaymentMethod);
        InvoiceToCustomer.Validate("Payment Method Code", PaymentMethod.Code);
        InvoiceToCustomer.Modify(true);

        // Bank account and factoring for InvoiceToCustomer (Customer2)
        LibraryCarteraReceivables.CreateFactoringOperationFeesForBankAccount(BankAccount);
        LibraryCarteraReceivables.CreateCustomerRatingForBank(CustomerRating,
          BankAccount."No.", LocalCurrencyCode, InvoiceToCustomer."No.");

        // Post a sales invoice for BillToCustomer - results a Receivable Doc - Type : Bill
        LibraryCarteraReceivables.CreateSalesInvoice(SalesHeader, BillToCustomer."No.");
        DocumentTypeBill := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Post a sales invoice for InvoiceToCustomer - results a Receivable Doc - Type : Invoice
        LibraryCarteraReceivables.CreateSalesInvoice(SalesHeader, InvoiceToCustomer."No.");
        DocumentTypeInvoice := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Create factoring bill group including two documents
        CreateBillGroup(BillGroup, BankAccount."No.", BillGroup."Dealing Type"::Collection, BillGroup.Factoring::Risked);

        LibraryCarteraReceivables.AddCarteraDocumentToBillGroup(CarteraDocBill, DocumentTypeBill,
          BillToCustomer."No.", BillGroup."No.");
        LibraryCarteraReceivables.AddCarteraDocumentToBillGroup(CarteraDocInvoice, DocumentTypeInvoice,
          InvoiceToCustomer."No.", BillGroup."No.");

        LibraryVariableStorage.Enqueue(StrSubstNo(BillGroupNotPrintedMsg, BillGroup.TableCaption()));
        LibraryVariableStorage.Enqueue(StrSubstNo(BankFactoringBillGroupPostedForCollectionMsg, BillGroup."No."));
        BGPostAndPrint.ReceivablePostOnly(BillGroup);

        // Invoke Total Settlement On BillGroup
        TotalAmountBill := LibraryCarteraReceivables.GetPostedSalesInvoiceAmount(
            BillToCustomer."No.", DocumentTypeBill, CustLedgerEntry."Document Type"::Invoice);

        TotalAmountInvoice := LibraryCarteraReceivables.GetPostedSalesInvoiceAmount(
            InvoiceToCustomer."No.", DocumentTypeInvoice, CustLedgerEntry."Document Type"::Invoice);

        // Open View - Posted Bill Groups page
        PostedBillGroupTestPage.OpenView();

        PostedBillGroup.SetFilter("No.", BillGroup."No.");
        PostedBillGroup.FindFirst();

        PostedBillGroupTestPage.GotoRecord(PostedBillGroup);

        // Exercise - settle both documents
        // Limitation : cannot focus on two records, using page testability so call it sequentially
        Commit();
        LibraryVariableStorage.Enqueue(WorkDate());
        LibraryVariableStorage.Enqueue(StrSubstNo(TotalSettlementBillGroupMsg, 1, TotalAmountBill));
        PostedBillGroupTestPage.Docs."Total Settlement".Invoke();

        LibraryVariableStorage.Enqueue(WorkDate());
        LibraryVariableStorage.Enqueue(StrSubstNo(TotalSettlementBillGroupMsg, 1, TotalAmountInvoice));
        PostedBillGroupTestPage.Docs."Total Settlement".Invoke();

        // Validate General Ledger
        LibraryCarteraReceivables.FindCarteraGLEntries(GLEntry, BillGroup."No.", GLEntry."Document Type"::Payment);
        Assert.AreEqual(CustomerPostingGroupBillTo."Factoring for Collection Acc.", GLEntry."G/L Account No.", '');
        Assert.AreEqual(TotalAmountBill, GLEntry."Credit Amount", UnexpectedAmountErr);
        GLEntry.Next();
        Assert.AreEqual(TotalAmountBill, GLEntry."Debit Amount", UnexpectedAmountErr);
        GLEntry.Next();
        Assert.AreEqual(CustomerPostingGroupInvoiceTo."Factoring for Collection Acc.", GLEntry."G/L Account No.", '');
        Assert.AreEqual(TotalAmountInvoice, GLEntry."Credit Amount", UnexpectedAmountErr);
        GLEntry.Next();
        Assert.AreEqual(TotalAmountInvoice, GLEntry."Debit Amount", UnexpectedAmountErr);

        // Verify
        ValidateTotalSettlement(BillGroup."No.", 2);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,BillGroupDiscountPostedMessageHandler,BatchSettlPostedBillGrsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure BatchSettlementOfPostedBillGroup()
    var
        BankAccount: Record "Bank Account";
        BillGroup: Record "Bill Group";
        Customer: Record Customer;
        DocumentNo: Code[20];
    begin
        Initialize();

        // Pre-Setup
        PrePostBillGroupSetup(BankAccount, Customer);

        // Setup
        DocumentNo := CreateAndPostBillGroup(Customer."No.", BankAccount."No.", BillGroup);

        // Exercise
        ExerciseBatchSettlementReport(Customer."No.", DocumentNo, BillGroup."No.", 1);

        // Validate
        ValidateTotalSettlement(BillGroup."No.", 1);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,CheckDiscountCreditLimitModalPageHandler,PostBillGroupRequestPageHandler,CarteraJournalModalPageHandler,BillGroupDiscountPostedMessageHandler,BatchSettlPostedBillGrsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure BatchSettlementOfPostedBillGroupWithInstallmentAndDiscount()
    var
        BankAccount: Record "Bank Account";
        BillGroup: Record "Bill Group";
        Customer: Record Customer;
        NoOfInstallments: Integer;
        DocumentNo: Code[20];
    begin
        Initialize();

        // Pre-Setup
        PrePostBillGroupSetup(BankAccount, Customer);
        LibraryCarteraReceivables.CreateDiscountOperationFeesForBankAccount(BankAccount);

        // Setup
        NoOfInstallments := LibraryRandom.RandIntInRange(2, 4);
        DocumentNo := CreateAndPostInstallmentsBillGroupsWithDiscount(Customer."No.", BankAccount."No.", NoOfInstallments, BillGroup);

        // Exercise
        ExerciseBatchSettlementReport(Customer."No.", DocumentNo, BillGroup."No.", NoOfInstallments);

        // Validate
        ValidateTotalSettlement(BillGroup."No.", NoOfInstallments);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,CheckDiscountCreditLimitModalPageHandler,PostBillGroupRequestPageHandler,CarteraJournalModalPageHandler,BillGroupDiscountPostedMessageHandler,BatchSettlPostedBillGrsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure BatchSettlementOfPostedBillGroupWithDiscountAndRisk()
    var
        BankAccount: Record "Bank Account";
        BillGroup: Record "Bill Group";
        Customer: Record Customer;
        CustomerRating: Record "Customer Rating";
        DocumentNo: Code[20];
    begin
        Initialize();

        // Pre-Setup
        PrePostBillGroupSetup(BankAccount, Customer);
        LibraryCarteraReceivables.CreateDiscountOperationFeesForBankAccount(BankAccount);
        LibraryCarteraReceivables.CreateCustomerRatingForBank(CustomerRating, BankAccount."No.", LocalCurrencyCode, Customer."No.");

        // Setup
        DocumentNo := CreateAndPostFactoringBillGroupsWithDiscount(Customer."No.", BankAccount."No.", BillGroup);

        // Exercise
        ExerciseBatchSettlementReport(Customer."No.", DocumentNo, BillGroup."No.", 1);

        // Validate
        ValidateTotalSettlement(BillGroup."No.", 1);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,BatchSettlPostedBillGrsRequestPageHandler,BillGroupDiscountPostedMessageHandler')]
    [Scope('OnPrem')]
    procedure BatchSettlementOfPostedBillGroupWithRisk()
    var
        BankAccount: Record "Bank Account";
        BillGroup: Record "Bill Group";
        Customer: Record Customer;
        CustomerRating: Record "Customer Rating";
        DocumentNo: Code[20];
    begin
        Initialize();

        // Pre-Setup
        PrePostBillGroupSetup(BankAccount, Customer);
        LibraryCarteraReceivables.CreateCustomerRatingForBank(CustomerRating, BankAccount."No.", LocalCurrencyCode, Customer."No.");

        // Setup
        DocumentNo := CreateAndPostFactoringBillGroupsWithCollection(Customer."No.", BankAccount."No.", BillGroup);

        // Exercise
        ExerciseBatchSettlementReport(Customer."No.", DocumentNo, BillGroup."No.", 1);

        // Validate
        ValidateTotalSettlement(BillGroup."No.", 1);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,BatchSettlPostedBillGrsRequestPageHandler,BillGroupDiscountPostedMessageHandler,RedrawReceivableBillsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure BatchSettlementOfPostedBillGroupWithUnrealizedVAT()
    var
        Customer: Record Customer;
        BankAccount: Record "Bank Account";
        BillGroup: Record "Bill Group";
        DocumentNo: Code[20];
        SalesUnrVATAccount: Code[20];
        PurchUnrVATAccount: Code[20];
    begin
        Initialize();

        // Setup
        LibraryCarteraCommon.SetupUnrealizedVAT(SalesUnrVATAccount, PurchUnrVATAccount);
        PrePostBillGroupSetup(BankAccount, Customer);

        DocumentNo := CreateAndPostBillGroupsWithUnrealizedVAT(Customer."Payment Method Code",
            Customer."Payment Terms Code", Customer."No.", BankAccount."No.", BillGroup);

        // Exercise
        ExerciseBatchSettlementReport(Customer."No.", DocumentNo, BillGroup."No.", 1);

        // Validate
        ValidateTotalSettlement(BillGroup."No.", 1);
        ValidateUnrealizedVATRedraw(BillGroup."No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,BillGroupDiscountPostedMessageHandler,CheckDiscountCreditLimitModalPageHandler,PostBillGroupRequestPageHandler,CarteraJournalModalPageHandler,SettlDocsPostedBillGroupsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TotalSettlementBillGroupDealingTypeDiscount()
    var
        BankAccount: Record "Bank Account";
        BillGroup: Record "Bill Group";
        Customer: Record Customer;
        DocumentNo: Code[20];
        TotalAmount: Decimal;
    begin
        Initialize();

        // Pre-Setup
        PrePostBillGroupSetup(BankAccount, Customer);
        LibraryCarteraReceivables.CreateDiscountOperationFeesForBankAccount(BankAccount);

        // Setup
        DocumentNo := CreateAndPostBillGroupWithDiscount(Customer."No.", BankAccount."No.", BillGroup);

        // Exercise
        InvokeTotalSettlementOnBillGroup(Customer."No.", DocumentNo, BillGroup."No.", TotalAmount, WorkDate());

        // Verify
        ValidateSettlementLedgerEntries(Customer."No.", DocumentNo, BillGroup."No.", TotalAmount, TotalAmount);
        ValidateTotalSettlementClosedDocuments(DocumentNo, TotalAmount);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,BillGroupDiscountPostedMessageHandler,SettlDocsPostedBillGroupsRequestPageHandler,RedrawReceivableBillsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TotalSettlementBillGroupWithUnrealizedVAT()
    var
        BankAccount: Record "Bank Account";
        BillGroup: Record "Bill Group";
        Customer: Record Customer;
        SalesUnrVATAccount: Code[20];
        PurchUnrVATAccount: Code[20];
        DocumentNo: Code[20];
        TotalAmount: Decimal;
    begin
        Initialize();

        // Pre-Setup
        LibraryCarteraCommon.SetupUnrealizedVAT(SalesUnrVATAccount, PurchUnrVATAccount);
        PrePostBillGroupSetup(BankAccount, Customer);

        // Setup
        DocumentNo := CreateAndPostBillGroupsWithUnrealizedVAT(Customer."Payment Method Code",
            Customer."Payment Terms Code", Customer."No.", BankAccount."No.", BillGroup);

        // Exercise
        InvokeTotalSettlementOnBillGroup(Customer."No.", DocumentNo, BillGroup."No.", TotalAmount, WorkDate());

        // Verify
        ValidateSettlementUnrealizedVATLedgerEntries(Customer."No.", DocumentNo, BillGroup."No.", TotalAmount, TotalAmount);
        ValidateTotalSettlementClosedDocuments(DocumentNo, TotalAmount);
        ValidateUnrealizedVATRedraw(BillGroup."No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,BillGroupDiscountPostedMessageHandler,CheckDiscountCreditLimitModalPageHandler,PostBillGroupRequestPageHandler,CarteraJournalModalPageHandler,SettlDocsPostedBillGroupsRequestPageHandler,RedrawReceivableBillsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TotalSettlementBillGroupUnrealizedVATDealingTypeDiscount()
    var
        BankAccount: Record "Bank Account";
        BillGroup: Record "Bill Group";
        Customer: Record Customer;
        DocumentNo: Code[20];
        TotalAmount: Decimal;
        SalesUnrVATAccount: Code[20];
        PurchUnrVATAccount: Code[20];
    begin
        Initialize();

        // Pre-Setup
        LibraryCarteraCommon.SetupUnrealizedVAT(SalesUnrVATAccount, PurchUnrVATAccount);
        PrePostBillGroupSetup(BankAccount, Customer);
        LibraryCarteraReceivables.CreateDiscountOperationFeesForBankAccount(BankAccount);

        // Setup
        DocumentNo := CreateAndPostBillGroupWithDiscountAndUnrealizedVAT(Customer."Payment Method Code",
            Customer."Payment Terms Code", Customer."No.", BankAccount."No.", BillGroup);

        // Exercise
        InvokeTotalSettlementOnBillGroup(Customer."No.", DocumentNo, BillGroup."No.", TotalAmount, WorkDate());

        // Verify
        ValidateSettlementUnrealizedVATLedgerEntries(Customer."No.", DocumentNo, BillGroup."No.", TotalAmount, TotalAmount);
        ValidateTotalSettlementClosedDocuments(DocumentNo, TotalAmount);
        ValidateUnrealizedVATRedraw(BillGroup."No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,BillGroupDiscountPostedMessageHandler,SettlDocsPostedBillGroupsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TotalSettlementInvoiceBillGroupFactoringUnrVATDealingTypeCollection()
    var
        BankAccount: Record "Bank Account";
        Customer: Record Customer;
        CustomerRating: Record "Customer Rating";
        BillGroup: Record "Bill Group";
        SalesUnrVATAccount: Code[20];
        PurchUnrVATAccount: Code[20];
        DocumentNo: Code[20];
        TotalAmount: Decimal;
    begin
        Initialize();

        LibraryCarteraCommon.SetupUnrealizedVAT(SalesUnrVATAccount, PurchUnrVATAccount);
        PrePostBillGroupSetup(BankAccount, Customer);
        LibraryCarteraReceivables.CreateFactoringOperationFeesForBankAccount(BankAccount);
        LibraryCarteraReceivables.CreateCustomerRatingForBank(CustomerRating, BankAccount."No.", LocalCurrencyCode, Customer."No.");

        DocumentNo := CreateAndPostInvoiceBillGroupsWithFactoringAndUnrealizedVAT(Customer."Payment Method Code",
            Customer."Payment Terms Code", Customer."No.", BankAccount."No.", BillGroup);

        InvokeTotalSettlementOnBillGroup(Customer."No.", DocumentNo, BillGroup."No.", TotalAmount, WorkDate());

        // Verify
        ValidateSettlementUnrealizedVATWithRiskLedgerEntries(Customer."No.", DocumentNo, BillGroup."No.", TotalAmount, TotalAmount, 100);
        ValidateTotalSettlementClosedDocuments(DocumentNo, TotalAmount);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,BillGroupDiscountPostedMessageHandler,CheckDiscountCreditLimitModalPageHandler,PostBillGroupRequestPageHandler,CarteraJournalModalPageHandler,SettlDocsPostedBillGroupsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TotalSettlementInvoiceBillGroupFactoringUnrVATDealingTypeDiscount()
    var
        BankAccount: Record "Bank Account";
        BillGroup: Record "Bill Group";
        Customer: Record Customer;
        CustomerRating: Record "Customer Rating";
        FeeRange: Record "Fee Range";
        SalesUnrVATAccount: Code[20];
        PurchUnrVATAccount: Code[20];
        DocumentNo: Code[20];
        TotalAmount: Decimal;
    begin
        Initialize();

        LibraryCarteraCommon.SetupUnrealizedVAT(SalesUnrVATAccount, PurchUnrVATAccount);
        PrePostBillGroupSetup(BankAccount, Customer);
        LibraryCarteraReceivables.CreateFactoringOperationFeesForBankAccount(BankAccount);
        LibraryCarteraReceivables.CreateCustomerRatingForBank(CustomerRating, BankAccount."No.", LocalCurrencyCode, Customer."No.");

        LibraryCarteraReceivables.CreateDiscountOperationFeesForBankAccount(BankAccount);
        LibraryCarteraReceivables.CreateFeeRange(FeeRange,
          BankAccount."No.", LocalCurrencyCode, FeeRange."Type of Fee"::"Discount Interests");

        DocumentNo := CreateAndPostInvoiceBillGroupsWithFactoringUnrealizedVATAndDiscount(
            Customer."No.", BankAccount."No.", BillGroup);

        InvokeTotalSettlementOnBillGroup(Customer."No.", DocumentNo, BillGroup."No.", TotalAmount, WorkDate());

        // Verify
        ValidateSettlementUnrealizedVATWithRiskLedgerEntries(Customer."No.", DocumentNo, BillGroup."No.",
          TotalAmount, TotalAmount, CustomerRating."Risk Percentage");
        ValidateTotalSettlementClosedDocuments(DocumentNo, TotalAmount);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('NoSeriesListModalPageHandler,BankAccountSelectionModalPageHandler,CarteraDocumentsModalPageHandler,ConfirmHandlerYes,BillGroupDiscountPostedMessageHandler,SettlDocsPostedBillGroupsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TotalSettlementBillGroupPmtDiscountTypePmtDiscExclVAT()
    var
        BankAccount: Record "Bank Account";
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GLSetup: Record "General Ledger Setup";
        SalesHeader: Record "Sales Header";
        BillGroup: Record "Bill Group";
        GLEntry: Record "G/L Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        PaymentTerms: Record "Payment Terms";
        DocumentNo: Code[20];
        DiscountPercent: Decimal;
        TotalAmount: Decimal;
        PaymentDiscountGiven: Decimal;
    begin
        Initialize();

        LibraryCarteraReceivables.SetupPaymentDiscountType(GLSetup."Payment Discount Type"::"Pmt. Disc. Excl. VAT");

        LibraryCarteraReceivables.CreateFactoringCustomer(Customer, LocalCurrencyCode);
        Customer.Validate("Application Method", Customer."Application Method"::Manual);
        Customer.Modify(true);

        CustomerPostingGroup.Get(Customer."Customer Posting Group");

        DiscountPercent := LibraryRandom.RandDecInRange(1, 10, 2);

        // Update Payment Terms with discount %
        PaymentTerms.Get(Customer."Payment Terms Code");
        PaymentTerms.Validate("Discount %", DiscountPercent);
        PaymentTerms.Modify(true);

        // Difference is that test case sells lines of G/L account - miscellaneou
        LibraryCarteraReceivables.CreateSalesInvoice(SalesHeader, Customer."No.");
        // Verify the discount percent
        SalesHeader.TestField("Payment Discount %", DiscountPercent);

        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        LibraryCarteraReceivables.CreateBankAccount(BankAccount, LocalCurrencyCode);

        CreateBillGroupWithPageTestability(BillGroup, BankAccount."No.", DocumentNo,
          BillGroup."Dealing Type"::Collection, BillGroup.Factoring::Unrisked);

        InvokeSettlementFromPostedBillGroupsPage(Customer."No.", DocumentNo, TotalAmount);

        PaymentDiscountGiven := Round(TotalAmount * DiscountPercent / 100, LibraryERM.GetAmountRoundingPrecision());

        // Validate General Ledger with expected discount percent
        LibraryCarteraReceivables.FindCarteraGLEntries(GLEntry, BillGroup."No.", GLEntry."Document Type"::Payment);
        // -- Interest on bills discounted GL Account and discount value
        Assert.AreEqual(CustomerPostingGroup."Payment Disc. Debit Acc.", GLEntry."G/L Account No.", '');
        Assert.AreEqual(PaymentDiscountGiven, GLEntry."Debit Amount", UnexpectedAmountErr);
        GLEntry.Next();
        Assert.AreEqual(TotalAmount, GLEntry."Credit Amount", UnexpectedAmountErr);
        GLEntry.Next();
        Assert.AreEqual(Round(TotalAmount - PaymentDiscountGiven, LibraryERM.GetAmountRoundingPrecision()),
          GLEntry."Debit Amount", UnexpectedAmountErr);

        // Find Cartera Customer Ledger Entries for paid bill
        LibraryCarteraReceivables.FindCarteraDocCustomerLedgerEntry(CustLedgerEntry, Customer."No.", BillGroup."No.",
          CustLedgerEntry."Document Situation"::" ", CustLedgerEntry."Document Type"::Payment);
        // -- Validate
        Assert.AreEqual(-TotalAmount, CustLedgerEntry."Amount (LCY) stats.", UnexpectedAmountErr);
        Assert.AreEqual(0, CustLedgerEntry."Remaining Amount", UnexpectedAmountErr);

        // Find Detailed Customer Ledger Entry for Bill - Initial Entry
        LibraryCarteraReceivables.FindDetailedCustomerLedgerEntry(DetailedCustLedgEntry, Customer."No.", BillGroup."No.",
          DetailedCustLedgEntry."Entry Type"::"Initial Entry", DetailedCustLedgEntry."Document Type"::Payment);
        Assert.AreEqual(-(TotalAmount - PaymentDiscountGiven), DetailedCustLedgEntry.Amount, UnexpectedAmountErr);

        LibraryCarteraReceivables.FindDetailedCustomerLedgerEntry(DetailedCustLedgEntry, Customer."No.", BillGroup."No.",
          DetailedCustLedgEntry."Entry Type"::"Payment Discount", DetailedCustLedgEntry."Document Type"::Payment);
        Assert.AreEqual(-PaymentDiscountGiven, DetailedCustLedgEntry.Amount, UnexpectedAmountErr);

        LibraryCarteraReceivables.FindDetailedCustomerLedgerEntry(DetailedCustLedgEntry, Customer."No.", BillGroup."No.",
          DetailedCustLedgEntry."Entry Type"::Application, DetailedCustLedgEntry."Document Type"::Payment);
        Assert.AreEqual(-TotalAmount, DetailedCustLedgEntry.Amount, UnexpectedAmountErr);

        ValidateTotalSettlement(BillGroup."No.", 1);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,BillGroupDiscountPostedMessageHandler,CheckDiscountCreditLimitModalPageHandler,PostBillGroupRequestPageHandler,CarteraJournalModalPageHandler,SettlDocsPostedBillGroupsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TotalSettlementServiceInvoiceWithDealingDiscount()
    var
        BankAccount: Record "Bank Account";
        Customer: Record Customer;
        CarteraDoc: Record "Cartera Doc.";
        BillGroup: Record "Bill Group";
        DocumentNo: Code[20];
        TotalAmount: Decimal;
    begin
        Initialize();

        PrePostBillGroupSetup(BankAccount, Customer);
        LibraryCarteraReceivables.CreateDiscountOperationFeesForBankAccount(BankAccount);
        DocumentNo := CreateAndPostServiceInvoice(Customer);
        LibraryCarteraReceivables.CreateBillGroup(BillGroup, BankAccount."No.", BillGroup."Dealing Type"::Discount);
        LibraryCarteraReceivables.AddCarteraDocumentToBillGroup(CarteraDoc, DocumentNo, Customer."No.", BillGroup."No.");

        // Excercise
        PostBillGroupsWithDiscountForCustomer(BillGroup);
        InvokeTotalSettlementOnBillGroup(Customer."No.", DocumentNo, BillGroup."No.", TotalAmount, WorkDate());

        // Verify
        ValidateSettlementLedgerEntries(Customer."No.", DocumentNo, BillGroup."No.", TotalAmount, TotalAmount);
        ValidateTotalSettlementClosedDocuments(DocumentNo, TotalAmount);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,BillGroupDiscountPostedMessageHandler,SettlDocsPostedBillGroupsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TotalSettlementServiceInvoiceWithDealingCollection()
    var
        BankAccount: Record "Bank Account";
        Customer: Record Customer;
        BillGroup: Record "Bill Group";
        CarteraDoc: Record "Cartera Doc.";
        DocumentNo: Code[20];
        TotalAmount: Decimal;
    begin
        Initialize();

        PrePostBillGroupSetup(BankAccount, Customer);
        DocumentNo := CreateAndPostServiceInvoice(Customer);

        LibraryCarteraReceivables.CreateBillGroup(BillGroup, BankAccount."No.", BillGroup."Dealing Type"::Collection);
        LibraryCarteraReceivables.AddCarteraDocumentToBillGroup(CarteraDoc, DocumentNo, Customer."No.", BillGroup."No.");

        PostBillGroupWithTypeCollection(BillGroup);
        InvokeTotalSettlementOnBillGroup(Customer."No.", DocumentNo, BillGroup."No.", TotalAmount, WorkDate());

        // Verify
        ValidateSettlementLedgerEntries(Customer."No.", DocumentNo, BillGroup."No.", TotalAmount, TotalAmount);
        ValidateTotalSettlementClosedDocuments(DocumentNo, TotalAmount);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,BillGroupDiscountPostedMessageHandler,PartialSettlReceivableRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PartialSettlementBillGroupDealingTypeCollection()
    var
        BankAccount: Record "Bank Account";
        BillGroup: Record "Bill Group";
        Customer: Record Customer;
        DocumentNo: Code[20];
        InitialAmount: Decimal;
        SettledAmount: Decimal;
    begin
        Initialize();

        // Pre-Setup
        PrePostBillGroupSetup(BankAccount, Customer);

        // Setup
        DocumentNo := CreateAndPostBillGroup(Customer."No.", BankAccount."No.", BillGroup);

        // Exercise
        InvokePartialSettlementOnBillGroup(Customer."No.", DocumentNo, BillGroup."No.", InitialAmount, SettledAmount);

        // Verify
        ValidateSettlementLedgerEntries(Customer."No.", DocumentNo, BillGroup."No.", InitialAmount, SettledAmount);
        ValidatePartialSettlementPostedDocuments(DocumentNo, InitialAmount, SettledAmount);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,BillGroupDiscountPostedMessageHandler,PartialSettlReceivableRequestPageHandler,CheckDiscountCreditLimitModalPageHandler,PostBillGroupRequestPageHandler,CarteraJournalModalPageHandler')]
    [Scope('OnPrem')]
    procedure PartialSettlementBillGroupDealingTypeDiscount()
    var
        BankAccount: Record "Bank Account";
        BillGroup: Record "Bill Group";
        Customer: Record Customer;
        DocumentNo: Code[20];
        InitialAmount: Decimal;
        SettledAmount: Decimal;
    begin
        Initialize();

        // Pre-Setup
        PrePostBillGroupSetup(BankAccount, Customer);
        LibraryCarteraReceivables.CreateDiscountOperationFeesForBankAccount(BankAccount);

        // Setup
        DocumentNo := CreateAndPostBillGroupWithDiscount(Customer."No.", BankAccount."No.", BillGroup);

        // Exercise
        InvokePartialSettlementOnBillGroup(Customer."No.", DocumentNo, BillGroup."No.", InitialAmount, SettledAmount);

        // Verify
        ValidateSettlementLedgerEntries(Customer."No.", DocumentNo, BillGroup."No.", InitialAmount, SettledAmount);
        ValidatePartialSettlementPostedDocuments(DocumentNo, InitialAmount, SettledAmount);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,BillGroupDiscountPostedMessageHandler,PartialSettlReceivableRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PartialSettlementBillGroupUnrealizedVAT()
    var
        BankAccount: Record "Bank Account";
        BillGroup: Record "Bill Group";
        Customer: Record Customer;
        DocumentNo: Code[20];
        InitialAmount: Decimal;
        SettledAmount: Decimal;
        SalesUnrVATAccount: Code[20];
        PurchUnrVATAccount: Code[20];
    begin
        Initialize();

        // Pre-Setup
        LibraryCarteraCommon.SetupUnrealizedVAT(SalesUnrVATAccount, PurchUnrVATAccount);
        PrePostBillGroupSetup(BankAccount, Customer);

        DocumentNo := CreateAndPostBillGroupsWithUnrealizedVAT(Customer."Payment Method Code",
            Customer."Payment Terms Code", Customer."No.", BankAccount."No.", BillGroup);

        // Exercise
        InvokePartialSettlementOnBillGroup(Customer."No.", DocumentNo, BillGroup."No.", InitialAmount, SettledAmount);

        // Verify
        ValidateSettlementLedgerEntries(Customer."No.", DocumentNo, BillGroup."No.", InitialAmount, SettledAmount);
        ValidatePartialSettlementPostedDocuments(DocumentNo, InitialAmount, SettledAmount);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,BillGroupDiscountPostedMessageHandler,PartialSettlReceivableRequestPageHandler,CheckDiscountCreditLimitModalPageHandler,PostBillGroupRequestPageHandler,CarteraJournalModalPageHandler')]
    [Scope('OnPrem')]
    procedure PartialSettlementBillGroupUnrealizedVATDealingTypeDiscount()
    var
        BankAccount: Record "Bank Account";
        BillGroup: Record "Bill Group";
        Customer: Record Customer;
        DocumentNo: Code[20];
        InitialAmount: Decimal;
        SettledAmount: Decimal;
        SalesUnrVATAccount: Code[20];
        PurchUnrVATAccount: Code[20];
    begin
        Initialize();

        // Pre-Setup
        LibraryCarteraCommon.SetupUnrealizedVAT(SalesUnrVATAccount, PurchUnrVATAccount);
        PrePostBillGroupSetup(BankAccount, Customer);
        LibraryCarteraReceivables.CreateDiscountOperationFeesForBankAccount(BankAccount);

        // Setup
        DocumentNo := CreateAndPostBillGroupWithDiscountAndUnrealizedVAT(Customer."Payment Method Code",
            Customer."Payment Terms Code", Customer."No.", BankAccount."No.", BillGroup);

        // Exercise
        InvokePartialSettlementOnBillGroup(Customer."No.", DocumentNo, BillGroup."No.", InitialAmount, SettledAmount);

        // Verify
        ValidateSettlementLedgerEntries(Customer."No.", DocumentNo, BillGroup."No.", InitialAmount, SettledAmount);
        ValidatePartialSettlementPostedDocuments(DocumentNo, InitialAmount, SettledAmount);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,BillGroupDiscountPostedMessageHandler,PartialSettlReceivableRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PartialSettlementInvoiceBillGroupFactoringUnrVATDealingTypeCollection()
    var
        BankAccount: Record "Bank Account";
        Customer: Record Customer;
        CustomerRating: Record "Customer Rating";
        BillGroup: Record "Bill Group";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        SalesUnrVATAccount: Code[20];
        PurchUnrVATAccount: Code[20];
        DocumentNo: Code[20];
        InitialAmount: Decimal;
        SettledAmount: Decimal;
    begin
        // TFS ID 61619
        Initialize();

        // Pre-Setup Unrealized VAT
        LibraryCarteraCommon.SetupUnrealizedVAT(SalesUnrVATAccount, PurchUnrVATAccount);

        PrePostBillGroupSetup(BankAccount, Customer);

        // Pre-Setup Factoring
        LibraryCarteraReceivables.CreateFactoringOperationFeesForBankAccount(BankAccount);
        LibraryCarteraReceivables.CreateCustomerRatingForBank(CustomerRating, BankAccount."No.", LocalCurrencyCode, Customer."No.");

        // Setup - Post cartera document and create bill group
        DocumentNo := CreateAndPostInvoiceBillGroupsWithFactoringAndUnrealizedVAT(Customer."Payment Method Code",
            Customer."Payment Terms Code", Customer."No.", BankAccount."No.", BillGroup);

        // Exercise
        InvokePartialSettlementOnBillGroup(Customer."No.", DocumentNo, BillGroup."No.", InitialAmount, SettledAmount);

        // Verify
        ValidateLedgerEntries(Customer."No.", DocumentNo, BillGroup."No.",
          InitialAmount, SettledAmount, DetailedCustLedgEntry."Document Type"::Invoice);
        ValidatePartialSettlementPostedDocuments(DocumentNo, InitialAmount, SettledAmount);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,BillGroupDiscountPostedMessageHandler,PartialSettlReceivableRequestPageHandler,CheckDiscountCreditLimitModalPageHandler,PostBillGroupRequestPageHandler,CarteraJournalModalPageHandler')]
    [Scope('OnPrem')]
    procedure PartialSettlementInvoiceBillGroupFactoringUnrVATDealingTypeDiscount()
    var
        BankAccount: Record "Bank Account";
        BillGroup: Record "Bill Group";
        Customer: Record Customer;
        CustomerRating: Record "Customer Rating";
        FeeRange: Record "Fee Range";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        SalesUnrVATAccount: Code[20];
        PurchUnrVATAccount: Code[20];
        DocumentNo: Code[20];
        InitialAmount: Decimal;
        SettledAmount: Decimal;
    begin
        // TFS ID 61621
        Initialize();

        LibraryCarteraCommon.SetupUnrealizedVAT(SalesUnrVATAccount, PurchUnrVATAccount);
        PrePostBillGroupSetup(BankAccount, Customer);
        LibraryCarteraReceivables.CreateFactoringOperationFeesForBankAccount(BankAccount);
        LibraryCarteraReceivables.CreateCustomerRatingForBank(CustomerRating, BankAccount."No.", LocalCurrencyCode, Customer."No.");

        LibraryCarteraReceivables.CreateDiscountOperationFeesForBankAccount(BankAccount);
        LibraryCarteraReceivables.CreateFeeRange(FeeRange,
          BankAccount."No.", LocalCurrencyCode, FeeRange."Type of Fee"::"Discount Interests");

        DocumentNo := CreateAndPostInvoiceBillGroupsWithFactoringUnrealizedVATAndDiscount(
            Customer."No.", BankAccount."No.", BillGroup);

        // Exercise
        InvokePartialSettlementOnBillGroup(Customer."No.", DocumentNo, BillGroup."No.", InitialAmount, SettledAmount);

        // Verify
        ValidateLedgerEntries(Customer."No.", DocumentNo, BillGroup."No.",
          InitialAmount, SettledAmount, DetailedCustLedgEntry."Document Type"::Invoice);
        ValidatePartialSettlementPostedDocuments(DocumentNo, InitialAmount, SettledAmount);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,BillGroupDiscountPostedMessageHandler,PartialSettlReceivableRequestPageHandler,CheckDiscountCreditLimitModalPageHandler,PostBillGroupRequestPageHandler,CarteraJournalModalPageHandler')]
    [Scope('OnPrem')]
    procedure PartialSettlementServiceInvoiceWithDealingDiscount()
    var
        BankAccount: Record "Bank Account";
        Customer: Record Customer;
        CarteraDoc: Record "Cartera Doc.";
        BillGroup: Record "Bill Group";
        DocumentNo: Code[20];
        InitialAmount: Decimal;
        SettledAmount: Decimal;
    begin
        Initialize();

        PrePostBillGroupSetup(BankAccount, Customer);
        LibraryCarteraReceivables.CreateDiscountOperationFeesForBankAccount(BankAccount);
        DocumentNo := CreateAndPostServiceInvoice(Customer);
        LibraryCarteraReceivables.CreateBillGroup(BillGroup, BankAccount."No.", BillGroup."Dealing Type"::Discount);
        LibraryCarteraReceivables.AddCarteraDocumentToBillGroup(CarteraDoc, DocumentNo, Customer."No.", BillGroup."No.");

        // Excercise
        PostBillGroupsWithDiscountForCustomer(BillGroup);
        InvokePartialSettlementOnBillGroup(Customer."No.", DocumentNo, BillGroup."No.", InitialAmount, SettledAmount);

        // Verify
        ValidateSettlementLedgerEntries(Customer."No.", DocumentNo, BillGroup."No.", InitialAmount, SettledAmount);
        ValidatePartialSettlementPostedDocuments(DocumentNo, InitialAmount, SettledAmount);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,BillGroupDiscountPostedMessageHandler,PartialSettlReceivableRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PartialSettlementServiceInvoiceWithDealingCollection()
    var
        BankAccount: Record "Bank Account";
        Customer: Record Customer;
        BillGroup: Record "Bill Group";
        CarteraDoc: Record "Cartera Doc.";
        DocumentNo: Code[20];
        InitialAmount: Decimal;
        SettledAmount: Decimal;
    begin
        Initialize();

        PrePostBillGroupSetup(BankAccount, Customer);
        DocumentNo := CreateAndPostServiceInvoice(Customer);

        LibraryCarteraReceivables.CreateBillGroup(BillGroup, BankAccount."No.", BillGroup."Dealing Type"::Collection);
        LibraryCarteraReceivables.AddCarteraDocumentToBillGroup(CarteraDoc, DocumentNo, Customer."No.", BillGroup."No.");

        // Exercise
        PostBillGroupWithTypeCollection(BillGroup);
        InvokePartialSettlementOnBillGroup(Customer."No.", DocumentNo, BillGroup."No.", InitialAmount, SettledAmount);

        // Verify
        ValidateSettlementLedgerEntries(Customer."No.", DocumentNo, BillGroup."No.", InitialAmount, SettledAmount);
        ValidatePartialSettlementPostedDocuments(DocumentNo, InitialAmount, SettledAmount);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,PostBillGroupRequestPageHandler,CarteraJournalModalPageHandler,BillGroupDiscountPostedMessageHandler,SettlDocsPostedBillGroupsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TotalSettlOnNewDateBillGroupDiscountRiskedAndChargeAfterExchRateAdjust()
    var
        BillGroup: Record "Bill Group";
        CustomerNo: Code[20];
        BankAccountNo: Code[20];
        CurrencyCode: Code[10];
        PostingDate: array[4] of Date;
        DocumentNo: Code[20];
        InvoiceAmount: Decimal;
    begin
        // [FEATURE] [Bill Group] [Currency] [Adjust Exchange Rates]
        // [SCENARIO 270953] Total settlement of posted Bill Group with "Risked Factoring Expenses", "Charge Amt. per Operation" and "Bill Groups - Discount" after adjust exchange rates
        Initialize();

        // [GIVEN] Currency with "Bill Groups - Discount" = TRUE, exchange rates on dates 01-01-2018, 02-01-2018, 03-01-2018, 04-01-2018
        CurrencyCode := PrepareCurrencyTFS270953(PostingDate);

        // [GIVEN] FCY Bank Account with "Risked Factoring Expenses", "Charge Amt. per Operation", FCY Customer with ratings setup
        PrepareCustAndBankWithFCYCustRatingsAndFactOperFees(CustomerNo, BankAccountNo, CurrencyCode);

        // [GIVEN] Posted FCY Sales Invoice on 01-01-2018
        // [GIVEN] Posted Bill Group on 02-01-2018
        DocumentNo := CreateAndPostFactoringBillGroupsWithDiscountOnDate(CustomerNo, BankAccountNo, BillGroup, PostingDate[2]);

        // [GIVEN] Run adjust exchange rates using "Ending Date" = 03-01-2018
        LibraryERM.RunExchRateAdjustmentSimple(CurrencyCode, PostingDate[3], PostingDate[3]);

        // [WHEN] Run "Total Settlement" from posted bill group
        InvokeTotalSettlementOnBillGroup(CustomerNo, DocumentNo, BillGroup."No.", InvoiceAmount, PostingDate[4]);

        // [THEN] The document has been settled
        ValidateTotalSettlementClosedDocuments(DocumentNo, InvoiceAmount);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,BillGroupDiscountPostedMessageHandler,SettlDocsPostedBillGroupsRequestPageHandler,RedrawReceivableBillsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TotalSettlementBillGroupWithUnrealizedVATPositiveNegativeLinesInDocument()
    var
        BankAccount: Record "Bank Account";
        BillGroup: Record "Bill Group";
        Customer: Record Customer;
        PaymentMethod: Record "Payment Method";
        PaymentTerms: Record "Payment Terms";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        CarteraDoc: Record "Cartera Doc.";
        GeneralLedgerSetup: Record "General Ledger Setup";
        BGPostAndPrint: Codeunit "BG/PO-Post and Print";
        DocumentNo: Code[20];
        TotalAmount: Decimal;
    begin
        // [SCENARIO 416820] Stan can settle Payment Order for Invoice containing NO VAT self balancing zero VAT Entries within Cash Regime and Unrealized VAT
        Initialize();

        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("VAT Cash Regime", true);
        GeneralLedgerSetup.Modify(true);

        PrePostBillGroupSetup(BankAccount, Customer);

        PaymentMethod.Get(Customer."Payment Method Code");
        LibraryCarteraReceivables.UpdatePaymentMethodForBillsWithUnrealizedVAT(PaymentMethod);

        LibraryCarteraReceivables.SetPaymentTermsVatDistribution(
          Customer."Payment Terms Code", PaymentTerms."VAT distribution"::Proportional);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");

        CreateVATPostingSetupVATCashRegime(VATPostingSetup, Customer."VAT Bus. Posting Group", 0);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        SalesLine.Validate("Unit Price", 100);
        SalesLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        SalesLine.Modify(true);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, SalesLine."No.", -1);
        SalesLine.Validate("Unit Price", 100);
        SalesLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        SalesLine.Modify(true);

        CreateVATPostingSetupVATCashRegime(VATPostingSetup, Customer."VAT Bus. Posting Group", 21);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        SalesLine.Validate("Unit Price", 1000);
        SalesLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        SalesLine.Modify(true);

        SalesHeader.TestField("Special Scheme Code", SalesHeader."Special Scheme Code"::"07 Special Cash");

        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        LibraryCarteraReceivables.CreateBillGroup(BillGroup, BankAccount."No.", BillGroup."Dealing Type"::Collection);
        LibraryCarteraReceivables.AddCarteraDocumentToBillGroup(CarteraDoc, DocumentNo, Customer."No.", BillGroup."No.");

        LibraryVariableStorage.Enqueue(StrSubstNo(BillGroupNotPrintedMsg, BillGroup.TableCaption()));
        BGPostAndPrint.ReceivablePostOnly(BillGroup);

        InvokeTotalSettlementOnBillGroup(Customer."No.", DocumentNo, BillGroup."No.", TotalAmount, WorkDate());

        ValidateSettlementUnrealizedVATLedgerEntries(Customer."No.", DocumentNo, BillGroup."No.", TotalAmount, TotalAmount);
        ValidateTotalSettlementClosedDocuments(DocumentNo, TotalAmount);
        ValidateUnrealizedVATRedraw(BillGroup."No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,OpenBankCatPostRecBillsMatrix,OpenPostedBills')]
    procedure PostBillPaymentMatrixFiltersBankAccountNo()
    var
        BankAccount: Record "Bank Account";
        BillGroup: Record "Bill Group";
        Customer: Record Customer;
        BankAccountCard: TestPage "Bank Account Card";
        BankCatPostedReceivBills: TestPage "Bank Cat. Posted Receiv. Bills";
        AnalysisPeriodType: Enum "Analysis Period Type";
    begin
        // [SCENARIO 554713] The Posted Receivable Bills Matrix show correct information as there is filter to Bank Account.
        Initialize();

        // [GIVEN] Setup Bill Group Setup with Bank and Customer.
        PrePostBillGroupSetup(BankAccount, Customer);

        // [GIVEN] Create and Post Bill Group.
        CreateAndPostBillGroup(Customer."No.", BankAccount."No.", BillGroup);

        // [GIVEN] Store Bank Account.
        LibraryVariableStorage.Enqueue(BankAccount."No.");

        // [GIVEN] Open Bank Account Card and go to Posted Receivable Bills.
        BankAccountCard.OpenEdit();
        BankAccountCard.GoToRecord(BankAccount);
        BankAccountCard."Posted Recei&vable Bills".Invoke();

        // [GIVEN] Store Bank Account.
        LibraryVariableStorage.Enqueue(BankAccount."No.");

        // [THEN] Bank Account filter is added when Matrix is invoked.
        BankCatPostedReceivBills.OpenEdit();
        BankCatPostedReceivBills.GoToRecord(BankAccount);
        BankCatPostedReceivBills.PeriodType.SetValue(AnalysisPeriodType::Year);
        BankCatPostedReceivBills."&Show Matrix".Invoke();
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        LocalCurrencyCode := '';
        LibraryCarteraCommon.RevertUnrealizedVATPostingSetup();

        if IsInitialized then
            exit;

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateAccountInCustomerPostingGroup();
        IsInitialized := true;
    end;

    local procedure PrepareCurrencyTFS270953(var PostingDate: array[4] of Date): Code[10]
    var
        ExchRate: array[4] of Decimal;
    begin
        ExchRate[1] := 0.9;
        ExchRate[2] := 0.8;
        ExchRate[3] := 0.6;
        ExchRate[4] := 0.7;
        exit(CreateCurrencyWithSevExchRates(PostingDate, ExchRate, true));
    end;

    local procedure PrepareCustAndBankWithFCYCustRatingsAndFactOperFees(var CustomerNo: Code[20]; var BankAccountNo: Code[20]; CurrencyCode: Code[10])
    var
        Customer: Record Customer;
        BankAccount: Record "Bank Account";
        CustomerRating: Record "Customer Rating";
    begin
        LibraryCarteraReceivables.CreateCarteraCustomer(Customer, CurrencyCode);
        CustomerNo := Customer."No.";
        LibraryCarteraReceivables.CreateBankAccount(BankAccount, CurrencyCode);
        BankAccountNo := BankAccount."No.";
        LibraryCarteraReceivables.CreateCustomerRatingForBank(CustomerRating, BankAccountNo, CurrencyCode, CustomerNo);
        LibraryCarteraReceivables.CreateFactoringOperationFeesForBankAccount(BankAccount);
    end;

    local procedure PrePostBillGroupSetup(var BankAccount: Record "Bank Account"; var Customer: Record Customer)
    var
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        LibraryCarteraReceivables.CreateCarteraCustomer(Customer, LocalCurrencyCode);
        LibraryCarteraReceivables.CreateCustomerBankAccount(Customer, CustomerBankAccount);
        LibraryCarteraReceivables.CreateBankAccount(BankAccount, LocalCurrencyCode);
    end;

    local procedure ExerciseBatchSettlementReport(CustomerNo: Code[20]; DocumentNo: Code[20]; BillGroupNo: Code[20]; NoOfClosedCarteraDoc: Integer)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PostedBillGroup: Record "Posted Bill Group";
        PostedBillGroupSelect: TestPage "Posted Bill Group Select.";
        GroupAmountLCY: Decimal;
    begin
        // Pre-Exercise
        GroupAmountLCY :=
          LibraryCarteraReceivables.GetPostedSalesInvoiceAmount(CustomerNo, DocumentNo, CustLedgerEntry."Document Type"::Invoice);
        LibraryVariableStorage.Enqueue(StrSubstNo(BatchSettlementMsg, NoOfClosedCarteraDoc, 1, GroupAmountLCY));

        // Exercise
        PostedBillGroup.SetFilter("No.", BillGroupNo);
        PostedBillGroup.FindFirst();

        PostedBillGroupSelect.OpenView();
        PostedBillGroupSelect.GotoRecord(PostedBillGroup);

        Commit();
        PostedBillGroupSelect.BatchSettlement.Invoke();
    end;

    local procedure InvokePartialSettlementOnBillGroup(CustomerNo: Code[20]; DocumentNo: Code[20]; BillGroupNo: Code[20]; var InitialAmount: Decimal; var SettledAmount: Decimal)
    var
        PostedBillGroup: Record "Posted Bill Group";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GLSetup: Record "General Ledger Setup";
        PostedBillGroupTestPage: TestPage "Posted Bill Groups";
    begin
        GLSetup.Get();

        // Open for Edit - Posted Bill Groups page
        PostedBillGroupTestPage.OpenView();

        PostedBillGroup.SetFilter("No.", BillGroupNo);
        PostedBillGroup.FindFirst();

        PostedBillGroupTestPage.GotoRecord(PostedBillGroup);

        InitialAmount := LibraryCarteraReceivables.GetPostedSalesInvoiceAmount(
            CustomerNo, DocumentNo, CustLedgerEntry."Document Type"::Invoice);
        SettledAmount := LibraryRandom.RandDecInDecimalRange(0, InitialAmount / 2,
            LibraryCarteraPayables.GetRandomAllowedNumberOfDecimals(GLSetup."Amount Decimal Places"));

        LibraryVariableStorage.Enqueue(SettledAmount);
        LibraryVariableStorage.Enqueue(StrSubstNo(PartialSettlementBillGroupMsg, 1, InitialAmount, BillGroupNo, SettledAmount));

        // Exercise
        Commit();
        PostedBillGroupTestPage.Docs."Partial Settlement".Invoke();
    end;

    local procedure InvokeTotalSettlementOnBillGroup(CustomerNo: Code[20]; DocumentNo: Code[20]; BillGroupNo: Code[20]; var TotalAmount: Decimal; SettlePostingDate: Date)
    var
        PostedBillGroup: Record "Posted Bill Group";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PostedBillGroupTestPage: TestPage "Posted Bill Groups";
    begin
        TotalAmount := LibraryCarteraReceivables.GetPostedSalesInvoiceAmount(
            CustomerNo, DocumentNo, CustLedgerEntry."Document Type"::Invoice);

        // Open View - Posted Bill Groups page
        PostedBillGroupTestPage.OpenView();

        PostedBillGroup.SetFilter("No.", BillGroupNo);
        PostedBillGroup.FindFirst();

        PostedBillGroupTestPage.GotoRecord(PostedBillGroup);

        // Exercise
        Commit();
        LibraryVariableStorage.Enqueue(SettlePostingDate);
        LibraryVariableStorage.Enqueue(StrSubstNo(TotalSettlementBillGroupMsg, 1, TotalAmount));
        PostedBillGroupTestPage.Docs."Total Settlement".Invoke();
    end;

    local procedure InvokeSettlementFromPostedBillGroupsPage(CustomerNo: Code[20]; DocumentNo: Code[20]; var TotalAmount: Decimal)
    var
        PostedCarteraDoc: Record "Posted Cartera Doc.";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PostedBillsTestPage: TestPage "Posted Bills";
    begin
        TotalAmount := LibraryCarteraReceivables.GetPostedSalesInvoiceAmount(
            CustomerNo, DocumentNo, CustLedgerEntry."Document Type"::Invoice);

        PostedCarteraDoc.SetRange("Document No.", DocumentNo);
        PostedCarteraDoc.FindFirst();

        // Open View - Posted Bills page
        PostedBillsTestPage.OpenView();
        PostedBillsTestPage.GotoRecord(PostedCarteraDoc);

        // Settle
        Commit();
        LibraryVariableStorage.Enqueue(WorkDate());
        LibraryVariableStorage.Enqueue(StrSubstNo(TotalSettlementBillGroupMsg, 1, TotalAmount));
        PostedBillsTestPage.Settle.Invoke();
    end;

    local procedure ValidateTotalSettlement(BillGroupNo: Code[20]; NoOfClosedCarteraDoc: Integer)
    var
        ClosedBillGroup: Record "Closed Bill Group";
        ClosedCarteraDoc: Record "Closed Cartera Doc.";
    begin
        ClosedBillGroup.SetFilter("No.", BillGroupNo);
        ClosedBillGroup.FindFirst();

        ClosedCarteraDoc.SetFilter("Bill Gr./Pmt. Order No.", BillGroupNo);
        ClosedCarteraDoc.FindFirst();
        Assert.AreEqual(NoOfClosedCarteraDoc, ClosedCarteraDoc.Count, UnexpectedNoOfRecordsErr);
    end;

    local procedure ValidateSettlementLedgerEntries(CustomerNo: Code[20]; DocumentNo: Code[20]; BillGroupNo: Code[20]; InitialAmount: Decimal; SettledAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        // Find Cartera Payment GL Entries
        LibraryCarteraReceivables.FindCarteraGLEntries(GLEntry, BillGroupNo, GLEntry."Document Type"::Payment);
        // -- Validate
        Assert.AreEqual(SettledAmount, GLEntry."Credit Amount", UnexpectedAmountErr);
        GLEntry.Next();
        Assert.AreEqual(SettledAmount, GLEntry."Debit Amount", UnexpectedAmountErr);

        ValidateLedgerEntries(CustomerNo, DocumentNo, BillGroupNo, InitialAmount, SettledAmount, DetailedCustLedgEntry."Document Type"::Bill);
    end;

    local procedure ValidateSettlementUnrealizedVATLedgerEntries(CustomerNo: Code[20]; DocumentNo: Code[20]; BillGroupNo: Code[20]; InitialAmount: Decimal; SettledAmount: Decimal)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GLEntry: Record "G/L Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        ExpectedVATAmount: Decimal;
    begin
        // Find VAT Posting Setup
        LibraryCarteraReceivables.FindCarteraGLEntries(GLEntry, DocumentNo, GLEntry."Document Type"::Invoice);
        VATPostingSetup.Get(GLEntry."VAT Bus. Posting Group", GLEntry."VAT Prod. Posting Group");
        ExpectedVATAmount := Round(InitialAmount - InitialAmount * 100 / (VATPostingSetup."VAT %" + 100),
            LibraryERM.GetAmountRoundingPrecision());

        // Find Cartera Payment GL Entries
        GLEntry.Reset();
        GLEntry.SetFilter(Amount, '<>0');
        LibraryCarteraReceivables.FindCarteraGLEntries(GLEntry, BillGroupNo, GLEntry."Document Type"::Payment);
        Assert.AreEqual(SettledAmount, GLEntry."Credit Amount", UnexpectedAmountErr);
        GLEntry.Next();
        Assert.AreEqual(ExpectedVATAmount, GLEntry."Debit Amount", UnexpectedAmountErr);

        ValidateLedgerEntries(CustomerNo, DocumentNo, BillGroupNo, InitialAmount, SettledAmount, DetailedCustLedgEntry."Document Type"::Bill);
    end;

    local procedure ValidateSettlementUnrealizedVATWithRiskLedgerEntries(CustomerNo: Code[20]; DocumentNo: Code[20]; BillGroupNo: Code[20]; InitialAmount: Decimal; SettledAmount: Decimal; CustomerRatingRiskPercentage: Decimal)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GLEntry: Record "G/L Entry";
        GLSetup: Record "General Ledger Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        ExpectedVATAmount: Decimal;
    begin
        GLSetup.Get();
        // Find VAT Posting Setup
        LibraryCarteraReceivables.FindCarteraGLEntries(GLEntry, DocumentNo, GLEntry."Document Type"::Invoice);
        VATPostingSetup.Get(GLEntry."VAT Bus. Posting Group", GLEntry."VAT Prod. Posting Group");
        ExpectedVATAmount := Round(InitialAmount - InitialAmount * 100 / (VATPostingSetup."VAT %" + 100),
            LibraryERM.GetAmountRoundingPrecision());

        // Find Cartera Payment GL Entries
        GLEntry.Reset();
        LibraryCarteraReceivables.FindCarteraGLEntries(GLEntry, BillGroupNo, GLEntry."Document Type"::Payment);
        Assert.AreNearlyEqual(ExpectedVATAmount, GLEntry."Debit Amount", GLSetup."Amount Rounding Precision", UnexpectedAmountErr);
        GLEntry.Next();
        Assert.AreNearlyEqual(ExpectedVATAmount, GLEntry."Credit Amount", GLSetup."Amount Rounding Precision", UnexpectedAmountErr);
        GLEntry.Next();
        Assert.AreNearlyEqual(InitialAmount, GLEntry."Credit Amount", GLSetup."Amount Rounding Precision", UnexpectedAmountErr);
        GLEntry.Next();
        Assert.AreNearlyEqual(Round(SettledAmount * CustomerRatingRiskPercentage / 100, LibraryERM.GetAmountRoundingPrecision()),
          GLEntry."Debit Amount", GLSetup."Amount Rounding Precision", UnexpectedAmountErr);

        ValidateLedgerEntries(CustomerNo, DocumentNo, BillGroupNo,
          InitialAmount, SettledAmount, DetailedCustLedgEntry."Document Type"::Invoice);
    end;

    local procedure ValidateLedgerEntries(CustomerNo: Code[20]; DocumentNo: Code[20]; BillGroupNo: Code[20]; InitialAmount: Decimal; SettledAmount: Decimal; CustLedgEntryDocumentType: Enum "Gen. Journal Document Type")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GLSetup: Record "General Ledger Setup";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        GLSetup.Get();

        if InitialAmount <> SettledAmount then begin
            // Find Cartera Customer Ledger Entries for posted bill
            LibraryCarteraReceivables.FindCarteraDocCustomerLedgerEntry(CustLedgerEntry, CustomerNo, DocumentNo,
              CustLedgerEntry."Document Situation"::"Posted BG/PO", CustLedgEntryDocumentType);
            // -- Validate
            Assert.AreEqual(CustLedgerEntry."Document Status"::Open, CustLedgerEntry."Document Status", UnexpectedDocStatusErr);
            Assert.AreEqual(InitialAmount, CustLedgerEntry."Amount (LCY) stats.", UnexpectedAmountErr);
            Assert.AreNearlyEqual(InitialAmount - SettledAmount, CustLedgerEntry."Remaining Amount (LCY) stats.",
              GLSetup."Amount Rounding Precision", UnexpectedAmountErr);
        end;

        // Find Cartera Customer Ledger Entries for paid bill
        LibraryCarteraReceivables.FindCarteraDocCustomerLedgerEntry(CustLedgerEntry, CustomerNo, BillGroupNo,
          CustLedgerEntry."Document Situation"::" ", CustLedgerEntry."Document Type"::Payment);
        // -- Validate
        Assert.AreEqual(-SettledAmount, CustLedgerEntry."Amount (LCY) stats.", UnexpectedAmountErr);
        Assert.AreEqual(0, CustLedgerEntry."Remaining Amount", UnexpectedAmountErr);

        // Find Detailed Customer Ledger Entry for Bill - Initial Entry
        LibraryCarteraReceivables.FindDetailedCustomerLedgerEntry(DetailedCustLedgEntry, CustomerNo, DocumentNo,
          DetailedCustLedgEntry."Entry Type"::"Initial Entry", CustLedgEntryDocumentType);
        // -- Validate
        Assert.AreEqual(InitialAmount, DetailedCustLedgEntry.Amount, UnexpectedAmountErr);

        // Find Detailed Customer Ledger Entry for applying the payment to the bill
        LibraryCarteraReceivables.FindDetailedCustomerLedgerEntry(DetailedCustLedgEntry, CustomerNo, BillGroupNo,
          DetailedCustLedgEntry."Entry Type"::Application, DetailedCustLedgEntry."Document Type"::Payment);
        // -- Validate
        Assert.AreEqual(-SettledAmount, DetailedCustLedgEntry.Amount, UnexpectedAmountErr);
    end;

    local procedure ValidatePartialSettlementPostedDocuments(DocumentNo: Code[20]; InitialAmount: Decimal; SettledAmount: Decimal)
    var
        PostedCarteraDoc: Record "Posted Cartera Doc.";
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();

        PostedCarteraDoc.SetRange("Document No.", DocumentNo);
        PostedCarteraDoc.FindFirst();
        Assert.AreEqual(PostedCarteraDoc.Status::Open, PostedCarteraDoc.Status, UnexpectedCarteraDocStatusErr);
        Assert.AreEqual(InitialAmount, PostedCarteraDoc."Amount for Collection", UnexpectedAmountErr);
        Assert.AreNearlyEqual(InitialAmount - SettledAmount, PostedCarteraDoc."Remaining Amount",
          GLSetup."Amount Rounding Precision", UnexpectedAmountErr);
    end;

    local procedure ValidateTotalSettlementClosedDocuments(DocumentNo: Code[20]; TotalAmount: Decimal)
    var
        ClosedCarteraDoc: Record "Closed Cartera Doc.";
    begin
        ClosedCarteraDoc.SetRange("Document No.", DocumentNo);
        ClosedCarteraDoc.FindFirst();
        Assert.AreEqual(ClosedCarteraDoc.Status::Honored, ClosedCarteraDoc.Status, UnexpectedCarteraDocStatusErr);
        Assert.AreEqual(TotalAmount, ClosedCarteraDoc."Amount for Collection", UnexpectedAmountErr);
        Assert.AreEqual(0, ClosedCarteraDoc."Remaining Amount", UnexpectedAmountErr);
    end;

    local procedure ValidateUnrealizedVATRedraw(BillGroupNo: Code[20])
    var
        ClosedBillGroup: Record "Closed Bill Group";
        ClosedBillGroups: TestPage "Closed Bill Groups";
    begin
        Commit();
        ClosedBillGroup.SetRange("No.", BillGroupNo);
        ClosedBillGroup.FindFirst();
        ClosedBillGroups.OpenEdit();
        ClosedBillGroups.GotoRecord(ClosedBillGroup);

        LibraryVariableStorage.Enqueue(ClosedBillGroups.Docs."Due Date".AsDate());
        asserterror ClosedBillGroups.Docs.Redraw.Invoke();
        Assert.ExpectedError(BillContainsUnrealizedVATErr);

        ClosedBillGroups.Close();
    end;

    local procedure CreateAndPostBillGroup(CustomerNo: Code[20]; BankAccountNo: Code[20]; var BillGroup: Record "Bill Group"): Code[20]
    var
        SalesHeader: Record "Sales Header";
        CarteraDoc: Record "Cartera Doc.";
        DocumentNo: Code[20];
    begin
        LibraryCarteraReceivables.CreateSalesInvoice(SalesHeader, CustomerNo);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        LibraryCarteraReceivables.CreateBillGroup(BillGroup, BankAccountNo, BillGroup."Dealing Type"::Collection);
        LibraryCarteraReceivables.AddCarteraDocumentToBillGroup(CarteraDoc, DocumentNo, CustomerNo, BillGroup."No.");

        PostBillGroupWithTypeCollection(BillGroup);

        exit(DocumentNo);
    end;

    local procedure CreateAndPostBillGroupWithDiscount(CustomerNo: Code[20]; BankAccountNo: Code[20]; var BillGroup: Record "Bill Group") DocumentNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
        CarteraDoc: Record "Cartera Doc.";
    begin
        LibraryCarteraReceivables.CreateSalesInvoice(SalesHeader, CustomerNo);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        LibraryCarteraReceivables.CreateBillGroup(BillGroup, BankAccountNo, BillGroup."Dealing Type"::Discount);
        LibraryCarteraReceivables.AddCarteraDocumentToBillGroup(CarteraDoc, DocumentNo, CustomerNo, BillGroup."No.");
        CarteraDoc.ModifyAll("Due Date", CalcDate('<1M>', CarteraDoc."Posting Date"));

        PostBillGroupsWithDiscountForCustomer(BillGroup);
    end;

    local procedure CreateAndPostInstallmentsBillGroupsWithDiscount(CustomerNo: Code[20]; BankAccountNo: Code[20]; NoOfInstallments: Integer; var BillGroup: Record "Bill Group") DocumentNo: Code[20]
    var
        PaymentTerms: Record "Payment Terms";
        SalesHeader: Record "Sales Header";
        CarteraDoc: Record "Cartera Doc.";
    begin
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, true);
        LibraryCarteraReceivables.CreateMultipleInstallments(PaymentTerms.Code, NoOfInstallments);

        LibraryCarteraReceivables.CreateSalesInvoice(SalesHeader, CustomerNo);
        SalesHeader.Validate("Payment Terms Code", PaymentTerms.Code);
        SalesHeader.Modify(true);

        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        LibraryCarteraReceivables.CreateBillGroup(BillGroup, BankAccountNo, BillGroup."Dealing Type"::Discount);

        LibraryCarteraReceivables.AddInstallmentCarteraDocumentsToBillGroup(CarteraDoc, DocumentNo, CustomerNo, BillGroup."No.");
        CarteraDoc.ModifyAll("Due Date", CalcDate('<1M>', CarteraDoc."Posting Date"));

        PostBillGroupsWithDiscountForCustomer(BillGroup);
    end;

    local procedure CreateAndPostFactoringBillGroupsWithDiscount(CustomerNo: Code[20]; BankAccountNo: Code[20]; var BillGroup: Record "Bill Group") DocumentNo: Code[20]
    var
        CarteraDoc: Record "Cartera Doc.";
    begin
        DocumentNo := CreatePostSalesInvoice(CustomerNo);
        CreateBillGroup(BillGroup, BankAccountNo, BillGroup."Dealing Type"::Discount, BillGroup.Factoring::Risked);

        LibraryCarteraReceivables.AddCarteraDocumentToBillGroup(CarteraDoc, DocumentNo, CustomerNo, BillGroup."No.");
        CarteraDoc.ModifyAll("Due Date", CalcDate('<1M>', CarteraDoc."Posting Date"));

        PostBillGroupsWithDiscountForCustomer(BillGroup);
    end;

    local procedure CreateAndPostFactoringBillGroupsWithDiscountOnDate(CustomerNo: Code[20]; BankAccountNo: Code[20]; var BillGroup: Record "Bill Group"; BillGroupPostingDate: Date) DocumentNo: Code[20]
    var
        CarteraDoc: Record "Cartera Doc.";
    begin
        DocumentNo := CreatePostSalesInvoice(CustomerNo);
        CreateBillGroupFCY(BillGroup, BankAccountNo, BillGroupPostingDate, BillGroup."Dealing Type"::Discount, BillGroup.Factoring::Risked);

        LibraryCarteraReceivables.AddCarteraDocumentToBillGroup(CarteraDoc, DocumentNo, CustomerNo, BillGroup."No.");
        CarteraDoc.ModifyAll("Due Date", CalcDate('<1M>', CarteraDoc."Posting Date"));

        PostBillGroupsWithDiscountForCustomer(BillGroup);
    end;

    local procedure CreateAndPostFactoringBillGroupsWithCollection(CustomerNo: Code[20]; BankAccountNo: Code[20]; var BillGroup: Record "Bill Group") DocumentNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
        PaymentMethod: Record "Payment Method";
        CarteraDoc: Record "Cartera Doc.";
        BGPostAndPrint: Codeunit "BG/PO-Post and Print";
    begin
        LibraryCarteraReceivables.CreateFactoringPaymentMethod(PaymentMethod);

        LibraryCarteraReceivables.CreateSalesInvoice(SalesHeader, CustomerNo);
        SalesHeader.Validate("Payment Method Code", PaymentMethod.Code);
        SalesHeader.Modify(true);

        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        CreateBillGroup(BillGroup, BankAccountNo, BillGroup."Dealing Type"::Collection, BillGroup.Factoring::Risked);
        LibraryCarteraReceivables.AddCarteraDocumentToBillGroup(CarteraDoc, DocumentNo, CustomerNo, BillGroup."No.");

        LibraryVariableStorage.Enqueue(StrSubstNo(BillGroupNotPrintedMsg, BillGroup.TableCaption()));
        LibraryVariableStorage.Enqueue(StrSubstNo(BankFactoringBillGroupPostedForCollectionMsg, BillGroup."No."));
        BGPostAndPrint.ReceivablePostOnly(BillGroup);
    end;

    local procedure CreateAndPostBillGroupsWithUnrealizedVAT(PaymentMethodCode: Code[10]; PaymentTermsCode: Code[10]; CustomerNo: Code[20]; BankAccountNo: Code[20]; var BillGroup: Record "Bill Group") DocumentNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PaymentMethod: Record "Payment Method";
        PaymentTerms: Record "Payment Terms";
        CarteraDoc: Record "Cartera Doc.";
        BGPostAndPrint: Codeunit "BG/PO-Post and Print";
    begin
        // Payment Method for Bills with Unrealized VAT
        PaymentMethod.Get(PaymentMethodCode);
        LibraryCarteraReceivables.UpdatePaymentMethodForBillsWithUnrealizedVAT(PaymentMethod);

        LibraryCarteraReceivables.SetPaymentTermsVatDistribution(PaymentTermsCode,
          PaymentTerms."VAT distribution"::Proportional);

        LibraryCarteraReceivables.CreateSalesInvoice(SalesHeader, CustomerNo);

        // No extra Line Discounts per sold items
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.ModifyAll(SalesLine."Line Discount %", 0, true);
        SalesLine.ModifyAll(SalesLine."Line Discount Amount", 0, true);

        // Exercise
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        LibraryCarteraReceivables.CreateBillGroup(BillGroup, BankAccountNo, BillGroup."Dealing Type"::Collection);
        LibraryCarteraReceivables.AddCarteraDocumentToBillGroup(CarteraDoc, DocumentNo, CustomerNo, BillGroup."No.");

        LibraryVariableStorage.Enqueue(StrSubstNo(BillGroupNotPrintedMsg, BillGroup.TableCaption()));
        BGPostAndPrint.ReceivablePostOnly(BillGroup);
    end;

    local procedure CreateAndPostBillGroupWithDiscountAndUnrealizedVAT(PaymentMethodCode: Code[10]; PaymentTermsCode: Code[10]; CustomerNo: Code[20]; BankAccountNo: Code[20]; var BillGroup: Record "Bill Group") DocumentNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
        PaymentMethod: Record "Payment Method";
        CarteraDoc: Record "Cartera Doc.";
        PaymentTerms: Record "Payment Terms";
        SalesLine: Record "Sales Line";
    begin
        // Payment Method for Bills with Unrealized VAT
        PaymentMethod.Get(PaymentMethodCode);
        LibraryCarteraReceivables.UpdatePaymentMethodForBillsWithUnrealizedVAT(PaymentMethod);

        LibraryCarteraReceivables.SetPaymentTermsVatDistribution(PaymentTermsCode,
          PaymentTerms."VAT distribution"::Proportional);

        LibraryCarteraReceivables.CreateSalesInvoice(SalesHeader, CustomerNo);

        // No extra Line Discounts per sold items
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.ModifyAll(SalesLine."Line Discount %", 0, true);
        SalesLine.ModifyAll(SalesLine."Line Discount Amount", 0, true);

        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        LibraryCarteraReceivables.CreateBillGroup(BillGroup, BankAccountNo, BillGroup."Dealing Type"::Discount);

        LibraryCarteraReceivables.AddCarteraDocumentToBillGroup(CarteraDoc, DocumentNo, CustomerNo, BillGroup."No.");
        CarteraDoc.ModifyAll("Due Date", CalcDate('<1M>', CarteraDoc."Posting Date"));

        PostBillGroupsWithDiscountForCustomer(BillGroup);
    end;

    local procedure CreateAndPostInvoiceBillGroupsWithFactoringAndUnrealizedVAT(PaymentMethodCode: Code[10]; PaymentTermsCode: Code[10]; CustomerNo: Code[20]; BankAccountNo: Code[20]; var BillGroup: Record "Bill Group") DocumentNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PaymentTerms: Record "Payment Terms";
        CarteraDoc: Record "Cartera Doc.";
        BGPostAndPrint: Codeunit "BG/PO-Post and Print";
    begin
        // Payment Method for Invoices
        LibraryCarteraReceivables.UpdatePaymentMethodForInvoicesWithUnrealizedVAT(PaymentMethodCode);
        // Payment Terms setting VAT distribution
        LibraryCarteraReceivables.SetPaymentTermsVatDistribution(PaymentTermsCode,
          PaymentTerms."VAT distribution"::Proportional);

        LibraryCarteraReceivables.CreateSalesInvoice(SalesHeader, CustomerNo);

        // No extra Line Discounts per sold items
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.ModifyAll(SalesLine."Line Discount %", 0, true);
        SalesLine.ModifyAll(SalesLine."Line Discount Amount", 0, true);

        // Exercise
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Factoring Bill Group
        CreateBillGroup(BillGroup, BankAccountNo, BillGroup."Dealing Type"::Collection, BillGroup.Factoring::Risked);
        LibraryCarteraReceivables.AddCarteraDocumentToBillGroup(CarteraDoc, DocumentNo, CustomerNo, BillGroup."No.");

        LibraryVariableStorage.Enqueue(StrSubstNo(BillGroupNotPrintedMsg, BillGroup.TableCaption()));
        LibraryVariableStorage.Enqueue(StrSubstNo(BankFactoringBillGroupPostedForCollectionMsg, BillGroup."No."));
        BGPostAndPrint.ReceivablePostOnly(BillGroup);
    end;

    local procedure CreateAndPostInvoiceBillGroupsWithFactoringUnrealizedVATAndDiscount(CustomerNo: Code[20]; BankAccountNo: Code[20]; var BillGroup: Record "Bill Group") DocumentNo: Code[20]
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PaymentMethod: Record "Payment Method";
        PaymentTerms: Record "Payment Terms";
        CarteraDoc: Record "Cartera Doc.";
    begin
        // Payment Method for Invoices
        LibraryCarteraReceivables.CreateFactoringPaymentMethod(PaymentMethod);
        Customer.Get(CustomerNo);
        Customer.Validate("Payment Method Code", PaymentMethod.Code);
        Customer.Modify(true);

        // Payment Terms setting VAT distribution
        LibraryCarteraReceivables.SetPaymentTermsVatDistribution(Customer."Payment Terms Code",
          PaymentTerms."VAT distribution"::Proportional);

        LibraryCarteraReceivables.CreateSalesInvoice(SalesHeader, Customer."No.");

        // No extra Line Discounts per sold items
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.ModifyAll(SalesLine."Line Discount %", 0, true);
        SalesLine.ModifyAll(SalesLine."Line Discount Amount", 0, true);

        // Exercise
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        CreateBillGroup(BillGroup, BankAccountNo, BillGroup."Dealing Type"::Discount, BillGroup.Factoring::Risked);
        LibraryCarteraReceivables.AddCarteraDocumentToBillGroup(CarteraDoc, DocumentNo, Customer."No.", BillGroup."No.");

        PostBillGroupsWithDiscountForCustomer(BillGroup);
    end;

    local procedure CreateAndPostServiceInvoice(Customer: Record Customer) DocumentNo: Code[20]
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        LibraryCarteraReceivables.CreateServiceInvoice(ServiceHeader, Customer."No.");

        // Exercise
        LibraryService.PostServiceOrder(ServiceHeader, false, false, false);
        ServiceInvoiceHeader.SetRange("Customer No.", Customer."No.");
        ServiceInvoiceHeader.FindFirst();
        DocumentNo := ServiceInvoiceHeader."No.";
    end;

    local procedure CreatePostSalesInvoice(CustomerNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PaymentMethod: Record "Payment Method";
    begin
        LibraryCarteraReceivables.CreateFactoringPaymentMethod(PaymentMethod);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesHeader.Validate("Payment Method Code", PaymentMethod.Code);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateBillGroupWithPageTestability(var BillGroup: Record "Bill Group"; BankAccountNo: Code[20]; DocumentNo: Code[20]; BillGroupDealingType: Enum "Cartera Dealing Type"; Factoring: Option)
    var
        CarteraDoc: Record "Cartera Doc.";
        BillGroupsTestPage: TestPage "Bill Groups";
    begin
        // Open Bill Groups page
        BillGroupsTestPage.OpenNew();

        BillGroupsTestPage."No.".AssistEdit();

        LibraryVariableStorage.Enqueue(BankAccountNo);
        BillGroupsTestPage."Bank Account No.".Lookup();

        BillGroupsTestPage."Dealing Type".SetValue(BillGroupDealingType);
        BillGroupsTestPage.Factoring.SetValue(Factoring);

        LibraryVariableStorage.Enqueue(DocumentNo);
        BillGroupsTestPage.Docs.Insert.Invoke();

        // Bill Group including the Cartera Document
        CarteraDoc.SetRange("Document No.", DocumentNo);
        CarteraDoc.FindFirst();
        BillGroup.Get(CarteraDoc."Bill Gr./Pmt. Order No.");

        LibraryVariableStorage.Enqueue(StrSubstNo(BillGroupNotPrintedMsg, BillGroup.TableCaption()));
        LibraryVariableStorage.Enqueue(StrSubstNo(BankFactoringBillGroupPostedForCollectionMsg, BillGroup."No."));

        // Post the bill group
        BillGroupsTestPage.Post.Invoke();
    end;

    local procedure CreateCurrencyWithSevExchRates(var StartingDate: array[4] of Date; ExchRate: array[4] of Decimal; BillGroupsDiscount: Boolean): Code[10]
    var
        Currency: Record Currency;
        i: Integer;
    begin
        Currency.Get(LibraryERM.CreateCurrencyWithGLAccountSetup());
        Currency.Validate("Bill Groups - Discount", BillGroupsDiscount);
        Currency.Modify(true);
        StartingDate[1] := WorkDate();
        LibraryERM.CreateExchangeRate(Currency.Code, StartingDate[1], ExchRate[1], ExchRate[1]);
        for i := 2 to ArrayLen(ExchRate) do begin
            StartingDate[i] := CalcDate(StrSubstNo('<%1M>', i - 1), StartingDate[i - 1]);
            LibraryERM.CreateExchangeRate(Currency.Code, StartingDate[i], ExchRate[i], ExchRate[i]);
        end;
        exit(Currency.Code);
    end;

    local procedure CreateBillGroup(var BillGroup: Record "Bill Group"; BankAccountNo: Code[20]; DealingType: Enum "Cartera Dealing Type"; Factoring: Option)
    begin
        LibraryCarteraReceivables.CreateBillGroup(BillGroup, BankAccountNo, DealingType);
        BillGroup.Validate(Factoring, Factoring);
        BillGroup.Modify(true);
    end;

    local procedure CreateBillGroupFCY(var BillGroup: Record "Bill Group"; BankAccountNo: Code[20]; PostingDate: Date; DealingType: Enum "Cartera Dealing Type"; Factoring: Option)
    begin
        BillGroup.Init();
        BillGroup.Insert(true);
        BillGroup.Validate("Posting Date", PostingDate);
        BillGroup.Validate("Dealing Type", DealingType);
        BillGroup.Validate("Bank Account No.", BankAccountNo);
        BillGroup.Validate(Factoring, Factoring);
        BillGroup.Modify(true);
    end;

    local procedure CreateVATPostingSetupVATCashRegime(var VATPostingSetup: Record "VAT Posting Setup"; VATBusinessPostingGroupCode: Code[20]; VATPercent: Decimal)
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroupCode, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("VAT %", VATPercent);
        VATPostingSetup.Validate("VAT Identifier", LibraryUtility.GenerateGUID());
        VATPostingSetup.Validate("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::Percentage);
        VATPostingSetup.Validate("VAT Cash Regime", true);
        VATPostingSetup.Validate("Sales VAT Unreal. Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Sales VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);
    end;

    local procedure GetCarteraTemplBatch(var TemplateName: Code[10]; var BatchName: Code[10])
    var
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        GenJnlTemplate.SetRange(Type, GenJnlTemplate.Type::Cartera);
        GenJnlTemplate.SetRange(Recurring, false);
        GenJnlTemplate.FindFirst();

        GenJnlBatch.SetRange("Journal Template Name", GenJnlTemplate.Name);
        GenJnlBatch.FindFirst();

        TemplateName := GenJnlTemplate.Name;
        BatchName := GenJnlBatch.Name;
    end;

    local procedure PostBillGroupWithTypeCollection(BillGroup: Record "Bill Group")
    var
        BGPostAndPrint: Codeunit "BG/PO-Post and Print";
    begin
        LibraryVariableStorage.Enqueue(StrSubstNo(BillGroupNotPrintedMsg, BillGroup.TableCaption()));
        BGPostAndPrint.ReceivablePostOnly(BillGroup);
    end;

    local procedure PostBillGroupsWithDiscountForCustomer(var BillGroup: Record "Bill Group")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        BGPostAndPrint: Codeunit "BG/PO-Post and Print";
    begin
        LibraryCarteraReceivables.CreateCarteraJournalBatch(GenJournalBatch);

        LibraryVariableStorage.Enqueue(StrSubstNo(BillGroupNotPrintedMsg, BillGroup.TableCaption()));
        LibraryVariableStorage.Enqueue(GenJournalBatch."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalBatch.Name);
        LibraryVariableStorage.Enqueue(StrSubstNo(BankBillGroupPostedForDiscountMsg, BillGroup."No."));
        Commit();
        BGPostAndPrint.ReceivablePostOnly(BillGroup);

        LibraryVariableStorage.Enqueue(ConfirmPostingJournalLinesMsg);
        LibraryCarteraReceivables.PrepareCarteraDiscountJournalLines(GenJournalBatch);

        LibraryVariableStorage.Enqueue(SuccessfullyPostedJournalLinesMsg);
        LibraryCarteraReceivables.PostCarteraJournalLines(GenJournalBatch.Name);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);
        Assert.AreEqual(Format(ExpectedMessage), Question, UnexpectedMessageErr);
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CheckDiscountCreditLimitModalPageHandler(var CheckDiscountCreditLimit: TestPage "Check Discount Credit Limit")
    begin
        CheckDiscountCreditLimit.Yes().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PostBillGroupRequestPageHandler(var PostBillGroup: TestRequestPage "Post Bill Group")
    var
        BatchName: Variant;
        TemplateName: Variant;
    begin
        LibraryVariableStorage.Dequeue(TemplateName);
        LibraryVariableStorage.Dequeue(BatchName);
        PostBillGroup.TemplName.SetValue(TemplateName);
        PostBillGroup.BatchName.SetValue(BatchName);
        PostBillGroup.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CarteraJournalModalPageHandler(var CarteraJournal: Page "Cartera Journal"; var Response: Action)
    begin
        CarteraJournal.AllowClosing(true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure NoSeriesListModalPageHandler(var NoSeriesList: Page "No. Series"; var Response: Action)
    begin
        Response := ACTION::LookupOK;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure BankAccountSelectionModalPageHandler(var BankAccountSelection: Page "Bank Account Selection"; var Response: Action)
    var
        BankAccount: Record "Bank Account";
        BankAccountNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(BankAccountNo);

        BankAccount.Get(BankAccountNo);
        BankAccountSelection.SetRecord(BankAccount);

        Response := ACTION::LookupOK;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CarteraDocumentsModalPageHandler(var CarteraDocuments: Page "Cartera Documents"; var Response: Action)
    var
        CarteraDoc: Record "Cartera Doc.";
        DocumentNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNo);

        CarteraDoc.SetRange("Document No.", DocumentNo);
        CarteraDoc.FindLast();
        CarteraDocuments.SetRecord(CarteraDoc);

        Response := ACTION::LookupOK;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure BillGroupDiscountPostedMessageHandler(Message: Text[1024])
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);
        Assert.AreEqual(Format(ExpectedMessage), Message, UnexpectedMessageErr);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BatchSettlPostedBillGrsRequestPageHandler(var BatchSettlPostedBillGrs: TestRequestPage "Batch Settl. Posted Bill Grs.")
    begin
        BatchSettlPostedBillGrs.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PartialSettlReceivableRequestPageHandler(var PartialSettlReceivableReqPage: TestRequestPage "Partial Settl.- Receivable")
    var
        SettledAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(SettledAmount);

        PartialSettlReceivableReqPage.SettledAmount.SetValue(SettledAmount);
        PartialSettlReceivableReqPage.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SettlDocsPostedBillGroupsRequestPageHandler(var SettleDocsinPostBillGr: TestRequestPage "Settle Docs. in Post. Bill Gr.")
    begin
        SettleDocsinPostBillGr.PostingDate.SetValue(LibraryVariableStorage.DequeueDate());
        SettleDocsinPostBillGr.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RedrawReceivableBillsRequestPageHandler(var RedrawReceivableBillsRequestPage: TestRequestPage "Redraw Receivable Bills")
    var
        ClosedBillDueDate: Variant;
        TemplateName: Code[10];
        BatchName: Code[10];
    begin
        LibraryVariableStorage.Dequeue(ClosedBillDueDate);

        RedrawReceivableBillsRequestPage.NewDueDate.SetValue(CalcDate('<1D>', ClosedBillDueDate));
        RedrawReceivableBillsRequestPage.NewPmtMethod.SetValue('');
        RedrawReceivableBillsRequestPage.FinanceCharges.SetValue(false);
        RedrawReceivableBillsRequestPage.DiscCollExpenses.SetValue(false);
        RedrawReceivableBillsRequestPage.RejectionExpenses.SetValue(false);

        GetCarteraTemplBatch(TemplateName, BatchName);
        RedrawReceivableBillsRequestPage.AuxJnlTemplateName.SetValue(TemplateName);
        RedrawReceivableBillsRequestPage.AuxJnlBatchName.SetValue(BatchName);
        RedrawReceivableBillsRequestPage.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure OpenBankCatPostRecBillsMatrix(var BankCatPostRecBillsMatrix: TestPage "Bank Cat.Post.Rec.Bills Matrix")
    begin
        BankCatPostRecBillsMatrix.Filter.SetFilter("No.", LibraryVariableStorage.DequeueText());
        BankCatPostRecBillsMatrix.Field1.Drilldown();
    end;

    [ModalPageHandler]
    procedure OpenPostedBills(var PostedBills: TestPage "Posted Bills")
    begin
        Assert.AreEqual(PostedBills."Bank Account No.".Value(), LibraryVariableStorage.DequeueText(), '');
    end;
}

