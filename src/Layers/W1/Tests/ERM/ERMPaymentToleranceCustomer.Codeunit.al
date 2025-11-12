codeunit 134005 "ERM Payment Tolerance Customer"
{
    Permissions = TableData "Cust. Ledger Entry" = rimd;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Payment Tolerance] [Sales]
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
    procedure OverPmtBeforeDiscDtLCY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        InvAmount: Decimal;
        PmtAmount: Decimal;
        DiscountAmount: Decimal;
    begin
        // Setup: Calculate Invoice Amount using RANDOM, it can be anything between 10 and 1000, Amount always greater than
        // Maximum Payment Tolerance Amount.
        Initialize();
        UpdateAddCurrencySetup();
        InvAmount := 10 * LibraryRandom.RandInt(100);
        PmtAmount := InvAmount + LibraryRandom.RandInt(10);  // Over Payment and Before Discount Date.
        DiscountAmount := GetDiscountAmount(InvAmount);

        CreateAndPostDocumentLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, InvAmount, -PmtAmount,
          '', '', CalcDate('<-1D>', GetDueDate()));

        // Apply Payment Amount more than Invoice value and Verify Discount Amount and Additional-Currency Amount in GL Entry.
        BeforeDiscountDateEntry(
          GenJournalLine."Document Type"::Payment, GenJournalLine."Document No.", DiscountAmount, DiscountAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OverRefBeforeDiscDtFCY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CrMemoAmount: Decimal;
        DiscountAmountFCY: Decimal;
        RefAmount: Decimal;
        CurrencyCode: Code[10];
    begin
        // Setup: Calculate Credit Memo Amount using RANDOM, it can be anything between 10 and 1000, Amount need to always greater than
        // Maximum Payment Tolerance Amount.
        Initialize();
        CurrencyCode := UpdateAddCurrencySetup();
        CrMemoAmount := 10 * LibraryRandom.RandInt(100);
        RefAmount := CrMemoAmount + LibraryRandom.RandInt(10);  // Over Refund and Before Discount Date.
        DiscountAmountFCY := GetDiscountAmount(LibraryERM.ConvertCurrency(CrMemoAmount, CurrencyCode, '', WorkDate()));

        CreateAndPostDocumentLine(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund, -CrMemoAmount, RefAmount,
          CurrencyCode, CurrencyCode, CalcDate('<-1D>', GetDueDate()));

        // Apply Refund Amount more than Credit Memo value and Verify Discount Amount and Additional-Currency Amount in GL Entry.
        BeforeDiscountDateEntry(
          GenJournalLine."Document Type"::Refund, GenJournalLine."Document No.",
          -GetDiscountAmount(CrMemoAmount), -DiscountAmountFCY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OverPmtBeforeDiscDtMCurr()
    var
        GenJournalLine: Record "Gen. Journal Line";
        InvAmount: Decimal;
        InvAmountLCY: Decimal;
        DiscountAmountLCY: Decimal;
        PmtAmountFCY: Decimal;
        CurrencyCode: Code[10];
        CurrencyCode2: Code[10];
    begin
        // Setup: Calculate Invoice Amount using RANDOM, it can be anything between 10 and 1000, Amount always greater than
        // Maximum Payment Tolerance Amount.
        Initialize();
        CurrencyCode := UpdateAddCurrencySetup();
        CurrencyCode2 := CreateCurrency();
        InvAmount := 10 * LibraryRandom.RandInt(100);
        InvAmountLCY := LibraryERM.ConvertCurrency(InvAmount, CurrencyCode, '', WorkDate());
        DiscountAmountLCY := GetDiscountAmount(InvAmountLCY);
        PmtAmountFCY := LibraryERM.ConvertCurrency(InvAmountLCY, '', CurrencyCode2, WorkDate()) + LibraryRandom.RandInt(5);

        CreateAndPostDocumentLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, InvAmount, -PmtAmountFCY,
          CurrencyCode, CurrencyCode2, CalcDate('<-1D>', GetDueDate()));

        // Apply Payment Amount more than Invoice value and Verify Discount Amount and Additional-Currency Amount in GL Entry.
        BeforeDiscountDateEntry(
          GenJournalLine."Document Type"::Payment, GenJournalLine."Document No.",
          GetDiscountAmount(InvAmount), DiscountAmountLCY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EqualPmtBeforeDiscDtLCY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DiscountAmount: Decimal;
        InvAmount: Decimal;
    begin
        // Setup: Calculate Invoice Amount using RANDOM, it can be anything between 10 and 1000, Amount always greater than
        // Maximum Payment Tolerance Amount.
        Initialize();
        UpdateAddCurrencySetup();
        InvAmount := 10 * LibraryRandom.RandInt(100);
        DiscountAmount := GetDiscountAmount(InvAmount);

        CreateAndPostDocumentLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, InvAmount, -InvAmount,
          '', '', CalcDate('<-1D>', GetDueDate()));

        // Apply Payment Amount Equal Invoice value and Verify Discount Amount and Additional-Currency Amount in GL Entry.
        BeforeDiscountDateEntry(
          GenJournalLine."Document Type"::Payment, GenJournalLine."Document No.", DiscountAmount, DiscountAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtUnderInvAmtBeforeDiscDtLCY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DeltaAssert: Codeunit "Delta Assert";
        DiscountAmount: Decimal;
        InvAmount: Decimal;
        PmtAmount: Decimal;
    begin
        // Setup: Calculate Invoice Amount using RANDOM, it can be anything between 10 and 1000, Amount always greater than
        // Maximum Payment Tolerance Amount.
        Initialize();
        UpdateAddCurrencySetup();
        ComputeUnderAmountForMinValue(InvAmount, PmtAmount);
        DiscountAmount := GetDiscountAmount(InvAmount);

        CreateAndPostDocumentLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, InvAmount, -PmtAmount,
          '', '', CalcDate('<-1D>', GetDueDate()));

        // Apply Payment Amount Equal Invoice value and Verify Discount Amount and Additional-Currency Amount in GL Entry.
        // Watch Expected Discount value calculated as per Delta amount.
        DeltaAssert.Init();
        WatchPaymentDiscountAmount(DeltaAssert, GenJournalLine."Document No.", DiscountAmount);

        // Exercise: Apply Payment/Refund Amount on Invoice/Credit Memo.
        ApplyAndPostCustomerEntry(GenJournalLine."Document Type"::Payment, GenJournalLine."Document No.");

        // Verify: Verify Discount Amount and Additional-Currency Amount in GL Entry.
        DeltaAssert.Assert();
        VerifyCustomerLedgerEntryDisc(DiscountAmount, GenJournalLine."Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefUnderCrMAmtBeforeDiscDtFCY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DeltaAssert: Codeunit "Delta Assert";
        DiscountAmountFCY: Decimal;
        CrMemoAmount: Decimal;
        CrMemoAmountFCY: Decimal;
        RefAmount: Decimal;
        CurrencyCode: Code[10];
    begin
        // Setup: Calculate Invoice Amount using RANDOM, it can be anything between 10 and 1000, Amount always greater than
        // Maximum Payment Tolerance Amount.
        Initialize();
        CurrencyCode := UpdateAddCurrencySetup();
        ComputeUnderAmountForMaxValue(CrMemoAmount, RefAmount);
        CrMemoAmountFCY := LibraryERM.ConvertCurrency(CrMemoAmount, CurrencyCode, '', WorkDate());
        DiscountAmountFCY := GetDiscountAmount(CrMemoAmountFCY);

        CreateAndPostDocumentLine(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund, -CrMemoAmount, RefAmount,
          CurrencyCode, CurrencyCode, CalcDate('<-1D>', GetDueDate()));

        // Apply Refund Amount Under Credit Memo value and Verify Discount Amount and Additional-Currency Amount in GL Entry.

        // Watch Expected Discount value calculated as per Delta amount.
        DeltaAssert.Init();
        WatchPaymentDiscountAmount(DeltaAssert, GenJournalLine."Document No.", -GetDiscountAmount(CrMemoAmount));

        // Exercise: Apply Payment/Refund Amount on Invoice/Credit Memo.
        ApplyAndPostCustomerEntry(GenJournalLine."Document Type"::Refund, GenJournalLine."Document No.");

        // Verify: Verify Discount Amount and Additional-Currency Amount in GL Entry.
        DeltaAssert.Assert();

        VerifyCreditMemoAmountDiscount(-DiscountAmountFCY, GenJournalLine."Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtUnderInvAmtBeforeDtMCurr()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DiscountAmountLCY: Decimal;
        InvAmount: Decimal;
        InvAmountLCY: Decimal;
        PmtAmountFCY: Decimal;
        PmtAmount: Decimal;
        CurrencyCode: Code[10];
        CurrencyCode2: Code[10];
    begin
        // Setup: Calculate Invoice Amount using RANDOM, it can be anything between 10 and 1000, Amount always greater than
        // Maximum Payment Tolerance Amount.
        Initialize();
        CurrencyCode := UpdateAddCurrencySetup();
        CurrencyCode2 := CreateCurrency();
        InvAmount := 10 * LibraryRandom.RandInt(100);
        InvAmountLCY := LibraryERM.ConvertCurrency(InvAmount, CurrencyCode, '', WorkDate());
        DiscountAmountLCY := GetDiscountAmount(InvAmountLCY);
        PmtAmountFCY := LibraryERM.ConvertCurrency(InvAmountLCY, '', CurrencyCode2, WorkDate());

        // Calculate Payment Amount under Invoice Amount
        PmtAmount := PmtAmountFCY - (PmtAmountFCY * GetPaymentTolerancePercent() / 100) + 1;

        CreateAndPostDocumentLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, InvAmount, -PmtAmount,
          CurrencyCode, CurrencyCode2, CalcDate('<-1D>', GetDueDate()));

        // Apply Payment Amount Under Invoice value and Verify Discount Amount and Additional-Currency Amount in GL Entry.
        BeforeDiscountDateEntry(
          GenJournalLine."Document Type"::Payment, GenJournalLine."Document No.",
          GetDiscountAmount(InvAmount), DiscountAmountLCY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtLessFromInvBeforeDtNotInTol()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        InvAmount: Decimal;
        PmtAmount: Decimal;
        PmtTolAmount: Decimal;
        CurrencyCode: Code[10];
    begin
        // Setup: Calculate Invoice Amount using RANDOM, it can be anything between 1 and 499, Amount always greater than
        // Maximum Payment Tolerance Amount.
        Initialize();
        CurrencyCode := UpdateAddCurrencySetup();
        InvAmount := LibraryRandom.RandInt(499); // To Check Payment Tolerance % taking 499 maximum value.
        PmtTolAmount := InvAmount * GetPaymentTolerancePercent() / 100;
        PmtAmount := InvAmount - ((InvAmount * GetPaymentTolerancePercent() / 100) + GetDiscountAmount(InvAmount));

        CreateAndPostDocumentLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, InvAmount, -PmtAmount,
          '', '', CalcDate('<-1D>', GetDueDate()));

        // Apply Payment less from Invoice value and Verify Payment Tolerance Amount and Additional-Currency Amount in GL Entry.
        ToleranceDiscountEntry(
          GenJournalLine."Document Type"::Payment, DetailedCustLedgEntry."Entry Type"::"Payment Tolerance",
          GenJournalLine."Document No.", CurrencyCode, -PmtTolAmount, PmtTolAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefLessFromCrMBeforeDtWithFCY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DiscountAmount: Decimal;
        PmtTolAmount: Decimal;
        CrMemoAmount: Decimal;
        CrMemoAmountFCY: Decimal;
        RefAmount: Decimal;
        RefAmountFCY: Decimal;
        CurrencyCode: Code[10];
    begin
        // Setup: Calculate Invoice Amount using RANDOM, it can be anything between 500 and 2500, Amount always greater than
        // Maximum Payment Tolerance Amount.
        Initialize();
        CurrencyCode := UpdateAddCurrencySetup();
        CrMemoAmount := 500 * LibraryRandom.RandInt(5); // To check "Max. Payment Tolerance Amount" using 500 to 2500 range.
        CrMemoAmountFCY := LibraryERM.ConvertCurrency(CrMemoAmount, CurrencyCode, '', WorkDate());
        DiscountAmount := GetDiscountAmount(CrMemoAmount);
        RefAmount := CrMemoAmount - (GetMaxPaymentToleranceAmount() + DiscountAmount);
        RefAmountFCY := LibraryERM.ConvertCurrency(RefAmount, CurrencyCode, '', WorkDate());
        PmtTolAmount := CrMemoAmountFCY - (RefAmountFCY + GetDiscountAmount(CrMemoAmountFCY));

        CreateAndPostDocumentLine(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund, -CrMemoAmount, RefAmount,
          CurrencyCode, CurrencyCode, CalcDate('<-1D>', GetDueDate()));

        // Apply Refund Amount Less Credit Memo value and Verify Discount Amount and Additional-Currency Amount in GL Entry.
        BeforeDiscountDateEntry(
          GenJournalLine."Document Type"::Refund, GenJournalLine."Document No.", -DiscountAmount, -PmtTolAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OverPmtWithinPmtTolDtLCY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DiscountAmount: Decimal;
        InvAmount: Decimal;
        PmtAmount: Decimal;
        CurrencyCode: Code[10];
    begin
        // Setup: Calculate Invoice Amount using RANDOM, it can be anything between 10 and 1000, Amount always greater than
        // Maximum Payment Tolerance Amount.
        Initialize();
        CurrencyCode := UpdateAddCurrencySetup();
        InvAmount := 10 * LibraryRandom.RandInt(100);
        DiscountAmount := GetDiscountAmount(InvAmount);
        PmtAmount := InvAmount + LibraryRandom.RandInt(10);  // Over Payment and within Payment Tolerance Date.

        CreateAndPostDocumentLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, InvAmount, -PmtAmount,
          '', '', CalcDate('<1D>', GetDueDate()));

        // Apply Payment Over from Invoice value and Verify Payment Discount Tolerance Amount and Additional-Currency Amount in GL Entry.
        ToleranceDiscountEntry(
          GenJournalLine."Document Type"::Payment, DetailedCustLedgEntry."Entry Type"::"Payment Discount Tolerance",
          GenJournalLine."Document No.", CurrencyCode, -DiscountAmount, DiscountAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OverRefWithinPmtTolDtWithFCY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DiscountAmountFCY: Decimal;
        CrMemoAmount: Decimal;
        RefAmount: Decimal;
        CurrencyCode: Code[10];
    begin
        // Setup: Calculate Invoice Amount using RANDOM, it can be anything between 10 and 1000, Amount always greater than
        // Maximum Payment Tolerance Amount.
        Initialize();
        CurrencyCode := UpdateAddCurrencySetup();
        CrMemoAmount := 10 * LibraryRandom.RandInt(100);
        DiscountAmountFCY := GetDiscountAmount(LibraryERM.ConvertCurrency(CrMemoAmount, CurrencyCode, '', WorkDate()));
        RefAmount := CrMemoAmount + LibraryRandom.RandInt(10);  // Over Refund and within Payment Tolerance Date.

        CreateAndPostDocumentLine(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund, -CrMemoAmount, RefAmount,
          CurrencyCode, CurrencyCode, CalcDate('<1D>', GetDueDate()));

        // Apply Refund Over from Credit Memo value and Verify Payment Discount Tolerance Amount
        // and Additional-Currency Amount in GL Entry.
        ToleranceDiscountEntry(
          GenJournalLine."Document Type"::Refund, DetailedCustLedgEntry."Entry Type"::"Payment Discount Tolerance",
          GenJournalLine."Document No.", CurrencyCode, DiscountAmountFCY, -DiscountAmountFCY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OverPmtWithinPmtTolDtMCurr()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        InvAmount: Decimal;
        InvAmountLCY: Decimal;
        PmtAmountFCY: Decimal;
        DiscountAmount: Decimal;
        PmtTolAmount: Decimal;
        CurrencyCode: Code[10];
        CurrencyCode2: Code[10];
    begin
        // Setup: Calculate Invoice Amount using RANDOM, it can be anything between 10 and 1000, Amount always greater than
        // Maximum Payment Tolerance Amount.
        Initialize();
        CurrencyCode := UpdateAddCurrencySetup();
        CurrencyCode2 := CreateCurrency();
        InvAmount := 10 * LibraryRandom.RandInt(100);
        InvAmountLCY := LibraryERM.ConvertCurrency(InvAmount, CurrencyCode, '', WorkDate());
        PmtTolAmount := InvAmountLCY * GetPaymentTolerancePercent() / 100;
        PmtAmountFCY := LibraryERM.ConvertCurrency(InvAmountLCY, '', CurrencyCode2, WorkDate()) + (PmtTolAmount + 1);
        DiscountAmount := GetDiscountAmount(InvAmountLCY);

        CreateAndPostDocumentLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, InvAmount, -PmtAmountFCY,
          CurrencyCode, CurrencyCode2, CalcDate('<1D>', GetDueDate()));

        // Apply Payment Over from Invoice value and Verify Payment Discount Tolerance Amount
        // and Additional-Currency Amount in GL Entry.
        ToleranceDiscountEntry(
          GenJournalLine."Document Type"::Payment, DetailedCustLedgEntry."Entry Type"::"Payment Discount Tolerance",
          GenJournalLine."Document No.", CurrencyCode2, -DiscountAmount, DiscountAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EqualPmtWithinPmtTolDueDtLCY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DiscountAmount: Decimal;
        InvAmount: Decimal;
        CurrencyCode: Code[10];
    begin
        // Setup: Calculate Invoice Amount using RANDOM, it can be anything between 10 and 1000, Amount always greater than
        // Maximum Payment Tolerance Amount.
        Initialize();
        CurrencyCode := UpdateAddCurrencySetup();
        InvAmount := 10 * LibraryRandom.RandInt(100);
        DiscountAmount := GetDiscountAmount(InvAmount);

        CreateAndPostDocumentLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, InvAmount, -InvAmount,
          '', '', CalcDate('<1D>', GetDueDate()));

        // Apply Payment Equal from Invoice value and Verify Payment Discount Tolerance Amount
        // and Additional-Currency Amount in GL Entry.
        ToleranceDiscountEntry(
          GenJournalLine."Document Type"::Payment, DetailedCustLedgEntry."Entry Type"::"Payment Discount Tolerance",
          GenJournalLine."Document No.", CurrencyCode, -DiscountAmount, DiscountAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtUnderInvAmtWithinTolDtLCY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DiscountAmount: Decimal;
        InvAmount: Decimal;
        PmtAmount: Decimal;
        CurrencyCode: Code[10];
    begin
        // Setup: Calculate Invoice Amount using RANDOM, it can be anything between 10 and 1000, Amount always greater than
        // Maximum Payment Tolerance Amount.
        Initialize();
        CurrencyCode := UpdateAddCurrencySetup();
        ComputeUnderAmountForMinValue(InvAmount, PmtAmount);
        DiscountAmount := GetDiscountAmount(InvAmount);

        CreateAndPostDocumentLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, InvAmount, -PmtAmount,
          '', '', CalcDate('<-1D>', ComputeDueDateForGracePeriod()));

        // Apply Payment Under from Invoice value and Verify Payment Discount Tolerance Amount
        // and Additional-Currency Amount in GL Entry.
        ApplyAndPostCustomerEntry(GenJournalLine."Document Type"::Payment, GenJournalLine."Document No.");

        // Verify: Verify Payment Tolerance Amount and Additional-Currency Amount in GL Entry.
        VerifyRemainingDiscountPossible(GenJournalLine."Document No.", DiscountAmount, CurrencyCode, DetailedCustLedgEntry."Entry Type"::Application);
        VerifyCustomerLedgerEntryDisc(DiscountAmount, GenJournalLine."Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefUnderCrMAmtWithinTolDtFCY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        CrMemoAmount: Decimal;
        DiscountAmountFCY: Decimal;
        RefAmount: Decimal;
        CurrencyCode: Code[10];
    begin
        // Setup: Calculate Invoice Amount using RANDOM, it can be anything between 10 and 1000, Amount always greater than
        // Maximum Payment Tolerance Amount.
        Initialize();
        CurrencyCode := UpdateAddCurrencySetup();
        ComputeUnderAmountForMaxValue(CrMemoAmount, RefAmount);
        DiscountAmountFCY := GetDiscountAmount(LibraryERM.ConvertCurrency(CrMemoAmount, CurrencyCode, '', WorkDate()));

        CreateAndPostDocumentLine(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund, -CrMemoAmount, RefAmount,
          CurrencyCode, CurrencyCode, CalcDate('<-1D>', ComputeDueDateForGracePeriod()));

        // Apply Refund Under from Credit Memo value and Verify Payment Discount Tolerance Amount
        // and Additional-Currency Amount in GL Entry.
        // Exercise: Apply Payment/Refund Amount on Invoice/Credit Memo.
        ApplyAndPostCustomerEntry(GenJournalLine."Document Type"::Refund, GenJournalLine."Document No.");

        // Verify: Verify Payment Tolerance Amount and Additional-Currency Amount in GL Entry.
        VerifyPaymentDiscountTolAmountCustLedg(GenJournalLine."Document No.", DiscountAmountFCY, CurrencyCode, DetailedCustLedgEntry."Entry Type"::"Payment Discount Tolerance");
        VerifyCreditMemoAmountDiscount(-DiscountAmountFCY, GenJournalLine."Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtUnderInvAmtWithinTolDtMCurr()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        InvAmount: Decimal;
        InvAmountLCY: Decimal;
        PmtAmount: Decimal;
        PmtAmountFCY: Decimal;
        DiscountAmount: Decimal;
        CurrencyCode: Code[10];
        CurrencyCode2: Code[10];
    begin
        // Setup: Calculate Invoice Amount using RANDOM, it can be anything between 10 and 1000, Amount always greater than
        // Maximum Payment Tolerance Amount.
        Initialize();
        CurrencyCode := UpdateAddCurrencySetup();
        CurrencyCode2 := CreateCurrency();
        InvAmount := 10 * LibraryRandom.RandInt(100);
        InvAmountLCY := LibraryERM.ConvertCurrency(InvAmount, CurrencyCode, '', WorkDate());
        PmtAmountFCY := LibraryERM.ConvertCurrency(InvAmountLCY, '', CurrencyCode2, WorkDate());
        DiscountAmount := GetDiscountAmount(InvAmountLCY);
        PmtAmount := PmtAmountFCY - (PmtAmountFCY * GetPaymentTolerancePercent() / 100) + 1;

        CreateAndPostDocumentLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, InvAmount, -PmtAmount,
          CurrencyCode, CurrencyCode2, CalcDate('<-1D>', ComputeDueDateForGracePeriod()));

        // Apply Payment Under from Invoice value and Verify Payment Discount Tolerance Amount
        // and Additional-Currency Amount in GL Entry.
        ToleranceDiscountEntry(
          GenJournalLine."Document Type"::Payment, DetailedCustLedgEntry."Entry Type"::"Payment Discount Tolerance",
          GenJournalLine."Document No.", CurrencyCode2, -DiscountAmount, DiscountAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EqualPmtWithinPmtTolDtLCY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DiscountAmount: Decimal;
        InvAmount: Decimal;
        PmtAmount: Decimal;
        CurrencyCode: Code[10];
    begin
        // Setup: Calculate Invoice Amount using RANDOM, it can be anything between 10 and 1000, Amount always greater than
        // Maximum Payment Tolerance Amount.
        Initialize();
        CurrencyCode := UpdateAddCurrencySetup();
        InvAmount := 10 * LibraryRandom.RandInt(100);
        DiscountAmount := GetDiscountAmount(InvAmount);
        PmtAmount := InvAmount - DiscountAmount;

        CreateAndPostDocumentLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, InvAmount, -PmtAmount,
          '', '', CalcDate('<-1D>', ComputeDueDateForGracePeriod()));

        // Apply Payment Equal to Invoice value and Verify Payment Discount Tolerance Amount and Additional-Currency Amount in GL Entry.
        ToleranceDiscountEntry(
          GenJournalLine."Document Type"::Payment, DetailedCustLedgEntry."Entry Type"::"Payment Discount Tolerance",
          GenJournalLine."Document No.", CurrencyCode, -DiscountAmount, DiscountAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OverPmtOverPmtTolDtLCY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        InvAmount: Decimal;
        PmtAmount: Decimal;
        PmtTolAmount: Decimal;
        CurrencyCode: Code[10];
    begin
        // Setup: Calculate Invoice Amount using RANDOM, it can be anything between 501 and 2500, Amount always greater than
        // Maximum Payment Tolerance Amount.
        Initialize();
        CurrencyCode := UpdateAddCurrencySetup();
        InvAmount := 501 * LibraryRandom.RandInt(5);
        PmtAmount := InvAmount + GetMaxPaymentToleranceAmount();
        PmtTolAmount := GetMaxPaymentToleranceAmount();

        CreateAndPostDocumentLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, InvAmount, -PmtAmount,
          '', '', CalcDate('<1D>', ComputeDueDateForGracePeriod()));

        // Apply Payment Over from Invoice value and Verify Payment Tolerance Amount and Additional-Currency Amount in GL Entry.
        ToleranceDiscountEntry(
          GenJournalLine."Document Type"::Payment, DetailedCustLedgEntry."Entry Type"::"Payment Tolerance",
          GenJournalLine."Document No.", CurrencyCode, PmtTolAmount, -PmtTolAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OverRefOverPmtTolDtFCY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        CrMemoAmount: Decimal;
        RefAmount: Decimal;
        RefTolAmount: Decimal;
        RefTolAmountFCY: Decimal;
        CurrencyCode: Code[10];
    begin
        // Setup: Calculate Invoice Amount using RANDOM, it can be anything between 1 and 499, Amount always greater than
        // Maximum Payment Tolerance Amount.
        Initialize();
        CurrencyCode := UpdateAddCurrencySetup();
        CrMemoAmount := LibraryRandom.RandInt(499); // To Check Payment Tolerance % taking 499 maximum value.
        RefAmount := CrMemoAmount + (CrMemoAmount * GetPaymentTolerancePercent() / 100);
        RefTolAmount := CrMemoAmount * GetPaymentTolerancePercent() / 100;
        RefTolAmountFCY := LibraryERM.ConvertCurrency(RefTolAmount, CurrencyCode, '', WorkDate());

        CreateAndPostDocumentLine(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund, -CrMemoAmount, RefAmount,
          CurrencyCode, CurrencyCode, CalcDate('<1D>', ComputeDueDateForGracePeriod()));

        // Apply Refund Over from Credit Memo value and Verify Payment Tolerance Amount and Additional-Currency Amount in GL Entry.
        ToleranceDiscountEntry(
          GenJournalLine."Document Type"::Refund, DetailedCustLedgEntry."Entry Type"::"Payment Tolerance",
          GenJournalLine."Document No.", CurrencyCode, -RefTolAmountFCY, RefTolAmountFCY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EqualPmtOverPmtTolDtLCY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        InvAmount: Decimal;
    begin
        // Setup: Calculate Invoice Amount using RANDOM, it can be anything between 10 and 1000, Amount always greater than
        // Maximum Payment Tolerance Amount.
        Initialize();
        GeneralLedgerSetup.Get();
        UpdateAddCurrencySetup();
        InvAmount := 10 * LibraryRandom.RandInt(100);

        CreateAndPostDocumentLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, InvAmount, -InvAmount,
          '', '', CalcDate('<1D>', ComputeDueDateForGracePeriod()));

        // Exercise: Apply Payment on Invoice.
        ApplyAndPostCustomerEntry(GenJournalLine."Document Type"::Payment, GenJournalLine."Document No.");

        // Verify: Verify Dtld Customer Ledger Entry after application.
        LibraryERM.VerifyCustApplnWithZeroTransNo(
          GenJournalLine."Document No.", GenJournalLine."Document Type"::Payment, -GenJournalLine."Amount (LCY)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtUnderInvOverPmtTolDtLCY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        InvAmount: Decimal;
        PmtAmount: Decimal;
        PmtTolAmount: Decimal;
        CurrencyCode: Code[10];
    begin
        // Setup: Calculate Invoice Amount using RANDOM, it can be anything between 500 and 2500, Amount always greater than
        // Maximum Payment Tolerance Amount.
        Initialize();
        CurrencyCode := UpdateAddCurrencySetup();
        InvAmount := 500 * LibraryRandom.RandInt(5); // To Check Max Payment Tolerance Amount taking minimum 500 value.
        PmtAmount := InvAmount - GetMaxPaymentToleranceAmount();
        PmtTolAmount := GetMaxPaymentToleranceAmount();

        CreateAndPostDocumentLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, InvAmount, -PmtAmount,
          '', '', CalcDate('<1D>', ComputeDueDateForGracePeriod()));

        // Apply Payment Under Invoice value and Verify Payment Tolerance Amount and Additional-Currency Amount in GL Entry.
        ToleranceDiscountEntry(
          GenJournalLine."Document Type"::Payment, DetailedCustLedgEntry."Entry Type"::"Payment Tolerance",
          GenJournalLine."Document No.", CurrencyCode, -PmtTolAmount, PmtTolAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefUnderCrMOverPmtTolDtFCY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        CrMemoAmount: Decimal;
        RefAmount: Decimal;
        RefTolAmount: Decimal;
        RefTolAmountFCY: Decimal;
        CurrencyCode: Code[10];
    begin
        // Setup: Calculate Invoice Amount using RANDOM, it can be anything between 1 and 499, Amount always greater than
        // Maximum Payment Tolerance Amount.
        Initialize();
        CurrencyCode := UpdateAddCurrencySetup();
        CrMemoAmount := LibraryRandom.RandInt(499); // To Check Payment Tolerance % taking 499 maximum value.
        RefAmount := CrMemoAmount - (CrMemoAmount * GetPaymentTolerancePercent() / 100);
        RefTolAmount := CrMemoAmount * GetPaymentTolerancePercent() / 100;
        RefTolAmountFCY := LibraryERM.ConvertCurrency(RefTolAmount, CurrencyCode, '', WorkDate());

        CreateAndPostDocumentLine(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund, -CrMemoAmount, RefAmount,
          CurrencyCode, CurrencyCode, CalcDate('<1D>', ComputeDueDateForGracePeriod()));

        // Apply Refund Under Credit Memo value and Verify Payment Tolerance Amount and Additional-Currency Amount in GL Entry.
        ToleranceDiscountEntry(
          GenJournalLine."Document Type"::Refund, DetailedCustLedgEntry."Entry Type"::"Payment Tolerance",
          GenJournalLine."Document No.", CurrencyCode, RefTolAmountFCY, -RefTolAmountFCY);
    end;

    [Test]
    [HandlerFunctions('ApplyCustLedgerEntriesModalPageHandler,PostApplicationModalPageHandler,CancelPaymentDiscToleranceWarningModalPageHandler')]
    [Scope('OnPrem')]
    procedure NoApplicationPostIfUserCancelPaymentTolerance()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustomerLedgerEntries: TestPage "Customer Ledger Entries";
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
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment,
          InvAmount, -InvAmount + DiscountAmount, '', '', ComputeDueDateForGracePeriod() - 1);

        // [GIVEN] "Post Application" invoked from "Apply Customer Ledger Entries" where payment applied to invoice
        CustomerLedgerEntries.OpenEdit();
        CustomerLedgerEntries.FILTER.SetFilter("Document No.", GenJournalLine."Document No.");
        CustomerLedgerEntries.FILTER.SetFilter("Document Type", Format(GenJournalLine."Document Type"::Payment));
        CustomerLedgerEntries."Apply Entries".Invoke();

        // [WHEN] Choose "No" in "Payment Discount Tolerance Warning" window
        // Handles by CancelPaymentDiscToleranceWarningModalPageHandler

        // [THEN] No "application successfully posted" message shown
        // [THEN] "Accepted Payment Discount Tolerance" is not set on invoice customer ledger entry
        CustLedgerEntry.SetRange("Customer No.", GenJournalLine."Account No.");
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.TestField("Accepted Pmt. Disc. Tolerance", false);

        // [THEN] "Remainig Amount" equals "Amount" on invoice customer ledger entry
        CustLedgerEntry.CalcFields(Amount, "Remaining Amount");
        CustLedgerEntry.TestField("Remaining Amount", CustLedgerEntry.Amount);
    end;

    [Normal]
    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        // Lazy Setup.
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
        ApplyAndPostCustomerEntry(DocumentType, DocumentNo);

        // Verify: Verify Discount Amount and Additional-Currency Amount in GL Entry.
        DeltaAssert.Assert();
        VerifyGLEntry(Amount2, DocumentNo);
    end;

    local procedure ToleranceDiscountEntry(DocumentType: Enum "Gen. Journal Document Type"; EntryType: Enum "Detailed CV Ledger Entry Type"; DocumentNo: Code[20]; CurrencyCode: Code[10]; Amount: Decimal; Amount2: Decimal)
    begin
        // Exercise: Apply Payment/Refund Amount on Invoice/Credit Memo.
        ApplyAndPostCustomerEntry(DocumentType, DocumentNo);

        // Verify: Verify Payment Tolerance Amount and Additional-Currency Amount in GL Entry.
        VerifyPaymentDiscountTolAmount(DocumentNo, Amount, CurrencyCode, EntryType);
        VerifyGLEntry(Amount2, DocumentNo);
    end;

    local procedure VerifyPaymentDiscountTolAmountCustLedg(DocumentNo: Code[20]; Amount: Decimal; CurrencyCode: Code[10]; EntryType: Enum "Detailed CV Ledger Entry Type")
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        Currency: Record Currency;
        Assert: Codeunit Assert;
    begin
        Currency.Get(CurrencyCode);
        Currency.InitRoundingPrecision();
        DetailedCustLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedCustLedgEntry.SetRange("Entry Type", EntryType);
        DetailedCustLedgEntry.FindFirst();
        Assert.AreNearlyEqual(
          Amount, DetailedCustLedgEntry."Amount (LCY)", Currency."Amount Rounding Precision",
          StrSubstNo(PaymentToleranceError, Amount, DetailedCustLedgEntry.TableCaption(), DetailedCustLedgEntry.FieldCaption("Entry No."),
            DetailedCustLedgEntry."Entry No."));
    end;

    local procedure VerifyRemainingDiscountPossible(DocumentNo: Code[20]; Amount: Decimal; CurrencyCode: Code[10]; EntryType: Enum "Detailed CV Ledger Entry Type")
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        Currency: Record Currency;
        Assert: Codeunit Assert;
    begin
        Currency.Get(CurrencyCode);
        Currency.InitRoundingPrecision();
        DetailedCustLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedCustLedgEntry.SetRange("Entry Type", EntryType);
        DetailedCustLedgEntry.FindFirst();
        Assert.RecordIsNotEmpty(DetailedCustLedgEntry);
        Assert.AreNearlyEqual(
          Amount, DetailedCustLedgEntry."Remaining Pmt. Disc. Possible", Currency."Amount Rounding Precision",
          StrSubstNo(PaymentToleranceError, Amount, DetailedCustLedgEntry.TableCaption(), DetailedCustLedgEntry.FieldCaption("Entry No."),
            DetailedCustLedgEntry."Entry No."));
    end;

    local procedure ApplyCustomerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    var
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        GLRegister: Record "G/L Register";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        CustLedgerEntry.CalcFields("Remaining Amount");
        LibraryERM.SetApplyCustomerEntry(CustLedgerEntry, CustLedgerEntry."Remaining Amount");

        // Find Posted Customer Ledger Entries.
        GLRegister.FindLast();
        CustLedgerEntry2.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        CustLedgerEntry2.SetRange("Applying Entry", false);
        CustLedgerEntry2.FindFirst();
        // Set Applies-to ID.
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry2);
    end;

    local procedure ApplyAndPostCustomerEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        ApplyCustomerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry);
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Terms Code", GetPaymentTerms());
        Customer.Modify(true);
        UpdateCustomerPostingGroup(Customer."Customer Posting Group");
        exit(Customer."No.");
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

    local procedure CreateAndPostDocumentLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; Amount: Decimal; Amount2: Decimal; CurrencyCode: Code[10]; CurrencyCode2: Code[10]; PostingDate: Date)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // Select Journal Batch Name and Template Name.
        LibraryERM.SelectLastGenJnBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        CreateDocumentLine(GenJournalLine, GenJournalBatch, DocumentType, CreateCustomer(), Amount, WorkDate(), CurrencyCode);
        CreateDocumentLine(GenJournalLine, GenJournalBatch, DocumentType2, GenJournalLine."Account No.", Amount2, PostingDate, CurrencyCode2);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateDocumentLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; DocumentType: Enum "Gen. Journal Document Type"; CustomerNo: Code[20]; Amount: Decimal; PostingDate: Date; CurrencyCode: Code[10])
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          GenJournalLine."Account Type"::Customer, CustomerNo, Amount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);
    end;

    local procedure ComputeUnderAmountForMinValue(var Amount: Decimal; var Amount2: Decimal)
    begin
        // To Calculate Payment/Refund value using "Payment Tolerance %" field value from General Ledger Setup need to take fixed
        // higher seed value to 499.
        Amount := LibraryRandom.RandInt(499);
        Amount2 := Amount - (GetPaymentTolerancePercent() + 1);
    end;

    local procedure ComputeUnderAmountForMaxValue(var Amount: Decimal; var Amount2: Decimal)
    begin
        // To Calculate Payment/Refund value using "Max. Payment Tolerance Amount" field value from General Ledger Setup need to take fixed
        // lower seed value to 500.
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

    local procedure GetDueDate(): Date
    var
        PaymentTerms: Record "Payment Terms";
    begin
        PaymentTerms.Get(GetPaymentTerms());
        exit(CalcDate(PaymentTerms."Discount Date Calculation", WorkDate()));
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

    local procedure UpdateCustomerPostingGroup(PostingGroupCode: Code[20])
    var
        CustomerPostingGroup: Record "Customer Posting Group";
        GLAccount: Record "G/L Account";
        Counter: Integer;
    begin
        CustomerPostingGroup.Get(PostingGroupCode);
        GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.SetRange(Blocked, false);
        if GLAccount.FindSet() then
            repeat
                Counter += 1;
                CustomerPostingGroup.Validate("Payment Disc. Debit Acc.", GLAccount."No.");
                CustomerPostingGroup.Validate("Payment Disc. Credit Acc.", GLAccount."No.");
            until (GLAccount.Next() = 0) or (Counter = 2);
        CustomerPostingGroup.Validate("Payment Tolerance Debit Acc.", GLAccount."No.");
        CustomerPostingGroup.Validate("Payment Tolerance Credit Acc.", GLAccount."No.");
        CustomerPostingGroup.Modify(true);
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
    procedure ApplyCustLedgerEntriesModalPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries."Set Applies-to ID".Invoke();
        ApplyCustomerEntries."Post Application".Invoke();
        ApplyCustomerEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostApplicationModalPageHandler(var PostApplication: TestPage "Post Application")
    begin
        PostApplication.OK().Invoke();
    end;

    local procedure VerifyPaymentDiscountTolAmount(DocumentNo: Code[20]; Amount: Decimal; CurrencyCode: Code[10]; EntryType: Enum "Detailed CV Ledger Entry Type")
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        Currency: Record Currency;
        Assert: Codeunit Assert;
    begin
        Currency.Get(CurrencyCode);
        Currency.InitRoundingPrecision();
        DetailedCustLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedCustLedgEntry.SetRange("Entry Type", EntryType);
        DetailedCustLedgEntry.FindFirst();
        Assert.RecordIsNotEmpty(DetailedCustLedgEntry);
        Assert.AreNearlyEqual(
          Amount, DetailedCustLedgEntry."Amount (LCY)", Currency."Amount Rounding Precision",
          StrSubstNo(PaymentToleranceError, Amount, DetailedCustLedgEntry.TableCaption(), DetailedCustLedgEntry.FieldCaption("Entry No."),
            DetailedCustLedgEntry."Entry No."));
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
        GLRegister.FindLast();
        GLEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindFirst();
        Assert.RecordIsNotEmpty(GLEntry);
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

    local procedure VerifyCustomerLedgerEntryDisc(Amount: Decimal; DocumentNo: Code[20])
    var
        CustomerLedgerEntry: Record "Cust. Ledger Entry";
        Currency: Record Currency;
        GeneralLedgerSetup: Record "General Ledger Setup";
        Assert: Codeunit Assert;
        AdditionalCurrencyAmount: Decimal;
    begin
        GeneralLedgerSetup.Get();
        Currency.Get(GeneralLedgerSetup."Additional Reporting Currency");
        Currency.InitRoundingPrecision();
        CustomerLedgerEntry.SetRange("Document No.", DocumentNo);
        CustomerLedgerEntry.FindFirst();
        Assert.RecordIsNotEmpty(CustomerLedgerEntry);
        Assert.AreNearlyEqual(
          Amount, CustomerLedgerEntry."Original Pmt. Disc. Possible", Currency."Amount Rounding Precision", StrSubstNo(RoundingMessage, CustomerLedgerEntry.FieldCaption(Amount),
            CustomerLedgerEntry.Amount, CustomerLedgerEntry.TableCaption(), CustomerLedgerEntry.FieldCaption("Entry No."), CustomerLedgerEntry."Entry No."));

        // Verify Additional Reporting Currency Amount.
        AdditionalCurrencyAmount := LibraryERM.ConvertCurrency(Amount, '', Currency.Code, WorkDate());
        Assert.AreNearlyEqual(
          AdditionalCurrencyAmount, CustomerLedgerEntry."Max. Payment Tolerance", Currency."Amount Rounding Precision",
          StrSubstNo(RoundingMessage, CustomerLedgerEntry.FieldCaption("Max. Payment Tolerance"), CustomerLedgerEntry."Max. Payment Tolerance",
            CustomerLedgerEntry.TableCaption(), CustomerLedgerEntry.FieldCaption("Entry No."), CustomerLedgerEntry."Entry No."));
    end;

    local procedure VerifyCreditMemoAmountDiscount(Amount: Decimal; DocumentNo: Code[20])
    var
        CustomerLedgerEntry: Record "Cust. Ledger Entry";
        Currency: Record Currency;
        GeneralLedgerSetup: Record "General Ledger Setup";
        Assert: Codeunit Assert;
        AdditionalCurrencyAmount: Decimal;
    begin
        GeneralLedgerSetup.Get();
        Currency.Get(GeneralLedgerSetup."Additional Reporting Currency");
        Currency.InitRoundingPrecision();
        CustomerLedgerEntry.SetRange("Document No.", DocumentNo);
        CustomerLedgerEntry.FindFirst();
        Assert.RecordIsNotEmpty(CustomerLedgerEntry);
        Assert.AreNearlyEqual(
          Amount, CustomerLedgerEntry."Pmt. Disc. Given (LCY)", Currency."Amount Rounding Precision", StrSubstNo(RoundingMessage, CustomerLedgerEntry.FieldCaption(Amount),
            CustomerLedgerEntry.Amount, CustomerLedgerEntry.TableCaption(), CustomerLedgerEntry.FieldCaption("Entry No."), CustomerLedgerEntry."Entry No."));

        // Verify Additional Reporting Currency Amount.
        AdditionalCurrencyAmount := LibraryERM.ConvertCurrency(Amount, '', Currency.Code, WorkDate());
        Assert.AreNearlyEqual(
          AdditionalCurrencyAmount, CustomerLedgerEntry."Original Pmt. Disc. Possible", Currency."Amount Rounding Precision",
          StrSubstNo(RoundingMessage, CustomerLedgerEntry.FieldCaption("Original Pmt. Disc. Possible"), CustomerLedgerEntry."Original Pmt. Disc. Possible",
            CustomerLedgerEntry.TableCaption(), CustomerLedgerEntry.FieldCaption("Entry No."), CustomerLedgerEntry."Entry No."));
    end;

    local procedure WatchPaymentDiscountAmount(var DeltaAssert: Codeunit "Delta Assert"; DocumentNo: Code[20]; DiscountAmount: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // Watch Discount Amount expected value should be same as per Delta amount.
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.FindFirst();
        DeltaAssert.AddWatch(
          DATABASE::"Cust. Ledger Entry", CustLedgerEntry.GetPosition(), CustLedgerEntry.FieldNo("Original Pmt. Disc. Possible"),
          CustLedgerEntry."Original Pmt. Disc. Possible" - DiscountAmount);
    end;
}
