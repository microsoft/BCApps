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
        CalculateDisposal.CalcReverseAmounts(FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code", EntryAmounts);

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
        CalculateDisposal.CalcGainLoss(FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code", EntryAmounts);

        // [THEN] The derogatory gain or loss amount is negated
        FADepreciationBook.CalcFields("Derogatory Amount");
        Assert.AreEqual(-FADepreciationBook."Derogatory Amount", EntryAmounts[15], ValueMustEqualMsg);
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
}
