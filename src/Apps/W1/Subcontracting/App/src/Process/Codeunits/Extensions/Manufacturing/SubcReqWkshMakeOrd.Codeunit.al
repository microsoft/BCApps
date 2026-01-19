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
        HandleSubcontractingAfterPurchOrderLineInsert(PurchOrderLine, NextLineNo, RequisitionLine);
    end;

    local procedure HandleSubcontractingAfterPurchOrderLineInsert(var PurchOrderLine: Record "Purchase Line"; var NextLineNo: Integer; var RequisitionLine: Record "Requisition Line")
    var
        EnhSubMgmt: Codeunit "Subcontracting Management";
    begin
        EnhSubMgmt.InsertProdDescriptionOnAfterInsertPurchOrderLine(PurchOrderLine, RequisitionLine);
        EnhSubMgmt.TransferSubcontractingProdOrderComp(PurchOrderLine, RequisitionLine, NextLineNo);
    end;
}