codeunit 144007 "ERM VAT Reinstatement"
{
    // // [FEATURE] [VAT Reinstatement]
    // RegF 24897 VAT reinstatement

    TestPermissions = NonRestrictive;
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        GLSetup: Record "General Ledger Setup";
        ReinstmtVATPostingSetup: Record "VAT Posting Setup";
        DimMgt: Codeunit DimensionManagement;
        UnexpectedErr: Label 'Unexpected error.';
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        Assert: Codeunit Assert;
        DimErr: Label 'Dimension is not found';
        DimValueErr: Label 'Incorrect dimension value';
        PurchVATLedgerErr: Label 'VAT reinstatement must not affect on purchase VAT ledger';
        SalesVATLedgerErr: Label 'VAT reinstatement does not appear in the sales VAT ledger';
        VATEntriesQtyErr: Label 'Incorrect number of VAT entries';
        PostingDateErr: Label 'The Posting Date must not be less than';
        ZeroAmountErr: Label 'Amount must have a value';
        OverLimitAmountErr: Label 'The Amount must not be more than';
        VATAlreadyReinstatedErr: Label 'VAT has been already reinstated';
        ConfirmMsg: Label 'Do you want to post';
        IncorrectConfirmErr: Label 'Incorrect confirm dialog opened.';
        JnlLinePostedMsg: Label 'The journal lines were successfully posted.';
        VATReinstLinesCreatedMsg: Label 'Lines have been successfully created in the VAT reinstatement journal.';
        IsInitialized: Boolean;
        VATSettlType: Option ,Purchase,Sale,"Fixed Asset","Future Expense";
        DepCalcMsg: Label '1 fixed asset G/L journal lines were created.';
        AllowedvaluesFilterLbl: Label 'Allowed Values Filter';

    [Test]
    [HandlerFunctions('HNDLMessages,HndlConfirm')]
    [Scope('OnPrem')]
    procedure VATLedgerGeneration()
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        VATLedgerNo: Code[20];
        GLAccountNo: Code[20];
        VATLedgerStartDate: Date;
        VATLedgerEndDate: Date;
    begin
        Initialize();
        Vendor.Get(
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(ReinstmtVATPostingSetup."VAT Bus. Posting Group"));
        GLAccountNo := LibraryERM.CreateGLAccountWithVATPostingSetup(ReinstmtVATPostingSetup, "General Posting Type"::" ");
        LibrarySales.CreateCustomer(Customer);
        Customer."Vendor No." := Vendor."No.";
        Customer.Modify();

        CreatePostPurchInvoice(Vendor."No.", GLAccountNo, CalcDate('<-CM>', WorkDate()));
        CreatePostVATSettlementJnlLine(Vendor."No.", CalcDate('<CM>', WorkDate()));
        CreatePostVATReinstatementJnlLine(Vendor."No.", CalcDate('<CM+1D>', WorkDate()));

        VATLedgerStartDate := CalcDate('<-CM+1M>', WorkDate());
        VATLedgerEndDate := CalcDate('<CM>', VATLedgerStartDate);
        VATLedgerNo :=
          LibraryPurchase.CreatePurchaseVATLedger(VATLedgerStartDate, VATLedgerEndDate, Vendor."No.", false, false);
        VerifyPurchVATLedgLineDoesNotExist(VATLedgerNo);
        VATLedgerNo :=
          LibrarySales.CreateSalesVATLedger(VATLedgerStartDate, VATLedgerEndDate, Customer."No.");
        VerifySalesVATLedgLineExists(Vendor."No.", VATLedgerNo);
    end;

    [Test]
    [HandlerFunctions('HNDLMessages,HndlForm,HndlConfirm')]
    [Scope('OnPrem')]
    procedure VATReinstatementFromFAWriteOff()
    var
        Vendor: Record Vendor;
        GenJnlLine: Record "Gen. Journal Line";
        FixedAsset: array[3] of Record "Fixed Asset";
    begin
        Initialize();
        Vendor.Get(
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(ReinstmtVATPostingSetup."VAT Bus. Posting Group"));
        FAWriteOffScenario(FixedAsset, Vendor);
        CreatePostVATSettlementForFA(FixedAsset, WorkDate());
        ClearVATReinstatementJnlLinesByObjNo(GenJnlLine, FixedAsset[1]."No.");
        CreatePostVATReinstatementFromFAWriteOff(GenJnlLine, CalcDate('<CM+2M>', WorkDate()));
        VerifyVATEntriesOfFA(FixedAsset);
    end;

    [Test]
    [HandlerFunctions('HNDLMessages,HndlForm,HndlConfirm')]
    [Scope('OnPrem')]
    procedure VATReinstatementSuggestDocuments()
    var
        Vendor: Record Vendor;
        VATEntry: Record "VAT Entry";
        GLAccountNo: Code[20];
    begin
        Initialize();
        Vendor.Get(
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(ReinstmtVATPostingSetup."VAT Bus. Posting Group"));
        GLAccountNo := LibraryERM.CreateGLAccountWithVATPostingSetup(ReinstmtVATPostingSetup, "General Posting Type"::" ");
        CreatePostPurchInvoice(Vendor."No.", GLAccountNo, CalcDate('<CM+1D>', WorkDate()));
        CreatePostVATSettlementJnlLine(Vendor."No.", CalcDate('<CM+2D>', WorkDate()));
        CreateVATReinstJnlLineBySuggestDocuments(VATEntry, Vendor."No.", CalcDate('<CM+2D>', WorkDate()));
        VerifyReinstatementVATEntry(Vendor."No.");
    end;

    [Test]
    [HandlerFunctions('HNDLMessages,HndlConfirm,HndlForm,HndlConfirm')]
    [Scope('OnPrem')]
    procedure UT_VATReinstatementDim()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        VATEntry: Record "VAT Entry";
        DocNo: array[2] of Code[20];
        DimCode: array[2] of Code[20];
        DimValueCode: array[3] of Code[20];
        GLAccountNo: Code[20];
    begin
        Initialize();
        Vendor.Get(
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(ReinstmtVATPostingSetup."VAT Bus. Posting Group"));
        GLAccountNo := LibraryERM.CreateGLAccountWithVATPostingSetup(ReinstmtVATPostingSetup, "General Posting Type"::" ");
        SetupDimensionCodes(DimCode, DimValueCode);
        CreatePostPurchInvoicesWithDim(Vendor."No.", GLAccountNo, DimCode, DimValueCode);
        CreatePostVATSettlJnlLineForUnrealVATEntries(Vendor."No.", WorkDate());
        ClearVATReinstatementJnlLinesByVendNo(GenJournalLine, VATEntry, Vendor."No.");
        CreateVATReinstJnlLineBySuggestDocuments(VATEntry, Vendor."No.", VATEntry."Posting Date");
        FindDocNosFromGenJnlLine(DocNo, GenJournalLine, Vendor."No.");
        LibraryERM.PostVATReinstatementJournal(GenJournalLine);
        VerifyDimensionSetIDInGLEntry(DocNo, DimCode, DimValueCode);
    end;

    [Test]
    [HandlerFunctions('HNDLMessages,HndlConfirm')]
    [Scope('OnPrem')]
    procedure UT_VATReinstJnlLine_PostingDate()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VATEntry: Record "VAT Entry";
        Vendor: Record Vendor;
        GLAccountNo: Code[20];
        VATReinsDate: Date;
        VATSetlDate: Date;
    begin
        Initialize();
        Vendor.Get(
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(ReinstmtVATPostingSetup."VAT Bus. Posting Group"));
        GLAccountNo := LibraryERM.CreateGLAccountWithVATPostingSetup(ReinstmtVATPostingSetup, "General Posting Type"::" ");

        VATSetlDate := CalcDate('<CM+1D>', WorkDate());
        VATReinsDate := CalcDate('<CM+1M+1D>', WorkDate());
        CreatePostPurchInvoice(Vendor."No.", GLAccountNo, VATSetlDate);
        CreatePostVATSettlJnlLineForUnrealVATEntries(Vendor."No.", VATSetlDate);
        ClearVATReinstatementJnlLinesByVendNo(GenJournalLine, VATEntry, Vendor."No.");
        LibraryERM.CreateVATReinstatementJnlLine(GenJournalLine, VATEntry."Entry No.", VATReinsDate, 1000, false);
        asserterror
          GenJournalLine.Validate("Posting Date", WorkDate());
        Assert.ExpectedError(PostingDateErr);
    end;

    [Test]
    [HandlerFunctions('HNDLMessages,HndlConfirm')]
    [Scope('OnPrem')]
    procedure UT_VATReinstJnlLine_ZeroAmount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VATEntry: Record "VAT Entry";
        VATReinsDate: Date;
    begin
        CheckScenarioSetup(GenJournalLine, VATEntry, VATReinsDate);
        LibraryERM.CreateVATReinstatementJnlLine(GenJournalLine, VATEntry."Entry No.", VATReinsDate, 0, false);
        asserterror
          LibraryERM.PostVATReinstatementJournal(GenJournalLine);
        Assert.ExpectedError(ZeroAmountErr);
    end;

    [Test]
    [HandlerFunctions('HNDLMessages,HndlConfirm')]
    [Scope('OnPrem')]
    procedure UT_VATReinstJnlLine_AmountGreaterThanAllowed()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VATEntry: Record "VAT Entry";
        VATReinsDate: Date;
    begin
        CheckScenarioSetup(GenJournalLine, VATEntry, VATReinsDate);
        LibraryERM.CreateVATReinstatementJnlLine(GenJournalLine, VATEntry."Entry No.", VATReinsDate, 0, false);
        asserterror
          GenJournalLine.Validate(Amount, VATEntry.Amount * 1.3);
        Assert.ExpectedError(OverLimitAmountErr);
    end;

    [Test]
    [HandlerFunctions('HNDLMessages,HndlConfirm')]
    [Scope('OnPrem')]
    procedure UT_VATReinstJnlLine_TotAmtOfTwoLinesGreatreThanAllowed()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VATEntry: Record "VAT Entry";
        VATReinsDate: Date;
        HalfAmount: Decimal;
    begin
        CheckScenarioSetup(GenJournalLine, VATEntry, VATReinsDate);
        HalfAmount := VATEntry.Amount / 2;
        LibraryERM.CreateVATReinstatementJnlLine(GenJournalLine, VATEntry."Entry No.", VATReinsDate, HalfAmount, false);
        LibraryERM.CreateVATReinstatementJnlLine(GenJournalLine, VATEntry."Entry No.", VATReinsDate, HalfAmount * 1.3, false);
        asserterror
          LibraryERM.PostVATReinstatementJournal(GenJournalLine);
        Assert.ExpectedError(OverLimitAmountErr);
    end;

    [Test]
    [HandlerFunctions('HNDLMessages,HndlConfirm')]
    [Scope('OnPrem')]
    procedure UT_VATReinstJnlLine_PostAlreadyReinstatedVAT()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VATEntry: Record "VAT Entry";
        VATReinsDate: Date;
        LineNo: array[2] of Integer;
    begin
        CheckScenarioSetup(GenJournalLine, VATEntry, VATReinsDate);
        LibraryERM.CreateVATReinstatementJnlLine(GenJournalLine, VATEntry."Entry No.", VATReinsDate, VATEntry.Amount, false);
        LineNo[1] := GenJournalLine."Line No.";
        LibraryERM.CreateVATReinstatementJnlLine(
          GenJournalLine, VATEntry."Entry No.", VATReinsDate, LibraryRandom.RandDec(100, 2), false);
        LineNo[2] := GenJournalLine."Line No.";
        GenJournalLine.SetRange("Line No.", LineNo[1]);
        LibraryERM.PostVATReinstatementJournal(GenJournalLine);
        GenJournalLine.SetRange("Line No.", LineNo[2]);
        asserterror
          LibraryERM.PostVATReinstatementJournal(GenJournalLine);
        Assert.ExpectedError(VATAlreadyReinstatedErr);
    end;

    [Test]
    [HandlerFunctions('HndlConfirm,HNDLMessages,HndlForm')]
    [Scope('OnPrem')]
    procedure FullVATReinstatement()
    var
        Vendor: Record Vendor;
        VATPostingSetup: Record "VAT Posting Setup";
        VATEntry: Record "VAT Entry";
        GLAccNo: Code[20];
    begin
        // [FEATURE] [Full VAT]
        // [SCENARIO 363211] Reinstatement of Full VAT

        Initialize();
        // [GIVEN] Posted Purchase Invoice with Full VAT
        LibraryERM.CreateReinstmtVATPostingSetup(VATPostingSetup);
        Vendor.Get(
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        GLAccNo := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, "General Posting Type"::" ");
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Full VAT");
        VATPostingSetup.Validate("Purchase VAT Account", GLAccNo);
        VATPostingSetup.Modify(true);
        // SetFullVATPostingSetup(
        // VATPostingSetup,Vendor."VAT Bus. Posting Group",GLAccNo);
        CreatePostPurchInvoice(
          Vendor."No.", VATPostingSetup."Purchase VAT Account", CalcDate('<-CM>', WorkDate()));
        // [GIVEN] Posted VAT Settlement
        CreatePostVATSettlementJnlLine(Vendor."No.", CalcDate('<CM>', WorkDate()));
        // [WHEN] Run "Suggest Document" for VAT Reinstatement
        CreateVATReinstJnlLineBySuggestDocuments(VATEntry, Vendor."No.", CalcDate('<CM+1D>', WorkDate()));
        // [THEN] "Reinstatement VAT Entry No." of generated General Journal Line is equal to Full VAT Entry No.
        VerifyReinstatementVATEntry(Vendor."No.");
    end;

    [Test]
    [HandlerFunctions('HndlConfirm,HNDLMessages,HndlForm')]
    [Scope('OnPrem')]
    procedure CreditMemoVATReinstatement()
    var
        Vendor: Record Vendor;
        VATEntry: Record "VAT Entry";
        GLAccNo: Code[20];
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO 363236] Reinstatement of Credit Memo

        Initialize();
        // [GIVEN] Posted Purchase Credit Memo
        Vendor.Get(
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(ReinstmtVATPostingSetup."VAT Bus. Posting Group"));
        GLAccNo := LibraryERM.CreateGLAccountWithVATPostingSetup(ReinstmtVATPostingSetup, "General Posting Type"::" ");
        CreatePostPurchCrMemo(Vendor."No.", GLAccNo, CalcDate('<-CM>', WorkDate()));
        // [GIVEN] Posted VAT Settlement
        CreatePostVATSettlementJnlLine(Vendor."No.", CalcDate('<CM>', WorkDate()));
        // [GIVEN] Run "Suggest Document" for VAT Reinstatement
        CreateVATReinstJnlLineBySuggestDocuments(VATEntry, Vendor."No.", CalcDate('<CM+1D>', WorkDate()));
        // [THEN] "Reinstatement VAT Entry No." of generated General Journal Line is equal to Full VAT Entry No.
        VerifyReinstatementVATEntry(Vendor."No.");
    end;

    [Test]
    [HandlerFunctions('HndlForm')]
    [Scope('OnPrem')]
    procedure PurchIncrPrepmtDiffDebitCreditVATReinstatement()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJnlLine: Record "Gen. Journal Line";
        VATEntry: Record "VAT Entry";
        OldCancelPrepmtAdjmtInTA: Boolean;
        Factor: Decimal;
    begin
        // [FEATURE] [Prepayment] [Cancel Prepmt. Adjmt. in TA] [G/L Correspondence]
        // [SCENARIO 363276] G/L Correspondence Entry for Prepmt. Diff. VAT Reinstatement posted with Debit Purch. VAT Unreal Acc. and Credit Purch VAT Acc. when FCY increased

        OldCancelPrepmtAdjmtInTA := UpdateCancelPrepmtAdjmtInTA(true);
        Factor := 3;
        // [GIVEN] Posted Prepmt. Diff. VAT Settlement Line with "Initial VAT Entry No." = "VAT Entry No." of applied invoice
        SetupPrepmtDiffDebitCreditVATReinstatementScenario(VATPostingSetup, GenJnlLine, Factor);

        // [WHEN] Post VAT Reinstatement for Prepmt. Diff.
        PostVATReinstJnlLineBySuggestDocuments(VATEntry, VATPostingSetup, GenJnlLine);

        // [THEN] G/L Corr. Entry posted where Debit Acc. = "Purch. VAT Unreal Acc.", Credit Acc. = "Purch. VAT Acc." and Amount = -Prepmt. Diff. VAT Entry Amount
        VerifyVATReinstatementGLCorrEntry(
          VATPostingSetup, FindVATReinstatementEntry(GenJnlLine));

        // Tear Down
        UpdateCancelPrepmtAdjmtInTA(OldCancelPrepmtAdjmtInTA);
    end;

    [Test]
    [HandlerFunctions('HndlForm')]
    [Scope('OnPrem')]
    procedure PurchDecrPrepmtDiffDebitCreditVATReinstatement()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJnlLine: Record "Gen. Journal Line";
        VATEntry: Record "VAT Entry";
        OldCancelPrepmtAdjmtInTA: Boolean;
        Factor: Decimal;
    begin
        // [FEATURE] [Prepayment] [Cancel Prepmt. Adjmt. in TA] [G/L Correspondence]
        // [SCENARIO 363276] G/L Correspondence Entry for Prepmt. Diff. VAT Reinstatement posted with Debit Purch. VAT Unreal Acc. and Credit Purch VAT Acc. when FCY decreased

        OldCancelPrepmtAdjmtInTA := UpdateCancelPrepmtAdjmtInTA(true);
        Factor := 1 / 3;
        // [GIVEN] Posted Prepmt. Diff. VAT Settlement with "Initial VAT Entry No." = "VAT Entry No." of applied invoice
        SetupPrepmtDiffDebitCreditVATReinstatementScenario(VATPostingSetup, GenJnlLine, Factor);

        // [WHEN] Post VAT Reinstatement for Prepmt. Diff.
        PostVATReinstJnlLineBySuggestDocuments(VATEntry, VATPostingSetup, GenJnlLine);

        // [THEN] G/L Corr. Entry posted where Debit Acc. = "Purch. VAT Unreal Acc.", Credit Acc. = "Purch. VAT Acc." and Amount = -Prepmt. Diff. VAT Entry Amount
        VerifyVATReinstatementGLCorrEntry(
          VATPostingSetup, FindVATReinstatementEntry(GenJnlLine));

        // Tear Down
        UpdateCancelPrepmtAdjmtInTA(OldCancelPrepmtAdjmtInTA);
    end;

    [Test]
    [HandlerFunctions('HndlForm')]
    [Scope('OnPrem')]
    procedure PurchIncrPrepmtDiffDebitCreditVATReinstatementStorno()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJnlLine: Record "Gen. Journal Line";
        VATEntry: Record "VAT Entry";
        OldCancelPrepmtAdjmtInTA: Boolean;
        OldRedStornoVATReinstatement: Boolean;
        Factor: Decimal;
    begin
        // [FEATURE] [Prepayment] [Cancel Prepmt. Adjmt. in TA] [G/L Correspondence] [Red Storno VAT Reinstatament]
        // [SCENARIO 363276] G/L Correspondence Entry for Prepmt. Diff. VAT Reinstatement posted with Debit Purch VAT Acc. and Credit Purch. VAT Unreal Acc. when FCY increased and Red Storno is on

        OldCancelPrepmtAdjmtInTA := UpdateCancelPrepmtAdjmtInTA(true);
        OldRedStornoVATReinstatement := UpdateRedStornoVATReinstatementInGLSetup(true);
        Factor := 3;
        // [GIVEN] Posted Prepmt. Diff. VAT Settlement with "Initial VAT Entry No." = "VAT Entry No." of applied invoice
        SetupPrepmtDiffDebitCreditVATReinstatementScenario(VATPostingSetup, GenJnlLine, Factor);

        // [WHEN] Post VAT Reinstatement for Prepmt. Diff.
        PostVATReinstJnlLineBySuggestDocuments(VATEntry, VATPostingSetup, GenJnlLine);

        // [THEN] G/L Corr. Entry posted where Debit Acc. = "Purch. VAT Acc.", Credit Acc. = "Purch. VAT Unreal Acc." and Amount = Prepmt. Diff. VAT Entry Amount
        VerifyVATReinstatementGLCorrEntryRedStorno(
          VATPostingSetup, FindVATReinstatementEntry(GenJnlLine));

        // Tear Down
        UpdateCancelPrepmtAdjmtInTA(OldCancelPrepmtAdjmtInTA);
        UpdateRedStornoVATReinstatementInGLSetup(OldRedStornoVATReinstatement);
    end;

    [Test]
    [HandlerFunctions('HndlForm')]
    [Scope('OnPrem')]
    procedure PurchDecrPrepmtDiffDebitCreditVATReinstatementStorno()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJnlLine: Record "Gen. Journal Line";
        VATEntry: Record "VAT Entry";
        OldCancelPrepmtAdjmtInTA: Boolean;
        OldRedStornoVATReinstatement: Boolean;
        Factor: Decimal;
    begin
        // [FEATURE] [Prepayment] [Cancel Prepmt. Adjmt. in TA] [G/L Correspondence] [Red Storno VAT Reinstatament]
        // [SCENARIO 363276] G/L Correspondence Entry for Prepmt. Diff. VAT Reinstatement posted with Debit Purch VAT Acc. and Credit Purch. VAT Unreal Acc. when FCY decreased and Red Storno is on

        OldCancelPrepmtAdjmtInTA := UpdateCancelPrepmtAdjmtInTA(true);
        OldRedStornoVATReinstatement := UpdateRedStornoVATReinstatementInGLSetup(true);
        Factor := 1 / 3;
        // [GIVEN] Posted Prepmt. Diff. VAT Settlement with "Initial VAT Entry No." = "VAT Entry No." of applied invoice
        SetupPrepmtDiffDebitCreditVATReinstatementScenario(VATPostingSetup, GenJnlLine, Factor);

        // [WHEN] Post VAT Reinstatement for Prepmt. Diff.
        PostVATReinstJnlLineBySuggestDocuments(VATEntry, VATPostingSetup, GenJnlLine);

        // [THEN] G/L Corr. Entry posted where Debit Acc. = "Purch. VAT Acc.", Credit Acc. = "Purch. VAT Unreal Acc." and Amount = Prepmt. Diff. VAT Entry Amount
        VerifyVATReinstatementGLCorrEntryRedStorno(
          VATPostingSetup, FindVATReinstatementEntry(GenJnlLine));

        // Tear Down
        UpdateCancelPrepmtAdjmtInTA(OldCancelPrepmtAdjmtInTA);
        UpdateRedStornoVATReinstatementInGLSetup(OldRedStornoVATReinstatement);
    end;

    [Test]
    [HandlerFunctions('HNDLMessages,HndlForm,HndlConfirm')]
    [Scope('OnPrem')]
    procedure ReinstatedVATEntryNotIncludedIntoVATReinstatementCalc()
    var
        Vendor: Record Vendor;
        VATEntry: Record "VAT Entry";
        GLAccountNo: Code[20];
        VATPostingDate: Date;
        ReinstatedVATEntryNo: Integer;
    begin
        // [SCENARIO 364285] VAT Entry which is already reinstated not included into VAT Reinstatement calculation

        // [GIVEN] Posted purchase invoice
        Initialize();
        Vendor.Get(
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(ReinstmtVATPostingSetup."VAT Bus. Posting Group"));
        GLAccountNo := LibraryERM.CreateGLAccountWithVATPostingSetup(ReinstmtVATPostingSetup, "General Posting Type"::" ");
        CreatePostPurchInvoice(Vendor."No.", GLAccountNo, CalcDate('<1D>', WorkDate()));
        // [GIVEN] Posted VAT Settlement
        VATPostingDate := CalcDate('<2D>', WorkDate());
        CreatePostVATSettlementJnlLine(Vendor."No.", VATPostingDate);
        // [GIVEN] Posted VAT Reinstatement with Entry No. = "X"
        CreateVATReinstJnlLineBySuggestDocuments(VATEntry, Vendor."No.", VATPostingDate);
        ReinstatedVATEntryNo := VATEntry."Entry No.";
        PostVATReinstatementJournalByVendor(Vendor."No.");
        // [GIVEN] Posted VAT Settlement
        CreatePostVATSettlementJnlLine(Vendor."No.", VATPostingDate);

        // [WHEN] Create General Journal Line for VAT Reinstatement
        CreateVATReinstJnlLineBySuggestDocuments(VATEntry, Vendor."No.", VATPostingDate);

        // [THEN] General Journal Line with "Reinstatement VAT Entry No." = "X" does not exist
        VerifyGenJnlLineWithReinstVATEntryNoDoesNotExist(Vendor."No.", ReinstatedVATEntryNo);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        if IsInitialized then
            exit;

        LibraryERM.CreateReinstmtVATPostingSetup(ReinstmtVATPostingSetup);
        LibraryERMCountryData.UpdateVATPostingSetup();
        LibraryERMCountryData.UpdateLocalData();
        IsInitialized := true;
        Commit();
    end;

    local procedure SetupPrepmtDiffDebitCreditVATReinstatementScenario(var VATPostingSetup: Record "VAT Posting Setup"; var GenJnlLine: Record "Gen. Journal Line"; Factor: Decimal)
    var
        Vendor: Record Vendor;
        PurchHeader: Record "Purchase Header";
        VATEntry: Record "VAT Entry";
        GenJnlPostBatch: Codeunit "Gen. Jnl.-Post Batch";
        CurrencyCode: Code[10];
        InvNo: Code[20];
        PrepmtNo: Code[20];
        GLAccNo: Code[20];
        InvPostingDate: Date;
        PrepmtPostingDate: Date;
        TotalInvAmount: Decimal;
    begin
        // Prepayment with FCY applied to Invoice with FCY and different posting date
        Initialize();
        Vendor.Get(
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(ReinstmtVATPostingSetup."VAT Bus. Posting Group"));
        GLAccNo := LibraryERM.CreateGLAccountWithVATPostingSetup(ReinstmtVATPostingSetup, "General Posting Type"::" ");

        GetVATPostingSetup(VATPostingSetup, Vendor."VAT Bus. Posting Group", GLAccNo);
        SetupPostingDateAndCurrExchRates(InvPostingDate, PrepmtPostingDate, CurrencyCode, Factor);
        TotalInvAmount :=
          CreateReleasePurchInvoiceWithCurrency(PurchHeader, InvPostingDate, Vendor."No.", GLAccNo, CurrencyCode);
        PrepmtNo :=
          CreatePostPrepaymentWithCurrency(PrepmtPostingDate, CurrencyCode,
            GenJnlLine."Account Type"::Vendor, PurchHeader."Pay-to Vendor No.", TotalInvAmount, PurchHeader."No.");
        InvNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);
        ApplyPurchPrepmtToInv(PrepmtNo, InvNo);
        // Posted initial VAT Settlement Entry No. = "X"
        SuggestVATSettlement(InvNo, VATPostingSetup, GenJnlLine, InvPostingDate);
        UpdateVATSettlmentJnlLineDocNo(GenJnlLine);
        GenJnlLine.SetRange("Prepmt. Diff.", false);
        GenJnlLine.FindFirst();
        GenJnlPostBatch.VATSettlement(GenJnlLine);

        // Prepmt. Diff. VAT Settlement Jounrnal Line with "Initial VAT Entry No." = "X"
        GenJnlLine.SetRange("Prepmt. Diff.", true);
        GenJnlLine.FindFirst();
        GenJnlLine.Validate("Initial VAT Entry No.", FindVATSettlementVATEntry(GenJnlLine, false, VATEntry.Type::Purchase));
        GenJnlLine.Modify(true);

        // Post Prepmt. Diff. VAT Settlement Journal Line
        GenJnlPostBatch.VATSettlement(GenJnlLine);
    end;

    local procedure SetupDimensionCodes(var DimCode: array[2] of Code[20]; var DimValueCode: array[3] of Code[20])
    var
        Dimension: Record Dimension;
        DimValue: Record "Dimension Value";
        i: Integer;
    begin
        LibraryDimension.FindDimension(Dimension);
        DimCode[1] := Dimension.Code;
        for i := 1 to 2 do begin
            LibraryDimension.CreateDimensionValue(DimValue, Dimension.Code);
            DimValueCode[i] := DimValue.Code;
        end;

        Dimension.Next();
        DimCode[2] := Dimension.Code;
        LibraryDimension.CreateDimensionValue(DimValue, Dimension.Code);
        DimValueCode[3] := DimValue.Code;
    end;

    local procedure SetupPostingDateAndCurrExchRates(var InvPostingDate: Date; var PrepmtPostingDate: Date; var CurrencyCode: Code[10]; Factor: Decimal)
    var
        Currency: Record Currency;
        InvExchRateAmount: Decimal;
        PrepmtExchRateAmount: Decimal;
    begin
        PrepmtPostingDate := WorkDate();
        PrepmtExchRateAmount := LibraryRandom.RandInt(100);
        InvPostingDate := CalcDate('<1M>', WorkDate());
        InvExchRateAmount := PrepmtExchRateAmount * Factor;
        LibraryERM.CreateCurrency(Currency);
        Currency.Validate("Purch. PD Losses Acc. (TA)", LibraryERM.CreateGLAccountNo());
        Currency.Validate("Sales PD Losses Acc. (TA)", LibraryERM.CreateGLAccountNo());
        Currency.Validate("PD Bal. Gain/Loss Acc. (TA)", LibraryERM.CreateGLAccountNo());
        Currency.Modify(true);
        LibraryERM.CreateExchangeRate(
          Currency.Code, InvPostingDate, InvExchRateAmount, InvExchRateAmount);
        LibraryERM.CreateExchangeRate(
          Currency.Code, PrepmtPostingDate, PrepmtExchRateAmount, PrepmtExchRateAmount);
        CurrencyCode := Currency.Code;
    end;

    local procedure FAWriteOffScenario(var FixedAsset: array[3] of Record "Fixed Asset"; Vendor: Record Vendor)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        FADocHeader: Record "FA Document Header";
        FASetup: Record "FA Setup";
        FADocLine: Record "FA Document Line";
        i: Integer;
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        for i := 1 to 3 do begin
            LibraryFixedAsset.CreateFixedAssetWithCustomSetup(FixedAsset[i], ReinstmtVATPostingSetup);
            LibraryPurchase.CreatePurchaseLine(
              PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Fixed Asset", FixedAsset[i]."No.", 1);
            PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
            PurchaseLine.Modify(true);
        end;
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        LibraryFixedAsset.CreateFADocumentHeader(FADocHeader, FADocHeader."Document Type"::Release);
        for i := 1 to 3 do
            LibraryFixedAsset.CreateFADocumentLine(FADocLine, FADocHeader, FixedAsset[i]."No.");
        LibraryFixedAsset.PostFADocument(FADocHeader);

        FASetup.Get();
        for i := 1 to 3 do
            LibraryFixedAsset.CalcDepreciation(
              FixedAsset[i]."No.", FASetup."Release Depr. Book", CalcDate('<CM+1D+CM>', WorkDate()), true, false);

        LibraryFixedAsset.CreateFADocumentHeader(FADocHeader, FADocHeader."Document Type"::Writeoff);
        FADocHeader.Validate("Posting Date", CalcDate('<CM+2M>', WorkDate()));
        FADocHeader.Modify(true);
        for i := 1 to 3 do
            LibraryFixedAsset.CreateFADocumentLine(FADocLine, FADocHeader, FixedAsset[i]."No.");
        LibraryFixedAsset.PostFADocument(FADocHeader);
    end;

    local procedure CheckScenarioSetup(var GenJnlLine: Record "Gen. Journal Line"; var VATEntry: Record "VAT Entry"; var VATReinsDate: Date)
    var
        Vendor: Record Vendor;
        GLAccountNo: Code[20];
        VATSetlDate: Date;
    begin
        Initialize();
        Vendor.Get(
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(ReinstmtVATPostingSetup."VAT Bus. Posting Group"));
        GLAccountNo := LibraryERM.CreateGLAccountWithVATPostingSetup(ReinstmtVATPostingSetup, "General Posting Type"::" ");

        VATSetlDate := CalcDate('<CM+1D>', WorkDate());
        VATReinsDate := CalcDate('<CM+1M+1D>', WorkDate());
        CreatePostPurchInvoice(Vendor."No.", GLAccountNo, VATSetlDate);
        CreatePostVATSettlJnlLineForUnrealVATEntries(Vendor."No.", VATSetlDate);
        ClearVATReinstatementJnlLinesByVendNo(GenJnlLine, VATEntry, Vendor."No.");
    end;

    local procedure CreatePostPurchInvoice(VendNo: Code[20]; GLAccountNo: Code[20]; PostingDate: Date)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePostPurchDoc(PurchaseHeader."Document Type"::Invoice, VendNo, GLAccountNo, PostingDate);
    end;

    local procedure CreatePostPurchCrMemo(VendNo: Code[20]; GLAccountNo: Code[20]; PostingDate: Date)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePostPurchDoc(PurchaseHeader."Document Type"::"Credit Memo", VendNo, GLAccountNo, PostingDate);
    end;

    local procedure CreatePostPurchDoc(DocType: Enum "Purchase Document Type"; VendNo: Code[20]; GLAccountNo: Code[20]; PostingDate: Date)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocType, VendNo);
        PurchaseHeader.Validate("Posting Date", PostingDate);
        if DocType = PurchaseHeader."Document Type"::Invoice then
            PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID())
        else
            PurchaseHeader.Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccountNo, 1);
        PurchaseLine.Validate("Direct Unit Cost", 10000);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreatePostPurchInvoicesWithDim(VendNo: Code[20]; GLAccountNo: Code[20]; DimCode: array[2] of Code[20]; DimValueCode: array[3] of Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseInvoiceWithGLAcc(PurchaseHeader, PurchaseLine, VendNo, GLAccountNo);
        PurchaseHeader."Dimension Set ID" := AddDimension(PurchaseHeader."Dimension Set ID", DimCode[1], DimValueCode[1]);
        PurchaseHeader."Dimension Set ID" := AddDimension(PurchaseHeader."Dimension Set ID", DimCode[2], DimValueCode[3]);
        PurchaseHeader.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        LibraryPurchase.CreatePurchaseInvoiceWithGLAcc(PurchaseHeader, PurchaseLine, VendNo, GLAccountNo);
        PurchaseHeader."Dimension Set ID" := AddDimension(PurchaseHeader."Dimension Set ID", DimCode[1], DimValueCode[2]);
        PurchaseHeader.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreatePostVATSettlementJnlLine(VendNo: Code[20]; PostingDate: Date)
    var
        VATEntry: Record "VAT Entry";
    begin
        // Find unrealized VAT Entry
        VATEntry.SetRange("Bill-to/Pay-to No.", VendNo);
        VATEntry.SetFilter("Unrealized Amount", '<>%1', 0);
        VATEntry.FindLast();
        LibraryERM.CreateVATSettlementJnlLine(VATEntry."Entry No.", PostingDate, -VATEntry."Remaining Unrealized Amount", true);
    end;

    local procedure CreatePostVATSettlementForFA(FixedAsset: array[3] of Record "Fixed Asset"; PostingDate: Date)
    var
        VATEntry: Record "VAT Entry";
        i: Integer;
    begin
        VATEntry.SetCurrentKey(Type, "Posting Date");
        VATEntry.SetRange("Object Type", VATEntry."Object Type"::"Fixed Asset");
        for i := 1 to 3 do begin
            VATEntry.SetRange("Object No.", FixedAsset[i]."No.");
            VATEntry.FindLast();
            LibraryERM.CreateVATSettlementJnlLine(VATEntry."Entry No.", PostingDate, -VATEntry."Remaining Unrealized Amount", true);
        end;
    end;

    local procedure CreatePostVATSettlJnlLineForUnrealVATEntries(VendNo: Code[20]; PostingDate: Date)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetCurrentKey(Type, "Bill-to/Pay-to No.");
        VATEntry.SetRange("Bill-to/Pay-to No.", VendNo);
        VATEntry.SetFilter("Unrealized Base", '<>0');
        VATEntry.FindSet();
        repeat
            LibraryERM.CreateVATSettlementJnlLine(VATEntry."Entry No.", PostingDate, -VATEntry."Remaining Unrealized Amount", true);
        until VATEntry.Next() = 0;
    end;

    local procedure CreateReleasePurchInvoiceWithCurrency(var PurchHeader: Record "Purchase Header"; PostingDate: Date; VendNo: Code[20]; GLAccNo: Code[20]; CurrencyCode: Code[10]): Decimal
    var
        PurchLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchHeader, PurchHeader."Document Type"::Invoice, VendNo);
        PurchHeader.Validate("Posting Date", PostingDate);
        PurchHeader.Validate("Currency Code", CurrencyCode);
        PurchHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchLine, PurchHeader, PurchLine.Type::"G/L Account", GLAccNo, LibraryRandom.RandIntInRange(100, 1000));
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchLine.Modify(true);
        LibraryPurchase.ReleasePurchaseDocument(PurchHeader);
        PurchHeader.CalcFields("Amount Including VAT");
        exit(PurchHeader."Amount Including VAT");
    end;

    local procedure CreatePostPrepaymentWithCurrency(PostingDate: Date; CurrencyCode: Code[10]; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; EntryAmount: Decimal; PrepmtDocNo: Code[20]): Code[20]
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(GenJnlLine, GenJnlLine."Document Type"::Payment, AccountType, AccountNo, EntryAmount);
        GenJnlLine.Validate("Posting Date", PostingDate);
        GenJnlLine.Validate("Currency Code", CurrencyCode);
        GenJnlLine.Validate(Prepayment, true);
        GenJnlLine.Validate("Prepayment Document No.", PrepmtDocNo);
        GenJnlLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJnlLine);
        exit(GenJnlLine."Document No.");
    end;

    local procedure ClearVATReinstatementJnlLinesByObjNo(var GenJnlLine: Record "Gen. Journal Line"; ObjectNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetCurrentKey(Type, "Posting Date");
        VATEntry.SetRange("Object Type", VATEntry."Object Type"::"Fixed Asset");
        VATEntry.SetRange("Object No.", ObjectNo);
        VATEntry.FindLast();
        ClearVATReinstatementJnlLines(GenJnlLine, VATEntry);
    end;

    local procedure ClearVATReinstatementJnlLinesByVendNo(var GenJnlLine: Record "Gen. Journal Line"; var VATEntry: Record "VAT Entry"; VendNo: Code[20])
    begin
        VATEntry.SetCurrentKey(Type, "Bill-to/Pay-to No.");
        VATEntry.SetRange("Bill-to/Pay-to No.", VendNo);
        VATEntry.FindLast();
        ClearVATReinstatementJnlLines(GenJnlLine, VATEntry);
    end;

    local procedure ClearVATReinstatementJnlLines(var GenJnlLine: Record "Gen. Journal Line"; var VATEntry: Record "VAT Entry")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Get(VATEntry."VAT Bus. Posting Group", VATEntry."VAT Prod. Posting Group");
        GenJnlLine.SetRange("Journal Template Name", VATPostingSetup."VAT Reinstatement Template");
        GenJnlLine.SetRange("Journal Batch Name", VATPostingSetup."VAT Reinstatement Batch");
        GenJnlLine.DeleteAll();
    end;

    local procedure PostVATReinstJnlLineBySuggestDocuments(var VATEntry: Record "VAT Entry"; VATPostingSetup: Record "VAT Posting Setup"; VATSettlementGenJnlLine: Record "Gen. Journal Line")
    var
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlPostBatch: Codeunit "Gen. Jnl.-Post Batch";
    begin
        CreateVATReinstJnlLineBySuggestDocuments(VATEntry, VATSettlementGenJnlLine."Account No.", VATSettlementGenJnlLine."Posting Date");
        FilterVATGenJnlLine(
          GenJnlLine, VATPostingSetup."VAT Reinstatement Template",
          VATPostingSetup."VAT Reinstatement Batch", VATSettlementGenJnlLine."Document No.");
        GenJnlLine.FindFirst();
        GenJnlPostBatch.VATReinstatement(GenJnlLine);
    end;

    local procedure PostVATReinstatementJournalByVendor(VendNo: Code[20])
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine.SetRange("Account No.", VendNo);
        GenJnlLine.FindFirst();
        LibraryERM.PostVATReinstatementJournal(GenJnlLine);
    end;

    local procedure CreateVATReinstJnlLineBySuggestDocuments(var VATEntry: Record "VAT Entry"; VendNo: Code[20]; PostingDate: Date)
    var
        TempVATDocBuf: Record "VAT Document Entry Buffer" temporary;
        VATReinstMgt: Codeunit "VAT Reinstatement Management";
    begin
        VATReinstMgt.Generate(TempVATDocBuf, '', '', '');
        TempVATDocBuf.SetRange("CV No.", VendNo);
        TempVATDocBuf.FindFirst();
        VATEntry.Reset();
        VATReinstMgt.CopyToJnl(TempVATDocBuf, VATEntry, 1, PostingDate, '');
    end;

    local procedure CreatePostVATReinstatementJnlLine(VendNo: Code[20]; PostingDate: Date) ReinstAmount: Decimal
    var
        GenJournalLine: Record "Gen. Journal Line";
        VATEntry: Record "VAT Entry";
    begin
        // Find realized VAT Entry
        VATEntry.SetRange("Bill-to/Pay-to No.", VendNo);
        VATEntry.FindLast();
        ReinstAmount := Round(VATEntry.Amount / 3);
        LibraryERM.CreateVATReinstatementJnlLine(GenJournalLine, VATEntry."Entry No.", PostingDate, ReinstAmount, true);
        exit(ReinstAmount);
    end;

    local procedure CreatePostVATReinstatementFromFAWriteOff(var GenJnlLine: Record "Gen. Journal Line"; PostingDate: Date)
    var
        PostedFADocHeader: Record "Posted FA Doc. Header";
        VATReinstMgt: Codeunit "VAT Reinstatement Management";
    begin
        PostedFADocHeader.SetRange("Document Type", PostedFADocHeader."Document Type"::Writeoff);
        PostedFADocHeader.SetRange("Posting Date", PostingDate);
        PostedFADocHeader.FindLast();
        VATReinstMgt.CreateVATReinstFromFAWriteOff(PostedFADocHeader."No.");
        LibraryERM.PostVATReinstatementJournal(GenJnlLine);
    end;

    local procedure SuggestVATSettlement(DocumentNo: Code[20]; VATPostingSetup: Record "VAT Posting Setup"; var GenJnlLine: Record "Gen. Journal Line"; DateFilter: Date)
    var
        TempVATDocEntryBuffer: Record "VAT Document Entry Buffer" temporary;
        VATEntry: Record "VAT Entry";
        VATSettlementMgt: Codeunit "VAT Settlement Management";
    begin
        TempVATDocEntryBuffer.SetRange("Date Filter", 0D, DateFilter);
        TempVATDocEntryBuffer.SetRange("Document No.", DocumentNo);
        TempVATDocEntryBuffer.Next(0); // Needed to trick preCAL
        VATSettlementMgt.Generate(TempVATDocEntryBuffer, VATSettlType::Purchase);
        TempVATDocEntryBuffer.FindSet();
        VATSettlementMgt.CopyToJnl(TempVATDocEntryBuffer, VATEntry);
        FilterVATGenJnlLine(GenJnlLine, VATPostingSetup."VAT Settlement Template", VATPostingSetup."VAT Settlement Batch", DocumentNo);
    end;

    local procedure ApplyPurchPrepmtToInv(PrepmtNo: Code[20]; InvNo: Code[20])
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.ApplyVendorLedgerEntry(
          VendLedgEntry."Document Type"::Payment, PrepmtNo,
          VendLedgEntry."Document Type"::Invoice, InvNo);
    end;

    local procedure FindLastVATEntryNo(VendNo: Code[20]): Integer
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetCurrentKey(Type, "Bill-to/Pay-to No.");
        VATEntry.SetRange("Bill-to/Pay-to No.", VendNo);
        VATEntry.FindLast();
        exit(VATEntry."Entry No.");
    end;

    local procedure FindDocNosFromGenJnlLine(var DocNo: array[2] of Code[20]; var GenJnlLine: Record "Gen. Journal Line"; VendNo: Code[20])
    begin
        GenJnlLine.SetRange("Account No.", VendNo);
        GenJnlLine.FindFirst();
        DocNo[1] := GenJnlLine."Document No.";
        GenJnlLine.Next();
        DocNo[2] := GenJnlLine."Document No.";
    end;

    local procedure FindVATSettlementVATEntry(GenJnlLine: Record "Gen. Journal Line"; PrepmtDiff: Boolean; EntryType: Enum "General Posting Type"): Integer
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document Type", GenJnlLine."Document Type");
        VATEntry.SetRange("Document No.", GenJnlLine."Document No.");
        VATEntry.SetRange(Type, EntryType);
        VATEntry.SetFilter("Unrealized VAT Entry No.", '<>0');
        VATEntry.SetRange("Bill-to/Pay-to No.", GenJnlLine."Account No.");
        VATEntry.SetRange("Prepmt. Diff.", PrepmtDiff);
        VATEntry.FindLast();
        exit(VATEntry."Entry No.");
    end;

    local procedure FindVATReinstatementEntry(GenJnlLine: Record "Gen. Journal Line"): Integer
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document Type", GenJnlLine."Document Type");
        VATEntry.SetRange("Document No.", GenJnlLine."Document No.");
        VATEntry.SetRange("Bill-to/Pay-to No.", GenJnlLine."Account No.");
        VATEntry.SetRange("VAT Reinstatement", true);
        VATEntry.FindLast();
        exit(VATEntry."Entry No.");
    end;

    local procedure FilterVATGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; TemplateName: Code[10]; BatchName: Code[10]; DocumentNo: Code[20])
    begin
        GenJnlLine.SetRange("Journal Template Name", TemplateName);
        GenJnlLine.SetRange("Journal Batch Name", BatchName);
        GenJnlLine.SetRange("Document No.", DocumentNo);
    end;

    local procedure FilterVATReinstGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; VendNo: Code[20]; ReinstatedVATEntryNo: Integer)
    begin
        GenJnlLine.SetRange("Account No.", VendNo);
        GenJnlLine.SetRange("Reinstatement VAT Entry No.", ReinstatedVATEntryNo);
    end;

    local procedure UpdateCancelPrepmtAdjmtInTA(NewCancelPrepmtAdjmtInTA: Boolean) OldCancelPrepmtAdjmtInTA: Boolean
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        OldCancelPrepmtAdjmtInTA := GLSetup."Cancel Prepmt. Adjmt. in TA";
        GLSetup.Validate("Cancel Prepmt. Adjmt. in TA", NewCancelPrepmtAdjmtInTA);
        GLSetup.Modify(true);
    end;

    local procedure UpdateVATSettlmentJnlLineDocNo(var GenJnlLine: Record "Gen. Journal Line")
    var
        VATSettlementDocNo: Code[20];
    begin
        VATSettlementDocNo := LibraryUtility.GenerateGUID();
        GenJnlLine.FindSet(true);
        repeat
            GenJnlLine.Validate("Document No.", VATSettlementDocNo);
            GenJnlLine.Validate("External Document No.", GenJnlLine."Document No.");
            GenJnlLine.Modify(true);
        until GenJnlLine.Next() = 0;
        GenJnlLine.SetRange("Document No.");
    end;

    local procedure UpdateRedStornoVATReinstatementInGLSetup(NewRedStornoVATReinstatement: Boolean) OldRedStornoVATReinstatement: Boolean
    begin
        GLSetup.Get();
        OldRedStornoVATReinstatement := GLSetup."Red Storno VAT Reinstatement";
        GLSetup.Validate("Red Storno VAT Reinstatement", NewRedStornoVATReinstatement);
        GLSetup.Modify(true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure HndlConfirm(Question: Text[1024]; var Reply: Boolean)
    begin
        if StrPos(Question, DepCalcMsg) <> 0 then begin
            Reply := false;
            exit;
        end;

        if StrPos(Question, AllowedvaluesFilterLbl) <> 0 then begin
            Reply := false;
            exit;
        end;

        if StrPos(Question, ConfirmMsg) = 0 then
            Error(IncorrectConfirmErr);

        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure HNDLMessages(Message: Text[1024])
    begin
        case Message of
            JnlLinePostedMsg, VATReinstLinesCreatedMsg, DepCalcMsg:
                exit;
            else
                if StrPos(Message, DepCalcMsg) = 0 then
                    Error(UnexpectedErr);
        end;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure HndlForm(var VATReinstatementJournal: Page "VAT Reinstatement Journal")
    begin
    end;

    local procedure AddDimension(DimSetId: Integer; DimCode: Code[20]; DimValue: Code[20]): Integer
    var
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
    begin
        DimMgt.GetDimensionSet(TempDimSetEntry, DimSetId);
        if TempDimSetEntry.Get(DimSetId, DimCode) then begin
            TempDimSetEntry."Dimension Value Code" := DimValue;
            TempDimSetEntry.Modify();
        end else begin
            TempDimSetEntry."Dimension Set ID" := DimSetId;
            TempDimSetEntry."Dimension Code" := DimCode;
            TempDimSetEntry.Validate("Dimension Value Code", DimValue);
            TempDimSetEntry.Insert();
        end;
        exit(DimMgt.GetDimensionSetID(TempDimSetEntry));
    end;

    local procedure GetDimValue(DimSetId: Integer; DimCode: Code[20]; var DimValue: Code[20]): Boolean
    var
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
    begin
        // get dimension set
        DimMgt.GetDimensionSet(TempDimSetEntry, DimSetId);

        if not TempDimSetEntry.Get(DimSetId, DimCode) then
            exit(false);

        // fill in dimension value
        DimValue := TempDimSetEntry."Dimension Value Code";
        exit(true);
    end;

    local procedure GetVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATBusPostingGroupCode: Code[20]; GLAccNo: Code[20])
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get(GLAccNo);
        VATPostingSetup.Get(VATBusPostingGroupCode, GLAccount."VAT Prod. Posting Group");
    end;

    local procedure AssertDimension(DimSetId: Integer; DimCode: Code[20]; ExpectedDimValue: Code[20])
    var
        DimValueCode: Code[20];
    begin
        Assert.IsTrue(GetDimValue(DimSetId, DimCode, DimValueCode), DimErr);
        Assert.IsTrue(DimValueCode = ExpectedDimValue, DimValueErr);
    end;

    local procedure VerifyPurchVATLedgLineDoesNotExist(VATLedgerNo: Code[20])
    var
        VATLedgerLine: Record "VAT Ledger Line";
    begin
        VATLedgerLine.SetRange(Type, VATLedgerLine.Type::Purchase);
        VATLedgerLine.SetRange(Code, VATLedgerNo);
        Assert.IsTrue(VATLedgerLine.IsEmpty, PurchVATLedgerErr);
    end;

    local procedure VerifySalesVATLedgLineExists(VendNo: Code[20]; VATLedgerNo: Code[20])
    var
        VATLedgerLine: Record "VAT Ledger Line";
    begin
        VATLedgerLine.SetRange(Type, VATLedgerLine.Type::Sales);
        VATLedgerLine.SetRange(Code, VATLedgerNo);
        VATLedgerLine.SetRange("C/V No.", VendNo);
        Assert.IsTrue(VATLedgerLine.FindFirst(), SalesVATLedgerErr);
    end;

    local procedure VerifyVATEntriesOfFA(FixedAsset: array[3] of Record "Fixed Asset")
    var
        VATEntry: Record "VAT Entry";
        i: Integer;
    begin
        VATEntry.SetRange("Object Type", VATEntry."Object Type"::"Fixed Asset");
        for i := 1 to 3 do begin
            VATEntry.SetRange("Object No.", FixedAsset[i]."No.");
            Assert.IsTrue(VATEntry.Count = 3, VATEntriesQtyErr);
        end;
    end;

    local procedure VerifyDimensionSetIDInGLEntry(DocNo: array[2] of Code[20]; DimCode: array[2] of Code[20]; DimValueCode: array[3] of Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocNo[1]);
        GLEntry.FindLast();
        AssertDimension(GLEntry."Dimension Set ID", DimCode[1], DimValueCode[1]);
        AssertDimension(GLEntry."Dimension Set ID", DimCode[2], DimValueCode[3]);

        GLEntry.SetRange("Document No.", DocNo[2]);
        GLEntry.FindLast();
        AssertDimension(GLEntry."Dimension Set ID", DimCode[1], DimValueCode[2]);
    end;

    local procedure VerifyReinstatementVATEntry(AccountNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Account No.", AccountNo);
        GenJournalLine.FindFirst();
        Assert.AreEqual(
          FindLastVATEntryNo(AccountNo), GenJournalLine."Reinstatement VAT Entry No.",
          GenJournalLine.FieldCaption("Reinstatement VAT Entry No."));
    end;

    local procedure VerifyVATReinstatementGLCorrEntry(VATPostingSetup: Record "VAT Posting Setup"; VATEntryNo: Integer)
    var
        VATEntry: Record "VAT Entry";
        GLCorrespondenceEntry: Record "G/L Correspondence Entry";
    begin
        VATEntry.Get(VATEntryNo);
        GLCorrespondenceEntry.SetRange("Transaction No.", VATEntry."Transaction No.");
        GLCorrespondenceEntry.FindLast();
        Assert.AreEqual(
          VATPostingSetup."Purch. VAT Unreal. Account", GLCorrespondenceEntry."Debit Account No.",
          GLCorrespondenceEntry.FieldCaption("Debit Account No."));
        Assert.AreEqual(
          VATPostingSetup."Purchase VAT Account", GLCorrespondenceEntry."Credit Account No.",
          GLCorrespondenceEntry.FieldCaption("Credit Account No."));
        Assert.AreEqual(
          -VATEntry.Amount, GLCorrespondenceEntry.Amount, GLCorrespondenceEntry.FieldCaption(Amount));
    end;

    local procedure VerifyVATReinstatementGLCorrEntryRedStorno(VATPostingSetup: Record "VAT Posting Setup"; VATEntryNo: Integer)
    var
        VATEntry: Record "VAT Entry";
        GLCorrespondenceEntry: Record "G/L Correspondence Entry";
    begin
        VATEntry.Get(VATEntryNo);
        GLCorrespondenceEntry.SetRange("Transaction No.", VATEntry."Transaction No.");
        GLCorrespondenceEntry.FindLast();
        Assert.AreEqual(
          VATPostingSetup."Purchase VAT Account", GLCorrespondenceEntry."Debit Account No.",
          GLCorrespondenceEntry.FieldCaption("Debit Account No."));
        Assert.AreEqual(
          VATPostingSetup."Purch. VAT Unreal. Account", GLCorrespondenceEntry."Credit Account No.",
          GLCorrespondenceEntry.FieldCaption("Credit Account No."));
        Assert.AreEqual(
          VATEntry.Amount, GLCorrespondenceEntry.Amount, GLCorrespondenceEntry.FieldCaption(Amount));
    end;

    local procedure VerifyGenJnlLineWithReinstVATEntryNoDoesNotExist(VendNo: Code[20]; ReinstatedVATEntryNo: Integer)
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        FilterVATReinstGenJnlLine(GenJnlLine, VendNo, ReinstatedVATEntryNo);
        Assert.RecordIsEmpty(GenJnlLine);
    end;
}

