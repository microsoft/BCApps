// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Setup;
using Microsoft.Manufacturing.Document;
using Microsoft.Warehouse.Activity.History;
using Microsoft.Warehouse.Tracking;
using Microsoft.Warehouse.Worksheet;

codeunit 99000891 "Mfg. Item Tracking Mgt."
{
    var
        ItemTrackingManagement: Codeunit "Item Tracking Management";
        UOMMgt: Codeunit "Unit of Measure Management";
        ItemTrackingLines: Page "Item Tracking Lines";
        CountingRecordsMsg: Label 'Counting records...';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Management", 'OnGetItemTrackingSetupOnSetSerialNoRequired', '', false, false)]
    local procedure OnGetItemTrackingSetupOnSetSerialNoRequired(var ItemTrackingSetup: Record "Item Tracking Setup"; ItemTrackingCode: Record "Item Tracking Code"; EntryType: Enum "Item Ledger Entry Type"; Inbound: Boolean)
    begin
        case EntryType of
            EntryType::Consumption, EntryType::Output:
                if Inbound then
                    ItemTrackingSetup."Serial No. Required" := ItemTrackingCode."SN Manuf. Inbound Tracking"
                else
                    ItemTrackingSetup."Serial No. Required" := ItemTrackingCode."SN Manuf. Outbound Tracking";
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Management", 'OnGetItemTrackingSetupOnSetLotNoRequired', '', false, false)]
    local procedure OnGetItemTrackingSetupOnSetLotNoRequired(var ItemTrackingSetup: Record "Item Tracking Setup"; ItemTrackingCode: Record "Item Tracking Code"; EntryType: Enum "Item Ledger Entry Type"; Inbound: Boolean)
    begin
        case EntryType of
            EntryType::Consumption, EntryType::Output:
                if Inbound then
                    ItemTrackingSetup."Lot No. Required" := ItemTrackingCode."Lot Manuf. Inbound Tracking"
                else
                    ItemTrackingSetup."Lot No. Required" := ItemTrackingCode."Lot Manuf. Outbound Tracking";
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Management", 'OnGetItemTrackingSetupOnSetPackageNoRequired', '', false, false)]
    local procedure OnGetItemTrackingSetupOnSetPackageNoRequired(var ItemTrackingSetup: Record "Item Tracking Setup"; ItemTrackingCode: Record "Item Tracking Code"; EntryType: Enum "Item Ledger Entry Type"; Inbound: Boolean)
    begin
        case EntryType of
            EntryType::Consumption, EntryType::Output:
                if Inbound then
                    ItemTrackingSetup."Package No. Required" := ItemTrackingCode."Package Manuf. Inb. Tracking"
                else
                    ItemTrackingSetup."Package No. Required" := ItemTrackingCode."Package Manuf. Outb. Tracking";
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Management", 'OnAfterInitWhseWorksheetLine', '', false, false)]
    local procedure OnAfterInitWhseWorksheetLine(var WhseWorksheetLine: Record "Whse. Worksheet Line"; WhseDocType: Enum "Warehouse Worksheet Document Type"; SourceSubtype: Integer; SourceNo: Code[20]; SourceLineNo: Integer; SourceSublineNo: Integer)
    var
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        if WhseDocType <> Enum::"Warehouse Worksheet Document Type"::Production then
            exit;

        case WhseWorksheetLine."Source Type" of
            Database::"Prod. Order Line":
                begin
                    ProdOrderLine.SetLoadFields("Qty. Put Away (Base)");
                    ProdOrderLine.Get(SourceSubtype, SourceNo, SourceLineNo);
                    WhseWorksheetLine."Qty. Handled (Base)" := ProdOrderLine."Qty. Put Away (Base)";
                end;
            else begin
                ProdOrderComponent.SetLoadFields("Qty. Picked (Base)");
                ProdOrderComponent.Get(SourceSubtype, SourceNo, SourceLineNo, SourceSublineNo);
                WhseWorksheetLine."Qty. Handled (Base)" := ProdOrderComponent."Qty. Picked (Base)";
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Management", 'OnBeforeRetrieveItemTrackingFromReservEntry', '', false, false)]
    local procedure OnBeforeRetrieveItemTrackingFromReservEntry(ItemJnlLine: Record "Item Journal Line"; var ReservEntry: Record "Reservation Entry"; var Result: Boolean; var IsHandled: Boolean; var TempTrackingSpec: Record "Tracking Specification" temporary)
    begin
        if ItemJnlLine.Subcontracting then begin
            Result := RetrieveSubcontrItemTracking(ItemJnlLine, TempTrackingSpec);
            IsHandled := true;
        end;
    end;

    procedure RetrieveConsumpItemTracking(ItemJnlLine: Record "Item Journal Line"; var TempHandlingSpecification: Record "Tracking Specification" temporary): Boolean
    var
        ReservEntry: Record "Reservation Entry";
    begin
        ItemJnlLine.TestField("Order Type", ItemJnlLine."Order Type"::Production);
        ReservEntry.SetSourceFilter(
          Database::"Prod. Order Component", 3, ItemJnlLine."Order No.", ItemJnlLine."Prod. Order Comp. Line No.", true);
        ReservEntry.SetSourceFilter('', ItemJnlLine."Order Line No.");
        ReservEntry.SetFilter("Qty. to Handle (Base)", '<>0');
        ReservEntry.SetTrackingFilterFromItemJnlLine(ItemJnlLine);
        OnRetrieveConsumpItemTrackingOnAfterSetFilters(ReservEntry, ItemJnlLine);
#if not CLEAN26
        ItemTrackingManagement.RunOnRetrieveConsumpItemTrackingOnAfterSetFilters(ReservEntry, ItemJnlLine);
#endif

        // Sum up in a temporary table per component line:
        exit(ItemTrackingManagement.SumUpItemTracking(ReservEntry, TempHandlingSpecification, true, true));
    end;

    local procedure RetrieveSubcontrItemTracking(ItemJnlLine: Record "Item Journal Line"; var TempHandlingSpecification: Record "Tracking Specification" temporary) Result: Boolean
    var
        ReservEntry: Record "Reservation Entry";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        IsLastOperation: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRetrieveSubcontrItemTracking(ItemJnlLine, TempHandlingSpecification, Result, IsHandled);
#if not CLEAN26
        ItemTrackingManagement.RunOnBeforeRetrieveSubcontrItemTracking(ItemJnlLine, TempHandlingSpecification, Result, IsHandled);
#endif
        if IsHandled then
            exit(Result);

        if not ItemJnlLine.Subcontracting then
            exit(false);

        if ItemJnlLine."Operation No." = '' then
            exit(false);

        ItemJnlLine.TestField("Routing No.");
        ItemJnlLine.TestField("Order Type", ItemJnlLine."Order Type"::Production);
        if not ProdOrderRoutingLine.Get(
             ProdOrderRoutingLine.Status::Released, ItemJnlLine."Order No.",
             ItemJnlLine."Routing Reference No.", ItemJnlLine."Routing No.", ItemJnlLine."Operation No.")
        then
            exit(false);

        IsLastOperation := ProdOrderRoutingLine."Next Operation No." = '';
        OnRetrieveSubcontrItemTrackingOnBeforeCheckLastOperation(ProdOrderRoutingLine, IsLastOperation);
#if not CLEAN26
        ItemTrackingManagement.RunOnRetrieveSubcontrItemTrackingOnBeforeCheckLastOperation(ProdOrderRoutingLine, IsLastOperation);
#endif
        if not IsLastOperation then
            exit(false);

        ReservEntry.SetSourceFilter(Database::"Prod. Order Line", 3, ItemJnlLine."Order No.", 0, true);
        ReservEntry.SetSourceFilter('', ItemJnlLine."Order Line No.");
        ReservEntry.SetFilter("Qty. to Handle (Base)", '<>0');
        if ItemTrackingManagement.SumUpItemTracking(ReservEntry, TempHandlingSpecification, false, true) then begin
            ReservEntry.SetRange("Reservation Status", ReservEntry."Reservation Status"::Prospect);
            if not ReservEntry.IsEmpty() then
                ReservEntry.DeleteAll();
            OnRetrieveSubcontrItemTrackingOnAfterDeleteReservEntries(TempHandlingSpecification, ReservEntry);
#if not CLEAN26
            ItemTrackingManagement.RunOnRetrieveSubcontrItemTrackingOnAfterDeleteReservEntries(TempHandlingSpecification, ReservEntry);
#endif
            exit(true);
        end;
        exit(false);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Management", 'OnInitTrackingSpecificationByDocumentType', '', false, false)]
    local procedure OnInitTrackingSpecificationByDocumentType(var WhseWorksheetLine: Record "Whse. Worksheet Line"; SourceType: Integer)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        case WhseWorksheetLine."Whse. Document Type" of
            "Warehouse Worksheet Document Type"::Production:
                if SourceType = Database::"Prod. Order Line" then begin
                    ProdOrderLine.SetLoadFields(Status, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.");
                    ProdOrderLine.SetFilter(Status, '%1|%2', ProdOrderLine.Status::Released, ProdOrderLine.Status::Finished);
                    ProdOrderLine.SetRange("Prod. Order No.", WhseWorksheetLine."Source No.");
                    ProdOrderLine.SetRange("Line No.", WhseWorksheetLine."Source Line No.");
                    if ProdOrderLine.FindFirst() then
                        InsertWhseItemTrkgLinesForProdOrderLine(ProdOrderLine, SourceType);
                end;
        end;
    end;

    local procedure InsertWhseItemTrkgLinesForProdOrderLine(ProdOrderLine: Record "Prod. Order Line"; SourceType: Integer)
    var
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        EntryNo: Integer;
        QtyHandledBase: Decimal;
        RemQtyHandledBase: Decimal;
    begin
        EntryNo := WhseItemTrackingLine.GetLastEntryNo() + 1;
        QtyHandledBase := 0;

        ItemLedgerEntry.SetSourceFilterForProdOutputPutAway(ProdOrderLine);
        if ItemLedgerEntry.FindSet() then begin
            WhseItemTrackingLine.SetSourceFilter(SourceType, ProdOrderLine.Status.AsInteger(), ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.", false);
            WhseItemTrackingLine.DeleteAll();
            WhseItemTrackingLine.Init();
            WhseItemTrackingLine.SetTrackingKey();
            repeat
                WhseItemTrackingLine.SetTrackingFilterFromItemLedgerEntry(ItemLedgerEntry);
                if not WhseItemTrackingLine.HasSameTrackingWithItemLedgerEntry(ItemLedgerEntry) then
                    RemQtyHandledBase := RegisteredPutAwayQtyBase(ProdOrderLine, ItemLedgerEntry)
                else
                    RemQtyHandledBase -= QtyHandledBase;
                QtyHandledBase := RemQtyHandledBase;
                if QtyHandledBase > ItemLedgerEntry.Quantity then
                    QtyHandledBase := ItemLedgerEntry.Quantity;

                if not WhseItemTrackingLine.FindFirst() then begin
                    WhseItemTrackingLine.Init();
                    WhseItemTrackingLine."Entry No." := EntryNo;
                    EntryNo := EntryNo + 1;

                    WhseItemTrackingLine."Item No." := ItemLedgerEntry."Item No.";
                    WhseItemTrackingLine."Location Code" := ItemLedgerEntry."Location Code";
                    WhseItemTrackingLine.Description := ItemLedgerEntry.Description;
                    WhseItemTrackingLine.SetSource(
                      Database::"Prod. Order Line", ProdOrderLine.Status.AsInteger(), ItemLedgerEntry."Order No.",
                      ItemLedgerEntry."Order Line No.", '', ItemLedgerEntry."Order Line No.");
                    WhseItemTrackingLine.CopyTrackingFromItemLedgEntry(ItemLedgerEntry);
                    WhseItemTrackingLine."Warranty Date" := ItemLedgerEntry."Warranty Date";
                    WhseItemTrackingLine."Expiration Date" := ItemLedgerEntry."Expiration Date";
                    WhseItemTrackingLine."Qty. per Unit of Measure" := ItemLedgerEntry."Qty. per Unit of Measure";
                    WhseItemTrackingLine."Quantity Handled (Base)" := QtyHandledBase;
                    WhseItemTrackingLine."Qty. Registered (Base)" := QtyHandledBase;
                    WhseItemTrackingLine.Validate("Quantity (Base)", ItemLedgerEntry.Quantity);
                    WhseItemTrackingLine.Insert();
                end else begin
                    WhseItemTrackingLine."Quantity Handled (Base)" += QtyHandledBase;
                    WhseItemTrackingLine."Qty. Registered (Base)" += QtyHandledBase;
                    WhseItemTrackingLine.Validate("Quantity (Base)", WhseItemTrackingLine."Quantity (Base)" + ItemLedgerEntry.Quantity);
                    WhseItemTrackingLine.Modify();
                end;
            until ItemLedgerEntry.Next() = 0;
        end;
    end;

    local procedure RegisteredPutAwayQtyBase(ProdOrderLine: Record "Prod. Order Line"; ItemLedgerEntry: Record "Item Ledger Entry"): Decimal
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
    begin
        RegisteredWhseActivityLine.SetSourceFilter(Database::"Prod. Order Line", ProdOrderLine.Status.AsInteger(), ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.", -1, true);
        RegisteredWhseActivityLine.SetTrackingFilterFromItemLedgerEntry(ItemLedgerEntry);
        RegisteredWhseActivityLine.SetRange("Whse. Document No.", ProdOrderLine."Prod. Order No.");
        RegisteredWhseActivityLine.SetRange("Action Type", RegisteredWhseActivityLine."Action Type"::Take);
        RegisteredWhseActivityLine.CalcSums("Qty. (Base)");

        exit(RegisteredWhseActivityLine."Qty. (Base)");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Management", 'OnInitTrackingSpecificationOnCreateNew', '', false, false)]
    local procedure OnInitTrackingSpecificationOnCreateNew(var WhseWorksheetLine: Record "Whse. Worksheet Line"; SourceType: Integer)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        case SourceType of
            Database::"Prod. Order Line":
                begin
                    ProdOrderLine.SetLoadFields(Status, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.");
                    ProdOrderLine.SetFilter(Status, '%1|%2', ProdOrderLine.Status::Released, ProdOrderLine.Status::Finished);
                    ProdOrderLine.SetRange("Prod. Order No.", WhseWorksheetLine."Source No.");
                    ProdOrderLine.SetRange("Line No.", WhseWorksheetLine."Source Line No.");
                    if ProdOrderLine.FindFirst() then
                        CreateWhseItemTrackingForProdOrderLine(WhseWorksheetLine, ProdOrderLine);
                end;
        end;
    end;

    local procedure CreateWhseItemTrackingForProdOrderLine(WhseWkshLine: Record "Whse. Worksheet Line"; ProdOrderLine: Record "Prod. Order Line")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
        EntryNo: Integer;
        QtyToApply: Decimal;
    begin
        WhseItemTrackingLine.Reset();
        EntryNo := WhseItemTrackingLine.GetLastEntryNo();

        ItemLedgerEntry.SetSourceFilterForProdOutputPutAway(WhseWkshLine);
        if ItemLedgerEntry.FindSet() then
            repeat
                WhseItemTrackingLine.Init();
                EntryNo += 1;
                WhseItemTrackingLine."Entry No." := EntryNo;
                WhseItemTrackingLine."Item No." := WhseWkshLine."Item No.";
                WhseItemTrackingLine."Variant Code" := WhseWkshLine."Variant Code";
                WhseItemTrackingLine."Location Code" := WhseWkshLine."Location Code";
                WhseItemTrackingLine.Description := WhseWkshLine.Description;
                WhseItemTrackingLine."Qty. per Unit of Measure" := WhseWkshLine."Qty. per From Unit of Measure";
                WhseItemTrackingLine.SetSource(
                  Database::"Prod. Order Line", ProdOrderLine.Status.AsInteger(), WhseWkshLine."Whse. Document No.", WhseWkshLine."Whse. Document Line No.", '', 0);
                WhseItemTrackingLine.CopyTrackingFromItemLedgEntry(ItemLedgerEntry);
                QtyToApply := ItemLedgerEntry.Quantity - ProdOrderLine.GetUsedPutAwayQtyPerItemTracking(ItemLedgerEntry."Lot No.", ItemLedgerEntry."Serial No.", ItemLedgerEntry."Package No.");
                if QtyToApply <> 0 then begin
                    WhseItemTrackingLine."Quantity (Base)" := ItemLedgerEntry.Quantity - ProdOrderLine.GetUsedPutAwayQtyPerItemTracking(ItemLedgerEntry."Lot No.", ItemLedgerEntry."Serial No.", ItemLedgerEntry."Package No.");
                    if WhseWkshLine."Qty. (Base)" = WhseWkshLine."Qty. to Handle (Base)" then
                        WhseItemTrackingLine."Qty. to Handle (Base)" := WhseItemTrackingLine."Quantity (Base)";
                    WhseItemTrackingLine."Qty. to Handle" :=
                      Round(
                        WhseItemTrackingLine."Qty. to Handle (Base)" / WhseItemTrackingLine."Qty. per Unit of Measure",
                        UOMMgt.QtyRndPrecision());
                    WhseItemTrackingLine.Insert();
                end;
            until ItemLedgerEntry.Next() = 0;
    end;

    internal procedure SplitProdOrderLineForOutputPutAway(ProdOrderLine: Record "Prod. Order Line"; var TempProdOrdLineTrackingBuff: Record "Prod. Ord. Line Tracking Buff." temporary; SplitUpToQtyBase: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemTrackingSetup: Record "Item Tracking Setup";
        BufferEntryNo: Integer;
        RemainingHandledQtyBase: Decimal;
        QtyBaseAvailableToPutAway: Decimal;
        ExitLoop: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSplitProdOrderLineForOutputPutAway(ProdOrderLine, TempProdOrdLineTrackingBuff, SplitUpToQtyBase, IsHandled);
        if IsHandled then
            exit;

        TempProdOrdLineTrackingBuff.Reset();
        TempProdOrdLineTrackingBuff.DeleteAll();
        RemainingHandledQtyBase := SplitUpToQtyBase;

        if not ItemTrackingManagement.GetWhseItemTrkgSetup(ProdOrderLine."Item No.", ItemTrackingSetup) then begin
            CopyProdOrderLineFieldsToTempProdOrdLineTrackingBuff(ProdOrderLine, TempProdOrdLineTrackingBuff);
            TempProdOrdLineTrackingBuff."Buffer Entry No." := 1;
            TempProdOrdLineTrackingBuff.Insert();
            exit;
        end;

        ItemLedgerEntry.SetLoadFields("Order Type", "Order No.", "Order No.", "Serial No.", "Lot No.", "Package No.", "Warranty Date", "Expiration Date", Quantity);
        ItemLedgerEntry.SetSourceFilterForProdOutputPutAway(ProdOrderLine);
        if ItemLedgerEntry.FindSet() then
            repeat
                TempProdOrdLineTrackingBuff.SetTrackingFilterFromItemLedgerEntry(ItemLedgerEntry);
                TempProdOrdLineTrackingBuff.SetRange("Warranty Date", ItemLedgerEntry."Warranty Date");
                TempProdOrdLineTrackingBuff.SetRange("Expiration Date", ItemLedgerEntry."Expiration Date");
                if TempProdOrdLineTrackingBuff.FindFirst() then begin
                    UpdateQtySplitForPutAwayOnProdOrdLineTrackingBuffer(TempProdOrdLineTrackingBuff, ProdOrderLine, ItemLedgerEntry, QtyBaseAvailableToPutAway, RemainingHandledQtyBase);
                    if QtyBaseAvailableToPutAway > 0 then
                        TempProdOrdLineTrackingBuff.Modify();
                end else begin
                    BufferEntryNo += 1;
                    TempProdOrdLineTrackingBuff.Reset();
                    CopyProdOrderLineFieldsToTempProdOrdLineTrackingBuff(ProdOrderLine, TempProdOrdLineTrackingBuff);
                    TempProdOrdLineTrackingBuff."Buffer Entry No." := BufferEntryNo;
                    TempProdOrdLineTrackingBuff.CopyTrackingFromItemLedgerEntry(ItemLedgerEntry);
                    TempProdOrdLineTrackingBuff."Warranty Date" := ItemLedgerEntry."Warranty Date";
                    TempProdOrdLineTrackingBuff."Expiration Date" := ItemLedgerEntry."Expiration Date";
                    TempProdOrdLineTrackingBuff."Qty. split for Put Away (Base)" := 0;

                    UpdateQtySplitForPutAwayOnProdOrdLineTrackingBuffer(TempProdOrdLineTrackingBuff, ProdOrderLine, ItemLedgerEntry, QtyBaseAvailableToPutAway, RemainingHandledQtyBase);
                    if QtyBaseAvailableToPutAway > 0 then
                        TempProdOrdLineTrackingBuff.Insert();
                end;

                if SplitUpToQtyBase <> 0 then
                    ExitLoop := RemainingHandledQtyBase = 0;
            until (ItemLedgerEntry.Next() = 0) or ExitLoop
        else begin
            CopyProdOrderLineFieldsToTempProdOrdLineTrackingBuff(ProdOrderLine, TempProdOrdLineTrackingBuff);
            TempProdOrdLineTrackingBuff."Buffer Entry No." := 1;
            TempProdOrdLineTrackingBuff.Insert();
        end;
    end;

    local procedure CopyProdOrderLineFieldsToTempProdOrdLineTrackingBuff(ProdOrderLine: Record "Prod. Order Line"; var TempProdOrdLineTrackingBuff: Record "Prod. Ord. Line Tracking Buff.")
    begin
        Clear(TempProdOrdLineTrackingBuff);
        TempProdOrdLineTrackingBuff."Prod. Order Status" := ProdOrderLine."Status";
        TempProdOrdLineTrackingBuff."Prod. Order No." := ProdOrderLine."Prod. Order No.";
        TempProdOrdLineTrackingBuff."Prod. Order Line No." := ProdOrderLine."Line No.";
        TempProdOrdLineTrackingBuff."Item No." := ProdOrderLine."Item No.";
        TempProdOrdLineTrackingBuff."Variant Code" := ProdOrderLine."Variant Code";
        TempProdOrdLineTrackingBuff."Qty. Rounding Precision" := ProdOrderLine."Qty. Rounding Precision";
        TempProdOrdLineTrackingBuff."Qty. Rounding Precision (Base)" := ProdOrderLine."Qty. Rounding Precision (Base)";
        TempProdOrdLineTrackingBuff."Unit of Measure Code" := ProdOrderLine."Unit of Measure Code";
        TempProdOrdLineTrackingBuff."Qty. per Unit of Measure" := ProdOrderLine."Qty. per Unit of Measure";
        TempProdOrdLineTrackingBuff."Qty. split for Put Away (Base)" := ProdOrderLine."Finished Qty. (Base)";
        TempProdOrdLineTrackingBuff."Qty. split for Put Away" :=
          Round(
            TempProdOrdLineTrackingBuff."Qty. split for Put Away (Base)" / TempProdOrdLineTrackingBuff."Qty. per Unit of Measure",
            UOMMgt.QtyRndPrecision());

        OnAfterCopyProdOrderLineFieldsToTempProdOrdLineTrackingBuff(ProdOrderLine, TempProdOrdLineTrackingBuff);
    end;

    local procedure UpdateQtySplitForPutAwayOnProdOrdLineTrackingBuffer(var TempProdOrdLineTrackingBuff: Record "Prod. Ord. Line Tracking Buff." temporary; ProdOrderLine: Record "Prod. Order Line"; ItemLedgerEntry: Record "Item Ledger Entry"; var QtyBaseAvailableToPutAway: Decimal; var RemainingHandledQtyBase: Decimal)
    begin
        QtyBaseAvailableToPutAway := ItemLedgerEntry.Quantity - ProdOrderLine.GetUsedPutAwayQtyPerItemTracking(ItemLedgerEntry."Lot No.", ItemLedgerEntry."Serial No.", ItemLedgerEntry."Package No.");
        if QtyBaseAvailableToPutAway < 0 then
            exit;

        TempProdOrdLineTrackingBuff."Qty. split for Put Away (Base)" += CalcQtyBaseToPutAway(RemainingHandledQtyBase, QtyBaseAvailableToPutAway);
        TempProdOrdLineTrackingBuff."Qty. split for Put Away" :=
          Round(
            TempProdOrdLineTrackingBuff."Qty. split for Put Away (Base)" / TempProdOrdLineTrackingBuff."Qty. per Unit of Measure",
            UOMMgt.QtyRndPrecision());
    end;

    local procedure CalcQtyBaseToPutAway(var RemainingHandledQtyBase: Decimal; QtyBaseAvailableToPutAway: Decimal) Qty: Decimal
    begin
        if RemainingHandledQtyBase >= QtyBaseAvailableToPutAway then begin
            RemainingHandledQtyBase := RemainingHandledQtyBase - QtyBaseAvailableToPutAway;
            Qty := QtyBaseAvailableToPutAway;
        end else begin
            if RemainingHandledQtyBase <> 0 then
                Qty := RemainingHandledQtyBase
            else
                Qty := QtyBaseAvailableToPutAway;
            RemainingHandledQtyBase := 0;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Management", 'OnCalcWhseItemTrkgLineOnSetSourceTypeFilter', '', false, false)]
    local procedure OnCalcWhseItemTrkgLineOnSetSourceTypeFilter(var WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
        case WhseItemTrackingLine."Source Type" of
            Database::"Prod. Order Line",
            Database::"Prod. Order Component":
                WhseItemTrackingLine."Source Type Filter" := WhseItemTrackingLine."Source Type Filter"::Production;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRetrieveConsumpItemTrackingOnAfterSetFilters(var ReservationEntry: Record "Reservation Entry"; ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRetrieveSubcontrItemTracking(ItemJnlLine: Record "Item Journal Line"; var TempHandlingSpecification: Record "Tracking Specification" temporary; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRetrieveSubcontrItemTrackingOnBeforeCheckLastOperation(ProdOrderRoutingLine: Record Microsoft.Manufacturing.Document."Prod. Order Routing Line"; var IsLastOperation: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRetrieveSubcontrItemTrackingOnAfterDeleteReservEntries(var TempHandlingSpecification: Record "Tracking Specification" temporary; var ReservationEntry: Record "Reservation Entry")
    begin
    end;

    // Item Tracking Code

    [EventSubscriber(ObjectType::Table, Database::"Item Tracking Code", 'OnValidateSNSpecificTrackingOnAfterSet', '', false, false)]
    local procedure OnValidateSNSpecificTrackingOnAfterSet(var ItemTrackingCode: Record "Item Tracking Code")
    begin
        ItemTrackingCode."SN Manuf. Inbound Tracking" := true;
        ItemTrackingCode."SN Manuf. Outbound Tracking" := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Tracking Code", 'OnValidateLotSpecificTrackingOnAfterSet', '', false, false)]
    local procedure OnValidateLotSpecificTrackingOnAfterSet(var ItemTrackingCode: Record "Item Tracking Code")
    begin
        ItemTrackingCode."Lot Manuf. Inbound Tracking" := true;
        ItemTrackingCode."Lot Manuf. Outbound Tracking" := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Tracking Code", 'OnValidatePackageSpecificTrackingOnAfterSet', '', false, false)]
    local procedure OnValidatePackageSpecificTrackingOnAfterSet(var ItemTrackingCode: Record "Item Tracking Code")
    begin
        ItemTrackingCode."Package Manuf. Inb. Tracking" := true;
        ItemTrackingCode."Package Manuf. Outb. Tracking" := true;
    end;

    // Report Carry Out Reservation
    [EventSubscriber(ObjectType::Report, Report::"Carry Out Reservation", 'OnCarryOutReservationOtherDemandType', '', false, false)]
    local procedure OnCarryOutReservationOtherDemandType(var ReservationWkshLine: Record "Reservation Wksh. Line"; DemandType: Enum "Reservation Demand Type")
    begin
        case DemandType of
            DemandType::"Production Components":
                ReservationWkshLine.SetRange("Source Type", Database::"Prod. Order Component");
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Action Message Entry", 'OnAfterSumUp', '', false, false)]
    local procedure OnAfterSumUp(var ActionMessageEntry: Record "Action Message Entry"; var ComponentBinding: Boolean; var FirstDate: Date; var FirstTime: Time)
    var
        ReservEntry: Record "Reservation Entry";
        ReservEntry2: Record "Reservation Entry";
        ProdOrderComp: Record "Prod. Order Component";
    begin
        ComponentBinding := false;
        if ActionMessageEntry."Source Type" = Database::"Prod. Order Line" then begin
            FirstDate := DMY2Date(31, 12, 9999);
            ActionMessageEntry.FilterToReservEntry(ReservEntry);
            ReservEntry.SetRange(Binding, ReservEntry.Binding::"Order-to-Order");
            if ReservEntry.FindSet() then
                repeat
                    if ReservEntry2.Get(ReservEntry."Entry No.", false) then
                        if (ReservEntry2."Source Type" = Database::"Prod. Order Component") and
                           (ReservEntry2."Source Subtype" = ReservEntry."Source Subtype") and
                           (ReservEntry2."Source ID" = ReservEntry."Source ID")
                        then
                            if ProdOrderComp.Get(
                                 ReservEntry2."Source Subtype", ReservEntry2."Source ID",
                                 ReservEntry2."Source Prod. Order Line", ReservEntry2."Source Ref. No.")
                            then begin
                                ComponentBinding := true;
                                if ProdOrderComp."Due Date" < FirstDate then begin
                                    FirstDate := ProdOrderComp."Due Date";
                                    FirstTime := ProdOrderComp."Due Time";
                                end;
                            end;
                until ReservEntry.Next() = 0;
        end;
    end;

    // Codeunit "Item Tracing Mgt."

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracing Mgt.", 'OnInsertRecordOnBeforeSetDescription', '', false, false)]
    local procedure OnInsertRecordOnBeforeSetDescription(var TempTrackEntry: Record "Item Tracing Buffer"; var RecRef: RecordRef; var Description2: Text[100])
    var
        ProductionOrder: Record "Production Order";
    begin
        if RecRef.Get(TempTrackEntry."Record Identifier") then
            case RecRef.Number of
                Database::"Production Order":
                    begin
                        RecRef.SetTable(ProductionOrder);
                        Description2 :=
                            StrSubstNo('%1 %2 %3 %4', ProductionOrder.Status, RecRef.Caption, TempTrackEntry."Entry Type", TempTrackEntry."Document No.");
                    end;
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracing Mgt.", 'OnAfterSetRecordID', '', false, false)]
    local procedure OnAfterSetRecordID(var TrackingEntry: Record "Item Tracing Buffer"; RecRef: RecordRef)
    var
        ProductionOrder: Record "Production Order";
    begin
        case TrackingEntry."Entry Type" of
            TrackingEntry."Entry Type"::Consumption,
            TrackingEntry."Entry Type"::Output:
                begin
                    ProductionOrder.SetFilter(Status, '>=%1', ProductionOrder.Status::Released);
                    ProductionOrder.SetRange("No.", TrackingEntry."Document No.");
                    if ProductionOrder.FindFirst() then begin
                        RecRef.GetTable(ProductionOrder);
                        TrackingEntry."Record Identifier" := RecRef.RecordId;
                    end;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracing Mgt.", 'OnShowDocument', '', false, false)]
    local procedure OnShowDocument(RecRef: RecordRef; RecID: RecordId)
    var
        ProductionOrder: Record "Production Order";
    begin
        case RecID.TableNo of
            Database::"Production Order":
                begin
                    RecRef.SetTable(ProductionOrder);
                    if ProductionOrder.Status = ProductionOrder.Status::Released then
                        PAGE.RunModal(PAGE::"Released Production Order", ProductionOrder)
                    else
                        if ProductionOrder.Status = ProductionOrder.Status::Finished then
                            PAGE.RunModal(PAGE::"Finished Production Order", ProductionOrder);
                end;
        end;
    end;

    // Codeunit Reservation Engine Mgt.

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Engine Mgt.", 'OnModifyActionMessageDatingOnGetDampenerPeriod', '', false, false)]
    local procedure OnModifyActionMessageDatingOnGetDampenerPeriod(ReservEntry: Record "Reservation Entry"; var DampenerPeriod: Dateformula)
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        if (Format(InventorySetup."Default Dampener Period") = '') or
           ((ReservEntry.Binding = ReservEntry.Binding::"Order-to-Order") and
            (ReservEntry."Reservation Status" = ReservEntry."Reservation Status"::Reservation))
        then
            Evaluate(InventorySetup."Default Dampener Period", '<0D>');
        DampenerPeriod := InventorySetup."Default Dampener Period";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Engine Mgt.", 'OnAfterShouldModifyActionMessageDating', '', false, false)]
    local procedure OnAfterShouldModifyActionMessageDating(ReservationEntry: Record "Reservation Entry"; var Result: Boolean)
    begin
        Result := Result or (ReservationEntry."Source Type" = Database::"Prod. Order Line");
    end;

    // Page Item Tracking Lines

    [EventSubscriber(ObjectType::Page, Page::"Item Tracking Lines", 'OnSetSourceSpecOnCollectTrackingData', '', false, false)]
    local procedure OnSetSourceSpecOnCollectTrackingData(var TrackingSpecification: Record "Tracking Specification"; var TempTrackingSpecification: Record "Tracking Specification" temporary; ExcludePostedEntries: Boolean; CurrentSignFactor: Integer; var SourceQuantity: Decimal)
    begin
        if TrackingSpecification."Source Type" = Database::"Prod. Order Line" then
            if TrackingSpecification."Source Subtype" = 3 then
                CollectPostedOutputEntries(TrackingSpecification, TempTrackingSpecification, SourceQuantity);
    end;

    local procedure CollectPostedOutputEntries(TrackingSpecification: Record "Tracking Specification"; var TempTrackingSpecification: Record "Tracking Specification" temporary; var SourceQuantity: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // Used for collecting information about posted prod. order output from the created Item Ledger Entries.
        if TrackingSpecification."Source Type" <> Database::"Prod. Order Line" then
            exit;

        ItemLedgerEntry.SetCurrentKey("Order Type", "Order No.", "Order Line No.", "Entry Type");
        ItemLedgerEntry.SetRange("Order Type", ItemLedgerEntry."Order Type"::Production);
        ItemLedgerEntry.SetRange("Order No.", TrackingSpecification."Source ID");
        ItemLedgerEntry.SetRange("Order Line No.", TrackingSpecification."Source Prod. Order Line");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);

        if ItemLedgerEntry.Find('-') then begin
            repeat
                TempTrackingSpecification := TrackingSpecification;
                TempTrackingSpecification."Entry No." := ItemLedgerEntry."Entry No.";
                TempTrackingSpecification."Item No." := ItemLedgerEntry."Item No.";
                TempTrackingSpecification.CopyTrackingFromItemLedgEntry(ItemLedgerEntry);
                TempTrackingSpecification."Quantity (Base)" := ItemLedgerEntry.Quantity;
                TempTrackingSpecification."Quantity Handled (Base)" := ItemLedgerEntry.Quantity;
                TempTrackingSpecification."Quantity Invoiced (Base)" := ItemLedgerEntry.Quantity;
                TempTrackingSpecification."Qty. per Unit of Measure" := ItemLedgerEntry."Qty. per Unit of Measure";
                TempTrackingSpecification.InitQtyToShip();
                ItemTrackingLines.RunOnBeforeCollectTempTrackingSpecificationInsert(TempTrackingSpecification, ItemLedgerEntry, TrackingSpecification);
                TempTrackingSpecification.Insert();
            until ItemLedgerEntry.Next() = 0;

            ItemLedgerEntry.CalcSums(Quantity);
            if ItemLedgerEntry.Quantity > SourceQuantity then
                SourceQuantity := ItemLedgerEntry.Quantity;
        end;

        OnAfterCollectPostedOutputEntries(ItemLedgerEntry, TempTrackingSpecification);
#if not CLEAN26
        ItemTrackingLines.RunOnAfterCollectPostedOutputEntries(ItemLedgerEntry, TempTrackingSpecification);
#endif
    end;

    [EventSubscriber(ObjectType::Page, Page::"Item Tracking Lines", 'OnCheckItemTrackingLineIsBoundForBarcodeScanning', '', false, false)]
    local procedure OnCheckItemTrackingLineIsBoundForBarcodeScanning(var TrackingSpecification: Record "Tracking Specification"; var Result: Boolean; IsHandled: Boolean)
    begin
        if TrackingSpecification."Source Type" = Database::"Prod. Order Line" then begin
            Result := not (TrackingSpecification."Qty. to Handle (Base)" < 0);
            IsHandled := true;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCollectPostedOutputEntries(ItemLedgerEntry: Record "Item Ledger Entry"; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    procedure ShowItemTrackingForProdOrderComp(Type: Integer; ID: Code[20]; ProdOrderLine: Integer; RefNo: Integer): Boolean
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        Window: Dialog;
    begin
        Window.Open(CountingRecordsMsg);
        ItemLedgEntry.SetCurrentKey("Order Type", "Order No.", "Order Line No.",
          "Entry Type", "Prod. Order Comp. Line No.");
        ItemLedgEntry.SetRange("Order Type", ItemLedgEntry."Order Type"::Production);
        ItemLedgEntry.SetRange("Order No.", ID);
        ItemLedgEntry.SetRange("Order Line No.", ProdOrderLine);
        case Type of
            Database::"Prod. Order Line":
                begin
                    ItemLedgEntry.SetRange("Entry Type", ItemLedgEntry."Entry Type"::Output);
                    ItemLedgEntry.SetRange("Prod. Order Comp. Line No.", 0);
                end;
            Database::"Prod. Order Component":
                begin
                    ItemLedgEntry.SetRange("Entry Type", ItemLedgEntry."Entry Type"::Consumption);
                    ItemLedgEntry.SetRange("Prod. Order Comp. Line No.", RefNo);
                end;
            else
                exit(false);
        end;
        if ItemLedgEntry.FindSet() then
            repeat
                if ItemLedgEntry.TrackingExists() then begin
                    TempItemLedgEntry := ItemLedgEntry;
                    TempItemLedgEntry.Insert();
                end
            until ItemLedgEntry.Next() = 0;
        Window.Close();
        if TempItemLedgEntry.IsEmpty() then
            exit(false);

        PAGE.RunModal(PAGE::"Posted Item Tracking Lines", TempItemLedgEntry);
        exit(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Doc. Management", 'OnAfterTableSignFactor', '', false, false)]
    local procedure OnAfterTableSignFactor(TableNo: Integer; var Sign: Integer);
    begin
        if TableNo = Database::"Prod. Order Component" then
            Sign := -1;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Profile Offsetting", OnCheckIsSNSpecificTracking, '', false, false)]
    local procedure OnCheckIsSNSpecificTracking(ItemTrackingCode: Record "Item Tracking Code"; var SNSepecificTracking: Boolean)
    begin
        if SNSepecificTracking then
            exit;

        SNSepecificTracking := ItemTrackingCode."SN Manuf. Inbound Tracking" or ItemTrackingCode."SN Manuf. Outbound Tracking";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Profile Offsetting", OnCheckIsLotSpecificTracking, '', false, false)]
    local procedure OnCheckIsLotSpecificTracking(ItemTrackingCode: Record "Item Tracking Code"; var LotSepecificTracking: Boolean)
    begin
        if LotSepecificTracking then
            exit;

        LotSepecificTracking := ItemTrackingCode."Lot Manuf. Inbound Tracking" or ItemTrackingCode."Lot Manuf. Outbound Tracking";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Management", OnRegisterNewItemTrackingLinesOnBeforeCannotMatchItemTrackingError, '', false, false)]
    local procedure OnRegisterNewItemTrackingLinesOnBeforeCannotMatchItemTrackingError(var TempTrackingSpecification: Record "Tracking Specification" temporary; var QtyToHandleToNewRegister: Decimal; var QtyToHandleInItemTracking: Decimal; var QtyToHandleOnSourceDocLine: Decimal; var IsHandled: Boolean; var AllowWhseOverpick: Boolean)
    var
        Item: Record Item;
    begin
        if (TempTrackingSpecification."Source Type" <> Database::"Prod. Order Component") or (TempTrackingSpecification."Source Subtype" <> TempTrackingSpecification."Source Subtype"::"3") then
            exit;

        Item.SetLoadFields("Allow Whse. Overpick");
        Item.Get(TempTrackingSpecification."Item No.");
        AllowWhseOverpick := Item."Allow Whse. Overpick";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Data Collection", OnFindRelatedParentTrkgSpecOnSetSourceFilters, '', false, false)]
    local procedure OnFindRelatedParentTrkgSpecOnSetSourceFilters(ItemJnlLine: Record "Item Journal Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
        case ItemJnlLine."Entry Type" of
            ItemJnlLine."Entry Type"::Consumption:
                begin
                    if ItemJnlLine."Prod. Order Comp. Line No." = 0 then
                        exit;
                    TempTrackingSpecification.SetSourceFilter(Database::"Prod. Order Component", 3, ItemJnlLine."Order No.", ItemJnlLine."Prod. Order Comp. Line No.", false);
                    TempTrackingSpecification.SetSourceFilter('', ItemJnlLine."Order Line No.");
                end;
            ItemJnlLine."Entry Type"::Output:
                begin
                    TempTrackingSpecification.SetSourceFilter(Database::"Prod. Order Line", 3, ItemJnlLine."Order No.", -1, false);
                    TempTrackingSpecification.SetSourceFilter('', ItemJnlLine."Order Line No.");
                end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSplitProdOrderLineForOutputPutAway(ProdOrderLine: Record "Prod. Order Line"; var TempProdOrdLineTrackingBuff: Record "Prod. Ord. Line Tracking Buff." temporary; SplitUpToQtyBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyProdOrderLineFieldsToTempProdOrdLineTrackingBuff(ProdOrderLine: Record "Prod. Order Line"; var TempProdOrdLineTrackingBuff: Record "Prod. Ord. Line Tracking Buff.")
    begin
    end;
}
