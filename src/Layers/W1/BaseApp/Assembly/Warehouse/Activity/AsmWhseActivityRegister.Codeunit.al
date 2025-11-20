// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Activity;

using Microsoft.Assembly.Document;
using Microsoft.Warehouse.Request;
using Microsoft.Inventory.Tracking;

codeunit 939 "Asm. Whse.-Activity-Register"
{
#if not CLEAN27
    var
        WhseActivityRegister: Codeunit "Whse.-Activity-Register";
#endif

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Activity-Register", 'OnUpdateWhseDocHeaderByWhseDocumentType', '', false, false)]
    local procedure OnUpdateWhseDocHeaderByWhseDocumentType(var WarehouseActivityLine: Record "Warehouse Activity Line")
    var
        AssemblyHeader: Record "Assembly Header";
        WhsePickRequest: Record "Whse. Pick Request";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        case WarehouseActivityLine."Whse. Document Type" of
            WarehouseActivityLine."Whse. Document Type"::Assembly:
                if WarehouseActivityLine."Action Type" <> WarehouseActivityLine."Action Type"::Take then begin
                    AssemblyHeader.Get(WarehouseActivityLine."Source Subtype", WarehouseActivityLine."Source No.");
                    if AssemblyHeader.CompletelyPicked() then begin
                        WhsePickRequest.SetRange("Document Type", WhsePickRequest."Document Type"::Assembly);
                        WhsePickRequest.SetRange("Document No.", AssemblyHeader."No.");
                        WhsePickRequest.ModifyAll("Completely Picked", true);
                        ItemTrackingMgt.DeleteWhseItemTrkgLines(
                          Database::"Assembly Line", WarehouseActivityLine."Source Subtype", WarehouseActivityLine."Source No.", '', 0, 0, '', false);
                    end;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Activity-Register", 'OnUpdateWhseSourceDocLineByDocumentType', '', false, false)]
    local procedure OnUpdateWhseSourceDocLineByDocumentType(var WarehouseActivityLine: Record "Warehouse Activity Line"; WhseDocType: Enum "Warehouse Activity Document Type")
    begin
        case WhseDocType of
            WarehouseActivityLine."Whse. Document Type"::Assembly:
                if (WarehouseActivityLine."Action Type" <> WarehouseActivityLine."Action Type"::Take) and (WarehouseActivityLine."Breakbulk No." = 0) then
                    UpdateAssemblyLine(WarehouseActivityLine);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Activity-Register", 'OnAfterUpdateSourceDocumentForInvtMovement', '', false, false)]
    local procedure OnAfterUpdateSourceDocumentForInvtMovement(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
        case WarehouseActivityLine."Source Document" of
            WarehouseActivityLine."Source Document"::"Assembly Consumption":
                UpdateAssemblyLine(WarehouseActivityLine);
        end;
    end;

    local procedure UpdateAssemblyLine(WhseActivityLine: Record "Warehouse Activity Line")
    var
        AssemblyLine: Record "Assembly Line";
    begin
        AssemblyLine.Get(WhseActivityLine."Source Subtype", WhseActivityLine."Source No.", WhseActivityLine."Source Line No.");
        AssemblyLine."Qty. Picked (Base)" :=
          AssemblyLine."Qty. Picked (Base)" + WhseActivityLine."Qty. to Handle (Base)";
        if WhseActivityLine."Qty. per Unit of Measure" = AssemblyLine."Qty. per Unit of Measure" then
            AssemblyLine."Qty. Picked" := AssemblyLine."Qty. Picked" + WhseActivityLine."Qty. to Handle"
        else
            AssemblyLine."Qty. Picked" :=
              Round(AssemblyLine."Qty. Picked" + WhseActivityLine."Qty. to Handle (Base)" / WhseActivityLine."Qty. per Unit of Measure");
        OnBeforeAssemblyLineModify(AssemblyLine, WhseActivityLine);
#if not CLEAN27
        WhseActivityRegister.RunOnBeforeAssemblyLineModify(AssemblyLine, WhseActivityLine);
#endif
        AssemblyLine.Modify();
        OnAfterAssemblyLineModify(AssemblyLine);
#if not CLEAN27
        WhseActivityRegister.RunOnAfterAssemblyLineModify(AssemblyLine);
#endif
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssemblyLineModify(var AssemblyLine: Record "Assembly Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssemblyLineModify(var AssemblyLine: Record "Assembly Line"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Activity-Register", 'OnAfterSyncItemTrackingAndReserveSourceDocument', '', false, false)]
    local procedure OnAfterSyncItemTrackingAndReserveSourceDocument(var TempWhseActivLineToReserve: Record "Warehouse Activity Line" temporary; var sender: Codeunit "Whse.-Activity-Register")
    var
        TempReservEntryBeforeSync: Record "Reservation Entry" temporary;
        TempReservEntryAfterSync: Record "Reservation Entry" temporary;
    begin
        case TempWhseActivLineToReserve."Source Document" of
            "Warehouse Activity Source Document"::"Assembly Consumption":
                begin
                    sender.CollectReservEntries(TempReservEntryBeforeSync, TempWhseActivLineToReserve);
                    sender.SyncItemTracking();
                    sender.CollectReservEntries(TempReservEntryAfterSync, TempWhseActivLineToReserve);
                    AutoReserveForAssemblyLine(TempWhseActivLineToReserve, TempReservEntryBeforeSync, TempReservEntryAfterSync);
                end;
        end;
    end;

    local procedure AutoReserveForAssemblyLine(var TempWhseActivLineToReserve: Record "Warehouse Activity Line" temporary; var TempReservEntryBefore: Record "Reservation Entry" temporary; var TempReservEntryAfter: Record "Reservation Entry" temporary)
    var
        AssemblyLine: Record "Assembly Line";
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        ReservMgt: Codeunit "Reservation Management";
        FullAutoReservation: Boolean;
        IsHandled: Boolean;
        QtyToReserve: Decimal;
        QtyToReserveBase: Decimal;
    begin
        IsHandled := false;
        OnBeforeAutoReserveForAssemblyLine(TempWhseActivLineToReserve, IsHandled);
#if not CLEAN27
        WhseActivityRegister.RunOnBeforeAutoReserveForAssemblyLine(TempWhseActivLineToReserve, IsHandled);
#endif
        if IsHandled then
            exit;

        if TempWhseActivLineToReserve.FindSet() then
            repeat
                ItemTrackingMgt.GetWhseItemTrkgSetup(TempWhseActivLineToReserve."Item No.", WhseItemTrackingSetup);
                if TempWhseActivLineToReserve.HasRequiredTracking(WhseItemTrackingSetup) then begin
                    AssemblyLine.Get(
                      TempWhseActivLineToReserve."Source Subtype", TempWhseActivLineToReserve."Source No.", TempWhseActivLineToReserve."Source Line No.");

                    TempReservEntryBefore.SetSourceFilter(
                      TempWhseActivLineToReserve."Source Type", TempWhseActivLineToReserve."Source Subtype",
                      TempWhseActivLineToReserve."Source No.", TempWhseActivLineToReserve."Source Line No.", true);
                    TempReservEntryBefore.SetTrackingFilterFromWhseActivityLine(TempWhseActivLineToReserve);
                    TempReservEntryBefore.CalcSums(Quantity, "Quantity (Base)");

                    TempReservEntryAfter.CopyFilters(TempReservEntryBefore);
                    TempReservEntryAfter.CalcSums(Quantity, "Quantity (Base)");

                    QtyToReserve :=
                        TempWhseActivLineToReserve."Qty. to Handle" + (TempReservEntryAfter.Quantity - TempReservEntryBefore.Quantity);
                    QtyToReserveBase :=
                        TempWhseActivLineToReserve."Qty. to Handle (Base)" + (TempReservEntryAfter."Quantity (Base)" - TempReservEntryBefore."Quantity (Base)");

                    if not IsAssemblyLineCompletelyReserved(AssemblyLine) and (QtyToReserve > 0) then begin
                        ReservMgt.SetReservSource(AssemblyLine);
                        ReservMgt.SetTrackingFromWhseActivityLine(TempWhseActivLineToReserve);
                        ReservMgt.AutoReserve(FullAutoReservation, '', AssemblyLine."Due Date", QtyToReserve, QtyToReserveBase);
                    end;
                end;
            until TempWhseActivLineToReserve.Next() = 0;
    end;

    local procedure IsAssemblyLineCompletelyReserved(AssemblyLine: Record "Assembly Line"): Boolean
    begin
        AssemblyLine.CalcFields("Reserved Quantity");
        exit(AssemblyLine.Quantity = AssemblyLine."Reserved Quantity");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAutoReserveForAssemblyLine(var TempWhseActivLineToReserve: Record "Warehouse Activity Line" temporary; var IsHandled: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Activity-Register", 'OnRegisterWhseItemTrkgLineOnSetDueDate', '', false, false)]
    local procedure OnRegisterWhseItemTrkgLineOnSetDueDate(WarehouseActivityLine: Record "Warehouse Activity Line"; var DueDate: Date; var QtyToRegisterBase: Decimal; WhseDocType: Enum "Warehouse Activity Document Type")
    var
        AssemblyLine: Record "Assembly Line";
    begin
        case WhseDocType of
            WarehouseActivityLine."Whse. Document Type"::Assembly:
                begin
                    AssemblyLine.SetLoadFields("Due Date");
                    AssemblyLine.Get(WarehouseActivityLine."Source Subtype", WarehouseActivityLine."Source No.", WarehouseActivityLine."Source Line No.");
                    DueDate := AssemblyLine."Due Date";
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Activity-Register", 'OnRegisterWhseItemTrkgLineOnAfterSetDueDateForInvtMovement', '', false, false)]
    local procedure OnRegisterWhseItemTrkgLineOnAfterSetDueDateForInvtMovement(WarehouseActivityLine: Record "Warehouse Activity Line"; var DueDate: Date)
    var
        AssemblyLine: Record "Assembly Line";
    begin
        case WarehouseActivityLine."Source Type" of
            Database::"Assembly Line":
                begin
                    AssemblyLine.SetLoadFields("Due Date");
                    AssemblyLine.Get(WarehouseActivityLine."Source Subtype", WarehouseActivityLine."Source No.", WarehouseActivityLine."Source Line No.");
                    DueDate := AssemblyLine."Due Date";
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Activity-Register", 'OnGetSourceLineBaseQtyByWhseActivityDocumentType', '', false, false)]
    local procedure OnGetSourceLineBaseQtyByWhseActivityDocumentType(var WarehouseActivityLine: Record "Warehouse Activity Line"; var QtyBase: Decimal; WhseDocType: Enum "Warehouse Activity Document Type")
    begin
        case WhseDocType of
            WarehouseActivityLine."Whse. Document Type"::Assembly:
                QtyBase := GetSourceLineBaseQty(WarehouseActivityLine);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Activity-Register", 'OnGetSourceLineBaseQtyByWhseActivitySourceType', '', false, false)]
    local procedure OnGetSourceLineBaseQtyByWhseActivitySourceType(var WarehouseActivityLine: Record "Warehouse Activity Line"; var QtyBase: Decimal)
    begin
        case WarehouseActivityLine."Source Document" of
            WarehouseActivityLine."Source Document"::"Assembly Consumption":
                QtyBase := GetSourceLineBaseQty(WarehouseActivityLine);
        end;
    end;

    local procedure GetSourceLineBaseQty(var WarehouseActivityLine: Record "Warehouse Activity Line"): Decimal
    var
        AssemblyLine: Record "Assembly Line";
    begin
        if AssemblyLine.Get(WarehouseActivityLine."Source Subtype", WarehouseActivityLine."Source No.", WarehouseActivityLine."Source Line No.") then
            exit(AssemblyLine."Quantity (Base)");

    end;
}
