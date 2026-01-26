codeunit 134022 "ERM Payment Tolerance"
{
    Permissions = TableData "Cust. Ledger Entry" = rimd,
                  TableData "Vendor Ledger Entry" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Payment Tolerance]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPmtDiscSetup: Codeunit "Library - Pmt Disc Setup";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryJournals: Codeunit "Library - Journals";
        isInitialized: Boolean;
        AmountErrorMessage: Label '%1 must be %2 in %3 %4 %5.';
        PostingAction: Option " ","Payment Tolerance Accounts","Remaining Amount";
        DetailedCustomerLedgerEntryMustExist: Label '%1 must exist in Detailed Customer Ledger Entries.';
        DetailedCustomerLedgerEntryMustNotExist: Label '%1 must not exist in Detailed Customer Ledger Entries.';
        DetailedVendorLedgerEntryMustNotExistErr: Label '%1 must not exist in Detailed Vendor Ledger Entries.';
        AmountVerificationMsg: Label 'Amount must be equal.';
        WrongAmountErr: Label '%1 field %2 value is wrong';
        InvalidCustomerVendorNameErr: Label 'Invalid customer/vendor name.';

    [Test]
    [Scope('OnPrem')]
    procedure RemainingAmtUsingApplication()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Partial Application using Vendor Ledger Entry and verify the same post application.

        // Setup: Setup Data for Apply Vendor Ledger Entries and using Random value for Amounts.
        Initialize();
        SelectGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor, CreateVendor(), -1 * LibraryRandom.RandDec(100, 2));
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Vendor, GenJournalLine."Account No.", -1 * GenJournalLine.Amount / 2);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise: Apply and Post Payment to Invoice from Vendor Ledger Entry.
        ApplyAndPostVendorEntry(GenJournalLine."Document No.", GenJournalLine.Amount);

        // Verify: Verify Vendor Ledger Entry.
        VerifyVendLedEntry(-GenJournalLine.Amount, GenJournalLine."Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RemainingAmtUsingAppliesToID()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Application using Applies to ID and verify vendor Ledger Entry post application.

        // Setup: Setup Data for Apply vendor Ledger Entries and using Random value for Amounts.
        Initialize();
        SelectGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor, CreateVendor(), -1 * LibraryRandom.RandDec(100, 2));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        InvoiceNo := GenJournalLine."Document No.";

        // Create General Journal Line for Payment.
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Vendor, GenJournalLine."Account No.", GenJournalLine.Amount / 2);

        // Exercise: Application of Payment Entry to Invoice using Applies to ID and Post General Journal Line.
        ApplyVendLedEntryAppliesToID(GenJournalLine, GenJournalLine.Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify Vendor Ledger Entry.
        VerifyVendLedEntry(-GenJournalLine.Amount, InvoiceNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RemainingAmtUsingAppliesToDoc()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Application using Applies to Document No. and verify vendor Ledger Entry post application.

        // Setup: Setup Data for Apply vendor Ledger Entries and using Random value for Amounts.
        Initialize();
        SelectGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor, CreateVendor(), -1 * LibraryRandom.RandDec(100, 2));
        InvoiceNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Vendor, GenJournalLine."Account No.", -1 * GenJournalLine.Amount / 2);

        // Exercise: Execute Application of Payment Entry to Invoice using Applies to Document No and Post General Journal Line..
        ApplyVendLedEntryAppliesToDoc(GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine.Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify Vendor Ledger Entry.
        VerifyVendLedEntry(-GenJournalLine.Amount, InvoiceNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ApplyCustEntryPageHandler,PaymentToleranceWarningHandler')]
    [Scope('OnPrem')]
    procedure CustApplyPaymentWithTolerance()
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
        GenJournalLine: Record "Gen. Journal Line";
        TolerancePct: Decimal;
        ToleranceAmount: Decimal;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Check GL Entry for Payment Tolerance Received after applying Payment with Payment Tolerance Warning.

        // Setup: Create Customer, Update General Ledger, Post Invoice and create Customer Payment.
        Initialize();
        LibraryVariableStorage.Enqueue(PostingAction::"Payment Tolerance Accounts");
        LibrarySales.CreateCustomer(Customer);
        TolerancePct := LibraryRandom.RandDec(100, 2);
        SetPmtTolerance(true, false, TolerancePct);
        LibraryPmtDiscSetup.SetPmtDiscToleranceWarning(false);
        ToleranceAmount :=
          CustomerInvoiceAndPayment(GenJournalLine, Customer."No.", LibraryERM.CreateGLAccountWithSalesSetup(), TolerancePct);

        // Exercise: Apply Payment with Invoice.
        ApplyFromGeneralJournal(GenJournalLine."Document Type", GenJournalLine."Account No.");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify Payment Tolerance received in GL Entry.
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        VerifyGLEntry(GenJournalLine."Document Type", GenJournalLine."Document No.",
          CustomerPostingGroup."Payment Tolerance Debit Acc.", -ToleranceAmount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ApplyCustEntryPageHandler,PaymentToleranceWarningHandler')]
    [Scope('OnPrem')]
    procedure CustUnapplyPmtWithTolerance()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustomerPostingGroup: Record "Customer Posting Group";
        GenJournalLine: Record "Gen. Journal Line";
        TolerancePct: Decimal;
        ToleranceAmount: Decimal;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Check GL Entry for Payment Tolerance Received after unapplying Payment.

        // Setup: Create Customer, Update General Ledger, Post Invoice and Apply Customer Payment.
        Initialize();
        LibraryVariableStorage.Enqueue(PostingAction::"Payment Tolerance Accounts");
        LibrarySales.CreateCustomer(Customer);
        TolerancePct := LibraryRandom.RandDec(100, 2);
        SetPmtTolerance(true, false, TolerancePct);
        LibraryPmtDiscSetup.SetPmtDiscToleranceWarning(false);
        ToleranceAmount :=
          CustomerInvoiceAndPayment(GenJournalLine, Customer."No.", LibraryERM.CreateGLAccountWithSalesSetup(), TolerancePct);
        ApplyFromGeneralJournal(GenJournalLine."Document Type", GenJournalLine."Account No.");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise: Unapply Customer Payment.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");
        LibraryERM.UnapplyCustomerLedgerEntry(CustLedgerEntry);

        // Verify: Verify Payment Tolerance Received in GL Entry.
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        VerifyGLEntry(GenJournalLine."Document Type"::" ", GenJournalLine."Document No.",
          CustomerPostingGroup."Payment Tolerance Debit Acc.", ToleranceAmount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ApplyCustomerEntryPageHandler,PaymentToleranceWarningHandler')]
    [Scope('OnPrem')]
    procedure SalesPaymentWarningCurrency()
    var
        SalesLine: Record "Sales Line";
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        CurrencyCode: Code[10];
        DocumentNo: Code[20];
        Amount: Decimal;
        AmountInclVAT: Decimal;
        TolerancePct: Decimal;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Check Payment Tolerance Warning With Amount LCY on Sales Payment.

        // Setup: Create and Post Sales Invoice with Updated Payment Tolerance Warning.
        Initialize();
        LibraryVariableStorage.Enqueue(PostingAction::" ");
        TolerancePct := LibraryRandom.RandDec(10, 2);
        SetPmtTolerance(true, false, TolerancePct);
        CurrencyCode := CreateCurrencyAndExchangeRate();
        DocumentNo := CreateAndPostSalesInvoice(SalesLine);
        Amount := CalcHalfToleranceAmount(SalesLine."Line Amount", TolerancePct, CurrencyCode);
        AmountInclVAT := CalcHalfToleranceAmount(SalesLine."Amount Including VAT", TolerancePct, CurrencyCode);

        // Exercise: Payment with Convert currency with Exchange Rate of Posted Invoice.
        CreateGenLineAndApplyEntry(
          GenJournalLine, SalesLine."Sell-to Customer No.", -AmountInclVAT, GenJournalLine."Account Type"::Customer, CurrencyCode);

        // Verify: Verify that amount in GLEntry is same as calulated amount for payment with currency code.
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(
          Amount, CalcHalfToleranceAmount(Abs(GLEntry.Amount), TolerancePct, CurrencyCode), LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(
            AmountErrorMessage, GLEntry.FieldCaption(Amount), Amount, GLEntry.TableCaption(), GLEntry.FieldCaption("Entry No."),
            GLEntry."Entry No."));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ApplyVendorEntryPageHandler,PaymentToleranceWarningHandler')]
    [Scope('OnPrem')]
    procedure PurchasePaymentWarningCurrency()
    var
        PurchaseLine: Record "Purchase Line";
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        CurrencyCode: Code[10];
        DocumentNo: Code[20];
        Amount: Decimal;
        AmountInclVAT: Decimal;
        TolerancePct: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Check Payment Tolerance Warning With Amount LCY on Purchase Payment.

        // Setup: Create and Post Purchase Invoice with Updated Payment Tolerance Warning.
        Initialize();
        LibraryVariableStorage.Enqueue(PostingAction::" ");
        TolerancePct := LibraryRandom.RandDec(10, 2);
        SetPmtTolerance(true, false, TolerancePct);
        CurrencyCode := CreateCurrencyAndExchangeRate();
        DocumentNo := CreateAndPostPurchaseInvoice(PurchaseLine);
        Amount := CalcHalfToleranceAmount(PurchaseLine."Line Amount", TolerancePct, CurrencyCode);
        AmountInclVAT := CalcHalfToleranceAmount(PurchaseLine."Amount Including VAT", TolerancePct, CurrencyCode);

        // Exercise: Payment with Convert currency with Exchange Rate of Posted Invoice.
        CreateGenLineAndApplyEntry(
          GenJournalLine, PurchaseLine."Buy-from Vendor No.", AmountInclVAT, GenJournalLine."Account Type"::Vendor, CurrencyCode);

        // Verify: Verify that amount in GLEntry is same as calulated amount for payment with currency code.
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(
          Amount, CalcHalfToleranceAmount(Abs(GLEntry.Amount), TolerancePct, CurrencyCode), LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(
            AmountErrorMessage, GLEntry.FieldCaption(Amount), Amount, GLEntry.TableCaption(), GLEntry.FieldCaption("Entry No."),
            GLEntry."Entry No."));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PaymentToleranceWarningHandler')]
    [Scope('OnPrem')]
    procedure LeavePaymentToleranceAsRemainingAmount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Leave as remaining amount option within payment tolerance warning.

        // Setup: Create setup for payment tolerance. Create and post General Journal Lines.
        Initialize();
        LibraryVariableStorage.Enqueue(PostingAction::"Remaining Amount");
        CreateAndPostGenJournalLinesForCustomerWithPaymentToleranceSetup(
          GenJournalLine, LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(100, 2));

        // Exercise: Apply and post Customer Entry.
        ApplyAndPostCustomerEntry(GenJournalLine."Document No.", GenJournalLine.Amount);

        // Verify: Detailed Customer Ledger Entry must not exist with Payment Tolerance.
        Assert.IsFalse(
          FindDetailedCustLedgEntry(GenJournalLine."Account No.", DetailedCustLedgEntry."Entry Type"::"Payment Tolerance"),
          StrSubstNo(DetailedCustomerLedgerEntryMustNotExist, Format(DetailedCustLedgEntry."Entry Type"::"Payment Tolerance")));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PaymentToleranceWarningHandler')]
    [Scope('OnPrem')]
    procedure PostPaymentToleranceBalance()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Post payment tolerance balance option within payment tolerance warning.

        // Setup: Create setup for payment tolerance. Create and post General Journal Lines.
        Initialize();
        LibraryVariableStorage.Enqueue(PostingAction::"Payment Tolerance Accounts");
        CreateAndPostGenJournalLinesForCustomerWithPaymentToleranceSetup(
          GenJournalLine, LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(100, 2));

        // Exercise: Apply and post Customer Entry.
        ApplyAndPostCustomerEntry(GenJournalLine."Document No.", GenJournalLine.Amount);

        // Verify: Detailed Customer Ledger Entry must exist with Payment Tolerance.
        Assert.IsTrue(
          FindDetailedCustLedgEntry(GenJournalLine."Account No.", DetailedCustLedgEntry."Entry Type"::"Payment Tolerance"),
          StrSubstNo(DetailedCustomerLedgerEntryMustExist, Format(DetailedCustLedgEntry."Entry Type"::"Payment Tolerance")));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PaymentDiscToleranceWarningHandler')]
    [Scope('OnPrem')]
    procedure DoNotAcceptLastPaymentDiscount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Do not accept late payment discount option within payment discount warning.

        // Setup: Create setup for payment tolerance. Create and post General Journal Lines.
        Initialize();
        LibraryVariableStorage.Enqueue(PostingAction::"Remaining Amount");
        LibraryPmtDiscSetup.SetPmtDiscGracePeriodByText('<' + Format(LibraryRandom.RandInt(5)) + 'D>');
        CreateAndPostGenJournalLinesWithPaymentDiscountToleranceSetup(GenJournalLine);

        // Exercise: Apply and post Customer Entry.
        ApplyAndPostCustomerEntry(GenJournalLine."Document No.", GenJournalLine.Amount);

        // Verify: Detailed Customer Ledger Entry must not exist with Payment Discount Tolerance.
        Assert.IsFalse(
          FindDetailedCustLedgEntry(GenJournalLine."Account No.", DetailedCustLedgEntry."Entry Type"::"Payment Discount Tolerance"),
          StrSubstNo(DetailedCustomerLedgerEntryMustNotExist, Format(DetailedCustLedgEntry."Entry Type"::"Payment Discount Tolerance")));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PaymentDiscToleranceWarningHandler')]
    [Scope('OnPrem')]
    procedure PostPaymentDiscountBalance()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Post payment discount balance option within payment discount warning.

        // Setup: Create setup for payment tolerance. Create and post General Journal Lines.
        Initialize();
        LibraryVariableStorage.Enqueue(PostingAction::"Payment Tolerance Accounts");
        LibraryPmtDiscSetup.SetPmtDiscGracePeriodByText('<' + Format(LibraryRandom.RandInt(5)) + 'D>');
        CreateAndPostGenJournalLinesWithPaymentDiscountToleranceSetup(GenJournalLine);

        // Exercise: Apply and post Customer Entry.
        ApplyAndPostCustomerEntry(GenJournalLine."Document No.", GenJournalLine.Amount);

        // Verify: Detailed Customer Ledger Entry must not exist with Payment Discount Tolerance.
        Assert.IsTrue(
          FindDetailedCustLedgEntry(GenJournalLine."Account No.", DetailedCustLedgEntry."Entry Type"::"Payment Discount Tolerance"),
          StrSubstNo(DetailedCustomerLedgerEntryMustExist, Format(DetailedCustLedgEntry."Entry Type"::"Payment Discount Tolerance")));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ApplyCustomerEntryPageHandler,PaymentToleranceWarningHandler')]
    [Scope('OnPrem')]
    procedure SalesPaymentAppliedWithToleranceAmount()
    var
        SalesLine: Record "Sales Line";
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyCode: Code[10];
        TolerancePct: Decimal;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Check No Remaining Amount is left in Payment when Payment Tolerance Amount is adjusted.

        // Setup: Create and Post Sales Invoice with Updated Payment Tolerance Warning.
        Initialize();

        LibraryVariableStorage.Enqueue(PostingAction::"Payment Tolerance Accounts");
        TolerancePct := 2 * LibraryRandom.RandInt(10);
        SetPmtTolerance(true, false, TolerancePct);

        CreateCurrencyAndUpdateCurrencyExchangeRate(CurrencyCode);
        CreateAndPostSalesInvoice(SalesLine);

        // Exercise: Payment with Convert currency with Exchange Rate of Posted Invoice.
        CreateGenLineAndApplyEntry(
          GenJournalLine, SalesLine."Sell-to Customer No.",
          -CalcHalfToleranceAmount(SalesLine."Amount Including VAT", TolerancePct, CurrencyCode),
          GenJournalLine."Account Type"::Customer, CurrencyCode);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify that Payment is completely applied and no Remaining Amount is left.
        VerifyCustomerPaymentRemainingAmountIsZero(GenJournalLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler')]
    [Scope('OnPrem')]
    procedure PostFullPaymentAmountSalesNoWarning()
    var
        PaymentTerms: Record "Payment Terms";
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 312699] Entries are closed when Payment is applied to Sales Invoice with the same amount within Payment Discount Grace Period
        Initialize();

        // [GIVEN] Payment Discount Grace Period = 10D, Payment Terms with Discount % = 5
        SetPmtTolerance(false, false, 0);
        LibraryPmtDiscSetup.SetPmtDiscGracePeriodByText('<' + Format(LibraryRandom.RandInt(5)) + 'D>');
        CreatePaymentTerms(PaymentTerms);

        // [GIVEN] Sales Invoice is posted with Amount = 1000 on 01-01-2020, Payment Discount Possible = 50
        // [GIVEN] Pmt. Discount Date = 05-01-20, Pmt. Disc. Tolerance Date = 15-01-2020
        CreateAndPostInvoiceOfGenJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Customer, CreateCustomerWithPmtTerms(PaymentTerms.Code), '',
          LibraryRandom.RandDecInRange(1000, 2000, 2));

        // [WHEN] Payment with Amount = -1000 is posted on 11-01-2020 and applied to the invoice
        CreatePostPaymentWithAppliesToDoc(
          GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
          GenJournalLine."Account Type"::Customer, GenJournalLine."Document No.",
          CalcDate(Format(PaymentTerms."Discount Date Calculation"), WorkDate()),
          GenJournalLine.Amount);

        // [THEN] Both entries are closed
        // [THEN] No detailed entry with "Payment Discount Tolerance" type
        FindCustLedgEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, GenJournalLine."Account No.");
        CustLedgerEntry.TestField(Open, false);
        FindCustLedgEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, GenJournalLine."Account No.");
        CustLedgerEntry.TestField(Open, false);
        Assert.IsFalse(
          FindDetailedCustLedgEntry(GenJournalLine."Account No.", DetailedCustLedgEntry."Entry Type"::"Payment Discount Tolerance"),
          StrSubstNo(DetailedCustomerLedgerEntryMustNotExist, Format(DetailedCustLedgEntry."Entry Type"::"Payment Discount Tolerance")));
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler')]
    [Scope('OnPrem')]
    procedure PostLatePaymentDiscountSalesNoWarning()
    var
        PaymentTerms: Record "Payment Terms";
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 312699] Entries are closed when Payment is applied to Sales Invoice with amount reduced by Payment Discount amount within Payment Discount Grace Period
        Initialize();

        // [GIVEN] Payment Discount Grace Period = 10D, Payment Terms with Discount % = 5
        SetPmtTolerance(false, false, 0);
        LibraryPmtDiscSetup.SetPmtDiscGracePeriodByText('<' + Format(LibraryRandom.RandInt(5)) + 'D>');
        CreatePaymentTerms(PaymentTerms);

        // [GIVEN] Sales Invoice is posted with Amount = 1000 on 01-01-2020, Payment Discount Possible = 50
        // [GIVEN] Pmt. Discount Date = 05-01-20, Pmt. Disc. Tolerance Date = 15-01-2020
        CreateAndPostInvoiceOfGenJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Customer, CreateCustomerWithPmtTerms(PaymentTerms.Code), '',
          LibraryRandom.RandDecInRange(1000, 2000, 2));

        // [WHEN] Payment with Amount = -950 is posted on 11-01-2020 and applied to the invoice
        CreatePostPaymentWithAppliesToDoc(
          GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
          GenJournalLine."Account Type"::Customer, GenJournalLine."Document No.",
          CalcDate(Format(PaymentTerms."Discount Date Calculation"), WorkDate()),
          Round(GenJournalLine.Amount * (1 - PaymentTerms."Discount %" / 100)));

        // [THEN] Both entries are closed
        // [THEN] Detailed entry with "Payment Discount Tolerance" type is created
        FindCustLedgEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, GenJournalLine."Account No.");
        CustLedgerEntry.TestField(Open, false);
        FindCustLedgEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, GenJournalLine."Account No.");
        CustLedgerEntry.TestField(Open, false);
        Assert.IsTrue(
          FindDetailedCustLedgEntry(GenJournalLine."Account No.", DetailedCustLedgEntry."Entry Type"::"Payment Discount Tolerance"),
          StrSubstNo(DetailedCustomerLedgerEntryMustExist, Format(DetailedCustLedgEntry."Entry Type"::"Payment Discount Tolerance")));
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler')]
    [Scope('OnPrem')]
    procedure PostFullPaymentAmountPurchaseNoWarning()
    var
        PaymentTerms: Record "Payment Terms";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 312699] Entries are closed when Payment is applied to Purchase Invoice with the same amount within Payment Discount Grace Period
        Initialize();

        // [GIVEN] Payment Discount Grace Period = 10D, Payment Terms with Discount % = 5
        SetPmtTolerance(false, false, 0);
        LibraryPmtDiscSetup.SetPmtDiscGracePeriodByText('<' + Format(LibraryRandom.RandInt(5)) + 'D>');
        CreatePaymentTerms(PaymentTerms);

        // [GIVEN] Purchase Invoice is posted with Amount = -1000 on 01-01-2020, Payment Discount Possible = 50
        // [GIVEN] Pmt. Discount Date = 05-01-20, Pmt. Disc. Tolerance Date = 15-01-2020
        CreateAndPostInvoiceOfGenJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, CreateVendorWithPmtTerms(PaymentTerms.Code), '',
          -LibraryRandom.RandDecInRange(1000, 2000, 2));

        // [WHEN] Payment with Amount = 1000 is posted on 11-01-2020 and applied to the invoice
        CreatePostPaymentWithAppliesToDoc(
          GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
          GenJournalLine."Account Type"::Vendor, GenJournalLine."Document No.",
          CalcDate(Format(PaymentTerms."Discount Date Calculation"), WorkDate()),
          GenJournalLine.Amount);

        // [THEN] Both entries are closed
        // [THEN] No detailed entry with "Payment Discount Tolerance" type
        FindVendLedgEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, GenJournalLine."Account No.");
        VendorLedgerEntry.TestField(Open, false);
        FindVendLedgEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Payment, GenJournalLine."Account No.");
        VendorLedgerEntry.TestField(Open, false);
        Assert.IsFalse(
          FindDetailedVendorLedgEntry(GenJournalLine."Account No.", DetailedVendorLedgEntry."Entry Type"::"Payment Discount Tolerance"),
          StrSubstNo(DetailedVendorLedgerEntryMustNotExistErr, Format(DetailedVendorLedgEntry."Entry Type"::"Payment Discount Tolerance")));
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler')]
    [Scope('OnPrem')]
    procedure PostLatePaymentDiscountPurchaseNoWarning()
    var
        PaymentTerms: Record "Payment Terms";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 312699] Entries are closed when Payment is applied to Purchase Invoice with amount reduced by Payment Discount amount within Payment Discount Grace Period
        Initialize();

        // [GIVEN] Payment Discount Grace Period = 10D, Payment Terms with Discount % = 5
        SetPmtTolerance(false, false, 0);
        LibraryPmtDiscSetup.SetPmtDiscGracePeriodByText('<' + Format(LibraryRandom.RandInt(5)) + 'D>');
        CreatePaymentTerms(PaymentTerms);

        // [GIVEN] Purchase Invoice is posted with Amount = -1000 on 01-01-2020, Payment Discount Possible = 50
        // [GIVEN] Pmt. Discount Date = 05-01-20, Pmt. Disc. Tolerance Date = 15-01-2020
        CreateAndPostInvoiceOfGenJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, CreateVendorWithPmtTerms(PaymentTerms.Code), '',
          -LibraryRandom.RandDecInRange(1000, 2000, 2));

        // [WHEN] Payment with Amount = 950 is posted on 11-01-2020 and applied to the invoice
        CreatePostPaymentWithAppliesToDoc(
          GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
          GenJournalLine."Account Type"::Vendor, GenJournalLine."Document No.",
          CalcDate(Format(PaymentTerms."Discount Date Calculation"), WorkDate()),
          Round(GenJournalLine.Amount * (1 - PaymentTerms."Discount %" / 100)));

        // [THEN] Both entries are closed
        // [THEN] Detailed entry with "Payment Discount Tolerance" type is created
        FindVendLedgEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, GenJournalLine."Account No.");
        VendorLedgerEntry.TestField(Open, false);
        FindVendLedgEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Payment, GenJournalLine."Account No.");
        VendorLedgerEntry.TestField(Open, false);
        Assert.IsTrue(
          FindDetailedVendorLedgEntry(GenJournalLine."Account No.", DetailedVendorLedgEntry."Entry Type"::"Payment Discount Tolerance"),
          StrSubstNo(DetailedCustomerLedgerEntryMustExist, Format(DetailedVendorLedgEntry."Entry Type"::"Payment Discount Tolerance")));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ApplyVendorEntryPageHandler,PaymentToleranceWarningHandler')]
    [Scope('OnPrem')]
    procedure PurchasePaymentAppliedWithToleranceAmount()
    var
        PurchaseLine: Record "Purchase Line";
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyCode: Code[10];
        TolerancePct: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Check No Remaining Amount is left in Payment when Payment Tolerance Amount is adjusted.

        // Setup: Create and Post Purchase Invoice with Updated Payment Tolerance Warning.
        Initialize();
        LibraryVariableStorage.Enqueue(PostingAction::"Payment Tolerance Accounts");
        TolerancePct := 2 * LibraryRandom.RandInt(10);
        SetPmtTolerance(true, false, TolerancePct);

        CreateCurrencyAndUpdateCurrencyExchangeRate(CurrencyCode);
        CreateAndPostPurchaseInvoice(PurchaseLine);

        // Exercise: Payment with Convert currency with Exchange Rate of Posted Invoice.
        CreateGenLineAndApplyEntry(
          GenJournalLine, PurchaseLine."Buy-from Vendor No.",
          CalcHalfToleranceAmount(PurchaseLine."Amount Including VAT", TolerancePct, CurrencyCode),
          GenJournalLine."Account Type"::Vendor, CurrencyCode);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify that Payment is completely applied and no Remaining Amount is left.
        VerifyVendorPaymentRemainingAmountIsZero(GenJournalLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ApplyCustomerEntryPageHandlerForMultipleDocument,PostApplicationHandler')]
    [Scope('OnPrem')]
    procedure ApplySalesCreditMemoWithTwoRefundsAndExchRateAdjmt()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Index: Integer;
        AdjustmentFactor: Decimal;
        GenJournalLineAmount: Decimal;
        CurrencyCode: Code[10];
        CustomerNoToApply: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Check No Remaining Amount is left when a Credit Memo with Currency Code is applied to two refunds.

        // Setup: Update Pmt. Discount Grace Period in General Ledger Setup. Create a Customer with Payment term code having Calc. Discount on Credit Memo.
        // Create Currency with its currency exchange rate.
        Initialize();
        GenJournalLineAmount := 10 * LibraryRandom.RandDec(1000, 2);
        LibraryPmtDiscSetup.SetPmtDiscGracePeriodByText('<' + Format(LibraryRandom.RandInt(5)) + 'D>');
        CustomerNoToApply := CreateCustomerWithPmtTerms(CreatePaymentTermsWithDiscOnCreditMemo());  // CustomerNoToApply is used in report handler
        CurrencyCode := CreateCurrencyWithGainLossAccount();
        AdjustmentFactor := CreateAndUpdateCurrencyExchangeRate(CurrencyCode);

        // Exercise: Create and Post One Credit Memo with currency and two refunds. Apply it through Customer Ledger Entries. Run Adjust Currency Exchange Rate
        // Batch job.
        CreateGenJournalLineWithCurrencyCode(
          GenJournalLine, CustomerNoToApply, CurrencyCode, GenJournalLine."Document Type"::"Credit Memo",
          -GenJournalLineAmount, WorkDate(), GenJournalLine."Account Type"::Customer);
        PostGeneralJnlLine(GenJournalLine);
        for Index := 1 to 2 do begin
            CreateGenJournalLineWithCurrencyCode(
              GenJournalLine, CustomerNoToApply, '', GenJournalLine."Document Type"::Refund,
              (GenJournalLineAmount * AdjustmentFactor) / 2, CalcDate('<1D>', WorkDate()), GenJournalLine."Account Type"::Customer);
            PostGeneralJnlLine(GenJournalLine);
        end;
        LibraryERM.RunExchRateAdjustmentSimple(CurrencyCode, WorkDate(), WorkDate());
        LibraryVariableStorage.Enqueue(CustomerNoToApply);
        ApplyCustomerLedgerEntries(CustomerNoToApply, GenJournalLine."Document Type"::"Credit Memo");

        // Verify : Verify that no remaing amount is left in Refund and Credit Memo.
        VerifyRefundAndCreditMemoRemainingAmountIsZero(CustomerNoToApply);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ApplyVendorEntryPageHandlerForMultipleDocument,PostApplicationHandler')]
    [Scope('OnPrem')]
    procedure ApplyPurchInvoiceWithTwoPaymentsExchRateAdjmt()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Index: Integer;
        AdjustmentFactor: Decimal;
        GenJournalLineAmount: Decimal;
        CurrencyCode: Code[10];
        VendorNoToApply: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Check No Remaining Amount is left when a Invoice with Currency Code is applied to two payments.

        // Setup: Update Pmt. Discount Grace Period in General Ledger Setup. Create a Vendor with payment terms code.
        // Create Currency with its currency exchange rate.
        Initialize();
        GenJournalLineAmount := 10 * LibraryRandom.RandDec(1000, 2);
        LibraryPmtDiscSetup.SetPmtDiscGracePeriodByText('<' + Format(LibraryRandom.RandInt(5)) + 'D>');
        VendorNoToApply := CreateVendorWithPmtTerms(CreatePaymentTermsWithDiscOnCreditMemo());
        CurrencyCode := CreateCurrencyWithGainLossAccount();
        AdjustmentFactor := CreateAndUpdateCurrencyExchangeRate(CurrencyCode);

        // Exercise: Create and Post One Invoice currency and two Payments. Apply it through Vendor Ledger Entries. Run Adjust Currency Exchange Rate
        // Batch job.

        CreateGenJournalLineWithCurrencyCode(
          GenJournalLine, VendorNoToApply, CurrencyCode, GenJournalLine."Document Type"::Invoice,
          -GenJournalLineAmount, WorkDate(), GenJournalLine."Account Type"::Vendor);
        PostGeneralJnlLine(GenJournalLine);

        for Index := 1 to 2 do begin
            CreateGenJournalLineWithCurrencyCode(
              GenJournalLine, VendorNoToApply, '', GenJournalLine."Document Type"::Payment,
              (GenJournalLineAmount * AdjustmentFactor) / 2, CalcDate('<1D>', WorkDate()), GenJournalLine."Account Type"::Vendor);
            PostGeneralJnlLine(GenJournalLine);
        end;
        LibraryERM.RunExchRateAdjustmentSimple(CurrencyCode, WorkDate(), WorkDate());
        LibraryVariableStorage.Enqueue(VendorNoToApply);
        ApplyVendorLedgerEntries(VendorNoToApply, GenJournalLine."Document Type"::Invoice);

        // Verify : Verify that no remaing amount is left in Invoice and Payments.
        VerifyInvoiceAndPaymentsRemainingAmountIsZero(VendorNoToApply);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntriesOnPostedPurchaseInvoice()
    var
        PurchaseLine: Record "Purchase Line";
        GeneralPostingSetup: Record "General Posting Setup";
        PostedPurchaseInvoiceNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Test the G/L entries after Posting of Purchase Invoice.

        // Setup: Create setup for Payment Tolerance.
        Initialize();
        LibraryPmtDiscSetup.SetPmtTolerance(0);

        // Excercise: Create and Post Purchase Invoice.
        PostedPurchaseInvoiceNo := CreateAndPostPurchaseInvoice(PurchaseLine);

        // Verify: G/L Entries.
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        VerifyGLEntry(
          PurchaseLine."Document Type", PostedPurchaseInvoiceNo, GeneralPostingSetup."Purch. Account", PurchaseLine."Line Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntriesOnPostedPurchaseCreditMemo()
    var
        PurchaseLine: Record "Purchase Line";
        GeneralPostingSetup: Record "General Posting Setup";
        PostedPurchaseInvoiceNo: Code[20];
        PostedPurchaseCreditMemoNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Test the G/L entries after Posting of Purchase Credit Memo.

        // Setup: Create setup for Payment Tolerance. Create and post Purchase Invoice.
        Initialize();
        LibraryPmtDiscSetup.SetPmtTolerance(0);
        PostedPurchaseInvoiceNo := CreateAndPostPurchaseInvoice(PurchaseLine);

        // Excercise: Create and post Purchase Credit Memo by copy Document functionality.
        PostedPurchaseCreditMemoNo := CreateAndPostPurchaseCreditMemo(PurchaseLine, PostedPurchaseInvoiceNo);

        // Verify: G/L Entries.
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        VerifyGLEntry(
          PurchaseLine."Document Type", PostedPurchaseCreditMemoNo, GeneralPostingSetup."Purch. Credit Memo Account",
          -1 * PurchaseLine."Line Amount");
    end;

    [Test]
    [HandlerFunctions('PaymentToleranceWarningNoHandler')]
    [Scope('OnPrem')]
    procedure GLEntriesOnPostRefundJournalAppliedEntries()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseLine: Record "Purchase Line";
        VendorPostingGroup: Record "Vendor Posting Group";
        Vendor: Record Vendor;
        PostedPurchaseInvoiceNo: Code[20];
        PostedCreditMemoNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Test the G/L entries after Posting of Payment Journal.

        // Setup: Create setup for Payment Tolerance. Create and post Purchase Invoice and Credit Memo.
        Initialize();
        LibraryPmtDiscSetup.SetPmtTolerance(0);
        PostedPurchaseInvoiceNo := CreateAndPostPurchaseInvoice(PurchaseLine);
        PostedCreditMemoNo := CreateAndPostPurchaseCreditMemo(PurchaseLine, PostedPurchaseInvoiceNo);

        // Excercise: Create and Post Payment Journal by applying above posted Credit Memo.
        CreateRefundJournalLineAppliesToCrMemo(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, PurchaseLine."Buy-from Vendor No.", PostedCreditMemoNo,
          -CalcPurchPaymentAmount(PostedCreditMemoNo));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: G/L Entries.
        Vendor.Get(PurchaseLine."Buy-from Vendor No.");
        VendorPostingGroup.Get(Vendor."Vendor Posting Group");
        VerifyGLEntry(
          GenJournalLine."Document Type", GenJournalLine."Document No.", VendorPostingGroup."Payables Account",
          GenJournalLine."Amount (LCY)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntriesOnPostedSalesInvoice()
    var
        SalesLine: Record "Sales Line";
        GeneralPostingSetup: Record "General Posting Setup";
        PostedSalesInvoiceNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Test the G/L entries after Posting of Sales Invoice.

        // Setup: Create setup for Payment Tolerance.
        Initialize();
        LibraryPmtDiscSetup.SetPmtTolerance(0);

        // Excercise: Post Sales Invoice.
        PostedSalesInvoiceNo := CreateAndPostSalesInvoice(SalesLine);

        // Verify: G/L Entries.
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        VerifyGLEntry(SalesLine."Document Type", PostedSalesInvoiceNo, GeneralPostingSetup."Sales Account", -1 * SalesLine."Line Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntriesOnPostedSalesCreditMemo()
    var
        SalesLine: Record "Sales Line";
        GeneralPostingSetup: Record "General Posting Setup";
        PostedSalesInvoiceNo: Code[20];
        PostedSalesCreditMemoNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Test the G/L entries after Posting of Sales Credit Memo created by Copy Document.

        // Setup: Create setup for Payment Tolerance. Create and post Sales Invoice.
        Initialize();
        LibraryPmtDiscSetup.SetPmtTolerance(0);
        PostedSalesInvoiceNo := CreateAndPostSalesInvoice(SalesLine);

        // Excercise: Create and post Sales Credit Memo by copy Document functionality.
        PostedSalesCreditMemoNo := CreateAndPostSalesCreditMemo(SalesLine, PostedSalesInvoiceNo);

        // Verify: G/L Entries.
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        VerifyGLEntry(
          SalesLine."Document Type", PostedSalesCreditMemoNo, GeneralPostingSetup."Sales Credit Memo Account", SalesLine."Line Amount");
    end;

    [Test]
    [HandlerFunctions('PaymentToleranceWarningNoHandler')]
    [Scope('OnPrem')]
    procedure GLEntriesOnPostCashReceiptAppliedEntries()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
        PostedCreditMemoNo: Code[20];
        PostedSalesInvoiceNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Test the G/L entries after Posting of Cash Receipt Journal.

        // Setup: Create setup for Payment Tolerance. Create and post Sales Invoice and Credit Memo.
        Initialize();
        LibraryPmtDiscSetup.SetPmtTolerance(0);
        PostedSalesInvoiceNo := CreateAndPostSalesInvoice(SalesLine);
        PostedCreditMemoNo := CreateAndPostSalesCreditMemo(SalesLine, PostedSalesInvoiceNo);

        // Excercise: Create and Post Cash Receipt Journal by applying above posted Credit Memo.
        CreateRefundJournalLineAppliesToCrMemo(
          GenJournalLine, GenJournalLine."Account Type"::Customer, SalesLine."Sell-to Customer No.", PostedCreditMemoNo,
          -CalcSalesPaymentAmount(PostedCreditMemoNo));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: G/L Entries.
        Customer.Get(SalesLine."Sell-to Customer No.");
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        VerifyGLEntry(
          GenJournalLine."Document Type", GenJournalLine."Document No.", CustomerPostingGroup."Receivables Account",
          GenJournalLine."Amount (LCY)");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PaymentDiscToleranceWarningHandler')]
    [Scope('OnPrem')]
    procedure CheckPaymentToleranceWarningAfterUpdateApplyToDocNoForCustomer()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        ApplyToDocNo: Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Check Payment Tolerance Warning After Update ApplyToDocNo For Customer

        // Setup: Create and post an invoice of General Journal.
        Amount := CreateAndPostInvoiceOfGenJournalLineForCustomer(GenJournalLine, PaymentTerms);
        ApplyToDocNo := GenJournalLine."Document No.";

        // Create Payment and Apply to the Invoice.
        CreatePaymentOfGenJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Customer, GenJournalLine."Account No.",
          GenJournalLine."Bal. Account Type"::"G/L Account", GenJournalLine."Bal. Account No.",
          -Amount, CalcDate(PaymentTerms."Discount Date Calculation", WorkDate()), '');

        // Update Applies-to Doc. No. And calls the Payment Discount Tolerance Warning.
        GenJournalLine.Validate("Applies-to Doc. No.", ApplyToDocNo);
        GenJournalLine.Modify(true);

        // Verify the payment can be posted successfully and the Amount on G/L Entry.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        VerifyGLEntry(
          GenJournalLine."Document Type", GenJournalLine."Document No.", GenJournalLine."Bal. Account No.", Amount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CheckNoPaymentToleranceWarningAfterSetApplToDocNoWhenZeroAmountForCustomer()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        AppliesToDocNo: Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 269739] Payment Discount Tolerance Warning is not shown when Stan sets "Applies-to Doc. No." for Customer when Amount of Gen. Journal Line is 0.
        Initialize();

        // [GIVEN] Posted Sales Invoice "SI1" with Amount = "A1".
        Amount := CreateAndPostInvoiceOfGenJournalLineForCustomer(GenJournalLine, PaymentTerms);
        AppliesToDocNo := GenJournalLine."Document No.";

        // [GIVEN] Set empty "Account No." and zero Amount for General Journal Line.
        CreatePaymentOfGenJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Customer, '', "Gen. Journal Account Type"::"G/L Account", '',
          0, CalcDate(PaymentTerms."Discount Date Calculation", WorkDate()), '');

        // [WHEN] Set "Applies-to Doc. No." = "SI1".
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.Modify(true);

        // [THEN] Payment Discount Tolerance Warning is not shown, Amount updates to "A1".
        GenJournalLine.TestField("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.TestField(Amount, -Amount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PaymentDiscToleranceWarningHandler')]
    [Scope('OnPrem')]
    procedure CheckPaymentToleranceWarningAfterSetApplToDocNoWhenNonZeroAmountForCustomer()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        AppliesToDocNo: Code[20];
        AppliesToDocAmount: Decimal;
        Amount: Decimal;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 269739] Payment Discount Tolerance Warning is shown when Stan sets "Applies-to Doc. No." for Customer when Amount of Gen. Journal Line is nonzero.
        Initialize();

        // [GIVEN] Posted Sales Invoice "SI1" with Amount = "A1".
        AppliesToDocAmount := CreateAndPostInvoiceOfGenJournalLineForCustomer(GenJournalLine, PaymentTerms);
        AppliesToDocNo := GenJournalLine."Document No.";

        // [GIVEN] Set empty "Account No." and nonzero Amount for General Journal Line.
        // [GIVEN] Difference between Amount and "A1" is greater than Payment Tolerance (1-2%) and less than "Discount %" for Customer (3-10%).
        Amount := Round(AppliesToDocAmount * 0.975, 0.01);
        CreatePaymentOfGenJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Customer, GenJournalLine."Account No.", "Gen. Journal Account Type"::"G/L Account", '',
          -Amount, CalcDate(PaymentTerms."Discount Date Calculation", WorkDate()), '');

        // [WHEN] Set "Applies-to Doc. No." = "SI1".
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.Modify(true);

        // [THEN] Payment Discount Tolerance Warning is shown, Amount is not changed.
        GenJournalLine.TestField("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.TestField(Amount, -Amount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PaymentDiscToleranceWarningHandler')]
    [Scope('OnPrem')]
    procedure CheckPaymentToleranceWarningAfterUpdateAmountWhenApplToDocNoSetForCustomer()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        GeneralJournal: TestPage "General Journal";
        Amount: Decimal;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Check Payment Tolerance Warning After Update Amount When ApplToDocNo Set ForCustomer

        // Setup: Create and post an invoice of General Journal.
        Amount := CreateAndPostInvoiceOfGenJournalLineForCustomer(GenJournalLine, PaymentTerms);

        // Create Payment and Apply to the Invoice.
        CreatePaymentOfGenJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Customer, GenJournalLine."Account No.",
          GenJournalLine."Bal. Account Type"::"G/L Account", GenJournalLine."Bal. Account No.",
          0, CalcDate(PaymentTerms."Discount Date Calculation", WorkDate()), GenJournalLine."Document No.");

        // Update Amount. And calls the Payment Discount Tolerance Warning.
        GeneralJournal.OpenEdit();
        GeneralJournal.Amount.SetValue(-Amount);
        GeneralJournal.Next();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify the payment can be posted successfully and the Amount on G/L Entry.
        VerifyGLEntry(
          GenJournalLine."Document Type", GenJournalLine."Document No.", GenJournalLine."Bal. Account No.", Amount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PaymentDiscToleranceWarningHandler')]
    [Scope('OnPrem')]
    procedure CheckPaymentToleranceWarningAfterUpdateAmountWhenApplToIDSetForCustomer()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        GeneralJournal: TestPage "General Journal";
        PostedDocNo: Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 269739] Payment Discount Tolerance Warning is shown when Stan updates Amount from zero when "Applies-to ID" is set.
        Initialize();

        // [GIVEN] Posted Sales Invoice "SI1" with Amount = "A1".
        Amount := CreateAndPostInvoiceOfGenJournalLineForCustomer(GenJournalLine, PaymentTerms);
        PostedDocNo := GenJournalLine."Document No.";

        // [GIVEN] Apply "SI1" to General Journal Line using "Applies-to ID". Amount is set to zero.
        CreatePaymentOfGenJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Customer, GenJournalLine."Account No.",
          "Gen. Journal Account Type"::"G/L Account", '', 0, CalcDate(PaymentTerms."Discount Date Calculation", WorkDate()), '');
        SetCustLedgerEntryAppliesToID(
          GenJournalLine."Account No.", GenJournalLine."Document Type"::Invoice, PostedDocNo,
          GenJournalLine."Document No.", Amount);
        GenJournalLine.Validate("Applies-to ID", GenJournalLine."Document No.");
        GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::Payment);
        GenJournalLine.Modify(true);

        // [WHEN] Update Amount to "A1".
        GeneralJournal.OpenEdit();
        GeneralJournal.Amount.SetValue(-Amount);
        GeneralJournal.Next();

        // [THEN] Payment Discount Tolerance Warning is shown, Amount is changed to "A1".
        GenJournalLine.Find();
        GenJournalLine.TestField("Applies-to ID", GenJournalLine."Document No.");
        GenJournalLine.TestField(Amount, -Amount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PaymentDiscToleranceWarningHandler')]
    [Scope('OnPrem')]
    procedure CheckPaymentToleranceWarningAfterUpdateCustomerNoForCustomer()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        CustomerNo: Code[20];
        InvoiceNo: Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Check Payment Tolerance Warning After Update CustomerNo For Customer

        // Setup: Create and post an invoice of General Journal.
        Amount := CreateAndPostInvoiceOfGenJournalLineForCustomer(GenJournalLine, PaymentTerms);
        CustomerNo := GenJournalLine."Account No.";
        InvoiceNo := GenJournalLine."Document No.";

        // Create Payment and Apply to the Invoice.
        CreatePaymentOfGenJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Customer, CreateCustomerWithPmtTerms(PaymentTerms.Code),
          GenJournalLine."Bal. Account Type"::"G/L Account", GenJournalLine."Bal. Account No.", -Amount,
          CalcDate(PaymentTerms."Discount Date Calculation", WorkDate()), InvoiceNo);

        // Update Customer No. Post the payment.
        GenJournalLine.Validate("Account No.", CustomerNo);
        GenJournalLine.Validate("Applies-to Doc. No.", InvoiceNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify the payment can be posted successfully and the Amount on G/L Entry.
        VerifyGLEntry(
          GenJournalLine."Document Type", GenJournalLine."Document No.", GenJournalLine."Bal. Account No.", Amount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PaymentDiscToleranceWarningHandler')]
    [Scope('OnPrem')]
    procedure CheckPaymentToleranceWarningAfterUpdatePostingDateForCustomer()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        Amount: Decimal;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Check Payment Tolerance Warning After Update Posting Date For Customer

        // Setup: Create and post an invoice of General Journal.
        Amount := CreateAndPostInvoiceOfGenJournalLineForCustomer(GenJournalLine, PaymentTerms);

        // Create Payment and Apply to the Invoice.
        CreatePaymentOfGenJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Customer, GenJournalLine."Account No.",
          GenJournalLine."Bal. Account Type"::"G/L Account", GenJournalLine."Bal. Account No.",
          -Amount, WorkDate(), GenJournalLine."Document No.");

        // Update Posting Date Post the payment.
        GenJournalLine.Validate("Posting Date", CalcDate('<1D>', CalcDate(PaymentTerms."Discount Date Calculation", WorkDate())));
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify the posted payment and the Amount on G/L Entry.
        VerifyGLEntry(
          GenJournalLine."Document Type", GenJournalLine."Document No.", GenJournalLine."Bal. Account No.", Amount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PaymentDiscToleranceWarningHandler')]
    [Scope('OnPrem')]
    procedure CheckPaymentToleranceWarningAfterUpdateBalAccNoForCustomer()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        CustomerNo: Code[20];
        InvoiceNo: Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Check Payment Tolerance Warning After Update BalAccNo For Customer

        // Setup: Create and post an invoice of General Journal.
        Amount := CreateAndPostInvoiceOfGenJournalLineForCustomer(GenJournalLine, PaymentTerms);
        CustomerNo := GenJournalLine."Account No.";
        InvoiceNo := GenJournalLine."Document No.";

        // Create Payment and Apply to the Invoice.
        CreatePaymentOfGenJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::"G/L Account", GenJournalLine."Bal. Account No.",
          GenJournalLine."Bal. Account Type"::Customer, CreateCustomerWithPmtTerms(PaymentTerms.Code),
          Amount, CalcDate(PaymentTerms."Discount Date Calculation", WorkDate()), InvoiceNo);

        // Update Bal. Account No. Post the payment.
        GenJournalLine.Validate("Bal. Account No.", CustomerNo);
        GenJournalLine.Validate("Applies-to Doc. No.", InvoiceNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify the payment can be posted successfully and the Amount on G/L Entry.
        VerifyGLEntry(
          GenJournalLine."Document Type", GenJournalLine."Document No.", GenJournalLine."Account No.", Amount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PaymentDiscToleranceWarningHandler')]
    [Scope('OnPrem')]
    procedure CheckPaymentToleranceWarningAfterUpdateApplyToDocNoForVendor()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        ApplyToDocNo: Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Check Payment Tolerance Warning After Update ApplyToDocNo For Vendor

        // Setup: Create and post an invoice of General Journal.
        Amount := CreateAndPostInvoiceOfGenJournalLineForVendor(GenJournalLine, PaymentTerms);
        ApplyToDocNo := GenJournalLine."Document No.";

        // Create Payment and Apply to the Invoice.
        CreatePaymentOfGenJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, GenJournalLine."Account No.",
          GenJournalLine."Bal. Account Type"::"G/L Account", GenJournalLine."Bal. Account No.",
          Amount, CalcDate(PaymentTerms."Discount Date Calculation", WorkDate()), '');

        // Update Applies-to Doc. No. Post the payment.
        GenJournalLine.Validate("Applies-to Doc. No.", ApplyToDocNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify the payment can be posted successfully and the Amount on G/L Entry.
        VerifyGLEntry(
          GenJournalLine."Document Type", GenJournalLine."Document No.", GenJournalLine."Bal. Account No.", -Amount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CheckNoPaymentToleranceWarningAfterSetApplToDocNoWhenZeroAmountForVendor()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        AppliesToDocNo: Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 269739] Payment Discount Tolerance Warning is not shown when Stan sets "Applies-to Doc. No." for Vendor when Amount of Gen. Journal Line is 0.
        Initialize();

        // [GIVEN] Posted Purchase Invoice "PI1" with Amount = "A1".
        Amount := CreateAndPostInvoiceOfGenJournalLineForVendor(GenJournalLine, PaymentTerms);
        AppliesToDocNo := GenJournalLine."Document No.";

        // [GIVEN] Set empty "Account No." and zero Amount for General Journal Line.
        CreatePaymentOfGenJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, '', "Gen. Journal Account Type"::"G/L Account", '',
          0, CalcDate(PaymentTerms."Discount Date Calculation", WorkDate()), '');

        // [WHEN] Set "Applies-to Doc. No." = "PI1".
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.Modify(true);

        // [THEN] Payment Discount Tolerance Warning is not shown, Amount updates to "A1".
        GenJournalLine.TestField("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.TestField(Amount, Amount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PaymentDiscToleranceWarningHandler')]
    [Scope('OnPrem')]
    procedure CheckPaymentToleranceWarningAfterSetApplToDocNoWhenNonZeroAmountForVendor()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        AppliesToDocNo: Code[20];
        AppliesToDocAmount: Decimal;
        Amount: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 269739] Payment Discount Tolerance Warning is shown when Stan sets "Applies-to Doc. No." for Vendor when Amount of Gen. Journal Line is nonzero.
        Initialize();

        // [GIVEN] Posted Purchase Invoice "PI1" with Amount = "A1"..
        AppliesToDocAmount := CreateAndPostInvoiceOfGenJournalLineForVendor(GenJournalLine, PaymentTerms);
        AppliesToDocNo := GenJournalLine."Document No.";

        // [GIVEN] Set empty "Account No." and nonzero Amount for General Journal Line.
        // [GIVEN] Difference between Amount and "A1" is greater than Payment Tolerance (1-2%) and less than "Discount %" for Vendor (3-10%).
        Amount := Round(AppliesToDocAmount * 0.975, 0.01);
        CreatePaymentOfGenJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, GenJournalLine."Account No.", "Gen. Journal Account Type"::"G/L Account", '',
          Amount, CalcDate(PaymentTerms."Discount Date Calculation", WorkDate()), '');

        // [WHEN] Set "Applies-to Doc. No." = "SI1".
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.Modify(true);

        // [THEN] Payment Discount Tolerance Warning is shown, Amount is not changed.
        GenJournalLine.TestField("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.TestField(Amount, Amount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PaymentDiscToleranceWarningHandler')]
    [Scope('OnPrem')]
    procedure CheckPaymentToleranceWarningAfterUpdateAmountWhenApplToDocNoSetForVendor()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        GeneralJournal: TestPage "General Journal";
        Amount: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Check Payment Tolerance Warning After Update Amount When ApplToDocNo Set For Vendor

        // Setup: Create and post an invoice of General Journal.
        Amount := CreateAndPostInvoiceOfGenJournalLineForVendor(GenJournalLine, PaymentTerms);

        // Create Payment and Apply to the Invoice.
        CreatePaymentOfGenJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, GenJournalLine."Account No.",
          GenJournalLine."Bal. Account Type"::"G/L Account", GenJournalLine."Bal. Account No.", 0,
          CalcDate(PaymentTerms."Discount Date Calculation", WorkDate()), GenJournalLine."Document No.");

        // Update Amount. Post the payment.
        GeneralJournal.OpenEdit();
        GeneralJournal.Amount.SetValue(Amount);
        GeneralJournal.Next();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify the payment can be posted successfully and the Amount on G/L Entry.
        VerifyGLEntry(
          GenJournalLine."Document Type", GenJournalLine."Document No.", GenJournalLine."Bal. Account No.", -Amount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PaymentDiscToleranceWarningHandler')]
    [Scope('OnPrem')]
    procedure CheckPaymentToleranceWarningAfterUpdateAmountWhenApplToIDSetForVendor()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        GeneralJournal: TestPage "General Journal";
        PostedDocNo: Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 269739] Payment Discount Tolerance Warning is shown when Stan updates Amount from zero when "Applies-to ID" is set for Vendor.
        Initialize();

        // [GIVEN] Posted Purchase Invoice "PI1" with Amount = "A1".
        Amount := CreateAndPostInvoiceOfGenJournalLineForVendor(GenJournalLine, PaymentTerms);
        PostedDocNo := GenJournalLine."Document No.";

        // [GIVEN] Apply "PI1" to General Journal Line using "Applies-to ID". Amount is set to zero.
        CreatePaymentOfGenJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, GenJournalLine."Account No.",
          "Gen. Journal Account Type"::"G/L Account", '', 0, CalcDate(PaymentTerms."Discount Date Calculation", WorkDate()), '');
        SetVendLedgerEntryAppliesToID(
          GenJournalLine."Account No.", GenJournalLine."Document Type"::Invoice, PostedDocNo,
          GenJournalLine."Document No.", -Amount);
        GenJournalLine.Validate("Applies-to ID", GenJournalLine."Document No.");
        GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::Payment);
        GenJournalLine.Modify(true);

        // [WHEN] Update Amount to "A1".
        GeneralJournal.OpenEdit();
        GeneralJournal.Amount.SetValue(Amount);
        GeneralJournal.Next();

        // [THEN] Payment Discount Tolerance Warning is shown, Amount is changed to "A1".
        GenJournalLine.Find();
        GenJournalLine.TestField("Applies-to ID", GenJournalLine."Document No.");
        GenJournalLine.TestField(Amount, Amount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PaymentDiscToleranceWarningHandler')]
    [Scope('OnPrem')]
    procedure CheckPaymentToleranceWarningAfterUpdateVendorNoForVendor()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        Vendor: Record Vendor;
        InvoiceNo: Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Check Payment Tolerance Warning After Update VendorNo For Vendor

        // Setup: Create and post an invoice of General Journal.
        Amount := CreateAndPostInvoiceOfGenJournalLineForVendor(GenJournalLine, PaymentTerms);
        Vendor.Get(GenJournalLine."Account No.");
        InvoiceNo := GenJournalLine."Document No.";

        // Create Payment and Apply to the Invoice.
        CreatePaymentOfGenJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Vendor,
          CreateVendorWithPmtTerms(PaymentTerms.Code),
          GenJournalLine."Bal. Account Type"::"G/L Account", GenJournalLine."Bal. Account No.", Amount,
          CalcDate(PaymentTerms."Discount Date Calculation", WorkDate()), InvoiceNo);

        // Update Vendor No. Post the payment.
        GenJournalLine.Validate("Account No.", Vendor."No.");
        GenJournalLine.Validate("Applies-to Doc. No.", InvoiceNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify the payment can be posted successfully and the Amount on G/L Entry.
        VerifyGLEntry(
          GenJournalLine."Document Type", GenJournalLine."Document No.", GenJournalLine."Bal. Account No.", -Amount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PaymentDiscToleranceWarningHandler')]
    [Scope('OnPrem')]
    procedure CheckPaymentToleranceWarningAfterUpdatePostingDateForVendor()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        Amount: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Check Payment Tolerance Warning After Update Posting Date For Vendor

        // Setup: Create and post an invoice of General Journal.
        Amount := CreateAndPostInvoiceOfGenJournalLineForVendor(GenJournalLine, PaymentTerms);

        // Create Payment and Apply to the Invoice.
        CreatePaymentOfGenJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, GenJournalLine."Account No.",
          GenJournalLine."Bal. Account Type"::"G/L Account", GenJournalLine."Bal. Account No.",
          Amount, WorkDate(), GenJournalLine."Document No.");

        // Update Posting Date. Post the payment.
        GenJournalLine.Validate("Posting Date", CalcDate('<1D>', CalcDate(PaymentTerms."Discount Date Calculation", WorkDate())));
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify the payment can be posted successfully and the Amount on G/L Entry.
        VerifyGLEntry(
          GenJournalLine."Document Type", GenJournalLine."Document No.", GenJournalLine."Bal. Account No.", -Amount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PaymentDiscToleranceWarningHandler')]
    [Scope('OnPrem')]
    procedure CheckPaymentToleranceWarningAfterUpdateBalAccNoForVendor()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        Vendor: Record Vendor;
        InvoiceNo: Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Check Payment Tolerance Warning After Update BalAccNo For Vendor

        // Setup: Create and post an invoice of General Journal.
        Amount := CreateAndPostInvoiceOfGenJournalLineForVendor(GenJournalLine, PaymentTerms);
        Vendor.Get(GenJournalLine."Account No.");
        InvoiceNo := GenJournalLine."Document No.";

        // Create Payment and Apply to the Invoice.
        CreatePaymentOfGenJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::"G/L Account", GenJournalLine."Bal. Account No.",
          GenJournalLine."Bal. Account Type"::Vendor, CreateVendorWithPmtTerms(PaymentTerms.Code), -Amount,
          CalcDate(PaymentTerms."Discount Date Calculation", WorkDate()), InvoiceNo);

        // Update Bal. Account No. Post the payment.
        GenJournalLine.Validate("Bal. Account No.", Vendor."No.");
        GenJournalLine.Validate("Applies-to Doc. No.", InvoiceNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify the payment can be posted successfully and the Amount on G/L Entry.
        VerifyGLEntry(
          GenJournalLine."Document Type", GenJournalLine."Document No.", GenJournalLine."Account No.", -Amount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ApplyCustomerEntriesPageHandlerSelectLastDocument')]
    [Scope('OnPrem')]
    procedure NoPaymentToleranceWarningOnZeroAmountPaymentApplication()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        Amount: Decimal;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 360872] Payment Discount Tolerance Warning absence if Journal Line Amount is Zero and applied through Applies-to Doc No. lookup
        Initialize();
        // [GIVEN] Posted Invoice
        Amount := CreateAndPostInvoiceOfGenJournalLineForCustomer(GenJournalLine, PaymentTerms);
        // [GIVEN] Cash Receipt Journal Line with zero amount, Posting Date in Payment Tolerance period
        CreateCashReceiptJournalLine(
          GenJournalLine, GenJournalLine."Account No.",
          CalcDate('<1D>', CalcDate(PaymentTerms."Discount Date Calculation", WorkDate())));
        // [WHEN] User Applies payment to Invoice via Applies-to Doc. No. lookup field
        ApplyAndPostPaymentToSalesDoc(GenJournalLine);
        GenJournalLine.Find();
        // [THEN] No Payment Tolerance warning message appears, Amount value is equal to Sales Invoice Amount
        Assert.AreEqual(
          -Amount, GenJournalLine.Amount,
          StrSubstNo(WrongAmountErr, GenJournalLine.TableCaption(), GenJournalLine.FieldCaption(Amount)));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SetAppliesToIDAndCheckBalanceOnCustEntriesHandler')]
    [Scope('OnPrem')]
    procedure SalesBalanceOnPaymentAppliedToInvoiceWithPmtDiscAndPartialToleranceUsed()
    var
        PaymentTerms: Record "Payment Terms";
        GenJnlLine: Record "Gen. Journal Line";
        CustNo: Code[20];
        InvoiceAmount: Decimal;
        PmtAmount: Decimal;
        ExpectedBalance: Decimal;
        TolerancePct: Decimal;
    begin
        // [FEATURE] [Payment Discount] [Sales]
        // [SCENARIO 372197] Payment Discount should be used for Balance calculation on "Apply Customer Entries" page after "Set Applies-to ID" when using partial Payment Tolerance

        Initialize();
        // [GIVEN] "Payment Tolerance %" = "X1"
        TolerancePct := LibraryRandom.RandDec(100, 2);
        SetPmtTolerance(true, false, TolerancePct);
        LibraryPmtDiscSetup.SetPmtDiscToleranceWarning(false);
        // [GIVEN] Customer with "Pmt Discount %" = "X2"
        CreatePaymentTerms(PaymentTerms);
        CustNo := CreateCustomerWithPmtTerms(PaymentTerms.Code);
        // [GIVEN] Posted Invoice with Amount = "A" and "Pmt Disc. Amount" = "A" * "X2" / 100
        // [GIVEN] Posted Payment with Amount "B" = "A" * ("X2" + "X1" / 2) / 100
        CalcInvPmtAmountWithPartialDiscount(InvoiceAmount, PmtAmount, ExpectedBalance, 1, PaymentTerms."Discount %", TolerancePct);

        PostInvAndPmtGeneralJnlLines(GenJnlLine."Account Type"::Customer, CustNo, InvoiceAmount, PmtAmount);

        LibraryVariableStorage.Enqueue(CustNo);
        LibraryVariableStorage.Enqueue(ExpectedBalance);

        // [WHEN] Select Payment Document and Set Applies-to ID to Invoice on "Apply Customer Entries" page
        ApplyCustomerLedgerEntries(CustNo, GenJnlLine."Document Type"::Payment);

        // [THEN] Balance on "Apply Customer Entries" page = "A" - "B" - "Pmt. Disc. Amount"
        // Verification done in handler SetAppliesToIDAndCheckBalanceOnCustEntriesHandler
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SetAppliesToIDAndCheckBalanceOnVendEntriesHandler')]
    [Scope('OnPrem')]
    procedure PurchBalanceOnPaymentAppliedToInvoiceWithPmtDiscAndPartialToleranceUsed()
    var
        PaymentTerms: Record "Payment Terms";
        GenJnlLine: Record "Gen. Journal Line";
        VendNo: Code[20];
        InvoiceAmount: Decimal;
        PmtAmount: Decimal;
        ExpectedBalance: Decimal;
        TolerancePct: Decimal;
    begin
        // [FEATURE] [Payment Discount] [Purchase]
        // [SCENARIO 372197] Payment Discount should be used for Balance calculation on "Apply Vendor Entries" page after "Set Applies-to ID" when using partial Payment Tolerance

        Initialize();
        // [GIVEN] "Payment Tolerance %" = "X1"
        TolerancePct := LibraryRandom.RandDec(100, 2);
        SetPmtTolerance(true, false, TolerancePct);
        LibraryPmtDiscSetup.SetPmtDiscToleranceWarning(false);
        // [GIVEN] Vendor with "Pmt Discount %" = "X2"
        CreatePaymentTerms(PaymentTerms);
        VendNo := CreateVendorWithPmtTerms(PaymentTerms.Code);
        // [GIVEN] Posted Invoice with Amount = "A" and "Pmt Disc. Amount" = "A" * "X2" / 100
        // [GIVEN] Posted Payment with Amount "B" = "A" * ("X2" + "X1" / 2) / 100
        CalcInvPmtAmountWithPartialDiscount(InvoiceAmount, PmtAmount, ExpectedBalance, -1, PaymentTerms."Discount %", TolerancePct);
        PostInvAndPmtGeneralJnlLines(GenJnlLine."Account Type"::Vendor, VendNo, InvoiceAmount, PmtAmount);

        LibraryVariableStorage.Enqueue(VendNo);
        LibraryVariableStorage.Enqueue(ExpectedBalance);

        // [WHEN] Select Payment Document and Set Applies-to ID to Invoice on "Apply Vendor Entries" page
        ApplyVendorLedgerEntries(VendNo, GenJnlLine."Document Type"::Payment);

        // [THEN] Balance on "Apply Vendor Entries" page = "A" - "B" - "Pmt. Disc. Amount"
        // Verification done in handler SetAppliesToIDAndCheckBalanceOnVendEntriesHandler
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PaymentToleranceWarningHandler')]
    [Scope('OnPrem')]
    procedure ApplnRoundingPrecisionDoesNotConsiderWhenApplySalesLCYEntriesWithPmtDiscount()
    var
        GLSetup: Record "General Ledger Setup";
        PaymentTerms: Record "Payment Terms";
        GenJnlLine: Record "Gen. Journal Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
        CustNo: Code[20];
        InvoiceAmount: Decimal;
        PmtAmount: Decimal;
        ExpectedBalance: Decimal;
        TolerancePct: Decimal;
    begin
        // [FEATURE] [Sales] [Appln. Rounding Precision] [Payment Discount]
        // [SCENARIO 372197] Application Rounding Precision should not consider when apply Customer Ledger Entries with LCY and Payment Discount

        Initialize();
        // [GIVEN] "Payment Tolerance Warning" = Yes
        GLSetup.Get();
        TolerancePct := LibraryRandom.RandDec(100, 2);
        SetPmtTolerance(true, false, TolerancePct);
        LibraryPmtDiscSetup.SetPmtDiscToleranceWarning(false);

        // [GIVEN] Customer with "Pmt Discount %" = 5
        CreatePaymentTerms(PaymentTerms);
        CustNo := CreateCustomerWithPmtTerms(PaymentTerms.Code);
        // [GIVEN] Posted Invoice with Amount = 100 and "Pmt Disc. Amount" = 5
        // [GIVEN] Posted Payment with Amount = 92.5
        CalcInvPmtAmountWithPartialDiscount(
          InvoiceAmount, PmtAmount, ExpectedBalance, 1, PaymentTerms."Discount %", TolerancePct);
        // [GIVEN] "Appln. Rounding Precision" = 100 - 92.5 - 5 = 2.5
        SetApplnRoundingPrecision(Round(Abs(ExpectedBalance), 1, '>'));
        PostInvAndPmtGeneralJnlLines(GenJnlLine."Account Type"::Customer, CustNo, InvoiceAmount, PmtAmount);
        FindCustLedgEntry(CustLedgEntry, CustLedgEntry."Document Type"::Payment, CustNo);
        CustLedgEntry.CalcFields(Amount);
        LibraryVariableStorage.Enqueue(PostingAction::"Remaining Amount");

        // [WHEN] Apply Payment to Invoice
        ApplyAndPostCustomerEntry(CustLedgEntry."Document No.", CustLedgEntry.Amount);

        // [THEN] Payment applied fully and "Remaining Amount" = 0
        CustLedgEntry.CalcFields("Remaining Amount");
        CustLedgEntry.TestField("Remaining Amount", 0);

        // [THEN] Invoice applied and "Remaining Amount" = 100 - 92.5 = 7.5
        FindCustLedgEntry(CustLedgEntry, CustLedgEntry."Document Type"::Invoice, CustNo);
        CustLedgEntry.CalcFields("Remaining Amount");
        CustLedgEntry.TestField("Remaining Amount", InvoiceAmount + PmtAmount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PaymentToleranceWarningHandler')]
    [Scope('OnPrem')]
    procedure ApplnRoundingPrecisionDoesNotConsiderWhenApplyPurchLCYEntriesWithPmtDiscount()
    var
        GLSetup: Record "General Ledger Setup";
        PaymentTerms: Record "Payment Terms";
        GenJnlLine: Record "Gen. Journal Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
        VendNo: Code[20];
        InvoiceAmount: Decimal;
        PmtAmount: Decimal;
        ExpectedBalance: Decimal;
        TolerancePct: Decimal;
    begin
        // [FEATURE] [Purchase] [Appln. Rounding Precision] [Payment Discount]
        // [SCENARIO 372197] Application Rounding Precision should not consider when apply Vendor Ledger Entries with LCY and Payment Discount

        Initialize();
        // [GIVEN] "Payment Tolerance Warning" = Yes
        GLSetup.Get();
        TolerancePct := LibraryRandom.RandDec(100, 2);
        SetPmtTolerance(true, false, TolerancePct);
        LibraryPmtDiscSetup.SetPmtDiscToleranceWarning(false);

        // [GIVEN] Vendor with "Pmt Discount %" = 5
        CreatePaymentTerms(PaymentTerms);
        VendNo := CreateVendorWithPmtTerms(PaymentTerms.Code);
        // [GIVEN] Posted Invoice with Amount = 100 and "Pmt Disc. Amount" = 5
        // [GIVEN] Posted Payment with Amount = 92.5
        CalcInvPmtAmountWithPartialDiscount(
          InvoiceAmount, PmtAmount, ExpectedBalance, -1, PaymentTerms."Discount %", TolerancePct);
        // [GIVEN] "Appln. Rounding Precision" = 100 - 92.5 - 5 = 2.5
        SetApplnRoundingPrecision(Round(Abs(ExpectedBalance), 1, '>'));
        PostInvAndPmtGeneralJnlLines(GenJnlLine."Account Type"::Vendor, VendNo, InvoiceAmount, PmtAmount);
        FindVendLedgEntry(VendLedgEntry, VendLedgEntry."Document Type"::Payment, VendNo);
        VendLedgEntry.CalcFields(Amount);
        LibraryVariableStorage.Enqueue(PostingAction::"Remaining Amount");

        // [WHEN] Apply Payment to Invoice
        ApplyAndPostVendorEntry(VendLedgEntry."Document No.", VendLedgEntry.Amount);

        // [THEN] Payment applied fully and "Remaining Amount" = 0
        VendLedgEntry.CalcFields("Remaining Amount");
        VendLedgEntry.TestField("Remaining Amount", 0);

        // [THEN] Invoice applied and "Remaining Amount" = 100 - 92.5 = 7.5
        FindVendLedgEntry(VendLedgEntry, VendLedgEntry."Document Type"::Invoice, VendNo);
        VendLedgEntry.CalcFields("Remaining Amount");
        VendLedgEntry.TestField("Remaining Amount", InvoiceAmount + PmtAmount);
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesHandler,GenJnlTemplateHandler')]
    [Scope('OnPrem')]
    procedure ZeroSalesBalanceOnPaymentAppliedToInvWithPmtDiscAndCrMemo()
    var
        GeneralJournal: TestPage "General Journal";
        PmtDiscAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Payment Discount]
        // [SCENARIO 378399] Balance on "Apply Customer Entries" page is zero when apply payment to both invoice with Payment Discount and simple Credit Memo

        // [GIVEN] Invoice with "Amount" = 100, "Pmt Discount Possible" = 2
        // [GIVEN] Credit Memo with "Amount" = 20
        // [GIVEN] Payment with "Amount" = 78 (100 - 20 - 2)
        CreatePostSalesInvoiceCrMemoAndOpenPmtJournal(GeneralJournal, PmtDiscAmount, 0);

        // [WHEN] Open "Apply Entries" for Payment and apply to both Invoice and Credit Memo
        GeneralJournal."Apply Entries".Invoke();

        // [THEN] There are following "Apply Customer Entries" page subtotals:
        // [THEN] "Balance" = 0
        // [THEN] "Pmt. Disc. Amount" = -2
        VerifyBalanceAndPmtDiscEnqueuedFromHandler(0, -PmtDiscAmount);
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesHandler,GenJnlTemplateHandler')]
    [Scope('OnPrem')]
    procedure PositiveSalesBalanceOnPaymentAppliedToInvWithPmtDiscAndCrMemo()
    var
        GeneralJournal: TestPage "General Journal";
        PmtDiscAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Payment Discount]
        // [SCENARIO 213795] Positive balance on "Apply Customer Entries" page when apply payment to both invoice with Payment Discount and simple Credit Memo

        // [GIVEN] Invoice with "Amount" = 100, "Pmt Discount Possible" = 2
        // [GIVEN] Credit Memo with "Amount" = 20
        // [GIVEN] Payment with "Amount" = 77.99 (100 - 20 - 2 - 0.01)
        CreatePostSalesInvoiceCrMemoAndOpenPmtJournal(GeneralJournal, PmtDiscAmount, -LibraryERM.GetAmountRoundingPrecision());

        // [WHEN] Open "Apply Entries" for Payment and apply to both Invoice and Credit Memo
        GeneralJournal."Apply Entries".Invoke();

        // [THEN] There are following "Apply Customer Entries" page subtotals:
        // [THEN] "Balance" = 20.01
        // [THEN] "Pmt. Disc. Amount" = 0
        VerifyBalanceAndPmtDiscEnqueuedFromHandler(PmtDiscAmount + LibraryERM.GetAmountRoundingPrecision(), 0);
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesHandler,GenJnlTemplateHandler')]
    [Scope('OnPrem')]
    procedure NegativeSalesBalanceOnPaymentAppliedToInvWithPmtDiscAndCrMemo()
    var
        GeneralJournal: TestPage "General Journal";
        PmtDiscAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Payment Discount]
        // [SCENARIO 213795] Negative balance on "Apply Customer Entries" page when apply payment to both invoice with Payment Discount and simple Credit Memo

        // [GIVEN] Invoice with "Amount" = 100, "Pmt Discount Possible" = 2
        // [GIVEN] Credit Memo with "Amount" = 20
        // [GIVEN] Payment with "Amount" = 78.01 (100 - 20 - 2 + 0.01)
        CreatePostSalesInvoiceCrMemoAndOpenPmtJournal(GeneralJournal, PmtDiscAmount, LibraryERM.GetAmountRoundingPrecision());

        // [WHEN] Open "Apply Entries" for Payment and apply to both Invoice and Credit Memo
        GeneralJournal."Apply Entries".Invoke();

        // [THEN] There are following "Apply Customer Entries" page subtotals:
        // [THEN] "Balance" = -0.01
        // [THEN] "Pmt. Disc. Amount" = -2
        VerifyBalanceAndPmtDiscEnqueuedFromHandler(-LibraryERM.GetAmountRoundingPrecision(), -PmtDiscAmount);
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesHandler,GenJnlTemplateHandler')]
    [Scope('OnPrem')]
    procedure ZeroPurchBalanceOnPaymentAppliedToInvWithPmtDiscAndCrMemo()
    var
        GeneralJournal: TestPage "General Journal";
        PmtDiscAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Payment Discount]
        // [SCENARIO 378399] Balance on "Apply Vendor Entries" page is zero when apply payment to both invoice with Payment Discount and simple Credit Memo

        // [GIVEN] Invoice with "Amount" = 100, "Pmt Discount Possible" = 2
        // [GIVEN] Credit Memo with "Amount" = 20
        // [GIVEN] Payment with "Amount" = 78 (100 - 20 - 2)
        CreatePostPurchaseInvoiceCrMemoAndOpenPmtJournal(GeneralJournal, PmtDiscAmount, 0);

        // [WHEN] Open "Apply Entries" for Payment and apply to both Invoice and Credit Memo
        GeneralJournal."Apply Entries".Invoke();

        // [THEN] There are following "Apply Vendor Entries" page subtotals:
        // [THEN] "Balance" = 0
        // [THEN] "Pmt. Disc. Amount" = 2
        VerifyBalanceAndPmtDiscEnqueuedFromHandler(0, PmtDiscAmount);
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesHandler,GenJnlTemplateHandler')]
    [Scope('OnPrem')]
    procedure PositivePurchBalanceOnPaymentAppliedToInvWithPmtDiscAndCrMemo()
    var
        GeneralJournal: TestPage "General Journal";
        PmtDiscAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Payment Discount]
        // [SCENARIO 213795] Positive balance on "Apply Vendor Entries" page when apply payment to both invoice with Payment Discount and simple Credit Memo

        // [GIVEN] Invoice with "Amount" = 100, "Pmt Discount Possible" = 2
        // [GIVEN] Credit Memo with "Amount" = 20
        // [GIVEN] Payment with "Amount" = 78.01 (100 - 20 - 2 + 0.01)
        CreatePostPurchaseInvoiceCrMemoAndOpenPmtJournal(GeneralJournal, PmtDiscAmount, LibraryERM.GetAmountRoundingPrecision());

        // [WHEN] Open "Apply Entries" for Payment and apply to both Invoice and Credit Memo
        GeneralJournal."Apply Entries".Invoke();

        // [THEN] There are following "Apply Vendor Entries" page subtotals:
        // [THEN] "Balance" = 0.01
        // [THEN] "Pmt. Disc. Amount" = 2
        VerifyBalanceAndPmtDiscEnqueuedFromHandler(LibraryERM.GetAmountRoundingPrecision(), PmtDiscAmount);
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesHandler,GenJnlTemplateHandler')]
    [Scope('OnPrem')]
    procedure NegativePurchBalanceOnPaymentAppliedToInvWithPmtDiscAndCrMemo()
    var
        GeneralJournal: TestPage "General Journal";
        PmtDiscAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Payment Discount]
        // [SCENARIO 213795] Negative balance on "Apply Vendor Entries" page when apply payment to both invoice with Payment Discount and simple Credit Memo

        // [GIVEN] Invoice with "Amount" = 100, "Pmt Discount Possible" = 2
        // [GIVEN] Credit Memo with "Amount" = 20
        // [GIVEN] Payment with "Amount" = 77.99 (100 - 20 - 2 - 0.01)
        CreatePostPurchaseInvoiceCrMemoAndOpenPmtJournal(GeneralJournal, PmtDiscAmount, -LibraryERM.GetAmountRoundingPrecision());

        // [WHEN] Open "Apply Entries" for Payment and apply to both Invoice and Credit Memo
        GeneralJournal."Apply Entries".Invoke();

        // [THEN] There are following "Apply Vendor Entries" page subtotals:
        // [THEN] "Balance" = -20.01
        // [THEN] "Pmt. Disc. Amount" = 0
        VerifyBalanceAndPmtDiscEnqueuedFromHandler(-PmtDiscAmount - LibraryERM.GetAmountRoundingPrecision(), 0);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ApplyCustomerEntryPageHandler,GenJnlTemplateHandler,PaymentDiscToleranceWarningHandler')]
    [Scope('OnPrem')]
    procedure PmtDiscToleranceAcceptedWhenSalesCrMemoAppliesToPayment()
    var
        GenJnlLine: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustNo: Code[20];
        CrMemoNo: Code[20];
    begin
        // [FEATURE] [Sales] [Apply] [UI]
        // [SCENARIO 361036] Payment Discount Tolerance is accepted when Sales Credit Memo applies to Payment within Grace Period and option "Post as Payment Discount Tolerance" chosen in "Payment Discount Tolerance Warning"

        Initialize();

        // [GIVEN] Payment Discount Tolerance Warning = Yes, "Payment Discount Grade Period" = 5D
        SetupTolerancePmtDiscTolScenario(PaymentTerms);
        CustNo := CreateCustomerWithPmtTerms(PaymentTerms.Code);

        // [GIVEN] Credit Memo with "Posting Date" = 01.01, "Payment Discount Date" = 10.01
        // [GIVEN] Payment with "Posting Date" = 12.01 (within Payment Discount Grace Period)
        CreatePairedPaymentAndPostedCrMemoWithPmtDiscGracePeriod(
          GenJnlLine, CrMemoNo, GenJnlLine."Account Type"::Customer, CustNo, PaymentTerms, -LibraryRandom.RandDecInRange(100, 200, 2));

        // [GIVEN] "Apply Entries" page is opened and action "Set Applies-to ID" for Payment and Credit Memo is prformed
        InvokeApplyEntriesWithPmtToleranceInGeneralJournalPage(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name");

        // [WHEN] The LookUp action in "Apply Entries" page is invoked and option "Post as Payment Discount Tolerance" chosen in "Payment Discount Tolerance Warning"
        // Selection is performed in PaymentDiscToleranceWarningHandler

        // [THEN] "Payment Discount Tolerance" is updated in Customer Ledger Entry for "Credit Memo"
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJnlLine."Document Type"::"Credit Memo", CrMemoNo);
        CustLedgerEntry.TestField("Accepted Pmt. Disc. Tolerance");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ApplyVendorEntryPageHandler,GenJnlTemplateHandler,PaymentDiscToleranceWarningHandler')]
    [Scope('OnPrem')]
    procedure PmtDiscToleranceAcceptedWhenPurchCrMemoAppliesToPayment()
    var
        GenJnlLine: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        VendLedgerEntry: Record "Vendor Ledger Entry";
        VendNo: Code[20];
        CrMemoNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Apply] [UI]
        // [SCENARIO 361036] Payment Discount Tolerance is accepted when Purchase Credit Memo applies to Payment within Grace Period and option "Post as Payment Discount Tolerance" chosen in "Payment Discount Tolerance Warning"

        Initialize();

        // [GIVEN] Payment Discount Tolerance Warning = Yes, "Payment Discount Grade Period" = 5D
        SetupTolerancePmtDiscTolScenario(PaymentTerms);
        VendNo := CreateVendorWithPmtTerms(PaymentTerms.Code);

        // [GIVEN] Credit Memo with "Posting Date" = 01.01, "Payment Discount Date" = 10.01
        // [GIVEN] Payment with "Posting Date" = 12.01 (within Payment Discount Grace Period)
        CreatePairedPaymentAndPostedCrMemoWithPmtDiscGracePeriod(
          GenJnlLine, CrMemoNo, GenJnlLine."Account Type"::Vendor, VendNo, PaymentTerms, LibraryRandom.RandDecInRange(100, 200, 2));

        // [GIVEN] "Apply Entries" page is opened and action "Set Applies-to ID" for Payment and Credit Memo is prformed
        InvokeApplyEntriesWithPmtToleranceInGeneralJournalPage(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name");

        // [WHEN] The LookUp action in "Apply Entries" page is invoked and option "Post as Payment Discount Tolerance" chosen in "Payment Discount Tolerance Warning"
        // Selection is performed in PaymentDiscToleranceWarningHandler

        // [THEN] "Payment Discount Tolerance" is updated in Customer Ledger Entry for "Credit Memo"
        LibraryERM.FindVendorLedgerEntry(VendLedgerEntry, GenJnlLine."Document Type"::"Credit Memo", CrMemoNo);
        VendLedgerEntry.TestField("Accepted Pmt. Disc. Tolerance");
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesAndVerifyPmtDiscHandler,GenJnlTemplateHandler')]
    [Scope('OnPrem')]
    procedure SalesPmtDiscAmountWhenOnlyOneInvoiceAppliedToPaymentFully()
    var
        PaymentTerms: Record "Payment Terms";
        GenJnlLine: Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
        InvAmount: Decimal;
        PmtDiscAmount: Decimal;
        PmtAmount: Decimal;
        CustNo: Code[20];
        i: Integer;
    begin
        // [FEATURE] [Sales] [Payment Discount]
        // [SCENARIO 382074] The "Payment Discount Amount" is calculated for one of two sales invoices which is fully applied to payment

        Initialize();
        CreatePaymentTerms(PaymentTerms);

        InvAmount := LibraryRandom.RandDecInRange(1000, 2000, 2);
        PmtDiscAmount := Round(InvAmount * PaymentTerms."Discount %" / 100);
        PmtAmount := InvAmount + Round(InvAmount / LibraryRandom.RandIntInRange(3, 5));

        // [GIVEN] Invoice "I1" with "Amount" = 100, "Pmt Discount Possible" = 2
        // [GIVEN] Invoice "I2" with "Amount" = 100, "Pmt Discount Possible" = 2
        // [GIVEN] Payment with Amount = 150
        CustNo := LibrarySales.CreateCustomerNo();
        for i := 1 to 2 do
            CreateAndPostGenJnlLineWithPaymentTerms(
              GenJnlLine, GenJnlLine."Document Type"::Invoice, GenJnlLine."Account Type"::Customer,
              CustNo, PaymentTerms.Code, InvAmount);
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJnlLine, GenJnlLine."Document Type"::Payment, GenJnlLine."Account Type"::Customer, CustNo, -PmtAmount);

        LibraryVariableStorage.Enqueue(GenJnlLine."Journal Template Name");
        GeneralJournal.OpenEdit();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJnlLine."Journal Batch Name");
        LibraryVariableStorage.Enqueue(-PmtDiscAmount);

        // [WHEN] Open "Apply Entries" for Payment and apply to both Invoices
        GeneralJournal."Apply Entries".Invoke();

        // [THEN] "Pmt. Disc. Amount" = 2 on "Apply Customer Entries" page in total footer section
        // Verification done in handler ApplyCustomerEntriesAndVerifyPmtDiscHandler
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesAndVerifyPmtDiscHandler,GenJnlTemplateHandler')]
    [Scope('OnPrem')]
    procedure PurchPmtDiscAmountWhenOnlyOneInvoiceAppliedToPaymentFully()
    var
        PaymentTerms: Record "Payment Terms";
        GenJnlLine: Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
        InvAmount: Decimal;
        PmtDiscAmount: Decimal;
        PmtAmount: Decimal;
        VendNo: Code[20];
        i: Integer;
    begin
        // [FEATURE] [Purchase] [Payment Discount]
        // [SCENARIO 382074] The "Payment Discount Amount" is calculated for one of two purchase invoices which is fully applied to payment

        Initialize();
        CreatePaymentTerms(PaymentTerms);

        InvAmount := LibraryRandom.RandDecInRange(1000, 2000, 2);
        PmtDiscAmount := Round(InvAmount * PaymentTerms."Discount %" / 100);
        PmtAmount := InvAmount + Round(InvAmount / LibraryRandom.RandIntInRange(3, 5));

        // [GIVEN] Invoice "I1" with "Amount" = 100, "Pmt Discount Possible" = 2
        // [GIVEN] Invoice "I2" with "Amount" = 100, "Pmt Discount Possible" = 2
        // [GIVEN] Payment with Amount = 150
        VendNo := LibraryPurchase.CreateVendorNo();
        for i := 1 to 2 do
            CreateAndPostGenJnlLineWithPaymentTerms(
              GenJnlLine, GenJnlLine."Document Type"::Invoice, GenJnlLine."Account Type"::Vendor,
              VendNo, PaymentTerms.Code, -InvAmount);
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJnlLine, GenJnlLine."Document Type"::Payment, GenJnlLine."Account Type"::Vendor, VendNo, PmtAmount);

        LibraryVariableStorage.Enqueue(GenJnlLine."Journal Template Name");
        GeneralJournal.OpenEdit();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJnlLine."Journal Batch Name");
        LibraryVariableStorage.Enqueue(PmtDiscAmount);

        // [WHEN] Open "Apply Entries" for Payment and apply to both Invoices
        GeneralJournal."Apply Entries".Invoke();

        // [THEN] "Pmt. Disc. Amount" = 2 on "Apply Vendor Entries" page in total footer section
        // Verification done in handler ApplyVendorEntriesAndVerifyPmtDiscHandler
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesDebitDiscAccountUsedWhenPostPaymentTolWithFullVAT()
    var
        GLAccount: Record "G/L Account";
        SalesLine: Record "Sales Line";
        GenJnlLine: Record "Gen. Journal Line";
        GenPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        CustLedgEntry: Record "Cust. Ledger Entry";
        GLEntry: Record "G/L Entry";
        InvNo: Code[20];
        PmtNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 55999] G/L Entry with "Sales. Pmt. Disc. Debit Acc." is created when post "Payment Discount (VAT Excl.)" entry with Full VAT

        Initialize();
        // [GIVEN] "Adjust for Payment Disc." option is on
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);

        // [GIVEN] VAT Posting Setup with "Calculation Type" = "Full VAT"
        CreateFullVATPostingSetupWithAdjForPmtDisc(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale);

        // [GIVEN] Invoice with "Amount" = 100, "Pmt Discount Possible" = 2
        InvNo := PostSalesInvoiceWithPmtTermsAndVAT(SalesLine, VATPostingSetup, VATPostingSetup."Sales VAT Account");

        LibraryERM.FindCustomerLedgerEntry(CustLedgEntry, CustLedgEntry."Document Type"::Invoice, InvNo);
        CustLedgEntry.CalcFields("Remaining Amount");
        LibraryERM.SetApplyCustomerEntry(CustLedgEntry, CustLedgEntry."Remaining Amount" - CustLedgEntry."Remaining Pmt. Disc. Possible");

        // [WHEN] Post payment with "Amount" = 98 applied to Invoice
        PmtNo :=
          PostPaymentWithAppliedToId(GenJnlLine."Account Type"::Customer, CustLedgEntry."Customer No.",
            -CustLedgEntry."Remaining Amount" + CustLedgEntry."Remaining Pmt. Disc. Possible");

        // [THEN] G/L Entry is created with "Account No." = "Sales. Pmt. Disc. Debit Acc.", Amount = 0, "VAT Amount" = 2
        GenPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        VerifyVATAmountInGLEntry(
          GLEntry."Document Type"::Payment, PmtNo,
          GenPostingSetup."Sales Pmt. Disc. Debit Acc.", CustLedgEntry."Remaining Pmt. Disc. Possible");

        // Tear Down
        LibraryERM.ClearAdjustPmtDiscInVATSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesDebitDiscAccountUsedWhenUnapplyPaymentTolWithFullVAT()
    var
        GLAccount: Record "G/L Account";
        SalesLine: Record "Sales Line";
        GenJnlLine: Record "Gen. Journal Line";
        GenPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        CustLedgEntry: Record "Cust. Ledger Entry";
        GLEntry: Record "G/L Entry";
        InvNo: Code[20];
        PmtNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 54761] G/L Entry with "Sales. Pmt. Disc. Debit Acc." is created when unapply "Payment Discount (VAT Excl.)" entry with Full VAT

        Initialize();
        // [GIVEN] "Adjust for Payment Disc." option is on
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);

        // [GIVEN] VAT Posting Setup with "Calculation Type" = "Full VAT"
        CreateFullVATPostingSetupWithAdjForPmtDisc(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale);

        // [GIVEN] Invoice with "Amount" = 100, "Pmt Discount Possible" = 2
        InvNo := PostSalesInvoiceWithPmtTermsAndVAT(SalesLine, VATPostingSetup, VATPostingSetup."Sales VAT Account");

        LibraryERM.FindCustomerLedgerEntry(CustLedgEntry, CustLedgEntry."Document Type"::Invoice, InvNo);
        CustLedgEntry.CalcFields("Remaining Amount");
        LibraryERM.SetApplyCustomerEntry(CustLedgEntry, CustLedgEntry."Remaining Amount" - CustLedgEntry."Remaining Pmt. Disc. Possible");

        // [GIVEN] Payment with "Amount" = 98 applied to Invoice
        PmtNo :=
          PostPaymentWithAppliedToId(GenJnlLine."Account Type"::Customer, CustLedgEntry."Customer No.",
            -CustLedgEntry."Remaining Amount" + CustLedgEntry."Remaining Pmt. Disc. Possible");

        // [WHEN] Unapply payment
        LibraryERM.FindCustomerLedgerEntry(CustLedgEntry, CustLedgEntry."Document Type"::Payment, PmtNo);
        LibraryERM.UnapplyCustomerLedgerEntry(CustLedgEntry);

        // [THEN] G/L Entry is created with "Account No." = "Sales. Pmt. Disc. Debit Acc.", Amount = 0, "VAT Amount" = 2
        GenPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        VerifyGLEntryByTransNo(
          "General Posting Type"::" ", PmtNo, GetTransNoFromUnappliedCustDtldEntry(GLEntry."Document Type"::Payment, PmtNo),
          GenPostingSetup."Sales Pmt. Disc. Debit Acc.", CustLedgEntry."Remaining Pmt. Disc. Possible");

        // Tear Down
        LibraryERM.ClearAdjustPmtDiscInVATSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesDebitDiscAccountIsedWhenUnapplyPaymentWithLowPmtTol()
    var
        GenPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        GenJnlLine: Record "Gen. Journal Line";
        SalesLine: Record "Sales Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
        GLEntry: Record "G/L Entry";
        PmtTolAmount: Decimal;
        InvNo: Code[20];
        PmtNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 378550] G/L Entry with "Sales Pmt. Tol. Debit Acc." is created when unapply "Payment Tolerance (VAT Excl.)" with low amount

        Initialize();
        // [GIVEN] "Adjust for Payment Disc." option is on
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("Adjust for Payment Discount", true);
        VATPostingSetup.Modify(true);

        // [GIVEN] Invoice with "Amount" = 100, "Pmt Discount Possible" = 2
        InvNo :=
          PostSalesInvoiceWithPmtTermsAndVAT(SalesLine, VATPostingSetup,
            LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale));

        // [GIVEN] Payment Tolerance = 0.01
        LibraryERM.FindCustomerLedgerEntry(CustLedgEntry, CustLedgEntry."Document Type"::Invoice, InvNo);
        CustLedgEntry.CalcFields("Remaining Amount");
        PmtTolAmount := 0.01;
        CustLedgEntry.Validate("Accepted Payment Tolerance", PmtTolAmount);
        CustLedgEntry.Modify(true);
        LibraryERM.SetApplyCustomerEntry(
          CustLedgEntry, CustLedgEntry."Remaining Amount" - CustLedgEntry."Remaining Pmt. Disc. Possible" - PmtTolAmount);

        // [GIVEN] Payment with "Amount" = 97.99 (Amount - "Payment Discount" - Payment Tolerance) applied to invoice
        PmtNo :=
          PostPaymentWithAppliedToId(GenJnlLine."Account Type"::Customer, CustLedgEntry."Customer No.",
            -CustLedgEntry."Remaining Amount" + CustLedgEntry."Remaining Pmt. Disc. Possible");

        // [WHEN] Unapply payment
        LibraryERM.FindCustomerLedgerEntry(CustLedgEntry, CustLedgEntry."Document Type"::Payment, PmtNo);
        LibraryERM.UnapplyCustomerLedgerEntry(CustLedgEntry);

        // [THEN] G/L Entry is created with "Account No." = "Sales Pmt. Tol. Debit Acc.", Amount = -0.01
        GenPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        VerifyGLEntryByTransNo(
          "General Posting Type"::" ", PmtNo, GetTransNoFromUnappliedCustDtldEntry(GLEntry."Document Type"::Payment, PmtNo),
          GenPostingSetup."Sales Pmt. Tol. Debit Acc.", -PmtTolAmount);

        // Tear Down
        LibraryERM.ClearAdjustPmtDiscInVATSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCreditDiscAccountUsedWhenPostPaymentTolWithFullVAT()
    var
        GLAccount: Record "G/L Account";
        PurchLine: Record "Purchase Line";
        GenJnlLine: Record "Gen. Journal Line";
        GenPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        VendLedgEntry: Record "Vendor Ledger Entry";
        GLEntry: Record "G/L Entry";
        InvNo: Code[20];
        PmtNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 55999] G/L Entry with "Purch. Pmt. Disc. Credit Acc." is created when post "Payment Discount (VAT Excl.)" entry with Full VAT

        Initialize();
        // [GIVEN] "Adjust for Payment Disc." option is on
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);

        // [GIVEN] VAT Posting Setup with "Calculation Type" = "Full VAT"
        CreateFullVATPostingSetupWithAdjForPmtDisc(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase);

        // [GIVEN] Invoice with "Amount" = 100, "Pmt Discount Possible" = 2
        InvNo := PostPurchInvoiceWithPmtTermsAndVAT(PurchLine, VATPostingSetup, VATPostingSetup."Purchase VAT Account");

        LibraryERM.FindVendorLedgerEntry(VendLedgEntry, VendLedgEntry."Document Type"::Invoice, InvNo);
        VendLedgEntry.CalcFields("Remaining Amount");
        LibraryERM.SetApplyVendorEntry(VendLedgEntry, VendLedgEntry."Remaining Amount" - VendLedgEntry."Remaining Pmt. Disc. Possible");

        // [WHEN] Post payment with "Amount" = 98 applied to Invoice
        PmtNo :=
          PostPaymentWithAppliedToId(GenJnlLine."Account Type"::Vendor, VendLedgEntry."Vendor No.",
            -VendLedgEntry."Remaining Amount" + VendLedgEntry."Remaining Pmt. Disc. Possible");

        // [THEN] G/L Entry is created with "Account No." = "Purch. Pmt. Disc. Credit Acc.", Amount = 0, "VAT Amount" = 2
        GenPostingSetup.Get(PurchLine."Gen. Bus. Posting Group", PurchLine."Gen. Prod. Posting Group");
        VerifyVATAmountInGLEntry(
          GLEntry."Document Type"::Payment, PmtNo,
          GenPostingSetup."Purch. Pmt. Disc. Credit Acc.", VendLedgEntry."Remaining Pmt. Disc. Possible");

        // Tear Down
        LibraryERM.ClearAdjustPmtDiscInVATSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCreditDiscAccountUsedWhenUnapplyPaymentTolWithFullVAT()
    var
        GLAccount: Record "G/L Account";
        PurchLine: Record "Purchase Line";
        GenJnlLine: Record "Gen. Journal Line";
        GenPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        VendLedgEntry: Record "Vendor Ledger Entry";
        GLEntry: Record "G/L Entry";
        InvNo: Code[20];
        PmtNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 54761] G/L Entry with "Purch. Pmt. Disc. Credit Acc." is created when unapply "Payment Discount (VAT Excl.)" entry with Full VAT

        Initialize();
        // [GIVEN] "Adjust for Payment Disc." option is on
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);

        // [GIVEN] VAT Posting Setup with "Calculation Type" = "Full VAT"
        CreateFullVATPostingSetupWithAdjForPmtDisc(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase);

        // [GIVEN] Invoice with "Amount" = 100, "Pmt Discount Possible" = 2
        InvNo := PostPurchInvoiceWithPmtTermsAndVAT(PurchLine, VATPostingSetup, VATPostingSetup."Purchase VAT Account");

        LibraryERM.FindVendorLedgerEntry(VendLedgEntry, VendLedgEntry."Document Type"::Invoice, InvNo);
        VendLedgEntry.CalcFields("Remaining Amount");
        LibraryERM.SetApplyVendorEntry(VendLedgEntry, VendLedgEntry."Remaining Amount" - VendLedgEntry."Remaining Pmt. Disc. Possible");

        // [GIVEN] Payment with "Amount" = 98 applied to Invoice
        PmtNo :=
          PostPaymentWithAppliedToId(GenJnlLine."Account Type"::Vendor, VendLedgEntry."Vendor No.",
            -VendLedgEntry."Remaining Amount" + VendLedgEntry."Remaining Pmt. Disc. Possible");

        // [WHEN] Unapply payment
        LibraryERM.FindVendorLedgerEntry(VendLedgEntry, VendLedgEntry."Document Type"::Payment, PmtNo);
        LibraryERM.UnapplyVendorLedgerEntry(VendLedgEntry);

        // [THEN] G/L Entry is created with "Account No." = "Purch. Pmt. Disc. Credit Acc.", Amount = 0, "VAT Amount" = 2
        GenPostingSetup.Get(PurchLine."Gen. Bus. Posting Group", PurchLine."Gen. Prod. Posting Group");
        VerifyGLEntryByTransNo(
          "General Posting Type"::" ", PmtNo, GetTransNoFromUnappliedVendDtldEntry(GLEntry."Document Type"::Payment, PmtNo),
          GenPostingSetup."Purch. Pmt. Disc. Credit Acc.", VendLedgEntry."Remaining Pmt. Disc. Possible");

        // Tear Down
        LibraryERM.ClearAdjustPmtDiscInVATSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchDebitDiscAccountIsedWhenUnapplyPaymentWithLowPmtTol()
    var
        GenPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        GenJnlLine: Record "Gen. Journal Line";
        PurchLine: Record "Purchase Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
        GLEntry: Record "G/L Entry";
        PmtTolAmount: Decimal;
        InvNo: Code[20];
        PmtNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 378550] G/L Entry with "Sales Pmt. Tol. Debit Acc." is created when post "Payment Tolerance (VAT Excl.)" with low amount

        Initialize();
        // [GIVEN] "Adjust for Payment Disc." option is on
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("Adjust for Payment Discount", true);
        VATPostingSetup.Modify(true);

        // [GIVEN] Invoice with "Amount" = 100, "Pmt Discount Possible" = 2
        InvNo :=
          PostPurchInvoiceWithPmtTermsAndVAT(PurchLine, VATPostingSetup,
            LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase));

        // [GIVEN] Payment Tolerance = 0.01
        LibraryERM.FindVendorLedgerEntry(VendLedgEntry, VendLedgEntry."Document Type"::Invoice, InvNo);
        VendLedgEntry.CalcFields("Remaining Amount");
        PmtTolAmount := 0.01;
        VendLedgEntry.Validate("Accepted Payment Tolerance", PmtTolAmount);
        VendLedgEntry.Modify(true);
        LibraryERM.SetApplyVendorEntry(
          VendLedgEntry, VendLedgEntry."Remaining Amount" - VendLedgEntry."Remaining Pmt. Disc. Possible" - PmtTolAmount);

        // [GIVEN] Payment with "Amount" = 97.99 (Amount - "Payment Discount" - Payment Tolerance) applied to invoice
        PmtNo :=
          PostPaymentWithAppliedToId(GenJnlLine."Account Type"::Vendor, VendLedgEntry."Vendor No.",
            -VendLedgEntry."Remaining Amount" + VendLedgEntry."Remaining Pmt. Disc. Possible");

        // [WHEN] Unapply payment
        LibraryERM.FindVendorLedgerEntry(VendLedgEntry, VendLedgEntry."Document Type"::Payment, PmtNo);
        LibraryERM.UnapplyVendorLedgerEntry(VendLedgEntry);

        // [THEN] G/L Entry is created with "Account No." = "Sales Pmt. Tol. Debit Acc.", Amount = -0.01
        GenPostingSetup.Get(PurchLine."Gen. Bus. Posting Group", PurchLine."Gen. Prod. Posting Group");
        VerifyGLEntryByTransNo(
          "General Posting Type"::" ", PmtNo, GetTransNoFromUnappliedVendDtldEntry(GLEntry."Document Type"::Payment, PmtNo),
          GenPostingSetup."Purch. Pmt. Tol. Debit Acc.", -PmtTolAmount);

        // Tear Down
        LibraryERM.ClearAdjustPmtDiscInVATSetup();
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesHandler,GenJnlTemplateHandler')]
    [Scope('OnPrem')]
    procedure SalesPmtDiscWhenApplyBothInvAndCrMemoToPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
        PmtDiscAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Payment Discount]
        // [SCENARIO 226116] Balance on "Apply Customer Entries" page is zero when apply payment to both invoice and Credit Memo with Payment Discount

        // [GIVEN] Invoice with "Amount" = 100, "Pmt Discount Possible" = 2
        // [GIVEN] Credit Memo with "Amount" = -50, "Pmt Discount Possible" = -1
        // [GIVEN] Payment with "Amount" = 77 (100 - 20 - 2 - 1)
        CreatePostInvAndCrMemoWithDiscAndOpenPmtJournal(
          GeneralJournal, PmtDiscAmount, GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(), 1);

        // [WHEN] Open "Apply Entries" for Payment and apply to both Invoice and Credit Memo
        GeneralJournal."Apply Entries".Invoke();

        // [THEN] There are following "Apply Customer Entries" page subtotals:
        // [THEN] "Balance" = 0
        // [THEN] "Pmt. Disc. Amount" = 1
        VerifyBalanceAndPmtDiscEnqueuedFromHandler(0, -PmtDiscAmount);
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesHandler,GenJnlTemplateHandler')]
    [Scope('OnPrem')]
    procedure PurchPmtDiscWhenApplyBothInvAndCrMemoToPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
        PmtDiscAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Payment Discount]
        // [SCENARIO 226116] Balance on "Apply Vendor Entries" page is zero when apply payment to both invoice and Credit Memo with Payment Discount

        // [GIVEN] Invoice with "Amount" = 100, "Pmt Discount Possible" = 2
        // [GIVEN] Credit Memo with "Amount" = -50, "Pmt Discount Possible" = -1
        // [GIVEN] Payment with "Amount" = 77 (100 - 20 - 2 - 1)
        CreatePostInvAndCrMemoWithDiscAndOpenPmtJournal(
          GeneralJournal, PmtDiscAmount, GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(), -1);

        // [WHEN] Open "Apply Entries" for Payment and apply to both Invoice and Credit Memo
        GeneralJournal."Apply Entries".Invoke();

        // [THEN] There are following "Apply Vendor Entries" page subtotals:
        // [THEN] "Balance" = 0
        // [THEN] "Pmt. Disc. Amount" = -2
        VerifyBalanceAndPmtDiscEnqueuedFromHandler(0, PmtDiscAmount);
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler,ApplyPostCustomerEntryPageHandler,PostApplicationHandler,MessageHandler,PaymentToleranceWarningHandler')]
    [Scope('OnPrem')]
    procedure ApplyPostPmtTolFCYInvoice_Sales_PmtWithTolAmtEqualsToInvoiceAmt()
    var
        CurrencyCode: Code[10];
        CustomerNo: Code[20];
        InvoiceNo: Code[20];
        PaymentNo: Code[20];
        MaxPmtTolAmount: Decimal;
        MaxPmtTolAmountLCY: Decimal;
        InvoiceAmountFCY: Decimal;
        PaymentAmountLCY: Decimal;
        PaymentAmountFCY: Decimal;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 229966] Payment tolerance posting in case of LCY Payment to FCY Invoice, (Payment + Tolerance) = Invoice,
        // [SCENARIO 229966] currency with Max. Payment Tolerance Amount and Exchange:Relational ratio > 1
        Initialize();

        // [GIVEN] GLSetup."Max. Payment Tolerance Amount" = 200 LCY
        // [GIVEN] Currency "X" with Exchange:Relational ratio = 2, "Max. Payment Tolerance Amount" = 200 FCY (= 100 LCY)
        ApplyPostPmtTolFCYInvoice_SetupAndPrepareAmounts(
          MaxPmtTolAmount, MaxPmtTolAmountLCY, CurrencyCode, PaymentAmountLCY, PaymentAmountFCY, InvoiceAmountFCY, 0, 0);

        // [GIVEN] Customer FCY invoice with Amount = 600 FCY (= 300 LCY)
        // [GIVEN] Customer LCY payment with Amount = 200
        // [GIVEN] Invoice ledger entry has "Max. Payment Tolerance" = 200 FCY (= 100 LCY), "Remaining Amount" = 600
        CreatePostCustomerInvoiceAndPayment(
          CustomerNo, InvoiceNo, PaymentNo, CurrencyCode, InvoiceAmountFCY, PaymentAmountLCY, MaxPmtTolAmount);

        // [WHEN] Apply payment to invoice and perform post (Payment + Tolerance = 300 LCY = 600 FCY)
        ApplyPostCustomerPaymentUsingTolerance(CustomerNo);

        // [THEN] Payment tolerance warning page has been shown (post as Tolerance)
        // [THEN] Invoice ledger entry has "Max. Payment Tolerance" = 0, "Remaining Amount" = 0
        // [THEN] Payment ledger entry has "Original Amount" = -200, "Amount" = -300, "Remaining Amount" = 0
        VerifyCustomerInvoiceAndPayment(
          CustomerNo, InvoiceNo, PaymentNo, 0, 0, -PaymentAmountLCY, -(PaymentAmountLCY + MaxPmtTolAmountLCY), 0);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler,ApplyPostCustomerEntryPageHandler,PostApplicationHandler,MessageHandler,PaymentToleranceWarningHandler')]
    [Scope('OnPrem')]
    procedure ApplyPostPmtTolFCYInvoice_Sales_PmtWithTolAmtEqualsToInvoiceAmt_RoundingUp()
    var
        CurrencyCode: Code[10];
        CustomerNo: Code[20];
        InvoiceNo: Code[20];
        PaymentNo: Code[20];
        MaxPmtTolAmount: Decimal;
        MaxPmtTolAmountLCY: Decimal;
        InvoiceAmountFCY: Decimal;
        PaymentAmountLCY: Decimal;
        PaymentAmountFCY: Decimal;
    begin
        // [FEATURE] [Sales] [Rounding]
        // [SCENARIO 229966] Payment tolerance posting in case of LCY Payment to FCY Invoice, (Payment + Tolerance) = Invoice (+0.01 FCY cent is rounded to zero LCY),
        // [SCENARIO 229966] currency with Max. Payment Tolerance Amount and Exchange:Relational ratio > 1
        Initialize();

        // [GIVEN] GLSetup."Max. Payment Tolerance Amount" = 200 LCY
        // [GIVEN] Currency "X" with Exchange:Relational ratio = 2, "Max. Payment Tolerance Amount" = 200 FCY (= 100 LCY)
        ApplyPostPmtTolFCYInvoice_SetupAndPrepareAmounts(
          MaxPmtTolAmount, MaxPmtTolAmountLCY, CurrencyCode,
          PaymentAmountLCY, PaymentAmountFCY, InvoiceAmountFCY, 0, LibraryERM.GetAmountRoundingPrecision());

        // [GIVEN] Customer FCY invoice with Amount = 600.01 FCY (= 300 LCY)
        // [GIVEN] Customer LCY payment with Amount = 200
        // [GIVEN] Invoice ledger entry has "Max. Payment Tolerance" = 200 FCY (= 100 LCY), "Remaining Amount" = 600.01
        CreatePostCustomerInvoiceAndPayment(
          CustomerNo, InvoiceNo, PaymentNo, CurrencyCode, InvoiceAmountFCY, PaymentAmountLCY, MaxPmtTolAmount);

        // [WHEN] Apply payment to invoice and perform post (Payment + Tolerance = 300 LCY = 600 FCY)
        ApplyPostCustomerPaymentUsingTolerance(CustomerNo);

        // [THEN] Payment tolerance warning page has been shown (post as Tolerance)
        // [THEN] Invoice ledger entry has "Max. Payment Tolerance" = 0, "Remaining Amount" = 0
        // [THEN] Payment ledger entry has "Original Amount" = -200, "Amount" = -300, "Remaining Amount" = 0
        VerifyCustomerInvoiceAndPayment(
          CustomerNo, InvoiceNo, PaymentNo, 0, 0, -PaymentAmountLCY, -(PaymentAmountLCY + MaxPmtTolAmountLCY), 0);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler,ApplyPostCustomerEntryPageHandler,PostApplicationHandler,MessageHandler,PaymentToleranceWarningHandler')]
    [Scope('OnPrem')]
    procedure ApplyPostPmtTolFCYInvoice_Sales_PmtWithTolAmtEqualsToInvoiceAmt_RoundingDown()
    var
        CurrencyCode: Code[10];
        CustomerNo: Code[20];
        InvoiceNo: Code[20];
        PaymentNo: Code[20];
        MaxPmtTolAmount: Decimal;
        MaxPmtTolAmountLCY: Decimal;
        InvoiceAmountFCY: Decimal;
        PaymentAmountLCY: Decimal;
        PaymentAmountFCY: Decimal;
    begin
        // [FEATURE] [Sales] [Rounding]
        // [SCENARIO 229966] Payment tolerance posting in case of LCY Payment to FCY Invoice, (Payment + Tolerance) = Invoice (-0.01 FCY cent is rounded to zero LCY),
        // [SCENARIO 229966] currency with Max. Payment Tolerance Amount and Exchange:Relational ratio > 1
        Initialize();

        // [GIVEN] GLSetup."Max. Payment Tolerance Amount" = 200 LCY
        // [GIVEN] Currency "X" with Exchange:Relational ratio = 2, "Max. Payment Tolerance Amount" = 200 FCY (= 100 LCY)
        ApplyPostPmtTolFCYInvoice_SetupAndPrepareAmounts(
          MaxPmtTolAmount, MaxPmtTolAmountLCY, CurrencyCode,
          PaymentAmountLCY, PaymentAmountFCY, InvoiceAmountFCY, 0, -LibraryERM.GetAmountRoundingPrecision());

        // [GIVEN] Customer FCY invoice with Amount = 599.99 FCY (= 300 LCY)
        // [GIVEN] Customer LCY payment with Amount = 200
        // [GIVEN] Invoice ledger entry has "Max. Payment Tolerance" = 200 FCY (= 100 LCY), "Remaining Amount" = 599.99
        CreatePostCustomerInvoiceAndPayment(
          CustomerNo, InvoiceNo, PaymentNo, CurrencyCode, InvoiceAmountFCY, PaymentAmountLCY, MaxPmtTolAmount);

        // [WHEN] Apply payment to invoice and perform post (Payment + Tolerance = 300 LCY = 600 FCY)
        ApplyPostCustomerPaymentUsingTolerance(CustomerNo);

        // [THEN] Payment tolerance warning page has been shown (post as Tolerance)
        // [THEN] Invoice ledger entry has "Max. Payment Tolerance" = 0, "Remaining Amount" = 0
        // [THEN] Payment ledger entry has "Original Amount" = -200, "Amount" = -300, "Remaining Amount" = 0
        VerifyCustomerInvoiceAndPayment(
          CustomerNo, InvoiceNo, PaymentNo, 0, 0, -PaymentAmountLCY, -(PaymentAmountLCY + MaxPmtTolAmountLCY), 0);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler,ApplyPostCustomerEntryPageHandler,PostApplicationHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ApplyPostPmtTolFCYInvoice_Sales_PmtWithTolAmtIsLowerThanInvoiceAmt()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyCode: Code[10];
        CustomerNo: Code[20];
        InvoiceNo: Code[20];
        PaymentNo: Code[20];
        MaxPmtTolAmount: Decimal;
        MaxPmtTolAmountLCY: Decimal;
        InvoiceAmountFCY: Decimal;
        PaymentAmountLCY: Decimal;
        PaymentAmountFCY: Decimal;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 229966] Payment posting in case of LCY Payment to FCY Invoice, (Payment + Tolerance) < Invoice,
        // [SCENARIO 229966] currency with Max. Payment Tolerance Amount and Exchange:Relational ratio > 1
        Initialize();

        // [GIVEN] GLSetup."Max. Payment Tolerance Amount" = 200 LCY
        // [GIVEN] Currency "X" with Exchange:Relational ratio = 2, "Max. Payment Tolerance Amount" = 200 FCY (= 100 LCY)
        ApplyPostPmtTolFCYInvoice_SetupAndPrepareAmounts(
          MaxPmtTolAmount, MaxPmtTolAmountLCY, CurrencyCode,
          PaymentAmountLCY, PaymentAmountFCY, InvoiceAmountFCY, LibraryERM.GetAmountRoundingPrecision(), 0);

        // [GIVEN] Customer FCY invoice with Amount = 600.02 FCY (= 300.01 LCY)
        // [GIVEN] Customer LCY payment with Amount = 200
        // [GIVEN] Invoice ledger entry has "Max. Payment Tolerance" = 200 FCY (= 100 LCY), "Remaining Amount" = 600.02
        CreatePostCustomerInvoiceAndPayment(
          CustomerNo, InvoiceNo, PaymentNo, CurrencyCode, InvoiceAmountFCY, PaymentAmountLCY, MaxPmtTolAmount);

        // [WHEN] Apply payment to invoice and perform post (Payment + Tolerance = 300 LCY = 600 FCY)
        ApplyCustomerLedgerEntries(CustomerNo, GenJournalLine."Document Type"::Payment);

        // [THEN] Invoice ledger entry has "Max. Payment Tolerance" = 200, "Remaining Amount" = 200.02
        // [THEN] Payment ledger entry has "Original Amount" = -200, "Amount" = -200, "Remaining Amount" = 0
        VerifyCustomerInvoiceAndPayment(
          CustomerNo, InvoiceNo, PaymentNo,
          MaxPmtTolAmount, InvoiceAmountFCY - PaymentAmountFCY,
          -PaymentAmountLCY, -PaymentAmountLCY, 0);
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler,ApplyPostCustomerEntryPageHandler,PostApplicationHandler,MessageHandler,PaymentToleranceWarningHandler')]
    [Scope('OnPrem')]
    procedure ApplyPostPmtTolFCYInvoice_Sales_PmtWithTolAmtIsHigherThanInvoiceAmt()
    var
        CurrencyCode: Code[10];
        CustomerNo: Code[20];
        InvoiceNo: Code[20];
        PaymentNo: Code[20];
        MaxPmtTolAmount: Decimal;
        MaxPmtTolAmountLCY: Decimal;
        InvoiceAmountFCY: Decimal;
        PaymentAmountLCY: Decimal;
        PaymentAmountFCY: Decimal;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 229966] Payment tolerance posting in case of LCY Payment to FCY Invoice, (Payment + Tolerance) > Invoice,
        // [SCENARIO 229966] currency with Max. Payment Tolerance Amount and Exchange:Relational ratio > 1
        Initialize();

        // [GIVEN] GLSetup."Max. Payment Tolerance Amount" = 200 LCY
        // [GIVEN] Currency "X" with Exchange:Relational ratio = 2, "Max. Payment Tolerance Amount" = 200 FCY (= 100 LCY)
        ApplyPostPmtTolFCYInvoice_SetupAndPrepareAmounts(
          MaxPmtTolAmount, MaxPmtTolAmountLCY, CurrencyCode,
          PaymentAmountLCY, PaymentAmountFCY, InvoiceAmountFCY, -LibraryERM.GetAmountRoundingPrecision(), 0);

        // [GIVEN] Customer FCY invoice with Amount = 599.98 FCY (= 299.99 LCY)
        // [GIVEN] Customer LCY payment with Amount = 200
        // [GIVEN] Invoice ledger entry has "Max. Payment Tolerance" = 200 FCY (= 100 LCY), "Remaining Amount" = 599.98
        CreatePostCustomerInvoiceAndPayment(
          CustomerNo, InvoiceNo, PaymentNo, CurrencyCode, InvoiceAmountFCY, PaymentAmountLCY, MaxPmtTolAmount);

        // [WHEN] Apply payment to invoice and perform post (Payment + Tolerance = 300 LCY = 600 FCY)
        ApplyPostCustomerPaymentUsingTolerance(CustomerNo);

        // [THEN] Invoice ledger entry has "Max. Payment Tolerance" = 0, "Remaining Amount" = 0
        // [THEN] Payment ledger entry has "Original Amount" = -200, "Amount" = -299.99, "Remaining Amount" = 0
        VerifyCustomerInvoiceAndPayment(
          CustomerNo, InvoiceNo, PaymentNo, 0, 0,
          -PaymentAmountLCY, -(PaymentAmountLCY + MaxPmtTolAmountLCY - LibraryERM.GetAmountRoundingPrecision()), 0);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler,ApplyPostVendorEntryPageHandler,PostApplicationHandler,MessageHandler,PaymentToleranceWarningHandler')]
    [Scope('OnPrem')]
    procedure ApplyPostPmtTolFCYInvoice_Purch_PmtWithTolAmtEqualsToInvoiceAmt()
    var
        CurrencyCode: Code[10];
        VendorNo: Code[20];
        InvoiceNo: Code[20];
        PaymentNo: Code[20];
        MaxPmtTolAmount: Decimal;
        MaxPmtTolAmountLCY: Decimal;
        InvoiceAmountFCY: Decimal;
        PaymentAmountLCY: Decimal;
        PaymentAmountFCY: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 229966] Payment tolerance posting in case of LCY Payment to FCY Invoice, (Payment + Tolerance) = Invoice,
        // [SCENARIO 229966] currency with Max. Payment Tolerance Amount and Exchange:Relational ratio > 1
        Initialize();

        // [GIVEN] GLSetup."Max. Payment Tolerance Amount" = 200 LCY
        // [GIVEN] Currency "X" with Exchange:Relational ratio = 2, "Max. Payment Tolerance Amount" = 200 FCY (= 100 LCY)
        ApplyPostPmtTolFCYInvoice_SetupAndPrepareAmounts(
          MaxPmtTolAmount, MaxPmtTolAmountLCY, CurrencyCode,
          PaymentAmountLCY, PaymentAmountFCY, InvoiceAmountFCY, 0, 0);

        // [GIVEN] Vendor FCY invoice with Amount = 600 FCY (= 300 LCY)
        // [GIVEN] Vendor LCY payment with Amount = 200
        // [GIVEN] Invoice ledger entry has "Max. Payment Tolerance" = 200 FCY (= 100 LCY), "Remaining Amount" = 600
        CreatePostVendorInvoiceAndPayment(
          VendorNo, InvoiceNo, PaymentNo, CurrencyCode, InvoiceAmountFCY, PaymentAmountLCY, MaxPmtTolAmount);

        // [WHEN] Apply payment to invoice and perform post (Payment + Tolerance = 300 LCY = 600 FCY)
        ApplyPostVendorPaymentUsingTolerance(VendorNo);

        // [THEN] Payment tolerance warning page has been shown (post as Tolerance)
        // [THEN] Invoice ledger entry has "Max. Payment Tolerance" = 0, "Remaining Amount" = 0
        // [THEN] Payment ledger entry has "Original Amount" = 200, "Amount" = 300, "Remaining Amount" = 0
        VerifyVendorInvoiceAndPayment(
          VendorNo, InvoiceNo, PaymentNo, 0, 0, PaymentAmountLCY, PaymentAmountLCY + MaxPmtTolAmountLCY, 0);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler,ApplyPostVendorEntryPageHandler,PostApplicationHandler,MessageHandler,PaymentToleranceWarningHandler')]
    [Scope('OnPrem')]
    procedure ApplyPostPmtTolFCYInvoice_Purch_PmtWithTolAmtEqualsToInvoiceAmt_RoundingUp()
    var
        CurrencyCode: Code[10];
        VendorNo: Code[20];
        InvoiceNo: Code[20];
        PaymentNo: Code[20];
        MaxPmtTolAmount: Decimal;
        MaxPmtTolAmountLCY: Decimal;
        InvoiceAmountFCY: Decimal;
        PaymentAmountLCY: Decimal;
        PaymentAmountFCY: Decimal;
    begin
        // [FEATURE] [Purchase] [Rounding]
        // [SCENARIO 229966] Payment tolerance posting in case of LCY Payment to FCY Invoice, (Payment + Tolerance) = Invoice (+0.01 FCY cent is rounded to zero LCY),
        // [SCENARIO 229966] currency with Max. Payment Tolerance Amount and Exchange:Relational ratio > 1
        Initialize();

        // [GIVEN] GLSetup."Max. Payment Tolerance Amount" = 200 LCY
        // [GIVEN] Currency "X" with Exchange:Relational ratio = 2, "Max. Payment Tolerance Amount" = 200 FCY (= 100 LCY)
        ApplyPostPmtTolFCYInvoice_SetupAndPrepareAmounts(
          MaxPmtTolAmount, MaxPmtTolAmountLCY, CurrencyCode,
          PaymentAmountLCY, PaymentAmountFCY, InvoiceAmountFCY, 0, LibraryERM.GetAmountRoundingPrecision());

        // [GIVEN] Vendor FCY invoice with Amount = 600.01 FCY (= 300 LCY)
        // [GIVEN] Vendor LCY payment with Amount = 200
        // [GIVEN] Invoice ledger entry has "Max. Payment Tolerance" = 200 FCY (= 100 LCY), "Remaining Amount" = 600.01
        CreatePostVendorInvoiceAndPayment(
          VendorNo, InvoiceNo, PaymentNo, CurrencyCode, InvoiceAmountFCY, PaymentAmountLCY, MaxPmtTolAmount);

        // [WHEN] Apply payment to invoice and perform post (Payment + Tolerance = 300 LCY = 600 FCY)
        ApplyPostVendorPaymentUsingTolerance(VendorNo);

        // [THEN] Payment tolerance warning page has been shown (post as Tolerance)
        // [THEN] Invoice ledger entry has "Max. Payment Tolerance" = 0, "Remaining Amount" = 0
        // [THEN] Payment ledger entry has "Original Amount" = 200, "Amount" = 300, "Remaining Amount" = 0
        VerifyVendorInvoiceAndPayment(
          VendorNo, InvoiceNo, PaymentNo, 0, 0, PaymentAmountLCY, PaymentAmountLCY + MaxPmtTolAmountLCY, 0);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler,ApplyPostVendorEntryPageHandler,PostApplicationHandler,MessageHandler,PaymentToleranceWarningHandler')]
    [Scope('OnPrem')]
    procedure ApplyPostPmtTolFCYInvoice_Purch_PmtWithTolAmtEqualsToInvoiceAmt_RoundingDown()
    var
        CurrencyCode: Code[10];
        VendorNo: Code[20];
        InvoiceNo: Code[20];
        PaymentNo: Code[20];
        MaxPmtTolAmount: Decimal;
        MaxPmtTolAmountLCY: Decimal;
        InvoiceAmountFCY: Decimal;
        PaymentAmountLCY: Decimal;
        PaymentAmountFCY: Decimal;
    begin
        // [FEATURE] [Purchase] [Rounding]
        // [SCENARIO 229966] Payment tolerance posting in case of LCY Payment to FCY Invoice, (Payment + Tolerance) = Invoice (-0.01 FCY cent is rounded to zero LCY),
        // [SCENARIO 229966] currency with Max. Payment Tolerance Amount and Exchange:Relational ratio > 1
        Initialize();

        // [GIVEN] GLSetup."Max. Payment Tolerance Amount" = 200 LCY
        // [GIVEN] Currency "X" with Exchange:Relational ratio = 2, "Max. Payment Tolerance Amount" = 200 FCY (= 100 LCY)
        ApplyPostPmtTolFCYInvoice_SetupAndPrepareAmounts(
          MaxPmtTolAmount, MaxPmtTolAmountLCY, CurrencyCode,
          PaymentAmountLCY, PaymentAmountFCY, InvoiceAmountFCY, 0, -LibraryERM.GetAmountRoundingPrecision());

        // [GIVEN] Vendor FCY invoice with Amount = 599.99 FCY (= 300 LCY)
        // [GIVEN] Vendor LCY payment with Amount = 200
        // [GIVEN] Invoice ledger entry has "Max. Payment Tolerance" = 200 FCY (= 100 LCY), "Remaining Amount" = 599.99
        CreatePostVendorInvoiceAndPayment(
          VendorNo, InvoiceNo, PaymentNo, CurrencyCode, InvoiceAmountFCY, PaymentAmountLCY, MaxPmtTolAmount);

        // [WHEN] Apply payment to invoice and perform post (Payment + Tolerance = 300 LCY = 600 FCY)
        ApplyPostVendorPaymentUsingTolerance(VendorNo);

        // [THEN] Payment tolerance warning page has been shown (post as Tolerance)
        // [THEN] Invoice ledger entry has "Max. Payment Tolerance" = 0, "Remaining Amount" = 0
        // [THEN] Payment ledger entry has "Original Amount" = 200, "Amount" = 300, "Remaining Amount" = 0
        VerifyVendorInvoiceAndPayment(
          VendorNo, InvoiceNo, PaymentNo, 0, 0, PaymentAmountLCY, PaymentAmountLCY + MaxPmtTolAmountLCY, 0);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler,ApplyPostVendorEntryPageHandler,PostApplicationHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ApplyPostPmtTolFCYInvoice_Purch_PmtWithTolAmtIsLowerThanInvoiceAmt()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyCode: Code[10];
        VendorNo: Code[20];
        InvoiceNo: Code[20];
        PaymentNo: Code[20];
        MaxPmtTolAmount: Decimal;
        MaxPmtTolAmountLCY: Decimal;
        InvoiceAmountFCY: Decimal;
        PaymentAmountLCY: Decimal;
        PaymentAmountFCY: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 229966] Payment posting in case of LCY Payment to FCY Invoice, (Payment + Tolerance) < Invoice,
        // [SCENARIO 229966] currency with Max. Payment Tolerance Amount and Exchange:Relational ratio > 1
        Initialize();

        // [GIVEN] GLSetup."Max. Payment Tolerance Amount" = 200 LCY
        // [GIVEN] Currency "X" with Exchange:Relational ratio = 2, "Max. Payment Tolerance Amount" = 200 FCY (= 100 LCY)
        ApplyPostPmtTolFCYInvoice_SetupAndPrepareAmounts(
          MaxPmtTolAmount, MaxPmtTolAmountLCY, CurrencyCode,
          PaymentAmountLCY, PaymentAmountFCY, InvoiceAmountFCY, LibraryERM.GetAmountRoundingPrecision(), 0);

        // [GIVEN] Vendor FCY invoice with Amount = 600.02 FCY (= 300.01 LCY)
        // [GIVEN] Vendor LCY payment with Amount = 200
        // [GIVEN] Invoice ledger entry has "Max. Payment Tolerance" = 200 FCY (= 100 LCY), "Remaining Amount" = 600.02
        CreatePostVendorInvoiceAndPayment(
          VendorNo, InvoiceNo, PaymentNo, CurrencyCode, InvoiceAmountFCY, PaymentAmountLCY, MaxPmtTolAmount);

        // [WHEN] Apply payment to invoice and perform post (Payment + Tolerance = 300 LCY = 600 FCY)
        ApplyVendorLedgerEntries(VendorNo, GenJournalLine."Document Type"::Payment);

        // [THEN] Invoice ledger entry has "Max. Payment Tolerance" = -100, "Remaining Amount" = -200.02
        // [THEN] Payment ledger entry has "Original Amount" = 200, "Amount" = 200, "Remaining Amount" = 0
        VerifyVendorInvoiceAndPayment(
          VendorNo, InvoiceNo, PaymentNo,
          -MaxPmtTolAmount, -(InvoiceAmountFCY - PaymentAmountFCY),
          PaymentAmountLCY, PaymentAmountLCY, 0);
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler,ApplyPostVendorEntryPageHandler,PostApplicationHandler,MessageHandler,PaymentToleranceWarningHandler')]
    [Scope('OnPrem')]
    procedure ApplyPostPmtTolFCYInvoice_Purch_PmtWithTolAmtIsHigherThanInvoiceAmt()
    var
        CurrencyCode: Code[10];
        VendorNo: Code[20];
        InvoiceNo: Code[20];
        PaymentNo: Code[20];
        MaxPmtTolAmount: Decimal;
        MaxPmtTolAmountLCY: Decimal;
        InvoiceAmountFCY: Decimal;
        PaymentAmountLCY: Decimal;
        PaymentAmountFCY: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 229966] Payment tolerance posting in case of LCY Payment to FCY Invoice, (Payment + Tolerance) > Invoice,
        // [SCENARIO 229966] currency with Max. Payment Tolerance Amount and Exchange:Relational ratio > 1
        Initialize();

        // [GIVEN] GLSetup."Max. Payment Tolerance Amount" = 200 LCY
        // [GIVEN] Currency "X" with Exchange:Relational ratio = 2, "Max. Payment Tolerance Amount" = 200 FCY (= 100 LCY)
        ApplyPostPmtTolFCYInvoice_SetupAndPrepareAmounts(
          MaxPmtTolAmount, MaxPmtTolAmountLCY, CurrencyCode,
          PaymentAmountLCY, PaymentAmountFCY, InvoiceAmountFCY, -LibraryERM.GetAmountRoundingPrecision(), 0);

        // [GIVEN] Vendor FCY invoice with Amount = 599.98 FCY (= 299.99 LCY)
        // [GIVEN] Vendor LCY payment with Amount = 200
        // [GIVEN] Invoice ledger entry has "Max. Payment Tolerance" = 200 FCY (= 100 LCY), "Remaining Amount" = 599.98
        CreatePostVendorInvoiceAndPayment(
          VendorNo, InvoiceNo, PaymentNo, CurrencyCode, InvoiceAmountFCY, PaymentAmountLCY, MaxPmtTolAmount);

        // [WHEN] Apply payment to invoice and perform post (Payment + Tolerance = 300 LCY = 600 FCY)
        ApplyPostVendorPaymentUsingTolerance(VendorNo);

        // [THEN] Invoice ledger entry has "Max. Payment Tolerance" = 0, "Remaining Amount" = 0
        // [THEN] Payment ledger entry has "Original Amount" = 200, "Amount" = 299.99, "Remaining Amount" = 0
        VerifyVendorInvoiceAndPayment(
          VendorNo, InvoiceNo, PaymentNo, 0, 0,
          PaymentAmountLCY, PaymentAmountLCY + MaxPmtTolAmountLCY - LibraryERM.GetAmountRoundingPrecision(), 0);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ApplyPostCustomerEntryPageHandler,UnapplyCustomerEntryPageHandler,PostApplicationHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CustLedgerEntryMaxToleranceRecalculatedOnApplicationOnPage()
    var
        GenJnlLine: Record "Gen. Journal Line";
        CustNo: Code[20];
        InvoiceAmount: Decimal;
        PmtAmount: Decimal;
        MaxPaymtToleranceAmt: Decimal;
    begin
        // [FEATURE] [Sales] [UI]
        // [SCENARIO 265704] On "Customer Ledger Entry" Page if you Apply Document twice no Max Payment Tolerance errors occur.
        Initialize();

        // [GIVEN] Set "Max Payment Tolerance Amount" = "MPT".
        MaxPaymtToleranceAmt := LibraryRandom.RandDec(100, 2);
        SetPmtToleranceWithMaxAmount(true, false, 0, MaxPaymtToleranceAmt);

        // [GIVEN] Create Customer.
        CustNo := LibrarySales.CreateCustomerNo();

        // [GIVEN] Posted Invoice with Amount = "A" > "MPT".
        // [GIVEN] Posted Payment with Amount "B" > "A" - "MPT" and < "A".
        InvoiceAmount := LibraryRandom.RandDecInRange(100, 200, 2);
        PmtAmount := LibraryRandom.RandDecInDecimalRange(InvoiceAmount - MaxPaymtToleranceAmt, 200, 2);
        PostInvAndPmtGeneralJnlLines(GenJnlLine."Account Type"::Customer, CustNo, InvoiceAmount, -PmtAmount);

        // [WHEN] Apply Payment to Invoce twice on Customer Ledger Entries Page.
        ApplyCustomerLedgerEntriesTwice(CustNo, GenJnlLine."Document Type"::Invoice);

        // [THEN] No Max Payment Tolerance errors occur.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ApplyPostVendorEntryPageHandler,UnapplyVendorEntryPageHandler,PostApplicationHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure VendLedgerEntryMaxToleranceRecalculatedOnApplicationOnPage()
    var
        GenJnlLine: Record "Gen. Journal Line";
        VendNo: Code[20];
        InvoiceAmount: Decimal;
        PmtAmount: Decimal;
        MaxPaymtToleranceAmt: Decimal;
    begin
        // [FEATURE] [Purchase] [UI]
        // [SCENARIO 265704] On "Vendor Ledger Entry" Page if you Apply Document twice no Max Payment Tolerance errors occur.
        Initialize();

        // [GIVEN] Set "Max Payment Tolerance Amount" = "MPT".
        MaxPaymtToleranceAmt := LibraryRandom.RandDec(100, 2);
        SetPmtToleranceWithMaxAmount(true, false, 0, MaxPaymtToleranceAmt);

        // [GIVEN] Create Vendor.
        VendNo := LibraryPurchase.CreateVendorNo();

        // [GIVEN] Posted Invoice with Amount = "A" > "MPT".
        // [GIVEN] Posted Payment with Amount "B" > "A" - "MPT" and < "A".
        InvoiceAmount := LibraryRandom.RandDecInRange(100, 200, 2);
        PmtAmount := LibraryRandom.RandDecInDecimalRange(InvoiceAmount - MaxPaymtToleranceAmt, 200, 2);
        PostInvAndPmtGeneralJnlLines(GenJnlLine."Account Type"::Vendor, VendNo, -InvoiceAmount, PmtAmount);

        // [WHEN] Apply Payment to Invoce twice on Vendor Ledger Entries Page.
        ApplyVendorLedgerEntriesTwice(VendNo, GenJnlLine."Document Type"::Invoice);

        // [THEN] No Max Payment Tolerance errors occur.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PaymentDiscToleranceWarningHandler,PaymentToleranceWarningCheckValuesHandler')]
    [Scope('OnPrem')]
    procedure PaymentToleranceWarningValuesOnPageWhenPostBalanceForCustomer()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        AppliesToDocNo: Code[20];
        AppliesToDocAmount: Decimal;
        ApplyingAmount: Decimal;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 267495] Payment Tolerance Warning page with option "Post the Balance", "Applied Amount" = "Remaining Amount" of Applies-to Document, Balance = 0.
        Initialize();

        // [GIVEN] Posted Sales Invoice "SI1" with Amount = "A1".
        AppliesToDocAmount := CreateAndPostInvoiceOfGenJournalLineForCustomer(GenJournalLine, PaymentTerms);
        AppliesToDocNo := GenJournalLine."Document No.";

        // [GIVEN] General Journal Line with Amount = "A2".
        // [GIVEN] Difference between ABS("A2") and ABS("A1") is less or equal than Payment Tolerance (1-2%).
        ApplyingAmount := -CalcHalfToleranceAmount(AppliesToDocAmount, LibraryPmtDiscSetup.GetPmtTolerancePct(), '');
        CreatePaymentOfGenJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Customer, GenJournalLine."Account No.",
          GenJournalLine."Bal. Account Type"::"G/L Account", GenJournalLine."Bal. Account No.",
          ApplyingAmount, CalcDate(PaymentTerms."Discount Date Calculation", WorkDate()), '');

        // [WHEN] Set "Applies-to Doc. No." = "SI1". Select "Post the Balance as Payment Tolerance" on Payment Tolerance Warning page.
        LibraryVariableStorage.Enqueue(PostingAction::"Payment Tolerance Accounts");
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.Modify(true);

        // [THEN] The values on the Payment Tolerance Warning page are: "Amount" = "A2", "Applied Amount" = "A1", "Balance" = 0.
        Assert.AreEqual(ApplyingAmount, LibraryVariableStorage.DequeueDecimal(), 'Incorrect Applying Amount');
        Assert.AreEqual(AppliesToDocAmount, LibraryVariableStorage.DequeueDecimal(), 'Incorrect Applied Amount');
        Assert.AreEqual(0, LibraryVariableStorage.DequeueDecimal(), 'Incorrect Balance');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PaymentDiscToleranceWarningHandler,PaymentToleranceWarningCheckValuesHandler')]
    [Scope('OnPrem')]
    procedure PaymentToleranceWarningValuesOnPageWhenLeaveBalanceForCustomer()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        AppliesToDocNo: Code[20];
        AppliesToDocAmount: Decimal;
        ApplyingAmount: Decimal;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 267495] Payment Tolerance Warning page with option "Leave Amount", "Applied Amount" = MIN("Remaining Amount", Applying Amount), Balance =  "Remaining Amount" + Applying Amount.
        Initialize();

        // [GIVEN] Posted Sales Invoice "SI1" with Amount = "A1".
        AppliesToDocAmount := CreateAndPostInvoiceOfGenJournalLineForCustomer(GenJournalLine, PaymentTerms);
        AppliesToDocNo := GenJournalLine."Document No.";

        // [GIVEN] General Journal Line with Amount = "A2".
        // [GIVEN] Difference between ABS("A2") and ABS("A1") is less or equal than Payment Tolerance (1-2%).
        ApplyingAmount := -CalcHalfToleranceAmount(AppliesToDocAmount, LibraryPmtDiscSetup.GetPmtTolerancePct(), '');
        CreatePaymentOfGenJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Customer, GenJournalLine."Account No.",
          GenJournalLine."Bal. Account Type"::"G/L Account", GenJournalLine."Bal. Account No.",
          ApplyingAmount, CalcDate(PaymentTerms."Discount Date Calculation", WorkDate()), '');

        // [WHEN] Set "Applies-to Doc. No." = "SI1". Select "Leave a Remaining Amount" on Payment Tolerance Warning page.
        LibraryVariableStorage.Enqueue(PostingAction::"Remaining Amount");
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.Modify(true);

        // [THEN] The values on the Payment Tolerance Warning page are: "Amount" = "A2", "Applied Amount" = -"A2", "Balance" = "A1" + "A2".
        Assert.AreEqual(ApplyingAmount, LibraryVariableStorage.DequeueDecimal(), 'Incorrect Applying Amount');
        Assert.AreEqual(-ApplyingAmount, LibraryVariableStorage.DequeueDecimal(), 'Incorrect Applied Amount');
        Assert.AreEqual(ApplyingAmount + AppliesToDocAmount, LibraryVariableStorage.DequeueDecimal(), 'Incorrect Balance');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PaymentDiscToleranceWarningHandler,PaymentToleranceWarningCheckValuesHandler')]
    [Scope('OnPrem')]
    procedure PaymentToleranceWarningValuesOnPageWhenPostBalanceForVendor()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        AppliesToDocNo: Code[20];
        AppliesToDocAmount: Decimal;
        ApplyingAmount: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 267495] Payment Tolerance Warning page with option "Post the Balance", "Applied Amount" = "Remaining Amount" of Applies-to Document, Balance = 0.
        Initialize();

        // [GIVEN] Posted Purchase Invoice "PI1" with Amount = "A1".
        AppliesToDocAmount := CreateAndPostInvoiceOfGenJournalLineForVendor(GenJournalLine, PaymentTerms);
        AppliesToDocNo := GenJournalLine."Document No.";

        // [GIVEN] General Journal Line with Amount = "A2".
        // [GIVEN] Difference between ABS("A2") and ABS("A1") is less or equal than Payment Tolerance (1-2%).
        ApplyingAmount := CalcHalfToleranceAmount(AppliesToDocAmount, LibraryPmtDiscSetup.GetPmtTolerancePct(), '');
        CreatePaymentOfGenJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, GenJournalLine."Account No.",
          GenJournalLine."Bal. Account Type"::"G/L Account", GenJournalLine."Bal. Account No.",
          ApplyingAmount, CalcDate(PaymentTerms."Discount Date Calculation", WorkDate()), '');

        // [WHEN] Set "Applies-to Doc. No." = "PI1". Select "Post the Balance as Payment Tolerance" on Payment Tolerance Warning page.
        LibraryVariableStorage.Enqueue(PostingAction::"Payment Tolerance Accounts");
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.Modify(true);

        // [THEN] The values on the Payment Tolerance Warning page are: "Amount" = "A2", "Applied Amount" = "A1", "Balance" = 0.
        Assert.AreEqual(ApplyingAmount, LibraryVariableStorage.DequeueDecimal(), 'Incorrect Applying Amount');
        Assert.AreEqual(-AppliesToDocAmount, LibraryVariableStorage.DequeueDecimal(), 'Incorrect Applied Amount');
        Assert.AreEqual(0, LibraryVariableStorage.DequeueDecimal(), 'Incorrect Balance');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PaymentDiscToleranceWarningHandler,PaymentToleranceWarningCheckValuesHandler')]
    [Scope('OnPrem')]
    procedure PaymentToleranceWarningValuesOnPageWhenLeaveBalanceForVendor()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        AppliesToDocNo: Code[20];
        AppliesToDocAmount: Decimal;
        ApplyingAmount: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 267495] Payment Tolerance Warning page with option "Leave Amount", "Applied Amount" = MIN("Remaining Amount", Applying Amount), Balance =  "Remaining Amount" + Applying Amount.
        Initialize();

        // [GIVEN] Posted Purchase Invoice "PI1" with Amount = "A1".
        AppliesToDocAmount := CreateAndPostInvoiceOfGenJournalLineForVendor(GenJournalLine, PaymentTerms);
        AppliesToDocNo := GenJournalLine."Document No.";

        // [GIVEN] General Journal Line with Amount = "A2".
        // [GIVEN] Difference between ABS("A2") and ABS("A1") is less or equal than Payment Tolerance (1-2%).
        ApplyingAmount := CalcHalfToleranceAmount(AppliesToDocAmount, LibraryPmtDiscSetup.GetPmtTolerancePct(), '');
        CreatePaymentOfGenJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, GenJournalLine."Account No.",
          GenJournalLine."Bal. Account Type"::"G/L Account", GenJournalLine."Bal. Account No.",
          ApplyingAmount, CalcDate(PaymentTerms."Discount Date Calculation", WorkDate()), '');

        // [WHEN] Set "Applies-to Doc. No." = "PI1". Select "Leave a Remaining Amount" on Payment Tolerance Warning page.
        LibraryVariableStorage.Enqueue(PostingAction::"Remaining Amount");
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.Modify(true);

        // [THEN] The values on the Payment Tolerance Warning page are: "Amount" = "A2", "Applied Amount" = -"A2", "Balance" = "A1" + "A2".
        Assert.AreEqual(ApplyingAmount, LibraryVariableStorage.DequeueDecimal(), 'Incorrect Applying Amount');
        Assert.AreEqual(-ApplyingAmount, LibraryVariableStorage.DequeueDecimal(), 'Incorrect Applied Amount');
        Assert.AreEqual(ApplyingAmount - AppliesToDocAmount, LibraryVariableStorage.DequeueDecimal(), 'Incorrect Balance');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PaymentToleranceWarningCheckValuesHandler')]
    [Scope('OnPrem')]
    procedure PaymentToleranceWarningValuesOnPageWhenPostBalanceForPostedCustEntries()
    var
        GenJournalLine: Record "Gen. Journal Line";
        InvoiceAmount: Decimal;
        PaymentAmount: Decimal;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 267495] Payment Tolerance Warning page with "Post the Balance" when apply posted Customer Entries, "Applied Amount" = Applies-to Doc."Remaining Amount", Balance = 0.
        Initialize();

        // [GIVEN] Posted Sales Invoice with Amount = "A1", Posted Payment with Amount = "A2".
        // [GIVEN] Difference between ABS("A2") and ABS("A1") is less or equal than Payment Tolerance.
        InvoiceAmount := LibraryRandom.RandDec(100, 2);
        CreateAndPostGenJournalLinesForCustomerWithPaymentToleranceSetup(
          GenJournalLine, InvoiceAmount, LibraryRandom.RandDec(100, 2));
        PaymentAmount := GenJournalLine.Amount;

        // [WHEN] Apply Payment to Invoice, post application. Select "Post the Balance as Payment Tolerance" on Payment Tolerance Warning page.
        LibraryVariableStorage.Enqueue(PostingAction::"Payment Tolerance Accounts");
        ApplyAndPostCustomerEntry(GenJournalLine."Document No.", PaymentAmount);

        // [THEN] The values on the Payment Tolerance Warning page are: "Amount" = "A2", "Applied Amount" = "A1", "Balance" = 0.
        Assert.AreEqual(PaymentAmount, LibraryVariableStorage.DequeueDecimal(), 'Incorrect Applying Amount');
        Assert.AreEqual(InvoiceAmount, LibraryVariableStorage.DequeueDecimal(), 'Incorrect Applied Amount');
        Assert.AreEqual(0, LibraryVariableStorage.DequeueDecimal(), 'Incorrect Balance');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PaymentToleranceWarningCheckValuesHandler')]
    [Scope('OnPrem')]
    procedure PaymentToleranceWarningValuesOnPageWhenLeaveBalanceForPostedCustEntries()
    var
        GenJournalLine: Record "Gen. Journal Line";
        InvoiceAmount: Decimal;
        PaymentAmount: Decimal;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 267495] Payment Tolerance Warning page with "Leave Amount" when apply posted Customer Entries, "Applied Amount" = MIN("Remaining Amount", Applying Amount), Balance =  "Remaining Amount" + Applying Amount.
        Initialize();

        // [GIVEN] Posted Sales Invoice with Amount = "A1", Posted Payment with Amount = "A2".
        // [GIVEN] Difference between ABS("A2") and ABS("A1") is less or equal than Payment Tolerance.
        InvoiceAmount := LibraryRandom.RandDec(100, 2);
        CreateAndPostGenJournalLinesForCustomerWithPaymentToleranceSetup(
          GenJournalLine, InvoiceAmount, LibraryRandom.RandDec(100, 2));
        PaymentAmount := GenJournalLine.Amount;

        // [WHEN] Apply Payment to Invoice, post application. Select "Leave a Remaining Amount" on Payment Tolerance Warning page.
        LibraryVariableStorage.Enqueue(PostingAction::"Remaining Amount");
        ApplyAndPostCustomerEntry(GenJournalLine."Document No.", PaymentAmount);

        // [THEN] The values on the Payment Tolerance Warning page are: "Amount" = "A2", "Applied Amount" = -"A2", "Balance" = "A1" + "A2".
        Assert.AreEqual(PaymentAmount, LibraryVariableStorage.DequeueDecimal(), 'Incorrect Applying Amount');
        Assert.AreEqual(-PaymentAmount, LibraryVariableStorage.DequeueDecimal(), 'Incorrect Applied Amount');
        Assert.AreEqual(PaymentAmount + InvoiceAmount, LibraryVariableStorage.DequeueDecimal(), 'Incorrect Balance');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PaymentToleranceWarningCheckValuesHandler')]
    [Scope('OnPrem')]
    procedure PaymentToleranceWarningValuesOnPageWhenPostBalanceForPostedVendEntries()
    var
        GenJournalLine: Record "Gen. Journal Line";
        InvoiceAmount: Decimal;
        PaymentAmount: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 267495] Payment Tolerance Warning page with "Post the Balance" when apply posted Vendor Entries, "Applied Amount" = Applies-to Doc."Remaining Amount", Balance = 0.
        Initialize();

        // [GIVEN] Posted Purchase Invoice with Amount = "A1", Posted Payment with Amount = "A2".
        // [GIVEN] Difference between ABS("A2") and ABS("A1") is less or equal than Payment Tolerance.
        InvoiceAmount := -LibraryRandom.RandDec(100, 2);
        CreateAndPostGenJournalLinesForVendorWithPaymentToleranceSetup(
          GenJournalLine, InvoiceAmount, LibraryRandom.RandDec(100, 2));
        PaymentAmount := GenJournalLine.Amount;

        // [WHEN] Apply Payment to Invoice, post application. Select "Post the Balance as Payment Tolerance" on Payment Tolerance Warning page.
        LibraryVariableStorage.Enqueue(PostingAction::"Payment Tolerance Accounts");
        ApplyAndPostVendorEntry(GenJournalLine."Document No.", PaymentAmount);

        // [THEN] The values on the Payment Tolerance Warning page are: "Amount" = "A2", "Applied Amount" = "A1", "Balance" = 0.
        Assert.AreEqual(PaymentAmount, LibraryVariableStorage.DequeueDecimal(), 'Incorrect Applying Amount');
        Assert.AreEqual(InvoiceAmount, LibraryVariableStorage.DequeueDecimal(), 'Incorrect Applied Amount');
        Assert.AreEqual(0, LibraryVariableStorage.DequeueDecimal(), 'Incorrect Balance');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PaymentToleranceWarningCheckValuesHandler')]
    [Scope('OnPrem')]
    procedure PaymentToleranceWarningValuesOnPageWhenLeaveBalanceForPostedVendEntries()
    var
        GenJournalLine: Record "Gen. Journal Line";
        InvoiceAmount: Decimal;
        PaymentAmount: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 267495] Payment Tolerance Warning page with "Leave Amount" when apply posted Vendor Entries, "Applied Amount" = MIN("Remaining Amount", Applying Amount), Balance =  "Remaining Amount" + Applying Amount.
        Initialize();

        // [GIVEN] Posted Purchase Invoice with Amount = "A1", Posted Payment with Amount = "A2".
        // [GIVEN] Difference between ABS("A2") and ABS("A1") is less or equal than Payment Tolerance.
        InvoiceAmount := -LibraryRandom.RandDec(100, 2);
        CreateAndPostGenJournalLinesForVendorWithPaymentToleranceSetup(
          GenJournalLine, InvoiceAmount, LibraryRandom.RandDec(100, 2));
        PaymentAmount := GenJournalLine.Amount;

        // [WHEN] Apply Payment to Invoice, post application. Select "Leave a Remaining Amount" on Payment Tolerance Warning page.
        LibraryVariableStorage.Enqueue(PostingAction::"Remaining Amount");
        ApplyAndPostVendorEntry(GenJournalLine."Document No.", PaymentAmount);

        // [THEN] The values on the Payment Tolerance Warning page are: "Amount" = "A2", "Applied Amount" = -"A2", "Balance" = "A1" + "A2".
        Assert.AreEqual(PaymentAmount, LibraryVariableStorage.DequeueDecimal(), 'Incorrect Applying Amount');
        Assert.AreEqual(-PaymentAmount, LibraryVariableStorage.DequeueDecimal(), 'Incorrect Applied Amount');
        Assert.AreEqual(PaymentAmount + InvoiceAmount, LibraryVariableStorage.DequeueDecimal(), 'Incorrect Balance');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PaymentDiscToleranceWarningCheckNameHandler,PaymentToleranceWarningCheckNameHandler')]
    [Scope('OnPrem')]
    procedure PaymentDiscountToleranceAndPaymentTolernaceWarningCustomerName()
    var
        DummyCustomer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        InvoiceNo: Code[20];
        CustomerName: Text;
    begin
        // [FEATURE] [Sales] [UI]
        // [SCENARIO 267495] Payment Discount Tolerance and Payment Tolerance Warning pages show customer name
        Initialize();

        // [GIVEN] Post invoice and create payment for customer with Name = "CUSTNAME"
        CustomerName := LibraryRandom.RandText(MaxStrLen(DummyCustomer.Name));
        PostInvoiceAndCreatePaymentForCustomerWithSpecificName(GenJournalLine, InvoiceNo, CustomerName);

        // [WHEN] Apply payment to invoice
        GenJournalLine.Validate("Applies-to Doc. No.", InvoiceNo);

        // [THEN] Payment Discount Tolerance Warning page shows customer name "CUSTNAME"
        Assert.AreEqual(CustomerName, LibraryVariableStorage.DequeueText(), InvalidCustomerVendorNameErr);
        // [THEN] Payment Tolerance Warning page shows customer name "CUSTNAME"
        Assert.AreEqual(CustomerName, LibraryVariableStorage.DequeueText(), InvalidCustomerVendorNameErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PaymentDiscToleranceWarningCheckNameHandler,PaymentToleranceWarningCheckNameHandler')]
    [Scope('OnPrem')]
    procedure PaymentDiscountToleranceAndPaymentTolernaceWarningVendorName()
    var
        DummyVendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        InvoiceNo: Code[20];
        VendorName: Text;
    begin
        // [FEATURE] [Purchase] [UI]
        // [SCENARIO 267495] Payment Discount Tolerance and Payment Tolerance Warning pages show vendor name
        Initialize();

        // [GIVEN] Post invoice and create payment for vendor with Name = "VENDNAME"
        VendorName := LibraryRandom.RandText(MaxStrLen(DummyVendor.Name));
        PostInvoiceAndCreatePaymentForVendorWithSpecificName(GenJournalLine, InvoiceNo, VendorName);

        // [WHEN] Apply payment to invoice
        GenJournalLine.Validate("Applies-to Doc. No.", InvoiceNo);

        // [THEN] Payment Discount Tolerance Warning page shows vendor name "VENDNAME"
        Assert.AreEqual(VendorName, LibraryVariableStorage.DequeueText(), InvalidCustomerVendorNameErr);
        // [THEN] Payment Tolerance Warning page shows vendor name "VENDNAME"
        Assert.AreEqual(VendorName, LibraryVariableStorage.DequeueText(), InvalidCustomerVendorNameErr);
    end;

    [Test]
    [HandlerFunctions('ApplyCustEntriesOKPageHandler,ConfirmHandler,GeneralJournalTemplateListModalPageHandler,PaymentDiscToleranceWarningCheckNameHandler')]
    [Scope('OnPrem')]
    procedure CheckPaymentToleranceWarningAfterLookUpApplToDocNoWhenZeroAmount()
    var
        GenJournalLine: array[2] of Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        Customer: Record Customer;
        CashReceiptJournal: TestPage "Cash Receipt Journal";
    begin
        // [FEATURE] [Sales] [UI]
        // [SCENARIO 400306] Payment Discount Tolerance Warning is shown when Stan looks up "Applies-to Doc. No." for Customer when Amount of Gen. Journal Line is 0.
        Initialize();

        // [GIVEN] Customer "C1" with Payment Tolerance Discount setup
        SetupTolerancePmtDiscTolScenario(PaymentTerms);
        Customer.Get(CreateCustomerWithPmtTerms(PaymentTerms.Code));

        // [GIVEN] Posted Sales Invoice "SI1" with Amount = "A1" for Customer = "C1"
        CreateAndPostInvoiceOfGenJournalLine(
          GenJournalLine[1], GenJournalLine[1]."Account Type"::Customer,
          Customer."No.", '', LibraryRandom.RandDecInRange(100, 200, 2));

        // [GIVEN] Create Payment Gen. Journal Line with Customer = "C1" and Applies-to Doc. No. = "SI1" with Posting Date able to trigger Tolerance Warning
        CreateCashReceiptJnlLine(GenJournalLine[2], Customer."No.");
        SetupGenJnlLineForApplication(
          GenJournalLine[2], CalcDate(PaymentTerms."Discount Date Calculation", WorkDate()) + 1,
          GenJournalLine[1]."Document Type"::Invoice, GenJournalLine[1]."Document No.");

        // Enqueue value for GeneralJournalTemplateListModalPageHandler
        LibraryVariableStorage.Enqueue(GenJournalLine[2]."Journal Template Name");

        Commit();

        // [GIVEN] Cash Receipt Page was open for Payment Gen. Journal Line
        CashReceiptJournal.OpenEdit();
        CashReceiptJournal.GotoRecord(GenJournalLine[2]);
        LibraryVariableStorage.Enqueue(GenJournalLine[2].Description);

        // [WHEN] Applies-to Doc. No. Lookup is used, selecting Invoice "SI1"
        CashReceiptJournal."Applies-to Doc. No.".Lookup();
        // UI Handled by ApplyCustEntriesOKPageHandler and PaymentDiscToleranceWarningCheckNameHandler

        // [THEN] Payment Discount Tolerance Warning is shown, Amount updates to -"A1".
        CashReceiptJournal.Amount.AssertEquals(-GenJournalLine[1].Amount);

        CashReceiptJournal.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ApplyInvoicePartialySalesNoPmtDiscountTolerance()
    var
        PaymentTerms: Record "Payment Terms";
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        InvoiceAmount: Decimal;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 342795] Invoice below pmt. disc. tolerance has remaining amount when applied to payment with greater amount
        Initialize();

        // [GIVEN] Pmt. Disc. Tolerance Warning, Payment Discount Warning turned on in General Ledger Setup
        // [GIVEN] Payment Discount Grace Period = 3D, Payment Terms with Discount % = 5, Payment Tolerance % = 10
        SetPmtTolerance(true, true, LibraryRandom.RandIntInRange(5, 10));
        LibraryPmtDiscSetup.SetPmtDiscGracePeriodByText('<' + Format(LibraryRandom.RandInt(5)) + 'D>');
        CreatePaymentTerms(PaymentTerms);

        // [GIVEN] Sales Invoice with Amount = 1000 on 01-01-2020, Payment Discount Possible = 50, Max. Payment Tolerance = 100.
        // [GIVEN] Pmt. Discount Date = 05-01-20, Pmt. Disc. Tolerance Date = 08-01-2020
        // [GIVEN] Payment of Amount = -2000 is posted on 06-01-2020
        InvoiceAmount := LibraryRandom.RandDecInRange(1000, 2000, 0);
        CreateAndPostGenJournalLines(
          GenJournalLine, GenJournalLine."Account Type"::Customer, CreateCustomerWithPmtTerms(PaymentTerms.Code),
          InvoiceAmount, -InvoiceAmount * 2, CalcDate(PaymentTerms."Discount Date Calculation", WorkDate()) + 1);

        // [GIVEN] Set "Amount To Apply" = 500 for the invoice, below pmt. discount tolerance
        FindCustLedgEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, GenJournalLine."Account No.");
        LibraryERM.SetApplyCustomerEntry(CustLedgerEntry, InvoiceAmount / 2);
        FindCustLedgEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, GenJournalLine."Account No.");
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry);

        // [WHEN] Payment is applied to the invoice with no warnings
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry);

        // [THEN] Customer Ledger Entry for invoice has "Remaining Amount" = 500
        FindCustLedgEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, GenJournalLine."Account No.");
        CustLedgerEntry.CalcFields("Remaining Amount");
        CustLedgerEntry.TestField("Remaining Amount", InvoiceAmount / 2);
        // [THEN] Customer Ledger Entry for payment has "Remaining Amount" = -1500
        FindCustLedgEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, GenJournalLine."Account No.");
        CustLedgerEntry.CalcFields("Remaining Amount");
        CustLedgerEntry.TestField("Remaining Amount", -InvoiceAmount - InvoiceAmount / 2);
    end;

    [Test]
    [HandlerFunctions('PaymentDiscToleranceWarningHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ApplyInvoicePartialySalesDoNotAcceptPmtDiscountTolerance()
    var
        PaymentTerms: Record "Payment Terms";
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        InvoiceAmount: Decimal;
        PmtToleranceAmount: Decimal;
        PmtTolerancePct: Integer;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 342795] Invoice has remaining amount when applied to payment with greater amount within grace period and do not accept warnings
        Initialize();

        // [GIVEN] Pmt. Disc. Tolerance Warning, Payment Discount Warning turned on in General Ledger Setup
        // [GIVEN] Payment Discount Grace Period = 3D, Payment Terms with Discount % = 5, Payment Tolerance % = 10
        PmtTolerancePct := LibraryRandom.RandIntInRange(5, 10);
        SetPmtTolerance(true, true, PmtTolerancePct);
        LibraryPmtDiscSetup.SetPmtDiscGracePeriodByText('<' + Format(LibraryRandom.RandInt(5)) + 'D>');
        CreatePaymentTerms(PaymentTerms);

        // [GIVEN] Sales Invoice with Amount = 1000 on 01-01-2020, Payment Discount Possible = 50, Max. Payment Tolerance = 100.
        // [GIVEN] Pmt. Discount Date = 05-01-20, Pmt. Disc. Tolerance Date = 08-01-2020
        // [GIVEN] Payment of Amount = -2000 is posted on 06-01-2020
        InvoiceAmount := LibraryRandom.RandDecInRange(1000, 2000, 0);
        PmtToleranceAmount := Round(InvoiceAmount * PmtTolerancePct / 100);
        CreateAndPostGenJournalLines(
          GenJournalLine, GenJournalLine."Account Type"::Customer, CreateCustomerWithPmtTerms(PaymentTerms.Code),
          InvoiceAmount, -InvoiceAmount * 2, CalcDate(PaymentTerms."Discount Date Calculation", WorkDate()) + 1);

        // [GIVEN] Set "Amount To Apply" = 950 for the invoice
        FindCustLedgEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, GenJournalLine."Account No.");
        LibraryERM.SetApplyCustomerEntry(CustLedgerEntry, InvoiceAmount - PmtToleranceAmount / 2);
        FindCustLedgEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, GenJournalLine."Account No.");
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry);

        // [WHEN] Payment is applied to the invoice with confirmed 'Do not accept the late payment discount'
        LibraryVariableStorage.Enqueue(PostingAction::"Remaining Amount");
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry);

        // [THEN] Customer Ledger Entry for invoice has "Remaining Amount" = 50
        FindCustLedgEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, GenJournalLine."Account No.");
        CustLedgerEntry.CalcFields("Remaining Amount");
        CustLedgerEntry.TestField("Remaining Amount", PmtToleranceAmount / 2);
        // [THEN] Customer Ledger Entry for payment has "Remaining Amount" = -1050
        FindCustLedgEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, GenJournalLine."Account No.");
        CustLedgerEntry.CalcFields("Remaining Amount");
        CustLedgerEntry.TestField("Remaining Amount", -InvoiceAmount - PmtToleranceAmount / 2);
        // [THEN] No detailed entries created for types "Payment Discount Tolerance", "Payment Discount"
        Assert.IsFalse(
          FindDetailedCustLedgEntry(GenJournalLine."Account No.", DetailedCustLedgEntry."Entry Type"::"Payment Discount Tolerance"),
          StrSubstNo(DetailedCustomerLedgerEntryMustNotExist, Format(DetailedCustLedgEntry."Entry Type"::"Payment Discount Tolerance")));
        Assert.IsFalse(
          FindDetailedCustLedgEntry(GenJournalLine."Account No.", DetailedCustLedgEntry."Entry Type"::"Payment Discount"),
          StrSubstNo(DetailedCustomerLedgerEntryMustNotExist, Format(DetailedCustLedgEntry."Entry Type"::"Payment Discount")));

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ApplyInvoicePartialyPurchaseNoPmtDiscountTolerance()
    var
        PaymentTerms: Record "Payment Terms";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        InvoiceAmount: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 342795] Invoice has remaining amount when applied to payment with greater amount within grace period and do not accept warnings
        Initialize();

        // [GIVEN] Pmt. Disc. Tolerance Warning, Payment Discount Warning turned on in General Ledger Setup
        // [GIVEN] Payment Discount Grace Period = 3D, Payment Terms with Discount % = 5, Payment Tolerance % = 10
        SetPmtTolerance(true, true, LibraryRandom.RandIntInRange(5, 10));
        LibraryPmtDiscSetup.SetPmtDiscGracePeriodByText('<' + Format(LibraryRandom.RandInt(5)) + 'D>');
        CreatePaymentTerms(PaymentTerms);

        // [GIVEN] Purchase Invoice with Amount = -1000 on 01-01-2020, Payment Discount Possible = -50, Max. Payment Tolerance = -100.
        // [GIVEN] Pmt. Discount Date = 05-01-20, Pmt. Disc. Tolerance Date = 08-01-2020
        // [GIVEN] Payment of Amount = 2000 is posted on 06-01-2020
        InvoiceAmount := -LibraryRandom.RandDecInRange(1000, 2000, 0);
        CreateAndPostGenJournalLines(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, CreateVendorWithPmtTerms(PaymentTerms.Code),
          InvoiceAmount, -InvoiceAmount * 2, CalcDate(PaymentTerms."Discount Date Calculation", WorkDate()) + 1);

        // [GIVEN] Set "Amount To Apply" = -500 for the invoice
        FindVendLedgEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, GenJournalLine."Account No.");
        LibraryERM.SetApplyVendorEntry(VendorLedgerEntry, InvoiceAmount / 2);
        FindVendLedgEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Payment, GenJournalLine."Account No.");
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry);

        // [WHEN] Payment is applied to the invoice with no warnings
        LibraryVariableStorage.Enqueue(PostingAction::"Remaining Amount");
        LibraryERM.PostVendLedgerApplication(VendorLedgerEntry);

        // [THEN] Vendor Ledger Entry for invoice has "Remaining Amount" = -500
        FindVendLedgEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, GenJournalLine."Account No.");
        VendorLedgerEntry.CalcFields("Remaining Amount");
        VendorLedgerEntry.TestField("Remaining Amount", InvoiceAmount / 2);
        // [THEN] Vendor Ledger Entry for payment has "Remaining Amount" = 1500
        FindVendLedgEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Payment, GenJournalLine."Account No.");
        VendorLedgerEntry.CalcFields("Remaining Amount");
        VendorLedgerEntry.TestField("Remaining Amount", -InvoiceAmount - InvoiceAmount / 2);
    end;

    [Test]
    [HandlerFunctions('PaymentDiscToleranceWarningHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ApplyInvoicePartialyPurchaseDoNotAcceptPmtDiscountTolerance()
    var
        PaymentTerms: Record "Payment Terms";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        InvoiceAmount: Decimal;
        PmtToleranceAmount: Decimal;
        PmtTolerancePct: Integer;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 342795] Invoice has remaining amount when applied to payment with greater amount within grace period and do not accept warnings
        Initialize();

        // [GIVEN] Pmt. Disc. Tolerance Warning, Payment Discount Warning turned on in General Ledger Setup
        // [GIVEN] Payment Discount Grace Period = 3D, Payment Terms with Discount % = 5, Payment Tolerance % = 10
        PmtTolerancePct := LibraryRandom.RandIntInRange(5, 10);
        SetPmtTolerance(true, true, PmtTolerancePct);
        LibraryPmtDiscSetup.SetPmtDiscGracePeriodByText('<' + Format(LibraryRandom.RandInt(5)) + 'D>');
        CreatePaymentTerms(PaymentTerms);

        // [GIVEN] Purchase Invoice with Amount = -1000 on 01-01-2020, Payment Discount Possible = -50, Max. Payment Tolerance = -100.
        // [GIVEN] Pmt. Discount Date = 05-01-20, Pmt. Disc. Tolerance Date = 08-01-2020
        // [GIVEN] Payment of Amount = 2000 is posted on 06-01-2020
        InvoiceAmount := -LibraryRandom.RandDecInRange(1000, 2000, 0);
        PmtToleranceAmount := Round(InvoiceAmount * PmtTolerancePct / 100);
        CreateAndPostGenJournalLines(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, CreateVendorWithPmtTerms(PaymentTerms.Code),
          InvoiceAmount, -InvoiceAmount * 2, CalcDate(PaymentTerms."Discount Date Calculation", WorkDate()) + 1);

        // [GIVEN] Set "Amount To Apply" = -950 for the invoice
        FindVendLedgEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, GenJournalLine."Account No.");
        LibraryERM.SetApplyVendorEntry(VendorLedgerEntry, InvoiceAmount - PmtToleranceAmount / 2);
        FindVendLedgEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Payment, GenJournalLine."Account No.");
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry);

        // [WHEN] Payment is applied to the invoice with confirmed 'Do not accept the late payment discount'
        LibraryVariableStorage.Enqueue(PostingAction::"Remaining Amount");
        LibraryERM.PostVendLedgerApplication(VendorLedgerEntry);

        // [THEN] Vendor Ledger Entry for invoice has "Remaining Amount" = -50
        FindVendLedgEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, GenJournalLine."Account No.");
        VendorLedgerEntry.CalcFields("Remaining Amount");
        VendorLedgerEntry.TestField("Remaining Amount", PmtToleranceAmount / 2);
        // [THEN] Vendor Ledger Entry for payment has "Remaining Amount" = 1050
        FindVendLedgEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Payment, GenJournalLine."Account No.");
        VendorLedgerEntry.CalcFields("Remaining Amount");
        VendorLedgerEntry.TestField("Remaining Amount", -InvoiceAmount - PmtToleranceAmount / 2);
        // [THEN] No detailed entries created for types "Payment Discount Tolerance", "Payment Discount"
        Assert.IsFalse(
          FindDetailedVendorLedgEntry(GenJournalLine."Account No.", DetailedVendorLedgEntry."Entry Type"::"Payment Discount Tolerance"),
          StrSubstNo(DetailedVendorLedgerEntryMustNotExistErr, Format(DetailedVendorLedgEntry."Entry Type"::"Payment Discount Tolerance")));
        Assert.IsFalse(
          FindDetailedVendorLedgEntry(GenJournalLine."Account No.", DetailedVendorLedgEntry."Entry Type"::"Payment Discount"),
          StrSubstNo(DetailedVendorLedgerEntryMustNotExistErr, Format(DetailedVendorLedgEntry."Entry Type"::"Payment Discount")));

        LibraryVariableStorage.AssertEmpty();
    end;


    [Test]
    [HandlerFunctions('PostAndReconcilePageHandler,PaymentApplicationModalPageHandler,PostAndReconcilePageStatementDateHandler')]
    [Scope('OnPrem')]
    procedure ApplyReconciliationWithCurrencyAndPaymentToleranceSales()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        Currency: Record Currency;
        BankAccount: Record "Bank Account";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PaymentApplicationProposal: Record "Payment Application Proposal";
        Item: Record Item;
        PostedSalesDocNo: Code[20];
    begin
        // [SCENARIO 401363] Posting Reconciliation with Currency and payment tolerance should not leave opened applied Document
        Initialize();

        // [GIVEN] Currency "C" with Payment Tolerance % = 1 and Max. Payment Tolerance Amount = 1
        Currency.Get(LibraryERM.CreateCurrencyWithRandomExchRates());
        Currency.Validate("Payment Tolerance %", 1);
        Currency.Validate("Max. Payment Tolerance Amount", 1);
        Currency.Modify();

        // [GIVEN] Customer "CUST" with Currency Code = "C"
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", Currency.Code);
        Customer.Modify();

        // [GIVEN] Posted Sales Invoice for Customer "CUST" and Unit Price = 50
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        SalesLine.Validate("Unit Price", 50);
        SalesLine.Modify(true);
        PostedSalesDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Customer Ledger Entry "CLE" with Remaining Amount = 60.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, PostedSalesDocNo);
        CustLedgerEntry.CalcFields("Remaining Amount");

        // [GIVEN] Bank Account with Currency Code = "C"
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Currency Code", Currency.Code);
        BankAccount.Modify();

        // [GIVEN] Bank Account Reconciliation Line with "Statement Amount" = Customer Ledger Entry "CLE" - 0.01 (59.99)
        CreateBankPmtReconcWithLine(BankAccount, BankAccRecon, BankAccReconLine, WorkDate(), CustLedgerEntry."Remaining Amount" - 0.01);
        LibraryVariableStorage.Enqueue(FORMAT(PaymentApplicationProposal."Account Type"::Customer));
        LibraryVariableStorage.Enqueue(Customer."No.");
        LibraryVariableStorage.Enqueue(CustLedgerEntry."Document No.");

        // [GIVEN] Bank Account Reconciliation matched with Customer Ledger Entry
        MatchBankReconLineManually(BankAccReconLine);
        UpdateBankAccRecStmEndingBalance(BankAccRecon, BankAccRecon."Balance Last Statement" + BankAccReconLine."Statement Amount");

        // [WHEN] Bank Account Reconciliation is posted
        LibraryERM.PostBankAccReconciliation(BankAccRecon);

        // [THEN] Customer Ledger Entry "CLE" has Open = false and Remaining Amount = 0.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, PostedSalesDocNo);
        CustLedgerEntry.CalcFields("Remaining Amount");
        CustLedgerEntry.TestField(Open, false);
        CustLedgerEntry.TestField("Remaining Amount", 0);
    end;

    [Test]
    [HandlerFunctions('PostAndReconcilePageHandler,PaymentApplicationModalPageHandler,PostAndReconcilePageStatementDateHandler')]
    [Scope('OnPrem')]
    procedure ApplyReconciliationWithCurrencyAndPaymentTolerancePurch()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        Currency: Record Currency;
        BankAccount: Record "Bank Account";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        VendLedgerEntry: Record "Vendor Ledger Entry";
        PaymentApplicationProposal: Record "Payment Application Proposal";
        Item: Record Item;
        PostedPurchDocNo: Code[20];
    begin
        // [SCENARIO 401363] Posting Reconciliation with Currency and payment tolerance should not leave opened applied Document
        Initialize();

        // [GIVEN] Currency "C" with Payment Tolerance % = 1 and Max. Payment Tolerance Amount = 1
        Currency.Get(LibraryERM.CreateCurrencyWithRandomExchRates());
        Currency.Validate("Payment Tolerance %", 1);
        Currency.Validate("Max. Payment Tolerance Amount", 1);
        Currency.Modify();

        // [GIVEN] Vendor "Vend" with Currency Code = "C"
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", Currency.Code);
        Vendor.Modify();

        // [GIVEN] Posted Purchase Invoice for Vednor "VEND" and Direct Unit Cost = 50
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
        PurchaseLine.Validate("Direct Unit Cost", 50);
        PurchaseLine.Modify(true);
        PostedPurchDocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Vendor Ledger Entry "VLE" with Remaining Amount = 60.
        LibraryERM.FindVendorLedgerEntry(VendLedgerEntry, VendLedgerEntry."Document Type"::Invoice, PostedPurchDocNo);
        VendLedgerEntry.CalcFields("Remaining Amount");

        // [GIVEN] Bank Account with Currency Code = "C"
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Currency Code", Currency.Code);
        BankAccount.Modify();

        // [GIVEN] Bank Account Reconciliation Line with "Statement Amount" = Vendor Ledger Entry "VLE" - 0.01 (59.99)
        CreateBankPmtReconcWithLine(BankAccount, BankAccRecon, BankAccReconLine, WorkDate(), VendLedgerEntry."Remaining Amount" - 0.01);
        LibraryVariableStorage.Enqueue(FORMAT(PaymentApplicationProposal."Account Type"::Vendor));
        LibraryVariableStorage.Enqueue(Vendor."No.");
        LibraryVariableStorage.Enqueue(VendLedgerEntry."Document No.");

        // [GIVEN] Bank Account Reconciliation matched with Vendpr Ledger Entry
        MatchBankReconLineManually(BankAccReconLine);
        UpdateBankAccRecStmEndingBalance(BankAccRecon, BankAccRecon."Balance Last Statement" + BankAccReconLine."Statement Amount");

        // [WHEN] Bank Account Reconciliation is posted
        LibraryERM.PostBankAccReconciliation(BankAccRecon);

        // [THEN] Vendor Ledger Entry "VLE" has Open = false and Remaining Amount = 0.
        LibraryERM.FindVendorLedgerEntry(VendLedgerEntry, VendLedgerEntry."Document Type"::Invoice, PostedPurchDocNo);
        VendLedgerEntry.CalcFields("Remaining Amount");
        VendLedgerEntry.TestField(Open, false);
        VendLedgerEntry.TestField("Remaining Amount", 0);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Payment Tolerance");
        LibraryApplicationArea.EnableFoundationSetup();
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();
        // Setup demo data.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Payment Tolerance");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateAccountInCustomerPostingGroup();
        LibraryERMCountryData.UpdateAccountInVendorPostingGroups();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.RemoveBlankGenJournalTemplate();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        isInitialized := true;
        Commit();

        LibrarySetupStorage.SaveGeneralLedgerSetup();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Payment Tolerance");
    end;

    local procedure ApplyPostPmtTolFCYInvoice_SetupAndPrepareAmounts(var MaxPmtTolAmount: Decimal; var MaxPmtTolAmountLCY: Decimal; var CurrencyCode: Code[10]; var PaymentAmountLCY: Decimal; var PaymentAmountFCY: Decimal; var InvoiceAmountFCY: Decimal; InvoiceAdjustLCY: Decimal; InvoiceAdjustFCY: Decimal)
    begin
        SetupMaxPmtTolAmountLCYAndFCY(MaxPmtTolAmount, MaxPmtTolAmountLCY, CurrencyCode);
        ApplyPostPmtTolFCYInvoice_PrepareAmounts(
          PaymentAmountLCY, PaymentAmountFCY, InvoiceAmountFCY,
          CurrencyCode, MaxPmtTolAmountLCY, InvoiceAdjustLCY, InvoiceAdjustFCY);
    end;

    local procedure ApplyPostPmtTolFCYInvoice_PrepareAmounts(var PaymentAmountLCY: Decimal; var PaymentAmountFCY: Decimal; var InvoiceAmountFCY: Decimal; CurrencyCode: Code[10]; MaxPmtTolAmountLCY: Decimal; InvoiceAdjustLCY: Decimal; InvoiceAdjustFCY: Decimal)
    var
        InvoiceAmountLCY: Decimal;
    begin
        PaymentAmountLCY := LibraryRandom.RandDecInRange(1000, 2000, 2);
        PaymentAmountFCY := LibraryERM.ConvertCurrency(PaymentAmountLCY, '', CurrencyCode, WorkDate());
        InvoiceAmountLCY := PaymentAmountLCY + MaxPmtTolAmountLCY + InvoiceAdjustLCY;
        InvoiceAmountFCY := LibraryERM.ConvertCurrency(InvoiceAmountLCY, '', CurrencyCode, WorkDate()) + InvoiceAdjustFCY;
    end;

    local procedure PostGeneralJnlLine(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post Batch", GenJournalLine);

        // Delete the generated Journal Batch
        GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");
        GenJournalBatch.Delete();
    end;

    local procedure ApplyAndPostCustomerEntry(DocumentNo: Code[20]; AmountToApply: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
    begin
        // Apply Vendor Ledger Entries Using Set Applies-to ID.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, DocumentNo);
        LibraryERM.SetApplyCustomerEntry(CustLedgerEntry, AmountToApply);
        CustLedgerEntry2.SetRange("Document No.", DocumentNo);
        CustLedgerEntry2.SetRange("Customer No.", CustLedgerEntry."Customer No.");
        CustLedgerEntry2.FindFirst();
        CustLedgerEntry2.CalcFields("Remaining Amount");
        CustLedgerEntry2.Validate("Amount to Apply", CustLedgerEntry2."Remaining Amount");
        CustLedgerEntry2.Modify(true);
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry2);
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry);
    end;

    local procedure ApplyAndPostVendorEntry(DocumentNo: Code[20]; AmountToApply: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
    begin
        // Apply Vendor Ledger Entries Using Set Applies-to ID.
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Payment, DocumentNo);
        LibraryERM.SetApplyVendorEntry(VendorLedgerEntry, AmountToApply);
        VendorLedgerEntry2.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry2.SetRange("Vendor No.", VendorLedgerEntry."Vendor No.");
        VendorLedgerEntry2.FindFirst();
        VendorLedgerEntry2.CalcFields("Remaining Amount");
        VendorLedgerEntry2.Validate("Amount to Apply", VendorLedgerEntry2."Remaining Amount");
        VendorLedgerEntry2.Modify(true);
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry2);
        LibraryERM.PostVendLedgerApplication(VendorLedgerEntry);
    end;

    local procedure ApplyFromGeneralJournal(DocumentType: Enum "Gen. Journal Document Type"; AccountNo: Code[20])
    var
        GeneralJournal: TestPage "General Journal";
    begin
        GeneralJournal.OpenEdit();
        GeneralJournal.FILTER.SetFilter("Document Type", Format(DocumentType));
        GeneralJournal.FILTER.SetFilter("Account No.", AccountNo);
        GeneralJournal."Apply Entries".Invoke();
    end;

    local procedure ApplyVendLedEntryAppliesToID(var GenJournalLine: Record "Gen. Journal Line"; AmountToApply: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Apply Vendor Entries.
        VendorLedgerEntry.SetRange("Vendor No.", GenJournalLine."Account No.");
        VendorLedgerEntry.SetRange(Open, true);
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.Validate("Applies-to ID", GenJournalLine."Document No.");
        VendorLedgerEntry.Validate("Amount to Apply", AmountToApply);
        VendorLedgerEntry.Modify(true);
        GenJournalLine.Validate(Amount, -VendorLedgerEntry."Amount to Apply");
        GenJournalLine.Validate("Applies-to ID", GenJournalLine."Document No.");
        GenJournalLine.Modify(true);
    end;

    local procedure ApplyVendLedEntryAppliesToDoc(var GenJournalLine: Record "Gen. Journal Line"; AppliestoDocType: Enum "Gen. Journal Document Type"; AmountToApply: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Apply Vendor Ledger Entries Using Applies-to Doc. No.
        VendorLedgerEntry.SetRange("Vendor No.", GenJournalLine."Account No.");
        VendorLedgerEntry.SetRange(Open, true);
        VendorLedgerEntry.SetRange("Document Type", AppliestoDocType);
        VendorLedgerEntry.FindFirst();
        GenJournalLine.Validate("Applies-to Doc. Type", AppliestoDocType);
        GenJournalLine.Validate("Applies-to Doc. No.", VendorLedgerEntry."Document No.");
        GenJournalLine.Validate(Amount, AmountToApply);
        GenJournalLine.Modify(true);
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

    local procedure ApplyVendorLedgerEntries(VendorNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    var
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
    begin
        VendorLedgerEntries.OpenView();
        VendorLedgerEntries.FILTER.SetFilter("Vendor No.", VendorNo);
        VendorLedgerEntries.FILTER.SetFilter("Document Type", Format(DocumentType));
        VendorLedgerEntries.ActionApplyEntries.Invoke();
    end;

    local procedure ApplyCustomerLedgerEntriesTwice(CustomerNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    var
        CustomerLedgerEntries: TestPage "Customer Ledger Entries";
    begin
        CustomerLedgerEntries.OpenView();
        CustomerLedgerEntries.FILTER.SetFilter("Customer No.", CustomerNo);
        CustomerLedgerEntries.FILTER.SetFilter("Document Type", Format(DocumentType));
        CustomerLedgerEntries."Apply Entries".Invoke();
        CustomerLedgerEntries.UnapplyEntries.Invoke();
        CustomerLedgerEntries."Apply Entries".Invoke();
    end;

    local procedure ApplyVendorLedgerEntriesTwice(VendorNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    var
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
    begin
        VendorLedgerEntries.OpenView();
        VendorLedgerEntries.FILTER.SetFilter("Vendor No.", VendorNo);
        VendorLedgerEntries.FILTER.SetFilter("Document Type", Format(DocumentType));
        VendorLedgerEntries.ActionApplyEntries.Invoke();
        VendorLedgerEntries.UnapplyEntries.Invoke();
        VendorLedgerEntries.ActionApplyEntries.Invoke();
    end;

    local procedure ApplyPostCustomerPaymentUsingTolerance(CustomerNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryVariableStorage.Enqueue(PostingAction::"Payment Tolerance Accounts");
        ApplyCustomerLedgerEntries(CustomerNo, GenJournalLine."Document Type"::Payment);
    end;

    local procedure ApplyPostVendorPaymentUsingTolerance(VendorNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryVariableStorage.Enqueue(PostingAction::"Payment Tolerance Accounts");
        ApplyVendorLedgerEntries(VendorNo, GenJournalLine."Document Type"::Payment);
    end;

    local procedure ApplyAndPostPaymentToSalesDoc(GenJournalLine: Record "Gen. Journal Line")
    var
        CashReceiptJournal: TestPage "Cash Receipt Journal";
    begin
        CashReceiptJournal.OpenEdit();
        CashReceiptJournal.CurrentJnlBatchName.SetValue(GenJournalLine."Journal Batch Name");
        CashReceiptJournal.FILTER.SetFilter("Document Type", Format(GenJournalLine."Document Type"));
        CashReceiptJournal.FILTER.SetFilter("Document No.", GenJournalLine."Document No.");
        CashReceiptJournal."Applies-to Doc. No.".Lookup();
        CashReceiptJournal.OK().Invoke();
    end;

    local procedure CreateCashReceiptJnlLine(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, GenJournalTemplate.Type::"Cash Receipts");
        GenJournalTemplate.Modify(true);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, AccountNo,
          GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), 0);
    end;

    local procedure CreatePaymentOfGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; BalAccountType: Enum "Gen. Journal Account Type"; BalAccountNo: Code[20]; AmountToApply: Decimal; PaymentDate: Date; ApplyToDocNo: Code[20])
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
          GenJournalLine."Document Type"::Payment, AccountType, AccountNo, AmountToApply);
        GenJournalLine.Validate("Posting Date", PaymentDate + 1);
        GenJournalLine.Validate("Bal. Account Type", BalAccountType);
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", ApplyToDocNo);
        GenJournalLine.Modify(true);
    end;

    local procedure CreatePostPaymentWithAppliesToDoc(GenJnlTemplateName: Code[10]; GenJnlBatchName: Code[10]; AccountType: Enum "Gen. Journal Account Type"; DocumentNo: Code[20]; PostingDate: Date; PmtAmount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
    begin
        GenJournalLine."Journal Template Name" := GenJnlTemplateName;
        GenJournalLine."Journal Batch Name" := GenJnlBatchName;
        CreatePaymentOfGenJournalLine(
          GenJournalLine, AccountType, '',
          GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(),
          0, PostingDate, '');
        GenJournalLine.Validate("Applies-to Doc. No.", DocumentNo);
        GenJournalLine.Modify(true);

        GeneralJournal.OpenEdit();
        GeneralJournal.Amount.SetValue(-PmtAmount);
        GeneralJournal.Next();

        GenJournalLine.Find();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostGenJournalLines(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; InvoiceAmount: Decimal; PaymentAmount: Decimal; PaymentDate: Date)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        SelectGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Invoice, AccountType, AccountNo, InvoiceAmount);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, AccountType, AccountNo, PaymentAmount);
        GenJournalLine.Validate("Posting Date", PaymentDate);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostInvoiceOfGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; CurrencyCode: Code[10]; LineAmount: Decimal): Code[20]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        SelectGenJournalBatch(GenJournalBatch);
        GenJournalLine.DeleteAll();
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          AccountType, AccountNo, LineAmount);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreateAndPostInvoiceOfGenJournalLineForCustomer(var GenJournalLine: Record "Gen. Journal Line"; var PaymentTerms: Record "Payment Terms"): Decimal
    begin
        LibraryVariableStorage.Enqueue(PostingAction::"Remaining Amount");

        CreatePaymentTerms(PaymentTerms);
        SetPmtToleranceWithGracePeriod();

        CreateAndPostInvoiceOfGenJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Customer,
          CreateCustomerWithPmtTerms(PaymentTerms.Code), '', LibraryRandom.RandDecInRange(100, 200, 2));
        exit(GenJournalLine.Amount);
    end;

    local procedure CreateAndPostInvoiceOfGenJournalLineForVendor(var GenJournalLine: Record "Gen. Journal Line"; var PaymentTerms: Record "Payment Terms"): Decimal
    begin
        LibraryVariableStorage.Enqueue(PostingAction::"Remaining Amount");

        CreatePaymentTerms(PaymentTerms);
        SetPmtToleranceWithGracePeriod();
        CreateVendorWithPmtTerms(PaymentTerms.Code);

        CreateAndPostInvoiceOfGenJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Vendor,
          CreateVendorWithPmtTerms(PaymentTerms.Code), '', -LibraryRandom.RandDecInRange(100, 200, 2));
        exit(Abs(GenJournalLine.Amount));
    end;

    local procedure CreateAndPostGenJournalLinesForCustomerWithPaymentToleranceSetup(var GenJournalLine: Record "Gen. Journal Line"; InvoiceAmount: Decimal; TolerancePct: Decimal)
    var
        PaymentTerms: Record "Payment Terms";
        PaymentAmount: Decimal;
    begin
        PaymentAmount := (InvoiceAmount * TolerancePct / 100) - InvoiceAmount;
        SetPmtTolerance(true, false, TolerancePct);
        CreatePaymentTerms(PaymentTerms);
        CreateAndPostGenJournalLines(
          GenJournalLine, GenJournalLine."Account Type"::Customer, CreateCustomerWithPmtTerms(PaymentTerms.Code),
          InvoiceAmount, PaymentAmount, WorkDate());
    end;

    local procedure CreateAndPostGenJournalLinesForVendorWithPaymentToleranceSetup(var GenJournalLine: Record "Gen. Journal Line"; InvoiceAmount: Decimal; TolerancePct: Decimal)
    var
        PaymentTerms: Record "Payment Terms";
        PaymentAmount: Decimal;
    begin
        PaymentAmount := (InvoiceAmount * TolerancePct / 100) - InvoiceAmount;
        SetPmtTolerance(true, false, TolerancePct);
        CreatePaymentTerms(PaymentTerms);
        CreateAndPostGenJournalLines(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, CreateVendorWithPmtTerms(PaymentTerms.Code),
          InvoiceAmount, PaymentAmount, WorkDate());
    end;

    local procedure CreateAndPostGenJournalLinesWithPaymentDiscountToleranceSetup(var GenJournalLine: Record "Gen. Journal Line")
    var
        PaymentTerms: Record "Payment Terms";
        Amount: Decimal;
    begin
        Amount := LibraryRandom.RandDec(100, 2);
        SetPmtTolerance(false, true, 0);
        CreatePaymentTerms(PaymentTerms);
        CreateAndPostGenJournalLines(
          GenJournalLine, GenJournalLine."Account Type"::Customer, CreateCustomerWithPmtTerms(PaymentTerms.Code), Amount, -Amount,
          CalcDate(Format(PaymentTerms."Discount Date Calculation") + '+' + LibraryPmtDiscSetup.GetPmtDiscGracePeriod(), WorkDate()));
    end;

    local procedure CreateAndPostSalesCreditMemo(var SalesLine: Record "Sales Line"; DocumentNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesCreditMemoCopyDocument(SalesHeader, SalesLine."Sell-to Customer No.", DocumentNo);
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindLast();
        SalesLine.Validate("Unit Price", SalesLine."Unit Price" + LibraryRandom.RandDec(10, 2));
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreatePostCustomerPayment(CustomerNo: Code[20]; Amount: Decimal): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, CustomerNo, -Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreatePostVendorPayment(VendorNo: Code[20]; Amount: Decimal): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, VendorNo, Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreatePostSalesInvoiceFromJournal(CustomerNo: Code[20]; CurrencyCode: Code[10]; Amount: Decimal): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        exit(
          CreateAndPostInvoiceOfGenJournalLine(
            GenJournalLine, GenJournalLine."Account Type"::Customer, CustomerNo, CurrencyCode, Amount));
    end;

    local procedure CreatePostPurchaseInvoiceFromJournal(VendorNo: Code[20]; CurrencyCode: Code[10]; Amount: Decimal): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        exit(
          CreateAndPostInvoiceOfGenJournalLine(
            GenJournalLine, GenJournalLine."Account Type"::Vendor, VendorNo, CurrencyCode, -Amount));
    end;

    local procedure CreatePostCustomerInvoiceAndPayment(var CustomerNo: Code[20]; var InvoiceNo: Code[20]; var PaymentNo: Code[20]; CurrencyCode: Code[10]; InvoiceAmountFCY: Decimal; PaymentAmountLCY: Decimal; MaxPmtTolAmountFCY: Decimal)
    begin
        CustomerNo := LibrarySales.CreateCustomerNo();
        InvoiceNo := CreatePostSalesInvoiceFromJournal(CustomerNo, CurrencyCode, InvoiceAmountFCY);
        PaymentNo := CreatePostCustomerPayment(CustomerNo, PaymentAmountLCY);
        VerifyCustomerInvoiceMaxPaymentToleranceAndRemAmount(CustomerNo, InvoiceNo, MaxPmtTolAmountFCY, InvoiceAmountFCY);
    end;

    local procedure CreatePostVendorInvoiceAndPayment(var VendorNo: Code[20]; var InvoiceNo: Code[20]; var PaymentNo: Code[20]; CurrencyCode: Code[10]; InvoiceAmountFCY: Decimal; PaymentAmountLCY: Decimal; MaxPmtTolAmountFCY: Decimal)
    begin
        VendorNo := LibraryPurchase.CreateVendorNo();
        InvoiceNo := CreatePostPurchaseInvoiceFromJournal(VendorNo, CurrencyCode, InvoiceAmountFCY);
        PaymentNo := CreatePostVendorPayment(VendorNo, PaymentAmountLCY);
        VerifyVendorInvoiceMaxPaymentToleranceAndRemAmount(VendorNo, InvoiceNo, -MaxPmtTolAmountFCY, -InvoiceAmountFCY);
    end;

    local procedure CreateGenLineAndApplyEntry(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20]; Amount: Decimal; AccountType: Enum "Gen. Journal Account Type"; CurrencyCode: Code[10])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GeneralJournal: TestPage "General Journal";
    begin
        SelectGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);
        GeneralJournal.OpenView();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        GeneralJournal."Apply Entries".Invoke();
    end;

    local procedure CreateModifyGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType, AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Bal. Account No.", '');
        GenJournalLine.Modify(true);
    end;

    local procedure CreateAndPostPurchaseCreditMemo(var PurchaseLine: Record "Purchase Line"; DocumentNo: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseCreditMemoCopyDocument(PurchaseHeader, PurchaseLine."Buy-from Vendor No.", DocumentNo);
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindLast();
        PurchaseLine.Validate("Direct Unit Cost", PurchaseLine."Direct Unit Cost" + LibraryRandom.RandDec(10, 2));
        PurchaseLine.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateAndPostSalesInvoice(var SalesLine: Record "Sales Line"): Code[20]
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreatePairedPaymentAndPostedCrMemoWithPmtDiscGracePeriod(var GenJnlLine: Record "Gen. Journal Line"; var CrMemoNo: Code[20]; AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; PaymentTerms: Record "Payment Terms"; Amount: Decimal)
    var
        PaymentAmount: Decimal;
    begin
        CreateGenJournalLineWithCurrencyCode(
          GenJnlLine, AccNo, '', GenJnlLine."Document Type"::"Credit Memo", Amount,
          WorkDate(), AccType);
        LibraryERM.PostGeneralJnlLine(GenJnlLine);
        CrMemoNo := GenJnlLine."Document No.";
        PaymentAmount :=
          Abs(GenJnlLine.Amount - Round(GenJnlLine.Amount * PaymentTerms."Discount %" / 100)) + LibraryRandom.RandDec(100, 2);

        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJnlLine, GenJnlLine."Document Type"::Payment, AccType, GenJnlLine."Account No.", PaymentAmount);
        GenJnlLine.Validate("Posting Date",
          CalcDate(Format(PaymentTerms."Discount Date Calculation") + '+' + LibraryPmtDiscSetup.GetPmtDiscGracePeriod(), WorkDate()));
        GenJnlLine.Modify(true);
    end;

    local procedure CalcHalfToleranceAmount(LineAmount: Decimal; TolerancePct: Decimal; CurrencyCode: Code[10]) Amount: Decimal
    begin
        Amount := LineAmount - (LineAmount * 0.5 * TolerancePct / 100);
        Amount := Round(LibraryERM.ConvertCurrency(Amount, '', CurrencyCode, WorkDate()));
    end;

    local procedure CreateAndPostPurchaseInvoice(var PurchaseLine: Record "Purchase Line"): Code[20]
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateCurrencyAndExchangeRate(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);

        // Create Currency Exchange Rate.
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreatePaymentTerms(var PaymentTerms: Record "Payment Terms")
    var
        DiscountDateCalculation: DateFormula;
    begin
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        Evaluate(DiscountDateCalculation, Format(LibraryRandom.RandInt(5)) + 'D');
        PaymentTerms.Validate("Discount Date Calculation", DiscountDateCalculation);
        PaymentTerms.Validate("Discount %", LibraryRandom.RandIntInRange(3, 10));
        PaymentTerms.Modify(true);
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        exit(Vendor."No.");
    end;

    local procedure CreateCustomerWithPmtTerms(PaymentTermsCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Terms Code", PaymentTermsCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateVendorWithPmtTerms(PaymentTermsCode: Code[10]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Payment Terms Code", PaymentTermsCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateGeneralJournalTemplate(var GenJournalTemplate: Record "Gen. Journal Template"; GenJournalTemplateType: Enum "Gen. Journal Template Type")
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, GenJournalTemplateType);
        GenJournalTemplate.Modify(true);
    end;

    local procedure CustomerInvoiceAndPayment(var GenJournalLine: Record "Gen. Journal Line"; CustomerNo: Code[20]; GLAccountNo: Code[20]; TolerancePct: Decimal) ToleranceAmount: Decimal
    begin
        // Post Invoice and create Payment line with Random Amount.
        CreateModifyGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, CustomerNo,
          LibraryRandom.RandDec(1000, 2));
        CreateModifyGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type", GenJournalLine."Account Type"::"G/L Account", GLAccountNo, -GenJournalLine.Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        ToleranceAmount := GenJournalLine.Amount * TolerancePct / 100;

        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, CustomerNo,
          (GenJournalLine.Amount - ToleranceAmount));
        Commit();
    end;

    local procedure CreatePaymentTermsWithDiscOnCreditMemo(): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        // Create a Payment term code with Calc. Pmt. Disc. On grace Period.
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        PaymentTerms.Validate("Calc. Pmt. Disc. on Cr. Memos", true);
        PaymentTerms.Modify(true);
        exit(PaymentTerms.Code);
    end;

    local procedure CreateAndUpdateCurrencyExchangeRate(CurrencyCode: Code[10]) CurrencyAdjustFactor: Decimal
    var
        CurrencyExchRateAmount: Decimal;
    begin
        CurrencyAdjustFactor := LibraryRandom.RandDec(2, 2);
        CurrencyExchRateAmount := LibraryRandom.RandInt(100);
        CreateCurrencyExchangeRate(WorkDate(), CurrencyCode, CurrencyExchRateAmount, CurrencyAdjustFactor);
        CreateCurrencyExchangeRate(CalcDate('<1D>', WorkDate()), CurrencyCode, CurrencyExchRateAmount, 1);
        exit(CurrencyAdjustFactor);
    end;

    local procedure CreateCurrencyExchangeRate(StartingDate: Date; CurrencyCode: Code[10]; CurrExchangeRateAmount: Decimal; CurrAdjustmentFactor: Decimal)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        LibraryERM.CreateExchRate(CurrencyExchangeRate, CurrencyCode, StartingDate);
        CurrencyExchangeRate.Validate("Exchange Rate Amount", CurrExchangeRateAmount);
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", CurrExchangeRateAmount);
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", CurrExchangeRateAmount * CurrAdjustmentFactor);
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", CurrExchangeRateAmount * CurrAdjustmentFactor);
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure CreateGenJournalLineWithCurrencyCode(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20]; CurrencyCode: Code[10]; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal; PostingDate: Date; AccountType: Enum "Gen. Journal Account Type")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine,
          GenJournalBatch."Journal Template Name",
          GenJournalBatch.Name, DocumentType, AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());
        GenJournalLine.Modify(true);
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Recurring, false);
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::General);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);

        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        GenJournalBatch.Modify(true);
    end;

    local procedure CreateCurrencyAndUpdateCurrencyExchangeRate(var CurrencyCode: Code[10])
    begin
        CurrencyCode := CreateCurrencyAndExchangeRate();
        UpdateCurrencyExchangeRate(CurrencyCode);
    end;

    local procedure CreateCurrencyWithGainLossAccount(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
        exit(Currency.Code);
    end;

    local procedure CreateRefundJournalLineAppliesToCrMemo(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; AppliesToDocNo: Code[20]; Amount: Decimal)
    var
        BankAccount: Record "Bank Account";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        SelectGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Refund,
          AccountType, AccountNo, Amount);
        LibraryERM.FindBankAccount(BankAccount);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", BankAccount."No.");
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::"Credit Memo");
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateCashReceiptJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20]; PostingDate: Date)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::"Cash Receipts");
        if not GenJournalTemplate.FindFirst() then
            CreateGeneralJournalTemplate(GenJournalTemplate, GenJournalTemplate.Type::"Cash Receipts");
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        LibraryERM.CreateGeneralJnlLineWithBalAcc(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, AccountNo,
            GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), 0);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify(true);
        Commit();
    end;

    local procedure CreateAndPostGenJnlLineWithPaymentTerms(var GenJnlLine: Record "Gen. Journal Line"; DocType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; PaymentTermsCode: Code[10]; InvAmount: Decimal)
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJnlLine, DocType, AccountType, AccountNo, InvAmount);
        GenJnlLine.Validate("Payment Terms Code", PaymentTermsCode);
        GenJnlLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJnlLine);
    end;

    local procedure CreateFullVATPostingSetupWithAdjForPmtDisc(var VATPostingSetup: Record "VAT Posting Setup"; GenPostingType: Enum "General Posting Type")
    var
        GLAccount: Record "G/L Account";
        GLAccNo: Code[20];
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Full VAT", LibraryRandom.RandIntInRange(10, 25));
        GLAccNo := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GenPostingType);
        case GenPostingType of
            GLAccount."Gen. Posting Type"::Sale:
                VATPostingSetup.Validate("Sales VAT Account", GLAccNo);
            GLAccount."Gen. Posting Type"::Purchase:
                VATPostingSetup.Validate("Purchase VAT Account", GLAccNo);
        end;
        VATPostingSetup.Validate("Adjust for Payment Discount", true);
        VATPostingSetup.Modify(true);
    end;

    local procedure CreatePostSalesInvoiceCrMemoAndOpenPmtJournal(var GeneralJournal: TestPage "General Journal"; var PmtDiscAmount: Decimal; PmtAmountDifference: Decimal)
    var
        PaymentTerms: Record "Payment Terms";
        GenJournalLine: Record "Gen. Journal Line";
        InvAmount: Decimal;
        CrMemoAmount: Decimal;
        PmtAmount: Decimal;
    begin
        Initialize();
        CreatePaymentTerms(PaymentTerms);

        InvAmount := LibraryRandom.RandDecInRange(1000, 2000, 2);
        PmtDiscAmount := Round(InvAmount * PaymentTerms."Discount %" / 100);
        CrMemoAmount := Round(InvAmount / LibraryRandom.RandIntInRange(3, 5));
        PmtAmount := InvAmount - CrMemoAmount - PmtDiscAmount + PmtAmountDifference;

        // Posted Invoice
        CreateAndPostGenJnlLineWithPaymentTerms(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer,
          LibrarySales.CreateCustomerNo(), PaymentTerms.Code, InvAmount);

        // Posted Credit Memo
        CreateAndPostGenJnlLineWithPaymentTerms(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Account Type"::Customer,
          GenJournalLine."Account No.", '', -CrMemoAmount);

        // Open Payment
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, GenJournalLine."Account No.", -PmtAmount);

        // Open payment journal
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        GeneralJournal.OpenEdit();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalLine."Journal Batch Name");
    end;

    local procedure CreatePostPurchaseInvoiceCrMemoAndOpenPmtJournal(var GeneralJournal: TestPage "General Journal"; var PmtDiscAmount: Decimal; PmtAmountDifference: Decimal)
    var
        PaymentTerms: Record "Payment Terms";
        GenJournalLine: Record "Gen. Journal Line";
        InvAmount: Decimal;
        CrMemoAmount: Decimal;
        PmtAmount: Decimal;
    begin
        Initialize();
        CreatePaymentTerms(PaymentTerms);

        InvAmount := LibraryRandom.RandDecInRange(1000, 2000, 2);
        PmtDiscAmount := Round(InvAmount * PaymentTerms."Discount %" / 100);
        CrMemoAmount := Round(InvAmount / LibraryRandom.RandIntInRange(3, 5));
        PmtAmount := InvAmount - CrMemoAmount - PmtDiscAmount + PmtAmountDifference;

        // Posted Invoice
        CreateAndPostGenJnlLineWithPaymentTerms(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor,
          LibraryPurchase.CreateVendorNo(), PaymentTerms.Code, -InvAmount);

        // Posted Credit Memo
        CreateAndPostGenJnlLineWithPaymentTerms(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Account Type"::Vendor,
          GenJournalLine."Account No.", '', CrMemoAmount);

        // Open Payment
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Vendor, GenJournalLine."Account No.", PmtAmount);

        // Open payment journal
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        GeneralJournal.OpenEdit();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalLine."Journal Batch Name");
    end;

    local procedure CreatePostInvAndCrMemoWithDiscAndOpenPmtJournal(var GeneralJournal: TestPage "General Journal"; var PmtDiscAmount: Decimal; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Sign: Integer)
    var
        PaymentTerms: Record "Payment Terms";
        GenJournalLine: Record "Gen. Journal Line";
        InvAmount: Decimal;
        CrMemoAmount: Decimal;
        PmtAmount: Decimal;
    begin
        Initialize();
        CreatePaymentTerms(PaymentTerms);
        PaymentTerms.Validate("Calc. Pmt. Disc. on Cr. Memos", true);
        PaymentTerms.Modify(true);

        InvAmount := LibraryRandom.RandDecInRange(1000, 2000, 2);
        CrMemoAmount := Round(InvAmount / LibraryRandom.RandIntInRange(3, 5));
        PmtDiscAmount := Round(InvAmount * PaymentTerms."Discount %" / 100) - Round(CrMemoAmount * PaymentTerms."Discount %" / 100);
        PmtAmount := InvAmount - CrMemoAmount - PmtDiscAmount;
        CreateAndPostGenJnlLineWithPaymentTerms(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, AccountType,
          AccountNo, PaymentTerms.Code, Sign * InvAmount);
        CreateAndPostGenJnlLineWithPaymentTerms(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", AccountType,
          GenJournalLine."Account No.", PaymentTerms.Code, -Sign * CrMemoAmount);
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment,
          AccountType, GenJournalLine."Account No.", -Sign * PmtAmount);
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        GeneralJournal.OpenEdit();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalLine."Journal Batch Name");
    end;

    local procedure CalcPurchPaymentAmount(DocumentNo: Code[20]): Decimal
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        VendLedgEntry.SetRange("Document No.", DocumentNo);
        VendLedgEntry.FindLast();
        VendLedgEntry.CalcFields("Remaining Amount");
        exit(VendLedgEntry."Remaining Amount" - VendLedgEntry."Max. Payment Tolerance");
    end;

    local procedure CalcSalesPaymentAmount(DocumentNo: Code[20]): Decimal
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgEntry.SetRange("Document No.", DocumentNo);
        CustLedgEntry.FindLast();
        CustLedgEntry.CalcFields("Remaining Amount");
        exit(CustLedgEntry."Remaining Amount" - CustLedgEntry."Max. Payment Tolerance");
    end;

    local procedure PostInvAndPmtGeneralJnlLines(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; InvAmount: Decimal; PmtAmount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        SelectGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          AccountType, AccountNo, InvAmount);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          AccountType, GenJournalLine."Account No.", PmtAmount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure PostSalesInvoiceWithPmtTermsAndVAT(var SalesLine: Record "Sales Line"; VATPostingSetup: Record "VAT Posting Setup"; GLAccNo: Code[20]): Code[20]
    var
        PaymentTerms: Record "Payment Terms";
        SalesHeader: Record "Sales Header";
    begin
        CreatePaymentTerms(PaymentTerms);
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Invoice,
          LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        SalesHeader.Validate("Payment Terms Code", PaymentTerms.Code);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccNo, LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        UpdateGenPostingSetupWithPmtDiscAcc(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure PostPurchInvoiceWithPmtTermsAndVAT(var PurchLine: Record "Purchase Line"; VATPostingSetup: Record "VAT Posting Setup"; GLAccNo: Code[20]): Code[20]
    var
        PaymentTerms: Record "Payment Terms";
        PurchHeader: Record "Purchase Header";
    begin
        CreatePaymentTerms(PaymentTerms);
        LibraryPurchase.CreatePurchHeader(
          PurchHeader, PurchHeader."Document Type"::Invoice,
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        PurchHeader.Validate("Payment Terms Code", PaymentTerms.Code);
        PurchHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchLine, PurchHeader, PurchLine.Type::"G/L Account", GLAccNo, LibraryRandom.RandDec(10, 2));
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchLine.Modify(true);
        UpdateGenPostingSetupWithPmtDiscAcc(PurchLine."Gen. Bus. Posting Group", PurchLine."Gen. Prod. Posting Group");
        exit(LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true));
    end;

    local procedure PostPaymentWithAppliedToId(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal): Code[20]
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJnlLine, GenJnlLine."Document Type"::Payment, AccountType, AccountNo, Amount);
        GenJnlLine.Validate("Applies-to ID", UserId);
        GenJnlLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJnlLine);
        exit(GenJnlLine."Document No.");
    end;

    local procedure PostInvoiceAndCreatePaymentForCustomerWithSpecificName(var GenJournalLine: Record "Gen. Journal Line"; var InvoiceNo: Code[20]; CustomerName: Text)
    var
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
        AppliesToDocAmount: Decimal;
        ApplyingAmount: Decimal;
    begin
        AppliesToDocAmount := CreateAndPostInvoiceOfGenJournalLineForCustomer(GenJournalLine, PaymentTerms);
        InvoiceNo := GenJournalLine."Document No.";
        Customer.Get(GenJournalLine."Account No.");
        Customer.Validate(Name, CopyStr(CustomerName, 1, MaxStrLen(Customer.Name)));
        Customer.Modify(true);

        ApplyingAmount := -CalcHalfToleranceAmount(AppliesToDocAmount, LibraryPmtDiscSetup.GetPmtTolerancePct(), '');
        CreatePaymentOfGenJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Customer, GenJournalLine."Account No.",
          GenJournalLine."Bal. Account Type"::"G/L Account", GenJournalLine."Bal. Account No.",
          ApplyingAmount, CalcDate(PaymentTerms."Discount Date Calculation", WorkDate()), '');
    end;

    local procedure PostInvoiceAndCreatePaymentForVendorWithSpecificName(var GenJournalLine: Record "Gen. Journal Line"; var InvoiceNo: Code[20]; VendorName: Text)
    var
        Vendor: Record Vendor;
        PaymentTerms: Record "Payment Terms";
        AppliesToDocAmount: Decimal;
        ApplyingAmount: Decimal;
    begin
        AppliesToDocAmount := CreateAndPostInvoiceOfGenJournalLineForVendor(GenJournalLine, PaymentTerms);
        InvoiceNo := GenJournalLine."Document No.";
        Vendor.Get(GenJournalLine."Account No.");
        Vendor.Validate(Name, CopyStr(VendorName, 1, MaxStrLen(Vendor.Name)));
        Vendor.Modify(true);

        ApplyingAmount := CalcHalfToleranceAmount(AppliesToDocAmount, LibraryPmtDiscSetup.GetPmtTolerancePct(), '');
        CreatePaymentOfGenJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, GenJournalLine."Account No.",
          GenJournalLine."Bal. Account Type"::"G/L Account", GenJournalLine."Bal. Account No.",
          ApplyingAmount, CalcDate(PaymentTerms."Discount Date Calculation", WorkDate()), '');
    end;

    local procedure FindDetailedCustLedgEntry(CustomerNo: Code[20]; EntryType: Enum "Detailed CV Ledger Entry Type"): Boolean
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.SetRange("Customer No.", CustomerNo);
        DetailedCustLedgEntry.SetRange("Entry Type", EntryType);
        exit(not DetailedCustLedgEntry.IsEmpty);
    end;

    local procedure FindDetailedVendorLedgEntry(VendorNo: Code[20]; EntryType: Enum "Detailed CV Ledger Entry Type"): Boolean
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DetailedVendorLedgEntry.SetRange("Vendor No.", VendorNo);
        DetailedVendorLedgEntry.SetRange("Entry Type", EntryType);
        exit(not DetailedVendorLedgEntry.IsEmpty);
    end;

    local procedure PurchaseCreditMemoCopyDocument(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; DocumentNo: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VendorNo);
        LibraryPurchase.CopyPurchaseDocument(PurchaseHeader, "Sales Document Type From"::"Posted Invoice", DocumentNo, true, false);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
    end;

    local procedure SetApplnRoundingPrecision(NewApplnRoundingPrecision: Decimal)
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup.Validate("Appln. Rounding Precision", NewApplnRoundingPrecision);
        GLSetup.Modify(true);
    end;

    local procedure CalcInvPmtAmountWithPartialDiscount(var InvoiceAmount: Decimal; var PmtAmount: Decimal; var ExpectedBalance: Decimal; Sign: Integer; PmtDiscPct: Decimal; TolerancePct: Decimal)
    var
        PmtDiscWithPartialTolPct: Decimal;
    begin
        PmtDiscWithPartialTolPct := PmtDiscPct + TolerancePct / LibraryRandom.RandIntInRange(3, 5);
        InvoiceAmount := Sign * LibraryRandom.RandDec(100, 2);
        PmtAmount := Round(InvoiceAmount * PmtDiscWithPartialTolPct / 100 - InvoiceAmount);
        ExpectedBalance := Round(InvoiceAmount + PmtAmount - (InvoiceAmount * PmtDiscPct / 100));
    end;

    local procedure FindCustLedgEntry(var CustLedgEntry: Record "Cust. Ledger Entry"; DocType: Enum "Gen. Journal Document Type"; CustNo: Code[20])
    begin
        CustLedgEntry.SetRange("Document Type", DocType);
        CustLedgEntry.SetRange("Customer No.", CustNo);
        CustLedgEntry.FindFirst();
    end;

    local procedure FindVendLedgEntry(var VendLedgEntry: Record "Vendor Ledger Entry"; DocType: Enum "Gen. Journal Document Type"; VendNo: Code[20])
    begin
        VendLedgEntry.SetRange("Document Type", DocType);
        VendLedgEntry.SetRange("Vendor No.", VendNo);
        VendLedgEntry.FindFirst();
    end;

    local procedure FindGLEntry(var GLEntry: Record "G/L Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; GLAccountNo: Code[20])
    begin
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
    end;

    local procedure GetTransNoFromUnappliedCustDtldEntry(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]): Integer
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DtldCustLedgEntry.SetRange("Document Type", DocType);
        DtldCustLedgEntry.SetRange("Document No.", DocNo);
        DtldCustLedgEntry.SetRange(Unapplied, true);
        DtldCustLedgEntry.FindLast();
        exit(DtldCustLedgEntry."Transaction No.");
    end;

    local procedure GetTransNoFromUnappliedVendDtldEntry(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]): Integer
    var
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DtldVendLedgEntry.SetRange("Document Type", DocType);
        DtldVendLedgEntry.SetRange("Document No.", DocNo);
        DtldVendLedgEntry.SetRange(Unapplied, true);
        DtldVendLedgEntry.FindLast();
        exit(DtldVendLedgEntry."Transaction No.");
    end;

    local procedure RunChangePaymentTolerance(AllCurrency: Boolean; CurrencyCode: Code[10]; PaymentTolerancePercent: Decimal; MaxPaymentToleranceAmount: Decimal)
    var
        ChangePaymentTolerance: Report "Change Payment Tolerance";
    begin
        Clear(ChangePaymentTolerance);
        ChangePaymentTolerance.InitializeRequest(AllCurrency, CurrencyCode, PaymentTolerancePercent, MaxPaymentToleranceAmount);
        ChangePaymentTolerance.UseRequestPage(false);
        ChangePaymentTolerance.Run();
    end;

    local procedure InvokeApplyEntriesWithPmtToleranceInGeneralJournalPage(TemplateName: Code[10]; BatchName: Code[10])
    var
        GeneralJournal: TestPage "General Journal";
    begin
        LibraryVariableStorage.Enqueue(TemplateName);
        LibraryVariableStorage.Enqueue(PostingAction::"Payment Tolerance Accounts");
        GeneralJournal.OpenEdit();
        GeneralJournal.CurrentJnlBatchName.SetValue(BatchName);
        GeneralJournal."Apply Entries".Invoke();
    end;

    local procedure SalesCreditMemoCopyDocument(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; DocumentNo: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CustomerNo);
        LibrarySales.CopySalesDocument(SalesHeader, "Sales Document Type From"::"Posted Invoice", DocumentNo, true, false);
    end;

    local procedure SelectGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    local procedure SetPmtTolerance(PaymentToleranceWarning: Boolean; PmtDiscToleranceWarning: Boolean; TolerancePct: Decimal)
    begin
        LibraryPmtDiscSetup.SetPmtToleranceWarning(PaymentToleranceWarning);
        LibraryPmtDiscSetup.SetPmtDiscToleranceWarning(PmtDiscToleranceWarning);
        RunChangePaymentTolerance(true, '', TolerancePct, 0);
    end;

    local procedure SetPmtToleranceWithMaxAmount(PaymentToleranceWarning: Boolean; PmtDiscToleranceWarning: Boolean; TolerancePct: Decimal; MaxAmount: Decimal)
    begin
        LibraryPmtDiscSetup.SetPmtToleranceWarning(PaymentToleranceWarning);
        LibraryPmtDiscSetup.SetPmtDiscToleranceWarning(PmtDiscToleranceWarning);
        RunChangePaymentTolerance(true, '', TolerancePct, MaxAmount);
    end;

    local procedure SetPmtToleranceWithGracePeriod()
    begin
        LibraryPmtDiscSetup.SetPmtToleranceWarning(true);
        LibraryPmtDiscSetup.SetPmtDiscToleranceWarning(true);
        LibraryPmtDiscSetup.SetPmtDiscGracePeriodByText('5D');
        RunChangePaymentTolerance(false, '', LibraryRandom.RandDecInRange(1, 2, 2), LibraryRandom.RandDecInRange(1, 4, 2));
    end;

    local procedure SetupTolerancePmtDiscTolScenario(var PaymentTerms: Record "Payment Terms")
    begin
        LibraryPmtDiscSetup.SetPmtDiscToleranceWarning(true);
        LibraryPmtDiscSetup.SetPmtDiscGracePeriodByText('<' + Format(LibraryRandom.RandInt(5)) + 'D>');
        RunChangePaymentTolerance(true, '', LibraryRandom.RandIntInRange(3, 5), LibraryRandom.RandDecInDecimalRange(10, 20, 2));

        SetPmtTolerance(false, true, LibraryRandom.RandIntInRange(5, 10));
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, true);
    end;

    local procedure SetupMaxPmtTolAmountLCYAndFCY(var MaxPmtTolAmount: Decimal; var MaxPmtTolAmountLCY: Decimal; var CurrencyCode: Code[10])
    var
        ExchangeRateAmount: Decimal;
    begin
        LibraryPmtDiscSetup.SetPmtToleranceWarning(true);
        ExchangeRateAmount := LibraryRandom.RandIntInRange(3, 5);
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), ExchangeRateAmount, ExchangeRateAmount);

        MaxPmtTolAmountLCY := LibraryRandom.RandDecInRange(1000, 2000, 2);
        MaxPmtTolAmount := LibraryERM.ConvertCurrency(MaxPmtTolAmountLCY, '', CurrencyCode, WorkDate());
        RunChangePaymentTolerance(false, '', 0, MaxPmtTolAmount);
        RunChangePaymentTolerance(false, CurrencyCode, 0, MaxPmtTolAmount);
    end;

    local procedure SetCustLedgerEntryAppliesToID(CustomerNo: Code[20]; PostedDocType: Enum "Gen. Journal Document Type"; PostedDocNo: Code[20]; AppliesToID: Code[50]; AmountToApply: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, PostedDocType, PostedDocNo);
        CustLedgerEntry.Validate("Applies-to ID", AppliesToID);
        CustLedgerEntry.Validate("Amount to Apply", AmountToApply);
        CustLedgerEntry.Modify(true);
    end;

    local procedure SetVendLedgerEntryAppliesToID(VendorNo: Code[20]; PostedDocType: Enum "Gen. Journal Document Type"; PostedDocNo: Code[20]; AppliesToID: Code[50]; AmountToApply: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, PostedDocType, PostedDocNo);
        VendorLedgerEntry.Validate("Applies-to ID", AppliesToID);
        VendorLedgerEntry.Validate("Amount to Apply", AmountToApply);
        VendorLedgerEntry.Modify(true);
    end;

    local procedure UpdateGenPostingSetupWithPmtDiscAcc(GenBusPostGroupCode: Code[20]; GenProdPostGroupCode: Code[20])
    var
        GenPostingSetup: Record "General Posting Setup";
    begin
        GenPostingSetup.Get(GenBusPostGroupCode, GenProdPostGroupCode);
        GenPostingSetup."Sales Pmt. Disc. Debit Acc." := LibraryERM.CreateGLAccountNo();
        GenPostingSetup."Sales Pmt. Disc. Credit Acc." := LibraryERM.CreateGLAccountNo();
        GenPostingSetup."Sales Pmt. Tol. Debit Acc." := LibraryERM.CreateGLAccountNo();
        GenPostingSetup."Sales Pmt. Tol. Credit Acc." := LibraryERM.CreateGLAccountNo();
        GenPostingSetup."Purch. Pmt. Disc. Debit Acc." := LibraryERM.CreateGLAccountNo();
        GenPostingSetup."Purch. Pmt. Disc. Credit Acc." := LibraryERM.CreateGLAccountNo();
        GenPostingSetup."Purch. Pmt. Tol. Debit Acc." := LibraryERM.CreateGLAccountNo();
        GenPostingSetup."Purch. Pmt. Tol. Credit Acc." := LibraryERM.CreateGLAccountNo();
        GenPostingSetup.Modify(true);
    end;

    local procedure UpdateCurrencyExchangeRate(CurrencyCode: Code[10])
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        CurrencyExchangeRate.FindFirst();
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", 1);
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", 1);
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure SetupGenJnlLineForApplication(var GenJournalLine: Record "Gen. Journal Line"; PostingDate: Date; AppliesToDocType: Enum "Gen. Journal Document Type"; AppliesToDocNo: Code[20])
    begin
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Applies-to Doc. Type", AppliesToDocType);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.Modify(true);
    end;

    local procedure VerifyGLEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; GLAccountNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        FindGLEntry(GLEntry, DocumentType, DocumentNo, GLAccountNo);
        Assert.AreNearlyEqual(GLEntry.Amount, Round(Amount), LibraryERM.GetAmountRoundingPrecision(), AmountVerificationMsg);
    end;

    local procedure VerifyVATAmountInGLEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; GLAccountNo: Code[20]; ExpectedAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        FindGLEntry(GLEntry, DocumentType, DocumentNo, GLAccountNo);
        GLEntry.TestField("VAT Amount", ExpectedAmount);
    end;

    local procedure VerifyGLEntryByTransNo(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; TransNo: Integer; GLAccountNo: Code[20]; ExpectedAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Transaction No.", TransNo);
        FindGLEntry(GLEntry, DocumentType, DocumentNo, GLAccountNo);
        GLEntry.TestField(Amount, ExpectedAmount);
    end;

    local procedure VerifyCustomerPaymentRemainingAmountIsZero(DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.CalcFields("Remaining Amount");
        CustLedgerEntry.TestField("Remaining Amount", 0);
    end;

    local procedure VerifyVendorPaymentRemainingAmountIsZero(DocumentNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry.CalcFields("Remaining Amount");
        VendorLedgerEntry.TestField("Remaining Amount", 0);
    end;

    local procedure VerifyRefundAndCreditMemoRemainingAmountIsZero(CustomerCode: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerCode);
        CustLedgerEntry.SetAutoCalcFields("Remaining Amount");
        CustLedgerEntry.FindSet();
        repeat
            CustLedgerEntry.TestField("Remaining Amount", 0);
        until CustLedgerEntry.Next() = 0;
    end;

    local procedure VerifyInvoiceAndPaymentsRemainingAmountIsZero(VendorCode: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorCode);
        VendorLedgerEntry.SetAutoCalcFields("Remaining Amount");
        VendorLedgerEntry.FindSet();
        repeat
            VendorLedgerEntry.TestField("Remaining Amount", 0);
        until VendorLedgerEntry.Next() = 0;
    end;

    local procedure VerifyVendLedEntry(RemainingAmount: Decimal; DocumentNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Assert: Codeunit Assert;
    begin
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Invoice);
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.CalcFields("Remaining Amount");
        Assert.AreNearlyEqual(RemainingAmount, VendorLedgerEntry."Remaining Amount", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(
            AmountErrorMessage, VendorLedgerEntry.FieldCaption("Remaining Amount"), RemainingAmount, VendorLedgerEntry.TableCaption(),
            VendorLedgerEntry.FieldCaption("Entry No."), VendorLedgerEntry."Entry No."));
    end;

    local procedure VerifyVendorPayment(VendorNo: Code[20]; PaymentNo: Code[20]; ExpectedOrigAmount: Decimal; ExpectedAmount: Decimal; ExpectedRemAmount: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Payment, PaymentNo);
        VendorLedgerEntry.CalcFields("Original Amount", Amount, "Remaining Amount");
        VendorLedgerEntry.TestField("Original Amount", ExpectedOrigAmount);
        VendorLedgerEntry.TestField(Amount, ExpectedAmount);
        VendorLedgerEntry.TestField("Remaining Amount", ExpectedRemAmount);
    end;

    local procedure VerifyCustomerPayment(CustomerNo: Code[20]; PaymentNo: Code[20]; ExpectedOrigAmount: Decimal; ExpectedAmount: Decimal; ExpectedRemAmount: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, PaymentNo);
        CustLedgerEntry.CalcFields("Original Amount", Amount, "Remaining Amount");
        CustLedgerEntry.TestField("Original Amount", ExpectedOrigAmount);
        CustLedgerEntry.TestField(Amount, ExpectedAmount);
        CustLedgerEntry.TestField("Remaining Amount", ExpectedRemAmount);
    end;

    local procedure VerifyVendorInvoiceMaxPaymentToleranceAndRemAmount(VendorNo: Code[20]; InvoiceNo: Code[20]; ExpectedMaxPaymentTolerance: Decimal; ExpectedRemAmount: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, InvoiceNo);
        VendorLedgerEntry.CalcFields("Remaining Amount");
        VendorLedgerEntry.TestField("Max. Payment Tolerance", ExpectedMaxPaymentTolerance);
        VendorLedgerEntry.TestField("Remaining Amount", ExpectedRemAmount);
    end;

    local procedure VerifyCustomerInvoiceMaxPaymentToleranceAndRemAmount(CustomerNo: Code[20]; InvoiceNo: Code[20]; ExpectedMaxPaymentTolerance: Decimal; ExpectedRemAmount: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, InvoiceNo);
        CustLedgerEntry.CalcFields("Remaining Amount");
        CustLedgerEntry.TestField("Max. Payment Tolerance", ExpectedMaxPaymentTolerance);
        CustLedgerEntry.TestField("Remaining Amount", ExpectedRemAmount);
    end;

    local procedure VerifyVendorInvoiceAndPayment(VendorNo: Code[20]; InvoiceNo: Code[20]; PaymentNo: Code[20]; ExpectedInvMaxPaymentTolerance: Decimal; ExpectedInvRemAmount: Decimal; ExpectedPmtOrigAmount: Decimal; ExpectedPmtAmount: Decimal; ExpectedPmtRemAmount: Decimal)
    begin
        VerifyVendorInvoiceMaxPaymentToleranceAndRemAmount(VendorNo, InvoiceNo, ExpectedInvMaxPaymentTolerance, ExpectedInvRemAmount);
        VerifyVendorPayment(VendorNo, PaymentNo, ExpectedPmtOrigAmount, ExpectedPmtAmount, ExpectedPmtRemAmount);
    end;

    local procedure VerifyCustomerInvoiceAndPayment(CustomerNo: Code[20]; InvoiceNo: Code[20]; PaymentNo: Code[20]; ExpectedInvMaxPaymentTolerance: Decimal; ExpectedInvRemAmount: Decimal; ExpectedPmtOrigAmount: Decimal; ExpectedPmtAmount: Decimal; ExpectedPmtRemAmount: Decimal)
    begin
        VerifyCustomerInvoiceMaxPaymentToleranceAndRemAmount(CustomerNo, InvoiceNo, ExpectedInvMaxPaymentTolerance, ExpectedInvRemAmount);
        VerifyCustomerPayment(CustomerNo, PaymentNo, ExpectedPmtOrigAmount, ExpectedPmtAmount, ExpectedPmtRemAmount);
    end;

    local procedure VerifyBalanceAndPmtDiscEnqueuedFromHandler(Balance: Decimal; PmtDisc: Decimal)
    begin
        // Values enqueued from ApplyCustomerEntriesHandler or ApplyVendorEntriesHandler
        Assert.AreEqual(Balance, LibraryVariableStorage.DequeueDecimal(), 'Balance is incorrect');
        Assert.AreEqual(PmtDisc, LibraryVariableStorage.DequeueDecimal(), 'Payment discount is incorrect');
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure CreateBankPmtReconcWithLine(BankAcc: Record "Bank Account"; var BankAccRecon: Record "Bank Acc. Reconciliation"; var BankAccReconLine: Record "Bank Acc. Reconciliation Line"; TransactionDate: Date; StmtLineAmt: Decimal)
    begin
        Clear(BankAccRecon);
        Clear(BankAccReconLine);

        // Create Bank Rec Header
        LibraryERM.CreateBankAccReconciliation(
          BankAccRecon, BankAcc."No.", BankAccRecon."Statement Type"::"Payment Application");
        LibraryERM.CreateBankAccReconciliationLn(BankAccReconLine, BankAccRecon);

        // Create Bank Rec Line
        BankAccReconLine.Validate("Transaction Date", TransactionDate);
        BankAccReconLine.Validate("Statement Amount", StmtLineAmt);
        BankAccReconLine.Modify(true);
    end;

    local procedure MatchBankReconLineManually(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    var
        PaymentReconciliationJournal: TestPage "Payment Reconciliation Journal";
    begin
        PaymentReconciliationJournal.OpenEdit();
        PaymentReconciliationJournal.GotoRecord(BankAccReconciliationLine);
        PaymentReconciliationJournal.ApplyEntries.Invoke();
    end;

    local procedure UpdateBankAccRecStmEndingBalance(var BankAccRecon: Record "Bank Acc. Reconciliation"; NewStmEndingBalance: Decimal)
    begin
        BankAccRecon.Validate("Statement Ending Balance", NewStmEndingBalance);
        BankAccRecon.Modify();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntryPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries."Set Applies-to ID".Invoke();
        ApplyCustomerEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyPostCustomerEntryPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries."Set Applies-to ID".Invoke();
        ApplyCustomerEntries."Post Application".Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyVendorEntryPageHandler(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    begin
        ApplyVendorEntries.ActionSetAppliesToID.Invoke();
        ApplyVendorEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyPostVendorEntryPageHandler(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    begin
        ApplyVendorEntries.ActionSetAppliesToID.Invoke();
        ApplyVendorEntries.ActionPostApplication.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure UnapplyCustomerEntryPageHandler(var UnapplyCustomerEntries: TestPage "Unapply Customer Entries")
    begin
        UnapplyCustomerEntries.Unapply.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure UnapplyVendorEntryPageHandler(var UnapplyVendorEntries: TestPage "Unapply Vendor Entries")
    begin
        UnapplyVendorEntries.Unapply.Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmNoHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustEntryPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries."Set Applies-to ID".Invoke();
        ApplyCustomerEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesPageHandlerSelectLastDocument(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries.Last();
        ApplyCustomerEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PaymentToleranceWarningHandler(var PaymentToleranceWarning: Page "Payment Tolerance Warning"; var Response: Action)
    begin
        // Modal Page Handler for Payment Tolerance Warning.
        PaymentToleranceWarning.InitializeOption(LibraryVariableStorage.DequeueInteger());
        Response := ACTION::Yes;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PaymentToleranceWarningCheckValuesHandler(var PaymentToleranceWarning: TestPage "Payment Tolerance Warning")
    begin
        PaymentToleranceWarning.Posting.SetValue(LibraryVariableStorage.DequeueInteger());
        LibraryVariableStorage.Enqueue(PaymentToleranceWarning.ApplyingAmount.Value);
        LibraryVariableStorage.Enqueue(PaymentToleranceWarning.AppliedAmount.Value);
        LibraryVariableStorage.Enqueue(PaymentToleranceWarning.BalanceAmount.Value);
        PaymentToleranceWarning.Yes().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PaymentToleranceWarningNoHandler(var PaymentToleranceWarning: Page "Payment Tolerance Warning"; var Response: Action)
    begin
        Response := ACTION::No;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntryPageHandlerForMultipleDocument(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries.FILTER.SetFilter("Customer No.", LibraryVariableStorage.DequeueText());
        ApplyCustomerEntries."Set Applies-to ID".Invoke();
        ApplyCustomerEntries.Next();
        ApplyCustomerEntries."Set Applies-to ID".Invoke();
        Commit();
        ApplyCustomerEntries."Post Application".Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyVendorEntryPageHandlerForMultipleDocument(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    begin
        ApplyVendorEntries.FILTER.SetFilter("Vendor No.", LibraryVariableStorage.DequeueText());
        ApplyVendorEntries.ActionSetAppliesToID.Invoke();
        ApplyVendorEntries.Next();
        ApplyVendorEntries.ActionSetAppliesToID.Invoke();
        Commit();
        ApplyVendorEntries.ActionPostApplication.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SetAppliesToIDAndCheckBalanceOnCustEntriesHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries.FILTER.SetFilter("Customer No.", LibraryVariableStorage.DequeueText());
        ApplyCustomerEntries."Set Applies-to ID".Invoke();
        ApplyCustomerEntries.ControlBalance.AssertEquals(LibraryVariableStorage.DequeueDecimal());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SetAppliesToIDAndCheckBalanceOnVendEntriesHandler(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    begin
        ApplyVendorEntries.FILTER.SetFilter("Vendor No.", LibraryVariableStorage.DequeueText());
        ApplyVendorEntries.ActionSetAppliesToID.Invoke();
        ApplyVendorEntries.ControlBalance.AssertEquals(LibraryVariableStorage.DequeueDecimal());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostApplicationHandler(var PostApplication: TestPage "Post Application")
    begin
        PostApplication.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PaymentDiscToleranceWarningHandler(var PaymentDiscToleranceWarning: Page "Payment Disc Tolerance Warning"; var Response: Action)
    begin
        // Modal Page Handler for Payment Discount Tolerance Warning.
        PaymentDiscToleranceWarning.InitializeNewPostingAction(LibraryVariableStorage.DequeueInteger());
        Response := ACTION::Yes
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PaymentDiscToleranceWarningCheckNameHandler(var PaymentDiscToleranceWarning: TestPage "Payment Disc Tolerance Warning")
    begin
        // Modal Page Handler for Payment Discount Tolerance Warning.
        LibraryVariableStorage.Enqueue(PaymentDiscToleranceWarning.AccountName.Value);
        PaymentDiscToleranceWarning.Yes().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PaymentToleranceWarningCheckNameHandler(var PaymentToleranceWarning: TestPage "Payment Tolerance Warning")
    begin
        PaymentToleranceWarning.Posting.SetValue(LibraryVariableStorage.DequeueInteger());
        LibraryVariableStorage.Enqueue(PaymentToleranceWarning.AccountName.Value);
        PaymentToleranceWarning.Yes().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries."Set Applies-to ID".Invoke();
        ApplyCustomerEntries.Next();
        ApplyCustomerEntries."Set Applies-to ID".Invoke();
        // Enqueue values to verify in test case
        LibraryVariableStorage.Enqueue(ApplyCustomerEntries.ControlBalance.Value);
        LibraryVariableStorage.Enqueue(ApplyCustomerEntries.PmtDiscountAmount.Value);
        ApplyCustomerEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesAndVerifyPmtDiscHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries."Set Applies-to ID".Invoke();
        ApplyCustomerEntries.Next();
        ApplyCustomerEntries."Set Applies-to ID".Invoke();
        ApplyCustomerEntries.PmtDiscountAmount.AssertEquals(LibraryVariableStorage.DequeueDecimal());
        ApplyCustomerEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyVendorEntriesHandler(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    begin
        ApplyVendorEntries.ActionSetAppliesToID.Invoke();
        ApplyVendorEntries.Next();
        ApplyVendorEntries.ActionSetAppliesToID.Invoke();
        // Enqueue values to verify in test case
        LibraryVariableStorage.Enqueue(ApplyVendorEntries.ControlBalance.Value);
        LibraryVariableStorage.Enqueue(ApplyVendorEntries.PmtDiscountAmount.Value);
        ApplyVendorEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyVendorEntriesAndVerifyPmtDiscHandler(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    begin
        ApplyVendorEntries.ActionSetAppliesToID.Invoke();
        ApplyVendorEntries.Next();
        ApplyVendorEntries.ActionSetAppliesToID.Invoke();
        ApplyVendorEntries.PmtDiscountAmount.AssertEquals(LibraryVariableStorage.DequeueDecimal());

        ApplyVendorEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GenJnlTemplateHandler(var GeneralJournalTemplateList: TestPage "General Journal Template List")
    begin
        GeneralJournalTemplateList.FILTER.SetFilter(Name, LibraryVariableStorage.DequeueText());
        GeneralJournalTemplateList.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // This is a dummy Handler
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GeneralJournalTemplateListModalPageHandler(var GeneralJournalTemplateList: TestPage "General Journal Template List")
    begin
        GeneralJournalTemplateList.GotoKey(LibraryVariableStorage.DequeueText());
        GeneralJournalTemplateList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustEntriesOKPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostAndReconcilePageHandler(var PostPmtsAndRecBankAcc: TestPage "Post Pmts and Rec. Bank Acc.")
    begin
        PostPmtsAndRecBankAcc.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PaymentApplicationModalPageHandler(var PaymentApplication: TestPage "Payment Application")
    var
        PaymentApplicationProposal: Record "Payment Application Proposal";
    begin
        PaymentApplication.FILTER.SetFilter("Account Type", LibraryVariableStorage.DequeueText());
        PaymentApplication.FILTER.SetFilter("Account No.", LibraryVariableStorage.DequeueText());
        PaymentApplication.FILTER.SetFilter("Document Type", Format(PaymentApplicationProposal."Document Type"::Invoice));
        PaymentApplication.FILTER.SetFilter("Document No.", LibraryVariableStorage.DequeueText());
        PaymentApplication.Applied.SetValue(true);
        PaymentApplication.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure PostAndReconcilePageStatementDateHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

