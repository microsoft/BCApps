// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Ledger;

/// <summary>
/// Calculates running account balances for bank account ledger entries with optimized caching.
/// Provides efficient balance calculations for both local and foreign currency amounts by maintaining
/// daily totals and entry-specific balance caches to avoid repetitive database queries.
/// </summary>
codeunit 105 "Calc. Running Acc. Balance"
{
    InherentPermissions = X;

    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        BankAccountLedgerEntry2: Record "Bank Account Ledger Entry";
        ClientTypeManagement: Codeunit System.Environment."Client Type Management";
        DayTotals: Dictionary of [Date, Decimal];
        DayTotalsLCY: Dictionary of [Date, Decimal];
        EntryValues: Dictionary of [Integer, Decimal];
        EntryValuesLCY: Dictionary of [Integer, Decimal];
        PrevAccNo: Code[20];

    /// <summary>
    /// Calculates the running balance for a bank account ledger entry in the original currency.
    /// Uses cached daily totals and entry-specific values to optimize performance for repeated calls.
    /// </summary>
    /// <param name="BankAccountLedgerEntry">Bank account ledger entry to calculate running balance for.</param>
    /// <returns>Running balance in the original currency at the time of the entry.</returns>
    procedure GetBankAccBalance(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"): Decimal
    var
        RunningBalance: Decimal;
        RunningBalanceLCY: Decimal;
    begin
        CalcBankAccBalance(BankAccountLedgerEntry, RunningBalance, RunningBalanceLCY);
        exit(RunningBalance);
    end;

    /// <summary>
    /// Calculates the running balance for a bank account ledger entry in local currency (LCY).
    /// Uses cached daily totals and entry-specific values to optimize performance for repeated calls.
    /// </summary>
    /// <param name="BankAccountLedgerEntry">Bank account ledger entry to calculate running balance for.</param>
    /// <returns>Running balance in local currency (LCY) at the time of the entry.</returns>
    procedure GetBankAccBalanceLCY(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"): Decimal
    var
        RunningBalance: Decimal;
        RunningBalanceLCY: Decimal;
    begin
        CalcBankAccBalance(BankAccountLedgerEntry, RunningBalance, RunningBalanceLCY);
        exit(RunningBalanceLCY);
    end;

    local procedure CalcBankAccBalance(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; var RunningBalance: Decimal; var RunningBalanceLCY: Decimal)
    var
        DateTotal: Decimal;
        DateTotalLCY: Decimal;
    begin
        if ClientTypeManagement.GetCurrentClientType() in [ClientType::OData, ClientType::ODataV4] then
            exit;
        if (PrevAccNo <> '') and (PrevAccNo <> BankAccountLedgerEntry."Bank Account No.") then begin
            Clear(DayTotals);
            Clear(DayTotalsLCY);
        end;
        PrevAccNo := BankAccountLedgerEntry."Bank Account No.";

        if EntryValues.Get(BankAccountLedgerEntry."Entry No.", RunningBalance) and EntryValuesLCY.Get(BankAccountLedgerEntry."Entry No.", RunningBalanceLCY) then
            exit;

        BankAccountLedgerEntry2.Reset();
        BankAccountLedgerEntry2.SetLoadFields("Entry No.", "Bank Account No.", "Posting Date", Amount, "Amount (LCY)");
        BankAccountLedgerEntry2.SetRange("Bank Account No.", BankAccountLedgerEntry."Bank Account No.");
        if not (DayTotals.Get(BankAccountLedgerEntry."Posting Date", DateTotal) and DayTotalsLCY.Get(BankAccountLedgerEntry."Posting Date", DateTotalLCY)) then begin
            BankAccountLedgerEntry2.SetFilter("Posting Date", '<=%1', BankAccountLedgerEntry."Posting Date");
            BankAccountLedgerEntry2.CalcSums(Amount, "Amount (LCY)");
            DateTotal := BankAccountLedgerEntry2.Amount;
            DateTotalLCY := BankAccountLedgerEntry2."Amount (LCY)";
            DayTotals.Add(BankAccountLedgerEntry."Posting Date", DateTotal);
            DayTotalsLCY.Add(BankAccountLedgerEntry."Posting Date", DateTotalLCY);
        end;
        RunningBalance := DateTotal;
        RunningBalanceLCY := DateTotalLCY;
        BankAccountLedgerEntry2.SetRange("Posting Date", BankAccountLedgerEntry."Posting Date");
        BankAccountLedgerEntry2.SetCurrentKey("Entry No.");
        BankAccountLedgerEntry2.Ascending(false);
        if BankAccountLedgerEntry2.FindSet() then
            repeat
                if BankAccountLedgerEntry2."Entry No." = BankAccountLedgerEntry."Entry No." then begin
                    RunningBalance := DateTotal;
                    RunningBalanceLCY := DateTotalLCY;
                end;
                if not EntryValues.ContainsKey(BankAccountLedgerEntry2."Entry No.") then
                    EntryValues.Add(BankAccountLedgerEntry2."Entry No.", DateTotal);
                if not EntryValuesLCY.ContainsKey(BankAccountLedgerEntry2."Entry No.") then
                    EntryValuesLCY.Add(BankAccountLedgerEntry2."Entry No.", DateTotalLCY);
                DateTotal -= BankAccountLedgerEntry2.Amount;
                DateTotalLCY -= BankAccountLedgerEntry2."Amount (LCY)";
            until BankAccountLedgerEntry2.Next() = 0;
    end;
}
