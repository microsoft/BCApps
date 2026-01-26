codeunit 144027 "UT COD FA Derogatory Depr."
{
    // Test for feature FADD - Fixed Asset Derogatory Depreciation.

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryUTUtility: Codeunit "Library UT Utility";
        ValueMustEqualMsg: Label 'Value must be equal';
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnRunGenJnlPostBatchFAPostingTypeError()
    begin
        // Purpose of the test is to validate OnRun trigger of Codeunit ID - 13 Gen. Jnl.-Post Batch.

        // Test to verify error, FA Posting Type Acquisition Cost must be posted in the FA journal in Gen. Journal Line.
        OnRunGenJnlPostBatch(LibraryUTUtility.GetNewCode(), 'NCLCSRTS:TableErrorStr');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnRunGenJnlPostBatchDocumentNoError()
    begin
        // Purpose of the test is to validate OnRun trigger of Codeunit ID - 13 Gen. Jnl.-Post Batch.

        // Test to verify error, Document No. must have a value in Gen. Journal Line.
        OnRunGenJnlPostBatch('', 'TestField');
    end;

    local procedure OnRunGenJnlPostBatch(DocumentNo: Code[20]; ErrorCode: Text[1024])
    var
        GenJournalLine: Record "Gen. Journal Line";
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        // Setup: Create Fixed Asset Depreciation Book and General Journal Line.
        CreateFADepreciationBook(FADepreciationBook);
        CreateGenJournalLine(GenJournalLine, FADepreciationBook."Depreciation Book Code", FADepreciationBook."FA No.", DocumentNo);

        // Exercise.
        asserterror CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post Batch", GenJournalLine);

        // Verify: Verify expected error code.
        Assert.ExpectedErrorCode(ErrorCode);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SetReverseTypeCalculateDisposal()
    var
        FALedgerEntry: Record "FA Ledger Entry";
        CalculateDisposal: Codeunit "Calculate Disposal";
    begin
        // Purpose of the test is to validate SetReverseType function of Codeunit ID - 5605 Calculate Disposal.
        // Exercise & verify: Call SetReverseType function of Codeunit ID - 5605 Calculate Disposal and verify the returned value.
        Assert.AreEqual(FALedgerEntry."FA Posting Type"::Derogatory, CalculateDisposal.SetReverseType(5), ValueMustEqualMsg);  // 5 for FA Posting Type Derogatory.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SetFAPostingCategoryCalculateDisposal()
    var
        FALedgerEntry: Record "FA Ledger Entry";
        CalculateDisposal: Codeunit "Calculate Disposal";
    begin
        // Purpose of the test is to validate SetFAPostingCategory function of Codeunit ID - 5605 Calculate Disposal.
        // Exercise & verify: Call SetFAPostingCategory function of Codeunit ID - 5605 Calculate Disposal and verify the returned value.
        Assert.AreEqual(FALedgerEntry."FA Posting Type", CalculateDisposal.SetFALedgerPostingCategory(15), ValueMustEqualMsg);  // 15 for FA Posting Category Derogatory.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SetFAPostingTypeCalculateDisposal()
    var
        FALedgerEntry: Record "FA Ledger Entry";
        CalculateDisposal: Codeunit "Calculate Disposal";
    begin
        // Purpose of the test is to validate SetFAPostingType function of Codeunit ID - 5605 Calculate Disposal.
        // Exercise & verify: Call SetFAPostingType function of Codeunit ID - 5605 Calculate Disposal and verify the returned value.
        Assert.AreEqual(FALedgerEntry."FA Posting Type"::Derogatory, CalculateDisposal.SetFAPostingType(15), ValueMustEqualMsg);  // 15 for FA Posting Type Derogatory.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CalcReverseAmountsCalculateDisposal()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        CalculateDisposal: Codeunit "Calculate Disposal";
        EntryAmounts: array[15] of Decimal;
    begin
        // Purpose of the test is to validate CalcReverseAmounts function of Codeunit ID - 5605 Calculate Disposal.
        CreateMultipleFAPostingTypeSetup(FADepreciationBook);

        // Exercise.
        CalculateDisposal.CalcReverseAmounts(FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code", EntryAmounts);  // EntryAmounts, calclulated on the basis of CalcReverseAmounts function of Calculate Disposal.

        // Verify.
        FADepreciationBook.CalcFields(Derogatory);
        Assert.AreEqual(-FADepreciationBook.Derogatory, EntryAmounts[5], ValueMustEqualMsg);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CalcGainLossCalculateDisposal()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        CalculateDisposal: Codeunit "Calculate Disposal";
        EntryAmounts: array[15] of Decimal;
    begin
        // Purpose of the test is to validate CalcGainLoss function of Codeunit ID - 5605 Calculate Disposal.
        CreateMultipleFAPostingTypeSetup(FADepreciationBook);

        // Exercise.
        CalculateDisposal.CalcGainLoss(FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code", EntryAmounts);

        // Verify.
        FADepreciationBook.CalcFields(Derogatory);
        Assert.AreEqual(-FADepreciationBook.Derogatory, EntryAmounts[15], ValueMustEqualMsg);
    end;

    local procedure CreateFixedAsset(): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
    begin
        FixedAsset."No." := LibraryUTUtility.GetNewCode();
        FixedAsset.Insert();
        exit(FixedAsset."No.");
    end;

    local procedure CreateFADepreciationBook(var FADepreciationBook: Record "FA Depreciation Book")
    begin
        FADepreciationBook."FA No." := CreateFixedAsset();
        FADepreciationBook."Depreciation Book Code" := CreateDepreciationBook();
        FADepreciationBook."Depreciation Starting Date" := WorkDate();
        FADepreciationBook.Insert();
    end;

    local procedure CreateSourceCode(): Code[10]
    var
        SourceCode: Record "Source Code";
    begin
        SourceCode.Code := LibraryUTUtility.GetNewCode10();
        SourceCode.Insert();
        exit(SourceCode.Code);
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

    local procedure CreateDepreciationBook(): Code[10]
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        DepreciationBook.Code := LibraryUTUtility.GetNewCode10();
        DepreciationBook.Insert();
        exit(DepreciationBook.Code);
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
        FAPostingTypeSetup."Reverse before Disposal" := true;
        FAPostingTypeSetup.Insert();
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
}

