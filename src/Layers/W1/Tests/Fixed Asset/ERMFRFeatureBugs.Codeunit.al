// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 134085 "ERM FR Feature Bugs"
{
    // [FEATURE] [Fixed Asset] [Derogatory]

    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    trigger OnRun()
    begin
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;

    [Test]
    procedure BookValueAfterPostDepreciationAndDerogatoryFAJnl()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        GenJournalLine: Record "Gen. Journal Line";
        AcquisitionCostAmount: Integer;
        FANo: Code[20];
        NormalDepreciationBookCode: Code[10];
        TaxDepreciationBookCode: Code[10];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Tax depreciation book value is zero at the depreciation ending date
        Initialize();

        // [GIVEN] FA "FA" with normal and tax depreciation books and a posted acquisition cost
        AcquisitionCostAmount := LibraryRandom.RandIntInRange(10000, 20000);
        NormalDepreciationBookCode := CreateDepreciationBookAndModifyDerogatoryCalculation('');
        FANo := CreateFAWithTaxFADepreciationBookAndGLIntegration(TaxDepreciationBookCode, NormalDepreciationBookCode);
        CreateAndPostGenJournalLine(
          GenJournalLine, WorkDate(), GenJournalLine."FA Posting Type"::"Acquisition Cost", FANo,
          NormalDepreciationBookCode, 2 * AcquisitionCostAmount);

        // [WHEN] Post depreciation and derogatory entries for "FA"
        CreatePostDepreciationAndDerogatoryFAJournal(FANo, NormalDepreciationBookCode, AcquisitionCostAmount, AcquisitionCostAmount);

        // [THEN] The tax depreciation book value is zero
        FADepreciationBook.Get(FANo, TaxDepreciationBookCode);
        FADepreciationBook.CalcFields("Book Value");
        FADepreciationBook.TestField("Book Value", 0);
    end;

    [Test]
    [HandlerFunctions('CalculateDepreciationRequestPageHandler,DepreciationCalcConfirmHandler')]
    procedure DerogatoryAmountAfterPostDepreciationAndDerogatoryFAJnl()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        GenJournalLine: Record "Gen. Journal Line";
        AcquisitionCostAmount: Integer;
        FANo: Code[20];
        NormalDepreciationBookCode: Code[10];
        TaxDepreciationBookCode: Code[10];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Derogatory amount is recorded in the tax depreciation book
        Initialize();

        // [GIVEN] FA "FA" with normal and tax depreciation books and calculated depreciation
        AcquisitionCostAmount := LibraryRandom.RandIntInRange(10000, 20000);
        NormalDepreciationBookCode := CreateDepreciationBookAndModifyDerogatoryCalculation('');
        FANo := CreateFAWithTaxFADepreciationBookAndGLIntegration(TaxDepreciationBookCode, NormalDepreciationBookCode);
        CreateAndPostGenJournalLine(
          GenJournalLine, WorkDate(), GenJournalLine."FA Posting Type"::"Acquisition Cost", FANo,
          NormalDepreciationBookCode, 2 * AcquisitionCostAmount);
        RunCalculateDepreciationReport(NormalDepreciationBookCode);

        // [WHEN] Post depreciation and derogatory entries for "FA"
        CreatePostDepreciationAndDerogatoryFAJournal(FANo, NormalDepreciationBookCode, AcquisitionCostAmount, AcquisitionCostAmount);

        // [THEN] The tax depreciation book contains the derogatory amount
        FADepreciationBook.Get(FANo, TaxDepreciationBookCode);
        FADepreciationBook.CalcFields("Derogatory Amount");
        FADepreciationBook.TestField("Derogatory Amount", -AcquisitionCostAmount);
    end;

    [Test]
    [HandlerFunctions('CalculateDepreciationRequestPageHandler,DepreciationCalcConfirmHandler')]
    procedure DerogatoryEntriesAfterPostDepreciationAndDerogatoryFAJnl()
    var
        FALedgerEntry: Record "FA Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        AcquisitionCostAmount: Integer;
        FANo: Code[20];
        NormalDepreciationBookCode: Code[10];
        TaxDepreciationBookCode: Code[10];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] FA ledger entries contain acquisition, derogatory, and depreciation amounts
        Initialize();

        // [GIVEN] FA "FA" with normal and tax depreciation books and calculated depreciation
        AcquisitionCostAmount := LibraryRandom.RandIntInRange(10000, 20000);
        NormalDepreciationBookCode := CreateDepreciationBookAndModifyDerogatoryCalculation('');
        FANo := CreateFAWithTaxFADepreciationBookAndGLIntegration(TaxDepreciationBookCode, NormalDepreciationBookCode);
        CreateAndPostGenJournalLine(
          GenJournalLine, WorkDate(), GenJournalLine."FA Posting Type"::"Acquisition Cost", FANo,
          NormalDepreciationBookCode, 2 * AcquisitionCostAmount);
        RunCalculateDepreciationReport(NormalDepreciationBookCode);

        // [WHEN] Post depreciation and derogatory entries for "FA"
        CreatePostDepreciationAndDerogatoryFAJournal(FANo, NormalDepreciationBookCode, AcquisitionCostAmount, AcquisitionCostAmount);

        // [THEN] The FA ledger contains the expected posting dates and amounts
        VerifyFALedgerEntries(FANo, FALedgerEntry."FA Posting Type"::"Acquisition Cost", WorkDate(), 2 * AcquisitionCostAmount);
        VerifyFALedgerEntries(FANo, FALedgerEntry."FA Posting Type"::Derogatory, CalcDate('<1M>', WorkDate()), -AcquisitionCostAmount);
        VerifyFALedgerEntries(
          FANo, FALedgerEntry."FA Posting Type"::Depreciation, CalcDate('<1Y>', WorkDate()), -AcquisitionCostAmount);
    end;

    [Test]
    [HandlerFunctions('CalculateDepreciationRequestPageHandler,DepreciationCalcConfirmHandler')]
    procedure PostingDatesAfterPostDepreciationAndDerogatoryFAJnl()
    var
        FALedgerEntry: Record "FA Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        AcquisitionCostAmount: Integer;
        FANo: Code[20];
        NormalDepreciationBookCode: Code[10];
        TaxDepreciationBookCode: Code[10];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] FA ledger entries retain their FA posting dates
        Initialize();

        // [GIVEN] FA "FA" with normal and tax depreciation books and calculated depreciation
        AcquisitionCostAmount := LibraryRandom.RandIntInRange(10000, 20000);
        NormalDepreciationBookCode := CreateDepreciationBookAndModifyDerogatoryCalculation('');
        FANo := CreateFAWithTaxFADepreciationBookAndGLIntegration(TaxDepreciationBookCode, NormalDepreciationBookCode);
        CreateAndPostGenJournalLine(
          GenJournalLine, WorkDate(), GenJournalLine."FA Posting Type"::"Acquisition Cost", FANo,
          NormalDepreciationBookCode, AcquisitionCostAmount);
        RunCalculateDepreciationReport(NormalDepreciationBookCode);

        // [WHEN] Post depreciation and a zero derogatory amount for "FA"
        CreatePostDepreciationAndDerogatoryFAJournal(FANo, NormalDepreciationBookCode, AcquisitionCostAmount, 0);

        // [THEN] The FA ledger contains the expected posting dates and amounts
        VerifyFALedgerEntries(FANo, FALedgerEntry."FA Posting Type"::"Acquisition Cost", WorkDate(), AcquisitionCostAmount);
        VerifyFALedgerEntries(FANo, FALedgerEntry."FA Posting Type"::Derogatory, CalcDate('<1M>', WorkDate()), 0);
        VerifyFALedgerEntries(
          FANo, FALedgerEntry."FA Posting Type"::Depreciation, CalcDate('<1Y>', WorkDate()), -AcquisitionCostAmount);
    end;

    local procedure Initialize()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"ERM FR Feature Bugs");
        GenJournalLine.DeleteAll();
        LibraryVariableStorage.Clear();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"ERM FR Feature Bugs");
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"ERM FR Feature Bugs");
    end;

    local procedure CreateAndPostGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; FAPostingDate: Date; FAPostingType: Enum "Gen. Journal Line FA Posting Type"; FANo: Code[20]; DepreciationBookCode: Code[10]; Amount: Decimal)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Document Type",
          GenJournalLine."Account Type"::"Fixed Asset", FANo, Amount);
        GenJournalLine.Validate("FA Posting Type", FAPostingType);
        GenJournalLine.Validate("FA Posting Date", FAPostingDate);
        GenJournalLine.Validate("Posting Date", WorkDate());
        GenJournalLine.Validate("Depreciation Book Code", DepreciationBookCode);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", CreateGLAccount());
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndSetupDepreciationBook(var DepreciationBook: Record "Depreciation Book")
    var
        FAJournalSetup: Record "FA Journal Setup";
    begin
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        LibraryFixedAsset.CreateFAJournalSetup(FAJournalSetup, DepreciationBook.Code, '');
        UpdateFAJournalSetup(FAJournalSetup);
    end;

    local procedure CreateDepreciationBookAndModifyDerogatoryCalculation(DerogatoryCalculation: Code[10]): Code[10]
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        CreateAndSetupDepreciationBook(DepreciationBook);
        DepreciationBook.Validate("Use Same FA+G/L Posting Dates", false);
        DepreciationBook.Validate("Derogatory Calc.", DerogatoryCalculation);
        DepreciationBook.Modify(true);
        exit(DepreciationBook.Code);
    end;

    local procedure CreateFADepreciationBook(FANo: Code[20]; DepreciationBookCode: Code[10]; FAPostingGroup: Code[20])
    var
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FANo, DepreciationBookCode);
        FADepreciationBook.Validate("Depreciation Book Code", DepreciationBookCode);
        FADepreciationBook.Validate("Depreciation Starting Date", WorkDate());

        FADepreciationBook.Validate(
          "Depreciation Ending Date", CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate()));
        FADepreciationBook.Validate("FA Posting Group", FAPostingGroup);
        FADepreciationBook.Modify(true);
    end;

    local procedure CreateFAWithTaxFADepreciationBookAndGLIntegration(var TaxDepreciationBookCode: Code[10]; NormalDepreciationBookCode: Code[10]): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
    begin
        UpdateIntegrationInBook(NormalDepreciationBookCode);
        TaxDepreciationBookCode := CreateDepreciationBookAndModifyDerogatoryCalculation(NormalDepreciationBookCode);
        CreateFixedAssetAndUpdateFAPostingGroup(FixedAsset);
        CreateFADepreciationBook(FixedAsset."No.", NormalDepreciationBookCode, FixedAsset."FA Posting Group");
        CreateFADepreciationBook(FixedAsset."No.", TaxDepreciationBookCode, FixedAsset."FA Posting Group");
        exit(FixedAsset."No.");
    end;

    local procedure CreateFixedAsset(var FixedAsset: Record "Fixed Asset")
    var
        FAPostingGroup: Record "FA Posting Group";
    begin
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        FixedAsset.Validate("FA Posting Group", FAPostingGroup.Code);
        FixedAsset.Modify(true);
    end;

    local procedure CreateFixedAssetAndUpdateFAPostingGroup(var FixedAsset: Record "Fixed Asset")
    begin
        CreateFixedAsset(FixedAsset);
        UpdateFAPostingGroup(FixedAsset."FA Posting Group");
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        exit(GLAccount."No.");
    end;

    local procedure CreatePostDepreciationAndDerogatoryFAJournal(FANo: Code[20]; DepreciationBookCode: Code[10]; DepreciationAmount: Decimal; DerogatoryAmount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateAndPostGenJournalLine(
          GenJournalLine, CalcDate('<1Y>', WorkDate()), GenJournalLine."FA Posting Type"::Depreciation, FANo,
          DepreciationBookCode, -DepreciationAmount);
        CreateAndPostGenJournalLine(
          GenJournalLine, CalcDate('<1M>', WorkDate()), GenJournalLine."FA Posting Type"::Derogatory, FANo,
          DepreciationBookCode, -DerogatoryAmount);
    end;

    local procedure RunCalculateDepreciationReport(DepreciationBookCode: Code[10])
    begin
        LibraryVariableStorage.Enqueue(DepreciationBookCode);
        REPORT.Run(REPORT::"Calculate Depreciation");
    end;

    local procedure UpdateFAJournalSetup(var FAJournalSetup: Record "FA Journal Setup")
    var
        FAJournalSetup2: Record "FA Journal Setup";
        FASetup: Record "FA Setup";
    begin
        FASetup.Get();
        FAJournalSetup2.SetRange("Depreciation Book Code", FASetup."Default Depr. Book");
        FAJournalSetup2.FindFirst();
        FAJournalSetup.TransferFields(FAJournalSetup2, false);
        FAJournalSetup.Modify(true);
    end;

    local procedure UpdateFAPostingGroup(FAPostingGroupCode: Code[20])
    var
        FAPostingGroup: Record "FA Posting Group";
        FAPostingGroup2: Record "FA Posting Group";
        RecordRef: RecordRef;
    begin
        FAPostingGroup.Get(FAPostingGroupCode);
        FAPostingGroup2.SetFilter("Acquisition Cost Account", '<>''''');
        RecordRef.GetTable(FAPostingGroup2);
        LibraryUtility.FindRecord(RecordRef);
        RecordRef.SetTable(FAPostingGroup2);
        FAPostingGroup.TransferFields(FAPostingGroup2, false);
        // Ensure the derogatory accounts are set (some localizations' demo FA posting groups have none),
        // reusing the group's existing valid accounts so the setup is country-independent.
        FAPostingGroup.Validate("Derogatory Acc.", FAPostingGroup."Accum. Depreciation Account");
        FAPostingGroup.Validate("Derogatory Account (Decrease)", FAPostingGroup."Accum. Depreciation Account");
        FAPostingGroup.Validate("Derogatory Expense Acc.", FAPostingGroup."Depreciation Expense Acc.");
        FAPostingGroup.Validate("Derog. Bal. Account (Decrease)", FAPostingGroup."Depreciation Expense Acc.");
        FAPostingGroup.Modify(true);
    end;

    local procedure UpdateIntegrationInBook(DepreciationBookCode: Code[10])
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        DepreciationBook.Get(DepreciationBookCode);
        DepreciationBook.Validate("G/L Integration - Acq. Cost", true);
        DepreciationBook.Validate("G/L Integration - Depreciation", true);
        DepreciationBook.Validate("Integration G/L - Derogatory", true);
        DepreciationBook.Modify(true);
    end;

    local procedure VerifyFALedgerEntries(FANo: Code[20]; FAPostingType: Enum "FA Ledger Entry FA Posting Type"; FAPostingDate: Date; Amount: Decimal)
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        FALedgerEntry.SetRange("FA No.", FANo);
        FALedgerEntry.SetRange("FA Posting Type", FAPostingType);
        FALedgerEntry.FindSet();
        repeat
            FALedgerEntry.TestField("FA Posting Date", FAPostingDate);
            FALedgerEntry.TestField(Amount, Amount);
        until FALedgerEntry.Next() = 0;
    end;

    [RequestPageHandler]
    procedure CalculateDepreciationRequestPageHandler(var CalculateDepreciation: TestRequestPage "Calculate Depreciation")
    var
        DepreciationBookCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(DepreciationBookCode);
        CalculateDepreciation.DepreciationBook.SetValue(DepreciationBookCode);
        CalculateDepreciation.FAPostingDate.SetValue(WorkDate());
        CalculateDepreciation.PostingDate.SetValue(WorkDate());
        CalculateDepreciation.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure DepreciationCalcConfirmHandler(Message: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;
}
