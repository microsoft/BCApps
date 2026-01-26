codeunit 147531 "Cartera Recv. Installments"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Cartera] [Receivables] [Installments]
    end;

    var
        Assert: Codeunit Assert;
        LibraryCarteraCommon: Codeunit "Library - Cartera Common";
        LibraryCarteraReceivables: Codeunit "Library - Cartera Receivables";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryJournals: Codeunit "Library - Journals";
        CountMismatchErr: Label 'Number of %1 does not match %2.', Comment = '%1=TableCaption;%2=FieldCaption';
        LocalCurrencyCode: Code[10];
        RemainingAmountLCYstatsErr: Label 'Remaining Amount (LCY) stats. must be %1 in %2.', Comment = '%1= Field Value, %2=Table Name.';

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesPageHandler,PostApplicationPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ApplyCrMemoToCarteraDocWithMultipleInstallments()
    var
        CreditMemoSalesHeader: Record "Sales Header";
        CreditMemoCustLedgerEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
        FirstInstallmentCustLedgerEntry: Record "Cust. Ledger Entry";
        PaymentTerms: Record "Payment Terms";
        SalesHeader: Record "Sales Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        CreditMemoDocumentNo: Code[20];
        DocumentNo: Code[20];
        NoOfInstallments: Integer;
    begin
        Initialize();

        // Pre-Setup
        NoOfInstallments := 5;

        // Setup
        LibraryCarteraReceivables.CreateCarteraCustomer(Customer, LocalCurrencyCode);
        LibraryCarteraReceivables.CreateCustomerBankAccount(Customer, CustomerBankAccount);
        LibraryCarteraReceivables.SetPaymentTermsVatDistribution(Customer."Payment Terms Code",
          PaymentTerms."VAT distribution"::Proportional);
        LibraryCarteraReceivables.CreateMultipleInstallments(Customer."Payment Terms Code", NoOfInstallments);
        LibraryCarteraReceivables.CreateSalesInvoice(SalesHeader, Customer."No.");
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Post-Setup
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.SetRange("Sell-to Customer No.", Customer."No.");
        SalesInvoiceLine.SetRange(Type, SalesInvoiceLine.Type::Item);
        SalesInvoiceLine.FindFirst();
        LibraryCarteraReceivables.FindOpenCarteraDocCustomerLedgerEntries(FirstInstallmentCustLedgerEntry,
          Customer."No.", DocumentNo, FirstInstallmentCustLedgerEntry."Document Situation"::Cartera,
          FirstInstallmentCustLedgerEntry."Document Type"::Bill);
        FirstInstallmentCustLedgerEntry.CalcFields("Original Amount");

        // Pre-Exercise
        CreateCreditMemoToCorrectInvoice(CreditMemoSalesHeader,
          Customer."No.", DocumentNo, SalesInvoiceLine."No.", 1, FirstInstallmentCustLedgerEntry."Original Amount" / 2);
        CreditMemoDocumentNo := LibrarySales.PostSalesDocument(CreditMemoSalesHeader, true, true);
        LibraryERM.FindCustomerLedgerEntry(CreditMemoCustLedgerEntry,
          CreditMemoCustLedgerEntry."Document Type"::"Credit Memo", CreditMemoDocumentNo);

        // Exercise
        ApplyCreditMemoToFirstInstallment(CreditMemoCustLedgerEntry."Entry No.");

        // Verify
        VerifyRemainingAmountOnFirstInstallment(CreditMemoCustLedgerEntry."Entry No.", FirstInstallmentCustLedgerEntry."Entry No.");
        VerifyRemainingAmountOnCarteraDocOfFirstInstallment(FirstInstallmentCustLedgerEntry."Entry No.", DocumentNo);
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesPageHandler,PostApplicationPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ApplyCrMemoToCarteraDocWithMultipleInstallmentsUnrealizedVAT()
    var
        CreditMemoSalesHeader: Record "Sales Header";
        CreditMemoCustLedgerEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
        FirstInstallmentCustLedgerEntry: Record "Cust. Ledger Entry";
        PaymentTerms: Record "Payment Terms";
        SalesHeader: Record "Sales Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        VATPostingSetup: Record "VAT Posting Setup";
        CreditMemoDocumentNo: Code[20];
        DocumentNo: Code[20];
        NoOfInstallments: Integer;
        PurchUnrealizedVATAccount: Code[20];
        SalesUnrealizedVATAccount: Code[20];
        TotalAmount: Decimal;
        InitialVATAmount: Decimal;
        CreditMemoVATAmount: Decimal;
        CreditMemoAmount: Decimal;
    begin
        Initialize();

        // Pre-Setup
        NoOfInstallments := 5;
        LibraryCarteraCommon.SetupUnrealizedVAT(SalesUnrealizedVATAccount, PurchUnrealizedVATAccount);

        // Setup
        LibraryCarteraReceivables.CreateCarteraCustomer(Customer, LocalCurrencyCode);
        LibraryCarteraReceivables.CreateCustomerBankAccount(Customer, CustomerBankAccount);
        LibraryCarteraReceivables.SetPaymentTermsVatDistribution(Customer."Payment Terms Code",
          PaymentTerms."VAT distribution"::Proportional);
        LibraryCarteraReceivables.CreateMultipleInstallments(Customer."Payment Terms Code", NoOfInstallments);
        LibraryCarteraReceivables.CreateSalesInvoice(SalesHeader, Customer."No.");
        ClearSalesLineDiscount(SalesHeader."Document Type", SalesHeader."No.");
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Post-Setup
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.SetRange("Sell-to Customer No.", Customer."No.");
        SalesInvoiceLine.SetRange(Type, SalesInvoiceLine.Type::Item);
        SalesInvoiceLine.FindFirst();

        TotalAmount :=
          LibraryCarteraReceivables.GetPostedSalesInvoiceAmount(
            Customer."No.", DocumentNo, FirstInstallmentCustLedgerEntry."Document Type"::Invoice);

        VATPostingSetup.Get(SalesInvoiceLine."VAT Bus. Posting Group", SalesInvoiceLine."VAT Prod. Posting Group");

        InitialVATAmount :=
          Round(TotalAmount - TotalAmount * 100 / (VATPostingSetup."VAT %" + 100), LibraryERM.GetAmountRoundingPrecision());

        LibraryCarteraReceivables.FindOpenCarteraDocCustomerLedgerEntries(FirstInstallmentCustLedgerEntry,
          Customer."No.", DocumentNo, FirstInstallmentCustLedgerEntry."Document Situation"::Cartera,
          FirstInstallmentCustLedgerEntry."Document Type"::Bill);
        FirstInstallmentCustLedgerEntry.CalcFields("Original Amount");

        // Pre-Exercise
        CreditMemoAmount := Round(FirstInstallmentCustLedgerEntry."Original Amount" / 2, LibraryERM.GetAmountRoundingPrecision());
        CreateCreditMemoToCorrectInvoice(CreditMemoSalesHeader,
          Customer."No.", DocumentNo, SalesInvoiceLine."No.", 1, CreditMemoAmount);
        CreditMemoDocumentNo := LibrarySales.PostSalesDocument(CreditMemoSalesHeader, true, true);
        LibraryERM.FindCustomerLedgerEntry(CreditMemoCustLedgerEntry,
          CreditMemoCustLedgerEntry."Document Type"::"Credit Memo", CreditMemoDocumentNo);

        // Exercise
        ApplyCreditMemoToFirstInstallment(CreditMemoCustLedgerEntry."Entry No.");

        // Verify
        CreditMemoVATAmount := Round(CreditMemoAmount * VATPostingSetup."VAT %" / 100, LibraryERM.GetAmountRoundingPrecision());
        ValidateUnrVATGLEntriesAfterApplyingCreditMemo(SalesUnrealizedVATAccount, InitialVATAmount, CreditMemoVATAmount);
        ValidateUnrVATVendorEntriesAfterApplyingCreditMemo(Customer."No.", CreditMemoVATAmount, CreditMemoAmount);

        VerifyRemainingAmountOnFirstInstallment(CreditMemoCustLedgerEntry."Entry No.", FirstInstallmentCustLedgerEntry."Entry No.");
        VerifyRemainingAmountOnCarteraDocOfFirstInstallment(FirstInstallmentCustLedgerEntry."Entry No.", DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateCarteraDocumentWithMultipleInstallmentsLCY()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
        PaymentTerms: Record "Payment Terms";
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
        NoOfInstallments: Integer;
        TotalAmount: Decimal;
    begin
        Initialize();

        // Pre-Setup
        NoOfInstallments := 5;

        // Setup
        LibraryCarteraReceivables.CreateCarteraCustomer(Customer, LocalCurrencyCode);
        LibraryCarteraReceivables.CreateCustomerBankAccount(Customer, CustomerBankAccount);
        LibraryCarteraReceivables.SetPaymentTermsVatDistribution(Customer."Payment Terms Code",
          PaymentTerms."VAT distribution"::Proportional);
        LibraryCarteraReceivables.CreateMultipleInstallments(Customer."Payment Terms Code", NoOfInstallments);
        LibraryCarteraReceivables.CreateSalesInvoice(SalesHeader, Customer."No.");

        // Exercise
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Pre-Verify
        TotalAmount :=
          LibraryCarteraReceivables.GetPostedSalesInvoiceAmount(Customer."No.", DocumentNo, CustLedgerEntry."Document Type"::Invoice);

        // Verify
        ValidateInstallmentCustomerLedgerEntries(Customer."No.",
          DocumentNo, CustLedgerEntry."Document Situation"::Cartera, TotalAmount, NoOfInstallments);
        ValidateInstallmentCarteraDocuments(Customer."No.", DocumentNo, TotalAmount, NoOfInstallments);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateCarteraDocumentWithMultipleInstallmentsNonLCY()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
        PaymentTerms: Record "Payment Terms";
        SalesHeader: Record "Sales Header";
        CurrencyCode: Code[10];
        DocumentNo: Code[20];
        NoOfInstallments: Integer;
        TotalAmount: Decimal;
    begin
        Initialize();

        // Pre-Setup
        NoOfInstallments := 5;
        CurrencyCode := LibraryCarteraCommon.CreateCarteraCurrency(true, false, false);

        // Setup
        LibraryCarteraReceivables.CreateCarteraCustomer(Customer, CurrencyCode);
        LibraryCarteraReceivables.CreateCustomerBankAccount(Customer, CustomerBankAccount);
        LibraryCarteraReceivables.SetPaymentTermsVatDistribution(Customer."Payment Terms Code",
          PaymentTerms."VAT distribution"::Proportional);
        LibraryCarteraReceivables.CreateMultipleInstallments(Customer."Payment Terms Code", NoOfInstallments);
        LibraryCarteraReceivables.CreateSalesInvoice(SalesHeader, Customer."No.");

        // Exercise
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Pre-Verify
        TotalAmount :=
          LibraryCarteraReceivables.GetPostedSalesInvoiceAmount(Customer."No.", DocumentNo, CustLedgerEntry."Document Type"::Invoice);

        // Verify
        ValidateInstallmentCustomerLedgerEntries(Customer."No.",
          DocumentNo, CustLedgerEntry."Document Situation"::Cartera, TotalAmount, NoOfInstallments);
        ValidateInstallmentCarteraDocuments(Customer."No.", DocumentNo, TotalAmount, NoOfInstallments);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateCarteraDocumentWithSingleInstallment()
    var
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PaymentTerms: Record "Payment Terms";
        SalesHeader: Record "Sales Header";
        CurrencyCode: Code[10];
        DocumentNo: Code[20];
        NoOfInstallments: Integer;
        TotalAmount: Decimal;
    begin
        Initialize();

        // Pre-Setup
        NoOfInstallments := 1;

        // Setup
        CurrencyCode := LibraryCarteraCommon.CreateCarteraCurrency(true, false, false);
        LibraryCarteraReceivables.CreateCarteraCustomer(Customer, CurrencyCode);
        LibraryCarteraReceivables.CreateCustomerBankAccount(Customer, CustomerBankAccount);
        LibraryCarteraReceivables.SetPaymentTermsVatDistribution(Customer."Payment Terms Code",
          PaymentTerms."VAT distribution"::Proportional);
        LibraryCarteraReceivables.CreateMultipleInstallments(Customer."Payment Terms Code", NoOfInstallments);
        LibraryCarteraReceivables.CreateSalesInvoice(SalesHeader, Customer."No.");

        // Exercise
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Pre-Verify
        TotalAmount :=
          LibraryCarteraReceivables.GetPostedSalesInvoiceAmount(Customer."No.", DocumentNo, CustLedgerEntry."Document Type"::Invoice);

        // Verify
        ValidateInstallmentCustomerLedgerEntries(Customer."No.",
          DocumentNo, CustLedgerEntry."Document Situation"::Cartera, TotalAmount, NoOfInstallments);
        ValidateInstallmentCarteraDocuments(Customer."No.", DocumentNo, TotalAmount, NoOfInstallments);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateCarteraDocumentWithInstallmentsAndUnrealizedVAT()
    var
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PaymentTerms: Record "Payment Terms";
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
        NoOfInstallments: Integer;
        TotalAmount: Decimal;
        SalesUnrVATAccount: Code[20];
        PurchUnrVATAccount: Code[20];
    begin
        Initialize();

        // Pre-Setup
        NoOfInstallments := 1;

        LibraryCarteraCommon.SetupUnrealizedVAT(SalesUnrVATAccount, PurchUnrVATAccount);

        // Setup
        LibraryCarteraReceivables.CreateCarteraCustomerForUnrealizedVAT(Customer, LocalCurrencyCode);
        LibraryCarteraReceivables.CreateCustomerBankAccount(Customer, CustomerBankAccount);
        LibraryCarteraReceivables.SetPaymentTermsVatDistribution(Customer."Payment Terms Code",
          PaymentTerms."VAT distribution"::Proportional);
        LibraryCarteraReceivables.CreateMultipleInstallments(Customer."Payment Terms Code", NoOfInstallments);
        LibraryCarteraReceivables.CreateSalesInvoice(SalesHeader, Customer."No.");
        ClearSalesLineDiscount(SalesHeader."Document Type", SalesHeader."No.");

        // Exercise
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Pre-Verify
        TotalAmount :=
          LibraryCarteraReceivables.GetPostedSalesInvoiceAmount(Customer."No.", DocumentNo, CustLedgerEntry."Document Type"::Invoice);

        // Verify
        ValidateUnrVATGLEntries(DocumentNo, SalesUnrVATAccount, TotalAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotPostDocumentWithMultipleCarteraInstallmentsAndUnrealizedVAT()
    var
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
        PaymentMethod: Record "Payment Method";
        PaymentTerms: Record "Payment Terms";
        SalesHeader: Record "Sales Header";
        NoOfInstallments: Integer;
        SalesUnrVATAccount: Code[20];
        PurchUnrVATAccount: Code[20];
    begin
        Initialize();

        // Pre-Setup
        NoOfInstallments := 5;

        LibraryCarteraCommon.SetupUnrealizedVAT(SalesUnrVATAccount, PurchUnrVATAccount);

        // Setup
        LibraryCarteraReceivables.CreateCarteraCustomerForUnrealizedVAT(Customer, LocalCurrencyCode);
        LibraryCarteraReceivables.CreateCustomerBankAccount(Customer, CustomerBankAccount);
        LibraryCarteraReceivables.SetPaymentTermsVatDistribution(Customer."Payment Terms Code",
          PaymentTerms."VAT distribution"::Proportional);
        LibraryCarteraReceivables.CreateMultipleInstallments(Customer."Payment Terms Code", NoOfInstallments);
        LibraryCarteraReceivables.CreateSalesInvoice(SalesHeader, Customer."No.");

        // Exercise
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify
        // No. of Installments must be 1 if Invoices to Cartera is True in Payment Method
        Assert.ExpectedError(
          StrSubstNo('%1 must be 1 if %2 is True in %3', PaymentTerms.FieldCaption("No. of Installments"),
            PaymentMethod.FieldCaption("Invoices to Cartera"), PaymentMethod.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('InsertDocModelHandler,CheckDiscountCreditLimitModalPageHandler,ConfirmHandlerYes,PostBillGroupRequestPageHandler,CarteraJournalModalPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostCarteraDocumentWithInstallmentsAndDiscount()
    var
        BankAccount: Record "Bank Account";
        BillGroup: Record "Bill Group";
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        PaymentTerms: Record "Payment Terms";
        SalesHeader: Record "Sales Header";
        POPostAndPrint: Codeunit "BG/PO-Post and Print";
        BillGroupNo: Code[20];
        DocumentNo: Code[20];
        NoOfInstallments: Integer;
    begin
        Initialize();

        // Pre-Setup
        NoOfInstallments := 5;

        // Setup
        LibraryCarteraReceivables.CreateCarteraCustomer(Customer, LocalCurrencyCode);
        LibraryCarteraReceivables.CreateCustomerBankAccount(Customer, CustomerBankAccount);
        LibraryCarteraReceivables.SetPaymentTermsVatDistribution(Customer."Payment Terms Code",
          PaymentTerms."VAT distribution"::Proportional);
        LibraryCarteraReceivables.CreateMultipleInstallments(Customer."Payment Terms Code", NoOfInstallments);
        LibraryCarteraReceivables.CreateSalesInvoice(SalesHeader, Customer."No.");

        // Post-Setup
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Pre-Exercise
        LibraryCarteraReceivables.CreateBankAccount(BankAccount, LocalCurrencyCode);
        LibraryCarteraReceivables.CreateDiscountOperationFeesForBankAccount(BankAccount);
        BillGroupNo := LibraryCarteraReceivables.CreateBillGroup(BillGroup, BankAccount."No.", BillGroup."Dealing Type"::Discount);
        LibraryVariableStorage.Enqueue(DocumentNo);
        AddCarteraDocumentToBillGroup(BillGroup."No.");

        // Exercise
        LibraryCarteraReceivables.CreateCarteraJournalBatch(GenJournalBatch);
        Commit();
        LibraryVariableStorage.Enqueue(GenJournalBatch."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalBatch.Name);
        POPostAndPrint.ReceivablePostOnly(BillGroup);

        // Post-Exercise
        LibraryCarteraReceivables.PrepareCarteraDiscountJournalLines(GenJournalBatch);
        LibraryCarteraReceivables.PostCarteraJournalLines(GenJournalBatch.Name);

        // Verify
        ValidateCarteraDiscountGLEntries(BankAccount, BillGroupNo);

        // Teardown
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateCarteraSalesDocumentWithMultipleInstallmentsSmallAmount()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
        PaymentTerms: Record "Payment Terms";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
        NoOfInstallments: Integer;
        TotalAmount: Decimal;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 307483] Create cartera documents when Sales Document with small amount has Payment Terms of multiple installments
        Initialize();

        // [GIVEN] Sales Invoice has Payment Method with Create Bills = Yes and Payment Terms with 5 installments
        NoOfInstallments := LibraryRandom.RandIntInRange(2, 5);
        LibraryCarteraReceivables.CreateCarteraCustomer(Customer, LocalCurrencyCode);
        LibraryCarteraReceivables.CreateCustomerBankAccount(Customer, CustomerBankAccount);
        LibraryCarteraReceivables.SetPaymentTermsVatDistribution(Customer."Payment Terms Code",
          PaymentTerms."VAT distribution"::Proportional);
        LibraryCarteraReceivables.CreateMultipleInstallments(Customer."Payment Terms Code", NoOfInstallments);
        LibraryCarteraReceivables.CreateSalesInvoice(SalesHeader, Customer."No.");

        // [GIVEN] Amount of the invoice is 0.01
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        SalesLine.Validate(Quantity, 1);
        SalesLine.Validate("Unit Price", 0.01);
        SalesLine.Modify(true);

        // [WHEN] Post Sales Invoice
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] One Customer Ledger Entry with "Document Situation" = Cartera is created for amount = 0.01
        // [THEN] One Cartera Document is created for amount = 0.01 and BillNo = 1
        TotalAmount :=
          LibraryCarteraReceivables.GetPostedSalesInvoiceAmount(Customer."No.", DocumentNo, CustLedgerEntry."Document Type"::Invoice);
        ValidateInstallmentCustomerLedgerEntries(Customer."No.",
          DocumentNo, CustLedgerEntry."Document Situation"::Cartera, TotalAmount, 1);
        ValidateInstallmentCarteraDocuments(Customer."No.", DocumentNo, TotalAmount, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateCarteraServiceDocumentWithMultipleInstallmentsSmallAmount()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
        PaymentTerms: Record "Payment Terms";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        DocumentNo: Code[20];
        NoOfInstallments: Integer;
        TotalAmount: Decimal;
    begin
        // [FEATURE] [Service]
        // [SCENARIO 307483] Create cartera documents when Service Document with small amount has Payment Terms of multiple installments
        Initialize();

        // [GIVEN] Service Invoice has Payment Method with Create Bills = Yes and Payment Terms with 5 installments
        NoOfInstallments := LibraryRandom.RandIntInRange(2, 5);
        LibraryCarteraReceivables.CreateCarteraCustomer(Customer, LocalCurrencyCode);
        LibraryCarteraReceivables.CreateCustomerBankAccount(Customer, CustomerBankAccount);
        LibraryCarteraReceivables.SetPaymentTermsVatDistribution(Customer."Payment Terms Code",
          PaymentTerms."VAT distribution"::Proportional);
        LibraryCarteraReceivables.CreateMultipleInstallments(Customer."Payment Terms Code", NoOfInstallments);
        LibraryCarteraReceivables.CreateServiceInvoice(ServiceHeader, Customer."No.");

        // [GIVEN] Amount of the invoice is 0.01
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.FindFirst();
        ServiceLine.Validate(Quantity, 1);
        ServiceLine.Validate("Unit Price", 0.01);
        ServiceLine.Modify(true);

        // [WHEN] Post Service Invoice
        DocumentNo := LibraryUtility.GetNextNoFromNoSeries(ServiceHeader."Posting No. Series", WorkDate());
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] One Customer Ledger Entry with "Document Situation" = Cartera is created for amount = 0.01
        // [THEN] One Cartera Document is created for amount = 0.01 and BillNo = 1
        TotalAmount :=
          LibraryCarteraReceivables.GetPostedSalesInvoiceAmount(Customer."No.", DocumentNo, CustLedgerEntry."Document Type"::Invoice);
        ValidateInstallmentCustomerLedgerEntries(Customer."No.",
          DocumentNo, CustLedgerEntry."Document Situation"::Cartera, TotalAmount, 1);
        ValidateInstallmentCarteraDocuments(Customer."No.", DocumentNo, TotalAmount, 1);
    end;

    [Test]
    procedure VATIsFullyRealizedAfterSevPmtToBillApplicationsForSevInstallments()
    var
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
        SalesHeader: Record "Sales Header";
        VATEntry: Record "VAT Entry";
        DocumentNo: Code[20];
        SalesUnrVATAccount: Code[20];
        PurchUnrVATAccount: Code[20];
    begin
        // [FEATURE] [Unrealized VAT]
        // [SCENARIO 403927] Sales invoice unrealized VAT is fully realized after several payment to Bill applications
        // [SCENARIO 403927] in case of several installments
        Initialize();

        // [GIVEN] Unrealized VAT setup, payment term with 2 installments
        LibraryCarteraCommon.SetupUnrealizedVAT(SalesUnrVATAccount, PurchUnrVATAccount);
        LibraryCarteraReceivables.CreateCarteraCustomer(Customer, '');
        LibraryCarteraReceivables.SetPaymentTermsVatDistribution(
          Customer."Payment Terms Code", PaymentTerms."VAT distribution"::Proportional);
        LibraryCarteraReceivables.CreateMultipleInstallments(Customer."Payment Terms Code", 2);

        // [GIVEN] Posted sales invoice with 2 opened Bills
        LibraryCarteraReceivables.CreateSalesInvoice(SalesHeader, Customer."No.");
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Invoice);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindFirst();
        VATEntry.TestField("Unrealized Base");
        VATEntry.TestField("Unrealized Amount");
        VATEntry.TestField("Remaining Unrealized Base", VATEntry."Unrealized Base");
        VATEntry.TestField("Remaining Unrealized Amount", VATEntry."Unrealized Amount");

        // [GIVEN] Apply and post the first Bill
        ApplyPostFirstOpenBill(Customer."No.", DocumentNo);

        // [WHEN] Apply and post the second Bill
        ApplyPostFirstOpenBill(Customer."No.", DocumentNo);

        // [THEN] Original document unrealized VAT is fully realized
        VATEntry.Find();
        VATEntry.TestField("Remaining Unrealized Base", 0);
        VATEntry.TestField("Remaining Unrealized Amount", 0);
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesPageHandler,PostApplicationPageHandler,MessageHandler,UnapplyCustomerEntriesPageHandler,ConfirmHandlerYes')]
    procedure ValueOfRemainingAmountLCYStatWhenApplyAndUnApplyOfCustomerLedgerEntry()
    var
        SalesHeader: array[2] of Record "Sales Header";
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
        CustLedgerEntry: array[2] of Record "Cust. Ledger Entry";
        SalesInvoiceLine: Record "Sales Invoice Line";
        CustomerLedgerEntries: TestPage "Customer Ledger Entries";
        CreditMemoDocumentNo: Code[20];
        DocumentNo: Code[20];
        RemainingAmountLCYStats: Decimal;
    begin
        // [SCENARIO 575331] The "Remaining Amount (LCY) stats." field is correct after unapplying a Credit Memo.
        Initialize();

        // [GIVEN] Create Cartera Customer to use Cartera Payment.
        LibraryCarteraReceivables.CreateCarteraCustomer(Customer, LocalCurrencyCode);

        // [GIVEN] Create Customer Bank Account.
        LibraryCarteraReceivables.CreateCustomerBankAccount(Customer, CustomerBankAccount);

        // [GIVEN] Create Sales Invoice.
        LibraryCarteraReceivables.CreateSalesInvoice(SalesHeader[1], Customer."No.");

        // [GIVEN] Post Sales Document and store Document No.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader[1], true, true);

        // [GIVEN] Find Sales Invoice Line.
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.SetRange("Sell-to Customer No.", Customer."No.");
        SalesInvoiceLine.SetRange(Type, SalesInvoiceLine.Type::Item);
        SalesInvoiceLine.FindFirst();

        // [GIVEN] Find Open Customer Ledger Entry of Cartera Document.
        LibraryCarteraReceivables.FindOpenCarteraDocCustomerLedgerEntries(
          CustLedgerEntry[1],
          Customer."No.",
          DocumentNo,
          CustLedgerEntry[1]."Document Situation"::Cartera,
          CustLedgerEntry[1]."Document Type"::Bill);

        CustLedgerEntry[1].CalcFields("Original Amount");

        // [GIVEN] Store the Current Value of Remaining Amount LCY Stat.
        RemainingAmountLCYStats := CustLedgerEntry[1]."Remaining Amount (LCY) stats.";

        // [GIVEN] Create Corrective Credit Memo.
        CreateCreditMemoToCorrectInvoice(
          SalesHeader[2],
          Customer."No.",
          DocumentNo,
          SalesInvoiceLine."No.",
          LibraryRandom.RandIntInRange(1, 1),
          CustLedgerEntry[1]."Original Amount" / 2);

        // [GIVEN] Post Purchase Credit Memo and store Document No.
        CreditMemoDocumentNo := LibrarySales.PostSalesDocument(SalesHeader[2], true, true);

        // [GIVEN] Find Customer Ledger Entry of Credit Memo.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry[2], CustLedgerEntry[2]."Document Type"::"Credit Memo", CreditMemoDocumentNo);

        // [GIVEN] Apply Customer Ledger Entry.
        ApplyCreditMemoToFirstInstallment(CustLedgerEntry[2]."Entry No.");

        // [WHEN] Unapply the Customer Leger Entry.
        CustomerLedgerEntries.OpenEdit();
        CustomerLedgerEntries.GotoKey(CustLedgerEntry[2]."Entry No.");
        CustomerLedgerEntries.UnapplyEntries.Invoke();

        // [THEN] Remaining Amount (LCY) stats. must be restored into previous value.
        CustLedgerEntry[1].Get(CustLedgerEntry[1]."Entry No.");
        Assert.AreEqual(
          RemainingAmountLCYStats,
          CustLedgerEntry[1]."Remaining Amount (LCY) stats.",
          StrSubstNo(
            RemainingAmountLCYstatsErr,
            RemainingAmountLCYStats,
            CustLedgerEntry[1].TableName()));
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        LibraryCarteraCommon.RevertUnrealizedVATPostingSetup();
        LocalCurrencyCode := '';
    end;

    local procedure CreateCreditMemoToCorrectInvoice(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; CorrectedInvoiceNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; UnitPrice: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CustomerNo);
        SalesHeader.Validate("Corrected Invoice No.", CorrectedInvoiceNo);
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

    local procedure ApplyCreditMemoToFirstInstallment(EntryNo: Integer)
    var
        CustomerLedgerEntries: TestPage "Customer Ledger Entries";
    begin
        CustomerLedgerEntries.OpenEdit();
        CustomerLedgerEntries.GotoKey(EntryNo);
        CustomerLedgerEntries."Apply Entries".Invoke();
    end;

    local procedure ApplyPostFirstOpenBill(CustomerNo: Code[20]; DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange(Open, true);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Bill, DocumentNo);
        CustLedgerEntry.CalcFields(Amount);
        CustLedgerEntry.Validate("Applies-to ID", LibraryUtility.GenerateGUID());
        CustLedgerEntry.Validate("Amount to Apply", CustLedgerEntry.Amount);
        CustLedgerEntry.Modify(true);

        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, CustomerNo, -CustLedgerEntry.Amount);
        GenJournalLine.Validate("Applies-to ID", CustLedgerEntry."Applies-to ID");
        GenJournalLine.Modify(true);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries."Set Applies-to ID".Invoke();
        ApplyCustomerEntries."Post Application".Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostApplicationPageHandler(var PostApplication: TestPage "Post Application")
    begin
        PostApplication.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    local procedure VerifyRemainingAmountOnFirstInstallment(ApplyingCustLedgerEntryNo: Integer; AppliedToCustLedgerEntryNo: Integer)
    var
        AppliedToCustLedgerEntry: Record "Cust. Ledger Entry";
        ApplyingCustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        ApplyingCustLedgerEntry.Get(ApplyingCustLedgerEntryNo);
        ApplyingCustLedgerEntry.TestField(Open, false);
        ApplyingCustLedgerEntry.CalcFields("Remaining Amount");
        ApplyingCustLedgerEntry.TestField("Remaining Amount", 0);

        AppliedToCustLedgerEntry.Get(AppliedToCustLedgerEntryNo);
        AppliedToCustLedgerEntry.TestField(Open, true);
        AppliedToCustLedgerEntry.CalcFields("Original Amount", "Remaining Amount");
        Assert.IsTrue(AppliedToCustLedgerEntry."Remaining Amount" > 0, '');
        Assert.IsTrue(AppliedToCustLedgerEntry."Remaining Amount" < AppliedToCustLedgerEntry."Original Amount", '');
    end;

    local procedure VerifyRemainingAmountOnCarteraDocOfFirstInstallment(AppliedToCustLedgerEntryNo: Integer; DocumentNo: Code[20])
    var
        AppliedToCustLedgerEntry: Record "Cust. Ledger Entry";
        CarteraDoc: Record "Cartera Doc.";
        ReceivablesCarteraDocs: TestPage "Receivables Cartera Docs";
    begin
        AppliedToCustLedgerEntry.Get(AppliedToCustLedgerEntryNo);
        AppliedToCustLedgerEntry.CalcFields("Remaining Amount");

        CarteraDoc.SetRange(Type, CarteraDoc.Type::Receivable);
        CarteraDoc.SetRange("Document No.", DocumentNo);
        CarteraDoc.SetRange("No.", '1');
        CarteraDoc.FindFirst();

        ReceivablesCarteraDocs.OpenView();
        ReceivablesCarteraDocs.GotoRecord(CarteraDoc);
        ReceivablesCarteraDocs."Remaining Amount".AssertEquals(AppliedToCustLedgerEntry."Remaining Amount");
    end;

    local procedure ClearSalesLineDiscount(DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        // Remove the line discount - without it we would get more GL/Lines
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.ModifyAll(SalesLine."Line Discount %", 0, true);
        SalesLine.ModifyAll(SalesLine."Line Discount Amount", 0, true);
    end;

    local procedure ValidateCarteraDiscountGLEntries(BankAccount: Record "Bank Account"; BillGroupNo: Code[20])
    var
        BankAccountPostingGroup: Record "Bank Account Posting Group";
        GLEntry: Record "G/L Entry";
        OperationFee: Record "Operation Fee";
        PostedBillGroup: Record "Posted Bill Group";
        DiscountExpenses: Decimal;
        DiscountInterests: Decimal;
    begin
        PostedBillGroup.Get(BillGroupNo);
        BankAccountPostingGroup.Get(BankAccount."Bank Acc. Posting Group");

        OperationFee.Get(BankAccount."No.", BankAccount."Currency Code", OperationFee."Type of Fee"::"Discount Expenses");
        DiscountExpenses := OperationFee."Charge Amt. per Operation";
        PostedBillGroup.TestField("Discount Expenses Amt.", DiscountExpenses);
        LibraryCarteraReceivables.FindGLEntry(GLEntry, BillGroupNo, BankAccountPostingGroup."Bank Services Acc.");
        GLEntry.TestField("Debit Amount", DiscountExpenses);

        OperationFee.Get(BankAccount."No.", BankAccount."Currency Code", OperationFee."Type of Fee"::"Discount Interests");
        DiscountInterests := OperationFee."Charge Amt. per Operation";
        PostedBillGroup.TestField("Discount Interests Amt.", DiscountInterests);
        LibraryCarteraReceivables.FindGLEntry(GLEntry, BillGroupNo, BankAccountPostingGroup."Discount Interest Acc.");
        GLEntry.TestField("Debit Amount", DiscountInterests);

        PostedBillGroup.CalcFields(Amount);
        LibraryCarteraReceivables.FindGLEntry(GLEntry, BillGroupNo, BankAccountPostingGroup."G/L Account No.");
        GLEntry.TestField("Debit Amount", PostedBillGroup.Amount - (DiscountExpenses + DiscountInterests));
    end;

    local procedure ValidateInstallmentCarteraDocuments(AccountNo: Code[20]; DocumentNo: Code[20]; TotalAmount: Decimal; NoOfInstallments: Integer)
    var
        CarteraDoc: Record "Cartera Doc.";
        PaymentTerms: Record "Payment Terms";
        Index: Integer;
        CarteraDocsTotalAmount: Decimal;
    begin
        LibraryCarteraReceivables.FindCarteraDocs(CarteraDoc, AccountNo, DocumentNo);
        Assert.AreEqual(NoOfInstallments, CarteraDoc.Count,
          StrSubstNo(CountMismatchErr, CarteraDoc.TableCaption(), PaymentTerms.FieldCaption("No. of Installments")));

        CarteraDocsTotalAmount := 0;

        repeat
            Index += 1;
            CarteraDoc.TestField("No.", Format(Index));
            CarteraDoc.TestField(Description, StrSubstNo('%1 %2/%3', CarteraDoc."Document Type", DocumentNo, Index));
            Assert.IsTrue(((TotalAmount / NoOfInstallments) - CarteraDoc."Remaining Amount") < 1, '');
            CarteraDocsTotalAmount += CarteraDoc."Remaining Amount"
        until CarteraDoc.Next() = 0;

        Assert.AreEqual(TotalAmount, CarteraDocsTotalAmount, 'There is a rounding error.');
    end;

    local procedure ValidateInstallmentCustomerLedgerEntries(CustomerNo: Code[20]; DocumentNo: Code[20]; DocumentSituation: Enum "ES Document Situation"; TotalAmount: Decimal; NoOfInstallments: Integer)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PaymentTerms: Record "Payment Terms";
        Index: Integer;
        CustomerLedgerTotalAmount: Decimal;
    begin
        LibraryCarteraReceivables.FindOpenCarteraDocCustomerLedgerEntries(CustLedgerEntry,
          CustomerNo, DocumentNo, DocumentSituation, CustLedgerEntry."Document Type"::Bill);
        Assert.AreEqual(NoOfInstallments, CustLedgerEntry.Count,
          StrSubstNo(CountMismatchErr, CustLedgerEntry.TableCaption(), PaymentTerms.FieldCaption("No. of Installments")));

        CustomerLedgerTotalAmount := 0;

        repeat
            Index += 1;
            CustLedgerEntry.TestField("Bill No.", Format(Index));
            CustLedgerEntry.TestField(Description, StrSubstNo('%1 %2/%3', CustLedgerEntry."Document Type", DocumentNo, Index));
            CustLedgerEntry.CalcFields(Amount);
            Assert.IsTrue(((TotalAmount / NoOfInstallments) - CustLedgerEntry.Amount) < 1, '');
            CustomerLedgerTotalAmount += CustLedgerEntry.Amount;
        until CustLedgerEntry.Next() = 0;

        Assert.AreEqual(TotalAmount, CustomerLedgerTotalAmount, 'There is a rounding error.');
    end;

    local procedure ValidateUnrVATGLEntries(DocumentNo: Code[20]; VATAccountNo: Code[20]; TotalAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        TotalCreditAmount: Decimal;
        TotalDebitAmount: Decimal;
        ExpectedVATAmount: Decimal;
    begin
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Invoice);
        GLEntry.SetRange("Document No.", DocumentNo);

        Assert.AreEqual(3, GLEntry.Count, 'Unexpected number of GL entries.');

        GLEntry.Find('-');
        VATPostingSetup.Get(GLEntry."VAT Bus. Posting Group", GLEntry."VAT Prod. Posting Group");
        TotalCreditAmount := GLEntry."Credit Amount";
        Assert.IsTrue(TotalCreditAmount > 0, 'Total Credit Amount has a wrong value');

        GLEntry.Next();
        ExpectedVATAmount :=
          Round(TotalAmount - TotalAmount * 100 / (VATPostingSetup."VAT %" + 100), LibraryERM.GetAmountRoundingPrecision());

        Assert.IsTrue(ExpectedVATAmount > 0, 'Expected VAT Amount must be greater than zero for this test');
        Assert.AreEqual(ExpectedVATAmount, GLEntry."Credit Amount", 'Wrong VAT Amount was set on the line');
        Assert.AreEqual(VATAccountNo, GLEntry."G/L Account No.", 'Wrong account is set on the line');

        GLEntry.Next();
        TotalDebitAmount := GLEntry."Debit Amount";
        Assert.IsTrue(TotalDebitAmount > 0, 'Total Amount without VAT should be greater than zero');
        Assert.AreEqual(TotalAmount, TotalDebitAmount, 'Wrong total value was set on line');

        // Verify numbers add up
        Assert.AreEqual(TotalDebitAmount, TotalCreditAmount + ExpectedVATAmount, 'Total Credit and Debit Amounts do not add up');
    end;

    local procedure ValidateUnrVATGLEntriesAfterApplyingCreditMemo(AccountNo: Code[20]; InitialVATAmount: Decimal; CreditMemoVATAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("G/L Account No.", AccountNo);
        GLEntry.Find('-');
        Assert.AreEqual(InitialVATAmount, GLEntry."Credit Amount", 'Wrong amount for the Initial VAT Amount');

        GLEntry.Next();
        Assert.AreEqual(CreditMemoVATAmount, GLEntry."Debit Amount", 'Wrong amount for Credit Memo Amount');

        GLEntry.Next();
        Assert.AreEqual(CreditMemoVATAmount, GLEntry."Debit Amount", 'Wrong amount for Credit Memo Amount');

        GLEntry.Next();
        Assert.AreEqual(CreditMemoVATAmount, GLEntry."Credit Amount", 'Wrong amount for Applied Credit Memo Amount');

        Assert.IsTrue(GLEntry.Next() = 0, 'Too many G/L entries were found after posting and applying a Credit Memo');
    end;

    local procedure ValidateUnrVATVendorEntriesAfterApplyingCreditMemo(VendorNo: Code[20]; CreditMemoVATAmount: Decimal; CreditMemoBaseAmount: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Bill-to/Pay-to No.", VendorNo);

        VATEntry.Find('-');
        Assert.AreEqual(0, VATEntry.Amount, 'Wrong value for the VAT entry for Amount on Invoice');
        Assert.AreEqual(0, VATEntry.Base, 'Wrong value for the VAT entry for Base on Invoice');
        Assert.AreEqual(VATEntry."Document Type"::Invoice, VATEntry."Document Type", 'Wrong document type on the line');

        VATEntry.Next();
        Assert.AreEqual(0, VATEntry.Amount, 'Wrong value for the VAT entry for Amount on Credit Memo');
        Assert.AreEqual(0, VATEntry.Base, 'Wrong value for the VAT entry for Base on Credit Memo');
        Assert.AreEqual(VATEntry."Document Type"::"Credit Memo", VATEntry."Document Type", 'Wrong document type on the line');

        VATEntry.Next();
        Assert.AreEqual(-1 * CreditMemoVATAmount, VATEntry.Amount, 'Wrong value for the VAT entry for Amount on Credit Memo');
        Assert.AreEqual(-1 * CreditMemoBaseAmount, VATEntry.Base, 'Wrong value for the VAT entry for Base on Credit Memo');
        Assert.AreEqual(VATEntry."Document Type"::"Credit Memo", VATEntry."Document Type", 'Wrong document type on the line');

        VATEntry.Next();
        Assert.AreEqual(CreditMemoVATAmount, VATEntry.Amount, 'Wrong value for the VAT entry for Amount on Credit Memo');
        Assert.AreEqual(CreditMemoBaseAmount, VATEntry.Base, 'Wrong value for the VAT entry for Base on Credit Memo');
        Assert.AreEqual(VATEntry."Document Type"::"Credit Memo", VATEntry."Document Type", 'Wrong document type on the line');

        Assert.IsTrue(VATEntry.Next() = 0, 'Too many VAT Entries were found after posting and applying a Credit Memo');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CarteraJournalModalPageHandler(var CarteraJournal: Page "Cartera Journal"; var Response: Action)
    begin
        CarteraJournal.AllowClosing(true);
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

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    local procedure AddCarteraDocumentToBillGroup(BillGroupNo: Code[20])
    var
        BillGroup: Record "Bill Group";
        BillGroupsTestPage: TestPage "Bill Groups";
    begin
        BillGroup.Get(BillGroupNo);
        BillGroupsTestPage.OpenEdit();
        BillGroupsTestPage.GotoRecord(BillGroup);
        BillGroupsTestPage.Docs.Insert.Invoke();
        BillGroupsTestPage.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure InsertDocModelHandler(var CarteraDocumentsPage: Page "Cartera Documents"; var Response: Action)
    var
        CarteraDoc: Record "Cartera Doc.";
        DocumentNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNo);

        CarteraDoc.SetRange("Document No.", DocumentNo);
        CarteraDoc.FindLast();
        CarteraDocumentsPage.SetRecord(CarteraDoc);

        Response := ACTION::LookupOK;
    end;

    [ModalPageHandler]
    procedure UnapplyCustomerEntriesPageHandler(var UnapplyCustomerEntries: TestPage "Unapply Customer Entries")
    begin
        UnapplyCustomerEntries.Unapply.Invoke();
    end;
}

