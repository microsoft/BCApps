// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Tracking;

codeunit 99000862 "Sales Line Invt. Profile"
{
    // Inventory Profile
#if not CLEAN25
    var
        InventoryProfileOffsetting: Codeunit "Inventory Profile Offsetting";
#endif

    procedure TransferInventoryProfileFromSalesLine(var InventoryProfile: Record "Inventory Profile"; var SalesLine: Record "Sales Line"; var TrackingReservationEntry: Record "Reservation Entry")
    var
        ReservationEntry: Record "Reservation Entry";
        AutoReservedQty: Decimal;
    begin
        SalesLine.TestField(Type, SalesLine.Type::Item);
        InventoryProfile.SetSource(
            Database::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.", '', 0);
        InventoryProfile."Item No." := SalesLine."No.";
        InventoryProfile."Variant Code" := SalesLine."Variant Code";
        InventoryProfile."Location Code" := SalesLine."Location Code";
        InventoryProfile."Bin Code" := SalesLine."Bin Code";
        SalesLine.CalcFields("Reserved Qty. (Base)");
        SalesLine.SetReservationFilters(ReservationEntry);
        AutoReservedQty := -InventoryProfile.TransferBindings(ReservationEntry, TrackingReservationEntry);
        if SalesLine."Document Type" = SalesLine."Document Type"::"Return Order" then begin
            SalesLine."Reserved Qty. (Base)" := -SalesLine."Reserved Qty. (Base)";
            AutoReservedQty := -AutoReservedQty;
        end;
        InventoryProfile."Untracked Quantity" := SalesLine."Outstanding Qty. (Base)" - SalesLine."Reserved Qty. (Base)" + AutoReservedQty;
        InventoryProfile.Quantity := SalesLine.Quantity;
        InventoryProfile."Remaining Quantity" := SalesLine."Outstanding Quantity";
        InventoryProfile."Finished Quantity" := SalesLine."Quantity Shipped";
        InventoryProfile."Quantity (Base)" := SalesLine."Quantity (Base)";
        InventoryProfile."Remaining Quantity (Base)" := SalesLine."Outstanding Qty. (Base)";
        InventoryProfile."Unit of Measure Code" := SalesLine."Unit of Measure Code";
        InventoryProfile."Qty. per Unit of Measure" := SalesLine."Qty. per Unit of Measure";
        if SalesLine."Document Type" = SalesLine."Document Type"::"Return Order" then
            InventoryProfile.ChangeSign();
        InventoryProfile.IsSupply := InventoryProfile."Untracked Quantity" < 0;
        InventoryProfile."Due Date" := SalesLine."Shipment Date";
        InventoryProfile."Planning Flexibility" := InventoryProfile."Planning Flexibility"::None;
        if SalesLine."Blanket Order No." <> '' then begin
            InventoryProfile."Sell-to Customer No." := SalesLine."Sell-to Customer No.";
            InventoryProfile."Derived from Blanket Order" := true;
            InventoryProfile."Ref. Blanket Order No." := SalesLine."Blanket Order No.";
        end;
        InventoryProfile."Drop Shipment" := SalesLine."Drop Shipment";
        InventoryProfile."Special Order" := SalesLine."Special Order";

        OnAfterTransferInventoryProfileFromSalesLine(InventoryProfile, SalesLine);
#if not CLEAN25
        InventoryProfile.RunOnAfterTransferFromSalesLine(InventoryProfile, SalesLine);
#endif
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferInventoryProfileFromSalesLine(var InventoryProfile: Record "Inventory Profile"; var SalesLine: Record "Sales Line")
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"Inventory Profile", 'OnTransferToTrackingEntrySourceTypeElseCase', '', false, false)]
    local procedure OnTransferToTrackingEntrySourceTypeElseCase(var InventoryProfile: Record "Inventory Profile"; var ReservationEntry: Record "Reservation Entry"; var IsHandled: Boolean)
    begin
        if InventoryProfile."Source Type" = Database::"Sales Line" then begin
            if InventoryProfile."Source Order Status" = 4 then begin
                // Blanket Order will be marked as Surplus
                ReservationEntry."Reservation Status" := ReservationEntry."Reservation Status"::Surplus;
                ReservationEntry."Suppressed Action Msg." := true;
            end;
            ReservationEntry.SetSource(
                Database::"Sales Line", InventoryProfile."Source Order Status", InventoryProfile."Source ID", InventoryProfile."Source Ref. No.", '', 0);
            IsHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Profile Offsetting", 'OnAfterSetDemandPriority', '', false, false)]
    local procedure OnAfterSetDemandPriority(var InventoryProfile: Record "Inventory Profile")
    begin
        if InventoryProfile."Source Type" = Database::"Sales Line" then
            case InventoryProfile."Source Order Status" of
                // Quote,Order,Invoice,Credit Memo,Blanket Order,Return Order
                1:
                    InventoryProfile."Order Priority" := 300;
                // Order
                4:
                    InventoryProfile."Order Priority" := 700;
                // Blanket Order
                5:
                    InventoryProfile."Order Priority" := 300;
            // Negative Return Order
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Profile Offsetting", 'OnAfterSetSupplyPriority', '', false, false)]
    local procedure OnAfterSetSupplyPriority(var InventoryProfile: Record "Inventory Profile")
    begin
        if InventoryProfile."Source Type" = Database::"Sales Line" then
            case InventoryProfile."Source Order Status" of
                // Quote,Order,Invoice,Credit Memo,Blanket Order,Return Order
                5:
                    InventoryProfile."Order Priority" := 200;
                // Return Order
                1:
                    InventoryProfile."Order Priority" := 200;
            // Negative Sales Order
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Profile Offsetting", 'OnAfterDemandToInvProfile', '', false, false)]
    local procedure OnAfterDemandToInvProfile(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; var ReservEntry: Record "Reservation Entry"; var NextLineNo: Integer)
    begin
        TransSalesLineToProfile(InventoryProfile, Item, ReservEntry, NextLineNo);
    end;

    local procedure TransSalesLineToProfile(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; var TempReservationEntry: Record "Reservation Entry" temporary; var NextLineNo: Integer)
    var
        SalesLine: Record "Sales Line";
        IsHandled: Boolean;
        ShouldProcess: Boolean;
    begin
        OnBeforeTransSalesLineToProfile(InventoryProfile, Item, SalesLine);
