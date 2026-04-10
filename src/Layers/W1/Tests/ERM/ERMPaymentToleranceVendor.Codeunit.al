codeunit 134003 "ERM Payment Tolerance Vendor"
{
    Permissions = TableData "Vendor Ledger Entry" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Payment Tolerance] [Purchase]
        isInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryPmtDiscSetup: Codeunit "Library - Pmt Disc Setup";
        isInitialized: Boolean;
        PaymentToleranceError: Label 'The amount must be %1 in %2 %3 =%4.';
        RoundingMessage: Label '%1 must be %2 in %3 %4=%5.';

    [Test]
    [Scope('OnPrem')]
    procedure OvrPmtAndBfrDiscDateLCY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        InvAmount: Decimal;
        PmtAmount: Decimal;
        DiscountAmount: Decimal;
    begin
        // Check Payment Discount Amount, Addnl. Currency Amount after Posting Invoice, Payment Entries before Payment Discount Date.

        // Setup: Update General Ledger Setup. Compute Amounts to use them in General Journal Line. Create General Journal Lines for Invoice
        // and Payment and Post them with Random Values. Take Payment Amount more than Invoice Amount.
        Initialize();
        UpdateAddCurrencySetup();
        InvAmount := 10 * LibraryRandom.RandInt(100);
        PmtAmount := InvAmount + LibraryRandom.RandInt(10);
        DiscountAmount := GetDiscountAmount(InvAmount);
        CreateAndPostDocumentLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, -InvAmount, PmtAmount,
          '', '', CalcDate('<-1D>', GetDueDate()));

        // Apply Payment Over Invoice. Verify Discount Amount, Additional-Currency Amount in GL Entry.
        BeforeDiscountDateEntry(
          GenJournalLine."Document Type"::Payment, GenJournalLine."Document No.", DiscountAmount, -DiscountAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OvrRefAndBfrDiscDateFCY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyCode: Code[10];
        CrMemoAmount: Decimal;
        RefAmount: Decimal;
        DiscountAmountFCY: Decimal;
    begin
        // Check Payment Discount Amount, Addnl. Currency Amount after Posting Credit Memo, Refund Entries before Payment Discount Date.

        // Setup: Update General Ledger Setup. Compute Amounts to use them in General Journal Line. Create General Journal Lines for
        // Credit Memo and Refund and Post them with Random Values. Refund Amount is more than Credit Memo Amount.
        Initialize();
        CurrencyCode := UpdateAddCurrencySetup();
        CrMemoAmount := 10 * LibraryRandom.RandInt(100);
        RefAmount := CrMemoAmount + LibraryRandom.RandInt(10);
        DiscountAmountFCY := GetDiscountAmount(LibraryERM.ConvertCurrency(CrMemoAmount, CurrencyCode, '', WorkDate()));
        CreateAndPostDocumentLine(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund, CrMemoAmount, -RefAmount,
          CurrencyCode, CurrencyCode, CalcDate('<-1D>', GetDueDate()));

        // Apply Refund over Credit Memo. Verify Discount Amount, Additional-Currency Amount in GL Entry.
        BeforeDiscountDateEntry(
          GenJournalLine."Document Type"::Refund, GenJournalLine."Document No.", -GetDiscountAmount(CrMemoAmount),
          DiscountAmountFCY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OvrPmtAndBfrDiscDateMCr()
    var
        GenJournalLine: Record "Gen. Journal Line";
        InvAmount: Decimal;
        InvAmountLCY: Decimal;
        PmtAmountFCY: Decimal;
        CurrencyCode: Code[10];
        CurrencyCode2: Code[10];
        DiscountAmountLCY: Decimal;
    begin
        // Check Payment Discount Amount, Addnl. Currency Amount after Posting Invoice, Payment Entries before Payment Discount Date.

        // Setup: Create Two Currencies. Update General Ledger Setup, Create and  Post Invoice, Payment entries for Vendor through General
        // Journal Line with Random Values. Take Posting Date before Payment Discount Period.
        Initialize();
        CurrencyCode := UpdateAddCurrencySetup();
        CurrencyCode2 := CreateCurrency();
        InvAmount := 10 * LibraryRandom.RandInt(100);
        InvAmountLCY := LibraryERM.ConvertCurrency(InvAmount, CurrencyCode, '', WorkDate());
        DiscountAmountLCY := GetDiscountAmount(InvAmountLCY);
        PmtAmountFCY := LibraryERM.ConvertCurrency(InvAmountLCY, '', CurrencyCode2, WorkDate()) + LibraryRandom.RandInt(5);
        CreateAndPostDocumentLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, -InvAmount, PmtAmountFCY,
          CurrencyCode, CurrencyCode2, CalcDate('<-1D>', GetDueDate()));

        // Apply Payment on Invoice. Verify Discount Amount, Additional-Currency Amount in GL Entry.
        BeforeDiscountDateEntry(
          GenJournalLine."Document Type"::Payment, GenJournalLine."Document No.", GetDiscountAmount(InvAmount),
          -DiscountAmountLCY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EqlPmtAndBfrDiscDateLCY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        InvAmount: Decimal;
        DiscountAmount: Decimal;
    begin
        // Check Payment Discount Amount, Addnl. Currency Amount after Posting Invoice, Payment Entries before Payment Discount Date.

        // Setup: Update General Ledger Setup, Create and Post General Journal Lines for Payment and Invoice with Random Amounts.
        // Take posting date before Payment Discount Date.
        Initialize();
        UpdateAddCurrencySetup();
        InvAmount := 10 * LibraryRandom.RandInt(100);
        DiscountAmount := GetDiscountAmount(InvAmount);
        CreateAndPostDocumentLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, -InvAmount, InvAmount,
          '', '', CalcDate('<-1D>', GetDueDate()));

        // Apply Payment on Invoice. Verify Discount Amount and Additional-Currency Amount in GL Entry.
        BeforeDiscountDateEntry(
          GenJournalLine."Document Type"::Payment, GenJournalLine."Document No.", DiscountAmount, -DiscountAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtUndrInvAmtBfrDiscDtLCY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DeltaAssert: Codeunit "Delta Assert";
        InvAmount: Decimal;
        PmtAmount: Decimal;
        DiscountAmount: Decimal;
    begin
        // Check Payment Discount Amount, Addnl. Currency Amount after Posting Invoice, Less Payment before Payment Discount Date.

        // Setup: Update General Ledger Setup. Create and Post General Journal Lines for Invoice and Payment with Random Amounts.
        // Take Payment Amount less than Invoice Amount. Post Entries on a Date before Payment Discount Date.
        Initialize();
        UpdateAddCurrencySetup();
        ComputeUnderAmountForMinValue(InvAmount, PmtAmount);
        DiscountAmount := GetDiscountAmount(InvAmount);
        CreateAndPostDocumentLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, -InvAmount, PmtAmount,
          '', '', CalcDate('<-1D>', GetDueDate()));

        // Apply Payment on Invoice. Verify Discount Amount, Additional-Currency Amount in GL Entry.
        // Watch Expected Discount value calculated as per Delta amount.
        DeltaAssert.Init();
        WatchPaymentDiscountAmount(DeltaAssert, GenJournalLine."Document No.", DiscountAmount);

        // Exercise: Apply Payment/Refund Amount on Invoice/Credit Memo.
        ApplyAndPostVendorEntry(GenJournalLine."Document Type"::Payment, GenJournalLine."Document No.");

        // Verify: Verify Discount Amount and Additional-Currency Amount in GL Entry.
        DeltaAssert.Assert();
        VerifyRefundUnderInvoiceAmountBeforeDiscountDateFCY(-DiscountAmount, GenJournalLine."Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefUndrCrMAmtBfrDisDtFCY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DeltaAssert: Codeunit "Delta Assert";
        CurrencyCode: Code[10];
        CrMemoAmount: Decimal;
        CrMemoAmountFCY: Decimal;
        RefAmount: Decimal;
        DiscountAmountFCY: Decimal;
    begin
        // Check Payment Discount Amount, Addnl. Currency Amount after Posting Credit Memo, Less Refund before Payment Discount Date.

        // Setup: Update General Ledger Setup. Create and Post General Journal Lines for Credit Memo and Refund with Random Amounts.
        // Take Refund Amount always greater than Maximum Payment Tolerance Amount. Post Entries on a Date before Payment Discount Date.
        Initialize();
        CurrencyCode := UpdateAddCurrencySetup();
        ComputeUnderAmountForMaxValue(CrMemoAmount, RefAmount);
        CrMemoAmountFCY := LibraryERM.ConvertCurrency(CrMemoAmount, CurrencyCode, '', WorkDate());
        DiscountAmountFCY := GetDiscountAmount(CrMemoAmountFCY);
        CreateAndPostDocumentLine(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund, CrMemoAmount, -RefAmount,
          CurrencyCode, CurrencyCode, CalcDate('<-1D>', GetDueDate()));

        // Apply Refund on Credit Memo. Verify Discount Amount, Additional-Currency Amount in GL Entry.
        // Watch Expected Discount value calculated as per Delta amount.
        DeltaAssert.Init();
        WatchPaymentDiscountAmount(DeltaAssert, GenJournalLine."Document No.", -GetDiscountAmount(CrMemoAmount));

        // Exercise: Apply Payment/Refund Amount on Invoice/Credit Memo.
        ApplyAndPostVendorEntry(GenJournalLine."Document Type"::Refund, GenJournalLine."Document No.");

        // Verify: Verify Discount Amount and Additional-Currency Amount in GL Entry.
        DeltaAssert.Assert();
        VerifyRefundUnderCreditMemoAmountBeforeDiscountDateFCY(DiscountAmountFCY, GenJournalLine."Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtUndrInvAmtBfrDtMCr()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyCode: Code[10];
        CurrencyCode2: Code[10];
        InvAmount: Decimal;
        InvAmountLCY: Decimal;
        PmtAmountFCY: Decimal;
        PmtAmount: Decimal;
        DiscountAmountLCY: Decimal;
    begin
        // Check Payment Discount Amount, Addnl. Currency Amount after Posting Payment, Less Payment before Payment Discount Date.

        // Setup: Create Two Currencies. Update General Ledger Setup. Create and Post General Journal Lines for Invoice and Payment
        // with Random Amounts. Post Entries on a Date before Payment Discount Date.
        Initialize();
        CurrencyCode := UpdateAddCurrencySetup();
        CurrencyCode2 := CreateCurrency();
        InvAmount := 10 * LibraryRandom.RandInt(100);
        InvAmountLCY := LibraryERM.ConvertCurrency(InvAmount, CurrencyCode, '', WorkDate());
        DiscountAmountLCY := GetDiscountAmount(InvAmountLCY);
        PmtAmountFCY := LibraryERM.ConvertCurrency(InvAmountLCY, '', CurrencyCode2, WorkDate());
        PmtAmount := PmtAmountFCY - (PmtAmountFCY * GetPaymentTolerancePercent() / 100) + 1;
        CreateAndPostDocumentLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, -InvAmount, PmtAmount,
          CurrencyCode, CurrencyCode2, CalcDate('<-1D>', GetDueDate()));

        // Apply Payment on Invoice. Verify Discount Amount, Additional-Currency Amount in GL Entry.
        BeforeDiscountDateEntry(
          GenJournalLine."Document Type"::Payment, GenJournalLine."Document No.", GetDiscountAmount(InvAmount),
          -DiscountAmountLCY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtLessFrmInvBfrDtNtInTol()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        InvAmount: Decimal;
        PmtAmount: Decimal;
        PmtTolAmount: Decimal;
        CurrencyCode: Code[10];
    begin
        // Check Payment Discount Amount, Addnl. Currency Amount after Posting Payment, Less Payment before Payment Discount Date.

        // Setup: Update General Ledger Setup. Create and Post General Journal Lines for Payment and Invoice with Random Amounts.
        // Post Entries on a Date before Payment Discount Date.
        Initialize();
        CurrencyCode := UpdateAddCurrencySetup();
        InvAmount := LibraryRandom.RandInt(499);
        PmtTolAmount := InvAmount * GetPaymentTolerancePercent() / 100;
        PmtAmount := InvAmount - ((InvAmount * GetPaymentTolerancePercent() / 100) + GetDiscountAmount(InvAmount));
        CreateAndPostDocumentLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, -InvAmount, PmtAmount,
          '', '', CalcDate('<-1D>', GetDueDate()));

        // Apply Payment on Invoice. Verify Payment Tolerance Amount, Additional-Currency Amount in GL Entry.
        ToleranceDiscountEntry(
          GenJournalLine."Document Type"::Payment, DetailedVendorLedgEntry."Entry Type"::"Payment Tolerance",
          GenJournalLine."Document No.", CurrencyCode, PmtTolAmount, -PmtTolAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefLessFrmCrMBfrDtWithFCY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PmtTolAmount: Decimal;
        CrMemoAmount: Decimal;
        CrMemoAmountFCY: Decimal;
        RefAmount: Decimal;
        RefAmountFCY: Decimal;
        CurrencyCode: Code[10];
        DiscountAmount: Decimal;
    begin
        // Check Payment Discount Amount, Addnl. Currency Amount after Posting Credit Memo, Less Refund before Payment Discount Date.

        // Setup: Update General Ledger Setup. Create and Post General Journal Lines for Refund and Credit Memo with Random Amounts.
        // Post Entries on a Date before Payment Discount Date.
        Initialize();
        CurrencyCode := UpdateAddCurrencySetup();
        CrMemoAmount := 500 * LibraryRandom.RandInt(5);
        CrMemoAmountFCY := LibraryERM.ConvertCurrency(CrMemoAmount, CurrencyCode, '', WorkDate());
        DiscountAmount := GetDiscountAmount(CrMemoAmount);
        RefAmount := CrMemoAmount - (GetMaxPaymentToleranceAmount() + DiscountAmount);
        RefAmountFCY := LibraryERM.ConvertCurrency(RefAmount, CurrencyCode, '', WorkDate());
        PmtTolAmount := CrMemoAmountFCY - (RefAmountFCY + GetDiscountAmount(CrMemoAmountFCY));
        CreateAndPostDocumentLine(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund, CrMemoAmount, -RefAmount,
          CurrencyCode, CurrencyCode, CalcDate('<-1D>', GetDueDate()));

        // Apply Refund on Credit Memo. Verify Discount Amount, Additional-Currency Amount in GL Entry.
        BeforeDiscountDateEntry(
          GenJournalLine."Document Type"::Refund, GenJournalLine."Document No.", -DiscountAmount, PmtTolAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OvrPmtWithinPmtTolDateLCY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        InvAmount: Decimal;
        PmtAmount: Decimal;
        CurrencyCode: Code[10];
        DiscountAmount: Decimal;
    begin
        // Check Payment Discount Tolerance Amount, Addnl. Currency Amount after Posting Invoice, Over Payment After Payment Discount Date.

        // Setup: Update General Ledger Setup. Create and Post General Journal Lines for Payment and Invoice with Random Amounts.
        // Post Entries on a Date after Payment Discount Date.
        Initialize();
        CurrencyCode := UpdateAddCurrencySetup();
        InvAmount := 10 * LibraryRandom.RandInt(100);
        DiscountAmount := GetDiscountAmount(InvAmount);
        PmtAmount := InvAmount + LibraryRandom.RandInt(10);
        CreateAndPostDocumentLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, -InvAmount, PmtAmount,
          '', '', CalcDate('<1D>', GetDueDate()));

        // Apply Payment on Invoice. Verify Payment Discount Tolerance Amount, Additional Currency Amount in GL Entry.
        ToleranceDiscountEntry(
          GenJournalLine."Document Type"::Payment, DetailedVendorLedgEntry."Entry Type"::"Payment Discount Tolerance",
          GenJournalLine."Document No.", CurrencyCode, DiscountAmount, -DiscountAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OvrRefWithinPmTolDtWithFCY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        CrMemoAmount: Decimal;
        RefAmount: Decimal;
        CurrencyCode: Code[10];
        DiscountAmountFCY: Decimal;
    begin
        // Check Payment Discount Tolerance Amt., Addnl. Currency Amount after Posting Credit Memo, Over Refund After Payment Discount Date.

        // Setup: Update General Ledger Setup. Create and Post General Journal Lines for Credit Memo and Refund with Random Amounts.
        // Post Entries on a Date after Payment Discount Date.
        Initialize();
        CurrencyCode := UpdateAddCurrencySetup();
        CrMemoAmount := 10 * LibraryRandom.RandInt(100);
        DiscountAmountFCY := GetDiscountAmount(LibraryERM.ConvertCurrency(CrMemoAmount, CurrencyCode, '', WorkDate()));
        RefAmount := CrMemoAmount + LibraryRandom.RandInt(10);
        CreateAndPostDocumentLine(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund, CrMemoAmount, -RefAmount,
          CurrencyCode, CurrencyCode, CalcDate('<1D>', GetDueDate()));

        // Apply Refund on Credit Memo. Verify Payment Discount Tolerance Amount, Additional Currency Amount in GL Entry.
        ToleranceDiscountEntry(
          GenJournalLine."Document Type"::Refund, DetailedVendorLedgEntry."Entry Type"::"Payment Discount Tolerance",
          GenJournalLine."Document No.", CurrencyCode, -DiscountAmountFCY, DiscountAmountFCY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OvrPmtWithinPmTolDtMCr()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        InvAmount: Decimal;
        InvAmountLCY: Decimal;
        PmtAmountFCY: Decimal;
        PmtTolAmount: Decimal;
        CurrencyCode: Code[10];
        CurrencyCode2: Code[10];
        DiscountAmount: Decimal;
    begin
        // Check Payment Discount Tolerance Amount, Addnl. Currency Amount after Posting Invoice, Over Payment After Payment Discount Date.

        // Setup: Update General Ledger Setup. Create Two new Currencies. Create and Post General Journal Lines for Invoice and Payment
        // using Random Amount. Post Entries on a Date after Payment Discount Date.
        Initialize();
        CurrencyCode := UpdateAddCurrencySetup();
        CurrencyCode2 := CreateCurrency();
        InvAmount := 10 * LibraryRandom.RandInt(100);
        InvAmountLCY := LibraryERM.ConvertCurrency(InvAmount, CurrencyCode, '', WorkDate());
        PmtTolAmount := InvAmountLCY * GetPaymentTolerancePercent() / 100;
        PmtAmountFCY := LibraryERM.ConvertCurrency(InvAmountLCY, '', CurrencyCode2, WorkDate()) + (PmtTolAmount + 1);
        DiscountAmount := GetDiscountAmount(InvAmountLCY);
        CreateAndPostDocumentLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, -InvAmount, PmtAmountFCY,
          CurrencyCode, CurrencyCode2, CalcDate('<1D>', GetDueDate()));

        // Apply Payment on Invoice. Verify Payment Discount Tolerance Amount, Additional Currency Amount in GL Entry.
        ToleranceDiscountEntry(
          GenJournalLine."Document Type"::Payment, DetailedVendorLedgEntry."Entry Type"::"Payment Discount Tolerance",
          GenJournalLine."Document No.", CurrencyCode2, DiscountAmount, -DiscountAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EqlPmtAndWithinPmtTolDtLCY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        InvAmount: Decimal;
        CurrencyCode: Code[10];
        DiscountAmount: Decimal;
    begin
        // Check Payment Discount Tolerance Amount, Addnl. Currency Amount after Posting Invoice, Equal Payment After Payment Discount Date.

        // Setup: Update General Ledger Setup. Create and Post General Journal Lines for Invoice and Payment using Random Amount.
        // Post Entries on a Date after Payment Discount Date. Take Payment Amount less than Invoice Amount.
        Initialize();
        CurrencyCode := UpdateAddCurrencySetup();
        InvAmount := 10 * LibraryRandom.RandInt(100);
        DiscountAmount := GetDiscountAmount(InvAmount);
        CreateAndPostDocumentLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, -InvAmount, InvAmount,
          '', '', CalcDate('<1D>', GetDueDate()));

        // Apply Payment on Invoice. Verify Payment Discount Tolerance Amount, Additional Currency Amount in GL Entry.
        ToleranceDiscountEntry(
          GenJournalLine."Document Type"::Payment, DetailedVendorLedgEntry."Entry Type"::"Payment Discount Tolerance",
          GenJournalLine."Document No.", CurrencyCode, DiscountAmount, -DiscountAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtUndrInvAmtWithnTolDtLCY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        CurrencyCode: Code[10];
        InvAmount: Decimal;
        PmtAmount: Decimal;
        DiscountAmount: Decimal;
    begin
        // Check Payment Discount Tolerance Amount, Additonal Currency Amount after Posting Invoice, Less Payment within Payment Discount
        // Grace Period.

        // Setup: Update General Ledger Setup. Create and Post General Journal Lines for Invoice and Payment using Random Amount.
        // Post Entries on a Date within Payment Discount Grace Period. Take Payment Amount less than Invoice Amount.
        Initialize();
        CurrencyCode := UpdateAddCurrencySetup();
        ComputeUnderAmountForMinValue(InvAmount, PmtAmount);
        DiscountAmount := GetDiscountAmount(InvAmount);
        CreateAndPostDocumentLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, -InvAmount, PmtAmount,
          '', '', CalcDate('<-1D>', ComputeDueDateForGracePeriod()));

        // Apply Payment on Invoice. Verify Payment Discount Tolerance Amount, Additional Currency Amount in GL Entry.
        // Exercise: Apply Payment/Refund Amount on Invoice/Credit Memo.
        ApplyAndPostVendorEntry(GenJournalLine."Document Type"::Payment, GenJournalLine."Document No.");

        // Verification: Verify Payment Tolerance Amount and Additional-Currency Amount in GL Entry.
        VerifyPaymentUnderInvoiceDiscountTolAmount(GenJournalLine."Document No.", -DiscountAmount, CurrencyCode, DetailedVendorLedgEntry."Entry Type"::Application);
        VerifyPaymentUnderInvoiceAmountWithinToleranceDateLCY(-DiscountAmount, GenJournalLine."Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefUndrCrMAmtWithnTolDtFCY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgEntry: Record "Vendor Ledger Entry";
        CrMemoAmount: Decimal;
        RefAmount: Decimal;
        CurrencyCode: Code[10];
        DiscountAmountFCY: Decimal;
    begin
        // Check Payment Discount Tolerance Amount, Additonal Currency Amount after Posting Credit Memo, Less Refund within Payment Discount
        // Grace Period.

        // Setup: Update General Ledger Setup. Create and Post Journal Lines of Refund and Credit Memo for a Vendor. Take Random
        // Amounts. Post Entries on a Date within Payment Discount Grace Period. Take Refund Amount less than Credit Memo Amount.
        Initialize();
        CurrencyCode := UpdateAddCurrencySetup();
        ComputeUnderAmountForMaxValue(CrMemoAmount, RefAmount);
        DiscountAmountFCY := GetDiscountAmount(LibraryERM.ConvertCurrency(CrMemoAmount, CurrencyCode, '', WorkDate()));
        CreateAndPostDocumentLine(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund, CrMemoAmount, -RefAmount,
          CurrencyCode, CurrencyCode, CalcDate('<-1D>', ComputeDueDateForGracePeriod()));

        // Apply Refund on Credit Memo. Verify Payment Discount Tolerance Amount, Additional-Currency Amount in GL Entry.
        // Exercise: Apply Payment/Refund Amount on Invoice/Credit Memo.
        ApplyAndPostVendorEntry(GenJournalLine."Document Type"::Refund, GenJournalLine."Document No.");

        // Verification: Verify Payment Tolerance Amount and Additional-Currency Amount in GL Entry.
        VerifyRefundTolAmount(GenJournalLine."Document No.", DiscountAmountFCY, CurrencyCode, VendorLedgEntry."Document Type"::"Credit Memo");
        VeryifyRefundUnderAmountWithinToleranceDateFCY(-DiscountAmountFCY, GenJournalLine."Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtUndrInvAmtWithnTolDtMCr()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        InvAmount: Decimal;
        InvAmountLCY: Decimal;
        PmtAmount: Decimal;
        PmtAmountFCY: Decimal;
        CurrencyCode: Code[10];
        CurrencyCode2: Code[10];
        DiscountAmount: Decimal;
    begin
        // Check Payment Discount Tolerance Amount, Additonal Currency Amount after Posting Invoice, Less Payment within Payment Discount
        // Grace Period.

        // Setup: Create two Currencies. Update General Ledger Setup. Create and Post Journal Lines of Payment and Invoice for a Vendor.
        // Take Random Amounts. Post Entries on a Date within Payment Discount Grace Period. Take Payment Amount less than Invoice Amount.
        Initialize();
        CurrencyCode := UpdateAddCurrencySetup();
        CurrencyCode2 := CreateCurrency();
        InvAmount := 10 * LibraryRandom.RandInt(100);
        InvAmountLCY := LibraryERM.ConvertCurrency(InvAmount, CurrencyCode, '', WorkDate());
        PmtAmountFCY := LibraryERM.ConvertCurrency(InvAmountLCY, '', CurrencyCode2, WorkDate());
        DiscountAmount := GetDiscountAmount(InvAmountLCY);
        PmtAmount := PmtAmountFCY - (PmtAmountFCY * GetPaymentTolerancePercent() / 100) + 1;
        CreateAndPostDocumentLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, -InvAmount, PmtAmount,
          CurrencyCode, CurrencyCode2, CalcDate('<-1D>', ComputeDueDateForGracePeriod()));

        // Apply Payment on Invoice. Verify Payment Discount Tolerance Amount, Additional Currency Amount in GL Entry.
        ToleranceDiscountEntry(
          GenJournalLine."Document Type"::Payment, DetailedVendorLedgEntry."Entry Type"::"Payment Discount Tolerance",
          GenJournalLine."Document No.", CurrencyCode2, DiscountAmount, -DiscountAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EqlPmtAndWithnPmtTolDtLCY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        CurrencyCode: Code[10];
        PmtAmount: Decimal;
        InvAmount: Decimal;
        DiscountAmount: Decimal;
    begin
        // Check Payment Discount Tolerance Amount, Additonal Currency Amount after Posting Invoice, Equal Payment within Payment
        // Discount Grace Period.

        // Setup: Update General Ledger Setup. Create and Post Journal Lines of Payment and Invoice for a Vendor. Take Random
        // Amounts. Post Entries on a Date within Payment Discount Grace Period. Take Payment Amount less than Invoice Amount.
        Initialize();
        CurrencyCode := UpdateAddCurrencySetup();
        InvAmount := 10 * LibraryRandom.RandInt(100);
        DiscountAmount := GetDiscountAmount(InvAmount);
        PmtAmount := InvAmount - DiscountAmount;
        CreateAndPostDocumentLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, -InvAmount, PmtAmount,
          '', '', CalcDate('<-1D>', ComputeDueDateForGracePeriod()));

        // Apply Payment on Invoice. Verify Payment Discount Tolerance Amount, Additional Currency Amount in GL Entry.
        ToleranceDiscountEntry(
          GenJournalLine."Document Type"::Payment, DetailedVendorLedgEntry."Entry Type"::"Payment Discount Tolerance",
          GenJournalLine."Document No.", CurrencyCode, DiscountAmount, -DiscountAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OvrPmtOvrPmtTolDtLCY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        InvAmount: Decimal;
        PmtAmount: Decimal;
        PmtTolAmount: Decimal;
        CurrencyCode: Code[10];
    begin
        // Check Payment Tolerance Amount, Additonal Currency Amount after Posting Invoice, Over Payment after Payment
        // Discount Grace Period.

        // Setup: Update General Ledger Setup. Create and Post Journal Lines of Payment and Invoice for a Vendor. Take Random
        // Amounts. Post Entries on a Date after Payment Discount Grace Period. Take Payment Amount greater than Invoice Amount.
        Initialize();
        CurrencyCode := UpdateAddCurrencySetup();
        InvAmount := 501 * LibraryRandom.RandInt(5);
        PmtAmount := InvAmount + GetMaxPaymentToleranceAmount();
        PmtTolAmount := GetMaxPaymentToleranceAmount();
        CreateAndPostDocumentLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, -InvAmount, PmtAmount,
          '', '', CalcDate('<1D>', ComputeDueDateForGracePeriod()));

        // Apply Payment Over from Invoice value and Verify Payment Tolerance Amount and Additional-Currency Amount in GL Entry.
        ToleranceDiscountEntry(
          GenJournalLine."Document Type"::Payment, DetailedVendorLedgEntry."Entry Type"::"Payment Tolerance",
          GenJournalLine."Document No.", CurrencyCode, -PmtTolAmount, PmtTolAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OvrRefOvrPmtTolDtlFCY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        CrMemoAmount: Decimal;
        RefAmount: Decimal;
        RefTolAmount: Decimal;
        RefTolAmountFCY: Decimal;
        CurrencyCode: Code[10];
    begin
        // Check Payment Tolerance Amount, Additonal Currency Amount after Posting Credit Memo, Over Refund after Payment Discount
        // Grace Period.

        // Setup: Update General Ledger Setup. Create and Post Journal Lines of Credit Memo and Refund for a Vendor. Take Random
        // Amounts. Post Entries on a Date after Payment Discount Grace Period. Take Refund Amount greater than Credit Memo Amount.
        Initialize();
        CurrencyCode := UpdateAddCurrencySetup();
        CrMemoAmount := LibraryRandom.RandInt(499);
        RefAmount := CrMemoAmount + (CrMemoAmount * GetPaymentTolerancePercent() / 100);
        RefTolAmount := CrMemoAmount * GetPaymentTolerancePercent() / 100;
        RefTolAmountFCY := LibraryERM.ConvertCurrency(RefTolAmount, CurrencyCode, '', WorkDate());
        CreateAndPostDocumentLine(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund, CrMemoAmount, -RefAmount,
          CurrencyCode, CurrencyCode, CalcDate('<1D>', ComputeDueDateForGracePeriod()));

        // Apply Refund Over Credit Memo. Verify Payment Tolerance Amount, Additional Currency Amount in GL Entry.
        ToleranceDiscountEntry(
          GenJournalLine."Document Type"::Refund, DetailedVendorLedgEntry."Entry Type"::"Payment Tolerance",
          GenJournalLine."Document No.", CurrencyCode, RefTolAmountFCY, -RefTolAmountFCY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EqlPmtAndOvrPmtTolDtLCY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        InvAmount: Decimal;
    begin
        // Check Payment Discount Amount, Additonal Currency Amount after Posting Invoice, Equal Payment after Payment Discount
        // Grace Period.

        // Setup: Update General Ledger Setup. Create and Post Journal Lines of Invoice and Payment for a Vendor. Take Random
        // Amounts. Post Entries on a Date after Payment Discount Grace Period. Take Payment Amount Equal to Invoice Amount.
        Initialize();
        UpdateAddCurrencySetup();
        InvAmount := 10 * LibraryRandom.RandInt(100);
        CreateAndPostDocumentLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, -InvAmount, InvAmount,
          '', '', CalcDate('<1D>', ComputeDueDateForGracePeriod()));

        // Exercise: Apply Payment on Invoice.
        ApplyAndPostVendorEntry(GenJournalLine."Document Type"::Payment, GenJournalLine."Document No.");

        // Verify: Verify Posted GL Entry.
        VerifyGLEntry(InvAmount, GenJournalLine."Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtUndrInvOvrPmtTolDtLCY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        InvAmount: Decimal;
        PmtAmount: Decimal;
        PmtTolAmount: Decimal;
        CurrencyCode: Code[10];
    begin
        // Check Payment Tolerance Amount, Additonal Currency Amount after Posting Invoice, Less Payment after Payment Discount
        // Grace Period.

        // Setup: Update General Ledger Setup. Create and Post Journal Lines of Invoice and Payment for a Vendor. Take Random
        // Amounts. Post Entries on a Date after Payment Discount Grace Period. Take Payment Amount less than Invoice Amount.
        Initialize();
        CurrencyCode := UpdateAddCurrencySetup();
        InvAmount := 500 * LibraryRandom.RandInt(5);
        PmtAmount := InvAmount - GetMaxPaymentToleranceAmount();
        PmtTolAmount := GetMaxPaymentToleranceAmount();
        CreateAndPostDocumentLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, -InvAmount, PmtAmount,
          '', '', CalcDate('<1D>', ComputeDueDateForGracePeriod()));

        // Apply Payment over Invoice. Verify Payment Tolerance Amount, Additional Currency Amount in GL Entry.
        ToleranceDiscountEntry(
          GenJournalLine."Document Type"::Payment, DetailedVendorLedgEntry."Entry Type"::"Payment Tolerance",
          GenJournalLine."Document No.", CurrencyCode, PmtTolAmount, -PmtTolAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefUndrCrMOvrPmtTolDtFCY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        CrMemoAmount: Decimal;
        RefAmount: Decimal;
        RefTolAmount: Decimal;
        RefTolAmountFCY: Decimal;
        CurrencyCode: Code[10];
    begin
        // Check Payment Tolerance Amount, Additonal Currency Amount after Posting Credit Memo, Less Refund after Payment Discount
        // Grace Period.

        // Setup: Update General Ledger Setup. Create and Post Journal Lines of Credit Memo and Refund for a Vendor. Take Random
        // Amounts. Post Entries on a Date after Payment Discount Grace Period. Take Refund Amount greater than Credit Memo Amount.
        Initialize();
        CurrencyCode := UpdateAddCurrencySetup();
        CrMemoAmount := LibraryRandom.RandInt(499);
        RefAmount := CrMemoAmount - (CrMemoAmount * GetPaymentTolerancePercent() / 100);
        RefTolAmount := CrMemoAmount * GetPaymentTolerancePercent() / 100;
        RefTolAmountFCY := LibraryERM.ConvertCurrency(RefTolAmount, CurrencyCode, '', WorkDate());
        CreateAndPostDocumentLine(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund, CrMemoAmount, -RefAmount,
          CurrencyCode, CurrencyCode, CalcDate('<1D>', ComputeDueDateForGracePeriod()));

        // Apply Refund over Credit Memo. Verify Payment Tolerance Amount and Additional Currency Amount in GL Entry.
        ToleranceDiscountEntry(
          GenJournalLine."Document Type"::Refund, DetailedVendorLedgEntry."Entry Type"::"Payment Tolerance",
          GenJournalLine."Document No.", CurrencyCode, -RefTolAmountFCY, RefTolAmountFCY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RmngAmtLessThanRndgPrecMCr()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
        InvAmount: Decimal;
        InvAmountLCY: Decimal;
        PmtAmountFCY: Decimal;
        CurrencyCode: Code[10];
        CurrencyCode2: Code[10];
    begin
        // Check Payment Tolerance Amount, Additonal Currency Amount after Posting Invoice, Less Payment 3 Months after Posting
        // entries.

        // Setup: Create Two Currencies. Update General Ledger Setup. Create and Post General Journal Lines of Invoice and
        // Payment Type for a Vendor. Take Random Amounts. Make Payment less than Invoice Amount to create rounding Entry.
        Initialize();
        GeneralLedgerSetup.Get();
        CurrencyCode := UpdateAddCurrencySetup();
        CurrencyCode2 := CreateCurrency();
        UpdateAppRndgPrecisionCurrency(CurrencyCode2);
        InvAmount := 10 * LibraryRandom.RandInt(100);
        InvAmountLCY := LibraryERM.ConvertCurrency(InvAmount, CurrencyCode, '', WorkDate());
        PmtAmountFCY :=
          LibraryERM.ConvertCurrency(InvAmountLCY, '', CurrencyCode2, WorkDate()) - GeneralLedgerSetup."Amount Rounding Precision";
        CreateAndPostDocumentLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, -InvAmount, PmtAmountFCY,
          CurrencyCode, CurrencyCode2, CalcDate('<3M>', WorkDate()));

        // Apply Payment on Invoice. Verify Payment Tolerance Amount and Additional Currency Amount in GL Entry.
        ToleranceDiscountEntry(
          GenJournalLine."Document Type"::Payment, DetailedVendorLedgEntry."Entry Type"::"Appln. Rounding",
          GenJournalLine."Document No.", CurrencyCode, InvAmountLCY - GenJournalLine."Amount (LCY)",
          GenJournalLine."Amount (LCY)" - InvAmountLCY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RmngAmtOverRndgPrecFCY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        CrMemoAmount: Decimal;
        DifferenceAmountLCY: Decimal;
        RefAmount: Decimal;
        CurrencyCode: Code[10];
    begin
        // Check Payment Tolerance Amount, Additonal Currency Amount after Posting Credit Memo, Over Refund 3 Months after Posting
        // entries.

        // Setup: Update General Ledger Setup. Create and Post General Journal Lines of Credit Memo and Refund for Vendor with Random
        // Amounts. Take Refund Amount always gerater between 0.1 and 0.5 from Credit Memo Amount to create Payment Tolerance Entry.
        Initialize();
        CurrencyCode := UpdateAddCurrencySetup();
        UpdateAppRndgPrecisionCurrency(CurrencyCode);
        CrMemoAmount := 10 * LibraryRandom.RandInt(100);
        RefAmount := CrMemoAmount + Round(LibraryRandom.RandInt(50) / 100, 0.1, '>');
        DifferenceAmountLCY := LibraryERM.ConvertCurrency(RefAmount - CrMemoAmount, CurrencyCode, '', WorkDate());
        CreateAndPostDocumentLine(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund, CrMemoAmount, -RefAmount,
          CurrencyCode, CurrencyCode, CalcDate('<3M>', WorkDate()));

        // Apply Refund Under Credit Memo value and Verify Payment Tolerance Amount and Additional Currency Amount in GL Entry.
        ToleranceDiscountEntry(
          GenJournalLine."Document Type"::Refund, DetailedVendorLedgEntry."Entry Type"::"Payment Tolerance",
          GenJournalLine."Document No.", CurrencyCode, DifferenceAmountLCY, -DifferenceAmountLCY);
    end;

    [Test]
    [HandlerFunctions('ApplyVendLedgerEntriesModalPageHandler,PostApplicationModalPageHandler,CancelPaymentDiscToleranceWarningModalPageHandler')]
    [Scope('OnPrem')]
    procedure NoApplicationPostIfUserCancelPaymentTolerance()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
        DiscountAmount: Decimal;
        InvAmount: Decimal;
    begin
        // [FEATURE] [UI] [Apply]
        // [SCENARIO 277758] No application post if user choose "No" in "Payment Discount Tolerance Warning" window when apply payment to invoice with discount

        Initialize();
        UpdateAddCurrencySetup();

        // [GIVEN] Payment Discount Tolerance Warning is set in General Ledger Setup
        LibraryPmtDiscSetup.SetPmtToleranceWarning(true);
        LibraryPmtDiscSetup.SetPmtDiscToleranceWarning(true);

        InvAmount := LibraryRandom.RandIntInRange(10, 100);
        DiscountAmount := GetDiscountAmount(InvAmount);

        // [GIVEN] Payment and invoice with possible payment discount tolerance
        CreateAndPostDocumentLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, -InvAmount,
          InvAmount - DiscountAmount, '', '', ComputeDueDateForGracePeriod() - 1);

        // [GIVEN] "Post Application" invoked from "Apply Vendor Ledger Entries" where payment applied to invoice
        VendorLedgerEntries.OpenEdit();
        VendorLedgerEntries.FILTER.SetFilter("Document No.", GenJournalLine."Document No.");
        VendorLedgerEntries.FILTER.SetFilter("Document Type", Format(GenJournalLine."Document Type"::Payment));
        VendorLedgerEntries.ActionApplyEntries.Invoke();

        // [WHEN] Choose "No" in "Payment Discount Tolerance Warning" window
        // Handles by CancelPaymentDiscToleranceWarningModalPageHandler

        // [THEN] No "application successfully posted" message shown
        // [THEN] "Accepted Payment Discount Tolerance" is not set on invoice vendor ledger entry
        VendorLedgerEntry.SetRange("Vendor No.", GenJournalLine."Account No.");
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Invoice);
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.TestField("Accepted Pmt. Disc. Tolerance", false);

        // [THEN] "Remainig Amount" equals "Amount" on invoice vendor ledger entry
        VendorLedgerEntry.CalcFields(Amount, "Remaining Amount");
        VendorLedgerEntry.TestField("Remaining Amount", VendorLedgerEntry.Amount);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        isInitialized := true;
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        Commit();
    end;

    local procedure BeforeDiscountDateEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; Amount: Decimal; Amount2: Decimal)
    var
        DeltaAssert: Codeunit "Delta Assert";
    begin
        // Watch Expected Discount value calculated as per Delta amount.
        DeltaAssert.Init();
        WatchPaymentDiscountAmount(DeltaAssert, DocumentNo, Amount);

        // Exercise: Apply Payment/Refund Amount on Invoice/Credit Memo.
        ApplyAndPostVendorEntry(DocumentType, DocumentNo);

        // Verify: Verify Discount Amount and Additional-Currency Amount in GL Entry.
        DeltaAssert.Assert();
        VerifyGLEntry(Amount2, DocumentNo);
    end;

    local procedure ToleranceDiscountEntry(DocumentType: Enum "Gen. Journal Document Type"; EntryType: Enum "Detailed CV Ledger Entry Type"; DocumentNo: Code[20]; CurrencyCode: Code[10]; Amount: Decimal; Amount2: Decimal)
    begin
        // Exercise: Apply Payment/Refund Amount on Invoice/Credit Memo.
        ApplyAndPostVendorEntry(DocumentType, DocumentNo);

        // Verification: Verify Payment Tolerance Amount and Additional-Currency Amount in GL Entry.
        VerifyPaymentDiscountTolAmount(DocumentNo, Amount, CurrencyCode, EntryType);
        VerifyGLEntry(Amount2, DocumentNo);
    end;

    local procedure CreateAndPostDocumentLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; Amount: Decimal; Amount2: Decimal; CurrencyCode: Code[10]; CurrencyCode2: Code[10]; PostingDate: Date)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        CreateDocumentLine(GenJournalLine, GenJournalBatch, DocumentType, CreateVendor(), Amount, WorkDate(), CurrencyCode);
        CreateDocumentLine(GenJournalLine, GenJournalBatch, DocumentType2, GenJournalLine."Account No.", Amount2, PostingDate, CurrencyCode2);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure ApplyVendorEntry(var ApplyingVendorLedgerEntry: Record "Vendor Ledger Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GLRegister: Record "G/L Register";
    begin
        LibraryERM.FindVendorLedgerEntry(ApplyingVendorLedgerEntry, DocumentType, DocumentNo);
        ApplyingVendorLedgerEntry.CalcFields("Remaining Amount");
        LibraryERM.SetApplyVendorEntry(ApplyingVendorLedgerEntry, ApplyingVendorLedgerEntry."Remaining Amount");

        // Find Posted Vendor Ledger Entries.
        GLRegister.FindLast();
        VendorLedgerEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        VendorLedgerEntry.SetRange("Applying Entry", false);
        VendorLedgerEntry.FindFirst();

        // Set Applies-to ID.
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry);
    end;

    local procedure ApplyAndPostVendorEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        ApplyVendorEntry(VendorLedgerEntry, DocumentType, DocumentNo);
        LibraryERM.PostVendLedgerApplication(VendorLedgerEntry);
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
        LibraryPurchase: Codeunit "Library - Purchase";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Application Method", Vendor."Application Method"::Manual);
        Vendor.Validate("Payment Terms Code", GetPaymentTerms());
        Vendor.Modify(true);
        UpdateVendorPostingGroup(Vendor."Vendor Posting Group");
        exit(Vendor."No.");
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
        Currency.Validate("Payment Tolerance %", 1);
        Currency.Validate("Max. Payment Tolerance Amount", 5);
        Currency.Validate("Residual Gains Account", Currency."Realized Gains Acc.");
        Currency.Validate("Residual Losses Account", Currency."Realized Losses Acc.");
        Currency.Modify(true);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateDocumentLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; DocumentType: Enum "Gen. Journal Document Type"; VendorNo: Code[20]; Amount: Decimal; PostingDate: Date; CurrencyCode: Code[10])
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType, GenJournalLine."Account Type"::Vendor,
          VendorNo, Amount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);
    end;

    local procedure ComputeUnderAmountForMinValue(var Amount: Decimal; var Amount2: Decimal)
    begin
        // To Calculate Payment/Refund value using "Payment Tolerance %" field value from General Ledger Setup. Take seed value till 499.
        Amount := LibraryRandom.RandInt(499);
        Amount2 := Amount - (GetPaymentTolerancePercent() + 1);
    end;

    local procedure ComputeUnderAmountForMaxValue(var Amount: Decimal; var Amount2: Decimal)
    begin
        // To Calculate Payment/Refund value using "Max. Payment Tolerance Amount" field value from General Ledger Setup. Take seed value
        // greater than 500.
        Amount := 500 * LibraryRandom.RandInt(5);
        Amount2 := Amount - ((Amount * GetPaymentTolerancePercent() / 100) + 1);
    end;

    local procedure GetPaymentTerms(): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        if not PaymentTerms."Calc. Pmt. Disc. on Cr. Memos" then begin
            PaymentTerms.Validate("Calc. Pmt. Disc. on Cr. Memos", true);
            PaymentTerms.Modify(true);
        end;
        exit(PaymentTerms.Code);
    end;

    local procedure GetDiscountAmount(Amount: Decimal): Decimal
    begin
        exit(Amount * GetDiscountPercent() / 100);
    end;

    local procedure GetDiscountPercent(): Decimal
    var
        PaymentTerms: Record "Payment Terms";
    begin
        PaymentTerms.Get(GetPaymentTerms());
        exit(PaymentTerms."Discount %");
    end;

    local procedure GetPaymentTolerancePercent(): Decimal
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        exit(GeneralLedgerSetup."Payment Tolerance %");
    end;

    local procedure GetMaxPaymentToleranceAmount(): Decimal
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        exit(GeneralLedgerSetup."Max. Payment Tolerance Amount");
    end;

    local procedure ComputeDueDateForGracePeriod(): Date
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        exit(CalcDate(GeneralLedgerSetup."Payment Discount Grace Period", GetDueDate()));
    end;

    local procedure GetDueDate(): Date
    var
        PaymentTerms: Record "Payment Terms";
    begin
        PaymentTerms.Get(GetPaymentTerms());
        exit(CalcDate(PaymentTerms."Discount Date Calculation", WorkDate()));
    end;

    local procedure UpdateAppRndgPrecisionCurrency(CurrencyCode: Code[10])
    var
        Currency: Record Currency;
    begin
        Currency.Get(CurrencyCode);
        Currency.Validate("Appln. Rounding Precision", Currency."Amount Rounding Precision");
        Currency.Modify(true);
    end;

    local procedure UpdateVendorPostingGroup(PostingGroupCode: Code[20])
    var
        VendorPostingGroup: Record "Vendor Posting Group";
        GLAccount: Record "G/L Account";
        Counter: Integer;
    begin
        VendorPostingGroup.Get(PostingGroupCode);
        Counter := 0;
        GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.SetRange(Blocked, false);
        if GLAccount.FindSet() then
            repeat
                Counter += 1;
                VendorPostingGroup.Validate("Payment Disc. Debit Acc.", GLAccount."No.");
                VendorPostingGroup.Validate("Payment Disc. Credit Acc.", GLAccount."No.");
            until (GLAccount.Next() = 0) or (Counter = 2);
        VendorPostingGroup.Validate("Payment Tolerance Debit Acc.", GLAccount."No.");
        VendorPostingGroup.Validate("Payment Tolerance Credit Acc.", GLAccount."No.");
        VendorPostingGroup.Modify(true);
    end;

    local procedure UpdateAddCurrencySetup() CurrencyCode: Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // Setup 5D for Payment Discount Grace Period, 1 for Payment Tolerance % and 5 for Tolerance Amount.
        CurrencyCode := CreateCurrency();
        UpdatePmtTolInGenLedgerSetup(
          CurrencyCode, '<5D>', 1, 5, GeneralLedgerSetup."Payment Tolerance Posting"::"Payment Tolerance Accounts",
          GeneralLedgerSetup."Pmt. Disc. Tolerance Posting"::"Payment Tolerance Accounts");
    end;

    local procedure UpdatePmtTolInGenLedgerSetup(CurrencyCode: Code[10]; PaymentDiscountGracePeriod: Text[10]; PaymentTolerance: Decimal; MaxPaymentToleranceAmount: Decimal; PaymentTolerancePosting: Option; PmtDiscTolerancePosting: Option)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        Evaluate(GeneralLedgerSetup."Payment Discount Grace Period", PaymentDiscountGracePeriod);
        GeneralLedgerSetup.Validate("Payment Tolerance %", PaymentTolerance);
        GeneralLedgerSetup.Validate("Max. Payment Tolerance Amount", MaxPaymentToleranceAmount);
        GeneralLedgerSetup.Validate("Payment Tolerance Posting", PaymentTolerancePosting);
        GeneralLedgerSetup.Validate("Pmt. Disc. Tolerance Posting", PmtDiscTolerancePosting);
        GeneralLedgerSetup."Additional Reporting Currency" := CurrencyCode;
        GeneralLedgerSetup.Modify(true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CancelPaymentDiscToleranceWarningModalPageHandler(var PaymentDiscToleranceWarning: Page "Payment Disc Tolerance Warning"; var Response: Action)
    begin
        Response := ACTION::No;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyVendLedgerEntriesModalPageHandler(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    begin
        ApplyVendorEntries.ActionSetAppliesToID.Invoke();
        ApplyVendorEntries.ActionPostApplication.Invoke();
        ApplyVendorEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostApplicationModalPageHandler(var PostApplication: TestPage "Post Application")
    begin
        PostApplication.OK().Invoke();
    end;

    local procedure VerifyPaymentDiscountTolAmount(DocumentNo: Code[20]; Amount: Decimal; CurrencyCode: Code[10]; EntryType: Enum "Detailed CV Ledger Entry Type")
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        Currency: Record Currency;
        Assert: Codeunit Assert;
    begin
        Currency.Get(CurrencyCode);
        Currency.InitRoundingPrecision();
        DetailedVendorLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedVendorLedgEntry.SetRange("Entry Type", EntryType);
        DetailedVendorLedgEntry.FindFirst();
        Assert.RecordIsNotEmpty(DetailedVendorLedgEntry);
        Assert.AreNearlyEqual(
          DetailedVendorLedgEntry."Amount (LCY)", Amount, Currency."Amount Rounding Precision", StrSubstNo(PaymentToleranceError,
            Amount, DetailedVendorLedgEntry.TableCaption(), DetailedVendorLedgEntry.FieldCaption("Entry No."),
            DetailedVendorLedgEntry."Entry No."));
    end;

    local procedure VerifyRefundTolAmount(DocumentNo: Code[20]; Amount: Decimal; CurrencyCode: Code[10]; DocumentType: Enum "Gen. Journal Document Type")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Currency: Record Currency;
        Assert: Codeunit Assert;
    begin
        Currency.Get(CurrencyCode);
        Currency.InitRoundingPrecision();
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry.SetRange("Document Type", DocumentType);
        VendorLedgerEntry.FindFirst();
        Assert.RecordIsNotEmpty(VendorLedgerEntry);
        Assert.AreNearlyEqual(
          VendorLedgerEntry."Pmt. Disc. Rcd.(LCY)", Amount, Currency."Amount Rounding Precision", StrSubstNo(PaymentToleranceError,
            Amount, VendorLedgerEntry.TableCaption(), VendorLedgerEntry.FieldCaption("Entry No."),
            VendorLedgerEntry."Entry No."));
    end;

    local procedure VerifyPaymentUnderInvoiceDiscountTolAmount(DocumentNo: Code[20]; Amount: Decimal; CurrencyCode: Code[10]; EntryType: Enum "Detailed CV Ledger Entry Type")
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        Currency: Record Currency;
        Assert: Codeunit Assert;
    begin
        Currency.Get(CurrencyCode);
        Currency.InitRoundingPrecision();
        DetailedVendorLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedVendorLedgEntry.SetRange("Entry Type", EntryType);
        DetailedVendorLedgEntry.FindFirst();
        Assert.RecordIsNotEmpty(DetailedVendorLedgEntry);
        Assert.AreNearlyEqual(
          DetailedVendorLedgEntry."Remaining Pmt. Disc. Possible", Amount, Currency."Amount Rounding Precision", StrSubstNo(PaymentToleranceError,
            Amount, DetailedVendorLedgEntry.TableCaption(), DetailedVendorLedgEntry.FieldCaption("Entry No."),
            DetailedVendorLedgEntry."Entry No."));
    end;

    local procedure VerifyGLEntry(Amount: Decimal; DocumentNo: Code[20])
    var
        GLRegister: Record "G/L Register";
        GLEntry: Record "G/L Entry";
        Currency: Record Currency;
        GeneralLedgerSetup: Record "General Ledger Setup";
        Assert: Codeunit Assert;
        AdditionalCurrencyAmount: Decimal;
    begin
        GeneralLedgerSetup.Get();
        Currency.Get(GeneralLedgerSetup."Additional Reporting Currency");
        Currency.InitRoundingPrecision();

        // Verify Amount in GL Entry.
        GLRegister.FindLast();
        GLEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(
          Amount, GLEntry.Amount, Currency."Amount Rounding Precision", StrSubstNo(RoundingMessage, GLEntry.FieldCaption(Amount),
            GLEntry.Amount, GLEntry.TableCaption(), GLEntry.FieldCaption("Entry No."), GLEntry."Entry No."));

        // Verify Additional Reporting Currency Amount.
        AdditionalCurrencyAmount := LibraryERM.ConvertCurrency(Amount, '', Currency.Code, WorkDate());
        Assert.AreNearlyEqual(
          AdditionalCurrencyAmount, GLEntry."Additional-Currency Amount", Currency."Amount Rounding Precision",
          StrSubstNo(RoundingMessage, GLEntry.FieldCaption("Additional-Currency Amount"), GLEntry."Additional-Currency Amount",
            GLEntry.TableCaption(), GLEntry.FieldCaption("Entry No."), GLEntry."Entry No."));
    end;

    local procedure VerifyRefundUnderInvoiceAmountBeforeDiscountDateFCY(Amount: Decimal; DocumentNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Currency: Record Currency;
        GeneralLedgerSetup: Record "General Ledger Setup";
        Assert: Codeunit Assert;
        AdditionalCurrencyAmount: Decimal;
    begin
        GeneralLedgerSetup.Get();
        Currency.Get(GeneralLedgerSetup."Additional Reporting Currency");
        Currency.InitRoundingPrecision();
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry.FindFirst();
        Assert.RecordIsNotEmpty(VendorLedgerEntry);
        Assert.AreNearlyEqual(
          Amount, VendorLedgerEntry."Original Pmt. Disc. Possible", Currency."Amount Rounding Precision", StrSubstNo(RoundingMessage, VendorLedgerEntry.FieldCaption(Amount),
            VendorLedgerEntry.Amount, VendorLedgerEntry.TableCaption(), VendorLedgerEntry.FieldCaption("Entry No."), VendorLedgerEntry."Entry No."));

        // Verify Additional Reporting Currency Amount.
        AdditionalCurrencyAmount := LibraryERM.ConvertCurrency(Amount, '', Currency.Code, WorkDate());
        Assert.AreNearlyEqual(
          AdditionalCurrencyAmount, VendorLedgerEntry."Max. Payment Tolerance", Currency."Amount Rounding Precision",
          StrSubstNo(RoundingMessage, VendorLedgerEntry.FieldCaption("Max. Payment Tolerance"), VendorLedgerEntry."Max. Payment Tolerance",
            VendorLedgerEntry.TableCaption(), VendorLedgerEntry.FieldCaption("Entry No."), VendorLedgerEntry."Entry No."));
    end;

    local procedure VerifyRefundUnderCreditMemoAmountBeforeDiscountDateFCY(Amount: Decimal; DocumentNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Currency: Record Currency;
        GeneralLedgerSetup: Record "General Ledger Setup";
        Assert: Codeunit Assert;
        AdditionalCurrencyAmount: Decimal;
    begin
        GeneralLedgerSetup.Get();
        Currency.Get(GeneralLedgerSetup."Additional Reporting Currency");
        Currency.InitRoundingPrecision();
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry.FindFirst();
        Assert.RecordIsNotEmpty(VendorLedgerEntry);
        Assert.AreNearlyEqual(
          Amount, VendorLedgerEntry."Pmt. Disc. Rcd.(LCY)", Currency."Amount Rounding Precision", StrSubstNo(RoundingMessage, VendorLedgerEntry.FieldCaption(Amount),
            VendorLedgerEntry.Amount, VendorLedgerEntry.TableCaption(), VendorLedgerEntry.FieldCaption("Entry No."), VendorLedgerEntry."Entry No."));

        // Verify Additional Reporting Currency Amount.
        AdditionalCurrencyAmount := LibraryERM.ConvertCurrency(Amount, '', Currency.Code, WorkDate());
        Assert.AreNearlyEqual(
          AdditionalCurrencyAmount, VendorLedgerEntry."Original Pmt. Disc. Possible", Currency."Amount Rounding Precision",
          StrSubstNo(RoundingMessage, VendorLedgerEntry.FieldCaption("Original Pmt. Disc. Possible"), VendorLedgerEntry."Original Pmt. Disc. Possible",
            VendorLedgerEntry.TableCaption(), VendorLedgerEntry.FieldCaption("Entry No."), VendorLedgerEntry."Entry No."));
    end;

    local procedure VerifyPaymentUnderInvoiceAmountWithinToleranceDateLCY(Amount: Decimal; DocumentNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Currency: Record Currency;
        GeneralLedgerSetup: Record "General Ledger Setup";
        Assert: Codeunit Assert;
        AdditionalCurrencyAmount: Decimal;
    begin
        GeneralLedgerSetup.Get();
        Currency.Get(GeneralLedgerSetup."Additional Reporting Currency");
        Currency.InitRoundingPrecision();
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry.FindFirst();
        Assert.RecordIsNotEmpty(VendorLedgerEntry);
        Assert.AreNearlyEqual(
          Amount, VendorLedgerEntry."Original Pmt. Disc. Possible", Currency."Amount Rounding Precision", StrSubstNo(RoundingMessage, VendorLedgerEntry.FieldCaption(Amount),
            VendorLedgerEntry.Amount, VendorLedgerEntry.TableCaption(), VendorLedgerEntry.FieldCaption("Entry No."), VendorLedgerEntry."Entry No."));

        // Verify Additional Reporting Currency Amount.
        AdditionalCurrencyAmount := LibraryERM.ConvertCurrency(Amount, '', Currency.Code, WorkDate());
        Assert.AreNearlyEqual(
          AdditionalCurrencyAmount, VendorLedgerEntry."Max. Payment Tolerance", Currency."Amount Rounding Precision",
          StrSubstNo(RoundingMessage, VendorLedgerEntry.FieldCaption("Max. Payment Tolerance"), VendorLedgerEntry."Max. Payment Tolerance",
            VendorLedgerEntry.TableCaption(), VendorLedgerEntry.FieldCaption("Entry No."), VendorLedgerEntry."Entry No."));
    end;

    local procedure VeryifyRefundUnderAmountWithinToleranceDateFCY(Amount: Decimal; DocumentNo: Code[20])
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        Currency: Record Currency;
        GeneralLedgerSetup: Record "General Ledger Setup";
        Assert: Codeunit Assert;
        AdditionalCurrencyAmount: Decimal;
    begin
        GeneralLedgerSetup.Get();
        Currency.Get(GeneralLedgerSetup."Additional Reporting Currency");
        Currency.InitRoundingPrecision();
        DetailedVendorLedgEntry.SetRange("Entry Type", DetailedVendorLedgEntry."Entry Type"::"Payment Discount Tolerance");
        DetailedVendorLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedVendorLedgEntry.FindFirst();
        Assert.RecordIsNotEmpty(DetailedVendorLedgEntry);
        Assert.AreNearlyEqual(
          Amount, DetailedVendorLedgEntry."Amount (LCY)", Currency."Amount Rounding Precision", StrSubstNo(RoundingMessage, DetailedVendorLedgEntry.FieldCaption(Amount),
            DetailedVendorLedgEntry.Amount, DetailedVendorLedgEntry.TableCaption(), DetailedVendorLedgEntry.FieldCaption("Entry No."), DetailedVendorLedgEntry."Entry No."));

        // Verify Additional Reporting Currency Amount.
        AdditionalCurrencyAmount := LibraryERM.ConvertCurrency(Amount, '', Currency.Code, WorkDate());
        Assert.AreNearlyEqual(
          AdditionalCurrencyAmount, DetailedVendorLedgEntry.Amount, Currency."Amount Rounding Precision",
          StrSubstNo(RoundingMessage, DetailedVendorLedgEntry.FieldCaption(Amount), DetailedVendorLedgEntry.Amount,
            DetailedVendorLedgEntry.TableCaption(), DetailedVendorLedgEntry.FieldCaption("Entry No."), DetailedVendorLedgEntry."Entry No."));
    end;

    local procedure WatchPaymentDiscountAmount(var DeltaAssert: Codeunit "Delta Assert"; DocumentNo: Code[20]; PmtDiscAmount: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Watch Discount Amount expected value should be same as per Delta amount.
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry.FindFirst();
        DeltaAssert.AddWatch(
          DATABASE::"Vendor Ledger Entry", VendorLedgerEntry.GetPosition(), VendorLedgerEntry.FieldNo("Original Pmt. Disc. Possible"),
          VendorLedgerEntry."Original Pmt. Disc. Possible" + PmtDiscAmount);
    end;
}
