// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;

codeunit 99001520 "Subc. Prod. Order Rtng. Ext."
{
    var
        CannotModifyRtngLineTransferExistsErr: Label 'You cannot change this routing line because transfer orders exist for the linked production order %1, purchase order %2.', Comment = '%1=Production Order No., %2=Purchase Order No.';
        CannotModifyRtngLineStockAtSubcErr: Label 'You cannot change this routing line because there are remaining components or WIP items transferred to the subcontractor for production order %1, purchase order %2.', Comment = '%1=Production Order No., %2=Purchase Order No.';

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Routing Line", OnBeforeDeleteEvent, '', false, false)]
    local procedure OnBeforeDeleteProdOrderRtngLine(var Rec: Record "Prod. Order Routing Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary then
            exit;

        if not RunTrigger then
            exit;

        if Rec."Transfer WIP Item" then
            CheckSubcRtngLineDocumentsExist(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Routing Line", OnAfterDeleteEvent, '', false, false)]
    local procedure OnAfterDeleteProdOrderRtngLine(var Rec: Record "Prod. Order Routing Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary then
            exit;

        if not RunTrigger then
            exit;

        HandleSubcontractingAfterRoutingLineDelete(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Routing Line", OnBeforeValidateEvent, "No.", false, false)]
    local procedure OnBeforeValidateNo(var Rec: Record "Prod. Order Routing Line"; var xRec: Record "Prod. Order Routing Line"; CurrFieldNo: Integer)
    var
        SubcontractingManagement: Codeunit "Subcontracting Management";
    begin
        if Rec.IsTemporary then
            exit;

        if CurrFieldNo <> 0 then
            if (xRec."No." <> Rec."No.") and xRec."Transfer WIP Item" then
                CheckSubcRtngLineDocumentsExist(xRec);

        if (xRec."No." <> Rec."No.") and (Rec."Routing Link Code" <> '') then
            SubcontractingManagement.UpdLinkedComponents(Rec, true);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Routing Line", OnBeforeValidateEvent, "Operation No.", false, false)]
    local procedure OnBeforeValidateOperationNo(var Rec: Record "Prod. Order Routing Line"; var xRec: Record "Prod. Order Routing Line"; CurrFieldNo: Integer)
    begin
        if Rec.IsTemporary then
            exit;

        if CurrFieldNo <> 0 then
            if (xRec."Operation No." <> Rec."Operation No.") and xRec."Transfer WIP Item" then
                CheckSubcRtngLineDocumentsExist(xRec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Routing Line", OnBeforeValidateEvent, "Routing Link Code", false, false)]
    local procedure OnBeforeValidateRoutingLinkCode(var Rec: Record "Prod. Order Routing Line"; var xRec: Record "Prod. Order Routing Line"; CurrFieldNo: Integer)
    begin
        if Rec.IsTemporary then
            exit;

        if CurrFieldNo <> 0 then
            if (xRec."Routing Link Code" <> Rec."Routing Link Code") and xRec."Transfer WIP Item" then
                CheckSubcRtngLineDocumentsExist(xRec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Routing Line", OnBeforeValidateEvent, "Type", false, false)]
    local procedure OnBeforeValidateType(var Rec: Record "Prod. Order Routing Line"; var xRec: Record "Prod. Order Routing Line"; CurrFieldNo: Integer)
    begin
        if Rec.IsTemporary then
            exit;

        if CurrFieldNo <> 0 then
            if (xRec.Type <> Rec.Type) and xRec."Transfer WIP Item" then
                CheckSubcRtngLineDocumentsExist(xRec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Routing Line", OnBeforeValidateEvent, "Transfer WIP Item", false, false)]
    local procedure OnBeforeValidateTransferWIPItem(var Rec: Record "Prod. Order Routing Line"; var xRec: Record "Prod. Order Routing Line"; CurrFieldNo: Integer)
    begin
        if Rec.IsTemporary then
            exit;

        if CurrFieldNo <> 0 then
            if (xRec."Transfer WIP Item" <> Rec."Transfer WIP Item") and xRec."Transfer WIP Item" then
                CheckSubcRtngLineDocumentsExist(xRec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Routing Line", OnAfterValidateEvent, "Routing Link Code", false, false)]
    local procedure OnAfterValidateRoutingLinkCode(var Rec: Record "Prod. Order Routing Line"; var xRec: Record "Prod. Order Routing Line"; CurrFieldNo: Integer)
    begin
        if Rec.IsTemporary then
            exit;
        HandleRoutingLinkCodeValidation(Rec, xRec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Routing Line", OnAfterValidateEvent, "Standard Task Code", false, false)]
    local procedure OnAfterValidateStandardTaskCode(var Rec: Record "Prod. Order Routing Line"; var xRec: Record "Prod. Order Routing Line"; CurrFieldNo: Integer)
    var
        SubcPriceManagement: Codeunit "Subc. Price Management";
    begin
        if Rec.IsTemporary then
            exit;
        SubcPriceManagement.GetSubcPriceList(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Routing Line", OnAfterWorkCenterTransferFields, '', false, false)]
    local procedure OnAfterWorkCenterTransferFields(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; WorkCenter: Record "Work Center")
    var
        SubcPriceManagement: Codeunit "Subc. Price Management";
    begin
        SubcPriceManagement.GetSubcPriceList(ProdOrderRoutingLine);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Routing Line", OnAfterCopyFromRoutingLine, '', false, false)]
    local procedure OnAfterCopyFromRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; RoutingLine: Record "Routing Line")
    begin
        ProdOrderRoutingLine."Transfer WIP Item" := RoutingLine."Transfer WIP Item";
        ProdOrderRoutingLine."Transfer Description" := RoutingLine."Transfer Description";
        ProdOrderRoutingLine."Transfer Description 2" := RoutingLine."Transfer Description 2";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Prod. Order Route Management", OnCalculateOnBeforeProdOrderRtngLineLoopIteration, '', false, false)]
    local procedure CheckSubcontractingOnCalculateOnBeforeProdOrderRtngLineLoopIteration(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var ProdOrderLine: Record "Prod. Order Line"; var IsHandled: Boolean)
    begin
        ProdOrderRoutingLine.CheckForSubcontractingPurchaseLineTypeMismatch();
    end;

    local procedure HandleRoutingLinkCodeValidation(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var xProdOrderRoutingLine: Record "Prod. Order Routing Line")
    var
        SubcontractingManagement: Codeunit "Subcontracting Management";
    begin
        if ProdOrderRoutingLine."Routing Link Code" <> xProdOrderRoutingLine."Routing Link Code" then
            if xProdOrderRoutingLine."Routing Link Code" <> '' then begin
                SubcontractingManagement.DelLocationLinkedComponents(xProdOrderRoutingLine, true);
                if ProdOrderRoutingLine."Routing Link Code" <> '' then
                    SubcontractingManagement.UpdLinkedComponents(ProdOrderRoutingLine, false);
            end else
                if ProdOrderRoutingLine."Routing Link Code" <> '' then
                    SubcontractingManagement.UpdLinkedComponents(ProdOrderRoutingLine, true);
    end;

    local procedure HandleSubcontractingAfterRoutingLineDelete(var ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    var
        WorkCenter: Record "Work Center";
        SubcontractingManagement: Codeunit "Subcontracting Management";
    begin
        if ProdOrderRoutingLine.Status = ProdOrderRoutingLine.Status::Released then
            if ProdOrderRoutingLine.Type = ProdOrderRoutingLine.Type::"Work Center" then begin
                WorkCenter.SetLoadFields("Subcontractor No.");
                if WorkCenter.Get(ProdOrderRoutingLine."No.") then
                    if (ProdOrderRoutingLine."Routing Link Code" <> '') and (WorkCenter."Subcontractor No." <> '') then
                        SubcontractingManagement.DelLocationLinkedComponents(ProdOrderRoutingLine, false);
            end;
    end;

    local procedure CheckSubcRtngLineDocumentsExist(ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetCurrentKey("Document Type", Type, "Prod. Order No.", "Prod. Order Line No.");
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        PurchaseLine.SetRange("Routing No.", ProdOrderRoutingLine."Routing No.");
        PurchaseLine.SetRange("Routing Reference No.", ProdOrderRoutingLine."Routing Reference No.");
        PurchaseLine.SetRange("Operation No.", ProdOrderRoutingLine."Operation No.");
        if PurchaseLine.FindSet() then
            repeat
                if HasSubcTransferForPurchLine(PurchaseLine) then
                    Error(CannotModifyRtngLineTransferExistsErr, PurchaseLine."Prod. Order No.", PurchaseLine."Document No.");
                if HasStockAtSubcLocation(PurchaseLine, ProdOrderRoutingLine) then
                    Error(CannotModifyRtngLineStockAtSubcErr, PurchaseLine."Prod. Order No.", PurchaseLine."Document No.");
            until PurchaseLine.Next() = 0;
    end;

    local procedure HasSubcTransferForPurchLine(PurchaseLine: Record "Purchase Line"): Boolean
    var
        TransferLine: Record "Transfer Line";
    begin
        TransferLine.SetRange("Subc. Purch. Order No.", PurchaseLine."Document No.");
        TransferLine.SetRange("Subc. Purch. Order Line No.", PurchaseLine."Line No.");
        TransferLine.SetRange("Subc. Prod. Order No.", PurchaseLine."Prod. Order No.");
        exit(not TransferLine.IsEmpty());
    end;

    local procedure HasStockAtSubcLocation(PurchaseLine: Record "Purchase Line"; ProdOrderRoutingLine: Record "Prod. Order Routing Line"): Boolean
    var
        ProdOrderComponent: Record "Prod. Order Component";
        SubcWIPLedgerEntry: Record "Subcontractor WIP Ledger Entry";
        SubcTransferManagement: Codeunit "Subc. Transfer Management";
        NetStockAtSubcLocation: Decimal;
    begin
        ProdOrderComponent.SetCurrentKey(Status, "Prod. Order No.", "Routing Link Code");
        ProdOrderComponent.SetRange(Status, "Production Order Status"::Released);
        ProdOrderComponent.SetRange("Prod. Order No.", PurchaseLine."Prod. Order No.");
        ProdOrderComponent.SetRange("Prod. Order Line No.", PurchaseLine."Prod. Order Line No.");
        ProdOrderComponent.SetRange("Component Supply Method", ProdOrderComponent."Component Supply Method"::"Transfer to Vendor");
        ProdOrderComponent.SetRange("Subc. Purchase Order Filter", PurchaseLine."Document No.");
        ProdOrderComponent.SetRange("Routing Link Code", ProdOrderRoutingLine."Routing Link Code");
        ProdOrderComponent.SetAutoCalcFields("Subc. Qty. transf. to Subcontr");
        if ProdOrderComponent.FindSet() then
            repeat
                if ProdOrderComponent."Subc. Qty. transf. to Subcontr" <> 0 then begin
                    NetStockAtSubcLocation := ProdOrderComponent."Subc. Qty. transf. to Subcontr";
                    NetStockAtSubcLocation -= SubcTransferManagement.CalcConsumedQtyAtSubcLocation(ProdOrderComponent);
                    if NetStockAtSubcLocation > 0 then
                        exit(true);
                end;
            until ProdOrderComponent.Next() = 0;

        SubcWIPLedgerEntry.SetCurrentKey("Prod. Order No.", "Prod. Order Status", "Prod. Order Line No.", "Routing Reference No.", "Routing No.", "Operation No.", "Location Code");
        SubcWIPLedgerEntry.SetRange("Prod. Order No.", PurchaseLine."Prod. Order No.");
        SubcWIPLedgerEntry.SetRange("Prod. Order Status", "Production Order Status"::Released);
        SubcWIPLedgerEntry.SetRange("Prod. Order Line No.", PurchaseLine."Prod. Order Line No.");
        SubcWIPLedgerEntry.SetRange("Routing Reference No.", ProdOrderRoutingLine."Routing Reference No.");
        SubcWIPLedgerEntry.SetRange("Routing No.", ProdOrderRoutingLine."Routing No.");
        SubcWIPLedgerEntry.SetRange("Operation No.", ProdOrderRoutingLine."Operation No.");
        SubcWIPLedgerEntry.SetRange("In Transit", false);
        SubcWIPLedgerEntry.CalcSums("Quantity (Base)");
        if SubcWIPLedgerEntry."Quantity (Base)" <> 0 then
            exit(true);

        exit(false);
    end;
}