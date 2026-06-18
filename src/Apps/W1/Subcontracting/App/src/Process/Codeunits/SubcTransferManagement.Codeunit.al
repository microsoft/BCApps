// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Setup;
using Microsoft.Purchases.Document;

codeunit 99001504 "Subc. Transfer Management"
{
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        TempGlobalReservationEntry: Record "Reservation Entry" temporary;
#if not CLEAN29
#pragma warning disable AL0432
        SubcFeatureFlagHandler: Codeunit "Subc. Feature Flag Handler";
#pragma warning restore AL0432
#endif
        CannotModifySubcPurchLineErr: Label 'You cannot change %1 on the subcontracting purchase line because transfer orders exist for the linked production order %2.', Comment = '%1=Field Caption, %2=Production Order No.';
        CannotModifyStockAtSubcErr: Label 'You cannot change %1 on the subcontracting purchase line because there are remaining components or WIP items transferred to the subcontractor for production order %2.', Comment = '%1=Field Caption, %2=Production Order No.';
        CannotModifySubcTransferLineErr: Label 'You cannot change %1 on the subcontracting transfer line because it is linked to production order %2.', Comment = '%1=Field Caption, %2=Production Order No.';
        CannotModifySubcTransferHeaderErr: Label 'You cannot change %1 on the subcontracting transfer order because it contains lines linked to a production order.', Comment = '%1=Field Caption';
        CannotDeletePurchLineTransferExistsErr: Label 'You cannot delete the subcontracting purchase line because transfer orders exist for the linked production order %1.', Comment = '%1=Production Order No.';
        CannotDeletePurchLineStockAtSubcErr: Label 'You cannot delete the subcontracting purchase line because there are remaining components or WIP items transferred to the subcontractor for production order %1.', Comment = '%1=Production Order No.';
        CannotDeleteStockAtSubcErr: Label 'You cannot delete Subcontracting Order %1 because components or WIP items have been transferred to the subcontractor location for production order %2.', Comment = '%1=Purchase Order No., %2=Production Order No.';
        HasManufacturingSetup: Boolean;

    procedure CalcReceiptDateFromProdCompDueDateWithCompTransferLeadTime(ProdOrderComponent: Record "Prod. Order Component") ReceiptDate: Date
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        GetManufacturingSetup();
        if not HasManufacturingSetup or (Format(ManufacturingSetup."Subc. Comp. Transfer Lead Time") = '') then
            exit(ProdOrderComponent."Due Date");

        ReceiptDate := CalcDate('-' + Format(ManufacturingSetup."Subc. Comp. Transfer Lead Time"), ProdOrderComponent."Due Date");

        exit(ReceiptDate);
    end;

    procedure CheckDirectTransferIsAllowedForTransferHeader(TransferHeader: Record "Transfer Header")
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        TransferHeader.CheckDirectTransferPosting();
    end;

    procedure TransferReservationEntryFromProdOrderCompToTransferOrder(TransferLine: Record "Transfer Line"; ProdOrderComponent: Record "Prod. Order Component")
    var
        ReservationEntry: Record "Reservation Entry";
        ProdOrderCompReserve: Codeunit "Prod. Order Comp.-Reserve";
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        TempGlobalReservationEntry.Reset();
        TempGlobalReservationEntry.DeleteAll();

        if not ProdOrderCompReserve.FindReservEntry(ProdOrderComponent, ReservationEntry) then
            exit;

        if ReservationEntry.FindSet() then
            repeat
                TempGlobalReservationEntry := ReservationEntry;
                TempGlobalReservationEntry.Insert();
            until ReservationEntry.Next() = 0;

        ReservationEntry.TransferReservations(
         ReservationEntry,
         TransferLine."Item No.",
         TransferLine."Variant Code",
         TransferLine."Transfer-from Code",
         true,
         TransferLine."Quantity (Base)",
         TransferLine."Qty. per Unit of Measure",
         Database::"Transfer Line",
         0,  // Direction::Outbound
         TransferLine."Document No.",
         '',
         0,
         TransferLine."Line No.");
    end;

    procedure ComponentHasExcessReservations(ProdOrderComponent: Record "Prod. Order Component"; MaxQtyBase: Decimal): Boolean
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        exit(GetComponentReservedQtyBase(ProdOrderComponent) > MaxQtyBase);
    end;

    procedure GetComponentReservedQtyBase(ProdOrderComponent: Record "Prod. Order Component"): Decimal
    var
        ReservationEntry: Record "Reservation Entry";
        ProdOrderCompReserve: Codeunit "Prod. Order Comp.-Reserve";
        TotalReservedQtyBase: Decimal;
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        if not ProdOrderCompReserve.FindReservEntry(ProdOrderComponent, ReservationEntry) then
            exit(0);

        if ReservationEntry.FindSet() then
            repeat
                TotalReservedQtyBase += Abs(ReservationEntry."Quantity (Base)");
            until ReservationEntry.Next() = 0;

        exit(TotalReservedQtyBase);
    end;

    procedure CreateReservEntryForTransferReceiptToProdOrderComp(
     TransferLine: Record "Transfer Line";
     ProdOrderComponent: Record "Prod. Order Component")
    var
        Item: Record Item;
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        CreateReservEntry: Codeunit "Create Reserv. Entry";
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        TempGlobalReservationEntry.SetRange("Reservation Status", TempGlobalReservationEntry."Reservation Status"::Reservation);
        if not TempGlobalReservationEntry.FindSet() then
            exit;

        repeat
            if TempGlobalReservationEntry.GetItemTrackingEntryType() <> "Item Tracking Entry Type"::None then
                if Item.Get(TempGlobalReservationEntry."Item No.") then begin
                    TempGlobalReservationEntry."Location Code" := ProdOrderComponent."Location Code";
                    CreateReservEntry.CreateReservEntryFor(
                        Database::"Transfer Line",
                        1,  // Direction::Inbound
                        TransferLine."Document No.",
                        '',
                        TransferLine."Derived From Line No.",
                        TransferLine."Line No.",
                        TransferLine."Qty. per Unit of Measure",
                        Abs(TempGlobalReservationEntry.Quantity),
                        Abs(TempGlobalReservationEntry."Quantity (Base)"),
                        TempGlobalReservationEntry);

                    TempTrackingSpecification.Init();
                    TempTrackingSpecification.SetSource(
                        Database::"Prod. Order Component",
                        ProdOrderComponent.Status.AsInteger(),
                        ProdOrderComponent."Prod. Order No.",
                        ProdOrderComponent."Line No.",
                        '',
                        ProdOrderComponent."Prod. Order Line No.");
                    TempTrackingSpecification."Qty. per Unit of Measure" := ProdOrderComponent."Qty. per Unit of Measure";
                    TempTrackingSpecification.CopyTrackingFromReservEntry(TempGlobalReservationEntry);

                    CreateReservEntry.CreateReservEntryFrom(TempTrackingSpecification);

                    CreateReservEntry.CreateEntry(
                        TempGlobalReservationEntry."Item No.",
                        TempGlobalReservationEntry."Variant Code",
                        TransferLine."Transfer-to Code",
                        TempGlobalReservationEntry.Description,
                        TransferLine."Receipt Date",
                        ProdOrderComponent."Due Date",
                        0,
                        TempGlobalReservationEntry."Reservation Status");
                end;
        until TempGlobalReservationEntry.Next() = 0;
    end;

    procedure TransferReservationEntryFromPstTransferLineToProdOrderComp(var TransferReceiptLine: Record "Transfer Receipt Line")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ProdOrderComponent: Record "Prod. Order Component";
        TempForReservationEntry: Record "Reservation Entry" temporary;
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        ProdOrderCompReserve: Codeunit "Prod. Order Comp.-Reserve";
        UnitOfMeasureManagement: Codeunit "Unit of Measure Management";
        QtyToReserve: Decimal;
        QtyToReserveBase: Decimal;
        AvailableToReserveBase: Decimal;
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        if (TransferReceiptLine."Subc. Prod. Order No." = '') or (TransferReceiptLine."Subc. Operation No." = '') then
            exit;
        if not ProdOrderComponent.Get("Production Order Status"::Released, TransferReceiptLine."Subc. Prod. Order No.", TransferReceiptLine."Subc. Prod. Order Line No.", TransferReceiptLine."Subc. Prod. Ord. Comp Line No.") then
            exit;
        ItemLedgerEntry.SetCurrentKey("Item No.", Open, "Variant Code", Positive, "Expiration Date", "Lot No.", "Serial No.");
        ItemLedgerEntry.SetRange("Item No.", TransferReceiptLine."Item No.");
        ItemLedgerEntry.SetRange(Open, true);
        ItemLedgerEntry.SetRange(Positive, true);
        ItemLedgerEntry.SetRange("Document No.", TransferReceiptLine."Document No.");
        ItemLedgerEntry.SetRange("Document Line No.", TransferReceiptLine."Line No.");
        ItemLedgerEntry.SetRange("Location Code", TransferReceiptLine."Transfer-to Code");
        ItemLedgerEntry.SetLoadFields("Serial No.", "Lot No.", "Package No.", "Variant Code", "Location Code", Quantity);
        if not ItemLedgerEntry.IsEmpty() then begin
            ItemLedgerEntry.FindSet();
            repeat
                if (ItemLedgerEntry."Lot No." <> '') or (ItemLedgerEntry."Serial No." <> '') or (ItemLedgerEntry."Package No." <> '') then begin
                    // Only reserve up to the component's remaining need. Excess received quantity
                    // (e.g. when more was transferred to/from the subcontractor than the component requires)
                    // is left as free inventory instead of failing with "Reserved quantity cannot be greater than 0".
                    ProdOrderComponent.CalcFields("Reserved Qty. (Base)");
                    AvailableToReserveBase := Abs(ProdOrderComponent."Remaining Qty. (Base)") - Abs(ProdOrderComponent."Reserved Qty. (Base)");

                    // Item ledger entry quantities are always stored in the base unit of measure.
                    QtyToReserveBase := ItemLedgerEntry.Quantity;
                    if QtyToReserveBase > AvailableToReserveBase then
                        // Serial-tracked entries are indivisible, so skip the entry entirely when it no longer
                        // fully fits. Lot- and package-tracked entries can be reserved partially.
                        if ItemLedgerEntry."Serial No." <> '' then
                            QtyToReserveBase := 0
                        else
                            QtyToReserveBase := AvailableToReserveBase;

                    if QtyToReserveBase > 0 then begin
                        if ProdOrderComponent."Qty. per Unit of Measure" <> 0 then
                            QtyToReserve := UnitOfMeasureManagement.CalcQtyFromBase(QtyToReserveBase, ProdOrderComponent."Qty. per Unit of Measure")
                        else
                            QtyToReserve := QtyToReserveBase;

                        if not TempTrackingSpecification.IsEmpty() then
                            TempTrackingSpecification.DeleteAll();
                        TempTrackingSpecification."Source Type" := Database::"Item Ledger Entry";
                        TempTrackingSpecification."Source Subtype" := 0;
                        TempTrackingSpecification."Source ID" := '';
                        TempTrackingSpecification."Source Batch Name" := '';
                        TempTrackingSpecification."Source Prod. Order Line" := 0;
                        TempTrackingSpecification."Source Ref. No." := ItemLedgerEntry."Entry No.";
                        TempTrackingSpecification."Variant Code" := ItemLedgerEntry."Variant Code";
                        TempTrackingSpecification."Location Code" := ItemLedgerEntry."Location Code";
                        TempTrackingSpecification."Serial No." := ItemLedgerEntry."Serial No.";
                        TempTrackingSpecification."Lot No." := ItemLedgerEntry."Lot No.";
                        TempTrackingSpecification."Package No." := ItemLedgerEntry."Package No.";
                        TempTrackingSpecification."Qty. per Unit of Measure" := ProdOrderComponent."Qty. per Unit of Measure";
                        TempTrackingSpecification.Insert();

                        ProdOrderCompReserve.CreateReservationSetFrom(TempTrackingSpecification);
                        TempForReservationEntry.CopyTrackingFromSpec(TempTrackingSpecification);
                        ProdOrderCompReserve.CreateReservation(
                          ProdOrderComponent,
                          ProdOrderComponent.Description,
                          ProdOrderComponent."Due Date",
                          QtyToReserve,
                          QtyToReserveBase,
                          TempForReservationEntry);
                    end;
                end;
            until ItemLedgerEntry.Next() = 0;
        end;
    end;

    procedure UpdateLocationCodeInProdOrderCompAfterDeleteTransferLine(var TransferLine: Record "Transfer Line")
    var
        ProdOrderComponent: Record "Prod. Order Component";
        SubcontractingManagement: Codeunit "Subcontracting Management";
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        if TransferLine."Quantity Shipped" <> 0 then
            exit;

        if not ProdOrderComponent.Get("Production Order Status"::Released, TransferLine."Subc. Prod. Order No.", TransferLine."Subc. Prod. Order Line No.", TransferLine."Subc. Prod. Ord. Comp Line No.") then
            exit;

        if TransferLine."Subc. Return Order" then begin
            // Return TO deletion (unshipped): component location was changed to Transfer-to (original location)
            // during Return TO creation. Revert it back to Transfer-from (subcontractor location)
            // so the component correctly reflects that items are still at the subcontractor.
            if (TransferLine."Transfer-from Code" <> '') and (ProdOrderComponent."Location Code" <> TransferLine."Transfer-from Code") then begin
                ProdOrderComponent.Validate("Location Code", TransferLine."Transfer-from Code");
                ProdOrderComponent.Modify();
            end;
            exit;
        end;

        if ProdOrderComponent."Subc. Original Location Code" <> '' then begin
            SubcontractingManagement.ChangeLocationOnProdOrderComponent(ProdOrderComponent, '', ProdOrderComponent."Subc. Original Location Code", ProdOrderComponent."Subc. Orig. Bin Code");
            ProdOrderComponent."Subc. Original Location Code" := '';
            ProdOrderComponent."Subc. Orig. Bin Code" := '';

            ProdOrderComponent.Modify();
        end;
    end;

    internal procedure IsSubcontractingTransferDocument(TransferHeader: Record "Transfer Header"): Boolean
    begin
        exit(TransferHeader."Subc. Source Type" = TransferHeader."Subc. Source Type"::Subcontracting);
    end;

    internal procedure IsSubcontractingTransferLine(TransferLine: Record "Transfer Line"): Boolean
    begin
        exit((TransferLine."Subc. Prod. Order No." <> '') and (TransferLine."Subc. Prod. Order Line No." <> 0));
    end;

    internal procedure CheckSubcPurchLineCanBeModified(PurchaseLine: Record "Purchase Line"; FieldCaption: Text)
    begin
        if not PurchaseLine."Transfer WIP Item" then
            exit;

        if HasSubcTransferForPurchLine(PurchaseLine) then
            Error(CannotModifySubcPurchLineErr, FieldCaption, PurchaseLine."Prod. Order No.");
        if HasStockAtSubcLocation(PurchaseLine) then
            Error(CannotModifyStockAtSubcErr, FieldCaption, PurchaseLine."Prod. Order No.");
    end;

    internal procedure CheckSubcPurchLineCanBeDeleted(PurchaseLine: Record "Purchase Line")
    begin
        if not PurchaseLine."Transfer WIP Item" then
            exit;

        if HasSubcTransferForPurchLine(PurchaseLine) then
            Error(CannotDeletePurchLineTransferExistsErr, PurchaseLine."Prod. Order No.");
        if HasStockAtSubcLocation(PurchaseLine) then
            Error(CannotDeletePurchLineStockAtSubcErr, PurchaseLine."Prod. Order No.");
    end;

    internal procedure CheckStockAtSubcLocationForPurchHeader(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetFilter("Prod. Order No.", '<>%1', '');
        PurchaseLine.SetRange("Transfer WIP Item", true);
        if PurchaseLine.FindSet() then
            repeat
                if HasStockAtSubcLocation(PurchaseLine) then
                    Error(CannotDeleteStockAtSubcErr, PurchaseHeader."No.", PurchaseLine."Prod. Order No.");
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

    local procedure HasStockAtSubcLocation(PurchaseLine: Record "Purchase Line"): Boolean
    var
        ProdOrderComponent: Record "Prod. Order Component";
        SubcWIPLedgerEntry: Record "Subcontractor WIP Ledger Entry";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        NetStockAtSubcLocation: Decimal;
    begin
        GetProdOrderRoutingLinkCode(ProdOrderRoutingLine, PurchaseLine);
        ProdOrderComponent.SetCurrentKey(Status, "Prod. Order No.", "Routing Link Code");
        ProdOrderComponent.SetRange(Status, "Production Order Status"::Released);
        ProdOrderComponent.SetRange("Prod. Order No.", PurchaseLine."Prod. Order No.");
        ProdOrderComponent.SetRange("Prod. Order Line No.", PurchaseLine."Prod. Order Line No.");
        ProdOrderComponent.SetRange("Subc. Purchase Order Filter", PurchaseLine."Document No.");
        ProdOrderComponent.SetRange("Routing Link Code", ProdOrderRoutingLine."Routing Link Code");
        ProdOrderComponent.SetRange("Component Supply Method", ProdOrderComponent."Component Supply Method"::"Transfer to Vendor");
        ProdOrderComponent.SetAutoCalcFields("Subc. Qty. transf. to Subcontr");
        if ProdOrderComponent.FindSet() then
            repeat
                if ProdOrderComponent."Subc. Qty. transf. to Subcontr" <> 0 then begin
                    NetStockAtSubcLocation := ProdOrderComponent."Subc. Qty. transf. to Subcontr";
                    NetStockAtSubcLocation -= CalcConsumedQtyAtSubcLocation(ProdOrderComponent);
                    if NetStockAtSubcLocation > 0 then
                        exit(true);
                end;
            until ProdOrderComponent.Next() = 0;

        SubcWIPLedgerEntry.SetCurrentKey("Prod. Order No.", "Prod. Order Status", "Prod. Order Line No.", "Routing Reference No.", "Routing No.", "Operation No.", "Location Code");
        SubcWIPLedgerEntry.SetRange("Prod. Order No.", PurchaseLine."Prod. Order No.");
        SubcWIPLedgerEntry.SetRange("Prod. Order Status", "Production Order Status"::Released);
        SubcWIPLedgerEntry.SetRange("Prod. Order Line No.", PurchaseLine."Prod. Order Line No.");
        SubcWIPLedgerEntry.SetRange("Routing Reference No.", PurchaseLine."Routing Reference No.");
        SubcWIPLedgerEntry.SetRange("Routing No.", PurchaseLine."Routing No.");
        SubcWIPLedgerEntry.SetRange("Operation No.", PurchaseLine."Operation No.");

        SubcWIPLedgerEntry.SetRange("In Transit", false);
        SubcWIPLedgerEntry.CalcSums("Quantity (Base)");
        if SubcWIPLedgerEntry."Quantity (Base)" <> 0 then
            exit(true);

        exit(false);
    end;

    internal procedure CalcConsumedQtyAtSubcLocation(ProdOrderComponent: Record "Prod. Order Component"): Decimal
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetCurrentKey("Order Type", "Order No.", "Order Line No.", "Entry Type", "Prod. Order Comp. Line No.");
        ItemLedgerEntry.SetRange("Order Type", ItemLedgerEntry."Order Type"::Production);
        ItemLedgerEntry.SetRange("Order No.", ProdOrderComponent."Prod. Order No.");
        ItemLedgerEntry.SetRange("Order Line No.", ProdOrderComponent."Prod. Order Line No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Consumption);
        ItemLedgerEntry.SetRange("Prod. Order Comp. Line No.", ProdOrderComponent."Line No.");
        ItemLedgerEntry.SetRange("Location Code", ProdOrderComponent."Location Code");
        ItemLedgerEntry.CalcSums(Quantity);
        exit(-ItemLedgerEntry.Quantity);
    end;

    internal procedure CheckSubcTransferLineCanBeModified(TransferLine: Record "Transfer Line"; FieldCaption: Text)
    begin
        if IsSubcontractingTransferLine(TransferLine) then
            if not TransferLine."Transfer WIP Item" then //for now allow updating WIP item lines
                Error(CannotModifySubcTransferLineErr, FieldCaption, TransferLine."Subc. Prod. Order No.");
    end;

    internal procedure CheckSubcTransferHeaderCanBeModified(TransferHeader: Record "Transfer Header"; FieldCaption: Text)
    var
        TransferLine: Record "Transfer Line";
    begin
        if not IsSubcontractingTransferDocument(TransferHeader) then
            exit;

        TransferLine.SetRange("Document No.", TransferHeader."No.");
        TransferLine.SetFilter("Subc. Prod. Order No.", '<>%1', '');
        if not TransferLine.IsEmpty() then
            Error(CannotModifySubcTransferHeaderErr, FieldCaption);
    end;

    local procedure GetManufacturingSetup()
    begin
        if HasManufacturingSetup then
            exit;
        HasManufacturingSetup := ManufacturingSetup.Get();
    end;

    local procedure GetProdOrderRoutingLinkCode(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; PurchaseLine: Record "Purchase Line")
    var
        RoutingOperationNotFoundErr: Label 'Operation %1 in the subcontracting order %2 does not exist in the routing %3 of the production order %4.', Comment = '%1=Operation No., %2=Purchase Order No., %3=Routing No., %4=Production Order No.';
    begin
        if not ProdOrderRoutingLine.Get(
            "Production Order Status"::Released,
            PurchaseLine."Prod. Order No.",
            PurchaseLine."Routing Reference No.",
            PurchaseLine."Routing No.",
            PurchaseLine."Operation No.")
        then
            Error(RoutingOperationNotFoundErr, PurchaseLine."Operation No.", PurchaseLine."Document No.", PurchaseLine."Routing No.", PurchaseLine."Prod. Order No.");
    end;
}
