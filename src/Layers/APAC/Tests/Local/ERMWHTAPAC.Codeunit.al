codeunit 141014 "ERM WHT - APAC"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [WHT]
    end;

    var
        Assert: Codeunit Assert;
        LibraryAPACLocalization: Codeunit "Library - APAC Localization";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        ValueMustBeSameMsg: Label 'Value must be same.';
        LibraryJournals: Codeunit "Library - Journals";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        WHTAccountCodeEmptyErr: Label '%1 must have a value in WHT Posting Setup: WHT Business Posting Group=%2, WHT Product Posting Group=%3. It cannot be zero or empty.';
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure WHTEntryOfPostedInvoiceJnlAndPaymentJnl()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        VATPostingSetup: Record "VAT Posting Setup";
        WHTEntry: Record "WHT Entry";
        WHTPostingSetup: Record "WHT Posting Setup";
        DocumentNo: Code[20];
        WHTAmount: Decimal;
    begin
        // [SCENARIO] WHT Entry Amount after post a Purchase transaction through Purchase Journals then make payment.

        // [GIVEN] Create and Post Purchase Journal with Document Type - Invoice, Create and Post Payment Journal.
        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateGeneralJournalLineWithBalAccountType(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, CreateVendor(VATPostingSetup."VAT Bus. Posting Group", ''), '',
          '', GenJournalLine."Bal. Account Type"::"G/L Account", CreateGLAccountWithVATBusPostingGroup(VATPostingSetup),
          -LibraryRandom.RandDecInRange(100, 200, 2));  // Blank - WHT Bus Posting Group, Applies To Doc. No, Currency, Random - Direct unit cost.
        UpdateGenJournalLineWHTAbsorbBase(GenJournalLine);
        FindWHTPostingSetup(WHTPostingSetup, GenJournalLine."WHT Business Posting Group", GenJournalLine."WHT Product Posting Group", '');  // Blank Currency Code.
        WHTAmount := GenJournalLine."WHT Absorb Base" * WHTPostingSetup."WHT %" / 100;
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        DocumentNo := FindVendorLedgerEntry(GenJournalLine."Account No.");
        LibraryERM.CreateBankAccount(BankAccount);
        CreateGeneralJournalLineWithBalAccountType(
          GenJournalLine2, GenJournalLine."Document Type"::Payment, GenJournalLine."Account No.", DocumentNo,
          '', GenJournalLine2."Bal. Account Type"::"Bank Account", BankAccount."No.", -FindVendorLedgerEntryAmount(DocumentNo));  // Currency - Blank.

        // Exercise.
        LibraryERM.PostGeneralJnlLine(GenJournalLine2);

        // [THEN] Verify WHT Entry - Amount and Unrealized Amount.
        VerifyWHTEntry(WHTEntry."Document Type"::Payment, GenJournalLine."Account No.", -WHTAmount, 0);  // Unrealized Amount - 0.
        VerifyWHTEntry(WHTEntry."Document Type"::Invoice, GenJournalLine."Account No.", 0, -WHTAmount);  // Amount - 0.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedMultipleInvoicesWithWHTMinInvAmtAndPayment()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        WHTPostingSetup: Record "WHT Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        PurchaseInvoiceStatistics: TestPage "Purchase Invoice Statistics";
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
    begin
        // [SCENARIO] WHT Entry Amount, after Posting two Purchase Invoices, having sum equal to WHT minimum invoice amount and apply a single payment entry with more than WHT minimum invoice amount.

        // [GIVEN] Create and Post two Purchase Order with WHT minimum invoice amount, Create and Post General Journal with WHT Minimum Invoice Amount for Posted Invoices.
        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        DocumentNo :=
          CreateAndPostPurchaseOrder(
            PurchaseLine, CreateVendor(VATPostingSetup."VAT Bus. Posting Group", ''), VATPostingSetup."VAT Prod. Posting Group",
            '', '', LibraryRandom.RandDecInRange(1, 5, 2));  // Blank - WHT Bus. Posting Group, WHT Prod. Posting Group, Currency,Random - Direct unit cost.
        DocumentNo2 :=
          CreateAndPostPurchaseOrder(
            PurchaseLine2, PurchaseLine."Buy-from Vendor No.", VATPostingSetup."VAT Prod. Posting Group",
            '', '', LibraryRandom.RandDecInRange(1, 5, 2));  // Blank - WHT Bus. Posting Group, WHT Prod. Posting Group, Currency,Random - Direct unit cost.
        WHTPostingSetup.Get(PurchaseLine."WHT Business Posting Group", PurchaseLine."WHT Product Posting Group");
        CreateAndPostGenJournalLineWithMultipleAppliesToDocNo(
          PurchaseLine2."Buy-from Vendor No.", DocumentNo, DocumentNo2, WHTPostingSetup."WHT Minimum Invoice Amount");
        PurchaseInvoiceStatistics.Trap();

        // Exercise.
        OpenStatisticsOnPostedPurchaseInvoicePage(PostedPurchaseInvoice, DocumentNo2);

        // [THEN] Verify Purchase Invoice Statistics Page, GST Purchase Entry with 0 value.
        VerifyPurchaseInvoiceStatisticsPage(PurchaseInvoiceStatistics, 0, 0);  // Remaining WHT Prepaid Amount and Paid WHT Prepaid Amount - 0.
        VerifyGSTPurchaseEntry(DocumentNo);
    end;

    [Test]
    [HandlerFunctions('CalcAndPostWHTSettlementRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostedPurchInvAndCalculatePostWHTSettlement()
    var
        GLAccount: Record "G/L Account";
        GLAccount2: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        WHTPostingSetup: Record "WHT Posting Setup";
        DocumentNo: Code[20];
        WHTAmount: Decimal;
        WHTRoundingAmount: Decimal;
    begin
        // [SCENARIO] WHT Settlement Amount, Create and Post Purchase Invoice and calculate and Post WHT Settlement.

        // [GIVEN] Create and Post Purchase Order, Create and Post General Journal with Applies To Document Number.
        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        UpdateSourceCodeSetupWHTSettlement();
        RunCalcAndPostWHTSettlement();
        DocumentNo :=
          CreateAndPostPurchaseOrder(
            PurchaseLine, CreateVendor(VATPostingSetup."VAT Bus. Posting Group", ''), VATPostingSetup."VAT Prod. Posting Group",
            '', '', LibraryRandom.RandDecInRange(1000, 10000, 2));  // Blank - WHT Bus. Posting Group, WHT Prod. Posting Group, Currency, Random - Direct unit cost.
        WHTPostingSetup.Get(PurchaseLine."WHT Business Posting Group", PurchaseLine."WHT Product Posting Group");
        CreateAndPostGenJournalLine(PurchaseLine."Buy-from Vendor No.", '', DocumentNo, WorkDate(), -FindVendorLedgerEntryAmount(DocumentNo));  // Blank Currency Code.
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGLAccount(GLAccount2);

        // Exercise.
        RunReportCalcAndPostWHTSettlement(GLAccount."No.", GLAccount2."No.");  // Calculate and Post WHT Settlement for already exists entries on WORKDATE.

        // [THEN] Verify G/L Entry WHT Settlement Amount and WHT Rounding Amount.
        WHTAmount := FindVendorLedgerEntryAmount(DocumentNo) * WHTPostingSetup."WHT %" / 100;
        WHTRoundingAmount := WHTAmount - Round(WHTAmount, 1, '<');  // Rounded down to nearest whole value.
        VerifyGLEntry(GLEntry, GLAccount."No.", Round(WHTAmount, 1, '<'));  // Rounded down to nearest whole value.
        VerifyGLEntry(GLEntry, GLAccount2."No.", WHTRoundingAmount);
    end;

    [Test]
    [HandlerFunctions('CalcAndPostWHTSettlementRequestPageHandler,MessageHandler,BASUpdateRequestPageHandler')]
    [Scope('OnPrem')]
    procedure WithheldAmtOnBASCalculationSheet()
    var
        BASCalculationSheet: Record "BAS Calculation Sheet";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        WHTPostingSetup: Record "WHT Posting Setup";
        A1: Text[11];
        DocumentNo: Code[20];
        WHTAmount: Decimal;
    begin
        // [SCENARIO] Withheld Amount on BAS Calculation Sheet, Create and Post Purchase Invoice, make Payment.

        // [GIVEN] Create and Post Purchase Order, Create and Post General Journal with Applies To Document Number.
        Initialize();
        UpdateSourceCodeSetupWHTSettlement();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        RunCalcAndPostWHTSettlement();
        DocumentNo :=
          CreateAndPostPurchaseOrder(
            PurchaseLine, CreateVendor(VATPostingSetup."VAT Bus. Posting Group", ''), VATPostingSetup."VAT Prod. Posting Group",
            '', '', LibraryRandom.RandDecInRange(1000, 10000, 2));  // Blank - WHT Bus. Posting Group, WHT Prod. Posting Group, Currency, Random - Direct unit cost.
        WHTPostingSetup.Get(PurchaseLine."WHT Business Posting Group", PurchaseLine."WHT Product Posting Group");
        A1 := FindBASSetup(WHTPostingSetup."Payable WHT Account Code");
        CreateAndPostGenJournalLine(PurchaseLine."Buy-from Vendor No.", '', DocumentNo, WorkDate(), -FindVendorLedgerEntryAmount(DocumentNo));
        WHTAmount := FindVendorLedgerEntryAmount(DocumentNo) * WHTPostingSetup."WHT %" / 100;

        // Exercise.
        BASCalculationSheetInvokeActionUpdate(A1);

        // [THEN] Verify Amounts Withheld with W4 flow field on BAS Calculation Sheet.
        BASCalculationSheet.FindFirst();
        BASCalculationSheet.TestField(W4, Round(WHTAmount, 1, '<'));  // Rounded down to nearest whole value.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WHTEntryForPaymentWithManualApplication()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        WHTPostingSetup: Record "WHT Posting Setup";
        WHTEntry: Record "WHT Entry";
        CurrencyCode: Code[10];
        DocumentNo: Code[20];
        WHTAmount: Decimal;
    begin
        // [SCENARIO] posting of payment without applying it to the invoice and manually apply the invoice and payment entries will create correct WHT Entries.

        // [GIVEN] Create and Post Purchase Order, Create and Post Payment.
        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CurrencyCode := CreateCurrencyWithExchangeRate();
        CreateWHTPostingSetupWithPayableAccount(WHTPostingSetup, CurrencyCode);
        DocumentNo :=
          CreateAndPostPurchaseOrder(
            PurchaseLine, CreateVendor(VATPostingSetup."VAT Bus. Posting Group", WHTPostingSetup."WHT Business Posting Group"),
            VATPostingSetup."VAT Prod. Posting Group", WHTPostingSetup."WHT Product Posting Group", CurrencyCode,
            LibraryRandom.RandIntInRange(1000, 10000));  // Random - Direct unit cost.
        CreateGeneralJournalLineWithBalAccountType(
          GenJournalLine, GenJournalLine."Document Type"::Payment, PurchaseLine."Buy-from Vendor No.", '',
          CurrencyCode, GenJournalLine."Bal. Account Type"::"G/L Account", CreateGLAccountWithVATBusPostingGroup(VATPostingSetup),
          -FindVendorLedgerEntryAmount(DocumentNo));  // Blank - Balance Account No.
        GenJournalLine.Validate("WHT Product Posting Group", WHTPostingSetup."WHT Product Posting Group");
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        WHTAmount := -Round(GenJournalLine.Amount * WHTPostingSetup."WHT %" / 100);

        // Exercise: Apply Payment to Invoice.
        ApplyAndPostVendorEntryApplication(GenJournalLine."Document Type"::Payment, GenJournalLine."Document No.");

        // [THEN] Verify WHT Entires created for Payment and invoice.
        VerifyWHTEntry(WHTEntry."Document Type"::Payment, GenJournalLine."Account No.", -WHTAmount, 0);  // Unrealized Amount - 0.
        VerifyWHTEntry(WHTEntry."Document Type"::Invoice, GenJournalLine."Account No.", 0, -WHTAmount);  // Amount - 0.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WHTEntryForPaymentWithAppliesToDocument()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        PurchaseInvoiceStatistics: TestPage "Purchase Invoice Statistics";
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        WHTAmount: Decimal;
    begin
        // [SCENARIO] Amount on G/L Entry, Post purchase order with multiple line, Create General Journal Line and apply Posted Invoices.

        // [GIVEN] Create and Post purchase order with multiple lines, Create and Post General Journal Line - Applies To Document Number.
        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        WHTAmount :=
          CreatePurchaseOrderWithMultipleLines(
            PurchaseLine, VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", '');  // Blank as Currency.
        PurchaseHeader.Get(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");
        PurchaseHeader.CalcFields(Amount);
        DocumentNo := PostPurchaseDocument(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");
        DocumentNo2 :=
          CreateAndPostGenJournalLine(
            PurchaseLine."Buy-from Vendor No.", '', DocumentNo, WorkDate(), -FindVendorLedgerEntryAmount(DocumentNo));  // Blank as Currency, WorkDate() - Posting Date.
        Vendor.Get(PurchaseLine."Buy-from Vendor No.");
        VendorPostingGroup.Get(Vendor."Vendor Posting Group");
        PurchaseInvoiceStatistics.Trap();

        // Exercise.
        OpenStatisticsOnPostedPurchaseInvoicePage(PostedPurchaseInvoice, DocumentNo);

        // [THEN] Verify WHT Amount - Purchase Invoice Statistics Page and Amount on G/L Entries.
        VerifyPurchaseInvoiceStatisticsPage(PurchaseInvoiceStatistics, 0, WHTAmount);  // Remaining WHT Prepaid Amount - 0.
        VerifyAmountOnGLEntry(DocumentNo, VendorPostingGroup."Payables Account", -PurchaseHeader.Amount);
        VerifyAmountOnGLEntry(DocumentNo2, VendorPostingGroup."Payables Account", PurchaseHeader.Amount);
        PostedPurchaseInvoice.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WHTEntryForPartialPaymentsWithDiffAccounts()
    var
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        CurrencyCode: Code[10];
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        VendorNo: Code[20];
        GenJnlDocNo: array[4] of Code[20];
        Amount: Decimal;
        Amount2: Decimal;
        Amount3: Decimal;
    begin
        // [SCENARIO] WHT Amount, GST Entry for multiple partial payments to the invoices in different months.

        // [GIVEN] Create and Post multiple Purchase Orders, Create and Post multiple Payment Journal for partial payment.
        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CurrencyCode := CreateCurrencyWithExchangeRate();
        VendorNo := CreateVendor(VATPostingSetup."VAT Bus. Posting Group", '');  // Blank WHT Business Posting Group.
        DocumentNo :=
          CreateAndPostPurchaseOrder(
            PurchaseLine, VendorNo, VATPostingSetup."VAT Prod. Posting Group", '',
            CurrencyCode, LibraryRandom.RandIntInRange(1000, 10000));  // Blank - WHT Prod. Posting Group, Random - Direct unit cost.
        Amount := 10 * LibraryRandom.RandInt(10);  // Taking random Amount in multiple of 10.
        Amount2 := -PurchaseLine.Amount + Amount;  // Partial Amount.
        DocumentNo2 :=
          CreateAndPostPurchaseOrder(
            PurchaseLine, VendorNo, VATPostingSetup."VAT Prod. Posting Group", '',
            CurrencyCode, PurchaseLine.Amount + LibraryRandom.RandIntInRange(1100, 10000));  // Blank - WHT Prod. Posting Group, Random - Direct unit cost.
        Amount3 := -PurchaseLine.Amount + Amount;  // Partial Amount.

        // Exercise: Apply multiple Partial Payments for different Accounts of same Vendor.
        CreateAndPostMultiplePartialPayments(GenJnlDocNo, VendorNo, CurrencyCode, DocumentNo, DocumentNo2, Amount, Amount2, Amount3);

        // [THEN] Verify GST Purchase Entry, WHT Amounts with Currency and Vendor Ledger Entry closed for all the partial payments.
        VerifyGSTPurchaseEntry(DocumentNo);
        VerifyGSTPurchaseEntry(DocumentNo2);
        VerifyVendorLedgerEntryAndWHTAmount(GenJnlDocNo, VendorNo, CurrencyCode, Amount, Amount2, Amount3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchInvStatsWithMultipleLineAndDiffWHTPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        WHTEntry: Record "WHT Entry";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        PurchaseInvoiceStatistics: TestPage "Purchase Invoice Statistics";
        CurrencyCode: Code[10];
        DocumentNo: Code[20];
        Amount: Decimal;
        WHTAmount: Decimal;
    begin
        // [SCENARIO] WHT Amount on Purchase Invoice Statistics Page, Post purchase order with multiple lines and diffrent WHT Posting Setup, make Partial and full payment.

        // [GIVEN] Create and Post purchase order with multiple lines and diffrent WHT Posting Setup. Create and Post General Journal Line - Applies To Document Number with Partial payment and full payment.
        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CurrencyCode := CreateCurrencyWithExchangeRate();
        WHTAmount :=
          CreatePurchaseOrderWithMultipleLines(
            PurchaseLine, VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", CurrencyCode);
        DocumentNo := PostPurchaseDocument(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");
        Amount := LibraryRandom.RandIntInRange(100, 500);
        CreateAndPostGenJournalLineWithWHT(
          PurchaseLine, GenJournalLine."Document Type"::Payment, DocumentNo, CurrencyCode,
          CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate()), Amount);  // Random - Posting Date more than WORKDATE.
        CreateAndPostGenJournalLineWithWHT(
          PurchaseLine, GenJournalLine."Document Type"::Payment, DocumentNo, CurrencyCode,
          CalcDate('<' + Format(LibraryRandom.RandIntInRange(10, 20)) + 'D>', WorkDate()),
          -(FindVendorLedgerEntryAmount(DocumentNo) + Amount));  // Random - Posting Date more than WORKDATE.
        PurchaseInvoiceStatistics.Trap();

        // Exercise.
        OpenStatisticsOnPostedPurchaseInvoicePage(PostedPurchaseInvoice, DocumentNo);

        // [THEN] Verify Purchase Invoice Statistics Page and Number of created WHT Entry.
        VerifyPurchaseInvoiceStatisticsPage(PurchaseInvoiceStatistics, 0, Round(WHTAmount, LibraryERM.GetAmountRoundingPrecision()));  // Remaining WHT Prepaid Amount - 0.
        FilterOnWHTEntry(WHTEntry, WHTEntry."Document Type"::Payment, PurchaseLine."Buy-from Vendor No.");
        Assert.AreEqual(6, WHTEntry.Count, ValueMustBeSameMsg);  // Six WHT Entry are created in Against of Posted Entries.
        PostedPurchaseInvoice.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostApplyPaymentsToWHTAndNormalInvoices()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        WHTPostingSetup: Record "WHT Posting Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        NormalGenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        NoSeriesBatch: Codeunit "No. Series - Batch";
        WHTBalAccountNo: Code[20];
        WHTPaymentNo: Code[20];
        TransactionNo: Integer;
    begin
        // [SCENARIO 377799] WHT Payment should be posted in one transaction if we have different Payment lines
        Initialize();

        // [GIVEN] Purchase WHT Invoice = "Inv1"
        UpdateGLSetupAndPurchasesPayablesSetup(VATPostingSetup);
        CreateAndPostVendorInvoice(GenJournalLine, CreateVendor(VATPostingSetup."VAT Bus. Posting Group", ''));
        FindWHTPostingSetup(
          WHTPostingSetup, GenJournalLine."WHT Business Posting Group", GenJournalLine."WHT Product Posting Group", '');

        // [GIVEN] Normal Purchase Invoice = "Inv2"
        CreateAndPostVendorInvoice(NormalGenJournalLine, LibraryPurchase.CreateVendorNo());

        // [GIVEN] Use General Journal Batch with No. Series defined
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        GenJournalBatch.Validate("No. Series", LibraryERM.CreateNoSeriesCode());
        GenJournalBatch.Modify(true);

        // [GIVEN] Payment lines within the Batch for "Inv1" and "Inv2"
        CreateApplnVendorPayment(
          GenJournalLine, GenJournalBatch,
          GenJournalLine."Account Type", GenJournalLine."Account No.", -GenJournalLine.Amount,
          GenJournalLine."Applies-to Doc. Type"::Invoice, GenJournalLine."Document No.",
          NoSeriesBatch.GetNextNo(GenJournalBatch."No. Series"));
        WHTPaymentNo := GenJournalLine."Document No.";
        WHTBalAccountNo := GenJournalLine."Bal. Account No.";

        CreateApplnVendorPayment(
          GenJournalLine, GenJournalBatch,
          NormalGenJournalLine."Account Type", NormalGenJournalLine."Account No.", -NormalGenJournalLine.Amount,
          GenJournalLine."Applies-to Doc. Type"::Invoice, NormalGenJournalLine."Document No.",
          NoSeriesBatch.GetNextNo(GenJournalBatch."No. Series"));

        // [WHEN] Post Gen. Journal Lines
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Transaction No. for "Payable WHT Account Code" is equal to the Transaction No. of WHT Payment for "Inv1"
        GLEntry.SetRange("Document No.", WHTPaymentNo);
        GLEntry.SetRange("G/L Account No.", WHTBalAccountNo);
        GLEntry.FindFirst();
        TransactionNo := GLEntry."Transaction No.";

        GLEntry.SetRange("G/L Account No.", WHTPostingSetup."Payable WHT Account Code");
        GLEntry.FindFirst();
        GLEntry.TestField("Transaction No.", TransactionNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ConfirmErrorOnBlankWHTSetupPurchase()
    var
        PurchLine: Record "Purchase Line";
        WHTPostingSetup: Record "WHT Posting Setup";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 273872] Meaningful error trying posting purchase invoice with blanked Payable WHT Account Code
        Initialize();
        UpdateLocalFunctionalitiesOnGeneralLedgerSetup(false, true, false);

        // [GIVEN] WHT Setup with a blank payable accountCreateWHTPostingSetupWithBlankAccounts(WHTPostingSetup);
        CreateWHTPostingSetupWithBlankAccounts(WHTPostingSetup);

        // [WHEN] Post a purchase invoice with given WHT setup
        asserterror CreateAndPostPurchaseOrder(PurchLine, CreateVendor('', ''),
            CreateVATPostingSetupWithZeroVATPct(''), WHTPostingSetup."WHT Product Posting Group",
            '', LibraryRandom.RandDecInRange(1000, 2000, 2));

        // [THEN] 'Payable WHT Account Code must have a value in WHT Posting Setup' error appears
        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError(StrSubstNo(WHTAccountCodeEmptyErr,
            WHTPostingSetup.FieldCaption("Payable WHT Account Code"), '', WHTPostingSetup."WHT Product Posting Group"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ConfirmErrorOnBlankWHTSetupSales()
    var
        WHTPostingSetup: Record "WHT Posting Setup";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 273872] Meaningful error trying posting sales invoice with blanked Prepaid WHT Account Code
        Initialize();
        UpdateLocalFunctionalitiesOnGeneralLedgerSetup(false, true, false);
        // [GIVEN] WHT Setup with a blank prepaid account
        CreateWHTPostingSetupWithBlankAccounts(WHTPostingSetup);

        // [WHEN] Post a sales invoice with given WHT setup
        asserterror CreateAndPostSalesOrder(WHTPostingSetup."WHT Product Posting Group");

        // [THEN] 'Prepaid WHT Account Code must have a value in WHT Posting Setup' error appears
        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError(StrSubstNo(WHTAccountCodeEmptyErr,
            WHTPostingSetup.FieldCaption("Prepaid WHT Account Code"), '', WHTPostingSetup."WHT Product Posting Group"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WHTPostingSetupGetPrepaidWHTAccountUT()
    var
        WHTPostingSetup: Record "WHT Posting Setup";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 273872] WHT Posting Setup's functions GetPrepaidWHTAccount returns PrepaidWHTAccount or throws an error when empty
        Initialize();

        WHTPostingSetup.Init();
        asserterror WHTPostingSetup.GetPrepaidWHTAccount();
        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError(StrSubstNo(WHTAccountCodeEmptyErr,
            WHTPostingSetup.FieldCaption("Prepaid WHT Account Code"), '', WHTPostingSetup."WHT Product Posting Group"));

        WHTPostingSetup.Init();
        WHTPostingSetup."Prepaid WHT Account Code" := LibraryUtility.GenerateGUID();
        WHTPostingSetup."Payable WHT Account Code" := LibraryUtility.GenerateGUID();
        Assert.AreEqual(WHTPostingSetup."Prepaid WHT Account Code",
          WHTPostingSetup.GetPrepaidWHTAccount(), 'WHTPostingSetup.GetPrepaidWHTAccount returned wrong data');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WHTPostingSetupGetPayableWHTAccountUT()
    var
        WHTPostingSetup: Record "WHT Posting Setup";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 273872] WHT Posting Setup's functions GetPayableWHTAccount returns PayableWHTAccount or throws an error when empty
        Initialize();

        WHTPostingSetup.Init();
        asserterror WHTPostingSetup.GetPayableWHTAccount();
        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError(StrSubstNo(WHTAccountCodeEmptyErr,
            WHTPostingSetup.FieldCaption("Payable WHT Account Code"), '', WHTPostingSetup."WHT Product Posting Group"));

        WHTPostingSetup.Init();
        WHTPostingSetup."Prepaid WHT Account Code" := LibraryUtility.GenerateGUID();
        WHTPostingSetup."Payable WHT Account Code" := LibraryUtility.GenerateGUID();
        Assert.AreEqual(WHTPostingSetup."Payable WHT Account Code",
          WHTPostingSetup.GetPayableWHTAccount(), 'WHTPostingSetup.GetPayableWHTAccount returned wrong data');
    end;

    [Test]
    procedure JournalPostingNoSeriesLessThanNoSeriesOnePmtOneInv()
    var
        InvoiceGenJournalLine: Record "Gen. Journal Line";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // [FEATURE] [No. Series] [Journal] [Payment] [Purchase]
        // [SCENARIO 384295] Posting of one payment applied to one invoice with WHT in case of
        // [SCENARIO 384295] journal Posting No Series ("A..") goes before No. Series ("B..")
        Initialize();

        // [GIVEN] Posted purchase invoice with WHT
        CreateAndPostVendorInvoice(InvoiceGenJournalLine, CreateDefaultVendorNo());

        // [GIVEN] General Journal Batch with No. Series "B0..B9", Posting No. Series "A0..A9"
        CreateGenJournalBatchWithCustomNoSeries(GenJournalBatch, 'B0', 'B9', 'A0', 'A9');

        // [GIVEN] One payment applied to the posted invoice (journal Document No. = "B0")
        CreateOnePmtAppliedToOneInv(GenJournalLine, GenJournalBatch, InvoiceGenJournalLine, 'B0');

        // [WHEN] Post the payment journal
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Payment posting produced 3 G/L entries including 1 WHT with Document No. = "A0"
        VerifyPostingNoSeriesOnePostedDoc('A0', 3, 1);
    end;

    [Test]
    procedure JournalPostingNoSeriesMoreThanNoSeriesOnePmtOneInv()
    var
        InvoiceGenJournalLine: Record "Gen. Journal Line";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // [FEATURE] [No. Series] [Journal] [Payment] [Purchase]
        // [SCENARIO 384295] Posting of one payment applied to one invoice with WHT in case of
        // [SCENARIO 384295] journal Posting No Series ("B..") goes after No. Series ("A..")
        Initialize();

        // [GIVEN] Posted purchase invoice with WHT
        CreateAndPostVendorInvoice(InvoiceGenJournalLine, CreateDefaultVendorNo());

        // [GIVEN] General Journal Batch with No. Series "A0..A9", Posting No. Series "B0..B9"
        CreateGenJournalBatchWithCustomNoSeries(GenJournalBatch, 'A0', 'A9', 'B0', 'B9');

        // [GIVEN] One payment applied to the posted invoice (journal Document No. = "A0")
        CreateOnePmtAppliedToOneInv(GenJournalLine, GenJournalBatch, InvoiceGenJournalLine, 'A0');

        // [WHEN] Post the payment journal
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Payment posting produced 3 G/L entries including 1 WHT with Document No. = "B0"
        VerifyPostingNoSeriesOnePostedDoc('B0', 3, 1);
    end;

    [Test]
    procedure JournalPostingNoSeriesLessThanNoSeriesOnePmtTwoInv()
    var
        InvoiceGenJournalLine: array[2] of Record "Gen. Journal Line";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        VendorNo: Code[20];
    begin
        // [FEATURE] [No. Series] [Journal] [Payment] [Purchase]
        // [SCENARIO 384295] Posting of one payment applied to two invoices with WHT in case of
        // [SCENARIO 384295] journal Posting No Series ("A..") goes before No. Series ("B..")
        Initialize();

        // [GIVEN] Two posted purchase invoice with WHT
        VendorNo := CreateDefaultVendorNo();
        CreateAndPostVendorInvoice(InvoiceGenJournalLine[1], VendorNo);
        CreateAndPostVendorInvoice(InvoiceGenJournalLine[2], VendorNo);

        // [GIVEN] General Journal Batch with No. Series "B0..B9", Posting No. Series "A0..A9"
        CreateGenJournalBatchWithCustomNoSeries(GenJournalBatch, 'B0', 'B9', 'A0', 'A9');

        // [GIVEN] One payment applied to the both posted invoices (journal Document No. = "B0")
        CreateOnePmtAppliedToTwoInv(GenJournalLine, GenJournalBatch, InvoiceGenJournalLine, 'B0');

        // [WHEN] Post the payment journal
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Payment posting produced 4 G/L entries including 2 WHT with Document No. = "A0"
        VerifyPostingNoSeriesOnePostedDoc('A0', 4, 2);
    end;

    [Test]
    procedure JournalPostingNoSeriesMoreThanNoSeriesOnePmtTwoInv()
    var
        InvoiceGenJournalLine: array[2] of Record "Gen. Journal Line";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        VendorNo: Code[20];
    begin
        // [FEATURE] [No. Series] [Journal] [Payment] [Purchase]
        // [SCENARIO 384295] Posting of one payment applied to two invoices with WHT in case of
        // [SCENARIO 384295] journal Posting No Series ("B..") goes after No. Series ("A..")
        Initialize();

        // [GIVEN] Two posted purchase invoices with WHT
        VendorNo := CreateDefaultVendorNo();
        CreateAndPostVendorInvoice(InvoiceGenJournalLine[1], VendorNo);
        CreateAndPostVendorInvoice(InvoiceGenJournalLine[2], VendorNo);

        // [GIVEN] General Journal Batch with No. Series "A0..A9", Posting No. Series "B0..B9"
        CreateGenJournalBatchWithCustomNoSeries(GenJournalBatch, 'A0', 'A9', 'B0', 'B9');

        // [GIVEN] One payment applied to the both posted invoices (journal Document No. = "A0")
        CreateOnePmtAppliedToTwoInv(GenJournalLine, GenJournalBatch, InvoiceGenJournalLine, 'A0');

        // [WHEN] Post the payment journal
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Payment posting produced 4 G/L entries including 2 WHT with Document No. = "B0"
        VerifyPostingNoSeriesOnePostedDoc('B0', 4, 2);
    end;

    [Test]
    procedure JournalPostingNoSeriesLessThanNoSeriesTwoPmtTwoInvDiffDocNos()
    var
        InvoiceGenJournalLine: array[2] of Record "Gen. Journal Line";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // [FEATURE] [No. Series] [Journal] [Payment] [Purchase]
        // [SCENARIO 384295] Posting of two payments each applied to one invoice with WHT in case of
        // [SCENARIO 384295] journal Posting No Series ("A..") goes before No. Series ("B..") and different payment document numbers
        Initialize();

        // [GIVEN] Two posted purchase invoices with WHT
        CreateAndPostVendorInvoice(InvoiceGenJournalLine[1], CreateDefaultVendorNo());
        CreateAndPostVendorInvoice(InvoiceGenJournalLine[2], CreateDefaultVendorNo());

        // [GIVEN] General Journal Batch with No. Series "B0..B9", Posting No. Series "A0..A9"
        CreateGenJournalBatchWithCustomNoSeries(GenJournalBatch, 'B0', 'B9', 'A0', 'A9');

        // [GIVEN] Two payments each applied to one of the posted invoices (journal lines Document No. = "B0", "B1")
        CreateOnePmtAppliedToOneInv(GenJournalLine, GenJournalBatch, InvoiceGenJournalLine[1], 'B0');
        CreateOnePmtAppliedToOneInv(GenJournalLine, GenJournalBatch, InvoiceGenJournalLine[2], 'B1');

        // [WHEN] Post the payment journal
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Payment posting produced 6 G/L entries including 3 with Document No. = "A0", 3 with Document No. = "A1"
        VerifyPostingNoSeriesTwoPostedDocs('A0', 'A1');
    end;

    [Test]
    procedure JournalPostingNoSeriesMoreThanNoSeriesTwoPmtTwoInvDiffDocNos()
    var
        InvoiceGenJournalLine: array[2] of Record "Gen. Journal Line";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // [FEATURE] [No. Series] [Journal] [Payment] [Purchase]
        // [SCENARIO 384295] Posting of two payments each applied to one invoice with WHT in case of
        // [SCENARIO 384295] journal Posting No Series ("B..") goes after No. Series ("A..") and different payment document numbers
        Initialize();

        // [GIVEN] Two posted purchase invoices with WHT
        CreateAndPostVendorInvoice(InvoiceGenJournalLine[1], CreateDefaultVendorNo());
        CreateAndPostVendorInvoice(InvoiceGenJournalLine[2], CreateDefaultVendorNo());

        // [GIVEN] General Journal Batch with No. Series "A0..A9", Posting No. Series "B0..B9"
        CreateGenJournalBatchWithCustomNoSeries(GenJournalBatch, 'A0', 'A9', 'B0', 'B9');

        // [GIVEN] Two payments each applied to one of the posted invoices (journal lines Document No. = "A0", "A1")
        CreateOnePmtAppliedToOneInv(GenJournalLine, GenJournalBatch, InvoiceGenJournalLine[1], 'A0');
        CreateOnePmtAppliedToOneInv(GenJournalLine, GenJournalBatch, InvoiceGenJournalLine[2], 'A1');

        // [WHEN] Post the payment journal
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Payment posting produced 6 G/L entries including 3 with Document No. = "B0", 3 with Document No. = "B1"
        VerifyPostingNoSeriesTwoPostedDocs('B0', 'B1');
    end;

    [Test]
    procedure JournalPostingNoSeriesLessThanNoSeriesTwoPmtTwoInvSameDocNos()
    var
        InvoiceGenJournalLine: array[2] of Record "Gen. Journal Line";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // [FEATURE] [No. Series] [Journal] [Payment] [Purchase]
        // [SCENARIO 384295] Posting of two payments each applied to one invoice with WHT in case of
        // [SCENARIO 384295] journal Posting No Series ("A..") goes before No. Series ("B..") and the same payment document numbers
        Initialize();

        // [GIVEN] Two posted purchase invoices with WHT
        CreateAndPostVendorInvoice(InvoiceGenJournalLine[1], CreateDefaultVendorNo());
        CreateAndPostVendorInvoice(InvoiceGenJournalLine[2], CreateDefaultVendorNo());

        // [GIVEN] General Journal Batch with No. Series "B0..B9", Posting No. Series "A0..A9"
        CreateGenJournalBatchWithCustomNoSeries(GenJournalBatch, 'B0', 'B9', 'A0', 'A9');

        // [GIVEN] Two payments each applied to one of the posted invoices (journal lines Document No. = "B0", "B0")
        CreateOnePmtAppliedToOneInv(GenJournalLine, GenJournalBatch, InvoiceGenJournalLine[1], 'B0');
        CreateOnePmtAppliedToOneInv(GenJournalLine, GenJournalBatch, InvoiceGenJournalLine[2], 'B0');

        // [WHEN] Post the payment journal
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Payment posting produced 6 G/L entries including 2 WHT with Document No. = "A0"
        VerifyPostingNoSeriesOnePostedDoc('A0', 6, 2);
    end;

    [Test]
    procedure JournalPostingNoSeriesMoreThanNoSeriesTwoPmtTwoInvSameDocNos()
    var
        InvoiceGenJournalLine: array[2] of Record "Gen. Journal Line";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // [FEATURE] [No. Series] [Journal] [Payment] [Purchase]
        // [SCENARIO 384295] Posting of two payments each applied to one invoice with WHT in case of
        // [SCENARIO 384295] journal Posting No Series ("B..") goes after No. Series ("A..") and the same payment document numbers
        Initialize();

        // [GIVEN] Two posted purchase invoices with WHT
        CreateAndPostVendorInvoice(InvoiceGenJournalLine[1], CreateDefaultVendorNo());
        CreateAndPostVendorInvoice(InvoiceGenJournalLine[2], CreateDefaultVendorNo());

        // [GIVEN] General Journal Batch with No. Series "A0..A9", Posting No. Series "B0..B9"
        CreateGenJournalBatchWithCustomNoSeries(GenJournalBatch, 'A0', 'A9', 'B0', 'B9');

        // [GIVEN] Two payments each applied to one of the posted invoices (journal lines Document No. = "A0", "A0")
        CreateOnePmtAppliedToOneInv(GenJournalLine, GenJournalBatch, InvoiceGenJournalLine[1], 'A0');
        CreateOnePmtAppliedToOneInv(GenJournalLine, GenJournalBatch, InvoiceGenJournalLine[2], 'A0');

        // [WHEN] Post the payment journal
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Payment posting produced 6 G/L entries including 2 WHT with Document No. = "B0"
        VerifyPostingNoSeriesOnePostedDoc('B0', 6, 2);
    end;

    local procedure Initialize()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;
        IsInitialized := true;

        UpdateGLSetupAndPurchasesPayablesSetup(VATPostingSetup);

        LibrarySetupStorage.SavePurchasesSetup();
        LibrarySetupStorage.SaveGeneralLedgerSetup();
    end;

    local procedure ApplyVendorLedgerEntry(var ApplyingVendorLedgerEntry: Record "Vendor Ledger Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(ApplyingVendorLedgerEntry, DocumentType, DocumentNo);
        ApplyingVendorLedgerEntry.CalcFields("Remaining Amount");
        LibraryERM.SetApplyVendorEntry(ApplyingVendorLedgerEntry, ApplyingVendorLedgerEntry."Remaining Amount");

        // Find Posted Vendor Ledger Entries.
        VendorLedgerEntry.SetRange("Vendor No.", ApplyingVendorLedgerEntry."Vendor No.");
        VendorLedgerEntry.SetRange("Applying Entry", false);
        VendorLedgerEntry.FindFirst();

        // Set Applies-to ID.
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry);
    end;

    local procedure ApplyAndPostVendorEntryApplication(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        ApplyVendorLedgerEntry(VendorLedgerEntry, DocumentType, DocumentNo);
        LibraryERM.PostVendLedgerApplication(VendorLedgerEntry);
    end;

    local procedure BASCalculationSheetInvokeActionUpdate(A1: Text[80])
    var
        BASCalculationSheet: TestPage "BAS Calculation Sheet";
    begin
        BASCalculationSheet.OpenEdit();
        BASCalculationSheet.FILTER.SetFilter(A1, A1);
        BASCalculationSheet.Update.Invoke();  // Invoke handler - BASUpdateRequestPageHandler.
        BASCalculationSheet.Close();
    end;

    local procedure CreateAndPostGenJournalLine(AccountNo: Code[20]; CurrencyCode: Code[10]; AppliesToDocNo: Code[20]; PostingDate: Date; Amount: Decimal): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment, AccountNo, AppliesToDocNo, CurrencyCode, PostingDate, Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreateAndPostPurchaseOrder(var PurchaseLine: Record "Purchase Line"; VendorNo: Code[20]; VATProdPostingGroup: Code[20]; WHTProductPostingGroup: Code[20]; CurrencyCode: Code[10]; DirectUnitCost: Decimal): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        WHTPostingSetup: Record "WHT Posting Setup";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Modify(true);
        CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", CreateGLAccount(VATProdPostingGroup), DirectUnitCost);
        PurchaseLine.Validate("WHT Product Posting Group", WHTProductPostingGroup);
        PurchaseLine.Modify(true);
        FindWHTPostingSetup(
          WHTPostingSetup, PurchaseLine."WHT Business Posting Group", PurchaseLine."WHT Product Posting Group", CurrencyCode);
        exit(PostPurchaseDocument(PurchaseLine."Document Type"::Order, PurchaseLine."Document No."));
    end;

    local procedure CreateAndPostSalesOrder(WHTProductPostingGroup: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        WHTPostingSetup: Record "WHT Posting Setup";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithSalesSetup(), LibraryRandom.RandInt(10));
        SalesLine.Validate("WHT Product Posting Group", WHTProductPostingGroup);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));
        SalesLine.Modify(true);
        FindWHTPostingSetup(
          WHTPostingSetup, SalesLine."WHT Business Posting Group", SalesLine."WHT Product Posting Group", '');
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateBASSetup(AccountTotaling: Text[80]): Code[20]
    var
        BASSetup: Record "BAS Setup";
        BASSetupName: Record "BAS Setup Name";
        BASCalculationSheet: Record "BAS Calculation Sheet";
    begin
        LibraryAPACLocalization.CreateBASSetupName(BASSetupName);
        LibraryAPACLocalization.CreateBASSetup(BASSetup, BASSetupName.Name);
        BASSetup.Validate("Field No.", BASCalculationSheet.FieldNo(W4));
        BASSetup.Validate(Print, true);
        BASSetup.Validate("Account Totaling", AccountTotaling);
        BASSetup.Validate("Amount Type", BASSetup."Amount Type"::Amount);
        BASSetup.Modify(true);
        exit(BASSetup."Setup Name");
    end;

    local procedure CreateBASCalculationSheet(AccountTotaling: Text[80]): Code[11]
    var
        BASCalculationSheet: Record "BAS Calculation Sheet";
    begin
        LibraryAPACLocalization.CreateBASCalculationSheet(BASCalculationSheet);
        BASCalculationSheet.Validate(A3, WorkDate());
        BASCalculationSheet.Validate(A4, WorkDate());
        BASCalculationSheet.Validate(A5, WorkDate());
        BASCalculationSheet.Validate(A6, WorkDate());
        BASCalculationSheet.Validate(Exported, false);
        BASCalculationSheet.Validate("BAS Setup Name", CreateBASSetup(AccountTotaling));
        BASCalculationSheet.Modify(true);
        exit(BASCalculationSheet.A1);
    end;

    local procedure CreateGeneralJournalLineWithBalAccountType(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; AccountNo: Code[20]; AppliesToDocNo: Code[20]; CurrencyCode: Code[10]; BalAccountType: Enum "Gen. Journal Account Type"; BalAccountNo: Code[20]; Amount: Decimal)
    begin
        CreateGeneralJournalLine(GenJournalLine, DocumentType, AccountNo, AppliesToDocNo, CurrencyCode, WorkDate(), Amount);
        GenJournalLine.Validate("Bal. Account Type", BalAccountType);
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; AccountNo: Code[20]; AppliesToDocNo: Code[20]; CurrencyCode: Code[10]; PostingDate: Date; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Payments);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"Bank Account");
        GenJournalBatch.Validate("Bal. Account No.", BankAccount."No.");
        GenJournalBatch.Modify(true);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          DocumentType, GenJournalLine."Account Type"::Vendor, AccountNo, Amount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateAndPostGenJournalLineWithMultipleAppliesToDocNo(AccountNo: Code[20]; AppliesToDocNo: Code[20]; AppliesToDocNo2: Code[20]; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateGeneralJournalLine(GenJournalLine, GenJournalLine."Document Type"::Payment, AccountNo, AppliesToDocNo, '', WorkDate(), Amount);  // Currency - Blank.
        CreateGeneralJournalLine(GenJournalLine, GenJournalLine."Document Type"::Payment, AccountNo, AppliesToDocNo2, '', WorkDate(), Amount);  // Currency - Blank.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateGLAccount(VATProdPostingGroup: Code[20]): Code[20]
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.FindGenProductPostingGroup(GenProductPostingGroup);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Prod. Posting Group", GenProductPostingGroup.Code);
        GLAccount.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateGLAccountWithVATBusPostingGroup(VATPostingSetup: Record "VAT Posting Setup"): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get(CreateGLAccount(VATPostingSetup."VAT Prod. Posting Group"));
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("Gen. Posting Type", GLAccount."Gen. Posting Type"::Purchase);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateVendor(VATBusPostingGroup: Code[20]; WHTBusinessPostingGroup: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Vendor.Validate(ABN, '');
        Vendor.Validate("WHT Business Posting Group", WHTBusinessPostingGroup);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateDefaultVendorNo(): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        exit(CreateVendor(VATPostingSetup."VAT Bus. Posting Group", ''));
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; Type: Enum "Purchase Line Type"; No: Code[20]; DirectUnitCost: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, LibraryRandom.RandInt(5));  // Random Quantity.
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateVATPostingSetupWithZeroVATPct(VATBusPostingGroup: Code[20]): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroup, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT %", 0);
        VATPostingSetup.Modify(true);
        exit(VATPostingSetup."VAT Prod. Posting Group");
    end;

    local procedure CreateWHTPostingSetupWithPayableAccount(var WHTPostingSetup: Record "WHT Posting Setup"; CurrencyCode: Code[10])
    var
        WHTBusinessPostingGroup: Record "WHT Business Posting Group";
        WHTProductPostingGroup: Record "WHT Product Posting Group";
    begin
        LibraryAPACLocalization.CreateWHTBusinessPostingGroup(WHTBusinessPostingGroup);
        LibraryAPACLocalization.CreateWHTProductPostingGroup(WHTProductPostingGroup);
        CreateWHTPostingSetup(
          WHTPostingSetup, WHTBusinessPostingGroup.Code, WHTProductPostingGroup.Code,
          CurrencyCode, LibraryRandom.RandDecInRange(50, 100, 2));  // WHT Minimum Invoice Amount.
    end;

    local procedure CreateWHTPostingSetup(var WHTPostingSetup: Record "WHT Posting Setup"; WHTBusinessPostingGroup: Code[20]; WHTProductPostingGroup: Code[20]; CurrencyCode: Code[10]; WHTMinimumInvoiceAmount: Decimal)
    var
        BankAccount: Record "Bank Account";
        GLAccount: Record "G/L Account";
        WHTRevenueTypes: Record "WHT Revenue Types";
    begin
        LibraryAPACLocalization.CreateWHTPostingSetup(WHTPostingSetup, WHTBusinessPostingGroup, WHTProductPostingGroup);
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Currency Code", CurrencyCode);
        BankAccount.Modify(true);
        LibraryAPACLocalization.CreateWHTRevenueTypes(WHTRevenueTypes);
        WHTPostingSetup.Validate("Revenue Type", WHTRevenueTypes.Code);
        WHTPostingSetup.Validate("WHT %", LibraryRandom.RandInt(10));
        WHTPostingSetup.Validate("WHT Minimum Invoice Amount", WHTMinimumInvoiceAmount);
        WHTPostingSetup.Validate("Realized WHT Type", WHTPostingSetup."Realized WHT Type"::Payment);
        WHTPostingSetup.Validate("Prepaid WHT Account Code", GLAccount."No.");
        WHTPostingSetup.Validate("Payable WHT Account Code", WHTPostingSetup."Prepaid WHT Account Code");
        WHTPostingSetup.Validate("Purch. WHT Adj. Account No.", WHTPostingSetup."Prepaid WHT Account Code");
        WHTPostingSetup.Validate("Bal. Payable Account No.", BankAccount."No.");
        WHTPostingSetup.Modify(true);
    end;

    local procedure CreateWHTPostingSetupWithBlankAccounts(var WHTPostingSetup: Record "WHT Posting Setup")
    var
        WHTProdPostingGroup: Record "WHT Product Posting Group";
    begin
        LibraryAPACLocalization.CreateWHTProductPostingGroup(WHTProdPostingGroup);
        CreateWHTPostingSetup(WHTPostingSetup, '', WHTProdPostingGroup.Code, '', 0);
        WHTPostingSetup.Validate("Payable WHT Account Code", '');
        WHTPostingSetup.Validate("Prepaid WHT Account Code", '');
        WHTPostingSetup.Validate("Realized WHT Type", WHTPostingSetup."Realized WHT Type"::Invoice);
        WHTPostingSetup.Modify(true);
    end;

    local procedure CreateMultiplePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; VATProdPostingGroup: Code[20]) WHTAmount: Decimal
    var
        WHTBusinessPostingGroup: Record "WHT Business Posting Group";
    begin
        LibraryAPACLocalization.CreateWHTBusinessPostingGroup(WHTBusinessPostingGroup);
        CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine."Document Type"::Order, CreateGLAccount(VATProdPostingGroup),
          LibraryRandom.RandIntInRange(1000, 2000));  // Direct Unit Cost in Random Range.
        WHTAmount := UpdateWHTOnPurchaseLine(
            PurchaseLine, WHTBusinessPostingGroup.Code, PurchaseLine."Line Amount");
        CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", CreateGLAccount(VATProdPostingGroup),
          LibraryRandom.RandIntInRange(1000, 5000));  // Direct Unit Cost in Random Range.
        WHTAmount +=
          UpdateWHTOnPurchaseLine(PurchaseLine, WHTBusinessPostingGroup.Code, PurchaseLine."Line Amount");
        CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine."Document Type"::Order, CreateGLAccount(VATProdPostingGroup),
          LibraryRandom.RandIntInRange(5000, 10000));  // Direct Unit Cost in Random Range.
        WHTAmount +=
          UpdateWHTOnPurchaseLine(PurchaseLine, WHTBusinessPostingGroup.Code, PurchaseLine."Line Amount");
    end;

    local procedure CreatePurchaseOrderWithMultipleLines(var PurchaseLine: Record "Purchase Line"; VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; CurrencyCode: Code[10]) WHTAmount: Decimal
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor(VATBusPostingGroup, ''));  // Blank - WHT Business Posting Group
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Modify(true);
        WHTAmount := CreateMultiplePurchaseLine(PurchaseLine, PurchaseHeader, VATProdPostingGroup);
    end;

    local procedure CreateCurrencyWithExchangeRate(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
        Currency.Validate("Invoice Rounding Precision", LibraryERM.GetInvoiceRoundingPrecisionLCY());
        Currency.Validate("Residual Gains Account", Currency."Realized Gains Acc.");
        Currency.Validate("Residual Losses Account", Currency."Realized Losses Acc.");
        Currency.Modify(true);

        // Create Currency Exchange Rate.
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateAndPostMultiplePartialPayments(var GenJnlDocNo: array[4] of Code[20]; VendorNo: Code[20]; CurrencyCode: Code[10]; DocumentNo: Code[20]; DocumentNo2: Code[20]; Amount: Decimal; Amount2: Decimal; Amount3: Decimal)
    begin
        // Create and Post multiple Payment Journal for partial payment on variation of Posting Date.
        GenJnlDocNo[1] := CreateAndPostGenJournalLine(VendorNo, CurrencyCode, DocumentNo, CalcDate('<1M>', WorkDate()), -Amount2);
        GenJnlDocNo[2] := CreateAndPostGenJournalLine(VendorNo, CurrencyCode, DocumentNo2, CalcDate('<2M>', WorkDate()), -Amount3);
        GenJnlDocNo[3] := CreateAndPostGenJournalLine(VendorNo, CurrencyCode, DocumentNo, CalcDate('<3M>', WorkDate()), Amount);
        GenJnlDocNo[4] := CreateAndPostGenJournalLine(VendorNo, CurrencyCode, DocumentNo2, CalcDate('<4M>', WorkDate()), Amount);
    end;

    local procedure CreateAndPostGenJournalLineWithWHT(PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Gen. Journal Document Type"; AppliesToDocNo: Code[20]; CurrencyCode: Code[10]; PostingDate: Date; Amount: Decimal) DocumentNo: Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
        WHTPostingSetup: Record "WHT Posting Setup";
    begin
        CreateGeneralJournalLine(
          GenJournalLine, DocumentType, PurchaseLine."Buy-from Vendor No.", AppliesToDocNo, CurrencyCode, PostingDate, Amount);
        FindWHTPostingSetup(WHTPostingSetup, PurchaseLine."WHT Business Posting Group", PurchaseLine."WHT Product Posting Group", '');  // Currency Code - Blank.
        GenJournalLine.Validate("WHT Business Posting Group", WHTPostingSetup."WHT Business Posting Group");
        GenJournalLine.Validate("WHT Product Posting Group", WHTPostingSetup."WHT Product Posting Group");
        GenJournalLine.Modify(true);
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostVendorInvoice(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20]): Code[20]
    begin
        CreateGeneralJournalLineWithBalAccountType(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, VendorNo, '',
          '', GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(),
          -LibraryRandom.RandDecInRange(100, 200, 2));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreateApplnVendorPayment(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; ApplyAmount: Decimal; ApplyToDocType: Enum "Gen. Journal Account Type"; ApplyToDocNo: Code[20]; DocumentNo: Code[20])
    begin
        LibraryJournals.CreateGenJournalLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, AccountType, AccountNo,
          GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(),
          ApplyAmount);
        GenJournalLine.Validate("Document No.", DocumentNo);
        GenJournalLine.Validate("Applies-to Doc. Type", ApplyToDocType);
        GenJournalLine.Validate("Applies-to Doc. No.", ApplyToDocNo);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateOnePmtAppliedToOneInv(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; InvoiceJournalLine: Record "Gen. Journal Line"; DocumentNo: Code[20])
    begin
        LibraryJournals.CreateGenJournalLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, InvoiceJournalLine."Account Type", InvoiceJournalLine."Account No.",
          GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), -InvoiceJournalLine.Amount);
        GenJournalLine.Validate("Document No.", DocumentNo);
        GenJournalLine.Validate("Applies-to Doc. Type", InvoiceJournalLine."Document Type");
        GenJournalLine.Validate("Applies-to Doc. No.", InvoiceJournalLine."Document No.");
        GenJournalLine.Modify(true);
    end;

    local procedure CreateOnePmtAppliedToTwoInv(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; InvoiceJournalLine: array[2] of Record "Gen. Journal Line"; DocumentNo: Code[20])
    begin
        LibraryJournals.CreateGenJournalLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, InvoiceJournalLine[1]."Account No.",
          GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(),
          -(InvoiceJournalLine[1].Amount + InvoiceJournalLine[2].Amount));
        GenJournalLine.Validate("Document No.", DocumentNo);
        GenJournalLine.Validate("Applies-to ID", LibraryUtility.GenerateGUID());
        GenJournalLine.Modify(true);

        SetAppliesToIDVendorLedgerEntry(InvoiceJournalLine[1]."Document No.", GenJournalLine."Applies-to ID");
        SetAppliesToIDVendorLedgerEntry(InvoiceJournalLine[2]."Document No.", GenJournalLine."Applies-to ID");
    end;

    local procedure CreateGenJournalBatchWithCustomNoSeries(var GenJournalBatch: Record "Gen. Journal Batch"; NoSeriesStartingNo: Code[20]; NoSeriesEndingNo: Code[20]; PostingNoSeriesStartingNo: Code[20]; PostingNoSeriesEndingNo: Code[20])
    begin
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        GenJournalBatch.Validate("No. Series", CreateCustomNoSeries(NoSeriesStartingNo, NoSeriesEndingNo));
        GenJournalBatch.Validate("Posting No. Series", CreateCustomNoSeries(PostingNoSeriesStartingNo, PostingNoSeriesEndingNo));
        GenJournalBatch.Modify(true);
    end;

    local procedure CreateCustomNoSeries(StartingNo: Code[20]; EndingNo: Code[20]): Code[20];
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        LibraryUtility.CreateNoSeries(NoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, StartingNo, EndingNo);
        exit(NoSeries.Code);
    end;

    local procedure SetAppliesToIDVendorLedgerEntry(DocumentNo: Code[20]; AppliesToID: Code[50])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, DocumentNo);
        VendorLedgerEntry.Validate("Applies-to ID", AppliesToID);
        VendorLedgerEntry.CalcFields("Remaining Amount");
        VendorLedgerEntry.Validate("Amount to Apply", VendorLedgerEntry."Remaining Amount");
        VendorLedgerEntry.Modify();
    end;

    local procedure FindBASSetup(AccountTotaling: Text[80]): Code[11]
    var
        BASSetup: Record "BAS Setup";
    begin
        // Enable test cases in NZ, Create BAS Setup And BAS Calculation Sheet.
        if not BASSetup.FindFirst() then
            exit(CreateBASCalculationSheet(AccountTotaling));
        exit(UpdateBASSetupAndBASCalculationSheet(AccountTotaling));
    end;

    local procedure SelectBASSetup(var BASSetup: Record "BAS Setup")
    var
        BASCalculationSheet: Record "BAS Calculation Sheet";
    begin
        BASSetup.SetRange("Field Label No.", BASCalculationSheet.FieldCaption(W4));
        BASSetup.FindFirst();
    end;

    local procedure FilterOnWHTEntry(var WHTEntry: Record "WHT Entry"; DocumentType: Enum "Gen. Journal Document Type"; BillToPayToNo: Code[20])
    begin
        WHTEntry.SetRange("Document Type", DocumentType);
        WHTEntry.SetRange("Bill-to/Pay-to No.", BillToPayToNo);
    end;

    local procedure FindWHTPostingSetup(var WHTPostingSetup: Record "WHT Posting Setup"; WHTBusinessPostingGroup: Code[20]; WHTProductPostingGroup: Code[20]; CurrencyCode: Code[10])
    begin
        // Enable test cases in NZ, create WHT Posting Setup.
        if not WHTPostingSetup.Get(WHTBusinessPostingGroup, WHTProductPostingGroup) then
            CreateWHTPostingSetup(WHTPostingSetup, WHTBusinessPostingGroup,
              WHTProductPostingGroup, CurrencyCode, LibraryRandom.RandDecInRange(50, 100, 2));  // WHT Minimum Invoice Amount.
    end;

    local procedure FindVendorLedgerEntry(VendorNo: Code[20]): Code[20]
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Invoice);
        VendorLedgerEntry.FindFirst();
        exit(VendorLedgerEntry."Document No.");
    end;

    local procedure FindVendorLedgerEntryAmount(DocumentNo: Code[20]): Decimal
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, DocumentNo);
        VendorLedgerEntry.CalcFields(Amount);
        exit(VendorLedgerEntry.Amount);
    end;

    local procedure OpenStatisticsOnPostedPurchaseInvoicePage(var PostedPurchaseInvoice: TestPage "Posted Purchase Invoice"; No: Code[20])
    begin
        PostedPurchaseInvoice.OpenEdit();
        PostedPurchaseInvoice.FILTER.SetFilter("No.", No);
        PostedPurchaseInvoice.Statistics.Invoke();  // Open Statistics Page.
    end;

    local procedure PostPurchaseDocument(DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Get(DocumentType, DocumentNo);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure RunCalcAndPostWHTSettlement()
    var
        WHTEntry: Record "WHT Entry";
    begin
        if WHTEntry.FindFirst() then  // Enable test cases in NZ.
            RunReportCalcAndPostWHTSettlement(CreateGLAccount(''), CreateGLAccount(''));  // Blank VAT Product Posting Group, Calculate and Post WHT Settlement for already exists entries on WORKDATE.
    end;

    local procedure RunReportCalcAndPostWHTSettlement(SettlementAccount: Code[20]; RoundAccNo: Code[20])
    var
        WHTPostingSetup: Record "WHT Posting Setup";
        CalcAndPostWHTSettlement: Report "Calc. and Post WHT Settlement";
    begin
        LibraryVariableStorage.Enqueue(SettlementAccount);
        LibraryVariableStorage.Enqueue(RoundAccNo);
        FindWHTPostingSetup(WHTPostingSetup, '', '', '');  // Blank - WHT product posting Group, WHT Business Posting Group, Currency Code.
        WHTPostingSetup.SetRange("WHT Business Posting Group", '');
        WHTPostingSetup.SetRange("WHT Product Posting Group", '');
        CalcAndPostWHTSettlement.SetTableView(WHTPostingSetup);
        Commit();  // Commit required.
        CalcAndPostWHTSettlement.Run();  // Opens handler - CalcAndPostWHTSettlementRequestPageHandler.
    end;

    local procedure UpdateBASSetupAndBASCalculationSheet(AccountTotaling: Text[80]): Code[11]
    var
        BASSetup: Record "BAS Setup";
        BASCalculationSheet: Record "BAS Calculation Sheet";
    begin
        SelectBASSetup(BASSetup);
        BASSetup.Validate("Account Totaling", AccountTotaling);
        BASSetup.Modify(true);
        BASCalculationSheet.FindFirst();
        BASCalculationSheet.Validate(A3, WorkDate());
        BASCalculationSheet.Validate(A4, WorkDate());
        BASCalculationSheet.Validate(A5, WorkDate());
        BASCalculationSheet.Validate(A6, WorkDate());
        BASCalculationSheet.Validate(Exported, false);
        BASCalculationSheet.Modify(true);
        exit(BASCalculationSheet.A1);
    end;

    local procedure UpdateGenJournalLineWHTAbsorbBase(var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine.Validate("WHT Absorb Base", -LibraryRandom.RandDecInRange(10, 50, 2));
        GenJournalLine.Validate("Bal. Gen. Posting Type", GenJournalLine."Gen. Posting Type"::Purchase);
        GenJournalLine.Modify(true);
    end;

    local procedure UpdateLocalFunctionalitiesOnGeneralLedgerSetup(EnableGST: Boolean; EnableWHT: Boolean; GSTReport: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Enable GST (Australia)", EnableGST);
        GeneralLedgerSetup.Validate("Enable WHT", EnableWHT);
        GeneralLedgerSetup.Validate("GST Report", GSTReport);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateGSTProdPostingGroupOnPurchasesSetup(GSTProdPostingGroup: Code[20]) OldGSTProdPostingGroup: Code[20]
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        OldGSTProdPostingGroup := PurchasesPayablesSetup."GST Prod. Posting Group";
        PurchasesPayablesSetup.Validate("GST Prod. Posting Group", GSTProdPostingGroup);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure UpdateGLSetupAndPurchasesPayablesSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        UpdateLocalFunctionalitiesOnGeneralLedgerSetup(true, true, true);  // Enable GST (Australia),Enable WHT and GST Report as True.
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        UpdateGSTProdPostingGroupOnPurchasesSetup(CreateVATPostingSetupWithZeroVATPct(VATPostingSetup."VAT Bus. Posting Group"));
    end;

    local procedure UpdateSourceCodeSetupWHTSettlement()
    var
        SourceCodeSetup: Record "Source Code Setup";
        SourceCode: Record "Source Code";
    begin
        SourceCodeSetup.Get();
        LibraryERM.CreateSourceCode(SourceCode);
        SourceCodeSetup.Validate("WHT Settlement", SourceCode.Code);
        SourceCodeSetup.Modify(true);
    end;

    local procedure UpdateWHTOnPurchaseLine(PurchaseLine: Record "Purchase Line"; WHTBusinessPostingGroup: Code[20]; Amount: Decimal): Decimal
    var
        WHTProductPostingGroup: Record "WHT Product Posting Group";
        WHTPostingSetup: Record "WHT Posting Setup";
    begin
        LibraryAPACLocalization.CreateWHTProductPostingGroup(WHTProductPostingGroup);
        CreateWHTPostingSetup(WHTPostingSetup, WHTBusinessPostingGroup, WHTProductPostingGroup.Code, '', 0);  // O as WHT Minimum Invoice Amount.
        PurchaseLine.Validate("WHT Business Posting Group", WHTPostingSetup."WHT Business Posting Group");
        PurchaseLine.Validate("WHT Product Posting Group", WHTPostingSetup."WHT Product Posting Group");
        PurchaseLine.Modify(true);
        exit(Amount * WHTPostingSetup."WHT %" / 100);
    end;

    local procedure VerifyGLEntry(var GLEntry: Record "G/L Entry"; GLAccountNo: Code[20]; Amount: Decimal)
    begin
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(Amount, GLEntry.Amount, LibraryERM.GetAmountRoundingPrecision(), ValueMustBeSameMsg);
    end;

    local procedure VerifyWHTEntry(DocumentType: Enum "Gen. Journal Document Type"; BillToPayToNo: Code[20]; Amount: Decimal; UnrealizedAmount: Decimal)
    var
        WHTEntry: Record "WHT Entry";
    begin
        WHTEntry.SetRange("Document Type", DocumentType);
        WHTEntry.SetRange("Bill-to/Pay-to No.", BillToPayToNo);
        WHTEntry.FindFirst();
        Assert.AreNearlyEqual(Amount, WHTEntry.Amount, LibraryERM.GetAmountRoundingPrecision(), ValueMustBeSameMsg);
        Assert.AreNearlyEqual(UnrealizedAmount, WHTEntry."Unrealized Amount", LibraryERM.GetAmountRoundingPrecision(), ValueMustBeSameMsg);
    end;

    local procedure VerifyPurchaseInvoiceStatisticsPage(PurchaseInvoiceStatistics: TestPage "Purchase Invoice Statistics"; RemWHTPrepaidAmount: Decimal; PaidWHTPrepaidAmount: Decimal)
    begin
        Assert.AreNearlyEqual(
          RemWHTPrepaidAmount, PurchaseInvoiceStatistics."Rem. WHT Prepaid Amount (LCY)".AsDecimal(),
          LibraryERM.GetAmountRoundingPrecision(), ValueMustBeSameMsg);
        Assert.AreNearlyEqual(
          PaidWHTPrepaidAmount, PurchaseInvoiceStatistics."Paid WHT Prepaid Amount (LCY)".AsDecimal(),
          LibraryERM.GetAmountRoundingPrecision(), ValueMustBeSameMsg);
        PurchaseInvoiceStatistics.OK().Invoke();
    end;

    local procedure VerifyGSTPurchaseEntry(DocumentNo: Code[20])
    var
        GSTPurchaseEntry: Record "GST Purchase Entry";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        // Verify GST Purchase Entry Created with Zero Amount.
        PurchasesPayablesSetup.Get();
        GSTPurchaseEntry.SetRange("Document No.", DocumentNo);
        GSTPurchaseEntry.SetRange("Document Line Type", GSTPurchaseEntry."Document Line Type"::"G/L Account");
        GSTPurchaseEntry.FindFirst();
        GSTPurchaseEntry.TestField("VAT Prod. Posting Group", PurchasesPayablesSetup."GST Prod. Posting Group");
        GSTPurchaseEntry.TestField(Amount, 0);
    end;

    local procedure VerifyAmountOnGLEntry(DocumentNo: Code[20]; GLAccountNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        VerifyGLEntry(GLEntry, GLAccountNo, Amount);
    end;

    local procedure VerifyWHTAmountWithCurrency(BillToPayToNo: Code[20]; CurrencyCode: Code[10]; OriginalDocumentNo: Code[20]; Amount: Decimal)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        WHTEntry: Record "WHT Entry";
        WHTPostingSetup: Record "WHT Posting Setup";
        WHTAmount: Decimal;
    begin
        WHTPostingSetup.Get('', '');  // Blank - WHT Product Posting Group, WHT Business Posting Group.
        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        CurrencyExchangeRate.FindFirst();
        WHTEntry.SetRange("Document Type", WHTEntry."Document Type"::Payment);
        WHTEntry.SetRange("Bill-to/Pay-to No.", BillToPayToNo);
        WHTEntry.SetRange("Original Document No.", OriginalDocumentNo);
        WHTEntry.FindFirst();
        WHTAmount :=
          Round(
            (Amount * WHTPostingSetup."WHT %" / 100) /
            (CurrencyExchangeRate."Exchange Rate Amount" / CurrencyExchangeRate."Relational Exch. Rate Amount"));
        Assert.AreNearlyEqual(WHTAmount, WHTEntry."Amount (LCY)", LibraryERM.GetAmountRoundingPrecision(), ValueMustBeSameMsg);
    end;

    local procedure VerifyClosedVendorLedgerEntry(DocumentNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Payment, DocumentNo);
        VendorLedgerEntry.TestField(Open, false);
    end;

    local procedure VerifyVendorLedgerEntryAndWHTAmount(DcoumentNo: array[4] of Code[20]; VendorNo: Code[20]; CurrencyCode: Code[10]; Amount: Decimal; Amount2: Decimal; Amount3: Decimal)
    begin
        VerifyWHTAmountWithCurrency(VendorNo, CurrencyCode, DcoumentNo[1], -Amount2);
        VerifyWHTAmountWithCurrency(VendorNo, CurrencyCode, DcoumentNo[2], -Amount3);
        VerifyWHTAmountWithCurrency(VendorNo, CurrencyCode, DcoumentNo[3], Amount);
        VerifyWHTAmountWithCurrency(VendorNo, CurrencyCode, DcoumentNo[4], Amount);
        VerifyClosedVendorLedgerEntry(DcoumentNo[1]);
        VerifyClosedVendorLedgerEntry(DcoumentNo[2]);
        VerifyClosedVendorLedgerEntry(DcoumentNo[3]);
        VerifyClosedVendorLedgerEntry(DcoumentNo[4]);
    end;

    local procedure VerifyPostingNoSeriesOnePostedDoc(PostedNo: Code[20]; GLEntryCount: Integer; WHTEntryCount: Integer)
    var
        GLEntry: Record "G/L Entry";
        WHTEntry: Record "WHT Entry";
        GLRegister: Record "G/L Register";
    begin
        GLRegister.FindLast();
        GLRegister.TestField("To Entry No.", GLRegister."From Entry No." + GLEntryCount - 1);

        WHTEntry.SetRange("Entry No.", GLRegister."From WHT Entry No.", GLRegister."To WHT Entry No.");
        Assert.RecordCount(WHTEntry, WHTEntryCount);

        GLEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        GLEntry.SetRange("Document No.", PostedNo);
        Assert.RecordCount(GLEntry, GLEntryCount);
    end;

    local procedure VerifyPostingNoSeriesTwoPostedDocs(PostedNo1: Code[20]; PostedNo2: Code[20])
    var
        GLEntry: Record "G/L Entry";
        WHTEntry: Record "WHT Entry";
        GLRegister: Record "G/L Register";
    begin
        GLRegister.FindLast();
        GLRegister.TestField("To Entry No.", GLRegister."From Entry No." + 5);

        WHTEntry.SetRange("Entry No.", GLRegister."From WHT Entry No.", GLRegister."To WHT Entry No.");
        Assert.RecordCount(WHTEntry, 2);

        GLEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        GLEntry.SetRange("Document No.", PostedNo1);
        Assert.RecordCount(GLEntry, 3);

        GLEntry.SetRange("Document No.", PostedNo2);
        Assert.RecordCount(GLEntry, 3);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BASUpdateRequestPageHandler(var BASUpdate: TestRequestPage "BAS-Update")
    var
        BASSetup: Record "BAS Setup";
        IncludeGSTEntries: Option Open;
        PeriodSelection: Enum "VAT Statement Report Period Selection";
    begin
        SelectBASSetup(BASSetup);
        BASUpdate.UpdateBASCalcSheet.SetValue(true);
        BASUpdate.IncludeGSTEntries.SetValue(IncludeGSTEntries::Open);
        BASUpdate.PeriodSelection.SetValue(PeriodSelection::"Within Period");
        BASUpdate."BAS Setup".SetFilter("Setup Name", BASSetup."Setup Name");
        BASUpdate.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalcAndPostWHTSettlementRequestPageHandler(var CalcAndPostWHTSettlement: TestRequestPage "Calc. and Post WHT Settlement")
    var
        RoundAccNo: Variant;
        SettlementAccount: Variant;
        SettlementAccountType: Option "G/L Account",Vendor;
    begin
        LibraryVariableStorage.Dequeue(SettlementAccount);
        LibraryVariableStorage.Dequeue(RoundAccNo);
        CalcAndPostWHTSettlement.StartingDate.SetValue(WorkDate());
        CalcAndPostWHTSettlement.EndingDate.SetValue(WorkDate());
        CalcAndPostWHTSettlement.PostingDate.SetValue(WorkDate());
        CalcAndPostWHTSettlement.DocumentNo.SetValue(SettlementAccount);
        CalcAndPostWHTSettlement.SettlementAccountType.SetValue(SettlementAccountType::"G/L Account");
        CalcAndPostWHTSettlement.SettlementAccount.SetValue(SettlementAccount);
        CalcAndPostWHTSettlement.RoundAccNo.SetValue(RoundAccNo);
        CalcAndPostWHTSettlement.ShowWHTEntries.SetValue(false);
        CalcAndPostWHTSettlement.Post.SetValue(true);
        CalcAndPostWHTSettlement.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}
