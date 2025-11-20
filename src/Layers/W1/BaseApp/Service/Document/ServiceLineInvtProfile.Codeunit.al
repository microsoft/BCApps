// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Tracking;

codeunit 99000863 "Service Line Invt. Profile"
{
    // Inventory Profile

    procedure TransferInventoryProfileFromServLine(var InventoryProfile: Record "Inventory Profile"; var ServiceLine: Record "Service Line"; var TrackingReservationEntry: Record "Reservation Entry")
    var
        ReservationEntry: Record "Reservation Entry";
        AutoReservedQty: Decimal;
    begin
        ServiceLine.TestField(Type, ServiceLine.Type::Item);
        InventoryProfile.SetSource(Database::"Service Line", ServiceLine."Document Type".AsInteger(), ServiceLine."Document No.", ServiceLine."Line No.", '', 0);
        InventoryProfile."Item No." := ServiceLine."No.";
        InventoryProfile."Variant Code" := ServiceLine."Variant Code";
        InventoryProfile."Location Code" := ServiceLine."Location Code";
        ServiceLine.CalcFields("Reserved Qty. (Base)");
        ServiceLine.SetReservationFilters(ReservationEntry);
        AutoReservedQty := -InventoryProfile.TransferBindings(ReservationEntry, TrackingReservationEntry);
        InventoryProfile."Untracked Quantity" := ServiceLine."Outstanding Qty. (Base)" - ServiceLine."Reserved Qty. (Base)" + AutoReservedQty;
        InventoryProfile.Quantity := ServiceLine.Quantity;
        InventoryProfile."Remaining Quantity" := ServiceLine."Outstanding Quantity";
        InventoryProfile."Finished Quantity" := ServiceLine."Quantity Shipped";
        InventoryProfile."Quantity (Base)" := ServiceLine."Quantity (Base)";
        InventoryProfile."Remaining Quantity (Base)" := ServiceLine."Outstanding Qty. (Base)";
        InventoryProfile."Unit of Measure Code" := ServiceLine."Unit of Measure Code";
        InventoryProfile."Qty. per Unit of Measure" := ServiceLine."Qty. per Unit of Measure";
        InventoryProfile.IsSupply := InventoryProfile."Untracked Quantity" < 0;
        InventoryProfile."Due Date" := ServiceLine."Needed by Date";
        InventoryProfile."Planning Flexibility" := InventoryProfile."Planning Flexibility"::None;

        OnAfterTransferInventoryProfileFromServiceLine(InventoryProfile, ServiceLine);
#if not CLEAN25
        InventoryProfile.RunOnAfterTransferFromServLine(InventoryProfile, ServiceLine);
#endif
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferInventoryProfileFromServiceLine(var InventoryProfile: Record "Inventory Profile"; var ServiceLine: Record "Service Line")
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"Inventory Profile", 'OnTransferToTrackingEntrySourceTypeElseCase', '', false, false)]
    local procedure OnTransferToTrackingEntrySourceTypeElseCase(var InventoryProfile: Record "Inventory Profile"; var ReservationEntry: Record "Reservation Entry"; var IsHandled: Boolean)
    begin
        if InventoryProfile."Source Type" = Database::"Service Line" then begin
            ReservationEntry.SetSource(
                Database::"Service Line", InventoryProfile."Source Order Status", InventoryProfile."Source ID", InventoryProfile."Source Ref. No.", '', 0);
            IsHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Profile Offsetting", 'OnAfterDemandToInvProfile', '', false, false)]
    local procedure OnAfterDemandToInvProfile(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; var ReservEntry: Record "Reservation Entry"; var NextLineNo: Integer)
    begin
        TransServLineToProfile(InventoryProfile, Item, ReservEntry, NextLineNo);
    end;

    local procedure TransServLineToProfile(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; var TempReservationEntry: Record "Reservation Entry" temporary; var NextLineNo: Integer)
    var
        ServiceLine: Record "Service Line";
#if not CLEAN25
        InventoryProfileOfsetting: Codeunit "Inventory Profile Offsetting";
#endif
        ShouldProcess: Boolean;
    begin
        if ServiceLine.FindLinesWithItemToPlan(Item) then
            repeat
                ShouldProcess := ServiceLine."Needed by Date" <> 0D;
                OnTransServLineToProfileOnBeforeProcessLine(ServiceLine, ShouldProcess, Item);
#if not CLEAN25
                InventoryProfileOfsetting.RunOnTransServLineToProfileOnBeforeProcessLine(ServiceLine, ShouldProcess, Item);
#endif
                if ShouldProcess then begin
                    InventoryProfile.Init();
                    NextLineNo += 1;
                    InventoryProfile."Line No." := NextLineNo;
                    TransferInventoryProfileFromServLine(InventoryProfile, ServiceLine, TempReservationEntry);
                    if InventoryProfile.IsSupply then
                        InventoryProfile.ChangeSign();
                    InventoryProfile.Insert();
                end;
            until ServiceLine.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransServLineToProfileOnBeforeProcessLine(ServiceLine: Record "Service Line"; var ShouldProcess: Boolean; var Item: REcord Item)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Profile Offsetting", 'OnAfterSetDemandPriority', '', false, false)]
    local procedure OnAfterSetDemandPriority(var InventoryProfile: Record "Inventory Profile")
    begin
        if InventoryProfile."Source Type" = Database::"Service Line" then
            InventoryProfile."Order Priority" := 400;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Profile Offsetting", 'OnAfterSetSupplyPriority', '', false, false)]
    local procedure OnAfterSetSupplyPriority(var InventoryProfile: Record "Inventory Profile")
    begin
        if InventoryProfile."Source Type" = Database::"Service Line" then
            InventoryProfile."Order Priority" := 300;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Profile Offsetting", 'OnForecastConsumptionOnAfterSetSalesSourceTypeFilter', '', false, false)]
    local procedure OnForecastConsumptionOnAfterSetSalesSourceTypeFilter(var DemandInventoryProfile: Record "Inventory Profile")
    begin
        DemandInventoryProfile.SetSourceTypeFilter(Database::"Service Line");
    end;
}
