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
using Microsoft.Purchases.Vendor;

codeunit 20520 "Subc. Prod. Order Rtng. Ext."
{
    var
#if not CLEAN28
#pragma warning disable AL0432
        SubcFeatureFlagHandler: Codeunit "Subc. Feature Flag Handler";
#pragma warning restore AL0432
#endif
        CannotModifyRtngLineTransferExistsErr: Label 'You cannot change this routing line because transfer orders exist for the linked production order %1, purchase order %2.', Comment = '%1=Production Order No., %2=Purchase Order No.';
        CannotModifyRtngLineStockAtSubcErr: Label 'You cannot change this routing line because there are remaining components or WIP items transferred to the subcontractor for production order %1, purchase order %2.', Comment = '%1=Production Order No., %2=Purchase Order No.';
        VendorSuppliedComponentLocationErr: Label 'Cannot change the subcontractor on operation %1 of production order %2 because vendor-supplied component %3 is associated with the previous subcontractor location %4.', Comment = '%1 = operation number, %2 = production order number, %3 = component item number, %4 = previous subcontractor location';

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Routing Line", OnBeforeDeleteEvent, '', false, false)]
    local procedure OnBeforeDeleteProdOrderRtngLine(var Rec: Record "Prod. Order Routing Line"; RunTrigger: Boolean)
    begin
#if not CLEAN28
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
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
#if not CLEAN28
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
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
#if not CLEAN28
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        if Rec.IsTemporary then
            exit;

        if CurrFieldNo <> 0 then
            if (xRec."No." <> Rec."No.") and xRec."Transfer WIP Item" then
                CheckSubcRtngLineDocumentsExist(xRec);

        if xRec."No." <> Rec."No." then
            Rec."Subc. Subcontractor No." := '';

        if (xRec."No." <> Rec."No.") and (Rec."Routing Link Code" <> '') then
            SubcontractingManagement.UpdLinkedComponents(Rec, true);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Routing Line", OnBeforeValidateEvent, "Operation No.", false, false)]
    local procedure OnBeforeValidateOperationNo(var Rec: Record "Prod. Order Routing Line"; var xRec: Record "Prod. Order Routing Line"; CurrFieldNo: Integer)
    begin
#if not CLEAN28
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        if Rec.IsTemporary then
            exit;

        if CurrFieldNo <> 0 then
            if (xRec."Operation No." <> Rec."Operation No.") and xRec."Transfer WIP Item" then
                CheckSubcRtngLineDocumentsExist(xRec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Routing Line", OnBeforeValidateEvent, "Routing Link Code", false, false)]
    local procedure OnBeforeValidateRoutingLinkCode(var Rec: Record "Prod. Order Routing Line"; var xRec: Record "Prod. Order Routing Line"; CurrFieldNo: Integer)
    begin
#if not CLEAN28
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        if Rec.IsTemporary then
            exit;

        if CurrFieldNo <> 0 then
            if (xRec."Routing Link Code" <> Rec."Routing Link Code") and xRec."Transfer WIP Item" then
                CheckSubcRtngLineDocumentsExist(xRec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Routing Line", OnBeforeValidateEvent, "Type", false, false)]
    local procedure OnBeforeValidateType(var Rec: Record "Prod. Order Routing Line"; var xRec: Record "Prod. Order Routing Line"; CurrFieldNo: Integer)
    begin
#if not CLEAN28
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        if Rec.IsTemporary then
            exit;

        if CurrFieldNo <> 0 then
            if (xRec.Type <> Rec.Type) and xRec."Transfer WIP Item" then
                CheckSubcRtngLineDocumentsExist(xRec);
        Rec."Subc. Subcontractor No." := '';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Routing Line", OnBeforeValidateEvent, "Transfer WIP Item", false, false)]
    local procedure OnBeforeValidateTransferWIPItem(var Rec: Record "Prod. Order Routing Line"; var xRec: Record "Prod. Order Routing Line"; CurrFieldNo: Integer)
    begin
#if not CLEAN28
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        if Rec.IsTemporary then
            exit;

        if CurrFieldNo <> 0 then
            if (xRec."Transfer WIP Item" <> Rec."Transfer WIP Item") and xRec."Transfer WIP Item" then
                CheckSubcRtngLineDocumentsExist(xRec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Routing Line", OnAfterDeleteRelations, '', false, false)]
    local procedure OnAfterDeleteProdOrderRoutingLineRelations(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; SkipUpdateOfCompBinCodes: Boolean)
    var
        ProdOrderRoutingComment: Record "Subc. Prod. Rtng. Comment";
    begin
#if not CLEAN28
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        if ProdOrderRoutingLine.IsTemporary() then
            exit;

        ProdOrderRoutingComment.SetRange(Status, ProdOrderRoutingLine.Status);
        ProdOrderRoutingComment.SetRange("Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        ProdOrderRoutingComment.SetRange("Routing Reference No.", ProdOrderRoutingLine."Routing Reference No.");
        ProdOrderRoutingComment.SetRange("Routing No.", ProdOrderRoutingLine."Routing No.");
        ProdOrderRoutingComment.SetRange("Operation No.", ProdOrderRoutingLine."Operation No.");
        ProdOrderRoutingComment.DeleteAll();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Routing Line", OnAfterWorkCenterTransferFields, '', false, false)]
    local procedure OnAfterWorkCenterTransferFields(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; WorkCenter: Record "Work Center")
    var
        SubcPriceManagement: Codeunit "Subc. Price Management";
    begin
#if not CLEAN28
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        SubcPriceManagement.GetSubcPriceList(ProdOrderRoutingLine);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Routing Line", OnAfterCopyFromRoutingLine, '', false, false)]
    local procedure OnAfterCopyFromRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; RoutingLine: Record "Routing Line")
    begin
#if not CLEAN28
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        ProdOrderRoutingLine."Subc. Subcontractor No." := '';
        ProdOrderRoutingLine."Transfer WIP Item" := RoutingLine."Transfer WIP Item";
        ProdOrderRoutingLine."Transfer Description" := RoutingLine."Transfer Description";
        ProdOrderRoutingLine."Transfer Description 2" := RoutingLine."Transfer Description 2";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Routing Line", OnAfterCopyFromPlanningRoutingLine, '', false, false)]
    local procedure OnAfterCopyFromPlanningRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; PlanningRoutingLine: Record "Planning Routing Line")
    begin
#if not CLEAN28
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        ProdOrderRoutingLine."Subc. Subcontractor No." := '';
        ProdOrderRoutingLine."Transfer WIP Item" := PlanningRoutingLine."Transfer WIP Item";
        ProdOrderRoutingLine."Transfer Description" := PlanningRoutingLine."Transfer Description";
        ProdOrderRoutingLine."Transfer Description 2" := PlanningRoutingLine."Transfer Description 2";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Prod. Order Route Management", OnCalculateOnBeforeProdOrderRtngLineLoopIteration, '', false, false)]
    local procedure CheckSubcontractingOnCalculateOnBeforeProdOrderRtngLineLoopIteration(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var ProdOrderLine: Record "Prod. Order Line"; var IsHandled: Boolean)
    begin
#if not CLEAN28
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        ProdOrderRoutingLine.CheckForSubcontractingPurchaseLineTypeMismatch();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Prod. Order Status Management", OnAfterToProdOrderRtngLineInsert, '', false, false)]
    local procedure TransferSubcontractingCommentsOnAfterToProdOrderRoutingLineInsert(var ToProdOrderRoutingLine: Record "Prod. Order Routing Line"; var FromProdOrderRoutingLine: Record "Prod. Order Routing Line")
    begin
#if not CLEAN28
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        if FromProdOrderRoutingLine.IsTemporary() or ToProdOrderRoutingLine.IsTemporary() then
            exit;

        TransferSubcontractingComments(FromProdOrderRoutingLine, ToProdOrderRoutingLine);
    end;

    local procedure TransferSubcontractingComments(FromProdOrderRoutingLine: Record "Prod. Order Routing Line"; ToProdOrderRoutingLine: Record "Prod. Order Routing Line")
    var
        FromSubcProdRtngComment, ToSubcProdRtngComment : Record "Subc. Prod. Rtng. Comment";
    begin
        FromSubcProdRtngComment.SetRange(Status, FromProdOrderRoutingLine.Status);
        FromSubcProdRtngComment.SetRange("Prod. Order No.", FromProdOrderRoutingLine."Prod. Order No.");
        FromSubcProdRtngComment.SetRange("Routing Reference No.", FromProdOrderRoutingLine."Routing Reference No.");
        FromSubcProdRtngComment.SetRange("Routing No.", FromProdOrderRoutingLine."Routing No.");
        FromSubcProdRtngComment.SetRange("Operation No.", FromProdOrderRoutingLine."Operation No.");
        if FromSubcProdRtngComment.FindSet() then begin
            repeat
                ToSubcProdRtngComment := FromSubcProdRtngComment;
                ToSubcProdRtngComment.Status := ToProdOrderRoutingLine.Status;
                ToSubcProdRtngComment."Prod. Order No." := ToProdOrderRoutingLine."Prod. Order No.";
                ToSubcProdRtngComment."Routing Reference No." := ToProdOrderRoutingLine."Routing Reference No.";
                ToSubcProdRtngComment."Routing No." := ToProdOrderRoutingLine."Routing No.";
                ToSubcProdRtngComment."Operation No." := ToProdOrderRoutingLine."Operation No.";
                ToSubcProdRtngComment.Insert();
            until FromSubcProdRtngComment.Next() = 0;
            FromSubcProdRtngComment.DeleteAll();
        end;
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
        PurchaseLine.ReadIsolation := IsolationLevel::UpdLock;
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

    internal procedure CheckOperationSubcontractorChange(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; NewVendor: Record Vendor)
    var
        ProductionLine: Record "Prod. Order Line";
        PurchaseLine: Record "Purchase Line";
        OperationTransferLine: Record "Transfer Line";
        Component: Record "Prod. Order Component";
        SupplierComponent: Record "Prod. Order Component";
        PreviousVendor: Record Vendor;
        WIPEntry, LocationEntry: Record "Subcontractor WIP Ledger Entry";
        SubcTransferManagement: Codeunit "Subc. Transfer Management";
        SubcontractingManagement: Codeunit "Subcontracting Management";
    begin
        SubcontractingManagement.ProtectOperationChange(ProdOrderRoutingLine);
        ProductionLine.ReadIsolation := IsolationLevel::UpdLock;
        PurchaseLine.ReadIsolation := IsolationLevel::UpdLock;
        PreviousVendor.ReadIsolation := IsolationLevel::UpdLock;
        PreviousVendor.Get(ProdOrderRoutingLine.GetEffectiveSubcontractorNo());
        CheckSubcRtngLineDocumentsExist(ProdOrderRoutingLine);
        ProductionLine.SetRange(Status, ProdOrderRoutingLine.Status);
        ProductionLine.SetRange("Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        ProductionLine.SetRange("Routing Reference No.", ProdOrderRoutingLine."Routing Reference No.");
        ProductionLine.SetRange("Routing No.", ProdOrderRoutingLine."Routing No.");
        if ProductionLine.FindSet() then
            repeat
                if (ProdOrderRoutingLine."Routing Link Code" <> '') and
                   (PreviousVendor."Subc. Location Code" <> '') and
                   (PreviousVendor."Subc. Location Code" <> NewVendor."Subc. Location Code") and
                   (PreviousVendor."Subc. Location Code" <> ProductionLine."Location Code")
                then begin
                    SupplierComponent.ReadIsolation := IsolationLevel::UpdLock;
                    SupplierComponent.SetRange(Status, ProductionLine.Status);
                    SupplierComponent.SetRange("Prod. Order No.", ProductionLine."Prod. Order No.");
                    SupplierComponent.SetRange("Prod. Order Line No.", ProductionLine."Line No.");
                    SupplierComponent.SetRange("Routing Link Code", ProdOrderRoutingLine."Routing Link Code");
                    SupplierComponent.SetRange("Component Supply Method", SupplierComponent."Component Supply Method"::"Vendor-Supplied");
                    SupplierComponent.SetRange("Location Code", PreviousVendor."Subc. Location Code");
                    if SupplierComponent.FindFirst() then
                        Error(VendorSuppliedComponentLocationErr, ProdOrderRoutingLine."Operation No.", ProductionLine."Prod. Order No.", SupplierComponent."Item No.", SupplierComponent."Location Code");
                end;

                OperationTransferLine.Reset();
                OperationTransferLine.ReadIsolation := IsolationLevel::UpdLock;
                OperationTransferLine.SetRange("Subc. Prod. Order No.", ProductionLine."Prod. Order No.");
                OperationTransferLine.SetRange("Subc. Prod. Order Line No.", ProductionLine."Line No.");
                OperationTransferLine.SetRange("Subc. Routing No.", ProdOrderRoutingLine."Routing No.");
                OperationTransferLine.SetRange("Subc. Routing Reference No.", ProdOrderRoutingLine."Routing Reference No.");
                OperationTransferLine.SetRange("Subc. Operation No.", ProdOrderRoutingLine."Operation No.");
                if OperationTransferLine.FindFirst() then
                    Error(CannotModifyRtngLineTransferExistsErr, ProductionLine."Prod. Order No.", OperationTransferLine."Subc. Purch. Order No.");
                OperationTransferLine.SetRange("Subc. Operation No.");
                OperationTransferLine.SetRange("Prev. Operation No.", ProdOrderRoutingLine."Operation No.");
                if OperationTransferLine.FindFirst() then
                    Error(CannotModifyRtngLineTransferExistsErr, ProductionLine."Prod. Order No.", OperationTransferLine."Subc. Purch. Order No.");

                Component.SetRange(Status, ProductionLine.Status);
                Component.SetRange("Prod. Order No.", ProductionLine."Prod. Order No.");
                Component.SetRange("Prod. Order Line No.", ProductionLine."Line No.");
                Component.SetRange("Routing Link Code", ProdOrderRoutingLine."Routing Link Code");
                Component.SetRange("Component Supply Method", Component."Component Supply Method"::"Transfer to Vendor");
                Component.SetAutoCalcFields("Subc. Qty. transf. to Subcontr", "Subc. Qty. in Transit (Base)", "Subc. Qty.on TransOrder (Base)");
                if Component.FindSet() then
                    repeat
                        if (Component."Subc. Qty. in Transit (Base)" <> 0) or (Component."Subc. Qty.on TransOrder (Base)" <> 0) or
                           (Component."Subc. Qty. transf. to Subcontr" - SubcTransferManagement.CalcConsumedQtyAtSubcLocation(Component) > 0)
                        then
                            Error(CannotModifyRtngLineStockAtSubcErr, ProductionLine."Prod. Order No.", '');
                    until Component.Next() = 0;

                WIPEntry.ReadIsolation := IsolationLevel::UpdLock;
                WIPEntry.SetProductionOrderRoutingFilter(ProdOrderRoutingLine, true);
                WIPEntry.SetRange("Prod. Order Line No.", ProductionLine."Line No.");
                if WIPEntry.FindSet() then
                    repeat
                        LocationEntry.CopyFilters(WIPEntry);
                        LocationEntry.ReadIsolation := IsolationLevel::UpdLock;
                        LocationEntry.SetRange("Location Code", WIPEntry."Location Code");
                        LocationEntry.SetRange("In Transit", WIPEntry."In Transit");
                        LocationEntry.SetRange("Item No.", WIPEntry."Item No.");
                        LocationEntry.SetRange("Variant Code", WIPEntry."Variant Code");
                        LocationEntry.CalcSums("Quantity (Base)");
                        if LocationEntry."Quantity (Base)" <> 0 then
                            Error(CannotModifyRtngLineStockAtSubcErr, ProductionLine."Prod. Order No.", WIPEntry."Document No.");
                    until WIPEntry.Next() = 0;

                PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
                PurchaseLine.SetRange("Prod. Order No.", ProductionLine."Prod. Order No.");
                PurchaseLine.SetRange("Prod. Order Line No.", ProductionLine."Line No.");
                PurchaseLine.SetRange("Routing No.", ProdOrderRoutingLine."Routing No.");
                PurchaseLine.SetRange("Routing Reference No.", ProdOrderRoutingLine."Routing Reference No.");
                PurchaseLine.SetRange("Operation No.", ProdOrderRoutingLine."Operation No.");
                if PurchaseLine.FindSet() then
                    repeat
                        if (PurchaseLine."Quantity Received" <> 0) or HasStockAtSubcLocation(PurchaseLine, ProdOrderRoutingLine) then
                            Error(CannotModifyRtngLineStockAtSubcErr, ProductionLine."Prod. Order No.", PurchaseLine."Document No.");
                    until PurchaseLine.Next() = 0;
            until ProductionLine.Next() = 0;
    end;

    local procedure HasSubcTransferForPurchLine(PurchaseLine: Record "Purchase Line"): Boolean
    var
        TransferLine: Record "Transfer Line";
    begin
        TransferLine.ReadIsolation := IsolationLevel::UpdLock;
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
        SubcWIPLedgerEntry.ReadIsolation := IsolationLevel::UpdLock;
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