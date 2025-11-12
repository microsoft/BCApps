// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Inventory.Location;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Transfer;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Availability;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Tracking;

codeunit 300 "Reservation Worksheet Mgt."
{
    trigger OnRun()
    begin

    end;

    var
        DefaultNameTok: Label 'DEFAULT';
        DefaultDescriptionTok: Label 'Default Worksheet';
        LineIsOutdatedErr: Label 'The Reservation Worksheet Line is outdated. Please recalculate the demand.';

    procedure LookupName(var CurrentJnlBatchName: Code[10]; var ReservationWkshLine: Record "Reservation Wksh. Line")
    var
        ReservationWkshBatch: Record "Reservation Wksh. Batch";
    begin
        Commit();
        ReservationWkshBatch.Name := ReservationWkshLine.GetRangeMax("Journal Batch Name");
        if PAGE.RunModal(0, ReservationWkshBatch) = ACTION::LookupOK then begin
            CurrentJnlBatchName := ReservationWkshBatch.Name;
            SetName(CurrentJnlBatchName, ReservationWkshLine);
        end;
    end;

    procedure SetName(CurrentJnlBatchName: Code[10]; var ReservationWkshLine: Record "Reservation Wksh. Line")
    begin
        ReservationWkshLine.FilterGroup(2);
        ReservationWkshLine.SetRange("Journal Batch Name", CurrentJnlBatchName);
        ReservationWkshLine.FilterGroup(0);
        if ReservationWkshLine.FindFirst() then;
    end;

    procedure CheckName(CurrentJnlBatchName: Code[10])
    var
        ReservationWkshBatch: Record "Reservation Wksh. Batch";
    begin
        ReservationWkshBatch.Get(CurrentJnlBatchName);
    end;

    local procedure CheckAndCreateName(var CurrentJnlBatchName: Code[10])
    var
        ReservationWkshBatch: Record "Reservation Wksh. Batch";
    begin
        if ReservationWkshBatch.Get(CurrentJnlBatchName) then
            exit;

        if not ReservationWkshBatch.FindFirst() then begin
            ReservationWkshBatch.Init();
            ReservationWkshBatch.Name := DefaultNameTok;
            ReservationWkshBatch.Description := DefaultDescriptionTok;
            ReservationWkshBatch.Insert(true);
            Commit();
        end;
        CurrentJnlBatchName := ReservationWkshBatch.Name;
    end;

    procedure OpenJnl(var CurrentJnlBatchName: Code[10]; var ReservationWkshLine: Record "Reservation Wksh. Line")
    begin
        CheckAndCreateName(CurrentJnlBatchName);
        ReservationWkshLine.FilterGroup(2);
        ReservationWkshLine.SetRange("Journal Batch Name", CurrentJnlBatchName);
        ReservationWkshLine.FilterGroup(0);
    end;

    procedure CalculateDemand(BatchName: Code[10])
    var
        GetDemandToReserve: Report "Get Demand To Reserve";
    begin
        GetDemandToReserve.SetBatchName(BatchName);
        GetDemandToReserve.RunModal();

        OnCalculateDemandOnAfterSync(BatchName, GetDemandToReserve);

        AutoAllocate(BatchName, GetDemandToReserve);
    end;

    local procedure AutoAllocate(BatchName: Code[10]; var GetDemandToReserve: Report "Get Demand To Reserve")
    var
        ReservationWkshLine: Record "Reservation Wksh. Line";
    begin
        if GetDemandToReserve.GetAllocateAfterPopulate() then begin
            ReservationWkshLine.SetRange("Journal Batch Name", BatchName);
            AllocateQuantity(ReservationWkshLine);
        end;
    end;

    procedure CreateSourceDocumentText(ReservationWkshLine: Record "Reservation Wksh. Line") LineText: Text[100]
    begin
        OnBeforeCreateSourceDocumentText(ReservationWkshLine, LineText);
        if LineText <> '' then
            exit(LineText);

        exit('');
    end;

    procedure GetSourceDocumentLine(ReservationWkshLine: Record "Reservation Wksh. Line";
                                    var RecordVariant: Variant;
                                    var MaxQtyToReserve: Decimal; var MaxQtyToReserveBase: Decimal;
                                    var AvailabilityDate: Date)
    begin
        Clear(RecordVariant);
        Clear(MaxQtyToReserve);
        Clear(MaxQtyToReserveBase);
        Clear(AvailabilityDate);

        if ReservationWkshLine.IsOutdated() then
            exit;

        OnGetSourceDocumentLine(ReservationWkshLine, RecordVariant, MaxQtyToReserve, MaxQtyToReserveBase, AvailabilityDate);
    end;

    procedure GetSourceDocumentLineQuantities(ReservationWkshLine: Record "Reservation Wksh. Line";
                                              var OutstandingQty: Decimal; var ReservedQty: Decimal; var ReservedFromStockQty: Decimal)
    begin
        OutstandingQty := 0;
        ReservedQty := 0;
        ReservedFromStockQty := 0;

        if ReservationWkshLine.IsOutdated() then
            exit;

        OnGetSourceDocumentLineQuantities(ReservationWkshLine, OutstandingQty, ReservedQty, ReservedFromStockQty);
    end;

    procedure ShowSourceDocument(ReservationWkshLine: Record "Reservation Wksh. Line")
    var
    begin
        if ReservationWkshLine.IsOutdated() then
            Error(LineIsOutdatedErr);

        OnShowSourceDocument(ReservationWkshLine);
    end;

    procedure ShowReservationEntries(ReservationWkshLine: Record "Reservation Wksh. Line")
    begin
        if ReservationWkshLine.IsOutdated() then
            Error(LineIsOutdatedErr);

        OnShowReservationEntries(ReservationWkshLine);
    end;

    procedure ShowStatistics(ReservationWkshLine: Record "Reservation Wksh. Line")
    var
    begin
        if ReservationWkshLine.IsOutdated() then
            Error(LineIsOutdatedErr);

        OnShowStatistics(ReservationWkshLine);
    end;

    procedure GetAvailRemainingQtyOnItemLedgerEntry(var AvailableQtyBase: Decimal; var InventoryQtyBase: Decimal; var ReservedQtyBase: Decimal; var WarehouseQtyBase: Decimal;
                                                    ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10])
    var
        ItemTrackingSetup: Record "Item Tracking Setup";
        Location: Record Location;
        TempBinContentBuffer: Record "Bin Content Buffer" temporary;
        WarehouseAvailabilityMgt: Codeunit "Warehouse Availability Mgt.";
        SummarizedStockByItemTrkg: Query "Summarized Stock By Item Trkg.";
        QtyReservedFromItemLedger: Query "Qty. Reserved From Item Ledger";
        NonReservedQtyLotSN: Decimal;
        CurrWhseQty: Decimal;
        QtyOnOutboundBins: Decimal;
        QtyOnSpecialBins: Decimal;
    begin
        AvailableQtyBase := 0;
        InventoryQtyBase := 0;
        ReservedQtyBase := 0;
        WarehouseQtyBase := 0;

        SummarizedStockByItemTrkg.SetRange(Item_No_, ItemNo);
        SummarizedStockByItemTrkg.SetRange(Variant_Code, VariantCode);
        SummarizedStockByItemTrkg.SetRange(Location_Code, LocationCode);
        SummarizedStockByItemTrkg.SetRange(Open, true);
        SummarizedStockByItemTrkg.SetRange(Positive, true);
        SummarizedStockByItemTrkg.Open();
        while SummarizedStockByItemTrkg.Read() do begin
            ItemTrackingSetup."Serial No." := SummarizedStockByItemTrkg.Serial_No_;
            ItemTrackingSetup."Lot No." := SummarizedStockByItemTrkg.Lot_No_;
            ItemTrackingSetup."Package No." := SummarizedStockByItemTrkg.Package_No_;
            if not IsItemTrackingBlocked(ItemNo, VariantCode, ItemTrackingSetup) then begin
                NonReservedQtyLotSN := SummarizedStockByItemTrkg.Remaining_Quantity;
                InventoryQtyBase += SummarizedStockByItemTrkg.Remaining_Quantity;

                QtyReservedFromItemLedger.SetRange(Item_No_, ItemNo);
                QtyReservedFromItemLedger.SetRange(Variant_Code, VariantCode);
                QtyReservedFromItemLedger.SetRange(Location_Code, LocationCode);
                QtyReservedFromItemLedger.SetRange(Serial_No_, ItemTrackingSetup."Serial No.");
                QtyReservedFromItemLedger.SetRange(Lot_No_, ItemTrackingSetup."Lot No.");
                QtyReservedFromItemLedger.SetRange(Package_No_, ItemTrackingSetup."Package No.");
                QtyReservedFromItemLedger.Open();
                if QtyReservedFromItemLedger.Read() then begin
                    NonReservedQtyLotSN -= QtyReservedFromItemLedger.Quantity__Base_;
                    ReservedQtyBase += QtyReservedFromItemLedger.Quantity__Base_;
                end;

                CurrWhseQty := 0;
                QtyOnOutboundBins := 0;
                QtyOnSpecialBins := 0;
                if Location.Get(LocationCode) and Location."Require Pick" then begin
                    CurrWhseQty := CalcNonRegisteredQtyOutstanding(ItemNo, VariantCode, LocationCode, ItemTrackingSetup);

                    if Location."Bin Mandatory" and not Location."Directed Put-away and Pick" and ItemTrackingSetup.TrackingExists()
                    then begin
                        WarehouseAvailabilityMgt.GetOutboundBinsOnBasicWarehouseLocation(
                          TempBinContentBuffer, LocationCode, ItemNo, VariantCode, ItemTrackingSetup);
                        TempBinContentBuffer.CalcSums("Qty. Outstanding (Base)");
                        QtyOnOutboundBins := TempBinContentBuffer."Qty. Outstanding (Base)";
                    end else
                        QtyOnOutboundBins :=
                            WarehouseAvailabilityMgt.CalcQtyOnOutboundBins(LocationCode, ItemNo, VariantCode, ItemTrackingSetup, true);

                    QtyOnSpecialBins :=
                        WarehouseAvailabilityMgt.CalcQtyOnSpecialBinsOnLocation(
                          LocationCode, ItemNo, VariantCode, ItemTrackingSetup, TempBinContentBuffer);

                    CurrWhseQty += QtyOnOutboundBins + QtyOnSpecialBins;
                    if CurrWhseQty < 0 then
                        CurrWhseQty := 0;
                end;
                NonReservedQtyLotSN -= CurrWhseQty;
                WarehouseQtyBase += CurrWhseQty;

                if NonReservedQtyLotSN > 0 then
                    AvailableQtyBase += NonReservedQtyLotSN;
            end;
        end;
    end;

    local procedure IsItemTrackingBlocked(ItemNo: Code[20]; VariantCode: Code[10]; ItemTrackingSetup: Record "Item Tracking Setup"): Boolean
    var
        LotNoInformation: Record "Lot No. Information";
        SerialNoInformation: Record "Serial No. Information";
    begin
        if ItemTrackingSetup."Lot No." <> '' then
            if LotNoInformation.Get(ItemNo, VariantCode, ItemTrackingSetup."Lot No.") then
                if LotNoInformation.Blocked then
                    exit(true);

        if ItemTrackingSetup."Serial No." <> '' then
            if SerialNoInformation.Get(ItemNo, VariantCode, ItemTrackingSetup."Serial No.") then
                if SerialNoInformation.Blocked then
                    exit(true);

        exit(false);
    end;

    local procedure CalcNonRegisteredQtyOutstanding(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; WhseItemTrackingSetup: Record "Item Tracking Setup"): Decimal
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        WarehouseActivityLine.SetRange("Variant Code", VariantCode);
        WarehouseActivityLine.SetRange("Location Code", LocationCode);
        WarehouseActivityLine.SetTrackingFilterFromItemTrackingSetup(WhseItemTrackingSetup);
        WarehouseActivityLine.CalcSums("Qty. Outstanding (Base)");
        exit(WarehouseActivityLine."Qty. Outstanding (Base)");
    end;

    procedure CarryOutAction(var ReservationWkshLine: Record "Reservation Wksh. Line")
    var
        ReservationWkshLineToProcess: Record "Reservation Wksh. Line";
        CarryOutReservation: Report "Carry Out Reservation";
    begin
        ReservationWkshLineToProcess.Copy(ReservationWkshLine);
        CarryOutReservation.SetTableView(ReservationWkshLineToProcess);
        CarryOutReservation.RunModal();
    end;

    procedure LogChanges(ReservationWkshLine: Record "Reservation Wksh. Line"; Qty: Decimal)
    var
        ReservationWorksheetLog: Record "Reservation Worksheet Log";
    begin
        ReservationWorksheetLog.Init();
        ReservationWorksheetLog."Journal Batch Name" := ReservationWkshLine."Journal Batch Name";
        ReservationWorksheetLog."Entry No." := 0;
        ReservationWorksheetLog."Record ID" := ReservationWkshLine."Record ID";
        ReservationWorksheetLog.Quantity := Qty;
        ReservationWorksheetLog.Insert(true);
    end;

    procedure AllocateQuantity(var ReservationWkshLine: Record "Reservation Wksh. Line")
    var
        AllocationPolicy: Record "Allocation Policy";
        TempAllocationPolicy: Record "Allocation Policy" temporary;
        AllocateReservation: Interface "Allocate Reservation";
        AllocationCompleted: Boolean;
    begin
        ReservationWkshLine.LockTable();
        if not ReservationWkshLine.FindFirst() then
            exit;

        AllocationPolicy.SetRange("Journal Batch Name", ReservationWkshLine."Journal Batch Name");
        if not AllocationPolicy.FindSet() then begin
            TempAllocationPolicy.Init();
            TempAllocationPolicy."Journal Batch Name" := ReservationWkshLine."Journal Batch Name";
            TempAllocationPolicy."Line No." := 10000;
            TempAllocationPolicy."Allocation Rule" := TempAllocationPolicy."Allocation Rule"::"Basic (No Conflicts)";
            TempAllocationPolicy.Insert();
        end else
            repeat
                TempAllocationPolicy.Init();
                TempAllocationPolicy := AllocationPolicy;
                TempAllocationPolicy.Insert();
            until AllocationPolicy.Next() = 0;

        TempAllocationPolicy.FindSet();
        repeat
            AllocateReservation := TempAllocationPolicy."Allocation Rule";
            AllocateReservation.DeleteAllocation(ReservationWkshLine);
            AllocateReservation.Allocate(ReservationWkshLine);
            AllocationCompleted := AllocateReservation.AllocationCompleted(ReservationWkshLine);
        until (TempAllocationPolicy.Next() = 0) or AllocationCompleted;
    end;

    procedure DeleteAllocation(var ReservationWkshLine: Record "Reservation Wksh. Line")
    var
        ReservWkshLine: Record "Reservation Wksh. Line";
    begin
        ReservWkshLine.LockTable();
        ReservWkshLine.Copy(ReservationWkshLine);
        if not ReservWkshLine.FindSet(true) then
            exit;

        repeat
            ReservWkshLine.Validate("Qty. to Reserve", 0);
            ReservWkshLine.Modify(true);
        until ReservWkshLine.Next() = 0;
    end;

    procedure AcceptSelected(var ReservationWkshLine: Record "Reservation Wksh. Line")
    begin
        ReservationWkshLine.ModifyAll(Accept, true, true);
    end;

    procedure CreateTransferOrder(var TransferHeader: Record "Transfer Header"; ReservationWkshLine: Record "Reservation Wksh. Line"; LocationFromCode: Code[10])
    var
        TransferLine: Record "Transfer Line";
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.TestField("Transfer Order Nos.");

        TransferHeader.Init();
        TransferHeader."No." := '';
        TransferHeader."Posting Date" := WorkDate();
        TransferHeader.Insert(true);
        TransferHeader.Validate("Transfer-from Code", LocationFromCode);
        TransferHeader.Validate("Transfer-to Code", ReservationWkshLine."Location Code");
        TransferHeader.Modify();

        TransferLine.Init();
        TransferLine.BlockDynamicTracking(true);
        TransferLine."Document No." := TransferHeader."No.";
        TransferLine."Line No." := 10000;
        TransferLine.Validate("Item No.", ReservationWkshLine."Item No.");
        TransferLine.Description := ReservationWkshLine.Description;
        TransferLine.Validate("Variant Code", ReservationWkshLine."Variant Code");
        TransferLine.Validate("Transfer-from Code", TransferHeader."Transfer-from Code");
        TransferLine.Validate("Transfer-to Code", TransferHeader."Transfer-to Code");
        TransferLine.Validate("Unit of Measure Code", ReservationWkshLine."Unit of Measure Code");
        TransferLine."Receipt Date" := TransferHeader."Receipt Date";
        TransferLine."Shipment Date" := TransferHeader."Shipment Date";
        TransferLine.Insert();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateSourceDocumentText(var ReservationWkshLine: Record "Reservation Wksh. Line"; var LineText: Text[100])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSourceDocumentLine(var ReservationWkshLine: Record "Reservation Wksh. Line"; var RecordVariant: Variant; var MaxQtyToReserve: Decimal; var MaxQtyToReserveBase: Decimal; var AvailabilityDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSourceDocumentLineQuantities(var ReservationWkshLine: Record "Reservation Wksh. Line"; var OutstandingQty: Decimal; var ReservedQty: Decimal; var ReservedFromStockQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowSourceDocument(var ReservationWkshLine: Record "Reservation Wksh. Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowReservationEntries(var ReservationWkshLine: Record "Reservation Wksh. Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowStatistics(var ReservationWkshLine: Record "Reservation Wksh. Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateDemandOnAfterSync(BatchName: Code[10]; var GetDemandToReserve: Report "Get Demand To Reserve")
    begin
    end;
}
