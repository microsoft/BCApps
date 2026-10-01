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
        CorpCardTrans: Record "EA Corp Card Trans";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        CorpCardPostMgt: Codeunit "EA Corp Card Post Mgt";
        BankAccountLedgerEntryCount: Integer;
        BankAccReconciliationCount: Integer;
        BankAccReconciliationLineCount: Integer;
    begin
        BankAccountLedgerEntryCount := BankAccountLedgerEntry.Count();
        BankAccReconciliationCount := BankAccReconciliation.Count();
        BankAccReconciliationLineCount := BankAccReconciliationLine.Count();

        CorpCardTrans.Init();
        CorpCardTrans."Card Id" := CopyStr(Format(CreateGuid()), 1, MaxStrLen(CorpCardTrans."Card Id"));
        CorpCardTrans."Provider Trans Id" := CopyStr(Format(CreateGuid()), 1, MaxStrLen(CorpCardTrans."Provider Trans Id"));
        CorpCardTrans."Trans Date" := WorkDate();
        CorpCardTrans.Amount := 2000;
        CorpCardTrans.Status := CorpCardTrans.Status::Submitted;
        CorpCardTrans.Insert(true);

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

        CorpCardTrans.Init();
        CorpCardTrans."Provider Code" := CorpCardProvider.Code;
        CorpCardTrans."Card Id" := CopyStr(Format(CreateGuid()), 1, MaxStrLen(CorpCardTrans."Card Id"));
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
        CorpCardStatement."Statement No." := 'STMT-CANCEL';
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
        CorpCardTrans."Expense No." := 'EXP-CANCEL';
        CorpCardTrans."Posted Expense Report No." := 'PER-CANCEL';
        CorpCardTrans.Status := CorpCardTrans.Status::Posted;
        CorpCardTrans.Insert(true);

        PostedExpenseReportHeader."No." := CorpCardTrans."Posted Expense Report No.";
        PostedExpenseReportLine."Credit Card Feed No." := CorpCardTrans."Entry No.";

        CorpCardPostMgt.HandleCanceledPostedExpense(PostedExpenseReportLine, PostedExpenseReportHeader);

        CorpCardStatement.Get(CorpCardStatement."Statement Entry No.");
        CorpCardTrans.Get(CorpCardTrans."Entry No.");
        Assert.AreEqual(CorpCardStatement.Status::ReconciliationRequired, CorpCardStatement.Status, 'Canceling the posted expense must invalidate statement closure.');
        Assert.AreEqual(OriginalClosedAt, CorpCardStatement."Previous Closed At", 'The previous statement closure must be preserved.');
        Assert.IsTrue(StrPos(CorpCardStatement."Recon. Invalidation Reason", 'PER-CANCEL') > 0, 'The cancellation reason must identify the posted expense report.');
        Assert.AreEqual(CorpCardTrans.Status::Matched, CorpCardTrans.Status, 'The corporate card transaction must return to matched status.');
        Assert.AreEqual('', CorpCardTrans."Posted Expense Report No.", 'The canceled posted report reference must be cleared.');
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
