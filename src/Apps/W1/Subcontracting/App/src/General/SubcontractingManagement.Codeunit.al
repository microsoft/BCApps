// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Foundation.Company;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using System.Utilities;

codeunit 20505 "Subcontracting Management"
{
    var
        ManufacturingSetup: Record "Manufacturing Setup";
#if not CLEAN28
#pragma warning disable AL0432
        SubcFeatureFlagHandler: Codeunit "Subc. Feature Flag Handler";
#pragma warning restore AL0432
#endif
        RoutingLinkUpdConfQst: Label 'If you change the Work Center, you will also change the default location for components with Routing Link Code=%1.\Do you want to continue anyway?', Comment = '%1=Routing Link Code';
        SuccessfullyUpdatedMsg: Label 'Successfully updated.';
        UpdateIsCancelledErr: Label 'The update is cancelled.';
        WorkCenterVendorDoesntExistErr: Label 'Subcontractor %1 on Work Center %2 does not exist.', Comment = 'Parameter %1 - subcontractor/vendor number, %2 - work center number.';
        PurchOrderExistErr: Label 'The currently selected component %1 is already used in Purchase Order %2. Therefore, it is not permitted to change the %3 field.', Comment = '%1=Item No, %2=Purchase Order No, %3=Field Caption';
        ProductionBlockedOutputItemErr: Label 'You cannot produce %1 %2 because the %3 is %4 on the %1 card.', Comment = '%1 - Table Caption (Item), %2 - Item No., %3 - Field Caption, %4 - Field Value';
        ProductionBlockedOutputItemVariantErr: Label 'You cannot produce variant %1 for %2 %3 because it is blocked for production output.', Comment = '%1 - Item Variant Code, %2 - Table Caption (Item), %3 - Item No.';
        HasManufacturingSetup: Boolean;
        WIPSelectionChangedErr: Label 'The selected operation %1 of production order %2 has changed. Reopen the order and try again.', Comment = '%1 = operation number, %2 = production order number';
        WIPSourceEvidenceErr: Label 'Cannot verify WIP availability for operation %1 of production order %2 at location %3, document %4. Retain the source documents and reconcile the WIP evidence before creating another transfer.', Comment = '%1 = source operation, %2 = production order, %3 = source location, %4 = evidence document';

    internal procedure CheckNewSubcontractingPurchase(RequisitionLine: Record "Requisition Line")
    var
        ProductionLine: Record "Prod. Order Line";
        Routing: Record "Prod. Order Routing Line";
        WorkCenter: Record "Work Center";
        ReqLineExtension: Codeunit "Subc. Req.Line Extension";
    begin
#if not CLEAN28
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        if not ReqLineExtension.IsProductionSuggestion(RequisitionLine) then
            exit;
        ProductionLine.ReadIsolation := IsolationLevel::UpdLock;
        ProductionLine.Get(ProductionLine.Status::Released, RequisitionLine."Prod. Order No.", RequisitionLine."Prod. Order Line No.");
        ProductionLine.TestField("Routing No.", RequisitionLine."Routing No.");
        ProductionLine.TestField("Routing Reference No.", RequisitionLine."Routing Reference No.");
        Routing.ReadIsolation := IsolationLevel::UpdLock;
        Routing.Get(Routing.Status::Released, RequisitionLine."Prod. Order No.", RequisitionLine."Routing Reference No.", RequisitionLine."Routing No.", RequisitionLine."Operation No.");
        Routing.TestField(Type, Routing.Type::"Work Center");
        Routing.TestField("No.", RequisitionLine."Work Center No.");
        Routing.TestField("Work Center No.", RequisitionLine."Work Center No.");
        WorkCenter.ReadIsolation := IsolationLevel::UpdLock;
        WorkCenter.Get(Routing."No.");
        WorkCenter.TestField("Subcontractor No.");
    end;

    internal procedure ProtectOperationChange(var Routing: Record "Prod. Order Routing Line")
    var
        ProductionLine: Record "Prod. Order Line";
        LockedRouting: Record "Prod. Order Routing Line";
    begin
        ProductionLine.ReadIsolation := IsolationLevel::UpdLock;
        ProductionLine.SetCurrentKey(Status, "Prod. Order No.", "Line No.");
        ProductionLine.SetRange(Status, Routing.Status);
        ProductionLine.SetRange("Prod. Order No.", Routing."Prod. Order No.");
        ProductionLine.SetRange("Routing No.", Routing."Routing No.");
        ProductionLine.SetRange("Routing Reference No.", Routing."Routing Reference No.");
        if not ProductionLine.FindSet() then
            Error(WIPSelectionChangedErr, Routing."Operation No.", Routing."Prod. Order No.");
        repeat
            ProductionLine.TestField("Routing Reference No.", Routing."Routing Reference No.");
        until ProductionLine.Next() = 0;
        LockedRouting.ReadIsolation := IsolationLevel::UpdLock;
        LockedRouting.Get(Routing.Status, Routing."Prod. Order No.", Routing."Routing Reference No.", Routing."Routing No.", Routing."Operation No.");
        if LockedRouting.SystemRowVersion <> Routing.SystemRowVersion then
            Error(WIPSelectionChangedErr, Routing."Operation No.", Routing."Prod. Order No.");
        Routing := LockedRouting;
    end;

    internal procedure RememberWIPSelection(PurchaseLine: Record "Purchase Line"; var TempPurchaseLine: Record "Purchase Line" temporary; var SourceVersions: Dictionary of [Text, BigInteger])
    begin
        SourceVersions.Add(Format(PurchaseLine.RecordId), PurchaseLine.SystemRowVersion);
        TempPurchaseLine := PurchaseLine;
        TempPurchaseLine.Insert();
    end;

    internal procedure ProtectWIPSelection(var TempPurchaseLine: Record "Purchase Line" temporary; var TempProductionLine: Record "Prod. Order Line" temporary; var TempRouting: Record "Prod. Order Routing Line" temporary; var SourceVersions: Dictionary of [Text, BigInteger])
    var
        ProductionLine: Record "Prod. Order Line";
        Routing: Record "Prod. Order Routing Line";
        PurchaseLine: Record "Purchase Line";
    begin
        TempProductionLine.Reset();
        TempProductionLine.DeleteAll();
        TempRouting.Reset();
        TempRouting.DeleteAll();
        ProductionLine.ReadIsolation := IsolationLevel::ReadCommitted;
        Routing.ReadIsolation := IsolationLevel::ReadCommitted;
        TempPurchaseLine.Reset();
        if TempPurchaseLine.FindSet() then
            repeat
                if ProductionLine.Get(ProductionLine.Status::Released, TempPurchaseLine."Prod. Order No.", TempPurchaseLine."Prod. Order Line No.") then begin
                    if not TempProductionLine.Get(ProductionLine.Status, ProductionLine."Prod. Order No.", ProductionLine."Line No.") then begin
                        SourceVersions.Add(Format(ProductionLine.RecordId), ProductionLine.SystemRowVersion);
                        TempProductionLine := ProductionLine;
                        TempProductionLine.Insert();
                    end;
                    if Routing.Get(Routing.Status::Released, TempPurchaseLine."Prod. Order No.", TempPurchaseLine."Routing Reference No.", TempPurchaseLine."Routing No.", TempPurchaseLine."Operation No.") then
                        if not TempRouting.Get(Routing.Status, Routing."Prod. Order No.", Routing."Routing Reference No.", Routing."Routing No.", Routing."Operation No.") then begin
                            SourceVersions.Add(Format(Routing.RecordId), Routing.SystemRowVersion);
                            TempRouting := Routing;
                            TempRouting.Insert();
                        end;
                end;
            until TempPurchaseLine.Next() = 0;

        // Take actual update-intent reads of every existing production key before any dependent protected scan.
        ProductionLine.ReadIsolation := IsolationLevel::UpdLock;
        TempProductionLine.SetCurrentKey(Status, "Prod. Order No.", "Line No.");
        if TempProductionLine.FindSet() then
            repeat
                ProductionLine.Get(TempProductionLine.Status, TempProductionLine."Prod. Order No.", TempProductionLine."Line No.");
                if ProductionLine.SystemRowVersion <> SourceVersions.Get(Format(ProductionLine.RecordId)) then
                    Error(WIPSelectionChangedErr, '', TempProductionLine."Prod. Order No.");
            until TempProductionLine.Next() = 0;
        Routing.ReadIsolation := IsolationLevel::UpdLock;
        TempRouting.SetCurrentKey(Status, "Prod. Order No.", "Routing Reference No.", "Routing No.", "Operation No.");
        if TempRouting.FindSet() then
            repeat
                Routing.Get(TempRouting.Status, TempRouting."Prod. Order No.", TempRouting."Routing Reference No.", TempRouting."Routing No.", TempRouting."Operation No.");
                if Routing.SystemRowVersion <> SourceVersions.Get(Format(Routing.RecordId)) then
                    Error(WIPSelectionChangedErr, TempRouting."Operation No.", TempRouting."Prod. Order No.");
            until TempRouting.Next() = 0;
        PurchaseLine.ReadIsolation := IsolationLevel::UpdLock;
        if TempPurchaseLine.FindSet() then
            repeat
                PurchaseLine.Get(TempPurchaseLine."Document Type", TempPurchaseLine."Document No.", TempPurchaseLine."Line No.");
                if PurchaseLine.SystemRowVersion <> SourceVersions.Get(Format(PurchaseLine.RecordId)) then
                    Error(WIPSelectionChangedErr, TempPurchaseLine."Operation No.", TempPurchaseLine."Prod. Order No.");
                if TempProductionLine.Get(TempProductionLine.Status::Released, PurchaseLine."Prod. Order No.", PurchaseLine."Prod. Order Line No.") then begin
                    if (PurchaseLine."No." <> TempProductionLine."Item No.") or
                       (PurchaseLine."Variant Code" <> TempProductionLine."Variant Code")
                    then
                        Error(WIPSelectionChangedErr, PurchaseLine."Operation No.", PurchaseLine."Prod. Order No.");
                    TempProductionLine.TestField("Routing No.", PurchaseLine."Routing No.");
                    TempProductionLine.TestField("Routing Reference No.", PurchaseLine."Routing Reference No.");
                    if not TempRouting.Get(TempRouting.Status::Released, PurchaseLine."Prod. Order No.", PurchaseLine."Routing Reference No.", PurchaseLine."Routing No.", PurchaseLine."Operation No.") then
                        Error(WIPSelectionChangedErr, PurchaseLine."Operation No.", PurchaseLine."Prod. Order No.");
                end;
            until TempPurchaseLine.Next() = 0;
    end;

    internal procedure CheckWIPSelection(PurchaseLine: Record "Purchase Line"; var TempPurchaseLine: Record "Purchase Line" temporary; var TempProductionLine: Record "Prod. Order Line" temporary; var TempRouting: Record "Prod. Order Routing Line" temporary; SourceVersions: Dictionary of [Text, BigInteger])
    var
        ProductionLine: Record "Prod. Order Line";
        Routing: Record "Prod. Order Routing Line";
    begin
        if not TempPurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.") then
            Error(WIPSelectionChangedErr, PurchaseLine."Operation No.", PurchaseLine."Prod. Order No.");
        if PurchaseLine.SystemRowVersion <> SourceVersions.Get(Format(PurchaseLine.RecordId)) then
            Error(WIPSelectionChangedErr, PurchaseLine."Operation No.", PurchaseLine."Prod. Order No.");
        if not TempProductionLine.Get(TempProductionLine.Status::Released, PurchaseLine."Prod. Order No.", PurchaseLine."Prod. Order Line No.") then
            exit;
        ProductionLine.ReadIsolation := IsolationLevel::UpdLock;
        ProductionLine.Get(TempProductionLine.Status, TempProductionLine."Prod. Order No.", TempProductionLine."Line No.");
        if (PurchaseLine."No." <> ProductionLine."Item No.") or
           (PurchaseLine."Variant Code" <> ProductionLine."Variant Code")
        then
            Error(WIPSelectionChangedErr, PurchaseLine."Operation No.", PurchaseLine."Prod. Order No.");
        Routing.ReadIsolation := IsolationLevel::UpdLock;
        Routing.Get(Routing.Status::Released, PurchaseLine."Prod. Order No.", PurchaseLine."Routing Reference No.", PurchaseLine."Routing No.", PurchaseLine."Operation No.");
        TempRouting.Get(Routing.Status, Routing."Prod. Order No.", Routing."Routing Reference No.", Routing."Routing No.", Routing."Operation No.");
        if (ProductionLine.SystemRowVersion <> SourceVersions.Get(Format(ProductionLine.RecordId))) or
           (Routing.SystemRowVersion <> SourceVersions.Get(Format(Routing.RecordId)))
        then
            Error(WIPSelectionChangedErr, PurchaseLine."Operation No.", PurchaseLine."Prod. Order No.");
    end;

    internal procedure CheckWIPSelectedKeys(var TempPurchaseLine: Record "Purchase Line" temporary; SelectionViews: List of [Text]; SourceVersions: Dictionary of [Text, BigInteger])
    var
        PurchaseLine: Record "Purchase Line";
        View: Text;
        SelectedCount: Integer;
    begin
        foreach View in SelectionViews do begin
            PurchaseLine.Reset();
            PurchaseLine.SetView(View);
            PurchaseLine.ReadIsolation := IsolationLevel::UpdLock;
            if PurchaseLine.FindSet() then
                repeat
                    if not TempPurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.") then
                        Error(WIPSelectionChangedErr, PurchaseLine."Operation No.", PurchaseLine."Prod. Order No.");
                    if PurchaseLine.SystemRowVersion <> SourceVersions.Get(Format(PurchaseLine.RecordId)) then
                        Error(WIPSelectionChangedErr, PurchaseLine."Operation No.", PurchaseLine."Prod. Order No.");
                    SelectedCount += 1;
                until PurchaseLine.Next() = 0;
        end;
        TempPurchaseLine.Reset();
        if SelectedCount <> TempPurchaseLine.Count() then
            Error(WIPSelectionChangedErr, '', '');
    end;

    internal procedure FilterWIPSourceIdentity(var Entry: Record "Subcontractor WIP Ledger Entry"; ProductionLine: Record "Prod. Order Line"; Routing: Record "Prod. Order Routing Line")
    begin
        Entry.Reset();
        Entry.ReadIsolation := IsolationLevel::UpdLock;
        Entry.SetProductionOrderRoutingFilter(Routing, true);
        Entry.SetRange("Prod. Order Line No.", ProductionLine."Line No.");
        Entry.SetRange("Item No.", ProductionLine."Item No.");
        Entry.SetRange("Variant Code", ProductionLine."Variant Code");
    end;

    internal procedure FilterWIPTransferSourceIdentity(var Line: Record "Transfer Line"; ProductionLine: Record "Prod. Order Line"; Routing: Record "Prod. Order Routing Line")
    begin
        Line.ReadIsolation := IsolationLevel::UpdLock;
        Line.SetRange("Subc. Prod. Order No.", ProductionLine."Prod. Order No.");
        Line.SetRange("Subc. Prod. Order Line No.", ProductionLine."Line No.");
        Line.SetRange("Subc. Routing No.", Routing."Routing No.");
        Line.SetRange("Subc. Routing Reference No.", Routing."Routing Reference No.");
        Line.SetRange("Item No.", ProductionLine."Item No.");
        Line.SetRange("Variant Code", ProductionLine."Variant Code");
        Line.SetRange("Transfer WIP Item", true);
    end;

    internal procedure WIPQuantityBase(ProductionLine: Record "Prod. Order Line"; UOMCode: Code[10]; Quantity: Decimal): Decimal
    var
        Item: Record Item;
        UOMManagement: Codeunit "Unit of Measure Management";
    begin
        Item.Get(ProductionLine."Item No.");
        exit(UOMManagement.CalcBaseQty(Quantity, UOMManagement.GetQtyPerUnitOfMeasure(Item, UOMCode)));
    end;

    internal procedure GetWIPSourceCommitment(ProductionLine: Record "Prod. Order Line"; Routing: Record "Prod. Order Routing Line"; SourceOperation: Code[10]; SourceLocation: Code[10]; PurchaseLine: Record "Purchase Line"; ExcludeOwnForward: Boolean): Decimal
    var
        Line: Record "Transfer Line";
        Total: Decimal;
    begin
        FilterWIPTransferSourceIdentity(Line, ProductionLine, Routing);
        Line.SetRange("Derived From Line No.", 0);
        Line.SetRange("Transfer-from Code", SourceLocation);
        Line.SetRange("Subc. Return Order", false);
        Line.SetRange("Prev. Operation No.", SourceOperation);
        if Line.FindSet() then
            repeat
                if not ExcludeOwnForward or (Line."Subc. Purch. Order No." <> PurchaseLine."Document No.") or
                   (Line."Subc. Purch. Order Line No." <> PurchaseLine."Line No.")
                then
                    Total += WIPQuantityBase(ProductionLine, Line."Unit of Measure Code", Line.Quantity - Line."Quantity Shipped");
            until Line.Next() = 0;
        Line.SetRange("Subc. Return Order", true);
        Line.SetRange("Prev. Operation No.");
        Line.SetRange("Subc. Operation No.", SourceOperation);
        if Line.FindSet() then
            repeat
                Total += WIPQuantityBase(ProductionLine, Line."Unit of Measure Code", Line.Quantity - Line."Quantity Shipped");
            until Line.Next() = 0;
        exit(Total);
    end;

    internal procedure RoundWIPPlanQuantity(ProductionLine: Record "Prod. Order Line"; UOMCode: Code[10]; RequestedBase: Decimal; PhysicalCap: Decimal; SourceOperation: Code[10]; SourceLocation: Code[10]; var ActualBase: Decimal): Decimal
    var
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        UOMManagement: Codeunit "Unit of Measure Management";
        Factor, DocumentQuantity: Decimal;
    begin
        Item.Get(ProductionLine."Item No.");
        ItemUOM.ReadIsolation := IsolationLevel::UpdLock;
        if UOMCode <> '' then
            ItemUOM.Get(Item."No.", UOMCode);
        Factor := UOMManagement.GetQtyPerUnitOfMeasure(Item, UOMCode);
        if Factor <> 0 then
            DocumentQuantity := Round(RequestedBase / Factor, UOMManagement.QtyRndPrecision())
        else
            DocumentQuantity := Round(RequestedBase, UOMManagement.QtyRndPrecision());
        ActualBase := UOMManagement.CalcBaseQty(DocumentQuantity, Factor);
        if ActualBase > PhysicalCap then
            Error(WIPSourceEvidenceErr, SourceOperation, ProductionLine."Prod. Order No.", SourceLocation, '');
        exit(DocumentQuantity);
    end;

    internal procedure CheckWIPSourceEvidence(ProductionLine: Record "Prod. Order Line"; Routing: Record "Prod. Order Routing Line"; SourceOperation: Code[10]; SourceLocation: Code[10]): Decimal
    var
        Shipment, ReceiptShipment: Record "Transfer Shipment Line";
        Receipt: Record "Transfer Receipt Line";
        Evidence: Record "Subcontractor WIP Ledger Entry";
        DirectLine: Record "Direct Trans. Line";
        DirectHeader: Record "Direct Trans. Header";
        PreviousOperation: Code[10];
        Debited: Boolean;
        MissingDebit, QuantityBase: Decimal;
    begin
        Receipt.ReadIsolation := IsolationLevel::ReadCommitted;
        ReceiptShipment.ReadIsolation := IsolationLevel::ReadCommitted;
        Shipment.ReadIsolation := IsolationLevel::ReadCommitted;
        DirectLine.ReadIsolation := IsolationLevel::ReadCommitted;
        DirectHeader.ReadIsolation := IsolationLevel::ReadCommitted;
        Receipt.SetRange("Subc. Prod. Order No.", ProductionLine."Prod. Order No.");
        Receipt.SetRange("Subc. Prod. Order Line No.", ProductionLine."Line No.");
        Receipt.SetRange("Subc. Routing No.", Routing."Routing No.");
        Receipt.SetRange("Subc. Routing Reference No.", Routing."Routing Reference No.");
        Receipt.SetRange("Item No.", ProductionLine."Item No.");
        Receipt.SetRange("Variant Code", ProductionLine."Variant Code");
        Receipt.SetRange("Transfer WIP Item", true);
        Receipt.SetRange("Transfer-from Code", SourceLocation);
        if Receipt.FindSet() then
            repeat
                ReceiptShipment.Reset();
                ReceiptShipment.ReadIsolation := IsolationLevel::ReadCommitted;
                ReceiptShipment.SetRange("Transfer Order No.", Receipt."Transfer Order No.");
                ReceiptShipment.SetRange("Subc. Prod. Order No.", ProductionLine."Prod. Order No.");
                ReceiptShipment.SetRange("Subc. Prod. Order Line No.", ProductionLine."Line No.");
                ReceiptShipment.SetRange("Subc. Routing No.", Routing."Routing No.");
                ReceiptShipment.SetRange("Subc. Routing Reference No.", Routing."Routing Reference No.");
                ReceiptShipment.SetRange("Subc. Operation No.", Receipt."Subc. Operation No.");
                ReceiptShipment.SetRange("Transfer WIP Item", true);
                ReceiptShipment.SetRange("Transfer-from Code", SourceLocation);
                ReceiptShipment.SetRange("Item No.", Receipt."Item No.");
                ReceiptShipment.SetRange("Variant Code", Receipt."Variant Code");
                ReceiptShipment.SetRange("Derived Trans. Order Line No.", Receipt."Line No.");
                if ReceiptShipment.IsEmpty() then begin
                    ReceiptShipment.SetRange("Derived Trans. Order Line No.");
                    ReceiptShipment.SetRange("Trans. Order Line No.", Receipt."Line No.");
                    if ReceiptShipment.IsEmpty() then
                        Error(WIPSourceEvidenceErr, SourceOperation, ProductionLine."Prod. Order No.", SourceLocation, Receipt."Document No.");
                end;
            until Receipt.Next() = 0;
        FilterWIPSourceIdentity(Evidence, ProductionLine, Routing);
        Evidence.SetFilter("Operation No.", '<>%1', SourceOperation);
        Evidence.SetRange("In Transit", false);
        Evidence.SetRange("Document Type", Evidence."Document Type"::"Transfer Order");
        Evidence.SetFilter("Quantity (Base)", '>0');
        if Evidence.FindSet() then
            repeat
                if not Receipt.Get(Evidence."Document No.", Evidence."Document Line No.") and
                   not DirectLine.Get(Evidence."Document No.", Evidence."Document Line No.")
                then
                    Error(WIPSourceEvidenceErr, SourceOperation, ProductionLine."Prod. Order No.", SourceLocation, Evidence."Document No.");
            until Evidence.Next() = 0;
        Shipment.SetRange("Subc. Prod. Order No.", ProductionLine."Prod. Order No.");
        Shipment.SetRange("Subc. Prod. Order Line No.", ProductionLine."Line No.");
        Shipment.SetRange("Subc. Routing No.", Routing."Routing No.");
        Shipment.SetRange("Subc. Routing Reference No.", Routing."Routing Reference No.");
        Shipment.SetRange("Item No.", ProductionLine."Item No.");
        Shipment.SetRange("Variant Code", ProductionLine."Variant Code");
        Shipment.SetRange("Transfer WIP Item", true);
        Shipment.SetRange("Transfer-from Code", SourceLocation);
        if Shipment.FindSet() then
            repeat
                QuantityBase := WIPQuantityBase(ProductionLine, Shipment."Unit of Measure Code", Shipment.Quantity);
                if QuantityBase <> 0 then begin
                    if not ResolveWIPPostedSource(ProductionLine, Routing, SourceLocation,
                         Shipment."Document No.", Shipment."Line No.", Shipment."Transfer Order No.",
                         Shipment."Trans. Order Line No.", Shipment."Derived Trans. Order Line No.",
                         Shipment."Subc. Operation No.", Shipment."Subc. Return Order", QuantityBase, PreviousOperation, Debited)
                    then
                        Error(WIPSourceEvidenceErr, SourceOperation, ProductionLine."Prod. Order No.", SourceLocation, Shipment."Document No.");
                    if (PreviousOperation = SourceOperation) and not Debited then
                        MissingDebit += QuantityBase;
                end;
            until Shipment.Next() = 0;
        DirectLine.Reset();
        DirectLine.ReadIsolation := IsolationLevel::ReadCommitted;
        DirectLine.SetRange("Prod. Order No.", ProductionLine."Prod. Order No.");
        DirectLine.SetRange("Prod. Order Line No.", ProductionLine."Line No.");
        DirectLine.SetRange("Routing No.", Routing."Routing No.");
        DirectLine.SetRange("Routing Reference No.", Routing."Routing Reference No.");
        DirectLine.SetRange("Item No.", ProductionLine."Item No.");
        DirectLine.SetRange("Variant Code", ProductionLine."Variant Code");
        DirectLine.SetRange("Transfer WIP Item", true);
        DirectLine.SetRange("Transfer-from Code", SourceLocation);
        if DirectLine.FindSet() then
            repeat
                QuantityBase := WIPQuantityBase(ProductionLine, DirectLine."Unit of Measure Code", DirectLine.Quantity);
                if QuantityBase <> 0 then begin
                    DirectHeader.Get(DirectLine."Document No.");
                    if not ResolveWIPPostedSource(ProductionLine, Routing, SourceLocation,
                         DirectLine."Document No.", DirectLine."Line No.", DirectHeader."Transfer Order No.",
                         DirectLine."Line No.", 0, DirectLine."Operation No.", DirectLine."Subc. Return Order",
                         QuantityBase, PreviousOperation, Debited)
                    then
                        Error(WIPSourceEvidenceErr, SourceOperation, ProductionLine."Prod. Order No.", SourceLocation, DirectLine."Document No.");
                    if (PreviousOperation = SourceOperation) and not Debited then
                        MissingDebit += QuantityBase;
                end;
            until DirectLine.Next() = 0;
        exit(MissingDebit);
    end;

    internal procedure ResolveWIPPostedSource(ProductionLine: Record "Prod. Order Line"; Routing: Record "Prod. Order Routing Line"; SourceLocation: Code[10]; DocumentNo: Code[20]; DocumentLineNo: Integer; TransferOrderNo: Code[20]; OriginalLineNo: Integer; DerivedLineNo: Integer; CurrentOperation: Code[10]; IsReturn: Boolean; QuantityBase: Decimal; var PreviousOperation: Code[10]; var Debited: Boolean): Boolean
    var
        Debit: Record "Subcontractor WIP Ledger Entry";
        Line: Record "Transfer Line";
    begin
        Clear(PreviousOperation);
        Debited := false;
        FilterWIPSourceIdentity(Debit, ProductionLine, Routing);
        Debit.SetRange("Operation No.");
        Debit.SetRange("Document Type", Debit."Document Type"::"Transfer Order");
        Debit.SetRange("Document No.", DocumentNo);
        Debit.SetRange("Document Line No.", DocumentLineNo);
        Debit.SetRange("Location Code", SourceLocation);
        Debit.SetRange("In Transit", false);
        Debit.SetFilter("Quantity (Base)", '<0');
        if Debit.FindFirst() then begin
            if (Debit.Count() <> 1) or (Debit."Quantity (Base)" <> -QuantityBase) then
                exit(false);
            PreviousOperation := Debit."Operation No.";
            Debited := true;
            exit(true);
        end;
        if IsReturn then begin
            PreviousOperation := CurrentOperation;
            exit(true);
        end;
        FilterWIPTransferSourceIdentity(Line, ProductionLine, Routing);
        if Line.Get(TransferOrderNo, OriginalLineNo) then
            if MatchesWIPPostedIdentity(Line, ProductionLine, Routing, CurrentOperation) and
               (Line."Transfer-from Code" = SourceLocation)
            then begin
                PreviousOperation := Line."Prev. Operation No.";
                exit(true);
            end;
        if DerivedLineNo <> 0 then
            if Line.Get(TransferOrderNo, DerivedLineNo) then
                if MatchesWIPPostedIdentity(Line, ProductionLine, Routing, CurrentOperation) and
                   (Line."Derived From Line No." = OriginalLineNo) and
                   (Line."Transfer-from Code" = SourceLocation)
                then begin
                    PreviousOperation := Line."Prev. Operation No.";
                    exit(true);
                end;
        exit(false);
    end;

    local procedure MatchesWIPPostedIdentity(Line: Record "Transfer Line"; ProductionLine: Record "Prod. Order Line"; Routing: Record "Prod. Order Routing Line"; CurrentOperation: Code[10]): Boolean
    begin
        exit(Line."Transfer WIP Item" and not Line."Subc. Return Order" and
             (Line."Subc. Prod. Order No." = ProductionLine."Prod. Order No.") and
             (Line."Subc. Prod. Order Line No." = ProductionLine."Line No.") and
             (Line."Subc. Routing No." = Routing."Routing No.") and
             (Line."Subc. Routing Reference No." = Routing."Routing Reference No.") and
             (Line."Subc. Operation No." = CurrentOperation) and
             (Line."Item No." = ProductionLine."Item No.") and (Line."Variant Code" = ProductionLine."Variant Code"));
    end;

    procedure ChangeLocationOnProdOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; VendorSubcontrLocation: Code[10]; OriginalLocationCode: Code[10]; OriginalBinCode: Code[20])
    begin
