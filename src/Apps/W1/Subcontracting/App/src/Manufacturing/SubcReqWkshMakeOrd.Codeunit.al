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

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Req. Wksh.-Make Order", OnAfterInitPurchOrderLine, '', false, false)]
    local procedure OnAfterInitPurchOrderLine(var PurchaseLine: Record "Purchase Line"; RequisitionLine: Record "Requisition Line")
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        if (RequisitionLine."Prod. Order No." = '') or (RequisitionLine."Operation No." = '') then
            exit;

        SetSubcontractingPurchaseDates(PurchaseLine, RequisitionLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Req. Wksh.-Make Order", OnBeforeCopyOrderDateFromPurchHeader, '', false, false)]
    local procedure OnBeforeCopyOrderDateFromPurchHeader(var RequisitionLine: Record "Requisition Line"; PurchOrderHeader: Record "Purchase Header"; PurchOrderLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        if (RequisitionLine."Prod. Order No." = '') or (RequisitionLine."Operation No." = '') then
            exit;

        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Req. Wksh.-Make Order", OnInsertPurchOrderLineOnAfterTransferFromReqLineToPurchLine, '', false, false)]
    local procedure OnInsertPurchOrderLineOnAfterTransferFromReqLineToPurchLine(var PurchOrderLine: Record "Purchase Line"; RequisitionLine: Record "Requisition Line")
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        SubcPriceManagement: Codeunit "Subc. Price Management";
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        if (RequisitionLine."Prod. Order No." = '') or (RequisitionLine."Operation No." = '') then
            exit;

        if not SubcPriceManagement.IsAutomaticSubcCostForReqLine(RequisitionLine, ProdOrderRoutingLine) then
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

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Carry Out Action", OnPurchOrderChgAndResheduleOnBeforePurchLineModify, '', false, false)]
    local procedure OnPurchOrderChgAndResheduleOnBeforePurchLineModify(var ReqLine: Record "Requisition Line"; var PurchLine: Record "Purchase Line")
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        if (ReqLine."Prod. Order No." = '') or (ReqLine."Operation No." = '') then
            exit;

        SetSubcontractingPurchaseDates(PurchLine, ReqLine);
    end;

    local procedure SetSubcontractingPurchaseDates(var PurchaseLine: Record "Purchase Line"; RequisitionLine: Record "Requisition Line")
    begin
        PurchaseLine.Validate("Order Date", RequisitionLine."Order Date");
        PurchaseLine."Expected Receipt Date" := RequisitionLine."Due Date";
        PurchaseLine."Requested Receipt Date" := PurchaseLine."Planned Receipt Date";
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
        SubcPurchaseOrderCreator: Codeunit "Subc. Purchase Order Creator";
        SubcNotificationMgmt: Codeunit "Subc. Notification Mgmt.";
        FoundPurchaseLineComp: Boolean;
        ShouldModifyPurchaseLine: Boolean;
        MissingComponentCount: Integer;
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
        ProdOrderComponent.SetLoadFields("Item No.", "Variant Code", "Routing Link Code", "Component Supply Method", "Remaining Quantity", "Due Date");
        if ProdOrderComponent.FindSet() then
            repeat
                SetExactComponentPurchaseLineFilters(PurchaseLineComp, ProdOrderComponent, ProdOrderRoutingLine, PurchaseLine."Document No.");
                FoundPurchaseLineComp := PurchaseLineComp.FindFirst();
                ShouldModifyPurchaseLine := false;
                if not FoundPurchaseLineComp then begin
                    FoundPurchaseLineComp := FindUniqueLegacyComponentPurchaseLine(
                        PurchaseLineComp, ProdOrderComponent, ProdOrderRoutingLine, PurchaseLine."Document No.", false);
                    if FoundPurchaseLineComp then begin
                        PurchaseLineComp."Subc. Prod. Order Line No." := RequisitionLine."Prod. Order Line No.";
                        PurchaseLineComp."Subc. Prod. Comp. Line No." := ProdOrderComponent."Line No.";
                        ShouldModifyPurchaseLine := true;
                    end;
                end;

                if FoundPurchaseLineComp then begin
                    if PurchaseLineComp.Quantity <> ProdOrderComponent."Remaining Quantity" then begin
                        PurchaseLineComp.Validate(Quantity, ProdOrderComponent."Remaining Quantity");
                        ShouldModifyPurchaseLine := true;
                    end;
                    // Old purchase lines have no source-date baseline. Preserve their dates on the first synchronization.
                    if not PurchaseLineComp."Subc. Comp. Date Initialized" then begin
                        PurchaseLineComp."Subc. Last Comp. Due Date" := ProdOrderComponent."Due Date";
                        PurchaseLineComp."Subc. Comp. Date Initialized" := true;
                        ShouldModifyPurchaseLine := true;
                    end else
                        if SubcPurchaseOrderCreator.SetVendorSuppliedComponentPurchaseDates(PurchaseLineComp, ProdOrderComponent) then
                            ShouldModifyPurchaseLine := true;
                    if ShouldModifyPurchaseLine then
                        PurchaseLineComp.Modify(true);
                end else
                    MissingComponentCount += 1;
            until ProdOrderComponent.Next() = 0;
        SubcNotificationMgmt.ShowComponentSynchronizationNotification(
            PurchaseLine."Document No.", MissingComponentCount,
            CountOrphanedComponentPurchaseLines(PurchaseLine."Document No.", ProdOrderRoutingLine));
    end;

    internal procedure SetExactComponentPurchaseLineFilters(var PurchaseLine: Record "Purchase Line"; ProdOrderComponent: Record "Prod. Order Component"; ProdOrderRoutingLine: Record "Prod. Order Routing Line"; PurchaseDocumentNo: Code[20])
    begin
        SetComponentPurchaseLineFilters(PurchaseLine, ProdOrderRoutingLine, PurchaseDocumentNo);
        PurchaseLine.SetRange("No.", ProdOrderComponent."Item No.");
        PurchaseLine.SetRange("Variant Code", ProdOrderComponent."Variant Code");
        PurchaseLine.SetRange("Subc. Prod. Order Line No.", ProdOrderComponent."Prod. Order Line No.");
        PurchaseLine.SetRange("Subc. Prod. Comp. Line No.", ProdOrderComponent."Line No.");
    end;

    local procedure SetComponentPurchaseLineFilters(var PurchaseLine: Record "Purchase Line"; ProdOrderRoutingLine: Record "Prod. Order Routing Line"; PurchaseDocumentNo: Code[20])
    begin
        PurchaseLine.Reset();
        PurchaseLine.SetRange("Document Type", "Purchase Document Type"::Order);
        if PurchaseDocumentNo <> '' then
            PurchaseLine.SetRange("Document No.", PurchaseDocumentNo);
        PurchaseLine.SetRange(Type, "Purchase Line Type"::Item);
        PurchaseLine.SetRange("Subc. Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        PurchaseLine.SetRange("Subc. Routing No.", ProdOrderRoutingLine."Routing No.");
        PurchaseLine.SetRange("Subc. Operation No.", ProdOrderRoutingLine."Operation No.");
        PurchaseLine.SetRange("Subc. Work Center No.", ProdOrderRoutingLine."Work Center No.");
    end;

    internal procedure FindUniqueLegacyComponentPurchaseLine(var PurchaseLine: Record "Purchase Line"; ProdOrderComponent: Record "Prod. Order Component"; ProdOrderRoutingLine: Record "Prod. Order Routing Line"; PurchaseDocumentNo: Code[20]; AllowExactOwner: Boolean): Boolean
    begin
        if not IsComponentOwnershipUnambiguous(ProdOrderComponent, ProdOrderRoutingLine, PurchaseDocumentNo, AllowExactOwner) then
            exit(false);

        SetExactComponentPurchaseLineFilters(PurchaseLine, ProdOrderComponent, ProdOrderRoutingLine, PurchaseDocumentNo);
        PurchaseLine.SetRange("Subc. Prod. Comp. Line No.", 0);
        PurchaseLine.SetFilter("Subc. Prod. Order Line No.", '%1|%2', ProdOrderComponent."Prod. Order Line No.", ProdOrderRoutingLine."Routing Reference No.");
        if PurchaseLine.Count() <> 1 then
            exit(false);
        exit(PurchaseLine.FindFirst());
    end;

    local procedure IsComponentOwnershipUnambiguous(ProdOrderComponent: Record "Prod. Order Component"; ProdOrderRoutingLine: Record "Prod. Order Routing Line"; PurchaseDocumentNo: Code[20]; AllowExactOwner: Boolean): Boolean
    var
        MatchingProdOrderComponent: Record "Prod. Order Component";
        ProdOrderLine: Record "Prod. Order Line";
        ExactPurchaseLine: Record "Purchase Line";
        MatchingComponentCount: Integer;
        HasExactOwner: Boolean;
    begin
        SetExactComponentPurchaseLineFilters(ExactPurchaseLine, ProdOrderComponent, ProdOrderRoutingLine, PurchaseDocumentNo);
        HasExactOwner := not ExactPurchaseLine.IsEmpty();
        if HasExactOwner and not AllowExactOwner then
            exit(false);

        // Read-only totals may include a legacy line for an exact-owned component only when no other component could own it.
        MatchingProdOrderComponent.SetRange(Status, ProdOrderComponent.Status);
        MatchingProdOrderComponent.SetRange("Prod. Order No.", ProdOrderComponent."Prod. Order No.");
        MatchingProdOrderComponent.SetRange("Routing Link Code", ProdOrderComponent."Routing Link Code");
        MatchingProdOrderComponent.SetRange("Component Supply Method", ProdOrderComponent."Component Supply Method");
        MatchingProdOrderComponent.SetRange("Item No.", ProdOrderComponent."Item No.");
        MatchingProdOrderComponent.SetRange("Variant Code", ProdOrderComponent."Variant Code");
        ProdOrderLine.SetRange(Status, ProdOrderComponent.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderComponent."Prod. Order No.");
        ProdOrderLine.SetRange("Routing Reference No.", ProdOrderRoutingLine."Routing Reference No.");
        ProdOrderLine.SetRange("Routing No.", ProdOrderRoutingLine."Routing No.");
        if ProdOrderLine.FindSet() then
            repeat
                MatchingProdOrderComponent.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
                if MatchingProdOrderComponent.FindSet() then
                    repeat
                        SetExactComponentPurchaseLineFilters(ExactPurchaseLine, MatchingProdOrderComponent, ProdOrderRoutingLine, PurchaseDocumentNo);
                        if HasExactOwner or ExactPurchaseLine.IsEmpty() then
                            MatchingComponentCount += 1;
                        if MatchingComponentCount > 1 then
                            exit(false);
                    until MatchingProdOrderComponent.Next() = 0;
            until ProdOrderLine.Next() = 0;
        exit(MatchingComponentCount = 1);
    end;

    local procedure CountOrphanedComponentPurchaseLines(PurchaseDocumentNo: Code[20]; ProdOrderRoutingLine: Record "Prod. Order Routing Line") OrphanedCount: Integer
    var
        PurchaseLine: Record "Purchase Line";
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderLine: Record "Prod. Order Line";
        HasComponent: Boolean;
    begin
        SetComponentPurchaseLineFilters(PurchaseLine, ProdOrderRoutingLine, PurchaseDocumentNo);
        if PurchaseLine.FindSet() then
            repeat
                ProdOrderComponent.Reset();
                ProdOrderComponent.SetRange(Status, ProdOrderRoutingLine.Status);
                ProdOrderComponent.SetRange("Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
                ProdOrderComponent.SetRange("Routing Link Code", ProdOrderRoutingLine."Routing Link Code");
                ProdOrderComponent.SetRange("Component Supply Method", "Component Supply Method"::"Vendor-Supplied");
                ProdOrderComponent.SetRange("Item No.", PurchaseLine."No.");
                ProdOrderComponent.SetRange("Variant Code", PurchaseLine."Variant Code");
                if PurchaseLine."Subc. Prod. Comp. Line No." <> 0 then begin
                    ProdOrderComponent.SetRange("Prod. Order Line No.", PurchaseLine."Subc. Prod. Order Line No.");
                    ProdOrderComponent.SetRange("Line No.", PurchaseLine."Subc. Prod. Comp. Line No.");
                    HasComponent := not ProdOrderComponent.IsEmpty();
                end else begin
                    HasComponent := false;
                    ProdOrderLine.Reset();
                    ProdOrderLine.SetRange(Status, ProdOrderRoutingLine.Status);
                    ProdOrderLine.SetRange("Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
                    ProdOrderLine.SetRange("Routing No.", ProdOrderRoutingLine."Routing No.");
                    ProdOrderLine.SetRange("Routing Reference No.", ProdOrderRoutingLine."Routing Reference No.");
                    if ProdOrderLine.FindSet() then
                        repeat
                            if PurchaseLine."Subc. Prod. Order Line No." in [ProdOrderLine."Line No.", ProdOrderRoutingLine."Routing Reference No."] then begin
                                ProdOrderComponent.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
                                HasComponent := not ProdOrderComponent.IsEmpty();
                            end;
                        until (ProdOrderLine.Next() = 0) or HasComponent;
                end;
                if not HasComponent then
                    OrphanedCount += 1;
            until PurchaseLine.Next() = 0;
    end;
}