#if not CLEAN25
        InventoryProfileOffsetting.RunOnBeforeTransSalesLineToProfile(InventoryProfile, Item, SalesLine);
#endif
        if SalesLine.FindLinesWithItemToPlan(Item, SalesLine."Document Type"::Order) then
            repeat
                ShouldProcess := SalesLine."Shipment Date" <> 0D;
                OnTransSalesLineToProfileOnBeforeProcessLine(SalesLine, ShouldProcess, Item);
#if not CLEAN25
                InventoryProfileOffsetting.RunOnTransSalesLineToProfileOnBeforeProcessLine(SalesLine, ShouldProcess, Item);
#endif
                if ShouldProcess then begin
                    IsHandled := false;
                    OnAfterFindLinesWithItemToPlan(SalesLine, IsHandled, InventoryProfile, Item, NextLineNo);
#if not CLEAN25
                    InventoryProfileOffsetting.RunOnAfterFindLinesWithItemToPlan(SalesLine, IsHandled, InventoryProfile, Item, NextLineNo);
#endif
                    if not IsHandled then begin
                        InventoryProfile.Init();
                        NextLineNo += 1;
                        InventoryProfile."Line No." := NextLineNo;
                        OnTransSalesLineToProfileOnBeforeTransferFromSalesLineOrder(Item, SalesLine);
#if not CLEAN25
                        InventoryProfileOffsetting.RunOnTransSalesLineToProfileOnBeforeTransferFromSalesLineOrder(Item, SalesLine);
#endif
                        TransferInventoryProfileFromSalesLine(InventoryProfile, SalesLine, TempReservationEntry);
                        OnTransSalesLineToProfileOnAfterTransferFromSalesLineOrder(Item, SalesLine, InventoryProfile);
#if not CLEAN25
                        InventoryProfileOffsetting.RunOnTransSalesLineToProfileOnAfterTransferFromSalesLineOrder(Item, SalesLine, InventoryProfile);
