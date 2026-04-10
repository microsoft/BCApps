codeunit 134025 "ERM Unrealized VAT Customer"
{
    Permissions = TableData "Cust. Ledger Entry" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Unrealized VAT] [Sales]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPmtDiscSetup: Codeunit "Library - Pmt Disc Setup";
        LibrarySales: Codeunit "Library - Sales";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        isInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure TestUnrealizedVATEntry()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesInvoiceLine: Record "Sales Invoice Line";
        UnrealizedVATAmount: Decimal;
        DocumentNo: Code[20];
    begin
        // Test Unrealized VAT option to Percentage.

        // Setup: Setup Demonstration Data, Update Unrealized VAT Setup, Create and Post Sales Invoice.
        EnableUnrealizedSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::Percentage, false, false);

        DocumentNo := CreateSalesInvoice(SalesHeader, VATPostingSetup);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Execution: Make a Payment entry from General Journal Line, Apply Payment on Invoice from Customer Ledger Entries.
        FindSalesInvoiceLine(SalesInvoiceLine, DocumentNo);
        // Payment Amount can be anything between 1 and 99% of the full Amount.
        CreateAndPostPaymentJournaLine(
          GenJournalLine, SalesHeader."Sell-to Customer No.", '',
          -SalesInvoiceLine."Amount Including VAT" * LibraryRandom.RandInt(99) / 100);
        UnrealizedVATAmount := -Round(GenJournalLine.Amount * VATPostingSetup."VAT %" / (100 + VATPostingSetup."VAT %"));
        ApplyAndPostCustomerEntry(
          DocumentNo, GenJournalLine."Document No.", GenJournalLine."Document Type"::Payment,
          SalesHeader."Document Type");

        // Verification: Verify General Ledger Register for Unrealized VAT.
        VerifyUnrealizedVATEntry(
          GenJournalLine."Document No.", VATPostingSetup."Sales VAT Unreal. Account", UnrealizedVATAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestZeroVATUnrealizedVATEntry()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SalesHeader: Record "Sales Header";
        ZeroVATPostingSetup: Record "VAT Posting Setup";
        SalesInvoiceLine: Record "Sales Invoice Line";
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        DocumentNo: Code[20];
    begin
        // [SCENARIO 357562] Sales Unrealized VAT with VAT% = 0 is realized - G/L and VAT Entries are posted
        Initialize();
        LibraryERM.SetUnrealizedVAT(true);
        LibraryERM.CreateVATPostingSetupWithAccounts(ZeroVATPostingSetup, ZeroVATPostingSetup."VAT Calculation Type"::"Normal VAT", 1);
        UpdateVATPostingSetup(ZeroVATPostingSetup, ZeroVATPostingSetup."Unrealized VAT Type"::Percentage, false);

        // [GIVEN] Set VAT% = 0 in Unrealized VAT Posting Setup
        ZeroVATPostingSetup."VAT %" := 0;
        ZeroVATPostingSetup.Modify();

        // [GIVEN] Post Sales Invoice1. Transaction No = 100.
        DocumentNo := CreateSalesInvoice(SalesHeader, ZeroVATPostingSetup);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        GLEntry.FindLast();

        // [GIVEN] Post Payment1 where Amount is the full Invoice Amount. Transaction No = 101.
        FindSalesInvoiceLine(SalesInvoiceLine, DocumentNo);
        CreateAndPostPaymentJournaLine(
          GenJournalLine, SalesHeader."Sell-to Customer No.", '', -SalesInvoiceLine."Amount Including VAT");

        // [GIVEN] Apply Payment1 on Invoice1 from Customer Ledger Entries. Transaction No = 102.
        ApplyAndPostCustomerEntry(
          DocumentNo, GenJournalLine."Document No.", GenJournalLine."Document Type"::Payment,
          SalesHeader."Document Type");

        // [WHEN] Post Sales Invoice2. Transaction No = 103.
        CreateSalesInvoice(SalesHeader, ZeroVATPostingSetup);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] (Invoice1) Verify VAT Entry is realized - Remaining Unrealized Amounts are 0
        // [THEN] (Invoice1) Unrealized VAT Transaction No = 100
        // [THEN] (Invoice1) Realized VAT Transaction No = 102
        VerifyUnrealizedVATEntryIsRealized(GenJournalLine."Document No.", GLEntry."Transaction No.", GLEntry."Transaction No." + 2);
        // [THEN] (Invoice1) Verify zero G/L Entry is posted for Realized VAT
        VerifyUnrealizedVATEntry(GenJournalLine."Document No.", ZeroVATPostingSetup."Sales VAT Unreal. Account", 0);
        // [THEN] (Invoice2) Unrealized VAT Transaction No = 103 (TFS 305387)
        FindLastVATEntry(VATEntry, DocumentNo);
        VATEntry.TestField("Transaction No.", GLEntry."Transaction No." + 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnrealizedVATFullyPaid()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesInvoiceLine: Record "Sales Invoice Line";
        DocumentNo: Code[20];
    begin
        // Test Unrealized VAT option to First (Fully Paid).

        // 1.Setup: Update Unrealized VAT Setup, Create and Post Sales Invoice.
        EnableUnrealizedSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::"First (Fully Paid)", false, false);

        DocumentNo := CreateSalesInvoice(SalesHeader, VATPostingSetup);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // 2. Exercise: Create and Apply Payment on Invoice from Customer Ledger Entries.
        FindSalesInvoiceLine(SalesInvoiceLine, DocumentNo);
        // Payment Amount should be half of VAT Amount.
        CreateAndPostPaymentJournaLine(
          GenJournalLine, SalesHeader."Sell-to Customer No.", '', -SalesInvoiceLine."Amount Including VAT" - SalesInvoiceLine.Amount / 2);
        ApplyAndPostCustomerEntry(
          DocumentNo, GenJournalLine."Document No.", GenJournalLine."Document Type"::Payment,
          SalesHeader."Document Type");

        // 3. Verify: Verify General Ledger Entry for Unrealized VAT.
        VerifyGLEntryForFullyPaid(
          VATPostingSetup."Sales VAT Unreal. Account", SalesInvoiceLine.Amount - SalesInvoiceLine."Amount Including VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnrealizedVATPercentageApply()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        PostedInvoiceNo: Code[20];
    begin
        // Test Unrealized VAT option to Percentage and Apply.

        // 1. Setup: Update Unrealized VAT Setup, Create and Post Sales Invoice.
        EnableUnrealizedSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::Percentage, false, false);

        PostedInvoiceNo := CreateSalesInvoiceWithGL(SalesHeader, VATPostingSetup);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // 2. Exercise: Create, Post and Apply Credit Memo.
        ApplyAndPostCustomerEntry(
          PostedInvoiceNo, CreateAndPostCreditMemo(PostedInvoiceNo, SalesHeader."Sell-to Customer No."),
          SalesHeader."Document Type"::"Credit Memo", SalesHeader."Document Type");

        // 3. Verify: Verify that Credit Memo Applies to Invoice.
        VerifyCustomerLedgerEntry(SalesHeader."Sell-to Customer No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnrealizedLossAfterAdjustRate()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesLine: Record "Sales Line";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        Amount: Decimal;
        CurrencyUpdateFactor: Decimal;
        DocumentNo: Code[20];
    begin
        // Test Detailed Customer Ledger Entry after running Adjust Exchange Batch Report.

        // 1. Setup: Update General Ledger Setup, Unrealized VAT Setup, Create new Currency with Exchange Rates, Create and
        // Post Sales Credit Memo with Currency.
        EnableUnrealizedSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::Percentage, false, false);
        CreateCurrencyWithExchangeRate(CurrencyExchangeRate);

        DocumentNo := CreateAndPostSalesDocument(SalesLine, VATPostingSetup, CurrencyExchangeRate."Currency Code");
        CurrencyUpdateFactor := LibraryRandom.RandDec(100, 2);  // Use Random because value is not important.

        // 2. Exercise: Modify Exchange Rate with greater value and Run Adjust Exchange Rate Batch report.
        ModifyAmountInExchangeRate(CurrencyExchangeRate, CurrencyUpdateFactor);
        LibraryERM.RunExchRateAdjustmentSimple(CurrencyExchangeRate."Currency Code", WorkDate(), WorkDate());
        Amount :=
          Round(CalculateCreditMemoAmount(DocumentNo, SalesLine.Type::Item) * (1 + SalesLine."VAT %" / 100) +
            CalculateCreditMemoAmount(DocumentNo, SalesLine.Type::"G/L Account"));

        // 3. Verify: Verify Detailed Customer Ledger Entry for Unrealized Loss Document Type..
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", DocumentNo);
        VerifyDetailedCustomerEntry(
          CustLedgerEntry."Entry No.", DetailedCustLedgEntry."Entry Type"::"Unrealized Loss", DetailedCustLedgEntry."Document Type"::" ", 0,
          -Round(Amount * CurrencyUpdateFactor / CurrencyExchangeRate."Exchange Rate Amount"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnrealizedVATWithExchangeRate()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesLine: Record "Sales Line";
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        CurrencyExchangeRate2: Record "Currency Exchange Rate";
        Amount: Decimal;
        CurrencyUpdateFactor: Decimal;
        DocumentNo: Code[20];
    begin
        // Test Unrealized Loss and Realized Loss entries after Applying Refund on Credit Memo.

        // 1. Setup: Update General Ledger Setup, Unrealized VAT Setup, Create two Currencies with Exchange Rates, Create and
        // Post Sales Credit Memo with Currency, Modify Exchange Rate with greater value and Run Adjust Exchange Rate Batch report.
        EnableUnrealizedSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::Percentage, true, true);

        CreateCurrencyWithExchangeRate(CurrencyExchangeRate);
        CreateCurrencyWithExchangeRate(CurrencyExchangeRate2);
        DocumentNo := CreateAndPostSalesDocument(SalesLine, VATPostingSetup, CurrencyExchangeRate."Currency Code");
        CurrencyUpdateFactor := LibraryRandom.RandDec(100, 2);  // Use Random because value is not important.
        ModifyAmountInExchangeRate(CurrencyExchangeRate, CurrencyUpdateFactor);
        LibraryERM.RunExchRateAdjustmentSimple(CurrencyExchangeRate."Currency Code", WorkDate(), WorkDate());
        Amount :=
          Round(CalculateCreditMemoAmount(DocumentNo, SalesLine.Type::Item) * (1 + SalesLine."VAT %" / 100) +
            CalculateCreditMemoAmount(DocumentNo, SalesLine.Type::"G/L Account"));

        // 2. Exercise: Create and Post General Journal with Document Type Refund and different Currency Code, Apply Refund on Credit Memo.
        CreateAndPostGeneralJournal(GenJournalLine, SalesLine."Sell-to Customer No.", CurrencyExchangeRate2."Currency Code", 0);
        ApplyAndPostCustomerEntry(
          DocumentNo, GenJournalLine."Document No.", GenJournalLine."Document Type"::Refund, SalesLine."Document Type");

        // 3. Verify: Verify Detailed Customer Ledger entries for Credit Memo, Refund and G/L Entry for Unrealized VAT.
        VerifyDetailedEntryCreditMemo(CurrencyExchangeRate, GenJournalLine, DocumentNo, Amount, CurrencyUpdateFactor);
        VerifyDetailedEntryRefund(CurrencyExchangeRate, GenJournalLine);

        // Tear Down
        VATPostingSetup.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnrealizedVATWithCreditMemo()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GLEntry: Record "G/L Entry";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
    begin
        // Test G/L Entry for Unrealized VAT after Applying Refund on Credit Memo.

        // 1. Setup: Update General Ledger Setup, Unrealized VAT Setup, Create Sales Header with document Type Credit Memo, Sales Line
        // and Post the Credit Memo.
        EnableUnrealizedSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::Percentage, true, true);

        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::"Credit Memo",
          CreateCustomerWithPaymentTerms(VATPostingSetup."VAT Bus. Posting Group"));
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"));
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, false, false);

        // 2. Exercise: Create and Post General Journal for Refund and apply it on Credit Memo.
        // Use Random for Date Formula.
        CreateAndPostGeneralJournal(GenJournalLine, SalesHeader."Sell-to Customer No.", '', LibraryRandom.RandInt(5));
        ApplyAndPostCustomerEntry(
          DocumentNo, GenJournalLine."Document No.", GenJournalLine."Document Type",
          SalesHeader."Document Type");

        // 3. Verify: Verify G/L Entry for Unrealized VAT.
        FindGLEntry(
          GLEntry, VATPostingSetup."Sales VAT Unreal. Account", GLEntry."Document Type"::Refund, GenJournalLine."Document No.");
        GLEntry.TestField(Amount, -Round(GenJournalLine.Amount * VATPostingSetup."VAT %" / (VATPostingSetup."VAT %" + 100)));

        // Tear Down
        VATPostingSetup.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnrealizedVATWithCurrencies()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesLine: Record "Sales Line";
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        CurrencyExchangeRate2: Record "Currency Exchange Rate";
        GLEntry: Record "G/L Entry";
        DocumentNo: Code[20];
    begin
        // Test G/L Entry for Unrealized VAT after Applying Refund on Credit Memo with different Currencies.

        // 1. Setup: Update General Ledger Setup, Unrealized VAT Setup, Create 2 Currencies with Exchange Rates, Create Sales Header
        // with document Type Credit Memo having first Currency, Sales Line and Post the Credit Memo.
        EnableUnrealizedSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::Percentage, true, true);

        CreateCurrencyWithExchangeRate(CurrencyExchangeRate);
        CreateCurrencyWithExchangeRate(CurrencyExchangeRate2);
        DocumentNo := CreateAndPostSalesDocument(SalesLine, VATPostingSetup, CurrencyExchangeRate."Currency Code");

        // 2. Exercise: Create and Post General Journal for Refund with second Currency and apply it on Credit Memo.
        // Use Random for Date Formula.
        CreateAndPostGeneralJournal(
          GenJournalLine, SalesLine."Sell-to Customer No.", CurrencyExchangeRate2."Currency Code", LibraryRandom.RandInt(5));
        ApplyAndPostCustomerEntry(
          DocumentNo, GenJournalLine."Document No.", GenJournalLine."Document Type",
          SalesLine."Document Type");

        // 3. Verify: Verify G/L Entry for Unrealized VAT.
        VerifyGLEntryForUnrealizedVAT(
          GLEntry."Document Type"::Refund, GenJournalLine."Document No.",
          VATPostingSetup."Sales VAT Unreal. Account", CurrencyExchangeRate."Currency Code",
          CalculateGLAmount(CurrencyExchangeRate, GenJournalLine, SalesLine, DocumentNo));

        // Tear Down
        VATPostingSetup.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnrealizedVATWithSameCurrency()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        GLEntry: Record "G/L Entry";
        DocumentNo: Code[20];
    begin
        // Test G/L Entry for Unrealized VAT after Applying Refund on Credit Memo with same Currency.

        // 1. Setup: Update General Ledger Setup, Unrealized VAT Setup, Create Currency with Exchange Rate, Create Sales Header
        // with document Type Credit Memo having Currency, Sales Line and Post the Credit Memo.
        EnableUnrealizedSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::Percentage, true, true);

        CreateCurrencyWithExchangeRate(CurrencyExchangeRate);
        CreateSalesHeaderWithCurrency(SalesHeader, VATPostingSetup."VAT Bus. Posting Group", CurrencyExchangeRate."Currency Code");
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"));
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, false, false);

        // 2. Exercise: Create and Post General Journal for Refund with Currency and apply it on Credit Memo.
        // Use Random for Date Formula.
        CreateAndPostGeneralJournal(
          GenJournalLine, SalesHeader."Sell-to Customer No.", CurrencyExchangeRate."Currency Code", LibraryRandom.RandInt(5));
        ApplyAndPostCustomerEntry(
          DocumentNo, GenJournalLine."Document No.", GenJournalLine."Document Type",
          SalesHeader."Document Type");

        // 3. Verify: Verify G/L Entry for Unrealized VAT.
        VerifyGLEntryForUnrealizedVAT(
          GLEntry."Document Type"::Refund, GenJournalLine."Document No.",
          VATPostingSetup."Sales VAT Unreal. Account", CurrencyExchangeRate."Currency Code",
          CalculateGLAmount(CurrencyExchangeRate, GenJournalLine, SalesLine, DocumentNo));

        // Tear Down
        VATPostingSetup.Delete();
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesHandler,PostApplicationHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ApplyCreditMemoToInvoice()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // Test Application of Credit Memo to Invoice using page testability having Unrealized VAT Type as Percentage.

        // 1. Setup: Update Unrealized VAT Setup as TRUE on General Ledger Setup and Unrealized VAT Type as Percentage on VAT Posting
        // Setup. Create and post Sales Invoice. Create and post Credit Memo.
        EnableUnrealizedSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::Percentage, true, false);

        CreateAndPostSalesInvoiceAndCreditMemo(SalesHeader, VATPostingSetup, SalesInvoiceLine);

        // 2. Exercise: Apply Credit Memo on Invoice from Customer Ledger Entries page.
        ApplyCustomerLedgerEntries(SalesHeader."Sell-to Customer No.", CustLedgerEntry."Document Type"::"Credit Memo");

        // 3. Verify: Verify the Remaining Amount on Credit Memo applied to Invoice.
        VerifyRemainingAmountOnLedger(
          SalesHeader."Sell-to Customer No.", SalesInvoiceLine."Document No.", SalesInvoiceLine."Amount Including VAT" / 2);
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesHandler,PostApplicationHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ApplyPaymentToInvoice()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // Test Application of Credit Memo and Payment to Invoice using page testability having Unrealized VAT Type as Percentage.

        // 1. Setup: Update Unrealized VAT Setup as TRUE on General Ledger Setup and Unrealized VAT Type as Percentage on VAT Posting
        // Setup. Create and post Sales Invoice. Create and post Credit Memo.
        EnableUnrealizedSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::Percentage, true, false);

        CreateAndPostSalesInvoiceAndCreditMemo(SalesHeader, VATPostingSetup, SalesInvoiceLine);

        // Apply Credit Memo on Invoice from Customer Ledger Entries page.
        ApplyCustomerLedgerEntries(SalesHeader."Sell-to Customer No.", CustLedgerEntry."Document Type"::"Credit Memo");

        // 2. Exercise: Post and Apply Payment to Invoice for remaining Amount.
        CreateAndPostPaymentJournaLine(
          GenJournalLine, SalesHeader."Sell-to Customer No.", '', -SalesInvoiceLine."Amount Including VAT" / 2);

        // Apply Payment on Invoice from Customer Ledger Entries Page.
        ApplyCustomerLedgerEntries(SalesHeader."Sell-to Customer No.", CustLedgerEntry."Document Type"::Payment);

        // 3. Verify: Verify the Remaining Amount on Invoice applied by Credit Memo and Payment.
        VerifyRemainingAmountOnLedger(SalesHeader."Sell-to Customer No.", SalesInvoiceLine."Document No.", 0);
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesHandler,PostApplicationHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UnrealizedVATApplyPayment()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        LibrarySales: Codeunit "Library - Sales";
        DocumentNo: Code[20];
        UnrealizedVATAmount: Decimal;
    begin
        // Test Unrealized VAT Amount in G/L Entry for Half Payment to Invoice using page testability having Unrealized VAT Type
        // as Percentage.

        // 1. Setup: Update Unrealized VAT Setup as TRUE on General Ledger Setup and Unrealized VAT Type as Percentage on VAT Posting
        // Create and post Sales Invoice.
        EnableUnrealizedSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::Percentage, true, false);

        LibrarySales.SetStockoutWarning(false);
        DocumentNo := CreateSalesInvoice(SalesHeader, VATPostingSetup);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        FindSalesInvoiceLine(SalesInvoiceLine, DocumentNo);

        // 2. Exercise: Post and Apply Payment to Invoice for half the Invoice Amount.
        CreateAndPostPaymentJournaLine(
          GenJournalLine, SalesHeader."Sell-to Customer No.", '', -SalesInvoiceLine."Amount Including VAT" / 2);
        UnrealizedVATAmount := -Round(GenJournalLine.Amount * VATPostingSetup."VAT %" / (100 + VATPostingSetup."VAT %"));

        // Apply Payment on Invoice from Customer Ledger Entries Page.
        ApplyCustomerLedgerEntries(SalesHeader."Sell-to Customer No.", CustLedgerEntry."Document Type"::Payment);

        // 3. Verify: Verify G/L Entry for Unrealized VAT Amount.
        VerifyUnrealizedVATEntry(GenJournalLine."Document No.", VATPostingSetup."Sales VAT Unreal. Account", UnrealizedVATAmount);
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesHandler,PostApplicationHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UnrealizedVATWithDiffCurrency()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesLine: Record "Sales Line";
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        CurrencyExchangeRate2: Record "Currency Exchange Rate";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GLEntry: Record "G/L Entry";
    begin
        // Test Unrealized VAT Amount in G/L Entry for Payment to Invoice using page testability having Unrealized VAT Type
        // as Percentage with different currencies.

        // 1. Setup: Update General Ledger Setup, Unrealized VAT Setup. Create two Currencies with Exchange Rates.
        // Create Sales and Post Invoice.
        EnableUnrealizedSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::Percentage, true, false);
        LibrarySales.SetApplnBetweenCurrencies(SalesReceivablesSetup."Appln. between Currencies"::All);
        LibrarySales.SetStockoutWarning(false);
        CreateCurrencyWithExchangeRate(CurrencyExchangeRate);
        CreateCurrencyWithExchangeRate(CurrencyExchangeRate2);
        CreateAndPostSalesInvoice(SalesLine, VATPostingSetup, CurrencyExchangeRate."Currency Code");

        // 2. Exercise: Create and Post General Journal for Payment with second Currency and apply it on Invoice using Random Values.
        CreateAndPostPaymentJournaLine(
          GenJournalLine, SalesLine."Sell-to Customer No.",
          CurrencyExchangeRate2."Currency Code", -(LibraryRandom.RandDec(100, 2) + 100));

        ApplyCustomerLedgerEntries(SalesLine."Sell-to Customer No.", CustLedgerEntry."Document Type"::Payment);

        // 3. Verify: Verify G/L Entry for Unrealized VAT.
        VerifyGLEntryForUnrealizedVAT(
          GLEntry."Document Type"::Payment, GenJournalLine."Document No.",
          VATPostingSetup."Sales VAT Unreal. Account", CurrencyExchangeRate."Currency Code",
          -CalculateGLAmountPayment(CurrencyExchangeRate, GenJournalLine, SalesLine));
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesHandler,PostApplicationHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UnrealizedVATWithFCY()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesLine: Record "Sales Line";
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GLEntry: Record "G/L Entry";
    begin
        // Test Unrealized VAT Amount in G/L Entry for Payment to Invoice using page testability having Unrealized VAT Type
        // as Percentage with currency.

        // 1. Setup: Update General Ledger Setup, Unrealized VAT Setup. Create Currencies with Exchange Rates.
        // Create Sales and Post Invoice.
        EnableUnrealizedSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::Percentage, true, false);
        LibrarySales.SetStockoutWarning(false);
        CreateCurrencyWithExchangeRate(CurrencyExchangeRate);
        CreateAndPostSalesInvoice(SalesLine, VATPostingSetup, CurrencyExchangeRate."Currency Code");

        // 2. Exercise: Create and Post General Journal for Payment with and apply it on Invoice.
        CreateAndPostPaymentJournaLine(
          GenJournalLine, SalesLine."Sell-to Customer No.",
          CurrencyExchangeRate."Currency Code", -(SalesLine."Line Amount" + (SalesLine."Line Amount" * SalesLine."VAT %" / 100)));
        ApplyCustomerLedgerEntries(SalesLine."Sell-to Customer No.", CustLedgerEntry."Document Type"::Payment);

        // 3. Verify: Verify G/L Entry for Unrealized VAT.
        VerifyGLEntryForUnrealizedVAT(
          GLEntry."Document Type"::Payment, GenJournalLine."Document No.",
          VATPostingSetup."Sales VAT Unreal. Account", CurrencyExchangeRate."Currency Code",
          -CalculateGLAmountPayment(CurrencyExchangeRate, GenJournalLine, SalesLine));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnrealizedVATWithACY()
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
        AdditionalCurrencyBaseAmount: Decimal;
        AdditionalCurrencyVATAmount: Decimal;
    begin
        // Test and verify Additional Currency VAT Amount and Additional Currency Base Amount on VAT Entry.

        // 1. Setup: Setup Additional Currency in General Ledger Setup. Update Unrealized VAT in General Ledger Setup.
        // Create Sales Invoice. Post Sales Invoice. Calculate Additional Currency VAT Amount.
        EnableUnrealizedSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::Percentage, false, false);
        CreateAdditionalCurrencySetup(CurrencyExchangeRate);

        DocumentNo := CreateSalesInvoice(SalesHeader, VATPostingSetup);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        FindSalesInvoiceLine(SalesInvoiceLine, DocumentNo);
        AdditionalCurrencyBaseAmount :=
          LibraryERM.ConvertCurrency(SalesInvoiceLine."Line Amount", '', CurrencyExchangeRate."Currency Code", WorkDate());
        AdditionalCurrencyVATAmount := Round(AdditionalCurrencyBaseAmount * SalesInvoiceLine."VAT %" / 100);

        // 2. Exercise: Create and Post General Journal for Payment with and apply it on Invoice.
        CreateAndPostPaymentJournaLine(GenJournalLine, SalesHeader."Sell-to Customer No.", '', -SalesInvoiceLine."Amount Including VAT");
        ApplyAndPostCustomerEntry(
          DocumentNo, GenJournalLine."Document No.", GenJournalLine."Document Type"::Payment, SalesHeader."Document Type");

        // 3. Verify: Additional Currency Amount and Additional Currency Base on VAT Entry.
        VerifyValuesOnVATEntry(
          GenJournalLine."Document No.", GenJournalLine."Document Type", -AdditionalCurrencyVATAmount, -AdditionalCurrencyBaseAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithNegativeLinePartialApply()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
        VATBaseAmount: array[2] of Decimal;
        VATAmount: array[2] of Decimal;
        DocAmount: Decimal;
        AmountToApply: Decimal;
        Fraction: Decimal;
        AmountRoundingPrecision: Decimal;
    begin
        // [FEATURE] [Partial Payment]
        // [SCENARIO 363444] Unrealized VAT Entries are filled with percentage amount values in case of partial applying Sales Invoice with negative line

        // [GIVEN] Enable GLSetup."Unealized VAT".  Config "VAT Posting Setup"."Unrealized VAT Type" = Percentage.
        EnableUnrealizedSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::Percentage, false, false);
        AmountRoundingPrecision := LibraryERM.GetAmountRoundingPrecision();

        // [GIVEN] Create and post Sales Invoice with two lines:
        // [GIVEN] Positive Line: Quantity = 1,"Unit Price" = 1000, VAT Amount = 200
        // [GIVEN] Negative Line: Quantity = -1,"Unit Price" = 800, VAT Amount = 160
        DocumentNo :=
          CreatePostSalesInvoiceWithNegativeLine(SalesHeader, VATPostingSetup, VATBaseAmount, VATAmount, AmountRoundingPrecision);

        // [GIVEN] Post customer partial payment with amount = 30% of Invoice
        DocAmount := VATBaseAmount[1] + VATAmount[1] - (VATBaseAmount[2] + VATAmount[2]);
        Fraction := LibraryRandom.RandIntInRange(3, 5);
        AmountToApply := Round(DocAmount / Fraction, AmountRoundingPrecision);
        CreateAndPostPaymentJournaLine(GenJournalLine, SalesHeader."Bill-to Customer No.", '', -AmountToApply);

        // [WHEN] Apply payment to the invoice
        ApplyAndPostCustomerEntry(
          DocumentNo, GenJournalLine."Document No.", GenJournalLine."Document Type"::Payment,
          SalesHeader."Document Type");

        // [THEN] Positive realized VAT Entry has Base = 240, Amount = 48  (30% of 160)
        VerifyPositiveVATEntry(
          GenJournalLine."Document No.", Round(VATBaseAmount[2] / Fraction), Round(VATAmount[2] / Fraction));

        // [THEN] Negative realized VAT Entry has Base = -300, Amount = -60 (30% of 200)
        VerifyNegativeVATEntry(
          GenJournalLine."Document No.", -Round(VATBaseAmount[1] / Fraction), -Round(VATAmount[1] / Fraction));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ThreePartialPaymentsOfUnrealVATSalesInvoiceWithThreeLines()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: array[3] of Record "Sales Line";
        CustomerNo: Code[20];
        InvoiceNo: Code[20];
        PaymentNo: array[3] of Code[20];
        TotalAmount: Decimal;
        PmtAmount: array[2] of Decimal;
        UnrealizedVATEntryNo: array[3] of Integer;
    begin
        // [SCENARIO 380404] Several partial payments of Sales Invoice with Unrealized VAT and several sales lines

        // [GIVEN] Unrealized VAT Posting Setup with VAT% = 20
        EnableUnrealizedSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::Percentage, false, false);
        // [GIVEN] Sales Invoice with three different G/l Account's lines:
        CustomerNo := LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group");
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        // [GIVEN] Line1: Amount = 3000, Amount Including VAT = 3600
        CreateSalesLineWithGLAccount(
          SalesLine[1], SalesHeader, VATPostingSetup, 1, LibraryRandom.RandDecInRange(5000, 6000, 2));
        // [GIVEN] Line2: Amount = 2000, Amount Including VAT = 2400
        CreateSalesLineWithGLAccount(
          SalesLine[2], SalesHeader, VATPostingSetup, 1, SalesLine[1].Amount - LibraryRandom.RandDecInRange(1000, 2000, 2));
        // [GIVEN] Line3: Amount = 1000, Amount Including VAT = 1200
        CreateSalesLineWithGLAccount(
          SalesLine[3], SalesHeader, VATPostingSetup, 1, SalesLine[2].Amount - LibraryRandom.RandDecInRange(1000, 2000, 2));
        // [GIVEN] Post Sales Invoice. Total Amount Including VAT = 7200
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        TotalAmount := SalesLine[1]."Amount Including VAT" + SalesLine[2]."Amount Including VAT" + SalesLine[3]."Amount Including VAT";
        // [GIVEN] Create apply and post partial payment "P1" with Amount = 7200 * 0.1 = 720 (10%)
        PmtAmount[1] := Round(TotalAmount * 0.1);
        PaymentNo[1] := CreateApplyAndPostPayment(CustomerNo, InvoiceNo, -PmtAmount[1]);
        // [GIVEN] Create apply and post partial payment "P2" with Amount = 7200 * 0.6 = 4320 (60%)
        PmtAmount[2] := Round(TotalAmount * 0.6);
        PaymentNo[2] := CreateApplyAndPostPayment(CustomerNo, InvoiceNo, -PmtAmount[2]);
        // [WHEN] Create apply and post partial (final) payment "P3" with Amount = 7200 * 0.3 = 2160 (30%)
        PaymentNo[3] := CreateApplyAndPostPayment(CustomerNo, InvoiceNo, -(TotalAmount - PmtAmount[1] - PmtAmount[2]));

        // [THEN] Customer's Invoice and Payments ledger entries are closed ("Remaining Amount" = 0)
        VerifyCustomerLedgerEntryAmounts(CustomerNo, InvoiceNo, TotalAmount, 0);
        VerifyCustomerLedgerEntryAmounts(CustomerNo, PaymentNo[1], -PmtAmount[1], 0);
        VerifyCustomerLedgerEntryAmounts(CustomerNo, PaymentNo[2], -PmtAmount[2], 0);
        VerifyCustomerLedgerEntryAmounts(CustomerNo, PaymentNo[3], -(TotalAmount - PmtAmount[1] - PmtAmount[2]), 0);

        // [THEN] There are 3 closed Invoice Unrealized VAT Entries ("Remaining Unrealized Base" = "Remaining Unrealized Amount" = 0):
        // [THEN] "Entry No." = 1, "Unrealized Base" = 1000, "Unrealized Amount" = 200
        // [THEN] "Entry No." = 2, "Unrealized Base" = 2000, "Unrealized Amount" = 400
        // [THEN] "Entry No." = 3, "Unrealized Base" = 3000, "Unrealized Amount" = 600
        VerifyThreeUnrealizedVATEntry(UnrealizedVATEntryNo, CustomerNo, InvoiceNo, SalesLine);

        // [THEN] There are 3 realized VAT Entries related to payment "P1" :
        // [THEN] "Document No." = "P1", "Base" = 100, "Amount" = 20, "Unrealized VAT Entry No." = 1
        // [THEN] "Document No." = "P1", "Base" = 200, "Amount" = 40, "Unrealized VAT Entry No." = 2
        // [THEN] "Document No." = "P1", "Base" = 300, "Amount" = 60, "Unrealized VAT Entry No." = 3
        VerifyThreeRealizedVATEntry(UnrealizedVATEntryNo, CustomerNo, PaymentNo[1], SalesLine, 0.1);

        // [THEN] There are 3 realized VAT Entries related to payment "P2" :
        // [THEN] "Document No." = "P2", "Base" = 600, "Amount" = 120, "Unrealized VAT Entry No." = 1
        // [THEN] "Document No." = "P2", "Base" = 1200, "Amount" = 240, "Unrealized VAT Entry No." = 2
        // [THEN] "Document No." = "P2", "Base" = 1800, "Amount" = 360, "Unrealized VAT Entry No." = 3
        VerifyThreeRealizedVATEntry(UnrealizedVATEntryNo, CustomerNo, PaymentNo[2], SalesLine, 0.6);

        // [THEN] There are 3 realized VAT Entries related to payment "P3" :
        // [THEN] "Document No." = "P3", "Base" = 300, "Amount" = 60, "Unrealized VAT Entry No." = 1
        // [THEN] "Document No." = "P3", "Base" = 600, "Amount" = 120, "Unrealized VAT Entry No." = 2
        // [THEN] "Document No." = "P3", "Base" = 900, "Amount" = 180, "Unrealized VAT Entry No." = 3
        VerifyThreeRealizedVATEntry(UnrealizedVATEntryNo, CustomerNo, PaymentNo[3], SalesLine, 0.3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FCYCrMemoToInvoiceHalfMinusPaidDownExchRate()
    var
        SalesHeader: Record "Sales Header";
        InvoiceNo: Code[20];
        CrMemoNo: Code[20];
    begin
        // [FEATURE] [Currency]
        // [SCENARIO 261852] Post sales credit memo applied to partially paid invoice (credit memo = invoice, payment < 1/2 invoice)
        // [SCENARIO 261852] in case of unrealized VAT, FCY, custom amounts, Exchange:Relational ratio < 1
        Initialize();

        // [GIVEN] Unrealized VAT Setup with "Unrealized VAT Type" = Percentage, "VAT %" = 18
        // [GIVEN] Currency with Exchange:Relational ratio = 1/100:1
        // [GIVEN] Posted Invoice with FCY Amount = 1000
        // [GIVEN] Posted Payment with FCY Amount = 589.99
        // [GIVEN] Payment is applied to the Invoice
        // [GIVEN] Credit Memo with FCY Amount = 1000
        // [GIVEN] Apply Credit Memo to the Invoice
        PerformScenarioTFS261852(SalesHeader, InvoiceNo, 18, 1 / 100, 1000, 1000, 589.99);

        // [WHEN] Post the Credit Memo
        CrMemoNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The Credit Memo has been posted. Invoice VAT has been fully realized. Credit Memo VAT has been realized by 50000.85\9000.15
        VerifyInvAndCrMemoVATEntries(InvoiceNo, CrMemoNo, 100000, 18000, 50000.85, 9000.15);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FCYCrMemoToInvoiceHalfPlusPaidDownExchRate()
    var
        SalesHeader: Record "Sales Header";
        InvoiceNo: Code[20];
        CrMemoNo: Code[20];
    begin
        // [FEATURE] [Currency]
        // [SCENARIO 261852] Post sales credit memo applied to partially paid invoice (credit memo = invoice, payment > 1/2 invoice)
        // [SCENARIO 261852] in case of unrealized VAT, FCY, custom amounts, Exchange:Relational ratio < 1
        Initialize();

        // [GIVEN] Unrealized VAT Setup with "Unrealized VAT Type" = Percentage, "VAT %" = 18
        // [GIVEN] Currency with Exchange:Relational ratio = 1/100:1
        // [GIVEN] Posted Invoice with FCY Amount = 1000
        // [GIVEN] Posted Payment with FCY Amount = 590.01
        // [GIVEN] Payment is applied to the Invoice
        // [GIVEN] Credit Memo with FCY Amount = 1000
        // [GIVEN] Apply Credit Memo to the Invoice
        PerformScenarioTFS261852(SalesHeader, InvoiceNo, 18, 1 / 100, 1000, 1000, 590.01);

        // [WHEN] Post the Credit Memo
        CrMemoNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The Credit Memo has been posted. Invoice VAT has been fully realized. Credit Memo VAT has been realized by 49999.15\8999.85
        VerifyInvAndCrMemoVATEntries(InvoiceNo, CrMemoNo, 100000, 18000, 49999.15, 8999.85);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FCYCrMemoToInvoiceHalfMinusPaidUpExchRate()
    var
        SalesHeader: Record "Sales Header";
        InvoiceNo: Code[20];
        CrMemoNo: Code[20];
    begin
        // [FEATURE] [Currency]
        // [SCENARIO 261852] Post sales credit memo applied to partially paid invoice (credit memo = invoice, payment < 1/2 invoice)
        // [SCENARIO 261852] in case of unrealized VAT, FCY, custom amounts, Exchange:Relational ratio > 1
        Initialize();

        // [GIVEN] Unrealized VAT Setup with "Unrealized VAT Type" = Percentage, "VAT %" = 18
        // [GIVEN] Currency with Exchange:Relational ratio = 100
        // [GIVEN] Posted Invoice with FCY Amount = 1000
        // [GIVEN] Posted Payment with FCY Amount = 589
        // [GIVEN] Payment is applied to the Invoice
        // [GIVEN] Credit Memo with FCY Amount = 1000
        // [GIVEN] Apply Credit Memo to the Invoice
        PerformScenarioTFS261852(SalesHeader, InvoiceNo, 18, 100, 1000, 1000, 589);

        // [WHEN] Post the Credit Memo
        CrMemoNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The Credit Memo has been posted. Invoice VAT has been fully realized. Credit Memo VAT has been realized by 5.01\0.9
        VerifyInvAndCrMemoVATEntries(InvoiceNo, CrMemoNo, 10, 1.8, 5.01, 0.9);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FCYCrMemoToInvoiceHalfPlusPaidUpExchRate()
    var
        SalesHeader: Record "Sales Header";
        InvoiceNo: Code[20];
        CrMemoNo: Code[20];
    begin
        // [FEATURE] [Currency]
        // [SCENARIO 261852] Post sales credit memo applied to partially paid invoice (credit memo = invoice, payment > 1/2 invoice)
        // [SCENARIO 261852] in case of unrealized VAT, FCY, custom amounts, Exchange:Relational ratio > 1
        Initialize();

        // [GIVEN] Unrealized VAT Setup with "Unrealized VAT Type" = Percentage, "VAT %" = 18
        // [GIVEN] Currency with Exchange:Relational ratio = 100
        // [GIVEN] Posted Invoice with FCY Amount = 1000
        // [GIVEN] Posted Payment with FCY Amount = 591
        // [GIVEN] Payment is applied to the Invoice
        // [GIVEN] Credit Memo with FCY Amount = 1000
        // [GIVEN] Apply Credit Memo to the Invoice
        PerformScenarioTFS261852(SalesHeader, InvoiceNo, 18, 100, 1000, 1000, 591);

        // [WHEN] Post the Credit Memo
        CrMemoNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The Credit Memo has been posted. Invoice VAT has been fully realized. Credit Memo VAT has been realized by 4.99\0.9
        VerifyInvAndCrMemoVATEntries(InvoiceNo, CrMemoNo, 10, 1.8, 4.99, 0.9);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FCYCrMemoOverInvoiceHalfMinusPaidDownExchRate()
    var
        SalesHeader: Record "Sales Header";
        InvoiceNo: Code[20];
        CrMemoNo: Code[20];
    begin
        // [FEATURE] [Currency]
        // [SCENARIO 261852] Post sales credit memo applied to partially paid invoice (credit memo > invoice, payment < 1/2 invoice)
        // [SCENARIO 261852] in case of unrealized VAT, FCY, custom amounts, Exchange:Relational ratio < 1
        Initialize();

        // [GIVEN] Unrealized VAT Setup with "Unrealized VAT Type" = Percentage, "VAT %" = 18
        // [GIVEN] Currency with Exchange:Relational ratio = 1/100:1
        // [GIVEN] Posted Invoice with FCY Amount = 1000
        // [GIVEN] Posted Payment with FCY Amount = 589.99
        // [GIVEN] Payment is applied to the Invoice
        // [GIVEN] Credit Memo with FCY Amount = 2000
        // [GIVEN] Apply Credit Memo to the Invoice
        PerformScenarioTFS261852(SalesHeader, InvoiceNo, 18, 1 / 100, 1000, 2000, 589.99);

        // [WHEN] Post the Credit Memo
        CrMemoNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The Credit Memo has been posted. Invoice VAT has been fully realized. Credit Memo VAT has been realized by 50000.85\9000.15
        VerifyInvAndCrMemoVATEntries(InvoiceNo, CrMemoNo, 200000, 36000, 50000.85, 9000.15);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FCYCrMemoOverInvoiceHalfPlusPaidDownExchRate()
    var
        SalesHeader: Record "Sales Header";
        InvoiceNo: Code[20];
        CrMemoNo: Code[20];
    begin
        // [FEATURE] [Currency]
        // [SCENARIO 261852] Post sales credit memo applied to partially paid invoice (credit memo > invoice, payment > 1/2 invoice)
        // [SCENARIO 261852] in case of unrealized VAT, FCY, custom amounts, Exchange:Relational ratio < 1
        Initialize();

        // [GIVEN] Unrealized VAT Setup with "Unrealized VAT Type" = Percentage, "VAT %" = 18
        // [GIVEN] Currency with Exchange:Relational ratio = 1/100:1
        // [GIVEN] Posted Invoice with FCY Amount = 1000
        // [GIVEN] Posted Payment with FCY Amount = 590.01
        // [GIVEN] Payment is applied to the Invoice
        // [GIVEN] Credit Memo with FCY Amount = 2000
        // [GIVEN] Apply Credit Memo to the Invoice
        PerformScenarioTFS261852(SalesHeader, InvoiceNo, 18, 1 / 100, 1000, 2000, 590.01);

        // [WHEN] Post the Credit Memo
        CrMemoNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The Credit Memo has been posted. Invoice VAT has been fully realized. Credit Memo VAT has been realized by 49999.15\8999.85
        VerifyInvAndCrMemoVATEntries(InvoiceNo, CrMemoNo, 200000, 36000, 49999.15, 8999.85);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FCYCrMemoOverInvoiceHalfMinusPaidUpExchRate()
    var
        SalesHeader: Record "Sales Header";
        InvoiceNo: Code[20];
        CrMemoNo: Code[20];
    begin
        // [FEATURE] [Currency]
        // [SCENARIO 261852] Post sales credit memo applied to partially paid invoice (credit memo > invoice, payment < 1/2 invoice)
        // [SCENARIO 261852] in case of unrealized VAT, FCY, custom amounts, Exchange:Relational ratio > 1
        Initialize();

        // [GIVEN] Unrealized VAT Setup with "Unrealized VAT Type" = Percentage, "VAT %" = 18
        // [GIVEN] Currency with Exchange:Relational ratio = 100
        // [GIVEN] Posted Invoice with FCY Amount = 1000
        // [GIVEN] Posted Payment with FCY Amount = 589
        // [GIVEN] Payment is applied to the Invoice
        // [GIVEN] Credit Memo with FCY Amount = 2000
        // [GIVEN] Apply Credit Memo to the Invoice
        PerformScenarioTFS261852(SalesHeader, InvoiceNo, 18, 100, 1000, 2000, 589);

        // [WHEN] Post the Credit Memo
        CrMemoNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The Credit Memo has been posted. Invoice VAT has been fully realized. Credit Memo VAT has been realized by 5.01\0.9
        VerifyInvAndCrMemoVATEntries(InvoiceNo, CrMemoNo, 20, 3.6, 5.01, 0.9);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FCYCrMemoOverInvoiceHalfPlusPaidUpExchRate()
    var
        SalesHeader: Record "Sales Header";
        InvoiceNo: Code[20];
        CrMemoNo: Code[20];
    begin
        // [FEATURE] [Currency]
        // [SCENARIO 261852] Post sales credit memo applied to partially paid invoice (credit memo > invoice, payment > 1/2 invoice)
        // [SCENARIO 261852] in case of unrealized VAT, FCY, custom amounts, Exchange:Relational ratio > 1
        Initialize();

        // [GIVEN] Unrealized VAT Setup with "Unrealized VAT Type" = Percentage, "VAT %" = 18
        // [GIVEN] Currency with Exchange:Relational ratio = 100
        // [GIVEN] Posted Invoice with FCY Amount = 1000
        // [GIVEN] Posted Payment with FCY Amount = 591
        // [GIVEN] Payment is applied to the Invoice
        // [GIVEN] Credit Memo with FCY Amount = 2000
        // [GIVEN] Apply Credit Memo to the Invoice
        PerformScenarioTFS261852(SalesHeader, InvoiceNo, 18, 100, 1000, 2000, 591);

        // [WHEN] Post the Credit Memo
        CrMemoNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The Credit Memo has been posted. Invoice VAT has been fully realized. Credit Memo VAT has been realized by 4.99\0.9
        VerifyInvAndCrMemoVATEntries(InvoiceNo, CrMemoNo, 20, 3.6, 4.99, 0.9);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FCYCrMemoLowerInvoiceHalfMinusPaidDownExchRate()
    var
        SalesHeader: Record "Sales Header";
        InvoiceNo: Code[20];
        CrMemoNo: Code[20];
    begin
        // [FEATURE] [Currency]
        // [SCENARIO 261852] Post sales credit memo applied to partially paid invoice (credit memo < invoice, payment < 1/2 invoice)
        // [SCENARIO 261852] in case of unrealized VAT, FCY, custom amounts, Exchange:Relational ratio < 1
        Initialize();

        // [GIVEN] Unrealized VAT Setup with "Unrealized VAT Type" = Percentage, "VAT %" = 18
        // [GIVEN] Currency with Exchange:Relational ratio = 1/100:1
        // [GIVEN] Posted Invoice with FCY Amount = 1000
        // [GIVEN] Posted Payment with FCY Amount = 589.99
        // [GIVEN] Payment is applied to the Invoice
        // [GIVEN] Credit Memo with FCY Amount = 800
        // [GIVEN] Apply Credit Memo to the Invoice
        PerformScenarioTFS261852(SalesHeader, InvoiceNo, 18, 1 / 100, 1000, 800, 589.99);

        // [WHEN] Post the Credit Memo
        CrMemoNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The Credit Memo has been posted. Invoice VAT has been fully realized. Credit Memo VAT has been realized by 50000.85\9000.15
        VerifyInvAndCrMemoVATEntries(InvoiceNo, CrMemoNo, 80000, 14400, 50000.85, 9000.15);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FCYCrMemoLowerInvoiceHalfPlusPaidDownExchRate()
    var
        SalesHeader: Record "Sales Header";
        InvoiceNo: Code[20];
        CrMemoNo: Code[20];
    begin
        // [FEATURE] [Currency]
        // [SCENARIO 261852] Post sales credit memo applied to partially paid invoice (credit memo < invoice, payment > 1/2 invoice)
        // [SCENARIO 261852] in case of unrealized VAT, FCY, custom amounts, Exchange:Relational ratio < 1
        Initialize();

        // [GIVEN] Unrealized VAT Setup with "Unrealized VAT Type" = Percentage, "VAT %" = 18
        // [GIVEN] Currency with Exchange:Relational ratio = 1/100:1
        // [GIVEN] Posted Invoice with FCY Amount = 1000
        // [GIVEN] Posted Payment with FCY Amount = 590.01
        // [GIVEN] Payment is applied to the Invoice
        // [GIVEN] Credit Memo with FCY Amount = 800
        // [GIVEN] Apply Credit Memo to the Invoice
        PerformScenarioTFS261852(SalesHeader, InvoiceNo, 18, 1 / 100, 1000, 800, 590.01);

        // [WHEN] Post the Credit Memo
        CrMemoNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The Credit Memo has been posted. Invoice VAT has been fully realized. Credit Memo VAT has been realized by 49999.15\8999.85
        VerifyInvAndCrMemoVATEntries(InvoiceNo, CrMemoNo, 80000, 14400, 49999.15, 8999.85);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FCYCrMemoLowerInvoiceHalfMinusPaidUpExchRate()
    var
        SalesHeader: Record "Sales Header";
        InvoiceNo: Code[20];
        CrMemoNo: Code[20];
    begin
        // [FEATURE] [Currency]
        // [SCENARIO 261852] Post sales credit memo applied to partially paid invoice (credit memo < invoice, payment < 1/2 invoice)
        // [SCENARIO 261852] in case of unrealized VAT, FCY, custom amounts, Exchange:Relational ratio > 1
        Initialize();

        // [GIVEN] Unrealized VAT Setup with "Unrealized VAT Type" = Percentage, "VAT %" = 18
        // [GIVEN] Currency with Exchange:Relational ratio = 100
        // [GIVEN] Posted Invoice with FCY Amount = 1000
        // [GIVEN] Posted Payment with FCY Amount = 589
        // [GIVEN] Payment is applied to the Invoice
        // [GIVEN] Credit Memo with FCY Amount = 800
        // [GIVEN] Apply Credit Memo to the Invoice
        PerformScenarioTFS261852(SalesHeader, InvoiceNo, 18, 100, 1000, 800, 589);

        // [WHEN] Post the Credit Memo
        CrMemoNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The Credit Memo has been posted. Invoice VAT has been fully realized. Credit Memo VAT has been realized by 5.01\0.9
        VerifyInvAndCrMemoVATEntries(InvoiceNo, CrMemoNo, 8, 1.44, 5.01, 0.9);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FCYCrMemoLowerInvoiceHalfPlusPaidUpExchRate()
    var
        SalesHeader: Record "Sales Header";
        InvoiceNo: Code[20];
        CrMemoNo: Code[20];
    begin
        // [FEATURE] [Currency]
        // [SCENARIO 261852] Post sales credit memo applied to partially paid invoice (credit memo < invoice, payment > 1/2 invoice)
        // [SCENARIO 261852] in case of unrealized VAT, FCY, custom amounts, Exchange:Relational ratio > 1
        Initialize();

        // [GIVEN] Unrealized VAT Setup with "Unrealized VAT Type" = Percentage, "VAT %" = 18
        // [GIVEN] Currency with Exchange:Relational ratio = 100
        // [GIVEN] Posted Invoice with FCY Amount = 1000
        // [GIVEN] Posted Payment with FCY Amount = 591
        // [GIVEN] Payment is applied to the Invoice
        // [GIVEN] Credit Memo with FCY Amount = 800
        // [GIVEN] Apply Credit Memo to the Invoice
        PerformScenarioTFS261852(SalesHeader, InvoiceNo, 18, 100, 1000, 800, 591);

        // [WHEN] Post the Credit Memo
        CrMemoNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The Credit Memo has been posted. Invoice VAT has been fully realized. Credit Memo VAT has been realized by 4.99\0.9
        VerifyInvAndCrMemoVATEntries(InvoiceNo, CrMemoNo, 8, 1.44, 4.99, 0.9);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FCYInvoiceAppliedWithSameExchRateAfterAdjustment()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VATEntry: Record "VAT Entry";
        CustomerNo: Code[20];
        CurrencyCode: Code[10];
        InvoiceNo: Code[20];
        PaymentNo: Code[20];
        ExchangeRate: Decimal;
        Amount: Decimal;
        AmountInclVAT: Decimal;
        AdjustedAmtInclVAT: Decimal;
    begin
        // [SCENARIO 293111] Unrealized VAT when payment applied with exch. rate of the sales invoice after exchange rate adjustment

        // [GIVEN] VAT Posting Setup with "Unrealized VAT Type" = Percentage and VAT% = 10
        EnableUnrealizedSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::Percentage, false, false);

        // [GIVEN] Currency with exch. rate 100/60 and adjustment exch. rate 100/65
        ExchangeRate := LibraryRandom.RandIntInRange(2, 5);
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), ExchangeRate + 1, ExchangeRate);

        // [GIVEN] Posted Sales Invoice with Amount = 600, VAT Amount = 60 in LCY, 1000 and 100 in FCY respectively
        CustomerNo := CreateCustomerWithCurrency(VATPostingSetup."VAT Bus. Posting Group", CurrencyCode);
        InvoiceNo :=
          CreatePostSalesInvoiceForGivenCustomer(
            CustomerNo, LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, "General Posting Type"::" "),
            CurrencyCode, LibraryRandom.RandDecInRange(100, 200, 2));

        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, InvoiceNo);
        CustLedgerEntry.CalcFields(Amount, "Amount (LCY)");
        AmountInclVAT := -CustLedgerEntry."Amount (LCY)";
        Amount := Round(AmountInclVAT / (1 + VATPostingSetup."VAT %" / 100));

        // [GIVEN] Adjusted exchange rate changed total invoice amount = 715 (1100 * 65 / 100), adjustment amount = 55 (715 - 660)
        LibraryERM.RunExchRateAdjustmentSimple(CurrencyCode, WorkDate(), WorkDate());
        CustLedgerEntry.CalcFields(Amount, "Amount (LCY)");
        AdjustedAmtInclVAT := -CustLedgerEntry."Amount (LCY)";

        // [WHEN] Payment is applied with same exch. rate 100/65
        PaymentNo := CreateApplyAndPostPayment(CustomerNo, InvoiceNo, -CustLedgerEntry.Amount);

        // [THEN] Invoice VAT Entry has Base = 0, Amount = 0
        // [THEN] Unrealized Base = 600, Unrealized Amount = 60
        // [THEN] Remaining Unrealized Base and Remaining Unrealized Amount = 0
        VATEntry.SetRange("Bill-to/Pay-to No.", CustomerNo);
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Invoice);
        VATEntry.FindFirst();
        VerifyRealizedVATEntryAmounts(VATEntry, 0, 0);
        VerifyUnrealizedVATEntryAmounts(VATEntry, Amount, AmountInclVAT - Amount, 0, 0);

        // [THEN] Payment VAT Entry has Base = 600, Amount = 60
        // [THEN] Unrealized Base = 0, Unrealized Amount = 0
        // [THEN] Remaining Unrealized Base and Remaining Unrealized Amount = 0
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Payment);
        VATEntry.FindFirst();
        VerifyRealizedVATEntryAmounts(VATEntry, Amount, AmountInclVAT - Amount);
        VerifyUnrealizedVATEntryAmounts(VATEntry, 0, 0, 0, 0);

        // [THEN] Unrealized Gains posted with amount 55 for adjustment and amount = -55 after payment is applied
        VerifyUnrealizedGainLossesGLEntries(CurrencyCode, PaymentNo, AdjustedAmtInclVAT - AmountInclVAT);
    end;

    [Test]
    procedure ExpectedGLEntriesWhenPostingUnrealizedVATDeferralHeaderDiscountInvoice()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        DeferralTemplate: Record "Deferral Template";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        GLRegister: Record "G/L Register";
        GLEntry: Record "G/L Entry";
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
        CustomerNo: Code[20];
        PostingDate: Date;
        PriceBeforeTax, Discount, Tax : Decimal;
    begin
        // [SCENARIO 548280] An invoice with header level discount and deferred revenue is posted in an unrealized VAT setup

        // [GIVEN] GL Setup using unrealized VAT
        EnableUnrealizedSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::"Last (Fully Paid)", false, false);
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.SetDiscountPostingInSalesReceivablesSetup();
        // [GIVEN] A deferral over 2 periods DEF1
        LibraryERM.CreateDeferralTemplate(DeferralTemplate, DeferralTemplate."Calc. Method"::"Equal per Period", DeferralTemplate."Start Date"::"Beginning of Next Period", 2);
        // [GIVEN] A sales invoice with header level discount
        CustomerNo := CreateCustomer(VATPostingSetup."VAT Bus. Posting Group");
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        Item.Get(CreateItem(VATPostingSetup."VAT Prod. Posting Group"));
        Item."Default Deferral Template Code" := DeferralTemplate."Deferral Code";
        Item.Modify(true);
        // [GIVEN] A sales invoice line with deferral code DEF1
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.");
        PriceBeforeTax := Round(SalesLine."Unit Price" * SalesLine.Quantity);
        // [GIVEN] A header level discount
        Discount := Round(0.1 * PriceBeforeTax);
        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(Discount, SalesHeader);
        // [WHEN] Posting the sales invoice
        PostingDate := SalesHeader."Posting Date";
        GLRegisterOfPostedDocument(LibrarySales.PostSalesDocument(SalesHeader, false, false), PostingDate, GLRegister);
        // [THEN] The G/L Accounts affected by the posting with the date of the invoice (not deferred) are affected as expected.
        Tax := Round((PriceBeforeTax - Discount) * VATPostingSetup."VAT %" / 100);
        GLEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        GLEntry.SetRange("Posting Date", PostingDate);
        AssertBalanceInAccountOfFilteredGLEntries(PriceBeforeTax + Tax - Discount, GetAccountReceivablesGLAccount(CustomerNo), GLEntry, 'The account receivable GL Account should have the total + tax - discount at the posting date');
        AssertBalanceInAccountOfFilteredGLEntries(Discount, GetHeaderDiscountGLAccount(CustomerNo, Item), GLEntry, 'The discount granted GL account should have the discount at posting date');
        AssertBalanceInAccountOfFilteredGLEntries(-Discount, GetRevenueGLAccount(CustomerNo, Item), GLEntry, 'The revenue GL account should only have the discount at posting date');
        AssertBalanceInAccountOfFilteredGLEntries(-(PriceBeforeTax - Discount), GetDeferralGLAccount(DeferralTemplate), GLEntry, 'The deferred revenue GL Account should have the total - discount (no tax) at the posting date');
        AssertBalanceInAccountOfFilteredGLEntries(-Tax, GetUnrealizedVATGLAccount(VATPostingSetup), GLEntry, 'The unrealized VAT should have the VAT at the posting date (considering discount)');
        // [THEN] The G/L Accounts affected by the posting including deferrals are affected as expected.
        GLEntry.SetRange("Posting Date");
        AssertBalanceInAccountOfFilteredGLEntries(-PriceBeforeTax, GetRevenueGLAccount(CustomerNo, Item), GLEntry, 'Over all time, the revenue GL account should have the total (no tax or discount)');
        AssertBalanceInAccountOfFilteredGLEntries(0, GetDeferralGLAccount(DeferralTemplate), GLEntry, 'Over all time, the deferral GL Account should be zero', true);
    end;

    [Test]
    procedure ExpectedGLEntriesWhenPostingUnrealizedVATDeferralLineDiscountInvoice()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        DeferralTemplate: Record "Deferral Template";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        GLRegister: Record "G/L Register";
        GLEntry: Record "G/L Entry";
        CustomerNo: Code[20];
        PostingDate: Date;
        PriceBeforeTax, Discount, Tax : Decimal;
    begin
        // [SCENARIO 548280] An invoice with line level discount and deferred revenue is posted in an unrealized VAT setup

        // [GIVEN] GL Setup using unrealized VAT
        EnableUnrealizedSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::"Last (Fully Paid)", false, false);
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.SetDiscountPostingInSalesReceivablesSetup();
        // [GIVEN] A deferral over 2 periods DEF1
        LibraryERM.CreateDeferralTemplate(DeferralTemplate, DeferralTemplate."Calc. Method"::"Equal per Period", DeferralTemplate."Start Date"::"Beginning of Next Period", 2);
        // [GIVEN] A sales invoice with header level discount
        CustomerNo := CreateCustomer(VATPostingSetup."VAT Bus. Posting Group");
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        Item.Get(CreateItem(VATPostingSetup."VAT Prod. Posting Group"));
        Item."Default Deferral Template Code" := DeferralTemplate."Deferral Code";
        Item.Modify(true);
        // [GIVEN] A sales invoice line with deferral code DEF1
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.");
        PriceBeforeTax := Round(SalesLine."Unit Price" * SalesLine.Quantity);
        // [GIVEN] A line level discount
        Discount := Round(0.1 * PriceBeforeTax);
        SalesLine.Validate("Line Discount Amount", Discount);
        SalesLine.Modify();
        // [WHEN] Posting the sales invoice
        PostingDate := SalesHeader."Posting Date";
        GLRegisterOfPostedDocument(LibrarySales.PostSalesDocument(SalesHeader, false, false), PostingDate, GLRegister);
        // [THEN] The G/L Accounts affected by the posting with the date of the invoice (not deferred) are affected as expected.
        Tax := Round((PriceBeforeTax - Discount) * VATPostingSetup."VAT %" / 100);
        GLEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        GLEntry.SetRange("Posting Date", PostingDate);
        AssertBalanceInAccountOfFilteredGLEntries(PriceBeforeTax + Tax - Discount, GetAccountReceivablesGLAccount(CustomerNo), GLEntry, 'The account receivable GL Account should have the total + tax - discount at the posting date');
        AssertBalanceInAccountOfFilteredGLEntries(Discount, GetLineDiscountGLAccount(CustomerNo, Item), GLEntry, 'The discount granted GL account should have the discount at posting date');
        AssertBalanceInAccountOfFilteredGLEntries(-Discount, GetRevenueGLAccount(CustomerNo, Item), GLEntry, 'The revenue GL account should only have the discount at posting date');
        AssertBalanceInAccountOfFilteredGLEntries(-(PriceBeforeTax - Discount), GetDeferralGLAccount(DeferralTemplate), GLEntry, 'The deferred revenue GL Account should have the total - discount (no tax) at the posting date');
        AssertBalanceInAccountOfFilteredGLEntries(-Tax, GetUnrealizedVATGLAccount(VATPostingSetup), GLEntry, 'The unrealized VAT should have the VAT at the posting date (considering discount)');
        // [THEN] The G/L Accounts affected by the posting including deferrals are affected as expected.
        GLEntry.SetRange("Posting Date");
        AssertBalanceInAccountOfFilteredGLEntries(-PriceBeforeTax, GetRevenueGLAccount(CustomerNo, Item), GLEntry, 'Over all time, the revenue GL account should have the total (no tax or discount)');
        AssertBalanceInAccountOfFilteredGLEntries(0, GetDeferralGLAccount(DeferralTemplate), GLEntry, 'Over all time, the deferral GL Account should be zero', true);
    end;

    [Test]
    procedure GLEntriesRevertWithCreditMemoWhenPostingUnrealizedVATDeferralDiscountInvoice()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        DeferralTemplate: Record "Deferral Template";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader, CreditMemoSalesHeader : Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        InvoiceGLRegister, CreditMemoGLRegister : Record "G/L Register";
        GLEntry: Record "G/L Entry";
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        CustomerNo, GLAccountNo : Code[20];
        PostingDate: Date;
        Discount: Decimal;
        GLAccountNos: List of [Code[20]];
        GLEntriesFilter: Text;
        BalanceErr: Label 'The balance of %1 account from the past two postings should be zero', Locked = true;
    begin
        // [SCENARIO 548280] An invoice with header and line level discount and deferred revenue is posted in an unrealized VAT setup.
        // A corrective credit memo is then created and posted.

        // [GIVEN] GL Setup using unrealized VAT
        EnableUnrealizedSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::"Last (Fully Paid)", false, false);
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.SetDiscountPostingInSalesReceivablesSetup();
        // [GIVEN] A deferral over 2 periods DEF1
        LibraryERM.CreateDeferralTemplate(DeferralTemplate, DeferralTemplate."Calc. Method"::"Equal per Period", DeferralTemplate."Start Date"::"Beginning of Next Period", 2);
        // [GIVEN] A sales invoice with header level discount
        CustomerNo := CreateCustomer(VATPostingSetup."VAT Bus. Posting Group");
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        Item.Get(CreateItem(VATPostingSetup."VAT Prod. Posting Group"));
        Item."Default Deferral Template Code" := DeferralTemplate."Deferral Code";
        Item.Modify(true);
        // [GIVEN] A sales invoice line with deferral code DEF1
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.");
        // [GIVEN] A line level discount
        Discount := Round(0.1 * SalesLine."Unit Price" * SalesLine.Quantity);
        SalesLine.Validate("Line Discount Amount", Discount);
        // [GIVEN] A header level discount
        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(Discount, SalesHeader);
        // [GIVEN] The sales invoice is posted
        PostingDate := SalesHeader."Posting Date";
        GLRegisterOfPostedDocument(LibrarySales.PostSalesDocument(SalesHeader, false, false), PostingDate, InvoiceGLRegister);
        // [GIVEN] A credit memo is created from the posted sales invoice
        SalesInvoiceHeader.SetRange("Bill-to Customer No.", CustomerNo);
        SalesInvoiceHeader.FindLast();
        CorrectPostedSalesInvoice.CreateCreditMemoCopyDocument(SalesInvoiceHeader, CreditMemoSalesHeader);
        // [WHEN] Posting the credit memo
        GLRegisterOfPostedDocument(LibrarySales.PostSalesDocument(CreditMemoSalesHeader, false, false), PostingDate, CreditMemoGLRegister);
        // [THEN] All the balances of every account from the past two postings should be zero
        GLEntriesFilter := StrSubstNo('%1..%2|%3..%4', InvoiceGLRegister."From Entry No.", InvoiceGLRegister."To Entry No.", CreditMemoGLRegister."From Entry No.", CreditMemoGLRegister."To Entry No.");

        GLEntry.SetFilter("Entry No.", GLEntriesFilter);
        // [THEN] Balance of purchases accounts should be zero
        GetGeneralPostingSetup(CustomerNo, Item, GeneralPostingSetup);
        GLEntry.SetFilter("G/L Account No.", '%1|%2', GeneralPostingSetup."Sales Account", GeneralPostingSetup."Sales Credit Memo Account");
        GLEntry.CalcSums(Amount);
        Assert.AreEqual(0, GLEntry.Amount, 'Balances in the sales accounts should be zero.');
        // [THEN] All the balances of the rest of the accounts from the past two postings should be zero
        CollectGLAccountNosInGLEntries(GLEntriesFilter, GLAccountNos);
        foreach GLAccountNo in GLAccountNos do
            if (GLAccountNo <> GeneralPostingSetup."Sales Account") and (GLAccountNo <> GeneralPostingSetup."Sales Credit Memo Account") then begin
                GLEntry.SetRange("G/L Account No.", GLAccountNo);
                GLEntry.CalcSums(Amount);
                Assert.AreEqual(0, GLEntry.Amount, StrSubstNo(BalanceErr, GLAccountNo));
            end;
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Unrealized VAT Customer");
        LibrarySetupStorage.Restore();
        // Lazy Setup.
        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Unrealized VAT Customer");
        LibrarySales.SetInvoiceRounding(false);
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateAccountInCustomerPostingGroup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        isInitialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Unrealized VAT Customer");
    end;

    local procedure GLRegisterOfPostedDocument(DocumentNo: Code[20]; PostingDate: Date; var GLRegister: Record "G/L Register")
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Posting Date", PostingDate);
        GLEntry.FindLast();
        GLRegister.SetCurrentKey("To Entry No.");
        GLRegister.SetAscending("To Entry No.", true);
        GLRegister.SetFilter("To Entry No.", '>=%1', GLEntry."Entry No.");
        GLRegister.FindFirst();
    end;

    local procedure AssertBalanceInAccountOfFilteredGLEntries(Expected: Decimal; GLAccountNo: Code[20]; var GLEntry: Record "G/L Entry"; ReasonMsg: Text)
    begin
        AssertBalanceInAccountOfFilteredGLEntries(Expected, GLAccountNo, GLEntry, ReasonMsg, false);
    end;

    local procedure AssertBalanceInAccountOfFilteredGLEntries(Expected: Decimal; GLAccountNo: Code[20]; var GLEntry: Record "G/L Entry"; ReasonMsg: Text; UseAreEqual: Boolean)
    var
        AutoFormat: Codeunit "Auto Format";
    begin
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.CalcSums(Amount);
        if UseAreEqual then
            Assert.AreEqual(Expected, GLEntry.Amount, ReasonMsg)
        else
            Assert.AreNearlyEqual(Expected, GLEntry.Amount, AutoFormat.ReadRounding(), ReasonMsg);
    end;

    local procedure EnableUnrealizedSetup(var VATPostingSetup: Record "VAT Posting Setup"; UnrealizedVATType: Option; GLSetupAdjustforPaymentDisc: Boolean; VATSetupAdjustforPaymentDisc: Boolean)
    begin
        EnableUnrealVATSetupWithGivenPct(
          VATPostingSetup, UnrealizedVATType, GLSetupAdjustforPaymentDisc,
          VATSetupAdjustforPaymentDisc, LibraryRandom.RandIntInRange(10, 30));
    end;

    local procedure EnableUnrealVATSetupWithGivenPct(var VATPostingSetup: Record "VAT Posting Setup"; UnrealizedVATType: Option; GLSetupAdjustforPaymentDisc: Boolean; VATSetupAdjustforPaymentDisc: Boolean; VATRate: Decimal)
    var
        VATPostingSetup2: Record "VAT Posting Setup";
    begin
        Initialize();
        LibraryERM.SetUnrealizedVAT(true);
        if not GLSetupAdjustforPaymentDisc then begin
            VATPostingSetup2.SetRange("Adjust for Payment Discount", true);
            VATPostingSetup2.DeleteAll();
        end;
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(GLSetupAdjustforPaymentDisc);
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATRate);
        UpdateVATPostingSetup(VATPostingSetup, UnrealizedVATType, VATSetupAdjustforPaymentDisc);
    end;

    local procedure GetAccountReceivablesGLAccount(CustomerNo: Code[20]): Code[20]
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        Customer.Get(CustomerNo);
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        exit(CustomerPostingGroup."Receivables Account");
    end;

    local procedure GetHeaderDiscountGLAccount(CustomerNo: Code[20]; Item: Record Item): Code[20]
    var
        Customer: Record Customer;
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        Customer.Get(CustomerNo);
        GeneralPostingSetup.Get(Customer."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group");
        exit(GeneralPostingSetup."Sales Inv. Disc. Account");
    end;

    local procedure GetLineDiscountGLAccount(CustomerNo: Code[20]; Item: Record Item): Code[20]
    var
        Customer: Record Customer;
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        Customer.Get(CustomerNo);
        GeneralPostingSetup.Get(Customer."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group");
        exit(GeneralPostingSetup."Sales Line Disc. Account");
    end;

    local procedure GetRevenueGLAccount(CustomerNo: Code[20]; Item: Record Item): Code[20]
    var
        Customer: Record Customer;
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        Customer.Get(CustomerNo);
        GeneralPostingSetup.Get(Customer."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group");
        exit(GeneralPostingSetup."Sales Account");
    end;

    local procedure GetDeferralGLAccount(DeferralTemplate: Record "Deferral Template"): Code[20]
    begin
        exit(DeferralTemplate."Deferral Account");
    end;

    local procedure GetGeneralPostingSetup(CustomerNo: Code[20]; Item: Record Item; var GeneralPostingSetup: Record "General Posting Setup")
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        GeneralPostingSetup.Get(Customer."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group");
    end;

    local procedure GetUnrealizedVATGLAccount(VATPostingSetup: Record "VAT Posting Setup"): Code[20]
    begin
        exit(VATPostingSetup."Sales VAT Unreal. Account");
    end;

    local procedure CollectGLAccountNosInGLEntries(GLEntryFilter: Text; var GLAccountNos: List of [Code[20]])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetFilter("Entry No.", GLEntryFilter);
        repeat
            if not GLAccountNos.Contains(GLEntry."G/L Account No.") then
                GLAccountNos.Add(GLEntry."G/L Account No.");
        until GLEntry.Next() = 0;
    end;

    local procedure PerformScenarioTFS261852(var SalesHeader: Record "Sales Header"; var InvoiceNo: Code[20]; VATPct: Decimal; ExchangeRate: Decimal; InvoiceAmount: Decimal; CrMemoAmount: Decimal; PaymentAmount: Decimal)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        CustomerNo: Code[20];
        GLAccountNo: Code[20];
        CurrencyCode: Code[10];
        PaymentNo: Code[20];
    begin
        EnableUnrealVATSetupWithGivenPct(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::Percentage, false, false, VATPct);
        CustomerNo := LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group");
        GLAccountNo := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, "General Posting Type"::" ");
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), ExchangeRate, 1);

        InvoiceNo := CreatePostSalesInvoiceForGivenCustomer(CustomerNo, GLAccountNo, CurrencyCode, InvoiceAmount);
        PaymentNo := CreateAndPostPaymentJnlLine(CustomerNo, CurrencyCode, -PaymentAmount);
        ApplyCustomerPaymentToInvoice(InvoiceNo, PaymentNo);

        CreateSalesCreditMemoForGivenCustomer(SalesHeader, CustomerNo, GLAccountNo, CurrencyCode, CrMemoAmount);
        SetAppliesToIDSalesDocumentToPostedInvoice(SalesHeader, InvoiceNo);
    end;

    local procedure ApplyAndPostCustomerEntry(DocumentNo: Code[20]; ApplyingDocumentNo: Code[20]; ApplyingDocumentType: Enum "Gen. Journal Document Type"; DocumentType: Enum "Gen. Journal Document Type")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ApplyingCustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // Apply Payment Entry on Posted Invoice.
        LibraryERM.FindCustomerLedgerEntry(ApplyingCustLedgerEntry, ApplyingDocumentType, ApplyingDocumentNo);
        ApplyingCustLedgerEntry.CalcFields("Remaining Amount");
        LibraryERM.SetApplyCustomerEntry(ApplyingCustLedgerEntry, ApplyingCustLedgerEntry."Remaining Amount");

        // Set Applies-to ID.
        CustLedgerEntry.SetRange("Document Type", DocumentType);
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.SetRange(Open, true);
        CustLedgerEntry.FindFirst();
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry);

        // Post Application Entries.
        LibraryERM.PostCustLedgerApplication(ApplyingCustLedgerEntry);
    end;

    local procedure ApplyCustomerLedgerEntries(CustomerNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    var
        CustomerLedgerEntries: TestPage "Customer Ledger Entries";
    begin
        CustomerLedgerEntries.OpenView();
        CustomerLedgerEntries.FILTER.SetFilter("Customer No.", CustomerNo);
        CustomerLedgerEntries.FILTER.SetFilter("Document Type", Format(DocumentType));
        CustomerLedgerEntries."Apply Entries".Invoke(); // Apply Entries.
    end;

    local procedure ApplyCustomerPaymentToInvoice(InvoiceDocNo: Code[20]; PaymentDocNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.ApplyCustomerLedgerEntries(
          CustLedgerEntry."Document Type"::Invoice, CustLedgerEntry."Document Type"::Payment, InvoiceDocNo, PaymentDocNo);
    end;

    local procedure CalculateCreditMemoAmount(DocumentNo: Code[20]; Type: Enum "Sales Line Type"): Decimal
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        SalesCrMemoLine.SetRange("Document No.", DocumentNo);
        SalesCrMemoLine.SetRange(Type, Type);
        if SalesCrMemoLine.FindFirst() then
            exit(SalesCrMemoLine.Amount);
    end;

    local procedure CalculateGLAmount(CurrencyExchangeRate: Record "Currency Exchange Rate"; GenJournalLine: Record "Gen. Journal Line"; SalesLine: Record "Sales Line"; DocumentNo: Code[20]): Decimal
    var
        Currency: Record Currency;
        RefundAmountLCY: Decimal;
    begin
        Currency.Get(CurrencyExchangeRate."Currency Code");
        RefundAmountLCY :=
          CalculateRefundAmount(CurrencyExchangeRate, GenJournalLine) *
          CurrencyExchangeRate."Relational Exch. Rate Amount" / CurrencyExchangeRate."Exchange Rate Amount";
        exit(
          Round((
                 CalculateCreditMemoAmount(DocumentNo, SalesLine.Type::Item) *
                 (CurrencyExchangeRate."Relational Exch. Rate Amount" / CurrencyExchangeRate."Exchange Rate Amount") *
                 Abs(RefundAmountLCY) /
                 (Abs(Round(SalesLine.Quantity * SalesLine."Unit Price" * (1 + SalesLine."VAT %" / 100),
                      Currency."Amount Rounding Precision", Currency.InvoiceRoundingDirection()) *
                    CurrencyExchangeRate."Relational Exch. Rate Amount" / CurrencyExchangeRate."Exchange Rate Amount") -
                  (Abs(GenJournalLine."Amount (LCY)") - Abs(RefundAmountLCY))) *
                 SalesLine."VAT %" / 100)
            ));
    end;

    local procedure CalculateGLAmountPayment(CurrencyExchangeRate: Record "Currency Exchange Rate"; GenJournalLine: Record "Gen. Journal Line"; SalesLine: Record "Sales Line"): Decimal
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        FindSalesInvoiceLine(SalesInvoiceLine, FindPostedSalesInvoice(SalesLine."Document No."));
        exit(
          CalculateUnrealizedVAT(
            CurrencyExchangeRate, GenJournalLine, SalesInvoiceLine.Amount,
            SalesInvoiceLine."Amount Including VAT", SalesInvoiceLine."VAT %"));
    end;

    local procedure CalculateUnrealizedVAT(CurrencyExchangeRate: Record "Currency Exchange Rate"; GenJournalLine: Record "Gen. Journal Line"; Amount: Decimal; AmountInclVAT: Decimal; VATPct: Decimal): Decimal
    var
        Currency: Record Currency;
        PaymentAmountLCY: Decimal;
        PaymentAmountLCYExclVAT: Decimal;
        LineAmountLCY: Decimal;
        LineAmountInclVATLCY: Decimal;
        LineVATAmountLCY: Decimal;
        NotPaidAmountExclVAT: Decimal;
        VATAmountNotPaid: Decimal;
        UnrealizedVATAmountLCY: Decimal;
    begin
        Currency.Get(CurrencyExchangeRate."Currency Code");

        PaymentAmountLCY :=
          CalculateRefundAmount(CurrencyExchangeRate, GenJournalLine) *
          CurrencyExchangeRate."Relational Exch. Rate Amount" / CurrencyExchangeRate."Exchange Rate Amount";

        PaymentAmountLCYExclVAT := Round(PaymentAmountLCY) / (1 + VATPct / 100);

        LineAmountLCY :=
          Round(Amount *
            (CurrencyExchangeRate."Relational Exch. Rate Amount" / CurrencyExchangeRate."Exchange Rate Amount"));
        LineAmountInclVATLCY :=
          Round(AmountInclVAT *
            (CurrencyExchangeRate."Relational Exch. Rate Amount" / CurrencyExchangeRate."Exchange Rate Amount"));

        LineVATAmountLCY := LineAmountInclVATLCY - LineAmountLCY;

        NotPaidAmountExclVAT := LineAmountLCY - Abs(PaymentAmountLCYExclVAT);
        VATAmountNotPaid := NotPaidAmountExclVAT * (VATPct / 100);
        UnrealizedVATAmountLCY := LineVATAmountLCY - VATAmountNotPaid;

        exit(Round(UnrealizedVATAmountLCY, Currency."Invoice Rounding Precision"));
    end;

    local procedure CalculateRefundAmount(CurrencyExchangeRate: Record "Currency Exchange Rate"; GenJournalLine: Record "Gen. Journal Line"): Decimal
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        exit(
          Round(
            LibraryERM.ConvertCurrency(
              GenJournalLine.Amount, GenJournalLine."Currency Code", CurrencyExchangeRate."Currency Code",
              CurrencyExchangeRate."Starting Date"),
            GeneralLedgerSetup."Inv. Rounding Precision (LCY)"));
    end;

    local procedure CreatePostSalesInvoiceWithNegativeLine(var SalesHeader: Record "Sales Header"; VATPostingSetup: Record "VAT Posting Setup"; var VATBaseAmount: array[2] of Decimal; var VATAmount: array[2] of Decimal; AmountRoundingPrecision: Decimal): Code[20]
    var
        SalesLine: Record "Sales Line";
    begin
        VATBaseAmount[1] := LibraryRandom.RandDecInRange(3000, 4000, 2);
        VATBaseAmount[2] := LibraryRandom.RandDecInRange(1000, 2000, 2);
        VATAmount[1] := Round(VATBaseAmount[1] * VATPostingSetup."VAT %" / 100, AmountRoundingPrecision);
        VATAmount[2] := Round(VATBaseAmount[2] * VATPostingSetup."VAT %" / 100, AmountRoundingPrecision);

        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer(VATPostingSetup."VAT Bus. Posting Group"));
        CreateSalesLineWithGLAccount(SalesLine, SalesHeader, VATPostingSetup, 1, VATBaseAmount[1]);
        CreateSalesLineWithGLAccount(SalesLine, SalesHeader, VATPostingSetup, -1, VATBaseAmount[2]);

        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAdditionalCurrencySetup(var CurrencyExchangeRate: Record "Currency Exchange Rate")
    begin
        CreateCurrencyWithExchangeRate(CurrencyExchangeRate);
        LibraryERM.CreateRandomExchangeRate(CurrencyExchangeRate."Currency Code");
        UpdateResidualAccountCurrency(CurrencyExchangeRate."Currency Code");
        LibraryERM.SetAddReportingCurrency(CurrencyExchangeRate."Currency Code");
        LibraryERM.RunAddnlReportingCurrency(
          CurrencyExchangeRate."Currency Code", CurrencyExchangeRate."Currency Code",
          LibraryERM.CreateGLAccountWithSalesSetup());
    end;

    local procedure CreateCustomerWithPaymentTerms(VATBusPostingGroup: Code[20]): Code[20]
    var
        Customer: Record Customer;
        PaymentMethod: Record "Payment Method";
    begin
        LibraryERM.FindPaymentMethod(PaymentMethod);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Method Code", PaymentMethod.Code);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Customer.Validate("Payment Terms Code", CreatePaymentTermsWithDiscount());
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateItem(VATProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        // Create a new Item and Update VAT Prod. Posting Group.
        ModifyItemNoSeries();
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateCurrencyWithExchangeRate(var CurrencyExchangeRate: Record "Currency Exchange Rate")
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
        CreateExchangeRate(CurrencyExchangeRate, Currency.Code, WorkDate());
    end;

    local procedure CreateAndPostSalesInvoice(var SalesLine: Record "Sales Line"; VATPostingSetup: Record "VAT Posting Setup"; CurrencyCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesInvoiceWithCurrency(SalesHeader, VATPostingSetup."VAT Bus. Posting Group", CurrencyCode);
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"));
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateAndPostSalesInvoiceAndCreditMemo(var SalesHeader: Record "Sales Header"; var VATPostingSetup: Record "VAT Posting Setup"; var SalesInvoiceLine: Record "Sales Invoice Line")
    var
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        DocumentNo := CreateSalesInvoice(SalesHeader, VATPostingSetup);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        FindSalesInvoiceLine(SalesInvoiceLine, DocumentNo);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", SalesHeader."Sell-to Customer No.");
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"));

        // Credit Memo Amount must be half the amount of Invoice.
        ModifyAmountInSalesLine(SalesLine, SalesInvoiceLine."Line Amount" / 2);
        LibrarySales.PostSalesDocument(SalesHeader, false, false);
    end;

    local procedure CreateCustomer(VATBusPostingGroup: Code[20]): Code[20]
    var
        Customer: Record Customer;
        PaymentMethod: Record "Payment Method";
    begin
        // Create a new Customer and Update VAT Bus. Posting Group.
        LibraryERM.FindPaymentMethod(PaymentMethod);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Method Code", PaymentMethod.Code);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerWithCurrency(VATBusPostingGroup: Code[20]; CurrencyCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer.Get(LibrarySales.CreateCustomerWithVATBusPostingGroup(VATBusPostingGroup));
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateExchangeRate(var CurrencyExchangeRate: Record "Currency Exchange Rate"; CurrencyCode: Code[10]; StartingDate: Date)
    begin
        LibraryERM.CreateExchRate(CurrencyExchangeRate, CurrencyCode, StartingDate);

        // Using Random Exchange Rate Amount and Adjustment Exchange Rate.
        CurrencyExchangeRate.Validate("Exchange Rate Amount", LibraryRandom.RandDec(100, 2));
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", CurrencyExchangeRate."Exchange Rate Amount");

        // Relational Exchange Rate Amount and Relational Adjmt Exchange Rate Amount always greater than Exchange Rate Amount.
        CurrencyExchangeRate.Validate(
          "Relational Exch. Rate Amount", LibraryRandom.RandDec(100, 2) + CurrencyExchangeRate."Exchange Rate Amount");

        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", CurrencyExchangeRate."Relational Exch. Rate Amount");
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure CreatePaymentTermsWithDiscount(): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, true);
        exit(PaymentTerms.Code);
    end;

    local procedure CreateSalesHeaderWithCurrency(var SalesHeader: Record "Sales Header"; VATBusPostingGroup: Code[20]; CurrencyCode: Code[10])
    begin
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::"Credit Memo", CreateCustomerWithPaymentTerms(VATBusPostingGroup));
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesInvoiceWithGL(var SalesHeader: Record "Sales Header"; VATPostingSetup: Record "VAT Posting Setup") DocumentNo: Code[20]
    var
        GLAccount: Record "G/L Account";
        SalesLine: Record "Sales Line";
        GLAccountNo: Code[20];
    begin
        DocumentNo := CreateSalesInvoice(SalesHeader, VATPostingSetup);
        GLAccountNo := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale);
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccountNo);
    end;

    local procedure CreateSalesInvoice(var SalesHeader: Record "Sales Header"; VATPostingSetup: Record "VAT Posting Setup") DocumentNo: Code[20]
    var
        SalesLine: Record "Sales Line";
        NoSeries: Codeunit "No. Series";
    begin
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer(VATPostingSetup."VAT Bus. Posting Group"));
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"));
        DocumentNo := NoSeries.PeekNextNo(SalesHeader."Posting No. Series");
    end;

    local procedure CreateSalesInvoiceWithCurrency(var SalesHeader: Record "Sales Header"; VATBusPostingGroup: Code[20]; CurrencyCode: Code[10])
    begin
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomerWithPaymentTerms(VATBusPostingGroup));
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; Type: Enum "Sales Line Type"; No: Code[20])
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, No, LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Unit Price", 100 + LibraryRandom.RandDec(100, 2));  // Use Random Unit Price between 100 and 200.
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesLineWithGLAccount(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; VATPostingSetup: Record "VAT Posting Setup"; Quantity: Decimal; UnitPrice: Decimal)
    var
        GLAccount: Record "G/L Account";
    begin
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale), Quantity);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify();
    end;

    local procedure CreateAndPostPaymentJournaLine(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20]; CurrencyCode: Code[10]; LineAmount: Decimal)
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, AccountNo, LineAmount);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostPaymentJnlLine(CustomerNo: Code[20]; CurrencyCode: Code[10]; LineAmount: Decimal): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateAndPostPaymentJournaLine(GenJournalLine, CustomerNo, CurrencyCode, LineAmount);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreateAndPostCreditMemo(PostedInvoiceNo: Code[20]; CustomerNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CustomerNo);
        SalesHeader.Validate("External Document No.", SalesHeader."No.");
        SalesHeader.Modify(true);
        RunCopySalesDocument(SalesHeader, PostedInvoiceNo);
        RemoveAppliestoDocument(SalesHeader."Document Type"::"Credit Memo", SalesHeader."No.");
        exit(LibrarySales.PostSalesDocument(SalesHeader, false, false));
    end;

    local procedure CreateAndPostGeneralJournal(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20]; CurrencyCode: Code[10]; PostingDaysAdded: Integer)
    begin
        // Use Random because value is not important.
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Refund, GenJournalLine."Account Type"::Customer, AccountNo, LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate("Posting Date", CalcDate('<' + Format(PostingDaysAdded) + 'M>', WorkDate()));
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateApplyAndPostPayment(CustomerNo: Code[20]; AppliesToInvoiceNo: Code[20]; PmtAmount: Decimal): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, CustomerNo, PmtAmount);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToInvoiceNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreateAndPostSalesDocument(var SalesLine: Record "Sales Line"; VATPostingSetup: Record "VAT Posting Setup"; CurrencyCode: Code[10]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::"Credit Memo", CreateCustomer(VATPostingSetup."VAT Bus. Posting Group"));
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"));
        exit(LibrarySales.PostSalesDocument(SalesHeader, false, false));
    end;

    local procedure CreatePostSalesInvoiceForGivenCustomer(CustomerNo: Code[20]; GLAccountNo: Code[20]; CurrencyCode: Code[10]; UnitPrice: Decimal): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccountNo, 1);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);

        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateSalesCreditMemoForGivenCustomer(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; GLAccountNo: Code[20]; CurrencyCode: Code[10]; UnitPrice: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CustomerNo);
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccountNo, 1);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

    local procedure SetAppliesToIDSalesDocumentToPostedInvoice(var SalesHeader: Record "Sales Header"; InvoiceNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        SalesHeader.Validate("Applies-to ID", UserId);
        SalesHeader.Modify(true);

        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, InvoiceNo);
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry);
    end;

    local procedure FilterVATEntry(var VATEntry: Record "VAT Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; AmountFilter: Text)
    begin
        VATEntry.SetRange(Type, VATEntry.Type::Sale);
        VATEntry.SetRange("Document Type", DocumentType);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetFilter(Amount, AmountFilter);
    end;

    local procedure FindGLEntry(var GLEntry: Record "G/L Entry"; GLAccountNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    begin
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
    end;

    local procedure FindSalesInvoiceLine(var SalesInvoiceLine: Record "Sales Invoice Line"; DocumentNo: Code[20])
    begin
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.FindFirst();
    end;

    local procedure FindPostedSalesInvoice(PreAssignedNo: Code[20]): Code[20]
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.SetRange("Pre-Assigned No.", PreAssignedNo);
        SalesInvoiceHeader.FindFirst();
        exit(SalesInvoiceHeader."No.");
    end;

    local procedure FindPositiveVATEntry(var VATEntry: Record "VAT Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    begin
        FilterVATEntry(VATEntry, DocumentType, DocumentNo, '>0');
        VATEntry.FindFirst();
    end;

    local procedure FindNegativeVATEntry(var VATEntry: Record "VAT Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    begin
        FilterVATEntry(VATEntry, DocumentType, DocumentNo, '<0');
        VATEntry.FindFirst();
    end;

    local procedure FindUnrealVATEntry(var VATEntry: Record "VAT Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    begin
        FilterVATEntry(VATEntry, DocumentType, DocumentNo, '=0');
        VATEntry.SetRange("Unrealized VAT Entry No.", 0);
        VATEntry.FindFirst();
    end;

    local procedure FindPositiveRealVATEntry(var VATEntry: Record "VAT Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    begin
        FilterVATEntry(VATEntry, DocumentType, DocumentNo, '>0');
        VATEntry.SetFilter("Unrealized VAT Entry No.", '<>%1', 0);
        VATEntry.FindFirst();
    end;

    local procedure FindNegativeRealVATEntry(var VATEntry: Record "VAT Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    begin
        FilterVATEntry(VATEntry, DocumentType, DocumentNo, '<0');
        VATEntry.SetFilter("Unrealized VAT Entry No.", '<>%1', 0);
        VATEntry.FindFirst();
    end;

    local procedure FindLastVATEntry(var VATEntry: Record "VAT Entry"; DocumentNo: Code[20])
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindLast();
    end;

    local procedure ModifyAmountInExchangeRate(CurrencyExchangeRate: Record "Currency Exchange Rate"; ExchRateAmt: Decimal)
    begin
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", CurrencyExchangeRate."Relational Exch. Rate Amount" + ExchRateAmt);
        CurrencyExchangeRate.Validate(
          "Relational Adjmt Exch Rate Amt", CurrencyExchangeRate."Relational Adjmt Exch Rate Amt" + ExchRateAmt);
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure ModifyAmountInSalesLine(var SalesLine: Record "Sales Line"; LineAmount: Decimal)
    begin
        SalesLine.Validate("Line Amount", LineAmount);
        SalesLine.Modify(true);
    end;

    local procedure ModifyItemNoSeries()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.Validate("Item Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        InventorySetup.Modify(true);
    end;

    local procedure RunCopySalesDocument(SalesHeader: Record "Sales Header"; DocumentNo: Code[20])
    var
        CopySalesDocument: Report "Copy Sales Document";
    begin
        Clear(CopySalesDocument);
        CopySalesDocument.SetSalesHeader(SalesHeader);
        CopySalesDocument.SetParameters("Sales Document Type From"::"Posted Invoice", DocumentNo, true, false);
        CopySalesDocument.UseRequestPage(false);
        CopySalesDocument.Run();
    end;

    local procedure RemoveAppliestoDocument(DocumentType: Enum "Sales Document Type"; No: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(DocumentType, No);
        SalesHeader.Validate("Applies-to Doc. Type", SalesHeader."Applies-to Doc. Type"::" ");
        SalesHeader.Validate("Applies-to Doc. No.", '');
        SalesHeader.Modify(true);
    end;

    local procedure UpdateResidualAccountCurrency(CurrencyCode: Code[10])
    var
        Currency: Record Currency;
        GLAccount: Record "G/L Account";
    begin
        Currency.Get(CurrencyCode);
        LibraryERM.CreateGLAccount(GLAccount);
        Currency.Validate("Residual Gains Account", GLAccount."No.");
        Currency.Validate("Residual Losses Account", GLAccount."No.");
        Currency.Modify(true);
    end;

    local procedure UpdateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; UnrealizedVATType: Option; AdjustForPaymentDiscount: Boolean)
    begin
        VATPostingSetup.Validate("Unrealized VAT Type", UnrealizedVATType);
        VATPostingSetup.Validate("Sales VAT Unreal. Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Adjust for Payment Discount", AdjustForPaymentDiscount);
        VATPostingSetup.Modify(true);
    end;

    local procedure VerifyDetailedCustomerEntry(CustLedgerEntryNo: Integer; EntryType: Enum "Detailed CV Ledger Entry Type"; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal; AmountLCY: Decimal)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgerEntryNo);
        DetailedCustLedgEntry.SetRange("Entry Type", EntryType);
        DetailedCustLedgEntry.SetRange("Document Type", DocumentType);
        DetailedCustLedgEntry.FindFirst();
        DetailedCustLedgEntry.TestField(Amount, Amount);
        Assert.AreNearlyEqual(
          AmountLCY, DetailedCustLedgEntry."Amount (LCY)", GeneralLedgerSetup."Inv. Rounding Precision (LCY)",
          DetailedCustLedgEntry.FieldCaption("Amount (LCY)"));
    end;

    local procedure VerifyDetailedEntryCreditMemo(CurrencyExchangeRate: Record "Currency Exchange Rate"; GenJournalLine: Record "Gen. Journal Line"; DocumentNo: Code[20]; Amount: Decimal; CurrencyUpdateFactor: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        RefundAmount: Decimal;
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", DocumentNo);
        RefundAmount := CalculateRefundAmount(CurrencyExchangeRate, GenJournalLine);

        VerifyDetailedCustomerEntry(
          CustLedgerEntry."Entry No.", DetailedCustLedgEntry."Entry Type"::"Initial Entry",
          DetailedCustLedgEntry."Document Type"::"Credit Memo", -Amount,
          -Round(Amount * CurrencyExchangeRate."Relational Exch. Rate Amount" / CurrencyExchangeRate."Exchange Rate Amount"));

        VerifyDetailedCustomerEntry(
          CustLedgerEntry."Entry No.", DetailedCustLedgEntry."Entry Type"::"Unrealized Loss", DetailedCustLedgEntry."Document Type"::" ", 0,
          -Round(Amount * CurrencyUpdateFactor / CurrencyExchangeRate."Exchange Rate Amount"));

        VerifyDetailedCustomerEntry(
          CustLedgerEntry."Entry No.", DetailedCustLedgEntry."Entry Type"::Application, DetailedCustLedgEntry."Document Type"::Refund,
          RefundAmount,
          Round(RefundAmount * CurrencyExchangeRate."Relational Exch. Rate Amount" / CurrencyExchangeRate."Exchange Rate Amount"));

        VerifyDetailedCustomerEntry(
          CustLedgerEntry."Entry No.", DetailedCustLedgEntry."Entry Type"::"Unrealized Loss",
          DetailedCustLedgEntry."Document Type"::Refund,
          0, Round(RefundAmount * CurrencyUpdateFactor / CurrencyExchangeRate."Exchange Rate Amount"));
    end;

    local procedure VerifyDetailedEntryRefund(CurrencyExchangeRate: Record "Currency Exchange Rate"; GenJournalLine: Record "Gen. Journal Line")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        RefundAmountLCY: Decimal;
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Refund, GenJournalLine."Document No.");
        RefundAmountLCY :=
          CalculateRefundAmount(CurrencyExchangeRate, GenJournalLine) *
          CurrencyExchangeRate."Relational Exch. Rate Amount" / CurrencyExchangeRate."Exchange Rate Amount";

        VerifyDetailedCustomerEntry(
          CustLedgerEntry."Entry No.", DetailedCustLedgEntry."Entry Type"::"Initial Entry",
          DetailedCustLedgEntry."Document Type"::Refund, GenJournalLine.Amount, Round(GenJournalLine."Amount (LCY)"));

        VerifyDetailedCustomerEntry(
          CustLedgerEntry."Entry No.", DetailedCustLedgEntry."Entry Type"::Application,
          DetailedCustLedgEntry."Document Type"::Refund, -GenJournalLine.Amount, -Round(RefundAmountLCY));

        VerifyDetailedCustomerEntry(
          CustLedgerEntry."Entry No.", DetailedCustLedgEntry."Entry Type"::"Realized Loss",
          DetailedCustLedgEntry."Document Type"::Refund, 0,
          -Round(GenJournalLine."Amount (LCY)" - RefundAmountLCY));
    end;

    local procedure VerifyUnrealizedVATEntry(DocumentNo: Code[20]; GLAccountNo: Code[20]; UnrealizedVATAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(
          UnrealizedVATAmount, GLEntry.Amount, LibraryERM.GetAmountRoundingPrecision(), GLEntry.FieldCaption(Amount));
    end;

    local procedure VerifyUnrealizedVATEntryIsRealized(PmtDocumentNo: Code[20]; UnrealizedTransactionNo: Integer; RealizedTransactionNo: Integer)
    var
        VATEntry: Record "VAT Entry";
        UnrealVATEntry: Record "VAT Entry";
    begin
        FindLastVATEntry(VATEntry, PmtDocumentNo);
        VATEntry.TestField("Unrealized VAT Entry No.");
        VATEntry.TestField("Transaction No.", RealizedTransactionNo);

        UnrealVATEntry.Get(VATEntry."Unrealized VAT Entry No.");
        UnrealVATEntry.TestField("Transaction No.", UnrealizedTransactionNo);
        VerifyUnrealizedVATEntryAmounts(UnrealVATEntry, VATEntry.Base, VATEntry.Amount, 0, 0);
    end;

    local procedure VerifyGLEntryForFullyPaid(BalAccountNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Bal. Account No.", BalAccountNo);
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, Amount);
    end;

    local procedure VerifyGLEntryForUnrealizedVAT(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; GLAccountNo: Code[20]; CurrencyCode: Code[10]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
        Currency: Record Currency;
    begin
        Currency.Get(CurrencyCode);
        FindGLEntry(GLEntry, GLAccountNo, DocumentType, DocumentNo);
        Assert.AreNearlyEqual(
          -Amount, GLEntry.Amount, 0.05, GLEntry.FieldCaption(Amount));
    end;

    local procedure VerifyCustomerLedgerEntry(CustomerNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.FindSet();
        repeat
            CustLedgerEntry.CalcFields("Remaining Amount");
            CustLedgerEntry.TestField("Remaining Amount", 0);
        until CustLedgerEntry.Next() = 0;
    end;

    local procedure VerifyCustomerLedgerEntryAmounts(CustomerNo: Code[20]; DocumentNo: Code[20]; ExpectedAmount: Decimal; ExpectedRemAmount: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.CalcFields(Amount, "Remaining Amount");
        Assert.AreEqual(ExpectedAmount, CustLedgerEntry.Amount, CustLedgerEntry.FieldCaption(Amount));
        Assert.AreEqual(ExpectedRemAmount, CustLedgerEntry."Remaining Amount", CustLedgerEntry.FieldCaption("Remaining Amount"));
    end;

    local procedure VerifyRemainingAmountOnLedger(CustomerNo: Code[20]; DocumentNo: Code[20]; RemainingAmount: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.CalcFields("Remaining Amount");
        Assert.AreNearlyEqual(
          RemainingAmount, CustLedgerEntry."Remaining Amount", LibraryERM.GetAmountRoundingPrecision(), CustLedgerEntry.FieldCaption("Remaining Amount"));
    end;

    local procedure VerifyValuesOnVATEntry(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; AdditionalCurrencyAmount: Decimal; AdditionalCurrencyBase: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document Type", DocumentType);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindFirst();
        Assert.AreNearlyEqual(
          AdditionalCurrencyAmount, VATEntry."Additional-Currency Amount",
          LibraryERM.GetAmountRoundingPrecision(), VATEntry.FieldCaption("Additional-Currency Amount"));
        Assert.AreNearlyEqual(
          AdditionalCurrencyBase, VATEntry."Additional-Currency Base",
          LibraryERM.GetAmountRoundingPrecision(), VATEntry.FieldCaption("Additional-Currency Base"));
    end;

    local procedure VerifyPositiveVATEntry(DocumentNo: Code[20]; ExpectedVATBaseAmount: Decimal; ExpectedVATAmount: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        FindPositiveVATEntry(VATEntry, VATEntry."Document Type"::Payment, DocumentNo);
        VerifyRealizedVATEntryAmounts(VATEntry, ExpectedVATBaseAmount, ExpectedVATAmount);
    end;

    local procedure VerifyNegativeVATEntry(DocumentNo: Code[20]; ExpectedVATBaseAmount: Decimal; ExpectedVATAmount: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        FindNegativeVATEntry(VATEntry, VATEntry."Document Type"::Payment, DocumentNo);
        VerifyRealizedVATEntryAmounts(VATEntry, ExpectedVATBaseAmount, ExpectedVATAmount);
    end;

    local procedure VerifyUnrealizedVATEntryAmounts(VATEntry: Record "VAT Entry"; ExpectedBase: Decimal; ExpectedAmount: Decimal; ExpectedRemBase: Decimal; ExpectedRemAmount: Decimal)
    var
        AmountRoundingPrecision: Decimal;
    begin
        AmountRoundingPrecision := LibraryERM.GetAmountRoundingPrecision();
        Assert.AreNearlyEqual(
          ExpectedBase, VATEntry."Unrealized Base", AmountRoundingPrecision,
          VATEntry.FieldCaption("Unrealized Base"));
        Assert.AreNearlyEqual(
          ExpectedAmount, VATEntry."Unrealized Amount", AmountRoundingPrecision,
          VATEntry.FieldCaption("Unrealized Amount"));
        Assert.AreNearlyEqual(
          ExpectedRemBase, VATEntry."Remaining Unrealized Base", AmountRoundingPrecision,
          VATEntry.FieldCaption("Remaining Unrealized Base"));
        Assert.AreNearlyEqual(
          ExpectedRemAmount, VATEntry."Remaining Unrealized Amount", AmountRoundingPrecision,
          VATEntry.FieldCaption("Remaining Unrealized Amount"));
    end;

    local procedure VerifyRealizedVATEntryAmounts(VATEntry: Record "VAT Entry"; ExpectedBase: Decimal; ExpectedAmount: Decimal)
    var
        AmountRoundingPrecision: Decimal;
    begin
        AmountRoundingPrecision := LibraryERM.GetAmountRoundingPrecision();
        Assert.AreNearlyEqual(
          ExpectedBase, VATEntry.Base, AmountRoundingPrecision, VATEntry.FieldCaption(Base));
        Assert.AreNearlyEqual(
          ExpectedAmount, VATEntry.Amount, AmountRoundingPrecision, VATEntry.FieldCaption(Amount));
    end;

    local procedure VerifyThreeUnrealizedVATEntry(var VATEntryNo: array[3] of Integer; CVNo: Code[20]; InvoiceNo: Code[20]; SalesLine: array[3] of Record "Sales Line")
    var
        VATEntry: Record "VAT Entry";
        i: Integer;
    begin
        VATEntry.SetRange(Type, VATEntry.Type::Sale);
        VATEntry.SetRange("Bill-to/Pay-to No.", CVNo);
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Invoice);
        VATEntry.SetRange("Document No.", InvoiceNo);
        VATEntry.FindSet();
        for i := ArrayLen(SalesLine) downto 1 do begin
            VerifyUnrealizedVATEntryAmounts(
              VATEntry, -SalesLine[i].Amount, -(SalesLine[i]."Amount Including VAT" - SalesLine[i].Amount), 0, 0);
            VATEntryNo[ArrayLen(SalesLine) - i + 1] := VATEntry."Entry No.";
            VATEntry.Next();
        end;
    end;

    local procedure VerifyThreeRealizedVATEntry(UnrealVATEntryNo: array[3] of Integer; CVNo: Code[20]; PaymentNo: Code[20]; SalesLine: array[3] of Record "Sales Line"; VATPart: Decimal)
    var
        VATEntry: Record "VAT Entry";
        i: Integer;
    begin
        VATEntry.SetRange(Type, VATEntry.Type::Sale);
        VATEntry.SetRange("Bill-to/Pay-to No.", CVNo);
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Payment);
        VATEntry.SetRange("Document No.", PaymentNo);
        VATEntry.FindSet();
        for i := ArrayLen(SalesLine) downto 1 do begin
            Assert.AreEqual(
              UnrealVATEntryNo[ArrayLen(SalesLine) - i + 1],
              VATEntry."Unrealized VAT Entry No.",
              VATEntry.FieldCaption("Unrealized VAT Entry No."));
            VerifyRealizedVATEntryAmounts(
              VATEntry,
              -SalesLine[i].Amount * VATPart,
              -(SalesLine[i]."Amount Including VAT" - SalesLine[i].Amount) * VATPart);
            VATEntry.Next();
        end;
    end;

    local procedure VerifyInvAndCrMemoVATEntries(InvoiceNo: Code[20]; CrMemoNo: Code[20]; UnrealBase: Decimal; UnrealAmount: Decimal; RealBase: Decimal; RealAmount: Decimal)
    var
        InvoiceVATEntry: Record "VAT Entry";
        CrMemoVATEntry: Record "VAT Entry";
    begin
        FindUnrealVATEntry(InvoiceVATEntry, InvoiceVATEntry."Document Type"::Invoice, InvoiceNo);
        InvoiceVATEntry.TestField("Remaining Unrealized Base", 0);
        InvoiceVATEntry.TestField("Remaining Unrealized Amount", 0);

        CrMemoVATEntry.SetRange("Document No.", CrMemoNo);
        Assert.RecordCount(CrMemoVATEntry, 3);

        FindUnrealVATEntry(CrMemoVATEntry, CrMemoVATEntry."Document Type"::"Credit Memo", CrMemoNo);
        CrMemoVATEntry.TestField("Unrealized Base", UnrealBase);
        CrMemoVATEntry.TestField("Unrealized Amount", UnrealAmount);
        CrMemoVATEntry.TestField("Remaining Unrealized Base", UnrealBase - RealBase);
        CrMemoVATEntry.TestField("Remaining Unrealized Amount", UnrealAmount - RealAmount);

        FindPositiveRealVATEntry(CrMemoVATEntry, CrMemoVATEntry."Document Type"::"Credit Memo", CrMemoNo);
        CrMemoVATEntry.TestField(Base, RealBase);
        CrMemoVATEntry.TestField(Amount, RealAmount);

        FindNegativeRealVATEntry(CrMemoVATEntry, CrMemoVATEntry."Document Type"::"Credit Memo", CrMemoNo);
        CrMemoVATEntry.TestField(Base, -RealBase);
        CrMemoVATEntry.TestField(Amount, -RealAmount);
        CrMemoVATEntry.TestField("Unrealized VAT Entry No.", InvoiceVATEntry."Entry No.");
    end;

    local procedure VerifyUnrealizedGainLossesGLEntries(CurrencyCode: Code[10]; PaymentNo: Code[20]; GainLossAmt: Decimal)
    var
        GLEntry: Record "G/L Entry";
        Currency: Record Currency;
    begin
        Currency.Get(CurrencyCode);
        GLEntry.SetRange("G/L Account No.", Currency."Unrealized Gains Acc.");
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, GainLossAmt);
        GLEntry.SetRange("Document No.", PaymentNo);
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, -GainLossAmt);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries."Set Applies-to ID".Invoke();  // Set Applies To ID.
        ApplyCustomerEntries."Post Application".Invoke();  // Post Application.
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
        // Message Handler.
    end;
}

