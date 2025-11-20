// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Manufacturing.Document;

codeunit 99000858 "Mfg. Get Demand To Reserve"
{
    var
        ProductionTok: Label 'Prod. Order';
        ReleasedTok: Label 'Released';
        SourceDocTok: Label '%1 %2 %3', Locked = true;

    // Reservation Worksheet

    [EventSubscriber(ObjectType::Table, Database::"Reservation Wksh. Line", 'OnIsOutdated', '', false, false)]
    local procedure OnIsOutdated(ReservationWkshLine: Record "Reservation Wksh. Line"; var Outdated: Boolean)
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        case ReservationWkshLine."Source Type" of
            Database::"Prod. Order Component":
                begin
                    if not ProdOrderComponent.Get(ReservationWkshLine."Record ID") then
                        Outdated := true;
                    if not ProdOrderComponent.IsInventoriableItem() or
                       (ReservationWkshLine."Item No." <> ProdOrderComponent."Item No.") or
                       (ReservationWkshLine."Variant Code" <> ProdOrderComponent."Variant Code") or
                       (ReservationWkshLine."Location Code" <> ProdOrderComponent."Location Code") or
                       (ReservationWkshLine."Unit of Measure Code" <> ProdOrderComponent."Unit of Measure Code")
                    then
                        Outdated := true;
                end;
        end;
    end;


    [EventSubscriber(ObjectType::Page, Page::"Reservation Wksh. Log Factbox", 'OnShowDocument', '', false, false)]
    local procedure OnShowDocument(var ReservationWorksheetLog: Record "Reservation Worksheet Log"; var IsHandled: Boolean)
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        if ProdOrderComponent.Get(ReservationWorksheetLog."Record ID") then begin
            ProdOrderComponent.SetRecFilter();
            Page.Run(0, ProdOrderComponent);
            IsHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Worksheet Mgt.", 'OnBeforeCreateSourceDocumentText', '', false, false)]
    local procedure OnBeforeCreateSourceDocumentText(var ReservationWkshLine: Record "Reservation Wksh. Line"; var LineText: Text[100])
    begin
        case ReservationWkshLine."Source Type" of
            Database::"Prod. Order Component":
                LineText := StrSubstNo(SourceDocTok, ReleasedTok, ProductionTok, ReservationWkshLine."Source ID");
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Worksheet Mgt.", 'OnGetSourceDocumentLine', '', false, false)]
    local procedure OnGetSourceDocumentLine(var ReservationWkshLine: Record "Reservation Wksh. Line"; var RecordVariant: Variant; var MaxQtyToReserve: Decimal; var MaxQtyToReserveBase: Decimal; var AvailabilityDate: Date)
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        case ReservationWkshLine."Source Type" of
            Database::"Prod. Order Component":
                begin
                    ProdOrderComponent.Get(ReservationWkshLine."Record ID");
                    RecordVariant := ProdOrderComponent;
                    ProdOrderComponent.GetRemainingQty(MaxQtyToReserve, MaxQtyToReserveBase);
                    AvailabilityDate := ProdOrderComponent."Due Date";
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Worksheet Mgt.", 'OnGetSourceDocumentLineQuantities', '', false, false)]
    local procedure OnGetSourceDocumentLineQuantities(var ReservationWkshLine: Record "Reservation Wksh. Line"; var OutstandingQty: Decimal; var ReservedQty: Decimal; var ReservedFromStockQty: Decimal)
    var
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderCompReserve: Codeunit "Prod. Order Comp.-Reserve";
    begin
        case ReservationWkshLine."Source Type" of
            Database::"Prod. Order Component":
                begin
                    ProdOrderComponent.SetLoadFields("Remaining Quantity");
                    ProdOrderComponent.Get(ReservationWkshLine."Record ID");
                    ProdOrderComponent.CalcFields("Reserved Quantity");
                    OutstandingQty := ProdOrderComponent."Remaining Quantity";
                    ReservedQty := ProdOrderComponent."Reserved Quantity";
                    ReservedFromStockQty := ProdOrderCompReserve.GetReservedQtyFromInventory(ProdOrderComponent);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Worksheet Mgt.", 'OnShowSourceDocument', '', false, false)]
    local procedure OnShowSourceDocument(var ReservationWkshLine: Record "Reservation Wksh. Line")
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        case ReservationWkshLine."Source Type" of
            Database::"Prod. Order Component":
                if ProdOrderComponent.Get(ReservationWkshLine."Record ID") then begin
                    ProdOrderComponent.SetRecFilter();
                    Page.Run(0, ProdOrderComponent);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Worksheet Mgt.", 'OnShowReservationEntries', '', false, false)]
    local procedure OnShowReservationEntries(var ReservationWkshLine: Record "Reservation Wksh. Line")
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        case ReservationWkshLine."Source Type" of
            Database::"Prod. Order Component":
                begin
                    ProdOrderComponent.Get(ReservationWkshLine."Record ID");
                    ProdOrderComponent.ShowReservationEntries(false);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Worksheet Mgt.", 'OnShowStatistics', '', false, false)]
    local procedure OnShowStatistics(var ReservationWkshLine: Record "Reservation Wksh. Line")
    var
        ProductionOrder: Record "Production Order";
    begin
        case ReservationWkshLine."Source Type" of
            Database::"Prod. Order Component":
                begin
                    ProductionOrder.SetLoadFields(Status, "No.");
                    ProductionOrder.Get(ReservationWkshLine."Source Subtype", ReservationWkshLine."Source ID");
                    Page.RunModal(Page::"Production Order Statistics", ProductionOrder);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Worksheet Mgt.", 'OnCalculateDemandOnAfterSync', '', false, false)]
    local procedure SyncProdOrderComponents(BatchName: Code[10]; var GetDemandToReserve: Report "Get Demand To Reserve")
    var
        ReservationWkshLine: Record "Reservation Wksh. Line";
        TempProdOrderComponent: Record "Prod. Order Component" temporary;
        ReservationWorksheetMgt: Codeunit "Reservation Worksheet Mgt.";
        RemainingQty, RemainingQtyBase : Decimal;
        AvailableQtyBase, InventoryQtyBase, ReservedQtyBase, WarehouseQtyBase : Decimal;
        LineNo: Integer;
    begin
        GetDemandToReserve.GetProdOrderComponents(TempProdOrderComponent);
        if TempProdOrderComponent.IsEmpty() then
            exit;

        ReservationWkshLine.SetCurrentKey("Journal Batch Name", "Source Type");
        ReservationWkshLine.SetRange("Journal Batch Name", BatchName);
        ReservationWkshLine.SetRange("Source Type", Database::"Prod. Order Component");
        if ReservationWkshLine.FindSet(true) then
            repeat
                if ReservationWkshLine.IsOutdated() or TempProdOrderComponent.Get(ReservationWkshLine."Record ID") then
                    ReservationWkshLine.Delete(true);
            until ReservationWkshLine.Next() = 0;

        ReservationWkshLine."Journal Batch Name" := BatchName;
        LineNo := ReservationWkshLine.GetLastLineNo();

        TempProdOrderComponent.FindSet();
        repeat
            LineNo += 10000;
            ReservationWkshLine.Init();
            ReservationWkshLine."Journal Batch Name" := BatchName;
            ReservationWkshLine."Line No." := LineNo;
            ReservationWkshLine."Source Type" := Database::"Prod. Order Component";
            ReservationWkshLine."Source Subtype" := TempProdOrderComponent.Status.AsInteger();
            ReservationWkshLine."Source ID" := TempProdOrderComponent."Prod. Order No.";
            ReservationWkshLine."Source Ref. No." := TempProdOrderComponent."Line No.";
            ReservationWkshLine."Source Prod. Order Line" := TempProdOrderComponent."Prod. Order Line No.";
            ReservationWkshLine."Record ID" := TempProdOrderComponent.RecordId;
            ReservationWkshLine."Item No." := TempProdOrderComponent."Item No.";
            ReservationWkshLine."Variant Code" := TempProdOrderComponent."Variant Code";
            ReservationWkshLine."Location Code" := TempProdOrderComponent."Location Code";
            ReservationWkshLine.Description := TempProdOrderComponent.Description;

            ReservationWkshLine."Demand Date" := TempProdOrderComponent."Due Date";
            ReservationWkshLine."Unit of Measure Code" := TempProdOrderComponent."Unit of Measure Code";
            ReservationWkshLine."Qty. per Unit of Measure" := TempProdOrderComponent."Qty. per Unit of Measure";

            TempProdOrderComponent.GetRemainingQty(RemainingQty, RemainingQtyBase);
            ReservationWkshLine."Remaining Qty. to Reserve" := RemainingQty;
            ReservationWkshLine."Rem. Qty. to Reserve (Base)" := RemainingQtyBase;

            ReservationWorksheetMgt.GetAvailRemainingQtyOnItemLedgerEntry(
              AvailableQtyBase, InventoryQtyBase, ReservedQtyBase, WarehouseQtyBase,
              ReservationWkshLine."Item No.", ReservationWkshLine."Variant Code", ReservationWkshLine."Location Code");

            ReservationWkshLine.Validate("Avail. Qty. to Reserve (Base)", AvailableQtyBase);
            ReservationWkshLine.Validate("Qty. in Stock (Base)", InventoryQtyBase);
            ReservationWkshLine.Validate("Qty. Reserv. in Stock (Base)", ReservedQtyBase);
            ReservationWkshLine.Validate("Qty. in Whse. Handling (Base)", WarehouseQtyBase);

            if (ReservationWkshLine."Remaining Qty. to Reserve" > 0) and
               (ReservationWkshLine."Available Qty. to Reserve" > 0)
            then
                ReservationWkshLine.Insert(true);
        until TempProdOrderComponent.Next() = 0;
    end;

#if not CLEAN27
    [Obsolete('This event is never raised.', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnGetDemandOnBeforeSetTempProdOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; var IsHandled: Boolean)
    begin
    end;
#endif
}
