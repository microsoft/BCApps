// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;

codeunit 99000868 "Prod. Order Comp. Invt.Profile"
{
    // Inventory Profile

    procedure TransferInventoryProfileFromProdOrderComponent(var InventoryProfile: Record "Inventory Profile"; var ProdOrderComponent: Record "Prod. Order Component"; var TrackingReservationEntry: Record "Reservation Entry")
    var
        ReservationEntry: Record "Reservation Entry";
        AutoReservedQty: Decimal;
    begin
        InventoryProfile.SetSource(
          Database::"Prod. Order Component", ProdOrderComponent.Status.AsInteger(), ProdOrderComponent."Prod. Order No.",
          ProdOrderComponent."Line No.", '', ProdOrderComponent."Prod. Order Line No.");
        InventoryProfile."Ref. Order Type" := InventoryProfile."Ref. Order Type"::"Prod. Order";
        InventoryProfile."Ref. Order No." := ProdOrderComponent."Prod. Order No.";
        InventoryProfile."Ref. Line No." := ProdOrderComponent."Prod. Order Line No.";
        InventoryProfile."Item No." := ProdOrderComponent."Item No.";
        InventoryProfile."Variant Code" := ProdOrderComponent."Variant Code";
        InventoryProfile."Location Code" := ProdOrderComponent."Location Code";
        InventoryProfile."Bin Code" := ProdOrderComponent."Bin Code";
        InventoryProfile."Due Date" := ProdOrderComponent."Due Date";
        InventoryProfile."Due Time" := ProdOrderComponent."Due Time";
        InventoryProfile."Planning Flexibility" := InventoryProfile."Planning Flexibility"::None;
        InventoryProfile."Planning Level Code" := ProdOrderComponent."Planning Level Code";
        ProdOrderComponent.CalcFields("Reserved Qty. (Base)");
        if ProdOrderComponent.Status in [ProdOrderComponent.Status::Released, ProdOrderComponent.Status::Finished] then
            ProdOrderComponent.CalcFields("Act. Consumption (Qty)");
        ProdOrderComponent.SetReservationFilters(ReservationEntry);
        AutoReservedQty := -InventoryProfile.TransferBindings(ReservationEntry, TrackingReservationEntry);
        InventoryProfile."Untracked Quantity" := ProdOrderComponent."Remaining Qty. (Base)" - ProdOrderComponent."Reserved Qty. (Base)" + AutoReservedQty;
        InventoryProfile.Quantity := ProdOrderComponent."Expected Quantity";
        InventoryProfile."Remaining Quantity" := ProdOrderComponent."Remaining Quantity";
        InventoryProfile."Finished Quantity" := ProdOrderComponent."Act. Consumption (Qty)";
        InventoryProfile."Quantity (Base)" := ProdOrderComponent."Expected Qty. (Base)";
        InventoryProfile."Remaining Quantity (Base)" := ProdOrderComponent."Remaining Qty. (Base)";
        InventoryProfile."Unit of Measure Code" := ProdOrderComponent."Unit of Measure Code";
        InventoryProfile."Qty. per Unit of Measure" := ProdOrderComponent."Qty. per Unit of Measure";
        InventoryProfile.IsSupply := InventoryProfile."Untracked Quantity" < 0;

        OnAfterTransferInventoryProfileFromProdOrderComponent(InventoryProfile, ProdOrderComponent);
#if not CLEAN25
        InventoryProfile.RunOnAfterTransferFromComponent(InventoryProfile, ProdOrderComponent);
#endif
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferInventoryProfileFromProdOrderComponent(var InventoryProfile: Record "Inventory Profile"; var ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"Inventory Profile", 'OnTransferToTrackingEntrySourceTypeElseCase', '', true, true)]
    local procedure OnTransferToTrackingEntrySourceTypeElseCase(var InventoryProfile: Record "Inventory Profile"; var ReservationEntry: Record "Reservation Entry"; var IsHandled: Boolean)
    begin
        if InventoryProfile."Source Type" = Database::"Prod. Order Component" then begin
            ReservationEntry.SetSource(
                Database::"Prod. Order Component", InventoryProfile."Source Order Status", InventoryProfile."Source ID",
                InventoryProfile."Source Ref. No.", '', InventoryProfile."Source Prod. Order Line");
            IsHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Profile Offsetting", 'OnAfterSetDemandPriority', '', true, true)]
    local procedure OnAfterSetDemandPriority(var InventoryProfile: Record "Inventory Profile")
    begin
        if InventoryProfile."Source Type" = Database::"Prod. Order Component" then
            case InventoryProfile."Source Order Status" of
                // Simulated,Planned,Firm Planned,Released,Finished
                3:
                    InventoryProfile."Order Priority" := 500;
                // Released
                2:
                    InventoryProfile."Order Priority" := 510;
                // Firm Planned
                1:
                    InventoryProfile."Order Priority" := 520;
            // Planned
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Profile Offsetting", 'OnAfterSetSupplyPriority', '', true, true)]
    local procedure OnAfterSetSupplyPriority(var InventoryProfile: Record "Inventory Profile")
    begin
        if InventoryProfile."Source Type" = Database::"Prod. Order Component" then
            case InventoryProfile."Source Order Status" of
                // Simulated,Planned,Firm Planned,Released,Finished
                3:
                    InventoryProfile."Order Priority" := 600;
                // Released
                2:
                    InventoryProfile."Order Priority" := 610;
                // Firm Planned
                1:
                    InventoryProfile."Order Priority" := 620;
            // Planned
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Profile Offsetting", 'OnAfterDemandToInvProfile', '', true, true)]
    local procedure OnAfterDemandToInvProfile(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; var ReservEntry: Record "Reservation Entry"; var NextLineNo: Integer)
    begin
        TransProdOrderCompToProfile(InventoryProfile, Item, ReservEntry, NextLineNo);
    end;

    local procedure TransProdOrderCompToProfile(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; var TempReservationEntry: Record "Reservation Entry" temporary; var NextLineNo: Integer)
    var
        ProdOrderComp: Record "Prod. Order Component";
        ReqLine: Record "Requisition Line";
