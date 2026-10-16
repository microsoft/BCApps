// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Ledger;
using Microsoft.Bank.Reconciliation;
using Microsoft.Bank.Statement;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.HumanResources.Employee;

codeunit 7440 "EA Corp Card Bank Rec Mgt"
{
    Access = Internal;
    Permissions = tabledata "Applied Payment Entry" = rim,
                  tabledata "Bank Acc. Reconciliation" = rim,
                  tabledata "Bank Acc. Reconciliation Line" = rim,
                  tabledata "Bank Account Ledger Entry" = rm,
                  tabledata "EA Corp Card Trans" = rm;

    var
        CurrencyMismatchErr: Label 'The reimbursement currency %1 for corporate card transaction %2 must match currency %3 on bank account %4.', Comment = '%1 = reimbursement currency, %2 = transaction entry number, %3 = bank account currency, %4 = bank account number';
        ReconciliationAlreadyExistsErr: Label 'Corporate card transaction %1 is already linked to payment reconciliation %2.', Comment = '%1 = transaction entry number, %2 = reconciliation number';

    internal procedure CreateReconciliation(var CorpCardTrans: Record "EA Corp Card Trans")
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        CorpCard: Record "EA Corp Card";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        EmployeePostingGroup: Record "Employee Posting Group";
        CardPaidAccountNo: Code[20];
    begin
        if CorpCardTrans."Bank Acc. Reconciliation No." <> '' then
            Error(ReconciliationAlreadyExistsErr, CorpCardTrans."Entry No.", CorpCardTrans."Bank Acc. Reconciliation No.");

        CorpCardTrans.TestField("Posted Expense Report No.");
        CorpCard.Get(CorpCardTrans."Card Id");
        CorpCard.TestField("Bank Account No.");
        PostedExpenseReportHeader.Get(CorpCardTrans."Posted Expense Report No.");
        ValidateBankAccountCurrency(
            CorpCardTrans, CorpCard."Bank Account No.",
            PostedExpenseReportHeader."Reimbursement Currency Code");
        EmployeePostingGroup.Get(PostedExpenseReportHeader."Employee Posting Group");
        CardPaidAccountNo := EmployeePostingGroup.GetExpensePayableCardPaidAccount();

        PostedExpenseReportLine.SetRange("Document No.", PostedExpenseReportHeader."No.");
        PostedExpenseReportLine.SetRange("Credit Card Feed No.", CorpCardTrans."Entry No.");
        PostedExpenseReportLine.FindFirst();
        PostedExpenseReportLine.TestField(
            "Reimbursement Type", PostedExpenseReportLine."Reimbursement Type"::"Credit Card");

        FindOrCreateReconciliation(
            BankAccReconciliation, CorpCard."Bank Account No.",
            PostedExpenseReportHeader."No.", GetTransactionDate(CorpCardTrans));
        CreateReconciliationLine(
            BankAccReconciliationLine, BankAccReconciliation, CorpCardTrans,
            PostedExpenseReportHeader, PostedExpenseReportLine, CardPaidAccountNo);
        UpdateReconciliationBalance(BankAccReconciliation);

        CorpCardTrans."Bank Account No." := CorpCard."Bank Account No.";
        CorpCardTrans."Bank Acc. Reconciliation No." := BankAccReconciliation."Statement No.";
        CorpCardTrans."Bank Acc. Rec. Line No." := BankAccReconciliationLine."Statement Line No.";
        CorpCardTrans.Status := CorpCardTrans.Status::ReconciliationCreated;
        CorpCardTrans.Modify(true);
    end;

    local procedure HandlePostedExpense(PostedExpenseReportLine: Record "Posted Expense Report Line"; PostedExpenseReportHeader: Record "Posted Expense Report Header")
    var
        CorpCard: Record "EA Corp Card";
        CorpCardTrans: Record "EA Corp Card Trans";
    begin
        if PostedExpenseReportLine."Credit Card Feed No." = 0 then
            exit;
        if not CorpCardTrans.Get(PostedExpenseReportLine."Credit Card Feed No.") then
            exit;

        CorpCardTrans."Posted Expense Report No." := PostedExpenseReportHeader."No.";
        CorpCardTrans.Status := CorpCardTrans.Status::ReadyForReconciliation;
        CorpCardTrans.Modify(true);

        if not CorpCard.Get(CorpCardTrans."Card Id") then
            exit;
        if CorpCard."Bank Account No." = '' then
            exit;

        CreateReconciliation(CorpCardTrans);
    end;

    local procedure FindOrCreateReconciliation(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; BankAccountNo: Code[20]; PostedExpenseReportNo: Code[20]; TransactionDate: Date)
    var
        ExistingBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        ExistingBankAccReconciliationLine.SetRange("Statement Type", ExistingBankAccReconciliationLine."Statement Type"::"Payment Application");
        ExistingBankAccReconciliationLine.SetRange("Bank Account No.", BankAccountNo);
        ExistingBankAccReconciliationLine.SetRange("EA Posted Exp. Report No.", PostedExpenseReportNo);
        if ExistingBankAccReconciliationLine.FindFirst() then begin
            BankAccReconciliation.Get(
                ExistingBankAccReconciliationLine."Statement Type",
                ExistingBankAccReconciliationLine."Bank Account No.",
                ExistingBankAccReconciliationLine."Statement No.");
            exit;
        end;

        BankAccReconciliation.CreateNewBankPaymentAppBatch(BankAccountNo, BankAccReconciliation);
        BankAccReconciliation."Statement Date" := TransactionDate;
        BankAccReconciliation.Modify(true);
    end;

    local procedure CreateReconciliationLine(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; BankAccReconciliation: Record "Bank Acc. Reconciliation"; CorpCardTrans: Record "EA Corp Card Trans"; PostedExpenseReportHeader: Record "Posted Expense Report Header"; PostedExpenseReportLine: Record "Posted Expense Report Line"; CardPaidAccountNo: Code[20])
    var
        AppliedPaymentEntry: Record "Applied Payment Entry";
        StatementAmount: Decimal;
    begin
        StatementAmount := GetStatementAmount(PostedExpenseReportHeader, PostedExpenseReportLine);

        BankAccReconciliationLine.Init();
        BankAccReconciliationLine."Statement Type" := BankAccReconciliation."Statement Type";
        BankAccReconciliationLine."Bank Account No." := BankAccReconciliation."Bank Account No.";
        BankAccReconciliationLine."Statement No." := BankAccReconciliation."Statement No.";
        BankAccReconciliationLine."Statement Line No." := GetNextLineNo(BankAccReconciliation);
        BankAccReconciliationLine."Document No." := CopyStr(PostedExpenseReportHeader."No.", 1, MaxStrLen(BankAccReconciliationLine."Document No."));
        BankAccReconciliationLine."Transaction Date" := GetTransactionDate(CorpCardTrans);
        BankAccReconciliationLine.Description := CopyStr(CorpCardTrans."Merchant Norm", 1, MaxStrLen(BankAccReconciliationLine.Description));
        BankAccReconciliationLine."Transaction Text" := CopyStr(CorpCardTrans."Merchant Raw", 1, MaxStrLen(BankAccReconciliationLine."Transaction Text"));
        BankAccReconciliationLine."Related-Party Name" := CorpCardTrans."Merchant Norm";
        BankAccReconciliationLine."Transaction ID" := CopyStr(CorpCardTrans."Provider Trans Id", 1, MaxStrLen(BankAccReconciliationLine."Transaction ID"));
        BankAccReconciliationLine."Dimension Set ID" := PostedExpenseReportLine."Dimension Set ID";
        BankAccReconciliationLine.Validate("Account Type", BankAccReconciliationLine."Account Type"::"G/L Account");
        BankAccReconciliationLine.Validate("Account No.", CardPaidAccountNo);
        BankAccReconciliationLine.Validate("Statement Amount", StatementAmount);
        BankAccReconciliationLine."EA Corp Card Trans Entry No." := CorpCardTrans."Entry No.";
        BankAccReconciliationLine."EA Posted Exp. Report No." := PostedExpenseReportHeader."No.";
        BankAccReconciliationLine.Insert(true);

        AppliedPaymentEntry.Init();
        AppliedPaymentEntry.TransferFromBankAccReconLine(BankAccReconciliationLine);
        AppliedPaymentEntry.Validate("Account Type", AppliedPaymentEntry."Account Type"::"G/L Account");
        AppliedPaymentEntry.Validate("Account No.", CardPaidAccountNo);
        AppliedPaymentEntry.Validate("Applied Amount", BankAccReconciliationLine."Statement Amount");
        AppliedPaymentEntry.Validate("Match Confidence", AppliedPaymentEntry."Match Confidence"::Manual);
        AppliedPaymentEntry.Description := BankAccReconciliationLine.Description;
        AppliedPaymentEntry.Insert(true);
        BankAccReconciliationLine.Find();
    end;

    local procedure GetNextLineNo(BankAccReconciliation: Record "Bank Acc. Reconciliation"): Integer
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        BankAccReconciliationLine.SetRange("Statement Type", BankAccReconciliation."Statement Type");
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccReconciliationLine.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        if BankAccReconciliationLine.FindLast() then
            exit(BankAccReconciliationLine."Statement Line No." + 10000);
        exit(10000);
    end;

    local procedure UpdateReconciliationBalance(var BankAccReconciliation: Record "Bank Acc. Reconciliation")
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        BankAccReconciliationLine.SetRange("Statement Type", BankAccReconciliation."Statement Type");
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccReconciliationLine.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        BankAccReconciliationLine.CalcSums("Statement Amount");
        BankAccReconciliation."Statement Ending Balance" :=
            BankAccReconciliation."Balance Last Statement" + BankAccReconciliationLine."Statement Amount";
        BankAccReconciliation.Modify(true);
    end;

    local procedure GetStatementAmount(PostedExpenseReportHeader: Record "Posted Expense Report Header"; PostedExpenseReportLine: Record "Posted Expense Report Line"): Decimal
    var
        ExpenseCurrency: Record Currency;
        ReimbursementCurrency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        Amount: Decimal;
        AmountLCY: Decimal;
        ConversionDate: Date;
    begin
        ExpenseCurrency.Initialize(PostedExpenseReportLine."Expense Currency Code");
        ReimbursementCurrency.Initialize(PostedExpenseReportHeader."Reimbursement Currency Code");
        ConversionDate := GetReimbursementConversionDate(PostedExpenseReportHeader, PostedExpenseReportLine);
        Amount := -(PostedExpenseReportLine.Amount - PostedExpenseReportLine."Non-Refundable Amount");
        AmountLCY :=
            Round(
                CurrencyExchangeRate.ExchangeAmtFCYToLCY(
                    ConversionDate, ExpenseCurrency.Code, Amount,
                    CurrencyExchangeRate.ExchangeRate(ConversionDate, ExpenseCurrency.Code)),
                ExpenseCurrency."Amount Rounding Precision");

        if ExpenseCurrency.Code <> ReimbursementCurrency.Code then
            Amount :=
                Round(
                    CurrencyExchangeRate.ExchangeAmtLCYToFCY(
                        ConversionDate, ReimbursementCurrency.Code, AmountLCY,
                        CurrencyExchangeRate.ExchangeRate(ConversionDate, ReimbursementCurrency.Code)),
                    ReimbursementCurrency."Amount Rounding Precision");

        exit(Amount);
    end;

    local procedure GetReimbursementConversionDate(PostedExpenseReportHeader: Record "Posted Expense Report Header"; PostedExpenseReportLine: Record "Posted Expense Report Line"): Date
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        ExpenseAgentSetup.GetRecordOnce();
        if (ExpenseAgentSetup."Exchange Rate for Expenses" = Enum::"Expense Exchange Rate"::"Expense Date") and
           (PostedExpenseReportHeader."Reimbursement Currency Code" = '') and
           (PostedExpenseReportLine."Expense Date" <> 0D)
        then
            exit(PostedExpenseReportLine."Expense Date");

        if PostedExpenseReportHeader."Posting Date" <> 0D then
            exit(PostedExpenseReportHeader."Posting Date");
        exit(WorkDate());
    end;

    local procedure ValidateBankAccountCurrency(CorpCardTrans: Record "EA Corp Card Trans"; BankAccountNo: Code[20]; ReimbursementCurrencyCode: Code[10])
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.Get(BankAccountNo);
        BankAccount.TestField(Blocked, false);
        if BankAccount."Currency Code" <> ReimbursementCurrencyCode then
            Error(
                CurrencyMismatchErr, ReimbursementCurrencyCode, CorpCardTrans."Entry No.",
                BankAccount."Currency Code", BankAccount."No.");
    end;

    local procedure GetTransactionDate(CorpCardTrans: Record "EA Corp Card Trans"): Date
    begin
        if CorpCardTrans."Posting Date" <> 0D then
            exit(CorpCardTrans."Posting Date");
        exit(CorpCardTrans."Trans Date");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Expense Report-Post", 'OnAfterProcessExpenseReportLine', '', false, false)]
    local procedure OnAfterProcessExpenseReportLine(ExpenseReportHeader: Record "Expense Report Header"; ExpenseReportLine: Record "Expense Report Line"; PostedExpenseReportLine: Record "Posted Expense Report Line"; PostedExpenseReportHeader: Record "Posted Expense Report Header")
    begin
        HandlePostedExpense(PostedExpenseReportLine, PostedExpenseReportHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Bank Acc. Reconciliation Post", 'OnPostPaymentApplicationsOnAfterInitGenJnlLine', '', false, false)]
    local procedure OnPostPaymentApplicationsOnAfterInitGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var IsApplied: Boolean; var AppliedAmount: Decimal; var PaymentLineAmount: Decimal; var IsHandled: Boolean)
    begin
        GenJournalLine."EA Corp Card Trans Entry No." := BankAccReconciliationLine."EA Corp Card Trans Entry No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Bank Acc. Reconciliation Post", 'OnPostPaymentApplicationsOnAfterPostGenJnlLine', '', false, false)]
    local procedure OnPostPaymentApplicationsOnAfterPostGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        CorpCardTrans: Record "EA Corp Card Trans";
    begin
        if GenJournalLine."EA Corp Card Trans Entry No." = 0 then
            exit;

        BankAccountLedgerEntry.SetRange(Open, true);
        BankAccountLedgerEntry.SetRange("Bank Account No.", GenJournalLine."Bal. Account No.");
        BankAccountLedgerEntry.SetRange("Document Type", GenJournalLine."Document Type");
        BankAccountLedgerEntry.SetRange("Document No.", GenJournalLine."Document No.");
        BankAccountLedgerEntry.SetRange("Posting Date", GenJournalLine."Posting Date");
        if not BankAccountLedgerEntry.FindLast() then
            exit;

        BankAccountLedgerEntry."EA Corp Card Trans Entry No." := GenJournalLine."EA Corp Card Trans Entry No.";
        BankAccountLedgerEntry.Modify();

        if CorpCardTrans.Get(GenJournalLine."EA Corp Card Trans Entry No.") then begin
            CorpCardTrans."Bank Acc. Ledger Entry No." := BankAccountLedgerEntry."Entry No.";
            CorpCardTrans.Status := CorpCardTrans.Status::BankEntryCreated;
            CorpCardTrans.Modify(true);
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Bank Acc. Reconciliation Line", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterBankAccReconciliationLineDelete(var Rec: Record "Bank Acc. Reconciliation Line"; RunTrigger: Boolean)
    var
        CorpCardTrans: Record "EA Corp Card Trans";
    begin
        if Rec."EA Corp Card Trans Entry No." = 0 then
            exit;
        if not CorpCardTrans.Get(Rec."EA Corp Card Trans Entry No.") then
            exit;
        if (CorpCardTrans."Bank Acc. Reconciliation No." <> Rec."Statement No.") or
           (CorpCardTrans."Bank Acc. Rec. Line No." <> Rec."Statement Line No.")
        then
            exit;

        CorpCardTrans."Bank Acc. Reconciliation No." := '';
        CorpCardTrans."Bank Acc. Rec. Line No." := 0;
        if CorpCardTrans.Status = CorpCardTrans.Status::ReconciliationCreated then
            CorpCardTrans.Status := CorpCardTrans.Status::ReadyForReconciliation;
        CorpCardTrans.Modify(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Bank Acc. Reconciliation Post", 'OnTransferToBankStmtOnBeforeBankAccStmtLineInsert', '', false, false)]
    local procedure OnTransferToBankStmtOnBeforeBankAccStmtLineInsert(var BankAccStmtLine: Record "Bank Account Statement Line"; BankAccReconLine: Record "Bank Acc. Reconciliation Line")
    var
        CorpCardTrans: Record "EA Corp Card Trans";
    begin
        BankAccStmtLine."EA Corp Card Trans Entry No." := BankAccReconLine."EA Corp Card Trans Entry No.";
        BankAccStmtLine."EA Posted Exp. Report No." := BankAccReconLine."EA Posted Exp. Report No.";

        if BankAccReconLine."EA Corp Card Trans Entry No." = 0 then
            exit;
        if CorpCardTrans.Get(BankAccReconLine."EA Corp Card Trans Entry No.") then begin
            CorpCardTrans."Bank Account Statement No." := BankAccStmtLine."Statement No.";
            CorpCardTrans."Bank Acc. Reconciliation No." := '';
            CorpCardTrans."Bank Acc. Rec. Line No." := 0;
            CorpCardTrans.Status := CorpCardTrans.Status::Reconciled;
            CorpCardTrans.Modify(true);
        end;
    end;
}
