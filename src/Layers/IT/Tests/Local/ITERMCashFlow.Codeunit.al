codeunit 144022 "IT - ERM Cash Flow"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryCashFlowHelper: Codeunit "Library - Cash Flow Helper";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        SourceType: Option " ",Receivables,Payables,"Liquid Funds","Cash Flow Manual Expense","Cash Flow Manual Revenue","Sales Orders","Purchase Orders","Fixed Assets Budget","Fixed Assets Disposal","Service Orders","G/L Budget",,,Job,Tax;
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure FillCFJnlWithSOMultiplePaymentLines()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        SalesHeader: Record "Sales Header";
        PaymentTerms: Record "Payment Terms";
        PaymentLines1: Record "Payment Lines";
        PaymentLines2: Record "Payment Lines";
        TotalAmount: Decimal;
        ConsiderSource: array[16] of Boolean;
    begin
        // Fill CF Journal with a Sales Order whose customer has Payment Terms with multiple Payment Lines
        // The order must be splitted based on the payment terms settings

        // Setup
        Initialize();
        LibraryCashFlowHelper.CreateCashFlowForecastConsiderDiscount(CashFlowForecast);
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        SetupPaymentLine(PaymentLines1, PaymentTerms.Code, 10, LibraryRandom.RandDec(90, 2), LibraryRandom.RandInt(3));
        SetupPaymentLine(PaymentLines2, PaymentTerms.Code, 20, 100.0 - PaymentLines1."Payment %", LibraryRandom.RandIntInRange(4, 7));
        // Sales order
        LibraryCashFlowHelper.CreateSpecificSalesOrder(SalesHeader, PaymentTerms.Code);

        // Exercise
        ConsiderSource[SourceType::"Sales Orders"] := true;
        FillJournalWithGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify
        TotalAmount := LibraryCashFlowHelper.GetTotalSalesAmount(SalesHeader, false);
        // Check for first splitted line
        VerifySplittedPaymentLinesOnCFJnl(CashFlowForecast."No.", SalesHeader."No.", SourceType::"Sales Orders",
          CalcDate(PaymentLines1."Discount Date Calculation", SalesHeader."Document Date"),
          CalculatePercentageAmount(TotalAmount, PaymentLines1."Payment %"));
        // and for second splitted line
        VerifySplittedPaymentLinesOnCFJnl(CashFlowForecast."No.", SalesHeader."No.", SourceType::"Sales Orders",
          CalcDate(PaymentLines2."Discount Date Calculation", SalesHeader."Document Date"),
          CalculatePercentageAmount(TotalAmount, PaymentLines2."Payment %"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillCFJnlWithPOMultiplePaymentLines()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        PurchaseHeader: Record "Purchase Header";
        PaymentTerms: Record "Payment Terms";
        PaymentLines1: Record "Payment Lines";
        PaymentLines2: Record "Payment Lines";
        TotalAmount: Decimal;
        ConsiderSource: array[16] of Boolean;
    begin
        // Fill CF Journal with a Purchase Order whos vendor has Payment Terms with multiple Payment Lines
        // The order must be splitted based on the payment terms settings

        // Setup
        Initialize();
        LibraryCashFlowHelper.CreateCashFlowForecastConsiderDiscount(CashFlowForecast);
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        SetupPaymentLine(PaymentLines1, PaymentTerms.Code, 10, LibraryRandom.RandDec(90, 2), LibraryRandom.RandInt(3));
        SetupPaymentLine(PaymentLines2, PaymentTerms.Code, 20, 100.0 - PaymentLines1."Payment %", LibraryRandom.RandIntInRange(5, 10));
        LibraryCashFlowHelper.CreateSpecificPurchaseOrder(PurchaseHeader, PaymentTerms.Code);

        // Exercise
        ConsiderSource[SourceType::"Purchase Orders"] := true;
        FillJournalWithGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify
        TotalAmount := LibraryCashFlowHelper.GetTotalPurchaseAmount(PurchaseHeader, false);
        // Check for first splitted line
        VerifySplittedPaymentLinesOnCFJnl(CashFlowForecast."No.", PurchaseHeader."No.", SourceType::"Purchase Orders",
          CalcDate(PaymentLines1."Discount Date Calculation", PurchaseHeader."Document Date"),
          -CalculatePercentageAmount(TotalAmount, PaymentLines1."Payment %"));
        // and for second splitted line
        VerifySplittedPaymentLinesOnCFJnl(CashFlowForecast."No.", PurchaseHeader."No.", SourceType::"Purchase Orders",
          CalcDate(PaymentLines2."Discount Date Calculation", PurchaseHeader."Document Date"),
          -CalculatePercentageAmount(TotalAmount, PaymentLines2."Payment %"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillCFJnlWithCustLEMultiplePaymentLines()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        PaymentLines1: Record "Payment Lines";
        PaymentLines2: Record "Payment Lines";
        ConsiderSource: array[16] of Boolean;
    begin
        // Fill CF Journal with customer ledger entries whos vendor has Payment Terms with multiple Payment Lines
        // The order must be splitted based on the payment terms settings

        // Setup
        Initialize();
        LibraryCashFlowHelper.CreateCashFlowForecastConsiderDiscount(CashFlowForecast);
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        SetupPaymentLine(PaymentLines1, PaymentTerms.Code, 10, LibraryRandom.RandDec(100, 1), LibraryRandom.RandInt(3));
        SetupPaymentLine(PaymentLines2, PaymentTerms.Code, 20, 100.0 - PaymentLines1."Payment %", LibraryRandom.RandIntInRange(5, 10));
        LibrarySales.CreateCustomer(Customer);
        LibraryCashFlowHelper.AssignPaymentTermToCustomer(Customer, PaymentTerms.Code);
        LibraryCashFlowHelper.CreateLedgerEntry(GenJournalLine, Customer."No.", LibraryRandom.RandDec(1000, 2),
          GenJournalLine."Account Type"::Customer, GenJournalLine."Document Type"::Invoice);

        // Exercise
        ConsiderSource[SourceType::Receivables] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify
        // Check for first splitted line
        VerifySplittedPaymentLinesOnCFJnl(CashFlowForecast."No.", GenJournalLine."Document No.", SourceType::Receivables,
          CalcDate(PaymentLines1."Discount Date Calculation", GenJournalLine."Posting Date"),
          CalculatePercentageAmount(GenJournalLine.Amount, PaymentLines1."Payment %"));
        // and for second splitted line
        VerifySplittedPaymentLinesOnCFJnl(CashFlowForecast."No.", GenJournalLine."Document No.", SourceType::Receivables,
          CalcDate(PaymentLines2."Discount Date Calculation", GenJournalLine."Posting Date"),
          CalculatePercentageAmount(GenJournalLine.Amount, PaymentLines2."Payment %"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillCFJnlWithVendLEMultiplePaymentLines()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        PaymentLines1: Record "Payment Lines";
        PaymentLines2: Record "Payment Lines";
        ConsiderSource: array[16] of Boolean;
    begin
        // Fill CF Journal with vendor ledger entries whos vendor has Payment Terms with multiple Payment Lines
        // The order must be splitted based on the payment terms settings

        // Setup
        Initialize();
        LibraryCashFlowHelper.CreateCashFlowForecastConsiderDiscount(CashFlowForecast);
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        SetupPaymentLine(PaymentLines1, PaymentTerms.Code, 10, LibraryRandom.RandDec(100, 1), LibraryRandom.RandInt(3));
        SetupPaymentLine(PaymentLines2, PaymentTerms.Code, 20, 100.0 - PaymentLines1."Payment %", LibraryRandom.RandIntInRange(5, 10));
        LibraryPurchase.CreateVendor(Vendor);
        LibraryCashFlowHelper.AssignPaymentTermToVendor(Vendor, PaymentTerms.Code);
        LibraryCashFlowHelper.CreateLedgerEntry(GenJournalLine, Vendor."No.", -LibraryRandom.RandDec(1000, 2),
          GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::Invoice);

        // Exercise
        ConsiderSource[SourceType::Payables] := true;
        FillJournalWithoutGroupBy(ConsiderSource, CashFlowForecast."No.");

        // Verify
        // Check for first splitted line
        VerifySplittedPaymentLinesOnCFJnl(CashFlowForecast."No.", GenJournalLine."Document No.", SourceType::Payables,
          CalcDate(PaymentLines1."Discount Date Calculation", GenJournalLine."Posting Date"),
          CalculatePercentageAmount(GenJournalLine.Amount, PaymentLines1."Payment %"));
        // and for second splitted line
        VerifySplittedPaymentLinesOnCFJnl(CashFlowForecast."No.", GenJournalLine."Document No.", SourceType::Payables,
          CalcDate(PaymentLines2."Discount Date Calculation", GenJournalLine."Posting Date"),
          CalculatePercentageAmount(GenJournalLine.Amount, PaymentLines2."Payment %"));
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        if IsInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        IsInitialized := true;
        Commit();
    end;

    local procedure CalculatePercentageAmount(TotalAmount: Decimal; Percentage: Decimal): Decimal
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        exit(Round(TotalAmount / 100 * Percentage, GLSetup."Amount Rounding Precision"));
    end;

    local procedure CreatePaymentLine(var PaymentLines: Record "Payment Lines"; PaymentTermsCode: Code[20]; LineNo: Integer; PaymentPercentage: Decimal; DiscountDateCalculation: DateFormula)
    begin
        PaymentLines.Init();
        PaymentLines.Validate(Type, PaymentLines.Type::"Payment Terms");
        PaymentLines.Validate(Code, PaymentTermsCode);
        PaymentLines.Validate("Line No.", LineNo);
        PaymentLines.Validate("Payment %", PaymentPercentage);
        PaymentLines.Validate("Discount Date Calculation", DiscountDateCalculation);
        PaymentLines.SetRange(Code, PaymentLines.Code);
        PaymentLines.SetRange(Type, PaymentLines.Type);
        PaymentLines.Insert(true);
    end;

    local procedure FillJournalWithGroupBy(ConsiderSource: array[16] of Boolean; CashFlowForecastNo: Code[20])
    begin
        LibraryCashFlowHelper.FillJournal(ConsiderSource, CashFlowForecastNo, true);
    end;

    local procedure FillJournalWithoutGroupBy(ConsiderSource: array[16] of Boolean; CashFlowForecastNo: Code[20])
    begin
        LibraryCashFlowHelper.FillJournal(ConsiderSource, CashFlowForecastNo, false);
    end;

    local procedure SetupPaymentLine(var PaymentLines: Record "Payment Lines"; PaymentTermsCode: Code[20]; LineNo: Integer; PaymentPercentage: Decimal; DiscountDateDelta: Integer)
    var
        DiscountDateCalculation: DateFormula;
    begin
        Evaluate(DiscountDateCalculation, '<' + Format(DiscountDateDelta) + 'D>');
        CreatePaymentLine(PaymentLines, PaymentTermsCode, LineNo, PaymentPercentage, DiscountDateCalculation);
    end;

    local procedure VerifySplittedPaymentLinesOnCFJnl(CashFlowNo: Code[20]; DocumentNo: Code[20]; SourceType: Option; ExpectedCFDate: Date; ExpectedCFAmount: Decimal)
    var
        CashFlowWorksheetLine: Record "Cash Flow Worksheet Line";
    begin
        CashFlowWorksheetLine.SetFilter("Cash Flow Forecast No.", '%1', CashFlowNo);
        CashFlowWorksheetLine.SetFilter("Document No.", '%1', DocumentNo);
        CashFlowWorksheetLine.SetFilter("Source Type", '%1', SourceType);
        CashFlowWorksheetLine.SetFilter("Cash Flow Date", '%1', ExpectedCFDate);
        CashFlowWorksheetLine.SetFilter("Amount (LCY)", '%1', ExpectedCFAmount);
        Assert.RecordIsNotEmpty(CashFlowWorksheetLine);
    end;
}

