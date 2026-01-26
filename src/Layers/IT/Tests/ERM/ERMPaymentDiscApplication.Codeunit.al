codeunit 134914 "ERM Payment Disc Application"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Adjust For Payment Discount] [Payment Discount] [Application]
        IsInitialized := false;
    end;

    var
        LibraryJournals: Codeunit "Library - Journals";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibraryPmtDiscSetup: Codeunit "Library - Pmt Disc Setup";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        UnappliedError: Label '%1 %2 field must be true after Unapply entries.';

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvDiscApplication()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GenJournalLine: Record "Gen. Journal Line";
        GeneralPostingSetup: Record "General Posting Setup";
        InvoiceAmount: Decimal;
        PurhInvHeaderNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Invoice Discount Amount in GL Entry after Posting Purchase Invoice and Apply Payment on Invoice

        // Setup: Modify General Ledger Setup, Purchase Payables Setup and Create and Post Purchase Invoice and General
        // Journal Line Also Calculate Invoice Amount and Amount to be Applied.
        Initialize();
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        LibraryPurchase.SetCalcInvDiscount(true);
        CreatePurchaseInvoice(PurchaseHeader, PurchaseLine);
        InvoiceAmount := PurchaseLine."Line Amount" * (1 + PurchaseLine."VAT %" / 100);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        PurhInvHeaderNo := FindPurchaseInvoiceHeader(PurchaseHeader."No.");
        CreateApplyAndPostGenJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, PurchaseHeader."Buy-from Vendor No.",
          InvoiceAmount - (InvoiceAmount * PurchaseHeader."Payment Discount %" / 100), PurhInvHeaderNo);

        // Exercise: UnApply Vendor Ledger Entry.
        UnapplyVendorLedgerEntry(GenJournalLine."Account No.", GenJournalLine."Document No.");

        // Verify: Verify GL Entry for Purchase Invoice Discount Amount and Detailed Ledger Entry for Unapplied Entries.
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        VerifyGLEntry(PurhInvHeaderNo, GeneralPostingSetup."Purch. Line Disc. Account", -PurchaseLine."Line Discount Amount");
        VerifyUnappliedDtldLedgEntry(GenJournalLine."Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvDiscApplication()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GenJournalLine: Record "Gen. Journal Line";
        GeneralPostingSetup: Record "General Posting Setup";
        InvoiceAmount: Decimal;
        SalesInvoiceHeaderNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Invoice Discount Amount in GL Entry after Posting Sales Invoice and Apply Payment on Invoice

        // Setup: Modify General Ledger Setup, Sales Receivables Setup and Create and Post Sales Invoice and
        // Calculate Invoice Amount and Amount to be Applied.
        Initialize();
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        LibrarySales.SetCalcInvDiscount(true);
        CreateSalesInvoice(SalesHeader, SalesLine);
        InvoiceAmount := SalesLine."Line Amount" * (1 + SalesLine."VAT %" / 100);
        SalesInvoiceHeaderNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise: Create and Post General Journal Line with Apply Posted Invoice.
        CreateApplyAndPostGenJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Customer, SalesHeader."Sell-to Customer No.",
          -InvoiceAmount - (InvoiceAmount * SalesHeader."Payment Discount %" / 100), SalesInvoiceHeaderNo);

        // Verify: Verify GL Entry for Purchase Invoice Discount Amount and Detailed Ledger Entry for Unapplied Entries.
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        VerifyGLEntry(SalesInvoiceHeaderNo, GeneralPostingSetup."Sales Line Disc. Account", SalesLine."Line Discount Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchUnapplyPmtToTwoInvoicesWithNormalAndRevChrgVATSetup()
    var
        VATPostingSetup: array[2] of Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        VendorNo: Code[20];
        InvoiceNo: array[2] of Code[20];
        PaymentNo: Code[20];
        DiscountAmount: array[2] of Decimal;
        InvoiceAmount: array[2] of Decimal;
        NormalVATAmountDiscount: Decimal;
        RevChrgVATAmountDiscount: Decimal;
    begin
        // [FEATURE] [Purchase] [Reverse Charge VAT]
        // [SCENARIO 220987] Unapply Payment to two Invoices application in case of "Normal" and "Reverse Charge" VAT setups
        Initialize();
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        VendorNo := LibraryPurchase.CreateVendorNo();

        // [GIVEN] "Normal VAT" posting setup with "Adjust for Payment Discount" = TRUE, "Purchase VAT Account" = "NORM_A", "VAT %" = 25
        CreateVATPostingSetupWithAdjForPmtDisc(VATPostingSetup[1], VATPostingSetup[1]."VAT Calculation Type"::"Normal VAT");
        // [GIVEN] "Reverse Charge VAT" posting setup with "Adjust for Payment Discount" = TRUE, "Purchase VAT Account" = "REV_A", "Reverse Chrg. VAT Acc." = "REV_B", "VAT %" = 25
        CreateVATPostingSetupWithAdjForPmtDisc(VATPostingSetup[2], VATPostingSetup[2]."VAT Calculation Type"::"Reverse Charge VAT");

        // [GIVEN] Posted purchase invoice with "Normal VAT", Amount = 10000 = 8000 (VAT Base) + 2000 (VAT Amount), payment terms "Discount %" = 2
        // [GIVEN] Posted purchase invoice with "Reverse Charge VAT", Amount = 2000 = 1600 (VAT Base) + 400 (VAT Amount), payment terms "Discount %" = 2
        CreatePostTwoInvoicesWithDiscount(VATPostingSetup, VendorNo, InvoiceNo, InvoiceAmount, DiscountAmount);
        NormalVATAmountDiscount := Round(DiscountAmount[1] * VATPostingSetup[1]."VAT %" / 100 / (1 + VATPostingSetup[1]."VAT %" / 100));
        RevChrgVATAmountDiscount := Round(DiscountAmount[2] * VATPostingSetup[2]."VAT %" / 100);

        // [GIVEN] Posted payment "P" with Amount = (10000 - 200) + (2000 - 40) = 11760
        PaymentNo :=
          CreatePostPmtJournalLine(
            WorkDate(), GenJournalLine."Account Type"::Vendor, VendorNo,
            InvoiceAmount[1] - DiscountAmount[1] + InvoiceAmount[2] - DiscountAmount[2]);

        // [GIVEN] Apply payment to both invoices
        ApplyVendorPmtToSevDocs(VendorNo, PaymentNo, InvoiceNo);

        // [GIVEN] Three payment discount VAT adjustment G/L Entries have been created:
        // [GIVEN] "Document No." = "P", "G/L Account No." = "NORM_A", "Amount" = -40
        // [GIVEN] "Document No." = "P", "G/L Account No." = "REV_A", "Amount" = -10
        // [GIVEN] "Document No." = "P", "G/L Account No." = "REV_B", "Amount" = 10
        VerifyGLEntry(PaymentNo, VATPostingSetup[1]."Purchase VAT Account", -NormalVATAmountDiscount);
        VerifyGLEntry(PaymentNo, VATPostingSetup[2]."Purchase VAT Account", -RevChrgVATAmountDiscount);
        VerifyGLEntry(PaymentNo, VATPostingSetup[2]."Reverse Chrg. VAT Acc.", RevChrgVATAmountDiscount);

        // [WHEN] Unapply
        UnapplyVendorLedgerEntry(VendorNo, PaymentNo);

        // [THEN] Three payment discount VAT adjustment G/L Entries have been created:
        // [THEN] "Document No." = "P", "G/L Account No." = "NORM_A", "Amount" = 40
        // [THEN] "Document No." = "P", "G/L Account No." = "REV_A", "Amount" = 10
        // [THEN] "Document No." = "P", "G/L Account No." = "REV_B", "Amount" = -10
        VerifyLastRegisterGLEntry(PaymentNo, VATPostingSetup[1]."Purchase VAT Account", NormalVATAmountDiscount);
        VerifyLastRegisterGLEntry(PaymentNo, VATPostingSetup[2]."Purchase VAT Account", RevChrgVATAmountDiscount);
        VerifyLastRegisterGLEntry(PaymentNo, VATPostingSetup[2]."Reverse Chrg. VAT Acc.", -RevChrgVATAmountDiscount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchUnapplyPmtToTwoInvoicesWithRevChrgAndNormalVATSetup()
    var
        VATPostingSetup: array[2] of Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        VendorNo: Code[20];
        InvoiceNo: array[2] of Code[20];
        PaymentNo: Code[20];
        DiscountAmount: array[2] of Decimal;
        InvoiceAmount: array[2] of Decimal;
        NormalVATAmountDiscount: Decimal;
        RevChrgVATAmountDiscount: Decimal;
    begin
        // [FEATURE] [Purchase] [Reverse Charge VAT]
        // [SCENARIO 220987] Unapply Payment to two Invoices application in case of "Reverse Charge" and "Normal" VAT setups
        Initialize();
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        VendorNo := LibraryPurchase.CreateVendorNo();

        // [GIVEN] "Reverse Charge VAT" posting setup with "Adjust for Payment Discount" = TRUE, "Purchase VAT Account" = "REV_A", "Reverse Chrg. VAT Acc." = "REV_B", "VAT %" = 25
        CreateVATPostingSetupWithAdjForPmtDisc(VATPostingSetup[1], VATPostingSetup[1]."VAT Calculation Type"::"Reverse Charge VAT");
        // [GIVEN] "Normal VAT" posting setup with "Adjust for Payment Discount" = TRUE, "Purchase VAT Account" = "NORM_A", "VAT %" = 25
        CreateVATPostingSetupWithAdjForPmtDisc(VATPostingSetup[2], VATPostingSetup[2]."VAT Calculation Type"::"Normal VAT");

        // [GIVEN] Posted purchase invoice with "Reverse Charge VAT", Amount = 2000 = 1600 (VAT Base) + 400 (VAT Amount), payment terms "Discount %" = 2
        // [GIVEN] Posted purchase invoice with "Normal VAT", Amount = 10000 = 8000 (VAT Base) + 2000 (VAT Amount), payment terms "Discount %" = 2
        CreatePostTwoInvoicesWithDiscount(VATPostingSetup, VendorNo, InvoiceNo, InvoiceAmount, DiscountAmount);
        RevChrgVATAmountDiscount := Round(DiscountAmount[1] * VATPostingSetup[1]."VAT %" / 100);
        NormalVATAmountDiscount := Round(DiscountAmount[2] * VATPostingSetup[2]."VAT %" / 100 / (1 + VATPostingSetup[2]."VAT %" / 100));

        // [GIVEN] Posted payment "P" with Amount = (2000 - 40) + (10000 - 200) = 11760
        PaymentNo :=
          CreatePostPmtJournalLine(
            WorkDate(), GenJournalLine."Account Type"::Vendor, VendorNo,
            InvoiceAmount[1] - DiscountAmount[1] + InvoiceAmount[2] - DiscountAmount[2]);

        // [GIVEN] Apply payment to both invoices
        ApplyVendorPmtToSevDocs(VendorNo, PaymentNo, InvoiceNo);

        // [GIVEN] Three payment discount VAT adjustment G/L Entries have been created:
        // [GIVEN] "Document No." = "P", "G/L Account No." = "REV_A", "Amount" = -10
        // [GIVEN] "Document No." = "P", "G/L Account No." = "REV_B", "Amount" = 10
        // [GIVEN] "Document No." = "P", "G/L Account No." = "NORM_A", "Amount" = -40
        VerifyGLEntry(PaymentNo, VATPostingSetup[1]."Reverse Chrg. VAT Acc.", RevChrgVATAmountDiscount);
        VerifyGLEntry(PaymentNo, VATPostingSetup[1]."Purchase VAT Account", -RevChrgVATAmountDiscount);
        VerifyGLEntry(PaymentNo, VATPostingSetup[2]."Purchase VAT Account", -NormalVATAmountDiscount);

        // [WHEN] Unapply
        UnapplyVendorLedgerEntry(VendorNo, PaymentNo);

        // [THEN] Three payment discount VAT adjustment G/L Entries have been created:
        // [THEN] "Document No." = "P", "G/L Account No." = "NORM_A", "Amount" = 40
        // [THEN] "Document No." = "P", "G/L Account No." = "REV_A", "Amount" = 10
        // [THEN] "Document No." = "P", "G/L Account No." = "REV_B", "Amount" = -10
        VerifyLastRegisterGLEntry(PaymentNo, VATPostingSetup[1]."Reverse Chrg. VAT Acc.", -RevChrgVATAmountDiscount);
        VerifyLastRegisterGLEntry(PaymentNo, VATPostingSetup[1]."Purchase VAT Account", RevChrgVATAmountDiscount);
        VerifyLastRegisterGLEntry(PaymentNo, VATPostingSetup[2]."Purchase VAT Account", NormalVATAmountDiscount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchUnapplyPmtToCrMemoAndInvWithSevLinesDiscAndTolerance()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VATPostingSetup: Record "VAT Posting Setup";
        PaymentTerms: Record "Payment Terms";
        GLAccount: Record "G/L Account";
        VendorNo: Code[20];
        GLAccountNo: Code[20];
        DocumentNo: array[2] of Code[20];
        PaymentNo: Code[20];
        CrMemoLineAmount: Decimal;
        InvLineAmount: Decimal;
        PmtAmount: Decimal;
        ApplTransactionNo: Integer;
        CrMemoLinesCount: Integer;
        InvLinesCount: Integer;
    begin
        // [FEATURE] [Purchase] [Payment Tolerance]
        // [SCENARIO 222804] Several VAT Entries have been created for Apply\Unapply vendor payment to credit memo and invoice with several lines
        // [SCENARIO 222804] in case of the same General\VAT Posting setup, payment discount and tolerance
        Initialize();

        // [GIVEN] "Adjust for Payment Disc." = TRUE, "Payment Discount Grace Period" = "5D"
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        LibraryPmtDiscSetup.SetPmtDiscGracePeriodByText('<5D>');

        // [GIVEN] Vendor with payment terms "1M(8D)"
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, true);
        CreateVATPostingSetupWithAdjForPmtDisc(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VendorNo := LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group");
        GLAccountNo := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase);
        UpdateGenPostingSetupForVendorAndGLAccount(VendorNo, GLAccountNo);

        // [GIVEN] Posted purchase credit memo on 04-01-2017 with Amount = 1250 (2 lines, each has Amount = 625)
        CrMemoLinesCount := LibraryRandom.RandIntInRange(2, 5);
        CrMemoLineAmount := LibraryRandom.RandDecInRange(1000, 2000, 2);
        DocumentNo[1] :=
          CreatePostDocWithSevLines(
            WorkDate() + 1, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Account Type"::Vendor,
            VendorNo, GLAccountNo, PaymentTerms.Code, CrMemoLinesCount, -CrMemoLineAmount);
        // [GIVEN] Posted purchase invoice on 01-01-2017 with Amount = 2500 (4 lines, each has Amount = 625)
        InvLinesCount := LibraryRandom.RandIntInRange(2, 5);
        InvLineAmount := Round(CrMemoLineAmount * CrMemoLinesCount / InvLinesCount) + LibraryRandom.RandDecInRange(1000, 2000, 2);
        DocumentNo[2] :=
          CreatePostDocWithSevLines(
            WorkDate(), GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor,
            VendorNo, GLAccountNo, PaymentTerms.Code, InvLinesCount, InvLineAmount);
        // [GIVEN] Posted payment on 10-01-2017 with Amount = 1250
        PmtAmount := InvLineAmount * InvLinesCount - CrMemoLineAmount * CrMemoLinesCount;
        PaymentNo :=
          CreatePostPmtJournalLine(
            LibraryPmtDiscSetup.GetPaymentTermsDiscountDate(PaymentTerms.Code) + 1,
            GenJournalLine."Account Type"::Vendor, VendorNo, PmtAmount);

        // [GIVEN] Apply payment to both documents
        ApplyVendorPmtToSevDocs(VendorNo, PaymentNo, DocumentNo);

        // [THEN] There are 6 VAT Entries have been created for application (2 Discount, 4 Tolerance)
        ApplTransactionNo := GetVendApplTransactionNo(VendorNo, PaymentNo);
        VerifyVATEntriesCountByTransactionNo(ApplTransactionNo, CrMemoLinesCount + InvLinesCount);

        // [WHEN] Unapply
        UnapplyVendorLedgerEntry(VendorNo, PaymentNo);

        // [THEN] There are 6 VAT Entries have been created for application (2 Discount, 4 Tolerance)
        VerifyVATEntriesCountByTransactionNo(ApplTransactionNo + 1, CrMemoLinesCount + InvLinesCount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesUnapplyPmtToCrMemoAndInvWithSevLinesDiscAndTolerance()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VATPostingSetup: Record "VAT Posting Setup";
        PaymentTerms: Record "Payment Terms";
        GLAccount: Record "G/L Account";
        CustomerNo: Code[20];
        GLAccountNo: Code[20];
        DocumentNo: array[2] of Code[20];
        PaymentNo: Code[20];
        CrMemoLineAmount: Decimal;
        InvLineAmount: Decimal;
        PmtAmount: Decimal;
        ApplTransactionNo: Integer;
        CrMemoLinesCount: Integer;
        InvLinesCount: Integer;
    begin
        // [FEATURE] [Sales] [Payment Tolerance]
        // [SCENARIO 222804] Several VAT Entries have been created for Apply\Unapply customer payment to credit memo and invoice with several lines
        // [SCENARIO 222804] in case of the same General\VAT Posting setup, payment discount and tolerance
        Initialize();

        // [GIVEN] "Adjust for Payment Disc." = TRUE, "Payment Discount Grace Period" = "5D"
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        LibraryPmtDiscSetup.SetPmtDiscGracePeriodByText('<5D>');

        // [GIVEN] Customer with payment terms "1M(8D)"
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, true);
        CreateVATPostingSetupWithAdjForPmtDisc(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CustomerNo := LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group");
        GLAccountNo := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale);
        UpdateGenPostingSetupForCustomerAndGLAccount(CustomerNo, GLAccountNo);

        // [GIVEN] Posted sales credit memo on 04-01-2017 with Amount = 1250 (2 lines, each has Amount = 625)
        CrMemoLinesCount := LibraryRandom.RandIntInRange(2, 5);
        CrMemoLineAmount := LibraryRandom.RandDecInRange(1000, 2000, 2);
        DocumentNo[1] :=
          CreatePostDocWithSevLines(
            WorkDate() + 1, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Account Type"::Customer,
            CustomerNo, GLAccountNo, PaymentTerms.Code, CrMemoLinesCount, CrMemoLineAmount);
        // [GIVEN] Posted sales invoice on 01-01-2017 with Amount = 2500 (4 lines, each has Amount = 625)
        InvLinesCount := LibraryRandom.RandIntInRange(2, 5);
        InvLineAmount := Round(CrMemoLineAmount * CrMemoLinesCount / InvLinesCount) + LibraryRandom.RandDecInRange(1000, 2000, 2);
        DocumentNo[2] :=
          CreatePostDocWithSevLines(
            WorkDate(), GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer,
            CustomerNo, GLAccountNo, PaymentTerms.Code, InvLinesCount, -InvLineAmount);
        // [GIVEN] Posted payment on 10-01-2017 with Amount = 1250
        PmtAmount := InvLineAmount * InvLinesCount - CrMemoLineAmount * CrMemoLinesCount;
        PaymentNo :=
          CreatePostPmtJournalLine(
            LibraryPmtDiscSetup.GetPaymentTermsDiscountDate(PaymentTerms.Code) + 1,
            GenJournalLine."Account Type"::Customer, CustomerNo, -PmtAmount);

        // [GIVEN] Apply payment to both documents
        ApplyCustomerPmtToSevDocs(CustomerNo, PaymentNo, DocumentNo);

        // [THEN] There are 6 VAT Entries have been created for application (2 Discount, 4 Tolerance)
        ApplTransactionNo := GetCustApplTransactionNo(CustomerNo, PaymentNo);
        VerifyVATEntriesCountByTransactionNo(ApplTransactionNo, CrMemoLinesCount + InvLinesCount);

        // [WHEN] Unapply
        UnapplyCustomerLedgerEntry(CustomerNo, PaymentNo);

        // [THEN] There are 6 VAT Entries have been created for application (2 Discount, 4 Tolerance)
        VerifyVATEntriesCountByTransactionNo(ApplTransactionNo + 1, CrMemoLinesCount + InvLinesCount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchUnapplyPmtToSevInvNormAndRevChrgVATAndTolDiscAndRounding()
    var
        NormalVATPostingSetup: array[3] of Record "VAT Posting Setup";
        RevChrgVATPostingSetup: Record "VAT Posting Setup";
        PaymentTerms: Record "Payment Terms";
        GenJournalLine: Record "Gen. Journal Line";
        GeneralPostingSetup: Record "General Posting Setup";
        VendorNo: Code[20];
        InvoiceNo: array[3] of Code[20];
        PaymentNo: Code[20];
        ApplTransactionNo: Integer;
    begin
        // [FEATURE] [Unapply] [Payment Tolerance] [Rounding] [Purchase]
        // [SCENARIO 271401] Several VAT entries have been created for Apply\Unapply vendor payment to several invoices
        // [SCENARIO 271401] with Normal and Reverse Charge VAT Setup, several document lines, Tolerance and Discount, custom amounts
        Initialize();

        // [GIVEN] G/L Setup: "Adjust for Payment Disc." = TRUE, "Payment Discount Grace Period" = "5D", "Payment Tolerance %" = 5, "Max. Payment Tolerance Amount" = 20
        SetPmtDiscToleranceInGenLedgSetup(5, 5, 20);
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        UpdateGeneralPostingSetup(GeneralPostingSetup."Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");

        // [GIVEN] Payment terms "1M(8D)" with "Discount %" = 2
        CreatePaymentTermsDiscount(PaymentTerms, 2);
        // [GIVEN] Three "Normal" VAT posting setup (25%, 10%, 0%) with "Adjust for Payment Discount" = TRUE
        // [GIVEN] One "Reverse Charge" 25% VAT posting setup with "Adjust for Payment Discount" = TRUE
        Create3NormalAnd1RevChrgVATPostingSetup(NormalVATPostingSetup, RevChrgVATPostingSetup, 25, 10, 0, 25);
        VendorNo := LibraryPurchase.CreateVendorNo();

        // [GIVEN] Posted purchase invoice on "Posting Date" = 01-06-2018 with 3 lines (Normal VAT 25%, 10%, 0%) with line's Direct Cost = 100
        // [GIVEN] Posted purchase invoice on "Posting Date" = 01-06-2018 with 3 lines (Normal VAT 25%, 10%, 0%) with line's Direct Cost = 100
        // [GIVEN] Posted purchase invoice on "Posting Date" = 01-06-2018 with 1 line (Reverse Charge VAT 25%) with line's Direct Cost = 100
        InvoiceNo[1] := CreatePostPurchaseInvoiceWithSevLines(NormalVATPostingSetup, VendorNo, PaymentTerms.Code, 100);
        InvoiceNo[2] := CreatePostPurchaseInvoiceWithSevLines(NormalVATPostingSetup, VendorNo, PaymentTerms.Code, 100);
        InvoiceNo[3] := CreatePostPurchaseInvoiceWithOneLine(RevChrgVATPostingSetup, VendorNo, PaymentTerms.Code, 100);
        // [GIVEN] Posted vendor payment on "Posting Date" = 10-06-2018 with Amount = 754
        PaymentNo :=
          CreatePostPmtJournalLine(
            LibraryPmtDiscSetup.GetPaymentTermsDiscountDate(PaymentTerms.Code) + 1,
            GenJournalLine."Account Type"::Vendor, VendorNo, 754);

        // [GIVEN] Apply post payment to three invoices, accept Tolerance and Discount warnings
        ApplyVendorPmtToSevDocs(VendorNo, PaymentNo, InvoiceNo);
        // [GIVEN] 14 VAT Entries have been created for Apply
        ApplTransactionNo := GetVendApplTransactionNo(VendorNo, PaymentNo);
        VerifyVATEntriesCountAndBalanceByTransactionNo(ApplTransactionNo, 16, -16.64, -1.44);

        // [WHEN] Unapply payment
        UnapplyVendorLedgerEntry(VendorNo, PaymentNo);

        // [THEN] 14 VAT Entries have been created for UnApply
        VerifyVATEntriesCountAndBalanceByTransactionNo(ApplTransactionNo + 1, 14, 14.56, 1.96);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesUnapplyPmtToSevInvNormAndRevChrgVATAndTolDiscAndRounding()
    var
        NormalVATPostingSetup: array[3] of Record "VAT Posting Setup";
        RevChrgVATPostingSetup: Record "VAT Posting Setup";
        PaymentTerms: Record "Payment Terms";
        GenJournalLine: Record "Gen. Journal Line";
        GeneralPostingSetup: Record "General Posting Setup";
        CustomerNo: Code[20];
        InvoiceNo: array[3] of Code[20];
        PaymentNo: Code[20];
        ApplTransactionNo: Integer;
    begin
        // [FEATURE] [Unapply] [Payment Tolerance] [Rounding] [Sales]
        // [SCENARIO 271401] Several VAT entries have been created for Apply\Unapply customer payment to several invoices
        // [SCENARIO 271401] with Normal and Reverse Charge VAT Setup, several document lines, Tolerance and Discount, custom amounts
        Initialize();

        // [GIVEN] G/L Setup: "Adjust for Payment Disc." = TRUE, "Payment Discount Grace Period" = "5D", "Payment Tolerance %" = 5, "Max. Payment Tolerance Amount" = 20
        SetPmtDiscToleranceInGenLedgSetup(5, 5, 20);
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        UpdateGeneralPostingSetup(GeneralPostingSetup."Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");

        // [GIVEN] Payment terms "1M(8D)" with "Discount %" = 2
        CreatePaymentTermsDiscount(PaymentTerms, 2);
        // [GIVEN] Three "Normal" VAT posting setup (25%, 10%, 0%) with "Adjust for Payment Discount" = TRUE
        // [GIVEN] One "Reverse Charge" 25% VAT posting setup with "Adjust for Payment Discount" = TRUE
        Create3NormalAnd1RevChrgVATPostingSetup(NormalVATPostingSetup, RevChrgVATPostingSetup, 25, 10, 0, 25);
        CustomerNo := LibrarySales.CreateCustomerWithVATBusPostingGroup(NormalVATPostingSetup[1]."VAT Bus. Posting Group");
        UpdateGenPostingSetupForCustomerAndGLAccount(
          CustomerNo, LibraryERM.CreateGLAccountWithVATPostingSetup(NormalVATPostingSetup[1], "General Posting Type"::" "));

        // [GIVEN] Posted sales invoice on "Posting Date" = 01-06-2018 with 3 lines (Normal VAT 25%, 10%, 0%) with line's Direct Cost = 100
        // [GIVEN] Posted sales invoice on "Posting Date" = 01-06-2018 with 3 lines (Normal VAT 25%, 10%, 0%) with line's Direct Cost = 100
        // [GIVEN] Posted sales invoice on "Posting Date" = 01-06-2018 with 1 line (Reverse Charge VAT 25%) with line's Direct Cost = 100
        InvoiceNo[1] := CreatePostSalesInvoiceWithSevLines(NormalVATPostingSetup, CustomerNo, PaymentTerms.Code, 100);
        InvoiceNo[2] := CreatePostSalesInvoiceWithSevLines(NormalVATPostingSetup, CustomerNo, PaymentTerms.Code, 100);
        InvoiceNo[3] := CreatePostSalesInvoiceWithOneLine(RevChrgVATPostingSetup, CustomerNo, PaymentTerms.Code, 100);
        // [GIVEN] Posted customer payment on "Posting Date" = 10-06-2018 with Amount = 754
        PaymentNo :=
          CreatePostPmtJournalLine(
            LibraryPmtDiscSetup.GetPaymentTermsDiscountDate(PaymentTerms.Code) + 1,
            GenJournalLine."Account Type"::Customer, CustomerNo, -754);

        // [GIVEN] Apply post payment to three invoices, accept Tolerance and Discount warnings
        ApplyCustomerPmtToSevDocs(CustomerNo, PaymentNo, InvoiceNo);
        // [GIVEN] 14 VAT Entries have been created for Apply
        ApplTransactionNo := GetCustApplTransactionNo(CustomerNo, PaymentNo);
        VerifyVATEntriesCountAndBalanceByTransactionNo(ApplTransactionNo, 14, 14.56, 1.44);

        // [WHEN] Unapply payment
        UnapplyCustomerLedgerEntry(CustomerNo, PaymentNo);

        // [THEN] 14 VAT Entries have been created for UnApply
        VerifyVATEntriesCountAndBalanceByTransactionNo(ApplTransactionNo + 1, 14, -14.56, -1.44);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentDiscountVATEntryDocumentDate()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        VATPostingSetup: Record "VAT Posting Setup";
        VATEntry: Record "VAT Entry";
        GLAccount: Record "G/L Account";
        PaymentTerms: Record "Payment Terms";
        GenJournalLine: Record "Gen. Journal Line";
        GeneralPostingSetup: Record "General Posting Setup";
        CustomerNo: Code[20];
        InvoiceNo: Code[20];
        PaymentTermsDiscount: Decimal;
        Amount: Decimal;
    begin
        // [FEATURE] [VAT Entry] [Document Date]
        // [SCENARIO 293503] "Document Date" of VAT Entry created from a payment with Payment Discount corresponds to "Document Date" of the Payment
        Initialize();

        // [GIVEN] G/L Setup: "Adjust for Payment Disc." = TRUE
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        UpdateGeneralPostingSetup(GeneralPostingSetup."Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");

        // [GIVEN] Payment terms "1M(8D)" with "Discount %" = 2
        PaymentTermsDiscount := LibraryRandom.RandDec(10, 0);
        CreatePaymentTermsDiscount(PaymentTerms, PaymentTermsDiscount);

        // [GIVEN] VAT posting setup 10% with "Adjust for Payment Discount" = TRUE
        CreateVATPostingSetupWithGivenPct(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandDec(10, 0));
        CustomerNo := LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group");
        UpdateGenPostingSetupForCustomerAndGLAccount(
          CustomerNo, LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, "General Posting Type"::" "));

        // [GIVEN] Posted sales invoice on "Posting Date" =25-11-2018  with Amount = -1000 and Payment Terms "1M(8D)"
        Amount := LibraryRandom.RandDec(1000, 2);
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        LibraryJournals.CreateGenJournalLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale),
          GenJournalLine."Bal. Account Type"::Customer, CustomerNo, -Amount);
        GenJournalLine.Validate("Payment Terms Code", PaymentTerms.Code);
        GenJournalLine.Modify(true);
        InvoiceNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Customer payment with "Posting Date" = 02-12-2018 with Amount = -980 applied to invoice
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, CustomerNo, -Amount * (100 - PaymentTermsDiscount) / 100);
        GenJournalLine.Validate("Posting Date", LibraryPmtDiscSetup.GetPaymentTermsDiscountDate(PaymentTerms.Code));
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Document Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", InvoiceNo);
        GenJournalLine.Modify(true);

        // [WHEN] Post the payment
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Created VAT Entry for the payment has "Document Date" = 02-12-2018
        VATEntry.SetRange("Document No.", GenJournalLine."Document No.");
        VATEntry.FindFirst();
        VATEntry.TestField("Document Date", GenJournalLine."Document Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentDiscountOfOneCentForCrMemoAndInvoiceAppliedToPayment()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PaymentTerms: Record "Payment Terms";
        GenJournalLine: Record "Gen. Journal Line";
        GeneralPostingSetup: Record "General Posting Setup";
        Customer: Record "Customer";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        InvoiceCustLedgerEntry, CrMemoCustLedgerEntry, PmtCustLedgerEntry : Record "Cust. Ledger Entry";
        DetailedCustLedgerEntry: Record "Detailed Cust. Ledg. Entry";
        InvoiceNo, CrMemoNo : Code[20];
        PaymentTermsDiscount: Decimal;
        Amount: Decimal;
    begin
        // [FEATURE] [Payment Discount] [Credit Memo] [Invoice] [Payment]
        // [SCENARIO 569281] Apply payment to invoice and credit memo with same amounts on last payment discount date when credit memo has Rem. Pmt. Disc. Possible = -0.01
        Initialize();

        // [GIVEN] G/L Setup: "Adjust for Payment Disc." = TRUE
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        UpdateGeneralPostingSetup(GeneralPostingSetup."Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");

        // [GIVEN] Payment terms with "Due Date Calculation" = 5D, "Discount Date Calculation" = 10D, "Discount %" = 0
        PaymentTermsDiscount := LibraryRandom.RandDec(10, 0);
        CreatePaymentTermsDiscount(PaymentTerms, 0);
        Evaluate(PaymentTerms."Due Date Calculation", '<' + Format(LibraryRandom.RandInt(5)) + 'D>');
        Evaluate(PaymentTerms."Discount Date Calculation", '<' + Format(LibraryRandom.RandIntInRange(6, 10)) + 'D>');
        PaymentTerms.Modify();

        // [GIVEN] VAT posting setup 19%
        CreateVATPostingSetupWithGivenPct(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandIntInRange(11, 19));
        Customer.Get(LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        Customer.Validate("Payment Terms Code", PaymentTerms.Code);
        Customer.Modify(true);
        UpdateGenPostingSetupForCustomerAndGLAccount(
          Customer."No.", LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, "General Posting Type"::" "));

        // [GIVEN] Posted sales invoice on "Posting Date" = 01 Jan with Amount = 1000
        Amount := LibraryRandom.RandIntInRange(1000, 1999);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GenJournalLine."Gen. Posting Type"::" "), 1);
        SalesLine.Validate("Unit Price", Amount);
        SalesLine.Modify(true);
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        LibraryERM.FindCustomerLedgerEntry(InvoiceCustLedgerEntry, InvoiceCustLedgerEntry."Document Type"::Invoice, InvoiceNo);

        // [GIVEN] Posted sales credit memo on "Posting Date" = 01 Jan with Amount = 1000
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.");
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
          SalesLine."No.", 1);
        SalesLine.Validate("Unit Price", Amount);
        SalesLine.Modify(true);
        CrMemoNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        LibraryERM.FindCustomerLedgerEntry(CrMemoCustLedgerEntry, CrMemoCustLedgerEntry."Document Type"::"Credit Memo", CrMemoNo);

        // [GIVEN] Customer payment with "Posting Date" = 11 Jan (01 Jan + 10D of "Discount Date Calculation") with Amount = -0.01
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, Customer."No.", -0.01);
        GenJournalLine.Validate("Posting Date", CalcDate(PaymentTerms."Discount Date Calculation", WorkDate()));
        GenJournalLine.Validate("Applies-to ID", GenJournalLine."Document No.");
        GenJournalLine.Modify(true);
        // [GIVEN] Set apply payment to full amount of the invoice 
        InvoiceCustLedgerEntry.CalcFields("Remaining Amount");
        InvoiceCustLedgerEntry.Validate("Applies-to ID", GenJournalLine."Document No.");
        InvoiceCustLedgerEntry.Validate("Amount to Apply", InvoiceCustLedgerEntry."Remaining Amount");
        InvoiceCustLedgerEntry.Modify();
        // [GIVEN] Set apply payment to full amount of credit memo with Rem. Pmt. Disc. Possible = -0.01
        CrMemoCustLedgerEntry.CalcFields("Remaining Amount");
        CrMemoCustLedgerEntry.Validate("Applies-to ID", GenJournalLine."Document No.");
        CrMemoCustLedgerEntry.Validate("Amount to Apply", CrMemoCustLedgerEntry."Remaining Amount");
        CrMemoCustLedgerEntry.Validate(CrMemoCustLedgerEntry."Remaining Pmt. Disc. Possible", -0.01);
        CrMemoCustLedgerEntry.Modify();

        // [WHEN] Post the payment
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryERM.FindCustomerLedgerEntry(PmtCustLedgerEntry, PmtCustLedgerEntry."Document Type"::Payment, GenJournalLine."Document No.");
        PmtCustLedgerEntry.CalcFields("Remaining Amount");

        // [THEN] Both customer ledger entries for invoice and credit memo have been closed
        InvoiceCustLedgerEntry.Find();
        InvoiceCustLedgerEntry.TestField(Open, false);
        CrMemoCustLedgerEntry.Find();
        CrMemoCustLedgerEntry.TestField(Open, false);
        // [THEN] The payment is closed, payment discount of one cent has been applied to the payment        
        PmtCustLedgerEntry.TestField(Open, false);
        DetailedCustLedgerEntry.SetRange("Cust. Ledger Entry No.", PmtCustLedgerEntry."Entry No.");
        DetailedCustLedgerEntry.SetRange("Entry Type", DetailedCustLedgerEntry."Entry Type"::"Payment Discount");
        DetailedCustLedgerEntry.FindFirst();
        DetailedCustLedgerEntry.TestField(Amount, 0.01);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Payment Disc Application");
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Payment Disc Application");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateAccountInCustomerPostingGroup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        IsInitialized := true;
        Commit();
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Payment Disc Application");
    end;

    local procedure Create3NormalAnd1RevChrgVATPostingSetup(var NormalVATPostingSetup: array[3] of Record "VAT Posting Setup"; var RevChrgVATPostingSetup: Record "VAT Posting Setup"; NormalVATRate1: Decimal; NormalVATRate2: Decimal; NormalVATRate3: Decimal; RevChrgVATRate: Decimal)
    begin
        CreateVATPostingSetupWithGivenPct(
          NormalVATPostingSetup[1], NormalVATPostingSetup[1]."VAT Calculation Type"::"Normal VAT", NormalVATRate1);
        CreateDuplicatedVATPostingSetup(NormalVATPostingSetup[2], NormalVATPostingSetup[1], NormalVATRate2);
        CreateDuplicatedVATPostingSetup(NormalVATPostingSetup[3], NormalVATPostingSetup[1], NormalVATRate3);
        CreateVATPostingSetupWithGivenPct(
          RevChrgVATPostingSetup, RevChrgVATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", RevChrgVATRate);
    end;

    local procedure CreateVATPostingSetupWithGivenPct(var VATPostingSetup: Record "VAT Posting Setup"; VATCalculationType: Enum "Tax Calculation Type"; VATRate: Decimal)
    begin
        CreateVATPostingSetupWithAdjForPmtDisc(VATPostingSetup, VATCalculationType);
        VATPostingSetup.Validate("VAT %", VATRate);
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateDuplicatedVATPostingSetup(var NewVATPostingSetup: Record "VAT Posting Setup"; VATPostingSetup: Record "VAT Posting Setup"; VATRate: Decimal)
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        NewVATPostingSetup := VATPostingSetup;
        NewVATPostingSetup.Validate("VAT Prod. Posting Group", VATProductPostingGroup.Code);
        NewVATPostingSetup."VAT Identifier" := VATProductPostingGroup.Code;
        NewVATPostingSetup.Validate("VAT %", VATRate);
        NewVATPostingSetup.Insert();
    end;

    local procedure CreatePaymentTermsDiscount(var PaymentTerms: Record "Payment Terms"; DiscountPct: Decimal)
    var
        PaymentLines: Record "Payment Lines";
    begin
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, true);
        LibraryERM.FindPaymentLines(PaymentLines, PaymentTerms.Code);
        PaymentLines.Validate("Discount %", DiscountPct);
        PaymentLines.Modify(true);
    end;

    local procedure CreatePostPurchaseInvoiceWithSevLines(VATPostingSetup: array[3] of Record "VAT Posting Setup"; VendorNo: Code[20]; PaymentTermsCode: Code[10]; DirectUnitCost: Decimal): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        i: Integer;
    begin
        CreatePurchaseHeader(PurchaseHeader, VendorNo, VATPostingSetup[1]."VAT Bus. Posting Group", PaymentTermsCode);

        for i := 1 to ArrayLen(VATPostingSetup) do
            CreateCustomPurchaseLine(PurchaseHeader, VATPostingSetup[i], DirectUnitCost);

        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreatePostPurchaseInvoiceWithOneLine(VATPostingSetup: Record "VAT Posting Setup"; VendorNo: Code[20]; PaymentTermsCode: Code[10]; DirectUnitCost: Decimal): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseHeader(PurchaseHeader, VendorNo, VATPostingSetup."VAT Bus. Posting Group", PaymentTermsCode);

        CreateCustomPurchaseLine(PurchaseHeader, VATPostingSetup, DirectUnitCost);

        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreatePostSalesInvoiceWithSevLines(VATPostingSetup: array[3] of Record "VAT Posting Setup"; CustomerNo: Code[20]; PaymentTermsCode: Code[10]; DirectUnitCost: Decimal): Code[20]
    var
        SalesHeader: Record "Sales Header";
        i: Integer;
    begin
        CreateSalesHeader(SalesHeader, CustomerNo, VATPostingSetup[1]."VAT Bus. Posting Group", PaymentTermsCode);

        for i := 1 to ArrayLen(VATPostingSetup) do
            CreateCustomSalesLine(SalesHeader, VATPostingSetup[i], DirectUnitCost);

        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreatePostSalesInvoiceWithOneLine(VATPostingSetup: Record "VAT Posting Setup"; CustomerNo: Code[20]; PaymentTermsCode: Code[10]; DirectUnitCost: Decimal): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesHeader(SalesHeader, CustomerNo, VATPostingSetup."VAT Bus. Posting Group", PaymentTermsCode);

        CreateCustomSalesLine(SalesHeader, VATPostingSetup, DirectUnitCost);

        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreatePostTwoInvoicesWithDiscount(VATPostingSetup: array[2] of Record "VAT Posting Setup"; VendorNo: Code[20]; var InvoiceNo: array[2] of Code[20]; var InvoiceAmount: array[2] of Decimal; var DiscountAmount: array[2] of Decimal)
    var
        PaymentTerms: Record "Payment Terms";
        GenJournalLine: Record "Gen. Journal Line";
        i: Integer;
    begin
        for i := 1 to ArrayLen(VATPostingSetup) do begin
            LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, false);
            CreatePostPurchaseInvoice(GenJournalLine, VATPostingSetup[i], VendorNo, PaymentTerms.Code);
            InvoiceNo[i] := GenJournalLine."Document No.";
            InvoiceAmount[i] := GenJournalLine.Amount;
            DiscountAmount[i] := Round(InvoiceAmount[i] * LibraryPmtDiscSetup.GetPaymentTermsDiscountPct(PaymentTerms.Code) / 100);
        end;
    end;

    local procedure CreateApplyAndPostGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; LineAmount: Decimal; AppliestoDocNo: Code[20])
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(GenJournalLine, GenJournalLine."Document Type"::Payment, AccountType, AccountNo, LineAmount);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliestoDocNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreatePostPmtJournalLine(PostingDate: Date; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; LineAmount: Decimal): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(GenJournalLine, GenJournalLine."Document Type"::Payment, AccountType, AccountNo, LineAmount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Find GL Account and Modify VAT Posting Setup.
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Adjust for Payment Discount", true);
        VATPostingSetup.Modify(true);

        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify(true);
        CreateInvDiscForCustomer(Customer."No.");
        exit(Customer."No.");
    end;

    local procedure CreateInvDiscForCustomer(CustomerNo: Code[20])
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
    begin
        // Using Random values for calculation and value is not important for Test Case.
        LibraryERM.CreateInvDiscForCustomer(CustInvoiceDisc, CustomerNo, '', 0);
        CustInvoiceDisc.Validate("Discount %", LibraryRandom.RandDec(10, 2));
        CustInvoiceDisc.Modify(true);
    end;

    local procedure CreateInvDiscForVendor(VendorNo: Code[20])
    var
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
    begin
        // Using Random values for calculation and value is not important for Test Case.
        LibraryERM.CreateInvDiscForVendor(VendorInvoiceDisc, VendorNo, '', 0);
        VendorInvoiceDisc.Validate("Discount %", LibraryRandom.RandDec(10, 2));
        VendorInvoiceDisc.Modify(true);
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; VATBusPostingGroupCode: Code[20]; PaymentTermsCode: Code[10])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        PurchaseHeader.Validate("VAT Bus. Posting Group", VATBusPostingGroupCode);
        PurchaseHeader.Validate("Payment Terms Code", PaymentTermsCode);
        PurchaseHeader.Validate("Tax Area Code", '');
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchaseInvoice(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
        // Using Random values for calculation and value is not important for Test Case.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateVendor());
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Payment Discount %", LibraryRandom.RandInt(5));

        // Posting Date is always Less than Payment Discount Date.
        PurchaseHeader.Validate(
          "Pmt. Discount Date", CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', PurchaseHeader."Posting Date"));
        PurchaseHeader.Modify(true);
        CreatePurchaseLine(PurchaseHeader, PurchaseLine);
    end;

    local procedure CreatePurchaseLine(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        PurchCalcDiscount: Codeunit "Purch.-Calc.Discount";
        GLAccountCode: Code[20];
    begin
        // Find GL Account and Using Random values for calculation and value is not important for Test Case.
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        GLAccountCode := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccountCode,
          LibraryRandom.RandInt(5));
        UpdateGeneralPostingSetup(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        PurchaseLine.Validate("Direct Unit Cost", 300 * LibraryRandom.RandDec(10, 2));
        PurchaseLine.Validate("Line Discount %", LibraryRandom.RandInt(15));
        PurchaseLine.Validate("Allow Invoice Disc.", true);
        PurchaseLine.Modify(true);
        PurchCalcDiscount.CalculateInvoiceDiscount(PurchaseHeader, PurchaseLine);
    end;

    local procedure CreateCustomPurchaseLine(PurchaseHeader: Record "Purchase Header"; VATPostingSetup: Record "VAT Posting Setup"; DirectUnitCost: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, "General Posting Type"::" "), 1);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; VATBusPostingGroupCode: Code[20]; PaymentTermsCode: Code[10])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesHeader.Validate("VAT Bus. Posting Group", VATBusPostingGroupCode);
        SalesHeader.Validate("Payment Terms Code", PaymentTermsCode);
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesInvoice(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        // Using Random values for calculation and value is not important for Test Case.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer());
        SalesHeader.Validate("Payment Discount %", LibraryRandom.RandInt(5));

        // Posting Date is always Less than Payment Discount Date.
        SalesHeader.Validate(
          "Pmt. Discount Date", CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', SalesHeader."Posting Date"));
        SalesHeader.Modify(true);
        CreateSalesLine(SalesHeader, SalesLine);
    end;

    local procedure CreateSalesLine(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        SalesCalcDiscount: Codeunit "Sales-Calc. Discount";
        GLAccountCode: Code[20];
    begin
        // Find GL Account and Using Random values for calculation and value is not important for Test Case.
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        GLAccountCode := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccountCode,
          LibraryRandom.RandInt(10));
        UpdateGeneralPostingSetup(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        SalesLine.Validate("Unit Price", 300 * LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Line Discount %", LibraryRandom.RandInt(15));
        SalesLine.Validate("Allow Invoice Disc.", true);
        SalesLine.Modify(true);
        SalesCalcDiscount.CalculateWithSalesHeader(SalesHeader, SalesLine);
    end;

    local procedure CreateCustomSalesLine(SalesHeader: Record "Sales Header"; VATPostingSetup: Record "VAT Posting Setup"; UnitPrice: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, "General Posting Type"::" "), 1);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        VATPostingSetup.Validate("Adjust for Payment Discount", true);
        VATPostingSetup.Modify(true);

        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Modify(true);
        CreateInvDiscForVendor(Vendor."No.");
        exit(Vendor."No.");
    end;

    local procedure CreateVATPostingSetupWithAdjForPmtDisc(var VATPostingSetup: Record "VAT Posting Setup"; VATCalculationType: Enum "Tax Calculation Type")
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATCalculationType, LibraryRandom.RandIntInRange(10, 20));
        VATPostingSetup.Validate("Adjust for Payment Discount", true);
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);
    end;

    local procedure CreatePostPurchaseInvoice(var GenJournalLine: Record "Gen. Journal Line"; VATPostingSetup: Record "VAT Posting Setup"; VendorNo: Code[20]; PaymentTermsCode: Code[10])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
    begin
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        LibraryJournals.CreateGenJournalLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::"G/L Account",
        LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase),
            GenJournalLine."Bal. Account Type"::Vendor, VendorNo, LibraryRandom.RandDecInRange(1000, 2000, 2));
        GenJournalLine.Validate("Payment Terms Code", PaymentTermsCode);
        GenJournalLine.Modify(true);
        UpdateGeneralPostingSetup(GenJournalLine."Gen. Bus. Posting Group", GenJournalLine."Gen. Prod. Posting Group");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreatePostDocWithSevLines(PostingDate: Date; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; GLAccountNo: Code[20]; PaymentTermsCode: Code[10]; LinesCount: Integer; LineAmount: Decimal) DocumentNo: Code[20]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        TotalAmount: Decimal;
        i: Integer;
    begin
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        DocumentNo := LibraryUtility.GenerateGUID();
        for i := 1 to LinesCount do begin
            LibraryJournals.CreateGenJournalLine(
              GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
              DocumentType, GenJournalLine."Account Type"::"G/L Account", GLAccountNo, "Gen. Journal Account Type"::"G/L Account", '', LineAmount);
            GenJournalLine.Validate("Posting Date", PostingDate);
            GenJournalLine.Validate("Document No.", DocumentNo);
            GenJournalLine.Modify(true);
            TotalAmount += GenJournalLine.Amount;
        end;
        LibraryJournals.CreateGenJournalLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          DocumentType, AccountType, AccountNo, "Gen. Journal Account Type"::"G/L Account", '', -TotalAmount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Document No.", DocumentNo);
        GenJournalLine.Validate("Payment Terms Code", PaymentTermsCode);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure GetVendApplTransactionNo(VendorNo: Code[20]; PaymentNo: Code[20]): Integer
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DetailedVendorLedgEntry.SetRange("Vendor No.", VendorNo);
        DetailedVendorLedgEntry.SetRange("Document No.", PaymentNo);
        DetailedVendorLedgEntry.SetRange("Entry Type", DetailedVendorLedgEntry."Entry Type"::Application);
        DetailedVendorLedgEntry.FindFirst();
        exit(DetailedVendorLedgEntry."Transaction No.");
    end;

    local procedure GetCustApplTransactionNo(CustomerNo: Code[20]; PaymentNo: Code[20]): Integer
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.SetRange("Customer No.", CustomerNo);
        DetailedCustLedgEntry.SetRange("Document No.", PaymentNo);
        DetailedCustLedgEntry.SetRange("Entry Type", DetailedCustLedgEntry."Entry Type"::Application);
        DetailedCustLedgEntry.FindFirst();
        exit(DetailedCustLedgEntry."Transaction No.");
    end;

    local procedure FindPurchaseInvoiceHeader(PreAssignedNo: Code[20]): Code[20]
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.SetRange("Pre-Assigned No.", PreAssignedNo);
        PurchInvHeader.FindFirst();
        exit(PurchInvHeader."No.")
    end;

    local procedure ApplyVendorPmtToSevDocs(VendorNo: Code[20]; PaymentNo: Code[20]; DocumentNo: array[3] of Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
        i: Integer;
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Payment, PaymentNo);
        VendorLedgerEntry.CalcFields("Remaining Amount");
        LibraryERM.SetApplyVendorEntry(VendorLedgerEntry, VendorLedgerEntry."Remaining Amount");
        VendorLedgerEntry2.SetRange("Vendor No.", VendorNo);
        for i := 1 to ArrayLen(DocumentNo) do begin
            VendorLedgerEntry2.SetRange("Document No.", DocumentNo[i]);
            LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry2);
        end;
        LibraryERM.PostVendLedgerApplication(VendorLedgerEntry);
    end;

    local procedure ApplyCustomerPmtToSevDocs(CustomerNo: Code[20]; PaymentNo: Code[20]; DocNo: array[3] of Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        i: Integer;
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, PaymentNo);
        CustLedgerEntry.CalcFields("Remaining Amount");
        LibraryERM.SetApplyCustomerEntry(CustLedgerEntry, CustLedgerEntry."Remaining Amount");
        CustLedgerEntry2.SetRange("Customer No.", CustomerNo);
        for i := 1 to ArrayLen(DocNo) do begin
            CustLedgerEntry2.SetRange("Document No.", DocNo[i]);
            LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry2);
        end;
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry);
    end;

    local procedure UnapplyVendorLedgerEntry(VendorNo: Code[20]; DocumentNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Payment);
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry.FindFirst();
        LibraryERM.UnapplyVendorLedgerEntry(VendorLedgerEntry);
    end;

    local procedure UnapplyCustomerLedgerEntry(CustomerNo: Code[20]; DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Payment);
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.FindFirst();
        LibraryERM.UnapplyCustomerLedgerEntry(CustLedgerEntry);
    end;

    local procedure UpdateGeneralPostingSetup(GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        // Requirement of Test case we need to create and find different GL Accounts.
        GeneralPostingSetup.Get(GenBusPostingGroup, GenProdPostingGroup);
        GeneralPostingSetup.Validate("Sales Line Disc. Account", LibraryERM.CreateGLAccountNo());
        GeneralPostingSetup.Validate("Purch. Line Disc. Account", LibraryERM.CreateGLAccountNo());
        LibraryERM.SetGeneralPostingSetupPurchPmtDiscAccounts(GeneralPostingSetup);
        LibraryERM.SetGeneralPostingSetupSalesPmtDiscAccounts(GeneralPostingSetup);
        GeneralPostingSetup.Modify(true);
    end;

    local procedure UpdateGenPostingSetupForVendorAndGLAccount(VendorNo: Code[20]; GLAccountNo: Code[20])
    var
        Vendor: Record Vendor;
        GLAccount: Record "G/L Account";
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        Vendor.Get(VendorNo);
        GLAccount.Get(GLAccountNo);
        UpdateGeneralPostingSetup(Vendor."Gen. Bus. Posting Group", GLAccount."Gen. Prod. Posting Group");

        VendorPostingGroup.Get(Vendor."Vendor Posting Group");
        VendorPostingGroup.Validate("Invoice Rounding Account", GLAccountNo);
        VendorPostingGroup.Modify(true);
    end;

    local procedure UpdateGenPostingSetupForCustomerAndGLAccount(CustomerNo: Code[20]; GLAccountNo: Code[20])
    var
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        Customer.Get(CustomerNo);
        GLAccount.Get(GLAccountNo);
        UpdateGeneralPostingSetup(Customer."Gen. Bus. Posting Group", GLAccount."Gen. Prod. Posting Group");

        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        CustomerPostingGroup.Validate("Invoice Rounding Account", GLAccountNo);
        CustomerPostingGroup.Modify(true);
    end;

    local procedure SetPmtDiscToleranceInGenLedgSetup(PmtDiscGracePeriod: Integer; PaymentTolerancePct: Decimal; MaxPaymentToleranceAmount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        LibraryPmtDiscSetup.SetPmtDiscGracePeriodByText(StrSubstNo('<%1D>', PmtDiscGracePeriod));
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Adjust for Payment Disc.", true);
        GeneralLedgerSetup.Validate("Pmt. Disc. Tolerance Warning", false);
        GeneralLedgerSetup.Validate("Pmt. Disc. Tolerance Posting", GeneralLedgerSetup."Pmt. Disc. Tolerance Posting"::"Payment Discount Accounts");
        GeneralLedgerSetup.Validate("Payment Tolerance Warning", false);
        GeneralLedgerSetup.Validate("Payment Tolerance Posting", GeneralLedgerSetup."Payment Tolerance Posting"::"Payment Tolerance Accounts");
        GeneralLedgerSetup.Validate("Payment Tolerance %", PaymentTolerancePct);
        GeneralLedgerSetup.Validate("Max. Payment Tolerance Amount", MaxPaymentToleranceAmount);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; GLAccountNo: Code[20]; ExpectedAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, ExpectedAmount);
    end;

    local procedure VerifyLastRegisterGLEntry(DocumentNo: Code[20]; GLAccountNo: Code[20]; ExpectedAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
        GLRegister: Record "G/L Register";
    begin
        GLRegister.FindLast();
        GLEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, ExpectedAmount);
    end;

    local procedure VerifyUnappliedDtldLedgEntry(DocumentNo: Code[20])
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DetailedVendorLedgEntry.SetRange("Entry Type", DetailedVendorLedgEntry."Entry Type"::Application);
        DetailedVendorLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedVendorLedgEntry.FindSet();
        repeat
            Assert.IsTrue(
              DetailedVendorLedgEntry.Unapplied, StrSubstNo(UnappliedError, DetailedVendorLedgEntry.TableCaption(),
                DetailedVendorLedgEntry.Unapplied));
        until DetailedVendorLedgEntry.Next() = 0;
    end;

    local procedure VerifyVATEntriesCountByTransactionNo(TransactionNo: Integer; ExpectedCount: Integer)
    var
        DummyVATEntry: Record "VAT Entry";
    begin
        DummyVATEntry.Init();
        DummyVATEntry.SetRange("Transaction No.", TransactionNo);
        Assert.RecordCount(DummyVATEntry, ExpectedCount);
    end;

    local procedure VerifyVATEntriesCountAndBalanceByTransactionNo(TransactionNo: Integer; ExpectedCount: Integer; ExpectedBase: Decimal; ExpectedAmount: Decimal)
    var
        DummyVATEntry: Record "VAT Entry";
    begin
        DummyVATEntry.SetRange("Transaction No.", TransactionNo);
        Assert.RecordCount(DummyVATEntry, ExpectedCount);

        DummyVATEntry.CalcSums(Base, Amount);
        DummyVATEntry.TestField(Base, ExpectedBase);
        DummyVATEntry.TestField(Amount, ExpectedAmount);
    end;
}

