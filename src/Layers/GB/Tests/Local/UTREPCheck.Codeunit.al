codeunit 144051 "UT REP Check"
{
    // // [FEATURE] [Reports]
    // Test for feature CHECK - Reports Check.

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportDataset: Codeunit "Library - Report Dataset";

    [Test]
    [HandlerFunctions('CheckRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPrintCheck()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CheckAmountText: Text;
    begin
        // Purpose of the test is to validate PrintCheck - OnAfterGetRecord Trigger of Report 1401 - Check.

        // Setup: Create Bank Account and General Journal Line.
        Initialize();
        CreateGeneralJournalLine(GenJournalLine, GenJournalLine."Account Type"::"Bank Account", CreateBankAccount());
        CheckAmountText := DelChr(Format(GenJournalLine.Amount, 0, '**<Sign><Integer>-<Decimals,3>**'), '=', '.');  // Calculation of format String and DELCHR based on Report - Check.

        // Exercise.
        REPORT.Run(REPORT::Check);  // Opens handler - CheckRequestPageHandler.

        // Verify: Verify Line Amount and Check Amount Text on Report - Check.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('LineAmount', GenJournalLine.Amount);
        LibraryReportDataset.AssertElementWithValueExists('CheckAmountText', CheckAmountText);
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
        BankAccount."Last Check No." := LibraryUTUtility.GetNewCode();
        BankAccount.Insert();
        LibraryVariableStorage.Enqueue(BankAccount."No.");  // Enqueue value for Request Page handler - CheckRequestPageHandler.
        exit(BankAccount."No.")
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGenJournalTemplateAndBatch(GenJournalBatch);
        GenJournalLine."Journal Template Name" := GenJournalBatch."Journal Template Name";
        GenJournalLine."Journal Batch Name" := GenJournalBatch.Name;
        GenJournalLine."Account Type" := AccountType;
        GenJournalLine."Account No." := AccountNo;
        GenJournalLine."Bal. Account Type" := GenJournalLine."Bal. Account Type"::"Bank Account";
        GenJournalLine."Bal. Account No." := GenJournalLine."Account No.";
        GenJournalLine."Document No." := LibraryUTUtility.GetNewCode();
        GenJournalLine."Bank Payment Type" := GenJournalLine."Bank Payment Type"::"Computer Check";
        GenJournalLine."Applies-to ID" := LibraryUTUtility.GetNewCode();
        GenJournalLine.Amount := LibraryRandom.RandDec(10, 2);
        GenJournalLine.Insert();

        // Enqueue value for Request Page handler - CheckRequestPageHandler.
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Batch Name");
    end;

    local procedure CreateGenJournalTemplateAndBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.Name := LibraryUTUtility.GetNewCode10();
        GenJournalTemplate.Insert();
        GenJournalBatch."Journal Template Name" := GenJournalTemplate.Name;
        GenJournalBatch.Name := LibraryUTUtility.GetNewCode10();
        GenJournalBatch.Insert();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CheckRequestPageHandler(var Check: TestRequestPage Check)
    var
        BankAccount: Variant;
        JournalTemplateName: Variant;
        JournalBatchName: Variant;
    begin
        LibraryVariableStorage.Dequeue(BankAccount);
        LibraryVariableStorage.Dequeue(JournalTemplateName);
        LibraryVariableStorage.Dequeue(JournalBatchName);
        Check.VoidGenJnlLine.SetFilter("Journal Template Name", JournalTemplateName);
        Check.VoidGenJnlLine.SetFilter("Journal Batch Name", JournalBatchName);
        Check.BankAccount.SetValue(BankAccount);
        Check.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

