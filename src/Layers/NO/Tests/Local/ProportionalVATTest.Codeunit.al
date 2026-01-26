codeunit 144000 "Proportional VAT Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [VAT] [Prop. Deductible VAT]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryJournals: Codeunit "Library - Journals";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        IsInitialized: Boolean;
        DeferralAmountErr: Label 'Amount to defer';

    [Test]
    [Scope('OnPrem')]
    procedure PurchJournalWithACY()
    var
        GenPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        GenJnlLine: Record "Gen. Journal Line";
        CurrencyCode: Code[10];
    begin
        // Check that proportional VAT successfully posted through Purchase Journal with Additional Currency

        Initialize();
        CurrencyCode := SetupAdditionalCurrency();
        LibraryERM.FindGeneralPostingSetup(GenPostingSetup);
        CreateProportionalVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", GetTFS190253PropVATRate());
        CreatePostGenJnlLines(GenJnlLine, GenPostingSetup, VATPostingSetup, CurrencyCode, '', WorkDate());
        VerifyGLEntryWithNormalVAT(GenJnlLine, VATPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvWithACY()
    var
        GenPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        CurrencyCode: Code[10];
        DocNo: Code[20];
    begin
        // Check that proportional VAT successfully posted through Purchase Invoice with Additional Currency

        Initialize();
        CurrencyCode := SetupAdditionalCurrency();
        LibraryERM.FindGeneralPostingSetup(GenPostingSetup);

        CreateProportionalVATPostingSetup(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", GetTFS190253PropVATRate());
        CreatePurchDoc(PurchHeader, PurchLine, CurrencyCode, GenPostingSetup, VATPostingSetup);
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);
        VerifyGLEntryWithReverseChrgVAT(PurchHeader, PurchLine, VATPostingSetup, DocNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchInvPropVat()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        GLAcc: Record "G/L Account";
        DirectUnitCost: Decimal;
        Quantity: Decimal;
    begin
        Initialize();
        // Proportinal VAT has to be be greater than 0 and less than 100 otherwise the test is not testing the funcationality.
        CreateProportionalVATPostingSetup(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandInt(99));

        DirectUnitCost := LibraryRandom.RandDec(100, 2);
        Quantity := LibraryRandom.RandDec(10, 3);
        CreatePurchInvWithPropVat(
          PurchHeader, PurchHeader."Document Type"::Invoice, PurchLine, VATPostingSetup, DirectUnitCost, Quantity);
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // Validate
        GLAcc.Get(VATPostingSetup."Purchase VAT Account");
        GLAcc.CalcFields(Balance);
        Assert.AreNearlyEqual(
          PurchLine.Quantity *
          PurchLine."Direct Unit Cost" *
          VATPostingSetup."VAT %" / 100 *
          VATPostingSetup."Proportional Deduction VAT %" / 100,
          0.01,
          GLAcc.Balance, 'The propotional VAT is not posted');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchInvCredMemoPropVat()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        GLAcc: Record "G/L Account";
        DirectUnitCost: Decimal;
        Quantity: Decimal;
    begin
        Initialize();
        // Proportinal VAT has to be be greater than 0 and less than 100 otherwise the test is not testing the funcationality.
        CreateProportionalVATPostingSetup(
          VATPostingSetup,
          VATPostingSetup."VAT Calculation Type"::"Normal VAT",
          LibraryRandom.RandInt(99));

        DirectUnitCost := LibraryRandom.RandDec(100, 2);
        Quantity := LibraryRandom.RandDec(10, 3);
        CreatePurchInvWithPropVat(
          PurchHeader, PurchHeader."Document Type"::Invoice, PurchLine, VATPostingSetup, DirectUnitCost, Quantity);
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // Create and post credit memo purchase journal
        Clear(PurchHeader);
        Clear(PurchLine);
        CreatePurchInvWithPropVat(
          PurchHeader, PurchHeader."Document Type"::"Credit Memo",
          PurchLine, VATPostingSetup, DirectUnitCost, Quantity);
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // Validate
        GLAcc.Get(VATPostingSetup."Purchase VAT Account");
        GLAcc.CalcFields(Balance);
        Assert.AreEqual(0, GLAcc.Balance, 'The propotional VAT is not posted');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchInvWithDeferralAndPropVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        DeferralTemplate: Record "Deferral Template";
        PurchaseHeader: Record "Purchase Header";
        GLEntry: Record "G/L Entry";
        PurchaseLine: Record "Purchase Line";
        DocNo: Code[20];
        DeferredAmount: Decimal;
        ExpectedDeferralAmount: Decimal;
    begin
        // [FEATURE] [Deferral] [Purchases]
        // [SCENARIO 225690] Deferred G/L Entries must be contains correct amounts after posting Purchase Invoice with Deferrals and Proportional Deduction VAT.
        Initialize();

        // [GIVEN] VAT Posting Setup with "Calc. Proportional Deduction VAT" = TRUE, "Proportional Deduction VAT %" = 25 and "VAT %" = 20
        CreateProportionalVATPostingSetup(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandIntInRange(10, 30));

        // [GIVEN] "Deferral Tempalate" - "DefTempl" with "Period No." = 4 and "Calc. Method" = "Straight-Line"
        LibraryERM.CreateDeferralTemplate(
          DeferralTemplate, DeferralTemplate."Calc. Method"::"Straight-Line",
          DeferralTemplate."Start Date"::"Posting Date", LibraryRandom.RandIntInRange(2, 5) * 2);

        // [GIVEN] Purchase Invoice with Purchase Line
        // [GIVEN] Amount = 100, "Deferral Code" = "DefTempl", "VAT Posting Setup" with Prop. Deduction VAT
        DeferredAmount := CreatePurchInvWithDeferral(PurchaseHeader, VATPostingSetup, DeferralTemplate."Deferral Code");

        LibraryPurchase.FindFirstPurchLine(PurchaseLine, PurchaseHeader);
        ExpectedDeferralAmount :=
          PurchaseLine."VAT Base Amount" +
          Round(
            (PurchaseLine."Amount Including VAT" - PurchaseLine.Amount) * (100 - VATPostingSetup."Proportional Deduction VAT %") / 100);

        // [WHEN] Post purchase invoice with Amount = 120
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Total amount to defer = "VAT Base Amount" + "VAT Amount" excluding proportional VAT = 100 + 20 * (100 - 25%) / 100 = 115.
        // [THEN] Created 4 Deferral G/L Entries with summarized Amount = 115
        Assert.AreEqual(ExpectedDeferralAmount, DeferredAmount, DeferralAmountErr);

        VerifyGLEntryDeferrals(
          DeferralTemplate."Deferral Account", DocNo, ExpectedDeferralAmount,
          GLEntry."Document Type"::Invoice, DeferralTemplate."No. of Periods");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedGenJnlLineWithDeferralAndPropVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        DeferralTemplate: Record "Deferral Template";
        GeneralPostingSetup: Record "General Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        ExpectedDeferralAmount: Decimal;
    begin
        // [FEATURE] [Deferral] [General Journal]
        // [SCENARIO 312560] Deferred G/L Entries must be contains correct amounts after posting Gen. Journal Line with Deferrals and Proportional Deduction VAT.
        Initialize();

        // [GIVEN] VAT Posting Setup with "Calc. Proportional Deduction VAT" = TRUE, "Proportional Deduction VAT %" = 25 and "VAT %" = 20
        CreateProportionalVATPostingSetup(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandIntInRange(10, 30));

        // [GIVEN] "Deferral Tempalate" - "DefTempl" with "Period No." = 4 and "Calc. Method" = "Straight-Line"
        LibraryERM.CreateDeferralTemplate(
          DeferralTemplate, DeferralTemplate."Calc. Method"::"Straight-Line",
          DeferralTemplate."Start Date"::"Posting Date", LibraryRandom.RandIntInRange(2, 10));
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);

        // [WHEN] Post Gen. Journal Line with Amount = 120
        CreatePostGenJnlLines(
          GenJournalLine, GeneralPostingSetup, VATPostingSetup, '',
          DeferralTemplate."Deferral Code", CalcDate('<-CM>', WorkDate()));

        // [THEN] Total amount to defer = "VAT Base Amount" + "VAT Amount" excluding proportional VAT = 100 + 20 * (100 - 25%) / 100 = 115.
        // [THEN] Created 4 Deferral G/L Entries with summarized Amount = 115
        ExpectedDeferralAmount :=
          GenJournalLine."VAT Base Amount" +
          Round(
            GenJournalLine."VAT Amount" * (100 - VATPostingSetup."Proportional Deduction VAT %") / 100);

        Assert.AreEqual(ExpectedDeferralAmount, GenJournalLine.GetDeferralAmount(), DeferralAmountErr);
        VerifyGLEntryDeferrals(
          DeferralTemplate."Deferral Account", GenJournalLine."Document No.",
          ExpectedDeferralAmount, GLEntry."Document Type"::" ", DeferralTemplate."No. of Periods");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchaseGenJnlLineWithReverseChargeVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
    begin
        // [FEATURE] [Reverse Charge VAT]
        // [SCENARIO 290805] System creates G/L entry for "Reverse Charge VAT Account" with VAT amount in case of "Calc. Proportional Deduction VAT" = TRUE and "Proportional Deduction VAT %" = 0
        Initialize();

        // [GIVEN] VAT Posting Setup with "Calc. Proportional Deduction VAT" = TRUE and "Proportional Deduction VAT %" = 0 and "VAT %" = 20%
        CreateProportionalVATPostingSetup(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", 0);

        // [GIVEN] Purchase Journal with "Amount" = 100
        CreatePurchInvWithVATPostingSetup(GenJournalLine, VATPostingSetup);

        // [WHEN] Post journal
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] G/L Entry for "Reverse Charge VAT Account" created with Amount = -20
        GLEntry.SetRange("G/L Account No.", VATPostingSetup."Reverse Chrg. VAT Acc.");
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, -Round(GenJournalLine.Amount * VATPostingSetup."VAT %" / 100));
    end;

    [Test]
    [HandlerFunctions('CalcPostVATSettlementReqPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CalcPostVATSettlementPurchaseWithRevChargeVATPropDeductionVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        SettlementGLAccNo: Code[20];
        SettlementDocNo: Code[20];
        RevChargeVATAmount: Decimal;
        PropDedVATAmount: Decimal;
    begin
        // [FEATURE] [Reverse Charge VAT] [VAT Settlement]
        // [SCENARIO 295010] Calc. and Post VAT Settlement for reverse charge VAT setup with Proportional Deduction VAT
        Initialize();
        UpdateSettledVATPeriods();

        // [GIVEN] VAT Posting Setup with "Calc. Proportional Deduction VAT" = TRUE and "Proportional Deduction VAT %" = 10 and "VAT %" = 20%
        CreateProportionalVATPostingSetup(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", LibraryRandom.RandIntInRange(10, 20));

        // [GIVEN] Posted purchase journal line with "Amount" = 100
        CreatePurchInvWithVATPostingSetup(GenJournalLine, VATPostingSetup);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        RevChargeVATAmount := Round(GenJournalLine.Amount * VATPostingSetup."VAT %" / 100);
        PropDedVATAmount := Round(RevChargeVATAmount * VATPostingSetup."Proportional Deduction VAT %" / 100);

        // [WHEN] Calc and post VAT Settlement
        SettlementGLAccNo := LibraryERM.CreateGLAccountNo();
        SettlementDocNo := LibraryUtility.GenerateGUID();
        RunCalcAndPostVATSettlement(
          VATPostingSetup."VAT Bus. Posting Group", SettlementDocNo, SettlementGLAccNo, WorkDate());

        // [THEN] 3 G/L entries created
        // [THEN] Purchase VAT Account has amount = -2 (-(100 * 20%) * 10%)
        // [THEN] Reverse charge account has amount = 20 (100 * 20%)
        // [THEN] Settlement Account has amount = -18 (2 - 20)
        VerifyVATSettlementGLEntries(
          SettlementDocNo, VATPostingSetup."Purchase VAT Account", VATPostingSetup."Reverse Chrg. VAT Acc.", SettlementGLAccNo,
          PropDedVATAmount, RevChargeVATAmount, 3);

        // [THEN] GenJnlLineVATAmount = -2; GenJnlLine2Amount = 20; VATAmount = 18
        VerifyVATSettlementDataset(PropDedVATAmount, RevChargeVATAmount, RevChargeVATAmount - PropDedVATAmount);
    end;

    [Test]
    [HandlerFunctions('CalcPostVATSettlementReqPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CalcPostVATSettlementPurchaseWithRevChargeVATPropDeductionVAT0()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        SettlementGLAccNo: Code[20];
        SettlementDocNo: Code[20];
        RevChargeVATAmount: Decimal;
    begin
        // [FEATURE] [Reverse Charge VAT] [VAT Settlement]
        // [SCENARIO 295010] Calc. and Post VAT Settlement for reverse charge VAT setup with Proportional Deduction VAT = 0
        Initialize();
        UpdateSettledVATPeriods();

        // [GIVEN] VAT Posting Setup with "Calc. Proportional Deduction VAT" = TRUE and "Proportional Deduction VAT %" = 0 and "VAT %" = 20%
        CreateProportionalVATPostingSetup(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", 0);

        // [GIVEN] Posted purchase journal line with "Amount" = 100
        CreatePurchInvWithVATPostingSetup(GenJournalLine, VATPostingSetup);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        RevChargeVATAmount := Round(GenJournalLine.Amount * VATPostingSetup."VAT %" / 100);

        // [WHEN] Calc and post VAT Settlement
        SettlementGLAccNo := LibraryERM.CreateGLAccountNo();
        SettlementDocNo := LibraryUtility.GenerateGUID();
        RunCalcAndPostVATSettlement(VATPostingSetup."VAT Bus. Posting Group", SettlementDocNo, SettlementGLAccNo, WorkDate());

        // [THEN] 3 G/L entries created
        // [THEN] Purchase VAT Account has amount = 0 (-(100 * 20%) * 0%)
        // [THEN] Reverse charge account has amount = 20 (100 * 20%)
        // [THEN] Settlement Account has amount = -20 (0 - 20)
        VerifyVATSettlementGLEntries(
          SettlementDocNo, VATPostingSetup."Purchase VAT Account", VATPostingSetup."Reverse Chrg. VAT Acc.", SettlementGLAccNo,
          0, RevChargeVATAmount, 3);

        // [THEN] GenJnlLineVATAmount = 0; GenJnlLine2Amount = 20; VATAmount = 20
        VerifyVATSettlementDataset(0, RevChargeVATAmount, RevChargeVATAmount);
    end;

    [Test]
    [HandlerFunctions('CalcPostVATSettlementReqPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CalcPostVATSettlementPurchaseWithRevChargeVATPropDeductionVAT100()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        SettlementGLAccNo: Code[20];
        SettlementDocNo: Code[20];
        RevChargeVATAmount: Decimal;
        PropDedVATAmount: Decimal;
    begin
        // [FEATURE] [Reverse Charge VAT] [VAT Settlement]
        // [SCENARIO 295010] Calc. and Post VAT Settlement for reverse charge VAT setup with Proportional Deduction VAT = 100
        Initialize();
        UpdateSettledVATPeriods();

        // [GIVEN] VAT Posting Setup with "Calc. Proportional Deduction VAT" = TRUE and "Proportional Deduction VAT %" = 100 and "VAT %" = 20%
        CreateProportionalVATPostingSetup(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", 100);

        // [GIVEN] Posted purchase journal line with "Amount" = 100
        CreatePurchInvWithVATPostingSetup(GenJournalLine, VATPostingSetup);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        RevChargeVATAmount := Round(GenJournalLine.Amount * VATPostingSetup."VAT %" / 100);
        PropDedVATAmount := RevChargeVATAmount;

        // [WHEN] Calc and post VAT Settlement
        SettlementGLAccNo := LibraryERM.CreateGLAccountNo();
        SettlementDocNo := LibraryUtility.GenerateGUID();
        RunCalcAndPostVATSettlement(VATPostingSetup."VAT Bus. Posting Group", SettlementDocNo, SettlementGLAccNo, WorkDate());

        // [THEN] 2 G/L entries created
        // [THEN] Purchase VAT Account has amount = -20 (-(100 * 20%) * 100%)
        // [THEN] Reverse charge account has amount = 20 (100 * 20%)
        // [THEN] Settlement Account has amount = 0 (20 - 20)
        VerifyVATSettlementGLEntries(
          SettlementDocNo, VATPostingSetup."Purchase VAT Account", VATPostingSetup."Reverse Chrg. VAT Acc.", SettlementGLAccNo,
          PropDedVATAmount, RevChargeVATAmount, 2);

        // [THEN] GenJnlLineVATAmount = -20; GenJnlLine2Amount = 20; VATAmount = 0
        VerifyVATSettlementDataset(PropDedVATAmount, RevChargeVATAmount, 0);
    end;

    [Test]
    [HandlerFunctions('CalcPostVATSettlementReqPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CalcPostVATSettlementWithRevChargeVATPropDeductionVAT2VATPostingSetup()
    var
        VATPostingSetup1: Record "VAT Posting Setup";
        VATPostingSetup2: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        SettlementGLAccNo: Code[20];
        SettlementDocNo: Code[20];
        RevChargeVATAmount: Decimal;
        PropDedVATAmount: Decimal;
        RevChargeVATAmount2: Decimal;
        PropDedVATAmount2: Decimal;
    begin
        // [FEATURE] [Reverse Charge VAT] [VAT Settlement]
        // [SCENARIO 297117] Calc. and Post VAT Settlement for reverse charge VAT setup with Proportional Deduction VAT 2 VAT Posting Groups
        Initialize();
        UpdateSettledVATPeriods();

        // [GIVEN] Two VAT Posting Setup with "Calc. Proportional Deduction VAT" = TRUE and same VAT Business Posting Group
        // [GIVEN] The first VAT Posting Setup has "Proportional Deduction VAT %" = 10 and "VAT %" = 20%
        // [GIVEN] The second VAT Posting Setup has "Proportional Deduction VAT %" = 20 and "VAT %" = 20%
        CreateProportionalVATPostingSetup(
          VATPostingSetup1, VATPostingSetup1."VAT Calculation Type"::"Reverse Charge VAT", LibraryRandom.RandIntInRange(10, 20));
        CreateCopyOfVATPostingSetup(VATPostingSetup2, VATPostingSetup1, LibraryRandom.RandIntInRange(10, 20));

        // [GIVEN] Posted purchase invoice 1 has "Amount" = 100, Reverse charge = 20 (100 * 20%), Prop. Deduction VAT = -2 (-(100 * 20%) * 10%)
        CreatePurchInvWithVATPostingSetup(GenJournalLine, VATPostingSetup1);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        RevChargeVATAmount := Round(GenJournalLine.Amount * VATPostingSetup1."VAT %" / 100);
        PropDedVATAmount := Round(RevChargeVATAmount * VATPostingSetup1."Proportional Deduction VAT %" / 100);

        // [GIVEN] Posted purchase invoice 2 has "Amount" = 150, Reverse charge = 30 (150 * 20%), Prop. Deduction VAT = -6 (-(150 * 20%) * 20%)
        CreatePurchInvWithVATPostingSetup(GenJournalLine, VATPostingSetup2);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        RevChargeVATAmount2 := Round(GenJournalLine.Amount * VATPostingSetup2."VAT %" / 100);
        PropDedVATAmount2 := Round(RevChargeVATAmount2 * VATPostingSetup2."Proportional Deduction VAT %" / 100);

        // [WHEN] Calc and post VAT Settlement
        SettlementGLAccNo := LibraryERM.CreateGLAccountNo();
        SettlementDocNo := LibraryUtility.GenerateGUID();
        RunCalcAndPostVATSettlement(VATPostingSetup1."VAT Bus. Posting Group", SettlementDocNo, SettlementGLAccNo, WorkDate());

        // [THEN] 5 G/L entries created
        // [THEN] Purchase VAT Account has amount = -8 (-2 - 6)
        // [THEN] Reverse charge account has amount = 50 (20 + 30)
        // [THEN] Settlement Account has amount = -42 (8 - 50)
        VerifyVATSettlementGLEntries(
          SettlementDocNo, VATPostingSetup1."Purchase VAT Account", VATPostingSetup1."Reverse Chrg. VAT Acc.", SettlementGLAccNo,
          PropDedVATAmount + PropDedVATAmount2, RevChargeVATAmount + RevChargeVATAmount2, 5);

        // [THEN] Last line of the report is exported with GenJnlLineVATAmount = -6; GenJnlLine2Amount = 30; VATAmount = 42
        VerifyVATSettlementDataset(
          PropDedVATAmount2, RevChargeVATAmount2, RevChargeVATAmount - PropDedVATAmount + RevChargeVATAmount2 - PropDedVATAmount2);
    end;

    [Test]
    [HandlerFunctions('CalcPostVATSettlementReqPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CalcAndPostVATSettlementOnProportionalVATPostedWithoutVendLedgEntry()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        SettlementGLAccNo: Code[20];
        SettlementDocNo: Code[20];
        RevChargeVATAmount: Decimal;
        PropDedVATAmount: Decimal;
    begin
        // [SCENARIO 339793] Stan can calculate and post VAT settlement against the proportional VAT entry posted without the associated vendor ledger entry

        Initialize();
        UpdateSettledVATPeriods();

        // [GIVEN] VAT Posting Setup with "Calc. Proportional Deduction VAT" = TRUE and "Proportional Deduction VAT %" = 10 and "VAT %" = 20%
        CreateProportionalVATPostingSetup(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", LibraryRandom.RandIntInRange(10, 20));

        // [GIVEN] Posted purchase journal line with both "Account Type" and "Bal. Account Type" equals "G/L Account" and "Amount" = 100
        CreateLineWithVATPostingSetup(GenJournalLine, VATPostingSetup);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        RevChargeVATAmount := Round(GenJournalLine.Amount * VATPostingSetup."VAT %" / 100);
        PropDedVATAmount := Round(RevChargeVATAmount * VATPostingSetup."Proportional Deduction VAT %" / 100);
        SettlementGLAccNo := LibraryERM.CreateGLAccountNo();
        SettlementDocNo := LibraryUtility.GenerateGUID();

        // [WHEN] Calc and post VAT Settlement
        RunCalcAndPostVATSettlement(
          VATPostingSetup."VAT Bus. Posting Group", SettlementDocNo, SettlementGLAccNo, WorkDate());

        // [THEN] 3 G/L entries created
        // [THEN] Purchase VAT Account has amount = -2 (-(100 * 20%) * 10%)
        // [THEN] Reverse charge account has amount = 20 (100 * 20%)
        // [THEN] Settlement Account has amount = -18 (2 - 20)
        VerifyVATSettlementGLEntries(
          SettlementDocNo, VATPostingSetup."Purchase VAT Account", VATPostingSetup."Reverse Chrg. VAT Acc.", SettlementGLAccNo,
          PropDedVATAmount, RevChargeVATAmount, 3);

        // [THEN] GenJnlLineVATAmount = -2; GenJnlLine2Amount = 20; VATAmount = 18
        VerifyVATSettlementDataset(PropDedVATAmount, RevChargeVATAmount, RevChargeVATAmount - PropDedVATAmount);
    end;

    local procedure Initialize()
    var
        PurchSetup: Record "Purchases & Payables Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryReportDataset.Reset();
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;

        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        PurchSetup.Get();
        PurchSetup."Invoice Rounding" := false;
        PurchSetup.Modify();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        IsInitialized := true;
        Commit();
    end;

    [Normal]
    local procedure CreatePurchInvWithPropVat(var PurchHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; var PurchLine: Record "Purchase Line"; VatPostingSetup: Record "VAT Posting Setup"; DirectUnitCost: Decimal; Quantity: Decimal)
    var
        GenPostingSetup: Record "General Posting Setup";
    begin
        // Update posting group
        LibraryERM.FindGeneralPostingSetup(GenPostingSetup);

        // Create and post purchase journal
        LibraryPurchase.CreatePurchHeader(
          PurchHeader, DocumentType, CreateVendor(GenPostingSetup."Gen. Bus. Posting Group", VatPostingSetup."VAT Bus. Posting Group"));

        case PurchHeader."Document Type" of
            PurchHeader."Document Type"::Order, PurchHeader."Document Type"::Invoice:
                PurchHeader."Vendor Invoice No." := LibraryUtility.GenerateGUID();
            PurchHeader."Document Type"::"Credit Memo":
                PurchHeader."Vendor Cr. Memo No." := LibraryUtility.GenerateGUID();
        end;
        PurchHeader.Modify(true);

        CreatePurchLine(PurchLine, PurchHeader, GenPostingSetup."Gen. Prod. Posting Group", VatPostingSetup, Quantity, DirectUnitCost);
    end;

    local procedure SetupAdditionalCurrency(): Code[10]
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup."Additional Reporting Currency" := CreateCurrencyWithExchRate();
        GLSetup.Modify(true);
        exit(GLSetup."Additional Reporting Currency");
    end;

    local procedure CreateCurrencyWithExchRate(): Code[10]
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        LibraryERM.CreateCurrency(Currency);
        Currency.Validate("Residual Gains Account", LibraryERM.CreateGLAccountNo());
        Currency.Validate("Residual Losses Account", LibraryERM.CreateGLAccountNo());
        Currency.Modify(true);

        LibraryERM.CreateExchRate(CurrencyExchangeRate, Currency.Code, WorkDate());
        CurrencyExchangeRate.Validate("Exchange Rate Amount", 1);
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", CurrencyExchangeRate."Exchange Rate Amount");
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", GetTFS190253ExchRate());
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", CurrencyExchangeRate."Relational Exch. Rate Amount");
        CurrencyExchangeRate.Modify(true);
        exit(Currency.Code);
    end;

    local procedure CreateCopyOfVATPostingSetup(var VATPostingSetupNew: Record "VAT Posting Setup"; VATPostingSetup: Record "VAT Posting Setup"; ProportionalVATPct: Decimal)
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        VATPostingSetupNew := VATPostingSetup;
        VATPostingSetupNew."VAT Prod. Posting Group" := VATProductPostingGroup.Code;
        VATPostingSetupNew."Proportional Deduction VAT %" := ProportionalVATPct;
        VATPostingSetupNew.Insert();
    end;

    local procedure CreateProportionalVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATCalculationType: Enum "Tax Calculation Type"; ProportionalVATPct: Decimal)
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATCalculationType, GetTFS190253VATRate());

        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Calc. Prop. Deduction VAT", true);
        VATPostingSetup.Validate("Proportional Deduction VAT %", ProportionalVATPct);
        VATPostingSetup.Modify(true);
    end;

    local procedure CreatePostGenJnlLines(var GenJnlLine: Record "Gen. Journal Line"; GenPostingSetup: Record "General Posting Setup"; VATPostingSetup: Record "VAT Posting Setup"; CurrencyCode: Code[10]; DeferralCode: Code[10]; PostingDate: Date)
    var
        EntryAmount: Decimal;
        VendNo: Code[20];
    begin
        EntryAmount := LibraryRandom.RandDec(100, 2) * 100;

        InitGenJnlLine(GenJnlLine);
        VendNo := CreateVendor(GenPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");

        LibraryERM.CreateGeneralJnlLine(
          GenJnlLine, GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name", GenJnlLine."Document Type"::Invoice, GenJnlLine."Account Type"::Vendor, VendNo, -EntryAmount);
        GenJnlLine.Validate("Currency Code", CurrencyCode);
        GenJnlLine.Validate("Posting Date", PostingDate);
        GenJnlLine.Modify(true);

        LibraryERM.CreateGeneralJnlLine(
          GenJnlLine, GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name", "Gen. Journal Document Type"::" ",
          GenJnlLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), EntryAmount);
        GenJnlLine.Validate("Currency Code", CurrencyCode);
        GenJnlLine.Validate("Posting Date", PostingDate);
        GenJnlLine.Validate("Gen. Posting Type", GenJnlLine."Gen. Posting Type"::Purchase);
        GenJnlLine.Validate("Gen. Bus. Posting Group", GenPostingSetup."Gen. Bus. Posting Group");
        GenJnlLine.Validate("Gen. Prod. Posting Group", GenPostingSetup."Gen. Prod. Posting Group");
        GenJnlLine.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GenJnlLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GenJnlLine.Validate("Deferral Code", DeferralCode);
        GenJnlLine.Modify(true);

        LibraryERM.PostGeneralJnlLine(GenJnlLine);
    end;

    local procedure InitGenJnlLine(var GenJnlLine: Record "Gen. Journal Line")
    var
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJnlTemplate);
        GenJnlTemplate.Validate("Force Doc. Balance", false);
        GenJnlTemplate.Modify(true);
        LibraryERM.CreateGenJournalBatch(GenJnlBatch, GenJnlTemplate.Name);
        GenJnlLine.Init();
        GenJnlLine."Journal Template Name" := GenJnlBatch."Journal Template Name";
        GenJnlLine."Journal Batch Name" := GenJnlBatch.Name;
    end;

    local procedure CreatePurchDoc(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; CurrencyCode: Code[10]; GenPostingSetup: Record "General Posting Setup"; VATPostingSetup: Record "VAT Posting Setup")
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchHeader, PurchHeader."Document Type"::Invoice,
          CreateVendor(GenPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group"));

        PurchHeader."Vendor Invoice No." := LibraryUtility.GenerateGUID();
        PurchHeader.Validate("Currency Code", CurrencyCode);
        PurchHeader.Modify(true);
        CreatePurchLine(PurchLine, PurchHeader, GenPostingSetup."Gen. Prod. Posting Group", VATPostingSetup, 3, 23.12);
    end;

    local procedure CreatePurchLine(var PurchLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header"; GenProdPostGroupCode: Code[20]; VATPostingSetup: Record "VAT Posting Setup"; Quantity: Decimal; DirectUnitCost: Decimal)
    var
        GLAccNo: Code[20];
    begin
        if VATPostingSetup."VAT Calculation Type" = VATPostingSetup."VAT Calculation Type"::"Full VAT" then begin
            GLAccNo := VATPostingSetup."Purchase VAT Account";
            UpdateGLAccWithSetup(GLAccNo, GenProdPostGroupCode, VATPostingSetup."VAT Prod. Posting Group");
        end else
            GLAccNo := CreateGLAccWithSetup(GenProdPostGroupCode, VATPostingSetup."VAT Prod. Posting Group");

        LibraryPurchase.CreatePurchaseLine(
          PurchLine, PurchHeader, PurchLine.Type::"G/L Account", GLAccNo, Quantity);
        PurchLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchLine.Modify(true);
    end;

    local procedure CreateVendor(GenBusPostGroupCode: Code[20]; VATBusPostGroupCode: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Gen. Bus. Posting Group", GenBusPostGroupCode);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostGroupCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateGLAccWithSetup(GenProdPostGroupCode: Code[20]; VATProdPostGroupCode: Code[20]) GLAccNo: Code[20]
    begin
        GLAccNo := LibraryERM.CreateGLAccountNo();
        UpdateGLAccWithSetup(GLAccNo, GenProdPostGroupCode, VATProdPostGroupCode);
        exit(GLAccNo);
    end;

    local procedure CreatePurchInvWithDeferral(var PurchaseHeader: Record "Purchase Header"; VATPostingSetup: Record "VAT Posting Setup"; DeferralTemplateCode: Code[10]): Decimal
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        PurchaseHeader.Validate("Posting Date", CalcDate('<-CM>', WorkDate()));
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
          LibraryInventory.CreateItemNoWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"),
          LibraryRandom.RandIntInRange(10, 100));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(10, 100));
        PurchaseLine.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        PurchaseLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        PurchaseLine.Validate("Deferral Code", DeferralTemplateCode);
        PurchaseLine.Modify(true);
        exit(PurchaseLine.GetDeferralAmount());
    end;

    local procedure CreatePurchInvWithVATPostingSetup(var GenJournalLine: Record "Gen. Journal Line"; VATPostingSetup: Record "VAT Posting Setup")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        LibraryJournals.CreateGenJournalLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(),
          GenJournalLine."Bal. Account Type"::Vendor, LibraryPurchase.CreateVendorNo(),
          LibraryRandom.RandIntInRange(100, 200));
        GenJournalLine.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GenJournalLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GenJournalLine.Validate("Gen. Posting Type", GenJournalLine."Gen. Posting Type"::Purchase);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateLineWithVATPostingSetup(var GenJournalLine: Record "Gen. Journal Line"; VATPostingSetup: Record "VAT Posting Setup")
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, "Gen. Journal Document Type"::" ", GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(),
          LibraryRandom.RandIntInRange(100, 200));
        GenJournalLine.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GenJournalLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GenJournalLine.Validate("Gen. Posting Type", GenJournalLine."Gen. Posting Type"::Purchase);
        GenJournalLine.Modify(true);
    end;

    local procedure RunCalcAndPostVATSettlement(VATBusPostingGr: Code[20]; SettlementDocNo: Code[20]; SettlementGLAccNo: Code[20]; PostingDate: Date)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        CalcAndPostVATSettlement: Report "Calc. and Post VAT Settlement";
    begin
        CalcAndPostVATSettlement.InitializeRequest(
          PostingDate, PostingDate, PostingDate, SettlementDocNo, SettlementGLAccNo, true, true);
        CalcAndPostVATSettlement.SetInitialized(false);
        VATPostingSetup.SetRange("VAT Bus. Posting Group", VATBusPostingGr);
        CalcAndPostVATSettlement.SetTableView(VATPostingSetup);
        Commit();
        CalcAndPostVATSettlement.Run();
    end;

    local procedure UpdateGLAccWithSetup(GLAccNo: Code[20]; GenProdPostGroupCode: Code[20]; VATProdPostGroupCode: Code[20])
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get(GLAccNo);
        GLAccount.Validate("Gen. Prod. Posting Group", GenProdPostGroupCode);
        GLAccount.Validate("VAT Prod. Posting Group", VATProdPostGroupCode);
        GLAccount.Modify(true);
    end;

    local procedure GetTFS190253VATRate(): Decimal
    begin
        exit(25);
    end;

    local procedure GetTFS190253PropVATRate(): Decimal
    begin
        exit(75);
    end;

    local procedure GetTFS190253ExchRate(): Decimal
    begin
        exit(0.16809);
    end;

    local procedure CalcVATBaseAmount(var VATBaseAmount: Decimal; var VATBaseAmountACY: Decimal; PostingDate: Date; CurrencyCode: Code[10]; Amount: Decimal)
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup.TestField("Additional Reporting Currency");
        if CurrencyCode = GLSetup."Additional Reporting Currency" then begin
            VATBaseAmountACY := Amount;
            VATBaseAmount :=
              Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', PostingDate),
                LibraryERM.GetAmountRoundingPrecision());
        end else begin
            VATBaseAmount := Amount;
            VATBaseAmountACY :=
              Round(LibraryERM.ConvertCurrency(Amount, '', GLSetup."Additional Reporting Currency", PostingDate),
                LibraryERM.GetAmountRoundingPrecision());
        end;
    end;

    local procedure CalcPropVATBaseAmount(VATBaseAmount: Decimal; VATPostingSetup: Record "VAT Posting Setup") VATAmount: Decimal
    begin
        VATAmount :=
          Round(VATBaseAmount * 100 / (100 + VATPostingSetup."VAT %"), LibraryERM.GetAmountRoundingPrecision());
        VATAmount :=
          Round(VATAmount * VATPostingSetup."Proportional Deduction VAT %" / 100, LibraryERM.GetAmountRoundingPrecision());
        exit(VATAmount);
    end;

    local procedure CalcVATAmount(VATBaseAmount: Decimal; VATPostingSetup: Record "VAT Posting Setup") VATAmount: Decimal
    var
        RoundingPrecision: Decimal;
    begin
        RoundingPrecision := LibraryERM.GetAmountRoundingPrecision();
        VATAmount := Round(CalcPropVATBaseAmount(VATBaseAmount, VATPostingSetup) * VATPostingSetup."VAT %" / 100, RoundingPrecision);
        exit(VATAmount);
    end;

    local procedure CalcVATAmount2(VATBaseAmount: Decimal; VATPostingSetup: Record "VAT Posting Setup"; DeductWithPropVAT: Boolean) VATAmount: Decimal
    begin
        VATAmount := Round(VATBaseAmount * VATPostingSetup."VAT %" / 100, LibraryERM.GetAmountRoundingPrecision());
        if DeductWithPropVAT then
            VATAmount := Round(VATAmount * VATPostingSetup."Proportional Deduction VAT %" / 100, LibraryERM.GetAmountRoundingPrecision());
        exit(VATAmount);
    end;

    local procedure UpdateSettledVATPeriods()
    var
        SettledVATPeriod: Record "Settled VAT Period";
    begin
        SettledVATPeriod.ModifyAll(Closed, false);
    end;

    local procedure VerifyGLEntryWithNormalVAT(GenJnlLine: Record "Gen. Journal Line"; VATPostingSetup: Record "VAT Posting Setup")
    var
        ExpectedAmount: Decimal;
        ExpectedAmountACY: Decimal;
    begin
        CalcVATBaseAmount(ExpectedAmount, ExpectedAmountACY, GenJnlLine."Posting Date", GenJnlLine."Currency Code", GenJnlLine.Amount);
        ExpectedAmount := CalcVATAmount(ExpectedAmount, VATPostingSetup);
        ExpectedAmountACY := CalcVATAmount(ExpectedAmountACY, VATPostingSetup);

        VerifyGLEntry(VATPostingSetup."Purchase VAT Account", GenJnlLine."Document No.", ExpectedAmount, ExpectedAmountACY);
    end;

    local procedure VerifyGLEntryWithReverseChrgVAT(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; VATPostingSetup: Record "VAT Posting Setup"; DocNo: Code[20])
    var
        ExpectedAmount: Decimal;
        ExpectedAmountACY: Decimal;
    begin
        ExpectedAmount := LibraryERM.ConvertCurrency(PurchLine.Amount, PurchHeader."Currency Code", '', PurchHeader."Posting Date");
        ExpectedAmountACY := PurchLine.Amount;

        ExpectedAmount := CalcVATAmount2(ExpectedAmount, VATPostingSetup, TRUE);
        ExpectedAmountACY := CalcVATAmount2(ExpectedAmountACY, VATPostingSetup, TRUE);

        VerifyGLEntry(VATPostingSetup."Purchase VAT Account", DocNo, ExpectedAmount, ExpectedAmountACY);
    end;

    local procedure VerifyGLEntry(GLAccNo: Code[20]; DocNo: Code[20]; ExpectedAmount: Decimal; ExpectedAmountACY: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("G/L Account No.", GLAccNo);
        GLEntry.SetRange("Document No.", DocNo);
        GLEntry.FindLast();
        GLEntry.TestField(Amount, ExpectedAmount);
        GLEntry.TestField("Additional-Currency Amount", ExpectedAmountACY);
    end;

    local procedure VerifyGLEntryDeferrals(DeferralAccountNo: Code[20]; DocNo: Code[20]; DeferredAmount: Decimal; DocType: Enum "Gen. Journal Document Type"; CountOfPeriod: Integer)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("G/L Account No.", DeferralAccountNo);
        GLEntry.SetRange("Document No.", DocNo);
        GLEntry.SetRange("Document Type", DocType);
        GLEntry.SetFilter(Amount, '<%1', 0);
        Assert.RecordCount(GLEntry, CountOfPeriod);
        GLEntry.CalcSums(Amount);
        GLEntry.TestField(Amount, -DeferredAmount);
    end;

    local procedure VerifyVATSettlementGLEntries(SettlementDocNo: Code[20]; PurchaseAccount: Code[20]; RevChargeAccount: Code[20]; SettlementAccount: Code[20]; PropDedVATAmount: Decimal; RevChargeVATAmount: Decimal; GLCount: Integer)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", SettlementDocNo);
        Assert.RecordCount(GLEntry, GLCount);

        GLEntry.SetRange("G/L Account No.", PurchaseAccount);
        GLEntry.CalcSums(Amount);
        GLEntry.TestField(Amount, -PropDedVATAmount);

        GLEntry.SetRange("G/L Account No.", RevChargeAccount);
        GLEntry.CalcSums(Amount);
        GLEntry.TestField(Amount, RevChargeVATAmount);

        GLEntry.SetRange("G/L Account No.", SettlementAccount);
        GLEntry.CalcSums(Amount);
        GLEntry.TestField(Amount, PropDedVATAmount - RevChargeVATAmount);
    end;

    local procedure VerifyVATSettlementDataset(PropDedVATAmount: Decimal; RevChargeVATAmount: Decimal; SettledVATAmount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.GetLastRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('GenJnlLineVATAmount', -PropDedVATAmount);
        LibraryReportDataset.AssertCurrentRowValueEquals('GenJnlLine2Amount', RevChargeVATAmount);
        LibraryReportDataset.AssertCurrentRowValueEquals('VATAmount', SettledVATAmount);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustEntryPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalcPostVATSettlementReqPageHandler(var CalcAndPostVATSettlement: TestRequestPage "Calc. and Post VAT Settlement")
    begin
        CalcAndPostVATSettlement.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Message: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;
}
