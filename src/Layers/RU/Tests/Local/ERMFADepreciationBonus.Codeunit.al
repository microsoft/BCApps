codeunit 144507 "ERM FA Depreciation Bonus"
{
    TestPermissions = NonRestrictive;
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        FAJournalNotEmptyErr: Label 'FA Journal is not empty';
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        TaxDeprBookCode: Code[10];
        IncorrectAmountErr: Label 'FA Ledger Entry line Amount value is incorrect';
        DeprBonusFieldErr: Label 'FA Ledger Entry line Depr. Bonus field value is incorrect';
        DeprBonusPctFieldErr: Label 'FA Depreciation Book Depr. Bonus % field value is incorrect';

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure FADeprBonusCheck()
    var
        FALedgerEntry: Record "FA Ledger Entry";
        FixedAssetNo: Code[20];
        FAPurchAmount: Decimal;
        FADeprBonusPct: Decimal;
        DeprAmount: Decimal;
    begin
        // Post FA Depreciation (Bonus). Chech FA Ledger Entry Amount of posted Depreciation
        FixedAssetNo := CreateCustFAPostDepr(false, false, 0, FAPurchAmount, FADeprBonusPct, DeprAmount);

        FindFADeprLedgerEntry(
          FixedAssetNo, FALedgerEntry, FALedgerEntry."FA Posting Type"::Depreciation);
        VerifyFALedgerEntry(
          FALedgerEntry,
          Round(-FAPurchAmount * (FADeprBonusPct / 100), LibraryERM.GetAmountRoundingPrecision()),
          true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure FADeprDoubleBonus()
    var
        FAJournalLine: Record "FA Journal Line";
        FixedAssetNo: Code[20];
        FADeprDate: Date;
        FAPurchAmount: Decimal;
        FADeprBonusPct: Decimal;
        DeprAmount: Decimal;
    begin
        // Post FA Depreciation (Bonus). Post FA Depreciation (Bonus) -
        // Check no more FA Depreciation Entries in FA Journal created
        FixedAssetNo := CreateCustFAPostDepr(false, false, 0, FAPurchAmount, FADeprBonusPct, DeprAmount);

        FADeprDate := CalcDate('<CM+2M>', WorkDate());
        CalcBonusDepreciation(
          FixedAssetNo, TaxDeprBookCode, FADeprDate, true);

        FAJournalLine.SetRange("FA Posting Date", FADeprDate);
        FAJournalLine.SetRange("FA No.", FixedAssetNo);
        FAJournalLine.SetRange("FA Posting Type", FAJournalLine."FA Posting Type"::Depreciation);
        Assert.IsTrue(FAJournalLine.IsEmpty, FAJournalNotEmptyErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure FADeprBonusNormDepr()
    var
        FALedgerEntry: Record "FA Ledger Entry";
        FixedAssetNo: Code[20];
        FAPurchAmount: Decimal;
        FADeprBonusPct: Decimal;
        DeprAmount: Decimal;
    begin
        // Post FA Depreciation (Bonus). Post original Depreciation
        // Check Bonus and Original Depreciations` Amounts.
        FixedAssetNo := CreateCustFAPostDepr(true, true, 0, FAPurchAmount, FADeprBonusPct, DeprAmount);

        FindFADeprLedgerEntry(FixedAssetNo, FALedgerEntry, FALedgerEntry."FA Posting Type"::Depreciation);
        VerifyFALedgerEntry(FALedgerEntry, -FAPurchAmount * (FADeprBonusPct / 100), true);
        FALedgerEntry.Next();
        VerifyFALedgerEntry(FALedgerEntry, DeprAmount, false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure FADeprBonusCheckAddAcqCostTAX()
    var
        FALedgerEntry: Record "FA Ledger Entry";
        FixedAssetNo: Code[20];
        FAPurchAmount: Decimal;
        FADeprBonusPct: Decimal;
        AddAcqCost: Decimal;
        DeprAmount: Decimal;
    begin
        // Post FA Additional Acquisition Cost before FA Release.
        // Post FA Depreciation (Bonus). Post original Depreciation.
        // Check Bonus and Original Depreciations` Amounts.
        AddAcqCost := LibraryRandom.RandDecInRange(100, 10000, 2);
        FixedAssetNo := CreateCustFAPostDepr(
            false, false, AddAcqCost, FAPurchAmount, FADeprBonusPct, DeprAmount);

        FindFADeprLedgerEntry(FixedAssetNo, FALedgerEntry, FALedgerEntry."FA Posting Type"::Depreciation);
        VerifyFALedgerEntry(
          FALedgerEntry,
          Round(-FAPurchAmount * (FADeprBonusPct / 100), LibraryERM.GetAmountRoundingPrecision()),
          true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure FADeprBonusAppreciationScenario()
    var
        FALedgerEntry: Record "FA Ledger Entry";
        FixedAssetNo: Code[20];
        FADeprDate: Date;
        FAPurchAmount: Decimal;
        FADeprBonusPct: Decimal;
        DeprAmount: array[7] of Decimal;
        AppreciationAmount: array[2] of Decimal;
        "Count": Integer;
    begin
        // Post FA Depreciation (Bonus). Post original Depreciation.
        // Post original Depreciation (+1M),  Post original Depreciation (+1M).
        // Post Appreciation (Bonus), Post Appeciation (Original).
        // Post FA Depreciation (Bonus). Post original Depreciation.
        // Check Bonus and Original Depreciations` Amounts.

        FixedAssetNo := CreateCustFAPostDepr(
            true, true, 0, FAPurchAmount, FADeprBonusPct, DeprAmount[2]);
        DeprAmount[1] := -FAPurchAmount * (FADeprBonusPct / 100);

        FADeprDate := CalcDate('<CM+3M>', WorkDate());
        DeprAmount[3] := CalcDepreciation(FixedAssetNo, TaxDeprBookCode, FADeprDate, true);
        FADeprDate := CalcDate('<CM+4M>', WorkDate());
        DeprAmount[4] := CalcDepreciation(FixedAssetNo, TaxDeprBookCode, FADeprDate, true);

        FADeprDate := CalcDate('<CM+5M>', WorkDate());
        AppreciationAmount[1] :=
          CreatePostFAAppreciation(
            FixedAssetNo, FAPurchAmount, TaxDeprBookCode,
            true, FADeprDate);

        AppreciationAmount[2] :=
          CreatePostFAAppreciation(
            FixedAssetNo, FAPurchAmount, TaxDeprBookCode,
            false, FADeprDate);

        DeprAmount[5] := CalcDepreciation(FixedAssetNo, TaxDeprBookCode, FADeprDate, true);
        FADeprDate := CalcDate('<CM+6M>', WorkDate());
        DeprAmount[6] := CalcBonusDepreciation(FixedAssetNo, TaxDeprBookCode, FADeprDate, true);
        DeprAmount[7] := CalcDepreciation(FixedAssetNo, TaxDeprBookCode, FADeprDate, true);

        FindFADeprLedgerEntry(FixedAssetNo, FALedgerEntry, FALedgerEntry."FA Posting Type"::Depreciation);
        repeat
            Count += 1;
            Assert.AreEqual(DeprAmount[Count], FALedgerEntry.Amount, IncorrectAmountErr);
        until FALedgerEntry.Next() = 0;

        FALedgerEntry.Reset();
        FALedgerEntry.SetRange("Depr. Bonus", true);
        FindFADeprLedgerEntry(FixedAssetNo, FALedgerEntry, FALedgerEntry."FA Posting Type"::Depreciation);
        Assert.AreEqual(DeprAmount[1], FALedgerEntry.Amount, IncorrectAmountErr);
        FALedgerEntry.Next();
        Assert.AreEqual(DeprAmount[6], FALedgerEntry.Amount, IncorrectAmountErr);
        FALedgerEntry.Reset();
        FindFADeprLedgerEntry(FixedAssetNo, FALedgerEntry, FALedgerEntry."FA Posting Type"::Appreciation);
        VerifyFALedgerEntry(FALedgerEntry, AppreciationAmount[1], false);
        FALedgerEntry.Next();
        VerifyFALedgerEntry(FALedgerEntry, AppreciationAmount[2], false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure FAMarkUnmarkAsDeprBonus()
    var
        FALedgerEntry: Record "FA Ledger Entry";
        FixedAssetNo: Code[20];
        FAPurchAmount: Decimal;
        FADeprBonusPct: Decimal;
        DeprAmount: Decimal;
        FADeprDate: Date;
    begin
        // Validate correctness of Mark/Unmark as Depreciation Bonus functionality
        FixedAssetNo := CreateCustFAPostDepr(true, true, 0, FAPurchAmount, FADeprBonusPct, DeprAmount);

        FADeprDate := CalcDate('<CM+2M+1D>', WorkDate());
        CreatePostFAAppreciation(
          FixedAssetNo, FAPurchAmount, TaxDeprBookCode,
          false, FADeprDate);

        FALedgEntryMarkUnmarkAsDeprBonus(FixedAssetNo, true);
        FALedgEntryMarkUnmarkAsDeprBonus(FixedAssetNo, false);

        FindFADeprLedgerEntry(FixedAssetNo, FALedgerEntry, FALedgerEntry."FA Posting Type"::Depreciation);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure FADeprBonusCancel()
    var
        FALedgerEntry: Record "FA Ledger Entry";
        FAJournalLine: Record "FA Journal Line";
        CancelFALedgerEntries: Codeunit "Cancel FA Ledger Entries";
        FixedAssetNo: Code[20];
        FADeprDate: Date;
        FAPurchAmount: Decimal;
        FADeprBonusPct: Decimal;
        DeprAmount: Decimal;
    begin
        // Post FA Depreciation (Bonus). Post original Depreciation.
        // Cancel posted Depreciations
        // Mark Acquistion cost as Bonus Base
        // Post FA Depreciation (Bonus). Post original Depreciation.
        // Check Bonus and Original Depreciations` Amounts.

        FixedAssetNo := CreateCustFAPostDepr(true, true, 0, FAPurchAmount, FADeprBonusPct, DeprAmount);

        FindFADeprLedgerEntry(FixedAssetNo, FALedgerEntry, FALedgerEntry."FA Posting Type"::Depreciation);
        CancelFALedgerEntries.TransferLine(FALedgerEntry, false, 0D);
        FAJournalLine.SetRange("FA No.", FixedAssetNo);
        SetFAJournalLineDocNo(FAJournalLine);
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
        FindFADeprLedgerEntry(FixedAssetNo, FALedgerEntry, FALedgerEntry."FA Posting Type"::"Acquisition Cost");
        FALedgerEntry.SetRange("Depreciation Book Code", TaxDeprBookCode);
        FALedgerEntry.FindLast();
        FALedgerEntry.UnMarkAsDeprBonusBase(FALedgerEntry, true);

        FADeprDate := CalcDate('<CM+2M>', WorkDate());
        CalcBonusDepreciation(FixedAssetNo, TaxDeprBookCode, FADeprDate, true);

        FindFADeprLedgerEntry(FixedAssetNo, FALedgerEntry, FALedgerEntry."FA Posting Type"::Depreciation);
        VerifyFALedgerEntry(FALedgerEntry, -FAPurchAmount * (FADeprBonusPct / 100), true);
        CalcDepreciation(FixedAssetNo, TaxDeprBookCode, FADeprDate, true);
        FALedgerEntry.Next();
        VerifyFALedgerEntry(FALedgerEntry, DeprAmount, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure FADeprBonusDeprGroup()
    var
        FADeprGroup: Record "Depreciation Group";
        Vendor: Record Vendor;
        FADeprBook: Record "FA Depreciation Book";
        FixedAssetNo: Code[20];
        FADeprBonusPct: Decimal;
    begin
        // Set Depr. Bonus % for specific Group
        // Assing the Group to Fixed Asset
        // Validate correct Depr. Bonus % from Group Assigned to Fixed Assset
        Setup();

        FADeprGroup.FindFirst();
        FADeprBonusPct := LibraryRandom.RandDec(99, 2);
        FADeprGroup.Validate("Depr. Bonus %", FADeprBonusPct);
        FADeprGroup.Modify();

        LibraryPurchase.CreateVendor(Vendor);
        FixedAssetNo := CreateFA(FADeprGroup.Code);
        FADeprBook.Get(FixedAssetNo, TaxDeprBookCode);
        Assert.AreEqual(FADeprBonusPct, FADeprBook."Depr. Bonus %", DeprBonusPctFieldErr);
    end;

    local procedure CreateFA(FADeprGroupCode: Code[10]): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
    begin
        LibraryFixedAsset.CreateFixedAssetWithSetup(FixedAsset);
        FixedAsset.Validate("Depreciation Group", FADeprGroupCode);
        FixedAsset.Modify(true);
        exit(FixedAsset."No.");
    end;

    local procedure SetRandFADeprBonus(FixedAssetNo: Code[20]): Integer
    var
        FADeprBook: Record "FA Depreciation Book";
    begin
        FADeprBook.Get(FixedAssetNo, TaxDeprBookCode);
        FADeprBook.Validate("Depr. Bonus %", LibraryRandom.RandIntInRange(1, 99));
        FADeprBook.Modify(true);
        exit(FADeprBook."Depr. Bonus %");
    end;

    local procedure AddPurchaseLine(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; Type: Enum "Purchase Line Type"; No: Code[20])
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(50));
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchInv(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; FixedAssetNo: Code[20]): Decimal
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        AddPurchaseLine(PurchaseHeader, PurchaseLine, PurchaseLine.Type::"Fixed Asset", FixedAssetNo);
        PurchaseHeader.CalcFields(Amount);
        exit(PurchaseHeader.Amount);
    end;

    [Test]
    [HandlerFunctions('ComparingDeprBookEntriesHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ComparingDeprBookEntriesReport()
    var
        FixedAsset: Record "Fixed Asset";
        ComparingDeprBookEntries: Report "Comparing Depr. Book Entries";
        FixedAssetNo1: Code[20];
        FixedAssetNo2: Code[20];
        FAPurchAmount1: Decimal;
        DeprAmount1: Decimal;
        FAPurchAmount2: Decimal;
        DeprAmount2: Decimal;
    begin
        // Verify Totals for Comparing Depr. Book Entries report
        FixedAssetNo1 := CreateFAWithAcquisitionDepreciation(FAPurchAmount1, DeprAmount1);
        FixedAssetNo2 := CreateFAWithAcquisitionDepreciation(FAPurchAmount2, DeprAmount2);

        Commit();
        Clear(ComparingDeprBookEntries);
        FixedAsset.SetFilter("No.", '%1|%2', FixedAssetNo1, FixedAssetNo2);
        ComparingDeprBookEntries.SetTableView(FixedAsset);
        ComparingDeprBookEntries.Run();

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          'Totals_1_Index__Acquisition_', FAPurchAmount1 + FAPurchAmount2);
        LibraryReportDataset.AssertElementWithValueExists(
          'Totals_2_Index__Depreciation_', DeprAmount1 + DeprAmount2);
        LibraryReportDataset.AssertElementWithValueExists(
          'Totals_2_Index___Book_Value__', FAPurchAmount1 + FAPurchAmount2 + DeprAmount1 + DeprAmount2);
    end;

    local procedure FindFADeprLedgerEntry(FixedAssetNo: Code[20]; var FALedgerEntry: Record "FA Ledger Entry"; FAPostingType: Enum "FA Ledger Entry FA Posting Type")
    begin
        FALedgerEntry.SetRange("FA No.", FixedAssetNo);
        FALedgerEntry.SetRange("FA Posting Type", FAPostingType);
        FALedgerEntry.FindFirst();
    end;

    local procedure VerifyFALedgerEntry(var FALedgerEntry: Record "FA Ledger Entry"; Amount: Decimal; IsBonus: Boolean)
    begin
        Assert.AreEqual(Amount, FALedgerEntry.Amount, IncorrectAmountErr);
        Assert.AreEqual(IsBonus, FALedgerEntry."Depr. Bonus", DeprBonusFieldErr);
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

    local procedure CreateCustFAPostDepr(CalcOriginalDepr: Boolean; PostOriginalDepr: Boolean; AddAcqCost: Decimal; var FAPurchAmount: Decimal; var FADeprBonusPct: Decimal; var OriginalDeprAmount: Decimal): Code[20]
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        FixedAssetNo: Code[20];
        FAReleaseDate: Date;
        FADeprDate: Date;
    begin
        Setup();
        FAReleaseDate := CalcDate('<CM+1M>', WorkDate());
        FADeprDate := CalcDate('<CM+2M>', WorkDate());
        LibraryPurchase.CreateVendor(Vendor);
        FixedAssetNo := CreateFA('');
        FADeprBonusPct := SetRandFADeprBonus(FixedAssetNo);
        FAPurchAmount := AddAcqCost + CreatePurchInv(PurchaseHeader, Vendor."No.", FixedAssetNo);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        if AddAcqCost <> 0 then
            CreatePostAddFAAcqCost(FixedAssetNo, WorkDate(), AddAcqCost);
        CreateAndPostFAReleaseDoc(FixedAssetNo, FAReleaseDate);
        LibraryFixedAsset.CalcDepreciation(FixedAssetNo, TaxDeprBookCode, FADeprDate, true, true);
        if CalcOriginalDepr then
            OriginalDeprAmount := LibraryFixedAsset.CalcDepreciation(FixedAssetNo, TaxDeprBookCode, FADeprDate, PostOriginalDepr, false);
        exit(FixedAssetNo);
    end;

    local procedure CreateFAJournalLine(var FAJournalLine: Record "FA Journal Line"; FANo: Code[20]; AmountValue: Decimal; DepreciationBookCode: Code[10]; DocumentType: Enum "FA Journal Line Document Type"; FAPostingType: Enum "FA Journal Line FA Posting Type")
    var
        FAJournalBatch: Record "FA Journal Batch";
    begin
        CreateFAJournalBatch(FAJournalBatch);
        LibraryFixedAsset.CreateFAJournalLine(FAJournalLine, FAJournalBatch."Journal Template Name", FAJournalBatch.Name);
        FAJournalLine.Validate("Document Type", DocumentType);
        FAJournalLine.Validate("Document No.", GetDocumentNo(FAJournalBatch));
        FAJournalLine.Validate("Posting Date", WorkDate());
        FAJournalLine.Validate("FA Posting Date", WorkDate());
        FAJournalLine.Validate("FA Posting Type", FAPostingType);
        FAJournalLine.Validate("FA No.", FANo);
        FAJournalLine.Validate(Amount, AmountValue);
        FAJournalLine.Validate("Depreciation Book Code", DepreciationBookCode);
        FAJournalLine.Modify(true);
    end;

    local procedure CreateFAJournalBatch(var FAJournalBatch: Record "FA Journal Batch")
    var
        FAJournalTemplate: Record "FA Journal Template";
    begin
        FAJournalTemplate.SetRange(Recurring, false);
        LibraryFixedAsset.FindFAJournalTemplate(FAJournalTemplate);
        LibraryFixedAsset.CreateFAJournalBatch(FAJournalBatch, FAJournalTemplate.Name);
        FAJournalBatch.Validate("No. Series", LibraryERM.CreateNoSeriesCode());
        FAJournalBatch.Modify(true);
    end;

    local procedure GetDocumentNo(FAJournalBatch: Record "FA Journal Batch"): Code[20]
    var
        NoSeries: Record "No. Series";
        NoSeriesCodeunit: Codeunit "No. Series";
    begin
        NoSeries.Get(FAJournalBatch."No. Series");
        exit(NoSeriesCodeunit.PeekNextNo(FAJournalBatch."No. Series"));
    end;

    local procedure CalcDepreciation(FixedAssetNo: Code[20]; DeprBook: Code[10]; PostingDate: Date; Post: Boolean): Decimal
    begin
        exit(LibraryFixedAsset.CalcDepreciation(FixedAssetNo, DeprBook, PostingDate, Post, false));
    end;

    local procedure CalcBonusDepreciation(FixedAssetNo: Code[20]; DeprBookCode: Code[10]; FADeprDate: Date; Post: Boolean): Decimal
    begin
        exit(LibraryFixedAsset.CalcDepreciation(FixedAssetNo, DeprBookCode, FADeprDate, Post, true));
    end;

    local procedure CreatePostFAAppreciation(FixedAssetNo: Code[20]; FAPurchAmount: Decimal; DeprBook: Code[10]; IsDeprBonus: Boolean; PostingDate: Date) AppreciationAmount: Decimal
    var
        FAJournalLine: Record "FA Journal Line";
    begin
        AppreciationAmount := LibraryRandom.RandDecInRange(1, FAPurchAmount, 2);
        CreateFAJournalLine(
          FAJournalLine, FixedAssetNo,
          AppreciationAmount, DeprBook,
          FAJournalLine."Document Type"::" ", FAJournalLine."FA Posting Type"::Appreciation);
        FAJournalLine.Validate("Depreciation Book Code", DeprBook);
        FAJournalLine.Validate("Depr. Bonus", IsDeprBonus);
        FAJournalLine.Validate("FA Posting Date", PostingDate);
        FAJournalLine.Validate("Posting Date", PostingDate);
        FAJournalLine.Modify(true);
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
    end;

    local procedure FALedgEntryMarkUnmarkAsDeprBonus(FixedAssetNo: Code[20]; Mark: Boolean)
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        FindFADeprLedgerEntry(FixedAssetNo, FALedgerEntry, FALedgerEntry."FA Posting Type"::Appreciation);
        FALedgerEntry.UnMarkAsDeprBonusBase(FALedgerEntry, Mark);

        FALedgerEntry.FindFirst();
        Assert.AreEqual(Mark, FALedgerEntry."Depr. Bonus", DeprBonusFieldErr);
    end;

    local procedure SetFAJournalLineDocNo(var FAJournalLine: Record "FA Journal Line")
    begin
        FAJournalLine.FindSet();
        repeat
            FAJournalLine."Document No." := FAJournalLine.Description;
            FAJournalLine.Modify();
        until FAJournalLine.Next() = 0;
    end;

    local procedure Setup()
    var
        TaxRegisterSetup: Record "Tax Register Setup";
        DeprBook: Record "Depreciation Book";
    begin
        TaxRegisterSetup.Get();
        TaxRegisterSetup."Rel. Act as Depr. Bonus Base" := true;
        TaxRegisterSetup.Modify(true);
        TaxDeprBookCode := TaxRegisterSetup."Tax Depreciation Book";
        DeprBook.Get(TaxDeprBookCode);
        DeprBook."Allow Identical Document No." := true;
        DeprBook.Modify();
    end;

    local procedure CreateFAWithAcquisitionDepreciation(var FAPurchAmount: Decimal; var DeprAmount: Decimal) FANo: Code[20]
    var
        TaxRegisterSetup: Record "Tax Register Setup";
        FADeprBook: Record "FA Depreciation Book";
        FADeprBonusPct: Decimal;
        OrigDeprAmount: Decimal;
    begin
        FANo := CreateCustFAPostDepr(true, true, 0, FAPurchAmount, FADeprBonusPct, OrigDeprAmount);

        TaxRegisterSetup.Get();
        FADeprBook.Get(FANo, TaxRegisterSetup."Tax Depreciation Book");
        FADeprBook.CalcFields(Depreciation);
        DeprAmount := FADeprBook.Depreciation;
    end;

    local procedure CreateAndPostFAReleaseDoc(FANo: Code[20]; PostingDate: Date)
    var
        FADocumentHeader: Record "FA Document Header";
    begin
        LibraryFixedAsset.CreateFAReleaseDoc(FADocumentHeader, FANo, PostingDate);
        LibraryFixedAsset.PostFADocument(FADocumentHeader);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ComparingDeprBookEntriesHandler(var ComparingDeprBookEntries: TestRequestPage "Comparing Depr. Book Entries")
    begin
        ComparingDeprBookEntries.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

