// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AllocationAccount;

using Microsoft.Bank.Ledger;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Foundation.Period;

codeunit 2670 "Variable Allocation Mgt."
{
    var
        NoAccountingPeriodDefinedErr: Label 'The next accounting period for workdate %1 is not defined.\Verify the accounting period setup.', Comment = '%1 - Represents the date.';
        PreviousYearIsNotDefinedErr: Label 'Previous year is not defined in accounting period.';

    internal procedure CalculateAmountDistributions(var AllocationAccount: Record "Allocation Account"; AmountToDistribute: Decimal; var AmountDistributions: Dictionary of [Guid, Decimal]; var ShareDistributions: Dictionary of [Guid, Decimal]; PostingDate: Date; CurrencyCode: Code[10])
    var
        AllocationAccountMgt: Codeunit "Allocation Account Mgt.";
        AccountSystemID: Guid;
        AccountBalance: Decimal;
        TotalBalance: Decimal;
        AmountDistribution: Decimal;
        TotalDistributedAmount: Decimal;
        FixedShareDistributions: Dictionary of [Guid, Decimal];
        AmountRoundingPrecision: Decimal;
    begin
        CalculateVariableBalance(AllocationAccount, ShareDistributions, TotalBalance, PostingDate);
        FixBalances(ShareDistributions, FixedShareDistributions, TotalBalance);

        AmountRoundingPrecision := AllocationAccountMgt.GetCurrencyRoundingPrecision(CurrencyCode);
        foreach AccountSystemID in FixedShareDistributions.Keys() do begin
            FixedShareDistributions.Get(AccountSystemID, AccountBalance);
            if TotalBalance <> 0 then
                AmountDistribution := Round(AmountToDistribute * AccountBalance / TotalBalance, AmountRoundingPrecision);
            AmountDistributions.Add(AccountSystemID, AmountDistribution);
            TotalDistributedAmount += AmountDistribution;
        end;

        if TotalDistributedAmount = AmountToDistribute then
            exit;

        foreach AccountSystemID in AmountDistributions.Keys() do begin
            AmountDistributions.Get(AccountSystemID, AccountBalance);
            if AccountBalance <> 0 then begin
                AccountBalance += AmountToDistribute - TotalDistributedAmount;
                AmountDistributions.Set(AccountSystemID, AccountBalance);
                exit;
            end;
        end;
    end;

    internal procedure FixBalances(var ShareDistributions: Dictionary of [Guid, Decimal]; var FixedDistributions: Dictionary of [Guid, Decimal]; var TotalBalance: Decimal)
    var
        AmountDistribution: Decimal;
        AccountSystemID: Guid;
        AllZeros: Boolean;
    begin
        AllZeros := true;

        foreach AccountSystemID in ShareDistributions.Keys() do begin
            ShareDistributions.Get(AccountSystemID, AmountDistribution);
            if AmountDistribution <> 0 then
                AllZeros := false;
        end;

        if AllZeros then begin
            foreach AccountSystemID in ShareDistributions.Keys() do begin
                FixedDistributions.Add(AccountSystemID, 100);
                TotalBalance += 100;
            end;
            exit;
        end;

        foreach AccountSystemID in ShareDistributions.Keys() do begin
            ShareDistributions.Get(AccountSystemID, AmountDistribution);
            FixedDistributions.Add(AccountSystemID, AmountDistribution);
        end;
        exit;
    end;

    internal procedure CalculateVariableBalance(var AllocationAccount: Record "Allocation Account"; var ShareDistributions: Dictionary of [Guid, Decimal]; var TotalBalance: Decimal; PostingDate: Date)
    var
        AllocAccountDistribution: Record "Alloc. Account Distribution";
        AccountBalance: Decimal;
        StartDate: Date;
        EndDate: Date;
    begin
        Clear(TotalBalance);
        Clear(ShareDistributions);
        AllocAccountDistribution.SetRange("Allocation Account No.", AllocationAccount."No.");
        if AllocAccountDistribution.IsEmpty() then
            exit;

        if AllocAccountDistribution.FindSet() then
            repeat
                CalculateDateFilterForDistributionAccount(AllocAccountDistribution, StartDate, EndDate, PostingDate);
                GetAccountBalance(AllocAccountDistribution, StartDate, EndDate, AccountBalance, ShareDistributions, TotalBalance);
                ShareDistributions.Add(AllocAccountDistribution.SystemId, AccountBalance);
                TotalBalance += AccountBalance;
            until AllocAccountDistribution.Next() = 0;
    end;

    internal procedure GetAccountBalance(var AllocAccountDistribution: Record "Alloc. Account Distribution"; StartDate: Date; EndDate: Date; var AccountBalance: Decimal; var ShareDistributions: Dictionary of [Guid, Decimal]; TotalBalance: Decimal)
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        GLEntry: Record "G/L Entry";
        Handled: Boolean;
    begin
        OnGetAccountBalance(AllocAccountDistribution, StartDate, EndDate, AccountBalance, ShareDistributions, TotalBalance, Handled);
        if Handled then
            exit;

        case AllocAccountDistribution."Breakdown Account Type" of
            AllocAccountDistribution."Breakdown Account Type"::"Bank Account":
                begin
                    BankAccountLedgerEntry.SetRange("Posting Date", StartDate, EndDate);
                    BankAccountLedgerEntry.SetRange("Bank Account No.", AllocAccountDistribution."Breakdown Account Number");
                    if AllocAccountDistribution."Dimension 1 Filter" <> '' then
                        BankAccountLedgerEntry.SetFilter("Global Dimension 1 Code", AllocAccountDistribution."Dimension 1 Filter");

                    if AllocAccountDistribution."Dimension 2 Filter" <> '' then
                        BankAccountLedgerEntry.SetFilter("Global Dimension 2 Code", AllocAccountDistribution."Dimension 2 Filter");

                    if AllocAccountDistribution."Dimension 3 Filter" <> '' then
                        BankAccountLedgerEntry.SetFilter("Shortcut Dimension 3 Code", AllocAccountDistribution."Dimension 3 Filter");

                    if AllocAccountDistribution."Dimension 4 Filter" <> '' then
                        BankAccountLedgerEntry.SetFilter("Shortcut Dimension 4 Code", AllocAccountDistribution."Dimension 4 Filter");

                    if AllocAccountDistribution."Dimension 5 Filter" <> '' then
                        BankAccountLedgerEntry.SetFilter("Shortcut Dimension 5 Code", AllocAccountDistribution."Dimension 5 Filter");

                    if AllocAccountDistribution."Dimension 6 Filter" <> '' then
                        BankAccountLedgerEntry.SetFilter("Shortcut Dimension 6 Code", AllocAccountDistribution."Dimension 6 Filter");

                    if AllocAccountDistribution."Dimension 7 Filter" <> '' then
                        BankAccountLedgerEntry.SetFilter("Shortcut Dimension 7 Code", AllocAccountDistribution."Dimension 7 Filter");

                    if AllocAccountDistribution."Dimension 8 Filter" <> '' then
                        BankAccountLedgerEntry.SetFilter("Shortcut Dimension 8 Code", AllocAccountDistribution."Dimension 8 Filter");

                    BankAccountLedgerEntry.ReadIsolation := IsolationLevel::ReadCommitted;
                    BankAccountLedgerEntry.CalcSums("Amount (LCY)");
                    AccountBalance := BankAccountLedgerEntry."Amount (LCY)";
                end;
            AllocAccountDistribution."Breakdown Account Type"::"G/L Account":
                begin
                    GLEntry.SetRange("Posting Date", StartDate, EndDate);
                    GLEntry.SetRange("G/L Account No.", AllocAccountDistribution."Breakdown Account Number");
                    if AllocAccountDistribution."Business Unit Code Filter" <> '' then
                        GLEntry.SetFilter("Business Unit Code", AllocAccountDistribution."Business Unit Code Filter");

                    if AllocAccountDistribution."Dimension 1 Filter" <> '' then
                        GLEntry.SetFilter("Global Dimension 1 Code", AllocAccountDistribution."Dimension 1 Filter");

                    if AllocAccountDistribution."Dimension 2 Filter" <> '' then
                        GLEntry.SetFilter("Global Dimension 2 Code", AllocAccountDistribution."Dimension 2 Filter");

                    if AllocAccountDistribution."Dimension 3 Filter" <> '' then
                        GLEntry.SetFilter("Shortcut Dimension 3 Code", AllocAccountDistribution."Dimension 3 Filter");

                    if AllocAccountDistribution."Dimension 4 Filter" <> '' then
                        GLEntry.SetFilter("Shortcut Dimension 4 Code", AllocAccountDistribution."Dimension 4 Filter");

                    if AllocAccountDistribution."Dimension 5 Filter" <> '' then
                        GLEntry.SetFilter("Shortcut Dimension 5 Code", AllocAccountDistribution."Dimension 5 Filter");

                    if AllocAccountDistribution."Dimension 6 Filter" <> '' then
                        GLEntry.SetFilter("Shortcut Dimension 6 Code", AllocAccountDistribution."Dimension 6 Filter");

                    if AllocAccountDistribution."Dimension 7 Filter" <> '' then
                        GLEntry.SetFilter("Shortcut Dimension 7 Code", AllocAccountDistribution."Dimension 7 Filter");

                    if AllocAccountDistribution."Dimension 8 Filter" <> '' then
                        GLEntry.SetFilter("Shortcut Dimension 8 Code", AllocAccountDistribution."Dimension 8 Filter");

                    GLEntry.ReadIsolation := IsolationLevel::ReadCommitted;
                    GLEntry.CalcSums(Amount);
                    AccountBalance := GLEntry.Amount;
                end;
        end;
    end;

    internal procedure CalculateDateFilterForDistributionAccount(AllocAccountDistribution: Record "Alloc. Account Distribution"; var StartDate: Date; var EndDate: Date; PostingDate: Date)
    var
        AccountingPeriod: Record "Accounting Period";
        PeriodStart: Date;
        NextPeriodStart: Date;
        LastPeriodStart: Date;
        LastYearPeriodStart: Date;
        LastYearNextPeriodStart: Date;
        YearStart: Date;
        NextYearStart: Date;
        LastYearStart: Date;
    begin
        if AllocAccountDistribution."Calculation Period" = AllocAccountDistribution."Calculation Period"::"Balance at Date" then begin
            StartDate := 0D;
            EndDate := PostingDate;
            exit;
        end;

        case AllocAccountDistribution."Calculation Period" of
            AllocAccountDistribution."Calculation Period"::Week:
                begin
                    StartDate := CalcDate('<-CW>', PostingDate);
                    EndDate := CalcDate('<CW>', PostingDate);
                    exit;
                end;
            AllocAccountDistribution."Calculation Period"::"Last Week":
                begin
                    StartDate := CalcDate('<-CW-1W>', PostingDate);
                    EndDate := CalcDate('<CW-1W>', PostingDate);
                    exit;
                end;
            AllocAccountDistribution."Calculation Period"::Month:
                begin
                    StartDate := CalcDate('<-CM>', PostingDate);
                    EndDate := CalcDate('<CM>', PostingDate);
                    exit;
                end;
            AllocAccountDistribution."Calculation Period"::"Last Month":
                begin
                    StartDate := CalcDate('<-CM-1M>', PostingDate);
                    EndDate := CalcDate('<CM>', StartDate);
                    exit;
                end;
            AllocAccountDistribution."Calculation Period"::Quarter:
                begin
                    StartDate := CalcDate('<-CQ>', PostingDate);
                    EndDate := CalcDate('<CQ>', PostingDate);
                    exit;
                end;
            AllocAccountDistribution."Calculation Period"::"Last Quarter":
                begin
                    StartDate := CalcDate('<-CQ-1Q>', PostingDate);
                    EndDate := CalcDate('<CQ>', StartDate);
                    exit;
                end;
            AllocAccountDistribution."Calculation Period"::"Month of Last Year":
                begin
                    StartDate := CalcDate('<-CM-1Y>', PostingDate);
                    EndDate := CalcDate('<CM-1Y>', PostingDate);
                    exit;
                end;
            AllocAccountDistribution."Calculation Period"::Year:
                begin
                    StartDate := CalcDate('<-CY>', PostingDate);
                    EndDate := CalcDate('<CY>', PostingDate);
                    exit;
                end;
            AllocAccountDistribution."Calculation Period"::"Last Year":
                begin
                    StartDate := CalcDate('<-CY-1Y>', PostingDate);
                    EndDate := CalcDate('<CY-1Y>', PostingDate);
                    exit;
                end;
        end;

        AccountingPeriod.Reset();
        StartDate := 0D;
        EndDate := DMY2Date(31, 12, 9999);

        if AccountingPeriod.IsEmpty() then
            exit;

        AccountingPeriod.SetFilter("Starting Date", '>%1', PostingDate);
        if not AccountingPeriod.FindFirst() then
            Error(NoAccountingPeriodDefinedErr, PostingDate);

        NextPeriodStart := AccountingPeriod."Starting Date";
        AccountingPeriod.SetRange("Starting Date");

        AccountingPeriod.Next(-1);
        PeriodStart := AccountingPeriod."Starting Date";

        AccountingPeriod.Next(-1);
        LastPeriodStart := AccountingPeriod."Starting Date";

        case AllocAccountDistribution."Calculation Period" of
            AllocAccountDistribution."Calculation Period"::Period:
                begin
                    StartDate := PeriodStart;
                    EndDate := NextPeriodStart - 1;
                    exit;
                end;
            AllocAccountDistribution."Calculation Period"::"Last Period":
                begin
                    StartDate := LastPeriodStart;
                    EndDate := PeriodStart - 1;
                    exit;
                end;
        end;

        AccountingPeriod.SetFilter("Starting Date", '>%1', CalcDate('<-1Y>', PostingDate));
        AccountingPeriod.FindFirst();
        LastYearNextPeriodStart := AccountingPeriod."Starting Date";
        AccountingPeriod.SetRange("Starting Date");

        if AccountingPeriod.Next(-1) = 0 then
            if AllocAccountDistribution."Calculation Period" in
               [AllocAccountDistribution."Calculation Period"::"Period of Last Year", AllocAccountDistribution."Calculation Period"::"Last Fiscal Year"]
            then
                Error(PreviousYearIsNotDefinedErr);

        LastYearPeriodStart := AccountingPeriod."Starting Date";

        AccountingPeriod.SetRange("New Fiscal Year", true);
        AccountingPeriod.SetFilter("Starting Date", '>%1', PostingDate);
        AccountingPeriod.Find('-');
        NextYearStart := AccountingPeriod."Starting Date";
        AccountingPeriod.SetRange("Starting Date");

        AccountingPeriod.Next(-1);
        YearStart := AccountingPeriod."Starting Date";

        if AccountingPeriod.Next(-1) = 0 then
            if AllocAccountDistribution."Calculation Period" in
               [AllocAccountDistribution."Calculation Period"::"Period of Last Year", AllocAccountDistribution."Calculation Period"::"Last Fiscal Year"]
            then
                Error(PreviousYearIsNotDefinedErr);
        LastYearStart := AccountingPeriod."Starting Date";

        case AllocAccountDistribution."Calculation Period" of
            AllocAccountDistribution."Calculation Period"::"Period of Last Year":
                begin
                    StartDate := LastYearPeriodStart;
                    EndDate := LastYearNextPeriodStart - 1;
                end;
            AllocAccountDistribution."Calculation Period"::"Fiscal Year":
                begin
                    StartDate := YearStart;
                    EndDate := NextYearStart - 1;
                end;
            AllocAccountDistribution."Calculation Period"::"Last Fiscal Year":
                begin
                    StartDate := LastYearStart;
                    EndDate := YearStart - 1;
                end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetAccountBalance(var AllocAccountDistribution: Record "Alloc. Account Distribution"; StartDate: Date; EndDate: Date; var AccountBalance: Decimal; var ShareDistributions: Dictionary of [Guid, Decimal]; var TotalBalance: Decimal; var Handled: Boolean);
    begin
    end;
}
