// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Tracking;

using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Ledger;

codeunit 7326 "Whse. Item Tracking FEFO"
{

    trigger OnRun()
    begin
    end;

    var
        TempGlobalEntrySummary: Record "Entry Summary" temporary;
        SourceReservationEntry: Record "Reservation Entry";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        LastSummaryEntryNo: Integer;
        StrictExpirationPosting: Boolean;
        HasExpiredItems: Boolean;
        ExpiredItemsForPickMsg: Label '\\Some items were not included in the pick due to their expiration date.';
        CalledFromMovementWksh: Boolean;

    procedure CreateEntrySummaryFEFO(Location: Record Location; ItemNo: Code[20]; VariantCode: Code[10]; UseExpDates: Boolean)
    begin
        InitEntrySummaryFEFO();
        LastSummaryEntryNo := 0;
        StrictExpirationPosting := ItemTrackingMgt.StrictExpirationPosting(ItemNo);

        SummarizeInventoryFEFO(Location, ItemNo, VariantCode, '', UseExpDates);
        if UseExpDates then
            SummarizeAdjustmentBinFEFO(Location, ItemNo, VariantCode);

        OnAfterCreateEntrySummaryFEFO(TempGlobalEntrySummary);
    end;

    procedure CreateEntrySummaryFEFO(Location: Record Location; ItemNo: Code[20]; VariantCode: Code[10]; UnitofMeasureCode: Code[10]; UseExpDates: Boolean)
    begin
        InitEntrySummaryFEFO();
        LastSummaryEntryNo := 0;
        StrictExpirationPosting := ItemTrackingMgt.StrictExpirationPosting(ItemNo);

        SummarizeInventoryFEFO(Location, ItemNo, VariantCode, UnitofMeasureCode, UseExpDates);
        if UseExpDates then
            SummarizeAdjustmentBinFEFO(Location, ItemNo, VariantCode);

        OnAfterCreateEntrySummaryFEFO(TempGlobalEntrySummary);
    end;

    local procedure SummarizeInventoryFEFO(Location: Record Location; ItemNo: Code[20]; VariantCode: Code[10]; UnitofMeasureCode: Code[10]; HasExpirationDate: Boolean)
    var
        ItemTrackingSetup: Record "Item Tracking Setup";
        SummarizedStockByItemTrkg: Query "Summarized Stock By Item Trkg.";
        QtyReservedFromItemLedger: Query "Qty. Reserved From Item Ledger";
        NonReservedQtyLotSN: Decimal;
        DoInsertEntrySummary: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSummarizeInventoryFEFO(Location, ItemNo, VariantCode, HasExpirationDate, IsHandled,
            TempGlobalEntrySummary, StrictExpirationPosting, LastSummaryEntryNo, HasExpiredItems);
        if IsHandled then
            exit;

        SummarizedStockByItemTrkg.SetSKUFilters(ItemNo, VariantCode, Location.Code);
        SummarizedStockByItemTrkg.SetRange(Open, true);
        SummarizedStockByItemTrkg.SetRange(Positive, true);
        if UnitofMeasureCode <> '' then
            SummarizedStockByItemTrkg.SetRange(Unit_of_Measure_Code, UnitofMeasureCode);
        if HasExpirationDate then
            SummarizedStockByItemTrkg.SetFilter(Expiration_Date, '<>%1', 0D)
        else
            SummarizedStockByItemTrkg.SetRange(Expiration_Date, 0D);

        SummarizedStockByItemTrkg.Open();
        while SummarizedStockByItemTrkg.Read() do
            if not CheckIfWhseACtivityLineExists(SummarizedStockByItemTrkg, ItemNo, Location.Code) then begin
                SummarizedStockByItemTrkg.GetItemTrackingSetup(ItemTrackingSetup);
                if not IsItemTrackingBlocked(ItemNo, VariantCode, ItemTrackingSetup) then begin
                    NonReservedQtyLotSN := SummarizedStockByItemTrkg.Remaining_Quantity;

                    QtyReservedFromItemLedger.SetSKUFilters(ItemNo, VariantCode, Location.Code);
                    QtyReservedFromItemLedger.SetTrackingFilters(ItemTrackingSetup);
                    QtyReservedFromItemLedger.Open();
                    if QtyReservedFromItemLedger.Read() then
                        NonReservedQtyLotSN -= QtyReservedFromItemLedger.Quantity__Base_;

                    DoInsertEntrySummary := NonReservedQtyLotSN - CalcNonRegisteredQtyOutstanding(ItemNo, VariantCode, Location.Code, ItemTrackingSetup, HasExpirationDate) > 0;
                    OnSummarizeInventoryFEFOOnBeforeInsertEntrySummaryFEFO(Location, ItemNo, VariantCode, HasExpirationDate, NonReservedQtyLotSN, ItemTrackingSetup, SummarizedStockByItemTrkg.Expiration_Date, DoInsertEntrySummary, TempGlobalEntrySummary);
                    if DoInsertEntrySummary then
                        InsertEntrySummaryFEFO(ItemTrackingSetup, SummarizedStockByItemTrkg.Expiration_Date);
                end;
            end;
    end;

    local procedure CalcNonRegisteredQtyOutstanding(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; WhseItemTrackingSetup: Record "Item Tracking Setup"; HasExpirationDate: Boolean): Decimal
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        if CalledFromMovementWksh then
            WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::Movement)
        else
            WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        WarehouseActivityLine.SetRange("Variant Code", VariantCode);
        WarehouseActivityLine.SetRange("Location Code", LocationCode);
        WarehouseActivityLine.SetTrackingFilterFromItemTrackingSetup(WhseItemTrackingSetup);
        if HasExpirationDate then
            WarehouseActivityLine.SetFilter(WarehouseActivityLine."Expiration Date", '<>%1', 0D)
        else
            WarehouseActivityLine.SetRange("Expiration Date", 0D);
        WarehouseActivityLine.CalcSums(WarehouseActivityLine."Qty. Outstanding (Base)");
        exit(WarehouseActivityLine."Qty. Outstanding (Base)");
    end;

    local procedure SummarizeAdjustmentBinFEFO(Location: Record Location; ItemNo: Code[20]; VariantCode: Code[10])
    var
        WhseEntry: Record "Warehouse Entry";
        ItemTrackingSetup: Record "Item Tracking Setup";
        ExpirationDate: Date;
        EntriesExist: Boolean;
    begin
        if Location."Adjustment Bin Code" = '' then
            exit;

        WhseEntry.Reset();
        WhseEntry.SetCurrentKey("Item No.", "Bin Code", "Location Code", "Variant Code", "Unit of Measure Code", "Lot No.", "Serial No.");
        WhseEntry.SetRange("Item No.", ItemNo);
        WhseEntry.SetRange("Bin Code", Location."Adjustment Bin Code");
        WhseEntry.SetRange("Location Code", Location.Code);
        WhseEntry.SetRange("Variant Code", VariantCode);
        if WhseEntry.IsEmpty() then
            exit;

        if WhseEntry.FindSet() then
            repeat
                ItemTrackingSetup.CopyTrackingFromWhseEntry(WhseEntry);
                if not EntrySummaryFEFOExists(ItemTrackingSetup) then
                    if CalcAvailQtyOnWarehouse(WhseEntry) <> 0 then
                        if not IsItemTrackingBlocked(WhseEntry."Item No.", WhseEntry."Variant Code", ItemTrackingSetup) then begin
                            ExpirationDate :=
                                ItemTrackingMgt.WhseExistingExpirationDate(
                                    WhseEntry."Item No.", WhseEntry."Variant Code", Location, ItemTrackingSetup, EntriesExist);

                            if not EntriesExist then
                                ExpirationDate := 0D;

                            OnSummarizeAdjustmentBinFEFOOnBeforeInsertEntrySummaryFEFO(TempGlobalEntrySummary, WhseEntry, ItemTrackingSetup, Location);
                            InsertEntrySummaryFEFO(ItemTrackingSetup, ExpirationDate);
                        end;
            until WhseEntry.Next() = 0;
    end;

    local procedure InitEntrySummaryFEFO()
    begin
        TempGlobalEntrySummary.DeleteAll();
        TempGlobalEntrySummary.Reset();
        TempGlobalEntrySummary.SetTrackingKey();
    end;

    procedure InsertEntrySummaryFEFO(ItemTrackingSetup: Record "Item Tracking Setup"; ExpirationDate: Date)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertEntrySummaryFEFOProcedure(ItemTrackingSetup, TempGlobalEntrySummary, LastSummaryEntryNo, StrictExpirationPosting, ExpirationDate, HasExpiredItems, IsHandled);
        if IsHandled then
            exit;

        if (not StrictExpirationPosting) or (ExpirationDate >= WorkDate()) then begin
            TempGlobalEntrySummary.Init();
            TempGlobalEntrySummary."Entry No." := LastSummaryEntryNo + 1;
            TempGlobalEntrySummary.CopyTrackingFromItemTrackingSetup(ItemTrackingSetup);
            TempGlobalEntrySummary."Expiration Date" := ExpirationDate;
            OnBeforeInsertEntrySummaryFEFO(TempGlobalEntrySummary);
            TempGlobalEntrySummary.Insert();
            LastSummaryEntryNo := TempGlobalEntrySummary."Entry No.";
        end else
            HasExpiredItems := true;
    end;

    procedure EntrySummaryFEFOExists(ItemTrackingSetup: Record "Item Tracking Setup"): Boolean
    begin
        TempGlobalEntrySummary.SetTrackingFilterFromItemTrackingSetup(ItemTrackingSetup);
        OnEntrySummaryFEFOExistsOnAfterSetFilters(TempGlobalEntrySummary);
        exit(TempGlobalEntrySummary.FindSet());
    end;

    procedure FindFirstEntrySummaryFEFO(var EntrySummary: Record "Entry Summary"): Boolean
    var
        IsFound: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        IsFound := false;
        OnBeforeFindFirstEntrySummaryFEFO(TempGlobalEntrySummary, IsFound, IsHandled);
        if IsHandled then begin
            if IsFound then
                EntrySummary := TempGlobalEntrySummary;
            exit(IsFound);
        end;

        TempGlobalEntrySummary.Reset();
        TempGlobalEntrySummary.SetCurrentKey("Expiration Date");
        if not TempGlobalEntrySummary.Find('-') then
            exit(false);

        EntrySummary := TempGlobalEntrySummary;
        exit(true);
    end;

    procedure FindNextEntrySummaryFEFO(var EntrySummary: Record "Entry Summary") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindNextEntrySummaryFEFO(EntrySummary, TempGlobalEntrySummary, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if TempGlobalEntrySummary.Next() = 0 then
            exit(false);

        EntrySummary := TempGlobalEntrySummary;
        exit(true);
    end;

    procedure GetHasExpiredItems(): Boolean
    begin
        exit(HasExpiredItems);
    end;

    procedure GetResultMessageForExpiredItem(): Text[100]
    begin
        if HasExpiredItems then
            exit(ExpiredItemsForPickMsg);

        exit('');
    end;

    procedure SetSource(SourceType2: Integer; SourceSubType2: Integer; SourceNo2: Code[20]; SourceLineNo2: Integer; SourceSubLineNo2: Integer)
    var
        CreatePick: Codeunit "Create Pick";
    begin
        OnBeforeSetSource(SourceType2, SourceSubType2, SourceNo2, SourceLineNo2, SourceSubLineNo2);

        SourceReservationEntry.Reset();
        CreatePick.SetFiltersOnReservEntry(
          SourceReservationEntry, SourceType2, SourceSubType2, SourceNo2, SourceLineNo2, SourceSubLineNo2);
    end;

    procedure SetCalledFromMovementWksh(NewCalledFromMovementWksh: Boolean)
    begin
        CalledFromMovementWksh := NewCalledFromMovementWksh;
    end;

    local procedure CalcAvailQtyOnWarehouse(var WhseEntry: Record "Warehouse Entry"): Decimal
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        WarehouseEntry.CopyFilters(WhseEntry);
        WarehouseEntry.SetTrackingFilterFromWhseEntry(WhseEntry);
        WarehouseEntry.CalcSums(Quantity);
        exit(WarehouseEntry.Quantity);
    end;

    local procedure IsItemTrackingBlocked(ItemNo: Code[20]; VariantCode: Code[10]; ItemTrackingSetup: Record "Item Tracking Setup"): Boolean
    var
        LotNoInformation: Record "Lot No. Information";
        SerialNoInformation: Record "Serial No. Information";
        IsBlocked: Boolean;
    begin
        if ItemTrackingSetup."Lot No." <> '' then
            if LotNoInformation.Get(ItemNo, VariantCode, ItemTrackingSetup."Lot No.") then
                if LotNoInformation.Blocked then
                    exit(true);
        if ItemTrackingSetup."Serial No." <> '' then
            if SerialNoInformation.Get(ItemNo, VariantCode, ItemTrackingSetup."Serial No.") then
                if SerialNoInformation.Blocked then
                    exit(true);

        IsBlocked := false;
        OnAfterIsItemTrackingBlocked(SourceReservationEntry, ItemNo, VariantCode, ItemTrackingSetup."Lot No.", IsBlocked, ItemTrackingSetup);

        exit(IsBlocked);
    end;

    local procedure CheckIfWhseActivityLineExists(var SummarizedStockByItemTrkg: Query "Summarized Stock By Item Trkg."; ItemNo: Code[20]; LocationCode: Code[10]): Boolean
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Invt. Movement");
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        WarehouseActivityLine.SetRange("Location Code", LocationCode);
        WarehouseActivityLine.SetRange("Serial No.", SummarizedStockByItemTrkg.Serial_No_);
        WarehouseActivityLine.SetRange("Lot No.", SummarizedStockByItemTrkg.Lot_No_);
        WarehouseActivityLine.SetRange("Package No.", SummarizedStockByItemTrkg.Package_No_);
        exit(not WarehouseActivityLine.IsEmpty());
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateEntrySummaryFEFO(var TempEntrySummary: Record "Entry Summary" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsItemTrackingBlocked(var ReservEntry: Record "Reservation Entry"; ItemNo: Code[20]; VariantCode: Code[10]; LotNo: Code[50]; var IsBlocked: Boolean; ItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindFirstEntrySummaryFEFO(var TempGlobalEntrySummary: Record "Entry Summary" temporary; var IsFound: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertEntrySummaryFEFO(var TempGlobalEntrySummary: Record "Entry Summary" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertEntrySummaryFEFOProcedure(ItemTrackingSetup: Record "Item Tracking Setup"; var TempGlobalEntrySummary: Record "Entry Summary" temporary; var LastSummaryEntryNo: Integer; StrictExpirationPosting: Boolean; ExpirationDate: Date; var HasExpiredItems: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetSource(SourceType2: Integer; SourceSubType2: Integer; SourceNo2: Code[20]; SourceLineNo2: Integer; SourceSubLineNo2: Integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeSummarizeInventoryFEFO(Location: Record Location; ItemNo: Code[20]; VariantCode: Code[10]; HasExpirationDate: Boolean; var IsHandled: Boolean; var TempGlobalEntrySummary: Record "Entry Summary"; var StrictExpirationPosting: Boolean; var LastSummaryEntryNo: Integer; var HasExpiredItems: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnEntrySummaryFEFOExistsOnAfterSetFilters(var TempGlobalEntrySummary: Record "Entry Summary" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSummarizeAdjustmentBinFEFOOnBeforeInsertEntrySummaryFEFO(var TempGlobalEntrySummary: Record "Entry Summary" temporary; WarehouseEntry: Record "Warehouse Entry"; var ItemTrackingSetup: Record "Item Tracking Setup"; Location: Record Location)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindNextEntrySummaryFEFO(var EntrySummary: Record "Entry Summary"; var TempGlobalEntrySummary: Record "Entry Summary" temporary; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnSummarizeInventoryFEFOOnBeforeInsertEntrySummaryFEFO(var Location: Record Location; ItemNo: Code[20]; VariantCode: Code[10]; HasExpirationDate: Boolean; NonReservedQtyLotSN: Decimal; var ItemTrackingSetup: Record "Item Tracking Setup"; ExpirationDate: Date; var DoInsertEntrySummary: Boolean; var TempGlobalEntrySummary: Record "Entry Summary" temporary)
    begin
    end;
}

