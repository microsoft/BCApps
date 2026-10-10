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
    begin
        Clear(CorpCardTrans);
        CorpCardTrans.Init();
        CorpCardTrans."Statement Entry No." := CorpCardStatement."Statement Entry No.";
        CorpCardTrans."Provider Code" := CorpCardStatement."Provider Code";
        CorpCardTrans."Provider Trans Id" := ProviderTransId;
        CorpCardTrans."Card Id" := 'CARD-001';
        CorpCardTrans."Trans Date" := WorkDate() - 1;
        CorpCardTrans.Amount := Amount;
        CorpCardTrans."Currency Code" := CorpCardStatement."Currency Code";
        CorpCardTrans."Expense No." := ExpenseNo;
        CorpCardTrans.Status := CorpCardTrans.Status::Matched;
        CorpCardTrans.Insert(true);
    end;
}
