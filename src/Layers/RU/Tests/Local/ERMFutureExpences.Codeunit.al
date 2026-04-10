codeunit 144010 "ERM Future Expences"
{
    TestPermissions = NonRestrictive;
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        FutureExpenseNotFoundErr: Label 'Future Expense not found';

    [Test]
    [HandlerFunctions('CalcFEDeprReportHandler,SelectPeriodPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyFEDepreciationWithAnyEndingDate()
    begin
        // Verify FE Depreciation with any Ending Date
        CalculateFEDepreciationWithEndDate('');
    end;

    [Test]
    [HandlerFunctions('CalcFEDeprReportHandler,SelectPeriodPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyFEDepreciationWithEndingDateEqFirstDay()
    begin
        // Verify FE Depreciation with Ending Date equals to 1st day of month
        CalculateFEDepreciationWithEndDate('-CM+');
    end;

    [Test]
    [HandlerFunctions('CalcFEDeprReportHandler,SelectPeriodPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyFEDepreciationWithAddAquisitionCost()
    var
        FADeprBook: Record "FA Depreciation Book";
        VendorNo: Code[20];
        PurchaseDate: Date;
        StartDeprDate: Date;
        EndDeprDate: Date;
        AddAcqCostDate: Date;
        DeprAmounts: array[10] of Decimal;
        DeprDates: array[10] of Date;
        MonthQty1: Integer;
        MonthQty2: Integer;
        Index: Integer;
        i: Integer;
    begin
        // Verify FE Depreciation with additional aquisition cost
        MonthQty1 := LibraryRandom.RandIntInRange(2, 4);
        MonthQty2 := LibraryRandom.RandIntInRange(2, 4);
        InitDeprDates(PurchaseDate, StartDeprDate, EndDeprDate, MonthQty1 + MonthQty2, '');
        // AddAcqCostDate is a 1st day of month
        AddAcqCostDate := CalcDate('<' + Format(MonthQty1) + 'M-CM>', PurchaseDate);

        VendorNo := CreateFEAndPostInvoice(FADeprBook, StartDeprDate, EndDeprDate, PurchaseDate);

        // calculate FE Depreciation for full months before AddAcqCostDate
        for i := 0 to MonthQty1 - 1 do
            CalcFEDepreciationWithExpectedAmounts(
              DeprAmounts, DeprDates, FADeprBook,
              CalcDate('<' + Format(i) + 'M+CM>', PurchaseDate), 0D, Index);

        CreatePostAddFAAcqCost(
          FADeprBook."FA No.", FADeprBook."Depreciation Book Code", VendorNo, AddAcqCostDate, LibraryRandom.RandDecInRange(100, 1000, 2));

        // calculate FE Depreciation after AddAcqCostDate
        for i := MonthQty1 to MonthQty1 + MonthQty2 do
            CalcFEDepreciationWithExpectedAmounts(
              DeprAmounts, DeprDates, FADeprBook, CalcDate('<' + Format(i) + 'M+CM>', PurchaseDate), 0D, Index);

        VerifyFEDepreciation(FADeprBook, DeprAmounts, DeprDates);
    end;

    [Test]
    [HandlerFunctions('CalcFEDeprReportHandler,SelectPeriodPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyFEDepreciationWithAddAquisitionCostInMidMonth()
    var
        FADeprBook: Record "FA Depreciation Book";
        VendorNo: Code[20];
        PurchaseDate: Date;
        StartDeprDate: Date;
        EndDeprDate: Date;
        AddAcqCostDate: Date;
        DeprAmounts: array[10] of Decimal;
        DeprDates: array[10] of Date;
        MonthQty1: Integer;
        MonthQty2: Integer;
        Index: Integer;
        i: Integer;
    begin
        // Verify FE Depreciation with additional aquisition cost and depreciation in the middle of the month
        MonthQty1 := LibraryRandom.RandIntInRange(2, 4);
        MonthQty2 := LibraryRandom.RandIntInRange(2, 4);
        InitDeprDates(PurchaseDate, StartDeprDate, EndDeprDate, MonthQty1 + MonthQty2, '');
        // AddAcqCostDate is not a 1st day of month
        AddAcqCostDate :=
          CalcDate('<' + Format(MonthQty1) + 'M-CM+>' + Format(LibraryRandom.RandIntInRange(1, 5)) + 'D>', PurchaseDate);

        VendorNo := CreateFEAndPostInvoice(FADeprBook, StartDeprDate, EndDeprDate, PurchaseDate);

        // calculate FE Depreciation for full months before AddAcqCostDate
        for i := 0 to MonthQty1 - 1 do
            CalcFEDepreciationWithExpectedAmounts(
              DeprAmounts, DeprDates, FADeprBook, CalcDate('<' + Format(i) + 'M+CM>', PurchaseDate), 0D, Index);

        // calculate FE Depreciation on AddAcqCostDate-1 day inside month of AddAcquisition
        CalcFEDepreciationWithExpectedAmounts(
          DeprAmounts, DeprDates, FADeprBook,
          CalcDate('<' + Format(MonthQty1) + 'M+CM>', PurchaseDate), CalcDate('<-1D>', AddAcqCostDate), Index);

        CreatePostAddFAAcqCost(
          FADeprBook."FA No.", FADeprBook."Depreciation Book Code", VendorNo, AddAcqCostDate, LibraryRandom.RandDecInRange(100, 1000, 2));

        // calculate FE Depreciation after AddAcqCostDate
        for i := MonthQty1 to MonthQty1 + MonthQty2 do
            CalcFEDepreciationWithExpectedAmounts(
              DeprAmounts, DeprDates, FADeprBook, CalcDate('<' + Format(i) + 'M+CM>', PurchaseDate), 0D, Index);

        VerifyFEDepreciation(FADeprBook, DeprAmounts, DeprDates);
    end;

    [Test]
    [HandlerFunctions('CreateFEfromSoldFAHandler')]
    [Scope('OnPrem')]
    procedure CreateFEFromSoldFAGLIntegrationTrue()
    begin
        // Create Future Expense from Fixed Asset
        // G/L Integration = TRUE
        CreateFEFromSoldFA(true);
    end;

    [Test]
    [HandlerFunctions('CreateFEfromSoldFAHandler')]
    [Scope('OnPrem')]
    procedure CreateFEFromSoldFAGLIntegrationFalse()
    begin
        // Create Future Expense from Fixed Asset
        // G/L Integration = FALSE
        CreateFEFromSoldFA(false);
    end;

    local procedure InitDeprDates(var PurchaseDate: Date; var StartDeprDate: Date; var EndDeprDate: Date; MonthQty: Integer; AddCalcFormula: Text)
    begin
        PurchaseDate := CalcDate('<-CM+' + Format(LibraryRandom.RandIntInRange(1, 10)) + 'D>', WorkDate());
        StartDeprDate := CalcDate('<' + Format(LibraryRandom.RandIntInRange(1, 10)) + 'D>', PurchaseDate);
        EndDeprDate := CalcDate('<' + AddCalcFormula + Format(MonthQty) + 'M>', PurchaseDate);
    end;

    local procedure CalculateFEDepreciationWithEndDate(AddCalcFormula: Text)
    var
        FADeprBook: Record "FA Depreciation Book";
        PurchaseDate: Date;
        StartDeprDate: Date;
        EndDeprDate: Date;
        DeprAmounts: array[10] of Decimal;
        DeprDates: array[10] of Date;
        MonthQty: Integer;
        Index: Integer;
        i: Integer;
    begin
        MonthQty := LibraryRandom.RandIntInRange(4, 6);
        InitDeprDates(PurchaseDate, StartDeprDate, EndDeprDate, MonthQty, AddCalcFormula);
        CreateFEAndPostInvoice(FADeprBook, StartDeprDate, EndDeprDate, PurchaseDate);

        for i := 0 to MonthQty do
            CalcFEDepreciationWithExpectedAmounts(
              DeprAmounts, DeprDates, FADeprBook, CalcDate('<' + Format(i) + 'M+CM>', PurchaseDate), 0D, Index);

        VerifyFEDepreciation(FADeprBook, DeprAmounts, DeprDates);
    end;

    local procedure CreateFEAndPostInvoice(var FADeprBook: Record "FA Depreciation Book"; StartDeprDate: Date; EndDeprDate: Date; PurchaseDate: Date): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        CreateFEAsset(FADeprBook, StartDeprDate, EndDeprDate);
        CreateAndPostPurchInv(Vendor."No.", FADeprBook."FA No.", PurchaseDate);
        exit(Vendor."No.");
    end;

    local procedure CreateFEAsset(var FADeprBook: Record "FA Depreciation Book"; StartDeprDate: Date; EndDeprDate: Date)
    var
        FA: Record "Fixed Asset";
        FAPostingGroup: Record "FA Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        FA.Init();
        FA.Validate("FA Type", FA."FA Type"::"Future Expense");
        FA.Insert(true);

        FADeprBook.SetRange("FA No.", FA."No.");
        FADeprBook.FindFirst();
        FADeprBook.Validate("Depreciation Starting Date", StartDeprDate);
        FADeprBook.Validate("Depreciation Ending Date", EndDeprDate);
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        LibraryERM.FindVATPostingSetupInvt(VATPostingSetup);
        LibraryFixedAsset.UpdateFAPostingGroupGLAccounts(FAPostingGroup, VATPostingSetup);
        FADeprBook.Validate("FA Posting Group", FAPostingGroup.Code);
        FADeprBook.Validate("Depreciation Method", FADeprBook."Depreciation Method"::"Straight-Line");
        FADeprBook.Modify(true);
        UpdateRoundingForDeprBook(FADeprBook."Depreciation Book Code");
    end;

    local procedure UpdateRoundingForDeprBook(DeprBookCode: Code[10])
    var
        DeprBook: Record "Depreciation Book";
    begin
        DeprBook.Get(DeprBookCode);
        DeprBook.Validate("Use Rounding in Periodic Depr.", true);
        DeprBook.Modify(true);
    end;

    local procedure CreateAndPostPurchInv(VendorNo: Code[20]; FixedAssetNo: Code[20]; PurchaseDate: Date)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        PurchaseHeader.Validate("Posting Date", PurchaseDate);
        PurchaseHeader.Modify(true);

        AddPurchaseLine(PurchaseHeader, PurchaseLine, PurchaseLine.Type::"Fixed Asset", FixedAssetNo);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure AddPurchaseLine(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; Type: Enum "Purchase Line Type"; No: Code[20])
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(100, 1000, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePostAddFAAcqCost(FANo: Code[20]; DeprBookCode: Code[10]; BalAccountNo: Code[20]; PostingDate: Date; AcqAmount: Decimal)
    var
        FAJnlSetup: Record "FA Journal Setup";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        GLAccount: Record "G/L Account";
        DocumentNo: Code[20];
    begin
        FAJnlSetup.Get(DeprBookCode, '');
        GenJnlBatch.Get(FAJnlSetup."Gen. Jnl. Template Name", FAJnlSetup."Gen. Jnl. Batch Name");
        LibraryERM.ClearGenJournalLines(GenJnlBatch);
        GenJnlLine."Journal Template Name" := FAJnlSetup."Gen. Jnl. Template Name";
        GenJnlLine."Journal Batch Name" := FAJnlSetup."Gen. Jnl. Batch Name";
        Vendor.Get(BalAccountNo);
        GetFAAcquisitionPostingGroups(GLAccount, FANo, DeprBookCode);

        // create g/l line
        LibraryERM.CreateGeneralJnlLine(
          GenJnlLine, GenJnlBatch."Journal Template Name", GenJnlBatch.Name,
          GenJnlLine."Document Type"::" ", GenJnlLine."Account Type"::"Fixed Asset", FANo,
          AcqAmount);
        GenJnlLine.Validate("Posting Date", PostingDate);
        GenJnlLine.Validate("FA Posting Type", GenJnlLine."FA Posting Type"::"Acquisition Cost");
        GenJnlLine.Validate("Depreciation Book Code", DeprBookCode);
        GenJnlLine.Validate("Gen. Posting Type", GenJnlLine."Gen. Posting Type"::Purchase);
        GenJnlLine.Validate("Gen. Bus. Posting Group", Vendor."Gen. Bus. Posting Group");
        GenJnlLine.Validate("Gen. Prod. Posting Group", GLAccount."Gen. Prod. Posting Group");
        GenJnlLine.Validate("VAT Bus. Posting Group", Vendor."VAT Bus. Posting Group");
        GenJnlLine.Validate("VAT Prod. Posting Group", GLAccount."VAT Prod. Posting Group");
        GenJnlLine.Modify(true);
        DocumentNo := GenJnlLine."Document No.";
        // create g/l bal. line
        LibraryERM.CreateGeneralJnlLine(
          GenJnlLine, GenJnlBatch."Journal Template Name", GenJnlBatch.Name,
          GenJnlLine."Document Type"::" ", GenJnlLine."Account Type"::Vendor, BalAccountNo,
          -AcqAmount);
        GenJnlLine.Validate("Posting Date", PostingDate);
        GenJnlLine.Validate("Document No.", DocumentNo);
        GenJnlLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJnlLine);
    end;

    local procedure GetFAAcquisitionPostingGroups(var GLAccount: Record "G/L Account"; FANo: Code[20]; DeprBookCode: Code[10])
    var
        FADepreciationBook: Record "FA Depreciation Book";
        FAPostingGr: Record "FA Posting Group";
    begin
        FADepreciationBook.Get(FANo, DeprBookCode);
        FAPostingGr.Get(FADepreciationBook."FA Posting Group");
        GLAccount.Get(FAPostingGr."Acquisition Cost Account");
    end;

    local procedure CalcFEDepreciationWithExpectedAmounts(var DeprAmounts: array[10] of Decimal; var DeprDates: array[10] of Date; FADeprBook: Record "FA Depreciation Book"; EndPeriodDate: Date; EndDeprDate: Date; var i: Integer)
    begin
        CalcExpectedDeprAmount(DeprAmounts, DeprDates, FADeprBook, EndPeriodDate, EndDeprDate, i);
        CalcAndPostFEDepreciation(FADeprBook, EndPeriodDate, EndDeprDate, true);
    end;

    local procedure CalcAndPostFEDepreciation(FADeprBook: Record "FA Depreciation Book"; EndPeriodDate: Date; DeprPostingDate: Date; Post: Boolean)
    var
        FAJnlSetup: Record "FA Journal Setup";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        FAJnlSetup.Get(FADeprBook."Depreciation Book Code", '');
        GenJnlBatch.Get(FAJnlSetup."Gen. Jnl. Template Name", FAJnlSetup."Gen. Jnl. Batch Name");
        LibraryERM.ClearGenJournalLines(GenJnlBatch);

        RunCalcFEDepreciation(FADeprBook."FA No.", FADeprBook."Depreciation Book Code", EndPeriodDate, DeprPostingDate);

        GenJnlLine."Journal Template Name" := FAJnlSetup."Gen. Jnl. Template Name";
        GenJnlLine."Journal Batch Name" := FAJnlSetup."Gen. Jnl. Batch Name";
        if Post then
            LibraryERM.PostGeneralJnlLine(GenJnlLine);
    end;

    local procedure RunCalcFEDepreciation(FANo: Code[20]; DeprBookCode: Code[10]; EndPeriodDate: Date; DeprPostingDate: Date)
    var
        FEAsset: Record "Fixed Asset";
        CalcFEDeprReport: Report "Calculate FE Depreciation";
    begin
        Commit();
        LibraryVariableStorage.Enqueue(DeprBookCode);
        LibraryVariableStorage.Enqueue(EndPeriodDate);
        LibraryVariableStorage.Enqueue(DeprPostingDate);

        FEAsset.SetRange("No.", FANo);
        Clear(CalcFEDeprReport);
        CalcFEDeprReport.SetTableView(FEAsset);
        CalcFEDeprReport.Run();
    end;

    local procedure CalcFeDeprUpdateDetails(var CalcFEDeprReport: TestRequestPage "Calculate FE Depreciation"; DeprPostingDate: Date)
    begin
        if DeprPostingDate = 0D then
            exit;

        CalcFEDeprReport.ChangeDetails.SetValue(true);
        CalcFEDeprReport.DeprDate.SetValue(DeprPostingDate);
        CalcFEDeprReport.PostDate.SetValue(DeprPostingDate);
        CalcFEDeprReport.DocNo.SetValue(PadStr('', LibraryRandom.RandIntInRange(3, 10), '0'));
        CalcFEDeprReport.UseNumbDays.SetValue(false);
    end;

    local procedure CalcExpectedDeprAmount(var DeprAmounts: array[10] of Decimal; var DeprDates: array[10] of Date; FADeprBook: Record "FA Depreciation Book"; EndPeriodDay: Date; DeprDate: Date; var i: Integer)
    var
        DeprBook: Record "Depreciation Book";
        StartDate: Date;
        DeprAmount: Decimal;
        NumberOfDays: Integer;
        RemainingDays: Integer;
    begin
        FADeprBook.CalcFields("Book Value");
        DeprBook.Get(FADeprBook."Depreciation Book Code");

        StartDate := GetDeprStartDate(FADeprBook."FA No.", FADeprBook."Depreciation Starting Date");
        if DeprDate = 0D then
            DeprDate := EndPeriodDay;
        if CalcDate('<-CM>', StartDate) <> CalcDate('<-CM>', DeprDate) then
            StartDate := CalcDate('<-CM>', DeprDate);
        NumberOfDays := DeprDate - StartDate + 1;
        RemainingDays := FADeprBook."Depreciation Ending Date" - StartDate + 1;

        DeprAmount := -Round(FADeprBook."Book Value" * NumberOfDays / RemainingDays, 1);

        if FADeprBook."Book Value" + DeprAmount < DeprBook."Default Final Rounding Amount" then
            DeprAmount := -FADeprBook."Book Value";

        i += 1;
        DeprAmounts[i] := DeprAmount;
        DeprDates[i] := DeprDate;
    end;

    local procedure GetDeprStartDate(FANo: Code[20]; DeprStartDate: Date): Date
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        FilterFALedgerEntries(FALedgerEntry, FANo);
        if FALedgerEntry.FindLast() then
            exit(CalcDate('<1D>', FALedgerEntry."FA Posting Date"));

        exit(DeprStartDate);
    end;

    local procedure FilterFALedgerEntries(var FALedgerEntry: Record "FA Ledger Entry"; FANo: Code[20])
    begin
        FALedgerEntry.SetRange("FA No.", FANo);
        FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::Depreciation);
    end;

    local procedure CreateAndPostFAReleaseDoc(FANo: Code[20]; PostingDate: Date)
    var
        FADocumentHeader: Record "FA Document Header";
    begin
        LibraryFixedAsset.CreateFAReleaseDoc(FADocumentHeader, FANo, PostingDate);
        LibraryFixedAsset.PostFADocument(FADocumentHeader);
    end;

    local procedure CreateAndPostFAWriteOffDoc(FANo: Code[20]; PostingDate: Date)
    var
        FADocumentHeader: Record "FA Document Header";
    begin
        LibraryFixedAsset.CreateFAWriteOffDoc(FADocumentHeader, FANo, PostingDate);
        LibraryFixedAsset.PostFADocument(FADocumentHeader);
    end;

    local procedure VerifyFEDepreciation(FADeprBook: Record "FA Depreciation Book"; DeprAmounts: array[10] of Decimal; DeprDates: array[10] of Date)
    begin
        VerifyVATEntry(FADeprBook."FA No.");
        VerifyFALedgerEntry(FADeprBook."FA No.", DeprAmounts, DeprDates);

        FADeprBook.CalcFields("Acquisition Cost", Depreciation);
        Assert.AreEqual(FADeprBook."Acquisition Cost", -FADeprBook.Depreciation, FADeprBook.FieldCaption(Depreciation));
    end;

    local procedure VerifyVATEntry(FANo: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Object Type", VATEntry."Object Type"::"Fixed Asset");
        VATEntry.SetRange("Object No.", FANo);
        VATEntry.FindSet();
        repeat
            Assert.AreEqual(VATEntry."VAT Settlement Type"::"Future Expenses", VATEntry."VAT Settlement Type", VATEntry.FieldCaption("VAT Settlement Type"));
        until VATEntry.Next() = 0;
    end;

    local procedure VerifyFALedgerEntry(FANo: Code[20]; DeprAmounts: array[10] of Decimal; DeprDates: array[10] of Date)
    var
        FALedgerEntry: Record "FA Ledger Entry";
        i: Integer;
    begin
        FilterFALedgerEntries(FALedgerEntry, FANo);
        FALedgerEntry.FindSet();
        repeat
            i += 1;
            Assert.AreEqual(DeprAmounts[i], FALedgerEntry.Amount, FALedgerEntry.FieldCaption(Amount));
            Assert.AreEqual(DeprDates[i], FALedgerEntry."Posting Date", FALedgerEntry.FieldCaption("Posting Date"));
        until FALedgerEntry.Next() = 0;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalcFEDeprReportHandler(var CalcFEDepr: TestRequestPage "Calculate FE Depreciation")
    var
        FADeprBookCode: Variant;
        DeprPostingDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(FADeprBookCode);

        CalcFEDepr.DepreciationBookFilter.SetValue(FADeprBookCode);
        CalcFEDepr.AccountingPeriod.Lookup();

        LibraryVariableStorage.Dequeue(DeprPostingDate);
        CalcFeDeprUpdateDetails(CalcFEDepr, DeprPostingDate);

        CalcFEDepr.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectPeriodPageHandler(var SelectReportingPeriod: TestPage "Select Reporting Period")
    var
        DatePeriod: Record Date;
        VarEndDate: Variant;
        EndDate: Date;
    begin
        LibraryVariableStorage.Dequeue(VarEndDate);
        EndDate := VarEndDate;

        SelectReportingPeriod.FILTER.SetFilter("Period Type", Format(DatePeriod."Period Type"::Month));
        SelectReportingPeriod.FILTER.SetFilter("Period End", Format(ClosingDate(EndDate)));
        SelectReportingPeriod.OK().Invoke();
    end;

    local procedure FindFETemplate(): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
    begin
        FixedAsset.SetRange("FA Type", FixedAsset."FA Type"::"Future Expense");
        FixedAsset.SetRange(Blocked, true);
        FixedAsset.SetRange(Inactive, true);
        FixedAsset.FindFirst();
        exit(FixedAsset."No.");
    end;

    local procedure CreateFEFromSoldFA(IsGLIntegration: Boolean)
    var
        FixedAsset: Record "Fixed Asset";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PostedFADocLine: Record "Posted FA Doc. Line";
        PostedFADocHeader: Record "Posted FA Doc. Header";
        FASetup: Record "FA Setup";
        WriteOffForTaxLedger: Report "Write-off for Tax Ledger";
        CreateFEfromSoldFARep: Report "Create FE from Sold FA";
        FixedAssetNo: Code[20];
    begin
        TaxDeprBookGLIntegration(IsGLIntegration);

        LibraryPurchase.CreateVendor(Vendor);
        LibraryFixedAsset.CreateFixedAssetWithSetup(FixedAsset);
        FixedAssetNo := FixedAsset."No.";
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        AddPurchaseLine(PurchaseHeader, PurchaseLine, PurchaseLine.Type::"Fixed Asset", FixedAssetNo);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        CreateAndPostFAReleaseDoc(FixedAssetNo, WorkDate());
        CreateAndPostFAWriteOffDoc(FixedAssetNo, WorkDate());
        PostedFADocLine.SetRange("FA No.", FixedAssetNo);
        PostedFADocLine.FindFirst();
        PostedFADocHeader.Get(PostedFADocLine."Document Type", PostedFADocLine."Document No.");
        PostedFADocHeader.SetRecFilter();
        WriteOffForTaxLedger.SetTableView(PostedFADocHeader);
        WriteOffForTaxLedger.InitializeRequest(false, 0D, true);
        WriteOffForTaxLedger.UseRequestPage(false);
        WriteOffForTaxLedger.Run();
        FASetup.Get();
        LibraryVariableStorage.Enqueue(FindFETemplate());
        LibraryVariableStorage.Enqueue(FASetup."Fixed Asset Nos.");
        LibraryVariableStorage.Enqueue(LibraryUtility.GenerateGUID());
        Commit();
        FixedAsset.SetRecFilter();
        CreateFEfromSoldFARep.SetTableView(FixedAsset);
        CreateFEfromSoldFARep.UseRequestPage(true);
        CreateFEfromSoldFARep.Run();

        FixedAsset.Reset();
        FixedAsset.SetRange("Created by FA No.", FixedAssetNo);
        FixedAsset.SetRange("FA Type", FixedAsset."FA Type"::"Future Expense");
        Assert.IsFalse(FixedAsset.IsEmpty, FutureExpenseNotFoundErr);
    end;

    local procedure TaxDeprBookGLIntegration(IsGLIntegration: Boolean)
    var
        TaxRegSetup: Record "Tax Register Setup";
        FASetup: Record "FA Setup";
    begin
        TaxRegSetup.Get();
        UpdateDeprBookAndFAJnlSetup(TaxRegSetup."Future Exp. Depreciation Book", IsGLIntegration);
        FASetup.Get();
        UpdateDeprBookAndFAJnlSetup(FASetup."Future Depr. Book", IsGLIntegration);
    end;

    local procedure UpdateDeprBookAndFAJnlSetup(DeprBookCode: Code[10]; IsGLIntegration: Boolean)
    var
        DeprBook: Record "Depreciation Book";
        FAJnlSetup: Record "FA Journal Setup";
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        DeprBook.Get(DeprBookCode);
        DeprBook."G/L Integration - Acq. Cost" := IsGLIntegration;
        DeprBook."G/L Integration - Depreciation" := IsGLIntegration;
        DeprBook."G/L Integration - Disposal" := IsGLIntegration;
        DeprBook.Modify();
        if IsGLIntegration then begin
            if not FAJnlSetup.Get(DeprBook.Code, UserId) then
                FAJnlSetup.Get(DeprBook.Code, '');
            LibraryERM.CreateGenJournalTemplate(GenJnlTemplate);
            LibraryERM.CreateGenJournalBatch(GenJnlBatch, GenJnlTemplate.Name);
            FAJnlSetup."Gen. Jnl. Template Name" := GenJnlTemplate.Name;
            FAJnlSetup."Gen. Jnl. Batch Name" := GenJnlBatch.Name;
            FAJnlSetup.Modify();
        end;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreateFEfromSoldFAHandler(var CreateFEfromSoldFA: TestRequestPage "Create FE from Sold FA")
    var
        FETemplate: Variant;
        FENoSeries: Variant;
        DocumentNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(FETemplate);
        LibraryVariableStorage.Dequeue(FENoSeries);
        LibraryVariableStorage.Dequeue(DocumentNo);
        CreateFEfromSoldFA.FETemplateNo.SetValue(FETemplate); // FE Template
        CreateFEfromSoldFA.NoSeriesCode.SetValue(FENoSeries); // FE No. Series
        CreateFEfromSoldFA.DocumentNo.SetValue(DocumentNo); // Document No
        CreateFEfromSoldFA.OK().Invoke();
    end;
}

