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
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Req. Wksh.-Make Order", OnBeforeInsertPurchOrderLine, '', false, false)]
    local procedure CheckBeforeInsertPurchase(var RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    var
        SubcontractingManagement: Codeunit "Subcontracting Management";
    begin
        if not IsHandled then
            SubcontractingManagement.CheckNewSubcontractingPurchase(RequisitionLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Req. Wksh.-Make Order", OnBeforeInitPurchOrderLine, '', false, false)]
    local procedure CheckBeforeInitPurchase(var ReqLine: Record "Requisition Line"; var IsHandled: Boolean)
    var
        SubcontractingManagement: Codeunit "Subcontracting Management";
    begin
        if not IsHandled then
            SubcontractingManagement.CheckNewSubcontractingPurchase(ReqLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Req. Wksh.-Make Order", OnBeforePurchOrderLineInsert, '', false, false)]
    local procedure CheckBeforePurchaseLineInsert(var ReqLine: Record "Requisition Line")
    var
        SubcontractingManagement: Codeunit "Subcontracting Management";
    begin
        SubcontractingManagement.CheckNewSubcontractingPurchase(ReqLine);
    end;

#if not CLEAN28
    var
#pragma warning disable AL0432
        SubcFeatureFlagHandler: Codeunit "Subc. Feature Flag Handler";
#pragma warning restore AL0432

#endif
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Req. Wksh.-Make Order", OnBeforeCheckRequisitionLine, '', false, false)]
    local procedure CheckNewSubcontractingSuggestion(var ReqLine2: Record "Requisition Line"; SuppressCommit: Boolean; var IsHandled: Boolean)
    var
        ProductionLine: Record "Prod. Order Line";
        Routing: Record "Prod. Order Routing Line";
        WorkCenter: Record "Work Center";
    begin
#if not CLEAN28
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        if IsHandled or not IsProductionSuggestion(ReqLine2) then
            exit;
        if (ReqLine2."Ref. Order Type" = ReqLine2."Ref. Order Type"::"Prod. Order") and
           ((ReqLine2."Ref. Order Status" <> ReqLine2."Ref. Order Status"::Released) or
            (ReqLine2."Ref. Order No." <> ReqLine2."Prod. Order No."))
        then
            exit;
        if not ProductionLine.Get(ProductionLine.Status::Released, ReqLine2."Prod. Order No.", ReqLine2."Prod. Order Line No.") then
            exit;
        if (ProductionLine."Routing No." <> ReqLine2."Routing No.") or
           (ProductionLine."Routing Reference No." <> ReqLine2."Routing Reference No.")
        then
            exit;
        if not Routing.Get(Routing.Status::Released, ReqLine2."Prod. Order No.", ReqLine2."Routing Reference No.", ReqLine2."Routing No.", ReqLine2."Operation No.") then
            exit;
        if (Routing.Type <> Routing.Type::"Work Center") or
           (Routing."No." <> ReqLine2."Work Center No.") or (Routing."Work Center No." <> ReqLine2."Work Center No.")
        then
            exit;
        WorkCenter.Get(Routing."No.");
        WorkCenter.TestField("Subcontractor No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", OnGetLocationCodeOnBeforeUpdate, '', false, false)]
    local procedure PreserveProductionLocation(var RequisitionLine: Record "Requisition Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
#if not CLEAN28
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        if IsHandled then
            exit;
        if (CurrentFieldNo <> 0) and (CurrentFieldNo <> RequisitionLine.FieldNo("Vendor No.")) then
            exit;
        IsHandled := IsProductionSuggestion(RequisitionLine);
    end;

    internal procedure IsProductionSuggestion(RequisitionLine: Record "Requisition Line"): Boolean
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        if RequisitionLine.IsTemporary() or
           (RequisitionLine.Type <> RequisitionLine.Type::Item) or
           (RequisitionLine."Action Message" <> RequisitionLine."Action Message"::New) or
           (RequisitionLine."Prod. Order No." = '') or (RequisitionLine."Prod. Order Line No." = 0) or
           (RequisitionLine."Routing No." = '') or (RequisitionLine."Routing Reference No." = 0) or
           (RequisitionLine."Operation No." = '') or (RequisitionLine."Work Center No." = '')
        then
            exit(false);
        if not (RequisitionLine."Ref. Order Type" in
                [RequisitionLine."Ref. Order Type"::"Prod. Order", RequisitionLine."Ref. Order Type"::Purchase])
        then
            exit(false);
        if not ReqWkshTemplate.Get(RequisitionLine."Worksheet Template Name") then
            exit(false);
        exit(ReqWkshTemplate.Type = ReqWkshTemplate.Type::Subcontracting);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", OnAfterGetDirectCost, '', false, false)]
    local procedure OnAfterGetDirectCost(var RequisitionLine: Record "Requisition Line"; CalledByFieldNo: Integer)
    var
        SubcontractingManagement: Codeunit "Subcontracting Management";
    begin
#if not CLEAN28
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
#if not CLEAN28
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
        ProductionLine: Record "Prod. Order Line";
        WorkCenter: Record "Work Center";
        RoutingLineFound: Boolean;
    begin
        if (RequisitionLine."Ref. Order Type" <> RequisitionLine."Ref. Order Type"::"Prod. Order") and
           not ((RequisitionLine."Ref. Order Type" = RequisitionLine."Ref. Order Type"::Purchase) and
                (RequisitionLine."Action Message" = RequisitionLine."Action Message"::New) and
                (RequisitionLine."Prod. Order No." <> ''))
        then
            exit;
            
        if not WorkCenter.Get(RequisitionLine."Work Center No.") then
            exit;

        if RequisitionLine."Ref. Order Type" = RequisitionLine."Ref. Order Type"::"Prod. Order" then
            RoutingLineFound := ProdOrderRoutingLine.Get(
                RequisitionLine."Ref. Order Status", RequisitionLine."Ref. Order No.", RequisitionLine."Routing Reference No.",
                RequisitionLine."Routing No.", RequisitionLine."Operation No.")
        else
            RoutingLineFound := ProdOrderRoutingLine.Get(
                ProdOrderRoutingLine.Status::Released, RequisitionLine."Prod. Order No.", RequisitionLine."Routing Reference No.",
                RequisitionLine."Routing No.", RequisitionLine."Operation No.");
        if RoutingLineFound and (RequisitionLine."Prod. Order No." <> '') and (RequisitionLine."Prod. Order Line No." <> 0) then
            if ProductionLine.Get(ProdOrderRoutingLine.Status, RequisitionLine."Prod. Order No.", RequisitionLine."Prod. Order Line No.") then
                RoutingLineFound := (ProductionLine."Routing No." = ProdOrderRoutingLine."Routing No.") and
                    (ProductionLine."Routing Reference No." = ProdOrderRoutingLine."Routing Reference No.")
            else
                RoutingLineFound := false;
        if RoutingLineFound and
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
#if not CLEAN28
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
#if not CLEAN28
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