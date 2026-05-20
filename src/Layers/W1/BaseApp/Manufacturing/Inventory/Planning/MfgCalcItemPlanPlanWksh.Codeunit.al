// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Planning;

using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.Document;

codeunit 99000821 "Mfg. CalcItemPlanPlanWksh"
{

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Item Plan - Plan Wksh.", 'OnAfterReqLineExternDelete', '', true, false)]
    local procedure OnAfterReqLineExternDelete(var Item: Record Item)
    var
        PlannedProdOrderLine: Record "Prod. Order Line";
        TempPlannedProdOrderLine: Record "Prod. Order Line" temporary;
    begin
        PlannedProdOrderLine.SetRange(Status, PlannedProdOrderLine.Status::Planned);
        Item.CopyFilter("Variant Filter", PlannedProdOrderLine."Variant Code");
        Item.CopyFilter("Location Filter", PlannedProdOrderLine."Location Code");
        PlannedProdOrderLine.SetRange("Item No.", Item."No.");
        OnOnAfterReqLineExternDeleteOnAfterSetPlannedProdOrderLineFilters(PlannedProdOrderLine, Item);

        PlannedProdOrderLine.SetLoadFields(Status, "Prod. Order No.", "Line No.", "Item No.");
        if PlannedProdOrderLine.FindSet() then
            repeat
                TempPlannedProdOrderLine := PlannedProdOrderLine;
                TempPlannedProdOrderLine.Insert(false);
            until PlannedProdOrderLine.Next() = 0;

        DeletePlannedProdOrderLines(TempPlannedProdOrderLine);
    end;

    /// <summary>
    /// Deletes planned production order lines and their associated production orders when applicable.
    /// </summary>
    /// <param name="TempPlannedProdOrderLine">Temporary record containing the planned production order lines to process.</param>
    local procedure DeletePlannedProdOrderLines(var TempPlannedProdOrderLine: Record "Prod. Order Line" temporary)
    var
        ProdOrderLineToDelete: Record "Prod. Order Line";
        ProductionOrderToDelete: Record "Production Order";
        TempDeletedProductionOrder: Record "Production Order" temporary;
        TempNotFoundProductionOrder: Record "Production Order" temporary;
        TempNonItemProductionOrder: Record "Production Order" temporary;
    begin
        if TempPlannedProdOrderLine.FindSet() then
            repeat
                case true of
                    TempDeletedProductionOrder.Get(TempPlannedProdOrderLine.Status, TempPlannedProdOrderLine."Prod. Order No."),
                    TempNonItemProductionOrder.Get(TempPlannedProdOrderLine.Status, TempPlannedProdOrderLine."Prod. Order No."):
                        ; // Already processed, skip
                    TempNotFoundProductionOrder.Get(TempPlannedProdOrderLine.Status, TempPlannedProdOrderLine."Prod. Order No."):
                        if ProdOrderLineToDelete.Get(TempPlannedProdOrderLine.Status, TempPlannedProdOrderLine."Prod. Order No.", TempPlannedProdOrderLine."Line No.") then
                            ProdOrderLineToDelete.Delete(true);
                    ProductionOrderToDelete.Get(TempPlannedProdOrderLine.Status, TempPlannedProdOrderLine."Prod. Order No."):
                        if (ProductionOrderToDelete."Source Type" = ProductionOrderToDelete."Source Type"::Item) and
                           (ProductionOrderToDelete."Source No." = TempPlannedProdOrderLine."Item No.")
                        then begin
                            ProductionOrderToDelete.Delete(true);
                            TempDeletedProductionOrder := ProductionOrderToDelete;
                            TempDeletedProductionOrder.Insert(false);
                        end else begin
                            TempNonItemProductionOrder := ProductionOrderToDelete;
                            TempNonItemProductionOrder.Insert(false);
                        end;
                    else begin
                        Clear(TempNotFoundProductionOrder);
                        TempNotFoundProductionOrder.Status := TempPlannedProdOrderLine.Status;
                        TempNotFoundProductionOrder."No." := TempPlannedProdOrderLine."Prod. Order No.";
                        TempNotFoundProductionOrder.Insert(false);
                        if ProdOrderLineToDelete.Get(TempPlannedProdOrderLine.Status, TempPlannedProdOrderLine."Prod. Order No.", TempPlannedProdOrderLine."Line No.") then
                            ProdOrderLineToDelete.Delete(true);
                    end;
                end;
            until TempPlannedProdOrderLine.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Item Plan - Plan Wksh.", 'OnProdOrderLineIsEmpty', '', true, false)]
    local procedure OnProdOrderLineIsEmpty(var Item: Record Item; var Result: Boolean)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange("Item No.", Item."No.");
        ProdOrderLine.SetRange("MPS Order", true);
        Result := ProdOrderLine.IsEmpty();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOnAfterReqLineExternDeleteOnAfterSetPlannedProdOrderLineFilters(var PlannedProdOrderLine: Record "Prod. Order Line"; var Item: Record Item)
    begin
    end;
}