#endif
                        if InventoryProfile.IsSupply then
                            InventoryProfile.ChangeSign();
                        InventoryProfile."MPS Order" := true;
                        OnTransSalesLineToProfileOnBeforeInvProfileInsert(InventoryProfile, Item, NextLineNo);
#if not CLEAN25
                        InventoryProfileOffsetting.RunOnTransSalesLineToProfileOnBeforeInvProfileInsert(InventoryProfile, Item, NextLineNo);
#endif
                        InventoryProfile.Insert();
                        OnTransSalesLineToProfileOnAfterInsertInventoryProfileFromOrder(Item, SalesLine, InventoryProfile);
#if not CLEAN25
                        InventoryProfileOffsetting.RunOnTransSalesLineToProfileOnAfterInsertInventoryProfileFromOrder(Item, SalesLine, InventoryProfile);
#endif
                    end;
                end;
            until SalesLine.Next() = 0;

        if SalesLine.FindLinesWithItemToPlan(Item, SalesLine."Document Type"::"Return Order") then
            repeat
                if SalesLine."Shipment Date" <> 0D then begin
                    IsHandled := false;
                    OnAfterFindLinesWithItemToPlan(SalesLine, IsHandled, InventoryProfile, Item, NextLineNo);
#if not CLEAN25
                    InventoryProfileOffsetting.RunOnAfterFindLinesWithItemToPlan(SalesLine, IsHandled, InventoryProfile, Item, NextLineNo);
#endif
                    if not IsHandled then begin
                        InventoryProfile.Init();
                        NextLineNo += 1;
                        InventoryProfile."Line No." := NextLineNo;
                        OnTransSalesLineToProfileOnBeforeTransferFromSalesLineReturnOrder(Item, SalesLine);
#if not CLEAN25
                        InventoryProfileOffsetting.RunOnTransSalesLineToProfileOnBeforeTransferFromSalesLineReturnOrder(Item, SalesLine);
#endif
                        TransferInventoryProfileFromSalesLine(InventoryProfile, SalesLine, TempReservationEntry);
                        OnTransSalesLineToProfileOnAfterTransferFromSalesLineReturnOrder(Item, SalesLine, InventoryProfile);
#if not CLEAN25
                        InventoryProfileOffsetting.RunOnTransSalesLineToProfileOnAfterTransferFromSalesLineReturnOrder(Item, SalesLine, InventoryProfile);
#endif
                        if InventoryProfile.IsSupply then
                            InventoryProfile.ChangeSign();
                        InventoryProfile.Insert();
                        OnTransSalesLineToProfileOnAfterInsertInventoryProfileFromReturnOrder(Item, SalesLine, InventoryProfile);
#if not CLEAN25
                        InventoryProfileOffsetting.RunOnTransSalesLineToProfileOnAfterInsertInventoryProfileFromReturnOrder(Item, SalesLine, InventoryProfile);
#endif
                    end;
                end;
            until SalesLine.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransSalesLineToProfile(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransSalesLineToProfileOnBeforeProcessLine(SalesLine: Record "Sales Line"; var ShouldProcess: Boolean; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindLinesWithItemToPlan(var SalesLine: Record "Sales Line"; var IsHandled: Boolean; var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; var LineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransSalesLineToProfileOnBeforeTransferFromSalesLineOrder(var Item: Record Item; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransSalesLineToProfileOnAfterTransferFromSalesLineOrder(var Item: Record Item; var SalesLine: Record "Sales Line"; var InventoryProfile: Record "Inventory Profile")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransSalesLineToProfileOnAfterInsertInventoryProfileFromOrder(var Item: Record Item; var SalesLine: Record "Sales Line"; var InventoryProfile: Record "Inventory Profile")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransSalesLineToProfileOnAfterInsertInventoryProfileFromReturnOrder(var Item: Record Item; var SalesLine: Record "Sales Line"; var InventoryProfile: Record "Inventory Profile")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransSalesLineToProfileOnBeforeTransferFromSalesLineReturnOrder(var Item: Record Item; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransSalesLineToProfileOnAfterTransferFromSalesLineReturnOrder(var Item: Record Item; var SalesLine: Record "Sales Line"; var InventoryProfile: Record "Inventory Profile")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransSalesLineToProfileOnBeforeInvProfileInsert(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; var LineNo: Integer)
    begin
    end;
}
