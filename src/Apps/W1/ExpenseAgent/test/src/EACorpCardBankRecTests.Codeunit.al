// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Reconciliation;
using Microsoft.ExpenseAgent;
using Microsoft.HumanResources.Employee;

codeunit 148358 EACorpCardBankRecTests
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryExpense: Codeunit "Library - Expense";

    [Test]
    procedure CreateReconciliationCreatesAppliedNegativeStatementLine()
    var
        AppliedPaymentEntry: Record "Applied Payment Entry";
        BankAccount: Record "Bank Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        CorpCardTrans: Record "EA Corp Card Trans";
        CardPaidAccountNo: Code[20];
        PostedExpenseReportNo: Code[20];
    begin
        Initialize();
        CreateReconciliationScenario(BankAccount, CorpCardTrans, PostedExpenseReportNo, CardPaidAccountNo, 123.45);

        CreatePaymentReconciliation(CorpCardTrans);

        CorpCardTrans.Get(CorpCardTrans."Entry No.");
        BankAccReconciliation.Get(
            BankAccReconciliation."Statement Type"::"Payment Application",
            BankAccount."No.", CorpCardTrans."Bank Acc. Reconciliation No.");
        BankAccReconciliationLine.Get(
            BankAccReconciliation."Statement Type", BankAccount."No.",
            BankAccReconciliation."Statement No.", CorpCardTrans."Bank Acc. Rec. Line No.");

        Assert.AreEqual(
            CorpCardTrans.Status::ReconciliationCreated, CorpCardTrans.Status,
            'The corporate card transaction must be marked as linked to a reconciliation.');
        Assert.AreEqual(
            -CorpCardTrans.Amount, BankAccReconciliationLine."Statement Amount",
            'A card purchase must be represented as a negative bank statement amount.');
        Assert.AreEqual(
            CardPaidAccountNo, BankAccReconciliationLine."Account No.",
            'The reconciliation line must clear the card-paid G/L account.');
        Assert.AreEqual(
            CorpCardTrans."Entry No.", BankAccReconciliationLine."EA Corp Card Trans Entry No.",
            'The reconciliation line must retain the source corporate card transaction.');
        Assert.AreEqual(
            PostedExpenseReportNo, BankAccReconciliationLine."EA Posted Exp. Report No.",
            'The reconciliation line must retain the posted expense report.');

        AppliedPaymentEntry.FilterAppliedPmtEntry(BankAccReconciliationLine);
        Assert.IsTrue(AppliedPaymentEntry.FindFirst(), 'The reconciliation line must be applied to the card-paid G/L account.');
        Assert.AreEqual(
            BankAccReconciliationLine."Statement Amount", AppliedPaymentEntry."Applied Amount",
            'The G/L application must fully apply the statement amount.');
        Assert.AreEqual(
            BankAccReconciliation."Balance Last Statement" + BankAccReconciliationLine."Statement Amount",
            BankAccReconciliation."Statement Ending Balance",
            'The statement ending balance must include the corporate card transaction.');
    end;

    [Test]
    procedure TransactionsForSameReportAndBankShareReconciliation()
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        FirstCorpCardTrans: Record "EA Corp Card Trans";
        SecondCorpCardTrans: Record "EA Corp Card Trans";
        CardPaidAccountNo: Code[20];
        PostedExpenseReportNo: Code[20];
    begin
        Initialize();
        CreateReconciliationScenario(BankAccount, FirstCorpCardTrans, PostedExpenseReportNo, CardPaidAccountNo, 40);
        CreateSecondTransactionForScenario(FirstCorpCardTrans, PostedExpenseReportNo, SecondCorpCardTrans, 60);

        CreatePaymentReconciliation(FirstCorpCardTrans);
        CreatePaymentReconciliation(SecondCorpCardTrans);

        FirstCorpCardTrans.Get(FirstCorpCardTrans."Entry No.");
        SecondCorpCardTrans.Get(SecondCorpCardTrans."Entry No.");
        Assert.AreEqual(
            FirstCorpCardTrans."Bank Acc. Reconciliation No.", SecondCorpCardTrans."Bank Acc. Reconciliation No.",
            'Transactions for the same posted report and bank account must share one reconciliation.');

        BankAccReconciliationLine.SetRange("Statement Type", BankAccReconciliationLine."Statement Type"::"Payment Application");
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccount."No.");
        BankAccReconciliationLine.SetRange("Statement No.", FirstCorpCardTrans."Bank Acc. Reconciliation No.");
        Assert.RecordCount(BankAccReconciliationLine, 2);
    end;

    [Test]
    procedure DeletingReconciliationLineClearsTransactionReference()
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        CorpCardTrans: Record "EA Corp Card Trans";
        CardPaidAccountNo: Code[20];
        PostedExpenseReportNo: Code[20];
    begin
        Initialize();
        CreateReconciliationScenario(BankAccount, CorpCardTrans, PostedExpenseReportNo, CardPaidAccountNo, 75);
        CreatePaymentReconciliation(CorpCardTrans);

        CorpCardTrans.Get(CorpCardTrans."Entry No.");
        BankAccReconciliationLine.Get(
            BankAccReconciliationLine."Statement Type"::"Payment Application",
            BankAccount."No.", CorpCardTrans."Bank Acc. Reconciliation No.",
            CorpCardTrans."Bank Acc. Rec. Line No.");
        BankAccReconciliationLine.Delete(true);

        CorpCardTrans.Get(CorpCardTrans."Entry No.");
        Assert.AreEqual(
            '', CorpCardTrans."Bank Acc. Reconciliation No.",
            'Deleting the reconciliation line must clear the reconciliation number.');
        Assert.AreEqual(
            0, CorpCardTrans."Bank Acc. Rec. Line No.",
            'Deleting the reconciliation line must clear the reconciliation line number.');
        Assert.AreEqual(
            CorpCardTrans.Status::ReadyForReconciliation, CorpCardTrans.Status,
            'A transaction whose reconciliation line was deleted must be ready for reconciliation again.');
    end;

    [Test]
    procedure ReconciliationUsesAmountAfterNonRefundableReduction()
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        CorpCardTrans: Record "EA Corp Card Trans";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        CardPaidAccountNo: Code[20];
        PostedExpenseReportNo: Code[20];
    begin
        Initialize();
        CreateReconciliationScenario(BankAccount, CorpCardTrans, PostedExpenseReportNo, CardPaidAccountNo, 100);
        PostedExpenseReportLine.SetRange("Document No.", PostedExpenseReportNo);
        PostedExpenseReportLine.SetRange("Credit Card Feed No.", CorpCardTrans."Entry No.");
        PostedExpenseReportLine.FindFirst();
        PostedExpenseReportLine."Non-Refundable Amount" := 25;
        PostedExpenseReportLine.Modify(true);

        CreatePaymentReconciliation(CorpCardTrans);

        CorpCardTrans.Get(CorpCardTrans."Entry No.");
        BankAccReconciliationLine.Get(
            BankAccReconciliationLine."Statement Type"::"Payment Application",
            BankAccount."No.", CorpCardTrans."Bank Acc. Reconciliation No.",
            CorpCardTrans."Bank Acc. Rec. Line No.");
        Assert.AreEqual(
            -75, BankAccReconciliationLine."Statement Amount",
            'The reconciliation must clear only the refundable card-paid amount.');
    end;

    [Test]
    procedure ReconciliationRejectsNonCreditCardExpense()
    var
        BankAccount: Record "Bank Account";
        CorpCardTrans: Record "EA Corp Card Trans";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        CardPaidAccountNo: Code[20];
        PostedExpenseReportNo: Code[20];
    begin
        Initialize();
        CreateReconciliationScenario(BankAccount, CorpCardTrans, PostedExpenseReportNo, CardPaidAccountNo, 100);
        PostedExpenseReportLine.SetRange("Document No.", PostedExpenseReportNo);
        PostedExpenseReportLine.SetRange("Credit Card Feed No.", CorpCardTrans."Entry No.");
        PostedExpenseReportLine.FindFirst();
        PostedExpenseReportLine."Reimbursement Type" := PostedExpenseReportLine."Reimbursement Type"::"Employee Paid";
        PostedExpenseReportLine.Modify(true);
        Commit();

        asserterror CreatePaymentReconciliation(CorpCardTrans);

        Assert.ExpectedError('Reimbursement Type must be equal to');
        CorpCardTrans.Get(CorpCardTrans."Entry No.");
        Assert.AreEqual(
            '', CorpCardTrans."Bank Acc. Reconciliation No.",
            'A non-credit-card expense must not create a reconciliation reference.');
    end;

    [Test]
    procedure ReconciliationConvertsExpenseToReimbursementCurrency()
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        CorpCardTrans: Record "EA Corp Card Trans";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        CardPaidAccountNo: Code[20];
        ExpenseCurrencyCode: Code[10];
        PostedExpenseReportNo: Code[20];
        ReimbursementCurrencyCode: Code[10];
    begin
        Initialize();
        CreateReconciliationScenario(BankAccount, CorpCardTrans, PostedExpenseReportNo, CardPaidAccountNo, 100);
        ExpenseCurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 2, 2);
        ReimbursementCurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1, 1);
        BankAccount.Validate("Currency Code", ReimbursementCurrencyCode);
        BankAccount.Modify(true);
        PostedExpenseReportHeader.Get(PostedExpenseReportNo);
        PostedExpenseReportHeader."Posting Date" := WorkDate();
        PostedExpenseReportHeader."Reimbursement Currency Code" := ReimbursementCurrencyCode;
        PostedExpenseReportHeader.Modify(true);
        PostedExpenseReportLine.SetRange("Document No.", PostedExpenseReportNo);
        PostedExpenseReportLine.SetRange("Credit Card Feed No.", CorpCardTrans."Entry No.");
        PostedExpenseReportLine.FindFirst();
        PostedExpenseReportLine."Expense Date" := WorkDate();
        PostedExpenseReportLine."Expense Currency Code" := ExpenseCurrencyCode;
        PostedExpenseReportLine.Modify(true);

        CreatePaymentReconciliation(CorpCardTrans);

        CorpCardTrans.Get(CorpCardTrans."Entry No.");
        BankAccReconciliationLine.Get(
            BankAccReconciliationLine."Statement Type"::"Payment Application",
            BankAccount."No.", CorpCardTrans."Bank Acc. Reconciliation No.",
            CorpCardTrans."Bank Acc. Rec. Line No.");
        Assert.AreEqual(
            -50, BankAccReconciliationLine."Statement Amount",
            'The statement amount must use the posted report reimbursement currency.');
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryExpense.CleanUpBeforeTesting();
        LibraryExpense.CleanTransactionalData();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
    end;

    local procedure CreateReconciliationScenario(var BankAccount: Record "Bank Account"; var CorpCardTrans: Record "EA Corp Card Trans"; var PostedExpenseReportNo: Code[20]; var CardPaidAccountNo: Code[20]; Amount: Decimal)
    var
        CorpCard: Record "EA Corp Card";
        Employee: Record Employee;
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpenseUser: Record "Expense User";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        Employee.Get(ExpenseUser."Employee No.");
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");
        EmployeePostingGroup.Get(Employee."Employee Posting Group");
        CardPaidAccountNo := EmployeePostingGroup.GetExpensePayableCardPaidAccount();

        CorpCard.Init();
        CorpCard."Card Id" := CopyStr(Format(CreateGuid()), 1, MaxStrLen(CorpCard."Card Id"));
        CorpCard."Expense User No." := ExpenseUser."No.";
        CorpCard."Bank Account No." := BankAccount."No.";
        CorpCard.Insert(true);

        CorpCardTrans.Init();
        CorpCardTrans."Card Id" := CorpCard."Card Id";
        CorpCardTrans."Provider Trans Id" := CopyStr(Format(CreateGuid()), 1, MaxStrLen(CorpCardTrans."Provider Trans Id"));
        CorpCardTrans."Trans Date" := WorkDate();
        CorpCardTrans."Posting Date" := WorkDate();
        CorpCardTrans.Amount := Amount;
        CorpCardTrans."Merchant Raw" := 'Corporate card merchant';
        CorpCardTrans."Merchant Norm" := 'Corporate card merchant';
        CorpCardTrans.Status := CorpCardTrans.Status::ReadyForReconciliation;
        CorpCardTrans.Insert(true);

        PostedExpenseReportNo := CopyStr(Format(CreateGuid()), 1, MaxStrLen(PostedExpenseReportHeader."No."));
        PostedExpenseReportHeader.Init();
        PostedExpenseReportHeader."No." := PostedExpenseReportNo;
        PostedExpenseReportHeader."Expense User No." := ExpenseUser."No.";
        PostedExpenseReportHeader."Employee Posting Group" := Employee."Employee Posting Group";
        PostedExpenseReportHeader.Insert(true);

        InsertPostedExpenseReportLine(
            PostedExpenseReportLine, PostedExpenseReportNo, 10000,
            CorpCardTrans."Entry No.", Amount);

        CorpCardTrans."Posted Expense Report No." := PostedExpenseReportNo;
        CorpCardTrans.Modify(true);
    end;

    local procedure CreateSecondTransactionForScenario(FirstCorpCardTrans: Record "EA Corp Card Trans"; PostedExpenseReportNo: Code[20]; var SecondCorpCardTrans: Record "EA Corp Card Trans"; Amount: Decimal)
    var
        PostedExpenseReportLine: Record "Posted Expense Report Line";
    begin
        SecondCorpCardTrans.Init();
        SecondCorpCardTrans."Card Id" := FirstCorpCardTrans."Card Id";
        SecondCorpCardTrans."Provider Trans Id" := CopyStr(Format(CreateGuid()), 1, MaxStrLen(SecondCorpCardTrans."Provider Trans Id"));
        SecondCorpCardTrans."Trans Date" := WorkDate();
        SecondCorpCardTrans."Posting Date" := WorkDate();
        SecondCorpCardTrans.Amount := Amount;
        SecondCorpCardTrans."Merchant Raw" := 'Second corporate card merchant';
        SecondCorpCardTrans."Merchant Norm" := 'Second corporate card merchant';
        SecondCorpCardTrans.Status := SecondCorpCardTrans.Status::ReadyForReconciliation;
        SecondCorpCardTrans."Posted Expense Report No." := PostedExpenseReportNo;
        SecondCorpCardTrans.Insert(true);

        InsertPostedExpenseReportLine(
            PostedExpenseReportLine, PostedExpenseReportNo, 20000,
            SecondCorpCardTrans."Entry No.", Amount);
    end;

    local procedure InsertPostedExpenseReportLine(var PostedExpenseReportLine: Record "Posted Expense Report Line"; PostedExpenseReportNo: Code[20]; LineNo: Integer; CorpCardTransEntryNo: Integer; Amount: Decimal)
    begin
        PostedExpenseReportLine.Init();
        PostedExpenseReportLine."Document No." := PostedExpenseReportNo;
        PostedExpenseReportLine."Line No." := LineNo;
        PostedExpenseReportLine."Credit Card Feed No." := CorpCardTransEntryNo;
        PostedExpenseReportLine."Reimbursement Type" := PostedExpenseReportLine."Reimbursement Type"::"Credit Card";
        PostedExpenseReportLine.Amount := Amount;
        PostedExpenseReportLine.Insert(true);
    end;

    local procedure CreatePaymentReconciliation(var CorpCardTrans: Record "EA Corp Card Trans")
    var
        CorpCardBankRecMgt: Codeunit "EA Corp Card Bank Rec Mgt";
    begin
        CorpCardBankRecMgt.CreateReconciliation(CorpCardTrans);
    end;
}
