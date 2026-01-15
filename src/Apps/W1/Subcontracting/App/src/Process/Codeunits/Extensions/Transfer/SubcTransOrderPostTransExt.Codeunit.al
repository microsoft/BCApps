// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Posting;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;

codeunit 99001547 "Subc. TransOrderPostTrans Ext"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Transfer", OnAfterCreateItemJnlLine, '', false, false)]
    local procedure OnAfterCreateItemJnlLine(var ItemJnlLine: Record "Item Journal Line"; TransLine: Record "Transfer Line"; DirectTransHeader: Record "Direct Trans. Header"; DirectTransLine: Record "Direct Trans. Line")
    begin
        ItemJnlLine."Prod. Order No." := DirectTransLine."Prod. Order No.";
        ItemJnlLine."Prod. Order Line No." := DirectTransLine."Prod. Order Line No.";
        ItemJnlLine."Prod. Order Comp. Line No." := DirectTransLine."Prod. Order Comp. Line No.";
        ItemJnlLine."Subcontr. Purch. Order No." := DirectTransLine."Subcontr. Purch. Order No.";
        ItemJnlLine."Subcontr. PO Line No." := DirectTransLine."Subcontr. PO Line No.";
        ItemJnlLine."Subc. Operation No." := TransLine."Operation No."
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Transfer", OnAfterInsertDirectTransHeader, '', false, false)]
    local procedure OnAfterInsertDirectTransHeader(var DirectTransHeader: Record "Direct Trans. Header"; TransferHeader: Record "Transfer Header")
    begin
        DirectTransHeader."Source Type" := TransferHeader."Source Type";
        DirectTransHeader."Source Subtype" := TransferHeader."Source Subtype";
        DirectTransHeader."Source ID" := TransferHeader."Source ID";
        DirectTransHeader."Source Ref. No." := TransferHeader."Source Ref. No.";
        DirectTransHeader."Return Order" := TransferHeader."Return Order";
        DirectTransHeader."Subcontr. Purch. Order No." := TransferHeader."Subcontr. Purch. Order No.";
        DirectTransHeader."Subcontr. PO Line No." := TransferHeader."Subcontr. PO Line No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Transfer", OnBeforeInsertDirectTransLine, '', false, false)]
    local procedure OnBeforeInsertDirectTransLine(TransferLine: Record "Transfer Line")
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        if (TransferLine."Prod. Order No." = '') or (TransferLine."Prod. Order Line No." = 0) or (TransferLine."Prod. Order Comp. Line No." = 0) then
            exit;

        if not ProdOrderComponent.Get(ProdOrderComponent.Status::Released, TransferLine."Prod. Order No.", TransferLine."Prod. Order Line No.", TransferLine."Prod. Order Comp. Line No.") then
            exit;

        ProdOrderComponent.Validate("Location Code");
        ProdOrderComponent.Modify();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Receipt", OnAfterPostItemJnlLine, '', false, false)]
    local procedure OnAfterPostItemJnlLineReceipt(ItemJnlLine: Record "Item Journal Line"; var TransLine3: Record "Transfer Line"; var TransRcptHeader2: Record "Transfer Receipt Header"; var TransRcptLine2: Record "Transfer Receipt Line"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line")
    begin
        if not ItemJnlLine."Direct Transfer" then
            exit;

        HandleDirectTransferReservationAndTracking(TransLine3, ItemJnlPostLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Transfer", OnAfterPostItemJnlLine, '', false, false)]
    local procedure OnAfterPostItemJnlLineDirectTransfer(var TransferLine3: Record "Transfer Line"; DirectTransHeader2: Record "Direct Trans. Header"; DirectTransLine2: Record "Direct Trans. Line"; ItemJournalLine: Record "Item Journal Line"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line")
    begin
        HandleDirectTransferReservationAndTracking(TransferLine3, ItemJnlPostLine);
    end;

    local procedure HandleDirectTransferReservationAndTracking(var TransLine3: Record "Transfer Line"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line")
    var
        TempItemEntryRelation: Record "Item Entry Relation" temporary;
    begin
        if not ItemJnlPostLine.CollectItemEntryRelation(TempItemEntryRelation) then
            exit;

        if not TempItemEntryRelation.FindSet() then
            exit;

        HandleReservationEntries(TransLine3, TempItemEntryRelation);

        HandleItemTrackingSurplus(TransLine3, TempItemEntryRelation);
    end;

    local procedure HandleReservationEntries(var TransLine3: Record "Transfer Line"; var TempItemEntryRelation: Record "Item Entry Relation" temporary)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        OldReservEntry: Record "Reservation Entry";
        OldReservEntryPair: Record "Reservation Entry";
        MatchFound: Boolean;
    begin
        // Find old reservations: Transfer Line (Inbound) → Prod. Order Component
        OldReservEntry.SetSourceFilter(Database::"Transfer Line", 1, TransLine3."Document No.", -1, true);
        OldReservEntry.SetRange("Source Batch Name", '');
        OldReservEntry.SetRange("Source Prod. Order Line", TransLine3."Derived From Line No.");
        OldReservEntry.SetRange("Reservation Status", OldReservEntry."Reservation Status"::Reservation);

        if not OldReservEntry.FindSet() then
            exit;

        // Process each old reservation entry
        repeat
            // Get the opposite side of the reservation (should be Prod. Order Component)
            if not OldReservEntryPair.Get(OldReservEntry."Entry No.", not OldReservEntry.Positive) then
                continue;

            if OldReservEntryPair."Source Type" <> Database::"Prod. Order Component" then
                continue;

            // Find matching Item Ledger Entry based on tracking (Serial No, Lot No)
            MatchFound := false;
            TempItemEntryRelation.Reset();
            if TempItemEntryRelation.FindSet() then
                repeat
                    if ItemLedgerEntry.Get(TempItemEntryRelation."Item Entry No.") then
                        // Check if tracking matches
                        if (ItemLedgerEntry."Serial No." = OldReservEntry."Serial No.") and
                           (ItemLedgerEntry."Lot No." = OldReservEntry."Lot No.") and
                           (ItemLedgerEntry."Package No." = OldReservEntry."Package No.")
                        then begin
                            // Create new reservation: Item Ledger Entry → Prod. Order Component
                            CreateReservEntryForProdOrderComp(
                                ItemLedgerEntry,
                                OldReservEntryPair,
                                OldReservEntry,
                                OldReservEntry."Reservation Status"::Reservation);

                            MatchFound := true;
                        end;
                until (TempItemEntryRelation.Next() = 0) or MatchFound;

            // Delete the old reservation pair only if we successfully created a new one
            if MatchFound then begin
                OldReservEntry.Delete();
                OldReservEntryPair.Delete();
            end;
        until OldReservEntry.Next() = 0;
    end;

    local procedure HandleItemTrackingSurplus(var TransLine3: Record "Transfer Line"; var TempItemEntryRelation: Record "Item Entry Relation" temporary)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ProdOrderComp: Record "Prod. Order Component";
    begin
        if not FindProdOrderComponentsForTransferLine(TransLine3, ProdOrderComp) then
            exit;

        // Process each Item Ledger Entry that was created
        TempItemEntryRelation.Reset();
        if not TempItemEntryRelation.FindSet() then
            exit;

        repeat
            if ItemLedgerEntry.Get(TempItemEntryRelation."Item Entry No.") then begin
                // Only process entries with item tracking
                if not ItemLedgerEntry.TrackingExists() then
                    continue;

                // Check if this tracking already has a reservation (was handled above)
                if ItemLedgerEntryHasReservation(ItemLedgerEntry) then
                    continue;

                // Check if this component needs this specific tracking
                if ShouldCreateSurplusForComponent(ItemLedgerEntry, ProdOrderComp) then
                    // Create surplus entry: Item Ledger Entry → Prod. Order Component
                    CreateSurplusEntryForProdOrderComp(ItemLedgerEntry, ProdOrderComp);
            end;
        until TempItemEntryRelation.Next() = 0;
    end;

    local procedure CreateReservEntryForProdOrderComp(var ItemLedgerEntry: Record "Item Ledger Entry"; var OldReservEntryPair: Record "Reservation Entry";
        var OldReservEntry: Record "Reservation Entry"; ReservationStatus: Enum "Reservation Status")
    var
        FromTrackingSpecification: Record "Tracking Specification";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
    begin
        // Set up the "For" side (Item Ledger Entry)
        CreateReservEntry.CreateReservEntryFor(
            Database::"Item Ledger Entry", 0, '', '', 0, ItemLedgerEntry."Entry No.",
            ItemLedgerEntry."Qty. per Unit of Measure",
            0, ItemLedgerEntry.Quantity,
            OldReservEntry);

        // Set up the "From" side (Prod. Order Component)
        FromTrackingSpecification.SetSourceFromReservEntry(OldReservEntryPair);
        FromTrackingSpecification."Qty. per Unit of Measure" := OldReservEntryPair."Qty. per Unit of Measure";
        FromTrackingSpecification.CopyTrackingFromReservEntry(OldReservEntryPair);
        CreateReservEntry.CreateReservEntryFrom(FromTrackingSpecification);

        CreateReservEntry.SetApplyFromEntryNo(ItemLedgerEntry."Entry No.");

        CreateReservEntry.CreateEntry(
            ItemLedgerEntry."Item No.",
            ItemLedgerEntry."Variant Code",
            ItemLedgerEntry."Location Code",
            '',
            0D,
            0D,
            0,
            ReservationStatus);
    end;

    local procedure CreateSurplusEntryForProdOrderComp(
    var ItemLedgerEntry: Record "Item Ledger Entry";
    var ProdOrderComp: Record "Prod. Order Component")
    var
        DummyReservEntry: Record "Reservation Entry";
        FromTrackingSpecification: Record "Tracking Specification";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
    begin
        // Initialize dummy reservation entry for the demand side
        DummyReservEntry.Init();
        DummyReservEntry."Source Type" := Database::"Prod. Order Component";
        DummyReservEntry."Source Subtype" := ProdOrderComp.Status.AsInteger();
        DummyReservEntry."Source ID" := ProdOrderComp."Prod. Order No.";
        DummyReservEntry."Source Prod. Order Line" := ProdOrderComp."Prod. Order Line No.";
        DummyReservEntry."Source Ref. No." := ProdOrderComp."Line No.";
        DummyReservEntry."Qty. per Unit of Measure" := ProdOrderComp."Qty. per Unit of Measure";
        DummyReservEntry.CopyTrackingFromItemLedgEntry(ItemLedgerEntry);
        DummyReservEntry."Expected Receipt Date" := ProdOrderComp."Due Date";

        CreateReservEntry.CreateReservEntryFor(
            Database::"Prod. Order Component",
            ProdOrderComp.Status.AsInteger(),
            ProdOrderComp."Prod. Order No.",
            '',
            ProdOrderComp."Prod. Order Line No.",
            ProdOrderComp."Line No.",
            ProdOrderComp."Qty. per Unit of Measure",
            0,
            ItemLedgerEntry.Quantity,
            DummyReservEntry);

        // Set up the "From" side (Item Ledger Entry - SUPPLY)
        FromTrackingSpecification.InitTrackingSpecification(
            Database::"Item Ledger Entry",
            0, '', '', 0,
            ItemLedgerEntry."Entry No.",
            ItemLedgerEntry."Variant Code",
            ItemLedgerEntry."Location Code",
            ItemLedgerEntry."Qty. per Unit of Measure");
        FromTrackingSpecification.CopyTrackingFromItemLedgEntry(ItemLedgerEntry);
        CreateReservEntry.CreateReservEntryFrom(FromTrackingSpecification);

        CreateReservEntry.SetItemLedgEntryNo(ItemLedgerEntry."Entry No.");

        CreateReservEntry.CreateEntry(
            ItemLedgerEntry."Item No.",
            ItemLedgerEntry."Variant Code",
            ItemLedgerEntry."Location Code",
            '',
            ProdOrderComp."Due Date",
            0D,
            0,
            "Reservation Status"::Surplus);
    end;

    local procedure ItemLedgerEntryHasReservation(var ItemLedgerEntry: Record "Item Ledger Entry"): Boolean
    var
        ReservEntry: Record "Reservation Entry";
    begin
        ReservEntry.SetSourceFilter(Database::"Item Ledger Entry", 0, '', ItemLedgerEntry."Entry No.", true);
        ReservEntry.SetRange("Reservation Status", ReservEntry."Reservation Status"::Reservation);
        exit(not ReservEntry.IsEmpty());
    end;

    local procedure FindProdOrderComponentsForTransferLine(var TransferLine: Record "Transfer Line"; var ProdOrderComp: Record "Prod. Order Component"): Boolean
    begin
        exit(ProdOrderComp.Get("Production Order Status"::Released, TransferLine."Prod. Order No.", TransferLine."Prod. Order Line No.", TransferLine."Prod. Order Comp. Line No."));
    end;

    local procedure ShouldCreateSurplusForComponent(var ItemLedgerEntry: Record "Item Ledger Entry"; var ProdOrderComp: Record "Prod. Order Component"): Boolean
    begin
        if (ProdOrderComp."Item No." <> ItemLedgerEntry."Item No.") or
           (ProdOrderComp."Variant Code" <> ItemLedgerEntry."Variant Code") or
           (ProdOrderComp."Location Code" <> ItemLedgerEntry."Location Code")
        then
            exit(false);

        exit(true);
    end;
}