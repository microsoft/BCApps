codeunit 134255 "Delete Bank Reconciliation"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var

        Assert: Codeunit Assert;
        LedgerEntryDate: Date;


    [Test]
    [HandlerFunctions('BankAccReconciliationPageHandler,SuggestBankLedgerEntriesLinesHandler')]
    procedure ReapplyBankLedgerEntries()
    var
        BankAccountReconciliation: Record "Bank Acc. Reconciliation";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        BankAccount: Record "Bank Account";
        BankAccLedgerEntryNo1, BankAccLedgerEntryNo2 : Integer;
        BankAccountNo, StatementNo : Code[20];
    begin
        BankAccountNo := 'bank account no.';
        StatementNo := 'statement no.';
        LedgerEntryDate := Today;

        // [GIVEN] A bank account
        BankAccount.DeleteAll();
        CreateBankAccount(BankAccountNo);

        // [GIVEN] 2 bank ledger entries
        BankAccountLedgerEntry.DeleteAll();
        BankAccLedgerEntryNo1 := 40;
        BankAccLedgerEntryNo2 := 50;
        CreateBankAccountLedgerEntry(BankAccLedgerEntryNo1, BankAccountNo);
        CreateBankAccountLedgerEntry(BankAccLedgerEntryNo2, BankAccountNo);

        // [GIVEN] The 2 bank ledger entries are suggested as lines for a bank account 
        // reconciliation
        SuggestLedgerEntryLinesForBankAccReconciliation(BankAccountNo, StatementNo, LedgerEntryDate);
        VerifyStatementLines(BankAccountNo, StatementNo);

        // [WHEN] Deleting the bank account reconciliation
        BankAccountReconciliation.DeleteAll(true);

        // [THEN] The bank account ledger entries get reset correctly
        Assert.IsTrue(IsBankLedgerEntryReset(BankAccLedgerEntryNo1),
            'The first bank account ledger entry was not reset correctly.');
        Assert.IsTrue(IsBankLedgerEntryReset(BankAccLedgerEntryNo2),
            'The second bank account ledger entry was not reset correctly.');

        // [WHEN] Suggesting lines for a new bank reconciliation        
        SuggestLedgerEntryLinesForBankAccReconciliation(BankAccountNo, StatementNo, LedgerEntryDate);

        // [THEN] The two ledger entries can be added to the new bank account reconciliation
        VerifyStatementLines(BankAccountNo, StatementNo);
    end;

    [Test]
    [HandlerFunctions('BankAccReconciliationPageHandler,SuggestBankLedgerEntriesLinesHandler')]
    procedure ReapplyBankAndCheckLedgerEntries()
    var
        BankAccountReconciliation: Record "Bank Acc. Reconciliation";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        CheckLedgerEntry: Record "Check Ledger Entry";
        BankAccount: Record "Bank Account";
        CheckLedgerEntryNo1, CheckLedgerEntryNo2 : Integer;
        BankAccountNo, StatementNo : Code[20];
    begin
        BankAccountNo := 'bank account no.';
        StatementNo := 'statement no.';
        LedgerEntryDate := Today;

        // [GIVEN] A bank account
        BankAccount.DeleteAll();
        CreateBankAccount(BankAccountNo);

        // [GIVEN] 2 check ledger entries
        BankAccountLedgerEntry.DeleteAll();
        CheckLedgerEntry.DeleteAll();
        CheckLedgerEntryNo1 := 40;
        CheckLedgerEntryNo2 := 50;
        CreateCheckLedgerEntry(CheckLedgerEntryNo1, BankAccountNo);
        CreateCheckLedgerEntry(CheckLedgerEntryNo2, BankAccountNo);

        // [GIVEN] The 2 ledger entries are suggested as lines for a bank account 
        // reconciliation
        SuggestLedgerEntryLinesForBankAccReconciliation(BankAccountNo, StatementNo, LedgerEntryDate);
        VerifyStatementLines(BankAccountNo, StatementNo);

        // [WHEN] Deleting the bank account reconciliation
        BankAccountReconciliation.DeleteAll(true);

        // [THEN] The check ledger entries are reset correctly
        Assert.IsTrue(IsCheckLedgerEntryReset(CheckLedgerEntryNo1),
            'The first check ledger entry was not reset correctly.');
        Assert.IsTrue(IsCheckLedgerEntryReset(CheckLedgerEntryNo2),
            'The second check ledger entry was not reset correctly.');

        // [WHEN] Suggesting lines for a new bank reconciliation        
        SuggestLedgerEntryLinesForBankAccReconciliation(BankAccountNo, StatementNo, LedgerEntryDate);

        // [THEN] The two ledger entries can be added to the new bank account reconciliation
        VerifyStatementLines(BankAccountNo, StatementNo);
    end;

    local procedure IsBankLedgerEntryReset(EntryNo: Integer): Boolean
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        BankAccountLedgerEntry.SetRange("Entry No.", EntryNo);
        if not BankAccountLedgerEntry.FindFirst() then
            exit(false);

        exit((BankAccountLedgerEntry."Statement Line No." = 0)
            and (BankAccountLedgerEntry."Statement No." = '')
            and (BankAccountLedgerEntry."Statement Status" = BankAccountLedgerEntry."Statement Status"::Open)
            and BankAccountLedgerEntry.Open);
    end;

    local procedure IsCheckLedgerEntryReset(EntryNo: Integer): Boolean
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
    begin
        CheckLedgerEntry.SetRange("Entry No.", EntryNo);
        if not CheckLedgerEntry.FindFirst() then
            exit(false);

        exit((CheckLedgerEntry."Statement Line No." = 0)
            and (CheckLedgerEntry."Statement No." = '')
            and (CheckLedgerEntry."Statement Status" = CheckLedgerEntry."Statement Status"::Open)
            and CheckLedgerEntry.Open);
    end;

    local procedure SuggestLedgerEntryLinesForBankAccReconciliation(BankAccountNo: Code[20]; StatementNo: Code[20]; StatementDate: Date)
    var
        BankAccountReconciliation: Record "Bank Acc. Reconciliation";
        BankAccountReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        // [GIVEN] A bank account reconciliation
        BankAccountReconciliation.DeleteAll();
        CreateBankAccRec(BankAccountReconciliation, BankAccountNo, StatementNo, StatementDate);

        // [GIVEN] There are no bank account reconciliation lines
        BankAccountReconciliationLine.DeleteAll();

        // [WHEN] The 2 bank account ledger entries are suggested as lines for the bank 
        // account reconciliation 
        Commit();
        Page.Run(Page::"Bank Acc. Reconciliation", BankAccountReconciliation);
    end;

    local procedure VerifyStatementLines(BankAccountNo: Code[20]; StatementNo: Code[20])
    var
        BankAccountReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        BankAccountReconciliationLine.SetRange("Bank Account No.", BankAccountNo);
        BankAccountReconciliationLine.SetRange("Statement No.", StatementNo);
        Assert.AreEqual(2, BankAccountReconciliationLine.Count,
            'The bank account reconciliation should have 2 lines.');
    end;

    local procedure CreateBankAccRec(var BankAccRecon: Record "Bank Acc. Reconciliation"; BankAccNo: Code[20]; StatementNo: Code[20]; StatementDate: Date)
    begin
        BankAccRecon.Init();
        BankAccRecon."Bank Account No." := BankAccNo;
        BankAccRecon."Statement No." := StatementNo;
        BankAccRecon."Statement Date" := StatementDate;
        BankAccRecon."Statement Type" := BankAccRecon."Statement Type"::"Bank Reconciliation";
        BankAccRecon.Insert();
    end;

    local procedure CreateBankAccountLedgerEntry(EntryNo: Integer; BankAccountNo: Code[20])
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        BankAccountLedgerEntry."Entry No." := EntryNo;
        BankAccountLedgerEntry."Bank Account No." := BankAccountNo;
        BankAccountLedgerEntry."Statement Status" := BankAccountLedgerEntry."Statement Status"::Open;
        BankAccountLedgerEntry."Statement No." := '';
        BankAccountLedgerEntry."Statement Line No." := 0;
        BankAccountLedgerEntry."Posting Date" := LedgerEntryDate;
        BankAccountLedgerEntry.Open := true;
        BankAccountLedgerEntry.Insert();
    end;

    local procedure CreateCheckLedgerEntry(EntryNo: Integer; BankAccountNo: Code[20])
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
    begin
        CheckLedgerEntry."Entry No." := EntryNo;
        CheckLedgerEntry."Bank Account No." := BankAccountNo;
        CheckLedgerEntry."Statement Status" := CheckLedgerEntry."Statement Status"::Open;
        CheckLedgerEntry."Statement No." := '';
        CheckLedgerEntry."Statement Line No." := 0;
        CheckLedgerEntry."Check Date" := LedgerEntryDate;
        CheckLedgerEntry."Entry Status" := CheckLedgerEntry."Entry Status"::Posted;
        CheckLedgerEntry.Open := true;

        CreateBankAccountLedgerEntry(EntryNo, BankAccountNo);
        CheckLedgerEntry."Bank Account Ledger Entry No." := EntryNo;

        CheckLedgerEntry.Insert();
    end;

    local procedure CreateBankAccount(BankAccountNo: Code[20])
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount."No." := BankAccountNo;
        BankAccount.Insert();
    end;

    [PageHandler]
    procedure BankAccReconciliationPageHandler(var BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation")
    begin
        BankAccReconciliationPage.SuggestLines.Invoke();
    end;

    [RequestPageHandler]
    procedure SuggestBankLedgerEntriesLinesHandler(var SuggestBankAccReconLines: TestRequestPage "Suggest Bank Acc. Recon. Lines")
    begin
        SuggestBankAccReconLines.StartingDate.SetValue(LedgerEntryDate);
        SuggestBankAccReconLines.EndingDate.SetValue(LedgerEntryDate);
        SuggestBankAccReconLines.OK().Invoke();
    end;

}