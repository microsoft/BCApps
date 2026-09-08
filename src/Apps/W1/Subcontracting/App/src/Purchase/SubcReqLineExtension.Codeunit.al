// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Requisition;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.WorkCenter;

codeunit 20513 "Subc. Req.Line Extension"
{
#if not CLEAN29
    var
#pragma warning disable AL0432
        SubcFeatureFlagHandler: Codeunit "Subc. Feature Flag Handler";
#pragma warning restore AL0432

#endif
    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", OnAfterGetDirectCost, '', false, false)]
    local procedure OnAfterGetDirectCost(var RequisitionLine: Record "Requisition Line"; CalledByFieldNo: Integer)
    var
        SubcontractingManagement: Codeunit "Subcontracting Management";
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        SubcontractingManagement.UpdateSubcontractorPriceForRequisitionLine(RequisitionLine);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", OnAfterValidateEvent, "Vendor No.", false, false)]
    local procedure OnAfterValidateVendorNo(var Rec: Record "Requisition Line"; var xRec: Record "Requisition Line"; CurrFieldNo: Integer)
    var
        SubcontractingManagement: Codeunit "Subcontracting Management";
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        if Rec.IsTemporary then
            exit;

        SubcontractingManagement.UpdateSubcontractorPriceForRequisitionLine(Rec);
        RestoreSubcontractingDescriptions(Rec);
    end;

    local procedure RestoreSubcontractingDescriptions(var RequisitionLine: Record "Requisition Line")
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        WorkCenter: Record "Work Center";
    begin
        if RequisitionLine."Ref. Order Type" <> RequisitionLine."Ref. Order Type"::"Prod. Order" then
            exit;
        if not WorkCenter.Get(RequisitionLine."Work Center No.") then
            exit;

        if ProdOrderRoutingLine.Get(
             RequisitionLine."Ref. Order Status", RequisitionLine."Ref. Order No.", RequisitionLine."Routing Reference No.",
             RequisitionLine."Routing No.", RequisitionLine."Operation No.") and
           (ProdOrderRoutingLine."Work Center No." = RequisitionLine."Work Center No.")
        then begin
            RequisitionLine.Description := ProdOrderRoutingLine.Description;
            if ProdOrderRoutingLine."Description 2" <> '' then
                RequisitionLine."Description 2" := ProdOrderRoutingLine."Description 2"
            else
                RequisitionLine."Description 2" := WorkCenter."Name 2";
            exit;
        end;

        RequisitionLine.Description := WorkCenter.Name;
        RequisitionLine."Description 2" := WorkCenter."Name 2";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", OnAfterValidateEvent, Quantity, false, false)]
    local procedure OnAfterValidateQuantity(var Rec: Record "Requisition Line"; var xRec: Record "Requisition Line"; CurrFieldNo: Integer)
    var
        SubcontractingManagement: Codeunit "Subcontracting Management";
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        if Rec.IsTemporary then
            exit;

        SubcontractingManagement.UpdateSubcontractorPriceForRequisitionLine(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Req. Wksh. Template", 'OnAfterValidateEvent', 'Recurring', true, false)]
    local procedure ReqWkshTemplateOnAfterValidateRecurring(var Rec: Record "Req. Wksh. Template")
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        if not Rec.Recurring then
            case Rec.Type of
                Rec.Type::Subcontracting:
                    Rec."Page ID" := Page::"Subc. Subcontracting Worksheet";
            end;
    end;
}
