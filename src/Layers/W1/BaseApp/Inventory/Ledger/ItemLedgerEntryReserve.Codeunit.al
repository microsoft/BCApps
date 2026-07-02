// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Ledger;

using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Warehouse.Activity;

codeunit 99000841 "Item Ledger Entry-Reserve"
{
    Permissions = TableData "Reservation Entry" = rimd;

    var
        SourceDoc2Txt: Label '%1 %2', Locked = true;

    trigger OnRun()
    begin
    end;

    procedure FilterReservFor(var FilterReservationEntry: Record "Reservation Entry"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        FilterReservFor(FilterReservationEntry, ItemLedgerEntry."Entry No.", false);
    end;

    procedure FilterReservFor(var FilterReservationEntry: Record "Reservation Entry"; ItemLedgerEntryNo: Integer; SourceKey: Boolean)
    begin
        FilterReservationEntry.SetSourceFilter(Database::"Item Ledger Entry", 0, '', ItemLedgerEntryNo, SourceKey);
        FilterReservationEntry.SetSourceFilter('', 0);
    end;

    procedure Caption(ItemLedgerEntry: Record "Item Ledger Entry") CaptionText: Text
    begin
        CaptionText := ItemLedgerEntry.GetSourceCaption();
    end;

    local procedure DrillDownTotalQuantity(SourceRecordRef: RecordRef; EntrySummary: Record "Entry Summary"; ReservationEntry: Record "Reservation Entry"; Location: Record Location; MaxQtyToReserve: Decimal)
    var
        IsHandled: Boolean;
    begin
        OnDrillDownTotalQuantity(SourceRecordRef, EntrySummary, ReservationEntry, Location, MaxQtyToReserve, IsHandled);
        if IsHandled then
            exit;

        OnDrillDownTotalQuantityElseCase(SourceRecordRef, EntrySummary, ReservationEntry, Location, MaxQtyToReserve);
    end;

    procedure DrillDownTotalQuantity(SourceRecordRef: RecordRef; EntrySummary: Record "Entry Summary"; ReservationEntry: Record "Reservation Entry"; MaxQtyToReserve: Decimal)
    var
        AvailableItemLedgEntries: Page "Available - Item Ledg. Entries";
    begin
        Clear(AvailableItemLedgEntries);
        AvailableItemLedgEntries.SetSource(SourceRecordRef, ReservationEntry, ReservationEntry.GetTransferDirection());
        AvailableItemLedgEntries.SetTotalAvailQty(EntrySummary."Total Available Quantity");
        AvailableItemLedgEntries.SetMaxQtyToReserve(MaxQtyToReserve);
        AvailableItemLedgEntries.RunModal();
    end;

    procedure DrillDownTotalQuantity(SourceRecordRef: RecordRef; EntrySummary: Record "Entry Summary"; ReservationEntry: Record "Reservation Entry"; MaxQtyToReserve: Decimal; CheckOutbound: Boolean; SetMaxQtyToreserve: Boolean)
    var
        CreatePick: Codeunit "Create Pick";
        AvailableItemLedgEntries: Page "Available - Item Ledg. Entries";
        TotalOutBoundQty: Decimal;
    begin
        Clear(AvailableItemLedgEntries);
        AvailableItemLedgEntries.SetSource(SourceRecordRef, ReservationEntry, ReservationEntry.GetTransferDirection());
        if CheckOutbound then
            TotalOutBoundQty :=
                CreatePick.CheckOutBound(
                ReservationEntry."Source Type", ReservationEntry."Source Subtype",
                ReservationEntry."Source ID", ReservationEntry."Source Ref. No.",
                ReservationEntry."Source Prod. Order Line");
        AvailableItemLedgEntries.SetTotalAvailQty(EntrySummary."Total Available Quantity" + TotalOutBoundQty);
        if SetMaxQtyToreserve then
            AvailableItemLedgEntries.SetMaxQtyToReserve(MaxQtyToReserve);
        AvailableItemLedgEntries.RunModal();
    end;

    local procedure MatchThisTable(TableID: Integer): Boolean
    begin
        exit(TableID = Database::"Item Ledger Entry");
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnFilterReservEntry', '', false, false)]
    local procedure OnFilterReservEntry(var FilterReservEntry: Record "Reservation Entry"; ReservEntrySummary: Record "Entry Summary")
    begin
        if ReservEntrySummary."Entry No." = 1 then begin
            FilterReservEntry.SetRange("Source Type", DATABASE::"Item Ledger Entry");
            FilterReservEntry.SetRange("Source Subtype", 0);
            FilterReservEntry.SetRange("Expected Receipt Date");
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnAfterRelatesToSummEntry', '', false, false)]
    local procedure OnRelatesToEntrySummary(var FilterReservEntry: Record "Reservation Entry"; FromEntrySummary: Record "Entry Summary"; var IsHandled: Boolean)
    begin
        if FromEntrySummary."Entry No." = 1 then
            IsHandled :=
                (FilterReservEntry."Source Type" = DATABASE::"Item Ledger Entry") and (FilterReservEntry."Source Subtype" = 0);
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnDrillDownTotalQuantity', '', false, false)]
    local procedure ReservationOnDrillDownTotalQuantity(SourceRecRef: RecordRef; EntrySummary: Record "Entry Summary"; ReservEntry: Record "Reservation Entry"; Location: Record Location; MaxQtyToReserve: Decimal)
    begin
        if EntrySummary."Entry No." = 1 then
            DrillDownTotalQuantity(SourceRecRef, EntrySummary, ReservEntry, Location, MaxQtyToReserve);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnLookupDocument', '', false, false)]
    local procedure OnLookupDocument(SourceType: Integer; SourceRefNo: Integer)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        if MatchThisTable(SourceType) then begin
            ItemLedgEntry.Reset();
            ItemLedgEntry.SetRange("Entry No.", SourceRefNo);
            PAGE.RunModal(0, ItemLedgEntry);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnLookupLine', '', false, false)]
    local procedure OnLookupLine(SourceType: Integer; SourceRefNo: Integer)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        if MatchThisTable(SourceType) then begin
            ItemLedgEntry.Reset();
            ItemLedgEntry.SetRange("Entry No.", SourceRefNo);
            PAGE.Run(0, ItemLedgEntry);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnFilterReservFor', '', false, false)]
    local procedure OnFilterReservFor(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var CaptionText: Text)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        if MatchThisTable(SourceRecRef.Number) then begin
            SourceRecRef.SetTable(ItemLedgerEntry);
            ItemLedgerEntry.SetReservationFilters(ReservEntry);
            CaptionText := ItemLedgerEntry.GetSourceCaption();
        end;
    end;

    local procedure GetSourceValue(ReservationEntry: Record "Reservation Entry"; var SourceRecordRef: RecordRef; ReturnOption: Option "Net Qty. (Base)","Gross Qty. (Base)"): Decimal
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.Get(ReservationEntry."Source Ref. No.");
        SourceRecordRef.GetTable(ItemLedgerEntry);
        case ReturnOption of
            ReturnOption::"Net Qty. (Base)":
                exit(ItemLedgerEntry."Remaining Quantity");
            ReturnOption::"Gross Qty. (Base)":
                exit(ItemLedgerEntry.Quantity);
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Reservation Entries", 'OnLookupReserved', '', false, false)]
    local procedure OnLookupReserved(var ReservationEntry: Record "Reservation Entry")
    begin
        if MatchThisTable(ReservationEntry."Source Type") then
            ShowSourceLines(ReservationEntry);
    end;

    local procedure ShowSourceLines(var ReservationEntry: Record "Reservation Entry")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.Reset();
        ItemLedgerEntry.SetRange("Entry No.", ReservationEntry."Source Ref. No.");
        PAGE.RunModal(Page::"Item Ledger Entries", ItemLedgerEntry);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnGetSourceRecordValue', '', false, false)]
    local procedure OnGetSourceRecordValue(var ReservEntry: Record "Reservation Entry"; ReturnOption: Option; var ReturnQty: Decimal; var SourceRecRef: RecordRef)
    begin
        if MatchThisTable(ReservEntry."Source Type") then
            ReturnQty := GetSourceValue(ReservEntry, SourceRecRef, ReturnOption);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnDrillDownTotalQuantity(SourceRecRef: RecordRef; EntrySummary: Record "Entry Summary"; ReservEntry: Record "Reservation Entry"; Location: Record Location; MaxQtyToReserve: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDrillDownTotalQuantityElseCase(SourceRecRef: RecordRef; EntrySummary: Record "Entry Summary"; ReservEntry: Record "Reservation Entry"; Location: Record Location; MaxQtyToReserve: Decimal)
    begin
    end;

#if not CLEAN27
    [Obsolete('This event is never raised.', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnSetItemLedgEntryOnBeforeUpdateReservation(var ReservEntry: Record "Reservation Entry"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;
#endif
    // codeunit Reservation Engine Mgt. subscribers

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Engine Mgt.", 'OnRevertDateToSourceDate', '', false, false)]
    local procedure OnRevertDateToSourceDate(var ReservEntry: Record "Reservation Entry")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        if ReservEntry."Source Type" = Database::"Item Ledger Entry" then begin
            ItemLedgerEntry.Get(ReservEntry."Source Ref. No.");
            ReservEntry."Expected Receipt Date" := ItemLedgerEntry."Posting Date";
            ReservEntry."Shipment Date" := 0D;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Engine Mgt.", 'OnCreateText', '', false, false)]
    local procedure OnAfterCreateText(ReservationEntry: Record "Reservation Entry"; var Description: Text[80])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        if ReservationEntry."Source Type" = Database::"Item Ledger Entry" then
            Description :=
                StrSubstNo(SourceDoc2Txt, ItemLedgerEntry.TableCaption(), ReservationEntry."Source Ref. No.");
    end;
}
