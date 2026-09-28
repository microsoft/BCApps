// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Requisition;
using Microsoft.Manufacturing.Document;
using Microsoft.Purchases.Document;

codeunit 20516 "Subc. Req. Wksh. Make Ord."
{
#if not CLEAN29
    var
#pragma warning disable AL0432
        SubcFeatureFlagHandler: Codeunit "Subc. Feature Flag Handler";
#pragma warning restore AL0432

#endif
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Req. Wksh.-Make Order", OnAfterInsertPurchOrderLine, '', false, false)]
    local procedure OnAfterInsertPurchOrderLine(var PurchOrderLine: Record "Purchase Line"; var NextLineNo: Integer; var RequisitionLine: Record "Requisition Line")
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        HandleSubcontractingAfterPurchOrderLineInsert(PurchOrderLine, NextLineNo, RequisitionLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Req. Wksh.-Make Order", OnInsertPurchOrderLineOnAfterTransferFromReqLineToPurchLine, '', false, false)]
    local procedure OnInsertPurchOrderLineOnAfterTransferFromReqLineToPurchLine(var PurchOrderLine: Record "Purchase Line"; RequisitionLine: Record "Requisition Line")
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        SubcPriceManagement: Codeunit "Subc. Price Management";
        AutomaticReqLineCost: Decimal;
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        if (RequisitionLine."Prod. Order No." = '') or (RequisitionLine."Operation No." = '') then
            exit;

        AutomaticReqLineCost := SubcPriceManagement.GetAutomaticSubcCostForReqLine(RequisitionLine, ProdOrderRoutingLine);
        if RequisitionLine."Direct Unit Cost" <> AutomaticReqLineCost then
            exit;

        SubcPriceManagement.GetSubcPriceForPurchLine(PurchOrderLine, ProdOrderRoutingLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Req. Wksh.-Make Order", OnInsertPurchOrderLineOnAfterCheckInsertFinalizePurchaseOrderHeader, '', false, false)]
    local procedure OnInsertPurchOrderLineOnAfterCheckInsertFinalizePurchaseOrderHeader(var RequisitionLine: Record "Requisition Line"; var PurchaseHeader: Record "Purchase Header"; var NextLineNo: Integer)
    var
        PurchaseLineWithService: Record "Purchase Line";
        SubcPurchaseOrderCreator: Codeunit "Subc. Purchase Order Creator";
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        if RequisitionLine."Prod. Order No." = '' then
            exit;
        PurchaseLineWithService."Document Type" := PurchaseHeader."Document Type";
        PurchaseLineWithService."Document No." := PurchaseHeader."No.";
        SubcPurchaseOrderCreator.TransferSubcontractingProdOrderComp(PurchaseLineWithService, RequisitionLine, NextLineNo);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Carry Out Action", OnPurchOrderChgAndResheduleOnAfterGetPurchHeader, '', false, false)]
    local procedure OnPurchOrderChgAndResheduleOnAfterGetPurchHeader(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var RequisitionLine: Record "Requisition Line")
    var
        SubcPurchaseOrderCreator: Codeunit "Subc. Purchase Order Creator";
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        SubcPurchaseOrderCreator.TransferSubcontractingProdOrderLineAttachments(PurchaseLine, RequisitionLine);
        UpdateSubcontractingComponentPurchLines(PurchaseLine, RequisitionLine);
    end;

    local procedure HandleSubcontractingAfterPurchOrderLineInsert(var PurchaseLine: Record "Purchase Line"; var NextLineNo: Integer; var RequisitionLine: Record "Requisition Line")
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        SubcPurchaseOrderCreator: Codeunit "Subc. Purchase Order Creator";
    begin
        SubcPurchaseOrderCreator.InsertProdDescriptionOnAfterInsertPurchOrderLine(PurchaseLine, RequisitionLine);
        SubcPurchaseOrderCreator.TransferSubcontractingProdOrderLineAttachments(PurchaseLine, RequisitionLine);
        SubcPurchaseOrderCreator.InsertSubcontractingProdOrderComments(PurchaseLine, RequisitionLine, NextLineNo);
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
        TempPurchaseLineComp: Record "Purchase Line" temporary;
        PurchaseLineChanged: Boolean;
        MissingComponentPurchLineCount: Integer;
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

        PurchaseLineComp.SetRange("Document Type", PurchaseLine."Document Type");
        PurchaseLineComp.SetRange("Document No.", PurchaseLine."Document No.");
        PurchaseLineComp.SetRange(Type, "Purchase Line Type"::Item);
        PurchaseLineComp.SetRange("Subc. Prod. Order No.", RequisitionLine."Prod. Order No.");
        PurchaseLineComp.SetRange("Subc. Routing No.", RequisitionLine."Routing No.");
        PurchaseLineComp.SetRange("Subc. Rtng Reference No.", RequisitionLine."Routing Reference No.");
        PurchaseLineComp.SetRange("Subc. Operation No.", RequisitionLine."Operation No.");
        if PurchaseLineComp.FindSet() then
            repeat
                TempPurchaseLineComp := PurchaseLineComp;
                TempPurchaseLineComp.Insert();
            until PurchaseLineComp.Next() = 0;

        ProdOrderComponent.SetRange(Status, "Production Order Status"::Released);
        ProdOrderComponent.SetRange("Prod. Order No.", RequisitionLine."Prod. Order No.");
        ProdOrderComponent.SetRange("Prod. Order Line No.", RequisitionLine."Prod. Order Line No.");
        ProdOrderComponent.SetRange("Routing Link Code", ProdOrderRoutingLine."Routing Link Code");
        ProdOrderComponent.SetRange("Component Supply Method", "Component Supply Method"::"Vendor-Supplied");
        ProdOrderComponent.SetLoadFields("Item No.", "Variant Code", "Remaining Quantity", "Due Date");
        if ProdOrderComponent.FindSet() then
            repeat
                Clear(PurchaseLineChanged);
                TempPurchaseLineComp.Reset();
                TempPurchaseLineComp.SetRange("Subc. Prod. Order Line No.", ProdOrderComponent."Prod. Order Line No.");
                TempPurchaseLineComp.SetRange("Subc. Prod. Ord. Comp Line No.", ProdOrderComponent."Line No.");
                if not TempPurchaseLineComp.FindFirst() then begin
                    TempPurchaseLineComp.Reset();
                    TempPurchaseLineComp.SetRange("Subc. Prod. Ord. Comp Line No.", 0);
                    TempPurchaseLineComp.SetRange("No.", ProdOrderComponent."Item No.");
                    TempPurchaseLineComp.SetRange("Variant Code", ProdOrderComponent."Variant Code");
                end;

                if TempPurchaseLineComp.FindFirst() then begin
                    PurchaseLineComp := TempPurchaseLineComp;
                    TempPurchaseLineComp.Delete();
                    if PurchaseLineComp."Subc. Prod. Order Line No." <> ProdOrderComponent."Prod. Order Line No." then begin
                        PurchaseLineComp."Subc. Prod. Order Line No." := ProdOrderComponent."Prod. Order Line No.";
                        PurchaseLineChanged := true;
                    end;
                    if PurchaseLineComp."Subc. Prod. Ord. Comp Line No." <> ProdOrderComponent."Line No." then begin
                        PurchaseLineComp."Subc. Prod. Ord. Comp Line No." := ProdOrderComponent."Line No.";
                        PurchaseLineChanged := true;
                    end;
                    if PurchaseLineComp.Quantity <> ProdOrderComponent."Remaining Quantity" then begin
                        PurchaseLineComp.Validate(Quantity, ProdOrderComponent."Remaining Quantity");
                        PurchaseLineChanged := true;
                    end;

                    if (ProdOrderComponent."Due Date" <> 0D) and
                       (PurchaseLineComp."Subc. Prod. Ord. Comp Due Date" <> ProdOrderComponent."Due Date")
                    then begin
                        PurchaseLineComp.Validate("Expected Receipt Date", ProdOrderComponent."Due Date");
                        PurchaseLineComp."Requested Receipt Date" := PurchaseLineComp."Planned Receipt Date";
                        PurchaseLineComp."Subc. Prod. Ord. Comp Due Date" := ProdOrderComponent."Due Date";
                        PurchaseLineChanged := true;
                    end;

                    if PurchaseLineChanged then
                        PurchaseLineComp.Modify(true);
                end else
                    MissingComponentPurchLineCount += 1;
            until ProdOrderComponent.Next() = 0;

        TempPurchaseLineComp.Reset();
        LogComponentPurchaseLineMismatches(MissingComponentPurchLineCount, TempPurchaseLineComp.Count());
    end;

    local procedure LogComponentPurchaseLineMismatches(MissingComponentPurchLineCount: Integer; OrphanComponentPurchLineCount: Integer)
    var
        TelemetryDimensions: Dictionary of [Text, Text];
    begin
        if (MissingComponentPurchLineCount = 0) and (OrphanComponentPurchLineCount = 0) then
            exit;

        TelemetryDimensions.Add('Missing component purchase lines', Format(MissingComponentPurchLineCount));
        TelemetryDimensions.Add('Orphan component purchase lines', Format(OrphanComponentPurchLineCount));
        Session.LogMessage(
            '0000QZ1', ComponentPurchLineMismatchTelemetryMsg, Verbosity::Warning,
            DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, TelemetryDimensions);
    end;

    var
        ComponentPurchLineMismatchTelemetryMsg: Label 'Subcontracting component purchase-line synchronization found unmatched records.', Locked = true;
}
