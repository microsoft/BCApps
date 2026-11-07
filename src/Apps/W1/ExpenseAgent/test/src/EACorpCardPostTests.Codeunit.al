// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Ledger;
using Microsoft.Bank.Reconciliation;
using Microsoft.ExpenseAgent;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.HumanResources.Employee;

codeunit 148358 EACorpCardPostTests
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        CorpCardTestLib: Codeunit EACorpCardTestLib;
        LibraryERM: Codeunit "Library - ERM";
        LibraryExpense: Codeunit "Library - Expense";
        IsInitialized: Boolean;

    [Test]
    procedure LinkPostedExpenseMarksTransactionPostedWithoutCreatingBankingRecords()
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        CorpCard: Record "EA Corp Card";
        CorpCardStatement: Record "EA Corp Card Statement";
        CorpCardTrans: Record "EA Corp Card Trans";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        CorpCardPostMgt: Codeunit "EA Corp Card Post Mgt";
        BankAccountLedgerEntryCount: Integer;
        BankAccReconciliationCount: Integer;
        BankAccReconciliationLineCount: Integer;
    begin
        Initialize();
        CorpCard.FindFirst();
        CorpCardTestLib.CreateStatement(CorpCardStatement, CorpCard."Provider Code", 'STMT-LINK-POSTED', 2000, CorpCardStatement.Status::Validated);
        CorpCardTestLib.CreatePostedTransaction(CorpCardTrans, CorpCardStatement, 2000);
        CorpCardTrans."Card Id" := CorpCard."Card Id";
        CorpCardTrans."Posted Expense Report No." := '';
        CorpCardTrans.Status := CorpCardTrans.Status::Submitted;
        CorpCardTrans.Modify(true);

        BankAccountLedgerEntryCount := BankAccountLedgerEntry.Count();
        BankAccReconciliationCount := BankAccReconciliation.Count();
        BankAccReconciliationLineCount := BankAccReconciliationLine.Count();

        PostedExpenseReportHeader."No." := CopyStr(Format(CreateGuid()), 1, MaxStrLen(PostedExpenseReportHeader."No."));
        PostedExpenseReportLine."Credit Card Feed No." := CorpCardTrans."Entry No.";

        CorpCardPostMgt.LinkPostedExpense(PostedExpenseReportLine, PostedExpenseReportHeader);

        CorpCardTrans.Get(CorpCardTrans."Entry No.");
        Assert.AreEqual(CorpCardTrans.Status::Posted, CorpCardTrans.Status, 'Posting the expense report must mark the corporate card transaction as posted.');
        Assert.AreEqual(PostedExpenseReportHeader."No.", CorpCardTrans."Posted Expense Report No.", 'The corporate card transaction must reference the posted expense report.');
        Assert.AreEqual(BankAccountLedgerEntryCount, BankAccountLedgerEntry.Count(), 'Posting an expense report must not create a bank account ledger entry.');
        Assert.AreEqual(BankAccReconciliationCount, BankAccReconciliation.Count(), 'Posting an expense report must not create a bank account reconciliation.');
        Assert.AreEqual(BankAccReconciliationLineCount, BankAccReconciliationLine.Count(), 'Posting an expense report must not create a bank account reconciliation line.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure CreditCardExpensePostsLiabilityToProviderBankAccount()
    var
        BankAccount: Record "Bank Account";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        CorpCard: Record "EA Corp Card";
        CorpCardProvider: Record "EA Corp Card Provider";
        CorpCardTrans: Record "EA Corp Card Trans";
        Employee: Record Employee;
        ExpenseCategory: Record "Expense Category";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpensePostingGroup: Record "Expense Posting Group";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseUser: Record "Expense User";
        GLAccount: Record "G/L Account";
        ExpenseReportPost: Codeunit "Expense Report-Post";
    begin
        Initialize();
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateBankAccount(BankAccount, GLAccount);
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Credit Card", ExpenseCategory."Expense Detail Required"::" ");
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Credit Card");
        Employee.Get(ExpenseUser."Employee No.");
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");
        ExpensePostingGroup.Get(ExpenseCategory."Posting Group");
        ExpensePostingGroup.Validate("Refundable Debit Account", LibraryERM.CreateGLAccountNo());
        ExpensePostingGroup.Modify(true);

        CorpCardProvider.Get('TEST');
        CorpCardProvider.Validate("Corp Card Bank Account No.", BankAccount."No.");
        CorpCardProvider.Modify(true);

        CorpCard.Init();
        CorpCard."Card Id" := CopyStr(Format(CreateGuid()), 1, MaxStrLen(CorpCard."Card Id"));
        CorpCard."Provider Code" := CorpCardProvider.Code;
        CorpCard."Expense User No." := ExpenseUser."No.";
        CorpCard.Insert(true);

        CorpCardTrans.Init();
        CorpCardTrans."Provider Code" := CorpCardProvider.Code;
        CorpCardTrans."Card Id" := CorpCard."Card Id";
        CorpCardTrans."Provider Trans Id" := CopyStr(Format(CreateGuid()), 1, MaxStrLen(CorpCardTrans."Provider Trans Id"));
        CorpCardTrans."Trans Date" := WorkDate();
        CorpCardTrans.Amount := 2000;
        CorpCardTrans.Status := CorpCardTrans.Status::Matched;
        CorpCardTrans.Insert(true);

        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');
        LibraryExpense.CreateExpenseReportLine(
            ExpenseReportLine, ExpenseReportHeader, ExpenseUser."No.", ExpenseCategory.Code,
            ExpensePaymentMethod.Code, true, '', 2000);
        ExpenseReportLine."Credit Card Feed No." := CorpCardTrans."Entry No.";
        ExpenseReportLine."Corporate Card Id" := CorpCard."Card Id";
        ExpenseReportLine.Modify(true);
        ExpenseReportHeader.PerformManualRelease();

        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        BankAccountLedgerEntry.SetRange("EA Corp Card Trans Entry No.", CorpCardTrans."Entry No.");
        Assert.IsTrue(BankAccountLedgerEntry.FindFirst(), 'Posting a linked credit-card expense must create a bank account ledger entry.');
        Assert.AreEqual(BankAccount."No.", BankAccountLedgerEntry."Bank Account No.", 'The expense liability must be posted to the provider corporate card bank account.');
        Assert.AreEqual(-2000, BankAccountLedgerEntry.Amount, 'The corporate card bank account must be credited by the expense amount.');
        CorpCardTrans.Get(CorpCardTrans."Entry No.");
        Assert.AreEqual(CorpCardTrans.Status::Posted, CorpCardTrans.Status, 'The linked corporate card transaction must be marked as posted.');
    end;

    [Test]
    procedure CancelingPostedExpenseInvalidatesClosedStatement()
    var
        CorpCardStatement: Record "EA Corp Card Statement";
        CorpCardTrans: Record "EA Corp Card Trans";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        CorpCardPostMgt: Codeunit "EA Corp Card Post Mgt";
        OriginalClosedAt: DateTime;
    begin
        Initialize();
        OriginalClosedAt := CurrentDateTime();
        CorpCardStatement.Init();
        CorpCardStatement."Provider Code" := 'TEST';
        CorpCardStatement."Statement No." := CopyStr(Format(CreateGuid()), 1, MaxStrLen(CorpCardStatement."Statement No."));
        CorpCardStatement."Statement Date" := WorkDate();
        CorpCardStatement."Statement Total" := 2000;
        CorpCardStatement."Reconciled Transactions" := 1;
        CorpCardStatement."Reconciled Amount" := 2000;
        CorpCardStatement."Closed At" := OriginalClosedAt;
        CorpCardStatement."Closed By User ID" := CopyStr(UserId(), 1, MaxStrLen(CorpCardStatement."Closed By User ID"));
        CorpCardStatement.Status := CorpCardStatement.Status::Closed;
        CorpCardStatement.Insert(true);

        CorpCardTrans.Init();
        CorpCardTrans."Statement Entry No." := CorpCardStatement."Statement Entry No.";
        CorpCardTrans."Provider Code" := CorpCardStatement."Provider Code";
        CorpCardTrans."Card Id" := CopyStr(Format(CreateGuid()), 1, MaxStrLen(CorpCardTrans."Card Id"));
        CorpCardTrans."Provider Trans Id" := CopyStr(Format(CreateGuid()), 1, MaxStrLen(CorpCardTrans."Provider Trans Id"));
        CorpCardTrans."Trans Date" := WorkDate();
        CorpCardTrans.Amount := 2000;
        CorpCardTrans."Expense No." := CopyStr(Format(CreateGuid()), 1, MaxStrLen(CorpCardTrans."Expense No."));
        CorpCardTrans."Posted Expense Report No." := CopyStr(Format(CreateGuid()), 1, MaxStrLen(CorpCardTrans."Posted Expense Report No."));
        CorpCardTrans.Status := CorpCardTrans.Status::Posted;
        CorpCardTrans.Insert(true);

        PostedExpenseReportHeader."No." := CorpCardTrans."Posted Expense Report No.";
        PostedExpenseReportLine."Credit Card Feed No." := CorpCardTrans."Entry No.";

        CorpCardPostMgt.HandleCanceledPostedExpense(PostedExpenseReportLine, PostedExpenseReportHeader);

        CorpCardStatement.Get(CorpCardStatement."Statement Entry No.");
        CorpCardTrans.Get(CorpCardTrans."Entry No.");
        Assert.AreEqual(CorpCardStatement.Status::ReconciliationRequired, CorpCardStatement.Status, 'Canceling the posted expense must invalidate statement closure.');
        Assert.AreEqual(OriginalClosedAt, CorpCardStatement."Previous Closed At", 'The previous statement closure must be preserved.');
        Assert.IsTrue(StrPos(CorpCardStatement."Recon. Invalidation Reason", PostedExpenseReportHeader."No.") > 0, 'The cancellation reason must identify the posted expense report.');
        Assert.AreEqual(CorpCardTrans.Status::Matched, CorpCardTrans.Status, 'The corporate card transaction must return to matched status.');
        Assert.AreEqual('', CorpCardTrans."Posted Expense Report No.", 'The canceled posted report reference must be cleared.');
    end;

    [Test]
    procedure PostedReportCardQueryIncludesOnlyActiveReportLinks()
    var
        CorpCardStatement: Record "EA Corp Card Statement";
        CorpCardTrans: array[3] of Record "EA Corp Card Trans";
        CorpCardPostMgt: Codeunit "EA Corp Card Post Mgt";
        PostedReportCardTrans: Query "EA Posted Report Card Trans";
        ExpectedStatementNos: Dictionary of [Integer, Integer];
        ActualFeedNos: List of [Integer];
        TransactionIndex: Integer;
    begin
        // [SCENARIO] Discovery batches active feed links, including duplicate links and transactions without a statement.
        Initialize();

        // [GIVEN] Three transactions on two statements, with the first transaction linked twice.
        for TransactionIndex := 1 to ArrayLen(CorpCardTrans) do begin
            if TransactionIndex <= 2 then
                CorpCardTestLib.CreateStatement(
                    CorpCardStatement, 'TEST', 'STMT-LOCK-' + Format(TransactionIndex), 100, CorpCardStatement.Status::Validated);
            CorpCardTestLib.CreatePostedTransaction(CorpCardTrans[TransactionIndex], CorpCardStatement, 100);
            if TransactionIndex = 3 then begin
                CorpCardTrans[TransactionIndex]."Statement Entry No." := 0;
                CorpCardTrans[TransactionIndex].Modify();
            end;
            ExpectedStatementNos.Add(CorpCardTrans[TransactionIndex]."Entry No.", CorpCardTrans[TransactionIndex]."Statement Entry No.");
            CreatePostedReportCardLink('PER-LOCK', TransactionIndex * 10000, CorpCardTrans[TransactionIndex]."Entry No.", false);
        end;
        CreatePostedReportCardLink('PER-LOCK', 40000, CorpCardTrans[1]."Entry No.", false);

        // [GIVEN] Canceled and other-report links point to missing transactions, and a manual line has no feed link.
        CreatePostedReportCardLink('PER-LOCK', 50000, -1, true);
        CreatePostedReportCardLink('PER-OTHER', 10000, -1, false);
        CreatePostedReportCardLink('PER-LOCK', 60000, 0, false);

        // [WHEN] The active report links are read in one query.
        PostedReportCardTrans.SetRange(PostedReportNo, 'PER-LOCK');
        PostedReportCardTrans.Open();
        while PostedReportCardTrans.Read() do begin
            Assert.AreEqual(PostedReportCardTrans.CreditCardFeedNo, PostedReportCardTrans.TransactionEntryNo, 'Each feed link must resolve to its transaction.');
            Assert.IsTrue(ExpectedStatementNos.ContainsKey(PostedReportCardTrans.TransactionEntryNo), 'Only linked report transactions must be returned.');
            Assert.AreEqual(
                ExpectedStatementNos.Get(PostedReportCardTrans.TransactionEntryNo), PostedReportCardTrans.StatementEntryNo,
                'Each transaction must retain its statement for the subsequent ordered lock pass.');
            ActualFeedNos.Add(PostedReportCardTrans.CreditCardFeedNo);
        end;
        PostedReportCardTrans.Close();

        // [THEN] All four active links are present, including the duplicate.
        Assert.AreEqual(4, ActualFeedNos.Count(), 'Canceled, manual, and other-report lines must be excluded.');
        for TransactionIndex := 1 to ArrayLen(CorpCardTrans) do
            Assert.IsTrue(ActualFeedNos.Remove(CorpCardTrans[TransactionIndex]."Entry No."), 'Each linked transaction must be included.');
        Assert.AreEqual(CorpCardTrans[1]."Entry No.", ActualFeedNos.Get(1), 'The duplicate link must be preserved.');

        // [THEN] Lock preparation tolerates duplicate links and transactions without statements.
        CorpCardPostMgt.LockPostedReportTransactions('PER-LOCK');
    end;

    [Test]
    procedure LockPostedReportTransactionsRejectsMissingFeedTransaction()
    var
        CorpCardPostMgt: Codeunit "EA Corp Card Post Mgt";
    begin
        // [SCENARIO] A left join must not silently discard a broken active feed link.
        Initialize();

        // [GIVEN] An active report line refers to a missing transaction.
        CreatePostedReportCardLink('PER-MISSING', 10000, -1, false);

        // [WHEN] Cancellation prepares the report's transaction locks.
        asserterror CorpCardPostMgt.LockPostedReportTransactions('PER-MISSING');

        // [THEN] Cancellation fails explicitly instead of proceeding without the transaction.
        Assert.ExpectedError('Corporate card links changed while preparing cancellation.');
    end;

    local procedure CreatePostedReportCardLink(PostedReportNo: Code[20]; LineNo: Integer; FeedEntryNo: Integer; IsCanceled: Boolean)
    var
        PostedExpenseReportLine: Record "Posted Expense Report Line";
    begin
        PostedExpenseReportLine."Document No." := PostedReportNo;
        PostedExpenseReportLine."Line No." := LineNo;
        PostedExpenseReportLine."Credit Card Feed No." := FeedEntryNo;
        PostedExpenseReportLine."Is Canceled" := IsCanceled;
        PostedExpenseReportLine.Insert();
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        CorpCardTestLib.InitializeCorpCardData();
        CorpCardTestLib.EnsureCorpCardProvider('TEST');
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
        LibraryExpense.InitializeExpenseSourceCode();
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(false);
        if IsInitialized then
            exit;

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateVATPostingSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        IsInitialized := true;
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}
