codeunit 144515 "ERM Tax Accounting"
{
    TestPermissions = NonRestrictive;
    Permissions = tabledata "G/L Correspondence Entry" = rimd,
                  tabledata "FA Ledger Entry" = im;
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        LibraryTaxAcc: Codeunit "Library - Tax Accounting";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        IsInitialized: Boolean;
        TaxDiffJnlLineErr: Label 'Incorrect Tax Diff. Jnl. Line count.';
        TaxCalcAccumErr: Label 'Incorrect Tax Calc. Accumlation line count.';
        TaxCalcAccumAmountErr: Label 'Incorrect Tax Calc. Accumlation line amount.';
        EntryNotFoundErr: Label 'FA Ledger Entry not found';

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;

        LibrarySetupStorage.Save(DATABASE::"FA Setup");
        LibrarySetupStorage.Save(DATABASE::"Tax Register Setup");

        IsInitialized := true;
        Commit();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcTaxDiffDeprBonus()
    var
        FixedAsset: Record "Fixed Asset";
        TaxRegisterSetup: Record "Tax Register Setup";
        TaxDiffJnlTemplateName: Code[10];
        TaxDiffJnlBatchName: Code[10];
    begin
        // Setup:
        Initialize();

        LibraryTaxAcc.PrepareTaxDiffDeprBonusSetup();
        LibraryTaxAcc.CreateTaxDiffJnlSetup(TaxDiffJnlTemplateName, TaxDiffJnlBatchName);
        CreateFixedAsset(FixedAsset);
        CreateTaxDiffDeprBonusEntry(FixedAsset."No.", WorkDate(), WorkDate(), FixedAsset."Tax Difference Code", 100);

        // Exercise:
        RunCalcTaxDiffDeprBonusReport(FixedAsset, WorkDate(), WorkDate(), TaxDiffJnlTemplateName, TaxDiffJnlBatchName);

        // Verify:
        TaxRegisterSetup.Get();
        VerifyTaxDiffJnl(TaxDiffJnlTemplateName, TaxDiffJnlBatchName, TaxRegisterSetup."Depr. Bonus TD Code", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcTaxDiffFixedAsset()
    var
        FixedAsset: Record "Fixed Asset";
        TaxDiffJnlTemplateName: Code[10];
        TaxDiffJnlBatchName: Code[10];
    begin
        // Setup:
        Initialize();

        LibraryTaxAcc.PrepareTaxDiffFASetup();
        LibraryTaxAcc.CreateTaxDiffJnlSetup(TaxDiffJnlTemplateName, TaxDiffJnlBatchName);
        CreateFixedAsset(FixedAsset);
        CreateTaxDiffFAEntry(FixedAsset."No.", WorkDate(), WorkDate(), FixedAsset."Tax Difference Code", 100);

        // Exercise:
        RunCalcTaxDiffFAReport(FixedAsset, WorkDate(), TaxDiffJnlTemplateName, TaxDiffJnlBatchName);

        // Verify:
        VerifyTaxDiffJnl(TaxDiffJnlTemplateName, TaxDiffJnlBatchName, FixedAsset."Tax Difference Code", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcTaxDiffDisposedFA()
    var
        FixedAsset: Record "Fixed Asset";
        TaxRegisterSetup: Record "Tax Register Setup";
        TaxDiffJnlTemplateName: Code[10];
        TaxDiffJnlBatchName: Code[10];
    begin
        // Setup:
        Initialize();

        LibraryTaxAcc.PrepareTaxDiffDisposalSetup();
        LibraryTaxAcc.CreateTaxDiffJnlSetup(TaxDiffJnlTemplateName, TaxDiffJnlBatchName);
        CreateFixedAsset(FixedAsset);
        CreateTaxDiffDisposalEntry(FixedAsset."No.", WorkDate(), WorkDate(), FixedAsset."Tax Difference Code", 100);

        // Exercise:
        RunCalcTaxDiffDisposedFAReport(FixedAsset, WorkDate(), WorkDate(), TaxDiffJnlTemplateName, TaxDiffJnlBatchName);

        // Verify:
        TaxRegisterSetup.Get();
        VerifyTaxDiffJnl(TaxDiffJnlTemplateName, TaxDiffJnlBatchName, TaxRegisterSetup."Disposal TD Code", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcTaxDiffDeprFE()
    var
        FutureExpense: Record "Fixed Asset";
        TaxDiffJnlTemplateName: Code[10];
        TaxDiffJnlBatchName: Code[10];
    begin
        // Setup:
        Initialize();

        LibraryTaxAcc.PrepareTaxDiffDeprFESetup();
        LibraryTaxAcc.CreateTaxDiffJnlSetup(TaxDiffJnlTemplateName, TaxDiffJnlBatchName);
        CreateFutureExpense(FutureExpense);
        CreateTaxDiffFEDeprEntry(FutureExpense."No.", WorkDate(), WorkDate(), 100);

        // Exercise:
        RunCalcTaxDiffDeprFEReport(FutureExpense, WorkDate(), WorkDate(), TaxDiffJnlTemplateName, TaxDiffJnlBatchName);

        // Verify:
        VerifyTaxDiffJnl(TaxDiffJnlTemplateName, TaxDiffJnlBatchName, '', 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TaxCalcGL()
    var
        TaxCalcSectionCode: Code[10];
        TaxCalcHeaderNo: Code[10];
    begin
        // Setup:
        CreateTaxCalcSetupGL(TaxCalcSectionCode, TaxCalcHeaderNo);

        // Exercise:
        CreateTaxCalcAccum(TaxCalcSectionCode, true, false, false, false, WorkDate());

        // Verify:
        VerifyTaxCalcAccum(TaxCalcSectionCode, TaxCalcHeaderNo, 2);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TaxCalcFA()
    var
        TaxCalcSectionCode: Code[10];
        TaxCalcHeaderNo: Code[10];
    begin
        // Setup:
        CreateTaxCalcSetupFA(TaxCalcSectionCode, TaxCalcHeaderNo);

        // Exercise:
        CreateTaxCalcAccum(TaxCalcSectionCode, false, true, false, false, WorkDate());

        // Verify:
        VerifyTaxCalcAccum(TaxCalcSectionCode, TaxCalcHeaderNo, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WriteOffForTaxLedger()
    begin
        // Check FA Ledger Entry created by Write-off in Tax Accounting report
        // Tax Depreciation Book G/L Integration = FALSE
        CreatePurchTaxWriteOffFA(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WriteOffForTaxLedgerGLIntegration()
    begin
        // Check FA Ledger Entry created by Write-off in Tax Accounting report
        // Tax Depreciation Book G/L Integration = TRUE
        CreatePurchTaxWriteOffFA(true);
    end;

    local procedure ClearTaxDiffJnlLine()
    var
        TaxDiffJnlLine: Record "Tax Diff. Journal Line";
    begin
        TaxDiffJnlLine.Init();
        TaxDiffJnlLine.DeleteAll();
        Commit();
    end;

    local procedure RunCalcTaxDiffDeprBonusReport(FixedAsset: Record "Fixed Asset"; StartDate: Date; EndDate: Date; TaxDiffJnlTemplateName: Code[10]; TaxDiffJnlBatchName: Code[10])
    var
        CalcTaxDiffDeprBonusReport: Report "Calc. Tax Diff.- Depr. Bonus";
    begin
        ClearTaxDiffJnlLine();
        FixedAsset.SetRange("No.", FixedAsset."No.");
        CalcTaxDiffDeprBonusReport.SetTableView(FixedAsset);
        CalcTaxDiffDeprBonusReport.InitializeRequest(
          StartDate, EndDate, TaxDiffJnlTemplateName, TaxDiffJnlBatchName);
        CalcTaxDiffDeprBonusReport.UseRequestPage(false);
        CalcTaxDiffDeprBonusReport.Run();
    end;

    local procedure RunCalcTaxDiffFAReport(FixedAsset: Record "Fixed Asset"; EndDate: Date; TaxDiffJnlTemplateName: Code[10]; TaxDiffJnlBatchName: Code[10])
    var
        CalcTaxDiffFAReport: Report "Calculate Tax Diff. for FA";
    begin
        ClearTaxDiffJnlLine();
        FixedAsset.SetRange("No.", FixedAsset."No.");
        CalcTaxDiffFAReport.SetTableView(FixedAsset);
        CalcTaxDiffFAReport.InitializeRequest(
          EndDate, TaxDiffJnlTemplateName, TaxDiffJnlBatchName);
        CalcTaxDiffFAReport.UseRequestPage(false);
        CalcTaxDiffFAReport.Run();
    end;

    local procedure RunCalcTaxDiffDisposedFAReport(FixedAsset: Record "Fixed Asset"; StartDate: Date; EndDate: Date; TaxDiffJnlTemplateName: Code[10]; TaxDiffJnlBatchName: Code[10])
    var
        CalcTaxDiffDisposedFAReport: Report "Calc. Tax Diff.- Disposed FA";
    begin
        ClearTaxDiffJnlLine();
        FixedAsset.SetRange("No.", FixedAsset."No.");
        CalcTaxDiffDisposedFAReport.SetTableView(FixedAsset);
        CalcTaxDiffDisposedFAReport.InitializeRequest(
          StartDate, EndDate, TaxDiffJnlTemplateName, TaxDiffJnlBatchName);
        CalcTaxDiffDisposedFAReport.UseRequestPage(false);
        CalcTaxDiffDisposedFAReport.Run();
    end;

    local procedure RunCalcTaxDiffDeprFEReport(FutureExpense: Record "Fixed Asset"; StartDate: Date; EndDate: Date; TaxDiffJnlTemplateName: Code[10]; TaxDiffJnlBatchName: Code[10])
    var
        CalcTaxDiffFEReport: Report "Calculate Tax Diff. for FE";
    begin
        ClearTaxDiffJnlLine();
        FutureExpense.SetRange("No.", FutureExpense."No.");
        CalcTaxDiffFEReport.SetTableView(FutureExpense);
        CalcTaxDiffFEReport.InitializeRequest(
          StartDate, EndDate, TaxDiffJnlTemplateName, TaxDiffJnlBatchName, true, true);
        CalcTaxDiffFEReport.UseRequestPage(false);
        CalcTaxDiffFEReport.Run();
    end;

    local procedure CreateTaxCalcAccum(TaxCalcSectionCode: Code[10]; UseGLEntry: Boolean; UseFAEntry: Boolean; UseItemEntry: Boolean; UseTemplate: Boolean; StartingDate: Date)
    var
        CalendarPeriod: Record Date;
        TaxCalcSection: Record "Tax Calc. Section";
        TaxCalcMgt: Codeunit "Tax Calc. Mgt.";
    begin
        TaxCalcSection.Get(TaxCalcSectionCode);
        TaxCalcSection.Validate(Status, TaxCalcSection.Status::Open);
        TaxCalcSection.Modify(true);

        CalendarPeriod.SetRange("Period Type", CalendarPeriod."Period Type"::Month);
        CalendarPeriod.SetRange("Period Start", CalcDate('<-CM>', StartingDate));
        CalendarPeriod.FindSet();
        CalendarPeriod.Next(0);
        TaxCalcMgt.CreateTaxCalcForPeriod(
          TaxCalcSectionCode, UseGLEntry, UseFAEntry, UseItemEntry, UseTemplate, CalendarPeriod);
    end;

    local procedure GetLastFALedgerEntryNo(): Integer
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        if FALedgerEntry.FindLast() then
            exit(FALedgerEntry."Entry No.");
        exit(0);
    end;

    local procedure InsertFALedgerEntry(var FALedgerEntry: Record "FA Ledger Entry"; FANo: Code[20]; DeprBookCode: Code[10]; FAPostingDate: Date; PostingDate: Date; FAPostingType: Enum "FA Ledger Entry FA Posting Type")
    begin
        FALedgerEntry.Init();
        FALedgerEntry."Entry No." := GetLastFALedgerEntryNo() + 1;
        FALedgerEntry."FA No." := FANo;
        FALedgerEntry."Depreciation Book Code" := DeprBookCode;
        FALedgerEntry."FA Posting Date" := FAPostingDate;
        FALedgerEntry."Posting Date" := PostingDate;
        FALedgerEntry."Part of Book Value" := true;
        FALedgerEntry."FA Posting Type" := FAPostingType;
        FALedgerEntry.Insert();
    end;

    local procedure CreateTaxDiffDeprBonusEntry(FANo: Code[20]; FAPostingDate: Date; PostingDate: Date; TaxDiffCode: Code[10]; EntryAmount: Decimal)
    var
        FALedgerEntry: Record "FA Ledger Entry";
        TaxRegisterSetup: Record "Tax Register Setup";
    begin
        TaxRegisterSetup.Get();
        InsertFALedgerEntry(
          FALedgerEntry, FANo, TaxRegisterSetup."Tax Depreciation Book", FAPostingDate, PostingDate,
          FALedgerEntry."FA Posting Type"::Depreciation);
        FALedgerEntry.Validate("Depr. Bonus", true);
        FALedgerEntry.Validate(Amount, EntryAmount);
        FALedgerEntry.Validate("Tax Difference Code", TaxDiffCode);
        FALedgerEntry.Modify(true);
    end;

    local procedure CreateTaxDiffFAEntry(FANo: Code[20]; FAPostingDate: Date; PostingDate: Date; TaxDiffCode: Code[10]; EntryAmount: Decimal)
    var
        FALedgerEntry: Record "FA Ledger Entry";
        FASetup: Record "FA Setup";
        TaxRegisterSetup: Record "Tax Register Setup";
    begin
        FASetup.Get();
        InsertFALedgerEntry(
          FALedgerEntry, FANo, FASetup."Release Depr. Book", FAPostingDate, PostingDate,
          FALedgerEntry."FA Posting Type"::"Acquisition Cost");
        FALedgerEntry.Validate(Amount, EntryAmount);
        FALedgerEntry.Validate("Tax Difference Code", TaxDiffCode);
        FALedgerEntry.Modify(true);

        TaxRegisterSetup.Get();
        InsertFALedgerEntry(
          FALedgerEntry, FANo, TaxRegisterSetup."Tax Depreciation Book", FAPostingDate, PostingDate,
          FALedgerEntry."FA Posting Type"::"Acquisition Cost");
        FALedgerEntry.Validate(Amount, EntryAmount / 2);
        FALedgerEntry.Validate("Tax Difference Code", TaxDiffCode);
        FALedgerEntry.Modify(true);
    end;

    local procedure CreateTaxDiffDisposalEntry(FANo: Code[20]; FAPostingDate: Date; PostingDate: Date; TaxDiffCode: Code[10]; EntryAmount: Decimal)
    var
        FALedgerEntry: Record "FA Ledger Entry";
        FASetup: Record "FA Setup";
        TaxRegisterSetup: Record "Tax Register Setup";
    begin
        FASetup.Get();
        InsertFALedgerEntry(
          FALedgerEntry, FANo, FASetup."Release Depr. Book", FAPostingDate, PostingDate,
          FALedgerEntry."FA Posting Type"::"Gain/Loss");
        FALedgerEntry.Validate(Amount, EntryAmount);
        FALedgerEntry.Validate("Tax Difference Code", TaxDiffCode);
        FALedgerEntry.Validate("Disposal Entry No.", 1);
        FALedgerEntry.Modify(true);

        TaxRegisterSetup.Get();
        InsertFALedgerEntry(
          FALedgerEntry, FANo, TaxRegisterSetup."Tax Depreciation Book", FAPostingDate, PostingDate,
          FALedgerEntry."FA Posting Type"::"Proceeds on Disposal");
        FALedgerEntry.Validate(Amount, EntryAmount / 2);
        FALedgerEntry.Validate("Tax Difference Code", TaxDiffCode);
        FALedgerEntry.Modify(true);

        InsertFALedgerEntry(
          FALedgerEntry, FANo, TaxRegisterSetup."Tax Depreciation Book", FAPostingDate, PostingDate,
          FALedgerEntry."FA Posting Type"::"Gain/Loss");
        FALedgerEntry.Validate(Amount, EntryAmount / 2);
        FALedgerEntry.Validate("Tax Difference Code", TaxDiffCode);
        FALedgerEntry.Validate("Disposal Entry No.", 1);
        FALedgerEntry.Modify(true);
    end;

    local procedure CreateTaxDiffFEDeprEntry(FANo: Code[20]; FAPostingDate: Date; PostingDate: Date; EntryAmount: Decimal)
    var
        FALedgerEntry: Record "FA Ledger Entry";
        FASetup: Record "FA Setup";
        TaxRegisterSetup: Record "Tax Register Setup";
    begin
        FASetup.Get();
        InsertFALedgerEntry(
          FALedgerEntry, FANo, FASetup."Future Depr. Book", FAPostingDate, PostingDate,
          FALedgerEntry."FA Posting Type"::Depreciation);
        FALedgerEntry.Validate(Amount, EntryAmount);
        FALedgerEntry.Modify(true);

        TaxRegisterSetup.Get();
        InsertFALedgerEntry(
          FALedgerEntry, FANo, TaxRegisterSetup."Future Exp. Depreciation Book", FAPostingDate, PostingDate,
          FALedgerEntry."FA Posting Type"::Depreciation);
        FALedgerEntry.Validate(Amount, EntryAmount / 2);
        FALedgerEntry.Modify(true);
    end;

    local procedure CreateFixedAsset(var FixedAsset: Record "Fixed Asset")
    var
        FADeprBook: Record "FA Depreciation Book";
        FASetup: Record "FA Setup";
        TaxRegisterSetup: Record "Tax Register Setup";
    begin
        LibraryTaxAcc.CreateFixedAsset(FixedAsset);

        FASetup.Get();
        if FASetup."Default Depr. Book" <> '' then
            LibraryFixedAsset.CreateFADepreciationBook(
              FADeprBook, FixedAsset."No.", FASetup."Default Depr. Book");
        if FASetup."Release Depr. Book" <> '' then
            LibraryFixedAsset.CreateFADepreciationBook(
              FADeprBook, FixedAsset."No.", FASetup."Release Depr. Book");
        TaxRegisterSetup.Get();
        if TaxRegisterSetup."Tax Depreciation Book" <> '' then
            LibraryFixedAsset.CreateFADepreciationBook(
              FADeprBook, FixedAsset."No.", TaxRegisterSetup."Tax Depreciation Book");
    end;

    local procedure CreateFutureExpense(var FutureExpense: Record "Fixed Asset")
    var
        FADeprBook: Record "FA Depreciation Book";
        FASetup: Record "FA Setup";
        TaxRegisterSetup: Record "Tax Register Setup";
    begin
        LibraryTaxAcc.CreateFutureExpense(FutureExpense);

        FASetup.Get();
        if FASetup."Future Depr. Book" <> '' then
            LibraryFixedAsset.CreateFADepreciationBook(
              FADeprBook, FutureExpense."No.", FASetup."Future Depr. Book");
        TaxRegisterSetup.Get();
        if TaxRegisterSetup."Future Exp. Depreciation Book" <> '' then
            LibraryFixedAsset.CreateFADepreciationBook(
              FADeprBook, FutureExpense."No.", TaxRegisterSetup."Future Exp. Depreciation Book");
    end;

    local procedure CreateTaxCalcSetupGL(var TaxCalcSectionCode: Code[10]; var TaxCalcHeaderNo: Code[10])
    var
        TaxCalcSection: Record "Tax Calc. Section";
        TaxCalcHeader: Record "Tax Calc. Header";
    begin
        LibraryTaxAcc.CreateTaxCalcSection(TaxCalcSection, WorkDate(), WorkDate());
        LibraryTaxAcc.CreateTaxCalcHeader(TaxCalcHeader, TaxCalcSection.Code, DATABASE::"Tax Calc. G/L Entry");
        TaxCalcSectionCode := TaxCalcSection.Code;
        TaxCalcHeaderNo := TaxCalcHeader."No.";

        CreateTaxCalcSelectionSetupGL(TaxCalcSection.Code, TaxCalcHeader."No.");
    end;

    local procedure CreateTaxCalcSelectionSetupGL(TaxCalcSectionCode: Code[10]; TaxCalcHeaderNo: Code[10])
    var
        TaxCalcSelectionSetup: Record "Tax Calc. Selection Setup";
        TaxCalcLine: Record "Tax Calc. Line";
        GLAccount: array[2] of Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount[1]);
        LibraryTaxAcc.CreateTaxCalcSelectionSetup(TaxCalcSelectionSetup, TaxCalcSectionCode, TaxCalcHeaderNo);
        TaxCalcSelectionSetup.Validate("Account No.", GLAccount[1]."No.");
        TaxCalcSelectionSetup.Modify(true);
        LibraryTaxAcc.CreateTaxCalcLine(
          TaxCalcLine, TaxCalcLine."Expression Type"::SumField, TaxCalcSectionCode, TaxCalcHeaderNo);

        LibraryERM.CreateGLAccount(GLAccount[2]);
        LibraryTaxAcc.CreateTaxCalcSelectionSetup(TaxCalcSelectionSetup, TaxCalcSectionCode, TaxCalcHeaderNo);
        TaxCalcSelectionSetup.Validate("Bal. Account No.", GLAccount[2]."No.");
        TaxCalcSelectionSetup.Modify(true);
        LibraryTaxAcc.CreateTaxCalcLine(
          TaxCalcLine, TaxCalcLine."Expression Type"::SumField, TaxCalcSectionCode, TaxCalcHeaderNo);

        CreateGLCorrEntry(GLAccount[1]."No.", GLAccount[2]."No.", WorkDate());
    end;

    local procedure GetLastGLCorrEntryNo(): Integer
    var
        GLCorrEntry: Record "G/L Correspondence Entry";
    begin
        if GLCorrEntry.FindLast() then
            exit(GLCorrEntry."Entry No.");
        exit(0);
    end;

    local procedure CreateGLCorrEntry(AccountNo: Code[20]; BalAccountNo: Code[20]; PostingDate: Date)
    var
        GLCorrEntry: Record "G/L Correspondence Entry";
    begin
        GLCorrEntry.Init();
        GLCorrEntry.Validate("Entry No.", GetLastGLCorrEntryNo() + 10000);
        GLCorrEntry.Validate("Posting Date", PostingDate);
        GLCorrEntry.Validate("Debit Account No.", AccountNo);
        GLCorrEntry.Validate("Credit Account No.", BalAccountNo);
        GLCorrEntry.Validate(Amount, 1000);
        GLCorrEntry.Insert(true);
    end;

    local procedure CreateTaxCalcSetupFA(var TaxCalcSectionCode: Code[10]; var TaxCalcHeaderNo: Code[10])
    var
        TaxCalcSection: Record "Tax Calc. Section";
        TaxCalcHeader: Record "Tax Calc. Header";
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        TaxCalcLine: Record "Tax Calc. Line";
        TaxCalcFAEntry: Record "Tax Calc. FA Entry";
        FASetup: Record "FA Setup";
        TaxRegisterSetup: Record "Tax Register Setup";
    begin
        LibraryTaxAcc.CreateTaxCalcSection(TaxCalcSection, WorkDate(), WorkDate());
        LibraryTaxAcc.CreateTaxCalcHeader(TaxCalcHeader, TaxCalcSection.Code, DATABASE::"Tax Calc. FA Entry");
        TaxCalcSectionCode := TaxCalcSection.Code;
        TaxCalcHeaderNo := TaxCalcHeader."No.";

        LibraryTaxAcc.CreateTaxCalcLine(
          TaxCalcLine, TaxCalcLine."Expression Type"::SumField, TaxCalcSectionCode, TaxCalcHeaderNo);
        TaxCalcLine.Validate("Sum Field No.", TaxCalcFAEntry.FieldNo("Depreciation Amount (Base)"));
        TaxCalcLine.Modify(true);

        LibraryTaxAcc.CreateAccDeprBook(DepreciationBook);
        FASetup.Get();
        FASetup.Validate("Release Depr. Book", DepreciationBook.Code);
        FASetup.Modify(true);
        LibraryTaxAcc.CreateTaxAccDeprBook(DepreciationBook);
        TaxRegisterSetup.Get();
        TaxRegisterSetup.Validate("Tax Depreciation Book", DepreciationBook.Code);
        TaxRegisterSetup.Modify(true);

        CreateFixedAsset(FixedAsset);
        CreateTaxCalcDeprEntry(FixedAsset."No.", WorkDate(), WorkDate());
    end;

    local procedure CreateTaxCalcDeprEntry(FANo: Code[20]; FAPostingDate: Date; PostingDate: Date)
    var
        FALedgerEntry: Record "FA Ledger Entry";
        FASetup: Record "FA Setup";
        TaxRegisterSetup: Record "Tax Register Setup";
    begin
        FASetup.Get();
        InsertFALedgerEntry(
          FALedgerEntry, FANo, FASetup."Release Depr. Book", FAPostingDate, PostingDate,
          FALedgerEntry."FA Posting Type"::Depreciation);
        FALedgerEntry.Validate(Amount, 1000);
        FALedgerEntry.Modify(true);
        TaxRegisterSetup.Get();
        InsertFALedgerEntry(
          FALedgerEntry, FANo, TaxRegisterSetup."Tax Depreciation Book", FAPostingDate, PostingDate,
          FALedgerEntry."FA Posting Type"::Depreciation);
        FALedgerEntry.Validate(Amount, 500);
        FALedgerEntry.Modify(true);
    end;

    local procedure CreateAndPostFAReleaseDoc(FANo: Code[20]; PostingDate: Date)
    var
        FADocumentHeader: Record "FA Document Header";
    begin
        LibraryFixedAsset.CreateFAReleaseDoc(FADocumentHeader, FANo, PostingDate);
        LibraryFixedAsset.PostFADocument(FADocumentHeader);
    end;

    local procedure CreateAndPostFAWriteOffDoc(FANo: Code[20]; PostingDate: Date): Code[20]
    var
        FADocumentHeader: Record "FA Document Header";
    begin
        LibraryFixedAsset.CreateFAWriteOffDoc(FADocumentHeader, FANo, PostingDate);
        exit(LibraryFixedAsset.PostFADocument(FADocumentHeader));
    end;

    local procedure VerifyTaxDiffJnl(TaxDiffJnlTemplateName: Code[10]; TaxDiffJnlBatchName: Code[10]; TaxDiffCode: Code[10]; ExpectedTaxDiffJnlLineCount: Integer)
    var
        TaxDiffJnlLine: Record "Tax Diff. Journal Line";
    begin
        TaxDiffJnlLine.SetRange("Journal Template Name", TaxDiffJnlTemplateName);
        TaxDiffJnlLine.SetRange("Journal Batch Name", TaxDiffJnlBatchName);
        if TaxDiffCode <> '' then
            TaxDiffJnlLine.SetRange("Tax Diff. Code", TaxDiffCode);
        Assert.AreEqual(ExpectedTaxDiffJnlLineCount, TaxDiffJnlLine.Count, TaxDiffJnlLineErr)
    end;

    local procedure VerifyTaxCalcAccum(SectionCode: Code[10]; RegisterNo: Code[10]; ExpectedLineCount: Integer)
    var
        TaxCalcAccum: Record "Tax Calc. Accumulation";
    begin
        TaxCalcAccum.SetRange("Section Code", SectionCode);
        TaxCalcAccum.SetRange("Register No.", RegisterNo);
        Assert.AreEqual(ExpectedLineCount, TaxCalcAccum.Count, TaxCalcAccumErr);
        if ExpectedLineCount <> 0 then begin
            TaxCalcAccum.FindSet();
            repeat
                Assert.AreNotEqual(0, TaxCalcAccum.Amount, TaxCalcAccumAmountErr);
            until TaxCalcAccum.Next() = 0;
        end;
    end;

    local procedure CreatePurchTaxWriteOffFA(GLIntegration: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PostedFADocHeader: Record "Posted FA Doc. Header";
        FALedgerEntry: Record "FA Ledger Entry";
        TaxRegisterSetup: Record "Tax Register Setup";
        WriteOffForTaxLedger: Report "Write-off for Tax Ledger";
        DocNo: Code[20];
    begin
        Initialize();
        if GLIntegration then
            TaxDeprBookGLIntegration(true);

        LibraryPurchase.CreatePurchaseInvoiceWithFixedAsset(PurchaseHeader, PurchaseLine, '', '');
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        CreateAndPostFAReleaseDoc(PurchaseLine."No.", WorkDate());
        DocNo := CreateAndPostFAWriteOffDoc(PurchaseLine."No.", WorkDate());
        PostedFADocHeader.Get(PostedFADocHeader."Document Type"::Writeoff, DocNo);
        PostedFADocHeader.SetRecFilter();

        WriteOffForTaxLedger.SetTableView(PostedFADocHeader);
        WriteOffForTaxLedger.InitializeRequest(false, 0D, true);
        WriteOffForTaxLedger.UseRequestPage(false);
        WriteOffForTaxLedger.Run();

        TaxRegisterSetup.Get();
        FALedgerEntry.SetRange("FA No.", PurchaseLine."No.");
        FALedgerEntry.SetRange("Depreciation Book Code", TaxRegisterSetup."Tax Depreciation Book");
        FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::"Proceeds on Disposal");
        Assert.IsFalse(FALedgerEntry.IsEmpty, EntryNotFoundErr);

        RestoreGLIntegration(GLIntegration);
    end;

    local procedure TaxDeprBookGLIntegration(IsGLIntegration: Boolean)
    var
        DeprBook: Record "Depreciation Book";
        TaxRegisterSetup: Record "Tax Register Setup";
    begin
        TaxRegisterSetup.Get();
        DeprBook.Get(TaxRegisterSetup."Tax Depreciation Book");
        DeprBook."G/L Integration - Acq. Cost" := IsGLIntegration;
        DeprBook."G/L Integration - Depreciation" := IsGLIntegration;
        DeprBook."G/L Integration - Disposal" := IsGLIntegration;
        DeprBook.Modify();
    end;

    local procedure RestoreGLIntegration(GLIntegration: Boolean)
    begin
        if not GLIntegration then
            exit;

        TaxDeprBookGLIntegration(false);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

