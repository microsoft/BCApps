// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Activity;

using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Document;
using Microsoft.Warehouse.Request;
using System.Telemetry;

codeunit 99000899 "Mfg. Create Invt.Pick/Movement"
{
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
#if not CLEAN27
        CreateInventoryPickMovement: Codeunit "Create Inventory Pick/Movement";
#endif
        ProdAsmJobWhseHandlingTelemetryCategoryTok: Label 'Prod/Asm/Project Whse. Handling', Locked = true;
        ProdAsmJobWhseHandlingTelemetryTok: Label 'Prod/Asm/Project Whse. Handling in used for warehouse pick.', Locked = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Inventory Pick/Movement", 'OnGetSourceDocHeaderFromWhseRequest', '', true, true)]
    local procedure OnGetSourceDocHeaderFromWhseRequest(var WarehouseRequest: Record "Warehouse Request"; var SourceDocRecRef: RecordRef; var PostingDate: Date; var RecordExists: Boolean; var SourceDocRecordVar: Variant);
    var
        ProductionOrder: Record "Production Order";
    begin
        case WarehouseRequest."Source Document" of
            WarehouseRequest."Source Document"::"Prod. Consumption":
                begin
                    RecordExists := ProductionOrder.Get(WarehouseRequest."Source Subtype", WarehouseRequest."Source No.");
                    PostingDate := WorkDate();
                    SourceDocRecordVar := ProductionOrder;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Inventory Pick/Movement", 'OnCheckSourceDocForWhseRequest', '', true, true)]
    local procedure OnCheckSourceDocForWhseRequest(
        var WarehouseRequest: Record "Warehouse Request"; var SourceDocRecordVar: Variant; var Result: Boolean;
        var WhseActivHeader: Record "Warehouse Activity Header"; var WarehouseSourceFilter: Record "Warehouse Source Filter";
        CheckLineExist: Boolean; ApplyAdditionalSourceDocFilters: Boolean; IsInvtMovement: Boolean; var IsHandled: Boolean)
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        case WarehouseRequest."Source Document" of
            WarehouseRequest."Source Document"::"Prod. Consumption":
                begin
                    Result :=
                        SetFilterProductionLine(
                            ProdOrderComponent, SourceDocRecordVar, WhseActivHeader, WarehouseSourceFilter, CheckLineExist, ApplyAdditionalSourceDocFilters, IsInvtMovement);
                    IsHandled := true;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Inventory Pick/Movement", 'OnCreatePickOrMoveFromWhseRequest', '', true, true)]
    local procedure OnCreatePickOrMoveFromWhseRequest(
        var WarehouseRequest: Record "Warehouse Request"; SourceDocRecRef: RecordRef; var LineCreated: Boolean; var SourceDocRecVar: Variant;
        var WhseActivityHeader: Record "Warehouse Activity Header"; var WarehouseSourceFilter: Record "Warehouse Source Filter";
        CheckLineExist: Boolean; ApplySourceFilters: Boolean; IsInvtMovement: Boolean; ReservedFromStock: Enum "Reservation From Stock";
        sender: Codeunit "Create Inventory Pick/Movement")
    begin
        case WarehouseRequest."Source Document" of
            WarehouseRequest."Source Document"::"Prod. Consumption":
                CreatePickOrMoveFromProduction(
                    SourceDocRecVar, WhseActivityHeader, WarehouseSourceFilter, CheckLineExist, ApplySourceFilters, IsInvtMovement, ReservedFromStock, sender);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Inventory Pick/Movement", 'OnAutoCreatePickOrMoveFromWhseRequest', '', true, true)]
    local procedure OnAutoCreatePickOrMoveFromWhseRequest(
        var WarehouseRequest: Record "Warehouse Request"; SourceDocRecRef: RecordRef; var LineCreated: Boolean; var SourceDocRecVar: Variant;
        var WhseActivityHeader: Record "Warehouse Activity Header"; var WarehouseSourceFilter: Record "Warehouse Source Filter";
        CheckLineExist: Boolean; ApplyAdditionalSourceDocFilters: Boolean; IsInvtMovement: Boolean;
        ReservedFromStock: Enum "Reservation From Stock"; var sender: Codeunit "Create Inventory Pick/Movement")
    begin
        case WarehouseRequest."Source Document" of
            WarehouseRequest."Source Document"::"Prod. Consumption":
                CreatePickOrMoveFromProduction(
                    SourceDocRecVar, WhseActivityHeader, WarehouseSourceFilter, CheckLineExist, ApplyAdditionalSourceDocFilters, IsInvtMovement, ReservedFromStock, sender);
        end;
    end;

    local procedure CreatePickOrMoveFromProduction(ProductionOrderVar: Variant; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var WarehouseSourceFilter: Record "Warehouse Source Filter"; CheckLineExist: Boolean; ApplySourceFilters: Boolean; IsInvtMovement: Boolean; ReservedFromStock: Enum "Reservation From Stock"; var sender: Codeunit "Create Inventory Pick/Movement")
    var
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        NewWarehouseActivityLine: Record "Warehouse Activity Line";
        RemQtyToPickBase: Decimal;
        IsHandled: Boolean;
    begin
        ProductionOrder := ProductionOrderVar;

        if not SetFilterProductionLine(ProdOrderComponent, ProductionOrder, WarehouseActivityHeader, WarehouseSourceFilter, CheckLineExist, ApplySourceFilters, IsInvtMovement) then begin
            sender.RaiseNothingToHandleMessage();
            exit;
        end;

        sender.FindNextLineNo();

        repeat
            GetLocation(Location, ProdOrderComponent."Location Code");
            if (ProdOrderComponent."Location Code" = '') or (Location."Prod. Consump. Whse. Handling" = Location."Prod. Consump. Whse. Handling"::"Inventory Pick/Movement") then begin
                if Location."Prod. Consump. Whse. Handling" = Location."Prod. Consump. Whse. Handling"::"Inventory Pick/Movement" then
                    FeatureTelemetry.LogUsage('0000KT2', ProdAsmJobWhseHandlingTelemetryCategoryTok, ProdAsmJobWhseHandlingTelemetryTok);

                IsHandled := false;
                OnBeforeCreatePickOrMoveLineFromProductionLoop(WarehouseActivityHeader, ProductionOrder, IsHandled, ProdOrderComponent);
#if not CLEAN27
                CreateInventoryPickMovement.RunOnBeforeCreatePickOrMoveLineFromProductionLoop(WarehouseActivityHeader, ProductionOrder, IsHandled, ProdOrderComponent);
#endif
                if not IsHandled and CanPickProdOrderComponent(ProdOrderComponent, ReservedFromStock) then
                    if not
                       NewWarehouseActivityLine.ActivityExists(
                        Database::"Prod. Order Component", ProdOrderComponent.Status.AsInteger(), ProdOrderComponent."Prod. Order No.", ProdOrderComponent."Prod. Order Line No.", ProdOrderComponent."Line No.", 0)
                    then begin
                        NewWarehouseActivityLine.Init();
                        NewWarehouseActivityLine."Activity Type" := WarehouseActivityHeader.Type;
                        NewWarehouseActivityLine."No." := WarehouseActivityHeader."No.";
                        if Location."Bin Mandatory" then
                            NewWarehouseActivityLine."Action Type" := NewWarehouseActivityLine."Action Type"::Take;
                        NewWarehouseActivityLine.SetSource(Database::"Prod. Order Component", ProdOrderComponent.Status.AsInteger(), ProdOrderComponent."Prod. Order No.", ProdOrderComponent."Prod. Order Line No.", ProdOrderComponent."Line No.");
                        NewWarehouseActivityLine."Location Code" := ProdOrderComponent."Location Code";
                        NewWarehouseActivityLine."Bin Code" := ProdOrderComponent."Bin Code";
                        NewWarehouseActivityLine."Item No." := ProdOrderComponent."Item No.";
                        NewWarehouseActivityLine."Variant Code" := ProdOrderComponent."Variant Code";
                        NewWarehouseActivityLine."Unit of Measure Code" := ProdOrderComponent."Unit of Measure Code";
                        NewWarehouseActivityLine."Qty. per Unit of Measure" := ProdOrderComponent."Qty. per Unit of Measure";
                        NewWarehouseActivityLine."Qty. Rounding Precision" := ProdOrderComponent."Qty. Rounding Precision";
                        NewWarehouseActivityLine."Qty. Rounding Precision (Base)" := ProdOrderComponent."Qty. Rounding Precision (Base)";
                        NewWarehouseActivityLine.Description := ProdOrderComponent.Description;
                        NewWarehouseActivityLine."Source Document" := NewWarehouseActivityLine."Source Document"::"Prod. Consumption";
                        NewWarehouseActivityLine."Due Date" := ProdOrderComponent."Due Date";
                        if WarehouseActivityHeader.Type = WarehouseActivityHeader.Type::"Invt. Pick" then
                            RemQtyToPickBase := ProdOrderComponent."Remaining Qty. (Base)"
                        else
                            RemQtyToPickBase := ProdOrderComponent."Expected Qty. (Base)" - ProdOrderComponent."Qty. Picked (Base)";
                        OnBeforeNewWhseActivLineInsertFromComp(NewWarehouseActivityLine, ProdOrderComponent, WarehouseActivityHeader, RemQtyToPickBase);
#if not CLEAN27
                        CreateInventoryPickMovement.RunOnBeforeNewWhseActivLineInsertFromComp(NewWarehouseActivityLine, ProdOrderComponent, WarehouseActivityHeader, RemQtyToPickBase);
#endif
                        ProdOrderComponent.CalcFields(ProdOrderComponent."Reserved Quantity");
                        sender.CreatePickOrMoveLine(
                            NewWarehouseActivityLine, RemQtyToPickBase, RemQtyToPickBase, ProdOrderComponent."Reserved Quantity" <> 0);
                    end;
            end;
        until ProdOrderComponent.Next() = 0;
    end;

    local procedure SetFilterProductionLine(var ProdOrderComponent: Record "Prod. Order Component"; ProductionOrder: Record "Production Order"; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var WarehouseSourceFilter: Record "Warehouse Source Filter"; CheckLineExist: Boolean; ApplySourceFilters: Boolean; IsInvtMovement: Boolean): Boolean
#if not CLEAN26
    var
        ManufacturingSetup: Record Microsoft.Manufacturing.Setup."Manufacturing Setup";
#endif
    begin
        ProdOrderComponent.SetRange(ProdOrderComponent.Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange(ProdOrderComponent."Prod. Order No.", ProductionOrder."No.");
        if not CheckLineExist then
            ProdOrderComponent.SetRange(ProdOrderComponent."Location Code", WarehouseActivityHeader."Location Code");
        ProdOrderComponent.SetRange(ProdOrderComponent."Planning Level Code", 0);
        if IsInvtMovement then begin
            ProdOrderComponent.SetFilter(ProdOrderComponent."Bin Code", '<>%1', '');
#if not CLEAN26
            if not ManufacturingSetup.IsFeatureKeyFlushingMethodManualWithoutPickEnabled() then
                ProdOrderComponent.SetFilter(ProdOrderComponent."Flushing Method", '%1|%2|%3|%4',
                  ProdOrderComponent."Flushing Method"::Manual,
                  ProdOrderComponent."Flushing Method"::"Pick + Manual",
                  ProdOrderComponent."Flushing Method"::"Pick + Forward",
                  ProdOrderComponent."Flushing Method"::"Pick + Backward")
            else
#endif
                ProdOrderComponent.SetFilter(ProdOrderComponent."Flushing Method", '%1|%2|%3',
                  ProdOrderComponent."Flushing Method"::"Pick + Manual",
                  ProdOrderComponent."Flushing Method"::"Pick + Forward",
                  ProdOrderComponent."Flushing Method"::"Pick + Backward");
        end else
#if not CLEAN26
            if not ManufacturingSetup.IsFeatureKeyFlushingMethodManualWithoutPickEnabled() then
                ProdOrderComponent.SetFilter(ProdOrderComponent."Flushing Method", '%1|%2', ProdOrderComponent."Flushing Method"::Manual, ProdOrderComponent."Flushing Method"::"Pick + Manual")
            else
#endif
                ProdOrderComponent.SetRange(ProdOrderComponent."Flushing Method", ProdOrderComponent."Flushing Method"::"Pick + Manual");
        ProdOrderComponent.SetFilter(ProdOrderComponent."Remaining Quantity", '>0');

        if ApplySourceFilters then begin
            ProdOrderComponent.SetFilter(ProdOrderComponent."Item No.", WarehouseSourceFilter.GetFilter("Item No. Filter"));
            ProdOrderComponent.SetFilter(ProdOrderComponent."Variant Code", WarehouseSourceFilter.GetFilter("Variant Code Filter"));
            ProdOrderComponent.SetFilter(ProdOrderComponent."Due Date", WarehouseSourceFilter.GetFilter("Shipment Date Filter"));
            ProdOrderComponent.SetFilter(ProdOrderComponent."Prod. Order Line No.", WarehouseSourceFilter.GetFilter("Prod. Order Line No. Filter"));
        end;

        OnBeforeFindProdOrderComp(ProdOrderComponent, ProductionOrder, WarehouseActivityHeader);
#if not CLEAN27
        CreateInventoryPickMovement.RunOnBeforeFindProdOrderComp(ProdOrderComponent, ProductionOrder, WarehouseActivityHeader);
#endif
        exit(ProdOrderComponent.Find('-'));
    end;

    local procedure CanPickProdOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; ReservedFromStock: Enum "Reservation From Stock"): Boolean
    begin
        exit(
          ProdOrderComponent.CheckIfProdOrderCompMeetsReservedFromStockSetting(Abs(ProdOrderComponent."Remaining Qty. (Base)"), ReservedFromStock));
    end;

    local procedure GetLocation(var Location: Record Location; LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Clear(Location)
        else
            if LocationCode <> Location.Code then
                Location.Get(LocationCode);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePickOrMoveLineFromProductionLoop(var WarehouseActivityHeader: Record "Warehouse Activity Header"; ProductionOrder: Record Microsoft.Manufacturing.Document."Production Order"; var IsHandled: Boolean; ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNewWhseActivLineInsertFromComp(var WarehouseActivityLine: Record "Warehouse Activity Line"; var ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component"; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var RemQtyToPickBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindProdOrderComp(var ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component"; ProductionOrder: Record Microsoft.Manufacturing.Document."Production Order"; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;
}