#if not CLEAN28
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        case ProdOrderComponent."Component Supply Method" of
            "Component Supply Method"::"Consignment at Vendor",
            "Component Supply Method"::"Vendor-Supplied":
                if (VendorSubcontrLocation <> '') and (ProdOrderComponent."Location Code" <> VendorSubcontrLocation) then
                    ValidateProdOrderCompLocationPreservingFlushingMethod(ProdOrderComponent, VendorSubcontrLocation);

            "Component Supply Method"::"Transfer to Vendor",
            "Component Supply Method"::Empty:
                begin
                    if (ProdOrderComponent."Location Code" <> OriginalLocationCode) and (OriginalLocationCode <> '') then begin
                        ValidateProdOrderCompLocationPreservingFlushingMethod(ProdOrderComponent, OriginalLocationCode);
                        ProdOrderComponent."Subc. Original Location Code" := '';
                    end;
                    if (ProdOrderComponent."Bin Code" <> OriginalBinCode) and (OriginalBinCode <> '') then begin
                        ProdOrderComponent.Validate("Bin Code", OriginalBinCode);
                        ProdOrderComponent."Subc. Orig. Bin Code" := '';
                    end;
                end;
        end;
    end;

    internal procedure ValidateProdOrderCompLocationPreservingFlushingMethod(var ProdOrderComponent: Record "Prod. Order Component"; NewLocationCode: Code[10])
    var
        PreservedFlushingMethod: Enum "Flushing Method";
        PreservedLocationCode: Code[10];
        PreservedBinCode: Code[20];
    begin
        // Validating "Location Code" re-reads the planning parameters from the item or SKU (Prod. Order Component.GetUpdateFromSKU),
        // which silently overwrites a manually chosen "Flushing Method". Subcontracting only shuttles the component between the
        // shop floor and the subcontractor location, so a manually set "Flushing Method" must survive that automatic move.
        // The "Flushing Method" is restored by direct assignment on purpose: re-validating it errors once consumption has been
        // posted at the subcontractor (see the return leg), which is a lifecycle subcontracting must support.
        PreservedFlushingMethod := ProdOrderComponent."Flushing Method";
        PreservedLocationCode := ProdOrderComponent."Location Code";
        PreservedBinCode := ProdOrderComponent."Bin Code";

        ProdOrderComponent.Validate("Location Code", NewLocationCode);

        if ProdOrderComponent."Flushing Method" <> PreservedFlushingMethod then
            ProdOrderComponent."Flushing Method" := PreservedFlushingMethod;

        // Restoring the "Flushing Method" by direct assignment does not undo the "Bin Code" that the "Location Code"/temporary
        // "Flushing Method" validation already derived (GetDefaultBin/GetUpdateFromSKU -> UpdateBin). Realign the default bin with
        // the preserved flushing method so it never lingers on the bin picked for the item/SKU flushing method.
        if ProdOrderComponent."Location Code" <> PreservedLocationCode then
            // The component actually moved: recompute the default bin, now evaluated against the preserved flushing method.
            ProdOrderComponent.GetDefaultBin()
        else
            // Same location (e.g. the direct-transfer post revalidates the current location to trigger side effects): keep the
            // component on the bin it already had instead of the one derived for the temporary flushing method.
            ProdOrderComponent."Bin Code" := PreservedBinCode;
    end;

    procedure ChangeLocationOnPlanningComponent(var PlanningComponent: Record "Planning Component"; VendorSubcontrLocation: Code[10]; OriginalLocationCode: Code[10]; OriginalBinCode: Code[20])
    begin
