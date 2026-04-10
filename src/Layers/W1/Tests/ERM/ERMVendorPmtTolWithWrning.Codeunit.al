codeunit 134016 "ERM Vendor Pmt Tol With Wrning"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Payment Tolerance] [Purchase]
        isInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryPmtDiscSetup: Codeunit "Library - Pmt Disc Setup";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryJournals: Codeunit "Library - Journals";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        AmountError: Label '%1 must be %2 in %3.';

    [Test]
    [Scope('OnPrem')]
    procedure OverPmtWithDisountLCY()
    begin
        // Covers documents TFS_TC_ID=124390,124391.

        // Check Payment Tolerance on various entries after Post General Lines with more Amount and Same Posting Date.
        Initialize();
        OverPmtWithDiscount('', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OverPmtWithDiscountFCY()
    var
        CurrencyCode: Code[10];
    begin
        // Covers documents TFS_TC_ID=124390,124391.

        // Check Payment Tolerance on various entries after Post General Lines with more Amount and Same Posting Date with Currency.
        Initialize();
        CurrencyCode := CreateCurrency();
        OverPmtWithDiscount(CurrencyCode, CurrencyCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OverPmtWithDiscountMultiCur()
    begin
        // Covers documents TFS_TC_ID=124390,124391.

        // Check Payment Tolerance on various entries after Post General Lines with more Amount and Same Posting Date with New Currency.
        Initialize();
        OverPmtWithDiscount(CreateCurrency(), CreateCurrency());
    end;

    local procedure OverPmtWithDiscount(CurrencyCode1: Code[10]; CurrencyCode2: Code[10])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
        Amount2: Decimal;
    begin
        // Modify General Ledger Setup and Post Gen. Journal Lines for Invoice/Credit Memo and Payment/Refund
        // with Random Amount.
        LibraryPmtDiscSetup.SetPmtTolerance(1);

        GeneralLedgerSetup.Get();
        Amount := 10 * LibraryRandom.RandInt(100);
        Amount2 := Amount + GeneralLedgerSetup."Max. Payment Tolerance Amount";

        PaymentWithDiscount(
          CurrencyCode1, CurrencyCode2, GenJournalLine."Document Type"::"Credit Memo",
          GenJournalLine."Document Type"::Refund, Amount, -Amount2);
        PaymentWithDiscount(
          CurrencyCode1, CurrencyCode2, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, -Amount, Amount2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EqualPmtWithDisountLCY()
    begin
        // Covers documents TFS_TC_ID=124390,124392.

        // Check Payment Tolerance on various entries after Post General Lines with more Amount and Same Posting Date.
        Initialize();
        EqualPmtWithDiscount('', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EqualPmtWithDisountFCY()
    var
        CurrencyCode: Code[10];
    begin
        // Covers documents TFS_TC_ID=124390,124392.

        // Check Payment Tolerance on various entries after Post General Lines with more Amount and Same Posting Date with Currency.
        Initialize();
        CurrencyCode := CreateCurrency();
        EqualPmtWithDiscount(CurrencyCode, CurrencyCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EqualPmtWithDisountMultiCur()
    begin
        // Covers documents TFS_TC_ID=124390,124392.

        // Check Payment Tolerance on various entries after Post General Lines with more Amount and Same Posting Date with New Currency.
        Initialize();
        EqualPmtWithDiscount(CreateCurrency(), CreateCurrency());
    end;

    local procedure EqualPmtWithDiscount(CurrencyCode1: Code[10]; CurrencyCode2: Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
    begin
        // Modify General Ledger Setup and Post Gen. Journal Lines for Invoice/Credit Memo and Payment/Refund
        // with Random Amount.
        LibraryPmtDiscSetup.SetPmtTolerance(1);
        Amount := 10 * LibraryRandom.RandInt(100);

        PaymentWithDiscount(
          CurrencyCode1, CurrencyCode2, GenJournalLine."Document Type"::"Credit Memo",
          GenJournalLine."Document Type"::Refund, Amount, -Amount);
        PaymentWithDiscount(
          CurrencyCode1, CurrencyCode2, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, -Amount, Amount);
    end;

    [Test]
    [HandlerFunctions('PaymentDiscTolPageHandler,PaymentTolerancePageHandler')]
    [Scope('OnPrem')]
    procedure LessPmtWithToleranceLCY()
    begin
        // Covers documents TFS_TC_ID=124390,124401,124402,124403.

        // Check Payment Tolerance on various entries after Post General Lines with Less Amount and After Posting Date.
        Initialize();
        LessPmtWithTolerance('', '');
    end;

    [Test]
    [HandlerFunctions('PaymentDiscTolPageHandler,PaymentTolerancePageHandler')]
    [Scope('OnPrem')]
    procedure LessPmtWithToleranceFCY()
    var
        CurrencyCode: Code[10];
    begin
        // Covers documents TFS_TC_ID=124390,124401,124402,124403.

        // Check Payment Tolerance on various entries after Post General Lines with Less Amount and After Posting Date with Currency.
        Initialize();
        CurrencyCode := CreateCurrency();
        LessPmtWithTolerance(CurrencyCode, CurrencyCode);
    end;

    [Test]
    [HandlerFunctions('PaymentDiscTolPageHandler,PaymentTolerancePageHandler')]
    [Scope('OnPrem')]
    procedure LessPmtWithToleranceMultiCur()
    begin
        // Covers documents TFS_TC_ID=124390,124401,124402,124403.

        // Check Payment Tolerance on various entries after Post General Lines with Less Amount and After Posting Date with New Currency.
        Initialize();
        LessPmtWithTolerance(CreateCurrency(), CreateCurrency());
    end;

    local procedure LessPmtWithTolerance(CurrencyCode1: Code[10]; CurrencyCode2: Code[10])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
        Amount2: Decimal;
    begin
        // Check Payment Tolerance on various entries after Post General Lines with Less Amount and After Posting Date.

        // Modify General Ledger Setup and Post Gen. Journal Lines for Invoice/Credit Memo and Payment/Refund
        // with Random Amount.
        LibraryPmtDiscSetup.SetPmtTolerance(1);
        GeneralLedgerSetup.Get();

        ComputePmtTolAmountForMinValue(Amount, Amount2);
        PaymentWithDiscountTolerance(
          CurrencyCode1, CurrencyCode2, GenJournalLine."Document Type"::"Credit Memo",
          GenJournalLine."Document Type"::Refund, Amount, -Amount2);
        ComputePmtTolAmountForMaxValue(Amount, Amount2);
        PaymentWithDiscountTolerance(
          CurrencyCode1, CurrencyCode2, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, -Amount, Amount2);
    end;

    [Test]
    [HandlerFunctions('PaymentTolerancePageHandler')]
    [Scope('OnPrem')]
    procedure UnderAmtBfrDiscDateLCY()
    begin
        // Covers documents TFS_TC_ID=124390, 124393,124394,124395.

        // Check Payment Tolerance on various entries after Post General Lines with Less Amount and Less Posting Date.
        Initialize();
        UnderAmtBfrDiscDate('', '');
    end;

    [Test]
    [HandlerFunctions('PaymentTolerancePageHandler')]
    [Scope('OnPrem')]
    procedure UnderAmtBfrDiscDateFCY()
    var
        CurrencyCode: Code[10];
    begin
        // Covers documents TFS_TC_ID=124390, 124393,124394,124395.

        // Check Payment Tolerance on various entries after Post General Lines with Less Amount and Less Posting Date with Currency.
        Initialize();
        CurrencyCode := CreateCurrency();
        UnderAmtBfrDiscDate(CurrencyCode, CurrencyCode);
    end;

    [Test]
    [HandlerFunctions('PaymentTolerancePageHandler')]
    [Scope('OnPrem')]
    procedure UnderAmtBfrDiscDateMultiCur()
    begin
        // Covers documents TFS_TC_ID=124390, 124393,124394,124395.

        // Check Payment Tolerance on various entries after Post General Lines with Less Amount and Less Posting Date with New Currency.
        Initialize();
        UnderAmtBfrDiscDate(CreateCurrency(), CreateCurrency());
    end;

    local procedure UnderAmtBfrDiscDate(CurrencyCode1: Code[10]; CurrencyCode2: Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
        Amount2: Decimal;
    begin
        // Modify General Ledger Setup and Post Gen. Journal Lines for Credit Memo and Refund with Random Amount.
        LibraryPmtDiscSetup.SetPmtTolerance(1);

        ComputePmtTolAmountForMinValue(Amount, Amount2);
        PaymentWithTolerance(
          CurrencyCode1, CurrencyCode2, GenJournalLine."Document Type"::"Credit Memo",
          GenJournalLine."Document Type"::Refund, Amount, -Amount2);
        PaymentWithTolerance(
          CurrencyCode1, CurrencyCode2, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, -Amount, Amount2);
    end;

    [Test]
    [HandlerFunctions('PaymentDiscTolPageHandler')]
    [Scope('OnPrem')]
    procedure OverWithoutToleranceLCY()
    begin
        // Covers documents TFS_TC_ID=124390,124404,124405,124409,124410.

        // Check Payment Tolerance on various entries after Post General Lines with More Amount and After Posting Date.
        Initialize();
        OverWithoutTolerance('', '');
    end;

    [Test]
    [HandlerFunctions('PaymentDiscTolPageHandler')]
    [Scope('OnPrem')]
    procedure OverWithoutToleranceFCY()
    var
        CurrencyCode: Code[10];
    begin
        // Covers documents TFS_TC_ID=124390,124404,124405,124409,124410.

        // Check Payment Tolerance on various entries after Post General Lines with Less Amount and After Posting Date with Currency.
        Initialize();
        CurrencyCode := CreateCurrency();
        OverWithoutTolerance(CurrencyCode, CurrencyCode);
    end;

    [Test]
    [HandlerFunctions('PaymentDiscTolPageHandler')]
    [Scope('OnPrem')]
    procedure OverWithoutToleranceMultiCur()
    begin
        // Covers documents TFS_TC_ID=124390,124404,124405,124409,124410.

        // Check Payment Tolerance on various entries after Post General Lines with Less Amount and After Posting Date with New Currency.
        Initialize();
        OverWithoutTolerance(CreateCurrency(), CreateCurrency());
    end;

    local procedure OverWithoutTolerance(CurrencyCode1: Code[10]; CurrencyCode2: Code[10])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
        Amount2: Decimal;
    begin
        // Check Payment Tolerance on various entries after Post General Lines with More Amount and After Posting Date.

        // Modify General Ledger Setup and Post Gen. Journal Lines for Credit Memo and Refund with Random Amount.
        LibraryPmtDiscSetup.SetPmtTolerance(1);
        GeneralLedgerSetup.Get();
        Amount := 10 * LibraryRandom.RandInt(100);
        Amount2 := Amount + GeneralLedgerSetup."Max. Payment Tolerance Amount";

        PaymentWithoutTolerance(
          CurrencyCode1, CurrencyCode2, GenJournalLine."Document Type"::"Credit Memo",
          GenJournalLine."Document Type"::Refund, Amount, -Amount2);
        PaymentWithoutTolerance(
          CurrencyCode1, CurrencyCode2, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, -Amount, Amount2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EqualWithoutDiscountLCY()
    begin
        // Covers documents TFS_TC_ID=124390,124406,124407,124408.

        // Check Payment Tolerance on various entries after Post General Lines with Same Amount and After Posting Date.
        Initialize();
        EqualWithoutDiscount('', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EqualWithoutDiscountFCY()
    var
        CurrencyCode: Code[10];
    begin
        // Covers documents TFS_TC_ID=124390,124406,124407,124408.

        // Check Payment Tolerance on various entries after Post General Lines with Same Amount and After Posting Date with Currency.
        Initialize();
        CurrencyCode := CreateCurrency();
        EqualWithoutDiscount(CurrencyCode, CurrencyCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EqualWithoutDiscountMultiCur()
    begin
        // Covers documents TFS_TC_ID=124390,124406,124407,124408.

        // Check Payment Tolerance on various entries after Post General Lines with Same Amount and After Posting Date with New Currency.
        Initialize();
        EqualWithoutDiscount(CreateCurrency(), CreateCurrency());
    end;

    local procedure EqualWithoutDiscount(CurrencyCode1: Code[10]; CurrencyCode2: Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
    begin
        // Check Payment Tolerance on various entries after Post General Lines with Same Amount and After Posting Date.

        // Modify General Ledger Setup and Post Gen. Journal Lines for Credit Memo and Refund with Random Amount.
        LibraryPmtDiscSetup.SetPmtTolerance(1);
        Amount := 10 * LibraryRandom.RandInt(100);

        PaymentWithoutDiscount(
          CurrencyCode1, CurrencyCode2, GenJournalLine."Document Type"::"Credit Memo",
          GenJournalLine."Document Type"::Refund, Amount, -Amount);
        PaymentWithoutDiscount(
          CurrencyCode1, CurrencyCode2, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, -Amount, Amount);
    end;

    [Test]
    [HandlerFunctions('PaymentTolerancePageHandler')]
    [Scope('OnPrem')]
    procedure LessWithoutDiscountLCY()
    begin
        // Covers documents TFS_TC_ID=124390, 124396,124397,124398,124399,124400.

        // Check Payment Tolerance on various entries after Post General Lines with Less Amount and Over Posting Date.
        Initialize();
        LessPmtWithoutDiscount('', '');
    end;

    [Test]
    [HandlerFunctions('PaymentTolerancePageHandler')]
    [Scope('OnPrem')]
    procedure LessPmtWithoutDiscountFCY()
    var
        CurrencyCode: Code[10];
    begin
        // Covers documents TFS_TC_ID=124390, 124396,124397,124398,124399,124400.

        // Check Payment Tolerance on various entries after Post General Lines with Less Amount and Over Posting Date with Currency.
        Initialize();
        CurrencyCode := CreateCurrency();
        LessPmtWithoutDiscount(CurrencyCode, CurrencyCode);
    end;

    [Test]
    [HandlerFunctions('PaymentTolerancePageHandler')]
    [Scope('OnPrem')]
    procedure LessPmtWithoutDiscountMultiCur()
    begin
        // Covers documents TFS_TC_ID=124390, 124396,124397,124398,124399,124400.

        // Check Payment Tolerance on various entries after Post General Lines with Less Amount and Over Posting Date with New Currency.
        Initialize();
        LessPmtWithoutDiscount(CreateCurrency(), CreateCurrency());
    end;

    local procedure LessPmtWithoutDiscount(CurrencyCode1: Code[10]; CurrencyCode2: Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        Amount: Decimal;
        Amount2: Decimal;
    begin
        // Modify General Ledger Setup and Post Gen. Journal Lines for Credit Memo and Refund with Random Amount.
        LibraryPmtDiscSetup.SetPmtTolerance(1);
        GeneralLedgerSetup.Get();

        ComputePmtTolAmountForMinValue(Amount, Amount2);
        PaymentWithoutDiscount(
          CurrencyCode1, CurrencyCode2, GenJournalLine."Document Type"::"Credit Memo",
          GenJournalLine."Document Type"::Refund, Amount, -Amount2);
        ComputeAmountForABSMaxValue(Amount, Amount2);
        PaymentWithoutDiscount(
          CurrencyCode1, CurrencyCode2, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, -Amount, Amount2);
    end;

    [Normal]
    local procedure PaymentWithoutDiscount(CurrencyCode: Code[10]; CurrencyCode2: Code[10]; GenJnlDocumentType: Enum "Gen. Journal Document Type"; GenJnlDocumentType2: Enum "Gen. Journal Document Type"; Amount: Decimal; Amount2: Decimal)
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
    begin
        // Setup: Modify General Ledger Setup and Post Gen. Journal Lines for Invoice and Payment with Random Amount and
        // attached currency and Post them.
        CreateAndPostJnlLine(GenJournalLine, CurrencyCode, GenJnlDocumentType, Amount);

        // Exercise: Apply Invoice Document No. with Payment Gen. Journal Line and Post it.
        DocumentNo :=
          PostApplicationJnlLine(GenJournalLine, CurrencyCode2, GenJnlDocumentType2,
            Amount2, CalcDate('<' + LibraryPmtDiscSetup.GetPmtDiscGracePeriod() + '>', CalcDate('<1M>', CalcDueDate())));

        // Verify: Verify Vendor Ledger Entry, Detailed Vendor Ledger Entry.
        VerifyVendorLedgerEntry(GenJnlDocumentType, GenJournalLine."Document No.", (Amount * GetDiscountPercent() / 100));
        VerifyDetldVendorLedgerEntry(
          GenJnlDocumentType2, DetailedVendorLedgEntry."Entry Type"::Application, DocumentNo, -GetAmountFCY(CurrencyCode2, Amount));
    end;

    [Normal]
    local procedure PaymentWithDiscount(CurrencyCode: Code[10]; CurrencyCode2: Code[10]; GenJnlDocumentType: Enum "Gen. Journal Document Type"; GenJnlDocumentType2: Enum "Gen. Journal Document Type"; Amount: Decimal; Amount2: Decimal)
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
        PmtDiscount: Decimal;
    begin
        // Setup: Modify General Ledger Setup and Post Gen. Journal Lines with Random Amount and
        // attached currency and Post them.
        CreateAndPostJnlLine(GenJournalLine, CurrencyCode, GenJnlDocumentType, Amount);

        // Exercise: Apply Document with Gen. Journal Line and Post it.
        DocumentNo := PostApplicationJnlLine(GenJournalLine, CurrencyCode2, GenJnlDocumentType2, Amount2, CalcDueDate());

        // Verify: Verify Vendor Ledger Entry, Detailed Vendor Ledger Entry and G/L Entry.
        PmtDiscount := GetAmountFCY(CurrencyCode2, GetDiscountAmount(Amount));
        VerifyVendorLedgerEntry(GenJnlDocumentType, GenJournalLine."Document No.", GetDiscountAmount(Amount));
        VerifyDetldVendorLedgerEntry(GenJnlDocumentType2, DetailedVendorLedgEntry."Entry Type"::"Payment Discount", DocumentNo, -PmtDiscount);
    end;

    [Normal]
    local procedure PaymentWithTolerance(CurrencyCode: Code[10]; CurrencyCode2: Code[10]; GenJnlDocumentType: Enum "Gen. Journal Document Type"; GenJnlDocumentType2: Enum "Gen. Journal Document Type"; Amount: Decimal; Amount2: Decimal)
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
        PmtTolAmount: Decimal;
    begin
        // Setup: Modify General Ledger Setup and Post Gen. Journal Lines with Random Amount and
        // attached currency and Post them.
        CreateAndPostJnlLine(GenJournalLine, CurrencyCode, GenJnlDocumentType, Amount);

        // Exercise: Apply Invoice/Credit Memo Document No. with Payment/Refund Gen. Journal Line and Post it.
        DocumentNo := PostApplicationJnlLine(GenJournalLine, CurrencyCode2, GenJnlDocumentType2, Amount2, CalcDate('<-1D>', CalcDueDate()));

        // Verify: Verify Vendor Ledger Entry, Detailed Vendor Ledger Entry.
        PmtTolAmount := GetAmountFCY(CurrencyCode2, Amount2 + (Amount - GetDiscountAmount(Amount)));
        VerifyVendorLedgerEntry(GenJnlDocumentType, GenJournalLine."Document No.", GetDiscountAmount(Amount));
        VerifyDetldVendorLedgerEntry(
          GenJnlDocumentType2, DetailedVendorLedgEntry."Entry Type"::"Payment Tolerance", DocumentNo, -PmtTolAmount);
    end;

    local procedure PaymentWithoutTolerance(CurrencyCode: Code[10]; CurrencyCode2: Code[10]; GenJnlDocumentType: Enum "Gen. Journal Document Type"; GenJnlDocumentType2: Enum "Gen. Journal Document Type"; Amount: Decimal; Amount2: Decimal)
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
        PmtDiscount: Decimal;
    begin
        // Setup: Modify General Ledger Setup and Post Gen. Journal Lines with Random Amount and
        // attached currency and Post them.
        CreateAndPostJnlLine(GenJournalLine, CurrencyCode, GenJnlDocumentType, Amount);

        // Exercise: Apply Credit Memo Document No. with Refund Gen. Journal Line and Post it.
        DocumentNo := PostApplicationJnlLine(GenJournalLine, CurrencyCode2, GenJnlDocumentType2, Amount2, CalcDate('<1D>', CalcDueDate()));

        // Verify: Verify Vendor Ledger Entry and Detailed Vendor Ledger Entry.
        PmtDiscount := GetAmountFCY(CurrencyCode2, GetDiscountAmount(Amount));
        VerifyVendorLedgerEntry(GenJnlDocumentType, GenJournalLine."Document No.", Amount * GetDiscountPercent() / 100);
        VerifyDetldVendorLedgerEntry(
          GenJnlDocumentType2, DetailedVendorLedgEntry."Entry Type"::"Payment Discount Tolerance", DocumentNo, -PmtDiscount);
    end;

    local procedure PaymentWithDiscountTolerance(CurrencyCode: Code[10]; CurrencyCode2: Code[10]; GenJnlDocumentType: Enum "Gen. Journal Document Type"; GenJnlDocumentType2: Enum "Gen. Journal Document Type"; Amount: Decimal; Amount2: Decimal)
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
        PmtTolAmount: Decimal;
    begin
        // Setup: Modify General Ledger Setup and Post Gen. Journal Lines for Invoice and Payment with Random Amount and
        // attached currency and Post them.
        CreateAndPostJnlLine(GenJournalLine, CurrencyCode, GenJnlDocumentType, Amount);

        // Exercise: Apply Document with Gen. Journal Line and Post it.
        DocumentNo := PostApplicationJnlLine(GenJournalLine, CurrencyCode2, GenJnlDocumentType2, Amount2, CalcDate('<1D>', CalcDueDate()));

        // Verify: Verify Vendor Ledger Entry, Detailed Vendor Ledger Entry and G/L Entry.
        PmtTolAmount := GetAmountFCY(CurrencyCode2, Amount2 + (Amount - GetDiscountAmount(Amount)));
        VerifyDetldVendorLedgerEntry(
          GenJnlDocumentType2, DetailedVendorLedgEntry."Entry Type"::"Payment Tolerance", DocumentNo, -PmtTolAmount);
        VerifyDetldVendorLedgerEntry(GenJnlDocumentType2, DetailedVendorLedgEntry."Entry Type"::"Payment Discount Tolerance", DocumentNo,
          -GetAmountFCY(CurrencyCode2, GetDiscountAmount(Amount)));
    end;

    local procedure CreateAndPostJnlLine(var GenJournalLine: Record "Gen. Journal Line"; CurrencyCode: Code[10]; GenJnlDocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal)
    begin
        // Setup: Modify General Ledger Setup and Post Gen. Journal Lines for Invoice and Payment with Random Amount and
        // attached currency and Post them.
        CreateDocumentLine(GenJournalLine, GenJnlDocumentType, CreateVendor(), Amount, CurrencyCode, WorkDate());
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure PostApplicationJnlLine(GenJournalLine: Record "Gen. Journal Line"; CurrencyCode: Code[10]; GenJnlDocumentType: Enum "Gen. Journal Document Type"; Amount2: Decimal; DueDate: Date): Code[20]
    var
        GenJournalLine2: Record "Gen. Journal Line";
    begin
        // Set Amount and Posting Date with Payment Terms for Payment Tolerance Discount.
        CreateDocumentLine(GenJournalLine2, GenJnlDocumentType, GenJournalLine."Account No.", Amount2, CurrencyCode, DueDate);

        // Exercise: Apply Document with Gen. Journal Line and Post it.
        UpdateAndPostGenJnlLine(GenJournalLine2, GenJournalLine."Document Type", GenJournalLine."Document No.");
        exit(GenJournalLine2."Document No.");
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure ApplyUnderRefundToCrMemosWhenFirstTwoHaveMaxPmtTolerance()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DocumentType: Enum "Gen. Journal Document Type";
        CrMemoAmounts: List of [Decimal];
        MaxTolAmounts: List of [Decimal];
        ExpectedPmtTolAmounts: List of [Decimal];
        TotalCrMemoAmount: Decimal;
        TotalTolAmount: Decimal;
        VendorNo: Code[20];
    begin
        // [SCENARIO 377808] Apply Refund with underpaid Amount to four posted Purchase Credit Memos when the first two of them have different non-zero "Max. Payment Tolerance".
        Initialize();

        // [GIVEN] Four posted Purchase Credit Memos with Amounts = 100.
        VendorNo := CreateVendor();
        FillListWithDecimalValues(
            CrMemoAmounts, TotalCrMemoAmount, LibraryRandom.RandDecInRange(100, 200, 2), LibraryRandom.RandDecInRange(100, 200, 2),
            LibraryRandom.RandDecInRange(100, 200, 2), LibraryRandom.RandDecInRange(100, 200, 2));
        CreateGenJournalLinesDifferentAmount(GenJournalLine, DocumentType::"Credit Memo", VendorNo, CrMemoAmounts);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] First two posted Purchase Credit Memos have "Max. Payment Tolerance" = 5.
        // [GIVEN] Last two posted Purchase Credit Memos have "Max. Payment Tolerance" = 0.
        FillListWithDecimalValues(
            MaxTolAmounts, TotalTolAmount, LibraryRandom.RandDecInRange(5, 10, 2), LibraryRandom.RandDecInRange(5, 10, 2), 0, 0);
        UpdateMaxPaymentToleranceOnVendorLedgerEntry(VendorNo, DocumentType::"Credit Memo", MaxTolAmounts);

        // [GIVEN] Refund with Amount = (<sum of Credit Memos Amounts> - <half of sum of Max Payment Tolerance Amounts>), i.e. 400 - 5 = 395.
        // [GIVEN] Posting Date of Refund is larger that Due Date of posted Purchase Credit Memos to avoid discounts caused by Payment Terms.
        CreateDocumentLine(
            GenJournalLine, DocumentType::Refund, VendorNo, -TotalCrMemoAmount + TotalTolAmount / 2,
            '', LibraryRandom.RandDateFromInRange(GenJournalLine."Due Date", 10, 20));

        // [WHEN] Apply Refund to four posted Purchase Credit Memos and then post Refund.
        ApplyAndPostJournalLines(GenJournalLine, DocumentType::"Credit Memo");

        // [THEN] All posted Purchase Credit Memos were closed, i.e. Remaining Amount = 0, Open = false.
        // [THEN] Underpaid Amount = 5 was distributed over the first two posted Purchase Credit Memos with the proportion = proportion of their Amounts.
        ExpectedPmtTolAmounts.Add((TotalTolAmount / 2) * CrMemoAmounts.Get(1) / (CrMemoAmounts.Get(1) + CrMemoAmounts.Get(2)));
        ExpectedPmtTolAmounts.Add((TotalTolAmount / 2) * CrMemoAmounts.Get(2) / (CrMemoAmounts.Get(1) + CrMemoAmounts.Get(2)));
        ExpectedPmtTolAmounts.Add(0);
        ExpectedPmtTolAmounts.Add(0);
        VerifyPmtToleranceOnClosedVendorLedgerEntry(VendorNo, DocumentType::"Credit Memo", ExpectedPmtTolAmounts);
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure ApplyOverRefundToCrMemosWhenFirstTwoHaveMaxPmtTolerance()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DocumentType: Enum "Gen. Journal Document Type";
        CrMemoAmounts: List of [Decimal];
        MaxTolAmounts: List of [Decimal];
        ExpectedPmtTolAmounts: List of [Decimal];
        TotalCrMemoAmount: Decimal;
        TotalTolAmount: Decimal;
        VendorNo: Code[20];
    begin
        // [SCENARIO 377808] Apply Refund with overpaid Amount to four posted Purchase Credit Memos when the first two of them have different non-zero "Max. Payment Tolerance".
        Initialize();

        // [GIVEN] Four posted Purchase Credit Memos with Amounts = 100.
        VendorNo := CreateVendor();
        FillListWithDecimalValues(
            CrMemoAmounts, TotalCrMemoAmount, LibraryRandom.RandDecInRange(100, 200, 2), LibraryRandom.RandDecInRange(100, 200, 2),
            LibraryRandom.RandDecInRange(100, 200, 2), LibraryRandom.RandDecInRange(100, 200, 2));
        CreateGenJournalLinesDifferentAmount(GenJournalLine, DocumentType::"Credit Memo", VendorNo, CrMemoAmounts);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] First two posted Purchase Credit Memos have "Max. Payment Tolerance" = 5.
        // [GIVEN] Last two posted Purchase Credit Memos have "Max. Payment Tolerance" = 0.
        FillListWithDecimalValues(
            MaxTolAmounts, TotalTolAmount, LibraryRandom.RandDecInRange(5, 10, 2), LibraryRandom.RandDecInRange(5, 10, 2), 0, 0);
        UpdateMaxPaymentToleranceOnVendorLedgerEntry(VendorNo, DocumentType::"Credit Memo", MaxTolAmounts);

        // [GIVEN] Refund with Amount = (<sum of Credit Memos Amounts> + <half of sum of Max Payment Tolerance Amounts>), i.e. 400 + 5 = 405.
        // [GIVEN] Posting Date of Refund is larger that Due Date of posted Purchase Credit Memos to avoid discounts caused by Payment Terms.
        CreateDocumentLine(
            GenJournalLine, DocumentType::Refund, VendorNo, -TotalCrMemoAmount - TotalTolAmount / 2,
            '', LibraryRandom.RandDateFromInRange(GenJournalLine."Due Date", 10, 20));

        // [WHEN] Apply Refund to four posted Purchase Credit Memos and then post Refund.
        ApplyAndPostJournalLines(GenJournalLine, DocumentType::"Credit Memo");

        // [THEN] All posted Purchase Credit Memos were closed, i.e. Remaining Amount = 0, Open = false.
        // [THEN] Overpaid Amount = 5 was distributed over the first two posted Purchase Credit Memos with the proportion = proportion of their Amounts.
        ExpectedPmtTolAmounts.Add(-(TotalTolAmount / 2) * CrMemoAmounts.Get(1) / (CrMemoAmounts.Get(1) + CrMemoAmounts.Get(2)));
        ExpectedPmtTolAmounts.Add(-(TotalTolAmount / 2) * CrMemoAmounts.Get(2) / (CrMemoAmounts.Get(1) + CrMemoAmounts.Get(2)));
        ExpectedPmtTolAmounts.Add(0);
        ExpectedPmtTolAmounts.Add(0);
        VerifyPmtToleranceOnClosedVendorLedgerEntry(VendorNo, DocumentType::"Credit Memo", ExpectedPmtTolAmounts);
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure ApplyUnderPmtToInvoicesWhenFirstTwoHaveMaxPmtTolerance()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DocumentType: Enum "Gen. Journal Document Type";
        InvAmounts: List of [Decimal];
        MaxTolAmounts: List of [Decimal];
        ExpectedPmtTolAmounts: List of [Decimal];
        TotalInvAmount: Decimal;
        TotalTolAmount: Decimal;
        VendorNo: Code[20];
    begin
        // [SCENARIO 377808] Apply Payment with underpaid Amount to four posted Purchase Invoices when the first two of them have different non-zero "Max. Payment Tolerance".
        Initialize();

        // [GIVEN] Four posted Purchase Invoices with Amounts = 100.
        VendorNo := CreateVendor();
        FillListWithDecimalValues(
            InvAmounts, TotalInvAmount, -LibraryRandom.RandDecInRange(100, 200, 2), -LibraryRandom.RandDecInRange(100, 200, 2),
            -LibraryRandom.RandDecInRange(100, 200, 2), -LibraryRandom.RandDecInRange(100, 200, 2));
        CreateGenJournalLinesDifferentAmount(GenJournalLine, DocumentType::Invoice, VendorNo, InvAmounts);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] First two posted Purchase Invoices have "Max. Payment Tolerance" = 5.
        // [GIVEN] Last two posted Purchase Invoices have "Max. Payment Tolerance" = 0.
        FillListWithDecimalValues(
            MaxTolAmounts, TotalTolAmount, -LibraryRandom.RandDecInRange(5, 10, 2), -LibraryRandom.RandDecInRange(5, 10, 2), 0, 0);
        UpdateMaxPaymentToleranceOnVendorLedgerEntry(VendorNo, DocumentType::Invoice, MaxTolAmounts);

        // [GIVEN] Payment with Amount = (<sum of Invoices Amounts> - <half of sum of Max Payment Tolerance Amounts>), i.e. 400 - 5 = 395.
        // [GIVEN] Posting Date of Payment is larger that Due Date of posted Purchase Invoices to avoid discounts caused by Payment Terms.
        CreateDocumentLine(
            GenJournalLine, DocumentType::Payment, VendorNo, -TotalInvAmount + TotalTolAmount / 2,
            '', LibraryRandom.RandDateFromInRange(GenJournalLine."Due Date", 10, 20));

        // [WHEN] Apply Payment to four posted Purchase Invoices and then post Payment.
        ApplyAndPostJournalLines(GenJournalLine, DocumentType::Invoice);

        // [THEN] All posted Purchase Invoices were closed, i.e. Remaining Amount = 0, Open = false.
        // [THEN] Underpaid Amount = 5 was distributed over the first two posted Purchase Invoices with the proportion = proportion of their Amounts.
        ExpectedPmtTolAmounts.Add((TotalTolAmount / 2) * InvAmounts.Get(1) / (InvAmounts.Get(1) + InvAmounts.Get(2)));
        ExpectedPmtTolAmounts.Add((TotalTolAmount / 2) * InvAmounts.Get(2) / (InvAmounts.Get(1) + InvAmounts.Get(2)));
        ExpectedPmtTolAmounts.Add(0);
        ExpectedPmtTolAmounts.Add(0);
        VerifyPmtToleranceOnClosedVendorLedgerEntry(VendorNo, DocumentType::Invoice, ExpectedPmtTolAmounts);
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure ApplyUnderRefundToCrMemosWhenLastTwoHaveMaxPmtTolerance()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DocumentType: Enum "Gen. Journal Document Type";
        CrMemoAmounts: List of [Decimal];
        MaxTolAmounts: List of [Decimal];
        ExpectedPmtTolAmounts: List of [Decimal];
        TotalCrMemoAmount: Decimal;
        TotalTolAmount: Decimal;
        VendorNo: Code[20];
    begin
        // [SCENARIO 377808] Apply Refund with underpaid Amount to four posted Purchase Credit Memos when the last two of them have different non-zero "Max. Payment Tolerance".
        Initialize();

        // [GIVEN] Four posted Purchase Credit Memos with Amounts = 100.
        VendorNo := CreateVendor();
        FillListWithDecimalValues(
            CrMemoAmounts, TotalCrMemoAmount, LibraryRandom.RandDecInRange(100, 200, 2), LibraryRandom.RandDecInRange(100, 200, 2),
            LibraryRandom.RandDecInRange(100, 200, 2), LibraryRandom.RandDecInRange(100, 200, 2));
        CreateGenJournalLinesDifferentAmount(GenJournalLine, DocumentType::"Credit Memo", VendorNo, CrMemoAmounts);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] First two posted Purchase Credit Memos have "Max. Payment Tolerance" = 0.
        // [GIVEN] Last two posted Purchase Credit Memos have "Max. Payment Tolerance" = 5.
        FillListWithDecimalValues(
            MaxTolAmounts, TotalTolAmount, 0, 0, LibraryRandom.RandDecInRange(5, 10, 2), LibraryRandom.RandDecInRange(5, 10, 2));
        UpdateMaxPaymentToleranceOnVendorLedgerEntry(VendorNo, DocumentType::"Credit Memo", MaxTolAmounts);

        // [GIVEN] Refund with Amount = (<sum of Credit Memos Amounts> - <half of sum of Max Payment Tolerance Amounts>), i.e. 400 - 5 = 395.
        // [GIVEN] Posting Date of Refund is larger that Due Date of posted Purchase Credit Memos to avoid discounts caused by Payment Terms.
        CreateDocumentLine(
            GenJournalLine, DocumentType::Refund, VendorNo, -TotalCrMemoAmount + TotalTolAmount / 2,
            '', LibraryRandom.RandDateFromInRange(GenJournalLine."Due Date", 10, 20));

        // [WHEN] Apply Refund to four posted Purchase Credit Memos and then post Refund.
        ApplyAndPostJournalLines(GenJournalLine, DocumentType::"Credit Memo");

        // [THEN] All posted Purchase Credit Memos were closed, i.e. Remaining Amount = 0, Open = false.
        // [THEN] Underpaid Amount = 5 was distributed over the last two posted Purchase Credit Memos with the proportion = proportion of their Amounts.
        ExpectedPmtTolAmounts.Add(0);
        ExpectedPmtTolAmounts.Add(0);
        ExpectedPmtTolAmounts.Add((TotalTolAmount / 2) * CrMemoAmounts.Get(3) / (CrMemoAmounts.Get(3) + CrMemoAmounts.Get(4)));
        ExpectedPmtTolAmounts.Add((TotalTolAmount / 2) * CrMemoAmounts.Get(4) / (CrMemoAmounts.Get(3) + CrMemoAmounts.Get(4)));
        VerifyPmtToleranceOnClosedVendorLedgerEntry(VendorNo, DocumentType::"Credit Memo", ExpectedPmtTolAmounts);
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure ApplyUnderRefundToCrMemosWhenBigAmtSmallToleranceAndSmallAmtBigTolerance()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DocumentType: Enum "Gen. Journal Document Type";
        CrMemoAmounts: List of [Decimal];
        MaxTolAmounts: List of [Decimal];
        ExpectedPmtTolAmounts: List of [Decimal];
        TotalCrMemoAmount: Decimal;
        TotalTolAmount: Decimal;
        VendorNo: Code[20];
    begin
        // [SCENARIO 377808] Apply Refund with underpaid Amount to posted Purchase Credit Memos when first Credit Memo has big Amount and small Tolerance, and the second one has small Amount and big Tolerance.
        Initialize();

        // [GIVEN] Posted Purchase Credit Memo with Amount = 10000.
        // [GIVEN] Posted Purchase Credit Memo with Amount = 100.
        // [GIVEN] Two posted Purchase Credit Memos with Amount = 100.
        VendorNo := CreateVendor();
        FillListWithDecimalValues(
            CrMemoAmounts, TotalCrMemoAmount, LibraryRandom.RandDecInRange(10000, 20000, 2), LibraryRandom.RandDecInRange(100, 200, 2),
            LibraryRandom.RandDecInRange(100, 200, 2), LibraryRandom.RandDecInRange(100, 200, 2));
        CreateGenJournalLinesDifferentAmount(GenJournalLine, DocumentType::"Credit Memo", VendorNo, CrMemoAmounts);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] First posted Purchase Credit Memo has "Max. Payment Tolerance" = 1.
        // [GIVEN] Second posted Purchase Credit Memo has "Max. Payment Tolerance" = 10.
        // [GIVEN] Last two posted Purchase Credit Memos have "Max. Payment Tolerance" = 0.
        FillListWithDecimalValues(
            MaxTolAmounts, TotalTolAmount, LibraryRandom.RandDecInRange(1, 2, 2), LibraryRandom.RandDecInRange(10, 20, 2), 0, 0);
        UpdateMaxPaymentToleranceOnVendorLedgerEntry(VendorNo, DocumentType::"Credit Memo", MaxTolAmounts);

        // [GIVEN] Refund with Amount = (<sum of Credit Memos Amounts> - <half of sum of Max Payment Tolerance Amounts>), i.e. 10300 - 5.5 = 10294.5.
        // [GIVEN] Posting Date of Refund is larger that Due Date of posted Purchase Credit Memos to avoid discounts caused by Payment Terms.
        CreateDocumentLine(
            GenJournalLine, DocumentType::Refund, VendorNo, -TotalCrMemoAmount + TotalTolAmount / 2,
            '', LibraryRandom.RandDateFromInRange(GenJournalLine."Due Date", 10, 20));

        // [WHEN] Apply Refund to four posted Purchase Credit Memos and then post Refund.
        ApplyAndPostJournalLines(GenJournalLine, DocumentType::"Credit Memo");

        // [THEN] All posted Purchase Credit Memos were closed, i.e. Remaining Amount = 0, Open = false.
        // [THEN] Underpaid Amount = 5.5 was distributed over the first two posted Purchase Credit Memos.
        // [THEN] "Pmt. Tolerance" = 1 for the first Credit Memo, because "Max. Payment Tolerance" < 5.5 * (10000/10100) ~ 5.45.
        // [THEN] "Pmt. Tolerance" = 5.5 - 1 = 4.5 for the second Credit Memo.
        ExpectedPmtTolAmounts.Add(MaxTolAmounts.Get(1));
        ExpectedPmtTolAmounts.Add(TotalTolAmount / 2 - MaxTolAmounts.Get(1));
        ExpectedPmtTolAmounts.Add(0);
        ExpectedPmtTolAmounts.Add(0);
        VerifyPmtToleranceOnClosedVendorLedgerEntry(VendorNo, DocumentType::"Credit Memo", ExpectedPmtTolAmounts);
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure ApplyOverRefundToCrMemosWhenBigAmtSmallToleranceAndSmallAmtBigTolerance()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DocumentType: Enum "Gen. Journal Document Type";
        CrMemoAmounts: List of [Decimal];
        MaxTolAmounts: List of [Decimal];
        ExpectedPmtTolAmounts: List of [Decimal];
        TotalCrMemoAmount: Decimal;
        TotalTolAmount: Decimal;
        VendorNo: Code[20];
    begin
        // [SCENARIO 377808] Apply Refund with overpaid Amount to posted Purchase Credit Memos when first Credit Memo has big Amount and small Tolerance, and the second one has small Amount and big Tolerance.
        Initialize();

        // [GIVEN] Posted Purchase Credit Memo with Amount = 10000.
        // [GIVEN] Posted Purchase Credit Memo with Amount = 100.
        // [GIVEN] Two posted Purchase Credit Memos with Amount = 100.
        VendorNo := CreateVendor();
        FillListWithDecimalValues(
            CrMemoAmounts, TotalCrMemoAmount, LibraryRandom.RandDecInRange(10000, 20000, 2), LibraryRandom.RandDecInRange(100, 200, 2),
            LibraryRandom.RandDecInRange(100, 200, 2), LibraryRandom.RandDecInRange(100, 200, 2));
        CreateGenJournalLinesDifferentAmount(GenJournalLine, DocumentType::"Credit Memo", VendorNo, CrMemoAmounts);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] First posted Purchase Credit Memo has "Max. Payment Tolerance" = 1.
        // [GIVEN] Second posted Purchase Credit Memo has "Max. Payment Tolerance" = 10.
        // [GIVEN] Last two posted Purchase Credit Memos have "Max. Payment Tolerance" = 0.
        FillListWithDecimalValues(
            MaxTolAmounts, TotalTolAmount, LibraryRandom.RandDecInRange(1, 2, 2), LibraryRandom.RandDecInRange(10, 20, 2), 0, 0);
        UpdateMaxPaymentToleranceOnVendorLedgerEntry(VendorNo, DocumentType::"Credit Memo", MaxTolAmounts);

        // [GIVEN] Refund with Amount = (<sum of Credit Memos Amounts> + <half of sum of Max Payment Tolerance Amounts>), i.e. 10300 + 5.5 = 10305.5.
        // [GIVEN] Posting Date of Refund is larger that Due Date of posted Purchase Credit Memos to avoid discounts caused by Payment Terms.
        CreateDocumentLine(
            GenJournalLine, DocumentType::Refund, VendorNo, -TotalCrMemoAmount - TotalTolAmount / 2,
            '', LibraryRandom.RandDateFromInRange(GenJournalLine."Due Date", 10, 20));

        // [WHEN] Apply Refund to four posted Purchase Credit Memos and then post Refund.
        ApplyAndPostJournalLines(GenJournalLine, DocumentType::"Credit Memo");

        // [THEN] All posted Purchase Credit Memos were closed, i.e. Remaining Amount = 0, Open = false.
        // [THEN] Overpaid Amount = 5.5 was distributed over the first two posted Purchase Credit Memos.
        // [THEN] "Pmt. Tolerance" = -1 for the first Credit Memo, because Abs("Max. Payment Tolerance") < Abs(-5.5) * (10000/10100) ~ 5.45.
        // [THEN] "Pmt. Tolerance" = -5.5 + 1 = 4.5 for the second Credit Memo.
        ExpectedPmtTolAmounts.Add(-MaxTolAmounts.Get(1));
        ExpectedPmtTolAmounts.Add(-TotalTolAmount / 2 + MaxTolAmounts.Get(1));
        ExpectedPmtTolAmounts.Add(0);
        ExpectedPmtTolAmounts.Add(0);
        VerifyPmtToleranceOnClosedVendorLedgerEntry(VendorNo, DocumentType::"Credit Memo", ExpectedPmtTolAmounts);
    end;

    [Normal]
    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Vendor Pmt Tol With Wrning");
        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Vendor Pmt Tol With Wrning");

        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        isInitialized := true;
        Commit();
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Vendor Pmt Tol With Wrning")
    end;

    local procedure ApplyAndPostJournalLines(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type")
    var
        GLRegister: Record "G/L Register";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GenJnlApply: Codeunit "Gen. Jnl.-Apply";
        VendEntrySetApplID: Codeunit "Vend. Entry-SetAppl.ID";
        ApplyVendorEntries: Page "Apply Vendor Entries";
    begin
        GLRegister.FindLast();
        VendorLedgerEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        VendorLedgerEntry.SetRange("Document Type", DocumentType);
        VendorLedgerEntry.FindSet();
        repeat
            VendEntrySetApplID.SetApplId(VendorLedgerEntry, VendorLedgerEntry, GenJournalLine."Document No.");
            ApplyVendorEntries.CalcApplnAmount();
        until VendorLedgerEntry.Next() = 0;
        Commit();
        GenJnlApply.Run(GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure ComputePmtTolAmountForMinValue(var Amount: Decimal; var Amount2: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // To Calculate Payment/Refund value using "Payment Tolerance %" field value from General Ledger Setup need to take fixed
        // higher seed value to 499.
        GeneralLedgerSetup.Get();
        Amount := LibraryRandom.RandInt(499);
        Amount2 := Amount - (Amount * GeneralLedgerSetup."Payment Tolerance %" / 100);
    end;

    local procedure ComputePmtTolAmountForMaxValue(var Amount: Decimal; var Amount2: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // To Calculate Payment/Refund value using "Max. Payment Tolerance Amount" field value from General Ledger Setup need to take fixed
        // lower seed value to 500.
        GeneralLedgerSetup.Get();
        Amount := 500 * LibraryRandom.RandInt(5);
        Amount2 := Amount - (GeneralLedgerSetup."Max. Payment Tolerance Amount" + (Amount * GetDiscountPercent() / 100));
    end;

    local procedure ComputeAmountForABSMaxValue(var Amount: Decimal; var Amount2: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // To Calculate Payment/Refund value using "Max. Payment Tolerance Amount" field value from General Ledger Setup need to take fixed
        // lower seed value to 500.
        GeneralLedgerSetup.Get();
        Amount := 500 * LibraryRandom.RandInt(5);
        Amount2 := Amount - GeneralLedgerSetup."Max. Payment Tolerance Amount";
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

        // Create Exchange Rate.
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        Commit();
        exit(Currency.Code);
    end;

    local procedure CreateDocumentLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; VendorNo: Code[20]; Amount: Decimal; CurrencyCode: Code[10]; PostingDate: Date)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // Select Journal Batch Name and Template Name.
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType, GenJournalLine."Account Type"::Vendor,
          VendorNo, Amount);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateGenJournalLinesDifferentAmount(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; VendorNo: Code[20]; Amounts: List of [Decimal])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJnlAccType: Enum "Gen. Journal Account Type";
        BalGLAccountNo: Code[20];
        i: Integer;
    begin
        BalGLAccountNo := LibraryERM.CreateGLAccountNo();
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, LibraryERM.SelectGenJnlTemplate());
        for i := 1 to Amounts.Count() do
            LibraryJournals.CreateGenJournalLine(
                GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
                GenJnlAccType::Vendor, VendorNo, GenJnlAccType::"G/L Account", BalGLAccountNo, Amounts.Get(i));
    end;

    local procedure CalcDueDate(): Date
    var
        PaymentTerms: Record "Payment Terms";
    begin
        PaymentTerms.Get(GetPaymentTerms());
        exit(CalcDate(PaymentTerms."Discount Date Calculation", WorkDate()));
    end;

    local procedure FillListWithDecimalValues(var DecimalsList: List of [Decimal]; var TotalValue: Decimal; Value1: Decimal; Value2: Decimal; Value3: Decimal; Value4: Decimal)
    begin
        DecimalsList.Add(Value1);
        DecimalsList.Add(Value2);
        DecimalsList.Add(Value3);
        DecimalsList.Add(Value4);
        TotalValue := Value1 + Value2 + Value3 + Value4;
    end;

    local procedure GetDiscountPercent(): Decimal
    var
        PaymentTerms: Record "Payment Terms";
    begin
        PaymentTerms.Get(GetPaymentTerms());
        exit(PaymentTerms."Discount %");
    end;

    local procedure GetDiscountAmount(Amount: Decimal): Decimal
    begin
        exit(Amount * GetDiscountPercent() / 100);
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

    [Normal]
    local procedure GetAmountFCY(CurrencyCode: Code[10]; Amount: Decimal): Decimal
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        if CurrencyCode = '' then
            exit(Amount);
        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        CurrencyExchangeRate.FindFirst();
        exit(Amount * CurrencyExchangeRate."Relational Exch. Rate Amount" / CurrencyExchangeRate."Exchange Rate Amount");
    end;

    local procedure UpdateVendorPostingGroup(PostingGroupCode: Code[20])
    var
        VendorPostingGroup: Record "Vendor Posting Group";
        GLAccount: Record "G/L Account";
    begin
        VendorPostingGroup.Get(PostingGroupCode);
        GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.SetRange(Blocked, false);
        GLAccount.FindSet();
        VendorPostingGroup.Validate("Payment Disc. Debit Acc.", GLAccount."No.");
        VendorPostingGroup.Validate("Payment Disc. Credit Acc.", GLAccount."No.");
        GLAccount.Next();
        VendorPostingGroup.Validate("Payment Tolerance Debit Acc.", GLAccount."No.");
        VendorPostingGroup.Validate("Payment Tolerance Credit Acc.", GLAccount."No.");
        VendorPostingGroup.Modify(true);
    end;

    [Normal]
    local procedure UpdateAndPostGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; AppliestoDocType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    begin
        GenJournalLine.Validate("Applies-to Doc. Type", AppliestoDocType);
        GenJournalLine.Validate("Applies-to Doc. No.", DocumentNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure UpdateMaxPaymentToleranceOnVendorLedgerEntry(VendorNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; MaxPmtTolAmounts: List of [Decimal])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        MaxPmtTolerance: Decimal;
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetRange("Document Type", DocumentType);
        VendorLedgerEntry.FindSet(true, false);
        foreach MaxPmtTolerance in MaxPmtTolAmounts do begin
            VendorLedgerEntry.Validate("Max. Payment Tolerance", MaxPmtTolerance);
            VendorLedgerEntry.Modify(true);
            VendorLedgerEntry.Next();
        end;
    end;

    [Normal]
    local procedure VerifyVendorLedgerEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; ToleranceDiscount: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        VendorLedgerEntry.SetRange("Document Type", DocumentType);
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry.FindFirst();
        Assert.AreNearlyEqual(
          ToleranceDiscount, VendorLedgerEntry."Original Pmt. Disc. Possible", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountError, VendorLedgerEntry.FieldCaption("Original Pmt. Disc. Possible"),
            ToleranceDiscount, VendorLedgerEntry.TableCaption()));
    end;

    [Normal]
    local procedure VerifyDetldVendorLedgerEntry(DocumentType: Enum "Gen. Journal Document Type"; EntryType: Enum "Detailed CV Ledger Entry Type"; DocumentNo: Code[20]; ToleranceDiscount: Decimal)
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        DetailedVendorLedgEntry.SetRange("Document Type", DocumentType);
        DetailedVendorLedgEntry.SetRange("Entry Type", EntryType);
        DetailedVendorLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedVendorLedgEntry.FindFirst();
        Assert.AreNearlyEqual(
          ToleranceDiscount, DetailedVendorLedgEntry."Amount (LCY)", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountError, DetailedVendorLedgEntry.FieldCaption("Amount (LCY)"),
            ToleranceDiscount, DetailedVendorLedgEntry.TableCaption()));
    end;

    local procedure VerifyPmtToleranceOnClosedVendorLedgerEntry(VendorNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; ExpectedPmtTolerances: List of [Decimal])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        ExpectedPmtTolAmt: Decimal;
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetRange("Document Type", DocumentType);
        VendorLedgerEntry.FindSet();
        foreach ExpectedPmtTolAmt in ExpectedPmtTolerances do begin
            VendorLedgerEntry.CalcFields("Remaining Amount");
            VendorLedgerEntry.TestField("Remaining Amount", 0);
            VendorLedgerEntry.TestField(Open, false);
            Assert.AreNearlyEqual(ExpectedPmtTolAmt, VendorLedgerEntry."Pmt. Tolerance (LCY)", LibraryERM.GetAmountRoundingPrecision(), '');
            VendorLedgerEntry.Next();
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PaymentTolerancePageHandler(var PaymentToleranceWarning: Page "Payment Tolerance Warning"; var Response: Action)
    begin
        // Set Integer Value 1 for option "Post Balance for Payment Discount" on Tolerance Warning page.
        PaymentToleranceWarning.InitializeOption(1);
        Response := ACTION::Yes;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PaymentDiscTolPageHandler(var PaymentDiscToleranceWarning: Page "Payment Disc Tolerance Warning"; var Response: Action)
    begin
        // Set Integer Value 1 for option "Post as Payment Disc. Tolerance" on Tolerance Warning page.
        PaymentDiscToleranceWarning.InitializeNewPostingAction(1);
        Response := ACTION::Yes;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyVendorEntriesPageHandler(var ApplyVendorEntries: Page "Apply Vendor Entries"; var Response: Action)
    begin
        Response := ACTION::LookupOK;
    end;
}

