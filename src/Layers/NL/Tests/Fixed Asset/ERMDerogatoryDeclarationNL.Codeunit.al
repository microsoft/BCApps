codeunit 144149 "ERM Derogatory Declaration NL"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryRandom: Codeunit "Library - Random";
        CounterpartCountErr: Label 'The inherited W1 posting must create exactly one linked tax-book counterpart without using Is Derogatory.';
        PostedFieldErr: Label 'The zero-reference posted-journal Is Derogatory field must be removed.';

    [Test]
    procedure PostedJournalHasNoDormantIsDerogatoryField()
    var
        PostedGenJournalLine: Record "Posted Gen. Journal Line";
        PostedGenJournalLineRecordRef: RecordRef;
    begin
        // [SCENARIO 617335] The zero-reference posted-journal declaration is removed
        PostedGenJournalLineRecordRef.GetTable(PostedGenJournalLine);

        Assert.IsFalse(PostedGenJournalLineRecordRef.FieldExist(5865), PostedFieldErr);
    end;

    [Test]
    procedure FalseIsDerogatoryDoesNotBlockInheritedW1Posting()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SourceFALedgerEntry: Record "FA Ledger Entry";
        CounterpartFALedgerEntry: Record "FA Ledger Entry";
        FANo: Code[20];
        NormalDeprBookCode: Code[10];
        TaxDeprBookCode: Code[10];
    begin
        // [SCENARIO 617336] The NL declaration does not control inherited W1 derogatory posting
        FANo := CreateFAWithNormalAndTaxBooks(NormalDeprBookCode, TaxDeprBookCode);
        CreateAcquisitionLine(GenJournalLine, FANo, NormalDeprBookCode);

        GenJournalLine."Is Derogatory" := false;
        GenJournalLine.Modify();

        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        SourceFALedgerEntry.SetRange("FA No.", FANo);
        SourceFALedgerEntry.SetRange("Depreciation Book Code", NormalDeprBookCode);
        SourceFALedgerEntry.SetRange("Automatic Entry", false);
        SourceFALedgerEntry.FindFirst();

        CounterpartFALedgerEntry.SetRange("FA No.", FANo);
        CounterpartFALedgerEntry.SetRange("Depreciation Book Code", TaxDeprBookCode);
        Assert.AreEqual(1, CounterpartFALedgerEntry.Count, CounterpartCountErr);
        CounterpartFALedgerEntry.SetRange("Derogatory Source Entry No.", SourceFALedgerEntry."Entry No.");
        Assert.AreEqual(1, CounterpartFALedgerEntry.Count, CounterpartCountErr);
    end;

    local procedure CreateFAWithNormalAndTaxBooks(var NormalDeprBookCode: Code[10]; var TaxDeprBookCode: Code[10]): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
        NormalDeprBook: Record "Depreciation Book";
        TaxDeprBook: Record "Depreciation Book";
    begin
        CreateAndSetupDeprBook(NormalDeprBook);
        NormalDeprBook.Validate("G/L Integration - Acq. Cost", true);
        NormalDeprBook.Validate("Integration G/L - Derogatory", true);
        NormalDeprBook.Modify(true);
        NormalDeprBookCode := NormalDeprBook.Code;

        CreateAndSetupDeprBook(TaxDeprBook);
        TaxDeprBook.Validate("Derogatory Calc.", NormalDeprBookCode);
        TaxDeprBook.Modify(true);
        TaxDeprBookCode := TaxDeprBook.Code;

        CreateFixedAsset(FixedAsset);
        CreateFADeprBook(FixedAsset, NormalDeprBookCode);
        CreateFADeprBook(FixedAsset, TaxDeprBookCode);
        exit(FixedAsset."No.");
    end;

    local procedure CreateAndSetupDeprBook(var DepreciationBook: Record "Depreciation Book")
    var
        FAJournalSetup: Record "FA Journal Setup";
        DefaultFAJournalSetup: Record "FA Journal Setup";
        FASetup: Record "FA Setup";
    begin
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        LibraryFixedAsset.CreateFAJournalSetup(FAJournalSetup, DepreciationBook.Code, '');
        FASetup.Get();
        DefaultFAJournalSetup.SetRange("Depreciation Book Code", FASetup."Default Depr. Book");
        DefaultFAJournalSetup.FindFirst();
        FAJournalSetup.TransferFields(DefaultFAJournalSetup, false);
        FAJournalSetup.Modify(true);
    end;

    local procedure CreateFixedAsset(var FixedAsset: Record "Fixed Asset")
    var
        FAPostingGroup: Record "FA Posting Group";
    begin
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        FAPostingGroup.Validate("Derogatory Acc.", CreateGLAccount());
        FAPostingGroup.Validate("Derogatory Account (Decrease)", CreateGLAccount());
        FAPostingGroup.Validate("Derogatory Expense Acc.", CreateGLAccount());
        FAPostingGroup.Validate("Derog. Bal. Account (Decrease)", CreateGLAccount());
        FAPostingGroup.Modify(true);
        FixedAsset.Validate("FA Posting Group", FAPostingGroup.Code);
        FixedAsset.Modify(true);
    end;

    local procedure CreateFADeprBook(FixedAsset: Record "Fixed Asset"; DeprBookCode: Code[10])
    var
        FADeprBook: Record "FA Depreciation Book";
    begin
        LibraryFixedAsset.CreateFADepreciationBook(FADeprBook, FixedAsset."No.", DeprBookCode);
        FADeprBook.Validate("Depreciation Starting Date", WorkDate());
        FADeprBook.Validate("Depreciation Ending Date", CalcDate('<5Y>', WorkDate()));
        FADeprBook.Validate("FA Posting Group", FixedAsset."FA Posting Group");
        FADeprBook.Modify(true);
    end;

    local procedure CreateAcquisitionLine(var GenJournalLine: Record "Gen. Journal Line"; FANo: Code[20]; DeprBookCode: Code[10])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Assets);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.FindGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
            GenJournalLine."Account Type"::"Fixed Asset", FANo, LibraryRandom.RandDec(10000, 2));
        GenJournalLine.Validate("FA Posting Type", GenJournalLine."FA Posting Type"::"Acquisition Cost");
        GenJournalLine.Validate("FA Posting Date", WorkDate());
        GenJournalLine.Validate("Depreciation Book Code", DeprBookCode);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", CreateGLAccount());
        GenJournalLine.Modify(true);
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        exit(GLAccount."No.");
    end;
}
