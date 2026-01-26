codeunit 142056 "UT REP Bank Reconciliation"
{

    // Validate feature Bank Reconciliation.
    //  1. Verify values updated on Bank Rec. Test Report after creating Bank Rec Line for Adjustment.
    //  2. Verify error text value updated on Bank Rec. Test Report after creating Bank Rec Line for Adjustment.
    //  3. Verify Bank Account No. on Bank Reconciliation Report after creating Posted Bank Rec. Header and Line.
    //  4. Verify Bank Account No. on Bank Account - Reconcile Report after creating Bank Account Ledger Entry.
    //  5. Purpose of the test is to validate Push Action for Page 10120 Bank Rec.Worksheet.
    // 
    //  Covers Test Cases for WI - 336180,336609
    //  -----------------------------------------------------------------------------------------------------
    //  Test Function Name                                                                             TFS ID
    //  -----------------------------------------------------------------------------------------------------
    //  OnAfterGetRecordAdjustmentBankRecTest, OnAfterGetRecordBankRecHeaderBankRecTest   171129,171130,171131
    //  OnAfterGetRecordPostedBankRecHeaderPositiveTrueBankReconciliation                 266821
    //  OnAfterGetRecordPostedBankRecHeaderPositiveFalseBankReconciliation                266821
    //  OnAfterGetRecordBankAccountLedgerEntryBankAccountReconcile                        266821
    // 
    //  Covers Test Cases for WI - 338943
    //  -----------------------------------------------------------------------------------------------------
    //  Test Function Name                                                                             TFS ID
    //  -----------------------------------------------------------------------------------------------------
    //  ValidateTestReportActionOnPageBankRecWorkSheet

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Bank Reconciliation]
    end;

    var
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [HandlerFunctions('BankAccountReconcileRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordBankAccountLedgerEntryBankAccountReconcile()
    var
        BankAccountNo: Code[20];
    begin
        // Purpose of the test is to validate Bank Account Ledger Entry - OnAfterGetRecord trigger of Report ID - 10409.
        // Setup: Create Bank Account Ledger Entry.
        Initialize();
        BankAccountNo := CreateBankAccountLedgerEntry();

        // Exercise.
        REPORT.Run(REPORT::"Bank Account - Reconcile");  // Opens BankAccountReconcileRequestPageHandler;

        // Verify: Verify Bank Account No. after report generation.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('No_BankAccount', BankAccountNo);
    end;

    [Test]
    [HandlerFunctions('CheckRequestPageHandler,BankAccountReconcileRequestPageHandler')]
    [Scope('OnPrem')]
    procedure BankAccountReconcileForPaymentWithCheck()
    var
        BankAccount: Record "Bank Account";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlTemplate: Record "Gen. Journal Template";
        Amount: Integer;
    begin
        // [SCENARIO 375775] Check Amount is negative in report "Bank Account - Reconcile". 
        Initialize();

        // [GIVEN] Bank Account "B" with Last Check No.
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Last Check No.", BankAccount."No.");
        BankAccount.Modify(true);

        // [GIVEN] Payment Journal line with Amount = 100, "Bal. Account No" = "B" and "Bank Payment Type" = "Computer Check".
        LibraryERM.CreateGenJournalTemplate(GenJnlTemplate);
        LibraryERM.CreateGenJournalBatch(GenJnlBatch, GenJnlTemplate.Name);
        Amount := LibraryRandom.RandInt(100);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
            GenJnlLine, GenJnlTemplate.Name, GenJnlBatch.Name, GenJnlLine."Document Type"::Payment, GenJnlLine."Account Type"::Vendor,
            LibraryPurchase.CreateVendorNo(), GenJnlLine."Bal. Account Type"::"Bank Account", BankAccount."No.", Amount);
        GenJnlLine.Validate("Bank Payment Type", GenJnlLine."Bank Payment Type"::"Computer Check");
        GenJnlLine.Modify(true);

        // [GIVEN] Check printed for Payment Journal line.
        Commit();
        LibraryVariableStorage.Enqueue(BankAccount."No.");
        GenJnlLine.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
        REPORT.Run(REPORT::"Check", true, true, GenJnlLine);

        // [GIVEN] Payment Journal Line posted.
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        // [WHEN] Report "Bank Account - Reconcile" is run for Bank Account "B".
        LibraryVariableStorage.Enqueue(BankAccount."No.");
        REPORT.Run(REPORT::"Bank Account - Reconcile");

        // [THEN] In result dataset Amount_CheckLedgEntry = -100, WithdrawAmount = -100.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Amount_CheckLedgEntry', -Amount);
        LibraryReportDataset.AssertElementWithValueExists('WithdrawAmount', -Amount);
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateBankAccount(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount."No." := LibraryUTUtility.GetNewCode();
        BankAccount.Insert();
        exit(BankAccount."No.");
    end;

    local procedure CreateBankAccountLedgerEntry(): Code[20]
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        BankAccountLedgerEntry2: Record "Bank Account Ledger Entry";
    begin
        BankAccountLedgerEntry2.FindLast();
        BankAccountLedgerEntry."Entry No." := BankAccountLedgerEntry2."Entry No." + 1;
        BankAccountLedgerEntry."Bank Account No." := CreateBankAccount();
        BankAccountLedgerEntry."Document Type" := BankAccountLedgerEntry."Document Type"::Payment;
        BankAccountLedgerEntry.Amount := LibraryRandom.RandDec(10, 2);

        // Enqueue required inside BankAccountReconcileRequestPageHandler.
        LibraryVariableStorage.Enqueue(BankAccountLedgerEntry."Bank Account No.");
        exit(BankAccountLedgerEntry."Bank Account No.");
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BankAccountReconcileRequestPageHandler(var BankAccountReconcile: TestRequestPage "Bank Account - Reconcile")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        BankAccountReconcile."Bank Account".SetFilter("No.", No);
        BankAccountReconcile.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CheckRequestPageHandler(var Check: TestRequestPage Check)
    begin
        Check.BankAccount.SetValue(LibraryVariableStorage.DequeueText());
        Check.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}