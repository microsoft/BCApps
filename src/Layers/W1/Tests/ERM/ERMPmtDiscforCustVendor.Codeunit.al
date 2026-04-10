codeunit 134088 "ERM Pmt Disc for Cust/Vendor"
{
    Permissions = TableData "Cust. Ledger Entry" = rimd,
                  TableData "Vendor Ledger Entry" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Payment Discount] [Detailed Ledger Entry]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPmtDiscSetup: Codeunit "Library - Pmt Disc Setup";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryService: Codeunit "Library - Service";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        isInitialized: Boolean;
        AmountLCYErr: Label '%1 should be %2 in %3.', Comment = '.';
        UnappliedErr: Label '%1 %2 field must be true after Unapply entries.', Comment = '%1 = Detailed Customer Ledger Entry or Detailed Vendor Ledger Entry table caption. %2 = Unapplied field caption';
        ExpectedValueErr: Label 'Expected value %1 must exist.', Comment = '.';
        WrongCountErr: Label 'Wrong number of %1.', Comment = '.';
        NothingToAdjustTxt: Label 'There is nothing to adjust.';

    [Test]
    [Scope('OnPrem')]
    procedure SalePaymentDiscWithoutCurrency()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralLedgerSetup: Record "General Ledger Setup";
        DocumentNo: Code[20];
        PmtDiscAmountInclVAT: Decimal;
        PmtDiscAmountVAT: Decimal;
        OldAdjustforPaymentDiscount: Boolean;
    begin
        // Create Sales Invoice Post it and Post Payment with apply entry from General Line and Check VAT Adjustment and VAT Excluding
        // entry created on Detailed Customer Ledger Entry.

        // Modify Setup.
        Initialize();
        GeneralLedgerSetup.Get();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        OldAdjustforPaymentDiscount := ModifySetup(VATPostingSetup, true, GeneralLedgerSetup."Unrealized VAT");

        // Create Sales Invoice with Payment Discount and Post it and apply payment with General Journal Line.
        PmtDiscAmountInclVAT := SalesInvoiceWithPaymentDisc(DocumentNo, '');
        PmtDiscAmountVAT := FindVATAmount(VATPostingSetup, PmtDiscAmountInclVAT);

        // Verify: Verify Detailed Customer Ledger Entry for VAT Adjustment and VAT Excluding entries.
        VerifyPmtDiscDetailedCustLedgEntries(DocumentNo, -PmtDiscAmountInclVAT, -PmtDiscAmountVAT);

        // TearDown: Rollback Payment Discount Setup.
        UpdateVATPostingSetup(VATPostingSetup, OldAdjustforPaymentDiscount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalePaymentDiscWithCurrency()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralLedgerSetup: Record "General Ledger Setup";
        DocumentNo: Code[20];
        CurrencyCode: Code[10];
        PmtDiscAmountInclVAT: Decimal;
        PmtDiscAmountVAT: Decimal;
        OldAdjustforPaymentDiscount: Boolean;
    begin
        // Create Sales Invoice Post it with Currency and Post Payment with apply entry from General Line and Check VAT Adjustment and
        // VAT Excluding entry created on Detailed Customer Ledger Entry.

        // Modify Setup.
        Initialize();
        GeneralLedgerSetup.Get();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        OldAdjustforPaymentDiscount := ModifySetup(VATPostingSetup, true, GeneralLedgerSetup."Unrealized VAT");

        // Create Sales Invoice with Payment Discount and Currency and Post it and Apply Payment with General Journal Line.
        CurrencyCode := CreateCurrency();
        ModifyExchangeRate(CurrencyCode);
        PmtDiscAmountInclVAT := SalesInvoiceWithPaymentDisc(DocumentNo, CurrencyCode);
        PmtDiscAmountInclVAT := GetCurrencyExchRateAmount(PmtDiscAmountInclVAT, CurrencyCode);
        PmtDiscAmountVAT := FindVATAmount(VATPostingSetup, PmtDiscAmountInclVAT);

        // Verify: Verify Detailed Customer Ledger Entry for VAT Adjustment and VAT Excluding entries with Currency.
        VerifyPmtDiscDetailedCustLedgEntries(DocumentNo, -PmtDiscAmountInclVAT, -PmtDiscAmountVAT);

        // TearDown: Rollback Payment Discount Setup.
        UpdateVATPostingSetup(VATPostingSetup, OldAdjustforPaymentDiscount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchasePaymentDisc()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalLine: Record "Gen. Journal Line";
        VATPostingSetup: Record "VAT Posting Setup";
        PostedDocumentNo: Code[20];
        BuyfromVendorNo: Code[20];
        Amount: Decimal;
        PmtDiscAmountInclVAT: Decimal;
        PmtDiscAmountVAT: Decimal;
        OldAdjustforPaymentDiscount: Boolean;
    begin
        // Create Purchase Invoice Post it and Post Payment with apply entry from General Line and Check VAT Adjustment and VAT Excluding
        // entry created on Detailed Vendor Ledger Entry.

        // Setup: Modify Setup.
        Initialize();
        GeneralLedgerSetup.Get();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        OldAdjustforPaymentDiscount := ModifySetup(VATPostingSetup, true, GeneralLedgerSetup."Unrealized VAT");

        // Create Purchase Invoice with Payment Discount and Post it.
        BuyfromVendorNo := CreateVendor();
        PostedDocumentNo := CreateAndPostPurchaseInvoice(BuyfromVendorNo, '');
        Amount := GetPurchaseInvoiceHeaderAmt(PmtDiscAmountInclVAT, PostedDocumentNo);
        PmtDiscAmountVAT := FindVATAmount(VATPostingSetup, PmtDiscAmountInclVAT);

        // Exercise: Make a Payment entry from General Journal Line, Apply Payment on Invoice from Vendor Ledger Entries.
        CreatePostGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, BuyfromVendorNo, Amount, '');
        ApplyAndPostVendorEntry(GenJournalLine."Document No.", GenJournalLine.Amount, PostedDocumentNo);

        // Verify: Verify Detailed Vendor Ledger Entry for VAT Adjustment and VAT Excluding entries.
        VerifyPmtDiscDetailedVendLedgEntries(GenJournalLine."Document No.", PmtDiscAmountInclVAT, PmtDiscAmountVAT);

        // TearDown: Rollback Payment Discount Setup.
        UpdateVATPostingSetup(VATPostingSetup, OldAdjustforPaymentDiscount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyWithPmtDiscForCustomerExchRateAdjmt()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
        CurrencyCode: Code[10];
        PmtDiscAmountInclVAT: Decimal;
        PmtDiscAmountVAT: Decimal;
        OldAdjustforPaymentDiscount: Boolean;
    begin
        // Create Sales Invoice with Currency, run Adjust Exchange Rate Batch Job, Apply Payment from General Journal Line, Unapply
        // Payment and Check VAT Adjustment and VAT Excluding entry created on Detailed Customer Ledger Entry.

        // Setup: Modify Setup.
        Initialize();
        GeneralLedgerSetup.Get();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        OldAdjustforPaymentDiscount := ModifySetup(VATPostingSetup, true, true);

        // Create Sales Invoice with Payment Discount and Currency and Post it and Apply Payment with General Journal Line.
        CurrencyCode := CreateCurrency();
        PmtDiscAmountInclVAT := PostSalesInvoiceAndApplyPayment(DocumentNo, CurrencyCode);
        PmtDiscAmountInclVAT := GetCurrencyExchRateAmount(PmtDiscAmountInclVAT, CurrencyCode);
        PmtDiscAmountVAT := FindVATAmount(VATPostingSetup, PmtDiscAmountInclVAT);

        // Exercise: Unapply Payment from Customer Ledger Entry.
        UnapplyCustLedgerEntry(GenJournalLine."Document Type"::Payment, DocumentNo);

        // Verify: Verify Detailed Customer Ledger Entry for VAT Adjustment and VAT Excluding entries with Currency.
        VerifyPmtDiscDetailedCustLedgEntries(DocumentNo, -PmtDiscAmountInclVAT, -PmtDiscAmountVAT);

        // TearDown: Cleanup the Setups done.
        UpdateVATPostingSetup(VATPostingSetup, OldAdjustforPaymentDiscount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyWithPmtDiscCalcOnCrMemosForCustomer()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        GenJnlLine: Record "Gen. Journal Line";
        PmtDocNo: Code[20];
        OldAdjustforPaymentDiscount: Boolean;
    begin
        // Create Invoice and Credit Memo with the same amount, apply payments with the same document no., unapply payments and
        // check Unpplied and Remaining Amount on Detailed Customer Ledger Entry.

        Initialize();
        GeneralLedgerSetup.Get();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        OldAdjustforPaymentDiscount := ModifySetup(VATPostingSetup, true, GeneralLedgerSetup."Unrealized VAT");

        PmtDocNo := PostApplyUnapplyCustPaymentsToInvCrMemoWithPmtDisc();

        VerifyUnappliedDtldCustLedgEntry(PmtDocNo, GenJnlLine."Document Type"::Payment);
        VerifyCustLedgerEntryForRemAmt(GenJnlLine."Document Type"::Payment, PmtDocNo);
        VerifyUnappliedDtldCustLedgEntry(PmtDocNo, GenJnlLine."Document Type"::Refund);
        VerifyCustLedgerEntryForRemAmt(GenJnlLine."Document Type"::Refund, PmtDocNo);

        UpdateVATPostingSetup(VATPostingSetup, OldAdjustforPaymentDiscount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyWithPmtDiscCalcOnCrMemosForVendor()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        GenJnlLine: Record "Gen. Journal Line";
        PmtDocNo: Code[20];
        OldAdjustforPaymentDiscount: Boolean;
    begin
        // Create Invoice and Credit Memo with the same amount, apply payments with the same document no., unapply payments and
        // check Unpplied and Remaining Amount on Detailed Customer Ledger Entry.

        Initialize();
        GeneralLedgerSetup.Get();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        OldAdjustforPaymentDiscount := ModifySetup(VATPostingSetup, true, GeneralLedgerSetup."Unrealized VAT");

        PmtDocNo := PostApplyUnapplyVendPaymentsToInvCrMemoWithPmtDisc();

        VerifyUnappliedDtldVendLedgEntry(PmtDocNo, GenJnlLine."Document Type"::Payment);
        VerifyVendLedgerEntryForRemAmt(GenJnlLine."Document Type"::Payment, PmtDocNo);
        VerifyUnappliedDtldVendLedgEntry(PmtDocNo, GenJnlLine."Document Type"::Refund);
        VerifyVendLedgerEntryForRemAmt(GenJnlLine."Document Type"::Refund, PmtDocNo);

        UpdateVATPostingSetup(VATPostingSetup, OldAdjustforPaymentDiscount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyWithPmtDiscForVendorExchRateAdjmt()
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalLine: Record "Gen. Journal Line";
        VATPostingSetup: Record "VAT Posting Setup";
        PostedDocumentNo: Code[20];
        CurrencyCode: Code[10];
        BuyfromVendorNo: Code[20];
        Amount: Decimal;
        PmtDiscAmountInclVAT: Decimal;
        PmtDiscAmountVAT: Decimal;
        OldAdjustforPaymentDiscount: Boolean;
    begin
        // Create Purchase Invoice with currency, Post it, run Adjust Exchange Rate Batch Job and Post Payment with apply entry from General
        // Line and Check VAT Adjustment and VAT Excluding entry created on Detailed Vendor Ledger Entry.

        // Setup: Modify Setup.
        Initialize();
        GeneralLedgerSetup.Get();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        OldAdjustforPaymentDiscount := ModifySetup(VATPostingSetup, true, true);

        // Create Purchase Invoice with Payment Discount, Currency and Post it and Apply Payment with General Journal Line.
        CurrencyCode := CreateCurrency();
        BuyfromVendorNo := CreateVendor();
        PostedDocumentNo := CreateAndPostPurchaseInvoice(BuyfromVendorNo, CurrencyCode);
        Amount := GetPurchaseInvoiceHeaderAmt(PmtDiscAmountInclVAT, PostedDocumentNo);
        PmtDiscAmountVAT := FindVATAmount(VATPostingSetup, PmtDiscAmountInclVAT);

        CreateExchangeRate(CurrencyCode);
        FindCurrencyExchangeRate(CurrencyExchangeRate, CurrencyCode);

        LibraryERM.RunExchRateAdjustmentSimple(CurrencyCode, CurrencyExchangeRate."Starting Date", CurrencyExchangeRate."Starting Date");

        CreatePostGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, BuyfromVendorNo, Amount,
          CurrencyCode);
        ApplyAndPostVendorEntry(GenJournalLine."Document No.", GenJournalLine.Amount, PostedDocumentNo);

        // Exercise: Unapply Payment from Vendor Ledger Entry.
        UnapplyVendLedgerEntry(GenJournalLine."Document Type", GenJournalLine."Document No.");

        // Verify: Verify Detailed Vendor Ledger Entry for VAT Adjustment and VAT Excluding entries.
        VerifyPmtDiscDetailedVendLedgEntries(GenJournalLine."Document No.", PmtDiscAmountInclVAT, PmtDiscAmountVAT);

        // TearDown: Cleanup the Setups done.
        UpdateVATPostingSetup(VATPostingSetup, OldAdjustforPaymentDiscount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyWithPmtDiscForCustomerRevCharge()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VATGLAccountNo: Code[20];
        InvoiceNo: Code[20];
        PaymentNo: Code[20];
        PmtDiscAmountInclVAT: Decimal;
    begin
        // [FEATURE] [Unapply] [Reverse Charge VAT] [Sales]
        // [SCENARIO 301002] VAT Entry for Sales Invoice with Payment Discount and Reverse Charge VAT is reversed after unapply
        Initialize();

        // [GIVEN] General Ledger Setup with "Adjust for Payment Disc." = True and "Pmt. Disc. Excl. VAT" = False
        ModifyGeneralLedgerSetup(true, false);
        LibraryPmtDiscSetup.SetPmtDiscExclVAT(false);

        // [GIVEN] Sales Invoice with Payment Discount applied to payment
        // [GIVEN] Invoice Amount = 1000, Payment Discount Amount = 50, VAT% = 20
        CreateSalesInvoiceRevCharge(SalesHeader, VATGLAccountNo, CreateCustomer(), CreateCurrency(), LibraryRandom.RandIntInRange(10, 20));
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        PaymentNo :=
          CreatePostApplyCustGenJournalLine(
            PmtDiscAmountInclVAT, SalesHeader."Sell-to Customer No.", InvoiceNo, SalesHeader."Currency Code");
        PmtDiscAmountInclVAT := GetCurrencyExchRateAmount(PmtDiscAmountInclVAT, SalesHeader."Currency Code");

        // [WHEN] Unapply Payment from Customer Ledger Entry
        UnapplyCustLedgerEntry(CustLedgerEntry."Document Type"::Payment, PaymentNo);

        // [THEN] VAT Entry is created with amounts after unapply for Base = 50 and Amount = 0
        VerifyUnappliedVATEntry(PaymentNo, SalesHeader."Sell-to Customer No.", PmtDiscAmountInclVAT, 0);
        // [THEN] Two G/L Entries created with amount of 50 for Receivables G/L Account
        // [THEN] No G/L Entries created for Sales VAT Account
        VerifyUnappliedGLEntriesSales(PaymentNo, SalesHeader."Sell-to Customer No.", VATGLAccountNo, PmtDiscAmountInclVAT, 2);

        DeleteVATPostingSetup(SalesHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyWithPmtDiscForVendorRevCharge()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VATGLAccountNo: Code[20];
        InvoiceNo: Code[20];
        PaymentNo: Code[20];
        PmtDiscAmountInclVAT: Decimal;
        PmtDiscAmountVAT: Decimal;
        VATPct: Decimal;
    begin
        // [FEATURE] [Unapply] [Reverse Charge VAT] [Purchase]
        // [SCENARIO 301002] VAT Entry for Purchase Invoice with Payment Discount and Reverse Charge VAT is reversed after unapply
        Initialize();

        // [GIVEN] General Ledger Setup with "Adjust for Payment Disc." = True and "Pmt. Disc. Excl. VAT" = False
        ModifyGeneralLedgerSetup(true, false);

        // [GIVEN] Purchase Invoice with Payment Discount applied to payment
        // [GIVEN] Invoice Amount = 1000, Payment Discount Amount = 50, VAT% = 20
        VATPct := LibraryRandom.RandIntInRange(10, 20);
        CreatePurchaseInvoiceRevCharge(PurchaseHeader, VATGLAccountNo, CreateVendor(), CreateCurrency(), VATPct);
        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        PaymentNo :=
          CreatePostApplyVendGenJournalLine(
            PmtDiscAmountInclVAT, PurchaseHeader."Buy-from Vendor No.", InvoiceNo, PurchaseHeader."Currency Code");
        PmtDiscAmountInclVAT := GetCurrencyExchRateAmount(PmtDiscAmountInclVAT, PurchaseHeader."Currency Code");
        PmtDiscAmountVAT := Round(PmtDiscAmountInclVAT * VATPct / 100);

        // [WHEN] Unapply Payment from Vendor Ledger Entry
        UnapplyVendLedgerEntry(VendorLedgerEntry."Document Type"::Payment, PaymentNo);

        // [THEN] VAT Entry is created with amounts after unapply for Base = -50 and Amount = -10
        VerifyUnappliedVATEntry(PaymentNo, PurchaseHeader."Buy-from Vendor No.", -PmtDiscAmountInclVAT, -PmtDiscAmountVAT);
        // [THEN] Two G/L Entries created with amount of 50 for Payables G/L Account
        // [THEN] Two G/L Entries created with amount of -10 for Purchase VAT Account
        VerifyUnappliedGLEntriesPurchase(
          PaymentNo, PurchaseHeader."Buy-from Vendor No.", VATGLAccountNo, -PmtDiscAmountInclVAT, PmtDiscAmountVAT, 4, 1);

        DeleteVATPostingSetup(PurchaseHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentTermsCreation()
    var
        PaymentTerms: Record "Payment Terms";
        DueDateCalculation: DateFormula;
        DiscountPct: Decimal;
    begin
        // Create Payment Terms and check it's creation.

        // Setup.
        Initialize();

        // Exercise: Create Payment Terms and Set Parameters.
        LibraryERM.CreatePaymentTerms(PaymentTerms);

        // Calculating DueDateCalculation using LibraryRandom.
        Evaluate(DueDateCalculation, StrSubstNo('%1D', LibraryRandom.RandInt(10)));
        DiscountPct := LibraryRandom.RandDec(10, 2);
        SetParameters(PaymentTerms, DueDateCalculation, DiscountPct);

        // Verify: Verify Payment Terms.
        VerifyPaymentTerms(PaymentTerms.Code, DueDateCalculation, DiscountPct);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLAccountDirectPosting()
    var
        GLAccount: Record "G/L Account";
    begin
        // Check whether Direct Posting can be set as TRUE on G/L account.

        // Setup: Create a G/L Account.
        Initialize();
        LibraryERM.CreateGLAccount(GLAccount);

        // Exercise: Set Direct Posting as True in G/L Account.
        GLAccount.Validate("Direct Posting", true);
        GLAccount.Modify(true);

        // Verify: Verify Direct Posting as True in G/L Account.
        GLAccount.Get(GLAccount."No.");
        GLAccount.TestField("Direct Posting", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentDiscountForVendor()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalLine: Record "Gen. Journal Line";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        DiscountAmountLCY: Decimal;
        OldAdjustforPaymentDiscount: Boolean;
    begin
        // Check Payment Discount Amount for Vendor after posting Invoice and Payment entries.

        // Setup: Modify Setup.
        Initialize();
        GeneralLedgerSetup.Get();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        OldAdjustforPaymentDiscount := ModifySetup(VATPostingSetup, true, true);

        // Create and post General Journal Line with Currency with Random values.
        CreatePostGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor, CreateVendorWithApplication(),
          -LibraryRandom.RandDec(100, 2), CreateCurrency());

        // Exercise: Create and Post Payment with Currency for Vendor and calculate Payment Discount Amount.
        CreatePostGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, GenJournalLine."Account No.",
          -GenJournalLine.Amount, GenJournalLine."Currency Code");
        DiscountAmountLCY := CalculatePaymentDiscountAmount(GenJournalLine, GenJournalLine."Payment Terms Code");

        // Verify: Verify Payment Discount Amount.
        VerifyDetailedVendLedgerEntryAmount(
          GenJournalLine."Document No.", DiscountAmountLCY, DetailedVendorLedgEntry."Entry Type"::"Payment Discount");

        // TearDown: Cleanup the Setups done.
        UpdateVATPostingSetup(VATPostingSetup, OldAdjustforPaymentDiscount);
    end;

    [Test]
    [HandlerFunctions('ApplyCustEntryPageHandler')]
    [Scope('OnPrem')]
    procedure ApplyCustEntriesOnCashRcptJnl()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        PmtDiscAmount: Decimal;
    begin
        // Verify Payment Discount Amount on Apply Customer Entries Page.

        // Setup: Create and post General Journal  Line, Create Cash Receipt Journal.
        Initialize();
        Customer.Get(CreateCustomerWithPaymentTerms());

        // Use Random large value for Amount as Payment Term Percent is small, blank value for Currency Code.
        CreatePostGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Account Type"::Customer, Customer."No.",
          -(100 + LibraryRandom.RandDec(100, 2)), '');
        PmtDiscAmount := -(GetPmtTermDisc(Customer."Payment Terms Code") * GenJournalLine.Amount) / 100;
        CreateGeneralJournalDocument(GenJournalLine, GenJournalTemplate.Type::"Cash Receipts");
        LibraryVariableStorage.Enqueue(PmtDiscAmount);  // Enqueue variable for ApplyCustEntryPageHandler.

        // Exercise: Apply Customer Entries with Set Applies to ID.
        SetAppliesToIDToCashRcptJnl(GenJournalLine."Journal Batch Name");

        // Verify: Verification for Payment Discount Amount done on ApplyCustEntryPageHandler.
    end;

    [Test]
    [HandlerFunctions('ApplyCustEntryPageHandler')]
    [Scope('OnPrem')]
    procedure ApplyAndPostCustEntriesOnCashRcptJnl()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        Amount: Decimal;
        PmtDiscAmount: Decimal;
    begin
        // Verify General Ledger Entry After Posting Cash Receipt Journal.

        // Setup: Create and post General Journal Line, Create Cash Receipt Journal.
        Initialize();
        Customer.Get(CreateCustomerWithPaymentTerms());

        // Use Random large value for Amount as Payment Term Percent is small, blank value for Currency Code.
        CreatePostGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Account Type"::Customer, Customer."No.",
          -(100 + LibraryRandom.RandDec(100, 2)), '');
        Amount := GenJournalLine.Amount;
        PmtDiscAmount := -(GetPmtTermDisc(Customer."Payment Terms Code") * Amount) / 100;
        CreateGeneralJournalDocument(GenJournalLine, GenJournalTemplate.Type::"Cash Receipts");
        LibraryVariableStorage.Enqueue(PmtDiscAmount);  // Enqueue variable for ApplyCustEntryPageHandler.
        SetAppliesToIDToCashRcptJnl(GenJournalLine."Journal Batch Name");
        ModifyGenJnlLine(GenJournalLine);

        // Exercise: Post Cash Receipt Journal.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify General ledger Entries.
        VerifyGLEntries(GenJournalLine, -Amount, 0);  // Use value 0 for Credit Amount.
    end;

    [Test]
    [HandlerFunctions('ApplyVendorPageHandler')]
    [Scope('OnPrem')]
    procedure ApplyVendEntriesOnPmtJnl()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        Vendor: Record Vendor;
        PmtDiscAmount: Decimal;
    begin
        // Verify Payment Discount Amount on Apply Vendor Entries Page.

        // Setup: Create and post General Journal Line, Create Purchase Journal.
        Initialize();
        Vendor.Get(CreateVendorWithPaymentTerms());

        // Use Random large value for Amount as Payment Term Percent is small, blank value for Currency Code.
        CreatePostGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Account Type"::Vendor, Vendor."No.",
          100 + LibraryRandom.RandDec(100, 2), '');
        PmtDiscAmount := -(GetPmtTermDisc(Vendor."Payment Terms Code") * GenJournalLine.Amount) / 100;
        CreateGeneralJournalDocument(GenJournalLine, GenJournalTemplate.Type::Purchases);
        LibraryVariableStorage.Enqueue(PmtDiscAmount);  // Enqueue variable for ApplyVendorPageHandler.

        // Exercise: Apply Vendor Entries with Set Applies to ID.
        SetAppliesToIDToPmtJnl(GenJournalLine."Journal Batch Name");

        // Verify: Verification done on ApplyVendorPageHandler.
    end;

    [Test]
    [HandlerFunctions('ApplyVendorPageHandler')]
    [Scope('OnPrem')]
    procedure ApplyAndPostVendEntriesOnPmtJnl()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        Vendor: Record Vendor;
        Amount: Decimal;
        PmtDiscAmount: Decimal;
    begin
        // Verify General Ledger Entry after posting Payment Journal.

        // Setup: Create and post General Journal Line, Create Purchase Journal.
        Initialize();
        Vendor.Get(CreateVendorWithPaymentTerms());

        // Use Random large value for Amount as Payment Term Percent is small, blank value for Currency Code.
        CreatePostGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Account Type"::Vendor, Vendor."No.",
          100 + LibraryRandom.RandDec(100, 2), '');
        Amount := GenJournalLine.Amount;
        PmtDiscAmount := -(GetPmtTermDisc(Vendor."Payment Terms Code") * Amount) / 100;
        CreateGeneralJournalDocument(GenJournalLine, GenJournalTemplate.Type::Purchases);
        LibraryVariableStorage.Enqueue(PmtDiscAmount);  // Enqueue variable for ApplyVendorPageHandler.
        SetAppliesToIDToPmtJnl(GenJournalLine."Journal Batch Name");
        ModifyGenJnlLine(GenJournalLine);

        // Exercise: Post Purchase Journal.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify General Ledger Entries.
        VerifyGLEntries(GenJournalLine, 0, Amount);   // Use value 0 for Debit Amount.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorCountyWithCityPostCode()
    var
        CountryRegion: Record "Country/Region";
        Vendor: Record Vendor;
        FormatAddress: Codeunit "Format Address";
        CountryRegionName: Text[50];
        AddrArray: array[8] of Text[100];
    begin
        // Verify ExpectedCounty when Vendor CountryRegion Address Format is City+Post Code.

        // Setup: Create Vendor and Update Address format on Vendor Country/Region.
        Initialize();
        CreateVendorWithAddress(Vendor);
        CountryRegionName := UpdateCountryRegion(Vendor."Country/Region Code", CountryRegion."Address Format"::"City+Post Code");

        // Exercise: Get Vendor Address Array Values from Format Address.
        FormatAddress.Vendor(AddrArray, Vendor);

        // Verify: Verify County and PostCodeCity are equal with Vendor Card County Post Code and City in the Array.
        VerifyArrayValuesWithCityPostcode(Vendor, CountryRegionName, AddrArray);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorCountyWithBalnkLinePostCodeCity()
    var
        CountryRegion: Record "Country/Region";
        Vendor: Record Vendor;
        FormatAddress: Codeunit "Format Address";
        AddrArray: array[8] of Text[100];
    begin
        // Verify ExpectedCounty when Vendor CountryRegion Address Format is Blank Line+Post Code+City.

        // Setup: Create Vendor and Update Address format on Vendor Country/Region.
        Initialize();
        CreateVendorWithAddress(Vendor);
        UpdateCountryRegion(Vendor."Country/Region Code", CountryRegion."Address Format"::"Blank Line+Post Code+City");

        // Exercise: Get Vendor Address Array Values from Format Address.
        FormatAddress.Vendor(AddrArray, Vendor);

        // Verify: Verify County and PostCodeCity are equal with Vendor Card County Post Code and City in the array.
        VerifyArrayValuesWithBlankLinePostCodeCity(Vendor, AddrArray);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATEntryCntAfterUnapplySalesSevDocsInOneTransaction()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        SalesInvoiceLine: Record "Sales Invoice Line";
        VATEntry: Record "VAT Entry";
        CustomerNo: Code[20];
        InvoiceDocNo: array[2] of Code[20];
        PaymentAmt: array[2] of Decimal;
        NoOfVATEntries: Integer;
        LastVATEntryNo: Integer;
        OldAdjustforPaymentDiscount: Boolean;
        OldUnrealizedVATType: Option;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 375774] System creates several reversal VATEntries for Payment Discount Adj. in case of unapply multiple docs in one transaction
        Initialize();
        GeneralLedgerSetup.Get();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        OldUnrealizedVATType := ModifyVATPostingSetupUnrealizedType(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::" ");
        OldAdjustforPaymentDiscount := ModifySetup(VATPostingSetup, true, GeneralLedgerSetup."Unrealized VAT");

        // [GIVEN] Posted two Sales Invoices for same customer, where Amount including discount: 80 and 50.
        CustomerNo := CreateCustomer();
        CreatePostTwoSalesInvoices(CustomerNo, InvoiceDocNo, PaymentAmt);
        VATEntry.FindLast();
        LastVATEntryNo := VATEntry."Entry No.";

        // [GIVEN] Two payment journal lines applied to posted Invoices, where Amounts: -80 and -50
        // [GIVEN] Third payment line to Bank where amount is 130 is to balance first two lines
        PreparePaymentLine(GenJournalLine, GenJournalLine."Account Type"::Customer, CustomerNo);
        CreatePostTwoPaymentsWithoutBalAcc(GenJournalLine, InvoiceDocNo, PaymentAmt);
        SalesInvoiceLine.SetFilter("Document No.", '%1|%2', InvoiceDocNo[1], InvoiceDocNo[2]);
        NoOfVATEntries := SalesInvoiceLine.Count();

        // [WHEN] Unapply last customer payment
        UnapplyCustLedgerEntry(GenJournalLine."Document Type"::Payment, GenJournalLine."Document No.");

        // [THEN] 4 VAT Entries is posted : 2 positive and 2 negative. Total amount is zero.
        VATEntry.SetRange("Entry No.", LastVATEntryNo + 1, LastVATEntryNo + 1 + 2 * NoOfVATEntries);

        VATEntry.SetFilter(Amount, '>%1', 0);
        Assert.AreEqual(NoOfVATEntries, VATEntry.Count, StrSubstNo(WrongCountErr, VATEntry.TableCaption()));

        VATEntry.SetFilter(Amount, '<%1', 0);
        Assert.AreEqual(NoOfVATEntries, VATEntry.Count, StrSubstNo(WrongCountErr, VATEntry.TableCaption()));

        VATEntry.SetRange(Amount);
        VATEntry.CalcSums(Amount);
        Assert.AreEqual(0, VATEntry.Amount, VATEntry.FieldCaption(Amount));

        // TearDown: Rollback Payment Discount Setup.
        ModifyVATPostingSetupUnrealizedType(VATPostingSetup, OldUnrealizedVATType);
        UpdateVATPostingSetup(VATPostingSetup, OldAdjustforPaymentDiscount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATEntryCntAfterUnapplyPurchSevDocsInOneTransaction()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        PurchInvLine: Record "Purch. Inv. Line";
        VATEntry: Record "VAT Entry";
        VendorNo: Code[20];
        InvoiceDocNo: array[2] of Code[20];
        PaymentAmt: array[2] of Decimal;
        NoOfVATEntries: Integer;
        LastVATEntryNo: Integer;
        OldAdjustforPaymentDiscount: Boolean;
        OldUnrealizedVATType: Option;
    begin
        // [FEATURE] [Purchases]
        // [SCENARIO 375774] System creates several reversal VATEntries for Payment Discount Adj. in case of unapply multiple docs in one transaction
        Initialize();
        GeneralLedgerSetup.Get();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        OldUnrealizedVATType := ModifyVATPostingSetupUnrealizedType(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::" ");
        OldAdjustforPaymentDiscount := ModifySetup(VATPostingSetup, true, GeneralLedgerSetup."Unrealized VAT");

        // [GIVEN] Posted two Purchase Invoices for same vendor, where Amount including discount: 80 and 50.
        VendorNo := CreateVendor();
        CreatePostTwoPurchInvoices(VendorNo, InvoiceDocNo, PaymentAmt);
        VATEntry.FindLast();
        LastVATEntryNo := VATEntry."Entry No.";

        // [GIVEN] Two payment journal lines applied to posted Invoices, where Amounts: 80 and 50
        // [GIVEN] Third payment line to Bank where amount is -130 is to balance first two lines
        PreparePaymentLine(GenJournalLine, GenJournalLine."Account Type"::Vendor, VendorNo);
        CreatePostTwoPaymentsWithoutBalAcc(GenJournalLine, InvoiceDocNo, PaymentAmt);
        PurchInvLine.SetFilter("Document No.", '%1|%2', InvoiceDocNo[1], InvoiceDocNo[2]);
        NoOfVATEntries := PurchInvLine.Count();

        // [WHEN] Unapply last vendor payment
        UnapplyVendLedgerEntry(GenJournalLine."Document Type"::Payment, GenJournalLine."Document No.");

        // [THEN] 4 VAT Entries is posted : 2 positive and 2 negative. Total amount is zero.
        VATEntry.SetRange("Entry No.", LastVATEntryNo + 1, LastVATEntryNo + 1 + 2 * NoOfVATEntries);

        VATEntry.SetFilter(Amount, '>%1', 0);
        Assert.AreEqual(NoOfVATEntries, VATEntry.Count, StrSubstNo(WrongCountErr, VATEntry.TableCaption()));

        VATEntry.SetFilter(Amount, '<%1', 0);
        Assert.AreEqual(NoOfVATEntries, VATEntry.Count, StrSubstNo(WrongCountErr, VATEntry.TableCaption()));

        VATEntry.SetRange(Amount);
        VATEntry.CalcSums(Amount);
        Assert.AreEqual(0, VATEntry.Amount, VATEntry.FieldCaption(Amount));

        // TearDown: Rollback Payment Discount Setup.
        ModifyVATPostingSetupUnrealizedType(VATPostingSetup, OldUnrealizedVATType);
        UpdateVATPostingSetup(VATPostingSetup, OldAdjustforPaymentDiscount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntryGenPostingTypeAfterUnapplyVendWithDiscount()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GLEntry: Record "G/L Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        VendorNo: Code[20];
        DocumentNo: Code[20];
        OldAdjustforPaymentDiscount: Boolean;
        OldUnrealizedVATType: Option;
        PmtDiscountAmt: Decimal;
    begin
        // [FEATURE] [Purchases]
        // [SCENARIO 375874] GLEntry."Gen. Posting Type" = Purchase for "Purch. Pmt. Disc. Credit Acc." after unapply vendor payment with discount
        Initialize();
        GeneralLedgerSetup.Get();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        OldUnrealizedVATType := ModifyVATPostingSetupUnrealizedType(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::" ");
        OldAdjustforPaymentDiscount := ModifySetup(VATPostingSetup, true, GeneralLedgerSetup."Unrealized VAT");

        // [GIVEN] Posted Purchase Invoice with possible discount.
        VendorNo := CreateVendor();
        DocumentNo := CreateAndPostPurchaseInvoice(VendorNo, '');

        // [GIVEN] Apply Payment to Purchase Invoice. Discount is deducted.
        DocumentNo := CreatePostApplyVendGenJournalLine(PmtDiscountAmt, VendorNo, DocumentNo, '');

        // [WHEN] Unapply payment.
        GLEntry.FindLast();
        UnapplyVendLedgerEntry(GenJournalLine."Document Type"::Payment, DocumentNo);

        // [THEN] GLEntry is posted, where "No." = "Purch. Pmt. Disc. Credit Acc." and "Gen. Posting Type" = "Purchase".
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        VerifyGLEntryGenPostingType(
          DocumentNo, GeneralPostingSetup."Purch. Pmt. Disc. Credit Acc.", true, GLEntry."Gen. Posting Type"::Purchase);

        // TearDown: Rollback Payment Discount Setup.
        ModifyVATPostingSetupUnrealizedType(VATPostingSetup, OldUnrealizedVATType);
        UpdateVATPostingSetup(VATPostingSetup, OldAdjustforPaymentDiscount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntryGenPostingTypeAfterUnapplyCustWithDiscount()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GLEntry: Record "G/L Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        CustomerNo: Code[20];
        DocumentNo: Code[20];
        OldAdjustforPaymentDiscount: Boolean;
        OldUnrealizedVATType: Option;
        PmtDiscountAmt: Decimal;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 375874] GLEntry."Gen. Posting Type" = Sale for "Sales Pmt. Disc. Debit Acc." after unapply customer payment with discount
        Initialize();
        GeneralLedgerSetup.Get();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        OldUnrealizedVATType := ModifyVATPostingSetupUnrealizedType(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::" ");
        OldAdjustforPaymentDiscount := ModifySetup(VATPostingSetup, true, GeneralLedgerSetup."Unrealized VAT");

        // [GIVEN] Posted Sales Invoice with possible discount.
        CustomerNo := CreateCustomer();
        DocumentNo := CreateAndPostSalesInvoice(CustomerNo, '');

        // [GIVEN] Apply Payment to Sales Invoice. Discount is deducted.
        DocumentNo := CreatePostApplyCustGenJournalLine(PmtDiscountAmt, CustomerNo, DocumentNo, '');

        // [WHEN] Unapply payment.
        GLEntry.FindLast();
        UnapplyCustLedgerEntry(GenJournalLine."Document Type"::Payment, DocumentNo);

        // [THEN] GLEntry is posted, where "No." = "Sales Pmt. Disc. Debit Acc." and "Gen. Posting Type" = "Sale".
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        VerifyGLEntryGenPostingType(
          DocumentNo, GeneralPostingSetup."Sales Pmt. Disc. Debit Acc.", false, GLEntry."Gen. Posting Type"::Sale);

        // TearDown: Rollback Payment Discount Setup.
        ModifyVATPostingSetupUnrealizedType(VATPostingSetup, OldUnrealizedVATType);
        UpdateVATPostingSetup(VATPostingSetup, OldAdjustforPaymentDiscount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPmtDiscountDateWhenUseZeroPmtDisc()
    var
        PaymentTerms: Record "Payment Terms";
        SalesHeader: Record "Sales Header";
        ExpectedPmtDiscDate: Date;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 378178] Payment Discount Date should be calculated according to "Discount Date Calculation" of Payment Terms

        Initialize();
        // [GIVEN] Payment Terms "X" with "Discount %" = 0, "Due Date Calculation" = 10 days, "Pmt. Discount Date Calculation" = 5 days
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, false);
        PaymentTerms.Validate("Discount %", 0);
        PaymentTerms.Modify(true);

        // [GIVEN] Sales Invoice with "Posting Date" = 01.01
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        ExpectedPmtDiscDate := CalcDate(PaymentTerms."Discount Date Calculation", SalesHeader."Posting Date");

        // [WHEN] Assign Payment Terms "X" to Sales Invoice
        SalesHeader.Validate("Payment Terms Code", PaymentTerms.Code);

        // [THEN] "Pmt. Discount Date" = 06.01 in Sales Invoice
        SalesHeader.TestField("Pmt. Discount Date", ExpectedPmtDiscDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchPmtDiscountDateWhenUseZeroPmtDisc()
    var
        PaymentTerms: Record "Payment Terms";
        PurchHeader: Record "Purchase Header";
        ExpectedPmtDiscDate: Date;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 378178] Payment Discount Date should be calculated according to "Discount Date Calculation" of Payment Terms

        Initialize();
        // [GIVEN] Payment Terms "X" with "Discount %" = 0, "Due Date Calculation" = 10 days, "Pmt. Discount Date Calculation" = 5 days
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, false);
        PaymentTerms.Validate("Discount %", 0);
        PaymentTerms.Modify(true);

        // [GIVEN] Purchase Invoice with "Posting Date" = 01.01
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        ExpectedPmtDiscDate := CalcDate(PaymentTerms."Discount Date Calculation", PurchHeader."Posting Date");

        // [WHEN] Assign Payment Terms "X" to Purchase Invoice
        PurchHeader.Validate("Payment Terms Code", PaymentTerms.Code);

        // [THEN] "Pmt. Discount Date" = 06.01 in Purchase Invoice
        PurchHeader.TestField("Pmt. Discount Date", ExpectedPmtDiscDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServPmtDiscountDateWhenUseZeroPmtDisc()
    var
        PaymentTerms: Record "Payment Terms";
        ServHeader: Record "Service Header";
        ExpectedPmtDiscDate: Date;
    begin
        // [FEATURE] [Service]
        // [SCENARIO 378178] Payment Discount Date should be calculated according to "Discount Date Calculation" of Payment Terms

        Initialize();
        // [GIVEN] Payment Terms "X" with "Discount %" = 0, "Due Date Calculation" = 10 days, "Pmt. Discount Date Calculation" = 5 days
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, false);
        PaymentTerms.Validate("Discount %", 0);
        PaymentTerms.Modify(true);

        // [GIVEN] Service Invoice with "Posting Date" = 01.01
        LibraryService.CreateServiceHeader(ServHeader, ServHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        ExpectedPmtDiscDate := CalcDate(PaymentTerms."Discount Date Calculation", ServHeader."Posting Date");

        // [WHEN] Assign Payment Terms "X" to Service Invoice
        ServHeader.Validate("Payment Terms Code", PaymentTerms.Code);

        // [THEN] "Pmt. Discount Date" = 06.01 in Service Invoice
        ServHeader.TestField("Pmt. Discount Date", ExpectedPmtDiscDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPmtDiscountDateWithGracePeriod()
    var
        PaymentTerms: Record "Payment Terms";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GracePeriod: DateFormula;
        ExpectedPmtDiscDate: Date;
        DocumentDate: Date;
        PostingDate: Date;
        DocumentNo: Code[20];
        ExpectedDiscountAmount: Decimal;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 344532] Payment Discount Date should be calculated according to "Discount Date Calculation" of Payment Terms and "Payment Discount Grace Period" of general ledger setup
        Initialize();

        // [GIVEN] Payment Terms "X" with "Discount %" = 10, "Due Date Calculation" = 10 days, "Pmt. Discount Date Calculation" = 5 days
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, false);

        // [GIVEN] "Payment Discount Grace Period" = 3D in General Ledger Setup
        Evaluate(GracePeriod, '<' + Format(LibraryRandom.RandIntInRange(3, 10)) + 'D>');
        LibraryPmtDiscSetup.SetPmtDiscGracePeriod(GracePeriod);

        // [GIVEN] Sales Invoice with "Document Date" = January 1st and "Posting Date" = January 9th
        // [GIVEN] Payment Terms "X" specified in invoice
        // [GIVEN] "Pmt. Discount Date" = January 6th in invoice
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());

        ExpectedPmtDiscDate := CalcDate(PaymentTerms."Discount Date Calculation", WorkDate());
        SalesHeader.Validate("Payment Terms Code", PaymentTerms.Code);
        SalesHeader.TestField("Pmt. Discount Date", ExpectedPmtDiscDate);

        DocumentDate := WorkDate();
        PostingDate := CalcDate(PaymentTerms."Discount Date Calculation", DocumentDate);
        PostingDate := CalcDate(GracePeriod, PostingDate);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Validate("Document Date", DocumentDate);
        SalesHeader.Modify(true);

        // [GIVEN] Amount = 1000 in invoice
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandIntInRange(100, 200));
        SalesLine.Modify(true);

        // [WHEN] Post invoice
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] "Original Pmt. Disc. Possible" = 100 and "Remaining Pmt. Disc. Possible" = 100 in posted Customer Ledger Entry.
        ExpectedDiscountAmount := Round(SalesLine."Amount Including VAT" * PaymentTerms."Discount %" / 100);

        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, DocumentNo);
        CustLedgerEntry.TestField("Original Pmt. Disc. Possible", ExpectedDiscountAmount);
        CustLedgerEntry.TestField("Remaining Pmt. Disc. Possible", ExpectedDiscountAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchPmtDiscountDateWithGracePeriod()
    var
        PaymentTerms: Record "Payment Terms";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GracePeriod: DateFormula;
        ExpectedPmtDiscDate: Date;
        DocumentDate: Date;
        PostingDate: Date;
        DocumentNo: Code[20];
        ExpectedDiscountAmount: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 344532] Payment Discount Date should be calculated according to "Discount Date Calculation" of Payment Terms and "Payment Discount Grace Period" of general ledger setup
        Initialize();

        // [GIVEN] Payment Terms "X" with "Discount %" = 10, "Due Date Calculation" = 10 days, "Pmt. Discount Date Calculation" = 5 days
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, false);
        // [GIVEN] "Payment Discount Grace Period" = 3D in General Ledger Setup
        Evaluate(GracePeriod, '<' + Format(LibraryRandom.RandIntInRange(3, 10)) + 'D>');
        LibraryPmtDiscSetup.SetPmtDiscGracePeriod(GracePeriod);

        // [GIVEN] Sales Invoice with "Document Date" = January 1st and "Posting Date" = January 9th
        // [GIVEN] Payment Terms "X" specified in invoice
        // [GIVEN] "Pmt. Discount Date" = January 6th in invoice
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());

        ExpectedPmtDiscDate := CalcDate(PaymentTerms."Discount Date Calculation", WorkDate());
        PurchaseHeader.Validate("Payment Terms Code", PaymentTerms.Code);
        PurchaseHeader.TestField("Pmt. Discount Date", ExpectedPmtDiscDate);

        DocumentDate := WorkDate();
        PostingDate := CalcDate(PaymentTerms."Discount Date Calculation", DocumentDate);
        PostingDate := CalcDate(GracePeriod, PostingDate);
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Validate("Document Date", DocumentDate);
        PurchaseHeader.Modify(true);

        // [GIVEN] Amount = 1000 in invoice
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(100, 200));
        PurchaseLine.Modify(true);

        // [WHEN] Post invoice
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] "Original Pmt. Disc. Possible" = -100 and "Remaining Pmt. Disc. Possible" = -100 in posted Customer Ledger Entry.
        ExpectedDiscountAmount := Round(PurchaseLine."Amount Including VAT" * PaymentTerms."Discount %" / 100);

        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, DocumentNo);
        VendorLedgerEntry.TestField("Original Pmt. Disc. Possible", -ExpectedDiscountAmount);
        VendorLedgerEntry.TestField("Remaining Pmt. Disc. Possible", -ExpectedDiscountAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPmtDiscountDateWithGracePeriodPostingDateExceedsPeriod()
    var
        PaymentTerms: Record "Payment Terms";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GracePeriod: DateFormula;
        ExpectedPmtDiscDate: Date;
        DocumentDate: Date;
        PostingDate: Date;
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 351131] "Original Pmt. Disc. Possible" is not calculated in Customer Ledger Entry when "Posting Date" exceeds "Payment Discount Period" + "Grace Period"
        Initialize();

        // [GIVEN] Payment Terms "X" with "Discount %" = 10, "Due Date Calculation" = 10 days, "Pmt. Discount Date Calculation" = 5 days
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, false);

        // [GIVEN] "Payment Discount Grace Period" = 3D in General Ledger Setup
        Evaluate(GracePeriod, '<' + Format(LibraryRandom.RandIntInRange(3, 10)) + 'D>');
        LibraryPmtDiscSetup.SetPmtDiscGracePeriod(GracePeriod);

        // [GIVEN] Sales Invoice with "Document Date" = January 1st and "Posting Date" = January 12th
        // [GIVEN] Payment Terms "X" specified in invoice
        // [GIVEN] "Pmt. Discount Date" = January 6th in invoice
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());

        ExpectedPmtDiscDate := CalcDate(PaymentTerms."Discount Date Calculation", WorkDate());
        SalesHeader.Validate("Payment Terms Code", PaymentTerms.Code);
        SalesHeader.TestField("Pmt. Discount Date", ExpectedPmtDiscDate);

        DocumentDate := WorkDate();
        PostingDate := CalcDate(PaymentTerms."Discount Date Calculation", DocumentDate);
        PostingDate := CalcDate(GracePeriod, PostingDate) + 1;
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Validate("Document Date", DocumentDate);
        SalesHeader.Modify(true);

        // [GIVEN] Amount = 1000 in invoice
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandIntInRange(100, 200));
        SalesLine.Modify(true);

        // [WHEN] Post invoice
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] "Original Pmt. Disc. Possible" = 0 and "Remaining Pmt. Disc. Possible" = 0 in posted Customer Ledger Entry as the discount period is exceeded.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, DocumentNo);
        CustLedgerEntry.TestField("Original Pmt. Disc. Possible", 0);
        CustLedgerEntry.TestField("Remaining Pmt. Disc. Possible", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchPmtDiscountDateWithGracePeriodPostingDateExceedsPeriod()
    var
        PaymentTerms: Record "Payment Terms";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GracePeriod: DateFormula;
        ExpectedPmtDiscDate: Date;
        DocumentDate: Date;
        PostingDate: Date;
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 351131] "Original Pmt. Disc. Possible" is not calculated in Vendor Ledger Entry when "Posting Date" exceeds "Payment Discount Period" + "Grace Period"
        Initialize();

        // [GIVEN] Payment Terms "X" with "Discount %" = 10, "Due Date Calculation" = 10 days, "Pmt. Discount Date Calculation" = 5 days
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, false);
        // [GIVEN] "Payment Discount Grace Period" = 3D in General Ledger Setup
        Evaluate(GracePeriod, '<' + Format(LibraryRandom.RandIntInRange(3, 10)) + 'D>');
        LibraryPmtDiscSetup.SetPmtDiscGracePeriod(GracePeriod);

        // [GIVEN] Sales Invoice with "Document Date" = January 1st and "Posting Date" = January 12th
        // [GIVEN] Payment Terms "X" specified in invoice
        // [GIVEN] "Pmt. Discount Date" = January 6th in invoice
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());

        ExpectedPmtDiscDate := CalcDate(PaymentTerms."Discount Date Calculation", WorkDate());
        PurchaseHeader.Validate("Payment Terms Code", PaymentTerms.Code);
        PurchaseHeader.TestField("Pmt. Discount Date", ExpectedPmtDiscDate);

        DocumentDate := WorkDate();
        PostingDate := CalcDate(PaymentTerms."Discount Date Calculation", DocumentDate);
        PostingDate := CalcDate(GracePeriod, PostingDate) + 1;
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Validate("Document Date", DocumentDate);
        PurchaseHeader.Modify(true);

        // [GIVEN] Amount = 1000 in invoice
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(100, 200));
        PurchaseLine.Modify(true);

        // [WHEN] Post invoice
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] "Original Pmt. Disc. Possible" = 0 and "Remaining Pmt. Disc. Possible" = 0 in posted Vendor Ledger Entry as the discount period is exceeded.
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, DocumentNo);
        VendorLedgerEntry.TestField("Original Pmt. Disc. Possible", 0);
        VendorLedgerEntry.TestField("Remaining Pmt. Disc. Possible", 0);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"ERM Pmt Disc for Cust/Vendor");

        LibraryApplicationArea.EnableFoundationSetup();
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"ERM Pmt Disc for Cust/Vendor");

        LibraryPurchase.SetInvoiceRounding(false);
        LibrarySales.SetInvoiceRounding(false);
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateAccountInVendorPostingGroups();
        LibraryERMCountryData.UpdateAccountInCustomerPostingGroup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.RemoveBlankGenJournalTemplate();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        LibraryERMCountryData.UpdateVATPostingSetup();

        FindUpdateVATPostingSetupVATPct(GetW1VATPct());
        FindUpdateGeneralPostingSetupAccounts();

        isInitialized := true;
        Commit();

        LibrarySetupStorage.SaveGeneralLedgerSetup();
        LibrarySetupStorage.SavePurchasesSetup();
        LibrarySetupStorage.SaveSalesSetup();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"ERM Pmt Disc for Cust/Vendor");
    end;

    local procedure ApplyAndPostCustomerEntry(DocumentNo: Code[20]; AmountToApply: Decimal; DocumentNo2: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, DocumentNo);
        LibraryERM.SetApplyCustomerEntry(CustLedgerEntry, AmountToApply);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry2, CustLedgerEntry2."Document Type"::Invoice, DocumentNo2);
        CustLedgerEntry2.CalcFields("Remaining Amount");
        CustLedgerEntry2.Validate("Amount to Apply", CustLedgerEntry2."Remaining Amount");
        CustLedgerEntry2.Modify(true);
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry2);
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry);
    end;

    local procedure ApplyAndPostVendorEntry(DocumentNo: Code[20]; AmountToApply: Decimal; DocumentNo2: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Payment, DocumentNo);
        LibraryERM.SetApplyVendorEntry(VendorLedgerEntry, AmountToApply);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry2, VendorLedgerEntry2."Document Type"::Invoice, DocumentNo2);
        VendorLedgerEntry2.CalcFields("Remaining Amount");
        VendorLedgerEntry2.Validate("Amount to Apply", VendorLedgerEntry2."Remaining Amount");
        VendorLedgerEntry2.Modify(true);
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry2);
        LibraryERM.PostVendLedgerApplication(VendorLedgerEntry);
    end;

    local procedure CalculatePaymentDiscountAmount(GenJournalLine: Record "Gen. Journal Line"; PaymentTermsCode: Code[10]): Decimal
    var
        PaymentTerms: Record "Payment Terms";
    begin
        PaymentTerms.Get(PaymentTermsCode);
        exit(
          LibraryERM.ConvertCurrency(GenJournalLine.Amount, GenJournalLine."Currency Code", '', GenJournalLine."Posting Date") *
          PaymentTerms."Discount %" / 100);
    end;

    local procedure PostApplyUnapplyCustPaymentsToInvCrMemoWithPmtDisc() PmtDocNo: Code[20]
    var
        GenJnlLine: Record "Gen. Journal Line";
        CustomerNo: Code[20];
        InvNo: Code[20];
        CrMemoNo: Code[20];
        Amount: Decimal;
    begin
        CustomerNo := CreateCustomerWithPaymentTerms();
        Amount := LibraryRandom.RandDec(100, 2);

        CreatePostPairedInvoiceAndCrMemo(GenJnlLine."Account Type"::Customer, CustomerNo, Amount, InvNo, CrMemoNo);

        PreparePaymentLine(GenJnlLine, GenJnlLine."Account Type"::Customer, CustomerNo);
        CreatePmtLineAppliedToDoc(
          GenJnlLine, GenJnlLine."Document Type"::Payment, GenJnlLine."Document Type"::Invoice, InvNo, -Amount);
        CreatePmtLineAppliedToDoc(
          GenJnlLine, GenJnlLine."Document Type"::Refund, GenJnlLine."Document Type"::"Credit Memo", CrMemoNo, Amount);

        LibraryERM.PostGeneralJnlLine(GenJnlLine);
        PmtDocNo := GenJnlLine."Document No.";
        UnapplyCustLedgerEntry(GenJnlLine."Document Type"::Payment, PmtDocNo);
        UnapplyCustLedgerEntry(GenJnlLine."Document Type"::Refund, PmtDocNo);
    end;

    local procedure PostApplyUnapplyVendPaymentsToInvCrMemoWithPmtDisc() PmtDocNo: Code[20]
    var
        GenJnlLine: Record "Gen. Journal Line";
        VendorNo: Code[20];
        InvNo: Code[20];
        CrMemoNo: Code[20];
        Amount: Decimal;
    begin
        VendorNo := CreateVendorWithPaymentTerms();
        Amount := LibraryRandom.RandDec(100, 2);

        CreatePostPairedInvoiceAndCrMemo(GenJnlLine."Account Type"::Vendor, VendorNo, -Amount, InvNo, CrMemoNo);

        PreparePaymentLine(GenJnlLine, GenJnlLine."Account Type"::Vendor, VendorNo);
        CreatePmtLineAppliedToDoc(
          GenJnlLine, GenJnlLine."Document Type"::Payment, GenJnlLine."Document Type"::Invoice, InvNo, Amount);
        CreatePmtLineAppliedToDoc(
          GenJnlLine, GenJnlLine."Document Type"::Refund, GenJnlLine."Document Type"::"Credit Memo", CrMemoNo, -Amount);

        PostGenJnlLineFromBatch(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name");
        PmtDocNo := GenJnlLine."Document No.";
        UnapplyVendLedgerEntry(GenJnlLine."Document Type"::Payment, PmtDocNo);
        UnapplyVendLedgerEntry(GenJnlLine."Document Type"::Refund, PmtDocNo);
    end;

    local procedure CreateVendorWithAddress(var Vendor: Record Vendor)
    var
        PostCode: Record "Post Code";
        CountryRegion: Record "Country/Region";
    begin
        LibraryERM.CreatePostCode(PostCode);
        LibraryERM.CreateCountryRegion(CountryRegion);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Country/Region Code", CountryRegion.Code);
        Vendor.Validate("Post Code", PostCode.Code);
        Vendor.Validate(County, LibraryUtility.GenerateGUID());
        Vendor.Modify(true);
    end;

    local procedure CreateSalesInvoice(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; CurrencyCode: Code[10])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);
        CreateSalesInvoiceLine(SalesHeader);
    end;

    local procedure CreateSalesInvoiceRevCharge(var SalesHeader: Record "Sales Header"; var VATGLAccountNo: Code[20]; CustomerNo: Code[20]; CurrencyCode: Code[10]; VATPct: Decimal)
    var
        SalesLine: Record "Sales Line";
        GLAccountNo: Code[20];
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);
        GLAccountNo := LibraryERM.CreateGLAccountWithSalesSetup();
        VATGLAccountNo := UpdateGLAccountRevChargeVAT(GLAccountNo, SalesHeader."VAT Bus. Posting Group", VATPct);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccountNo, LibraryRandom.RandIntInRange(2, 10));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesInvoiceLine(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        Counter: Integer;
    begin
        // Create Random Sales Invoice Line more than 1 with Random Quantity and unit Price in Decimal.
        for Counter := 1 to LibraryRandom.RandIntInRange(2, 5) do begin
            LibrarySales.CreateSalesLine(
              SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
              LibraryERM.CreateGLAccountWithSalesSetup(), LibraryRandom.RandIntInRange(2, 10));
            SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));
            SalesLine.Modify(true);
        end;
    end;

    local procedure CreatePurchaseInvoiceCurrency(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; CurrencyCode: Code[10])
    var
        LibraryPurchase: Codeunit "Library - Purchase";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Modify(true);
        CreatePurchaseInvoiceLine(PurchaseHeader);
    end;

    local procedure CreatePurchaseInvoiceRevCharge(var PurchaseHeader: Record "Purchase Header"; var VATGLAccountNo: Code[20]; VendorNo: Code[20]; CurrencyCode: Code[10]; VATPct: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
        GLAccountNo: Code[20];
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Modify(true);
        GLAccountNo := LibraryERM.CreateGLAccountWithPurchSetup();
        VATGLAccountNo := UpdateGLAccountRevChargeVAT(GLAccountNo, PurchaseHeader."VAT Bus. Posting Group", VATPct);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccountNo, LibraryRandom.RandIntInRange(2, 10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1000, 2000, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseInvoiceLine(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        Counter: Integer;
    begin
        // Create Random Purchase Invoice Line more than 1 with Random Quantity and Direct Unit cost in Decimal.
        for Counter := 1 to LibraryRandom.RandIntInRange(2, 5) do begin
            LibraryPurchase.CreatePurchaseLine(
              PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
              LibraryERM.CreateGLAccountWithPurchSetup(), LibraryRandom.RandIntInRange(2, 10));
            PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1000, 2000, 2));
            PurchaseLine.Modify(true);
        end;
    end;

    local procedure PreparePaymentLine(var PmtGenJnlLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; CVNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGeneralJournalBatch(GenJournalBatch);
        PmtGenJnlLine.Init();
        PmtGenJnlLine."Journal Template Name" := GenJournalBatch."Journal Template Name";
        PmtGenJnlLine."Journal Batch Name" := GenJournalBatch.Name;
        PmtGenJnlLine."Document Type" := PmtGenJnlLine."Document Type"::Payment;
        PmtGenJnlLine."Document No." :=
          CopyStr(
            LibraryUtility.GenerateRandomCode(PmtGenJnlLine.FieldNo("Document No."), DATABASE::"Gen. Journal Line"), 1, MaxStrLen(PmtGenJnlLine."Document No."));
        PmtGenJnlLine."Account Type" := AccountType;
        PmtGenJnlLine."Account No." := CVNo;
    end;

    local procedure CreatePmtLineAppliedToDoc(PmtGenJnlLine: Record "Gen. Journal Line"; DocType: Enum "Gen. Journal Document Type"; AppliesToDocType: Enum "Gen. Journal Document Type"; AppliesToDocNo: Code[20]; PmtAmount: Decimal)
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.FindBankAccount(BankAccount);
        CreatePmtLine(
          PmtGenJnlLine, DocType, PmtGenJnlLine."Bal. Account Type"::"Bank Account",
          BankAccount."No.", AppliesToDocType, AppliesToDocNo, PmtAmount);
    end;

    local procedure CreatePmtLine(PmtGenJnlLine: Record "Gen. Journal Line"; DocType: Enum "Gen. Journal Document Type"; BalAccountType: Enum "Gen. Journal Account Type"; BalAccountNo: Code[20]; AppliesToDocType: Enum "Gen. Journal Document Type"; AppliesToDocNo: Code[20]; PmtAmount: Decimal)
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        LibraryERM.CreateGeneralJnlLine(
            GenJnlLine, PmtGenJnlLine."Journal Template Name", PmtGenJnlLine."Journal Batch Name", DocType,
            PmtGenJnlLine."Account Type", PmtGenJnlLine."Account No.", PmtAmount);
        GenJnlLine.Validate("Bal. Account Type", BalAccountType);
        GenJnlLine.Validate("Bal. Account No.", BalAccountNo);
        GenJnlLine.Validate("Document No.", PmtGenJnlLine."Document No.");
        GenJnlLine.Validate("Applies-to Doc. Type", AppliesToDocType);
        GenJnlLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJnlLine.Modify(true);
    end;

    local procedure CreatePostGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal; CurrencyCode: Code[10])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType, AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreatePostPairedInvoiceAndCrMemo(AccountType: Enum "Gen. Journal Account Type"; CVNo: Code[20]; Amount: Decimal; var InvNo: Code[20]; var CrMemoNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);

        InvNo := CreateGenJnlLineWithBalAcc(GenJournalBatch, GenJnlLine."Document Type"::Invoice, AccountType, CVNo, Amount);
        CrMemoNo := CreateGenJnlLineWithBalAcc(GenJournalBatch, GenJnlLine."Document Type"::"Credit Memo", AccountType, CVNo, -Amount);
        PostGenJnlLineFromBatch(GenJournalBatch."Journal Template Name", GenJournalBatch.Name);
    end;

    local procedure CreateGenJnlLineWithBalAcc(GenJournalBatch: Record "Gen. Journal Batch"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; CVNo: Code[20]; Amount: Decimal): Code[20]
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJnlLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType, AccountType, CVNo,
          Amount);
        FillBalAccountData(GenJnlLine);
        exit(GenJnlLine."Document No.");
    end;

    local procedure FillBalAccountData(var GenJnlLine: Record "Gen. Journal Line")
    var
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        FindGeneralPostingSetup(GeneralPostingSetup);
        FindVATPostingSetup(VATPostingSetup);

        GenJnlLine.Validate("Bal. Account Type", GenJnlLine."Bal. Account Type"::"G/L Account");
        GenJnlLine.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());
        GenJnlLine.Validate("Bal. Gen. Posting Type", GetGenPostingType(GenJnlLine."Account Type"));
        GenJnlLine.Validate("Bal. Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        GenJnlLine.Validate("Bal. Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GenJnlLine.Validate("Bal. VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GenJnlLine.Validate("Bal. VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GenJnlLine.Modify(true);
    end;

    local procedure GetGenPostingType(AccountType: Enum "Gen. Journal Account Type"): Enum "General Posting Type"
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        case AccountType of
            GenJnlLine."Account Type"::Customer:
                exit(GenJnlLine."Bal. Gen. Posting Type"::Sale);
            GenJnlLine."Account Type"::Vendor:
                exit(GenJnlLine."Bal. Gen. Posting Type"::Purchase);
        end;
    end;

    local procedure PostGenJnlLineFromBatch(JnlTemplName: Code[10]; JnlBatchName: Code[10])
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine.Init();
        GenJnlLine."Journal Template Name" := JnlTemplName;
        GenJnlLine."Journal Batch Name" := JnlBatchName;
        LibraryERM.PostGeneralJnlLine(GenJnlLine);
    end;

    local procedure CreatePaymentTermsWithDiscountAndCalcPmtDiscOnCrMemos(): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        // Take Random Values for Payment Terms.
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, true);
        exit(PaymentTerms.Code);
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
        Currency.Validate("EMU Currency", true);
        Currency.Modify(true);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
        GeneralPostingSetup: Record "General Posting Setup";
        PaymentTerms: Record "Payment Terms";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        FindGeneralPostingSetup(GeneralPostingSetup);
        FindVATPostingSetup(VATPostingSetup);
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Validate("Payment Terms Code", PaymentTerms.Code);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerWithPaymentTerms(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Terms Code", CreatePaymentTermsWithDiscountAndCalcPmtDiscOnCrMemos());
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateVendor(): Code[20]
    var
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        PaymentTerms: Record "Payment Terms";
    begin
        FindGeneralPostingSetup(GeneralPostingSetup);
        FindVATPostingSetup(VATPostingSetup);
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Validate("Payment Terms Code", PaymentTerms.Code);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateVendorWithPaymentTerms(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Payment Terms Code", CreatePaymentTermsWithDiscountAndCalcPmtDiscOnCrMemos());
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateVendorWithApplication(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(CreateVendor());
        Vendor.Validate("Application Method", Vendor."Application Method"::"Apply to Oldest");
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"): Code[10]
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Recurring, false);
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::General);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        exit(GenJournalBatch.Name);
    end;

    local procedure CreateGeneralJournalDocument(var GenJournalLine: Record "Gen. Journal Line"; Type: Enum "Gen. Journal Template Type")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, FindTemplateName(Type));
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type", GenJournalLine."Account No.", 0);
    end;

    local procedure CreatePostApplyCustGenJournalLine(var PmtDiscAmount: Decimal; AccountNo: Code[20]; PostedDocumentNo: Code[20]; CurrencyCode: Code[10]): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
    begin
        Amount := GetSalesInvoiceHeaderAmt(PmtDiscAmount, PostedDocumentNo);
        CreatePostGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, AccountNo, -Amount, CurrencyCode);
        ApplyAndPostCustomerEntry(GenJournalLine."Document No.", GenJournalLine.Amount, PostedDocumentNo);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreatePostApplyVendGenJournalLine(var PmtDiscAmount: Decimal; AccountNo: Code[20]; PostedDocumentNo: Code[20]; CurrencyCode: Code[10]): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Amount: Decimal;
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, PostedDocumentNo);
        VendorLedgerEntry.CalcFields(Amount);
        Amount := -VendorLedgerEntry.Amount;
        PmtDiscAmount := -VendorLedgerEntry."Original Pmt. Disc. Possible";
        CreatePostGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, AccountNo, Amount, CurrencyCode);
        ApplyAndPostVendorEntry(GenJournalLine."Document No.", GenJournalLine.Amount, PostedDocumentNo);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreatePostTwoPaymentsWithoutBalAcc(GenJournalLine: Record "Gen. Journal Line"; InvoiceDocNo: array[2] of Code[20]; PaymentAmt: array[2] of Decimal)
    var
        i: Integer;
    begin
        for i := 1 to 2 do
            CreatePmtLine(
              GenJournalLine, GenJournalLine."Document Type"::Payment, "Gen. Journal Account Type"::"G/L Account", '',
              GenJournalLine."Applies-to Doc. Type"::Invoice, InvoiceDocNo[i], PaymentAmt[i]);
        GenJournalLine."Account Type" := GenJournalLine."Account Type"::"G/L Account";
        GenJournalLine."Account No." := LibraryERM.CreateGLAccountNo();
        CreatePmtLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment, "Gen. Journal Account Type"::"G/L Account", '', "Gen. Journal Account Type"::"G/L Account", '', -(PaymentAmt[1] + PaymentAmt[2]));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostSalesInvoice(CustomerNo: Code[20]; CurrencyCode: Code[10]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesInvoice(SalesHeader, CustomerNo, CurrencyCode);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreatePostTwoSalesInvoices(CustomerNo: Code[20]; var InvoiceDocNo: array[2] of Code[20]; var PaymentAmt: array[2] of Decimal)
    var
        DiscountAmt: array[2] of Decimal;
        i: Integer;
    begin
        for i := 1 to 2 do begin
            InvoiceDocNo[i] := CreateAndPostSalesInvoice(CustomerNo, '');
            PaymentAmt[i] := -GetSalesInvoiceHeaderAmt(DiscountAmt[i], InvoiceDocNo[i]);
        end;
    end;

    local procedure CreatePostTwoPurchInvoices(VendorNo: Code[20]; var InvoiceDocNo: array[2] of Code[20]; var PaymentAmt: array[2] of Decimal)
    var
        DiscountAmt: array[2] of Decimal;
        i: Integer;
    begin
        for i := 1 to 2 do begin
            InvoiceDocNo[i] := CreateAndPostPurchaseInvoice(VendorNo, '');
            PaymentAmt[i] := GetPurchaseInvoiceHeaderAmt(DiscountAmt[i], InvoiceDocNo[i]);
        end;
    end;

    local procedure CreateExchangeRate(CurrencyCode: Code[10])
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        // Use Random Number Generator for Exchange Rate.
        FindCurrencyExchangeRate(CurrencyExchangeRate, CurrencyCode);
        LibraryERM.CreateExchRate(CurrencyExchangeRate, CurrencyCode, WorkDate());
        CurrencyExchangeRate.Validate("Exchange Rate Amount", LibraryRandom.RandInt(100));
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", CurrencyExchangeRate."Exchange Rate Amount");
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", CurrencyExchangeRate."Exchange Rate Amount");
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", CurrencyExchangeRate."Exchange Rate Amount");
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure PostSalesInvoiceAndApplyPayment(var DocumentNo: Code[20]; CurrencyCode: Code[10]) PmtDiscAmount: Decimal
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        PostedDocumentNo: Code[20];
        SelltoCustomerNo: Code[20];
    begin
        SelltoCustomerNo := CreateCustomer();
        PostedDocumentNo := CreateAndPostSalesInvoice(SelltoCustomerNo, CurrencyCode);
        CreateExchangeRate(CurrencyCode);
        FindCurrencyExchangeRate(CurrencyExchangeRate, CurrencyCode);
        LibraryERM.RunExchRateAdjustmentSimple(CurrencyCode, CurrencyExchangeRate."Starting Date", CurrencyExchangeRate."Starting Date");
        DocumentNo := CreatePostApplyCustGenJournalLine(PmtDiscAmount, SelltoCustomerNo, PostedDocumentNo, CreateCurrency());
    end;

    local procedure CreateAndPostPurchaseInvoice(VendorNo: Code[20]; CurrencyCode: Code[10]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseInvoiceCurrency(PurchaseHeader, VendorNo, CurrencyCode);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure UpdateGLAccountRevChargeVAT(GLAccountNo: Code[20]; VATBusPostingGroupCode: Code[20]; VATPct: Decimal) VATGLAccountNo: Code[20]
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroupCode, VATProductPostingGroup.Code);
        VATGLAccountNo := LibraryERM.CreateGLAccountNo();
        VATPostingSetup.Validate("Sales VAT Account", VATGLAccountNo);
        VATPostingSetup.Validate("Purchase VAT Account", VATGLAccountNo);
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        VATPostingSetup.Validate("VAT Identifier", LibraryUtility.GenerateGUID());
        VATPostingSetup.Validate("VAT %", VATPct);
        VATPostingSetup.Validate("Adjust for Payment Discount", true);
        VATPostingSetup.Modify(true);
        GLAccount.Get(GLAccountNo);
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
    end;

    local procedure UnapplyCustLedgerEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        LibraryERM.UnapplyCustomerLedgerEntry(CustLedgerEntry);
    end;

    local procedure UnapplyVendLedgerEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    var
        VendLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendLedgerEntry, DocumentType, DocumentNo);
        LibraryERM.UnapplyVendorLedgerEntry(VendLedgerEntry);
    end;

    local procedure UpdateCountryRegion(CountryRegionCode: Code[10]; AddressFormat: Enum "Country/Region Address Format"): Text[50]
    var
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.Get(CountryRegionCode);
        CountryRegion.Validate("Address Format", AddressFormat);
        CountryRegion.Modify(true);
        exit(CountryRegion.Name);
    end;

    local procedure FindTemplateName(Type: Enum "Gen. Journal Template Type"): Code[10]
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, Type);
        GenJournalTemplate.FindFirst();
        exit(GenJournalTemplate.Name);
    end;

    local procedure FindVATAmount(VATPostingSetup: Record "VAT Posting Setup"; Amount: Decimal) VATAmount: Decimal
    begin
        VATAmount := Round(Amount * VATPostingSetup."VAT %" / (100 + VATPostingSetup."VAT %"));
    end;

    local procedure FindCurrencyExchangeRate(var CurrencyExchangeRate: Record "Currency Exchange Rate"; CurrencyCode: Code[10])
    begin
        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        CurrencyExchangeRate.FindFirst();
    end;

    local procedure FindGeneralPostingSetup(var GeneralPostingSetup: Record "General Posting Setup")
    begin
        GeneralPostingSetup.SetFilter("Sales Pmt. Disc. Credit Acc.", '<>%1', '');
        GeneralPostingSetup.SetFilter("Sales Pmt. Disc. Debit Acc.", '<>%1', '');
        GeneralPostingSetup.SetFilter("Purch. Pmt. Disc. Credit Acc.", '<>%1', '');
        GeneralPostingSetup.SetFilter("Purch. Pmt. Disc. Debit Acc.", '<>%1', '');
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
    end;

    local procedure FindVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATPostingSetup.SetRange("Adjust for Payment Discount", true);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
    end;

    local procedure FindDetailedCustLedgerEntry(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; EntryType: Enum "Detailed CV Ledger Entry Type")
    begin
        DetailedCustLedgEntry.SetRange("Entry Type", EntryType);
        DetailedCustLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedCustLedgEntry.SetRange("Document Type", DocumentType);
        DetailedCustLedgEntry.FindSet();
    end;

    local procedure FindDetailedVendLedgerEntry(var DetailedVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; EntryType: Enum "Detailed CV Ledger Entry Type")
    begin
        DetailedVendLedgEntry.SetRange("Entry Type", EntryType);
        DetailedVendLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedVendLedgEntry.SetRange("Document Type", DocumentType);
        DetailedVendLedgEntry.FindSet();
    end;

    local procedure FindUpdateGeneralPostingSetupAccounts()
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        // Using assignment to avoid error in ES.
        if GeneralPostingSetup."Sales Pmt. Disc. Credit Acc." = '' then
            GeneralPostingSetup."Sales Pmt. Disc. Credit Acc." := LibraryERM.CreateGLAccountNo();
        if GeneralPostingSetup."Sales Pmt. Disc. Debit Acc." = '' then
            GeneralPostingSetup."Sales Pmt. Disc. Debit Acc." := LibraryERM.CreateGLAccountNo();
        if GeneralPostingSetup."Purch. Pmt. Disc. Credit Acc." = '' then
            GeneralPostingSetup."Purch. Pmt. Disc. Credit Acc." := LibraryERM.CreateGLAccountNo();
        if GeneralPostingSetup."Purch. Pmt. Disc. Debit Acc." = '' then
            GeneralPostingSetup."Purch. Pmt. Disc. Debit Acc." := LibraryERM.CreateGLAccountNo();
        GeneralPostingSetup.Modify(true);
    end;

    local procedure FindUpdateVATPostingSetupVATPct(NewVATPct: Decimal)
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.UpdateVATPostingSetup(VATPostingSetup, NewVATPct);
    end;

    local procedure GetSalesInvoiceHeaderAmt(var DiscountAmount: Decimal; SalesInvoiceNo: Code[20]) Amount: Decimal
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.Get(SalesInvoiceNo);
        SalesInvoiceHeader.CalcFields("Amount Including VAT");
        DiscountAmount := Round(SalesInvoiceHeader."Amount Including VAT" * SalesInvoiceHeader."Payment Discount %" / 100);
        Amount := SalesInvoiceHeader."Amount Including VAT" - DiscountAmount;
    end;

    local procedure GetPmtTermDisc("Code": Code[10]): Decimal
    var
        PaymentTerms: Record "Payment Terms";
    begin
        PaymentTerms.Get(Code);
        exit(PaymentTerms."Discount %")
    end;

    local procedure GetPurchaseInvoiceHeaderAmt(var DiscountAmount: Decimal; PurchaseInvoiceNo: Code[20]) Amount: Decimal
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.Get(PurchaseInvoiceNo);
        PurchInvHeader.CalcFields("Amount Including VAT");
        DiscountAmount := Round(PurchInvHeader."Amount Including VAT" * PurchInvHeader."Payment Discount %" / 100);
        Amount := PurchInvHeader."Amount Including VAT" - DiscountAmount;
    end;

    local procedure GetCurrencyExchRateAmount(Amount: Decimal; CurrencyCode: Code[10]): Decimal
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        Amount := LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate());
        FindCurrencyExchangeRate(CurrencyExchangeRate, CurrencyCode);
        Amount := LibraryERM.ConvertCurrency(Amount, CurrencyExchangeRate."Relational Currency Code", '', WorkDate());
        exit(Amount);
    end;

    local procedure GetW1VATPct(): Decimal
    begin
        exit(25);
    end;

    local procedure ModifyGenJnlLine(var GenJournalLine: Record "Gen. Journal Line")
    var
        Amount: Variant;
    begin
        LibraryVariableStorage.Dequeue(Amount);  // Dequeue value from ApplyVendorPageHandler.
        GenJournalLine.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());
        GenJournalLine.Validate(Amount, Amount);
        GenJournalLine.Modify(true);
    end;

    local procedure ModifyExchangeRate(CurrencyCode: Code[10])
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        FindCurrencyExchangeRate(CurrencyExchangeRate, CurrencyCode);
        CurrencyExchangeRate.Validate("Relational Currency Code", CreateCurrency());
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure ModifySetup(var VATPostingSetup: Record "VAT Posting Setup"; AdjustforPaymentDisc: Boolean; UnrealizedVAT: Boolean) OldAdjustforPaymentDiscount: Boolean
    begin
        ModifyGeneralLedgerSetup(AdjustforPaymentDisc, UnrealizedVAT);
        OldAdjustforPaymentDiscount := UpdateVATPostingSetup(VATPostingSetup, true);
    end;

    local procedure ModifyGeneralLedgerSetup(AdjustForPaymentDisc: Boolean; UnrealizedVAT: Boolean)
    begin
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(AdjustForPaymentDisc);
        LibraryERM.SetUnrealizedVAT(UnrealizedVAT);
    end;

    local procedure ModifyVATPostingSetupUnrealizedType(var VATPostingSetup: Record "VAT Posting Setup"; NewUnrealizedVATType: Option) OldUnrealizedVATType: Integer
    begin
        OldUnrealizedVATType := VATPostingSetup."Unrealized VAT Type";
        VATPostingSetup.Validate("Unrealized VAT Type", NewUnrealizedVATType);
        VATPostingSetup.Modify(true);
    end;

    local procedure DeleteVATPostingSetup(VATBusPostingGroupCode: Code[20])
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.SetRange("VAT Bus. Posting Group", VATBusPostingGroupCode);
        VATPostingSetup.DeleteAll();
    end;

    local procedure SalesInvoiceWithPaymentDisc(var DocumentNo: Code[20]; CurrencyCode: Code[10]) PmtDiscAmount: Decimal
    var
        PostedDocumentNo: Code[20];
        SelltoCustomerNo: Code[20];
    begin
        // Setup: Create Sales Invoice and Post it.
        SelltoCustomerNo := CreateCustomer();
        PostedDocumentNo := CreateAndPostSalesInvoice(SelltoCustomerNo, CurrencyCode);

        // Exercise: Make a Payment entry from General Journal Line, Apply Payment on Invoice from Customer Ledger Entries.
        DocumentNo := CreatePostApplyCustGenJournalLine(PmtDiscAmount, SelltoCustomerNo, PostedDocumentNo, CurrencyCode);
    end;

    local procedure SetParameters(PaymentTerms: Record "Payment Terms"; DueDateCalculation: DateFormula; DiscountPct: Decimal)
    begin
        // Setting Parameters, Due Date Calculation and Discount %.
        PaymentTerms.Validate("Due Date Calculation", DueDateCalculation);
        PaymentTerms.Validate("Discount %", DiscountPct);
        PaymentTerms.Modify(true);
    end;

    local procedure SetAppliesToIDToCashRcptJnl(JournalBatchName: Code[10])
    var
        CashReceiptJournal: TestPage "Cash Receipt Journal";
    begin
        Commit();  // Commit is require for opening Cash Receipt Journal Page.
        CashReceiptJournal.OpenEdit();
        CashReceiptJournal.CurrentJnlBatchName.SetValue := JournalBatchName;
        CashReceiptJournal.FILTER.SetFilter("Document Type", JournalBatchName);
        CashReceiptJournal."Apply Entries".Invoke();
    end;

    local procedure SetAppliesToIDToPmtJnl(JournalBatchName: Code[10])
    var
        PurchaseJournal: TestPage "Purchase Journal";
    begin
        Commit();  // Commit is require for opening Cash Receipt Journal Page.
        PurchaseJournal.OpenEdit();
        PurchaseJournal.CurrentJnlBatchName.SetValue := JournalBatchName;
        PurchaseJournal.FILTER.SetFilter("Document Type", JournalBatchName);
        PurchaseJournal."Apply Entries".Invoke();
    end;

    local procedure UpdateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; AdjustforPaymentDiscount: Boolean) OldAdjustforPaymentDiscount: Boolean
    begin
        OldAdjustforPaymentDiscount := VATPostingSetup."Adjust for Payment Discount";
        VATPostingSetup.Validate("Adjust for Payment Discount", AdjustforPaymentDiscount);
        VATPostingSetup.Modify(true);
    end;

    local procedure VerifyPmtDiscDetailedCustLedgEntries(DocumentNo: Code[20]; PmtDiscAmount: Decimal; PmtDiscAmountVAT: Decimal)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        VerifyDetailedCustLedgerEntryAmount(
          DocumentNo, PmtDiscAmount - PmtDiscAmountVAT, DetailedCustLedgEntry."Entry Type"::"Payment Discount (VAT Excl.)");
        VerifyDetailedCustLedgerEntryAmount(
          DocumentNo, PmtDiscAmountVAT, DetailedCustLedgEntry."Entry Type"::"Payment Discount (VAT Adjustment)");
    end;

    local procedure VerifyPmtDiscDetailedVendLedgEntries(DocumentNo: Code[20]; PmtDiscAmount: Decimal; PmtDiscAmountVAT: Decimal)
    var
        DetailedVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        VerifyDetailedVendLedgerEntryAmount(
          DocumentNo, PmtDiscAmount - PmtDiscAmountVAT, DetailedVendLedgEntry."Entry Type"::"Payment Discount (VAT Excl.)");
        VerifyDetailedVendLedgerEntryAmount(
          DocumentNo, PmtDiscAmountVAT, DetailedVendLedgEntry."Entry Type"::"Payment Discount (VAT Adjustment)");
    end;

    local procedure VerifyDetailedCustLedgerEntryAmount(DocumentNo: Code[20]; AmountLCY: Decimal; EntryType: Enum "Detailed CV Ledger Entry Type")
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.SetRange("Entry Type", EntryType);
        DetailedCustLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedCustLedgEntry.FindFirst();
        Assert.AreNearlyEqual(
          AmountLCY, DetailedCustLedgEntry."Amount (LCY)", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountLCYErr, DetailedCustLedgEntry.FieldCaption("Entry No."), AmountLCY, DetailedCustLedgEntry.TableCaption));
    end;

    local procedure VerifyDetailedVendLedgerEntryAmount(DocumentNo: Code[20]; AmountLCY: Decimal; EntryType: Enum "Detailed CV Ledger Entry Type")
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DetailedVendorLedgEntry.SetRange("Entry Type", EntryType);
        DetailedVendorLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedVendorLedgEntry.FindFirst();
        Assert.AreNearlyEqual(
          AmountLCY, DetailedVendorLedgEntry."Amount (LCY)", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountLCYErr, DetailedVendorLedgEntry.FieldCaption("Entry No."), AmountLCY, DetailedVendorLedgEntry.TableCaption));
    end;

    local procedure VerifyGLEntries(GenJournalLine: Record "Gen. Journal Line"; DebitAmount: Decimal; CreditAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Bal. Account Type", GenJournalLine."Account Type");
        GLEntry.SetRange("Bal. Account No.", GenJournalLine."Account No.");
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(
          DebitAmount, GLEntry."Debit Amount", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountLCYErr, GLEntry.FieldCaption("Debit Amount"), GLEntry."Debit Amount", GLEntry.TableCaption()));
        Assert.AreNearlyEqual(
          CreditAmount, GLEntry."Credit Amount", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountLCYErr, GLEntry.FieldCaption("Credit Amount"), GLEntry."Credit Amount", GLEntry.TableCaption()))
    end;

    local procedure VerifyUnappliedDtldCustLedgEntry(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        FindDetailedCustLedgerEntry(DetailedCustLedgEntry, DocumentNo, DocumentType, DetailedCustLedgEntry."Entry Type"::Application);
        repeat
            Assert.IsTrue(
              DetailedCustLedgEntry.Unapplied,
              StrSubstNo(UnappliedErr, DetailedCustLedgEntry.TableCaption(), DetailedCustLedgEntry.FieldCaption(Unapplied)));
        until DetailedCustLedgEntry.Next() = 0;
    end;

    local procedure VerifyCustLedgerEntryForRemAmt(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        repeat
            CustLedgerEntry.CalcFields("Remaining Amount", Amount);
            CustLedgerEntry.TestField("Remaining Amount", CustLedgerEntry.Amount);
        until CustLedgerEntry.Next() = 0;
    end;

    local procedure VerifyPaymentTerms(PaymentTermsCode: Code[10]; DueDateCalculation: DateFormula; DiscountPct: Decimal)
    var
        PaymentTerms: Record "Payment Terms";
    begin
        PaymentTerms.Get(PaymentTermsCode);
        PaymentTerms.TestField("Due Date Calculation", DueDateCalculation);
        PaymentTerms.TestField("Discount %", DiscountPct);
    end;

    local procedure VerifyUnappliedDtldVendLedgEntry(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    var
        DetailedVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        FindDetailedVendLedgerEntry(DetailedVendLedgEntry, DocumentNo, DocumentType, DetailedVendLedgEntry."Entry Type"::Application);
        repeat
            Assert.IsTrue(
              DetailedVendLedgEntry.Unapplied, StrSubstNo(UnappliedErr, DetailedVendLedgEntry.TableCaption(), DetailedVendLedgEntry.Unapplied));
        until DetailedVendLedgEntry.Next() = 0;
    end;

    local procedure VerifyVendLedgerEntryForRemAmt(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    var
        VendLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendLedgerEntry, DocumentType, DocumentNo);
        repeat
            VendLedgerEntry.CalcFields("Remaining Amount", Amount);
            VendLedgerEntry.TestField("Remaining Amount", VendLedgerEntry.Amount);
        until VendLedgerEntry.Next() = 0;
    end;

    local procedure VerifyArrayValuesWithCityPostcode(Vendor: Record Vendor; CountryRegionName: Text[50]; AddrArray: array[8] of Text[100])
    begin
        Assert.AreEqual(AddrArray[1], Vendor."No.", StrSubstNo(ExpectedValueErr, Vendor."No."));
        Assert.AreEqual(AddrArray[2], StrSubstNo('%1, %2', Vendor.City, Vendor."Post Code"), StrSubstNo(ExpectedValueErr, Vendor.City));
        Assert.AreEqual(AddrArray[3], Vendor.County, StrSubstNo(ExpectedValueErr, Vendor.County));
        Assert.AreEqual(AddrArray[4], CountryRegionName, StrSubstNo(ExpectedValueErr, CountryRegionName));
    end;

    local procedure VerifyArrayValuesWithBlankLinePostCodeCity(Vendor: Record Vendor; AddrArray: array[8] of Text[100])
    begin
        Assert.AreEqual(AddrArray[1], Vendor."No.", StrSubstNo(ExpectedValueErr, Vendor."No."));
        Assert.AreEqual(AddrArray[2], '', StrSubstNo(ExpectedValueErr, Vendor.City));
        Assert.AreEqual(AddrArray[3], StrSubstNo('%1 %2', Vendor."Post Code", Vendor.City), StrSubstNo(ExpectedValueErr, Vendor.City));
        Assert.AreEqual(AddrArray[4], Vendor.County, StrSubstNo(ExpectedValueErr, Vendor.County));
    end;

    local procedure VerifyGLEntryGenPostingType(DocumentNo: Code[20]; GLAccountNo: Code[20]; IsPositiveAmount: Boolean; ExpectedGenPostingType: Enum "General Posting Type")
    var
        DummyGLEntry: Record "G/L Entry";
    begin
        DummyGLEntry.Init();
        DummyGLEntry.SetRange("Document No.", DocumentNo);
        DummyGLEntry.SetRange("G/L Account No.", GLAccountNo);
        if IsPositiveAmount then
            DummyGLEntry.SetFilter(Amount, '>%1', 0)
        else
            DummyGLEntry.SetFilter(Amount, '<%1', 0);
        DummyGLEntry.SetRange("Gen. Posting Type", ExpectedGenPostingType);
        Assert.RecordIsNotEmpty(DummyGLEntry);
    end;

    local procedure VerifyUnappliedVATEntry(DocumentNo: Code[20]; AccountNo: Code[20]; VATBase: Decimal; VATAmount: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange("Bill-to/Pay-to No.", AccountNo);

        VATEntry.FindFirst();
        Assert.AreNearlyEqual(VATBase, VATEntry.Base, LibraryERM.GetAmountRoundingPrecision(), VATEntry.FieldCaption(Base));
        Assert.AreNearlyEqual(VATAmount, VATEntry.Amount, LibraryERM.GetAmountRoundingPrecision(), VATEntry.FieldCaption(Amount));

        VATEntry.FindLast();
        Assert.AreNearlyEqual(VATBase, -VATEntry.Base, LibraryERM.GetAmountRoundingPrecision(), VATEntry.FieldCaption(Base));
        Assert.AreNearlyEqual(VATAmount, -VATEntry.Amount, LibraryERM.GetAmountRoundingPrecision(), VATEntry.FieldCaption(Amount));
    end;

    local procedure VerifyUnappliedGLEntriesSales(DocumentNo: Code[20]; SourceNo: Code[20]; VATGLAccountNo: Code[20]; GLAmount: Decimal; Qty: Integer)
    var
        SourceCodeSetup: Record "Source Code Setup";
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        SourceCodeSetup.Get();
        Customer.Get(SourceNo);
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        VerifyUnappliedGLEntries(
          DocumentNo, CustomerPostingGroup.GetReceivablesAccount(), VATGLAccountNo,
          SourceNo, SourceCodeSetup."Unapplied Sales Entry Appln.", GLAmount, 0, Qty, 0);
    end;

    local procedure VerifyUnappliedGLEntriesPurchase(DocumentNo: Code[20]; SourceNo: Code[20]; VATGLAccountNo: Code[20]; GLAmount: Decimal; VATAmount: Decimal; Qty: Integer; VATQty: Integer)
    var
        SourceCodeSetup: Record "Source Code Setup";
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        SourceCodeSetup.Get();
        Vendor.Get(SourceNo);
        VendorPostingGroup.Get(Vendor."Vendor Posting Group");
        VerifyUnappliedGLEntries(
          DocumentNo, VendorPostingGroup.GetPayablesAccount(), VATGLAccountNo,
          SourceNo, SourceCodeSetup."Unapplied Purch. Entry Appln.", GLAmount, VATAmount, Qty, VATQty);
    end;

    local procedure VerifyUnappliedGLEntries(DocumentNo: Code[20]; GLAccountNo: Code[20]; VATGLAccountNo: Code[20]; SourceNo: Code[20]; SourceCode: Code[20]; GLAmount: Decimal; VATAmount: Decimal; Qty: Integer; VATQty: Integer)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Source No.", SourceNo);
        GLEntry.SetRange("Source Code", SourceCode);
        Assert.RecordCount(GLEntry, Qty);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(GLAmount, GLEntry.Amount, LibraryERM.GetAmountRoundingPrecision(), GLEntry.FieldCaption(Amount));
        GLEntry.SetRange("G/L Account No.", VATGLAccountNo);
        Assert.RecordCount(GLEntry, VATQty);
        GLEntry.CalcSums(Amount);
        Assert.AreNearlyEqual(VATAmount, GLEntry.Amount, LibraryERM.GetAmountRoundingPrecision(), GLEntry.FieldCaption(Amount));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustEntryPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    var
        PmtDiscAmount: Variant;
    begin
        ApplyCustomerEntries."Set Applies-to ID".Invoke();
        LibraryVariableStorage.Dequeue(PmtDiscAmount);  // Dequeue variable.
        ApplyCustomerEntries.PmtDiscountAmount.AssertEquals(PmtDiscAmount);  // Verify Payment Discount Amount.
        LibraryVariableStorage.Enqueue(ApplyCustomerEntries.AppliedAmount.AsDecimal());  // Enqueue Applied Amount.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyVendorPageHandler(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    var
        PmtDiscAmount: Variant;
    begin
        ApplyVendorEntries.ActionSetAppliesToID.Invoke();
        LibraryVariableStorage.Dequeue(PmtDiscAmount);  // Dequeue variable.
        ApplyVendorEntries.PmtDiscountAmount.AssertEquals(PmtDiscAmount);  // Verify Payment Discount Amount.
        LibraryVariableStorage.Enqueue(ApplyVendorEntries.AppliedAmount.AsDecimal());  // Enqueue Applied Amount.
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure NothingAdjustedMessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(NothingToAdjustTxt, Message);
    end;
}