#if not CLEAN28
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        case PlanningComponent."Component Supply Method" of
            "Component Supply Method"::"Consignment at Vendor",
            "Component Supply Method"::"Vendor-Supplied":
                if (VendorSubcontrLocation <> '') and (PlanningComponent."Location Code" <> VendorSubcontrLocation) then
                    PlanningComponent.Validate("Location Code", VendorSubcontrLocation);

            "Component Supply Method"::"Transfer to Vendor",
            "Component Supply Method"::Empty:
                begin
                    if (PlanningComponent."Location Code" <> OriginalLocationCode) and (OriginalLocationCode <> '') then begin
                        PlanningComponent.Validate("Location Code", OriginalLocationCode);
                        PlanningComponent."Orig. Location Code" := '';
                    end;
                    if (PlanningComponent."Bin Code" <> OriginalBinCode) and (OriginalBinCode <> '') then begin
                        PlanningComponent.Validate("Bin Code", OriginalBinCode);
                        PlanningComponent."Orig. Bin Code" := '';
                    end;
                end;
        end;
    end;

    procedure DelLocationLinkedComponents(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ShowMsg: Boolean)
    var
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderLine: Record "Prod. Order Line";
        StockkeepingUnit: Record "Stockkeeping Unit";
        ConfirmManagement: Codeunit "Confirm Management";
        PlanningGetParameters: Codeunit "Planning-Get Parameters";
    begin
