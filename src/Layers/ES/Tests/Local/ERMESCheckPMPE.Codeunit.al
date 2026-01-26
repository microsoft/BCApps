codeunit 144049 "ERM ES Check PMPE"
{
    // // [FEATURE] [Prompt Payment Law]
    // Test for feature - ES Check PMPE.
    //  1. Verify Posted Sales Credit Memo - Payment Discount Date with blank after changing the Posting Date, Create and Post Sales Credit Memo.
    //  2. Verify Posted Purchase Credit Memo - Payment Discount Date with blank after changing the Posting Date, Create and Post Purchase Credit Memo.
    //  3. Verify Weighted Exceeded Amount Open Payments outside the legal limit in the case of the Posted Purchase Invoice with fully payment.
    //  4. Verify Weighted Exceeded Amount Open Payments outside the legal limit in the case of the Posted Purchase Invoice with partial payment.
    //  5. Verify Weighted Exceeded Amount Open Payments outside the legal limit in the case of the Posted Sales Invoice with fully payment.
    //  6. Verify Weighted Exceeded Amount Open Payments outside the legal limit in the case of the Posted Sales Invoice with partial payment.
    //  7. Verify Unrealized VAT when apply Payment to Purchase Invoice and have another Purchase Invoice in the same transaction.
    //  8. Verify Unrealized VAT when apply Payment to Purchase Credit Memo and have another Purchase Credit Memo in the same transaction.
    //  9. Verify Unrealized VAT when apply Payment to Sales Invoice and have another Sales Invoice in the same transaction.
    // 10. Verify Unrealized VAT when apply Payment to Sales Credit Memo and have another Sales Credit Memo in the same transaction.
    // 
    // Covers Test Cases for WI - 351135.
    // ---------------------------------------------------------------------------------------------------
    // Test Function Name                                                                          TFS ID
    // ---------------------------------------------------------------------------------------------------
    // SalesCreditMemoWithFalseCalculatePaymentDiscount                                            316223
    // PurchaseCreditMemoWithFalseCalculatePaymentDiscount                                         316225
    // PurchaseInvoiceWithFullyPmtVendOnOverduePayments                                            330542
    // PurchaseInvoiceWithPartialPmtVendOverduePayments                                            330545
    // SalesInvoiceWithFullyPmtCustOverduePayments                                                 330546
    // SalesInvoiceWithPartialPmtCustOverduePayments                                               330547
    // 
    // Covers Test Cases for WI - 351902.
    // ---------------------------------------------------------------------------------------------------
    // Test Function Name                                                                          TFS ID
    // ---------------------------------------------------------------------------------------------------
    // PurchaseInvoiceWithUnrealizedVAT                                                            315165
    // PurchaseCreditMemoWithUnrealizedVAT                                                         315198
    // SalesInvoiceWithUnrealizedVAT                                                               315193
    // SalesCreditMemoWithUnrealizedVAT                                                            315201

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        WeightedAmtCap: Label 'CalcWeightedExceededAmt';
        CustomerNoCap: Label 'Customer__No__';
        DetailedCustLedgEntryDocNoCap: Label 'Detailed_Cust__Ledg__Entry__Document_No__';
        DetailedVendLedgEntryDocNoCap: Label 'Detailed_Vend__Ledg__Entry__Document_No__';
        ValueMustBeEqualMsg: Label 'Value must be equal.';
        VendorWeightedAmtTxt: Label 'CalcVendorRatioOfPaidTransactions_';
        VendorWeightedOpenAmtTxt: Label 'CalcVendorRatioOfOutstandingPaymentTransactions_';
        AveragePaymentPeriodToSuppliersTxt: Label 'CalcAveragePaymentPeriodToVendor_';
        VendorNoCap: Label 'Vendor__No__';
        ShowPaymentsRef: Option Overdue,"Legally Overdue",All;
        VendPaymentWithinDueDateLbl: Label 'VendPaymentWithinDueDate';
        OpenVendPaymentWithinDueDateLbl: Label 'OpenVendPaymentWithinDueDate';
        CustRatioWithinTok: Label 'FORMAT_TotalPaymentWithinDueDate____Detailed_Cust__Ledg__Entry___Amount__LCY_____100_0___Precision_2__Standard_Format_1___________Control1100046';
        CustRatioOutsideTok: Label 'FORMAT_TotalPaymentOutsideDueDate____Detailed_Cust__Ledg__Entry___Amount__LCY_____100_0___Precision_2__Standard_Format_1___________Control1100047';
        VendRatioWithinTok: Label 'FORMAT_TotalPaymentWithinDueDate____Detailed_Vend__Ledg__Entry___Amount__LCY_____100_0___Precision_2__Standard_Format_1___________Control1100046';
        VendRatioOutsideTok: Label 'FORMAT_TotalPaymentOutsideDueDate____Detailed_Vend__Ledg__Entry___Amount__LCY_____100_0___Precision_2__Standard_Format_1___________Control1100047';

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoWithFalseCalculatePaymentDiscount()
    var
        SalesHeader: Record "Sales Header";
        PostedDocumentNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Verify Posted Sales Credit Memo - Payment Discount Date with blank after changing the Posting Date, Create and Post Sales Credit Memo.

        // Setup: Create Sales Credit Memo, Update Posting Date.
        Initialize();
        CreateSalesDocument(
          SalesHeader, SalesHeader."Document Type"::"Credit Memo", CreateItem(''), CreateCustomer(''),
          CalcDate('<-' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate()));  // Blank - VAT Product Posting Group, VAT Business Posting Group and Posting Date before WorkDate.
        SalesHeader.CalcFields(Amount);

        // Exercise.
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify Sales Credit Memo Header - Posting Date, Amount and Pmt. Discount Date with blank value.
        VerifySalesCrMemoHdrPostDatePmtDiscDateAndAmt(SalesHeader, PostedDocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoWithFalseCalculatePaymentDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        PostedDocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Verify Posted Purchase Credit Memo - Payment Discount Date with blank after changing the Posting Date, Create and Post Purchase Credit Memo.

        // Setup: Create Purchase Credit Memo, Update Posting Date.
        Initialize();
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", CreateItem(''), CreateVendor(''),
          CalcDate('<-' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate()));  // Blank - VAT Product Posting Group, VAT Business Posting Group and Posting Date before WorkDate.
        PurchaseHeader.CalcFields(Amount);

        // Exercise.
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify Purchase Credit Memo Header - Posting Date, Amount and Pmt. Discount Date with blank value.
        VerifyPurchCrMemoHdrPostDatePmtDiscDateAndAmt(PurchaseHeader, PostedDocumentNo);
    end;

    [Test]
    [HandlerFunctions('VendorOverduePaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceWithFullyPmtVendOnOverduePayments()
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Verify Weighted Exceeded Amount Open Payments outside the legal limit in the case of the Posted Purchase Invoice with fully payment.

        // Setup.
        Initialize();
        PurchaseInvoicePmtVendorOverduePayments(LibraryRandom.RandIntInRange(1, 1));  // Division factor for fully Payment.
    end;

    [Test]
    [HandlerFunctions('VendorOverduePaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceWithPartialPmtVendOverduePayments()
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Verify Weighted Exceeded Amount Open Payments outside the legal limit in the case of the Posted Purchase Invoice with partial payment.

        // Setup.
        Initialize();
        PurchaseInvoicePmtVendorOverduePayments(LibraryRandom.RandIntInRange(2, 10));  // Division factor for partial Payment.
    end;

    local procedure PurchaseInvoicePmtVendorOverduePayments(DivisionFactor: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
        DaysOverdue: Integer;
    begin
        // Create and Post multiple Purchase Invoice and General Journal Line.
        CreatePostApplyPurchaseDocument(PurchaseHeader, GenJournalLine, DivisionFactor);

        // Exercise.
        RunVendorOverduePaymentsReport(GenJournalLine."Account No.", PurchaseHeader."Posting Date", ShowPaymentsRef::"Legally Overdue");
        // Opens handler - VendorOverduePaymentsRequestPageHandler.

        DaysOverdue := WorkDate() - PurchaseHeader."Posting Date";   //TFS 380311
        // Verify: Verify Vendor No, Document No, and Calculated Weighted Exceeded Amount on generated XML of Report - Vendor Over due Payments.
        VerifyNumberDocNoAndWeightedAmtsOnVendorReport(
          GenJournalLine."Account No.", GenJournalLine."Document No.", 0, DaysOverdue, 0, 0);
    end;

    [Test]
    [HandlerFunctions('VendorOverduePaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceWithPaymentOnDueDate()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
        PostedDocumentNo: Code[20];
        DaysOverdue: Integer;
        InvoiceAmount: Decimal;
    begin
        // [FEATURE] [Report] [Purchase]
        // [SCENARIO 379545] Vendor Overdue Payments report with Payment posted on Due Date if Invoice
        Initialize();

        // [GIVEN] Posted Purchase Invoice where Amount = 100, Payment Method has 30D, Due Date = 01-02-16
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        PostedDocumentNo :=
          CreateAndPostPurchaseInvoice(
            PurchaseHeader, VATPostingSetup."VAT Prod. Posting Group", CreateVendor(VATPostingSetup."VAT Bus. Posting Group"),
            CalcDate('<-' + Format(LibraryRandom.RandIntInRange(5, 10)) + 'M>', WorkDate()));  // Posting Date before WorkDate.
        InvoiceAmount := FindVendorLedgerEntryAmount(GenJournalLine."Document Type"::Invoice, PostedDocumentNo);

        // [GIVEN] Payment applied to Invoice with Amount = 100 and Posting Date = 01-02-16
        CreateGeneralJornalLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor,
          PurchaseHeader."Buy-from Vendor No.", -FindVendorLedgerEntryAmount(GenJournalLine."Document Type"::Invoice, PostedDocumentNo));
        UpdateAndPostGenJournalLineWithAppliesToDoc(
          GenJournalLine, GenJournalLine."Applies-to Doc. Type"::Invoice, PostedDocumentNo,
          PurchaseHeader."Due Date");

        // [WHEN] Run Vendor - Overdue Payments report
        RunVendorOverduePaymentsReport(GenJournalLine."Account No.", PurchaseHeader."Posting Date", ShowPaymentsRef::All);

        // [THEN] Vendor Overdue Payment report has CalcVendorRatioOfPaidTransactions = 30, VendPaymentWithinDueDate = 100
        DaysOverdue := PurchaseHeader."Due Date" - PurchaseHeader."Posting Date";
        VerifyNumberDocNoAndWeightedAmtsOnVendorReport(
          GenJournalLine."Account No.", GenJournalLine."Document No.", DaysOverdue, 0, -InvoiceAmount, 0);
    end;

    [Test]
    [HandlerFunctions('VendorOverduePaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceOpenWithinDueDate()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
        PostedDocumentNo: Code[20];
        DaysOverdue: Integer;
        InvoiceAmount: Decimal;
    begin
        // [FEATURE] [Report] [Purchase]
        // [SCENARIO 381011] Vendor Overdue Payments report posted within Due Date
        Initialize();

        // [GIVEN] Posted Purchase Invoice where Amount = 100, "Posting Date" = 01-01-16, "Due Date" = 10-01-16
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        PostedDocumentNo :=
          CreateAndPostPurchaseInvoice(
            PurchaseHeader, VATPostingSetup."VAT Prod. Posting Group", CreateVendor(VATPostingSetup."VAT Bus. Posting Group"),
            LibraryRandom.RandDate(-10));
        InvoiceAmount := FindVendorLedgerEntryAmount(GenJournalLine."Document Type"::Invoice, PostedDocumentNo);

        // [WHEN] Run Vendor - Overdue Payments report for period from 01-01-16 until 25-01-16 (> "Due Date")
        RunVendorOverduePaymentsReport(
          PurchaseHeader."Buy-from Vendor No.", PurchaseHeader."Posting Date", ShowPaymentsRef::All);

        // [THEN] Vendor Overdue Payment report has CalcVendorRatioOfOutstandingPaymentTransactions = 10, OpenVendPaymentWithinDueDate = 100
        DaysOverdue := WorkDate() - PurchaseHeader."Posting Date";
        VerifyNumberDocNoAndWeightedAmtsOnVendorReport(
          PurchaseHeader."Buy-from Vendor No.", '', 0, DaysOverdue, 0, -InvoiceAmount);
    end;

    [Test]
    [HandlerFunctions('CutomerOverduePaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithFullyPmtCustOverduePayments()
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Verify Weighted Exceeded Amount Open Payments outside the legal limit in the case of the Posted Sales Invoice with fully payment.

        // Setup.
        Initialize();
        SalesInvoicePmtCustOverduePayments(LibraryRandom.RandIntInRange(1, 1));  // Division factor for fully Payment.
    end;

    [Test]
    [HandlerFunctions('CutomerOverduePaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithPartialPmtCustOverduePayments()
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Verify Weighted Exceeded Amount Open Payments outside the legal limit in the case of the Posted Sales Invoice with partial payment.

        // Setup.
        Initialize();
        SalesInvoicePmtCustOverduePayments(LibraryRandom.RandIntInRange(2, 10));  // Division factor for partial Payment.
    end;

    local procedure SalesInvoicePmtCustOverduePayments(DivisionFactor: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
        SalesHeader: Record "Sales Header";
    begin
        // Create and Post multiple Sales Invoice and General Journal Line.
        CreatePostApplySalesDocument(SalesHeader, GenJournalLine, DivisionFactor);

        // Exercise.
        RunCustomerOverduePaymentsReport(GenJournalLine."Account No.", SalesHeader."Posting Date");
        // Opens handler - CustomerOverduePaymentsRequestPageHandler.

        // Verify: Verify Customer No, Document No, and Calculated Weighted Exceeded Amount on generated XML of Report - Customer Over due Payments.
        VerifyNumberDocNoAndWeightedAmtOnReport(
          GenJournalLine, CustomerNoCap, WeightedAmtCap, DetailedCustLedgEntryDocNoCap, SalesHeader."Payment Terms Code",
          SalesHeader."Posting Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceWithUnrealizedVAT()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Verify Unrealized VAT when apply Payment to Purchase Invoice and have another Purchase Invoice in the same transaction.

        // Setup.
        Initialize();
        CreateAndPostGeneralJornalWithUnrealizedVAT(
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor,
          GenJournalLine."Bal. Gen. Posting Type"::Purchase, -LibraryRandom.RandDecInRange(10, 50, 2));  // Random - Amount.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoWithUnrealizedVAT()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Verify Unrealized VAT when apply Payment to Purchase Credit Memo and have another Purchase Credit Memo in the same transaction.

        // Setup.
        Initialize();
        CreateAndPostGeneralJornalWithUnrealizedVAT(
          GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund, GenJournalLine."Account Type"::Vendor,
          GenJournalLine."Bal. Gen. Posting Type"::Purchase, LibraryRandom.RandDecInRange(10, 50, 2));  // Random - Amount.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithUnrealizedVAT()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Verify Unrealized VAT when apply Payment to Sales Invoice and have another Sales Invoice in the same transaction.

        // Setup.
        Initialize();
        CreateAndPostGeneralJornalWithUnrealizedVAT(
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer,
          GenJournalLine."Bal. Gen. Posting Type"::Sale, LibraryRandom.RandDecInRange(10, 50, 2));  // Random - Amount.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoWithUnrealizedVAT()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Verify Unrealized VAT when apply Payment to Sales Credit Memo and have another Sales Credit Memo in the same transaction.

        // Setup.
        Initialize();
        CreateAndPostGeneralJornalWithUnrealizedVAT(
          GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund, GenJournalLine."Account Type"::Customer,
          GenJournalLine."Bal. Gen. Posting Type"::Sale, -LibraryRandom.RandDecInRange(10, 50, 2));  // Random - Amount.
    end;

    local procedure CreateAndPostGeneralJornalWithUnrealizedVAT(DocumentType: Enum "Gen. Journal Document Type"; AppliesToDocType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; BalGenPostingType: Enum "General Posting Type"; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        VATPostingSetup: Record "VAT Posting Setup";
        OldUnrealizedVAT: Boolean;
        VATAmount: Decimal;
        AppliesToDocNo: Code[20];
    begin
        // Update General Ledger Setup - Unrealized VAT, Create and Post General Journal Line with two Document.
        OldUnrealizedVAT := UpdateGeneralLedgerSetupUnrealizedVAT(true);  // Unrealized VAT - True.
        CreateVATPostingSetup(VATPostingSetup);
        CreateGeneralJornalLine(
          GenJournalLine, DocumentType, AccountType, CreateAccountNumber(AccountType, VATPostingSetup."VAT Bus. Posting Group"), Amount);
        UpdateGeneralJournalLine(
          GenJournalLine, CreateGLAccountWithPostingGroup(
            VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group"), BalGenPostingType);
        CreateAndPostGenJournalLine(
          GenJournalLine, GenJournalLine."Document No.", GenJournalLine."Bal. Account No.", GenJournalLine."Bal. Gen. Posting Type");
        AppliesToDocNo := GenJournalLine."Document No.";
        CreateGeneralJornalLine(
          GenJournalLine, AppliesToDocType, AccountType, GenJournalLine."Account No.",
          FindLedgerEntryAmount(AccountType, DocumentType, GenJournalLine."Document No."));

        // Exercise: Post General Journal Line With Applies To Document Number.
        UpdateAndPostGenJournalLineWithAppliesToDoc(GenJournalLine, DocumentType, AppliesToDocNo, WorkDate());

        // Verify: Verify VAT Entry - Base and Amount.
        VATAmount := GenJournalLine.Amount * VATPostingSetup."VAT %" / (100 + VATPostingSetup."VAT %");
        VerifyVATEntryVATAmountAndBase(AppliesToDocType, GenJournalLine."Account No.", VATAmount, GenJournalLine.Amount);

        // TearDown.
        UpdateGeneralLedgerSetupUnrealizedVAT(OldUnrealizedVAT);
    end;

    [HandlerFunctions('CutomerOverduePaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerOverduePaymentWithZeroTotal()
    var
        SalesHeader: Record "Sales Header";
        GenJournalLine: Record "Gen. Journal Line";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        // [SCENARIO 300477] Run 'Customer - Overdue Payments' report when TotalAmount for Customer is zero
        Initialize();

        // [GIVEN] Posted Sales Invoice with applied payment
        CreatePostApplySalesDocument(SalesHeader, GenJournalLine, 1);

        // [GIVEN] Detailed entries gives zero totals
        DetailedCustLedgEntry.SetRange("Customer No.", GenJournalLine."Account No.");
        DetailedCustLedgEntry.ModifyAll(Amount, 0);
        DetailedCustLedgEntry.ModifyAll("Amount (LCY)", 0);
        Commit();

        // [WHEN] Run 'Customer - Overdue Payments'
        RunCustomerOverduePaymentsReport(GenJournalLine."Account No.", SalesHeader."Posting Date");

        // [THEN] Elements for zero total ratio exported with zero values
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          'WeightedExceededAmount___ABS__Detailed_Cust__Ledg__Entry___Amount__LCY___', 0);
        LibraryReportDataset.AssertElementWithValueExists(
          'WeightedExceededAmount___ABS__Detailed_Cust__Ledg__Entry___Amount__LCY____Control1100057', 0);
        LibraryReportDataset.AssertElementWithValueExists(CustRatioWithinTok, GetZeroPctTxt());
        LibraryReportDataset.AssertElementWithValueExists(CustRatioOutsideTok, GetZeroPctTxt());
    end;

    [HandlerFunctions('VendorOverduePaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendorOverduePaymentWithZeroTotal()
    var
        PurchaseHeader: Record "Purchase Header";
        GenJournalLine: Record "Gen. Journal Line";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        // [SCENARIO 300477] Run 'Vendor - Overdue Payments' report when TotalAmount for Vendor is zero
        Initialize();

        // [GIVEN] Posted Purchase Invoice with applied payment
        CreatePostApplyPurchaseDocument(PurchaseHeader, GenJournalLine, 1);

        // [GIVEN] Detailed entries gives zero totals
        DetailedVendorLedgEntry.SetRange("Vendor No.", GenJournalLine."Account No.");
        DetailedVendorLedgEntry.ModifyAll(Amount, 0);
        DetailedVendorLedgEntry.ModifyAll("Amount (LCY)", 0);
        Commit();

        // [WHEN] Run 'Vendor - Overdue Payments'
        RunVendorOverduePaymentsReport(GenJournalLine."Account No.", PurchaseHeader."Posting Date", 0);

        // [THEN] Elements for zero total ratio exported with zero values
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          'WeightedExceededAmount___ABS__Detailed_Vend__Ledg__Entry___Amount__LCY___', 0);
        LibraryReportDataset.AssertElementWithValueExists(
          'WeightedExceededAmount___ABS__Detailed_Vend__Ledg__Entry___Amount__LCY____Control1100057', 0);
        LibraryReportDataset.AssertElementWithValueExists(VendRatioWithinTok, GetZeroPctTxt());
        LibraryReportDataset.AssertElementWithValueExists(VendRatioOutsideTok, GetZeroPctTxt());
    end;

    [Test]
    [HandlerFunctions('VendorOverduePaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestVendorOverduePaymentReportOnDueDatesAfterApplyInvoiceWithPayments()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
        PostedDocumentNo: Code[20];
        DaysOverdue: Integer;
        InvoiceAmount: Decimal;
    begin
        // [SCENARIO 453127] Error "An item with the same key has already been added." when running Vendor - Overdue Payments in Spanish version
        Initialize();

        // [GIVEN] Posted Purchase Invoice where Amount = 100, Payment Method has 30D, Due Date = 01-02-16
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        PostedDocumentNo :=
          CreateAndPostPurchaseInvoice(
            PurchaseHeader, VATPostingSetup."VAT Prod. Posting Group", CreateVendor(VATPostingSetup."VAT Bus. Posting Group"),
            CalcDate('<-' + Format(LibraryRandom.RandIntInRange(5, 10)) + 'M>', WorkDate()));  // Posting Date before WorkDate.
        InvoiceAmount := FindVendorLedgerEntryAmount(GenJournalLine."Document Type"::Invoice, PostedDocumentNo);

        // [GIVEN] Create two different payments and applied to Posted Invoice
        CreateGeneralJornalLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor,
          PurchaseHeader."Buy-from Vendor No.", -(InvoiceAmount / 2));
        UpdateAndPostGenJournalLineWithAppliesToDoc(
          GenJournalLine, GenJournalLine."Applies-to Doc. Type"::Invoice, PostedDocumentNo,
          PurchaseHeader."Due Date");

        CreateGeneralJornalLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor,
          PurchaseHeader."Buy-from Vendor No.", -(InvoiceAmount / 2));
        UpdateAndPostGenJournalLineWithAppliesToDoc(
          GenJournalLine, GenJournalLine."Applies-to Doc. Type"::Invoice, PostedDocumentNo,
          PurchaseHeader."Due Date");

        // [WHEN] Run Vendor - Overdue Payments report
        RunVendorOverduePaymentsReport(GenJournalLine."Account No.", PurchaseHeader."Posting Date", ShowPaymentsRef::All);

        // [THEN] Vendor Overdue Payment report has CalcVendorRatioOfPaidTransactions = 30, VendPaymentWithinDueDate = 100
        DaysOverdue := PurchaseHeader."Due Date" - PurchaseHeader."Posting Date";
        VerifyNumberDocNoAndWeightedAmtsOnVendorReport(
          GenJournalLine."Account No.", GenJournalLine."Document No.", DaysOverdue, 0, -InvoiceAmount, 0);
    end;

    local procedure Initialize()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        LibraryVariableStorage.Clear();
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Link Doc. Date To Posting Date", true);
        PurchasesPayablesSetup.Modify();
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Link Doc. Date To Posting Date", true);
        SalesReceivablesSetup.Modify();
    end;

    local procedure CreateAccountNumber(AccountType: Enum "Gen. Journal Account Type"; VATBusPostingGroup: Code[20]): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        if AccountType = GenJournalLine."Account Type"::Customer then
            exit(CreateCustomer(VATBusPostingGroup));
        exit(CreateVendor(VATBusPostingGroup));
    end;

    local procedure CreateAndPostGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentNo: Code[20]; BalAccountNo: Code[20]; BalGenPostingType: Enum "General Posting Type")
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Document Type",
          GenJournalLine."Account Type", GenJournalLine."Account No.", GenJournalLine.Amount);
        GenJournalLine.Validate("Document No.", IncStr(DocumentNo));
        UpdateGeneralJournalLine(GenJournalLine, BalAccountNo, BalGenPostingType);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure UpdateAndPostGenJournalLineWithAppliesToDoc(var GenJournalLine: Record "Gen. Journal Line"; AppliesToDocType: Enum "Gen. Journal Document Type"; AppliesToDocNo: Code[20]; PostingDate: Date)
    begin
        GenJournalLine.Validate("Applies-to Doc. Type", AppliesToDocType);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostSalesInvoice(var SalesHeader: Record "Sales Header"; VATProdPostingGroup: Code[20]; CustomerNo: Code[20]; PostingDate: Date): Code[20]
    begin
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, CreateItem(VATProdPostingGroup), CustomerNo, PostingDate);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostPurchaseInvoice(var PurchaseHeader: Record "Purchase Header"; VATProdPostingGroup: Code[20]; VendorNo: Code[20]; PostingDate: Date): Code[20]
    begin
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateItem(VATProdPostingGroup), VendorNo, PostingDate);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateCustomer(VATBusPostingGroup: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Customer.Validate("Payment Terms Code", CreatePaymentTerms());
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateItem(VATProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        exit(Item."No.");
    end;

    local procedure CreateGeneralJornalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType, AccountType, AccountNo, Amount);
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateGLAccountWithPostingGroup(VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
        GLAccount.Validate("Gen. Posting Type", GLAccount."Gen. Posting Type"::Purchase);
        GLAccount.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        GLAccount.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreatePaymentTerms(): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        Evaluate(PaymentTerms."Due Date Calculation", '<' + Format(LibraryRandom.RandInt(5)) + 'M>');
        PaymentTerms.Modify(true);
        exit(PaymentTerms.Code);
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; ItemNo: Code[20]; VendorNo: Code[20]; PostingDate: Date)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandDec(10, 2));  // Random value for Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; ItemNo: Code[20]; CustomerNo: Code[20]; PostingDate: Date)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandDec(10, 2));  // Random value for Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(10, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreatePostApplySalesDocument(var SalesHeader: Record "Sales Header"; var GenJournalLine: Record "Gen. Journal Line"; DivisionFactor: Integer)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PostedDocumentNo: Code[20];
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateAndPostSalesInvoice(
          SalesHeader, VATPostingSetup."VAT Prod. Posting Group", CreateCustomer(VATPostingSetup."VAT Bus. Posting Group"),
          CalcDate('<-' + Format(LibraryRandom.RandIntInRange(5, 10)) + 'M>', WorkDate()));  // Posting Date before WorkDate.
        PostedDocumentNo :=
          CreateAndPostSalesInvoice(
            SalesHeader, VATPostingSetup."VAT Prod. Posting Group", SalesHeader."Sell-to Customer No.", SalesHeader."Posting Date");
        CreateGeneralJornalLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer,
          SalesHeader."Sell-to Customer No.", -FindCustomerLedgerEntryAmount(GenJournalLine."Document Type"::Invoice, PostedDocumentNo) /
          DivisionFactor);
        UpdateAndPostGenJournalLineWithAppliesToDoc(
          GenJournalLine, GenJournalLine."Applies-to Doc. Type"::Invoice, PostedDocumentNo, WorkDate());
    end;

    local procedure CreatePostApplyPurchaseDocument(var PurchaseHeader: Record "Purchase Header"; var GenJournalLine: Record "Gen. Journal Line"; DivisionFactor: Integer)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PostedDocumentNo: Code[20];
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateAndPostPurchaseInvoice(
          PurchaseHeader, VATPostingSetup."VAT Prod. Posting Group", CreateVendor(VATPostingSetup."VAT Bus. Posting Group"),
          CalcDate('<-' + Format(LibraryRandom.RandIntInRange(5, 10)) + 'M>', WorkDate()));  // Posting Date before WorkDate.
        LibraryVariableStorage.Enqueue(PurchaseHeader."Posting Date");  // Enqueue value for handler - VendorOverduePaymentsRequestPageHandler.
        PostedDocumentNo :=
          CreateAndPostPurchaseInvoice(
            PurchaseHeader, VATPostingSetup."VAT Prod. Posting Group", PurchaseHeader."Buy-from Vendor No.", PurchaseHeader."Posting Date");
        CreateGeneralJornalLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor,
          PurchaseHeader."Buy-from Vendor No.", -FindVendorLedgerEntryAmount(GenJournalLine."Document Type"::Invoice, PostedDocumentNo) /
          DivisionFactor);
        UpdateAndPostGenJournalLineWithAppliesToDoc(
          GenJournalLine, GenJournalLine."Applies-to Doc. Type"::Invoice, PostedDocumentNo, WorkDate());
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::Percentage);
        VATPostingSetup.Validate("Purchase VAT Account", CreateGLAccount());
        VATPostingSetup.Validate(
          "Purch. VAT Unreal. Account",
          CreateGLAccountWithPostingGroup(VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group"));
        VATPostingSetup.Validate("Sales VAT Account", VATPostingSetup."Purchase VAT Account");
        VATPostingSetup.Validate("Sales VAT Unreal. Account", VATPostingSetup."Purch. VAT Unreal. Account");
        VATPostingSetup.Validate("VAT %", LibraryRandom.RandIntInRange(5, 10));
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateVendor(VATBusPostingGroup: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Vendor.Validate("Payment Terms Code", CreatePaymentTerms());
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure FindCustomerLedgerEntryAmount(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]): Decimal
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        CustLedgerEntry.CalcFields(Amount);
        exit(CustLedgerEntry.Amount);
    end;

    local procedure FindLedgerEntryAmount(AccountType: Enum "Gen. Journal Account Type"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]): Decimal
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        if AccountType = GenJournalLine."Account Type"::Customer then
            exit(-FindCustomerLedgerEntryAmount(DocumentType, DocumentNo));
        exit(-FindVendorLedgerEntryAmount(DocumentType, DocumentNo));
    end;

    local procedure FindVendorLedgerEntryAmount(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]): Decimal
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, DocumentType, DocumentNo);
        VendorLedgerEntry.CalcFields(Amount);
        exit(VendorLedgerEntry.Amount);
    end;

    local procedure GetZeroPctTxt(): Text
    begin
        exit('(' + Format(0.0, 0, '<Precision,2><Standard Format,1>') + '%)');
    end;

    local procedure RunCustomerOverduePaymentsReport(No: Code[20]; StartingDate: Date)
    var
        Customer: Record Customer;
        CustomerOverduePayments: Report "Customer - Overdue Payments";
        ShowPayments: Option Overdue,"Legally Overdue";
    begin
        Customer.SetRange("No.", No);
        CustomerOverduePayments.SetTableView(Customer);
        CustomerOverduePayments.InitReportParameters(StartingDate, WorkDate(), ShowPayments::"Legally Overdue");
        CustomerOverduePayments.Run();
    end;

    local procedure RunVendorOverduePaymentsReport(No: Code[20]; StartingDate: Date; ShowPayments: Option)
    var
        Vendor: Record Vendor;
        VendorOverduePayments: Report "Vendor - Overdue Payments";
    begin
        Vendor.SetRange("No.", No);
        VendorOverduePayments.InitReportParameters(StartingDate, WorkDate(), ShowPayments);
        VendorOverduePayments.SetTableView(Vendor);
        VendorOverduePayments.Run();
    end;

    local procedure UpdateGeneralLedgerSetupUnrealizedVAT(UnrealizedVAT: Boolean) OldUnrealizedVAT: Boolean
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        OldUnrealizedVAT := GeneralLedgerSetup."Unrealized VAT";
        GeneralLedgerSetup."Unrealized VAT" := UnrealizedVAT;
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; BalAccountNo: Code[20]; BalGenPostingType: Enum "General Posting Type")
    begin
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Validate("Bal. Gen. Posting Type", BalGenPostingType);
        GenJournalLine.Validate("External Document No.", GenJournalLine."Document No.");
        GenJournalLine.Modify(true);
    end;

    local procedure VerifyVATEntryVATAmountAndBase(DocumentType: Enum "Gen. Journal Document Type"; BillToPayToNo: Code[20]; VATAmount: Decimal; Amount: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document Type", DocumentType);
        VATEntry.SetRange("Bill-to/Pay-to No.", BillToPayToNo);
        VATEntry.FindFirst();
        Assert.AreNearlyEqual(VATAmount, VATEntry.Amount, LibraryERM.GetInvoiceRoundingPrecisionLCY(), ValueMustBeEqualMsg);
        Assert.AreNearlyEqual(Amount - VATEntry.Amount, VATEntry.Base, LibraryERM.GetInvoiceRoundingPrecisionLCY(), ValueMustBeEqualMsg);
    end;

    local procedure VerifyNumberDocNoAndWeightedAmtsOnVendorReport(VendorNo: Code[20]; DocumentNo: Code[20]; DaysOverdue: Integer; DaysOutstanding: Integer; WithinDueDateAmt: Decimal; OpenWithinDueDateAmt: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(VendorNoCap, VendorNo);
        LibraryReportDataset.AssertElementWithValueExists(DetailedVendLedgEntryDocNoCap, DocumentNo);

        LibraryReportDataset.AssertElementWithValueExists(VendorWeightedAmtTxt, DaysOverdue);
        LibraryReportDataset.AssertElementWithValueExists(VendorWeightedOpenAmtTxt, DaysOutstanding);
        LibraryReportDataset.AssertElementWithValueExists(AveragePaymentPeriodToSuppliersTxt, DaysOverdue + DaysOutstanding);
        LibraryReportDataset.AssertElementWithValueExists(VendPaymentWithinDueDateLbl, WithinDueDateAmt);
        LibraryReportDataset.AssertElementWithValueExists(OpenVendPaymentWithinDueDateLbl, OpenWithinDueDateAmt);
    end;

    local procedure VerifyNumberDocNoAndWeightedAmtOnReport(GenJournalLine: Record "Gen. Journal Line"; NumberCap: Text; CalcWeightedExceededAmtCap: Text; LedgEntryDocumentNoCap: Text; "Code": Code[10]; PostingDate: Date)
    var
        PaymentTerms: Record "Payment Terms";
    begin
        PaymentTerms.Get(Code);
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(NumberCap, GenJournalLine."Account No.");
        LibraryReportDataset.AssertElementWithValueExists(
          CalcWeightedExceededAmtCap, WorkDate() - CalcDate(PaymentTerms."Due Date Calculation", PostingDate));
        LibraryReportDataset.AssertElementWithValueExists(LedgEntryDocumentNoCap, GenJournalLine."Document No.");
    end;

    local procedure VerifyPurchCrMemoHdrPostDatePmtDiscDateAndAmt(PurchaseHeader: Record "Purchase Header"; No: Code[20])
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        PurchCrMemoHdr.Get(No);
        PurchCrMemoHdr.CalcFields(Amount);
        PurchCrMemoHdr.TestField("Posting Date", PurchaseHeader."Posting Date");
        PurchCrMemoHdr.TestField("Pmt. Discount Date", 0D);
        PurchCrMemoHdr.TestField(Amount, PurchaseHeader.Amount);
    end;

    local procedure VerifySalesCrMemoHdrPostDatePmtDiscDateAndAmt(SalesHeader: Record "Sales Header"; No: Code[20])
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        SalesCrMemoHeader.Get(No);
        SalesCrMemoHeader.CalcFields(Amount);
        SalesCrMemoHeader.TestField("Posting Date", SalesHeader."Posting Date");
        SalesCrMemoHeader.TestField("Pmt. Discount Date", 0D);
        SalesCrMemoHeader.TestField(Amount, SalesHeader.Amount);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CutomerOverduePaymentsRequestPageHandler(var CustomerOverduePayments: TestRequestPage "Customer - Overdue Payments")
    begin
        CustomerOverduePayments.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorOverduePaymentsRequestPageHandler(var VendorOverduePayments: TestRequestPage "Vendor - Overdue Payments")
    begin
        VendorOverduePayments.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

