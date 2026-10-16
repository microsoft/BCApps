// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Samples.BCLESnapshotDebugging.Tests;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.Period;
using Microsoft.Samples.BCLESnapshotDebugging;
using System.Security.User;
using System.TestLibraries.Utilities;

codeunit 99998 "My Demo Close Income Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        ClosingLinesCreatedMsg: Label 'The journal lines have successfully been created.';

    [Test]
    [HandlerFunctions('ClosingMessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure NoDimensionsConsolidatesClosingJournalLinesWithoutARC()
    var
        IncomeAccount: Record "G/L Account";
        BalancingAccount: Record "G/L Account";
        OutputJournalBatch: Record "Gen. Journal Batch";
        FiscalYearEndingDate: Date;
        ClosingDocumentNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Snapshot demo: the closing journal total differs from the test's expected posted balance.
        Initialize();

        // [GIVEN] Dimension-free income account "A", balancing account "B", and a closed fiscal year.
        CreateAccounts(IncomeAccount, BalancingAccount);
        FiscalYearEndingDate := CreateClosedFiscalYear();
        CreateOutputJournalBatch(OutputJournalBatch, FiscalYearEndingDate, ClosingDocumentNo);

        // [GIVEN] Three separate transactions for "A" totaling 600, with no currency, dimensions, or business unit.
        PostGeneralJournalTransaction(OutputJournalBatch, IncomeAccount."No.", BalancingAccount."No.", FiscalYearEndingDate, 100);
        PostGeneralJournalTransaction(OutputJournalBatch, IncomeAccount."No.", BalancingAccount."No.", FiscalYearEndingDate, 200);
        PostGeneralJournalTransaction(OutputJournalBatch, IncomeAccount."No.", BalancingAccount."No.", CalcDate('<1D>', FiscalYearEndingDate), 300);
        VerifyPostedEntries(IncomeAccount."No.");

        // [GIVEN] No saved dimension selections for this user and report, and an empty output batch "J".
        ClearSelectedDimensions();
        VerifyEmptyOutputBatch(OutputJournalBatch);

        // [WHEN] Close the income statement for "A" into "J" without a retained earnings account.
        RunCloseIncomeStatement(IncomeAccount, OutputJournalBatch, FiscalYearEndingDate);

        // [THEN] The closing total is -600 and exactly one closing journal line exists for "A".
        VerifyClosingJournalLines(OutputJournalBatch, IncomeAccount."No.", ClosingDocumentNo, FiscalYearEndingDate);
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        UserSetup: Record "User Setup";
    begin
        LibraryVariableStorage.Clear();
        // AutoRollback and ignored nested commits restore setup and posting data even when the assertion fails.
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Additional Reporting Currency" := '';
        GeneralLedgerSetup."Allow Posting From" := 0D;
        GeneralLedgerSetup."Allow Posting To" := 0D;
        GeneralLedgerSetup.Modify();
        if UserSetup.Get(UserId()) then begin
            UserSetup."Allow Posting From" := 0D;
            UserSetup."Allow Posting To" := 0D;
            UserSetup.Modify();
        end;
    end;

    local procedure CreateAccounts(var IncomeAccount: Record "G/L Account"; var BalancingAccount: Record "G/L Account")
    begin
        IncomeAccount.Init();
        IncomeAccount.Validate("No.", NewCode());
        IncomeAccount.Validate(Name, 'Close income statement regression');
        IncomeAccount.Validate("Account Type", IncomeAccount."Account Type"::Posting);
        IncomeAccount.Validate("Income/Balance", IncomeAccount."Income/Balance"::"Income Statement");
        IncomeAccount.Insert(true);

        BalancingAccount.Init();
        BalancingAccount.Validate("No.", NewCode());
        BalancingAccount.Validate(Name, 'Close income statement balancing');
        BalancingAccount.Validate("Account Type", BalancingAccount."Account Type"::Posting);
        BalancingAccount.Validate("Income/Balance", BalancingAccount."Income/Balance"::"Balance Sheet");
        BalancingAccount.Insert(true);
    end;

    local procedure CreateClosedFiscalYear(): Date
    var
        AccountingPeriod: Record "Accounting Period";
        FiscalYearStartDate: Date;
        PeriodIndex: Integer;
    begin
        FiscalYearStartDate := CalcDate('<-CY>', WorkDate());
        if AccountingPeriod.FindLast() then
            FiscalYearStartDate := CalcDate('<CY+1D>', AccountingPeriod."Starting Date");

        for PeriodIndex := 0 to 12 do begin
            AccountingPeriod.Init();
            AccountingPeriod.Validate("Starting Date", CalcDate(StrSubstNo('<%1M>', PeriodIndex), FiscalYearStartDate));
            AccountingPeriod.Validate("New Fiscal Year", PeriodIndex in [0, 12]);
            AccountingPeriod.Closed := PeriodIndex < 12;
            AccountingPeriod."Date Locked" := true;
            AccountingPeriod.Insert(true);
        end;

        exit(CalcDate('<1Y-1D>', FiscalYearStartDate));
    end;

    local procedure CreateOutputJournalBatch(var OutputJournalBatch: Record "Gen. Journal Batch"; PostingDate: Date; var ClosingDocumentNo: Code[20])
    var
        JournalTemplate: Record "Gen. Journal Template";
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        NoSeriesManagement: Codeunit "No. Series";
    begin
        JournalTemplate.Init();
        JournalTemplate.Name := CopyStr(NewCode(), 1, MaxStrLen(JournalTemplate.Name));
        JournalTemplate.Insert(true);
        JournalTemplate.Validate(Type, JournalTemplate.Type::General);
        JournalTemplate.Modify(true);

        NoSeries.Init();
        NoSeries.Code := NewCode();
        NoSeries."Default Nos." := true;
        NoSeries.Insert(true);

        NoSeriesLine.Init();
        NoSeriesLine.Validate("Series Code", NoSeries.Code);
        NoSeriesLine."Line No." := 10000;
        NoSeriesLine."Starting Date" := PostingDate;
        NoSeriesLine."Starting No." := CopyStr(NewCode(), 1, 10) + '000001';
        NoSeriesLine."Ending No." := IncStr(NoSeriesLine."Starting No.");
        NoSeriesLine."Increment-by No." := 1;
        NoSeriesLine.Open := true;
        NoSeriesLine.Insert(true);

        OutputJournalBatch.Init();
        OutputJournalBatch.Validate("Journal Template Name", JournalTemplate.Name);
        OutputJournalBatch.Name := 'CLOSE';
        OutputJournalBatch.Insert(true);
        OutputJournalBatch.Validate("No. Series", NoSeries.Code);
        OutputJournalBatch.Modify(true);
        ClosingDocumentNo := NoSeriesManagement.PeekNextNo(NoSeries.Code, PostingDate);
    end;

    local procedure PostGeneralJournalTransaction(OutputJournalBatch: Record "Gen. Journal Batch"; IncomeAccountNo: Code[20]; BalancingAccountNo: Code[20]; PostingDate: Date; Amount: Decimal)
    var
        GeneralJournalLine: Record "Gen. Journal Line";
        SourceCodeSetup: Record "Source Code Setup";
        GeneralJournalPostLine: Codeunit "Gen. Jnl.-Post Line";
    begin
        SourceCodeSetup.Get();
        GeneralJournalLine.Init();
        GeneralJournalLine.Validate("Journal Template Name", OutputJournalBatch."Journal Template Name");
        GeneralJournalLine.Validate("Journal Batch Name", OutputJournalBatch.Name);
        GeneralJournalLine."Line No." := 10000;
        GeneralJournalLine.Validate("Posting Date", PostingDate);
        GeneralJournalLine."Document No." := NewCode();
        GeneralJournalLine.Validate("Account Type", GeneralJournalLine."Account Type"::"G/L Account");
        GeneralJournalLine.Validate("Account No.", IncomeAccountNo);
        GeneralJournalLine.Validate("Bal. Account Type", GeneralJournalLine."Bal. Account Type"::"G/L Account");
        GeneralJournalLine.Validate("Bal. Account No.", BalancingAccountNo);
        GeneralJournalLine.Validate(Amount, Amount);
        GeneralJournalLine."Source Code" := SourceCodeSetup."General Journal";
        GeneralJournalPostLine.RunWithCheck(GeneralJournalLine);
    end;

    local procedure VerifyPostedEntries(IncomeAccountNo: Code[20])
    var
        GeneralLedgerEntry: Record "G/L Entry";
    begin
        GeneralLedgerEntry.SetRange("G/L Account No.", IncomeAccountNo);
        Assert.AreEqual(3, GeneralLedgerEntry.Count(), 'The income account must have exactly three original entries.');
        GeneralLedgerEntry.SetRange("Dimension Set ID", 0);
        GeneralLedgerEntry.SetRange("Source Currency Code", '');
        GeneralLedgerEntry.SetRange("Business Unit Code", '');
        Assert.AreEqual(3, GeneralLedgerEntry.Count(), 'All original entries must have no grouping attributes.');
        GeneralLedgerEntry.CalcSums(Amount);
        Assert.AreEqual(600, GeneralLedgerEntry.Amount, 'The original balance must be 600.');
    end;

    local procedure ClearSelectedDimensions()
    var
        SelectedDimension: Record "Selected Dimension";
    begin
        SelectedDimension.SetRange("User ID", UserId());
        SelectedDimension.SetRange("Object Type", 3);
        SelectedDimension.SetRange("Object ID", Report::"My Demo Close Income Statement");
        SelectedDimension.SetRange("Analysis View Code", '');
        SelectedDimension.DeleteAll(true);
        Assert.IsTrue(SelectedDimension.IsEmpty(), 'The report must have no selected dimensions.');
    end;

    local procedure VerifyEmptyOutputBatch(OutputJournalBatch: Record "Gen. Journal Batch")
    var
        GeneralJournalLine: Record "Gen. Journal Line";
    begin
        GeneralJournalLine.SetRange("Journal Template Name", OutputJournalBatch."Journal Template Name");
        GeneralJournalLine.SetRange("Journal Batch Name", OutputJournalBatch.Name);
        Assert.IsTrue(GeneralJournalLine.IsEmpty(), 'The output journal batch must be empty before closing.');
    end;

    local procedure RunCloseIncomeStatement(IncomeAccount: Record "G/L Account"; OutputJournalBatch: Record "Gen. Journal Batch"; FiscalYearEndingDate: Date)
    var
        GeneralJournalLine: Record "Gen. Journal Line";
        RetainedEarningsAccount: Record "G/L Account";
        CloseIncomeStatement: Report "My Demo Close Income Statement";
    begin
        GeneralJournalLine."Journal Template Name" := OutputJournalBatch."Journal Template Name";
        GeneralJournalLine."Journal Batch Name" := OutputJournalBatch.Name;
        IncomeAccount.SetRecFilter();
        CloseIncomeStatement.SetTableView(IncomeAccount);
        CloseIncomeStatement.InitializeRequestTest(FiscalYearEndingDate, GeneralJournalLine, RetainedEarningsAccount, false);
        CloseIncomeStatement.UseRequestPage(false);
        CloseIncomeStatement.RunModal();
    end;

    local procedure VerifyClosingJournalLines(OutputJournalBatch: Record "Gen. Journal Batch"; IncomeAccountNo: Code[20]; ClosingDocumentNo: Code[20]; FiscalYearEndingDate: Date)
    var
        GeneralJournalLine: Record "Gen. Journal Line";
    begin
        Assert.AreEqual(ClosingLinesCreatedMsg, LibraryVariableStorage.DequeueText(), 'Closing must finish by creating journal lines.');
        LibraryVariableStorage.AssertEmpty();
        GeneralJournalLine.SetRange("Journal Template Name", OutputJournalBatch."Journal Template Name");
        GeneralJournalLine.SetRange("Journal Batch Name", OutputJournalBatch.Name);
        GeneralJournalLine.SetRange("Document No.", ClosingDocumentNo);
        GeneralJournalLine.SetRange("Account Type", GeneralJournalLine."Account Type"::"G/L Account");
        GeneralJournalLine.SetRange("Account No.", IncomeAccountNo);
        GeneralJournalLine.SetRange("Posting Date", ClosingDate(FiscalYearEndingDate));
        Assert.AreEqual(1, GeneralJournalLine.Count(), 'Entries without selected dimensions must consolidate into one closing journal line.');
        GeneralJournalLine.CalcSums(Amount);
        Assert.AreEqual(-600, GeneralJournalLine.Amount, 'Closing lines must reverse the entire income account balance.');
    end;

    local procedure NewCode(): Code[20]
    begin
        exit(CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 20));
    end;

    [MessageHandler]
    procedure ClosingMessageHandler(MessageText: Text[1024])
    begin
        LibraryVariableStorage.Enqueue(MessageText);
    end;
}
