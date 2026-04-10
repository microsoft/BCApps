codeunit 134553 "ERM Cash Flow - Filling II"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Cash Flow]
        IsInitialized := false;
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryCashFlowForecast: Codeunit "Library - Cash Flow";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryCashFlowHelper: Codeunit "Library - Cash Flow Helper";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryDimension: Codeunit "Library - Dimension";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryService: Codeunit "Library - Service";
        LibraryUtility: Codeunit "Library - Utility";
        IsInitialized: Boolean;
        EmptyDateFormula: DateFormula;
        CustomDateFormula: DateFormula;
        ExpectedMessageQst: Label 'The Credit Memo doesn''t have a Corrected Invoice No. Do you want to continue?';
        UnexpectedCFWorksheetLineCountErr: Label 'ENU=Unexpected Cash Flow journal line count within filter: Cash Flow No.: %1, Document No.: %2.', Comment = '%1 - Cash Flow No.; %2 - Document No.';
        PlusOneDayFormula: DateFormula;
        MinusOneDayFormula: DateFormula;
        SourceType: Enum "Cash Flow Source Type";
        UnexpectedCFWorksheetLineCountForMultipleSourcesErr: Label 'ENU=Unexpected Cash Flow journal line count within filter: Cash Flow No.: %1, Document No.: %2, %3, %4.', Comment = 'Unexpected Cash Flow journal line count within filter: Cash Flow No.: Cash Flow No, Document No.: Sales Order No, Purchase Order No, Service Order No.';
        DescriptionTxt: Label 'Taxes from VAT Entries';
        AmountZeroErr: Label 'Amount must be zero.';
        TaxAmountErr: Label 'Tax Amount must be equal.';
        ValueMustBeEqualErr: Label '%1 must be equal to %2 in %3', Comment = '%1 = Field Caption , %2 = Expected Value , %3 = Table Caption';

    [Test]
    [Scope('OnPrem')]
    procedure CustLEPartialPayment()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        GenJournalLine: Record "Gen. Journal Line";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        Customer: Record Customer;
        TotalAmount: Decimal;
        ConsiderSource: array[16] of Boolean;
    begin
        // Test filling a CF journal by using Fill batch with single customer ledger entry
        // where only partial payment is applied
        // Verify computed cash flow date and discounted amount

        // Setup
        Initialize();
        LibraryCashFlowHelper.CreateCashFlowForecastDefault(CashFlowForecast);
        LibrarySales.CreateCustomer(Customer);
        TotalAmount := LibraryRandom.RandInt(500);
        LibraryCashFlowHelper.CreateAndApplySalesInvPayment(GenJournalLine, Customer."No.", TotalAmount, -(TotalAmount / 2),
          EmptyDateFormula, EmptyDateFormula, EmptyDateFormula);

        // Exercise
        ConsiderSource[SourceType::Receivables.AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify
        LibraryCashFlowHelper.FilterSingleJournalLine(
          CFWorksheetLine, GenJournalLine."Document No.", SourceType::Receivables, CashFlowForecast."No.");
        LibraryCashFlowHelper.VerifyExpectedCFAmount(TotalAmount - (TotalAmount / 2), CFWorksheetLine."Amount (LCY)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustLEDiscountedPmtIsOverdue()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
        CashFlowForecast: Record "Cash Flow Forecast";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Amount: Decimal;
        DiscountedAmount: Decimal;
        ConsiderSource: array[16] of Boolean;
    begin
        // Test filling a CF journal using Fill batch considering discount CF Payment Terms
        // This scenario covers a discounted payment AFTER the payment discount date,
        // therefore the expected CF amount is the remaining amount (total amount - discounted amount)
        // the CF date should be the due date

        // Setup
        Initialize();
        LibraryCashFlowHelper.SetupDsctPmtTermsCustLETest(CashFlowForecast, Customer, PaymentTerms, Amount, DiscountedAmount);
        // payment is done 1 day after discount date in order to be overdue
        CustomDateFormula := PlusOneDayFormula;
        LibraryCashFlowHelper.CreateAndApplySalesInvPayment(GenJournalLine, Customer."No.", Amount, -DiscountedAmount,
          PaymentTerms."Discount Date Calculation", EmptyDateFormula, CustomDateFormula);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document No.");

        // Exercise
        // forecast is calculated after the discount date, payment already done
        ConsiderSource[SourceType::Receivables.AsInteger()] := true;
        LibraryCashFlowHelper.FillJnlOnCertDateFormulas(ConsiderSource, CashFlowForecast."No.", PaymentTerms."Discount Date Calculation",
          EmptyDateFormula, CustomDateFormula);

        // Verify
        LibraryCashFlowHelper.VerifyCFDataOnSnglJnlLine(
          CFWorksheetLine, GenJournalLine."Document No.", SourceType::Receivables,
          CashFlowForecast."No.", Amount - DiscountedAmount,
          CalcDate(PaymentTerms."Due Date Calculation", CustLedgerEntry."Document Date"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustLEDiscountedPmtIsDue()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
        CashFlowForecast: Record "Cash Flow Forecast";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        Amount: Decimal;
        DiscountedAmount: Decimal;
        ConsiderSource: array[16] of Boolean;
    begin
        // Test filling a CF journal using Fill batch considering discount CF Payment Terms
        // This scenario covers a discounted payment from a customer w/ discount default pmt terms
        // BEFORE the payment discount date, therefore the opened entry should be closed and no CF journal line should exist

        // Setup
        Initialize();
        LibraryCashFlowHelper.SetupDsctPmtTermsCustLETest(CashFlowForecast, Customer, PaymentTerms, Amount, DiscountedAmount);
        // make sure Customer has discounted default payment terms as well, in order to close open entry
        Customer.Validate("Payment Terms Code", PaymentTerms.Code);
        Customer.Modify(true);
        // payment is done 1 day before discount date => discount allowed
        LibraryCashFlowHelper.CreateAndApplySalesInvPayment(GenJournalLine, Customer."No.", Amount, -DiscountedAmount,
          PaymentTerms."Discount Date Calculation", EmptyDateFormula, MinusOneDayFormula);

        // Exercise
        ConsiderSource[SourceType::Receivables.AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify
        // No CF lines expected
        Assert.AreEqual(0,
          LibraryCashFlowHelper.FilterSingleJournalLine(
            CFWorksheetLine, GenJournalLine."Document No.", SourceType::Receivables, CashFlowForecast."No."),
          StrSubstNo(UnexpectedCFWorksheetLineCountErr, CashFlowForecast."No.", GenJournalLine."Document No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustLEWithinDsctPmtTolNoPmt()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
        CashFlowForecast: Record "Cash Flow Forecast";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        Amount: Decimal;
        DiscountedAmount: Decimal;
        ConsiderSource: array[16] of Boolean;
    begin
        // Test filling a CF journal using Fill batch considering discount, CF pmt terms and payment discount tolerance date
        // Covers an opened customer ledger entry w/o payment where the CF forecast is done within the tolerance period
        // The expected CF amount must be the discounted total amount,
        // the CF date must be the calculated discount date + tolerance, based on the ledger entries document date

        // Setup
        Initialize();
        GeneralLedgerSetup.Get(); // keep current setup
        LibraryCashFlowHelper.CreateRandomDateFormula(CustomDateFormula); // used as pmt discount grace period
        LibraryCashFlowHelper.SetupPmtDsctTolCustLETest(
          CashFlowForecast, Customer, PaymentTerms, CustomDateFormula, Amount, DiscountedAmount);
        LibraryCashFlowHelper.CreateLedgerEntry(GenJournalLine, Customer."No.", Amount,
          GenJournalLine."Account Type"::Customer, GenJournalLine."Document Type"::Invoice);

        // Exercise
        ConsiderSource[SourceType::Receivables.AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify
        LibraryCashFlowHelper.VerifyCFDataOnSnglJnlLine(
          CFWorksheetLine, GenJournalLine."Document No.", SourceType::Receivables, CashFlowForecast."No.",
          Amount - LibraryCashFlowHelper.CalcDiscAmtFromGenJnlLine(GenJournalLine, PaymentTerms."Discount %"),
          CalcDate(CustomDateFormula,
            CalcDate(PaymentTerms."Discount Date Calculation", GenJournalLine."Document Date")));

        // Tear down
        LibraryCashFlowHelper.SetupPmtDsctGracePeriod(GeneralLedgerSetup."Payment Discount Grace Period");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustLEWithinDsctPmtTolDsctPmt()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
        CashFlowForecast: Record "Cash Flow Forecast";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        Amount: Decimal;
        DiscountedAmount: Decimal;
        PmtDiscountGracePeriod: DateFormula;
        ConsiderSource: array[16] of Boolean;
    begin
        // Test filling a CF journal using Fill batch considering discount, CF pmt terms and payment discount tolerance date
        // Covers a total discounted sales invoice payment within payment discount tolerance date.
        // The payment has to close the open invoice, therefore no CF journal lines are expected

        // Setup
        Initialize();
        GeneralLedgerSetup.Get(); // keep current setup
        LibraryCashFlowHelper.CreateRandomDateFormula(PmtDiscountGracePeriod);
        LibraryCashFlowHelper.SetupPmtDsctTolCustLETest(
          CashFlowForecast, Customer, PaymentTerms, PmtDiscountGracePeriod, Amount, DiscountedAmount);
        // make sure Customer has discounted default payment terms as well, in order to close open entry
        Customer.Validate("Payment Terms Code", PaymentTerms.Code);
        Customer.Modify(true);
        // Payment should be done before pmt dsct tol date
        Evaluate(PmtDiscountGracePeriod, '-' + Format(PmtDiscountGracePeriod));
        LibraryCashFlowHelper.CreateAndApplySalesInvPayment(GenJournalLine, Customer."No.", Amount, -DiscountedAmount,
          PaymentTerms."Discount Date Calculation", PmtDiscountGracePeriod, MinusOneDayFormula);

        // Exercise
        // forecast is done on pmt dsct tol date
        ConsiderSource[SourceType::Receivables.AsInteger()] := true;
        LibraryCashFlowHelper.FillJnlOnCertDateFormulas(ConsiderSource, CashFlowForecast."No.", PaymentTerms."Discount Date Calculation",
           PmtDiscountGracePeriod, EmptyDateFormula);

        // Verify
        // No CF lines expected
        Assert.AreEqual(
          0,
          LibraryCashFlowHelper.FilterSingleJournalLine(
            CFWorksheetLine, GenJournalLine."Document No.", SourceType::Receivables, CashFlowForecast."No."),
          StrSubstNo(UnexpectedCFWorksheetLineCountErr, CashFlowForecast."No.", GenJournalLine."Document No."));

        // Tear down
        LibraryCashFlowHelper.SetupPmtDsctGracePeriod(GeneralLedgerSetup."Payment Discount Grace Period");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustLEOutsideDsctPmtTolNoPmt()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
        CashFlowForecast: Record "Cash Flow Forecast";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        Amount: Decimal;
        DiscountedAmount: Decimal;
        PmtDiscountGracePeriod: DateFormula;
        ConsiderSource: array[16] of Boolean;
    begin
        // Test filling a CF journal using Fill batch considering discount, CF pmt terms and payment discount tolerance date
        // Covers a CF forecast ran after the pmt dsct tol date of a customer ledger entry w/o payment
        // The expected CF amount must be the total ledger entry amount w/o discount, due to an expired dsct date the expected
        // CF date must be the source due date

        // Setup
        Initialize();
        GeneralLedgerSetup.Get(); // keep current setup
        LibraryCashFlowHelper.CreateRandomDateFormula(PmtDiscountGracePeriod);
        LibraryCashFlowHelper.SetupPmtDsctTolCustLETest(
          CashFlowForecast, Customer, PaymentTerms, PmtDiscountGracePeriod, Amount, DiscountedAmount);
        LibraryCashFlowHelper.CreateLedgerEntry(GenJournalLine, Customer."No.", Amount,
          GenJournalLine."Account Type"::Customer, GenJournalLine."Document Type"::Invoice);

        // Exercise
        // forecast should be done after pmt dsct tol date
        ConsiderSource[SourceType::Receivables.AsInteger()] := true;
        LibraryCashFlowHelper.FillJnlOnCertDateFormulas(ConsiderSource, CashFlowForecast."No.", PaymentTerms."Discount Date Calculation",
          PlusOneDayFormula, PmtDiscountGracePeriod);

        // Verify
        LibraryCashFlowHelper.VerifyCFDataOnSnglJnlLine(CFWorksheetLine, GenJournalLine."Document No.", SourceType::Receivables,
          CashFlowForecast."No.", Amount, CalcDate(PaymentTerms."Due Date Calculation", GenJournalLine."Document Date"));

        // Tear down
        LibraryCashFlowHelper.SetupPmtDsctGracePeriod(GeneralLedgerSetup."Payment Discount Grace Period");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustLEOutsideDsctPmtTolPartPmt()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
        CashFlowForecast: Record "Cash Flow Forecast";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Amount: Decimal;
        DiscountedAmount: Decimal;
        PmtDiscountGracePeriod: DateFormula;
        ConsiderSource: array[16] of Boolean;
    begin
        // Test filling a CF journal using Fill batch considering discount, CF pmt terms and payment discount tolerance date
        // Covers a partial payment AFTER the payment discount tolerance date, no discount allowed, therefore the expected
        // CF amount is the remaining amount (total amount - partial payment), due to an expired Due date the expected CF date must
        // be moved to the CF execution date

        // Setup
        Initialize();
        GeneralLedgerSetup.Get(); // keep current setup
        LibraryCashFlowHelper.CreateRandomDateFormula(PmtDiscountGracePeriod);
        LibraryCashFlowHelper.SetupPmtDsctTolCustLETest(
          CashFlowForecast, Customer, PaymentTerms, PmtDiscountGracePeriod, Amount, DiscountedAmount);
        // payment should be 1 days before dsct tol date
        LibraryCashFlowHelper.CreateAndApplySalesInvPayment(GenJournalLine, Customer."No.", Amount, -Round(DiscountedAmount / 2),
          PaymentTerms."Discount Date Calculation", MinusOneDayFormula, PmtDiscountGracePeriod);
        // get invoice ledger entry
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document No.");

        // Exercise
        // forecast should be done after pmt dsct tol date
        ConsiderSource[SourceType::Receivables.AsInteger()] := true;
        LibraryCashFlowHelper.FillJnlOnCertDateFormulas(ConsiderSource, CashFlowForecast."No.", PaymentTerms."Discount Date Calculation",
          PlusOneDayFormula, PmtDiscountGracePeriod);

        // Verify
        LibraryCashFlowHelper.VerifyCFDataOnSnglJnlLine(
          CFWorksheetLine, GenJournalLine."Document No.", SourceType::Receivables, CashFlowForecast."No.",
          Amount - Round(DiscountedAmount / 2), CalcDate(PaymentTerms."Due Date Calculation", CustLedgerEntry."Document Date"));

        // Tear down
        LibraryCashFlowHelper.SetupPmtDsctGracePeriod(GeneralLedgerSetup."Payment Discount Grace Period");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustLEOutsideDsctPmtTolDsctPmt()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
        CashFlowForecast: Record "Cash Flow Forecast";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Amount: Decimal;
        DiscountedAmount: Decimal;
        PmtDiscountGracePeriod: DateFormula;
        ConsiderSource: array[16] of Boolean;
    begin
        // Test filling a CF journal using Fill batch considering discount, CF pmt terms and payment discount tolerance period
        // Covers a discounted payment AFTER the payment discount tolerance, no discount allowed,
        // therefore the expected CF amount is the remaining amount (total amount - discounted amount),
        // due to an expired Due date the expected CF date must be moved to the CF execution date

        // Setup
        Initialize();
        GeneralLedgerSetup.Get(); // keep current setup
        LibraryCashFlowHelper.CreateRandomDateFormula(PmtDiscountGracePeriod);
        LibraryCashFlowHelper.SetupPmtDsctTolCustLETest(
          CashFlowForecast, Customer, PaymentTerms, PmtDiscountGracePeriod, Amount, DiscountedAmount);
        // discounted payment should be done after pmt disc tol date
        CustomDateFormula := PlusOneDayFormula;
        LibraryCashFlowHelper.CreateAndApplySalesInvPayment(GenJournalLine, Customer."No.", Amount, -DiscountedAmount,
          PaymentTerms."Discount Date Calculation", CustomDateFormula, PmtDiscountGracePeriod);
        // get invoice ledger entry
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document No.");

        // Exercise
        // forecast should be done after payment
        Evaluate(CustomDateFormula, Format(CustomDateFormula) + Format(PlusOneDayFormula));
        ConsiderSource[SourceType::Receivables.AsInteger()] := true;
        LibraryCashFlowHelper.FillJnlOnCertDateFormulas(ConsiderSource, CashFlowForecast."No.", PaymentTerms."Discount Date Calculation",
          CustomDateFormula, PmtDiscountGracePeriod);

        // Verify
        LibraryCashFlowHelper.VerifyCFDataOnSnglJnlLine(CFWorksheetLine, GenJournalLine."Document No.", SourceType::Receivables,
          CashFlowForecast."No.", Amount - DiscountedAmount,
          CalcDate(PaymentTerms."Due Date Calculation", CustLedgerEntry."Document Date"));

        // Tear down
        LibraryCashFlowHelper.SetupPmtDsctGracePeriod(GeneralLedgerSetup."Payment Discount Grace Period");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustLEPmtAmtWithinPmtTolAmt()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        Customer: Record Customer;
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalLine: Record "Gen. Journal Line";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        Amount: Decimal;
        ConsiderSource: array[16] of Boolean;
    begin
        // Test filling a CF journal using Fill batch considering Pmt. Tol. Amount
        // The payment amount for the invoice should be within the tolerance amount, which leads to a closed
        // ledger entry and therefore there must not be a CF forecast consideration

        // Setup
        Initialize();
        GeneralLedgerSetup.Get(); // keep current setup
        // max pmt tol amount should be 50% of the invoice amount
        LibraryCashFlowHelper.SetupCustomerPmtTolAmtTestCase(CashFlowForecast, Customer, Amount, 0.5, 50);
        LibraryCashFlowHelper.CreateAndApplySalesInvPayment(GenJournalLine, Customer."No.", Amount,
          -(Amount - Round(Amount * 0.5)), EmptyDateFormula, EmptyDateFormula, EmptyDateFormula);

        // Exercise
        ConsiderSource[SourceType::Receivables.AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify
        // No CF lines expected
        Assert.AreEqual(0,
          LibraryCashFlowHelper.FilterSingleJournalLine(
            CFWorksheetLine, GenJournalLine."Document No.", SourceType::Receivables, CashFlowForecast."No."),
          StrSubstNo(UnexpectedCFWorksheetLineCountErr, CashFlowForecast."No.", GenJournalLine."Document No."));

        // Tear down
        LibraryCashFlowHelper.SetupPmtTolPercentage(GeneralLedgerSetup."Payment Tolerance %");
        LibraryCashFlowHelper.SetupPmtTolAmount(GeneralLedgerSetup."Max. Payment Tolerance Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustLEPmtAmtOutsidePmtTolAmt()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        Customer: Record Customer;
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalLine: Record "Gen. Journal Line";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        Amount: Decimal;
        ExpectedAmount: Decimal;
        PaymentAmount: Decimal;
        ConsiderSource: array[16] of Boolean;
    begin
        // Test filling a CF journal using Fill batch considering Pmt. Tol. Amount
        // The payment amount for the invoice should be less than the tolerance deducted amount, which keeps
        // ledger entry open and therefore the difference between payment amount and tolerance deducted amount must be forecasted

        // Setup
        Initialize();
        GeneralLedgerSetup.Get(); // keep current setup
        // max pmt tol amount should be 30% of the invoice amount
        LibraryCashFlowHelper.SetupCustomerPmtTolAmtTestCase(CashFlowForecast, Customer, Amount, 0.3, 30);
        ExpectedAmount := Amount - Round(Amount * 0.3);
        PaymentAmount := Amount / 2; // less then the invoice amount but more than the pmt tol amount
        LibraryCashFlowHelper.CreateAndApplySalesInvPayment(GenJournalLine, Customer."No.", Amount, -PaymentAmount,
          EmptyDateFormula, EmptyDateFormula, EmptyDateFormula);

        // Exercise
        ConsiderSource[SourceType::Receivables.AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify
        LibraryCashFlowHelper.FilterSingleJournalLine(
          CFWorksheetLine, GenJournalLine."Document No.", SourceType::Receivables, CashFlowForecast."No.");
        LibraryCashFlowHelper.VerifyExpectedCFAmount(ExpectedAmount - PaymentAmount, CFWorksheetLine."Amount (LCY)");

        // Tear down
        LibraryCashFlowHelper.SetupPmtTolPercentage(GeneralLedgerSetup."Payment Tolerance %");
        LibraryCashFlowHelper.SetupPmtTolAmount(GeneralLedgerSetup."Max. Payment Tolerance Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorLEWithinDsctPmtTolNoPmt()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        PaymentTerms: Record "Payment Terms";
        CashFlowForecast: Record "Cash Flow Forecast";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        Amount: Decimal;
        DiscountedAmount: Decimal;
        PmtDiscountGracePeriod: DateFormula;
        ConsiderSource: array[16] of Boolean;
    begin
        // Test filling a CF journal using Fill batch considering discount, CF pmt terms and payment discount tolerance date
        // Covers an opened vendor ledger entry w/o payment where the CF forecast is done within the discount period
        // The expected CF amount must be the discounted total amount,
        // the CF date must be the calculated discount date + tolerance, based on the ledger entries document date

        // Setup
        Initialize();
        GeneralLedgerSetup.Get(); // keep current setup
        LibraryCashFlowHelper.CreateRandomDateFormula(PmtDiscountGracePeriod);
        LibraryCashFlowHelper.SetupPmtDsctTolVendorLETest(
          CashFlowForecast, Vendor, PaymentTerms, PmtDiscountGracePeriod, Amount, DiscountedAmount);
        LibraryCashFlowHelper.CreateLedgerEntry(GenJournalLine, Vendor."No.", -Amount,
          GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::Invoice);

        // Exercise
        ConsiderSource[SourceType::Payables.AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify
        LibraryCashFlowHelper.VerifyCFDataOnSnglJnlLine(
          CFWorksheetLine, GenJournalLine."Document No.", SourceType::Payables, CashFlowForecast."No.",
          -(Amount - LibraryCashFlowHelper.CalcDiscAmtFromGenJnlLine(GenJournalLine, PaymentTerms."Discount %")),
          CalcDate(PmtDiscountGracePeriod,
            CalcDate(PaymentTerms."Discount Date Calculation", GenJournalLine."Document Date")));

        // Tear down
        LibraryCashFlowHelper.SetupPmtDsctGracePeriod(GeneralLedgerSetup."Payment Discount Grace Period");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendLEWithinDsctPmtTolDsctPmt()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        PaymentTerms: Record "Payment Terms";
        CashFlowForecast: Record "Cash Flow Forecast";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        Amount: Decimal;
        DiscountedAmount: Decimal;
        PmtDiscountGracePeriod: DateFormula;
        ConsiderSource: array[16] of Boolean;
    begin
        // Test filling a CF journal using Fill batch considering discount, CF pmt terms and payment discount tolerance date
        // Covers a total discounted sales invoice payment within payment discount tolerance date.
        // The payment has to close the open invoice, therefore no CF journal lines are expected

        // Setup
        Initialize();
        GeneralLedgerSetup.Get(); // keep current setup
        LibraryCashFlowHelper.CreateRandomDateFormula(PmtDiscountGracePeriod);
        LibraryCashFlowHelper.SetupPmtDsctTolVendorLETest(
          CashFlowForecast, Vendor, PaymentTerms, PmtDiscountGracePeriod, Amount, DiscountedAmount);
        // make sure Vendor has discounted default payment terms as well, in order to close open entry
        Vendor.Validate("Payment Terms Code", PaymentTerms.Code);
        Vendor.Modify(true);
        // Payment should be done before pmt dsct tol date
        Evaluate(PmtDiscountGracePeriod, '-' + Format(PmtDiscountGracePeriod));
        LibraryCashFlowHelper.CreateAndApplyVendorInvPmt(GenJournalLine, Vendor."No.", -Amount, DiscountedAmount,
          PaymentTerms."Discount Date Calculation", PmtDiscountGracePeriod, MinusOneDayFormula);

        // Exercise
        // Forecast should be done after payment
        ConsiderSource[SourceType::Payables.AsInteger()] := true;
        LibraryCashFlowHelper.FillJnlOnCertDateFormulas(ConsiderSource, CashFlowForecast."No.", PaymentTerms."Discount Date Calculation",
          PmtDiscountGracePeriod, EmptyDateFormula);

        // Verify
        // No CF lines expected
        Assert.AreEqual(0,
          LibraryCashFlowHelper.FilterSingleJournalLine(
            CFWorksheetLine, GenJournalLine."Document No.", SourceType::Payables, CashFlowForecast."No."),
          StrSubstNo(UnexpectedCFWorksheetLineCountErr, CashFlowForecast."No.", GenJournalLine."Document No."));

        // Tear down
        LibraryCashFlowHelper.SetupPmtDsctGracePeriod(GeneralLedgerSetup."Payment Discount Grace Period");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendLEOutsideDsctPmtTolNoPmt()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        PaymentTerms: Record "Payment Terms";
        CashFlowForecast: Record "Cash Flow Forecast";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        Amount: Decimal;
        DiscountedAmount: Decimal;
        PmtDiscountGracePeriod: DateFormula;
        ConsiderSource: array[16] of Boolean;
    begin
        // Test filling a CF journal using Fill batch considering discount, CF pmt terms and payment discount tolerance date
        // Covers a partial purchase invoice payment within payment discount tolerance date.

        // Setup
        Initialize();
        GeneralLedgerSetup.Get(); // keep current setup
        LibraryCashFlowHelper.CreateRandomDateFormula(PmtDiscountGracePeriod);
        LibraryCashFlowHelper.SetupPmtDsctTolVendorLETest(
          CashFlowForecast, Vendor, PaymentTerms, PmtDiscountGracePeriod, Amount, DiscountedAmount);
        LibraryCashFlowHelper.CreateLedgerEntry(GenJournalLine, Vendor."No.", -Amount,
          GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::Invoice);

        // Exercise
        // forecast should be done after pmt dsct tol date
        ConsiderSource[SourceType::Payables.AsInteger()] := true;
        LibraryCashFlowHelper.FillJnlOnCertDateFormulas(ConsiderSource, CashFlowForecast."No.", PaymentTerms."Discount Date Calculation",
          PlusOneDayFormula, PmtDiscountGracePeriod);

        // Verify
        LibraryCashFlowHelper.VerifyCFDataOnSnglJnlLine(
          CFWorksheetLine, GenJournalLine."Document No.", SourceType::Payables, CashFlowForecast."No.",
          -Amount, CalcDate(PaymentTerms."Due Date Calculation", GenJournalLine."Document Date"));

        // Tear down
        LibraryCashFlowHelper.SetupPmtDsctGracePeriod(GeneralLedgerSetup."Payment Discount Grace Period");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendLEOutsideDsctPmtTolDsctPmt()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        PaymentTerms: Record "Payment Terms";
        CashFlowForecast: Record "Cash Flow Forecast";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Amount: Decimal;
        DiscountedAmount: Decimal;
        PmtDiscountGracePeriod: DateFormula;
        ConsiderSource: array[16] of Boolean;
    begin
        // Test filling a CF journal using Fill batch considering discount, CF pmt terms and payment discount tolerance date
        // Covers a discounted purchase invoice payment outside payment discount tolerance date.

        // Setup
        Initialize();
        GeneralLedgerSetup.Get(); // keep current setup
        LibraryCashFlowHelper.CreateRandomDateFormula(PmtDiscountGracePeriod);
        LibraryCashFlowHelper.SetupPmtDsctTolVendorLETest(
          CashFlowForecast, Vendor, PaymentTerms, PmtDiscountGracePeriod, Amount, DiscountedAmount);
        // discounted payment should be done after pmt disc tol date
        CustomDateFormula := PlusOneDayFormula;
        LibraryCashFlowHelper.CreateAndApplyVendorInvPmt(GenJournalLine, Vendor."No.", -Amount, DiscountedAmount,
          PaymentTerms."Discount Date Calculation", CustomDateFormula, PmtDiscountGracePeriod);
        // get invoice ledger entry
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document No.");

        // Exercise
        // forecast should be done after pmt dsct tol date and payment
        Evaluate(CustomDateFormula, Format(CustomDateFormula) + Format(PlusOneDayFormula));
        ConsiderSource[SourceType::Payables.AsInteger()] := true;
        LibraryCashFlowHelper.FillJnlOnCertDateFormulas(ConsiderSource, CashFlowForecast."No.", PaymentTerms."Discount Date Calculation",
          CustomDateFormula, PmtDiscountGracePeriod);

        // Verify
        LibraryCashFlowHelper.VerifyCFDataOnSnglJnlLine(
          CFWorksheetLine, GenJournalLine."Document No.", SourceType::Payables, CashFlowForecast."No.",
          -(Amount - DiscountedAmount), CalcDate(PaymentTerms."Due Date Calculation", VendorLedgerEntry."Document Date"));

        // Tear down
        LibraryCashFlowHelper.SetupPmtDsctGracePeriod(GeneralLedgerSetup."Payment Discount Grace Period");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendLEPmtAmtWithinPmtTolAmt()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        Vendor: Record Vendor;
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalLine: Record "Gen. Journal Line";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        Amount: Decimal;
        ConsiderSource: array[16] of Boolean;
    begin
        // Test filling a CF journal using Fill batch considering Pmt. Tol. Amount
        // The payment amount for the invoice should be within the tolerance amount, which leads to a closed
        // ledger entry and therefore there must not be a CF forecast consideration

        // Setup
        Initialize();
        GeneralLedgerSetup.Get(); // keep current setup
        // max pmt tol amount should be 50% of the invoice amount
        LibraryCashFlowForecast.ClearJournal();
        LibraryCashFlowHelper.SetupVendorPmtTolAmtTestCase(CashFlowForecast, Vendor, Amount, 0.5, 50);
        LibraryCashFlowHelper.CreateAndApplyVendorInvPmt(GenJournalLine, Vendor."No.", -Amount,
          Amount - Round(Amount * 0.5 / 100), EmptyDateFormula, EmptyDateFormula, EmptyDateFormula);

        // Exercise
        ConsiderSource[SourceType::Payables.AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify
        // No CF lines expected
        Assert.AreEqual(
          0,
          LibraryCashFlowHelper.FilterSingleJournalLine(
            CFWorksheetLine, GenJournalLine."Document No.", SourceType::Payables, CashFlowForecast."No."),
          StrSubstNo(UnexpectedCFWorksheetLineCountErr, CashFlowForecast."No.", GenJournalLine."Document No."));

        // Tear down
        LibraryCashFlowHelper.SetupPmtTolPercentage(GeneralLedgerSetup."Payment Tolerance %");
        LibraryCashFlowHelper.SetupPmtTolAmount(GeneralLedgerSetup."Max. Payment Tolerance Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendLEPmtAmtOutsidePmtTolAmt()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        Vendor: Record Vendor;
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalLine: Record "Gen. Journal Line";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        Amount: Decimal;
        ExpectedAmount: Decimal;
        PaymentAmount: Decimal;
        ConsiderSource: array[16] of Boolean;
    begin
        // Test filling a CF journal using Fill batch considering Pmt. Tol. Amount
        // The payment amount for the invoice should be less than the tolerance deducted amount, which keeps
        // ledger entry open and therefore the difference between payment amount and tolerance deducted amount must be forecasted

        // Setup
        Initialize();
        GeneralLedgerSetup.Get(); // keep current state
        // max pmt tol amount should be 30% of the invoice amount
        LibraryCashFlowHelper.SetupVendorPmtTolAmtTestCase(CashFlowForecast, Vendor, Amount, 0.3, 0);
        ExpectedAmount := Amount - Round(Amount * 0.3);
        PaymentAmount := Amount / 2; // less then the invoice amount but more than the pmt tol amount
        LibraryCashFlowHelper.CreateAndApplyVendorInvPmt(GenJournalLine, Vendor."No.", -Amount, PaymentAmount,
          EmptyDateFormula, EmptyDateFormula, EmptyDateFormula);

        // Exercise
        ConsiderSource[SourceType::Payables.AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify
        LibraryCashFlowHelper.FilterSingleJournalLine(
          CFWorksheetLine, GenJournalLine."Document No.", SourceType::Payables, CashFlowForecast."No.");
        LibraryCashFlowHelper.VerifyExpectedCFAmount(-(ExpectedAmount - PaymentAmount), CFWorksheetLine."Amount (LCY)");

        // Tear down
        LibraryCashFlowHelper.SetupPmtTolPercentage(GeneralLedgerSetup."Payment Tolerance %");
        LibraryCashFlowHelper.SetupPmtTolAmount(GeneralLedgerSetup."Max. Payment Tolerance Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SOWithPendPrepmtAndCFPmtTerms()
    var
        PaymentTerms: Record "Payment Terms";
        CashFlowForecast: Record "Cash Flow Forecast";
        SalesHeader: Record "Sales Header";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ExpectedSOAmount: Decimal;
        ExpectedPrePmtAmount: Decimal;
        PrePmtInvNo: Code[20];
        ConsiderSource: array[16] of Boolean;
    begin
        // Test filling a CF journal using Fill Batch where only CF payment terms are considered,
        // with a sales order which requires prepayment. The prepayment invoice has been posted and the prepayment is pending.

        // Setup
        Initialize();
        LibraryCashFlowHelper.CreateCashFlowForecastConsiderCFPmtTerms(CashFlowForecast);
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        LibraryCashFlowHelper.CreatePrepmtSalesOrder(SalesHeader, '', PaymentTerms.Code);
        PrePmtInvNo := LibraryCashFlowHelper.AddAndPostSOPrepaymentInvoice(SalesHeader, LibraryRandom.RandInt(10));
        SalesInvoiceHeader.Get(PrePmtInvNo);
        LibraryCashFlowHelper.CalcSalesExpectedPrepmtAmounts(SalesHeader, 0, ExpectedSOAmount, ExpectedPrePmtAmount);

        // Exercise
        ConsiderSource[SourceType::Receivables.AsInteger()] := true;
        ConsiderSource[SourceType::"Sales Orders".AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify
        // Discount is not considered - due date is the indicator
        LibraryCashFlowHelper.VerifyCFDataOnSnglJnlLine(
          CFWorksheetLine, SalesHeader."No.", SourceType::"Sales Orders", CashFlowForecast."No.",
          ExpectedSOAmount, CalcDate(PaymentTerms."Due Date Calculation", SalesHeader."Document Date"));
        LibraryCashFlowHelper.VerifyCFDataOnSnglJnlLine(CFWorksheetLine, PrePmtInvNo, SourceType::Receivables, CashFlowForecast."No.",
          ExpectedPrePmtAmount, CalcDate(PaymentTerms."Due Date Calculation", SalesInvoiceHeader."Posting Date"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SOWithPendPrepmtAndDsct()
    var
        PaymentTerms: Record "Payment Terms";
        CashFlowForecast: Record "Cash Flow Forecast";
        SalesHeader: Record "Sales Header";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ExpectedSOAmount: Decimal;
        ExpectedPrePmtAmount: Decimal;
        PrePmtInvNo: Code[20];
        ConsiderSource: array[16] of Boolean;
    begin
        // Test filling a CF journal using Fill Batch where only discount is considered,
        // with a sales order which requires prepayment. The prepayment invoice has been posted and the prepayment is pending.

        // Setup
        Initialize();
        LibraryCashFlowHelper.CreateCashFlowForecastConsiderDiscount(CashFlowForecast);
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        LibraryCashFlowHelper.CreatePrepmtSalesOrder(SalesHeader, PaymentTerms.Code, '');
        PrePmtInvNo := LibraryCashFlowHelper.AddAndPostSOPrepaymentInvoice(SalesHeader, LibraryRandom.RandInt(10));
        SalesInvoiceHeader.Get(PrePmtInvNo);
        LibraryCashFlowHelper.CalcSalesExpectedPrepmtAmounts(
          SalesHeader, PaymentTerms."Discount %", ExpectedSOAmount, ExpectedPrePmtAmount);

        // Exercise
        ConsiderSource[SourceType::Receivables.AsInteger()] := true;
        ConsiderSource[SourceType::"Sales Orders".AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify
        LibraryCashFlowHelper.VerifyCFDataOnSnglJnlLine(CFWorksheetLine, SalesHeader."No.", SourceType::"Sales Orders",
          CashFlowForecast."No.", ExpectedSOAmount, SalesHeader."Pmt. Discount Date");
        LibraryCashFlowHelper.VerifyCFDataOnSnglJnlLine(CFWorksheetLine, PrePmtInvNo, SourceType::Receivables, CashFlowForecast."No.",
          ExpectedPrePmtAmount, CalcDate(PaymentTerms."Discount Date Calculation", SalesInvoiceHeader."Posting Date"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SOWithPendPrepmtDsctAndCFTerms()
    var
        PaymentTerms: Record "Payment Terms";
        PaymentTerms2: Record "Payment Terms";
        CashFlowForecast: Record "Cash Flow Forecast";
        SalesHeader: Record "Sales Header";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ExpectedSOAmount: Decimal;
        ExpectedPrePmtAmount: Decimal;
        PrePmtInvNo: Code[20];
        ConsiderSource: array[16] of Boolean;
    begin
        // Test filling a CF journal using Fill Batch where discount and CF Pmt Terms are considered,
        // with a sales order which requires prepayment. The prepayment invoice has been posted and the prepayment is pending.

        // Setup
        Initialize();
        LibraryCashFlowHelper.CreateCashFlowForecastConsiderDiscountAndCFPmtTerms(CashFlowForecast);
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        LibraryCashFlowHelper.GetDifferentDsctPaymentTerms(PaymentTerms2, PaymentTerms.Code);
        LibraryCashFlowHelper.CreatePrepmtSalesOrder(SalesHeader, PaymentTerms.Code, PaymentTerms2.Code);
        PrePmtInvNo := LibraryCashFlowHelper.AddAndPostSOPrepaymentInvoice(SalesHeader, LibraryRandom.RandInt(10));
        SalesInvoiceHeader.Get(PrePmtInvNo);
        LibraryCashFlowHelper.CalcSalesExpectedPrepmtAmounts(
          SalesHeader, PaymentTerms2."Discount %", ExpectedSOAmount, ExpectedPrePmtAmount);

        // Exercise
        ConsiderSource[SourceType::Receivables.AsInteger()] := true;
        ConsiderSource[SourceType::"Sales Orders".AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify
        LibraryCashFlowHelper.VerifyCFDataOnSnglJnlLine(
          CFWorksheetLine, SalesHeader."No.", SourceType::"Sales Orders", CashFlowForecast."No.",
          ExpectedSOAmount, CalcDate(PaymentTerms2."Discount Date Calculation", SalesHeader."Document Date"));
        LibraryCashFlowHelper.VerifyCFDataOnSnglJnlLine(CFWorksheetLine, PrePmtInvNo, SourceType::Receivables, CashFlowForecast."No.",
          ExpectedPrePmtAmount, CalcDate(PaymentTerms2."Discount Date Calculation", SalesInvoiceHeader."Posting Date"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure POWithPendPrepmtAndCFPmtTerms()
    var
        PaymentTerms: Record "Payment Terms";
        CashFlowForecast: Record "Cash Flow Forecast";
        PurchaseHeader: Record "Purchase Header";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        ExpectedPOAmount: Decimal;
        ExpectedPrePmtAmount: Decimal;
        PrePmtInvNo: Code[20];
        ConsiderSource: array[16] of Boolean;
    begin
        // Test filling a CF journal using Fill Batch where only CF payment terms are considered,
        // with a purchase order which requires prepayment. The prepayment invoice has been posted and the prepayment is pending.

        // Setup
        Initialize();
        LibraryCashFlowHelper.CreateCashFlowForecastConsiderCFPmtTerms(CashFlowForecast);
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        LibraryCashFlowHelper.CreatePrepmtPurchaseOrder(PurchaseHeader, '', PaymentTerms.Code);
        PrePmtInvNo := LibraryCashFlowHelper.AddAndPostPOPrepaymentInvoice(PurchaseHeader, LibraryRandom.RandInt(10));
        PurchInvHeader.Get(PrePmtInvNo);
        LibraryCashFlowHelper.CalcPurchExpectedPrepmtAmounts(PurchaseHeader, 0, ExpectedPOAmount, ExpectedPrePmtAmount);
        LibraryApplicationArea.EnableFoundationSetup();

        // Exercise
        ConsiderSource[SourceType::Payables.AsInteger()] := true;
        ConsiderSource[SourceType::"Purchase Orders".AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify
        // Discount is not considered on CF card - due date is the indicator
        LibraryCashFlowHelper.VerifyCFDataOnSnglJnlLine(
          CFWorksheetLine, PurchaseHeader."No.", SourceType::"Purchase Orders", CashFlowForecast."No.",
          -ExpectedPOAmount, CalcDate(PaymentTerms."Due Date Calculation", PurchaseHeader."Document Date"));
        LibraryCashFlowHelper.VerifyCFDataOnSnglJnlLine(CFWorksheetLine, PrePmtInvNo, SourceType::Payables, CashFlowForecast."No.",
          -ExpectedPrePmtAmount, CalcDate(PaymentTerms."Due Date Calculation", PurchInvHeader."Posting Date"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure POWithPendPrepmtAndDsct()
    var
        PaymentTerms: Record "Payment Terms";
        CashFlowForecast: Record "Cash Flow Forecast";
        PurchaseHeader: Record "Purchase Header";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        ExpectedPOAmount: Decimal;
        ExpectedPrePmtAmount: Decimal;
        PrePmtInvNo: Code[20];
        ConsiderSource: array[16] of Boolean;
    begin
        // Test filling a CF journal using Fill Batch where only discount is considered,
        // with a Purchase order which requires prepayment. The prepayment invoice has been posted and the prepayment is pending.

        // Setup
        Initialize();
        LibraryCashFlowHelper.CreateCashFlowForecastConsiderDiscount(CashFlowForecast);
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        LibraryCashFlowHelper.CreatePrepmtPurchaseOrder(PurchaseHeader, PaymentTerms.Code, '');
        PrePmtInvNo := LibraryCashFlowHelper.AddAndPostPOPrepaymentInvoice(PurchaseHeader, LibraryRandom.RandInt(10));
        PurchInvHeader.Get(PrePmtInvNo);
        LibraryCashFlowHelper.CalcPurchExpectedPrepmtAmounts(
          PurchaseHeader, PaymentTerms."Discount %", ExpectedPOAmount, ExpectedPrePmtAmount);
        LibraryApplicationArea.EnableFoundationSetup();

        // Exercise
        ConsiderSource[SourceType::Payables.AsInteger()] := true;
        ConsiderSource[SourceType::"Purchase Orders".AsInteger()] := true;
        LibraryCashFlowHelper.FillJournal(ConsiderSource, CashFlowForecast."No.", true);

        // Verify
        LibraryCashFlowHelper.VerifyCFDataOnSnglJnlLine(CFWorksheetLine, PurchaseHeader."No.", SourceType::"Purchase Orders",
          CashFlowForecast."No.", -ExpectedPOAmount, PurchaseHeader."Pmt. Discount Date");

        LibraryCashFlowHelper.VerifyCFDataOnSnglJnlLine(CFWorksheetLine, PrePmtInvNo, SourceType::Payables, CashFlowForecast."No.",
          -ExpectedPrePmtAmount, CalcDate(PaymentTerms."Discount Date Calculation", PurchInvHeader."Posting Date"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure POWithPendPrepmtDsctAndCFTerms()
    var
        PaymentTerms: Record "Payment Terms";
        PaymentTerms2: Record "Payment Terms";
        CashFlowForecast: Record "Cash Flow Forecast";
        PurchaseHeader: Record "Purchase Header";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        ExpectedPOAmount: Decimal;
        ExpectedPrePmtAmount: Decimal;
        PrePmtInvNo: Code[20];
        ConsiderSource: array[16] of Boolean;
    begin
        // Test filling a CF journal using Fill Batch where discount and CF Pmt Terms are considered,
        // with a Purchase order which requires prepayment. The prepayment invoice has been posted and the prepayment is pending.

        // Setup
        Initialize();
        LibraryCashFlowHelper.CreateCashFlowForecastConsiderDiscountAndCFPmtTerms(CashFlowForecast);
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        LibraryCashFlowHelper.GetDifferentDsctPaymentTerms(PaymentTerms2, PaymentTerms.Code);
        LibraryCashFlowHelper.CreatePrepmtPurchaseOrder(PurchaseHeader, PaymentTerms.Code, PaymentTerms2.Code);
        PrePmtInvNo := LibraryCashFlowHelper.AddAndPostPOPrepaymentInvoice(PurchaseHeader, LibraryRandom.RandInt(10));
        PurchInvHeader.Get(PrePmtInvNo);
        LibraryCashFlowHelper.CalcPurchExpectedPrepmtAmounts(
          PurchaseHeader, PaymentTerms2."Discount %", ExpectedPOAmount, ExpectedPrePmtAmount);
        LibraryApplicationArea.EnableFoundationSetup();

        // Exercise
        ConsiderSource[SourceType::Payables.AsInteger()] := true;
        ConsiderSource[SourceType::"Purchase Orders".AsInteger()] := true;
        LibraryCashFlowHelper.FillJournal(ConsiderSource, CashFlowForecast."No.", true);

        // Verify
        LibraryCashFlowHelper.VerifyCFDataOnSnglJnlLine(
          CFWorksheetLine, PurchaseHeader."No.", SourceType::"Purchase Orders", CashFlowForecast."No.",
          -ExpectedPOAmount, CalcDate(PaymentTerms2."Discount Date Calculation", PurchaseHeader."Document Date"));
        LibraryCashFlowHelper.VerifyCFDataOnSnglJnlLine(CFWorksheetLine, PrePmtInvNo, SourceType::Payables, CashFlowForecast."No.",
          -ExpectedPrePmtAmount, CalcDate(PaymentTerms2."Discount Date Calculation", PurchInvHeader."Posting Date"));
    end;

    [Test]
    [HandlerFunctions('AccountScheduleOverviewPageHandler,SuggestWorksheetLinesReqPageHandler')]
    [Scope('OnPrem')]
    procedure CashFlowWithAccountSchedule()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        AccScheduleName: Record "Acc. Schedule Name";
        ColumnLayout: Record "Column Layout";
        CashFlowAccount: Record "Cash Flow Account";
        AccScheduleLine: Record "Acc. Schedule Line";
        RowNo: Integer;
    begin
        // Verify Cash Flow Forcast show in Account Schedule with Cashflow Layout.

        // Setup: Create Cash Flow Forecast, suggest Cash Flow Worksheet Line and Register.
        Initialize();
        CreateAndPostCashFlowForecast(CashFlowForecast);
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        CreateColumnLayout(ColumnLayout);
        LibraryVariableStorage.Enqueue(ColumnLayout."Column Layout Name");  // Enqueue AccountScheduleOverviewPageHandler.
        LibraryVariableStorage.Enqueue(CashFlowForecast."No.");  // Enqueue AccountScheduleOverviewPageHandler.
        RowNo := LibraryRandom.RandInt(10);  // Using Random value for Account Schedule Row No.
        CashFlowAccount.SetRange("Account Type", CashFlowAccount."Account Type"::Entry);
        CashFlowAccount.FindSet();
        repeat
            RowNo += 1;
            CreateAccountScheduleAndLine(AccScheduleLine, CashFlowAccount."No.", Format(RowNo), AccScheduleName.Name);
        until CashFlowAccount.Next() = 0;

        // Exercise.
        OpenAccountScheduleOverviewPage(AccScheduleLine."Schedule Name");

        // Verify: Cash Flow Forcast show in Account Schedule with Cashflow Layout, done by .
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,AnalysisByDimensionsHandler,AnalysisByDimensionsMatrixHandler,SuggestWorksheetLinesReqPageHandler')]
    [Scope('OnPrem')]
    procedure CashFlowWithAnalysisByDimension()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        AnalysisView: Record "Analysis View";
    begin
        // Verify Cash Flow Forcast show in Analysis by Dimesnion with view by Month.

        // Setup: Create Cash Flow Forecast, suggest Cash Flow Worksheet Line and Register, find Cash Flow Analysis by Dimension and Update.
        Initialize();
        CreateAndPostCashFlowForecast(CashFlowForecast);
        ExecuteUIHandler();
        LibraryCashFlowForecast.FindCashFlowAnalysisView(AnalysisView);
        LibraryVariableStorage.Enqueue(CashFlowForecast."No.");  // Enqueue AnalysisByDimensionsHandler.

        // Exercise.
        UpdateAnalysisViewList(AnalysisView.Code);

        // Verify: Verify Cash Flow Forcast show in Analysis by Dimesnion with view by Month, done by AnalysisByDimensionsMatrixHandler.
    end;

    [Test]
    [HandlerFunctions('SuggestWorksheetLinesReqLiquidFundsPageHandler')]
    [Scope('OnPrem')]
    procedure CatchCircularReferencesInCashFlowAccountTotals()
    var
        CashFlowAccount: Record "Cash Flow Account";
        CashFlowForecast: Record "Cash Flow Forecast";
        GLAccount: array[3] of Record "G/L Account";
    begin
        // [SCENARIO 416767] "Suggest Cashflow Worksheet Lines" catches circular references.
        Initialize();

        // [GIVEN] Three Total G/L Accounts:
        // [GIVEN] G/L Account 100, where Totaling 101..150
        GLAccount[1]."No." := 'LF100';
        GLAccount[1].Totaling := 'LF101..LF150';
        GLAccount[1]."Account Type" := GLAccount[1]."Account Type"::Total;
        GLAccount[1].Insert();
        // [GIVEN] G/L Account 150, where Totaling 151..199
        GLAccount[2]."No." := 'LF150';
        GLAccount[2].Totaling := 'LF151..LF199';
        GLAccount[2]."Account Type" := GLAccount[2]."Account Type"::Total;
        GLAccount[2].Insert();
        // [GIVEN] G/L Account 199, where Totaling 100..110
        GLAccount[3]."No." := 'LF199';
        GLAccount[3].Totaling := 'LF100..LF110';
        GLAccount[3]."Account Type" := GLAccount[3]."Account Type"::Total;
        GLAccount[3].Insert();
        // [GIVEN] Cash Flow Account 'LF', where "G/L Account Filter" is 199
        CashFlowAccount.Init();
        CashFlowAccount."No." := 'LF';
        CashFlowAccount."Account Type" := CashFlowAccount."Account Type"::Entry;
        CashFlowAccount."Source Type" := CashFlowAccount."Source Type"::"Liquid Funds";
        CashFlowAccount."G/L Integration" := CashFlowAccount."G/L Integration"::Balance;
        CashFlowAccount."G/L Account Filter" := 'LF199';
        CashFlowAccount.Insert();

        // [WHEN] Create Cash Flow Forecast, suggest Cash Flow Worksheet Line 
        asserterror CreateAndPostCashFlowForecast(CashFlowForecast);

        // [THEN] Error message:"There are one or more circular references ..."
        Assert.ExpectedError(
            StrSubstNo('%3, (%1, %2, %3) ', GLAccount[1]."No.", GLAccount[2]."No.", GLAccount[3]."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ForecastingFCYAmountConsideringDiscountOnCustLE()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
    begin
        // Setup
        Initialize();
        LibraryCashFlowHelper.CreateCashFlowForecastConsiderDiscount(CashFlowForecast);

        // Exercise & Verify
        ForecastingFCYAmountsOnReceivablesWithCFCardOptions(CashFlowForecast);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ForecastingFCYAmountConsideringDiscountAndCFPmtTermsOnCustLE()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
    begin
        // Setup
        Initialize();
        LibraryCashFlowHelper.CreateCashFlowForecastConsiderDiscountAndCFPmtTerms(CashFlowForecast);

        // Exercise & Verify
        ForecastingFCYAmountsOnReceivablesWithCFCardOptions(CashFlowForecast);
    end;

    local procedure ForecastingFCYAmountsOnReceivablesWithCFCardOptions(CashFlowForecast: Record "Cash Flow Forecast")
    var
        PaymentTerms: Record "Payment Terms";
        SalesHeader: Record "Sales Header";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        RelationalExchangeRateAmount: Decimal;
        AmountFCY: Decimal;
        ExpectedAmount: Decimal;
        SalesInvoiceNo: Code[20];
        CustomerNo: Code[20];
        ConsiderSource: array[16] of Boolean;
    begin
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, true);
        RelationalExchangeRateAmount := 0.4379; // hard coded exchange rate for bug fix purpose #329266
        CustomerNo := CreateCustomerWithPaymentTerms(PaymentTerms.Code);
        ModifyCustomerWithCurrency(CustomerNo, CreateCurrencyWithExchangeRate(RelationalExchangeRateAmount));
        SalesInvoiceNo := CreateAndPostSalesOrderWithOneLine(SalesHeader, CustomerNo);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, SalesInvoiceNo);
        CustLedgerEntry.CalcFields(Amount);

        AmountFCY := CustLedgerEntry.Amount;
        ExpectedAmount :=
          Round(AmountFCY * RelationalExchangeRateAmount, LibraryERM.GetAmountRoundingPrecision()) -
          LibraryCashFlowHelper.CalcCustDiscAmtLCY(CustLedgerEntry, PaymentTerms."Discount %", RelationalExchangeRateAmount);

        // Exercise
        ConsiderSource[SourceType::Receivables.AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify
        CFWorksheetLine.SetRange("Document No.", SalesInvoiceNo);
        CFWorksheetLine.FindFirst();
        Assert.AreEqual(ExpectedAmount, CFWorksheetLine."Amount (LCY)", 'Unexpected forecast amount when converting from FCY to LCY');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ForecastingFCYAmountConsideringDiscountOnVendLE()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
    begin
        // Setup
        Initialize();
        LibraryCashFlowHelper.CreateCashFlowForecastConsiderDiscount(CashFlowForecast);

        // Exercise & Verify
        ForecastingFCYAmountsOnPayablesWithCFCardOptions(CashFlowForecast);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ForecastingFCYAmountConsideringDiscountAndCFPmtTermsOnVendLE()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
    begin
        // Setup
        Initialize();
        LibraryCashFlowHelper.CreateCashFlowForecastConsiderDiscountAndCFPmtTerms(CashFlowForecast);

        // Exercise & Verify
        ForecastingFCYAmountsOnPayablesWithCFCardOptions(CashFlowForecast);
    end;

    local procedure ForecastingFCYAmountsOnPayablesWithCFCardOptions(CashFlowForecast: Record "Cash Flow Forecast")
    var
        PaymentTerms: Record "Payment Terms";
        PurchaseHeader: Record "Purchase Header";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        RelationalExchangeRateAmount: Decimal;
        AmountFCY: Decimal;
        ExpectedAmount: Decimal;
        PurchaseInvoiceNo: Code[20];
        ConsiderSource: array[16] of Boolean;
        VendorNo: Code[20];
    begin
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, true);
        RelationalExchangeRateAmount := 0.4379; // hard coded exchange rate for bug fix purpose #329266
        VendorNo := CreateVendorWithPaymentTerms(PaymentTerms.Code);
        ModifyVendorWithCurrency(VendorNo, CreateCurrencyWithExchangeRate(RelationalExchangeRateAmount));
        PurchaseInvoiceNo := CreateAndPostPurchaseOrderWithOneLine(PurchaseHeader, VendorNo);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, PurchaseInvoiceNo);
        VendorLedgerEntry.CalcFields(Amount);

        AmountFCY := VendorLedgerEntry.Amount;
        ExpectedAmount :=
          Round(AmountFCY * RelationalExchangeRateAmount, LibraryERM.GetAmountRoundingPrecision()) -
          LibraryCashFlowHelper.CalcVendDiscAmtLCY(
            VendorLedgerEntry, PaymentTerms."Discount %", RelationalExchangeRateAmount);

        // Exercise
        ConsiderSource[SourceType::Payables.AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify
        CFWorksheetLine.SetRange("Document No.", PurchaseInvoiceNo);
        CFWorksheetLine.FindFirst();
        Assert.AreEqual(ExpectedAmount, CFWorksheetLine."Amount (LCY)", 'Unexpected forecast amount when converting from FCY to LCY');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerLedgerEntryValuesAreConsideredWhenCFPmtTermsNotApplicable()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        PaymentTerms: Record "Payment Terms";
        PaymentTermsDifferent: Record "Payment Terms";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustomerNo: Code[20];
        ExpectedAmount: Decimal;
        SalesInvoiceNo: Code[20];
        ConsiderSource: array[16] of Boolean;
    begin
        // Setup
        Initialize();
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, true);
        CustomerNo := CreateCustomerWithPaymentTerms(PaymentTerms.Code);
        LibraryCashFlowHelper.GetDifferentDsctPaymentTerms(PaymentTermsDifferent, PaymentTerms.Code);
        SalesInvoiceNo := CreateAndPostSalesOrderWithDiscountPercentage(CustomerNo, PaymentTermsDifferent.Code);
        LibraryCashFlowHelper.CreateCashFlowForecastConsiderDiscountAndCFPmtTerms(CashFlowForecast);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, SalesInvoiceNo);
        CustLedgerEntry.CalcFields(Amount);

        ExpectedAmount :=
          CustLedgerEntry.Amount -
          LibraryCashFlowHelper.CalcCustDiscAmt(CustLedgerEntry, PaymentTermsDifferent."Discount %");

        // Exercise
        ConsiderSource[SourceType::Receivables.AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify
        VerifyCFWorksheetLineAmount(CashFlowForecast."No.", SalesInvoiceNo, SourceType::Receivables, ExpectedAmount,
          'Forecast amount calculation is not using values from customer ledger entries');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorLedgerEntryValuesAreConsideredWhenCFPmtTermsNotApplicable()
    var
        PaymentTerms: Record "Payment Terms";
        PaymentTermsDifferent: Record "Payment Terms";
        CashFlowForecast: Record "Cash Flow Forecast";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PurchaseInvoiceNo: Code[20];
        VendorNo: Code[20];
        ExpectedAmount: Decimal;
        ConsiderSource: array[16] of Boolean;
    begin
        // Setup
        Initialize();
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, true);
        VendorNo := CreateVendorWithPaymentTerms(PaymentTerms.Code);
        LibraryCashFlowHelper.GetDifferentDsctPaymentTerms(PaymentTermsDifferent, PaymentTerms.Code);
        PurchaseInvoiceNo := CreateAndPostPurchaseOrderWithDiscountPercentage(VendorNo, PaymentTermsDifferent.Code);
        LibraryCashFlowHelper.CreateCashFlowForecastConsiderDiscountAndCFPmtTerms(CashFlowForecast);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, PurchaseInvoiceNo);
        VendorLedgerEntry.CalcFields(Amount);

        ExpectedAmount :=
          VendorLedgerEntry.Amount -
          LibraryCashFlowHelper.CalcVendDiscAmt(VendorLedgerEntry, PaymentTermsDifferent."Discount %");

        // Exercise
        ConsiderSource[SourceType::Payables.AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify
        VerifyCFWorksheetLineAmount(CashFlowForecast."No.", PurchaseInvoiceNo, SourceType::Payables, ExpectedAmount,
          'Forecast amount calculation is not using values from vendor ledger entries');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CashFlowWorksheetLineWithGroupByDocumentTypeOption()
    begin
        Initialize();
        CashFlowWorksheetLineGroupByDocumentTypeOption(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CashFlowWorksheetLineWithoutGroupByDocumentTypeOption()
    begin
        Initialize();
        CashFlowWorksheetLineGroupByDocumentTypeOption(false);
    end;

    local procedure CashFlowWorksheetLineGroupByDocumentTypeOption(IsSet: Boolean)
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        ServiceHeader: Record "Service Header";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        ConsiderSource: array[16] of Boolean;
        ExpectedCountOfLines: Integer;
    begin
        // Setup
        LibraryCashFlowHelper.CreateCashFlowForecastDefault(CashFlowForecast);
        LibraryCashFlowHelper.CreateDefaultSalesOrder(SalesHeader);
        LibraryCashFlowHelper.CreateDefaultPurchaseOrder(PurchaseHeader);
        LibraryService.CreateDefaultServiceOrder(ServiceHeader);
        LibraryApplicationArea.EnableFoundationSetup();

        // Excercise
        ConsiderSource[SourceType::"Sales Orders".AsInteger()] := true;
        ConsiderSource[SourceType::"Purchase Orders".AsInteger()] := true;
        ConsiderSource[SourceType::"Service Orders".AsInteger()] := true;

        if IsSet then begin
            FillJournalWithGroupBy(ConsiderSource, CashFlowForecast."No.");
            ExpectedCountOfLines := 3; // 3 SourceType are selected above, each with one line
        end else begin
            FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");
            ExpectedCountOfLines := GetNumberOfSalesLines(SalesHeader) +
              GetNumberOfPurchaseLines(PurchaseHeader) + GetNumberOfServiceLines(ServiceHeader);
        end;

        // Verify
        CFWorksheetLine.SetFilter("Cash Flow Forecast No.", '%1', CashFlowForecast."No.");
        CFWorksheetLine.SetFilter("Document No.", '%1|%2|%3', SalesHeader."No.", PurchaseHeader."No.", ServiceHeader."No.");

        Assert.AreEqual(ExpectedCountOfLines, CFWorksheetLine.Count,
          StrSubstNo(UnexpectedCFWorksheetLineCountForMultipleSourcesErr,
            CashFlowForecast."No.", SalesHeader."No.", PurchaseHeader."No.", ServiceHeader."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderInFCYWithGroupByDocumentTypeOption()
    begin
        Initialize();
        SalesOrderInFCYGroupByDocumentTypeOption(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderInFCYWithoutGroupByDocumentTypeOption()
    begin
        Initialize();
        SalesOrderInFCYGroupByDocumentTypeOption(false);
    end;

    local procedure SalesOrderInFCYGroupByDocumentTypeOption(IsSet: Boolean)
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
        RelationalExchangeRateAmount: Decimal;
        ExpectedAmountLCY: Decimal;
        ConsiderSource: array[16] of Boolean;
    begin
        // Test filling a CF Journal with a sales order for a Customer in FCY
        // Verify computed cash flow forecast amount

        // Setup
        LibraryCashFlowHelper.CreateCashFlowForecastDefault(CashFlowForecast);
        RelationalExchangeRateAmount := LibraryRandom.RandDec(10, 4);
        CustomerNo := CreateCustomerWithCurrency(CreateCurrencyWithExchangeRate(RelationalExchangeRateAmount));
        CreateSalesOrderWithLineCount(SalesHeader, CustomerNo, 2);
        ExpectedAmountLCY := LibraryCashFlowHelper.GetTotalSalesAmount(SalesHeader, false);

        // Excercise
        ConsiderSource[SourceType::"Sales Orders".AsInteger()] := true;
        if IsSet then
            FillJournalWithGroupBy(ConsiderSource, CashFlowForecast."No.")
        else
            FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify
        VerifyExpectedCFAmount(ExpectedAmountLCY, SalesHeader."No.", SourceType::"Sales Orders", CashFlowForecast."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderInFCYWithDiscount()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        SalesHeader: Record "Sales Header";
        PaymentTerms: Record "Payment Terms";
        CustomerNo: Code[20];
        RelationalExchangeRateAmount: Decimal;
        ExpectedAmountLCY: Decimal;
        ConsiderSource: array[16] of Boolean;
    begin
        // Setup
        Initialize();
        LibraryCashFlowHelper.CreateCashFlowForecastConsiderDiscount(CashFlowForecast);
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, true);
        RelationalExchangeRateAmount := LibraryRandom.RandDec(10, 4);
        CustomerNo := CreateCustomerWithPaymentTerms(PaymentTerms.Code);
        ModifyCustomerWithCurrency(CustomerNo, CreateCurrencyWithExchangeRate(RelationalExchangeRateAmount));
        CreateSalesOrderWithLineCount(SalesHeader, CustomerNo, 2);
        ExpectedAmountLCY := LibraryCashFlowHelper.GetTotalSalesAmount(SalesHeader, true);

        // Excercise
        ConsiderSource[SourceType::"Sales Orders".AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify
        VerifyExpectedCFAmount(ExpectedAmountLCY, SalesHeader."No.", SourceType::"Sales Orders", CashFlowForecast."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderInFCYWithCashFlowPaymentTerms()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        SalesHeader: Record "Sales Header";
        PaymentTerms: Record "Payment Terms";
        CustomerNo: Code[20];
        RelationalExchangeRateAmount: Decimal;
        ExpectedAmountLCY: Decimal;
        ConsiderSource: array[16] of Boolean;
    begin
        // Setup
        Initialize();
        LibraryCashFlowHelper.CreateCashFlowForecastConsiderCFPmtTerms(CashFlowForecast);
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, true);
        RelationalExchangeRateAmount := LibraryRandom.RandDec(10, 4);
        CustomerNo := CreateCustomerWithCashFlowPaymentTerms(PaymentTerms.Code);
        ModifyCustomerWithCurrency(CustomerNo, CreateCurrencyWithExchangeRate(RelationalExchangeRateAmount));
        CreateSalesOrderWithLineCount(SalesHeader, CustomerNo, 2);
        ExpectedAmountLCY := LibraryCashFlowHelper.GetTotalSalesAmount(SalesHeader, false);

        // Excercise
        ConsiderSource[SourceType::"Sales Orders".AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify
        VerifyExpectedCFAmount(ExpectedAmountLCY, SalesHeader."No.", SourceType::"Sales Orders", CashFlowForecast."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderInFCYWithDiscountAndCashFlowPaymentTerms()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        SalesHeader: Record "Sales Header";
        PaymentTerms: Record "Payment Terms";
        PaymentTermsCashFlow: Record "Payment Terms";
        CustomerNo: Code[20];
        RelationalExchangeRateAmount: Decimal;
        ExpectedAmountLCY: Decimal;
        ConsiderSource: array[16] of Boolean;
    begin
        // Setup
        Initialize();
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, true);
        LibraryCashFlowHelper.GetDifferentDsctPaymentTerms(PaymentTermsCashFlow, PaymentTerms.Code);
        LibraryCashFlowHelper.CreateCashFlowForecastConsiderDiscountAndCFPmtTerms(CashFlowForecast);
        RelationalExchangeRateAmount := LibraryRandom.RandDec(10, 4);
        CustomerNo := CreateCustomerWithPaymentTerms(PaymentTerms.Code);
        ModifyCustomerWithCashFlowPaymentTerms(CustomerNo, PaymentTermsCashFlow.Code);
        ModifyCustomerWithCurrency(CustomerNo, CreateCurrencyWithExchangeRate(RelationalExchangeRateAmount));
        CreateSalesOrderWithLineCount(SalesHeader, CustomerNo, 2);
        ExpectedAmountLCY := LibraryCashFlowHelper.GetTotalAmountForSalesOrderWithCashFlowPaymentTermsDiscount(SalesHeader);

        // Excercise
        ConsiderSource[SourceType::"Sales Orders".AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify
        VerifyExpectedCFAmount(ExpectedAmountLCY, SalesHeader."No.", SourceType::"Sales Orders", CashFlowForecast."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderInFCYWithGroupByDocumentTypeOption()
    begin
        PurchaseOrderInFCYGroupByDocumentTypeOption(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderInFCYWithoutGroupByDocumentTypeOption()
    begin
        PurchaseOrderInFCYGroupByDocumentTypeOption(false);
    end;

    local procedure PurchaseOrderInFCYGroupByDocumentTypeOption(isSet: Boolean)
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
        RelationalExchangeRateAmount: Decimal;
        ExpectedAmountLCY: Decimal;
        ConsiderSource: array[16] of Boolean;
    begin
        // Test filling a CF Journal with a purchase order for a Customer in FCY
        // Verify computed cash flow forecast amount

        // Setup
        Initialize();
        LibraryCashFlowHelper.CreateCashFlowForecastDefault(CashFlowForecast);
        RelationalExchangeRateAmount := LibraryRandom.RandDec(10, 4);
        VendorNo := CreateVendorWithCurrency(CreateCurrencyWithExchangeRate(RelationalExchangeRateAmount));
        CreatePurchaseOrderWithLineCount(PurchaseHeader, VendorNo, 2);
        ExpectedAmountLCY := -1 * LibraryCashFlowHelper.GetTotalPurchaseAmount(PurchaseHeader, false);
        LibraryApplicationArea.EnableFoundationSetup();

        // Excercise
        ConsiderSource[SourceType::"Purchase Orders".AsInteger()] := true;
        if isSet then
            FillJournalWithGroupBy(ConsiderSource, CashFlowForecast."No.")
        else
            FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify
        VerifyExpectedCFAmount(ExpectedAmountLCY, PurchaseHeader."No.", SourceType::"Purchase Orders", CashFlowForecast."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderInFCYWithDiscount()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        PurchaseHeader: Record "Purchase Header";
        PaymentTerms: Record "Payment Terms";
        VendorNo: Code[20];
        RelationalExchangeRateAmount: Decimal;
        ExpectedAmountLCY: Decimal;
        ConsiderSource: array[16] of Boolean;
    begin
        // Setup
        Initialize();
        LibraryCashFlowHelper.CreateCashFlowForecastConsiderDiscount(CashFlowForecast);
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, true);
        RelationalExchangeRateAmount := LibraryRandom.RandDec(10, 4);
        VendorNo := CreateVendorWithPaymentTerms(PaymentTerms.Code);
        ModifyVendorWithCurrency(VendorNo, CreateCurrencyWithExchangeRate(RelationalExchangeRateAmount));
        CreatePurchaseOrderWithLineCount(PurchaseHeader, VendorNo, 2);
        ExpectedAmountLCY := -1 * LibraryCashFlowHelper.GetTotalPurchaseAmount(PurchaseHeader, true);
        LibraryApplicationArea.EnableFoundationSetup();

        // Excercise
        ConsiderSource[SourceType::"Purchase Orders".AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify
        VerifyExpectedCFAmount(ExpectedAmountLCY, PurchaseHeader."No.", SourceType::"Purchase Orders", CashFlowForecast."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderInFCYWithCashFlowPaymentTerms()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        PurchaseHeader: Record "Purchase Header";
        PaymentTerms: Record "Payment Terms";
        VendorNo: Code[20];
        RelationalExchangeRateAmount: Decimal;
        ExpectedAmountLCY: Decimal;
        ConsiderSource: array[16] of Boolean;
    begin
        // Setup
        Initialize();
        LibraryCashFlowHelper.CreateCashFlowForecastConsiderCFPmtTerms(CashFlowForecast);
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, true);
        RelationalExchangeRateAmount := LibraryRandom.RandDec(10, 4);
        VendorNo := CreateVendorWithCashFlowPaymentTerms(PaymentTerms.Code);
        ModifyVendorWithCurrency(VendorNo, CreateCurrencyWithExchangeRate(RelationalExchangeRateAmount));
        CreatePurchaseOrderWithLineCount(PurchaseHeader, VendorNo, 2);
        ExpectedAmountLCY := -1 * LibraryCashFlowHelper.GetTotalPurchaseAmount(PurchaseHeader, false);
        LibraryApplicationArea.EnableFoundationSetup();

        // Excercise
        ConsiderSource[SourceType::"Purchase Orders".AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify
        VerifyExpectedCFAmount(ExpectedAmountLCY, PurchaseHeader."No.", SourceType::"Purchase Orders", CashFlowForecast."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderInFCYWithDiscountAndCashFlowPaymentTerms()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        PurchaseHeader: Record "Purchase Header";
        PaymentTerms: Record "Payment Terms";
        PaymentTermsCashFlow: Record "Payment Terms";
        VendorNo: Code[20];
        RelationalExchangeRateAmount: Decimal;
        ExpectedAmountLCY: Decimal;
        ConsiderSource: array[16] of Boolean;
    begin
        // Setup
        Initialize();
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, true);
        LibraryCashFlowHelper.GetDifferentDsctPaymentTerms(PaymentTermsCashFlow, PaymentTerms.Code);
        LibraryCashFlowHelper.CreateCashFlowForecastConsiderDiscountAndCFPmtTerms(CashFlowForecast);
        RelationalExchangeRateAmount := LibraryRandom.RandDec(10, 4);
        VendorNo := CreateVendorWithPaymentTerms(PaymentTerms.Code);
        ModifyVendorWithCashFlowPaymentTerms(VendorNo, PaymentTermsCashFlow.Code);
        ModifyVendorWithCurrency(VendorNo, CreateCurrencyWithExchangeRate(RelationalExchangeRateAmount));
        CreatePurchaseOrderWithLineCount(PurchaseHeader, VendorNo, 2);
        ExpectedAmountLCY := -LibraryCashFlowHelper.GetTotalAmountForPurchaseOrderWithCashFlowPaymentTermsDiscount(PurchaseHeader);
        LibraryApplicationArea.EnableFoundationSetup();

        // Excercise
        ConsiderSource[SourceType::"Purchase Orders".AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify
        VerifyExpectedCFAmount(ExpectedAmountLCY, PurchaseHeader."No.", SourceType::"Purchase Orders", CashFlowForecast."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrderInFCYWithGroupByDocumentTypeOption()
    begin
        ServiceOrderInFCYGroupByDocumentTypeOption(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrderInFCYWithoutGroupByDocumentTypeOption()
    begin
        ServiceOrderInFCYGroupByDocumentTypeOption(false);
    end;

    local procedure ServiceOrderInFCYGroupByDocumentTypeOption(isSet: Boolean)
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        ServiceHeader: Record "Service Header";
        CustomerNo: Code[20];
        RelationalExchangeRateAmount: Decimal;
        ExpectedAmountLCY: Decimal;
        ConsiderSource: array[16] of Boolean;
    begin
        // Test filling a CF Journal with a service order for a Customer in FCY
        // Verify computed cash flow forecast amount

        // Setup
        Initialize();
        LibraryCashFlowHelper.CreateCashFlowForecastDefault(CashFlowForecast);
        RelationalExchangeRateAmount := LibraryRandom.RandDec(10, 4);
        CustomerNo := CreateCustomerWithCurrency(CreateCurrencyWithExchangeRate(RelationalExchangeRateAmount));
        CreateServiceOrderWithLineCount(ServiceHeader, CustomerNo, 2);
        ExpectedAmountLCY := LibraryCashFlowHelper.GetTotalServiceAmount(ServiceHeader, false);

        // Excercise
        ConsiderSource[SourceType::"Service Orders".AsInteger()] := true;
        if isSet then
            FillJournalWithGroupBy(ConsiderSource, CashFlowForecast."No.")
        else
            FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify
        VerifyExpectedCFAmount(ExpectedAmountLCY, ServiceHeader."No.", SourceType::"Service Orders", CashFlowForecast."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrderInFCYWithDiscount()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        ServiceHeader: Record "Service Header";
        PaymentTerms: Record "Payment Terms";
        CustomerNo: Code[20];
        RelationalExchangeRateAmount: Decimal;
        ExpectedAmountLCY: Decimal;
        ConsiderSource: array[16] of Boolean;
    begin
        // Setup
        Initialize();
        LibraryCashFlowHelper.CreateCashFlowForecastConsiderDiscount(CashFlowForecast);
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, true);
        RelationalExchangeRateAmount := LibraryRandom.RandDec(10, 4);
        CustomerNo := CreateCustomerWithPaymentTerms(PaymentTerms.Code);
        ModifyCustomerWithCurrency(CustomerNo, CreateCurrencyWithExchangeRate(RelationalExchangeRateAmount));
        CreateServiceOrderWithLineCount(ServiceHeader, CustomerNo, 2);
        ExpectedAmountLCY := LibraryCashFlowHelper.GetTotalServiceAmount(ServiceHeader, true);

        // Excercise
        ConsiderSource[SourceType::"Service Orders".AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify
        VerifyExpectedCFAmount(ExpectedAmountLCY, ServiceHeader."No.", SourceType::"Service Orders", CashFlowForecast."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrderInFCYWithCashFlowPaymentTerms()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        ServiceHeader: Record "Service Header";
        PaymentTerms: Record "Payment Terms";
        CustomerNo: Code[20];
        RelationalExchangeRateAmount: Decimal;
        ExpectedAmountLCY: Decimal;
        ConsiderSource: array[16] of Boolean;
    begin
        // Setup
        Initialize();
        LibraryCashFlowHelper.CreateCashFlowForecastConsiderCFPmtTerms(CashFlowForecast);
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, true);
        RelationalExchangeRateAmount := LibraryRandom.RandDec(10, 4);
        CustomerNo := CreateCustomerWithCashFlowPaymentTerms(PaymentTerms.Code);
        ModifyCustomerWithCurrency(CustomerNo, CreateCurrencyWithExchangeRate(RelationalExchangeRateAmount));
        CreateServiceOrderWithLineCount(ServiceHeader, CustomerNo, 2);
        ExpectedAmountLCY := LibraryCashFlowHelper.GetTotalServiceAmount(ServiceHeader, false);

        // Excercise
        ConsiderSource[SourceType::"Service Orders".AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify
        VerifyExpectedCFAmount(ExpectedAmountLCY, ServiceHeader."No.", SourceType::"Service Orders", CashFlowForecast."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrderInFCYWithDiscountAndCashFlowPaymentTerms()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        ServiceHeader: Record "Service Header";
        PaymentTerms: Record "Payment Terms";
        PaymentTermsCashFlow: Record "Payment Terms";
        CustomerNo: Code[20];
        RelationalExchangeRateAmount: Decimal;
        ExpectedAmountLCY: Decimal;
        ConsiderSource: array[16] of Boolean;
    begin
        // Setup
        Initialize();
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, true);
        LibraryCashFlowHelper.GetDifferentDsctPaymentTerms(PaymentTermsCashFlow, PaymentTerms.Code);
        LibraryCashFlowHelper.CreateCashFlowForecastConsiderDiscountAndCFPmtTerms(CashFlowForecast);
        RelationalExchangeRateAmount := LibraryRandom.RandDec(10, 4);
        CustomerNo := CreateCustomerWithPaymentTerms(PaymentTerms.Code);
        ModifyCustomerWithCashFlowPaymentTerms(CustomerNo, PaymentTermsCashFlow.Code);
        ModifyCustomerWithCurrency(CustomerNo, CreateCurrencyWithExchangeRate(RelationalExchangeRateAmount));
        CreateServiceOrderWithLineCount(ServiceHeader, CustomerNo, 2);
        ExpectedAmountLCY := LibraryCashFlowHelper.GetTotalAmountForServiceOrderWithCashFlowPaymentTermsDiscount(ServiceHeader);

        // Excercise
        ConsiderSource[SourceType::"Service Orders".AsInteger()] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify
        VerifyExpectedCFAmount(ExpectedAmountLCY, ServiceHeader."No.", SourceType::"Service Orders", CashFlowForecast."No.");
    end;

    [Test]
    [HandlerFunctions('SalesOrderListPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderWithoutVATIsShownInOrderListWhenSkipNoVATIsFalse()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [UI] [Sales] [Order]
        // [SCENARIO 382294] Sales Order without VAT is shown on the "Sales Order List" page when called with SkipShowingLinesWithoutVAT = FALSE
        Initialize();

        // [GIVEN] Sales Order "A" without VAT
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());

        // [WHEN] Open "Sales Order List" page with SkipShowingLinesWithoutVAT = FALSE
        LibraryVariableStorage.Enqueue(SalesHeader."No.");
        OpenSalesOrderList(SalesHeader, false);

        // [THEN] Sales Order "A" is on the order list
        // Verify sales order in SalesOrderListPageHandler
    end;

    [Test]
    [HandlerFunctions('SalesOrderListPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderWithoutVATIsNotShownInOrderListWhenSkipNoVATIsTrue()
    var
        SalesHeader: Record "Sales Header";
        VatPostingSetup: Record "Vat Posting Setup";
    begin
        // [FEATURE] [UI] [Sales] [Order]
        // [SCENARIO 382294] Sales Order without VAT is not shown on the "Sales Order List" page when called with SkipShowingLinesWithoutVAT = TRUE
        Initialize();

        // [GIVEN] Sales Order "A" without VAT
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        CreateVATPostingSetup(VatPostingSetup, false);
        SalesHeader."VAT Bus. Posting Group" := VatPostingSetup."VAT Bus. Posting Group";
        SalesHeader.Modify();

        // [WHEN] Open "Sales Order List" page with SkipShowingLinesWithoutVAT = TRUE
        LibraryVariableStorage.Enqueue('');
        OpenSalesOrderList(SalesHeader, true);

        // [THEN] Sales Order "A" is not shown on the order list
        // Verify sales order in SalesOrderListPageHandler
    end;

    [Test]
    [HandlerFunctions('SalesOrderListPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderWithVATIsShownInOrderListWhenSkipNoVATIsFalse()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [UI] [Sales] [Order]
        // [SCENARIO 382294] Sales Order with VAT is shown on the "Sales Order List" page when called with SkipShowingLinesWithoutVAT = FALSE
        Initialize();

        // [GIVEN] Sales Order "A" with VAT
        CreateSalesOrderWithVAT(SalesHeader);

        // [WHEN] Open "Sales Order List" page with SkipShowingLinesWithoutVAT = FALSE
        LibraryVariableStorage.Enqueue(SalesHeader."No.");
        OpenSalesOrderList(SalesHeader, false);

        // [THEN] Sales Order "A" is on the order list
        // Verify sales order in SalesOrderListPageHandler
    end;

    [Test]
    [HandlerFunctions('SalesOrderListPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderWithVATIsShownInOrderListWhenSkipNoVATIsTrue()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [UI] [Sales] [Order]
        // [SCENARIO 382294] Sales Order with VAT is shown on the "Sales Order List" page when called with SkipShowingLinesWithoutVAT = TRUE
        Initialize();

        // [GIVEN] Sales Order "A" with VAT
        CreateSalesOrderWithVAT(SalesHeader);

        // [WHEN] Open "Sales Order List" page with SkipShowingLinesWithoutVAT = TRUE
        LibraryVariableStorage.Enqueue(SalesHeader."No.");
        OpenSalesOrderList(SalesHeader, true);

        // [THEN] Sales Order "A" is on the order list
        // Verify sales order in SalesOrderListPageHandler
    end;

    [Test]
    [HandlerFunctions('SalesOrderListWithVATPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderListShownOrdersOnlyWithVATWhenSkipNoVATIsTrue()
    var
        SalesHeader: Record "Sales Header";
        YourReference: Text[35];
    begin
        // [FEATURE] [UI] [Sales] [Order]
        // [SCENARIO 269334] Page "Sales Order List" is filtering the Sales Orders without VAT and showing Sales Order with VAT when SkipShowingLinesWithoutVAT = TRUE
        Initialize();

        // [GIVEN] Sales Order "A" without VAT
        YourReference := CopyStr(LibraryRandom.RandText(MaxStrLen(YourReference)), 1, MaxStrLen(YourReference)); // Needed for filtering orders
        CreateSalesOrderWithoutVATAndWithYourReference(SalesHeader, YourReference);

        // [GIVEN] Sales Order "B" with VAT
        CreateSalesOrderWithVATAndYourReference(SalesHeader, YourReference);
        LibraryVariableStorage.Enqueue(SalesHeader."No.");

        // [GIVEN] Sales Order "C" without VAT
        CreateSalesOrderWithoutVATAndWithYourReference(SalesHeader, YourReference);

        // [GIVEN] Sales Order "D" with VAT
        CreateSalesOrderWithVATAndYourReference(SalesHeader, YourReference);
        LibraryVariableStorage.Enqueue(SalesHeader."No.");

        // [WHEN] Open "Sales Order List" page with SkipShowingLinesWithoutVAT = TRUE
        Clear(SalesHeader);
        OpenSalesOrdList(SalesHeader, true, YourReference);

        // [THEN] "Sales Order List" contains sales orders "B" and "D", and doesn't contain sales orders "A" and "C"
        // Verify sales orders in SalesOrderListWithVATPageHandler
    end;

    [Test]
    [HandlerFunctions('SalesOrderListAllOrdersVATPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderListShownAllOrdersWhenSkipNoVATIsFalse()
    var
        SalesHeader: Record "Sales Header";
        YourReference: Text[35];
    begin
        // [FEATURE] [UI] [Sales] [Order]
        // [SCENARIO 269334] Page "Sales Order List" is shown the Sales Orders without VAT and with VAT when SkipShowingLinesWithoutVAT = TRUE
        Initialize();

        // [GIVEN] Sales Order "A" without VAT
        YourReference := CopyStr(LibraryRandom.RandText(MaxStrLen(YourReference)), 1, MaxStrLen(YourReference)); // Needed for filtering orders
        CreateSalesOrderWithoutVATAndWithYourReference(SalesHeader, YourReference);
        LibraryVariableStorage.Enqueue(SalesHeader."No.");

        // [GIVEN] Sales Order "B" with VAT
        CreateSalesOrderWithVATAndYourReference(SalesHeader, YourReference);
        LibraryVariableStorage.Enqueue(SalesHeader."No.");

        // [GIVEN] Sales Order "C" without VAT
        CreateSalesOrderWithoutVATAndWithYourReference(SalesHeader, YourReference);
        LibraryVariableStorage.Enqueue(SalesHeader."No.");

        // [GIVEN] Sales Order "D" with VAT
        CreateSalesOrderWithVATAndYourReference(SalesHeader, YourReference);
        LibraryVariableStorage.Enqueue(SalesHeader."No.");

        // [WHEN] Open "Sales Order List" page with SkipShowingLinesWithoutVAT = FALSE
        Clear(SalesHeader);
        OpenSalesOrdList(SalesHeader, false, YourReference);

        // [THEN] "Sales Order List" contains sales orders "A", "B", "C" and "D"
        // Verify sales orders SalesOrderListAllOrdersVATPageHandler
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderListPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithoutVATIsShownInOrderListWhenSkipNoVATIsFalse()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [UI] [Purchase] [Order]
        // [SCENARIO 382294] Purchase Order without VAT is shown on the "Purchase Order List" page when called with SkipShowingLinesWithoutVAT = FALSE
        Initialize();

        // [GIVEN] Purchase Order "A" without VAT
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());

        // [WHEN] Open "Purchase Order List" page with SkipShowingLinesWithoutVAT = FALSE
        LibraryVariableStorage.Enqueue(PurchaseHeader."No.");
        OpenPurchaseOrderList(PurchaseHeader, false);

        // [THEN] Purchase Order "A" is on the order list
        // Verify purchase order in PurchaseOrderListPageHandler
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderListPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithoutVATIsNotShownInOrderListWhenSkipNoVATIsTrue()
    var
        PurchaseHeader: Record "Purchase Header";
        VatPostingSetup: Record "Vat Posting Setup";
    begin
        // [FEATURE] [UI] [Purchase] [Order]
        // [SCENARIO 382294] Purchase Order without VAT is not shown on the "Purchase Order List" page when called with SkipShowingLinesWithoutVAT = TRUE
        Initialize();

        // [GIVEN] Purchase Order "A" without VAT
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        CreateVATPostingSetup(VatPostingSetup, false);
        PurchaseHeader."VAT Bus. Posting Group" := VatPostingSetup."VAT Bus. Posting Group";
        PurchaseHeader.Modify();

        // [WHEN] Open "Purchase Order List" page with SkipShowingLinesWithoutVAT = TRUE
        LibraryVariableStorage.Enqueue('');
        OpenPurchaseOrderList(PurchaseHeader, true);

        // [THEN] Purchase Order "A" is not shown on the order list
        // Verify purchase order in PurchaseOrderListPageHandler
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderListPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithVATIsShownInOrderListWhenSkipNoVATIsFalse()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [UI] [Purchase] [Order]
        // [SCENARIO 382294] Purchase Order with VAT is shown on the "Purchase Order List" page when called with SkipShowingLinesWithoutVAT = FALSE
        Initialize();

        // [GIVEN] Purchase Order "A" with VAT
        CreatePurchaseOrderWithVAT(PurchaseHeader);

        // [WHEN] Open "Purchase Order List" page with SkipShowingLinesWithoutVAT = FALSE
        LibraryVariableStorage.Enqueue(PurchaseHeader."No.");
        OpenPurchaseOrderList(PurchaseHeader, false);

        // [THEN] Purchase Order "A" is on the order list
        // Verify purchase order in PurchaseOrderListPageHandler
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderListPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithVATIsShownInOrderListWhenSkipNoVATIsTrue()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [UI] [Purchase] [Order]
        // [SCENARIO 382294] Purchase Order with VAT is shown on the "Purchase Order List" page when called with SkipShowingLinesWithoutVAT = TRUE
        Initialize();

        // [GIVEN] Purchase Order "A" with VAT
        CreatePurchaseOrderWithVAT(PurchaseHeader);

        // [WHEN] Open "Purchase Order List" page with SkipShowingLinesWithoutVAT = TRUE
        LibraryVariableStorage.Enqueue(PurchaseHeader."No.");
        OpenPurchaseOrderList(PurchaseHeader, true);

        // [THEN] Purchase Order "A" is on the order list
        // Verify purchase order in PurchaseOrderListPageHandler
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderListWithVATPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderListShownOrdersOnlyWithVATWhenSkipNoVATIsTrue()
    var
        PurchaseHeader: Record "Purchase Header";
        YourReference: Text[35];
    begin
        // [FEATURE] [UI] [Purchase] [Order]
        // [SCENARIO 269334] Page "Purchase Order List" is filtering the Purchase Orders without VAT and showing Purchase Order with VAT when SkipShowingLinesWithoutVAT = TRUE
        Initialize();

        // [GIVEN] Purchase Order "A" without VAT
        YourReference := CopyStr(LibraryRandom.RandText(MaxStrLen(YourReference)), 1, MaxStrLen(YourReference)); // Needed for filtering orders
        CreatePurchaseOrderWithoutVATAndWithYourReference(PurchaseHeader, YourReference);

        // [GIVEN] Purchase Order "B" with VAT
        CreatePurchaseOrderWithVATAndYourReference(PurchaseHeader, YourReference);
        LibraryVariableStorage.Enqueue(PurchaseHeader."No.");

        // [GIVEN] Purchase Order "C" without VAT
        CreatePurchaseOrderWithoutVATAndWithYourReference(PurchaseHeader, YourReference);

        // [GIVEN] Sales Order "D" with VAT
        CreatePurchaseOrderWithVATAndYourReference(PurchaseHeader, YourReference);
        LibraryVariableStorage.Enqueue(PurchaseHeader."No.");

        // [WHEN] Open "Purchase Order List" page with SkipShowingLinesWithoutVAT = TRUE
        Clear(PurchaseHeader);
        OpenPurchaseOrdList(PurchaseHeader, true, YourReference);

        // [THEN] "Purchase Order List" contains purchase orders "B" and "D", and doesn't contain purchase orders "A" and "C"
        // Verify purchase orders in PurchaseOrderListWithVATPageHandler
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderListAllOrdersVATPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderListShownAllOrdersWhenSkipNoVATIsFalse()
    var
        PurchaseHeader: Record "Purchase Header";
        YourReference: Text[35];
    begin
        // [FEATURE] [UI] [Purchase] [Order]
        // [SCENARIO 269334] Page "Purchase Order List" is shown the Purchase Orders without VAT and with VAT when SkipShowingLinesWithoutVAT = TRUE
        Initialize();

        // [GIVEN] Purchase Order "A" without VAT
        YourReference := CopyStr(LibraryRandom.RandText(MaxStrLen(YourReference)), 1, MaxStrLen(YourReference)); // Needed for filtering orders
        CreatePurchaseOrderWithoutVATAndWithYourReference(PurchaseHeader, YourReference);
        LibraryVariableStorage.Enqueue(PurchaseHeader."No.");

        // [GIVEN] Purchase Order "B" with VAT
        CreatePurchaseOrderWithVATAndYourReference(PurchaseHeader, YourReference);
        LibraryVariableStorage.Enqueue(PurchaseHeader."No.");

        // [GIVEN] Purchase Order "C" without VAT
        CreatePurchaseOrderWithoutVATAndWithYourReference(PurchaseHeader, YourReference);
        LibraryVariableStorage.Enqueue(PurchaseHeader."No.");

        // [GIVEN] Purchase Order "D" with VAT
        CreatePurchaseOrderWithVATAndYourReference(PurchaseHeader, YourReference);
        LibraryVariableStorage.Enqueue(PurchaseHeader."No.");

        // [WHEN] Open "Purchase Order List" page with SkipShowingLinesWithoutVAT = FALSE
        Clear(PurchaseHeader);
        OpenPurchaseOrdList(PurchaseHeader, false, YourReference);

        // [THEN] "Purchase Order List" contains purchase orders "A", "B", "C" and "D"
        // Verify purchase orders PurchaseOrderListAllOrdersVATPageHandler
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CashFlowWorksheetLineMoveDefaultDimToJnlLineDim()
    var
        DimensionValue: Record "Dimension Value";
        CashFlowWorksheetLine: Record "Cash Flow Worksheet Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimSetID: Integer;
        GLAccountNo: Code[20];
    begin
        // [FEATURE] [UT] [CashFlow]
        // [SCENARIO 352901] The "Cash Flow Worksheet Line".MoveDefaultDimToJnlLineDim must return correct Dimension Set ID when Dimension Value Code has max lenght.
        Initialize();

        // [GIVEN] "Dimension Value".Code = 'longnameofdimensionv'
        // [GIVEN] "G/L Account" with default dimension "Dimension Value"."Dimension Code"
        CreateGLAccountWithDefaultDimValue(DimensionValue, GLAccountNo);
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Shortcut Dimension 1 Code" := DimensionValue."Dimension Code";
        GeneralLedgerSetup.Modify();

        // [GIVEN] "Cash Flow Worksheet Line" with "Shortcut Dimension 1 Code"
        CashFlowWorksheetLine.Init();
        CashFlowWorksheetLine."Shortcut Dimension 1 Code" := DimensionValue."Dimension Code";

        // [WHEN] Invoke MoveDefualtDimToJnlLineDim
        CashFlowWorksheetLine.MoveDefualtDimToJnlLineDim(DATABASE::"G/L Account", GLAccountNo, DimSetID);

        // [THEN] Dimension Set ID must have non-zero value
        Assert.AreNotEqual(0, DimSetID, 'The Dimension Set ID must have non-zero value.');
    end;

    [Test]
    [HandlerFunctions('SuggestWorksheetLinesTaxesPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyCalculationForSourceTypeTax()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        Customer: Record Customer;
        GenJnlDocumentType: Enum "Gen. Journal Document Type";
        InvoiceAmount: array[3] of Decimal;
        CreditMemoAmount: Decimal;
        BalAccountNo: Code[20];
    begin
        // [SCENARIO 492129] Calculation error in cash flow for the source type tax (origin no. 254)
        Initialize();

        // [GIVEN] Create Customer
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Save amount
        InvoiceAmount[1] := LibraryRandom.RandDec(100, 2);
        InvoiceAmount[2] := LibraryRandom.RandDec(100, 2);
        InvoiceAmount[3] := LibraryRandom.RandDec(100, 2);
        CreditMemoAmount := -InvoiceAmount[1];

        // [GIVEN] Create BAl. Account No.
        BalAccountNo := LibraryERM.CreateGLAccountWithSalesSetup();

        // [GIVEN] Set today as WorkDate.
        WorkDate := CalcDate('<+5Y>', Today);

        // [GIVEN] Create General Journal Batch
        CreateGeneralJournalBatch(GenJournalBatch);

        // [GIVEN] Create four Sales Journal Line
        CreateSalesJournalLine(GenJournalLine, GenJournalBatch, GenJnlDocumentType::Invoice, Customer, BalAccountNo, InvoiceAmount[1]);
        CreateSalesJournalLine(GenJournalLine, GenJournalBatch, GenJnlDocumentType::"Credit Memo", Customer, BalAccountNo, CreditMemoAmount);
        CreateSalesJournalLine(GenJournalLine, GenJournalBatch, GenJnlDocumentType::Invoice, Customer, BalAccountNo, InvoiceAmount[2]);
        CreateSalesJournalLine(GenJournalLine, GenJournalBatch, GenJnlDocumentType::Invoice, Customer, BalAccountNo, InvoiceAmount[3]);

        // [THEN] Post Gen. Journal Line
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Create Cash Flow Forecast and run Suggest Line Worksheet Report
        CreateCashFlowForecastLine(CashFlowForecast);

        // [VERIFY] Verify Tax Entries
        VerifyTaxEntries(CashFlowForecast."No.", Customer."No.");
    end;

    [Test]
    [HandlerFunctions('SuggestWorksheetLinesProjectsPageHandler')]
    procedure VerifyCFWorksheetLinesCannotBeCreatedIfCFAccountNumberNotExist()
    var
        CashFlowAccount: Record "Cash Flow Account";
        CashFlowForecast: Record "Cash Flow Forecast";
        CashFlowSetup: Record "Cash Flow Setup";
        CashFlowWorksheetLine: Record "Cash Flow Worksheet Line";
        CashFlowWorksheet: TestPage "Cash Flow Worksheet";
    begin
        // [SCENARIO 591567] Verify Cash Flow Worksheet Lines cannot be created if the Cash Flow Account Number does not exist in the Chart of Cash Flow Accounts.
        Initialize();

        // [GIVEN] Create Cash Flow Chart of Account.
        CreateCashFlowChartOfAccount(CashFlowAccount);

        // [GIVEN] Create Cash Flow Forecast.
        LibraryCashFlowHelper.CreateCashFlowForecastDefault(CashFlowForecast);

        // [GIVEN] Set the 'Job CF Account No.' field value in the Cash Flow Setup.
        CashFlowSetup.Get();
        UpdateCashFlowSetup(CashFlowSetup, CashFlowAccount."No.");

        // [GIEVN] Open Cash Flow Worksheet.
        OpenCashFlowWorkSheet(CashFlowWorksheet, CashFlowForecast."No.");

        // [WHEN] 'Suggest Worksheet Lines' action was invoked from the Cash Flow Worksheet.
        CashFlowWorksheet.SuggestWorksheetLines.Invoke();
        CashFlowWorksheet.Close();

        // [THEN] Verify that Cash Flow Worksheet lines have been created and that the new Cash Flow Account No. exists.
        CashFlowWorksheetLine.SetRange("Cash Flow Forecast No.", CashFlowForecast."No.");
        CashFlowWorksheetLine.SetRange("Cash Flow Account No.", CashFlowAccount."No.");
        CashFlowWorksheetLine.FindFirst();
        Assert.AreEqual(
            CashFlowAccount."No.", CashFlowWorksheetLine."Cash Flow Account No.",
            StrSubstNo(
               ValueMustBeEqualErr, CashFlowWorksheetLine."Cash Flow Account No.",
               CashFlowAccount."No.", CashFlowWorksheetLine.TableCaption()));

        // [GIVEN] Delete the Cash Flow Account.
        CashFlowAccount.Delete(true);

        // [GIEVN] Open Cash Flow Worksheet.
        OpenCashFlowWorkSheet(CashFlowWorksheet, CashFlowForecast."No.");

        // [WHEN] 'Suggest Worksheet Lines' action was invoked from the Cash Flow Worksheet.
        // [THEN] An error occurs because the Cash Flow Account does not exist in the Cash Flow Account table.
        asserterror CashFlowWorksheet.SuggestWorksheetLines.Invoke();
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Cash Flow - Filling II");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        Evaluate(EmptyDateFormula, '<0D>');
        Evaluate(CustomDateFormula, '<0D>');
        // for boundary reasons
        Evaluate(PlusOneDayFormula, '<+1D>');
        Evaluate(MinusOneDayFormula, '<-1D>');

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Cash Flow - Filling II");

        LibraryPurchase.SetInvoiceRounding(false);
        LibrarySales.SetInvoiceRounding(false);
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateAccountInCustomerPostingGroup();
        LibraryERMCountryData.UpdateAccountInVendorPostingGroups();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        IsInitialized := true;
        Commit();
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Cash Flow - Filling II");
    end;

    local procedure CreateAndPostCashFlowForecast(var CashFlowForecast: Record "Cash Flow Forecast")
    var
        CashFlowWorksheetLine: Record "Cash Flow Worksheet Line";
    begin
        LibraryCashFlowHelper.CreateCashFlowForecastDefault(CashFlowForecast);
        Commit();  // Commit Required for REPORT.RUN.
        LibraryVariableStorage.Enqueue(CashFlowForecast."No.");  // Enqueue SuggestWorksheetLinesReqPageHandler.
        REPORT.Run(REPORT::"Suggest Worksheet Lines");
        CashFlowWorksheetLine.SetRange("Cash Flow Forecast No.", CashFlowForecast."No.");
        LibraryCashFlowForecast.PostJournalLines(CashFlowWorksheetLine);
    end;

    local procedure CreateAccountScheduleAndLine(var AccScheduleLine: Record "Acc. Schedule Line"; Totaling: Text[50]; RowNo: Code[10]; AccScheduleName: Code[10])
    begin
        LibraryERM.CreateAccScheduleLine(AccScheduleLine, AccScheduleName);
        AccScheduleLine.Validate("Row No.", RowNo);
        AccScheduleLine.Validate("Totaling Type", AccScheduleLine."Totaling Type"::"Cash Flow Entry Accounts");
        AccScheduleLine.Validate(Totaling, Totaling);
        AccScheduleLine.Modify(true);
    end;

    local procedure CreateColumnLayout(var ColumnLayout: Record "Column Layout")
    var
        ColumnLayoutName: Record "Column Layout Name";
    begin
        LibraryERM.CreateColumnLayoutName(ColumnLayoutName);
        LibraryERM.CreateColumnLayout(ColumnLayout, ColumnLayoutName.Name);
    end;

    local procedure ExecuteUIHandler()
    begin
        // Generate Dummy message. Required for executing the test case successfully.
        if Confirm(StrSubstNo(ExpectedMessageQst)) then;
    end;

    local procedure OpenAccountScheduleOverviewPage(LayoutName: Code[10])
    var
        AccountScheduleNames: TestPage "Financial Reports";
    begin
        AccountScheduleNames.OpenEdit();
        AccountScheduleNames.FILTER.SetFilter(Name, LayoutName);
        AccountScheduleNames.Overview.Invoke();
    end;

    local procedure UpdateAnalysisViewList(AnalysisViewCode: Code[10])
    var
        AnalysisViewList: TestPage "Analysis View List";
    begin
        AnalysisViewList.OpenView();
        AnalysisViewList.FILTER.SetFilter(Code, AnalysisViewCode);
        AnalysisViewList."&Update".Invoke();
        AnalysisViewList.EditAnalysis.Invoke();
    end;

    local procedure FillJournalWithoutGroupBy(ConsiderSource: array[16] of Boolean; CashFlowForecastNo: Code[20])
    begin
        LibraryCashFlowHelper.FillJournal(ConsiderSource, CashFlowForecastNo, false);
    end;

    local procedure FillJournalWithGroupBy(ConsiderSource: array[16] of Boolean; CashFlowForecastNo: Code[20])
    begin
        LibraryCashFlowHelper.FillJournal(ConsiderSource, CashFlowForecastNo, true);
    end;

    local procedure CreateCurrencyWithExchangeRate(RelationalExchangeRateAmount: Decimal): Code[10]
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        CreateExchangeRate(CurrencyExchangeRate, Currency.Code, 1.0, RelationalExchangeRateAmount);
        exit(Currency.Code);
    end;

    local procedure CreateCustomerWithPaymentTerms(PaymentTermsCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Terms Code", PaymentTermsCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerWithCurrency(CurrencyCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure ModifyCustomerWithCurrency(CustomerNo: Code[20]; CurrencyCode: Code[10])
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Modify(true);
    end;

    local procedure CreateCustomerWithCashFlowPaymentTerms(PaymentTermsCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Cash Flow Payment Terms Code", PaymentTermsCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure ModifyCustomerWithCashFlowPaymentTerms(CustomerNo: Code[20]; PaymentTermsCode: Code[10])
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        Customer.Validate("Cash Flow Payment Terms Code", PaymentTermsCode);
        Customer.Modify(true);
    end;

    local procedure CreateVendorWithPaymentTerms(PaymentTermsCode: Code[10]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Payment Terms Code", PaymentTermsCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateVendorWithCurrency(CurrencyCode: Code[10]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", CurrencyCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure ModifyVendorWithCurrency(VendorNo: Code[20]; CurrencyCode: Code[10])
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        Vendor.Validate("Currency Code", CurrencyCode);
        Vendor.Modify(true);
    end;

    local procedure CreateVendorWithCashFlowPaymentTerms(PaymentTermsCode: Code[10]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Cash Flow Payment Terms Code", PaymentTermsCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure ModifyVendorWithCashFlowPaymentTerms(VendorNo: Code[20]; PaymentTermsCode: Code[10])
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        Vendor.Validate("Cash Flow Payment Terms Code", PaymentTermsCode);
        Vendor.Modify(true);
    end;

    local procedure CreateSalesOrderWithLineCount(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; LineCount: Integer)
    var
        GLAccount: Record "G/L Account";
        "Count": Integer;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        GLAccount.Init();
        for Count := 1 to LineCount do
            LibraryCashFlowHelper.CreateSalesLine(SalesHeader, GLAccount);
    end;

    local procedure CreateAndPostSalesOrderWithOneLine(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]): Code[20]
    begin
        CreateSalesOrderWithLineCount(SalesHeader, CustomerNo, 1);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostSalesOrderWithDiscountPercentage(CustomerNo: Code[20]; PaymentTermsCode: Code[10]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesOrderWithLineCount(SalesHeader, CustomerNo, 1);
        SalesHeader.Validate("Payment Terms Code", PaymentTermsCode);
        SalesHeader.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateSalesOrderWithoutVATAndWithYourReference(var SalesHeader: Record "Sales Header"; YourReference: Text[35])
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        CreateVATPostingSetup(VATPostingSetup, false);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        SalesHeader."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        SalesHeader."Your Reference" := YourReference;
        SalesHeader.Modify();
    end;

    local procedure CreateSalesOrderWithVAT(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DummyGLAccount: Record "G/L Account";
    begin
        CreateVATPostingSetup(VATPostingSetup, true);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order,
          LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, DummyGLAccount."Gen. Posting Type"::Sale), 1);
        SalesLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrderWithVATAndYourReference(var SalesHeader: Record "Sales Header"; YourReference: Text[35])
    begin
        CreateSalesOrderWithVAT(SalesHeader);
        SalesHeader."Your Reference" := YourReference;
        SalesHeader.Modify();
    end;

    local procedure CreatePurchaseOrderWithLineCount(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; LineCount: Integer)
    var
        GLAccount: Record "G/L Account";
        "Count": Integer;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        GLAccount.Init();
        for Count := 1 to LineCount do
            LibraryCashFlowHelper.CreatePurchaseLine(PurchaseHeader, GLAccount);
    end;

    local procedure CreateAndPostPurchaseOrderWithOneLine(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]): Code[20]
    begin
        CreatePurchaseOrderWithLineCount(PurchaseHeader, VendorNo, 1);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateAndPostPurchaseOrderWithDiscountPercentage(VendorNo: Code[20]; PaymentTermsCode: Code[10]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseOrderWithLineCount(PurchaseHeader, VendorNo, 1);
        PurchaseHeader.Validate("Payment Terms Code", PaymentTermsCode);
        PurchaseHeader.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreatePurchaseOrderWithoutVATAndWithYourReference(var PurchaseHeader: Record "Purchase Header"; YourReference: Text[35])
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        CreateVATPostingSetup(VATPostingSetup, false);
        PurchaseHeader."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        PurchaseHeader."Your Reference" := YourReference;
        PurchaseHeader.Modify();
    end;

    local procedure CreatePurchaseOrderWithVAT(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DummyGLAccount: Record "G/L Account";
    begin
        CreateVATPostingSetup(VATPostingSetup, true);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order,
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, DummyGLAccount."Gen. Posting Type"::Purchase), 1);
        PurchaseLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1000, 2000, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseOrderWithVATAndYourReference(var PurchaseHeader: Record "Purchase Header"; YourReference: Text[35])
    begin
        CreatePurchaseOrderWithVAT(PurchaseHeader);
        PurchaseHeader."Your Reference" := YourReference;
        PurchaseHeader.Modify();
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; WithVat: Boolean)
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);
        if WithVat then
            VATPostingSetup.Validate("VAT %", LibraryRandom.RandIntInRange(10, 50));
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateServiceOrderWithLineCount(var ServiceHeader: Record "Service Header"; CustomerNo: Code[20]; LineCount: Integer)
    var
        "Count": Integer;
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CustomerNo);
        for Count := 1 to LineCount do
            LibraryService.CreateServiceLines(ServiceHeader);
    end;

    local procedure CreateExchangeRate(var CurrencyExchangeRate: Record "Currency Exchange Rate"; CurrencyCode: Code[10]; ExchangeRateAmount: Decimal; RelationalExchangeRateAmount: Decimal)
    var
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
    begin
        CurrencyExchangeRate.Init();
        CurrencyExchangeRate.Validate("Currency Code", CurrencyCode);
        CurrencyExchangeRate.Validate("Starting Date", LibraryFiscalYear.GetFirstPostingDate(true));
        CurrencyExchangeRate.Insert(true);

        CurrencyExchangeRate.Validate("Exchange Rate Amount", ExchangeRateAmount);
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", CurrencyExchangeRate."Exchange Rate Amount");

        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", RelationalExchangeRateAmount);
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", CurrencyExchangeRate."Relational Exch. Rate Amount");
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure CreateGLAccountWithDefaultDimValue(var DimensionValue: Record "Dimension Value"; var GLAccountNo: Code[20])
    var
        Dimension: Record Dimension;
        DefaultDimension: Record "Default Dimension";
    begin
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValueWithCode(
          DimensionValue,
          LibraryUtility.GenerateRandomCode20(DimensionValue.FieldNo(Code), DATABASE::"Dimension Value"),
          Dimension.Code);
        LibraryDimension.CreateDefaultDimensionGLAcc(DefaultDimension, GLAccountNo, Dimension.Code, DimensionValue.Code);
    end;

    local procedure GetNumberOfSalesLines(SalesHeader: Record "Sales Header"): Integer
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        exit(SalesLine.Count);
    end;

    local procedure GetNumberOfPurchaseLines(PurchaseHeader: Record "Purchase Header"): Integer
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        exit(PurchaseLine.Count);
    end;

    local procedure GetNumberOfServiceLines(ServiceHeader: Record "Service Header"): Integer
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        exit(ServiceLine.Count);
    end;

    local procedure OpenSalesOrderList(SalesHeader: Record "Sales Header"; SkipShowingLinesWithoutVAT: Boolean)
    var
        SalesOrderList: Page "Sales Order List";
    begin
        SalesHeader.SetRecFilter();
        Clear(SalesOrderList);
        if SkipShowingLinesWithoutVAT then
            SalesOrderList.SkipShowingLinesWithoutVAT();
        SalesOrderList.SetTableView(SalesHeader);
        SalesOrderList.Run();
    end;

    local procedure OpenSalesOrdList(SalesHeader: Record "Sales Header"; SkipShowingLinesWithoutVAT: Boolean; YourReference: Text[35])
    var
        CashFlowManagement: Codeunit "Cash Flow Management";
        SalesOrderList: Page "Sales Order List";
    begin
        CashFlowManagement.SetViewOnSalesHeaderForTaxCalc(
          SalesHeader, CalcDate(StrSubstNo('<%1D>', LibraryRandom.RandIntInRange(5, 10)), WorkDate()));
        SalesHeader.SetFilter("Your Reference", YourReference);
        Clear(SalesOrderList);
        if SkipShowingLinesWithoutVAT then
            SalesOrderList.SkipShowingLinesWithoutVAT();
        SalesOrderList.SetTableView(SalesHeader);
        SalesOrderList.Run();
    end;

    local procedure OpenPurchaseOrderList(PurchaseHeader: Record "Purchase Header"; SkipShowingLinesWithoutVAT: Boolean)
    var
        PurchaseOrderList: Page "Purchase Order List";
    begin
        PurchaseHeader.SetRecFilter();
        Clear(PurchaseOrderList);
        if SkipShowingLinesWithoutVAT then
            PurchaseOrderList.SkipShowingLinesWithoutVAT();
        PurchaseOrderList.SetTableView(PurchaseHeader);
        PurchaseOrderList.Run();
    end;

    local procedure OpenPurchaseOrdList(PurchaseHeader: Record "Purchase Header"; SkipShowingLinesWithoutVAT: Boolean; YourReference: Text[35])
    var
        CashFlowManagement: Codeunit "Cash Flow Management";
        PurchaseOrderList: Page "Purchase Order List";
    begin
        CashFlowManagement.SetViewOnPurchaseHeaderForTaxCalc(
          PurchaseHeader, CalcDate(StrSubstNo('<%1D>', LibraryRandom.RandIntInRange(5, 10)), WorkDate()));
        PurchaseHeader.SetFilter("Your Reference", YourReference);
        Clear(PurchaseOrderList);
        if SkipShowingLinesWithoutVAT then
            PurchaseOrderList.SkipShowingLinesWithoutVAT();
        PurchaseOrderList.SetTableView(PurchaseHeader);
        PurchaseOrderList.Run();
    end;

    local procedure VerifyCFWorksheetLineAmount(CashFlowForecastNo: Code[20]; DocumentNo: Code[20]; SourceType: Enum "Cash Flow Source Type"; ExpectedAmount: Decimal; ErrorText: Text[150])
    var
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
    begin
        LibraryCashFlowHelper.FilterSingleJournalLine(CFWorksheetLine, DocumentNo, SourceType, CashFlowForecastNo);
        Assert.AreEqual(ExpectedAmount, CFWorksheetLine."Amount (LCY)", ErrorText);
    end;

    local procedure VerifyExpectedCFAmount(ExpectedAmount: Decimal; DocumentNo: Code[20]; SourceType: Enum "Cash Flow Source Type"; CashFlowNo: Code[20])
    var
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        TotalAmount: Decimal;
    begin
        CFWorksheetLine.SetFilter("Cash Flow Forecast No.", '%1', CashFlowNo);
        CFWorksheetLine.SetFilter("Document No.", '%1', DocumentNo);
        CFWorksheetLine.SetFilter("Source Type", '%1', SourceType);
        TotalAmount := 0;
        repeat
            TotalAmount += CFWorksheetLine."Amount (LCY)";
        until CFWorksheetLine.Next() = 0;
        LibraryCashFlowHelper.VerifyExpectedCFAmount(ExpectedAmount, TotalAmount);
    end;

    local procedure CreateCashFlowForecastLine(var CashFlowForecast: Record "Cash Flow Forecast")
    begin
        LibraryCashFlowHelper.CreateCashFlowForecastDefault(CashFlowForecast);
        Commit();  // Commit Required for REPORT.RUN.
        LibraryVariableStorage.Enqueue(CashFlowForecast."No.");  // Enqueue SuggestWorksheetLinesReqPageHandler.
        REPORT.Run(REPORT::"Suggest Worksheet Lines");
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateSalesJournalLine(
        var GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJnlDocumentType: Enum "Gen. Journal Document Type";
        Customer: Record Customer;
        BalAccountNo: Code[20];
        Amount: Decimal)
    begin
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJnlDocumentType, GenJournalLine."Account Type"::Customer, Customer."No.",
          Amount);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Modify(true);
    end;

    local procedure VerifyTaxEntries(CashFlowForecastNo: Code[20]; CustomerNo: Code[20])
    var
        CashFlowWorksheetLine: Record "Cash Flow Worksheet Line";
        VatEntry: Record "VAT Entry";
    begin
        CashFlowWorksheetLine.SetRange("Cash Flow Forecast No.", CashFlowForecastNo);
        CashFlowWorksheetLine.SetRange("Source No.", '254');
        CashFlowWorksheetLine.SetRange(Description, DescriptionTxt);
        CashFlowWorksheetLine.FindFirst();

        Assert.AreEqual(0, CashFlowWorksheetLine."Amount (LCY)", AmountZeroErr);

        VatEntry.SetRange("Bill-to/Pay-to No.", CustomerNo);
        VatEntry.CalcSums(Amount);

        CashFlowWorksheetLine.Next();
        Assert.AreEqual(VatEntry.Amount, CashFlowWorksheetLine."Amount (LCY)", TaxAmountErr);
    end;

    local procedure CreateCashFlowChartOfAccount(var CashFlowAccount: Record "Cash Flow Account")
    begin
        LibraryCashFlowForecast.CreateCashFlowAccount(CashFlowAccount, CashFlowAccount."Account Type"::Entry);
        CashFlowAccount.Validate("Source Type", CashFlowAccount."Source Type"::Job);
        CashFlowAccount.Modify(true);
    end;

    local procedure UpdateCashFlowSetup(var CashFlowSetup: Record "Cash Flow Setup"; CashFlowAccNo: Code[20])
    begin
        CashFlowSetup.Validate("Job CF Account No.", CashFlowAccNo);
        CashFlowSetup.Modify(true);
    end;

    local procedure OpenCashFlowWorkSheet(var CashFlowWorksheet: TestPage "Cash Flow Worksheet"; CashFlowForecastNo: Code[20])
    begin
        LibraryVariableStorage.Enqueue(CashFlowForecastNo);  // Enqueue SuggestWorksheetLinesReqPageHandler.
        CashFlowWorksheet.OpenEdit();
        Commit();  // Commit Required for Report.Run
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure AccountScheduleOverviewPageHandler(var AccScheduleOverview: TestPage "Acc. Schedule Overview")
    var
        CashFlowForcastNo: Variant;
        ColumnLayout: Variant;
        ViewBy: Option Day,Week,Month;
    begin
        AccScheduleOverview.PeriodTypeDefault.SetValue(Format(ViewBy::Day));
        LibraryVariableStorage.Dequeue(ColumnLayout);
        LibraryVariableStorage.Dequeue(CashFlowForcastNo);
        AccScheduleOverview.CurrentColumnName.SetValue(ColumnLayout);
        AccScheduleOverview.CashFlowFilter.SetValue(CashFlowForcastNo);
        AccScheduleOverview.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure AnalysisByDimensionsHandler(var AnalysisbyDimensions: TestPage "Analysis by Dimensions")
    var
        CashFlowFilter: Variant;
        PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
    begin
        LibraryVariableStorage.Dequeue(CashFlowFilter);
        AnalysisbyDimensions.PeriodType.SetValue(Format(PeriodType::Month));
        AnalysisbyDimensions.CashFlowFilter.SetValue(CashFlowFilter);
        AnalysisbyDimensions.ShowMatrix.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AnalysisByDimensionsMatrixHandler(var AnalysisByDimensionsMatrix: TestPage "Analysis by Dimensions Matrix")
    begin
        AnalysisByDimensionsMatrix.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Msg: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestWorksheetLinesReqPageHandler(var SuggestWorksheetLines: TestRequestPage "Suggest Worksheet Lines")
    var
        CashFlowNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(CashFlowNo);
        SuggestWorksheetLines.CashFlowNo.SetValue(CashFlowNo);
        SuggestWorksheetLines."ConsiderSource[SourceType::""Service Orders""]".SetValue(true);
        SuggestWorksheetLines."ConsiderSource[SourceType::""Liquid Funds""]".SetValue(true);  // Liquid Funds.
        SuggestWorksheetLines."ConsiderSource[SourceType::Receivables]".SetValue(true);  // Receivables.
        SuggestWorksheetLines."ConsiderSource[SourceType::Payables]".SetValue(true);  // Payables.
        SuggestWorksheetLines."ConsiderSource[SourceType::""Purchase Order""]".SetValue(true);  // Purchase Order.
        SuggestWorksheetLines."ConsiderSource[SourceType::""Cash Flow Manual Revenue""]".SetValue(true);  // Cash Flow Manual Revenue.
        SuggestWorksheetLines."ConsiderSource[SourceType::""Sales Order""]".SetValue(true);  // Sales Order.
        SuggestWorksheetLines."ConsiderSource[SourceType::""Budgeted Fixed Asset""]".SetValue(true);  // Budgeted Fixed Asset.
        SuggestWorksheetLines."ConsiderSource[SourceType::""Cash Flow Manual Expense""]".SetValue(true);  // Cash Flow Manual Expense.
        SuggestWorksheetLines."ConsiderSource[SourceType::""Sale of Fixed Asset""]".SetValue(true);  // Sale of Fixed Asset.
        SuggestWorksheetLines."ConsiderSource[SourceType::""G/L Budget""]".SetValue(true);  // G/L Budget.
        SuggestWorksheetLines.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestWorksheetLinesReqLiquidFundsPageHandler(var SuggestWorksheetLines: TestRequestPage "Suggest Worksheet Lines")
    var
        CashFlowNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(CashFlowNo);
        SuggestWorksheetLines.CashFlowNo.SetValue(CashFlowNo);
        SuggestWorksheetLines."ConsiderSource[SourceType::""Liquid Funds""]".SetValue(true);  // Liquid Funds.

        SuggestWorksheetLines."ConsiderSource[SourceType::""Service Orders""]".SetValue(false);
        SuggestWorksheetLines."ConsiderSource[SourceType::Receivables]".SetValue(false);  // Receivables.
        SuggestWorksheetLines."ConsiderSource[SourceType::Payables]".SetValue(false);  // Payables.
        SuggestWorksheetLines."ConsiderSource[SourceType::""Purchase Order""]".SetValue(false);  // Purchase Order.
        SuggestWorksheetLines."ConsiderSource[SourceType::""Cash Flow Manual Revenue""]".SetValue(false);  // Cash Flow Manual Revenue.
        SuggestWorksheetLines."ConsiderSource[SourceType::""Sales Order""]".SetValue(false);  // Sales Order.
        SuggestWorksheetLines."ConsiderSource[SourceType::""Budgeted Fixed Asset""]".SetValue(false);  // Budgeted Fixed Asset.
        SuggestWorksheetLines."ConsiderSource[SourceType::""Cash Flow Manual Expense""]".SetValue(false);  // Cash Flow Manual Expense.
        SuggestWorksheetLines."ConsiderSource[SourceType::""Sale of Fixed Asset""]".SetValue(false);  // Sale of Fixed Asset.
        SuggestWorksheetLines."ConsiderSource[SourceType::""G/L Budget""]".SetValue(false);  // G/L Budget.
        SuggestWorksheetLines.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestWorksheetLinesTaxesPageHandler(var SuggestWorksheetLines: TestRequestPage "Suggest Worksheet Lines")
    var
        CashFlowNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(CashFlowNo);
        SuggestWorksheetLines.CashFlowNo.SetValue(CashFlowNo);
        SuggestWorksheetLines."ConsiderSource[SourceType::Tax]".SetValue(true);

        SuggestWorksheetLines."ConsiderSource[SourceType::""Liquid Funds""]".SetValue(false);  // Liquid Funds
        SuggestWorksheetLines."ConsiderSource[SourceType::""Service Orders""]".SetValue(false);
        SuggestWorksheetLines."ConsiderSource[SourceType::Receivables]".SetValue(false);  // Receivables.
        SuggestWorksheetLines."ConsiderSource[SourceType::Payables]".SetValue(false);  // Payables.
        SuggestWorksheetLines."ConsiderSource[SourceType::""Purchase Order""]".SetValue(false);  // Purchase Order.
        SuggestWorksheetLines."ConsiderSource[SourceType::""Cash Flow Manual Revenue""]".SetValue(false);  // Cash Flow Manual Revenue.
        SuggestWorksheetLines."ConsiderSource[SourceType::""Sales Order""]".SetValue(false);  // Sales Order.
        SuggestWorksheetLines."ConsiderSource[SourceType::""Budgeted Fixed Asset""]".SetValue(false);  // Budgeted Fixed Asset.
        SuggestWorksheetLines."ConsiderSource[SourceType::""Cash Flow Manual Expense""]".SetValue(false);  // Cash Flow Manual Expense.
        SuggestWorksheetLines."ConsiderSource[SourceType::""Sale of Fixed Asset""]".SetValue(false);  // Sale of Fixed Asset.
        SuggestWorksheetLines."ConsiderSource[SourceType::""G/L Budget""]".SetValue(false);  // G/L Budget.
        SuggestWorksheetLines.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderListPageHandler(var SalesOrderList: TestPage "Sales Order List")
    begin
        SalesOrderList."No.".AssertEquals(LibraryVariableStorage.DequeueText());
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderListPageHandler(var PurchaseOrderList: TestPage "Purchase Order List")
    begin
        PurchaseOrderList."No.".AssertEquals(LibraryVariableStorage.DequeueText());
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderListWithVATPageHandler(var SalesOrderList: TestPage "Sales Order List")
    begin
        SalesOrderList."No.".AssertEquals(LibraryVariableStorage.DequeueText());
        SalesOrderList.Next();
        SalesOrderList."No.".AssertEquals(LibraryVariableStorage.DequeueText());
        SalesOrderList.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderListAllOrdersVATPageHandler(var SalesOrderList: TestPage "Sales Order List")
    begin
        SalesOrderList."No.".AssertEquals(LibraryVariableStorage.DequeueText());
        SalesOrderList.Next();
        SalesOrderList."No.".AssertEquals(LibraryVariableStorage.DequeueText());
        SalesOrderList.Next();
        SalesOrderList."No.".AssertEquals(LibraryVariableStorage.DequeueText());
        SalesOrderList.Next();
        SalesOrderList."No.".AssertEquals(LibraryVariableStorage.DequeueText());
        SalesOrderList.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderListWithVATPageHandler(var PurchaseOrderList: TestPage "Purchase Order List")
    begin
        PurchaseOrderList."No.".AssertEquals(LibraryVariableStorage.DequeueText());
        PurchaseOrderList.Next();
        PurchaseOrderList."No.".AssertEquals(LibraryVariableStorage.DequeueText());
        PurchaseOrderList.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderListAllOrdersVATPageHandler(var PurchaseOrderList: TestPage "Purchase Order List")
    begin
        PurchaseOrderList."No.".AssertEquals(LibraryVariableStorage.DequeueText());
        PurchaseOrderList.Next();
        PurchaseOrderList."No.".AssertEquals(LibraryVariableStorage.DequeueText());
        PurchaseOrderList.Next();
        PurchaseOrderList."No.".AssertEquals(LibraryVariableStorage.DequeueText());
        PurchaseOrderList.Next();
        PurchaseOrderList."No.".AssertEquals(LibraryVariableStorage.DequeueText());
        PurchaseOrderList.Close();
    end;

    [RequestPageHandler]
    procedure SuggestWorksheetLinesProjectsPageHandler(var SuggestWorksheetLines: TestRequestPage "Suggest Worksheet Lines")
    var
        CashFlowAccountNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(CashFlowAccountNo);
        SuggestWorksheetLines.CashFlowNo.SetValue(CashFlowAccountNo);
        SuggestWorksheetLines."ConsiderSource[SourceType::Job]".SetValue(true);  // Jobs/Projects

        SuggestWorksheetLines."ConsiderSource[SourceType::Tax]".SetValue(false);  // Tax
        SuggestWorksheetLines."ConsiderSource[SourceType::""Liquid Funds""]".SetValue(false);  // Liquid Funds
        SuggestWorksheetLines."ConsiderSource[SourceType::""Service Orders""]".SetValue(false);
        SuggestWorksheetLines."ConsiderSource[SourceType::Receivables]".SetValue(false);  // Receivables.
        SuggestWorksheetLines."ConsiderSource[SourceType::Payables]".SetValue(false);  // Payables.
        SuggestWorksheetLines."ConsiderSource[SourceType::""Purchase Order""]".SetValue(false);  // Purchase Order.
        SuggestWorksheetLines."ConsiderSource[SourceType::""Cash Flow Manual Revenue""]".SetValue(false);  // Cash Flow Manual Revenue.
        SuggestWorksheetLines."ConsiderSource[SourceType::""Sales Order""]".SetValue(false);  // Sales Order.
        SuggestWorksheetLines."ConsiderSource[SourceType::""Budgeted Fixed Asset""]".SetValue(false);  // Budgeted Fixed Asset.
        SuggestWorksheetLines."ConsiderSource[SourceType::""Cash Flow Manual Expense""]".SetValue(false);  // Cash Flow Manual Expense.
        SuggestWorksheetLines."ConsiderSource[SourceType::""Sale of Fixed Asset""]".SetValue(false);  // Sale of Fixed Asset.
        SuggestWorksheetLines."ConsiderSource[SourceType::""G/L Budget""]".SetValue(false);  // G/L Budget.
        SuggestWorksheetLines.OK().Invoke();
    end;
}

