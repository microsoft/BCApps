codeunit 134284 "Non Ded. VAT Misc."
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Non Deductible VAT]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryJob: Codeunit "Library - Job";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryFA: Codeunit "Library - Fixed Asset";
        LibraryRandom: Codeunit "Library - Random";
        LibraryDimension: Codeunit "Library - Dimension";
        LibrarySales: Codeunit "Library - Sales";
        Assert: Codeunit Assert;
        LibraryNonDeductibleVAT: Codeunit "Library - NonDeductible VAT";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IncorrectGLEntryAmtErr: Label 'Incorect amount in G/L Entry.';
        InCorrectProjLedgEntryAmtErr: Label 'Incorrect amount in Project Ledger Entry';
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure JobJnlLineWithNonDeductNormalVATFromPurchLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchInvHeader: record "Purch. Inv. Header";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        JobJnlLine: Record "Job Journal Line";
        JobTransferLine: Codeunit "Job Transfer Line";
        DeductiblePercent: Decimal;
        NonDeductiblePercent: Decimal;
    begin
        // [FEATURE] [Normal VAT]
        // [SCENARIO 416091] Job journal line built from purchase line includes non deductible VAT in "Unit Cost"
        Initialize();
        LibraryNonDeductibleVAT.SetUseForJobCost();
        // [GIVEN] VAT Posting Setup, where "Tax Calculation Type"::"Normal VAT", 'Deductible %' is '60'
        DeductiblePercent := LibraryRandom.RandInt(90);
        CreateNonDeductibleVATPostingSetup(VATPostingSetup, "Tax Calculation Type"::"Normal VAT", '', DeductiblePercent);
        NonDeductiblePercent := VATPostingSetup."VAT %" * (100 - DeductiblePercent) / 100;
        // [GIVEN] Purch Invoice, where line contains "Job No." = 'J', "Job Task No." = 'JT', "Job Line Type" = 'Billable'
        CreatePurchaseInvoice(PurchaseHeader, PurchaseLine, VATPostingSetup);
        // [GIVEN] "Direct Unit Cost" is 100
        SetJobForPurchaseLine(PurchaseLine);

        // [WHEN] Run FromPurchaseLineToJnlLine
        JobTransferLine.FromPurchaseLineToJnlLine(PurchaseHeader, PurchInvHeader, PurchCrMemoHeader, PurchaseLine, '', JobJnlLine);

        // [THEN] JobJnlLine, where "Unit Cost" is 108
        Assert.AreEqual(
            Round(JobJnlLine."Unit Cost (LCY)"),
            Round(PurchaseLine."Unit Cost (LCY)" * (100 + NonDeductiblePercent) / 100),
            'Unit Cost (LCY) with Non-Deductible VAT amount is not correct in Job Journal Line');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobJnlLineWithNonDeductReverseChargeVATFromPurchLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchInvHeader: record "Purch. Inv. Header";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        JobJnlLine: Record "Job Journal Line";
        JobTransferLine: Codeunit "Job Transfer Line";
        DeductiblePercent: Decimal;
        NonDeductiblePercent: Decimal;
    begin
        // [FEATURE] [Reverse Charge VAT]
        // [SCENARIO 416091] Job journal line built from purchase line includes non deductible VAT in "Unit Cost"
        Initialize();
        LibraryNonDeductibleVAT.SetUseForJobCost();
        // [GIVEN] VAT Posting Setup, where "Tax Calculation Type"::"Reverse Charge VAT", 'Deductible %' is '60'
        DeductiblePercent := LibraryRandom.RandInt(90);
        CreateNonDeductibleVATPostingSetup(VATPostingSetup, "Tax Calculation Type"::"Reverse Charge VAT", '', DeductiblePercent);
        NonDeductiblePercent := VATPostingSetup."VAT %" * (100 - DeductiblePercent) / 100;
        // [GIVEN] Purch Invoice, where line contains "Job No." = 'J', "Job Task No." = 'JT', "Job Line Type" = 'Billable'
        CreatePurchaseInvoice(PurchaseHeader, PurchaseLine, VATPostingSetup);
        // [GIVEN] "Direct Unit Cost" is 100
        SetJobForPurchaseLine(PurchaseLine);

        // [WHEN] Run FromPurchaseLineToJnlLine
        JobTransferLine.FromPurchaseLineToJnlLine(PurchaseHeader, PurchInvHeader, PurchCrMemoHeader, PurchaseLine, '', JobJnlLine);

        // [THEN] JobJnlLine, where "Unit Cost" is 108
        Assert.AreEqual(
            Round(JobJnlLine."Unit Cost (LCY)"),
            Round(PurchaseLine."Unit Cost (LCY)" * (100 + NonDeductiblePercent) / 100), 'Unit Cost (LCY)');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobJnlLineWithNonDeductReverseChargeVATFromPurchLineFCY()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchInvHeader: record "Purch. Inv. Header";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        JobJnlLine: Record "Job Journal Line";
        CurrExchRate: Record "Currency Exchange Rate";
        JobTransferLine: Codeunit "Job Transfer Line";
        DeductiblePercent: Decimal;
        NonDeductiblePercent: Decimal;
    begin
        // [FEATURE] [Reverse Charge VAT] [FCY]
        // [SCENARIO 416091] Job journal line built from purchase line (in FCY) includes non deductible VAT in "Unit Cost"
        Initialize();
        LibraryNonDeductibleVAT.SetUseForJobCost();
        // [GIVEN] VAT Posting Setup, where "Tax Calculation Type"::"Reverse Charge VAT", 'Deductible %' is '60'
        DeductiblePercent := LibraryRandom.RandInt(90);
        CreateNonDeductibleVATPostingSetup(VATPostingSetup, "Tax Calculation Type"::"Reverse Charge VAT", '', DeductiblePercent);
        NonDeductiblePercent := VATPostingSetup."VAT %" * (100 - DeductiblePercent) / 100;
        // [GIVEN] Purch Invoice in FCY, where line contains "Job No." = 'J', "Job Task No." = 'JT', "Job Line Type" = 'Billable'
        PurchaseHeader."Currency Code" := LibraryERM.CreateCurrencyWithRandomExchRates();
        CreatePurchaseInvoice(PurchaseHeader, PurchaseLine, VATPostingSetup);
        // [GIVEN] "Direct Unit Cost" is 100
        SetJobForPurchaseLine(PurchaseLine);
        // [GIVEN] Exchange amounts in the purchase line to local currency
        PurchaseLine.Amount :=
            Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                PurchaseHeader.GetUseDate(), PurchaseHeader."Currency Code",
                PurchaseLine.Amount, PurchaseHeader."Currency Factor"));
        PurchaseLine."Amount Including VAT" :=
            Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                PurchaseHeader.GetUseDate(), PurchaseHeader."Currency Code",
                PurchaseLine."Amount Including VAT", PurchaseHeader."Currency Factor"));

        // [WHEN] Run FromPurchaseLineToJnlLine
        JobTransferLine.FromPurchaseLineToJnlLine(PurchaseHeader, PurchInvHeader, PurchCrMemoHeader, PurchaseLine, '', JobJnlLine);

        // [THEN] JobJnlLine, where "Unit Cost" is 108
        // Work item id 521514: Non-Deductible VAT is correctly added to the job ledger entry for the purchase invoice with FCY
        Assert.AreEqual(
            Round(JobJnlLine."Unit Cost (LCY)"),
            Round(PurchaseLine."Unit Cost (LCY)" * (100 + NonDeductiblePercent) / 100), 'Unit Cost (LCY)');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NonDeductibleVATInPurchaseInvoice()
    var
        GLSetup: Record "General Ledger Setup";
        PurchaseHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        DeductiblePercent: Decimal;
        LineAmount: Decimal;
        NonDeductibleBase: Decimal;
        NonDeductibleAmount: Decimal;
        VATAmount: Decimal;
    begin
        // Post a purchase invoice and verify Non Deductible VAT in posted entries.
        Initialize();
        // Setup.
        DeductiblePercent := UpdateVATPostingSetup(VATPostingSetup);

        // Exercise: Post a Purchase Invoice and calculate Non-Deductible Base and Amount.
        LineAmount := CreatePurchaseInvoice(PurchaseHeader, VATPostingSetup);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        GLSetup.Get();
        NonDeductibleBase :=
          Round(LineAmount * (100 - GetDeductibleVATPctFromVATPostingSetup(VATPostingSetup)) / 100, GLSetup."Amount Rounding Precision");
        VATAmount := Round(LineAmount * VATPostingSetup."VAT %" / 100, GLSetup."Amount Rounding Precision");

        // As Non Deductible Amount = VAT Amount - Deductible Amount.
        NonDeductibleAmount :=
          VATAmount - Round(VATAmount * GetDeductibleVATPctFromVATPostingSetup(VATPostingSetup) / 100, GLSetup."Amount Rounding Precision");

        // Verify: Verify posted entries.
        VerifyGLEntry(DocumentNo, VATPostingSetup."Non-Ded. Purchase VAT Account", NonDeductibleAmount);
        VerifyVATEntry(DocumentNo, NonDeductibleBase, NonDeductibleAmount);

        // Tear Down.
        VATPostingSetup.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAmtOnAcqAccountWhenZeroDedPctAndBlankNDVATAccount()
    var
        GLSetup: Record "General Ledger Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GLEntry: Record "G/L Entry";
        DocumentNo: Code[20];
        NonDeductGLAccountNo: Code[20];
        FAAccountNo: Code[20];
        LineAmount: Decimal;
        TotalAmount: Decimal;
        OldDeductiblePercent: Decimal;
    begin
        // [SCENARIO 118209] VAT amount is posted to FA's Acquisition Account when 'Deductible %' = 0 and 'Non. Deductible VAT Account' is blank
        // [GIVEN] VAT Posting Setup with "Deductible %" = 0 and blank "Non. Deductible VAT Account"
        Initialize();
        LibraryNonDeductibleVAT.SetUseForFixedAssetCost();
        OldDeductiblePercent := GetZeroNonDeductibleVATPostingSetup(VATPostingSetup, NonDeductGLAccountNo, "Tax Calculation Type"::"Normal VAT");
        // [GIVEN] Purchase Invoice with Fixed Asset which Acquisition Account No. = "X" and Non Deductible VAT Amount = "Y"
        LineAmount := CreatePurchaseInvoiceWithFixedAsset(PurchaseHeader, PurchLine, VATPostingSetup);
        GLSetup.Get();
        TotalAmount := Round(LineAmount * (1 + VATPostingSetup."VAT %" / 100), GLSetup."Amount Rounding Precision");

        // [WHEN] Post Purchase Invoice
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] G/L Entry posted with G/L Account No. = "X" and Non Deductible VAT Amount = "Y"
        FAAccountNo := GetAcquisitionAccFromPurchLine(PurchLine);
        VerifyGLAccountBalance(DocumentNo, FAAccountNo, TotalAmount);

        // [THEN] There are 2 G/L Entries with linked Fixed Asset Ledger entries (TFS 409121)
        GLEntry.SetRange("G/L Account No.", FAAccountNo);
        Assert.RecordCount(GLEntry, 2);
        GLEntry.FindFirst();
        VerifyGLEntryFAEntryLinedPair(GLEntry);
        GLEntry.Next();
        VerifyGLEntryFAEntryLinedPair(GLEntry);

        // Tear Down.
        VATPostingSetup.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReverseChargeVATAmtOnAcqAccountWhenZeroDedPctAndBlankNDVATAccount()
    var
        GLSetup: Record "General Ledger Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GLEntry: Record "G/L Entry";
        DocumentNo: Code[20];
        NonDeductGLAccountNo: Code[20];
        FAAccountNo: Code[20];
        LineAmount: Decimal;
        TotalAmount: Decimal;
        OldDeductiblePercent: Decimal;
    begin
        // [SCENARIO 409121] VAT amount is posted to FA's Acquisition Account when 'Deductible %' = 0 and 'Non. Deductible VAT Account' is blank
        // [GIVEN] Reverse Charge VAT Posting Setup with "Deductible %" = 0 and blank "Non. Deductible VAT Account"

        Initialize();
        LibraryNonDeductibleVAT.SetUseForFixedAssetCost();
        OldDeductiblePercent := GetZeroNonDeductibleVATPostingSetup(VATPostingSetup, NonDeductGLAccountNo, "Tax Calculation Type"::"Reverse Charge VAT");
        // [GIVEN] Purchase Invoice with Fixed Asset which Acquisition Account No. = "X" and Non Deductible VAT Amount = "Y"
        LineAmount := CreatePurchaseInvoiceWithFixedAsset(PurchaseHeader, PurchLine, VATPostingSetup);
        GLSetup.Get();
        TotalAmount := Round(LineAmount * (1 + VATPostingSetup."VAT %" / 100), GLSetup."Amount Rounding Precision");

        // [WHEN] Post Purchase Invoice
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] G/L Entry posted with G/L Account No. = "X" and Non Deductible VAT Amount = "Y"
        FAAccountNo := GetAcquisitionAccFromPurchLine(PurchLine);
        VerifyGLAccountBalance(DocumentNo, FAAccountNo, TotalAmount);

        // [THEN] There are 2 G/L Entries with linked Fixed Asset Ledger entries
        GLEntry.SetRange("G/L Account No.", FAAccountNo);
        Assert.RecordCount(GLEntry, 2);
        GLEntry.FindFirst();
        VerifyGLEntryFAEntryLinedPair(GLEntry);
        GLEntry.Next();
        VerifyGLEntryFAEntryLinedPair(GLEntry);

        // Tear Down.
        VATPostingSetup.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAmtOnRevChargeVATAcctWhenZeroDedPctAndBlankNDVATAccount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        LineAmount: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Fixed Assets] [Reverse Charge VAT]
        // [SCENARIO 371652] VAT amount is posted to Reverse Charge VAT. Account when "Reverse Charge VAT", Deductible %" = 0 and "Non-Deductible VAT Account" is blank
        // [GIVEN] Reverse Charge VAT Posting Setup with "Reverse Charge VAT Acc." = "X", "Deductible %" = 0 and blank "Non-Deductible VAT Account"
        Initialize();
        LibraryNonDeductibleVAT.SetUseForFixedAssetCost();
        CreateNonDeductibleVATPostingSetup(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", '', 0);
        // [GIVEN] Purchase Invoice with Fixed Asset, "Non-Deductible VAT Amount" = "Y1", "Amount Including VAT" = "Y2"
        LineAmount := CreatePurchaseInvoiceWithFixedAsset(PurchaseHeader, PurchLine, VATPostingSetup);
        VATAmount :=
          Round(LineAmount * VATPostingSetup."VAT %" / 100, LibraryERM.GetAmountRoundingPrecision());

        // [WHEN] Post Purchase Invoice
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] G/L Entry created with "G/L Account No." = "X" and "Amount" = "Y1"
        VerifyGLEntry(DocumentNo, VATPostingSetup."Reverse Chrg. VAT Acc.", -VATAmount);
        // [THEN] Total Amount in FA Ledger Entries = "Y2"
        VerifyFALedgEntry(DocumentNo, PurchLine."No.", LineAmount + VATAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAmtOnRevChargeVATAcctWhenZeroDedPctAndNDVATAccount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        LineAmount: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Fixed Assets] [Reverse Charge VAT]
        // [SCENARIO 372201] VAT amount is posted to Reverse Charge VAT. Account when "Reverse Charge VAT", Deductible %" = 0 and "Non-Deductible VAT Account" is set up
        // [GIVEN] Reverse Charge VAT Posting Setup with "Reverse Charge VAT Acc." = "X", "Deductible %" = 0 and "Non-Deductible VAT Account"
        Initialize();
        LibraryNonDeductibleVAT.SetUseForFixedAssetCost();
        CreateNonDeductibleVATPostingSetup(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", LibraryERM.CreateGLAccountNo(), 0);
        // [GIVEN] Purchase Invoice with Fixed Asset, "Non-Deductible VAT Amount" = "Y1", "Amount Including VAT" = "Y2"
        LineAmount := CreatePurchaseInvoiceWithFixedAsset(PurchaseHeader, PurchLine, VATPostingSetup);
        VATAmount :=
          Round(LineAmount * VATPostingSetup."VAT %" / 100, LibraryERM.GetAmountRoundingPrecision());

        // [WHEN] Post Purchase Invoice
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] G/L Entry created with "G/L Account No." = "X" and "Amount" = "Y1"
        VerifyGLEntry(DocumentNo, VATPostingSetup."Reverse Chrg. VAT Acc.", -VATAmount);
        // [THEN] Total Amount in FA Ledger Entries = "Y2"
        VerifyFALedgEntry(DocumentNo, PurchLine."No.", LineAmount + VATAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NonDeductibleReverseChargeVATInPurchaseInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        LineAmount: Decimal;
        NonDeductibleBase: Decimal;
        NonDeductibleAmount: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Reverse Charge VAT]
        // [SCENARIO 378347] Non-Deductible VAT with Reverse Charge VAT when "Non-Deductible VAT Account" is not defined
        Initialize();
        // [GIVEN] Reverse Charge VAT Posting Setup where "Reverse Chrg. VAT Acc." = "R" and "Non-Deductible VAT Account" = ''
        CreateNonDeductibleVATPostingSetup(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", '', LibraryRandom.RandInt(99));

        // [GIVEN] Purchase Invoice with VAT Amount = "X", Non-Deductible VAT Amount = "Y",
        LineAmount := CreatePurchaseInvoice(PurchaseHeader, VATPostingSetup);
        NonDeductibleBase := Round(LineAmount * (100 - GetDeductibleVATPctFromVATPostingSetup(VATPostingSetup)) / 100);
        VATAmount := Round(LineAmount * VATPostingSetup."VAT %" / 100);
        NonDeductibleAmount := VATAmount - Round(VATAmount * GetDeductibleVATPctFromVATPostingSetup(VATPostingSetup) / 100);

        // [WHEN] Post Purchase Invoice
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] G/L Entry created with "G/L Account No." = "R" and "Non-Deductible VAT Amount" = -"Y"
        VerifyGLEntry(DocumentNo, VATPostingSetup."Reverse Chrg. VAT Acc.", -NonDeductibleAmount);
        // [THEN] G/L Entry balance for "G/L Account No." = "R" is equal to "VAT Amount" = -"X"
        VerifyGLAccountBalance(DocumentNo, VATPostingSetup."Reverse Chrg. VAT Acc.", -VATAmount);
        // [THEN] VAT Entry created with "Non-Deductible VAT Amount" = "Y"
        VerifyVATEntry(DocumentNo, NonDeductibleBase, NonDeductibleAmount);
    end;


    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure JobLedgerEntryAfterPostPurchCrMemoWithNonDeductibleVAT()
    var
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        JobLedgerEntry: Record "Job Ledger Entry";
        PostedCrMemoNo: Code[20];
    begin
        // [FEATURE] [Non-Deductible] [VAT] [Job]
        // [SCENARIO 348104] When you post Non-deductible VAT Credit Memo the Job Ledger Entry gets correct amounts
        Initialize();
        LibraryNonDeductibleVAT.SetUseForJobCost();
        // [GIVEN] VAT Posting Setup with Non-deductible VAT
        LibraryNonDeductibleVAT.CreatVATPostingSetupAllowedForNonDeductibleVAT(
            VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandDec(40, 2));
        AssignDeductibleVATPct(VATPostingSetup, 0);
        VATPostingSetup.Modify(true);

        // [WHEN] Credit Memo posted with this VAT Setup and Job No.
        PostedCrMemoNo := CreateAndPostCrMemoWithJobAndVATPostingSetup(PurchaseLine, VATPostingSetup);

        // [THEN] Unit Cost on Job Ledger Entry is Amount Including VAT for original purchase line
        JobLedgerEntry.SetRange("Document No.", PostedCrMemoNo);
        JobLedgerEntry.FindFirst();
        JobLedgerEntry.TestField("Total Cost", -PurchaseLine."Amount Including VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchInvWithDeferralAndDeductibleVATBlankNonDeductibleVATAcc()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        DeferralTemplate: Record "Deferral Template";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase] [Deferral] [VAT] [Deductible]
        // [SCENARIO 277884] Non-deductible VAT Amount posted to account of purchase line and deferred to account of purchase line
        // [SCENARIO 277884] when VAT Posting Setup."Non-Deductible VAT Account" is blank
        Initialize();
        // [GIVEN] VAT Posting Setup "V" with "VAT %" = 20 and "Deductible %" = 40% and "Non-Deductible VAT Account" = <blank>
        CreateNonDeductibleVATPostingSetup(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT",
          '', 3 * LibraryRandom.RandIntInRange(2, 5));

        // [GIVEN] "Deferral Template" "DT" with "Period No." = 2 and "Calc. Method" = "Straight-Line"
        LibraryERM.CreateDeferralTemplate(
          DeferralTemplate, DeferralTemplate."Calc. Method"::"Straight-Line",
          DeferralTemplate."Start Date"::"Beginning of Next Period", LibraryRandom.RandIntInRange(2, 5));

        // [GIVEN] Purchase Invoice with Amount = 1000, "Deferral Code" = "DT" and VAT setup = "V"
        // [GIVEN] Posting G/L Account = "GLA"
        CreatePurchInvoiceWithDeferralAndDedVAT(
            PurchaseHeader, PurchaseLine, WorkDate(), VATPostingSetup,
            DeferralTemplate."Deferral Code", LibraryRandom.RandDecInRange(1000, 2000, 2));

        // [WHEN] Post purchase invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Total Deferral Amount = 1000 * (20% VAT * (100% - 40% Deductible VAT)) = 1000 + (1000 * 20%) * 60% = 1000 + 200 * 60% = 1120.
        // [THEN] Non-Deductible VAT Amount to defer = 120
        // [THEN] Non-Deductible VAT Amount posted to "GLA"
        // [THEN] G/L Entries for "GLA" = 1000, 120 and balanced with deferall account -1000, -120, 500, 60, 500, 60.
        VerifyGLEntryDeferrals(DeferralTemplate."Deferral Account", PurchaseLine, VATPostingSetup, DeferralTemplate);

        TearDownLastUsedDateInPurchInvoiceNoSeries();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchInvWithDeferralAndDeductibleVATWithNonDeductibleVATAcc()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        DeferralTemplate: Record "Deferral Template";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase] [Deferral] [VAT] [Deductible]
        // [SCENARIO 277884] Non-deductible VAT Amount posted to account specified setup and deferred to account specified in setup
        // [SCENARIO 277884] when VAT Posting Setup."Non-Deductible VAT Account" is specified
        Initialize();
        // [GIVEN] VAT Posting Setup "V" with "VAT %" = 20 and "Deductible %" = 40% and "Non-Deductible VAT Account" = "NDVA"
        CreateNonDeductibleVATPostingSetup(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT",
          LibraryERM.CreateGLAccountNo(), 3 * LibraryRandom.RandIntInRange(2, 5));

        // [GIVEN] "Deferral Template" "DT" with "Period No." = 2 and "Calc. Method" = "Straight-Line"
        LibraryERM.CreateDeferralTemplate(
          DeferralTemplate, DeferralTemplate."Calc. Method"::"Straight-Line",
          DeferralTemplate."Start Date"::"Beginning of Next Period", LibraryRandom.RandIntInRange(2, 5));

        // [GIVEN] Purchase Invoice with Amount = 1000, "Deferral Code" = "DT" and VAT setup = "V"
        // [GIVEN] Posting G/L Account = "GLA"
        CreatePurchInvoiceWithDeferralAndDedVAT(
            PurchaseHeader, PurchaseLine, WorkDate(), VATPostingSetup,
            DeferralTemplate."Deferral Code", LibraryRandom.RandDecInRange(1000, 2000, 2));

        // [WHEN] Post purchase invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Total Deferral Amount = 1000 * (20% VAT * (100% - 40% Deductible VAT)) = 1000 + (1000 * 20%) * 60% = 1000 + 200 * 60% = 1120.
        // [THEN] Non-Deductible VAT Amount to defer = 120
        // [THEN] Non-Deductible VAT Amount posted to "NDVA"
        // [THEN] G/L Entries for "NDVA" = 120 and balanced with deferall account -120, 60, 60.

        VerifyGLEntryDeferrals(DeferralTemplate."Deferral Account", PurchaseLine, VATPostingSetup, DeferralTemplate);

        TearDownLastUsedDateInPurchInvoiceNoSeries();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchInvWithDeferralAndZeroDeductibleVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        DeferralTemplate: Record "Deferral Template";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase] [Deferral] [VAT] [Deductible]
        // [SCENARIO 285131] 100 % non-deductible VAT Amount should be deferred (border case)
        Initialize();
        // [GIVEN] VAT Posting Setup "V" with "VAT %" = 20 and "Deductible %" = 0%
        CreateNonDeductibleVATPostingSetup(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", '', 0);

        // [GIVEN] "Deferral Template" "DT" with "Period No." = 2 and "Calc. Method" = "Straight-Line"
        LibraryERM.CreateDeferralTemplate(
          DeferralTemplate, DeferralTemplate."Calc. Method"::"Straight-Line",
          DeferralTemplate."Start Date"::"Beginning of Next Period", LibraryRandom.RandIntInRange(2, 5));

        // [GIVEN] Purchase Invoice with Amount = 1000, "Deferral Code" = "DT" and VAT setup = "V"
        // [GIVEN] Posting G/L Account = "GLA"
        CreatePurchInvoiceWithDeferralAndDedVAT(
            PurchaseHeader, PurchaseLine, WorkDate(), VATPostingSetup,
            DeferralTemplate."Deferral Code", LibraryRandom.RandDecInRange(1000, 2000, 2));

        // [WHEN] Post purchase invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Non-Deductible VAT Amount to defer = 200
        // [THEN] G/L Entries for "GLA" = 1000, 200 and balanced with deferall account -1000, -200, 500, 100, 500, 100.
        VerifyGLEntryDeferrals(DeferralTemplate."Deferral Account", PurchaseLine, VATPostingSetup, DeferralTemplate);

        TearDownLastUsedDateInPurchInvoiceNoSeries();
    end;

    [Test]
    procedure NonDedRevChrgVATRoundingOnPurchInvWithCustomLinesAndDimensions()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        VATEntry: Record "VAT Entry";
        PostedInvoiceNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Non-deductible VAT] [Reverse Charge VAT] [Dimension] [Rounding]
        // [SCENARIO 384393] Purchase invoice non-deductible VAT rounding in case of reverse charge VAT, several custom lines with different dimensions
        Initialize();
        // [GIVEN] Reverse charge VAT posting setup with VAT = 22% and Deductible VAT = 40%
        CreateVATPostingSetupWithPct(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", 22, 40);
        // [GIVEN] Purchase invoice with several custom lines with different dimensions having in total Amount Excl. VAT = 1675.71, VAT Amount = 368.66
        CreatePurchaseInvoiceTFS384393(PurchaseHeader, VATPostingSetup);

        // [WHEN] Post the invoice
        PostedInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] There are several VAT entries having in total: Base = 670.28, Amount = 147.46, Nondeductible Base = 1005.43, Nondeductible Amount = 221.20
        FindVATEntry(VATEntry, PostedInvoiceNo);
        VATEntry.CalcSums(Base, Amount, "Non-Deductible VAT Base", "Non-Deductible VAT Amount");
        VATEntry.TestField(Base, 670.28);
        VATEntry.TestField(Amount, 147.46);
        VATEntry.TestField("Non-Deductible VAT Base", 1005.43);
        VATEntry.TestField("Non-Deductible VAT Amount", 221.2);
    end;

    [Test]
    procedure NonDedNormalVATRoundingOnPurchInvWithCustomLinesAndDimensions()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        VATEntry: Record "VAT Entry";
        PostedInvoiceNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Non-deductible VAT] [Normal VAT] [Dimension] [Rounding]
        // [SCENARIO 384393] Purchase invoice non-deductible VAT rounding in case of normal VAT, several custom lines with different dimensions
        Initialize();
        // [GIVEN] Normal VAT posting setup with VAT = 22% and Deductible VAT = 40%
        CreateVATPostingSetupWithPct(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 22, 40);
        // [GIVEN] Purchase invoice with several custom lines with different dimensions having in total Amount Excl. VAT = 1675.71, VAT Amount = 368.66
        CreatePurchaseInvoiceTFS384393(PurchaseHeader, VATPostingSetup);

        // [WHEN] Post the invoice
        PostedInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] There are several VAT entries having in total: Base = 670.28, Amount = 147.46, Nondeductible Base = 1005.43, Nondeductible Amount = 221.20
        FindVATEntry(VATEntry, PostedInvoiceNo);
        VATEntry.CalcSums(Base, Amount, "Non-Deductible VAT Base", "Non-Deductible VAT Amount");
        VATEntry.TestField(Base, 670.28);
        VATEntry.TestField(Amount, 147.46);
        VATEntry.TestField("Non-Deductible VAT Base", 1005.43);
        VATEntry.TestField("Non-Deductible VAT Amount", 221.2);
    end;

    [Test]
    procedure NonDedRevChrgVATRoundingOnPurchInvWith6LinesAndDimensions()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        VATEntry: Record "VAT Entry";
        PostedInvoiceNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Non-deductible VAT] [Reverse Charge VAT] [Dimension] [Rounding]
        // [SCENARIO 384393] Purchase invoice non-deductible VAT rounding in case of reverse charge VAT, several custom lines with different dimensions (384393 case 2)
        Initialize();
        // [GIVEN] Reverse charge VAT posting setup with VAT = 22% and Deductible VAT = 40%
        CreateVATPostingSetupWithPct(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", 22, 40);
        // [GIVEN] Purchase invoice with 6 lines different dimensions each having Amount = 151.53, having in total Amount Excl. VAT = 909.18, VAT Amount = 200.02
        CreatePurchaseInvoiceTFS384393_2(PurchaseHeader, VATPostingSetup);

        // [WHEN] Post the invoice
        PostedInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] There are several VAT entries having in total: Base = 363.67, Amount = 80.01, Nondeductible Base = 545.51, Nondeductible Amount = 120.01
        FindVATEntry(VATEntry, PostedInvoiceNo);
        Assert.RecordCount(VATEntry, 6);
        VATEntry.CalcSums(Base, Amount, "Non-Deductible VAT Base", "Non-Deductible VAT Amount");
        VATEntry.TestField(Base, 363.67);
        VATEntry.TestField(Amount, 80.01);
        VATEntry.TestField("Non-Deductible VAT Base", 545.51);
        VATEntry.TestField("Non-Deductible VAT Amount", 120.01);
    end;

    [Test]
    procedure NonDedNormalVATRoundingOnPurchInvWith6LinesAndDimensions()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        VATEntry: Record "VAT Entry";
        PostedInvoiceNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Non-deductible VAT] [Normal VAT] [Dimension] [Rounding]
        // [SCENARIO 384393] Purchase invoice non-deductible VAT rounding in case of normal VAT, several custom lines with different dimensions (384393 case 2)
        Initialize();
        // [GIVEN] Normal VAT posting setup with VAT = 22% and Deductible VAT = 40%
        CreateVATPostingSetupWithPct(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 22, 40);
        // [GIVEN] Purchase invoice with 6 lines different dimensions each having Amount = 151.53, having in total Amount Excl. VAT = 909.18, VAT Amount = 200.02
        CreatePurchaseInvoiceTFS384393_2(PurchaseHeader, VATPostingSetup);

        // [WHEN] Post the invoice
        PostedInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] There are several VAT entries having in total: Base = 363.67, Amount = 80.01, Nondeductible Base = 545.51, Nondeductible Amount = 120.01
        FindVATEntry(VATEntry, PostedInvoiceNo);
        Assert.RecordCount(VATEntry, 6);
        VATEntry.CalcSums(Base, Amount, "Non-Deductible VAT Base", "Non-Deductible VAT Amount");
        VATEntry.TestField(Base, 363.67);
        VATEntry.TestField(Amount, 80.01);
        VATEntry.TestField("Non-Deductible VAT Base", 545.51);
        VATEntry.TestField("Non-Deductible VAT Amount", 120.01);
    end;

    [Test]
    procedure DeferralNonDedVATRounding()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        DeferralTemplate: Record "Deferral Template";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GLEntry: Record "G/L Entry";
        PostedInvoiceNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Non-deductible VAT] [Deferral] [Rounding]
        // [SCENARIO 394920] Purchase invoice non-deductible VAT rounding in case of deferrals with several periods
        Initialize();
        // [GIVEN] VAT posting setup with VAT = 22% and Deductible VAT = 40%
        CreateVATPostingSetupWithPct(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 22, 60);
        // [GIVEN] Deferral Template 6 periods
        LibraryERM.CreateDeferralTemplate(
          DeferralTemplate, DeferralTemplate."Calc. Method"::"Straight-Line",
          DeferralTemplate."Start Date"::"Posting Date", 6);
        // [GIVEN] Purchase Invoice with Amount = 426.5, Posting Date = 30-06-2021
        CreatePurchInvoiceWithDeferralAndDedVAT(
          PurchaseHeader, PurchaseLine, WorkDate(), VATPostingSetup, DeferralTemplate."Deferral Code", 426.5);

        // [WHEN] Post the invoice
        PostedInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] There are several deferral non-deductible G/L entries with total amount 37.53
        FindGLEntry(GLEntry, PostedInvoiceNo, VATPostingSetup."Non-Ded. Purchase VAT Account");
        Assert.RecordCount(GLEntry, 9);
        GLEntry.CalcSums(Amount);
        GLEntry.TestField(Amount, 37.53);

        TearDownLastUsedDateInPurchInvoiceNoSeries();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchInvWithDeferralAndDeductibleVATBlankNonDeductibleVATAccReverseChargeVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        DeferralTemplate: Record "Deferral Template";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase] [Deferral] [VAT] [Deductible] [Reverse Charge VAT]
        // [SCENARIO 427120] Non-deductible VAT Amount posted to account of purchase line and deferred to account of purchase line
        // [SCENARIO 427120] when Reverse Charge VAT Posting Setup."Non-Deductible VAT Account" is blank
        Initialize();
        // [GIVEN] VAT Posting Setup "V" with "VAT %" = 20 and "Deductible %" = 40% and "Non-Deductible VAT Account" = <blank>, "VAT Calculation Type" = "Reverse Charge VAAT"
        CreateNonDeductibleVATPostingSetup(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT",
          '', 3 * LibraryRandom.RandIntInRange(2, 5));

        // [GIVEN] "Deferral Template" "DT" with "Period No." = 2 and "Calc. Method" = "Straight-Line"
        LibraryERM.CreateDeferralTemplate(
          DeferralTemplate, DeferralTemplate."Calc. Method"::"Straight-Line",
          DeferralTemplate."Start Date"::"Beginning of Next Period", LibraryRandom.RandIntInRange(2, 5));

        // [GIVEN] Purchase Invoice with Amount = 1000, "Deferral Code" = "DT" and VAT setup = "V"
        // [GIVEN] Posting G/L Account = "GLA"
        CreatePurchInvoiceWithDeferralAndDedVAT(
            PurchaseHeader, PurchaseLine, GetPostingDate(), VATPostingSetup,
            DeferralTemplate."Deferral Code", LibraryRandom.RandDecInRange(1000, 2000, 2));

        // [WHEN] Post purchase invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Total Deferral Amount = 1000 * (20% VAT * (100% - 40% Deductible VAT)) = 1000 + (1000 * 20%) * 60% = 1000 + 200 * 60% = 1120.
        // [THEN] Non-Deductible VAT Amount to defer = 120
        // [THEN] Non-Deductible VAT Amount posted to "GLA"
        // [THEN] G/L Entries for "GLA" = 1000, 120 and balanced with deferall account -1000, -120, 500, 60, 500, 60.
        VerifyGLEntryDeferrals(DeferralTemplate."Deferral Account", PurchaseLine, VATPostingSetup, DeferralTemplate, GetPostingDate());

        TearDownLastUsedDateInPurchInvoiceNoSeries();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchInvWithDeferralAndDeductibleVATWithNonDeductibleVATAccReverseChargeVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        DeferralTemplate: Record "Deferral Template";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase] [Deferral] [VAT] [Deductible] [Reverse Charge VAT]
        // [SCENARIO 427120] Non-deductible VAT Amount posted to account specified setup and deferred to account specified in setup
        // [SCENARIO 427120] when Reverse Charge VAT Posting Setup."Non-Deductible VAT Account" is specified
        Initialize();
        // [GIVEN] VAT Posting Setup "V" with "VAT %" = 20 and "Deductible %" = 40% and "Non-Deductible VAT Account" = "NDVA", "VAT Calculation Type" = "Reverse Charge VAAT"
        CreateNonDeductibleVATPostingSetup(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT",
          LibraryERM.CreateGLAccountNo(), 3 * LibraryRandom.RandIntInRange(2, 5));

        // [GIVEN] "Deferral Template" "DT" with "Period No." = 2 and "Calc. Method" = "Straight-Line"
        LibraryERM.CreateDeferralTemplate(
          DeferralTemplate, DeferralTemplate."Calc. Method"::"Straight-Line",
          DeferralTemplate."Start Date"::"Beginning of Next Period", LibraryRandom.RandIntInRange(2, 5));

        // [GIVEN] Purchase Invoice with Amount = 1000, "Deferral Code" = "DT" and VAT setup = "V"
        // [GIVEN] Posting G/L Account = "GLA"
        CreatePurchInvoiceWithDeferralAndDedVAT(
            PurchaseHeader, PurchaseLine, GetPostingDate(), VATPostingSetup,
            DeferralTemplate."Deferral Code", LibraryRandom.RandDecInRange(1000, 2000, 2));

        // [WHEN] Post purchase invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Total Deferral Amount = 1000 * (20% VAT * (100% - 40% Deductible VAT)) = 1000 + (1000 * 20%) * 60% = 1000 + 200 * 60% = 1120.
        // [THEN] Non-Deductible VAT Amount to defer = 120
        // [THEN] Non-Deductible VAT Amount posted to "NDVA"
        // [THEN] G/L Entries for "NDVA" = 120 and balanced with deferall account -120, 60, 60.

        VerifyGLEntryDeferrals(DeferralTemplate."Deferral Account", PurchaseLine, VATPostingSetup, DeferralTemplate, GetPostingDate());

        TearDownLastUsedDateInPurchInvoiceNoSeries();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchInvWithDeferralAndZeroDeductibleVATReverseChargeVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        DeferralTemplate: Record "Deferral Template";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase] [Deferral] [VAT] [Deductible] [Reverse Charge VAT]
        // [SCENARIO 427120] 100 % non-deductible Reverse Charge VAT Amount should be deferred (border case)
        Initialize();
        // [GIVEN] VAT Posting Setup "V" with "VAT %" = 20 and "Deductible %" = 0%, "VAT Calculation Type" = "Reverse Charge VAAT"
        CreateNonDeductibleVATPostingSetup(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", '', 0);

        // [GIVEN] "Deferral Template" "DT" with "Period No." = 2 and "Calc. Method" = "Straight-Line"
        LibraryERM.CreateDeferralTemplate(
          DeferralTemplate, DeferralTemplate."Calc. Method"::"Straight-Line",
          DeferralTemplate."Start Date"::"Beginning of Next Period", LibraryRandom.RandIntInRange(2, 5));

        // [GIVEN] Purchase Invoice with Amount = 1000, "Deferral Code" = "DT" and VAT setup = "V"
        // [GIVEN] Posting G/L Account = "GLA"
        CreatePurchInvoiceWithDeferralAndDedVAT(
            PurchaseHeader, PurchaseLine, GetPostingDate(), VATPostingSetup,
            DeferralTemplate."Deferral Code", LibraryRandom.RandDecInRange(1000, 2000, 2));

        // [WHEN] Post purchase invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Non-Deductible VAT Amount to defer = 200
        // [THEN] G/L Entries for "GLA" = 1000, 200 and balanced with deferall account -1000, -200, 500, 100, 500, 100.
        VerifyGLEntryDeferrals(DeferralTemplate."Deferral Account", PurchaseLine, VATPostingSetup, DeferralTemplate, GetPostingDate());

        TearDownLastUsedDateInPurchInvoiceNoSeries();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeferralNonDedVATRoundingReverseChargeVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        DeferralTemplate: Record "Deferral Template";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GLEntry: Record "G/L Entry";
        PostedInvoiceNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Non-deductible VAT] [Deferral] [Rounding]
        // [SCENARIO 427120] Purchase invoice non-deductible Reverse Charge VAT rounding in case of deferrals with several periods
        Initialize();
        // [GIVEN] VAT posting setup with VAT = 22% and Deductible VAT = 40%, "VAT Calculation Type" = "Reverse Charge VAAT"
        CreateVATPostingSetupWithPct(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", 22, 60);
        // [GIVEN] Deferral Template 6 periods
        LibraryERM.CreateDeferralTemplate(
          DeferralTemplate, DeferralTemplate."Calc. Method"::"Straight-Line",
          DeferralTemplate."Start Date"::"Posting Date", 6);
        // [GIVEN] Purchase Invoice with Amount = 426.5, Posting Date = 30-06-2021
        CreatePurchInvoiceWithDeferralAndDedVAT(
          PurchaseHeader, PurchaseLine, GetPostingDate(), VATPostingSetup, DeferralTemplate."Deferral Code", 426.5);

        // [WHEN] Post the invoice
        PostedInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] There are several deferral non-deductible G/L entries with total amount 37.53
        FindGLEntry(GLEntry, PostedInvoiceNo, VATPostingSetup."Non-Ded. Purchase VAT Account");
        Assert.RecordCount(GLEntry, 9);
        GLEntry.CalcSums(Amount);
        GLEntry.TestField(Amount, 37.53);

        TearDownLastUsedDateInPurchInvoiceNoSeries();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedFCYPurchInvWithDeferralAndDeductibleVATBlankNonDeductibleVATAcc()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        DeferralTemplate: Record "Deferral Template";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        // [FEATURE] [Purchase] [Deferral] [VAT] [Deductible]
        // [SCENARIO 473521] Non-deductible VAT Amount posted to account of purchase line with currecy and deferred to account of purchase line


        Initialize();
        // [GIVEN] VAT Posting Setup "V" with "VAT %" = 20 and "Deductible %" = 40%
        CreateNonDeductibleVATPostingSetup(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT",
          '', 3 * LibraryRandom.RandIntInRange(2, 5));

        // [GIVEN] "Deferral Template" "DT" with "Period No." = 2 and "Calc. Method" = "Straight-Line"
        LibraryERM.CreateDeferralTemplate(
          DeferralTemplate, DeferralTemplate."Calc. Method"::"Straight-Line",
          DeferralTemplate."Start Date"::"Posting Date", LibraryRandom.RandIntInRange(2, 5));

        // [GIVEN] Currency "USD" with "Exchange Rate" = 0.5
        Currency.Get(LibraryERM.CreateCurrencyWithRandomExchRates());
        // [GIVEN] Purchase Invoice with Amount = 1000, "Deferral Code" = "DT" and VAT setup = "V"
        // [GIVEN] Posting G/L Account = "GLA"
        CreatePurchInvoiceWithDeferralAndDedVAT(
            PurchaseHeader, PurchaseLine, CalcDate('<CM+1D>', WorkDate()), VATPostingSetup,
            Currency.Code, DeferralTemplate."Deferral Code", LibraryRandom.RandDecInRange(1000, 2000, 2));

        // [WHEN] Post purchase invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Total Deferral Amount = 1000 * (20% VAT * (100% - 40% Deductible VAT)) = 1000 + (1000 * 20%) * 60% = 1000 + 200 * 60% = 1120.
        // [THEN] Non-Deductible VAT Amount to defer = 120
        // [THEN] LCY Non-Deductible VAT Amount to defer = 60
        PurchaseLine.Amount :=
            Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                    PurchaseHeader.GetUseDate(), PurchaseHeader."Currency Code",
                    PurchaseLine.Amount, PurchaseHeader."Currency Factor"));
        VerifyGLEntriesDeferralsAmount(PurchaseLine, VATPostingSetup);

        TearDownLastUsedDateInPurchInvoiceNoSeries();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobJnlLineWithNonDeductNormalVATFromGenJnlLine()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJnlLine: Record "Gen. Journal Line";
        JobJnlLine: Record "Job Journal Line";
        JobTransferLine: Codeunit "Job Transfer Line";
        DeductiblePercent: Decimal;
        NonDeductiblePercent: Decimal;
    begin
        // [FEATURE] [Normal VAT] [UT]
        // [SCENARIO 547475] Job journal line built from the general journal line includes non deductible VAT in "Unit Cost"
        Initialize();
        LibraryNonDeductibleVAT.SetUseForJobCost();
        // [GIVEN] VAT Posting Setup, where "Tax Calculation Type"::"Normal VAT", 'Deductible %' is '60'
        DeductiblePercent := LibraryRandom.RandInt(90);
        CreateNonDeductibleVATPostingSetup(VATPostingSetup, "Tax Calculation Type"::"Normal VAT", '', DeductiblePercent);
        NonDeductiblePercent := VATPostingSetup."VAT %" * (100 - DeductiblePercent) / 100;
        // [GIVEN] General journal line where line contains Amount = 100, "Job No." = 'J', "Job Task No." = 'JT', "Job Line Type" = 'Billable'
        CreateJobGLJournalLine(GenJnlLine, VATPostingSetup);

        // [WHEN] Run FromGenJnlLineToJnlLine
        JobTransferLine.FromGenJnlLineToJnlLine(GenJnlLine, JobJnlLine);

        // [THEN] JobJnlLine contains "Unit Cost" equals 106
        Assert.AreEqual(
            Round(JobJnlLine."Unit Cost (LCY)"),
            Round((GenJnlLine."VAT Base Amount (LCY)" + GenJnlLine."Non-Deductible VAT Amount LCY") / GenJnlLine."Job Quantity"),
            'Unit Cost (LCY) with Non-Deductible VAT amount is not correct in Job Journal Line');
        // [THEN] JobJnlLine contains "Total Unit Cost" equals 106
        Assert.AreEqual(
            Round(JobJnlLine."Total Cost (LCY)"),
            Round(GenJnlLine."VAT Base Amount (LCY)" + GenJnlLine."Non-Deductible VAT Amount LCY"),
            'Total Cost (LCY) with Non-Deductible VAT amount is not correct in Job Journal Line');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvWithNonDedAndDeprUntilFADateBeforeInvDate()
    var
        GLSetup: Record "General Ledger Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo, NonDeductGLAccountNo : Code[20];
        LineAmount, TotalAmount : Decimal;
    begin
        // [SCENARIO 538673] Depreciation FA Ledger Entry is not created when post purchase invoice
        // [SCENARIO 538673] with fixed asset, Non-Deductible VAT, "Depr. until FA Posting Date" option
        // [SCENARIO 538673] and posting date after "Depreciation Starting Date" of the FA

        Initialize();
        LibraryNonDeductibleVAT.SetUseForFixedAssetCost();
        GetZeroNonDeductibleVATPostingSetup(VATPostingSetup, NonDeductGLAccountNo, "Tax Calculation Type"::"Normal VAT");
        // [GIVEN] Fixed asset with "Depreciation Starting Date" = 01.01.2024
        // [GIVEN] Purchase Invoice with "Posting Date" = 06.06.2024, Non Deductible VAT, Fixed Asset,
        // [GIVEN] "Depr. until FA Posting Date" and "Amount Including VAT" = 100
        LineAmount :=
            CreatePurchaseInvoiceWithFixedAsset(
                PurchaseHeader, PurchLine, VATPostingSetup,
                CreateFixedAssetWithDepreciationStartDate(VATPostingSetup));
        PurchLine.Validate("Depr. until FA Posting Date", true);
        PurchLine.Modify(true);
        GLSetup.Get();
        TotalAmount := Round(LineAmount * (1 + VATPostingSetup."VAT %" / 100), GLSetup."Amount Rounding Precision");

        // [WHEN] Post Purchase Invoice
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Total Amount in FA Ledger Entries = 100
        VerifyFALedgEntry(DocumentNo, PurchLine."No.", TotalAmount);

        // Tear Down.
        VATPostingSetup.Delete();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ProjectLedgerEntryShowsCorrectAmountWithNonDeductibleVATWhenPostFromPurchaseInvoice()
    var
        GLAccount: Record "G/L Account";
        JobLedgerEntry: Record "Job Ledger Entry";
        JobTask: Record "Job Task";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        VATPostingSetup: Record "VAT Posting Setup";
        Cost: array[3] of Decimal;
        Quantity: array[3] of Decimal;
        GenPostingType: Enum "General Posting Type";
    begin
        // [SCENARIO 540694] Project Ledger Entry shows correct Amounts
        // When Purchase Invoice is posted with Non-Deductible VAT and Project No.
        Initialize();

        // [GIVEN] Setup NonDeductibleVAT.
        LibraryNonDeductibleVAT.SetUseForJobCost();

        // [GIVEN] Create VAT Posting Setup with Non-deductible VAT.
        LibraryNonDeductibleVAT.CreateVATPostingSetupWithNonDeductibleDetail(VATPostingSetup, 19, 100);

        // [GIVEN] Create G/L Account.
        GLAccount.Get(LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GenPostingType::Purchase));

        // [GIVEN] Create Job and Job Task.
        CreateJobWithJobsUtil(JobTask);

        // [GIVEN] Generate Cost.
        GenerateCost(Cost);

        // [GIVEN] Generate Quantities.
        GenerateQuantites(Quantity);

        // [GIVEN] Create Purchase Invoice and Post it.
        PurchInvHeader.Get(CreatePurchaseInvoiceWithProject(VATPostingSetup, GLAccount."No.", Cost, Quantity, JobTask));

        // [GIVEN] Find Purchase Invoice Line.
        FindPurchaseInvoiceLine(PurchInvLine, PurchInvHeader."No.");

        // [WHEN] Find Job Ledger Entry.
        FindJobLedgerEntry(JobLedgerEntry, PurchInvHeader."No.");

        // [THEN] Verify Job Ledger Entry Total Cost Field equals to Purchase Invoice Line Field Amount Including VAT.
        Assert.AreEqual(JobLedgerEntry."Total Cost", PurchInvLine."Amount Including VAT", InCorrectProjLedgEntryAmtErr);

        // [THEN] Verify Job Ledger Entry Unit Cost Field equals to Purchase Invoice Line Field Amount Including VAT.
        Assert.AreEqual(JobLedgerEntry."Unit Cost", PurchInvLine."Amount Including VAT", InCorrectProjLedgEntryAmtErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ProjectLedgerEntryShowsCorrectAmountWithNonDeductibleVATWhenPostFromGenJnlLine()
    var
        GLAccount: Record "G/L Account";
        JobLedgerEntry: Record "Job Ledger Entry";
        JobTask: Record "Job Task";
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        Cost: array[4] of Decimal;
        Quantity: array[3] of Decimal;
        DocumentNo: Code[20];
        GenPostingType: Enum "General Posting Type";
    begin
        // [SCENARIO 540694] Project Ledger Entry shows correct Amounts
        // When Job G/L Journal is posted with Non-Deductible VAT and Project No.
        Initialize();

        // [GIVEN] Setup NonDeductibleVAT.
        LibraryNonDeductibleVAT.SetUseForJobCost();

        // [GIVEN] Create VAT Posting Setup with Non-deductible VAT.
        LibraryNonDeductibleVAT.CreateVATPostingSetupWithNonDeductibleDetail(VATPostingSetup, 19, 100);

        // [GIVEN] Create G/L Account.
        GLAccount.Get(LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GenPostingType::Purchase));

        // [GIVEN] Create Job and Job Task.
        CreateJobWithJobsUtil(JobTask);

        // [GIVEN] Generate Cost.
        GenerateCost(Cost);

        // [GIVEN] Generate Quantities.
        GenerateQuantites(Quantity);

        // [GIVEN] Create Vendor.
        CreateVendor(Vendor, VATPostingSetup);

        // [GIVEN] Generate Document No. and save it in a Variable.
        DocumentNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Create General Journal Lines and Post it.
        CreateGeneralJournalLines(
            GLAccount."No.", Cost,
            Quantity,
            JobTask."Job No.",
            JobTask."Job Task No.",
            DocumentNo,
            Vendor."No.");

        // [WHEN] Find Job Ledger Entry.
        FindJobLedgerEntry(JobLedgerEntry, DocumentNo);

        // [THEN] Verify Job Ledger Entry Total Cost Field equals to Purchase Invoice Line Field Amount Including VAT.
        Assert.AreEqual(JobLedgerEntry."Total Cost", Quantity[2] * Cost[2], InCorrectProjLedgEntryAmtErr);

        // [THEN] Verify Job Ledger Entry Unit Cost Field equals to Purchase Invoice Line Field Amount Including VAT.
        Assert.AreEqual(JobLedgerEntry."Unit Cost", Cost[2], InCorrectProjLedgEntryAmtErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceNonDeductibleVAT()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        GLEntry: Record "G/L Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        AcquisitionCostGLAccount: Code[20];
        InvoiceNo: Code[20];
        VATAmount: Decimal;
        VATCalculationType: Enum "Tax Calculation Type";

    begin
        // [SCENARIO 562366] Posting a Purchase Invoice with Non-deductible VAT amount incorrectly posts to the depreciation expense account instead of the fixed asset cost account in the British version.
        Initialize();

        // [GIVEN] Enable "Use For Item Cost" on VAT Setup
        LibraryNonDeductibleVAT.SetUseForFixedAssetCost();

        // [GIVEN] Create VAT Posting Setup as VAT % 20 and Non-Deductible VAT % as 100.
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATCalculationType::"Normal VAT", 20);
        VATPostingSetup."Allow Non-Deductible VAT" := VATPostingSetup."Allow Non-Deductible VAT"::Allow;
        VATPostingSetup.Validate("Non-Deductible VAT %", 100);
        VATPostingSetup.Modify(true);

        // [GIVEN] Create Vendor with VAT Posting Setup.
        CreateVendor(Vendor, VATPostingSetup);

        // [GIVEN] Create FA Depreciation with Acquired as True.
        CreateFixedAssetDepreciation(FADepreciationBook, VATPostingSetup."VAT Prod. Posting Group", Vendor."No.", AcquisitionCostGLAccount);

        // [GIVEN] Create Purchase Invoice Header
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, vendor."No.");

        // [GIVEN] Create Purchase Invoice with Fixed Asset and Direct Unit Cost as 25702.50 and Depr. Acquisition Cost, Depr. until FA Posting Date as TRUE.
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Fixed Asset", fADepreciationBook."FA No.", 1);
        PurchaseLine.Validate("Direct Unit Cost", 25702.50);
        PurchaseLine.Validate("Depreciation Book Code", FADepreciationBook."Depreciation Book Code");
        PurchaseLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        PurchaseLine.Validate("Depr. Acquisition Cost", true);
        PurchaseLine.Validate("Depr. until FA Posting Date", true);
        PurchaseLine.Modify(true);

        // [GIVEN] Calculate VAT Amount
        VATAmount := PurchaseLine."Amount Including VAT" - PurchaseLine.Amount;

        // [WHEN] Post Purchase Invoice
        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Verify G/L Entry Account for VAT Amount.
        GLEntry.SetRange("Document No.", InvoiceNo);
        GLEntry.SetRange("G/L Account No.", AcquisitionCostGLAccount);
        GLEntry.SetRange(Amount, VATAmount);
        Assert.RecordIsNotEmpty(GLEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobJnlLineWithNonDeductNormalVATInFCYFromGenJnlLine()
    var
        Customer: Record Customer;
        Job: Record Job;
        JobTask: Record "Job Task";
        VATPostingSetup: Record "VAT Posting Setup";
        GenJnlLine: Record "Gen. Journal Line";
        JobJnlLine: Record "Job Journal Line";
        JobTransferLine: Codeunit "Job Transfer Line";
        DeductiblePercent: Decimal;
    begin
        // [FEATURE] [Normal VAT] [UT]
        // [SCENARIO 575793] Job journal line with FCY built from the general journal line includes non deductible VAT in "Unit Cost"
        Initialize();
        LibraryNonDeductibleVAT.SetUseForJobCost();
        // [GIVEN] VAT Posting Setup, where "Tax Calculation Type"::"Normal VAT", 'Deductible %' is '60'
        DeductiblePercent := LibraryRandom.RandInt(90);
        CreateNonDeductibleVATPostingSetup(VATPostingSetup, "Tax Calculation Type"::"Normal VAT", '', DeductiblePercent);
        // [GIVEN] Job "X" with currency which factor is 0.5
        LibrarySales.CreateCustomer(Customer);
        LibraryJob.CreateJob(Job, Customer."No.");
        Job.Validate("Currency Code", LibraryERM.CreateCurrencyWithRandomExchRates());
        Job.Modify(true);
        LibraryJob.CreateJobTask(Job, JobTask);
        // [GIVEN] General journal line where line contains "Non-Deductible VAT Amount" = 100, "Job No." = "X" "Job Line Type" = 'Billable'
        // [GIVEN] "Job Quantity" = 2, "Job Unit Cost" = 50
        CreateJobGLJournalLine(GenJnlLine, JobTask, VATPostingSetup);

        // [WHEN] Run FromGenJnlLineToJnlLine
        JobTransferLine.FromGenJnlLineToJnlLine(GenJnlLine, JobJnlLine);

        // [THEN] JobJnlLine contains "Unit Cost LCY" = ("Job Unit Cost" + "Non-Deductible VAT Amount") * "Currency Factor" / "Job Quantity" = (50 + 100) * 0.5 / 2 = 37.5
        Assert.AreEqual(
            Round(JobJnlLine."Unit Cost (LCY)"),
            Round(GenJnlLine."Job Total Cost (LCY)" / GenJnlLine."Job Quantity") +
            Round(Round(GenJnlLine."Non-Deductible VAT Amount" * GenJnlLine."Job Currency Factor") / GenJnlLine."Job Quantity"),
            'Unit Cost (LCY) with Non-Deductible VAT amount is not correct in Job Journal Line');
        // [THEN] JobJnlLine contains "Total Unit Cost" = ("Job Unit Cost" + "Non-Deductible VAT Amount") * "Currency Factor" = (50 + 100) * 0.5 = 75
        Assert.AreEqual(
            Round(JobJnlLine."Total Cost (LCY)"),
            Round(GenJnlLine."Job Total Cost (LCY)" + Round(GenJnlLine."Non-Deductible VAT Amount" * GenJnlLine."Job Currency Factor")),
            'Total Cost (LCY) with Non-Deductible VAT amount is not correct in Job Journal Line');
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Non Ded. VAT Misc.");
        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Non Ded. VAT Misc.");
        LibraryNonDeductibleVAT.EnableNonDeductibleVAT();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibrarySetupStorage.Save(Database::"VAT Setup");
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Non Ded. VAT Misc.");
    end;

    local procedure CreatePurchaseInvoiceTFS384393(var PurchaseHeader: Record "Purchase Header"; VATPostingSetup: Record "VAT Posting Setup")
    var
        DimensionValue: array[7] of Record "Dimension Value";
        VendorNo: Code[20];
        GLAccountNo: Code[20];
        GeneralPostingType: Enum "General Posting Type";
    begin
        VendorNo := LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group");
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);

        GLAccountNo := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GeneralPostingType::Purchase);
        Create7DimensionValues(DimensionValue);
        CreatePurchaseLineGL(PurchaseHeader, GLAccountNo, 1.42, DimensionValue[1]);
        CreatePurchaseLineGL(PurchaseHeader, GLAccountNo, 88.97, DimensionValue[2]);
        CreatePurchaseLineGL(PurchaseHeader, GLAccountNo, 48.94, DimensionValue[3]);
        CreatePurchaseLineGL(PurchaseHeader, GLAccountNo, 90.44, DimensionValue[3]);
        CreatePurchaseLineGL(PurchaseHeader, GLAccountNo, 60.27, DimensionValue[4]);
        CreatePurchaseLineGL(PurchaseHeader, GLAccountNo, 52.29, DimensionValue[3]);
        CreatePurchaseLineGL(PurchaseHeader, GLAccountNo, 64.12, DimensionValue[1]);
        CreatePurchaseLineGL(PurchaseHeader, GLAccountNo, 107.87, DimensionValue[5]);
        CreatePurchaseLineGL(PurchaseHeader, GLAccountNo, 48.03, DimensionValue[6]);
        CreatePurchaseLineGL(PurchaseHeader, GLAccountNo, 219.05, DimensionValue[5]);
        CreatePurchaseLineGL(PurchaseHeader, GLAccountNo, 132.73, DimensionValue[2]);
        CreatePurchaseLineGL(PurchaseHeader, GLAccountNo, 50.82, DimensionValue[2]);
        CreatePurchaseLineGL(PurchaseHeader, GLAccountNo, 68.85, DimensionValue[4]);
        CreatePurchaseLineGL(PurchaseHeader, GLAccountNo, 222.95, DimensionValue[5]);
        CreatePurchaseLineGL(PurchaseHeader, GLAccountNo, 58.9, DimensionValue[7]);
        CreatePurchaseLineGL(PurchaseHeader, GLAccountNo, 65.2, DimensionValue[2]);
        CreatePurchaseLineGL(PurchaseHeader, GLAccountNo, 232.63, DimensionValue[5]);
        CreatePurchaseLineGL(PurchaseHeader, GLAccountNo, 62.23, DimensionValue[1]);
    end;

    local procedure CreatePurchaseInvoiceTFS384393_2(var PurchaseHeader: Record "Purchase Header"; VATPostingSetup: Record "VAT Posting Setup")
    var
        DimensionValue: array[7] of Record "Dimension Value";
        VendorNo: Code[20];
        GLAccountNo: Code[20];
        GeneralPostingType: Enum "General Posting Type";
        i: Integer;
    begin
        VendorNo := LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group");
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        GLAccountNo := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GeneralPostingType::Purchase);
        Create7DimensionValues(DimensionValue);
        for i := 1 to 6 do
            CreatePurchaseLineGL(PurchaseHeader, GLAccountNo, 151.53, DimensionValue[i]);
    end;

    local procedure CreateGLAccount(GenProdPostingGroup: Code[20]; VATProductPostingGroup: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        GLAccount.Validate("VAT Prod. Posting Group", VATProductPostingGroup);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateFixedAssetWithDepreciationStartDate(VATPostingSetup: Record "VAT Posting Setup"): Code[20]
    var
        GeneralPostingSetup: Record "General Posting Setup";
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        FixedAsset.Get(CreateFixedAsset(GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group"));
        FADepreciationBook.SetRange("FA No.", FixedAsset."No.");
        FADepreciationBook.FindFirst();
        FADepreciationBook.Validate("Depreciation Starting Date", WorkDate() - LibraryRandom.RandInt(10));
        FADepreciationBook.Validate("No. of Depreciation Years", 1);
        FADepreciationBook.Modify(true);
        exit(FixedAsset."No.");
    end;

    local procedure CreateFixedAsset(GenProdPostingGroup: Code[20]; VATProductPostingGroup: Code[20]): Code[20]
    var
        FASetup: Record "FA Setup";
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        LibraryFA.CreateFixedAsset(FixedAsset);
        FASetup.Get();
        LibraryFA.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FASetup."Default Depr. Book");
        FADepreciationBook.Validate("FA Posting Group", FindFAPostingGroup(GenProdPostingGroup, VATProductPostingGroup));
        FADepreciationBook.Modify(true);
        exit(FixedAsset."No.");
    end;

    local procedure CreatePurchaseInvoice(var PurchaseHeader: Record "Purchase Header"; VATPostingSetup: Record "VAT Posting Setup"): Decimal
    var
        PurchaseLine: Record "Purchase Line";
    begin
        exit(CreatePurchaseInvoice(PurchaseHeader, PurchaseLine, VATPostingSetup));
    end;

    local procedure CreatePurchaseInvoice(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; VATPostingSetup: Record "VAT Posting Setup"): Decimal
    var
        GeneralPostingSetup: Record "General Posting Setup";
        CurrencyCode: Code[20];
        VendNo: Code[20];
        GLAccNo: Code[20];
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        VendNo :=
          CreateVendor(GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccNo :=
          CreateGLAccount(GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        CurrencyCode := PurchaseHeader."Currency Code";
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendNo);
        if CurrencyCode <> '' then begin
            PurchaseHeader.Validate("Currency Code", CurrencyCode);
            PurchaseHeader.Modify();
        end;
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccNo, LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(1000, 2));
        PurchaseLine.Modify(true);
        exit(PurchaseLine."Line Amount");
    end;

    local procedure CreatePurchaseInvoiceWithFixedAsset(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; VATPostingSetup: Record "VAT Posting Setup"): Decimal
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        exit(
            CreatePurchaseInvoiceWithFixedAsset(
                PurchaseHeader, PurchaseLine, VATPostingSetup,
                CreateFixedAsset(GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group")));
    end;

    local procedure CreatePurchaseInvoiceWithFixedAsset(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; VATPostingSetup: Record "VAT Posting Setup"; FANo: Code[20]): Decimal
    var
        GeneralPostingSetup: Record "General Posting Setup";
        VendNo: Code[20];
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        VendNo :=
          CreateVendor(GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendNo);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Fixed Asset", FANo, LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(1000, 2));
        PurchaseLine.Modify(true);
        exit(PurchaseLine."Line Amount");
    end;

    local procedure CreateVendor(GenBusPostingGroup: Code[20]; VATBusinessPostingGroup: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Gen. Bus. Posting Group", GenBusPostingGroup);
        Vendor.Validate("VAT Bus. Posting Group", VATBusinessPostingGroup);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreatePurchInvoiceWithDeferralAndDedVAT(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; PostingDate: Date; VATPostingSetup: Record "VAT Posting Setup"; DeferralCode: Code[10]; DirectUnitCost: Decimal)
    begin
        CreatePurchInvoiceWithDeferralAndDedVATCustom(PurchaseHeader, PurchaseLine, PostingDate, VATPostingSetup, '', DeferralCode, DirectUnitCost);
    end;

    local procedure CreatePurchInvoiceWithDeferralAndDedVAT(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; PostingDate: Date; VATPostingSetup: Record "VAT Posting Setup"; CurrencyCode: Code[10]; DeferralCode: Code[10]; DirectUnitCost: Decimal)
    begin
        CreatePurchInvoiceWithDeferralAndDedVATCustom(PurchaseHeader, PurchaseLine, PostingDate, VATPostingSetup, CurrencyCode, DeferralCode, DirectUnitCost);
    end;

    local procedure CreatePurchInvoiceWithDeferralAndDedVATCustom(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; PostingDate: Date; VATPostingSetup: Record "VAT Posting Setup"; CurrencyCode: Code[10]; DeferralCode: Code[10]; DirectUnitCost: Decimal)
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        PurchaseHeader.SetHideValidationDialog(true);
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase), 1);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Validate("Deferral Code", DeferralCode);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseLineGL(PurchaseHeader: Record "Purchase Header"; GLAccountNo: Code[20]; DirectUnitCost: Decimal; DimensionValue: Record "Dimension Value")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccountNo, 1);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Validate(
          "Dimension Set ID",
          LibraryDimension.CreateDimSet(PurchaseLine."Dimension Set ID", DimensionValue."Dimension Code", DimensionValue.Code));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateJobGLJournalLine(var GenJournalLine: Record "Gen. Journal Line"; VATPostingSetup: Record "VAT Posting Setup")
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryJob.CreateJob(Job, Customer."No.");  // Blank value for Currency Code.
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobGLJournalLine(GenJournalLine."Job Line Type"::Billable, JobTask, GenJournalLine);
        GenJournalLine.Validate("Gen. Posting Type", GenJournalLine."Gen. Posting Type"::Purchase);
        GenJournalLine.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GenJournalLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GenJournalLine.Modify(true);
    end;

    local procedure CreateJobGLJournalLine(var GenJournalLine: Record "Gen. Journal Line"; JobTask: Record "Job Task"; VATPostingSetup: Record "VAT Posting Setup")
    begin
        LibraryJob.CreateJobGLJournalLine(GenJournalLine."Job Line Type"::Billable, JobTask, GenJournalLine);
        GenJournalLine.Validate("Gen. Posting Type", GenJournalLine."Gen. Posting Type"::Purchase);
        GenJournalLine.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GenJournalLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GenJournalLine.Modify(true);
    end;

    local procedure FindFAPostingGroup(GenProdPostingGroup: Code[20]; VATProductPostingGroup: Code[20]): Code[20]
    var
        FAPostingGroup: Record "FA Posting Group";
    begin
        FAPostingGroup.FindFirst();
        FAPostingGroup.Validate("Acquisition Cost Account",
          CreateGLAccount(GenProdPostingGroup, VATProductPostingGroup));
        FAPostingGroup.Modify(true);
        exit(FAPostingGroup.Code);
    end;

    local procedure FindGLEntry(var GLEntry: Record "G/L Entry"; DocumentNo: Code[20]; GLAccNo: Code[20])
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Invoice);
        GLEntry.SetRange("G/L Account No.", GLAccNo);
        GLEntry.FindLast();
    end;

    local procedure FindVATEntry(var VATEntry: Record "VAT Entry"; DocumentNo: Code[20])
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Invoice);
        VATEntry.FindLast();
    end;

    local procedure GetPostingDate(): Date
    begin
        exit(DMY2Date(30, 6, Date2DMY(WorkDate(), 3)));
    end;

    local procedure UpdateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"): Decimal
    begin
        exit(UpdateVATPostingSetup(VATPostingSetup, "Tax Calculation Type"::"Normal VAT"));
    end;

    local procedure UpdateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATCalculationType: enum "Tax Calculation Type") DeductiblePercent: Decimal
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATCalculationType);
        DeductiblePercent := GetDeductibleVATPctFromVATPostingSetup(VATPostingSetup);
        LibraryERM.CreateGLAccount(GLAccount);
        AssignNonDeductibleVATAccount(VATPostingSetup, GLAccount."No.");
        AssignDeductibleVATPct(VATPostingSetup, LibraryRandom.RandInt(99));
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateNonDeductibleVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATCalculationType: Enum "Tax Calculation Type"; NonDeductibleGLAccount: Code[20]; DeductiblePct: Decimal)
    begin
        LibraryNonDeductibleVAT.CreatVATPostingSetupAllowedForNonDeductibleVAT(
            VATPostingSetup, VATCalculationType, LibraryRandom.RandDecInRange(10, 25, 2));
        AssignNonDeductibleVATAccount(VATPostingSetup, NonDeductibleGLAccount);
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", LibraryERM.CreateGLAccountNo());
        AssignDeductibleVATPct(VATPostingSetup, DeductiblePct);
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateVATPostingSetupWithPct(var VATPostingSetup: Record "VAT Posting Setup"; VATCalculationType: Enum "Tax Calculation Type"; VATPct: Decimal; DeductiblePct: Decimal)
    begin
        LibraryNonDeductibleVAT.CreatVATPostingSetupAllowedForNonDeductibleVAT(VATPostingSetup, VATCalculationType, VATPct);
        AssignNonDeductibleVATAccount(VATPostingSetup, LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", LibraryERM.CreateGLAccountNo());
        AssignDeductibleVATPct(VATPostingSetup, DeductiblePct);
        VATPostingSetup.Modify(true);
    end;

    local procedure Create7DimensionValues(var DimensionValue: array[7] of Record "Dimension Value")
    var
        Dimension: Record Dimension;
        i: Integer;
    begin
        LibraryDimension.CreateDimension(Dimension);
        for i := 1 to ArrayLen(DimensionValue) do
            LibraryDimension.CreateDimensionValue(DimensionValue[i], Dimension.Code);
    end;

    local procedure CreateAndPostCrMemoWithJobAndVATPostingSetup(var PurchaseLine: Record "Purchase Line"; VATPostingSetup: Record "VAT Posting Setup"): Code[20]
    var
        GeneralPostingSetup: Record "General Posting Setup";
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
    begin
        CreateJobWithJobsUtil(JobTask);
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", CreateVendor(
            GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group"));
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", CreateGLAccount(
            GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group"), LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Validate("Job No.", JobTask."Job No.");
        PurchaseLine.Validate("Job Task No.", JobTask."Job Task No.");
        PurchaseLine.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateJobWithJobsUtil(var JobTask: Record "Job Task")
    var
        Job: Record Job;
    begin
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
    end;

    local procedure GetNonDeductibleVATAccountNo(VATPostingSetup: Record "VAT Posting Setup"; PostingGLAccountNo: Code[20]): Code[20]
    begin
        if VATPostingSetup."Non-Ded. Purchase VAT Account" = '' then
            exit(PostingGLAccountNo);

        VATPostingSetup.TestField("Non-Ded. Purchase VAT Account");
        exit(VATPostingSetup."Non-Ded. Purchase VAT Account");
    end;

    local procedure GetNonDeductibleVATExpectedAmount(VATPostingSetup: Record "VAT Posting Setup"; Amount: Decimal): Decimal
    var
        NonDeductibleVATAmount: Decimal;
    begin
        NonDeductibleVATAmount := Round(Amount * VATPostingSetup."VAT %" / 100);
        NonDeductibleVATAmount := Round(NonDeductibleVATAmount * (100 - GetDeductibleVATPctFromVATPostingSetup(VATPostingSetup)) / 100);

        if VATPostingSetup."Non-Ded. Purchase VAT Account" = '' then
            exit(Amount + NonDeductibleVATAmount);

        exit(NonDeductibleVATAmount);
    end;

    local procedure GetZeroNonDeductibleVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; var NonDeductGLAccountNo: Code[20]; VATCalcType: Enum "Tax Calculation Type") DeductiblePercent: Decimal
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATCalcType);
        DeductiblePercent := GetDeductibleVATPctFromVATPostingSetup(VATPostingSetup);
        NonDeductGLAccountNo := VATPostingSetup."Non-Ded. Purchase VAT Account";
        AssignNonDeductibleVATAccount(VATPostingSetup, '');
        AssignDeductibleVATPct(VATPostingSetup, 0);
        VATPostingSetup.Modify(true);
    end;

    local procedure GetAcquisitionAccFromPurchLine(PurchLine: Record "Purchase Line"): Code[20]
    var
        FADeprBook: Record "FA Depreciation Book";
        FAPostingGroup: Record "FA Posting Group";
    begin
        FADeprBook.Get(PurchLine."No.", PurchLine."Depreciation Book Code");
        FAPostingGroup.Get(FADeprBook."FA Posting Group");
        exit(FAPostingGroup."Acquisition Cost Account");
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; GLAccNo: Code[20]; ExpectedAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        FindGLEntry(GLEntry, DocumentNo, GLAccNo);
        Assert.AreEqual(ExpectedAmount, GLEntry.Amount, IncorrectGLEntryAmtErr);
    end;

    local procedure VerifyGLAccountBalance(DocumentNo: Code[20]; GLAccNo: Code[20]; ExpectedGLAccBalance: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetCurrentKey("Transaction No.", "G/L Account No.", "Document No.", "Source Type", "Source No.");
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccNo);
        GLEntry.CalcSums(Amount);
        Assert.AreEqual(ExpectedGLAccBalance, GLEntry.Amount, IncorrectGLEntryAmtErr);
    end;

    local procedure VerifyVATEntry(DocumentNo: Code[20]; NonDeductibleBase: Decimal; NonDeductibleAmount: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        FindVATEntry(VATEntry, DocumentNo);
        VATEntry.TestField("Non-Deductible VAT Base", NonDeductibleBase);
        VATEntry.TestField("Non-Deductible VAT Amount", NonDeductibleAmount);
    end;

    local procedure VerifyFALedgEntry(DocNo: Code[20]; FANo: Code[20]; ExpectedAmount: Decimal)
    var
        FALedgEntry: Record "FA Ledger Entry";
    begin
        FALedgEntry.SetRange("FA No.", FANo);
        FALedgEntry.SetRange("Document No.", DocNo);
        FALedgEntry.CalcSums(Amount);
        FALedgEntry.TestField(Amount, ExpectedAmount);
    end;

    local procedure VerifyGLEntryDeferrals(DeferralAccountNo: Code[20]; PurchaseLine: Record "Purchase Line"; VATPostingSetup: Record "VAT Posting Setup"; DeferralTemplate: Record "Deferral Template")
    begin
        VerifyGLEntryDeferrals(DeferralAccountNo, PurchaseLine."No.", PurchaseLine.Amount, VATPostingSetup, DeferralTemplate, WorkDate());
    end;

    local procedure VerifyGLEntryDeferrals(DeferralAccountNo: Code[20]; PurchaseLine: Record "Purchase Line"; VATPostingSetup: Record "VAT Posting Setup"; DeferralTemplate: Record "Deferral Template"; PostingDate: Date)
    begin
        VerifyGLEntryDeferrals(DeferralAccountNo, PurchaseLine."No.", PurchaseLine.Amount, VATPostingSetup, DeferralTemplate, PostingDate);
    end;

    local procedure VerifyGLEntryDeferrals(DeferralAccountNo: Code[20]; PostingGLAccNo: Code[20]; Amount: Decimal; VATPostingSetup: Record "VAT Posting Setup"; DeferralTemplate: Record "Deferral Template"; PostingDate: Date)
    var
        GLEntry: Record "G/L Entry";
    begin
        // We post to "Posting G/Account" + "Non-Ded. Purchase VAT Account" = 2
        // We post 1 balancing deferral entry + period deferral entries per each = 1 + CountOfPeriod
        GLEntry.SetRange("G/L Account No.", DeferralAccountNo);
        Assert.RecordCount(GLEntry, (DeferralTemplate."No. of Periods" + 1) * 2);

        Clear(GLEntry);
        GLEntry.SetRange("G/L Account No.", GetNonDeductibleVATAccountNo(VATPostingSetup, PostingGLAccNo));
        GLEntry.SetFilter(Amount, '<%1', 0);
        GLEntry.CalcSums(Amount);
        GLEntry.TestField(Amount, -GetNonDeductibleVATExpectedAmount(VATPostingSetup, Amount));
        if VATPostingSetup."Non-Ded. Purchase VAT Account" <> '' then
            Assert.RecordCount(GLEntry, 1)
        else
            Assert.RecordCount(GLEntry, 2);

        Clear(GLEntry);
        GLEntry.SetRange("G/L Account No.", GetNonDeductibleVATAccountNo(VATPostingSetup, PostingGLAccNo));
        GLEntry.SetRange("Posting Date", PostingDate);
        GLEntry.CalcSums(Amount);
        GLEntry.TestField(Amount, 0);
        if VATPostingSetup."Non-Ded. Purchase VAT Account" <> '' then
            Assert.RecordCount(GLEntry, 2)
        else
            Assert.RecordCount(GLEntry, 4);
    end;

    local procedure VerifyGLEntriesDeferralsAmount(PurchaseLine: Record "Purchase Line"; VATPostingSetup: Record "VAT Posting Setup")
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("G/L Account No.", GetNonDeductibleVATAccountNo(VATPostingSetup, PurchaseLine."No."));
        GLEntry.SetFilter(Amount, '<%1', 0);
        GLEntry.CalcSums(Amount);
        GLEntry.TestField(Amount, -GetNonDeductibleVATExpectedAmount(VATPostingSetup, PurchaseLine.Amount));
    end;

    local procedure VerifyGLEntryFAEntryLinedPair(GLEntry: Record "G/L Entry")
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        GLEntry.TestField("FA Entry Type");
        GLEntry.TestField("FA Entry No.");
        FALedgerEntry.Get(GLEntry."FA Entry No.");
        FALedgerEntry.TestField("G/L Entry No.", GLEntry."Entry No.");
        FALedgerEntry.TestField(Amount, GLEntry.Amount);
    end;

    local procedure SetJobForPurchaseLine(var PurchaseLine: Record "Purchase Line")
    var
        Job: Record Job;
        JobTask: Record "Job Task";
    begin
        PurchaseLine.Validate("Job Line Type", "Job Line Type"::Billable);
        LibraryJob.CreateJob(Job);
        PurchaseLine.Validate("Job No.", Job."No.");
        LibraryJob.CreateJobTask(Job, JobTask);
        PurchaseLine.Validate("Job Task No.", JobTask."Job Task No.");
        PurchaseLine.Validate(Quantity, LibraryRandom.RandIntInRange(100, 200));
        PurchaseLine.Modify(true);
    end;

    local procedure TearDownLastUsedDateInPurchInvoiceNoSeries()
    var
        PurchPayablesSetup: Record "Purchases & Payables Setup";
        NoSeriesLine: Record "No. Series Line";
    begin
        PurchPayablesSetup.Get();
        NoSeriesLine.SetRange("Series Code", PurchPayablesSetup."Posted Invoice Nos.");
        NoSeriesLine.ModifyAll("Last Date Used", 0D);
    end;

    local procedure GetDeductibleVATPctFromVATPostingSetup(VATPostingSetup: Record "VAT Posting Setup"): Decimal
    begin
        exit(100 - VATPostingSetup."Non-Deductible VAT %");
    end;

    local procedure AssignDeductibleVATPct(var VATPostingSetup: Record "VAT Posting Setup"; DedVATPct: Decimal)
    begin
        LibraryNonDeductibleVAT.SetAllowNonDeductibleVATForVATPostingSetup(VATPostingSetup);
        VATPostingSetup.Validate("Non-Deductible VAT %", 100 - DedVATPct);
    end;

    local procedure AssignNonDeductibleVATAccount(var VATPostingSetup: Record "VAT Posting Setup"; GLAccNo: Code[20])
    begin
        VATPostingSetup.Validate("Non-Ded. Purchase VAT Account", GLAccNo);
    end;

    local procedure FindPurchaseInvoiceLine(var PurchInvLine: Record "Purch. Inv. Line"; PurchaseInvoiceNo: Code[20])
    begin
        PurchInvLine.SetRange("Document No.", PurchaseInvoiceNo);
        PurchInvLine.SetFilter("Direct Unit Cost", '<%1', 0);
        PurchInvLine.FindFirst();
    end;

    local procedure FindJobLedgerEntry(var JobLedgerEntry: Record "Job Ledger Entry"; PurchaseInvoiceNo: Code[20])
    begin
        JobLedgerEntry.SetRange("Document No.", PurchaseInvoiceNo);
        JobLedgerEntry.SetFilter("Unit Cost", '<%1', 0);
        JobLedgerEntry.FindFirst();
    end;

    local procedure GenerateCost(var DirectUnitCost: array[3] of Decimal)
    begin
        DirectUnitCost[1] := LibraryRandom.RandIntInRange(1000, 100);
        DirectUnitCost[2] := -LibraryRandom.RandIntInRange(100, 100);
        DirectUnitCost[3] := LibraryRandom.RandIntInRange(100, 100);
    end;

    local procedure GenerateQuantites(var Quantity: array[3] of Decimal)
    begin
        Quantity[1] := LibraryRandom.RandInt(0);
        Quantity[2] := LibraryRandom.RandInt(0);
        Quantity[3] := -LibraryRandom.RandInt(0);
    end;

    local procedure CreatePurchaseInvoiceWithProject(
        VATPostingSetup: Record "VAT Posting Setup"; GLAccountNo: Code[20];
        Cost: array[3] of Decimal; Quantity: array[3] of Decimal; JobTask: Record "Job Task"): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        GeneralPostingSetup: Record "General Posting Setup";
        i: Integer;
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryPurchase.CreatePurchHeader(
             PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
             CreateVendor(GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group"));

        for i := 1 to 3 do
            CreatePurchaseLines(PurchaseHeader, GLAccountNo, Cost[i], Quantity[i], JobTask);

        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreatePurchaseLines(
        var PurchaseHeader: Record "Purchase Header"; GLAccountNo: Code[20];
        DirectUnitCost: Decimal; Quantity: Decimal; JobTask: Record "Job Task")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccountNo, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Validate("Job No.", JobTask."Job No.");
        PurchaseLine.Validate("Job Task No.", JobTask."Job Task No.");
        PurchaseLine.Modify(true);
    end;

    local procedure CreateVendor(var Vendor: Record Vendor; VATPostingSetup: Record "VAT Posting Setup")
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        Vendor.Get(CreateVendor(GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group"));
    end;

    local procedure CreateGeneralJournalLines(
        GLAccountNo: Code[20]; Cost: array[3] of Decimal; Quantity: array[3] of Decimal;
        JobNo: Code[20]; JobTaskNo: Code[20]; DocumentNo: Code[20]; VendorNo: Code[20])
    var
        GenJournalLine: array[4] of Record "Gen. Journal Line";
        GeneralPostingSetup: Record "General Posting Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        i: Integer;
        TotalCost: Decimal;
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);

        for i := 1 to 3 do begin
            CreateGenJournalLinesWithJobNo(
                GenJournalLine[i], GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GLAccountNo, Cost[i],
                Quantity[i], JobNo, JobTaskNo, DocumentNo, GenJournalLine[i]."Account Type"::"G/L Account");
            TotalCost := TotalCost + Cost[i];
        end;

        CreateGenJournalLinesWithJobNo(
               GenJournalLine[4], GenJournalBatch."Journal Template Name", GenJournalBatch.Name, VendorNo, -TotalCost,
                0, '', '', DocumentNo, GenJournalLine[i]."Account Type"::Vendor);

        LibraryERM.PostGeneralJnlLine(GenJournalLine[4]);
    end;

    local procedure CreateGenJournalLinesWithJobNo(
        var GenJournalLine: Record "Gen. Journal Line"; JournalTemplateName: Code[10];
        JournalBatchName: Code[10]; GLAccountNo: Code[20];
        Amount: Decimal; Quantity: Decimal;
        JobNo: Code[20]; JobTaskNo: Code[20];
        DocumentNo: Code[20]; GenJournalAccountType: Enum "Gen. Journal Account Type")
    var
        GenJournalDocumentType: Enum "Gen. Journal Document Type";
    begin
        LibraryJournals.CreateGenJournalLine(
            GenJournalLine, JournalTemplateName, JournalBatchName, GenJournalDocumentType::Invoice,
            GenJournalAccountType, GLAccountNo, GenJournalAccountType::"G/L Account", '', Amount);
        GenJournalLine.Validate("Document No.", DocumentNo);
        GenJournalLine.Validate("Job No.", JobNo);
        GenJournalLine.Validate("Job Task No.", JobTaskNo);
        GenJournalLine.Validate("Job Quantity", Quantity);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateFixedAssetDepreciation(var FADepreciationBook: Record "FA Depreciation Book"; VATProdPostingGroup: Code[20]; VendorNo: code[20]; var AcquisitionCostGL: Code[20])
    var
        FASubClass: Record "FA Subclass";
        FAPostingGroup: Record "FA Posting Group";
        FixedAsset: Record "Fixed Asset";
        GLAccount: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DepreciationBook: Record "Depreciation Book";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
    begin
        DepreciationBook.Get(LibraryFixedAsset.GetDefaultDeprBook());
        LibraryFixedAsset.CreateFASubclass(FASubClass);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        FixedAsset.Validate("FA Subclass Code", FASubClass.Code);
        FixedAsset.Modify(true);
        FAPostingGroup.Get(FixedAsset."FA Posting Group");
        AcquisitionCostGL := FAPostingGroup."Acquisition Cost Account";
        if GLAccount.Get(FAPostingGroup."Acquisition Cost Account") then begin
            GLAccount.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
            GLAccount.Modify(true);
        end;
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", DepreciationBook.Code, FixedAsset."FA Posting Group");
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Fixed Asset", FixedAsset."No.", 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(100, 200, 2));
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateFADepreciationBook(var FADepreciationBook: Record "FA Depreciation Book"; No: Code[20]; DepreciationBookCode: Code[10]; FAPostingGroup: Code[20])
    var
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
    begin
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, No, DepreciationBookCode);
        UpdateDateFADepreciationBook(FADepreciationBook, DepreciationBookCode);
        FADepreciationBook.Validate("FA Posting Group", FAPostingGroup);
        FADepreciationBook.Modify(true);
    end;

    local procedure UpdateDateFADepreciationBook(var FADepreciationBook: Record "FA Depreciation Book"; DepreciationBookCode: Code[10])
    begin
        FADepreciationBook.Validate("Depreciation Book Code", DepreciationBookCode);
        FADepreciationBook.Validate("Depreciation Starting Date", WorkDate());
        FADepreciationBook.Validate("Depreciation Ending Date", CalculateDepreciationDateAfterOneYear());
        FADepreciationBook.Modify(true);
    end;

    local procedure CalculateDepreciationDateAfterOneYear(): Date
    begin
        exit(CalcDate('<1Y>', WorkDate()));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;
}