#if not CLEAN28
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        ProdOrderComponent.SetRange(Status, ProdOrderRoutingLine.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        ProdOrderComponent.SetRange("Prod. Order Line No.", ProdOrderRoutingLine."Routing Reference No.");
        ProdOrderComponent.SetRange("Routing Link Code", ProdOrderRoutingLine."Routing Link Code");
        if not ProdOrderComponent.IsEmpty() then begin
            ProdOrderComponent.FindSet();
            if ShowMsg then
                if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(RoutingLinkUpdConfQst, ProdOrderRoutingLine."Routing Link Code"), true) then
                    Error(UpdateIsCancelledErr);

            ProdOrderLine.SetLoadFields("Item No.", "Variant Code", "Location Code");
            ProdOrderLine.Get(ProdOrderRoutingLine.Status, ProdOrderComponent."Prod. Order No.", ProdOrderComponent."Prod. Order Line No.");
            PlanningGetParameters.AtSKU(
              StockkeepingUnit,
              ProdOrderLine."Item No.",
              ProdOrderLine."Variant Code",
              ProdOrderLine."Location Code");
            repeat
                ProdOrderComponent.Validate("Location Code", StockkeepingUnit."Components at Location");
                ProdOrderComponent.Modify();
            until ProdOrderComponent.Next() = 0;

            if ShowMsg then
                Message(SuccessfullyUpdatedMsg);
        end;
    end;

    procedure GetSubcontractor(WorkCenterNo: Code[20]; var Vendor: Record Vendor): Boolean
    var
        WorkCenter: Record "Work Center";
        HasSubcontractor, IsHandled : Boolean;
    begin
