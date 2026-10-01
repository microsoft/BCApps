// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Bank.Ledger;

codeunit 7441 "EA Corp Card Statement Mgt"
{
    Access = Internal;
    Permissions =
        tabledata "Bank Account Ledger Entry" = r,
        tabledata "EA Corp Card Settlement" = r,
        tabledata "EA Corp Card Settlement Line" = r,
        tabledata "EA Corp Card Statement" = rimd,
        tabledata "EA Corp Card Trans" = r;

    internal procedure ValidateStatement(var CorpCardStatement: Record "EA Corp Card Statement")
    var
        DuplicateStatement: Record "EA Corp Card Statement";
        CorpCardTrans: Record "EA Corp Card Trans";
        TransactionTotal: Decimal;
    begin
        if CorpCardStatement.Status <> CorpCardStatement.Status::Imported then
            Error(StatementMustBeImportedErr, CorpCardStatement."Statement Entry No.", CorpCardStatement.Status);

        CorpCardStatement.TestField("Provider Code");
        CorpCardStatement.TestField("Statement No.");
        CorpCardStatement.TestField("Statement Date");
        CorpCardStatement.TestField("Period Start Date");
        CorpCardStatement.TestField("Period End Date");
        CorpCardStatement.TestField(Rejected, 0);
        CorpCardStatement.TestField(Duplicates, 0);
        CorpCardStatement.TestField(Exceptions, 0);
        CorpCardStatement.CalcFields("Imported Transactions");
        if CorpCardStatement.Imported <> CorpCardStatement."Imported Transactions" then
            Error(ImportedCountMismatchErr, CorpCardStatement.Imported, CorpCardStatement."Imported Transactions");
        if CorpCardStatement."Period Start Date" > CorpCardStatement."Period End Date" then
            Error(InvalidStatementPeriodErr, CorpCardStatement."Period Start Date", CorpCardStatement."Period End Date");

        DuplicateStatement.SetRange("Provider Code", CorpCardStatement."Provider Code");
        DuplicateStatement.SetRange("Statement No.", CorpCardStatement."Statement No.");
        DuplicateStatement.SetFilter("Statement Entry No.", '<>%1', CorpCardStatement."Statement Entry No.");
        if not DuplicateStatement.IsEmpty() then
            Error(DuplicateStatementErr, CorpCardStatement."Statement No.", CorpCardStatement."Provider Code");

        CorpCardTrans.SetRange("Statement Entry No.", CorpCardStatement."Statement Entry No.");
        CorpCardTrans.SetRange("Provider Code", CorpCardStatement."Provider Code");
        if not CorpCardTrans.FindSet() then
            Error(NoStatementTransactionsErr, CorpCardStatement."Statement No.");

        repeat
            ValidateTransaction(CorpCardStatement, CorpCardTrans);
            TransactionTotal += CorpCardTrans.Amount;
        until CorpCardTrans.Next() = 0;

        if TransactionTotal <> CorpCardStatement."Statement Total" then
            Error(StatementTotalMismatchErr, CorpCardStatement."Statement Total", TransactionTotal);

        CorpCardStatement.Status := CorpCardStatement.Status::Validated;
        CorpCardStatement.Modify(true);
    end;

    internal procedure ReopenStatement(var CorpCardStatement: Record "EA Corp Card Statement")
    begin
        if CorpCardStatement.Status = CorpCardStatement.Status::Imported then
            exit;
        if CorpCardStatement.Status <> CorpCardStatement.Status::Validated then
            Error(OnlyValidatedCanReopenErr, CorpCardStatement."Statement Entry No.");
        CorpCardStatement.CalcFields("Settlement Entry No.");
        if CorpCardStatement."Settlement Entry No." <> 0 then
            Error(SettledStatementCannotReopenErr, CorpCardStatement."Statement No.", CorpCardStatement."Settlement Entry No.");

        CorpCardStatement.Status := CorpCardStatement.Status::Imported;
        CorpCardStatement.Modify(true);
    end;

    internal procedure CloseStatement(var CorpCardStatement: Record "EA Corp Card Statement")
    var
        CorpCardSettlement: Record "EA Corp Card Settlement";
        CorpCardSettlementLine: Record "EA Corp Card Settlement Line";
        CorpCardTrans: Record "EA Corp Card Trans";
        CorpCardSettlementMgt: Codeunit "EA Corp Card Settlement Mgt";
        ReconciledAmount: Decimal;
        ReconciledTransactions: Integer;
    begin
        CorpCardStatement.LockTable();
        CorpCardStatement.Get(CorpCardStatement."Statement Entry No.");
        if not (CorpCardStatement.Status in [CorpCardStatement.Status::Validated, CorpCardStatement.Status::ReconciliationRequired]) then
            Error(StatementMustBeValidatedForClosureErr, CorpCardStatement."Statement Entry No.", CorpCardStatement.Status);

        CorpCardStatement.CalcFields("Settlement Entry No.");
        if CorpCardStatement."Settlement Entry No." = 0 then
            Error(StatementHasNoSettlementErr, CorpCardStatement."Statement No.");
        CorpCardSettlement.Get(CorpCardStatement."Settlement Entry No.");
        CorpCardSettlementMgt.ValidatePostedSettlement(CorpCardSettlement);

        CorpCardSettlementLine.SetRange("Settlement Entry No.", CorpCardSettlement."Settlement Entry No.");
        CorpCardSettlementLine.SetRange("Statement Entry No.", CorpCardStatement."Statement Entry No.");
        CorpCardSettlementLine.SetRange(Inactive, false);
        if not CorpCardSettlementLine.FindFirst() then
            Error(StatementSettlementLineNotFoundErr, CorpCardStatement."Statement No.", CorpCardSettlement."Settlement Entry No.");
        if CorpCardSettlementLine."Statement Amount" <> CorpCardStatement."Statement Total" then
            Error(StatementSettlementAmountMismatchErr, CorpCardStatement."Statement No.", CorpCardSettlementLine."Statement Amount", CorpCardStatement."Statement Total");

        CorpCardTrans.SetRange("Statement Entry No.", CorpCardStatement."Statement Entry No.");
        CorpCardTrans.SetRange("Provider Code", CorpCardStatement."Provider Code");
        if not CorpCardTrans.FindSet() then
            Error(NoStatementTransactionsErr, CorpCardStatement."Statement No.");

        repeat
            ValidateReconciledTransaction(CorpCardTrans, CorpCardStatement, CorpCardSettlement);
            ReconciledTransactions += 1;
            ReconciledAmount += CorpCardTrans.Amount;
        until CorpCardTrans.Next() = 0;

        if ReconciledAmount <> CorpCardStatement."Statement Total" then
            Error(ReconciledAmountMismatchErr, ReconciledAmount, CorpCardStatement."Statement Total");

        CorpCardStatement."Reconciled Transactions" := ReconciledTransactions;
        CorpCardStatement."Reconciled Amount" := ReconciledAmount;
        CorpCardStatement."Closed At" := CurrentDateTime();
        CorpCardStatement."Closed By User ID" := CopyStr(UserId(), 1, MaxStrLen(CorpCardStatement."Closed By User ID"));
        CorpCardStatement.Status := CorpCardStatement.Status::Closed;
        CorpCardStatement.Modify(false);
    end;

    internal procedure InvalidateReconciliation(var CorpCardStatement: Record "EA Corp Card Statement"; InvalidationReason: Text[250])
    begin
        if not (CorpCardStatement.Status in [
            CorpCardStatement.Status::Validated,
            CorpCardStatement.Status::Closed,
            CorpCardStatement.Status::ReconciliationRequired])
        then
            exit;

        if CorpCardStatement.Status = CorpCardStatement.Status::Closed then begin
            CorpCardStatement."Prev. Reconciled Transactions" := CorpCardStatement."Reconciled Transactions";
            CorpCardStatement."Prev. Reconciled Amount" := CorpCardStatement."Reconciled Amount";
            CorpCardStatement."Previous Closed At" := CorpCardStatement."Closed At";
            CorpCardStatement."Previous Closed By User ID" := CorpCardStatement."Closed By User ID";
        end;

        CorpCardStatement."Reconciled Transactions" := 0;
        CorpCardStatement."Reconciled Amount" := 0;
        CorpCardStatement."Closed At" := 0DT;
        CorpCardStatement."Closed By User ID" := '';
        CorpCardStatement."Reconciliation Invalidated At" := CurrentDateTime();
        CorpCardStatement."Reconciliation Invalidated By" := CopyStr(UserId(), 1, MaxStrLen(CorpCardStatement."Reconciliation Invalidated By"));
        CorpCardStatement."Recon. Invalidation Reason" := InvalidationReason;
        CorpCardStatement.Status := CorpCardStatement.Status::ReconciliationRequired;
        CorpCardStatement.Modify(false);
    end;

    internal procedure GetReconciliationSummary(CorpCardStatement: Record "EA Corp Card Statement"; var ReconciledTransactions: Integer; var ReconciledAmount: Decimal; var UnreconciledTransactions: Integer; var UnreconciledAmount: Decimal; var SettlementStatus: Enum "EA Corp Card Settle Status")
    var
        CorpCardSettlement: Record "EA Corp Card Settlement";
        CorpCardTrans: Record "EA Corp Card Trans";
    begin
        Clear(ReconciledTransactions);
        Clear(ReconciledAmount);
        Clear(UnreconciledTransactions);
        Clear(UnreconciledAmount);
        Clear(SettlementStatus);

        CorpCardStatement.CalcFields("Settlement Entry No.");
        if CorpCardStatement."Settlement Entry No." = 0 then begin
            AddAllTransactionsAsUnreconciled(CorpCardStatement, UnreconciledTransactions, UnreconciledAmount);
            exit;
        end;
        if not CorpCardSettlement.Get(CorpCardStatement."Settlement Entry No.") then begin
            AddAllTransactionsAsUnreconciled(CorpCardStatement, UnreconciledTransactions, UnreconciledAmount);
            exit;
        end;
        SettlementStatus := CorpCardSettlement.Status;

        CorpCardTrans.SetRange("Statement Entry No.", CorpCardStatement."Statement Entry No.");
        CorpCardTrans.SetRange("Provider Code", CorpCardStatement."Provider Code");
        if not CorpCardTrans.FindSet() then
            exit;

        repeat
            if IsTransactionReconciled(CorpCardTrans, CorpCardStatement, CorpCardSettlement) then begin
                ReconciledTransactions += 1;
                ReconciledAmount += CorpCardTrans.Amount;
            end else begin
                UnreconciledTransactions += 1;
                UnreconciledAmount += CorpCardTrans.Amount;
            end;
        until CorpCardTrans.Next() = 0;
    end;

    local procedure ValidateTransaction(CorpCardStatement: Record "EA Corp Card Statement"; CorpCardTrans: Record "EA Corp Card Trans")
    begin
        CorpCardTrans.TestField("Provider Trans Id");
        CorpCardTrans.TestField("Card Id");
        CorpCardTrans.TestField("Trans Date");

        if CorpCardTrans."Currency Code" <> CorpCardStatement."Currency Code" then
            Error(TransactionCurrencyMismatchErr, CorpCardTrans."Entry No.", CorpCardTrans."Currency Code", CorpCardStatement."Currency Code");
        if not ((CorpCardTrans."Trans Date" >= CorpCardStatement."Period Start Date") and
                (CorpCardTrans."Trans Date" <= CorpCardStatement."Period End Date"))
        then
            Error(TransactionOutsidePeriodErr, CorpCardTrans."Entry No.", CorpCardTrans."Trans Date");
        if CorpCardTrans."Expense No." = '' then
            Error(TransactionNotMatchedToExpenseErr, CorpCardTrans."Entry No.");
    end;

    local procedure ValidateReconciledTransaction(CorpCardTrans: Record "EA Corp Card Trans"; CorpCardStatement: Record "EA Corp Card Statement"; CorpCardSettlement: Record "EA Corp Card Settlement")
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        if CorpCardTrans.Status <> CorpCardTrans.Status::Posted then
            Error(TransactionNotPostedErr, CorpCardTrans."Entry No.", CorpCardTrans.Status);
        CorpCardTrans.TestField("Posted Expense Report No.");

        BankAccountLedgerEntry.SetRange("EA Corp Card Trans Entry No.", CorpCardTrans."Entry No.");
        BankAccountLedgerEntry.SetRange(Reversed, false);
        if BankAccountLedgerEntry.Count() = 0 then
            Error(TransactionBankEntryMissingErr, CorpCardTrans."Entry No.");
        if BankAccountLedgerEntry.Count() > 1 then
            Error(TransactionHasMultipleBankEntriesErr, CorpCardTrans."Entry No.", BankAccountLedgerEntry.Count());
        BankAccountLedgerEntry.FindFirst();
        if BankAccountLedgerEntry."Bank Account No." <> CorpCardSettlement."Corp Card Bank Account No." then
            Error(TransactionBankAccountMismatchErr, CorpCardTrans."Entry No.", BankAccountLedgerEntry."Bank Account No.", CorpCardSettlement."Corp Card Bank Account No.");
        if BankAccountLedgerEntry."Currency Code" <> CorpCardStatement."Currency Code" then
            Error(TransactionBankEntryCurrencyMismatchErr, CorpCardTrans."Entry No.", BankAccountLedgerEntry."Currency Code", CorpCardStatement."Currency Code");
        if BankAccountLedgerEntry.Amount <> -CorpCardTrans.Amount then
            Error(TransactionBankEntryAmountMismatchErr, CorpCardTrans."Entry No.", BankAccountLedgerEntry.Amount, -CorpCardTrans.Amount);
    end;

    local procedure IsTransactionReconciled(CorpCardTrans: Record "EA Corp Card Trans"; CorpCardStatement: Record "EA Corp Card Statement"; CorpCardSettlement: Record "EA Corp Card Settlement"): Boolean
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        if CorpCardSettlement.Status <> CorpCardSettlement.Status::Posted then
            exit(false);
        if CorpCardTrans.Status <> CorpCardTrans.Status::Posted then
            exit(false);
        if CorpCardTrans."Posted Expense Report No." = '' then
            exit(false);

        BankAccountLedgerEntry.SetRange("EA Corp Card Trans Entry No.", CorpCardTrans."Entry No.");
        BankAccountLedgerEntry.SetRange(Reversed, false);
        if BankAccountLedgerEntry.Count() <> 1 then
            exit(false);
        BankAccountLedgerEntry.FindFirst();
        exit(
            (BankAccountLedgerEntry."Bank Account No." = CorpCardSettlement."Corp Card Bank Account No.") and
            (BankAccountLedgerEntry."Currency Code" = CorpCardStatement."Currency Code") and
            (BankAccountLedgerEntry.Amount = -CorpCardTrans.Amount));
    end;

    local procedure AddAllTransactionsAsUnreconciled(CorpCardStatement: Record "EA Corp Card Statement"; var UnreconciledTransactions: Integer; var UnreconciledAmount: Decimal)
    var
        CorpCardTrans: Record "EA Corp Card Trans";
    begin
        CorpCardTrans.SetRange("Statement Entry No.", CorpCardStatement."Statement Entry No.");
        CorpCardTrans.SetRange("Provider Code", CorpCardStatement."Provider Code");
        UnreconciledTransactions := CorpCardTrans.Count();
        CorpCardTrans.CalcSums(Amount);
        UnreconciledAmount := CorpCardTrans.Amount;
    end;

    var
        DuplicateStatementErr: Label 'Statement %1 already exists for provider %2.', Comment = '%1 = statement number, %2 = provider code';
        ImportedCountMismatchErr: Label 'The imported transaction count %1 does not equal the number of stored statement transactions %2.', Comment = '%1 = imported count, %2 = stored transaction count';
        InvalidStatementPeriodErr: Label 'The statement period start date %1 cannot be after the end date %2.', Comment = '%1 = start date, %2 = end date';
        NoStatementTransactionsErr: Label 'Corporate card statement %1 has no imported transactions.', Comment = '%1 = statement number';
        OnlyValidatedCanReopenErr: Label 'Statement entry %1 must be validated before it can be reopened.', Comment = '%1 = statement entry number';
        StatementMustBeImportedErr: Label 'Statement entry %1 must have status Imported before it can be validated. Current status: %2.', Comment = '%1 = statement entry number, %2 = status';
        StatementTotalMismatchErr: Label 'The statement total %1 does not equal the transaction total %2.', Comment = '%1 = statement total, %2 = transaction total';
        TransactionCurrencyMismatchErr: Label 'Statement transaction %1 has currency %2, but the statement currency is %3.', Comment = '%1 = transaction entry number, %2 = transaction currency, %3 = statement currency';
        TransactionBankAccountMismatchErr: Label 'Statement transaction %1 is linked to bank account %2, but corporate card bank account %3 is expected.', Comment = '%1 = transaction entry number, %2 = actual bank account number, %3 = expected bank account number';
        TransactionBankEntryAmountMismatchErr: Label 'Statement transaction %1 has bank account ledger amount %2, but amount %3 is expected.', Comment = '%1 = transaction entry number, %2 = actual amount, %3 = expected amount';
        TransactionBankEntryCurrencyMismatchErr: Label 'Statement transaction %1 has bank account ledger currency %2, but statement currency %3 is expected.', Comment = '%1 = transaction entry number, %2 = actual currency, %3 = expected currency';
        TransactionBankEntryMissingErr: Label 'Statement transaction %1 has no corporate card bank account ledger entry.', Comment = '%1 = transaction entry number';
        TransactionHasMultipleBankEntriesErr: Label 'Statement transaction %1 has %2 bank account ledger entries; exactly one is required.', Comment = '%1 = transaction entry number, %2 = entry count';
        TransactionNotMatchedToExpenseErr: Label 'Statement transaction %1 is not matched to an expense.', Comment = '%1 = transaction entry number';
        TransactionNotPostedErr: Label 'Statement transaction %1 must be posted before reconciliation can be closed. Current status: %2.', Comment = '%1 = transaction entry number, %2 = status';
        TransactionOutsidePeriodErr: Label 'Statement transaction %1 has transaction date %2, which is outside the statement period.', Comment = '%1 = transaction entry number, %2 = transaction date';
        ReconciledAmountMismatchErr: Label 'The reconciled transaction amount %1 does not equal the statement total %2.', Comment = '%1 = reconciled amount, %2 = statement total';
        StatementHasNoSettlementErr: Label 'Corporate card statement %1 is not included in a settlement.', Comment = '%1 = statement number';
        StatementMustBeValidatedForClosureErr: Label 'Statement entry %1 must have status Validated before reconciliation can be closed. Current status: %2.', Comment = '%1 = statement entry number, %2 = status';
        StatementSettlementAmountMismatchErr: Label 'Statement %1 has settlement-line amount %2, but its statement total is %3.', Comment = '%1 = statement number, %2 = settlement-line amount, %3 = statement total';
        StatementSettlementLineNotFoundErr: Label 'Statement %1 is not linked to settlement entry %2.', Comment = '%1 = statement number, %2 = settlement entry number';
        SettledStatementCannotReopenErr: Label 'Statement %1 cannot be reopened because it is included in settlement entry %2. Remove it from the open settlement before reopening.', Comment = '%1 = statement number, %2 = settlement entry number';
}
