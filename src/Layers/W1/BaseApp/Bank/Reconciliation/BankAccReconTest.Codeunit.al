// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Statement;
using Microsoft.Bank.Ledger;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;

codeunit 380 "Bank Acc. Recon. Test"
{

    trigger OnRun()
    begin
    end;

    procedure TotalPositiveDifference(BankAccReconciliation: Record "Bank Acc. Reconciliation"): Decimal
    begin
        case BankAccReconciliation."Statement Type" of
            BankAccReconciliation."Statement Type"::"Bank Reconciliation":
                exit(0);
            BankAccReconciliation."Statement Type"::"Payment Application":
                exit(BankAccReconciliation."Total Positive Adjustments");
        end;
    end;

    procedure TotalNegativeDifference(BankAccReconciliation: Record "Bank Acc. Reconciliation"): Decimal
    begin
        case BankAccReconciliation."Statement Type" of
            BankAccReconciliation."Statement Type"::"Bank Reconciliation":
                exit(0);
            BankAccReconciliation."Statement Type"::"Payment Application":
                exit(BankAccReconciliation."Total Negative Adjustments");
        end;
    end;

    procedure SetOutstandingFilters(BankAccReconciliation: Record "Bank Acc. Reconciliation"; var BankAccountLedgerEntry: Record "Bank Account Ledger Entry")
    begin
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccountLedgerEntry.SetRange(Reversed, false);
        if BankAccReconciliation."Statement Date" <> 0D then
            BankAccountLedgerEntry.SetRange("Posting Date", 0D, BankAccReconciliation."Statement Date");
        BankAccountLedgerEntry.SetFilter("Statement No.", '<> %1', BankAccReconciliation."Statement No.");
    end;

    local procedure TotalOfClosedEntriesWithNoClosedAtDate(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"): Decimal
    begin
        BankAccountLedgerEntry.SetRange("Closed at Date", 0D);
        BankAccountLedgerEntry.SetRange(Open, false);
        BankAccountLedgerEntry.CalcSums(Amount);
        exit(BankAccountLedgerEntry.Amount);
    end;

    procedure TotalOutstandingBankTransactions(BankAccReconciliation: Record "Bank Acc. Reconciliation") Total: Decimal
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        DocNo: Text;
    begin
        SetOutstandingFilters(BankAccReconciliation, BankAccountLedgerEntry);
        BankAccountLedgerEntry.SetRange("Check Ledger Entries", 0);
        if BankAccountLedgerEntry.IsEmpty() then
            exit;

        FilterOutstandingBankAccLedgerEntry(BankAccountLedgerEntry, BankAccReconciliation."Statement No.", BankAccReconciliation."Statement Date");
        BankAccountLedgerEntry.MarkedOnly(true);

        BankAccountLedgerEntry.CalcSums(Amount);
        Total := BankAccountLedgerEntry.Amount;
        Total -= TotalOfClosedEntriesWithNoClosedAtDate(BankAccountLedgerEntry);

        if BankAccReconciliation."Statement Type" = BankAccReconciliation."Statement Type"::"Payment Application" then begin
            // When the BankAccReconciliation is created from the Payment Reconciliation Journal:
            // we subtract the "Applied Amount" to Bank Ledger Entries with no CLE, since those are no longer outstanding.
            // These are the lines with "Account Type" "Bank Account", that are applied to some "Document No." (Lines of type Bank Account without Doc. No are bank to bank transfers, which are not outstanding)
            BankAccReconciliation.SetFiltersOnBankAccReconLineTable(BankAccReconciliation, BankAccReconciliationLine);
            BankAccReconciliationLine.SetRange("Account Type", BankAccReconciliationLine."Account Type"::"Bank Account");
            if BankAccReconciliationLine.FindSet() then
                repeat
                    DocNo := BankAccReconciliationLine.GetAppliedToDocumentNo('|');
                    if DocNo <> '' then begin
                        // We will just subtract the "Applied Amount" if there is no Check Ledger Entry
                        // associated to that BLE
                        BankAccountLedgerEntry.Reset();
                        BankAccountLedgerEntry.SetFilter("Document No.", DocNo);
                        BankAccountLedgerEntry.SetRange("Check Ledger Entries", 0);
                        if not BankAccountLedgerEntry.IsEmpty() then
                            Total -= BankAccReconciliationLine."Applied Amount";
                    end;
                until BankAccReconciliationLine.Next() = 0;
        end;
        exit(Total);
    end;

    local procedure FilterOutstandingBankAccLedgerEntry(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; StatementNo: Code[20]; StatementDate: Date)
    begin
        if BankAccountLedgerEntry.FindSet() then
            repeat
                if CheckBankAccountLedgerEntryFilters(BankAccountLedgerEntry, StatementNo, StatementDate) then
                    BankAccountLedgerEntry.Mark(true);
            until BankAccountLedgerEntry.Next() = 0;
    end;

    procedure CheckBankAccountLedgerEntryFilters(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; StatementNo: Code[20]; StatementDate: Date): Boolean
    begin
        if BankAccountLedgerEntry."Statement No." = '' then begin
            if CheckBankLedgerEntryIsOpen(BankAccountLedgerEntry, StatementDate) then
                exit(true);
        end else
            if CheckBankLedgerEntryOnStatement(BankAccountLedgerEntry, StatementDate) then
                exit(true);
        exit(false);
    end;

    local procedure CheckBankLedgerEntryOnStatement(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; StatementDate: Date): Boolean
    var
        BankAccountReconciliation: Record "Bank Acc. Reconciliation";
    begin
        // Check if the Bank Account Ledger Entry is closed on a later statement
        if BankAccountLedgerEntry."Closed at Date" > StatementDate then
            exit(true);

        if not BankAccountLedgerEntry.Open then
            exit(false);

        if BankAccountLedgerEntry."Statement Status" = BankAccountLedgerEntry."Statement Status"::Closed then
            exit(false);

        if not BankAccountReconciliation.Get(BankAccountReconciliation."Statement Type"::"Bank Reconciliation", BankAccountLedgerEntry."Bank Account No.", BankAccountLedgerEntry."Statement No.") then
            exit(false);

        exit(BankAccountReconciliation."Statement Date" > StatementDate);
    end;

    local procedure CheckBankLedgerEntryIsOpen(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; StatementDate: Date): Boolean
    begin
        //there are closed entries with "statement status" = closed but with blank statement no.
        if BankAccountLedgerEntry."Statement Status" = BankAccountLedgerEntry."Statement Status"::Closed then
            exit(false);
        if BankAccountLedgerEntry.Open then
            exit(true);
        if (BankAccountLedgerEntry."Closed at Date" = 0D) then
            exit(true);
        if BankAccountLedgerEntry."Closed at Date" > StatementDate then
            exit(true);
    end;

    procedure TotalOutstandingPayments(BankAccReconciliation: Record "Bank Acc. Reconciliation") Total: Decimal
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        DocNo: Text;
    begin
        SetOutstandingFilters(BankAccReconciliation, BankAccountLedgerEntry);
        BankAccountLedgerEntry.SetFilter("Check Ledger Entries", '<>0');
        if BankAccountLedgerEntry.IsEmpty() then
            exit;

        FilterOutstandingBankAccLedgerEntry(BankAccountLedgerEntry, BankAccReconciliation."Statement No.", BankAccReconciliation."Statement Date");
        BankAccountLedgerEntry.MarkedOnly(true);

        BankAccountLedgerEntry.CalcSums(Amount);
        Total := BankAccountLedgerEntry.Amount;

        Total -= TotalOfClosedEntriesWithNoClosedAtDate(BankAccountLedgerEntry);

        if BankAccReconciliation."Statement Type" = BankAccReconciliation."Statement Type"::"Payment Application" then begin
            // When the BankAccReconciliation is created from the Payment Reconciliation Journal:
            // we subtract the "Applied Amount" to Bank Ledger Entries with CLEs, since those are no longer outstanding.
            // These are the lines with "Account Type" "Bank Account", that are applied to some "Document No." (Lines of type Bank Account without Doc. No are bank to bank transfers, which are not outstanding)
            BankAccReconciliation.SetFiltersOnBankAccReconLineTable(BankAccReconciliation, BankAccReconciliationLine);
            BankAccReconciliationLine.SetRange("Account Type", BankAccReconciliationLine."Account Type"::"Bank Account");
            if BankAccReconciliationLine.FindSet() then
                repeat
                    DocNo := BankAccReconciliationLine.GetAppliedToDocumentNo('|');
                    if DocNo <> '' then begin
                        // We will just subtract the "Applied Amount" if there are Check Ledger Entry
                        // associated to that BLE
                        BankAccountLedgerEntry.Reset();
                        BankAccountLedgerEntry.SetFilter("Document No.", DocNo);
                        BankAccountLedgerEntry.SetFilter("Check Ledger Entries", '<>0');
                        if not BankAccountLedgerEntry.IsEmpty() then
                            Total -= BankAccReconciliationLine."Applied Amount";
                    end;
                until BankAccReconciliationLine.Next() = 0;
        end;
        exit(Total);
    end;

    local procedure SetGLAccountBalanceFilters(BankAccountPostingGroup: Record "Bank Account Posting Group"; StatementDate: Date; var GLEntry: Record "G/L Entry")
    begin
        GLEntry.SetRange("G/L Account No.", BankAccountPostingGroup."G/L Account No.");
        if (StatementDate <> 0D) then
            GLEntry.SetFilter("Posting Date", '<= %1', StatementDate);
    end;

    procedure GetGLAccountBalanceLCYForBankStatement(BankAccountStatement: Record "Bank Account Statement"): Decimal
    var
        BankAccount: Record "Bank Account";
        BankAccountPostingGroup: Record "Bank Account Posting Group";
        GLEntry: Record "G/L Entry";
    begin
        if not BankAccount.Get(BankAccountStatement."Bank Account No.") then
            exit(0);
        if not BankAccountPostingGroup.Get(BankAccount."Bank Acc. Posting Group") then
            exit(0);
        SetGLAccountBalanceFilters(BankAccountPostingGroup, BankAccountStatement."Statement Date", GLEntry);
        GLEntry.SetFilter(SystemCreatedAt, '< %1', BankAccountStatement.SystemCreatedAt);
        GLEntry.CalcSums(Amount);
        exit(GLEntry.Amount);
    end;

    procedure GetGLAccountBalanceLCY(BankAcc: Record "Bank Account"; BankAccPostingGroup: Record "Bank Account Posting Group"; StatementDate: Date): Decimal
    var
        GLAccount: Record "G/L Account";
        GLEntries: Record "G/L Entry";
    begin
        if BankAccPostingGroup."G/L Account No." = '' then
            exit(0);

        if not GLAccount.Get(BankAccPostingGroup."G/L Account No.") then
            exit(0);

        SetGLAccountBalanceFilters(BankAccPostingGroup, StatementDate, GLEntries);

        GLEntries.CalcSums(Amount);
        exit(GLEntries.Amount);
    end;

    procedure GetGLAccountBalance(TotalBalOnGLAccountLCY: Decimal; StatementDate: Date; CurrencyCode: Code[10]): Decimal
    var
        Currency: Record "Currency Exchange Rate";
        ExchangeRate: Decimal;
    begin
        ExchangeRate := Currency.ExchangeRate(StatementDate, CurrencyCode);
        exit(TotalBalOnGLAccountLCY * ExchangeRate);
    end;
}

