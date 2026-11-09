// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Ledger;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Reversal;
using Microsoft.Foundation.AuditCodes;

codeunit 7449 "EA Corp Card Liability Mgt"
{
    Access = Internal;
    Permissions =
        tabledata "Bank Account Ledger Entry" = r,
        tabledata "EA Corp Card Trans" = rm;

    internal procedure TransferLiability(var CorpCardTrans: Record "EA Corp Card Trans"; PostingDate: Date)
    var
        BankAccount: Record "Bank Account";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        CorpCardStatement: Record "EA Corp Card Statement";
        GenJournalLine: Record "Gen. Journal Line";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
    begin
        LockTransaction(CorpCardTrans, CorpCardStatement);
        if CorpCardTrans."Liability Reversal Trans. No." <> 0 then
            Error(PreviouslyReversedErr, CorpCardTrans."Entry No.");
        if (CorpCardTrans."Liability Bank Entry No." <> 0) or (CorpCardTrans."Liability Transaction No." <> 0) then
            Error(AlreadyTransferredErr, CorpCardTrans."Entry No.");

        GetPostedLiability(CorpCardTrans, PostedExpenseReportLine, PostingDate);
        GetProviderBankAccount(CorpCardTrans, BankAccount);
        ValidateAmounts(CorpCardTrans, PostedExpenseReportLine, BankAccount);

        BankAccountLedgerEntry.LockTable();
        BankAccountLedgerEntry.SetRange("EA Corp Card Trans Entry No.", CorpCardTrans."Entry No.");
        BankAccountLedgerEntry.SetRange(Reversed, false);
        if not BankAccountLedgerEntry.IsEmpty() then
            Error(ExistingBankEntryErr, CorpCardTrans."Entry No.");

        CreateJournalLine(GenJournalLine, CorpCardTrans, PostedExpenseReportLine, BankAccount, PostingDate);
        GenJnlPostLine.SetIgnoreJournalTemplNameMandatoryCheck();
        GenJnlPostLine.RunWithCheck(GenJournalLine);

        if BankAccountLedgerEntry.Count() <> 1 then
            Error(BankEntryNotUniqueErr, CorpCardTrans."Entry No.");
        BankAccountLedgerEntry.FindFirst();
        BankAccountLedgerEntry.TestField("Bank Account No.", BankAccount."No.");
        BankAccountLedgerEntry.TestField("Currency Code", BankAccount."Currency Code");
        BankAccountLedgerEntry.TestField(Amount, -CorpCardTrans.GetAmountInCurrency(BankAccount."Currency Code"));
        BankAccountLedgerEntry.TestField("Amount (LCY)", PostedExpenseReportLine."Card Liability Amount (LCY)");
        BankAccountLedgerEntry.TestField("Dimension Set ID", PostedExpenseReportLine."Dimension Set ID");
        BankAccountLedgerEntry.TestField("Transaction No.");

        InvalidateStatement(CorpCardStatement, CorpCardTrans."Entry No.");
        CorpCardTrans."Liability Bank Entry No." := BankAccountLedgerEntry."Entry No.";
        CorpCardTrans."Liability Transaction No." := BankAccountLedgerEntry."Transaction No.";
        CorpCardTrans.Modify(true);
    end;

    internal procedure ReverseLiability(var CorpCardTrans: Record "EA Corp Card Trans")
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        CorpCardStatement: Record "EA Corp Card Statement";
        ReversalBankEntry: Record "Bank Account Ledger Entry";
        ReversalEntry: Record "Reversal Entry";
    begin
        LockTransaction(CorpCardTrans, CorpCardStatement);
        // Cancellation may already have reversed the expense. Only the persisted transfer is reversed here.
        if CorpCardTrans."Liability Bank Entry No." = 0 then begin
            CorpCardTrans.TestField("Liability Transaction No.", 0);
            CorpCardTrans.TestField("Liability Reversal Trans. No.", 0);
            exit;
        end;

        CorpCardTrans.TestField("Liability Transaction No.");
        BankAccountLedgerEntry.LockTable();
        BankAccountLedgerEntry.Get(CorpCardTrans."Liability Bank Entry No.");
        BankAccountLedgerEntry.TestField("EA Corp Card Trans Entry No.", CorpCardTrans."Entry No.");
        BankAccountLedgerEntry.TestField("Transaction No.", CorpCardTrans."Liability Transaction No.");
        BankAccountLedgerEntry.TestField("Reversed Entry No.", 0);
        if CorpCardTrans."Liability Reversal Trans. No." <> 0 then begin
            ValidateReversal(BankAccountLedgerEntry, ReversalBankEntry);
            ReversalBankEntry.TestField("Transaction No.", CorpCardTrans."Liability Reversal Trans. No.");
            exit;
        end;

        BankAccountLedgerEntry.TestField(Reversed, false);
        BankAccountLedgerEntry.TestField("Reversed by Entry No.", 0);
        ReversalEntry.SetHideDialog(true);
        ReversalEntry.SetHideWarningDialogs();
        ReversalEntry.ReverseTransaction(CorpCardTrans."Liability Transaction No.");

        BankAccountLedgerEntry.Get(CorpCardTrans."Liability Bank Entry No.");
        ValidateReversal(BankAccountLedgerEntry, ReversalBankEntry);
        InvalidateStatement(CorpCardStatement, CorpCardTrans."Entry No.");
        CorpCardTrans."Liability Reversal Trans. No." := ReversalBankEntry."Transaction No.";
        CorpCardTrans.Modify(true);
    end;

    local procedure LockTransaction(var CorpCardTrans: Record "EA Corp Card Trans"; var CorpCardStatement: Record "EA Corp Card Statement")
    var
        StatementEntryNo: Integer;
    begin
        StatementEntryNo := CorpCardTrans."Statement Entry No.";
        CorpCardStatement.LockTable();
        if StatementEntryNo <> 0 then
            CorpCardStatement.Get(StatementEntryNo);
        CorpCardTrans.LockTable();
        CorpCardTrans.Get(CorpCardTrans."Entry No.");
        CorpCardTrans.TestField("Statement Entry No.", StatementEntryNo);
    end;

    local procedure GetPostedLiability(CorpCardTrans: Record "EA Corp Card Trans"; var PostedExpenseReportLine: Record "Posted Expense Report Line"; PostingDate: Date)
    var
        Expense: Record Expense;
        ExpenseLedgerEntry: Record "Expense Ledger Entry";
        GLEntry: Record "G/L Entry";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        MatchingExpenseLedgerEntries: Integer;
        TransactionNo: Integer;
    begin
        CorpCardTrans.TestField(Status, CorpCardTrans.Status::Posted);
        CorpCardTrans.TestField("Expense No.");
        CorpCardTrans.TestField("Posted Expense Report No.");
        CorpCardTrans.TestField("Card Id");
        // Keep the financial basis stable without escalating reads on other record instances.
        Expense.ReadIsolation := IsolationLevel::RepeatableRead;
        Expense.Get(CorpCardTrans."Expense No.");
        Expense.TestField("Credit Card Feed No.", CorpCardTrans."Entry No.");
        Expense.TestField("Corporate Card Id", CorpCardTrans."Card Id");
        Expense.TestField("Posted Expense Report No.", CorpCardTrans."Posted Expense Report No.");
        PostedExpenseReportHeader.ReadIsolation := IsolationLevel::RepeatableRead;
        PostedExpenseReportHeader.Get(CorpCardTrans."Posted Expense Report No.");
        PostedExpenseReportHeader.TestField(Canceled, false);
        PostedExpenseReportHeader.TestField("Posting Date");
        if (PostingDate = 0D) or (PostingDate < PostedExpenseReportHeader."Posting Date") then
            Error(InvalidPostingDateErr, PostedExpenseReportHeader."Posting Date");

        PostedExpenseReportLine.ReadIsolation := IsolationLevel::RepeatableRead;
        PostedExpenseReportLine.SetRange("Document No.", CorpCardTrans."Posted Expense Report No.");
        PostedExpenseReportLine.SetRange("Expense No.", CorpCardTrans."Expense No.");
        PostedExpenseReportLine.SetRange("Is Canceled", false);
        if PostedExpenseReportLine.Count() <> 1 then
            Error(PostedLineNotUniqueErr, CorpCardTrans."Entry No.");
        PostedExpenseReportLine.FindFirst();
        PostedExpenseReportLine.TestField("Reimbursement Type", PostedExpenseReportLine."Reimbursement Type"::"Credit Card");
        PostedExpenseReportLine.TestField("Corporate Card Id", CorpCardTrans."Card Id");
        PostedExpenseReportLine.TestField("Credit Card Feed No.", CorpCardTrans."Entry No.");
        PostedExpenseReportLine.TestField("Card Payable Account No.");
        PostedExpenseReportLine.TestField("Card Liability Amount");
        PostedExpenseReportLine.TestField("Card Liability Amount (LCY)");
        if (PostedExpenseReportLine."Card Liability Amount" < 0) <>
           (PostedExpenseReportLine."Card Liability Amount (LCY)" < 0)
        then
            Error(LiabilityAmountMismatchErr, CorpCardTrans."Entry No.");
        if PostedExpenseReportLine."Card Liability Currency Code" <> '' then
            if PostedExpenseReportLine."Card Liability Currency Factor" <= 0 then
                Error(InvalidCurrencyFactorErr);

        ExpenseLedgerEntry.ReadIsolation := IsolationLevel::RepeatableRead;
        ExpenseLedgerEntry.SetRange("Document No.", PostedExpenseReportLine."Document No.");
        ExpenseLedgerEntry.SetRange("Document Line No.", PostedExpenseReportLine."Line No.");
        ExpenseLedgerEntry.SetRange("Posting Date", PostedExpenseReportHeader."Posting Date");
        ExpenseLedgerEntry.SetRange(Reversed, false);
        if ExpenseLedgerEntry.FindSet() then
            repeat
                if ExpenseLedgerEntry."Posting Date" = PostedExpenseReportHeader."Posting Date" then begin
                    MatchingExpenseLedgerEntries += 1;
                    if MatchingExpenseLedgerEntries > 1 then
                        Error(OriginalPostingMissingErr, PostedExpenseReportLine."Document No.");
                    ExpenseLedgerEntry.TestField("Transaction No.");
                    TransactionNo := ExpenseLedgerEntry."Transaction No.";
                end;
            until ExpenseLedgerEntry.Next() = 0;
        if MatchingExpenseLedgerEntries <> 1 then
            Error(OriginalPostingMissingErr, PostedExpenseReportLine."Document No.");
        GLEntry.ReadIsolation := IsolationLevel::RepeatableRead;
        GLEntry.SetRange("Transaction No.", TransactionNo);
        GLEntry.SetRange(Reversed, true);
        if not GLEntry.IsEmpty() then
            Error(OriginalPostingMissingErr, PostedExpenseReportLine."Document No.");
        GLEntry.SetRange(Reversed, false);
        GLEntry.SetRange("G/L Account No.", PostedExpenseReportLine."Card Payable Account No.");
        if GLEntry.IsEmpty() then
            Error(OriginalPostingMissingErr, PostedExpenseReportLine."Document No.");
    end;

    local procedure GetProviderBankAccount(CorpCardTrans: Record "EA Corp Card Trans"; var BankAccount: Record "Bank Account")
    var
        BankAccountPostingGroup: Record "Bank Account Posting Group";
        CorpCard: Record "EA Corp Card";
        CorpCardProvider: Record "EA Corp Card Provider";
    begin
        CorpCard.Get(CorpCardTrans."Card Id");
        CorpCard.TestField(Blocked, false);
        CorpCard.TestField("Provider Code", CorpCardTrans."Provider Code");
        CorpCardProvider.Get(CorpCardTrans."Provider Code");
        CorpCardProvider.TestField("Corp Card Bank Account No.");
        BankAccount.Get(CorpCardProvider."Corp Card Bank Account No.");
        BankAccount.TestField(Blocked, false);
        BankAccount.TestField("Bank Acc. Posting Group");
        BankAccountPostingGroup.Get(BankAccount."Bank Acc. Posting Group");
        BankAccountPostingGroup.TestField("G/L Account No.");
    end;

    local procedure ValidateAmounts(CorpCardTrans: Record "EA Corp Card Trans"; PostedExpenseReportLine: Record "Posted Expense Report Line"; BankAccount: Record "Bank Account")
    var
        BankAmount: Decimal;
    begin
        if (BankAccount."Currency Code" <> '') and
           (BankAccount."Currency Code" <> PostedExpenseReportLine."Card Liability Currency Code")
        then
            Error(UnsupportedCurrencyErr, BankAccount."Currency Code", PostedExpenseReportLine."Card Liability Currency Code");
        if (CorpCardTrans."Currency Code" <> '') and
           ((BankAccount."Currency Code" = '') or (PostedExpenseReportLine."Card Liability Currency Code" = ''))
        then
            CorpCardTrans.TestField("Amount (LCY)");
        if PostedExpenseReportLine."Card Liability Amount" <>
           -CorpCardTrans.GetAmountInCurrency(PostedExpenseReportLine."Card Liability Currency Code")
        then
            Error(LiabilityAmountMismatchErr, CorpCardTrans."Entry No.");

        BankAmount := -CorpCardTrans.GetAmountInCurrency(BankAccount."Currency Code");
        if BankAccount."Currency Code" = '' then begin
            if BankAmount <> PostedExpenseReportLine."Card Liability Amount (LCY)" then
                Error(LiabilityAmountMismatchErr, CorpCardTrans."Entry No.");
        end else
            if BankAmount <> PostedExpenseReportLine."Card Liability Amount" then
                Error(LiabilityAmountMismatchErr, CorpCardTrans."Entry No.");
    end;

    local procedure CreateJournalLine(var GenJournalLine: Record "Gen. Journal Line"; CorpCardTrans: Record "EA Corp Card Trans"; PostedExpenseReportLine: Record "Posted Expense Report Line"; BankAccount: Record "Bank Account"; PostingDate: Date)
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        SourceCodeSetup.Get();
        SourceCodeSetup.TestField(Expense);
        GenJournalLine.Init();
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::" ");
        GenJournalLine.Validate("Document No.", PostedExpenseReportLine."Document No.");
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::"Bank Account");
        GenJournalLine.Validate("Account No.", BankAccount."No.");
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", PostedExpenseReportLine."Card Payable Account No.");
        ClearPostingGroups(GenJournalLine);
        GenJournalLine.Validate("Currency Code", BankAccount."Currency Code");
        if BankAccount."Currency Code" <> '' then
            GenJournalLine."Currency Factor" := PostedExpenseReportLine."Card Liability Currency Factor";
        GenJournalLine.Validate(Amount, -CorpCardTrans.GetAmountInCurrency(BankAccount."Currency Code"));
        // Clear the historical liability exactly, not a conversion at the transfer date's exchange rate.
        GenJournalLine."Amount (LCY)" := PostedExpenseReportLine."Card Liability Amount (LCY)";
        GenJournalLine.Validate("Dimension Set ID", PostedExpenseReportLine."Dimension Set ID");
        ClearPostingGroups(GenJournalLine);
        GenJournalLine."Source Currency Code" := GenJournalLine."Currency Code";
        GenJournalLine."Source Currency Amount" := GenJournalLine.Amount;
        GenJournalLine.Description :=
            CopyStr(StrSubstNo(TransferDescriptionTxt, CorpCardTrans."Entry No."), 1, MaxStrLen(GenJournalLine.Description));
        GenJournalLine."Source Code" := SourceCodeSetup.Expense;
        GenJournalLine."EA Corp Card Trans Entry No." := CorpCardTrans."Entry No.";
        GenJournalLine."System-Created Entry" := true;
    end;

    local procedure ClearPostingGroups(var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine."Gen. Posting Type" := GenJournalLine."Gen. Posting Type"::" ";
        GenJournalLine."Gen. Bus. Posting Group" := '';
        GenJournalLine."Gen. Prod. Posting Group" := '';
        GenJournalLine."VAT Bus. Posting Group" := '';
        GenJournalLine."VAT Prod. Posting Group" := '';
        Clear(GenJournalLine."VAT Calculation Type");
        GenJournalLine."VAT %" := 0;
        GenJournalLine."VAT Amount" := 0;
        GenJournalLine."VAT Base Amount" := 0;
        GenJournalLine."VAT Amount (LCY)" := 0;
        GenJournalLine."VAT Base Amount (LCY)" := 0;
        GenJournalLine."VAT Difference" := 0;
        GenJournalLine."Source Curr. VAT Amount" := 0;
        GenJournalLine."Source Curr. VAT Base Amount" := 0;
        GenJournalLine."Bal. Gen. Posting Type" := GenJournalLine."Bal. Gen. Posting Type"::" ";
        GenJournalLine."Bal. Gen. Bus. Posting Group" := '';
        GenJournalLine."Bal. Gen. Prod. Posting Group" := '';
        GenJournalLine."Bal. VAT Bus. Posting Group" := '';
        GenJournalLine."Bal. VAT Prod. Posting Group" := '';
        Clear(GenJournalLine."Bal. VAT Calculation Type");
        GenJournalLine."Bal. VAT %" := 0;
        GenJournalLine."Bal. VAT Amount" := 0;
        GenJournalLine."Bal. VAT Base Amount" := 0;
        GenJournalLine."Bal. VAT Amount (LCY)" := 0;
        GenJournalLine."Bal. VAT Base Amount (LCY)" := 0;
        GenJournalLine."Bal. VAT Difference" := 0;
    end;

    local procedure ValidateReversal(BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; var ReversalBankEntry: Record "Bank Account Ledger Entry")
    begin
        BankAccountLedgerEntry.TestField(Reversed, true);
        BankAccountLedgerEntry.TestField("Reversed by Entry No.");
        ReversalBankEntry.Get(BankAccountLedgerEntry."Reversed by Entry No.");
        ReversalBankEntry.TestField(Reversed, true);
        ReversalBankEntry.TestField("Reversed Entry No.", BankAccountLedgerEntry."Entry No.");
        ReversalBankEntry.TestField("Bank Account No.", BankAccountLedgerEntry."Bank Account No.");
        ReversalBankEntry.TestField("Currency Code", BankAccountLedgerEntry."Currency Code");
        ReversalBankEntry.TestField(Amount, -BankAccountLedgerEntry.Amount);
        ReversalBankEntry.TestField("Amount (LCY)", -BankAccountLedgerEntry."Amount (LCY)");
        ReversalBankEntry.TestField("Dimension Set ID", BankAccountLedgerEntry."Dimension Set ID");
        ReversalBankEntry.TestField("Transaction No.");
    end;

    local procedure InvalidateStatement(var CorpCardStatement: Record "EA Corp Card Statement"; TransactionEntryNo: Integer)
    var
        CorpCardStatementMgt: Codeunit "EA Corp Card Statement Mgt";
        InvalidationReason: Text[250];
    begin
        if CorpCardStatement."Statement Entry No." = 0 then
            exit;
        InvalidationReason := CopyStr(StrSubstNo(LiabilityChangedReasonTxt, TransactionEntryNo), 1, MaxStrLen(InvalidationReason));
        CorpCardStatementMgt.InvalidateReconciliation(CorpCardStatement, InvalidationReason);
    end;

    var
        AlreadyTransferredErr: Label 'Liability has already been transferred for corporate card transaction %1.', Comment = '%1 = corporate card transaction entry number';
        PreviouslyReversedErr: Label 'Liability transfer for corporate card transaction %1 was reversed. A new transfer is not supported because the original audit references must be preserved.', Comment = '%1 = corporate card transaction entry number';
        ExistingBankEntryErr: Label 'Corporate card transaction %1 already has an active bank account ledger entry.', Comment = '%1 = corporate card transaction entry number';
        BankEntryNotUniqueErr: Label 'Liability transfer for corporate card transaction %1 must create exactly one active bank account ledger entry.', Comment = '%1 = corporate card transaction entry number';
        InvalidPostingDateErr: Label 'The liability transfer posting date must be specified and cannot precede the original expense posting date %1.', Comment = '%1 = original expense posting date';
        PostedLineNotUniqueErr: Label 'Corporate card transaction %1 must be linked to exactly one uncanceled posted expense report line.', Comment = '%1 = corporate card transaction entry number';
        LiabilityAmountMismatchErr: Label 'The original liability amounts do not match corporate card transaction %1. Liability cannot be transferred.', Comment = '%1 = corporate card transaction entry number';
        InvalidCurrencyFactorErr: Label 'The original liability must have a positive currency factor for a foreign currency.', Comment = 'The currency factor is captured when the original expense is posted.';
        OriginalPostingMissingErr: Label 'The original unreversed expense posting for report %1 could not be verified.', Comment = '%1 = posted expense report number';
        UnsupportedCurrencyErr: Label 'Bank currency %1 is not compatible with original liability currency %2. Cross-currency liability transfers are not supported.', Comment = '%1 = bank currency code, %2 = original liability currency code';
        TransferDescriptionTxt: Label 'Corporate card liability transfer %1', Comment = '%1 = corporate card transaction entry number';
        LiabilityChangedReasonTxt: Label 'Liability transfer or reversal changed corporate card transaction %1.', Comment = '%1 = corporate card transaction entry number';
}
