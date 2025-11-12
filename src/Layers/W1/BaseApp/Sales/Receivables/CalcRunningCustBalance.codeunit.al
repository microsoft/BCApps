// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Receivables;

codeunit 120 "Calc. Running Cust. Balance"
{
    InherentPermissions = X;

    var
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        ClientTypeManagement: Codeunit System.Environment."Client Type Management";
        EntryValuesLCY: Dictionary of [Integer, Decimal];

    internal procedure GetCustomerBalanceLCY(var CustLedgerEntry: Record "Cust. Ledger Entry"): Decimal
    var
        RunningBalanceLCY: Decimal;
    begin
        CalcCustomerBalance(CustLedgerEntry, RunningBalanceLCY);
        exit(RunningBalanceLCY);
    end;

    local procedure CalcCustomerBalance(var CustLedgerEntry: Record "Cust. Ledger Entry"; var RunningBalanceLCY: Decimal)
    var
        BalanceLCY: Decimal;
    begin
        if ClientTypeManagement.GetCurrentClientType() in [ClientType::OData, ClientType::ODataV4] then
            exit;
        if EntryValuesLCY.Get(CustLedgerEntry."Entry No.", RunningBalanceLCY) then
            exit;
        RunningBalanceLCY := 0;
        CustLedgerEntry2.SetLoadFields("Entry No.", "Amount (LCY)");
        CustLedgerEntry2.SetAutoCalcFields("Amount (LCY)");
        CustLedgerEntry2.SetRange("Customer No.", CustLedgerEntry."Customer No.");
        CustLedgerEntry2.SetCurrentKey("Customer No.", "Posting Date", "Entry No.");
        if CustLedgerEntry2.FindSet() then
            repeat
                BalanceLCY += CustLedgerEntry2."Amount (LCY)";
                if CustLedgerEntry2."Entry No." = CustLedgerEntry."Entry No." then
                    RunningBalanceLCY := BalanceLCY;
                if not EntryValuesLCY.ContainsKey(CustLedgerEntry2."Entry No.") then
                    EntryValuesLCY.Add(CustLedgerEntry2."Entry No.", BalanceLCY);
            until CustLedgerEntry2.Next() = 0;
    end;
}