#if not CLEAN28
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit(false);

#endif
        OnBeforeGetSubcontractor(WorkCenterNo, Vendor, HasSubcontractor, IsHandled);//DO NOT DELETE
        if IsHandled then
            exit(HasSubcontractor);

        WorkCenter.SetLoadFields("Subcontractor No.");
        WorkCenter.Get(WorkCenterNo);
        if WorkCenter."Subcontractor No." <> '' then begin
            Vendor.SetLoadFields("Subc. Location Code");
            if not Vendor.Get(WorkCenter."Subcontractor No.") then
                Error(WorkCenterVendorDoesntExistErr, WorkCenter."Subcontractor No.", WorkCenter."No.");
            Vendor.TestField("Subc. Location Code");
            exit(true);
        end;
        exit(false);
    end;

    internal procedure GetOperationSubcontractor(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var Vendor: Record Vendor): Boolean
    var
        WorkCenter: Record "Work Center";
    begin
        if (ProdOrderRoutingLine.Type <> ProdOrderRoutingLine.Type::"Work Center") or (ProdOrderRoutingLine."No." = '') then
            exit(false);
        WorkCenter.SetLoadFields("Subcontractor No.");
        WorkCenter.Get(ProdOrderRoutingLine."No.");
        if WorkCenter."Subcontractor No." = '' then
            exit(false);
        if ProdOrderRoutingLine."Subc. Subcontractor No." = '' then
            exit(GetSubcontractor(ProdOrderRoutingLine."No.", Vendor));
        Vendor.Get(ProdOrderRoutingLine."Subc. Subcontractor No.");
        Vendor.TestField("Subc. Location Code");
        exit(true);
    end;

    internal procedure CheckSubcontractingWorkCenter(WorkCenterNo: Code[20])
    var
        WorkCenter: Record "Work Center";
    begin
        WorkCenter.SetLoadFields("Subcontractor No.", "Gen. Prod. Posting Group");
        WorkCenter.Get(WorkCenterNo);
        WorkCenter.TestField("Subcontractor No.");
        WorkCenter.TestField("Gen. Prod. Posting Group");
    end;

    internal procedure CheckProdNotBlockedForOutput(ItemNo: Code[20]; VariantCode: Code[20])
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
    begin
        if ItemNo = '' then
            exit;

        Item.SetLoadFields("Production Blocked");
        Item.Get(ItemNo);
        if Item."Production Blocked" = Item."Production Blocked"::Output then
            Error(ProductionBlockedOutputItemErr, Item.TableCaption(), ItemNo, Item.FieldCaption("Production Blocked"), Item."Production Blocked");

        if VariantCode <> '' then begin
            ItemVariant.SetLoadFields("Production Blocked");
            ItemVariant.Get(ItemNo, VariantCode);
            if ItemVariant."Production Blocked" = ItemVariant."Production Blocked"::Output then
                Error(ProductionBlockedOutputItemVariantErr, VariantCode, Item.TableCaption(), ItemNo);
        end;
    end;

    internal procedure SetSubcontractingOrderDate(var RequisitionLine: Record "Requisition Line"; RoutingStartingDate: Date)
    var
        LeadTimeManagement: Codeunit "Lead-Time Management";
    begin
        RequisitionLine.Validate(
            "Order Date",
            LeadTimeManagement.GetPlannedStartingDate(
                RequisitionLine."No.", RequisitionLine."Location Code", RequisitionLine."Variant Code", RequisitionLine."Vendor No.",
                LeadTimeManagement.PurchaseLeadTime(
                    RequisitionLine."No.", RequisitionLine."Location Code", RequisitionLine."Variant Code", RequisitionLine."Vendor No."),
                RequisitionLine."Ref. Order Type"::Purchase, RoutingStartingDate));
    end;

    procedure UpdateSubcontractorPriceForRequisitionLine(var RequisitionLine: Record "Requisition Line")
    begin
