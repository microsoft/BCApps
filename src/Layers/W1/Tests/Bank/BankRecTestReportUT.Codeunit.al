codeunit 134279 "Bank Rec. Test Report UT"
{
    Subtype = Test;
    TestType = UnitTest;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        LibraryERM: Codeunit "Library - ERM";

    /// <summary>
    /// This test creates several bank ledger entries that should or should not be counted as outstanding
    /// To keep track of which should be counted, we maintain an ExpectedAmount variable.
    /// It is helpful to see the amounts in binary representation, since each bit represents an entry that should be counted (1) or not (0).
    /// For example, the expected amount in this case is in binary: 00010101 = 1 + 4 + 16 = 21
    /// Since the entries that should be counted are the 1st, 3rd and 5th entries created in the test.
    /// </summary>
    [Test]
    procedure TestGetTotalOutstandingTransactions()
    var
        BankAccount: Record "Bank Account";
        CurrentBankRec, BankRecBefore, BankRecAfter : Record "Bank Acc. Reconciliation";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        BankRecTestReport: Codeunit "Bank Acc. Recon. Test";
        StatementDate, BeforeStatementDate, AfterStatementDate : Date;
        Amount: Decimal;
        ExpectedAmount: Decimal;
    begin
        StatementDate := WorkDate();
        BeforeStatementDate := StatementDate - 10;
        AfterStatementDate := StatementDate + 10;

        LibraryERM.CreateBankAccount(BankAccount);
        LibraryERM.CreateBankAccReconciliation(CurrentBankRec, BankAccount."No.", Enum::"Bank Acc. Rec. Stmt. Type"::"Bank Reconciliation");
        CurrentBankRec."Statement Date" := StatementDate;
        CurrentBankRec.Modify();
        LibraryERM.CreateBankAccReconciliation(BankRecBefore, BankAccount."No.", Enum::"Bank Acc. Rec. Stmt. Type"::"Bank Reconciliation");
        BankRecBefore."Statement Date" := BeforeStatementDate;
        BankRecBefore.Modify();
        LibraryERM.CreateBankAccReconciliation(BankRecAfter, BankAccount."No.", Enum::"Bank Acc. Rec. Stmt. Type"::"Bank Reconciliation");
        BankRecAfter."Statement Date" := AfterStatementDate;
        BankRecAfter.Modify();

        // [GIVEN] An unmatched open BLE (should be counted)
        Amount := 1;
        OpenBankAccountLedgerEntry(BankAccount, Amount);
        ExpectedAmount += Amount;

        // [GIVEN] A closed BLE before statement date (should not be counted)
        Amount *= 2;
        ClosedBankAccountLedgerEntry(BankAccount, Amount, BeforeStatementDate);

        // [GIVEN] A closed BLE after statement date (should be counted)
        Amount *= 2;
        ClosedBankAccountLedgerEntry(BankAccount, Amount, AfterStatementDate);
        ExpectedAmount += Amount;

        // [GIVEN] A matched BLE in the current bank rec (should not be counted)
        Amount *= 2;
        BankAccountLedgerEntry := OpenBankAccountLedgerEntry(BankAccount, Amount);
        CreateLineMatchingBLE(CurrentBankRec, BankAccountLedgerEntry);

        // [GIVEN] A matched open BLE in another bank rec with statement date after current bank rec (should be counted)
        Amount *= 2;
        BankAccountLedgerEntry := OpenBankAccountLedgerEntry(BankAccount, Amount);
        CreateLineMatchingBLE(BankRecAfter, BankAccountLedgerEntry);
        ExpectedAmount += Amount;

        // [GIVEN] A matched open BLE in another bank rec with statement date before current bank rec (should not be counted)
        Amount *= 2;
        BankAccountLedgerEntry := OpenBankAccountLedgerEntry(BankAccount, Amount);
        CreateLineMatchingBLE(BankRecBefore, BankAccountLedgerEntry);

        // [GIVEN] A corrupted entry Closed at Date = 0D and Open = false (should not be counted)
        Amount *= 2;
        CorruptClosedBankAccountLedgerEntry(BankAccount, Amount);

        // [GIVEN] An unmatched open BLE with a CLE (should not be counted)
        Amount *= 2;
        BankAccountLedgerEntry := OpenBankAccountLedgerEntry(BankAccount, Amount);
        CreateCheckLedgerEntryForBLE(BankAccountLedgerEntry);

        // [WHEN] We calculate total outstanding transactions
        // [THEN] The total outstanding transactions is the sum of the amounts of the BLE that should be counted
        Assert.AreEqual(ExpectedAmount, BankRecTestReport.TotalOutstandingBankTransactions(CurrentBankRec), 'Total outstanding transactions calculation is incorrect.');
    end;

    local procedure CreateCheckLedgerEntryForBLE(BankAccountLedgerEntry: Record "Bank Account Ledger Entry") CheckLedgerEntry: Record "Check Ledger Entry";
    begin
        CheckLedgerEntry."Bank Account Ledger Entry No." := BankAccountLedgerEntry."Entry No.";
        CheckLedgerEntry."Entry No." := BankAccountLedgerEntry."Entry No.";
        CheckLedgerEntry.Amount := BankAccountLedgerEntry.Amount;
        CheckLedgerEntry.Insert();
    end;

    local procedure CreateLineMatchingBLE(BankAccReconciliation: Record "Bank Acc. Reconciliation"; var BankAccountLedgerEntry: Record "Bank Account Ledger Entry")
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        LibraryERM.CreateBankAccReconciliationLn(BankAccReconciliationLine, BankAccReconciliation);
        BankAccountLedgerEntry."Statement No." := BankAccReconciliation."Statement No.";
        BankAccountLedgerEntry."Statement Status" := BankAccountLedgerEntry."Statement Status"::"Bank Acc. Entry Applied";
        BankAccountLedgerEntry.Modify();
    end;

    local procedure OpenBankAccountLedgerEntry(BankAccount: Record "Bank Account"; Amount: Decimal) BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    var
        LastEntryNo: Integer;
    begin
        BankAccountLedgerEntry.FindLast();
        LastEntryNo := BankAccountLedgerEntry."Entry No.";
        Clear(BankAccountLedgerEntry);
        BankAccountLedgerEntry."Entry No." := LastEntryNo + 1;
        BankAccountLedgerEntry."Bank Account No." := BankAccount."No.";
        BankAccountLedgerEntry.Amount := Amount;
        BankAccountLedgerEntry.Open := true;
        BankAccountLedgerEntry.Insert();
    end;

    local procedure ClosedBankAccountLedgerEntry(BankAccount: Record "Bank Account"; Amount: Decimal; ClosedAtDate: Date) BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    var
        LastEntryNo: Integer;
    begin
        BankAccountLedgerEntry.FindLast();
        LastEntryNo := BankAccountLedgerEntry."Entry No.";
        Clear(BankAccountLedgerEntry);
        BankAccountLedgerEntry."Entry No." := LastEntryNo + 1;
        BankAccountLedgerEntry."Bank Account No." := BankAccount."No.";
        BankAccountLedgerEntry.Amount := Amount;
        BankAccountLedgerEntry.Open := false;
        BankAccountLedgerEntry."Closed at Date" := ClosedAtDate;
        BankAccountLedgerEntry."Statement Status" := BankAccountLedgerEntry."Statement Status"::Closed;
        BankAccountLedgerEntry."Statement No." := 'OLDREC';
        BankAccountLedgerEntry.Insert();
    end;

    // Entries as corrupted ones found in some NA environments
    local procedure CorruptClosedBankAccountLedgerEntry(BankAccount: Record "Bank Account"; Amount: Decimal) BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    var
        LastEntryNo: Integer;
    begin
        BankAccountLedgerEntry.FindLast();
        LastEntryNo := BankAccountLedgerEntry."Entry No.";
        Clear(BankAccountLedgerEntry);
        BankAccountLedgerEntry."Entry No." := LastEntryNo + 1;
        BankAccountLedgerEntry."Bank Account No." := BankAccount."No.";
        BankAccountLedgerEntry.Amount := Amount;
        BankAccountLedgerEntry.Open := false;
        BankAccountLedgerEntry."Closed at Date" := 0D;
        BankAccountLedgerEntry."Statement Status" := BankAccountLedgerEntry."Statement Status"::Closed;
        BankAccountLedgerEntry."Statement No." := 'OLDREC';
        BankAccountLedgerEntry.Insert();
    end;
}