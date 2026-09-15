// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Ledger;

codeunit 124 "Calc. Running Inv. Balance"
{
    InherentPermissions = X;

    var
        ItemLedgerEntry2: Record "Item Ledger Entry";
        ClientTypeManagement: Codeunit System.Environment."Client Type Management";
        DayTotals: Dictionary of [Date, Decimal];
        DayTotalsLoc: Dictionary of [Date, Decimal];
        EntryValues: Dictionary of [Integer, Decimal];
        EntryValuesLoc: Dictionary of [Integer, Decimal];
        PrevAccNo: Code[20];
        PrevLocation: Code[20];

    procedure GetItemBalance(var ItemLedgerEntry: Record "Item Ledger Entry"): Decimal
    var
        RunningBalance: Decimal;
    begin
        CalcItemBalance(ItemLedgerEntry, false, Daytotals, EntryValues, RunningBalance);
        exit(RunningBalance);
    end;

    procedure GetItemBalanceLoc(var ItemLedgerEntry: Record "Item Ledger Entry"): Decimal
    var
        RunningBalance: Decimal;
    begin
        CalcItemBalance(ItemLedgerEntry, true, DaytotalsLoc, EntryValuesLoc, RunningBalance);
        exit(RunningBalance);
    end;

    local procedure CalcItemBalance(var ItemLedgerEntry: Record "Item Ledger Entry"; PerLocation: Boolean; var Daytotals2: Dictionary of [Date, Decimal]; EntryValues2: Dictionary of [Integer, Decimal]; var RunningBalance: Decimal)
    var
        DateTotal: Decimal;
    begin
        if ClientTypeManagement.GetCurrentClientType() in [ClientType::OData, ClientType::ODataV4] then
            exit;
        if PrevAccNo <> ItemLedgerEntry."Item No." then
            Clear(DayTotals2);
        if PerLocation and (PrevLocation <> ItemLedgerEntry."Location code") then begin
            Clear(DayTotals2);
            PrevLocation := ItemLedgerEntry."Location Code";
        end;
        PrevAccNo := ItemLedgerEntry."Item No.";

        if EntryValues2.Get(ItemLedgerEntry."Entry No.", RunningBalance) then
            exit;

        ItemLedgerEntry2.Reset();
        ItemLedgerEntry2.SetLoadFields("Entry No.", "Item No.", "Posting Date", Quantity);
        ItemLedgerEntry2.SetRange("Item No.", ItemLedgerEntry."Item No.");
        if PerLocation then
            ItemLedgerEntry2.SetRange("Location Code", ItemLedgerEntry."Location Code")
        else
            ItemLedgerEntry2.SetRange("Location Code");
        if not DayTotals2.Get(ItemLedgerEntry."Posting Date", DateTotal) then begin
            ItemLedgerEntry2.SetFilter("Posting Date", '<=%1', ItemLedgerEntry."Posting Date");
            ItemLedgerEntry2.CalcSums(Quantity);
            DateTotal := ItemLedgerEntry2.Quantity;
            DayTotals2.Add(ItemLedgerEntry."Posting Date", DateTotal);
        end;
        RunningBalance := DateTotal;
        ItemLedgerEntry2.SetRange("Posting Date", ItemLedgerEntry."Posting Date");
        ItemLedgerEntry2.SetCurrentKey("Entry No.");
        ItemLedgerEntry2.Ascending(false);
        if ItemLedgerEntry2.FindSet() then
            repeat
                if ItemLedgerEntry2."Entry No." = ItemLedgerEntry."Entry No." then
                    RunningBalance := DateTotal;
                if not EntryValues2.ContainsKey(ItemLedgerEntry2."Entry No.") then
                    EntryValues2.Add(ItemLedgerEntry2."Entry No.", DateTotal);
                DateTotal -= ItemLedgerEntry2.Quantity;
            until ItemLedgerEntry2.Next() = 0;
    end;
}
