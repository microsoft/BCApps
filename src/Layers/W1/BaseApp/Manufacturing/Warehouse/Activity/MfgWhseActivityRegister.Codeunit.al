// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Activity;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Document;
using Microsoft.Warehouse.Request;

codeunit 99000765 "Mfg. Whse. Activity Register"
{
    Permissions = tabledata "Production Order" = rm,
                  tabledata "Prod. Order Line" = rm;

#if not CLEAN27
    var
        WhseActivityRegister: Codeunit "Whse.-Activity-Register";
#endif

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Activity-Register", 'OnUpdateWhseDocHeaderByWhseDocumentType', '', false, false)]
    local procedure OnUpdateWhseDocHeaderByWhseDocumentType(var WarehouseActivityLine: Record "Warehouse Activity Line")
    var
        ProductionOrder: Record "Production Order";
        WhsePickRequest: Record "Whse. Pick Request";
        WhsePutAwayRequest: Record "Whse. Put-away Request";
        ItemTrackingManagement: Codeunit "Item Tracking Management";
    begin
        case WarehouseActivityLine."Whse. Document Type" of
            WarehouseActivityLine."Whse. Document Type"::Production:
                begin
                    if WarehouseActivityLine."Source Document" = WarehouseActivityLine."Source Document"::"Prod. Consumption" then
                        if WarehouseActivityLine."Action Type" <> WarehouseActivityLine."Action Type"::Take then begin
                            ProductionOrder.SetLoadFields("Completely Picked");
                            ProductionOrder.SetAutoCalcFields("Completely Picked");
                            ProductionOrder.Get(WarehouseActivityLine."Source Subtype", WarehouseActivityLine."Source No.");
                            if ProductionOrder."Completely Picked" then begin
                                WhsePickRequest.SetRange("Document Type", WhsePickRequest."Document Type"::Production);
                                WhsePickRequest.SetRange("Document No.", ProductionOrder."No.");
                                WhsePickRequest.ModifyAll("Completely Picked", true);
                                ItemTrackingManagement.DeleteWhseItemTrkgLines(
                                     Database::"Prod. Order Component", WarehouseActivityLine."Source Subtype", WarehouseActivityLine."Source No.", '', 0, 0, '', false);
                            end;
                        end;
                    if WarehouseActivityLine."Source Document" = WarehouseActivityLine."Source Document"::"Prod. Output" then
                        if WarehouseActivityLine."Action Type" <> WarehouseActivityLine."Action Type"::Place then begin
                            ProductionOrder.Get(WarehouseActivityLine."Source Subtype", WarehouseActivityLine."Source No.");
                            UpdateProductionOrderPutAwayStatus(ProductionOrder);
                            if ProductionOrder."Document Put-away Status" = ProductionOrder."Document Put-away Status"::"Completely Put Away" then begin
                                WhsePutAwayRequest.SetRange("Document Type", WhsePutAwayRequest."Document Type"::Production);
                                WhsePutAwayRequest.SetRange("Document No.", ProductionOrder."No.");
                                WhsePutAwayRequest.DeleteAll();
                                ItemTrackingManagement.DeleteWhseItemTrkgLines(
                                    Database::"Prod. Order Line", 0, ProductionOrder."No.", '', 0, 0, '', false);
                            end;
                        end;
                end;
        end;
    end;

    local procedure UpdateProductionOrderPutAwayStatus(var ProductionOrder: Record "Production Order")
    var
        NewProductionOrderPutAwayStatus: Option;
    begin
        NewProductionOrderPutAwayStatus := ProductionOrder.GetHeaderPutAwayStatus(0);
        if NewProductionOrderPutAwayStatus <> ProductionOrder."Document Put-away Status" then begin
            ProductionOrder."Document Put-away Status" := NewProductionOrderPutAwayStatus;
            ProductionOrder.Modify();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Activity-Register", 'OnCheckSourceDocumentForAvailabilityBySourceDocument', '', false, false)]
    local procedure OnCheckSourceDocumentForAvailabilityBySourceDocument(var WarehouseActivityLine: Record "Warehouse Activity Line"; var RemainingQtyBase: Decimal; var RemainingQtyUoM: Code[10]; var AllowWhseOverpick: Boolean)
    var
        Item: Record Item;
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        case WarehouseActivityLine."Source Document" of
            "Warehouse Activity Source Document"::"Prod. Consumption":
                begin
                    ProdOrderComponent.SetLoadFields("Remaining Qty. (Base)", "Unit of Measure Code");
                    ProdOrderComponent.Get(WarehouseActivityLine."Source Subtype", WarehouseActivityLine."Source No.", WarehouseActivityLine."Source Line No.", WarehouseActivityLine."Source Subline No.");
                    Item.SetLoadFields("Allow Whse. Overpick");
                    Item.Get(WarehouseActivityLine."Item No.");

                    AllowWhseOverpick := Item."Allow Whse. Overpick";
                    RemainingQtyBase := ProdOrderComponent."Remaining Qty. (Base)";
                    RemainingQtyUoM := ProdOrderComponent."Unit of Measure Code";

                    ProdOrderComponent.SetLoadFields("Remaining Qty. (Base)", "Unit of Measure Code");
                    ProdOrderComponent.Get(WarehouseActivityLine."Source Subtype", WarehouseActivityLine."Source No.", WarehouseActivityLine."Source Line No.", WarehouseActivityLine."Source Subline No.");
                    RemainingQtyBase := ProdOrderComponent."Remaining Qty. (Base)";
                    RemainingQtyUoM := ProdOrderComponent."Unit of Measure Code";
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Activity-Register", 'OnRegisterWhseItemTrkgLineOnSetDueDate', '', false, false)]
    local procedure OnRegisterWhseItemTrkgLineOnSetDueDate(WarehouseActivityLine: Record "Warehouse Activity Line"; var DueDate: Date; var QtyToRegisterBase: Decimal; WhseDocType: Enum "Warehouse Activity Document Type")
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        case WhseDocType of
            WarehouseActivityLine."Whse. Document Type"::Production:
                begin
                    ProdOrderComponent.SetLoadFields("Due Date");
                    ProdOrderComponent.Get(
                        WarehouseActivityLine."Source Subtype", WarehouseActivityLine."Source No.",
                        WarehouseActivityLine."Source Line No.", WarehouseActivityLine."Source Subline No.");
                    DueDate := ProdOrderComponent."Due Date";
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Activity-Register", 'OnRegisterWhseItemTrkgLineOnAfterSetDueDateForInvtMovement', '', false, false)]
    local procedure OnRegisterWhseItemTrkgLineOnAfterSetDueDateForInvtMovement(WarehouseActivityLine: Record "Warehouse Activity Line"; var DueDate: Date)
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        case WarehouseActivityLine."Source Type" of
            Database::"Prod. Order Component":
                begin
                    ProdOrderComponent.SetLoadFields("Due Date");
                    ProdOrderComponent.Get(
                        WarehouseActivityLine."Source Subtype", WarehouseActivityLine."Source No.",
                        WarehouseActivityLine."Source Line No.", WarehouseActivityLine."Source Subline No.");
                    DueDate := ProdOrderComponent."Due Date";
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Activity-Register", 'OnUpdateWhseSourceDocLineByDocumentType', '', false, false)]
    local procedure OnUpdateWhseSourceDocLineByDocumentType(var WarehouseActivityLine: Record "Warehouse Activity Line"; WhseDocType: Enum "Warehouse Activity Document Type")
    begin
        case WhseDocType of
            WarehouseActivityLine."Whse. Document Type"::Production:
                if WarehouseActivityLine."Source Document" = WarehouseActivityLine."Source Document"::"Prod. Consumption" then begin
                    if (WarehouseActivityLine."Action Type" <> WarehouseActivityLine."Action Type"::Take) and (WarehouseActivityLine."Breakbulk No." = 0) then
                        UpdateProdCompLine(WarehouseActivityLine);
                end else
                    if WarehouseActivityLine."Source Document" = WarehouseActivityLine."Source Document"::"Prod. Output" then
                        if (WarehouseActivityLine."Action Type" <> WarehouseActivityLine."Action Type"::Place) and (WarehouseActivityLine."Breakbulk No." = 0) then
                            UpdateProdOrderLine(WarehouseActivityLine);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Activity-Register", 'OnAfterUpdateSourceDocumentForInvtMovement', '', false, false)]
    local procedure OnAfterUpdateSourceDocumentForInvtMovement(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
        case WarehouseActivityLine."Source Document" of
            WarehouseActivityLine."Source Document"::"Prod. Consumption":
                UpdateProdCompLine(WarehouseActivityLine);
        end;
    end;

    local procedure UpdateProdCompLine(WhseActivityLine: Record "Warehouse Activity Line")
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.Get(WhseActivityLine."Source Subtype", WhseActivityLine."Source No.", WhseActivityLine."Source Line No.", WhseActivityLine."Source Subline No.");
        ProdOrderComponent."Qty. Picked (Base)" :=
          ProdOrderComponent."Qty. Picked (Base)" + WhseActivityLine."Qty. to Handle (Base)";
        if WhseActivityLine."Qty. per Unit of Measure" = ProdOrderComponent."Qty. per Unit of Measure" then
            ProdOrderComponent."Qty. Picked" := ProdOrderComponent."Qty. Picked" + WhseActivityLine."Qty. to Handle"
        else
            ProdOrderComponent."Qty. Picked" :=
              Round(ProdOrderComponent."Qty. Picked" + WhseActivityLine."Qty. to Handle (Base)" / WhseActivityLine."Qty. per Unit of Measure");
        ProdOrderComponent."Completely Picked" :=
          ProdOrderComponent."Qty. Picked" = ProdOrderComponent."Expected Quantity";
        OnBeforeProdCompLineModify(ProdOrderComponent, WhseActivityLine);
#if not CLEAN27
        WhseActivityRegister.RunOnBeforeProdCompLineModify(ProdOrderComponent, WhseActivityLine);
#endif
        ProdOrderComponent.Modify();
        OnAfterProdCompLineModify(ProdOrderComponent);
#if not CLEAN27
        WhseActivityRegister.RunOnAfterProdCompLineModify(ProdOrderComponent);
#endif
    end;

    local procedure UpdateProdOrderLine(WarehouseActivityLine: Record "Warehouse Activity Line")
    var
        ProdOrderLine: Record "Prod. Order Line";
        xProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.Get(WarehouseActivityLine."Source Subtype", WarehouseActivityLine."Source No.", WarehouseActivityLine."Source Line No.");
        xProdOrderLine := ProdOrderLine;

        ProdOrderLine."Qty. Put Away (Base)" :=
          ProdOrderLine."Qty. Put Away (Base)" + WarehouseActivityLine."Qty. to Handle (Base)";
        if WarehouseActivityLine."Qty. per Unit of Measure" = ProdOrderLine."Qty. per Unit of Measure" then
            ProdOrderLine."Qty. Put Away" := ProdOrderLine."Qty. Put Away" + WarehouseActivityLine."Qty. to Handle"
        else
            ProdOrderLine."Qty. Put Away" :=
              Round(ProdOrderLine."Qty. Put Away" + WarehouseActivityLine."Qty. to Handle (Base)" / WarehouseActivityLine."Qty. per Unit of Measure");
        ProdOrderLine."Put-away Status" := ProdOrderLine.GetLinePutAwayStatus();

        if (ProdOrderLine."Qty. Put Away (Base)" <> xProdOrderLine."Qty. Put Away (Base)") or
           (ProdOrderLine."Qty. Put Away" <> xProdOrderLine."Qty. Put Away") or
           (ProdOrderLine."Put-away Status" <> xProdOrderLine."Put-away Status")
        then
            ProdOrderLine.Modify();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Activity-Register", 'OnGetSourceLineBaseQtyByWhseActivityDocumentType', '', false, false)]
    local procedure OnGetSourceLineBaseQtyByWhseActivityDocumenttype(var WarehouseActivityLine: Record "Warehouse Activity Line"; var QtyBase: Decimal; WhseDocType: Enum "Warehouse Activity Document Type")
    begin
        case WhseDocType of
            WarehouseActivityLine."Whse. Document Type"::Production:
                QtyBase := GetSourceLineBaseQty(WarehouseActivityLine);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Activity-Register", 'OnGetSourceLineBaseQtyByWhseActivitySourceType', '', false, false)]
    local procedure OnGetSourceLineBaseQtyByWhseActivitySourceType(var WarehouseActivityLine: Record "Warehouse Activity Line"; var QtyBase: Decimal)
    begin
        case WarehouseActivityLine."Source Document" of
            WarehouseActivityLine."Source Document"::"Prod. Consumption":
                QtyBase := GetSourceLineBaseQty(WarehouseActivityLine);
        end;
    end;

    local procedure GetSourceLineBaseQty(var WarehouseActivityLine: Record "Warehouse Activity Line"): Decimal
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.SetLoadFields("Expected Qty. (Base)");
        if ProdOrderComponent.Get(
                WarehouseActivityLine."Source Subtype", WarehouseActivityLine."Source No.",
                WarehouseActivityLine."Source Line No.", WarehouseActivityLine."Source Subline No.")
        then
            exit(ProdOrderComponent."Expected Qty. (Base)");

    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Activity-Register", 'OnBeforeCheckQtyAvailToInsertBase', '', false, false)]
    local procedure OnBeforeCheckQtyAvailToInsertBase(var TempWhseActivLine: Record "Warehouse Activity Line" temporary; var QtyAvailToInsertBase: Decimal; var AllowWhseOverpick: Boolean)
    var
        Item: Record Item;
    begin
        if TempWhseActivLine."Whse. Document Type" <> TempWhseActivLine."Whse. Document Type"::Production then
            exit;
        if TempWhseActivLine."Source Type" <> Database::"Prod. Order Component" then
            exit;
        if TempWhseActivLine."Activity Type" <> TempWhseActivLine."Activity Type"::Pick then
            exit;
        if TempWhseActivLine."Source Document" <> TempWhseActivLine."Source Document"::"Prod. Consumption" then
            exit;
        if TempWhseActivLine."Source Subtype" <> TempWhseActivLine."Source Subtype"::"3" then
            exit;

        Item.SetLoadFields("Allow Whse. Overpick");
        Item.Get(TempWhseActivLine."Item No.");
        AllowWhseOverpick := Item."Allow Whse. Overpick";
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProdCompLineModify(var ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProdCompLineModify(var ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component")
    begin
    end;
}
