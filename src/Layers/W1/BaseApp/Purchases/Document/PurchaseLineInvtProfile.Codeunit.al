// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Tracking;

codeunit 99000864 "Purchase Line Invt. Profile"
{
    // Inventory Profile
#if not CLEAN25
    var
        InventoryProfileOffsetting: Codeunit "Inventory Profile Offsetting";
#endif

    procedure TransferInventoryProfileFromPurchaseLine(var InventoryProfile: Record "Inventory Profile"; var PurchaseLine: Record "Purchase Line"; var TrackingReservationEntry: Record "Reservation Entry")
    var
        ReservationEntry: Record "Reservation Entry";
        AutoReservedQty: Decimal;
    begin
        PurchaseLine.TestField(Type, PurchaseLine.Type::Item);
        InventoryProfile.SetSource(
            Database::"Purchase Line", PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.", PurchaseLine."Line No.", '', 0);
        InventoryProfile."Item No." := PurchaseLine."No.";
        InventoryProfile."Variant Code" := PurchaseLine."Variant Code";
        InventoryProfile."Location Code" := PurchaseLine."Location Code";
        InventoryProfile."Bin Code" := PurchaseLine."Bin Code";
        PurchaseLine.SetReservationFilters(ReservationEntry);
        AutoReservedQty := InventoryProfile.TransferBindings(ReservationEntry, TrackingReservationEntry);
        PurchaseLine.CalcFields("Reserved Qty. (Base)");
        if PurchaseLine."Document Type" = PurchaseLine."Document Type"::"Return Order" then begin
            AutoReservedQty := -AutoReservedQty;
            PurchaseLine."Reserved Qty. (Base)" := -PurchaseLine."Reserved Qty. (Base)";
        end;
        InventoryProfile."Untracked Quantity" := PurchaseLine."Outstanding Qty. (Base)" - PurchaseLine."Reserved Qty. (Base)" + AutoReservedQty;
        InventoryProfile."Min. Quantity" := PurchaseLine."Reserved Qty. (Base)" - AutoReservedQty;
        InventoryProfile.Quantity := PurchaseLine.Quantity;
        InventoryProfile."Remaining Quantity" := PurchaseLine."Outstanding Quantity";
        InventoryProfile."Finished Quantity" := PurchaseLine."Quantity Received";
        InventoryProfile."Quantity (Base)" := PurchaseLine."Quantity (Base)";
        InventoryProfile."Remaining Quantity (Base)" := PurchaseLine."Outstanding Qty. (Base)";
        InventoryProfile."Unit of Measure Code" := PurchaseLine."Unit of Measure Code";
        InventoryProfile."Qty. per Unit of Measure" := PurchaseLine."Qty. per Unit of Measure";
        if PurchaseLine."Document Type" = PurchaseLine."Document Type"::"Return Order" then begin
            InventoryProfile.ChangeSign();
            InventoryProfile."Planning Flexibility" := InventoryProfile."Planning Flexibility"::None;
        end else
            InventoryProfile."Planning Flexibility" := PurchaseLine."Planning Flexibility";
        InventoryProfile.IsSupply := InventoryProfile."Untracked Quantity" >= 0;
        InventoryProfile."Due Date" := PurchaseLine."Expected Receipt Date";
        InventoryProfile."Drop Shipment" := PurchaseLine."Drop Shipment";
        InventoryProfile."Special Order" := PurchaseLine."Special Order";

        OnAfterTransferInventoryProfileFromPurchaseLine(InventoryProfile, PurchaseLine);
#if not CLEAN25
        InventoryProfile.RunOnAfterTransferFromPurchaseLine(InventoryProfile, PurchaseLine);
#endif
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferInventoryProfileFromPurchaseLine(var InventoryProfile: Record "Inventory Profile"; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"Inventory Profile", 'OnTransferToTrackingEntrySourceTypeElseCase', '', false, false)]
    local procedure OnTransferToTrackingEntrySourceTypeElseCase(var InventoryProfile: Record "Inventory Profile"; var ReservationEntry: Record "Reservation Entry"; var IsHandled: Boolean)
    begin
        if InventoryProfile."Source Type" = Database::"Purchase Line" then begin
            ReservationEntry.SetSource(
                Database::"Purchase Line", InventoryProfile."Source Order Status", InventoryProfile."Source ID", InventoryProfile."Source Ref. No.", '', 0);
            IsHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Profile Offsetting", 'OnAfterSetDemandPriority', '', false, false)]
    local procedure OnAfterSetDemandPriority(var InventoryProfile: Record "Inventory Profile")
    begin
        if InventoryProfile."Source Type" = Database::"Purchase Line" then
            InventoryProfile."Order Priority" := 200;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Profile Offsetting", 'OnAfterSetSupplyPriority', '', false, false)]
    local procedure OnAfterSetSupplyPriority(var InventoryProfile: Record "Inventory Profile")
    begin
        if InventoryProfile."Source Type" = Database::"Purchase Line" then
            InventoryProfile."Order Priority" := 500;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Profile Offsetting", 'OnAfterSupplyToInvProfile', '', false, false)]
    local procedure OnAfterSupplyToInvProfile(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; var ReservEntry: Record "Reservation Entry"; var NextLineNo: Integer; var ToDate: Date)
    begin
        TransPurchaseLineToProfile(InventoryProfile, Item, ToDate, ReservEntry, NextLineNo);
    end;

    local procedure TransPurchaseLineToProfile(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; ToDate: Date; var ReservationEntry: Record "Reservation Entry"; var NextLineNo: Integer)
    var
        PurchLine: Record "Purchase Line";
    begin
        OnBeforeTransPurchLineToProfile(InventoryProfile, Item, ToDate);
#if not CLEAN25
        InventoryProfileOffsetting.RunOnBeforeTransPurchLineToProfile(InventoryProfile, Item, ToDate);
#endif
        if PurchLine.FindLinesWithItemToPlan(Item, PurchLine."Document Type"::Order) then
            repeat
                CheckInsertPurchLineToProfile(InventoryProfile, PurchLine, ToDate, ReservationEntry, NextLineNo);
            until PurchLine.Next() = 0;

        if PurchLine.FindLinesWithItemToPlan(Item, PurchLine."Document Type"::"Return Order") then
            repeat
                CheckInsertPurchLineToProfile(InventoryProfile, PurchLine, ToDate, ReservationEntry, NextLineNo);
            until PurchLine.Next() = 0;
    end;

    local procedure CheckInsertPurchLineToProfile(var InventoryProfile: Record "Inventory Profile"; var PurchLine: Record "Purchase Line"; ToDate: Date; var ReservationEntry: Record "Reservation Entry"; var NextLineNo: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckInsertPurchLineToProfile(InventoryProfile, PurchLine, ToDate, IsHandled);
#if not CLEAN25
        InventoryProfileOffsetting.RunOnBeforeCheckInsertPurchLineToProfile(InventoryProfile, PurchLine, ToDate, IsHandled);
#endif
        if IsHandled then
            exit;

        if PurchLine."Expected Receipt Date" <> 0D then
            if not PurchLine.IsProdOrder() then
                InsertPurchLineToProfile(InventoryProfile, PurchLine, ToDate, ReservationEntry, NextLineNo);
    end;

    local procedure InsertPurchLineToProfile(var InventoryProfile: Record "Inventory Profile"; PurchLine: Record "Purchase Line"; ToDate: Date; var ReservationEntry: Record "Reservation Entry"; var NextLineNo: Integer)
    begin
        InventoryProfile.Init();
        NextLineNo += 1;
        InventoryProfile."Line No." := NextLineNo;
        TransferInventoryProfileFromPurchaseLine(InventoryProfile, PurchLine, ReservationEntry);
        if InventoryProfile."Finished Quantity" > 0 then
            InventoryProfile."Planning Flexibility" := InventoryProfile."Planning Flexibility"::None;
        InventoryProfile.InsertSupplyInvtProfile(ToDate);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransPurchLineToProfile(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; ToDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckInsertPurchLineToProfile(var InventoryProfile: Record "Inventory Profile"; var PurchLine: Record "Purchase Line"; ToDate: Date; var IsHandled: Boolean)
    begin
    end;
}
