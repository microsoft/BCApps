// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Planning;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Tracking;
using Microsoft.Purchases.Document;

codeunit 1035 "Job Planning Invt. Profile"
{
    // Inventory Profile

    procedure TransferInventoryProfileFromJobPlanningLine(var InventoryProfile: Record "Inventory Profile"; var JobPlanningLine: Record "Job Planning Line"; var TrackingReservationEntry: Record "Reservation Entry")
    var
        ReservationEntry: Record "Reservation Entry";
        AutoReservedQty: Decimal;
    begin
        JobPlanningLine.TestField(Type, JobPlanningLine.Type::Item);
        InventoryProfile.SetSource(
            Database::"Job Planning Line", JobPlanningLine.Status.AsInteger(), JobPlanningLine."Job No.",
            JobPlanningLine."Job Contract Entry No.", '', 0);
        InventoryProfile."Item No." := JobPlanningLine."No.";
        InventoryProfile."Variant Code" := JobPlanningLine."Variant Code";
        InventoryProfile."Location Code" := JobPlanningLine."Location Code";
        InventoryProfile."Bin Code" := JobPlanningLine."Bin Code";
        JobPlanningLine.CalcFields("Reserved Qty. (Base)");
        JobPlanningLine.SetReservationFilters(ReservationEntry);
        AutoReservedQty := -InventoryProfile.TransferBindings(ReservationEntry, TrackingReservationEntry);
        InventoryProfile."Untracked Quantity" := JobPlanningLine."Remaining Qty. (Base)" - JobPlanningLine."Reserved Qty. (Base)" + AutoReservedQty;
        InventoryProfile.Quantity := JobPlanningLine.Quantity;
        InventoryProfile."Remaining Quantity" := JobPlanningLine."Remaining Qty.";
        InventoryProfile."Finished Quantity" := JobPlanningLine."Qty. Posted";
        InventoryProfile."Quantity (Base)" := JobPlanningLine."Quantity (Base)";
        InventoryProfile."Remaining Quantity (Base)" := JobPlanningLine."Remaining Qty. (Base)";
        InventoryProfile."Unit of Measure Code" := JobPlanningLine."Unit of Measure Code";
        InventoryProfile."Qty. per Unit of Measure" := JobPlanningLine."Qty. per Unit of Measure";
        InventoryProfile.IsSupply := InventoryProfile."Untracked Quantity" < 0;
        InventoryProfile."Due Date" := JobPlanningLine."Planning Date";
        InventoryProfile."Planning Flexibility" := InventoryProfile."Planning Flexibility"::None;

        OnAfterTransferInventoryProfileFromJobPlanningLine(InventoryProfile, JobPlanningLine);
#if not CLEAN25
        InventoryProfile.RunOnAfterTransferFromJobPlanningLine(InventoryProfile, JobPlanningLine);
#endif
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferInventoryProfileFromJobPlanningLine(var InventoryProfile: Record "Inventory Profile"; var JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"Inventory Profile", 'OnTransferToTrackingEntrySourceTypeElseCase', '', false, false)]
    local procedure OnTransferToTrackingEntrySourceTypeElseCase(var InventoryProfile: Record "Inventory Profile"; var ReservationEntry: Record "Reservation Entry"; var IsHandled: Boolean)
    begin
        if InventoryProfile."Source Type" = Database::"Job Planning Line" then begin
            ReservationEntry.SetSource(
                Database::"Job Planning Line", InventoryProfile."Source Order Status", InventoryProfile."Source ID", InventoryProfile."Source Ref. No.", '', 0);
            IsHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Profile Offsetting", 'OnAfterSetDemandPriority', '', false, false)]
    local procedure OnAfterSetDemandPriority(var InventoryProfile: Record "Inventory Profile")
    begin
        if InventoryProfile."Source Type" = Database::"Job Planning Line" then
            InventoryProfile."Order Priority" := 450;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Profile Offsetting", 'OnAfterSetSupplyPriority', '', false, false)]
    local procedure OnAfterSetSupplyPriority(var InventoryProfile: Record "Inventory Profile")
    begin
        if InventoryProfile."Source Type" = Database::"Job Planning Line" then
            InventoryProfile."Order Priority" := 230;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Profile Offsetting", 'OnAfterDemandToInvProfile', '', false, false)]
    local procedure OnAfterDemandToInvProfile(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; var ReservEntry: Record "Reservation Entry"; var NextLineNo: Integer)
    begin
        TransJobPlanningLineToProfile(InventoryProfile, Item, ReservEntry, NextLineNo);
    end;

    local procedure TransJobPlanningLineToProfile(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; var TempReservationEntry: Record "Reservation Entry" temporary; var NextLineNo: Integer)
    var
        JobPlanningLine: Record "Job Planning Line";
#if not CLEAN25
        InventoryProfileOffsetting: Codeunit "Inventory Profile Offsetting";
#endif
        ShouldProcess: Boolean;
    begin
        if JobPlanningLine.FindLinesWithItemToPlan(Item) then
            repeat
                ShouldProcess := JobPlanningLine."Planning Date" <> 0D;
                if ShouldProcess then
                    ShouldProcess := not ShouldReducePurchaseOrderReceiptQuantity(JobPlanningLine);
                OnTransJobPlanningLineToProfileOnBeforeProcessLine(JobPlanningLine, ShouldProcess);
#if not CLEAN25
                InventoryProfileOffsetting.RunOnTransJobPlanningLineToProfileOnBeforeProcessLine(JobPlanningLine, ShouldProcess);
#endif
                if ShouldProcess then begin
                    InventoryProfile.
               Init();
                    NextLineNo += 1;
                    InventoryProfile."Line No." := NextLineNo;
                    TransferInventoryProfileFromJobPlanningLine(InventoryProfile, JobPlanningLine, TempReservationEntry);
                    if InventoryProfile.IsSupply then
                        InventoryProfile.ChangeSign();
                    InventoryProfile.Insert();
                end;
            until JobPlanningLine.Next() = 0;
    end;

    local procedure ShouldReducePurchaseOrderReceiptQuantity(JobPlanningLine: Record "Job Planning Line"): Boolean
    var
        PurchaseLine: Record "Purchase Line";
    begin
        JobPlanningLine.SetPurchLineFilters(PurchaseLine);
        PurchaseLine.SetRange("No.", JobPlanningLine."No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.CalcSums("Qty. Rcd. Not Invoiced (Base)");

        exit(PurchaseLine."Qty. Rcd. Not Invoiced (Base)" = JobPlanningLine."Remaining Qty. (Base)");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransJobPlanningLineToProfileOnBeforeProcessLine(JobPlanningLine: Record "Job Planning Line"; var ShouldProcess: Boolean)
    begin
    end;
}
