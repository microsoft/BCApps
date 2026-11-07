// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

codeunit 121 "Calc. Running Vend. Balance"
{
    InherentPermissions = X;

    var
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
        ClientTypeManagement: Codeunit System.Environment."Client Type Management";
        EntryValuesLCY: Dictionary of [Integer, Decimal];

    procedure GetVendorBalanceLCY(var VendorLedgerEntry: Record "Vendor Ledger Entry"): Decimal
    var
        RunningBalanceLCY: Decimal;
    begin
        CalcVendorBalance(VendorLedgerEntry, RunningBalanceLCY);
        exit(RunningBalanceLCY);
    end;

    local procedure CalcVendorBalance(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var RunningBalanceLCY: Decimal)
    var
        BalanceLCY: Decimal;
    begin
        if ClientTypeManagement.GetCurrentClientType() in [ClientType::OData, ClientType::ODataV4] then
            exit;
        if EntryValuesLCY.Get(VendorLedgerEntry."Entry No.", RunningBalanceLCY) then
            exit;
        RunningBalanceLCY := 0;
        VendorLedgerEntry2.SetLoadFields("Entry No.", "Amount (LCY)");
        VendorLedgerEntry2.SetAutoCalcFields("Amount (LCY)");
        VendorLedgerEntry2.SetRange("Vendor No.", VendorLedgerEntry."Vendor No.");
        VendorLedgerEntry2.SetCurrentKey("Vendor No.", "Posting Date", "Entry No.");
        if VendorLedgerEntry2.FindSet() then
            repeat
                BalanceLCY += VendorLedgerEntry2."Amount (LCY)";
                if VendorLedgerEntry2."Entry No." = VendorLedgerEntry."Entry No." then
                    RunningBalanceLCY := BalanceLCY;
                if not EntryValuesLCY.ContainsKey(VendorLedgerEntry2."Entry No.") then
                    EntryValuesLCY.Add(VendorLedgerEntry2."Entry No.", BalanceLCY);
            until VendorLedgerEntry2.Next() = 0;
    end;
}
