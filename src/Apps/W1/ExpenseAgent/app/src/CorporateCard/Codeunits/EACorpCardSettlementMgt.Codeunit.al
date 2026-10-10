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

codeunit 7443 "EA Corp Card Settlement Mgt"
{
    Access = Internal;
    Permissions =
        tabledata "Bank Account Ledger Entry" = r,
        tabledata "EA Corp Card Settlement" = rimd,
        tabledata "EA Corp Card Settlement Line" = rimd;

    internal procedure SetReadyToPost(var CorpCardSettlement: Record "EA Corp Card Settlement")
    begin
        CorpCardSettlement.EnsureOpen();
        ValidateSettlement(CorpCardSettlement);

        CorpCardSettlement.Status := CorpCardSettlement.Status::ReadyToPost;
        CorpCardSettlement.Modify(true);
    end;

    internal procedure PostSettlement(var CorpCardSettlement: Record "EA Corp Card Settlement")
    var
        CorpCardBankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        GLRegister: Record "G/L Register";
        GenJournalLine: Record "Gen. Journal Line";
        PaymentBankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
    begin
        CorpCardSettlement.LockTable();
        CorpCardSettlement.Get(CorpCardSettlement."Settlement Entry No.");
        if CorpCardSettlement.Status <> CorpCardSettlement.Status::ReadyToPost then
            Error(SettlementNotReadyToPostErr, CorpCardSettlement."Settlement Entry No.", CorpCardSettlement.Status);

        ValidateSettlement(CorpCardSettlement);
        CreateSettlementJournalLine(GenJournalLine, CorpCardSettlement);

        GenJnlPostLine.SetIgnoreJournalTemplNameMandatoryCheck();
        GenJnlPostLine.RunWithCheck(GenJournalLine);
        GenJnlPostLine.GetGLReg(GLRegister);

        GetSettlementBankAccountLedgerEntry(
            CorpCardBankAccountLedgerEntry, CorpCardSettlement,
            CorpCardSettlement."Corp Card Bank Account No.");
        GetSettlementBankAccountLedgerEntry(
            PaymentBankAccountLedgerEntry, CorpCardSettlement,
            CorpCardSettlement."Payment Bank Account No.");
        if CorpCardBankAccountLedgerEntry."Transaction No." <> PaymentBankAccountLedgerEntry."Transaction No." then
            Error(SettlementEntriesTransactionMismatchErr, CorpCardSettlement."Settlement Entry No.");

        CorpCardSettlement."Posted Document No." := GenJournalLine."Document No.";
        CorpCardSettlement."Posted Date" := CorpCardSettlement."Settlement Date";
        CorpCardSettlement."Corp Card Bank Acc. Entry No." := CorpCardBankAccountLedgerEntry."Entry No.";
        CorpCardSettlement."Payment Bank Acc. Entry No." := PaymentBankAccountLedgerEntry."Entry No.";
        CorpCardSettlement."G/L Register No." := GLRegister."No.";
        CorpCardSettlement."Transaction No." := CorpCardBankAccountLedgerEntry."Transaction No.";
        CorpCardSettlement.Status := CorpCardSettlement.Status::Posted;
        CorpCardSettlement.Modify(true);
    end;

    internal procedure Reopen(var CorpCardSettlement: Record "EA Corp Card Settlement")
    begin
        if CorpCardSettlement.Status = CorpCardSettlement.Status::Open then
            exit;
        if CorpCardSettlement.Status <> CorpCardSettlement.Status::ReadyToPost then
            Error(OnlyReadySettlementCanReopenErr, CorpCardSettlement."Settlement Entry No.");

        CorpCardSettlement.Status := CorpCardSettlement.Status::Open;
        CorpCardSettlement.Modify(true);
    end;

    internal procedure ValidatePostedSettlement(CorpCardSettlement: Record "EA Corp Card Settlement")
    var
        CorpCardBankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        PaymentBankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        if CorpCardSettlement.Status <> CorpCardSettlement.Status::Posted then
            Error(SettlementNotPostedErr, CorpCardSettlement."Settlement Entry No.", CorpCardSettlement.Status);

        if not CorpCardBankAccountLedgerEntry.Get(CorpCardSettlement."Corp Card Bank Acc. Entry No.") then
            Error(SettlementBankAccountEntryNotFoundErr, CorpCardSettlement."Settlement Entry No.", CorpCardSettlement."Corp Card Bank Account No.");
        if not PaymentBankAccountLedgerEntry.Get(CorpCardSettlement."Payment Bank Acc. Entry No.") then
            Error(SettlementBankAccountEntryNotFoundErr, CorpCardSettlement."Settlement Entry No.", CorpCardSettlement."Payment Bank Account No.");

        ValidateSettlementBankAccountLedgerEntry(
            CorpCardBankAccountLedgerEntry, CorpCardSettlement,
            CorpCardSettlement."Corp Card Bank Account No.", CorpCardSettlement."Settlement Amount");
        ValidateSettlementBankAccountLedgerEntry(
            PaymentBankAccountLedgerEntry, CorpCardSettlement,
            CorpCardSettlement."Payment Bank Account No.", -CorpCardSettlement."Settlement Amount");
        if CorpCardBankAccountLedgerEntry."Transaction No." <> PaymentBankAccountLedgerEntry."Transaction No." then
            Error(SettlementEntriesTransactionMismatchErr, CorpCardSettlement."Settlement Entry No.");
        if CorpCardSettlement."Transaction No." <> CorpCardBankAccountLedgerEntry."Transaction No." then
            Error(SettlementTransactionChangedErr, CorpCardSettlement."Settlement Entry No.");
    end;

    internal procedure ReverseSettlement(var CorpCardSettlement: Record "EA Corp Card Settlement")
    var
        CorpCardBankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        CorpCardReversalBankEntry: Record "Bank Account Ledger Entry";
        PaymentBankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        PaymentReversalBankEntry: Record "Bank Account Ledger Entry";
        ReversalGLRegister: Record "G/L Register";
        ReversalEntry: Record "Reversal Entry";
    begin
        CorpCardSettlement.LockTable();
        CorpCardSettlement.Get(CorpCardSettlement."Settlement Entry No.");
        if CorpCardSettlement.Status <> CorpCardSettlement.Status::Posted then
            Error(OnlyPostedSettlementCanReverseErr, CorpCardSettlement."Settlement Entry No.", CorpCardSettlement.Status);
        CorpCardSettlement.TestField("Reversal Reason");
        ValidatePostedSettlement(CorpCardSettlement);

        ReversalEntry.SetHideDialog(true);
        ReversalEntry.SetHideWarningDialogs();
        ReversalEntry.ReverseTransaction(CorpCardSettlement."Transaction No.");

        CorpCardBankAccountLedgerEntry.Get(CorpCardSettlement."Corp Card Bank Acc. Entry No.");
        PaymentBankAccountLedgerEntry.Get(CorpCardSettlement."Payment Bank Acc. Entry No.");
        CorpCardBankAccountLedgerEntry.TestField("Reversed by Entry No.");
        PaymentBankAccountLedgerEntry.TestField("Reversed by Entry No.");
        CorpCardReversalBankEntry.Get(CorpCardBankAccountLedgerEntry."Reversed by Entry No.");
        PaymentReversalBankEntry.Get(PaymentBankAccountLedgerEntry."Reversed by Entry No.");
        if CorpCardReversalBankEntry."Transaction No." <> PaymentReversalBankEntry."Transaction No." then
            Error(ReversalEntriesTransactionMismatchErr, CorpCardSettlement."Settlement Entry No.");
        ValidateReversalBankAccountLedgerEntry(
            CorpCardReversalBankEntry, CorpCardSettlement,
            CorpCardSettlement."Corp Card Bank Account No.", -CorpCardSettlement."Settlement Amount");
        ValidateReversalBankAccountLedgerEntry(
            PaymentReversalBankEntry, CorpCardSettlement,
            CorpCardSettlement."Payment Bank Account No.", CorpCardSettlement."Settlement Amount");
        FindGLRegisterForTransaction(ReversalGLRegister, CorpCardReversalBankEntry."Transaction No.");

        InvalidateSettlementStatements(CorpCardSettlement);

        CorpCardSettlement."Reversal Transaction No." := CorpCardReversalBankEntry."Transaction No.";
        CorpCardSettlement."Reversal G/L Register No." := ReversalGLRegister."No.";
        CorpCardSettlement."Corp Card Reversal Entry No." := CorpCardReversalBankEntry."Entry No.";
        CorpCardSettlement."Payment Reversal Entry No." := PaymentReversalBankEntry."Entry No.";
        CorpCardSettlement."Reversed At" := CurrentDateTime();
        CorpCardSettlement."Reversed By User ID" := CopyStr(UserId(), 1, MaxStrLen(CorpCardSettlement."Reversed By User ID"));
        CorpCardSettlement.Status := CorpCardSettlement.Status::Reversed;
        CorpCardSettlement.Modify(true);
    end;

    local procedure ValidateSettlement(CorpCardSettlement: Record "EA Corp Card Settlement")
    var
        CorpCardBankAccount: Record "Bank Account";
        CorpCardBankAccountPostingGroup: Record "Bank Account Posting Group";
        CorpCardSettlementLine: Record "EA Corp Card Settlement Line";
        CorpCardStatement: Record "EA Corp Card Statement";
        DuplicateSettlement: Record "EA Corp Card Settlement";
        PaymentBankAccount: Record "Bank Account";
        PaymentBankAccountPostingGroup: Record "Bank Account Posting Group";
        StatementTotal: Decimal;
    begin
        CorpCardSettlement.TestField("Provider Code");
        CorpCardSettlement.TestField("Settlement No.");
        CorpCardSettlement.TestField("Settlement Date");
        CorpCardSettlement.TestField("Corp Card Bank Account No.");
        CorpCardSettlement.TestField("Payment Bank Account No.");
        if CorpCardSettlement."Settlement Amount" <= 0 then
            Error(SettlementAmountMustBePositiveErr);
        if CorpCardSettlement."Corp Card Bank Account No." = CorpCardSettlement."Payment Bank Account No." then
            Error(SettlementAccountsMustDifferErr);

        CorpCardBankAccount.Get(CorpCardSettlement."Corp Card Bank Account No.");
        PaymentBankAccount.Get(CorpCardSettlement."Payment Bank Account No.");
        ValidateBankAccountCurrency(CorpCardBankAccount, CorpCardSettlement."Currency Code");
        ValidateBankAccountCurrency(PaymentBankAccount, CorpCardSettlement."Currency Code");
        CorpCardBankAccount.TestField("Bank Acc. Posting Group");
        PaymentBankAccount.TestField("Bank Acc. Posting Group");
        CorpCardBankAccountPostingGroup.Get(CorpCardBankAccount."Bank Acc. Posting Group");
        PaymentBankAccountPostingGroup.Get(PaymentBankAccount."Bank Acc. Posting Group");
        CorpCardBankAccountPostingGroup.TestField("G/L Account No.");
        PaymentBankAccountPostingGroup.TestField("G/L Account No.");

        DuplicateSettlement.SetRange("Provider Code", CorpCardSettlement."Provider Code");
        DuplicateSettlement.SetRange("Settlement No.", CorpCardSettlement."Settlement No.");
        DuplicateSettlement.SetFilter("Settlement Entry No.", '<>%1', CorpCardSettlement."Settlement Entry No.");
        if not DuplicateSettlement.IsEmpty() then
            Error(DuplicateSettlementErr, CorpCardSettlement."Settlement No.", CorpCardSettlement."Provider Code");

        CorpCardSettlementLine.SetRange("Settlement Entry No.", CorpCardSettlement."Settlement Entry No.");
        CorpCardSettlementLine.SetRange(Inactive, false);
        if not CorpCardSettlementLine.FindSet() then
            Error(NoStatementsErr, CorpCardSettlement."Settlement No.");

        repeat
            CorpCardStatement.Get(CorpCardSettlementLine."Statement Entry No.");
            if not (CorpCardStatement.Status in [CorpCardStatement.Status::Validated, CorpCardStatement.Status::ReconciliationRequired]) then
                Error(StatementStatusNotEligibleErr, CorpCardStatement."Statement No.", CorpCardStatement.Status);
            if CorpCardStatement."Provider Code" <> CorpCardSettlement."Provider Code" then
                Error(StatementChangedErr, CorpCardStatement."Statement No.");
            if (CorpCardStatement."Statement No." <> CorpCardSettlementLine."Statement No.") or
               (CorpCardStatement."Statement Date" <> CorpCardSettlementLine."Statement Date") or
               (CorpCardStatement.GetTotalInCurrency(CorpCardSettlement."Currency Code") <> CorpCardSettlementLine."Statement Amount")
            then
                Error(StatementChangedErr, CorpCardStatement."Statement No.");
            StatementTotal += CorpCardSettlementLine."Statement Amount";
        until CorpCardSettlementLine.Next() = 0;

        if StatementTotal <> CorpCardSettlement."Settlement Amount" then
            Error(SettlementTotalMismatchErr, CorpCardSettlement."Settlement Amount", StatementTotal);
    end;

    local procedure CreateSettlementJournalLine(var GenJournalLine: Record "Gen. Journal Line"; CorpCardSettlement: Record "EA Corp Card Settlement")
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        SourceCodeSetup.Get();
        SourceCodeSetup.TestField(Expense);

        GenJournalLine.Init();
        GenJournalLine.Validate("Posting Date", CorpCardSettlement."Settlement Date");
        GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::" ");
        GenJournalLine.Validate("Document No.", CopyStr(CorpCardSettlement."Settlement No.", 1, MaxStrLen(GenJournalLine."Document No.")));
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::"Bank Account");
        GenJournalLine.Validate("Account No.", CorpCardSettlement."Corp Card Bank Account No.");
        GenJournalLine.Validate("Currency Code", CorpCardSettlement."Currency Code");
        GenJournalLine.Validate(Amount, CorpCardSettlement."Settlement Amount");
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", CorpCardSettlement."Payment Bank Account No.");
        GenJournalLine.Description :=
            CopyStr(StrSubstNo(SettlementDescriptionTxt, CorpCardSettlement."Settlement No."), 1, MaxStrLen(GenJournalLine.Description));
        GenJournalLine."External Document No." :=
            CopyStr(CorpCardSettlement."Settlement No.", 1, MaxStrLen(GenJournalLine."External Document No."));
        GenJournalLine."Source Code" := SourceCodeSetup.Expense;
        GenJournalLine."EA Corp Card Settle Entry No." := CorpCardSettlement."Settlement Entry No.";
        GenJournalLine."System-Created Entry" := true;
    end;

    local procedure GetSettlementBankAccountLedgerEntry(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; CorpCardSettlement: Record "EA Corp Card Settlement"; BankAccountNo: Code[20])
    begin
        BankAccountLedgerEntry.SetRange("EA Corp Card Settle Entry No.", CorpCardSettlement."Settlement Entry No.");
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccountNo);
        if not BankAccountLedgerEntry.FindFirst() then
            Error(SettlementBankAccountEntryNotFoundErr, CorpCardSettlement."Settlement Entry No.", BankAccountNo);
    end;

    local procedure ValidateSettlementBankAccountLedgerEntry(BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; CorpCardSettlement: Record "EA Corp Card Settlement"; ExpectedBankAccountNo: Code[20]; ExpectedAmount: Decimal)
    begin
        if BankAccountLedgerEntry.Reversed then
            Error(SettlementBankAccountEntryReversedErr, BankAccountLedgerEntry."Entry No.");
        if BankAccountLedgerEntry."Bank Account No." <> ExpectedBankAccountNo then
            Error(SettlementBankAccountChangedErr, BankAccountLedgerEntry."Entry No.", ExpectedBankAccountNo);
        if BankAccountLedgerEntry.Amount <> ExpectedAmount then
            Error(SettlementBankAccountAmountChangedErr, BankAccountLedgerEntry."Entry No.", ExpectedAmount, BankAccountLedgerEntry.Amount);
        if BankAccountLedgerEntry."Currency Code" <> CorpCardSettlement."Currency Code" then
            Error(SettlementBankAccountCurrencyChangedErr, BankAccountLedgerEntry."Entry No.", CorpCardSettlement."Currency Code", BankAccountLedgerEntry."Currency Code");
        if BankAccountLedgerEntry."EA Corp Card Settle Entry No." <> CorpCardSettlement."Settlement Entry No." then
            Error(SettlementBankAccountReferenceChangedErr, BankAccountLedgerEntry."Entry No.", CorpCardSettlement."Settlement Entry No.");
    end;

    local procedure ValidateReversalBankAccountLedgerEntry(BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; CorpCardSettlement: Record "EA Corp Card Settlement"; ExpectedBankAccountNo: Code[20]; ExpectedAmount: Decimal)
    begin
        if not BankAccountLedgerEntry.Reversed then
            Error(ReversalBankAccountEntryNotReversedErr, BankAccountLedgerEntry."Entry No.");
        if BankAccountLedgerEntry."Bank Account No." <> ExpectedBankAccountNo then
            Error(SettlementBankAccountChangedErr, BankAccountLedgerEntry."Entry No.", ExpectedBankAccountNo);
        if BankAccountLedgerEntry.Amount <> ExpectedAmount then
            Error(SettlementBankAccountAmountChangedErr, BankAccountLedgerEntry."Entry No.", ExpectedAmount, BankAccountLedgerEntry.Amount);
        if BankAccountLedgerEntry."Currency Code" <> CorpCardSettlement."Currency Code" then
            Error(SettlementBankAccountCurrencyChangedErr, BankAccountLedgerEntry."Entry No.", CorpCardSettlement."Currency Code", BankAccountLedgerEntry."Currency Code");
        if BankAccountLedgerEntry."EA Corp Card Settle Entry No." <> CorpCardSettlement."Settlement Entry No." then
            Error(SettlementBankAccountReferenceChangedErr, BankAccountLedgerEntry."Entry No.", CorpCardSettlement."Settlement Entry No.");
    end;

    local procedure InvalidateSettlementStatements(CorpCardSettlement: Record "EA Corp Card Settlement")
    var
        CorpCardSettlementLine: Record "EA Corp Card Settlement Line";
        CorpCardStatement: Record "EA Corp Card Statement";
        CorpCardStatementMgt: Codeunit "EA Corp Card Statement Mgt";
        InvalidationReason: Text[250];
    begin
        InvalidationReason :=
            CopyStr(
                StrSubstNo(SettlementReversedReasonTxt, CorpCardSettlement."Settlement No.", CorpCardSettlement."Reversal Reason"),
                1, MaxStrLen(InvalidationReason));
        CorpCardSettlementLine.SetRange("Settlement Entry No.", CorpCardSettlement."Settlement Entry No.");
        CorpCardSettlementLine.SetRange(Inactive, false);
        if not CorpCardSettlementLine.FindSet(true) then
            exit;

        repeat
            CorpCardStatement.Get(CorpCardSettlementLine."Statement Entry No.");
            CorpCardStatementMgt.InvalidateReconciliation(CorpCardStatement, InvalidationReason);
            CorpCardSettlementLine.Inactive := true;
            CorpCardSettlementLine.Modify(false);
        until CorpCardSettlementLine.Next() = 0;
    end;

    local procedure FindGLRegisterForTransaction(var GLRegister: Record "G/L Register"; TransactionNo: Integer)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Transaction No.", TransactionNo);
        if not GLEntry.FindFirst() then
            Error(ReversalGLEntryNotFoundErr, TransactionNo);

        GLRegister.SetFilter("From Entry No.", '<=%1', GLEntry."Entry No.");
        GLRegister.SetFilter("To Entry No.", '>=%1', GLEntry."Entry No.");
        if not GLRegister.FindFirst() then
            Error(ReversalGLRegisterNotFoundErr, TransactionNo);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnPostBankAccOnBeforeBankAccLedgEntryInsert', '', false, false)]
    local procedure CopyCorpCardReferencesToBankAccountLedgerEntry(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line"; BankAccount: Record "Bank Account"; var TempGLEntryBuf: Record "G/L Entry" temporary; var NextTransactionNo: Integer; GLRegister: Record "G/L Register"; Balancing: Boolean)
    begin
        BankAccountLedgerEntry."EA Corp Card Trans Entry No." := GenJournalLine."EA Corp Card Trans Entry No.";
        BankAccountLedgerEntry."EA Corp Card Settle Entry No." := GenJournalLine."EA Corp Card Settle Entry No.";
    end;

    local procedure ValidateBankAccountCurrency(BankAccount: Record "Bank Account"; SettlementCurrencyCode: Code[10])
    begin
        if BankAccount."Currency Code" <> SettlementCurrencyCode then
            Error(BankAccountCurrencyMismatchErr, BankAccount."No.", BankAccount."Currency Code", SettlementCurrencyCode);
    end;

    var
        BankAccountCurrencyMismatchErr: Label 'Bank account %1 has currency %2, but the settlement currency is %3.', Comment = '%1 = bank account number, %2 = bank account currency, %3 = settlement currency';
        DuplicateSettlementErr: Label 'Settlement %1 already exists for provider %2.', Comment = '%1 = settlement number, %2 = provider code';
        NoStatementsErr: Label 'Settlement %1 has no statements.', Comment = '%1 = settlement number';
        OnlyReadySettlementCanReopenErr: Label 'Settlement entry %1 must be ready to post before it can be reopened.', Comment = '%1 = settlement entry number';
        OnlyPostedSettlementCanReverseErr: Label 'Settlement entry %1 must be posted before it can be reversed. Current status: %2.', Comment = '%1 = settlement entry number, %2 = settlement status';
        ReversalBankAccountEntryNotReversedErr: Label 'Bank account ledger entry %1 created by settlement reversal is not marked as reversed.', Comment = '%1 = bank account ledger entry number';
        ReversalEntriesTransactionMismatchErr: Label 'The reversal bank account ledger entries for settlement entry %1 do not belong to the same transaction.', Comment = '%1 = settlement entry number';
        ReversalGLEntryNotFoundErr: Label 'No general ledger entry was found for reversal transaction %1.', Comment = '%1 = transaction number';
        ReversalGLRegisterNotFoundErr: Label 'No G/L register was found for reversal transaction %1.', Comment = '%1 = transaction number';
        SettlementBankAccountEntryNotFoundErr: Label 'Settlement entry %1 was posted, but its bank account ledger entry for bank account %2 could not be found.', Comment = '%1 = settlement entry number, %2 = bank account number';
        SettlementBankAccountEntryReversedErr: Label 'Bank account ledger entry %1 has already been reversed.', Comment = '%1 = bank account ledger entry number';
        SettlementBankAccountAmountChangedErr: Label 'Bank account ledger entry %1 must have amount %2, but its amount is %3.', Comment = '%1 = bank account ledger entry number, %2 = expected amount, %3 = actual amount';
        SettlementBankAccountChangedErr: Label 'Bank account ledger entry %1 must belong to bank account %2.', Comment = '%1 = bank account ledger entry number, %2 = expected bank account number';
        SettlementBankAccountCurrencyChangedErr: Label 'Bank account ledger entry %1 must have currency %2, but its currency is %3.', Comment = '%1 = bank account ledger entry number, %2 = expected currency, %3 = actual currency';
        SettlementBankAccountReferenceChangedErr: Label 'Bank account ledger entry %1 must reference settlement entry %2.', Comment = '%1 = bank account ledger entry number, %2 = settlement entry number';
        SettlementDescriptionTxt: Label 'Corporate card settlement %1', Comment = '%1 = settlement number';
        SettlementEntriesTransactionMismatchErr: Label 'The bank account ledger entries for settlement entry %1 do not belong to the same transaction.', Comment = '%1 = settlement entry number';
        SettlementNotReadyToPostErr: Label 'Settlement entry %1 must be ready to post. Current status: %2.', Comment = '%1 = settlement entry number, %2 = settlement status';
        SettlementNotPostedErr: Label 'Settlement entry %1 must be posted before it can be reconciled. Current status: %2.', Comment = '%1 = settlement entry number, %2 = settlement status';
        SettlementTransactionChangedErr: Label 'The stored transaction number for settlement entry %1 does not match its bank account ledger entries.', Comment = '%1 = settlement entry number';
        SettlementAccountsMustDifferErr: Label 'The corporate card bank account and payment bank account must be different.';
        SettlementAmountMustBePositiveErr: Label 'The settlement amount must be greater than zero.';
        SettlementTotalMismatchErr: Label 'The settlement amount %1 does not equal the included statement total %2.', Comment = '%1 = settlement amount, %2 = statement total';
        StatementChangedErr: Label 'Statement %1 has changed since it was added to the settlement.', Comment = '%1 = statement number';
        StatementStatusNotEligibleErr: Label 'Statement %1 must be validated or require reconciliation. Current status: %2.', Comment = '%1 = statement number, %2 = statement status';
        SettlementReversedReasonTxt: Label 'Settlement %1 was reversed: %2', Comment = '%1 = settlement number, %2 = reversal reason';
}
