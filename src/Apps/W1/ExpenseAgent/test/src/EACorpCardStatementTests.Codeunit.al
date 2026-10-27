// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.Bank.Ledger;
using Microsoft.Bank.Reconciliation;
using Microsoft.ExpenseAgent;

codeunit 148359 EACorpCardStatementTests
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        CorpCardTestLib: Codeunit EACorpCardTestLib;
        ExpectedStatementEntryNo: Integer;

    [Test]
    [HandlerFunctions('StatementLookupHandler')]
    procedure SettlementLineUsesLightweightStatementLookup()
    var
        CorpCardSettlement: Record "EA Corp Card Settlement";
        CorpCardSettlementLine: Record "EA Corp Card Settlement Line";
        CorpCardStatement: Record "EA Corp Card Statement";
        SettlementLines: TestPage "EA Corp Card Settlement Lines";
    begin
        Initialize();
        CreateStatement(CorpCardStatement, 'STMT-LOOKUP', 2000, 1);
        CorpCardStatement.Status := CorpCardStatement.Status::Validated;
        CorpCardStatement.Modify();
        ExpectedStatementEntryNo := CorpCardStatement."Statement Entry No.";
        CorpCardSettlement."Provider Code" := CorpCardStatement."Provider Code";
        CorpCardSettlement."Currency Code" := CorpCardStatement."Currency Code";
        CorpCardSettlement.Insert(false);
        CorpCardSettlementLine."Settlement Entry No." := CorpCardSettlement."Settlement Entry No.";
        CorpCardSettlementLine."Line No." := 10000;
        CorpCardSettlementLine.Insert(false);
        SettlementLines.OpenEdit();
        SettlementLines.GoToRecord(CorpCardSettlementLine);

        SettlementLines."Statement Entry No.".Lookup();

        Assert.AreEqual(Format(ExpectedStatementEntryNo), SettlementLines."Statement Entry No.".Value, 'The lookup must select the statement on the settlement line.');
        Assert.AreEqual(CorpCardStatement."Statement No.", SettlementLines."Statement No.".Value, 'The lookup must retain statement snapshot validation.');
        SettlementLines.Close();
    end;

    [ModalPageHandler]
    procedure StatementLookupHandler(var StatementLookup: TestPage "EA Corp Card Statement Lookup")
    begin
        StatementLookup.Filter.SetFilter("Statement Entry No.", Format(ExpectedStatementEntryNo));
        Assert.IsTrue(StatementLookup.First(), 'The statement must be available on the lightweight lookup.');
        StatementLookup.OK().Invoke();
    end;

    [Test]
    procedure StatementLookupShowsStatementDetails()
    var
        CorpCardStatement: Record "EA Corp Card Statement";
        StatementLookup: TestPage "EA Corp Card Statement Lookup";
    begin
        Initialize();
        CreateStatement(CorpCardStatement, 'STMT-LOOKUP-DETAILS', 2000, 1);

        StatementLookup.OpenView();
        StatementLookup.GoToRecord(CorpCardStatement);

        Assert.AreEqual(CorpCardStatement."Statement No.", StatementLookup."Statement No.".Value, 'The lookup must show the provider statement number.');
        Assert.AreEqual(CorpCardStatement."Currency Code", StatementLookup."Currency Code".Value, 'The lookup must show the statement currency.');
        StatementLookup.Close();
    end;

    [Test]
    procedure StatementSummaryFollowsCurrentStatement()
    var
        FirstStatement: Record "EA Corp Card Statement";
        SecondStatement: Record "EA Corp Card Statement";
        EmptyStatement: Record "EA Corp Card Statement";
        CorpCardTrans: Record "EA Corp Card Trans";
        CorpCardStmtSummary: Codeunit "EA Corp Card Stmt Summary";
        StatementSummary: TestPage "EA Corp Card Stmt. FactBox";
        Parameters: Dictionary of [Text, Text];
    begin
        Initialize();
        CreateStatement(FirstStatement, 'STMT-SUMMARY-A', 1000, 1);
        CreateTransaction(CorpCardTrans, FirstStatement, 'SUMMARY-A', 1000, 'EXP-SUMMARY-A');
        CreateStatement(SecondStatement, 'STMT-SUMMARY-B', 3000, 2);
        CreateTransaction(CorpCardTrans, SecondStatement, 'SUMMARY-B1', 1000, 'EXP-SUMMARY-B1');
        CreateTransaction(CorpCardTrans, SecondStatement, 'SUMMARY-B2', 2000, 'EXP-SUMMARY-B2');
        CreateStatement(EmptyStatement, 'STMT-SUMMARY-EMPTY', 0, 0);
        Commit();

        StatementSummary.OpenView();
        StatementSummary.GoToRecord(FirstStatement);
        Parameters.Set(CorpCardStmtSummary.GetStatementEntryNoKey(), Format(FirstStatement."Statement Entry No."));
        Assert.IsTrue(
            StatementSummary.RunPageBackgroundTask(Codeunit::"EA Corp Card Stmt Summary", Parameters, true).ContainsKey(CorpCardStmtSummary.GetUnreconciledTransactionsKey()),
            'The background task must return the reconciliation summary.');
        StatementSummary.UnreconciledTransactions.AssertEquals(1);
        StatementSummary.UnreconciledAmount.AssertEquals(1000);

        StatementSummary.GoToRecord(SecondStatement);
        Parameters.Set(CorpCardStmtSummary.GetStatementEntryNoKey(), Format(SecondStatement."Statement Entry No."));
        Assert.IsTrue(
            StatementSummary.RunPageBackgroundTask(Codeunit::"EA Corp Card Stmt Summary", Parameters, true).ContainsKey(CorpCardStmtSummary.GetUnreconciledTransactionsKey()),
            'The background task must return the reconciliation summary.');
        StatementSummary.UnreconciledTransactions.AssertEquals(2);
        StatementSummary.UnreconciledAmount.AssertEquals(3000);

        StatementSummary.GoToRecord(EmptyStatement);
        Parameters.Set(CorpCardStmtSummary.GetStatementEntryNoKey(), Format(EmptyStatement."Statement Entry No."));
        Assert.IsTrue(
            StatementSummary.RunPageBackgroundTask(Codeunit::"EA Corp Card Stmt Summary", Parameters, true).ContainsKey(CorpCardStmtSummary.GetUnreconciledTransactionsKey()),
            'The background task must return the reconciliation summary.');
        StatementSummary.ReconciledTransactions.AssertEquals(0);
        StatementSummary.ReconciledAmount.AssertEquals(0);
        StatementSummary.UnreconciledTransactions.AssertEquals(0);
        StatementSummary.UnreconciledAmount.AssertEquals(0);
        StatementSummary.SettlementStatus.AssertEquals('');

        StatementSummary.GoToRecord(FirstStatement);
        Parameters.Set(CorpCardStmtSummary.GetStatementEntryNoKey(), Format(FirstStatement."Statement Entry No."));
        Assert.IsTrue(
            StatementSummary.RunPageBackgroundTask(Codeunit::"EA Corp Card Stmt Summary", Parameters, true).ContainsKey(CorpCardStmtSummary.GetUnreconciledTransactionsKey()),
            'The background task must return the reconciliation summary.');
        StatementSummary.UnreconciledTransactions.AssertEquals(1);
        StatementSummary.UnreconciledAmount.AssertEquals(1000);
        StatementSummary.Close();
    end;

    [Test]
    procedure ValidateStatementIncludesAllTransactionsWithPartialRecords()
    var
        CorpCardStatement: Record "EA Corp Card Statement";
        CorpCardTrans: Record "EA Corp Card Trans";
        CorpCardStatementMgt: Codeunit "EA Corp Card Statement Mgt";
    begin
        Initialize();
        CreateStatement(CorpCardStatement, 'STMT-MULTI', 3000, 2);
        CreateTransaction(CorpCardTrans, CorpCardStatement, 'TRANS-MULTI-A', 1000, 'EXP-MULTI-A');
        CreateTransaction(CorpCardTrans, CorpCardStatement, 'TRANS-MULTI-B', 2000, 'EXP-MULTI-B');

        CorpCardStatementMgt.ValidateStatement(CorpCardStatement);

        CorpCardStatement.Get(CorpCardStatement."Statement Entry No.");
        Assert.AreEqual(CorpCardStatement.Status::Validated, CorpCardStatement.Status, 'Validation must read and total every transaction with partial records.');
    end;

    [Test]
    procedure ValidateStatementUsesImportedTransactionsAsLines()
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        CorpCardStatement: Record "EA Corp Card Statement";
        CorpCardTrans: Record "EA Corp Card Trans";
        CorpCardStatementMgt: Codeunit "EA Corp Card Statement Mgt";
        BankAccountLedgerEntryCount: Integer;
        BankAccReconciliationCount: Integer;
    begin
        Initialize();
        BankAccountLedgerEntryCount := BankAccountLedgerEntry.Count();
        BankAccReconciliationCount := BankAccReconciliation.Count();
        CreateStatement(CorpCardStatement, 'STMT-001', 2000, 1);
        CreateTransaction(CorpCardTrans, CorpCardStatement, 'TRANS-001', 2000, 'EXP-001');

        CorpCardStatementMgt.ValidateStatement(CorpCardStatement);

        CorpCardStatement.Get(CorpCardStatement."Statement Entry No.");
        Assert.AreEqual(CorpCardStatement.Status::Validated, CorpCardStatement.Status, 'A complete and balanced provider statement must be validated.');
        Assert.AreEqual(BankAccountLedgerEntryCount, BankAccountLedgerEntry.Count(), 'Provider statement validation must not create bank account ledger entries.');
        Assert.AreEqual(BankAccReconciliationCount, BankAccReconciliation.Count(), 'Provider statement validation must not create bank account reconciliations.');
    end;

    [Test]
    procedure ValidateStatementRejectsMissingImportedTransaction()
    var
        CorpCardStatement: Record "EA Corp Card Statement";
        CorpCardStatementMgt: Codeunit "EA Corp Card Statement Mgt";
    begin
        Initialize();
        CreateStatement(CorpCardStatement, 'STMT-002', 2000, 1);

        asserterror CorpCardStatementMgt.ValidateStatement(CorpCardStatement);

        Assert.ExpectedError('does not equal the number of stored statement transactions');
    end;

    [Test]
    procedure ValidateStatementRejectsDuplicateProviderStatement()
    var
        FirstStatement: Record "EA Corp Card Statement";
        DuplicateStatement: Record "EA Corp Card Statement";
        CorpCardTrans: Record "EA Corp Card Trans";
        CorpCardStatementMgt: Codeunit "EA Corp Card Statement Mgt";
    begin
        Initialize();
        CreateStatement(FirstStatement, 'STMT-003', 1000, 1);
        CreateTransaction(CorpCardTrans, FirstStatement, 'TRANS-003-A', 1000, 'EXP-003-A');
        CreateStatement(DuplicateStatement, 'STMT-003', 2000, 1);
        CreateTransaction(CorpCardTrans, DuplicateStatement, 'TRANS-003-B', 2000, 'EXP-003-B');

        asserterror CorpCardStatementMgt.ValidateStatement(DuplicateStatement);

        Assert.ExpectedError('already exists for provider');
    end;

    [Test]
    procedure ValidateStatementRejectsTransactionWithoutExpense()
    var
        CorpCardStatement: Record "EA Corp Card Statement";
        CorpCardTrans: Record "EA Corp Card Trans";
        CorpCardStatementMgt: Codeunit "EA Corp Card Statement Mgt";
    begin
        Initialize();
        CreateStatement(CorpCardStatement, 'STMT-004', 2000, 1);
        CreateTransaction(CorpCardTrans, CorpCardStatement, 'TRANS-004', 2000, '');

        asserterror CorpCardStatementMgt.ValidateStatement(CorpCardStatement);

        Assert.ExpectedError('is not matched to an expense');
    end;

    [Test]
    procedure ValidateStatementRejectsCardBlockedAfterImport()
    var
        CorpCard: Record "EA Corp Card";
        CorpCardStatement: Record "EA Corp Card Statement";
        CorpCardTrans: Record "EA Corp Card Trans";
        CorpCardStatementMgt: Codeunit "EA Corp Card Statement Mgt";
    begin
        Initialize();
        CreateStatement(CorpCardStatement, 'STMT-BLOCKED-CARD', 2000, 1);
        CreateTransaction(CorpCardTrans, CorpCardStatement, 'TRANS-BLOCKED-CARD', 2000, 'EXP-BLOCKED-CARD');
        CorpCard.Get(CorpCardTrans."Card Id");
        CorpCard.Blocked := true;
        CorpCard.Modify(true);

        asserterror CorpCardStatementMgt.ValidateStatement(CorpCardStatement);

        Assert.ExpectedTestFieldError(CorpCard.FieldCaption(Blocked), Format(false));
    end;

    [Test]
    procedure ValidateStatementRejectsUnbalancedTotal()
    var
        CorpCardStatement: Record "EA Corp Card Statement";
        CorpCardTrans: Record "EA Corp Card Trans";
        CorpCardStatementMgt: Codeunit "EA Corp Card Statement Mgt";
    begin
        Initialize();
        CreateStatement(CorpCardStatement, 'STMT-005', 2100, 1);
        CreateTransaction(CorpCardTrans, CorpCardStatement, 'TRANS-005', 2000, 'EXP-005');

        asserterror CorpCardStatementMgt.ValidateStatement(CorpCardStatement);

        Assert.ExpectedError('does not equal the transaction total');
    end;

    [Test]
    procedure ValidateStatementRejectsImportExceptions()
    var
        CorpCardStatement: Record "EA Corp Card Statement";
        CorpCardTrans: Record "EA Corp Card Trans";
        CorpCardStatementMgt: Codeunit "EA Corp Card Statement Mgt";
    begin
        Initialize();
        CreateStatement(CorpCardStatement, 'STMT-006', 2000, 1);
        CreateTransaction(CorpCardTrans, CorpCardStatement, 'TRANS-006', 2000, 'EXP-006');
        CorpCardStatement.Exceptions := 1;
        CorpCardStatement.Modify();

        asserterror CorpCardStatementMgt.ValidateStatement(CorpCardStatement);

        Assert.ExpectedError(CorpCardStatement.FieldCaption(Exceptions));
    end;

    local procedure Initialize()
    begin
        CorpCardTestLib.InitializeCorpCardData();
    end;

    local procedure CreateStatement(var CorpCardStatement: Record "EA Corp Card Statement"; StatementNo: Code[50]; StatementTotal: Decimal; ImportedTransactions: Integer)
    begin
        CorpCardStatement.Init();
        CorpCardStatement."Provider Code" := 'TEST';
        CorpCardStatement."Statement No." := StatementNo;
        CorpCardStatement."Statement Date" := WorkDate();
        CorpCardStatement."Period Start Date" := WorkDate() - 10;
        CorpCardStatement."Period End Date" := WorkDate();
        CorpCardStatement."Currency Code" := 'USD';
        CorpCardStatement."Statement Total" := StatementTotal;
        CorpCardStatement.Imported := ImportedTransactions;
        CorpCardStatement.Status := CorpCardStatement.Status::Imported;
        CorpCardStatement.Insert(true);
    end;

    local procedure CreateTransaction(var CorpCardTrans: Record "EA Corp Card Trans"; CorpCardStatement: Record "EA Corp Card Statement"; ProviderTransId: Code[100]; Amount: Decimal; ExpenseNo: Code[20])
    var
        CorpCard: Record "EA Corp Card";
    begin
        CorpCard.FindFirst();
        Clear(CorpCardTrans);
        CorpCardTrans.Init();
        CorpCardTrans."Statement Entry No." := CorpCardStatement."Statement Entry No.";
        CorpCardTrans."Provider Code" := CorpCardStatement."Provider Code";
        CorpCardTrans."Provider Trans Id" := ProviderTransId;
        CorpCardTrans."Card Id" := CorpCard."Card Id";
        CorpCardTrans."Trans Date" := WorkDate() - 1;
        CorpCardTrans.Amount := Amount;
        CorpCardTrans."Currency Code" := CorpCardStatement."Currency Code";
        CorpCardTrans."Expense No." := ExpenseNo;
        CorpCardTrans.Status := CorpCardTrans.Status::Matched;
        CorpCardTrans.Insert(true);
    end;
}