#if not CLEAN28
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        if IsSubcontracting(RequisitionLine."Work Center No.") then
            RequisitionLine.UpdateSubcontractorPrice();
    end;

    procedure UpdateLinkedComponentsAfterRoutingTransfer(var ProdOrderLine: Record "Prod. Order Line"; var RoutingLine: Record "Routing Line"; var ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    var
        WorkCenter: Record "Work Center";
    begin
#if not CLEAN28
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        if ProdOrderRoutingLine.Type <> "Capacity Type"::"Work Center" then
            exit;

        if ProdOrderRoutingLine."Routing Link Code" = '' then
            exit;

        WorkCenter.SetLoadFields("Subcontractor No.");
        WorkCenter.Get(RoutingLine."Work Center No.");
        if WorkCenter."Subcontractor No." = '' then
            exit;

        UpdLinkedComponents(ProdOrderRoutingLine, false);
    end;

    procedure UpdateComponentSupplyMethodForPlanningComponent(var PlanningComponent: Record "Planning Component")
    var
        PlanningRoutingLine: Record "Planning Routing Line";
        Vendor: Record Vendor;
        OrigLocationCode, VendorSubcontractingLocationCode : Code[10];
        OrigBinCode: Code[20];
    begin
#if not CLEAN28
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        if PlanningComponent."Routing Link Code" = '' then
            exit;

        PlanningRoutingLine.SetRange("Worksheet Template Name", PlanningComponent."Worksheet Template Name");
        PlanningRoutingLine.SetRange("Worksheet Batch Name", PlanningComponent."Worksheet Batch Name");
        PlanningRoutingLine.SetRange("Worksheet Line No.", PlanningComponent."Worksheet Line No.");
        PlanningRoutingLine.SetRange("Routing Link Code", PlanningComponent."Routing Link Code");
        PlanningRoutingLine.SetRange(Type, "Capacity Type"::"Work Center");
        if not PlanningRoutingLine.IsEmpty() then begin
            PlanningRoutingLine.SetLoadFields("No.");
            PlanningRoutingLine.FindFirst();

            if not GetSubcontractor(PlanningRoutingLine."No.", Vendor) then
                Clear(Vendor);
            if PlanningComponent."Component Supply Method" in ["Component Supply Method"::"Consignment at Vendor", "Component Supply Method"::"Vendor-Supplied"] then
                VendorSubcontractingLocationCode := Vendor."Subc. Location Code";
            OrigLocationCode := PlanningComponent."Orig. Location Code";
            OrigBinCode := PlanningComponent."Orig. Bin Code";

            ChangeLocationOnPlanningComponent(PlanningComponent, VendorSubcontractingLocationCode, OrigLocationCode, OrigBinCode);

            PlanningComponent.Modify();
        end;
    end;

    procedure UpdateComponentSupplyMethodForProdOrderComponent(var ProdOrderComponent: Record "Prod. Order Component")
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        Vendor: Record Vendor;
        ProdOrderCompFound: Boolean;
        OrigLocationCode, VendorSubcontractingLocationCode : Code[10];
        OrigBinCode: Code[20];
        PurchOrderNo: Code[20];
    begin
#if not CLEAN28
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        if ProdOrderComponent."Routing Link Code" = '' then
            exit;

        ProdOrderLine.SetLoadFields("Routing Reference No.", "Routing No.");
        ProdOrderLine.Get(ProdOrderComponent.Status, ProdOrderComponent."Prod. Order No.", ProdOrderComponent."Prod. Order Line No.");

        ProdOrderRoutingLine.SetRange(Status, ProdOrderComponent.Status);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrderComponent."Prod. Order No.");
        ProdOrderRoutingLine.SetRange("Routing No.", ProdOrderLine."Routing No.");
        ProdOrderRoutingLine.SetRange("Routing Reference No.", ProdOrderLine."Routing Reference No.");
        ProdOrderRoutingLine.SetRange("Routing Link Code", ProdOrderComponent."Routing Link Code");
        ProdOrderRoutingLine.SetLoadFields("Prod. Order No.", Type, "No.");
        if ProdOrderRoutingLine.FindFirst() then begin
            PurchaseLine.SetRange("Document Type", "Purchase Document Type"::Order);
            PurchaseLine.SetRange("Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
            PurchaseLine.SetLoadFields(SystemId);
            if PurchaseLine.FindSet() then
                repeat
                    if PurchOrderNo <> PurchaseLine."Document No." then begin
                        PurchOrderNo := PurchaseLine."Document No.";
                        PurchaseLine2.SetRange("Document Type", PurchaseLine."Document Type");
                        PurchaseLine2.SetRange("Document No.", PurchaseLine."Document No.");
                        PurchaseLine2.SetRange(Type, "Purchase Line Type"::Item);
                        PurchaseLine2.SetRange("No.", ProdOrderComponent."Item No.");
                        ProdOrderCompFound := not PurchaseLine2.IsEmpty();
                    end;
                until (PurchaseLine.Next() = 0) or ProdOrderCompFound;
            if ProdOrderCompFound then
                Error(PurchOrderExistErr, ProdOrderComponent."Item No.", PurchOrderNo, ProdOrderComponent.FieldCaption("Component Supply Method"));

            if ProdOrderRoutingLine.Type = "Capacity Type"::"Work Center" then begin
                if not GetOperationSubcontractor(ProdOrderRoutingLine, Vendor) then
                    Clear(Vendor);

                VendorSubcontractingLocationCode := Vendor."Subc. Location Code";
                if not (ProdOrderComponent."Component Supply Method" in ["Component Supply Method"::"Consignment at Vendor", "Component Supply Method"::"Vendor-Supplied"]) then
                    Clear(VendorSubcontractingLocationCode);
                OrigLocationCode := ProdOrderComponent."Subc. Original Location Code";
                OrigBinCode := ProdOrderComponent."Subc. Orig. Bin Code";

                ChangeLocationOnProdOrderComponent(ProdOrderComponent, VendorSubcontractingLocationCode, OrigLocationCode, OrigBinCode);

                ProdOrderComponent.Modify();
            end;
        end;
    end;

    internal procedure UpdateOperationConsignmentLocations(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; VendorLocationCode: Code[10])
    var
        ProductionLine: Record "Prod. Order Line";
        Component: Record "Prod. Order Component";
        OriginalLocationCode: Code[10];
        OriginalBinCode: Code[20];
    begin
        if ProdOrderRoutingLine."Routing Link Code" = '' then
            exit;

        ProductionLine.SetRange(Status, ProdOrderRoutingLine.Status);
        ProductionLine.SetRange("Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        ProductionLine.SetRange("Routing No.", ProdOrderRoutingLine."Routing No.");
        ProductionLine.SetRange("Routing Reference No.", ProdOrderRoutingLine."Routing Reference No.");
        if ProductionLine.FindSet() then
            repeat
                Component.SetRange(Status, ProductionLine.Status);
                Component.SetRange("Prod. Order No.", ProductionLine."Prod. Order No.");
                Component.SetRange("Prod. Order Line No.", ProductionLine."Line No.");
                Component.SetRange("Routing Link Code", ProdOrderRoutingLine."Routing Link Code");
                Component.SetRange("Component Supply Method", Component."Component Supply Method"::"Consignment at Vendor");
                Component.SetFilter("Location Code", '<>%1', VendorLocationCode);
                if Component.FindSet(true) then
                    repeat
                        OriginalLocationCode := Component."Subc. Original Location Code";
                        OriginalBinCode := Component."Subc. Orig. Bin Code";
                        ValidateProdOrderCompLocationPreservingFlushingMethod(Component, VendorLocationCode);
                        // Keep the shop-floor origin, not the previous subcontractor's location.
                        Component."Subc. Original Location Code" := OriginalLocationCode;
                        Component."Subc. Orig. Bin Code" := OriginalBinCode;
                        Component.Modify(true);
                    until Component.Next() = 0;
            until ProductionLine.Next() = 0;
    end;

    procedure UpdLinkedComponents(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ShowMsg: Boolean)
    var
        ProdOrderComponent: Record "Prod. Order Component";
        Vendor: Record Vendor;
        ConfirmManagement: Codeunit "Confirm Management";
        Subcontracting: Boolean;
        OrigLocationCode, VendorSubcontractingLocationCode : Code[10];
        OrigBinCode: Code[20];
    begin
#if not CLEAN28
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        ProdOrderComponent.SetRange(Status, ProdOrderRoutingLine.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        ProdOrderComponent.SetRange("Prod. Order Line No.", ProdOrderRoutingLine."Routing Reference No.");
        ProdOrderComponent.SetRange("Routing Link Code", ProdOrderRoutingLine."Routing Link Code");
        if ProdOrderComponent.FindSet() then begin
            if ProdOrderRoutingLine.Type = "Capacity Type"::"Work Center" then
                Subcontracting := GetOperationSubcontractor(ProdOrderRoutingLine, Vendor);

            if Subcontracting then begin
                VendorSubcontractingLocationCode := Vendor."Subc. Location Code";
                if ShowMsg then
                    if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(RoutingLinkUpdConfQst, ProdOrderRoutingLine."Routing Link Code"), true) then
                        Error(UpdateIsCancelledErr);
                repeat
                    if not (ProdOrderComponent."Component Supply Method" in ["Component Supply Method"::"Consignment at Vendor", "Component Supply Method"::"Vendor-Supplied"]) then
                        Clear(VendorSubcontractingLocationCode);
                    OrigLocationCode := ProdOrderComponent."Subc. Original Location Code";
                    OrigBinCode := ProdOrderComponent."Subc. Orig. Bin Code";

                    ChangeLocationOnProdOrderComponent(ProdOrderComponent, VendorSubcontractingLocationCode, OrigLocationCode, OrigBinCode);

                    ProdOrderComponent.Modify();
                until ProdOrderComponent.Next() = 0;

                if ShowMsg then
                    Message(SuccessfullyUpdatedMsg);
            end;
        end;
    end;

    /// <summary>
    /// Gets the location code for production order components based on the setup field "Subc. Default Comp. Location".
    /// The location code is retrieved from the purchase line, company information, or manufacturing setup.
    /// </summary>
    /// <returns>The components location code.</returns>
    procedure GetComponentsLocationCode(PurchaseLine: Record "Purchase Line"): Code[10]
    var
        CompanyInformation: Record "Company Information";
        ComponentsLocationCode: Code[10];
    begin
#if not CLEAN28
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit('');

#endif
        GetManufacturingSetup();
        ManufacturingSetup.TestField("Subc. Default Comp. Location");

        case ManufacturingSetup."Subc. Default Comp. Location" of
            "Components at Location"::Purchase:
                begin
                    PurchaseLine.TestField("Location Code");
                    ComponentsLocationCode := PurchaseLine."Location Code";
                end;
            "Components at Location"::Company:
                begin
                    CompanyInformation.SetLoadFields("Location Code");
                    CompanyInformation.Get();
                    CompanyInformation.TestField("Location Code");
                    ComponentsLocationCode := CompanyInformation."Location Code";
                end;
            "Components at Location"::Manufacturing:
                begin
                    ManufacturingSetup.SetLoadFields("Components at Location");
                    ManufacturingSetup.Get();
                    ManufacturingSetup.TestField("Components at Location");
                    ComponentsLocationCode := ManufacturingSetup."Components at Location";
                end;
        end;

        exit(ComponentsLocationCode);
    end;

    internal procedure IsSubcontractingPurchaseDocument(PurchaseHeader: Record "Purchase Header"): Boolean
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetFilter("Prod. Order No.", '<>%1', '');
        PurchaseLine.SetFilter("Prod. Order Line No.", '<>%1', 0);
        exit(not PurchaseLine.IsEmpty());
    end;

    internal procedure IsSubcontractingPurchaseLine(PurchaseLine: Record "Purchase Line"): Boolean
    begin
        exit((PurchaseLine."Prod. Order No." <> '') and (PurchaseLine."Prod. Order Line No." <> 0));
    end;

    local procedure GetManufacturingSetup()
    begin
        if HasManufacturingSetup then
            exit;
        HasManufacturingSetup := ManufacturingSetup.Get();
    end;

    local procedure IsSubcontracting(WorkCenterNo: Code[20]): Boolean
    var
        WorkCenter: Record "Work Center";
    begin
        WorkCenter.SetLoadFields("Subcontractor No.");
        if WorkCenter.Get(WorkCenterNo) then
            exit(WorkCenter."Subcontractor No." <> '')
    end;

    [InternalEvent(false, false)]
    local procedure OnBeforeGetSubcontractor(WorkCenterNo: Code[20]; var Vendor: Record Vendor; var HasSubcontractor: Boolean; var IsHandled: Boolean)
    begin
    end;
}
