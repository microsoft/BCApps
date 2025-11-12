// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Inventory.Transfer;
using Microsoft.Foundation.Enums;

codeunit 99000846 "Trans. Get Demand To Reserve"
{
    var
        SourceDocTok: Label '%1 %2 %3', Locked = true;
        TransferTok: Label 'Transfer';

    // Reservation Worksheet

    [EventSubscriber(ObjectType::Table, Database::"Reservation Wksh. Line", 'OnIsOutdated', '', false, false)]
    local procedure OnIsOutdated(ReservationWkshLine: Record "Reservation Wksh. Line"; var Outdated: Boolean)
    var
        TransferLine: Record "Transfer Line";
    begin
        case ReservationWkshLine."Source Type" of
            Database::"Transfer Line":
                begin
                    if not TransferLine.Get(ReservationWkshLine."Record ID") then
                        Outdated := true;
                    if (ReservationWkshLine."Item No." <> TransferLine."Item No.") or
                       (ReservationWkshLine."Variant Code" <> TransferLine."Variant Code") or
                       (ReservationWkshLine."Location Code" <> TransferLine."Transfer-from Code") or
                       (ReservationWkshLine."Unit of Measure Code" <> TransferLine."Unit of Measure Code")
                    then
                        Outdated := true;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Reservation Wksh. Log Factbox", 'OnShowDocument', '', false, false)]
    local procedure OnShowDocument(var ReservationWorksheetLog: Record "Reservation Worksheet Log"; var IsHandled: Boolean)
    var
        TransferLine: Record "Transfer Line";
    begin
        if TransferLine.Get(ReservationWorksheetLog."Record ID") then begin
            TransferLine.SetRecFilter();
            Page.Run(0, TransferLine);
            IsHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Worksheet Mgt.", 'OnBeforeCreateSourceDocumentText', '', false, false)]
    local procedure OnBeforeCreateSourceDocumentText(var ReservationWkshLine: Record "Reservation Wksh. Line"; var LineText: Text[100])
    begin
        case ReservationWkshLine."Source Type" of
            Database::"Transfer Line":
                LineText :=
                  StrSubstNo(
                    SourceDocTok, TransferTok,
                    Enum::"Transfer Direction".FromInteger(ReservationWkshLine."Source Subtype"), ReservationWkshLine."Source ID");
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Worksheet Mgt.", 'OnGetSourceDocumentLine', '', false, false)]
    local procedure OnGetSourceDocumentLine(var ReservationWkshLine: Record "Reservation Wksh. Line"; var RecordVariant: Variant; var MaxQtyToReserve: Decimal; var MaxQtyToReserveBase: Decimal; var AvailabilityDate: Date)
    var
        TransferLine: Record "Transfer Line";
    begin
        case ReservationWkshLine."Source Type" of
            Database::"Transfer Line":
                begin
                    TransferLine.Get(ReservationWkshLine."Record ID");
                    RecordVariant := TransferLine;
                    TransferLine.GetRemainingQty(MaxQtyToReserve, MaxQtyToReserveBase, ReservationWkshLine."Source Subtype");
                    AvailabilityDate := TransferLine."Shipment Date";
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Worksheet Mgt.", 'OnGetSourceDocumentLineQuantities', '', false, false)]
    local procedure OnGetSourceDocumentLineQuantities(var ReservationWkshLine: Record "Reservation Wksh. Line"; var OutstandingQty: Decimal; var ReservedQty: Decimal; var ReservedFromStockQty: Decimal)
    var
        TransferLine: Record "Transfer Line";
        TransferLineReserve: Codeunit "Transfer Line-Reserve";
    begin
        case ReservationWkshLine."Source Type" of
            Database::"Transfer Line":
                begin
                    TransferLine.SetLoadFields("Outstanding Quantity");
                    TransferLine.Get(ReservationWkshLine."Record ID");
                    TransferLine.CalcFields("Reserved Quantity Outbnd.");
                    OutstandingQty := TransferLine."Outstanding Quantity";
                    ReservedQty := TransferLine."Reserved Quantity Outbnd.";
                    ReservedFromStockQty := TransferLineReserve.GetReservedQtyFromInventory(TransferLine);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Worksheet Mgt.", 'OnShowSourceDocument', '', false, false)]
    local procedure OnShowSourceDocument(var ReservationWkshLine: Record "Reservation Wksh. Line")
    var
        TransferLine: Record "Transfer Line";
    begin
        case ReservationWkshLine."Source Type" of
            Database::"Transfer Line":
                if TransferLine.Get(ReservationWkshLine."Record ID") then begin
                    TransferLine.SetRecFilter();
                    Page.Run(0, TransferLine);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Worksheet Mgt.", 'OnShowReservationEntries', '', false, false)]
    local procedure OnShowReservationEntries(var ReservationWkshLine: Record "Reservation Wksh. Line")
    var
        TransferLine: Record "Transfer Line";
    begin
        case ReservationWkshLine."Source Type" of
            Database::"Transfer Line":
                begin
                    TransferLine.Get(ReservationWkshLine."Record ID");
                    TransferLine.ShowReservationEntries(false, Enum::"Transfer Direction"::Outbound);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Worksheet Mgt.", 'OnShowStatistics', '', false, false)]
    local procedure OnShowStatistics(var ReservationWkshLine: Record "Reservation Wksh. Line")
    var
        TransferHeader: Record "Transfer Header";
    begin
        case ReservationWkshLine."Source Type" of
            Database::"Transfer Line":
                begin
                    TransferHeader.SetLoadFields("No.");
                    TransferHeader.Get(ReservationWkshLine."Source ID");
                    Page.RunModal(Page::"Transfer Statistics", TransferHeader);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Worksheet Mgt.", 'OnCalculateDemandOnAfterSync', '', false, false)]
    local procedure SyncTransferOrderLines(BatchName: Code[10]; var GetDemandToReserve: Report "Get Demand To Reserve")
    var
        ReservationWkshLine: Record "Reservation Wksh. Line";
        TempTransferLine: Record "Transfer Line" temporary;
        ReservationWorksheetMgt: Codeunit "Reservation Worksheet Mgt.";
        RemainingQty, RemainingQtyBase : Decimal;
        AvailableQtyBase, InventoryQtyBase, ReservedQtyBase, WarehouseQtyBase : Decimal;
        LineNo: Integer;
    begin
        GetDemandToReserve.GetTransferOrderLines(TempTransferLine);
        if TempTransferLine.IsEmpty() then
            exit;

        ReservationWkshLine.SetCurrentKey("Journal Batch Name", "Source Type");
        ReservationWkshLine.SetRange("Journal Batch Name", BatchName);
        ReservationWkshLine.SetRange("Source Type", Database::"Transfer Line");
        if ReservationWkshLine.FindSet(true) then
            repeat
                if ReservationWkshLine.IsOutdated() or TempTransferLine.Get(ReservationWkshLine."Record ID") then
                    ReservationWkshLine.Delete(true);
            until ReservationWkshLine.Next() = 0;

        ReservationWkshLine."Journal Batch Name" := BatchName;
        LineNo := ReservationWkshLine.GetLastLineNo();

        TempTransferLine.FindSet();
        repeat
            LineNo += 10000;
            ReservationWkshLine.Init();
            ReservationWkshLine."Journal Batch Name" := BatchName;
            ReservationWkshLine."Line No." := LineNo;
            ReservationWkshLine."Source Type" := Database::"Transfer Line";
            ReservationWkshLine."Source Subtype" := Enum::"Transfer Direction"::Outbound.AsInteger();
            ReservationWkshLine."Source ID" := TempTransferLine."Document No.";
            ReservationWkshLine."Source Ref. No." := TempTransferLine."Line No.";
            ReservationWkshLine."Record ID" := TempTransferLine.RecordId;
            ReservationWkshLine."Item No." := TempTransferLine."Item No.";
            ReservationWkshLine."Variant Code" := TempTransferLine."Variant Code";
            ReservationWkshLine."Location Code" := TempTransferLine."Transfer-from Code";
            ReservationWkshLine.Description := TempTransferLine.Description;
            ReservationWkshLine."Description 2" := TempTransferLine."Description 2";
            ReservationWkshLine."Demand Date" := TempTransferLine."Shipment Date";
            ReservationWkshLine."Unit of Measure Code" := TempTransferLine."Unit of Measure Code";
            ReservationWkshLine."Qty. per Unit of Measure" := TempTransferLine."Qty. per Unit of Measure";

            TempTransferLine.GetRemainingQty(RemainingQty, RemainingQtyBase, Enum::"Transfer Direction"::Outbound.AsInteger());
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
        until TempTransferLine.Next() = 0;
    end;

#if not CLEAN27
    [Obsolete('This event is never raised.', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnGetDemandOnBeforeSetTempTransferLine(var TransferLine: Record "Transfer Line"; var IsHandled: Boolean)
    begin
    end;
#endif
}
