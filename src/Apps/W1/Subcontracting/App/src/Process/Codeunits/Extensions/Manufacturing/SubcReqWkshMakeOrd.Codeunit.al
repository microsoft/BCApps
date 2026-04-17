// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Requisition;
using Microsoft.Manufacturing.Document;
using Microsoft.Purchases.Document;

codeunit 99001516 "Subc. Req. Wksh. Make Ord."
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Req. Wksh.-Make Order", OnAfterInsertPurchOrderLine, '', false, false)]
    local procedure OnAfterInsertPurchOrderLine(var PurchOrderLine: Record "Purchase Line"; var NextLineNo: Integer; var RequisitionLine: Record "Requisition Line")
    begin
        HandleSubcontractingAfterPurchOrderLineInsert(PurchOrderLine, NextLineNo, RequisitionLine);
    end;

    local procedure HandleSubcontractingAfterPurchOrderLineInsert(var PurchaseLine: Record "Purchase Line"; var NextLineNo: Integer; var RequisitionLine: Record "Requisition Line")
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        SubcPurchaseOrderCreator: Codeunit "Subc. Purchase Order Creator";
    begin
        SubcPurchaseOrderCreator.InsertProdDescriptionOnAfterInsertPurchOrderLine(PurchaseLine, RequisitionLine);
        SubcPurchaseOrderCreator.TransferSubcontractingProdOrderComp(PurchaseLine, RequisitionLine, NextLineNo);

        if (RequisitionLine."Prod. Order No." <> '') and (RequisitionLine."Operation No." <> '') then begin
            ProdOrderRoutingLine.SetLoadFields("Transfer WIP Item");
            if ProdOrderRoutingLine.Get(
                "Production Order Status"::Released,
                RequisitionLine."Prod. Order No.",
                RequisitionLine."Routing Reference No.",
                RequisitionLine."Routing No.",
                RequisitionLine."Operation No.")
            then begin
                PurchaseLine."Transfer WIP Item" := ProdOrderRoutingLine."Transfer WIP Item";
                PurchaseLine.Modify();
            end;
        end;
    end;
}