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
        HandleSubcontractingAfterPurchOrderLineInsert(PurchOrderLine, RequisitionLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Req. Wksh.-Make Order", OnInsertPurchOrderLineOnAfterCheckInsertFinalizePurchaseOrderHeader, '', false, false)]
    local procedure OnInsertPurchOrderLineOnAfterCheckInsertFinalizePurchaseOrderHeader(var RequisitionLine: Record "Requisition Line"; var PurchaseHeader: Record "Purchase Header"; var NextLineNo: Integer)
    var
        PurchaseLineWithService: Record "Purchase Line";
        SubcPurchaseOrderCreator: Codeunit "Subc. Purchase Order Creator";
    begin
        if RequisitionLine."Prod. Order No." = '' then
            exit;
        PurchaseLineWithService."Document Type" := PurchaseHeader."Document Type";
        PurchaseLineWithService."Document No." := PurchaseHeader."No.";
        SubcPurchaseOrderCreator.TransferSubcontractingProdOrderComp(PurchaseLineWithService, RequisitionLine, NextLineNo);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Carry Out Action", OnPurchOrderChgAndResheduleOnAfterGetPurchHeader, '', false, false)]
    local procedure OnPurchOrderChgAndResheduleOnAfterGetPurchHeader(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var RequisitionLine: Record "Requisition Line")
    begin
        UpdateSubcontractingComponentPurchLines(PurchaseLine, RequisitionLine);
    end;

    local procedure HandleSubcontractingAfterPurchOrderLineInsert(var PurchaseLine: Record "Purchase Line"; var RequisitionLine: Record "Requisition Line")
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        SubcPurchaseOrderCreator: Codeunit "Subc. Purchase Order Creator";
    begin
        SubcPurchaseOrderCreator.InsertProdDescriptionOnAfterInsertPurchOrderLine(PurchaseLine, RequisitionLine);
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

    local procedure UpdateSubcontractingComponentPurchLines(PurchaseLine: Record "Purchase Line"; RequisitionLine: Record "Requisition Line")
    var
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        PurchaseLineComp: Record "Purchase Line";
    begin
        if RequisitionLine."Prod. Order No." = '' then
            exit;
        if RequisitionLine."Operation No." = '' then
            exit;

        ProdOrderRoutingLine.SetLoadFields("Routing Link Code");
        if not ProdOrderRoutingLine.Get(
                "Production Order Status"::Released, RequisitionLine."Prod. Order No.",
                RequisitionLine."Routing Reference No.", RequisitionLine."Routing No.", RequisitionLine."Operation No.")
        then
            exit;

        ProdOrderComponent.SetRange(Status, "Production Order Status"::Released);
        ProdOrderComponent.SetRange("Prod. Order No.", RequisitionLine."Prod. Order No.");
        ProdOrderComponent.SetRange("Prod. Order Line No.", RequisitionLine."Prod. Order Line No.");
        ProdOrderComponent.SetRange("Routing Link Code", ProdOrderRoutingLine."Routing Link Code");
        ProdOrderComponent.SetRange("Component Supply Method", "Component Supply Method"::"Vendor-Supplied");
        if ProdOrderComponent.FindSet() then
            repeat
                PurchaseLineComp.SetRange("Document Type", PurchaseLine."Document Type");
                PurchaseLineComp.SetRange("Document No.", PurchaseLine."Document No.");
                PurchaseLineComp.SetRange(Type, "Purchase Line Type"::Item);
                PurchaseLineComp.SetRange("No.", ProdOrderComponent."Item No.");
                PurchaseLineComp.SetRange("Variant Code", ProdOrderComponent."Variant Code");
                PurchaseLineComp.SetRange("Subc. Prod. Order No.", ProdOrderComponent."Prod. Order No.");
                PurchaseLineComp.SetRange("Subc. Operation No.", RequisitionLine."Operation No.");
                if PurchaseLineComp.FindFirst() then
                    if PurchaseLineComp.Quantity <> ProdOrderComponent."Remaining Quantity" then begin
                        PurchaseLineComp.Validate(Quantity, ProdOrderComponent."Remaining Quantity");
                        PurchaseLineComp.Modify(true);
                    end;
            until ProdOrderComponent.Next() = 0;
    end;
}