codeunit 144509 "ERM FA Depreciation Groups"
{
    TestPermissions = NonRestrictive;
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        OldWorkDate: Date;

    [Test]
    [HandlerFunctions('CalcGroupDeprRequestPage')]
    [Scope('OnPrem')]
    procedure FAGroupGLJournal()
    var
        FixedAsset: Record "Fixed Asset";
        FADeprGroupCode: Code[10];
        ReleaseDeprBookCode: Code[10];
        DocumentNo: Code[20];
        DeprDate: Date;
        NoOfFA: Integer;
    begin
        Initialize();

        OldWorkDate := WorkDate();
        WorkDate := CalcDate('<9M-10D>', OldWorkDate);
        ReleaseDeprBookCode := GetReleaseDeprBookCode();
        CreateReleaseCalculateFAGroup(FADeprGroupCode, NoOfFA, DeprDate, DocumentNo, true, false);

        FixedAsset.SetRange("Depreciation Group", FADeprGroupCode);
        Assert.AreEqual(NoOfFA, FixedAsset.Count, '');

        FixedAsset.FindSet();
        repeat
            VerifyFAGLJournal(
              DeprDate, DocumentNo, FixedAsset."No.", ReleaseDeprBookCode, CalcFADeprBookAmount(FixedAsset, ReleaseDeprBookCode));
        until FixedAsset.Next() = 0;
        WorkDate := OldWorkDate;
    end;

    [Test]
    [HandlerFunctions('CalcGroupDeprRequestPage')]
    [Scope('OnPrem')]
    procedure FAGroupPostedGLJournal()
    var
        FixedAsset: Record "Fixed Asset";
        FALedgerEntry: Record "FA Ledger Entry";
        FADeprGroupCode: Code[10];
        ReleaseDeprBookCode: Code[10];
        DocumentNo: Code[20];
        DeprDate: Date;
        NoOfFA: Integer;
    begin
        Initialize();

        OldWorkDate := WorkDate();
        WorkDate := CalcDate('<9M-10D>', OldWorkDate);
        ReleaseDeprBookCode := GetReleaseDeprBookCode();
        CreateReleaseCalculateFAGroup(FADeprGroupCode, NoOfFA, DeprDate, DocumentNo, true, true);

        FALedgerEntry.SetRange("Document No.", DocumentNo);
        FALedgerEntry.SetRange("Depreciation Group", FADeprGroupCode);
        Assert.AreEqual(NoOfFA, FALedgerEntry.Count, '');

        FixedAsset.SetRange("Depreciation Group", FADeprGroupCode);
        FixedAsset.FindSet();
        repeat
            VerifyFALedgerEntry(
              DeprDate, DocumentNo, FixedAsset."No.", ReleaseDeprBookCode, CalcFADeprBookAmount(FixedAsset, ReleaseDeprBookCode));
        until FixedAsset.Next() = 0;
        WorkDate := OldWorkDate;
    end;

    [Test]
    [HandlerFunctions('CalcGroupDeprRequestPage')]
    [Scope('OnPrem')]
    procedure FAGroupUnderMinGroupBalance()
    var
        FixedAsset: Record "Fixed Asset";
        FAGLJournalLine: Record "Gen. Journal Line";
        FADeprGroupCode: Code[10];
        DocumentNo: Code[20];
        DeprDate: Date;
        NoOfFA: Integer;
    begin
        Initialize();

        CreateReleaseCalculateFAGroup(FADeprGroupCode, NoOfFA, DeprDate, DocumentNo, false, false);

        FixedAsset.SetRange("Depreciation Group", FADeprGroupCode);
        Assert.AreEqual(NoOfFA, FixedAsset.Count, '');

        FAGLJournalLine.SetRange("Document No.", DocumentNo);
        Assert.IsTrue(FAGLJournalLine.IsEmpty, '');
    end;

    local procedure CreateReleaseCalculateFAGroup(var FADeprGroupCode: Code[10]; var NoOfFA: Integer; var DeprDate: Date; var DocumentNo: Code[20]; BalanceCompliant: Boolean; Post: Boolean)
    var
        GroupAmount: Decimal;
    begin
        FADeprGroupCode := CreateFADeprGroup();
        NoOfFA := LibraryRandom.RandIntInRange(5, 10);
        CreateCustFAPostDepr(GroupAmount, FADeprGroupCode, NoOfFA);
        DeprDate := CalcDate('<CM+2M>', WorkDate());
        if BalanceCompliant then
            SetMinGroupBalanceValue(GroupAmount)
        else
            SetMinGroupBalanceValue(GroupAmount + 0.01);
        CalcGroupDepreciation(DocumentNo, GetReleaseDeprBookCode(), DeprDate, Post, FADeprGroupCode);
    end;

    local procedure CreateFA(FADeprGroupCode: Code[10]): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
    begin
        LibraryFixedAsset.CreateFixedAssetWithSetup(FixedAsset);
        FixedAsset.Validate("Depreciation Group", FADeprGroupCode);
        FixedAsset.Modify(true);

        SetFADeprBookMethodDBSLRUTaxGroup(FixedAsset."No.");

        exit(FixedAsset."No.");
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        IsInitialized := true;

        UpdateTaxRegisterSetup();
    end;

    local procedure UpdateTaxRegisterSetup()
    var
        TaxRegisterSetup: Record "Tax Register Setup";
        FASetup: Record "FA Setup";
        DeprBook: Record "Depreciation Book";
    begin
        FASetup.Get();
        TaxRegisterSetup.Get();

        TaxRegisterSetup.Validate("Calculate TD for each FA", false);
        TaxRegisterSetup.Modify(true);

        DeprBook.Get(FASetup."Default Depr. Book");
        DeprBook.Validate("Control FA Acquis. Cost", false);
        DeprBook.Modify(true);

        TaxRegisterSetup.Validate("Use Group Depr. Method from", DMY2Date(1, 1, Date2DMY(WorkDate(), 3)));
        TaxRegisterSetup.Modify(true);

        DeprBook.Get(GetTaxDeprBookCode());
        DeprBook."Allow Identical Document No." := true;
        DeprBook.Modify(true);
    end;

    local procedure CreatePostAddFAAcqCost(FixedAssetNo: Code[20]; PostingDate: Date; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.FindGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name,
          GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"Fixed Asset", FixedAssetNo,
          Amount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("FA Posting Type", GenJournalLine."FA Posting Type"::"Acquisition Cost");
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());
        GenJournalLine.Modify(true);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateCustFAPostDepr(var GroupAmount: Decimal; FADeprGroupCode: Code[10]; NoOfFA: Integer)
    var
        Vendor: Record Vendor;
        FixedAssetNo: Code[20];
        FAReleaseDate: Date;
        Counter: Integer;
        AcqCostAmount: Decimal;
    begin
        FAReleaseDate := CalcDate('<CM+1M>', WorkDate());
        LibraryPurchase.CreateVendor(Vendor);
        for Counter := 1 to NoOfFA do begin
            FixedAssetNo := CreateFA(FADeprGroupCode);
            AcqCostAmount := LibraryRandom.RandDec(10000, 2);
            CreatePostAddFAAcqCost(FixedAssetNo, WorkDate(), AcqCostAmount);
            GroupAmount += AcqCostAmount;
            CreateAndPostFAReleaseDoc(FixedAssetNo, FAReleaseDate);
        end;
    end;

    local procedure CreateFADeprGroup(): Code[10]
    var
        FADeprGroup: Record "Depreciation Group";
    begin
        FADeprGroup.Init();
        FADeprGroup.Code := LibraryUtility.GenerateRandomCode(FADeprGroup.FieldNo(Code), DATABASE::"Depreciation Group");
        FADeprGroup."Tax Depreciation Rate" := LibraryRandom.RandDec(10, 2);
        FADeprGroup.Insert();
        exit(FADeprGroup.Code);
    end;

    local procedure GetReleaseDeprBookCode(): Code[10]
    var
        FASetup: Record "FA Setup";
    begin
        FASetup.Get();
        exit(FASetup."Release Depr. Book");
    end;

    local procedure GetTaxDeprBookCode(): Code[10]
    var
        TaxRegisterSetup: Record "Tax Register Setup";
    begin
        TaxRegisterSetup.Get();
        exit(TaxRegisterSetup."Tax Depreciation Book");
    end;

    local procedure GetFADeprBookAcquisitionCostAmount(FANo: Code[20]; DeprBookCode: Code[10]): Decimal
    var
        FADeprBook: Record "FA Depreciation Book";
    begin
        FADeprBook.Get(FANo, DeprBookCode);
        FADeprBook.CalcFields("Acquisition Cost");
        exit(FADeprBook."Acquisition Cost");
    end;

    local procedure SetFADeprBookMethodDBSLRUTaxGroup(FANo: Code[20])
    var
        FASetup: Record "FA Setup";
        FADeprBook: Record "FA Depreciation Book";
    begin
        FASetup.Get();
        FADeprBook.Get(FANo, FASetup."Release Depr. Book");
        FADeprBook.Validate("Depreciation Method", FADeprBook."Depreciation Method"::"DB/SL-RU Tax Group");
        FADeprBook.Modify(true);
    end;

    local procedure SetMinGroupBalanceValue(MinGroupBalance: Decimal)
    var
        TaxRegsterSetup: Record "Tax Register Setup";
    begin
        TaxRegsterSetup.Get();
        TaxRegsterSetup.Validate("Min. Group Balance", MinGroupBalance);
        TaxRegsterSetup.Modify(true);
    end;

    local procedure CalcGroupDepreciation(var DocumentNo: Code[20]; DeprBookCode: Code[10]; DeprDate: Date; Post: Boolean; DeprGroupCode: Code[10]) DeprAmount: Decimal
    var
        GenJournalLine: Record "Gen. Journal Line";
        FAJournalLine: Record "FA Journal Line";
        FADeprGroup: Record "Depreciation Group";
        CalcGroupDepr: Report "Calculate Group Depreciation";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        FAJnlPostLine: Codeunit "FA Jnl.-Post Line";
        AccPeriodAsText: Text;
    begin
        DocumentNo := 'DP-' + CopyStr(Format(Date2DMY(DeprDate, 3)), 3, 2) + '-' + Format(Date2DMY(DeprDate, 2));
        AccPeriodAsText := LowerCase(Format(DeprDate, 0, '<Month Text> <Year4>'));
        FADeprGroup.SetRange(Code, DeprGroupCode);
        CalcGroupDepr.SetTableView(FADeprGroup);

        LibraryVariableStorage.Enqueue(AccPeriodAsText);
        LibraryVariableStorage.Enqueue(DeprBookCode);
        Commit();
        CalcGroupDepr.Run();

        if Post then begin
            GenJournalLine.SetCurrentKey("Journal Template Name", "Journal Batch Name", "Posting Date");
            GenJournalLine.SetRange("Posting Date", DeprDate);
            GenJournalLine.SetRange("Document No.", DocumentNo);
            if GenJournalLine.FindSet() then begin
                repeat
                    GenJnlPostLine.RunWithCheck(GenJournalLine);
                    DeprAmount := GenJournalLine.Amount;
                until GenJournalLine.Next() = 0;
                GenJournalLine.DeleteAll();
            end;

            FAJournalLine.SetRange("FA Posting Date", DeprDate);
            FAJournalLine.SetRange("Document No.", DocumentNo);
            if FAJournalLine.FindSet() then begin
                repeat
                    FAJnlPostLine.FAJnlPostLine(FAJournalLine, true);
                    DeprAmount := FAJournalLine.Amount;
                until FAJournalLine.Next() = 0;
                FAJournalLine.DeleteAll();
            end;
        end;
    end;

    local procedure CalcFADeprBookAmount(FixedAsset: Record "Fixed Asset"; DeprBookCode: Code[10]): Decimal
    var
        FADeprGroup: Record "Depreciation Group";
    begin
        FADeprGroup.Get(FixedAsset."Depreciation Group");
        exit(-Round(GetFADeprBookAcquisitionCostAmount(FixedAsset."No.", DeprBookCode) * FADeprGroup."Tax Depreciation Rate" * 0.01));
    end;

    local procedure CreateAndPostFAReleaseDoc(FANo: Code[20]; PostingDate: Date)
    var
        FADocumentHeader: Record "FA Document Header";
    begin
        LibraryFixedAsset.CreateFAReleaseDoc(FADocumentHeader, FANo, PostingDate);
        LibraryFixedAsset.PostFADocument(FADocumentHeader);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalcGroupDeprRequestPage(var CalcGroupDeprReqPage: TestRequestPage "Calculate Group Depreciation")
    var
        FieldValue: Variant;
    begin
        LibraryVariableStorage.Dequeue(FieldValue);
        CalcGroupDeprReqPage.AccountPeriod.SetValue(FieldValue);
        LibraryVariableStorage.Dequeue(FieldValue);
        CalcGroupDeprReqPage.DeprBookCode.SetValue(FieldValue);
        CalcGroupDeprReqPage.OK().Invoke();
    end;

    local procedure VerifyFAGLJournal(PostingDate: Date; DocumentNo: Code[20]; FANo: Code[20]; FADeprBookCode: Code[10]; ExpectedAmount: Decimal)
    var
        FAGLJournalLine: Record "Gen. Journal Line";
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        FAGLJournalLine.SetRange("Posting Date", PostingDate);
        FAGLJournalLine.SetRange("Document No.", DocumentNo);
        FAGLJournalLine.SetRange("Account Type", FAGLJournalLine."Account Type"::"Fixed Asset");
        FAGLJournalLine.SetRange("Account No.", FANo);
        FAGLJournalLine.SetRange("Depreciation Book Code", FADeprBookCode);
        FAGLJournalLine.FindFirst();
        Assert.AreNearlyEqual(ExpectedAmount, FAGLJournalLine.Amount, GLSetup."Amount Rounding Precision", FAGLJournalLine.FieldCaption(Amount));
    end;

    local procedure VerifyFALedgerEntry(PostingDate: Date; DocumentNo: Code[20]; FANo: Code[20]; FADeprBookCode: Code[10]; ExpectedAmount: Decimal)
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        FALedgerEntry.SetRange("FA Posting Date", PostingDate);
        FALedgerEntry.SetRange("Document No.", DocumentNo);
        FALedgerEntry.SetRange("FA No.", FANo);
        FALedgerEntry.SetRange("Depreciation Book Code", FADeprBookCode);
        FALedgerEntry.FindFirst();
        Assert.AreNearlyEqual(ExpectedAmount, FALedgerEntry.Amount, 0.01, FALedgerEntry.FieldCaption(Amount));
    end;
}

