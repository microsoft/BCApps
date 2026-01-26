codeunit 147543 "Cartera Recv. Rejection Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        CarteraGenJournalTemplate: Record "Gen. Journal Template";
        CarteraGenJournalBatch: Record "Gen. Journal Batch";
        Assert: Codeunit Assert;
        LibraryCarteraPayables: Codeunit "Library - Cartera Payables";
        LibraryCarteraReceivables: Codeunit "Library - Cartera Receivables";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryCarteraCommon: Codeunit "Library - Cartera Common";
        LibraryJournals: Codeunit "Library - Journals";
        IsInitialized: Boolean;
        ConfirmPostingJournalLinesMsg: Label 'Do you want to post the journal lines?';
        BillGroupNotPrintedMsg: Label 'This Bill Group has not been printed. Do you want to continue?';
        BankBillGroupPostedForDiscountMsg: Label 'Bank Bill Group %1 was successfully posted for discount.';
        SuccessfullyPostedJournalLinesMsg: Label 'The journal lines were successfully posted.';
        PartialSettlementBillGroupMsg: Label '%1 receivable documents totaling %2 have been partially settled in Bill Group %3 by an amount of %4.';
        NotRejection: Boolean;
        Rejection: Boolean;
        WithoutUnrealizedVAT: Boolean;
        WithUnrealizedVAT: Boolean;
        OneDocumentRejectedMsg: Label '1 documents have been rejected.';
        PostJnlLinesMsg: Label 'Do you want to post the journal lines?';
        JnlLinesPostedMsg: Label 'The journal lines were successfully posted.';
        DealingTypeDiscount: Boolean;
        DealingTypeCollection: Boolean;
        LocalCurrencyCode: Code[10];
        UnexpectedMessageErr: Label 'Unexpected Message.';

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,BillGroupDiscountPostedMessageHandler,PartialSettlReceivableRequestPageHandler,RejectCarteraDocRequestPageHandler,CarteraJournalModalPageHandler')]
    [Scope('OnPrem')]
    procedure RejectionOfPartiallySettledBillGroupDealingTypeCollection()
    var
        BankAccount: Record "Bank Account";
        BillGroup: Record "Bill Group";
        Customer: Record Customer;
        DocumentNo: Code[20];
        RejectionFeeAmount: Decimal;
        RemainingAmount: Decimal;
        ExpectedVATAmount: Decimal;
    begin
        Initialize();

        // Setup
        RejectionTestsSetup(BankAccount, Customer);
        DocumentNo := CreateAndPostBillGroup(Customer."No.", BankAccount."No.", BillGroup, RemainingAmount);
        InvokePartialSettlementOnBillGroup(Customer."No.", DocumentNo, BillGroup."No.", RemainingAmount, ExpectedVATAmount);
        RejectionFeeAmount := CalculateRejectionFeeAmount(BillGroup, RemainingAmount);

        // Exercise
        InvokeRejectOnBillGroup(BillGroup, RemainingAmount, RejectionFeeAmount, WithoutUnrealizedVAT, 0, DealingTypeCollection, 0);

        VerifyRejectedBillGroupVATGLEntries(RemainingAmount, RejectionFeeAmount, WithoutUnrealizedVAT, 0, DealingTypeCollection, 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,BillGroupDiscountPostedMessageHandler,PartialSettlReceivableRequestPageHandler,CheckDiscountCreditLimitModalPageHandler,PostBillGroupRequestPageHandler,CarteraJournalModalPageHandler,RejectCarteraDocRequestPageHandler')]
    [Scope('OnPrem')]
    procedure RejectionOfPartiallySettledBillGroupDealingTypeDiscount()
    var
        BankAccount: Record "Bank Account";
        BillGroup: Record "Bill Group";
        Customer: Record Customer;
        CustomerRating: Record "Customer Rating";
        DocumentNo: Code[20];
        RemainingAmount: Decimal;
        RejectionFeeAmount: Decimal;
        ExpectedVATAmount: Decimal;
    begin
        Initialize();

        // Pre-Setup
        RejectionTestsSetup(BankAccount, Customer);
        LibraryCarteraReceivables.CreateCustomerRatingForBank(CustomerRating, BankAccount."No.", LocalCurrencyCode, Customer."No.");

        LibraryCarteraReceivables.CreateDiscountOperationFeesForBankAccount(BankAccount);
        DocumentNo := CreateAndPostBillGroupWithDiscount(Customer."No.", BankAccount."No.", BillGroup, RemainingAmount);
        InvokePartialSettlementOnBillGroup(Customer."No.", DocumentNo, BillGroup."No.", RemainingAmount, ExpectedVATAmount);
        RejectionFeeAmount := CalculateRejectionFeeAmount(BillGroup, RemainingAmount);

        // Exercise
        InvokeRejectOnBillGroup(BillGroup, RemainingAmount, RejectionFeeAmount, WithoutUnrealizedVAT, 0, DealingTypeDiscount, RemainingAmount);

        VerifyRejectedBillGroupVATGLEntries(
          RemainingAmount, RejectionFeeAmount, WithoutUnrealizedVAT, 0, DealingTypeDiscount, RemainingAmount);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,BillGroupDiscountPostedMessageHandler,PartialSettlReceivableRequestPageHandler,RejectCarteraDocRequestPageHandler,CarteraJournalModalPageHandler')]
    [Scope('OnPrem')]
    procedure RejectionOfPartiallySettledBillGroupUnrealizedVAT()
    var
        BankAccount: Record "Bank Account";
        BillGroup: Record "Bill Group";
        Customer: Record Customer;
        DocumentNo: Code[20];
        RemainingAmount: Decimal;
        RejectionFeeAmount: Decimal;
        ExpectedVATAmount: Decimal;
        SalesUnrVATAccount: Code[20];
        PurchUnrVATAccount: Code[20];
    begin
        Initialize();

        // Pre-Setup
        LibraryCarteraCommon.SetupUnrealizedVAT(SalesUnrVATAccount, PurchUnrVATAccount);
        RejectionTestsSetup(BankAccount, Customer);
        DocumentNo := CreateAndPostBillGroupsWithUnrealizedVAT(
            Customer."Payment Method Code",
            Customer."Payment Terms Code", Customer."No.", BankAccount."No.", BillGroup, ExpectedVATAmount, RemainingAmount);

        InvokePartialSettlementOnBillGroup(Customer."No.", DocumentNo, BillGroup."No.", RemainingAmount, ExpectedVATAmount);
        RejectionFeeAmount := CalculateRejectionFeeAmount(BillGroup, RemainingAmount);

        // Exercise
        InvokeRejectOnBillGroup(
          BillGroup, RemainingAmount, RejectionFeeAmount, WithUnrealizedVAT, ExpectedVATAmount, DealingTypeCollection, 0);

        // Verify
        VerifyRejectedBillGroupVATGLEntries(
          RemainingAmount, RejectionFeeAmount, WithUnrealizedVAT, ExpectedVATAmount, DealingTypeCollection, 0);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,BillGroupDiscountPostedMessageHandler,PartialSettlReceivableRequestPageHandler,CheckDiscountCreditLimitModalPageHandler,PostBillGroupRequestPageHandler,CarteraJournalModalPageHandler,RejectCarteraDocRequestPageHandler')]
    [Scope('OnPrem')]
    procedure RejectionOfPartiallySettledBillGroupUnrealizedVATDealingTypeDiscount()
    var
        BankAccount: Record "Bank Account";
        BillGroup: Record "Bill Group";
        Customer: Record Customer;
        DocumentNo: Code[20];
        RemainingAmount: Decimal;
        RejectionFeeAmount: Decimal;
        ExpectedVATAmount: Decimal;
        SalesUnrVATAccount: Code[20];
        PurchUnrVATAccount: Code[20];
    begin
        Initialize();

        // Pre-Setup
        LibraryCarteraCommon.SetupUnrealizedVAT(SalesUnrVATAccount, PurchUnrVATAccount);
        RejectionTestsSetup(BankAccount, Customer);
        LibraryCarteraReceivables.CreateDiscountOperationFeesForBankAccount(BankAccount);
        DocumentNo := CreateAndPostBillGroupWithDiscountAndUnrealizedVAT(Customer."Payment Method Code",
            Customer."Payment Terms Code", Customer."No.", BankAccount."No.", BillGroup, ExpectedVATAmount, RemainingAmount);
        InvokePartialSettlementOnBillGroup(Customer."No.", DocumentNo, BillGroup."No.", RemainingAmount, ExpectedVATAmount);
        RejectionFeeAmount := CalculateRejectionFeeAmount(BillGroup, RemainingAmount);

        // Exercise
        InvokeRejectOnBillGroup(
          BillGroup, RemainingAmount, RejectionFeeAmount, WithUnrealizedVAT, ExpectedVATAmount, DealingTypeDiscount, RemainingAmount);

        // Verify
        VerifyRejectedBillGroupVATGLEntries(
          RemainingAmount, RejectionFeeAmount, WithUnrealizedVAT, ExpectedVATAmount, DealingTypeDiscount, RemainingAmount);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,BillGroupDiscountPostedMessageHandler,RejectCarteraDocRequestPageHandler,CarteraJournalModalPageHandler')]
    [Scope('OnPrem')]
    procedure RejectionOfBillGroupDealingTypeCollection()
    var
        BankAccount: Record "Bank Account";
        BillGroup: Record "Bill Group";
        Customer: Record Customer;
        RejectionFeeAmount: Decimal;
        RemainingAmount: Decimal;
    begin
        Initialize();

        // Setup
        RejectionTestsSetup(BankAccount, Customer);
        CreateAndPostBillGroup(Customer."No.", BankAccount."No.", BillGroup, RemainingAmount);
        RejectionFeeAmount := CalculateRejectionFeeAmount(BillGroup, RemainingAmount);

        // Exercise
        InvokeRejectOnBillGroup(BillGroup, RemainingAmount, RejectionFeeAmount, WithoutUnrealizedVAT, 0, DealingTypeCollection, 0);

        VerifyRejectedBillGroupVATGLEntries(RemainingAmount, RejectionFeeAmount, WithoutUnrealizedVAT, 0, DealingTypeCollection, 0);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,BillGroupDiscountPostedMessageHandler,CheckDiscountCreditLimitModalPageHandler,PostBillGroupRequestPageHandler,CarteraJournalModalPageHandler,RejectCarteraDocRequestPageHandler')]
    [Scope('OnPrem')]
    procedure RejectionOfBillGroupDealingTypeDiscount()
    var
        BankAccount: Record "Bank Account";
        BillGroup: Record "Bill Group";
        Customer: Record Customer;
        CustomerRating: Record "Customer Rating";
        RemainingAmount: Decimal;
        RejectionFeeAmount: Decimal;
    begin
        Initialize();

        // Pre-Setup
        RejectionTestsSetup(BankAccount, Customer);
        LibraryCarteraReceivables.CreateCustomerRatingForBank(CustomerRating, BankAccount."No.", LocalCurrencyCode, Customer."No.");

        LibraryCarteraReceivables.CreateDiscountOperationFeesForBankAccount(BankAccount);
        CreateAndPostBillGroupWithDiscount(Customer."No.", BankAccount."No.", BillGroup, RemainingAmount);
        RejectionFeeAmount := CalculateRejectionFeeAmount(BillGroup, RemainingAmount);

        // Exercise
        InvokeRejectOnBillGroup(BillGroup, RemainingAmount, RejectionFeeAmount, WithoutUnrealizedVAT, 0, DealingTypeDiscount, RemainingAmount);

        VerifyRejectedBillGroupVATGLEntries(
          RemainingAmount, RejectionFeeAmount, WithoutUnrealizedVAT, 0, DealingTypeDiscount, RemainingAmount);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,BillGroupDiscountPostedMessageHandler,RejectCarteraDocRequestPageHandler,CarteraJournalModalPageHandler')]
    [Scope('OnPrem')]
    procedure RejectionOfBillGroupUnrealizedVAT()
    var
        BankAccount: Record "Bank Account";
        BillGroup: Record "Bill Group";
        Customer: Record Customer;
        RemainingAmount: Decimal;
        RejectionFeeAmount: Decimal;
        ExpectedVATAmount: Decimal;
        SalesUnrVATAccount: Code[20];
        PurchUnrVATAccount: Code[20];
    begin
        Initialize();

        // Pre-Setup
        LibraryCarteraCommon.SetupUnrealizedVAT(SalesUnrVATAccount, PurchUnrVATAccount);
        RejectionTestsSetup(BankAccount, Customer);
        CreateAndPostBillGroupsWithUnrealizedVAT(Customer."Payment Method Code",
          Customer."Payment Terms Code", Customer."No.", BankAccount."No.", BillGroup, ExpectedVATAmount, RemainingAmount);
        RejectionFeeAmount := CalculateRejectionFeeAmount(BillGroup, RemainingAmount);

        // Exercise
        InvokeRejectOnBillGroup(
          BillGroup, RemainingAmount, RejectionFeeAmount, WithUnrealizedVAT, ExpectedVATAmount, DealingTypeCollection, 0);

        // Verify
        VerifyRejectedBillGroupVATGLEntries(
          RemainingAmount, RejectionFeeAmount, WithUnrealizedVAT, ExpectedVATAmount, DealingTypeCollection, 0);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,BillGroupDiscountPostedMessageHandler,CheckDiscountCreditLimitModalPageHandler,PostBillGroupRequestPageHandler,CarteraJournalModalPageHandler,RejectCarteraDocRequestPageHandler')]
    [Scope('OnPrem')]
    procedure RejectionOfBillGroupUnrealizedVATDealingTypeDiscount()
    var
        BankAccount: Record "Bank Account";
        BillGroup: Record "Bill Group";
        Customer: Record Customer;
        RemainingAmount: Decimal;
        RejectionFeeAmount: Decimal;
        ExpectedVATAmount: Decimal;
        SalesUnrVATAccount: Code[20];
        PurchUnrVATAccount: Code[20];
    begin
        Initialize();

        // Pre-Setup
        LibraryCarteraCommon.SetupUnrealizedVAT(SalesUnrVATAccount, PurchUnrVATAccount);
        RejectionTestsSetup(BankAccount, Customer);
        LibraryCarteraReceivables.CreateDiscountOperationFeesForBankAccount(BankAccount);
        CreateAndPostBillGroupWithDiscountAndUnrealizedVAT(Customer."Payment Method Code",
          Customer."Payment Terms Code", Customer."No.", BankAccount."No.", BillGroup, ExpectedVATAmount, RemainingAmount);
        RejectionFeeAmount := CalculateRejectionFeeAmount(BillGroup, RemainingAmount);

        // Exercise
        InvokeRejectOnBillGroup(
          BillGroup, RemainingAmount, RejectionFeeAmount, WithUnrealizedVAT, ExpectedVATAmount, DealingTypeDiscount, RemainingAmount);

        // Verify
        VerifyRejectedBillGroupVATGLEntries(
          RemainingAmount, RejectionFeeAmount, WithUnrealizedVAT, ExpectedVATAmount, DealingTypeDiscount, RemainingAmount);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,BillGroupDiscountPostedMessageHandler,RejectCarteraDocRequestPageHandler,CarteraJournalModalPageHandler')]
    [Scope('OnPrem')]
    procedure PaymentOfRejectedBillGroupDocumentTypePayment()
    var
        BankAccount: Record "Bank Account";
        BillGroup: Record "Bill Group";
        Customer: Record Customer;
        RejectionFeeAmount: Decimal;
        RemainingAmount: Decimal;
    begin
        Initialize();

        // Setup
        RejectionTestsSetup(BankAccount, Customer);
        CreateAndPostBillGroup(Customer."No.", BankAccount."No.", BillGroup, RemainingAmount);
        RejectionFeeAmount := CalculateRejectionFeeAmount(BillGroup, RemainingAmount);

        // Exercise
        InvokeRejectOnBillGroup(BillGroup, RemainingAmount, RejectionFeeAmount, WithoutUnrealizedVAT, 0, DealingTypeCollection, 0);

        VerifyRejectedBillGroupVATGLEntries(RemainingAmount, RejectionFeeAmount, WithoutUnrealizedVAT, 0, DealingTypeCollection, 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,BillGroupDiscountPostedMessageHandler,RejectCarteraDocRequestPageHandler,CarteraJournalModalPageHandler,ApplyCustomerEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure ApplyPaymentToRejectedInvoiceWithDocumentTypePayment()
    var
        BankAccount: Record "Bank Account";
        BillGroup: Record "Bill Group";
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        RejectionFeeAmount: Decimal;
        RemainingAmount: Decimal;
        BalancingAccountNo: Code[20];
    begin
        Initialize();

        // Setup
        RejectionTestsSetup(BankAccount, Customer);
        CreateAndPostBillGroup(Customer."No.", BankAccount."No.", BillGroup, RemainingAmount);
        RejectionFeeAmount := CalculateRejectionFeeAmount(BillGroup, RemainingAmount);

        // Exercise
        InvokeRejectOnBillGroup(BillGroup, RemainingAmount, RejectionFeeAmount, WithoutUnrealizedVAT, 0, DealingTypeCollection, 0);

        PostPaymentToRejectedBill(Customer."No.", GenJournalLine."Document Type"::Payment, BalancingAccountNo);
        VerifyPostedPaymentToRejectedBill(RemainingAmount, BalancingAccountNo, GenJournalLine."Document Type"::Payment, Customer."No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,BillGroupDiscountPostedMessageHandler,RejectCarteraDocRequestPageHandler,CarteraJournalModalPageHandler,ApplyCustomerEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure ApplyPaymentToRejectedInvoiceWithDocumentTypeBlank()
    var
        BankAccount: Record "Bank Account";
        BillGroup: Record "Bill Group";
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        RejectionFeeAmount: Decimal;
        RemainingAmount: Decimal;
        BalancingAccountNo: Code[20];
    begin
        Initialize();

        // Setup
        RejectionTestsSetup(BankAccount, Customer);
        CreateAndPostBillGroup(Customer."No.", BankAccount."No.", BillGroup, RemainingAmount);
        RejectionFeeAmount := CalculateRejectionFeeAmount(BillGroup, RemainingAmount);

        // Exercise
        InvokeRejectOnBillGroup(BillGroup, RemainingAmount, RejectionFeeAmount, WithoutUnrealizedVAT, 0, DealingTypeCollection, 0);

        PostPaymentToRejectedBill(Customer."No.", GenJournalLine."Document Type"::" ", BalancingAccountNo);
        VerifyPostedPaymentToRejectedBill(RemainingAmount, BalancingAccountNo, GenJournalLine."Document Type"::" ", Customer."No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,BillGroupDiscountPostedMessageHandler,RejectCarteraDocRequestPageHandlerSimple')]
    [Scope('OnPrem')]
    procedure HonorSalesInvoiceRejectedFromBillGroupWhenFullPayment()
    var
        SalesHeader: Record "Sales Header";
        BillGroup: Record "Bill Group";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        ClosedCarteraDoc: Record "Closed Cartera Doc.";
        PostedDocNo: Code[20];
        AmountToPay: Decimal;
    begin
        // [FEATURE] [Document Status] [Cust. Ledger Entry] [Closed Cartera Doc.]
        // [SCENARIO 270642] When Sales Invoice rejected from Bill Group is fully paid, then Document Status is changed from "Rejected" to "Honored" in Cust. Ledger Entry and Closed Cartera Doc.
        Initialize();

        // [GIVEN] Payment Method with "Invoices to Cartera" = TRUE and Collection Agent = Bank
        // [GIVEN] Posted Sales Invoice with Payment Method Code and Amount Including VAT = 1000.0
        CreateSalesInvoiceWithPaymentMethod(SalesHeader, CreatePaymentMethodWithInvoicesToCarteraAndCollectionAgentBank());
        SalesHeader.CalcFields("Amount Including VAT");
        PostedDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Posted Bill Group with Dealing Type = "Collection" and Cartera Doc. = Posted Sales Invoice "No."
        CreateBillGroupWithCarteraDoc(BillGroup, BillGroup."Dealing Type"::Collection, SalesHeader."Sell-to Customer No.", PostedDocNo);
        LibraryVariableStorage.Enqueue(BillGroupNotPrintedMsg);
        LibraryCarteraReceivables.PostCarteraBillGroup(BillGroup);

        // [GIVEN] Rejected Posted Bill Group
        LibraryVariableStorage.Enqueue(OneDocumentRejectedMsg);
        LibraryCarteraReceivables.FindCarteraDocCustomerLedgerEntry(
          CustLedgerEntry, SalesHeader."Sell-to Customer No.", PostedDocNo, CustLedgerEntry."Document Situation"::"Posted BG/PO",
          CustLedgerEntry."Document Type"::Invoice);
        REPORT.Run(REPORT::"Reject Docs.", true, false, CustLedgerEntry);

        // [GIVEN] Posted Payment for Invoice with Amount = -900.0
        AmountToPay := Round(SalesHeader."Amount Including VAT" / LibraryRandom.RandIntInRange(2, 5));
        CreatePaymentLineForPostedSalesInvoice(
          GenJournalLine, SalesHeader."Sell-to Customer No.", PostedDocNo, -AmountToPay);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Payment Line for Invoice with Amount = -100.0
        CreatePaymentLineForPostedSalesInvoice(
          GenJournalLine, SalesHeader."Sell-to Customer No.", PostedDocNo,
          -(SalesHeader."Amount Including VAT" - AmountToPay));

        // [WHEN] Post Payment Line
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Cust. Ledger Entry for Invoice has Document Status = Honored
        LibraryCarteraReceivables.FindCarteraDocCustomerLedgerEntry(
          CustLedgerEntry, SalesHeader."Sell-to Customer No.", PostedDocNo, CustLedgerEntry."Document Situation"::"Closed BG/PO",
          CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.TestField("Document Status", CustLedgerEntry."Document Status"::Honored);

        // [THEN] Closed Cartera Doc for Invoice has Document Status = Honored
        ClosedCarteraDoc.Get(ClosedCarteraDoc.Type::Receivable, CustLedgerEntry."Entry No.");
        ClosedCarteraDoc.TestField(Status, ClosedCarteraDoc.Status::Honored);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('BillGroupDiscountPostedMessageHandler,RejectCarteraDocRequestPageHandlerSimple')]
    [Scope('OnPrem')]
    procedure HonorRejectedSalesInvoiceWhenFullPayment()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        ClosedCarteraDoc: Record "Closed Cartera Doc.";
        PostedDocNo: Code[20];
        AmountToPay: Decimal;
    begin
        // [FEATURE] [Document Status] [Cust. Ledger Entry] [Closed Cartera Doc.]
        // [SCENARIO 270642] When rejected Sales Invoice is fully paid, then Document Status is changed from "Rejected" to "Honored" in Cust. Ledger Entry and Closed Cartera Doc.
        Initialize();

        // [GIVEN] Payment Method with "Invoices to Cartera" = TRUE and Collection Agent = Bank
        // [GIVEN] Posted Sales Invoice with Payment Method Code and Amount Including VAT = 1000.0
        CreateSalesInvoiceWithPaymentMethod(SalesHeader, CreatePaymentMethodWithInvoicesToCarteraAndCollectionAgentBank());
        SalesHeader.CalcFields("Amount Including VAT");
        PostedDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Rejected Customer Ledger Entry for Invoice
        LibraryVariableStorage.Enqueue(OneDocumentRejectedMsg);
        LibraryCarteraReceivables.FindCarteraDocCustomerLedgerEntry(
          CustLedgerEntry, SalesHeader."Sell-to Customer No.", PostedDocNo, CustLedgerEntry."Document Situation"::Cartera,
          CustLedgerEntry."Document Type"::Invoice);
        REPORT.Run(REPORT::"Reject Docs.", true, false, CustLedgerEntry);

        // [GIVEN] Posted Payment for Invoice with Amount = -900.0
        AmountToPay := Round(SalesHeader."Amount Including VAT" / LibraryRandom.RandIntInRange(2, 5));
        CreatePaymentLineForPostedSalesInvoice(
          GenJournalLine, SalesHeader."Sell-to Customer No.", PostedDocNo, -AmountToPay);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Payment Line for Invoice with Amount = -100.0
        CreatePaymentLineForPostedSalesInvoice(
          GenJournalLine, SalesHeader."Sell-to Customer No.", PostedDocNo,
          -(SalesHeader."Amount Including VAT" - AmountToPay));

        // [WHEN] Post Payment Line
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Cust. Ledger Entry for Invoice has Document Status = Honored
        LibraryCarteraReceivables.FindCarteraDocCustomerLedgerEntry(
          CustLedgerEntry, SalesHeader."Sell-to Customer No.", PostedDocNo, CustLedgerEntry."Document Situation"::"Closed Documents",
          CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.TestField("Document Status", CustLedgerEntry."Document Status"::Honored);

        // [THEN] Closed Cartera Doc for Invoice has Document Status = Honored
        ClosedCarteraDoc.Get(ClosedCarteraDoc.Type::Receivable, CustLedgerEntry."Entry No.");
        ClosedCarteraDoc.TestField(Status, ClosedCarteraDoc.Status::Honored);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('BillGroupDiscountPostedMessageHandler,RejectCarteraDocRequestPageHandlerSimple')]
    [Scope('OnPrem')]
    procedure DoNotHonorRejectedSalesInvoiceWhenNotFullyPaid()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        ClosedCarteraDoc: Record "Closed Cartera Doc.";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Document Status] [Cust. Ledger Entry] [Closed Cartera Doc.]
        // [SCENARIO 270642] When rejected Sales Invoice is not fully paid, then Document Status remains "Rejected" in Cust. Ledger Entry and Closed Cartera Doc.
        Initialize();

        // [GIVEN] Payment Method with "Invoices to Cartera" = TRUE and Collection Agent = Bank
        // [GIVEN] Posted Sales Invoice with Payment Method Code and Amount Including VAT = 1000.0
        CreateSalesInvoiceWithPaymentMethod(SalesHeader, CreatePaymentMethodWithInvoicesToCarteraAndCollectionAgentBank());
        SalesHeader.CalcFields("Amount Including VAT");
        PostedDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Rejected Customer Ledger Entry for Invoice
        LibraryVariableStorage.Enqueue(OneDocumentRejectedMsg);
        LibraryCarteraReceivables.FindCarteraDocCustomerLedgerEntry(
          CustLedgerEntry, SalesHeader."Sell-to Customer No.", PostedDocNo, CustLedgerEntry."Document Situation"::Cartera,
          CustLedgerEntry."Document Type"::Invoice);
        REPORT.Run(REPORT::"Reject Docs.", true, false, CustLedgerEntry);

        // [GIVEN] Posted Payment for Invoice with Amount = -900.0
        CreatePaymentLineForPostedSalesInvoice(
          GenJournalLine, SalesHeader."Sell-to Customer No.", PostedDocNo,
          -Round(SalesHeader."Amount Including VAT" / LibraryRandom.RandIntInRange(2, 5)));

        // [WHEN] Post Payment Line
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Cust. Ledger Entry for Invoice has Document Status = Rejected
        LibraryCarteraReceivables.FindCarteraDocCustomerLedgerEntry(
          CustLedgerEntry, SalesHeader."Sell-to Customer No.", PostedDocNo, CustLedgerEntry."Document Situation"::"Closed Documents",
          CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.TestField("Document Status", CustLedgerEntry."Document Status"::Rejected);

        // [THEN] Closed Cartera Doc for Invoice has Document Status = Honored
        ClosedCarteraDoc.Get(ClosedCarteraDoc.Type::Receivable, CustLedgerEntry."Entry No.");
        ClosedCarteraDoc.TestField(Status, ClosedCarteraDoc.Status::Rejected);

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    begin
        LibraryCarteraCommon.RevertUnrealizedVATPostingSetup();
        LibraryVariableStorage.Clear();

        if IsInitialized then
            exit;

        IsInitialized := true;

        CarteraGenJournalTemplate.SetRange(Type, CarteraGenJournalTemplate.Type::Cartera);
        LibraryERM.FindGenJournalTemplate(CarteraGenJournalTemplate);
        LibraryERM.FindGenJournalBatch(CarteraGenJournalBatch, CarteraGenJournalTemplate.Name);

        // Named constants not to place unmeaningfull values within tests
        LocalCurrencyCode := '';
        NotRejection := false;
        Rejection := true;
        WithoutUnrealizedVAT := false;
        WithUnrealizedVAT := true;
        DealingTypeDiscount := true;
        DealingTypeCollection := false;
    end;

    local procedure CreatePaymentMethodWithInvoicesToCarteraAndCollectionAgentBank(): Code[10]
    var
        PaymentMethod: Record "Payment Method";
    begin
        LibraryCarteraCommon.CreatePaymentMethod(PaymentMethod, false, true);
        PaymentMethod.Validate("Collection Agent", PaymentMethod."Collection Agent"::Bank);
        PaymentMethod.Modify(true);
        exit(PaymentMethod.Code);
    end;

    local procedure CreateSalesInvoiceWithPaymentMethod(var SalesHeader: Record "Sales Header"; PaymentMethodCode: Code[10])
    begin
        LibrarySales.CreateSalesInvoice(SalesHeader);
        SalesHeader.Validate("Payment Method Code", PaymentMethodCode);
        SalesHeader.Modify(true);
    end;

    local procedure CreateBillGroupWithCarteraDoc(var BillGroup: Record "Bill Group"; DealingType: Enum "Cartera Dealing Type"; CustNo: Code[20]; PostedDocNo: Code[20])
    var
        BankAccount: Record "Bank Account";
        CarteraDoc: Record "Cartera Doc.";
    begin
        LibraryCarteraReceivables.CreateBankAccount(BankAccount, '');
        LibraryCarteraReceivables.CreateBillGroup(BillGroup, BankAccount."No.", DealingType);
        LibraryCarteraReceivables.AddCarteraDocumentToBillGroup(CarteraDoc, PostedDocNo, CustNo, BillGroup."No.");
    end;

    local procedure CreatePaymentLineForPostedSalesInvoice(var GenJournalLine: Record "Gen. Journal Line"; CustNo: Code[20]; PostedDocNo: Code[20]; Amount: Decimal)
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, CustNo, Amount);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", PostedDocNo);
        GenJournalLine.Modify(true);
    end;

    local procedure RejectionTestsSetup(var BankAccount: Record "Bank Account"; var Customer: Record Customer)
    var
        CustomerBankAccount: Record "Customer Bank Account";
        FeeRange: Record "Fee Range";
    begin
        LibraryCarteraReceivables.CreateCarteraCustomer(Customer, LocalCurrencyCode);
        LibraryCarteraReceivables.CreateCustomerBankAccount(Customer, CustomerBankAccount);
        LibraryCarteraReceivables.CreateBankAccount(BankAccount, LocalCurrencyCode);
        LibraryCarteraReceivables.CreateFeeRange(FeeRange,
          BankAccount."No.", LocalCurrencyCode, FeeRange."Type of Fee"::"Rejection Expenses");
    end;

    local procedure InvokeRejectOnBillGroup(BillGroup: Record "Bill Group"; Amount: Decimal; RejectionFeeAmount: Decimal; HasUnrealizedVAT: Boolean; UnrealizedVATAmount: Decimal; IsDealingTypeDiscount: Boolean; DiscountAmount: Decimal)
    var
        PostedBillGroup: Record "Posted Bill Group";
        PostedCarteraDoc: Record "Posted Cartera Doc.";
        PostedBillGroups: TestPage "Posted Bill Groups";
    begin
        PostedBillGroup.Get(BillGroup."No.");
        PostedBillGroups.OpenEdit();
        PostedBillGroups.GotoRecord(PostedBillGroup);

        PostedCarteraDoc.SetRange(Type, PostedCarteraDoc.Type::Receivable);
        PostedCarteraDoc.SetRange("Bill Gr./Pmt. Order No.", BillGroup."No.");
        PostedCarteraDoc.FindFirst();

        PostedBillGroups.Docs.GotoRecord(PostedCarteraDoc);

        LibraryVariableStorage.Enqueue(Rejection);
        LibraryVariableStorage.Enqueue(Amount);
        LibraryVariableStorage.Enqueue(RejectionFeeAmount);

        LibraryVariableStorage.Enqueue(HasUnrealizedVAT);
        LibraryVariableStorage.Enqueue(IsDealingTypeDiscount);

        if HasUnrealizedVAT then
            LibraryVariableStorage.Enqueue(UnrealizedVATAmount);

        if IsDealingTypeDiscount then
            LibraryVariableStorage.Enqueue(DiscountAmount);

        LibraryVariableStorage.Enqueue(PostJnlLinesMsg);
        LibraryVariableStorage.Enqueue(JnlLinesPostedMsg);
        LibraryVariableStorage.Enqueue(OneDocumentRejectedMsg);

        Commit();
        PostedBillGroups.Docs.Reject.Invoke();
    end;

    local procedure InvokePartialSettlementOnBillGroup(CustomerNo: Code[20]; DocumentNo: Code[20]; BillGroupNo: Code[20]; var RemainingAmount: Decimal; var ExpectedVATAmount: Decimal)
    var
        PostedBillGroup: Record "Posted Bill Group";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GLSetup: Record "General Ledger Setup";
        PostedBillGroupTestPage: TestPage "Posted Bill Groups";
        InitialAmount: Decimal;
        SettledAmount: Decimal;
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

        RemainingAmount := InitialAmount - SettledAmount;
        ExpectedVATAmount := ExpectedVATAmount - SettledAmount / InitialAmount * ExpectedVATAmount;
        // Exercise
        Commit();
        PostedBillGroupTestPage.Docs."Partial Settlement".Invoke();
    end;

    local procedure VerifyRejectedBillGroupVATGLEntries(TotalAmount: Decimal; RejectionFeeAmount: Decimal; HasUnsettledVAT: Boolean; ExpectedVATAmount: Decimal; IsDealingTypeDiscount: Boolean; ExpectedDiscountAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
        GLRegister: Record "G/L Register";
    begin
        GLRegister.FindLast();
        GLEntry.SetRange("Transaction No.", GLRegister."No.");

        GLEntry.Find('-');
        Assert.AreNearlyEqual(
          TotalAmount, GLEntry."Debit Amount", LibraryERM.GetAmountRoundingPrecision(),
          'Total Credit Amount for Total Amount has a wrong value');

        GLEntry.Next();
        Assert.AreNearlyEqual(
          TotalAmount, GLEntry."Credit Amount", LibraryERM.GetAmountRoundingPrecision(),
          'Total Debit Amount for Total Amount has a wrong value');

        if IsDealingTypeDiscount then begin
            GLEntry.Next();
            Assert.AreNearlyEqual(
              ExpectedDiscountAmount, GLEntry."Debit Amount", LibraryERM.GetAmountRoundingPrecision(),
              'Total Credit Amount for Discount Amount has a wrong value');

            GLEntry.Next();
            Assert.AreNearlyEqual(
              ExpectedDiscountAmount, GLEntry."Credit Amount", LibraryERM.GetAmountRoundingPrecision(),
              'Total Debit Amount for Discount Amount has a wrong value');
        end;

        if HasUnsettledVAT then begin
            GLEntry.Next();
            Assert.AreNearlyEqual(
              ExpectedVATAmount, GLEntry."Debit Amount", LibraryERM.GetAmountRoundingPrecision(),
              'Total Credit Amount for Unsettled VAT Amount has a wrong value');

            GLEntry.Next();
            Assert.AreNearlyEqual(
              ExpectedVATAmount, GLEntry."Credit Amount", LibraryERM.GetAmountRoundingPrecision(),
              'Total Debit Amount for Unsettled VAT Amount has a wrong value');
        end;

        GLEntry.Next();
        Assert.AreNearlyEqual(
          RejectionFeeAmount, GLEntry."Debit Amount", LibraryERM.GetAmountRoundingPrecision(),
          'Total Debit Amount for Rejection Fee has a wrong value');

        GLEntry.Next();
        Assert.AreNearlyEqual(
          RejectionFeeAmount, GLEntry."Credit Amount", LibraryERM.GetAmountRoundingPrecision(),
          'Total Debit Amount for Rejection Fee has a wrong value');
    end;

    [Normal]
    local procedure CreateAndPostBillGroup(CustomerNo: Code[20]; BankAccountNo: Code[20]; var BillGroup: Record "Bill Group"; var TotalAmount: Decimal): Code[20]
    var
        SalesHeader: Record "Sales Header";
        CarteraDoc: Record "Cartera Doc.";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BGPostAndPrint: Codeunit "BG/PO-Post and Print";
        DocumentNo: Code[20];
    begin
        LibraryCarteraReceivables.CreateSalesInvoice(SalesHeader, CustomerNo);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        TotalAmount := LibraryCarteraReceivables.GetPostedSalesInvoiceAmount(CustomerNo, DocumentNo,
            CustLedgerEntry."Document Type"::Invoice);

        LibraryCarteraReceivables.CreateBillGroup(BillGroup, BankAccountNo, BillGroup."Dealing Type"::Collection);
        LibraryCarteraReceivables.AddCarteraDocumentToBillGroup(CarteraDoc, DocumentNo, CustomerNo, BillGroup."No.");

        LibraryVariableStorage.Enqueue(BillGroupNotPrintedMsg);
        BGPostAndPrint.ReceivablePostOnly(BillGroup);

        exit(DocumentNo);
    end;

    [Normal]
    local procedure CreateAndPostBillGroupWithDiscount(CustomerNo: Code[20]; BankAccountNo: Code[20]; var BillGroup: Record "Bill Group"; var TotalAmount: Decimal) DocumentNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
        CarteraDoc: Record "Cartera Doc.";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryCarteraReceivables.CreateSalesInvoice(SalesHeader, CustomerNo);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        TotalAmount := LibraryCarteraReceivables.GetPostedSalesInvoiceAmount(CustomerNo, DocumentNo,
            CustLedgerEntry."Document Type"::Invoice);

        LibraryCarteraReceivables.CreateBillGroup(BillGroup, BankAccountNo, BillGroup."Dealing Type"::Discount);
        LibraryCarteraReceivables.AddCarteraDocumentToBillGroup(CarteraDoc, DocumentNo, CustomerNo, BillGroup."No.");
        CarteraDoc.ModifyAll("Due Date", CalcDate('<1M>', CarteraDoc."Posting Date"));

        PostBillGroupsWithDiscountForCustomer(BillGroup);
    end;

    [Normal]
    local procedure CreateAndPostBillGroupsWithUnrealizedVAT(PaymentMethodCode: Code[10]; PaymentTermsCode: Code[10]; CustomerNo: Code[20]; BankAccountNo: Code[20]; var BillGroup: Record "Bill Group"; var ExpectedVATAmount: Decimal; var TotalAmount: Decimal) DocumentNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PaymentMethod: Record "Payment Method";
        PaymentTerms: Record "Payment Terms";
        CarteraDoc: Record "Cartera Doc.";
        VATPostingSetup: Record "VAT Posting Setup";
        CustLedgerEntry: Record "Cust. Ledger Entry";
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
        SalesLine.FindFirst();

        VATPostingSetup.Get(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group");

        // Exercise
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        TotalAmount := LibraryCarteraReceivables.GetPostedSalesInvoiceAmount(CustomerNo, DocumentNo,
            CustLedgerEntry."Document Type"::Invoice);

        ExpectedVATAmount :=
          Round(TotalAmount - TotalAmount * 100 / (VATPostingSetup."VAT %" + 100), LibraryERM.GetAmountRoundingPrecision());

        LibraryCarteraReceivables.CreateBillGroup(BillGroup, BankAccountNo, BillGroup."Dealing Type"::Collection);
        LibraryCarteraReceivables.AddCarteraDocumentToBillGroup(CarteraDoc, DocumentNo, CustomerNo, BillGroup."No.");

        LibraryVariableStorage.Enqueue(BillGroupNotPrintedMsg);
        BGPostAndPrint.ReceivablePostOnly(BillGroup);
    end;

    [Normal]
    local procedure CreateAndPostBillGroupWithDiscountAndUnrealizedVAT(PaymentMethodCode: Code[10]; PaymentTermsCode: Code[10]; CustomerNo: Code[20]; BankAccountNo: Code[20]; var BillGroup: Record "Bill Group"; var ExpectedVATAmount: Decimal; var TotalAmount: Decimal) DocumentNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
        PaymentMethod: Record "Payment Method";
        CarteraDoc: Record "Cartera Doc.";
        PaymentTerms: Record "Payment Terms";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        CustLedgerEntry: Record "Cust. Ledger Entry";
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
        SalesLine.FindFirst();

        VATPostingSetup.Get(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group");

        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        TotalAmount := LibraryCarteraReceivables.GetPostedSalesInvoiceAmount(CustomerNo, DocumentNo,
            CustLedgerEntry."Document Type"::Invoice);

        ExpectedVATAmount :=
          Round(TotalAmount - TotalAmount * 100 / (VATPostingSetup."VAT %" + 100), LibraryERM.GetAmountRoundingPrecision());

        LibraryCarteraReceivables.CreateBillGroup(BillGroup, BankAccountNo, BillGroup."Dealing Type"::Discount);

        LibraryCarteraReceivables.AddCarteraDocumentToBillGroup(CarteraDoc, DocumentNo, CustomerNo, BillGroup."No.");
        CarteraDoc.ModifyAll("Due Date", CalcDate('<1M>', CarteraDoc."Posting Date"));

        PostBillGroupsWithDiscountForCustomer(BillGroup);
    end;

    local procedure CreateCashGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, FindCashReceiptTemplate());
        GenJournalBatch.SetupNewBatch();
        GenJournalBatch.Modify(true);
    end;

    local procedure FindCashReceiptTemplate(): Code[10]
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::"Cash Receipts");
        GenJournalTemplate.FindFirst();
        exit(GenJournalTemplate.Name);
    end;

    local procedure CalculateRejectionFeeAmount(BillGroup: Record "Bill Group"; TotalAmount: Decimal): Decimal
    var
        FeeRange: Record "Fee Range";
        RejectionFeeAmount: Decimal;
    begin
        FeeRange.SetRange(Code, BillGroup."Bank Account No.");
        FeeRange.SetRange("Currency Code", BillGroup."Currency Code");
        FeeRange.SetRange("Type of Fee", FeeRange."Type of Fee"::"Rejection Expenses");
        FeeRange.FindFirst();
        RejectionFeeAmount := TotalAmount * FeeRange."Charge % per Doc." / 100 + FeeRange."Charge Amount per Doc.";
        exit(RejectionFeeAmount);
    end;

    local procedure PostPaymentToRejectedBill(CustomerAccountNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; var BalancingAccountNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        CashGenJournalBatch: Record "Gen. Journal Batch";
        CashReceiptJournal: TestPage "Cash Receipt Journal";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        BalancingAccountNo := GLAccount."No.";
        CreateCashGenJournalBatch(CashGenJournalBatch);

        Commit();
        CashReceiptJournal.OpenEdit();
        CashReceiptJournal.CurrentJnlBatchName.SetValue(CashGenJournalBatch.Name);
        CashReceiptJournal."Document Type".SetValue(DocumentType);
        CashReceiptJournal."Account Type".SetValue(GenJournalLine."Account Type"::Customer);
        CashReceiptJournal."Account No.".SetValue(CustomerAccountNo);

        CashReceiptJournal."Bal. Account No.".SetValue(BalancingAccountNo);
        CashReceiptJournal."Apply Entries".Invoke();
        Assert.IsTrue(CashReceiptJournal."Applied (Yes/No)".AsBoolean(), 'Document should have been applied to a line');

        LibraryVariableStorage.Enqueue(PostJnlLinesMsg);
        LibraryVariableStorage.Enqueue(JnlLinesPostedMsg);
        CashReceiptJournal.Post.Invoke();
    end;

    local procedure VerifyPostedPaymentToRejectedBill(RemainingAmount: Decimal; AccountNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; BalancingAccountNo: Code[20])
    var
        GLRegister: Record "G/L Register";
        GLEntry: Record "G/L Entry";
    begin
        GLRegister.FindLast();
        GLEntry.SetRange("Transaction No.", GLRegister."No.");

        GLEntry.SetRange("G/L Account No.", AccountNo);
        GLEntry.SetRange(Amount, RemainingAmount);
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.SetRange("Bal. Account No.", BalancingAccountNo);

        Assert.AreEqual(1, GLEntry.Count, 'Could not find the entry');
    end;

    local procedure PostBillGroupsWithDiscountForCustomer(var BillGroup: Record "Bill Group")
    var
        BGPostAndPrint: Codeunit "BG/PO-Post and Print";
    begin
        LibraryVariableStorage.Enqueue(BillGroupNotPrintedMsg);
        LibraryVariableStorage.Enqueue(NotRejection);
        LibraryVariableStorage.Enqueue(ConfirmPostingJournalLinesMsg);
        LibraryVariableStorage.Enqueue(SuccessfullyPostedJournalLinesMsg);
        LibraryVariableStorage.Enqueue(StrSubstNo(BankBillGroupPostedForDiscountMsg, BillGroup."No."));
        Commit();
        BGPostAndPrint.ReceivablePostOnly(BillGroup);
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
    begin
        PostBillGroup.TemplName.SetValue(CarteraGenJournalTemplate.Name);
        PostBillGroup.BatchName.SetValue(CarteraGenJournalBatch.Name);

        PostBillGroup.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CarteraJournalModalPageHandler(var CarteraJournal: TestPage "Cartera Journal")
    var
        AmountVariant: Variant;
        RejectionFeeAmountVariant: Variant;
        HasUnrealizedVATVariant: Variant;
        ExpectedVATAmountVariant: Variant;
        IsDealingTypeDiscountVariant: Variant;
        ExpectedDiscountAmountVariant: Variant;
        IsRejectionVariant: Variant;
        Amount: Decimal;
        RejectionFeeAmount: Decimal;
        CreditAmount: Decimal;
        ExpectedVATAmount: Decimal;
        ExpectedDiscountAmount: Decimal;
        HasUnrealizedVAT: Boolean;
        IsRejection: Boolean;
        IsDealingTypeDiscount: Boolean;
    begin
        LibraryVariableStorage.Dequeue(IsRejectionVariant);
        IsRejection := IsRejectionVariant;

        if not IsRejection then begin
            LibraryCarteraReceivables.PrepareCarteraDiscountJournalLines(CarteraGenJournalBatch);
            CarteraJournal.Post.Invoke();
            exit;
        end;

        LibraryVariableStorage.Dequeue(AmountVariant);
        LibraryVariableStorage.Dequeue(RejectionFeeAmountVariant);
        LibraryVariableStorage.Dequeue(HasUnrealizedVATVariant);
        LibraryVariableStorage.Dequeue(IsDealingTypeDiscountVariant);

        Amount := AmountVariant;
        RejectionFeeAmount := RejectionFeeAmountVariant;
        HasUnrealizedVAT := HasUnrealizedVATVariant;
        IsDealingTypeDiscount := IsDealingTypeDiscountVariant;

        // Go from the last to check that there are only 4 rows present
        CarteraJournal.Last();
        Assert.AreNearlyEqual(
          RejectionFeeAmount, CarteraJournal."Credit Amount".AsDecimal(), LibraryERM.GetAmountRoundingPrecision(),
          'Wrong amount on the Rejection Fee line');
        CreditAmount := CarteraJournal."Credit Amount".AsDecimal();

        CarteraJournal.Previous();
        Assert.AreNearlyEqual(
          RejectionFeeAmount, CarteraJournal."Debit Amount".AsDecimal(), LibraryERM.GetAmountRoundingPrecision(),
          'Wrong amount on the Rejection Fee line');
        Assert.AreEqual(CreditAmount, CarteraJournal."Debit Amount".AsDecimal(), 'Credit and Debit amounts must match');

        if HasUnrealizedVAT then begin
            LibraryVariableStorage.Dequeue(ExpectedVATAmountVariant);
            ExpectedVATAmount := ExpectedVATAmountVariant;

            CarteraJournal.Previous();
            Assert.AreNearlyEqual(
              ExpectedVATAmount, CarteraJournal."Credit Amount".AsDecimal(), LibraryERM.GetAmountRoundingPrecision(), 'Wrong amount on the line');

            CarteraJournal.Previous();
            Assert.AreNearlyEqual(
              ExpectedVATAmount, CarteraJournal."Debit Amount".AsDecimal(), LibraryERM.GetAmountRoundingPrecision(), 'Wrong amount on the line');
        end;

        if IsDealingTypeDiscount then begin
            LibraryVariableStorage.Dequeue(ExpectedDiscountAmountVariant);
            ExpectedDiscountAmount := ExpectedDiscountAmountVariant;

            CarteraJournal.Previous();
            Assert.AreNearlyEqual(
              ExpectedDiscountAmount, CarteraJournal."Credit Amount".AsDecimal(), LibraryERM.GetAmountRoundingPrecision(),
              'Wrong amount on the line');

            CarteraJournal.Previous();
            Assert.AreNearlyEqual(
              ExpectedDiscountAmount, CarteraJournal."Debit Amount".AsDecimal(), LibraryERM.GetAmountRoundingPrecision(),
              'Wrong amount on the line');
        end;

        CarteraJournal.Previous();
        Assert.AreNearlyEqual(
          Amount, CarteraJournal."Credit Amount".AsDecimal(), LibraryERM.GetAmountRoundingPrecision(), 'Wrong amount on the line');

        CarteraJournal.Previous();
        Assert.AreNearlyEqual(
          Amount, CarteraJournal."Debit Amount".AsDecimal(), LibraryERM.GetAmountRoundingPrecision(), 'Wrong amount on the line');

        CarteraJournal.Post.Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure BillGroupDiscountPostedMessageHandler(Message: Text[1024])
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);
        Assert.ExpectedMessage(ExpectedMessage, Message);
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
    procedure RejectCarteraDocRequestPageHandler(var RejectDocs: TestRequestPage "Reject Docs.")
    begin
        RejectDocs.IncludeExpenses.SetValue(true);
        RejectDocs.UseJournal.SetValue(true);

        RejectDocs.TemplateName.SetValue(CarteraGenJournalTemplate.Name);
        RejectDocs.BatchName.SetValue(CarteraGenJournalBatch.Name);
        RejectDocs.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RejectCarteraDocRequestPageHandlerSimple(var RejectDocs: TestRequestPage "Reject Docs.")
    begin
        RejectDocs.IncludeExpenses.SetValue(false);
        RejectDocs.UseJournal.SetValue(false);
        RejectDocs.TemplateName.SetValue('');
        RejectDocs.BatchName.SetValue('');
        RejectDocs.PostingDate.SetValue(WorkDate());
        RejectDocs.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries."Set Applies-to ID".Invoke();
        ApplyCustomerEntries.OK().Invoke();
    end;
}

