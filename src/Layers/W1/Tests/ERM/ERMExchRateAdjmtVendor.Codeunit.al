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
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
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

    [Test]
    procedure VendorsDiffPostingGroupsGetSeparateRegisters()
    var
        Vendor1: Record Vendor;
        Vendor2: Record Vendor;
        VendorPostingGroup1: Record "Vendor Posting Group";
        VendorPostingGroup2: Record "Vendor Posting Group";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        ExchRateAdjmtReg: Record "Exch. Rate Adjmt. Reg.";
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO 626336] Two vendors with different posting groups get separate registers with non-zero amounts
        Initialize();

        // [GIVEN] Currency "C" with exchange rate
        CurrencyCode := CreateCurrency();

        // [GIVEN] Vendor "V1" with Vendor Posting Group "VPG1" and currency "C"
        CreateVendorWithNewPostingGroup(Vendor1, VendorPostingGroup1, CurrencyCode);

        // [GIVEN] Vendor "V2" with Vendor Posting Group "VPG2" and currency "C"
        CreateVendorWithNewPostingGroup(Vendor2, VendorPostingGroup2, CurrencyCode);

        // [GIVEN] Posted purchase invoices for "V1" and "V2"
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        CreateVendorInvoiceJnlLine(GenJournalLine, GenJournalBatch, Vendor1."No.", -LibraryRandom.RandIntInRange(500, 1000));
        CreateVendorInvoiceJnlLine(GenJournalLine, GenJournalBatch, Vendor2."No.", -LibraryRandom.RandIntInRange(500, 1000));
        GenJournalLine.Validate("Document No.", LibraryUtility.GenerateGUID());
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Exchange rate is changed
        ModifyExchRateForCurrency(CurrencyCode, LibraryRandom.RandInt(50));

        // [WHEN] Run Adjust Exchange Rates
        LibraryERM.RunExchRateAdjustmentForDocNo(CurrencyCode, LibraryUtility.GenerateGUID());

        // [THEN] Two register entries exist for Vendor with different posting groups
        ExchRateAdjmtReg.SetRange("Account Type", ExchRateAdjmtReg."Account Type"::Vendor);
        ExchRateAdjmtReg.SetRange("Currency Code", CurrencyCode);
        Assert.AreEqual(2, ExchRateAdjmtReg.Count(), 'Expected 2 vendor registers for 2 posting groups.');

        // [THEN] Both registers have non-zero adjusted amounts
        ExchRateAdjmtReg.SetRange("Posting Group", VendorPostingGroup1.Code);
        ExchRateAdjmtReg.FindFirst();
        Assert.AreNotEqual(0, ExchRateAdjmtReg."Adjusted Amt. (LCY)", 'Register for VPG1 must have non-zero amount.');

        // [THEN] Register for VPG2 has non-zero adjusted amount
        ExchRateAdjmtReg.SetRange("Posting Group", VendorPostingGroup2.Code);
        ExchRateAdjmtReg.FindFirst();
        Assert.AreNotEqual(0, ExchRateAdjmtReg."Adjusted Amt. (LCY)", 'Register for VPG2 must have non-zero amount.');
    end;

    [Test]
    procedure VendorRegisterAmtMatchesLinkedLedgerEntries()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ExchRateAdjmtReg: Record "Exch. Rate Adjmt. Reg.";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO 626336] Vendor register "Adjusted Amt. (LCY)" equals sum of linked ledger entry amounts
        Initialize();

        // [GIVEN] Vendor "V" with posted invoice and changed exchange rate
        CreateGeneralJnlLine(GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        ModifyExchRateForCurrency(GenJournalLine."Currency Code", LibraryRandom.RandInt(50));

        // [WHEN] Run Adjust Exchange Rates
        LibraryERM.RunExchRateAdjustmentForDocNo(GenJournalLine."Currency Code", GenJournalLine."Document No.");

        // [THEN] Register "Adjusted Amt. (LCY)" equals CalcSums of linked ledger entries "Adjustment Amount"
        ExchRateAdjmtReg.SetRange("Account Type", ExchRateAdjmtReg."Account Type"::Vendor);
        ExchRateAdjmtReg.SetRange("Currency Code", GenJournalLine."Currency Code");
        ExchRateAdjmtReg.FindFirst();
        VerifyRegisterAmtMatchesLedgerEntries(ExchRateAdjmtReg);
    end;

    [Test]
    procedure TwoVendorsSamePostingGroupSingleRegister()
    var
        Vendor1: Record Vendor;
        Vendor2: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        ExchRateAdjmtReg: Record "Exch. Rate Adjmt. Reg.";
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO 626336] Two vendors with the same posting group produce one register with combined amount
        Initialize();

        // [GIVEN] Currency "C" with exchange rate
        CurrencyCode := CreateCurrency();

        // [GIVEN] Vendor "V1" with currency "C"
        LibraryPurchase.CreateVendor(Vendor1);
        Vendor1.Validate("Currency Code", CurrencyCode);
        Vendor1.Modify();

        // [GIVEN] Vendor "V2" with the same posting group as "V1" and currency "C"
        LibraryPurchase.CreateVendor(Vendor2);
        Vendor2.Validate("Currency Code", CurrencyCode);
        Vendor2.Validate("Vendor Posting Group", Vendor1."Vendor Posting Group");
        Vendor2.Modify();

        // [GIVEN] Posted purchase invoices for "V1" and "V2"
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        CreateVendorInvoiceJnlLine(GenJournalLine, GenJournalBatch, Vendor1."No.", -LibraryRandom.RandIntInRange(500, 1000));
        CreateVendorInvoiceJnlLine(GenJournalLine, GenJournalBatch, Vendor2."No.", -LibraryRandom.RandIntInRange(500, 1000));
        GenJournalLine.Validate("Document No.", LibraryUtility.GenerateGUID());
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Exchange rate is changed
        ModifyExchRateForCurrency(CurrencyCode, LibraryRandom.RandInt(50));

        // [WHEN] Run Adjust Exchange Rates
        LibraryERM.RunExchRateAdjustmentForDocNo(CurrencyCode, LibraryUtility.GenerateGUID());

        // [THEN] One register entry exists since both vendors share the same posting group
        ExchRateAdjmtReg.SetRange("Account Type", ExchRateAdjmtReg."Account Type"::Vendor);
        ExchRateAdjmtReg.SetRange("Currency Code", CurrencyCode);
        Assert.AreEqual(1, ExchRateAdjmtReg.Count(), 'Expected 1 vendor register for same posting group.');

        // [THEN] Register amount matches linked ledger entries
        ExchRateAdjmtReg.FindFirst();
        VerifyRegisterAmtMatchesLedgerEntries(ExchRateAdjmtReg);
    end;

    [Test]
    procedure CustomerAndVendorInSameRunGetSeparateRegisters()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        VendorPostingGroup: Record "Vendor Posting Group";
        CustomerPostingGroup: Record "Customer Posting Group";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        ExchRateAdjmtReg: Record "Exch. Rate Adjmt. Reg.";
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO 626336] One customer and one vendor in the same run get separate registers with correct Account Type
        Initialize();

        // [GIVEN] Currency "C" with exchange rate
        CurrencyCode := CreateCurrency();

        // [GIVEN] Vendor "V" with Vendor Posting Group and currency "C"
        CreateVendorWithNewPostingGroup(Vendor, VendorPostingGroup, CurrencyCode);

        // [GIVEN] Customer "C1" with Customer Posting Group and currency "C"
        CreateCustomerWithNewPostingGroup(Customer, CustomerPostingGroup, CurrencyCode);

        // [GIVEN] Posted purchase invoice for "V" and sales invoice for "C1"
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        CreateVendorInvoiceJnlLine(GenJournalLine, GenJournalBatch, Vendor."No.", -LibraryRandom.RandIntInRange(500, 1000));
        CreateCustomerInvoiceJnlLine(GenJournalLine, GenJournalBatch, Customer."No.", LibraryRandom.RandIntInRange(500, 1000));
        GenJournalLine.Validate("Document No.", LibraryUtility.GenerateGUID());
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Exchange rate is changed
        ModifyExchRateForCurrency(CurrencyCode, LibraryRandom.RandInt(50));

        // [WHEN] Run Adjust Exchange Rates
        LibraryERM.RunExchRateAdjustmentForDocNo(CurrencyCode, LibraryUtility.GenerateGUID());

        // [THEN] One vendor register exists with non-zero amount
        ExchRateAdjmtReg.SetRange("Currency Code", CurrencyCode);
        ExchRateAdjmtReg.SetRange("Account Type", ExchRateAdjmtReg."Account Type"::Vendor);
        Assert.AreEqual(1, ExchRateAdjmtReg.Count(), 'Expected 1 vendor register.');
        ExchRateAdjmtReg.FindFirst();
        Assert.AreNotEqual(0, ExchRateAdjmtReg."Adjusted Amt. (LCY)", 'Vendor register must have non-zero amount.');

        // [THEN] One customer register exists with non-zero amount
        ExchRateAdjmtReg.SetRange("Account Type", ExchRateAdjmtReg."Account Type"::Customer);
        Assert.AreEqual(1, ExchRateAdjmtReg.Count(), 'Expected 1 customer register.');
        ExchRateAdjmtReg.FindFirst();
        Assert.AreNotEqual(0, ExchRateAdjmtReg."Adjusted Amt. (LCY)", 'Customer register must have non-zero amount.');
    end;

    [Test]
    procedure ThreeVendorsThreePostingGroupsThreeRegisters()
    var
        Vendor1: Record Vendor;
        Vendor2: Record Vendor;
        Vendor3: Record Vendor;
        VendorPostingGroup1: Record "Vendor Posting Group";
        VendorPostingGroup2: Record "Vendor Posting Group";
        VendorPostingGroup3: Record "Vendor Posting Group";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        ExchRateAdjmtReg: Record "Exch. Rate Adjmt. Reg.";
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO 626336] Three vendors each with a distinct posting group produce exactly 3 registers
        Initialize();

        // [GIVEN] Currency "C" with exchange rate
        CurrencyCode := CreateCurrency();

        // [GIVEN] Three vendors with different posting groups
        CreateVendorWithNewPostingGroup(Vendor1, VendorPostingGroup1, CurrencyCode);
        CreateVendorWithNewPostingGroup(Vendor2, VendorPostingGroup2, CurrencyCode);
        CreateVendorWithNewPostingGroup(Vendor3, VendorPostingGroup3, CurrencyCode);

        // [GIVEN] Posted purchase invoices for all three vendors
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        CreateVendorInvoiceJnlLine(GenJournalLine, GenJournalBatch, Vendor1."No.", -LibraryRandom.RandIntInRange(500, 1000));
        CreateVendorInvoiceJnlLine(GenJournalLine, GenJournalBatch, Vendor2."No.", -LibraryRandom.RandIntInRange(500, 1000));
        GenJournalLine.Validate("Document No.", LibraryUtility.GenerateGUID());
        GenJournalLine.Modify(true);
        CreateVendorInvoiceJnlLine(GenJournalLine, GenJournalBatch, Vendor3."No.", -LibraryRandom.RandIntInRange(500, 1000));
        GenJournalLine.Validate("Document No.", LibraryUtility.GenerateGUID());
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Exchange rate is changed
        ModifyExchRateForCurrency(CurrencyCode, LibraryRandom.RandInt(50));

        // [WHEN] Run Adjust Exchange Rates
        LibraryERM.RunExchRateAdjustmentForDocNo(CurrencyCode, LibraryUtility.GenerateGUID());

        // [THEN] Three registers exist for Vendor
        ExchRateAdjmtReg.SetRange("Account Type", ExchRateAdjmtReg."Account Type"::Vendor);
        ExchRateAdjmtReg.SetRange("Currency Code", CurrencyCode);
        Assert.AreEqual(3, ExchRateAdjmtReg.Count(), 'Expected 3 vendor registers for 3 posting groups.');

        // [THEN] All three registers have non-zero amounts
        ExchRateAdjmtReg.FindSet();
        repeat
            Assert.AreNotEqual(0, ExchRateAdjmtReg."Adjusted Amt. (LCY)",
                StrSubstNo('Register for posting group %1 must have non-zero amount.', ExchRateAdjmtReg."Posting Group"));
            VerifyRegisterAmtMatchesLedgerEntries(ExchRateAdjmtReg);
        until ExchRateAdjmtReg.Next() = 0;
    end;

    [Test]
    procedure TwoCurrenciesTwoPostingGroupsCreateFourVendorRegisters()
    var
        Vendor1: Record Vendor;
        Vendor2: Record Vendor;
        Vendor3: Record Vendor;
        Vendor4: Record Vendor;
        VendorPostingGroup1: Record "Vendor Posting Group";
        VendorPostingGroup2: Record "Vendor Posting Group";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        ExchRateAdjmtReg: Record "Exch. Rate Adjmt. Reg.";
        CurrencyCode1: Code[10];
        CurrencyCode2: Code[10];
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO 626336] Two currencies x two vendor posting groups produce four registers
        Initialize();

        // [GIVEN] Two currencies with exchange rates
        CurrencyCode1 := CreateCurrency();
        CurrencyCode2 := CreateCurrency();

        // [GIVEN] Two vendor posting groups
        LibraryPurchase.CreateVendorPostingGroup(VendorPostingGroup1);
        VendorPostingGroup1.Validate("Payables Account", LibraryERM.CreateGLAccountNo());
        VendorPostingGroup1.Modify(true);
        LibraryPurchase.CreateVendorPostingGroup(VendorPostingGroup2);
        VendorPostingGroup2.Validate("Payables Account", LibraryERM.CreateGLAccountNo());
        VendorPostingGroup2.Modify(true);

        // [GIVEN] Four vendors: VPG1+Ccy1, VPG1+Ccy2, VPG2+Ccy1, VPG2+Ccy2
        CreateVendorWithPostingGroupAndCurrency(Vendor1, VendorPostingGroup1.Code, CurrencyCode1);
        CreateVendorWithPostingGroupAndCurrency(Vendor2, VendorPostingGroup1.Code, CurrencyCode2);
        CreateVendorWithPostingGroupAndCurrency(Vendor3, VendorPostingGroup2.Code, CurrencyCode1);
        CreateVendorWithPostingGroupAndCurrency(Vendor4, VendorPostingGroup2.Code, CurrencyCode2);

        // [GIVEN] Posted purchase invoices for all four vendors
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        CreateVendorInvoiceJnlLine(GenJournalLine, GenJournalBatch, Vendor1."No.", -LibraryRandom.RandIntInRange(500, 1000));
        CreateVendorInvoiceJnlLine(GenJournalLine, GenJournalBatch, Vendor2."No.", -LibraryRandom.RandIntInRange(500, 1000));
        GenJournalLine.Validate("Document No.", LibraryUtility.GenerateGUID());
        GenJournalLine.Modify(true);
        CreateVendorInvoiceJnlLine(GenJournalLine, GenJournalBatch, Vendor3."No.", -LibraryRandom.RandIntInRange(500, 1000));
        GenJournalLine.Validate("Document No.", LibraryUtility.GenerateGUID());
        GenJournalLine.Modify(true);
        CreateVendorInvoiceJnlLine(GenJournalLine, GenJournalBatch, Vendor4."No.", -LibraryRandom.RandIntInRange(500, 1000));
        GenJournalLine.Validate("Document No.", LibraryUtility.GenerateGUID());
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Exchange rates are changed for both currencies
        ModifyExchRateForCurrency(CurrencyCode1, LibraryRandom.RandInt(50));
        ModifyExchRateForCurrency(CurrencyCode2, LibraryRandom.RandInt(50));

        // [WHEN] Run Adjust Exchange Rates for currency 1
        LibraryERM.RunExchRateAdjustmentForDocNo(CurrencyCode1, LibraryUtility.GenerateGUID());
        // [WHEN] Run Adjust Exchange Rates for currency 2
        LibraryERM.RunExchRateAdjustmentForDocNo(CurrencyCode2, LibraryUtility.GenerateGUID());

        // [THEN] Two vendor registers exist for currency 1
        ExchRateAdjmtReg.SetRange("Account Type", ExchRateAdjmtReg."Account Type"::Vendor);
        ExchRateAdjmtReg.SetRange("Currency Code", CurrencyCode1);
        Assert.AreEqual(2, ExchRateAdjmtReg.Count(), 'Expected 2 vendor registers for currency 1.');

        // [THEN] Two vendor registers exist for currency 2
        ExchRateAdjmtReg.SetRange("Currency Code", CurrencyCode2);
        Assert.AreEqual(2, ExchRateAdjmtReg.Count(), 'Expected 2 vendor registers for currency 2.');

        // [THEN] All four registers have non-zero amounts and match ledger entries
        ExchRateAdjmtReg.SetRange("Currency Code");
        ExchRateAdjmtReg.SetFilter("Currency Code", '%1|%2', CurrencyCode1, CurrencyCode2);
        Assert.AreEqual(4, ExchRateAdjmtReg.Count(), 'Expected 4 total vendor registers.');
        ExchRateAdjmtReg.FindSet();
        repeat
            Assert.AreNotEqual(0, ExchRateAdjmtReg."Adjusted Amt. (LCY)",
                StrSubstNo('Register for %1/%2 must have non-zero amount.', ExchRateAdjmtReg."Currency Code", ExchRateAdjmtReg."Posting Group"));
            VerifyRegisterAmtMatchesLedgerEntries(ExchRateAdjmtReg);
        until ExchRateAdjmtReg.Next() = 0;
    end;

    [Test]
    procedure GainToLossReversalMultiVendorPostingGroupsCorrectRegisters()
    var
        Vendor1: Record Vendor;
        Vendor2: Record Vendor;
        VendorPostingGroup1: Record "Vendor Posting Group";
        VendorPostingGroup2: Record "Vendor Posting Group";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        ExchRateAdjmtReg: Record "Exch. Rate Adjmt. Reg.";
        CurrencyCode: Code[10];
        ExchRateAmt: Decimal;
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO 626336] Gain-to-loss reversal with two vendor posting groups produces correct registers in both runs
        Initialize();

        // [GIVEN] Currency "C" with exchange rate
        CurrencyCode := CreateCurrency();
        ExchRateAmt := LibraryRandom.RandIntInRange(5, 20);

        // [GIVEN] Two vendors with different posting groups
        CreateVendorWithNewPostingGroup(Vendor1, VendorPostingGroup1, CurrencyCode);
        CreateVendorWithNewPostingGroup(Vendor2, VendorPostingGroup2, CurrencyCode);

        // [GIVEN] Posted purchase invoices for both vendors
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        CreateVendorInvoiceJnlLine(GenJournalLine, GenJournalBatch, Vendor1."No.", -LibraryRandom.RandIntInRange(500, 1000));
        CreateVendorInvoiceJnlLine(GenJournalLine, GenJournalBatch, Vendor2."No.", -LibraryRandom.RandIntInRange(500, 1000));
        GenJournalLine.Validate("Document No.", LibraryUtility.GenerateGUID());
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Exchange rate is changed (gain direction) and first adjustment run
        ModifyExchRateForCurrency(CurrencyCode, ExchRateAmt);
        LibraryERM.RunExchRateAdjustmentForDocNo(CurrencyCode, LibraryUtility.GenerateGUID());

        // [THEN] Two registers from the first run, both non-zero
        ExchRateAdjmtReg.SetRange("Account Type", ExchRateAdjmtReg."Account Type"::Vendor);
        ExchRateAdjmtReg.SetRange("Currency Code", CurrencyCode);
        Assert.AreEqual(2, ExchRateAdjmtReg.Count(), 'Expected 2 vendor registers after first adjustment.');
        ExchRateAdjmtReg.FindSet();
        repeat
            Assert.AreNotEqual(0, ExchRateAdjmtReg."Adjusted Amt. (LCY)", 'First-run register must have non-zero amount.');
            VerifyRegisterAmtMatchesLedgerEntries(ExchRateAdjmtReg);
        until ExchRateAdjmtReg.Next() = 0;

        // [GIVEN] Exchange rate is reversed (loss direction)
        ModifyExchRateForCurrency(CurrencyCode, -2 * ExchRateAmt);

        // [WHEN] Run Adjust Exchange Rates second time
        LibraryERM.RunExchRateAdjustmentForDocNo(CurrencyCode, LibraryUtility.GenerateGUID());

        // [THEN] Four total registers (2 per run), all with non-zero amounts
        ExchRateAdjmtReg.Reset();
        ExchRateAdjmtReg.SetRange("Account Type", ExchRateAdjmtReg."Account Type"::Vendor);
        ExchRateAdjmtReg.SetRange("Currency Code", CurrencyCode);
        Assert.AreEqual(4, ExchRateAdjmtReg.Count(), 'Expected 4 vendor registers after two adjustments.');
        ExchRateAdjmtReg.FindSet();
        repeat
            Assert.AreNotEqual(0, ExchRateAdjmtReg."Adjusted Amt. (LCY)", 'Register must have non-zero amount.');
            VerifyRegisterAmtMatchesLedgerEntries(ExchRateAdjmtReg);
        until ExchRateAdjmtReg.Next() = 0;
    end;

    [Test]
    procedure RunAdjustmentTwiceMultiPostingGroupsAllRegistersCorrect()
    var
        Vendor1: Record Vendor;
        Vendor2: Record Vendor;
        VendorPostingGroup1: Record "Vendor Posting Group";
        VendorPostingGroup2: Record "Vendor Posting Group";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        ExchRateAdjmtReg: Record "Exch. Rate Adjmt. Reg.";
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO 626336] Running adjustment twice with two vendor posting groups produces 4 correct registers
        Initialize();

        // [GIVEN] Currency "C" with exchange rate
        CurrencyCode := CreateCurrency();

        // [GIVEN] Two vendors with different posting groups
        CreateVendorWithNewPostingGroup(Vendor1, VendorPostingGroup1, CurrencyCode);
        CreateVendorWithNewPostingGroup(Vendor2, VendorPostingGroup2, CurrencyCode);

        // [GIVEN] Posted purchase invoices for both vendors
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        CreateVendorInvoiceJnlLine(GenJournalLine, GenJournalBatch, Vendor1."No.", -LibraryRandom.RandIntInRange(500, 1000));
        CreateVendorInvoiceJnlLine(GenJournalLine, GenJournalBatch, Vendor2."No.", -LibraryRandom.RandIntInRange(500, 1000));
        GenJournalLine.Validate("Document No.", LibraryUtility.GenerateGUID());
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] First exchange rate change and adjustment
        ModifyExchRateForCurrency(CurrencyCode, LibraryRandom.RandInt(50));
        LibraryERM.RunExchRateAdjustmentForDocNo(CurrencyCode, LibraryUtility.GenerateGUID());

        // [GIVEN] Second exchange rate change
        ModifyExchRateForCurrency(CurrencyCode, LibraryRandom.RandInt(50));

        // [WHEN] Run Adjust Exchange Rates second time
        LibraryERM.RunExchRateAdjustmentForDocNo(CurrencyCode, LibraryUtility.GenerateGUID());

        // [THEN] Four total registers (2 per run)
        ExchRateAdjmtReg.SetRange("Account Type", ExchRateAdjmtReg."Account Type"::Vendor);
        ExchRateAdjmtReg.SetRange("Currency Code", CurrencyCode);
        Assert.AreEqual(4, ExchRateAdjmtReg.Count(), 'Expected 4 vendor registers after two adjustments.');

        // [THEN] All registers have non-zero amounts and match ledger entries
        ExchRateAdjmtReg.FindSet();
        repeat
            Assert.AreNotEqual(0, ExchRateAdjmtReg."Adjusted Amt. (LCY)", 'Register must have non-zero amount.');
            VerifyRegisterAmtMatchesLedgerEntries(ExchRateAdjmtReg);
        until ExchRateAdjmtReg.Next() = 0;
    end;

    [Test]
    procedure BankAndVendorInSameRunGetCorrectSeparateRegisters()
    var
        Vendor: Record Vendor;
        BankAccount: Record "Bank Account";
        VendorPostingGroup: Record "Vendor Posting Group";
        BankAccountPostingGroup: Record "Bank Account Posting Group";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        ExchRateAdjmtReg: Record "Exch. Rate Adjmt. Reg.";
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO 626336] One bank account and one vendor in the same run get separate registers with no cross-contamination
        Initialize();

        // [GIVEN] Currency "C" with exchange rate
        CurrencyCode := CreateCurrency();

        // [GIVEN] Vendor "V" with Vendor Posting Group and currency "C"
        CreateVendorWithNewPostingGroup(Vendor, VendorPostingGroup, CurrencyCode);

        // [GIVEN] Bank Account "BA" with Bank Posting Group and currency "C"
        CreateBankAccountWithNewPostingGroup(BankAccount, BankAccountPostingGroup, CurrencyCode);

        // [GIVEN] Posted journal entries for vendor and bank
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        CreateVendorInvoiceJnlLine(GenJournalLine, GenJournalBatch, Vendor."No.", -LibraryRandom.RandIntInRange(500, 1000));
        CreateBankAccountJnlLine(GenJournalLine, GenJournalBatch, BankAccount."No.", LibraryRandom.RandIntInRange(500, 1000));
        GenJournalLine.Validate("Document No.", LibraryUtility.GenerateGUID());
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Exchange rate is changed
        ModifyExchRateForCurrency(CurrencyCode, LibraryRandom.RandInt(50));

        // [WHEN] Run Adjust Exchange Rates
        LibraryERM.RunExchRateAdjustmentForDocNo(CurrencyCode, LibraryUtility.GenerateGUID());

        // [THEN] One vendor register with non-zero amount
        ExchRateAdjmtReg.SetRange("Currency Code", CurrencyCode);
        ExchRateAdjmtReg.SetRange("Account Type", ExchRateAdjmtReg."Account Type"::Vendor);
        Assert.AreEqual(1, ExchRateAdjmtReg.Count(), 'Expected 1 vendor register.');
        ExchRateAdjmtReg.FindFirst();
        Assert.AreNotEqual(0, ExchRateAdjmtReg."Adjusted Amt. (LCY)", 'Vendor register must have non-zero amount.');
        VerifyRegisterAmtMatchesLedgerEntries(ExchRateAdjmtReg);

        // [THEN] One bank register with non-zero amount
        ExchRateAdjmtReg.SetRange("Account Type", ExchRateAdjmtReg."Account Type"::"Bank Account");
        Assert.AreEqual(1, ExchRateAdjmtReg.Count(), 'Expected 1 bank register.');
        ExchRateAdjmtReg.FindFirst();
        Assert.AreNotEqual(0, ExchRateAdjmtReg."Adjusted Amt. (LCY)", 'Bank register must have non-zero amount.');
        VerifyRegisterAmtMatchesLedgerEntries(ExchRateAdjmtReg);
    end;

    [Test]
    procedure BankAndCustomerAndVendorAllInSameRun()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        BankAccount: Record "Bank Account";
        VendorPostingGroup: Record "Vendor Posting Group";
        CustomerPostingGroup: Record "Customer Posting Group";
        BankAccountPostingGroup: Record "Bank Account Posting Group";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        ExchRateAdjmtReg: Record "Exch. Rate Adjmt. Reg.";
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO 626336] Bank, customer, and vendor all in one run produce 3 correct registers with no leakage
        Initialize();

        // [GIVEN] Currency "C" with exchange rate
        CurrencyCode := CreateCurrency();

        // [GIVEN] Vendor, customer, and bank account each with their own posting group
        CreateVendorWithNewPostingGroup(Vendor, VendorPostingGroup, CurrencyCode);
        CreateCustomerWithNewPostingGroup(Customer, CustomerPostingGroup, CurrencyCode);
        CreateBankAccountWithNewPostingGroup(BankAccount, BankAccountPostingGroup, CurrencyCode);

        // [GIVEN] Posted journal entries for all three
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        CreateVendorInvoiceJnlLine(GenJournalLine, GenJournalBatch, Vendor."No.", -LibraryRandom.RandIntInRange(500, 1000));
        CreateCustomerInvoiceJnlLine(GenJournalLine, GenJournalBatch, Customer."No.", LibraryRandom.RandIntInRange(500, 1000));
        GenJournalLine.Validate("Document No.", LibraryUtility.GenerateGUID());
        GenJournalLine.Modify(true);
        CreateBankAccountJnlLine(GenJournalLine, GenJournalBatch, BankAccount."No.", LibraryRandom.RandIntInRange(500, 1000));
        GenJournalLine.Validate("Document No.", LibraryUtility.GenerateGUID());
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Exchange rate is changed
        ModifyExchRateForCurrency(CurrencyCode, LibraryRandom.RandInt(50));

        // [WHEN] Run Adjust Exchange Rates
        LibraryERM.RunExchRateAdjustmentForDocNo(CurrencyCode, LibraryUtility.GenerateGUID());

        // [THEN] One vendor register with non-zero amount
        ExchRateAdjmtReg.SetRange("Currency Code", CurrencyCode);
        ExchRateAdjmtReg.SetRange("Account Type", ExchRateAdjmtReg."Account Type"::Vendor);
        Assert.AreEqual(1, ExchRateAdjmtReg.Count(), 'Expected 1 vendor register.');
        ExchRateAdjmtReg.FindFirst();
        Assert.AreNotEqual(0, ExchRateAdjmtReg."Adjusted Amt. (LCY)", 'Vendor register must have non-zero amount.');
        VerifyRegisterAmtMatchesLedgerEntries(ExchRateAdjmtReg);

        // [THEN] One customer register with non-zero amount
        ExchRateAdjmtReg.SetRange("Account Type", ExchRateAdjmtReg."Account Type"::Customer);
        Assert.AreEqual(1, ExchRateAdjmtReg.Count(), 'Expected 1 customer register.');
        ExchRateAdjmtReg.FindFirst();
        Assert.AreNotEqual(0, ExchRateAdjmtReg."Adjusted Amt. (LCY)", 'Customer register must have non-zero amount.');
        VerifyRegisterAmtMatchesLedgerEntries(ExchRateAdjmtReg);

        // [THEN] One bank register with non-zero amount
        ExchRateAdjmtReg.SetRange("Account Type", ExchRateAdjmtReg."Account Type"::"Bank Account");
        Assert.AreEqual(1, ExchRateAdjmtReg.Count(), 'Expected 1 bank register.');
        ExchRateAdjmtReg.FindFirst();
        Assert.AreNotEqual(0, ExchRateAdjmtReg."Adjusted Amt. (LCY)", 'Bank register must have non-zero amount.');
        VerifyRegisterAmtMatchesLedgerEntries(ExchRateAdjmtReg);
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

    local procedure ModifyExchRateForCurrency(CurrencyCode: Code[10]; ExchRateAmount: Decimal)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        UpdateExchangeRate(CurrencyExchangeRate, CurrencyCode, ExchRateAmount);
    end;

    local procedure CreateVendorWithNewPostingGroup(var Vendor: Record Vendor; var VendorPostingGroup: Record "Vendor Posting Group"; CurrencyCode: Code[10])
    begin
        LibraryPurchase.CreateVendorPostingGroup(VendorPostingGroup);
        VendorPostingGroup.Validate("Payables Account", LibraryERM.CreateGLAccountNo());
        VendorPostingGroup.Modify(true);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", CurrencyCode);
        Vendor.Validate("Vendor Posting Group", VendorPostingGroup.Code);
        Vendor.Modify(true);
    end;

    local procedure VerifyRegisterAmtMatchesLedgerEntries(ExchRateAdjmtReg: Record "Exch. Rate Adjmt. Reg.")
    var
        ExchRateAdjmtLedgEntry: Record "Exch. Rate Adjmt. Ledg. Entry";
    begin
        ExchRateAdjmtReg.CalcFields("Adjustment Amount");
        ExchRateAdjmtLedgEntry.SetRange("Register No.", ExchRateAdjmtReg."No.");
        Assert.AreNotEqual(0, ExchRateAdjmtReg."Adjustment Amount", 'Register adjustment amount must be non-zero.');
        Assert.AreEqual(
            ExchRateAdjmtReg."Adjusted Amt. (LCY)", ExchRateAdjmtReg."Adjustment Amount",
            'Register Adjusted Amt. (LCY) must equal sum of linked ledger entry Adjustment Amount.');
    end;

    local procedure CreateVendorWithPostingGroupAndCurrency(var Vendor: Record Vendor; PostingGroupCode: Code[20]; CurrencyCode: Code[10])
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", CurrencyCode);
        Vendor.Validate("Vendor Posting Group", PostingGroupCode);
        Vendor.Modify(true);
    end;

    local procedure CreateCustomerWithNewPostingGroup(var Customer: Record Customer; var CustomerPostingGroup: Record "Customer Posting Group"; CurrencyCode: Code[10])
    begin
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup);
        CustomerPostingGroup.Validate("Receivables Account", LibraryERM.CreateGLAccountNo());
        CustomerPostingGroup.Modify(true);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Validate("Customer Posting Group", CustomerPostingGroup.Code);
        Customer.Modify(true);
    end;

    local procedure CreateVendorInvoiceJnlLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; VendorNo: Code[20]; Amount: Decimal)
    begin
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor, VendorNo, Amount);
    end;

    local procedure CreateCustomerInvoiceJnlLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; CustomerNo: Code[20]; Amount: Decimal)
    begin
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, CustomerNo, Amount);
    end;

    local procedure CreateBankAccountJnlLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; BankAccountNo: Code[20]; Amount: Decimal)
    begin
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"Bank Account", BankAccountNo, Amount);
    end;

    local procedure CreateBankAccountWithNewPostingGroup(var BankAccount: Record "Bank Account"; var BankAccountPostingGroup: Record "Bank Account Posting Group"; CurrencyCode: Code[10])
    begin
        LibraryERM.CreateBankAccountPostingGroup(BankAccountPostingGroup);
        BankAccountPostingGroup.Validate("G/L Account No.", LibraryERM.CreateGLAccountNo());
        BankAccountPostingGroup.Modify(true);
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Currency Code", CurrencyCode);
        BankAccount.Validate("Bank Acc. Posting Group", BankAccountPostingGroup.Code);
        BankAccount.Modify(true);
    end;
}

