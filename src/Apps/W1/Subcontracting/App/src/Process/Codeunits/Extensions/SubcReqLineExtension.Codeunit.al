// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Requisition;

codeunit 99001513 "Subc. Req.Line Extension"
{
    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", OnAfterGetDirectCost, '', false, false)]
    local procedure OnAfterGetDirectCost(var RequisitionLine: Record "Requisition Line"; CalledByFieldNo: Integer)
    var
        SubcontractingManagement: Codeunit "Subcontracting Management";
    begin
        SubcontractingManagement.UpdateSubcontractorPriceForRequisitionLine(RequisitionLine);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", OnAfterValidateEvent, "Vendor No.", false, false)]
    local procedure OnAfterValidateVendorNo(var Rec: Record "Requisition Line"; var xRec: Record "Requisition Line"; CurrFieldNo: Integer)
    begin
        if (Rec.Type = Rec.Type::Item) and (Rec."No." <> '') and (Rec."Prod. Order No." <> '') then
            Rec.UpdateSubcontractorPrice();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", OnAfterValidateEvent, Quantity, false, false)]
    local procedure OnAfterValidateQuantity(var Rec: Record "Requisition Line"; var xRec: Record "Requisition Line"; CurrFieldNo: Integer)
    begin
        if (Rec.Type = Rec.Type::Item) and (Rec."No." <> '') and (Rec."Prod. Order No." <> '') then
            Rec.UpdateSubcontractorPrice();
    end;
}