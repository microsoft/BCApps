codeunit 144080 "ERM PPL"
{
    //  1. Purpose of this test verifies that if there are not payments for some Invoice and Start and End date of the report are outside the legal limit then this Invoice is reflected in the report with Legally Overdue option.
    //  2. Purpose of this test verifies that if there are not payments for some Invoice and Start and End date of the report are outside the legal limit then this Invoice is reflected in the report with Overdue option.
    //  3. Purpose of this test verifies that if the payment is applied partially that the Invoice is still open and reflected in the report 10747.
    //  4. Purpose of this test verifies that if Posting Date of applied payment is out of the range that the Invoice is still open in report 10747.
    //  5. Purpose of this test verifies that if there are not payments for some Invoice and Start and End date of the report are outside the legal limit then this Invoice is reflected in the report with Legally Overdue option.
    //  6. Purpose of this test verifies that if there are not payments for some Invoice and Start and End date of the report are outside the legal limit then this Invoice is reflected in the report with Overdue option.
    //  7. Purpose of this test verifies that if the payment is applied partially that the Invoice is still open and reflected in the report 10748.
    //  8. Purpose of this test verifies that if Posting Date of applied payment is out of the range that the Invoice is still open in report 10748.
    //  9. Purpose of this test verifies the error when Due Date is updated and is outside the limit on General Journal Line.
    // 10. Test to Verify Program calculates correct Due Date on Purchase Invoice with Spanish Prompt Law objects when Max. No. of days till Due Date =BLANK.
    // 11. Verify Program Calculate correct amount on Vendor Ledger Entries when used to compress entries using date compression.
    // 12. Verify Program Calculate correct amount on Customer Ledger Entries when used to compress entries using date compression.
    // 
    // Covers Test Cases for WI: 351160
    // ----------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                    TFS ID
    // ----------------------------------------------------------------------------------------------------------------------
    // CustomerOverduePaymentsTypeLegallyOverdue                                                             309945
    // CustomerOverduePaymentsTypeOverdue                                                                    309946
    // CustomerOverduePaymentsTypeAllWithPartialPayment                                                      310133
    // CustomerOverduePaymentsTypeAllWithFullPayment                                                         310187
    // VendorOverduePaymentsTypeLegallyOverdue                                                               309941
    // VendorOverduePaymentsTypeOverdue                                                                      309934
    // VendorOverduePaymentsTypeAllWithPartialPayment                                                        310121
    // VendorOverduePaymentsTypeAllWithFullPayment                                                           310175
    // 
    // Covers Test Cases for WI: 352331
    // ----------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                    TFS ID
    // ----------------------------------------------------------------------------------------------------------------------
    // GeneralJournalLineDueDateError                                                                 309889,309888
    // DueDateOnPurchaseInvoice                                                                              302846
    // VendorLedgerEntryWithSettleDocsRedrawPayableBill,                                                     302923
    // CustomerLedgerEntryWithSettleDocsRedrawReceivableBill

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryESLocalization: Codeunit "Library - ES Localization";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        FileMgt: Codeunit "File Management";
        ABSAmountCap: Label 'ABS_Amount_';
        AmountMustMatchMsg: Label 'Amount must match.';
        CustomerNoCap: Label 'Customer__No__';
        DaysOverdueCap: Label 'DaysOverdue';
        DueDateErr: Label 'The %1 exceeds the %2 defined on the %3.';
        DocumentNoCap: Label 'Cust__Ledger_Entry___Document_No__';
        VendorNoCap: Label 'Vendor__No__';
        VendorDocumentNoCap: Label 'Vend__Ledger_Entry___Document_No__';
        DueDatesAreNotEqualErr: Label 'Due dates are not equal';

    [Test]
    [HandlerFunctions('CustomerOverduePaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerOverduePaymentsTypeLegallyOverdue()
    var
        ShowPayment: Option Overdue,"Legally Overdue",All;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Purpose of this test verifies that if there are not payments for some Invoice and Start and End date of the report are outside the legal limit then this Invoice is reflected in the report with Legally Overdue option.
        CustomerOverduePayments(ShowPayment::"Legally Overdue");
    end;

    [Test]
    [HandlerFunctions('CustomerOverduePaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerOverduePaymentsTypeOverdue()
    var
        ShowPayment: Option Overdue,"Legally Overdue",All;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Purpose of this test verifies that if there are not payments for some Invoice and Start and End date of the report are outside the legal limit then this Invoice is reflected in the report with Overdue option.
        CustomerOverduePayments(ShowPayment::Overdue);
    end;

    local procedure CustomerOverduePayments(ShowPayment: Option)
    var
        PaymentTerms: Record "Payment Terms";
        SalesHeader: Record "Sales Header";
        Amount: Decimal;
        Amount2: Decimal;
        DueDays: Integer;
    begin
        // Setup: Create and Post Sales Invoice with Overdue Payments.
        Initialize();
        CreateAndPostSalesInvoice(SalesHeader, CreateCustomerWithMultipleInstallmentsSetup());
        FindPaymentTerms(PaymentTerms, SalesHeader."Payment Terms Code");
        Amount :=
          FindSalesInvoiceAmountIncludingVAT(
            SalesHeader."Last Posting No.") * FindInstallmentPct(PaymentTerms.Code, Format(PaymentTerms."Due Date Calculation")) / 100;
        Amount2 :=
          FindSalesInvoiceAmountIncludingVAT(
            SalesHeader."Last Posting No.") *
          (100 - FindInstallmentPct(PaymentTerms.Code, Format(PaymentTerms."Due Date Calculation"))) / 100;
        DueDays := CalcDate('<CM + 1M>', SalesHeader."Document Date") - SalesHeader."Due Date";  // Taking next month date.
        EnqueueValuesForRequestPageHandler(
          CalcDate('<-CM - 1M>', SalesHeader."Document Date"), CalcDate('<CM + 1M>', SalesHeader."Document Date"),
          ShowPayment, SalesHeader."Sell-to Customer No.");  // Enqueue values for CustomerOverduePaymentsRequestPageHandler and taking one month back and next month date.

        // Exercise & Verify.
        RunAndVerifyCustomerOverduePaymentsReport(SalesHeader, Round(Amount), Round(Amount2), DueDays);
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesWithAppliesToIDModalPageHandler,CustomerOverduePaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerOverduePaymentsTypeAllWithPartialPayment()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        SalesHeader: Record "Sales Header";
        ShowPayment: Option Overdue,"Legally Overdue",All;
        Amount: Decimal;
        Amount2: Decimal;
        DueDays: Integer;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Purpose of this test verifies that if the payment is applied partially that the Invoice is still open and reflected in the report 10747.

        // Setup: Create and Post Sales Invoice and Payment.
        Initialize();
        CreateAndPostSalesInvoice(SalesHeader, CreateCustomerWithMultipleInstallmentsSetup());
        CreateAndPostGenJournalLine(
          GenJournalLine."Account Type"::Customer, SalesHeader."Sell-to Customer No.",
          -FindCustomerLedgerEntryAmount(SalesHeader."Last Posting No."),
          CalcDate('<' + Format(LibraryRandom.RandIntInRange(10, 20)) + 'D>', SalesHeader."Due Date"));  // Using Random value for Posting Date.
        FindPaymentTerms(PaymentTerms, SalesHeader."Payment Terms Code");
        Amount :=
          FindSalesInvoiceAmountIncludingVAT(
            SalesHeader."Last Posting No.") * FindInstallmentPct(PaymentTerms.Code, Format(PaymentTerms."Due Date Calculation")) / 100;
        Amount2 :=
          FindSalesInvoiceAmountIncludingVAT(
            SalesHeader."Last Posting No.") *
          (100 - FindInstallmentPct(PaymentTerms.Code, Format(PaymentTerms."Due Date Calculation"))) / 100;
        DueDays :=
          FindCustomerLedgerEntryPostingDate(
            SalesHeader."Sell-to Customer No.", CustLedgerEntry."Document Type"::Payment) - SalesHeader."Due Date";
        EnqueueValuesForRequestPageHandler(
          CalcDate('<-CM - 1M>', SalesHeader."Document Date"), CalcDate('<CM + 1M>', SalesHeader."Document Date"),
          ShowPayment::All, SalesHeader."Sell-to Customer No.");  // Enqueue values for CustomerOverduePaymentsRequestPageHandler and taking one month back and next month date.
        Commit();  // Commit is required.

        // Exercise & Verify.
        RunAndVerifyCustomerOverduePaymentsReport(SalesHeader, Round(Amount), Round(Amount2), DueDays);
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesWithAppliesToIDModalPageHandler,CustomerOverduePaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerOverduePaymentsTypeAllWithFullPayment()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        SalesHeader: Record "Sales Header";
        ShowPayment: Option Overdue,"Legally Overdue",All;
        Amount: Decimal;
        Amount2: Decimal;
        DueDays: Integer;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Purpose of this test verifies that if Posting Date of applied payment is out of the range that the Invoice is still open on report 10747.

        // Setup: Create and Post Sales Invoice and Payment.
        Initialize();
        CreateAndPostSalesInvoice(SalesHeader, CreateCustomerWithMultipleInstallmentsSetup());
        CreateAndPostGenJournalLine(
          GenJournalLine."Account Type"::Customer, SalesHeader."Sell-to Customer No.",
          -FindCustomerLedgerEntryAmount(SalesHeader."Last Posting No."),
          CalcDate('<' + Format(LibraryRandom.RandIntInRange(10, 20)) + 'D>', SalesHeader."Due Date"));  // Using Random value for Posting Date.
        CreateAndPostGenJournalLine(
          GenJournalLine."Account Type"::Customer, SalesHeader."Sell-to Customer No.",
          -FindCustomerLedgerEntryAmount(SalesHeader."Last Posting No."),
          CalcDate('<' + Format(LibraryRandom.RandIntInRange(20, 30)) + 'D>', SalesHeader."Due Date"));  // Using Random value for Posting Date.
        FindPaymentTerms(PaymentTerms, SalesHeader."Payment Terms Code");
        Amount :=
          FindSalesInvoiceAmountIncludingVAT(
            SalesHeader."Last Posting No.") * FindInstallmentPct(PaymentTerms.Code, Format(PaymentTerms."Due Date Calculation")) / 100;
        Amount2 :=
          FindSalesInvoiceAmountIncludingVAT(
            SalesHeader."Last Posting No.") *
          (100 - FindInstallmentPct(PaymentTerms.Code, Format(PaymentTerms."Due Date Calculation"))) / 100;
        DueDays :=
          FindCustomerLedgerEntryPostingDate(
            SalesHeader."Sell-to Customer No.", CustLedgerEntry."Document Type"::Payment) - SalesHeader."Due Date";
        EnqueueValuesForRequestPageHandler(
          CalcDate('<-CM - 1M>', SalesHeader."Document Date"), CalcDate('<CM + 1M>', SalesHeader."Document Date"),
          ShowPayment::All, SalesHeader."Sell-to Customer No.");  // Enqueue values for CustomerOverduePaymentsRequestPageHandler and taking one month back and next month date.
        Commit();  // Commit is required.

        // Exercise & Verify.
        RunAndVerifyCustomerOverduePaymentsReport(SalesHeader, Round(Amount), Round(Amount2), DueDays);
    end;

    [Test]
    [HandlerFunctions('VendorOverduePaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendorOverduePaymentsTypeLegallyOverdue()
    var
        ShowPayment: Option Overdue,"Legally Overdue",All;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Purpose of this test verifies that if there are not payments for some Invoice and Start and End date of the report are outside the legal limit then this Invoice is reflected in the report with Legally Overdue option.
        VendorOverduePayments(ShowPayment::"Legally Overdue");
    end;

    [Test]
    [HandlerFunctions('VendorOverduePaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendorOverduePaymentsTypeOverdue()
    var
        ShowPayment: Option Overdue,"Legally Overdue",All;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Purpose of this test verifies that if there are not payments for some Invoice and Start and End date of the report are outside the legal limit then this Invoice is reflected in the report with Overdue option.
        VendorOverduePayments(ShowPayment::Overdue);
    end;

    local procedure VendorOverduePayments(ShowPayment: Option)
    var
        PurchaseHeader: Record "Purchase Header";
        PaymentTerms: Record "Payment Terms";
        Amount: Decimal;
        Amount2: Decimal;
        DueDays: Integer;
    begin
        // Setup: Create and Post Purchase Invoice with Overdue Payments.
        Initialize();
        CreateAndPostPurchaseInvoice(PurchaseHeader, CreateVendorWithMultipleInstallmentsSetup());
        FindPaymentTerms(PaymentTerms, PurchaseHeader."Payment Terms Code");
        Amount :=
          FindPurchInvoiceAmountIncludingVAT(
            PurchaseHeader."Last Posting No.") * FindInstallmentPct(PaymentTerms.Code, Format(PaymentTerms."Due Date Calculation")) / 100;
        Amount2 :=
          FindPurchInvoiceAmountIncludingVAT(
            PurchaseHeader."Last Posting No.") *
          (100 - FindInstallmentPct(PaymentTerms.Code, Format(PaymentTerms."Due Date Calculation"))) / 100;
        DueDays := CalcDate('<CM + 1M>', PurchaseHeader."Document Date") - PurchaseHeader."Posting Date";  // Taking next month date.
        EnqueueValuesForRequestPageHandler(
          CalcDate('<-CM - 1M>', PurchaseHeader."Document Date"), CalcDate('<CM + 1M>', PurchaseHeader."Document Date"),
          ShowPayment, PurchaseHeader."Buy-from Vendor No.");  // Enqueue values for VendorOverduePaymentsRequestPageHandler and taking one month back and next month date.

        // Exercise & Verify.
        RunAndVerifyVendorOverduePaymentsReport(PurchaseHeader, Round(Amount), Round(Amount2), DueDays);
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesWithAppliesToIDModalPageHandler,VendorOverduePaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendorOverduePaymentsTypeAllWithPartialPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        ShowPayment: Option Overdue,"Legally Overdue",All;
        Amount: Decimal;
        Amount2: Decimal;
        DueDays: Integer;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Purpose of this test verifies that if the payment is applied partially that the Invoice is still open and reflected in the report 10748.

        // Setup: Create and Post Purchase Invoice and Payment.
        Initialize();
        CreateAndPostPurchaseInvoice(PurchaseHeader, CreateVendorWithMultipleInstallmentsSetup());
        CreateAndPostGenJournalLine(
          GenJournalLine."Account Type"::Vendor, PurchaseHeader."Buy-from Vendor No.",
          -FindVendorLedgerEntryAmount(PurchaseHeader."Last Posting No."),
          CalcDate('<' + Format(LibraryRandom.RandIntInRange(10, 20)) + 'D>', PurchaseHeader."Due Date"));  // Using Random value for Posting Date.
        FindPaymentTerms(PaymentTerms, PurchaseHeader."Payment Terms Code");
        Amount :=
          FindPurchInvoiceAmountIncludingVAT(
            PurchaseHeader."Last Posting No.") * FindInstallmentPct(PaymentTerms.Code, Format(PaymentTerms."Due Date Calculation")) / 100;
        Amount2 :=
          FindPurchInvoiceAmountIncludingVAT(
            PurchaseHeader."Last Posting No.") *
          (100 - FindInstallmentPct(PaymentTerms.Code, Format(PaymentTerms."Due Date Calculation"))) / 100;
        DueDays :=
          FindVendorLedgerEntryPostingDate(
            PurchaseHeader."Buy-from Vendor No.", VendorLedgerEntry."Document Type"::Payment) - PurchaseHeader."Posting Date";
        EnqueueValuesForRequestPageHandler(
          CalcDate('<-CM - 1M>', PurchaseHeader."Document Date"), CalcDate('<CM + 1M>', PurchaseHeader."Document Date"),
          ShowPayment::All, PurchaseHeader."Buy-from Vendor No.");  // Enqueue values for VendorOverduePaymentsRequestPageHandler and taking one month back and next month date.
        Commit();  // Commit is required.

        // Exercise & Verify.
        RunAndVerifyVendorOverduePaymentsReport(PurchaseHeader, Round(Amount), Round(Amount2), DueDays);
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesWithAppliesToIDModalPageHandler,VendorOverduePaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendorOverduePaymentsTypeAllWithFullPayment()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        PurchaseHeader: Record "Purchase Header";
        ShowPayment: Option Overdue,"Legally Overdue",All;
        Amount: Decimal;
        Amount2: Decimal;
        DueDays: Integer;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Purpose of this test verifies that if Posting Date of applied payment is out of the range that the Invoice is still open in report 10748.

        // Setup: Create and Post Purchase Invoice and Payment.
        Initialize();
        CreateAndPostPurchaseInvoice(PurchaseHeader, CreateVendorWithMultipleInstallmentsSetup());
        CreateAndPostGenJournalLine(
          GenJournalLine."Account Type"::Vendor, PurchaseHeader."Buy-from Vendor No.",
          -FindVendorLedgerEntryAmount(PurchaseHeader."Last Posting No."),
          CalcDate('<' + Format(LibraryRandom.RandIntInRange(10, 20)) + 'D>', PurchaseHeader."Due Date"));  // Using Random value for Posting Date.
        CreateAndPostGenJournalLine(
          GenJournalLine."Account Type"::Vendor, PurchaseHeader."Buy-from Vendor No.",
          -FindVendorLedgerEntryAmount(PurchaseHeader."Last Posting No."),
          CalcDate('<' + Format(LibraryRandom.RandIntInRange(20, 30)) + 'D>', PurchaseHeader."Due Date"));  // Using Random value for Posting Date.
        FindPaymentTerms(PaymentTerms, PurchaseHeader."Payment Terms Code");
        Amount :=
          FindPurchInvoiceAmountIncludingVAT(
            PurchaseHeader."Last Posting No.") * FindInstallmentPct(PaymentTerms.Code, Format(PaymentTerms."Due Date Calculation")) / 100;
        Amount2 :=
          FindPurchInvoiceAmountIncludingVAT(
            PurchaseHeader."Last Posting No.") *
          (100 - FindInstallmentPct(PaymentTerms.Code, Format(PaymentTerms."Due Date Calculation"))) / 100;
        DueDays :=
          FindVendorLedgerEntryPostingDate(
            PurchaseHeader."Buy-from Vendor No.", VendorLedgerEntry."Document Type"::Payment) - PurchaseHeader."Posting Date";
        EnqueueValuesForRequestPageHandler(
          CalcDate('<-CM - 1M>', PurchaseHeader."Document Date"), CalcDate('<CM + 1M>', PurchaseHeader."Document Date"),
          ShowPayment::All, PurchaseHeader."Buy-from Vendor No.");  // Enqueue values for VendorOverduePaymentsRequestPageHandler and taking one month back and next month date.
        Commit();  // Commit is required.

        // Exercise & Verify.
        RunAndVerifyVendorOverduePaymentsReport(PurchaseHeader, Round(Amount), Round(Amount2), DueDays);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GeneralJournalLineDueDateError()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        MaxNoOfDaysTillDueDate: Integer;
    begin
        // [SCENARIO] Purpose of this test verifies the error when Due Date is updated and is outside the limit on General Journal Line.

        // Setup: Create General Journal Line.
        Initialize();
        MaxNoOfDaysTillDueDate := LibraryRandom.RandInt(30);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Customer, GenJournalLine."Document Type"::Bill,
          CreateCustomer(CreatePaymentTerms(MaxNoOfDaysTillDueDate)), LibraryRandom.RandDec(100, 2), WorkDate());  // Using random for Amount.

        // Exercise: Validating Due Date to exceed Max. No. of Days till Due Date.
        asserterror
          GenJournalLine.Validate(
            "Due Date", GenJournalLine."Due Date" + MaxNoOfDaysTillDueDate + LibraryRandom.RandInt(5));

        // Verify: Verify Expected error - The Due Date exceeds the Max. No. of Days till Due Date defined on the Payment Terms.
        Assert.ExpectedError(
          StrSubstNo(DueDateErr, GenJournalLine.FieldCaption("Due Date"), PaymentTerms.FieldCaption("Max. No. of Days till Due Date"),
            PaymentTerms.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DueDateOnPurchaseInvoice()
    var
        PaymentTerms: Record "Payment Terms";
        PaymentDay: Record "Payment Day";
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
    begin
        // [SCENARIO] Test to Verify Program calculates correct Due Date on Purchase Invoice with Spanish Prompt Law objects when Max. No. of days till Due Date =BLANK.

        // Setup: Create Payment Terms. Create Vendor with Payment Day.
        Initialize();
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        VendorNo := CreateVendor(PaymentTerms.Code);
        LibraryESLocalization.CreatePaymentDay(
          PaymentDay, PaymentDay."Table Name"::Vendor, VendorNo, LibraryRandom.RandIntInRange(10, 20));  // Random Payment Day.

        // Exercise: Create Purchase Invoice.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);

        // Verify: Verify Program calculates correct Due Date on Purchase Invoice.
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        PurchaseHeader.TestField("Due Date", CalcDate('<CM>', WorkDate()) + PaymentDay."Day of the month");
    end;

    [Test]
    [HandlerFunctions('CarteraDocumentsModalPageHandler,ConfirmHandler,MessageHandler,SettleDocsInPostedPORequestPageHandler,RedrawPayableBillsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendorLedgerEntryWithSettleDocsRedrawPayableBill()
    var
        PaymentTerms: Record "Payment Terms";
        PurchaseHeader: Record "Purchase Header";
        BankAccountNo: Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Verify Program Calculate correct amount on Vendor Ledger Entries when used to compress entries using date compression.

        // Setup: Create and Post Purchase Invoice, Post Payment Order.
        Initialize();
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        DocumentNo := CreateAndPostPurchaseInvoice(PurchaseHeader, CreateVendor(PaymentTerms.Code));
        LibraryVariableStorage.Enqueue(DocumentNo);
        BankAccountNo := PostPaymentOrders();

        // Exercise: Run Total Settlement and Redraw Payable Bills.
        RunSettleDocsAndRedrawPayablBills(BankAccountNo, PurchaseHeader."Buy-from Vendor No.");  // Open handler for - SettleDocsInPostedPORequestPageHandler,RedrawPayableBillsRequestPageHandler.

        // Verify: Verify Vendor Ledger Entry for Document Type - Bill.
        VerifyAmountOnVendorLedgerEntry(PurchaseHeader."Buy-from Vendor No.", DocumentNo);
    end;

    [Test]
    [HandlerFunctions('CarteraDocumentsModalPageHandler,ConfirmHandler,MessageHandler,SettleDocsInPostedPORequestPageHandler,RedrawReceivableBillsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerLedgerEntryWithSettleDocsRedrawReceivableBill()
    var
        PaymentTerms: Record "Payment Terms";
        SalesHeader: Record "Sales Header";
        BankAccountNo: Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Verify Program Calculate correct amount on Customer Ledger Entries when used to compress entries using date compression.

        // Setup: Create and Post Sales Invoice and Post Payment Order.
        Initialize();
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        DocumentNo := CreateAndPostSalesInvoice(SalesHeader, CreateCustomer(PaymentTerms.Code));
        LibraryVariableStorage.Enqueue(DocumentNo);
        BankAccountNo := PostPaymentOrders();

        // Exercise: Run Total Settlement and Redraw Receivable Bills.
        RunSettleDocsAndRedrawReceivableBills(BankAccountNo, SalesHeader."Sell-to Customer No.");  // Open handler for - SettleDocsInPostedPORequestPageHandler,RedrawReceivableBillsRequestPageHandler.

        // Verify: Verify Customer Ledger Entry for Document Type - Bill.
        VerifyAmountOnCustomerLedgerEntry(SalesHeader."Sell-to Customer No.", DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorPaymentAppliesToDocDueDate()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase] [Bill]
        // [SCENARIO 380382] Applies-to Doc Due Date field on the Payment Journal must inherit the Due Date of the installment in all the bills.

        Initialize();

        // [GIVEN] Create and Post Purchase Invoice
        CreateAndPostPurchaseInvoice(PurchaseHeader, CreateVendorWithMultipleInstallmentsSetup());

        // [WHEN] Gen. Journal Line to pay the bill
        CreateVendorPayment(GenJournalLine, PurchaseHeader);

        // [THEN] Verify applied document Due Date
        VerifyVendorPaymentDueDate(GenJournalLine, PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerPaymentAppliesToDocDueDate()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales] [Bill]
        // [SCENARIO 380382] Applies-to Doc Due Date field on the Payment Journal must inherit the Due Date of the installment in all the bills.
        Initialize();

        // [GIVEN] Create and Post Sales Invoice
        CreateAndPostSalesInvoice(SalesHeader, CreateCustomerWithMultipleInstallmentsSetup());

        // [WHEN] Gen. Journal Line to pay the bill
        CreateCustomerPayment(GenJournalLine, SalesHeader);

        // [THEN] Verify applied document Due Date
        VerifyCustomerPaymentDueDate(GenJournalLine, SalesHeader);
    end;

    [Test]
    [HandlerFunctions('CustomerOverduePaymentsFileNameRequestPageHandler')]
    procedure CustomerOverduePaymentsWithinOutsideLegalDueDateShowAll()
    var
        GenJournalLine: array[3] of record "Gen. Journal Line";
        CustomerNo: Code[20];
        XmlFileName: Text;
        ShowPayment: Option Overdue,"Legally Overdue",All;
        Amount: array[3] of Decimal;
        i: Integer;
    begin
        // [SCENARIO 440275] "Payments within/outside the legal limit" value when run Customer - Overdue Payments with Show Payments All.
        Initialize();

        // [GIVEN] Customer with Payment Terms with Max. No. of Days till Due Date = 30.
        CustomerNo := CreateCustomer(CreatePaymentTerms(30));

        // [GIVEN] Three posted Sales Invoices with Amounts 100, 1000, 10000.
        for i := 1 to 3 do begin
            Amount[i] := LibraryRandom.RandDecInRange(10 * Power(10, i), 20 * Power(10, i), 2);
            CreateGeneralJournalLine(
                GenJournalLine[i], "Gen. Journal Account Type"::Customer,
                "Gen. Journal Document Type"::Invoice, CustomerNo, Amount[i], WorkDate());
            LibraryERM.PostGeneralJnlLine(GenJournalLine[i]);
        end;

        // [GIVEN] Three payments applied to posted Sales Invoices.
        // [GIVEN] First invoice is paid before due date, second is paid after due date, but before legal due date, third is paid after legal due date.
        CreateAndApplyPayment(GenJournalLine[1], WorkDate() + 1);
        CreateAndApplyPayment(GenJournalLine[2], WorkDate() + 15);
        CreateAndApplyPayment(GenJournalLine[3], WorkDate() + 45);

        // [WHEN] Run Customer - Overdue Payments report with Show Payments = All on Customer.
        EnqueueValuesForRequestPageHandler(
            CalcDate('<-CM>', WorkDate()), CalcDate('<CM + 1M>', WorkDate()), ShowPayment::All, CustomerNo);
        Report.Run(Report::"Customer - Overdue Payments");

        // [THEN] Footer has Payments within the legal limit = A1 + A2; Payments outside the legal limit = A3.
        XmlFileName := LibraryVariableStorage.DequeueText();
        LibraryXPathXMLReader.Initialize(XmlFileName, '');
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex('//DataSet/Result/TotalPaymentWithinDueDate', DelChr(Format(Round(Amount[1] + Amount[2], 0.01), 0, '<Precision,2><Integer><Decimal>'), '=', ','), 2);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex('//DataSet/Result/TotalPaymentOutsideDueDate', DelChr(Format(Round(Amount[3], 0.01), 0, '<Precision,2><Integer><Decimal>'), '=', ','), 2);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('//DataSet/Result/TotalPaymentWithinDueDate', 3);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('//DataSet/Result/TotalPaymentOutsideDueDate', 3);
    end;

    [Test]
    [HandlerFunctions('CustomerOverduePaymentsFileNameRequestPageHandler')]
    procedure CustomerOverduePaymentsWithinOutsideLegalDueDateShowOverdue()
    var
        GenJournalLine: array[3] of record "Gen. Journal Line";
        CustomerNo: Code[20];
        XmlFileName: Text;
        ShowPayment: Option Overdue,"Legally Overdue",All;
        Amount: array[3] of Decimal;
        i: Integer;
    begin
        // [SCENARIO 440275] "Payments within/outside the legal limit" value when run Customer - Overdue Payments with Show Payments Overdue.
        Initialize();

        // [GIVEN] Customer with Payment Terms with Max. No. of Days till Due Date = 30.
        CustomerNo := CreateCustomer(CreatePaymentTerms(30));

        // [GIVEN] Three posted Sales Invoices with Amounts 100, 1000, 10000.
        for i := 1 to 3 do begin
            Amount[i] := LibraryRandom.RandDecInRange(10 * Power(10, i), 20 * Power(10, i), 2);
            CreateGeneralJournalLine(
                GenJournalLine[i], "Gen. Journal Account Type"::Customer,
                "Gen. Journal Document Type"::Invoice, CustomerNo, Amount[i], WorkDate());
            LibraryERM.PostGeneralJnlLine(GenJournalLine[i]);
        end;

        // [GIVEN] Three payments applied to posted Sales Invoices.
        // [GIVEN] First invoice is paid before due date, second is paid after due date, but before legal due date, third is paid after legal due date.
        CreateAndApplyPayment(GenJournalLine[1], WorkDate() + 1);
        CreateAndApplyPayment(GenJournalLine[2], WorkDate() + 15);
        CreateAndApplyPayment(GenJournalLine[3], WorkDate() + 45);

        // [WHEN] Run Customer - Overdue Payments report with Show Payments = Overdue on Customer.
        EnqueueValuesForRequestPageHandler(
            CalcDate('<-CM>', WorkDate()), CalcDate('<CM + 1M>', WorkDate()), ShowPayment::Overdue, CustomerNo);
        Report.Run(Report::"Customer - Overdue Payments");

        // [THEN] Footer has Payments within the legal limit = A2; Payments outside the legal limit = A3.
        XmlFileName := LibraryVariableStorage.DequeueText();
        LibraryXPathXMLReader.Initialize(XmlFileName, '');
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex('//DataSet/Result/TotalPaymentWithinDueDate', Format(Amount[2], 0, 9), 1);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex('//DataSet/Result/TotalPaymentOutsideDueDate', Format(Amount[3], 0, 9), 1);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('//DataSet/Result/TotalPaymentWithinDueDate', 2);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('//DataSet/Result/TotalPaymentOutsideDueDate', 2);
    end;

    [Test]
    [HandlerFunctions('CustomerOverduePaymentsFileNameRequestPageHandler')]
    procedure CustomerOverduePaymentsWithinOutsideLegalDueDateShowLegallyOverdue()
    var
        GenJournalLine: array[3] of record "Gen. Journal Line";
        CustomerNo: Code[20];
        XmlFileName: Text;
        ShowPayment: Option Overdue,"Legally Overdue",All;
        Amount: array[3] of Decimal;
        i: Integer;
    begin
        // [SCENARIO 440275] "Payments within/outside the legal limit" value when run Customer - Overdue Payments with Show Payments Legally Overdue.
        Initialize();

        // [GIVEN] Customer with Payment Terms with Max. No. of Days till Due Date = 30.
        CustomerNo := CreateCustomer(CreatePaymentTerms(30));

        // [GIVEN] Three posted Sales Invoices with Amounts 100, 1000, 10000.
        for i := 1 to 3 do begin
            Amount[i] := LibraryRandom.RandDecInRange(10 * Power(10, i), 20 * Power(10, i), 2);
            CreateGeneralJournalLine(
                GenJournalLine[i], "Gen. Journal Account Type"::Customer,
                "Gen. Journal Document Type"::Invoice, CustomerNo, Amount[i], WorkDate());
            LibraryERM.PostGeneralJnlLine(GenJournalLine[i]);
        end;

        // [GIVEN] Three payments applied to posted Sales Invoices.
        // [GIVEN] First invoice is paid before due date, second is paid after due date, but before legal due date, third is paid after legal due date.
        CreateAndApplyPayment(GenJournalLine[1], WorkDate() + 1);
        CreateAndApplyPayment(GenJournalLine[2], WorkDate() + 15);
        CreateAndApplyPayment(GenJournalLine[3], WorkDate() + 45);

        // [WHEN] Run Customer - Overdue Payments report with Show Payments = Legally Overdue on Customer.
        EnqueueValuesForRequestPageHandler(
            CalcDate('<-CM>', WorkDate()), CalcDate('<CM + 1M>', WorkDate()), ShowPayment::"Legally Overdue", CustomerNo);
        Report.Run(Report::"Customer - Overdue Payments");

        // [THEN] Footer has Payments within the legal limit = 0; Payments outside the legal limit = A3.
        XmlFileName := LibraryVariableStorage.DequeueText();
        LibraryXPathXMLReader.Initialize(XmlFileName, '');
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex('//DataSet/Result/TotalPaymentWithinDueDate', Format(0, 0, 9), 0);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex('//DataSet/Result/TotalPaymentOutsideDueDate', Format(Amount[3], 0, 9), 0);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('//DataSet/Result/TotalPaymentWithinDueDate', 1);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('//DataSet/Result/TotalPaymentOutsideDueDate', 1);
    end;

    [Test]
    [HandlerFunctions('VendorOverduePaymentsFileNameRequestPageHandler')]
    procedure VendorOverduePaymentsWithinOutsideLegalDueDateShowAll()
    var
        GenJournalLine: array[3] of record "Gen. Journal Line";
        VendorNo: Code[20];
        XmlFileName: Text;
        ShowPayment: Option Overdue,"Legally Overdue",All;
        Amount: array[3] of Decimal;
        i: Integer;
    begin
        // [SCENARIO 440275] "Payments within/outside the legal limit" value when run Vendor - Overdue Payments with Show Payments All.
        Initialize();

        // [GIVEN] Vendor with Payment Terms with Max. No. of Days till Due Date = 30.
        VendorNo := CreateVendor(CreatePaymentTerms(30));

        // [GIVEN] Three posted Purchase Invoices with Amounts 100, 1000, 10000.
        for i := 1 to 3 do begin
            Amount[i] := LibraryRandom.RandDecInRange(10 * Power(10, i), 20 * Power(10, i), 2);
            CreateGeneralJournalLine(
                GenJournalLine[i], "Gen. Journal Account Type"::Vendor,
                "Gen. Journal Document Type"::Invoice, VendorNo, -Amount[i], WorkDate());
            LibraryERM.PostGeneralJnlLine(GenJournalLine[i]);
        end;

        // [GIVEN] Three payments applied to posted Purchase Invoices.
        // [GIVEN] First invoice is paid before due date, second is paid after due date, but before legal due date, third is paid after legal due date.
        CreateAndApplyPayment(GenJournalLine[1], WorkDate() + 1);
        CreateAndApplyPayment(GenJournalLine[2], WorkDate() + 15);
        CreateAndApplyPayment(GenJournalLine[3], WorkDate() + 45);

        // [WHEN] Run Vendor - Overdue Payments report with Show Payments = All on Vendor.
        EnqueueValuesForRequestPageHandler(
            CalcDate('<-CM>', WorkDate()), CalcDate('<CM + 1M>', WorkDate()), ShowPayment::All, VendorNo);
        Report.Run(Report::"Vendor - Overdue Payments");

        // [THEN] Footer has Payments within the legal limit = A1 + A2; Payments outside the legal limit = A3.
        XmlFileName := LibraryVariableStorage.DequeueText();
        LibraryXPathXMLReader.Initialize(XmlFileName, '');
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex('//DataSet/Result/TotalPaymentWithinDueDate', DelChr(Format(Round(Amount[1] + Amount[2], 0.01), 0, '<Precision,2><Integer><Decimal>'), '=', ','), 2);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex('//DataSet/Result/TotalPaymentOutsideDueDate', DelChr(Format(Round(Amount[3], 0.01), 0, '<Precision,2><Integer><Decimal>'), '=', ','), 2);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('//DataSet/Result/TotalPaymentWithinDueDate', 3);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('//DataSet/Result/TotalPaymentOutsideDueDate', 3);
    end;

    [Test]
    [HandlerFunctions('VendorOverduePaymentsFileNameRequestPageHandler')]
    procedure VendorOverduePaymentsWithinOutsideLegalDueDateShowOverdue()
    var
        GenJournalLine: array[3] of record "Gen. Journal Line";
        VendorNo: Code[20];
        XmlFileName: Text;
        ShowPayment: Option Overdue,"Legally Overdue",All;
        Amount: array[3] of Decimal;
        i: Integer;
    begin
        // [SCENARIO 440275] "Payments within/outside the legal limit" value when run Vendor - Overdue Payments with Show Payments Overdue.
        Initialize();

        // [GIVEN] Vendor with Payment Terms with Max. No. of Days till Due Date = 30.
        VendorNo := CreateVendor(CreatePaymentTerms(30));

        // [GIVEN] Three posted Purchase Invoices with Amounts 100, 1000, 10000.
        for i := 1 to 3 do begin
            Amount[i] := LibraryRandom.RandDecInRange(10 * Power(10, i), 20 * Power(10, i), 2);
            CreateGeneralJournalLine(
                GenJournalLine[i], "Gen. Journal Account Type"::Vendor,
                "Gen. Journal Document Type"::Invoice, VendorNo, -Amount[i], WorkDate());
            LibraryERM.PostGeneralJnlLine(GenJournalLine[i]);
        end;

        // [GIVEN] Three payments applied to posted Purchase Invoices.
        // [GIVEN] First invoice is paid before due date, second is paid after due date, but before legal due date, third is paid after legal due date.
        CreateAndApplyPayment(GenJournalLine[1], WorkDate() + 1);
        CreateAndApplyPayment(GenJournalLine[2], WorkDate() + 15);
        CreateAndApplyPayment(GenJournalLine[3], WorkDate() + 45);

        // [WHEN] Run Vendor - Overdue Payments report with Show Payments = Overdue on Vendor.
        EnqueueValuesForRequestPageHandler(
            CalcDate('<-CM>', WorkDate()), CalcDate('<CM + 1M>', WorkDate()), ShowPayment::Overdue, VendorNo);
        Report.Run(Report::"Vendor - Overdue Payments");

        // [THEN] Footer has Payments within the legal limit = A2; Payments outside the legal limit = A3.
        XmlFileName := LibraryVariableStorage.DequeueText();
        LibraryXPathXMLReader.Initialize(XmlFileName, '');
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex('//DataSet/Result/TotalPaymentWithinDueDate', Format(Amount[2], 0, 9), 1);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex('//DataSet/Result/TotalPaymentOutsideDueDate', Format(Amount[3], 0, 9), 1);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('//DataSet/Result/TotalPaymentWithinDueDate', 2);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('//DataSet/Result/TotalPaymentOutsideDueDate', 2);
    end;

    [Test]
    [HandlerFunctions('VendorOverduePaymentsFileNameRequestPageHandler')]
    procedure VendorOverduePaymentsWithinOutsideLegalDueDateShowLegallyOverdue()
    var
        GenJournalLine: array[3] of record "Gen. Journal Line";
        VendorNo: Code[20];
        XmlFileName: Text;
        ShowPayment: Option Overdue,"Legally Overdue",All;
        Amount: array[3] of Decimal;
        i: Integer;
    begin
        // [SCENARIO 440275] "Payments within/outside the legal limit" value when run Vendor - Overdue Payments with Show Payments Legally Overdue.
        Initialize();

        // [GIVEN] Vendor with Payment Terms with Max. No. of Days till Due Date = 30.
        VendorNo := CreateVendor(CreatePaymentTerms(30));

        // [GIVEN] Three posted Purchase Invoices with Amounts 100, 1000, 10000.
        for i := 1 to 3 do begin
            Amount[i] := LibraryRandom.RandDecInRange(10 * Power(10, i), 20 * Power(10, i), 2);
            CreateGeneralJournalLine(
                GenJournalLine[i], "Gen. Journal Account Type"::Vendor,
                "Gen. Journal Document Type"::Invoice, VendorNo, -Amount[i], WorkDate());
            LibraryERM.PostGeneralJnlLine(GenJournalLine[i]);
        end;

        // [GIVEN] Three payments applied to posted Purchase Invoices.
        // [GIVEN] First invoice is paid before due date, second is paid after due date, but before legal due date, third is paid after legal due date.
        CreateAndApplyPayment(GenJournalLine[1], WorkDate() + 1);
        CreateAndApplyPayment(GenJournalLine[2], WorkDate() + 15);
        CreateAndApplyPayment(GenJournalLine[3], WorkDate() + 45);

        // [WHEN] Run Vendor - Overdue Payments report with Show Payments = Legally Overdue on Vendor.
        EnqueueValuesForRequestPageHandler(
            CalcDate('<-CM>', WorkDate()), CalcDate('<CM + 1M>', WorkDate()), ShowPayment::"Legally Overdue", VendorNo);
        Report.Run(Report::"Vendor - Overdue Payments");

        // [THEN] Footer has Payments within the legal limit =0; Payments outside the legal limit = A3.
        XmlFileName := LibraryVariableStorage.DequeueText();
        LibraryXPathXMLReader.Initialize(XmlFileName, '');
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex('//DataSet/Result/TotalPaymentWithinDueDate', Format(0, 0, 9), 0);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex('//DataSet/Result/TotalPaymentOutsideDueDate', Format(Amount[3], 0, 9), 0);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('//DataSet/Result/TotalPaymentWithinDueDate', 1);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('//DataSet/Result/TotalPaymentOutsideDueDate', 1);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateAndPostGenJournalLine(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal; PostingDate: Date)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateGeneralJournalLine(
          GenJournalLine, AccountType, GenJournalLine."Document Type"::Payment, AccountNo, Amount, PostingDate);
        OpenAndApplyGeneralJournal(GenJournalLine."Document Type"::Payment, GenJournalLine."Document No.");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostPurchaseInvoice(var PurchaseHeader: Record "Purchase Header"; BuyFromVendorNo: Code[20]): Code[20]
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, BuyFromVendorNo);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(10, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));  // Using True for Receive and Invoice.
    end;

    local procedure CreateAndPostSalesInvoice(var SalesHeader: Record "Sales Header"; SellToCustomerNo: Code[20]): Code[20]
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, SellToCustomerNo);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(10, 2));  // Using Random value for Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));  // Using True for Ship and Invoice.
    end;

    local procedure CreateCustomer(PaymentTermsCode: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Terms Code", PaymentTermsCode);
        Customer.Validate("Payment Method Code", FindPaymentMethod());
        Customer.Validate("Payment Days Code", Customer."No.");
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerPayment(var GenJournalLine: Record "Gen. Journal Line"; SalesHeader: Record "Sales Header")
    begin
        CreateGeneralJournalLine(
          GenJournalLine,
          GenJournalLine."Account Type"::Customer,
          GenJournalLine."Document Type"::Payment,
          SalesHeader."Sell-to Customer No.",
          0,
          SalesHeader."Posting Date");
    end;

    local procedure CreateAndApplyPayment(CustomerVendorDocGenJnlLine: Record "Gen. Journal Line"; PostingDate: Date)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateGeneralJournalLine(
            GenJournalLine, CustomerVendorDocGenJnlLine."Account Type", "Gen. Journal Document Type"::Payment,
            CustomerVendorDocGenJnlLine."Account No.", 0, PostingDate);
        GenJournalLine.Validate("Applies-to Doc. Type", CustomerVendorDocGenJnlLine."Document Type");
        GenJournalLine.Validate("Applies-to Doc. No.", CustomerVendorDocGenJnlLine."Document No.");
        GenJournalLine.Validate(Amount, -CustomerVendorDocGenJnlLine.Amount);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateCustomerWithMultipleInstallmentsSetup(): Code[20]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        CreateMultipleInstallmentForPaymentTerms(PaymentTerms);
        exit(CreateCustomer(PaymentTerms.Code));
    end;

    local procedure CreateInstallment(PaymentTerms: Record "Payment Terms"; PctOfTotal: Decimal; DueDateCalculation: Code[20])
    var
        Installment: Record Installment;
    begin
        LibraryESLocalization.CreateInstallment(Installment, PaymentTerms.Code);
        Installment.Validate("% of Total", PctOfTotal);
        Installment.Validate("Gap between Installments", Format(DueDateCalculation));
        Installment.Modify(true);
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; DocumentType: Enum "Gen. Journal Document Type"; AccountNo: Code[20]; Amount: Decimal; PostingDate: Date)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType, AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateMultipleInstallmentForPaymentTerms(var PaymentTerms: Record "Payment Terms")
    begin
        PaymentTerms.Get(CreatePaymentTerms(0));  // 0 - Max. No. of Days till Due Date.
        PaymentTerms.Validate("VAT distribution", PaymentTerms."VAT distribution"::Proportional);
        PaymentTerms.Modify(true);
        CreateInstallment(PaymentTerms, LibraryRandom.RandIntInRange(10, 50), Format(PaymentTerms."Due Date Calculation"));  // Using Random value for Pct Total.
        CreateInstallment(PaymentTerms, LibraryRandom.RandIntInRange(10, 50), '');  // Using Random value for Pct Total and blank for Due Date Calculation.
    end;

    local procedure CreatePaymentTerms(MaxNoOfDaysTillDueDate: Integer): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        PaymentTerms.Validate("Max. No. of Days till Due Date", MaxNoOfDaysTillDueDate);
        Evaluate(PaymentTerms."Due Date Calculation", (Format(LibraryRandom.RandIntInRange(5, 10)) + 'D'));
        PaymentTerms.Validate("Calc. Pmt. Disc. on Cr. Memos", true);
        PaymentTerms.Modify(true);
        exit(PaymentTerms.Code);
    end;

    local procedure CreateVendor(PaymentTermsCode: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Payment Method Code", FindPaymentMethod());
        Vendor.Validate("Payment Terms Code", PaymentTermsCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateVendorPayment(var GenJournalLine: Record "Gen. Journal Line"; PurchaseHeader: Record "Purchase Header")
    begin
        CreateGeneralJournalLine(
          GenJournalLine,
          GenJournalLine."Account Type"::Vendor,
          GenJournalLine."Document Type"::Payment,
          PurchaseHeader."Buy-from Vendor No.",
          0,
          PurchaseHeader."Posting Date");
    end;

    local procedure CreateVendorWithMultipleInstallmentsSetup(): Code[20]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        CreateMultipleInstallmentForPaymentTerms(PaymentTerms);
        exit(CreateVendor(PaymentTerms.Code));
    end;

    local procedure EnqueueValuesForRequestPageHandler(StartDate: Date; EndDate: Date; ShowPayment: Option; No: Code[20])
    begin
        LibraryVariableStorage.Enqueue(StartDate);
        LibraryVariableStorage.Enqueue(EndDate);
        LibraryVariableStorage.Enqueue(ShowPayment);
        LibraryVariableStorage.Enqueue(No);
    end;

    local procedure FindCustomerLedgerEntryAmount(DocumentNo: Code[20]): Decimal
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, DocumentNo);
        CustLedgerEntry.CalcFields(Amount);
        exit(CustLedgerEntry.Amount);
    end;

    local procedure FindCustomerLedgerEntryPostingDate(CustomerNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"): Date
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange("Document Type", DocumentType);
        CustLedgerEntry.FindFirst();
        exit(CustLedgerEntry."Posting Date");
    end;

    local procedure FindSalesInvoiceAmountIncludingVAT(DocumentNo: Code[20]): Decimal
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.Get(DocumentNo);
        SalesInvoiceHeader.CalcFields("Amount Including VAT");
        exit(SalesInvoiceHeader."Amount Including VAT");
    end;

    local procedure FindPurchInvoiceAmountIncludingVAT(DocumentNo: Code[20]): Decimal
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.Get(DocumentNo);
        PurchInvHeader.CalcFields("Amount Including VAT");
        exit(PurchInvHeader."Amount Including VAT");
    end;

    local procedure FindInstallmentPct(PaymentTermsCode: Code[10]; GapBetweenInstallments: Code[20]): Decimal
    var
        Installment: Record Installment;
    begin
        Installment.SetRange("Payment Terms Code", PaymentTermsCode);
        Installment.SetRange("Gap between Installments", GapBetweenInstallments);
        Installment.FindFirst();
        exit(Installment."% of Total");
    end;

    local procedure FindPaymentMethod(): Code[10]
    var
        PaymentMethod: Record "Payment Method";
    begin
        PaymentMethod.SetRange("Create Bills", true);
        PaymentMethod.FindFirst();
        exit(PaymentMethod.Code);
    end;

    local procedure FindPaymentTerms(var PaymentTerms: Record "Payment Terms"; PaymentTermsCode: Code[10])
    begin
        PaymentTerms.SetRange(Code, PaymentTermsCode);
        PaymentTerms.FindFirst();
    end;

    local procedure FindVendorLedgerEntryAmount(DocumentNo: Code[20]): Decimal
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, DocumentNo);
        VendorLedgerEntry.CalcFields(Amount);
        exit(VendorLedgerEntry.Amount);
    end;

    local procedure FindVendorLedgerEntryPostingDate(VendorNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"): Date
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetRange("Document Type", DocumentType);
        VendorLedgerEntry.FindFirst();
        exit(VendorLedgerEntry."Posting Date");
    end;

    local procedure PostPaymentOrders(): Code[20]
    var
        BankAccount: Record "Bank Account";
        PaymentOrders: TestPage "Payment Orders";
    begin
        LibraryERM.FindBankAccount(BankAccount);
        PaymentOrders.OpenNew();
        PaymentOrders."Bank Account No.".SetValue(BankAccount."No.");
        PaymentOrders.Docs.Insert.Invoke();
        PaymentOrders.Post.Invoke();
        exit(BankAccount."No.");
    end;

    local procedure OpenAndApplyGeneralJournal(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    var
        GeneralJournal: TestPage "General Journal";
    begin
        GeneralJournal.OpenEdit();
        GeneralJournal.FILTER.SetFilter("Document Type", Format(DocumentType));
        GeneralJournal.FILTER.SetFilter("Document No.", DocumentNo);
        GeneralJournal."Apply Entries".Invoke();  // Invoke ApplyCustomerEntriesWithAppliesToIDModalPageHandler and ApplyVendorEntriesWithAppliesToIDModalPageHandler.
        GeneralJournal.Close();
    end;

    local procedure RunAndVerifyCustomerOverduePaymentsReport(SalesHeader: Record "Sales Header"; Amount: Decimal; Amount2: Decimal; DueDays: Integer)
    begin
        // Exercise.
        REPORT.Run(REPORT::"Customer - Overdue Payments");

        // Verify: Verify Customer No,Amount,Amount,DocumentNo and Due Date on report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(CustomerNoCap, SalesHeader."Sell-to Customer No.");
        LibraryReportDataset.AssertElementWithValueExists(ABSAmountCap, Round(Amount));
        LibraryReportDataset.AssertElementWithValueExists(ABSAmountCap, Round(Amount2));
        LibraryReportDataset.AssertElementWithValueExists(DocumentNoCap, SalesHeader."Last Posting No.");
        LibraryReportDataset.AssertElementWithValueExists(DaysOverdueCap, DueDays);
    end;

    local procedure RunAndVerifyVendorOverduePaymentsReport(PurchaseHeader: Record "Purchase Header"; Amount: Decimal; Amount2: Decimal; DueDays: Integer)
    begin
        // Exercise.
        REPORT.Run(REPORT::"Vendor - Overdue Payments");

        // Verify: Verify Vendor No,Amount,Amount,DocumentNo and Due Date on report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(VendorNoCap, PurchaseHeader."Buy-from Vendor No.");
        LibraryReportDataset.AssertElementWithValueExists(ABSAmountCap, Round(Amount));
        LibraryReportDataset.AssertElementWithValueExists(ABSAmountCap, Round(Amount2));
        LibraryReportDataset.AssertElementWithValueExists(VendorDocumentNoCap, PurchaseHeader."Last Posting No.");
        LibraryReportDataset.AssertElementWithValueExists(DaysOverdueCap, DueDays);
    end;

    local procedure RunSettleDocs(BankAccountNo: Code[20])
    var
        PostedCarteraDoc: Record "Posted Cartera Doc.";
        SettleDocsInPostedPO: Report "Settle Docs. in Posted PO";
    begin
        PostedCarteraDoc.SetRange("Bank Account No.", BankAccountNo);
        SettleDocsInPostedPO.SetTableView(PostedCarteraDoc);
        SettleDocsInPostedPO.Run();  // Opens handler - SettleDocsInPostedPORequestPageHandler.
    end;

    local procedure VerifyAmountOnCustomerLedgerEntry(CustomerNo: Code[20]; DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Bill);
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.CalcFields(Amount);
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.FindFirst();
        Assert.AreNearlyEqual(
          SalesInvoiceLine."Amount Including VAT", CustLedgerEntry.Amount, LibraryERM.GetAmountRoundingPrecision(), AmountMustMatchMsg);
    end;

    local procedure VerifyAmountOnVendorLedgerEntry(VendorNo: Code[20]; DocumentNo: Code[20])
    var
        PurchInvLine: Record "Purch. Inv. Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Bill);
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.CalcFields(Amount);
        PurchInvLine.SetRange("Document No.", DocumentNo);
        PurchInvLine.FindFirst();
        Assert.AreNearlyEqual(
          -PurchInvLine."Amount Including VAT", VendorLedgerEntry.Amount, LibraryERM.GetAmountRoundingPrecision(), AmountMustMatchMsg);
    end;

    local procedure VerifyCustomerPaymentDueDate(var GenJournalLine: Record "Gen. Journal Line"; SalesHeader: Record "Sales Header")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Bill);
        CustLedgerEntry.SetRange("Customer No.", SalesHeader."Sell-to Customer No.");
        CustLedgerEntry.SetRange("Document No.", SalesHeader."Last Posting No.");
        if CustLedgerEntry.FindSet() then
            repeat
                GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Bill);
                GenJournalLine.Validate("Applies-to Doc. No.", SalesHeader."Last Posting No.");
                GenJournalLine.Validate("Applies-to Bill No.", CustLedgerEntry."Bill No.");
                Assert.AreEqual(CustLedgerEntry."Due Date",
                  GenJournalLine.GetAppliesToDocDueDate(),
                  DueDatesAreNotEqualErr);
            until CustLedgerEntry.Next() = 0;
    end;

    local procedure VerifyVendorPaymentDueDate(var GenJournalLine: Record "Gen. Journal Line"; PurchaseHeader: Record "Purchase Header")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Bill);
        VendorLedgerEntry.SetRange("Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        VendorLedgerEntry.SetRange("Document No.", PurchaseHeader."Last Posting No.");
        if VendorLedgerEntry.FindSet() then
            repeat
                GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Bill);
                GenJournalLine.Validate("Applies-to Doc. No.", PurchaseHeader."Last Posting No.");
                GenJournalLine.Validate("Applies-to Bill No.", VendorLedgerEntry."Bill No.");
                Assert.AreEqual(VendorLedgerEntry."Due Date",
                  GenJournalLine.GetAppliesToDocDueDate(),
                  DueDatesAreNotEqualErr);
            until VendorLedgerEntry.Next() = 0;
    end;

    local procedure RunSettleDocsAndRedrawPayablBills(BankAccountNo: Code[20]; VendorNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        RedrawPayableBills: Report "Redraw Payable Bills";
    begin
        Commit();  // Commit Required.
        RunSettleDocs(BankAccountNo);
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        RedrawPayableBills.SetTableView(VendorLedgerEntry);
        RedrawPayableBills.Run();  // Open handler - RedrawPayableBillsRequestPageHandler.
    end;

    local procedure RunSettleDocsAndRedrawReceivableBills(BankAccountNo: Code[20]; CustomerNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        RedrawReceivableBills: Report "Redraw Receivable Bills";
    begin
        Commit();  // Commit Required.
        RunSettleDocs(BankAccountNo);
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        RedrawReceivableBills.SetTableView(CustLedgerEntry);
        RedrawReceivableBills.Run();  // Open handler - RedrawReceivableBillsRequestPageHandler.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CarteraDocumentsModalPageHandler(var CarteraDocuments: TestPage "Cartera Documents")
    var
        DocumentNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNo);
        CarteraDocuments."Document No.".SetValue(DocumentNo);
        CarteraDocuments.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesWithAppliesToIDModalPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries."Set Applies-to ID".Invoke();
        ApplyCustomerEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyVendorEntriesWithAppliesToIDModalPageHandler(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    begin
        ApplyVendorEntries.ActionSetAppliesToID.Invoke();
        ApplyVendorEntries.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RedrawPayableBillsRequestPageHandler(var RedrawPayableBills: TestRequestPage "Redraw Payable Bills")
    begin
        RedrawPayableBills.NewDueDate.SetValue(CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate()));
        RedrawPayableBills.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RedrawReceivableBillsRequestPageHandler(var RedrawReceivableBills: TestRequestPage "Redraw Receivable Bills")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Cartera);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        GenJournalBatch.SetRange("Template Type", GenJournalBatch."Template Type"::Cartera);
        LibraryERM.FindGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        RedrawReceivableBills.NewDueDate.SetValue(CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate()));
        RedrawReceivableBills.AuxJnlTemplateName.SetValue(GenJournalTemplate.Name);
        RedrawReceivableBills.AuxJnlBatchName.SetValue(GenJournalBatch.Name);
        RedrawReceivableBills.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SettleDocsInPostedPORequestPageHandler(var SettleDocsInPostedPO: TestRequestPage "Settle Docs. in Posted PO")
    begin
        SettleDocsInPostedPO.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerOverduePaymentsRequestPageHandler(var CustomerOverduePayments: TestRequestPage "Customer - Overdue Payments")
    var
        EndDate: Variant;
        No: Variant;
        StartDate: Variant;
        ShowPayments: Variant;
    begin
        LibraryVariableStorage.Dequeue(StartDate);
        LibraryVariableStorage.Dequeue(EndDate);
        LibraryVariableStorage.Dequeue(ShowPayments);
        LibraryVariableStorage.Dequeue(No);
        CustomerOverduePayments.StartDate.SetValue(StartDate);
        CustomerOverduePayments.EndDate.SetValue(EndDate);
        CustomerOverduePayments.ShowPayments.SetValue(ShowPayments);
        CustomerOverduePayments.Customer.SetFilter("No.", No);
        CustomerOverduePayments.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    procedure CustomerOverduePaymentsFileNameRequestPageHandler(var CustomerOverduePayments: TestRequestPage "Customer - Overdue Payments")
    var
        FileName: Text;
    begin
        FileName := FileMgt.ServerTempFileName('xml');
        CustomerOverduePayments.StartDate.SetValue(LibraryVariableStorage.DequeueDate());
        CustomerOverduePayments.EndDate.SetValue(LibraryVariableStorage.DequeueDate());
        CustomerOverduePayments.ShowPayments.SetValue(LibraryVariableStorage.DequeueInteger());
        CustomerOverduePayments.Customer.SetFilter("No.", LibraryVariableStorage.DequeueText());
        CustomerOverduePayments.SaveAsXml(FileMgt.ServerTempFileName('xml'), FileName);
        LibraryVariableStorage.Enqueue(FileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorOverduePaymentsRequestPageHandler(var VendorOverduePayments: TestRequestPage "Vendor - Overdue Payments")
    var
        EndDate: Variant;
        No: Variant;
        StartDate: Variant;
        ShowPayments: Variant;
    begin
        LibraryVariableStorage.Dequeue(StartDate);
        LibraryVariableStorage.Dequeue(EndDate);
        LibraryVariableStorage.Dequeue(ShowPayments);
        LibraryVariableStorage.Dequeue(No);
        VendorOverduePayments.StartDate.SetValue(StartDate);
        VendorOverduePayments.EndDate.SetValue(EndDate);
        VendorOverduePayments.ShowPayments.SetValue(ShowPayments);
        VendorOverduePayments.Vendor.SetFilter("No.", No);
        VendorOverduePayments.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    procedure VendorOverduePaymentsFileNameRequestPageHandler(var VendorOverduePayments: TestRequestPage "Vendor - Overdue Payments")
    var
        FileName: Text;
    begin
        FileName := FileMgt.ServerTempFileName('xml');
        VendorOverduePayments.StartDate.SetValue(LibraryVariableStorage.DequeueDate());
        VendorOverduePayments.EndDate.SetValue(LibraryVariableStorage.DequeueDate());
        VendorOverduePayments.ShowPayments.SetValue(LibraryVariableStorage.DequeueInteger());
        VendorOverduePayments.Vendor.SetFilter("No.", LibraryVariableStorage.DequeueText());
        VendorOverduePayments.SaveAsXml(FileMgt.ServerTempFileName('xml'), FileName);
        LibraryVariableStorage.Enqueue(FileName);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Msg: Text)
    begin
    end;
}

