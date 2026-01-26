codeunit 134043 "ERM Additional Currency"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Additional Currency] [Currency Adjustment]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryJournals: Codeunit "Library - Journals";
        Assert: Codeunit Assert;
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        AmountErr: Label '%1 must be %2 in %3.';
        FiscalPostingDateTok: Label 'C%1', Locked = true;
        ExchRateWasAdjustedTxt: Label 'One or more currency exchange rates have been adjusted.';
        AdjustExchRateDefaultDescTxt: Label 'Adjmt. of %1 %2, Ex.Rate Adjust.', Locked = true;
        BankExchRateAdjustedErr: Label 'Bank Exch Rate should be Adjusted for %1', Comment = '%1 = Bank Account No.';
        AmountLCYError: Label 'Amount LCY must be %1.', Comment = '%1 = Amount (LCY)';

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseAdditionalCurrencyAmt()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GeneralPostingSetup: Record "General Posting Setup";
        CurrencyCode: Code[10];
        PurchInvoiceNo: Code[20];
        AdditionalCurrencyAmount: Decimal;
        VATAmount: Decimal;
        OriginalVATBase: Decimal;
    begin
        // Verify Additional Currency Amount in GL Entry and VAT Entry after Posting Purchase Invoice.

        // Setup: Update Purchase Payables Setup and Update General Posting Setup. Create Purchase Invoice and
        // Calculate Additional Currency Amount and VAT Amount.

        Initialize();
        CurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();
        LibraryERM.SetAddReportingCurrency(CurrencyCode);
        LibraryPurchase.SetCalcInvDiscount(true);
        OriginalVATBase := -Round(CreatePurchaseInvoiceCalcDisc(PurchaseHeader, PurchaseLine));
        UpdateGeneralPostingSetup(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        AdditionalCurrencyAmount := LibraryERM.ConvertCurrency(OriginalVATBase, '', CurrencyCode, WorkDate());
        VATAmount := Round(AdditionalCurrencyAmount * PurchaseLine."VAT %" / 100);

        // Exercise: Post Purchase Invoice and Find Purchase Invoice Header.
        PurchInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify GL Entry and VAT Entry for Additional Currency Amount.
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        VerifyGLEntry(PurchInvoiceNo, GeneralPostingSetup."Purch. Line Disc. Account", AdditionalCurrencyAmount);
        VerifyVATEntry(PurchInvoiceNo, VATAmount, OriginalVATBase);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesAdditionalCurrencyAmt()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GeneralPostingSetup: Record "General Posting Setup";
        CurrencyCode: Code[10];
        SalesInvoiceNo: Code[20];
        AdditionalCurrencyAmount: Decimal;
        VATAmount: Decimal;
        OriginalVATBase: Decimal;
    begin
        // Verify Additional Currency Amount in GL Entry and VAT Entry after Posting Sales Invoice.

        // Setup: Update Sales Receivables Setup and General Posting Setup. Create Sales Invoice and Calculate Additional Currency Amount
        // and VAT Amount.

        Initialize();
        CurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();
        LibraryERM.SetAddReportingCurrency(CurrencyCode);
        LibrarySales.SetCalcInvDiscount(true);
        OriginalVATBase := Round(CreateSalesInvoiceCalcDisc(SalesHeader, SalesLine));
        UpdateGeneralPostingSetup(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        AdditionalCurrencyAmount := LibraryERM.ConvertCurrency(OriginalVATBase, '', CurrencyCode, WorkDate());
        VATAmount := Round(AdditionalCurrencyAmount * SalesLine."VAT %" / 100);

        // Exercise: Post Sales Invoice and Find Sales Invoice Header.
        SalesInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify GL Entry and VAT Entry for Additional Currency Amount.
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        VerifyGLEntry(SalesInvoiceNo, GeneralPostingSetup."Sales Line Disc. Account", AdditionalCurrencyAmount);
        VerifyVATEntry(SalesInvoiceNo, VATAmount, OriginalVATBase);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvAdditionalCurr()
    var
        SalesLine: Record "Sales Line";
        GeneralPostingSetup: Record "General Posting Setup";
        CurrencyCode: Code[10];
        SalesInvoiceNo: Code[20];
        AdditionalCurrencyAmount: Decimal;
    begin
        // Check Additional Currency Amount in GL Entry and VAT Entry after Posting Sales Invoice.

        // Setup: Create and Post Sales Invoice and Calculate Additional Currency and VAT Amount.
        Initialize();
        CurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();
        LibraryERM.SetAddReportingCurrency(CurrencyCode);
        AdditionalCurrencyAmount := CreateAndPostSalesInvoice(SalesLine, SalesInvoiceNo, CurrencyCode);

        // Verify: Verify GL Entry for Additional Currency Amount after Posting Sales Invoice.
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        VerifyGLEntry(SalesInvoiceNo, GeneralPostingSetup."Sales Account", -AdditionalCurrencyAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvAdditionalCurrWithPmt()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SalesLine: Record "Sales Line";
        CurrencyCode: Code[10];
        SalesInvoiceNo: Code[20];
        AdditionalCurrencyAmount: Decimal;
    begin
        // Check Additional Currency Amount in GL Entry after Posting Sales Invoice and Payment with General Line.

        // Setup: Create and Post Sales Invoice and Calculate Additional Currency.
        Initialize();
        CurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();
        LibraryERM.SetAddReportingCurrency(CurrencyCode);
        AdditionalCurrencyAmount := CreateAndPostSalesInvoice(SalesLine, SalesInvoiceNo, CurrencyCode);

        // Exercise: Create Payment with Posted Sales Invoice.
        CreateAndPostGeneralLine(
          GenJournalLine, SalesLine."Sell-to Customer No.", -SalesLine."Line Amount", SalesInvoiceNo,
          '', GenJournalLine."Document Type"::Payment);

        // Verify: Verify GL Entry for Additional Currency Amount.
        VerifyGLEntry(GenJournalLine."Document No.", GenJournalLine."Bal. Account No.", AdditionalCurrencyAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvAdditionalCurrGLAct()
    var
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        SalesLine: Record "Sales Line";
        CurrencyCode: Code[10];
        SalesInvoiceNo: Code[20];
        AdditionalCurrencyAmount: Decimal;
    begin
        // Check Additional Currency Fields Value in GL Account after Posting Sales Invoice and Payment with General Line.

        // Setup: Create and Post Sales Invoice and Post Payment Entry and Calculate Additional Currency.
        Initialize();
        CurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();
        LibraryERM.SetAddReportingCurrency(CurrencyCode);
        AdditionalCurrencyAmount := CreateAndPostSalesInvoice(SalesLine, SalesInvoiceNo, CurrencyCode);

        // Exercise: Create Payment with Posted Sales Invoice.
        CreateAndPostGeneralLine(
          GenJournalLine, SalesLine."Sell-to Customer No.", -SalesLine."Line Amount", SalesInvoiceNo, '',
          GenJournalLine."Document Type"::Payment);
        GLAccount.Get(GenJournalLine."Bal. Account No.");
        GLAccount.CalcFields("Additional-Currency Net Change", "Add.-Currency Balance at Date", "Additional-Currency Balance");

        // Verify: Verify GL Account for Additional Currency fields Values.
        VerifyGLAccount(
          AdditionalCurrencyAmount, GLAccount."Additional-Currency Net Change", GLAccount.FieldCaption("Additional-Currency Net Change"));
        VerifyGLAccount(
          AdditionalCurrencyAmount, GLAccount."Add.-Currency Balance at Date", GLAccount.FieldCaption("Add.-Currency Balance at Date"));
        VerifyGLAccount(
          AdditionalCurrencyAmount, GLAccount."Additional-Currency Balance", GLAccount.FieldCaption("Additional-Currency Balance"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATBaseWithPostedGenLine()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        VATPostingSetup: Record "VAT Posting Setup";
        CurrencyCode: Code[10];
        VATBase: Decimal;
    begin
        // Check Base amount on VAT entry after Posting General Line with Currency.

        // Setup: Update Addtional Currency and Post General Line with Currency and Random Values.
        Initialize();
        CurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();
        LibraryERM.SetAddReportingCurrency(CurrencyCode);

        SelectGenJournalBatch(GenJournalBatch);
        if not GenJournalBatch."Copy VAT Setup to Jnl. Lines" then begin
            GenJournalBatch."Copy VAT Setup to Jnl. Lines" := true;
            GenJournalBatch.Modify();
        end;
        CreateGLAccountWithVAT(GLAccount, VATPostingSetup);
        GLAccount.Validate("Gen. Posting Type", GLAccount."Gen. Posting Type"::Sale);
        GLAccount.Modify(true);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", GLAccount."No.", LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::Customer);
        GenJournalLine.Validate("Bal. Account No.", CreateCustomer());
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);
        VATBase := GenJournalLine.Amount - ((GenJournalLine.Amount * GenJournalLine."VAT %") / (GenJournalLine."VAT %" + 100));
        VATBase := Round(LibraryERM.ConvertCurrency(VATBase, CurrencyCode, '', WorkDate()));

        // Exercise.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify VAT Entry for Base Amount after Updating Addtional Currency.
        VerifyVATEntryForBase(GenJournalLine."Document No.", VATBase);
    end;

    [Test]
    [HandlerFunctions('FiscalYearConfirmHandler,CloseIncomeStatementReportHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure FiscalYearAdditionalCurrency()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        CurrencyCode: Code[10];
        PostingDate: Date;
        AdditionalCurrencyAmount: Decimal;
    begin
        // Check Amount on GL Entry After Running Close Income Statement with Closing Fiscal Year.

        // Setup: Close Already Opened Fiscal Year. Create New One, Update New currency on General Ledger Setup.
        // Create General Line and Post them with Random Values.
        Initialize();
        LibraryFiscalYear.CloseFiscalYear();
        LibraryFiscalYear.CreateFiscalYear();
        PostingDate := LibraryFiscalYear.GetFirstPostingDate(false);

        CurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();
        LibraryERM.SetAddReportingCurrency(CurrencyCode);

        SelectGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", GLAccount."No.", -LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify(true);
        AdditionalCurrencyAmount := Round(LibraryERM.ConvertCurrency(GenJournalLine.Amount, '', CurrencyCode, WorkDate()));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Close Newly Created Fiscal Year. Customized Date formula required to calculate Fiscal Ending Date.
        LibraryFiscalYear.CloseFiscalYear();
        PostingDate := CalcDate('<1M-1D>', LibraryFiscalYear.GetLastPostingDate(true));

        // Exercise: Run Close Income Statement Batch Report.
        RunCloseIncomeStatementBatchJob(GenJournalLine, PostingDate);

        // Verify: Verify GL Entry for Fiscal Year Ending Date.
        Evaluate(PostingDate, StrSubstNo(FiscalPostingDateTok, PostingDate));
        VerifyGLEntryForFiscalYear(PostingDate, GenJournalLine."Account No.", -GenJournalLine.Amount, -AdditionalCurrencyAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GeneralLineWithoutCurr()
    begin
        // Check Payment Discount Date and Amount on Customer Ledger Entry after Posting Invoice without Currency.
        Initialize();
        PostAndVerifyGeneralEntry('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GeneralLineWithCurr()
    begin
        // Check Payment Discount Date and Amount on Customer Ledger Entry after Posting Invoice with Currency.
        Initialize();
        PostAndVerifyGeneralEntry(LibraryERM.CreateCurrencyWithRandomExchRates());
    end;

    local procedure PostAndVerifyGeneralEntry(CurrencyCode: Code[10])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PaymentTerms: Record "Payment Terms";
        GenJournalLine: Record "Gen. Journal Line";
        DiscountDate: Date;
    begin
        // Setup: Create and Post General Line with Randome Values.
        CreateGeneralLine(
          GenJournalLine, CreateCustomer(), CurrencyCode, GenJournalLine."Document Type"::Invoice, LibraryRandom.RandDec(100, 2));
        PaymentTerms.Get(GenJournalLine."Payment Terms Code");
        DiscountDate := CalcDate(PaymentTerms."Discount Date Calculation", GenJournalLine."Posting Date");

        // Exericse.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify Customer Ledger Entry with Discount Date and Amount.
        VerifyCustLedgerEntry(CustLedgerEntry."Document Type"::Invoice, GenJournalLine."Document No.", DiscountDate, GenJournalLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyInvoiceWithCreditMemo()
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Payment Discount Date and Amount on Customer Ledger Entry and Detailed Customer Ledger Entry after Posting Invoice
        // and Apply Credit Memo without Currency.
        Initialize();
        ApplyAndPostCreditMemo(GenJournalLine, '', '');

        // Exercise.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify Customer Ledger Entry and Detailed Customer Entry with Discount Date and Amount.
        VerifyCustLedgerEntry(CustLedgerEntry."Document Type"::"Credit Memo", GenJournalLine."Document No.", 0D, GenJournalLine.Amount);
        VerifyDetailedCustLedgerEntry(
          DetailedCustLedgEntry."Document Type"::"Credit Memo", GenJournalLine."Document No.", GenJournalLine.Amount,
          GenJournalLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyInvoiceWithCreditMemoCurr()
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        AmountLCY: Decimal;
    begin
        // Check Payment Discount Date and Amount on Customer Ledger Entry and Detailed Customer Ledger Entry after Posting Invoice
        // and Apply Credit Memo with Different Currency.
        Initialize();
        ApplyAndPostCreditMemo(GenJournalLine, LibraryERM.CreateCurrencyWithRandomExchRates(), LibraryERM.CreateCurrencyWithRandomExchRates());

        // Exercise: Convert Amount LCY According to Currency and Post General Line.
        AmountLCY := LibraryERM.ConvertCurrency(GenJournalLine.Amount, GenJournalLine."Currency Code", '', WorkDate());
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify Customer Ledger Entry and Detailed Customer Entry with Discount Date and Amount, Amount LCY.
        VerifyCustLedgerEntry(CustLedgerEntry."Document Type"::"Credit Memo", GenJournalLine."Document No.", 0D, GenJournalLine.Amount);
        VerifyDetailedCustLedgerEntry(
          DetailedCustLedgEntry."Document Type"::"Credit Memo", GenJournalLine."Document No.", GenJournalLine.Amount, AmountLCY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostJournalWithACYBank()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        CurrencyFCY: Code[10];
        CurrencyACY: Code[10];
        BankAccountNo: Code[20];
        AddnlReportingCurrencyAmount: Decimal;
    begin
        // Verify Additional Currency Amount in GL Entry after Posting General Journal Line for Bank.

        // 1. Setup: Update Additional Currency in General Ledger Setup. Run Additional Currency Reporting Report for ACY.
        Initialize();
        CreateCurrencies(CurrencyACY, CurrencyFCY);
        UpdateRunAddnReportingCurrency(CurrencyACY, CurrencyACY);

        BankAccountNo := CreateBankAccountWithCurrency(CurrencyFCY);

        // 2. Exercise: Create and Post General Journal Line with Random Values.
        CreateJournalLineForInvoice(
          GenJournalLine, GenJournalLine."Account Type"::"Bank Account", BankAccountNo, LibraryRandom.RandDec(100, 2) + 100);
        ModifyGeneralJournalLine(GenJournalLine, GenJournalLine."Bal. Gen. Posting Type"::Purchase, CurrencyFCY);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        AddnlReportingCurrencyAmount := CalculateAdditionalAmount(CurrencyExchangeRate, CurrencyACY, GenJournalLine."Amount (LCY)");

        // 3. Verify: Verify G/L Entry for Additional Currency Amount.
        VerifyGLEntryForACY(GenJournalLine, AddnlReportingCurrencyAmount);
    end;

    [Test]
    [HandlerFunctions('StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure AdjustExchangeRateBankACY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        CurrencyFCY: Code[10];
        CurrencyACY: Code[10];
        BankAccountNo: Code[20];
        AddnlReportingCurrencyAmount: Decimal;
    begin
        // Post General Journal Line for Bank and Run Adjust Exchange Rate for ACY after changing Currency Exchange Rate.

        // 1. Setup: Update Additional Currency in General Ledger Setup. Run Additional Currency Reporting Report.
        // Create and Post General Journal Line with Random Values.
        Initialize();
        CreateCurrencies(CurrencyACY, CurrencyFCY);
        UpdateRunAddnReportingCurrency(CurrencyACY, CurrencyACY);

        BankAccountNo := CreateBankAccountWithCurrency(CurrencyFCY);

        CreateJournalLineForInvoice(
          GenJournalLine, GenJournalLine."Account Type"::"Bank Account", BankAccountNo, LibraryRandom.RandDec(100, 2) + 100);
        ModifyGeneralJournalLine(GenJournalLine, GenJournalLine."Bal. Gen. Posting Type"::Purchase, CurrencyFCY);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 2. Exercise: Modify Exchange Rate for Additional Reporting Currency and Run Adjust Exchange Rate Batch.
        AddnlReportingCurrencyAmount := CalculateAdditionalAmount(CurrencyExchangeRate, CurrencyACY, GenJournalLine."Amount (LCY)");
        ModifyCurrencyExchangeRate(CurrencyExchangeRate);
        RunAdjustExchangeRates(CurrencyExchangeRate, BankAccountNo);

        // 3. Verify: Verify G/L Entry for Additional Currency Amount. Bank Account Ledger for Adjust Exchange Rate Entry.
        VerifyGLEntryForACY(GenJournalLine, AddnlReportingCurrencyAmount);
        VerifyAdjExchEntryBankExists(BankAccountNo, GenJournalLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure AdjustExchangeRateBankFCY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        CurrencyFCY: Code[10];
        CurrencyACY: Code[10];
        BankAccountNo: Code[20];
        AddnlReportingCurrencyAmount: Decimal;
    begin
        // Post General Journal Line for Bank and Run Adjust Exchange Rate for ACY after changing Currency Exchange Rate.

        // 1. Setup: Update Additional Currency in General Ledger Setup. Run Additional Currency Reporting Report.
        // Create and Post General Journal Line with Random Values.
        Initialize();
        CreateCurrencies(CurrencyACY, CurrencyFCY);
        UpdateRunAddnReportingCurrency(CurrencyACY, CurrencyACY);

        BankAccountNo := CreateBankAccountWithCurrency(CurrencyFCY);

        CreateJournalLineForInvoice(
          GenJournalLine, GenJournalLine."Account Type"::"Bank Account", BankAccountNo, LibraryRandom.RandDec(100, 2) + 100);
        ModifyGeneralJournalLine(GenJournalLine, GenJournalLine."Bal. Gen. Posting Type"::Purchase, CurrencyFCY);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 2. Exercise: Modify Exchange Rate for Foreign Currency and Run Adjust Exchange Rate Batch.
        AddnlReportingCurrencyAmount := CalculateAdditionalAmount(CurrencyExchangeRate, CurrencyACY, GenJournalLine."Amount (LCY)");
        UpdateRunAdjustExchangeRates(CurrencyExchangeRate, CurrencyFCY, BankAccountNo);

        // 3. Verify: Verify G/L Entry for Additional Currency Amount, Bank Account Ledger for Adjust Exchange Rate Entry.
        VerifyGLEntryForACY(GenJournalLine, AddnlReportingCurrencyAmount);
        VerifyAdjExchEntryBankExists(BankAccountNo, GenJournalLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('ApplyPostCustomerEntryHandler,PostApplicationHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CustomerPartialApplyCurrencies()
    var
        Customer: Record Customer;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CurrencyFCY: Code[10];
        CurrencyACY: Code[10];
        DocumentNo: Code[20];
        Amount: Decimal;
        AmountACY: Decimal;
        AmountFCY: Decimal;
        RemainingAmountLCY: Decimal;
        AdjustExchangeAmount: Decimal;
    begin
        // Post General Journal Lines for Customer with  Foreign Currency. Apply Payment to Invoice with Page Testability.
        // Run Adjust Exchange Rate for ACY after changing Currency Exchange Rate.

        // 1. Setup: Update Additional Currency in General Ledger Setup. Run Additional Currency Reporting Report.
        // Create and Post General Journal Line for Invoice and Payment.
        Initialize();
        LibrarySales.SetApplnBetweenCurrencies(SalesReceivablesSetup."Appln. between Currencies"::All);
        LibrarySales.SetStockoutWarning(false);
        CreateCurrencies(CurrencyACY, CurrencyFCY);
        UpdateRunAddnReportingCurrency(CurrencyACY, CurrencyACY);

        Amount := LibraryRandom.RandDec(100, 2);
        LibrarySales.CreateCustomer(Customer);
        DocumentNo := CreatePostGeneralLineCustomer(Customer."No.", CurrencyACY, CurrencyFCY, Amount);

        // 2. Exercise: Apply Payment on Invoice from Customer Ledger Entries Page.
        // Modify Exchange Rate for Additional Reporting Currency and Run Adjust Exchange Rate Batch.
        ApplyCustomerLedgerEntries(Customer."No.", CustLedgerEntry."Document Type"::Payment);
        AmountFCY := CalculateExchangeAmount(CurrencyExchangeRate, CurrencyFCY, Amount / 2);
        AmountACY := CalculateExchangeAmount(CurrencyExchangeRate, CurrencyACY, Amount);
        ModifyCurrencyExchangeRate(CurrencyExchangeRate);
        AdjustExchangeAmount := CalculateExchangeAmount(CurrencyExchangeRate, CurrencyACY, AmountACY - AmountFCY);
        RemainingAmountLCY := Round((AmountACY - AmountFCY) - AdjustExchangeAmount, GetAmountRoundingPrecision());
        RunAdjustExchangeRates(CurrencyExchangeRate, Customer."No.");

        // 3. Verify: Verify Customer Ledger Entry for Remaining Amount LCY.
        RemainingAmountLCYInCustomer(CustLedgerEntry."Document Type"::Invoice, Customer."No.", DocumentNo, RemainingAmountLCY);
    end;

    [Test]
    [HandlerFunctions('ApplyPostCustomerEntryHandler,PostApplicationHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CustomerPartialApply()
    var
        Customer: Record Customer;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CurrencyFCY: Code[10];
        CurrencyACY: Code[10];
        DocumentNo: Code[20];
        Amount: Decimal;
        AmountACY: Decimal;
        AmountFCY: Decimal;
    begin
        // Post General Journal Lines for Customer, Apply Payment to Invoice Page Testability,

        // 1. Setup: Update Additional Currency in General Ledger Setup, Run Additional Currency Reporting Report.
        // Create and Post General Journal Line for Invoice and Payment.
        Initialize();
        LibrarySales.SetApplnBetweenCurrencies(SalesReceivablesSetup."Appln. between Currencies"::All);
        LibrarySales.SetStockoutWarning(false);

        CreateCurrencies(CurrencyACY, CurrencyFCY);
        UpdateRunAddnReportingCurrency(CurrencyACY, CurrencyACY);

        Amount := LibraryRandom.RandDec(100, 2);
        LibrarySales.CreateCustomer(Customer);
        DocumentNo := CreatePostGeneralLineCustomer(Customer."No.", CurrencyACY, CurrencyFCY, Amount);

        // 2. Exercise: Apply Payment on Invoice from Customer Ledger Entries Page.
        ApplyCustomerLedgerEntries(Customer."No.", CustLedgerEntry."Document Type"::Payment);

        // Calculate Remaining Amount LCY for different Currencies.
        AmountFCY := CalculateExchangeAmount(CurrencyExchangeRate, CurrencyFCY, Amount / 2);
        AmountACY := CalculateExchangeAmount(CurrencyExchangeRate, CurrencyACY, Amount);

        // 3. Verify: Verify Customer Ledger Entry for Remaining Amount LCY.
        RemainingAmountLCYInCustomer(
          CustLedgerEntry."Document Type"::Invoice, Customer."No.", DocumentNo, Round(AmountACY - AmountFCY, GetAmountRoundingPrecision()));
    end;

    [Test]
    [HandlerFunctions('StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure PostJournalCustomerFCY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        LibrarySales: Codeunit "Library - Sales";
        CurrencyFCY: Code[10];
        CurrencyACY: Code[10];
        AddnlReportingCurrencyAmount: Decimal;
    begin
        // Post General Journal Line for Customer and Run Adjust Exchange Rate for Foreign Currency after changing Currency Exchange Rate.

        // 1. Setup: Update Additional Currency in General Ledger Setup. Run Additional Currency Reporting Report.
        // Create and Post General Journal Line with Random Values for Customer Invoice.
        Initialize();
        CreateCurrencies(CurrencyACY, CurrencyFCY);
        UpdateRunAddnReportingCurrency(CurrencyACY, CurrencyACY);

        LibrarySales.CreateCustomer(Customer);
        CreateJournalLineForInvoice(
          GenJournalLine, GenJournalLine."Account Type"::Customer, Customer."No.", LibraryRandom.RandDec(100, 2) + 100);
        ModifyGeneralJournalLine(GenJournalLine, GenJournalLine."Bal. Gen. Posting Type"::Sale, CurrencyFCY);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 2. Exercise: Modify Exchange Rate for Foreign Currency and Run Adjust Exchange Rate Batch for Foreign Currency.
        AddnlReportingCurrencyAmount := CalculateAdditionalAmount(CurrencyExchangeRate, CurrencyACY, GenJournalLine."Amount (LCY)");
        UpdateRunAdjustExchangeRates(CurrencyExchangeRate, CurrencyFCY, CurrencyFCY);

        // 3. Verify: Verify G/L Entry for Additional Currency Amount. Verify Detailed Customer Ledger for Adjust Exchange Rate Entry.
        VerifyGLEntryForACY(GenJournalLine, AddnlReportingCurrencyAmount);
        VerifyDtldCustAdjExchExists(CurrencyFCY);
    end;

    [Test]
    [HandlerFunctions('StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure AdjustExchangeRateCustomerACY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        LibrarySales: Codeunit "Library - Sales";
        CurrencyFCY: Code[10];
        CurrencyACY: Code[10];
        AddnlReportingCurrencyAmount: Decimal;
    begin
        // Post General Journal Line for Customer and Run Adjust Exchange Rate for Additional Reporting Currency
        // after changing Currency Exchange Rate.

        // 1. Setup: Update Additional Currency in General Ledger Setup and Run Additional Currency Reporting Report.
        // Create and Post General Journal Line with Random Values for Customer Invoice.
        Initialize();
        CreateCurrencies(CurrencyACY, CurrencyFCY);
        UpdateRunAddnReportingCurrency(CurrencyACY, CurrencyACY);

        LibrarySales.CreateCustomer(Customer);
        CreateJournalLineForInvoice(
          GenJournalLine, GenJournalLine."Account Type"::Customer, Customer."No.", LibraryRandom.RandDec(100, 2) + 100);
        ModifyGeneralJournalLine(GenJournalLine, GenJournalLine."Bal. Gen. Posting Type"::Sale, CurrencyFCY);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 2. Exercise: Modify Exchange Rate for Additional Reporting Currency and Run Adjust Exchange Rate Batch.
        AddnlReportingCurrencyAmount := CalculateAdditionalAmount(CurrencyExchangeRate, CurrencyACY, GenJournalLine."Amount (LCY)");
        ModifyCurrencyExchangeRate(CurrencyExchangeRate);
        RunAdjustExchangeRates(CurrencyExchangeRate, CurrencyACY);

        // 3. Verify: Verify G/L Entry for Additional Currency Amount and Adjust Exchange Rate Entry.
        VerifyGLEntryForACY(GenJournalLine, AddnlReportingCurrencyAmount);
        VerifyGLEntryAdjustExchExists(CurrencyACY);
    end;

    [Test]
    [HandlerFunctions('StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure CustomerFCYFullApply()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        Customer: Record Customer;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        LibrarySales: Codeunit "Library - Sales";
        CurrencyFCY: Code[10];
        CurrencyACY: Code[10];
        AddnlReportingCurrencyAmount: Decimal;
        Amount: Decimal;
    begin
        // Create Invoice for Customer change Exchange Rate for Foreign Currency and Additional Currency. Run Adjust Exchange Batch.
        // Create Payment and apply to Invoice.

        // 1. Setup: Update Additional Currency in General Ledger Setup, Run Additional Currency Reporting Report.
        // Create and Post General Journal Line with Random Values for Customer Invoice.
        Initialize();
        CreateCurrencies(CurrencyACY, CurrencyFCY);
        UpdateRunAddnReportingCurrency(CurrencyACY, CurrencyACY);

        LibrarySales.CreateCustomer(Customer);
        Amount := LibraryRandom.RandDec(100, 2) + 100;
        CreateJournalLineForInvoice(GenJournalLine, GenJournalLine."Account Type"::Customer, Customer."No.", Amount);
        ModifyGeneralJournalLine(GenJournalLine, GenJournalLine."Bal. Gen. Posting Type"::Sale, CurrencyFCY);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 2. Exercise: Modify Exchange Rate for Additional Reporting Currency and Foreign Currency and
        // Run Adjust Exchange Rate Batch for both.
        UpdateRunAdjustExchangeRates(CurrencyExchangeRate, CurrencyACY, Customer."No.");
        UpdateRunAdjustExchangeRates(CurrencyExchangeRate, CurrencyFCY, Customer."No.");
        AddnlReportingCurrencyAmount := Round(
            CalculateAdditionalAmount(CurrencyExchangeRate, CurrencyACY, GenJournalLine."Amount (LCY)"), GetAmountRoundingPrecision());

        CreateAndApplyPaymentToInvoice(
          GenJournalLine2, GenJournalLine2."Account Type"::Customer, GenJournalLine."Bal. Gen. Posting Type"::Sale,
          Customer."No.", GenJournalLine."Document No.", CurrencyFCY, -Amount);

        // 3. Verify: Verify G/L Entry for Additional Currency Amount. Verify Remaining Amount in Customer Ledger Entry.
        VerifyGLEntryForACYPayment(GenJournalLine2, -AddnlReportingCurrencyAmount);
        RemainingAmountLCYInCustomer(CustLedgerEntry."Document Type"::Invoice, Customer."No.", GenJournalLine."Document No.", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostGeneralJournalACY()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        CurrencyCode: Code[10];
        AddnlReportingCurrencyAmount: Decimal;
    begin
        // Verify Additional Currency Amount in GL Entry after Posting General Journal Line.

        // 1. Setup: Update Additional Currency in General Ledger Setup and Run Additional Currency Reporting Report.
        Initialize();
        CurrencyCode := CreateCurrencyWithAccounts();
        UpdateRunAddnReportingCurrency(CurrencyCode, CurrencyCode);

        LibraryPurchase.CreateVendor(Vendor);

        // 2. Exercise: Create and Post General Journal Line with Random Values.
        CreateJournalLineForInvoice(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, Vendor."No.", -LibraryRandom.RandDec(100, 2));
        ModifyGeneralJournalLine(GenJournalLine, GenJournalLine."Bal. Gen. Posting Type"::Purchase, CurrencyCode);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        AddnlReportingCurrencyAmount := CalculateAdditionalAmount(CurrencyExchangeRate, CurrencyCode, GenJournalLine."Amount (LCY)");

        // 3. Verify: Verify G/L Entry for Additional Currency Amount.
        VerifyGLEntryForACY(GenJournalLine, AddnlReportingCurrencyAmount);
    end;

    [Test]
    [HandlerFunctions('StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure AdjustExchangeRateVendorACY()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        CurrencyCode: Code[10];
        AddnlReportingCurrencyAmount: Decimal;
    begin
        // Verify Additional Currency Amount in GL Entry. Verify Adjust Exchange Rate Entry in Detailed Vendor Ledger Entry after
        // Posting General Journal Line and changing Currency Exchange Rate.

        // 1. Setup: Update Additional Currency in General Ledger Setup and Run Additional Currency Reporting Report.
        // Create and Post General Journal Line with Random Values.
        Initialize();
        CurrencyCode := CreateCurrencyWithAccounts();
        UpdateRunAddnReportingCurrency(CurrencyCode, CurrencyCode);

        LibraryPurchase.CreateVendor(Vendor);

        CreateJournalLineForInvoice(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, Vendor."No.", -LibraryRandom.RandDec(100, 2));
        ModifyGeneralJournalLine(GenJournalLine, GenJournalLine."Bal. Gen. Posting Type"::Purchase, CurrencyCode);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 2. Exercise: Modify Exchange Rate for Additional Reporting Currency and Run Adjust Exchange Rate Batch.
        AddnlReportingCurrencyAmount := CalculateAdditionalAmount(CurrencyExchangeRate, CurrencyCode, GenJournalLine."Amount (LCY)");
        ModifyCurrencyExchangeRate(CurrencyExchangeRate);
        RunAdjustExchangeRates(CurrencyExchangeRate, CurrencyCode);

        // 3. Verify: Verify G/L Entry for Additional Currency Amount, Verify Detailed Vendor Ledger Entry Adjust Exchange Rate Entry.
        VerifyGLEntryForACY(GenJournalLine, AddnlReportingCurrencyAmount);
        VerifyDetailedVendorLedger(Vendor."No.");
    end;

    [Test]
    [HandlerFunctions('StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure PostGeneralJournalVendorFCY()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        CurrencyFCY: Code[10];
        CurrencyACY: Code[10];
        AddnlReportingCurrencyAmount: Decimal;
    begin
        // Post General Journal Line for Vendor and Run Adjust Exchange Rate for Foreign Currency after changing Currency Exchange Rate.

        // 1. Setup: Update Additional Currency in General Ledger Setup. Run Additional Currency Reporting Report.
        // Create and Post General Journal Line with Random Values for Vendor Invoice.
        Initialize();
        CreateCurrencies(CurrencyACY, CurrencyFCY);
        UpdateRunAddnReportingCurrency(CurrencyACY, CurrencyACY);

        LibraryPurchase.CreateVendor(Vendor);
        CreateJournalLineForInvoice(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, Vendor."No.", -LibraryRandom.RandDec(100, 2));
        ModifyGeneralJournalLine(GenJournalLine, GenJournalLine."Bal. Gen. Posting Type"::Purchase, CurrencyFCY);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 2. Exercise: Modify Exchange Rate for Foreign Currency and Run Adjust Exchange Rate Batch for Foreign Currency.
        AddnlReportingCurrencyAmount := CalculateAdditionalAmount(CurrencyExchangeRate, CurrencyACY, GenJournalLine."Amount (LCY)");
        UpdateRunAdjustExchangeRates(CurrencyExchangeRate, CurrencyFCY, Vendor."No.");

        // 3. Verify: Verify G/L Entry for Additional Currency Amount. Verify Detailed Vendor Ledger for Adjust Exchange Rate Entry.
        VerifyGLEntryForACY(GenJournalLine, AddnlReportingCurrencyAmount);
        VerifyDetailedVendorLedger(Vendor."No.");
    end;

    [Test]
    [HandlerFunctions('StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure AdjustExchRateVendorCurrencies()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        CurrencyFCY: Code[10];
        CurrencyACY: Code[10];
        AddnlReportingCurrencyAmount: Decimal;
    begin
        // Post General Journal Line for Vendor and Run Adjust Exchange Rate for Additional Reporting Currency
        // after changing Currency Exchange Rate.

        // 1. Setup: Update Additional Currency in General Ledger Setup and Run Additional Currency Reporting Report.
        // Create and Post General Journal Line with Random Values for Vendor Invoice.
        Initialize();
        CreateCurrencies(CurrencyACY, CurrencyFCY);
        UpdateRunAddnReportingCurrency(CurrencyACY, CurrencyACY);

        LibraryPurchase.CreateVendor(Vendor);
        CreateJournalLineForInvoice(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, Vendor."No.", -LibraryRandom.RandDec(100, 2));
        ModifyGeneralJournalLine(GenJournalLine, GenJournalLine."Bal. Gen. Posting Type"::Purchase, CurrencyFCY);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 2. Exercise: Modify Exchange Rate for Additional Reporting Currency and Run Adjust Exchange Rate Batch.
        CurrencyExchangeRate.Get(CurrencyFCY, LibraryERM.FindEarliestDateForExhRate());
        ModifyCurrencyExchangeRate(CurrencyExchangeRate);
        AddnlReportingCurrencyAmount := CalculateAdditionalAmount(CurrencyExchangeRate, CurrencyACY, GenJournalLine."Amount (LCY)");
        ModifyCurrencyExchangeRate(CurrencyExchangeRate);
        RunAdjustExchangeRates(CurrencyExchangeRate, CurrencyACY);

        // 3. Verify: Verify G/L Entry for Additional Currency Amount and Adjust Exchange Rate Entry.
        VerifyGLEntryForACY(GenJournalLine, AddnlReportingCurrencyAmount);
        VerifyGLEntryAdjustExchExists(CurrencyACY);
    end;

    [Test]
    [HandlerFunctions('StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure VendorFCYFullApply()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        CurrencyFCY: Code[10];
        CurrencyACY: Code[10];
        AddnlReportingCurrencyAmount: Decimal;
        Amount: Decimal;
    begin
        // Create Invoice for Vendor change Exchange Rate for Foreign Currency and Additional Currency. Run Adjust Exchange Batch.
        // Create Payment and apply to Invoice.

        // 1. Setup: Update Additional Currency in General Ledger Setup, Run Additional Currency Reporting Report.
        // Create and Post General Journal Line with Random Values for Vendor Invoice.
        Initialize();
        CreateCurrencies(CurrencyACY, CurrencyFCY);
        UpdateRunAddnReportingCurrency(CurrencyACY, CurrencyACY);

        LibraryPurchase.CreateVendor(Vendor);
        Amount := LibraryRandom.RandDec(100, 2) + 100;
        CreateJournalLineForInvoice(GenJournalLine, GenJournalLine."Account Type"::Vendor, Vendor."No.", -Amount);
        ModifyGeneralJournalLine(GenJournalLine, GenJournalLine."Bal. Gen. Posting Type"::Purchase, CurrencyFCY);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 2. Exercise: Modify Exchange Rate for Additional Reporting Currency and Foreign Currency and
        // Run Adjust Exchange Rate Batch for both.
        UpdateRunAdjustExchangeRates(CurrencyExchangeRate, CurrencyACY, Vendor."No.");
        UpdateRunAdjustExchangeRates(CurrencyExchangeRate, CurrencyFCY, Vendor."No.");
        AddnlReportingCurrencyAmount := Round(
            CalculateAdditionalAmount(CurrencyExchangeRate, CurrencyACY, GenJournalLine."Amount (LCY)"), GetAmountRoundingPrecision());

        CreateAndApplyPaymentToInvoice(
          GenJournalLine2, GenJournalLine2."Account Type"::Vendor, GenJournalLine."Bal. Gen. Posting Type"::Purchase,
          Vendor."No.", GenJournalLine."Document No.", CurrencyFCY, Amount);

        // 3. Verify: Verify G/L Entry for Additional Currency Amount. Verify Remaining Amount in Vendor Ledger Entry.
        VerifyGLEntryForACYPayment(GenJournalLine2, -AddnlReportingCurrencyAmount);
        RemainingAmountLCYInVendor(VendorLedgerEntry."Document Type"::Invoice, Vendor."No.", GenJournalLine."Document No.", 0);
    end;

    [Test]
    [HandlerFunctions('FiscalYearConfirmHandler,CloseIncomeStatementReportHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CloseFiscalYearWithAdditionalCurrencyRounding()
    var
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        VATPostingSetup: Record "VAT Posting Setup";
        CurrencyCode: Code[10];
        PostingDate: Date;
        OldVATPercent: Decimal;
        AdditionalCurrencyAmount: Decimal;
    begin
        // Check there is no error pops up when running Close Income Statement Batch Report with "Residual caused by rounding of Additional-Currency" entries exist.
        // There is 0.01 rounding of Additional-Currency when Amount = 2000, VAT = 25% and Currency Factor = 100 / 55.7551
        // 2000 * (100 / 55.7551) = 3,587.12
        // 500 * (100 / 55.7551) =   896.78
        // 2500 * (100 / 55.7551) = 4,483.89 (0.01 rounding here)

        // Setup: Close Already Opened Fiscal Year. Create New One.
        Initialize();
        LibraryFiscalYear.CloseFiscalYear();
        LibraryFiscalYear.CreateFiscalYear();
        PostingDate := LibraryFiscalYear.GetFirstPostingDate(false);

        // Create and Post General Line.
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        VATPostingSetup.Get(GLAccount."VAT Bus. Posting Group", GLAccount."VAT Prod. Posting Group");
        OldVATPercent := UpdateVATPostingSetupForVATPercent(VATPostingSetup, 25);
        CreateAndPostGeneralJnlLine(
          GenJournalLine, PostingDate, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", GLAccount."No.", -2500);

        // Create Currency and Exchange Rate.
        // Update Additional Currency in General Ledger Setup. Run Additional Currency Reporting Report for ACY.
        CurrencyCode := CreateAndUpdateCurrencyAndExchangeRate(55.7551);
        UpdateRunAddnReportingCurrency(CurrencyCode, CurrencyCode);

        // Close Newly Created Fiscal Year. Customized Date formula required to calculate Fiscal Ending Date.
        LibraryFiscalYear.CloseFiscalYear();
        PostingDate := CalcDate('<CM>', LibraryFiscalYear.GetLastPostingDate(true)); // PostingDate should be the end of month

        // Exercise: Run Close Income Statement Batch Report.
        RunCloseIncomeStatementBatchJob(GenJournalLine, PostingDate);

        // Verify: G/L entry generated for Close Income statement. "Additional-Currency Amount" is correct.
        AdditionalCurrencyAmount :=
          Round(LibraryERM.ConvertCurrency(GenJournalLine.Amount / (1 + VATPostingSetup."VAT %" / 100), '', CurrencyCode, WorkDate()));
        VerifyGLEntryForCloseIncomeStatement(PostingDate, GenJournalLine."Account No.", -AdditionalCurrencyAmount);

        // Tear Down.
        UpdateVATPostingSetupForVATPercent(VATPostingSetup, OldVATPercent);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddCurrDiffVATPostingSetupDesciptionSales()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATPostingSetup: array[2] of Record "VAT Posting Setup";
        GLEntry: Record "G/L Entry";
        GenJournalLine: Record "Gen. Journal Line";
        Currency: Record Currency;
        CustomerNo: Code[20];
        VATAmount: array[2] of Decimal;
        StartingDate: Date;
    begin
        // [SCENARIO 378407] Adjust Exchange Rate for Additional-Currency VAT Adjustment generates correct G/L Entry Description - Sales
        Initialize();

        // [GIVEN] Currency FCY with different exchange rates for Dates: "D1", "D2", "D3".
        CreateCurrencyWithExchangeRates(Currency, 3, StartingDate);

        // [GIVEN] General Ledger Setup "Additional Reporting Currency" = "FCY"
        LibraryERM.SetAddReportingCurrency(Currency.Code);

        // [GIVEN] General Ledger Setup "VAT Exchange Rate Adjustment" := Adjust Additional-Currency Amount
        UpdateGenLedgerVATExchRateAdjustment(
          GeneralLedgerSetup."VAT Exchange Rate Adjustment"::"Adjust Additional-Currency Amount");

        // [GIVEN] Invoice "I1"(VAT Amount "V1") posted at Date "D1", 2nd Invoice "I2"(VAT Amount "V2") posted at Date "D2" with different VAT Posting Setup
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup[1], VATPostingSetup[1]."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandInt(25));
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup[2], VATPostingSetup[2]."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandInt(25));
        CustomerNo := LibrarySales.CreateCustomerNo();
        VATAmount[1] :=
          CreatePostGenJnlLineWithBalVATSetup(
            GenJournalLine."Account Type"::Customer, CustomerNo, LibraryRandom.RandInt(500), StartingDate,
            VATPostingSetup[1], GenJournalLine."Bal. Gen. Posting Type"::Sale);
        VATAmount[2] :=
          CreatePostGenJnlLineWithBalVATSetup(
            GenJournalLine."Account Type"::Customer, CustomerNo, LibraryRandom.RandInt(600), StartingDate + 1,
            VATPostingSetup[2], GenJournalLine."Bal. Gen. Posting Type"::Sale);

        // [WHEN] Adjust Exchange Rate from Date "D1" to "D3" for Currency "FCY"
        LibraryERM.RunExchRateAdjustment(
          Currency.Code, StartingDate, StartingDate + 2, AdjustExchRateDefaultDescTxt, StartingDate + 2, Currency.Code, true);

        // [THEN] Description of G/L Entry for Currency VAT Adjustment of Invoice "I1" contains its VAT Amount "V1"
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::" ");
        GLEntry.SetRange("Document No.", Currency.Code);
        VerifyCurrAdjGLEntryDescription(GLEntry, VATPostingSetup[1]."Sales VAT Account", VATAmount[1]);

        // [THEN] Description of G/L Entry for Currency VAT Adjustment of Invoice "I2" contains its VAT Amount "V2"
        VerifyCurrAdjGLEntryDescription(GLEntry, VATPostingSetup[2]."Sales VAT Account", VATAmount[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddCurrDiffVATPostingSetupDesciptionPurch()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATPostingSetup: array[2] of Record "VAT Posting Setup";
        GLEntry: Record "G/L Entry";
        GenJournalLine: Record "Gen. Journal Line";
        Currency: Record Currency;
        VendorNo: Code[20];
        VATAmount: array[2] of Decimal;
        StartingDate: Date;
    begin
        // [SCENARIO 378407] Adjust Exchange Rate for Additional-Currency VAT Adjustment generates correct G/L Entry Description - Purchase
        Initialize();

        // [GIVEN] Currency FCY with different exchange rates for Dates: "D1", "D2", "D3".
        CreateCurrencyWithExchangeRates(Currency, 3, StartingDate);

        // [GIVEN] General Ledger Setup "Additional Reporting Currency" = "FCY"
        LibraryERM.SetAddReportingCurrency(Currency.Code);

        // [GIVEN] General Ledger Setup "VAT Exchange Rate Adjustment" := Adjust Additional-Currency Amount
        UpdateGenLedgerVATExchRateAdjustment(
          GeneralLedgerSetup."VAT Exchange Rate Adjustment"::"Adjust Additional-Currency Amount");

        // [GIVEN] Invoice "I1" (VAT Amount "V1") posted at Date "D1", 2nd Invoice "I2"(VAT Amount "V2") posted at Date "D2" with different VAT Posting Setup
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup[1], VATPostingSetup[1]."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandInt(25));
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup[2], VATPostingSetup[2]."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandInt(25));
        VendorNo := LibraryPurchase.CreateVendorNo();
        VATAmount[1] :=
          CreatePostGenJnlLineWithBalVATSetup(
            GenJournalLine."Account Type"::Vendor, VendorNo, -LibraryRandom.RandInt(500), StartingDate,
            VATPostingSetup[1], GenJournalLine."Bal. Gen. Posting Type"::Purchase);
        VATAmount[2] :=
          CreatePostGenJnlLineWithBalVATSetup(
            GenJournalLine."Account Type"::Vendor, VendorNo, -LibraryRandom.RandInt(600), StartingDate + 1,
            VATPostingSetup[2], GenJournalLine."Bal. Gen. Posting Type"::Purchase);

        // [WHEN] Adjust Exchange Rate from Date "D1" to "D3" for Currency "FCY"
        LibraryERM.RunExchRateAdjustment(
          Currency.Code, StartingDate, StartingDate + 2, AdjustExchRateDefaultDescTxt, StartingDate + 2, Currency.Code, true);

        // [THEN] Description of G/L Entry for Currency VAT Adjustment of Invoice "I1" contains its VAT Amount "V1"
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::" ");
        GLEntry.SetRange("Document No.", Currency.Code);
        VerifyCurrAdjGLEntryDescription(GLEntry, VATPostingSetup[1]."Purchase VAT Account", VATAmount[1]);

        // [THEN] Description of G/L Entry for Currency VAT Adjustment of Invoice "I2" contains its VAT Amount "V2"
        VerifyCurrAdjGLEntryDescription(GLEntry, VATPostingSetup[2]."Purchase VAT Account", VATAmount[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostTwoGenJournalWithZeroAmountsAndNonZeroAdditionalCurrency()
    var
        Currency: Record Currency;
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        PostingDate: Date;
        DocumentNo: Code[20];
        TransactionNo: Integer;
        DocumentAmount: Decimal;
    begin
        // [SCENARIO 205467] G/L Entries must be posted with the same "Transaction No." when two gen. journal lines are posted separately and both lines have zero amount and non-zero additional currency amount

        // [GIVEN] Additional currency setup
        Initialize();

        PostingDate := WorkDate();
        CreateCurrencyWithExchangeRates(Currency, 3, PostingDate);
        LibraryERM.SetAddReportingCurrency(Currency.Code);
        DocumentNo := LibraryUtility.GenerateGUID();
        DocumentAmount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] "Gen. Journal Line"[1] where Amount = 100 and "Additional-Currency Posting" = "Additional-Currency Amount Only"
        // [GIVEN] "Gen. Journal Line"[2] where Amount = -100 and "Additional-Currency Posting" = "Additional-Currency Amount Only"
        CreateGenJournalLineWithAdditionalCurrencyPosting(
          GenJournalLine, DocumentNo, Currency."Realized G/L Gains Account", DocumentAmount, Currency.Code);
        GenJnlPostLine.RunWithCheck(GenJournalLine);

        CreateGenJournalLineWithAdditionalCurrencyPosting(
          GenJournalLine, DocumentNo, Currency."Realized G/L Losses Account", -DocumentAmount, Currency.Code);
        GenJnlPostLine.RunWithCheck(GenJournalLine);

        // [WHEN] Both lines posted in the same system transaction
        Commit();

        // [THEN] Both G/L Entries have the same "Transaction No."
        GLEntry.Find('+');
        TransactionNo := GLEntry."Transaction No.";
        GLEntry.Next(-1);
        GLEntry.TestField("Transaction No.", TransactionNo);
    end;

    [Test]
    [HandlerFunctions('FiscalYearConfirmHandler,StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure AdjustExchangeRateOnlyWithGLAccountsAdjustment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        CurrencyFCY: Code[10];
        CurrencyACY: Code[10];
        BankAccountNo: Code[20];
        AddnlReportingCurrencyAmount: Decimal;
    begin
        // [SCENARIO 493211] Adjust Exchange Rates -> Adjust G/L Accounts for Add.-Reporting Currency not working
        Initialize();

        // [GIVEN] Setup: Update Additional Currency in General Ledger Setup. Run Additional Currency Reporting Report.
        CreateCurrencies(CurrencyACY, CurrencyFCY);
        UpdateRunAddnReportingCurrency(CurrencyACY, CurrencyACY);

        // [THEN] Create and Post General Journal Line with Random Values.
        BankAccountNo := CreateBankAccountWithCurrency(CurrencyFCY);
        CreateJournalLineForInvoice(
          GenJournalLine, GenJournalLine."Account Type"::"Bank Account", BankAccountNo, LibraryRandom.RandDec(100, 2) + 100);
        ModifyGeneralJournalLine(GenJournalLine, GenJournalLine."Bal. Gen. Posting Type"::Purchase, CurrencyFCY);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [When] Exercise: Modify Exchange Rate for Foreign Currency and Run Adjust Exchange Rate Batch.
        AddnlReportingCurrencyAmount := CalculateAdditionalAmount(CurrencyExchangeRate, CurrencyACY, GenJournalLine."Amount (LCY)");
        CurrencyExchangeRate.Get(CurrencyFCY, LibraryERM.FindEarliestDateForExhRate());
        ModifyCurrencyExchangeRate(CurrencyExchangeRate);

        // [THEN] Run Adjust Exchange Rate with Adjust G/L Account and without other Adjustments
        RunAdjustExchangeRatesWithAdjGLAccOnly(CurrencyExchangeRate, BankAccountNo);

        // [VERIFY] Verify: Verify G/L Entry for Additional Currency Amount
        VerifyGLEntryForACY(GenJournalLine, AddnlReportingCurrencyAmount);
    end;

    [Test]
    [HandlerFunctions('StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure AdjustExchangeRateForSpecificBankAcountACY()
    var
        GenJournalLine: array[2] of Record "Gen. Journal Line";
        CurrencyExchangeRate: array[2] of Record "Currency Exchange Rate";
        CurrencyFCY: Code[10];
        CurrencyACY: Code[10];
        BankAccountNo: array[2] of Code[20];
        AddnlReportingCurrencyAmount: array[2] of Decimal;
    begin
        // [SCENARIO 498473] After Enabling the use of new extensible exchange rate adjustment Feature, Bank Account Filter not working on Adjust Exchange Rate report
        Initialize();

        // [GIVEN] Setup: Create Currencies and Bank Accounts
        CreateCurrencies(CurrencyACY, CurrencyFCY);
        BankAccountNo[1] := CreateBankAccountWithCurrency(CurrencyFCY);
        BankAccountNo[2] := CreateBankAccountWithCurrency(CurrencyFCY);

        // [GIVEN] Update Additional Currency in General Ledger Setup. Run Additional Currency Reporting Report.
        UpdateRunAddnReportingCurrency(CurrencyACY, CurrencyACY);

        // [THEN] Create and Post General Journal Line with Random Values.
        CreateAndPostJournalLineForBank(GenJournalLine, CurrencyExchangeRate, AddnlReportingCurrencyAmount, BankAccountNo, CurrencyFCY, CurrencyACY);

        // [THEN] Modify Exchange Rate for Additional Reporting Currency and Run Adjust Exchange Rate Batch for Bank Account 1
        UpdateRunAdjustExchangeRates(CurrencyExchangeRate[1], CurrencyFCY, BankAccountNo[1]);

        // [VERIFY]: Verify Entries for Bank Account Ledger Entry Adjusted For Specific Bank
        VerifyAdjExchEntryExistsOnlyForSpecificBank(BankAccountNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountLCYShouldNotResetAfterEnteringBalAccNoWithCurrency()
    var
        Currency: Record Currency;
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        NewAmountLCY: Decimal;
    begin
        // [SCENARIO 537470] Amount LCY should not reset after entering the Bal. Account No.
        Initialize();

        // [GIVEN] Setup: Create a Currency with it's exchange rate and G/L Account
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateExchangeRate(Currency.Code, WorkDate(), LibraryRandom.RandInt(10), LibraryRandom.RandInt(20));
        LibraryERM.CreateGLAccount(GLAccount);

        // [GIVEN] Create Customer with Currency
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", Currency.Code);
        Customer.Modify(true);

        // [GIVEN] Create General Journal Batch
        GenJournalTemplate.SetRange(Recurring, false);
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::General);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch."Bal. Account Type" := GenJournalBatch."Bal. Account Type"::"G/L Account";
        GenJournalBatch.Modify();

        // [THEN] Gen. Journal Line for customer
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer,
            Customer."No.", LibraryRandom.RandDecInDecimalRange(100, 100, 2));

        // [WHEN] Change Amount (LCY) on Gen. Journal Line and then update Bal. Account No.
        GenJournalLine.Validate("Amount (LCY)", LibraryRandom.RandDecInDecimalRange(100, 100, 2));
        NewAmountLCY := GenJournalLine."Amount (LCY)";
        GenJournalLine.Validate("Bal. Account No.", GenJournalBatch."Bal. Account No.");
        GenJournalLine.Modify(true);

        // [THEN] Verify: After updating Bal. Account No. the Amount (LCY) should not reset
        Assert.AreEqual(
            NewAmountLcy,
            GenJournalLine."Amount (LCY)",
            StrSubstNo(AmountLCYError, GenJournalLine."Amount (LCY)"));
    end;

    [Test]
    [HandlerFunctions('StatisticsMessageHandler')]
    procedure NoVATEntryAddCurrExchRateAdjust()
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATEntry: Record "VAT Entry";
        PostingDate: Date;
    begin
        // [SCENARIO 598998] "Attempted to divide by zero" error during Exchange Rates Adjustment if the company has no Tax/VAT Entries.
        Initialize();
        VATEntry.DeleteAll();

        // [GIVEN] Currency FCY with exchange rates.
        PostingDate := WorkDate();
        CreateCurrencyWithExchangeRates(Currency, 1, PostingDate);

        // [GIVEN] General Ledger Setup "Additional Reporting Currency" = "FCY"
        LibraryERM.SetAddReportingCurrency(Currency.Code);

        // [GIVEN] General Ledger Setup "VAT Exchange Rate Adjustment" := Adjust Additional-Currency Amount
        UpdateGenLedgerVATExchRateAdjustment(
            GeneralLedgerSetup."VAT Exchange Rate Adjustment"::"Adjust Additional-Currency Amount");

        // [THEN] Run Adjust Exchange Rate with Adjust G/L Account and without other Adjustments
        CurrencyExchangeRate.Get(Currency.code, LibraryERM.FindEarliestDateForExhRate());

        // [THEN] Report should executed without any error
        RunAdjustExchangeRates(CurrencyExchangeRate, Currency.Code);
    end;

    local procedure Initialize()
    var
        CompanyInformation: Record "Company Information";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Additional Currency");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        // Lazy Setup.
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Additional Currency");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateVATPostingSetup();
        LibraryERMCountryData.UpdateLocalData();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        if CompanyInformation.IsCanada() then begin
            CompanyInformation."Tax Area Code" := '';
            CompanyInformation.Modify();
        end;
        IsInitialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Additional Currency");
    end;

    local procedure ApplyAndPostCreditMemo(var GenJournalLine: Record "Gen. Journal Line"; CurrencyCode: Code[10]; CurrencyCode2: Code[10])
    begin
        // Setup: Create General Line with Invoice and Currency and Post it with Random values.
        CreateGeneralLine(
          GenJournalLine, CreateCustomer(), CurrencyCode, GenJournalLine."Document Type"::Invoice, LibraryRandom.RandDec(100, 2));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise: Apply Credit Memo with Posted Invoice.
        CreateAndPostGeneralLine(
          GenJournalLine, GenJournalLine."Account No.", -GenJournalLine.Amount, GenJournalLine."Document No.", CurrencyCode2,
          GenJournalLine."Document Type"::"Credit Memo");
    end;

    local procedure ApplyCustomerLedgerEntries(CustomerNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    var
        CustomerLedgerEntries: TestPage "Customer Ledger Entries";
    begin
        CustomerLedgerEntries.OpenView();
        CustomerLedgerEntries.FILTER.SetFilter("Customer No.", CustomerNo);
        CustomerLedgerEntries.FILTER.SetFilter("Document Type", Format(DocumentType));
        CustomerLedgerEntries."Apply Entries".Invoke();
    end;

    local procedure CalculateAdditionalAmount(var CurrencyExchangeRate: Record "Currency Exchange Rate"; CurrencyCode: Code[10]; Amount: Decimal) AddnlReportingCurrencyAmount: Decimal
    begin
        CurrencyExchangeRate.Get(CurrencyCode, LibraryERM.FindEarliestDateForExhRate());
        AddnlReportingCurrencyAmount := CurrencyExchangeRate."Exchange Rate Amount" /
          CurrencyExchangeRate."Relational Exch. Rate Amount" * Amount;
    end;

    local procedure CalculateExchangeAmount(var CurrencyExchangeRate: Record "Currency Exchange Rate"; CurrencyCode: Code[10]; Amount: Decimal): Decimal
    begin
        CurrencyExchangeRate.Get(CurrencyCode, LibraryERM.FindEarliestDateForExhRate());
        exit(CurrencyExchangeRate."Relational Exch. Rate Amount" / CurrencyExchangeRate."Exchange Rate Amount" * Amount);
    end;

    local procedure CreateCurrencyWithAccounts() CurrencyCode: Code[10]
    begin
        CurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();
        UpdateAccountsInCurrency(CurrencyCode);
    end;

    local procedure CreateGeneralLine(var GenJournalLine: Record "Gen. Journal Line"; CustomerNo: Code[20]; CurrencyCode: Code[10]; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        SelectGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          GenJournalLine."Account Type"::Customer, CustomerNo, Amount);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateJournalLineForInvoice(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGeneralBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          AccountType, AccountNo, Amount);
    end;

    local procedure CreateAndPostGeneralLine(var GenJournalLine: Record "Gen. Journal Line"; CustomerNo: Code[20]; Amount: Decimal; AppliesToDocNo: Code[20]; CurrencyCode: Code[10]; DocumentType: Enum "Gen. Journal Document Type")
    begin
        CreateGeneralLine(GenJournalLine, CustomerNo, CurrencyCode, DocumentType, Amount);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostSalesInvoice(var SalesLine: Record "Sales Line"; var SalesInvoiceNo: Code[20]; CurrencyCode: Code[10]) AdditionalCurrencyAmount: Decimal
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));
        AdditionalCurrencyAmount := LibraryERM.ConvertCurrency(SalesLine."Line Amount", '', CurrencyCode, WorkDate());

        // Exercise.
        SalesInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateAndPostGeneralJnlLine(var GenJournalLine: Record "Gen. Journal Line"; PostingDate: Date; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
    begin
        SelectGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType, AccountType, AccountNo, Amount);
        GLAccount.Get(AccountNo);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Gen. Posting Type", GLAccount."Gen. Posting Type");
        GenJournalLine.Validate("VAT Bus. Posting Group", GLAccount."VAT Bus. Posting Group");
        GenJournalLine.Validate("VAT Prod. Posting Group", GLAccount."VAT Prod. Posting Group");
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreatePostGenJnlLineWithBalVATSetup(AccountType: Enum "Gen. Journal Account Type"; CustomerNo: Code[20]; Amount: Decimal; PostingDate: Date; VATPostingSetup: Record "VAT Posting Setup"; BalGenPostingType: Enum "General Posting Type"): Decimal
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateJournalLineForInvoice(GenJournalLine, AccountType, CustomerNo, Amount);
        ModifyGeneralJournalLine(GenJournalLine, BalGenPostingType, '');
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Bal. Gen. Posting Type", BalGenPostingType);
        GenJournalLine.Validate("Bal. VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GenJournalLine.Validate("Bal. VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(FindVATEntryAmount(GenJournalLine."Document No."));
    end;

    local procedure CreateAndUpdateCurrencyAndExchangeRate(RelationalExchRateAmt: Decimal): Code[10]
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        CurrencyExchangeRate.SetRange("Currency Code", LibraryERM.CreateCurrencyWithRandomExchRates());
        CurrencyExchangeRate.FindFirst();
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", RelationalExchRateAmt);
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", CurrencyExchangeRate."Relational Exch. Rate Amount");
        CurrencyExchangeRate.Modify(true);
        exit(CurrencyExchangeRate."Currency Code");
    end;

    local procedure CreateBankAccountWithCurrency(CurrencyCode: Code[10]): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Currency Code", CurrencyCode);
        BankAccount.Modify(true);
        exit(BankAccount."No.");
    end;

    local procedure CreateCurrencies(var CurrencyACY: Code[10]; var CurrencyFCY: Code[10])
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        CurrencyExchangeRate2: Record "Currency Exchange Rate";
    begin
        CurrencyACY := CreateCurrencyWithAccounts();
        CurrencyFCY := CreateCurrencyWithAccounts();
        CurrencyExchangeRate.Get(CurrencyFCY, LibraryERM.FindEarliestDateForExhRate());
        CurrencyExchangeRate2.Get(CurrencyACY, LibraryERM.FindEarliestDateForExhRate());
        ModifyExchangeRateAmountFCY(CurrencyExchangeRate, CurrencyExchangeRate2);  // Modifying Exchange Rate Value Important for test.
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        CreateInvDiscForCustomer(Customer."No.");
        exit(Customer."No.");
    end;

    local procedure CreateGeneralBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Recurring, false);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateInvDiscForVendor(VendorNo: Code[20])
    var
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
    begin
        // Using Random and value is not important for Test Case.
        LibraryERM.CreateInvDiscForVendor(VendorInvoiceDisc, VendorNo, '', 0);
        VendorInvoiceDisc.Validate("Discount %", LibraryRandom.RandDec(10, 2));
        VendorInvoiceDisc.Modify(true);
    end;

    local procedure CreateInvDiscForCustomer(CustomerNo: Code[20])
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
    begin
        // Using Random and value is not important for Test Case.
        LibraryERM.CreateInvDiscForCustomer(CustInvoiceDisc, CustomerNo, '', 0);
        CustInvoiceDisc.Validate("Discount %", LibraryRandom.RandDec(10, 2));
        CustInvoiceDisc.Modify(true);
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
        VATPostingSetup: Record "VAT Posting Setup";
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        FindVATPostingSetup(VATPostingSetup);
        // Using Random and value is not important for Test Case.
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Validate("Last Direct Cost", LibraryRandom.RandDec(100, 2));
        Item.Validate("Unit Price", Item."Last Direct Cost");
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateAndApplyPaymentToInvoice(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; GenPostingType: Enum "General Posting Type"; AccountNo: Code[20]; AppliestoDocNo: Code[20]; CurrencyCode: Code[10]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGeneralBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliestoDocNo);
        ModifyGeneralJournalLine(GenJournalLine, GenPostingType, CurrencyCode);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateCurrencyWithExchangeRates(var Currency: Record Currency; NoOfExchangeRates: Integer; var StartingDate: Date)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        i: Integer;
    begin
        Currency.Get(LibraryERM.CreateCurrencyWithRandomExchRates());
        CurrencyExchangeRate.SetRange("Currency Code", Currency.Code);
        CurrencyExchangeRate.FindFirst();
        StartingDate := CurrencyExchangeRate."Starting Date";
        for i := 1 to NoOfExchangeRates - 1 do
            LibraryERM.CreateExchangeRate(
              Currency.Code, StartingDate + i, LibraryRandom.RandInt(10), LibraryRandom.RandInt(20));
    end;

    local procedure CreatePostGeneralLineCustomer(CustomerNo: Code[20]; CurrencyACY: Code[10]; CurrencyFCY: Code[10]; Amount: Decimal): Code[20]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
    begin
        CreateGeneralBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, CustomerNo, Amount);
        ModifyGeneralJournalLine(GenJournalLine, GenJournalLine."Gen. Posting Type"::Sale, CurrencyACY);
        DocumentNo := GenJournalLine."Document No.";

        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, CustomerNo, -Amount / 2);  // Applying Partial Payment for Invoice.
        ModifyGeneralJournalLine(GenJournalLine, GenJournalLine."Gen. Posting Type"::Sale, CurrencyFCY);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(DocumentNo);
    end;

    local procedure CreatePurchaseInvoiceCalcDisc(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line") DiscountAmount: Decimal
    var
        PurchCalcDiscount: Codeunit "Purch.-Calc.Discount";
        Counter: Integer;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateVendor());
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);

        // Creating multiple purchase lines up to 3 using Random function.
        for Counter := 1 to 1 + LibraryRandom.RandInt(3) do begin
            LibraryPurchase.CreatePurchaseLine(
              PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));
            PurchaseLine.Validate("Line Discount %", LibraryRandom.RandDec(15, 2));
            PurchaseLine.Validate("Allow Invoice Disc.", true);
            PurchaseLine.Modify(true);
            DiscountAmount += PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost" * PurchaseLine."Line Discount %" / 100;
        end;
        PurchCalcDiscount.CalculateInvoiceDiscount(PurchaseHeader, PurchaseLine);
    end;

    local procedure CreateSalesInvoiceCalcDisc(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line") DiscountAmount: Decimal
    var
        SalesCalcDiscount: Codeunit "Sales-Calc. Discount";
        Counter: Integer;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer());

        // Creating multiple Sales lines up to 3 using Random function.
        for Counter := 1 to 1 + LibraryRandom.RandInt(8) do begin
            LibrarySales.CreateSalesLine(
              SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));
            SalesLine.Validate("Line Discount %", LibraryRandom.RandDec(15, 2));
            SalesLine.Validate("Allow Invoice Disc.", true);
            SalesLine.Modify(true);
            DiscountAmount += SalesLine.Quantity * SalesLine."Unit Price" * SalesLine."Line Discount %" / 100;
        end;
        SalesCalcDiscount.CalculateWithSalesHeader(SalesHeader, SalesLine);
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        FindVATPostingSetup(VATPostingSetup);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Modify(true);
        CreateInvDiscForVendor(Vendor."No.");
        exit(Vendor."No.");
    end;

    local procedure CreateGLAccountWithVAT(var GLAccount: Record "G/L Account"; var VATPostingSetup: Record "VAT Posting Setup")
    begin
        FindVATPostingSetup(VATPostingSetup);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Exchange Rate Adjustment", GLAccount."Exchange Rate Adjustment"::"Adjust Additional-Currency Amount");
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
    end;

    local procedure CreateGenJournalLineWithAdditionalCurrencyPosting(var GenJournalLine: Record "Gen. Journal Line"; DocumentNo: Code[20]; AccountNo: Code[20]; DocumentAmount: Decimal; CurrencyCode: Code[10])
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account", AccountNo, DocumentAmount);

        GenJournalLine.Description := LibraryUtility.GenerateGUID();
        GenJournalLine."Document No." := DocumentNo;
        GenJournalLine."Posting Date" := WorkDate();
        GenJournalLine."Source Code" := LibraryUtility.GenerateGUID();
        GenJournalLine."Additional-Currency Posting" := GenJournalLine."Additional-Currency Posting"::"Additional-Currency Amount Only";
        GenJournalLine."Currency Code" := CurrencyCode;
        GenJournalLine."Amount (LCY)" := 0;
        GenJournalLine.Modify();
    end;

    local procedure FindVATEntry(var VATEntry: Record "VAT Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    begin
        VATEntry.SetRange("Document Type", DocumentType);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindFirst();
    end;

    local procedure FindVATEntryAmount(DocumentNo: Code[20]): Decimal
    var
        VATEntry: Record "VAT Entry";
    begin
        FindVATEntry(VATEntry, VATEntry."Document Type"::Invoice, DocumentNo);
        exit(VATEntry.Amount);
    end;

    local procedure FindVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATPostingSetup.SetRange("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::" ");
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
    end;

    local procedure FilterGLEntry(var GLEntry: Record "G/L Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; BalAccountNo: Code[20])
    begin
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Bal. Account No.", BalAccountNo);
    end;

    local procedure GetAmountRoundingPrecision(): Decimal
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        exit(GeneralLedgerSetup."Amount Rounding Precision");
    end;

    local procedure ModifyCurrencyExchangeRate(var CurrencyExchangeRate: Record "Currency Exchange Rate")
    begin
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", CurrencyExchangeRate."Relational Exch. Rate Amount" / 3);
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", CurrencyExchangeRate."Relational Adjmt Exch Rate Amt" / 3);
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure ModifyExchangeRateAmountFCY(CurrencyExchangeRate: Record "Currency Exchange Rate"; CurrencyExchangeRate2: Record "Currency Exchange Rate")
    begin
        CurrencyExchangeRate.Validate("Exchange Rate Amount", CurrencyExchangeRate2."Exchange Rate Amount");
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", CurrencyExchangeRate2."Adjustment Exch. Rate Amount");
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", CurrencyExchangeRate2."Relational Exch. Rate Amount" / 3);
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", CurrencyExchangeRate2."Relational Exch. Rate Amount" / 3);
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure ModifyGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; BalGenPostingType: Enum "General Posting Type"; CurrencyCode: Code[10])
    var
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        GLAccount.Get(LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, BalGenPostingType));
        // Value of Document No. is not important.
        GenJournalLine.Validate("Document No.", GenJournalLine."Journal Batch Name" + Format(GenJournalLine."Line No."));
        GenJournalLine.Validate("Bal. Account No.", GLAccount."No.");
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Validate("External Document No.", GenJournalLine."Document No.");
        GenJournalLine.Modify(true);
    end;

    local procedure RunAdditionalReportingCurrency(CurrencyCode: Code[10]; DocumentNo: Code[20])
    var
        AdjustAddReportingCurrency: Report "Adjust Add. Reporting Currency";
    begin
        AdjustAddReportingCurrency.SetAddCurr(CurrencyCode);
        AdjustAddReportingCurrency.InitializeRequest(DocumentNo, LibraryERM.CreateGLAccountNo());
        AdjustAddReportingCurrency.UseRequestPage(false);
        AdjustAddReportingCurrency.Run();
    end;

    local procedure RunAdjustExchangeRates(CurrencyExchangeRate: Record "Currency Exchange Rate"; DocumentNo: Code[20])
    var
        Currency: Record Currency;
        ExchRateAdjustment: Report "Exch. Rate Adjustment";
    begin
        Currency.SetRange(Code, CurrencyExchangeRate."Currency Code");
        Clear(ExchRateAdjustment);
        ExchRateAdjustment.SetTableView(Currency);
        ExchRateAdjustment.InitializeRequest2(
          CurrencyExchangeRate."Starting Date", WorkDate(), 'Test', CurrencyExchangeRate."Starting Date",
          DocumentNo, true, true);
        ExchRateAdjustment.UseRequestPage(false);
        ExchRateAdjustment.Run();
    end;

    local procedure RunCloseIncomeStatementBatchJob(GenJournalLine: Record "Gen. Journal Line"; PostingDate: Date)
    var
        GLAccount: Record "G/L Account";
        CloseIncomeStatement: Report "Close Income Statement";
    begin
        LibraryVariableStorage.Enqueue(PostingDate);
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Batch Name");
        LibraryVariableStorage.Enqueue(IncStr(GenJournalLine."Document No."));
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryVariableStorage.Enqueue(GLAccount."No.");
        Commit();  // Required to commit changes done.
        Clear(CloseIncomeStatement);
        CloseIncomeStatement.Run();
    end;

    local procedure UpdateRunAddnReportingCurrency(CurrencyCode: Code[10]; DocumentNo: Code[20])
    begin
        LibraryERM.SetAddReportingCurrency(CurrencyCode);
        RunAdditionalReportingCurrency(CurrencyCode, DocumentNo);
    end;

    local procedure UpdateRunAdjustExchangeRates(var CurrencyExchangeRate: Record "Currency Exchange Rate"; CurrencyCode: Code[10]; DocumentNo: Code[20])
    begin
        CurrencyExchangeRate.Get(CurrencyCode, LibraryERM.FindEarliestDateForExhRate());
        ModifyCurrencyExchangeRate(CurrencyExchangeRate);
        RunAdjustExchangeRates(CurrencyExchangeRate, DocumentNo);
    end;

    local procedure SelectGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        // Select General Journal Batch and clear General Journal Lines to make sure that no line exits before creating
        // General Journal Lines.
        LibraryERM.SelectLastGenJnBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch)
    end;

    local procedure UpdateAccountsInCurrency(CurrencyCode: Code[10])
    var
        Currency: Record Currency;
    begin
        Currency.Get(CurrencyCode);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
    end;

    local procedure UpdateGeneralPostingSetup(GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        // Requirement of Test case we need to create and find different GL Accounts.
        LibraryERM.CreateGLAccount(GLAccount);
        GeneralPostingSetup.Get(GenBusPostingGroup, GenProdPostingGroup);
        GeneralPostingSetup.Validate("Purch. Line Disc. Account", GLAccount."No.");
        LibraryERM.CreateGLAccount(GLAccount);
        GeneralPostingSetup.Validate("Sales Line Disc. Account", GLAccount."No.");
        GeneralPostingSetup.Modify(true);
    end;

    local procedure UpdateGenLedgerVATExchRateAdjustment(NewVATExchRateAdjustment: Enum "Exch. Rate Adjustment Type")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("VAT Exchange Rate Adjustment", NewVATExchRateAdjustment);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateVATPostingSetupForVATPercent(var VATPostingSetup: Record "VAT Posting Setup"; VATPercent: Decimal) OldVATPercent: Decimal
    begin
        OldVATPercent := VATPostingSetup."VAT %";
        VATPostingSetup.Validate("VAT %", VATPercent);
        VATPostingSetup.Modify(true);
        exit(OldVATPercent);
    end;

    local procedure VerifyAdditionalCurrencyAmount(var GLEntry: Record "G/L Entry"; AdditionalCurrencyAmount: Decimal)
    begin
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(
          AdditionalCurrencyAmount, GLEntry."Additional-Currency Amount", GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, GLEntry.FieldCaption("Additional-Currency Amount"), AdditionalCurrencyAmount, GLEntry.TableCaption()));
    end;

    local procedure VerifyAdjExchEntryBankExists(BankAccountNo: Code[20]; DocumentNo: Code[20])
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccountNo);
        BankAccountLedgerEntry.SetRange("Document No.", DocumentNo);
        BankAccountLedgerEntry.FindFirst();
    end;

    local procedure VerifyCustLedgerEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; PmtDiscountDate: Date; Amount: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        CustLedgerEntry.CalcFields(Amount);
        CustLedgerEntry.TestField("Pmt. Discount Date", PmtDiscountDate);
        CustLedgerEntry.TestField(Amount, Amount);
    end;

    local procedure VerifyCurrAdjGLEntryDescription(var GLEntry: Record "G/L Entry"; GLAccountNo: Code[20]; VATAmount: Decimal)
    begin
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
        Assert.IsTrue(StrPos(GLEntry.Description, Format(VATAmount)) > 0, GLEntry.FieldCaption(Description));
    end;

    local procedure RemainingAmountLCYInCustomer(DocumentType: Enum "Gen. Journal Document Type"; CustomerNo: Code[20]; DocumentNo: Code[20]; RemainingAmountLCY: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        CustLedgerEntry.CalcFields("Remaining Amt. (LCY)");
        Assert.AreNearlyEqual(
          RemainingAmountLCY, CustLedgerEntry."Remaining Amt. (LCY)", GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, CustLedgerEntry.FieldCaption("Remaining Amt. (LCY)"), RemainingAmountLCY, CustLedgerEntry.TableCaption()));
    end;

    local procedure RemainingAmountLCYInVendor(DocumentType: Enum "Gen. Journal Document Type"; VendorNo: Code[20]; DocumentNo: Code[20]; RemainingAmountLCY: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, DocumentType, DocumentNo);
        VendorLedgerEntry.CalcFields("Remaining Amt. (LCY)");
        Assert.AreNearlyEqual(
          RemainingAmountLCY, VendorLedgerEntry."Remaining Amt. (LCY)", GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, VendorLedgerEntry.FieldCaption("Remaining Amt. (LCY)"), RemainingAmountLCY, VendorLedgerEntry.TableCaption())
          );
    end;

    local procedure VerifyDetailedVendorLedger(VendorNo: Code[20])
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DetailedVendorLedgEntry.SetFilter(
          "Entry Type", '%1|%2',
          DetailedVendorLedgEntry."Entry Type"::"Unrealized Gain", DetailedVendorLedgEntry."Entry Type"::"Unrealized Loss");
        DetailedVendorLedgEntry.SetRange("Vendor No.", VendorNo);
        DetailedVendorLedgEntry.FindFirst();
    end;

    local procedure VerifyDetailedCustLedgerEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; Amount: Decimal; AmountLCY: Decimal)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.SetRange("Entry Type", DetailedCustLedgEntry."Entry Type"::Application);
        DetailedCustLedgEntry.SetRange("Document Type", DocumentType);
        DetailedCustLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedCustLedgEntry.FindFirst();
        DetailedCustLedgEntry.TestField(Amount, Amount);
        DetailedCustLedgEntry.TestField("Amount (LCY)", AmountLCY);
    end;

    local procedure VerifyDtldCustAdjExchExists(DocumentNo: Code[20])
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.SetFilter(
          "Entry Type", '%1|%2',
          DetailedCustLedgEntry."Entry Type"::"Unrealized Loss", DetailedCustLedgEntry."Entry Type"::"Unrealized Gain");
        DetailedCustLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedCustLedgEntry.FindFirst();
    end;

    local procedure VerifyGLAccount(ExpectedAmount: Decimal; ActualAmount: Decimal; FieldCaption: Text[30])
    var
        GLAccount: Record "G/L Account";
    begin
        Assert.AreNearlyEqual(
          ExpectedAmount, ActualAmount, GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, FieldCaption, ExpectedAmount, GLAccount.TableCaption()));
    end;

    local procedure VerifyGLEntryAdjustExchExists(DocumentNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindFirst();
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; GLAccountNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        VerifyAdditionalCurrencyAmount(GLEntry, Amount);
    end;

    local procedure VerifyGLEntryForACY(GenJournalLine: Record "Gen. Journal Line"; AdditionalCurrencyAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        FilterGLEntry(GLEntry, GLEntry."Document Type"::Invoice, GenJournalLine."Document No.", GenJournalLine."Bal. Account No.");
        VerifyAdditionalCurrencyAmount(GLEntry, AdditionalCurrencyAmount);
        Assert.AreNearlyEqual(
          GenJournalLine."Amount (LCY)", GLEntry.Amount, GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, GLEntry.FieldCaption(Amount), GenJournalLine."Amount (LCY)", GLEntry.TableCaption()));
    end;

    local procedure VerifyGLEntryForACYPayment(GenJournalLine: Record "Gen. Journal Line"; AdditionalCurrencyAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        FilterGLEntry(GLEntry, GLEntry."Document Type"::Payment, GenJournalLine."Document No.", GenJournalLine."Bal. Account No.");
        VerifyAdditionalCurrencyAmount(GLEntry, AdditionalCurrencyAmount);
    end;

    local procedure VerifyGLEntryForFiscalYear(PostingDate: Date; GLAccountNo: Code[20]; Amount: Decimal; AdditionalCurrencyAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.SetRange("Posting Date", PostingDate);
        VerifyAdditionalCurrencyAmount(GLEntry, AdditionalCurrencyAmount);
        Assert.AreNearlyEqual(
          Amount, GLEntry.Amount, GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, GLEntry.FieldCaption(Amount), Amount, GLEntry.TableCaption()));
    end;

    local procedure VerifyGLEntryForCloseIncomeStatement(PostingDate: Date; AccountNo: Code[20]; AdditionalCurrencyAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
        SourceCodeSetup: Record "Source Code Setup";
    begin
        SourceCodeSetup.Get();
        Evaluate(PostingDate, StrSubstNo(FiscalPostingDateTok, PostingDate));
        GLEntry.SetRange("Posting Date", PostingDate);
        GLEntry.SetRange("G/L Account No.", AccountNo);
        GLEntry.SetRange("Source Code", SourceCodeSetup."Close Income Statement");
        VerifyAdditionalCurrencyAmount(GLEntry, AdditionalCurrencyAmount);
    end;

    local procedure VerifyVATEntry(DocumentNo: Code[20]; AdditionalCurrencyAmount: Decimal; OriginalBase: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange(Base, OriginalBase);
        FindVATEntry(VATEntry, VATEntry."Document Type"::Invoice, DocumentNo);
        Assert.AreNearlyEqual(
          AdditionalCurrencyAmount, VATEntry."Additional-Currency Amount", GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, VATEntry.FieldCaption("Additional-Currency Amount"), AdditionalCurrencyAmount, VATEntry.TableCaption()));
    end;

    local procedure VerifyVATEntryForBase(DocumentNo: Code[20]; BaseAmount: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        FindVATEntry(VATEntry, VATEntry."Document Type"::" ", DocumentNo);
        Assert.AreNearlyEqual(
          BaseAmount, VATEntry.Base, GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, VATEntry.FieldCaption(Base), BaseAmount, VATEntry.TableCaption()));
    end;

    local procedure RunAdjustExchangeRatesWithAdjGLAccOnly(CurrencyExchangeRate: Record "Currency Exchange Rate"; DocumentNo: Code[20])
    var
        Currency: Record Currency;
        ExchRateAdjustment: Report "Exch. Rate Adjustment";
    begin
        Currency.SetRange(Code, CurrencyExchangeRate."Currency Code");
        Clear(ExchRateAdjustment);
        ExchRateAdjustment.SetTableView(Currency);
        ExchRateAdjustment.InitializeRequest2(
            CurrencyExchangeRate."Starting Date", WorkDate(), LibraryRandom.RandText(100),
            CurrencyExchangeRate."Starting Date", DocumentNo, false, true);
        ExchRateAdjustment.UseRequestPage(false);
        ExchRateAdjustment.Run();
    end;

    local procedure CreateAndPostJournalLineForBank(
        var GenJournalLine: array[2] of Record "Gen. Journal Line";
        var CurrencyExchangeRate: array[2] of Record "Currency Exchange Rate";
        var AddnlReportingCurrencyAmount: array[2] of Decimal;
        BankAccountNo: array[2] of Code[20];
        CurrencyFCY: Code[10];
        CurrencyACY: Code[10])
    var
        Index: Integer;
    begin
        for Index := 1 to ArrayLen(BankAccountNo) do begin
            CreateJournalLineForInvoice(
            GenJournalLine[Index], GenJournalLine[Index]."Account Type"::"Bank Account",
            BankAccountNo[Index], LibraryRandom.RandDec(100, 2) + 100);
            ModifyGeneralJournalLine(GenJournalLine[Index], GenJournalLine[Index]."Bal. Gen. Posting Type"::Purchase, CurrencyFCY);
            LibraryERM.PostGeneralJnlLine(GenJournalLine[Index]);
            AddnlReportingCurrencyAmount[Index] := CalculateAdditionalAmount(CurrencyExchangeRate[Index], CurrencyACY, GenJournalLine[Index]."Amount (LCY)");
            ModifyCurrencyExchangeRate(CurrencyExchangeRate[Index]);
        end;
    end;

    local procedure VerifyAdjExchEntryExistsOnlyForSpecificBank(BankAccountNo: array[2] of Code[20])
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        BankAccountLedgerEntry.SetRange("Document No.", BankAccountNo[1]);
        Assert.IsTrue(BankAccountLedgerEntry.Count > 1, StrSubstNo(BankExchRateAdjustedErr, BankAccountNo[1]));
        BankAccountLedgerEntry.SetRange("Document No.", BankAccountNo[2]);
        Assert.IsFalse(BankAccountLedgerEntry.Count > 1, StrSubstNo(BankExchRateAdjustedErr, BankAccountNo[2]));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyPostCustomerEntryHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries."Set Applies-to ID".Invoke();
        ApplyCustomerEntries."Post Application".Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure FiscalYearConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostApplicationHandler(var PostApplication: TestPage "Post Application")
    begin
        PostApplication.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CloseIncomeStatementReportHandler(var CloseIncomeStatement: TestRequestPage "Close Income Statement")
    var
        FieldValue: Variant;
    begin
        LibraryVariableStorage.Dequeue(FieldValue);
        CloseIncomeStatement.FiscalYearEndingDate.SetValue(FieldValue);
        LibraryVariableStorage.Dequeue(FieldValue);
        CloseIncomeStatement.GenJournalTemplate.SetValue(FieldValue);
        LibraryVariableStorage.Dequeue(FieldValue);
        CloseIncomeStatement.GenJournalBatch.SetValue(FieldValue);
        LibraryVariableStorage.Dequeue(FieldValue);
        CloseIncomeStatement.DocumentNo.SetValue(FieldValue);
        LibraryVariableStorage.Dequeue(FieldValue);
        CloseIncomeStatement.RetainedEarningsAcc.SetValue(FieldValue);
        CloseIncomeStatement.PostingDescription.SetValue('Test');
        CloseIncomeStatement.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure StatisticsMessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(ExchRateWasAdjustedTxt, Message);
    end;
}

