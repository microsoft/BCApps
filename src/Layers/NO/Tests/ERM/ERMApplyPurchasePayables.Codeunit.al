codeunit 134001 "ERM Apply Purchase/Payables"
{
    Permissions = TableData "Vendor Ledger Entry" = rimd;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Purchase]
        isInitialized := false;
    end;

    var
        PmtTerms: Record "Payment Terms";
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        InvoiceError: Label 'Invoice did not close.';
        InternalError: Label 'Internal error: %1 did not add up to full amount.';
        AmountErr: Label 'ENU=%1 and %2 must be same.', Comment = '%1 = PmtDiscountAmount,%2 = VendorLedgerEntry."Original Pmt. Disc. Possible"';
        AppliesToIDIsNotEmptyOnLedgEntryErr: Label 'Applies-to ID is not empty in %1.';
        AmountToApplyErr: Label '"Amount to Apply" should be zero.';
        WrongValErr: Label '%1 must be %2 in %3.';
        DialogTxt: Label 'Dialog';
        DimensionUsedErr: Label 'A dimension used in %1 %2, %3, %4 has caused an error.';
        VATPostingSetupErr: Label 'No VAT Posting Setup found with VAT Code for Purchase.';
        EarlierPostingDateErr: Label 'You cannot apply and post an entry to an entry with an earlier posting date.';
        DifferentCurrenciesErr: Label 'All entries in one application must be in the same currency.';
        SourceCurrAmtErr: Label '%1 must be %2 in %3', Comment = '%1 = Source Currency Amount, %2 = Amount, %3 = G/L Entry';
        ClosedAtDateErr: Label 'Closed at Date must have value.';

    [Test]
    [Scope('OnPrem')]
    procedure VendorApplyLCYTest()
    begin
        Initialize();

        // We don't need to know what LCY currency is, it suffices to post with blank currency code.
        // Invoice and Payment in LCY, Pay 100% of invoice in 1 payment 0 days after invoice date.
        TestApplication('', '', 1.0, 1, 1, '<0D>', false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorApplyFCYTestInvAndPmtCurrencyBlank()
    var
        FCY1: Code[10];
        FCY2: Code[10];
    begin
        Initialize();

        FCY1 := RandomCurrency();
        FCY2 := FCY1;
        while FCY2 = FCY1 do
            FCY2 := RandomCurrency();

        TestApplication('', '', 1.0, 1, 1, '<0D>', false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorApplyFCYTestPmtCurrencyBlank()
    var
        VendorLedgerEntries: Record "Vendor Ledger Entry";
        FCY1: Code[10];
        FCY2: Code[10];
    begin
        VendorLedgerEntries.DeleteAll(false);
        Initialize();

        FCY1 := RandomCurrency();
        FCY2 := FCY1;
        while FCY2 = FCY1 do
            FCY2 := RandomCurrency();

        TestApplication(FCY1, '', 1.0, 1, 1, '<0D>', false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorApplyFCYTestInvCurrencyBlank()
    var
        FCY1: Code[10];
        FCY2: Code[10];
    begin
        Initialize();

        FCY1 := RandomCurrency();
        FCY2 := FCY1;
        while FCY2 = FCY1 do
            FCY2 := RandomCurrency();

        TestApplication('', FCY1, 1.0, 1, 1, '<0D>', false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorApplyFCYTestSameCurrency()
    var
        FCY1: Code[10];
        FCY2: Code[10];
    begin
        Initialize();

        FCY1 := RandomCurrency();
        FCY2 := FCY1;
        while FCY2 = FCY1 do
            FCY2 := RandomCurrency();

        TestApplication(FCY1, FCY1, 1.0, 1, 1, '<0D>', false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorApplyFCYTestDifferentCurrency()
    var
        FCY1: Code[10];
        FCY2: Code[10];
    begin
        Initialize();

        FCY1 := RandomCurrency();
        FCY2 := FCY1;
        while FCY2 = FCY1 do
            FCY2 := RandomCurrency();

        TestApplication(FCY2, FCY1, 1.0, 1, 1, '<0D>', false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorApplyLastDueDateTest()
    begin
        Initialize();

        // Check boundary case when payment is at last day for discount to apply.
        TestApplication('', '', 1.0, 1, 1, Format(PmtTerms."Discount Date Calculation"), false);

        // Check boundary case when payment is just after the last day for discount to apply.
        TestApplication('', '', 1.0, 1, 1, Format(PmtTerms."Discount Date Calculation") + '+<1D>', false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorApplyOverPmtTest()
    begin
        Initialize();

        // Check over payment (110% here).
        TestApplication('', '', 1.1, 1, 1, '<0D>', false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorApplyUnderPmtTest()
    begin
        Initialize();

        // Check under payment (90% here). Invoice should not close.
        asserterror TestApplication('', '', 0.9, 1, 1, '<0D>', false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorApplyMultiPmtTest()
    begin
        Initialize();

        // Check multi payment (4 payments).
        TestApplication('', '', 1.0, 1, 4, '<0D>', false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorApplyMultiInvTest()
    begin
        Initialize();

        // Check multi invoice (4 invoices).
        TestApplication('', '', 1.0, 4, 1, '<0D>', false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorApplyStepWiseInvTest()
    begin
        Initialize();

        // Check multi invoice with step-wise posting (4 invoices).
        TestApplication('', '', 1.0, 4, 1, '<0D>', true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorApplyMultiInvPmtTest()
    begin
        Initialize();

        // Check multi invoice and payment (4 each).
        TestApplication('', '', 1.0, 4, 4, '<0D>', false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorApplyFuzzyTest()
    var
        i: Integer;
    begin
        Initialize();

        // Fuzzy testing on discount percentage, currency and number of payments.
        for i := 1 to 10 do begin
            ReplacePaymentTerms(PmtTerms, 'NEW', '<1M>', '<8D>', LibraryRandom.RandInt(200) / 10);
            FuzzyTestApplication(LibraryRandom.RandInt(4), LibraryRandom.RandInt(4));
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorApplyBoundaryTest()
    var
        Vendor: Record Vendor;
        InvVendorLedgerEntry: Record "Vendor Ledger Entry";
        PmtVendorLedgerEntry: Record "Vendor Ledger Entry";
        PaymentTerms: Record "Payment Terms";
        CurrencyCode: Code[10];
        VendorNo: Code[20];
        Amount: Decimal;
        AmountLCY: Decimal;
    begin
        // This is a bug repro test case, it tests for a rounding issue in multi currency apply
        // Test for W1 regression of PS bug #44288.

        Initialize();

        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);

        VendorNo := CreateVendorWithPaymentTerms(PaymentTerms);
        SetApplicationMethodOnVendor(VendorNo, Vendor."Application Method"::Manual);

        CurrencyCode := RandomCurrency();
        Amount := LibraryRandom.RandDec(200, 2);
        CreateVendorInvoice(InvVendorLedgerEntry, VendorNo, -Amount, '');
        AmountLCY := LibraryERM.ConvertCurrency(Amount, '', CurrencyCode, WorkDate());
        CreateVendorPayment(PmtVendorLedgerEntry, VendorNo, AmountLCY, CurrencyCode, '<0D>');
        SetupApplyingEntry(PmtVendorLedgerEntry, PmtVendorLedgerEntry.Amount);
        SetupApplyEntry(InvVendorLedgerEntry);
        CODEUNIT.Run(CODEUNIT::"VendEntry-Apply Posted Entries", PmtVendorLedgerEntry);

        // Validation.
        ValidateVendLedgEntrClosed(InvVendorLedgerEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntriesOnPostedPurchaseInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Test G/L Entries and Remaining Amount on Vendor Ledger Entry after Posting of Purchase Invoice.
        TestRemainingAmountOnVendorLedgerEntry(PurchaseHeader."Document Type"::Invoice, 1, -1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntriesOnPostedPurchaseCreditMemo()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Test G/L Entries and Remaining Amount on Vendor Ledger Entry after Posting of Purchase Credit Memo.
        TestRemainingAmountOnVendorLedgerEntry(PurchaseHeader."Document Type"::"Credit Memo", -1, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntriesOnPostedGeneralJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Test G/L Entries on Posted General Journal.
        // Setup: Create and Post General Journal Line.
        Initialize();
        CreateAndPostGenJournalLine(GenJournalLine, CreateVendor(), LibraryRandom.RandDec(1000, 2));

        // Verify: Verify G/L Entries.
        VerifyGLEntry(GenJournalLine."Document Type"::Payment, GenJournalLine."Document No.", -1 * GenJournalLine."Amount (LCY)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyAndPostApplicationOnVendorLedgerEntry()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        InvAmountIncludingVAT: Decimal;
        RemainingPmtDiscPossible: Decimal;
        Quantity: Decimal;
    begin
        // Test when apply Remaining Amount fully when Amount to Apply is reduced to the extent of payment discount in the Invoice and with Credit Memo.
        // Setup: Create and Post Purchase Invoice,Purchase Credit Memo and General Journal.
        Initialize();
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndPostPurchaseDocument(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice, CreateVendor(), CreateItem(),
          LibraryRandom.RandDecInDecimalRange(100, 500, 2), Quantity);
        InvAmountIncludingVAT := PurchaseLine."Amount Including VAT";
        RemainingPmtDiscPossible := (PurchaseLine."Amount Including VAT" * PurchaseHeader."Payment Discount %") / 100;

        CreateAndPostPurchaseDocument(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Credit Memo", PurchaseHeader."Buy-from Vendor No.",
          PurchaseLine."No.", LibraryRandom.RandDec(100, 2), Quantity);
        CreateAndPostGenJournalLine(
          GenJournalLine, PurchaseLine."Buy-from Vendor No.",
          InvAmountIncludingVAT - PurchaseLine."Amount Including VAT" - RemainingPmtDiscPossible);

        // Excercise: Apply Vendor ledger Entries.
        ApplyAndPostVendorEntry(GenJournalLine."Document Type", GenJournalLine."Document No.");

        // Verify: Verify G/L and Vendor Ledger Entries.
        VerifyVendorLedgerEntry(GenJournalLine."Account No.", 0); // Remaining Amount should be Zero in all Lines.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckDiscountValueWithPmtDiscExcVatWithBalAccTypeVAT()
    begin
        // To verify that program calculate correct payment discount value in Vendor ledger entry when Pmt. Disc. Excl. VAT is true while Bal Account Type having VAT.
        Initialize();
        LibraryLowerPermissions.SetAccountPayables();
        LibraryLowerPermissions.AddO365Setup();
        CreateAndPostGenJournalLineWithPmtDiscExclVAT(true, CreateGLAccountWithVAT());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckDiscountValueWithPmtDiscExclVATWithOutBalAccTypeVAT()
    begin
        // To verify that program calculate correct payment discount value in Vendor ledger entry when Pmt. Disc. Excl. VAT is true while Bal Account Type does not having VAT.
        Initialize();
        LibraryLowerPermissions.SetAccountPayables();
        LibraryLowerPermissions.AddO365Setup();
        CreateAndPostGenJournalLineWithPmtDiscExclVAT(true, LibraryERM.CreateGLAccountNo());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckDiscountValueWithOutPmtDiscExcVatWithBalAccTypeVAT()
    begin
        // To verify that program calculate correct payment discount value in Vendor ledger entry when Pmt. Disc. Excl. VAT is false while Bal Account Type having VAT.
        Initialize();
        LibraryLowerPermissions.SetAccountPayables();
        LibraryLowerPermissions.AddO365Setup();
        CreateAndPostGenJournalLineWithPmtDiscExclVAT(false, CreateGLAccountWithVAT());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckDiscountValueWithOutPmtDiscExcVatWithOutBalAccTypeVAT()
    begin
        // To verify that program calculate correct payment discount value in Vendor ledger entry when Pmt. Disc. Excl. VAT is false while Bal Account Type does not having VAT.
        Initialize();
        LibraryLowerPermissions.SetAccountPayables();
        LibraryLowerPermissions.AddO365Setup();
        CreateAndPostGenJournalLineWithPmtDiscExclVAT(false, LibraryERM.CreateGLAccountNo());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckDiscountValueWithPmtDiscExcVatWithBalVATAmount()
    var
        PaymentTerms: Record "Payment Terms";
        GenJournalLine: Record "Gen. Journal Line";
        LibraryPmtDiscSetup: Codeunit "Library - Pmt Disc Setup";
        Amount: Decimal;
    begin
        // To verify that program calculate correct payment discount value in Vendor ledger entry when Pmt. Disc. Excl. VAT is true while Bal. VAT Amount (LCY) not equal to zero.

        // Setup: Update Pmt. Disc. Excl. VAT in General Ledger & Create Vendor with Payment Terms & Create Gen. Journal Line.
        Initialize();
        LibraryLowerPermissions.SetAccountPayables();
        LibraryLowerPermissions.AddO365Setup();
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(false);
        LibraryPmtDiscSetup.SetPmtDiscExclVAT(true);

        // Exercise: Create - Post Gen. Journal Line.
        CreatePostGenJnlLineWithBalAccount(GenJournalLine, GetVendorWithPaymentTerms(PaymentTerms));

        // Verify: Verifying Vendor Ledger Entry.
        Amount :=
          Round(GenJournalLine."Bal. VAT Amount (LCY)" * PaymentTerms."Discount %" / 100) -
          Round(GenJournalLine."Amount (LCY)" * PaymentTerms."Discount %" / 100);
        VerifyDiscountValueInVendorLedger(GenJournalLine, -Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ClearAppliesToIDFromVendLedgEntryWhenChangeValueOnGenJnlLine()
    var
        GenJnlLine: Record "Gen. Journal Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        // [SCENARIO 118226] Applies-to ID is cleared from Vendor Ledger Entry when change value of General Journal Line

        // [GIVEN] Vendor Ledger Entry and General Journal Line with the same Applies-to ID
        Initialize();
        LibraryLowerPermissions.SetAccountPayables();
        LibraryLowerPermissions.AddO365Setup();
        FindOpenInvVendLedgEntry(VendLedgEntry);
        SetAppliesToIDOnVendLedgEntry(VendLedgEntry);
        CreateGenJnlLineWithAppliesToID(
          GenJnlLine, GenJnlLine."Account Type"::Vendor, VendLedgEntry."Vendor No.", VendLedgEntry."Applies-to ID");

        // [WHEN] Change "Applies-to ID" in General Journal Line
        LibraryLowerPermissions.SetAccountPayables();
        GenJnlLine.Validate("Applies-to ID", LibraryUtility.GenerateGUID());
        GenJnlLine.Modify(true);

        // [THEN] "Applies-to ID" in Vendor Ledger Entry is empty
        VendLedgEntry.Find();
        Assert.AreEqual('', VendLedgEntry."Applies-to ID", StrSubstNo(AppliesToIDIsNotEmptyOnLedgEntryErr, VendLedgEntry.TableCaption()));
        Assert.AreEqual(0, VendLedgEntry."Amount to Apply", AmountToApplyErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ClearAppliesToIDFromVendLedgEntryWhenDeleteGenJnlLine()
    var
        GenJnlLine: Record "Gen. Journal Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        // [SCENARIO 118226] Applies-to ID is cleared from Vendor Ledger Entry when delete General Journal Line

        // [GIVEN] Vendor Ledger Entry and General Journal Line with the same Applies-to ID
        Initialize();
        FindOpenInvVendLedgEntry(VendLedgEntry);
        SetAppliesToIDOnVendLedgEntry(VendLedgEntry);
        CreateGenJnlLineWithAppliesToID(
          GenJnlLine, GenJnlLine."Account Type"::Vendor, VendLedgEntry."Vendor No.", VendLedgEntry."Applies-to ID");

        // [WHEN] Delete General Journal Line
        LibraryLowerPermissions.SetAccountPayables();
        GenJnlLine.Delete(true);

        // [THEN] "Applies-to ID" in Vendor Ledger Entry is empty
        VendLedgEntry.Find();
        Assert.AreEqual('', VendLedgEntry."Applies-to ID", StrSubstNo(AppliesToIDIsNotEmptyOnLedgEntryErr, VendLedgEntry.TableCaption()));
        Assert.AreEqual(0, VendLedgEntry."Amount to Apply", AmountToApplyErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ClearAppliesToDocNoValueFromGenJnlLine()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 120733] Vendor Ledger Entry "Amount-to Apply" = 0 when blank "Applies-to Doc. No." field in General Journal Line
        Initialize();

        // [GIVEN] Vendor Ledger Entry and General Journal Line with "Applies-to Doc. No"
        FindOpenInvVendLedgEntry(VendLedgEntry);
        CreateGenJnlLineWithAppliesToDocNo(
          GenJnlLine, GenJnlLine."Account Type"::Vendor, VendLedgEntry."Vendor No.", VendLedgEntry."Document No.");

        // [WHEN] Blank "Applies-to Doc. No." field in General Journal Line
        LibraryLowerPermissions.SetAccountPayables();
        GenJnlLine.Validate("Applies-to Doc. No.", '');
        GenJnlLine.Modify(true);

        // [THEN] Vendor Ledger Entry "Amount to Apply" = 0
        VendLedgEntry.Find();
        Assert.AreEqual(0, VendLedgEntry."Amount to Apply", AmountToApplyErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteGenJnlLineWithAppliesToDocNo()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 120733] Vendor Ledger Entry "Amount-to Apply" = 0 when delete General Journal Line with "Applies-to Doc. No."
        Initialize();
        // [GIVEN] Vendor Ledger Entry and General Journal Line with "Applies-to Doc. No"
        FindOpenInvVendLedgEntry(VendLedgEntry);
        CreateGenJnlLineWithAppliesToDocNo(
          GenJnlLine, GenJnlLine."Account Type"::Vendor, VendLedgEntry."Vendor No.", VendLedgEntry."Document No.");

        // [WHEN] Delete General Journal Line
        LibraryLowerPermissions.SetAccountPayables();
        GenJnlLine.Validate("Applies-to Doc. No.", '');
        GenJnlLine.Modify(true);

        // [THEN] Vendor Ledger Entry "Amount to Apply" = 0
        VendLedgEntry.Find();
        Assert.AreEqual(0, VendLedgEntry."Amount to Apply", AmountToApplyErr);
    end;

    [Test]
    [HandlerFunctions('GeneralJournalTemplateListPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyAmountApplToExtDocNoWhenSetValue()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentJournal: TestPage "Payment Journal";
        PostedDocNo: Code[20];
        ExpectedExtDocNo: Code[35];
    begin
        // [FEATURE] [Application] [Cash Receipt]
        // [SCENARIO 363069] Verify that External Doc No transferred when setting 'Applies-to Doc. No.' value in Payment Journal.

        // [GIVEN] Create invoice from vendor ('External Document No.' non-empty).
        Initialize();
        PostInvoice(GenJournalLine);
        ExpectedExtDocNo := GenJournalLine."External Document No.";
        PostedDocNo := GenJournalLine."Document No.";

        // [GIVEN] Create Payment Journal Line for the vendor.
        CreatePaymentJnlLine(GenJournalLine, GenJournalLine."Account No.");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        Commit();

        LibraryLowerPermissions.SetAccountPayables();
        PaymentJournal.OpenEdit();
        PaymentJournal."Applies-to Doc. Type".SetValue(GenJournalLine."Applies-to Doc. Type"::Invoice);

        // [WHEN] Set 'Applies-to Doc. No.' manually to Posted Invoice doc. no.
        PaymentJournal.AppliesToDocNo.SetValue(PostedDocNo);
        PaymentJournal.OK().Invoke();

        // [THEN] External doc. no. transferred to 'Applied-to Ext. Doc. No.', but Amount is not.
        VerifyExtDocNoAmount(GenJournalLine, ExpectedExtDocNo, 0);
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesModalPageHandler,GeneralJournalTemplateListPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyAmountApplToExtDocNoWhenLookUp()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentJournal: TestPage "Payment Journal";
        ExpectedExtDocNo: Code[35];
        ExpectedAmount: Decimal;
    begin
        // [FEATURE] [Application] [Cash Receipt]
        // [SCENARIO 363069] Verify that Amount and External Doc No transferred when looking up 'Applies-to Doc. No.' value in Payment Journal.

        // [GIVEN] Create invoice from vendor ('External Document No.' non-empty).
        Initialize();
        PostInvoice(GenJournalLine);
        ExpectedExtDocNo := GenJournalLine."External Document No.";
        ExpectedAmount := -GenJournalLine.Amount;

        // [GIVEN] Create Payment Journal Line for the vendor.
        CreatePaymentJnlLine(GenJournalLine, GenJournalLine."Account No.");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        Commit();

        LibraryLowerPermissions.SetAccountPayables();
        PaymentJournal.OpenEdit();
        PaymentJournal."Applies-to Doc. Type".SetValue(GenJournalLine."Applies-to Doc. Type"::Invoice);

        // [WHEN] Look up and set 'Applies-to Doc. No.' to Posted Invoice doc. no.
        PaymentJournal.AppliesToDocNo.Lookup();
        PaymentJournal.OK().Invoke();

        // [THEN] External doc. no. transferred to 'Applied-to Ext. Doc. No.' as well as Amount.
        VerifyExtDocNoAmount(GenJournalLine, ExpectedExtDocNo, ExpectedAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtJnlApplToInvWithNoDimDiscountAndDefDimErr()
    var
        DimensionValue: Record "Dimension Value";
        GenJournalLine: Record "Gen. Journal Line";
        VendorNo: Code[20];
        PaymentAmount: Decimal;
    begin
        // [FEATURE] [Dimension] [Payment Discount]
        // [SCENARIO 376797] Error try posting purchase payment journal without dimension applied to posted Invoice in case of Discount, "Payment Disc. Credit Acc." with default dimension with "Value Posting" = "Same Code"
        Initialize();

        // [GIVEN] Vendor with "Payment Disc. Credit Acc." = "A"
        // [GIVEN] Default Dimension "D" with "Value Posting" = "Same Code" is set for G/L Account "A"
        VendorNo := CreateVendor();
        CreateDefaultDimensionGLAccSameValue(DimensionValue, CreateVendPostingGrPmtDiscCreditAccNo(VendorNo));

        // [GIVEN] Posted Purchase Invoice with Amount Including VAT = 10000 and possible Discount = 2%. No dimension is set.
        CreatePostGenJnlLineWithBalAccount(GenJournalLine, VendorNo);
        PaymentAmount := -GenJournalLine.Amount + GenJournalLine.Amount * GetPmtTermsDiscountPct() / 100;

        // [GIVEN] Purchase Journal with Payment Amount = 9800 and applied to posted Invoice. No dimension is set.
        CreateGenJnlLineWithAppliesToDocNo(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, VendorNo, GenJournalLine."Document No.");
        GenJournalLine.Validate(Amount, PaymentAmount);
        GenJournalLine.Modify();

        // [WHEN] Post Purchase Journal
        LibraryLowerPermissions.SetAccountPayables();
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Error occurs: "A dimension used in Gen. Journal Line GENERAL, CASH, 10000 has caused an error."
        Assert.ExpectedErrorCode(DialogTxt);
        Assert.ExpectedError(
          StrSubstNo(DimensionUsedErr,
            GenJournalLine.TableCaption(), GenJournalLine."Journal Template Name",
            GenJournalLine."Journal Batch Name", GenJournalLine."Line No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtJnlApplToInvWithDimDiscountAndDefDim()
    var
        DimensionValue: Record "Dimension Value";
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        VendorNo: Code[20];
        GLAccountNo: Code[20];
        PaymentAmount: Decimal;
    begin
        // [FEATURE] [Dimension] [Payment Discount]
        // [SCENARIO 376797] Purchase payment journal with dimension applied to posted Invoice can be posted in case of Discount, "Payment Disc. Credit Acc." with default dimension with "Value Posting" = "Same Code"
        Initialize();

        // [GIVEN] Vendor with "Payment Disc. Credit Acc." = "A"
        // [GIVEN] Default Dimension "D" with "Value Posting" = "Same Code" is set for G/L Account "A"
        VendorNo := CreateVendor();
        GLAccountNo := CreateVendPostingGrPmtDiscCreditAccNo(VendorNo);
        CreateDefaultDimensionGLAccSameValue(DimensionValue, GLAccountNo);

        // [GIVEN] Posted Purchase Invoice with Amount Including VAT = 10000 and possible Discount = 2%. No dimension is set.
        CreatePostGenJnlLineWithBalAccount(GenJournalLine, VendorNo);
        PaymentAmount := -GenJournalLine.Amount + GenJournalLine.Amount * GetPmtTermsDiscountPct() / 100;

        // [GIVEN] Purchase Journal with Payment Amount = 9800 and applied to posted Invoice. No dimension is set.
        CreateGenJnlLineWithAppliesToDocNo(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, VendorNo, GenJournalLine."Document No.");
        GenJournalLine.Validate("Dimension Set ID", LibraryDimension.CreateDimSet(0, DimensionValue."Dimension Code", DimensionValue.Code));
        GenJournalLine.Validate(Amount, PaymentAmount);
        GenJournalLine.Modify();

        // [WHEN] Post Purchase Journal
        LibraryLowerPermissions.SetAccountPayables();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Posted G/L Entry with "G/L Account No." = "A" has Dimension "D"
        FindGLEntry(GLEntry, GenJournalLine."Document No.", GLAccountNo);
        Assert.AreEqual(GenJournalLine."Dimension Set ID", GLEntry."Dimension Set ID", GLEntry.FieldCaption("Dimension Set ID"))
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtToInvApplWithNoDimDiscountAndDefDim()
    var
        DimensionValue: Record "Dimension Value";
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        VendorNo: Code[20];
        GLAccountNo: Code[20];
        PaymentAmount: Decimal;
    begin
        // [FEATURE] [Dimension] [Payment Discount]
        // [SCENARIO 376797] Error try posting purchase payment journal without dimension applied to posted Invoice in case of Discount, "Payment Disc. Credit Acc." with default dimension with "Value Posting" = "Same Code"
        Initialize();

        // [GIVEN] Vendor with "Payment Disc. Credit Acc." = "A"
        // [GIVEN] Default Dimension "D" with "Value Posting" = "Same Code" is set for G/L Account "A"
        VendorNo := CreateVendor();
        GLAccountNo := CreateVendPostingGrPmtDiscCreditAccNo(VendorNo);
        CreateDefaultDimensionGLAccSameValue(DimensionValue, GLAccountNo);

        // [GIVEN] Posted Purchase Invoice with Amount Including VAT = 10000 and possible Discount = 2%. No dimension is set.
        CreatePostGenJnlLineWithBalAccount(GenJournalLine, VendorNo);
        PaymentAmount := -GenJournalLine.Amount + GenJournalLine.Amount * GetPmtTermsDiscountPct() / 100;

        // [GIVEN] Posted Purcahse Payment with Amount = 9800. No dimension is set.
        CreateAndPostGenJournalLine(GenJournalLine, GenJournalLine."Account No.", PaymentAmount);

        // [WHEN] Post Payment to Invoice application
        LibraryLowerPermissions.SetAccountPayables();
        ApplyAndPostVendorEntry(GenJournalLine."Document Type", GenJournalLine."Document No.");

        // [THEN] Posted G/L Entry with "G/L Account No." = "A" has no Dimension ("Dimension Set ID" = 0).
        FindGLEntry(GLEntry, GenJournalLine."Document No.", GLAccountNo);
        Assert.AreEqual(0, GLEntry."Dimension Set ID", GLEntry.FieldCaption("Dimension Set ID"))
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesWithSetAppliesToIDModalPageHandler,GeneralJournalTemplateListPageHandler')]
    [Scope('OnPrem')]
    procedure ClearAmountToApplyWhenDeleteAppliesToIDUT()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentJournal: TestPage "Payment Journal";
        ExpectedAmount: Decimal;
    begin
        // [FEATURE] [Application] [Cash Receipt]
        // [SCENARIO 230936] When deleting the value in "Applies-to-ID" field on the PAG 233 manually, "Amount to Apply" must be reset to zero

        // [GIVEN] Posted Purchase Invoice
        Initialize();

        PostInvoice(GenJournalLine);
        ExpectedAmount := GenJournalLine.Amount;

        // [GIVEN] Create Payment Journal Line
        CreatePaymentJnlLine(GenJournalLine, GenJournalLine."Account No.");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        Commit();

        LibraryLowerPermissions.SetAccountPayables();
        PaymentJournal.OpenEdit();
        PaymentJournal."Applies-to Doc. Type".SetValue(GenJournalLine."Applies-to Doc. Type"::Invoice);

        // [GIVEN] Open "Apply Vendor Entries" page
        LibraryVariableStorage.Enqueue(ExpectedAmount);
        PaymentJournal.ApplyEntries.Invoke();

        // [GIVEN] Use "Set Applies-to ID"
        // Done in ApplyVendorEntriesWithSetAppliesToIDModalPageHandler

        // [WHEN] Manually remove "Applies-to ID"
        // Done in ApplyVendorEntriesWithSetAppliesToIDModalPageHandler

        // [THEN] "Amount to apply" and "Appln. Amount to Apply" on "Apply Customer Entries" page is 0
        // Done in ApplyVendorEntriesWithSetAppliesToIDModalPageHandler
    end;

    [Test]
    [HandlerFunctions('TwoApplyVendorEntriesModalPageHandler,GeneralJournalTemplateListPageHandler')]
    [Scope('OnPrem')]
    procedure ClearAppliesToIDInOneRecordOfSeveralCustLedgEntries()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [FEATURE] [Application] [Payment Journal]
        // [SCENARIO 230936] When deleting the value in "Applies-to-ID" field on the "Apply Vendor Entries" page manually, "Applies-to-ID" should not be deleted in other lines having the same "Applies-to-ID"

        Initialize();

        // [GIVEN] Two Posted Sales Invoices
        CreateAndPostTwoGenJournalLinesForSameVendor(GenJournalLine);

        // [GIVEN] Create Payment Journal Line
        CreatePaymentJnlLine(GenJournalLine, GenJournalLine."Account No.");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        Commit();

        LibraryLowerPermissions.SetAccountPayables();
        PaymentJournal.OpenEdit();
        PaymentJournal."Applies-to Doc. Type".SetValue(GenJournalLine."Applies-to Doc. Type"::Invoice);

        // [GIVEN] Open "Apply Vendor Entries" page with two lines
        PaymentJournal.ApplyEntries.Invoke();

        // [GIVEN] Use "Set Applies-to ID" on both lines, "Applies-to ID" of the 1st line = "A", "Applies-to ID" of the 2nd line = "A"
        // Done in TwoEntriesWithSameAppliesToIDModalPageHandler

        // [WHEN] Manually remove "Applies-to ID" on the 2nd line
        // Done in TwoEntriesWithSameAppliesToIDModalPageHandler

        // [THEN] "Applies-to ID" of the 1st line = "A"
        // Done in TwoEntriesWithSameAppliesToIDModalPageHandler

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('TwoEntriesWithSameAppliesToIDModalPageHandler,GeneralJournalTemplateListPageHandler')]
    [Scope('OnPrem')]
    procedure SetAppliesToIDInOneRecordOfSeveralCustLedgEntries()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [FEATURE] [Application] [Payment Journal]
        // [SCENARIO 230936] When manually set the value in "Applies-to-ID" field on the "Apply Vendor Entries" page, "Applies-to-ID" of the other lines with the same value is not changed

        Initialize();

        // [GIVEN] Two Posted Sales Invoices
        CreateAndPostTwoGenJournalLinesForSameVendor(GenJournalLine);

        // [GIVEN] Create Payment Journal Line
        CreatePaymentJnlLine(GenJournalLine, GenJournalLine."Account No.");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        Commit();

        LibraryLowerPermissions.SetAccountPayables();
        PaymentJournal.OpenEdit();
        PaymentJournal."Applies-to Doc. Type".SetValue(GenJournalLine."Applies-to Doc. Type"::Invoice);

        // [GIVEN] Open "Apply Vendor Entries" page with two lines
        PaymentJournal.ApplyEntries.Invoke();

        // [GIVEN] Use "Set Applies-to ID" action on 1st line, "Applies-to ID" of the 1st line = "A"
        // Done in TwoApplyVendorEntriesModalPageHandler

        // [WHEN] Manually set "Applies-to ID" on the 2nd line = "A"
        // Done in TwoApplyVendorEntriesModalPageHandler

        // [THEN] "Applies-to ID" of the 1st line = "A"
        // Done in TwoApplyVendorEntriesModalPageHandler

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('TwoEntriesWithDifferentAppliesToIDModalPageHandler,GeneralJournalTemplateListPageHandler')]
    [Scope('OnPrem')]
    procedure SetDifferentAppliesToIDInOneRecordOfSeveralCustLedgEntries()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [FEATURE] [Application] [Payment Journal]
        // [SCENARIO 230936] When manually set the value in "Applies-to-ID" field on the "Apply Vendor Entries" page, "Applies-to-ID" of the other lines with different value is not changed

        Initialize();

        // [GIVEN] Two Posted Sales Invoices
        CreateAndPostTwoGenJournalLinesForSameVendor(GenJournalLine);

        // [GIVEN] Create Payment Journal Line
        CreatePaymentJnlLine(GenJournalLine, GenJournalLine."Account No.");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        Commit();

        LibraryLowerPermissions.SetAccountPayables();
        PaymentJournal.OpenEdit();
        PaymentJournal."Applies-to Doc. Type".SetValue(GenJournalLine."Applies-to Doc. Type"::Invoice);

        // [GIVEN] Open "Apply Vendor Entries" page with two lines
        PaymentJournal.ApplyEntries.Invoke();

        // [GIVEN] Use "Set Applies-to ID" action on 1st line, "Applies-to ID" of the 1st line = "A"
        // Done in TwoEntriesWithDifferentAppliesToIDModalPageHandler

        // [WHEN] Manually set "Applies-to ID" of the 2nd line = "B"
        // Done in TwoEntriesWithDifferentAppliesToIDModalPageHandler

        // [THEN] "Applies-to ID" of the 1st line = "A", "Applies-to ID" of the 2nd line = "B"
        // Done in TwoEntriesWithDifferentAppliesToIDModalPageHandler

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('GeneralJournalTemplateListPageHandler,ApplyVendorEntriesWithAmountModalPageHandler')]
    [Scope('OnPrem')]
    procedure ApplyInvoiceToSecondPaymentLineWhenAnotherInvoiceIsMarkedAsApplied()
    var
        GenJournalLineInv: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [FEATURE] [Application] [Payment Journal] [UI]
        // [SCENARIO 379474] Apply payment line to the invoice when another invoice has Applied-to ID
        Initialize();

        // [GIVEN] Two invoices "Inv1" of Amount = -1000 and "Inv2" of Amount = -2000
        CreateAndPostTwoGenJournalLinesForSameVendor(GenJournalLineInv);
        VendorLedgerEntry.SetRange("Vendor No.", GenJournalLineInv."Account No.");
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.CalcFields(Amount);

        // [GIVEN] Two payment journal lines for the vendor with Amount = 0
        CreatePaymentJournalBatch(GenJournalBatch);
        LibraryJournals.CreateGenJournalLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, GenJournalLineInv."Account No.",
          "Gen. Journal Account Type"::"G/L Account", '', 0);
        GenJournalLine."Line No." := LibraryUtility.GetNewRecNo(GenJournalLine, GenJournalLine.FieldNo("Line No."));
        GenJournalLine.Insert();
        Commit();

        // [GIVEN] Set Applies-to ID on first payment line for first invoice, payment journal Line gets Amount = 1000
        LibraryLowerPermissions.SetAccountPayables();
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        PaymentJournal.OpenEdit();
        LibraryVariableStorage.Enqueue(VendorLedgerEntry."Document No.");
        LibraryVariableStorage.Enqueue(VendorLedgerEntry.Amount);
        PaymentJournal.ApplyEntries.Invoke();
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.FindFirst();
        GenJournalLine.TestField(Amount, -VendorLedgerEntry.Amount);

        // [WHEN] Set Applies-to ID on second payment line for second invoice, Amount to Apply = -1000
        LibraryVariableStorage.Enqueue(GenJournalLineInv."Document No.");
        LibraryVariableStorage.Enqueue(GenJournalLineInv.Amount / 2);
        PaymentJournal.Next();
        PaymentJournal.ApplyEntries.Invoke();
        PaymentJournal.OK().Invoke();

        // [THEN] Second payment journal line gets Amount = 1000
        GenJournalLine.FindLast();
        GenJournalLine.TestField(Amount, -GenJournalLineInv.Amount / 2);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyFCYInvoicesToFCYPaymentsWithBalancePaymentLineApplnBtwCurrenciesAll()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry1: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
        CurrencyCode1: Code[10];
        CurrencyCode2: Code[10];
        VendorNo: Code[20];
    begin
        // [FEATURE] [Application] [Currency]
        // [SCENARIO 379474] Apply two FCY invoices to two FCY payments with "Appln. between Currencies" = All
        Initialize();

        // [GIVEN] "Appln. between Currencies" = All in Purchase Setup
        UpdateApplnBetweenCurrenciesAllInPurchSetup();

        // [GIVEN] Two invoices "Inv1" in "FCY1" of Amount = -1000 and "Inv2" in "FCY2" of Amount = -2000
        CurrencyCode1 := RandomCurrency();
        CurrencyCode2 := RandomCurrency();
        VendorNo := LibraryPurchase.CreateVendorNo();
        CreateVendorInvoice(VendorLedgerEntry1, VendorNo, -LibraryRandom.RandIntInRange(1000, 2000), CurrencyCode1);
        CreateVendorInvoice(VendorLedgerEntry2, VendorNo, -LibraryRandom.RandIntInRange(1000, 2000), CurrencyCode2);

        // [GIVEN] First payment journal line for the vendor with Amount = 2000 in "FCY2"
        // [GIVEN] Second invoice in "FCY2" is marked with Applies-to ID and Amount to Apply = -2000
        CreatePaymentJournalBatch(GenJournalBatch);
        LibraryJournals.CreateGenJournalLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, VendorNo,
          "Gen. Journal Account Type"::"G/L Account", '', 0);
        UpdateGenJnlLineAppln(GenJournalLine, CurrencyCode2, -VendorLedgerEntry2.Amount);
        UpdateVendorLedgerEntryAppln(VendorLedgerEntry2, GenJournalLine."Document No.", VendorLedgerEntry2.Amount);

        // [GIVEN] Second payment journal line for the vendor with Amount = 500 in "FCY1"
        // [GIVEN] First invoice in "FCY1" is marked with Applies-to ID and Amount to Apply = -500
        GenJournalLine."Line No." := LibraryUtility.GetNewRecNo(GenJournalLine, GenJournalLine.FieldNo("Line No."));
        GenJournalLine.Insert();
        UpdateGenJnlLineAppln(GenJournalLine, CurrencyCode1, -VendorLedgerEntry1.Amount / 2);
        UpdateVendorLedgerEntryAppln(VendorLedgerEntry1, GenJournalLine."Document No.", VendorLedgerEntry1.Amount / 2);

        // [GIVEN] Balance payment journal line for bank account in LCY
        GenJournalLine."Line No." := LibraryUtility.GetNewRecNo(GenJournalLine, GenJournalLine.FieldNo("Line No."));
        GenJournalLine.Insert();
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::"Bank Account");
        GenJournalLine.Validate("Account No.", LibraryERM.CreateBankAccountNo());
        UpdateGenJnlLineAppln(
          GenJournalLine, '', VendorLedgerEntry1."Amount (LCY)" / 2 + VendorLedgerEntry2."Amount (LCY)");

        // [WHEN] Post payment journal lines
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Invoice in "FCY1" has "Remaining Amount" = -500, Invoice in "FCY2" has "Remaining Amount" = 0
        VendorLedgerEntry1.CalcFields("Remaining Amount");
        VendorLedgerEntry1.TestField("Remaining Amount", VendorLedgerEntry1.Amount / 2);
        VendorLedgerEntry2.CalcFields("Remaining Amount");
        VendorLedgerEntry2.TestField("Remaining Amount", 0);

        // [THEN] First payment lines in "FCY2" is applied with to both first and second invoices
        VerifyPaymentWithDetailedEntries(
          VendorNo, CurrencyCode2, VendorLedgerEntry1."Entry No.", VendorLedgerEntry2."Entry No.", 1, 1);
        // [THEN] Second payment line in "FCY1" is applied to second invoice in "FCY2"
        VerifyPaymentWithDetailedEntries(
          VendorNo, CurrencyCode1, VendorLedgerEntry1."Entry No.", VendorLedgerEntry2."Entry No.", 0, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyFCYInvoicesToFCYPaymentsWithBalancePaymentLineApplnBtwCurrenciesNone()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry1: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
        CurrencyCode1: Code[10];
        CurrencyCode2: Code[10];
        VendorNo: Code[20];
    begin
        // [FEATURE] [Application] [Currency]
        // [SCENARIO 379474] Apply two FCY invoices to two FCY payments with "Appln. between Currencies" = None
        Initialize();

        // [GIVEN] "Appln. between Currencies" = None in Purchase Setup
        UpdateApplnBetweenCurrenciesNoneInPurchSetup();

        // [GIVEN] Two invoices "Inv1" in "FCY1" of Amount = -1000 and "Inv2" in "FCY2" of Amount = -2000
        CurrencyCode1 := RandomCurrency();
        CurrencyCode2 := RandomCurrency();
        VendorNo := LibraryPurchase.CreateVendorNo();
        CreateVendorInvoice(VendorLedgerEntry1, VendorNo, -LibraryRandom.RandIntInRange(1000, 2000), CurrencyCode1);
        CreateVendorInvoice(VendorLedgerEntry2, VendorNo, -LibraryRandom.RandIntInRange(1000, 2000), CurrencyCode2);

        // [GIVEN] First payment journal line for the vendor with Amount = 2000 in "FCY2"
        // [GIVEN] Second invoice in "FCY2" is marked with Applies-to ID and Amount to Apply = -2000
        CreatePaymentJournalBatch(GenJournalBatch);
        LibraryJournals.CreateGenJournalLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, VendorNo,
          "Gen. Journal Account Type"::"G/L Account", '', 0);
        UpdateGenJnlLineAppln(GenJournalLine, CurrencyCode2, -VendorLedgerEntry2.Amount);
        UpdateVendorLedgerEntryAppln(VendorLedgerEntry2, GenJournalLine."Document No.", VendorLedgerEntry2.Amount);

        // [GIVEN] Second payment journal line for the vendor with Amount = 500 in "FCY1"
        // [GIVEN] First invoice in "FCY1" is marked with Applies-to ID and Amount to Apply = -500
        GenJournalLine."Line No." := LibraryUtility.GetNewRecNo(GenJournalLine, GenJournalLine.FieldNo("Line No."));
        GenJournalLine.Insert();
        UpdateGenJnlLineAppln(GenJournalLine, CurrencyCode1, -VendorLedgerEntry1.Amount / 2);
        UpdateVendorLedgerEntryAppln(VendorLedgerEntry1, GenJournalLine."Document No.", VendorLedgerEntry1.Amount / 2);

        // [GIVEN] Balance payment journal line for bank account in LCY
        GenJournalLine."Line No." := LibraryUtility.GetNewRecNo(GenJournalLine, GenJournalLine.FieldNo("Line No."));
        GenJournalLine.Insert();
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::"Bank Account");
        GenJournalLine.Validate("Account No.", LibraryERM.CreateBankAccountNo());
        UpdateGenJnlLineAppln(
          GenJournalLine, '', VendorLedgerEntry1."Amount (LCY)" / 2 + VendorLedgerEntry2."Amount (LCY)");

        // [WHEN] Post payment journal lines
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Invoice in "FCY1" has "Remaining Amount" = -500, Invoice in "FCY2" has "Remaining Amount" = 0
        VendorLedgerEntry1.CalcFields("Remaining Amount");
        VendorLedgerEntry1.TestField("Remaining Amount", VendorLedgerEntry1.Amount / 2);
        VendorLedgerEntry2.CalcFields("Remaining Amount");
        VendorLedgerEntry2.TestField("Remaining Amount", 0);

        // [THEN] First payment lines in "FCY2" is applied with the second invoice in "FCY2"
        VerifyPaymentWithDetailedEntries(
          VendorNo, CurrencyCode2, VendorLedgerEntry1."Entry No.", VendorLedgerEntry2."Entry No.", 0, 1);
        // [THEN] Second payment line in "FCY1" is applied to the first invoice in "FCY1"
        VerifyPaymentWithDetailedEntries(
          VendorNo, CurrencyCode1, VendorLedgerEntry1."Entry No.", VendorLedgerEntry2."Entry No.", 1, 0);
    end;

    [Test]
    [HandlerFunctions('MultipleSelectionApplyVendorEntriesModalPageHandler')]
    [Scope('OnPrem')]
    procedure CheckPostingDateForMultipleVendLedgEntriesWhenSetAppliesToIDOnApplyVendorEntries()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Application]
        // [SCENARIO 383611] When "Set Applies-to ID" on "Apply Vendor Entries" page is used for multiple lines, Posting Date of each line is checked.
        Initialize();

        // [GIVEN] Two Posted Purchase Invoices with Posting Date = "01.01.21" / "21.01.21".
        LibraryPurchase.CreateVendor(Vendor);
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        CreateGenJnlLineWithPostingDateAndCurrency(
            GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::Vendor, Vendor."No.", -LibraryRandom.RandInt(100),
            LibraryRandom.RandDate(-10), '');
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        CreateGenJnlLineWithPostingDateAndCurrency(
            GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::Vendor, Vendor."No.", -LibraryRandom.RandInt(100),
            LibraryRandom.RandDate(10), '');
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Payment Journal Line with Posting Date = "11.01.21".
        CreatePaymentJnlLine(GenJournalLine, GenJournalLine."Account No.");
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Modify(true);

        // [GIVEN] "Apply Vendor Entries" page is opened by Codeunit "Gen. Jnl.-Apply" run for Payment Journal Line.
        LibraryVariableStorage.Enqueue(Vendor."No.");
        asserterror CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Apply", GenJournalLine);

        // [WHEN] Multiple lines are selected on "Apply Vendor Entries" page and action "Set Applies-to ID" is used.
        // Done in MultipleSelectionApplyVendorEntriesModalPageHandler

        // [THEN] Error "You cannot apply and post an entry to an entry with an earlier posting date." is thrown.
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(EarlierPostingDateErr);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesModalPageHandler')]
    [Scope('OnPrem')]
    procedure CheckCurrencyForMultipleVendLedgEntriesWhenSetAppliesToIDOnApplyVendorEntries()
    var
        Currency: Record Currency;
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        ApplyVendorEntriesPage: Page "Apply Vendor Entries";
    begin
        // [FEATURE] [Application]
        // [SCENARIO 383611] When "Set Applies-to ID" on "Apply Vendor Entries" page is used for multiple lines, Currency Code of each line is checked.
        Initialize();

        // [GIVEN] "Appln. between Currencies" in "Sales & Receivables Setup" is set to None.
        LibraryPurchase.SetApplnBetweenCurrencies(PurchasesPayablesSetup."Appln. between Currencies"::None);

        // [GIVEN] Two Posted Purchase Invoices with Currency Code = blank / "JPY".
        LibraryPurchase.CreateVendor(Vendor);
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        CreateGenJnlLineWithPostingDateAndCurrency(
            GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::Vendor, Vendor."No.", -LibraryRandom.RandInt(100),
            WorkDate(), '');
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        Currency.Get(LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1, 1));
        CreateGenJnlLineWithPostingDateAndCurrency(
          GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::Vendor, Vendor."No.", -LibraryRandom.RandInt(100),
          WorkDate(), Currency.Code);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Posted Payment Journal Line with Currency = blank.
        CreatePaymentJnlLine(GenJournalLine, GenJournalLine."Account No.");
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate(Amount, LibraryRandom.RandInt(100));
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] "Apply Vendor Entries" page  is opened.
        VendorLedgerEntry.FindLast();
        VendorLedgerEntry."Applies-to ID" := UserId();
        VendorLedgerEntry."Applying Entry" := true;
        VendorLedgerEntry.Modify();
        ApplyVendorEntriesPage.SetVendLedgEntry(VendorLedgerEntry);
        ApplyVendorEntriesPage.RunModal();

        // [WHEN] Multiple lines are selected on "Apply Vendor Entries" page and action "Set Applies-to ID" is used.
        VendorLedgerEntry.SetRange("Vendor No.", Vendor."No.");
        asserterror ApplyVendorEntriesPage.CheckVendLedgEntry(VendorLedgerEntry);

        // [THEN] Error "All entries in one application must be in the same currency." is thrown.
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(DifferentCurrenciesErr);
    end;

    [Test]
    [HandlerFunctions('GeneralJournalTemplateListPageHandler,ApplyVendorEntriesWithAppliesToIDModalPageHandler')]
    [Scope('OnPrem')]
    procedure EnsureAppliesToIDIsNotRemovedWhenCopyJournalLines()
    var
        GenJournalLineInv: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Vendor: Record Vendor;
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [SCENARIO 449685] Applies-to ID is removed when copying lines to Journal
        Initialize();

        // [GIVEN] Create two invoices
        LibraryPurchase.CreateVendor(Vendor);
        CreateAndPostTwoGenJournalLinesForSameVendor(GenJournalLineInv);
        VendorLedgerEntry.SetRange("Vendor No.", GenJournalLineInv."Account No.");
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.CalcFields(Amount);

        // [GIVEN] Create two payment journals
        CreatePaymentJournalBatch(GenJournalBatch);
        LibraryJournals.CreateGenJournalLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, GenJournalLineInv."Account No.",
          "Gen. Journal Account Type"::"G/L Account", '', 0);
        GenJournalLine."Line No." := LibraryUtility.GetNewRecNo(GenJournalLine, GenJournalLine.FieldNo("Line No."));
        GenJournalLine.Insert();
        Commit();

        // [GIVEN] Set Applies-to ID on first payment journal Line 
        LibraryLowerPermissions.SetAccountPayables();
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        PaymentJournal.OpenEdit();
        LibraryVariableStorage.Enqueue(VendorLedgerEntry."Document No.");
        LibraryVariableStorage.Enqueue(VendorLedgerEntry.Amount);
        PaymentJournal.ApplyEntries.Invoke();
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");

        // [WHEN] Set Account No. on second payment journal line 
        PaymentJournal.Next();
        PaymentJournal."Account No.".SetValue(Vendor."No.");

        // [THEN] Verify Applies to ID is not removed on Gen Journal Line & Vendor Ledger Entry
        GenJournalLine.FindFirst();
        GenJournalLine.TestField("Applies-to ID");
        VendorLedgerEntry.Reset();
        VendorLedgerEntry.Get(LibraryVariableStorage.DequeueInteger());
        VendorLedgerEntry.TestField("Applies-to ID");
        PaymentJournal.Close();

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ReverseTransactionEntriesPageHandler,VoidCheckPageHandler')]
    procedure SourceCurrAmtIsPopulatedInGLEntryWhenVoidCheck()
    var
        BankAccount: Record "Bank Account";
        CheckLedgerEntry: Record "Check Ledger Entry";
        GLEntry: Record "G/L Entry";
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
        Amount: Decimal;
        DocumentNo: Code[20];
        VoidType: Option "Unapply and void check","Void check only";
    begin
        // [SCENARIO 559194] Source Currency Amount is populated in G/L Entries which 
        // Are created when Stan runs Void Check action from a Check Ledger Entry.
        Initialize();

        // [GIVEN] Create a Vendor.
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Create a Bank Account and Validate Currency Code.
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Currency Code", CreateCurrencyCode());
        BankAccount.Modify(true);

        // [GIVEN] Generate and save Amount in a Variable.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create and Post Gen. Journal Line.
        CreateAndPostGenJournalLine(Vendor, BankAccount, Amount);

        // [GIVEN] Find Vendor ledger Entry.
        VendorLedgerEntry.SetRange("Vendor No.", Vendor."No.");
        VendorLedgerEntry.FindFirst();

        // [GIVEN] Run Reverse Transaction action from Vendor Ledger Entries page.
        VendorLedgerEntries.OpenEdit();
        VendorLedgerEntries.GoToRecord(VendorLedgerEntry);
        VendorLedgerEntries.ReverseTransaction.Invoke();

        // [GIVEN] Find Check Ledger Entry.
        CheckLedgerEntry.SetRange("Bank Account No.", BankAccount."No.");
        CheckLedgerEntry.FindFirst();

        // [GIVEN] Void Check.
        LibraryVariableStorage.Enqueue(VoidType::"Void check only");
        VoidCheck(CheckLedgerEntry."Document No.");

        // [GIVEN] Find GL Entry and save Document No. in a Variable.
        GLEntry.SetRange("Source Currency Code", BankAccount."Currency Code");
        GLEntry.FindFirst();
        DocumentNo := GLEntry."Document No.";

        // [WHEN] Find GL Entry.
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Bal. Account Type", GLEntry."Bal. Account Type"::"G/L Account");
        GLEntry.FindFirst();

        // [THEN] Source Currency Amount of GL Entry is equal to Amount.
        Assert.AreEqual(
            Amount,
            GLEntry."Source Currency Amount",
            StrSubstNo(
                SourceCurrAmtErr,
                GLEntry.FieldCaption("Source Currency Amount"),
                Amount,
                GLEntry.TableCaption()));

        // [WHEN] Find GL Entry.
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Bal. Account Type", GLEntry."Bal. Account Type"::"G/L Account");
        GLEntry.FindLast();

        // [THEN] Source Currency Amount of GL Entry is equal to -Amount.
        Assert.AreEqual(
            -Amount,
            GLEntry."Source Currency Amount",
            StrSubstNo(
                SourceCurrAmtErr,
                GLEntry.FieldCaption("Source Currency Amount"),
                -Amount,
                GLEntry.TableCaption()));
    end;

    [Test]
    procedure ValueInClosedAtDateMustHaveValueInVendorLedgerEntryPostApplication()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DocumentNo: Code[20];
        DirectUnitCost: Decimal;
        Quantity: Decimal;
    begin
        // [SCENARIO 573806] The Closed at Date updates when applying entries on the Vendor Ledger Entries and Customer Ledger Entries.
        Initialize();

        // [GIVEN] Store Quantity and Direct Unit Cost in a Variable.
        Quantity := LibraryRandom.RandDec(100, 2);
        DirectUnitCost := LibraryRandom.RandDec(100, 2);

        // [GIVEN] Create and Post Purchase Invoice.
        CreateAndPostPurchaseDocument(
            PurchaseHeader,
            PurchaseLine,
            PurchaseHeader."Document Type"::Invoice,
            CreateVendor(),
            CreateItem(),
            DirectUnitCost,
            Quantity);

        // [GIVEN] Create and Post Purchase Credit Memo.
        DocumentNo := CreateAndPostPurchaseDocument(
            PurchaseHeader,
            PurchaseLine,
            PurchaseHeader."Document Type"::"Credit Memo",
            PurchaseHeader."Buy-from Vendor No.",
            PurchaseLine."No.",
            DirectUnitCost,
            Quantity);

        // [WHEN] Apply Credit Memo with Invoice.
        ApplyAndPostVendorEntry(PurchaseHeader."Document Type"::"Credit Memo", DocumentNo);

        // [THEN] Closed at Date must have value in applying Vendor Leder Entry.
        VendorLedgerEntry.SetRange("Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        VendorLedgerEntry.SetRange("Document Type", PurchaseHeader."Document Type"::"Credit Memo");
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry.FindFirst();
        Assert.AreNotEqual(0D, VendorLedgerEntry."Closed at Date", ClosedAtDateErr);
    end;

    local procedure Initialize()
    var
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Apply Purchase/Payables");

        LibraryApplicationArea.EnableFoundationSetup();
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Apply Purchase/Payables");

        // Setup default fixture

        // Create new payment terms with random discount due date and discount percentage.
        // The due date must be after the discount due date.
        LibraryLowerPermissions.SetOutsideO365Scope();
        ReplacePaymentTerms(
          PmtTerms, 'NEW', '<1M>', '<' + Format(LibraryRandom.RandInt(20)) + 'D>', LibraryRandom.RandInt(200) / 10);
        ModifyGenJnlBatchNoSeries();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateAccountInVendorPostingGroups();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        isInitialized := true;
        Commit();
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Apply Purchase/Payables");
    end;

    local procedure ApplyVendorEntry(var ApplyingVendorLedgerEntry: Record "Vendor Ledger Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(ApplyingVendorLedgerEntry, DocumentType, DocumentNo);
        ApplyingVendorLedgerEntry.CalcFields("Remaining Amount");
        LibraryERM.SetApplyVendorEntry(ApplyingVendorLedgerEntry, ApplyingVendorLedgerEntry."Remaining Amount");

        // Find Posted Vendor Ledger Entries.
        VendorLedgerEntry.SetRange("Vendor No.", ApplyingVendorLedgerEntry."Vendor No.");
        VendorLedgerEntry.SetRange("Applying Entry", false);
        VendorLedgerEntry.FindSet();
        repeat
            VendorLedgerEntry.CalcFields("Remaining Amount");
            VendorLedgerEntry.Validate("Amount to Apply", VendorLedgerEntry."Remaining Amount");
            VendorLedgerEntry.Modify(true);
        until VendorLedgerEntry.Next() = 0;

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

    local procedure ClearGenenalJournalLine(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    local procedure TestApplication(InvCurrency: Code[10]; PmtCurrency: Code[10]; PaymentPercentage: Decimal; NumberOfInvoices: Integer; NumberOfPayments: Integer; PostingDelta: Text[30]; StepWisePost: Boolean)
    var
        InvVendorLedgerEntry: array[10] of Record "Vendor Ledger Entry";
        PmtVendorLedgerEntry: array[10] of Record "Vendor Ledger Entry";
        Vendor: Record Vendor;
        InvLCYFullAmount: Decimal;
        PmtLCYFullAmount: Decimal;
        i: Integer;
    begin
        LibraryLowerPermissions.SetOutsideO365Scope();
        Assert.IsTrue(NumberOfInvoices <= 10, 'Not more than 10 invoices');
        Assert.IsTrue(NumberOfPayments <= 10, 'Not more than 10 payments');

        // Find a random vendor and update the payment terms.
        GetVendorAndUpdatePmtTerms(Vendor);

        // Compute Invoice and Payment amounts.
        ComputeAmounts(InvLCYFullAmount, PmtLCYFullAmount, PaymentPercentage, CalcDate(PostingDelta));

        // Create Invoices.
        for i := 1 to NumberOfInvoices do
            // Make a partial invoice.
            CreateVendorPartialInvoice(InvVendorLedgerEntry[i], InvLCYFullAmount, Vendor, InvCurrency, i, NumberOfInvoices);

        // Create multiple Payments.
        for i := 1 to NumberOfPayments do
            // Make a partial payment.
            CreateVendorPartialPayment(PmtVendorLedgerEntry[i], PmtLCYFullAmount, Vendor, PostingDelta, PmtCurrency, i, NumberOfPayments);

        // Sanity check that the full amount has been paid.
        Assert.AreEqual(Round(InvLCYFullAmount), 0, StrSubstNo(InternalError, 'Invoice'));
        Assert.AreEqual(Round(PmtLCYFullAmount), 0, StrSubstNo(InternalError, 'Payment'));

        // Excercise application of invoice and payments.
        if StepWisePost then
            PostApplicationStepwise(InvVendorLedgerEntry, PmtVendorLedgerEntry, NumberOfInvoices, NumberOfPayments)
        else
            PostApplication(InvVendorLedgerEntry, PmtVendorLedgerEntry, NumberOfInvoices, NumberOfPayments);

        // Validate that all invoices closed.
        for i := 1 to NumberOfInvoices do
            ValidateVendLedgEntrClosed(InvVendorLedgerEntry[i])
    end;

    local procedure FuzzyTestApplication(NumberOfInvoices: Integer; NumberOfPayments: Integer)
    var
        InvVendorLedgerEntry: array[10] of Record "Vendor Ledger Entry";
        PmtVendorLedgerEntry: array[10] of Record "Vendor Ledger Entry";
        Vendor: Record Vendor;
        InvLCYFullAmount: Decimal;
        PmtLCYFullAmount: Decimal;
        TotalPmtAmount: Decimal;
        i: Integer;
    begin
        Assert.IsTrue(NumberOfPayments <= 10, 'Not more than 10 payments');

        // Find a random vendor and update the payment terms.
        GetVendorAndUpdatePmtTerms(Vendor);

        // Compute Invoice and Payment amounts.
        ComputeAmounts(InvLCYFullAmount, PmtLCYFullAmount, 1.0, WorkDate());

        // Create an Invoice.
        for i := 1 to NumberOfInvoices do begin
            // Make a partial invoice.
            CreateVendorPartialInvoice(InvVendorLedgerEntry[i], InvLCYFullAmount, Vendor, RandomCurrency(), i, NumberOfInvoices);
            InvVendorLedgerEntry[i].CalcFields("Remaining Amount");
            TotalPmtAmount += InvVendorLedgerEntry[i]."Remaining Pmt. Disc. Possible" - InvVendorLedgerEntry[i]."Remaining Amount";
        end;

        // Create multiple Payments.
        for i := 1 to NumberOfPayments do begin
            // Make a partial payment in a random currency.
            CreateVendorPartialPaymentWithRemainder(
              PmtVendorLedgerEntry[i], PmtLCYFullAmount,
              TotalPmtAmount, Vendor, '<0D>', RandomCurrency(), i, NumberOfPayments);
            PmtVendorLedgerEntry[i].CalcFields("Remaining Amount");
            TotalPmtAmount -= PmtVendorLedgerEntry[i]."Remaining Amount";
        end;

        // Sanity check that the full amount has been paid.
        Assert.AreEqual(Round(InvLCYFullAmount), 0, StrSubstNo(InternalError, 'Invoice'));
        Assert.AreEqual(Round(PmtLCYFullAmount), 0, StrSubstNo(InternalError, 'Payment'));

        // Excercise application of invoice and payments.
        PostApplication(InvVendorLedgerEntry, PmtVendorLedgerEntry, NumberOfInvoices, NumberOfPayments);

        // Validation.
        for i := 1 to NumberOfInvoices do
            ValidateVendLedgEntrClosed(InvVendorLedgerEntry[i])
    end;

    local procedure FindVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATCalculationType: Enum "Tax Calculation Type")
    begin
        VATPostingSetup.SetFilter("VAT Bus. Posting Group", '<>''''');
        VATPostingSetup.SetFilter("VAT Prod. Posting Group", '<>''''');
        VATPostingSetup.SetRange("VAT Calculation Type", VATCalculationType);
        VATPostingSetup.SetFilter("VAT %", '0');

        VATPostingSetup.FindFirst();
    end;

    local procedure FindVATPostingSetupForPurchase(var VATPostingSetup: Record "VAT Posting Setup"; VATCalculationType: Enum "Tax Calculation Type")
    var
        VATReportingCode: Record "VAT Reporting Code";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATCalculationType);
        VATPostingSetup.SetFilter("VAT Number", '<>''''');
        if VATPostingSetup.FindSet() then
            repeat
                VATReportingCode.Get(VATPostingSetup."VAT Number");
                if VATReportingCode."Gen. Posting Type" = VATReportingCode."Gen. Posting Type"::Purchase then
                    exit;
            until VATPostingSetup.Next() = 0;

        Assert.Fail(VATPostingSetupErr);
    end;

    local procedure FindVendorLedgerEntryAmount(GenJournalLine: Record "Gen. Journal Line"; PmtDiscExclVAT: Boolean; DiscountPercentage: Decimal) PmtDiscountAmount: Decimal
    begin
        if PmtDiscExclVAT then
            PmtDiscountAmount := ((-GenJournalLine.Amount + GenJournalLine."VAT Amount") * DiscountPercentage / 100)
        else
            PmtDiscountAmount := (-GenJournalLine.Amount * DiscountPercentage / 100);
    end;

    local procedure GetPmtTermsDiscountPct(): Decimal
    var
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        exit(PaymentTerms."Discount %");
    end;

    local procedure ReplacePaymentTerms(var PmtTerms: Record "Payment Terms"; "Code": Code[10]; DueDateCalc: Text[30]; DiscountDateCalc: Text[30]; Discount: Decimal)
    begin
        // Creates or updates payment terms with given code.
        if not PmtTerms.Get(Code) then begin
            PmtTerms.Init();
            PmtTerms.Code := Code;
            PmtTerms.Insert(true);
        end;

        Evaluate(PmtTerms."Due Date Calculation", DueDateCalc);
        Evaluate(PmtTerms."Discount Date Calculation", DiscountDateCalc);
        PmtTerms.Validate("Discount %", Discount);
        PmtTerms.Modify(true);
    end;

    local procedure RandomCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure GetVendorAndUpdatePmtTerms(var Vendor: Record Vendor)
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Payment Terms Code", PmtTerms.Code);
        Vendor.Validate("Application Method", Vendor."Application Method"::Manual);
        Vendor.Modify(true);
    end;

    local procedure ComputeAmounts(var InvLCYFullAmount: Decimal; var PmtLCYFullAmount: Decimal; PmtPercentage: Decimal; PostingDate: Date)
    var
        PmtLCYAmount: Decimal;
        PmtLCYDiscount: Decimal;
    begin
        // Compute a random decimal invoice amount (invoice is negative for vendors).
        InvLCYFullAmount := -LibraryRandom.RandDec(100000, 2);

        // Compute payment LCY amount.
        PmtLCYAmount := -Round(PmtPercentage * InvLCYFullAmount);

        // Compute discount (if applicable).
        if PostingDate <= CalcDate(PmtTerms."Discount Date Calculation") then
            PmtLCYDiscount := -Round(PmtLCYAmount * PmtTerms."Discount %" / 100)
        else
            PmtLCYDiscount := 0.0;

        // Adjust full amount for discount.
        PmtLCYFullAmount := PmtLCYAmount + PmtLCYDiscount;
    end;

    local procedure CreateAndPostGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20]; Amount: Decimal)
    begin
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::Payment, AccountNo, Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostTwoGenJournalLinesForSameVendor(var GenJournalLine: Record "Gen. Journal Line")
    var
        VendorNo: Code[20];
    begin
        VendorNo := LibraryPurchase.CreateVendorNo();
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor,
          VendorNo, -LibraryRandom.RandIntInRange(1000, 2000));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor,
          VendorNo, -LibraryRandom.RandIntInRange(1000, 2000));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; AccountNo: Code[20]; Amount: Decimal)
    var
        BankAccount: Record "Bank Account";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.FindBankAccount(BankAccount);
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          GenJournalLine."Account Type"::Vendor, AccountNo, Amount);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", BankAccount."No.");
        GenJournalLine.Modify(true);
    end;

    local procedure PostInvoice(var GenJournalLine: Record "Gen. Journal Line")
    begin
        CreateGenJournalLine(
            GenJournalLine, GenJournalLine."Document Type"::Invoice,
            LibraryPurchase.CreateVendorNo(), -LibraryRandom.RandIntInRange(10, 100));
        GenJournalLine.Validate("External Document No.", LibraryUtility.GenerateGUID());
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostGenJournalLineWithPmtDiscExclVAT(PmtDiscExclVAT: Boolean; GLAccountNo: Code[20])
    var
        PaymentTerms: Record "Payment Terms";
        GenJournalLine: Record "Gen. Journal Line";
        LibraryPmtDiscSetup: Codeunit "Library - Pmt Disc Setup";
        VendorNo: Code[20];
    begin
        // Setup: Update Pmt. Disc. Excl. VAT in General Ledger & Create Vendor with Payment Terms & Create Gen. Journal Line.
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(false);
        LibraryPmtDiscSetup.SetPmtDiscExclVAT(PmtDiscExclVAT);

        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        VendorNo := CreateVendorWithPaymentTerms(PaymentTerms);

        // Exercise: Create-Post Gen. Journal Line.
        CreatePostBalancedGenJnlLine(GenJournalLine, VendorNo, GLAccountNo);

        // Verify: Verifying Vendor Ledger Entry.
        VerifyDiscountValueInVendorLedger(
          GenJournalLine,
          FindVendorLedgerEntryAmount(GenJournalLine, PmtDiscExclVAT, PaymentTerms."Discount %"));
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateAndPostPurchaseDocument(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Gen. Journal Document Type"; VendorNo: Code[20]; ItemNo: Code[20]; DirectUnitCost: Decimal; Quantity: Decimal): Code[20]
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, ItemNo, DirectUnitCost, Quantity);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreatePostBalancedGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20]; GLAccountNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        DocumentNo: Code[20];
    begin
        CreateGenJnlTemplateAndBatch(GenJournalBatch);
        CreateGenJnlLine(GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::Vendor, VendorNo, -LibraryRandom.RandInt(50));
        DocumentNo := GenJournalLine."Document No.";
        CreateGenJnlLine(GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::"G/L Account", GLAccountNo, -GenJournalLine.Amount);
        GenJournalLine.Validate("Document No.", DocumentNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal)
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          AccountType, AccountNo, Amount);
    end;

    local procedure CreateGenJnlLineWithPostingDateAndCurrency(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal; PostingDate: Date; CurrencyCode: Code[10])
    begin
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
            AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateGenJnlTemplateAndBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateGLAccountWithVAT(): Code[20]
    var
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        FindVATPostingSetupForPurchase(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Posting Type", GLAccount."Gen. Posting Type"::Purchase);
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreatePostGenJnlLineWithBalAccount(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGenJnlTemplateAndBatch(GenJournalBatch);
        CreateGenJnlLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::Vendor, VendorNo, -LibraryRandom.RandIntInRange(1000, 2000));
        GenJournalLine.Validate("Bal. Account No.", CreateGLAccountWithVAT());
        GenJournalLine.Validate("Sales/Purch. (LCY)", 0);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreatePurchaseLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; DirectUnitCost: Decimal; Quantity: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateVendor(): Code[20]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        PaymentTerms.SetRange("Calc. Pmt. Disc. on Cr. Memos", false);
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        exit(CreateVendorWithPaymentTerms(PaymentTerms));
    end;

    local procedure CreateVendorWithPaymentTerms(PaymentTerms: Record "Payment Terms"): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Payment Terms Code", PaymentTerms.Code);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateVendorInvoice(var VendorLedgerEntry: Record "Vendor Ledger Entry"; VendorNo: Code[20]; Amount: Decimal; Currency: Code[10])
    var
        Inv: Record "Gen. Journal Line";
        Batch: Record "Gen. Journal Batch";
    begin
        // Create an Invoice in the General Journal.
        Inv.Init();
        ClearGenenalJournalLine(Batch);
        LibraryERM.CreateGeneralJnlLine(
          Inv,
          Batch."Journal Template Name",
          Batch.Name,
          Inv."Document Type"::Invoice,
          Inv."Account Type"::Vendor,
          VendorNo,
          Amount);

        // Set currency.
        Inv.Validate("Currency Code", Currency);
        Inv.Modify(true);

        // Post it.
        LibraryERM.PostGeneralJnlLine(Inv);

        // Find the newly posted vendor ledger entry and update flowfields.
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, Inv."Document Type", Inv."Document No.");
        VendorLedgerEntry.CalcFields(Amount, "Amount (LCY)", "Remaining Amount");
    end;

    local procedure CreateVendorPayment(var VendorLedgerEntry: Record "Vendor Ledger Entry"; VendorNo: Code[20]; Amount: Decimal; Currency: Code[10]; PostingDelta: Text[30])
    var
        Pmt: Record "Gen. Journal Line";
        Batch: Record "Gen. Journal Batch";
        PostingDate: Date;
    begin
        // Create a Payment in the General Journal.
        Pmt.Init();
        ClearGenenalJournalLine(Batch);
        LibraryERM.CreateGeneralJnlLine(
          Pmt,
          Batch."Journal Template Name",
          Batch.Name,
          Pmt."Document Type"::Payment,
          Pmt."Account Type"::Vendor,
          VendorNo,
          Amount);

        // Set posting date and currency.
        PostingDate := CalcDate(PostingDelta, WorkDate());
        Pmt.Validate("Posting Date", PostingDate);
        Pmt.Validate("Currency Code", Currency);
        Pmt.Modify(true);

        // Post it.
        LibraryERM.PostGeneralJnlLine(Pmt);

        // Find the newly posted vendor ledger entry and update flowfields.
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, Pmt."Document Type", Pmt."Document No.");
        VendorLedgerEntry.CalcFields(Amount, "Amount (LCY)", "Remaining Amount");
    end;

    local procedure CreateVendorPartialInvoice(var InvVendorLedgerEntry: Record "Vendor Ledger Entry"; var Remainder: Decimal; Vendor: Record Vendor; Currency: Code[10]; InvoiceNumber: Integer; NumberOfInvoices: Integer)
    var
        InvLCYAmount: Decimal;
        InvAmount: Decimal;
    begin
        // Pay a random percentage between 10% and 90% of the remaining amount (last invoice is always full).
        if InvoiceNumber = NumberOfInvoices then
            InvLCYAmount := Remainder
        else
            InvLCYAmount := Round((10 + LibraryRandom.RandInt(80)) / 100 * Remainder);

        // Convert amount to foreign currency.
        InvAmount := Round(LibraryERM.ConvertCurrency(InvLCYAmount, '', Currency, WorkDate()));

        // Create partial payment for PmtAmount.
        CreateVendorInvoice(InvVendorLedgerEntry, Vendor."No.", InvAmount, Currency);
        Remainder := Remainder - InvLCYAmount;
    end;

    local procedure CreateVendorPartialPayment(var PmtVendorLedgerEntry: Record "Vendor Ledger Entry"; var Remainder: Decimal; Vendor: Record Vendor; PostingDelta: Text[30]; Currency: Code[10]; PaymentNumber: Integer; NumberOfPayments: Integer)
    var
        PmtLCYAmount: Decimal;
        PmtAmount: Decimal;
    begin
        // Pay a random percentage between 10% and 90% of the remaining amount (last payment is always full).
        if PaymentNumber = NumberOfPayments then
            PmtLCYAmount := Remainder
        else
            PmtLCYAmount := Round((10 + LibraryRandom.RandInt(80)) / 100 * Remainder);

        // Convert amount to foreign currency.
        PmtAmount := Round(LibraryERM.ConvertCurrency(PmtLCYAmount, '', Currency, WorkDate()));

        // Create partial payment for PmtAmount.
        CreateVendorPayment(PmtVendorLedgerEntry, Vendor."No.", PmtAmount, Currency, PostingDelta);
        Remainder := Remainder - PmtLCYAmount;
    end;

    local procedure CreateVendorPartialPaymentWithRemainder(var PmtVendorLedgerEntry: Record "Vendor Ledger Entry"; var Remainder: Decimal; LCYRemainder: Decimal; Vendor: Record Vendor; PostingDelta: Text[30]; Currency: Code[10]; PaymentNumber: Integer; NumberOfPayments: Integer)
    var
        PmtLCYAmount: Decimal;
        PmtAmount: Decimal;
    begin
        // Pay a random percentage between 10% and 90% of the remaining amount (last payment is always full).
        if PaymentNumber = NumberOfPayments then
            PmtLCYAmount := Remainder
        else
            PmtLCYAmount := Round((10 + LibraryRandom.RandInt(80)) / 100 * Remainder);

        // Convert amount to foreign currency.
        PmtAmount := Round(LibraryERM.ConvertCurrency(PmtLCYAmount, '', Currency, WorkDate()));
        if PaymentNumber = NumberOfPayments then
            PmtAmount += Abs(LCYRemainder - PmtAmount);

        // Create partial payment for PmtAmount.
        CreateVendorPayment(PmtVendorLedgerEntry, Vendor."No.", PmtAmount, Currency, PostingDelta);
        Remainder := Remainder - PmtLCYAmount;
    end;

    local procedure CreateGenJnlLineWithAppliesToID(var GenJnlLine: Record "Gen. Journal Line"; AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; AppliesToID: Code[50])
    var
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJnlBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJnlLine, GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Payment, AccType, AccNo, 0);
        GenJnlLine."Applies-to ID" := AppliesToID;
        GenJnlLine.Modify();
    end;

    local procedure CreateGenJnlLineWithAppliesToDocNo(var GenJnlLine: Record "Gen. Journal Line"; AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; AppliesToDocNo: Code[20])
    var
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJnlBatch);
        LibraryERM.ClearGenJournalLines(GenJnlBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJnlLine, GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Payment, AccType, AccNo, 0);
        GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::Invoice;
        GenJnlLine."Applies-to Doc. No." := AppliesToDocNo;
        GenJnlLine.Modify();
    end;

    local procedure CreatePaymentJnlLine(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreatePaymentJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, AccountNo,
          GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), 0);
    end;

    local procedure CreatePaymentJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, GenJournalTemplate.Type::Payments);
        GenJournalTemplate.Modify(true);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateDefaultDimensionGLAccSameValue(var DimensionValue: Record "Dimension Value"; GLAccountNo: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimensionGLAcc(DefaultDimension, GLAccountNo, DimensionValue."Dimension Code", DimensionValue.Code);
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Same Code");
        DefaultDimension.Modify();
    end;

    local procedure CreateVendPostingGrPmtDiscCreditAccNo(VendorNo: Code[20]): Code[20]
    var
        VendorPostingGroup: Record "Vendor Posting Group";
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        VendorPostingGroup.Get(Vendor."Vendor Posting Group");
        VendorPostingGroup.Validate("Payment Disc. Credit Acc.", LibraryERM.CreateGLAccountNo());
        VendorPostingGroup.Modify(true);
        exit(VendorPostingGroup."Payment Disc. Credit Acc.");
    end;

    local procedure FindOpenInvVendLedgEntry(var VendLedgEntry: Record "Vendor Ledger Entry")
    begin
        VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::Invoice);
        VendLedgEntry.SetRange("Applying Entry", false);
        VendLedgEntry.SetRange(Open, true);
        VendLedgEntry.FindFirst();
    end;

    local procedure FindGLEntry(var GLEntry: Record "G/L Entry"; DocumentNo: Code[20]; GLAccountNo: Code[20])
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
    end;

    local procedure GetVendorWithPaymentTerms(var PaymentTerms: Record "Payment Terms"): Code[20]
    begin
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        exit(CreateVendorWithPaymentTerms(PaymentTerms));
    end;

    local procedure ModifyGenJnlBatchNoSeries()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJnlBatch);
        GenJnlBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        GenJnlBatch.Modify(true);
    end;

    local procedure PostApplication(var InvVendorLedgerEntry: array[10] of Record "Vendor Ledger Entry"; var PmtVendorLedgerEntries: array[10] of Record "Vendor Ledger Entry"; NumberOfInvoices: Integer; NumberOfPayments: Integer)
    var
        i: Integer;
    begin
        // The first payment is the applying entry, otherwise the discount does not apply.
        SetupApplyingEntry(PmtVendorLedgerEntries[1], PmtVendorLedgerEntries[1].Amount);

        // Include all invoices.
        for i := 1 to NumberOfInvoices do
            SetupApplyEntry(InvVendorLedgerEntry[i]);

        // Include remaining payments.
        for i := 2 to NumberOfPayments do
            SetupApplyEntry(PmtVendorLedgerEntries[i]);

        // Call Apply codeunit.
        CODEUNIT.Run(CODEUNIT::"VendEntry-Apply Posted Entries", PmtVendorLedgerEntries[1]);
    end;

    local procedure PostApplicationStepwise(var InvVendorLedgerEntry: array[10] of Record "Vendor Ledger Entry"; var PmtVendorLedgerEntries: array[10] of Record "Vendor Ledger Entry"; NumberOfInvoices: Integer; NumberOfPayments: Integer)
    var
        i: Integer;
        j: Integer;
    begin
        // Apply invoices step-wise.
        for i := 1 to NumberOfInvoices do begin
            // The first payment is the applying entry, otherwise the discount does not apply.
            PmtVendorLedgerEntries[1].Get(PmtVendorLedgerEntries[1]."Entry No.");
            PmtVendorLedgerEntries[1].CalcFields("Remaining Amount");

            SetupApplyingEntry(PmtVendorLedgerEntries[1], PmtVendorLedgerEntries[1]."Remaining Amount");

            // Apply all remaining payments.
            for j := 2 to NumberOfPayments do begin
                PmtVendorLedgerEntries[j].Get(PmtVendorLedgerEntries[j]."Entry No.");
                PmtVendorLedgerEntries[j].CalcFields("Remaining Amount");

                if PmtVendorLedgerEntries[j].Open then
                    SetupApplyEntry(PmtVendorLedgerEntries[j]);
            end;

            // Apply to i'th invoice.
            SetupApplyEntry(InvVendorLedgerEntry[i]);

            // Call Apply codeunit.
            CODEUNIT.Run(CODEUNIT::"VendEntry-Apply Posted Entries", PmtVendorLedgerEntries[1]);
        end;
    end;

    local procedure SetAppliesToIDOnVendLedgEntry(var VendLedgEntry: Record "Vendor Ledger Entry")
    begin
        VendLedgEntry."Applies-to ID" := LibraryUtility.GenerateGUID();
        VendLedgEntry.Modify();
    end;

    local procedure SetupApplyingEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; AmountToApply: Decimal)
    begin
        LibraryERM.SetApplyVendorEntry(VendorLedgerEntry, AmountToApply);
    end;

    local procedure SetupApplyEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry);
    end;

    local procedure TestRemainingAmountOnVendorLedgerEntry(DocumentType: Enum "Gen. Journal Document Type"; SignForGLEntry: Integer; SignForVendorLedgerEntry: Integer)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PostedDocumentNo: Code[20];
    begin
        // Setup.
        Initialize();

        // Exercise: Create and Post Purchase Document.
        PostedDocumentNo :=
          CreateAndPostPurchaseDocument(
            PurchaseHeader, PurchaseLine, DocumentType, CreateVendor(), CreateItem(), LibraryRandom.RandDec(1000, 2),
            LibraryRandom.RandDec(100, 2));

        // Verify: Verify G/L and Vendor Ledger Entries.
        VerifyGLEntry(DocumentType, PostedDocumentNo, SignForGLEntry * PurchaseLine."Line Amount");
        VerifyVendorLedgerEntry(PurchaseHeader."Buy-from Vendor No.", SignForVendorLedgerEntry * PurchaseLine."Line Amount");
    end;

    local procedure UpdateGenJnlLineAppln(var GenJournalLine: Record "Gen. Journal Line"; CurrencyCode: Code[10]; AmountToApply: Decimal)
    begin
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Validate(Amount, AmountToApply);
        GenJournalLine.Validate("Applies-to ID", GenJournalLine."Document No.");
        GenJournalLine.Modify(true);
    end;

    local procedure UpdateVendorLedgerEntryAppln(var VendorLedgerEntry: Record "Vendor Ledger Entry"; DocumentNo: Code[20]; AmountToApply: Decimal)
    begin
        VendorLedgerEntry.Validate("Applies-to ID", DocumentNo);
        VendorLedgerEntry.Validate("Amount to Apply", AmountToApply);
        VendorLedgerEntry.Modify(true);
    end;

    local procedure UpdateApplnBetweenCurrenciesNoneInPurchSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Appln. between Currencies", PurchasesPayablesSetup."Appln. between Currencies"::None);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure UpdateApplnBetweenCurrenciesAllInPurchSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Appln. between Currencies", PurchasesPayablesSetup."Appln. between Currencies"::All);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure ValidateVendLedgEntrClosed(VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        // Update record to reflect changes done by codeunit.
        VendorLedgerEntry.Get(VendorLedgerEntry."Entry No.");
        VendorLedgerEntry.CalcFields(Amount, "Remaining Amount");
        // Check that the invoice closed and has no remaining amount.
        Assert.IsFalse(VendorLedgerEntry.Open, InvoiceError);
        Assert.IsTrue(VendorLedgerEntry."Remaining Amount" = 0.0, 'Invoice has remaining amount');
    end;

    local procedure VerifyDiscountValueInVendorLedger(GenJournalLine: Record "Gen. Journal Line"; PmtDiscountAmount: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document No.");
        Assert.AreNearlyEqual(PmtDiscountAmount, VendorLedgerEntry."Original Pmt. Disc. Possible", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, Round(PmtDiscountAmount, LibraryERM.GetAmountRoundingPrecision()), PmtDiscountAmount));
        VendorLedgerEntry.TestField("Remaining Pmt. Disc. Possible", VendorLedgerEntry."Original Pmt. Disc. Possible");
    end;

    local procedure VerifyGLEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, Amount);
    end;

    local procedure VerifyVendorLedgerEntry(VendorNo: Code[20]; RemainingAmount: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.FindSet();
        VendorLedgerEntry.CalcFields("Remaining Amount");
        repeat
            VendorLedgerEntry.TestField("Remaining Amount", RemainingAmount);
        until VendorLedgerEntry.Next() = 0;
    end;

    local procedure SetApplicationMethodOnVendor(VendorNo: Code[20]; ApplicationMethod: Enum "Application Method")
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        Vendor.Validate("Application Method", ApplicationMethod);
        Vendor.Modify(true);
    end;

    local procedure VerifyExtDocNoAmount(GenJournalLine: Record "Gen. Journal Line"; ExpectedExtDocNo: Code[35]; ExpectedAmount: Decimal)
    begin
        GenJournalLine.Find();
        Assert.AreEqual(
          ExpectedExtDocNo, GenJournalLine."Applies-to Ext. Doc. No.",
          StrSubstNo(WrongValErr, GenJournalLine.FieldCaption("Applies-to Ext. Doc. No."), ExpectedExtDocNo, GenJournalLine.TableCaption));
        Assert.AreEqual(
          ExpectedAmount, GenJournalLine.Amount,
          StrSubstNo(WrongValErr, GenJournalLine.FieldCaption(Amount), ExpectedAmount, GenJournalLine.TableCaption));
    end;

    local procedure VerifyPaymentWithDetailedEntries(VendorNo: Code[20]; CurrencyCode: Code[10]; EntryNoInvoice1: Integer; EntryNoInvoice2: Integer; AppliedEntries1: Integer; AppliedEntries2: Integer)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetRange("Currency Code", CurrencyCode);
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Payment);
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.CalcFields("Remaining Amount");
        VendorLedgerEntry.TestField("Remaining Amount", 0);

        DetailedVendorLedgEntry.SetRange("Vendor No.", VendorNo);
        DetailedVendorLedgEntry.SetRange("Applied Vend. Ledger Entry No.", VendorLedgerEntry."Entry No.");
        DetailedVendorLedgEntry.SetRange("Vendor Ledger Entry No.", EntryNoInvoice1);
        Assert.RecordCount(DetailedVendorLedgEntry, AppliedEntries1);
        DetailedVendorLedgEntry.SetRange("Vendor Ledger Entry No.", EntryNoInvoice2);
        Assert.RecordCount(DetailedVendorLedgEntry, AppliedEntries2);
    end;

    local procedure CreateAndPostGenJournalLine(Vendor: Record Vendor; BankAccount: Record "Bank Account"; Amount: Decimal)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine,
            GenJournalTemplate.Name,
            GenJournalBatch.Name,
            GenJournalLine."Document Type"::Payment,
            GenJournalLine."Account Type"::Vendor,
            Vendor."No.",
            Amount);

        GenJournalLine.Validate("Currency Code", BankAccount."Currency Code");
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", BankAccount."No.");
        GenJournalLine.Validate("Bank Payment Type", GenJournalLine."Bank Payment Type"::"Manual Check");
        GenJournalLine.Modify(true);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure VoidCheck(DocumentNo: Code[20])
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
        CheckManagement: Codeunit CheckManagement;
        ConfirmFinancialVoid: Page "Confirm Financial Void";
    begin
        CheckLedgerEntry.SetRange("Document No.", DocumentNo);
        CheckLedgerEntry.FindFirst();
        CheckManagement.FinancialVoidCheck(CheckLedgerEntry);
        ConfirmFinancialVoid.SetCheckLedgerEntry(CheckLedgerEntry);
    end;

    local procedure CreateCurrencyCode(): Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Currency: Record Currency;
    begin
        GeneralLedgerSetup.Get();

        LibraryERM.CreateCurrency(Currency);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
        Currency.Validate("Invoice Rounding Precision", GeneralLedgerSetup."Inv. Rounding Precision (LCY)");
        Currency.Validate("EMU Currency", true);
        Currency.Modify(true);

        LibraryERM.CreateRandomExchangeRate(Currency.Code);

        exit(Currency.Code);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyVendorEntriesModalPageHandler(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    begin
        ApplyVendorEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyVendorEntriesWithSetAppliesToIDModalPageHandler(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    begin
        ApplyVendorEntries.ActionSetAppliesToID.Invoke();
        ApplyVendorEntries.AppliedAmount.AssertEquals(LibraryVariableStorage.DequeueDecimal());

        ApplyVendorEntries.AppliesToID.SetValue('');
        ApplyVendorEntries.AppliedAmount.AssertEquals(0);
        ApplyVendorEntries."Amount to Apply".AssertEquals(0);
        ApplyVendorEntries.ApplnAmountToApply.AssertEquals(0);

        ApplyVendorEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyVendorEntriesWithAmountModalPageHandler(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    begin
        ApplyVendorEntries.FILTER.SetFilter("Document No.", LibraryVariableStorage.DequeueText());
        ApplyVendorEntries.ActionSetAppliesToID.Invoke();
        ApplyVendorEntries."Amount to Apply".SetValue(LibraryVariableStorage.DequeueDecimal());
        ApplyVendorEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure MultipleSelectionApplyVendorEntriesModalPageHandler(var ApplyVendorEntries: Page "Apply Vendor Entries"; var Response: Action)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Vendor No.", LibraryVariableStorage.DequeueText());
        ApplyVendorEntries.CheckVendLedgEntry(VendorLedgerEntry);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TwoApplyVendorEntriesModalPageHandler(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    var
        AppliesToID: Code[20];
    begin
        ApplyVendorEntries.ActionSetAppliesToID.Invoke();
        AppliesToID := ApplyVendorEntries.AppliesToID.Value();

        ApplyVendorEntries.Next();
        ApplyVendorEntries.ActionSetAppliesToID.Invoke();
        ApplyVendorEntries.AppliesToID.SetValue('');
        ApplyVendorEntries.AppliesToID.AssertEquals('');

        ApplyVendorEntries.Previous();
        ApplyVendorEntries.AppliesToID.AssertEquals(AppliesToID);

        ApplyVendorEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TwoEntriesWithSameAppliesToIDModalPageHandler(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    var
        AppliesToID: Code[20];
    begin
        ApplyVendorEntries.ActionSetAppliesToID.Invoke();
        AppliesToID := ApplyVendorEntries.AppliesToID.Value();

        ApplyVendorEntries.Next();
        ApplyVendorEntries.AppliesToID.SetValue(AppliesToID);
        ApplyVendorEntries.AppliesToID.AssertEquals(AppliesToID);

        ApplyVendorEntries.Previous();
        ApplyVendorEntries.AppliesToID.AssertEquals(AppliesToID);

        ApplyVendorEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TwoEntriesWithDifferentAppliesToIDModalPageHandler(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    var
        AppliesToID: Code[20];
        AlternativeAppliesToID: Code[20];
    begin
        ApplyVendorEntries.ActionSetAppliesToID.Invoke();
        AppliesToID := ApplyVendorEntries.AppliesToID.Value();

        ApplyVendorEntries.Next();
        AlternativeAppliesToID := LibraryUtility.GenerateGUID();
        ApplyVendorEntries.AppliesToID.SetValue(AlternativeAppliesToID);

        ApplyVendorEntries.Previous();
        ApplyVendorEntries.AppliesToID.AssertEquals(AppliesToID);

        ApplyVendorEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GeneralJournalTemplateListPageHandler(var GeneralJournalTemplateList: TestPage "General Journal Template List")
    begin
        GeneralJournalTemplateList.GotoKey(LibraryVariableStorage.DequeueText());
        GeneralJournalTemplateList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyVendorEntriesWithAppliesToIDModalPageHandler(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DocNo: Text;
    begin
        DocNo := LibraryVariableStorage.DequeueText();
        ApplyVendorEntries.FILTER.SetFilter("Document No.", DocNo);
        ApplyVendorEntries.ActionSetAppliesToID.Invoke();
        ApplyVendorEntries."Amount to Apply".SetValue(LibraryVariableStorage.DequeueDecimal());
        ApplyVendorEntries.OK().Invoke();
        VendorLedgerEntry.SetRange("Document No.", DocNo);
        VendorLedgerEntry.FindFirst();
        LibraryVariableStorage.Enqueue(VendorLedgerEntry."Entry No.");
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReverseTransactionEntriesPageHandler(var ReverseTransactionEntries: TestPage "Reverse Transaction Entries")
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VoidCheckPageHandler(var ConfirmFinancialVoid: Page "Confirm Financial Void"; var Response: Action)
    var
        VoidTypeVariant: Variant;
    begin
        LibraryVariableStorage.Dequeue(VoidTypeVariant);
        ConfirmFinancialVoid.InitializeRequest(WorkDate(), VoidTypeVariant);
        Response := ACTION::Yes
    end;
}

