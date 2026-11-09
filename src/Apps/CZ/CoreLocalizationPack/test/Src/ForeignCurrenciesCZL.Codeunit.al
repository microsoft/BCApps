codeunit 148088 "Foreign Currencies CZL"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Core] [Foreign Currencies]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryHumanResource: Codeunit "Library - Human Resource";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        IsInitialized: Boolean;
        AmountErr: Label 'Amounts must be the same.';
        ExchRateWasAdjustedTxt: Label 'One or more currency exchange rates have been adjusted.';

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Foreign Currencies CZL");

        LibraryVariableStorage.Clear();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Foreign Currencies CZL");

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Foreign Currencies CZL");
    end;

    [Test]
    [HandlerFunctions('RequestPageAdjustExchangeRatesHandler')]
    procedure AdjustExchangeRateSplitToCustomer()
    begin
        AdjustExchangeRateSplit(true, false);
    end;

    [Test]
    [HandlerFunctions('RequestPageAdjustExchangeRatesHandler')]
    procedure AdjustExchangeRateSplitToVendor()
    begin
        AdjustExchangeRateSplit(false, true);
    end;

    local procedure AdjustExchangeRateSplit(AdjCust: Boolean; AdjVend: Boolean)
    var
        CurrencyCode: Code[10];
        CurrExchRateDate: array[2] of Date;
        DocumentNo: array[3] of Code[20];
    begin
        Initialize();

        // [GIVEN] The currency with exchange rate has been created
        CurrExchRateDate[1] := WorkDate();
        CurrExchRateDate[2] := CalcDate('<1D>', CurrExchRateDate[1]);
        CurrencyCode := CreateCurrency(CurrExchRateDate);

        // [GIVEN] The Customer Ledger Entries with created currency have been created
        DocumentNo[1] := CreateCustomerLedgerEntries(CurrencyCode, CurrExchRateDate);

        // [GIVEN] The Vendor Ledger Entries with created currency have been created
        DocumentNo[2] := CreateVendorLedgerEntries(CurrencyCode, CurrExchRateDate);

        // [WHEN] Run adjust exchnage rates report
        DocumentNo[3] := GenerateDocumentNo(CurrExchRateDate[1]);
        RunAdjustExchangeRates(
          CurrencyCode, CurrExchRateDate[1], CurrExchRateDate[2], DocumentNo[3], AdjCust, AdjVend, false, false, false);

        // [THEN] The document number in report will be filled from customer/vendor ledger entry
        if AdjCust then
            LibraryReportDataset.AssertElementWithValueExists('CLEDocumentNo_Fld', DocumentNo[1])
        else
            LibraryReportDataset.AssertElementWithValueNotExist('CLEDocumentNo_Fld', DocumentNo[1]);
        if AdjVend then
            LibraryReportDataset.AssertElementWithValueExists('VLEDocumentNo_Fld', DocumentNo[2])
        else
            LibraryReportDataset.AssertElementWithValueNotExist('VLEDocumentNo_Fld', DocumentNo[2]);
    end;

    [Test]
    [HandlerFunctions('RequestPageAdjustExchangeRatesHandler')]
    procedure AdjustExchangeRateTestReport()
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        DetailedEmployeeLedgerEntry: Record "Detailed Employee Ledger Entry";
        CurrencyCode: Code[10];
        CurrExchRateDate: array[2] of Date;
        DocumentNo: Code[20];
    begin
        Initialize();

        // [GIVEN] The currency with exchange rate has been created
        CurrExchRateDate[1] := WorkDate();
        CurrExchRateDate[2] := CalcDate('<1D>', CurrExchRateDate[1]);
        CurrencyCode := CreateCurrency(CurrExchRateDate);

        // [GIVEN] The Customer Ledger Entries with created currency have been created
        CreateCustomerLedgerEntries(CurrencyCode, CurrExchRateDate);

        // [GIVEN] The Vendor Ledger Entries with created currency have been created
        CreateVendorLedgerEntries(CurrencyCode, CurrExchRateDate);

        // [GIVEN] The Employee Ledger Entries with created currency have been created
        CreateEmployeeLedgerEntries(CurrencyCode, CurrExchRateDate);

        // [WHEN] Run adjust exchange rates report
        DocumentNo := GenerateDocumentNo(CurrExchRateDate[1]);
        RunAdjustExchangeRates(
          CurrencyCode, CurrExchRateDate[1], CurrExchRateDate[2], DocumentNo, true, true, false, true, false);

        // [THEN] The post parameter on request page will be false
        LibraryReportDataset.AssertElementWithValueExists('PostVar', Format(false));

        // [THEN] The Detail Customer Ledger Entries won't be exist
        DetailedCustLedgEntry.Reset();
        DetailedCustLedgEntry.SetRange("Entry Type", DetailedCustLedgEntry."Entry Type"::"Unrealized Loss");
        DetailedCustLedgEntry.SetRange("Document No.", DocumentNo);
        Assert.RecordIsEmpty(DetailedCustLedgEntry);

        // [THEN] The Detail Vendor Ledger Entries won't be exist
        DetailedVendorLedgEntry.Reset();
        DetailedVendorLedgEntry.SetRange("Entry Type", DetailedVendorLedgEntry."Entry Type"::"Unrealized Gain");
        DetailedVendorLedgEntry.SetRange("Document No.", DocumentNo);
        Assert.RecordIsEmpty(DetailedVendorLedgEntry);

        // [THEN] The Detail Employee Ledger Entries won't be exist
        DetailedEmployeeLedgerEntry.Reset();
        DetailedEmployeeLedgerEntry.SetRange("Entry Type", DetailedEmployeeLedgerEntry."Entry Type"::"Unrealized Gain");
        DetailedEmployeeLedgerEntry.SetRange("Document No.", DocumentNo);
        Assert.RecordIsEmpty(DetailedEmployeeLedgerEntry);
    end;

    [Test]
    [HandlerFunctions('RequestPageAdjustExchangeRatesHandler,StatisticsMessageHandler')]
    procedure AdjustExchangeRatePostingByEntries()
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        DetailedEmployeeLedgerEntry: Record "Detailed Employee Ledger Entry";
        CurrencyCode: Code[10];
        CurrExchRateDate: array[2] of Date;
        DocumentNo: Code[20];
    begin
        Initialize();

        // [GIVEN] The currency with exchange rate has been created
        CurrExchRateDate[1] := WorkDate();
        CurrExchRateDate[2] := CalcDate('<1D>', CurrExchRateDate[1]);
        CurrencyCode := CreateCurrency(CurrExchRateDate);

        // [GIVEN] The Customer Ledger Entries with created currency have been created
        CreateCustomerLedgerEntries(CurrencyCode, CurrExchRateDate);

        // [GIVEN] The Vendor Ledger Entries with created currency have been created
        CreateVendorLedgerEntries(CurrencyCode, CurrExchRateDate);

        // [GIVEN] The Employee Ledger Entries with created currency have been created
        CreateEmployeeLedgerEntries(CurrencyCode, CurrExchRateDate);

        // [WHEN] Run adjust exchange rates report
        DocumentNo := GenerateDocumentNo(CurrExchRateDate[1]);
        RunAdjustExchangeRates(
          CurrencyCode, CurrExchRateDate[1], CurrExchRateDate[2], DocumentNo, true, true, false, true, true);

        // [THEN] The Detail Customer Ledger Entries will be exist
        DetailedCustLedgEntry.Reset();
        DetailedCustLedgEntry.SetRange("Entry Type", DetailedCustLedgEntry."Entry Type"::"Unrealized Loss");
        DetailedCustLedgEntry.SetRange("Document No.", DocumentNo);
        Assert.RecordIsNotEmpty(DetailedCustLedgEntry);

        // [THEN] The Detail Vendor Ledger Entries will be exist
        DetailedVendorLedgEntry.Reset();
        DetailedVendorLedgEntry.SetRange("Entry Type", DetailedVendorLedgEntry."Entry Type"::"Unrealized Gain");
        DetailedVendorLedgEntry.SetRange("Document No.", DocumentNo);
        Assert.RecordIsNotEmpty(DetailedVendorLedgEntry);

        // [THEN] The Detail Employee Ledger Entries will be exist
        DetailedEmployeeLedgerEntry.Reset();
        DetailedEmployeeLedgerEntry.SetRange("Entry Type", DetailedEmployeeLedgerEntry."Entry Type"::"Unrealized Gain");
        DetailedEmployeeLedgerEntry.SetRange("Document No.", DocumentNo);
        Assert.RecordIsNotEmpty(DetailedEmployeeLedgerEntry);
    end;

    [Test]
    [HandlerFunctions('RequestPageAdjustExchangeRatesHandler,StatisticsMessageHandler')]
    procedure AdjustExchangeRateIncrementalPosting()
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyCode: Code[10];
        CurrExchRateDate: array[2] of Date;
        DocumentNo: Code[20];
        Amount: Decimal;
        ExchRateAmount: Decimal;
        OriginalAmountLCY: Decimal;
    begin
        Initialize();

        // [GIVEN] The currency with exchange rate has been created
        CurrExchRateDate[1] := WorkDate();
        CurrExchRateDate[2] := CalcDate('<1D>', CurrExchRateDate[1]);
        CurrencyCode := LibraryERM.CreateCurrencyWithGLAccountSetup();

        // [GIVEN] The currency exchange rate for the first date has been created
        ExchRateAmount := LibraryRandom.RandDec(1, 2);
        LibraryERM.CreateExchangeRate(CurrencyCode, CurrExchRateDate[1], ExchRateAmount, ExchRateAmount);

        // [GIVEN] The general journal batch has been selected
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);

        // [GIVEN] The general journal line has been created
        Amount := LibraryRandom.RandDec(1000, 2);
        DocumentNo := CreateJournalLine(
            GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Invoice,
            GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
            Amount, CurrExchRateDate[2], CurrencyCode);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] The currency exchange rate for the second date has been created
        LibraryERM.CreateExchangeRate(CurrencyCode, CurrExchRateDate[2], ExchRateAmount * 2, ExchRateAmount * 2);
        Commit();

        // [WHEN] Run adjust exchange rates report
        RunAdjustExchangeRates(
          CurrencyCode, CurrExchRateDate[1], CurrExchRateDate[2], DocumentNo, true, false, false, false, true);

        // [THEN] The Detail Customer Ledger Entries will be exist
        DetailedCustLedgEntry.Reset();
        DetailedCustLedgEntry.SetRange("Entry Type", DetailedCustLedgEntry."Entry Type"::"Initial Entry");
        DetailedCustLedgEntry.SetRange("Document Type", DetailedCustLedgEntry."Document Type"::Invoice);
        DetailedCustLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedCustLedgEntry.FindFirst();
        OriginalAmountLCY := DetailedCustLedgEntry."Amount (LCY)";

        DetailedCustLedgEntry.Reset();
        DetailedCustLedgEntry.SetRange("Entry Type", DetailedCustLedgEntry."Entry Type"::"Unrealized Loss");
        DetailedCustLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedCustLedgEntry.FindFirst();
        Assert.AreEqual(
          Round((1 / CurrencyExchangeRate.GetCurrentCurrencyFactor(CurrencyCode)) * Amount),
          OriginalAmountLCY + DetailedCustLedgEntry."Amount (LCY)", AmountErr);
    end;

    [Test]
    procedure IncrementalExchangePostingEnabledByDefault()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // [SCENARIO] New companies use incremental posting of exchange gains and losses by default.
        // [WHEN] A new general ledger setup record is initialized
        GeneralLedgerSetup.Init();

        // [THEN] Incremental posting is not disabled
        Assert.IsFalse(GeneralLedgerSetup."Disable Incr. Exch. Post. CZL", 'Incremental exchange posting must be enabled by default.');
    end;

    [Test]
    [HandlerFunctions('RequestPageAdjustExchangeRatesHandler,StatisticsMessageHandler')]
    procedure DisableIncrementalPostingReversesUnrealizedLoss()
    var
        InvoiceEntry: Record "Cust. Ledger Entry";
        PaymentEntry: Record "Cust. Ledger Entry";
        GenJournalBatch: Record "Gen. Journal Batch";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        InvoiceAmount: Decimal;
        OriginalCurrencyFactor: Decimal;
        AdjustedCurrencyFactor: Decimal;
        PaymentCurrencyFactor: Decimal;
    begin
        // [SCENARIO] With incremental posting disabled, final application reverses unrealized losses and realizes the loss from the original exchange rate.
        Initialize();

        // [GIVEN] Incremental posting is disabled
        SetDisableIncrementalExchangePosting(true);
        InvoiceAmount := 1000;
        OriginalCurrencyFactor := 1;
        AdjustedCurrencyFactor := 2;
        PaymentCurrencyFactor := 4;

        // [GIVEN] An invoice for 1,000 FCY (1,000 LCY) revalued to 500 LCY, with an unrealized loss of 500 LCY
        CreateAdjustedCustomerInvoice(
            InvoiceEntry, GenJournalBatch, InvoiceAmount, OriginalCurrencyFactor, AdjustedCurrencyFactor);
        VerifyDetailedCustomerAmount(
            InvoiceEntry."Entry No.", DetailedCustLedgEntry."Entry Type"::"Unrealized Loss",
            Round(InvoiceAmount / AdjustedCurrencyFactor) - Round(InvoiceAmount / OriginalCurrencyFactor));

        // [WHEN] A payment of 1,000 FCY (250 LCY) is posted and fully applied to the invoice
        PostPaymentAndApplyCustomerInvoice(InvoiceEntry, GenJournalBatch, PaymentCurrencyFactor, PaymentEntry);

        // [THEN] The unrealized loss is reversed and the realized loss is based on the original exchange rate
        VerifyDetailedCustomerAmount(InvoiceEntry."Entry No.", DetailedCustLedgEntry."Entry Type"::"Unrealized Loss", 0);
        VerifyDetailedCustomerAmount(
            PaymentEntry."Entry No.", DetailedCustLedgEntry."Entry Type"::"Realized Loss",
            Round(InvoiceAmount / PaymentCurrencyFactor) - Round(InvoiceAmount / OriginalCurrencyFactor));
        VerifyCustomerEntryClosed(InvoiceEntry);
        VerifyCustomerEntryClosed(PaymentEntry);
    end;

    [Test]
    [HandlerFunctions('RequestPageAdjustExchangeRatesHandler,StatisticsMessageHandler')]
    procedure KeepIncrementalPostingDoesNotReverseUnrealizedLoss()
    var
        InvoiceEntry: Record "Cust. Ledger Entry";
        PaymentEntry: Record "Cust. Ledger Entry";
        GenJournalBatch: Record "Gen. Journal Batch";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        InvoiceAmount: Decimal;
        OriginalCurrencyFactor: Decimal;
        AdjustedCurrencyFactor: Decimal;
        PaymentCurrencyFactor: Decimal;
    begin
        // [SCENARIO] With incremental posting enabled, final application retains unrealized losses and realizes only the additional loss since revaluation.
        Initialize();

        // [GIVEN] Incremental posting remains enabled
        SetDisableIncrementalExchangePosting(false);
        InvoiceAmount := 1000;
        OriginalCurrencyFactor := 1;
        AdjustedCurrencyFactor := 2;
        PaymentCurrencyFactor := 4;

        // [GIVEN] An invoice for 1,000 FCY (1,000 LCY) revalued to 500 LCY, with an unrealized loss of 500 LCY
        CreateAdjustedCustomerInvoice(
            InvoiceEntry, GenJournalBatch, InvoiceAmount, OriginalCurrencyFactor, AdjustedCurrencyFactor);
        VerifyDetailedCustomerAmount(
            InvoiceEntry."Entry No.", DetailedCustLedgEntry."Entry Type"::"Unrealized Loss",
            Round(InvoiceAmount / AdjustedCurrencyFactor) - Round(InvoiceAmount / OriginalCurrencyFactor));

        // [WHEN] A payment of 1,000 FCY (250 LCY) is posted and fully applied to the invoice
        PostPaymentAndApplyCustomerInvoice(InvoiceEntry, GenJournalBatch, PaymentCurrencyFactor, PaymentEntry);

        // [THEN] The unrealized loss is not reversed; only the additional loss since revaluation is realized
        VerifyDetailedCustomerAmount(
            InvoiceEntry."Entry No.", DetailedCustLedgEntry."Entry Type"::"Unrealized Loss",
            Round(InvoiceAmount / AdjustedCurrencyFactor) - Round(InvoiceAmount / OriginalCurrencyFactor));
        VerifyDetailedCustomerAmount(
            PaymentEntry."Entry No.", DetailedCustLedgEntry."Entry Type"::"Realized Loss",
            Round(InvoiceAmount / PaymentCurrencyFactor) - Round(InvoiceAmount / AdjustedCurrencyFactor));
        VerifyCustomerEntryClosed(InvoiceEntry);
        VerifyCustomerEntryClosed(PaymentEntry);
    end;

    [Test]
    procedure AppliedAmountLCYUsesAdjustedRateForIncrementalPosting()
    var
        NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer";
        OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer";
        OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer";
        GenJnlPostLineMgtCZL: Codeunit "Gen. Jnl.-Post Line Mgt. CZL";
        OldAppliedAmount: Decimal;
        AppliedAmount: Decimal;
        AppliedAmountLCY: Decimal;
    begin
        // [SCENARIO] Incremental posting values an application in local currency using the latest adjusted exchange rate.
        Initialize();

        // [GIVEN] An application of 1,000 FCY and an entry revalued from a factor of 1 to a factor of 2
        SetDisableIncrementalExchangePosting(false);
        NewCVLedgEntryBuf."Currency Code" := 'EUR';
        OldCVLedgEntryBuf2."Currency Code" := NewCVLedgEntryBuf."Currency Code";
        OldCVLedgEntryBuf."Original Currency Factor" := 1;
        OldCVLedgEntryBuf."Adjusted Currency Factor" := 2;
        AppliedAmount := 1000;
        OldAppliedAmount := AppliedAmount;
        AppliedAmountLCY := Round(AppliedAmount / OldCVLedgEntryBuf."Original Currency Factor");

        // [WHEN] The Czech calculation processes the W1 applied amount of 1,000 LCY
        GenJnlPostLineMgtCZL.CalcAppliedAmountLCY(
            NewCVLedgEntryBuf, OldCVLedgEntryBuf, OldCVLedgEntryBuf2, OldAppliedAmount, AppliedAmount, AppliedAmountLCY);

        // [THEN] The applied amount is recalculated at the adjusted rate to 500 LCY
        Assert.AreEqual(Round(AppliedAmount / OldCVLedgEntryBuf."Adjusted Currency Factor"), AppliedAmountLCY, AmountErr);
    end;

    [Test]
    procedure DisabledIncrementalPostingPreservesOriginalRateAmount()
    var
        NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer";
        OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer";
        OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer";
        GenJnlPostLineMgtCZL: Codeunit "Gen. Jnl.-Post Line Mgt. CZL";
        OldAppliedAmount: Decimal;
        AppliedAmount: Decimal;
        AppliedAmountLCY: Decimal;
        OriginalAppliedAmountLCY: Decimal;
    begin
        // [SCENARIO] Disabling incremental posting preserves the applied local currency amount calculated using the original exchange rate.
        Initialize();

        // [GIVEN] An application of 1,000 FCY with incremental posting disabled
        SetDisableIncrementalExchangePosting(true);
        NewCVLedgEntryBuf."Currency Code" := 'EUR';
        OldCVLedgEntryBuf2."Currency Code" := NewCVLedgEntryBuf."Currency Code";
        OldCVLedgEntryBuf."Original Currency Factor" := 1;
        OldCVLedgEntryBuf."Adjusted Currency Factor" := 2;
        AppliedAmount := 1000;
        OldAppliedAmount := AppliedAmount;
        OriginalAppliedAmountLCY := Round(AppliedAmount / OldCVLedgEntryBuf."Original Currency Factor");
        AppliedAmountLCY := OriginalAppliedAmountLCY;

        // [WHEN] The Czech calculation processes the W1 result
        GenJnlPostLineMgtCZL.CalcAppliedAmountLCY(
            NewCVLedgEntryBuf, OldCVLedgEntryBuf, OldCVLedgEntryBuf2, OldAppliedAmount, AppliedAmount, AppliedAmountLCY);

        // [THEN] The amount at the original rate is preserved, rather than recalculated at the adjusted rate
        Assert.AreEqual(OriginalAppliedAmountLCY, AppliedAmountLCY, AmountErr);
    end;

    [Test]
    procedure UnrealizedCalculationSuppressedOnlyForIncrementalPosting()
    var
        GenJnlPostLineMgtCZL: Codeunit "Gen. Jnl.-Post Line Mgt. CZL";
    begin
        // [SCENARIO] Unrealized exchange gains and losses are reversed on application only when incremental posting is disabled.
        Initialize();

        // [GIVEN] Incremental posting is enabled
        SetDisableIncrementalExchangePosting(false);

        // [THEN] The W1 unrealized calculation is suppressed
        Assert.IsTrue(GenJnlPostLineMgtCZL.IsCalcCurrencyUnrealizedGainLossSuppressed(), 'Incremental posting must suppress unrealized reversals.');

        // [WHEN] Incremental posting is disabled
        SetDisableIncrementalExchangePosting(true);

        // [THEN] The W1 unrealized calculation is allowed
        Assert.IsFalse(GenJnlPostLineMgtCZL.IsCalcCurrencyUnrealizedGainLossSuppressed(), 'Disabling incremental posting must allow unrealized reversals.');
    end;

    local procedure CreateAdjustedCustomerInvoice(var InvoiceEntry: Record "Cust. Ledger Entry"; var GenJournalBatch: Record "Gen. Journal Batch"; InvoiceAmount: Decimal; OriginalCurrencyFactor: Decimal; AdjustedCurrencyFactor: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        InstructionMgt: Codeunit "Instruction Mgt.";
        CurrencyCode: Code[10];
        InvoiceNo: Code[20];
        AdjustmentDate: Date;
    begin
        LibraryERM.DisableMyNotifications(CopyStr(UserId(), 1, 50), InstructionMgt.GetPostingAfterWorkingDateNotificationId());
        CurrencyCode := LibraryERM.CreateCurrencyWithGLAccountSetup();
        LibraryERM.CreateExchangeRate(CurrencyCode, WorkDate(), OriginalCurrencyFactor, OriginalCurrencyFactor);
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        InvoiceNo := CreateJournalLine(
            GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Invoice,
            GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(), InvoiceAmount, WorkDate(), CurrencyCode);
        GenJournalLine.Validate("Payment Discount %", 0);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        InvoiceEntry.SetRange("Document Type", InvoiceEntry."Document Type"::Invoice);
        InvoiceEntry.SetRange("Document No.", InvoiceNo);
        InvoiceEntry.SetRange("Currency Code", CurrencyCode);
        InvoiceEntry.FindFirst();

        AdjustmentDate := CalcDate('<1D>', WorkDate());
        LibraryERM.CreateExchangeRate(CurrencyCode, AdjustmentDate, AdjustedCurrencyFactor, AdjustedCurrencyFactor);
        Commit();
        RunAdjustExchangeRates(
            CurrencyCode, WorkDate(), AdjustmentDate, GenerateDocumentNo(AdjustmentDate), true, false, false, false, true);
    end;

    local procedure PostPaymentAndApplyCustomerInvoice(InvoiceEntry: Record "Cust. Ledger Entry"; GenJournalBatch: Record "Gen. Journal Batch"; PaymentCurrencyFactor: Decimal; var PaymentEntry: Record "Cust. Ledger Entry")
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentNo: Code[20];
        PaymentDate: Date;
    begin
        PaymentDate := CalcDate('<2D>', WorkDate());
        LibraryERM.CreateExchangeRate(InvoiceEntry."Currency Code", PaymentDate, PaymentCurrencyFactor, PaymentCurrencyFactor);
        InvoiceEntry.CalcFields("Original Amount");
        PaymentNo := CreateJournalLine(
            GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Payment,
            GenJournalLine."Account Type"::Customer, InvoiceEntry."Customer No.", -InvoiceEntry."Original Amount",
            PaymentDate, InvoiceEntry."Currency Code");
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", InvoiceEntry."Document No.");
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        PaymentEntry.SetRange("Customer No.", InvoiceEntry."Customer No.");
        PaymentEntry.SetRange("Document Type", PaymentEntry."Document Type"::Payment);
        PaymentEntry.SetRange("Document No.", PaymentNo);
        PaymentEntry.FindFirst();
    end;

    local procedure VerifyDetailedCustomerAmount(EntryNo: Integer; EntryType: Enum "Detailed CV Ledger Entry Type"; ExpectedAmountLCY: Decimal)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", EntryNo);
        DetailedCustLedgEntry.SetRange("Entry Type", EntryType);
        Assert.RecordIsNotEmpty(DetailedCustLedgEntry);
        DetailedCustLedgEntry.CalcSums("Amount (LCY)");
        Assert.AreEqual(ExpectedAmountLCY, DetailedCustLedgEntry."Amount (LCY)", AmountErr);
    end;

    local procedure VerifyCustomerEntryClosed(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        CustLedgerEntry.Get(CustLedgerEntry."Entry No.");
        CustLedgerEntry.TestField(Open, false);
        CustLedgerEntry.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
        CustLedgerEntry.TestField("Remaining Amount", 0);
        CustLedgerEntry.TestField("Remaining Amt. (LCY)", 0);
    end;

    local procedure SetDisableIncrementalExchangePosting(DisableIncrementalPosting: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Disable Incr. Exch. Post. CZL", DisableIncrementalPosting);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure CreateCurrency(CurrExchRateDate: array[2] of Date): Code[10]
    var
        CurrencyCode: Code[10];
        ExchRateAmount: Decimal;
    begin
        CurrencyCode := LibraryERM.CreateCurrencyWithGLAccountSetup();
        ExchRateAmount := LibraryRandom.RandDec(1, 2);
        LibraryERM.CreateExchangeRate(CurrencyCode, CurrExchRateDate[1], ExchRateAmount, ExchRateAmount);
        LibraryERM.CreateExchangeRate(CurrencyCode, CurrExchRateDate[2], ExchRateAmount * 2, ExchRateAmount * 2);
        exit(CurrencyCode);
    end;

    local procedure CreateCustomerLedgerEntries(CurrencyCode: Code[10]; PostingDate: array[2] of Date): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        exit(CreateLedgerEntries(
            GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(), CurrencyCode, PostingDate));
    end;

    local procedure CreateVendorLedgerEntries(CurrencyCode: Code[10]; PostingDate: array[2] of Date): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        exit(CreateLedgerEntries(
            GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(), CurrencyCode, PostingDate));
    end;

    local procedure CreateEmployeeLedgerEntries(CurrencyCode: Code[10]; PostingDate: array[2] of Date): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        exit(CreateLedgerEntries(
            GenJournalLine."Account Type"::Employee, LibraryHumanResource.CreateEmployeeNo(), CurrencyCode, PostingDate));
    end;

    local procedure CreateLedgerEntries(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; CurrencyCode: Code[10]; PostingDate: array[2] of Date): Code[20]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
        Amount: Decimal;
    begin
        Amount := LibraryRandom.RandDec(1000, 2);
        if (AccountType = GenJournalLine."Account Type"::Vendor) or (AccountType = GenJournalLine."Account Type"::Employee) then
            Amount := -Amount;

        LibraryERM.SelectGenJnlBatch(GenJournalBatch);

        // create and post invoice
        if AccountType = GenJournalLine."Account Type"::Employee then
            DocumentNo := CreateJournalLine(
               GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::" ",
               AccountType, AccountNo, Amount, PostingDate[1], CurrencyCode)
        else
            DocumentNo := CreateJournalLine(
                GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Invoice,
                AccountType, AccountNo, Amount, PostingDate[1], CurrencyCode);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // create and post payment with first currency exchange rate
        CreateJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Payment,
          AccountType, AccountNo, -Amount / 2, PostingDate[1], CurrencyCode);
        if AccountType <> GenJournalLine."Account Type"::Employee then
            GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", DocumentNo);
        GenJournalLine.Modify();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // create and post payment with second currency exchange rate
        CreateJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Payment,
          AccountType, AccountNo, -GenJournalLine.Amount - Amount, CalcDate('<+1D>', PostingDate[2]), CurrencyCode);
        if AccountType <> GenJournalLine."Account Type"::Employee then
            GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", DocumentNo);
        GenJournalLine.Modify();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(DocumentNo);
    end;

    local procedure CreateJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal; PostingDate: Date; CurrencyCode: Code[10]): Code[20]
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine,
          GenJournalBatch."Journal Template Name",
          GenJournalBatch.Name,
          DocumentType,
          AccountType,
          AccountNo,
          Amount);

        // Update journal line currency
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Validate(Description, GenJournalLine."Document No.");
        GenJournalLine.Validate("External Document No.", GenJournalLine."Document No.");
        GenJournalLine.Modify(true);

        exit(GenJournalLine."Document No.");
    end;

    local procedure GenerateDocumentNo(PostingDate: Date): Code[20]
    var
        PlaceholderTok: Label 'ADJSK%1%2', Locked = true;
    begin
        exit(StrSubstNo(PlaceholderTok, Date2DMY(PostingDate, 3), Date2DMY(PostingDate, 2)));
    end;

    local procedure RunAdjustExchangeRates(CurrencyCode: Code[10]; StartDate: Date; EndDate: Date; DocumentNo: Code[20]; AdjCust: Boolean; AdjVend: Boolean; AdjBank: Boolean; AdjEmpl: Boolean; Post: Boolean)
    var
        Currency: Record Currency;
        XmlParameters: Text;
    begin
        LibraryVariableStorage.Enqueue(StartDate);
        LibraryVariableStorage.Enqueue(EndDate);
        LibraryVariableStorage.Enqueue(DocumentNo);
        LibraryVariableStorage.Enqueue(AdjCust);
        LibraryVariableStorage.Enqueue(AdjVend);
        LibraryVariableStorage.Enqueue(AdjEmpl);
        LibraryVariableStorage.Enqueue(AdjBank);
        LibraryVariableStorage.Enqueue(Post);

        Currency.SetRange(Code, CurrencyCode);
        XmlParameters := Report.RunRequestPage(Report::"Adjust Exchange Rates CZL");
        LibraryReportDataset.RunReportAndLoad(Report::"Adjust Exchange Rates CZL", Currency, XmlParameters);
    end;

    [RequestPageHandler]
    procedure RequestPageAdjustExchangeRatesHandler(var AdjustExchangeRatesCZL: TestRequestPage "Adjust Exchange Rates CZL")
    var
        FieldVariant: Variant;
    begin
        LibraryVariableStorage.Dequeue(FieldVariant);
        AdjustExchangeRatesCZL.StartingDate.SetValue(FieldVariant);
        LibraryVariableStorage.Dequeue(FieldVariant);
        AdjustExchangeRatesCZL.EndingDate.SetValue(FieldVariant);
        LibraryVariableStorage.Dequeue(FieldVariant);
        AdjustExchangeRatesCZL.DocumentNo.SetValue(FieldVariant);
        LibraryVariableStorage.Dequeue(FieldVariant);
        AdjustExchangeRatesCZL.AdjCustField.SetValue(FieldVariant);
        LibraryVariableStorage.Dequeue(FieldVariant);
        AdjustExchangeRatesCZL.AdjVendField.SetValue(FieldVariant);
        LibraryVariableStorage.Dequeue(FieldVariant);
        AdjustExchangeRatesCZL.AdjEmplAcc.SetValue(FieldVariant);
        LibraryVariableStorage.Dequeue(FieldVariant);
        AdjustExchangeRatesCZL.AdjBankField.SetValue(FieldVariant);
        LibraryVariableStorage.Dequeue(FieldVariant);
        AdjustExchangeRatesCZL.PostField.SetValue(FieldVariant);
        AdjustExchangeRatesCZL.OK().Invoke();
    end;

    [MessageHandler]
    procedure StatisticsMessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(ExchRateWasAdjustedTxt, Message);
    end;
}

