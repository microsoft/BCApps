// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Foundation.Enums;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Warehouse.Document;

codeunit 99001541 "Subc. Transfer WIP Posting"
{

    Permissions = TableData "Subcontractor WIP Ledger Entry" = RIMD;

    var
        WIPLedgEntryNo: Integer;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Line", OnBeforeValidateQuantityShipIsBalanced, '', false, false)]
    local procedure HandleWipTransferOnBeforeValidateQuantityShipIsBalanced(var TransferLine: Record "Transfer Line"; xTransferLine: Record "Transfer Line"; var IsHandled: Boolean)
    begin
        if TransferLine."Transfer WIP Item" then
            IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Line", OnBeforeValidateQuantityReceiveIsBalanced, '', false, false)]
    local procedure HandleWipTransferOnBeforeValidateQuantityReceiveIsBalanced(var TransferLine: Record "Transfer Line"; xTransferLine: Record "Transfer Line"; var IsHandled: Boolean)
    begin
        if TransferLine."Transfer WIP Item" then
            IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Shipment", OnBeforeCheckItemInInventory, '', false, false)]
    local procedure HandleWipTransferOnBeforeCheckItemInInventory(TransferLine: Record "Transfer Line"; var IsHandled: Boolean)
    begin
        if TransferLine."Transfer WIP Item" then
            IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Check Line", OnBeforeCheckEmptyQuantity, '', false, false)]
    local procedure HandleWipTransferOnBeforeCheckEmptyQuantity(ItemJnlLine: Record "Item Journal Line"; var IsHandled: Boolean)
    var
        TransferLine: Record "Transfer Line";
    begin
        TransferLine.SetLoadFields("Transfer WIP Item");
        if ItemJnlLine."Order Type" = "Inventory Order Type"::Transfer then
            if TransferLine.Get(ItemJnlLine."Order No.", ItemJnlLine."Order Line No.") then
                if TransferLine."Transfer WIP Item" then
                    IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Shipment Line", OnAfterCopyFromTransferLine, '', false, false)]
    local procedure HandleWipTransferShipmentLineOnAfterCopyFromTransferLine(var TransferShipmentLine: Record "Transfer Shipment Line"; TransferLine: Record "Transfer Line")
    var
        TransferHeader: Record "Transfer Header";
    begin
        TransferHeader.SetLoadFields("Posting Date");
        TransferHeader.Get(TransferLine."Document No.");
        TransferShipmentLine."Transfer WIP Item" := TransferLine."Transfer WIP Item";
        CreateWIPLedgerEntryForShipment(TransferShipmentLine, TransferLine, TransferHeader);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Receipt Line", OnAfterCopyFromTransferLine, '', false, false)]
    local procedure HandleWipTransferReceiptLineOnAfterCopyFromTransferLine(var TransferReceiptLine: Record "Transfer Receipt Line"; TransferLine: Record "Transfer Line")
    var
        TransferHeader: Record "Transfer Header";
    begin
        TransferHeader.SetLoadFields("Posting Date");
        TransferHeader.Get(TransferLine."Document No.");
        TransferReceiptLine."Transfer WIP Item" := TransferLine."Transfer WIP Item";
        CreateWIPLedgerEntryForReceive(TransferReceiptLine, TransferLine, TransferHeader);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Direct Trans. Line", OnAfterCopyFromTransferLine, '', false, false)]
    local procedure HandleWipDirectTransLineOnAfterCopyFromTransferLine(var DirectTransLine: Record "Direct Trans. Line"; TransferLine: Record "Transfer Line")
    var
        TransferHeader: Record "Transfer Header";
    begin
        TransferHeader.SetLoadFields("Posting Date");
        TransferHeader.Get(TransferLine."Document No.");
        DirectTransLine."Transfer WIP Item" := TransferLine."Transfer WIP Item";
        CreateWIPLedgerEntryForDirectTransfer(DirectTransLine, TransferLine, TransferHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Undo Transfer Shipment", OnNoItemLedgerEntriesCheckIsNeeded, '', false, false)]
    local procedure HandleWipTransferOnNoItemLedgerEntriesCheckIsNeeded(TransShptLine: Record "Transfer Shipment Line"; var NoCheckNeeded: Boolean)
    begin
        if TransShptLine."Transfer WIP Item" then
            NoCheckNeeded := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Line", OnBeforeShowReservation, '', false, false)]
    local procedure HandleWipTransferOnBeforeShowReservation(var TransferLine: Record "Transfer Line"; var IsHandled: Boolean)
    begin
        TransferLine.TestField("Transfer WIP Item", false);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", OnSetReservSource, '', false, false)]
    local procedure HandleWipTransferOnSetReservSource(var Sender: Codeunit "Reservation Management"; SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; Direction: Enum "Transfer Direction"; var RefOrderType: Enum "Requisition Ref. Order Type"; var PlanningLineOrigin: Enum "Planning Line Origin Type"; Positive: Boolean)
    var
        TransferLine: Record "Transfer Line";
    begin
        if SourceRecRef.Number = Database::"Transfer Line" then begin
            SourceRecRef.SetTable(TransferLine);
            TransferLine.CheckForExistingReservationsOrItemTracking();
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Line", OnBeforeOpenItemTrackingLines, '', false, false)]
    local procedure HandleWipTransferOnBeforeOpenItemTrackingLines(var TransferLine: Record "Transfer Line"; var IsHandled: Boolean)
    begin
        TransferLine.TestField("Transfer WIP Item", false);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Transfer Warehouse Mgt.", OnBeforeCheckIfTransLine2ReceiptLine, '', false, false)]
    local procedure HandleWipTransferOnBeforeCheckIfTransLine2ReceiptLine(var TransferLine: Record "Transfer Line"; var IsHandled: Boolean; var ReturnValue: Boolean)
    var
        Location: Record Location;
    begin
        if TransferLine."Transfer WIP Item" then begin
            TransferLine.CalcFields("Whse. Inbnd. Otsdg. Qty");
            if Location.GetLocationSetup(TransferLine."Transfer-to Code", Location) then
                if Location."Use As In-Transit" then begin
                    IsHandled := true;
                    ReturnValue := false;
                    exit;
                end;
            IsHandled := true;
            ReturnValue := (TransferLine."Qty. in Transit" > TransferLine."Whse. Inbnd. Otsdg. Qty");
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Transfer Warehouse Mgt.", OnTransLine2ReceiptLineOnAfterInitNewLine, '', false, false)]
    local procedure HandleWipTransferOnTransLine2ReceiptLineOnAfterInitNewLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; WarehouseReceiptHeader: Record "Warehouse Receipt Header"; TransferLine: Record "Transfer Line"; var QtyOnRcptLineSet: Boolean)
    begin
        WarehouseReceiptLine."Transfer WIP Item" := TransferLine."Transfer WIP Item";
        if WarehouseReceiptLine."Transfer WIP Item" then begin
            WarehouseReceiptLine.Validate(WarehouseReceiptLine."Qty. Received", TransferLine."Quantity Received");
            TransferLine.CalcFields("Whse. Inbnd. Otsdg. Qty");
            WarehouseReceiptLine.Quantity := TransferLine."Quantity Received" + TransferLine."Qty. in Transit" - TransferLine."Whse. Inbnd. Otsdg. Qty";
            WarehouseReceiptLine."Qty. (Base)" := 0;
            WarehouseReceiptLine.InitOutstandingQtys();
            QtyOnRcptLineSet := true;
        end;
    end;

    local procedure CreateWIPLedgerEntryForShipment(var TransferShipmentLine: Record "Transfer Shipment Line"; var TransferLine: Record "Transfer Line"; TransferHeader: Record "Transfer Header")
    var
        Location: Record Location;
        SubcontractorWIPLedgerEntry: Record "Subcontractor WIP Ledger Entry";
    begin
        if not TransferShipmentLine."Transfer WIP Item" then
            exit;

        if IsUsedAsSubcontractingLocation(TransferLine."Transfer-from Code") then begin
            Location.Get(TransferLine."Transfer-from Code");
            InitWIPItemLedgerEntry(SubcontractorWIPLedgerEntry, TransferHeader."Posting Date");
            SubcontractorWIPLedgerEntry."Entry Type" := "WIP Ledger Entry Type"::"Negative Adjustment";
            SubcontractorWIPLedgerEntry."Location Code" := TransferLine."Transfer-from Code";
            SubcontractorWIPLedgerEntry."In Transit" := false;
            AssignFieldsFromTransferLine(SubcontractorWIPLedgerEntry, TransferLine, true);
            SubcontractorWIPLedgerEntry."Quantity (Base)" := -TransferLine.CalcBaseQty(TransferShipmentLine.Quantity);
            AssignSourceDocument(SubcontractorWIPLedgerEntry, "WIP Document Type"::"Transfer Order", TransferShipmentLine."Document No.", TransferShipmentLine."Line No.");
            InsertWIPItemLedgerEntry(SubcontractorWIPLedgerEntry);
        end;

        if TransferLine."In-Transit Code" <> '' then begin
            InitWIPItemLedgerEntry(SubcontractorWIPLedgerEntry, TransferHeader."Posting Date");
            SubcontractorWIPLedgerEntry."Entry Type" := "WIP Ledger Entry Type"::"Positive Adjustment";
            SubcontractorWIPLedgerEntry."Location Code" := TransferLine."In-Transit Code";
            SubcontractorWIPLedgerEntry."In Transit" := true;
            AssignFieldsFromTransferLine(SubcontractorWIPLedgerEntry, TransferLine, true);
            SubcontractorWIPLedgerEntry."Quantity (Base)" := TransferLine.CalcBaseQty(TransferShipmentLine.Quantity);
            AssignSourceDocument(SubcontractorWIPLedgerEntry, "WIP Document Type"::"Transfer Order", TransferShipmentLine."Document No.", TransferShipmentLine."Line No.");
            InsertWIPItemLedgerEntry(SubcontractorWIPLedgerEntry);
        end;
    end;

    local procedure CreateWIPLedgerEntryForReceive(var TransferReceiptLine: Record "Transfer Receipt Line"; var TransferLine: Record "Transfer Line"; TransferHeader: Record "Transfer Header")
    var
        SubcontractorWIPLedgerEntry: Record "Subcontractor WIP Ledger Entry";
    begin
        if not TransferReceiptLine."Transfer WIP Item" then
            exit;

        if TransferLine."In-Transit Code" <> '' then begin
            InitWIPItemLedgerEntry(SubcontractorWIPLedgerEntry, TransferHeader."Posting Date");
            SubcontractorWIPLedgerEntry."Entry Type" := "WIP Ledger Entry Type"::"Negative Adjustment";
            SubcontractorWIPLedgerEntry."Location Code" := TransferLine."In-Transit Code";
            SubcontractorWIPLedgerEntry."In Transit" := true;
            AssignFieldsFromTransferLine(SubcontractorWIPLedgerEntry, TransferLine, false);
            SubcontractorWIPLedgerEntry."Quantity (Base)" := -TransferLine.CalcBaseQty(TransferReceiptLine.Quantity);
            AssignSourceDocument(SubcontractorWIPLedgerEntry, "WIP Document Type"::"Transfer Order", TransferReceiptLine."Document No.", TransferReceiptLine."Line No.");
            InsertWIPItemLedgerEntry(SubcontractorWIPLedgerEntry);
        end;

        if IsUsedAsSubcontractingLocation(TransferLine."Transfer-to Code") then begin
            InitWIPItemLedgerEntry(SubcontractorWIPLedgerEntry, TransferHeader."Posting Date");
            SubcontractorWIPLedgerEntry."Entry Type" := "WIP Ledger Entry Type"::"Positive Adjustment";
            SubcontractorWIPLedgerEntry."Location Code" := TransferLine."Transfer-to Code";
            SubcontractorWIPLedgerEntry."In Transit" := false;
            AssignFieldsFromTransferLine(SubcontractorWIPLedgerEntry, TransferLine, false);
            SubcontractorWIPLedgerEntry."Quantity (Base)" := TransferLine.CalcBaseQty(TransferReceiptLine.Quantity);
            AssignSourceDocument(SubcontractorWIPLedgerEntry, "WIP Document Type"::"Transfer Order", TransferReceiptLine."Document No.", TransferReceiptLine."Line No.");
            InsertWIPItemLedgerEntry(SubcontractorWIPLedgerEntry);
        end;
    end;

    local procedure CreateWIPLedgerEntryForDirectTransfer(var DirectTransLine: Record "Direct Trans. Line"; var TransferLine: Record "Transfer Line"; TransferHeader: Record "Transfer Header")
    var
        SubcontractorWIPLedgerEntry: Record "Subcontractor WIP Ledger Entry";
    begin
        if not DirectTransLine."Transfer WIP Item" then
            exit;

        if IsUsedAsSubcontractingLocation(TransferLine."Transfer-from Code") then begin
            InitWIPItemLedgerEntry(SubcontractorWIPLedgerEntry, TransferHeader."Posting Date");
            SubcontractorWIPLedgerEntry."Entry Type" := "WIP Ledger Entry Type"::"Negative Adjustment";
            SubcontractorWIPLedgerEntry."Location Code" := TransferLine."Transfer-from Code";
            SubcontractorWIPLedgerEntry."In Transit" := false;
            AssignFieldsFromTransferLine(SubcontractorWIPLedgerEntry, TransferLine, true);
            SubcontractorWIPLedgerEntry."Quantity (Base)" := -TransferLine.CalcBaseQty(DirectTransLine.Quantity);
            AssignSourceDocument(SubcontractorWIPLedgerEntry, "WIP Document Type"::"Transfer Order", DirectTransLine."Document No.", DirectTransLine."Line No.");
            InsertWIPItemLedgerEntry(SubcontractorWIPLedgerEntry);
        end;

        if IsUsedAsSubcontractingLocation(TransferLine."Transfer-to Code") then begin
            InitWIPItemLedgerEntry(SubcontractorWIPLedgerEntry, TransferHeader."Posting Date");
            SubcontractorWIPLedgerEntry."Entry Type" := "WIP Ledger Entry Type"::"Positive Adjustment";
            SubcontractorWIPLedgerEntry."Location Code" := TransferLine."Transfer-to Code";
            SubcontractorWIPLedgerEntry."In Transit" := false;
            AssignFieldsFromTransferLine(SubcontractorWIPLedgerEntry, TransferLine, false);
            SubcontractorWIPLedgerEntry."Quantity (Base)" := TransferLine.CalcBaseQty(DirectTransLine.Quantity);
            AssignSourceDocument(SubcontractorWIPLedgerEntry, "WIP Document Type"::"Transfer Order", DirectTransLine."Document No.", DirectTransLine."Line No.");
            InsertWIPItemLedgerEntry(SubcontractorWIPLedgerEntry);
        end;
    end;

    internal procedure CreateAdjustmentWIPEntriesOnFinishProdOrder(ProductionOrder: Record "Production Order"; PostingDate: Date)
    var
        SubcontractorWIPLedgerEntry: Record "Subcontractor WIP Ledger Entry";
    begin
        SubcontractorWIPLedgerEntry.SetProductionOrderFilter(ProductionOrder, false);
        SearchForAllWIPLedgerEntryCombinationAndCreateAdjustmentEntryToBalanceTheQuantities(SubcontractorWIPLedgerEntry, PostingDate);
    end;

    local procedure SearchForAllWIPLedgerEntryCombinationAndCreateAdjustmentEntryToBalanceTheQuantities(var FilteredWIPLedgerEntry: Record "Subcontractor WIP Ledger Entry"; PostingDate: Date)
    var
        LastWIPEntry: Record "Subcontractor WIP Ledger Entry";
        IsFirstEntry: Boolean;
        TotalQty: Decimal;
    begin
        IsFirstEntry := true;
        TotalQty := 0;

        FilteredWIPLedgerEntry.SetCurrentKey("Prod. Order No.", "Prod. Order Status", "Prod. Order Line No.", "Routing Reference No.", "Routing No.", "Operation No.", "Location Code", "Item No.", "Variant Code");
        if not FilteredWIPLedgerEntry.FindSet() then
            exit;

        repeat
            if not IsFirstEntry then
                if (FilteredWIPLedgerEntry."Prod. Order Line No." <> LastWIPEntry."Prod. Order Line No.") or
                   (FilteredWIPLedgerEntry."Routing Reference No." <> LastWIPEntry."Routing Reference No.") or
                   (FilteredWIPLedgerEntry."Routing No." <> LastWIPEntry."Routing No.") or
                   (FilteredWIPLedgerEntry."Operation No." <> LastWIPEntry."Operation No.") or
                   (FilteredWIPLedgerEntry."Location Code" <> LastWIPEntry."Location Code") or
                   (FilteredWIPLedgerEntry."Item No." <> LastWIPEntry."Item No.") or
                   (FilteredWIPLedgerEntry."Variant Code" <> LastWIPEntry."Variant Code")
                then begin
                    if TotalQty <> 0 then
                        CreateAdjustmentWIPEntry(LastWIPEntry, PostingDate, TotalQty);
                    TotalQty := 0;
                end;

            TotalQty += FilteredWIPLedgerEntry."Quantity (Base)";
            LastWIPEntry := FilteredWIPLedgerEntry;
            IsFirstEntry := false;
        until FilteredWIPLedgerEntry.Next() = 0;

        if TotalQty <> 0 then
            CreateAdjustmentWIPEntry(LastWIPEntry, PostingDate, TotalQty);
    end;

    local procedure CreateAdjustmentWIPEntry(TemplateWIPEntry: Record "Subcontractor WIP Ledger Entry"; PostingDate: Date; TotalQty: Decimal)
    var
        AdjustmentEntry: Record "Subcontractor WIP Ledger Entry";
    begin
        InitWIPItemLedgerEntry(AdjustmentEntry, PostingDate);
        AdjustmentEntry."Item No." := TemplateWIPEntry."Item No.";
        AdjustmentEntry."Variant Code" := TemplateWIPEntry."Variant Code";
        AdjustmentEntry."Unit of Measure Code" := TemplateWIPEntry."Unit of Measure Code";
        AdjustmentEntry."Location Code" := TemplateWIPEntry."Location Code";
        AdjustmentEntry."Prod. Order Status" := TemplateWIPEntry."Prod. Order Status";
        AdjustmentEntry."Prod. Order No." := TemplateWIPEntry."Prod. Order No.";
        AdjustmentEntry."Prod. Order Line No." := TemplateWIPEntry."Prod. Order Line No.";
        AdjustmentEntry."Routing No." := TemplateWIPEntry."Routing No.";
        AdjustmentEntry."Routing Reference No." := TemplateWIPEntry."Routing Reference No.";
        AdjustmentEntry."Operation No." := TemplateWIPEntry."Operation No.";
        AdjustmentEntry."Work Center No." := TemplateWIPEntry."Work Center No.";
        AdjustmentEntry.Description := TemplateWIPEntry.Description;
        AdjustmentEntry."Description 2" := TemplateWIPEntry."Description 2";
        AdjustmentEntry."In Transit" := TemplateWIPEntry."In Transit";
        AdjustmentEntry."Quantity (Base)" := -TotalQty;
        if TotalQty > 0 then
            AdjustmentEntry."Entry Type" := "WIP Ledger Entry Type"::"Negative Adjustment"
        else
            AdjustmentEntry."Entry Type" := "WIP Ledger Entry Type"::"Positive Adjustment";
        AdjustmentEntry."Document Type" := "WIP Document Type"::"Adjustment (Finish Prod Order)";
        AdjustmentEntry."Document No." := TemplateWIPEntry."Prod. Order No.";
        InsertWIPItemLedgerEntry(AdjustmentEntry);
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Subcontractor WIP Ledger Entry", 'r')]
    local procedure ValidateSequenceNo(LedgEntryNo: Integer; xLedgEntryNo: Integer; TableNo: Integer)
    var
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
    begin
        if LedgEntryNo = xLedgEntryNo then
            exit;
        SequenceNoMgt.ValidateSeqNo(TableNo);
    end;

    local procedure InitWIPItemLedgerEntry(var SubcontractorWIPLedgerEntry: Record "Subcontractor WIP Ledger Entry"; PostingDate: Date)
    begin
        WIPLedgEntryNo := SubcontractorWIPLedgerEntry.GetNextEntryNo();

        SubcontractorWIPLedgerEntry.Init();
        SubcontractorWIPLedgerEntry."Entry No." := WIPLedgEntryNo;
        SubcontractorWIPLedgerEntry."Posting Date" := PostingDate;
    end;

    local procedure AssignFieldsFromTransferLine(var SubcontractorWIPLedgerEntry: Record "Subcontractor WIP Ledger Entry"; var TransferLine: Record "Transfer Line"; IsShipment: Boolean)
    begin
        SubcontractorWIPLedgerEntry."Item No." := TransferLine."Item No.";
        SubcontractorWIPLedgerEntry."Unit of Measure Code" := TransferLine."Unit of Measure Code";
        SubcontractorWIPLedgerEntry."Prod. Order Status" := "Production Order Status"::Released;
        SubcontractorWIPLedgerEntry."Variant Code" := TransferLine."Variant Code";
        SubcontractorWIPLedgerEntry."Prod. Order No." := TransferLine."Prod. Order No.";
        SubcontractorWIPLedgerEntry."Prod. Order Line No." := TransferLine."Prod. Order Line No.";
        SubcontractorWIPLedgerEntry."Routing No." := TransferLine."Routing No.";
        SubcontractorWIPLedgerEntry."Routing Reference No." := TransferLine."Routing Reference No.";
        SubcontractorWIPLedgerEntry."Operation No." := TransferLine."Operation No.";
        if IsShipment and not (SubcontractorWIPLedgerEntry."In Transit") then
            if TransferLine."Prev. Operation No." <> '' then
                SubcontractorWIPLedgerEntry."Operation No." := TransferLine."Prev. Operation No.";
        SubcontractorWIPLedgerEntry."Work Center No." := TransferLine."Work Center No.";
        SubcontractorWIPLedgerEntry.Description := TransferLine.Description;
        SubcontractorWIPLedgerEntry."Description 2" := TransferLine."Description 2";
    end;

    local procedure AssignSourceDocument(var SubcontractorWIPLedgerEntry: Record "Subcontractor WIP Ledger Entry"; WIPDocumentType: Enum "WIP Document Type"; DocumentNo: Code[20]; DocumentLineNo: Integer)
    begin
        SubcontractorWIPLedgerEntry."Document Type" := WIPDocumentType;
        SubcontractorWIPLedgerEntry."Document No." := DocumentNo;
        SubcontractorWIPLedgerEntry."Document Line No." := DocumentLineNo;
    end;

    local procedure InsertWIPItemLedgerEntry(var SubcontractorWIPLedgerEntry: Record "Subcontractor WIP Ledger Entry")
    var
        xWIPLedgEntryNo: Integer;
    begin
        xWIPLedgEntryNo := WIPLedgEntryNo;
        ValidateSequenceNo(WIPLedgEntryNo, xWIPLedgEntryNo, Database::"Subcontractor WIP Ledger Entry");
        if SubcontractorWIPLedgerEntry."Quantity (Base)" = 0 then
            exit;
        SubcontractorWIPLedgerEntry.Insert();
    end;

    local procedure IsUsedAsSubcontractingLocation(LocationCode: Code[10]): Boolean
    var
        Vendor: Record Vendor;
    begin
        Vendor.SetCurrentKey("Subcontr. Location Code");
        Vendor.SetRange("Subcontr. Location Code", LocationCode);
        exit(not Vendor.IsEmpty());
    end;
}