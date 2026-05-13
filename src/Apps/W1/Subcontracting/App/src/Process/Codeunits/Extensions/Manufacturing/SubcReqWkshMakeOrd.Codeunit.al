// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Requisition;
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

    local procedure HandleSubcontractingAfterPurchOrderLineInsert(var PurchaseLine: Record "Purchase Line"; var RequisitionLine: Record "Requisition Line")
    var
        SubcPurchaseOrderCreator: Codeunit "Subc. Purchase Order Creator";
    begin
        SubcPurchaseOrderCreator.InsertProdDescriptionOnAfterInsertPurchOrderLine(PurchaseLine, RequisitionLine);
    end;
}