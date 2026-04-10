codeunit 134551 "ERM Cash Flow Filling I"
{
    Permissions = TableData "Cust. Ledger Entry" = m,
                  TableData "Vendor Ledger Entry" = m;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Cash Flow]
        IsInitialized := false;
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        CFHelper: Codeunit "Library - Cash Flow Helper";
        LibraryCF: Codeunit "Library - Cash Flow";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryFA: Codeunit "Library - Fixed Asset";
        LibraryService: Codeunit "Library - Service";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        DocumentType: Option Sale,Purchase,Service;
        DateFieldOption: Option DueDate,DiscountDate;
        UnsupportedDateField: Label '''Unsupported Date Field Option: %1''';
        AmountError: Label '%1 must be equal to %2.', Comment = '%1 = Expected Amount %2 = Actual Amount.';
        NoLinesForAppliedPrepaymentErr: Label 'There should not be any %1 for the posted Prepayment Invoice.';
        CFSourceExistsInJnlErr: Label '%1 exists in Cash Flow Journal.';
        ManualPmtRevExpNeedsUpdateMsg: Label 'There are one or more Cash Flow Manual Revenues/Expenses with a Recurring Frequency';
        UnexpectedMessageErr: Label 'Unexpected message.';
        CashFlowWorkSheetLineCountErr: Label 'Cash Flow WorkSheet Lines are not equal.';

    [Test]
    [Scope('OnPrem')]
    procedure FillCFJnlWithManRevenue()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        CFManualRevenue: Record "Cash Flow Manual Revenue";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        ConsiderSource: array[16] of Boolean;
    begin
        // Test filling a CF journal using Fill batch with a manual revenue
        // and verify computed due and cash flow date

        // Setup
        Initialize();
        CFHelper.CreateCashFlowForecastDefault(CashFlowForecast);
        CFHelper.CreateManualRevenue(CFManualRevenue);

        // Exercise
        ConsiderSource["Cash Flow Source Type"::"Cash Flow Manual Revenue".AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify
        CFHelper.VerifyCFDataOnSnglJnlLine(CFWorksheetLine, CFManualRevenue.Code, "Cash Flow Source Type"::"Cash Flow Manual Revenue",
          CashFlowForecast."No.", CFManualRevenue.Amount, CFManualRevenue."Starting Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillCFJnlWithManExpense()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        CFManualExpense: Record "Cash Flow Manual Expense";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        ConsiderSource: array[16] of Boolean;
    begin
        // Test filling a CF journal using Fill batch with a manual expense
        // and verify computed due and cash flow date

        // Setup
        Initialize();
        CFHelper.CreateCashFlowForecastDefault(CashFlowForecast);
        CFHelper.CreateManualPayment(CFManualExpense);

        // Exercise
        ConsiderSource["Cash Flow Source Type"::"Cash Flow Manual Expense".AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify
        CFHelper.VerifyCFDataOnSnglJnlLine(CFWorksheetLine, CFManualExpense.Code, "Cash Flow Source Type"::"Cash Flow Manual Expense",
          CashFlowForecast."No.", -CFManualExpense.Amount, CFManualExpense."Starting Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillCFJnlWithManRevenueOutOfDate()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        CFManualRevenue: array[2] of Record "Cash Flow Manual Revenue";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        ConsiderSource: array[16] of Boolean;
        i: Integer;
    begin
        // Test filling a CF journal using Fill batch with a manual revenue out of forecast date
        // and verify that it does not exist in journal

        // Setup
        Initialize();
        CreateCashFlowForecastDefaultWithManualPmtDates(CashFlowForecast, WorkDate(), CalcDate('<1M>', WorkDate()));
        CreateManualRevenueWithStartingDate(CFManualRevenue[1], CalcDate('<-1D>', CashFlowForecast."Manual Payments From"));
        CreateManualRevenueWithStartingDate(CFManualRevenue[2], CalcDate('<+1D>', CashFlowForecast."Manual Payments To"));

        // Exercise
        ConsiderSource["Cash Flow Source Type"::"Cash Flow Manual Revenue".AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify
        for i := 1 to ArrayLen(CFManualRevenue) do
            Assert.AreEqual(
              0,
              CFHelper.FilterSingleJournalLine(
                CFWorksheetLine, CFManualRevenue[i].Code, "Cash Flow Source Type"::"Cash Flow Manual Revenue", CashFlowForecast."No."),
              StrSubstNo(CFSourceExistsInJnlErr, "Cash Flow Source Type"::"Cash Flow Manual Revenue"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillCFJnlWithManExpenseOutOfDate()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        CFManualExpense: array[2] of Record "Cash Flow Manual Expense";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        ConsiderSource: array[16] of Boolean;
        i: Integer;
    begin
        // Test filling a CF journal using Fill batch with a manual expense out of forecast date
        // and verify that it does not exist in journal

        // Setup
        Initialize();
        CreateCashFlowForecastDefaultWithManualPmtDates(CashFlowForecast, WorkDate(), CalcDate('<1M>', WorkDate()));
        CreateManualExpenseWithStartingDate(CFManualExpense[1], CalcDate('<-1D>', CashFlowForecast."Manual Payments From"));
        CreateManualExpenseWithStartingDate(CFManualExpense[2], CalcDate('<+1D>', CashFlowForecast."Manual Payments To"));

        // Exercise
        ConsiderSource["Cash Flow Source Type"::"Cash Flow Manual Expense".AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify
        for i := 1 to ArrayLen(CFManualExpense) do
            Assert.AreEqual(
              0,
              CFHelper.FilterSingleJournalLine(
                CFWorksheetLine, CFManualExpense[i].Code, "Cash Flow Source Type"::"Cash Flow Manual Expense", CashFlowForecast."No."),
              StrSubstNo(CFSourceExistsInJnlErr, "Cash Flow Source Type"::"Cash Flow Manual Expense"));
    end;

    [Test]
    [HandlerFunctions('ManPmtRevExptNeedsUpdateMessageHandler')]
    [Scope('OnPrem')]
    procedure FillCFJnlWithManRevenueWithoutManPmtToDate()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        CFManualRevenue: Record "Cash Flow Manual Revenue";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        ConsiderSource: array[16] of Boolean;
    begin
        // Test filling a CF journal using Fill batch with a manual revenue out of forecast date
        // and verify that it does not exist in journal

        // Setup
        Initialize();
        CreateCashFlowForecastDefaultWithManualPmtDates(CashFlowForecast, WorkDate(), 0D);
        CreateManualRevenueWithStartingDate(CFManualRevenue, CashFlowForecast."Manual Payments From");

        // Exercise
        ConsiderSource["Cash Flow Source Type"::"Cash Flow Manual Revenue".AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify
        Assert.AreEqual(
          1,
          CFHelper.FilterSingleJournalLine(
            CFWorksheetLine, CFManualRevenue.Code, "Cash Flow Source Type"::"Cash Flow Manual Revenue", CashFlowForecast."No."),
          StrSubstNo(CFSourceExistsInJnlErr, "Cash Flow Source Type"::"Cash Flow Manual Revenue"));
    end;

    [Test]
    [HandlerFunctions('ManPmtRevExptNeedsUpdateMessageHandler')]
    [Scope('OnPrem')]
    procedure FillCFJnlWithManExpenseWithoutManPmtToDate()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        CFManualExpense: Record "Cash Flow Manual Expense";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        ConsiderSource: array[16] of Boolean;
    begin
        // Test filling a CF journal using Fill batch with a manual expense out of forecast date
        // and verify that it does not exist in journal

        // Setup
        Initialize();
        CreateCashFlowForecastDefaultWithManualPmtDates(CashFlowForecast, WorkDate(), 0D);
        CreateManualExpenseWithStartingDate(CFManualExpense, CashFlowForecast."Manual Payments From");

        // Exercise
        ConsiderSource["Cash Flow Source Type"::"Cash Flow Manual Expense".AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify: Check text message in ManPmtRevExptNeedsUpdateMessageHandler
        Assert.AreEqual(
          1,
          CFHelper.FilterSingleJournalLine(
            CFWorksheetLine, CFManualExpense.Code, "Cash Flow Source Type"::"Cash Flow Manual Expense", CashFlowForecast."No."),
          StrSubstNo(CFSourceExistsInJnlErr, "Cash Flow Source Type"::"Cash Flow Manual Expense"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillCFJnlWithSalesOrder()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        SalesHeader: Record "Sales Header";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        ConsiderSource: array[16] of Boolean;
    begin
        // Test filling a CF journal by using Fill batch with a 3-line sales order
        // and verify computed due and cash flow date

        // Setup
        Initialize();
        CFHelper.CreateCashFlowForecastDefault(CashFlowForecast);
        CFHelper.CreateDefaultSalesOrder(SalesHeader);

        // Exercise
        ConsiderSource["Cash Flow Source Type"::"Sales Orders".AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify
        CFHelper.VerifyCFDataOnSnglJnlLine(CFWorksheetLine, SalesHeader."No.", "Cash Flow Source Type"::"Sales Orders",
          CashFlowForecast."No.", CFHelper.GetTotalSalesAmount(SalesHeader, false), SalesHeader."Due Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillCFJnlWithPurchOrder()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        PurchaseHeader: Record "Purchase Header";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        ConsiderSource: array[16] of Boolean;
    begin
        // Test filling a CF journal by using Fill batch with a 3-line purchase order
        // and verify computed due and cash flow date

        // Setup
        Initialize();
        CFHelper.CreateCashFlowForecastDefault(CashFlowForecast);
        CFHelper.CreateDefaultPurchaseOrder(PurchaseHeader);

        // Exercise
        LibraryApplicationArea.EnableFoundationSetup();
        ConsiderSource["Cash Flow Source Type"::"Purchase Orders".AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify
        CFHelper.VerifyCFDataOnSnglJnlLine(CFWorksheetLine, PurchaseHeader."No.", "Cash Flow Source Type"::"Purchase Orders",
          CashFlowForecast."No.", -CFHelper.GetTotalPurchaseAmount(PurchaseHeader, false), PurchaseHeader."Due Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillCFJnlWithServiceOrder()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        ServiceHeader: Record "Service Header";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        ConsiderSource: array[16] of Boolean;
    begin
        // Test filling a CF journal by using Fill batch with a 3-line service order
        // and verify computed due and cash flow date

        // Setup
        Initialize();
        CFHelper.CreateCashFlowForecastDefault(CashFlowForecast);
        LibraryService.CreateDefaultServiceOrder(ServiceHeader);

        // Exercise
        ConsiderSource["Cash Flow Source Type"::"Service Orders".AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify
        CFHelper.VerifyCFDataOnSnglJnlLine(CFWorksheetLine, ServiceHeader."No.", "Cash Flow Source Type"::"Service Orders",
          CashFlowForecast."No.", CFHelper.GetTotalServiceAmount(ServiceHeader, false), ServiceHeader."Document Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillCFJnlWithCustomerLE()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        SalesHeader: Record "Sales Header";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ConsiderSource: array[16] of Boolean;
    begin
        // Test filling a CF journal by using Fill batch with a single customer ledger entry
        // Verify computed due and cash flow date

        // Setup
        Initialize();
        CFHelper.CreateCashFlowForecastDefault(CashFlowForecast);
        CFHelper.CreateDefaultSalesOrder(SalesHeader);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        CFHelper.FindFirstCustLEFromSO(CustLedgerEntry, SalesHeader."No.");

        // Exercise
        ConsiderSource["Cash Flow Source Type"::Receivables.AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify
        CustLedgerEntry.CalcFields("Amount (LCY)");
        CFHelper.VerifyCFDataOnSnglJnlLine(CFWorksheetLine, CustLedgerEntry."Document No.", "Cash Flow Source Type"::Receivables,
          CashFlowForecast."No.", CustLedgerEntry."Amount (LCY)", CustLedgerEntry."Due Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillCFJnlWithVendorLE()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        PurchaseHeader: Record "Purchase Header";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        ConsiderSource: array[16] of Boolean;
    begin
        // Test filling a CF journal by using Fill batch with a single vendor ledger entry
        // Verify computed due and cash flow date

        // Setup
        Initialize();
        CFHelper.CreateCashFlowForecastDefault(CashFlowForecast);
        CFHelper.CreateDefaultPurchaseOrder(PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        CFHelper.FindFirstVendorLEFromPO(VendorLedgerEntry, PurchaseHeader."No.");

        // Exercise
        ConsiderSource["Cash Flow Source Type"::Payables.AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify
        VendorLedgerEntry.CalcFields("Amount (LCY)");
        CFHelper.VerifyCFDataOnSnglJnlLine(CFWorksheetLine, VendorLedgerEntry."Document No.", "Cash Flow Source Type"::Payables,
          CashFlowForecast."No.", VendorLedgerEntry."Amount (LCY)", VendorLedgerEntry."Due Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillCFJnlFixedAssetAquisition()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        FixedAsset: Record "Fixed Asset";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        FASetup: Record "FA Setup";
        ExpectedDueAndCFDate: Date;
        InvestmentAmount: Decimal;
        FAPostingDateFormula: DateFormula;
        ConsiderSource: array[16] of Boolean;
    begin
        // Test filling a CF journal by using Fill batch with budgeted fixed asset acquisition costs (planned FA investment)
        // Verify due and CF date match the posting date of the FA acquisition journal

        // Setup
        CFHelper.CreateCashFlowForecastDefault(CashFlowForecast);
        InvestmentAmount := LibraryRandom.RandDec(2000, 2);
        Evaluate(FAPostingDateFormula, '<1M>');
        FASetup.Get();
        CFHelper.CreateFixedAssetForInvestment(FixedAsset, FASetup."Default Depr. Book", FAPostingDateFormula, InvestmentAmount);
        ExpectedDueAndCFDate := CalcDate(FAPostingDateFormula, WorkDate());

        // Exercise
        ConsiderSource["Cash Flow Source Type"::"Fixed Assets Budget".AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify
        CFHelper.VerifyCFDataOnSnglJnlLine(CFWorksheetLine, FixedAsset."No.", "Cash Flow Source Type"::"Fixed Assets Budget",
          CashFlowForecast."No.", -InvestmentAmount, ExpectedDueAndCFDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillCFJnlFixedAssetDisposal()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        FixedAsset: Record "Fixed Asset";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        FASetup: Record "FA Setup";
        ExpectedDueAndCFDate: Date;
        ExpectedDisposalDateFormula: DateFormula;
        DeprecStartDateFormula: DateFormula;
        DeprecEndDateFormula: DateFormula;
        ExpectedDisposalAmount: Decimal;
        ConsiderSource: array[16] of Boolean;
    begin
        // Test filling a CF journal by using Fill batch with planned sale of fixed asset
        // Verify due and CF date match the planned disposal date

        // Setup
        CFHelper.CreateCashFlowForecastDefault(CashFlowForecast);
        Evaluate(DeprecStartDateFormula, '<-2Y>');
        Evaluate(DeprecEndDateFormula, '<1M-D5>');
        Evaluate(ExpectedDisposalDateFormula, '<1M+1W-WD1>');
        ExpectedDisposalAmount := LibraryRandom.RandDec(2000, 2);
        FASetup.Get();
        CFHelper.CreateFixedAssetForDisposal(FixedAsset, FASetup."Default Depr. Book", DeprecStartDateFormula, DeprecEndDateFormula,
          ExpectedDisposalDateFormula, ExpectedDisposalAmount);
        ExpectedDueAndCFDate := CalcDate(ExpectedDisposalDateFormula, WorkDate());

        // Exercise
        ConsiderSource["Cash Flow Source Type"::"Fixed Assets Disposal".AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify
        CFHelper.VerifyCFDataOnSnglJnlLine(CFWorksheetLine, FixedAsset."No.", "Cash Flow Source Type"::"Fixed Assets Disposal",
          CashFlowForecast."No.", ExpectedDisposalAmount, ExpectedDueAndCFDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillCFJnlSODiscount()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        SalesHeader: Record "Sales Header";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        PaymentTerms: Record "Payment Terms";
        ExpectedAmount: Decimal;
        ConsiderSource: array[16] of Boolean;
    begin
        // Test filling a CF journal by using Fill batch with a discounted 3-line sales order
        // Verify computed due and cash flow date, discounted amount and discount percentage

        // Setup
        Initialize();
        CFHelper.CreateCashFlowForecastConsiderDiscount(CashFlowForecast);
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        CFHelper.CreateSpecificSalesOrder(SalesHeader, PaymentTerms.Code, '');
        ExpectedAmount := CFHelper.GetTotalSalesAmount(SalesHeader, true);

        // Exercise
        ConsiderSource["Cash Flow Source Type"::"Sales Orders".AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify
        CFHelper.VerifyCFDataOnSnglJnlLine(CFWorksheetLine, SalesHeader."No.", "Cash Flow Source Type"::"Sales Orders",
          CashFlowForecast."No.", ExpectedAmount, CalcDate(PaymentTerms."Discount Date Calculation", SalesHeader."Document Date"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillCFJnlSOCFPmtTerms()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        SalesHeader: Record "Sales Header";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        PaymentTerms: Record "Payment Terms";
        ExpectedCFDate: Date;
        ExpectedAmount: Decimal;
        ConsiderSource: array[16] of Boolean;
    begin
        // Test filling a CF journal by using Fill batch with a 3-line sales order where customer has
        // CF payment terms set. Verify computed due and cash flow date and discounted amount

        // Setup
        Initialize();
        CFHelper.CreateCashFlowForecastConsiderCFPmtTerms(CashFlowForecast);
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        CFHelper.CreateSpecificSalesOrder(SalesHeader, '', PaymentTerms.Code);
        // set expected values considering only CF payment terms
        CFHelper.SetExpectedDsctAPmtTermValues(DocumentType::Sale, SalesHeader."No.",
          SalesHeader."Sell-to Customer No.", SalesHeader."Document Date", false,
          ExpectedCFDate, ExpectedAmount);

        // Exercise
        ConsiderSource["Cash Flow Source Type"::"Sales Orders".AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify - passing 0 as expected discount amount since discount is not considered on the CF card
        CFHelper.VerifyCFDataOnSnglJnlLine(CFWorksheetLine, SalesHeader."No.", "Cash Flow Source Type"::"Sales Orders",
          CashFlowForecast."No.", ExpectedAmount, ExpectedCFDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillCFJnlSODsctAndCFPmtTerms()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        SalesHeader: Record "Sales Header";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        PaymentTerms: Record "Payment Terms";
        PaymentTerms2: Record "Payment Terms";
        ExpectedCFDate: Date;
        ExpectedAmount: Decimal;
        ConsiderSource: array[16] of Boolean;
    begin
        // Test filling a CF journal by using Fill batch with a discounted 3-line sales order
        // where customer has CF payment terms set. Verify computed due and cash flow date and discounted amount

        // Setup
        Initialize();
        CFHelper.CreateCashFlowForecastConsiderDiscountAndCFPmtTerms(CashFlowForecast);
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms); // default pmt terms
        CFHelper.GetDifferentDsctPaymentTerms(PaymentTerms2, PaymentTerms.Code); // cf pmt terms
        CFHelper.CreateSpecificSalesOrder(SalesHeader, PaymentTerms.Code, PaymentTerms2.Code);
        // set expected vales considering CF payment terms and line discount
        CFHelper.SetExpectedDsctAPmtTermValues(DocumentType::Sale, SalesHeader."No.",
          SalesHeader."Sell-to Customer No.", SalesHeader."Document Date", true,
          ExpectedCFDate, ExpectedAmount);

        // Exercise
        ConsiderSource["Cash Flow Source Type"::"Sales Orders".AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify
        CFHelper.VerifyCFDataOnSnglJnlLine(CFWorksheetLine, SalesHeader."No.", "Cash Flow Source Type"::"Sales Orders",
          CashFlowForecast."No.", ExpectedAmount, ExpectedCFDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillCFJnlSOPmtDscTolDate()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        SalesHeader: Record "Sales Header";
        GeneralLedgerSetup: Record "General Ledger Setup";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        PaymentTerms: Record "Payment Terms";
        ExpectedCFDate: Date;
        PmtDiscountGracePeriod: DateFormula;
        ConsiderSource: array[16] of Boolean;
    begin
        // Test filling a CF journal by using Fill batch with a 3-line sales order
        // and a payment discount grace period set. Verify computed due and cash flow date and discounted amount

        // Setup
        Initialize();
        CFHelper.CreateCashFlowForecastConsiderDiscount(CashFlowForecast);
        CFHelper.SetPmtToleranceOptionsOnCashFlowForecast(CashFlowForecast, true, false);
        GeneralLedgerSetup.Get();
        CFHelper.CreateRandomDateFormula(PmtDiscountGracePeriod);
        CFHelper.SetupPmtDsctGracePeriod(PmtDiscountGracePeriod);
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        CFHelper.CreateSpecificSalesOrder(SalesHeader, PaymentTerms.Code, '');
        ExpectedCFDate :=
          CalcDate(PaymentTerms."Discount Date Calculation",
            CalcDate(PmtDiscountGracePeriod, SalesHeader."Document Date"));

        // Exercise
        ConsiderSource["Cash Flow Source Type"::"Sales Orders".AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify
        CFHelper.FilterSingleJournalLine(CFWorksheetLine, SalesHeader."No.", "Cash Flow Source Type"::"Sales Orders", CashFlowForecast."No.");
        CFHelper.VerifyCFDateOnCFJnlLine(CFWorksheetLine, ExpectedCFDate);

        // Tear down
        CFHelper.SetupPmtDsctGracePeriod(GeneralLedgerSetup."Payment Discount Grace Period");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillCFJnlCustLEDiscount()
    var
        PaymentTerms: Record "Payment Terms";
        CashFlowForecast: Record "Cash Flow Forecast";
        SalesHeader: Record "Sales Header";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ExpectedAmount: Decimal;
        ConsiderSource: array[16] of Boolean;
    begin
        // Test filling a CF journal by using Fill batch with a discounted single customer ledger entry
        // Verify computed due and cash flow date, discounted amount and discount percentage

        // Setup
        Initialize();
        CFHelper.CreateCashFlowForecastConsiderDiscount(CashFlowForecast);
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        CFHelper.CreateSpecificSalesOrder(SalesHeader, PaymentTerms.Code, '');
        ExpectedAmount := CFHelper.GetTotalSalesAmount(SalesHeader, true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        CFHelper.FindFirstCustLEFromSO(CustLedgerEntry, SalesHeader."No.");

        // Exercise
        ConsiderSource["Cash Flow Source Type"::Receivables.AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify
        CFHelper.VerifyCFDataOnSnglJnlLine(CFWorksheetLine, CustLedgerEntry."Document No.", "Cash Flow Source Type"::Receivables,
          CashFlowForecast."No.", ExpectedAmount, CustLedgerEntry."Pmt. Discount Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillCFJnlCustLEPmtTerms()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        SalesHeader: Record "Sales Header";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PaymentTerms: Record "Payment Terms";
        ExpectedCFDate: Date;
        ExpectedAmount: Decimal;
        ConsiderSource: array[16] of Boolean;
    begin
        // Test filling a CF journal by using Fill batch with a single customer ledger entry
        // where customer CF payment terms are set.
        // Verify computed due and cash flow date, discounted amount and discount percentage

        // Setup
        Initialize();
        CFHelper.CreateCashFlowForecastConsiderCFPmtTerms(CashFlowForecast);
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        CFHelper.CreateSpecificSalesOrder(SalesHeader, '', PaymentTerms.Code);

        // Set expected values
        CFHelper.SetExpectedDsctAPmtTermValues(DocumentType::Sale, SalesHeader."No.", SalesHeader."Sell-to Customer No.",
          SalesHeader."Posting Date", false, ExpectedCFDate, ExpectedAmount);

        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        CFHelper.FindFirstCustLEFromSO(CustLedgerEntry, SalesHeader."No.");

        // Exercise
        ConsiderSource["Cash Flow Source Type"::Receivables.AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify
        CFHelper.VerifyCFDataOnSnglJnlLine(CFWorksheetLine, CustLedgerEntry."Document No.", "Cash Flow Source Type"::Receivables,
          CashFlowForecast."No.", ExpectedAmount, ExpectedCFDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillCFJnlCustLEDsctCFPmtTerms()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesHeader: Record "Sales Header";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        PaymentTerms: Record "Payment Terms";
        PaymentTerms2: Record "Payment Terms";
        ExpectedCFDate: Date;
        ExpectedAmount: Decimal;
        ConsiderSource: array[16] of Boolean;
    begin
        // Test filling a CF journal by using Fill batch with a discounted single customer ledger entry
        // and customer CF payment terms set. Verify computed due and cash flow date, discounted amount and discount percentage

        // Setup
        Initialize();
        CFHelper.CreateCashFlowForecastConsiderDiscountAndCFPmtTerms(CashFlowForecast);
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        CFHelper.GetDifferentDsctPaymentTerms(PaymentTerms2, PaymentTerms.Code);
        CFHelper.CreateSpecificSalesOrder(SalesHeader, PaymentTerms.Code, PaymentTerms2.Code);
        CFHelper.SetExpectedDsctAPmtTermValues(DocumentType::Sale, SalesHeader."No.",
          SalesHeader."Sell-to Customer No.", SalesHeader."Posting Date", true,
          ExpectedCFDate, ExpectedAmount);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        CFHelper.FindFirstCustLEFromSO(CustLedgerEntry, SalesHeader."No.");

        // Exercise
        ConsiderSource["Cash Flow Source Type"::Receivables.AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify
        CFHelper.VerifyCFDataOnSnglJnlLine(CFWorksheetLine, CustLedgerEntry."Document No.", "Cash Flow Source Type"::Receivables,
          CashFlowForecast."No.", ExpectedAmount, ExpectedCFDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillCFJnlVendorLEDiscount()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        PurchaseHeader: Record "Purchase Header";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PaymentTerms: Record "Payment Terms";
        ExpectedAmount: Decimal;
        ConsiderSource: array[16] of Boolean;
    begin
        // Test filling a CF journal by using Fill batch with a discounted single vendor ledger entry
        // Verify computed due and cash flow date, discounted amount and discount percentage

        // Setup
        Initialize();
        CFHelper.CreateCashFlowForecastConsiderDiscount(CashFlowForecast);
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        CFHelper.CreateSpecificPurchaseOrder(PurchaseHeader, PaymentTerms.Code, '');
        ExpectedAmount := -CFHelper.GetTotalPurchaseAmount(PurchaseHeader, true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        CFHelper.FindFirstVendorLEFromPO(VendorLedgerEntry, PurchaseHeader."No.");

        // Exercise
        ConsiderSource["Cash Flow Source Type"::Payables.AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify
        CFHelper.VerifyCFDataOnSnglJnlLine(CFWorksheetLine, VendorLedgerEntry."Document No.", "Cash Flow Source Type"::Payables,
          CashFlowForecast."No.", ExpectedAmount, VendorLedgerEntry."Pmt. Discount Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillCFJnlVendorLECFPmtTerms()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        PaymentTerms: Record "Payment Terms";
        ExpectedCFDate: Date;
        ExpectedAmount: Decimal;
        ConsiderSource: array[16] of Boolean;
    begin
        // Test filling a CF journal by using Fill batch with a single vendor ledger entry where vendor has
        // CF payment terms set. Verify computed due, cash flow date and expected amount

        // Setup
        Initialize();
        CFHelper.CreateCashFlowForecastConsiderCFPmtTerms(CashFlowForecast);
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        CFHelper.CreateSpecificPurchaseOrder(PurchaseHeader, '', PaymentTerms.Code);

        // Set expected values
        CFHelper.SetExpectedDsctAPmtTermValues(DocumentType::Purchase, PurchaseHeader."No.",
          PurchaseHeader."Buy-from Vendor No.", PurchaseHeader."Posting Date", false,
          ExpectedCFDate, ExpectedAmount);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        CFHelper.FindFirstVendorLEFromPO(VendorLedgerEntry, PurchaseHeader."No.");

        // Exercise
        ConsiderSource["Cash Flow Source Type"::Payables.AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify
        CFHelper.VerifyCFDataOnSnglJnlLine(CFWorksheetLine, VendorLedgerEntry."Document No.", "Cash Flow Source Type"::Payables,
          CashFlowForecast."No.", ExpectedAmount, ExpectedCFDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillCFJnlVendorLEDsctCFPmtTerm()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PurchaseHeader: Record "Purchase Header";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        PaymentTerms: Record "Payment Terms";
        PaymentTerms2: Record "Payment Terms";
        ExpectedCFDate: Date;
        ExpectedAmount: Decimal;
        ConsiderSource: array[16] of Boolean;
    begin
        // Test filling a CF journal by using Fill batch with a discounted single vendor ledger entry
        // and vendor CF payment terms set. Verify computed due and cash flow date, discounted amount and discount percentage

        // Setup
        Initialize();
        CFHelper.CreateCashFlowForecastConsiderDiscountAndCFPmtTerms(CashFlowForecast);
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        CFHelper.GetDifferentDsctPaymentTerms(PaymentTerms2, PaymentTerms.Code);
        CFHelper.CreateSpecificPurchaseOrder(PurchaseHeader, PaymentTerms.Code, PaymentTerms2.Code);
        CFHelper.SetExpectedDsctAPmtTermValues(DocumentType::Purchase, PurchaseHeader."No.",
          PurchaseHeader."Buy-from Vendor No.", PurchaseHeader."Posting Date", true,
          ExpectedCFDate, ExpectedAmount);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        CFHelper.FindFirstVendorLEFromPO(VendorLedgerEntry, PurchaseHeader."No.");

        // Exercise
        ConsiderSource["Cash Flow Source Type"::Payables.AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify
        CFHelper.VerifyCFDataOnSnglJnlLine(CFWorksheetLine, VendorLedgerEntry."Document No.", "Cash Flow Source Type"::Payables,
          CashFlowForecast."No.", ExpectedAmount, ExpectedCFDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillCFJnlPODiscount()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        PurchaseHeader: Record "Purchase Header";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        PaymentTerms: Record "Payment Terms";
        ExpectedAmount: Decimal;
        ExpectedCFDate: Date;
        ConsiderSource: array[16] of Boolean;
    begin
        // Test filling a CF journal by using Fill batch with a discounted 3-line purchase order
        // Verify computed due and cash flow date, discounted amount and discount percentage

        // Setup
        Initialize();
        CFHelper.CreateCashFlowForecastConsiderDiscount(CashFlowForecast);
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        CFHelper.CreateSpecificPurchaseOrder(PurchaseHeader, PaymentTerms.Code, '');
        ExpectedAmount := -CFHelper.GetTotalPurchaseAmount(PurchaseHeader, true);
        ExpectedCFDate := PurchaseHeader."Pmt. Discount Date";

        // Exercise
        ConsiderSource["Cash Flow Source Type"::"Purchase Orders".AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify
        CFHelper.VerifyCFDataOnSnglJnlLine(CFWorksheetLine, PurchaseHeader."No.", "Cash Flow Source Type"::"Purchase Orders",
          CashFlowForecast."No.", ExpectedAmount, ExpectedCFDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillCFJnlPOCFPmtTerms()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        PurchaseHeader: Record "Purchase Header";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        PaymentTerms: Record "Payment Terms";
        ExpectedCFDate: Date;
        ExpectedAmount: Decimal;
        ConsiderSource: array[16] of Boolean;
    begin
        // Test filling a CF journal by using Fill batch with a 3-line purchase order where vendor has
        // CF payment terms set. Verify computed due and cash flow date and non-discounted amount

        // Setup
        Initialize();
        CFHelper.CreateCashFlowForecastConsiderCFPmtTerms(CashFlowForecast);
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        CFHelper.CreateSpecificPurchaseOrder(PurchaseHeader, '', PaymentTerms.Code);
        CFHelper.SetExpectedDsctAPmtTermValues(DocumentType::Purchase, PurchaseHeader."No.",
          PurchaseHeader."Buy-from Vendor No.", PurchaseHeader."Document Date", false,
          ExpectedCFDate, ExpectedAmount);

        // Exercise
        ConsiderSource["Cash Flow Source Type"::"Purchase Orders".AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify
        CFHelper.VerifyCFDataOnSnglJnlLine(CFWorksheetLine, PurchaseHeader."No.", "Cash Flow Source Type"::"Purchase Orders",
          CashFlowForecast."No.", ExpectedAmount, ExpectedCFDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillCFJnlPODsctAndCFPmtTerms()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        PurchaseHeader: Record "Purchase Header";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        PaymentTerms: Record "Payment Terms";
        PaymentTerms2: Record "Payment Terms";
        ExpectedCFDate: Date;
        ExpectedAmount: Decimal;
        ConsiderSource: array[16] of Boolean;
    begin
        // Test filling a CF journal by using Fill batch with a discounted 3-line purchase order where vendor has
        // CF payment terms set. Verify computed due and cash flow date and discounted amount

        // Setup
        Initialize();
        CFHelper.CreateCashFlowForecastConsiderDiscountAndCFPmtTerms(CashFlowForecast);
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        CFHelper.GetDifferentDsctPaymentTerms(PaymentTerms2, PaymentTerms.Code);
        CFHelper.CreateSpecificPurchaseOrder(PurchaseHeader, PaymentTerms.Code, PaymentTerms2.Code);
        CFHelper.SetExpectedDsctAPmtTermValues(DocumentType::Purchase, PurchaseHeader."No.",
          PurchaseHeader."Buy-from Vendor No.", PurchaseHeader."Document Date", true,
          ExpectedCFDate, ExpectedAmount);

        // Exercise
        ConsiderSource["Cash Flow Source Type"::"Purchase Orders".AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify
        CFHelper.VerifyCFDataOnSnglJnlLine(CFWorksheetLine, PurchaseHeader."No.", "Cash Flow Source Type"::"Purchase Orders",
          CashFlowForecast."No.", ExpectedAmount, ExpectedCFDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillCFJnlSvcDiscount()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        ServiceHeader: Record "Service Header";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        PaymentTerms: Record "Payment Terms";
        ExpectedAmount: Decimal;
        ExpectedCFDate: Date;
        ConsiderSource: array[16] of Boolean;
    begin
        // Test filling a CF journal by using Fill batch with a discounted 3-line service order
        // Verify computed due and cash flow date, discounted amount and order discount percentage

        // Setup
        Initialize();
        CFHelper.CreateCashFlowForecastConsiderDiscount(CashFlowForecast);
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        LibraryService.CreateSpecificServiceOrder(ServiceHeader, PaymentTerms.Code, '');
        ExpectedAmount := CFHelper.GetTotalServiceAmount(ServiceHeader, true);
        ExpectedCFDate := ServiceHeader."Pmt. Discount Date";

        // Exercise
        ConsiderSource["Cash Flow Source Type"::"Service Orders".AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify
        CFHelper.VerifyCFDataOnSnglJnlLine(CFWorksheetLine, ServiceHeader."No.", "Cash Flow Source Type"::"Service Orders",
          CashFlowForecast."No.", ExpectedAmount, ExpectedCFDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillCFJnlSvcCFPmtTerms()
    begin
        // Test filling a CF journal by using Fill batch with a 3-line service order where vendor has
        // CF payment terms set. Verify computed due and cash flow date and the full order amount
        FillCFJnlSvcOrderWithCFPmtTerms(false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillCFJnlSvcDsctAndCFPmtTerms()
    begin
        // Test filling a CF journal by using Fill batch with a discounted 3-line service order where vendor has
        // CF payment terms set. Verify computed due and cash flow date and discounted amount
        FillCFJnlSvcOrderWithCFPmtTerms(true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillCFJnlSvcCFPmtTermsAndGroupBy()
    begin
        // Test filling a CF journal by using Fill batch with a 3-line service order where vendor has
        // CF payment terms set. Verify computed due and cash flow date and the full order amount
        FillCFJnlSvcOrderWithCFPmtTerms(false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillCFJnlSvcDsctAndCFPmtTermsAndGroupBy()
    begin
        // Test filling a CF journal by using Fill batch with a discounted 3-line service order where vendor has
        // CF payment terms set. Verify computed due and cash flow date and discounted amount
        FillCFJnlSvcOrderWithCFPmtTerms(true, true);
    end;

    local procedure FillCFJnlSvcOrderWithCFPmtTerms(ConsiderDiscount: Boolean; GroupByDocumentType: Boolean)
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        ServiceHeader: Record "Service Header";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        PaymentTerms: Record "Payment Terms";
        PaymentTerms2: Record "Payment Terms";
        ExpectedCFDate: Date;
        ExpectedAmount: Decimal;
        ConsiderSource: array[16] of Boolean;
        PaymentTermsCode: Code[10];
        PaymentTermsCode2: Code[10];
    begin
        // Test filling a CF journal by using Fill batch with/without a discounted 3-line service order where vendor has
        // CF payment terms set. Verify computed due and cash flow date and discounted/full amount

        // Setup
        Initialize();
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        if ConsiderDiscount then begin
            CFHelper.GetDifferentDsctPaymentTerms(PaymentTerms2, PaymentTerms.Code);
            CFHelper.CreateCashFlowForecastConsiderDiscountAndCFPmtTerms(CashFlowForecast);
            PaymentTermsCode := PaymentTerms.Code;
            PaymentTermsCode2 := PaymentTerms2.Code;
        end else begin
            CFHelper.CreateCashFlowForecastConsiderCFPmtTerms(CashFlowForecast);
            PaymentTermsCode2 := PaymentTerms.Code;
        end;
        LibraryService.CreateSpecificServiceOrder(ServiceHeader, PaymentTermsCode, PaymentTermsCode2);

        CFHelper.SetExpectedDsctAPmtTermValues(DocumentType::Service, ServiceHeader."No.", ServiceHeader."Customer No.",
          ServiceHeader."Document Date", ConsiderDiscount, ExpectedCFDate, ExpectedAmount);

        // Exercise
        ConsiderSource["Cash Flow Source Type"::"Service Orders".AsInteger()] := true;
        CFHelper.FillJournal(ConsiderSource, CashFlowForecast."No.", GroupByDocumentType);

        // Verify
        CFHelper.VerifyCFDataOnSnglJnlLine(CFWorksheetLine, ServiceHeader."No.", "Cash Flow Source Type"::"Service Orders",
          CashFlowForecast."No.", ExpectedAmount, ExpectedCFDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillCFJnlWithJob()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        Job: Record Job;
        JobPlanningLine: Record "Job Planning Line";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        ConsiderSource: array[16] of Boolean;
        OldDate: Date;
        NewDate: Date;
    begin
        // Test filling a CF journal by using Fill batch with a 3-planning line job
        // and verify computed due and cash flow date

        // Setup - create the entities
        SetupCashFlowForJobs(CashFlowForecast, Job, JobPlanningLine, OldDate, NewDate);

        // Exercise
        LibraryApplicationArea.EnableJobsSetup();
        ConsiderSource["Cash Flow Source Type"::Job.AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify
        CFHelper.VerifyCFDataOnSnglJnlLine(CFWorksheetLine, Job."No.", "Cash Flow Source Type"::Job,
          CashFlowForecast."No.", CFHelper.GetTotalJobsAmount(Job, OldDate), OldDate);
        CFHelper.VerifyCFDataOnSnglJnlLine(CFWorksheetLine, Job."No.", "Cash Flow Source Type"::Job,
          CashFlowForecast."No.", CFHelper.GetTotalJobsAmount(Job, NewDate), NewDate);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure FillCFJnlWithTax()
    var
        CashFlowSetup: Record "Cash Flow Setup";
        SalesHeader1: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesHeader3: Record "Sales Header";
        CashFlowForecast: Record "Cash Flow Forecast";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        ConsiderSource: array[16] of Boolean;
        DocumentDate1: Date;
        DocumentDate2: Date;
        DocumentDate3: Date;
        TaxDueDate1: Date;
        TaxDueDate2: Date;
    begin
        // Test filling a CF journal by using Fill batch with 3 sales orders
        // and verify computed due and cash flow date

        Initialize();

        // Setup - set the Tax schedule on CashFlowSetup
        CashFlowSetup.Get();
        CashFlowSetup."Taxable Period" := CashFlowSetup."Taxable Period"::Quarterly;
        Evaluate(CashFlowSetup."Tax Payment Window", '<5D>');
        CashFlowSetup.Modify();
        DocumentDate1 := CalcDate('<-CQ+1D>', WorkDate());
        DocumentDate2 := CalcDate('<CQ>', WorkDate());
        DocumentDate3 := CalcDate('<3D>', DocumentDate2);

        // Setup - create the sales orders - 2 in the same tax period and the third a little later
        SalesHeader1.DeleteAll();
        CFHelper.CreateDefaultSalesOrder(SalesHeader1);
        SalesHeader1."Document Date" := DocumentDate1;
        SalesHeader1.Modify();
        CFHelper.CreateDefaultSalesOrder(SalesHeader2);
        SalesHeader2."Document Date" := DocumentDate2;
        SalesHeader2.Modify();
        CFHelper.CreateDefaultSalesOrder(SalesHeader3);
        SalesHeader3."Document Date" := DocumentDate3;
        SalesHeader3.Modify();

        // Setup - create the forecast entity
        CFHelper.CreateCashFlowForecastDefault(CashFlowForecast);

        // Exercise
        ConsiderSource["Cash Flow Source Type"::Tax.AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify - worksheet lines for the two dates for sales
        CFWorksheetLine.SetRange("Source No.", Format(DATABASE::"Sales Header"));
        TaxDueDate1 := CashFlowSetup.GetTaxPaymentDueDate(DocumentDate1);
        CFWorksheetLine.SetRange("Cash Flow Date", TaxDueDate1);
        CFHelper.VerifyCFDataOnSnglJnlLine(CFWorksheetLine, '', "Cash Flow Source Type"::Tax,
          CashFlowForecast."No.", CFHelper.GetTotalTaxAmount(TaxDueDate1, DATABASE::"Sales Header"), TaxDueDate1);
        TaxDueDate2 := CashFlowSetup.GetTaxPaymentDueDate(DocumentDate3);
        CFWorksheetLine.SetRange("Cash Flow Date", TaxDueDate2);
        CFHelper.VerifyCFDataOnSnglJnlLine(CFWorksheetLine, '', "Cash Flow Source Type"::Tax,
          CashFlowForecast."No.", CFHelper.GetTotalTaxAmount(TaxDueDate2, DATABASE::"Sales Header"), TaxDueDate2);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure FillCFJnlWithTaxAfterTaxPayment()
    var
        GLAccount: Record "G/L Account";
        Vendor: Record Vendor;
        CashFlowSetup: Record "Cash Flow Setup";
        SalesHeader: Record "Sales Header";
        CashFlowForecast: Record "Cash Flow Forecast";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        ConsiderSource: array[16] of Boolean;
        DocumentDate: Date;
        TaxDueDate: Date;
    begin
        // Test filling a CF journal by using Fill batch with 1 sales orders
        // and verify computed due and cash flow date

        Initialize();

        // Setup account to pay taxes to (vendor)
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        Vendor.Get(
          LibraryPurchase.CreateVendorWithBusPostingGroups(
            GLAccount."Gen. Bus. Posting Group", GLAccount."VAT Bus. Posting Group"));

        // Setup - set the Tax schedule on CashFlowSetup
        CashFlowSetup.Get();
        CashFlowSetup."Taxable Period" := CashFlowSetup."Taxable Period"::Quarterly;
        Evaluate(CashFlowSetup."Tax Payment Window", '<5D>');
        CashFlowSetup."Tax Bal. Account Type" := CashFlowSetup."Tax Bal. Account Type"::Vendor;
        CashFlowSetup."Tax Bal. Account No." := Vendor."No.";
        CashFlowSetup.Modify();
        DocumentDate := CalcDate('<-CQ-30D>', WorkDate());

        // Setup - create the sales order
        CFHelper.CreateDefaultSalesOrder(SalesHeader);
        SalesHeader."Document Date" := DocumentDate;
        SalesHeader.Modify();

        // Setup - create the forecast entity
        CFHelper.CreateCashFlowForecastDefault(CashFlowForecast);

        // Setup - create an entry in the Bank Account Leger Entry for a valid tax payment date (represents payment of taxes)
        TaxDueDate := CashFlowSetup.GetTaxPaymentDueDate(DocumentDate);
        BankAccountLedgerEntry.FindLast();
        BankAccountLedgerEntry."Entry No." += 1;
        BankAccountLedgerEntry."Bal. Account Type" := BankAccountLedgerEntry."Bal. Account Type"::Vendor;
        BankAccountLedgerEntry."Bal. Account No." := CashFlowSetup."Tax Bal. Account No.";
        BankAccountLedgerEntry."Amount (LCY)" := LibraryRandom.RandDec(100, 2);
        BankAccountLedgerEntry."Posting Date" := CalcDate('<-1D>', TaxDueDate);
        BankAccountLedgerEntry.Insert();

        // Exercise
        ConsiderSource["Cash Flow Source Type"::Tax.AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify - no worksheet lines for the sales
        CFWorksheetLine.SetRange("Source No.", Format(DATABASE::"Sales Header"));
        CFWorksheetLine.SetRange("Cash Flow Date", TaxDueDate);
        Assert.IsTrue(CFWorksheetLine.IsEmpty, 'As there is a bank account ledger entry for this date, no lines expected.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyGetTaxAmountFromPurchaseOrder()
    var
        CashFlowSetup: Record "Cash Flow Setup";
        PurchaseHeader1: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        CashFlowManagement: Codeunit "Cash Flow Management";
        Result: Decimal;
    begin
        // Test that the tax amounts are correctly calculated for purchase orders

        Initialize();

        // Setup - set the Tax schedule on CashFlowSetup
        CashFlowSetup.Get();
        CashFlowSetup."Taxable Period" := CashFlowSetup."Taxable Period"::Quarterly;
        Evaluate(CashFlowSetup."Tax Payment Window", '<5D>');
        CashFlowSetup.Modify();

        // Setup: Create two purchase orders
        PurchaseHeader1.DeleteAll();
        CFHelper.CreateDefaultPurchaseOrder(PurchaseHeader1);
        CFHelper.CreateDefaultPurchaseOrder(PurchaseHeader2);

        // Exercise: Call the unit
        Result := CashFlowManagement.GetTaxAmountFromPurchaseOrder(PurchaseHeader1) +
          CashFlowManagement.GetTaxAmountFromPurchaseOrder(PurchaseHeader2);

        // Verify: The sum of the tax amounts in the two purchase orders
        Assert.AreEqual(CFHelper.GetTotalTaxAmount(CashFlowSetup.GetTaxPaymentDueDate(PurchaseHeader1."Document Date"),
            DATABASE::"Purchase Header"), Result, 'Incorrect total taxable amount on purchase order calculated.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillCFJnlWithTaxSkipOlderPeriods()
    var
        CashFlowSetup: Record "Cash Flow Setup";
        SalesHeaderPrevPeriod: Record "Sales Header";
        SalesHeaderOlderThanPrevPeriod: Record "Sales Header";
        CashFlowForecast: Record "Cash Flow Forecast";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        ConsiderSource: array[16] of Boolean;
        DocumentDatePrevPeriod: Date;
        DocumentDateOlderThenPrevPeriod: Date;
    begin
        // Test filling a CF journal by using Fill batch with 2 sales orders in two periods
        // and verify that due and cash flow date are calculated only for the sales order whose taxa due date ends in current period.

        Initialize();

        // Setup - set the Tax schedule on CashFlowSetup
        CashFlowSetup.Get();
        CashFlowSetup."Taxable Period" := CashFlowSetup."Taxable Period"::Quarterly;
        Evaluate(CashFlowSetup."Tax Payment Window", '<5D>');
        CashFlowSetup.Modify();
        DocumentDatePrevPeriod := CalcDate('<-CQ-30D>', WorkDate());
        DocumentDateOlderThenPrevPeriod := CalcDate('<-CQ-30D>', DocumentDatePrevPeriod);

        // Setup - create the sales orders
        CFHelper.CreateDefaultSalesOrder(SalesHeaderPrevPeriod);
        SalesHeaderPrevPeriod."Document Date" := DocumentDatePrevPeriod;
        SalesHeaderPrevPeriod.Modify();
        SalesHeaderPrevPeriod.CalcFields("Amount Including VAT", Amount);
        CFHelper.CreateDefaultSalesOrder(SalesHeaderOlderThanPrevPeriod);
        SalesHeaderOlderThanPrevPeriod."Document Date" := DocumentDateOlderThenPrevPeriod;
        SalesHeaderOlderThanPrevPeriod.Modify();

        // Setup - create the forecast entity
        CFHelper.CreateCashFlowForecastDefault(CashFlowForecast);

        // Exercise
        ConsiderSource["Cash Flow Source Type"::Tax.AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify - no worksheet lines for the sales
        CFWorksheetLine.SetRange("Source No.", Format(DATABASE::"Sales Header"));
        CFWorksheetLine.SetFilter("Cash Flow Date", '<%1', WorkDate());
        Assert.AreEqual(1, CFWorksheetLine.Count, 'Old sales are going to be cumulated to the work date.');
        CFWorksheetLine.FindFirst();
        Assert.AreEqual(SalesHeaderPrevPeriod.Amount - SalesHeaderPrevPeriod."Amount Including VAT",
          CFWorksheetLine."Amount (LCY)", 'Only the sales from the prev period will be considered.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SOWithUnpostedPrepmt()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        SalesHeader: Record "Sales Header";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        ExpectedSOAmount: Decimal;
        ConsiderSource: array[16] of Boolean;
    begin
        // Test filling a CF journal using Fill Batch where discount and CF payment terms are not considered,
        // with a sales order which requires prepayment. The prepayment invoice has not been posted yet.

        // Setup
        Initialize();
        CFHelper.CreateCashFlowForecastDefault(CashFlowForecast);
        CFHelper.CreatePrepmtSalesOrder(SalesHeader, '', '');
        CFHelper.AddSOPrepayment(SalesHeader, LibraryRandom.RandInt(10));
        ExpectedSOAmount := CFHelper.GetTotalSalesAmount(SalesHeader, false);

        // Exercise
        ConsiderSource["Cash Flow Source Type"::"Sales Orders".AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify
        // Prepayment has not been posted, therefore it must not be considered in the forecast!
        CFHelper.VerifyCFDataOnSnglJnlLine(CFWorksheetLine, SalesHeader."No.", "Cash Flow Source Type"::"Sales Orders",
          CashFlowForecast."No.", ExpectedSOAmount, SalesHeader."Due Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SOWithPendingPrepmt()
    begin
        SOWithSinglePrepmt(false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SOWithPendingPrepmtAndGroupBy()
    begin
        SOWithSinglePrepmt(false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SOWithAppliedPrepmt()
    begin
        SOWithSinglePrepmt(true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SOWithAppliedPrepmtAndGroupBy()
    begin
        SOWithSinglePrepmt(true, true);
    end;

    local procedure SOWithSinglePrepmt(ApplyInvoicePayment: Boolean; GroupByDocumentType: Boolean)
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        SalesHeader: Record "Sales Header";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        GenJournalLine: Record "Gen. Journal Line";
        PrepaymentInvNo: Code[20];
        ExpectedSOAmount: Decimal;
        ExpectedPrepaymentAmount: Decimal;
        ConsiderSource: array[16] of Boolean;
    begin
        // Setup
        Initialize();
        CFHelper.CreateCashFlowForecastDefault(CashFlowForecast);
        CFHelper.CreatePrepmtSalesOrder(SalesHeader, '', '');

        PrepaymentInvNo := CFHelper.AddAndPostSOPrepaymentInvoice(SalesHeader, LibraryRandom.RandIntInRange(5, 20));
        ExpectedPrepaymentAmount := GetCustomerLedgerEntryAmount(PrepaymentInvNo, SalesHeader."Document Type"::Invoice);

        ExpectedSOAmount := CFHelper.GetTotalSalesAmount(SalesHeader, false);
        ExpectedSOAmount := ExpectedSOAmount - ExpectedPrepaymentAmount;

        if ApplyInvoicePayment then
            CFHelper.ApplyInvoicePayment(GenJournalLine, SalesHeader."Sell-to Customer No.",
              GenJournalLine."Account Type"::Customer, PrepaymentInvNo, -ExpectedPrepaymentAmount);

        // Exercise
        ConsiderSource["Cash Flow Source Type"::Receivables.AsInteger()] := true;
        ConsiderSource["Cash Flow Source Type"::"Sales Orders".AsInteger()] := true;
        CFHelper.FillJournal(ConsiderSource, CashFlowForecast."No.", GroupByDocumentType);

        // Verify
        CFHelper.VerifyCFDataOnSnglJnlLine(CFWorksheetLine, SalesHeader."No.", "Cash Flow Source Type"::"Sales Orders",
          CashFlowForecast."No.", ExpectedSOAmount, SalesHeader."Due Date");
        if not ApplyInvoicePayment then
            CFHelper.VerifyCFDataOnSnglJnlLine(CFWorksheetLine, PrepaymentInvNo, "Cash Flow Source Type"::Receivables,
              CashFlowForecast."No.", ExpectedPrepaymentAmount, SalesHeader."Due Date")
        else
            Assert.AreEqual(0, CFHelper.FilterSingleJournalLine(CFWorksheetLine, PrepaymentInvNo, "Cash Flow Source Type"::Receivables,
                CashFlowForecast."No."), StrSubstNo(NoLinesForAppliedPrepaymentErr, 'Receivables'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SOWithPendingSecondPrepmt()
    begin
        SOWithSecondPrepmt(false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SOWithPendingSecondPrepmtAndGroupBy()
    begin
        SOWithSecondPrepmt(false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SOWithAppliedSecondPrepmt()
    begin
        SOWithSecondPrepmt(true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SOWithAppliedSecondPrepmtAndGroupBy()
    begin
        SOWithSecondPrepmt(true, true);
    end;

    local procedure SOWithSecondPrepmt(ApplySecondInvoicePayment: Boolean; GroupByDocumentType: Boolean)
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        SalesHeader: Record "Sales Header";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        GenJournalLine: Record "Gen. Journal Line";
        FirstPrepaymentInvNo: Code[20];
        SecondPrepaymentInvNo: Code[20];
        FirstPrepaymentAmount: Decimal;
        SecondPrepaymentAmount: Decimal;
        ExpectedSOAmount: Decimal;
        ConsiderSource: array[16] of Boolean;
    begin
        // If second Prepayment is not applied, the first prepayment is applied.
        // Setup
        Initialize();
        CFHelper.CreateCashFlowForecastDefault(CashFlowForecast);
        CFHelper.CreatePrepmtSalesOrder(SalesHeader, '', '');

        FirstPrepaymentInvNo := CFHelper.AddAndPostSOPrepaymentInvoice(SalesHeader, LibraryRandom.RandIntInRange(5, 20));
        FirstPrepaymentAmount := GetCustomerLedgerEntryAmount(FirstPrepaymentInvNo, SalesHeader."Document Type"::Invoice);
        SecondPrepaymentInvNo := AddSalesLineAndPostAdditionalPrepaymentInvoice(SalesHeader);
        SecondPrepaymentAmount := GetCustomerLedgerEntryAmount(SecondPrepaymentInvNo, SalesHeader."Document Type"::Invoice);

        ExpectedSOAmount := CFHelper.GetTotalSalesAmount(SalesHeader, false);
        ExpectedSOAmount := ExpectedSOAmount - FirstPrepaymentAmount - SecondPrepaymentAmount;

        if ApplySecondInvoicePayment then
            CFHelper.ApplyInvoicePayment(GenJournalLine, SalesHeader."Sell-to Customer No.",
              GenJournalLine."Account Type"::Customer, SecondPrepaymentInvNo, -SecondPrepaymentAmount)
        else
            CFHelper.ApplyInvoicePayment(GenJournalLine, SalesHeader."Sell-to Customer No.",
              GenJournalLine."Account Type"::Customer, FirstPrepaymentInvNo, -FirstPrepaymentAmount);

        // Exercise
        ConsiderSource["Cash Flow Source Type"::Receivables.AsInteger()] := true;
        ConsiderSource["Cash Flow Source Type"::"Sales Orders".AsInteger()] := true;
        CFHelper.FillJournal(ConsiderSource, CashFlowForecast."No.", GroupByDocumentType);

        // Verify
        CFHelper.VerifyCFDataOnSnglJnlLine(CFWorksheetLine, SalesHeader."No.", "Cash Flow Source Type"::"Sales Orders",
          CashFlowForecast."No.", ExpectedSOAmount, SalesHeader."Due Date");
        if ApplySecondInvoicePayment then
            CFHelper.VerifyCFDataOnSnglJnlLine(CFWorksheetLine, FirstPrepaymentInvNo, "Cash Flow Source Type"::Receivables,
              CashFlowForecast."No.", FirstPrepaymentAmount, SalesHeader."Due Date")
        else
            CFHelper.VerifyCFDataOnSnglJnlLine(CFWorksheetLine, SecondPrepaymentInvNo, "Cash Flow Source Type"::Receivables,
              CashFlowForecast."No.", SecondPrepaymentAmount, SalesHeader."Due Date")
    end;

    [Test]
    [Scope('OnPrem')]
    procedure POWithUnpostedPrepmt()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        PurchaseHeader: Record "Purchase Header";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        ExpectedPOAmount: Decimal;
        ConsiderSource: array[16] of Boolean;
    begin
        // Setup
        Initialize();
        CFHelper.CreateCashFlowForecastDefault(CashFlowForecast);
        CFHelper.CreatePrepmtPurchaseOrder(PurchaseHeader, '', '');
        CFHelper.AddPOPrepayment(PurchaseHeader, LibraryRandom.RandInt(10));
        ExpectedPOAmount := CFHelper.GetTotalPurchaseAmount(PurchaseHeader, false);

        // Exercise
        LibraryApplicationArea.EnableFoundationSetup();
        ConsiderSource["Cash Flow Source Type"::"Purchase Orders".AsInteger()] := true;
        CFHelper.FillJournal(ConsiderSource, CashFlowForecast."No.", true);

        // Verify
        // Prepayment has not been posted, therefore it must not be considered in the forecast!
        CFHelper.VerifyCFDataOnSnglJnlLine(CFWorksheetLine, PurchaseHeader."No.", "Cash Flow Source Type"::"Purchase Orders",
          CashFlowForecast."No.", -ExpectedPOAmount, PurchaseHeader."Due Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure POWithPendingPrepmt()
    begin
        POWithSinglePrepmt(false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure POWithPendingPrepmtAndGroupBy()
    begin
        POWithSinglePrepmt(false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure POWithAppliedPrepmt()
    begin
        POWithSinglePrepmt(true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure POWithAppliedPrepmtAndGroupBy()
    begin
        POWithSinglePrepmt(true, true);
    end;

    local procedure POWithSinglePrepmt(ApplyInvoicePayment: Boolean; GroupByDocumentType: Boolean)
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        PurchaseHeader: Record "Purchase Header";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        GenJournalLine: Record "Gen. Journal Line";
        PrepaymentInvNo: Code[20];
        ExpectedPrepaymentAmount: Decimal;
        ExpectedPOAmount: Decimal;
        ConsiderSource: array[16] of Boolean;
    begin
        // Setup
        Initialize();
        CFHelper.CreateCashFlowForecastDefault(CashFlowForecast);
        CFHelper.CreatePrepmtPurchaseOrder(PurchaseHeader, '', '');

        PrepaymentInvNo := CFHelper.AddAndPostPOPrepaymentInvoice(PurchaseHeader, LibraryRandom.RandIntInRange(5, 20));
        ExpectedPrepaymentAmount := -GetVendorLedgerEntryAmount(PrepaymentInvNo, PurchaseHeader."Document Type"::Invoice);

        ExpectedPOAmount := CFHelper.GetTotalPurchaseAmount(PurchaseHeader, false);
        ExpectedPOAmount := ExpectedPOAmount - ExpectedPrepaymentAmount;

        if ApplyInvoicePayment then
            CFHelper.ApplyInvoicePayment(GenJournalLine, PurchaseHeader."Buy-from Vendor No.",
              GenJournalLine."Account Type"::Vendor, PrepaymentInvNo, ExpectedPrepaymentAmount);

        // Exercise
        LibraryApplicationArea.EnableFoundationSetup();
        ConsiderSource["Cash Flow Source Type"::Payables.AsInteger()] := true;
        ConsiderSource["Cash Flow Source Type"::"Purchase Orders".AsInteger()] := true;
        CFHelper.FillJournal(ConsiderSource, CashFlowForecast."No.", GroupByDocumentType);

        // Verify
        CFHelper.VerifyCFDataOnSnglJnlLine(CFWorksheetLine, PurchaseHeader."No.", "Cash Flow Source Type"::"Purchase Orders",
          CashFlowForecast."No.", -ExpectedPOAmount, PurchaseHeader."Due Date");
        if not ApplyInvoicePayment then
            CFHelper.VerifyCFDataOnSnglJnlLine(CFWorksheetLine, PrepaymentInvNo, "Cash Flow Source Type"::Payables,
              CashFlowForecast."No.", -ExpectedPrepaymentAmount, PurchaseHeader."Due Date")
        else
            Assert.AreEqual(0, CFHelper.FilterSingleJournalLine(CFWorksheetLine, PrepaymentInvNo, "Cash Flow Source Type"::Receivables,
                CashFlowForecast."No."), StrSubstNo(NoLinesForAppliedPrepaymentErr, 'Payables'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure POWithPendingSecondPrepmt()
    begin
        POWithSecondPrepmt(false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure POWithPendingSecondPrepmtAndGroupBy()
    begin
        POWithSecondPrepmt(false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure POWithAppliedSecondPrepmt()
    begin
        POWithSecondPrepmt(true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure POWithAppliedSecondPrepmtAndGroupBy()
    begin
        POWithSecondPrepmt(true, true);
    end;

    local procedure POWithSecondPrepmt(ApplySecondInvoicePayment: Boolean; GroupByDocumentType: Boolean)
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        PurchaseHeader: Record "Purchase Header";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        GenJournalLine: Record "Gen. Journal Line";
        FirstPrepaymentInvNo: Code[20];
        SecondPrepaymentInvNo: Code[20];
        FirstPrepaymentAmount: Decimal;
        SecondPrepaymentAmount: Decimal;
        ExpectedPOAmount: Decimal;
        ConsiderSource: array[16] of Boolean;
    begin
        // If second Prepayment is not applied, the first prepayment is applied.
        // Setup
        Initialize();
        CFHelper.CreateCashFlowForecastDefault(CashFlowForecast);
        CFHelper.CreatePrepmtPurchaseOrder(PurchaseHeader, '', '');

        FirstPrepaymentInvNo :=
          CFHelper.AddAndPostPOPrepaymentInvoice(PurchaseHeader, LibraryRandom.RandIntInRange(5, 20));
        FirstPrepaymentAmount := -GetVendorLedgerEntryAmount(FirstPrepaymentInvNo, PurchaseHeader."Document Type"::Invoice);
        SecondPrepaymentInvNo := AddPurchaseLineAndPostAdditionalPrepaymentInvoice(PurchaseHeader);
        SecondPrepaymentAmount := -GetVendorLedgerEntryAmount(SecondPrepaymentInvNo, PurchaseHeader."Document Type"::Invoice);

        ExpectedPOAmount := CFHelper.GetTotalPurchaseAmount(PurchaseHeader, false);
        ExpectedPOAmount := ExpectedPOAmount - FirstPrepaymentAmount - SecondPrepaymentAmount;

        if ApplySecondInvoicePayment then
            CFHelper.ApplyInvoicePayment(GenJournalLine, PurchaseHeader."Buy-from Vendor No.",
              GenJournalLine."Account Type"::Vendor, SecondPrepaymentInvNo, SecondPrepaymentAmount)
        else
            CFHelper.ApplyInvoicePayment(GenJournalLine, PurchaseHeader."Buy-from Vendor No.",
              GenJournalLine."Account Type"::Vendor, FirstPrepaymentInvNo, FirstPrepaymentAmount);

        // Exercise
        LibraryApplicationArea.EnableFoundationSetup();
        ConsiderSource["Cash Flow Source Type"::Payables.AsInteger()] := true;
        ConsiderSource["Cash Flow Source Type"::"Purchase Orders".AsInteger()] := true;
        CFHelper.FillJournal(ConsiderSource, CashFlowForecast."No.", GroupByDocumentType);

        // Verify
        CFHelper.VerifyCFDataOnSnglJnlLine(CFWorksheetLine, PurchaseHeader."No.", "Cash Flow Source Type"::"Purchase Orders",
          CashFlowForecast."No.", -ExpectedPOAmount, PurchaseHeader."Due Date");
        if ApplySecondInvoicePayment then
            CFHelper.VerifyCFDataOnSnglJnlLine(CFWorksheetLine, FirstPrepaymentInvNo, "Cash Flow Source Type"::Payables,
              CashFlowForecast."No.", -FirstPrepaymentAmount, PurchaseHeader."Due Date")
        else
            CFHelper.VerifyCFDataOnSnglJnlLine(CFWorksheetLine, SecondPrepaymentInvNo, "Cash Flow Source Type"::Payables,
              CashFlowForecast."No.", -SecondPrepaymentAmount, PurchaseHeader."Due Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillCFJnlWithModifiedCustLEDueDate()
    begin
        // Filling CF journal lines without considering CF Payment Terms where the due date field on the customer ledger entries
        // has been manually modified before running the fill batch job

        // Exercise and Verify
        VerifyModifiedCustLEDatesOnCFJnl(DateFieldOption::DueDate, false, false, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillCFJnlWithModifiedCustLEDueDateConsiderCFPmtTerms()
    var
        PaymentTerms: Record "Payment Terms";
    begin
        // Filling CF journal lines considering CF Payment Terms where the due date field on the customer ledger entries
        // has been manually modified before running the fill batch job

        // Exercise and Verify - dont consider discount but CF Pmt Terms
        VerifyModifiedCustLEDatesOnCFJnl(DateFieldOption::DueDate, false, true, PaymentTerms.FieldNo("Due Date Calculation"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillCFJnlWithModifiedVendLEDueDate()
    begin
        // Filling CF journal lines without considering CF Payment Terms where the due date field on the vendor ledger entries
        // has been manually modified before running the fill batch job

        // Exercise and Verify - dont consider discount and CF Pmt Terms
        VerifyModifiedVendLEDatesOnCFJnl(DateFieldOption::DueDate, false, false, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillCFJnlWithModifiedVendLEDueDateConsiderCFPmtTerms()
    var
        PaymentTerms: Record "Payment Terms";
    begin
        // Filling CF journal lines considering CF Payment Terms where the due date field on the vendor ledger entries
        // has been manually modified before running the fill batch job

        // Exercise and Verify - dont consider discount but CF Pmt Terms
        VerifyModifiedVendLEDatesOnCFJnl(DateFieldOption::DueDate, false, true, PaymentTerms.FieldNo("Due Date Calculation"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillCFJnlWithModifiedCustLEDsctDate()
    begin
        // Filling CF journal lines without considering CF Payment Terms where the discount date field on the customer ledger entries
        // has been manually modified before running the fill batch job

        // Exercise and Verify - consider discount but not CF Pmt Terms
        VerifyModifiedCustLEDatesOnCFJnl(DateFieldOption::DiscountDate, true, false, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillCFJnlWithModifiedCustLEDsctDateConsiderCFPmtTerms()
    var
        PaymentTerms: Record "Payment Terms";
    begin
        // Filling CF journal lines considering CF Payment Terms where the discount date field on the customer ledger entries
        // has been manually modified before running the fill batch job

        // Exercise and Verify - consider discount and CF Pmt Terms
        VerifyModifiedCustLEDatesOnCFJnl(DateFieldOption::DiscountDate, true, true, PaymentTerms.FieldNo("Discount Date Calculation"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillCFJnlWithModifiedVendLEDsctDate()
    begin
        // Filling CF journal lines without considering CF Payment Terms where the discount date field on the vendor ledger entries
        // has been manually modified before running the fill batch job

        // Exercise and Verify - consider discount but not CF Pmt Terms
        VerifyModifiedVendLEDatesOnCFJnl(DateFieldOption::DiscountDate, true, false, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillCFJnlWithModifiedVendLEDsctDateConsiderCFPmtTerms()
    var
        PaymentTerms: Record "Payment Terms";
    begin
        // Filling CF journal lines considering CF Payment Terms where the discount date field on the vendor ledger entries
        // has been manually modified before running the fill batch job

        // Exercise and Verify - consider discount and CF Pmt Terms
        VerifyModifiedVendLEDatesOnCFJnl(DateFieldOption::DiscountDate, true, true, PaymentTerms.FieldNo("Discount Date Calculation"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyServiceOrderSourceTypeInJnlLine()
    var
        ServiceHeader: Record "Service Header";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        CashFlowForecast: Record "Cash Flow Forecast";
        ConsiderSource: array[16] of Boolean;
    begin
        // Setup
        Initialize();
        CFHelper.CreateCashFlowForecastDefault(CashFlowForecast);
        LibraryService.CreateDefaultServiceOrder(ServiceHeader);

        // Exercise
        ConsiderSource["Cash Flow Source Type"::"Service Orders".AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify
        CFHelper.FilterSingleJournalLine(CFWorksheetLine, ServiceHeader."No.", "Cash Flow Source Type"::"Service Orders", CashFlowForecast."No.");
        CFWorksheetLine.TestField("Source Type", CFWorksheetLine."Source Type"::"Service Orders");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyServiceOrderSourceTypeInLedgEntry()
    var
        ServiceHeader: Record "Service Header";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        CashFlowForecast: Record "Cash Flow Forecast";
        CFForecastEntry: Record "Cash Flow Forecast Entry";
        ConsiderSource: array[16] of Boolean;
    begin
        // Setup
        Initialize();
        CFHelper.CreateCashFlowForecastDefault(CashFlowForecast);
        LibraryService.CreateDefaultServiceOrder(ServiceHeader);

        // Exercise
        ConsiderSource["Cash Flow Source Type"::"Service Orders".AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");
        CFHelper.FilterSingleJournalLine(CFWorksheetLine, ServiceHeader."No.", "Cash Flow Source Type"::"Service Orders", CashFlowForecast."No.");

        LibraryCF.PostJournalLines(CFWorksheetLine);

        // Verify
        CFForecastEntry.SetRange("Document No.", ServiceHeader."No.");
        CFForecastEntry.FindFirst();
        CFForecastEntry.TestField("Source Type", CFForecastEntry."Source Type"::"Service Orders");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestLinesConsideringGLBudget()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        GLBudgetEntry: Record "G/L Budget Entry";
    begin
        // Suggest lines should set source type accordingly

        // Setup
        Initialize();
        CFHelper.CreateCashFlowForecastDefault(CashFlowForecast);
        CashFlowForecast.Validate("G/L Budget From", WorkDate());
        CashFlowForecast.Validate("G/L Budget To", WorkDate());
        CashFlowForecast.Modify(true);
        CFHelper.CreateBudgetEntry(GLBudgetEntry, CashFlowForecast."G/L Budget To");

        // Exercise
        LibraryCF.FillBudgetJournal(false, CashFlowForecast."No.", GLBudgetEntry."Budget Name");

        // Verify
        CFHelper.FilterSingleJournalLine(CFWorksheetLine, Format(GLBudgetEntry."Entry No."),
          CFWorksheetLine."Source Type"::"G/L Budget", CashFlowForecast."No.");
        CFWorksheetLine.TestField("Source Type", CFWorksheetLine."Source Type"::"G/L Budget");
        CFWorksheetLine.TestField("G/L Budget Name", GLBudgetEntry."Budget Name");
        CFHelper.VerifyExpectedCFAmount(-GLBudgetEntry.Amount, CFWorksheetLine."Amount (LCY)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SingleSalesPrepaymentInvoicePriceExclVAT()
    begin
        PostSingleSalesPrepaymentInvoice(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultipleSalesPrepaymentInvoicePriceExclVAT()
    begin
        PostMultipleSalesPrepaymentInvoice(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SingleSalesPrepaymentInvoicePriceIncVAT()
    begin
        PostSingleSalesPrepaymentInvoice(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultipleSalesPrepaymentInvoicePriceIncVAT()
    begin
        PostMultipleSalesPrepaymentInvoice(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestApplicationAreasForJobs()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        Job: Record Job;
        JobPlanningLine: Record "Job Planning Line";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        ConsiderSource: array[16] of Boolean;
        OldDate: Date;
        NewDate: Date;
    begin
        // [SCENARIO] Jobs are only included in the CF if Jobs App Area is enabled

        SetupCashFlowForJobs(CashFlowForecast, Job, JobPlanningLine, OldDate, NewDate);

        // Exercise
        ConsiderSource["Cash Flow Source Type"::Job.AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify no data have been included for jobs
        Assert.AreEqual(CashFlowForecast."Amount (LCY)", 0, 'Unexpected Cashflow ammount');

        // Exercise
        LibraryApplicationArea.EnableJobsSetup();
        ConsiderSource["Cash Flow Source Type"::Job.AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify data have been included for jobs
        CFHelper.VerifyCFDataOnSnglJnlLine(CFWorksheetLine, Job."No.", "Cash Flow Source Type"::Job,
          CashFlowForecast."No.", CFHelper.GetTotalJobsAmount(Job, OldDate), OldDate);
        CFHelper.VerifyCFDataOnSnglJnlLine(CFWorksheetLine, Job."No.", "Cash Flow Source Type"::Job,
          CashFlowForecast."No.", CFHelper.GetTotalJobsAmount(Job, NewDate), NewDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestApplicationAreasForJobsWithPaymentTerms()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        Job: Record Job;
        JobPlanningLine: Record "Job Planning Line";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        PaymentTerms: Record "Payment Terms";
        ConsiderSource: array[16] of Boolean;
        OldDate: Date;
        NewDate: Date;
        DueDateCalculation: DateFormula;
    begin
        // [FEATURE] [Jobs]
        // [SCENARIO 402915] Jobs with Payment Terms are included in the CF with recalculated Cash Flow Date
        // [GIVEN] Job for Customer with Payment Terms of '5D' having lines with "Document Date" = 01/02/21, 05/02/21
        SetupCashFlowForJobsWithPaymentTerms(CashFlowForecast, Job, JobPlanningLine, PaymentTerms, OldDate, NewDate);
        PaymentTerms.GetDueDateCalculation(DueDateCalculation);

        // [WHEN] Run 'Suggest Worksheet Lines' report for the job
        LibraryApplicationArea.EnableJobsSetup();
        ConsiderSource["Cash Flow Source Type"::Job.AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // [THEN] Cash Flow Worksheet lines created with correct amounts and "Cash Flow Date" = 06/02/21, 11/02/21 respectively
        CFHelper.VerifyCFDataOnSnglJnlLineWithDates(
          CFWorksheetLine, Job."No.", "Cash Flow Source Type"::Job, CashFlowForecast."No.", OldDate,
          CFHelper.GetTotalJobsAmount(Job, OldDate), CalcDate(DueDateCalculation, OldDate));
        CFHelper.VerifyCFDataOnSnglJnlLineWithDates(
          CFWorksheetLine, Job."No.", "Cash Flow Source Type"::Job, CashFlowForecast."No.", NewDate,
          CFHelper.GetTotalJobsAmount(Job, NewDate), CalcDate(DueDateCalculation, NewDate));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestApplicationAreasForPurchaseOrders()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        PurchaseHeader: Record "Purchase Header";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        ConsiderSource: array[16] of Boolean;
    begin
        // [SCENARIO] Purchase Orders are only included in the CF if Suite App Area is enabled

        // Setup
        Initialize();
        CFHelper.CreateCashFlowForecastDefault(CashFlowForecast);
        CFHelper.CreateDefaultPurchaseOrder(PurchaseHeader);

        // GIVEN no application area is enabled
        ConsiderSource["Cash Flow Source Type"::"Purchase Orders".AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify no data have been included for purchase orders
        Assert.AreEqual(CashFlowForecast."Amount (LCY)", 0, 'Unexpected Cashflow ammount');

        // GIVEN application area Suite is enabled
        LibraryApplicationArea.EnableFoundationSetup();
        ConsiderSource["Cash Flow Source Type"::"Purchase Orders".AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify data have been included for purchase orders
        CFHelper.VerifyCFDataOnSnglJnlLine(CFWorksheetLine, PurchaseHeader."No.", "Cash Flow Source Type"::"Purchase Orders",
          CashFlowForecast."No.", -CFHelper.GetTotalPurchaseAmount(PurchaseHeader, false), PurchaseHeader."Due Date");
    end;

    local procedure PostSingleSalesPrepaymentInvoice(PricesInclVAT: Boolean)
    var
        SalesHeader: Record "Sales Header";
    begin
        Initialize();

        PostSalesPrepaymentInvoice(SalesHeader, PricesInclVAT);
        VerifySalesOrderInCashFlowWorksheet(SalesHeader);
    end;

    local procedure PostMultipleSalesPrepaymentInvoice(PricesInclVAT: Boolean)
    var
        SalesHeader: Record "Sales Header";
    begin
        Initialize();

        PostSalesPrepaymentInvoice(SalesHeader, PricesInclVAT);
        AddSalesLineAndPostAdditionalPrepaymentInvoice(SalesHeader);
        VerifySalesOrderInCashFlowWorksheet(SalesHeader);
    end;

    local procedure PostSalesPrepaymentInvoice(var SalesHeader: Record "Sales Header"; PricesInclVAT: Boolean)
    var
        SalesLine: Record "Sales Line";
        SalesPostPrepayments: Codeunit "Sales-Post Prepayments";
    begin
        CreateSalesPrepaymentInvoice(SalesHeader, SalesLine, PricesInclVAT);
        SalesPostPrepayments.Invoice(SalesHeader);
    end;

    local procedure AddSalesLineAndPostAdditionalPrepaymentInvoice(var SalesHeader: Record "Sales Header"): Code[20]
    var
        GLAccount: Record "G/L Account";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.ReopenSalesDocument(SalesHeader);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindLast();
        GLAccount.Get(SalesLine."No.");
        CFHelper.CreateSalesLine(SalesHeader, GLAccount);
        exit(CFHelper.PostSOPrepaymentInvoice(SalesHeader));
    end;

    local procedure VerifySalesOrderInCashFlowWorksheet(SalesHeader: Record "Sales Header")
    var
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        ExpectedAmount: Decimal;
    begin
        ExpectedAmount := GetSalesActualAmount(SalesHeader);

        FindFilledCashFlowJnlLine(CFWorksheetLine, CFWorksheetLine."Source Type"::"Sales Orders", SalesHeader."No.");
        Assert.AreNearlyEqual(
          ExpectedAmount, CFWorksheetLine."Amount (LCY)", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountError, ExpectedAmount, CFWorksheetLine."Amount (LCY)"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SinglePurchasePrepaymentInvoicePriceExclVAT()
    begin
        PostSinglePurchasePrepaymentInvoice(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultiplePurchasePrepaymentInvoicePriceExclVAT()
    begin
        PostMultiplePurchasePrepaymentInvoice(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SinglePurchasePrepaymentInvoicePriceIncVAT()
    begin
        PostSinglePurchasePrepaymentInvoice(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultiplePurchasePrepaymentInvoicePriceIncVAT()
    begin
        PostMultiplePurchasePrepaymentInvoice(true);
    end;

    local procedure PostSinglePurchasePrepaymentInvoice(PricesInclVAT: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        Initialize();

        PostPurchasePrepaymentInvoice(PurchaseHeader, PricesInclVAT);
        VerifyPurchaseOrderInCashFlowWorksheet(PurchaseHeader);
    end;

    local procedure PostMultiplePurchasePrepaymentInvoice(PricesInclVAT: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        Initialize();

        PostPurchasePrepaymentInvoice(PurchaseHeader, PricesInclVAT);
        AddPurchaseLineAndPostAdditionalPrepaymentInvoice(PurchaseHeader);
        VerifyPurchaseOrderInCashFlowWorksheet(PurchaseHeader);
    end;

    local procedure PostPurchasePrepaymentInvoice(var PurchaseHeader: Record "Purchase Header"; PricesInclVAT: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchasePrepaymentInvoice(PurchaseHeader, PurchaseLine, PricesInclVAT);
        PurchasePostPrepaymentInvoice(PurchaseHeader);
    end;

    local procedure AddPurchaseLineAndPostAdditionalPrepaymentInvoice(var PurchaseHeader: Record "Purchase Header"): Code[20]
    var
        GLAccount: Record "G/L Account";
        PurchLine: Record "Purchase Line";
    begin
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        PurchaseHeader.Validate("Vendor Invoice No.",
          LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("Vendor Invoice No."), DATABASE::"Purchase Header"));
        PurchLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchLine.FindLast();
        GLAccount.Get(PurchLine."No.");
        CFHelper.CreatePurchaseLine(PurchaseHeader, GLAccount);
        exit(CFHelper.PostPOPrepaymentInvoice(PurchaseHeader));
    end;

    local procedure PurchasePostPrepaymentInvoice(var PurchaseHeader: Record "Purchase Header")
    var
        PurchPostPrepayments: Codeunit "Purchase-Post Prepayments";
    begin
        SetPrepaymentPctOnPurchaseLines(PurchaseHeader);
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());

        PurchPostPrepayments.Invoice(PurchaseHeader);
    end;

    local procedure VerifyPurchaseOrderInCashFlowWorksheet(PurchaseHeader: Record "Purchase Header")
    var
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        ExpectedAmount: Decimal;
    begin
        ExpectedAmount := -GetPurchaseActualAmount(PurchaseHeader);

        FindFilledCashFlowJnlLine(CFWorksheetLine, CFWorksheetLine."Source Type"::"Purchase Orders", PurchaseHeader."No.");
        Assert.AreNearlyEqual(
          ExpectedAmount, CFWorksheetLine."Amount (LCY)", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountError, ExpectedAmount, CFWorksheetLine."Amount (LCY)"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MovingDefDimAfterRenameCashFlowManualRevenue()
    var
        CashFlowManualRevenue: Record "Cash Flow Manual Revenue";
        DimensionValue: array[2] of Record "Dimension Value";
    begin
        // [SCENARIO 208630] Default dimension have to been exist after renaming record of "Cash Flow Manual Revenue"
        Initialize();

        // [GIVEN] "Cash Flow Manual Revenue" with Code = "NAME1"
        LibraryCF.CreateManualLineRevenue(CashFlowManualRevenue, '');

        // [GIVEN] Default dimension DIM1 with value DIMVALUE1
        CreateDefDimForRecord(DimensionValue[1], DATABASE::"Cash Flow Manual Revenue", CashFlowManualRevenue.Code);

        // [GIVEN] Default dimension DIM2 with value DIMVALUE2
        CreateDefDimForRecord(DimensionValue[2], DATABASE::"Cash Flow Manual Revenue", CashFlowManualRevenue.Code);

        // [WHEN] Rename "Cash Flow Manual Revenue" to "NAME2"
        CashFlowManualRevenue.Rename(
          LibraryUtility.GenerateRandomCode(CashFlowManualRevenue.FieldNo(Code), DATABASE::"Cash Flow Manual Revenue"));

        // [THEN] Renamed record has values:
        // [THEN] Global Dimension 1 Code = "DIM1" with value = "DIMVALUE1"
        VerifyDefaultDimension(DimensionValue[1], DATABASE::"Cash Flow Manual Revenue", CashFlowManualRevenue.Code);

        // [THEN] Global Dimension 2 Code = "DIM2" with value = "DIMVALUE2"
        VerifyDefaultDimension(DimensionValue[2], DATABASE::"Cash Flow Manual Revenue", CashFlowManualRevenue.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MovingDefDimAfterRenameCashFlowManualExpense()
    var
        CashFlowManualExpense: Record "Cash Flow Manual Expense";
        DimensionValue: array[2] of Record "Dimension Value";
    begin
        // [SCENARIO 208630] Default dimension have to been exist after renaming record of "Cash Flow Manual Expense"
        Initialize();

        // [GIVEN] "Cash Flow Manual Expense" with Code = "NAME1"
        LibraryCF.CreateManualLinePayment(CashFlowManualExpense, '');

        // [GIVEN] Default dimension DIM1 with value DIMVALUE1
        CreateDefDimForRecord(DimensionValue[1], DATABASE::"Cash Flow Manual Expense", CashFlowManualExpense.Code);

        // [GIVEN] Default dimension DIM2 with value DIMVALUE2
        CreateDefDimForRecord(DimensionValue[2], DATABASE::"Cash Flow Manual Expense", CashFlowManualExpense.Code);

        // [WHEN] Rename "Cash Flow Manual Expense" to "NAME2"
        CashFlowManualExpense.Rename(
          LibraryUtility.GenerateRandomCode(CashFlowManualExpense.FieldNo(Code), DATABASE::"Cash Flow Manual Expense"));

        // [THEN] Renamed record has values:
        // [THEN] Global Dimension 1 Code = "DIM1" with value = "DIMVALUE1"
        VerifyDefaultDimension(DimensionValue[1], DATABASE::"Cash Flow Manual Expense", CashFlowManualExpense.Code);

        // [THEN] Global Dimension 2 Code = "DIM2" with value = "DIMVALUE2"
        VerifyDefaultDimension(DimensionValue[2], DATABASE::"Cash Flow Manual Expense", CashFlowManualExpense.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyCasFlowForecastForBudgetedFixedAsset()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        FixedAsset: Record "Fixed Asset";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        FASetup: Record "FA Setup";
        InvestmentAmount: Decimal;
        ConsiderSource: array[16] of Boolean;
    begin
        // [SCENARIO] 473911 Budgeted Fixed Asset do not appear correctly in Cash Flow Forecast
        CFWorksheetLine.DeleteAll();

        // [GIVEN] Create Cash Flow Forecast Default.
        CFHelper.CreateCashFlowForecastDefault(CashFlowForecast);

        // [GIVEN] Create Amount 
        InvestmentAmount := LibraryRandom.RandDec(2000, 2);

        // [GIVEN] Create Fixed Asset and Post two FA Journal Line
        FASetup.Get();
        CreateFixedAssetAndPostTwoFAJournalLine(FixedAsset, FASetup."Default Depr. Book", InvestmentAmount);

        // [WHEN] Using Suggest WorkSheet Lines, create Cash Flow Worksheet Lines.
        ConsiderSource["Cash Flow Source Type"::"Fixed Assets Budget".AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // [WHEN] Filter Cash Flow WorkSheet Lines to created Cash Flow Forecast and Fixed Asset.
        CFWorksheetLine.SetRange("Cash Flow Forecast No.", CashFlowForecast."No.");
        CFWorkSheetLine.SetRange("Document No.", FixedAsset."No.");
        CFWorksheetLine.FindSet();

        // [VERIFY] Verify 2 lines created for created Fixed Asset
        Assert.AreEqual(2, CFWorksheetLine.Count, CashFlowWorkSheetLineCountErr);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Cash Flow Filling I");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Cash Flow Filling I");

        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Cash Flow Filling I");
    end;

    local procedure CalculatePurchaseActualAmountInclPrepayment(PurchaseHeader: Record "Purchase Header"; InvoiceRoundingPrecision: Decimal) Amount: Decimal
    var
        PurchaseLine: Record "Purchase Line";
        PrepaymentAmount: Decimal;
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        if PurchaseLine.FindSet() then
            repeat
                PrepaymentAmount := Round(PurchaseLine.Amount * PurchaseHeader."Prepayment %" / 100, InvoiceRoundingPrecision);
                PrepaymentAmount += Round(PrepaymentAmount * PurchaseLine."VAT %" / 100, InvoiceRoundingPrecision);
                Amount += PurchaseLine."Amount Including VAT" - PrepaymentAmount;
            until PurchaseLine.Next() = 0;
    end;

    local procedure CalculateSalesActualAmountInclPrepayment(SalesHeader: Record "Sales Header"; InvoiceRoundingPrecision: Decimal) Amount: Decimal
    var
        SalesLine: Record "Sales Line";
        PrepaymentAmount: Decimal;
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindSet() then
            repeat
                PrepaymentAmount := Round(SalesLine.Amount * SalesHeader."Prepayment %" / 100, InvoiceRoundingPrecision);
                PrepaymentAmount += Round(PrepaymentAmount * SalesLine."VAT %" / 100, InvoiceRoundingPrecision);
                Amount += SalesLine."Amount Including VAT" - PrepaymentAmount;
            until SalesLine.Next() = 0;
    end;

    local procedure CreateSalesPrepaymentInvoice(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; PricesInclVAT: Boolean)
    var
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        CustomerNo: Code[20];
    begin
        LibrarySales.CreatePrepaymentVATSetup(GLAccount, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CustomerNo :=
          LibrarySales.CreateCustomerWithBusPostingGroups(
            GLAccount."Gen. Bus. Posting Group", GLAccount."VAT Bus. Posting Group");
        CreateSalesOrder(SalesHeader, PricesInclVAT, CustomerNo);
        SetPrepaymentPctOnSalesHeader(SalesHeader, LibraryRandom.RandDecInRange(10, 90, 2));
        CreateTwoSalesOrderLines(SalesHeader, GLAccount."No.", SalesLine);
    end;

    local procedure CreatePurchasePrepaymentInvoice(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; PricesInclVAT: Boolean)
    var
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        VendorNo: Code[20];
    begin
        LibraryPurchase.CreatePrepaymentVATSetup(GLAccount, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VendorNo :=
          LibraryPurchase.CreateVendorWithBusPostingGroups(
            GLAccount."Gen. Bus. Posting Group", GLAccount."VAT Bus. Posting Group");
        CreatePurchaseOrder(PurchaseHeader, PricesInclVAT, VendorNo);
        SetPrepaymentPctOnPurchaseHeader(PurchaseHeader, LibraryRandom.RandDecInRange(10, 90, 2));
        CreateTwoPurchaseOrderLines(PurchaseHeader, GLAccount."No.", PurchaseLine);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; PricesInclVAT: Boolean; CustomerNo: Code[20])
    begin
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        SetPricesInclVATOnSalesHeader(SalesHeader, PricesInclVAT);
    end;

    local procedure CreateTwoSalesOrderLines(SalesHeader: Record "Sales Header"; GLAccountNo: Code[20]; var SalesLine: Record "Sales Line")
    var
        Index: Integer;
    begin
        for Index := 1 to 2 do begin
            LibrarySales.CreateSalesLine(
              SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccountNo, LibraryRandom.RandDec(10, 2));
            SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(10, 100, 2));
            SalesLine.Modify(true);
        end;
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; PricesInclVAT: Boolean; VendorNo: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        SetPricesInclVATOnPurchaseHeader(PurchaseHeader, PricesInclVAT);
    end;

    local procedure CreateTwoPurchaseOrderLines(PurchaseHeader: Record "Purchase Header"; GLAccountNo: Code[20]; var PurchaseLine: Record "Purchase Line")
    var
        Index: Integer;
    begin
        for Index := 1 to 2 do begin
            LibraryPurchase.CreatePurchaseLine(
              PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccountNo, LibraryRandom.RandDec(10, 2));
            PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 100, 2));
            PurchaseLine.Modify(true);
        end;
    end;

    local procedure CreateCashFlowForecastDefaultWithManualPmtDates(var CashFlowForecast: Record "Cash Flow Forecast"; ManualPaymentsFrom: Date; ManualPaymentsTo: Date)
    begin
        CFHelper.CreateCashFlowForecastDefault(CashFlowForecast);
        CashFlowForecast."Manual Payments From" := ManualPaymentsFrom;
        CashFlowForecast."Manual Payments To" := ManualPaymentsTo;
        CashFlowForecast.Modify();
    end;

    local procedure CreateManualRevenueWithStartingDate(var CFManualRevenue: Record "Cash Flow Manual Revenue"; StartingDate: Date)
    begin
        CFHelper.CreateManualRevenue(CFManualRevenue);
        Evaluate(CFManualRevenue."Recurring Frequency", '');
        CFManualRevenue."Starting Date" := StartingDate;
        CFManualRevenue.Modify();
    end;

    local procedure CreateManualExpenseWithStartingDate(var CFManualExpense: Record "Cash Flow Manual Expense"; StartingDate: Date)
    begin
        CFHelper.CreateManualPayment(CFManualExpense);
        Evaluate(CFManualExpense."Recurring Frequency", '');
        CFManualExpense."Starting Date" := StartingDate;
        CFManualExpense.Modify();
    end;

    local procedure CreateDefDimForRecord(var DimensionValue: Record "Dimension Value"; TableID: Integer; "Code": Code[20])
    var
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, TableID, Code, DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    local procedure FindFilledCashFlowJnlLine(var CashFlowWorksheetLine: Record "Cash Flow Worksheet Line"; SourceType: Enum "Cash Flow Source Type"; DocumentNo: Code[20])
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        ConsiderSource: array[16] of Boolean;
    begin
        CFHelper.CreateCashFlowForecastDefault(CashFlowForecast);
        ConsiderSource[SourceType.AsInteger()] := true;
        CFHelper.FillJournal(ConsiderSource, CashFlowForecast."No.", true);
        CFHelper.FilterSingleJournalLine(CashFlowWorksheetLine, DocumentNo, SourceType, CashFlowForecast."No.");
    end;

    local procedure GetSalesActualAmount(SalesHeader: Record "Sales Header") Amount: Decimal
    var
        Currency: Record Currency;
    begin
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        if SalesHeader."Currency Code" = '' then
            Currency.InitRoundingPrecision()
        else
            Currency.Get(SalesHeader."Currency Code");

        if SalesHeader."Prices Including VAT" then begin
            SalesHeader.CalcFields("Amount Including VAT");
            Amount := SalesHeader."Amount Including VAT" - Round(SalesHeader."Amount Including VAT" * SalesHeader."Prepayment %" / 100,
                Currency."Invoice Rounding Precision", '=');
        end else
            Amount := CalculateSalesActualAmountInclPrepayment(SalesHeader, Currency."Invoice Rounding Precision");
    end;

    local procedure GetPurchaseActualAmount(PurchaseHeader: Record "Purchase Header") Amount: Decimal
    var
        Currency: Record Currency;
    begin
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        if PurchaseHeader."Currency Code" = '' then
            Currency.InitRoundingPrecision()
        else
            Currency.Get(PurchaseHeader."Currency Code");

        if PurchaseHeader."Prices Including VAT" then begin
            PurchaseHeader.CalcFields("Amount Including VAT");
            Amount :=
              PurchaseHeader."Amount Including VAT" - Round(PurchaseHeader."Amount Including VAT" * PurchaseHeader."Prepayment %" / 100,
                Currency."Invoice Rounding Precision", '=');
        end else
            Amount := CalculatePurchaseActualAmountInclPrepayment(PurchaseHeader, Currency."Invoice Rounding Precision");
    end;

    local procedure SetPrepaymentPctOnSalesHeader(var SalesHeader: Record "Sales Header"; PrepaymentPct: Decimal)
    begin
        SalesHeader.Validate("Prepayment %", PrepaymentPct);
        SalesHeader.Modify(true);
    end;

    local procedure SetPrepaymentPctOnPurchaseHeader(var PurchaseHeader: Record "Purchase Header"; PrepaymentPct: Decimal)
    begin
        PurchaseHeader.Validate("Prepayment %", PrepaymentPct);
        PurchaseHeader.Modify(true);
    end;

    local procedure SetPrepaymentPctOnPurchaseLines(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindSet();
        repeat
            PurchaseLine.Validate("Prepayment %", PurchaseHeader."Prepayment %");
            PurchaseLine.Modify(true);
        until PurchaseLine.Next() = 0;
    end;

    local procedure VerifyModifiedCustLEDatesOnCFJnl(DateField: Option; ConsiderDiscount: Boolean; ConsiderCFPmtTerms: Boolean; CFPmtTermsDateCalculationFieldNo: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
        CashFlowForecast: Record "Cash Flow Forecast";
        PaymentTerms: Record "Payment Terms";
        Customer: Record Customer;
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        RecRef: RecordRef;
        FieldRef: FieldRef;
        ExpectedDate: Date;
        CFPmtTermsDateFormula: DateFormula;
        Amount: Decimal;
        ConsiderSource: array[16] of Boolean;
    begin
        // Setup
        Initialize();
        CFHelper.CreateSpecificCashFlowCard(CashFlowForecast, ConsiderDiscount, ConsiderCFPmtTerms);
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        LibrarySales.CreateCustomer(Customer);
        CFHelper.AssignPaymentTermToCustomer(Customer, PaymentTerms.Code);
        if ConsiderCFPmtTerms then
            CFHelper.AssignCFPaymentTermToCustomer(Customer, PaymentTerms.Code);
        Amount := LibraryRandom.RandDec(100, 2);
        CFHelper.CreateLedgerEntry(
          GenJournalLine, Customer."No.", Amount, GenJournalLine."Account Type"::Customer, GenJournalLine."Document Type"::Invoice);

        // Exercise
        ExpectedDate := UpdateCustLedgerEntry(GenJournalLine."Document No.", GenJournalLine."Document Type", DateField);
        ConsiderSource["Cash Flow Source Type"::Receivables.AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify
        // The expected behavior is that the CF Journal line must reflect the modified date if CF pmt terms are not considered,
        // otherwise the CF pmt terms should be reflected
        if ConsiderCFPmtTerms then begin
            RecRef.GetTable(PaymentTerms);
            FieldRef := RecRef.Field(CFPmtTermsDateCalculationFieldNo);
            Evaluate(CFPmtTermsDateFormula, Format(FieldRef.Value));
            ExpectedDate := CalcDate(Format(FieldRef.Value), GenJournalLine."Posting Date");
        end;

        CFHelper.FilterSingleJournalLine(CFWorksheetLine, GenJournalLine."Document No.", "Cash Flow Source Type"::Receivables, CashFlowForecast."No.");
        CFHelper.VerifyCFDateOnCFJnlLine(CFWorksheetLine, ExpectedDate);
    end;

    local procedure VerifyModifiedVendLEDatesOnCFJnl(DateField: Option; ConsiderDiscount: Boolean; ConsiderCFPmtTerms: Boolean; CFPmtTermsDateCalculationFieldNo: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
        CashFlowForecast: Record "Cash Flow Forecast";
        PaymentTerms: Record "Payment Terms";
        Vendor: Record Vendor;
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        RecRef: RecordRef;
        FieldRef: FieldRef;
        ExpectedDate: Date;
        CFPmtTermsDateFormula: DateFormula;
        Amount: Decimal;
        ConsiderSource: array[16] of Boolean;
    begin
        // Setup
        Initialize();
        CFHelper.CreateSpecificCashFlowCard(CashFlowForecast, ConsiderDiscount, ConsiderCFPmtTerms);
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        LibraryPurchase.CreateVendor(Vendor);
        CFHelper.AssignPaymentTermToVendor(Vendor, PaymentTerms.Code);
        if ConsiderCFPmtTerms then
            CFHelper.AssignCFPaymentTermToVendor(Vendor, PaymentTerms.Code);
        Amount := -LibraryRandom.RandDec(100, 2);
        CFHelper.CreateLedgerEntry(
          GenJournalLine, Vendor."No.", Amount, GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::Invoice);

        // Exercise
        ExpectedDate := UpdateVendLedgerEntry(GenJournalLine."Document No.", GenJournalLine."Document Type", DateField);
        ConsiderSource["Cash Flow Source Type"::Payables.AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify
        // The expected behavior is that the CF Journal line must reflect the modified date if CF pmt terms are not considered,
        // otherwise the CF pmt terms should be reflected
        if ConsiderCFPmtTerms then begin
            RecRef.GetTable(PaymentTerms);
            FieldRef := RecRef.Field(CFPmtTermsDateCalculationFieldNo);
            Evaluate(CFPmtTermsDateFormula, Format(FieldRef.Value));
            ExpectedDate := CalcDate(Format(FieldRef.Value), GenJournalLine."Posting Date");
        end;

        CFHelper.FilterSingleJournalLine(CFWorksheetLine, GenJournalLine."Document No.", "Cash Flow Source Type"::Payables, CashFlowForecast."No.");
        CFHelper.VerifyCFDateOnCFJnlLine(CFWorksheetLine, ExpectedDate);
    end;

    local procedure VerifyDefaultDimension(DimensionValue: Record "Dimension Value"; TableID: Integer; No: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
    begin
        DefaultDimension.Get(TableID, No, DimensionValue."Dimension Code");
        DefaultDimension.TestField("Dimension Code", DimensionValue."Dimension Code");
        DefaultDimension.TestField("Dimension Value Code", DimensionValue.Code);
    end;

    local procedure UpdateCustLedgerEntry(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; DateField: Option) ExpectedDate: Date
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        case DateField of
            DateFieldOption::DueDate:
                begin
                    CFHelper.UpdateDueDateOnCustomerLedgerEntry(CustLedgerEntry);
                    ExpectedDate := CustLedgerEntry."Due Date";
                end;
            DateFieldOption::DiscountDate:
                begin
                    CFHelper.UpdatePmtDiscountDateOnCustomerLedgerEntry(CustLedgerEntry);
                    ExpectedDate := CustLedgerEntry."Pmt. Discount Date";
                end;
            else
                Error(UnsupportedDateField, DateField);
        end;
    end;

    local procedure UpdateVendLedgerEntry(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; DateField: Option) ExpectedDate: Date
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, DocumentType, DocumentNo);
        case DateField of
            DateFieldOption::DueDate:
                begin
                    CFHelper.UpdateDueDateOnVendorLedgerEntry(VendorLedgerEntry);
                    ExpectedDate := VendorLedgerEntry."Due Date";
                end;
            DateFieldOption::DiscountDate:
                begin
                    CFHelper.UpdatePmtDiscountDateOnVendorLedgerEntry(VendorLedgerEntry);
                    ExpectedDate := VendorLedgerEntry."Pmt. Discount Date";
                end;
            else
                Error(UnsupportedDateField, DateField);
        end;
    end;

    local procedure FillJournalWithoutGroupBy(ConsiderSource: array[16] of Boolean; CashFlowForecastNo: Code[20])
    begin
        CFHelper.FillJournal(ConsiderSource, CashFlowForecastNo, false);
    end;

    local procedure SetPricesInclVATOnSalesHeader(var SalesHeader: Record "Sales Header"; PricesInclVAT: Boolean)
    begin
        SalesHeader.Validate("Prices Including VAT", PricesInclVAT);
        SalesHeader.Modify(true);
    end;

    local procedure SetPricesInclVATOnPurchaseHeader(var PurchaseHeader: Record "Purchase Header"; PricesInclVAT: Boolean)
    begin
        PurchaseHeader.Validate("Prices Including VAT", PricesInclVAT);
        PurchaseHeader.Modify(true);
    end;

    local procedure GetCustomerLedgerEntryAmount(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"): Decimal
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        CustLedgerEntry.CalcFields("Amount (LCY)");
        exit(CustLedgerEntry."Amount (LCY)");
    end;

    local procedure GetVendorLedgerEntryAmount(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"): Decimal
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, DocumentType, DocumentNo);
        VendorLedgerEntry.CalcFields("Amount (LCY)");
        exit(VendorLedgerEntry."Amount (LCY)");
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure ManPmtRevExptNeedsUpdateMessageHandler(Message: Text)
    begin
        Assert.IsFalse(StrPos(Message, ManualPmtRevExpNeedsUpdateMsg) = 0, UnexpectedMessageErr);
    end;

    local procedure SetupCashFlowForJobsWithPaymentTerms(var CashFlowForecast: Record "Cash Flow Forecast"; var Job: Record Job; var JobPlanningLine: Record "Job Planning Line"; var PaymentTerms: Record "Payment Terms"; var OldDate: Date; var NewDate: Date)
    var
        Customer: Record Customer;
    begin
        // Setup - create the entities
        Initialize();
        CFHelper.CreateCashFlowForecastDefault(CashFlowForecast);
        CFHelper.CreateDefaultJob(Job);

        LibrarySales.CreateCustomer(Customer);
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, false);
        Customer.Validate("Payment Terms Code", PaymentTerms.Code);
        Customer.Modify(true);
        CFHelper.CreateDefaultJobForCustomer(Job, Customer."No.");

        SetupJobPlanningLines(Job, JobPlanningLine, OldDate, NewDate);
    end;

    local procedure SetupCashFlowForJobs(var CashFlowForecast: Record "Cash Flow Forecast"; var Job: Record Job; var JobPlanningLine: Record "Job Planning Line"; var OldDate: Date; var NewDate: Date)
    begin
        // Setup - create the entities
        Initialize();
        CFHelper.CreateCashFlowForecastDefault(CashFlowForecast);
        CFHelper.CreateDefaultJob(Job);

        SetupJobPlanningLines(Job, JobPlanningLine, OldDate, NewDate);
    end;

    local procedure SetupJobPlanningLines(Job: Record Job; var JobPlanningLine: Record "Job Planning Line"; var OldDate: Date; var NewDate: Date)
    begin
        JobPlanningLine.SetRange("Job No.", Job."No.");
        JobPlanningLine.FindFirst();
        OldDate := JobPlanningLine."Planning Date";

        // Setup - add two lines for a different date
        NewDate := CalcDate('<1D>', OldDate);
        CFHelper.CreateJobPlanningLine(Job, JobPlanningLine."Line Type"::Billable, JobPlanningLine);
        JobPlanningLine.Validate("Planning Date", NewDate);
        JobPlanningLine.Modify(true);
        CFHelper.CreateJobPlanningLine(Job, JobPlanningLine."Line Type"::"Both Budget and Billable", JobPlanningLine);
        JobPlanningLine.Validate("Planning Date", NewDate);
        JobPlanningLine.Modify(true);
    end;

    local procedure CreateFixedAssetAndPostTwoFAJournalLine(var FixedAsset: Record "Fixed Asset"; DepreciationBookCode: Code[10]; InvestmentAmount: Decimal)
    var
        FADepreciationBook: Record "FA Depreciation Book";
        FAJournalTemplate: Record "FA Journal Template";
        FAJournalBatch: Record "FA Journal Batch";
        FAJournalLine: Record "FA Journal Line";
        NoSeries: Record "No. Series";
        NoSeriesBatch: Codeunit "No. Series - Batch";
    begin
        LibraryFA.CreateFixedAsset(FixedAsset);
        FixedAsset.Validate("Budgeted Asset", true);
        FixedAsset.Modify(true);

        LibraryFA.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", DepreciationBookCode);
        FAJournalTemplate.SetRange(Recurring, false);
        LibraryFA.FindFAJournalTemplate(FAJournalTemplate);
        LibraryFA.CreateFAJournalBatch(FAJournalBatch, FAJournalTemplate.Name);
        FAJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        FAJournalBatch.Modify(true);

        LibraryFA.CreateFAJournalLine(FAJournalLine, FAJournalTemplate.Name, FAJournalBatch.Name);
        NoSeries.Get(FAJournalBatch."No. Series");
        FAJournalLine.Validate("Document No.", NoSeriesBatch.GetNextNo(FAJournalBatch."No. Series"));
        FAJournalLine.Validate("FA No.", FixedAsset."No.");
        FAJournalLine.Validate("Depreciation Book Code", FADepreciationBook."Depreciation Book Code");
        FAJournalLine.Validate(Amount, InvestmentAmount);
        FAJournalLine.Validate("FA Posting Date", CalcDate('<-2M>', WorkDate()));
        FAJournalLine.Modify(true);
        LibraryFA.PostFAJournalLine(FAJournalLine);

        LibraryFA.CreateFAJournalLine(FAJournalLine, FAJournalTemplate.Name, FAJournalBatch.Name);
        NoSeries.Get(FAJournalBatch."No. Series");
        FAJournalLine.Validate("Document No.", NoSeriesBatch.GetNextNo(FAJournalBatch."No. Series"));
        FAJournalLine.Validate("FA No.", FixedAsset."No.");
        FAJournalLine.Validate("Depreciation Book Code", FADepreciationBook."Depreciation Book Code");
        FAJournalLine.Validate(Amount, InvestmentAmount + 100);
        FAJournalLine.Validate("FA Posting Date", CalcDate('<-1M>', WorkDate()));
        FAJournalLine.Modify(true);
        LibraryFA.PostFAJournalLine(FAJournalLine);
    end;
}

