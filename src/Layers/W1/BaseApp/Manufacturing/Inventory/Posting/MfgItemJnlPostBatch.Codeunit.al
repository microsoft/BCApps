// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Posting;

using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Activity;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Document;

codeunit 99000823 "Mfg. Item Jnl.-Post Batch"
{
    SingleInstance = true;

    var
        MfgCreatePutaway: Codeunit "Mfg. Create Put-away";
#if not CLEAN27
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
#endif

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Batch", 'OnAfterPostLines', '', true, true)]
    local procedure OnBeforeCode()
    begin
        Clear(MfgCreatePutaway);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Batch", 'OnAfterPostLines', '', true, true)]
    local procedure OnAfterPostLines(var ItemJournalLine: Record "Item Journal Line"; var ItemRegNo: Integer; var WhseRegNo: Integer)
    begin
        MfgCreatePutaway.CreateWhsePutAwayForProdOutput();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Batch", 'OnCheckItemAvailabilityOnAfterSetAvailableQty', '', true, true)]
    local procedure OnCheckItemAvailabilityOnAfterSetAvailableQty(var TempSKU: Record "Stockkeeping Unit" temporary; var ItemJnlLine: Record "Item Journal Line"; var AvailableQty: Decimal)
    begin
        AvailableQty += SelfReservedQty(TempSKU, ItemJnlLine);
    end;

    local procedure SelfReservedQty(SKU: Record "Stockkeeping Unit"; ItemJnlLine: Record "Item Journal Line") Result: Decimal
    var
        ReservationEntry: Record "Reservation Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSelfReservedQty(SKU, ItemJnlLine, Result, IsHandled);
#if not CLEAN27
        ItemJnlPostBatch.RunOnBeforeSelfReservedQty(SKU, ItemJnlLine, Result, IsHandled);
#endif
        if IsHandled then
            exit(Result);

        if ItemJnlLine."Order Type" <> ItemJnlLine."Order Type"::Production then
            exit;

        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Reservation);
        ReservationEntry.SetRange("Item No.", SKU."Item No.");
        ReservationEntry.SetRange("Location Code", SKU."Location Code");
        ReservationEntry.SetRange("Variant Code", SKU."Variant Code");
        ReservationEntry.SetRange("Source Type", Database::"Prod. Order Component");
        ReservationEntry.SetRange("Source ID", ItemJnlLine."Order No.");
        if ReservationEntry.IsEmpty() then
            exit;
        ReservationEntry.CalcSums(ReservationEntry."Quantity (Base)");
        exit(-ReservationEntry."Quantity (Base)");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Batch", 'OnHandleWhsePutAwayForProdOutput', '', true, true)]
    local procedure OnHandleWhsePutAwayForProdOutput(var ItemJnlLine: Record "Item Journal Line")
    begin
        HandleWhsePutAwayForProdOutput(ItemJnlLine);
    end;

    local procedure HandleWhsePutAwayForProdOutput(ItemJournalLine: Record "Item Journal Line")
    begin
        if ItemJournalLine.OutputValuePosting() then
            exit;

        if ItemJournalLine."Entry Type" <> ItemJournalLine."Entry Type"::Output then
            exit;

        if (ItemJournalLine."Order No." = '') or (ItemJournalLine."Order Line No." = 0) then
            exit;

        MfgCreatePutaway.IncludeIntoWhsePutAwayForProdOrder(ItemJournalLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSelfReservedQty(SKU: Record "Stockkeeping Unit"; ItemJnlLine: Record "Item Journal Line"; var Result: Decimal; var IsHandled: Boolean)
    begin
    end;
}