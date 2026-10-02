// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 134150 "UT COD FA Derogatory Depr."
{
    // [FEATURE] [Fixed Asset] [Derogatory]

    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        IsInitialized: Boolean;
        ValueMustEqualMsg: Label 'Value must be equal';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OnRunGenJnlPostBatchFAPostingTypeError()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] General journal batch posting rejects FA acquisition cost in a general journal
        Initialize();

        // [GIVEN] A general journal line with an FA acquisition-cost posting type
        // [WHEN] The general journal batch is posted
        // [THEN] Posting reports that the entry belongs in an FA journal
        OnRunGenJnlPostBatch(LibraryUTUtility.GetNewCode(), 'NCLCSRTS:TableErrorStr');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OnRunGenJnlPostBatchDocumentNoError()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] General journal batch posting requires a document number
        Initialize();

        // [GIVEN] A general journal line without a document number
        // [WHEN] The general journal batch is posted
        // [THEN] Posting reports the missing document number
        OnRunGenJnlPostBatch('', 'TestField');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SetReverseTypeCalculateDisposal()
    var
        FALedgerEntry: Record "FA Ledger Entry";
        CalculateDisposal: Codeunit "Calculate Disposal";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Calculate Disposal maps reverse type 5 to derogatory
        Initialize();

        // [GIVEN] The derogatory reverse-type index
        // [WHEN] The reverse posting type is calculated
        // [THEN] The result is the derogatory FA posting type
        Assert.AreEqual(FALedgerEntry."FA Posting Type"::Derogatory, CalculateDisposal.SetReverseType(5), ValueMustEqualMsg);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SetFAPostingCategoryCalculateDisposal()
    var
        FALedgerEntry: Record "FA Ledger Entry";
        CalculateDisposal: Codeunit "Calculate Disposal";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Calculate Disposal maps category 15 to the default ledger posting category
        Initialize();

        // [GIVEN] The derogatory posting-category index
        // [WHEN] The FA ledger posting category is calculated
        // [THEN] The result is the default FA ledger posting category
        Assert.AreEqual(FALedgerEntry."FA Posting Type", CalculateDisposal.SetFALedgerPostingCategory(15), ValueMustEqualMsg);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SetFAPostingTypeCalculateDisposal()
    var
        FALedgerEntry: Record "FA Ledger Entry";
        CalculateDisposal: Codeunit "Calculate Disposal";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Calculate Disposal maps posting type 15 to derogatory
        Initialize();

        // [GIVEN] The derogatory posting-type index
        // [WHEN] The FA posting type is calculated
        // [THEN] The result is the derogatory FA posting type
        Assert.AreEqual(FALedgerEntry."FA Posting Type"::Derogatory, CalculateDisposal.SetFAPostingType(15), ValueMustEqualMsg);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CalcReverseAmountsCalculateDisposal()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        CalculateDisposal: Codeunit "Calculate Disposal";
        EntryAmounts: array[15] of Decimal;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Disposal reversal amounts include the negated derogatory amount
        Initialize();

        // [GIVEN] An FA depreciation book with derogatory ledger and posting setup
        CreateMultipleFAPostingTypeSetup(FADepreciationBook);

        // [WHEN] Disposal reversal amounts are calculated
        CalculateDisposal.CalcReverseAmounts(FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code", EntryAmounts, true);

        // [THEN] The derogatory reversal amount is negated
        FADepreciationBook.CalcFields("Derogatory Amount");
        Assert.AreEqual(-FADepreciationBook."Derogatory Amount", EntryAmounts[5], ValueMustEqualMsg);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CalcGainLossCalculateDisposal()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        CalculateDisposal: Codeunit "Calculate Disposal";
        EntryAmounts: array[15] of Decimal;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Disposal gain or loss includes the negated derogatory amount
        Initialize();

        // [GIVEN] An FA depreciation book with derogatory ledger and posting setup
        CreateMultipleFAPostingTypeSetup(FADepreciationBook);

        // [WHEN] Disposal gain or loss is calculated
        CalculateDisposal.CalcGainLoss(FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code", EntryAmounts, true);

        // [THEN] The derogatory gain or loss amount is negated
        FADepreciationBook.CalcFields("Derogatory Amount");
        Assert.AreEqual(-FADepreciationBook."Derogatory Amount", EntryAmounts[15], ValueMustEqualMsg);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LegacyDisposalAPIsPreserveAmountsAndEntryNumbers()
    var
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Published disposal APIs retain their original array contracts and results
        Initialize();

        // [GIVEN] FA "F" has normal and derogatory amounts
        CreateCompatibilityFixture(FADepreciationBook);

        // [WHEN] The legacy and extended disposal APIs are called
        // [THEN] Legacy amounts and entry numbers agree, and extended results include derogatory amounts
        VerifyDisposalAPICompatibility(FADepreciationBook);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GainLossOverloadCanExcludeAdditionalPostingTypes()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        CalculateDisposal: Codeunit "Calculate Disposal";
        IncludedAmounts: array[15] of Decimal;
        ExcludedAmounts: array[15] of Decimal;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] The generic gain/loss overload can exclude additional posting types without changing legacy results
        Initialize();

        // [GIVEN] FA "F" has a derogatory amount and a reused result buffer
        CreateCompatibilityFixture(FADepreciationBook);
        CalculateDisposal.CalcGainLoss(FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code", IncludedAmounts, true);
        CopyArray(ExcludedAmounts, IncludedAmounts, 1, 15);

        // [WHEN] Additional posting types are excluded
        CalculateDisposal.CalcGainLoss(FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code", ExcludedAmounts, false);

        // [THEN] Only the additional result is cleared
        VerifyLegacyAmounts(IncludedAmounts, ExcludedAmounts);
        Assert.AreEqual(-200, IncludedAmounts[15], 'Including additional types must return the derogatory amount.');
        Assert.AreEqual(0, ExcludedAmounts[15], 'Excluding additional types must clear a previous derogatory result.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReverseAmountsOverloadCanExcludeAdditionalPostingTypes()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        CalculateDisposal: Codeunit "Calculate Disposal";
        IncludedAmounts: array[5] of Decimal;
        ExcludedAmounts: array[5] of Decimal;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] The generic reversal overload can exclude additional posting types without changing legacy results
        Initialize();

        // [GIVEN] FA "F" has a derogatory amount and a reused result buffer
        CreateCompatibilityFixture(FADepreciationBook);
        CalculateDisposal.CalcReverseAmounts(FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code", IncludedAmounts, true);
        CopyArray(ExcludedAmounts, IncludedAmounts, 1, 5);

        // [WHEN] Additional posting types are excluded
        CalculateDisposal.CalcReverseAmounts(FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code", ExcludedAmounts, false);

        // [THEN] Only the additional result is cleared
        VerifyReverseAmountsWithoutAdditionalTypes(IncludedAmounts, ExcludedAmounts);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"UT COD FA Derogatory Depr.");

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"UT COD FA Derogatory Depr.");
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"UT COD FA Derogatory Depr.");
    end;

    local procedure CreateDepreciationBook(): Code[10]
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        DepreciationBook.Code := LibraryUTUtility.GetNewCode10();
        DepreciationBook.Insert();
        exit(DepreciationBook.Code);
    end;

    local procedure CreateFADepreciationBook(var FADepreciationBook: Record "FA Depreciation Book")
    begin
        FADepreciationBook."FA No." := CreateFixedAsset();
        FADepreciationBook."Depreciation Book Code" := CreateDepreciationBook();
        FADepreciationBook."Depreciation Starting Date" := WorkDate();
        FADepreciationBook.Insert();
    end;

    local procedure CreateFALedgerEntry(FANo: Code[20]; DepreciationBookCode: Code[10])
    var
        FALedgerEntry: Record "FA Ledger Entry";
        FALedgerEntry2: Record "FA Ledger Entry";
    begin
        FALedgerEntry."Entry No." := 1;
        if FALedgerEntry2.FindLast() then
            FALedgerEntry."Entry No." := FALedgerEntry2."Entry No." + 1;
        FALedgerEntry."FA No." := FANo;
        FALedgerEntry."Depreciation Book Code" := DepreciationBookCode;
        FALedgerEntry."FA Posting Type" := FALedgerEntry."FA Posting Type"::Derogatory;
        FALedgerEntry.Amount := LibraryRandom.RandDec(10, 2);
        FALedgerEntry.Insert();
    end;

    local procedure CreateFAPostingTypeSetup(DepreciationBookCode: Code[10]; FAPostingType: Enum "FA Posting Type Setup Type")
    var
        FAPostingTypeSetup: Record "FA Posting Type Setup";
    begin
        FAPostingTypeSetup."Depreciation Book Code" := DepreciationBookCode;
        FAPostingTypeSetup."FA Posting Type" := FAPostingType;
        FAPostingTypeSetup."Part of Book Value" := true;
        FAPostingTypeSetup."Include in Gain/Loss Calc." := true;
        FAPostingTypeSetup."Reverse before Disposal" := true;
        FAPostingTypeSetup.Insert();
    end;

    local procedure CreateFixedAsset(): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
    begin
        FixedAsset."No." := LibraryUTUtility.GetNewCode();
        FixedAsset.Insert();
        exit(FixedAsset."No.");
    end;

    local procedure CreateGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.Name := LibraryUTUtility.GetNewCode10();
        GenJournalTemplate."Page ID" := PAGE::"Fixed Asset G/L Journal";
        GenJournalTemplate.Insert();

        GenJournalBatch."Journal Template Name" := GenJournalTemplate.Name;
        GenJournalBatch.Name := LibraryUTUtility.GetNewCode10();
        GenJournalBatch.Insert();
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DepreciationBookCode: Code[10]; AccountNo: Code[20]; DocumentNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGenJournalBatch(GenJournalBatch);
        GenJournalLine."Journal Template Name" := GenJournalBatch."Journal Template Name";
        GenJournalLine."Journal Batch Name" := GenJournalBatch.Name;
        GenJournalLine."Source Code" := CreateSourceCode();
        GenJournalLine."Posting Date" := WorkDate();
        GenJournalLine."FA Posting Type" := GenJournalLine."FA Posting Type"::"Acquisition Cost";
        GenJournalLine."Document No." := DocumentNo;
        GenJournalLine."Depreciation Book Code" := DepreciationBookCode;
        GenJournalLine."Account Type" := GenJournalLine."Account Type"::"Fixed Asset";
        GenJournalLine."Account No." := AccountNo;
        GenJournalLine.Insert();
    end;

    local procedure CreateMultipleFAPostingTypeSetup(var FADepreciationBook: Record "FA Depreciation Book")
    var
        FAPostingTypeSetup: Record "FA Posting Type Setup";
    begin
        CreateFADepreciationBook(FADepreciationBook);
        CreateFALedgerEntry(FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code");
        CreateFAPostingTypeSetup(FADepreciationBook."Depreciation Book Code", FAPostingTypeSetup."FA Posting Type"::"Write-Down");
        CreateFAPostingTypeSetup(FADepreciationBook."Depreciation Book Code", FAPostingTypeSetup."FA Posting Type"::Appreciation);
        CreateFAPostingTypeSetup(FADepreciationBook."Depreciation Book Code", FAPostingTypeSetup."FA Posting Type"::"Custom 1");
        CreateFAPostingTypeSetup(FADepreciationBook."Depreciation Book Code", FAPostingTypeSetup."FA Posting Type"::"Custom 2");
    end;

    local procedure CreateSourceCode(): Code[10]
    var
        SourceCode: Record "Source Code";
    begin
        SourceCode.Code := LibraryUTUtility.GetNewCode10();
        SourceCode.Insert();
        exit(SourceCode.Code);
    end;

    local procedure CreateCompatibilityFixture(var FADepreciationBook: Record "FA Depreciation Book")
    var
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", DepreciationBook.Code);
        FALedgerEntry."Entry No." := FALedgerEntry.GetLastEntryNo() + 1;
        FALedgerEntry."FA No." := FixedAsset."No.";
        FALedgerEntry."Depreciation Book Code" := DepreciationBook.Code;
        FALedgerEntry."FA Posting Type" := FALedgerEntry."FA Posting Type"::Derogatory;
        FALedgerEntry.Amount := 200;
        FALedgerEntry.Insert();
    end;

    local procedure OnRunGenJnlPostBatch(DocumentNo: Code[20]; ErrorCode: Text[1024])
    var
        GenJournalLine: Record "Gen. Journal Line";
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        CreateFADepreciationBook(FADepreciationBook);
        CreateGenJournalLine(GenJournalLine, FADepreciationBook."Depreciation Book Code", FADepreciationBook."FA No.", DocumentNo);

        asserterror CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post Batch", GenJournalLine);

        Assert.ExpectedErrorCode(ErrorCode);
    end;

    local procedure VerifyDisposalAPICompatibility(FADepreciationBook: Record "FA Depreciation Book")
    var
        CalculateDisposal: Codeunit "Calculate Disposal";
        DepreciationBookRecordRef: RecordRef;
        LegacyAmounts: array[14] of Decimal;
        LegacyNumbers: array[14] of Integer;
        LegacyReverseAmounts: array[4] of Decimal;
        ExtendedAmounts: array[15] of Decimal;
        ExtendedNumbers: array[15] of Integer;
        ExtendedReverseAmounts: array[5] of Decimal;
        FrenchAmounts: array[15] of Decimal;
        FrenchNumbers: array[15] of Integer;
        FrenchReverseAmounts: array[5] of Decimal;
        IsFrenchAPI: Boolean;
        Index: Integer;
    begin
        // The French APIs already exposed the extended arrays before the W1 feature.
        DepreciationBookRecordRef.Open(Database::"Depreciation Book");
        IsFrenchAPI := DepreciationBookRecordRef.FieldExist(10802);
        DepreciationBookRecordRef.Close();
        if IsFrenchAPI then begin
            CalculateDisposal.CalcGainLoss(FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code", FrenchAmounts);
            CopyArray(LegacyAmounts, FrenchAmounts, 1, 14);
        end else
            CalculateDisposal.CalcGainLoss(FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code", LegacyAmounts);
        CalculateDisposal.CalcGainLoss(FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code", ExtendedAmounts, true);
        VerifyLegacyAmounts(LegacyAmounts, ExtendedAmounts);
        Assert.AreEqual(-200, ExtendedAmounts[15], 'The extended disposal result must include derogatory depreciation.');

        if IsFrenchAPI then begin
            CalculateDisposal.CalcSecondGainLoss(FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code", 100, FrenchAmounts);
            CopyArray(LegacyAmounts, FrenchAmounts, 1, 14);
        end else
            CalculateDisposal.CalcSecondGainLoss(FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code", 100, LegacyAmounts);
        CalculateDisposal.CalcSecondGainLoss(FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code", 100, ExtendedAmounts);
        VerifyLegacyAmounts(LegacyAmounts, ExtendedAmounts);

        if IsFrenchAPI then begin
            CalculateDisposal.CalcReverseAmounts(FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code", FrenchReverseAmounts);
            CopyArray(LegacyReverseAmounts, FrenchReverseAmounts, 1, 4);
        end else
            CalculateDisposal.CalcReverseAmounts(FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code", LegacyReverseAmounts);
        CalculateDisposal.CalcReverseAmounts(FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code", ExtendedReverseAmounts, true);
        for Index := 1 to 4 do
            Assert.AreEqual(LegacyReverseAmounts[Index], ExtendedReverseAmounts[Index], 'Legacy reverse amounts must not change.');
        Assert.AreEqual(-200, ExtendedReverseAmounts[5], 'The extended reversal must include derogatory depreciation.');

        LegacyAmounts[3] := 300;
        ExtendedAmounts[3] := 300;
        FrenchAmounts[3] := 300;
        LegacyNumbers[3] := 123;
        ExtendedNumbers[3] := 123;
        FrenchNumbers[3] := 123;
        if IsFrenchAPI then begin
            CalculateDisposal.GetErrorDisposal(FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code", true, 1, FrenchAmounts, FrenchNumbers);
            CopyArray(LegacyAmounts, FrenchAmounts, 1, 14);
            CopyArray(LegacyNumbers, FrenchNumbers, 1, 14);
        end else
            CalculateDisposal.GetErrorDisposal(FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code", true, 1, LegacyAmounts, LegacyNumbers);
        CalculateDisposal.GetErrorDisposal(FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code", true, 1, ExtendedAmounts, ExtendedNumbers);
        VerifyLegacyAmounts(LegacyAmounts, ExtendedAmounts);
        for Index := 1 to 14 do
            Assert.AreEqual(LegacyNumbers[Index], ExtendedNumbers[Index], 'Legacy disposal entry numbers must not change.');
        Assert.AreEqual(300, LegacyAmounts[3], 'Unchanged input amounts must survive the compatibility delegate.');
        Assert.AreEqual(0, LegacyNumbers[3], 'The compatibility delegate must return the cleared entry numbers.');
    end;

    local procedure VerifyLegacyAmounts(LegacyAmounts: array[14] of Decimal; ExtendedAmounts: array[15] of Decimal)
    var
        Index: Integer;
    begin
        for Index := 1 to 14 do
            Assert.AreEqual(LegacyAmounts[Index], ExtendedAmounts[Index], 'Legacy disposal amounts must not change.');
    end;

    local procedure VerifyReverseAmountsWithoutAdditionalTypes(IncludedAmounts: array[5] of Decimal; ExcludedAmounts: array[5] of Decimal)
    var
        Index: Integer;
    begin
        for Index := 1 to 4 do
            Assert.AreEqual(IncludedAmounts[Index], ExcludedAmounts[Index], 'Legacy reversal amounts must not change.');
        Assert.AreEqual(-200, IncludedAmounts[5], 'Including additional types must return the derogatory amount.');
        Assert.AreEqual(0, ExcludedAmounts[5], 'Excluding additional types must clear a previous derogatory result.');
    end;
}
