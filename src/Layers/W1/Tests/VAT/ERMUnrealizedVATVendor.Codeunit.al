codeunit 134026 "ERM Unrealized VAT Vendor"
{
    Permissions = TableData "Vendor Ledger Entry" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Unrealized VAT] [Purchase]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        isInitialized: Boolean;
        CrMemoCorrInvNoQst: Label 'The Credit Memo doesn''t have a Corrected Invoice No. Do you want to continue?';

    [Test]
    [Scope('OnPrem')]
    procedure TestUnrealizedVATEntry()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        // Test Unrealized VAT option to Percentage.

        // Setup: Setup Demonstration Data, Update Unrealized VAT Setup, Create and Post Purchase Invoice.
        EnableUnrealizedSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::Percentage);

        CreatePurchaseInvoice(PurchaseHeader, VATPostingSetup);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Execution: Make a Payment entry from General Journal Line, Apply Payment on Invoice from Vendor Ledger Entries.
        FindPurchaseInvoiceLine(PurchInvLine, PurchaseHeader."No.");
        // Payment Amount can be anything between 1 and 99% of the full Amount.
        CreateAndPostGeneralJournaLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment, PurchaseHeader."Buy-from Vendor No.",
          PurchInvLine."Amount Including VAT" * LibraryRandom.RandInt(99) / 100, 0, '');
        ApplyAndPostVendorEntry(
          PurchInvLine."Document No.", GenJournalLine."Document No.", GenJournalLine."Document Type"::Payment);

        // Verification: Verify General Ledger Register for Unrealized VAT.
        VerifyUnrealizedVATEntry(GenJournalLine, VATPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestZeroVATUnrealizedVATEntry()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
        ZeroVATPostingSetup: Record "VAT Posting Setup";
        PurchInvLine: Record "Purch. Inv. Line";
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        DocumentNo: Code[20];
    begin
        // [SCENARIO 357562] Purchase Unrealized VAT with VAT% = 0 is realized - G/L and VAT Entries are posted
        Initialize();
        LibraryERM.SetUnrealizedVAT(true);
        LibraryERM.CreateVATPostingSetupWithAccounts(ZeroVATPostingSetup, ZeroVATPostingSetup."VAT Calculation Type"::"Normal VAT", 1);
        UpdateVATPostingSetup(ZeroVATPostingSetup, ZeroVATPostingSetup."Unrealized VAT Type"::Percentage);

        // [GIVEN] Set VAT% = 0 in Unrealized VAT Posting Setup
        ZeroVATPostingSetup."VAT %" := 0;
        ZeroVATPostingSetup.Modify();

        // [GIVEN] Post Purchase Invoice1. Transaction No = 100.
        CreatePurchaseInvoice(PurchaseHeader, ZeroVATPostingSetup);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        GLEntry.FindLast();

        // [GIVEN] Post Payment where Amount is the full Invoice Amount. Transaction No = 101.
        FindPurchaseInvoiceLine(PurchInvLine, PurchaseHeader."No.");
        CreateAndPostGeneralJournaLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment, PurchaseHeader."Buy-from Vendor No.",
          PurchInvLine."Amount Including VAT", 0, '');

        // [GIVEN] Apply Payment on Invoice from Vendor Ledger Entries. Transaction No = 102.
        ApplyAndPostVendorEntry(
          PurchInvLine."Document No.", GenJournalLine."Document No.", GenJournalLine."Document Type"::Payment);

        // [WHEN] Post Purchase Invoice2. Transaction No = 103.
        CreatePurchaseInvoice(PurchaseHeader, ZeroVATPostingSetup);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] (Invoice1) Verify VAT Entry is realized - Remaining Unrealized Amounts are 0
        // [THEN] (Invoice1) Unrealized VAT Transaction No = 100
        // [THEN] (Invoice1) Realized VAT Transaction No = 102
        VerifyUnrealizedVATEntryIsRealized(GenJournalLine."Document No.", GLEntry."Transaction No.", GLEntry."Transaction No." + 2);
        // [THEN] (Invoice1) Verify zero G/L Entry is posted for Realized VAT.
        VerifyUnrealizedVATEntry(GenJournalLine, ZeroVATPostingSetup);
        // [THEN] (Invoice2) Unrealized VAT Transaction No = 103 (TFS 305387)
        FindLastVATEntry(VATEntry, DocumentNo);
        VATEntry.TestField("Transaction No.", GLEntry."Transaction No." + 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnrealizedVATFullyPaid()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        // Test Unrealized VAT option to First (Fully Paid).

        // 1. Setup: Update Unrealized VAT Setup, Create and Post Purchase Invoice.
        EnableUnrealizedSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::"First (Fully Paid)");

        CreatePurchaseInvoice(PurchaseHeader, VATPostingSetup);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // 2. Excercise: Create and Apply Payment on Invoice from Vendor Ledger Entries.
        FindPurchaseInvoiceLine(PurchInvLine, PurchaseHeader."No.");
        // Payment Amount should be half of VAT Amount.
        CreateAndPostGeneralJournaLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment, PurchaseHeader."Buy-from Vendor No.",
          PurchInvLine."Amount Including VAT" - PurchInvLine.Amount / 2, 0, '');
        ApplyAndPostVendorEntry(PurchInvLine."Document No.", GenJournalLine."Document No.", GenJournalLine."Document Type"::Payment);

        // 3. Verify: Verify General Ledger Register for Unrealized VAT.
        VerifyGLEntryForFullyPaid(
          VATPostingSetup."Purch. VAT Unreal. Account", PurchInvLine.Amount - PurchInvLine."Amount Including VAT");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UnrealizedVATPercentage()
    var
        PurchaseHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Test Unrealized VAT option to Percentage with Credit Memo.

        // 1. Setup: Update Unrealized VAT Setup, Create and Post Purchase Invoice.
        EnableUnrealizedSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::Percentage);

        CreatePurchaseInvoice(PurchaseHeader, VATPostingSetup);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // 2. Exercise: Create and Post Credit Memo.
        CreateAndPostCreditMemo(FindPostedInvoiceNo(PurchaseHeader."No."), PurchaseHeader."Buy-from Vendor No.");

        // 3. Verify: Verify that VAT Entries exist for Invoice and Credit Memo.
        VerifyGLEntry(
          VATPostingSetup."Purch. VAT Unreal. Account", PurchaseHeader."Document Type"::Invoice,
          CalculateInvoiceAmount(FindPostedInvoiceNo(PurchaseHeader."No.")) * VATPostingSetup."VAT %" / 100);
        VerifyGLEntry(
          VATPostingSetup."Purch. VAT Unreal. Account", PurchaseHeader."Document Type"::"Credit Memo",
          -CalculateInvoiceAmount(FindPostedInvoiceNo(PurchaseHeader."No.")) * VATPostingSetup."VAT %" / 100);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UnrealizedVATPercentageApply()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PostedInvoiceNo: Code[20];
    begin
        // Test Unrealized VAT option to Percentage and Apply.

        // 1. Setup: Update Unrealized VAT Setup, Create and Post Purchase Invoice.
        EnableUnrealizedSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::Percentage);

        CreatePurchaseInvoiceWithGL(PurchaseHeader, VATPostingSetup);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // 2. Exercise: Create, Post and Apply Credit Memo.
        PostedInvoiceNo := FindPostedInvoiceNo(PurchaseHeader."No.");
        ApplyAndPostVendorEntry(
          PostedInvoiceNo, FindPostedCreditMemoNo(CreateAndPostCreditMemo(PostedInvoiceNo, PurchaseHeader."Buy-from Vendor No.")),
          PurchaseHeader."Document Type"::"Credit Memo");

        // 3. Verify: Verify that Credit Memo Applies to Invoice.
        VerifyVendorLedgerEntry(PurchaseHeader."Buy-from Vendor No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnrealizedVATWithCreditMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        GenJournalLine: Record "Gen. Journal Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GLEntry: Record "G/L Entry";
    begin
        // Test G/L Entry for Unrealized VAT after Applying Refund on Credit Memo.

        // 1. Setup: Update General Ledger Setup, Create Payment Terms with Calc. Pmt. Disc. on Cr. Memos as True, Unrealized VAT Setup,
        EnableUnrealizedSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::Percentage);

        // Create Purchase Header with document Type Credit Memo, Purchase Line and Post the Credit Memo.
        CreatePurchaseCreditMemo(PurchaseHeader, VATPostingSetup);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // 2. Exercise: Create and Post General Journal for Refund and apply it on Credit Memo.
        CreateAndPostGeneralJournaLine(
          GenJournalLine, GenJournalLine."Document Type"::Refund, PurchaseHeader."Buy-from Vendor No.",
          -LibraryRandom.RandDec(100, 2), LibraryRandom.RandInt(5), '');
        ApplyAndPostVendorEntry(
          FindPostedCreditMemoNo(PurchaseHeader."No."), GenJournalLine."Document No.", GenJournalLine."Document Type");

        // 3. Verify: Verify G/L Entry for Unrealized VAT.
        VerifyGLEntry(
          VATPostingSetup."Purch. VAT Unreal. Account", GLEntry."Document Type"::Refund,
          -Round(GenJournalLine.Amount * VATPostingSetup."VAT %" / (VATPostingSetup."VAT %" + 100)));
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesHandler,PostApplicationHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ApplyAndPostApplicationPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        // Test application of Payment to Invoice for Unrealized VAT Type as Blank using Page Testability.

        // 1. Setup: Update Unrealized VAT on General Ledger Setup and Unrealized VAT Type as Blank on VAT Posting Setup.
        EnableUnrealizedSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::" ");

        // Create and post Purchase Invoice. Create and post General Journal Line.
        CreatePurchaseInvoice(PurchaseHeader, VATPostingSetup);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        FindPurchaseInvoiceLine(PurchInvLine, PurchaseHeader."No.");

        // Payment Amount should be half of Amount Including VAT of Purchase Invoice line.
        CreateAndPostGeneralJournaLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment, PurchaseHeader."Buy-from Vendor No.",
          PurchInvLine."Amount Including VAT" / 2, 0, '');

        // 2. Exercise: Open Vendor Ledger Entries and invoke Apply Entries page.
        ApplyVendorLedgerEntriesByPage(PurchaseHeader."Buy-from Vendor No.", GenJournalLine."Document Type"::Payment);

        // 3. Verify: Verify zero Transaction No on Application Entry after Apply Vendor payment.
        LibraryERM.VerifyVendApplnWithZeroTransNo(
          GenJournalLine."Document No.", GenJournalLine."Document Type", -GenJournalLine."Amount (LCY)");
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesHandler,PostApplicationHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UnrealizedVATApplyPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        // Test application of Payment to Invoice for Unrealized VAT Type as Percentage using Page Testability.

        // 1. Setup: Update Unrealized VAT on General Ledger Setup and Unrealized VAT Type as Percentage on VAT Posting Setup.
        EnableUnrealizedSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::Percentage);

        // Create and post Purchase Invoice. Create and post General Journal Line.
        CreatePurchaseInvoice(PurchaseHeader, VATPostingSetup);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        FindPurchaseInvoiceLine(PurchInvLine, PurchaseHeader."No.");

        // Payment Amount should be half of Amount Including VAT of Purchase Invoice line.
        CreateAndPostGeneralJournaLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment, PurchaseHeader."Buy-from Vendor No.",
          PurchInvLine."Amount Including VAT" / 2, 0, '');

        // 2. Exercise: Open Vendor Ledger Entries and invoke Apply Entries page.
        ApplyVendorLedgerEntriesByPage(PurchaseHeader."Buy-from Vendor No.", GenJournalLine."Document Type"::Payment);

        // 3. Verify: Verify Unrealized VAT Amount on G/L Entry after Apply Vendor payment.
        VerifyUnrealizedVATEntry(GenJournalLine, VATPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreditMemoPostingWithUnrealizedVatTypePercentage()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GLAccount: Record "G/L Account";
        PurchInvLine: Record "Purch. Inv. Line";
        GLAccountNo: Code[20];
        PostedDocumentNo: Code[20];
    begin
        // Test Credit Memo Posted Successfully when Payment to Invoice for Unrealized VAT Type as Percentage in VAT Posting Setup.

        // Setup: Update Unrealized VAT on General Ledger Setup and Unrealized VAT Type as Percentage on VAT Posting Setup.
        EnableUnrealizedSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::Percentage);

        // Create and post Purchase Invoice. Create and post General Journal Line.
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateVendor(VATPostingSetup."VAT Bus. Posting Group"));
        GLAccountNo :=
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase);
        CreatePurchaseLine(PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccountNo);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        FindPurchaseInvoiceLine(PurchInvLine, PurchaseHeader."No.");
        CreateApplyAndPostPayment(
          PurchaseHeader."Buy-from Vendor No.", PurchInvLine."Document No.", PurchInvLine."Amount Including VAT" / 2);

        // Exercise: Create and Post Credit Memo.
        PostedDocumentNo := CreateAndPostPurchaseCreditMemo(PurchInvLine);

        // Verify: Verify Purchase Credit Memo Header Exist.
        VerifyPurchaseCreditMemoHeader(PostedDocumentNo, PurchInvLine."Buy-from Vendor No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceWithNegativeLinePartialApply()
    var
        PurchaseHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        PaymentNo: Code[20];
        VATBaseAmount: array[2] of Decimal;
        VATAmount: array[2] of Decimal;
        DocAmount: Decimal;
        AmountToApply: Decimal;
        Fraction: Decimal;
        AmountRoundingPrecision: Decimal;
    begin
        // [FEATURE] [Partial Payment]
        // [SCENARIO 363444] Unrealized VAT Entries are filled with percentage amount values in case of partial applying Purchase Invoice with negative line

        // [GIVEN] Enable GLSetup."Unealized VAT".  Config "VAT Posting Setup"."Unrealized VAT Type" = Percentage.
        EnableUnrealizedSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::Percentage);
        AmountRoundingPrecision := LibraryERM.GetAmountRoundingPrecision();

        // [GIVEN] Create and Post Purchase Invoice with two lines:
        // [GIVEN] Positive Line: Quantity = 1,"Unit Price" = 1000, VAT Amount = 200
        // [GIVEN] Negative Line: Quantity = -1,"Unit Price" = 800, VAT Amount = 160
        DocumentNo :=
          CreatePostPurchaseInvoiceWithNegativeLine(PurchaseHeader, VATPostingSetup, VATBaseAmount, VATAmount, AmountRoundingPrecision);

        // [WHEN] Post and apply vendor partial payment to the Invoice with amount = 30% of Invoice
        DocAmount := VATBaseAmount[1] + VATAmount[1] - (VATBaseAmount[2] + VATAmount[2]);
        Fraction := LibraryRandom.RandIntInRange(3, 5);
        AmountToApply := Round(DocAmount / Fraction, AmountRoundingPrecision);
        PaymentNo := CreateApplyAndPostPayment(PurchaseHeader."Buy-from Vendor No.", DocumentNo, AmountToApply);

        // [THEN] Positive realized VAT Entry has Base = 300, Amount = 60 (30% of 200)
        VerifyPositiveVATEntry(
          PaymentNo, Round(VATBaseAmount[1] / Fraction), Round(VATAmount[1] / Fraction));

        // [THEN] Negative realized VAT Entry has Base = -240, Amount = -48  (30% of 160)
        VerifyNegativeVATEntry(
          PaymentNo, -Round(VATBaseAmount[2] / Fraction), -Round(VATAmount[2] / Fraction));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ThreePartialPaymentsOfUnrealVATPurchInvoiceWithThreeLines()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[3] of Record "Purchase Line";
        VendorNo: Code[20];
        InvoiceNo: Code[20];
        PaymentNo: array[3] of Code[20];
        TotalAmount: Decimal;
        PmtAmount: array[2] of Decimal;
        UnrealizedVATEntryNo: array[3] of Integer;
    begin
        // [SCENARIO 380404] Several partial payments of Purchase Invoice with Unrealized VAT and several purchase lines

        // [GIVEN] Unrealized VAT Posting Setup with VAT% = 20
        EnableUnrealizedSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::Percentage);
        // [GIVEN] Purchase Invoice with three different G/l Account's lines:
        VendorNo := LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group");
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        // [GIVEN] Line1: Amount = 3000, Amount Including VAT = 3600
        CreatePurchaseLineWithGLAccount(
          PurchaseLine[1], PurchaseHeader, VATPostingSetup, 1, LibraryRandom.RandDecInRange(5000, 6000, 2));
        // [GIVEN] Line2: Amount = 2000, Amount Including VAT = 2400
        CreatePurchaseLineWithGLAccount(
          PurchaseLine[2], PurchaseHeader, VATPostingSetup, 1, PurchaseLine[1].Amount - LibraryRandom.RandDecInRange(1000, 2000, 2));
        // [GIVEN] Line3: Amount = 1000, Amount Including VAT = 1200
        CreatePurchaseLineWithGLAccount(
          PurchaseLine[3], PurchaseHeader, VATPostingSetup, 1, PurchaseLine[2].Amount - LibraryRandom.RandDecInRange(1000, 2000, 2));
        // [GIVEN] Post Purchase Invoice. Total Amount Including VAT = 7200
        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        TotalAmount :=
          PurchaseLine[1]."Amount Including VAT" + PurchaseLine[2]."Amount Including VAT" + PurchaseLine[3]."Amount Including VAT";
        // [GIVEN] Create apply and post partial payment "P1" with Amount = 7200 * 0.1 = 720 (10%)
        PmtAmount[1] := Round(TotalAmount * 0.1);
        PaymentNo[1] := CreateApplyAndPostPayment(VendorNo, InvoiceNo, PmtAmount[1]);
        // [GIVEN] Create apply and post partial payment "P2" with Amount = 7200 * 0.6 = 4320 (60%)
        PmtAmount[2] := Round(TotalAmount * 0.6);
        PaymentNo[2] := CreateApplyAndPostPayment(VendorNo, InvoiceNo, PmtAmount[2]);
        // [WHEN] Create apply and post partial (final) payment "P3" with Amount = 7200 * 0.3 = 2160 (30%)
        PaymentNo[3] := CreateApplyAndPostPayment(VendorNo, InvoiceNo, TotalAmount - PmtAmount[1] - PmtAmount[2]);

        // [THEN] Vendor's Invoice and Payments ledger entries are closed ("Remaining Amount" = 0)
        VerifyVendorLedgerEntryAmounts(VendorNo, InvoiceNo, -TotalAmount, 0);
        VerifyVendorLedgerEntryAmounts(VendorNo, PaymentNo[1], PmtAmount[1], 0);
        VerifyVendorLedgerEntryAmounts(VendorNo, PaymentNo[2], PmtAmount[2], 0);
        VerifyVendorLedgerEntryAmounts(VendorNo, PaymentNo[3], TotalAmount - PmtAmount[1] - PmtAmount[2], 0);

        // [THEN] There are 3 closed Invoice Unrealized VAT Entries ("Remaining Unrealized Base" = "Remaining Unrealized Amount" = 0):
        // [THEN] "Entry No." = 1, "Unrealized Base" = 1000, "Unrealized Amount" = 200
        // [THEN] "Entry No." = 2, "Unrealized Base" = 2000, "Unrealized Amount" = 400
        // [THEN] "Entry No." = 3, "Unrealized Base" = 3000, "Unrealized Amount" = 600
        VerifyThreeUnrealizedVATEntry(UnrealizedVATEntryNo, VendorNo, InvoiceNo, PurchaseLine);

        // [THEN] There are 3 realized VAT Entries related to payment "P1" :
        // [THEN] "Document No." = "P1", "Base" = 100, "Amount" = 20, "Unrealized VAT Entry No." = 1
        // [THEN] "Document No." = "P1", "Base" = 200, "Amount" = 40, "Unrealized VAT Entry No." = 2
        // [THEN] "Document No." = "P1", "Base" = 300, "Amount" = 60, "Unrealized VAT Entry No." = 3
        VerifyThreeRealizedVATEntry(UnrealizedVATEntryNo, VendorNo, PaymentNo[1], PurchaseLine, 0.1);

        // [THEN] There are 3 realized VAT Entries related to payment "P2" :
        // [THEN] "Document No." = "P2", "Base" = 600, "Amount" = 120, "Unrealized VAT Entry No." = 1
        // [THEN] "Document No." = "P2", "Base" = 1200, "Amount" = 240, "Unrealized VAT Entry No." = 2
        // [THEN] "Document No." = "P2", "Base" = 1800, "Amount" = 360, "Unrealized VAT Entry No." = 3
        VerifyThreeRealizedVATEntry(UnrealizedVATEntryNo, VendorNo, PaymentNo[2], PurchaseLine, 0.6);

        // [THEN] There are 3 realized VAT Entries related to payment "P3" :
        // [THEN] "Document No." = "P3", "Base" = 300, "Amount" = 60, "Unrealized VAT Entry No." = 1
        // [THEN] "Document No." = "P3", "Base" = 600, "Amount" = 120, "Unrealized VAT Entry No." = 2
        // [THEN] "Document No." = "P3", "Base" = 900, "Amount" = 180, "Unrealized VAT Entry No." = 3
        VerifyThreeRealizedVATEntry(UnrealizedVATEntryNo, VendorNo, PaymentNo[3], PurchaseLine, 0.3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FCYCrMemoToInvoiceHalfMinusPaidDownExchRate()
    var
        PurchaseHeader: Record "Purchase Header";
        InvoiceNo: Code[20];
        CrMemoNo: Code[20];
    begin
        // [FEATURE] [Currency]
        // [SCENARIO 261852] Post purchase credit memo applied to partially paid invoice (credit memo = invoice, payment < 1/2 invoice)
        // [SCENARIO 261852] in case of unrealized VAT, FCY, custom amounts, Exchange:Relational ratio < 1
        Initialize();

        // [GIVEN] Unrealized VAT Setup with "Unrealized VAT Type" = Percentage, "VAT %" = 18
        // [GIVEN] Currency with Exchange:Relational ratio = 1/100:1
        // [GIVEN] Posted Invoice with FCY Amount = 1000
        // [GIVEN] Posted Payment with FCY Amount = 589.99
        // [GIVEN] Payment is applied to the Invoice
        // [GIVEN] Credit Memo with FCY Amount = 1000
        // [GIVEN] Apply Credit Memo to the Invoice
        PerformScenarioTFS261852(PurchaseHeader, InvoiceNo, 18, 1 / 100, 1000, 1000, 589.99);

        // [WHEN] Post the Credit Memo
        CrMemoNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] The Credit Memo has been posted. Invoice VAT has been fully realized. Credit Memo VAT has been realized by 50000.85\9000.15
        VerifyInvAndCrMemoVATEntries(InvoiceNo, CrMemoNo, 100000, 18000, 50000.85, 9000.15);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FCYCrMemoToInvoiceHalfPlusPaidDownExchRate()
    var
        PurchaseHeader: Record "Purchase Header";
        InvoiceNo: Code[20];
        CrMemoNo: Code[20];
    begin
        // [FEATURE] [Currency]
        // [SCENARIO 261852] Post purchase credit memo applied to partially paid invoice (credit memo = invoice, payment > 1/2 invoice)
        // [SCENARIO 261852] in case of unrealized VAT, FCY, custom amounts, Exchange:Relational ratio < 1
        Initialize();

        // [GIVEN] Unrealized VAT Setup with "Unrealized VAT Type" = Percentage, "VAT %" = 18
        // [GIVEN] Currency with Exchange:Relational ratio = 1/100:1
        // [GIVEN] Posted Invoice with FCY Amount = 1000
        // [GIVEN] Posted Payment with FCY Amount = 590.01
        // [GIVEN] Payment is applied to the Invoice
        // [GIVEN] Credit Memo with FCY Amount = 1000
        // [GIVEN] Apply Credit Memo to the Invoice
        PerformScenarioTFS261852(PurchaseHeader, InvoiceNo, 18, 1 / 100, 1000, 1000, 590.01);

        // [WHEN] Post the Credit Memo
        CrMemoNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] The Credit Memo has been posted. Invoice VAT has been fully realized. Credit Memo VAT has been realized by 49999.15\8999.85
        VerifyInvAndCrMemoVATEntries(InvoiceNo, CrMemoNo, 100000, 18000, 49999.15, 8999.85);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FCYCrMemoToInvoiceHalfMinusPaidUpExchRate()
    var
        PurchaseHeader: Record "Purchase Header";
        InvoiceNo: Code[20];
        CrMemoNo: Code[20];
    begin
        // [FEATURE] [Currency]
        // [SCENARIO 261852] Post purchase credit memo applied to partially paid invoice (credit memo = invoice, payment < 1/2 invoice)
        // [SCENARIO 261852] in case of unrealized VAT, FCY, custom amounts, Exchange:Relational ratio > 1
        Initialize();

        // [GIVEN] Unrealized VAT Setup with "Unrealized VAT Type" = Percentage, "VAT %" = 18
        // [GIVEN] Currency with Exchange:Relational ratio = 100
        // [GIVEN] Posted Invoice with FCY Amount = 1000
        // [GIVEN] Posted Payment with FCY Amount = 589
        // [GIVEN] Payment is applied to the Invoice
        // [GIVEN] Credit Memo with FCY Amount = 1000
        // [GIVEN] Apply Credit Memo to the Invoice
        PerformScenarioTFS261852(PurchaseHeader, InvoiceNo, 18, 100, 1000, 1000, 589);

        // [WHEN] Post the Credit Memo
        CrMemoNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] The Credit Memo has been posted. Invoice VAT has been fully realized. Credit Memo VAT has been realized by 5.01\0.9
        VerifyInvAndCrMemoVATEntries(InvoiceNo, CrMemoNo, 10, 1.8, 5.01, 0.9);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FCYCrMemoToInvoiceHalfPlusPaidUpExchRate()
    var
        PurchaseHeader: Record "Purchase Header";
        InvoiceNo: Code[20];
        CrMemoNo: Code[20];
    begin
        // [FEATURE] [Currency]
        // [SCENARIO 261852] Post purchase credit memo applied to partially paid invoice (credit memo = invoice, payment > 1/2 invoice)
        // [SCENARIO 261852] in case of unrealized VAT, FCY, custom amounts, Exchange:Relational ratio > 1
        Initialize();

        // [GIVEN] Unrealized VAT Setup with "Unrealized VAT Type" = Percentage, "VAT %" = 18
        // [GIVEN] Currency with Exchange:Relational ratio = 100
        // [GIVEN] Posted Invoice with FCY Amount = 1000
        // [GIVEN] Posted Payment with FCY Amount = 591
        // [GIVEN] Payment is applied to the Invoice
        // [GIVEN] Credit Memo with FCY Amount = 1000
        // [GIVEN] Apply Credit Memo to the Invoice
        PerformScenarioTFS261852(PurchaseHeader, InvoiceNo, 18, 100, 1000, 1000, 591);

        // [WHEN] Post the Credit Memo
        CrMemoNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] The Credit Memo has been posted. Invoice VAT has been fully realized. Credit Memo VAT has been realized by 4.99\0.9
        VerifyInvAndCrMemoVATEntries(InvoiceNo, CrMemoNo, 10, 1.8, 4.99, 0.9);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FCYCrMemoOverInvoiceHalfMinusPaidDownExchRate()
    var
        PurchaseHeader: Record "Purchase Header";
        InvoiceNo: Code[20];
        CrMemoNo: Code[20];
    begin
        // [FEATURE] [Currency]
        // [SCENARIO 261852] Post purchase credit memo applied to partially paid invoice (credit memo > invoice, payment < 1/2 invoice)
        // [SCENARIO 261852] in case of unrealized VAT, FCY, custom amounts, Exchange:Relational ratio < 1
        Initialize();

        // [GIVEN] Unrealized VAT Setup with "Unrealized VAT Type" = Percentage, "VAT %" = 18
        // [GIVEN] Currency with Exchange:Relational ratio = 1/100:1
        // [GIVEN] Posted Invoice with FCY Amount = 1000
        // [GIVEN] Posted Payment with FCY Amount = 589.99
        // [GIVEN] Payment is applied to the Invoice
        // [GIVEN] Credit Memo with FCY Amount = 2000
        // [GIVEN] Apply Credit Memo to the Invoice
        PerformScenarioTFS261852(PurchaseHeader, InvoiceNo, 18, 1 / 100, 1000, 2000, 589.99);

        // [WHEN] Post the Credit Memo
        CrMemoNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] The Credit Memo has been posted. Invoice VAT has been fully realized. Credit Memo VAT has been realized by 50000.85\9000.15
        VerifyInvAndCrMemoVATEntries(InvoiceNo, CrMemoNo, 200000, 36000, 50000.85, 9000.15);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FCYCrMemoOverInvoiceHalfPlusPaidDownExchRate()
    var
        PurchaseHeader: Record "Purchase Header";
        InvoiceNo: Code[20];
        CrMemoNo: Code[20];
    begin
        // [FEATURE] [Currency]
        // [SCENARIO 261852] Post purchase credit memo applied to partially paid invoice (credit memo > invoice, payment > 1/2 invoice)
        // [SCENARIO 261852] in case of unrealized VAT, FCY, custom amounts, Exchange:Relational ratio < 1
        Initialize();

        // [GIVEN] Unrealized VAT Setup with "Unrealized VAT Type" = Percentage, "VAT %" = 18
        // [GIVEN] Currency with Exchange:Relational ratio = 1/100:1
        // [GIVEN] Posted Invoice with FCY Amount = 1000
        // [GIVEN] Posted Payment with FCY Amount = 590.01
        // [GIVEN] Payment is applied to the Invoice
        // [GIVEN] Credit Memo with FCY Amount = 2000
        // [GIVEN] Apply Credit Memo to the Invoice
        PerformScenarioTFS261852(PurchaseHeader, InvoiceNo, 18, 1 / 100, 1000, 2000, 590.01);

        // [WHEN] Post the Credit Memo
        CrMemoNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] The Credit Memo has been posted. Invoice VAT has been fully realized. Credit Memo VAT has been realized by 49999.15\8999.85
        VerifyInvAndCrMemoVATEntries(InvoiceNo, CrMemoNo, 200000, 36000, 49999.15, 8999.85);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FCYCrMemoOverInvoiceHalfMinusPaidUpExchRate()
    var
        PurchaseHeader: Record "Purchase Header";
        InvoiceNo: Code[20];
        CrMemoNo: Code[20];
    begin
        // [FEATURE] [Currency]
        // [SCENARIO 261852] Post purchase credit memo applied to partially paid invoice (credit memo > invoice, payment < 1/2 invoice)
        // [SCENARIO 261852] in case of unrealized VAT, FCY, custom amounts, Exchange:Relational ratio > 1
        Initialize();

        // [GIVEN] Unrealized VAT Setup with "Unrealized VAT Type" = Percentage, "VAT %" = 18
        // [GIVEN] Currency with Exchange:Relational ratio = 100
        // [GIVEN] Posted Invoice with FCY Amount = 1000
        // [GIVEN] Posted Payment with FCY Amount = 589
        // [GIVEN] Payment is applied to the Invoice
        // [GIVEN] Credit Memo with FCY Amount = 2000
        // [GIVEN] Apply Credit Memo to the Invoice
        PerformScenarioTFS261852(PurchaseHeader, InvoiceNo, 18, 100, 1000, 2000, 589);

        // [WHEN] Post the Credit Memo
        CrMemoNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] The Credit Memo has been posted. Invoice VAT has been fully realized. Credit Memo VAT has been realized by 5.01\0.9
        VerifyInvAndCrMemoVATEntries(InvoiceNo, CrMemoNo, 20, 3.6, 5.01, 0.9);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FCYCrMemoOverInvoiceHalfPlusPaidUpExchRate()
    var
        PurchaseHeader: Record "Purchase Header";
        InvoiceNo: Code[20];
        CrMemoNo: Code[20];
    begin
        // [FEATURE] [Currency]
        // [SCENARIO 261852] Post purchase credit memo applied to partially paid invoice (credit memo > invoice, payment > 1/2 invoice)
        // [SCENARIO 261852] in case of unrealized VAT, FCY, custom amounts, Exchange:Relational ratio > 1
        Initialize();

        // [GIVEN] Unrealized VAT Setup with "Unrealized VAT Type" = Percentage, "VAT %" = 18
        // [GIVEN] Currency with Exchange:Relational ratio = 100
        // [GIVEN] Posted Invoice with FCY Amount = 1000
        // [GIVEN] Posted Payment with FCY Amount = 591
        // [GIVEN] Payment is applied to the Invoice
        // [GIVEN] Credit Memo with FCY Amount = 2000
        // [GIVEN] Apply Credit Memo to the Invoice
        PerformScenarioTFS261852(PurchaseHeader, InvoiceNo, 18, 100, 1000, 2000, 591);

        // [WHEN] Post the Credit Memo
        CrMemoNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] The Credit Memo has been posted. Invoice VAT has been fully realized. Credit Memo VAT has been realized by 4.99\0.9
        VerifyInvAndCrMemoVATEntries(InvoiceNo, CrMemoNo, 20, 3.6, 4.99, 0.9);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FCYCrMemoLowerInvoiceHalfMinusPaidDownExchRate()
    var
        PurchaseHeader: Record "Purchase Header";
        InvoiceNo: Code[20];
        CrMemoNo: Code[20];
    begin
        // [FEATURE] [Currency]
        // [SCENARIO 261852] Post purchase credit memo applied to partially paid invoice (credit memo < invoice, payment < 1/2 invoice)
        // [SCENARIO 261852] in case of unrealized VAT, FCY, custom amounts, Exchange:Relational ratio < 1
        Initialize();

        // [GIVEN] Unrealized VAT Setup with "Unrealized VAT Type" = Percentage, "VAT %" = 18
        // [GIVEN] Currency with Exchange:Relational ratio = 1/100:1
        // [GIVEN] Posted Invoice with FCY Amount = 1000
        // [GIVEN] Posted Payment with FCY Amount = 589.99
        // [GIVEN] Payment is applied to the Invoice
        // [GIVEN] Credit Memo with FCY Amount = 800
        // [GIVEN] Apply Credit Memo to the Invoice
        PerformScenarioTFS261852(PurchaseHeader, InvoiceNo, 18, 1 / 100, 1000, 800, 589.99);

        // [WHEN] Post the Credit Memo
        CrMemoNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] The Credit Memo has been posted. Invoice VAT has been fully realized. Credit Memo VAT has been realized by 50000.85\9000.15
        VerifyInvAndCrMemoVATEntries(InvoiceNo, CrMemoNo, 80000, 14400, 50000.85, 9000.15);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FCYCrMemoLowerInvoiceHalfPlusPaidDownExchRate()
    var
        PurchaseHeader: Record "Purchase Header";
        InvoiceNo: Code[20];
        CrMemoNo: Code[20];
    begin
        // [FEATURE] [Currency]
        // [SCENARIO 261852] Post purchase credit memo applied to partially paid invoice (credit memo < invoice, payment > 1/2 invoice)
        // [SCENARIO 261852] in case of unrealized VAT, FCY, custom amounts, Exchange:Relational ratio < 1
        Initialize();

        // [GIVEN] Unrealized VAT Setup with "Unrealized VAT Type" = Percentage, "VAT %" = 18
        // [GIVEN] Currency with Exchange:Relational ratio = 1/100:1
        // [GIVEN] Posted Invoice with FCY Amount = 1000
        // [GIVEN] Posted Payment with FCY Amount = 590.01
        // [GIVEN] Payment is applied to the Invoice
        // [GIVEN] Credit Memo with FCY Amount = 800
        // [GIVEN] Apply Credit Memo to the Invoice
        PerformScenarioTFS261852(PurchaseHeader, InvoiceNo, 18, 1 / 100, 1000, 800, 590.01);

        // [WHEN] Post the Credit Memo
        CrMemoNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] The Credit Memo has been posted. Invoice VAT has been fully realized. Credit Memo VAT has been realized by 49999.15\8999.85
        VerifyInvAndCrMemoVATEntries(InvoiceNo, CrMemoNo, 80000, 14400, 49999.15, 8999.85);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FCYCrMemoLowerInvoiceHalfMinusPaidUpExchRate()
    var
        PurchaseHeader: Record "Purchase Header";
        InvoiceNo: Code[20];
        CrMemoNo: Code[20];
    begin
        // [FEATURE] [Currency]
        // [SCENARIO 261852] Post purchase credit memo applied to partially paid invoice (credit memo < invoice, payment < 1/2 invoice)
        // [SCENARIO 261852] in case of unrealized VAT, FCY, custom amounts, Exchange:Relational ratio > 1
        Initialize();

        // [GIVEN] Unrealized VAT Setup with "Unrealized VAT Type" = Percentage, "VAT %" = 18
        // [GIVEN] Currency with Exchange:Relational ratio = 100
        // [GIVEN] Posted Invoice with FCY Amount = 1000
        // [GIVEN] Posted Payment with FCY Amount = 589
        // [GIVEN] Payment is applied to the Invoice
        // [GIVEN] Credit Memo with FCY Amount = 800
        // [GIVEN] Apply Credit Memo to the Invoice
        PerformScenarioTFS261852(PurchaseHeader, InvoiceNo, 18, 100, 1000, 800, 589);

        // [WHEN] Post the Credit Memo
        CrMemoNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] The Credit Memo has been posted. Invoice VAT has been fully realized. Credit Memo VAT has been realized by 5.01\0.9
        VerifyInvAndCrMemoVATEntries(InvoiceNo, CrMemoNo, 8, 1.44, 5.01, 0.9);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FCYCrMemoLowerInvoiceHalfPlusPaidUpExchRate()
    var
        PurchaseHeader: Record "Purchase Header";
        InvoiceNo: Code[20];
        CrMemoNo: Code[20];
    begin
        // [FEATURE] [Currency]
        // [SCENARIO 261852] Post purchase credit memo applied to partially paid invoice (credit memo < invoice, payment > 1/2 invoice)
        // [SCENARIO 261852] in case of unrealized VAT, FCY, custom amounts, Exchange:Relational ratio > 1
        Initialize();

        // [GIVEN] Unrealized VAT Setup with "Unrealized VAT Type" = Percentage, "VAT %" = 18
        // [GIVEN] Currency with Exchange:Relational ratio = 100
        // [GIVEN] Posted Invoice with FCY Amount = 1000
        // [GIVEN] Posted Payment with FCY Amount = 591
        // [GIVEN] Payment is applied to the Invoice
        // [GIVEN] Credit Memo with FCY Amount = 800
        // [GIVEN] Apply Credit Memo to the Invoice
        PerformScenarioTFS261852(PurchaseHeader, InvoiceNo, 18, 100, 1000, 800, 591);

        // [WHEN] Post the Credit Memo
        CrMemoNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] The Credit Memo has been posted. Invoice VAT has been fully realized. Credit Memo VAT has been realized by 4.99\0.9
        VerifyInvAndCrMemoVATEntries(InvoiceNo, CrMemoNo, 8, 1.44, 4.99, 0.9);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FCYInvoiceAppliedWithSameExchRateAfterExchRateAdjustment()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VATEntry: Record "VAT Entry";
        VendorNo: Code[20];
        CurrencyCode: Code[10];
        InvoiceNo: Code[20];
        PaymentNo: Code[20];
        ExchangeRate: Decimal;
        Amount: Decimal;
        AmountInclVAT: Decimal;
        AdjustedAmtInclVAT: Decimal;
    begin
        // [SCENARIO 293111] Unrealized VAT when payment applied with exch. rate of the invoice after exchange rate adjustment

        // [GIVEN] VAT Posting Setup with "Unrealized VAT Type" = Percentage and VAT% = 10
        EnableUnrealizedSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::Percentage);

        // [GIVEN] Currency with exch. rate 100/60 and adjustment exch. rate 100/65
        ExchangeRate := LibraryRandom.RandIntInRange(2, 5);
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), ExchangeRate + 1, ExchangeRate);

        // [GIVEN] Posted Purchase Invoice with Amount = 600, VAT Amount = 60 in LCY, 1000 and 100 in FCY respectively
        VendorNo := CreateVendorWithCurrency(VATPostingSetup."VAT Bus. Posting Group", CurrencyCode);
        InvoiceNo :=
          CreatePostSalesInvoiceForGivenCustomer(
            VendorNo, LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, "General Posting Type"::" "),
            CurrencyCode, LibraryRandom.RandDecInRange(100, 200, 2));

        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, InvoiceNo);
        VendorLedgerEntry.CalcFields(Amount, "Amount (LCY)");
        AmountInclVAT := -VendorLedgerEntry."Amount (LCY)";
        Amount := Round(AmountInclVAT / (1 + VATPostingSetup."VAT %" / 100));

        // [GIVEN] Adjusted exchange rate changed total invoice amount = 715 (1100 * 65 / 100), adjustment amount = 55 (715 - 660)
        LibraryERM.RunExchRateAdjustmentSimple(CurrencyCode, WorkDate(), WorkDate());
        VendorLedgerEntry.CalcFields(Amount, "Amount (LCY)");
        AdjustedAmtInclVAT := -VendorLedgerEntry."Amount (LCY)";

        // [WHEN] Payment is applied with same exch. rate 100/65
        PaymentNo := CreateApplyAndPostPayment(VendorNo, InvoiceNo, -VendorLedgerEntry.Amount);

        // [THEN] Invoice VAT Entry has Base = 0, Amount = 0
        // [THEN] Unrealized Base = 600, Unrealized Amount = 60
        // [THEN] Remaining Unrealized Base and Remaining Unrealized Amount = 0
        VATEntry.SetRange("Bill-to/Pay-to No.", VendorNo);
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

        // [THEN] Unrealized Losses posted with amount 55 for adjustment and amount = -55 after payment is applied
        VerifyUnrealizedGainLossesGLEntries(CurrencyCode, PaymentNo, AdjustedAmtInclVAT - AmountInclVAT);
    end;

    [Test]
    procedure ExpectedGLEntriesWhenPostingUnrealizedVATDeferralHeaderDiscountInvoice()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        DeferralTemplate: Record "Deferral Template";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        GLRegister: Record "G/L Register";
        GLEntry: Record "G/L Entry";
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
        VendorNo: Code[20];
        PostingDate: Date;
        PriceBeforeTax, Discount, Tax : Decimal;
    begin
        // [SCENARIO 548280] An invoice with header level discount and deferred revenue is posted in an unrealized VAT setup

        // [GIVEN] GL Setup using unrealized VAT
        EnableUnrealizedSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::"Last (Fully Paid)");
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.SetDiscountPostingInPurchasePayablesSetup();
        // [GIVEN] A deferral over 2 periods DEF1
        LibraryERM.CreateDeferralTemplate(DeferralTemplate, DeferralTemplate."Calc. Method"::"Equal per Period", DeferralTemplate."Start Date"::"Beginning of Next Period", 2);
        // [GIVEN] A purchase invoice with header level discount
        VendorNo := CreateVendor(VATPostingSetup."VAT Bus. Posting Group");
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        Item.Get(CreateItem(VATPostingSetup."VAT Prod. Posting Group"));
        Item."Default Deferral Template Code" := DeferralTemplate."Deferral Code";
        Item.Modify(true);
        // [GIVEN] A purchase invoice line with deferral code DEF1
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.");
        PriceBeforeTax := Round(PurchaseLine."Unit Cost" * PurchaseLine.Quantity);
        // [GIVEN] A header level discount
        Discount := Round(0.1 * PriceBeforeTax);
        PurchCalcDiscByType.ApplyInvDiscBasedOnAmt(Discount, PurchaseHeader);
        // [WHEN] Posting the sales invoice
        PostingDate := PurchaseHeader."Posting Date";
        GLRegisterOfPostedDocument(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, false), PostingDate, GLRegister);
        // [THEN] The G/L Accounts affected by the posting with the date of the invoice (not deferred) are affected as expected.
        Tax := Round((PriceBeforeTax - Discount) * VATPostingSetup."VAT %" / 100);
        GLEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        GLEntry.SetRange("Posting Date", PostingDate);
        AssertBalanceInAccountOfFilteredGLEntries(-(PriceBeforeTax + Tax - Discount), GetAccountPayablesGLAccount(VendorNo), GLEntry, 'The account payable GL Account should have the total + tax - discount at the posting date');
        AssertBalanceInAccountOfFilteredGLEntries(-Discount, GetHeaderDiscountGLAccount(VendorNo, Item), GLEntry, 'The discount granted GL account should have the discount at posting date');
        AssertBalanceInAccountOfFilteredGLEntries(Discount, GetExpensesGLAccount(VendorNo, Item), GLEntry, 'The revenue GL account should only have the discount at posting date');
        AssertBalanceInAccountOfFilteredGLEntries(PriceBeforeTax - Discount, GetDeferralGLAccount(DeferralTemplate), GLEntry, 'The deferred revenue GL Account should have the total - discount (no tax) at the posting date');
        AssertBalanceInAccountOfFilteredGLEntries(Tax, GetUnrealizedVATGLAccount(VATPostingSetup), GLEntry, 'The unrealized VAT should have the VAT at the posting date (considering discount)');
        // [THEN] The G/L Accounts affected by the posting including deferrals are affected as expected.
        GLEntry.SetRange("Posting Date");
        AssertBalanceInAccountOfFilteredGLEntries(PriceBeforeTax, GetExpensesGLAccount(VendorNo, Item), GLEntry, 'Over all time, the revenue GL account should have the total (no tax or discount)');
        AssertBalanceInAccountOfFilteredGLEntries(0, GetDeferralGLAccount(DeferralTemplate), GLEntry, 'Over all time, the deferral GL Account should be zero', true);
    end;

    [Test]
    procedure ExpectedGLEntriesWhenPostingUnrealizedVATDeferralLineDiscountInvoice()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        DeferralTemplate: Record "Deferral Template";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        GLRegister: Record "G/L Register";
        GLEntry: Record "G/L Entry";
        VendorNo: Code[20];
        PostingDate: Date;
        PriceBeforeTax, Discount, Tax : Decimal;
    begin
        // [SCENARIO 548280] An invoice with header level discount and deferred revenue is posted in an unrealized VAT setup

        // [GIVEN] GL Setup using unrealized VAT
        EnableUnrealizedSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::"Last (Fully Paid)");
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.SetDiscountPostingInPurchasePayablesSetup();
        // [GIVEN] A deferral over 2 periods DEF1
        LibraryERM.CreateDeferralTemplate(DeferralTemplate, DeferralTemplate."Calc. Method"::"Equal per Period", DeferralTemplate."Start Date"::"Beginning of Next Period", 2);
        // [GIVEN] A sales invoice with header level discount
        VendorNo := CreateVendor(VATPostingSetup."VAT Bus. Posting Group");
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        Item.Get(CreateItem(VATPostingSetup."VAT Prod. Posting Group"));
        Item."Default Deferral Template Code" := DeferralTemplate."Deferral Code";
        Item.Modify(true);
        // [GIVEN] A sales invoice line with deferral code DEF1
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.");
        PriceBeforeTax := Round(PurchaseLine."Unit Cost" * PurchaseLine.Quantity);
        // [GIVEN] A line level discount
        Discount := Round(0.1 * PriceBeforeTax);
        PurchaseLine.Validate("Line Discount Amount", Discount);
        PurchaseLine.Modify();
        // [WHEN] Posting the sales invoice
        PostingDate := PurchaseHeader."Posting Date";
        GLRegisterOfPostedDocument(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, false), PostingDate, GLRegister);
        // [THEN] The G/L Accounts affected by the posting with the date of the invoice (not deferred) are affected as expected.
        Tax := Round((PriceBeforeTax - Discount) * VATPostingSetup."VAT %" / 100);
        GLEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        GLEntry.SetRange("Posting Date", PostingDate);
        AssertBalanceInAccountOfFilteredGLEntries(-(PriceBeforeTax + Tax - Discount), GetAccountPayablesGLAccount(VendorNo), GLEntry, 'The account payable GL Account should have the total + tax - discount at the posting date');
        AssertBalanceInAccountOfFilteredGLEntries(-Discount, GetLineDiscountGLAccount(VendorNo, Item), GLEntry, 'The discount granted GL account should have the discount at posting date');
        AssertBalanceInAccountOfFilteredGLEntries(Discount, GetExpensesGLAccount(VendorNo, Item), GLEntry, 'The revenue GL account should only have the discount at posting date');
        AssertBalanceInAccountOfFilteredGLEntries(PriceBeforeTax - Discount, GetDeferralGLAccount(DeferralTemplate), GLEntry, 'The deferred revenue GL Account should have the total - discount (no tax) at the posting date');
        AssertBalanceInAccountOfFilteredGLEntries(Tax, GetUnrealizedVATGLAccount(VATPostingSetup), GLEntry, 'The unrealized VAT should have the VAT at the posting date (considering discount)');
        // [THEN] The G/L Accounts affected by the posting including deferrals are affected as expected.
        GLEntry.SetRange("Posting Date");
        AssertBalanceInAccountOfFilteredGLEntries(PriceBeforeTax, GetExpensesGLAccount(VendorNo, Item), GLEntry, 'Over all time, the revenue GL account should have the total (no tax or discount)');
        AssertBalanceInAccountOfFilteredGLEntries(0, GetDeferralGLAccount(DeferralTemplate), GLEntry, 'Over all time, the deferral GL Account should be zero', true);
    end;

    [Test]
    procedure GLEntriesRevertWithCreditMemoWhenPostingUnrealizedVATDeferralDiscountInvoice()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        DeferralTemplate: Record "Deferral Template";
        PurchaseInvoiceHeader: Record "Purch. Inv. Header";
        PurchaseHeader, CreditMemoPurchaseHeader : Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        InvoiceGLRegister, CreditMemoGLRegister : Record "G/L Register";
        GLEntry: Record "G/L Entry";
        PurchCalcDiscountByType: Codeunit "Purch - Calc Disc. By Type";
        CorrectPostedPurchaseInvoice: Codeunit "Correct Posted Purch. Invoice";
        VendorNo, GLAccountNo : Code[20];
        GLEntriesFilter: Text;
        PostingDate: Date;
        Discount: Decimal;
        GLAccountNos: List of [Code[20]];
        BalanceErr: Label 'The balance of %1 account from the past two postings should be zero', Locked = true;
    begin
        // [SCENARIO 548280] An invoice with header and line level discount and deferred revenue is posted in an unrealized VAT setup.
        // A corrective credit memo is then created and posted.

        // [GIVEN] GL Setup using unrealized VAT
        EnableUnrealizedSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::"Last (Fully Paid)");
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.SetDiscountPostingInPurchasePayablesSetup();
        // [GIVEN] A deferral over 2 periods DEF1
        LibraryERM.CreateDeferralTemplate(DeferralTemplate, DeferralTemplate."Calc. Method"::"Equal per Period", DeferralTemplate."Start Date"::"Beginning of Next Period", 2);
        // [GIVEN] A purchase invoice with header level discount
        VendorNo := CreateVendor(VATPostingSetup."VAT Bus. Posting Group");
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        Item.Get(CreateItem(VATPostingSetup."VAT Prod. Posting Group"));
        Item."Default Deferral Template Code" := DeferralTemplate."Deferral Code";
        Item.Modify(true);
        // [GIVEN] A purchase invoice line with deferral code DEF1
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.");
        // [GIVEN] A header level discount
        Discount := Round(0.1 * PurchaseLine."Unit Cost" * PurchaseLine.Quantity);
        PurchCalcDiscountByType.ApplyInvDiscBasedOnAmt(Discount, PurchaseHeader);
        // [WHEN] Posting the sales invoice
        PostingDate := PurchaseHeader."Posting Date";
        GLRegisterOfPostedDocument(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, false), PostingDate, InvoiceGLRegister);
        // [GIVEN] A credit memo is created from the posted sales invoice
        PurchaseInvoiceHeader.SetRange("Pay-to Vendor No.", VendorNo);
        PurchaseInvoiceHeader.FindLast();
        CorrectPostedPurchaseInvoice.CreateCreditMemoCopyDocument(PurchaseInvoiceHeader, CreditMemoPurchaseHeader);
        CreditMemoPurchaseHeader."Vendor Cr. Memo No." := 'VNDCM01';
        CreditMemoPurchaseHeader.Modify();
        // [WHEN] Posting the credit memo
        GLRegisterOfPostedDocument(LibraryPurchase.PostPurchaseDocument(CreditMemoPurchaseHeader, false, false), PostingDate, CreditMemoGLRegister);

        GLEntriesFilter := StrSubstNo('%1..%2|%3..%4', InvoiceGLRegister."From Entry No.", InvoiceGLRegister."To Entry No.", CreditMemoGLRegister."From Entry No.", CreditMemoGLRegister."To Entry No.");
        GLEntry.SetFilter("Entry No.", GLEntriesFilter);
        // [THEN] Balance of purchases accounts should be zero
        GetGeneralPostingSetup(VendorNo, Item, GeneralPostingSetup);
        GLEntry.SetFilter("G/L Account No.", '%1|%2', GeneralPostingSetup."Purch. Account", GeneralPostingSetup."Purch. Credit Memo Account");
        GLEntry.CalcSums(Amount);
        Assert.AreEqual(0, GLEntry.Amount, 'Balances in the purchase accounts should be zero.');
        // [THEN] All the balances of the rest of the accounts from the past two postings should be zero
        CollectGLAccountNosInGLEntries(GLEntriesFilter, GLAccountNos);
        foreach GLAccountNo in GLAccountNos do
            if (GLAccountNo <> GeneralPostingSetup."Purch. Account") and (GLAccountNo <> GeneralPostingSetup."Purch. Credit Memo Account") then begin
                GLEntry.SetRange("G/L Account No.", GLAccountNo);
                GLEntry.CalcSums(Amount);
                Assert.AreEqual(0, GLEntry.Amount, StrSubstNo(BalanceErr, GLAccountNo));
            end;
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Unrealized VAT Vendor");
        LibraryApplicationArea.EnableFoundationSetup();
        LibrarySetupStorage.Restore();
        // Lazy Setup.
        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Unrealized VAT Vendor");
        LibraryPurchase.SetInvoiceRounding(false);
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateAccountInVendorPostingGroups();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        isInitialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Unrealized VAT Vendor");
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

    local procedure EnableUnrealizedSetup(var VATPostingSetup: Record "VAT Posting Setup"; UnrealizedVATType: Option)
    begin
        EnableUnrealVATSetupWithGivenPct(
          VATPostingSetup, UnrealizedVATType, LibraryRandom.RandIntInRange(10, 30));
    end;

    local procedure EnableUnrealVATSetupWithGivenPct(var VATPostingSetup: Record "VAT Posting Setup"; UnrealizedVATType: Option; VATRate: Decimal)
    begin
        Initialize();
        LibraryERM.SetUnrealizedVAT(true);
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATRate);
        UpdateVATPostingSetup(VATPostingSetup, UnrealizedVATType);
    end;

    local procedure PerformScenarioTFS261852(var PurchaseHeader: Record "Purchase Header"; var InvoiceNo: Code[20]; VATPct: Decimal; ExchangeRate: Decimal; InvoiceAmount: Decimal; CrMemoAmount: Decimal; PaymentAmount: Decimal)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VendorNo: Code[20];
        GLAccountNo: Code[20];
        CurrencyCode: Code[10];
        PaymentNo: Code[20];
    begin
        EnableUnrealVATSetupWithGivenPct(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::Percentage, VATPct);
        VendorNo := LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group");
        GLAccountNo := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, "General Posting Type"::" ");
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), ExchangeRate, 1);

        InvoiceNo := CreatePostSalesInvoiceForGivenCustomer(VendorNo, GLAccountNo, CurrencyCode, InvoiceAmount);
        PaymentNo := CreateAndPostPaymentJnlLine(VendorNo, CurrencyCode, PaymentAmount);
        ApplyVendorPaymentToInvoice(InvoiceNo, PaymentNo);

        CreatePurchaseDocForGivenVendor(
          PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VendorNo, GLAccountNo, CurrencyCode, CrMemoAmount);
        SetAppliesToIDSalesDocumentToPostedInvoice(PurchaseHeader, InvoiceNo);
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

    local procedure GetAccountPayablesGLAccount(VendorNo: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        Vendor.Get(VendorNo);
        VendorPostingGroup.Get(Vendor."Vendor Posting Group");
        exit(VendorPostingGroup."Payables Account");
    end;

    local procedure GetHeaderDiscountGLAccount(VendorNo: Code[20]; Item: Record Item): Code[20]
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GetGeneralPostingSetup(VendorNo, Item, GeneralPostingSetup);
        exit(GeneralPostingSetup."Purch. Inv. Disc. Account");
    end;

    local procedure GetLineDiscountGLAccount(VendorNo: Code[20]; Item: Record Item): Code[20]
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GetGeneralPostingSetup(VendorNo, Item, GeneralPostingSetup);
        exit(GeneralPostingSetup."Purch. Line Disc. Account");
    end;

    local procedure GetExpensesGLAccount(VendorNo: Code[20]; Item: Record Item): Code[20]
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GetGeneralPostingSetup(VendorNo, Item, GeneralPostingSetup);
        exit(GeneralPostingSetup."Purch. Account");
    end;

    local procedure GetGeneralPostingSetup(VendorNo: Code[20]; Item: Record Item; var GeneralPostingSetup: Record "General Posting Setup")
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        GeneralPostingSetup.Get(Vendor."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group");
    end;

    local procedure GetDeferralGLAccount(DeferralTemplate: Record "Deferral Template"): Code[20]
    begin
        exit(DeferralTemplate."Deferral Account");
    end;

    local procedure GetUnrealizedVATGLAccount(VATPostingSetup: Record "VAT Posting Setup"): Code[20]
    begin
        exit(VATPostingSetup."Purch. VAT Unreal. Account");
    end;


    local procedure ApplyAndPostVendorEntry(DocumentNo: Code[20]; ApplyingDocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        ApplyingVendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Apply Payment Entry on Posted Invoice.
        LibraryERM.FindVendorLedgerEntry(ApplyingVendorLedgerEntry, DocumentType, ApplyingDocumentNo);
        ApplyingVendorLedgerEntry.CalcFields("Remaining Amount");
        LibraryERM.SetApplyVendorEntry(ApplyingVendorLedgerEntry, ApplyingVendorLedgerEntry."Remaining Amount");

        // Set Applies ID.
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry.SetRange(Open, true);
        VendorLedgerEntry.FindFirst();
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry);

        // Post Application Entries.
        LibraryERM.PostVendLedgerApplication(ApplyingVendorLedgerEntry);
    end;

    local procedure ApplyVendorLedgerEntriesByPage(VendorNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    var
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
    begin
        VendorLedgerEntries.OpenView();
        VendorLedgerEntries.FILTER.SetFilter("Vendor No.", VendorNo);
        VendorLedgerEntries.FILTER.SetFilter("Document Type", Format(DocumentType));
        VendorLedgerEntries.ActionApplyEntries.Invoke();
    end;

    local procedure ApplyVendorPaymentToInvoice(InvoiceDocNo: Code[20]; PaymentDocNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.ApplyVendorLedgerEntries(
          VendorLedgerEntry."Document Type"::Invoice, VendorLedgerEntry."Document Type"::Payment, InvoiceDocNo, PaymentDocNo);
    end;

    local procedure CreatePostPurchaseInvoiceWithNegativeLine(var PurchaseHeader: Record "Purchase Header"; VATPostingSetup: Record "VAT Posting Setup"; var VATBaseAmount: array[2] of Decimal; var VATAmount: array[2] of Decimal; AmountRoundingPrecision: Decimal): Code[20]
    var
        PurchaseLine: Record "Purchase Line";
    begin
        VATBaseAmount[1] := LibraryRandom.RandDecInRange(3000, 4000, 2);
        VATBaseAmount[2] := LibraryRandom.RandDecInRange(1000, 2000, 2);
        VATAmount[1] := Round(VATBaseAmount[1] * VATPostingSetup."VAT %" / 100, AmountRoundingPrecision);
        VATAmount[2] := Round(VATBaseAmount[2] * VATPostingSetup."VAT %" / 100, AmountRoundingPrecision);

        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateVendor(VATPostingSetup."VAT Bus. Posting Group"));
        CreatePurchaseLineWithGLAccount(PurchaseLine, PurchaseHeader, VATPostingSetup, 1, VATBaseAmount[1]);
        CreatePurchaseLineWithGLAccount(PurchaseLine, PurchaseHeader, VATPostingSetup, -1, VATBaseAmount[2]);

        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateAndPostPurchaseCreditMemo(PurchInvLine: Record "Purch. Inv. Line") DocumentNo: Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", PurchInvLine."Buy-from Vendor No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", PurchInvLine."No.", PurchInvLine.Quantity);
        PurchaseLine.Validate("Direct Unit Cost", PurchInvLine."Direct Unit Cost");
        PurchaseLine.Modify(true);
        UpdateVendorCreditMemoNo(PurchaseHeader);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; AccountNo: Code[20]; Amount: Decimal; PostingDaysAdded: Integer; CurrencyCode: Code[10])
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, DocumentType, GenJournalLine."Account Type"::Vendor, AccountNo, Amount);
        GenJournalLine.Validate("Posting Date", CalcDate('<' + Format(PostingDaysAdded) + 'M>', WorkDate()));
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);
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

    local procedure CreateVendor(VATBusPostingGroup: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
        PaymentTerms: Record "Payment Terms";
        PaymentMethod: Record "Payment Method";
    begin
        // Create new Vendor and Update VAT Bus. Posting Group.
        LibraryERM.FindPaymentMethod(PaymentMethod);
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Vendor.Validate("Payment Terms Code", PaymentTerms.Code);
        Vendor.Validate("Payment Method Code", PaymentMethod.Code);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateVendorWithPaymentTerms(VATBusPostingGroup: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Vendor.Validate("Payment Terms Code", CreatePaymentTermsWithDiscount());
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateVendorWithCurrency(VATBusPostingGroup: Code[20]; CurrencyCode: Code[10]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATBusPostingGroup));
        Vendor.Validate("Currency Code", CurrencyCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreatePaymentTermsWithDiscount(): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        // Input any random Due Date and Discount Date Calculation and Discount %.
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        Evaluate(PaymentTerms."Due Date Calculation", '<' + Format(LibraryRandom.RandInt(10)) + 'M>');
        Evaluate(PaymentTerms."Discount Date Calculation", '<' + Format(LibraryRandom.RandInt(10)) + 'D>');
        PaymentTerms.Validate("Due Date Calculation", PaymentTerms."Due Date Calculation");
        PaymentTerms.Validate("Discount Date Calculation", PaymentTerms."Discount Date Calculation");
        PaymentTerms.Validate("Discount %", LibraryRandom.RandDec(10, 2));
        PaymentTerms.Validate("Calc. Pmt. Disc. on Cr. Memos", true);
        PaymentTerms.Modify(true);
        exit(PaymentTerms.Code);
    end;

    local procedure CreatePurchaseCreditMemo(var PurchaseHeader: Record "Purchase Header"; VATPostingSetup: Record "VAT Posting Setup")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo",
          CreateVendorWithPaymentTerms(VATPostingSetup."VAT Bus. Posting Group"));
        UpdateVendorCreditMemoNo(PurchaseHeader);
        CreatePurchaseLine(PurchaseHeader, PurchaseLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"));
    end;

    local procedure CreatePurchaseInvoiceWithGL(var PurchaseHeader: Record "Purchase Header"; VATPostingSetup: Record "VAT Posting Setup")
    var
        GLAccount: Record "G/L Account";
        PurchaseLine: Record "Purchase Line";
        GLAccountNo: Code[20];
    begin
        CreatePurchaseInvoice(PurchaseHeader, VATPostingSetup);
        GLAccountNo := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase);
        CreatePurchaseLine(PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccountNo);
    end;

    local procedure CreatePurchaseInvoice(var PurchaseHeader: Record "Purchase Header"; VATPostingSetup: Record "VAT Posting Setup")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateVendor(VATPostingSetup."VAT Bus. Posting Group"));
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        CreatePurchaseLine(
          PurchaseHeader, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, "General Posting Type"::" "));
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; Type: Enum "Purchase Line Type"; No: Code[20])
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, LibraryRandom.RandDec(10, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));  // Use Random Unit Price between 1 and 100.
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseLine(PurchaseHeader: Record "Purchase Header"; Type: Enum "Purchase Line Type"; No: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No);
    end;

    local procedure CreatePurchaseLineWithGLAccount(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; VATPostingSetup: Record "VAT Posting Setup"; Quantity: Decimal; DirectUnitCost: Decimal)
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase), Quantity);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify();
    end;

    local procedure CreateAndPostCreditMemo(PostedInvoiceNo: Code[20]; VendorNo: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VendorNo);
        UpdateVendorCreditMemoNo(PurchaseHeader);
        RunCopyPurchaseDocument(PurchaseHeader, PostedInvoiceNo);
        RemoveAppliestoDocument(PurchaseHeader."Document Type"::"Credit Memo", PurchaseHeader."No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, false);
        ExecuteUIHandler();
        exit(PurchaseHeader."No.");
    end;

    local procedure CreateAndPostGeneralJournaLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; AccountNo: Code[20]; Amount: Decimal; PostingDaysAdded: Integer; CurrencyCode: Code[10])
    begin
        CreateGeneralJournalLine(GenJournalLine, DocumentType, AccountNo, Amount, PostingDaysAdded, CurrencyCode);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostPaymentJnlLine(VendorNo: Code[20]; CurrencyCode: Code[10]; LineAmount: Decimal): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateAndPostGeneralJournaLine(GenJournalLine, GenJournalLine."Document Type"::Payment, VendorNo, LineAmount, 0, CurrencyCode);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreateApplyAndPostPayment(VendorNo: Code[20]; AppliesToInvoiceNo: Code[20]; PmtAmount: Decimal): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, VendorNo, PmtAmount);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToInvoiceNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreatePostSalesInvoiceForGivenCustomer(VendorNo: Code[20]; GLAccountNo: Code[20]; CurrencyCode: Code[10]; DirectUnitCost: Decimal): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseDocForGivenVendor(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo, GLAccountNo, CurrencyCode, DirectUnitCost);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreatePurchaseDocForGivenVendor(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; GLAccountNo: Code[20]; CurrencyCode: Code[10]; UnitPrice: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccountNo, 1);
        PurchaseLine.Validate("Direct Unit Cost", UnitPrice);
        PurchaseLine.Modify(true);
    end;

    local procedure SetAppliesToIDSalesDocumentToPostedInvoice(var PurchaseHeader: Record "Purchase Header"; InvoiceNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        PurchaseHeader.Validate("Applies-to ID", UserId);
        PurchaseHeader.Modify(true);

        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, InvoiceNo);
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry);
    end;

    local procedure CalculateInvoiceAmount(DocumentNo: Code[20]) Amount: Decimal
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        PurchInvLine.SetRange("Document No.", DocumentNo);
        PurchInvLine.FindSet();
        repeat
            Amount += PurchInvLine.Amount;
        until PurchInvLine.Next() = 0;
    end;

    local procedure FilterVATEntry(var VATEntry: Record "VAT Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; AmountFilter: Text)
    begin
        VATEntry.SetRange(Type, VATEntry.Type::Purchase);
        VATEntry.SetRange("Document Type", DocumentType);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetFilter(Amount, AmountFilter)
    end;

    local procedure FindPostedInvoiceNo(PreAssignedNo: Code[20]): Code[20]
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.SetRange("Pre-Assigned No.", PreAssignedNo);
        PurchInvHeader.FindFirst();
        exit(PurchInvHeader."No.");
    end;

    local procedure FindPostedCreditMemoNo(PreAssignedNo: Code[20]): Code[20]
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        PurchCrMemoHdr.SetRange("Pre-Assigned No.", PreAssignedNo);
        PurchCrMemoHdr.FindFirst();
        exit(PurchCrMemoHdr."No.");
    end;

    local procedure FindPurchaseInvoiceLine(var PurchInvLine: Record "Purch. Inv. Line"; PreAssignedNo: Code[20])
    begin
        PurchInvLine.SetRange("Document No.", FindPostedInvoiceNo(PreAssignedNo));
        PurchInvLine.FindFirst();
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

    local procedure ModifyItemNoSeries()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.Validate("Item Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        InventorySetup.Modify(true);
    end;

    local procedure RunCopyPurchaseDocument(PurchaseHeader: Record "Purchase Header"; DocumentNo: Code[20])
    var
        CopyPurchaseDocument: Report "Copy Purchase Document";
    begin
        Clear(CopyPurchaseDocument);
        CopyPurchaseDocument.SetPurchHeader(PurchaseHeader);
        CopyPurchaseDocument.SetParameters("Purchase Document Type From"::"Posted Invoice", DocumentNo, true, false);
        CopyPurchaseDocument.UseRequestPage(false);
        CopyPurchaseDocument.Run();
    end;

    local procedure RemoveAppliestoDocument(DocumentType: Enum "Purchase Document Type"; No: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Get(DocumentType, No);
        PurchaseHeader.Validate("Applies-to Doc. Type", PurchaseHeader."Applies-to Doc. Type"::" ");
        PurchaseHeader.Validate("Applies-to Doc. No.", '');
        PurchaseHeader.Modify(true);
    end;

    local procedure UpdateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; UnrealizedVATType: Option)
    begin
        VATPostingSetup.Validate("Unrealized VAT Type", UnrealizedVATType);
        VATPostingSetup.Validate("Purch. VAT Unreal. Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);
    end;

    local procedure UpdateVendorCreditMemoNo(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
    end;

    local procedure VerifyPurchaseCreditMemoHeader(DocumentNo: Code[20]; BuyfromVendorNo: Code[20])
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        PurchCrMemoHdr.SetRange("No.", DocumentNo);
        PurchCrMemoHdr.SetRange("Buy-from Vendor No.", BuyfromVendorNo);
        PurchCrMemoHdr.FindFirst();
    end;

    local procedure VerifyUnrealizedVATEntry(GenJournalLine: Record "Gen. Journal Line"; VATPostingSetup: Record "VAT Posting Setup")
    var
        VATEntry: Record "VAT Entry";
        GLEntry: Record "G/L Entry";
        UnrealizedVATAmount: Decimal;
    begin
        // Verify General Ledger Register for Unrealized VAT Entry.
        GLEntry.SetRange("Document No.", GenJournalLine."Document No.");
        GLEntry.SetRange("Bal. Account No.", VATPostingSetup."Purch. VAT Unreal. Account");
        GLEntry.FindLast();
        UnrealizedVATAmount := LibraryERM.VATAmountRounding(GenJournalLine."Amount (LCY)" * VATPostingSetup."VAT %" / (100 + VATPostingSetup."VAT %"), GenJournalLine."Currency Code");
        Assert.AreNearlyEqual(UnrealizedVATAmount, GLEntry.Amount, LibraryERM.GetAmountRoundingPrecision(), GLEntry.FieldCaption(Amount));

        FindLastVATEntry(VATEntry, GLEntry."Document No.");
        Assert.AreEqual(VATEntry."VAT Reporting Date", GLEntry."VAT Reporting Date", 'VATEntry and GLEntry should have the same VAT Date');
        Assert.AreNotEqual(VATEntry."VAT Reporting Date", '', 'VAT Reporting Date in VATEntry is Empty');
    end;

    local procedure VerifyUnrealizedVATEntryIsRealized(PmtDocumentNo: Code[20]; UnrealizedTransactionNo: Integer; RealizedTransactionNo: Integer)
    var
        VATEntry: Record "VAT Entry";
        UnrealVATEntry: Record "VAT Entry";
    begin
        FindLastVATEntry(VATEntry, PmtDocumentNo);
        VATEntry.TestField("Unrealized VAT Entry No.");
        VATEntry.TestField("Transaction No.", RealizedTransactionNo);
        VATEntry.TestField("G/L Acc. No.", '');

        UnrealVATEntry.Get(VATEntry."Unrealized VAT Entry No.");
        UnrealVATEntry.TestField("Transaction No.", UnrealizedTransactionNo);
        Assert.AreEqual(0, UnrealVATEntry."Remaining Unrealized Base", UnrealVATEntry.FieldName("Remaining Unrealized Base"));
        Assert.AreEqual(0, UnrealVATEntry."Remaining Unrealized Amount", UnrealVATEntry.FieldName("Remaining Unrealized Amount"));
    end;

    local procedure VerifyGLEntryForFullyPaid(BalAccountNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Bal. Account No.", BalAccountNo);
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, -Amount);
    end;

    local procedure VerifyGLEntry(GLAccountNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(Amount, GLEntry.Amount, LibraryERM.GetAmountRoundingPrecision(), GLEntry.FieldCaption(Amount));

        Assert.AreNotEqual(GLEntry."VAT Reporting Date", '', 'VAT Reporting Date in GLEntry is Empty');
    end;

    local procedure VerifyVendorLedgerEntry(VendorNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.FindSet();
        repeat
            VendorLedgerEntry.CalcFields("Remaining Amount");
            VendorLedgerEntry.TestField("Remaining Amount", 0);
        until VendorLedgerEntry.Next() = 0;
    end;

    local procedure VerifyVendorLedgerEntryAmounts(VendorNo: Code[20]; DocumentNo: Code[20]; ExpectedAmount: Decimal; ExpectedRemAmount: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.CalcFields(Amount, "Remaining Amount");
        Assert.AreEqual(ExpectedAmount, VendorLedgerEntry.Amount, VendorLedgerEntry.FieldCaption(Amount));
        Assert.AreEqual(ExpectedRemAmount, VendorLedgerEntry."Remaining Amount", VendorLedgerEntry.FieldCaption("Remaining Amount"));
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

    local procedure VerifyThreeUnrealizedVATEntry(var VATEntryNo: array[3] of Integer; CVNo: Code[20]; InvoiceNo: Code[20]; PurchaseLine: array[3] of Record "Purchase Line")
    var
        VATEntry: Record "VAT Entry";
        i: Integer;
    begin
        VATEntry.SetRange(Type, VATEntry.Type::Purchase);
        VATEntry.SetRange("Bill-to/Pay-to No.", CVNo);
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Invoice);
        VATEntry.SetRange("Document No.", InvoiceNo);
        VATEntry.FindSet();
        for i := ArrayLen(PurchaseLine) downto 1 do begin
            VerifyUnrealizedVATEntryAmounts(
              VATEntry, PurchaseLine[i].Amount, PurchaseLine[i]."Amount Including VAT" - PurchaseLine[i].Amount, 0, 0);
            VATEntryNo[ArrayLen(PurchaseLine) - i + 1] := VATEntry."Entry No.";
            VATEntry.Next();
        end;
    end;

    local procedure VerifyThreeRealizedVATEntry(UnrealVATEntryNo: array[3] of Integer; CVNo: Code[20]; PaymentNo: Code[20]; PurchaseLine: array[3] of Record "Purchase Line"; VATPart: Decimal)
    var
        VATEntry: Record "VAT Entry";
        i: Integer;
    begin
        VATEntry.SetRange(Type, VATEntry.Type::Purchase);
        VATEntry.SetRange("Bill-to/Pay-to No.", CVNo);
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Payment);
        VATEntry.SetRange("Document No.", PaymentNo);
        VATEntry.FindSet();
        for i := ArrayLen(PurchaseLine) downto 1 do begin
            Assert.AreEqual(
              UnrealVATEntryNo[ArrayLen(PurchaseLine) - i + 1],
              VATEntry."Unrealized VAT Entry No.",
              VATEntry.FieldCaption("Unrealized VAT Entry No."));
            VerifyRealizedVATEntryAmounts(
              VATEntry,
              PurchaseLine[i].Amount * VATPart,
              (PurchaseLine[i]."Amount Including VAT" - PurchaseLine[i].Amount) * VATPart);
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
        CrMemoVATEntry.TestField("Unrealized Base", -UnrealBase);
        CrMemoVATEntry.TestField("Unrealized Amount", -UnrealAmount);
        CrMemoVATEntry.TestField("Remaining Unrealized Base", -UnrealBase + RealBase);
        CrMemoVATEntry.TestField("Remaining Unrealized Amount", -UnrealAmount + RealAmount);

        FindNegativeRealVATEntry(CrMemoVATEntry, CrMemoVATEntry."Document Type"::"Credit Memo", CrMemoNo);
        CrMemoVATEntry.TestField(Base, -RealBase);
        CrMemoVATEntry.TestField(Amount, -RealAmount);

        FindPositiveRealVATEntry(CrMemoVATEntry, CrMemoVATEntry."Document Type"::"Credit Memo", CrMemoNo);
        CrMemoVATEntry.TestField(Base, RealBase);
        CrMemoVATEntry.TestField(Amount, RealAmount);
        CrMemoVATEntry.TestField("Unrealized VAT Entry No.", InvoiceVATEntry."Entry No.");
    end;

    local procedure VerifyUnrealizedGainLossesGLEntries(CurrencyCode: Code[10]; PaymentNo: Code[20]; GainLossAmt: Decimal)
    var
        GLEntry: Record "G/L Entry";
        Currency: Record Currency;
    begin
        Currency.Get(CurrencyCode);
        GLEntry.SetRange("G/L Account No.", Currency."Unrealized Losses Acc.");
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, GainLossAmt);
        GLEntry.SetRange("Document No.", PaymentNo);
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, -GainLossAmt);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyVendorEntriesHandler(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    begin
        ApplyVendorEntries.ActionSetAppliesToID.Invoke();
        ApplyVendorEntries.ActionPostApplication.Invoke();
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

    local procedure ExecuteUIHandler()
    begin
        // Generate Dummy message. Required for executing the test case successfully.
        if Confirm(StrSubstNo(CrMemoCorrInvNoQst)) then;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

