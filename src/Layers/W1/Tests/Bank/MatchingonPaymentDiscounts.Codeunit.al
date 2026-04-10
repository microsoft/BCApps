codeunit 134269 "Matching on Payment Discounts"
{
    Permissions = TableData "Cust. Ledger Entry" = imd,
                  TableData "Vendor Ledger Entry" = imd;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Bank Reconciliation] [Match] [Payment Discount]
    end;

    var
        ZeroVATPostingSetup: Record "VAT Posting Setup";
        PaymentTermsDiscount: Record "Payment Terms";
        PaymentTermsNoDiscount: Record "Payment Terms";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        LinesAreAppliedTxt: Label 'are applied';

    local procedure Initialize()
    var
        InventorySetup: Record "Inventory Setup";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        AppliedPaymentEntry: Record "Applied Payment Entry";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Matching on Payment Discounts");

        LibraryVariableStorage.Clear();
        BankAccReconciliation.DeleteAll(true);
        BankAccReconciliationLine.DeleteAll(true);
        AppliedPaymentEntry.DeleteAll(true);
        CloseExistingEntries();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Matching on Payment Discounts");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryInventory.NoSeriesSetup(InventorySetup);
        LibraryERM.FindZeroVATPostingSetup(ZeroVATPostingSetup, ZeroVATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryERM.CreatePaymentTerms(PaymentTermsNoDiscount);
        LibraryERM.CreatePaymentTermsDiscount(PaymentTermsDiscount, false);
        Commit();
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Matching on Payment Discounts");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CustomerPaidDiscountedAmountOnTime()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        AppliedPaymentEntry: Record "Applied Payment Entry";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        AppliedAmount: Decimal;
        DiscountedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
        NoOfEntriesWithinRange: Integer;
        NoOfEntriesOutsideRange: Integer;
    begin
        Initialize();

        // Setup
        Amount := LibraryRandom.RandDecInRange(1, 10000, 2);

        CreateAndPostSalesInvoiceWithOneLine(CustLedgerEntry, Amount, '', true);
        CreateBankReconciliation(BankAccReconciliation);

        DiscountedAmount := CustLedgerEntry."Remaining Amount" - CustLedgerEntry."Remaining Pmt. Disc. Possible";
        CreateBankReconciliationLine(
          BankAccReconciliationLine,
          BankAccReconciliation, DiscountedAmount,
          CustLedgerEntry."Pmt. Discount Date", CustLedgerEntry."Document No.");

        // Excercise
        RunMatch(TempBankStatementMatchingBuffer, BankAccReconciliation, true);

        // Verify Payment was matched and discount was applied
        GetMatchConfidence(
          BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes, BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match");

        Difference := 0;
        AppliedAmount := Amount;
        NoOfEntries := 1;
        VerifyBankAccReconcilationLine(BankAccReconciliationLine, DiscountedAmount, Difference, NoOfEntries);
        GetAppliedPaymentEntries(AppliedPaymentEntry, BankAccReconciliationLine);
        VerifyAppliedEntries(
          AppliedPaymentEntry, BankPmtApplRule, AppliedAmount, CustLedgerEntry."Remaining Pmt. Disc. Possible", CustLedgerEntry."Entry No.");

        NoOfEntriesWithinRange := 1;
        NoOfEntriesOutsideRange := 0;
        VerifyNoOfEntriesWithingAndOutsideToleranceRangeForCustomer(
          BankPmtApplRule, BankAccReconciliationLine, NoOfEntriesWithinRange, NoOfEntriesOutsideRange, CustLedgerEntry."Entry No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CustomerPaidDiscountedAmountAfterDiscountDate()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        AppliedPaymentEntry: Record "Applied Payment Entry";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        AppliedAmount: Decimal;
        DiscountedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
        NoOfEntriesWithinRange: Integer;
        NoOfEntriesOutsideRange: Integer;
    begin
        Initialize();

        // Setup
        Amount := LibraryRandom.RandDecInRange(1, 10000, 2);

        CreateAndPostSalesInvoiceWithOneLine(CustLedgerEntry, Amount, '', true);
        CreateBankReconciliation(BankAccReconciliation);

        DiscountedAmount := CustLedgerEntry."Remaining Amount" - CustLedgerEntry."Remaining Pmt. Disc. Possible";
        CreateBankReconciliationLine(
          BankAccReconciliationLine, BankAccReconciliation, DiscountedAmount,
          CalcDate('<+1D>', CustLedgerEntry."Pmt. Discount Date"),
          CustLedgerEntry."Document No.");

        // Excercise
        RunMatch(TempBankStatementMatchingBuffer, BankAccReconciliation, true);

        // Verify no match on the amount, amount is out of range, no discount was assigned
        GetMatchConfidence(
          BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No, BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");

        Difference := 0;
        AppliedAmount := DiscountedAmount;
        NoOfEntries := 1;
        VerifyBankAccReconcilationLine(BankAccReconciliationLine, AppliedAmount, Difference, NoOfEntries);
        GetAppliedPaymentEntries(AppliedPaymentEntry, BankAccReconciliationLine);
        VerifyAppliedEntries(AppliedPaymentEntry, BankPmtApplRule, AppliedAmount, 0, CustLedgerEntry."Entry No.");

        NoOfEntriesWithinRange := 0;
        NoOfEntriesOutsideRange := 1;
        VerifyNoOfEntriesWithingAndOutsideToleranceRangeForCustomer(
          BankPmtApplRule, BankAccReconciliationLine, NoOfEntriesWithinRange, NoOfEntriesOutsideRange, CustLedgerEntry."Entry No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CustomerPaidFullAmountInsteadOfDiscountedAmount()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        AppliedPaymentEntry: Record "Applied Payment Entry";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        AppliedAmount: Decimal;
        DiscountedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
        NoOfEntriesWithinRange: Integer;
        NoOfEntriesOutsideRange: Integer;
    begin
        Initialize();

        // Setup
        Amount := LibraryRandom.RandDecInRange(1, 10000, 2);

        CreateAndPostSalesInvoiceWithOneLine(CustLedgerEntry, Amount, '', true);
        CreateBankReconciliation(BankAccReconciliation);

        DiscountedAmount := CustLedgerEntry."Remaining Amount" - CustLedgerEntry."Remaining Pmt. Disc. Possible";

        CreateBankReconciliationLine(
          BankAccReconciliationLine, BankAccReconciliation, Amount,
          CustLedgerEntry."Pmt. Discount Date",
          CustLedgerEntry."Document No.");

        // Excercise
        RunMatch(TempBankStatementMatchingBuffer, BankAccReconciliation, true);

        // Verify discount was applied but difference was registered. Amount should be out of range.
        GetMatchConfidence(
          BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No, BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");

        Difference := Amount - DiscountedAmount;
        AppliedAmount := DiscountedAmount;
        NoOfEntries := 1;
        VerifyBankAccReconcilationLine(BankAccReconciliationLine, AppliedAmount, Difference, NoOfEntries);
        GetAppliedPaymentEntries(AppliedPaymentEntry, BankAccReconciliationLine);
        VerifyAppliedEntries(
          AppliedPaymentEntry, BankPmtApplRule, Amount, CustLedgerEntry."Remaining Pmt. Disc. Possible", CustLedgerEntry."Entry No.");

        NoOfEntriesWithinRange := 0;
        NoOfEntriesOutsideRange := 1;
        VerifyNoOfEntriesWithingAndOutsideToleranceRangeForCustomer(
          BankPmtApplRule, BankAccReconciliationLine, NoOfEntriesWithinRange, NoOfEntriesOutsideRange, CustLedgerEntry."Entry No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CustomerPaidFullAmountAfterDiscountDate()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        AppliedPaymentEntry: Record "Applied Payment Entry";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        AppliedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
        NoOfEntriesWithinRange: Integer;
        NoOfEntriesOutsideRange: Integer;
    begin
        Initialize();

        // Setup
        Amount := LibraryRandom.RandDecInRange(1, 10000, 2);

        CreateAndPostSalesInvoiceWithOneLine(CustLedgerEntry, Amount, '', true);
        CreateBankReconciliation(BankAccReconciliation);

        CreateBankReconciliationLine(
          BankAccReconciliationLine, BankAccReconciliation, Amount,
          CalcDate('<+1D>', CustLedgerEntry."Pmt. Discount Date"),
          CustLedgerEntry."Document No.");

        // Excercise
        RunMatch(TempBankStatementMatchingBuffer, BankAccReconciliation, true);

        // Verify no discount was applied, amount is correct and within range
        GetMatchConfidence(
          BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No, BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match");

        Difference := 0;
        AppliedAmount := Amount;
        NoOfEntries := 1;
        VerifyBankAccReconcilationLine(BankAccReconciliationLine, AppliedAmount, Difference, NoOfEntries);
        GetAppliedPaymentEntries(AppliedPaymentEntry, BankAccReconciliationLine);
        VerifyAppliedEntries(AppliedPaymentEntry, BankPmtApplRule, AppliedAmount, 0, CustLedgerEntry."Entry No.");

        NoOfEntriesWithinRange := 1;
        NoOfEntriesOutsideRange := 0;
        VerifyNoOfEntriesWithingAndOutsideToleranceRangeForCustomer(
          BankPmtApplRule, BankAccReconciliationLine, NoOfEntriesWithinRange, NoOfEntriesOutsideRange, CustLedgerEntry."Entry No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CustomerApplicableDiscountMatchOnToleranceTypeAmount()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        AppliedPaymentEntry: Record "Applied Payment Entry";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        AppliedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
        NoOfEntriesWithinRange: Integer;
        NoOfEntriesOutsideRange: Integer;
        Tolerance: Decimal;
        StatementAmount: Decimal;
    begin
        Initialize();

        // Setup
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        Tolerance := Round(Amount / 4, 0.01);
        CreateAndPostSalesInvoiceWithOneLine(CustLedgerEntry, Amount, '', true);

        StatementAmount := Amount - CustLedgerEntry."Remaining Pmt. Disc. Possible" - Tolerance;
        CreateBankReconciliationAmountTolerance(BankAccReconciliation, Tolerance);
        CreateBankReconciliationLine(
          BankAccReconciliationLine, BankAccReconciliation, StatementAmount,
          CustLedgerEntry."Pmt. Discount Date",
          CustLedgerEntry."Document No.");

        // Exercise
        RunMatch(TempBankStatementMatchingBuffer, BankAccReconciliation, true);

        // Verify no discount was applied, amount is correct and within range
        GetMatchConfidence(
          BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No, BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match");

        Difference := 0;
        AppliedAmount := StatementAmount;
        NoOfEntries := 1;
        VerifyBankAccReconcilationLine(BankAccReconciliationLine, AppliedAmount, Difference, NoOfEntries);
        GetAppliedPaymentEntries(AppliedPaymentEntry, BankAccReconciliationLine);
        VerifyAppliedEntries(AppliedPaymentEntry, BankPmtApplRule, AppliedAmount, 0, CustLedgerEntry."Entry No.");

        NoOfEntriesWithinRange := 1;
        NoOfEntriesOutsideRange := 0;
        VerifyNoOfEntriesWithingAndOutsideToleranceRangeForCustomer(
          BankPmtApplRule, BankAccReconciliationLine, NoOfEntriesWithinRange, NoOfEntriesOutsideRange, CustLedgerEntry."Entry No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CustomerApplicableDiscountMatchOnToleranceTypePercentage()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        AppliedPaymentEntry: Record "Applied Payment Entry";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        AppliedAmount: Decimal;
        DiscountedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
        NoOfEntriesWithinRange: Integer;
        NoOfEntriesOutsideRange: Integer;
        Tolerance: Decimal;
        StatementAmount: Decimal;
    begin
        Initialize();

        // Setup
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        Tolerance := LibraryRandom.RandDecInRange(1, 99, 1);
        CreateAndPostSalesInvoiceWithOneLine(CustLedgerEntry, Amount, '', true);

        CreateBankReconciliationPercentageTolerance(BankAccReconciliation, Tolerance);

        // Create invoices within tolerance range

        DiscountedAmount := Amount - CustLedgerEntry."Remaining Pmt. Disc. Possible";
        StatementAmount := DiscountedAmount - Round(DiscountedAmount * Tolerance / 200);

        CreateBankReconciliationLine(
          BankAccReconciliationLine, BankAccReconciliation, StatementAmount,
          CustLedgerEntry."Pmt. Discount Date",
          CustLedgerEntry."Document No.");

        // Exercise
        RunMatch(TempBankStatementMatchingBuffer, BankAccReconciliation, true);

        // Verify no discount was applied, amount is correct and within range
        GetMatchConfidence(
          BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No, BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match");

        Difference := 0;
        AppliedAmount := StatementAmount;
        NoOfEntries := 1;
        VerifyBankAccReconcilationLine(BankAccReconciliationLine, AppliedAmount, Difference, NoOfEntries);
        GetAppliedPaymentEntries(AppliedPaymentEntry, BankAccReconciliationLine);
        VerifyAppliedEntries(AppliedPaymentEntry, BankPmtApplRule, AppliedAmount, 0, CustLedgerEntry."Entry No.");

        NoOfEntriesWithinRange := 1;
        NoOfEntriesOutsideRange := 0;
        VerifyNoOfEntriesWithingAndOutsideToleranceRangeForCustomer(
          BankPmtApplRule, BankAccReconciliationLine, NoOfEntriesWithinRange, NoOfEntriesOutsideRange, CustLedgerEntry."Entry No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CustomerMatchOnToleranceTypeAmountOnRemainingAmountWhenDiscountIsNotApplicable()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        AppliedPaymentEntry: Record "Applied Payment Entry";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        AppliedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
        NoOfEntriesWithinRange: Integer;
        NoOfEntriesOutsideRange: Integer;
        Tolerance: Decimal;
        StatementAmount: Decimal;
    begin
        Initialize();

        // Setup
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        Tolerance := Round(Amount / 4, 0.01);
        CreateAndPostSalesInvoiceWithOneLine(CustLedgerEntry, Amount, '', true);

        StatementAmount := Amount - Tolerance;
        CreateBankReconciliationAmountTolerance(BankAccReconciliation, Tolerance);
        CreateBankReconciliationLine(
          BankAccReconciliationLine, BankAccReconciliation, StatementAmount,
          CalcDate('<+10D>', CustLedgerEntry."Pmt. Discount Date"),
          CustLedgerEntry."Document No.");

        // Exercise
        RunMatch(TempBankStatementMatchingBuffer, BankAccReconciliation, true);

        // Verify no discount was applied, amount is correct and within range
        GetMatchConfidence(
          BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No, BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match");

        Difference := 0;
        AppliedAmount := StatementAmount;
        NoOfEntries := 1;
        VerifyBankAccReconcilationLine(BankAccReconciliationLine, AppliedAmount, Difference, NoOfEntries);
        GetAppliedPaymentEntries(AppliedPaymentEntry, BankAccReconciliationLine);
        VerifyAppliedEntries(AppliedPaymentEntry, BankPmtApplRule, AppliedAmount, 0, CustLedgerEntry."Entry No.");

        NoOfEntriesWithinRange := 1;
        NoOfEntriesOutsideRange := 0;
        VerifyNoOfEntriesWithingAndOutsideToleranceRangeForCustomer(
          BankPmtApplRule, BankAccReconciliationLine, NoOfEntriesWithinRange, NoOfEntriesOutsideRange, CustLedgerEntry."Entry No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CustomerMatchOnToleranceTypePercentageOnRemainingAmountWhenDiscountIsNotApplicable()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        AppliedPaymentEntry: Record "Applied Payment Entry";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        AppliedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
        NoOfEntriesWithinRange: Integer;
        NoOfEntriesOutsideRange: Integer;
        Tolerance: Decimal;
        StatementAmount: Decimal;
    begin
        Initialize();

        // Setup
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        Tolerance := LibraryRandom.RandDecInRange(1, 99, 1);
        CreateAndPostSalesInvoiceWithOneLine(CustLedgerEntry, Amount, '', true);

        CreateBankReconciliationPercentageTolerance(BankAccReconciliation, Tolerance);

        // Create invoices within tolerance range
        StatementAmount := Round(Amount / (1 + Tolerance / 100));

        CreateBankReconciliationLine(
          BankAccReconciliationLine, BankAccReconciliation, StatementAmount,
          CalcDate('<+10D>', CustLedgerEntry."Pmt. Discount Date"),
          CustLedgerEntry."Document No.");

        // Exercise
        RunMatch(TempBankStatementMatchingBuffer, BankAccReconciliation, true);

        // Verify no discount was applied, amount is correct and within range
        GetMatchConfidence(
          BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No, BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match");

        Difference := 0;
        AppliedAmount := StatementAmount;
        NoOfEntries := 1;
        VerifyBankAccReconcilationLine(BankAccReconciliationLine, AppliedAmount, Difference, NoOfEntries);
        GetAppliedPaymentEntries(AppliedPaymentEntry, BankAccReconciliationLine);
        VerifyAppliedEntries(AppliedPaymentEntry, BankPmtApplRule, AppliedAmount, 0, CustLedgerEntry."Entry No.");

        NoOfEntriesWithinRange := 1;
        NoOfEntriesOutsideRange := 0;
        VerifyNoOfEntriesWithingAndOutsideToleranceRangeForCustomer(
          BankPmtApplRule, BankAccReconciliationLine, NoOfEntriesWithinRange, NoOfEntriesOutsideRange, CustLedgerEntry."Entry No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CustomerLumpPaymentWithDiscountInvoicesPaidOnTime()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        AppliedPaymentEntry: Record "Applied Payment Entry";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        Amount2: Decimal;
        AppliedAmount: Decimal;
        DiscountedAmount: Decimal;
        DiscountedAmount2: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
        NoOfEntriesWithinRange: Integer;
        NoOfEntriesOutsideRange: Integer;
    begin
        Initialize();

        // Setup
        Amount := LibraryRandom.RandDecInRange(1, 10000, 2);
        Amount2 := LibraryRandom.RandDecInRange(1, 10000, 2);

        CreateAndPostSalesInvoiceWithOneLine(CustLedgerEntry, Amount, '', true);
        CreateAndPostSalesInvoiceWithOneLine(CustLedgerEntry2, Amount2, CustLedgerEntry."Customer No.", true);

        DiscountedAmount := CustLedgerEntry."Remaining Amount" - CustLedgerEntry."Remaining Pmt. Disc. Possible";
        DiscountedAmount2 := CustLedgerEntry2."Remaining Amount" - CustLedgerEntry2."Remaining Pmt. Disc. Possible";

        CreateBankReconciliation(BankAccReconciliation);
        CreateBankReconciliationLine(
          BankAccReconciliationLine, BankAccReconciliation, DiscountedAmount + DiscountedAmount2,
          CustLedgerEntry."Pmt. Discount Date",
          CustLedgerEntry."Document No." + ' ' + CustLedgerEntry2."Document No.");

        // Excercise
        RunMatch(TempBankStatementMatchingBuffer, BankAccReconciliation, true);

        // Verify amount is correct and within range, discount was applied to all entries
        GetMatchConfidence(
          BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple",
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match");

        Difference := 0;
        AppliedAmount := DiscountedAmount + DiscountedAmount2;
        NoOfEntries := 2;
        VerifyBankAccReconcilationLine(BankAccReconciliationLine, AppliedAmount, Difference, NoOfEntries);
        GetAppliedPaymentEntries(AppliedPaymentEntry, BankAccReconciliationLine);
        VerifyAppliedEntries(
          AppliedPaymentEntry, BankPmtApplRule, Amount, CustLedgerEntry."Remaining Pmt. Disc. Possible", CustLedgerEntry."Entry No.");

        AppliedPaymentEntry.Next();
        VerifyAppliedEntries(
          AppliedPaymentEntry, BankPmtApplRule, Amount2, CustLedgerEntry2."Remaining Pmt. Disc. Possible", CustLedgerEntry2."Entry No.");

        NoOfEntriesWithinRange := 0;
        NoOfEntriesOutsideRange := 2;
        GetMatchConfidence(
          BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No, BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");

        VerifyNoOfEntriesWithingAndOutsideToleranceRangeForCustomer(
          BankPmtApplRule, BankAccReconciliationLine, NoOfEntriesWithinRange, NoOfEntriesOutsideRange, CustLedgerEntry."Entry No.");
        VerifyNoOfEntriesWithingAndOutsideToleranceRangeForCustomer(
          BankPmtApplRule, BankAccReconciliationLine, NoOfEntriesWithinRange, NoOfEntriesOutsideRange, CustLedgerEntry2."Entry No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CustomerLumpPaymentWithInvoicesWithAndWithoutDiscountPaidOnTIme()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        AppliedPaymentEntry: Record "Applied Payment Entry";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        Amount2: Decimal;
        AppliedAmount: Decimal;
        DiscountedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
        NoOfEntriesWithinRange: Integer;
        NoOfEntriesOutsideRange: Integer;
    begin
        Initialize();

        // Setup
        Amount := LibraryRandom.RandDecInRange(1, 10000, 2);
        Amount2 := LibraryRandom.RandDecInRange(1, 10000, 2);

        CreateAndPostSalesInvoiceWithOneLine(CustLedgerEntry, Amount, '', true);
        CreateAndPostSalesInvoiceWithOneLine(CustLedgerEntry2, Amount2, CustLedgerEntry."Customer No.", false);

        DiscountedAmount := CustLedgerEntry."Remaining Amount" - CustLedgerEntry."Remaining Pmt. Disc. Possible";

        CreateBankReconciliation(BankAccReconciliation);
        CreateBankReconciliationLine(
          BankAccReconciliationLine, BankAccReconciliation, DiscountedAmount + Amount2,
          CustLedgerEntry."Pmt. Discount Date",
          CustLedgerEntry."Document No." + ' ' + CustLedgerEntry2."Document No.");

        // Excercise
        RunMatch(TempBankStatementMatchingBuffer, BankAccReconciliation, true);

        // Verify amount is correct and within range, first line got discount applied, second didn't
        GetMatchConfidence(
          BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple",
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match");

        Difference := 0;
        AppliedAmount := DiscountedAmount + Amount2;
        NoOfEntries := 2;
        VerifyBankAccReconcilationLine(BankAccReconciliationLine, AppliedAmount, Difference, NoOfEntries);
        GetAppliedPaymentEntries(AppliedPaymentEntry, BankAccReconciliationLine);
        VerifyAppliedEntries(
          AppliedPaymentEntry, BankPmtApplRule, Amount, CustLedgerEntry."Remaining Pmt. Disc. Possible", CustLedgerEntry."Entry No.");

        AppliedPaymentEntry.Next();
        VerifyAppliedEntries(AppliedPaymentEntry, BankPmtApplRule, Amount2, 0, CustLedgerEntry2."Entry No.");

        NoOfEntriesWithinRange := 0;
        NoOfEntriesOutsideRange := 2;
        GetMatchConfidence(
          BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No, BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");

        VerifyNoOfEntriesWithingAndOutsideToleranceRangeForCustomer(
          BankPmtApplRule, BankAccReconciliationLine, NoOfEntriesWithinRange, NoOfEntriesOutsideRange, CustLedgerEntry."Entry No.");
        VerifyNoOfEntriesWithingAndOutsideToleranceRangeForCustomer(
          BankPmtApplRule, BankAccReconciliationLine, NoOfEntriesWithinRange, NoOfEntriesOutsideRange, CustLedgerEntry2."Entry No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CustomerLumpPaymentWithInvoicesPaidDiscountedAmountAfterDate()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        AppliedPaymentEntry: Record "Applied Payment Entry";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        Amount2: Decimal;
        AppliedAmount: Decimal;
        DiscountedAmount: Decimal;
        DiscountedAmount2: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
        NoOfEntriesWithinRange: Integer;
        NoOfEntriesOutsideRange: Integer;
    begin
        Initialize();

        // Setup
        Amount := LibraryRandom.RandDecInRange(1, 10000, 2);
        Amount2 := LibraryRandom.RandDecInRange(1, 10000, 2);

        CreateAndPostSalesInvoiceWithOneLine(CustLedgerEntry, Amount, '', true);
        CreateAndPostSalesInvoiceWithOneLine(CustLedgerEntry2, Amount2, CustLedgerEntry."Customer No.", true);

        DiscountedAmount := CustLedgerEntry."Remaining Amount" - CustLedgerEntry."Remaining Pmt. Disc. Possible";
        DiscountedAmount2 := CustLedgerEntry2."Remaining Amount" - CustLedgerEntry2."Remaining Pmt. Disc. Possible";

        CreateBankReconciliation(BankAccReconciliation);
        CreateBankReconciliationLine(
          BankAccReconciliationLine, BankAccReconciliation, DiscountedAmount + DiscountedAmount2,
          CalcDate('<+1D>', CustLedgerEntry."Pmt. Discount Date"),
          CustLedgerEntry."Document No." + ' ' + CustLedgerEntry2."Document No.");

        // Excercise
        RunMatch(TempBankStatementMatchingBuffer, BankAccReconciliation, true);

        // Verify no discount was applied, amount is not correct. First invoice should be fully applied, second with remaining amount (We apply oldest first).
        GetMatchConfidence(
          BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple",
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");

        Difference := 0;
        AppliedAmount := DiscountedAmount + DiscountedAmount2;
        NoOfEntries := 2;
        VerifyBankAccReconcilationLine(BankAccReconciliationLine, AppliedAmount, Difference, NoOfEntries);
        GetAppliedPaymentEntries(AppliedPaymentEntry, BankAccReconciliationLine);
        VerifyAppliedEntries(AppliedPaymentEntry, BankPmtApplRule, Amount, 0, CustLedgerEntry."Entry No.");

        AppliedPaymentEntry.Next();
        VerifyAppliedEntries(
          AppliedPaymentEntry, BankPmtApplRule, DiscountedAmount2 - Amount + DiscountedAmount, 0, CustLedgerEntry2."Entry No.");

        NoOfEntriesWithinRange := 0;
        NoOfEntriesOutsideRange := 2;
        GetMatchConfidence(
          BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No, BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");

        VerifyNoOfEntriesWithingAndOutsideToleranceRangeForCustomer(
          BankPmtApplRule, BankAccReconciliationLine, NoOfEntriesWithinRange, NoOfEntriesOutsideRange, CustLedgerEntry."Entry No.");
        VerifyNoOfEntriesWithingAndOutsideToleranceRangeForCustomer(
          BankPmtApplRule, BankAccReconciliationLine, NoOfEntriesWithinRange, NoOfEntriesOutsideRange, CustLedgerEntry2."Entry No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CustomerLumpPaymentWithInvoicesPaidFullAmountAfterDate()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        AppliedPaymentEntry: Record "Applied Payment Entry";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        Amount2: Decimal;
        AppliedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
        NoOfEntriesWithinRange: Integer;
        NoOfEntriesOutsideRange: Integer;
    begin
        Initialize();

        // Setup
        Amount := LibraryRandom.RandDecInRange(1, 10000, 2);
        Amount2 := LibraryRandom.RandDecInRange(1, 10000, 2);

        CreateAndPostSalesInvoiceWithOneLine(CustLedgerEntry, Amount, '', true);
        CreateAndPostSalesInvoiceWithOneLine(CustLedgerEntry2, Amount2, CustLedgerEntry."Customer No.", true);

        CreateBankReconciliation(BankAccReconciliation);
        CreateBankReconciliationLine(
          BankAccReconciliationLine, BankAccReconciliation, Amount + Amount2,
          CalcDate('<+1D>', CustLedgerEntry."Pmt. Discount Date"),
          CustLedgerEntry."Document No." + ' ' + CustLedgerEntry2."Document No.");

        // Excercise
        RunMatch(TempBankStatementMatchingBuffer, BankAccReconciliation, true);

        // Verify no discount was applied, amount is matching
        GetMatchConfidence(
          BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple",
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match");

        Difference := 0;
        AppliedAmount := Amount + Amount2;
        NoOfEntries := 2;
        VerifyBankAccReconcilationLine(BankAccReconciliationLine, AppliedAmount, Difference, NoOfEntries);
        GetAppliedPaymentEntries(AppliedPaymentEntry, BankAccReconciliationLine);
        VerifyAppliedEntries(AppliedPaymentEntry, BankPmtApplRule, Amount, 0, CustLedgerEntry."Entry No.");

        AppliedPaymentEntry.Next();
        VerifyAppliedEntries(AppliedPaymentEntry, BankPmtApplRule, Amount2, 0, CustLedgerEntry2."Entry No.");

        NoOfEntriesWithinRange := 0;
        NoOfEntriesOutsideRange := 2;
        GetMatchConfidence(
          BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No, BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");

        VerifyNoOfEntriesWithingAndOutsideToleranceRangeForCustomer(
          BankPmtApplRule, BankAccReconciliationLine, NoOfEntriesWithinRange, NoOfEntriesOutsideRange, CustLedgerEntry."Entry No.");
        VerifyNoOfEntriesWithingAndOutsideToleranceRangeForCustomer(
          BankPmtApplRule, BankAccReconciliationLine, NoOfEntriesWithinRange, NoOfEntriesOutsideRange, CustLedgerEntry2."Entry No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CustomerLumpPaymentWithInvoicesMixOfInvoicesWithApplicableDiscountAndWithout()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        CustLedgerEntry3: Record "Cust. Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        AppliedPaymentEntry: Record "Applied Payment Entry";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        Amount2: Decimal;
        Amount3: Decimal;
        AppliedAmount: Decimal;
        DiscountedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
        NoOfEntriesWithinRange: Integer;
        NoOfEntriesOutsideRange: Integer;
    begin
        Initialize();

        // Setup
        Amount := LibraryRandom.RandDecInRange(1, 10000, 2);
        Amount2 := LibraryRandom.RandDecInRange(1, 10000, 2);
        Amount3 := LibraryRandom.RandDecInRange(1, 10000, 2);

        // Paid on time
        CreateAndPostSalesInvoiceWithOneLine(CustLedgerEntry, Amount, '', true);

        // No discount
        CreateAndPostSalesInvoiceWithOneLine(CustLedgerEntry2, Amount2, CustLedgerEntry."Customer No.", false);

        // Not paid on time but paid full amount
        CreateAndPostSalesInvoiceWithOneLine(CustLedgerEntry3, Amount3, CustLedgerEntry."Customer No.", true);
        CustLedgerEntry3."Pmt. Discount Date" := CalcDate('<-10D>', CustLedgerEntry."Pmt. Discount Date");
        CustLedgerEntry3."Pmt. Disc. Tolerance Date" := CustLedgerEntry3."Pmt. Discount Date";
        CODEUNIT.Run(CODEUNIT::"Cust. Entry-Edit", CustLedgerEntry3);

        DiscountedAmount := CustLedgerEntry."Remaining Amount" - CustLedgerEntry."Remaining Pmt. Disc. Possible";

        CreateBankReconciliation(BankAccReconciliation);
        CreateBankReconciliationLine(
          BankAccReconciliationLine, BankAccReconciliation, DiscountedAmount + Amount2 + Amount3,
          CustLedgerEntry."Pmt. Discount Date",
          CustLedgerEntry."Document No." + ' ' + CustLedgerEntry2."Document No." + ' ' + CustLedgerEntry3."Document No.");

        // Excercise
        RunMatch(TempBankStatementMatchingBuffer, BankAccReconciliation, true);

        // Verify amount is matching, only first invoice got discount applied
        GetMatchConfidence(
          BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple",
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match");

        Difference := 0;
        AppliedAmount := DiscountedAmount + Amount2 + Amount3;
        NoOfEntries := 3;
        VerifyBankAccReconcilationLine(BankAccReconciliationLine, AppliedAmount, Difference, NoOfEntries);
        GetAppliedPaymentEntries(AppliedPaymentEntry, BankAccReconciliationLine);
        VerifyAppliedEntries(
          AppliedPaymentEntry, BankPmtApplRule, Amount, CustLedgerEntry."Remaining Pmt. Disc. Possible", CustLedgerEntry."Entry No.");

        AppliedPaymentEntry.Next();
        VerifyAppliedEntries(AppliedPaymentEntry, BankPmtApplRule, Amount2, 0, CustLedgerEntry2."Entry No.");

        AppliedPaymentEntry.Next();
        VerifyAppliedEntries(AppliedPaymentEntry, BankPmtApplRule, Amount3, 0, CustLedgerEntry3."Entry No.");

        NoOfEntriesWithinRange := 0;
        NoOfEntriesOutsideRange := 3;
        GetMatchConfidence(
          BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No, BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");

        VerifyNoOfEntriesWithingAndOutsideToleranceRangeForCustomer(
          BankPmtApplRule, BankAccReconciliationLine, NoOfEntriesWithinRange, NoOfEntriesOutsideRange, CustLedgerEntry."Entry No.");
        VerifyNoOfEntriesWithingAndOutsideToleranceRangeForCustomer(
          BankPmtApplRule, BankAccReconciliationLine, NoOfEntriesWithinRange, NoOfEntriesOutsideRange, CustLedgerEntry2."Entry No.");
        VerifyNoOfEntriesWithingAndOutsideToleranceRangeForCustomer(
          BankPmtApplRule, BankAccReconciliationLine, NoOfEntriesWithinRange, NoOfEntriesOutsideRange, CustLedgerEntry3."Entry No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CustomerMixOfInvoicesWithAndWithoutDiscountsPaidCorrectly()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        CustLedgerEntry3: Record "Cust. Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        AppliedPaymentEntry: Record "Applied Payment Entry";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        Amount2: Decimal;
        Amount3: Decimal;
        AppliedAmount: Decimal;
        DiscountedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
        NoOfEntriesWithinRange: Integer;
        NoOfEntriesOutsideRange: Integer;
    begin
        Initialize();

        // Setup
        Amount := LibraryRandom.RandDecInRange(1, 10000, 2);
        Amount2 := LibraryRandom.RandDecInRange(1, 10000, 2);
        Amount3 := LibraryRandom.RandDecInRange(1, 10000, 2);

        // Paid on time
        CreateAndPostSalesInvoiceWithOneLine(CustLedgerEntry, Amount, '', true);

        // No discount
        CreateAndPostSalesInvoiceWithOneLine(CustLedgerEntry2, Amount2, CustLedgerEntry."Customer No.", false);

        // Not paid on time but paid full amount
        CreateAndPostSalesInvoiceWithOneLine(CustLedgerEntry3, Amount3, CustLedgerEntry."Customer No.", true);
        CustLedgerEntry3."Pmt. Discount Date" := CalcDate('<-10D>', CustLedgerEntry."Pmt. Discount Date");
        CustLedgerEntry3."Pmt. Disc. Tolerance Date" := CustLedgerEntry3."Pmt. Discount Date";
        CODEUNIT.Run(CODEUNIT::"Cust. Entry-Edit", CustLedgerEntry3);

        DiscountedAmount := CustLedgerEntry."Remaining Amount" - CustLedgerEntry."Remaining Pmt. Disc. Possible";

        CreateBankReconciliation(BankAccReconciliation);
        CreateBankReconciliationLine(
          BankAccReconciliationLine, BankAccReconciliation, DiscountedAmount,
          CustLedgerEntry."Pmt. Discount Date",
          CustLedgerEntry."Document No.");

        // Excercise
        RunMatch(TempBankStatementMatchingBuffer, BankAccReconciliation, true);

        // Full amount paid on a signle invoice
        GetMatchConfidence(
          BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No, BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match");

        Difference := 0;
        AppliedAmount := DiscountedAmount;
        NoOfEntries := 1;
        VerifyBankAccReconcilationLine(BankAccReconciliationLine, AppliedAmount, Difference, NoOfEntries);
        GetAppliedPaymentEntries(AppliedPaymentEntry, BankAccReconciliationLine);
        VerifyAppliedEntries(
          AppliedPaymentEntry, BankPmtApplRule, Amount, CustLedgerEntry."Remaining Pmt. Disc. Possible", CustLedgerEntry."Entry No.");

        NoOfEntriesWithinRange := 1;
        NoOfEntriesOutsideRange := 2;
        VerifyNoOfEntriesWithingAndOutsideToleranceRangeForCustomer(
          BankPmtApplRule, BankAccReconciliationLine, NoOfEntriesWithinRange, NoOfEntriesOutsideRange, CustLedgerEntry."Entry No.");

        GetMatchConfidence(
          BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No, BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");

        VerifyNoOfEntriesWithingAndOutsideToleranceRangeForCustomer(
          BankPmtApplRule, BankAccReconciliationLine, NoOfEntriesWithinRange, NoOfEntriesOutsideRange, CustLedgerEntry2."Entry No.");
        VerifyNoOfEntriesWithingAndOutsideToleranceRangeForCustomer(
          BankPmtApplRule, BankAccReconciliationLine, NoOfEntriesWithinRange, NoOfEntriesOutsideRange, CustLedgerEntry3."Entry No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CustomerMixOfInvoicesWithAndWithoutDiscountsPaidIncorrectly()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        CustLedgerEntry3: Record "Cust. Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        AppliedPaymentEntry: Record "Applied Payment Entry";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        Amount2: Decimal;
        Amount3: Decimal;
        AppliedAmount: Decimal;
        DiscountedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
        NoOfEntriesWithinRange: Integer;
        NoOfEntriesOutsideRange: Integer;
    begin
        Initialize();

        // Setup
        Amount := LibraryRandom.RandDecInRange(1, 10000, 2);
        Amount2 := LibraryRandom.RandDecInRange(1, 10000, 2);
        Amount3 := LibraryRandom.RandDecInRange(1, 10000, 2);

        // Paid on time
        CreateAndPostSalesInvoiceWithOneLine(CustLedgerEntry, Amount, '', true);

        // No discount
        CreateAndPostSalesInvoiceWithOneLine(CustLedgerEntry2, Amount2, CustLedgerEntry."Customer No.", false);

        // Not paid on time but paid full amount
        CreateAndPostSalesInvoiceWithOneLine(CustLedgerEntry3, Amount3, CustLedgerEntry."Customer No.", true);
        CustLedgerEntry3."Pmt. Discount Date" := CalcDate('<-10D>', CustLedgerEntry."Pmt. Discount Date");
        CustLedgerEntry3."Pmt. Disc. Tolerance Date" := CustLedgerEntry3."Pmt. Discount Date";
        CODEUNIT.Run(CODEUNIT::"Cust. Entry-Edit", CustLedgerEntry3);

        DiscountedAmount := CustLedgerEntry."Remaining Amount" - CustLedgerEntry."Remaining Pmt. Disc. Possible";

        CreateBankReconciliation(BankAccReconciliation);
        CreateBankReconciliationLine(
          BankAccReconciliationLine, BankAccReconciliation, DiscountedAmount,
          CalcDate('<+1D>', CustLedgerEntry."Pmt. Discount Date"),
          CustLedgerEntry."Document No.");

        // Excercise
        RunMatch(TempBankStatementMatchingBuffer, BankAccReconciliation, true);

        // Full amount paid on a signle invoice
        GetMatchConfidence(
          BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No, BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");

        Difference := 0;
        AppliedAmount := DiscountedAmount;
        NoOfEntries := 1;
        VerifyBankAccReconcilationLine(BankAccReconciliationLine, AppliedAmount, Difference, NoOfEntries);
        GetAppliedPaymentEntries(AppliedPaymentEntry, BankAccReconciliationLine);
        VerifyAppliedEntries(AppliedPaymentEntry, BankPmtApplRule, AppliedAmount, 0, CustLedgerEntry."Entry No.");

        NoOfEntriesWithinRange := 0;
        NoOfEntriesOutsideRange := 3;
        VerifyNoOfEntriesWithingAndOutsideToleranceRangeForCustomer(
          BankPmtApplRule, BankAccReconciliationLine, NoOfEntriesWithinRange, NoOfEntriesOutsideRange, CustLedgerEntry."Entry No.");

        GetMatchConfidence(
          BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No, BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");

        VerifyNoOfEntriesWithingAndOutsideToleranceRangeForCustomer(
          BankPmtApplRule, BankAccReconciliationLine, NoOfEntriesWithinRange, NoOfEntriesOutsideRange, CustLedgerEntry2."Entry No.");
        VerifyNoOfEntriesWithingAndOutsideToleranceRangeForCustomer(
          BankPmtApplRule, BankAccReconciliationLine, NoOfEntriesWithinRange, NoOfEntriesOutsideRange, CustLedgerEntry3."Entry No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure VendorPaidDiscountedAmountOnTime()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        AppliedPaymentEntry: Record "Applied Payment Entry";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        AppliedAmount: Decimal;
        DiscountedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
        NoOfEntriesWithinRange: Integer;
        NoOfEntriesOutsideRange: Integer;
    begin
        Initialize();

        // Setup
        Amount := LibraryRandom.RandDecInRange(1, 10000, 2);

        CreateAndPostPurchaseInvoiceWithOneLine(VendorLedgerEntry, Amount, '', true);
        CreateBankReconciliation(BankAccReconciliation);

        DiscountedAmount := VendorLedgerEntry."Remaining Amount" - VendorLedgerEntry."Remaining Pmt. Disc. Possible";
        CreateBankReconciliationLine(
          BankAccReconciliationLine,
          BankAccReconciliation, DiscountedAmount,
          VendorLedgerEntry."Pmt. Discount Date", VendorLedgerEntry."Document No.");

        // Excercise
        RunMatch(TempBankStatementMatchingBuffer, BankAccReconciliation, true);

        // Verify Payment was matched and discount was applied
        GetMatchConfidence(
          BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes, BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match");

        Difference := 0;
        AppliedAmount := -Amount;
        NoOfEntries := 1;
        VerifyBankAccReconcilationLine(BankAccReconciliationLine, DiscountedAmount, Difference, NoOfEntries);
        GetAppliedPaymentEntries(AppliedPaymentEntry, BankAccReconciliationLine);
        VerifyAppliedEntries(
          AppliedPaymentEntry, BankPmtApplRule, AppliedAmount, VendorLedgerEntry."Remaining Pmt. Disc. Possible",
          VendorLedgerEntry."Entry No.");

        NoOfEntriesWithinRange := 1;
        NoOfEntriesOutsideRange := 0;
        VerifyNoOfEntriesWithingAndOutsideToleranceRangeForVendor(
          BankPmtApplRule, BankAccReconciliationLine, NoOfEntriesWithinRange, NoOfEntriesOutsideRange, VendorLedgerEntry."Entry No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure VendorPaidDiscountedAmountAfterDiscountDate()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        AppliedPaymentEntry: Record "Applied Payment Entry";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        AppliedAmount: Decimal;
        DiscountedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
        NoOfEntriesWithinRange: Integer;
        NoOfEntriesOutsideRange: Integer;
    begin
        Initialize();

        // Setup
        Amount := LibraryRandom.RandDecInRange(1, 10000, 2);

        CreateAndPostPurchaseInvoiceWithOneLine(VendorLedgerEntry, Amount, '', true);
        CreateBankReconciliation(BankAccReconciliation);

        DiscountedAmount := VendorLedgerEntry."Remaining Amount" - VendorLedgerEntry."Remaining Pmt. Disc. Possible";
        CreateBankReconciliationLine(
          BankAccReconciliationLine, BankAccReconciliation, DiscountedAmount,
          CalcDate('<+1D>', VendorLedgerEntry."Pmt. Discount Date"),
          VendorLedgerEntry."Document No.");

        // Excercise
        RunMatch(TempBankStatementMatchingBuffer, BankAccReconciliation, true);

        // Verify no match on the amount, amount is out of range, no discount was assigned
        GetMatchConfidence(
          BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No, BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");

        Difference := 0;
        AppliedAmount := DiscountedAmount;
        NoOfEntries := 1;
        VerifyBankAccReconcilationLine(BankAccReconciliationLine, AppliedAmount, Difference, NoOfEntries);
        GetAppliedPaymentEntries(AppliedPaymentEntry, BankAccReconciliationLine);
        VerifyAppliedEntries(AppliedPaymentEntry, BankPmtApplRule, AppliedAmount, 0, VendorLedgerEntry."Entry No.");

        NoOfEntriesWithinRange := 0;
        NoOfEntriesOutsideRange := 1;
        VerifyNoOfEntriesWithingAndOutsideToleranceRangeForVendor(
          BankPmtApplRule, BankAccReconciliationLine, NoOfEntriesWithinRange, NoOfEntriesOutsideRange, VendorLedgerEntry."Entry No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure VendorPaidFullAmountInsteadOfDiscountedAmount()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        AppliedPaymentEntry: Record "Applied Payment Entry";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        AppliedAmount: Decimal;
        DiscountedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
        NoOfEntriesWithinRange: Integer;
        NoOfEntriesOutsideRange: Integer;
    begin
        Initialize();

        // Setup
        Amount := LibraryRandom.RandDecInRange(1, 10000, 2);

        CreateAndPostPurchaseInvoiceWithOneLine(VendorLedgerEntry, Amount, '', true);
        CreateBankReconciliation(BankAccReconciliation);

        DiscountedAmount := VendorLedgerEntry."Remaining Amount" - VendorLedgerEntry."Remaining Pmt. Disc. Possible";

        CreateBankReconciliationLine(
          BankAccReconciliationLine, BankAccReconciliation, -Amount,
          VendorLedgerEntry."Pmt. Discount Date",
          VendorLedgerEntry."Document No.");

        // Excercise
        RunMatch(TempBankStatementMatchingBuffer, BankAccReconciliation, true);

        // Verify discount was applied but difference was registered. Amount should be out of range.
        GetMatchConfidence(
          BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No, BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");

        Difference := -Amount - DiscountedAmount;
        AppliedAmount := DiscountedAmount;
        NoOfEntries := 1;
        VerifyBankAccReconcilationLine(BankAccReconciliationLine, AppliedAmount, Difference, NoOfEntries);
        GetAppliedPaymentEntries(AppliedPaymentEntry, BankAccReconciliationLine);
        VerifyAppliedEntries(
          AppliedPaymentEntry, BankPmtApplRule, -Amount, VendorLedgerEntry."Remaining Pmt. Disc. Possible", VendorLedgerEntry."Entry No.");

        NoOfEntriesWithinRange := 0;
        NoOfEntriesOutsideRange := 1;
        VerifyNoOfEntriesWithingAndOutsideToleranceRangeForVendor(
          BankPmtApplRule, BankAccReconciliationLine, NoOfEntriesWithinRange, NoOfEntriesOutsideRange, VendorLedgerEntry."Entry No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure VendorPaidFullAmountAfterDiscountDate()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        AppliedPaymentEntry: Record "Applied Payment Entry";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        AppliedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
        NoOfEntriesWithinRange: Integer;
        NoOfEntriesOutsideRange: Integer;
    begin
        Initialize();

        // Setup
        Amount := LibraryRandom.RandDecInRange(1, 10000, 2);

        CreateAndPostPurchaseInvoiceWithOneLine(VendorLedgerEntry, Amount, '', true);
        CreateBankReconciliation(BankAccReconciliation);

        CreateBankReconciliationLine(
          BankAccReconciliationLine, BankAccReconciliation, -Amount,
          CalcDate('<+1D>', VendorLedgerEntry."Pmt. Discount Date"),
          VendorLedgerEntry."Document No.");

        // Excercise
        RunMatch(TempBankStatementMatchingBuffer, BankAccReconciliation, true);

        // Verify no discount was applied, amount is correct and within range
        GetMatchConfidence(
          BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No, BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match");

        Difference := 0;
        AppliedAmount := -Amount;
        NoOfEntries := 1;
        VerifyBankAccReconcilationLine(BankAccReconciliationLine, AppliedAmount, Difference, NoOfEntries);
        GetAppliedPaymentEntries(AppliedPaymentEntry, BankAccReconciliationLine);
        VerifyAppliedEntries(AppliedPaymentEntry, BankPmtApplRule, AppliedAmount, 0, VendorLedgerEntry."Entry No.");

        NoOfEntriesWithinRange := 1;
        NoOfEntriesOutsideRange := 0;
        VerifyNoOfEntriesWithingAndOutsideToleranceRangeForVendor(
          BankPmtApplRule, BankAccReconciliationLine, NoOfEntriesWithinRange, NoOfEntriesOutsideRange, VendorLedgerEntry."Entry No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure VendorApplicableDiscountMatchOnToleranceTypeAmount()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        AppliedPaymentEntry: Record "Applied Payment Entry";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        AppliedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
        NoOfEntriesWithinRange: Integer;
        NoOfEntriesOutsideRange: Integer;
        Tolerance: Decimal;
        StatementAmount: Decimal;
    begin
        Initialize();

        // Setup
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        Tolerance := Round(Amount / 4, 0.01);
        CreateAndPostPurchaseInvoiceWithOneLine(VendorLedgerEntry, Amount, '', true);

        StatementAmount := -Amount - VendorLedgerEntry."Remaining Pmt. Disc. Possible" + Tolerance;
        CreateBankReconciliationAmountTolerance(BankAccReconciliation, Tolerance);
        CreateBankReconciliationLine(
          BankAccReconciliationLine, BankAccReconciliation, StatementAmount,
          VendorLedgerEntry."Pmt. Discount Date",
          VendorLedgerEntry."Document No.");

        // Exercise
        RunMatch(TempBankStatementMatchingBuffer, BankAccReconciliation, true);

        // Verify no discount was applied, amount is correct and within range
        GetMatchConfidence(
          BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No, BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match");

        Difference := 0;
        AppliedAmount := StatementAmount;
        NoOfEntries := 1;
        VerifyBankAccReconcilationLine(BankAccReconciliationLine, AppliedAmount, Difference, NoOfEntries);
        GetAppliedPaymentEntries(AppliedPaymentEntry, BankAccReconciliationLine);
        VerifyAppliedEntries(AppliedPaymentEntry, BankPmtApplRule, AppliedAmount, 0, VendorLedgerEntry."Entry No.");

        NoOfEntriesWithinRange := 1;
        NoOfEntriesOutsideRange := 0;
        VerifyNoOfEntriesWithingAndOutsideToleranceRangeForVendor(
          BankPmtApplRule, BankAccReconciliationLine, NoOfEntriesWithinRange, NoOfEntriesOutsideRange, VendorLedgerEntry."Entry No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure VendorApplicableDiscountMatchOnToleranceTypePercentage()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        AppliedPaymentEntry: Record "Applied Payment Entry";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        AppliedAmount: Decimal;
        DiscountedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
        NoOfEntriesWithinRange: Integer;
        NoOfEntriesOutsideRange: Integer;
        Tolerance: Decimal;
        StatementAmount: Decimal;
    begin
        Initialize();

        // Setup
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        Tolerance := LibraryRandom.RandDecInRange(1, 99, 1);
        CreateAndPostPurchaseInvoiceWithOneLine(VendorLedgerEntry, Amount, '', true);

        CreateBankReconciliationPercentageTolerance(BankAccReconciliation, Tolerance);

        // Create invoices within tolerance range

        DiscountedAmount := -Amount - VendorLedgerEntry."Remaining Pmt. Disc. Possible";
        StatementAmount := DiscountedAmount - Round(DiscountedAmount * Tolerance / 200);

        CreateBankReconciliationLine(
          BankAccReconciliationLine, BankAccReconciliation, StatementAmount,
          VendorLedgerEntry."Pmt. Discount Date",
          VendorLedgerEntry."Document No.");

        // Exercise
        RunMatch(TempBankStatementMatchingBuffer, BankAccReconciliation, true);

        // Verify no discount was applied, amount is correct and within range
        GetMatchConfidence(
          BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No, BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match");

        Difference := 0;
        AppliedAmount := StatementAmount;
        NoOfEntries := 1;
        VerifyBankAccReconcilationLine(BankAccReconciliationLine, AppliedAmount, Difference, NoOfEntries);
        GetAppliedPaymentEntries(AppliedPaymentEntry, BankAccReconciliationLine);
        VerifyAppliedEntries(AppliedPaymentEntry, BankPmtApplRule, AppliedAmount, 0, VendorLedgerEntry."Entry No.");

        NoOfEntriesWithinRange := 1;
        NoOfEntriesOutsideRange := 0;
        VerifyNoOfEntriesWithingAndOutsideToleranceRangeForVendor(
          BankPmtApplRule, BankAccReconciliationLine, NoOfEntriesWithinRange, NoOfEntriesOutsideRange, VendorLedgerEntry."Entry No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure VendorMatchOnToleranceTypeAmountOnRemainingAmountWhenDiscountIsNotApplicable()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        AppliedPaymentEntry: Record "Applied Payment Entry";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        AppliedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
        NoOfEntriesWithinRange: Integer;
        NoOfEntriesOutsideRange: Integer;
        Tolerance: Decimal;
        StatementAmount: Decimal;
    begin
        Initialize();

        // Setup
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        Tolerance := Round(Amount / 4, 0.01);
        CreateAndPostPurchaseInvoiceWithOneLine(VendorLedgerEntry, Amount, '', true);

        StatementAmount := -Amount + Tolerance;
        CreateBankReconciliationAmountTolerance(BankAccReconciliation, Tolerance);
        CreateBankReconciliationLine(
          BankAccReconciliationLine, BankAccReconciliation, StatementAmount,
          CalcDate('<+10D>', VendorLedgerEntry."Pmt. Discount Date"),
          VendorLedgerEntry."Document No.");

        // Exercise
        RunMatch(TempBankStatementMatchingBuffer, BankAccReconciliation, true);

        // Verify no discount was applied, amount is correct and within range
        GetMatchConfidence(
          BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No, BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match");

        Difference := 0;
        AppliedAmount := StatementAmount;
        NoOfEntries := 1;
        VerifyBankAccReconcilationLine(BankAccReconciliationLine, AppliedAmount, Difference, NoOfEntries);
        GetAppliedPaymentEntries(AppliedPaymentEntry, BankAccReconciliationLine);
        VerifyAppliedEntries(AppliedPaymentEntry, BankPmtApplRule, AppliedAmount, 0, VendorLedgerEntry."Entry No.");

        NoOfEntriesWithinRange := 1;
        NoOfEntriesOutsideRange := 0;
        VerifyNoOfEntriesWithingAndOutsideToleranceRangeForVendor(
          BankPmtApplRule, BankAccReconciliationLine, NoOfEntriesWithinRange, NoOfEntriesOutsideRange, VendorLedgerEntry."Entry No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure VendorMatchOnToleranceTypePercentageOnRemainingAmountWhenDiscountIsNotApplicable()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        AppliedPaymentEntry: Record "Applied Payment Entry";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        AppliedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
        NoOfEntriesWithinRange: Integer;
        NoOfEntriesOutsideRange: Integer;
        Tolerance: Decimal;
        StatementAmount: Decimal;
    begin
        Initialize();

        // Setup
        Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        Tolerance := LibraryRandom.RandDecInRange(1, 99, 1);
        CreateAndPostPurchaseInvoiceWithOneLine(VendorLedgerEntry, Amount, '', true);

        CreateBankReconciliationPercentageTolerance(BankAccReconciliation, Tolerance);

        // Create invoices within tolerance range
        StatementAmount := -Amount + Round(Amount * Tolerance / 200);

        CreateBankReconciliationLine(
          BankAccReconciliationLine, BankAccReconciliation, StatementAmount,
          CalcDate('<+10D>', VendorLedgerEntry."Pmt. Discount Date"),
          VendorLedgerEntry."Document No.");

        // Exercise
        RunMatch(TempBankStatementMatchingBuffer, BankAccReconciliation, true);

        // Verify no discount was applied, amount is correct and within range
        GetMatchConfidence(
          BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No, BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match");

        Difference := 0;
        AppliedAmount := StatementAmount;
        NoOfEntries := 1;
        VerifyBankAccReconcilationLine(BankAccReconciliationLine, AppliedAmount, Difference, NoOfEntries);
        GetAppliedPaymentEntries(AppliedPaymentEntry, BankAccReconciliationLine);
        VerifyAppliedEntries(AppliedPaymentEntry, BankPmtApplRule, AppliedAmount, 0, VendorLedgerEntry."Entry No.");

        NoOfEntriesWithinRange := 1;
        NoOfEntriesOutsideRange := 0;
        VerifyNoOfEntriesWithingAndOutsideToleranceRangeForVendor(
          BankPmtApplRule, BankAccReconciliationLine, NoOfEntriesWithinRange, NoOfEntriesOutsideRange, VendorLedgerEntry."Entry No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure VendorLumpPaymentWithDiscountInvoicesPaidOnTime()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        AppliedPaymentEntry: Record "Applied Payment Entry";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        Amount2: Decimal;
        AppliedAmount: Decimal;
        DiscountedAmount: Decimal;
        DiscountedAmount2: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
        NoOfEntriesWithinRange: Integer;
        NoOfEntriesOutsideRange: Integer;
    begin
        Initialize();

        // Setup
        Amount := LibraryRandom.RandDecInRange(1, 10000, 2);
        Amount2 := LibraryRandom.RandDecInRange(1, 10000, 2);

        CreateAndPostPurchaseInvoiceWithOneLine(VendorLedgerEntry, Amount, '', true);
        CreateAndPostPurchaseInvoiceWithOneLine(VendorLedgerEntry2, Amount2, VendorLedgerEntry."Vendor No.", true);

        DiscountedAmount := VendorLedgerEntry."Remaining Amount" - VendorLedgerEntry."Remaining Pmt. Disc. Possible";
        DiscountedAmount2 := VendorLedgerEntry2."Remaining Amount" - VendorLedgerEntry2."Remaining Pmt. Disc. Possible";

        CreateBankReconciliation(BankAccReconciliation);
        CreateBankReconciliationLine(
          BankAccReconciliationLine, BankAccReconciliation, DiscountedAmount + DiscountedAmount2,
          VendorLedgerEntry."Pmt. Discount Date",
          VendorLedgerEntry."Document No." + ' ' + VendorLedgerEntry2."Document No.");

        // Excercise
        RunMatch(TempBankStatementMatchingBuffer, BankAccReconciliation, true);

        // Verify amount is correct and within range, discount was applied to all entries
        GetMatchConfidence(
          BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple",
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match");

        Difference := 0;
        AppliedAmount := DiscountedAmount + DiscountedAmount2;
        NoOfEntries := 2;
        VerifyBankAccReconcilationLine(BankAccReconciliationLine, AppliedAmount, Difference, NoOfEntries);
        GetAppliedPaymentEntries(AppliedPaymentEntry, BankAccReconciliationLine);
        VerifyAppliedEntries(
          AppliedPaymentEntry, BankPmtApplRule, -Amount, VendorLedgerEntry."Remaining Pmt. Disc. Possible", VendorLedgerEntry."Entry No.");

        AppliedPaymentEntry.Next();
        VerifyAppliedEntries(
          AppliedPaymentEntry, BankPmtApplRule, -Amount2, VendorLedgerEntry2."Remaining Pmt. Disc. Possible",
          VendorLedgerEntry2."Entry No.");

        NoOfEntriesWithinRange := 0;
        NoOfEntriesOutsideRange := 2;
        GetMatchConfidence(
          BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No, BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");

        VerifyNoOfEntriesWithingAndOutsideToleranceRangeForVendor(
          BankPmtApplRule, BankAccReconciliationLine, NoOfEntriesWithinRange, NoOfEntriesOutsideRange, VendorLedgerEntry."Entry No.");
        VerifyNoOfEntriesWithingAndOutsideToleranceRangeForVendor(
          BankPmtApplRule, BankAccReconciliationLine, NoOfEntriesWithinRange, NoOfEntriesOutsideRange, VendorLedgerEntry2."Entry No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure VendorLumpPaymentWithInvoicesWithAndWithoutDiscountPaidOnTIme()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        AppliedPaymentEntry: Record "Applied Payment Entry";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        Amount2: Decimal;
        AppliedAmount: Decimal;
        DiscountedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
        NoOfEntriesWithinRange: Integer;
        NoOfEntriesOutsideRange: Integer;
    begin
        Initialize();

        // Setup
        Amount := LibraryRandom.RandDecInRange(1, 10000, 2);
        Amount2 := LibraryRandom.RandDecInRange(1, 10000, 2);

        CreateAndPostPurchaseInvoiceWithOneLine(VendorLedgerEntry, Amount, '', true);
        CreateAndPostPurchaseInvoiceWithOneLine(VendorLedgerEntry2, Amount2, VendorLedgerEntry."Vendor No.", false);

        DiscountedAmount := VendorLedgerEntry."Remaining Amount" - VendorLedgerEntry."Remaining Pmt. Disc. Possible";

        CreateBankReconciliation(BankAccReconciliation);
        CreateBankReconciliationLine(
          BankAccReconciliationLine, BankAccReconciliation, DiscountedAmount - Amount2,
          VendorLedgerEntry."Pmt. Discount Date",
          VendorLedgerEntry."Document No." + ' ' + VendorLedgerEntry2."Document No.");

        // Excercise
        RunMatch(TempBankStatementMatchingBuffer, BankAccReconciliation, true);

        // Verify amount is correct and within range, first line got discount applied, second didn't
        GetMatchConfidence(
          BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple",
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match");

        Difference := 0;
        AppliedAmount := DiscountedAmount - Amount2;
        NoOfEntries := 2;
        VerifyBankAccReconcilationLine(BankAccReconciliationLine, AppliedAmount, Difference, NoOfEntries);
        GetAppliedPaymentEntries(AppliedPaymentEntry, BankAccReconciliationLine);
        VerifyAppliedEntries(
          AppliedPaymentEntry, BankPmtApplRule, -Amount, VendorLedgerEntry."Remaining Pmt. Disc. Possible", VendorLedgerEntry."Entry No.");

        AppliedPaymentEntry.Next();
        VerifyAppliedEntries(AppliedPaymentEntry, BankPmtApplRule, -Amount2, 0, VendorLedgerEntry2."Entry No.");

        NoOfEntriesWithinRange := 0;
        NoOfEntriesOutsideRange := 2;
        GetMatchConfidence(
          BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No, BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");

        VerifyNoOfEntriesWithingAndOutsideToleranceRangeForVendor(
          BankPmtApplRule, BankAccReconciliationLine, NoOfEntriesWithinRange, NoOfEntriesOutsideRange, VendorLedgerEntry."Entry No.");
        VerifyNoOfEntriesWithingAndOutsideToleranceRangeForVendor(
          BankPmtApplRule, BankAccReconciliationLine, NoOfEntriesWithinRange, NoOfEntriesOutsideRange, VendorLedgerEntry2."Entry No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure VendorLumpPaymentWithInvoicesPaidDiscountedAmountAfterDate()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        AppliedPaymentEntry: Record "Applied Payment Entry";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        Amount2: Decimal;
        AppliedAmount: Decimal;
        DiscountedAmount: Decimal;
        DiscountedAmount2: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
        NoOfEntriesWithinRange: Integer;
        NoOfEntriesOutsideRange: Integer;
    begin
        Initialize();

        // Setup
        Amount := LibraryRandom.RandDecInRange(1, 10000, 2);
        Amount2 := LibraryRandom.RandDecInRange(1, 10000, 2);

        CreateAndPostPurchaseInvoiceWithOneLine(VendorLedgerEntry, Amount, '', true);
        CreateAndPostPurchaseInvoiceWithOneLine(VendorLedgerEntry2, Amount2, VendorLedgerEntry."Vendor No.", true);

        DiscountedAmount := VendorLedgerEntry."Remaining Amount" - VendorLedgerEntry."Remaining Pmt. Disc. Possible";
        DiscountedAmount2 := VendorLedgerEntry2."Remaining Amount" - VendorLedgerEntry2."Remaining Pmt. Disc. Possible";

        CreateBankReconciliation(BankAccReconciliation);
        CreateBankReconciliationLine(
          BankAccReconciliationLine, BankAccReconciliation, DiscountedAmount + DiscountedAmount2,
          CalcDate('<+1D>', VendorLedgerEntry."Pmt. Discount Date"),
          VendorLedgerEntry."Document No." + ' ' + VendorLedgerEntry2."Document No.");

        // Excercise
        RunMatch(TempBankStatementMatchingBuffer, BankAccReconciliation, true);

        // Verify no discount was applied, amount is not correct. First invoice should be fully applied, second with remaining amount (We apply oldest first).
        GetMatchConfidence(
          BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple",
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");

        Difference := 0;
        AppliedAmount := DiscountedAmount + DiscountedAmount2;
        NoOfEntries := 2;
        VerifyBankAccReconcilationLine(BankAccReconciliationLine, AppliedAmount, Difference, NoOfEntries);
        GetAppliedPaymentEntries(AppliedPaymentEntry, BankAccReconciliationLine);
        VerifyAppliedEntries(AppliedPaymentEntry, BankPmtApplRule, -Amount, 0, VendorLedgerEntry."Entry No.");

        AppliedPaymentEntry.Next();
        VerifyAppliedEntries(
          AppliedPaymentEntry, BankPmtApplRule, DiscountedAmount2 + Amount + DiscountedAmount, 0, VendorLedgerEntry2."Entry No.");

        NoOfEntriesWithinRange := 0;
        NoOfEntriesOutsideRange := 2;
        GetMatchConfidence(
          BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No, BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");

        VerifyNoOfEntriesWithingAndOutsideToleranceRangeForVendor(
          BankPmtApplRule, BankAccReconciliationLine, NoOfEntriesWithinRange, NoOfEntriesOutsideRange, VendorLedgerEntry."Entry No.");
        VerifyNoOfEntriesWithingAndOutsideToleranceRangeForVendor(
          BankPmtApplRule, BankAccReconciliationLine, NoOfEntriesWithinRange, NoOfEntriesOutsideRange, VendorLedgerEntry2."Entry No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure VendorLumpPaymentWithInvoicesPaidFullAmountAfterDate()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        AppliedPaymentEntry: Record "Applied Payment Entry";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        Amount2: Decimal;
        AppliedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
        NoOfEntriesWithinRange: Integer;
        NoOfEntriesOutsideRange: Integer;
    begin
        Initialize();

        // Setup
        Amount := LibraryRandom.RandDecInRange(1, 10000, 2);
        Amount2 := LibraryRandom.RandDecInRange(1, 10000, 2);

        CreateAndPostPurchaseInvoiceWithOneLine(VendorLedgerEntry, Amount, '', true);
        CreateAndPostPurchaseInvoiceWithOneLine(VendorLedgerEntry2, Amount2, VendorLedgerEntry."Vendor No.", true);

        CreateBankReconciliation(BankAccReconciliation);
        CreateBankReconciliationLine(
          BankAccReconciliationLine, BankAccReconciliation, -Amount - Amount2,
          CalcDate('<+1D>', VendorLedgerEntry."Pmt. Discount Date"),
          VendorLedgerEntry."Document No." + ' ' + VendorLedgerEntry2."Document No.");

        // Excercise
        RunMatch(TempBankStatementMatchingBuffer, BankAccReconciliation, true);

        // Verify no discount was applied, amount is matching
        GetMatchConfidence(
          BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple",
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match");

        Difference := 0;
        AppliedAmount := -Amount - Amount2;
        NoOfEntries := 2;
        VerifyBankAccReconcilationLine(BankAccReconciliationLine, AppliedAmount, Difference, NoOfEntries);
        GetAppliedPaymentEntries(AppliedPaymentEntry, BankAccReconciliationLine);
        VerifyAppliedEntries(AppliedPaymentEntry, BankPmtApplRule, -Amount, 0, VendorLedgerEntry."Entry No.");

        AppliedPaymentEntry.Next();
        VerifyAppliedEntries(AppliedPaymentEntry, BankPmtApplRule, -Amount2, 0, VendorLedgerEntry2."Entry No.");

        NoOfEntriesWithinRange := 0;
        NoOfEntriesOutsideRange := 2;
        GetMatchConfidence(
          BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No, BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");

        VerifyNoOfEntriesWithingAndOutsideToleranceRangeForVendor(
          BankPmtApplRule, BankAccReconciliationLine, NoOfEntriesWithinRange, NoOfEntriesOutsideRange, VendorLedgerEntry."Entry No.");
        VerifyNoOfEntriesWithingAndOutsideToleranceRangeForVendor(
          BankPmtApplRule, BankAccReconciliationLine, NoOfEntriesWithinRange, NoOfEntriesOutsideRange, VendorLedgerEntry2."Entry No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure VendorLumpPaymentWithInvoicesMixOfInvoicesWithApplicableDiscountAndWithout()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
        VendorLedgerEntry3: Record "Vendor Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        AppliedPaymentEntry: Record "Applied Payment Entry";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        Amount2: Decimal;
        Amount3: Decimal;
        AppliedAmount: Decimal;
        DiscountedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
        NoOfEntriesWithinRange: Integer;
        NoOfEntriesOutsideRange: Integer;
    begin
        Initialize();

        // Setup
        Amount := LibraryRandom.RandDecInRange(1, 10000, 2);
        Amount2 := LibraryRandom.RandDecInRange(1, 10000, 2);
        Amount3 := LibraryRandom.RandDecInRange(1, 10000, 2);

        // Paid on time
        CreateAndPostPurchaseInvoiceWithOneLine(VendorLedgerEntry, Amount, '', true);

        // No discount
        CreateAndPostPurchaseInvoiceWithOneLine(VendorLedgerEntry2, Amount2, VendorLedgerEntry."Vendor No.", false);

        // Not paid on time but paid full amount
        CreateAndPostPurchaseInvoiceWithOneLine(VendorLedgerEntry3, Amount3, VendorLedgerEntry."Vendor No.", true);
        VendorLedgerEntry3."Pmt. Discount Date" := CalcDate('<-10D>', VendorLedgerEntry."Pmt. Discount Date");
        VendorLedgerEntry3."Pmt. Disc. Tolerance Date" := VendorLedgerEntry3."Pmt. Discount Date";
        CODEUNIT.Run(CODEUNIT::"Vend. Entry-Edit", VendorLedgerEntry3);

        DiscountedAmount := VendorLedgerEntry."Remaining Amount" - VendorLedgerEntry."Remaining Pmt. Disc. Possible";

        CreateBankReconciliation(BankAccReconciliation);
        CreateBankReconciliationLine(
          BankAccReconciliationLine, BankAccReconciliation, DiscountedAmount - Amount2 - Amount3,
          VendorLedgerEntry."Pmt. Discount Date",
          VendorLedgerEntry."Document No." + ' ' + VendorLedgerEntry2."Document No." + ' ' + VendorLedgerEntry3."Document No.");

        // Excercise
        RunMatch(TempBankStatementMatchingBuffer, BankAccReconciliation, true);

        // Verify amount is matching, only first invoice got discount applied
        GetMatchConfidence(
          BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple",
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match");

        Difference := 0;
        AppliedAmount := DiscountedAmount - Amount2 - Amount3;
        NoOfEntries := 3;
        VerifyBankAccReconcilationLine(BankAccReconciliationLine, AppliedAmount, Difference, NoOfEntries);
        GetAppliedPaymentEntries(AppliedPaymentEntry, BankAccReconciliationLine);
        VerifyAppliedEntries(
          AppliedPaymentEntry, BankPmtApplRule, -Amount, VendorLedgerEntry."Remaining Pmt. Disc. Possible", VendorLedgerEntry."Entry No.");

        AppliedPaymentEntry.Next();
        VerifyAppliedEntries(AppliedPaymentEntry, BankPmtApplRule, -Amount2, 0, VendorLedgerEntry2."Entry No.");

        AppliedPaymentEntry.Next();
        VerifyAppliedEntries(AppliedPaymentEntry, BankPmtApplRule, -Amount3, 0, VendorLedgerEntry3."Entry No.");

        NoOfEntriesWithinRange := 0;
        NoOfEntriesOutsideRange := 3;
        GetMatchConfidence(
          BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No, BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");

        VerifyNoOfEntriesWithingAndOutsideToleranceRangeForVendor(
          BankPmtApplRule, BankAccReconciliationLine, NoOfEntriesWithinRange, NoOfEntriesOutsideRange, VendorLedgerEntry."Entry No.");
        VerifyNoOfEntriesWithingAndOutsideToleranceRangeForVendor(
          BankPmtApplRule, BankAccReconciliationLine, NoOfEntriesWithinRange, NoOfEntriesOutsideRange, VendorLedgerEntry2."Entry No.");
        VerifyNoOfEntriesWithingAndOutsideToleranceRangeForVendor(
          BankPmtApplRule, BankAccReconciliationLine, NoOfEntriesWithinRange, NoOfEntriesOutsideRange, VendorLedgerEntry3."Entry No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure VendorMixOfInvoicesWithAndWithoutDiscountsPaidCorrectly()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
        VendorLedgerEntry3: Record "Vendor Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        AppliedPaymentEntry: Record "Applied Payment Entry";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        Amount2: Decimal;
        Amount3: Decimal;
        AppliedAmount: Decimal;
        DiscountedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
        NoOfEntriesWithinRange: Integer;
        NoOfEntriesOutsideRange: Integer;
    begin
        Initialize();

        // Setup
        Amount := LibraryRandom.RandDecInRange(1, 10000, 2);
        Amount2 := LibraryRandom.RandDecInRange(1, 10000, 2);
        Amount3 := LibraryRandom.RandDecInRange(1, 10000, 2);

        // Paid on time
        CreateAndPostPurchaseInvoiceWithOneLine(VendorLedgerEntry, Amount, '', true);

        // No discount
        CreateAndPostPurchaseInvoiceWithOneLine(VendorLedgerEntry2, Amount2, VendorLedgerEntry."Vendor No.", false);

        // Not paid on time but paid full amount
        CreateAndPostPurchaseInvoiceWithOneLine(VendorLedgerEntry3, Amount3, VendorLedgerEntry."Vendor No.", true);
        VendorLedgerEntry3."Pmt. Discount Date" := CalcDate('<-10D>', VendorLedgerEntry."Pmt. Discount Date");
        VendorLedgerEntry3."Pmt. Disc. Tolerance Date" := VendorLedgerEntry3."Pmt. Discount Date";
        CODEUNIT.Run(CODEUNIT::"Vend. Entry-Edit", VendorLedgerEntry3);

        DiscountedAmount := VendorLedgerEntry."Remaining Amount" - VendorLedgerEntry."Remaining Pmt. Disc. Possible";

        CreateBankReconciliation(BankAccReconciliation);
        CreateBankReconciliationLine(
          BankAccReconciliationLine, BankAccReconciliation, DiscountedAmount,
          VendorLedgerEntry."Pmt. Discount Date",
          VendorLedgerEntry."Document No.");

        // Excercise
        RunMatch(TempBankStatementMatchingBuffer, BankAccReconciliation, true);

        // Full amount paid on a signle invoice
        GetMatchConfidence(
          BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No, BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match");

        Difference := 0;
        AppliedAmount := DiscountedAmount;
        NoOfEntries := 1;
        VerifyBankAccReconcilationLine(BankAccReconciliationLine, AppliedAmount, Difference, NoOfEntries);
        GetAppliedPaymentEntries(AppliedPaymentEntry, BankAccReconciliationLine);
        VerifyAppliedEntries(
          AppliedPaymentEntry, BankPmtApplRule, -Amount, VendorLedgerEntry."Remaining Pmt. Disc. Possible", VendorLedgerEntry."Entry No.");

        NoOfEntriesWithinRange := 1;
        NoOfEntriesOutsideRange := 2;
        VerifyNoOfEntriesWithingAndOutsideToleranceRangeForVendor(
          BankPmtApplRule, BankAccReconciliationLine, NoOfEntriesWithinRange, NoOfEntriesOutsideRange, VendorLedgerEntry."Entry No.");

        GetMatchConfidence(
          BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No, BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");

        VerifyNoOfEntriesWithingAndOutsideToleranceRangeForVendor(
          BankPmtApplRule, BankAccReconciliationLine, NoOfEntriesWithinRange, NoOfEntriesOutsideRange, VendorLedgerEntry2."Entry No.");
        VerifyNoOfEntriesWithingAndOutsideToleranceRangeForVendor(
          BankPmtApplRule, BankAccReconciliationLine, NoOfEntriesWithinRange, NoOfEntriesOutsideRange, VendorLedgerEntry3."Entry No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure VendorMixOfInvoicesWithAndWithoutDiscountsPaidIncorrectly()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
        VendorLedgerEntry3: Record "Vendor Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        AppliedPaymentEntry: Record "Applied Payment Entry";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        Amount2: Decimal;
        Amount3: Decimal;
        AppliedAmount: Decimal;
        DiscountedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
        NoOfEntriesWithinRange: Integer;
        NoOfEntriesOutsideRange: Integer;
    begin
        Initialize();

        // Setup
        Amount := LibraryRandom.RandDecInRange(1, 10000, 2);
        Amount2 := LibraryRandom.RandDecInRange(1, 10000, 2);
        Amount3 := LibraryRandom.RandDecInRange(1, 10000, 2);

        // Paid on time
        CreateAndPostPurchaseInvoiceWithOneLine(VendorLedgerEntry, Amount, '', true);

        // No discount
        CreateAndPostPurchaseInvoiceWithOneLine(VendorLedgerEntry2, Amount2, VendorLedgerEntry."Vendor No.", false);

        // Not paid on time but paid full amount
        CreateAndPostPurchaseInvoiceWithOneLine(VendorLedgerEntry3, Amount3, VendorLedgerEntry."Vendor No.", true);
        VendorLedgerEntry3."Pmt. Discount Date" := CalcDate('<-10D>', VendorLedgerEntry."Pmt. Discount Date");
        VendorLedgerEntry3."Pmt. Disc. Tolerance Date" := VendorLedgerEntry3."Pmt. Discount Date";
        CODEUNIT.Run(CODEUNIT::"Vend. Entry-Edit", VendorLedgerEntry3);

        DiscountedAmount := VendorLedgerEntry."Remaining Amount" - VendorLedgerEntry."Remaining Pmt. Disc. Possible";

        CreateBankReconciliation(BankAccReconciliation);
        CreateBankReconciliationLine(
          BankAccReconciliationLine, BankAccReconciliation, DiscountedAmount,
          CalcDate('<+1D>', VendorLedgerEntry."Pmt. Discount Date"),
          VendorLedgerEntry."Document No.");

        // Excercise
        RunMatch(TempBankStatementMatchingBuffer, BankAccReconciliation, true);

        // Full amount paid on a signle invoice
        GetMatchConfidence(
          BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No, BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");

        Difference := 0;
        AppliedAmount := DiscountedAmount;
        NoOfEntries := 1;
        VerifyBankAccReconcilationLine(BankAccReconciliationLine, AppliedAmount, Difference, NoOfEntries);
        GetAppliedPaymentEntries(AppliedPaymentEntry, BankAccReconciliationLine);
        VerifyAppliedEntries(AppliedPaymentEntry, BankPmtApplRule, AppliedAmount, 0, VendorLedgerEntry."Entry No.");

        NoOfEntriesWithinRange := 0;
        NoOfEntriesOutsideRange := 3;
        VerifyNoOfEntriesWithingAndOutsideToleranceRangeForVendor(
          BankPmtApplRule, BankAccReconciliationLine, NoOfEntriesWithinRange, NoOfEntriesOutsideRange, VendorLedgerEntry."Entry No.");

        GetMatchConfidence(
          BankPmtApplRule, BankPmtApplRule."Related Party Matched"::No, BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches");

        VerifyNoOfEntriesWithingAndOutsideToleranceRangeForVendor(
          BankPmtApplRule, BankAccReconciliationLine, NoOfEntriesWithinRange, NoOfEntriesOutsideRange, VendorLedgerEntry2."Entry No.");
        VerifyNoOfEntriesWithingAndOutsideToleranceRangeForVendor(
          BankPmtApplRule, BankAccReconciliationLine, NoOfEntriesWithinRange, NoOfEntriesOutsideRange, VendorLedgerEntry3."Entry No.");
    end;

    local procedure CreateBankReconciliation(var BankAccReconciliation: Record "Bank Acc. Reconciliation")
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation, BankAccount."No.",
          BankAccReconciliation."Statement Type"::"Payment Application");
    end;

    local procedure CreateBankReconciliationAmountTolerance(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; ToleranceValue: Decimal)
    var
        BankAccount: Record "Bank Account";
    begin
        CreateBankReconciliation(BankAccReconciliation);
        BankAccount.Get(BankAccReconciliation."Bank Account No.");
        BankAccount.Validate("Match Tolerance Type", BankAccount."Match Tolerance Type"::Amount);
        BankAccount.Validate("Match Tolerance Value", ToleranceValue);
        BankAccount.Modify(true);
    end;

    local procedure CreateBankReconciliationPercentageTolerance(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; ToleranceValue: Decimal)
    var
        BankAccount: Record "Bank Account";
    begin
        CreateBankReconciliation(BankAccReconciliation);
        BankAccount.Get(BankAccReconciliation."Bank Account No.");
        BankAccount.Validate("Match Tolerance Type", BankAccount."Match Tolerance Type"::Percentage);
        BankAccount.Validate("Match Tolerance Value", ToleranceValue);
        BankAccount.Modify(true);
    end;

    local procedure CreateBankReconciliationLine(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; BankAccReconciliation: Record "Bank Acc. Reconciliation"; Amount: Decimal; TransactionDate: Date; TransactionText: Text[140])
    begin
        LibraryERM.CreateBankAccReconciliationLn(BankAccReconciliationLine, BankAccReconciliation);
        BankAccReconciliationLine.Validate("Transaction Text", TransactionText);
        BankAccReconciliationLine.Validate("Transaction Date", TransactionDate);
        BankAccReconciliationLine.Validate("Statement Amount", Amount);
        BankAccReconciliationLine.Modify(true);
    end;

    local procedure CreateAndPostSalesInvoiceWithOneLine(var CustLedgerEntry: Record "Cust. Ledger Entry"; Amount: Decimal; CustomerNo: Code[20]; AddDiscount: Boolean)
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        if CustomerNo = '' then begin
            LibrarySales.CreateCustomer(Customer);
            CustomerNo := Customer."No.";
        end;

        CreateItem(Item, Amount);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);

        if AddDiscount then
            SalesHeader.Validate("Payment Terms Code", PaymentTermsDiscount.Code)
        else
            SalesHeader.Validate("Payment Terms Code", PaymentTermsNoDiscount.Code);

        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        Clear(CustLedgerEntry);
        CustLedgerEntry.Init();
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.CalcFields("Remaining Amount");
    end;

    local procedure CreateAndPostPurchaseInvoiceWithOneLine(var VendorLedgerEntry: Record "Vendor Ledger Entry"; Amount: Decimal; VendorNo: Code[20]; AddDiscount: Boolean)
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        if VendorNo = '' then begin
            LibraryPurchase.CreateVendor(Vendor);
            VendorNo := Vendor."No.";
        end;

        CreateItem(Item, Amount);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);

        if AddDiscount then
            PurchaseHeader.Validate("Payment Terms Code", PaymentTermsDiscount.Code)
        else
            PurchaseHeader.Validate("Payment Terms Code", PaymentTermsNoDiscount.Code);

        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);

        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        Clear(VendorLedgerEntry);
        VendorLedgerEntry.Init();
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.CalcFields("Remaining Amount");
    end;

    [Normal]
    local procedure CreateItem(var Item: Record Item; Amount: Decimal)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", ZeroVATPostingSetup."VAT Prod. Posting Group");
        Item.Validate("Unit Price", Amount);
        Item.Validate("Last Direct Cost", Amount);
        Item.Modify(true);
    end;

    [Normal]
    local procedure CloseExistingEntries()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        CustLedgerEntry.SetRange(Open, true);
        CustLedgerEntry.ModifyAll(Open, false);

        VendorLedgerEntry.SetRange(Open, true);
        VendorLedgerEntry.ModifyAll(Open, false);
    end;

    local procedure GetAppliedPaymentEntries(var AppliedPaymentEntry: Record "Applied Payment Entry"; BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    begin
        AppliedPaymentEntry.SetRange("Statement Type", BankAccReconciliationLine."Statement Type");
        AppliedPaymentEntry.SetRange("Bank Account No.", BankAccReconciliationLine."Bank Account No.");
        AppliedPaymentEntry.SetRange("Statement No.", BankAccReconciliationLine."Statement No.");
        AppliedPaymentEntry.SetRange("Statement Line No.", BankAccReconciliationLine."Statement Line No.");
        AppliedPaymentEntry.FindSet();
    end;

    local procedure RunMatch(var TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary; BankAccReconciliation: Record "Bank Acc. Reconciliation"; ApplyEntries: Boolean)
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        MatchBankPayments: Codeunit "Match Bank Payments";
    begin
        if ApplyEntries then
            LibraryVariableStorage.Enqueue(LinesAreAppliedTxt);

        BankAccReconciliationLine.SetRange("Statement Type", BankAccReconciliation."Statement Type");
        BankAccReconciliationLine.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        MatchBankPayments.SetApplyEntries(ApplyEntries);
        MatchBankPayments.Code(BankAccReconciliationLine);

        MatchBankPayments.GetBankStatementMatchingBuffer(TempBankStatementMatchingBuffer);
    end;

    local procedure GetMatchConfidence(var BankPmtApplRule: Record "Bank Pmt. Appl. Rule"; RelatedPartyMatched: Option; DocNoMatched: Option; AmountInclToleranceMatched: Option)
    var
        TempBankPmtApplRule: Record "Bank Pmt. Appl. Rule" temporary;
    begin
        Clear(BankPmtApplRule);

        BankPmtApplRule."Related Party Matched" := RelatedPartyMatched;
        BankPmtApplRule."Doc. No./Ext. Doc. No. Matched" := DocNoMatched;
        BankPmtApplRule."Amount Incl. Tolerance Matched" := AmountInclToleranceMatched;

        TempBankPmtApplRule.LoadRules();
        BankPmtApplRule.Score := TempBankPmtApplRule.GetBestMatchScore(BankPmtApplRule);
        BankPmtApplRule."Match Confidence" := TempBankPmtApplRule."Match Confidence";
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        ExpectedMsg: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMsg);
        Assert.IsTrue(StrPos(Message, ExpectedMsg) > 0, Message);
    end;

    local procedure VerifyBankAccReconcilationLine(BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; ExpectedAppliedAmount: Decimal; ExpectedDifference: Decimal; ExpectedNoOfEntries: Integer)
    begin
        BankAccReconciliationLine.Get(
          BankAccReconciliationLine."Statement Type",
          BankAccReconciliationLine."Bank Account No.",
          BankAccReconciliationLine."Statement No.",
          BankAccReconciliationLine."Statement Line No."
          );

        Assert.AreEqual(
          ExpectedDifference, BankAccReconciliationLine.Difference, 'Expected difference is wrong on BankAccReconciliationLine');
        Assert.AreEqual(
          ExpectedAppliedAmount, BankAccReconciliationLine."Applied Amount",
          'Expected Applied Amount is wrong on BankAccReconciliationLine');
        Assert.AreEqual(ExpectedNoOfEntries, BankAccReconciliationLine."Applied Entries", 'No of Applied Entries is wrong');
    end;

    local procedure VerifyAppliedEntries(AppliedPaymentEntry: Record "Applied Payment Entry"; BankPmtApplRule: Record "Bank Pmt. Appl. Rule"; ExpectedAppliedAmount: Decimal; ExpectedAppliedPmtDiscount: Decimal; ExpectedEntryNo: Integer)
    begin
        Assert.AreEqual(ExpectedAppliedAmount, AppliedPaymentEntry."Applied Amount", 'Expected Applied Amount was not correct');
        Assert.AreEqual(
          ExpectedAppliedPmtDiscount, AppliedPaymentEntry."Applied Pmt. Discount", 'Expected Applied Pmt Discount is not correct');
        Assert.AreEqual(ExpectedEntryNo, AppliedPaymentEntry."Applies-to Entry No.", 'Expected Entry No is not correct');
        Assert.AreEqual(BankPmtApplRule.Score, AppliedPaymentEntry.Quality, 'Quailty is not correct');
    end;

    local procedure VerifyNoOfEntriesWithingAndOutsideToleranceRangeForCustomer(ExpectedBankPmtApplRule: Record "Bank Pmt. Appl. Rule"; BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; ExpectedNoOfEntriesWithinRange: Integer; ExpectedNoOfEntriesOutsideRange: Integer; CustomerLedgerEntryNo: Integer)
    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        MatchBankPayments: Codeunit "Match Bank Payments";
        NoOfEntriesWithinRange: Integer;
        NoOfEntriesOutsideRange: Integer;
    begin
        MatchBankPayments.MatchSingleLineCustomer(
          BankPmtApplRule, BankAccReconciliationLine, CustomerLedgerEntryNo, NoOfEntriesWithinRange, NoOfEntriesOutsideRange);

        // Verify rule was identified correctly
        Assert.AreEqual(
          ExpectedBankPmtApplRule."Related Party Matched", BankPmtApplRule."Related Party Matched", 'Wrong Match Confidence Set');
        Assert.AreEqual(
          ExpectedBankPmtApplRule."Doc. No./Ext. Doc. No. Matched", BankPmtApplRule."Doc. No./Ext. Doc. No. Matched",
          'Wrong Match Confidence Set');
        Assert.AreEqual(
          ExpectedBankPmtApplRule."Amount Incl. Tolerance Matched", BankPmtApplRule."Amount Incl. Tolerance Matched",
          'Wrong Match Confidence Set');

        // Verify No. of entries is correct
        Assert.AreEqual(ExpectedNoOfEntriesWithinRange, NoOfEntriesWithinRange, 'Wrong No. of Entries Within Range');
        Assert.AreEqual(ExpectedNoOfEntriesOutsideRange, NoOfEntriesOutsideRange, 'Wrong No. of Entries outside Range');
    end;

    local procedure VerifyNoOfEntriesWithingAndOutsideToleranceRangeForVendor(ExpectedBankPmtApplRule: Record "Bank Pmt. Appl. Rule"; BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; ExpectedNoOfEntriesWithinRange: Integer; ExpectedNoOfEntriesOutsideRange: Integer; VendorLedgerEntryNo: Integer)
    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        MatchBankPayments: Codeunit "Match Bank Payments";
        NoOfEntriesWithinRange: Integer;
        NoOfEntriesOutsideRange: Integer;
    begin
        MatchBankPayments.MatchSingleLineVendor(
          BankPmtApplRule, BankAccReconciliationLine, VendorLedgerEntryNo, NoOfEntriesWithinRange, NoOfEntriesOutsideRange);

        // Verify rule was identified correctly
        Assert.AreEqual(
          ExpectedBankPmtApplRule."Related Party Matched", BankPmtApplRule."Related Party Matched", 'Wrong Match Confidence Set');
        Assert.AreEqual(
          ExpectedBankPmtApplRule."Doc. No./Ext. Doc. No. Matched", BankPmtApplRule."Doc. No./Ext. Doc. No. Matched",
          'Wrong Match Confidence Set');
        Assert.AreEqual(
          ExpectedBankPmtApplRule."Amount Incl. Tolerance Matched", BankPmtApplRule."Amount Incl. Tolerance Matched",
          'Wrong Match Confidence Set');

        // Verify No. of entries is correct
        Assert.AreEqual(ExpectedNoOfEntriesWithinRange, NoOfEntriesWithinRange, 'Wrong No. of Entries Within Range');
        Assert.AreEqual(ExpectedNoOfEntriesOutsideRange, NoOfEntriesOutsideRange, 'Wrong No. of Entries outside Range');
    end;
}

