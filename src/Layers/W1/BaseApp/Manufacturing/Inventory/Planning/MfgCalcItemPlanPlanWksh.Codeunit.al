// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Planning;

using Microsoft.Manufacturing.Document;
using Microsoft.Inventory.Item;

codeunit 99000821 "Mfg. CalcItemPlanPlanWksh"
{

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Item Plan - Plan Wksh.", 'OnAfterReqLineExternDelete', '', false, false)]
    local procedure OnAfterReqLineExternDelete(var Item: Record Item)
    var
        PlannedProdOrderLine: Record "Prod. Order Line";
        ProdOrder: Record "Production Order";
    begin
        PlannedProdOrderLine.SetCurrentKey(Status, "Item No.", "Variant Code", "Location Code");
        PlannedProdOrderLine.SetRange(Status, PlannedProdOrderLine.Status::Planned);
        Item.CopyFilter("Variant Filter", PlannedProdOrderLine."Variant Code");
        Item.CopyFilter("Location Filter", PlannedProdOrderLine."Location Code");
        PlannedProdOrderLine.SetRange("Item No.", Item."No.");
        OnOnAfterReqLineExternDeleteOnAfterSetPlannedProdOrderLineFilters(PlannedProdOrderLine, Item);
        if PlannedProdOrderLine.Find('-') then
            repeat
                if ProdOrder.Get(PlannedProdOrderLine.Status, PlannedProdOrderLine."Prod. Order No.") then begin
                    if (ProdOrder."Source Type" = ProdOrder."Source Type"::Item) and
                       (ProdOrder."Source No." = PlannedProdOrderLine."Item No.")
                    then
                        ProdOrder.Delete(true);
                end else
                    PlannedProdOrderLine.Delete(true);
            until PlannedProdOrderLine.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Item Plan - Plan Wksh.", 'OnProdOrderLineIsEmpty', '', false, false)]
    local procedure OnProdOrderLineIsEmpty(var Item: Record Item; var Result: Boolean)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetCurrentKey("Item No.");
        ProdOrderLine.SetRange("Item No.", Item."No.");
        ProdOrderLine.SetRange("MPS Order", true);
        Result := ProdOrderLine.IsEmpty();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOnAfterReqLineExternDeleteOnAfterSetPlannedProdOrderLineFilters(var PlannedProdOrderLine: Record "Prod. Order Line"; var Item: Record Item)
    begin
    end;
}