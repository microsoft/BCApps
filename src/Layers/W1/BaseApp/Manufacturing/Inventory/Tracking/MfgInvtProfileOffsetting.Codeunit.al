// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Requisition;
using Microsoft.Manufacturing.Document;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Setup;
using Microsoft.Manufacturing.Setup;
using Microsoft.Inventory.Planning;
using Microsoft.Manufacturing.ProductionBOM;

codeunit 99000869 "Mfg. Invt. Profile Offsetting"
{
    Permissions = TableData "Reservation Entry" = id,
                  TableData "Prod. Order Capacity Need" = rmd;

#if not CLEAN27
    var
        InventoryProfileOffsetting: Codeunit "Inventory Profile Offsetting";
#endif

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Profile Offsetting", 'OnAfterSupplyToInvProfile', '', true, true)]
    local procedure OnAfterSupplyToInvProfile(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; var ToDate: Date; var ReservEntry: Record "Reservation Entry" temporary; var NextLineNo: Integer)
    begin
        TransProdOrderToProfile(InventoryProfile, Item, ToDate, NextLineNo, ReservEntry);
    end;

    internal procedure TransProdOrderToProfile(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; ToDate: Date; var LineNo: Integer; var TempItemTrkgEntry: Record "Reservation Entry" temporary)
    var
        ItemLedgEntry: Record Microsoft.Inventory.Ledger."Item Ledger Entry";
        ProdOrderLine: Record "Prod. Order Line";
        CapLedgEntry: Record Microsoft.Manufacturing.Capacity."Capacity Ledger Entry";
        ProdOrderComp: Record "Prod. Order Component";
        ProdOrderLineReserve: Codeunit "Prod. Order Line-Reserve";
        ShouldProcess: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeTransProdOrderToProfile(InventoryProfile, Item, ToDate, IsHandled);
#if not CLEAN27
        InventoryProfileOffsetting.RunOnBeforeTransProdOrderToProfile(InventoryProfile, Item, ToDate, IsHandled);
#endif
        if not IsHandled then
            if ProdOrderLine.FindLinesWithItemToPlan(Item, true) then
                repeat
                    ShouldProcess := ProdOrderLine."Due Date" <> 0D;
                    OnTransProdOrderToProfileOnBeforeProcessLine(ProdOrderLine, ShouldProcess);
#if not CLEAN27
                    InventoryProfileOffsetting.RunOnTransProdOrderToProfileOnBeforeProcessLine(ProdOrderLine, ShouldProcess);
#endif
                    if ShouldProcess then begin
                        InventoryProfile.Init();
                        LineNo += 1;
                        InventoryProfile."Line No." := LineNo;
                        ProdOrderLineReserve.TransferInventoryProfileFromProdOrderLine(InventoryProfile, ProdOrderLine, TempItemTrkgEntry);
                        if (ProdOrderLine."Planning Flexibility" = ProdOrderLine."Planning Flexibility"::Unlimited) and
                           (ProdOrderLine.Status = ProdOrderLine.Status::Released)
                        then begin
                            CapLedgEntry.SetCurrentKey("Order Type", "Order No.");
                            CapLedgEntry.SetRange("Order Type", CapLedgEntry."Order Type"::Production);
                            CapLedgEntry.SetRange("Order No.", ProdOrderLine."Prod. Order No.");
                            ItemLedgEntry.Reset();
                            ItemLedgEntry.SetCurrentKey("Order Type", "Order No.");
                            ItemLedgEntry.SetRange("Order Type", ItemLedgEntry."Order Type"::Production);
                            ItemLedgEntry.SetRange("Order No.", ProdOrderLine."Prod. Order No.");
                            if not (CapLedgEntry.IsEmpty() and ItemLedgEntry.IsEmpty) then
                                InventoryProfile."Planning Flexibility" := InventoryProfile."Planning Flexibility"::None
                            else begin
                                ProdOrderComp.SetRange(Status, ProdOrderLine.Status);
                                ProdOrderComp.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
                                ProdOrderComp.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
                                ProdOrderComp.SetFilter("Qty. Picked (Base)", '>0');
                                if not ProdOrderComp.IsEmpty() then
                                    InventoryProfile."Planning Flexibility" := InventoryProfile."Planning Flexibility"::None;
                            end;
                        end;

                        OnTransProdOrderToProfileOnBeforeInsertSupplyInvtProfile(InventoryProfile, ProdOrderLine);
                        InventoryProfile.InsertSupplyInvtProfile(ToDate);
                    end;
                until ProdOrderLine.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Profile Offsetting", 'OnAfterDisableRelations', '', true, true)]
    local procedure OnAfterDisableRelations(var RequisitionLine: Record "Requisition Line")
    begin
        DisableProdRelations(RequisitionLine);
    end;

    local procedure DisableProdRelations(ReqLine: Record "Requisition Line")
    var
        PlanningRtngLine: Record Microsoft.Manufacturing.Routing."Planning Routing Line";
        ProdOrderCapNeed: Record "Prod. Order Capacity Need";
    begin
        PlanningRtngLine.SetRange("Worksheet Template Name", ReqLine."Worksheet Template Name");
        PlanningRtngLine.SetRange("Worksheet Batch Name", ReqLine."Journal Batch Name");
        PlanningRtngLine.SetRange("Worksheet Line No.", ReqLine."Line No.");
        PlanningRtngLine.DeleteAll();

        ProdOrderCapNeed.SetCurrentKey("Worksheet Template Name", "Worksheet Batch Name", "Worksheet Line No.");
        ProdOrderCapNeed.SetRange("Worksheet Template Name", ReqLine."Worksheet Template Name");
        ProdOrderCapNeed.SetRange("Worksheet Batch Name", ReqLine."Journal Batch Name");
        ProdOrderCapNeed.SetRange("Worksheet Line No.", ReqLine."Line No.");
        ProdOrderCapNeed.DeleteAll();
        ProdOrderCapNeed.Reset();
        ProdOrderCapNeed.SetCurrentKey(Status, "Prod. Order No.", Active);
        ProdOrderCapNeed.SetRange(Status, ReqLine."Ref. Order Status");
        ProdOrderCapNeed.SetRange("Prod. Order No.", ReqLine."Ref. Order No.");
        ProdOrderCapNeed.SetRange(Active, true);
        ProdOrderCapNeed.ModifyAll(Active, false);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Profile Offsetting", 'OnMaintainPlanningLineOnAfterSetSourceForNotNewReqLine', '', true, true)]
    local procedure OnMaintainPlanningLineOnAfterSetSourceForNotNewReqLine(var RequisitionLine: Record "Requisition Line"; var InventoryProfile: Record "Inventory Profile")
    begin
        case InventoryProfile."Source Type" of
            Database::"Prod. Order Line":
                SetProdOrder(RequisitionLine, InventoryProfile);
        end;
    end;

    local procedure SetProdOrder(var ReqLine: Record "Requisition Line"; var InventoryProfile: Record "Inventory Profile")
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ReqLine."Ref. Order Type" := ReqLine."Ref. Order Type"::"Prod. Order";
        ReqLine."Ref. Order Status" := "Production Order Status".FromInteger(InventoryProfile."Source Order Status");
        ReqLine."Ref. Order No." := InventoryProfile."Source ID";
        ReqLine."Ref. Line No." := InventoryProfile."Source Prod. Order Line";
        ProdOrderLine.Get(ReqLine."Ref. Order Status", ReqLine."Ref. Order No.", ReqLine."Ref. Line No.");
        ReqLine.TransferFromProdOrderLine(ProdOrderLine);

        OnAfterSetProdOrder(ReqLine, ProdOrderLine, InventoryProfile);
#if not CLEAN27
        InventoryProfileOffsetting.RunOnAfterSetProdOrder(ReqLine, ProdOrderLine, InventoryProfile);
#endif
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Profile Offsetting", 'OnMaintainPlanningLineOnBeforeValidateNo', '', true, true)]
    local procedure OnMaintainPlanningLineOnBeforeValidateNo(var RequisitionLine: Record "Requisition Line"; InventoryProfile: Record "Inventory Profile"; StockkeepingUnit: Record "Stockkeeping Unit")
    begin
        case StockkeepingUnit."Replenishment System" of
            StockkeepingUnit."Replenishment System"::"Prod. Order":
                SetProdOrderRefOrderType(RequisitionLine, InventoryProfile);
        end;
    end;

    local procedure SetProdOrderRefOrderType(var ReqLine: Record "Requisition Line"; SupplyInvtProfile: Record "Inventory Profile")
    begin
        ReqLine."Ref. Order Type" := ReqLine."Ref. Order Type"::"Prod. Order";
        if ReqLine."Planning Level" > 0 then begin
            ReqLine."Ref. Order Status" := "Production Order Status".FromInteger(SupplyInvtProfile."Primary Order Status");
            ReqLine."Ref. Order No." := SupplyInvtProfile."Primary Order No.";
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Profile Offsetting", 'OnIsProdOrderPlanned', '', true, true)]
    local procedure OnIsProdOrderPlanned(var ReservEntry: Record "Reservation Entry"; var Planned: Boolean)
    begin
        Planned := IsProdOrderPlanned(ReservEntry);
    end;

    local procedure IsProdOrderPlanned(ReservationEntry: Record "Reservation Entry"): Boolean
    var
        ProdOrderComponent: Record "Prod. Order Component";
        RequisitionLine: Record "Requisition Line";
    begin
        ProdOrderComponent.SetLoadFields(Status, "Prod. Order No.", "Prod. Order Line No.");
        if not ProdOrderComponent.Get(
             ReservationEntry."Source Subtype", ReservationEntry."Source ID",
             ReservationEntry."Source Prod. Order Line", ReservationEntry."Source Ref. No.")
        then
            exit(false);

        RequisitionLine.SetRefOrderFilters(
          RequisitionLine."Ref. Order Type"::"Prod. Order", ProdOrderComponent.Status.AsInteger(),
          ProdOrderComponent."Prod. Order No.", ProdOrderComponent."Prod. Order Line No.");
        RequisitionLine.SetRange("Operation No.", '');

        exit(not RequisitionLine.IsEmpty());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Profile Offsetting", 'OnMaintainPlanningLineOnAfterValidateFieldsForNewReqLine', '', true, true)]
    local procedure OnMaintainPlanningLineOnAfterValidateFieldsForNewReqLine(var RequisitionLine: Record "Requisition Line"; InventoryProfile: Record "Inventory Profile"; StockkeepingUnit: Record "Stockkeeping Unit")
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get();
        RequisitionLine."Starting Time" := ManufacturingSetup."Normal Starting Time";
        RequisitionLine."Ending Time" := ManufacturingSetup."Normal Ending Time";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Profile Offsetting", 'OnGetComponentsAtLocationCode', '', true, true)]
    local procedure OnGetComponentsAtLocationCode(var LocationCode: Code[10])
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get();
        LocationCode := ManufacturingSetup."Components at Location";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Profile Offsetting", 'OnGetComponentsOnNewActionMessage', '', true, true)]
    local procedure OnGetComponentsOnNewActionMessage(var RequisitionLine: Record "Requisition Line")
    var
        VersionManagement: Codeunit VersionManagement;
    begin
        if RequisitionLine."Production BOM No." <> '' then
            RequisitionLine.Validate("Production BOM Version Code",
                VersionManagement.GetBOMVersion(RequisitionLine."Production BOM No.", RequisitionLine."Due Date", true));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Profile Offsetting", 'OnGetComponentsOnUpdateForActionMessage', '', true, true)]
    local procedure OnGetComponentsOnUpdateForActionMessage(var RequisitionLine: Record "Requisition Line"; sender: Codeunit "Inventory Profile Offsetting")
    var
        PlanningComponent: Record "Planning Component";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        case RequisitionLine."Ref. Order Type" of
            RequisitionLine."Ref. Order Type"::"Prod. Order":
                begin
                    ProdOrderComponent.SetRange(Status, RequisitionLine."Ref. Order Status");
                    ProdOrderComponent.SetRange("Prod. Order No.", RequisitionLine."Ref. Order No.");
                    ProdOrderComponent.SetRange("Prod. Order Line No.", RequisitionLine."Ref. Line No.");
                    if ProdOrderComponent.Find('-') then
                        repeat
                            PlanningComponent.InitFromRequisitionLine(RequisitionLine);
                            PlanningComponent.TransferFromComponent(ProdOrderComponent);
                            sender.InsertPlanningComponent(PlanningComponent);
                        until ProdOrderComponent.Next() = 0;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Profile Offsetting", 'OnGetRouting', '', true, true)]
    local procedure OnGetRouting(var RequisitionLine: Record "Requisition Line"; var sender: Codeunit "Inventory Profile Offsetting")
    begin
        GetRouting(RequisitionLine, sender);
    end;

    procedure GetRouting(var ReqLine: Record "Requisition Line"; var sender: Codeunit "Inventory Profile Offsetting")
    var
        PlanRoutingLine: Record Microsoft.Manufacturing.Routing."Planning Routing Line";
        ProdOrderRoutingLine: Record Microsoft.Manufacturing.Document."Prod. Order Routing Line";
        ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line";
        VersionMgt: Codeunit Microsoft.Manufacturing.ProductionBOM.VersionManagement;
    begin
        if ReqLine.Quantity <= 0 then
            exit;

        if (ReqLine."Action Message" = ReqLine."Action Message"::New) or
           (ReqLine."Ref. Order Type" = ReqLine."Ref. Order Type"::Purchase)
        then begin
            if ReqLine."Routing No." <> '' then
                ReqLine.Validate(ReqLine."Routing Version Code",
                  VersionMgt.GetRtngVersion(ReqLine."Routing No.", ReqLine."Due Date", true));
        end else
            if ReqLine."Ref. Order Type" = ReqLine."Ref. Order Type"::"Prod. Order" then begin
                ProdOrderLine.Get(ReqLine."Ref. Order Status", ReqLine."Ref. Order No.", ReqLine."Ref. Line No.");
                ProdOrderRoutingLine.SetRange(Status, ProdOrderLine.Status);
                ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
                ProdOrderRoutingLine.SetRange("Routing Reference No.", ProdOrderLine."Routing Reference No.");
                ProdOrderRoutingLine.SetRange("Routing No.", ProdOrderLine."Routing No.");
                sender.DisableRelations(ReqLine);
                if ProdOrderRoutingLine.Find('-') then
                    repeat
                        PlanRoutingLine.Init();
                        PlanRoutingLine."Worksheet Template Name" := ReqLine."Worksheet Template Name";
                        PlanRoutingLine."Worksheet Batch Name" := ReqLine."Journal Batch Name";
                        PlanRoutingLine."Worksheet Line No." := ReqLine."Line No.";
                        PlanRoutingLine.TransferFromProdOrderRouting(ProdOrderRoutingLine);
                        PlanRoutingLine.Insert();
                    until ProdOrderRoutingLine.Next() = 0;
                OnAfterGetRoutingFromProdOrder(ReqLine);
#if not CLEAN27
                InventoryProfileOffsetting.RunOnAfterGetRoutingFromProdOrder(ReqLine);
#endif
            end;
        OnAfterGetRouting(ReqLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Profile Offsetting", 'OnFillTempSKUForLocation', '', true, true)]
    local procedure OnFillTempSKUForLocation(var Item: Record Item; var SupplyInvtProfile: Record "Inventory Profile"; sender: Codeunit "Inventory Profile Offsetting")
    var
        InventorySetup: Record "Inventory Setup";
        ManufacturingSetup: Record "Manufacturing Setup";
        ProdOrderWarehouseMgt: Codeunit "Prod. Order Warehouse Mgt.";
        VersionManagement: Codeunit VersionManagement;
        IsHandled: Boolean;
    begin
        InventorySetup.Get();
        ManufacturingSetup.Get();
        if (not InventorySetup."Location Mandatory") and (ManufacturingSetup."Components at Location" = '') then begin
            IsHandled := false;
            OnFindCombinationOnBeforeCreateTempSKUForLocation(Item, IsHandled);
#if not CLEAN27
            InventoryProfileOffsetting.RunOnFindCombinationOnBeforeCreateTempSKUForLocation(Item, IsHandled);
#endif
            if not IsHandled then
                sender.CreateTempSKUForLocation(
                    Item."No.",
                    ProdOrderWarehouseMgt.GetLastOperationLocationCode(
                        Item."Routing No.", VersionManagement.GetRtngVersion(Item."Routing No.", SupplyInvtProfile."Due Date", true)));
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Profile Offsetting", 'OnBeforeMatchAttributes', '', true, true)]
    local procedure CheckDemandAndSupplyQuantityAreEqual(var SupplyInvtProfile: Record "Inventory Profile"; var DemandInvtProfile: Record "Inventory Profile"; var SkipMatchingAttributes: Boolean)
    var
        TotalDemandQty: Decimal;
        TotalSupplyQty: Decimal;
    begin
        if (SupplyInvtProfile."Source Type" <> 5406) or // Database::"Prod. Order Line"
           (DemandInvtProfile."Source Type" <> 5407) // Database::"Prod. Order Component"
        then begin
            SkipMatchingAttributes := false;
            exit;
        end;

        DemandInvtProfile.ReadIsolation(IsolationLevel::ReadUncommitted);
        DemandInvtProfile.CalcSums(Quantity);
        TotalDemandQty := DemandInvtProfile.Quantity;

        if (TotalDemandQty <= 0) then begin
            SkipMatchingAttributes := false;
            exit;
        end;

        SupplyInvtProfile.ReadIsolation(IsolationLevel::ReadUncommitted);
        SupplyInvtProfile.CalcSums(Quantity);
        TotalSupplyQty := SupplyInvtProfile.Quantity;

        if TotalSupplyQty = TotalDemandQty then
            SkipMatchingAttributes := true;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransProdOrderToProfile(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; ToDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransProdOrderToProfileOnBeforeProcessLine(ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; var ShouldProcess: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetProdOrder(var ReqLine: Record "Requisition Line"; var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; var InventoryProfile: Record "Inventory Profile")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRoutingFromProdOrder(var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindCombinationOnBeforeCreateTempSKUForLocation(var Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransProdOrderToProfileOnBeforeInsertSupplyInvtProfile(var InventoryProfile: Record "Inventory Profile"; ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRouting(var RequisitionLine: Record "Requisition Line")
    begin
    end;
}
