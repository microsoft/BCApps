// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Planning;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;

codeunit 99000860 "Plng. Component Invt. Profile"
{
    // Inventory Profile

    procedure TransferInventoryProfileFromPlanComponent(var InventoryProfile: Record "Inventory Profile"; var PlanningComponent: Record "Planning Component"; var TrackingReservationEntry: Record "Reservation Entry")
    var
        ReservationEntry: Record "Reservation Entry";
        AutoReservedQty: Decimal;
    begin
        InventoryProfile.SetSource(
          Database::"Planning Component", 0, PlanningComponent."Worksheet Template Name", PlanningComponent."Line No.",
          PlanningComponent."Worksheet Batch Name", PlanningComponent."Worksheet Line No.");
        InventoryProfile."Ref. Order Type" := PlanningComponent."Ref. Order Type";
        InventoryProfile."Ref. Order No." := PlanningComponent."Ref. Order No.";
        InventoryProfile."Ref. Line No." := PlanningComponent."Ref. Order Line No.";
        InventoryProfile."Item No." := PlanningComponent."Item No.";
        InventoryProfile."Variant Code" := PlanningComponent."Variant Code";
        InventoryProfile."Location Code" := PlanningComponent."Location Code";
        InventoryProfile."Bin Code" := PlanningComponent."Bin Code";
        InventoryProfile."Due Date" := PlanningComponent."Due Date";
        InventoryProfile."Due Time" := PlanningComponent."Due Time";
        InventoryProfile."Planning Flexibility" := InventoryProfile."Planning Flexibility"::None;
        InventoryProfile."Planning Level Code" := PlanningComponent."Planning Level Code";
        PlanningComponent.SetReservationFilters(ReservationEntry);
        AutoReservedQty := -InventoryProfile.TransferBindings(ReservationEntry, TrackingReservationEntry);
        PlanningComponent.CalcFields("Reserved Qty. (Base)");
        InventoryProfile."Untracked Quantity" :=
          PlanningComponent."Expected Quantity (Base)" - PlanningComponent."Reserved Qty. (Base)" + AutoReservedQty;
        OnTransferInventoryProfileFromPlamComponentByRefOrderType(InventoryProfile, PlanningComponent);
        InventoryProfile.Quantity := PlanningComponent."Expected Quantity";
        InventoryProfile."Remaining Quantity" := PlanningComponent."Expected Quantity";
        InventoryProfile."Finished Quantity" := 0;
        InventoryProfile."Quantity (Base)" := PlanningComponent."Expected Quantity (Base)";
        InventoryProfile."Remaining Quantity (Base)" := PlanningComponent."Expected Quantity (Base)";
        InventoryProfile."Unit of Measure Code" := PlanningComponent."Unit of Measure Code";
        InventoryProfile."Qty. per Unit of Measure" := PlanningComponent."Qty. per Unit of Measure";
        InventoryProfile.IsSupply := InventoryProfile."Untracked Quantity" < 0;

        OnAfterTransferInventoryProfileFromPlanningComponent(InventoryProfile, PlanningComponent);
#if not CLEAN25
        InventoryProfile.RunOnAfterTransferFromPlanComponent(InventoryProfile, PlanningComponent);
#endif 
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferInventoryProfileFromPlanningComponent(var InventoryProfile: Record "Inventory Profile"; var PlanningComponent: Record "Planning Component")
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"Inventory Profile", 'OnTransferToTrackingEntrySourceTypeElseCase', '', false, false)]
    local procedure OnTransferToTrackingEntrySourceTypeElseCase(var InventoryProfile: Record "Inventory Profile"; var ReservationEntry: Record "Reservation Entry"; var IsHandled: Boolean; UseSecondaryFields: Boolean)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        if InventoryProfile."Source Type" = Database::"Planning Component" then begin
            if UseSecondaryFields then begin
                RequisitionLine.Get(InventoryProfile."Source ID", InventoryProfile."Source Batch Name", InventoryProfile."Source Prod. Order Line");
                OnTransferToTrackingEntrySourceTypeElseCaseOnSetSource(InventoryProfile, ReservationEntry, RequisitionLine);
            end else
                ReservationEntry.SetSource(
                    Database::"Planning Component", 0, InventoryProfile."Source ID", InventoryProfile."Source Ref. No.",
                    InventoryProfile."Source Batch Name", InventoryProfile."Source Prod. Order Line");
            IsHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Profile Offsetting", 'OnAfterSetDemandPriority', '', false, false)]
    local procedure OnAfterSetDemandPriority(var InventoryProfile: Record "Inventory Profile")
    begin
        if InventoryProfile."Source Type" = Database::"Planning Component" then
            InventoryProfile."Order Priority" := 600;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Profile Offsetting", 'OnAfterSetSupplyPriority', '', false, false)]
    local procedure OnAfterSetSupplyPriority(var InventoryProfile: Record "Inventory Profile")
    begin
        if InventoryProfile."Source Type" = Database::"Planning Component" then
            InventoryProfile."Order Priority" := 300;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Profile Offsetting", 'OnAfterDemandToInvProfile', '', false, false)]
    local procedure OnAfterDemandToInvProfile(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; var ReservEntry: Record "Reservation Entry"; var NextLineNo: Integer; PlanMRP: Boolean)
    begin
        TransPlanningCompToProfile(InventoryProfile, Item, ReservEntry, NextLineNo, PlanMRP);
    end;

    local procedure TransPlanningCompToProfile(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; var TempReservationEntry: Record "Reservation Entry" temporary; var NextLineNo: Integer; PlanMRP: Boolean)
    var
        PlanningComponent: Record "Planning Component";
#if not CLEAN25
        InventoryProfileOffsetting: Codeunit "Inventory Profile Offsetting";
#endif
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransPlanningCompToProfile(InventoryProfile, Item, IsHandled);
#if not CLEAN25
        InventoryProfileOffsetting.RunOnBeforeTransPlanningCompToProfile(InventoryProfile, Item, IsHandled);
#endif
        if IsHandled then
            exit;

        if not PlanMRP then
            exit;

        if PlanningComponent.FindLinesWithItemToPlan(Item) then
            repeat
                if PlanningComponent."Due Date" <> 0D then begin
                    InventoryProfile.Init();
                    NextLineNo += 1;
                    InventoryProfile."Line No." := NextLineNo;
                    InventoryProfile."Item No." := Item."No.";
                    TransferInventoryProfileFromPlanComponent(InventoryProfile, PlanningComponent, TempReservationEntry);
                    if InventoryProfile.IsSupply then
                        InventoryProfile.ChangeSign();
                    OnTransPlanningCompToProfileOnBeforeInventoryProfileInsert(InventoryProfile, Item, NextLineNo);
                    InventoryProfile.Insert();
                end;
            until PlanningComponent.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransPlanningCompToProfile(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransPlanningCompToProfileOnBeforeInventoryProfileInsert(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; var LineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferInventoryProfileFromPlamComponentByRefOrderType(var InventoryProfile: Record "Inventory Profile"; PlanningComponent: Record "Planning Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferToTrackingEntrySourceTypeElseCaseOnSetSource(var InventoryProfile: Record "Inventory Profile"; var ReservationEntry: Record "Reservation Entry"; var RequisitionLine: Record "Requisition Line")
    begin
    end;
}
