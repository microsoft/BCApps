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

