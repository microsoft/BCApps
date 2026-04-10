// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Ledger;
using Microsoft.Bank.Statement;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;

/// <summary>
/// Provides validation and testing functions for bank account reconciliation procedures.
/// Validates reconciliation balance calculations and data integrity before posting.
/// </summary>
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

    procedure TotalOutstandingBankTransactions(BankAccReconciliation: Record "Bank Acc. Reconciliation"): Decimal
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        BankAccountLedgerEntry.SetRange("Check Ledger Entries", 0);
        exit(GetTotalOutstanding(BankAccReconciliation, BankAccountLedgerEntry));
    end;

    procedure TotalOutstandingPayments(BankAccReconciliation: Record "Bank Acc. Reconciliation"): Decimal
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        BankAccountLedgerEntry.SetFilter("Check Ledger Entries", '<> %1', 0);
        exit(GetTotalOutstanding(BankAccReconciliation, BankAccountLedgerEntry));
    end;

    /// <summary>
    /// Gets the total outstanding amount for the given Bank Acc. Reconciliation, it considers the filters applied on the Bank Account Ledger Entry record passed as parameter (that are not overridden).
    /// The calculation avoids looping through the closed Bank Account Ledger Entries via sums and set operations, this is important for performance and it should be maintained like that since it's used at posting.
    /// </summary>
    /// <param name="BankAccReconciliation">The bank account reconciliation</param>
    /// <param name="BankAccountLedgerEntry">Record with the filters to consider throughout the calculation, several get overriden currently it's only meant to respect the "Check Ledger Entries" filter</param>
    /// <returns></returns>
    local procedure GetTotalOutstanding(BankAccReconciliation: Record "Bank Acc. Reconciliation"; var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"): Decimal
    var
        GeneralBankAccountLedgerEntryFilters: Record "Bank Account Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        x1, x2, x3, x4, x5, x6, x7, Total : Decimal;
        DocNo: Text;
    begin
        // Common filters for all cases
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccountLedgerEntry.SetRange(Reversed, false);
        if BankAccReconciliation."Statement Date" <> 0D then
            BankAccountLedgerEntry.SetRange("Posting Date", 0D, BankAccReconciliation."Statement Date");

        GeneralBankAccountLedgerEntryFilters.CopyFilters(BankAccountLedgerEntry);
        // Case 1: When Statement No. = ''
        // When we have Statement No = '' it means those BLE that are not matched to any statement yet.
        // This means either they are open and not matched to any ongoing bank rec.
        // We add all BLE that are considered open, or that have been closed after the statement date. The BLEs to add are those that satisfy:
        // 
        //  Statement Status <> Closed
        //  AND (Open = true // case 1.a - this avoids considering corrupted entries with Open = false and Closed at Date = 0D (found in some NA environments)
        //      OR Closed at Date > Statement Date of the bank rec. // case 1.b
        //  )
        //  Note for case 1.b: In principle the precondition Statement No = '' implies Closed at Date = 0D, but in case we have a data inconsistency with:
        //  - Statement No = ''
        //  - Open = false
        //  - Closed at Date > 0D
        //  We will consider it as closed, but for some reason the Statement No. is blank. We will consider the entry only if it was closed after the statement date (since it is considered open at the time of the statement date).
        //
        // We calculate amount for case 1:
        // To calculate possible overlaps between (case 1.a) and (case 1.b) we calculate the intersections and subtract them from the union to avoid double counting

        // General filters for case 1:
        BankAccountLedgerEntry.SetRange("Statement No.", '');
        BankAccountLedgerEntry.SetFilter("Statement Status", '%1 | %2 | %3', BankAccountLedgerEntry."Statement Status"::Open, BankAccountLedgerEntry."Statement Status"::"Bank Acc. Entry Applied", BankAccountLedgerEntry."Statement Status"::"Check Entry Applied");

        // total for case 1.a
        ClearOpenFilters(BankAccountLedgerEntry);
        BankAccountLedgerEntry.SetRange(Open, true);
        BankAccountLedgerEntry.CalcSums(Amount);
        x1 := BankAccountLedgerEntry.Amount;

        // total for case 1.b
        ClearOpenFilters(BankAccountLedgerEntry);
        BankAccountLedgerEntry.SetFilter("Closed at Date", '> %1', BankAccReconciliation."Statement Date");
        BankAccountLedgerEntry.CalcSums(Amount);
        x2 := BankAccountLedgerEntry.Amount;

        // total for (case 1.a) intersection (case 1.b), ideally should be 0, but in case of data inconsistencies we consider it
        ClearOpenFilters(BankAccountLedgerEntry);
        BankAccountLedgerEntry.SetRange(Open, true);
        BankAccountLedgerEntry.SetFilter("Closed at Date", '> %1', BankAccReconciliation."Statement Date");
        BankAccountLedgerEntry.CalcSums(Amount);
        x3 := BankAccountLedgerEntry.Amount;

        // total for case 1
        x4 := x1 + x2 - x3;

        // Case 2: Statement no. <> '' and Statement no. <> BankAccReconciliation."Statement No."
        // These are BLEs that are matched to other statements or to ongoing bank recs (not the current one).
        //
        // Case 2.a: BLEs with Closed at Date <> 0D
        // We will consider as outstanding if they were closed after the statement date of the current bank rec.
        // So we will consider those BLEs that satisfy 
        //
        // Closed at Date > Statement Date of the bank rec.
        //      (disregarding Open, or Statement Status, since we consider them closed when the "Closed At" date is specified):

        // General filters for case 2:
        BankAccountLedgerEntry.SetFilter("Statement No.", '<> %1 & <> %2', BankAccReconciliation."Statement No.", '');
        BankAccountLedgerEntry.SetRange("Statement Status");

        // total for case 2.a
        ClearOpenFilters(BankAccountLedgerEntry);
        BankAccountLedgerEntry.SetFilter("Closed at Date", '> %1', BankAccReconciliation."Statement Date");
        BankAccountLedgerEntry.CalcSums(Amount);
        x5 := BankAccountLedgerEntry.Amount;

        // Case 2.b: BLEs that are open (Closed at Date = 0D)
        // We will consider as outstanding in this case BLEs that are in different ongoing bank recs (not yet closed) as long as they are matched in an statement with a date after the statement date of the current bank rec.
        // If there is any of the BLE fields that signal that the BLE is not open (e.g., Statement Status = Closed or Open = false) we will disregard the BLE.
        // Note that (case 2.a) and (case 2.b) are disjoint

        // total for case 2.b
        ClearOpenFilters(BankAccountLedgerEntry);
        BankAccountLedgerEntry.SetRange("Closed at Date", 0D);
        BankAccountLedgerEntry.SetRange(Open, true); // this also avoids considering corrupted entries with Open = false and Closed at Date = 0D (found in some NA environments)
        BankAccountLedgerEntry.SetFilter("Statement Status", '%1 | %2 | %3', BankAccountLedgerEntry."Statement Status"::Open, BankAccountLedgerEntry."Statement Status"::"Bank Acc. Entry Applied", BankAccountLedgerEntry."Statement Status"::"Check Entry Applied");
        BankAccountLedgerEntry.SetFilter("Statement Date", '>%1', BankAccReconciliation."Statement Date");
        BankAccountLedgerEntry.CalcSums(Amount);
        x6 := BankAccountLedgerEntry.Amount;

        // total for case 2
        x7 := x5 + x6;

        // Final total = case 1 + case 2 (disjoint cases)
        Total := x7 + x4;

        // Adjustments for Payment Application type
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
                        // We will just subtract the "Applied Amount" 
                        GeneralBankAccountLedgerEntryFilters.SetFilter("Document No.", DocNo);
                        if not GeneralBankAccountLedgerEntryFilters.IsEmpty() then
                            Total -= BankAccReconciliationLine."Applied Amount";
                    end;
                until BankAccReconciliationLine.Next() = 0;
        end;
        exit(Total);
    end;

    local procedure ClearOpenFilters(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry")
    begin
        BankAccountLedgerEntry.SetRange(Open);
        BankAccountLedgerEntry.SetRange("Closed at Date");
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

