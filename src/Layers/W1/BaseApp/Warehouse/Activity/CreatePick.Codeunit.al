// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Activity;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Planning;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.Availability;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.InternalDocument;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Tracking;
using Microsoft.Warehouse.Worksheet;
using System.Telemetry;

codeunit 7312 "Create Pick"
{
    Permissions = TableData "Whse. Item Tracking Line" = rimd;

    trigger OnRun()
    begin
    end;

    var
        CurrWarehouseActivityHeader: Record "Warehouse Activity Header";
        CurrWarehouseShipmentLine: Record "Warehouse Shipment Line";
        CurrWhseInternalPickLine: Record "Whse. Internal Pick Line";
        CurrJobPlanningLine: Record "Job Planning Line";
        CurrWhseWorksheetLine: Record "Whse. Worksheet Line";
        CurrLocation: Record Location;
        CurrItem: Record Item;
        CurrBin: Record Bin;
        CurrBinType: Record "Bin Type";
        CurrStockkeepingUnit: Record "Stockkeeping Unit";
        CreatePickParameters: Record "Create Pick Parameters";
        SourceWhseItemTrackingLine: Record "Whse. Item Tracking Line";
        WarehouseSetup: Record "Warehouse Setup";
        WhseSetupLocation: Record Location;
        TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary;
        TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary;
        TempTotalWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary;
        TempWarehousePickSummary: Record "Warehouse Pick Summary" temporary;
        WhseManagement: Codeunit "Whse. Management";
        WarehouseAvailabilityMgt: Codeunit "Warehouse Availability Mgt.";
        ItemTrackingManagement: Codeunit "Item Tracking Management";
        UnitOfMeasureManagement: Codeunit "Unit of Measure Management";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        CustomWhseSourceLine: Variant;
        CurrSourceSubType: Option;
        CurrSourceNo: Code[20];
        ShippingAgentCode: Code[10];
        ShippingAgentServiceCode: Code[10];
        ShipmentMethodCode: Code[10];
        TransferRemQtyToPickBase: Decimal;
        TempNo: Integer;
        CurrBreakbulkNo: Integer;
        TempLineNo: Integer;
        CurrSourceType: Integer;
        CurrSourceLineNo: Integer;
        CurrSourceSubLineNo: Integer;
        IsMovementWorksheet: Boolean;
        LastWhseItemTrkgLineNo: Integer;
        WhseItemTrkgLineCount: Integer;
        WhseItemTrkgExists: Boolean;
        CrossDock: Boolean;
        ReservationExists: Boolean;
        ReservedForItemLedgEntry: Boolean;
        CalledFromPickWksh: Boolean;
        CalledFromMoveWksh: Boolean;
        CalledFromWksh: Boolean;
        ReqFEFOPick: Boolean;
        HasExpiredItems: Boolean;
        CannotBeHandledReasons: array[20] of Text;
        TotalQtyPickedBase: Decimal;
        SaveSummary: Boolean;
        SummaryPageMessage: Text;

        NothingToHandleTryShowSummaryLbl: Label 'Try the "Show Summary (Directed Put-away and Pick)" option when creating pick to inspect the error.';
        NothingToHandleErr: Label 'Nothing to handle. %1.', Comment = '%1 = reason in text';
        NothingToHandleWithoutReasonErr: Label 'Nothing to handle.';
        BinIsNotForPickTxt: Label 'The quantity to be picked is in bin %1, which is not set up for picking', Comment = '%1: Field("Bin Code")';
        BinIsForReceiveOrShipTxt: Label 'The quantity to be picked is in bin %1, which is set up for receiving or shipping', Comment = '%1: Field("Bin Code")';
        QtyReservedNotFromInventoryTxt: Label 'The quantity to be picked is not in inventory yet. You must first post the supply from which the source document is reserved';
        ValidValuesIfSNDefinedErr: Label 'Field %1 can only have values -1, 0 or 1 when serial no. is defined. Current value is %2.', Comment = '%1 = field name, %2 = field value';
        BinPolicyTelemetryCategoryTok: Label 'Bin Policy', Locked = true;
        CheckAllowBreakBulkTxt: Label 'Check "Allow Breakbulk" on Location Card';
        DefaultBinPickPolicyTelemetryTok: Label 'Default Bin Pick Policy in used for warehouse pick.', Locked = true;
        RankingBinPickPolicyTelemetryTok: Label 'Bin Ranking Bin Pick Policy in used for warehouse pick.', Locked = true;
        ProdAsmJobWhseHandlingTelemetryCategoryTok: Label 'Prod/Asm/Project Whse. Handling', Locked = true;
        ProdAsmJobWhseHandlingTelemetryTok: Label 'Prod/Asm/Project Whse. Handling in used for warehouse pick.', Locked = true;
        NotEqualTok: Label '<>%1', Locked = true;
        OrTok: Label '%1|%2', Locked = true;

    procedure CreateTempLine(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; UnitofMeasureCode: Code[10]; FromBinCode: Code[20]; ToBinCode: Code[20]; QtyPerUnitofMeasure: Decimal; var TotalQtytoPick: Decimal; var TotalQtytoPickBase: Decimal)
    begin
        CreateTempLine(LocationCode, ItemNo, VariantCode, UnitofMeasureCode, FromBinCode, ToBinCode, QtyPerUnitofMeasure, 0, 0, TotalQtytoPick, TotalQtytoPickBase);
    end;

    procedure CreateTempLine(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; UnitofMeasureCode: Code[10]; FromBinCode: Code[20]; ToBinCode: Code[20]; QtyPerUnitofMeasure: Decimal; QtyRoundingPrecision: Decimal; QtyRoundingPrecisionBase: Decimal; var TotalQtytoPick: Decimal; var TotalQtytoPickBase: Decimal)
    var
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        QtyToPick: Decimal;
        RemTrackedQtyToPick: Decimal;
        i: Integer;
        RemTrackedQtyToPickBase: Decimal;
        QtyToPickBase: Decimal;
        QtyToTrackBase: Decimal;
        TotalItemTrackedQtyToPick: Decimal;
        TotalItemTrackedQtyToPickBase: Decimal;
        NewQtyToHandle: Decimal;
        IsHandled: Boolean;
    begin
        TotalQtyPickedBase := 0;
        GetLocation(LocationCode);

        InitCalculationSummary(LocationCode, ItemNo, VariantCode, UnitofMeasureCode, FromBinCode, TotalQtytoPick, TotalQtytoPickBase);

        if CheckReservationAndUpdateQtyToPick(LocationCode, ItemNo, VariantCode, UnitofMeasureCode, FromBinCode, QtyPerUnitofMeasure, TotalQtytoPick, TotalQtytoPickBase) then begin
            FinalizeCalculationSummary(); // Insert the warehouse pick calculation summary line when exiting early
            exit;
        end;

        RemTrackedQtyToPick := TotalQtytoPick;
        RemTrackedQtyToPickBase := TotalQtytoPickBase;
        ItemTrackingManagement.GetWhseItemTrkgSetup(ItemNo, WhseItemTrackingSetup);

        ReqFEFOPick := false;
        HasExpiredItems := false;
        if PickAccordingToFEFO(LocationCode, WhseItemTrackingSetup) or PickStrictExpirationPosting(ItemNo, WhseItemTrackingSetup) then begin
            QtyToTrackBase := RemTrackedQtyToPickBase;
            if UndefinedItemTrkg(QtyToTrackBase) then begin
                CreateTempItemTrkgLines(ItemNo, VariantCode, UnitofMeasureCode, QtyToTrackBase, true);
                CreateTempItemTrkgLines(ItemNo, VariantCode, UnitofMeasureCode, TransferRemQtyToPickBase, false);
            end;
        end;

        if TotalQtytoPickBase <> 0 then begin
            TempWhseItemTrackingLine.Reset();
            TempWhseItemTrackingLine.SetFilter("Qty. to Handle", '<> 0');
            if TempWhseItemTrackingLine.Find('-') then begin // First create pick lines for the tracked items
                repeat
                    if TempWhseItemTrackingLine."Qty. to Handle (Base)" <> 0 then begin
                        if TempWhseItemTrackingLine."Qty. to Handle (Base)" > RemTrackedQtyToPickBase then begin
                            TempWhseItemTrackingLine."Qty. to Handle (Base)" := RemTrackedQtyToPickBase;
                            OnBeforeTempWhseItemTrackingLineModifyOnAfterAssignRemQtyToPickBase(TempWhseItemTrackingLine);
                            TempWhseItemTrackingLine.Modify();
                        end;
                        NewQtyToHandle :=
                          Round(RemTrackedQtyToPick / RemTrackedQtyToPickBase * TempWhseItemTrackingLine."Qty. to Handle (Base)", UnitOfMeasureManagement.QtyRndPrecision());
                        if TempWhseItemTrackingLine."Qty. to Handle" <> NewQtyToHandle then begin
                            TempWhseItemTrackingLine."Qty. to Handle" := NewQtyToHandle;
                            OnBeforeTempWhseItemTrackingLineModify(TempWhseItemTrackingLine);
                            TempWhseItemTrackingLine.Modify();
                        end;

                        QtyToPick := TempWhseItemTrackingLine."Qty. to Handle";
                        QtyToPickBase := TempWhseItemTrackingLine."Qty. to Handle (Base)";
                        TotalItemTrackedQtyToPick += QtyToPick;
                        TotalItemTrackedQtyToPickBase += QtyToPickBase;

                        CreateTempLine(
                            LocationCode, ItemNo, VariantCode, UnitofMeasureCode, FromBinCode, ToBinCode,
                            QtyPerUnitofMeasure, QtyRoundingPrecision, QtyRoundingPrecisionBase, QtyToPick, TempWhseItemTrackingLine, QtyToPickBase, WhseItemTrackingSetup);
                        RemTrackedQtyToPickBase -= TempWhseItemTrackingLine."Qty. to Handle (Base)" - QtyToPickBase;
                        RemTrackedQtyToPick -= TempWhseItemTrackingLine."Qty. to Handle" - QtyToPick;
                    end;
                until (TempWhseItemTrackingLine.Next() = 0) or (RemTrackedQtyToPickBase <= 0);

                RemTrackedQtyToPick := Minimum(RemTrackedQtyToPick, TotalQtytoPick - TotalItemTrackedQtyToPick);
                RemTrackedQtyToPickBase := Minimum(RemTrackedQtyToPickBase, TotalQtytoPickBase - TotalItemTrackedQtyToPickBase);
                TotalQtytoPick := RemTrackedQtyToPick;
                TotalQtytoPickBase := RemTrackedQtyToPickBase;

                SaveTempItemTrkgLines();
                Clear(TempWhseItemTrackingLine);
                WhseItemTrkgExists := false;
            end;

            IsHandled := false;
            OnCreateTempLineOnAfterCreateTempLineWithItemTracking(TotalQtytoPickBase, HasExpiredItems, LocationCode, ItemNo, VariantCode, UnitofMeasureCode, FromBinCode, ToBinCode, QtyPerUnitofMeasure, TempWarehouseActivityLine, TempLineNo, IsHandled, TotalItemTrackedQtyToPickBase);
            if not IsHandled then
                if TotalQtytoPickBase <> 0 then //TotalQtytoPickBase can be less than 0 if the item has been reserved for more than the available qty in the warehouse
                    if not HasExpiredItems then
                        if WhseItemTrackingSetup."Serial No. Required" then begin
                            IsHandled := false;
                            OnCreateTempLineOnBeforeCreateTempLineForSerialNo(
                                LocationCode, ItemNo, VariantCode, UnitofMeasureCode, FromBinCode, ToBinCode, QtyPerUnitofMeasure,
                                TotalQtytoPick, TotalQtytoPickBase, TempWhseItemTrackingLine, WhseItemTrackingSetup, IsHandled);
                            if IsHandled then
                                exit;

                            for i := 1 to TotalQtytoPickBase do begin
                                QtyToPickBase := 1;
                                QtyToPick := UnitOfMeasureManagement.RoundQty(QtyToPickBase / QtyPerUnitofMeasure, QtyRoundingPrecision);
                                CreateTempLine(
                                    LocationCode, ItemNo, VariantCode, UnitofMeasureCode, FromBinCode, ToBinCode, QtyPerUnitofMeasure,
                                    QtyRoundingPrecision, QtyRoundingPrecisionBase, QtyToPick, TempWhseItemTrackingLine, QtyToPickBase, WhseItemTrackingSetup);
                            end;
                            TotalQtytoPick := 0;
                            TotalQtytoPickBase := 0;
                        end else
                            CreateTempLine(
                                LocationCode, ItemNo, VariantCode, UnitofMeasureCode, FromBinCode, ToBinCode, QtyPerUnitofMeasure,
                                QtyRoundingPrecision, QtyRoundingPrecisionBase, TotalQtytoPick, TempWhseItemTrackingLine, TotalQtytoPickBase, WhseItemTrackingSetup);
        end;

        FinalizeCalculationSummary(); // Insert the warehouse pick calculation summary line

        OnAfterCreateTempLine(LocationCode, ToBinCode, ItemNo, VariantCode, UnitofMeasureCode, QtyPerUnitofMeasure);
    end;

    local procedure CheckReservationAndUpdateQtyToPick(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; UnitOfMeasureCode: Code[10]; FromBinCode: Code[20]; QtyPerUnitofMeasure: Decimal; var TotalQtyToPick: Decimal; var TotalQtyToPickBase: Decimal): Boolean;
    var
        QtyBaseMaxAvailToPick: Decimal;
        IsHandled: Boolean;
    begin
        ReservationExists := false;
        IsHandled := false;
        OnCreateTempLineOnBeforeCheckReservation(CurrSourceType, CurrSourceNo, CurrSourceLineNo, QtyBaseMaxAvailToPick, IsHandled, LocationCode, ItemNo);
        if not IsHandled then
            if IsReservationExists(CurrSourceType, CurrSourceSubType, CurrSourceNo, CurrSourceLineNo, CurrSourceSubLineNo) then begin
                if CurrLocation."Directed Put-away and Pick" then
                    QtyBaseMaxAvailToPick := CalcMaxQtyAvailToPickInWhseForDirectedPutAwayPick(LocationCode, ItemNo, VariantCode)
                else
                    QtyBaseMaxAvailToPick :=
                        CalcAvailableQty(ItemNo, VariantCode) -
                        CalcPickQtyAssigned(LocationCode, ItemNo, VariantCode, UnitOfMeasureCode, FromBinCode, TempWhseItemTrackingLine);

                OnCreateTempLineOnAfterCalcQtyBaseMaxAvailToPick(QtyBaseMaxAvailToPick, LocationCode, ItemNo, VariantCode);

                // Reduce the TotalQtyToPick based on the max available quantity to pick and existing reservations.
                CheckReservation(
                    QtyBaseMaxAvailToPick, CurrSourceType, CurrSourceSubType, CurrSourceNo, CurrSourceLineNo, CurrSourceSubLineNo, CurrLocation."Always Create Pick Line",
                    QtyPerUnitofMeasure, TotalQtyToPick, TotalQtyToPickBase);

                if not CurrLocation."Always Create Pick Line" then
                    if TotalQtyToPickBase = 0 then
                        exit(true); //TotalQtyToPickBase is modified and Error reason is enqueued in procedure CheckReservation(...)
            end;

        OnAfterCreateTempLineCheckReservation(
            LocationCode, ItemNo, VariantCode, UnitofMeasureCode, QtyPerUnitofMeasure, TotalQtytoPick, TotalQtytoPickBase,
            CurrSourceType, CurrSourceSubType, CurrSourceNo, CurrSourceLineNo, CurrSourceSubLineNo, LastWhseItemTrkgLineNo, TempWhseItemTrackingLine, CurrWarehouseShipmentLine, QtyBaseMaxAvailToPick);
    end;

    local procedure CreateTempLine(
        LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; UnitofMeasureCode: Code[10]; FromBinCode: Code[20]; ToBinCode: Code[20]; QtyPerUnitofMeasure: Decimal;
        QtyRoundingPrecision: Decimal; QtyRoundingPrecisionBase: Decimal; var TotalQtytoPick: Decimal; var TempWhseItemTrackingLine2: Record "Whse. Item Tracking Line" temporary; var TotalQtytoPickBase: Decimal;
        WhseItemTrackingSetup: Record "Item Tracking Setup")
    var
        QtytoPick: Decimal;
        QtytoPickBase: Decimal;
        QtyAvailableBase: Decimal;
        IsHandled: Boolean;
        FirstBinCode: Code[20];
    begin
        GetLocation(LocationCode);
        if CurrLocation."Bin Mandatory" then begin
            if not CurrLocation."Directed Put-away and Pick" then begin
                QtyAvailableBase :=
                    CalcAvailableQty(ItemNo, VariantCode) -
                    CalcPickQtyAssigned(LocationCode, ItemNo, VariantCode, UnitofMeasureCode, '', TempWhseItemTrackingLine2);

                OnCreateTempLineOnAfterSetQtyAvailableBaseForDirectedPutAwayAndPick(ItemNo, VariantCode, LocationCode, UnitofMeasureCode, QtyAvailableBase, TempWhseItemTrackingLine2);

                if QtyAvailableBase > 0 then begin
                    if TotalQtytoPickBase > QtyAvailableBase then
                        TotalQtytoPickBase := QtyAvailableBase;
                    CalcBWPickBin(
                        LocationCode, ItemNo, VariantCode, UnitofMeasureCode, QtyPerUnitofMeasure, QtyRoundingPrecision, QtyRoundingPrecisionBase,
                        TotalQtytoPick, TotalQtytoPickBase, TempWhseItemTrackingLine2, WhseItemTrackingSetup);
                end;

                if (TotalQtytoPick > 0) and CurrLocation."Always Create Pick Line" then begin
                    TotalQtytoPickBase := UnitOfMeasureManagement.CalcBaseQty(TotalQtytoPick, QtyPerUnitofMeasure);
                    UpdateQuantitiesToPick(
                        TotalQtytoPickBase,
                        QtyPerUnitofMeasure, QtytoPick, QtytoPickBase,
                        QtyPerUnitofMeasure, QtytoPick, QtytoPickBase,
                        TotalQtytoPick, TotalQtytoPickBase);

                    CreateTempActivityLine(
                        LocationCode, '', UnitofMeasureCode, QtyPerUnitofMeasure, QtytoPick, QtytoPickBase, 1, 0, QtyRoundingPrecision, QtyRoundingPrecisionBase);
                    CreateTempActivityLine(
                        LocationCode, ToBinCode, UnitofMeasureCode, QtyPerUnitofMeasure, QtytoPick, QtytoPickBase, 2, 0, QtyRoundingPrecision, QtyRoundingPrecisionBase);
                end;
                exit;
            end;

            IsHandled := false;
            OnCreateTempLine2OnBeforeDirectedPutAwayAndPick(
                LocationCode, ItemNo, VariantCode, UnitofMeasureCode, FromBinCode, ToBinCode, QtyPerUnitofMeasure,
                TotalQtytoPick, TotalQtytoPickBase, TempWhseItemTrackingLine2, CreatePickParameters."Whse. Document", IsHandled,
                ReservationExists, ReservedForItemLedgEntry, TempWarehouseActivityLine, TempLineNo);
            if IsHandled then
                exit;

            if IsMovementWorksheet and (FromBinCode <> '') then begin
                InsertTempActivityLineFromMovWkshLine(
                    LocationCode, ItemNo, VariantCode, FromBinCode, QtyPerUnitofMeasure,
                    TotalQtytoPick, TempWhseItemTrackingLine2, TotalQtytoPickBase,
                    QtyRoundingPrecision, QtyRoundingPrecisionBase);
                exit;
            end;

            if (ReservationExists and ReservedForItemLedgEntry) or not ReservationExists then begin
                if CurrLocation."Use Cross-Docking" then
                    CalcPickBin(
                        LocationCode, ItemNo, VariantCode, UnitofMeasureCode, ToBinCode, QtyPerUnitofMeasure,
                        QtyRoundingPrecision, QtyRoundingPrecisionBase, TotalQtytoPick, TempWhseItemTrackingLine2, true,
                        TotalQtytoPickBase, QtyRoundingPrecision, QtyRoundingPrecisionBase);
                if TotalQtytoPickBase > 0 then
                    CalcPickBin(
                        LocationCode, ItemNo, VariantCode, UnitofMeasureCode, ToBinCode, QtyPerUnitofMeasure,
                        QtyRoundingPrecision, QtyRoundingPrecisionBase, TotalQtytoPick, TempWhseItemTrackingLine2, false,
                        TotalQtytoPickBase, QtyRoundingPrecision, QtyRoundingPrecisionBase);
            end;
            if (TotalQtytoPickBase > 0) and CurrLocation."Always Create Pick Line" then begin
                UpdateQuantitiesToPick(
                    TotalQtytoPickBase,
                    QtyPerUnitofMeasure, QtytoPick, QtytoPickBase,
                    QtyPerUnitofMeasure, QtytoPick, QtytoPickBase,
                    TotalQtytoPick, TotalQtytoPickBase);

                FirstBinCode := '';
                OnBeforeCreateTempActivityLineWithoutBinCode(FirstBinCode);
                CreateTempActivityLine(
                    LocationCode, FirstBinCode, UnitofMeasureCode, QtyPerUnitofMeasure, QtytoPick, QtytoPickBase, 1, 0, QtyRoundingPrecision, QtyRoundingPrecisionBase);
                CreateTempActivityLine(
                    LocationCode, ToBinCode, UnitofMeasureCode, QtyPerUnitofMeasure, QtytoPick, QtytoPickBase, 2, 0, QtyRoundingPrecision, QtyRoundingPrecisionBase);
            end;
            exit;
        end;

        QtyAvailableBase :=
            CalcAvailableQty(ItemNo, VariantCode) -
            CalcPickQtyAssigned(LocationCode, ItemNo, VariantCode, UnitofMeasureCode, '', TempWhseItemTrackingLine2);
        OnCreateTempLineOnBeforeUpdateQuantitesToPick(QtyAvailableBase, QtyPerUnitofMeasure, QtytoPick, QtytoPickBase, TotalQtytoPick, TotalQtytoPickBase);
        if QtyAvailableBase > 0 then begin
            UpdateQuantitiesToPick(
                QtyAvailableBase,
                QtyPerUnitofMeasure, QtytoPick, QtytoPickBase,
                QtyPerUnitofMeasure, QtytoPick, QtytoPickBase,
                TotalQtytoPick, TotalQtytoPickBase);

            CreateTempActivityLine(LocationCode, '', UnitofMeasureCode, QtyPerUnitofMeasure, QtytoPick, QtytoPickBase, 0, 0, QtyRoundingPrecision, QtyRoundingPrecisionBase);
        end;
    end;

    local procedure InsertTempActivityLineFromMovWkshLine(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; FromBinCode: Code[20]; QtyPerUnitofMeasure: Decimal; var TotalQtytoPick: Decimal; var TempWhseItemTrackingLine2: Record "Whse. Item Tracking Line" temporary; var TotalQtyToPickBase: Decimal; QtyRndPrec: Decimal; QtyRndPrecBase: Decimal)
    var
        FromBinContent: Record "Bin Content";
        FromItemUnitOfMeasure: Record "Item Unit of Measure";
        FromQtyToPick: Decimal;
        FromQtyToPickBase: Decimal;
        ToQtyToPick: Decimal;
        ToQtyToPickBase: Decimal;
        QtyAvailableBase: Decimal;
    begin
        QtyAvailableBase := TotalQtyToPickBase;

        if CurrWhseWorksheetLine."From Unit of Measure Code" <> CurrWhseWorksheetLine."Unit of Measure Code" then begin
            FromBinContent.Get(
              LocationCode, FromBinCode, ItemNo, VariantCode, CurrWhseWorksheetLine."From Unit of Measure Code");
            FromBinContent.SetFilterOnUnitOfMeasure();
            FromBinContent.CalcFields("Quantity (Base)", "Pick Quantity (Base)", "Negative Adjmt. Qty. (Base)");

            QtyAvailableBase :=
              FromBinContent."Quantity (Base)" - FromBinContent."Pick Quantity (Base)" -
              FromBinContent."Negative Adjmt. Qty. (Base)" -
              CalcPickQtyAssigned(
                LocationCode, ItemNo, VariantCode,
                CurrWhseWorksheetLine."From Unit of Measure Code",
                CurrWhseWorksheetLine."From Bin Code", TempWhseItemTrackingLine2);

            FromItemUnitOfMeasure.Get(ItemNo, FromBinContent."Unit of Measure Code");

            CurrBreakbulkNo := CurrBreakbulkNo + 1;
        end;

        UpdateQuantitiesToPick(
          QtyAvailableBase,
          CurrWhseWorksheetLine."Qty. per From Unit of Measure", FromQtyToPick, FromQtyToPickBase,
          QtyPerUnitofMeasure, ToQtyToPick, ToQtyToPickBase,
          TotalQtytoPick, TotalQtyToPickBase);
        CreateBreakBulkTempLines(
          CurrWhseWorksheetLine."Location Code",
          CurrWhseWorksheetLine."From Unit of Measure Code",
          CurrWhseWorksheetLine."Unit of Measure Code",
          FromBinCode,
          CurrWhseWorksheetLine."To Bin Code",
          CurrWhseWorksheetLine."Qty. per From Unit of Measure",
          CurrWhseWorksheetLine."Qty. per Unit of Measure",
          CurrBreakbulkNo,
          ToQtyToPick, ToQtyToPickBase, FromQtyToPick, FromQtyToPickBase, QtyRndPrec, QtyRndPrecBase);

        TotalQtyToPickBase := 0;
        TotalQtytoPick := 0;
    end;

    procedure CalcMaxQty(var QtytoHandle: Decimal; QtyOutstanding: Decimal; var QtytoHandleBase: Decimal; QtyOutstandingBase: Decimal; ActionType: Enum "Warehouse Action Type")
    var
        WarehouseActivityLine2: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine2.Copy(TempWarehouseActivityLine);
        TempWarehouseActivityLine.SetCurrentKey(
            "Whse. Document No.", "Whse. Document Type", "Activity Type", "Whse. Document Line No.");
        TempWarehouseActivityLine.SetRange("Whse. Document Type", TempWarehouseActivityLine."Whse. Document Type");
        TempWarehouseActivityLine.SetRange("Whse. Document No.", TempWarehouseActivityLine."Whse. Document No.");
        TempWarehouseActivityLine.SetRange("Activity Type", TempWarehouseActivityLine."Activity Type");
        TempWarehouseActivityLine.SetRange("Whse. Document Line No.", TempWarehouseActivityLine."Whse. Document Line No.");
        TempWarehouseActivityLine.SetRange("Source Type", TempWarehouseActivityLine."Source Type");
        TempWarehouseActivityLine.SetRange("Source Subtype", TempWarehouseActivityLine."Source Subtype");
        TempWarehouseActivityLine.SetRange("Source No.", TempWarehouseActivityLine."Source No.");
        TempWarehouseActivityLine.SetRange("Source Line No.", TempWarehouseActivityLine."Source Line No.");
        TempWarehouseActivityLine.SetRange("Source Subline No.", TempWarehouseActivityLine."Source Subline No.");
        TempWarehouseActivityLine.SetRange("Action Type", ActionType);
        TempWarehouseActivityLine.SetRange("Breakbulk No.", 0);
        OnCalcMaxQtyOnAfterTempWhseActivLineSetFilters(TempWarehouseActivityLine);
        if TempWarehouseActivityLine.Find('-') then
            if (TempWarehouseActivityLine."Action Type" <> TempWarehouseActivityLine."Action Type"::Take) or
               (WarehouseActivityLine2."Unit of Measure Code" = TempWarehouseActivityLine."Unit of Measure Code")
            then begin
                TempWarehouseActivityLine.CalcSums(Quantity);
                if QtyOutstanding < TempWarehouseActivityLine.Quantity + QtytoHandle then
                    QtytoHandle := QtyOutstanding - TempWarehouseActivityLine.Quantity;
                if QtytoHandle < 0 then
                    QtytoHandle := 0;
                TempWarehouseActivityLine.CalcSums("Qty. (Base)");
                if QtyOutstandingBase < TempWarehouseActivityLine."Qty. (Base)" + QtytoHandleBase then
                    QtytoHandleBase := QtyOutstandingBase - TempWarehouseActivityLine."Qty. (Base)";
                if QtytoHandleBase < 0 then
                    QtytoHandleBase := 0;
            end;
        TempWarehouseActivityLine.Copy(WarehouseActivityLine2);
    end;

    local procedure CalcMaxQtyAvailToPickInWhseForDirectedPutAwayPick(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]): Decimal
    var
        DummyWhseItemTrackingSetup: Record "Item Tracking Setup";
    begin
        exit(CalcMaxQtyAvailToPickInWhseForDirectedPutAwayPick(LocationCode, ItemNo, VariantCode, DummyWhseItemTrackingSetup));
    end;

    local procedure CalcMaxQtyAvailToPickInWhseForDirectedPutAwayPick(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; WhseItemTrackingSetup: Record "Item Tracking Setup"): Decimal
    var
        BinTypeFilter: Option ExcludeReceive,ExcludeShip,OnlyPickBins;
    begin
        if CalledFromMoveWksh then
            exit(CalcMaxQtyAvailToPickInWhseForDirectedPutAwayPickWithBinTypeFilter(LocationCode, ItemNo, VariantCode, WhseItemTrackingSetup, BinTypeFilter::ExcludeReceive))
        else
            exit(CalcMaxQtyAvailToPickInWhseForDirectedPutAwayPickWithBinTypeFilter(LocationCode, ItemNo, VariantCode, WhseItemTrackingSetup, BinTypeFilter::OnlyPickBins));
    end;

    local procedure CalcMaxQtyAvailToPickInWhseForDirectedPutAwayPickWithBinTypeFilter(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; WhseItemTrackingSetup: Record "Item Tracking Setup"; BinTypeFilter: Option ExcludeReceive,ExcludeShip,OnlyPickBins): Decimal
    var
        BinContent: Record "Bin Content";
        CalcPickableQtyFromWhseEntry: Query CalcPickableQtyFromWhseEntry;
        CalcOutstandQtyOnWhseActLine: Query CalcOutstandQtyOnWhseActLine;
        QtyInBinNotBlockedNotDedicated: Decimal;
        QtyAssignedInWhseActLinesNotBlockedNotDedicated: Decimal;
        QtyWithBlockedItemTracking: Decimal;
        QtyInWhse: Decimal;
        MaxPickableQty: Decimal;
        QtyInBinNotBlockedNotDedicatedWithoutItemTrackingFilter: Decimal;
    begin
        GetLocation(LocationCode);
        if not CurrLocation."Directed Put-away and Pick" then
            exit;

        // Filters to exclude or include bin types depending on the BinTypeFilter parameter
        case BinTypeFilter of
            BinTypeFilter::ExcludeReceive:
                begin
                    CalcPickableQtyFromWhseEntry.SetFilter(Bin_Type_Code, '<>%1', GetBinTypeFilter(0));
                    CalcOutstandQtyOnWhseActLine.SetFilter(Bin_Type_Code, '<>%1', GetBinTypeFilter(0));
                end;
            BinTypeFilter::ExcludeShip:
                begin
                    CalcPickableQtyFromWhseEntry.SetFilter(Bin_Type_Code, '<>%1', GetBinTypeFilter(1));
                    CalcOutstandQtyOnWhseActLine.SetFilter(Bin_Type_Code, '<>%1', GetBinTypeFilter(1));
                end;
            BinTypeFilter::OnlyPickBins:
                begin
                    CalcPickableQtyFromWhseEntry.SetFilter(Bin_Type_Code, GetBinTypeFilter(3));
                    CalcOutstandQtyOnWhseActLine.SetFilter(Bin_Type_Code, GetBinTypeFilter(3));
                end;
        end;
        QtyInBinNotBlockedNotDedicatedWithoutItemTrackingFilter := GetQtyInBinNotBlockedNotDedicatedWithoutItemTrackingFilter(LocationCode, ItemNo, VariantCode);

        // Summing up Warehouse Entry
        CalcPickableQtyFromWhseEntry.SetRange(Location_Code, LocationCode);
        CalcPickableQtyFromWhseEntry.SetRange(Item_No_, ItemNo);
        CalcPickableQtyFromWhseEntry.SetRange(Variant_Code, VariantCode);
        CalcPickableQtyFromWhseEntry.SetTrackingFilterFromItemTrackingSetupIfNotBlankIfRequired(WhseItemTrackingSetup);
        CalcPickableQtyFromWhseEntry.Open();
        if CalcPickableQtyFromWhseEntry.Read() then
            QtyInBinNotBlockedNotDedicated := CalcPickableQtyFromWhseEntry.TotalPickableQtyBase;
        CalcPickableQtyFromWhseEntry.Close();

        // Summing up Warehouse Activity Lines to include active outstanding quantity on the pick lines
        CalcOutstandQtyOnWhseActLine.SetRange(Action_Type, Enum::"Warehouse Action Type"::" ", Enum::"Warehouse Action Type"::Take);
        CalcOutstandQtyOnWhseActLine.SetRange(Activity_Type, Enum::"Warehouse Activity Type"::Pick);
        CalcOutstandQtyOnWhseActLine.SetRange(Location_Code, LocationCode);
        CalcOutstandQtyOnWhseActLine.SetRange(Item_No_, ItemNo);
        CalcOutstandQtyOnWhseActLine.SetRange(Variant_Code, VariantCode);
        CalcOutstandQtyOnWhseActLine.SetTrackingFilterFromItemTrackingSetupIfNotBlankIfRequired(WhseItemTrackingSetup);

        CalcOutstandQtyOnWhseActLine.Open();
        if CalcOutstandQtyOnWhseActLine.Read() then
            QtyAssignedInWhseActLinesNotBlockedNotDedicated := CalcOutstandQtyOnWhseActLine.TotalWhseActLineQtyOutstandingBase;
        CalcOutstandQtyOnWhseActLine.Close();

        // If item tracking required and bins are not blocked for outbound, then remove the tracked quantity that is blocked.
        if WhseItemTrackingSetup.TrackingRequired() then begin
            BinContent.SetCurrentKey("Location Code", "Item No.", "Variant Code");
            BinContent.SetRange("Location Code", LocationCode);
            BinContent.SetRange("Item No.", ItemNo);
            BinContent.SetRange("Variant Code", VariantCode);
            BinContent.SetRange(Dedicated, false);
            BinContent.SetRange("Block Movement", BinContent."Block Movement"::" ", BinContent."Block Movement"::Inbound);
            BinContent.SetTrackingFilterFromItemTrackingSetupIfNotBlankIfRequired(WhseItemTrackingSetup);
            BinContent.ReadIsolation := IsolationLevel::ReadUncommitted;
            if BinContent.FindSet() then
                repeat
                    QtyWithBlockedItemTracking += BinContent.CalcQtyWithBlockedItemTracking();
                until BinContent.Next() = 0;
        end;

        MaxPickableQty := Maximum(0, QtyInBinNotBlockedNotDedicated - QtyWithBlockedItemTracking - QtyAssignedInWhseActLinesNotBlockedNotDedicated);

        if CalledFromMoveWksh then begin
            UpdateCalculationSummaryQuantitiesForMaxPickableQtyInWhse(0, QtyInBinNotBlockedNotDedicated, QtyWithBlockedItemTracking, QtyAssignedInWhseActLinesNotBlockedNotDedicated, BinTypeFilter, QtyInBinNotBlockedNotDedicatedWithoutItemTrackingFilter);
            exit(MaxPickableQty);
        end
        else begin
            // QtyInBinNotBlockedNotDedicated might not be in the inventory yet when using Adjustment bins, so we need to take the minimum of QtyInBinNotBlockedNotDedicated and QtyInWhse (which includes adjustment bins).
            QtyInWhse := SumWhseEntries(ItemNo, LocationCode, VariantCode, WhseItemTrackingSetup, '', '', false);
            UpdateCalculationSummaryQuantitiesForMaxPickableQtyInWhse(QtyInWhse, QtyInBinNotBlockedNotDedicated, QtyWithBlockedItemTracking, QtyAssignedInWhseActLinesNotBlockedNotDedicated, BinTypeFilter, QtyInBinNotBlockedNotDedicatedWithoutItemTrackingFilter);
            exit(Minimum(QtyInWhse, MaxPickableQty));
        end;
    end;

    local procedure CalcBWPickBin(
        LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; UnitofMeasureCode: Code[10]; QtyPerUnitofMeasure: Decimal; QtyRoundingPrecision: Decimal; QtyRoundingPrecisionBase: Decimal;
        var TotalQtyToPick: Decimal; var TotalQtytoPickBase: Decimal; var TempWhseItemTrackingLine2: Record "Whse. Item Tracking Line" temporary; WhseItemTrackingSetup: Record "Item Tracking Setup")
    var
        WhseSource2: Option;
        ToBinCode: Code[20];
        IsHandled: Boolean;
    begin
        // Basic warehousing
        IsHandled := false;
        OnBeforeCalcBWPickBin(TotalQtyToPick, TotalQtytoPickBase, TempWhseItemTrackingLine2, TempWarehouseActivityLine, WhseItemTrkgExists, IsHandled);
        if IsHandled then
            exit;

        if ((CreatePickParameters."Whse. Document" = CreatePickParameters."Whse. Document"::Shipment) and CurrWarehouseShipmentLine."Assemble to Order")
            or ((CreatePickParameters."Whse. Document" = CreatePickParameters."Whse. Document"::Job) and CurrJobPlanningLine."Assemble to Order") then
            WhseSource2 := CreatePickParameters."Whse. Document"::Assembly
        else
            WhseSource2 := CreatePickParameters."Whse. Document";

        if TotalQtytoPickBase > 0 then
            case WhseSource2 of
                CreatePickParameters."Whse. Document"::"Pick Worksheet":
                    ToBinCode := CurrWhseWorksheetLine."To Bin Code";
                CreatePickParameters."Whse. Document"::Shipment:
                    ToBinCode := CurrWarehouseShipmentLine."Bin Code";
                CreatePickParameters."Whse. Document"::Job:
                    ToBinCode := CurrJobPlanningLine."Bin Code";
                else
                    OnFindToBinCodeForCustomWhseSource(
                        CustomWhseSourceLine, ToBinCode, WhseSource2,
                        CurrSourceType, CurrSourceSubType, CurrSourceNo, CurrSourceLineNo, CurrSourceSubLineNo);
            end;

        RunFindBWPickBinLoop(
            LocationCode, ItemNo, VariantCode,
            ToBinCode, UnitofMeasureCode, QtyPerUnitofMeasure, QtyRoundingPrecision, QtyRoundingPrecisionBase,
            TotalQtyToPick, TotalQtytoPickBase, TempWhseItemTrackingLine2, WhseItemTrackingSetup);
    end;

    local procedure RunFindBWPickBinLoop(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; ToBinCode: Code[20];
        UnitofMeasureCode: Code[10]; QtyPerUnitofMeasure: Decimal; QtyRndPrec: Decimal; QtyRndPrecBase: Decimal; var TotalQtyToPick: Decimal; var TotalQtyToPickBase: Decimal;
        var TempWhseItemTrackingLine2: Record "Whse. Item Tracking Line" temporary; WhseItemTrackingSetup: Record "Item Tracking Setup")
    var
        DefaultBin: Boolean;
        CrossDockBin: Boolean;
        IsHandled: Boolean;
        ShouldExit: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunFindBWPickBinLoop(LocationCode, ItemNo, VariantCode, ToBinCode, UnitofMeasureCode, QtyPerUnitofMeasure,
            TotalQtyToPick, TotalQtytoPickBase, TempWhseItemTrackingLine2, WhseItemTrackingSetup, IsHandled);
        if IsHandled then
            exit;

        GetLocation(LocationCode);

        if (CurrSourceType = Database::"Job Planning Line") and (CurrLocation.Code <> '') then begin
            FeatureTelemetry.LogUsage('0000KT7', ProdAsmJobWhseHandlingTelemetryCategoryTok, ProdAsmJobWhseHandlingTelemetryTok);
            if not (CurrLocation."Job Consump. Whse. Handling" in [CurrLocation."Job Consump. Whse. Handling"::"Warehouse Pick (mandatory)", CurrLocation."Job Consump. Whse. Handling"::"Warehouse Pick (optional)"]) then
                exit;
        end;

        ShouldExit := false;
        OnRunFindBWPickBinLoopOnAfterCheckWhseHandling(CurrSourceType, CurrLocation, ShouldExit);
        if ShouldExit then
            exit;

        // This is what creates the lines
        case CurrLocation."Pick Bin Policy" of
            CurrLocation."Pick Bin Policy"::"Default Bin":
                begin
                    FeatureTelemetry.LogUsage('0000KP9', BinPolicyTelemetryCategoryTok, DefaultBinPickPolicyTelemetryTok);
                    for CrossDockBin := true downto false do
                        for DefaultBin := true downto false do
                            if TotalQtytoPickBase > 0 then
                                FindBWPickBin(
                                  LocationCode, ItemNo, VariantCode,
                                  ToBinCode, UnitofMeasureCode, QtyPerUnitofMeasure, QtyRndPrec, QtyRndPrecBase, DefaultBin, CrossDockBin,
                                  TotalQtyToPick, TotalQtytoPickBase, TempWhseItemTrackingLine2, WhseItemTrackingSetup);
                end;
            CurrLocation."Pick Bin Policy"::"Bin Ranking":
                begin
                    FeatureTelemetry.LogUsage('0000KPA', BinPolicyTelemetryCategoryTok, RankingBinPickPolicyTelemetryTok);
                    for CrossDockBin := true downto false do
                        if TotalQtytoPickBase > 0 then
                            FindBWPickBin(
                              LocationCode, ItemNo, VariantCode,
                              ToBinCode, UnitofMeasureCode, QtyPerUnitofMeasure, QtyRndPrec, QtyRndPrecBase, DefaultBin, CrossDockBin,
                              TotalQtyToPick, TotalQtytoPickBase, TempWhseItemTrackingLine2, WhseItemTrackingSetup, false);
                end;
            else
                OnCreatePutawayForPostedWhseReceiptLine(LocationCode, ItemNo, VariantCode, UnitofMeasureCode, QtyPerUnitofMeasure, QtyRndPrec, QtyRndPrecBase, TotalQtyToPick, TotalQtytoPickBase);
        end;
    end;

    local procedure FindBWPickBin(
        LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; ToBinCode: Code[20]; UnitofMeasureCode: Code[10]; QtyPerUnitofMeasure: Decimal;
        QtyRoundingPrecision: Decimal; QtyRoundingPrecisionBase: Decimal; DefaultBin: Boolean; CrossDockBin: Boolean; var TotalQtyToPick: Decimal; var TotalQtyToPickBase: Decimal;
        var TempWhseItemTrackingLine2: Record "Whse. Item Tracking Line" temporary; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        FindBWPickBin(
            LocationCode, ItemNo, VariantCode, ToBinCode, UnitofMeasureCode, QtyPerUnitofMeasure, QtyRoundingPrecision, QtyRoundingPrecisionBase,
            DefaultBin, CrossDockBin, TotalQtyToPick, TotalQtyToPickBase, TempWhseItemTrackingLine2, WhseItemTrackingSetup, true);
    end;

    local procedure FindBWPickBin(
        LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; ToBinCode: Code[20]; UnitofMeasureCode: Code[10]; QtyPerUnitofMeasure: Decimal;
        QtyRoundingPrecision: Decimal; QtyRoundingPrecisionBase: Decimal; DefaultBin: Boolean; CrossDockBin: Boolean; var TotalQtyToPick: Decimal; var TotalQtyToPickBase: Decimal;
        var TempWhseItemTrackingLine2: Record "Whse. Item Tracking Line" temporary; WhseItemTrackingSetup: Record "Item Tracking Setup"; UserDefaultBin: Boolean)
    var
        FromBinContent: Record "Bin Content";
        QtyAvailableBase: Decimal;
        QtyToPickBase: Decimal;
        QtytoPick: Decimal;
        BinCodeFilterText: Text[250];
        IsSetCurrentKeyHandled: Boolean;
        IsHandled: Boolean;
        EndLoop: Boolean;
        SkipUpdateQuantitiesToPick: Boolean;
    begin
        IsSetCurrentKeyHandled := false;
        OnBeforeFindBWPickBin(FromBinContent, IsSetCurrentKeyHandled);
        if not IsSetCurrentKeyHandled then
            // Bins are always sorted by 'Bin Ranking', its the filtering on 'Cross-Dock Bin' and 'Default' that includes or excludes a Bin
            if CrossDockBin or (CurrLocation."Pick Bin Policy" = CurrLocation."Pick Bin Policy"::"Bin Ranking") then begin
                FromBinContent.SetCurrentKey(
                  "Location Code", "Item No.", "Variant Code", "Cross-Dock Bin", "Qty. per Unit of Measure", "Bin Ranking");
                FromBinContent.Ascending(false);
            end else
                FromBinContent.SetCurrentKey(Default, "Location Code", "Item No.", "Variant Code", "Bin Code");

        if UserDefaultBin then
            FromBinContent.SetRange(Default, DefaultBin);
        FromBinContent.SetRange("Cross-Dock Bin", CrossDockBin);
        FromBinContent.SetRange("Location Code", LocationCode);
        FromBinContent.SetRange("Item No.", ItemNo);
        FromBinContent.SetRange("Variant Code", VariantCode);
        GetLocation(LocationCode);
        IsHandled := false;
        OnBeforeSetBinCodeFilter(
            BinCodeFilterText, LocationCode, ItemNo, VariantCode, ToBinCode, IsHandled,
            CurrSourceType, CurrSourceSubType, CurrSourceNo, CurrSourceLineNo, CurrSourceSubLineNo);
        if not IsHandled then begin
            if CurrLocation."Require Pick" and (CurrLocation."Shipment Bin Code" <> '') then
                AddToFilterText(BinCodeFilterText, '&', '<>', CurrLocation."Shipment Bin Code");
            if CurrLocation."Require Put-away" and (CurrLocation."Receipt Bin Code" <> '') then
                AddToFilterText(BinCodeFilterText, '&', '<>', CurrLocation."Receipt Bin Code");
            if ToBinCode <> '' then
                AddToFilterText(BinCodeFilterText, '&', '<>', ToBinCode);

            OnFindBWPickBinOnBeforeApplyBinCodeFilter(BinCodeFilterText, CurrLocation);
            if BinCodeFilterText <> '' then
                FromBinContent.SetFilter("Bin Code", BinCodeFilterText);
            if WhseItemTrkgExists then begin
                WhseItemTrackingSetup.CopyTrackingFromWhseItemTrackingLine(TempWhseItemTrackingLine2);
                FromBinContent.SetTrackingFilterFromItemTrackingSetupIfRequiredWithBlank(WhseItemTrackingSetup);
            end;
        end;

        IsHandled := false;
        OnFindBWPickBinOnBeforeFromBinContentFindSet(
            FromBinContent, CurrSourceType, TotalQtyPickedBase, TotalQtyToPickBase, IsHandled,
            CurrSourceSubType, CurrSourceNo, CurrSourceLineNo, CurrSourceSubLineNo, LocationCode, ItemNo, VariantCode, ToBinCode);
        if not IsHandled then
            if FromBinContent.FindSet() then // Loop that creates activity lines
                repeat
                    QtyAvailableBase :=
                        FromBinContent.CalcQtyAvailToPick(0) -
                        CalcPickQtyAssigned(LocationCode, ItemNo, VariantCode, '', FromBinContent."Bin Code", TempWhseItemTrackingLine2);

                    OnCalcAvailQtyOnFindBWPickBin(
                        ItemNo, VariantCode,
                        WhseItemTrackingSetup."Serial No. Required", WhseItemTrackingSetup."Lot No. Required", WhseItemTrkgExists,
                        TempWhseItemTrackingLine2."Serial No.", TempWhseItemTrackingLine2."Lot No.", FromBinContent."Location Code", FromBinContent."Bin Code",
                        CurrSourceType, CurrSourceSubType, CurrSourceNo, CurrSourceLineNo, CurrSourceSubLineNo, TotalQtyToPickBase, QtyAvailableBase);

                    if QtyAvailableBase > 0 then begin
                        IsHandled := false;
                        OnFindBWPickBinOnBeforeSetQtyAvailableBaseForSerialNo(FromBinContent, QtyAvailableBase, IsHandled);
                        if not IsHandled then
                            if WhseItemTrackingSetup."Serial No. Required" then
                                QtyAvailableBase := 1;

                        SkipUpdateQuantitiesToPick := false;
                        OnFindBWPickBinOnBeforeUpdateQuantitiesToPick(SkipUpdateQuantitiesToPick, FromBinContent, QtyAvailableBase,
                            QtyPerUnitofMeasure, QtytoPick, QtyToPickBase,
                            TotalQtyToPick, TotalQtyToPickBase);
                        if not SkipUpdateQuantitiesToPick then
                            UpdateQuantitiesToPick(
                                QtyAvailableBase,
                                QtyPerUnitofMeasure, QtytoPick, QtyToPickBase,
                                QtyPerUnitofMeasure, QtytoPick, QtyToPickBase,
                                TotalQtyToPick, TotalQtyToPickBase);

                        CreateTempActivityLine(
                            LocationCode, FromBinContent."Bin Code", UnitofMeasureCode, QtyPerUnitofMeasure, QtytoPick, QtyToPickBase, 1, 0, QtyRoundingPrecision, QtyRoundingPrecisionBase);
                        CreateTempActivityLine(
                            LocationCode, ToBinCode, UnitofMeasureCode, QtyPerUnitofMeasure, QtytoPick, QtyToPickBase, 2, 0, QtyRoundingPrecision, QtyRoundingPrecisionBase);
                    end;
                    EndLoop := false;
                    IsHandled := false;
                    OnFindBWPickBinOnBeforeEndLoop(FromBinContent, TotalQtyToPickBase, EndLoop, IsHandled, QtytoPick, QtyToPickBase);
                    if not IsHandled then
                        EndLoop := (FromBinContent.Next() = 0) or (TotalQtyToPickBase = 0);
                until EndLoop;
    end;

    local procedure CalcPickBin(
        LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; UnitofMeasureCode: Code[10]; ToBinCode: Code[20]; QtyPerUnitofMeasure: Decimal;
        QtyRoundingPrecision: Decimal; QtyRoundingPrecisionBase: Decimal; var TotalQtytoPick: Decimal; var TempWhseItemTrackingLine2: Record "Whse. Item Tracking Line" temporary;
        IsCrossDock: Boolean; var TotalQtytoPickBase: Decimal; QtyRndPrec: Decimal; QtyRndPrecBase: Decimal)
    var
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        IsHandled: Boolean;
    begin
        // Directed put-away and pick
        IsHandled := false;
        OnBeforeCalcPickBin(
            TempWarehouseActivityLine, TotalQtytoPick, TotalQtytoPickBase, TempWhseItemTrackingLine2,
            IsCrossDock, WhseItemTrkgExists, CreatePickParameters."Whse. Document",
            LocationCode, ItemNo, VariantCode, UnitofMeasureCode, ToBinCode, QtyPerUnitofMeasure, IsHandled);
        if IsHandled then
            exit;

        if TotalQtytoPickBase > 0 then begin
            ItemTrackingManagement.GetWhseItemTrkgSetup(ItemNo, WhseItemTrackingSetup);
            OnCalcPickBinOnAfterGetWhseItemTrkgSetup(WhseItemTrackingSetup, LocationCode);
            FindPickBin(
                LocationCode, ItemNo, VariantCode, UnitofMeasureCode,
                ToBinCode, QtyPerUnitofMeasure, QtyRoundingPrecision, QtyRoundingPrecisionBase, TempWarehouseActivityLine, TotalQtytoPick, TempWhseItemTrackingLine2, IsCrossDock, TotalQtytoPickBase, WhseItemTrackingSetup);
            if (TotalQtytoPickBase > 0) and CurrLocation."Allow Breakbulk" then begin
                FindBreakBulkBin(
                    LocationCode, ItemNo, VariantCode, UnitofMeasureCode, ToBinCode,
                    QtyPerUnitofMeasure, TempWarehouseActivityLine, TotalQtytoPick, TempWhseItemTrackingLine2, IsCrossDock,
                    TotalQtytoPickBase, WhseItemTrackingSetup, QtyRndPrec, QtyRndPrecBase);
                if TotalQtytoPickBase > 0 then
                    FindSmallerUOMBin(
                        LocationCode, ItemNo, VariantCode, UnitofMeasureCode, ToBinCode,
                        QtyPerUnitofMeasure, TotalQtytoPick, TempWhseItemTrackingLine2, IsCrossDock, TotalQtytoPickBase, WhseItemTrackingSetup, QtyRndPrec, QtyRndPrecBase);
            end
            else
                if not CurrLocation."Allow Breakbulk" and (TotalQtytoPickBase > 0) and not IsCrossDock then
                    if CanSaveSummary() and not CheckCanNotBeHandledReasonAlreadyAdded(CheckAllowBreakBulkTxt) then
                        if CheckInDifferentUoM(ItemNo, VariantCode, LocationCode, UnitofMeasureCode) then
                            if CheckItemAvailableInAnyUoM(ItemNo, VariantCode, LocationCode, TotalQtytoPickBase, WhseItemTrackingSetup) then
                                EnqueueCannotBeHandledReason(CheckAllowBreakBulkTxt);
        end;
    end;

    local procedure CheckInDifferentUoM(ItemNo: Code[20]; VariantCode: Code[20]; LocationCode: Code[10]; UnitofMeasureCode: Code[10]): Boolean
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
        PutAwayUnitOfMeasureCode: Code[10];
    begin
        GetItem(ItemNo);
        PutAwayUnitOfMeasureCode := CurrItem."Base Unit of Measure";
        if CurrItem."Put-away Unit of Measure Code" <> '' then
            PutAwayUnitOfMeasureCode := CurrItem."Put-away Unit of Measure Code";

        StockkeepingUnit.SetLoadFields("Put-away Unit of Measure Code");
        StockkeepingUnit.ReadIsolation := IsolationLevel::ReadUncommitted;
        StockkeepingUnit.SetRange("Location Code", LocationCode);
        StockkeepingUnit.SetRange("Item No.", ItemNo);
        StockkeepingUnit.SetFilter("Variant Code", '%1|%2', '', VariantCode);
        if StockkeepingUnit.FindLast() then
            if StockkeepingUnit."Put-away Unit of Measure Code" <> '' then
                PutAwayUnitOfMeasureCode := StockkeepingUnit."Put-away Unit of Measure Code";

        exit(PutAwayUnitOfMeasureCode <> UnitofMeasureCode);
    end;

    local procedure CheckItemAvailableInAnyUoM(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; TotalQtytoPickBase: Decimal; WhseItemTrackingSetup: Record "Item Tracking Setup"): Boolean
    var
        BinContent: Record "Bin Content";
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
    begin
        BinContent.SetRange("Location Code", LocationCode);
        BinContent.SetRange("Item No.", ItemNo);
        BinContent.SetRange("Variant Code", VariantCode);
        if BinContent.IsEmpty() then
            exit;

        WhseItemTrackingSetup.CopyTrackingFromWhseItemTrackingLine(TempWhseItemTrackingLine);
        exit(CalcTotalAvailQtyToPick(
                LocationCode, ItemNo, VariantCode, WhseItemTrackingLine,
                CurrSourceType, CurrSourceSubType, CurrSourceNo, CurrSourceLineNo,
                CurrSourceSubLineNo, TotalQtytoPickBase, false) > 0);
    end;

    local procedure BinContentBlocked(LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; UnitOfMeasureCode: Code[10]): Boolean
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.Get(LocationCode, BinCode, ItemNo, VariantCode, UnitOfMeasureCode);
        if BinContent."Block Movement" in [BinContent."Block Movement"::Outbound, BinContent."Block Movement"::All] then
            exit(true);
    end;

    local procedure BreakBulkPlacingExists(var TempBinContent: Record "Bin Content" temporary; ItemNo: Code[20]; LocationCode: Code[10]; UOMCode: Code[10]; VariantCode: Code[10]; IsCrossDock: Boolean; WhseItemTrackingSetup: Record "Item Tracking Setup"): Boolean
    var
        BinContent2: Record "Bin Content";
        WarehouseActivityLine2: Record "Warehouse Activity Line";
    begin
        TempBinContent.Reset();
        TempBinContent.DeleteAll();
        BinContent2.SetCurrentKey(BinContent2."Location Code", BinContent2."Item No.", BinContent2."Variant Code", BinContent2."Cross-Dock Bin", BinContent2."Qty. per Unit of Measure", BinContent2."Bin Ranking");
        BinContent2.SetRange(BinContent2."Location Code", LocationCode);
        BinContent2.SetRange(BinContent2."Item No.", ItemNo);
        BinContent2.SetRange(BinContent2."Variant Code", VariantCode);
        BinContent2.SetRange(BinContent2."Cross-Dock Bin", IsCrossDock);
        OnBreakBulkPlacingExistsOnAfterBinContent2SetFilters(BinContent2);
        if IsMovementWorksheet then
            BinContent2.SetFilter(BinContent2."Bin Ranking", '<%1', CurrBin."Bin Ranking");
        if WhseItemTrkgExists then begin
            WhseItemTrackingSetup.CopyTrackingFromWhseItemTrackingLine(TempWhseItemTrackingLine);
            BinContent2.SetTrackingFilterFromItemTrackingSetupIfRequiredWithBlank(WhseItemTrackingSetup);
        end;
        BinContent2.Ascending(false);

        WarehouseActivityLine2.Copy(TempWarehouseActivityLine);
        TempWarehouseActivityLine.SetRange("Location Code", LocationCode);
        TempWarehouseActivityLine.SetRange("Item No.", ItemNo);
        TempWarehouseActivityLine.SetRange("Variant Code", VariantCode);
        TempWarehouseActivityLine.SetRange("Unit of Measure Code", UOMCode);
        TempWarehouseActivityLine.SetRange("Action Type", "Warehouse Action Type"::Place);
        TempWarehouseActivityLine.SetFilter("Breakbulk No.", '<>0');
        TempWarehouseActivityLine.SetRange("Bin Code");
        if WhseItemTrkgExists then begin
            WhseItemTrackingSetup.CopyTrackingFromWhseItemTrackingLine(TempWhseItemTrackingLine);
            TempWarehouseActivityLine.SetTrackingFilterFromWhseItemTrackingSetup(WhseItemTrackingSetup);
        end;
        if TempWarehouseActivityLine.FindFirst() then
            repeat
                BinContent2.SetRange("Bin Code", TempWarehouseActivityLine."Bin Code");
                BinContent2.SetRange("Unit of Measure Code", UOMCode);
                if BinContent2.IsEmpty() then begin
                    BinContent2.SetRange("Unit of Measure Code");
                    if BinContent2.FindFirst() then begin
                        TempBinContent := BinContent2;
                        TempBinContent.Validate("Unit of Measure Code", UOMCode);
                        if TempBinContent.Insert() then;
                    end;
                end;
            until TempWarehouseActivityLine.Next() = 0;
        TempWarehouseActivityLine.Copy(WarehouseActivityLine2);
        exit(not TempBinContent.IsEmpty);
    end;

    local procedure FindPickBin(
        LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; UnitofMeasureCode: Code[10]; ToBinCode: Code[20]; ToQtyPerUOM: Decimal;
        QtyRndPrec: Decimal; QtyRndPrecBase: Decimal; var TempWarehouseActivityLine2: Record "Warehouse Activity Line" temporary; var TotalQtytoPick: Decimal; var TempWhseItemTrackingLine2: Record "Whse. Item Tracking Line" temporary;
        IsCrossDock: Boolean; var TotalQtytoPickBase: Decimal; WhseItemTrackingSetup: Record "Item Tracking Setup")
    var
        FromBinContent: Record "Bin Content";
        FromQtyToPick: Decimal;
        FromQtyToPickBase: Decimal;
        ToQtyToPick: Decimal;
        ToQtyToPickBase: Decimal;
        TotalAvailQtyToPickBase: Decimal;
        AvailableQtyBase: Decimal;
        BinIsForPick: Boolean;
        BinIsForReplenishment: Boolean;
        IsHandled: Boolean;
    begin
        // Directed put-away and pick
        GetCurrBin(LocationCode, ToBinCode);
        GetLocation(LocationCode);

        WhseItemTrackingSetup.CopyTrackingFromWhseItemTrackingLine(TempWhseItemTrackingLine2);

        IsHandled := false;
        OnBeforeFindPickBin(
            LocationCode, ItemNo, VariantCode, UnitofMeasureCode, ToBinCode, QtyRndPrec, QtyRndPrecBase,
            TempWarehouseActivityLine2, TotalQtytoPick, TempWhseItemTrackingLine2, IsCrossDock, TotalQtytoPickBase,
            WhseItemTrackingSetup, IsMovementWorksheet, WhseItemTrkgExists, IsHandled);
        if IsHandled then
            exit;

        if GetBinContent(
            FromBinContent, ItemNo, VariantCode, UnitofMeasureCode, LocationCode, ToBinCode, IsCrossDock,
            IsMovementWorksheet, WhseItemTrkgExists, false, false, WhseItemTrackingSetup, TotalQtytoPick, TotalQtytoPickBase)
        then begin
            TotalAvailQtyToPickBase :=
                CalcTotalAvailQtyToPick(
                    LocationCode, ItemNo, VariantCode, TempWhseItemTrackingLine2,
                    CurrSourceType, CurrSourceSubType, CurrSourceNo, CurrSourceLineNo, CurrSourceSubLineNo, TotalQtytoPickBase, false);

            if TotalAvailQtyToPickBase < 0 then
                TotalAvailQtyToPickBase := 0;

            if CurrLocation."Directed Put-away and Pick" and not CurrLocation."Always Create Pick Line" then
                if TotalAvailQtyToPickBase < TotalQtytoPickBase then begin
                    TotalQtytoPickBase := TotalAvailQtyToPickBase;
                    TotalQtytoPick := UnitOfMeasureManagement.CalcQtyFromBase(TotalQtyToPickBase, ToQtyPerUOM);
                end;

            OnFindPickBinOnBeforeStartFromBinContentLoop(TempWhseItemTrackingLine2, TotalAvailQtyToPickBase);
            repeat
                BinIsForPick := UseForPick(FromBinContent) and (not IsMovementWorksheet);
                BinIsForReplenishment := UseForReplenishment(FromBinContent) and IsMovementWorksheet;
                if FromBinContent."Bin Code" <> ToBinCode then
                    CalcBinAvailQtyToPick(AvailableQtyBase, FromBinContent, TempWarehouseActivityLine2, WhseItemTrackingSetup);
                if BinIsForPick or BinIsForReplenishment then begin
                    if TotalAvailQtyToPickBase < AvailableQtyBase then
                        AvailableQtyBase := TotalAvailQtyToPickBase;

                    if TotalQtytoPickBase < AvailableQtyBase then
                        AvailableQtyBase := TotalQtytoPickBase;

                    OnCalcAvailQtyOnFindPickBin2(
                        ItemNo, VariantCode,
                        WhseItemTrackingSetup."Serial No. Required", WhseItemTrackingSetup."Lot No. Required", WhseItemTrkgExists,
                        TempWhseItemTrackingLine2."Lot No.", TempWhseItemTrackingLine2."Serial No.",
                        FromBinContent."Location Code", FromBinContent."Bin Code",
                        CurrSourceType, CurrSourceSubType, CurrSourceNo, CurrSourceLineNo, CurrSourceSubLineNo, TotalQtytoPickBase, AvailableQtyBase);

                    if AvailableQtyBase > 0 then begin
                        ToQtyToPickBase := CalcQtyToPickBase(FromBinContent, TempWarehouseActivityLine);
                        if AvailableQtyBase > ToQtyToPickBase then
                            AvailableQtyBase := ToQtyToPickBase;

                        IsHandled := false;
                        OnFindPickBinOnBeforeUpdateQuantitesAndCreateActivityLines(FromBinContent, TempWarehouseActivityLine, ToQtyToPick, ToQtyToPickBase, AvailableQtyBase, IsHandled);
                        if not IsHandled then begin
                            UpdateQuantitiesToPick(
                                AvailableQtyBase,
                                FromBinContent."Qty. per Unit of Measure", FromQtyToPick, FromQtyToPickBase,
                                ToQtyPerUOM, ToQtyToPick, ToQtyToPickBase,
                                TotalQtytoPick, TotalQtytoPickBase);

                            CreateTempActivityLine(
                                LocationCode, FromBinContent."Bin Code", FromBinContent."Unit of Measure Code", FromBinContent."Qty. per Unit of Measure",
                                FromQtyToPick, FromQtyToPickBase, 1, 0, QtyRndPrec, QtyRndPrecBase);
                            CreateTempActivityLine(
                                LocationCode, ToBinCode, UnitofMeasureCode, ToQtyPerUOM,
                                ToQtyToPick, ToQtyToPickBase, 2, 0, QtyRndPrec, QtyRndPrecBase);
                        end;

                        TotalAvailQtyToPickBase := TotalAvailQtyToPickBase - ToQtyToPickBase;
                        OnFindPickBinOnAfterUpdateTotalAvailQtyToPickBase(TempWhseItemTrackingLine2, TotalAvailQtyToPickBase, ToQtyToPick, ToQtyToPickBase);
                    end;
                end else
                    EnqueueCannotBeHandledReason(
                        GetMessageForUnhandledQtyDueToBin(
                            BinIsForPick, BinIsForReplenishment, IsMovementWorksheet,
                            AvailableQtyBase, FromBinContent));
            until (FromBinContent.Next() = 0) or (TotalQtytoPickBase = 0);
        end;
    end;

    local procedure GetBinContent(
        var FromBinContent: Record "Bin Content";
        ItemNo: Code[20]; VariantCode: Code[10]; UnitofMeasureCode: Code[10]; LocationCode: Code[10]; ToBinCode: Code[20];
        IsCrossDock: Boolean; IsMovementWorksheet2: Boolean; WhseItemTrackingExists: Boolean; BreakbulkBins: Boolean; SmallerUOMBins: Boolean;
        WhseItemTrackingSetup: Record "Item Tracking Setup"; TotalQtytoPick: Decimal; TotalQtytoPickBase: Decimal): Boolean
    var
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetBinContent(
            FromBinContent, ItemNo, VariantCode, UnitofMeasureCode, LocationCode, ToBinCode, IsCrossDock, IsMovementWorksheet2,
            WhseItemTrackingExists, BreakbulkBins, SmallerUOMBins, WhseItemTrackingSetup, TotalQtytoPick, TotalQtytoPickBase,
            Result, IsHandled);
        if IsHandled then
            exit(Result);

        exit(
            FromBinContent.GetBinContent(
                ItemNo, VariantCode, UnitofMeasureCode, LocationCode, ToBinCode, IsCrossDock,
                IsMovementWorksheet2, WhseItemTrackingExists, WhseItemTrackingSetup));
    end;

    procedure FindBreakBulkBin(
        LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; ToUOMCode: Code[10]; ToBinCode: Code[20]; ToQtyPerUOM: Decimal;
        var TempWarehouseActivityLine2: Record "Warehouse Activity Line" temporary; var TotalQtytoPick: Decimal; var TempWhseItemTrackingLine2: Record "Whse. Item Tracking Line" temporary;
        IsCrossDock: Boolean; var TotalQtytoPickBase: Decimal; WhseItemTrackingSetup: Record "Item Tracking Setup"; QtyRndPrec: Decimal; QtyRndPrecBase: Decimal)
    var
        FromItemUnitOfMeasure: Record "Item Unit of Measure";
        FromBinContent: Record "Bin Content";
        TotalAvailQtyToPickBase: Decimal;
    begin
        // Directed put-away and pick
        GetCurrBin(LocationCode, ToBinCode);

        TotalAvailQtyToPickBase :=
          CalcTotalAvailQtyToPick(
            LocationCode, ItemNo, VariantCode, TempWhseItemTrackingLine2,
            CurrSourceType, CurrSourceSubType, CurrSourceNo, CurrSourceLineNo, CurrSourceSubLineNo, 0, false);

        if TotalAvailQtyToPickBase < 0 then
            TotalAvailQtyToPickBase := 0;

        if not CurrLocation."Always Create Pick Line" then begin
            if TotalAvailQtyToPickBase = 0 then
                exit;

            if TotalAvailQtyToPickBase < TotalQtytoPickBase then begin
                TotalQtytoPickBase := TotalAvailQtyToPickBase;
                TotalQtytoPick := Round(TotalQtytoPickBase / ToQtyPerUOM, UnitOfMeasureManagement.QtyRndPrecision());
            end;
        end;

        WhseItemTrackingSetup.CopyTrackingFromWhseItemTrackingLine(TempWhseItemTrackingLine2);

        FromItemUnitOfMeasure.SetCurrentKey("Item No.", "Qty. per Unit of Measure");
        FromItemUnitOfMeasure.SetRange("Item No.", ItemNo);
        FromItemUnitOfMeasure.SetFilter("Qty. per Unit of Measure", '>=%1', ToQtyPerUOM);
        FromItemUnitOfMeasure.SetFilter(Code, '<>%1', ToUOMCode);
        OnFindBreakBulkBinOnAfterFromItemUnitOfMeasureSetFilters(FromItemUnitOfMeasure, ItemNo, TotalQtytoPickBase, CreatePickParameters);
        if FromItemUnitOfMeasure.Find('-') then
            repeat
                if GetBinContent(
                    FromBinContent, ItemNo, VariantCode, FromItemUnitOfMeasure.Code, LocationCode, ToBinCode, IsCrossDock,
                    IsMovementWorksheet, WhseItemTrkgExists, true, false, WhseItemTrackingSetup, TotalQtytoPick, TotalQtytoPickBase)
                then
                    repeat
                        if (FromBinContent."Bin Code" <> ToBinCode) and
                            ((UseForPick(FromBinContent) and (not IsMovementWorksheet)) or
                            (UseForReplenishment(FromBinContent) and IsMovementWorksheet))
                        then
                            if FindBreakBulkBinPerBinContent(FromItemUnitOfMeasure, FromBinContent, ItemNo, VariantCode, ToUOMCode, ToBinCode, ToQtyPerUOM,
                                TempWarehouseActivityLine2, TotalQtytoPick, TempWhseItemTrackingLine2, TotalQtytoPickBase, WhseItemTrackingSetup, QtyRndPrec, QtyRndPrecBase)
                            then
                                exit;
                    until FromBinContent.Next() = 0;
            until FromItemUnitOfMeasure.Next() = 0;
    end;

    local procedure FindBreakBulkBinPerBinContent(FromItemUnitOfMeasure: Record "Item Unit of Measure"; var FromBinContent: Record "Bin Content"; ItemNo: Code[20]; VariantCode: Code[10]; ToUOMCode: Code[10]; ToBinCode: Code[20]; ToQtyPerUOM: Decimal;
        var TempWarehouseActivityLine2: Record "Warehouse Activity Line" temporary; var TotalQtytoPick: Decimal; var TempWhseItemTrackingLine2: Record "Whse. Item Tracking Line" temporary;
        var TotalQtytoPickBase: Decimal; WhseItemTrackingSetup: Record "Item Tracking Setup"; QtyRndPrec: Decimal; QtyRndPrecBase: Decimal) StopProcessing: Boolean
    var
        QtyAvailableBase: Decimal;
        FromQtyToPick: Decimal;
        FromQtyToPickBase: Decimal;
        ToQtyToPick: Decimal;
        ToQtyToPickBase: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindBreakBulkBinPerBinContent(
            FromBinContent, ItemNo, VariantCode, WhseItemTrackingSetup, WhseItemTrkgExists, TempWhseItemTrackingLine2,
             CurrSourceType, CurrSourceSubType, CurrSourceNo, CurrSourceLineNo, CurrSourceSubLineNo, TotalQtytoPickBase, QtyAvailableBase,
             StopProcessing, IsHandled);
        if IsHandled then
            exit(StopProcessing);

        // Check and use bulk that has previously been broken
        QtyAvailableBase := CalcBinAvailQtyInBreakbulk(TempWarehouseActivityLine2, FromBinContent, ToUOMCode, WhseItemTrackingSetup);

        OnCalcAvailQtyOnFindBreakBulkBin(
            true, ItemNo, VariantCode,
            WhseItemTrackingSetup."Serial No. Required", WhseItemTrackingSetup."Lot No. Required", WhseItemTrkgExists,
            TempWhseItemTrackingLine2."Lot No.", TempWhseItemTrackingLine2."Serial No.",
            FromBinContent."Location Code", FromBinContent."Bin Code",
            CurrSourceType, CurrSourceSubType, CurrSourceNo, CurrSourceLineNo, CurrSourceSubLineNo, TotalQtytoPickBase, QtyAvailableBase,
            WhseItemTrackingSetup);

        if QtyAvailableBase > 0 then begin
            UpdateQuantitiesToPick(
                QtyAvailableBase,
                ToQtyPerUOM, FromQtyToPick, FromQtyToPickBase,
                ToQtyPerUOM, ToQtyToPick, ToQtyToPickBase,
                TotalQtytoPick, TotalQtytoPickBase);

            CreateBreakBulkTempLines(
                FromBinContent."Location Code", ToUOMCode, ToUOMCode,
                FromBinContent."Bin Code", ToBinCode, ToQtyPerUOM, ToQtyPerUOM,
                0, FromQtyToPick, FromQtyToPickBase, ToQtyToPick, ToQtyToPickBase, QtyRndPrec, QtyRndPrecBase);
        end;

        if TotalQtytoPickBase <= 0 then
            exit(true);

        // Now break bulk and use
        QtyAvailableBase := CalcBinAvailQtyToBreakbulk(TempWarehouseActivityLine2, FromBinContent, WhseItemTrackingSetup);

        OnCalcAvailQtyOnFindBreakBulkBin(
            false, ItemNo, VariantCode,
            WhseItemTrackingSetup."Serial No. Required", WhseItemTrackingSetup."Lot No. Required", WhseItemTrkgExists,
            TempWhseItemTrackingLine2."Lot No.", TempWhseItemTrackingLine2."Serial No.",
            FromBinContent."Location Code", FromBinContent."Bin Code",
            CurrSourceType, CurrSourceSubType, CurrSourceNo, CurrSourceLineNo, CurrSourceSubLineNo, TotalQtytoPickBase, QtyAvailableBase,
            WhseItemTrackingSetup);

        if QtyAvailableBase > 0 then begin
            FromItemUnitOfMeasure.Get(ItemNo, FromBinContent."Unit of Measure Code");
            UpdateQuantitiesToPick(
                QtyAvailableBase,
                FromItemUnitOfMeasure."Qty. per Unit of Measure", FromQtyToPick, FromQtyToPickBase,
                ToQtyPerUOM, ToQtyToPick, ToQtyToPickBase,
                TotalQtytoPick, TotalQtytoPickBase);

            CurrBreakbulkNo := CurrBreakbulkNo + 1;
            CreateBreakBulkTempLines(
                FromBinContent."Location Code", FromBinContent."Unit of Measure Code", ToUOMCode,
                FromBinContent."Bin Code", ToBinCode, FromItemUnitOfMeasure."Qty. per Unit of Measure", ToQtyPerUOM,
                CurrBreakbulkNo, ToQtyToPick, ToQtyToPickBase, FromQtyToPick, FromQtyToPickBase,
                QtyRndPrec, QtyRndPrecBase);
        end;
        if TotalQtytoPickBase <= 0 then
            exit(true);
    end;

    local procedure FindSmallerUOMBin(
        LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; UnitofMeasureCode: Code[10]; ToBinCode: Code[20]; QtyPerUnitOfMeasure: Decimal;
        var TotalQtytoPick: Decimal; var TempWhseItemTrackingLine2: Record "Whse. Item Tracking Line" temporary;
        IsCrossDock: Boolean; var TotalQtytoPickBase: Decimal; WhseItemTrackingSetup: Record "Item Tracking Setup"; QtyRndPrec: Decimal; QtyRndPrecBase: Decimal)
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        FromBinContent: Record "Bin Content";
        TempFromBinContent: Record "Bin Content" temporary;
        FromQtyToPick: Decimal;
        FromQtyToPickBase: Decimal;
        ToQtyToPick: Decimal;
        ToQtyToPickBase: Decimal;
        QtyAvailableBase: Decimal;
        TotalAvailQtyToPickBase: Decimal;
    begin
        // Directed put-away and pick
        TotalAvailQtyToPickBase :=
          CalcTotalAvailQtyToPick(
            LocationCode, ItemNo, VariantCode, TempWhseItemTrackingLine2,
            CurrSourceType, CurrSourceSubType, CurrSourceNo, CurrSourceLineNo, CurrSourceSubLineNo, 0, false);

        if TotalAvailQtyToPickBase < 0 then
            TotalAvailQtyToPickBase := 0;

        if not CurrLocation."Always Create Pick Line" then begin
            if TotalAvailQtyToPickBase = 0 then
                exit;

            if TotalAvailQtyToPickBase < TotalQtytoPickBase then begin
                TotalQtytoPickBase := TotalAvailQtyToPickBase;
                ItemUnitOfMeasure.Get(ItemNo, UnitofMeasureCode);
                TotalQtytoPick := Round(TotalQtytoPickBase / ItemUnitOfMeasure."Qty. per Unit of Measure", UnitOfMeasureManagement.QtyRndPrecision());
            end;
        end;

        GetCurrBin(LocationCode, ToBinCode);

        WhseItemTrackingSetup.CopyTrackingFromWhseItemTrackingLine(TempWhseItemTrackingLine2);

        ItemUnitOfMeasure.SetCurrentKey("Item No.", "Qty. per Unit of Measure");
        ItemUnitOfMeasure.SetRange("Item No.", ItemNo);
        ItemUnitOfMeasure.SetFilter("Qty. per Unit of Measure", '<%1', QtyPerUnitOfMeasure);
        ItemUnitOfMeasure.SetFilter(Code, '<>%1', UnitofMeasureCode);
        ItemUnitOfMeasure.Ascending(false);
        if ItemUnitOfMeasure.Find('-') then
            repeat
                if GetBinContent(
                    FromBinContent, ItemNo, VariantCode, ItemUnitOfMeasure.Code, LocationCode, ToBinCode, IsCrossDock,
                    IsMovementWorksheet, WhseItemTrkgExists, false, true, WhseItemTrackingSetup, TotalQtytoPick, TotalQtytoPickBase)
                then
                    repeat
                        if (FromBinContent."Bin Code" <> ToBinCode) and
                            ((UseForPick(FromBinContent) and (not IsMovementWorksheet)) or
                            (UseForReplenishment(FromBinContent) and IsMovementWorksheet))
                        then begin
                            CalcBinAvailQtyFromSmallerUOM(QtyAvailableBase, FromBinContent, false, WhseItemTrackingSetup);

                            OnCalcAvailQtyOnFindSmallerUOMBin(
                                false, ItemNo, VariantCode,
                                WhseItemTrackingSetup."Serial No. Required", WhseItemTrackingSetup."Lot No. Required", WhseItemTrkgExists,
                                TempWhseItemTrackingLine2."Lot No.", TempWhseItemTrackingLine2."Serial No.",
                                FromBinContent."Location Code", FromBinContent."Bin Code",
                                CurrSourceType, CurrSourceSubType, CurrSourceNo, CurrSourceLineNo, CurrSourceSubLineNo, TotalQtytoPickBase, QtyAvailableBase,
                                WhseItemTrackingSetup);

                            if QtyAvailableBase > 0 then begin
                                UpdateQuantitiesToPick(
                                    QtyAvailableBase,
                                    ItemUnitOfMeasure."Qty. per Unit of Measure", FromQtyToPick, FromQtyToPickBase,
                                    QtyPerUnitOfMeasure, ToQtyToPick, ToQtyToPickBase,
                                    TotalQtytoPick, TotalQtytoPickBase);

                                CreateTempActivityLine(
                                    LocationCode, FromBinContent."Bin Code", FromBinContent."Unit of Measure Code",
                                    ItemUnitOfMeasure."Qty. per Unit of Measure", FromQtyToPick, FromQtyToPickBase, 1, 0, QtyRndPrec, QtyRndPrecBase);
                                CreateTempActivityLine(
                                    LocationCode, ToBinCode, UnitofMeasureCode,
                                    QtyPerUnitOfMeasure, ToQtyToPick, ToQtyToPickBase, 2, 0, QtyRndPrec, QtyRndPrecBase);

                                TotalAvailQtyToPickBase := TotalAvailQtyToPickBase - ToQtyToPickBase;
                            end;
                        end;
                    until (FromBinContent.Next() = 0) or (TotalQtytoPickBase = 0);

                if TotalQtytoPickBase > 0 then
                    if BreakBulkPlacingExists(TempFromBinContent, ItemNo, LocationCode, ItemUnitOfMeasure.Code, VariantCode, IsCrossDock, WhseItemTrackingSetup) then
                        repeat
                            if (TempFromBinContent."Bin Code" <> ToBinCode) and
                                ((UseForPick(TempFromBinContent) and (not IsMovementWorksheet)) or
                                (UseForReplenishment(TempFromBinContent) and IsMovementWorksheet))
                            then begin
                                CalcBinAvailQtyFromSmallerUOM(QtyAvailableBase, TempFromBinContent, true, WhseItemTrackingSetup);

                                OnCalcAvailQtyOnFindSmallerUOMBin(
                                    true, ItemNo, VariantCode,
                                    WhseItemTrackingSetup."Serial No. Required", WhseItemTrackingSetup."Lot No. Required", WhseItemTrkgExists,
                                    TempWhseItemTrackingLine2."Lot No.", TempWhseItemTrackingLine2."Serial No.",
                                    TempFromBinContent."Location Code", TempFromBinContent."Bin Code",
                                    CurrSourceType, CurrSourceSubType, CurrSourceNo, CurrSourceLineNo, CurrSourceSubLineNo, TotalQtytoPickBase, QtyAvailableBase,
                                    WhseItemTrackingSetup);

                                if QtyAvailableBase > 0 then begin
                                    UpdateQuantitiesToPick(
                                        QtyAvailableBase,
                                        ItemUnitOfMeasure."Qty. per Unit of Measure", FromQtyToPick, FromQtyToPickBase,
                                        QtyPerUnitOfMeasure, ToQtyToPick, ToQtyToPickBase,
                                        TotalQtytoPick, TotalQtytoPickBase);

                                    CreateTempActivityLine(
                                        LocationCode, TempFromBinContent."Bin Code", TempFromBinContent."Unit of Measure Code",
                                        ItemUnitOfMeasure."Qty. per Unit of Measure", FromQtyToPick, FromQtyToPickBase, 1, 0);
                                    CreateTempActivityLine(
                                        LocationCode, ToBinCode, UnitofMeasureCode,
                                        QtyPerUnitOfMeasure, ToQtyToPick, ToQtyToPickBase, 2, 0);
                                    TotalAvailQtyToPickBase := TotalAvailQtyToPickBase - ToQtyToPickBase;
                                end;
                            end;
                        until (TempFromBinContent.Next() = 0) or (TotalQtytoPickBase = 0);
            until (ItemUnitOfMeasure.Next() = 0) or (TotalQtytoPickBase = 0);
    end;

    local procedure FindWhseActivLine(var TempWarehouseActivityLine2: Record "Warehouse Activity Line" temporary; Location: Record Location; var FirstWhseDocNo: Code[20]; var LastWhseDocNo: Code[20]): Boolean
    begin
        TempWarehouseActivityLine2.SetRange("Location Code", TempWarehouseActivityLine2."Location Code");
        if Location."Bin Mandatory" then
            TempWarehouseActivityLine2.SetRange("Action Type", TempWarehouseActivityLine2."Action Type"::Take)
        else
            TempWarehouseActivityLine2.SetRange("Action Type", TempWarehouseActivityLine2."Action Type"::" ");

        OnFindSmallerUOMBinOnBeforeFindWhseActivLine(TempWarehouseActivityLine2, Location);

        if not TempWarehouseActivityLine2.Find('-') then begin
            OnAfterFindWhseActivLine(FirstWhseDocNo, LastWhseDocNo);
            exit(false);
        end;

        exit(true);
    end;

    procedure CalcBinAvailQtyToPick(var QtyToPickBase: Decimal; var BinContent: Record "Bin Content"; var TempWarehouseActivityLine2: Record "Warehouse Activity Line"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    var
        AvailableQtyBase: Decimal;
    begin
        TempWarehouseActivityLine2.Reset();
        TempWarehouseActivityLine2.SetCurrentKey(
          TempWarehouseActivityLine2."Item No.", TempWarehouseActivityLine2."Bin Code", TempWarehouseActivityLine2."Location Code", TempWarehouseActivityLine2."Action Type",
          TempWarehouseActivityLine2."Variant Code", TempWarehouseActivityLine2."Unit of Measure Code", TempWarehouseActivityLine2."Breakbulk No.");
        TempWarehouseActivityLine2.SetRange(TempWarehouseActivityLine2."Item No.", BinContent."Item No.");
        TempWarehouseActivityLine2.SetRange(TempWarehouseActivityLine2."Bin Code", BinContent."Bin Code");
        TempWarehouseActivityLine2.SetRange(TempWarehouseActivityLine2."Location Code", BinContent."Location Code");
        TempWarehouseActivityLine2.SetRange(TempWarehouseActivityLine2."Unit of Measure Code", BinContent."Unit of Measure Code");
        TempWarehouseActivityLine2.SetRange(TempWarehouseActivityLine2."Variant Code", BinContent."Variant Code");
        if WhseItemTrkgExists then
            TempWarehouseActivityLine2.SetTrackingFilterFromWhseItemTrackingSetup(WhseItemTrackingSetup);

        if CurrLocation."Allow Breakbulk" then begin
            TempWarehouseActivityLine2.SetRange(TempWarehouseActivityLine2."Action Type", TempWarehouseActivityLine2."Action Type"::Place);
            TempWarehouseActivityLine2.SetFilter(TempWarehouseActivityLine2."Breakbulk No.", '<>0');
            TempWarehouseActivityLine2.CalcSums(TempWarehouseActivityLine2."Qty. (Base)");
            AvailableQtyBase := TempWarehouseActivityLine2."Qty. (Base)";
        end;

        TempWarehouseActivityLine2.SetRange(TempWarehouseActivityLine2."Action Type", TempWarehouseActivityLine2."Action Type"::Take);
        TempWarehouseActivityLine2.SetRange(TempWarehouseActivityLine2."Breakbulk No.", 0);
        TempWarehouseActivityLine2.CalcSums(TempWarehouseActivityLine2."Qty. (Base)");

        QtyToPickBase := BinContent.CalcQtyAvailToPick(AvailableQtyBase - TempWarehouseActivityLine2."Qty. (Base)");

        OnAfterCalcBinAvailQtyToPick(QtyToPickBase, BinContent, TempWarehouseActivityLine2);
    end;

    local procedure CalcBinAvailQtyToBreakbulk(var TempWarehouseActivityLine2: Record "Warehouse Activity Line"; var BinContent: Record "Bin Content"; WhseItemTrackingSetup: Record "Item Tracking Setup") QtyToPickBase: Decimal
    begin
        BinContent.SetFilterOnUnitOfMeasure();
        BinContent.CalcFields(BinContent."Quantity (Base)", BinContent."Pick Quantity (Base)", BinContent."Negative Adjmt. Qty. (Base)");

        OnCalcBinAvailQtyToBreakbulkOnOnAfterBinContentCalcFields(BinContent);

        QtyToPickBase := BinContent."Quantity (Base)" - BinContent."Pick Quantity (Base)" - BinContent."Negative Adjmt. Qty. (Base)";
        if QtyToPickBase <= 0 then
            exit(0);

        TempWarehouseActivityLine2.SetCurrentKey(TempWarehouseActivityLine2."Item No.",
                                                 TempWarehouseActivityLine2."Bin Code",
                                                 TempWarehouseActivityLine2."Location Code",
                                                 TempWarehouseActivityLine2."Action Type",
                                                 TempWarehouseActivityLine2."Variant Code",
                                                 TempWarehouseActivityLine2."Unit of Measure Code",
                                                 TempWarehouseActivityLine2."Breakbulk No.");
        TempWarehouseActivityLine2.SetRange(TempWarehouseActivityLine2."Action Type", TempWarehouseActivityLine2."Action Type"::Take);
        TempWarehouseActivityLine2.SetRange(TempWarehouseActivityLine2."Location Code", BinContent."Location Code");
        TempWarehouseActivityLine2.SetRange(TempWarehouseActivityLine2."Bin Code", BinContent."Bin Code");
        TempWarehouseActivityLine2.SetRange(TempWarehouseActivityLine2."Item No.", BinContent."Item No.");
        TempWarehouseActivityLine2.SetRange(TempWarehouseActivityLine2."Unit of Measure Code", BinContent."Unit of Measure Code");
        TempWarehouseActivityLine2.SetRange(TempWarehouseActivityLine2."Variant Code", BinContent."Variant Code");
        if WhseItemTrkgExists then
            TempWarehouseActivityLine2.SetTrackingFilterFromWhseItemTrackingSetup(WhseItemTrackingSetup)
        else
            TempWarehouseActivityLine2.ClearTrackingFilter();

        TempWarehouseActivityLine2.ClearSourceFilter();
        TempWarehouseActivityLine2.SetRange(TempWarehouseActivityLine2."Breakbulk No.");
        TempWarehouseActivityLine2.CalcSums(TempWarehouseActivityLine2."Qty. (Base)");
        QtyToPickBase := QtyToPickBase - TempWarehouseActivityLine2."Qty. (Base)";
        exit(QtyToPickBase);
    end;

    local procedure CalcBinAvailQtyInBreakbulk(var TempWarehouseActivityLine2: Record "Warehouse Activity Line"; var BinContent: Record "Bin Content"; ToUOMCode: Code[10]; WhseItemTrackingSetup: Record "Item Tracking Setup") QtyToPickBase: Decimal
    begin
        if (CreatePickParameters."Max No. of Source Doc." > 1) or (CreatePickParameters."Max No. of Lines" <> 0) then
            exit(0);

        TempWarehouseActivityLine2.SetCurrentKey(TempWarehouseActivityLine2."Item No.",
                                                 TempWarehouseActivityLine2."Bin Code",
                                                 TempWarehouseActivityLine2."Location Code",
                                                 TempWarehouseActivityLine2."Action Type",
                                                 TempWarehouseActivityLine2."Variant Code",
                                                 TempWarehouseActivityLine2."Unit of Measure Code",
                                                 TempWarehouseActivityLine2."Breakbulk No.");
        TempWarehouseActivityLine2.SetRange(TempWarehouseActivityLine2."Action Type", TempWarehouseActivityLine2."Action Type"::Take);
        TempWarehouseActivityLine2.SetRange(TempWarehouseActivityLine2."Location Code", BinContent."Location Code");
        TempWarehouseActivityLine2.SetRange(TempWarehouseActivityLine2."Bin Code", BinContent."Bin Code");
        TempWarehouseActivityLine2.SetRange(TempWarehouseActivityLine2."Item No.", BinContent."Item No.");
        TempWarehouseActivityLine2.SetRange(TempWarehouseActivityLine2."Unit of Measure Code", ToUOMCode);
        TempWarehouseActivityLine2.SetRange(TempWarehouseActivityLine2."Variant Code", BinContent."Variant Code");
        if WhseItemTrkgExists then
            TempWarehouseActivityLine2.SetTrackingFilterFromWhseItemTrackingSetup(WhseItemTrackingSetup)
        else
            TempWarehouseActivityLine2.ClearTrackingFilter();
        TempWarehouseActivityLine2.SetRange(TempWarehouseActivityLine2."Breakbulk No.", 0);
        TempWarehouseActivityLine2.CalcSums(TempWarehouseActivityLine2."Qty. (Base)");
        QtyToPickBase := TempWarehouseActivityLine2."Qty. (Base)";

        TempWarehouseActivityLine2.SetRange(TempWarehouseActivityLine2."Action Type", TempWarehouseActivityLine2."Action Type"::Place);
        TempWarehouseActivityLine2.SetFilter(TempWarehouseActivityLine2."Breakbulk No.", '<>0');
        TempWarehouseActivityLine2.SetRange(TempWarehouseActivityLine2."No.", Format(TempNo));
        if CreatePickParameters."Max No. of Source Doc." = 1 then begin
            TempWarehouseActivityLine2.SetRange(TempWarehouseActivityLine2."Source Type", CurrWhseWorksheetLine."Source Type");
            TempWarehouseActivityLine2.SetRange(TempWarehouseActivityLine2."Source Subtype", CurrWhseWorksheetLine."Source Subtype");
            TempWarehouseActivityLine2.SetRange(TempWarehouseActivityLine2."Source No.", CurrWhseWorksheetLine."Source No.");
        end;
        TempWarehouseActivityLine2.CalcSums(TempWarehouseActivityLine2."Qty. (Base)");
        QtyToPickBase := TempWarehouseActivityLine2."Qty. (Base)" - QtyToPickBase;
        exit(QtyToPickBase);
    end;

    local procedure CalcBinAvailQtyFromSmallerUOM(var AvailableQtyBase: Decimal; var BinContent: Record "Bin Content"; AllowInitialZero: Boolean; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        BinContent.SetFilterOnUnitOfMeasure();
        BinContent.CalcFields(BinContent."Quantity (Base)", BinContent."Pick Quantity (Base)", BinContent."Negative Adjmt. Qty. (Base)");

        OnBeforeSetAvailableQtyBase(BinContent);

        AvailableQtyBase := BinContent."Quantity (Base)" - BinContent."Pick Quantity (Base)" - BinContent."Negative Adjmt. Qty. (Base)";
        if (AvailableQtyBase < 0) or ((AvailableQtyBase = 0) and (not AllowInitialZero)) then
            exit;

        TempWarehouseActivityLine.SetCurrentKey(TempWarehouseActivityLine."Item No.",
                                                TempWarehouseActivityLine."Bin Code",
                                                TempWarehouseActivityLine."Location Code",
                                                TempWarehouseActivityLine."Action Type",
                                                TempWarehouseActivityLine."Variant Code",
                                                TempWarehouseActivityLine."Unit of Measure Code",
                                                TempWarehouseActivityLine."Breakbulk No.");
        TempWarehouseActivityLine.SetRange(TempWarehouseActivityLine."Item No.", BinContent."Item No.");
        TempWarehouseActivityLine.SetRange(TempWarehouseActivityLine."Bin Code", BinContent."Bin Code");
        TempWarehouseActivityLine.SetRange(TempWarehouseActivityLine."Location Code", BinContent."Location Code");
        TempWarehouseActivityLine.SetRange(TempWarehouseActivityLine."Action Type", TempWarehouseActivityLine."Action Type"::Take);
        TempWarehouseActivityLine.SetRange(TempWarehouseActivityLine."Variant Code", BinContent."Variant Code");
        TempWarehouseActivityLine.SetRange(TempWarehouseActivityLine."Unit of Measure Code", BinContent."Unit of Measure Code");
        if WhseItemTrkgExists then
            TempWarehouseActivityLine.SetTrackingFilterFromWhseItemTrackingSetup(WhseItemTrackingSetup)
        else
            TempWarehouseActivityLine.ClearTrackingFilter();
        TempWarehouseActivityLine.CalcSums(TempWarehouseActivityLine."Qty. (Base)");
        AvailableQtyBase := AvailableQtyBase - TempWarehouseActivityLine."Qty. (Base)";

        TempWarehouseActivityLine.SetRange(TempWarehouseActivityLine."Action Type", TempWarehouseActivityLine."Action Type"::Place);
        TempWarehouseActivityLine.SetFilter(TempWarehouseActivityLine."Breakbulk No.", '<>0');
        TempWarehouseActivityLine.CalcSums(TempWarehouseActivityLine."Qty. (Base)");
        AvailableQtyBase := AvailableQtyBase + TempWarehouseActivityLine."Qty. (Base)";
        TempWarehouseActivityLine.Reset();
    end;

    local procedure CreateBreakBulkTempLines(LocationCode: Code[10]; FromUOMCode: Code[10]; ToUOMCode: Code[10]; FromBinCode: Code[20]; ToBinCode: Code[20]; FromQtyPerUOM: Decimal; ToQtyPerUOM: Decimal; BreakbulkNo2: Integer; ToQtyToPick: Decimal; ToQtyToPickBase: Decimal; FromQtyToPick: Decimal; FromQtyToPickBase: Decimal; QtyRndPrec: Decimal; QtyRndPrecBase: Decimal)
    var
        QtyToBreakBulk: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateBreakBulkTempLines(LocationCode, FromUOMCode, ToUOMCode, FromBinCode, ToBinCode, FromQtyPerUOM, ToQtyPerUOM, BreakbulkNo2, ToQtyToPick, ToQtyToPickBase, FromQtyToPick, FromQtyToPickBase, QtyRndPrec, QtyRndPrecBase, IsHandled);
        if IsHandled then
            exit;

        // Directed put-away and pick
        if FromUOMCode <> ToUOMCode then begin
            CreateTempActivityLine(
              LocationCode, FromBinCode, FromUOMCode, FromQtyPerUOM, FromQtyToPick, FromQtyToPickBase, 1, BreakbulkNo2, QtyRndPrec, QtyRndPrecBase);

            if FromQtyToPickBase = ToQtyToPickBase then
                QtyToBreakBulk := ToQtyToPick
            else
                QtyToBreakBulk := Round(FromQtyToPick * FromQtyPerUOM / ToQtyPerUOM, UnitOfMeasureManagement.QtyRndPrecision());
            CreateTempActivityLine(
              LocationCode, FromBinCode, ToUOMCode, ToQtyPerUOM, QtyToBreakBulk, FromQtyToPickBase, 2, BreakbulkNo2, QtyRndPrec, QtyRndPrecBase);
        end;
        CreateTempActivityLine(LocationCode, FromBinCode, ToUOMCode, ToQtyPerUOM, ToQtyToPick, ToQtyToPickBase, 1, 0, QtyRndPrec, QtyRndPrecBase);
        CreateTempActivityLine(LocationCode, ToBinCode, ToUOMCode, ToQtyPerUOM, ToQtyToPick, ToQtyToPickBase, 2, 0, QtyRndPrec, QtyRndPrecBase);
    end;

    procedure CreateWhseDocument(var FirstWhseDocNo: Code[20]; var LastWhseDocNo: Code[20]; ShowError: Boolean)
    var
        OldNo: Code[20];
        OldSourceNo: Code[20];
        OldLocationCode: Code[10];
        OldBinCode: Code[20];
        OldZoneCode: Code[10];
        NoOfLines: Integer;
        NoOfSourceDoc: Integer;
        CreateNewHeader: Boolean;
        WhseDocCreated: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeCreateWhseDocumentOnBeforeFindTempActivityLine(TempWarehouseActivityLine, CreatePickParameters."Whse. Document", IsHandled, IsMovementWorksheet, FirstWhseDocNo, LastWhseDocNo, CreatePickParameters, CalledFromWksh);
        TempWarehouseActivityLine.Reset();
        if not TempWarehouseActivityLine.Find('-') then begin
            OnCreateWhseDocumentOnBeforeShowError(ShowError, FirstWhseDocNo, CannotBeHandledReasons);
            if ShowError then
                ShowErrorWhenNoTempWarehouseActivityLineExists();
            exit;
        end;

        IsHandled := false;
        OnBeforeCreateWhseDocument(TempWarehouseActivityLine, CreatePickParameters."Whse. Document", IsHandled, IsMovementWorksheet, FirstWhseDocNo, LastWhseDocNo, CreatePickParameters);
        if IsHandled then
            exit;

        LockTables();

        if IsMovementWorksheet then
            TempWarehouseActivityLine.SetRange("Activity Type", TempWarehouseActivityLine."Activity Type"::Movement)
        else
            TempWarehouseActivityLine.SetRange("Activity Type", TempWarehouseActivityLine."Activity Type"::Pick);

        NoOfLines := 0;
        NoOfSourceDoc := 0;

        repeat
            GetLocation(TempWarehouseActivityLine."Location Code");
            if not FindWhseActivLine(TempWarehouseActivityLine, CurrLocation, FirstWhseDocNo, LastWhseDocNo) then
                exit;

            if CreatePickParameters."Per Bin" then
                TempWarehouseActivityLine.SetRange("Bin Code", TempWarehouseActivityLine."Bin Code");
            if CreatePickParameters."Per Zone" then
                TempWarehouseActivityLine.SetRange("Zone Code", TempWarehouseActivityLine."Zone Code");

            OnCreateWhseDocumentOnAfterSetFiltersBeforeLoop(TempWarehouseActivityLine, CreatePickParameters."Per Bin", CreatePickParameters."Per Zone");

            OldLocationCode := '';
            OldZoneCode := '';
            OldBinCode := '';
            OldNo := '';
            OldSourceNo := '';
            repeat
                IsHandled := false;
                CreateNewHeader := false;
                OnCreateWhseDocumentOnBeforeCreateDocAndLine(TempWarehouseActivityLine, IsHandled, CreateNewHeader);
                if IsHandled then begin
                    if CreateNewHeader then begin
                        CreateWhseActivHeader(
                          TempWarehouseActivityLine."Location Code", FirstWhseDocNo, LastWhseDocNo,
                          NoOfSourceDoc, NoOfLines, WhseDocCreated);
                        CreateWhseDocLine();
                    end else
                        CreateNewWhseDoc(OldNo, OldSourceNo, OldLocationCode, FirstWhseDocNo, LastWhseDocNo, NoOfSourceDoc, NoOfLines, WhseDocCreated);
                end else
                    if CreatePickParameters."Per Bin" then begin
                        if TempWarehouseActivityLine."Bin Code" <> OldBinCode then begin
                            CreateWhseActivHeader(
                              TempWarehouseActivityLine."Location Code", FirstWhseDocNo, LastWhseDocNo,
                              NoOfSourceDoc, NoOfLines, WhseDocCreated);
                            CreateWhseDocLine();
                        end else
                            CreateNewWhseDoc(
                              OldNo, OldSourceNo, OldLocationCode, FirstWhseDocNo, LastWhseDocNo,
                              NoOfSourceDoc, NoOfLines, WhseDocCreated);
                    end else
                        if CreatePickParameters."Per Zone" then
                            if TempWarehouseActivityLine."Zone Code" <> OldZoneCode then begin
                                CreateWhseActivHeader(
                                  TempWarehouseActivityLine."Location Code", FirstWhseDocNo, LastWhseDocNo,
                                  NoOfSourceDoc, NoOfLines, WhseDocCreated);
                                CreateWhseDocLine();
                            end else
                                CreateNewWhseDoc(
                                  OldNo, OldSourceNo, OldLocationCode, FirstWhseDocNo, LastWhseDocNo,
                                  NoOfSourceDoc, NoOfLines, WhseDocCreated)
                        else
                            CreateNewWhseDoc(
                              OldNo, OldSourceNo, OldLocationCode, FirstWhseDocNo, LastWhseDocNo,
                              NoOfSourceDoc, NoOfLines, WhseDocCreated);

                OldZoneCode := TempWarehouseActivityLine."Zone Code";
                OldBinCode := TempWarehouseActivityLine."Bin Code";
                OldNo := TempWarehouseActivityLine."No.";
                OldSourceNo := TempWarehouseActivityLine."Source No.";
                OldLocationCode := TempWarehouseActivityLine."Location Code";
                OnCreateWhseDocumentOnAfterSaveOldValues(TempWarehouseActivityLine, CurrWarehouseActivityHeader, LastWhseDocNo);
            until TempWarehouseActivityLine.Next() = 0;
            OnCreateWhseDocumentOnBeforeClearFilters(TempWarehouseActivityLine, CurrWarehouseActivityHeader);
            TempWarehouseActivityLine.SetRange("Bin Code");
            TempWarehouseActivityLine.SetRange("Zone Code");
            TempWarehouseActivityLine.SetRange("Location Code");
            TempWarehouseActivityLine.SetRange("Action Type");
            OnCreateWhseDocumentOnAfterSetFiltersAfterLoop(TempWarehouseActivityLine);
            if not TempWarehouseActivityLine.Find('-') then begin
                OnAfterCreateWhseDocument(FirstWhseDocNo, LastWhseDocNo, CreatePickParameters);
                exit;
            end;

        until false;
    end;

    procedure CreateNewWhseDoc(OldNo: Code[20]; OldSourceNo: Code[20]; OldLocationCode: Code[10]; var FirstWhseDocNo: Code[20]; var LastWhseDocNo: Code[20]; var NoOfSourceDoc: Integer; var NoOfLines: Integer; var WhseDocCreated: Boolean)
    var
        CreateNewWhseActivHeader: Boolean;
    begin
        OnBeforeCreateNewWhseDoc(
          TempWarehouseActivityLine, OldNo, OldSourceNo, OldLocationCode, FirstWhseDocNo, LastWhseDocNo, NoOfSourceDoc, NoOfLines, WhseDocCreated);

        CreateNewWhseActivHeader := (TempWarehouseActivityLine."No." <> OldNo) or
           (TempWarehouseActivityLine."Location Code" <> OldLocationCode);

        OnCreateNewWhseDocOnAfterCheckCreateNewWhseActivHeader(TempWarehouseActivityLine, CreateNewWhseActivHeader);

        if CreateNewWhseActivHeader then begin
            CreateWhseActivHeader(
              TempWarehouseActivityLine."Location Code", FirstWhseDocNo, LastWhseDocNo,
              NoOfSourceDoc, NoOfLines, WhseDocCreated);
            CreateWhseDocLine();
        end else begin
            NoOfLines := NoOfLines + 1;
            if TempWarehouseActivityLine."Source No." <> OldSourceNo then
                NoOfSourceDoc := NoOfSourceDoc + 1;
            if (CreatePickParameters."Max No. of Source Doc." > 0) and (NoOfSourceDoc > CreatePickParameters."Max No. of Source Doc.") then
                CreateWhseActivHeader(
                  TempWarehouseActivityLine."Location Code", FirstWhseDocNo, LastWhseDocNo,
                  NoOfSourceDoc, NoOfLines, WhseDocCreated);
            if (CreatePickParameters."Max No. of Lines" > 0) and (NoOfLines > CreatePickParameters."Max No. of Lines") then
                CreateWhseActivHeader(
                  TempWarehouseActivityLine."Location Code", FirstWhseDocNo, LastWhseDocNo,
                  NoOfSourceDoc, NoOfLines, WhseDocCreated);
            CreateWhseDocLine();
        end;
    end;

    local procedure CreateWhseActivHeader(LocationCode: Code[10]; var FirstWhseDocNo: Code[20]; var LastWhseDocNo: Code[20]; var NoOfSourceDoc: Integer; var NoOfLines: Integer; var WhseDocCreated: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateWhseActivHeader(CurrWarehouseActivityHeader, LocationCode, FirstWhseDocNo, LastWhseDocNo, NoOfSourceDoc, NoOfLines, WhseDocCreated, IsHandled);
        if not IsHandled then begin
            CurrWarehouseActivityHeader.Init();
            CurrWarehouseActivityHeader."No." := '';
            if CreatePickParameters."Whse. Document Type" = CreatePickParameters."Whse. Document Type"::Movement then
                CurrWarehouseActivityHeader.Type := CurrWarehouseActivityHeader.Type::Movement
            else
                CurrWarehouseActivityHeader.Type := CurrWarehouseActivityHeader.Type::Pick;
            CurrWarehouseActivityHeader."Location Code" := LocationCode;
            if CreatePickParameters."Assigned ID" <> '' then
                CurrWarehouseActivityHeader.Validate("Assigned User ID", CreatePickParameters."Assigned ID");
            CurrWarehouseActivityHeader."Sorting Method" := CreatePickParameters."Sorting Method";
            CurrWarehouseActivityHeader."Breakbulk Filter" := CreatePickParameters."Breakbulk Filter";
            OnBeforeWhseActivHeaderInsert(CurrWarehouseActivityHeader, TempWarehouseActivityLine, CreatePickParameters, CurrWarehouseShipmentLine);
            CurrWarehouseActivityHeader.Insert(true);
            OnCreateWhseActivHeaderOnAfterWhseActivHeaderInsert(CurrWarehouseActivityHeader, TempWarehouseActivityLine, CreatePickParameters);

            NoOfLines := 1;
            NoOfSourceDoc := 1;

            if not WhseDocCreated then begin
                FirstWhseDocNo := CurrWarehouseActivityHeader."No.";
                WhseDocCreated := true;
            end;
            LastWhseDocNo := CurrWarehouseActivityHeader."No.";
        end;
    end;

    local procedure CreateWhseDocLine()
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        LineNo: Integer;
        IsHandled: Boolean;
    begin
        TempWarehouseActivityLine.SetRange("Breakbulk No.", 0);
        TempWarehouseActivityLine.Find('-');
        WarehouseActivityLine.SetRange("Activity Type", CurrWarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", CurrWarehouseActivityHeader."No.");
        if WarehouseActivityLine.FindLast() then
            LineNo := WarehouseActivityLine."Line No."
        else
            LineNo := 0;

        ItemTrackingManagement.GetWhseItemTrkgSetup(TempWarehouseActivityLine."Item No.", WhseItemTrackingSetup);
        OnCreateWhseDocLineOnAfterGetWhseItemTrkgSetup(WhseItemTrackingSetup, TempWarehouseActivityLine);

        LineNo := LineNo + 10000;
        WarehouseActivityLine.Init();
        WarehouseActivityLine := TempWarehouseActivityLine;
        WarehouseActivityLine."No." := CurrWarehouseActivityHeader."No.";
        if not (WarehouseActivityLine."Whse. Document Type" in [
                                                        WarehouseActivityLine."Whse. Document Type"::"Internal Pick",
                                                        WarehouseActivityLine."Whse. Document Type"::"Movement Worksheet"])
        then
            WarehouseActivityLine."Source Document" := WhseManagement.GetWhseActivSourceDocument(WarehouseActivityLine."Source Type", WarehouseActivityLine."Source Subtype");

        IsHandled := false;
        OnBeforeCreateWhseDocTakeLine(WarehouseActivityLine, CurrLocation, IsHandled);
        if not IsHandled then
            if CurrLocation."Bin Mandatory" and (not WhseItemTrackingSetup."Serial No. Required") then
                CreateWhseDocTakeLine(WarehouseActivityLine, LineNo)
            else
                TempWarehouseActivityLine.Delete();

        if WarehouseActivityLine."Qty. (Base)" <> 0 then begin
            WarehouseActivityLine."Line No." := LineNo;
            ProcessDoNotFillQtytoHandle(WarehouseActivityLine);
            IsHandled := false;
            OnBeforeWhseActivLineInsert(WarehouseActivityLine, CurrWarehouseActivityHeader, IsHandled);
            if not IsHandled then
                WarehouseActivityLine.Insert();
            OnAfterWhseActivLineInsert(WarehouseActivityLine);
        end;

        if CurrLocation."Bin Mandatory" then
            CreateWhseDocPlaceLine(WarehouseActivityLine.Quantity, WarehouseActivityLine."Qty. (Base)", LineNo);

        OnAfterCreateWhseDocLine(WarehouseActivityLine);
    end;

    local procedure CreateWhseDocTakeLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; var LineNo: Integer)
    var
        WarehouseActivityLine2: Record "Warehouse Activity Line";
        WarehouseActivityLine3: Record "Warehouse Activity Line";
        TempWarehouseActivityLine2: Record "Warehouse Activity Line" temporary;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateWhseDocTakeLineProcedure(WarehouseActivityLine, IsHandled);
        if IsHandled then
            exit;

        TempWarehouseActivityLine2.Copy(TempWarehouseActivityLine);
        TempWarehouseActivityLine.SetCurrentKey(
          "Whse. Document No.", "Whse. Document Type", "Activity Type", "Whse. Document Line No.", "Action Type");
        TempWarehouseActivityLine.Delete();

        TempWarehouseActivityLine.SetRange("Whse. Document Type", TempWarehouseActivityLine2."Whse. Document Type");
        TempWarehouseActivityLine.SetRange("Whse. Document No.", TempWarehouseActivityLine2."Whse. Document No.");
        TempWarehouseActivityLine.SetRange("Activity Type", TempWarehouseActivityLine2."Activity Type");
        TempWarehouseActivityLine.SetRange("Whse. Document Line No.", TempWarehouseActivityLine2."Whse. Document Line No.");
        TempWarehouseActivityLine.SetRange("Action Type", TempWarehouseActivityLine2."Action Type"::Take);
        TempWarehouseActivityLine.SetSourceFilter(
          TempWarehouseActivityLine2."Source Type", TempWarehouseActivityLine2."Source Subtype", TempWarehouseActivityLine2."Source No.",
          TempWarehouseActivityLine2."Source Line No.", TempWarehouseActivityLine2."Source Subline No.", false);
        TempWarehouseActivityLine.SetRange("No.", TempWarehouseActivityLine2."No.");
        TempWarehouseActivityLine.SetFilter("Line No.", '>%1', TempWarehouseActivityLine2."Line No.");
        TempWarehouseActivityLine.SetRange("Bin Code", TempWarehouseActivityLine2."Bin Code");
        TempWarehouseActivityLine.SetRange("Unit of Measure Code", WarehouseActivityLine."Unit of Measure Code");
        TempWarehouseActivityLine.SetRange("Zone Code");
        TempWarehouseActivityLine.SetRange("Breakbulk No.", 0);
        TempWarehouseActivityLine.SetTrackingFilterFromWhseActivityLine(TempWarehouseActivityLine2);
        OnCreateWhseDocTakeLineOnAfterSetFilters(TempWarehouseActivityLine, TempWarehouseActivityLine2, WarehouseActivityLine);
        if TempWarehouseActivityLine.Find('-') then begin
            repeat
                WarehouseActivityLine.Quantity := WarehouseActivityLine.Quantity + TempWarehouseActivityLine.Quantity;
            until TempWarehouseActivityLine.Next() = 0;
            TempWarehouseActivityLine.DeleteAll();
            WarehouseActivityLine.Validate(Quantity);
        end;

        // insert breakbulk lines
        if CurrLocation."Directed Put-away and Pick" then begin
            TempWarehouseActivityLine.ClearSourceFilter();
            TempWarehouseActivityLine.SetRange("Line No.");
            TempWarehouseActivityLine.SetRange("Unit of Measure Code");
            TempWarehouseActivityLine.SetFilter("Breakbulk No.", '<>0');
            if TempWarehouseActivityLine.Find('-') then
                repeat
                    WarehouseActivityLine2.Init();
                    WarehouseActivityLine2 := TempWarehouseActivityLine;
                    WarehouseActivityLine2."No." := CurrWarehouseActivityHeader."No.";
                    WarehouseActivityLine2."Line No." := LineNo;
                    WarehouseActivityLine2."Source Document" := WarehouseActivityLine."Source Document";

                    ProcessDoNotFillQtytoHandle(WarehouseActivityLine2);
                    OnCreateWhseDocTakeLineOnBeforeWhseActivLineInsert(WarehouseActivityLine2, CurrWarehouseActivityHeader, TempWarehouseActivityLine);
                    WarehouseActivityLine2.Insert();
                    OnAfterWhseActivLineInsert(WarehouseActivityLine2);

                    TempWarehouseActivityLine.Delete();
                    LineNo := LineNo + 10000;

                    WarehouseActivityLine3.Copy(TempWarehouseActivityLine);
                    TempWarehouseActivityLine.SetRange("Action Type", TempWarehouseActivityLine."Action Type"::Place);
                    TempWarehouseActivityLine.SetRange("Line No.");
                    TempWarehouseActivityLine.SetRange("Breakbulk No.", TempWarehouseActivityLine."Breakbulk No.");
                    TempWarehouseActivityLine.Find('-');

                    WarehouseActivityLine2.Init();
                    WarehouseActivityLine2 := TempWarehouseActivityLine;
                    WarehouseActivityLine2."No." := CurrWarehouseActivityHeader."No.";
                    WarehouseActivityLine2."Line No." := LineNo;
                    WarehouseActivityLine2."Source Document" := WarehouseActivityLine."Source Document";

                    ProcessDoNotFillQtytoHandle(WarehouseActivityLine2);

                    WarehouseActivityLine2."Original Breakbulk" :=
                      WarehouseActivityLine."Qty. (Base)" = WarehouseActivityLine2."Qty. (Base)";
                    if CreatePickParameters."Breakbulk Filter" then
                        WarehouseActivityLine2.Breakbulk := WarehouseActivityLine2."Original Breakbulk";
                    OnCreateWhseDocTakeLineOnBeforeWhseActivLine2Insert(WarehouseActivityLine2, CurrWarehouseActivityHeader, TempWarehouseActivityLine);
                    WarehouseActivityLine2.Insert();
                    OnAfterWhseActivLineInsert(WarehouseActivityLine2);

                    TempWarehouseActivityLine.Delete();
                    LineNo := LineNo + 10000;

                    TempWarehouseActivityLine.Copy(WarehouseActivityLine3);
                    WarehouseActivityLine."Original Breakbulk" := WarehouseActivityLine2."Original Breakbulk";
                    if CreatePickParameters."Breakbulk Filter" then
                        WarehouseActivityLine.Breakbulk := WarehouseActivityLine."Original Breakbulk";
                until TempWarehouseActivityLine.Next() = 0;
        end;

        TempWarehouseActivityLine.Copy(TempWarehouseActivityLine2);
    end;

    local procedure CreateWhseDocPlaceLine(PickQty: Decimal; PickQtyBase: Decimal; var LineNo: Integer)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        TempWarehouseActivityLine2: Record "Warehouse Activity Line" temporary;
        TempWarehouseActivityLine3: Record "Warehouse Activity Line" temporary;
        IsHandled: Boolean;
    begin
        TempWarehouseActivityLine2.Copy(TempWarehouseActivityLine);
        TempWarehouseActivityLine.SetCurrentKey(
          "Whse. Document No.", "Whse. Document Type", "Activity Type", "Whse. Document Line No.", "Action Type");
        TempWarehouseActivityLine.SetRange("Whse. Document No.", TempWarehouseActivityLine2."Whse. Document No.");
        TempWarehouseActivityLine.SetRange("Whse. Document Type", TempWarehouseActivityLine2."Whse. Document Type");
        TempWarehouseActivityLine.SetRange("Activity Type", TempWarehouseActivityLine2."Activity Type");
        TempWarehouseActivityLine.SetRange("Whse. Document Line No.", TempWarehouseActivityLine2."Whse. Document Line No.");
        TempWarehouseActivityLine.SetRange("Source Subline No.", TempWarehouseActivityLine2."Source Subline No.");
        TempWarehouseActivityLine.SetRange("No.", TempWarehouseActivityLine2."No.");
        TempWarehouseActivityLine.SetRange("Action Type", TempWarehouseActivityLine2."Action Type"::Place);
        TempWarehouseActivityLine.SetFilter("Line No.", '>%1', TempWarehouseActivityLine2."Line No.");
        TempWarehouseActivityLine.SetRange("Bin Code");
        TempWarehouseActivityLine.SetRange("Zone Code");
        TempWarehouseActivityLine.SetRange("Item No.", TempWarehouseActivityLine2."Item No.");
        TempWarehouseActivityLine.SetRange("Variant Code", TempWarehouseActivityLine2."Variant Code");
        TempWarehouseActivityLine.SetRange("Breakbulk No.", 0);
        TempWarehouseActivityLine.SetTrackingFilterFromWhseActivityLine(TempWarehouseActivityLine2);
        OnCreateWhseDocPlaceLineOnAfterSetFilters(TempWarehouseActivityLine, TempWarehouseActivityLine2, LineNo);
        if TempWarehouseActivityLine.Find('-') then
            repeat
                LineNo := LineNo + 10000;
                WarehouseActivityLine.Init();
                WarehouseActivityLine := TempWarehouseActivityLine;
                OnCreateWhseDocPlaceLineOnAfterTransferTempWhseActivLineToWhseActivLine(WarehouseActivityLine, TempWarehouseActivityLine, PickQty, PickQtyBase);

                if (PickQty * WarehouseActivityLine."Qty. per Unit of Measure") <> PickQtyBase then
                    PickQty := UnitOfMeasureManagement.RoundQty(PickQtyBase / WarehouseActivityLine."Qty. per Unit of Measure", WarehouseActivityLine."Qty. Rounding Precision");

                PickQtyBase := PickQtyBase - WarehouseActivityLine."Qty. (Base)";
                PickQty := PickQty - WarehouseActivityLine.Quantity;

                WarehouseActivityLine."No." := CurrWarehouseActivityHeader."No.";
                WarehouseActivityLine."Line No." := LineNo;

                if not (WarehouseActivityLine."Whse. Document Type" in [
                                                                WarehouseActivityLine."Whse. Document Type"::"Internal Pick",
                                                                WarehouseActivityLine."Whse. Document Type"::"Movement Worksheet"])
                then
                    WarehouseActivityLine."Source Document" := WhseManagement.GetWhseActivSourceDocument(WarehouseActivityLine."Source Type", WarehouseActivityLine."Source Subtype");

                TempWarehouseActivityLine.Delete();
                if PickQtyBase > 0 then begin
                    TempWarehouseActivityLine3.Copy(TempWarehouseActivityLine);
                    TempWarehouseActivityLine.SetRange(
                      "Unit of Measure Code", WarehouseActivityLine."Unit of Measure Code");
                    TempWarehouseActivityLine.SetFilter("Line No.", '>%1', TempWarehouseActivityLine."Line No.");
                    TempWarehouseActivityLine.SetRange("No.", TempWarehouseActivityLine2."No.");
                    TempWarehouseActivityLine.SetRange("Bin Code", WarehouseActivityLine."Bin Code");
                    OnCreateWhseDocPlaceLineOnAfterTempWhseActivLineSetFilters(TempWarehouseActivityLine, WarehouseActivityLine);
                    if TempWarehouseActivityLine.Find('-') then
                        repeat
                            if TempWarehouseActivityLine."Qty. (Base)" >= PickQtyBase then begin
                                WarehouseActivityLine.Quantity := WarehouseActivityLine.Quantity + PickQty;
                                WarehouseActivityLine."Qty. (Base)" := WarehouseActivityLine."Qty. (Base)" + PickQtyBase;
                                TempWarehouseActivityLine.Quantity -= PickQty;
                                TempWarehouseActivityLine."Qty. (Base)" -= PickQtyBase;
                                TempWarehouseActivityLine.Modify();
                                PickQty := 0;
                                PickQtyBase := 0;
                            end else begin
                                WarehouseActivityLine.Quantity := WarehouseActivityLine.Quantity + TempWarehouseActivityLine.Quantity;
                                WarehouseActivityLine."Qty. (Base)" := WarehouseActivityLine."Qty. (Base)" + TempWarehouseActivityLine."Qty. (Base)";
                                PickQty := PickQty - TempWarehouseActivityLine.Quantity;
                                PickQtyBase := PickQtyBase - TempWarehouseActivityLine."Qty. (Base)";
                                TempWarehouseActivityLine.Delete();
                            end;
                        until (TempWarehouseActivityLine.Next() = 0) or (PickQtyBase = 0)
                    else
                        if TempWarehouseActivityLine.Delete() then;
                    TempWarehouseActivityLine.Copy(TempWarehouseActivityLine3);
                end;

                if WarehouseActivityLine.Quantity > 0 then begin
                    TempWarehouseActivityLine3 := WarehouseActivityLine;
                    ValidateWhseActivLineQtyFIeldsFromCreateWhseDocPlaceLine(WarehouseActivityLine, TempWarehouseActivityLine3);

                    ProcessDoNotFillQtytoHandle(WarehouseActivityLine);
                    IsHandled := false;
                    OnCreateWhseDocPlaceLineOnBeforeWhseActivLineInsert(WarehouseActivityLine, IsHandled);
                    if not IsHandled then
                        WarehouseActivityLine.Insert();
                    OnAfterWhseActivLineInsert(WarehouseActivityLine);
                end;
            until (TempWarehouseActivityLine.Next() = 0) or (PickQtyBase = 0);

        TempWarehouseActivityLine.Copy(TempWarehouseActivityLine2);
    end;

    local procedure ProcessDoNotFillQtytoHandle(var WarehouseActivityLine: Record "Warehouse Activity Line")
    var
        IsHandled: Boolean;
    begin
        OnBeforeProcessDoNotFillQtytoHandle(WarehouseActivityLine, TempWarehouseActivityLine, CreatePickParameters, IsHandled);
        if not IsHandled then
            if CreatePickParameters."Do Not Fill Qty. to Handle" then begin
                WarehouseActivityLine."Qty. to Handle" := 0;
                WarehouseActivityLine."Qty. to Handle (Base)" := 0;
                WarehouseActivityLine.Cubage := 0;
                WarehouseActivityLine.Weight := 0;
            end;

        OnAfterProcessDoNotFillQtytoHandle(WarehouseActivityLine, TempWarehouseActivityLine);
    end;

    local procedure ValidateWhseActivLineQtyFIeldsFromCreateWhseDocPlaceLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; TempWarehouseActivityLine3: Record "Warehouse Activity Line" temporary)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateWhseActivLineQtyFIeldsFromCreateWhseDocPlaceLine(WarehouseActivityLine, IsHandled);
        if IsHandled then
            exit;

        WarehouseActivityLine.Validate(Quantity);
        WarehouseActivityLine."Qty. (Base)" := TempWarehouseActivityLine3."Qty. (Base)";
        WarehouseActivityLine."Qty. Outstanding (Base)" := TempWarehouseActivityLine3."Qty. (Base)";
        WarehouseActivityLine."Qty. to Handle (Base)" := TempWarehouseActivityLine3."Qty. (Base)";
    end;

    local procedure AssignSpecEquipment(LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]): Code[10]
    begin
        if (BinCode <> '') and
           (CurrLocation."Special Equipment" =
            CurrLocation."Special Equipment"::"According to Bin")
        then begin
            GetCurrBin(LocationCode, BinCode);
            if CurrBin."Special Equipment Code" <> '' then
                exit(CurrBin."Special Equipment Code");

            GetSKU(LocationCode, ItemNo, VariantCode);
            if CurrStockkeepingUnit."Special Equipment Code" <> '' then
                exit(CurrStockkeepingUnit."Special Equipment Code");

            GetItem(ItemNo);
            exit(CurrItem."Special Equipment Code");
        end;
        GetSKU(LocationCode, ItemNo, VariantCode);
        if CurrStockkeepingUnit."Special Equipment Code" <> '' then
            exit(CurrStockkeepingUnit."Special Equipment Code");

        GetItem(ItemNo);
        if CurrItem."Special Equipment Code" <> '' then
            exit(CurrItem."Special Equipment Code");

        GetCurrBin(LocationCode, BinCode);
        exit(CurrBin."Special Equipment Code");
    end;

    local procedure CalcAvailableQty(ItemNo: Code[20]; VariantCode: Code[10]): Decimal
    var
        AvailableQtyBase: Decimal;
        LineReservedQty: Decimal;
        QtyReservedOnPickShip: Decimal;
        QtyOnDedicatedBins: Decimal;
        WhseSource2: Option;
    begin
        // For locations with pick/ship and without directed put-away and pick
        GetItem(ItemNo);
        AvailableQtyBase := WarehouseAvailabilityMgt.CalcInvtAvailQty(CurrItem, CurrLocation, VariantCode, TempWarehouseActivityLine);
        OnCalcAvailableQtyOnAfterCalcAvailableQtyBase(
            CurrItem, CurrLocation, VariantCode, CurrSourceType, CurrSourceSubType, CurrSourceNo, CurrSourceLineNo, CurrSourceSubLineNo, AvailableQtyBase);

        if (CreatePickParameters."Whse. Document" = CreatePickParameters."Whse. Document"::Shipment) and CurrWarehouseShipmentLine."Assemble to Order" then
            WhseSource2 := CreatePickParameters."Whse. Document"::Assembly
        else
            WhseSource2 := CreatePickParameters."Whse. Document";

        case WhseSource2 of
            CreatePickParameters."Whse. Document"::"Pick Worksheet",
            CreatePickParameters."Whse. Document"::"Movement Worksheet":
                LineReservedQty :=
                  WarehouseAvailabilityMgt.CalcLineReservedQtyOnInvt(
                    CurrWhseWorksheetLine."Source Type", CurrWhseWorksheetLine."Source Subtype", CurrWhseWorksheetLine."Source No.",
                    CurrWhseWorksheetLine."Source Line No.", CurrWhseWorksheetLine."Source Subline No.", true, TempWarehouseActivityLine);
            CreatePickParameters."Whse. Document"::Shipment:
                LineReservedQty :=
                  WarehouseAvailabilityMgt.CalcLineReservedQtyOnInvt(
                    CurrWarehouseShipmentLine."Source Type", CurrWarehouseShipmentLine."Source Subtype", CurrWarehouseShipmentLine."Source No.",
                    CurrWarehouseShipmentLine."Source Line No.", 0, true, TempWarehouseActivityLine);
            CreatePickParameters."Whse. Document"::Job:
                LineReservedQty :=
                  WarehouseAvailabilityMgt.CalcLineReservedQtyOnInvt(
                    Database::Job, Enum::"Job Planning Line Status"::Order.AsInteger(), CurrJobPlanningLine."Job No.",
                    CurrJobPlanningLine."Job Contract Entry No.",
                    CurrJobPlanningLine."Line No.", true, TempWarehouseActivityLine);
            else
                OnCalcAvailableQtyOnGetLineReservedQty(
                    WhseSource2, CurrSourceSubType, CurrSourceNo, CurrSourceLineNo, CurrSourceSubLineNo, LineReservedQty, TempWarehouseActivityLine);
        end;

        QtyReservedOnPickShip := WarehouseAvailabilityMgt.CalcReservQtyOnPicksShips(CurrLocation.Code, ItemNo, VariantCode, TempWarehouseActivityLine);
        OnCalcAvailableQtyOnAfterCalcReservQtyOnPicksShips(QtyReservedOnPickShip, CurrLocation.Code, ItemNo, VariantCode, TempWarehouseActivityLine, LineReservedQty);
        QtyOnDedicatedBins := WarehouseAvailabilityMgt.CalcQtyOnDedicatedBins(CurrLocation.Code, ItemNo, VariantCode);

        exit(AvailableQtyBase + LineReservedQty + QtyReservedOnPickShip - QtyOnDedicatedBins);
    end;

    local procedure CalcPickQtyAssigned(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; UOMCode: Code[10]; BinCode: Code[20]; var TempWhseItemTrackingLine2: Record "Whse. Item Tracking Line" temporary) PickQtyAssigned: Decimal
    var
        WarehouseActivityLine2: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine2.Copy(TempWarehouseActivityLine);
        TempWarehouseActivityLine.Reset();
        TempWarehouseActivityLine.SetCurrentKey(
          TempWarehouseActivityLine."Item No.", TempWarehouseActivityLine."Bin Code", TempWarehouseActivityLine."Location Code", TempWarehouseActivityLine."Action Type", TempWarehouseActivityLine."Variant Code",
          TempWarehouseActivityLine."Unit of Measure Code", TempWarehouseActivityLine."Breakbulk No.", TempWarehouseActivityLine."Activity Type", TempWarehouseActivityLine."Lot No.", TempWarehouseActivityLine."Serial No.");
        TempWarehouseActivityLine.SetRange(TempWarehouseActivityLine."Item No.", ItemNo);
        TempWarehouseActivityLine.SetRange(TempWarehouseActivityLine."Location Code", LocationCode);
        if CurrLocation."Bin Mandatory" then begin
            TempWarehouseActivityLine.SetRange(TempWarehouseActivityLine."Action Type", TempWarehouseActivityLine."Action Type"::Take);
            if BinCode <> '' then
                TempWarehouseActivityLine.SetRange(TempWarehouseActivityLine."Bin Code", BinCode)
            else
                TempWarehouseActivityLine.SetFilter(TempWarehouseActivityLine."Bin Code", '<>%1', '');
        end else begin
            TempWarehouseActivityLine.SetRange(TempWarehouseActivityLine."Action Type", TempWarehouseActivityLine."Action Type"::" ");
            TempWarehouseActivityLine.SetRange(TempWarehouseActivityLine."Bin Code", '');
        end;
        TempWarehouseActivityLine.SetRange(TempWarehouseActivityLine."Variant Code", VariantCode);
        if UOMCode <> '' then
            TempWarehouseActivityLine.SetRange(TempWarehouseActivityLine."Unit of Measure Code", UOMCode);
        TempWarehouseActivityLine.SetRange(TempWarehouseActivityLine."Activity Type", TempWarehouseActivityLine."Activity Type");
        TempWarehouseActivityLine.SetRange(TempWarehouseActivityLine."Breakbulk No.", 0);
        if WhseItemTrkgExists then
            TempWarehouseActivityLine.SetTrackingFilterFromWhseItemTrackingLineIfNotBlank(TempWhseItemTrackingLine2);
        OnCalcQtyOutstandingBaseAfterSetFilters(TempWarehouseActivityLine, TempWhseItemTrackingLine2, LocationCode, ItemNo, VariantCode, UOMCode, BinCode);
        TempWarehouseActivityLine.CalcSums(TempWarehouseActivityLine."Qty. Outstanding (Base)");
        PickQtyAssigned := TempWarehouseActivityLine."Qty. Outstanding (Base)";
        TempWarehouseActivityLine.Copy(WarehouseActivityLine2);
        exit(PickQtyAssigned);
    end;

    local procedure CalcQtyAssignedToPick(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; BinCode: Code[20]; WhseItemTrackingSetup: Record "Item Tracking Setup"): Decimal
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.Reset();
        WarehouseActivityLine.SetCurrentKey(
          WarehouseActivityLine."Item No.", WarehouseActivityLine."Location Code", WarehouseActivityLine."Activity Type", WarehouseActivityLine."Bin Type Code",
          WarehouseActivityLine."Unit of Measure Code", WarehouseActivityLine."Variant Code", WarehouseActivityLine."Breakbulk No.", WarehouseActivityLine."Action Type");

        WarehouseActivityLine.SetRange(WarehouseActivityLine."Item No.", ItemNo);
        WarehouseActivityLine.SetRange(WarehouseActivityLine."Location Code", LocationCode);
        WarehouseActivityLine.SetRange(WarehouseActivityLine."Activity Type", WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.SetRange(WarehouseActivityLine."Variant Code", VariantCode);
        WarehouseActivityLine.SetRange(WarehouseActivityLine."Breakbulk No.", 0);
        WarehouseActivityLine.SetFilter(WarehouseActivityLine."Action Type", '%1|%2', WarehouseActivityLine."Action Type"::" ", WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.SetFilter(WarehouseActivityLine."Bin Code", BinCode);
        WarehouseActivityLine.SetTrackingFilterFromWhseItemTrackingSetupIfNotBlank(WhseItemTrackingSetup);
        OnCalcQtyAssignedToPickOnAfterSetFilters(WarehouseActivityLine, WhseItemTrackingSetup);
        WarehouseActivityLine.CalcSums(WarehouseActivityLine."Qty. Outstanding (Base)");

        exit(WarehouseActivityLine."Qty. Outstanding (Base)" + CalcBreakbulkOutstdQty(WarehouseActivityLine, WhseItemTrackingSetup));
    end;

    local procedure UseForPick(FromBinContent: Record "Bin Content") IsForPick: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUseForPick(FromBinContent, IsForPick, IsHandled);
        if IsHandled then
            exit(IsForPick);

        if FromBinContent."Block Movement" in [FromBinContent."Block Movement"::Outbound, FromBinContent."Block Movement"::All] then
            exit(false);

        GetBinType(FromBinContent."Bin Type Code");
        exit(CurrBinType.Pick);
    end;

    local procedure UseForReplenishment(FromBinContent: Record "Bin Content"): Boolean
    begin
        if FromBinContent."Block Movement" in [FromBinContent."Block Movement"::Outbound, FromBinContent."Block Movement"::All] then
            exit(false);

        GetBinType(FromBinContent."Bin Type Code");
        exit(not (CurrBinType.Receive or CurrBinType.Ship));
    end;

    procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            CurrLocation := WhseSetupLocation
        else
            if CurrLocation.Code <> LocationCode then
                CurrLocation.Get(LocationCode);

        OnAfterGetLocation(LocationCode);
    end;

    local procedure GetBinType(BinTypeCode: Code[10])
    begin
        if BinTypeCode = '' then begin
            Clear(CurrBinType);
            CurrBinType.Init();
        end else
            if CurrBinType.Code <> BinTypeCode then
                CurrBinType.Get(BinTypeCode);
    end;

    local procedure GetCurrBin(LocationCode: Code[10]; BinCode: Code[20])
    begin
        if (CurrBin."Location Code" <> LocationCode) or
           (CurrBin.Code <> BinCode)
        then
            if not CurrBin.Get(LocationCode, BinCode) then
                Clear(CurrBin);
    end;

    local procedure GetItem(ItemNo: Code[20])
    begin
        if CurrItem."No." <> ItemNo then
            CurrItem.Get(ItemNo);
    end;

    local procedure GetSKU(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]): Boolean
    begin
        if (CurrStockkeepingUnit."Location Code" <> LocationCode) or
           (CurrStockkeepingUnit."Item No." <> ItemNo) or
           (CurrStockkeepingUnit."Variant Code" <> VariantCode)
        then
            if not CurrStockkeepingUnit.Get(LocationCode, ItemNo, VariantCode) then begin
                Clear(CurrStockkeepingUnit);
                exit(false)
            end;
        exit(true);
    end;

    local procedure GetQtyInBinNotBlockedNotDedicatedWithoutItemTrackingFilter(LocationCode: Code[20]; ItemNo: Code[20]; Variantcode: Code[20]) QtyInBinNotBlockedNotDedicatedWithoutItemTrackingFilter: Decimal
    var
        CalcPickableQtyFromWhseEntry: Query CalcPickableQtyFromWhseEntry;
    begin
        if not ReqFEFOPick then
            exit;
        CalcPickableQtyFromWhseEntry.SetRange(Location_Code, LocationCode);
        CalcPickableQtyFromWhseEntry.SetRange(Item_No_, ItemNo);
        CalcPickableQtyFromWhseEntry.SetRange(Variant_Code, VariantCode);
        CalcPickableQtyFromWhseEntry.Open();
        if CalcPickableQtyFromWhseEntry.Read() then
            QtyInBinNotBlockedNotDedicatedWithoutItemTrackingFilter := CalcPickableQtyFromWhseEntry.TotalPickableQtyBase;
        CalcPickableQtyFromWhseEntry.Close();
        exit(QtyInBinNotBlockedNotDedicatedWithoutItemTrackingFilter);
    end;

    procedure SetParameters(NewCreatePickParameters: Record "Create Pick Parameters")
    begin
        CreatePickParameters := NewCreatePickParameters;
        if CreatePickParameters."Per Bin" then
            CreatePickParameters."Per Zone" := false
        else
            CreatePickParameters."Per Zone" := NewCreatePickParameters."Per Zone";
        WarehouseSetup.Get();
        WhseSetupLocation.GetLocationSetup('', WhseSetupLocation);
        Clear(TempWarehouseActivityLine);
        LastWhseItemTrkgLineNo := 0;
        IsMovementWorksheet := CreatePickParameters."Whse. Document" = CreatePickParameters."Whse. Document"::"Movement Worksheet";

        OnAfterSetParameters(CreatePickParameters);
    end;

    procedure SetWhseWkshLine(WhseWorksheetLine2: Record "Whse. Worksheet Line"; TempNo2: Integer)
    begin
        CurrWhseWorksheetLine := WhseWorksheetLine2;
        TempNo := TempNo2;
        SetSource(
            WhseWorksheetLine2."Source Type", WhseWorksheetLine2."Source Subtype", WhseWorksheetLine2."Source No.",
            WhseWorksheetLine2."Source Line No.", WhseWorksheetLine2."Source Subline No.");

        OnAfterSetWhseWkshLine(CurrWhseWorksheetLine);
    end;

    procedure SetWhseShipment(WarehouseShipmentLine2: Record "Warehouse Shipment Line"; TempNo2: Integer; ShippingAgentCode2: Code[10]; ShippingAgentServiceCode2: Code[10]; ShipmentMethodCode2: Code[10])
    begin
        CurrWarehouseShipmentLine := WarehouseShipmentLine2;
        TempNo := TempNo2;
        ShippingAgentCode := ShippingAgentCode2;
        ShippingAgentServiceCode := ShippingAgentServiceCode2;
        ShipmentMethodCode := ShipmentMethodCode2;
        SetSource(WarehouseShipmentLine2."Source Type", WarehouseShipmentLine2."Source Subtype", WarehouseShipmentLine2."Source No.", WarehouseShipmentLine2."Source Line No.", 0);

        OnAfterSetWhseShipment(CurrWarehouseShipmentLine, TempNo2, ShippingAgentCode, ShippingAgentServiceCode, ShipmentMethodCode);
    end;

    procedure SetWhseInternalPickLine(WhseInternalPickLine2: Record "Whse. Internal Pick Line"; TempNo2: Integer)
    begin
        CurrWhseInternalPickLine := WhseInternalPickLine2;
        TempNo := TempNo2;

        OnAfterSetWhseInternalPickLine(CurrWhseInternalPickLine);
    end;

#if not CLEAN27
    [Obsolete('Replaced by SetCustomWhseSourceLine', '27.0')]
    procedure SetProdOrderCompLine(ProdOrderComponentLine2: Record Microsoft.Manufacturing.Document."Prod. Order Component"; TempNo2: Integer)
    begin
        SetCustomWhseSourceLine(
            ProdOrderComponentLine2, TempNo2, Database::Microsoft.Manufacturing.Document."Prod. Order Component",
            ProdOrderComponentLine2.Status.AsInteger(), ProdOrderComponentLine2."Prod. Order No.",
            ProdOrderComponentLine2."Prod. Order Line No.", ProdOrderComponentLine2."Line No.");

        OnAfterSetProdOrderCompLine(ProdOrderComponentLine2);
        CustomWhseSourceLine := ProdOrderComponentLine2;
    end;
#endif

#if not CLEAN27
    [Obsolete('Replaced by SetCustomWhseSourceLine', '27.0')]
    procedure SetAssemblyLine(AssemblyLine2: Record Microsoft.Assembly.Document."Assembly Line"; TempNo2: Integer)
    begin
        SetCustomWhseSourceLine(
            AssemblyLine2, TempNo2, Database::Microsoft.Assembly.Document."Assembly Line",
            AssemblyLine2."Document Type".AsInteger(), AssemblyLine2."Document No.", AssemblyLine2."Line No.", 0);

        OnAfterSetAssemblyLine(AssemblyLine2);
        CustomWhseSourceLine := AssemblyLine2;
    end;
#endif

    procedure SetJobPlanningLine(JobPlanningLine2: Record "Job Planning Line")
    begin
        CurrJobPlanningLine := JobPlanningLine2;
        TempNo := 1;
        SetSource(
          Database::"Job Planning Line", Enum::"Job Planning Line Status"::Order.AsInteger(),
          JobPlanningLine2."Job No.", JobPlanningLine2."Job Contract Entry No.", JobPlanningLine2."Line No.");
    end;

    procedure SetCustomWhseSourceLine(CustomWhseSourceLine2: Variant; TempNo2: Integer; SourceType2: Integer; SourceSubType2: Option; SourceNo2: Code[20]; SourceLineNo2: Integer; SourceSubLineNo2: Integer)
    begin
        CustomWhseSourceLine := CustomWhseSourceLine2;
        TempNo := TempNo2;
        CurrSourceType := SourceType2;
        CurrSourceSubType := SourceSubType2;
        CurrSourceNo := SourceNo2;
        CurrSourceLineNo := SourceLineNo2;
        CurrSourceSubLineNo := SourceSubLineNo2;

        OnAfterSetCustomWhseSourceLine(CustomWhseSourceLine2);
    end;

    procedure SetTempWhseItemTrkgLine(SourceID: Code[20]; SrcType: Integer; SourceBatchName: Code[10]; SourceProdOrderLine: Integer; SourceRefNo: Integer; LocationCode: Code[10])
    var
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
    begin
        TempWhseItemTrackingLine.DeleteAll();
        TempWhseItemTrackingLine.Init();
        WhseItemTrkgLineCount := 0;
        WhseItemTrkgExists := false;
        WhseItemTrackingLine.Reset();
        WhseItemTrackingLine.SetCurrentKey(
          "Source ID", "Source Type", "Source Subtype", "Source Batch Name",
          "Source Prod. Order Line", "Source Ref. No.", "Location Code");
        WhseItemTrackingLine.SetRange("Source ID", SourceID);
        WhseItemTrackingLine.SetRange("Source Type", SrcType);
        WhseItemTrackingLine.SetRange("Source Batch Name", SourceBatchName);
        WhseItemTrackingLine.SetRange("Source Prod. Order Line", SourceProdOrderLine);
        WhseItemTrackingLine.SetRange("Source Ref. No.", SourceRefNo);
        WhseItemTrackingLine.SetRange("Location Code", LocationCode);
        if WhseItemTrackingLine.Find('-') then
            repeat
                if WhseItemTrackingLine."Qty. to Handle (Base)" > 0 then
                    CopyToTempWhseItemTrkgLine(WhseItemTrackingLine);
            until WhseItemTrackingLine.Next() = 0;

        OnAfterCreateTempWhseItemTrackingLines(TempWhseItemTrackingLine);

        SetSourceWhseItemTrkgLine(SourceID, SrcType, SourceBatchName, SourceProdOrderLine, SourceRefNo);
    end;

    procedure SetTempWhseItemTrkgLineFromBuffer(var TempWhseItemTrackingLineBuffer: Record "Whse. Item Tracking Line" temporary; SourceID: Code[20]; SrcType: Integer; SourceBatchName: Code[10]; SourceProdOrderLine: Integer; SourceRefNo: Integer; LocationCode: Code[10])
    begin
        TempWhseItemTrackingLine.DeleteAll();
        TempWhseItemTrackingLine.Init();
        WhseItemTrkgLineCount := 0;
        WhseItemTrkgExists := false;

        TempWhseItemTrackingLineBuffer.Reset();
        TempWhseItemTrackingLineBuffer.SetSourceFilter(SrcType, 0, SourceID, SourceRefNo, true);
        TempWhseItemTrackingLineBuffer.SetSourceFilter(SourceBatchName, SourceProdOrderLine);
        TempWhseItemTrackingLineBuffer.SetRange("Location Code", LocationCode);
        if TempWhseItemTrackingLineBuffer.FindSet() then
            repeat
                CopyToTempWhseItemTrkgLine(TempWhseItemTrackingLineBuffer);
            until TempWhseItemTrackingLineBuffer.Next() = 0;

        SetSourceWhseItemTrkgLine(SourceID, SrcType, SourceBatchName, SourceProdOrderLine, SourceRefNo);
    end;

    local procedure CopyToTempWhseItemTrkgLine(WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyToTempWhseItemTrkgLine(WhseItemTrackingLine, IsHandled);
        if IsHandled then
            exit;

        TempWhseItemTrackingLine := WhseItemTrackingLine;
        TempWhseItemTrackingLine."Entry No." := LastWhseItemTrkgLineNo + 1;
        OnCopyToTempWhseItemTrkgLineOnBeforeTempWhseItemTrackingLineInsert(TempWhseItemTrackingLine);
        TempWhseItemTrackingLine.Insert();
        LastWhseItemTrkgLineNo := TempWhseItemTrackingLine."Entry No.";
        WhseItemTrkgExists := true;
        WhseItemTrkgLineCount += 1;
    end;

    local procedure SetSourceWhseItemTrkgLine(SourceID: Code[20]; SrcType: Integer; SourceBatchName: Code[10]; SourceProdOrderLine: Integer; SourceRefNo: Integer)
    begin
        SourceWhseItemTrackingLine.Init();
        SourceWhseItemTrackingLine."Source Type" := SrcType;
        SourceWhseItemTrackingLine."Source ID" := SourceID;
        SourceWhseItemTrackingLine."Source Batch Name" := SourceBatchName;
        SourceWhseItemTrackingLine."Source Prod. Order Line" := SourceProdOrderLine;
        SourceWhseItemTrackingLine."Source Ref. No." := SourceRefNo;

        OnAfterSetSourceWhseItemTrkgLine(TempWhseItemTrackingLine, LastWhseItemTrkgLineNo);
    end;

    procedure SaveTempItemTrkgLines()
    var
        i: Integer;
        isHandled: Boolean;
    begin
        if WhseItemTrkgLineCount = 0 then
            exit;

        OnBeforeSaveTempItemTrkgLines(isHandled);
        if isHandled then
            exit;

        i := 0;
        TempWhseItemTrackingLine.Reset();
        if TempWhseItemTrackingLine.Find('-') then
            repeat
                TempTotalWhseItemTrackingLine := TempWhseItemTrackingLine;
                TempTotalWhseItemTrackingLine.Insert();
                i += 1;
            until (TempWhseItemTrackingLine.Next() = 0) or (i = WhseItemTrkgLineCount);
    end;

    procedure ReturnTempItemTrkgLines(var TempWhseItemTrackingLine2: Record "Whse. Item Tracking Line" temporary)
    begin
        if TempTotalWhseItemTrackingLine.Find('-') then
            repeat
                TempWhseItemTrackingLine2 := TempTotalWhseItemTrackingLine;
                TempWhseItemTrackingLine2.Insert();
            until TempTotalWhseItemTrackingLine.Next() = 0;
    end;

    local procedure CreateTempItemTrkgLines(ItemNo: Code[20]; VariantCode: Code[10]; UnitofMeasureCode: Code[10]; TotalQtyToPickBase: Decimal; HasExpiryDate: Boolean)
    var
        EntrySummary: Record "Entry Summary";
        DummyEntrySummary2: Record "Entry Summary";
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        WhseItemTrackingFEFO: Codeunit "Whse. Item Tracking FEFO";
        TotalAvailQtyToPickBase: Decimal;
        RemQtyToPickBase: Decimal;
        QtyToPickBase: Decimal;
        QtyTracked: Decimal;
        FromBinContentQty: Decimal;
        QtyCanBePicked: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateTempItemTrkgLines(CurrLocation, ItemNo, VariantCode, TotalQtyToPickBase, HasExpiryDate, IsHandled, WhseItemTrackingFEFO, CurrWarehouseShipmentLine, CurrWhseWorksheetLine);
        if IsHandled then
            exit;

        if not HasExpiryDate then
            if TotalQtyToPickBase <= 0 then
                exit;

        WhseItemTrackingFEFO.SetSource(CurrSourceType, CurrSourceSubType, CurrSourceNo, CurrSourceLineNo, CurrSourceSubLineNo);
        WhseItemTrackingFEFO.SetCalledFromMovementWksh(CalledFromMoveWksh);
        if IsPickByExactRequestedUnitOfMeasure() then
            WhseItemTrackingFEFO.CreateEntrySummaryFEFO(CurrLocation, ItemNo, VariantCode, UnitofMeasureCode, HasExpiryDate)
        else
            WhseItemTrackingFEFO.CreateEntrySummaryFEFO(CurrLocation, ItemNo, VariantCode, HasExpiryDate);

        RemQtyToPickBase := TotalQtyToPickBase;
        if HasExpiryDate then
            TransferRemQtyToPickBase := TotalQtyToPickBase;
        if WhseItemTrackingFEFO.FindFirstEntrySummaryFEFO(EntrySummary) then begin
            ReqFEFOPick := true;
            repeat
                OnCreateTempItemTrkgLinesOnLoopEntrySummaryFEFOBeforeCheckExpirationDate(EntrySummary, CurrSourceType, CurrSourceSubType, CurrSourceNo, CurrSourceLineNo, CurrSourceSubLineNo);
                if ((EntrySummary."Expiration Date" <> 0D) and HasExpiryDate) or
                   ((EntrySummary."Expiration Date" = 0D) and (not HasExpiryDate))
                then begin
                    WhseItemTrackingSetup.CopyTrackingFromEntrySummary(EntrySummary);
                    QtyTracked := ItemTrackedQuantity(WhseItemTrackingSetup);
                    OnCreateTempItemTrkgLinesOnAfterCalcQtyTracked(EntrySummary, TempWhseItemTrackingLine, QtyTracked);

                    if not ((EntrySummary."Serial No." <> '') and (QtyTracked > 0)) then begin
                        WhseItemTrackingLine.CopyTrackingFromEntrySummary(EntrySummary);
                        TotalAvailQtyToPickBase :=
                            CalcTotalAvailQtyToPick(
                                CurrLocation.Code, ItemNo, VariantCode, WhseItemTrackingLine,
                                CurrSourceType, CurrSourceSubType, CurrSourceNo, CurrSourceLineNo, CurrSourceSubLineNo, 0, HasExpiryDate);

                        OnCreateTempItemTrkgLinesOnBeforeGetFromBinContentQty(EntrySummary, ItemNo, VariantCode, TotalAvailQtyToPickBase);
                        if CalledFromWksh and (CurrWhseWorksheetLine."From Bin Code" <> '') then begin
                            FromBinContentQty :=
                                GetFromBinContentQty(
                                    CurrWhseWorksheetLine."Location Code", CurrWhseWorksheetLine."From Bin Code", CurrWhseWorksheetLine."Item No.",
                                    CurrWhseWorksheetLine."Variant Code", CurrWhseWorksheetLine."From Unit of Measure Code", WhseItemTrackingLine);
                            if TotalAvailQtyToPickBase > FromBinContentQty then
                                TotalAvailQtyToPickBase := FromBinContentQty;
                        end;

                        QtyCanBePicked :=
                            CalcQtyCanBePicked(CurrLocation.Code, ItemNo, VariantCode, EntrySummary, CalledFromMoveWksh);
                        TotalAvailQtyToPickBase := Minimum(TotalAvailQtyToPickBase, QtyCanBePicked);

                        TotalAvailQtyToPickBase := TotalAvailQtyToPickBase - QtyTracked;
                        QtyToPickBase := 0;

                        OnBeforeInsertTempItemTrkgLine(EntrySummary, RemQtyToPickBase, TotalAvailQtyToPickBase);

                        if TotalAvailQtyToPickBase > 0 then
                            if TotalAvailQtyToPickBase >= RemQtyToPickBase then begin
                                QtyToPickBase := RemQtyToPickBase;
                                RemQtyToPickBase := 0
                            end else begin
                                QtyToPickBase := TotalAvailQtyToPickBase;
                                RemQtyToPickBase := RemQtyToPickBase - QtyToPickBase;
                            end;

                        OnCreateTempItemTrkgLinesOnBeforeCheckQtyToPickBase(EntrySummary, ItemNo, VariantCode, CurrLocation.Code, TotalAvailQtyToPickBase, QtyToPickBase);
                        if QtyToPickBase > 0 then
                            InsertTempItemTrkgLine(CurrLocation.Code, ItemNo, VariantCode, EntrySummary, QtyToPickBase);
                    end;
                end;
            until not WhseItemTrackingFEFO.FindNextEntrySummaryFEFO(EntrySummary) or (RemQtyToPickBase = 0);
            if HasExpiryDate then
                TransferRemQtyToPickBase := RemQtyToPickBase;
        end;
        if not HasExpiryDate then
            if RemQtyToPickBase > 0 then
                if CurrLocation."Always Create Pick Line" then
                    InsertTempItemTrkgLine(CurrLocation.Code, ItemNo, VariantCode, DummyEntrySummary2, RemQtyToPickBase);
        if not HasExpiredItems then begin
            HasExpiredItems := WhseItemTrackingFEFO.GetHasExpiredItems();
            EnqueueCannotBeHandledReason(WhseItemTrackingFEFO.GetResultMessageForExpiredItem());
        end;
    end;

    local procedure IsPickByExactRequestedUnitOfMeasure(): Boolean
    begin
        exit(CurrLocation."Directed Put-away and Pick" and (not CurrLocation."Allow Breakbulk"));
    end;

    procedure ItemTrackedQuantity(WhseItemTrackingSetup: Record "Item Tracking Setup"): Decimal
    var
        QtyToHandleBase: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeItemTrackedQuantity(TempWhseItemTrackingLine, WhseItemTrackingSetup, QtyToHandleBase, IsHandled);
        if IsHandled then
            exit(QtyToHandleBase);

        TempWhseItemTrackingLine.Reset();
        if not WhseItemTrackingSetup.TrackingExists() then
            if TempWhseItemTrackingLine.IsEmpty() then
                exit(0);

        if WhseItemTrackingSetup."Serial No." <> '' then begin
            TempWhseItemTrackingLine.SetTrackingKey();
            TempWhseItemTrackingLine.SetRange("Serial No.", WhseItemTrackingSetup."Serial No.");
            if TempWhseItemTrackingLine.IsEmpty() then
                exit(0);

            exit(1);
        end;

        if WhseItemTrackingSetup."Lot No." <> '' then begin
            TempWhseItemTrackingLine.SetTrackingKey();
            TempWhseItemTrackingLine.SetRange("Lot No.", WhseItemTrackingSetup."Lot No.");
            if TempWhseItemTrackingLine.IsEmpty() then
                exit(0);
        end;

        IsHandled := false;
        OnItemTrackedQuantityOnAfterCheckIfEmpty(TempWhseItemTrackingLine, WhseItemTrackingSetup, IsHandled);
        if IsHandled then
            exit(0);

        TempWhseItemTrackingLine.SetCurrentKey(
            "Source ID", "Source Type", "Source Subtype", "Source Batch Name",
            "Source Prod. Order Line", "Source Ref. No.", "Location Code");

        if WhseItemTrackingSetup."Lot No." <> '' then
            TempWhseItemTrackingLine.SetRange("Lot No.", WhseItemTrackingSetup."Lot No.");
        OnItemTrackedQuantityOnAfterSetFilters(TempWhseItemTrackingLine, WhseItemTrackingSetup);
        TempWhseItemTrackingLine.CalcSums("Qty. to Handle (Base)");
        exit(TempWhseItemTrackingLine."Qty. to Handle (Base)");
    end;

    procedure InsertTempItemTrkgLine(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; EntrySummary: Record "Entry Summary"; QuantityBase: Decimal)
    begin
        TempWhseItemTrackingLine.Init();
        TempWhseItemTrackingLine."Entry No." := LastWhseItemTrkgLineNo + 1;
        TempWhseItemTrackingLine."Location Code" := LocationCode;
        TempWhseItemTrackingLine."Item No." := ItemNo;
        TempWhseItemTrackingLine."Variant Code" := VariantCode;
        TempWhseItemTrackingLine.CopyTrackingFromEntrySummary(EntrySummary);
        TempWhseItemTrackingLine."Expiration Date" := EntrySummary."Expiration Date";
        TempWhseItemTrackingLine."Source ID" := SourceWhseItemTrackingLine."Source ID";
        TempWhseItemTrackingLine."Source Type" := SourceWhseItemTrackingLine."Source Type";
        TempWhseItemTrackingLine."Source Batch Name" := SourceWhseItemTrackingLine."Source Batch Name";
        TempWhseItemTrackingLine."Source Prod. Order Line" := SourceWhseItemTrackingLine."Source Prod. Order Line";
        TempWhseItemTrackingLine."Source Ref. No." := SourceWhseItemTrackingLine."Source Ref. No.";
        TempWhseItemTrackingLine.Validate(TempWhseItemTrackingLine."Quantity (Base)", QuantityBase);
        OnBeforeTempWhseItemTrkgLineInsert(TempWhseItemTrackingLine, SourceWhseItemTrackingLine, EntrySummary);
        TempWhseItemTrackingLine.Insert();
        LastWhseItemTrkgLineNo := TempWhseItemTrackingLine."Entry No.";
        WhseItemTrkgExists := true;
    end;

    local procedure TransferItemTrkgFields(var WarehouseActivityLine2: Record "Warehouse Activity Line"; TempWhseItemTrackingLine2: Record "Whse. Item Tracking Line" temporary)
    var
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        EntriesExist: Boolean;
    begin
        if WhseItemTrkgExists then begin
            if TempWhseItemTrackingLine2."Serial No." <> '' then
                ValidateQtyForSN(TempWhseItemTrackingLine2);
            WarehouseActivityLine2.CopyTrackingFromWhseItemTrackingLine(TempWhseItemTrackingLine2);
            WarehouseActivityLine2."Warranty Date" := TempWhseItemTrackingLine2."Warranty Date";
            if TempWhseItemTrackingLine2.TrackingExists() then begin
                WarehouseActivityLine2."Expiration Date" := ItemTrackingManagement.ExistingExpirationDate(WarehouseActivityLine2, false, EntriesExist);
                if not EntriesExist then
                    WarehouseActivityLine2."Expiration Date" := TempWhseItemTrackingLine2."Expiration Date";
            end;
            OnAfterTransferItemTrkgFields(WarehouseActivityLine2, TempWhseItemTrackingLine2, EntriesExist);
        end else begin
            ItemTrackingManagement.GetWhseItemTrkgSetup(TempWhseItemTrackingLine2."Item No.", WhseItemTrackingSetup);
            if WhseItemTrackingSetup."Serial No. Required" then
                WarehouseActivityLine2.ValidateQtyWhenSNDefined();
        end;
    end;

    local procedure ValidateQtyForSN(WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateQtyForSN(WhseItemTrackingLine, IsHandled);
        if IsHandled then
            exit;

        if not (WhseItemTrackingLine."Quantity (Base)" in [-1, 0, 1]) then
            Error(ValidValuesIfSNDefinedErr, WhseItemTrackingLine.FieldCaption("Quantity (Base)"), WhseItemTrackingLine."Quantity (Base)");

        if not (WhseItemTrackingLine."Qty. to Handle (Base)" in [-1, 0, 1]) then
            Error(ValidValuesIfSNDefinedErr, WhseItemTrackingLine.FieldCaption("Qty. to Handle (Base)"), WhseItemTrackingLine."Qty. to Handle (Base)");
    end;

    procedure SetSource(SourceType2: Integer; SourceSubType2: Option; SourceNo2: Code[20]; SourceLineNo2: Integer; SourceSubLineNo2: Integer)
    begin
        CurrSourceType := SourceType2;
        CurrSourceSubType := SourceSubType2;
        CurrSourceNo := SourceNo2;
        CurrSourceLineNo := SourceLineNo2;
        CurrSourceSubLineNo := SourceSubLineNo2;
        OnAfterSetSource(CurrSourceType, CurrSourceSubType, CurrSourceNo, CurrSourceLineNo, CurrSourceSubLineNo);
    end;

    local procedure ShowErrorWhenNoTempWarehouseActivityLineExists()
    var
        NothingToHandleErrorInfo: ErrorInfo;
        CannotHandleReason: Text;
        ErrorMsgText: Text;
    begin
        CannotHandleReason := DequeueCannotBeHandledReason();
        if CannotHandleReason = '' then
            ErrorMsgText := NothingToHandleWithoutReasonErr
        else
            ErrorMsgText := StrSubstNo(NothingToHandleErr, CannotHandleReason);

        if CanSaveSummary() then //Show the summary page when possible
            SetSummaryPageMessage(ErrorMsgText, false)
        else begin
            NothingToHandleErrorInfo.Verbosity := Verbosity::Error;

            if CurrLocation."Directed Put-away and Pick" then
                NothingToHandleErrorInfo.Message := ErrorMsgText + '\' + NothingToHandleTryShowSummaryLbl
            else
                NothingToHandleErrorInfo.Message := ErrorMsgText;

            Error(NothingToHandleErrorInfo);
        end;
    end;

    local procedure FindReservationEntries(var ReservationEntry: Record "Reservation Entry"; SrcType: Integer; SrcSubType: Option; SrcNo: Code[20]; SrcLineNo: Integer; SrcSubLineNo: Integer): Boolean
    begin
        SetFiltersOnReservEntry(ReservationEntry, SrcType, SrcSubType, SrcNo, SrcLineNo, SrcSubLineNo);
        exit(ReservationEntry.FindSet());
    end;

    local procedure IsReservationExists(SrcType: Integer; SrcSubType: Option; SrcNo: Code[20]; SrcLineNo: Integer; SrcSubLineNo: Integer): Boolean
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        SetFiltersOnReservEntry(ReservationEntry, SrcType, SrcSubType, SrcNo, SrcLineNo, SrcSubLineNo);
        exit(not ReservationEntry.IsEmpty());
    end;

    procedure CheckReservation(QtyBaseAvailToPick: Decimal; SrcType: Integer; SrcSubType: Option; SrcNo: Code[20]; SrcLineNo: Integer; SrcSubLineNo: Integer; AlwaysCreatePickLine: Boolean; QtyPerUnitOfMeasure: Decimal; var Quantity: Decimal; var QuantityBase: Decimal)
    var
        ReservationEntry: Record "Reservation Entry";
        Quantity2: Decimal;
        QuantityBase2: Decimal;
        QtyBaseResvdNotOnILE: Decimal;
        QtyResvdNotOnILE: Decimal;
        SrcDocQtyBaseToBeFilledByInvt: Decimal;
        SrcDocQtyToBeFilledByInvt: Decimal;
    begin
        ReservationExists := false;
        ReservedForItemLedgEntry := false;
        Quantity2 := Quantity;
        QuantityBase2 := QuantityBase;

        ReservationEntry.SetLoadFields("Entry No.", Positive);
        if FindReservationEntries(ReservationEntry, SrcType, SrcSubType, SrcNo, SrcLineNo, SrcSubLineNo) then begin
            ReservationExists := true;
            repeat
                QtyResvdNotOnILE += CalcQtyResvdNotOnILE(ReservationEntry."Entry No.", ReservationEntry.Positive);
            until ReservationEntry.Next() = 0;
            QtyBaseResvdNotOnILE := QtyResvdNotOnILE;
            QtyResvdNotOnILE := Round(QtyResvdNotOnILE / QtyPerUnitOfMeasure, UnitOfMeasureManagement.QtyRndPrecision());

            WhseManagement.GetOutboundDocLineQtyOtsdg(SrcType, SrcSubType,
              SrcNo, SrcLineNo, SrcSubLineNo, SrcDocQtyToBeFilledByInvt, SrcDocQtyBaseToBeFilledByInvt);
            OnCheckReservationOnAfterGetOutboundDocLineQtyOtsdg(ReservationEntry, SrcDocQtyToBeFilledByInvt, SrcDocQtyBaseToBeFilledByInvt, QtyResvdNotOnILE, QtyBaseResvdNotOnILE);
            SrcDocQtyBaseToBeFilledByInvt := SrcDocQtyBaseToBeFilledByInvt - QtyBaseResvdNotOnILE;
            SrcDocQtyToBeFilledByInvt := SrcDocQtyToBeFilledByInvt - QtyResvdNotOnILE;

            if QuantityBase > SrcDocQtyBaseToBeFilledByInvt then begin
                QuantityBase := SrcDocQtyBaseToBeFilledByInvt;
                Quantity := SrcDocQtyToBeFilledByInvt;
            end;

            if QuantityBase <= SrcDocQtyBaseToBeFilledByInvt then
                if (QuantityBase > QtyBaseAvailToPick) and (QtyBaseAvailToPick >= 0) then begin
                    QuantityBase := QtyBaseAvailToPick;
                    Quantity := Round(QtyBaseAvailToPick / QtyPerUnitOfMeasure, UnitOfMeasureManagement.QtyRndPrecision());
                end;

            ReservedForItemLedgEntry := QuantityBase <> 0;
            if AlwaysCreatePickLine then begin
                Quantity := Quantity2;
                QuantityBase := QuantityBase2;
            end;

            if Quantity <= 0 then
                EnqueueCannotBeHandledReason(GetMessageForUnhandledQtyDueToReserv());
        end else
            ReservationExists := false;

        OnAfterCheckReservation(Quantity, QuantityBase, QtyBaseAvailToPick, ReservationExists, SrcType, SrcSubType, SrcNo, SrcLineNo, SrcSubLineNo);
    end;

    procedure CalcTotalAvailQtyToPick(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; SrcType: Integer; SrcSubType: Option; SrcNo: Code[20]; SrcLineNo: Integer; SrcSubLineNo: Integer; NeededQtyBase: Decimal; RespectLocationBins: Boolean): Decimal
    var
        DummyWhseItemTrackingLine: Record "Whse. Item Tracking Line";
    begin
        exit(
            CalcTotalAvailQtyToPick(
                LocationCode, ItemNo, VariantCode, DummyWhseItemTrackingLine,
                SrcType, SrcSubType, SrcNo, SrcLineNo, SrcSubLineNo, NeededQtyBase, RespectLocationBins));
    end;

    procedure CalcTotalAvailQtyToPick(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; WhseItemTrackingLine: Record "Whse. Item Tracking Line"; SrcType: Integer; SrcSubType: Option; SrcNo: Code[20]; SrcLineNo: Integer; SrcSubLineNo: Integer; NeededQtyBase: Decimal; RespectLocationBins: Boolean): Decimal
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        TempWhseItemTrackingLine2: Record "Whse. Item Tracking Line" temporary;
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        TotalAvailQtyBase: Decimal;
        QtyInWhse: Decimal;
        QtyOnPickBins: Decimal;
        QtyOnPutAwayBins: Decimal;
        QtyOnOutboundBins: Decimal;
        QtyOnReceiveBins: Decimal;
        QtyOnDedicatedBins: Decimal;
        QtyBlocked: Decimal;
        SubTotal: Decimal;
        QtyReservedOnPickShip: Decimal;
        LineReservedQty: Decimal;
        QtyAssignedPick: Decimal;
        QtyAssignedToPick: Decimal;
        AvailableAfterReshuffle: Decimal;
        QtyOnToBinsBase: Decimal;
        ReservedQtyOnInventory: Decimal;
        ResetWhseItemTrkgExists: Boolean;
        BinTypeFilter: Text[1024];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcTotalAvailQtyToPick(
          LocationCode, ItemNo, VariantCode, WhseItemTrackingLine."Lot No.", WhseItemTrackingLine."Serial No.",
          SrcType, SrcSubType, SrcNo, SrcLineNo, SrcSubLineNo,
          NeededQtyBase, RespectLocationBins, CalledFromMoveWksh, CalledFromWksh, TempWarehouseActivityLine, IsHandled, TotalAvailQtyBase, WhseItemTrackingLine);
        if IsHandled then
            exit(TotalAvailQtyBase);

        // Directed put-away and pick
        GetLocation(LocationCode);
        if CurrLocation."Directed Put-away and Pick" then
            exit(CalcTotalAvailQtyToPickForDirectedPutAwayPick(LocationCode, ItemNo, VariantCode, WhseItemTrackingLine, SrcType, SrcSubType, SrcNo, SrcLineNo, SrcSubLineNo, NeededQtyBase));

        ItemTrackingManagement.GetWhseItemTrkgSetup(ItemNo, WhseItemTrackingSetup);
        OnCalcTotalAvailQtyToPickOnAfterGetWhseItemTrkgSetup(WhseItemTrackingSetup, LocationCode);
        WhseItemTrackingSetup.CopyTrackingFromWhseItemTrackingLine(WhseItemTrackingLine);

        ReservedQtyOnInventory :=
            CalcReservedQtyOnInventory(ItemNo, LocationCode, VariantCode, WhseItemTrackingSetup);

        QtyAssignedToPick :=
            CalcQtyAssignedToPick(ItemNo, LocationCode, VariantCode, '', WhseItemTrackingSetup);

        QtyInWhse :=
            SumWhseEntries(ItemNo, LocationCode, VariantCode, WhseItemTrackingSetup, '', '', false);

        // calculate quantity in receipt area and fixed receipt bin at location
        // quantity in pick bins is considered as total quantity on the warehouse excluding receipt area and fixed receipt bin
        CalcQtyOnPickAndReceiveBins(
            QtyOnReceiveBins, QtyOnPickBins, ItemNo, LocationCode, VariantCode, WhseItemTrackingSetup, RespectLocationBins);

        OnAfterCalcQtyOnPickAndReceiveBins(
            SrcType, LocationCode, ItemNo, VariantCode, WhseItemTrackingLine."Lot No.", WhseItemTrackingLine."Serial No.",
            CalledFromPickWksh, CalledFromMoveWksh, CalledFromWksh,
            QtyInWhse, QtyOnPickBins, QtyOnPutAwayBins, QtyOnOutboundBins, QtyOnReceiveBins, QtyOnDedicatedBins, QtyBlocked);

        if CalledFromMoveWksh then begin
            BinTypeFilter := GetBinTypeFilter(4); // put-away only
            if BinTypeFilter <> '' then
                QtyOnPutAwayBins :=
                    SumWhseEntries(
                        ItemNo, LocationCode, VariantCode, WhseItemTrackingSetup, BinTypeFilter, '', false);

            CalcQtyOnToBinsBase(WhseItemTrackingSetup, QtyOnToBinsBase, LocationCode, ItemNo, VariantCode);
        end;

        QtyOnOutboundBins := WarehouseAvailabilityMgt.CalcQtyOnOutboundBins(LocationCode, ItemNo, VariantCode, WhseItemTrackingSetup, true);

        QtyOnDedicatedBins := WarehouseAvailabilityMgt.CalcQtyOnDedicatedBins(LocationCode, ItemNo, VariantCode, WhseItemTrackingSetup);

        QtyBlocked := WarehouseAvailabilityMgt.CalcQtyOnBlockedITOrOnBlockedOutbndBins(LocationCode, ItemNo, VariantCode, WhseItemTrackingSetup);

        TempWhseItemTrackingLine2.Copy(TempWhseItemTrackingLine);
        if ReqFEFOPick then begin
            TempWhseItemTrackingLine2."Entry No." := TempWhseItemTrackingLine2."Entry No." + 1;
            TempWhseItemTrackingLine2.CopyTrackingFromWhseItemTrackingLine(WhseItemTrackingLine);
            if not WhseItemTrkgExists then begin
                WhseItemTrkgExists := true;
                ResetWhseItemTrkgExists := true;
            end;
        end;

        QtyAssignedPick := CalcPickQtyAssigned(LocationCode, ItemNo, VariantCode, '', '', TempWhseItemTrackingLine2);

        if ResetWhseItemTrkgExists then begin
            WhseItemTrkgExists := false;
            ResetWhseItemTrkgExists := false;
        end;

        if CurrLocation."Always Create Pick Line" or CrossDock then begin
            FilterWhsePickLinesWithUndefinedBin(WarehouseActivityLine, ItemNo, LocationCode, VariantCode, WhseItemTrackingSetup);
            WarehouseActivityLine.CalcSums("Qty. Outstanding (Base)");
            QtyAssignedPick := QtyAssignedPick - WarehouseActivityLine."Qty. Outstanding (Base)";
        end;

        OnCalcTotalAvailQtyToPickOnBeforeCalcSubTotal(QtyInWhse, QtyOnPickBins, QtyOnPutAwayBins, QtyOnOutboundBins, QtyOnDedicatedBins, QtyBlocked, QtyOnReceiveBins, ReservedQtyOnInventory);
        SubTotal :=
          QtyInWhse - QtyOnPickBins - QtyOnPutAwayBins - QtyOnOutboundBins - QtyOnDedicatedBins - QtyBlocked -
          QtyOnReceiveBins - Abs(ReservedQtyOnInventory);

        if (SubTotal < 0) or CalledFromPickWksh or CalledFromMoveWksh then begin
            TempTrackingSpecification.CopyTrackingFromWhseItemTrackingLine(WhseItemTrackingLine);
            QtyReservedOnPickShip :=
                WarehouseAvailabilityMgt.CalcReservQtyOnPicksShipsWithItemTracking(TempWarehouseActivityLine, TempTrackingSpecification, LocationCode, ItemNo, VariantCode);

            if WhseItemTrackingLine.TrackingExists() and (QtyReservedOnPickShip > 0) then
                LineReservedQty :=
                    WarehouseAvailabilityMgt.CalcLineReservedQtyOnInvt(
                      SrcType, SrcSubType, SrcNo, SrcLineNo, SrcSubLineNo, true, WhseItemTrackingSetup, TempWarehouseActivityLine)
            else
                LineReservedQty :=
                    WarehouseAvailabilityMgt.CalcLineReservedQtyOnInvt(
                      SrcType, SrcSubType, SrcNo, SrcLineNo, SrcSubLineNo, true, TempWarehouseActivityLine);

            AdjustQtyReservedOnPickShip(SubTotal, QtyReservedOnPickShip, LineReservedQty, ReservedQtyOnInventory);

            case true of
                CalledFromPickWksh:
                    begin
                        TotalAvailQtyBase :=
                            QtyOnPickBins - QtyAssignedToPick - Abs(ReservedQtyOnInventory) + QtyReservedOnPickShip + LineReservedQty;
                        MovementFromShipZone(TotalAvailQtyBase, QtyOnOutboundBins + QtyBlocked);
                    end;
                CalledFromMoveWksh:
                    begin
                        TotalAvailQtyBase :=
                            QtyOnPickBins + QtyOnPutAwayBins - QtyAssignedToPick;
                        if CalledFromWksh then
                            TotalAvailQtyBase := TotalAvailQtyBase - QtyAssignedPick - QtyOnPutAwayBins;
                        MovementFromShipZone(TotalAvailQtyBase, QtyOnOutboundBins + QtyBlocked);
                    end;
                else
                    TotalAvailQtyBase :=
                      QtyOnPickBins -
                      QtyAssignedPick - QtyAssignedToPick +
                      SubTotal +
                      QtyReservedOnPickShip +
                      LineReservedQty;
            end
        end else
            TotalAvailQtyBase := QtyOnPickBins - QtyAssignedPick - QtyAssignedToPick;

        if (NeededQtyBase <> 0) and (NeededQtyBase > TotalAvailQtyBase) then
            if ReleaseNonSpecificReservations(LocationCode, ItemNo, VariantCode, WhseItemTrackingSetup, NeededQtyBase - TotalAvailQtyBase) then begin
                AvailableAfterReshuffle :=
                    CalcTotalAvailQtyToPick(
                        LocationCode, ItemNo, VariantCode, TempWhseItemTrackingLine,
                        SrcType, SrcSubType, SrcNo, SrcLineNo, SrcSubLineNo, 0, false);
                exit(AvailableAfterReshuffle);
            end;

        exit(TotalAvailQtyBase - QtyOnToBinsBase);
    end;

    local procedure CalcTotalAvailQtyToPickForDirectedPutAwayPick(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; WhseItemTrackingLine: Record "Whse. Item Tracking Line"; SrcType: Integer; SrcSubType: Option; SrcNo: Code[20]; SrcLineNo: Integer; SrcSubLineNo: Integer; NeededQtyBase: Decimal): Decimal
    begin
        exit(CalcTotalAvailQtyToPickForDirectedPutAwayPick(LocationCode, ItemNo, VariantCode, WhseItemTrackingLine, SrcType, SrcSubType, SrcNo, SrcLineNo, SrcSubLineNo, NeededQtyBase, 0, 0));
    end;

    internal procedure CalcTotalAvailQtyToPickForDirectedPutAwayPick(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; WhseItemTrackingLine: Record "Whse. Item Tracking Line"; SrcType: Integer; SrcSubType: Option; SrcNo: Code[20]; SrcLineNo: Integer; SrcSubLineNo: Integer; NeededQtyBase: Decimal; ExcludeQtyAssignedOnPickWorksheetLines: Decimal; ExcludeReservedQtyAssignedOnPickWorksheetLines: Decimal): Decimal
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        TempWhseItemTrackingLine2: Record "Whse. Item Tracking Line" temporary;
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        BinTypeFilter: Option ExcludeReceive,ExcludeShip,OnlyPickBins;
        TotalAvailQtyBase: Decimal;
        MaxPickableQtyInWhse: Decimal;
        MaxPickableQtyExcludingShipBin: Decimal;
        QtyReservedOnPickShip: Decimal;
        LineReservedQty: Decimal;
        QtyAssignedPick: Decimal;
        AvailableAfterReshuffle: Decimal;
        QtyOnToBinsBase: Decimal;
        ReservedQtyOnInventory: Decimal;
        ResetWhseItemTrkgExists: Boolean;
    begin
        ItemTrackingManagement.GetWhseItemTrkgSetup(ItemNo, WhseItemTrackingSetup);
        OnCalcTotalAvailQtyToPickOnAfterGetWhseItemTrkgSetup(WhseItemTrackingSetup, LocationCode);
        WhseItemTrackingSetup.CopyTrackingFromWhseItemTrackingLine(WhseItemTrackingLine);

        MaxPickableQtyInWhse := CalcMaxQtyAvailToPickInWhseForDirectedPutAwayPick(LocationCode, ItemNo, VariantCode, WhseItemTrackingSetup);
        MaxPickableQtyInWhse -= ExcludeQtyAssignedOnPickWorksheetLines; //Exclude the quantity assigned on other active worksheet lines as they are considered to be already picked (Scenario: Available to Pick field in Pick Worksheet)

        if MaxPickableQtyInWhse <= 0 then //MaxPickableQtyInWhse can be negative when ExcludeQtyAssignedOnPickWorksheetLines > MaxPickableQtyInWhse
            exit(0);

        TempWhseItemTrackingLine2.Copy(TempWhseItemTrackingLine);
        if ReqFEFOPick then begin
            TempWhseItemTrackingLine2."Entry No." := TempWhseItemTrackingLine2."Entry No." + 1;
            TempWhseItemTrackingLine2.CopyTrackingFromWhseItemTrackingLine(WhseItemTrackingLine);
            if not WhseItemTrkgExists then begin
                WhseItemTrkgExists := true;
                ResetWhseItemTrkgExists := true;
            end;
        end;

        QtyAssignedPick := CalcPickQtyAssigned(LocationCode, ItemNo, VariantCode, '', '', TempWhseItemTrackingLine2);

        if ResetWhseItemTrkgExists then begin
            WhseItemTrkgExists := false;
            ResetWhseItemTrkgExists := false;
        end;

        if CurrLocation."Always Create Pick Line" or CrossDock then begin
            FilterWhsePickLinesWithUndefinedBin(WarehouseActivityLine, ItemNo, LocationCode, VariantCode, WhseItemTrackingSetup);
            WarehouseActivityLine.CalcSums("Qty. Outstanding (Base)");
            QtyAssignedPick := QtyAssignedPick - WarehouseActivityLine."Qty. Outstanding (Base)";
        end;

        //Reduce the pick quantity that has been assigned during previous iterations for creating picks for the current line
        TotalAvailQtyBase -= QtyAssignedPick;

        if CalledFromMoveWksh then begin
            CalcQtyOnToBinsBase(WhseItemTrackingSetup, QtyOnToBinsBase, LocationCode, ItemNo, VariantCode);

            // For movement worksheet, MaxPickableQtyInWhse does not contain quantity from RECEIVE bins
            TotalAvailQtyBase += MaxPickableQtyInWhse;
        end
        else begin
            ReservedQtyOnInventory := CalcReservedQtyOnInventory(ItemNo, LocationCode, VariantCode, WhseItemTrackingSetup, ExcludeReservedQtyAssignedOnPickWorksheetLines);

            // Identify the reserved quantity for the current line
            if Abs(ReservedQtyOnInventory) > 0 then begin
                TempTrackingSpecification.CopyTrackingFromWhseItemTrackingLine(WhseItemTrackingLine);
                QtyReservedOnPickShip :=
                    WarehouseAvailabilityMgt.CalcReservQtyOnPicksShipsWithItemTracking(TempWarehouseActivityLine, TempTrackingSpecification, LocationCode, ItemNo, VariantCode);

                if WhseItemTrackingLine.TrackingExists() and (QtyReservedOnPickShip > 0) then
                    LineReservedQty :=
                        WarehouseAvailabilityMgt.CalcLineReservedQtyOnInvt(
                          SrcType, SrcSubType, SrcNo, SrcLineNo, SrcSubLineNo, true, WhseItemTrackingSetup, TempWarehouseActivityLine)
                else
                    LineReservedQty :=
                        WarehouseAvailabilityMgt.CalcLineReservedQtyOnInvt(
                          SrcType, SrcSubType, SrcNo, SrcLineNo, SrcSubLineNo, true, TempWarehouseActivityLine);
            end;

            // For non-movement worksheet use MaxPickableQtyExcludingShipBin
            MaxPickableQtyExcludingShipBin := CalcMaxQtyAvailToPickInWhseForDirectedPutAwayPickWithBinTypeFilter(LocationCode, ItemNo, VariantCode, WhseItemTrackingSetup, BinTypeFilter::ExcludeShip);
            MaxPickableQtyExcludingShipBin -= ExcludeQtyAssignedOnPickWorksheetLines; //Exclude the quantity assigned on other active worksheet lines as they are considered to be already picked (Scenario: Available to Pick field in Pick Worksheet)

            // Reduce the available quantity if the items are reserved for other lines or dedicated bins
            TotalAvailQtyBase += CalcAvailabilityAfterReservationImpact(MaxPickableQtyExcludingShipBin, Abs(ReservedQtyOnInventory), QtyReservedOnPickShip, LineReservedQty);
            TotalAvailQtyBase := Minimum(TotalAvailQtyBase, MaxPickableQtyInWhse);

            OnCalcTotalAvailQtyToPickForDirectedPutAwayPickOnBeforeCalcAvailabilityAfterReservationImpact(TotalAvailQtyBase, MaxPickableQtyExcludingShipBin, MaxPickableQtyInWhse, ReservedQtyOnInventory, QtyReservedOnPickShip, LineReservedQty);
        end;

        if (NeededQtyBase <> 0) and (NeededQtyBase > TotalAvailQtyBase) then
            if ReleaseNonSpecificReservations(LocationCode, ItemNo, VariantCode, WhseItemTrackingSetup, NeededQtyBase - TotalAvailQtyBase) then begin
                AvailableAfterReshuffle :=
                    CalcTotalAvailQtyToPick(
                        LocationCode, ItemNo, VariantCode, TempWhseItemTrackingLine,
                        SrcType, SrcSubType, SrcNo, SrcLineNo, SrcSubLineNo, 0, false);
                exit(AvailableAfterReshuffle);
            end;

        UpdateCalculationSummaryQuantities(TotalAvailQtyBase, MaxPickableQtyInWhse, QtyAssignedPick, MaxPickableQtyExcludingShipBin, ReservedQtyOnInventory, QtyReservedOnPickShip, LineReservedQty);

        exit(TotalAvailQtyBase - QtyOnToBinsBase); //QtyOnToBinsBase is set when CalledFromMoveWksh is true
    end;

    internal procedure CalcAvailabilityAfterReservationImpact(MaxPickableQtyExcludingShipBin: Decimal; ReservedQtyOnInventory: Decimal; QtyReservedOnPickShip: Decimal; ReservedQtyForCurrLine: Decimal): Decimal
    var
        ReservedQtyCannotBePicked: Decimal;
    begin
        // Calculate the reserved quantity that cannot be picked. ReservedQtyOnInventory consists of QtyReservedOnPickShip and ReservedQtyForCurrLine.
        ReservedQtyCannotBePicked := Maximum(0, ReservedQtyOnInventory - QtyReservedOnPickShip - ReservedQtyForCurrLine);

        // Reduce the available quantity if the reserved quantity cannot be picked
        exit(Maximum(0, MaxPickableQtyExcludingShipBin - ReservedQtyCannotBePicked));
    end;

    local procedure AdjustQtyReservedOnPickShip(var SubTotal: Decimal; var QtyReservedOnPickShip: Decimal; LineReservedQty: Decimal; ReservedQtyOnInventory: Decimal)
    begin
        OnBeforeAdjustQtyReservedOnPickShip(SubTotal, QtyReservedOnPickShip, LineReservedQty, ReservedQtyOnInventory);
        if SubTotal < 0 then
            if Abs(SubTotal) < QtyReservedOnPickShip + LineReservedQty then
                QtyReservedOnPickShip := Abs(SubTotal) - LineReservedQty;
    end;

    local procedure CalcQtyOnPickAndReceiveBins(var QtyOnReceiveBins: Decimal; var QtyOnPickBins: Decimal; ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; WhseItemTrackingSetup: Record "Item Tracking Setup"; RespectLocationBins: Boolean)
    var
        WarehouseEntry: Record "Warehouse Entry";
        BinTypeFilter: Text;
    begin
        GetLocation(LocationCode);

        WarehouseEntry.SetCalculationFilters(ItemNo, LocationCode, VariantCode, WhseItemTrackingSetup, false);
        BinTypeFilter := GetBinTypeFilter(0);
        if BinTypeFilter <> '' then begin
            if RespectLocationBins and (CurrLocation."Receipt Bin Code" <> '') then begin
                WarehouseEntry.SetRange("Bin Code", CurrLocation."Receipt Bin Code");
                WarehouseEntry.CalcSums("Qty. (Base)");
                QtyOnReceiveBins := WarehouseEntry."Qty. (Base)";

                WarehouseEntry.SetFilter("Bin Code", '<>%1', CurrLocation."Receipt Bin Code");
            end;
            WarehouseEntry.SetFilter("Bin Type Code", BinTypeFilter); // Receive
            WarehouseEntry.CalcSums("Qty. (Base)");
            QtyOnReceiveBins += WarehouseEntry."Qty. (Base)";

            WarehouseEntry.SetFilter("Bin Type Code", '<>%1', BinTypeFilter);
        end;
        WarehouseEntry.CalcSums("Qty. (Base)");
        QtyOnPickBins := WarehouseEntry."Qty. (Base)";
    end;

    local procedure CalcQtyCanBePicked(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; EntrySummary: Record "Entry Summary"; IsMovement: Boolean): Decimal
    var
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        BinTypeFilter: Text;
        QtyOnOutboundBins: Decimal;
        QtyOnToBinsBase: Decimal;
    begin
        ItemTrackingManagement.GetWhseItemTrkgSetup(ItemNo, WhseItemTrackingSetup);
        OnCalcQtyCanBePickedOnAfterGetWhseItemTrkgSetup(WhseItemTrackingSetup, LocationCode);
        WhseItemTrackingSetup.CopyTrackingFromEntrySummary(EntrySummary);

        GetLocation(LocationCode);
        if not CurrLocation."Directed Put-away and Pick" then begin
            BinTypeFilter := '';
            QtyOnOutboundBins := WarehouseAvailabilityMgt.CalcQtyOnOutboundBins(LocationCode, ItemNo, VariantCode, WhseItemTrackingSetup, true);
        end else
            // movement can be picked from anywhere but receive and ship zones, yet pick only takes the pick zone
            if IsMovement then begin
                BinTypeFilter := StrSubstNo(NotEqualTok, GetBinTypeFilter(0));
                QtyOnOutboundBins := WarehouseAvailabilityMgt.CalcQtyOnOutboundBins(LocationCode, ItemNo, VariantCode, WhseItemTrackingSetup, true);
            end else begin
                BinTypeFilter := GetBinTypeFilter(3);
                QtyOnOutboundBins := 0;
            end;

        if CurrLocation."Directed Put-away and Pick" then
            if CalledFromMoveWksh then
                CalcQtyOnToBinsBase(WhseItemTrackingSetup, QtyOnToBinsBase, LocationCode, ItemNo, VariantCode);

        exit(SumWhseEntries(ItemNo, LocationCode, VariantCode, WhseItemTrackingSetup, BinTypeFilter, '', true) - QtyOnOutboundBins - QtyOnToBinsBase);
    end;

    procedure GetBinTypeFilter(Type: Option Receive,Ship,"Put Away",Pick,"Put Away only") BinTypeFilter: Text[1024]
    var
        BinType: Record "Bin Type";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetBinTypeFilter(BinTypeFilter, IsHandled, Type);
        if IsHandled then
            exit(BinTypeFilter);

        case Type of
            Type::Receive:
                BinType.SetRange(Receive, true);
            Type::Ship:
                BinType.SetRange(Ship, true);
            Type::"Put Away":
                BinType.SetRange("Put Away", true);
            Type::Pick:
                BinType.SetRange(Pick, true);
            Type::"Put Away only":
                begin
                    BinType.SetRange("Put Away", true);
                    BinType.SetRange(Pick, false);
                end;
        end;
        if BinType.Find('-') then
            repeat
                BinTypeFilter := StrSubstNo(OrTok, BinTypeFilter, BinType.Code);
            until BinType.Next() = 0;
        if BinTypeFilter <> '' then
            BinTypeFilter := CopyStr(BinTypeFilter, 2, MaxStrLen(BinTypeFilter));
        exit(BinTypeFilter);
    end;

    procedure CheckOutBound(SourceType: Integer; SourceSubType: Integer; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer) OutBoundQty: Decimal
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        JobPlanningLine: Record "Job Planning Line";
    begin
        case SourceType of
            Database::"Sales Line",
            Database::"Purchase Line",
            Database::"Transfer Line":
                begin
                    WarehouseShipmentLine.SetCurrentKey(
                      "Source Type", "Source Subtype", "Source No.", "Source Line No.");
                    WarehouseShipmentLine.SetRange("Source Type", SourceType);
                    WarehouseShipmentLine.SetRange("Source Subtype", SourceSubType);
                    WarehouseShipmentLine.SetRange("Source No.", SourceNo);
                    WarehouseShipmentLine.SetRange("Source Line No.", SourceLineNo);
                    WarehouseShipmentLine.SetAutoCalcFields("Pick Qty. (Base)");
                    WarehouseShipmentLine.SetLoadFields("Pick Qty. (Base)", "Qty. Picked (Base)");
                    if WarehouseShipmentLine.FindFirst() then
                        OutBoundQty := WarehouseShipmentLine."Pick Qty. (Base)" + WarehouseShipmentLine."Qty. Picked (Base)"
                    else begin
                        WarehouseActivityLine.SetCurrentKey(
                          "Source Type", "Source Subtype", "Source No.", "Source Line No.");
                        WarehouseActivityLine.SetRange("Source Type", SourceType);
                        WarehouseActivityLine.SetRange("Source Subtype", SourceSubType);
                        WarehouseActivityLine.SetRange("Source No.", SourceNo);
                        WarehouseActivityLine.SetRange("Source Line No.", SourceLineNo);
                        WarehouseActivityLine.SetLoadFields("Qty. Outstanding (Base)");
                        if WarehouseActivityLine.FindFirst() then
                            OutBoundQty := WarehouseActivityLine."Qty. Outstanding (Base)"
                        else
                            OutBoundQty := 0;
                    end;
                end;
            Database::"Job Planning Line":
                begin
                    JobPlanningLine.SetRange("Job No.", SourceNo);
                    JobPlanningLine.SetRange("Job Contract Entry No.", SourceLineNo);
                    JobPlanningLine.SetAutoCalcFields("Pick Qty. (Base)");
                    JobPlanningLine.SetLoadFields("Pick Qty. (Base)", "Qty. Picked (Base)");
                    if JobPlanningLine.FindFirst() then
                        OutBoundQty := JobPlanningLine."Pick Qty. (Base)" + JobPlanningLine."Qty. Picked (Base)"
                    else
                        OutBoundQty := 0;
                end;
        end;

        OnAfterCheckOutBound(SourceType, SourceSubType, SourceNo, SourceLineNo, OutBoundQty, SourceSubLineNo);
    end;

    procedure SetCrossDock(CrossDock2: Boolean)
    begin
        CrossDock := CrossDock2;
    end;

    procedure GetReservationStatus(var ReservationExists2: Boolean; var ReservedForItemLedgEntry2: Boolean)
    begin
        ReservationExists2 := ReservationExists;
        ReservedForItemLedgEntry2 := ReservedForItemLedgEntry;
    end;

    procedure SetCalledFromPickWksh(CalledFromPickWksh2: Boolean)
    begin
        CalledFromPickWksh := CalledFromPickWksh2;
    end;

    procedure SetCalledFromMoveWksh(CalledFromMoveWksh2: Boolean)
    begin
        CalledFromMoveWksh := CalledFromMoveWksh2;
    end;

    procedure CalcQtyToPickBaseExt(var BinContent: Record "Bin Content"; var TempWhseActivLine: Record "Warehouse Activity Line" temporary): Decimal
    begin
        exit(CalcQtyToPickBase(BinContent, TempWhseActivLine));
    end;

    local procedure CalcQtyToPickBase(var BinContent: Record "Bin Content"; var TempWhseActivLine: Record "Warehouse Activity Line" temporary): Decimal
    var
        WhseEntry: Record "Warehouse Entry";
        WhseActivLine: Record "Warehouse Activity Line";
        WhseJournalLine: Record "Warehouse Journal Line";
        QtyPlaced: Decimal;
        QtyTaken: Decimal;
    begin
        WhseEntry.SetRange("Location Code", BinContent."Location Code");
        WhseEntry.SetRange("Bin Code", BinContent."Bin Code");
        WhseEntry.SetRange("Item No.", BinContent."Item No.");
        WhseEntry.SetRange("Variant Code", BinContent."Variant Code");
        WhseEntry.SetRange("Unit of Measure Code", BinContent."Unit of Measure Code");
        WhseEntry.SetTrackingFilterFromBinContent(BinContent);
        WhseEntry.CalcSums("Qty. (Base)");

        WhseActivLine.SetCurrentKey(
            "Item No.", "Bin Code", "Location Code",
            "Action Type", "Variant Code", "Unit of Measure Code", "Breakbulk No.", "Activity Type", "Lot No.", "Serial No.");
        WhseActivLine.SetRange("Location Code", BinContent."Location Code");
        WhseActivLine.SetRange("Action Type", WhseActivLine."Action Type"::Take);
        WhseActivLine.SetRange("Bin Code", BinContent."Bin Code");
        WhseActivLine.SetRange("Item No.", BinContent."Item No.");
        WhseActivLine.SetRange("Variant Code", BinContent."Variant Code");
        WhseActivLine.SetRange("Unit of Measure Code", BinContent."Unit of Measure Code");
        WhseActivLine.SetTrackingFilterFromBinContent(BinContent);
        WhseActivLine.CalcSums("Qty. Outstanding (Base)");
        QtyTaken := WhseActivLine."Qty. Outstanding (Base)";

        TempWhseActivLine.Copy(WhseActivLine);
        TempWhseActivLine.CalcSums("Qty. Outstanding (Base)");
        QtyTaken += TempWhseActivLine."Qty. Outstanding (Base)";

        TempWhseActivLine.SetRange("Action Type", WhseActivLine."Action Type"::Place);
        TempWhseActivLine.CalcSums("Qty. Outstanding (Base)");
        QtyPlaced := TempWhseActivLine."Qty. Outstanding (Base)";

        TempWhseActivLine.Reset();

        WhseJournalLine.SetRange("Location Code", BinContent."Location Code");
        WhseJournalLine.SetRange("From Bin Code", BinContent."Bin Code");
        WhseJournalLine.SetRange("Item No.", BinContent."Item No.");
        WhseJournalLine.SetRange("Variant Code", BinContent."Variant Code");
        WhseJournalLine.SetRange("Unit of Measure Code", BinContent."Unit of Measure Code");
        WhseJournalLine.SetTrackingFilterFromBinContent(BinContent);
        WhseJournalLine.CalcSums("Qty. (Absolute, Base)");

        exit(WhseEntry."Qty. (Base)" + WhseJournalLine."Qty. (Absolute, Base)" + QtyPlaced - QtyTaken);
    end;

    local procedure PickAccordingToFEFO(LocationCode: Code[10]; WhseItemTrackingSetup: Record "Item Tracking Setup") PickAccordingToFEFO: Boolean
    var
        IsHandled: Boolean;
    begin
        GetLocation(LocationCode);

        OnBeforePickAccordingToFEFO(LocationCode, WhseItemTrackingSetup, PickAccordingToFEFO, IsHandled);
        if IsHandled then
            exit(PickAccordingToFEFO);

        PickAccordingToFEFO := CurrLocation."Pick According to FEFO" and WhseItemTrackingSetup.TrackingRequired();
        OnAfterPickAccordingToFEFO(LocationCode, WhseItemTrackingSetup, PickAccordingToFEFO);
    end;

    local procedure UndefinedItemTrkg(var QtyToTrackBase: Decimal): Boolean
    var
        DummyItemTrackingSetup: Record "Item Tracking Setup";
    begin
        QtyToTrackBase := QtyToTrackBase - ItemTrackedQuantity(DummyItemTrackingSetup);
        exit(QtyToTrackBase > 0);
    end;

    local procedure ReleaseNonSpecificReservations(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; WhseItemTrackingSetup: Record "Item Tracking Setup"; QtyToRelease: Decimal): Boolean
    var
        LateBindingMgt: Codeunit "Late Binding Management";
        xReservedQty: Decimal;
    begin
        if QtyToRelease <= 0 then
            exit;

        if WhseItemTrackingSetup.TrackingRequired() then
            if CurrItem."Reserved Qty. on Inventory" > 0 then begin
                xReservedQty := CurrItem."Reserved Qty. on Inventory";
                LateBindingMgt.ReleaseForReservation(ItemNo, VariantCode, LocationCode, WhseItemTrackingSetup, QtyToRelease);
                CurrItem.CalcFields("Reserved Qty. on Inventory");
            end;

        exit(xReservedQty > CurrItem."Reserved Qty. on Inventory");
    end;

    procedure SetCalledFromWksh(NewCalledFromWksh: Boolean)
    begin
        CalledFromWksh := NewCalledFromWksh;
    end;

    local procedure GetFromBinContentQty(LocCode: Code[10]; FromBinCode: Code[20]; ItemNo: Code[20]; Variant: Code[20]; UoMCode: Code[10]; WhseItemTrackingLine: Record "Whse. Item Tracking Line"): Decimal
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.Get(LocCode, FromBinCode, ItemNo, Variant, UoMCode);
        BinContent.SetTrackingFilterFromWhseItemTrackingLine(WhseItemTrackingLine);
        BinContent.CalcFields("Quantity (Base)");
        exit(BinContent."Quantity (Base)");
    end;

    procedure CreateTempActivityLine(
        LocationCode: Code[10]; BinCode: Code[20]; UOMCode: Code[10]; QtyPerUOM: Decimal; QtyToPick: Decimal; QtyToPickBase: Decimal; ActionType: Integer; BreakBulkNo: Integer)
    begin
        CreateTempActivityLine(LocationCode, BinCode, UOMCode, QtyPerUOM, QtyToPick, QtyToPickBase, ActionType, BreakBulkNo, 0, 0);
    end;

    procedure CreateTempActivityLine(
        LocationCode: Code[10]; BinCode: Code[20]; UOMCode: Code[10]; QtyPerUOM: Decimal; QtyToPick: Decimal; QtyToPickBase: Decimal; ActionType: Integer; BreakBulkNo: Integer; QtyRndPrec: Decimal; QtyRndPrecBase: Decimal)
    var
        WhseSource2: Option;
        ShouldCalcMaxQty: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateTempActivityLine(
            BinCode, QtyToPick, QtyToPickBase, ActionType, LocationCode, UOMCode, QtyPerUOM, CurrWarehouseShipmentLine, CreatePickParameters,
            TempWarehouseActivityLine, CurrBin, WhseItemTrkgExists, IsHandled);
        if IsHandled then
            exit;

        GetCurrBin(LocationCode, BinCode);

        TempLineNo := TempLineNo + 10000;

        TempWarehouseActivityLine.Reset();
        TempWarehouseActivityLine.Init();

        TempWarehouseActivityLine."No." := Format(TempNo);
        TempWarehouseActivityLine."Location Code" := LocationCode;
        TempWarehouseActivityLine."Unit of Measure Code" := UOMCode;
        TempWarehouseActivityLine."Qty. per Unit of Measure" := QtyPerUOM;
        TempWarehouseActivityLine."Qty. Rounding Precision" := QtyRndPrec;
        TempWarehouseActivityLine."Qty. Rounding Precision (Base)" := QtyRndPrecBase;
        TempWarehouseActivityLine."Starting Date" := WorkDate();
        TempWarehouseActivityLine."Bin Code" := BinCode;
        TempWarehouseActivityLine."Action Type" := Enum::"Warehouse Action Type".FromInteger(ActionType);
        TempWarehouseActivityLine."Breakbulk No." := BreakBulkNo;
        TempWarehouseActivityLine."Line No." := TempLineNo;

        case CreatePickParameters."Whse. Document" of
            CreatePickParameters."Whse. Document"::"Pick Worksheet":
                TempWarehouseActivityLine.TransferFromPickWkshLine(CurrWhseWorksheetLine);
            CreatePickParameters."Whse. Document"::Shipment:
                if CurrWarehouseShipmentLine."Assemble to Order" then
                    TempWarehouseActivityLine.TransferFromATOShptLine(CurrWarehouseShipmentLine, CustomWhseSourceLine)
                else
                    TempWarehouseActivityLine.TransferFromShptLine(CurrWarehouseShipmentLine);
            CreatePickParameters."Whse. Document"::"Internal Pick":
                TempWarehouseActivityLine.TransferFromIntPickLine(CurrWhseInternalPickLine);
            CreatePickParameters."Whse. Document"::"Movement Worksheet":
                TempWarehouseActivityLine.TransferFromMovWkshLine(CurrWhseWorksheetLine);
            CreatePickParameters."Whse. Document"::Job:
                if CurrJobPlanningLine."Assemble to Order" then
                    TempWarehouseActivityLine.TransferFromATOJobPlanningLine(CurrJobPlanningLine, CustomWhseSourceLine)
                else
                    TempWarehouseActivityLine.TransferFromJobPlanningLine(CurrJobPlanningLine);
            else
                OnCreateTempActivityLineForCustomWhseSource(CustomWhseSourceLine, TempWarehouseActivityLine, CreatePickParameters);
        end;

        OnCreateTempActivityLineOnAfterTransferFrom(TempWarehouseActivityLine, CreatePickParameters."Whse. Document");

        if ((CreatePickParameters."Whse. Document" = CreatePickParameters."Whse. Document"::Shipment) and CurrWarehouseShipmentLine."Assemble to Order")
            or ((CreatePickParameters."Whse. Document" = CreatePickParameters."Whse. Document"::Job) and CurrJobPlanningLine."Assemble to Order") then
            WhseSource2 := CreatePickParameters."Whse. Document"::Assembly
        else
            WhseSource2 := CreatePickParameters."Whse. Document";

        ShouldCalcMaxQty := (BreakBulkNo = 0) and (TempWarehouseActivityLine."Action Type" <> "Warehouse Action Type"::" ");
        OnCreateTempActivityLineOnAfterShouldCalcMaxQty(TempWarehouseActivityLine, BreakBulkNo, ShouldCalcMaxQty);
        if ShouldCalcMaxQty then
            case WhseSource2 of
                CreatePickParameters."Whse. Document"::"Pick Worksheet",
                CreatePickParameters."Whse. Document"::"Movement Worksheet":
                    if (TempWarehouseActivityLine."Action Type" <> "Warehouse Action Type"::Take) or (CurrWhseWorksheetLine."Unit of Measure Code" = TempWarehouseActivityLine."Unit of Measure Code") then
                        CalcMaxQty(
                            QtyToPick, CurrWhseWorksheetLine."Qty. to Handle", QtyToPickBase, CurrWhseWorksheetLine."Qty. to Handle (Base)", TempWarehouseActivityLine."Action Type");

                CreatePickParameters."Whse. Document"::Shipment:
                    if (TempWarehouseActivityLine."Action Type" <> "Warehouse Action Type"::Take) or (CurrWarehouseShipmentLine."Unit of Measure Code" = TempWarehouseActivityLine."Unit of Measure Code") then begin
                        CurrWarehouseShipmentLine.CalcFields("Pick Qty.", "Pick Qty. (Base)");
                        CalcMaxQty(
                            QtyToPick,
                            CurrWarehouseShipmentLine.Quantity -
                            CurrWarehouseShipmentLine."Qty. Picked" -
                            CurrWarehouseShipmentLine."Pick Qty.",
                            QtyToPickBase,
                            CurrWarehouseShipmentLine."Qty. (Base)" -
                            CurrWarehouseShipmentLine."Qty. Picked (Base)" -
                            CurrWarehouseShipmentLine."Pick Qty. (Base)",
                            TempWarehouseActivityLine."Action Type");
                    end;

                CreatePickParameters."Whse. Document"::"Internal Pick":
                    if (TempWarehouseActivityLine."Action Type" <> "Warehouse Action Type"::Take) or (CurrWhseInternalPickLine."Unit of Measure Code" = TempWarehouseActivityLine."Unit of Measure Code") then begin
                        CurrWhseInternalPickLine.CalcFields("Pick Qty.", "Pick Qty. (Base)");
                        CalcMaxQty(
                            QtyToPick,
                            CurrWhseInternalPickLine.Quantity -
                            CurrWhseInternalPickLine."Qty. Picked" -
                            CurrWhseInternalPickLine."Pick Qty.",
                            QtyToPickBase,
                            CurrWhseInternalPickLine."Qty. (Base)" -
                            CurrWhseInternalPickLine."Qty. Picked (Base)" -
                            CurrWhseInternalPickLine."Pick Qty. (Base)",
                            TempWarehouseActivityLine."Action Type");
                    end;

                CreatePickParameters."Whse. Document"::Job:
                    if not ((TempWarehouseActivityLine."Action Type" = "Warehouse Action Type"::Take) and (CurrJobPlanningLine."Unit of Measure Code" <> TempWarehouseActivityLine."Unit of Measure Code")) then begin
                        CurrJobPlanningLine.CalcFields("Pick Qty.", "Pick Qty. (Base)");
                        CalcMaxQty(
                            QtyToPick,
                            CurrJobPlanningLine.Quantity -
                            CurrJobPlanningLine."Qty. Picked" -
                            CurrJobPlanningLine."Pick Qty.",
                            QtyToPickBase,
                            CurrJobPlanningLine."Quantity (Base)" -
                            CurrJobPlanningLine."Qty. Picked (Base)" -
                            CurrJobPlanningLine."Pick Qty. (Base)",
                            TempWarehouseActivityLine."Action Type");
                    end;
                else
                    OnCalcMaxQtyForCustomWhseSource(
                        CustomWhseSourceLine, TempWarehouseActivityLine, QtyToPick, QtyToPickBase, BreakBulkNo, ShouldCalcMaxQty, WhseSource2);
            end;

        OnCreateTempActivityLineOnAfterCalcQtyToPick(
            TempWarehouseActivityLine, QtyToPick, QtyToPickBase, CreatePickParameters."Whse. Document", WhseSource2);

        if (LocationCode <> '') and (BinCode <> '') then begin
            GetCurrBin(LocationCode, BinCode);
            TempWarehouseActivityLine.Dedicated := CurrBin.Dedicated;
        end;
        TempWarehouseActivityLine."Zone Code" := CurrBin."Zone Code";
        TempWarehouseActivityLine."Bin Ranking" := CurrBin."Bin Ranking";
        if CurrLocation."Directed Put-away and Pick" then
            TempWarehouseActivityLine."Bin Type Code" := CurrBin."Bin Type Code";
        if CurrLocation."Special Equipment" <> CurrLocation."Special Equipment"::" " then
            TempWarehouseActivityLine."Special Equipment Code" :=
                AssignSpecEquipment(LocationCode, BinCode, TempWarehouseActivityLine."Item No.", TempWarehouseActivityLine."Variant Code");
        OnCreateTempActivityLineAfterAssignSpecEquipment(TempWarehouseActivityLine, QtyToPick);

        TempWarehouseActivityLine.Validate(Quantity, QtyToPick);
        if QtyToPickBase <> 0 then begin
            TempWarehouseActivityLine."Qty. (Base)" := QtyToPickBase;
            TempWarehouseActivityLine."Qty. to Handle (Base)" := QtyToPickBase;
            TempWarehouseActivityLine."Qty. Outstanding (Base)" := QtyToPickBase;
        end;
        OnCreateTempActivityLineOnAfterValidateQuantity(TempWarehouseActivityLine);

        case CreatePickParameters."Whse. Document" of
            CreatePickParameters."Whse. Document"::Shipment:
                begin
                    TempWarehouseActivityLine."Shipping Agent Code" := ShippingAgentCode;
                    TempWarehouseActivityLine."Shipping Agent Service Code" := ShippingAgentServiceCode;
                    TempWarehouseActivityLine."Shipment Method Code" := ShipmentMethodCode;
                end;
            CreatePickParameters."Whse. Document"::Production,
            CreatePickParameters."Whse. Document"::Assembly,
            CreatePickParameters."Whse. Document"::Job:
                if TempWarehouseActivityLine."Shelf No." = '' then begin
                    CurrItem."No." := TempWarehouseActivityLine."Item No.";
                    CurrItem.ItemSKUGet(CurrItem, TempWarehouseActivityLine."Location Code", TempWarehouseActivityLine."Variant Code");
                    TempWarehouseActivityLine."Shelf No." := CurrItem."Shelf No.";
                end;
            CreatePickParameters."Whse. Document"::"Movement Worksheet":
                if (CurrWhseWorksheetLine."Qty. Outstanding" <> QtyToPick) and (BreakBulkNo = 0) then begin
                    TempWarehouseActivityLine."Source Type" := Database::"Whse. Worksheet Line";
                    TempWarehouseActivityLine."Source No." := CurrWhseWorksheetLine."Worksheet Template Name";
                    TempWarehouseActivityLine."Source Line No." := TempWarehouseActivityLine."Line No.";
                end;
        end;

        TransferItemTrkgFields(TempWarehouseActivityLine, TempWhseItemTrackingLine);

        if (BreakBulkNo = 0) and (ActionType <> 2) then
            TotalQtyPickedBase += QtyToPickBase;

        OnBeforeTempWhseActivLineInsert(TempWarehouseActivityLine, ActionType, WhseSource2);
        TempWarehouseActivityLine.Insert();
    end;

    procedure UpdateQuantitiesToPick(QtyAvailableBase: Decimal; FromQtyPerUOM: Decimal; var FromQtyToPick: Decimal; var FromQtyToPickBase: Decimal; ToQtyPerUOM: Decimal; var ToQtyToPick: Decimal; var ToQtyToPickBase: Decimal; var TotalQtyToPick: Decimal; var TotalQtyToPickBase: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateQuantitiesToPick(QtyAvailableBase, FromQtyPerUOM, FromQtyToPick, FromQtyToPickBase, ToQtyPerUOM, ToQtyToPick, ToQtyToPickBase, TotalQtyToPick, TotalQtyToPickBase, IsHandled);
        if IsHandled then
            exit;

        UpdateToQtyToPick(QtyAvailableBase, ToQtyPerUOM, ToQtyToPick, ToQtyToPickBase, TotalQtyToPick, TotalQtyToPickBase);
        UpdateFromQtyToPick(QtyAvailableBase, FromQtyPerUOM, FromQtyToPick, FromQtyToPickBase, ToQtyPerUOM, ToQtyToPick, ToQtyToPickBase);
        UpdateTotalQtyToPick(ToQtyToPick, ToQtyToPickBase, TotalQtyToPick, TotalQtyToPickBase)
    end;

    procedure UpdateFromQtyToPick(QtyAvailableBase: Decimal; FromQtyPerUOM: Decimal; var FromQtyToPick: Decimal; var FromQtyToPickBase: Decimal; ToQtyPerUOM: Decimal; ToQtyToPick: Decimal; ToQtyToPickBase: Decimal)
    begin
        case FromQtyPerUOM of
            ToQtyPerUOM:
                begin
                    FromQtyToPick := ToQtyToPick;
                    FromQtyToPickBase := ToQtyToPickBase;
                end;
            0 .. ToQtyPerUOM:
                begin
                    FromQtyToPick := Round(ToQtyToPickBase / FromQtyPerUOM, UnitOfMeasureManagement.QtyRndPrecision());
                    FromQtyToPickBase := ToQtyToPickBase;
                end;
            else
                FromQtyToPick := Round(ToQtyToPickBase / FromQtyPerUOM, 1, '>');
                FromQtyToPickBase := FromQtyToPick * FromQtyPerUOM;
                if FromQtyToPickBase > QtyAvailableBase then begin
                    FromQtyToPickBase := ToQtyToPickBase;
                    FromQtyToPick := Round(FromQtyToPickBase / FromQtyPerUOM, UnitOfMeasureManagement.QtyRndPrecision());
                end;
        end;
    end;

    local procedure UpdateToQtyToPick(QtyAvailableBase: Decimal; ToQtyPerUOM: Decimal; var ToQtyToPick: Decimal; var ToQtyToPickBase: Decimal; TotalQtyToPick: Decimal; TotalQtyToPickBase: Decimal)
    begin
        ToQtyToPickBase := QtyAvailableBase;
        if ToQtyToPickBase > TotalQtyToPickBase then
            ToQtyToPickBase := TotalQtyToPickBase;

        ToQtyToPick := Round(ToQtyToPickBase / ToQtyPerUOM, UnitOfMeasureManagement.QtyRndPrecision());
        if ToQtyToPick > TotalQtyToPick then
            ToQtyToPick := TotalQtyToPick;
        if (ToQtyToPick <> TotalQtyToPick) and (ToQtyToPickBase = TotalQtyToPickBase) then
            if Abs(1 - ToQtyToPick / TotalQtyToPick) <= UnitOfMeasureManagement.QtyRndPrecision() then
                ToQtyToPick := TotalQtyToPick;
    end;

    procedure UpdateTotalQtyToPick(ToQtyToPick: Decimal; ToQtyToPickBase: Decimal; var TotalQtyToPick: Decimal; var TotalQtyToPickBase: Decimal)
    begin
        TotalQtyToPick := TotalQtyToPick - ToQtyToPick;
        TotalQtyToPickBase := TotalQtyToPickBase - ToQtyToPickBase;
    end;

#if not CLEAN27
    // Replaced by Query CalcOutstandQtyOnWhseActLine
    internal procedure CalcTotalQtyAssgndOnWhse(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]): Decimal
    var
        WhseShipmentLine: Record "Warehouse Shipment Line";
        ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component";
        AssemblyLine: Record Microsoft.Assembly.Document."Assembly Line";
        QtyAssgndToWhseAct: Decimal;
        QtyAssgndToShipment: Decimal;
        QtyAssgndToProdComp: Decimal;
        QtyAssgndToAsmLine: Decimal;
    begin
        QtyAssgndToWhseAct +=
          CalcTotalQtyAssgndOnWhseAct("Warehouse Activity Type"::" ", LocationCode, ItemNo, VariantCode);
        QtyAssgndToWhseAct +=
          CalcTotalQtyAssgndOnWhseAct("Warehouse Activity Type"::"Put-away", LocationCode, ItemNo, VariantCode);
        QtyAssgndToWhseAct +=
          CalcTotalQtyAssgndOnWhseAct("Warehouse Activity Type"::Pick, LocationCode, ItemNo, VariantCode);
        QtyAssgndToWhseAct +=
          CalcTotalQtyAssgndOnWhseAct("Warehouse Activity Type"::Movement, LocationCode, ItemNo, VariantCode);
        QtyAssgndToWhseAct +=
          CalcTotalQtyAssgndOnWhseAct("Warehouse Activity Type"::"Invt. Put-away", LocationCode, ItemNo, VariantCode);
        QtyAssgndToWhseAct +=
          CalcTotalQtyAssgndOnWhseAct("Warehouse Activity Type"::"Invt. Pick", LocationCode, ItemNo, VariantCode);

        WhseShipmentLine.SetCurrentKey("Item No.", "Location Code", "Variant Code", "Due Date");
        WhseShipmentLine.SetRange("Location Code", LocationCode);
        WhseShipmentLine.SetRange("Item No.", ItemNo);
        WhseShipmentLine.SetRange("Variant Code", VariantCode);
        WhseShipmentLine.CalcSums("Qty. Picked (Base)", "Qty. Shipped (Base)");
        QtyAssgndToShipment := WhseShipmentLine."Qty. Picked (Base)" - WhseShipmentLine."Qty. Shipped (Base)";

        ProdOrderComp.SetCurrentKey("Item No.", "Variant Code", "Location Code", Status, "Due Date");
        ProdOrderComp.SetRange("Location Code", LocationCode);
        ProdOrderComp.SetRange("Item No.", ItemNo);
        ProdOrderComp.SetRange("Variant Code", VariantCode);
        ProdOrderComp.SetRange(Status, ProdOrderComp.Status::Released);
        ProdOrderComp.CalcSums("Qty. Picked (Base)", "Expected Qty. (Base)", "Remaining Qty. (Base)");
        QtyAssgndToProdComp := ProdOrderComp."Qty. Picked (Base)" - (ProdOrderComp."Expected Qty. (Base)" - ProdOrderComp."Remaining Qty. (Base)");

        AssemblyLine.SetCurrentKey("Document Type", Type, "No.", "Variant Code", "Location Code");
        AssemblyLine.SetRange("Document Type", AssemblyLine."Document Type"::Order);
        AssemblyLine.SetRange("Location Code", LocationCode);
        AssemblyLine.SetRange(Type, AssemblyLine.Type::Item);
        AssemblyLine.SetRange("No.", ItemNo);
        AssemblyLine.SetRange("Variant Code", VariantCode);
        AssemblyLine.CalcSums("Qty. Picked (Base)", "Consumed Quantity (Base)");
        QtyAssgndToAsmLine := AssemblyLine.CalcQtyPickedNotConsumedBase();

        OnAfterCalcTotalQtyAssgndOnWhse(
            LocationCode, ItemNo, VariantCode, QtyAssgndToWhseAct, QtyAssgndToShipment, QtyAssgndToProdComp, QtyAssgndToAsmLine);

        exit(QtyAssgndToWhseAct + QtyAssgndToShipment + QtyAssgndToProdComp + QtyAssgndToAsmLine);
    end;

    local procedure CalcTotalQtyAssgndOnWhseAct(ActivityType: Enum "Warehouse Activity Type"; LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]): Decimal
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetCurrentKey(
            "Item No.", "Location Code", "Activity Type", "Bin Type Code",
            "Unit of Measure Code", "Variant Code", "Breakbulk No.", "Action Type");
        WarehouseActivityLine.SetRange("Location Code", LocationCode);
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        WarehouseActivityLine.SetRange("Variant Code", VariantCode);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.SetRange("Breakbulk No.", 0);
        WarehouseActivityLine.SetFilter("Action Type", '%1|%2', "Warehouse Action Type"::" ", "Warehouse Action Type"::Take);
        WarehouseActivityLine.CalcSums("Qty. Outstanding (Base)");
        exit(WarehouseActivityLine."Qty. Outstanding (Base)");
    end;
#endif

    procedure CalcTotalQtyOnBinType(BinTypeFilter: Text[1024]; LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]): Decimal
    var
        DummyItemTrackingSetup: Record "Item Tracking Setup";
    begin
        exit(SumWhseEntries(ItemNo, LocationCode, VariantCode, DummyItemTrackingSetup, BinTypeFilter, '', false));
    end;

    local procedure SumWhseEntries(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; WhseItemTrackingSetup: Record "Item Tracking Setup"; BinTypeCodeFilter: Text; BinCodeFilter: Text; ExcludeDedicatedBins: Boolean): Decimal
    var
        WhseEntry: Record "Warehouse Entry";
    begin
        WhseEntry.SetCalculationFilters(ItemNo, LocationCode, VariantCode, WhseItemTrackingSetup, ExcludeDedicatedBins);
        WhseEntry.SetFilter("Bin Type Code", BinTypeCodeFilter);
        WhseEntry.SetFilter("Bin Code", BinCodeFilter);
        WhseEntry.CalcSums("Qty. (Base)");
        exit(WhseEntry."Qty. (Base)");
    end;

    procedure CalcBreakbulkOutstdQty(var WhseActivLine: Record "Warehouse Activity Line"; WhseItemTrackingSetup: Record "Item Tracking Setup"): Decimal
    var
        BinContent: Record "Bin Content";
        WhseActivLine1: Record "Warehouse Activity Line";
        WhseActivLine2: Record "Warehouse Activity Line";
        TempUOM: Record "Unit of Measure" temporary;
        QtyOnBreakbulk: Decimal;
        BreakbulkBinFound: Boolean;
    begin
        WhseActivLine1.CopyFilters(WhseActivLine);
        WhseActivLine1.SetFilter("Breakbulk No.", '<>%1', 0);
        WhseActivLine1.SetRange("Action Type", "Warehouse Action Type"::Place);
        if WhseActivLine1.FindSet() then begin
            BinContent.SetCurrentKey(
                "Location Code", "Item No.", "Variant Code", "Cross-Dock Bin", "Qty. per Unit of Measure", "Bin Ranking");
            BinContent.SetRange("Location Code", WhseActivLine1."Location Code");
            BinContent.SetRange("Item No.", WhseActivLine1."Item No.");
            BinContent.SetRange("Variant Code", WhseActivLine1."Variant Code");
            BinContent.SetRange("Cross-Dock Bin", CrossDock);

            repeat
                if not TempUOM.Get(WhseActivLine1."Unit of Measure Code") then begin
                    TempUOM.Init();
                    TempUOM.Code := WhseActivLine1."Unit of Measure Code";
                    TempUOM.Insert();
                    WhseActivLine1.SetRange("Unit of Measure Code", WhseActivLine1."Unit of Measure Code");
                    WhseActivLine1.CalcSums("Qty. Outstanding (Base)");
                    QtyOnBreakbulk += WhseActivLine1."Qty. Outstanding (Base)";

                    // Exclude the qty counted in QtyAssignedToPick
                    BinContent.SetRange("Unit of Measure Code", WhseActivLine1."Unit of Measure Code");
                    if WhseItemTrackingSetup."Serial No. Required" then
                        BinContent.SetRange("Serial No. Filter", WhseActivLine1."Serial No.")
                    else
                        BinContent.SetFilter("Serial No. Filter", '%1|%2', WhseActivLine1."Serial No.", '');
                    if WhseItemTrackingSetup."Lot No. Required" then
                        BinContent.SetRange("Lot No. Filter", WhseActivLine1."Lot No.")
                    else
                        BinContent.SetFilter("Lot No. Filter", '%1|%2', WhseActivLine1."Lot No.", '');
                    if WhseItemTrackingSetup."Package No. Required" then
                        BinContent.SetRange("Package No. Filter", WhseActivLine1."Package No.")
                    else
                        BinContent.SetFilter("Package No. Filter", '%1|%2', WhseActivLine1."Package No.", '');

                    BreakbulkBinFound := false;
                    if BinContent.FindSet() then
                        repeat
                            if UseForPick(BinContent) then begin
                                BreakbulkBinFound := true;
                                BinContent.SetFilterOnUnitOfMeasure();
                                BinContent.CalcFields("Quantity (Base)", "Pick Quantity (Base)");
                                if BinContent."Pick Quantity (Base)" > BinContent."Quantity (Base)" then
                                    QtyOnBreakbulk -= (BinContent."Pick Quantity (Base)" - BinContent."Quantity (Base)");
                            end;
                        until BinContent.Next() = 0;

                    if not BreakbulkBinFound then begin
                        WhseActivLine2.CopyFilters(WhseActivLine1);
                        WhseActivLine2.SetFilter("Action Type", '%1|%2', "Warehouse Action Type"::" ", "Warehouse Action Type"::Take);
                        WhseActivLine2.SetRange("Breakbulk No.", 0);
                        WhseActivLine2.CalcSums("Qty. Outstanding (Base)");
                        QtyOnBreakbulk -= WhseActivLine2."Qty. Outstanding (Base)";
                    end;
                    WhseActivLine1.SetRange("Unit of Measure Code");
                end;
            until WhseActivLine1.Next() = 0;
        end;
        exit(QtyOnBreakbulk);
    end;

    procedure GetCannotBeHandledReason(): Text
    begin
        exit(DequeueCannotBeHandledReason());
    end;

    local procedure PickStrictExpirationPosting(ItemNo: Code[20]; WhseItemTrackingSetup: Record "Item Tracking Setup"): Boolean
    var
        StrictExpirationPosting: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePickStrictExpirationPosting(
            ItemNo, WhseItemTrackingSetup."Serial No. Required", WhseItemTrackingSetup."Lot No. Required", StrictExpirationPosting, IsHandled);
        if IsHandled then
            exit(StrictExpirationPosting);

        exit(ItemTrackingManagement.StrictExpirationPosting(ItemNo) and WhseItemTrackingSetup.TrackingRequired());
    end;

    procedure AddToFilterText(var TextVar: Text[250]; Separator: Code[1]; Comparator: Code[2]; Addendum: Code[20])
    begin
        if TextVar = '' then
            TextVar := Comparator + '''' + Addendum + ''''
        else
            TextVar += Separator + Comparator + '''' + Addendum + '''';
    end;

    procedure CreateAssemblyPickLine(AssemblyLine: Record Microsoft.Assembly.Document."Assembly Line")
    var
        QtyToPickBase: Decimal;
        QtyToPick: Decimal;
        EmptyGuid: Guid;
    begin
        AssemblyLine.TestField("Qty. per Unit of Measure");
        QtyToPickBase := AssemblyLine.CalcQtyToPickBase();
        QtyToPick := AssemblyLine.CalcQtyToPick();
        OnCreateAssemblyPickLineOnAfterCalcQtyToPick(AssemblyLine, QtyToPickBase, QtyToPick);
        if QtyToPick > 0 then begin
            SetCustomWhseSourceLine(
                AssemblyLine, 1, Database::Microsoft.Assembly.Document."Assembly Line",
                AssemblyLine."Document Type".AsInteger(), AssemblyLine."Document No.", AssemblyLine."Line No.", 0);
            SetTempWhseItemTrkgLine(
                AssemblyLine."Document No.", Database::Microsoft.Assembly.Document."Assembly Line", '', 0, AssemblyLine."Line No.", AssemblyLine."Location Code");
            CreateTempLine(
                AssemblyLine."Location Code", AssemblyLine."No.", AssemblyLine."Variant Code", AssemblyLine."Unit of Measure Code", '', AssemblyLine."Bin Code",
                AssemblyLine."Qty. per Unit of Measure", AssemblyLine."Qty. Rounding Precision", AssemblyLine."Qty. Rounding Precision (Base)", QtyToPick, QtyToPickBase);
        end else
            InsertSkippedLinesToCalculationSummary(
                Database::Microsoft.Assembly.Document."Assembly Line", AssemblyLine."Document No.", AssemblyLine."Line No.", AssemblyLine."Document Type".AsInteger(), 0,
                AssemblyLine."Location Code", AssemblyLine."No.", AssemblyLine."Variant Code", AssemblyLine."Unit of Measure Code", AssemblyLine."Bin Code", QtyToPick, QtyToPickBase, EmptyGuid);
    end;

    local procedure MovementFromShipZone(var TotalAvailQtyBase: Decimal; QtyOnOutboundBins: Decimal)
    begin
        if not IsShipZone(CurrWhseWorksheetLine."Location Code", CurrWhseWorksheetLine."To Zone Code") then
            TotalAvailQtyBase := TotalAvailQtyBase - QtyOnOutboundBins;
    end;

    procedure IsShipZone(LocationCode: Code[10]; ZoneCode: Code[10]): Boolean
    var
        Zone: Record Zone;
        BinType: Record "Bin Type";
    begin
        if not Zone.Get(LocationCode, ZoneCode) then
            exit(false);
        if not BinType.Get(Zone."Bin Type Code") then
            exit(false);
        exit(BinType.Ship);
    end;

    local procedure Minimum(a: Decimal; b: Decimal): Decimal
    begin
        if a < b then
            exit(a);

        exit(b);
    end;

    local procedure Maximum(a: Decimal; b: Decimal): Decimal
    begin
        if a > b then
            exit(a);

        exit(b);
    end;

    procedure CalcQtyResvdNotOnILE(ReservEntryNo: Integer; ReservEntryPositive: Boolean) QtyResvdNotOnILE: Decimal
    var
        ReservEntry: Record "Reservation Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcQtyResvdNotOnILE(ReservEntryNo, ReservEntryPositive, QtyResvdNotOnILE, IsHandled);
        if not IsHandled then
            if ReservEntry.Get(ReservEntryNo, not ReservEntryPositive) then
                if ReservEntry."Source Type" <> Database::"Item Ledger Entry" then
                    QtyResvdNotOnILE += ReservEntry."Quantity (Base)";

        exit(QtyResvdNotOnILE);
    end;

    procedure SetFiltersOnReservEntry(var ReservationEntry: Record "Reservation Entry"; SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer)
    begin
        ReservationEntry.SetCurrentKey(
            "Source ID", "Source Ref. No.", "Source Type", "Source Subtype",
            "Source Batch Name", "Source Prod. Order Line", "Reservation Status");
        ReservationEntry.SetRange("Source ID", SourceNo);
        case SourceType of
            Database::Job, Database::"Job Planning Line":
                begin
                    ReservationEntry.SetRange("Source Ref. No.", SourceLineNo);
                    ReservationEntry.SetRange("Source Type", Database::"Job Planning Line");
                    ReservationEntry.SetRange("Source Subtype", Enum::"Job Planning Line Status"::Order);
                end;
            else begin
                ReservationEntry.SetRange("Source Ref. No.", SourceLineNo);
                ReservationEntry.SetRange("Source Type", SourceType);
                ReservationEntry.SetRange("Source Subtype", SourceSubType);
            end;
        end;
        ReservationEntry.SetRange("Reservation Status", "Reservation Status"::Reservation);

        OnAfterSetFiltersOnReservEntry(ReservationEntry, SourceType, SourceSubType, SourceNo, SourceLineNo, SourceSubLineNo);
    end;

    procedure GetActualQtyPickedBase(): Decimal
    begin
        exit(TotalQtyPickedBase);
    end;

    procedure CalcReservedQtyOnInventory(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; WhseItemTrackingSetup: record "Item Tracking Setup") ReservedQty: Decimal
    begin
        ReservedQty := CalcReservedQtyOnInventory(ItemNo, LocationCode, VariantCode, WhseItemTrackingSetup, 0);
    end;

    local procedure CalcReservedQtyOnInventory(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; WhseItemTrackingSetup: record "Item Tracking Setup"; ExcludeReservedQty: Decimal) ReservedQty: Decimal
    var
        CalcQtyInReservEntry: Query CalcQtyInReservEntry;
    begin
        ReservedQty := 0;

        CalcQtyInReservEntry.SetRange(Source_Type, Database::"Item Ledger Entry");
        CalcQtyInReservEntry.SetRange(Source_Subtype, 0);
        CalcQtyInReservEntry.SetRange(Reservation_Status, Enum::"Reservation Status"::Reservation);
        CalcQtyInReservEntry.SetRange(Location_Code, LocationCode);
        CalcQtyInReservEntry.SetRange(Item_No_, ItemNo);
        CalcQtyInReservEntry.SetRange(Variant_Code, VariantCode);
        CalcQtyInReservEntry.SetTrackingFilterFromWhseItemTrackingSetupIfRequired(WhseItemTrackingSetup);
        CalcQtyInReservEntry.Open();
        while CalcQtyInReservEntry.Read() do
            ReservedQty += GetReservedQtyByBinAndRemoveDedicatedAndBlockedQty(CalcQtyInReservEntry, ExcludeReservedQty); //This is needed to distribute reservation entries with tracking to different bin and reduce the reserved qty that is blocked by the bin

        OnAfterCalcReservedQtyOnInventory(
            ItemNo, LocationCode, VariantCode,
            WhseItemTrackingSetup."Lot No.", WhseItemTrackingSetup."Lot No. Required",
            WhseItemTrackingSetup."Serial No.", WhseItemTrackingSetup."Serial No. Required",
            ReservedQty, WhseItemTrackingSetup);
    end;

    local procedure GetReservedQtyByBinAndRemoveDedicatedAndBlockedQty(var CalcQtyInReservEntry: Query CalcQtyInReservEntry; var ExcludeReservedQty: Decimal): Decimal
    var
        TempBinContentBufferByBins: Record "Bin Content Buffer" temporary;
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        CalcQtyInWhseEntries: Query CalcQtyInWhseEntries;
        QtyLeftToDistribute: Decimal;
        QtyInBin: Decimal;
        Qty: Decimal;
    begin
        QtyLeftToDistribute := CalcQtyLeftToDistribute(ExcludeReservedQty, CalcQtyInReservEntry.Quantity__Base_); //ExcludeReservedQty is used to exclude reserved quantities that are already considered in other worksheet lines like pick worksheet. Therfore, there is no need to distribute them again.

        GetLocation(CalcQtyInReservEntry.Location_Code);

        CalcQtyInWhseEntries.SetRange(Location_Code, CalcQtyInReservEntry.Location_Code);
        CalcQtyInWhseEntries.SetRange(Item_No_, CalcQtyInReservEntry.Item_No_);
        CalcQtyInWhseEntries.SetRange(Variant_Code, CalcQtyInReservEntry.Variant_Code);
        CalcQtyInWhseEntries.SetRange(Serial_No_, CalcQtyInReservEntry.Serial_No_);
        CalcQtyInWhseEntries.SetRange(Lot_No_, CalcQtyInReservEntry.Lot_No_);
        CalcQtyInWhseEntries.SetRange(Package_No_, CalcQtyInReservEntry.Package_No_);
        CalcQtyInWhseEntries.Open();

        // step 1: distribute quantity by bins
        while CalcQtyInWhseEntries.Read() and (QtyLeftToDistribute <> 0) do begin
            QtyInBin := Minimum(QtyLeftToDistribute, CalcQtyInWhseEntries.Qty___Base_);
            QtyLeftToDistribute -= QtyInBin;

            WhseItemTrackingSetup."Serial No." := CalcQtyInWhseEntries.Serial_No_;
            WhseItemTrackingSetup."Lot No." := CalcQtyInWhseEntries.Lot_No_;
            WhseItemTrackingSetup."Package No." := CalcQtyInWhseEntries.Package_No_;
            TempBinContentBufferByBins.UpdateBuffer(
              CalcQtyInWhseEntries.Location_Code, CalcQtyInWhseEntries.Bin_Code,
              CalcQtyInWhseEntries.Item_No_, CalcQtyInWhseEntries.Variant_Code,
              CalcQtyInWhseEntries.Unit_of_Measure_Code, WhseItemTrackingSetup, QtyInBin);
        end;

        // step 2: remove blocked item tracking and quantity from dedicated bins for directed put-away and pick
        if TempBinContentBufferByBins.FindSet() then
            repeat
                if not BlockedBinOrTracking(TempBinContentBufferByBins) then
                    if CurrLocation."Directed Put-away and Pick" then begin
                        if not ReservedFromDedicatedBin(TempBinContentBufferByBins) then
                            Qty += TempBinContentBufferByBins."Qty. to Handle (Base)";
                    end
                    else
                        Qty += TempBinContentBufferByBins."Qty. to Handle (Base)";
            until TempBinContentBufferByBins.Next() = 0;

        exit(Qty);
    end;

    local procedure ReservedFromDedicatedBin(var TempBinContentBuffer: Record "Bin Content Buffer" temporary): Boolean
    var
        BinContent: Record "Bin Content";
        ExcludeEntry: Boolean;
    begin
        BinContent.ReadIsolation := IsolationLevel::ReadUncommitted;
        if BinContent.Get(TempBinContentBuffer."Location Code", TempBinContentBuffer."Bin Code", TempBinContentBuffer."Item No.", TempBinContentBuffer."Variant Code", TempBinContentBuffer."Unit of Measure Code") then begin
            ExcludeEntry := BinContent.Dedicated;
            if ExcludeEntry then
                ExcludeEntry := not (TempBinContentBuffer."Bin Code" in [
                        CurrLocation."From-Production Bin Code",
                        CurrLocation."To-Production Bin Code",
                        CurrLocation."Open Shop Floor Bin Code",
                        CurrLocation."From-Assembly Bin Code",
                        CurrLocation."To-Assembly Bin Code"]);
        end;

        exit(ExcludeEntry);
    end;

    local procedure BlockedBinOrTracking(BinContentBuffer: Record "Bin Content Buffer"): Boolean
    var
        LotNoInformation: Record "Lot No. Information";
        SerialNoInformation: Record "Serial No. Information";
        IsBlocked: Boolean;
    begin
        if BinContentBlocked(BinContentBuffer."Location Code", BinContentBuffer."Bin Code", BinContentBuffer."Item No.", BinContentBuffer."Variant Code", BinContentBuffer."Unit of Measure Code") then
            exit(true);
        if LotNoInformation.Get(BinContentBuffer."Item No.", BinContentBuffer."Variant Code", BinContentBuffer."Lot No.") then
            if LotNoInformation.Blocked then
                exit(true);
        if SerialNoInformation.Get(BinContentBuffer."Item No.", BinContentBuffer."Variant Code", BinContentBuffer."Serial No.") then
            if SerialNoInformation.Blocked then
                exit(true);

        IsBlocked := false;
        OnAfterBlockedBinOrTracking(BinContentBuffer, IsBlocked);
        if IsBlocked then
            exit(true);

        exit(false);
    end;

    local procedure GetMessageForUnhandledQtyDueToBin(BinIsForPick: Boolean; BinIsForReplenishment: Boolean; IsMoveWksh: Boolean; AvailableQtyBase: Decimal; var FromBinContent: Record "Bin Content") Result: Text
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetMessageForUnhandledQtyDueToBinProcedure(BinIsForPick, BinIsForReplenishment, IsMoveWksh, AvailableQtyBase, FromBinContent, Result, IsHandled);
        if IsHandled then
            exit;

        if AvailableQtyBase <= 0 then
            exit('');
        if not BinIsForPick and not IsMoveWksh then
            exit(StrSubstNo(BinIsNotForPickTxt, FromBinContent."Bin Code"));
        if not BinIsForReplenishment and IsMoveWksh then
            exit(StrSubstNo(BinIsForReceiveOrShipTxt, FromBinContent."Bin Code"));
    end;

    local procedure GetMessageForUnhandledQtyDueToReserv(): Text
    begin
        exit(QtyReservedNotFromInventoryTxt);
    end;

    procedure FilterWhsePickLinesWithUndefinedBin(var WarehouseActivityLine: Record "Warehouse Activity Line"; ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        WarehouseActivityLine.Reset();
        WarehouseActivityLine.SetCurrentKey(
            "Item No.", "Bin Code", "Location Code", "Action Type", "Variant Code", "Unit of Measure Code", "Breakbulk No.", "Activity Type");
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        WarehouseActivityLine.SetRange("Bin Code", '');
        WarehouseActivityLine.SetRange("Location Code", LocationCode);
        WarehouseActivityLine.SetRange("Action Type", "Warehouse Action Type"::Take);
        WarehouseActivityLine.SetRange("Variant Code", VariantCode);
        WarehouseActivityLine.SetTrackingFilterFromWhseItemTrackingSetupIfNotBlank(WhseItemTrackingSetup);
        WarehouseActivityLine.SetRange("Breakbulk No.", 0);
        WarehouseActivityLine.SetRange("Activity Type", "Warehouse Activity Type"::Pick);
    end;

    procedure EnqueueCannotBeHandledReason(CannotBeHandledReason: Text)
    var
        NewReasonAdded: Boolean;
        i: Integer;
    begin
        if CannotBeHandledReason = '' then
            exit;

        repeat
            i += 1;
            if CannotBeHandledReasons[i] = '' then begin
                CannotBeHandledReasons[i] := CannotBeHandledReason;
                NewReasonAdded := true;
            end;
        until NewReasonAdded or (i = ArrayLen(CannotBeHandledReasons));
    end;

    local procedure DequeueCannotBeHandledReason() CannotBeHandledReason: Text
    begin
        CannotBeHandledReason := CannotBeHandledReasons[1];
        CannotBeHandledReasons[1] := '';
        CompressArray(CannotBeHandledReasons);
    end;

    local procedure CheckCanNotBeHandledReasonAlreadyAdded(CannotBeHandledReason: Text): Boolean
    var
        i: Integer;
    begin
        repeat
            i += 1;
            if CannotBeHandledReasons[i] = '' then
                exit(false);

            if CannotBeHandledReasons[i] = CannotBeHandledReason then
                exit(true);
        until (i = ArrayLen(CannotBeHandledReasons));
    end;

    local procedure LockTables()
    var
        WarehouseActivityHeaderToLock: Record "Warehouse Activity Header";
        WarehouseActivityLineToLock: Record "Warehouse Activity Line";
    begin
        WarehouseActivityHeaderToLock.Lock();
        WarehouseActivityLineToLock.Lock();
    end;

    internal procedure SetSaveSummary(NewSaveSummary: Boolean)
    begin
        SaveSummary := NewSaveSummary;
    end;

    local procedure InitCalculationSummary(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; UnitofMeasureCode: Code[10]; FromBinCode: Code[20]; TotalQtytoPick: Decimal; TotalQtytoPickBase: Decimal)
    begin
        if CanSaveSummary() then begin
            TempWarehousePickSummary.Init();
            TempWarehousePickSummary.IncrementEntryNumber();
            SetSourceDocumentInfoInCalcSummary(CurrSourceType, CurrSourceNo, CurrSourceLineNo, CurrSourceSubType, CurrSourceSubLineNo);
            SetItemInfoInCalcSummary(LocationCode, ItemNo, VariantCode, UnitofMeasureCode, FromBinCode, TotalQtytoPick, TotalQtytoPickBase);
        end;
    end;

    local procedure SetSourceDocumentInfoInCalcSummary(SourceType2: Integer; SourceNo2: Code[20]; SourceLineNo2: Integer; SourceSubType2: Option; SourceSubLineNo2: Integer)
    begin
        TempWarehousePickSummary."Source Type" := SourceType2;
        TempWarehousePickSummary."Source No." := SourceNo2;
        TempWarehousePickSummary."Source Line No." := SourceLineNo2;
        TempWarehousePickSummary."Source Subtype" := SourceSubType2;
        TempWarehousePickSummary."Source Subline No." := SourceSubLineNo2;
        TempWarehousePickSummary."Source Document" := WhseManagement.GetWhseActivSourceDocument(SourceType2, SourceSubType2);
    end;

    local procedure SetItemInfoInCalcSummary(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; UnitofMeasureCode: Code[10]; FromBinCode: Code[20]; QtyToPick: Decimal; QtytoPickBase: Decimal)
    begin
        TempWarehousePickSummary."Location Code" := LocationCode;
        TempWarehousePickSummary."Item No." := ItemNo;
        TempWarehousePickSummary."Variant Code" := VariantCode;
        TempWarehousePickSummary."Unit of Measure Code" := UnitofMeasureCode;
        TempWarehousePickSummary."Bin Code" := FromBinCode;
        TempWarehousePickSummary."Qty. to Handle" := QtyToPick;
        TempWarehousePickSummary."Qty. to Handle (Base)" := QtytoPickBase;
    end;

    internal procedure InsertSkippedLinesToCalculationSummary(SourceType2: Integer; SourceNo2: Code[20]; SourceLineNo2: Integer; SourceSubType2: Option; SourceSubLineNo2: Integer; LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; UnitofMeasureCode: Code[10]; FromBinCode: Code[20]; QtyToPick: Decimal; QtytoPickBase: Decimal; WhseWorksheetLineSystemID: Guid)
    begin
        GetLocation(LocationCode);
        if CanSaveSummary() then begin
            TempWarehousePickSummary.Init();
            TempWarehousePickSummary.IncrementEntryNumber();
            SetSourceDocumentInfoInCalcSummary(SourceType2, SourceNo2, SourceLineNo2, SourceSubType2, SourceSubLineNo2);
            SetItemInfoInCalcSummary(LocationCode, ItemNo, VariantCode, UnitofMeasureCode, FromBinCode, QtyToPick, QtytoPickBase);
            if not IsNullGuid(WhseWorksheetLineSystemID) then
                TempWarehousePickSummary.ActiveWhseWorksheetLine := WhseWorksheetLineSystemID;
            TempWarehousePickSummary.Insert();
        end;
    end;

    local procedure FinalizeCalculationSummary()
    begin
        if CanSaveSummary() then begin
            TempWarehousePickSummary."Qty. handled" := TotalQtyPickedBase;
            TempWarehousePickSummary."Qty. handled (base)" := TotalQtyPickedBase;
            TempWarehousePickSummary.Insert();
        end;
    end;

    local procedure UpdateCalculationSummaryQuantities(TotalAvailQtyBase: Decimal; MaxPickableQtyInWhse: Decimal; QtyAssignedPick: Decimal; MaxPickableQtyExcludingShipBin: Decimal; ReservedQtyOnInventory: Decimal; QtyReservedOnPickShip: Decimal; LineReservedQty: Decimal)
    begin
        if CanSaveSummary() then begin
            TempWarehousePickSummary."Potential pickable qty." := MaxPickableQtyInWhse;
            TempWarehousePickSummary."Qty. assigned" := QtyAssignedPick;
            TempWarehousePickSummary."Qty. available to pick" := TotalAvailQtyBase;

            if not CalledFromMoveWksh then begin
                //Needed to balance reserved quantities when not called from Movement Worksheet
                TempWarehousePickSummary."Qty. Reserved in warehouse" := ReservedQtyOnInventory;
                TempWarehousePickSummary."Qty. res. in pick/ship bins" := QtyReservedOnPickShip;
                TempWarehousePickSummary."Qty. Reserved for this line" := LineReservedQty;
                TempWarehousePickSummary."Available qty. not in ship bin" := MaxPickableQtyExcludingShipBin;
            end;
        end;
    end;

    local procedure UpdateCalculationSummaryQuantitiesForMaxPickableQtyInWhse(QtyInWhse: Decimal; QtyInBinNotBlockedNotDedicated: Decimal; QtyWithBlockedItemTracking: Decimal; QtyAssignedInWhseActLinesNotBlockedNotDedicated: Decimal; BinTypeFilter: Option ExcludeReceive,ExcludeShip,OnlyPickBins; QtyInBinNotBlockedNotDedicatedWithoutItemTrackingFilter: Decimal)
    begin
        if not CanSaveSummary() then
            exit;

        if CalledFromMoveWksh then
            case BinTypeFilter of
                BinTypeFilter::ExcludeReceive:
                    begin
                        TempWarehousePickSummary."Qty. in blocked item tracking" := QtyWithBlockedItemTracking;
                        TempWarehousePickSummary."Qty. in active pick lines" := QtyAssignedInWhseActLinesNotBlockedNotDedicated;
                        TempWarehousePickSummary."Qty. in pickable Bins" := QtyInBinNotBlockedNotDedicated;
                    end;
            end
        else
            case BinTypeFilter of
                BinTypeFilter::OnlyPickBins:
                    begin
                        TempWarehousePickSummary."Qty. in blocked item tracking" := QtyWithBlockedItemTracking;
                        TempWarehousePickSummary."Qty. in active pick lines" := QtyAssignedInWhseActLinesNotBlockedNotDedicated;
                        TempWarehousePickSummary."Qty. in Warehouse" := QtyInWhse;
                        if QtyInBinNotBlockedNotDedicatedWithoutItemTrackingFilter <> 0 then
                            TempWarehousePickSummary."Qty. in pickable Bins" := QtyInBinNotBlockedNotDedicatedWithoutItemTrackingFilter
                        else
                            TempWarehousePickSummary."Qty. in pickable Bins" := QtyInBinNotBlockedNotDedicated;
                    end;
                BinTypeFilter::ExcludeShip: //Needed to balance reserved quantities when not called from Movement Worksheet
                    begin
                        TempWarehousePickSummary."Qty. block. Item Tracking Res." := QtyWithBlockedItemTracking;
                        TempWarehousePickSummary."Qty. in active pick lines Res." := QtyAssignedInWhseActLinesNotBlockedNotDedicated;
                        TempWarehousePickSummary."Qty. not in ship bin" := QtyInBinNotBlockedNotDedicated;
                        TempWarehousePickSummary."Qty. in Warehouse" := QtyInWhse;
                    end;
            end;
    end;

    local procedure CanSaveSummary(): Boolean
    begin
        exit(SaveSummary and CurrLocation."Directed Put-away and Pick");
    end;

    local procedure CalcQtyOnToBinsBase(WhseItemTrackingSetup: Record "Item Tracking Setup"; var QtyOnToBinsBase: Decimal; LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10])
    var
        QtyOnToBinsBaseInPicks: Decimal;
    begin
        if CurrWhseWorksheetLine."To Bin Code" = '' then
            exit;

        if IsShipZone(CurrWhseWorksheetLine."Location Code", CurrWhseWorksheetLine."To Zone Code") then
            exit;

        QtyOnToBinsBase := SumWhseEntries(ItemNo, LocationCode, VariantCode, WhseItemTrackingSetup, '', CurrWhseWorksheetLine."To Bin Code", false);
        QtyOnToBinsBaseInPicks := CalcQtyAssignedToPick(ItemNo, LocationCode, VariantCode, CurrWhseWorksheetLine."To Bin Code", WhseItemTrackingSetup);
        QtyOnToBinsBase -= Minimum(QtyOnToBinsBase, QtyOnToBinsBaseInPicks);
    end;

    internal procedure SetSummaryPageMessage(MessageTxt: Text; OverwriteMessage: Boolean)
    begin
        if OverwriteMessage then
            SummaryPageMessage := MessageTxt
        else
            if SummaryPageMessage = '' then
                SummaryPageMessage := MessageTxt;
    end;

    internal procedure ShowCalculationSummary(): Boolean
    var
        WarehousePickSummaryPage: Page "Warehouse Pick Summary";
    begin
        if CanSaveSummary() then
            if TempWarehousePickSummary.Count > 0 then begin
                WarehousePickSummaryPage.SetRecords(TempWarehousePickSummary, SummaryPageMessage, CalledFromMoveWksh);
                WarehousePickSummaryPage.Run();
                exit(true);
            end;
    end;

    local procedure CalcQtyLeftToDistribute(var ExcludeReservedQty: Decimal; QtyBase: Decimal): Decimal
    begin
        if ExcludeReservedQty < QtyBase then
            exit(QtyBase - ExcludeReservedQty);

        if ExcludeReservedQty = 0 then
            exit(ExcludeReservedQty - QtyBase);

        ExcludeReservedQty := ExcludeReservedQty - QtyBase;

        exit(0);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcQtyOnPickAndReceiveBins(SourceType: Integer; LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; LotNo: Code[50]; SerialNo: Code[50]; CalledFromPickWksh: Boolean; CalledFromMoveWksh: Boolean; CalledFromWksh: Boolean; var QtyInWhse: Decimal; var QtyOnPickBins: Decimal; var QtyOnPutAwayBins: Decimal; var QtyOnOutboundBins: Decimal; var QtyOnReceiveBins: Decimal; var QtyOnDedicatedBins: Decimal; var QtyBlocked: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcReservedQtyOnInventory(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; LotNo: Code[50]; LNRequired: Boolean; SerialNo: Code[50]; SNRequired: Boolean; var ReservedQty: Decimal; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

#if not CLEAN27
    [Obsolete('Not used anymore.', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcTotalQtyAssgndOnWhse(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; var QtyAssgndToWhseAct: Decimal; var QtyAssgndToShipment: Decimal; var QtyAssgndToProdComp: Decimal; var QtyAssgndToAsmLine: Decimal);
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckOutBound(SourceType: Integer; SourceSubType: Integer; SourceNo: Code[20]; SourceLineNo: Integer; var OutBoundQty: Decimal; SourceSubLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckReservation(var Quantity: Decimal; var QuantityBase: Decimal; var QtyBaseAvailToPick: Decimal; var ReservationExists: Boolean; SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterWhseActivLineInsert(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCreateTempLine(LocationCode: Code[10]; ToBinCode: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; UnitofMeasureCode: Code[10]; QtyPerUnitofMeasure: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateTempLineCheckReservation(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; UnitofMeasureCode: Code[10]; QtyPerUnitofMeasure: Decimal; var TotalQtytoPick: Decimal; var TotalQtytoPickBase: Decimal; SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer; var LastWhseItemTrkgLineNo: Integer; var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary; var WhseShptLine: Record "Warehouse Shipment Line"; var QtyBaseMaxAvailToPick: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateTempWhseItemTrackingLines(var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateWhseDocument(var FirstWhseDocNo: Code[20]; var LastWhseDocNo: Code[20]; CreatePickParameters: Record "Create Pick Parameters")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateWhseDocLine(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindWhseActivLine(var FirstWhseDocNo: Code[20]; var LastWhseDocNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetSourceWhseItemTrkgLine(var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary; var LastWhseItemTrkgLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetParameters(var CreatePickParameters: Record "Create Pick Parameters");
    begin
    end;

#if not CLEAN27
    [Obsolete('Replaced by OnAfterSetCustomWhseSourceLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterSetAssemblyLine(var AssemblyLine: Record Microsoft.Assembly.Document."Assembly Line")
    begin
    end;

    [Obsolete('Replaced by OnAfterSetCustomWhseSourceLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterSetProdOrderCompLine(var ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetCustomWhseSourceLine(CustomSourceWhseSourceLine: Variant)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetWhseShipment(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; TempNo2: Integer; var ShippingAgentCode2: Code[10]; var ShippingAgentServiceCode2: Code[10]; var ShipmentMethodCode2: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetWhseWkshLine(var WhseWorksheetLine: Record "Whse. Worksheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetWhseInternalPickLine(var WhseInternalPickLine: Record "Whse. Internal Pick Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferItemTrkgFields(var WarehouseActivityLine: Record "Warehouse Activity Line"; WhseItemTrackingLine: Record "Whse. Item Tracking Line"; EntriesExist: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAdjustQtyReservedOnPickShip(var SubTotal: Decimal; QtyReservedOnPickShip: Decimal; LineReservedQty: Decimal; ReservedQtyOnInventory: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcQtyResvdNotOnILE(ReservEntryNo: Integer; ReservEntryPositive: Boolean; var QtyResvdNotOnILE: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateWhseDocTakeLineProcedure(var WhseActivLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCalcPickBin(var TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary; var TotalQtytoPick: Decimal; var TotalQtytoPickBase: Decimal; var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary; CrossDock: Boolean; WhseTrackingExists: Boolean; WhseSource: Option "Pick Worksheet",Shipment,"Movement Worksheet","Internal Pick",Production,Assembly; LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; UnitofMeasureCode: Code[10]; ToBinCode: Code[20]; QtyPerUnitofMeasure: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCalcBWPickBin(var TotalQtyToPick: Decimal; var TotalQtytoPickBase: Decimal; var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary; var TempWhseActivLine: Record "Warehouse Activity Line" temporary; WhseItemTrkgExists: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcTotalAvailQtyToPick(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; LotNo: Code[50]; SerialNo: Code[50]; SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer; NeededQtyBase: Decimal; RespectLocationBins: Boolean; CalledFromMoveWksh: Boolean; CalledFromWksh: Boolean; var TempWhseActivLine: Record "Warehouse Activity Line" temporary; var IsHandled: Boolean; var TotalAvailQtyBase: Decimal; WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyToTempWhseItemTrkgLine(WhseItemTrackingLine: Record "Whse. Item Tracking Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateWhseDocument(var TempWhseActivLine: Record "Warehouse Activity Line" temporary; WhseSource: Option "Pick Worksheet",Shipment,"Movement Worksheet","Internal Pick",Production,Assembly; var IsHandled: Boolean; IsMovementWorksheet: Boolean; var FirstWhseDocNo: Code[20]; var LastWhseDocNo: Code[20]; CreatePickParameters: Record "Create Pick Parameters")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCreateNewWhseDoc(var TempWhseActivLine: Record "Warehouse Activity Line" temporary; OldNo: Code[20]; OldSourceNo: Code[20]; OldLocationCode: Code[10]; var FirstWhseDocNo: Code[20]; var LastWhseDocNo: Code[20]; var NoOfSourceDoc: Integer; var NoOfLines: Integer; var WhseDocCreated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateTempItemTrkgLines(Location: Record Location; ItemNo: Code[20]; VariantCode: Code[10]; var TotalQtytoPickBase: Decimal; HasExpiryDate: Boolean; var IsHandled: Boolean; var WhseItemTrackingFEFO: Codeunit "Whse. Item Tracking FEFO"; WhseShptLine: Record "Warehouse Shipment Line"; WhseWkshLine: Record "Whse. Worksheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateTempActivityLine(BinCode: Code[20]; QtyToPick: Decimal; QtyToPickBase: Decimal; ActionType: Integer; LocationCode: Code[10]; UOMCode: Code[10]; QtyPerUOM: Decimal; WarehouseShipmentLine: Record "Warehouse Shipment Line"; var CreatePickParameters: Record "Create Pick Parameters"; var TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary; var Bin: Record Bin; WhseItemTrkgExists: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetBinTypeFilter(var BinTypeFilter: Text[1024]; var IsHandled: Boolean; Type: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetMessageForUnhandledQtyDueToBinProcedure(var BinIsForPick: Boolean; var BinIsForReplenishment: Boolean; var IsMoveWksh: Boolean; var AvailableQtyBase: Decimal; FromBinContent: Record "Bin Content"; var Result: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindBWPickBin(var BinContent: Record "Bin Content"; var IsSetCurrentKeyHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindBreakBulkBinPerBinContent(FromBinContent: Record "Bin Content"; ItemNo: Code[20]; VariantCode: Code[10]; WhseItemTrackingSetup: Record "Item Tracking Setup"; WhseItemTrkgExists: Boolean; var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary; SourceType: Integer; SourceSubType: Integer; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer; TotalQtyToPickBase: Decimal; var QtyAvailableBase: Decimal; var StopProcessing: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetBinCodeFilter(var BinCodeFilterText: Text[250]; LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; ToBinCode: Code[20]; var IsHandled: Boolean; SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePickStrictExpirationPosting(ItemNo: Code[20]; SNRequired: Boolean; LNRequired: Boolean; var StrictExpirationPosting: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeItemTrackedQuantity(var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary; WhseItemTrackingSetup: Record "Item Tracking Setup"; var QtyToHandleBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeInsertTempItemTrkgLine(var EntrySummary: Record "Entry Summary"; RemQtyToPickBase: Decimal; var TotalAvailQtyToPickBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunFindBWPickBinLoop(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; ToBinCode: Code[20];
        UnitofMeasureCode: Code[10]; QtyPerUnitofMeasure: Decimal; var TotalQtyToPick: Decimal; var TotalQtyToPickBase: Decimal;
        var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary; WhseItemTrackingSetup: Record "Item Tracking Setup"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempWhseActivLineInsert(var TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary; ActionType: Integer; WhseSource2: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempWhseItemTrkgLineInsert(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; FromWhseItemTrackingLine: Record "Whse. Item Tracking Line"; EntrySummary: Record "Entry Summary")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempWhseItemTrackingLineModify(var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempWhseItemTrackingLineModifyOnAfterAssignRemQtyToPickBase(var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUseForPick(var FromBinContent: Record "Bin Content"; var IsForPick: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateWhseActivLineQtyFIeldsFromCreateWhseDocPlaceLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseActivHeaderInsert(var WarehouseActivityHeader: Record "Warehouse Activity Header"; var TempWhseActivityLine: Record "Warehouse Activity Line" temporary; CreatePickParameters: Record "Create Pick Parameters"; WhseShptLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseActivLineInsert(var WarehouseActivityLine: Record "Warehouse Activity Line"; WarehouseActivityHeader: Record "Warehouse Activity Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQtyForSN(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcAvailQtyOnFindBWPickBin(ItemNo: Code[20]; VariantCode: Code[10]; SNRequired: Boolean; LNRequired: Boolean; WhseItemTrkgExists: Boolean; SerialNo: Code[50]; LotNo: Code[50]; LocationCode: Code[10]; BinCode: Code[20]; SourceType: Integer; SourceSubType: Integer; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer; TotalQtyToPickBase: Decimal; var QtyAvailableBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcAvailQtyOnFindPickBin2(ItemNo: Code[20]; VariantCode: Code[10]; SNRequired: Boolean; LNRequired: Boolean; WhseItemTrkgExists: Boolean; LotNo: Code[50]; SerialNo: Code[50]; LocationCode: Code[10]; BinCode: Code[20]; SourceType: Integer; SourceSubType: Integer; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer; TotalQtyToPickBase: Decimal; var QtyAvailableBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcAvailableQtyOnAfterCalcAvailableQtyBase(Item: Record Item; Location: Record Location; VariantCode: Code[10]; SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer; var AvailableQtyBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcAvailQtyOnFindBreakBulkBin(Broken: Boolean; ItemNo: Code[20]; VariantCode: Code[10]; SNRequired: Boolean; LNRequired: Boolean; WhseItemTrkgExists: Boolean; SerialNo: Code[50]; LotNo: Code[50]; LocationCode: Code[10]; BinCode: Code[20]; SourceType: Integer; SourceSubType: Integer; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer; TotalQtyToPickBase: Decimal; var QtyAvailableBase: Decimal; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcAvailQtyOnFindSmallerUOMBin(Broken: Boolean; ItemNo: Code[20]; VariantCode: Code[10]; SNRequired: Boolean; LNRequired: Boolean; WhseItemTrkgExists: Boolean; SerialNo: Code[50]; LotNo: Code[50]; LocationCode: Code[10]; BinCode: Code[20]; SourceType: Integer; SourceSubType: Integer; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer; TotalQtyToPickBase: Decimal; var QtyAvailableBase: Decimal; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcMaxQtyOnAfterTempWhseActivLineSetFilters(var TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcQtyAssignedToPickOnAfterSetFilters(var WarehouseActivityLine: Record "Warehouse Activity Line"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckReservationOnAfterGetOutboundDocLineQtyOtsdg(var ReservationEntry: Record "Reservation Entry"; var SrcDocQtyToBeFilledByInvt: Decimal; var SrcDocQtyBaseToBeFilledByInvt: Decimal; var QtyResvdNotOnILE: Decimal; var QtyBaseResvdNotOnILE: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyToTempWhseItemTrkgLineOnBeforeTempWhseItemTrackingLineInsert(var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTempItemTrkgLinesOnBeforeGetFromBinContentQty(EntrySummary: Record "Entry Summary"; ItemNo: Code[20]; VariantCode: Code[10]; var TotalAvailQtyToPickBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTempItemTrkgLinesOnAfterCalcQtyTracked(EntrySummary: Record "Entry Summary"; var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary; var QuantityTracked: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTempItemTrkgLinesOnBeforeCheckQtyToPickBase(EntrySummary: Record "Entry Summary"; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; TotalAvailQtyToPickBase: Decimal; var QtytoPickBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTempActivityLineOnAfterTransferFrom(var TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary; WhseSource: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTempActivityLineOnAfterShouldCalcMaxQty(var TempWarehouseActivityLine: Record "Warehouse Activity Line"; var BreakBulkNo: Integer; var ShouldCalcMaxQty: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTempActivityLineAfterAssignSpecEquipment(var TempWhseActivLine: Record "Warehouse Activity Line" temporary; QtyToPick: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTempActivityLineOnAfterValidateQuantity(var TempWhseActivLine: Record "Warehouse Activity Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTempLine2OnBeforeDirectedPutAwayAndPick(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; UnitofMeasureCode: Code[10]; FromBinCode: Code[20]; ToBinCode: Code[20]; QtyPerUnitofMeasure: Decimal; var TotalQtytoPick: Decimal; var TotalQtytoPickBase: Decimal; var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary; WhseSource: Option "Pick Worksheet",Shipment,"Movement Worksheet","Internal Pick",Production,Assembly; var IsHandled: Boolean; ReservationExists: Boolean; ReservedForItemLedgEntry: Boolean; var TempWhseActivLine: Record "Warehouse Activity Line" temporary; var TempLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTempLineOnAfterCreateTempLineWithItemTracking(var TotalQtytoPickBase: Decimal; var HasExpiredItems: Boolean; LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; UnitofMeasureCode: Code[10]; FromBinCode: Code[20]; ToBinCode: Code[20]; QtyPerUnitofMeasure: Decimal; var TempWhseActivLine: Record "Warehouse Activity Line" temporary; var TempLineNo: Integer; var IsHandled: Boolean; var TotalItemTrackedQtyToPickBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTempLineOnAfterCalcQtyBaseMaxAvailToPick(var QtyBaseMaxAvailToPick: Decimal; LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTempLineOnBeforeCheckReservation(SourceType: Integer; SourceNo: Code[20]; SourceLineNo: Integer; var QtyBaseMaxAvailToPick: Decimal; var isHandled: Boolean; LocationCode: Code[10]; ItemNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTempActivityLineOnAfterCalcQtyToPick(var TempWhseActivLine: Record "Warehouse Activity Line" temporary; var QtyToPick: Decimal; var QtyToPickBase: Decimal; WhseSource: Option "Pick Worksheet",Shipment,"Movement Worksheet","Internal Pick",Production,Assembly; WhseSource2: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTempLineOnBeforeCreateTempLineForSerialNo(
        LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; UnitofMeasureCode: Code[10];
        FromBinCode: Code[20]; ToBinCode: Code[20]; QtyPerUnitofMeasure: Decimal; TotalQtytoPick: Decimal; TotalQtytoPickBase: Decimal;
        var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary; WhseItemTrackingSetup: Record "Item Tracking Setup";
        var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTempLineOnBeforeUpdateQuantitesToPick(var QtyAvailableBase: Decimal; var QtyPerUOM: Decimal; var QtyToPick: Decimal; var QtyToPickBase: Decimal; var TotalQtyToPick: Decimal; var TotalQtyToPickBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateWhseDocumentOnAfterSaveOldValues(var TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary; var WarehouseActivityHeader: Record "Warehouse Activity Header"; LastWhseDocNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateWhseDocumentOnAfterSetFiltersAfterLoop(var TempWhseActivLine: Record "Warehouse Activity Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateWhseDocumentOnAfterSetFiltersBeforeLoop(var TempWhseActivLine: Record "Warehouse Activity Line" temporary; PerBin: Boolean; PerZone: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateWhseDocumentOnBeforeClearFilters(var TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary; var WhseActivHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateWhseDocumentOnBeforeCreateDocAndLine(var TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary; var IsHandled: Boolean; var CreateNewHeader: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateWhseDocumentOnBeforeShowError(var ShowError: Boolean; var FirstWhseDocNo: Code[20]; CannotBeHandledReasons: array[20] of Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateWhseDocTakeLineOnAfterSetFilters(var TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary; WarehouseActivityLine: Record "Warehouse Activity Line"; var WhseActivLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateWhseDocTakeLineOnBeforeWhseActivLine2Insert(var WarehouseActivityLine: Record "Warehouse Activity Line"; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateWhseDocPlaceLineOnAfterSetFilters(var TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary; WarehouseActivityLine: Record "Warehouse Activity Line"; LineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateWhseDocPlaceLineOnBeforeWhseActivLineInsert(var WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindBWPickBinOnBeforeEndLoop(var FromBinContent: Record "Bin Content"; var TotalQtyToPickBase: Decimal; var EndLoop: Boolean; var IsHandled: Boolean; QtytoPick: Decimal; QtyToPickBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindBWPickBinOnBeforeFromBinContentFindSet(var FromBinContent: Record "Bin Content"; SourceType: Integer; var TotalQtyPickedBase: Decimal; var TotalQtyToPickBase: Decimal; var IsHandled: Boolean; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer; LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; ToBinCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindBWPickBinOnBeforeSetQtyAvailableBaseForSerialNo(var FromBinContent: Record "Bin Content"; var QtyAvailableBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindPickBinOnAfterUpdateTotalAvailQtyToPickBase(var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary; TotalAvailQtyToPickBase: Decimal; ToQtyToPick: Decimal; ToQtyToPickBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindPickBinOnBeforeStartFromBinContentLoop(var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary; var TotalAvailQtyToPickBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindPickBinOnBeforeUpdateQuantitesAndCreateActivityLines(var FromBinContent: Record "Bin Content"; var TempWhseActivLine: Record "Warehouse Activity Line" temporary; var ToQtyToPick: Decimal; var ToQtyToPickBase: Decimal; var AvailableQtyBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcTotalAvailQtyToPickOnBeforeCalcSubTotal(var QtyInWhse: Decimal; var QtyOnPickBins: Decimal; var QtyOnPutAwayBins: Decimal; var QtyOnOutboundBins: Decimal; var QtyOnDedicatedBins: Decimal; var QtyBlocked: Decimal; var QtyOnReceiveBins: Decimal; var ReservedQtyOnInventory: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcTotalAvailQtyToPickOnAfterGetWhseItemTrkgSetup(var WhseItemTrackingSetup: Record "Item Tracking Setup"; LocationCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcQtyCanBePickedOnAfterGetWhseItemTrkgSetup(var WhseItemTrackingSetup: Record "Item Tracking Setup"; LocationCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateWhseDocLineOnAfterGetWhseItemTrkgSetup(var WhseItemTrackingSetup: Record "Item Tracking Setup"; TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcPickBinOnAfterGetWhseItemTrkgSetup(var WhseItemTrackingSetup: Record "Item Tracking Setup"; LocationCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateWhseDocTakeLineOnBeforeWhseActivLineInsert(var WarehouseActivityLine: Record "Warehouse Activity Line"; WarehouseActivityHeader: Record "Warehouse Activity Header"; TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPickAccordingToFEFO(LocationCode: Code[10]; ItemTrackingSetup: Record "Item Tracking Setup"; var PickAccordingToFEFO: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProcessDoNotFillQtytoHandle(var WarehouseActivityLine: Record "Warehouse Activity Line"; var TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateWhseActivHeaderOnAfterWhseActivHeaderInsert(var WhseActivHeader: Record "Warehouse Activity Header"; var TempWhseActivLine: Record "Warehouse Activity Line" temporary; CreatePickParameters: Record "Create Pick Parameters")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterBlockedBinOrTracking(BinContentBuffer: Record "Bin Content Buffer"; var IsBlocked: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemTrackedQuantityOnAfterCheckIfEmpty(var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary; WhseItemTrackingSetup: Record "Item Tracking Setup"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemTrackedQuantityOnAfterSetFilters(var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateWhseDocTakeLine(var WhseActivLine: Record "Warehouse Activity Line"; Location: Record Location; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateAssemblyPickLineOnAfterCalcQtyToPick(var AsmLine: Record Microsoft.Assembly.Document."Assembly Line"; var QtyToPickBase: Decimal; var QtyToPick: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateWhseDocPlaceLineOnAfterTempWhseActivLineSetFilters(var TempWhseActivLine: Record "Warehouse Activity Line"; WhseActivLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateWhseDocPlaceLineOnAfterTransferTempWhseActivLineToWhseActivLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; var TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary; PickQty: Decimal; PickQtyBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetBinContent(
        var TempBinContent: Record "Bin Content" temporary;
        ItemNo: Code[20]; VariantCode: Code[10]; UnitofMeasureCode: Code[10]; LocationCode: Code[10]; ToBinCode: Code[20];
        CrossDock: Boolean; IsMovementWorksheet: Boolean; WhseItemTrkgExists: Boolean; BreakbulkBins: Boolean; SmallerUOMBins: Boolean;
        WhseItemTrackingSetup: Record "Item Tracking Setup"; TotalQtytoPick: Decimal; TotalQtytoPickBase: Decimal;
        var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindPickBin(
        LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10];
        UnitofMeasureCode: Code[10]; ToBinCode: Code[20]; QtyRndPrec: Decimal; QtyRndPrecBase: Decimal;
        var TempWhseActivLine2: Record "Warehouse Activity Line" temporary; var TotalQtytoPick: Decimal;
        var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary; CrossDock: Boolean;
        var TotalQtytoPickBase: Decimal; WhseItemTrackingSetup: Record "Item Tracking Setup"; IsMovementWorksheet: Boolean;
        WhseItemTrkgExists: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetLocation(LocationCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcQtyOutstandingBaseAfterSetFilters(var TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary; var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary; LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; UOMCode: Code[10]; BinCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindBWPickBinOnBeforeApplyBinCodeFilter(var BinCodeFilterText: Text[250]; CurrLocation: Record Location)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateTempActivityLineWithoutBinCode(var BinCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePutawayForPostedWhseReceiptLine(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; UnitOfMeasureCode: Code[10]; QtyPerUnitofMeasure: Decimal; QtyRoundingPrecision: Decimal; QtyRoundingPrecisionBase: Decimal; var TotalQtyToPick: Decimal; var TotalQtytoPickBase: Decimal);
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBreakBulkPlacingExistsOnAfterBinContent2SetFilters(var BinContent: Record "Bin Content")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcBinAvailQtyToPick(var QtyToPickBase: Decimal; var BinContent: Record "Bin Content"; var TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindToBinCodeForCustomWhseSource(CustomWhseSourceLine: Variant; var ToBinCode: Code[20]; WhseSource2: Option; CurrSourceType: Integer; CurrSourceSubType: Integer; CurrSourceNo: Code[20]; CurrSourceLineNo: Integer; CurrSourceSubLineNo: Integer);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTempActivityLineForCustomWhseSource(CustomWhseSourceLine: Variant; var TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary; var CreatePickParameters: Record "Create Pick Parameters")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCalcMaxQtyForCustomWhseSource(CustomWhseSourceLine: Variant; var TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary; var QtytoHandle: Decimal; var QtytoHandleBase: Decimal; BreakBulkNo: Integer; ShouldCalcMaxQty: Boolean; WhseSource2: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcAvailableQtyOnAfterCalcReservQtyOnPicksShips(var QtyReservedOnPickShip: Decimal; LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; var WarehouseActivityLine: Record "Warehouse Activity Line"; var LineReservedQty: Decimal)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnFindBreakBulkBinOnAfterFromItemUnitOfMeasureSetFilters(var ItemUnitOfMeasure: Record "Item Unit of Measure"; ItemNo: Code[20]; TotalQtytoPickBase: Decimal; CreatePickParameters: Record "Create Pick Parameters")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCreateBreakBulkTempLines(LocationCode: Code[10]; FromUOMCode: Code[10]; ToUOMCode: Code[10]; FromBinCode: Code[20]; ToBinCode: Code[20]; FromQtyPerUOM: Decimal; ToQtyPerUOM: Decimal; BreakbulkNo2: Integer; ToQtyToPick: Decimal; ToQtyToPickBase: Decimal; FromQtyToPick: Decimal; FromQtyToPickBase: Decimal; QtyRndPrec: Decimal; QtyRndPrecBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateQuantitiesToPick(QtyAvailableBase: Decimal; FromQtyPerUOM: Decimal; var FromQtyToPick: Decimal; var FromQtyToPickBase: Decimal; ToQtyPerUOM: Decimal; var ToQtyToPick: Decimal; var ToQtyToPickBase: Decimal; var TotalQtyToPick: Decimal; var TotalQtyToPickBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateWhseDocumentOnBeforeFindTempActivityLine(var TempWarehouseActivLine: Record "Warehouse Activity Line" temporary; WhseSource: Option "Pick Worksheet",Shipment,"Movement Worksheet","Internal Pick",Production,Assembly; var IsHandled: Boolean; IsMovementWorksheet: Boolean; var FirstWhseDocNo: Code[20]; var LastWhseDocNo: Code[20]; CreatePickParameters: Record "Create Pick Parameters"; CalledFromWksh: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateNewWhseDocOnAfterCheckCreateNewWhseActivHeader(var TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary; var CreateNewWhseActivHeader: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindBWPickBinOnBeforeUpdateQuantitiesToPick(var SkipUpdateQuantitiesToPick: Boolean; FromBinContent: Record "Bin Content"; QtyAvailableBase: Decimal; QtyPerUnitofMeasure: Decimal; var QtyToPick: Decimal; var QtyToPickBase: Decimal; var TotalQtyToPick: Decimal; var TotalQtyToPickBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTempItemTrkgLinesOnLoopEntrySummaryFEFOBeforeCheckExpirationDate(var EntrySummary: Record "Entry Summary"; SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTempLineOnAfterSetQtyAvailableBaseForDirectedPutAwayAndPick(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; UnitofMeasureCode: Code[10]; var QtyAvailableBase: Decimal; var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcTotalAvailQtyToPickForDirectedPutAwayPickOnBeforeCalcAvailabilityAfterReservationImpact(var TotalAvailQtyBase: Decimal; MaxPickableQtyExcludingShipBin: Decimal; MaxPickableQtyInWhse: Decimal; ReservedQtyOnInventory: Decimal; QtyReservedOnPickShip: Decimal; LineReservedQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProcessDoNotFillQtytoHandle(var WarehouseActivityLine: Record "Warehouse Activity Line"; var TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary; var CreatePickParameters: Record "Create Pick Parameters" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateWhseActivHeader(var CurrWarehouseActivityHeader: Record "Warehouse Activity Header"; LocationCode: Code[10]; var FirstWhseDocNo: Code[20]; var LastWhseDocNo: Code[20]; var NoOfSourceDoc: Integer; var NoOfLines: Integer; var WhseDocCreated: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePickAccordingToFEFO(LocationCode: Code[10]; WhseItemTrackingSetup: Record "Item Tracking Setup"; var PickAccordingToFEFO: Boolean; var isHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindSmallerUOMBinOnBeforeFindWhseActivLine(var TempWarehouseActivityLine2: Record "Warehouse Activity Line" temporary; Location: Record Location)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetAvailableQtyBase(var BinContent: Record "Bin Content")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcBinAvailQtyToBreakbulkOnOnAfterBinContentCalcFields(var BinContent: Record "Bin Content")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSaveTempItemTrkgLines(isHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetSource(SourceType2: Integer; SourceSubType2: Option; SourceNo2: Code[20]; SourceLineNo2: Integer; SourceSubLineNo2: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcAvailableQtyOnGetLineReservedQty(WhseSource2: Option; CurrSourceSubType: Integer; CurrSourceNo: Code[20]; CurrSourceLineNo: Integer; CurrSourceSubLineNo: Integer; var LineReservedQty: Decimal; var TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunFindBWPickBinLoopOnAfterCheckWhseHandling(CurrSourceType: Integer; CurrLocation: Record Location; var ShouldExit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetFiltersOnReservEntry(var ReservationEntry: Record "Reservation Entry"; SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer)
    begin
    end;
}
