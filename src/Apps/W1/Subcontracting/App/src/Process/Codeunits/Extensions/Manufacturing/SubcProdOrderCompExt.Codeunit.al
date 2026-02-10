// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Location;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using System.Utilities;

codeunit 99001524 "Subc. Prod. Order Comp. Ext."
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Prod. Order Comp.-Reserve", OnAfterInitFromProdOrderComp, '', false, false)]
    local procedure OnAfterInitFromProdOrderComp(ProdOrderComponent: Record "Prod. Order Component")
    begin
        ValidateSubcontractingReservationConstraints(ProdOrderComponent);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Component", OnAfterValidateEvent, "Bin Code", false, false)]
    local procedure OnAfterValidateBinCode(var Rec: Record "Prod. Order Component"; var xRec: Record "Prod. Order Component"; CurrFieldNo: Integer)
    begin
        SetOriginalBinCode(Rec, xRec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Component", OnAfterValidateEvent, "Location Code", false, false)]
    local procedure OnAfterValidateLocationCode(var Rec: Record "Prod. Order Component"; var xRec: Record "Prod. Order Component"; CurrFieldNo: Integer)
    begin
        SetOriginalLocationCode(Rec, xRec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Component", OnAfterValidateEvent, "Routing Link Code", false, false)]
    local procedure OnAfterValidateRoutingLinkCode(var Rec: Record "Prod. Order Component"; var xRec: Record "Prod. Order Component"; CurrFieldNo: Integer)
    begin
        HandleRoutingLinkCodeValidation(Rec, xRec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Component", OnBeforeValidateEvent, "Location Code", false, false)]
    local procedure OnBeforeValidateLocationCode(var Rec: Record "Prod. Order Component"; var xRec: Record "Prod. Order Component"; CurrFieldNo: Integer)
    begin
        CheckExistingSubcontractingTransferOrder(Rec, xRec, CurrFieldNo);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Component", OnBeforeValidateEvent, "Quantity per", false, false)]
    local procedure OnBeforeValidateQuantityPer(var Rec: Record "Prod. Order Component"; var xRec: Record "Prod. Order Component"; CurrFieldNo: Integer)
    begin
        CheckExistingDocumentsForSubcontracting(Rec, xRec, CurrFieldNo);
    end;

    local procedure CheckExistingPostedSubcontractingTransferOrder(ProdOrderComponent: Record "Prod. Order Component"): Boolean
    var
        TransferShipmentLine: Record "Transfer Shipment Line";
        ConfirmManagement: Codeunit "Confirm Management";
        ExistingTransferLineQst: Label 'The component has already been assigned to the posted subcontracting transfer order %1.\\Do you want to continue?', Comment = '%1=Transfer Order No';
    begin
        if ProdOrderComponent."Subcontracting Type" <> "Subcontracting Type"::Transfer then
            exit;

        TransferShipmentLine.SetRange("Prod. Order No.", ProdOrderComponent."Prod. Order No.");
        TransferShipmentLine.SetRange("Prod. Order Line No.", ProdOrderComponent."Prod. Order Line No.");
        TransferShipmentLine.SetRange("Prod. Order Comp. Line No.", ProdOrderComponent."Line No.");
        TransferShipmentLine.SetRange("Item No.", ProdOrderComponent."Item No.");
        if not TransferShipmentLine.IsEmpty() then begin
            TransferShipmentLine.SetLoadFields(SystemId);
            TransferShipmentLine.FindFirst();
            if not ConfirmManagement.GetResponse(StrSubstNo(ExistingTransferLineQst, TransferShipmentLine."Document No.")) then
                Error('');
        end;
    end;

    local procedure CheckExistingReservationOnTransferLine(ProdOrderComponent: Record "Prod. Order Component"; TransferLine: Record "Transfer Line") Result: Boolean
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetCurrentKey("Source Type", "Source Subtype", "Source ID", "Source Ref. No.", "Reservation Status");
        ReservationEntry.SetRange("Source Type", Database::"Transfer Line");
        ReservationEntry.SetRange("Source ID", TransferLine."Document No.");
        ReservationEntry.SetRange("Source Ref. No.", TransferLine."Line No.");
        ReservationEntry.SetRange("Item No.", ProdOrderComponent."Item No.");
        ReservationEntry.SetRange("Variant Code", ProdOrderComponent."Variant Code");

        Result := not ReservationEntry.IsEmpty();
        exit(Result);
    end;

    local procedure CheckExistingSubcontractingPurchaseOrder(ProdOrderComponent: Record "Prod. Order Component"): Boolean
    var
        PurchaseLine: Record "Purchase Line";
        TempPurchaseLine: Record "Purchase Line" temporary;
        ExistingPurchLineErr: Label 'You cannot change this field because the component is already assigned to subcontracting purchase order %1.\\Updating the quantity is only allowed through the purchase order.', Comment = '%1=Document No';
    begin
        if ProdOrderComponent."Subcontracting Type" <> ProdOrderComponent."Subcontracting Type"::Purchase then
            exit;

        PurchaseLine.SetRange("Prod. Order No.", ProdOrderComponent."Prod. Order No.");
        PurchaseLine.SetRange("Prod. Order Line No.", ProdOrderComponent."Prod. Order Line No.");
        if PurchaseLine.FindSet() then
            repeat
                TempPurchaseLine.Init();
                TempPurchaseLine.TransferFields(PurchaseLine);
                TempPurchaseLine.Insert();
            until PurchaseLine.Next() = 0;

        if TempPurchaseLine.FindSet() then
            repeat
                PurchaseLine.Reset();
                PurchaseLine.SetRange("Document Type", TempPurchaseLine."Document Type");
                PurchaseLine.SetRange("Document No.", TempPurchaseLine."Document No.");
                PurchaseLine.SetRange(Type, "Purchase Line Type"::Item);
                PurchaseLine.SetRange("No.", ProdOrderComponent."Item No.");
                PurchaseLine.SetRange("Prod. Order No.", '');
                PurchaseLine.SetLoadFields("Document No.");
                if PurchaseLine.FindFirst() then
                    Error(ExistingPurchLineErr, PurchaseLine."Document No.");
            until TempPurchaseLine.Next() = 0;
    end;

    local procedure CheckExistingSubcontractingTransferOrder(var ProdOrderComponent: Record "Prod. Order Component"; var xProdOrderComponent: Record "Prod. Order Component"; CurrFieldNo: Integer)
    var
        TransferLine: Record "Transfer Line";
        ExistingTransferLineQst: Label 'The component has already been assigned to the subcontracting transfer order %1.\\The quantity may only be updated via the purchase order and processing of the stock transfer.', Comment = '%1=Transfer Order No';
    begin
        if CurrFieldNo = 0 then
            exit;

        if ProdOrderComponent."Location Code" = xProdOrderComponent."Location Code" then
            exit;

        if ProdOrderComponent."Subcontracting Type" <> "Subcontracting Type"::Transfer then
            exit;

        TransferLine.SetCurrentKey("Prod. Order No.", "Routing No.", "Routing Reference No.", "Operation No.", "Subcontr. Purch. Order No.");
        TransferLine.SetRange("Prod. Order No.", ProdOrderComponent."Prod. Order No.");
        TransferLine.SetRange("Prod. Order Line No.", ProdOrderComponent."Prod. Order Line No.");
        TransferLine.SetRange("Prod. Order Comp. Line No.", ProdOrderComponent."Line No.");
        TransferLine.SetRange("Item No.", ProdOrderComponent."Item No.");
        TransferLine.SetLoadFields(SystemId);
        if TransferLine.FindFirst() then
            Error(ExistingTransferLineQst, TransferLine."Document No.");
    end;

    local procedure CheckIfProdOrderCompIsInSubcontractingOrder(ProdOrderComponent: Record "Prod. Order Component") Result: Boolean
    var
        PurchOrderNo: Code[20];
        PurchOrderLineNo: Integer;
    begin
        GetPurchOrderFromProdOrderComp(ProdOrderComponent, PurchOrderNo, PurchOrderLineNo);

        Result := PurchOrderNo <> '';
        exit(Result);
    end;

    local procedure CheckIfTransferLineOnProdOrderCompLineExists(ProdOrderComponent: Record "Prod. Order Component"; var TransferLine: Record "Transfer Line"): Boolean
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        ProdOrderLine.SetLoadFields("Routing Reference No.");
        if not ProdOrderLine.Get(ProdOrderComponent.Status, ProdOrderComponent."Prod. Order No.", ProdOrderComponent."Prod. Order Line No.") then
            exit(false);

        GetProdOrderRtngLineFromProdOrderComp(ProdOrderRoutingLine, ProdOrderComponent);

        TransferLine.SetCurrentKey("Prod. Order No.", "Prod. Order Line No.", "Routing Reference No.", "Routing No.", "Operation No.");
        TransferLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        TransferLine.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
        TransferLine.SetRange("Routing Reference No.", ProdOrderLine."Routing Reference No.");
        TransferLine.SetRange("Routing No.", ProdOrderRoutingLine."Routing No.");
        TransferLine.SetRange("Operation No.", ProdOrderRoutingLine."Operation No.");
        TransferLine.SetRange("Item No.", ProdOrderComponent."Item No.");
        TransferLine.SetRange("Variant Code", ProdOrderComponent."Variant Code");
        if TransferLine.IsEmpty() then
            exit(false);

        TransferLine.SetLoadFields(SystemId);
        TransferLine.FindFirst();
        exit(true);
    end;

    local procedure GetProdOrderRtngLineFromProdOrderComp(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ProdOrderComponent: Record "Prod. Order Component")
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetLoadFields("Routing Reference No.");
        if not ProdOrderLine.Get(ProdOrderComponent.Status, ProdOrderComponent."Prod. Order No.", ProdOrderComponent."Prod. Order Line No.") then
            exit;

        ProdOrderRoutingLine.SetRange(Status, ProdOrderLine.Status);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderRoutingLine.SetRange("Routing Reference No.", ProdOrderLine."Routing Reference No.");
        ProdOrderRoutingLine.SetRange("Routing Link Code", ProdOrderComponent."Routing Link Code");
        if ProdOrderRoutingLine.IsEmpty() then
            exit;

        ProdOrderRoutingLine.SetLoadFields(SystemId);
        ProdOrderRoutingLine.FindFirst();
    end;

    local procedure GetPurchOrderFromProdOrderComp(ProdOrderComponent: Record "Prod. Order Component"; var PurchOrderNo: Code[20]; var PurchOrderLineNo: Integer)
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        PurchaseLine: Record "Purchase Line";
    begin
        GetProdOrderRtngLineFromProdOrderComp(ProdOrderRoutingLine, ProdOrderComponent);

        PurchaseLine.SetCurrentKey("Document Type", Type, "Prod. Order No.", "Prod. Order Line No.");
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProdOrderComponent."Prod. Order No.");
        PurchaseLine.SetRange("Prod. Order Line No.", ProdOrderComponent."Prod. Order Line No.");
        PurchaseLine.SetRange("Operation No.", ProdOrderRoutingLine."Operation No.");
        if PurchaseLine.IsEmpty() then
            exit;

        PurchaseLine.FindFirst();
        PurchOrderNo := PurchaseLine."Document No.";
        PurchOrderLineNo := PurchaseLine."Line No.";
    end;

    local procedure ValidateSubcontractingReservationConstraints(var ProdOrderComponent: Record "Prod. Order Component")
    var
        TransferLine: Record "Transfer Line";
        ExistingTransferLineErr: Label 'You cannot open Tracking Specification because this component is already specified in Transfer Order %1.', Comment = '%1=Document No.';
    begin
        if not CheckIfProdOrderCompIsInSubcontractingOrder(ProdOrderComponent) then
            exit;

        if not CheckIfTransferLineOnProdOrderCompLineExists(ProdOrderComponent, TransferLine) then
            exit;

        if not CheckExistingReservationOnTransferLine(ProdOrderComponent, TransferLine) then
            exit;

        Error(ExistingTransferLineErr, TransferLine."Document No.");
    end;

    local procedure HandleRoutingLinkCodeValidation(var ProdOrderComponent: Record "Prod. Order Component"; var xProdOrderComponent: Record "Prod. Order Component")
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        StockkeepingUnit: Record "Stockkeeping Unit";
        Vendor: Record Vendor;
        PlanningGetParameters: Codeunit "Planning-Get Parameters";
        SubcontractingManagement: Codeunit "Subcontracting Management";
    begin
        if ProdOrderComponent."Subcontracting Type" = ProdOrderComponent."Subcontracting Type"::Transfer then
            exit;

        ProdOrderLine.SetLoadFields("Routing No.", "Routing Reference No.", "Item No.", "Variant Code", "Location Code");
        ProdOrderLine.Get(ProdOrderComponent.Status, ProdOrderComponent."Prod. Order No.", ProdOrderComponent."Prod. Order Line No.");
        if ProdOrderComponent."Routing Link Code" <> '' then begin
            ProdOrderRoutingLine.SetRange(Status, ProdOrderComponent.Status);
            ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrderComponent."Prod. Order No.");
            ProdOrderRoutingLine.SetRange("Routing No.", ProdOrderLine."Routing No.");
            ProdOrderRoutingLine.SetRange("Routing Reference No.", ProdOrderLine."Routing Reference No.");
            ProdOrderRoutingLine.SetRange("Routing Link Code", ProdOrderComponent."Routing Link Code");
            if ProdOrderRoutingLine.FindFirst() then begin
                ProdOrderComponent."Due Date" := ProdOrderRoutingLine."Starting Date";
                ProdOrderComponent."Due Time" := ProdOrderRoutingLine."Starting Time";
                if (ProdOrderRoutingLine.Type = ProdOrderRoutingLine.Type::"Work Center") then
                    if SubcontractingManagement.GetSubcontractor(ProdOrderRoutingLine."No.", Vendor) then
                        SubcontractingManagement.ChangeLocation_OnProdOrderComponent(ProdOrderComponent, Vendor."Subcontr. Location Code", ProdOrderComponent."Orig. Location Code", ProdOrderComponent."Orig. Bin Code");
            end;
        end else
            if xProdOrderComponent."Routing Link Code" <> '' then
                if ProdOrderComponent."Orig. Location Code" <> '' then begin
                    ProdOrderComponent.Validate("Location Code", ProdOrderComponent."Orig. Location Code");
                    ProdOrderComponent."Orig. Location Code" := '';
                    if ProdOrderComponent."Orig. Bin Code" <> '' then begin
                        ProdOrderComponent.Validate("Bin Code", ProdOrderComponent."Orig. Bin Code");
                        ProdOrderComponent."Orig. Bin Code" := '';
                    end;
                end else begin
                    PlanningGetParameters.AtSKU(
                      StockkeepingUnit,
                      ProdOrderLine."Item No.",
                      ProdOrderLine."Variant Code",
                      ProdOrderLine."Location Code");
                    ProdOrderComponent.Validate("Location Code", StockkeepingUnit."Components at Location");
                end;
    end;

    local procedure SetOriginalBinCode(var ProdOrderComponent: Record "Prod. Order Component"; var xProdOrderComponent: Record "Prod. Order Component")
    begin
        if ProdOrderComponent."Bin Code" <> xProdOrderComponent."Bin Code" then
            ProdOrderComponent."Orig. Bin Code" := xProdOrderComponent."Bin Code";
    end;

    local procedure SetOriginalLocationCode(var ProdOrderComponent: Record "Prod. Order Component"; var xProdOrderComponent: Record "Prod. Order Component")
    begin
        if (ProdOrderComponent."Location Code" <> xProdOrderComponent."Location Code") then
            ProdOrderComponent."Orig. Location Code" := xProdOrderComponent."Location Code";
    end;

    local procedure CheckExistingDocumentsForSubcontracting(var ProdOrderComponent: Record "Prod. Order Component"; var xProdOrderComponent: Record "Prod. Order Component"; CurrFieldNo: Integer)
    begin
        if CurrFieldNo = 0 then
            exit;

        if ProdOrderComponent."Quantity per" <> xProdOrderComponent."Quantity per" then begin
            CheckExistingSubcontractingTransferOrder(ProdOrderComponent, xProdOrderComponent, CurrFieldNo);
            CheckExistingPostedSubcontractingTransferOrder(ProdOrderComponent);
            CheckExistingSubcontractingPurchaseOrder(ProdOrderComponent);
        end;
    end;
}
