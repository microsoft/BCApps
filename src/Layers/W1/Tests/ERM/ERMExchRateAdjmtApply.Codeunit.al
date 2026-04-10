codeunit 134885 "ERM Exch. Rate Adjmt. Apply"
{
    Permissions = TableData "Cust. Ledger Entry" = rimd,
                  TableData "Vendor Ledger Entry" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Adjust Exchange Rate]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        AmountErr: Label '%1 must be %2 in \\%3 %4=%5.';

    [Test]
    [Scope('OnPrem')]
    procedure ACYonGLEntryforRealizedLossCust()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        AddCurrencyCode: Code[10];
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [General Ledger] [ACY] [Application] [Sales]
        // [SCENARIO 361412] "Additional-Currency Amount" is calculated in G/L Entries of the sales application transaction that includes Realized Loss.
        Initialize();

        // [GIVEN] Currency "X" is set as Additional Currency in G/L Setup
        AddCurrencyCode := CreateCurrency();
        LibraryERM.SetAddReportingCurrency(AddCurrencyCode);
        // [GIVEN] Posted Sales Invoice in Currency "Y"
        CurrencyCode := CreateCurrency();
        ClearGeneralJournalLine(GenJournalBatch);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer,
          CreateCustomer(), CurrencyCode, LibraryRandom.RandDec(100, 2), WorkDate() - 1);
        // [GIVEN] Posted Payment in Currency "Y" on another date with higher exchange rate
        CreateCurrencyExchRate(CurrencyCode, WorkDate(), 1.1);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer,
          GenJournalLine."Account No.", CurrencyCode, -GenJournalLine.Amount, WorkDate());
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Payment is applied to Invoice
        ApplyAndPostCustomerEntry(
          GenJournalLine."Document No.", GenJournalLine.Amount, GenJournalLine."Document No.",
          CustLedgerEntry."Document Type"::Payment, CustLedgerEntry."Document Type"::Invoice);

        // [THEN] "Additional-Currency Amount" in the G/L Entries of the application transaction is calculated according to exchange rates of Currency "X"
        VerifyACYAmountOnGLEntriesOfLastTransaction(AddCurrencyCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ACYonGLEntryforRealizedGainVend()
    var
        VendLedgerEntry: Record "Vendor Ledger Entry";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        AddCurrencyCode: Code[10];
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [General Ledger] [ACY] [Application] [Purchase]
        // [SCENARIO 361412] "Additional-Currency Amount" is calculated in G/L Entries of the purchase application transaction that includes Realized Gain.
        Initialize();

        // [GIVEN] Currency "X" is set as Additional Currency in G/L Setup
        AddCurrencyCode := CreateCurrency();
        LibraryERM.SetAddReportingCurrency(AddCurrencyCode);
        // [GIVEN] Posted Purchase Invoice in Currency "Y"
        CurrencyCode := CreateCurrency();
        ClearGeneralJournalLine(GenJournalBatch);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor,
          CreateVendor(), CurrencyCode, -LibraryRandom.RandDec(100, 2), WorkDate() - 1);
        // [GIVEN] Posted Payment in Currency "Y" on another date with higher exchange rate
        CreateCurrencyExchRate(CurrencyCode, WorkDate(), 1.1);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor,
          GenJournalLine."Account No.", CurrencyCode, -GenJournalLine.Amount, WorkDate());
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Payment is applied to Invoice
        ApplyAndPostVendorEntry(
          GenJournalLine."Document No.", GenJournalLine.Amount, GenJournalLine."Document No.",
          VendLedgerEntry."Document Type"::Payment, VendLedgerEntry."Document Type"::Invoice);

        // [THEN] "Additional-Currency Amount" in the G/L Entries of the application transaction is calculated according to exchange rates of Currency "X"
        VerifyACYAmountOnGLEntriesOfLastTransaction(AddCurrencyCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyAdjustExchRateHigherCust()
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        // Create Currency, General Journal Line for Invoice and Payment and Post, Modify Exchange Rate and Apply Posted Entry and Check
        // Realized Gain Entry on Detailed Customer Ledger Entry.
        Initialize();
        ApplyAndAdjustExchRateForCust(LibraryRandom.RandDec(100, 2), DetailedCustLedgEntry."Entry Type"::"Realized Gain");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyAdjustExchRateLowerCust()
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        // Create Currency, General Journal Line for Invoice and Payment and Post, Modify Exchange Rate and Apply Posted Entry and Check
        // Realized Loss Entry on Detailed Customer Ledger Entry.
        Initialize();
        ApplyAndAdjustExchRateForCust(-LibraryRandom.RandDec(100, 2), DetailedCustLedgEntry."Entry Type"::"Realized Loss");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyAdjustExchRateHigherVend()
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        // Create Currency, General Journal Line for Invoice and Payment and Post, Modify Exchange Rate and Apply Posted Entry and Check
        // Realized Loss Entry on Detailed Vendor Ledger Entry.
        Initialize();
        ApplyAndAdjustExchRateForVend(LibraryRandom.RandDec(100, 2), DetailedVendorLedgEntry."Entry Type"::"Realized Loss");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplydjustExchRateLowerVend()
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        // Create Currency, General Journal Line for Invoice and Payment and Post, Modify Exchange Rate and Apply Posted Entry and Check
        // Realized Gain Entry on Detailed Vendor Ledger Entry.
        Initialize();
        ApplyAndAdjustExchRateForVend(-LibraryRandom.RandDec(100, 2), DetailedVendorLedgEntry."Entry Type"::"Realized Gain");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyCustomerLedgerEntry()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // Application using Customer Ledger Entry and Verify Applied Entry from Customer Ledger Entry.

        // Setup: Create Customer and Create and Post General Journal Line.
        Initialize();
        ClearGeneralJournalLine(GenJournalBatch);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer,
          CreateCustomer(), '', LibraryRandom.RandDec(100, 2), WorkDate());
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer,
          GenJournalLine."Account No.", '', -GenJournalLine.Amount, WorkDate());
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise: Apply and Post Invoice to Payment from Customer Ledger Entry.
        ApplyAndPostCustomerEntry(
          GenJournalLine."Document No.", GenJournalLine.Amount, GenJournalLine."Document No.",
          CustLedgerEntry."Document Type"::Payment, CustLedgerEntry."Document Type"::Invoice);

        // Verify: Verify Applied Entry from Customer Ledger Entry.
        VerifyCustomerLedgerEntry(GenJournalLine."Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RealizedLossDetailedLedgerVend()
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        // Check Detailed Vendor Ledger Entry for Realized Loss Entry after Applying Credit Memo for Vendor.
        Initialize();
        RealizedDetailedLedgerEntry(-LibraryRandom.RandDec(100, 2), DetailedVendorLedgEntry."Entry Type"::"Realized Loss");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RealizedGainDetailedLedgerVend()
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        // Check Detailed Vendor Ledger Entry for Realized Gain Entry after Applying Credit Memo for Vendor.
        Initialize();
        RealizedDetailedLedgerEntry(LibraryRandom.RandDec(100, 2), DetailedVendorLedgEntry."Entry Type"::"Realized Gain");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RealizedLossDetailedLedgerCust()
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        // Check Detailed Vendor Ledger Entry for Realized Loss Entry after Applying Credit Memo for Customer.
        Initialize();
        RealizedCustDetailedLedger(LibraryRandom.RandDec(100, 2), DetailedCustLedgEntry."Entry Type"::"Realized Loss");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RealizedGainDetailedLedgerCust()
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        // Check Detailed Customer Ledger Entry for Realized Gain Entry after Applying Credit Memo for Customer.
        Initialize();
        RealizedCustDetailedLedger(-LibraryRandom.RandDec(100, 2), DetailedCustLedgEntry."Entry Type"::"Realized Gain");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorUnrealizedLossInvoiceDebitCredit()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        Currency: Record Currency;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 309945] Unrealized Loss of Purchase Invoice has positive value after Exch. Rate adjustment
        Initialize();

        // [GIVEN] Currency with Exch.rate = 100 before WorkDate(), Exch.rate = 110 on workdate
        // [GIVEN] FCY Purchase Invoice is posted with Amount LCY = 1000
        Currency.Get(CreateCurrencyWithExchRate(-LibraryRandom.RandDecInDecimalRange(0.1, 0.5, 1)));
        CreatePostGenJnlLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor, CreateVendorWithCurrency(Currency.Code), WorkDate() - 1, -1, false);

        // [WHEN] Run Adjust Exch. Rate on workdate
        LibraryERM.RunExchRateAdjustmentSimple(GenJournalLine."Currency Code", WorkDate(), WorkDate());

        // [THEN] Unrealized Loss entry is posted with Debit Amount = 0 and Credit Amount = 100
        FindVendorLedgerEntry(
          VendorLedgerEntry, GenJournalLine."Account No.", VendorLedgerEntry."Document Type"::Invoice, GenJournalLine."Document No.");
        VerifyDtldVendEntryDebitCredit(
          GenJournalLine."Account No.", DetailedVendorLedgEntry."Entry Type"::"Unrealized Loss",
          0, Abs(GenJournalLine."Amount (LCY)" - VendorLedgerEntry."Amount (LCY)"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorUnrealizedLossPaymentDebitCredit()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        Currency: Record Currency;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 309945] Unrealized Loss of Vendor Payment has positive value after Exch. Rate adjustment
        Initialize();

        // [GIVEN] Currency with Exch.rate = 100 before WorkDate(), Exch.rate = 90 on workdate
        // [GIVEN] FCY Purchase Invoice is posted with Amount LCY = 1000
        Currency.Get(CreateCurrencyWithExchRate(LibraryRandom.RandDecInDecimalRange(0.1, 0.5, 1)));
        CreatePostGenJnlLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Vendor, CreateVendorWithCurrency(Currency.Code), WorkDate() - 1, 1, false);

        // [WHEN] Run Adjust Exch. Rate on workdate
        LibraryERM.RunExchRateAdjustmentSimple(GenJournalLine."Currency Code", WorkDate(), WorkDate());

        // [THEN] Unrealized Loss entry is posted with Debit Amount = 0 and Credit Amount = 100
        FindVendorLedgerEntry(
          VendorLedgerEntry, GenJournalLine."Account No.", VendorLedgerEntry."Document Type"::Payment, GenJournalLine."Document No.");
        VerifyDtldVendEntryDebitCredit(
          GenJournalLine."Account No.", DetailedVendorLedgEntry."Entry Type"::"Unrealized Loss",
          0, Abs(GenJournalLine."Amount (LCY)" - VendorLedgerEntry."Amount (LCY)"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorUnrealizedGainInvoiceDebitCredit()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        Currency: Record Currency;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 309945] Unrealized Gain of Purchase Invoice has positive value after Exch. Rate adjustment
        Initialize();

        // [GIVEN] Currency with Exch.rate = 100 before WorkDate(), Exch.rate = 90 on workdate
        // [GIVEN] FCY Purchase Invoice is posted with Amount LCY = 1000
        Currency.Get(CreateCurrencyWithExchRate(LibraryRandom.RandDecInDecimalRange(0.1, 0.5, 1)));
        CreatePostGenJnlLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor, CreateVendorWithCurrency(Currency.Code), WorkDate() - 1, -1, false);

        // [WHEN] Run Adjust Exch. Rate on workdate
        LibraryERM.RunExchRateAdjustmentSimple(GenJournalLine."Currency Code", WorkDate(), WorkDate());

        // [THEN] Unrealized Gain entry is posted with Debit Amount = 100 and Credit Amount = 0
        FindVendorLedgerEntry(
          VendorLedgerEntry, GenJournalLine."Account No.", VendorLedgerEntry."Document Type"::Invoice, GenJournalLine."Document No.");
        VerifyDtldVendEntryDebitCredit(
          GenJournalLine."Account No.", DetailedVendorLedgEntry."Entry Type"::"Unrealized Gain",
          Abs(GenJournalLine."Amount (LCY)" - VendorLedgerEntry."Amount (LCY)"), 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorUnrealizedGainPaymentDebitCredit()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        Currency: Record Currency;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 309945] Unrealized Gain of Vendor Payment has positive value after Exch. Rate adjustment
        Initialize();

        // [GIVEN] Currency with Exch.rate = 100 before WorkDate(), Exch.rate = 110 on workdate
        // [GIVEN] FCY Purchase Invoice is posted with Amount LCY = 1000
        Currency.Get(CreateCurrencyWithExchRate(-LibraryRandom.RandDecInDecimalRange(0.1, 0.5, 1)));
        CreatePostGenJnlLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Vendor, CreateVendorWithCurrency(Currency.Code), WorkDate() - 1, 1, false);

        // [WHEN] Run Adjust Exch. Rate on workdate
        LibraryERM.RunExchRateAdjustmentSimple(GenJournalLine."Currency Code", WorkDate(), WorkDate());

        // [THEN] Unrealized Gain entry is posted with Debit Amount = 100 and Credit Amount = 0
        FindVendorLedgerEntry(
          VendorLedgerEntry, GenJournalLine."Account No.", VendorLedgerEntry."Document Type"::Payment, GenJournalLine."Document No.");
        VerifyDtldVendEntryDebitCredit(
          GenJournalLine."Account No.", DetailedVendorLedgEntry."Entry Type"::"Unrealized Gain",
          Abs(GenJournalLine."Amount (LCY)" - VendorLedgerEntry."Amount (LCY)"), 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerUnrealizedLossInvoiceDebitCredit()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        Currency: Record Currency;
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 309945] Unrealized Loss of Sales Invoice has positive value after Exch. Rate adjustment
        Initialize();

        // [GIVEN] Currency with Exch.rate = 100 before WorkDate(), Exch.rate = 90 on workdate
        // [GIVEN] FCY Sales Invoice is posted with Amount LCY = 1000
        Currency.Get(CreateCurrencyWithExchRate(LibraryRandom.RandDecInDecimalRange(0.1, 0.5, 1)));
        CreatePostGenJnlLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, CreateCustomerWithCurrency(Currency.Code), WorkDate() - 1, 1, false);

        // [WHEN] Run Adjust Exch. Rate on workdate
        LibraryERM.RunExchRateAdjustmentSimple(GenJournalLine."Currency Code", WorkDate(), WorkDate());

        // [THEN] Unrealized Loss entry is posted with Debit Amount = 0 and Credit Amount = 100
        FindCustomerLedgerEntry(
          CustLedgerEntry, GenJournalLine."Account No.", CustLedgerEntry."Document Type"::Invoice, GenJournalLine."Document No.");
        VerifyDtldCustEntryDebitCredit(
          GenJournalLine."Account No.", DetailedCustLedgEntry."Entry Type"::"Unrealized Loss",
          0, Abs(GenJournalLine."Amount (LCY)" - CustLedgerEntry."Amount (LCY)"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerUnrealizedLossPaymentDebitCredit()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        Currency: Record Currency;
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 309945] Unrealized Loss of Customer Payment has positive value after Exch. Rate adjustment
        Initialize();

        // [GIVEN] Currency with Exch.rate = 100 before WorkDate(), Exch.rate = 110 on workdate
        // [GIVEN] FCY Sales Invoice is posted with Amount LCY = 1000
        Currency.Get(CreateCurrencyWithExchRate(-LibraryRandom.RandDecInDecimalRange(0.1, 0.5, 1)));
        CreatePostGenJnlLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, CreateCustomerWithCurrency(Currency.Code), WorkDate() - 1, -1, false);

        // [WHEN] Run Adjust Exch. Rate on workdate
        LibraryERM.RunExchRateAdjustmentSimple(GenJournalLine."Currency Code", WorkDate(), WorkDate());

        // [THEN] Unrealized Loss entry is posted with Debit Amount = 0 and Credit Amount = 100
        FindCustomerLedgerEntry(
          CustLedgerEntry, GenJournalLine."Account No.", CustLedgerEntry."Document Type"::Payment, GenJournalLine."Document No.");
        VerifyDtldCustEntryDebitCredit(
          GenJournalLine."Account No.", DetailedCustLedgEntry."Entry Type"::"Unrealized Loss",
          0, Abs(GenJournalLine."Amount (LCY)" - CustLedgerEntry."Amount (LCY)"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerUnrealizedGainInvoiceDebitCredit()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        Currency: Record Currency;
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 309945] Unrealized Gain of Sales Invoice has positive value after Exch. Rate adjustment
        Initialize();

        // [GIVEN] Currency with Exch.rate = 100 before WorkDate(), Exch.rate = 110 on workdate
        // [GIVEN] FCY Sales Invoice is posted with Amount LCY = 1000
        Currency.Get(CreateCurrencyWithExchRate(-LibraryRandom.RandDecInDecimalRange(0.1, 0.5, 1)));
        CreatePostGenJnlLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, CreateCustomerWithCurrency(Currency.Code), WorkDate() - 1, 1, false);

        // [WHEN] Run Adjust Exch. Rate on workdate
        LibraryERM.RunExchRateAdjustmentSimple(GenJournalLine."Currency Code", WorkDate(), WorkDate());

        // [THEN] Unrealized Gain entry is posted with Debit Amount = 100 and Credit Amount = 0
        FindCustomerLedgerEntry(
          CustLedgerEntry, GenJournalLine."Account No.", CustLedgerEntry."Document Type"::Invoice, GenJournalLine."Document No.");
        VerifyDtldCustEntryDebitCredit(
          GenJournalLine."Account No.", DetailedCustLedgEntry."Entry Type"::"Unrealized Gain",
          Abs(GenJournalLine."Amount (LCY)" - CustLedgerEntry."Amount (LCY)"), 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerUnrealizedGainPaymentDebitCredit()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        Currency: Record Currency;
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 309945] Unrealized Gain of Customer Payment has positive value after Exch. Rate adjustment
        Initialize();

        // [GIVEN] Currency with Exch.rate = 100 before WorkDate(), Exch.rate = 90 on workdate
        // [GIVEN] FCY Sales Invoice is posted with Amount LCY = 1000
        Currency.Get(CreateCurrencyWithExchRate(LibraryRandom.RandDecInDecimalRange(0.1, 0.5, 1)));
        CreatePostGenJnlLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, CreateCustomerWithCurrency(Currency.Code), WorkDate() - 1, -1, false);

        // [WHEN] Run Adjust Exch. Rate on workdate
        LibraryERM.RunExchRateAdjustmentSimple(GenJournalLine."Currency Code", WorkDate(), WorkDate());

        // [THEN] Unrealized Gain entry is posted with Debit Amount = 100 and Credit Amount = 0
        FindCustomerLedgerEntry(
          CustLedgerEntry, GenJournalLine."Account No.", CustLedgerEntry."Document Type"::Payment, GenJournalLine."Document No.");
        VerifyDtldCustEntryDebitCredit(
          GenJournalLine."Account No.", DetailedCustLedgEntry."Entry Type"::"Unrealized Gain",
          Abs(GenJournalLine."Amount (LCY)" - CustLedgerEntry."Amount (LCY)"), 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorUnrealizedLossInvoiceDebitCreditCorrection()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        Currency: Record Currency;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [FEATURE] [Purchase] [Correction]
        // [SCENARIO 309945] Unrealized Loss of Purchase Invoice with correction has negative value after Exch. Rate adjustment
        Initialize();

        // [GIVEN] Currency with Exch.rate = 100 before WorkDate(), Exch.rate = 110 on workdate
        // [GIVEN] FCY Purchase Invoice is posted with Amount LCY = 1000
        Currency.Get(CreateCurrencyWithExchRate(-LibraryRandom.RandDecInDecimalRange(0.1, 0.5, 1)));
        CreatePostGenJnlLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor, CreateVendorWithCurrency(Currency.Code), WorkDate() - 1, -1, true);

        // [WHEN] Run Adjust Exch. Rate on workdate
        LibraryERM.RunExchRateAdjustmentSimple(GenJournalLine."Currency Code", WorkDate(), WorkDate());

        // [THEN] Unrealized Loss entry is posted with Debit Amount = -100 and Credit Amount = 0
        FindVendorLedgerEntry(
          VendorLedgerEntry, GenJournalLine."Account No.", VendorLedgerEntry."Document Type"::Invoice, GenJournalLine."Document No.");
        VerifyDtldVendEntryDebitCredit(
          GenJournalLine."Account No.", DetailedVendorLedgEntry."Entry Type"::"Unrealized Loss",
          -Abs(GenJournalLine."Amount (LCY)" - VendorLedgerEntry."Amount (LCY)"), 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorUnrealizedLossPaymentDebitCreditCorrection()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        Currency: Record Currency;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [FEATURE] [Purchase] [Correction]
        // [SCENARIO 309945] Unrealized Loss of Vendor Payment with correction has negative value after Exch. Rate adjustment
        Initialize();

        // [GIVEN] Currency with Exch.rate = 100 before WorkDate(), Exch.rate = 90 on workdate
        // [GIVEN] FCY Purchase Invoice is posted with Amount LCY = 1000
        Currency.Get(CreateCurrencyWithExchRate(LibraryRandom.RandDecInDecimalRange(0.1, 0.5, 1)));
        CreatePostGenJnlLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Vendor, CreateVendorWithCurrency(Currency.Code), WorkDate() - 1, 1, true);

        // [WHEN] Run Adjust Exch. Rate on workdate
        LibraryERM.RunExchRateAdjustmentSimple(GenJournalLine."Currency Code", WorkDate(), WorkDate());

        // [THEN] Unrealized Loss entry is posted with Debit Amount = -100 and Credit Amount = 0
        FindVendorLedgerEntry(
          VendorLedgerEntry, GenJournalLine."Account No.", VendorLedgerEntry."Document Type"::Payment, GenJournalLine."Document No.");
        VerifyDtldVendEntryDebitCredit(
          GenJournalLine."Account No.", DetailedVendorLedgEntry."Entry Type"::"Unrealized Loss",
          -Abs(GenJournalLine."Amount (LCY)" - VendorLedgerEntry."Amount (LCY)"), 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorUnrealizedGainInvoiceDebitCreditCorrection()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        Currency: Record Currency;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [FEATURE] [Purchase] [Correction]
        // [SCENARIO 309945] Unrealized Gain of Purchase Invoice with correction has negative value after Exch. Rate adjustment
        Initialize();

        // [GIVEN] Currency with Exch.rate = 100 before WorkDate(), Exch.rate = 90 on workdate
        // [GIVEN] FCY Purchase Invoice is posted with Amount LCY = 1000
        Currency.Get(CreateCurrencyWithExchRate(LibraryRandom.RandDecInDecimalRange(0.1, 0.5, 1)));
        CreatePostGenJnlLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor, CreateVendorWithCurrency(Currency.Code), WorkDate() - 1, -1, true);

        // [WHEN] Run Adjust Exch. Rate on workdate
        LibraryERM.RunExchRateAdjustmentSimple(GenJournalLine."Currency Code", WorkDate(), WorkDate());

        // [THEN] Unrealized Gain entry is posted with Debit Amount = 0 and Credit Amount = -100
        FindVendorLedgerEntry(
          VendorLedgerEntry, GenJournalLine."Account No.", VendorLedgerEntry."Document Type"::Invoice, GenJournalLine."Document No.");
        VerifyDtldVendEntryDebitCredit(
          GenJournalLine."Account No.", DetailedVendorLedgEntry."Entry Type"::"Unrealized Gain",
          0, -Abs(GenJournalLine."Amount (LCY)" - VendorLedgerEntry."Amount (LCY)"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorUnrealizedGainPaymentDebitCreditCorrection()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        Currency: Record Currency;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [FEATURE] [Purchase] [Correction]
        // [SCENARIO 309945] Unrealized Gain of Vendor Payment with correction has negative value after Exch. Rate adjustment
        Initialize();

        // [GIVEN] Currency with Exch.rate = 100 before WorkDate(), Exch.rate = 110 on workdate
        // [GIVEN] FCY Purchase Invoice is posted with Amount LCY = 1000
        Currency.Get(CreateCurrencyWithExchRate(-LibraryRandom.RandDecInDecimalRange(0.1, 0.5, 1)));
        CreatePostGenJnlLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Vendor, CreateVendorWithCurrency(Currency.Code), WorkDate() - 1, 1, true);

        // [WHEN] Run Adjust Exch. Rate on workdate
        LibraryERM.RunExchRateAdjustmentSimple(GenJournalLine."Currency Code", WorkDate(), WorkDate());

        // [THEN] Unrealized Gain entry is posted with Debit Amount = 0 and Credit Amount = -100
        FindVendorLedgerEntry(
          VendorLedgerEntry, GenJournalLine."Account No.", VendorLedgerEntry."Document Type"::Payment, GenJournalLine."Document No.");
        VerifyDtldVendEntryDebitCredit(
          GenJournalLine."Account No.", DetailedVendorLedgEntry."Entry Type"::"Unrealized Gain",
          0, -Abs(GenJournalLine."Amount (LCY)" - VendorLedgerEntry."Amount (LCY)"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerUnrealizedLossInvoiceDebitCreditCorrection()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        Currency: Record Currency;
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // [FEATURE] [Sales] [Correction]
        // [SCENARIO 309945] Unrealized Loss of Sales Invoice with correction has negative value after Exch. Rate adjustment
        Initialize();

        // [GIVEN] Currency with Exch.rate = 100 before WorkDate(), Exch.rate = 90 on workdate
        // [GIVEN] FCY Sales Invoice is posted with Amount LCY = 1000
        Currency.Get(CreateCurrencyWithExchRate(LibraryRandom.RandDecInDecimalRange(0.1, 0.5, 1)));
        CreatePostGenJnlLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, CreateCustomerWithCurrency(Currency.Code), WorkDate() - 1, 1, true);

        // [WHEN] Run Adjust Exch. Rate on workdate
        LibraryERM.RunExchRateAdjustmentSimple(GenJournalLine."Currency Code", WorkDate(), WorkDate());

        // [THEN] Unrealized Loss entry is posted with Debit Amount = -100 and Credit Amount = 0
        FindCustomerLedgerEntry(
          CustLedgerEntry, GenJournalLine."Account No.", CustLedgerEntry."Document Type"::Invoice, GenJournalLine."Document No.");
        VerifyDtldCustEntryDebitCredit(
          GenJournalLine."Account No.", DetailedCustLedgEntry."Entry Type"::"Unrealized Loss",
          -Abs(GenJournalLine."Amount (LCY)" - CustLedgerEntry."Amount (LCY)"), 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerUnrealizedLossPaymentDebitCreditCorrection()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        Currency: Record Currency;
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // [FEATURE] [Sales] [Correction]
        // [SCENARIO 309945] Unrealized Loss of Customer Payment with correction has negative value after Exch. Rate adjustment
        Initialize();

        // [GIVEN] Currency with Exch.rate = 100 before WorkDate(), Exch.rate = 110 on workdate
        // [GIVEN] FCY Sales Invoice is posted with Amount LCY = 1000
        Currency.Get(CreateCurrencyWithExchRate(-LibraryRandom.RandDecInDecimalRange(0.1, 0.5, 1)));
        CreatePostGenJnlLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, CreateCustomerWithCurrency(Currency.Code), WorkDate() - 1, -1, true);

        // [WHEN] Run Adjust Exch. Rate on workdate
        LibraryERM.RunExchRateAdjustmentSimple(GenJournalLine."Currency Code", WorkDate(), WorkDate());

        // [THEN] Unrealized Loss entry is posted with Debit Amount = -100 and Credit Amount = 0
        FindCustomerLedgerEntry(
          CustLedgerEntry, GenJournalLine."Account No.", CustLedgerEntry."Document Type"::Payment, GenJournalLine."Document No.");
        VerifyDtldCustEntryDebitCredit(
          GenJournalLine."Account No.", DetailedCustLedgEntry."Entry Type"::"Unrealized Loss",
          -Abs(GenJournalLine."Amount (LCY)" - CustLedgerEntry."Amount (LCY)"), 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerUnrealizedGainInvoiceDebitCreditCorrection()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        Currency: Record Currency;
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // [FEATURE] [Sales] [Correction]
        // [SCENARIO 309945] Unrealized Gain of Sales Invoice with correction has negative value after Exch. Rate adjustment
        Initialize();

        // [GIVEN] Currency with Exch.rate = 100 before WorkDate(), Exch.rate = 110 on workdate
        // [GIVEN] FCY Sales Invoice is posted with Amount LCY = 1000
        Currency.Get(CreateCurrencyWithExchRate(-LibraryRandom.RandDecInDecimalRange(0.1, 0.5, 1)));
        CreatePostGenJnlLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, CreateCustomerWithCurrency(Currency.Code), WorkDate() - 1, 1, true);

        // [WHEN] Run Adjust Exch. Rate on workdate
        LibraryERM.RunExchRateAdjustmentSimple(GenJournalLine."Currency Code", WorkDate(), WorkDate());

        // [THEN] Unrealized Gain entry is posted with Debit Amount = 0 and Credit Amount = -100
        FindCustomerLedgerEntry(
          CustLedgerEntry, GenJournalLine."Account No.", CustLedgerEntry."Document Type"::Invoice, GenJournalLine."Document No.");
        VerifyDtldCustEntryDebitCredit(
          GenJournalLine."Account No.", DetailedCustLedgEntry."Entry Type"::"Unrealized Gain",
          0, -Abs(GenJournalLine."Amount (LCY)" - CustLedgerEntry."Amount (LCY)"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerUnrealizedGainPaymentDebitCreditCorrection()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        Currency: Record Currency;
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // [FEATURE] [Sales] [Correction]
        // [SCENARIO 309945] Unrealized Gain of Customer Payment with correction has negative value after Exch. Rate adjustment
        Initialize();

        // [GIVEN] Currency with Exch.rate = 100 before WorkDate(), Exch.rate = 90 on workdate
        // [GIVEN] FCY Sales Invoice is posted with Amount LCY = 1000
        Currency.Get(CreateCurrencyWithExchRate(LibraryRandom.RandDecInDecimalRange(0.1, 0.5, 1)));
        CreatePostGenJnlLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, CreateCustomerWithCurrency(Currency.Code), WorkDate() - 1, -1, true);

        // [WHEN] Run Adjust Exch. Rate on workdate
        LibraryERM.RunExchRateAdjustmentSimple(GenJournalLine."Currency Code", WorkDate(), WorkDate());

        // [THEN] Unrealized Gain entry is posted with Debit Amount = 0 and Credit Amount = -100
        FindCustomerLedgerEntry(
          CustLedgerEntry, GenJournalLine."Account No.", CustLedgerEntry."Document Type"::Payment, GenJournalLine."Document No.");
        VerifyDtldCustEntryDebitCredit(
          GenJournalLine."Account No.", DetailedCustLedgEntry."Entry Type"::"Unrealized Gain",
          0, -Abs(GenJournalLine."Amount (LCY)" - CustLedgerEntry."Amount (LCY)"));
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"ERM Exch. Rate Adjmt. Apply");
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        IsInitialized := true;
        Commit();

        LibrarySetupStorage.SaveGeneralLedgerSetup();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"ERM Exch. Rate Adjmt. Apply");
    end;

    local procedure RealizedCustDetailedLedger(ExchangeRateAmount: Decimal; EntryType: Enum "Detailed CV Ledger Entry Type")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
        Amount: Decimal;
        DocumentNo: Code[20];
    begin
        // Check Detailed Vendor Ledger Entry for Realized Loss Entry after Applying Credit Memo for Customer.
        ClearGeneralJournalLine(GenJournalBatch);
        DocumentNo :=
          RefundCreditMemoGeneralLine(
            TempGenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::Customer, CreateCustomer(),
            -LibraryRandom.RandDec(100, 2), ExchangeRateAmount);
        Amount := ComputeExhangeRate(TempGenJournalLine."Currency Code", TempGenJournalLine.Amount, ExchangeRateAmount);

        // Exercise: Apply Posted Credit Memo and Post Application.
        ApplyAndPostCustomerEntry(
          TempGenJournalLine."Document No.", TempGenJournalLine.Amount, DocumentNo,
          CustLedgerEntry."Document Type"::Refund, CustLedgerEntry."Document Type"::"Credit Memo");

        // Verify: Verify Detailed Vendor Ledger Entry after Apply Credit Memo.
        VerifyDetailedLedgerEntryCust(TempGenJournalLine."Document No.", -Amount, EntryType);
    end;

    local procedure RealizedDetailedLedgerEntry(ExchangeRateAmount: Decimal; EntryType: Enum "Detailed CV Ledger Entry Type")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
        DocumentNo: Code[20];
    begin
        // Create Rfund and Credit Memo General Line and Modify Exchange Rate.
        ClearGeneralJournalLine(GenJournalBatch);
        DocumentNo := RefundCreditMemoGeneralLine(
            TempGenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::Vendor, CreateVendor(),
            LibraryRandom.RandDec(100, 2), ExchangeRateAmount);

        // Apply Vendor Ledger Entry and Verify them.
        ApplyAndVerifyVendorEntry(TempGenJournalLine, ExchangeRateAmount, EntryType, DocumentNo);
    end;

    local procedure RefundCreditMemoGeneralLine(var TempGenJournalLine: Record "Gen. Journal Line" temporary; GenJournalBatch: Record "Gen. Journal Batch"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal; ExchangeRateAmount: Decimal): Code[20]
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        GeneralLineAmount: Decimal;
    begin
        // Setup: Create and Post General Journal Line for Refund and Credit Memo with Difference Currency Exchange Rate Amount.
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::"Credit Memo", AccountType, AccountNo,
          CreateCurrency(), Amount, WorkDate());
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Create New Exchange Rate and Run Adjust Exchange Rate Report.
        CreateNewExchangeRate(CurrencyExchangeRate, GenJournalLine."Currency Code", ExchangeRateAmount, GenJournalLine."Posting Date");
        LibraryERM.RunExchRateAdjustmentSimple(
          GenJournalLine."Currency Code", CurrencyExchangeRate."Starting Date", CurrencyExchangeRate."Starting Date");

        GeneralLineAmount := Amount / 2;  // Take partial amount for Refund Entry.
        CreateGeneralJournalLine(
          GenJournalLine2, GenJournalBatch, GenJournalLine."Document Type"::Refund, AccountType, AccountNo,
          GenJournalLine."Currency Code", -GeneralLineAmount, CurrencyExchangeRate."Starting Date");
        SaveGenJnlLineInTempTable(TempGenJournalLine, GenJournalLine2);
        LibraryERM.PostGeneralJnlLine(GenJournalLine2);
        exit(GenJournalLine."Document No.");
    end;

    local procedure ApplyAndAdjustExchRateForCust(ExchRateAmount: Decimal; EntryType: Enum "Detailed CV Ledger Entry Type")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
        DocumentNo: Code[20];
    begin
        // Setup: Create General Line for Invoice and Payment and Post them.
        Amount :=
          CreateGenLineAndModifyExchRate(
            GenJournalLine, DocumentNo, ExchRateAmount, GenJournalLine."Account Type"::Customer,
            CreateCustomer(), LibraryRandom.RandDec(100, 2));

        // Exercise: Apply Invoice and Post Customer Entry and Run Adjust Exchange Rate Batch.
        ApplyAndPostCustomerEntry(
          GenJournalLine."Document No.", GenJournalLine.Amount, DocumentNo,
          CustLedgerEntry."Document Type"::Payment, CustLedgerEntry."Document Type"::Invoice);
        LibraryERM.RunExchRateAdjustmentSimple(
          GenJournalLine."Currency Code", GenJournalLine."Posting Date", GenJournalLine."Posting Date");

        // Verify: Verify Detailed Ledger Entry has correct Realized entry.
        VerifyDetailedLedgerEntryCust(GenJournalLine."Document No.", -Amount, EntryType);
    end;

    local procedure ApplyAndAdjustExchRateForVend(ExchRateAmount: Decimal; EntryType: Enum "Detailed CV Ledger Entry Type")
    var
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
        DocumentNo: Code[20];
    begin
        // Setup: Create General Line for Invoice and Payment and Post them.
        Amount :=
          CreateGenLineAndModifyExchRate(
            GenJournalLine, DocumentNo, ExchRateAmount, GenJournalLine."Account Type"::Vendor,
            CreateVendor(), -LibraryRandom.RandDec(100, 2));

        // Exercise: Apply Invoice and Post Vendor Entry and Run Adjust Exchange Rate Batch.
        ApplyAndPostVendorEntry(GenJournalLine."Document No.", GenJournalLine.Amount, DocumentNo,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Document Type"::Invoice);
        LibraryERM.RunExchRateAdjustmentSimple(
          GenJournalLine."Currency Code", GenJournalLine."Posting Date", GenJournalLine."Posting Date");

        // Verify: Verify Detailed Vendor Ledger Entry for Realized Loss after Apply Invoice.
        VerifyDetailedLedgerEntryVend(GenJournalLine."Document No.", -Amount, EntryType);
    end;

    local procedure CreateGenLineAndModifyExchRate(var GenJournalLine2: Record "Gen. Journal Line"; var DocumentNo: Code[20]; ExchRateAmt: Decimal; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal): Decimal
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyCode: Code[10];
    begin
        CurrencyCode := CreateCurrency();
        LibraryERM.SetAddReportingCurrency(CurrencyCode);
        ClearGeneralJournalLine(GenJournalBatch);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Invoice, AccountType, AccountNo, CurrencyCode, Amount, WorkDate());
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        ModifyExchangeRate(CurrencyExchangeRate, CurrencyCode, ExchRateAmt);
        CreateGeneralJournalLine(
          GenJournalLine2, GenJournalBatch, GenJournalLine2."Document Type"::Payment, AccountType,
          AccountNo, GenJournalLine."Currency Code", -GenJournalLine.Amount / 2, WorkDate());
        Amount := GenJournalLine2.Amount * ExchRateAmt / CurrencyExchangeRate."Exchange Rate Amount";
        LibraryERM.PostGeneralJnlLine(GenJournalLine2);
        exit(Amount);
    end;

    [Normal]
    local procedure ApplyAndPostCustomerEntry(DocumentNo: Code[20]; AmountToApply: Decimal; DocumentNo2: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        LibraryERM.SetApplyCustomerEntry(CustLedgerEntry, AmountToApply);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry2, DocumentType2, DocumentNo2);
        CustLedgerEntry2.CalcFields("Remaining Amount");
        CustLedgerEntry2.Validate("Amount to Apply", CustLedgerEntry2."Remaining Amount");
        CustLedgerEntry2.Modify(true);
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry2);
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry);
    end;

    [Normal]
    local procedure ApplyAndPostVendorEntry(DocumentNo: Code[20]; AmountToApply: Decimal; DocumentNo2: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, DocumentType, DocumentNo);
        LibraryERM.SetApplyVendorEntry(VendorLedgerEntry, AmountToApply);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry2, DocumentType2, DocumentNo2);
        VendorLedgerEntry2.CalcFields("Remaining Amount");
        VendorLedgerEntry2.Validate("Amount to Apply", VendorLedgerEntry2."Remaining Amount");
        VendorLedgerEntry2.Modify(true);
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry2);
        LibraryERM.PostVendLedgerApplication(VendorLedgerEntry);
    end;

    local procedure ApplyAndVerifyVendorEntry(TempGenJournalLine: Record "Gen. Journal Line" temporary; ExchangeRateAmount: Decimal; EntryType: Enum "Detailed CV Ledger Entry Type"; DocumentNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Amount: Decimal;
    begin
        // Exercise: Apply Posted Credit Memo and Post Application.
        Amount := ComputeExhangeRate(TempGenJournalLine."Currency Code", TempGenJournalLine.Amount, ExchangeRateAmount);
        ApplyAndPostVendorEntry(
          TempGenJournalLine."Document No.", TempGenJournalLine.Amount, DocumentNo,
          VendorLedgerEntry."Document Type"::Refund, VendorLedgerEntry."Document Type"::"Credit Memo");

        // Verify: Verify Detailed Vendor Ledger Entry after Apply Credit Memo.
        VerifyDetailedLedgerEntryVend(TempGenJournalLine."Document No.", -Amount, EntryType);
    end;

    local procedure ClearGeneralJournalLine(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerWithCurrency(CurrencyCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer.Get(CreateCustomer());
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        exit(Vendor."No.");
    end;

    local procedure CreateVendorWithCurrency(CurrencyCode: Code[10]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(CreateVendor());
        Vendor.Validate("Currency Code", CurrencyCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        Currency.Get(LibraryERM.CreateCurrencyWithGLAccountSetup());
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateCurrencyExchRate(CurrencyCode: Code[10]; OnDate: Date; Factor: Decimal)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        CurrencyExchangeRate.FindLast();
        CurrencyExchangeRate."Starting Date" := OnDate;
        CurrencyExchangeRate.Validate("Exchange Rate Amount", CurrencyExchangeRate."Exchange Rate Amount" * Factor);
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", CurrencyExchangeRate."Exchange Rate Amount");
        CurrencyExchangeRate.Insert();
    end;

    local procedure CreateCurrencyWithExchRate(Delta: Decimal) CurrencyCode: Code[10]
    begin
        CurrencyCode := CreateCurrency();
        CreateCurrencyExchRate(CurrencyCode, WorkDate(), 1 + Delta);
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; CurrencyCode: Code[10]; Amount: Decimal; PostingDate: Date)
    begin
        // Take Random Amount for Invoice on General Journal Line.
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType, AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);
    end;

    local procedure CreatePostGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; PostingDate: Date; Sign: Integer; IsCorrection: Boolean)
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, DocumentType, AccountType, AccountNo, Sign * LibraryRandom.RandDecInRange(1000, 2000, 2));
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate(Correction, IsCorrection);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure ComputeExhangeRate(CurrencyCode: Code[10]; Amount: Decimal; ExchangeRateAmount: Decimal): Decimal
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        CurrencyExchangeRate.FindFirst();
        exit(Amount * ExchangeRateAmount / CurrencyExchangeRate."Exchange Rate Amount");
    end;

    local procedure FindCustomerLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        CustLedgerEntry.CalcFields("Amount (LCY)");
    end;

    local procedure FindVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; VendorNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, DocumentType, DocumentNo);
        VendorLedgerEntry.CalcFields("Amount (LCY)");
    end;

    local procedure ModifyExchangeRate(var CurrencyExchangeRate: Record "Currency Exchange Rate"; CurrencyCode: Code[10]; ExchRateAmt: Decimal)
    begin
        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        CurrencyExchangeRate.FindFirst();
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", CurrencyExchangeRate."Relational Exch. Rate Amount" + ExchRateAmt);
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure CreateNewExchangeRate(var CurrencyExchangeRate: Record "Currency Exchange Rate"; CurrencyCode: Code[10]; ExchRateAmt: Decimal; StartingDate: Date)
    var
        CurrencyExchangeRate2: Record "Currency Exchange Rate";
    begin
        CurrencyExchangeRate2.SetRange("Currency Code", CurrencyCode);
        CurrencyExchangeRate2.FindFirst();
        LibraryERM.CreateExchRate(CurrencyExchangeRate, CurrencyCode, StartingDate);
        CurrencyExchangeRate.Validate("Exchange Rate Amount", CurrencyExchangeRate2."Exchange Rate Amount");
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", CurrencyExchangeRate2."Adjustment Exch. Rate Amount");

        // Relational Exch. Rate Amount and Relational Adjmt Exch Rate Amt always greater than Exchange Rate Amount.
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", CurrencyExchangeRate2."Relational Exch. Rate Amount" + ExchRateAmt);
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", CurrencyExchangeRate2."Relational Exch. Rate Amount");
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure SaveGenJnlLineInTempTable(var NewGenJournalLine: Record "Gen. Journal Line"; GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJournalLine.FindSet();
        repeat
            NewGenJournalLine := GenJournalLine;
            NewGenJournalLine.Insert();
        until GenJournalLine.Next() = 0;
    end;

    local procedure VerifyACYAmountOnGLEntriesOfLastTransaction(AddCurrencyCode: Code[10])
    var
        GLEntry: Record "G/L Entry";
        CurrExchRate: Record "Currency Exchange Rate";
        ExpectedACYAmount: Decimal;
    begin
        GLEntry.FindLast();
        GLEntry.SetRange("Transaction No.", GLEntry."Transaction No.");
        GLEntry.FindSet();
        repeat
            ExpectedACYAmount :=
              Round(
                CurrExchRate.ExchangeAmtLCYToFCY(
                  GLEntry."Posting Date", AddCurrencyCode, GLEntry.Amount, CurrExchRate.ExchangeRate(GLEntry."Posting Date", AddCurrencyCode)));
            Assert.AreEqual(ExpectedACYAmount, GLEntry."Additional-Currency Amount", GLEntry.FieldName("Additional-Currency Amount"));
        until GLEntry.Next() = 0;
    end;

    local procedure VerifyCustomerLedgerEntry(DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, DocumentNo);
        CustLedgerEntry.SetRange("Closed by Entry No.", CustLedgerEntry."Entry No.");
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.FindFirst();
    end;

    local procedure VerifyDetailedLedgerEntryCust(DocumentNo: Code[20]; Amount: Decimal; EntryType: Enum "Detailed CV Ledger Entry Type")
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        Currency: Record Currency;
    begin
        DetailedCustLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedCustLedgEntry.SetRange("Entry Type", EntryType);
        DetailedCustLedgEntry.FindFirst();
        Currency.Get(DetailedCustLedgEntry."Currency Code");
        Assert.AreNearlyEqual(
          Amount, DetailedCustLedgEntry."Amount (LCY)", Currency."Amount Rounding Precision",
          StrSubstNo(AmountErr, DetailedCustLedgEntry.FieldCaption("Amount (LCY)"), Amount, DetailedCustLedgEntry.TableCaption(),
            DetailedCustLedgEntry.FieldCaption("Entry No."), DetailedCustLedgEntry."Entry No."));
    end;

    local procedure VerifyDetailedLedgerEntryVend(DocumentNo: Code[20]; Amount: Decimal; EntryType: Enum "Detailed CV Ledger Entry Type")
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        Currency: Record Currency;
    begin
        DetailedVendorLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedVendorLedgEntry.SetRange("Entry Type", EntryType);
        DetailedVendorLedgEntry.FindFirst();
        Currency.Get(DetailedVendorLedgEntry."Currency Code");
        Assert.AreNearlyEqual(
          Amount, DetailedVendorLedgEntry."Amount (LCY)", Currency."Amount Rounding Precision",
          StrSubstNo(AmountErr, DetailedVendorLedgEntry.FieldCaption("Amount (LCY)"), Amount, DetailedVendorLedgEntry.TableCaption(),
            DetailedVendorLedgEntry.FieldCaption("Entry No."), DetailedVendorLedgEntry."Entry No."));
    end;

    local procedure VerifyDtldVendEntryDebitCredit(VendorNo: Code[20]; EntryType: Enum "Detailed CV Ledger Entry Type"; DebitAmount: Decimal; CreditAmount: Decimal)
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DetailedVendorLedgEntry.SetRange("Vendor No.", VendorNo);
        DetailedVendorLedgEntry.SetRange("Entry Type", EntryType);
        DetailedVendorLedgEntry.FindFirst();
        DetailedVendorLedgEntry.TestField("Debit Amount (LCY)", DebitAmount);
        DetailedVendorLedgEntry.TestField("Credit Amount (LCY)", CreditAmount);
    end;

    local procedure VerifyDtldCustEntryDebitCredit(CustomerNo: Code[20]; EntryType: Enum "Detailed CV Ledger Entry Type"; DebitAmount: Decimal; CreditAmount: Decimal)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.SetRange("Customer No.", CustomerNo);
        DetailedCustLedgEntry.SetRange("Entry Type", EntryType);
        DetailedCustLedgEntry.FindFirst();
        DetailedCustLedgEntry.TestField("Debit Amount (LCY)", DebitAmount);
        DetailedCustLedgEntry.TestField("Credit Amount (LCY)", CreditAmount);
    end;
}
