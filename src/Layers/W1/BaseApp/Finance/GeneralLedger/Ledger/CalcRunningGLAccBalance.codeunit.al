// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Ledger;

codeunit 122 "Calc. Running GL. Acc. Balance"
{
    InherentPermissions = X;

    var
        GLEntry2: Record "G/L Entry";
        ClientTypeManagement: Codeunit System.Environment."Client Type Management";
        DayTotals: Dictionary of [Date, Decimal];
        DayTotalsACY: Dictionary of [Date, Decimal];
        EntryValues: Dictionary of [Integer, Decimal];
        EntryValuesACY: Dictionary of [Integer, Decimal];
        PrevAccNo: Code[20];

    procedure GetGLAccBalance(var GLEntry: Record "G/L Entry"): Decimal
    var
        RunningBalance: Decimal;
        RunningBalanceACY: Decimal;
    begin
        CalcGLAccBalance(GLEntry, RunningBalance, RunningBalanceACY);
        exit(RunningBalance);
    end;

    procedure GetGLAccBalanceACY(var GLEntry: Record "G/L Entry"): Decimal
    var
        RunningBalance: Decimal;
        RunningBalanceACY: Decimal;
    begin
        CalcGLAccBalance(GLEntry, RunningBalance, RunningBalanceACY);
        exit(RunningBalanceACY);
    end;

    local procedure CalcGLAccBalance(var GLEntry: Record "G/L Entry"; var RunningBalance: Decimal; var RunningBalanceACY: Decimal)
    var
        DateTotal: Decimal;
        DateTotalACY: Decimal;
    begin
        if ClientTypeManagement.GetCurrentClientType() in [ClientType::OData, ClientType::ODataV4] then
            exit;
        if (PrevAccNo <> '') and (PrevAccNo <> GLEntry."G/L Account No.") then begin
            Clear(DayTotals);
            Clear(DayTotalsACY);
        end;
        PrevAccNo := GLEntry."G/L Account No.";

        if EntryValues.Get(GLEntry."Entry No.", RunningBalance) and EntryValuesACY.Get(GLEntry."Entry No.", RunningBalanceACY) then
            exit;

        GLEntry2.Reset();
        GLEntry2.SetLoadFields("Entry No.", "G/L Account No.", "Posting Date", Amount, "Additional-Currency Amount");
        GLEntry2.SetRange("G/L Account No.", GLEntry."G/L Account No.");
        if not (DayTotals.Get(GLEntry."Posting Date", DateTotal) and DayTotalsACY.Get(GLEntry."Posting Date", DateTotalACY)) then begin
            GLEntry2.SetFilter("Posting Date", '<=%1', GLEntry."Posting Date");
            GLEntry2.CalcSums(Amount, "Additional-Currency Amount");
            DateTotal := GLEntry2.Amount;
            DateTotalACY := GLEntry2."Additional-Currency Amount";
            DayTotals.Add(GLEntry."Posting Date", DateTotal);
            DayTotalsACY.Add(GLEntry."Posting Date", DateTotalACY);
        end;
        RunningBalance := DateTotal;
        RunningBalanceACY := DateTotalACY;
        GLEntry2.SetRange("Posting Date", GLEntry."Posting Date");
        GLEntry2.SetCurrentKey("Entry No.");
        GLEntry2.Ascending(false);
        if GLEntry2.FindSet() then
            repeat
                if GLEntry2."Entry No." = GLEntry."Entry No." then begin
                    RunningBalance := DateTotal;
                    RunningBalanceACY := DateTotalACY;
                end;
                if not EntryValues.ContainsKey(GLEntry2."Entry No.") then
                    EntryValues.Add(GLEntry2."Entry No.", DateTotal);
                if not EntryValuesACY.ContainsKey(GLEntry2."Entry No.") then
                    EntryValuesACY.Add(GLEntry2."Entry No.", DateTotalACY);
                DateTotal -= GLEntry2.Amount;
                DateTotalACY -= GLEntry2."Additional-Currency Amount";
            until GLEntry2.Next() = 0;
    end;
}
