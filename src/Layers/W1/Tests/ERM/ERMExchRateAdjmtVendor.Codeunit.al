codeunit 134881 "ERM Exch. Rate Adjmt. Vendor"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Adjust Exchange Rate] [Detailed Ledger Entry] [Purchase]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        AmountMismatchErr: Label '%1 field must be %2 in %3 table for %4 field %5.';

    [Test]
    [Scope('OnPrem')]
    procedure AdjustExchRateWithHigherValue()
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        // Test Adjust Exchange Rate batch job after modifying Higher Exchange Rate and verify Unrealized Loss entry created
        // in Detailed Vendor Ledger Entry.
        Initialize();
        AdjustExchRateForVendor(LibraryRandom.RandInt(50), DetailedVendorLedgEntry."Entry Type"::"Unrealized Loss");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdjustExchRateWithLowerValue()
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        // Check that Adjust Exchange Rate batch job after Modify Higher Exchange Rate and verify Unrealized Gain entry created
        // in Detailed Vendor Ledger Entry.
        Initialize();
        AdjustExchRateForVendor(-LibraryRandom.RandInt(50), DetailedVendorLedgEntry."Entry Type"::"Unrealized Gain");
    end;

    local procedure AdjustExchRateForVendor(ExchRateAmount: Decimal; EntryType: Enum "Detailed CV Ledger Entry Type")
    var
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        Amount: Decimal;
    begin
        // Setup: Create and Post General Journal Line and Modify Exchange Rate.
        CreateGeneralJnlLine(GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        UpdateExchangeRate(CurrencyExchangeRate, GenJournalLine."Currency Code", ExchRateAmount);
        Amount :=
          GenJournalLine."Amount (LCY)" -
          (GenJournalLine.Amount * CurrencyExchangeRate."Relational Exch. Rate Amount" / CurrencyExchangeRate."Exchange Rate Amount");

        // Exercise: Run Adjust Exchange Rate Batch Job and calculate Realized Gain/Loss Amount.
        LibraryERM.RunExchRateAdjustmentForDocNo(GenJournalLine."Currency Code", GenJournalLine."Document No.");

        // Verify: Verify Detailed Ledger Entry for Unrealized Loss/Gain entry.
        VerifyDetailedVendorEntry(GenJournalLine."Document No.", GenJournalLine."Currency Code", -Amount, EntryType);
        VerifyExchRateAdjmtLedgEntry("Exch. Rate Adjmt. Account Type"::Vendor, GenJournalLine."Account No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdjustExchRateForVendorTwiceGainsLosses()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
        ExchRateAmt: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 253498] Run Adjust Exchange Rates report twice when currency is changed for vendor entries from gains to losses
        Initialize();

        // [GIVEN] Purchase Invoice with Amount = 39008 posted with exch.rate = 1,0887
        ExchRateAmt := LibraryRandom.RandDec(10, 2);
        CreateGeneralJnlLine(GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Exch. rates is changed to 1,0541 and adjustment completed.
        Amount :=
          UpdateExchRateAndCalcGainLossAmt(
            GenJournalLine.Amount, GenJournalLine."Amount (LCY)", GenJournalLine."Currency Code", 2 * ExchRateAmt);
        LibraryERM.RunExchRateAdjustmentForDocNo(GenJournalLine."Currency Code", GenJournalLine."Document No.");

        // [GIVEN] Dtld. Vend. Ledger Entry is created with amount = -1176,09 for Unrealized Loss type
        VerifyDtldVLELoss(GenJournalLine."Document No.", GenJournalLine."Currency Code", -Amount);

        // [GIVEN] Exch. rates is changed to 1,0666
        Amount :=
          UpdateExchRateAndCalcGainLossAmt(
            GenJournalLine.Amount, GenJournalLine."Amount (LCY)", GenJournalLine."Currency Code", -ExchRateAmt);

        // [WHEN] Run report Adjust Exchange Rates second time
        LibraryERM.RunExchRateAdjustmentForDocNo(GenJournalLine."Currency Code", GenJournalLine."Document No.");

        // [THEN] Dtld. Vendor Ledger Entry is created with amount = 433,69 for Unrealized Gain type
        VerifyDtldVLEGain(GenJournalLine."Document No.", GenJournalLine."Currency Code", Amount);
        VerifyExchRateAdjmtLedgEntry("Exch. Rate Adjmt. Account Type"::Vendor, GenJournalLine."Account No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdjustExchRateForVendorTwiceLossesGains()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
        ExchRateAmt: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 253498] Run Adjust Exchange Rates report twice when currency is changed for vendor entries from losses to gains
        Initialize();

        // [GIVEN] Purchase Invoice with Amount = 39008 posted with exch.rate = 1,0887
        ExchRateAmt := LibraryRandom.RandDec(10, 2);
        CreateGeneralJnlLine(GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Exch. rates is changed to 1,0541 and adjustment completed.
        Amount :=
          UpdateExchRateAndCalcGainLossAmt(
            GenJournalLine.Amount, GenJournalLine."Amount (LCY)", GenJournalLine."Currency Code", -2 * ExchRateAmt);
        LibraryERM.RunExchRateAdjustmentForDocNo(GenJournalLine."Currency Code", GenJournalLine."Document No.");

        // [GIVEN] Dtld. Vend. Ledger Entry is created with amount = 1176,09 for Unrealized Gain type
        VerifyDtldVLEGain(GenJournalLine."Document No.", GenJournalLine."Currency Code", -Amount);

        // [GIVEN] Exch. rates is changed to 1,0666
        Amount :=
          UpdateExchRateAndCalcGainLossAmt(
            GenJournalLine.Amount, GenJournalLine."Amount (LCY)", GenJournalLine."Currency Code", ExchRateAmt);

        // [WHEN] Run report Adjust Exchange Rates second time
        LibraryERM.RunExchRateAdjustmentForDocNo(GenJournalLine."Currency Code", GenJournalLine."Document No.");

        // [THEN] Dtld. Vendor Ledger Entry is created with amount = -742,4 for Unrealized Loss type
        VerifyDtldVLELoss(GenJournalLine."Document No.", GenJournalLine."Currency Code", Amount);
        VerifyExchRateAdjmtLedgEntry("Exch. Rate Adjmt. Account Type"::Vendor, GenJournalLine."Account No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdjustExchRateForVendorTwiceGainsToHigherLosses()
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Amount: Decimal;
        ExchRateAmt: Decimal;
        AdjDocNo: Code[20];
        LossesAmount: Decimal;
        k: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 365816] Run Adjust Exchange Rate report twice when exch.rate is changed lower and then upper than invoice's exch.rate
        Initialize();

        // [GIVEN] Purchase Invoice with Amount = 4000, Amount LCY = 4720 is posted with exch.rate = 1.18
        CreateGeneralJnlLine(GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        Currency.Get(GenJournalLine."Currency Code");
        FindCurrencyExchRate(CurrencyExchangeRate, Currency.Code);
        ExchRateAmt := CurrencyExchangeRate."Relational Exch. Rate Amount";
        k := 0.1;

        // [GIVEN] Exch. rates is changed to 1.16 (delta = -0.02) and adjustment completed.
        Amount :=
          UpdateExchRateAndCalcGainLossAmt(
            GenJournalLine.Amount, GenJournalLine."Amount (LCY)", GenJournalLine."Currency Code", -ExchRateAmt * k);
        LibraryERM.RunExchRateAdjustmentForDocNo(GenJournalLine."Currency Code", GenJournalLine."Document No.");

        // [GIVEN] Dtld. Vend. Ledger Entry is created with amount = 80 (4000 * 0.02) for Unrealized Gain type
        VerifyDtldVLEGain(
          GenJournalLine."Document No.", GenJournalLine."Currency Code", -Amount);

        // [GIVEN] Exch. rates is changed to 1.21 (delta = 0.05)
        Amount :=
          UpdateExchRateAndCalcGainLossAmt(
            GenJournalLine.Amount, GenJournalLine."Amount (LCY)", GenJournalLine."Currency Code", ExchRateAmt * 2 * k);

        AdjDocNo := LibraryUtility.GenerateGUID();
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, GenJournalLine."Document No.");
        VendorLedgerEntry.CalcFields("Amount (LCY)");
        LossesAmount := VendorLedgerEntry."Amount (LCY)";

        // [WHEN] Run report Adjust Exchange Rates second time
        LibraryERM.RunExchRateAdjustmentForDocNo(GenJournalLine."Currency Code", AdjDocNo);

        // [THEN] Dtld. Vend. Ledger Entry is created with amount = -200 (4000 * -0.05) for Unrealized Loss type
        VendorLedgerEntry.CalcFields("Amount (LCY)");
        LossesAmount := VendorLedgerEntry."Amount (LCY)" - LossesAmount;
        VerifyDtldVLELoss(AdjDocNo, GenJournalLine."Currency Code", LossesAmount);
        VerifyGLEntryForDocument(AdjDocNo, Currency."Unrealized Losses Acc.", -LossesAmount);
        VerifyExchRateAdjmtLedgEntry("Exch. Rate Adjmt. Account Type"::Vendor, GenJournalLine."Account No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdjustExchRateForVendorTwiceLossesToHigherGains()
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Amount: Decimal;
        ExchRateAmt: Decimal;
        AdjDocNo: Code[20];
        GainsAmount: Decimal;
        k: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 365816] Run Adjust Exchange Rate report twice when exch.rate is changed upper and then lower than invoice's exch.rate
        Initialize();

        // [GIVEN] Purchase Invoice with Amount = 4000, Amount LCY = 4720 is posted with exch.rate = 1.18
        CreateGeneralJnlLine(GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        Currency.Get(GenJournalLine."Currency Code");
        FindCurrencyExchRate(CurrencyExchangeRate, Currency.Code);
        ExchRateAmt := CurrencyExchangeRate."Relational Exch. Rate Amount";
        k := 0.1;

        // [GIVEN] Exch. rates is changed to 1.20 (delta = 0.02) and adjustment completed.
        Amount :=
          UpdateExchRateAndCalcGainLossAmt(
            GenJournalLine.Amount, GenJournalLine."Amount (LCY)", GenJournalLine."Currency Code", ExchRateAmt * k);
        LibraryERM.RunExchRateAdjustmentForDocNo(GenJournalLine."Currency Code", GenJournalLine."Document No.");

        // [GIVEN] Dtld. Vend. Ledger Entry is created with amount = -80 (4000 * 0.02) for Unrealized Loss type
        VerifyDtldVLELoss(
          GenJournalLine."Document No.", GenJournalLine."Currency Code", -Amount);

        // [GIVEN] Exch. rates is changed to 1.15 (delta = -0.05)
        Amount :=
          UpdateExchRateAndCalcGainLossAmt(
            GenJournalLine.Amount, GenJournalLine."Amount (LCY)", GenJournalLine."Currency Code", -ExchRateAmt * 2 * k);

        AdjDocNo := LibraryUtility.GenerateGUID();
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, GenJournalLine."Document No.");
        VendorLedgerEntry.CalcFields("Amount (LCY)");
        GainsAmount := VendorLedgerEntry."Amount (LCY)";

        // [WHEN] Run report Adjust Exchange Rates second time
        LibraryERM.RunExchRateAdjustmentForDocNo(GenJournalLine."Currency Code", AdjDocNo);

        // [THEN] Dtld. Vend. Ledger Entry is created with amount = 200 (4000 * 0.05) for Unrealized Gains type
        VendorLedgerEntry.CalcFields("Amount (LCY)");
        GainsAmount := VendorLedgerEntry."Amount (LCY)" - GainsAmount;
        VerifyDtldVLEGain(AdjDocNo, GenJournalLine."Currency Code", GainsAmount);
        VerifyGLEntryForDocument(AdjDocNo, Currency."Unrealized Gains Acc.", -GainsAmount);
        VerifyExchRateAdjmtLedgEntry("Exch. Rate Adjmt. Account Type"::Vendor, GenJournalLine."Account No.");
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"ERM Exch. Rate Adjmt. Vendor");
        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;

        LibraryTestInitialize.OnTestInitialize(Codeunit::"ERM Exch. Rate Adjmt. Vendor");

        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        isInitialized := true;
        Commit();

        LibrarySetupStorage.SaveGeneralLedgerSetup();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"ERM Exch. Rate Adjmt. Vendor");
    end;

    local procedure CreateGeneralJnlLine(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // Using Random value for Invoice Amount.
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor, CreateVendor(), -LibraryRandom.RandIntInRange(500, 1000));
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        Currency.Get(LibraryERM.CreateCurrencyWithGLAccountSetup());
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
        LibraryPurchase: Codeunit "Library - Purchase";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", CreateCurrency());
        Vendor.Modify();
        exit(Vendor."No.");
    end;

    local procedure FindGLEntry(var GLEntry: Record "G/L Entry"; DocumentNo: Code[20]; GLAccountNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    begin
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
    end;

    local procedure FindCurrencyExchRate(var CurrencyExchangeRate: Record "Currency Exchange Rate"; CurrencyCode: Code[10])
    begin
        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        CurrencyExchangeRate.FindFirst();
    end;

    local procedure UpdateExchangeRate(var CurrencyExchangeRate: Record "Currency Exchange Rate"; CurrencyCode: Code[10]; ExchRateAmount: Decimal)
    begin
        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        CurrencyExchangeRate.FindFirst();
        CurrencyExchangeRate.Validate(
          "Relational Exch. Rate Amount", CurrencyExchangeRate."Relational Exch. Rate Amount" + ExchRateAmount);
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", CurrencyExchangeRate."Relational Exch. Rate Amount");
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure VerifyDetailedVendorEntry(DocumentNo: Code[20]; CurrencyCode: Code[10]; Amount: Decimal; EntryType: Enum "Detailed CV Ledger Entry Type")
    var
        Currency: Record Currency;
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        Currency.Get(CurrencyCode);
        DetailedVendorLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedVendorLedgEntry.SetRange("Entry Type", EntryType);
        DetailedVendorLedgEntry.FindFirst();
        DetailedVendorLedgEntry.TestField("Ledger Entry Amount", true);
        DetailedVendorLedgEntry.CalcSums("Amount (LCY)");
        Assert.AreNearlyEqual(
            Amount, DetailedVendorLedgEntry."Amount (LCY)", Currency."Amount Rounding Precision",
            StrSubstNo(AmountMismatchErr,
                DetailedVendorLedgEntry.FieldCaption("Amount (LCY)"), Amount, DetailedVendorLedgEntry.TableCaption(),
                DetailedVendorLedgEntry.FieldCaption("Entry No."), DetailedVendorLedgEntry."Entry No."));
    end;

    local procedure VerifyExchRateAdjmtLedgEntry(AccountType: Enum "Exch. Rate Adjmt. Account Type"; AccountNo: Code[20])
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        ExchRateAdjmtLedgEntry: Record "Exch. Rate Adjmt. Ledg. Entry";
    begin
        ExchRateAdjmtLedgEntry.SetRange("Account Type", AccountType);
        ExchRateAdjmtLedgEntry.SetRange("Account No.", AccountNo);
        ExchRateAdjmtLedgEntry.FindSet();
        repeat
            DetailedVendorLedgEntry.Get(ExchRateAdjmtLedgEntry."Detailed Ledger Entry No.");
            Assert.AreEqual(
                DetailedVendorLedgEntry."Amount (LCY)", ExchRateAdjmtLedgEntry."Adjustment Amount",
                StrSubstNo(AmountMismatchErr,
                    DetailedVendorLedgEntry.FieldCaption("Amount (LCY)"), ExchRateAdjmtLedgEntry."Adjustment Amount",
                    ExchRateAdjmtLedgEntry.TableCaption(), ExchRateAdjmtLedgEntry.FieldCaption("Register No."),
                    ExchRateAdjmtLedgEntry."Entry No."));
        until ExchRateAdjmtLedgEntry.Next() = 0;
    end;

    local procedure VerifyDtldVLEGain(DocumentNo: Code[20]; CurrencyCode: Code[10]; Amount: Decimal)
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        VerifyDetailedVendorEntry(DocumentNo, CurrencyCode, Amount, DetailedVendorLedgEntry."Entry Type"::"Unrealized Gain");
    end;

    local procedure VerifyDtldVLELoss(DocumentNo: Code[20]; CurrencyCode: Code[10]; Amount: Decimal)
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        VerifyDetailedVendorEntry(DocumentNo, CurrencyCode, Amount, DetailedVendorLedgEntry."Entry Type"::"Unrealized Loss");
    end;

    local procedure VerifyGLEntryForDocument(DocumentNo: Code[20]; AccountNo: Code[20]; EntryAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        FindGLEntry(GLEntry, DocumentNo, AccountNo, GLEntry."Document Type"::" ");
        GLEntry.TestField(Amount, EntryAmount);
    end;

    local procedure UpdateExchRateAndCalcGainLossAmt(Amount: Decimal; AmountLCY: Decimal; CurrencyCode: Code[10]; ExchRateAmount: Decimal): Decimal
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        UpdateExchangeRate(CurrencyExchangeRate, CurrencyCode, ExchRateAmount);
        exit(
          AmountLCY -
          Amount * CurrencyExchangeRate."Relational Exch. Rate Amount" / CurrencyExchangeRate."Exchange Rate Amount");
    end;
}

