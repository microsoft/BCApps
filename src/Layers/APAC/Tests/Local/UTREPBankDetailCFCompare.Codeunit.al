codeunit 141071 "UT REP Bank Detail CF Compare"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Cash Flow] [Report] [Bank Detail Cashflow Compare] [UT]
    end;

    var
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        BankAccBalanceCap: Label 'BankAccBalance';
        BankAccBalanceLCYCap: Label 'BankAccBalanceLCY';
        StartBalanceCap: Label 'StartBalance';
        StartBalanceLCYCap: Label 'StartBalanceLCY';

    [Test]
    [HandlerFunctions('BankDetailCashflowCompareRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordBankAccountBankDetailCFCompare()
    begin
        // [SCENARIO] validate BankAccount - OnAfterGetRecord Trigger of Report - 28020 Bank Detail Cashflow Compare with blank Date Filter.

        // Setup & Exercise.
        Initialize();
        CreateBankAccLedgAndRunBankDetailCFCompareReport(0D, 0D, 0D);  // Using 0D as CompareStartDate, CompareEndDate and Date Filter.

        // Verify.
        VerifyXMLValuesOnBankDetailCashflowCompare(StartBalanceCap, StartBalanceLCYCap, 0);  // Using 0 for Balance Amount.
    end;

    [Test]
    [HandlerFunctions('BankDetailCashflowCompareRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecBankAccLedgerEntryBankDetailCFCompare()
    begin
        // [SCENARIO] validate BankAccountLedgerEntry - OnAfterGetRecord Trigger of Report - 28020 Bank Detail Cashflow Compare.
        BankDetailCashflowCompareWithDifferentDateFilters(0D, 0D, WorkDate());  // Using 0D as CompareStartDate, CompareEndDate and WORKDATE as Date Filter.
    end;

    [Test]
    [HandlerFunctions('BankDetailCashflowCompareRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecBankAccLedgerEntryTwoBankDtlCFCompare()
    begin
        // [SCENARIO] validate BankAccountLedgerEntry2 - OnAfterGetRecord Trigger of Report - 28020 Bank Detail Cashflow Compare.
        BankDetailCashflowCompareWithDifferentDateFilters(WorkDate(), WorkDate(), 0D);  // Using WORKDATE as CompareStartDate, CompareEndDate and 0D as Date Filter.
    end;

    local procedure BankDetailCashflowCompareWithDifferentDateFilters(CompareStartDate: Date; CompareEndDate: Date; DateFilter: Date)
    var
        Amount: Decimal;
    begin
        // Setup & Exercise.
        Initialize();
        Amount := CreateBankAccLedgAndRunBankDetailCFCompareReport(CompareStartDate, CompareEndDate, DateFilter);

        // Verify.
        VerifyXMLValuesOnBankDetailCashflowCompare(BankAccBalanceCap, BankAccBalanceLCYCap, Amount);
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
        BankAccount."Date Filter" := WorkDate();
        BankAccount.Insert();
        exit(BankAccount."No.");
    end;

    local procedure CreateBankAccountLedgerEntry(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry")
    begin
        BankAccountLedgerEntry."Bank Account No." := CreateBankAccount();
        BankAccountLedgerEntry."Posting Date" := WorkDate();
        BankAccountLedgerEntry.Amount := LibraryRandom.RandDec(100, 2);
        BankAccountLedgerEntry."Amount (LCY)" := BankAccountLedgerEntry.Amount;
        BankAccountLedgerEntry.Insert();
    end;

    local procedure CreateBankAccLedgAndRunBankDetailCFCompareReport(CompareStartDate: Date; CompareEndDate: Date; DateFilter: Date): Decimal
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        // Setup.
        CreateBankAccountLedgerEntry(BankAccountLedgerEntry);

        // Enqueue values for BankDetailCashflowCompareRequestPageHandler.
        LibraryVariableStorage.Enqueue(CompareStartDate);
        LibraryVariableStorage.Enqueue(CompareEndDate);
        LibraryVariableStorage.Enqueue(BankAccountLedgerEntry."Bank Account No.");
        LibraryVariableStorage.Enqueue(DateFilter);

        // Exercise.
        REPORT.Run(REPORT::"Bank Detail Cashflow Compare");
        exit(BankAccountLedgerEntry.Amount);
    end;

    local procedure VerifyXMLValuesOnBankDetailCashflowCompare(AmountCaption: Text; AmountLCYCaption: Text; ExpectedValue: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(AmountCaption, ExpectedValue);
        LibraryReportDataset.AssertElementWithValueExists(AmountLCYCaption, ExpectedValue);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BankDetailCashflowCompareRequestPageHandler(var BankDetailCashflowCompare: TestRequestPage "Bank Detail Cashflow Compare")
    var
        CompareEndDate: Variant;
        CompareStartDate: Variant;
        DateFilter: Variant;
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(CompareStartDate);
        LibraryVariableStorage.Dequeue(CompareEndDate);
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(DateFilter);
        BankDetailCashflowCompare.CompareStartDate.SetValue(CompareStartDate);
        BankDetailCashflowCompare.CompareEndDate.SetValue(CompareEndDate);
        BankDetailCashflowCompare."Bank Account".SetFilter("No.", No);
        BankDetailCashflowCompare."Bank Account".SetFilter("Date Filter", Format(DateFilter));
        BankDetailCashflowCompare.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

