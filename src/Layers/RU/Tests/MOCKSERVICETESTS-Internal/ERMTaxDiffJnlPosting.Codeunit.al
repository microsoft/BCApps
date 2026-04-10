codeunit 144521 "ERM Tax Diff. Jnl. Posting"
{
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryTaxAcc: Codeunit "Library - Tax Accounting";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        TaxDiffJnlLinePost: Codeunit "Tax Diff.-Post Jnl. Line";
        LibraryRandom: Codeunit "Library - Random";
        AmountMustBeErr: Label 'Amount (Tax) must be %1';
        AlreadyRecoveredErr: Label 'already recovered.';
        CannotBeLessThanErr: Label 'can not be less than';
        TaxDiffStartBalChangedErr: Label 'Start balance of tax difference changed.';
        TransactionNoIsEmptyErr: Label 'Transaction No. is empty.';
        WrongAmountErr: Label 'Wrong amount in %1.';

    [Test]
    [Scope('OnPrem')]
    procedure DiffTaxAmountOnDeprBonusRecover()
    var
        TaxDiffJnlLine: Record "Tax Diff. Journal Line";
        FANo: Code[20];
        ExpectedAmount: Decimal;
    begin
        InitDeprBonusFAWithJnlLine(FANo, ExpectedAmount, 0D);
        CreateDeprBonusRecoveryTaxDiffJnlLine(
          TaxDiffJnlLine, FANo, 0);
        asserterror TaxDiffJnlLinePost.RunWithCheck(TaxDiffJnlLine);
        Assert.ExpectedError(StrSubstNo(AmountMustBeErr, -ExpectedAmount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AlreadyRecoveredDeprBonus()
    var
        TaxDiffJnlLine: Record "Tax Diff. Journal Line";
        FANo: Code[20];
        ExpectedAmount: Decimal;
    begin
        InitDeprBonusFAWithJnlLine(FANo, ExpectedAmount, WorkDate());
        CreateDeprBonusRecoveryTaxDiffJnlLine(
          TaxDiffJnlLine, FANo, -ExpectedAmount);
        asserterror TaxDiffJnlLinePost.RunWithCheck(TaxDiffJnlLine);
        Assert.ExpectedError(AlreadyRecoveredErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DisposalDateLessThanPostingDate()
    var
        TaxDiffJnlLine: Record "Tax Diff. Journal Line";
        FANo: Code[20];
        ExpectedAmount: Decimal;
    begin
        InitDeprBonusFAWithJnlLine(FANo, ExpectedAmount, 0D);
        CreateDeprBonusRecoveryTaxDiffJnlLine(
          TaxDiffJnlLine, FANo, -ExpectedAmount);
        TaxDiffJnlLine."Disposal Mode" := TaxDiffJnlLine."Disposal Mode"::"Write Down";
        TaxDiffJnlLine."Disposal Date" :=
          CalcDate('<-1D>', TaxDiffJnlLine."Posting Date");
        asserterror TaxDiffJnlLinePost.RunWithCheck(TaxDiffJnlLine);
        Assert.ExpectedError(CannotBeLessThanErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangedStartBalanceOfTaxDiff()
    var
        TaxDiffJnlLine: Record "Tax Diff. Journal Line";
        FANo: Code[20];
        ExpectedAmount: Decimal;
    begin
        InitDeprBonusFAWithJnlLine(FANo, ExpectedAmount, 0D);
        CreateDeprBonusRecoveryTaxDiffJnlLine(
          TaxDiffJnlLine, FANo, -ExpectedAmount);
        TaxDiffJnlLine."DTA Starting Balance" := LibraryRandom.RandDec(100, 2);
        asserterror TaxDiffJnlLinePost.RunWithCheck(TaxDiffJnlLine);
        Assert.ExpectedError(TaxDiffStartBalChangedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DiffJnlLine_Constant()
    var
        TaxDiffJnlLine: Record "Tax Diff. Journal Line";
        TaxDiffPostingGroup: Record "Tax Diff. Posting Group";
    begin
        DiffJnlLineWithDefinedType(
          TaxDiffJnlLine."Tax Diff. Type"::Constant, TaxDiffPostingGroup.FieldNo("CTA Tax Account"),
          TaxDiffPostingGroup.FieldNo("CTL Tax Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DiffJnlLine_Temporary()
    var
        TaxDiffJnlLine: Record "Tax Diff. Journal Line";
        TaxDiffPostingGroup: Record "Tax Diff. Posting Group";
    begin
        DiffJnlLineWithDefinedType(
          TaxDiffJnlLine."Tax Diff. Type"::"Temporary", TaxDiffPostingGroup.FieldNo("DTA Tax Account"),
          TaxDiffPostingGroup.FieldNo("DTL Tax Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DiffJnlLine_DisposalWriteDownPositive()
    var
        TaxDiffPostingGroup: Record "Tax Diff. Posting Group";
    begin
        DiffJnlLine_DisposalWriteDown(LibraryRandom.RandDec(100, 2), TaxDiffPostingGroup.FieldNo("DTA Disposal Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DiffJnlLine_DisposalWriteDownNegative()
    var
        TaxDiffPostingGroup: Record "Tax Diff. Posting Group";
    begin
        DiffJnlLine_DisposalWriteDown(-LibraryRandom.RandDec(100, 2), TaxDiffPostingGroup.FieldNo("DTL Disposal Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DiffJnlLine_DisposalTransformPositive()
    var
        TaxDiffJnlLine: Record "Tax Diff. Journal Line";
        TaxDiffPostingGroup: Record "Tax Diff. Posting Group";
        TransactionNo: Integer;
    begin
        TransactionNo :=
          DiffJnlLine_DisposalTransform(TaxDiffJnlLine, TaxDiffPostingGroup, LibraryRandom.RandDec(100, 2));
        VerifyGLEntry(TransactionNo, TaxDiffPostingGroup."DTA Transfer Bal. Account", TaxDiffJnlLine."Disposal Tax Amount");
        VerifyGLEntry(TransactionNo, TaxDiffPostingGroup."CTL Transfer Tax Account", TaxDiffJnlLine."Disposal Tax Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DiffJnlLine_DisposalTransformNegative()
    var
        TaxDiffJnlLine: Record "Tax Diff. Journal Line";
        TaxDiffPostingGroup: Record "Tax Diff. Posting Group";
        TransactionNo: Integer;
    begin
        TransactionNo :=
          DiffJnlLine_DisposalTransform(TaxDiffJnlLine, TaxDiffPostingGroup, -LibraryRandom.RandDec(100, 2));
        VerifyGLEntry(TransactionNo, TaxDiffPostingGroup."DTL Account", -TaxDiffJnlLine."Disposal Tax Amount");
        VerifyGLEntry(TransactionNo, TaxDiffPostingGroup."DTL Transfer Bal. Account", TaxDiffJnlLine."Disposal Tax Amount");
    end;

    local procedure Initialize()
    begin
        Clear(TaxDiffJnlLinePost);
    end;

    local procedure InitDeprBonusFAWithJnlLine(var FANo: Code[20]; var ExpectedAmount: Decimal; DeprRecoveryDate: Date)
    var
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
    begin
        Initialize();
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        FANo := FixedAsset."No.";
        UpdateTaxRegisterDeprBook(DepreciationBook.Code);
        ExpectedAmount :=
          CreateFALedgEntryWithDeprBonus(DepreciationBook.Code, FixedAsset."No.", DeprRecoveryDate);
    end;

    local procedure InitTaxJnlLineWithDefinedType(var TaxDiffJnlLine: Record "Tax Diff. Journal Line"; TaxDiffType: Option)
    var
        FixedAsset: Record "Fixed Asset";
    begin
        Initialize();
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        CreateTaxDiffJnlLineWithDefinedType(TaxDiffJnlLine, FixedAsset."No.", TaxDiffType);
    end;

    local procedure InitTaxJnlLineWithDisposalData(var TaxDiffJnlLine: Record "Tax Diff. Journal Line"; DisposalMode: Option; EntryAmount: Decimal)
    var
        FixedAsset: Record "Fixed Asset";
    begin
        Initialize();
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        CreateTaxDiffJnlLineWithDisposalData(TaxDiffJnlLine, FixedAsset."No.", DisposalMode, EntryAmount);
    end;

    local procedure DiffJnlLineWithDefinedType(TaxDiffType: Option; AssetsFieldNo: Integer; LiabilitiesFieldNo: Integer)
    var
        TaxDiffJnlLine: Record "Tax Diff. Journal Line";
        TaxDiffPostingGroup: Record "Tax Diff. Posting Group";
    begin
        InitTaxJnlLineWithDefinedType(TaxDiffJnlLine, TaxDiffType);
        TaxDiffJnlLinePost.RunWithCheck(TaxDiffJnlLine);
        TaxDiffPostingGroup.Get(TaxDiffJnlLine."Tax Diff. Posting Group");
        VerifyTaxDiffEntries(
          TaxDiffJnlLine, GetAccountNo(TaxDiffPostingGroup, AssetsFieldNo), GetAccountNo(TaxDiffPostingGroup, LiabilitiesFieldNo));
    end;

    local procedure DiffJnlLine_DisposalWriteDown(EntryAmount: Decimal; FieldNo: Integer)
    var
        TaxDiffJnlLine: Record "Tax Diff. Journal Line";
        TaxDiffPostingGroup: Record "Tax Diff. Posting Group";
        TransactionNo: Integer;
    begin
        InitTaxJnlLineWithDisposalData(
          TaxDiffJnlLine, TaxDiffJnlLine."Disposal Mode"::"Write Down", EntryAmount);
        TaxDiffJnlLinePost.RunWithCheck(TaxDiffJnlLine);
        TaxDiffPostingGroup.Get(TaxDiffJnlLine."Tax Diff. Posting Group");
        TransactionNo := GetTaxDiffEntryTransNo(TaxDiffJnlLine);
        Assert.IsFalse(TransactionNo = 0, TransactionNoIsEmptyErr);
        VerifyGLEntry(
          TransactionNo, GetAccountNo(TaxDiffPostingGroup, FieldNo), TaxDiffJnlLine."Disposal Tax Amount");
    end;

    local procedure DiffJnlLine_DisposalTransform(var TaxDiffJnlLine: Record "Tax Diff. Journal Line"; var TaxDiffPostingGroup: Record "Tax Diff. Posting Group"; EntryAmount: Decimal): Integer
    var
        TransactionNo: Integer;
    begin
        InitTaxJnlLineWithDisposalData(
          TaxDiffJnlLine, TaxDiffJnlLine."Disposal Mode"::Transform, EntryAmount);
        TaxDiffJnlLinePost.RunWithCheck(TaxDiffJnlLine);
        TaxDiffPostingGroup.Get(TaxDiffJnlLine."Tax Diff. Posting Group");
        TransactionNo := GetTaxDiffEntryTransNo(TaxDiffJnlLine);
        Assert.IsFalse(TransactionNo = 0, TransactionNoIsEmptyErr);
        exit(TransactionNo);
    end;

    local procedure UpdateTaxRegisterDeprBook(DeprBookCode: Code[10])
    var
        TaxRegisterSetup: Record "Tax Register Setup";
    begin
        TaxRegisterSetup.Get();
        TaxRegisterSetup.Validate("Tax Depreciation Book", DeprBookCode);
        TaxRegisterSetup.Modify(true);
    end;

    local procedure CreateFALedgEntryWithDeprBonus(DeprBookCode: Code[10]; FANo: Code[20]; DeprBonusRecoveryDate: Date): Decimal
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        FALedgerEntry.Init();
        FALedgerEntry."Depreciation Book Code" := DeprBookCode;
        FALedgerEntry."FA No." := FANo;
        FALedgerEntry."FA Posting Type" := FALedgerEntry."FA Posting Type"::Depreciation;
        FALedgerEntry."Depr. Bonus" := true;
        FALedgerEntry.Amount := LibraryRandom.RandDec(100, 2);
        FALedgerEntry."Depr. Bonus Recovery Date" := DeprBonusRecoveryDate;
        FALedgerEntry.Insert();
        exit(FALedgerEntry.Amount);
    end;

    local procedure CreateDeprBonusRecoveryTaxDiffJnlLine(var TaxDiffJnlLine: Record "Tax Diff. Journal Line"; FANo: Code[20]; AmountTax: Decimal)
    begin
        LibraryTaxAcc.FillTaxDiffJnlLine(
          TaxDiffJnlLine, TaxDiffJnlLine."Source Type"::"Fixed Asset", FANo);
        TaxDiffJnlLine."Depr. Bonus Recovery" := true;
        TaxDiffJnlLine."Amount (Tax)" := AmountTax;
    end;

    local procedure CreateTaxDiffJnlLineWithDefinedType(var TaxDiffJnlLine: Record "Tax Diff. Journal Line"; FANo: Code[20]; TaxDiffType: Option)
    begin
        LibraryTaxAcc.FillTaxDiffJnlLine(
          TaxDiffJnlLine, TaxDiffJnlLine."Source Type"::"Fixed Asset", FANo);
        TaxDiffJnlLine."Tax Diff. Type" := TaxDiffType;
        TaxDiffJnlLine."Asset Tax Amount" := LibraryRandom.RandDec(100, 2);
        TaxDiffJnlLine."Liability Tax Amount" := LibraryRandom.RandDec(100, 2);
    end;

    local procedure CreateTaxDiffJnlLineWithDisposalData(var TaxDiffJnlLine: Record "Tax Diff. Journal Line"; FANo: Code[20]; DisposalMode: Option; EntryAmount: Decimal)
    begin
        LibraryTaxAcc.FillTaxDiffJnlLine(
          TaxDiffJnlLine, TaxDiffJnlLine."Source Type"::"Fixed Asset", FANo);
        TaxDiffJnlLine."Tax Diff. Type" := TaxDiffJnlLine."Tax Diff. Type"::"Temporary";
        TaxDiffJnlLine."Disposal Date" := TaxDiffJnlLine."Posting Date";
        TaxDiffJnlLine."Disposal Mode" := DisposalMode;
        TaxDiffJnlLine."Disposal Tax Amount" := EntryAmount;
    end;

    local procedure GetSign(TaxDiffType: Option): Integer
    var
        TaxDiffJnlLine: Record "Tax Diff. Journal Line";
    begin
        case TaxDiffType of
            TaxDiffJnlLine."Tax Diff. Type"::Constant:
                exit(1);
            TaxDiffJnlLine."Tax Diff. Type"::"Temporary":
                exit(-1);
        end;
    end;

    local procedure GetAccountNo(TaxDiffPostingGroup: Record "Tax Diff. Posting Group"; FieldNo: Integer): Code[20]
    begin
        case FieldNo of
            TaxDiffPostingGroup.FieldNo("CTA Tax Account"):
                exit(TaxDiffPostingGroup."CTA Tax Account");
            TaxDiffPostingGroup.FieldNo("DTA Tax Account"):
                exit(TaxDiffPostingGroup."DTA Tax Account");
            TaxDiffPostingGroup.FieldNo("CTL Tax Account"):
                exit(TaxDiffPostingGroup."CTL Tax Account");
            TaxDiffPostingGroup.FieldNo("DTL Tax Account"):
                exit(TaxDiffPostingGroup."DTL Tax Account");
            TaxDiffPostingGroup.FieldNo("DTA Disposal Account"):
                exit(TaxDiffPostingGroup."DTA Disposal Account");
            TaxDiffPostingGroup.FieldNo("DTL Disposal Account"):
                exit(TaxDiffPostingGroup."DTL Disposal Account");
        end;
    end;

    local procedure GetTaxDiffEntryTransNo(TaxDiffJnlLine: Record "Tax Diff. Journal Line"): Integer
    var
        TaxDiffEntry: Record "Tax Diff. Ledger Entry";
    begin
        TaxDiffEntry.SetRange("Source Type", TaxDiffJnlLine."Source Type");
        TaxDiffEntry.SetRange("Source No.", TaxDiffJnlLine."Source No.");
        TaxDiffEntry.FindLast();
        exit(TaxDiffEntry."Transaction No.");
    end;

    local procedure VerifyTaxDiffEntries(TaxDiffJnlLine: Record "Tax Diff. Journal Line"; AssetsAccountNo: Code[20]; LiabilitiesAccountNo: Code[20])
    var
        TransactionNo: Integer;
    begin
        TransactionNo := GetTaxDiffEntryTransNo(TaxDiffJnlLine);
        Assert.IsFalse(TransactionNo = 0, TransactionNoIsEmptyErr);
        VerifyPairedGLEntries(TaxDiffJnlLine, AssetsAccountNo, LiabilitiesAccountNo, TransactionNo);
    end;

    local procedure VerifyPairedGLEntries(TaxDiffJnlLine: Record "Tax Diff. Journal Line"; AssetsAccountNo: Code[20]; LiabilitiesAccountNo: Code[20]; TransactionNo: Integer)
    begin
        VerifyGLEntry(
          TransactionNo, AssetsAccountNo, GetSign(TaxDiffJnlLine."Tax Diff. Type") * TaxDiffJnlLine."Asset Tax Amount");
        VerifyGLEntry(TransactionNo, LiabilitiesAccountNo, -GetSign(TaxDiffJnlLine."Tax Diff. Type") * TaxDiffJnlLine."Liability Tax Amount");
    end;

    local procedure VerifyGLEntry(TransactionNo: Integer; AccountNo: Code[20]; ExpectedAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Transaction No.", TransactionNo);
        GLEntry.SetRange("G/L Account No.", AccountNo);
        GLEntry.FindFirst();
        Assert.AreEqual(ExpectedAmount, GLEntry.Amount, StrSubstNo(WrongAmountErr, GLEntry.TableCaption));
    end;
}

