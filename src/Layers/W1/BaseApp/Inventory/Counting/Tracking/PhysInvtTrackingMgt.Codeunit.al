// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.Tracking;

using Microsoft.Inventory.Counting.Document;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;

codeunit 5889 "Phys. Invt. Tracking Mgt."
{
    Permissions = TableData "Reservation Entry" = rimd,
                  TableData "Pstd. Phys. Invt. Tracking" = rimd;

    trigger OnRun()
    begin
    end;

    var
        CreateReservEntry: Codeunit "Create Reserv. Entry";

    procedure SuggestUseTrackingLines(Item: Record Item) Result: Boolean
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        if Item."Item Tracking Code" = '' then
            Result := false
        else begin
            ItemTrackingCode.Get(Item."Item Tracking Code");
            Result :=
                ItemTrackingCode."SN Specific Tracking" or
                ItemTrackingCode."SN Pos. Adjmt. Inb. Tracking" or
                ItemTrackingCode."SN Pos. Adjmt. Outb. Tracking" or
                ItemTrackingCode."SN Neg. Adjmt. Inb. Tracking" or
                ItemTrackingCode."SN Neg. Adjmt. Outb. Tracking" or
                ItemTrackingCode."Lot Specific Tracking" or
                ItemTrackingCode."Lot Pos. Adjmt. Inb. Tracking" or
                ItemTrackingCode."Lot Pos. Adjmt. Outb. Tracking" or
                ItemTrackingCode."Lot Neg. Adjmt. Inb. Tracking" or
                ItemTrackingCode."Lot Neg. Adjmt. Outb. Tracking" or
                ItemTrackingCode."Package Specific Tracking" or
                ItemTrackingCode."Package Pos. Inb. Tracking" or
                ItemTrackingCode."Package Pos. Outb. Tracking" or
                ItemTrackingCode."Package Neg. Inb. Tracking" or
                ItemTrackingCode."Package Neg. Outb. Tracking";
        end;
        OnAfterSuggestUseTrackingLines(Item, ItemTrackingCode, Result);
    end;

    procedure GetTrackingNosFromWhse(Item: Record Item) Result: Boolean
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        if Item."Item Tracking Code" = '' then
            Result := false
        else begin
            ItemTrackingCode.Get(Item."Item Tracking Code");
            Result := (ItemTrackingCode."SN Specific Tracking" and ItemTrackingCode."SN Warehouse Tracking") or
                      (ItemTrackingCode."Lot Specific Tracking" and ItemTrackingCode."Lot Warehouse Tracking") or
                      (ItemTrackingCode."Package Specific Tracking" and ItemTrackingCode."Package Warehouse Tracking");
        end;
        OnAfterGetTrackingNosFromWhse(Item, ItemTrackingCode, Result);
    end;

    procedure LocationIsBinMandatory(LocationCode: Code[20]): Boolean
    var
        Location: Record Location;
    begin
        if LocationCode = '' then
            exit(false);

        Location.Get(LocationCode);
        exit(Location."Bin Mandatory");
    end;

    procedure TransferResEntryToItemJnlLine(var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; var ItemJnlLine: Record "Item Journal Line"; Qty: Decimal; Positive: Boolean)
    var
        ReservEntry: Record "Reservation Entry";
    begin
        // Transfer all Reserve Entry, connected by a PhysInvtOrderLine, to an ItemJnlLine bevor posting the PhysInvtOrderLine

        if Qty = 0 then
            exit;

        ItemJnlLine.TestField("Item No.", PhysInvtOrderLine."Item No.");
        ItemJnlLine.TestField("Variant Code", PhysInvtOrderLine."Variant Code");
        ItemJnlLine.TestField("Location Code", PhysInvtOrderLine."Location Code");
        ItemJnlLine.TestField("Bin Code", PhysInvtOrderLine."Bin Code");

        ReservEntry.Reset();
        ReservEntry.SetSourceFilter(Database::"Phys. Invt. Order Line", 0, PhysInvtOrderLine."Document No.", PhysInvtOrderLine."Line No.", true);
        ReservEntry.SetSourceFilter('', 0);
        ReservEntry.SetRange(Positive, Positive);
        if ReservEntry.FindSet() then
            repeat
                ReservEntry.TestField("Reservation Status", ReservEntry."Reservation Status"::Prospect);
                ReservEntry.TestField("Item No.", PhysInvtOrderLine."Item No.");
                ReservEntry.TestField("Variant Code", PhysInvtOrderLine."Variant Code");
                ReservEntry.TestField("Location Code", PhysInvtOrderLine."Location Code");
                ReservEntry."New Serial No." := ReservEntry."Serial No.";
                ReservEntry."New Lot No." := ReservEntry."Lot No.";
                ReservEntry."New Package No." := ReservEntry."Package No.";
                ReservEntry."New Expiration Date" := ReservEntry."Expiration Date";
                OnTransferResEntryToItemJnlLineOnBeforeTransfer(ReservEntry, PhysInvtOrderLine);
                Qty :=
                    CreateReservEntry.TransferReservEntry(
                        Database::"Item Journal Line",
                        ItemJnlLine."Entry Type".AsInteger(), ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", 0,
                        ItemJnlLine."Line No.", ItemJnlLine."Qty. per Unit of Measure", ReservEntry, Qty);
            until (ReservEntry.Next() = 0) or (Qty = 0);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetTrackingNosFromWhse(Item: Record Item; ItemTrackingCode: Record "Item Tracking Code"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSuggestUseTrackingLines(Item: Record Item; ItemTrackingCode: Record "Item Tracking Code"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferResEntryToItemJnlLineOnBeforeTransfer(var ReservationEntry: Record "Reservation Entry"; PhysInvtOrderLine: Record "Phys. Invt. Order Line")
    begin
    end;
}