#if not CLEAN25
        InventoryProfileOffsetting: Codeunit "Inventory Profile Offsetting";
#endif
        IsHandled: Boolean;
        ShouldProcess: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransProdOrderCompToProfile(InventoryProfile, Item, IsHandled);
#if not CLEAN25
        InventoryProfileOffsetting.RunOnBeforeTransProdOrderCompToProfile(InventoryProfile, Item, IsHandled);
#endif
        if IsHandled then
            exit;

        if ProdOrderComp.FindLinesWithItemToPlan(Item, true) then
            repeat
                ShouldProcess := ProdOrderComp."Due Date" <> 0D;
                OnTransProdOrderCompToProfileOnBeforeProcessLine(ProdOrderComp, ShouldProcess);
#if not CLEAN25
                InventoryProfileOffsetting.RunOnTransProdOrderCompToProfileOnBeforeProcessLine(ProdOrderComp, ShouldProcess);
#endif
                if ShouldProcess then begin
                    ReqLine.SetRefOrderFilters(
                      ReqLine."Ref. Order Type"::"Prod. Order", ProdOrderComp.Status.AsInteger(),
                      ProdOrderComp."Prod. Order No.", ProdOrderComp."Prod. Order Line No.");
                    ReqLine.SetRange("Operation No.", '');
                    if ReqLine.IsEmpty() then begin
                        InventoryProfile.Init();
                        NextLineNo += 1;
                        InventoryProfile."Line No." := NextLineNo;
                        TransferInventoryProfileFromProdOrderComponent(InventoryProfile, ProdOrderComp, TempReservationEntry);
                        if InventoryProfile.IsSupply then
                            InventoryProfile.ChangeSign();
                        OnTransProdOrderCompToProfileOnBeforeInvProfileInsert(InventoryProfile, Item, NextLineNo);
#if not CLEAN25
                        InventoryProfileOffsetting.RunOnTransProdOrderCompToProfileOnBeforeInvProfileInsert(InventoryProfile, Item, NextLineNo);
#endif
                        InventoryProfile.Insert();
                    end;
                end;
            until ProdOrderComp.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransProdOrderCompToProfile(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransProdOrderCompToProfileOnBeforeProcessLine(ProdOrderComp: Record "Prod. Order Component"; var ShouldProcess: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransProdOrderCompToProfileOnBeforeInvProfileInsert(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; var LineNo: Integer)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Plng. Component Invt. Profile", 'OnTransferInventoryProfileFromPlamComponentByRefOrderType', '', true, true)]
    local procedure OnTransferInventoryProfileFromPlamComponentByRefOrderType(var InventoryProfile: Record "Inventory Profile"; PlanningComponent: Record "Planning Component")
    var
        ProdOrderComponent: Record "Prod. Order Component";
        ReservationEntry: Record "Reservation Entry";
        ReservedQty: Decimal;
    begin
        case PlanningComponent."Ref. Order Type" of
            PlanningComponent."Ref. Order Type"::"Prod. Order":
                if ProdOrderComponent.Get(
                     PlanningComponent."Ref. Order Status",
                     PlanningComponent."Ref. Order No.",
                     PlanningComponent."Ref. Order Line No.",
                     PlanningComponent."Line No.")
                then begin
                    InventoryProfile."Original Quantity" := ProdOrderComponent."Expected Quantity";
                    ProdOrderComponent.CalcFields("Reserved Qty. (Base)");
                    if ProdOrderComponent."Reserved Qty. (Base)" > 0 then begin
                        ReservedQty := ProdOrderComponent."Reserved Qty. (Base)";
                        ProdOrderComponent.SetReservationFilters(ReservationEntry);
                        InventoryProfile.CalcReservedQty(ReservationEntry, ReservedQty);
                        if ReservedQty > InventoryProfile."Untracked Quantity" then
                            InventoryProfile."Untracked Quantity" := 0
                        else
                            InventoryProfile."Untracked Quantity" := InventoryProfile."Untracked Quantity" - ReservedQty;
                    end;
                end else begin
                    InventoryProfile."Primary Order Type" := Database::"Planning Component";
                    InventoryProfile."Primary Order Status" := PlanningComponent."Ref. Order Status".AsInteger();
                    InventoryProfile."Primary Order No." := PlanningComponent."Ref. Order No.";
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Plng. Component Invt. Profile", 'OnTransferToTrackingEntrySourceTypeElseCaseOnSetSource', '', true, true)]
    local procedure OnTransferToTrackingEntrySourceTypeElseCaseOnSetSource(var InventoryProfile: Record "Inventory Profile"; var ReservationEntry: Record "Reservation Entry"; var RequisitionLine: Record "Requisition Line")
    begin
        case RequisitionLine."Ref. Order Type" of
            RequisitionLine."Ref. Order Type"::"Prod. Order":
                ReservationEntry.SetSource(
                    Database::"Prod. Order Component", RequisitionLine."Ref. Order Status".AsInteger(),
                    InventoryProfile."Ref. Order No.", InventoryProfile."Source Ref. No.", '', InventoryProfile."Ref. Line No.");
        end;
    end;
}
