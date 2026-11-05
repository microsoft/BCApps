codeunit 144001 "UT TAB Apply GL Entries"
{
    // 1. Purpose of the test is to verify error You cannot reverse G/L Entry No. because the entry is either applied to an entry or has been changed by a batch job.
    // 2. Purpose of the test is to verify error You cannot reverse G/L Entry No. because the entry is closed.
    // 
    // Covers Test Cases for WI - 344368.
    // ----------------------------------------------------------------------------
    // Test Function Name                                                    TFS ID
    // ----------------------------------------------------------------------------
    // OnActionReverseTransactionOpenTrue, OnActionReverseTransactionOpenFalse

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnActionReverseTransactionOpenTrue()
    begin
        // Purpose of the test is to verify error You cannot reverse G/L Entry No. because the entry is either applied to an entry or has been changed by a batch job.
        ReverseEntryTransaction(true);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnActionReverseTransactionOpenFalse()
    begin
        // Purpose of the test is to verify error You cannot reverse G/L Entry No. because the entry is closed.
        ReverseEntryTransaction(false);
    end;

    [Test]
    procedure DateCompressionPreservesAppliedGLEntries()
    var
        GLEntry: Record "G/L Entry";
        AnalysisView: Record "Analysis View";
        DateComprRegister: Record "Date Compr. Register";
        DateComprRetainFields: Record "Date Compr. Retain Fields";
        DimensionSelectionBuffer: Record "Dimension Selection Buffer";
        LibraryERM: Codeunit "Library - ERM";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        DateCompression: Codeunit "Date Compression";
        DateCompressGeneralLedger: Report "Date Compress General Ledger";
        GLAccountNo: array[2] of Code[20];
        PartialEntryNo: array[2] of Integer;
        ClosedEntryNo: array[2] of Integer;
        FirstUnappliedEntryNo: array[2] of Integer;
        SecondUnappliedEntryNo: array[2] of Integer;
        PostingDate: Date;
        AccountIndex: Integer;
    begin
        // [SCENARIO] Neither a partially applied first entry nor one inside a compression group is compressed.
        LibraryFiscalYear.CreateClosedAccountingPeriods();
        AnalysisView.DeleteAll();
        PostingDate := DateCompression.CalcMaxEndDate();
        for AccountIndex := 1 to ArrayLen(GLAccountNo) do begin
            GLAccountNo[AccountIndex] := LibraryERM.CreateGLAccountNoWithDirectPosting();
            if AccountIndex = 1 then
                PartialEntryNo[AccountIndex] := CreateCompressionGLEntry(GLAccountNo[AccountIndex], PostingDate, 100, 50, true);
            FirstUnappliedEntryNo[AccountIndex] := CreateCompressionGLEntry(GLAccountNo[AccountIndex], PostingDate, 100, 100, true);
            if AccountIndex = 2 then
                PartialEntryNo[AccountIndex] := CreateCompressionGLEntry(GLAccountNo[AccountIndex], PostingDate, 100, 50, true);
            SecondUnappliedEntryNo[AccountIndex] := CreateCompressionGLEntry(GLAccountNo[AccountIndex], PostingDate, 200, 200, true);
            ClosedEntryNo[AccountIndex] := CreateCompressionGLEntry(GLAccountNo[AccountIndex], PostingDate, 50, 0, false);
        end;

        GLEntry.SetFilter("G/L Account No.", '%1|%2', GLAccountNo[1], GLAccountNo[2]);
        DateCompressGeneralLedger.SetTableView(GLEntry);
        DateCompressGeneralLedger.InitializeRequest(
            PostingDate, PostingDate, DateComprRegister."Period Length"::Day, '', DateComprRetainFields,
            DimensionSelectionBuffer.GetDimSelectionText(3, Report::"Date Compress General Ledger", ''), false);
        DateCompressGeneralLedger.UseRequestPage(false);

        // [WHEN] Date compression processes both accounts.
        DateCompressGeneralLedger.Run();

        // [THEN] Applied entries stay unchanged, and only fully unapplied amounts are summarized.
        for AccountIndex := 1 to ArrayLen(GLAccountNo) do begin
            GLEntry.Reset();
            GLEntry.Get(PartialEntryNo[AccountIndex]);
            GLEntry.TestField(Amount, 100);
            GLEntry.TestField("Remaining Amount", 50);
            GLEntry.TestField(Open, true);
            GLEntry.Get(ClosedEntryNo[AccountIndex]);
            GLEntry.TestField(Amount, 50);
            GLEntry.TestField("Remaining Amount", 0);
            GLEntry.TestField(Open, false);
            Assert.IsFalse(GLEntry.Get(FirstUnappliedEntryNo[AccountIndex]), 'The first unapplied entry must be compressed');
            Assert.IsFalse(GLEntry.Get(SecondUnappliedEntryNo[AccountIndex]), 'The second unapplied entry must be compressed');
            GLEntry.SetRange("G/L Account No.", GLAccountNo[AccountIndex]);
            Assert.RecordCount(GLEntry, 3);
            GLEntry.SetRange("System-Created Entry", true);
            Assert.RecordCount(GLEntry, 1);
            GLEntry.FindFirst();
            GLEntry.TestField(Amount, 300);
            GLEntry.TestField("Remaining Amount", 300);
        end;
    end;

    local procedure CreateCompressionGLEntry(GLAccountNo: Code[20]; PostingDate: Date; Amount: Decimal; RemainingAmount: Decimal; Open: Boolean): Integer
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry."Entry No." := GLEntry.GetLastEntryNo() + 1;
        GLEntry."G/L Account No." := GLAccountNo;
        GLEntry."Posting Date" := PostingDate;
        GLEntry.Amount := Amount;
        GLEntry."Debit Amount" := Amount;
        GLEntry."Remaining Amount" := RemainingAmount;
        GLEntry.Open := Open;
        GLEntry."Transaction No." := GLEntry."Entry No.";
        GLEntry.Insert();
        exit(GLEntry."Entry No.");
    end;

    local procedure ReverseEntryTransaction(Open: Boolean)
    var
        GeneralLedgerEntries: TestPage "General Ledger Entries";
    begin
        // Setup.
        GeneralLedgerEntries.OpenEdit();
        GeneralLedgerEntries.FILTER.SetFilter("Entry No.", Format(CreateGLEntry(Open)));

        // Exercise.
        asserterror GeneralLedgerEntries.ReverseTransaction.Invoke();

        // Verify.
        Assert.ExpectedErrorCode('TestWrapped:Dialog');
    end;

    local procedure CreateGLEntry(Open: Boolean): Integer
    var
        GLEntry: Record "G/L Entry";
        GLEntry2: Record "G/L Entry";
    begin
        GLEntry2.FindLast();
        GLEntry."Entry No." := GLEntry2."Entry No." + 1;
        GLEntry."G/L Account No." := LibraryUTUtility.GetNewCode();
        GLEntry."Document Type" := GLEntry."Document Type"::Payment;
        GLEntry."Source Code" := LibraryUTUtility.GetNewCode10();
        GLEntry.Amount := LibraryRandom.RandDecInRange(100, 200, 2);
        GLEntry."Remaining Amount" := LibraryRandom.RandDec(10, 2);
        GLEntry.Open := Open;
        GLEntry."Journal Batch Name" := LibraryUTUtility.GetNewCode10();
        GLEntry."Transaction No." := GLEntry2."Transaction No." + 1;
        GLEntry.Insert();
        exit(GLEntry."Entry No.");
    end;
}
