// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Foundation.Calendar;
using Microsoft.Foundation.Shipping;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Transfer;
using Microsoft.Pricing.Calculation;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.Availability;
using Microsoft.Warehouse.Ledger;
using System.Reflection;

codeunit 99000854 "Inventory Profile Offsetting"
{
    Permissions = TableData "Reservation Entry" = id;

    trigger OnRun()
    begin
    end;

    var
        ReqLine: Record "Requisition Line";
        InventorySetup: Record "Inventory Setup";
        TempSKU: Record "Stockkeeping Unit" temporary;
        TempTransferSKU: Record "Stockkeeping Unit" temporary;
        ReservEntry: Record "Reservation Entry";
        TempTrkgReservEntry: Record "Reservation Entry" temporary;
        TempItemTrkgEntry: Record "Reservation Entry" temporary;
        ActionMsgEntry: Record "Action Message Entry";
        TempPlanningCompList: Record "Planning Component" temporary;
        DummyInventoryProfileTrackBuffer: Record "Inventory Profile Track Buffer";
        CustomizedCalendarChange: Record "Customized Calendar Change";
        CalendarManagement: Codeunit "Calendar Management";
        LeadTimeMgt: Codeunit "Lead-Time Management";
        PlanningLineManagement: Codeunit "Planning Line Management";
        PlanningTransparency: Codeunit "Planning Transparency";
        UOMMgt: Codeunit "Unit of Measure Management";
        BucketSize: DateFormula;
        ExcludeForecastBefore: Date;
        ScheduleDirection: Option Forward,Backward;
        PlanningLineStage: Option " ","Line Created","Routing Created",Exploded,Obsolete;
        SurplusType: Enum "Planning Surplus Type";
        CurrWorksheetType: Option Requisition,Planning;
        PriceCalculationMethod: Enum "Price Calculation Method";
        DampenerQty: Decimal;
        FutureSupplyWithinLeadtime: Decimal;
        LineNo: Integer;
        DampenersDays: Integer;
        BucketSizeInDays: Integer;
        CurrTemplateName: Code[10];
        CurrWorksheetName: Code[10];
        CurrForecast: Code[10];
        PlanMRP: Boolean;
        SpecificLotTracking: Boolean;
        SpecificSNTracking: Boolean;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'Assertion failed: %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        UseParm: Boolean;
        PlanningResiliency: Boolean;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text002: Label 'The %1 from ''%2'' to ''%3'' does not exist.';
        Text003: Label 'The %1 for %2 %3 %4 %5 does not exist.';
        Text004: Label '%1 must not be %2 in %3 %4 %5 %6 when %7 is %8.';
        Text005: Label '%1 must not be %2 in %3 %4 when %5 is %6.';
        Text006: Label '%1: The projected available inventory is %2 on the planning starting date %3.';
        Text007: Label '%1: The projected available inventory is below %2 %3 on %4.';
        Text008: Label '%1: The %2 %3 is before the work date %4.';
        Text009: Label '%1: The Status of %2 %3 is %4.';
        Text010: Label 'The projected inventory %1 is higher than the overflow level %2 on %3.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        LocationMandatoryTxt: Label 'Location is mandatory.';
        MissingStockkeepingUnitTxt: Label 'Missing stockkeeping unit.';
        MinimalSupplyPlannedTxt: Label '%1: %2 The item is planned to cover the exact demand.', Comment = '%1: Attention, %2: Reason';
        PlanToDate: Date;
        OverflowLevel: Decimal;
        ExceedROPqty: Decimal;
        NextStateTxt: Label 'StartOver,MatchDates,MatchQty,CreateSupply,ReduceSupply,CloseDemand,CloseSupply,CloseLoop';
        NextState: Option StartOver,MatchDates,MatchQty,CreateSupply,ReduceSupply,CloseDemand,CloseSupply,CloseLoop;
        LotAccumulationPeriodStartDate: Date;

#if not CLEAN27
    [Obsolete('Replaced by same procedure without parameter Manufacturing Setup', '27.0')]
    procedure CalculatePlanFromWorksheet(var Item: Record Item; ManufacturingSetup2: Record Microsoft.Manufacturing.Setup."Manufacturing Setup"; TemplateName: Code[10]; WorksheetName: Code[10]; OrderDate: Date; ToDate: Date; MRPPlanning: Boolean; RespectPlanningParm: Boolean)
    begin
        CalculatePlanFromWorksheet(Item, TemplateName, WorksheetName, OrderDate, ToDate, MRPPlanning, RespectPlanningParm);
    end;
#endif

    procedure CalculatePlanFromWorksheet(var Item: Record Item; TemplateName: Code[10]; WorksheetName: Code[10]; OrderDate: Date; ToDate: Date; MRPPlanning: Boolean; RespectPlanningParm: Boolean)
    var
        InventoryProfile: array[2] of Record "Inventory Profile" temporary;
#if not CLEAN27
        ManufacturingSetup: Record Microsoft.Manufacturing.Setup."Manufacturing Setup";
#endif
    begin
#if not CLEAN27
        ManufacturingSetup.GetRecordOnce();
        OnBeforeCalculatePlanFromWorksheet(
          Item, ManufacturingSetup, TemplateName, WorksheetName, OrderDate, ToDate, MRPPlanning, RespectPlanningParm);
#endif
        OnBeforeCalculatePlanFromWorksheet2(
          Item, TemplateName, WorksheetName, OrderDate, ToDate, MRPPlanning, RespectPlanningParm);

        PlanToDate := ToDate;
        InitVariables(InventoryProfile[1], Item, TemplateName, WorksheetName, MRPPlanning);
        DemandToInvtProfile(InventoryProfile[1], Item, ToDate);
        OrderDate := ForecastConsumption(InventoryProfile[1], Item, OrderDate, ToDate);
        OnCalculatePlanFromWorksheetOnAfterForecastConsumption(InventoryProfile[1], Item, OrderDate, ToDate, LineNo);
        BlanketOrderConsump(InventoryProfile[1], Item, ToDate);
        SupplytoInvProfile(InventoryProfile[1], Item, ToDate);
        OnCalculatePlanFromWorksheetOnBeforeUnfoldItemTracking(InventoryProfile[1], Item, ToDate, LineNo, TempTrkgReservEntry);
        UnfoldItemTracking(InventoryProfile[1], InventoryProfile[2]);
        FindCombination(InventoryProfile[1], InventoryProfile[2], Item);
        PlanItem(InventoryProfile[1], InventoryProfile[2], OrderDate, ToDate, RespectPlanningParm);
        OnCalculatePlanFromWorksheetOnAfterPlanItem(CurrTemplateName, CurrWorksheetName, Item, ReqLine, TempTrkgReservEntry);
        CommitTracking();

        OnAfterCalculatePlanFromWorksheet(Item);
    end;

    local procedure InitVariables(var InventoryProfile: Record "Inventory Profile"; Item: Record Item; TemplateName: Code[10]; WorksheetName: Code[10]; MRPPlanning: Boolean)
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        InventorySetup.GetRecordOnce();
        CurrTemplateName := TemplateName;
        CurrWorksheetName := WorksheetName;
        InventoryProfile.Reset();
        InventoryProfile.DeleteAll();
        TempSKU.Reset();
        TempSKU.DeleteAll();
        Clear(TempSKU);
        TempTransferSKU.Reset();
        TempTransferSKU.DeleteAll();
        Clear(TempTransferSKU);
        TempTrkgReservEntry.Reset();
        TempTrkgReservEntry.DeleteAll();
        TempItemTrkgEntry.Reset();
        TempItemTrkgEntry.DeleteAll();
        PlanMRP := MRPPlanning;
        if Item."Item Tracking Code" <> '' then begin
            ItemTrackingCode.Get(Item."Item Tracking Code");
            SpecificLotTracking := IsLotSpecificTracking(ItemTrackingCode);
            SpecificSNTracking := IsSNSpecificTracking(ItemTrackingCode);
        end else begin
            SpecificLotTracking := false;
            SpecificSNTracking := false;
        end;
        LineNo := 0; // Global variable
        PlanningTransparency.SetTemplAndWorksheet(CurrTemplateName, CurrWorksheetName);

        OnAfterInitVariables(InventoryProfile, Item);
    end;

    procedure CreateTempSKUForLocation(ItemNo: Code[20]; LocationCode: Code[10])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateTempSKUForLocation(TempSKU, LocationCode, IsHandled, ItemNo);
        if IsHandled then
            exit;

        TempSKU.Init();
        TempSKU."Item No." := ItemNo;
        TransferPlanningParameters(TempSKU);
        TempSKU."Location Code" := LocationCode;
        if TempSKU."Reordering Policy" <> TempSKU."Reordering Policy"::" " then
            TempSKU.Insert();
    end;

    local procedure DemandToInvtProfile(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; ToDate: Date)
    var
        CopyOfItem: Record Item;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDemandToInvProfile(InventoryProfile, Item, IsHandled);
        if IsHandled then
            exit;

        InventoryProfile.SetCurrentKey("Line No.");

        CopyOfItem.Copy(Item);
        Item.SetRange("Date Filter", 0D, ToDate);

        TransTransReqLineToProfile(InventoryProfile, Item, ToDate);
        TransShptTransLineToProfile(InventoryProfile, Item);

        OnAfterDemandToInvProfile(InventoryProfile, Item, TempItemTrkgEntry, LineNo, PlanMRP);

        Item.Copy(CopyOfItem);
    end;

    local procedure SupplytoInvProfile(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; ToDate: Date)
    var
        CopyOfItem: Record Item;
    begin
        InventoryProfile.Reset();
        InventoryProfile.SetCurrentKey("Line No.");

        CopyOfItem.Copy(Item);
        Item.SetRange("Date Filter");

        OnBeforeSupplyToInvProfile(InventoryProfile, Item, ToDate, TempItemTrkgEntry, LineNo);

        TransItemLedgEntryToProfile(InventoryProfile, Item);
        TransReqLineToProfile(InventoryProfile, Item, ToDate);
        TransRcptTransLineToProfile(InventoryProfile, Item, ToDate);

        OnAfterSupplyToInvProfile(InventoryProfile, Item, ToDate, TempItemTrkgEntry, LineNo, TempSKU, TempTransferSKU);

        Item.Copy(CopyOfItem);
    end;

#if not CLEAN25
    [Obsolete('Moved into scope of table Inventory Profile', '25.0')]
    procedure InsertSupplyInvtProfile(var InventoryProfile: Record "Inventory Profile"; ToDate: Date)
    begin
        InventoryProfile.InsertSupplyInvtProfile(ToDate);
    end;
#endif

    local procedure TransTransReqLineToProfile(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; ToDate: Date)
    var
        TransferReqLine: Record "Requisition Line";
    begin
        TransferReqLine.SetCurrentKey("Replenishment System", Type, "No.", "Variant Code", "Transfer-from Code", "Transfer Shipment Date");
        TransferReqLine.SetRange("Replenishment System", TransferReqLine."Replenishment System"::Transfer);
        TransferReqLine.SetRange(Type, TransferReqLine.Type::Item);
        TransferReqLine.SetRange("No.", Item."No.");
        Item.CopyFilter("Location Filter", TransferReqLine."Transfer-from Code");
        Item.CopyFilter("Variant Filter", TransferReqLine."Variant Code");
        TransferReqLine.SetFilter("Transfer Shipment Date", '>%1&<=%2', 0D, ToDate);
        if TransferReqLine.FindSet() then
            repeat
                InsertInventoryProfile(InventoryProfile, TransferReqLine, Item);
            until TransferReqLine.Next() = 0;
    end;

    local procedure TransShptTransLineToProfile(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item)
    var
        TransLine: Record "Transfer Line";
        FilterIsSetOnLocation: Boolean;
        ShouldProcess: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransShptTransLineToProfile(InventoryProfile, Item, LineNo, IsHandled, TransLine);
        if IsHandled then
            exit;

        FilterIsSetOnLocation := Item.GetFilter("Location Filter") <> '';
        if TransLine.FindLinesWithItemToPlan(Item, false, true) then
            repeat
                ShouldProcess := TransLine."Shipment Date" <> 0D;
                OnTransShptTransLineToProfileOnBeforeProcessLine(TransLine, ShouldProcess, Item);
                if ShouldProcess then begin
                    InventoryProfile.Init();
                    InventoryProfile."Line No." := GetNextLineNo();
                    InventoryProfile."Item No." := Item."No.";
                    OnTransShptTransLineToProfileOnBeforeTransferFromOutboundTransfer(Item, Transline);
                    InventoryProfile.TransferFromOutboundTransfer(TransLine, TempItemTrkgEntry);
                    OnTransShptTransLineToProfileOnAfterTransferFromOutboundTransfer(Item, Transline, InventoryProfile);
                    if InventoryProfile.IsSupply then
                        InventoryProfile.ChangeSign();
                    if FilterIsSetOnLocation then
                        InventoryProfile."Transfer Location Not Planned" := TransferLocationIsFilteredOut(Item, TransLine);
                    SyncTransferDemandWithReqLine(InventoryProfile, TransLine."Transfer-to Code");
                    InventoryProfile.Insert();
                    OnTransShptTransLineToProfileOnAfterInventoryProfileInsert(Item, Transline, InventoryProfile);
                end;
            until TransLine.Next() = 0;
    end;

    local procedure TransItemLedgEntryToProfile(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransItemLedgEntryToProfile(InventoryProfile, Item, ItemLedgEntry, IsHandled, LineNo);
        if IsHandled then
            exit;
        if ItemLedgEntry.FindLinesWithItemToPlan(Item, false) then
            repeat
                InventoryProfile.Init();
                InventoryProfile."Line No." := GetNextLineNo();
                OnTransItemLedgEntryToProfileOnBeforeTransferFromItemLedgerEntry(Item, ItemLedgEntry);
                InventoryProfile.TransferFromItemLedgerEntry(ItemLedgEntry, TempItemTrkgEntry);
                OnTransItemLedgEntryToProfileOnAfterTransferFromItemLedgerEntry(Item, ItemLedgEntry, InventoryProfile);
                InventoryProfile."Due Date" := 0D;
                if not InventoryProfile.IsSupply then
                    InventoryProfile.ChangeSign();
                InventoryProfile.Insert();
                OnTransItemLedgEntryToProfileOnAfterInsertInventoryProfile(Item, ItemLedgEntry, InventoryProfile);
            until ItemLedgEntry.Next() = 0;
    end;

    local procedure TransReqLineToProfile(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; ToDate: Date)
    var
        ReqLine: Record "Requisition Line";
        ReqLineReserve: Codeunit "Req. Line-Reserve";
    begin
        if ReqLine.FindLinesWithItemToPlan(Item) then
            repeat
                if ReqLine."Due Date" <> 0D then begin
                    InventoryProfile.Init();
                    InventoryProfile."Line No." := GetNextLineNo();
                    InventoryProfile."Item No." := Item."No.";
                    ReqLineReserve.TransferInventoryProfileFromRequisitionLine(InventoryProfile, ReqLine, TempItemTrkgEntry);
                    InventoryProfile.InsertSupplyInvtProfile(ToDate);
                end;
            until ReqLine.Next() = 0;
    end;

    local procedure TransRcptTransLineToProfile(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; ToDate: Date)
    var
        TransLine: Record "Transfer Line";
        WhseEntry: Record "Warehouse Entry";
        FilterIsSetOnLocation: Boolean;
        ShouldProcess: Boolean;
    begin
        OnBeforeTransRcptTransLineToProfile(InventoryProfile, Item, ToDate);
        FilterIsSetOnLocation := Item.GetFilter("Location Filter") <> '';
        if TransLine.FindLinesWithItemToPlan(Item, true, true) then
            repeat
                ShouldProcess := TransLine."Receipt Date" <> 0D;
                OnTransRcptTransLineToProfileOnBeforeProcessLine(TransLine, ShouldProcess, Item);
                if ShouldProcess then begin
                    InventoryProfile.Init();
                    InventoryProfile."Line No." := GetNextLineNo();
                    InventoryProfile.TransferFromInboundTransfer(TransLine, TempItemTrkgEntry);
                    if TransLine."Planning Flexibility" = TransLine."Planning Flexibility"::Unlimited then
                        if (InventoryProfile."Finished Quantity" > 0) or
                           (TransLine."Quantity Shipped" > 0) or (TransLine."Derived From Line No." > 0)
                        then
                            InventoryProfile."Planning Flexibility" := InventoryProfile."Planning Flexibility"::None
                        else begin
                            WhseEntry.SetSourceFilter(
                              Database::"Transfer Line", 0, InventoryProfile."Source ID", InventoryProfile."Source Ref. No.", true);
                            if not WhseEntry.IsEmpty() then
                                InventoryProfile."Planning Flexibility" := InventoryProfile."Planning Flexibility"::None;
                        end;
                    if FilterIsSetOnLocation then
                        InventoryProfile."Transfer Location Not Planned" := TransferLocationIsFilteredOut(Item, TransLine);
                    OnTransRcptTransLineToProfileOnBeforeInsertSupplyInvtProfile(InventoryProfile, TransLine);
                    InventoryProfile.InsertSupplyInvtProfile(ToDate);
                    InsertTempTransferSKU(TransLine);
                    OnTransRcptTransLineToProfileOnAfterInsertInventoryProfile(TransLine, InventoryProfile);
                end;
            until TransLine.Next() = 0;
    end;

    local procedure TransferLocationIsFilteredOut(var Item: Record Item; var TransLine: Record "Transfer Line"): Boolean
    var
        TempTransLine: Record "Transfer Line" temporary;
    begin
        TempTransLine := TransLine;
        TempTransLine.Insert();
        Item.CopyFilter("Location Filter", TempTransLine."Transfer-from Code");
        Item.CopyFilter("Location Filter", TempTransLine."Transfer-to Code");
        exit(TempTransLine.IsEmpty);
    end;

    procedure ForecastConsumption(var DemandInvtProfile: Record "Inventory Profile"; var Item: Record Item; OrderDate: Date; ToDate: Date) UpdatedOrderDate: Date
    var
        ForecastEntry: Record Microsoft.Manufacturing.Forecast."Production Forecast Entry";
        ForecastEntry2: Record Microsoft.Manufacturing.Forecast."Production Forecast Entry";
        NextForecast: Record Microsoft.Manufacturing.Forecast."Production Forecast Entry";
        ItemLedgEntry: Record "Item Ledger Entry";
        CustomCalendarChange: array[2] of Record "Customized Calendar Change";
        TotalForecastQty: Decimal;
        ReplenishmentLocation: Code[10];
        ForecastExist: Boolean;
        NextForecastExist: Boolean;
        ReplenishmentLocationFound: Boolean;
        ComponentForecast: Boolean;
        ComponentForecastFrom: Boolean;
        ByLocations: Boolean;
        ByVariants: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeForecastConsumption(
            DemandInvtProfile, Item, OrderDate, ToDate, UpdatedOrderDate, IsHandled,
            CurrForecast, ExcludeForecastBefore, UseParm, LineNo);
        if IsHandled then
            exit;

        UpdatedOrderDate := OrderDate;
        ComponentForecastFrom := false;
        InventorySetup.GetRecordOnce();
        ByLocations := InventorySetup."Use Forecast on Locations";
        ByVariants := InventorySetup."Use Forecast on Variants";

        if not ByLocations then begin
            ReplenishmentLocationFound := FindReplishmentLocation(ReplenishmentLocation, Item);
            if InventorySetup."Location Mandatory" and not ReplenishmentLocationFound then
                ComponentForecastFrom := true;
        end;

        case true of
            ByLocations and ByVariants:
                ForecastEntry.SetCurrentKey(
                  "Production Forecast Name", "Item No.", "Location Code", "Variant Code", "Forecast Date", "Component Forecast");
            ByLocations and not ByVariants:
                ForecastEntry.SetCurrentKey(
                  "Production Forecast Name", "Item No.", "Location Code", "Forecast Date", "Component Forecast", "Variant Code");
            not ByLocations and ByVariants:
                ForecastEntry.SetCurrentKey(
                  "Production Forecast Name", "Item No.", "Variant Code", "Forecast Date", "Component Forecast", "Location Code");
            not ByLocations and not ByVariants:
                ForecastEntry.SetCurrentKey(
                  "Production Forecast Name", "Item No.", "Component Forecast", "Forecast Date", "Location Code", "Variant Code");
        end;

        ItemLedgEntry.Reset();
        DemandInvtProfile.SetCurrentKey("Item No.", "Variant Code", "Location Code", "Due Date");

        NextForecast.Copy(ForecastEntry);

        InventorySetup.GetRecordOnce();

        if not UseParm then
            CurrForecast := InventorySetup."Current Demand Forecast";

        ForecastEntry.SetRange("Production Forecast Name", CurrForecast);
        ForecastEntry.SetRange("Forecast Date", ExcludeForecastBefore, ToDate);

        ForecastEntry.SetRange("Item No.", Item."No.");
        ForecastEntry2.Copy(ForecastEntry);
        Item.CopyFilter("Location Filter", ForecastEntry2."Location Code");

        for ComponentForecast := ComponentForecastFrom to true do begin
            if not InventorySetup."Use Forecast on Locations" then
                if ComponentForecast then begin
                    if not FindReplishmentLocation(ReplenishmentLocation, Item) then
                        ReplenishmentLocation := GetComponentsAtLocationCode();
                    if InventorySetup."Location Mandatory" and (ReplenishmentLocation = '') then
                        exit;
                end;
            ForecastEntry.SetRange("Component Forecast", ComponentForecast);
            ForecastEntry2.SetRange("Component Forecast", ComponentForecast);
            if ForecastEntry2.Find('-') then
                repeat
                    if ByLocations then begin
                        ForecastEntry2.SetRange("Location Code", ForecastEntry2."Location Code");
                        ItemLedgEntry.SetRange("Location Code", ForecastEntry2."Location Code");
                        DemandInvtProfile.SetRange("Location Code", ForecastEntry2."Location Code");
                    end else begin
                        Item.CopyFilter("Location Filter", ForecastEntry2."Location Code");
                        Item.CopyFilter("Location Filter", ItemLedgEntry."Location Code");
                        Item.CopyFilter("Location Filter", DemandInvtProfile."Location Code");
                    end;

                    if ByVariants then begin
                        ForecastEntry2.SetRange("Variant Code", ForecastEntry2."Variant Code");
                        ItemLedgEntry.SetRange("Variant Code", ForecastEntry2."Variant Code");
                        DemandInvtProfile.SetRange("Variant Code", ForecastEntry2."Variant Code");
                    end else begin
                        Item.CopyFilter("Variant Filter", ForecastEntry2."Variant Code");
                        Item.CopyFilter("Variant Filter", ItemLedgEntry."Variant Code");
                        Item.CopyFilter("Variant Filter", DemandInvtProfile."Variant Code");
                    end;

                    ForecastEntry2.Find('+');
                    ForecastEntry2.CopyFilter("Location Code", ForecastEntry."Location Code");
                    Item.CopyFilter("Location Filter", ForecastEntry2."Location Code");
                    ForecastEntry2.CopyFilter("Variant Code", ForecastEntry."Variant Code");
                    Item.CopyFilter("Variant Filter", ForecastEntry2."Variant Code");

                    ForecastExist := CheckForecastExist(ForecastEntry, OrderDate, ToDate);

                    if ForecastExist then
                        repeat
                            ForecastEntry.SetRange("Forecast Date", ForecastEntry."Forecast Date");
                            ForecastEntry.CalcSums("Forecast Quantity (Base)");
                            TotalForecastQty := ForecastEntry."Forecast Quantity (Base)";
                            ForecastEntry.Find('+');
                            NextForecast.CopyFilters(ForecastEntry);
                            NextForecast.SetRange("Forecast Date", ForecastEntry."Forecast Date" + 1, ToDate);
                            if not NextForecast.FindFirst() then
                                NextForecast."Forecast Date" := ToDate + 1
                            else
                                repeat
                                    NextForecast.SetRange("Forecast Date", NextForecast."Forecast Date");
                                    NextForecast.CalcSums("Forecast Quantity (Base)");
                                    if NextForecast."Forecast Quantity (Base)" = 0 then begin
                                        NextForecast.SetRange("Forecast Date", NextForecast."Forecast Date" + 1, ToDate);
                                        if not NextForecast.FindFirst() then
                                            NextForecast."Forecast Date" := ToDate + 1
                                    end else
                                        NextForecastExist := true
                                until (NextForecast."Forecast Date" = ToDate + 1) or NextForecastExist;
                            NextForecastExist := false;

                            ItemLedgEntry.SetRange("Item No.", Item."No.");
                            ItemLedgEntry.SetRange(Positive, false);
                            ItemLedgEntry.SetRange(Open);
                            ItemLedgEntry.SetRange(
                              "Posting Date", ForecastEntry."Forecast Date", NextForecast."Forecast Date" - 1);
                            Item.CopyFilter("Variant Filter", ItemLedgEntry."Variant Code");
                            if ComponentForecast then begin
                                ItemLedgEntry.SetRange("Entry Type", ItemLedgEntry."Entry Type"::Consumption);
                                ItemLedgEntry.CalcSums(Quantity);
                                TotalForecastQty += ItemLedgEntry.Quantity;
                            end else begin
                                ItemLedgEntry.SetRange("Entry Type", ItemLedgEntry."Entry Type"::Sale);
                                ItemLedgEntry.SetRange("Derived from Blanket Order", false);
                                ItemLedgEntry.CalcSums(Quantity);
                                TotalForecastQty += ItemLedgEntry.Quantity;
                                ItemLedgEntry.SetRange("Derived from Blanket Order");
                                // Undo shipment shall neutralize consumption from sales
                                ItemLedgEntry.SetRange(Positive, true);
                                ItemLedgEntry.SetRange(Correction, true);
                                ItemLedgEntry.CalcSums(Quantity);
                                TotalForecastQty += ItemLedgEntry.Quantity;
                                ItemLedgEntry.SetRange(Correction);
                            end;

                            DemandInvtProfile.SetRange("Item No.", ForecastEntry."Item No.");
                            DemandInvtProfile.SetRange(
                              "Due Date", ForecastEntry."Forecast Date", NextForecast."Forecast Date" - 1);
                            if ComponentForecast then begin
                                DemandInvtProfile.SetSourceTypeFilter(5407); // Database::"Prod. Order Component"
                                DemandInvtProfile.SetSourceTypeFilter(Database::"Planning Component");
                                OnForecastConsumptionOnAfterSetPlanningSourceTypeFilter(DemandInvtProfile);
                            end else begin
                                DemandInvtProfile.SetSourceTypeFilter(Database::"Sales Line");
                                OnForecastConsumptionOnAfterSetSalesSourceTypeFilter(DemandInvtProfile);
                            end;
                            OnForecastConsumptionOnBeforeFindDemandInvtProfile(DemandInvtProfile, ComponentForecast);
                            if DemandInvtProfile.Find('-') then
                                repeat
                                    if not (DemandInvtProfile.IsSupply or DemandInvtProfile."Derived from Blanket Order")
                                    then
                                        TotalForecastQty := TotalForecastQty - DemandInvtProfile."Remaining Quantity (Base)";
                                until (DemandInvtProfile.Next() = 0) or (TotalForecastQty < 0);
                            if TotalForecastQty > 0 then begin
                                ForecastInitDemand(DemandInvtProfile, ForecastEntry, Item."No.", ReplenishmentLocation, TotalForecastQty);
                                CustomCalendarChange[1].SetSource(CustomizedCalendarChange."Source Type"::Location, DemandInvtProfile."Location Code", '', '');
                                CustomCalendarChange[2].SetSource(CustomizedCalendarChange."Source Type"::Location, DemandInvtProfile."Location Code", '', '');
                                DemandInvtProfile."Due Date" := CalendarManagement.CalcDateBOC2('<0D>', ForecastEntry."Forecast Date", CustomCalendarChange, false);
                                OnForecastConsumptionOnAfterCalcDueDate(DemandInvtProfile, TotalForecastQty, ForecastEntry, NextForecast, Item, OrderDate, ToDate);
                                if DemandInvtProfile."Due Date" < UpdatedOrderDate then
                                    UpdatedOrderDate := DemandInvtProfile."Due Date";
                                DemandInvtProfile.Insert();
                            end;
                            ForecastEntry.SetRange("Forecast Date", ExcludeForecastBefore, ToDate);
                        until ForecastEntry.Next() = 0;
                until ForecastEntry2.Next() = 0;
        end;
    end;

    local procedure BlanketOrderConsump(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; ToDate: Date)
    var
        BlanketSalesLine: Record "Sales Line";
        SalesLineInvtProfile: Codeunit "Sales Line Invt. Profile";
        QtyReleased: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeBlanketOrderConsump(InventoryProfile, Item, ToDate, IsHandled);
        if IsHandled then
            exit;

        InventoryProfile.Reset();
        BlanketSalesLine.SetCurrentKey("Document Type", "Document No.", Type, "No.");
        BlanketSalesLine.SetRange("Document Type", BlanketSalesLine."Document Type"::"Blanket Order");
        BlanketSalesLine.SetRange(Type, BlanketSalesLine.Type::Item);
        BlanketSalesLine.SetRange("No.", Item."No.");
        Item.CopyFilter("Location Filter", BlanketSalesLine."Location Code");
        Item.CopyFilter("Variant Filter", BlanketSalesLine."Variant Code");
        BlanketSalesLine.SetFilter("Outstanding Qty. (Base)", '<>0');
        BlanketSalesLine.SetFilter("Shipment Date", '>%1&<=%2', 0D, ToDate);
        OnBeforeBlanketOrderConsumpFind(BlanketSalesLine);
        if BlanketSalesLine.Find('-') then
            repeat
                QtyReleased := CalcInventoryProfileRemainingQty(InventoryProfile, BlanketSalesLine."Document No.", BlanketSalesLine."Line No.");
                if BlanketSalesLine."Quantity (Base)" <> BlanketSalesLine."Qty. to Asm. to Order (Base)" then
                    if BlanketSalesLine."Outstanding Qty. (Base)" - BlanketSalesLine."Qty. to Asm. to Order (Base)" > QtyReleased then begin
                        InventoryProfile.Init();
                        InventoryProfile."Line No." := GetNextLineNo();
                        SalesLineInvtProfile.TransferInventoryProfileFromSalesLine(InventoryProfile, BlanketSalesLine, TempItemTrkgEntry);
                        InventoryProfile."Untracked Quantity" := BlanketSalesLine."Outstanding Qty. (Base)" - QtyReleased;
                        InventoryProfile."Remaining Quantity (Base)" := InventoryProfile."Untracked Quantity";
                        InventoryProfile.Insert();
                    end;
            until BlanketSalesLine.Next() = 0;
    end;

    procedure CheckForecastExist(var ForecastEntry: Record Microsoft.Manufacturing.Forecast."Production Forecast Entry"; OrderDate: Date; ToDate: Date): Boolean
    var
        ForecastExist: Boolean;
    begin
        ForecastEntry.SetRange("Forecast Date", ExcludeForecastBefore, OrderDate);
        if ForecastEntry.Find('+') then
            repeat
                ForecastEntry.SetRange("Forecast Date", ForecastEntry."Forecast Date");
                ForecastEntry.CalcSums("Forecast Quantity (Base)");
                if ForecastEntry."Forecast Quantity (Base)" <> 0 then
                    ForecastExist := true
                else
                    ForecastEntry.SetRange("Forecast Date", ExcludeForecastBefore, ForecastEntry."Forecast Date" - 1);
            until (not ForecastEntry.Find('+')) or ForecastExist;

        if not ForecastExist then begin
            if ExcludeForecastBefore > OrderDate then
                ForecastEntry.SetRange("Forecast Date", ExcludeForecastBefore, ToDate)
            else
                ForecastEntry.SetRange("Forecast Date", OrderDate + 1, ToDate);
            if ForecastEntry.Find('-') then
                repeat
                    ForecastEntry.SetRange("Forecast Date", ForecastEntry."Forecast Date");
                    ForecastEntry.CalcSums("Forecast Quantity (Base)");
                    if ForecastEntry."Forecast Quantity (Base)" <> 0 then
                        ForecastExist := true
                    else
                        ForecastEntry.SetRange("Forecast Date", ForecastEntry."Forecast Date" + 1, ToDate);
                until (not ForecastEntry.Find('-')) or ForecastExist
        end;

        OnAfterCheckForecastExist(ForecastEntry, ExcludeForecastBefore, OrderDate, ToDate, ForecastExist);
        exit(ForecastExist);
    end;

    procedure FindReplishmentLocation(var ReplenishmentLocation: Code[10]; var Item: Record Item): Boolean
    var
        SKU: Record "Stockkeeping Unit";
    begin
        ReplenishmentLocation := '';
        SKU.SetCurrentKey("Item No.", "Location Code", "Variant Code");
        SKU.SetRange("Item No.", Item."No.");
        Item.CopyFilter("Location Filter", SKU."Location Code");
        Item.CopyFilter("Variant Filter", SKU."Variant Code");
        SKU.SetRange("Replenishment System", Item."Replenishment System"::Purchase, Item."Replenishment System"::"Prod. Order");
        SKU.SetFilter("Reordering Policy", '<>%1', SKU."Reordering Policy"::" ");
        OnFindReplishmentLocationOnBeforeFindSKU(SKU);
        if SKU.Find('-') then
            if SKU.Next() = 0 then
                ReplenishmentLocation := SKU."Location Code";
        exit(ReplenishmentLocation <> '');
    end;

    local procedure FindCombination(var DemandInvtProfile: Record "Inventory Profile"; var SupplyInvtProfile: Record "Inventory Profile"; var Item: Record Item)
    var
        SKU: Record "Stockkeeping Unit";
        Location: Record Location;
        State: Option DemandExist,SupplyExist,BothExist;
        DemandBool: Boolean;
        SupplyBool: Boolean;
        TransitLocation: Boolean;
        IsHandled: Boolean;
    begin
        InventorySetup.GetRecordOnce();
        CreateTempSKUForComponentsLocation(Item);

        SKU.SetCurrentKey("Item No.", "Location Code", "Variant Code");
        SKU.SetRange("Item No.", Item."No.");
        Item.CopyFilter("Variant Filter", SKU."Variant Code");
        Item.CopyFilter("Location Filter", SKU."Location Code");

        OnFindCombinationOnBeforeSKUFindSet(SKU, Item);
        if SKU.FindSet() then
            FillSkUBuffer(SKU)
        else
            FillTempSKUForLocation(Item, SupplyInvtProfile);

        Clear(DemandInvtProfile);
        Clear(SupplyInvtProfile);
        OnFindCombinationOnBeforeFilterDemandAndSupply(DemandInvtProfile, SupplyInvtProfile);
        DemandInvtProfile.SetCurrentKey(
          "Item No.", "Variant Code", "Location Code", "Due Date", "Attribute Priority", "Order Priority");
        SupplyInvtProfile.SetCurrentKey(
          "Item No.", "Variant Code", "Location Code", "Due Date", "Attribute Priority", "Order Priority");
        DemandInvtProfile.SetRange(IsSupply, false);
        SupplyInvtProfile.SetRange(IsSupply, true);
        DemandBool := DemandInvtProfile.Find('-');
        SupplyBool := SupplyInvtProfile.Find('-');

        while DemandBool or SupplyBool do begin
            if DemandBool then begin
                TempSKU."Item No." := DemandInvtProfile."Item No.";
                TempSKU."Variant Code" := DemandInvtProfile."Variant Code";
                TempSKU."Location Code" := DemandInvtProfile."Location Code";
                OnFindCombinationAfterAssignTempSKU(TempSKU, DemandInvtProfile);
            end else begin
                TempSKU."Item No." := SupplyInvtProfile."Item No.";
                TempSKU."Variant Code" := SupplyInvtProfile."Variant Code";
                TempSKU."Location Code" := SupplyInvtProfile."Location Code";
                OnFindCombinationAfterAssignTempSKU(TempSKU, SupplyInvtProfile);
            end;

            IsHandled := false;
            OnFindCombinationOnBeforeSetState(TempSKU, Item, IsHandled);
            if IsHandled then
                exit;

            if DemandBool and SupplyBool then
                State := State::BothExist
            else
                if DemandBool then
                    State := State::DemandExist
                else
                    State := State::SupplyExist;

            case State of
                State::DemandExist:
                    DemandBool := FindNextSKU(DemandInvtProfile);
                State::SupplyExist:
                    SupplyBool := FindNextSKU(SupplyInvtProfile);
                State::BothExist:
                    if DemandInvtProfile."Variant Code" = SupplyInvtProfile."Variant Code" then begin
                        if DemandInvtProfile."Location Code" = SupplyInvtProfile."Location Code" then begin
                            DemandBool := FindNextSKU(DemandInvtProfile);
                            SupplyBool := FindNextSKU(SupplyInvtProfile);
                        end else
                            if DemandInvtProfile."Location Code" < SupplyInvtProfile."Location Code" then
                                DemandBool := FindNextSKU(DemandInvtProfile)
                            else
                                SupplyBool := FindNextSKU(SupplyInvtProfile)
                    end else
                        if DemandInvtProfile."Variant Code" < SupplyInvtProfile."Variant Code" then
                            DemandBool := FindNextSKU(DemandInvtProfile)
                        else
                            SupplyBool := FindNextSKU(SupplyInvtProfile);
            end;

            if TempSKU."Location Code" <> '' then begin
                Location.Get(TempSKU."Location Code"); // Assert: will fail if location cannot be found.
                TransitLocation := Location."Use As In-Transit";
            end else
                TransitLocation := false; // Variant SKU only - no location code involved.

            if not TransitLocation then begin
                TransferPlanningParameters(TempSKU);
                InsertTempSKU();
                while (TempSKU."Replenishment System" = TempSKU."Replenishment System"::Transfer) and
                      (TempSKU."Reordering Policy" <> TempSKU."Reordering Policy"::" ")
                do begin
                    TempSKU."Location Code" := TempSKU."Transfer-from Code";
                    TransferPlanningParameters(TempSKU);
                    if TempSKU."Reordering Policy" <> TempSKU."Reordering Policy"::" " then
                        InsertTempSKU();
                end;
            end;
        end;

        Item.CopyFilter("Location Filter", TempSKU."Location Code");
        Item.CopyFilter("Variant Filter", TempSKU."Variant Code");

        OnAfterFindCombination(DemandInvtProfile, SupplyInvtProfile);
    end;

    local procedure FillSKUBuffer(var SKU: Record "Stockkeeping Unit")
    var
        PlanningGetParameters: Codeunit "Planning-Get Parameters";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFillSkUBuffer(SKU, TempSKU, IsHandled);
        if IsHandled then
            exit;

        repeat
            PlanningGetParameters.AdjustInvalidSettings(SKU);
            if (SKU."Safety Stock Quantity" <> 0) or (SKU."Reorder Point" <> 0) or
               (SKU."Reorder Quantity" <> 0) or (SKU."Maximum Inventory" <> 0)
            then begin
                TempSKU.TransferFields(SKU);
                if TempSKU.Insert() then;
                while (TempSKU."Replenishment System" = TempSKU."Replenishment System"::Transfer) and
                      (TempSKU."Reordering Policy" <> TempSKU."Reordering Policy"::" ")
                do begin
                    TempSKU."Location Code" := TempSKU."Transfer-from Code";
                    TransferPlanningParameters(TempSKU);
                    if TempSKU."Reordering Policy" <> TempSKU."Reordering Policy"::" " then
                        InsertTempSKU();
                end;
            end;
        until SKU.Next() = 0;
    end;

    local procedure FillTempSKUForLocation(var Item: Record Item; SupplyInvtProfile: Record "Inventory Profile")
    begin
        OnFillTempSKUForLocation(Item, SupplyInvtProfile);
    end;

    local procedure InsertTempSKU()
    var
        SKU2: Record "Stockkeeping Unit";
        PlanningGetParameters: Codeunit "Planning-Get Parameters";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertTempSKU(TempSKU, IsHandled);
        if IsHandled then
            exit;

        if not TempSKU.Find('=') then begin
            PlanningGetParameters.SetLotForLot();
            PlanningGetParameters.AtSKU(SKU2, TempSKU."Item No.", TempSKU."Variant Code", TempSKU."Location Code");
            TempSKU := SKU2;
            if TempSKU."Reordering Policy" <> TempSKU."Reordering Policy"::" " then begin
                OnBeforeTempSKUInsert(TempSKU, PlanningGetParameters);
                TempSKU.Insert();
            end;
        end;
    end;

    local procedure FindNextSKU(var InventoryProfile: Record "Inventory Profile"): Boolean
    begin
        TempSKU."Variant Code" := InventoryProfile."Variant Code";
        TempSKU."Location Code" := InventoryProfile."Location Code";
        OnFindNextSKUOnAfterAssignTempSKU(TempSKU, InventoryProfile);

        InventoryProfile.SetRange("Variant Code", TempSKU."Variant Code");
        InventoryProfile.SetRange("Location Code", TempSKU."Location Code");
        InventoryProfile.FindLast();
        InventoryProfile.SetRange("Variant Code");
        InventoryProfile.SetRange("Location Code");
        exit(InventoryProfile.Next() <> 0);
    end;

    local procedure TransferPlanningParameters(var SKU: Record "Stockkeeping Unit")
    var
        SKU2: Record "Stockkeeping Unit";
        PlanningGetParameters: Codeunit "Planning-Get Parameters";
    begin
        PlanningGetParameters.AtSKU(SKU2, SKU."Item No.", SKU."Variant Code", SKU."Location Code");
        SKU := SKU2;

        OnAfterTransferPlanningParameters(SKU);
    end;

    local procedure DeleteTracking(var SKU: Record "Stockkeeping Unit"; ToDate: Date; var SupplyInventoryProfile: Record "Inventory Profile")
    var
        Item: Record Item;
        ReservEntry1: Record "Reservation Entry";
        ResEntryWasDeleted: Boolean;
    begin
        ActionMsgEntry.SetCurrentKey("Reservation Entry");

        ReservEntry.Reset();
        ReservEntry.SetCurrentKey("Item No.", "Variant Code", "Location Code");
        ReservEntry.SetRange("Item No.", SKU."Item No.");
        ReservEntry.SetRange("Variant Code", SKU."Variant Code");
        ReservEntry.SetRange("Location Code", SKU."Location Code");
        ReservEntry.SetFilter(ReservEntry."Reservation Status", '<>%1', ReservEntry."Reservation Status"::Prospect);
        if ReservEntry.Find('-') then
            repeat
                Item.SetLoadFields("Manufacturing Policy", "Replenishment System", "Reordering Policy", "Order Tracking Policy");
                Item.Get(ReservEntry."Item No.");
                if not IsTrkgForSpecialOrderOrDropShpt(ReservEntry) then begin
                    if ShouldDeleteReservEntry(ReservEntry, ToDate) then begin
                        ResEntryWasDeleted := true;
                        if ((ReservEntry."Source Type" = Database::"Item Ledger Entry") or CheckReorderingPolicyAndOrderTrackingPolicy(Item)) and
                           (ReservEntry."Reservation Status" = ReservEntry."Reservation Status"::Tracking)
                        then
                            if ReservEntry1.Get(ReservEntry."Entry No.", not ReservEntry.Positive) then
                                ReservEntry1.Delete();
                        ReservEntry.Delete();
                    end else
                        ResEntryWasDeleted := CloseTracking(ReservEntry, SupplyInventoryProfile, ToDate);

                    if ResEntryWasDeleted then begin
                        ActionMsgEntry.SetRange("Reservation Entry", ReservEntry."Entry No.");
                        ActionMsgEntry.DeleteAll();
                    end;
                end;
            until ReservEntry.Next() = 0;
    end;

    local procedure ShouldDeleteReservEntry(ReservEntry: Record "Reservation Entry"; ToDate: Date): Boolean
    var
        Item: Record Item;
        IsReservedForProdComponent: Boolean;
        DeleteCondition: Boolean;
    begin
        IsReservedForProdComponent := ReservedForProdComponent(ReservEntry);
        if IsReservedForProdComponent and not ReservEntry.IsReservationOrTracking() then
            if IsProdOrderPlanned(ReservEntry) then
                exit(false);

        Item.SetLoadFields("Manufacturing Policy", "Replenishment System");
        Item.Get(ReservEntry."Item No.");
        DeleteCondition :=
            ((ReservEntry."Reservation Status" <> ReservEntry."Reservation Status"::Reservation) and
            (ReservEntry."Expected Receipt Date" <= ToDate) and
            (ReservEntry."Shipment Date" <= ToDate)) or
            ((ReservEntry.Binding = ReservEntry.Binding::"Order-to-Order") and (ReservEntry."Shipment Date" <= ToDate) and
            (Item."Manufacturing Policy" = Item."Manufacturing Policy"::"Make-to-Stock") and Item.IsMfgItem() and
            (not IsReservedForProdComponent));

        OnAfterShouldDeleteReservEntry(ReservEntry, ToDate, DeleteCondition, CurrTemplateName, CurrWorksheetName);
        exit(DeleteCondition);
    end;

    local procedure IsProdOrderPlanned(var ReservEntry: Record "Reservation Entry") Planned: Boolean
    begin
        OnIsProdOrderPlanned(ReservEntry, Planned);
    end;

    local procedure RemoveOrdinaryInventory(var Supply: Record "Inventory Profile")
    var
        Supply2: Record "Inventory Profile";
    begin
        Supply2.Copy(Supply);
        Supply.SetRange(IsSupply);
        Supply.SetRange("Source Type", Database::"Item Ledger Entry");
        Supply.SetFilter(Binding, '<>%1', Supply2.Binding::"Order-to-Order");
        Supply.DeleteAll();
        Supply.Copy(Supply2);
    end;

    local procedure UnfoldItemTracking(var ParentInvProfile: Record "Inventory Profile"; var ChildInvProfile: Record "Inventory Profile")
    begin
        OnBeforeUnfoldItemTracking(ParentInvProfile, ChildInvProfile, TempItemTrkgEntry);

        ParentInvProfile.Reset();
        TempItemTrkgEntry.Reset();
        if not TempItemTrkgEntry.Find('-') then
            exit;
        ParentInvProfile.SetFilter("Source Type", '<>%1', Database::"Item Ledger Entry");
        ParentInvProfile.SetRange("Tracking Reference", 0);
        if ParentInvProfile.Find('-') then
            repeat
                TempItemTrkgEntry.Reset();
                TempItemTrkgEntry.SetSourceFilter(
                  ParentInvProfile."Source Type", ParentInvProfile."Source Order Status", ParentInvProfile."Source ID",
                  ParentInvProfile."Source Ref. No.", false);
                TempItemTrkgEntry.SetSourceFilter(ParentInvProfile."Source Batch Name", ParentInvProfile."Source Prod. Order Line");
                if TempItemTrkgEntry.Find('-') then begin
                    if ParentInvProfile.IsSupply and
                       (ParentInvProfile.Binding <> ParentInvProfile.Binding::"Order-to-Order")
                    then
                        ParentInvProfile."Planning Flexibility" := ParentInvProfile."Planning Flexibility"::None;
                    repeat
                        ChildInvProfile := ParentInvProfile;
                        ChildInvProfile."Line No." := GetNextLineNo();
                        ChildInvProfile."Tracking Reference" := ParentInvProfile."Line No.";
                        ChildInvProfile.CopyTrackingFromReservEntry(TempItemTrkgEntry);
                        ChildInvProfile."Expiration Date" := TempItemTrkgEntry."Expiration Date";
                        ChildInvProfile.TransferQtyFromItemTrgkEntry(TempItemTrkgEntry);
                        OnAfterTransToChildInvProfile(TempItemTrkgEntry, ChildInvProfile);
                        ChildInvProfile.Insert();
                        ParentInvProfile.ReduceQtyByItemTracking(ChildInvProfile);
                        ParentInvProfile.Modify();
                    until TempItemTrkgEntry.Next() = 0;
                end;
            until ParentInvProfile.Next() = 0;

        OnAfterUnfoldItemTracking(ParentInvProfile, ChildInvProfile);
    end;

    local procedure MatchAttributes(var SupplyInvtProfile: Record "Inventory Profile"; var DemandInvtProfile: Record "Inventory Profile"; RespectPlanningParm: Boolean; DemandForAdditionalProfile: Boolean)
    var
        xDemandInvtProfile: Record "Inventory Profile";
        xSupplyInvtProfile: Record "Inventory Profile";
        SupplyIleInvtProfile: Record "Inventory Profile";
        NewSupplyDate: Date;
        SupplyExists: Boolean;
        CanBeRescheduled: Boolean;
        ItemInventoryExists: Boolean;
        SkipMatchingAttributes: Boolean;
    begin
        SkipMatchingAttributes := false;
        OnBeforeMatchAttributes(SupplyInvtProfile, DemandInvtProfile, SkipMatchingAttributes);
        if SkipMatchingAttributes then
            exit;

        xDemandInvtProfile.CopyFilters(DemandInvtProfile);
        xSupplyInvtProfile.CopyFilters(SupplyInvtProfile);
        ItemInventoryExists := CheckItemInventoryExists(SupplyInvtProfile);
        DemandInvtProfile.SetRange("Attribute Priority", 1, 7);
        DemandInvtProfile.SetFilter("Source Type", '<>%1', Database::"Requisition Line");
        if DemandInvtProfile.FindSet(true) then
            repeat
                SupplyInvtProfile.SetRange(Binding, DemandInvtProfile.Binding);
                SupplyInvtProfile.SetRange("Primary Order Status", DemandInvtProfile."Primary Order Status");
                SupplyInvtProfile.SetRange("Primary Order No.", DemandInvtProfile."Primary Order No.");
                SupplyInvtProfile.SetRange("Primary Order Line", DemandInvtProfile."Primary Order Line");
                SupplyInvtProfile.SetRange("Source Prod. Order Line");
                if ((DemandInvtProfile."Ref. Order Type" = DemandInvtProfile."Ref. Order Type"::Assembly) or
                    ((DemandInvtProfile."Ref. Order Type" = DemandInvtProfile."Ref. Order Type"::"Prod. Order") and
                     (DemandInvtProfile."Source Type" = Database::"Planning Component"))) and
                   (DemandInvtProfile.Binding = DemandInvtProfile.Binding::"Order-to-Order") and
                   (DemandInvtProfile."Primary Order No." = '')
                then
                    SupplyInvtProfile.SetRange("Source Prod. Order Line", DemandInvtProfile."Source Prod. Order Line");

                SupplyInvtProfile.SetTrackingFilter(DemandInvtProfile);
                SupplyExists := SupplyInvtProfile.FindFirst();
                SupplyIleInvtProfile.Copy(SupplyInvtProfile);
                OnBeforeMatchAttributesDemandApplicationLoop(SupplyInvtProfile, DemandInvtProfile, SupplyExists);
                while (DemandInvtProfile."Untracked Quantity" > 0) and
                      (not ApplyUntrackedQuantityToItemInventory(SupplyExists, ItemInventoryExists, DemandForAdditionalProfile))
                do begin
                    OnStartOfMatchAttributesDemandApplicationLoop(SupplyInvtProfile, DemandInvtProfile, SupplyExists);
                    if SupplyExists and (DemandInvtProfile.Binding = DemandInvtProfile.Binding::"Order-to-Order") then begin
                        NewSupplyDate := SupplyInvtProfile."Due Date";
                        CanBeRescheduled :=
                          (SupplyInvtProfile."Fixed Date" = 0D) and
                          ((SupplyInvtProfile."Due Date" <> DemandInvtProfile."Due Date") or
                           (SupplyInvtProfile."Due Time" <> DemandInvtProfile."Due Time"));
                        if CanBeRescheduled then
                            if (SupplyInvtProfile."Due Date" > DemandInvtProfile."Due Date") or
                               (SupplyInvtProfile."Due Time" > DemandInvtProfile."Due Time")
                            then
                                CanBeRescheduled := CheckScheduleIn(SupplyInvtProfile, DemandInvtProfile."Due Date", NewSupplyDate, false)
                            else
                                CanBeRescheduled := CheckScheduleOut(SupplyInvtProfile, DemandInvtProfile."Due Date", NewSupplyDate, false);
                        if CanBeRescheduled and
                           ((NewSupplyDate <> SupplyInvtProfile."Due Date") or (SupplyInvtProfile."Planning Level Code" > 0))
                        then begin
                            Reschedule(SupplyInvtProfile, DemandInvtProfile."Due Date", DemandInvtProfile."Due Time");
                            SupplyInvtProfile."Fixed Date" := SupplyInvtProfile."Due Date";
                        end;
                    end;
                    if not SupplyExists or (SupplyInvtProfile."Due Date" > DemandInvtProfile."Due Date") then begin
                        InitSupply(
                          SupplyInvtProfile, DemandInvtProfile."Untracked Quantity", DemandInvtProfile."Due Date", DemandInvtProfile."Due Time");
                        OnMatchAttributesOnAfterInitSupply(SupplyInvtProfile, DemandInvtProfile);
                        TransferAttributes(SupplyInvtProfile, DemandInvtProfile);
                        SupplyInvtProfile."Fixed Date" := SupplyInvtProfile."Due Date";
                        SupplyInvtProfile.Insert();
                        SupplyExists := true;
                    end;

                    if DemandInvtProfile.Binding = DemandInvtProfile.Binding::"Order-to-Order" then
                        if (DemandInvtProfile."Untracked Quantity" > SupplyInvtProfile."Untracked Quantity") and
                           (SupplyInvtProfile."Due Date" <= DemandInvtProfile."Due Date")
                        then
                            IncreaseQtyToMeetDemand(SupplyInvtProfile, DemandInvtProfile, false, RespectPlanningParm, false);
                    if (TempSKU."Reordering Policy" = TempSKU."Reordering Policy"::"Maximum Qty.") and DemandForAdditionalProfile then
                        DecreaseQtyForMaxQty(SupplyInvtProfile, SupplyIleInvtProfile."Untracked Quantity");
                    if SupplyInvtProfile."Untracked Quantity" < DemandInvtProfile."Untracked Quantity" then
                        SupplyExists := CloseSupply(DemandInvtProfile, SupplyInvtProfile)
                    else
                        CloseDemand(DemandInvtProfile, SupplyInvtProfile);
                    OnEndMatchAttributesDemandApplicationLoop(SupplyInvtProfile, DemandInvtProfile, SupplyExists);
                end;
            until DemandInvtProfile.Next() = 0;

        // Neutralize or generalize excess Order-To-Order Supply
        SupplyInvtProfile.CopyFilters(xSupplyInvtProfile);
        SupplyInvtProfile.SetRange(Binding, SupplyInvtProfile.Binding::"Order-to-Order");
        SupplyInvtProfile.SetFilter("Untracked Quantity", '>=0');
        if SupplyInvtProfile.FindSet() then
            repeat
                if SupplyInvtProfile."Untracked Quantity" > 0 then begin
                    if DecreaseQty(SupplyInvtProfile, SupplyInvtProfile."Untracked Quantity", false) then begin
                        // Assertion: New specific Supply shall match the Demand exactly and must not update
                        // the Planning Line again since that will double the derived demand in case of transfers
                        if SupplyInvtProfile."Action Message" = SupplyInvtProfile."Action Message"::New then
                            SupplyInvtProfile.FieldError("Action Message");
                        MaintainPlanningLine(SupplyInvtProfile, DemandInvtProfile, PlanningLineStage::Exploded, ScheduleDirection::Backward)
                    end else
                        // Evaluate excess supply
                        if TempSKU."Include Inventory" then begin
                            // Release the remaining Untracked Quantity
                            SupplyInvtProfile.Binding := SupplyInvtProfile.Binding::" ";
                            SupplyInvtProfile."Primary Order Type" := 0;
                            SupplyInvtProfile."Primary Order Status" := 0;
                            SupplyInvtProfile."Primary Order No." := '';
                            SupplyInvtProfile."Primary Order Line" := 0;
                            SetAttributePriority(SupplyInvtProfile);
                        end else
                            SupplyInvtProfile."Untracked Quantity" := 0;

                    // Ensure that the directly allocated quantity will not be part of Projected Inventory
                    if SupplyInvtProfile."Untracked Quantity" <> 0 then begin
                        UpdateQty(SupplyInvtProfile, SupplyInvtProfile."Untracked Quantity");
                        SupplyInvtProfile.Modify();
                    end;
                end;
                if SupplyInvtProfile."Untracked Quantity" = 0 then
                    SupplyInvtProfile.Delete();
            until SupplyInvtProfile.Next() = 0;

        DemandInvtProfile.CopyFilters(xDemandInvtProfile);
        SupplyInvtProfile.CopyFilters(xSupplyInvtProfile);

        OnAfterMatchAttributes(SupplyInvtProfile, DemandInvtProfile, TempTrkgReservEntry);
    end;

    local procedure DecreaseQtyForMaxQty(var SupplyInvtProfile: Record "Inventory Profile"; ReduceQty: Decimal)
    begin
        if ReduceQty > 0 then begin
            SupplyInvtProfile."Remaining Quantity (Base)" -= ReduceQty;
            SupplyInvtProfile."Quantity (Base)" -= ReduceQty;
            SupplyInvtProfile.Modify();
        end;
    end;

    local procedure MatchReservationEntries(var FromTrkgReservEntry: Record "Reservation Entry"; var ToTrkgReservEntry: Record "Reservation Entry")
    begin
        if (FromTrkgReservEntry."Reservation Status" = FromTrkgReservEntry."Reservation Status"::Reservation) xor
           (ToTrkgReservEntry."Reservation Status" = ToTrkgReservEntry."Reservation Status"::Reservation)
        then begin
            SwitchTrackingToReservationStatus(FromTrkgReservEntry);
            SwitchTrackingToReservationStatus(ToTrkgReservEntry);
        end;
    end;

    local procedure SwitchTrackingToReservationStatus(var ReservEntry: Record "Reservation Entry")
    begin
        if ReservEntry."Reservation Status" = ReservEntry."Reservation Status"::Tracking then
            ReservEntry."Reservation Status" := ReservEntry."Reservation Status"::Reservation;
    end;

    local procedure PlanItem(var DemandInvtProfile: Record "Inventory Profile"; var SupplyInvtProfile: Record "Inventory Profile"; PlanningStartDate: Date; ToDate: Date; RespectPlanningParm: Boolean)
    var
        TempReminderInvtProfile: Record "Inventory Profile" temporary;
        PlanningGetParameters: Codeunit "Planning-Get Parameters";
        LatestBucketStartDate: Date;
        LastProjectedInventory: Decimal;
        LastAvailableInventory: Decimal;
        SupplyWithinLeadtime: Decimal;
        DemandExists: Boolean;
        SupplyExists: Boolean;
        PlanThisSKU: Boolean;
        ROPHasBeenCrossed: Boolean;
        NewSupplyHasTakenOver: Boolean;
        WeAreSureThatDatesMatch: Boolean;
        IsReorderPointPlanning: Boolean;
        NeedOfPublishSurplus: Boolean;
        IsHandled: Boolean;
        DemandForAdditionalProfile: Boolean;
        ProcessSupplyBeforeStartDate: Boolean;
        DoUpdatePriorities, DoInsertInsertSupplyForEmergencyOrder, DoCheckSupplyWithinLeadtime : Boolean;
    begin
        ReqLine.Reset();
        ReqLine.SetRange("Worksheet Template Name", CurrTemplateName);
        ReqLine.SetRange("Journal Batch Name", CurrWorksheetName);
        ReqLine.LockTable();
        if ReqLine.FindLast() then;

        if PlanningResiliency then
            ReqLine.SetResiliencyOn(CurrTemplateName, CurrWorksheetName, TempSKU."Item No.");

        PlanItemSetInvtProfileFilters(DemandInvtProfile, SupplyInvtProfile);

        TempReminderInvtProfile.SetCurrentKey("Item No.", "Variant Code", "Location Code", "Due Date");

        ExceedROPqty := 0.000000001;

        UpdateTempSKUTransferLevels();

        TempSKU.SetCurrentKey("Item No.", "Transfer-Level Code");
        OnPlanItemOnBeforeTempSKUFind(TempSKU, PlanningStartDate);
        if TempSKU.Find('-') then
            repeat
                IsReorderPointPlanning := IsSKUSetUpForReorderPointPlanning(TempSKU);
                OnPlanItemAfterCalcIsReorderPointPlanning(TempSKU, IsReorderPointPlanning, ReqLine, PlanningTransparency, PlanningResiliency, CurrTemplateName, CurrWorksheetName, PlanningStartDate);

                BucketSize := TempSKU."Time Bucket";
                // Minimum bucket size is 1 day:
                if CalcDate(BucketSize) <= Today then
                    Evaluate(BucketSize, '<1D>');
                BucketSizeInDays := CalcDate(BucketSize) - Today;

                FilterDemandSupplyRelatedToSKU(DemandInvtProfile);
                FilterDemandSupplyRelatedToSKU(SupplyInvtProfile);

                DampenersDays := PlanningGetParameters.CalcDampenerDays(TempSKU);
                DampenerQty := PlanningGetParameters.CalcDampenerQty(TempSKU);
                OverflowLevel := PlanningGetParameters.CalcOverflowLevel(TempSKU);

                if not TempSKU."Include Inventory" then
                    RemoveOrdinaryInventory(SupplyInvtProfile);

                DoUpdatePriorities := true;
                OnPlanItemOnBeforeInsertSafetyStockDemands(DemandInvtProfile, TempSKU, DoUpdatePriorities);
                InsertSafetyStockDemands(DemandInvtProfile, PlanningStartDate);
                if DoUpdatePriorities then
                    UpdatePriorities(SupplyInvtProfile, IsReorderPointPlanning, ToDate);

                DemandExists := DemandInvtProfile.FindSet();
                DemandForAdditionalProfile := DemandForAdditionalLine(DemandInvtProfile, SupplyInvtProfile);
                SupplyExists := SupplyInvtProfile.FindSet();
                LatestBucketStartDate := PlanningStartDate;
                OnPlanItemOnAfterInitLatestBucketStartDate(LatestBucketStartDate);
                LastProjectedInventory := 0;
                LastAvailableInventory := 0;
                PlanThisSKU := CheckPlanSKU(TempSKU, DemandExists, SupplyExists, IsReorderPointPlanning);

                if PlanThisSKU then begin
                    PrepareDemand(DemandInvtProfile, IsReorderPointPlanning, ToDate);
                    PlanThisSKU :=
                      not (DemandMatchedSupply(DemandInvtProfile, SupplyInvtProfile, TempSKU) and
                           DemandMatchedSupply(SupplyInvtProfile, DemandInvtProfile, TempSKU));
                    OnPlanItemOnAfterCheckDemandMatchedSupplyPlanThisSKU(DemandInvtProfile, SupplyInvtProfile, PlanThisSKU);
                end;
                if PlanThisSKU then begin
                    // Preliminary clean of tracking
                    if DemandExists or SupplyExists then
                        DeleteTracking(TempSKU, ToDate, SupplyInvtProfile);

                    MatchAttributes(SupplyInvtProfile, DemandInvtProfile, RespectPlanningParm, DemandForAdditionalProfile);

                    // Calculate initial inventory
                    PlanItemCalcInitialInventory(
                      DemandInvtProfile, SupplyInvtProfile, PlanningStartDate, DemandExists, SupplyExists, LastProjectedInventory);

                    OnBeforePrePlanDateDemandProc(SupplyInvtProfile, DemandInvtProfile, SupplyExists, DemandExists);
                    while DemandExists do begin
                        IsHandled := false;
                        OnPlanItemOnBeforeSumDemandInvtProfile(DemandInvtProfile, IsHandled, PlanningStartDate, LastProjectedInventory, LastAvailableInventory);
                        if not IsHandled then begin
                            LastProjectedInventory -= DemandInvtProfile."Remaining Quantity (Base)";
                            LastAvailableInventory -= DemandInvtProfile."Untracked Quantity";
                        end;
                        DemandInvtProfile.Modify();
                        DemandExists := DemandInvtProfile.Next() <> 0;
                    end;

                    OnBeforePrePlanDateSupplyProc(SupplyInvtProfile, DemandInvtProfile, SupplyExists, DemandExists);
                    while SupplyExists do begin
                        IsHandled := false;
                        OnPlanItemOnBeforeSumSupplyInvtProfile(SupplyInvtProfile, IsHandled, LastProjectedInventory, LastAvailableInventory);
                        if not IsHandled then begin
                            LastProjectedInventory += SupplyInvtProfile."Remaining Quantity (Base)";
                            LastAvailableInventory += SupplyInvtProfile."Untracked Quantity";
                        end;
                        SupplyInvtProfile."Planning Flexibility" := SupplyInvtProfile."Planning Flexibility"::None;
                        OnPlanItemOnBeforeSupplyInvtProfileModify(SupplyInvtProfile);
                        SupplyInvtProfile.Modify();
                        SupplyExists := SupplyInvtProfile.Next() <> 0;
                    end;
                    DoInsertInsertSupplyForEmergencyOrder := LastAvailableInventory < 0;
                    OnAfterPrePlanDateSupplyProc(SupplyInvtProfile, DemandInvtProfile, SupplyExists, DemandExists, TempSKU, TempTrkgReservEntry, ReqLine, DoInsertInsertSupplyForEmergencyOrder);

                    // Insert supply for emergency order
                    if DoInsertInsertSupplyForEmergencyOrder then
                        InsertEmergencyOrderSupply(SupplyInvtProfile, DemandInvtProfile, LastAvailableInventory, LastProjectedInventory, PlanningStartDate);

                    if not DemandInvtProfile.IsEmpty() then
                        DemandInvtProfile.ModifyAll("Untracked Quantity", 0);

                    // Initial Safety Stock Warning
                    if LastAvailableInventory < TempSKU."Safety Stock Quantity" then
                        InsertInitialSafetyStockWarningSupply(SupplyInvtProfile, LastAvailableInventory, LastProjectedInventory, PlanningStartDate, RespectPlanningParm, IsReorderPointPlanning);

                    DoCheckSupplyWithinLeadtime := IsReorderPointPlanning;
                    OnPlanItemOnBeforeCheckSupplyWithinLeadtime(SupplyInvtProfile, DemandInvtProfile, SupplyExists, DemandExists, TempSKU, TempTrkgReservEntry, ReqLine, DoCheckSupplyWithinLeadtime);

                    if DoCheckSupplyWithinLeadtime then begin
                        SupplyWithinLeadtime :=
                          SumUpProjectedSupply(SupplyInvtProfile, PlanningStartDate, PlanningStartDate + BucketSizeInDays - 1);

                        if LastProjectedInventory + SupplyWithinLeadtime <= TempSKU."Reorder Point" then begin
                            IsHandled := false;
                            OnPlanItemOnBeforeInitSupply(LastProjectedInventory, SupplyWithinLeadtime, TempSKU, IsHandled, PlanningStartDate);
                            if not IsHandled then begin
                                if (TempSKU."Reordering Policy" = TempSKU."Reordering Policy"::"Maximum Qty.") and DemandForAdditionalProfile then
                                    LastProjectedInventory := 0;
                                InitSupply(SupplyInvtProfile, 0, 0D, 0T);

                                IsHandled := false;
                                OnPlanItemOnBeforeCreateSupplyForward(TempSKU, SupplyInvtProfile, DemandInvtProfile, TempReminderInvtProfile, PlanningStartDate, LastAvailableInventory, LastProjectedInventory, NewSupplyHasTakenOver, IsHandled);
                                if not IsHandled then
                                    CreateSupplyForward(
                                    SupplyInvtProfile, DemandInvtProfile, TempReminderInvtProfile,
                                    PlanningStartDate, LastProjectedInventory, NewSupplyHasTakenOver, DemandInvtProfile."Due Date");

                                NeedOfPublishSurplus := SupplyInvtProfile."Due Date" > ToDate;
                                OnPlanItemOnAfterCreateInitialReorderPointSupply(PlanningStartDate);
                            end;
                        end;
                    end;

                    // Common balancing
                    OnBeforeCommonBalancing(TempSKU, DemandInvtProfile, SupplyInvtProfile, PlanningStartDate, ToDate, NewSupplyHasTakenOver, NeedOfPublishSurplus, FutureSupplyWithinLeadtime, OverflowLevel);
                    DemandInvtProfile.SetRange("Due Date", PlanningStartDate, ToDate);

                    DemandExists := DemandInvtProfile.FindSet();
                    DemandInvtProfile.SetRange("Due Date");

                    SupplyInvtProfile.SetFilter("Untracked Quantity", '>=0');
                    SupplyExists := SupplyInvtProfile.FindSet();

                    ProcessSupplyBeforeStartDate := SupplyExists;
                    while ProcessSupplyBeforeStartDate do begin
                        if (SupplyInvtProfile."Due Date" < PlanningStartDate) and (SupplyInvtProfile."Due Date" > 0D) and (SupplyInvtProfile."Untracked Quantity" = 0) then
                            SupplyExists := SupplyInvtProfile.Next() <> 0;
                        ProcessSupplyBeforeStartDate := SupplyExists and (SupplyInvtProfile."Due Date" < PlanningStartDate) and (SupplyInvtProfile."Due Date" > 0D) and (SupplyInvtProfile."Untracked Quantity" = 0);
                    end;

                    SupplyInvtProfile.SetRange("Untracked Quantity");
                    SupplyInvtProfile.SetRange("Due Date");

                    if not SupplyExists then
                        if not SupplyInvtProfile.IsEmpty() then begin
                            SupplyInvtProfile.SetRange("Due Date", PlanningStartDate, ToDate);
                            SupplyExists := SupplyInvtProfile.FindSet();
                            SupplyInvtProfile.SetRange("Due Date");
                            if NeedOfPublishSurplus and not (DemandExists or SupplyExists) then begin
                                Track(SupplyInvtProfile, DemandInvtProfile, true, false, SupplyInvtProfile.Binding::" ");
                                PlanningTransparency.PublishSurplus(SupplyInvtProfile, TempSKU, ReqLine, TempTrkgReservEntry);
                            end;
                        end;

                    if IsReorderPointPlanning then
                        ChkInitialOverflow(DemandInvtProfile, SupplyInvtProfile,
                          OverflowLevel, LastProjectedInventory, PlanningStartDate, ToDate);

                    CheckSupplyWithSKU(SupplyInvtProfile, TempSKU);

                    LotAccumulationPeriodStartDate := 0D;
                    NextState := NextState::StartOver;
                    OnPlanItemOnBeforePlanThisSKULoop(TempSKU, DemandInvtProfile);
                    while PlanThisSKU do begin
                        OnPlanItemOnBeforePlanThisSKULoopIteration(TempSKU, NextState, DemandInvtProfile, SupplyInvtProfile, SupplyExists, DemandExists, LotAccumulationPeriodStartDate);
                        case NextState of
                            NextState::StartOver:
                                PlanItemNextStateStartOver(
                                  DemandInvtProfile, SupplyInvtProfile, DemandExists, SupplyExists);
                            NextState::MatchDates:
                                PlanItemNextStateMatchDates(
                                  DemandInvtProfile, SupplyInvtProfile, TempReminderInvtProfile, WeAreSureThatDatesMatch, IsReorderPointPlanning,
                                  LastProjectedInventory, LatestBucketStartDate, ROPHasBeenCrossed, NewSupplyHasTakenOver);
                            NextState::MatchQty:
                                PlanItemNextStateMatchQty(
                                  DemandInvtProfile, SupplyInvtProfile, LastProjectedInventory, IsReorderPointPlanning, RespectPlanningParm);
                            NextState::CreateSupply:
                                PlanItemNextStateCreateSupply(
                                  DemandInvtProfile, SupplyInvtProfile, TempReminderInvtProfile, WeAreSureThatDatesMatch, IsReorderPointPlanning,
                                  LastProjectedInventory, LatestBucketStartDate, ROPHasBeenCrossed, NewSupplyHasTakenOver, SupplyExists,
                                  RespectPlanningParm);
                            NextState::ReduceSupply:
                                PlanItemNextStateReduceSupply(
                                  DemandInvtProfile, SupplyInvtProfile, TempReminderInvtProfile, IsReorderPointPlanning,
                                  LastProjectedInventory, LatestBucketStartDate, ROPHasBeenCrossed, NewSupplyHasTakenOver, DemandExists);
                            NextState::CloseDemand:
                                PlanItemNextStateCloseDemand(
                                  DemandInvtProfile, SupplyInvtProfile, TempReminderInvtProfile, IsReorderPointPlanning,
                                  LatestBucketStartDate, DemandExists, SupplyExists, PlanningStartDate);
                            NextState::CloseSupply:
                                PlanItemNextStateCloseSupply(
                                  DemandInvtProfile, SupplyInvtProfile, TempReminderInvtProfile, IsReorderPointPlanning,
                                  LatestBucketStartDate, DemandExists, SupplyExists, ToDate);
                            NextState::CloseLoop:
                                PlanItemNextStateCloseLoop(
                                  DemandInvtProfile, SupplyInvtProfile, TempReminderInvtProfile, IsReorderPointPlanning,
                                  LastProjectedInventory, LatestBucketStartDate, ROPHasBeenCrossed, NewSupplyHasTakenOver, SupplyExists,
                                  ToDate, PlanThisSKU);
                            else
                                Error(Text001, SelectStr(NextState + 1, NextStateTxt));
                        end;
                    end;
                end;
                OnPlanItemOnAfterTempSKULoop(TempSKU, ReqLine);
            until TempSKU.Next() = 0;

        SetAcceptAction(TempSKU."Item No.");
    end;

    local procedure PlanItemCalcInitialInventory(var DemandInvtProfile: Record "Inventory Profile"; var SupplyInvtProfile: Record "Inventory Profile"; PlanningStartDate: Date; var DemandExists: Boolean; var SupplyExists: Boolean; var LastProjectedInventory: Decimal)
    var
        IncrementLastProjectedInventory: Boolean;
    begin
        DemandInvtProfile.SetRange("Due Date", 0D, PlanningStartDate - 1);
        SupplyInvtProfile.SetRange("Due Date", 0D, PlanningStartDate - 1);
        DemandExists := DemandInvtProfile.FindSet();
        SupplyExists := SupplyInvtProfile.FindSet();
        OnBeforePrePlanDateApplicationLoop(SupplyInvtProfile, DemandInvtProfile, SupplyExists, DemandExists, LastProjectedInventory);
        while DemandExists and SupplyExists do begin
            IncrementLastProjectedInventory := true;
            OnStartOfPrePlanDateApplicationLoop(SupplyInvtProfile, DemandInvtProfile, SupplyExists, DemandExists, IncrementLastProjectedInventory);
            if DemandInvtProfile."Untracked Quantity" > SupplyInvtProfile."Untracked Quantity" then begin
                if IncrementLastProjectedInventory then
                    LastProjectedInventory += SupplyInvtProfile."Remaining Quantity (Base)";
                DemandInvtProfile."Untracked Quantity" -= SupplyInvtProfile."Untracked Quantity";
                FrozenZoneTrack(SupplyInvtProfile, DemandInvtProfile);
                SupplyInvtProfile."Untracked Quantity" := 0;
                SupplyInvtProfile.Modify();
                SupplyExists := SupplyInvtProfile.Next() <> 0;
            end else begin
                if IncrementLastProjectedInventory then
                    LastProjectedInventory -= DemandInvtProfile."Remaining Quantity (Base)";
                SupplyInvtProfile."Untracked Quantity" -= DemandInvtProfile."Untracked Quantity";
                FrozenZoneTrack(DemandInvtProfile, SupplyInvtProfile);
                DemandInvtProfile."Untracked Quantity" := 0;
                DemandInvtProfile.Modify();
                DemandExists := DemandInvtProfile.Next() <> 0;
                if not DemandExists then
                    SupplyInvtProfile.Modify();
            end;
            OnEndOfPrePlanDateApplicationLoop(SupplyInvtProfile, DemandInvtProfile, SupplyExists, DemandExists);
        end;
    end;

    local procedure PlanItemNextStateCloseDemand(var DemandInvtProfile: Record "Inventory Profile"; var SupplyInvtProfile: Record "Inventory Profile"; var TempReminderInvtProfile: Record "Inventory Profile" temporary; IsReorderPointPlanning: Boolean; LatestBucketStartDate: Date; var DemandExists: Boolean; var SupplyExists: Boolean; PlanningStartDate: Date)
    begin
        if DemandInvtProfile."Due Date" < PlanningStartDate then
            Error(Text001, DemandInvtProfile.FieldCaption("Due Date"));

        if DemandInvtProfile."Order Relation" = DemandInvtProfile."Order Relation"::"Safety Stock" then begin
            AllocateSafetystock(SupplyInvtProfile, DemandInvtProfile."Untracked Quantity", DemandInvtProfile."Due Date");
            if IsReorderPointPlanning and (SupplyInvtProfile."Due Date" >= LatestBucketStartDate) then
                PostInvChgReminder(TempReminderInvtProfile, SupplyInvtProfile, true);
        end else begin
            if IsReorderPointPlanning then
                PostInvChgReminder(TempReminderInvtProfile, DemandInvtProfile, false);
            if DemandInvtProfile."Untracked Quantity" <> 0 then begin
                SupplyInvtProfile."Untracked Quantity" -= DemandInvtProfile."Untracked Quantity";
                if SupplyInvtProfile."Untracked Quantity" < SupplyInvtProfile."Safety Stock Quantity" then
                    SupplyInvtProfile."Safety Stock Quantity" := SupplyInvtProfile."Untracked Quantity";
                if SupplyInvtProfile."Action Message" <> SupplyInvtProfile."Action Message"::" " then
                    MaintainPlanningLine(
                      SupplyInvtProfile, DemandInvtProfile, PlanningLineStage::"Line Created", ScheduleDirection::Backward);
                SupplyInvtProfile.Modify();
                if IsReorderPointPlanning and (SupplyInvtProfile."Due Date" >= LatestBucketStartDate) then
                    PostInvChgReminder(TempReminderInvtProfile, SupplyInvtProfile, true);
                CheckSupplyAndTrack(DemandInvtProfile, SupplyInvtProfile);
                SurplusType := PlanningTransparency.GetSurplusType(DemandInvtProfile);
                if SurplusType <> SurplusType::None then
                    PlanningTransparency.LogPlanningSurplus(
                      SupplyInvtProfile."Line No.", DemandInvtProfile."Line No.",
                      DemandInvtProfile."Source Type", DemandInvtProfile."Source ID",
                      DemandInvtProfile."Untracked Quantity", SurplusType);
            end;
        end;

        OnPlanItemNextStateCloseDemandOnBeforeDemandInvtProfileDelete(DemandInvtProfile, ReqLine);
        DemandInvtProfile.Delete();

        // If just handled demand was safetystock
        if DemandInvtProfile."Order Relation" = DemandInvtProfile."Order Relation"::"Safety Stock" then
            SupplyExists := SupplyInvtProfile.FindSet(true); // We assume that next profile is NOT safety stock

        DemandExists := DemandInvtProfile.Next() <> 0;
        NextState := NextState::StartOver;

        OnAfterPlanItemNextStateCloseDemand(SupplyInvtProfile, SupplyExists);
    end;

    local procedure PlanItemNextStateCloseLoop(var DemandInvtProfile: Record "Inventory Profile"; var SupplyInvtProfile: Record "Inventory Profile"; var TempReminderInvtProfile: Record "Inventory Profile" temporary; IsReorderPointPlanning: Boolean; var LastProjectedInventory: Decimal; var LatestBucketStartDate: Date; var ROPHasBeenCrossed: Boolean; var NewSupplyHasTakenOver: Boolean; var SupplyExists: Boolean; ToDate: Date; var PlanThisSKU: Boolean)
    begin
        if IsReorderPointPlanning then
            MaintainProjectedInventory(
              TempReminderInvtProfile, ToDate, LastProjectedInventory, LatestBucketStartDate, ROPHasBeenCrossed);
        if ROPHasBeenCrossed then begin
            CreateSupplyForward(
              SupplyInvtProfile, DemandInvtProfile, TempReminderInvtProfile,
              LatestBucketStartDate, LastProjectedInventory, NewSupplyHasTakenOver, DemandInvtProfile."Due Date");
            SupplyExists := true;
            NextState := NextState::StartOver;
        end else
            PlanThisSKU := false;
    end;

    local procedure PlanItemNextStateCloseSupply(var DemandInvtProfile: Record "Inventory Profile"; var SupplyInvtProfile: Record "Inventory Profile"; var TempReminderInvtProfile: Record "Inventory Profile" temporary; IsReorderPointPlanning: Boolean; LatestBucketStartDate: Date; DemandExists: Boolean; var SupplyExists: Boolean; ToDate: Date)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnPlanItemNextStateCloseSupplyOnBeforeUpdateDemandUntrackedQty(SupplyInvtProfile, DemandInvtProfile, IsHandled);
        if not IsHandled then
            if DemandExists and (SupplyInvtProfile."Untracked Quantity" > 0) then begin
                DemandInvtProfile."Untracked Quantity" -= SupplyInvtProfile."Untracked Quantity";
                DemandInvtProfile.Modify();
            end;

        if DemandExists and
           (DemandInvtProfile."Order Relation" = DemandInvtProfile."Order Relation"::"Safety Stock")
        then begin
            AllocateSafetystock(SupplyInvtProfile, SupplyInvtProfile."Untracked Quantity", DemandInvtProfile."Due Date");
            if IsReorderPointPlanning and (SupplyInvtProfile."Due Date" >= LatestBucketStartDate) then
                PostInvChgReminder(TempReminderInvtProfile, SupplyInvtProfile, true);
        end else begin
            if IsReorderPointPlanning and (SupplyInvtProfile."Due Date" >= LatestBucketStartDate) then
                PostInvChgReminder(TempReminderInvtProfile, SupplyInvtProfile, false);

            if SupplyInvtProfile."Action Message" <> SupplyInvtProfile."Action Message"::" " then
                MaintainPlanningLine(
                  SupplyInvtProfile, DemandInvtProfile, PlanningLineStage::Exploded, ScheduleDirection::Backward)
            else
                SupplyInvtProfile.TestField("Planning Line No.", 0);

            IsHandled := false;
            OnPlanItemNextStateCloseSupplyOnBeforeProcessActionMessageNew(SupplyInvtProfile, DemandInvtProfile, IsHandled);
            if not IsHandled then begin
                if (SupplyInvtProfile."Action Message" = SupplyInvtProfile."Action Message"::New) or
                   (SupplyInvtProfile."Due Date" <= ToDate)
                then
                    if DemandExists then
                        Track(SupplyInvtProfile, DemandInvtProfile, false, false, SupplyInvtProfile.Binding)
                    else
                        Track(SupplyInvtProfile, DemandInvtProfile, true, false, SupplyInvtProfile.Binding::" ");
                SupplyInvtProfile.Delete();
            end;

            // Planning Transparency
            if DemandExists then begin
                SurplusType := PlanningTransparency.GetSurplusType(DemandInvtProfile);
                if SurplusType <> SurplusType::None then
                    PlanningTransparency.LogPlanningSurplus(
                        SupplyInvtProfile."Line No.", DemandInvtProfile."Line No.",
                        DemandInvtProfile."Source Type", DemandInvtProfile."Source ID",
                        SupplyInvtProfile."Untracked Quantity", SurplusType);
            end;
            if SupplyInvtProfile."Planning Line No." <> 0 then begin
                if SupplyInvtProfile."Safety Stock Quantity" > 0 then
                    PlanningTransparency.LogPlanningSurplus(
                        SupplyInvtProfile."Line No.", SupplyInvtProfile."Line No.", 0, '',
                        SupplyInvtProfile."Safety Stock Quantity", SurplusType::SafetyStock);
                if SupplyInvtProfile."Planning Line No." <> ReqLine."Line No." then
                    ReqLine.Get(CurrTemplateName, CurrWorksheetName, SupplyInvtProfile."Planning Line No.");
                PlanningTransparency.PublishSurplus(SupplyInvtProfile, TempSKU, ReqLine, TempTrkgReservEntry);
            end else
                PlanningTransparency.CleanLog(SupplyInvtProfile."Line No.");
        end;
        if TempSKU."Maximum Order Quantity" > 0 then
            CheckSupplyRemQtyAndUntrackQty(SupplyInvtProfile);
        SupplyExists := SupplyInvtProfile.Next() <> 0;
        OnPlanItemNextStateCloseSupplyOnAfterCheckSupplyExist(SupplyInvtProfile, SupplyExists);

        NextState := NextState::StartOver;
    end;

    local procedure PlanItemNextStateCreateSupply(var DemandInvtProfile: Record "Inventory Profile"; var SupplyInvtProfile: Record "Inventory Profile"; var TempReminderInvtProfile: Record "Inventory Profile" temporary; var WeAreSureThatDatesMatch: Boolean; IsReorderPointPlanning: Boolean; var LastProjectedInventory: Decimal; var LatestBucketStartDate: Date; var ROPHasBeenCrossed: Boolean; var NewSupplyHasTakenOver: Boolean; var SupplyExists: Boolean; RespectPlanningParm: Boolean)
    var
        NewSupplyDate: Date;
        IsExceptionOrder: Boolean;
    begin
        WeAreSureThatDatesMatch := true; // We assume this is true at this point.....
        if FromLotAccumulationPeriodStartDate(LotAccumulationPeriodStartDate, DemandInvtProfile."Due Date") then
            NewSupplyDate := LotAccumulationPeriodStartDate
        else begin
            NewSupplyDate := DemandInvtProfile."Due Date";
            LotAccumulationPeriodStartDate := 0D;
        end;
        OnPlanItemNextStateCreateSupplyOnAfterCalcNewSupplyDate(NewSupplyDate, TempSKU, SupplyInvtProfile);

        if (NewSupplyDate >= LatestBucketStartDate) and IsReorderPointPlanning then
            MaintainProjectedInventory(
              TempReminderInvtProfile, NewSupplyDate, LastProjectedInventory, LatestBucketStartDate, ROPHasBeenCrossed);
        if ROPHasBeenCrossed then begin
            CreateSupplyForward(SupplyInvtProfile, DemandInvtProfile, TempReminderInvtProfile,
              LatestBucketStartDate, LastProjectedInventory, NewSupplyHasTakenOver, DemandInvtProfile."Due Date");
            if NewSupplyHasTakenOver then begin
                SupplyExists := true;
                WeAreSureThatDatesMatch := false;
                NextState := NextState::MatchDates;
            end;
        end;

        if WeAreSureThatDatesMatch then begin
            IsExceptionOrder := IsReorderPointPlanning;
            CreateSupply(SupplyInvtProfile, DemandInvtProfile,
              LastProjectedInventory +
              QtyFromPendingReminders(TempReminderInvtProfile, DemandInvtProfile."Due Date", LatestBucketStartDate) -
              DemandInvtProfile."Remaining Quantity (Base)",
              IsExceptionOrder, RespectPlanningParm);
            SupplyInvtProfile."Due Date" := NewSupplyDate;
            SupplyInvtProfile."Fixed Date" := SupplyInvtProfile."Due Date"; // We note the latest possible date on the SupplyInvtProfile.
            SupplyExists := true;
            if IsExceptionOrder then begin
                DummyInventoryProfileTrackBuffer."Warning Level" :=
                  DummyInventoryProfileTrackBuffer."Warning Level"::Exception;
                PlanningTransparency.LogWarning(
                  SupplyInvtProfile."Line No.", ReqLine, DummyInventoryProfileTrackBuffer."Warning Level",
                  StrSubstNo(Text007, DummyInventoryProfileTrackBuffer."Warning Level",
                    TempSKU.FieldCaption("Safety Stock Quantity"), TempSKU."Safety Stock Quantity",
                    DemandInvtProfile."Due Date"));
            end;
            NextState := NextState::MatchQty;
        end;
    end;

    local procedure PlanItemNextStateMatchDates(var DemandInvtProfile: Record "Inventory Profile"; var SupplyInvtProfile: Record "Inventory Profile"; var TempReminderInvtProfile: Record "Inventory Profile" temporary; var WeAreSureThatDatesMatch: Boolean; IsReorderPointPlanning: Boolean; var LastProjectedInventory: Decimal; var LatestBucketStartDate: Date; var ROPHasBeenCrossed: Boolean; var NewSupplyHasTakenOver: Boolean)
    var
        OriginalSupplyDate: Date;
        ShouldCalcNewSupplyDate: Boolean;
        NewSupplyDate: Date;
        CanBeRescheduled: Boolean;
        DemandDueDate: Date;
        LimitedHorizon: Boolean;
        IsHandled: Boolean;
    begin
        ShouldCalcNewSupplyDate := true;
        IsHandled := false;
        OnBeforePlanItemNextStateMatchDates(DemandInvtProfile, SupplyInvtProfile, NextState, IsHandled, ShouldCalcNewSupplyDate);
        if IsHandled then
            exit;

        if ShouldCalcNewSupplyDate then
            if FromLotAccumulationPeriodStartDate(LotAccumulationPeriodStartDate, DemandInvtProfile."Due Date") then begin
                NewSupplyDate := LotAccumulationPeriodStartDate;
                SupplyInvtProfile."Fixed Date" := NewSupplyDate;
            end else begin
                NewSupplyDate := SupplyInvtProfile."Due Date";
                LotAccumulationPeriodStartDate := 0D;
            end;

        OnPlanItemNextStateMatchDatesOnAfterCalcNewSupplyDate(NewSupplyDate, TempSKU, SupplyInvtProfile, LotAccumulationPeriodStartDate);
        DemandDueDate := DemandInvtProfile."Due Date";
        if TempSKU."Replenishment System" = TempSKU."Replenishment System"::Purchase then
            DemandDueDate := GetPrevAvailDateFromCompanyCalendar(DemandInvtProfile."Due Date");

        OriginalSupplyDate := SupplyInvtProfile."Due Date";
        WeAreSureThatDatesMatch := false;

        if DemandDueDate < SupplyInvtProfile."Due Date" then begin
            CanBeRescheduled := CheckScheduleIn(SupplyInvtProfile, DemandDueDate, NewSupplyDate, true);
            if CanBeRescheduled then
                WeAreSureThatDatesMatch := true
            else
                NextState := NextState::CreateSupply;
        end else
            if DemandDueDate > SupplyInvtProfile."Due Date" then begin
                LimitedHorizon := true;
                OnPlanItemNextStateMatchDatesOnBeforeCheckScheduleOut(SupplyInvtProfile, LimitedHorizon);
                CanBeRescheduled := CheckScheduleOut(SupplyInvtProfile, DemandDueDate, NewSupplyDate, LimitedHorizon);
                if CanBeRescheduled then
                    WeAreSureThatDatesMatch := not ScheduleAllOutChangesSequence(SupplyInvtProfile, NewSupplyDate)
                else
                    NextState := NextState::ReduceSupply;
            end else begin
                WeAreSureThatDatesMatch := true;
                CanBeRescheduled := SupplyInvtProfile."Planning Flexibility" = SupplyInvtProfile."Planning Flexibility"::Unlimited;
            end;

        if WeAreSureThatDatesMatch and IsReorderPointPlanning then begin
            // Now we know the final position on the timeline of the SupplyInvtProfile.
            MaintainProjectedInventory(
              TempReminderInvtProfile, NewSupplyDate, LastProjectedInventory, LatestBucketStartDate, ROPHasBeenCrossed);
            if ROPHasBeenCrossed then begin
                CreateSupplyForward(SupplyInvtProfile, DemandInvtProfile, TempReminderInvtProfile,
                  LatestBucketStartDate, LastProjectedInventory, NewSupplyHasTakenOver, DemandDueDate);
                if NewSupplyHasTakenOver then begin
                    WeAreSureThatDatesMatch := false;
                    NextState := NextState::MatchDates;
                end;
            end;
        end;

        if WeAreSureThatDatesMatch then begin
            if CanBeRescheduled and (NewSupplyDate <> OriginalSupplyDate) then begin
                Reschedule(SupplyInvtProfile, NewSupplyDate, 0T);
                SupplyInvtProfile.TestField("Due Date", NewSupplyDate);
            end;
            SupplyInvtProfile."Fixed Date" := SupplyInvtProfile."Due Date"; // We note the latest possible date on the SupplyInvtProfile.
            NextState := NextState::MatchQty;
        end;
    end;

    local procedure PlanItemNextStateMatchQty(var DemandInventoryProfile: Record "Inventory Profile"; var SupplyInventoryProfile: Record "Inventory Profile"; var LastProjectedInventory: Decimal; IsReorderPointPlanning: Boolean; RespectPlanningParm: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePlanItemNextStateMatchQty(SupplyInventoryProfile, DemandInventoryProfile, NextState, IsHandled);
        if IsHandled then
            exit;

        case true of
            SupplyInventoryProfile."Untracked Quantity" >= DemandInventoryProfile."Untracked Quantity":
                NextState := NextState::CloseDemand;
            ShallSupplyBeClosed(SupplyInventoryProfile, DemandInventoryProfile."Due Date", IsReorderPointPlanning):
                NextState := NextState::CloseSupply;
            IncreaseQtyToMeetDemand(SupplyInventoryProfile, DemandInventoryProfile, true, RespectPlanningParm, true):
                begin
                    NextState := NextState::CloseDemand;
                    // initial Safety Stock can be changed to normal, if we can increase qty for normal demand
                    if (SupplyInventoryProfile."Order Relation" = SupplyInventoryProfile."Order Relation"::"Safety Stock") and
                       (DemandInventoryProfile."Order Relation" = DemandInventoryProfile."Order Relation"::Normal)
                    then begin
                        SupplyInventoryProfile."Order Relation" := SupplyInventoryProfile."Order Relation"::Normal;
                        LastProjectedInventory -= TempSKU."Safety Stock Quantity";
                    end;
                end;
            else begin
                NextState := NextState::CloseSupply;
                if TempSKU."Maximum Order Quantity" > 0 then
                    LotAccumulationPeriodStartDate := SupplyInventoryProfile."Due Date";
            end;
        end;
    end;

    local procedure PlanItemNextStateReduceSupply(var DemandInvtProfile: Record "Inventory Profile"; var SupplyInvtProfile: Record "Inventory Profile"; var TempReminderInvtProfile: Record "Inventory Profile" temporary; IsReorderPointPlanning: Boolean; var LastProjectedInventory: Decimal; var LatestBucketStartDate: Date; var ROPHasBeenCrossed: Boolean; var NewSupplyHasTakenOver: Boolean; DemandExists: Boolean)
    begin
        if IsReorderPointPlanning and (SupplyInvtProfile."Due Date" >= LatestBucketStartDate) then
            MaintainProjectedInventory(
              TempReminderInvtProfile, SupplyInvtProfile."Due Date", LastProjectedInventory, LatestBucketStartDate, ROPHasBeenCrossed);
        NewSupplyHasTakenOver := false;
        if ROPHasBeenCrossed then begin
            CreateSupplyForward(
              SupplyInvtProfile, DemandInvtProfile, TempReminderInvtProfile,
              LatestBucketStartDate, LastProjectedInventory, NewSupplyHasTakenOver, SupplyInvtProfile."Due Date");
            if NewSupplyHasTakenOver then
                if DemandExists then
                    NextState := NextState::MatchDates
                else
                    NextState := NextState::CloseSupply;
        end;

        if not NewSupplyHasTakenOver then
            if DecreaseQty(SupplyInvtProfile, SupplyInvtProfile."Untracked Quantity", true) then
                NextState := NextState::CloseSupply
            else begin
                SupplyInvtProfile."Max. Quantity" := SupplyInvtProfile."Remaining Quantity (Base)";
                if DemandExists then
                    NextState := NextState::MatchQty
                else
                    NextState := NextState::CloseSupply;
            end;
    end;

    local procedure PlanItemNextStateStartOver(var DemandInvtProfile: Record "Inventory Profile"; var SupplyInvtProfile: Record "Inventory Profile"; var DemandExists: Boolean; var SupplyExists: Boolean)
    var
        IsHandled: Boolean;
    begin
        if DemandExists and (DemandInvtProfile."Source Type" = Database::"Transfer Line") then
            while CancelTransfer(SupplyInvtProfile, DemandInvtProfile, DemandExists) do
                DemandExists := DemandInvtProfile.Next() <> 0;

        IsHandled := false;
        OnBeforePlanStepSettingOnStartOver(
          SupplyInvtProfile, DemandInvtProfile, SupplyExists, DemandExists, NextState, IsHandled);
        if not IsHandled then
            if DemandExists then
                if DemandInvtProfile."Untracked Quantity" = 0 then
                    NextState := NextState::CloseDemand
                else
                    if SupplyExists then
                        NextState := NextState::MatchDates
                    else
                        NextState := NextState::CreateSupply
            else
                if SupplyExists then
                    NextState := NextState::ReduceSupply
                else
                    NextState := NextState::CloseLoop;

        OnAfterPlanItemNextStateStartOver(SupplyInvtProfile, TempSKU);
    end;

    local procedure PlanItemSetInvtProfileFilters(var DemandInvtProfile: Record "Inventory Profile"; var SupplyInvtProfile: Record "Inventory Profile")
    var
        IsHandled: Boolean;
    begin
        DemandInvtProfile.Reset();
        SupplyInvtProfile.Reset();
        DemandInvtProfile.SetRange(IsSupply, false);
        SupplyInvtProfile.SetRange(IsSupply, true);

        IsHandled := false;
        OnPlanItemSetInvtProfileFiltersOnBeforeSetCurrentKeys(SupplyInvtProfile, DemandInvtProfile, IsHandled);
        if not IsHandled then begin
            DemandInvtProfile.SetCurrentKey("Item No.", "Variant Code", "Location Code", "Due Date", "Attribute Priority", "Order Priority");
            SupplyInvtProfile.SetCurrentKey("Item No.", "Variant Code", "Location Code", "Due Date", "Attribute Priority", "Order Priority");
        end;

        SupplyInvtProfile.SetRange("Drop Shipment", false);
        SupplyInvtProfile.SetRange("Special Order", false);
        DemandInvtProfile.SetRange("Drop Shipment", false);
        DemandInvtProfile.SetRange("Special Order", false);

        OnAfterPlanItemSetInvtProfileFilters(DemandInvtProfile, SupplyInvtProfile);
    end;

    local procedure FilterDemandSupplyRelatedToSKU(var InventoryProfile: Record "Inventory Profile")
    begin
        InventoryProfile.SetRange("Item No.", TempSKU."Item No.");
        InventoryProfile.SetRange("Variant Code", TempSKU."Variant Code");
        InventoryProfile.SetRange("Location Code", TempSKU."Location Code");
        OnAfterFilterDemandSupplyRelatedToSKU(InventoryProfile, TempSKU);
    end;

    procedure ScheduleForward(var SupplyInvtProfile: Record "Inventory Profile"; DemandInvtProfile: Record "Inventory Profile"; StartingDate: Date)
    begin
        SupplyInvtProfile."Starting Date" := StartingDate;
        MaintainPlanningLine(SupplyInvtProfile, DemandInvtProfile, PlanningLineStage::"Routing Created", ScheduleDirection::Forward);
        if (SupplyInvtProfile."Fixed Date" > 0D) and
           (SupplyInvtProfile."Fixed Date" < SupplyInvtProfile."Due Date")
        then
            SupplyInvtProfile."Due Date" := SupplyInvtProfile."Fixed Date"
        else
            SupplyInvtProfile."Fixed Date" := SupplyInvtProfile."Due Date";
    end;

    local procedure IncreaseQtyToMeetDemand(var SupplyInvtProfile: Record "Inventory Profile"; DemandInvtProfile: Record "Inventory Profile"; LimitedHorizon: Boolean; RespectPlanningParm: Boolean; CheckSourceType: Boolean) Result: Boolean
    var
        TotalDemandedQty: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIncreaseQtyToMeetDemand(SupplyInvtProfile, DemandInvtProfile, CheckSourceType, Result, IsHandled, TempSKU);
        if IsHandled then
            exit(Result);

        if SupplyInvtProfile."Planning Flexibility" <> SupplyInvtProfile."Planning Flexibility"::Unlimited then
            exit(false);

        if CheckSourceType then
            if ((DemandInvtProfile."Source Type" = Database::"Planning Component") and
                (SupplyInvtProfile."Source Type" = 5406) or // Database::"Prod. Order Line"
                (DemandInvtProfile."Source Type" = Database::"Requisition Line")) and
               (DemandInvtProfile.Binding = DemandInvtProfile.Binding::"Order-to-Order")
            then
                exit(false);

        if (SupplyInvtProfile."Max. Quantity" > 0) or
           (SupplyInvtProfile."Action Message" = SupplyInvtProfile."Action Message"::Cancel)
        then
            if SupplyInvtProfile."Max. Quantity" <= SupplyInvtProfile."Remaining Quantity (Base)" then
                exit(false);

        if LimitedHorizon then
            if not AllowLotAccumulation(SupplyInvtProfile, DemandInvtProfile."Due Date") then
                exit(false);

        TotalDemandedQty := DemandInvtProfile."Untracked Quantity";
        IncreaseQty(
          SupplyInvtProfile, DemandInvtProfile."Untracked Quantity" - SupplyInvtProfile."Untracked Quantity", RespectPlanningParm);
        exit(TotalDemandedQty <= SupplyInvtProfile."Untracked Quantity");
    end;

    local procedure IncreaseQty(var SupplyInvtProfile: Record "Inventory Profile"; NeededQty: Decimal; RespectPlanningParm: Boolean)
    var
        TempQty: Decimal;
    begin
        OnBeforeIncreaseQty(SupplyInvtProfile, NeededQty, TempSKU);

        TempQty := SupplyInvtProfile."Remaining Quantity (Base)";

        if not SupplyInvtProfile."Is Exception Order" or RespectPlanningParm then
            SupplyInvtProfile."Remaining Quantity (Base)" += NeededQty +
              AdjustReorderQty(
                SupplyInvtProfile."Remaining Quantity (Base)" + NeededQty, TempSKU, SupplyInvtProfile."Line No.",
                SupplyInvtProfile."Min. Quantity")
        else
            SupplyInvtProfile."Remaining Quantity (Base)" += NeededQty;

        if TempSKU."Maximum Order Quantity" > 0 then
            if SupplyInvtProfile."Remaining Quantity (Base)" > TempSKU."Maximum Order Quantity" then
                SupplyInvtProfile."Remaining Quantity (Base)" := TempSKU."Maximum Order Quantity";
        if (SupplyInvtProfile."Action Message" <> SupplyInvtProfile."Action Message"::New) and
           (SupplyInvtProfile."Remaining Quantity (Base)" <> TempQty)
        then begin
            if SupplyInvtProfile."Original Quantity" = 0 then
                SupplyInvtProfile."Original Quantity" := SupplyInvtProfile.Quantity;
            if SupplyInvtProfile."Original Due Date" = 0D then
                SupplyInvtProfile."Action Message" := SupplyInvtProfile."Action Message"::"Change Qty."
            else
                SupplyInvtProfile."Action Message" := SupplyInvtProfile."Action Message"::"Resched. & Chg. Qty.";
        end;

        SupplyInvtProfile."Untracked Quantity" :=
          SupplyInvtProfile."Untracked Quantity" +
          SupplyInvtProfile."Remaining Quantity (Base)" -
          TempQty;

        SupplyInvtProfile."Quantity (Base)" :=
          SupplyInvtProfile."Quantity (Base)" +
          SupplyInvtProfile."Remaining Quantity (Base)" -
          TempQty;
        SupplyInvtProfile.Modify();
    end;

    local procedure InsertEmergencyOrderSupply(var SupplyInvtProfile: Record "Inventory Profile"; var DemandInvtProfile: Record "Inventory Profile"; var LastAvailableInventory: Decimal; var LastProjectedInventory: Decimal; PlanningStartDate: Date)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertEmergencyOrderSupply(SupplyInvtProfile, DemandInvtProfile, IsHandled, PlanningStartDate);
        if IsHandled then
            exit;

        InitSupply(SupplyInvtProfile, -LastAvailableInventory, PlanningStartDate - 1, 0T);
        OnInsertEmergencyOrderSupplyOnAfterInitSupply(SupplyInvtProfile, DemandInvtProfile);
        SupplyInvtProfile."Planning Flexibility" := SupplyInvtProfile."Planning Flexibility"::None;
        SupplyInvtProfile.Insert();
        MaintainPlanningLine(SupplyInvtProfile, DemandInvtProfile, PlanningLineStage::Exploded, ScheduleDirection::Backward);
        Track(SupplyInvtProfile, DemandInvtProfile, true, false, SupplyInvtProfile.Binding::" ");

        DemandInvtProfile.SetFilter("Untracked Quantity", '<>0');
        if DemandInvtProfile.FindFirst() then
            Track(DemandInvtProfile, SupplyInvtProfile, true, false, Enum::"Reservation Binding"::" ");
        DemandInvtProfile.SetRange("Untracked Quantity");

        LastProjectedInventory += SupplyInvtProfile."Remaining Quantity (Base)";
        LastAvailableInventory += SupplyInvtProfile."Untracked Quantity";
        PlanningTransparency.LogPlanningSurplus(
            SupplyInvtProfile."Line No.", SupplyInvtProfile."Line No.", 0, '',
            SupplyInvtProfile."Untracked Quantity", SurplusType::EmergencyOrder);
        SupplyInvtProfile."Untracked Quantity" := 0;
        if SupplyInvtProfile."Planning Line No." <> ReqLine."Line No." then
            ReqLine.Get(CurrTemplateName, CurrWorksheetName, SupplyInvtProfile."Planning Line No.");
        PlanningTransparency.PublishSurplus(SupplyInvtProfile, TempSKU, ReqLine, TempTrkgReservEntry);
        DummyInventoryProfileTrackBuffer."Warning Level" := DummyInventoryProfileTrackBuffer."Warning Level"::Emergency;
        PlanningTransparency.LogWarning(
            0, ReqLine, DummyInventoryProfileTrackBuffer."Warning Level",
            StrSubstNo(
            Text006, DummyInventoryProfileTrackBuffer."Warning Level", -SupplyInvtProfile."Remaining Quantity (Base)",
            PlanningStartDate));
        SupplyInvtProfile.Delete();
        OnAfterInsertEmergencyOrderSupply(SupplyInvtProfile, DemandInvtProfile, PlanningStartDate);
    end;

    procedure DecreaseQty(var SupplyInvtProfile: Record "Inventory Profile"; ReduceQty: Decimal; RespectPlanningParm: Boolean): Boolean
    var
        TempQty: Decimal;
        NewRemainingQty: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDecreaseQty(SupplyInvtProfile, ReduceQty, TempSKU, IsHandled);
        if IsHandled then
            exit;

        if not CanDecreaseSupply(SupplyInvtProfile, ReduceQty) then begin
            if (ReduceQty <= DampenerQty) and (SupplyInvtProfile."Planning Level Code" = 0) then
                PlanningTransparency.LogPlanningSurplus(
                  SupplyInvtProfile."Line No.", 0,
                  99000765, SupplyInvtProfile."Source ID", // Database::"Manufacturing Setup"
                  DampenerQty, SurplusType::DampenerQty);
            exit(false);
        end;

        if ReduceQty > 0 then begin
            TempQty := SupplyInvtProfile."Remaining Quantity (Base)";

            if RespectPlanningParm then begin
                NewRemainingQty :=
                    SupplyInvtProfile."Remaining Quantity (Base)" - ReduceQty +
                    AdjustReorderQty(
                        SupplyInvtProfile."Remaining Quantity (Base)" - ReduceQty, TempSKU, SupplyInvtProfile."Line No.",
                        SupplyInvtProfile."Min. Quantity");

                if (SupplyInvtProfile."Action Message" <> SupplyInvtProfile."Action Message"::New) and (TempQty <> NewRemainingQty) then
                    if (Abs(TempQty - NewRemainingQty) < DampenerQty) and (SupplyInvtProfile."Planning Level Code" = 0) then
                        exit(false);

                SupplyInvtProfile."Remaining Quantity (Base)" := NewRemainingQty;
            end else
                SupplyInvtProfile."Remaining Quantity (Base)" -= ReduceQty;

            if TempSKU."Maximum Order Quantity" > 0 then
                if SupplyInvtProfile."Remaining Quantity (Base)" > TempSKU."Maximum Order Quantity" then
                    SupplyInvtProfile."Remaining Quantity (Base)" := TempSKU."Maximum Order Quantity";
            if (SupplyInvtProfile."Action Message" <> SupplyInvtProfile."Action Message"::New) and
               (TempQty <> SupplyInvtProfile."Remaining Quantity (Base)")
            then begin
                if SupplyInvtProfile."Original Quantity" = 0 then
                    SupplyInvtProfile."Original Quantity" := SupplyInvtProfile.Quantity;
                if SupplyInvtProfile."Remaining Quantity (Base)" = 0 then
                    SupplyInvtProfile."Action Message" := SupplyInvtProfile."Action Message"::Cancel
                else
                    if SupplyInvtProfile."Original Due Date" = 0D then
                        SupplyInvtProfile."Action Message" := SupplyInvtProfile."Action Message"::"Change Qty."
                    else
                        SupplyInvtProfile."Action Message" := SupplyInvtProfile."Action Message"::"Resched. & Chg. Qty.";
            end;

            SupplyInvtProfile."Untracked Quantity" :=
              SupplyInvtProfile."Untracked Quantity" -
              TempQty +
              SupplyInvtProfile."Remaining Quantity (Base)";

            SupplyInvtProfile."Quantity (Base)" :=
              SupplyInvtProfile."Quantity (Base)" -
              TempQty +
              SupplyInvtProfile."Remaining Quantity (Base)";

            SupplyInvtProfile.Modify();
        end;

        exit(SupplyInvtProfile."Untracked Quantity" = 0);
    end;

    procedure CanDecreaseSupply(InventoryProfileSupply: Record "Inventory Profile"; var ReduceQty: Decimal): Boolean
    var
        TrackedQty: Decimal;
        IsHandled: Boolean;
        Result: Boolean;
    begin
        if ReduceQty > InventoryProfileSupply."Untracked Quantity" then
            ReduceQty := InventoryProfileSupply."Untracked Quantity";
        if InventoryProfileSupply."Min. Quantity" > InventoryProfileSupply."Remaining Quantity (Base)" - ReduceQty then
            ReduceQty := InventoryProfileSupply."Remaining Quantity (Base)" - InventoryProfileSupply."Min. Quantity";

        // Ensure leaving enough untracked qty. to cover the safety stock
        TrackedQty := InventoryProfileSupply."Remaining Quantity (Base)" - InventoryProfileSupply."Untracked Quantity";
        if TrackedQty + InventoryProfileSupply."Safety Stock Quantity" > InventoryProfileSupply."Remaining Quantity (Base)" - ReduceQty then
            ReduceQty := InventoryProfileSupply."Remaining Quantity (Base)" - (TrackedQty + InventoryProfileSupply."Safety Stock Quantity");

        // Planning Transparency
        if (ReduceQty <= DampenerQty) and (InventoryProfileSupply."Planning Level Code" = 0) then
            exit(false);

        if (InventoryProfileSupply."Planning Flexibility" = InventoryProfileSupply."Planning Flexibility"::None) or
           ((ReduceQty <= DampenerQty) and
            (InventoryProfileSupply."Planning Level Code" = 0))
        then
            exit(false);

        IsHandled := false;
        OnAfterCanDecreaseSupply(InventoryProfileSupply, ReduceQty, DampenerQty, Result, IsHandled);
        if IsHandled then
            exit(Result);

        exit(true);
    end;

    local procedure CreateSupply(var SupplyInvtProfile: Record "Inventory Profile"; var DemandInvtProfile: Record "Inventory Profile"; ProjectedInventory: Decimal; IsExceptionOrder: Boolean; RespectPlanningParm: Boolean)
    var
        ReorderQty: Decimal;
    begin
        OnBeforeCreateSupply(SupplyInvtProfile, DemandInvtProfile);

        InitSupply(SupplyInvtProfile, 0, DemandInvtProfile."Due Date", DemandInvtProfile."Due Time");
        OnCreateSupplyOnAfterInitSupply(SupplyInvtProfile, DemandInvtProfile);

        ReorderQty := DemandInvtProfile."Untracked Quantity";
        if (not IsExceptionOrder) or RespectPlanningParm then begin
            if not RespectPlanningParm then
                ReorderQty := CalcReorderQty(ReorderQty, ProjectedInventory, SupplyInvtProfile."Line No.")
            else
                if IsExceptionOrder then begin
                    if DemandInvtProfile."Order Relation" =
                       DemandInvtProfile."Order Relation"::"Safety Stock"
                    then // Compensate for Safety Stock offset
                        ProjectedInventory := ProjectedInventory + DemandInvtProfile."Remaining Quantity (Base)";
                    ReorderQty := CalcReorderQty(ReorderQty, ProjectedInventory, SupplyInvtProfile."Line No.");
                    if ReorderQty < -ProjectedInventory then
                        if ProjectedInventory mod TempSKU."Reorder Quantity" = 0 then
                            ReorderQty :=
                              Round(-ProjectedInventory / TempSKU."Reorder Quantity", 1, '>') *
                              TempSKU."Reorder Quantity"
                        else
                            ReorderQty :=
                              Round(-ProjectedInventory / TempSKU."Reorder Quantity" + ExceedROPqty, 1, '>') *
                              TempSKU."Reorder Quantity";
                end;

            if IsReorderQtyToAdjust(TempSKU) then
                ReorderQty += AdjustReorderQty(ReorderQty, TempSKU, SupplyInvtProfile."Line No.", SupplyInvtProfile."Min. Quantity");
            SupplyInvtProfile."Max. Quantity" := TempSKU."Maximum Order Quantity";
        end;
        UpdateQty(SupplyInvtProfile, ReorderQty);
        if TempSKU."Maximum Order Quantity" > 0 then begin
            if SupplyInvtProfile."Remaining Quantity (Base)" > TempSKU."Maximum Order Quantity" then
                SupplyInvtProfile."Remaining Quantity (Base)" := TempSKU."Maximum Order Quantity";
            if SupplyInvtProfile."Untracked Quantity" >= TempSKU."Maximum Order Quantity" then
                SupplyInvtProfile."Untracked Quantity" :=
                  SupplyInvtProfile."Untracked Quantity" -
                  ReorderQty +
                  SupplyInvtProfile."Remaining Quantity (Base)";
        end;
        SupplyInvtProfile."Min. Quantity" := SupplyInvtProfile."Remaining Quantity (Base)";
        TransferAttributes(SupplyInvtProfile, DemandInvtProfile);
        SupplyInvtProfile."Is Exception Order" := IsExceptionOrder;
        OnCreateSupplyOnBeforeSupplyInvtProfileInsert(SupplyInvtProfile, TempSKU);
        SupplyInvtProfile.Insert();
        if (not IsExceptionOrder or RespectPlanningParm) and (OverflowLevel > 0) then
            // the new supply might cause overflow in inventory since
            // it wasn't considered when Overflow was calculated
            CheckNewOverflow(SupplyInvtProfile, ProjectedInventory + ReorderQty, ReorderQty, SupplyInvtProfile."Due Date");
    end;

    procedure CreateDemand(var DemandInvtProfile: Record "Inventory Profile"; var SKU: Record "Stockkeeping Unit"; NeededQuantity: Decimal; NeededDueDate: Date; OrderRelation: Option Normal,"Safety Stock","Reorder Point")
    begin
        DemandInvtProfile.Init();
        DemandInvtProfile."Line No." := GetNextLineNo();
        DemandInvtProfile."Item No." := SKU."Item No.";
        DemandInvtProfile."Variant Code" := SKU."Variant Code";
        DemandInvtProfile."Location Code" := SKU."Location Code";
        DemandInvtProfile."Quantity (Base)" := NeededQuantity;
        DemandInvtProfile."Remaining Quantity (Base)" := NeededQuantity;
        DemandInvtProfile.IsSupply := false;
        DemandInvtProfile."Order Relation" := OrderRelation;
        DemandInvtProfile."Source Type" := 0;
        DemandInvtProfile."Untracked Quantity" := NeededQuantity;
        DemandInvtProfile."Due Date" := NeededDueDate;
        DemandInvtProfile."Planning Flexibility" := DemandInvtProfile."Planning Flexibility"::None;
        OnBeforeDemandInvtProfileInsert(DemandInvtProfile, SKU);
        DemandInvtProfile.Insert();
    end;

    local procedure Track(FromProfile: Record "Inventory Profile"; ToProfile: Record "Inventory Profile"; IsSurplus: Boolean; IssueActionMessage: Boolean; Binding: Enum "Reservation Binding")
    var
        TrkgReservEntryArray: array[6] of Record "Reservation Entry";
        SplitState: Option NoSplit,SplitFromProfile,SplitToProfile,Cancel;
        SplitQty: Decimal;
        SplitQty2: Decimal;
        TrackQty: Decimal;
        DecreaseSupply: Boolean;
    begin
        OnBeforeTrack(FromProfile, ToProfile, IsSurplus, IssueActionMessage, Binding);
        DecreaseSupply :=
          FromProfile.IsSupply and
          (FromProfile."Action Message" in [FromProfile."Action Message"::"Change Qty.",
                                            FromProfile."Action Message"::"Resched. & Chg. Qty."]) and
          (FromProfile."Quantity (Base)" < FromProfile."Original Quantity" * FromProfile."Qty. per Unit of Measure");

        if ((FromProfile."Action Message" = FromProfile."Action Message"::Cancel) and
            (FromProfile."Untracked Quantity" = 0)) or (DecreaseSupply and IsSurplus)
        then begin
            IsSurplus := false;
            if DecreaseSupply then
                FromProfile."Untracked Quantity" :=
                  FromProfile."Original Quantity" * FromProfile."Qty. per Unit of Measure" - FromProfile."Quantity (Base)"
            else
                if FromProfile.IsSupply then
                    FromProfile."Untracked Quantity" := FromProfile."Remaining Quantity" * FromProfile."Qty. per Unit of Measure"
                else
                    FromProfile."Untracked Quantity" := -FromProfile."Remaining Quantity" * FromProfile."Qty. per Unit of Measure";
            FromProfile.TransferToTrackingEntry(TrkgReservEntryArray[1], false);
            TrkgReservEntryArray[3] := TrkgReservEntryArray[1];
            ReqLine.TransferToTrackingEntry(TrkgReservEntryArray[3], true);
            if FromProfile.IsSupply then
                TrkgReservEntryArray[3]."Shipment Date" := FromProfile."Due Date"
            else
                TrkgReservEntryArray[3]."Expected Receipt Date" := FromProfile."Due Date";
            SplitState := SplitState::Cancel;
        end else begin
            TrackQty := FromProfile."Untracked Quantity";

            if FromProfile.IsSupply then begin
                if not ((FromProfile."Original Quantity" * FromProfile."Qty. per Unit of Measure" > FromProfile."Quantity (Base)") or
                        (FromProfile."Untracked Quantity" > 0))
                then
                    exit;

                SplitQty := FromProfile."Original Quantity" * FromProfile."Qty. per Unit of Measure" +
                  FromProfile."Untracked Quantity" - FromProfile."Quantity (Base)";

                case FromProfile."Action Message" of
                    FromProfile."Action Message"::"Resched. & Chg. Qty.",
                    FromProfile."Action Message"::Reschedule,
                    FromProfile."Action Message"::New,
                    FromProfile."Action Message"::"Change Qty.":
                        begin
                            if (SplitQty > 0) and (SplitQty < TrackQty) then begin
                                SplitState := SplitState::SplitFromProfile;
                                FromProfile.TransferToTrackingEntry(TrkgReservEntryArray[1],
                                  (FromProfile."Action Message" = FromProfile."Action Message"::Reschedule) or
                                  (FromProfile."Action Message" = FromProfile."Action Message"::"Resched. & Chg. Qty."));
                                TrkgReservEntryArray[3] := TrkgReservEntryArray[1];
                                ReqLine.TransferToTrackingEntry(TrkgReservEntryArray[3], true);
                                if IsSurplus then begin
                                    TrkgReservEntryArray[3]."Quantity (Base)" := TrackQty - SplitQty;
                                    TrkgReservEntryArray[1]."Quantity (Base)" := SplitQty;
                                end else begin
                                    TrkgReservEntryArray[1]."Quantity (Base)" := TrackQty - SplitQty;
                                    TrkgReservEntryArray[3]."Quantity (Base)" := SplitQty;
                                end;
                                TrkgReservEntryArray[1].Quantity :=
                                  Round(
                                    TrkgReservEntryArray[1]."Quantity (Base)" / TrkgReservEntryArray[1]."Qty. per Unit of Measure",
                                    UOMMgt.QtyRndPrecision());
                                TrkgReservEntryArray[3].Quantity :=
                                  Round(
                                    TrkgReservEntryArray[3]."Quantity (Base)" / TrkgReservEntryArray[3]."Qty. per Unit of Measure",
                                    UOMMgt.QtyRndPrecision());
                            end else begin
                                FromProfile.TransferToTrackingEntry(TrkgReservEntryArray[1], false);
                                ReqLine.TransferToTrackingEntry(TrkgReservEntryArray[1], true);
                            end;
                            if IsSurplus then begin
                                TrkgReservEntryArray[4] := TrkgReservEntryArray[1];
                                ReqLine.TransferToTrackingEntry(TrkgReservEntryArray[4], true);
                                TrkgReservEntryArray[4]."Shipment Date" := ReqLine."Due Date";
                            end;
                            ToProfile.TransferToTrackingEntry(TrkgReservEntryArray[2], false);
                        end;
                    else
                        FromProfile.TransferToTrackingEntry(TrkgReservEntryArray[1], false);
                        ToProfile.TransferToTrackingEntry(TrkgReservEntryArray[2],
                          (ToProfile."Source Type" = Database::"Planning Component") and
                          (ToProfile."Primary Order Status" > 1)); // Firm Planned, Released Prod.Order
                end;
            end else begin
                ToProfile.TestField(IsSupply, true);
                SplitQty := ToProfile."Remaining Quantity" * ToProfile."Qty. per Unit of Measure" + ToProfile."Untracked Quantity" +
                  FromProfile."Untracked Quantity" - ToProfile."Quantity (Base)";

                if FromProfile."Source Type" = Database::"Planning Component" then begin
                    SplitQty2 := FromProfile."Original Quantity" * FromProfile."Qty. per Unit of Measure";
                    if FromProfile."Untracked Quantity" < SplitQty2 then
                        SplitQty2 := FromProfile."Untracked Quantity";
                    if SplitQty2 > SplitQty then
                        SplitQty2 := SplitQty;
                end;

                if SplitQty2 > 0 then begin
                    ToProfile.TransferToTrackingEntry(TrkgReservEntryArray[5], false);
                    if ToProfile."Action Message" = ToProfile."Action Message"::New then begin
                        ReqLine.TransferToTrackingEntry(TrkgReservEntryArray[5], true);
                        FromProfile.TransferToTrackingEntry(TrkgReservEntryArray[6], false);
                    end else
                        FromProfile.TransferToTrackingEntry(TrkgReservEntryArray[6], true);
                    TrkgReservEntryArray[5]."Quantity (Base)" := SplitQty2;
                    TrkgReservEntryArray[5].Quantity :=
                      Round(
                        TrkgReservEntryArray[5]."Quantity (Base)" / TrkgReservEntryArray[5]."Qty. per Unit of Measure",
                        UOMMgt.QtyRndPrecision());
                    FromProfile."Untracked Quantity" := FromProfile."Untracked Quantity" - SplitQty2;
                    TrackQty := TrackQty - SplitQty2;
                    SplitQty := SplitQty - SplitQty2;
                    PrepareTempTracking(TrkgReservEntryArray[5], TrkgReservEntryArray[6], IsSurplus, IssueActionMessage, Binding);
                end;

                if (ToProfile."Action Message" <> ToProfile."Action Message"::" ") and
                   (SplitQty < TrackQty)
                then begin
                    if (SplitQty > 0) and (SplitQty < TrackQty) then begin
                        SplitState := SplitState::SplitToProfile;
                        ToProfile.TransferToTrackingEntry(TrkgReservEntryArray[2],
                          (FromProfile."Action Message" = FromProfile."Action Message"::Reschedule) or
                          (FromProfile."Action Message" = FromProfile."Action Message"::"Resched. & Chg. Qty."));
                        TrkgReservEntryArray[3] := TrkgReservEntryArray[2];
                        ReqLine.TransferToTrackingEntry(TrkgReservEntryArray[2], true);
                        TrkgReservEntryArray[2]."Quantity (Base)" := TrackQty - SplitQty;
                        TrkgReservEntryArray[3]."Quantity (Base)" := SplitQty;
                        TrkgReservEntryArray[2].Quantity :=
                          Round(
                            TrkgReservEntryArray[2]."Quantity (Base)" / TrkgReservEntryArray[2]."Qty. per Unit of Measure",
                            UOMMgt.QtyRndPrecision());
                        TrkgReservEntryArray[3].Quantity :=
                          Round(
                            TrkgReservEntryArray[3]."Quantity (Base)" / TrkgReservEntryArray[3]."Qty. per Unit of Measure",
                            UOMMgt.QtyRndPrecision());
                    end else begin
                        ToProfile.TransferToTrackingEntry(TrkgReservEntryArray[2], false);
                        ReqLine.TransferToTrackingEntry(TrkgReservEntryArray[2], true);
                    end;
                end else
                    ToProfile.TransferToTrackingEntry(TrkgReservEntryArray[2], false);
                FromProfile.TransferToTrackingEntry(TrkgReservEntryArray[1], false);
            end;
        end;

        OnTrackBeforePrepareTempTracking(TrkgReservEntryArray, SplitState, IsSurplus, IssueActionMessage, Binding);
        case SplitState of
            SplitState::NoSplit:
                PrepareTempTracking(TrkgReservEntryArray[1], TrkgReservEntryArray[2], IsSurplus, IssueActionMessage, Binding);
            SplitState::SplitFromProfile:
                if IsSurplus then begin
                    PrepareTempTracking(TrkgReservEntryArray[1], TrkgReservEntryArray[4], false, IssueActionMessage, Binding);
                    PrepareTempTracking(TrkgReservEntryArray[3], TrkgReservEntryArray[4], true, IssueActionMessage, Binding);
                end else begin
                    TrkgReservEntryArray[4] := TrkgReservEntryArray[2];
                    PrepareTempTracking(TrkgReservEntryArray[1], TrkgReservEntryArray[2], IsSurplus, IssueActionMessage, Binding);
                    PrepareTempTracking(TrkgReservEntryArray[3], TrkgReservEntryArray[4], IsSurplus, IssueActionMessage, Binding);
                end;
            SplitState::SplitToProfile:
                begin
                    TrkgReservEntryArray[4] := TrkgReservEntryArray[1];
                    PrepareTempTracking(TrkgReservEntryArray[2], TrkgReservEntryArray[1], IsSurplus, IssueActionMessage, Binding);
                    PrepareTempTracking(TrkgReservEntryArray[3], TrkgReservEntryArray[4], IsSurplus, IssueActionMessage, Binding);
                end;
            SplitState::Cancel:
                PrepareTempTracking(TrkgReservEntryArray[1], TrkgReservEntryArray[3], IsSurplus, IssueActionMessage, Binding);
        end;
        OnAfterTrack(FromProfile, ToProfile, IsSurplus, IssueActionMessage, Binding);
    end;

    local procedure PrepareTempTracking(var FromTrkgReservEntry: Record "Reservation Entry"; var ToTrkgReservEntry: Record "Reservation Entry"; IsSurplus: Boolean; IssueActionMessage: Boolean; Binding: Enum "Reservation Binding")
    begin
        if not IsSurplus then begin
            ToTrkgReservEntry."Quantity (Base)" := -FromTrkgReservEntry."Quantity (Base)";
            ToTrkgReservEntry.Quantity :=
              Round(ToTrkgReservEntry."Quantity (Base)" / ToTrkgReservEntry."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
        end else
            ToTrkgReservEntry."Suppressed Action Msg." := not IssueActionMessage;

        ToTrkgReservEntry.Positive := ToTrkgReservEntry."Quantity (Base)" > 0;
        FromTrkgReservEntry.Positive := FromTrkgReservEntry."Quantity (Base)" > 0;

        FromTrkgReservEntry.Binding := Binding;
        ToTrkgReservEntry.Binding := Binding;

        OnPrepareTempTrackingOnBeforeInsertTempTracking(FromTrkgReservEntry, ToTrkgReservEntry, IsSurplus);

        if IsSurplus or (ToTrkgReservEntry."Reservation Status" = ToTrkgReservEntry."Reservation Status"::Surplus) then begin
            FromTrkgReservEntry."Reservation Status" := FromTrkgReservEntry."Reservation Status"::Surplus;
            FromTrkgReservEntry."Suppressed Action Msg." := ToTrkgReservEntry."Suppressed Action Msg.";
            InsertTempTracking(FromTrkgReservEntry, ToTrkgReservEntry);
            exit;
        end;

        if FromTrkgReservEntry."Reservation Status" = FromTrkgReservEntry."Reservation Status"::Surplus then begin
            ToTrkgReservEntry."Reservation Status" := ToTrkgReservEntry."Reservation Status"::Surplus;
            ToTrkgReservEntry."Suppressed Action Msg." := FromTrkgReservEntry."Suppressed Action Msg.";
            InsertTempTracking(ToTrkgReservEntry, FromTrkgReservEntry);
            exit;
        end;

        InsertTempTracking(FromTrkgReservEntry, ToTrkgReservEntry);
    end;

    local procedure InsertTempTracking(var FromTrkgReservEntry: Record "Reservation Entry"; var ToTrkgReservEntry: Record "Reservation Entry")
    var
        NextEntryNo: Integer;
        ShouldInsert: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertTempTracking(FromTrkgReservEntry, ToTrkgReservEntry, IsHandled);
        if IsHandled then
            exit;

        if FromTrkgReservEntry."Quantity (Base)" = 0 then
            exit;
        NextEntryNo := TempTrkgReservEntry."Entry No." + 1;

        if FromTrkgReservEntry."Reservation Status" = FromTrkgReservEntry."Reservation Status"::Surplus then begin
            TempTrkgReservEntry := FromTrkgReservEntry;
            TempTrkgReservEntry."Entry No." := NextEntryNo;
            SetQtyToHandle(TempTrkgReservEntry);
            TempTrkgReservEntry.Insert();
        end else begin
            MatchReservationEntries(FromTrkgReservEntry, ToTrkgReservEntry);
            if FromTrkgReservEntry.Positive then begin
                FromTrkgReservEntry."Shipment Date" := ToTrkgReservEntry."Shipment Date";
                if ToTrkgReservEntry."Source Type" = Database::"Item Ledger Entry" then
                    ToTrkgReservEntry."Shipment Date" := DMY2Date(31, 12, 9999);
                ToTrkgReservEntry."Expected Receipt Date" := FromTrkgReservEntry."Expected Receipt Date";
            end else begin
                ToTrkgReservEntry."Shipment Date" := FromTrkgReservEntry."Shipment Date";
                if FromTrkgReservEntry."Source Type" = Database::"Item Ledger Entry" then
                    FromTrkgReservEntry."Shipment Date" := DMY2Date(31, 12, 9999);
                FromTrkgReservEntry."Expected Receipt Date" := ToTrkgReservEntry."Expected Receipt Date";
            end;

            if FromTrkgReservEntry.Positive then
                ShouldInsert := ShouldInsertTrackingEntry(FromTrkgReservEntry)
            else
                ShouldInsert := ShouldInsertTrackingEntry(ToTrkgReservEntry);

            if ShouldInsert then begin
                TempTrkgReservEntry := FromTrkgReservEntry;
                TempTrkgReservEntry."Entry No." := NextEntryNo;
                SetQtyToHandle(TempTrkgReservEntry);
                TempTrkgReservEntry.Insert();

                TempTrkgReservEntry := ToTrkgReservEntry;
                TempTrkgReservEntry."Entry No." := NextEntryNo;
                SetQtyToHandle(TempTrkgReservEntry);
                TempTrkgReservEntry.Insert();
            end;
        end;
    end;

    local procedure SetQtyToHandle(var TrkgReservEntry: Record "Reservation Entry")
    var
        WarehouseAvailabilityMgt: Codeunit "Warehouse Availability Mgt.";
        TypeHelper: Codeunit "Type Helper";
        PickedQty: Decimal;
    begin
        if not TrkgReservEntry.TrackingExists() then
            exit;

        TrkgReservEntry."Qty. to Handle (Base)" := TrkgReservEntry."Quantity (Base)";
        TrkgReservEntry."Qty. to Invoice (Base)" := TrkgReservEntry."Quantity (Base)";

        PickedQty := WarehouseAvailabilityMgt.CalcQtyRegisteredPick(TrkgReservEntry);
        if PickedQty > 0 then begin
            TrkgReservEntry."Qty. to Handle (Base)" := TypeHelper.Maximum(-PickedQty, TrkgReservEntry."Quantity (Base)");
            TrkgReservEntry."Qty. to Invoice (Base)" := TrkgReservEntry."Qty. to Handle (Base)";
        end;

        OnAfterSetQtyToHandle(TrkgReservEntry);
    end;

    local procedure CommitTracking()
    var
        PrevTempEntryNo: Integer;
        PrevInsertedEntryNo: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCommitTracking(TempTrkgReservEntry, IsHandled);
        if not IsHandled then begin
            if not TempTrkgReservEntry.Find('-') then
                exit;

            repeat
                ReservEntry := TempTrkgReservEntry;
                if TempTrkgReservEntry."Entry No." = PrevTempEntryNo then
                    ReservEntry."Entry No." := PrevInsertedEntryNo
                else
                    ReservEntry."Entry No." := 0;
                ReservEntry.UpdateItemTracking();
                UpdateAppliedItemEntry(ReservEntry);
                ReservEntry.Insert();
                OnCommitTrackingOnAfterInsertReservationEntry(ReservEntry);
                PrevTempEntryNo := TempTrkgReservEntry."Entry No.";
                PrevInsertedEntryNo := ReservEntry."Entry No.";
                TempTrkgReservEntry.Delete();
            until TempTrkgReservEntry.Next() = 0;
            Clear(TempTrkgReservEntry);
        end;

        OnAfterCommitTracking(TempItemTrkgEntry);
    end;

    procedure MaintainPlanningLine(var SupplyInvtProfile: Record "Inventory Profile"; DemandInvtProfile: Record "Inventory Profile"; NewPhase: Option " ","Line Created","Routing Created",Exploded,Obsolete; Direction: Option Forward,Backward)
    var
        PurchaseLine: Record "Purchase Line";
        TransLine: Record "Transfer Line";
        CurrentSupplyInvtProfile: Record "Inventory Profile";
        PlanLineNo: Integer;
        RecalculationRequired: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeMaintainPlanningLine(SupplyInvtProfile, DemandInvtProfile, NewPhase, Direction, TempTrkgReservEntry, IsHandled);
        if IsHandled then
            exit;

        if (NewPhase = NewPhase::"Line Created") or
           (SupplyInvtProfile."Planning Line Phase" < SupplyInvtProfile."Planning Line Phase"::"Line Created")
        then
            if SupplyInvtProfile."Planning Line No." = 0 then begin
                ReqLine.BlockDynamicTracking(true);
                if ReqLine.FindLast() then
                    PlanLineNo := ReqLine."Line No." + 10000
                else
                    PlanLineNo := 10000;

                OnMaintainPlanningLineOnAfterCalcPlanLineNo(ReqLine, PlanLineNo);

                ReqLine.Init();
                ReqLine."Worksheet Template Name" := CurrTemplateName;
                ReqLine."Journal Batch Name" := CurrWorksheetName;
                ReqLine."Line No." := PlanLineNo;
                ReqLine.Type := ReqLine.Type::Item;
                ReqLine."No." := SupplyInvtProfile."Item No.";
                ReqLine."Variant Code" := SupplyInvtProfile."Variant Code";
                ReqLine."Location Code" := SupplyInvtProfile."Location Code";
                ReqLine."Bin Code" := SupplyInvtProfile."Bin Code";
                ReqLine."Planning Line Origin" := ReqLine."Planning Line Origin"::Planning;
                SetPriceCalculationMethod(ReqLine);
                OnMaintainPlanningLineOnAfterPopulateReqLineFields(ReqLine, SupplyInvtProfile, DemandInvtProfile, NewPhase, Direction, TempSKU, CurrTemplateName, CurrWorksheetName);
                if SupplyInvtProfile."Action Message" = SupplyInvtProfile."Action Message"::New then begin
                    ReqLine."Order Date" := SupplyInvtProfile."Due Date";
                    ReqLine."Planning Level" := SupplyInvtProfile."Planning Level Code";
                    case TempSKU."Replenishment System" of
                        TempSKU."Replenishment System"::Purchase:
                            ReqLine."Ref. Order Type" := ReqLine."Ref. Order Type"::Purchase;
                        TempSKU."Replenishment System"::Transfer:
                            ReqLine."Ref. Order Type" := ReqLine."Ref. Order Type"::Transfer;
                    end;
                    OnMaintainPlanningLineOnBeforeValidateNo(ReqLine, SupplyInvtProfile, TempSKU);
                    ReqLine.Validate(ReqLine."No.");
                    ValidateUOMFromInventoryProfile(ReqLine, SupplyInvtProfile);
                    OnMaintainPlanningLineOnAfterValidateFieldsForNewReqLine(ReqLine, SupplyInvtProfile, TempSKU);
                end else
                    case SupplyInvtProfile."Source Type" of
                        Database::"Purchase Line":
                            SetPurchase(PurchaseLine, SupplyInvtProfile);
                        Database::"Transfer Line":
                            SetTransfer(TransLine, SupplyInvtProfile);
                        else
                            OnMaintainPlanningLineOnAfterSetSourceForNotNewReqLine(ReqLine, SupplyInvtProfile);
                    end;

                if ReqLine."Ref. Order Type" <> ReqLine."Ref. Order Type"::"Prod. Order" then
                    ReqLine."Low-Level Code" := 0;

                OnMaintainPlanningLineOnBeforeAdjustPlanLine(ReqLine, SupplyInvtProfile, TempSKU);
                AdjustPlanLine(SupplyInvtProfile);
                ReqLine."Accept Action Message" := true;
                ReqLine."Routing Reference No." := ReqLine."Line No.";
                ReqLine.UpdateDatetime();
                ReqLine."MPS Order" := SupplyInvtProfile."MPS Order";

                if TempSKU."Plan Minimal Supply" then begin
                    DummyInventoryProfileTrackBuffer."Warning Level" := DummyInventoryProfileTrackBuffer."Warning Level"::Attention;
                    if TempSKU."Location Code" = '' then
                        PlanningTransparency.LogWarning(
                          0, ReqLine, DummyInventoryProfileTrackBuffer."Warning Level",
                          StrSubstNo(MinimalSupplyPlannedTxt, DummyInventoryProfileTrackBuffer."Warning Level", LocationMandatoryTxt))
                    else
                        PlanningTransparency.LogWarning(
                           0, ReqLine, DummyInventoryProfileTrackBuffer."Warning Level",
                           StrSubstNo(MinimalSupplyPlannedTxt, DummyInventoryProfileTrackBuffer."Warning Level", MissingStockkeepingUnitTxt));
                end;

                OnMaintainPlanningLineOnBeforeReqLineInsert(
                  ReqLine, SupplyInvtProfile, PlanToDate, CurrForecast, NewPhase, Direction, DemandInvtProfile, ExcludeForecastBefore);
                ReqLine.Insert();
                OnMaintainPlanningLineOnAfterReqLineInsert(ReqLine);
                SupplyInvtProfile."Planning Line No." := ReqLine."Line No.";
                if NewPhase = NewPhase::"Line Created" then
                    SupplyInvtProfile."Planning Line Phase" := SupplyInvtProfile."Planning Line Phase"::"Line Created";
            end else begin
                if SupplyInvtProfile."Planning Line No." <> ReqLine."Line No." then
                    ReqLine.Get(CurrTemplateName, CurrWorksheetName, SupplyInvtProfile."Planning Line No.");
                ReqLine.BlockDynamicTracking(true);
                AdjustPlanLine(SupplyInvtProfile);
                OnMaintainPlanLineOnAfterAdjustPlanLine(
                    TempSKU, ReqLine, SupplyInvtProfile, DemandInvtProfile, PlanToDate, CurrForecast, NewPhase, Direction);
                if NewPhase = NewPhase::"Line Created" then
                    ReqLine.Modify();
            end;

        OnMaintainPlanningLineOnAfterLineCreated(SupplyInvtProfile, ReqLine);

        if (NewPhase = NewPhase::"Routing Created") or
           ((NewPhase > NewPhase::"Routing Created") and
            (SupplyInvtProfile."Planning Line Phase" < SupplyInvtProfile."Planning Line Phase"::"Routing Created"))
        then begin
            ReqLine.BlockDynamicTracking(true);
            if SupplyInvtProfile."Planning Line No." <> ReqLine."Line No." then
                ReqLine.Get(CurrTemplateName, CurrWorksheetName, SupplyInvtProfile."Planning Line No.");
            AdjustPlanLine(SupplyInvtProfile);
            if ReqLine.Quantity > 0 then begin
                if SupplyInvtProfile."Starting Date" <> 0D then
                    ReqLine."Starting Date" := SupplyInvtProfile."Starting Date"
                else
                    ReqLine."Starting Date" := SupplyInvtProfile."Due Date";
                GetRouting(ReqLine);
                RecalculationRequired := true;
                if NewPhase = NewPhase::"Routing Created" then
                    SupplyInvtProfile."Planning Line Phase" := SupplyInvtProfile."Planning Line Phase"::"Routing Created";
            end;
            OnMaintainPlanningLineOnBeforeReqLineModify(ReqLine, SupplyInvtProfile);
            ReqLine.Modify();
        end;

        if NewPhase = NewPhase::Exploded then begin
            if SupplyInvtProfile."Planning Line No." <> ReqLine."Line No." then
                ReqLine.Get(CurrTemplateName, CurrWorksheetName, SupplyInvtProfile."Planning Line No.");
            ReqLine.BlockDynamicTracking(true);
            AdjustPlanLine(SupplyInvtProfile);
            if ReqLine.Quantity = 0 then
                if ReqLine."Action Message" = ReqLine."Action Message"::New then begin
                    ReqLine.BlockDynamicTracking(true);
                    ReqLine.Delete(true);

                    RecalculationRequired := false;
                end else
                    DisableRelations(ReqLine)
            else begin
                GetComponents(ReqLine);
                RecalculationRequired := true;
            end;

            if (ReqLine."Ref. Order Type" = ReqLine."Ref. Order Type"::Transfer) and
               not ((ReqLine.Quantity = 0) and (ReqLine."Action Message" = ReqLine."Action Message"::New))
            then begin
                AdjustTransferDates(ReqLine);
                if ReqLine."Action Message" = ReqLine."Action Message"::New then begin
                    CurrentSupplyInvtProfile.Copy(SupplyInvtProfile);

                    SupplyInvtProfile.Reset();
                    SupplyInvtProfile.SetSourceFilter(
                      Database::"Requisition Line", 1, ReqLine."Worksheet Template Name", ReqLine."Line No.", ReqLine."Journal Batch Name", 0);
                    SupplyInvtProfile.SetTrackingFilter(CurrentSupplyInvtProfile);
                    if not SupplyInvtProfile.FindFirst() then begin
                        SupplyInvtProfile.Init();
                        SupplyInvtProfile."Line No." := GetNextLineNo();
                        SupplyInvtProfile."Item No." := ReqLine."No.";
                        SupplyInvtProfile.TransferFromOutboundTransfPlan(ReqLine, TempItemTrkgEntry);
                        SupplyInvtProfile.CopyTrackingFromInvtProfile(CurrentSupplyInvtProfile);
                        if SupplyInvtProfile.IsSupply then
                            SupplyInvtProfile.ChangeSign();
                        OnMaintainPlanningLineOnBeforeSupplyInvtProfileInsert(SupplyInvtProfile, CurrentSupplyInvtProfile);
                        SupplyInvtProfile.Insert();
                    end else begin
                        SupplyInvtProfile.TransferFromOutboundTransfPlan(ReqLine, TempItemTrkgEntry);
                        SupplyInvtProfile.Modify();
                    end;

                    SupplyInvtProfile.Copy(CurrentSupplyInvtProfile);
                end else
                    SynchronizeTransferProfiles(SupplyInvtProfile, ReqLine);
            end;
        end;

        if RecalculationRequired then begin
            Recalculate(
              ReqLine, Direction,
              ((SupplyInvtProfile."Planning Line Phase" < SupplyInvtProfile."Planning Line Phase"::"Routing Created") or
               (ReqLine."Action Message" = ReqLine."Action Message"::New)) and
              (ReqLine."Ref. Order Type" = ReqLine."Ref. Order Type"::"Prod. Order"));
            ReqLine.UpdateDatetime();
            ReqLine.Modify();

            SupplyInvtProfile."Starting Date" := ReqLine."Starting Date";
            SupplyInvtProfile."Due Date" := ReqLine."Due Date";

            OnMaintainPlanningLineOnAfterCopyDatesToInvtProfile(SupplyInvtProfile, ReqLine);
        end;

        if NewPhase = NewPhase::Obsolete then begin
            if SupplyInvtProfile."Planning Line No." <> ReqLine."Line No." then
                ReqLine.Get(CurrTemplateName, CurrWorksheetName, SupplyInvtProfile."Planning Line No.");
            DeletePlanningCompList(ReqLine);
            ReqLine.Delete(true);
            SupplyInvtProfile."Planning Line No." := 0;
            SupplyInvtProfile."Planning Line Phase" := SupplyInvtProfile."Planning Line Phase"::" ";
        end;

        SupplyInvtProfile.Modify();

        OnAfterMaintainPlanningLine(ReqLine, SupplyInvtProfile, NewPhase);
    end;

    local procedure ValidateUOMFromInventoryProfile(var RequisitionLine: Record "Requisition Line"; InventoryProfile: Record "Inventory Profile")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateUOMFromInventoryProfile(RequisitionLine, InventoryProfile, TempSKU, IsHandled);
        if IsHandled then
            exit;

        RequisitionLine.Validate("Unit of Measure Code", InventoryProfile."Unit of Measure Code");
    end;

    procedure AdjustReorderQty(OrderQty: Decimal; SKU: Record "Stockkeeping Unit"; SupplyLineNo: Integer; MinQty: Decimal): Decimal
    var
        DeltaQty: Decimal;
        Rounding: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAdjustReorderQty(OrderQty, SKU, SupplyLineNo, MinQty, DeltaQty, IsHandled);
        if IsHandled then
            exit(DeltaQty);

        // Copy of this procedure exists in COD5400- Available Management
        if OrderQty <= 0 then
            exit(0);

        if (SKU."Maximum Order Quantity" < OrderQty) and
           (SKU."Maximum Order Quantity" <> 0) and
           (SKU."Maximum Order Quantity" > MinQty)
        then begin
            DeltaQty := SKU."Maximum Order Quantity" - OrderQty;
            PlanningTransparency.LogPlanningSurplus(
              SupplyLineNo, 0, Database::Item, TempSKU."Item No.",
              DeltaQty, SurplusType::MaxOrder);
        end else
            DeltaQty := 0;
        if SKU."Minimum Order Quantity" > (OrderQty + DeltaQty) then begin
            DeltaQty := SKU."Minimum Order Quantity" - OrderQty;
            PlanningTransparency.LogPlanningSurplus(
              SupplyLineNo, 0, Database::Item, TempSKU."Item No.",
              SKU."Minimum Order Quantity", SurplusType::MinOrder);
        end;
        if SKU."Order Multiple" <> 0 then begin
            Rounding := Round(OrderQty + DeltaQty, SKU."Order Multiple", '>') - (OrderQty + DeltaQty);
            DeltaQty += Rounding;
            if DeltaQty <> 0 then
                PlanningTransparency.LogPlanningSurplus(
                  SupplyLineNo, 0, Database::Item, TempSKU."Item No.",
                  Rounding, SurplusType::OrderMultiple);
        end;

        OnAfterAdjustReorderQty(OrderQty, SKU, SupplyLineNo, MinQty, DeltaQty);
        exit(DeltaQty);
    end;

    local procedure CalcInventoryProfileRemainingQty(var InventoryProfile: Record "Inventory Profile"; DocumentNo: Code[20]; LineNo: Integer) RemQty: Decimal
    var
        SalesLine: Record "Sales Line";
    begin
        RemQty := 0;

        InventoryProfile.SetRange("Source Type", Database::"Sales Line");
        InventoryProfile.SetRange("Source Order Status", SalesLine."Document Type"::Order);
        InventoryProfile.SetRange("Ref. Blanket Order No.", DocumentNo);
        if InventoryProfile.FindSet() then
            repeat
                SalesLine.SetLoadFields("Blanket Order No.", "Blanket Order Line No.");
                SalesLine.Get(SalesLine."Document Type"::Order, InventoryProfile."Source ID", InventoryProfile."Source Ref. No.");
                if (SalesLine."Blanket Order No." = DocumentNo) and (SalesLine."Blanket Order Line No." = LineNo) then
                    RemQty += InventoryProfile."Remaining Quantity (Base)";
            until InventoryProfile.Next() = 0;
    end;

    procedure CalcReorderQty(NeededQty: Decimal; ProjectedInventory: Decimal; SupplyLineNo: Integer) QtyToOrder: Decimal
    var
        Item: Record Item;
        SKU: Record "Stockkeeping Unit";
        IsHandled: Boolean;
    begin
        // Calculate qty to order:
        // If Max:   QtyToOrder = MaxInv - ProjInvLevel
        // If Fixed: QtyToOrder = FixedReorderQty
        // Copy of this procedure exists in COD5400- Available Management
        case TempSKU."Reordering Policy" of
            TempSKU."Reordering Policy"::"Maximum Qty.":
                begin
                    if TempSKU."Maximum Inventory" <= TempSKU."Reorder Point" then
                        CalcMaximumReorderQty();

                    QtyToOrder := TempSKU."Maximum Inventory" - ProjectedInventory;
                    PlanningTransparency.LogPlanningSurplus(
                      SupplyLineNo, 0, Database::Item, TempSKU."Item No.",
                      QtyToOrder, SurplusType::MaxInventory);
                end;
            TempSKU."Reordering Policy"::"Fixed Reorder Qty.":
                begin
                    if TempSKU."Reorder Quantity" = 0 then
                        if SKU.Get(TempSKU."Location Code", TempSKU."Item No.", TempSKU."Variant Code") then begin
                            if PlanningResiliency then
                                ReqLine.SetResiliencyError(
                                  StrSubstNo(
                                    Text004, SKU.FieldCaption("Reorder Quantity"), 0, SKU.TableCaption(),
                                    SKU."Location Code", SKU."Item No.", SKU."Variant Code",
                                    SKU.FieldCaption("Reordering Policy"), SKU."Reordering Policy"),
                                  Database::"Stockkeeping Unit", SKU.GetPosition());
                            TempSKU.TestField("Reorder Quantity");
                        end else
                            if Item.Get(TempSKU."Item No.") then begin
                                if PlanningResiliency then
                                    ReqLine.SetResiliencyError(
                                      StrSubstNo(
                                        Text005, Item.FieldCaption("Reorder Quantity"), 0, Item.TableCaption(),
                                        Item."No.", Item.FieldCaption("Reordering Policy"), Item."Reordering Policy"),
                                      Database::Item, Item.GetPosition());
                                Item.TestField("Reorder Quantity");
                            end;

                    QtyToOrder := TempSKU."Reorder Quantity";
                    PlanningTransparency.LogPlanningSurplus(
                      SupplyLineNo, 0, Database::Item, TempSKU."Item No.",
                      QtyToOrder, SurplusType::FixedOrderQty);
                end;
            else begin
                IsHandled := false;
                OnCalcReorderQtyOnCaseElse(QtyToOrder, NeededQty, ProjectedInventory, SupplyLineNo, TempSKU, PlanningResiliency, IsHandled);
                if not IsHandled then
                    QtyToOrder := NeededQty;
            end;
        end;
    end;

    procedure CalcMaximumReorderQty()
    var
        Item: Record Item;
        SKU: Record "Stockkeeping Unit";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcMaximumReorderQty(TempSKU, ReqLine, PlanningResiliency, IsHandled);
        if IsHandled then
            exit;

        if PlanningResiliency then
            if SKU.Get(TempSKU."Location Code", TempSKU."Item No.", TempSKU."Variant Code") then
                ReqLine.SetResiliencyError(
                    StrSubstNo(
                    Text004, SKU.FieldCaption("Maximum Inventory"), SKU."Maximum Inventory", SKU.TableCaption(),
                    SKU."Location Code", SKU."Item No.", SKU."Variant Code",
                    SKU.FieldCaption("Reorder Point"), SKU."Reorder Point"),
                    Database::"Stockkeeping Unit", SKU.GetPosition())
            else
                if Item.Get(TempSKU."Item No.") then
                    ReqLine.SetResiliencyError(
                        StrSubstNo(
                        Text005, Item.FieldCaption("Maximum Inventory"), Item."Maximum Inventory", Item.TableCaption(),
                        Item."No.", Item.FieldCaption("Reorder Point"), Item."Reorder Point"),
                        Database::Item, Item.GetPosition());
        TempSKU.TestField("Maximum Inventory", TempSKU."Reorder Point" + 1); // Assertion
    end;

    procedure CalcOrderQty(NeededQty: Decimal; ProjectedInventory: Decimal; SupplyLineNo: Integer) QtyToOrder: Decimal
    begin
        QtyToOrder := CalcReorderQty(NeededQty, ProjectedInventory, SupplyLineNo);
        // Ensure that QtyToOrder is large enough to exceed ROP:
        if QtyToOrder <= (TempSKU."Reorder Point" - ProjectedInventory) then
            QtyToOrder :=
              Round((TempSKU."Reorder Point" - ProjectedInventory) / TempSKU."Reorder Quantity" + 0.000000001, 1, '>') *
              TempSKU."Reorder Quantity";

        OnAfterCalcOrderQty(TempSKU, NeededQty, ProjectedInventory, SupplyLineNo, QtyToOrder);
    end;

    local procedure AdjustPlanLine(var SupplyInventoryProfile: Record "Inventory Profile")
    begin
        OnBeforeAdjustPlanLine(ReqLine, SupplyInventoryProfile);

        ReqLine."Action Message" := SupplyInventoryProfile."Action Message";
        ReqLine.BlockDynamicTracking(true);
        if SupplyInventoryProfile."Action Message" in
           [SupplyInventoryProfile."Action Message"::New,
            SupplyInventoryProfile."Action Message"::"Change Qty.",
            SupplyInventoryProfile."Action Message"::Reschedule,
            SupplyInventoryProfile."Action Message"::"Resched. & Chg. Qty.",
            SupplyInventoryProfile."Action Message"::Cancel]
        then begin
            if SupplyInventoryProfile."Qty. per Unit of Measure" = 0 then
                SupplyInventoryProfile."Qty. per Unit of Measure" := 1;
            UpdateReqLineQuantity(SupplyInventoryProfile);
            UpdateReqLineOriginalQuantity(SupplyInventoryProfile);
            ReqLine."Net Quantity (Base)" :=
              (ReqLine."Remaining Quantity" - ReqLine."Original Quantity") *
              ReqLine."Qty. per Unit of Measure";
            OnAdjustPlanLineAfterValidateQuantity(ReqLine, SupplyInventoryProfile);
        end;
        UpdateOriginalDueDate(SupplyInventoryProfile);
        ReqLine."Due Date" := SupplyInventoryProfile."Due Date";
        if SupplyInventoryProfile."Planning Level Code" = 0 then begin
            ReqLine."Ending Date" :=
              LeadTimeMgt.GetPlannedEndingDate(
                SupplyInventoryProfile."Item No.", SupplyInventoryProfile."Location Code", SupplyInventoryProfile."Variant Code", SupplyInventoryProfile."Due Date", '', ReqLine."Ref. Order Type");
            InventorySetup.GetRecordOnce();
            if not IsSKUSetUpForReorderPointPlanning(TempSKU) then
                if CalcDate(TempSKU."Safety Lead Time", ReqLine."Ending Date") = ReqLine."Ending Date" then
                    if CalcDate(InventorySetup."Default Safety Lead Time", ReqLine."Ending Date") = ReqLine."Ending Date" then
                        ReqLine."Ending Time" := SupplyInventoryProfile."Due Time";
        end else begin
            ReqLine."Ending Date" := SupplyInventoryProfile."Due Date";
            ReqLine."Ending Time" := SupplyInventoryProfile."Due Time";
        end;
        if (ReqLine."Starting Date" = 0D) or
           (ReqLine."Starting Date" > ReqLine."Ending Date")
        then
            ReqLine."Starting Date" := ReqLine."Ending Date";
        if (ReqLine."Starting Date" = ReqLine."Ending Date") and
           (ReqLine."Ending Time" < ReqLine."Starting Time")
        then
            ReqLine."Ending Time" := ReqLine."Starting Time";

        OnAfterAdjustPlanLine(ReqLine, SupplyInventoryProfile);
    end;

    local procedure UpdateOriginalDueDate(var SupplyInventoryProfile: Record "Inventory Profile")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateOriginalDueDate(SupplyInventoryProfile, IsHandled);
        if not IsHandled then
            ReqLine."Original Due Date" := SupplyInventoryProfile."Original Due Date";
    end;

    local procedure UpdateReqLineQuantity(var SupplyInventoryProfile: Record "Inventory Profile")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateReqLineQuantity(ReqLine, SupplyInventoryProfile, IsHandled);
        if IsHandled then
            exit;

        ReqLine.Validate(
            Quantity,
            Round(SupplyInventoryProfile."Remaining Quantity (Base)" / SupplyInventoryProfile."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision()));
    end;

    local procedure UpdateReqLineOriginalQuantity(var SupplyInventoryProfile: Record "Inventory Profile")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateReqLineOriginalQuantity(ReqLine, SupplyInventoryProfile, IsHandled, TempSKU);
        if IsHandled then
            exit;

        ReqLine."Original Quantity" := SupplyInventoryProfile."Original Quantity";
    end;

    procedure DisableRelations(var ReqLine2: Record "Requisition Line")
    var
        PlanningComponent: Record "Planning Component";
    begin
        if ReqLine2.Type <> ReqLine2.Type::Item then
            exit;

        PlanningComponent.SetRange("Worksheet Template Name", ReqLine2."Worksheet Template Name");
        PlanningComponent.SetRange("Worksheet Batch Name", ReqLine2."Journal Batch Name");
        PlanningComponent.SetRange("Worksheet Line No.", ReqLine2."Line No.");
        if PlanningComponent.Find('-') then
            repeat
                PlanningComponent.BlockDynamicTracking(false);
                PlanningComponent.Delete(true);
            until PlanningComponent.Next() = 0;

        OnAfterDisableRelations(ReqLine2);
    end;

    local procedure SynchronizeTransferProfiles(var InventoryProfile: Record "Inventory Profile"; var TransferReqLine: Record "Requisition Line")
    var
        SupplyInvtProfile: Record "Inventory Profile";
    begin
        if InventoryProfile."Transfer Location Not Planned" then
            exit;
        SupplyInvtProfile.Copy(InventoryProfile);
        if GetTransferSisterProfile(SupplyInvtProfile, InventoryProfile) then begin
            TransferReqLineToInvProfiles(InventoryProfile, TransferReqLine);
            InventoryProfile.Modify();
        end;
        InventoryProfile.Copy(SupplyInvtProfile);
    end;

    procedure TransferReqLineToInvProfiles(var InventoryProfile: Record "Inventory Profile"; var TransferReqLine: Record "Requisition Line")
    begin
        InventoryProfile.TestField("Location Code", TransferReqLine."Transfer-from Code");

        InventoryProfile."Min. Quantity" := InventoryProfile."Remaining Quantity (Base)";
        InventoryProfile."Original Quantity" := TransferReqLine."Original Quantity";
        InventoryProfile.Quantity := TransferReqLine.Quantity;
        InventoryProfile."Remaining Quantity" := TransferReqLine.Quantity;
        InventoryProfile."Quantity (Base)" := TransferReqLine."Quantity (Base)";
        InventoryProfile."Remaining Quantity (Base)" := TransferReqLine."Quantity (Base)";
        InventoryProfile."Untracked Quantity" := TransferReqLine."Quantity (Base)";
        InventoryProfile."Unit of Measure Code" := TransferReqLine."Unit of Measure Code";
        InventoryProfile."Qty. per Unit of Measure" := TransferReqLine."Qty. per Unit of Measure";
        InventoryProfile."Due Date" := TransferReqLine."Transfer Shipment Date";
    end;

    local procedure SyncTransferDemandWithReqLine(var InventoryProfile: Record "Inventory Profile"; LocationCode: Code[10])
    var
        TransferReqLine: Record "Requisition Line";
    begin
        TransferReqLine.SetRange("Ref. Order Type", TransferReqLine."Ref. Order Type"::Transfer);
        TransferReqLine.SetRange("Ref. Order No.", InventoryProfile."Source ID");
        TransferReqLine.SetRange("Ref. Line No.", InventoryProfile."Source Ref. No.");
        TransferReqLine.SetRange("Transfer-from Code", InventoryProfile."Location Code");
        TransferReqLine.SetRange("Location Code", LocationCode);
        TransferReqLine.SetFilter("Action Message", '<>%1', TransferReqLine."Action Message"::New);
        OnSyncTransferDemandWithReqLineOnAfterSetFilters(TransferReqLine, InventoryProfile, LocationCode, CurrTemplateName, CurrWorksheetName);
        if TransferReqLine.FindFirst() then
            TransferReqLineToInvProfiles(InventoryProfile, TransferReqLine);
    end;

    local procedure GetTransferSisterProfile(CurrInvProfile: Record "Inventory Profile"; var SisterInvProfile: Record "Inventory Profile") InvtProfileFound: Boolean
    begin
        // Finds the invprofile which represents the opposite side of a transfer order.
        if (CurrInvProfile."Source Type" <> Database::"Transfer Line") or
           (CurrInvProfile."Action Message" = CurrInvProfile."Action Message"::New)
        then
            exit(false);

        SetFiltersForSisterInventoryProfile(CurrInvProfile, SisterInvProfile);

        InvtProfileFound := SisterInvProfile.Find('-');
        if InvtProfileFound then
            if SisterInvProfile.Next() <> 0 then
                Error(Text001, SisterInvProfile.TableCaption());

        exit;
    end;

    local procedure SetFiltersForSisterInventoryProfile(CurrInvProfile: Record "Inventory Profile"; var SisterInvProfile: Record "Inventory Profile")
    begin
        SisterInvProfile.Reset();
        SisterInvProfile.SetRange("Source Type", Database::"Transfer Line");
        SisterInvProfile.SetRange("Source ID", CurrInvProfile."Source ID");
        SisterInvProfile.SetRange("Source Ref. No.", CurrInvProfile."Source Ref. No.");
        SisterInvProfile.SetTrackingFilterFromInvtProfile(CurrInvProfile);
        SisterInvProfile.SetRange(IsSupply, not CurrInvProfile.IsSupply);

        OnAfterSetFiltersForSisterInventoryProfile(CurrInvProfile, SisterInvProfile);
    end;

    local procedure AdjustTransferDates(var TransferReqLine: Record "Requisition Line")
    var
        TransferRoute: Record "Transfer Route";
        ShippingAgentServices: Record "Shipping Agent Services";
        Location: Record Location;
        SKU: Record "Stockkeeping Unit";
        ShippingTime: DateFormula;
        OutboundWhseTime: DateFormula;
        InboundWhseTime: DateFormula;
        OK: Boolean;
        IsHandled: Boolean;
    begin
        // Used for planning lines handling transfer orders.
        // "Ending Date", Starting Date and "Transfer Shipment Date" are calculated backwards from "Due Date".
        IsHandled := false;
        OnBeforeAdjustTransferDates(TransferReqLine, IsHandled);
        if IsHandled then
            exit;

        TransferReqLine.TestField("Ref. Order Type", TransferReqLine."Ref. Order Type"::Transfer);
        OK := Location.Get(TransferReqLine."Transfer-from Code");
        if PlanningResiliency and not OK then
            if SKU.Get(TransferReqLine."Location Code", TransferReqLine."No.", TransferReqLine."Variant Code") then
                ReqLine.SetResiliencyError(
                  StrSubstNo(
                    Text003, SKU.FieldCaption("Transfer-from Code"), SKU.TableCaption(),
                    SKU."Location Code", SKU."Item No.", SKU."Variant Code"),
                  Database::"Stockkeeping Unit", SKU.GetPosition());
        if not OK then
            Location.Get(TransferReqLine."Transfer-from Code");
        OutboundWhseTime := Location."Outbound Whse. Handling Time";

        Location.Get(TransferReqLine."Location Code");
        InboundWhseTime := Location."Inbound Whse. Handling Time";
        OnAdjustTransferDatesOnAfterInboundWhseTimeSet(TransferReqLine, Location, InboundWhseTime);

        OK := TransferRoute.Get(TransferReqLine."Transfer-from Code", TransferReqLine."Location Code");
        if PlanningResiliency and not OK then
            ReqLine.SetResiliencyError(
              StrSubstNo(
                Text002, TransferRoute.TableCaption(),
                TransferReqLine."Transfer-from Code", TransferReqLine."Location Code"),
              Database::"Transfer Route", '');
        if not OK then
            TransferRoute.Get(TransferReqLine."Transfer-from Code", TransferReqLine."Location Code");

        if ShippingAgentServices.Get(TransferRoute."Shipping Agent Code", TransferRoute."Shipping Agent Service Code") then
            ShippingTime := ShippingAgentServices."Shipping Time"
        else
            Evaluate(ShippingTime, '');

        // The calculation will run through the following steps:
        // ShipmentDate <- PlannedShipmentDate <- PlannedReceiptDate <- ReceiptDate
        // Calc Planned Receipt Date (Ending Date) backward from ReceiptDate
        TransferRoute.CalcPlanReceiptDateBackward(
          TransferReqLine."Ending Date", TransferReqLine."Due Date", InboundWhseTime,
          TransferReqLine."Location Code", TransferRoute."Shipping Agent Code", TransferRoute."Shipping Agent Service Code");

        // Calc Planned Shipment Date (Starting Date) backward from Planned ReceiptDate (Ending Date)
        TransferRoute.CalcPlanShipmentDateBackward(
          TransferReqLine."Starting Date", TransferReqLine."Ending Date", ShippingTime,
          TransferReqLine."Transfer-from Code", TransferRoute."Shipping Agent Code", TransferRoute."Shipping Agent Service Code");

        // Calc Shipment Date backward from Planned Shipment Date (Starting Date)
        TransferRoute.CalcShipmentDateBackward(
          TransferReqLine."Transfer Shipment Date", TransferReqLine."Starting Date", OutboundWhseTime, TransferReqLine."Transfer-from Code");

        TransferReqLine.UpdateDatetime();
        OnAdjustTransferDatesOnBeforeTransferReqLineModify(TransferReqLine);
        TransferReqLine.Modify();
    end;

    local procedure InsertTempTransferSKU(var TransLine: Record "Transfer Line")
    var
        SKU: Record "Stockkeeping Unit";
    begin
        TempTransferSKU.Init();
        TempTransferSKU."Item No." := TransLine."Item No.";
        TempTransferSKU."Variant Code" := TransLine."Variant Code";
        if TransLine.Quantity > 0 then
            TempTransferSKU."Location Code" := TransLine."Transfer-to Code"
        else
            TempTransferSKU."Location Code" := TransLine."Transfer-from Code";
        if SKU.Get(TempTransferSKU."Location Code", TempTransferSKU."Item No.", TempTransferSKU."Variant Code") then
            TempTransferSKU."Transfer-from Code" := SKU."Transfer-from Code"
        else
            TempTransferSKU."Transfer-from Code" := '';

        OnBeforeTempTransferSKUInsert(TempTransferSKU, TransLine);
        if TempTransferSKU.Insert() then;
    end;

    local procedure UpdateTempSKUTransferLevels()
    var
        SKU: Record "Stockkeeping Unit";
    begin
        SKU.Copy(TempSKU);
        TempTransferSKU.Reset();
        if TempTransferSKU.Find('-') then
            repeat
                TempSKU.Reset();
                if TempSKU.Get(TempTransferSKU."Location Code", TempTransferSKU."Item No.", TempTransferSKU."Variant Code") then
                    if TempSKU."Transfer-from Code" = '' then begin
                        TempSKU.SetRange("Location Code", TempTransferSKU."Transfer-from Code");
                        TempSKU.SetRange("Item No.", TempTransferSKU."Item No.");
                        TempSKU.SetRange("Variant Code", TempTransferSKU."Variant Code");
                        if not TempSKU.Find('-') then
                            TempTransferSKU."Transfer-Level Code" := -1
                        else
                            TempTransferSKU."Transfer-Level Code" := TempSKU."Transfer-Level Code" - 1;
                        TempSKU.Get(TempTransferSKU."Location Code", TempTransferSKU."Item No.", TempTransferSKU."Variant Code");
                        TempSKU."Transfer-from Code" := TempTransferSKU."Transfer-from Code";
                        TempSKU."Transfer-Level Code" := TempTransferSKU."Transfer-Level Code";
                        TempSKU.Modify();
                        TempSKU.UpdateTempSKUTransferLevels(TempSKU, TempSKU, TempSKU."Transfer-from Code");
                    end;
            until TempTransferSKU.Next() = 0;
        TempSKU.Copy(SKU);
    end;

    local procedure CancelTransfer(var SupplyInvtProfile: Record "Inventory Profile"; var DemandInvtProfile: Record "Inventory Profile"; DemandExists: Boolean) Cancel: Boolean
    var
        xSupply2: Record "Inventory Profile";
    begin
        // Used to handle transfers where supply is planned with a higher Transfer Level Code than DemandInvtProfile.
        // If you encounter the demand before the SupplyInvtProfile, the supply must be removed.

        if not DemandExists then
            exit(false);
        if DemandInvtProfile."Source Type" <> Database::"Transfer Line" then
            exit(false);

        DemandInvtProfile.TestField(IsSupply, false);

        xSupply2.Copy(SupplyInvtProfile);
        if GetTransferSisterProfile(DemandInvtProfile, SupplyInvtProfile) then begin
            if SupplyInvtProfile."Action Message" = SupplyInvtProfile."Action Message"::New then
                SupplyInvtProfile.FieldError("Action Message");

            if SupplyInvtProfile."Planning Flexibility" = SupplyInvtProfile."Planning Flexibility"::Unlimited then begin
                SupplyInvtProfile."Original Quantity" := SupplyInvtProfile.Quantity;
                SupplyInvtProfile."Max. Quantity" := SupplyInvtProfile."Remaining Quantity (Base)";
                SupplyInvtProfile."Quantity (Base)" := SupplyInvtProfile."Min. Quantity";
                SupplyInvtProfile."Remaining Quantity (Base)" := SupplyInvtProfile."Min. Quantity";
                SupplyInvtProfile."Untracked Quantity" := 0;

                if SupplyInvtProfile."Remaining Quantity (Base)" = 0 then
                    SupplyInvtProfile."Action Message" := SupplyInvtProfile."Action Message"::Cancel
                else
                    SupplyInvtProfile."Action Message" := SupplyInvtProfile."Action Message"::"Change Qty.";
                SupplyInvtProfile.Modify();

                MaintainPlanningLine(SupplyInvtProfile, DemandInvtProfile, PlanningLineStage::Exploded, ScheduleDirection::Backward);
                Track(SupplyInvtProfile, DemandInvtProfile, true, false, SupplyInvtProfile.Binding::" ");
                SupplyInvtProfile.Delete();

                Cancel := (SupplyInvtProfile."Action Message" = SupplyInvtProfile."Action Message"::Cancel);

                // IF supply is fully cancelled, demand is deleted, otherwise demand is modified:
                if Cancel then
                    DemandInvtProfile.Delete()
                else begin
                    DemandInvtProfile.Get(DemandInvtProfile."Line No."); // Get the updated version
                    DemandInvtProfile."Untracked Quantity" -= (DemandInvtProfile."Original Quantity" - DemandInvtProfile."Quantity (Base)");
                    DemandInvtProfile.Modify();
                end;
            end;
        end;
        SupplyInvtProfile.Copy(xSupply2);
    end;

    local procedure PostInvChgReminder(var TempReminderInvtProfile: Record "Inventory Profile" temporary; var InvProfile: Record "Inventory Profile"; PostOnlyMinimum: Boolean)
    begin
        // Update information on changes in the Projected Inventory over time
        // Only the quantity that is known for sure should be posted

        OnBeforePostInvChgReminder(TempReminderInvtProfile, InvProfile, PostOnlyMinimum);
        TempReminderInvtProfile := InvProfile;

        if PostOnlyMinimum then begin
            TempReminderInvtProfile."Remaining Quantity (Base)" -= InvProfile."Untracked Quantity";
            TempReminderInvtProfile."Remaining Quantity (Base)" += InvProfile."Safety Stock Quantity";
        end;

        if not TempReminderInvtProfile.Insert() then
            TempReminderInvtProfile.Modify();
        OnAfterPostInvChgReminder(TempReminderInvtProfile, InvProfile, PostOnlyMinimum);
    end;

    local procedure QtyFromPendingReminders(var TempReminderInvtProfile: Record "Inventory Profile" temporary; AtDate: Date; LatestBucketStartDate: Date) PendingQty: Decimal
    var
        xReminderInvtProfile: Record "Inventory Profile";
    begin
        // Calculates the sum of queued up adjustments to the projected inventory level
        xReminderInvtProfile.Copy(TempReminderInvtProfile);

        FilterDemandSupplyRelatedToSKU(TempReminderInvtProfile);
        TempReminderInvtProfile.SetRange("Due Date", LatestBucketStartDate, AtDate);
        if TempReminderInvtProfile.FindSet() then
            repeat
                if TempReminderInvtProfile.IsSupply then
                    PendingQty += TempReminderInvtProfile."Remaining Quantity (Base)"
                else
                    PendingQty -= TempReminderInvtProfile."Remaining Quantity (Base)";
            until TempReminderInvtProfile.Next() = 0;

        TempReminderInvtProfile.Copy(xReminderInvtProfile);
    end;

    local procedure MaintainProjectedInventory(var TempReminderInvtProfile: Record "Inventory Profile" temporary; AtDate: Date; var LastProjectedInventory: Decimal; var LatestBucketStartDate: Date; var ROPHasBeenCrossed: Boolean)
    var
        NextBucketEndDate: Date;
        NewProjectedInv: Decimal;
        SupplyIncrementQty: Decimal;
        DemandIncrementQty: Decimal;
        IsHandled: Boolean;
    begin
        // Updates information about projected inventory up until AtDate or until reorder point is crossed.
        // The check is performed within time buckets.
        IsHandled := false;
        OnBeforeMaintainProjectedInventory(
          TempReminderInvtProfile, AtDate, LastProjectedInventory, LatestBucketStartDate, ROPHasBeenCrossed, IsHandled);
        if IsHandled then
            exit;

        ROPHasBeenCrossed := false;
        LatestBucketStartDate := FindNextBucketStartDate(TempReminderInvtProfile, AtDate, LatestBucketStartDate);
        NextBucketEndDate := LatestBucketStartDate + BucketSizeInDays - 1;

        while (NextBucketEndDate < AtDate) and not ROPHasBeenCrossed do begin
            TempReminderInvtProfile.SetFilter("Due Date", '%1..%2', LatestBucketStartDate, NextBucketEndDate);
            SupplyIncrementQty := 0;
            DemandIncrementQty := 0;
            if TempReminderInvtProfile.FindSet() then
                repeat
                    if TempReminderInvtProfile.IsSupply then begin
                        if TempReminderInvtProfile."Order Relation" <> TempReminderInvtProfile."Order Relation"::"Safety Stock" then
                            SupplyIncrementQty += TempReminderInvtProfile."Remaining Quantity (Base)";
                    end else
                        DemandIncrementQty -= TempReminderInvtProfile."Remaining Quantity (Base)";
                    TempReminderInvtProfile.Delete();
                until TempReminderInvtProfile.Next() = 0;

            NewProjectedInv := LastProjectedInventory + SupplyIncrementQty + DemandIncrementQty;
            if FutureSupplyWithinLeadtime > SupplyIncrementQty then
                FutureSupplyWithinLeadtime -= SupplyIncrementQty
            else
                FutureSupplyWithinLeadtime := 0;
            ROPHasBeenCrossed :=
              (LastProjectedInventory + SupplyIncrementQty > TempSKU."Reorder Point") and
              (NewProjectedInv <= TempSKU."Reorder Point") or
              (NewProjectedInv + FutureSupplyWithinLeadtime <= TempSKU."Reorder Point");
            LastProjectedInventory := NewProjectedInv;
            if ROPHasBeenCrossed then
                LatestBucketStartDate := NextBucketEndDate + 1
            else
                LatestBucketStartDate := FindNextBucketStartDate(TempReminderInvtProfile, AtDate, LatestBucketStartDate);
            NextBucketEndDate := LatestBucketStartDate + BucketSizeInDays - 1;
        end;
    end;

    local procedure FindNextBucketStartDate(var TempReminderInvtProfile: Record "Inventory Profile" temporary; AtDate: Date; LatestBucketStartDate: Date) NextBucketStartDate: Date
    var
        NumberOfDaysToNextReminder: Integer;
    begin
        if AtDate = 0D then
            exit(LatestBucketStartDate);

        TempReminderInvtProfile.SetFilter("Due Date", '%1..%2', LatestBucketStartDate, AtDate);
        if TempReminderInvtProfile.FindFirst() then
            AtDate := TempReminderInvtProfile."Due Date";

        NumberOfDaysToNextReminder := AtDate - LatestBucketStartDate;
        NextBucketStartDate := AtDate - (NumberOfDaysToNextReminder mod BucketSizeInDays);
    end;

    local procedure SetIgnoreOverflow(var SupplyInvtProfile: Record "Inventory Profile")
    begin
        // Apply a minimum quantity to the existing orders to protect the
        // remaining valid surplus from being reduced in the common balancing act

        if SupplyInvtProfile.FindSet(true) then
            repeat
                SupplyInvtProfile."Min. Quantity" := SupplyInvtProfile."Remaining Quantity (Base)";
                SupplyInvtProfile.Modify();
            until SupplyInvtProfile.Next() = 0;
    end;

    local procedure ChkInitialOverflow(var DemandInvtProfile: Record "Inventory Profile"; var SupplyInvtProfile: Record "Inventory Profile"; OverflowLevel: Decimal; InventoryLevel: Decimal; FromDate: Date; ToDate: Date)
    var
        xDemandInvtProfile: Record "Inventory Profile";
        xSupplyInvtProfile: Record "Inventory Profile";
        OverflowQty: Decimal;
        OriginalSupplyQty: Decimal;
        DecreasedSupplyQty: Decimal;
        PrevBucketStartDate: Date;
        PrevBucketEndDate: Date;
        CurrBucketStartDate: Date;
        CurrBucketEndDate: Date;
        NumberOfDaysToNextSupply: Integer;
    begin
        xDemandInvtProfile.Copy(DemandInvtProfile);
        xSupplyInvtProfile.Copy(SupplyInvtProfile);
        SupplyInvtProfile.SetRange("Is Exception Order", false);

        if OverflowLevel > 0 then begin
            // Detect if there is overflow in inventory within any time bucket
            // In that case: Decrease superfluous Supply; latest first
            // Apply a minimum quantity to the existing orders to protect the
            // remaining valid surplus from being reduced in the common balancing act

            // Avoid Safety Stock Demand
            DemandInvtProfile.SetRange("Order Relation", DemandInvtProfile."Order Relation"::Normal);

            PrevBucketStartDate := FromDate;
            CurrBucketEndDate := ToDate;

            while PrevBucketStartDate <= ToDate do begin
                SupplyInvtProfile.SetRange("Due Date", PrevBucketStartDate, ToDate);
                if SupplyInvtProfile.FindFirst() then begin
                    NumberOfDaysToNextSupply := SupplyInvtProfile."Due Date" - PrevBucketStartDate;
                    CurrBucketEndDate :=
                      SupplyInvtProfile."Due Date" - (NumberOfDaysToNextSupply mod BucketSizeInDays) + BucketSizeInDays - 1;
                    CurrBucketStartDate := CurrBucketEndDate - BucketSizeInDays + 1;
                    PrevBucketEndDate := CurrBucketStartDate - 1;

                    DemandInvtProfile.SetRange("Due Date", PrevBucketStartDate, PrevBucketEndDate);
                    DemandInvtProfile.CalcSums("Remaining Quantity (Base)");
                    InventoryLevel -= DemandInvtProfile."Remaining Quantity (Base)";

                    // Negative inventory from previous buckets shall not influence
                    // possible overflow in the current time bucket
                    if InventoryLevel < 0 then
                        InventoryLevel := 0;

                    DemandInvtProfile.SetRange("Due Date", CurrBucketStartDate, CurrBucketEndDate);
                    DemandInvtProfile.CalcSums("Remaining Quantity (Base)");
                    InventoryLevel -= DemandInvtProfile."Remaining Quantity (Base)";

                    SupplyInvtProfile.SetRange("Due Date", CurrBucketStartDate, CurrBucketEndDate);
                    if SupplyInvtProfile.Find('-') then begin
                        repeat
                            InventoryLevel += SupplyInvtProfile."Remaining Quantity (Base)";
                        until SupplyInvtProfile.Next() = 0;

                        OverflowQty := InventoryLevel - OverflowLevel;
                        repeat
                            if OverflowQty > 0 then begin
                                OriginalSupplyQty := SupplyInvtProfile."Quantity (Base)";
                                SupplyInvtProfile."Min. Quantity" := 0;
                                DecreaseQty(SupplyInvtProfile, OverflowQty, true);

                                // If the supply has not been decreased as planned, try to cancel it.
                                DecreasedSupplyQty := SupplyInvtProfile."Quantity (Base)";
                                if (DecreasedSupplyQty > 0) and (OriginalSupplyQty - DecreasedSupplyQty < OverflowQty) and
                                   (SupplyInvtProfile."Order Priority" < 1000)
                                then
                                    if CanDecreaseSupply(SupplyInvtProfile, OverflowQty) then
                                        DecreaseQty(SupplyInvtProfile, DecreasedSupplyQty, true);

                                if OriginalSupplyQty <> SupplyInvtProfile."Quantity (Base)" then begin
                                    DummyInventoryProfileTrackBuffer."Warning Level" := DummyInventoryProfileTrackBuffer."Warning Level"::Attention;
                                    PlanningTransparency.LogWarning(
                                      SupplyInvtProfile."Line No.", ReqLine, DummyInventoryProfileTrackBuffer."Warning Level",
                                      StrSubstNo(Text010, InventoryLevel, OverflowLevel, CurrBucketEndDate));
                                    OverflowQty -= (OriginalSupplyQty - SupplyInvtProfile."Quantity (Base)");
                                    InventoryLevel -= (OriginalSupplyQty - SupplyInvtProfile."Quantity (Base)");
                                end;
                            end;
                            SupplyInvtProfile."Min. Quantity" := SupplyInvtProfile."Remaining Quantity (Base)";
                            SupplyInvtProfile.Modify();
                            if SupplyInvtProfile."Line No." = xSupplyInvtProfile."Line No." then
                                xSupplyInvtProfile := SupplyInvtProfile;
                        until (SupplyInvtProfile.Next(-1) = 0);
                    end;

                    if InventoryLevel < 0 then
                        InventoryLevel := 0;
                    PrevBucketStartDate := CurrBucketEndDate + 1;
                end else
                    PrevBucketStartDate := ToDate + 1;
            end;
        end else
            if OverflowLevel = 0 then
                SetIgnoreOverflow(SupplyInvtProfile);

        DemandInvtProfile.Copy(xDemandInvtProfile);
        SupplyInvtProfile.Copy(xSupplyInvtProfile);
    end;

    procedure CheckNewOverflow(var SupplyInvtProfile: Record "Inventory Profile"; InventoryLevel: Decimal; QtyToDecreaseOverFlow: Decimal; LastDueDate: Date)
    var
        xSupplyInvtProfile: Record "Inventory Profile";
        OriginalSupplyQty: Decimal;
        QtyToDecrease: Decimal;
    begin
        // the function tries to avoid overflow when a new supply was suggested
        xSupplyInvtProfile.Copy(SupplyInvtProfile);
        SupplyInvtProfile.SetRange("Due Date", LastDueDate + 1, PlanToDate);
        SupplyInvtProfile.SetFilter("Remaining Quantity (Base)", '>0');

        if SupplyInvtProfile.FindSet(true) then
            repeat
                if SupplyInvtProfile."Original Quantity" > 0 then
                    InventoryLevel := InventoryLevel + SupplyInvtProfile."Original Quantity" * SupplyInvtProfile."Qty. per Unit of Measure"
                else
                    InventoryLevel := InventoryLevel + SupplyInvtProfile."Remaining Quantity (Base)";
                OriginalSupplyQty := SupplyInvtProfile."Quantity (Base)";

                if InventoryLevel > OverflowLevel then begin
                    SupplyInvtProfile."Min. Quantity" := 0;
                    DummyInventoryProfileTrackBuffer."Warning Level" := DummyInventoryProfileTrackBuffer."Warning Level"::Attention;
                    QtyToDecrease := InventoryLevel - OverflowLevel;

                    if QtyToDecrease > QtyToDecreaseOverFlow then
                        QtyToDecrease := QtyToDecreaseOverFlow;

                    if QtyToDecrease > SupplyInvtProfile."Remaining Quantity (Base)" then
                        QtyToDecrease := SupplyInvtProfile."Remaining Quantity (Base)";

                    DecreaseQty(SupplyInvtProfile, QtyToDecrease, true);

                    PlanningTransparency.LogWarning(
                      SupplyInvtProfile."Line No.", ReqLine, DummyInventoryProfileTrackBuffer."Warning Level",
                      StrSubstNo(Text010, InventoryLevel, OverflowLevel, SupplyInvtProfile."Due Date"));

                    QtyToDecreaseOverFlow := QtyToDecreaseOverFlow - (OriginalSupplyQty - SupplyInvtProfile."Quantity (Base)");
                    InventoryLevel := InventoryLevel - (OriginalSupplyQty - SupplyInvtProfile."Quantity (Base)");
                    SupplyInvtProfile."Min. Quantity" := SupplyInvtProfile."Remaining Quantity (Base)";
                    SupplyInvtProfile.Modify();
                end;
            until (SupplyInvtProfile.Next() = 0) or (QtyToDecreaseOverFlow <= 0);

        SupplyInvtProfile.Copy(xSupplyInvtProfile);
    end;

    local procedure CheckScheduleIn(var SupplyInvtProfile: Record "Inventory Profile"; TargetDate: Date; var PossibleDate: Date; LimitedHorizon: Boolean) Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckScheduleIn(SupplyInvtProfile, TempSKU, TargetDate, PossibleDate, LimitedHorizon, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if SupplyInvtProfile."Planning Flexibility" <> SupplyInvtProfile."Planning Flexibility"::Unlimited then
            exit(false);

        if LimitedHorizon and not AllowScheduleIn(SupplyInvtProfile, TargetDate) then
            PossibleDate := SupplyInvtProfile."Due Date"
        else
            PossibleDate := TargetDate;

        exit(TargetDate = PossibleDate);
    end;

    local procedure CheckScheduleOut(var SupplyInvtProfile: Record "Inventory Profile"; TargetDate: Date; var PossibleDate: Date; LimitedHorizon: Boolean): Boolean
    var
        ShouldExitAllowLotAccumulation: Boolean;
        IsHandled: Boolean;
        Result: Boolean;
    begin
        OnBeforeCheckScheduleOut(SupplyInvtProfile, TempSKU, BucketSize, DampenersDays);

        if SupplyInvtProfile."Planning Flexibility" <> SupplyInvtProfile."Planning Flexibility"::Unlimited then
            exit(false);

        if (TargetDate - SupplyInvtProfile."Due Date") <= DampenersDays then
            PossibleDate := SupplyInvtProfile."Due Date"
        else
            if not LimitedHorizon or
               (SupplyInvtProfile."Planning Level Code" > 0)
            then
                PossibleDate := TargetDate
            else
                if AllowScheduleOut(SupplyInvtProfile, TargetDate) then
                    PossibleDate := TargetDate
                else begin
                    // Do not reschedule but may be lot accumulation is still an option
                    PossibleDate := SupplyInvtProfile."Due Date";

                    IsHandled := false;
                    OnCheckScheduleOutOnBeforeAllowLotAccumulation(PossibleDate, TargetDate, SupplyInvtProfile, IsHandled, Result);
                    if IsHandled then
                        exit(Result);

                    ShouldExitAllowLotAccumulation := SupplyInvtProfile."Fixed Date" <> 0D;
                    OnCheckScheduleOutOnNotAllowScheduleOut(SupplyInvtProfile, ShouldExitAllowLotAccumulation);
                    if ShouldExitAllowLotAccumulation then
                        exit(AllowLotAccumulation(SupplyInvtProfile, TargetDate));

                    exit(false);
                end;

        // Limit possible rescheduling in case the supply is already linked up to another demand
        if (SupplyInvtProfile."Fixed Date" <> 0D) and
           (SupplyInvtProfile."Fixed Date" < PossibleDate)
        then begin
            if not AllowLotAccumulation(SupplyInvtProfile, TargetDate) then // but reschedule only if lot accumulation is allowed for target date
                exit(false);

            PossibleDate := SupplyInvtProfile."Fixed Date";
        end;

        exit(true);
    end;

    local procedure CheckSupplyWithSKU(var InventoryProfile: Record "Inventory Profile"; var SKU: Record "Stockkeeping Unit")
    var
        xInventoryProfile: Record "Inventory Profile";
    begin
        xInventoryProfile.Copy(InventoryProfile);

        if SKU."Maximum Order Quantity" > 0 then
            if InventoryProfile.Find('-') then
                repeat
                    CheckUpdateInventoryProfileMaxQuantity(InventoryProfile, SKU);
                until InventoryProfile.Next() = 0;
        InventoryProfile.Copy(xInventoryProfile);
        if InventoryProfile.Get(InventoryProfile."Line No.") then;
    end;

    local procedure CheckUpdateInventoryProfileMaxQuantity(var InventoryProfile: Record "Inventory Profile"; var SKU: Record "Stockkeeping Unit")
    begin
        OnBeforeCheckUpdateInventoryProfileMaxQuantity(InventoryProfile, SKU);

        if (SKU."Maximum Order Quantity" > InventoryProfile."Max. Quantity") and
               (InventoryProfile."Quantity (Base)" > 0) and
               (InventoryProfile."Max. Quantity" = 0)
            then begin
            InventoryProfile."Max. Quantity" := SKU."Maximum Order Quantity";
            InventoryProfile.Modify();
        end;
    end;

    procedure CreateSupplyForward(var SupplyInvtProfile: Record "Inventory Profile"; DemandInvtProfile: Record "Inventory Profile"; var TempReminderInvtProfile: Record "Inventory Profile" temporary; AtDate: Date; ProjectedInventory: Decimal; var NewSupplyHasTakenOver: Boolean; CurrDueDate: Date)
    var
        TempSupplyInvtProfile: Record "Inventory Profile" temporary;
        CurrSupplyInvtProfile: Record "Inventory Profile";
        LeadTimeEndDate: Date;
        QtyToOrder: Decimal;
        QtyToOrderThisLine: Decimal;
        SupplyWithinLeadtime: Decimal;
        HasLooped: Boolean;
        CurrSupplyExists: Boolean;
        QtyToDecreaseOverFlow: Decimal;
    begin
        // Save current supply and check if it is real
        CurrSupplyInvtProfile := SupplyInvtProfile;
        CurrSupplyExists := SupplyInvtProfile.Find('=');

        // Initiate new supplyprofile
        InitSupply(TempSupplyInvtProfile, 0, AtDate, 0T);

        // Make sure VAR boolean is reset:
        NewSupplyHasTakenOver := false;
        QtyToOrder := CalcOrderQty(QtyToOrder, ProjectedInventory, TempSupplyInvtProfile."Line No.");

        // Use new supplyprofile to determine lead-time
        UpdateQty(TempSupplyInvtProfile, QtyToOrder + AdjustReorderQty(QtyToOrder, TempSKU, TempSupplyInvtProfile."Line No.", 0));
        TempSupplyInvtProfile.Insert();
        ScheduleForward(TempSupplyInvtProfile, DemandInvtProfile, AtDate);
        LeadTimeEndDate := TempSupplyInvtProfile."Due Date";

        // Find supply within leadtime, returns a qty
        TempReminderInvtProfile.SetRange(IsSupply, true);
        SupplyWithinLeadtime :=
          SumUpProjectedSupply(SupplyInvtProfile, AtDate, LeadTimeEndDate) +
          QtyFromPendingReminders(TempReminderInvtProfile, LeadTimeEndDate, AtDate);
        TempReminderInvtProfile.SetRange(IsSupply);
        FutureSupplyWithinLeadtime := SupplyWithinLeadtime;

        // If found supply + projinvlevel covers ROP then the situation has already been taken care of: roll back and (exit)
        if SupplyWithinLeadtime + ProjectedInventory > TempSKU."Reorder Point" then begin
            // Delete obsolete Planning Line
            MaintainPlanningLine(TempSupplyInvtProfile, DemandInvtProfile, PlanningLineStage::Obsolete, ScheduleDirection::Backward);
            PlanningTransparency.CleanLog(TempSupplyInvtProfile."Line No.");
            exit;
        end;

        // If found supply only covers ROP partialy, then we need to adjust quantity.
        if TempSKU."Reordering Policy" = TempSKU."Reordering Policy"::"Fixed Reorder Qty." then
            if SupplyWithinLeadtime > 0 then begin
                QtyToOrder -= SupplyWithinLeadtime;
                if QtyToOrder < TempSKU."Reorder Quantity" then
                    QtyToOrder := TempSKU."Reorder Quantity";
                PlanningTransparency.ModifyPlanningLog(
                  TempSupplyInvtProfile."Line No.", 0, Database::Item, TempSKU."Item No.", -SupplyWithinLeadtime,
                  SurplusType::ReorderPoint);
            end;

        // If Max: Deduct found supply in order to stay below max inventory and adjust transparency log
        if TempSKU."Reordering Policy" = TempSKU."Reordering Policy"::"Maximum Qty." then
            if SupplyWithinLeadtime <> 0 then begin
                QtyToOrder -= SupplyWithinLeadtime;
                PlanningTransparency.ModifyPlanningLog(
                  TempSupplyInvtProfile."Line No.", 0, Database::Item, TempSKU."Item No.", -SupplyWithinLeadtime,
                  SurplusType::MaxInventory);
            end;

        LeadTimeEndDate := AtDate;

        OnCreateSupplyForwardOnBeforeLoopQtyToOrderMoreThanZero(TempSKU, QtyToOrder, SupplyWithinLeadtime, TempSupplyInvtProfile);

        while QtyToOrder > 0 do begin
            // In case of max order the new supply could be split in several new supplies:
            if HasLooped then begin
                InitSupply(TempSupplyInvtProfile, 0, AtDate, 0T);
                case TempSKU."Reordering Policy" of
                    TempSKU."Reordering Policy"::"Maximum Qty.":
                        SurplusType := SurplusType::MaxInventory;
                    TempSKU."Reordering Policy"::"Fixed Reorder Qty.":
                        SurplusType := SurplusType::FixedOrderQty;
                end;
                PlanningTransparency.LogPlanningSurplus(TempSupplyInvtProfile."Line No.", 0, 0, '', QtyToOrder, SurplusType);
                QtyToOrderThisLine := QtyToOrder + AdjustReorderQty(QtyToOrder, TempSKU, TempSupplyInvtProfile."Line No.", 0);
                UpdateQty(TempSupplyInvtProfile, QtyToOrderThisLine);
                TempSupplyInvtProfile.Insert();
                ScheduleForward(TempSupplyInvtProfile, DemandInvtProfile, AtDate);
            end else begin
                QtyToOrderThisLine := QtyToOrder + AdjustReorderQty(QtyToOrder, TempSKU, TempSupplyInvtProfile."Line No.", 0);
                if QtyToOrderThisLine <> TempSupplyInvtProfile."Remaining Quantity (Base)" then begin
                    UpdateQty(TempSupplyInvtProfile, QtyToOrderThisLine);
                    ScheduleForward(TempSupplyInvtProfile, DemandInvtProfile, AtDate);
                end;
                HasLooped := true;
            end;

            // The supply is inserted into the overall supply dataset
            SupplyInvtProfile := TempSupplyInvtProfile;
            TempSupplyInvtProfile.Delete();
            SupplyInvtProfile."Min. Quantity" := SupplyInvtProfile."Remaining Quantity (Base)";
            SupplyInvtProfile."Max. Quantity" := TempSKU."Maximum Order Quantity";
            SupplyInvtProfile."Fixed Date" := SupplyInvtProfile."Due Date";
            SupplyInvtProfile."Order Priority" := 1000; // Make sure to give last priority if supply exists on the same date
            SupplyInvtProfile."Attribute Priority" := 1000;
            OnCreateSupplyForwardOnBeforeSupplyInvtProfileInsert(SupplyInvtProfile, TempSKU);
            SupplyInvtProfile.Insert();

            // Planning Transparency
            PlanningTransparency.LogPlanningSurplus(
              SupplyInvtProfile."Line No.", 0, 0, '', SupplyInvtProfile."Untracked Quantity", SurplusType::ReorderPoint);

            if SupplyInvtProfile."Due Date" < CurrDueDate then begin
                CurrSupplyInvtProfile := SupplyInvtProfile;
                CurrDueDate := SupplyInvtProfile."Due Date";
                NewSupplyHasTakenOver := true
            end;

            if LeadTimeEndDate < SupplyInvtProfile."Due Date" then
                LeadTimeEndDate := SupplyInvtProfile."Due Date";

            if (not CurrSupplyExists) or
               (SupplyInvtProfile."Due Date" < CurrSupplyInvtProfile."Due Date")
            then begin
                CurrSupplyInvtProfile := SupplyInvtProfile;
                CurrSupplyExists := true;
                NewSupplyHasTakenOver := CurrSupplyInvtProfile."Due Date" <= CurrDueDate;
            end;

            QtyToOrder -= SupplyInvtProfile."Remaining Quantity (Base)";
            FutureSupplyWithinLeadtime += SupplyInvtProfile."Remaining Quantity (Base)";
            QtyToDecreaseOverFlow += SupplyInvtProfile."Quantity (Base)";
        end;

        if HasLooped and (OverflowLevel > 0) then
            // the new supply might cause overflow in inventory since
            // it wasn't considered when Overflow was calculated
            CheckNewOverflow(SupplyInvtProfile, ProjectedInventory + QtyToDecreaseOverFlow, QtyToDecreaseOverFlow, LeadTimeEndDate);

        SupplyInvtProfile := CurrSupplyInvtProfile;
    end;

    local procedure AllowScheduleIn(SupplyInvtProfile: Record "Inventory Profile"; TargetDate: Date) CanReschedule: Boolean
    begin
        CanReschedule := CalcDate(TempSKU."Rescheduling Period", TargetDate) >= SupplyInvtProfile."Due Date";

        OnAfterAllowScheduleIn(SupplyInvtProfile, TargetDate, CanReschedule);
    end;

    local procedure AllowScheduleOut(SupplyInvtProfile: Record "Inventory Profile"; TargetDate: Date) CanReschedule: Boolean
    begin
        CanReschedule := CalcDate(TempSKU."Rescheduling Period", SupplyInvtProfile."Due Date") >= TargetDate;

        OnAfterAllowScheduleOut(SupplyInvtProfile, TargetDate, CanReschedule, TempSKU);
    end;

    local procedure AllowLotAccumulation(SupplyInvtProfile: Record "Inventory Profile"; DemandDueDate: Date) AccumulationOK: Boolean
    begin
        AccumulationOK := CalcDate(TempSKU."Lot Accumulation Period", SupplyInvtProfile."Due Date") >= DemandDueDate;
        OnAfterAllowLotAccumulation(SupplyInvtProfile, DemandDueDate, TempSKU, AccumulationOK);
    end;

    local procedure ShallSupplyBeClosed(SupplyInventoryProfile: Record "Inventory Profile"; DemandDueDate: Date; IsReorderPointPlanning: Boolean) CloseSupply: Boolean
    begin
        if SupplyInventoryProfile."Is Exception Order" then begin
            if TempSKU."Reordering Policy" = TempSKU."Reordering Policy"::"Lot-for-Lot" then
                // supply within Lot Accumulation Period will be summed up with Exception order
                CloseSupply := not AllowLotAccumulation(SupplyInventoryProfile, DemandDueDate)
            else
                // only demand in the same day as Exception will be summed up
                CloseSupply := SupplyInventoryProfile."Due Date" <> DemandDueDate;
        end else
            CloseSupply := IsReorderPointPlanning;

        OnAfterShallSupplyBeClosed(TempSKU, SupplyInventoryProfile, DemandDueDate, IsReorderPointPlanning, CloseSupply);
    end;

    local procedure GetNextLineNo(): Integer
    begin
        LineNo += 1;
        exit(LineNo);
    end;

    local procedure Reschedule(var SupplyInvtProfile: Record "Inventory Profile"; TargetDate: Date; TargetTime: Time)
    begin
        SupplyInvtProfile.TestField("Planning Flexibility", SupplyInvtProfile."Planning Flexibility"::Unlimited);

        if (TargetDate <> SupplyInvtProfile."Due Date") and
           (SupplyInvtProfile."Action Message" <> SupplyInvtProfile."Action Message"::New)
        then begin
            if SupplyInvtProfile."Original Due Date" = 0D then
                SupplyInvtProfile."Original Due Date" := SupplyInvtProfile."Due Date";
            UpdateActionMessageOnReschedule(SupplyInvtProfile);
        end;
        SupplyInvtProfile."Due Date" := TargetDate;
        if (SupplyInvtProfile."Due Time" = 0T) or
           (SupplyInvtProfile."Due Time" > TargetTime)
        then
            SupplyInvtProfile."Due Time" := TargetTime;
        OnRescheduleOnBeforeModifySupplyInvtProfile(SupplyInvtProfile, TargetDate, TargetTime);
        SupplyInvtProfile.Modify();
    end;

    local procedure UpdateActionMessageOnReschedule(var SupplyInvtProfile: Record "Inventory Profile")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateActionMessageOnReschedule(SupplyInvtProfile, IsHandled);
        if IsHandled then
            exit;

        if SupplyInvtProfile."Original Quantity" = 0 then
            SupplyInvtProfile."Action Message" := SupplyInvtProfile."Action Message"::Reschedule
        else
            SupplyInvtProfile."Action Message" := SupplyInvtProfile."Action Message"::"Resched. & Chg. Qty.";

    end;

    procedure InitSupply(var SupplyInvtProfile: Record "Inventory Profile"; OrderQty: Decimal; DueDate: Date; DueTime: Time)
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        SupplyInvtProfile.Init();
        SupplyInvtProfile."Line No." := GetNextLineNo();
        SupplyInvtProfile."Item No." := TempSKU."Item No.";
        SupplyInvtProfile."Variant Code" := TempSKU."Variant Code";
        SupplyInvtProfile."Location Code" := TempSKU."Location Code";
        SupplyInvtProfile."Action Message" := SupplyInvtProfile."Action Message"::New;
        UpdateQty(SupplyInvtProfile, OrderQty);
        SupplyInvtProfile."Due Date" := DueDate;
        SupplyInvtProfile."Due Time" := DueTime;
        SupplyInvtProfile.IsSupply := true;
        Item.Get(TempSKU."Item No.");
        SupplyInvtProfile."Unit of Measure Code" := Item."Base Unit of Measure";
        SupplyInvtProfile."Qty. per Unit of Measure" := 1;

        case TempSKU."Replenishment System" of
            TempSKU."Replenishment System"::Purchase:
                begin
                    SupplyInvtProfile."Source Type" := Database::"Purchase Line";
                    SupplyInvtProfile."Unit of Measure Code" := Item."Purch. Unit of Measure";
                    if SupplyInvtProfile."Unit of Measure Code" <> Item."Base Unit of Measure" then begin
                        ItemUnitOfMeasure.Get(TempSKU."Item No.", Item."Purch. Unit of Measure");
                        SupplyInvtProfile."Qty. per Unit of Measure" := ItemUnitOfMeasure."Qty. per Unit of Measure";
                    end;
                end;
            TempSKU."Replenishment System"::"Prod. Order":
                SupplyInvtProfile."Source Type" := 5406; // Database::"Prod. Order Line"
            TempSKU."Replenishment System"::Transfer:
                SupplyInvtProfile."Source Type" := Database::"Transfer Line";
        end;

        OnAfterInitSupply(SupplyInvtProfile, TempSKU, Item);
    end;

    local procedure UpdateQty(var InvProfile: Record "Inventory Profile"; Qty: Decimal)
    begin
        InvProfile."Untracked Quantity" := Qty;
        InvProfile."Quantity (Base)" := InvProfile."Untracked Quantity";
        InvProfile."Remaining Quantity (Base)" := InvProfile."Quantity (Base)";
    end;

    local procedure TransferAttributes(var ToInvProfile: Record "Inventory Profile"; var FromInvProfile: Record "Inventory Profile")
    begin
        if SpecificLotTracking then
            ToInvProfile."Lot No." := FromInvProfile."Lot No.";
        if SpecificSNTracking then
            ToInvProfile."Serial No." := FromInvProfile."Serial No.";

        if TempSKU."Replenishment System" = TempSKU."Replenishment System"::"Prod. Order" then
            if FromInvProfile."Planning Level Code" > 0 then begin
                ToInvProfile.Binding := ToInvProfile.Binding::"Order-to-Order";
                ToInvProfile."Planning Level Code" := FromInvProfile."Planning Level Code";
                ToInvProfile."Due Time" := FromInvProfile."Due Time";
                ToInvProfile."Bin Code" := FromInvProfile."Bin Code";
            end;

        if FromInvProfile.Binding = FromInvProfile.Binding::"Order-to-Order" then begin
            ToInvProfile.Binding := ToInvProfile.Binding::"Order-to-Order";
            ToInvProfile."Primary Order Status" := FromInvProfile."Primary Order Status";
            ToInvProfile."Primary Order No." := FromInvProfile."Primary Order No.";
            ToInvProfile."Primary Order Line" := FromInvProfile."Primary Order Line";
        end;

        ToInvProfile."MPS Order" := FromInvProfile."MPS Order";

        if ToInvProfile.TrackingExists() then
            ToInvProfile."Planning Flexibility" := ToInvProfile."Planning Flexibility"::None;

        OnAfterTransferAttributes(ToInvProfile, FromInvProfile, TempSKU, SpecificLotTracking, SpecificSNTracking);
    end;

    local procedure AllocateSafetystock(var SupplyInvtProfile: Record "Inventory Profile"; QtyToAllocate: Decimal; AtDate: Date)
    var
        MinQtyToCoverSafetyStock: Decimal;
    begin
        if QtyToAllocate > SupplyInvtProfile."Safety Stock Quantity" then begin
            SupplyInvtProfile."Safety Stock Quantity" := QtyToAllocate;
            MinQtyToCoverSafetyStock :=
              SupplyInvtProfile."Remaining Quantity (Base)" -
              SupplyInvtProfile."Untracked Quantity" + SupplyInvtProfile."Safety Stock Quantity";
            if SupplyInvtProfile."Min. Quantity" < MinQtyToCoverSafetyStock then
                SupplyInvtProfile."Min. Quantity" := MinQtyToCoverSafetyStock;
            if SupplyInvtProfile."Min. Quantity" > SupplyInvtProfile."Remaining Quantity (Base)" then
                Error(Text001, SupplyInvtProfile.FieldCaption("Safety Stock Quantity"));
            if (SupplyInvtProfile."Fixed Date" = 0D) or (SupplyInvtProfile."Fixed Date" > AtDate) then
                SupplyInvtProfile."Fixed Date" := AtDate;
            SupplyInvtProfile.Modify();
        end;
    end;

    procedure SumUpProjectedSupply(var SupplyInvtProfile: Record "Inventory Profile"; FromDate: Date; ToDate: Date) ProjectedQty: Decimal
    var
        xSupplyInvtProfile: Record "Inventory Profile";
    begin
        // Sums up the contribution to the projected inventory
        OnBeforeSumUpProjectedSupply(SupplyInvtProfile, FromDate, ToDate);

        xSupplyInvtProfile.Copy(SupplyInvtProfile);
        SupplyInvtProfile.SetRange("Due Date", FromDate, ToDate);

        if SupplyInvtProfile.FindSet() then
            repeat
                if (SupplyInvtProfile.Binding <> SupplyInvtProfile.Binding::"Order-to-Order") and
                   (SupplyInvtProfile."Order Relation" <> SupplyInvtProfile."Order Relation"::"Safety Stock")
                then
                    ProjectedQty += SupplyInvtProfile."Remaining Quantity (Base)";
            until SupplyInvtProfile.Next() = 0;

        SupplyInvtProfile.Copy(xSupplyInvtProfile);
    end;

    local procedure SumUpAvailableSupply(var SupplyInvtProfile: Record "Inventory Profile"; FromDate: Date; ToDate: Date) AvailableQty: Decimal
    var
        xSupplyInvtProfile: Record "Inventory Profile";
    begin
        // Sums up the contribution to the available inventory
        OnBeforeSumUpAvailableSupply(SupplyInvtProfile, FromDate, ToDate);

        xSupplyInvtProfile.Copy(SupplyInvtProfile);
        SupplyInvtProfile.SetRange("Due Date", FromDate, ToDate);

        SupplyInvtProfile.CalcSums("Untracked Quantity");
        AvailableQty += SupplyInvtProfile."Untracked Quantity";

        SupplyInvtProfile.Copy(xSupplyInvtProfile);
    end;

    local procedure SetPriority(var InventoryProfile: Record "Inventory Profile"; IsReorderPointPlanning: Boolean; ToDate: Date)
    begin
        if InventoryProfile.IsSupply then begin
            if InventoryProfile."Due Date" > ToDate then
                InventoryProfile."Planning Flexibility" := InventoryProfile."Planning Flexibility"::None;

            if IsReorderPointPlanning and (InventoryProfile.Binding <> InventoryProfile.Binding::"Order-to-Order") and
               (InventoryProfile."Planning Flexibility" <> InventoryProfile."Planning Flexibility"::None)
            then
                InventoryProfile."Planning Flexibility" := InventoryProfile."Planning Flexibility"::"Reduce Only";
            SetSupplyPriority(InventoryProfile);
        end else
            SetDemandPriority(InventoryProfile);

        OnAfterSetOrderPriority(InventoryProfile);

        InventoryProfile.TestField("Order Priority");
        // Inflexible supply must be handled before all other supply and is therefore grouped
        // together with inventory in group 100:
        if InventoryProfile.IsSupply and (InventoryProfile."Source Type" <> Database::"Item Ledger Entry") then
            if InventoryProfile."Planning Flexibility" <> InventoryProfile."Planning Flexibility"::Unlimited then
                InventoryProfile."Order Priority" := 100 + (InventoryProfile."Order Priority" / 10);

        if InventoryProfile."Planning Flexibility" = InventoryProfile."Planning Flexibility"::Unlimited then
            if InventoryProfile.ActiveInWarehouse() then
                InventoryProfile."Order Priority" -= 1;

        SetAttributePriority(InventoryProfile);

        InventoryProfile.Modify();
    end;

    local procedure SetSupplyPriority(var InventoryProfile: Record "Inventory Profile")
    begin
        case InventoryProfile."Source Type" of
            Database::"Item Ledger Entry":
                InventoryProfile."Order Priority" := 100;
            Database::"Transfer Line":
                InventoryProfile."Order Priority" := 300;
        end;

        OnAfterSetSupplyPriority(InventoryProfile);
    end;

    local procedure SetDemandPriority(var InventoryProfile: Record "Inventory Profile")
    begin
        case InventoryProfile."Source Type" of
            Database::"Item Ledger Entry":
                InventoryProfile."Order Priority" := 100;
            Database::"Transfer Line":
                InventoryProfile."Order Priority" := 600;
            Database::Microsoft.Manufacturing.Forecast."Production Forecast Entry":
                InventoryProfile."Order Priority" := 800;
        end;

        OnAfterSetDemandPriority(InventoryProfile);
    end;

    local procedure SetAttributePriority(var InvProfile: Record "Inventory Profile")
    var
        HandleLot: Boolean;
        HandleSN: Boolean;
    begin
        HandleSN := (InvProfile."Serial No." <> '') and SpecificSNTracking;
        HandleLot := (InvProfile."Lot No." <> '') and SpecificLotTracking;

        if HandleSN then begin
            if HandleLot then
                if InvProfile.Binding = InvProfile.Binding::"Order-to-Order" then
                    InvProfile."Attribute Priority" := 1
                else
                    InvProfile."Attribute Priority" := 4
            else
                if InvProfile.Binding = InvProfile.Binding::"Order-to-Order" then
                    InvProfile."Attribute Priority" := 2
                else
                    InvProfile."Attribute Priority" := 5;
        end else
            if HandleLot then
                if InvProfile.Binding = InvProfile.Binding::"Order-to-Order" then
                    InvProfile."Attribute Priority" := 3
                else
                    InvProfile."Attribute Priority" := 6
            else
                if InvProfile.Binding = InvProfile.Binding::"Order-to-Order" then
                    InvProfile."Attribute Priority" := 7
                else
                    InvProfile."Attribute Priority" := 8;
    end;

    local procedure UpdatePriorities(var InvProfile: Record "Inventory Profile"; IsReorderPointPlanning: Boolean; ToDate: Date)
    var
        xInvProfile: Record "Inventory Profile";
    begin
        xInvProfile.Copy(InvProfile);
        InvProfile.SetCurrentKey("Line No.");
        if InvProfile.FindSet(true) then
            repeat
                SetPriority(InvProfile, IsReorderPointPlanning, ToDate);
            until InvProfile.Next() = 0;
        InvProfile.Copy(xInvProfile);
    end;

    local procedure InsertSafetyStockDemands(var DemandInvtProfile: Record "Inventory Profile"; PlanningStartDate: Date)
    var
        xDemandInvtProfile: Record "Inventory Profile";
        TempSafetyStockInvtProfile: Record "Inventory Profile" temporary;
        OrderRelation: Option Normal,"Safety Stock","Reorder Point";
    begin
        if TempSKU."Safety Stock Quantity" = 0 then
            exit;

        xDemandInvtProfile.Copy(DemandInvtProfile);

        OnInsertSafetyStockDemandsOnBeforeCreateDemand(DemandInvtProfile, PlanningStartDate, TempSKU);

        DemandInvtProfile.SetCurrentKey(
          "Item No.", "Variant Code", "Location Code", "Due Date", "Attribute Priority", "Order Priority");
        DemandInvtProfile.SetFilter("Due Date", '%1..', PlanningStartDate);
        if DemandInvtProfile.FindSet() then
            repeat
                if TempSafetyStockInvtProfile."Due Date" <> DemandInvtProfile."Due Date" then begin
                    CreateDemand(
                        TempSafetyStockInvtProfile, TempSKU, TempSKU."Safety Stock Quantity", DemandInvtProfile."Due Date", OrderRelation::"Safety Stock");
                    TempSafetyStockInvtProfile."MPS Order" := DemandInvtProfile."MPS Order";
                    TempSafetyStockInvtProfile.Modify();
                end;
            until DemandInvtProfile.Next() = 0;

        DemandInvtProfile.SetRange("Due Date", PlanningStartDate);
        if DemandInvtProfile.IsEmpty() then
            CreateDemand(
              TempSafetyStockInvtProfile, TempSKU, TempSKU."Safety Stock Quantity", PlanningStartDate, OrderRelation::"Safety Stock");

        if TempSafetyStockInvtProfile.FindSet(true) then
            repeat
                DemandInvtProfile := TempSafetyStockInvtProfile;
                DemandInvtProfile."Order Priority" := 1000;
                DemandInvtProfile.Insert();
            until TempSafetyStockInvtProfile.Next() = 0;

        DemandInvtProfile.Copy(xDemandInvtProfile);

        OnAfterInsertSafetyStockDemands(
          DemandInvtProfile, xDemandInvtProfile, TempSafetyStockInvtProfile, TempSKU, PlanningStartDate, PlanToDate);
    end;

    local procedure ScheduleAllOutChangesSequence(var SupplyInvtProfile: Record "Inventory Profile"; NewDate: Date): Boolean
    var
        TempRescheduledSupplyInvtProfile: Record "Inventory Profile" temporary;
        NumberofSupplies: Integer;
        NextRecExists: Integer;
        SavedPosition: Integer;
        IsHandled: Boolean;
    begin
        SavedPosition := SupplyInvtProfile."Line No.";
        if (SupplyInvtProfile."Due Date" = 0D) or
           (SupplyInvtProfile."Planning Flexibility" <> SupplyInvtProfile."Planning Flexibility"::Unlimited)
        then
            exit(false);

        if not AllowScheduleOut(SupplyInvtProfile, NewDate) then
            exit(false);

        NextRecExists := 1;

        // check if reschedule is needed
        IsHandled := false;
        OnScheduleAllOutChangesSequenceOnBeforeCheckIfRescheduleIsNeeded(SupplyInvtProfile, NextRecExists, IsHandled, NewDate, NumberofSupplies);
        if not IsHandled then
            while (SupplyInvtProfile."Due Date" < NewDate) and
                  (SupplyInvtProfile."Action Message" <> SupplyInvtProfile."Action Message"::New) and
                  (SupplyInvtProfile."Planning Flexibility" = SupplyInvtProfile."Planning Flexibility"::Unlimited) and
                  (SupplyInvtProfile."Fixed Date" = 0D) and
                  (NextRecExists <> 0)
            do begin
                NumberofSupplies += 1;
                TempRescheduledSupplyInvtProfile := SupplyInvtProfile;
                TempRescheduledSupplyInvtProfile.Insert();
                Reschedule(TempRescheduledSupplyInvtProfile, NewDate, 0T);

                NextRecExists := SupplyInvtProfile.Next();
            end;

        // if there is only one supply before the demand we roll back
        if NumberofSupplies <= 1 then
            if not ((NextRecExists <> 0) and (SupplyInvtProfile."Due Date" = NewDate) and (SupplyInvtProfile."Line No." < SavedPosition)) then begin
                SupplyInvtProfile.Get(SavedPosition);
                exit(false);
            end;

        TempRescheduledSupplyInvtProfile.SetCurrentKey(
          "Item No.", "Variant Code", "Location Code", "Due Date", "Attribute Priority", "Order Priority");

        // If we have resheduled we replace the original supply records with the resceduled ones,
        // we re-write the primary key to make sure that the supplies are handled in the right order.
        if TempRescheduledSupplyInvtProfile.FindSet() then begin
            if (NextRecExists <> 0) and (SupplyInvtProfile."Due Date" = NewDate) then
                SavedPosition := SupplyInvtProfile."Line No."
            else
                SavedPosition := 0;

            repeat
                SupplyInvtProfile := TempRescheduledSupplyInvtProfile;
                SupplyInvtProfile.Delete();
                SupplyInvtProfile."Line No." := GetNextLineNo();
                OnScheduleAllOutChangesSequenceOnBeforeSupplyInvtProfileInsert(SupplyInvtProfile);
                SupplyInvtProfile.Insert();
                if SavedPosition = 0 then
                    SavedPosition := SupplyInvtProfile."Line No.";
            until TempRescheduledSupplyInvtProfile.Next() = 0;

            SupplyInvtProfile.Get(SavedPosition);
        end;

        exit(true);
    end;

    local procedure PrepareOrderToOrderLink(var InventoryProfile: Record "Inventory Profile")
    var
        IsHandled: Boolean;
    begin
        // Prepare new demand for order-to-order planning
        if InventoryProfile.FindSet(true) then
            repeat
                if not InventoryProfile.IsSupply and
                    (not (InventoryProfile."Source Type" = Database::Microsoft.Manufacturing.Forecast."Production Forecast Entry")) and
                    (not ((InventoryProfile."Source Type" = Database::"Sales Line") and (InventoryProfile."Source Order Status" = 4))) and
                    ((TempSKU."Reordering Policy" = TempSKU."Reordering Policy"::Order) or (InventoryProfile."Planning Level Code" <> 0))
                then begin
                    if InventoryProfile."Source Type" = Database::"Planning Component" then
                        // Primary Order references have already been set on Component Lines
                        InventoryProfile.Binding := InventoryProfile.Binding::"Order-to-Order"
                    else begin
                        InventoryProfile.Binding := InventoryProfile.Binding::"Order-to-Order";
                        InventoryProfile."Primary Order Type" := InventoryProfile."Source Type";
                        InventoryProfile."Primary Order Status" := InventoryProfile."Source Order Status";
                        InventoryProfile."Primary Order No." := InventoryProfile."Source ID";
                        if InventoryProfile."Source Type" <> 5407 then // Database::"Prod. Order Component"
                            InventoryProfile."Primary Order Line" := InventoryProfile."Source Ref. No."
                        else
                            InventoryProfile."Primary Order Line" := InventoryProfile."Source Prod. Order Line";
                    end;
                    IsHandled := false;
                    OnPrepareOrderToOrderLinkOnBeforeInventoryProfileModify(InventoryProfile, TempSKU, IsHandled);
                    if not IsHandled then
                        InventoryProfile.Modify();
                end;
            until InventoryProfile.Next() = 0;
    end;

    local procedure SetAcceptAction(ItemNo: Code[20])
    var
        ReqLine: Record "Requisition Line";
        PurchHeader: Record "Purchase Header";
        TransHeader: Record "Transfer Header";
        ReqWkshTempl: Record "Req. Wksh. Template";
        AcceptActionMsg: Boolean;
        IsHandled: Boolean;
    begin
        ReqWkshTempl.Get(CurrTemplateName);
        if ReqWkshTempl.Type <> ReqWkshTempl.Type::Planning then
            exit;
        ReqLine.SetCurrentKey("Worksheet Template Name", "Journal Batch Name", Type, "No.");
        ReqLine.SetRange("Worksheet Template Name", CurrTemplateName);
        ReqLine.SetRange("Journal Batch Name", CurrWorksheetName);
        ReqLine.SetRange(Type, ReqLine.Type::Item);
        ReqLine.SetRange("No.", ItemNo);
        DummyInventoryProfileTrackBuffer."Warning Level" := DummyInventoryProfileTrackBuffer."Warning Level"::Attention;

        if ReqLine.FindSet(true) then
            repeat
                AcceptActionMsg := ReqLine."Starting Date" >= WorkDate();
                if not AcceptActionMsg then
                    PlanningTransparency.LogWarning(0, ReqLine, DummyInventoryProfileTrackBuffer."Warning Level",
                      StrSubstNo(Text008, DummyInventoryProfileTrackBuffer."Warning Level", ReqLine.FieldCaption(ReqLine."Starting Date"),
                        ReqLine."Starting Date", WorkDate()));

                if ReqLine."Action Message" <> ReqLine."Action Message"::New then
                    case ReqLine."Ref. Order Type" of
                        ReqLine."Ref. Order Type"::Purchase:
                            if (PurchHeader.Get(PurchHeader."Document Type"::Order, ReqLine."Ref. Order No.") and
                                (PurchHeader.Status = PurchHeader.Status::Released))
                            then begin
                                AcceptActionMsg := false;
                                PlanningTransparency.LogWarning(
                                    0, ReqLine, DummyInventoryProfileTrackBuffer."Warning Level",
                                    StrSubstNo(Text009,
                                        DummyInventoryProfileTrackBuffer."Warning Level", ReqLine."Ref. Order Type",
                                        ReqLine."Ref. Order No.", PurchHeader.Status));
                            end;
                        ReqLine."Ref. Order Type"::"Prod. Order":
                            if ReqLine."Ref. Order Status" = ReqLine."Ref. Order Status"::Released then begin
                                AcceptActionMsg := false;
                                PlanningTransparency.LogWarning(
                                    0, ReqLine, DummyInventoryProfileTrackBuffer."Warning Level",
                                    StrSubstNo(Text009,
                                        DummyInventoryProfileTrackBuffer."Warning Level", ReqLine."Ref. Order Type",
                                        ReqLine."Ref. Order No.", ReqLine."Ref. Order Status"));
                            end;
                        ReqLine."Ref. Order Type"::Transfer:
                            begin
                                IsHandled := false;
                                OnSetAcceptActionOnCaseRefOrderTypeTransfer(ReqLine, AcceptActionMsg, IsHandled);
                                if not IsHandled then
                                    if (TransHeader.Get(ReqLine."Ref. Order No.") and (TransHeader.Status = TransHeader.Status::Released)) then begin
                                        AcceptActionMsg := false;
                                        PlanningTransparency.LogWarning(
                                            0, ReqLine, DummyInventoryProfileTrackBuffer."Warning Level",
                                            StrSubstNo(Text009,
                                                DummyInventoryProfileTrackBuffer."Warning Level", ReqLine."Ref. Order Type",
                                                ReqLine."Ref. Order No.", TransHeader.Status));
                                    end;
                            end;
                    end;

                OnSetAcceptActionOnBeforeAcceptActionMsg(ReqLine, AcceptActionMsg, PlanningTransparency);

                if AcceptActionMsg then
                    AcceptActionMsg := PlanningTransparency.ReqLineWarningLevel(ReqLine) = 0;

                if not AcceptActionMsg then begin
                    ReqLine."Accept Action Message" := false;
                    ReqLine.Modify();
                end;
            until ReqLine.Next() = 0;
    end;

    procedure GetRouting(var ReqLine2: Record "Requisition Line")
    begin
        OnGetRouting(ReqLine2);
    end;

    procedure GetComponents(var ReqLine2: Record "Requisition Line")
    begin
        ReqLine.BlockDynamicTracking(true);
        if ReqLine."Action Message" = ReqLine."Action Message"::New then
            OnGetComponentsOnNewActionMessage(ReqLine)
        else
            OnGetComponentsOnUpdateForActionMessage(ReqLine);

        OnGetComponents(ReqLine2);
    end;

    procedure Recalculate(var ReqLine: Record "Requisition Line"; Direction: Option Forward,Backward; RefreshRouting: Boolean)
    begin
        Clear(PlanningLineManagement);
        if PlanningResiliency then
            PlanningLineManagement.SetResiliencyOn(ReqLine."Worksheet Template Name", ReqLine."Journal Batch Name", ReqLine."No.");
        PlanningLineManagement.BlockDynamicTracking(true);
        OnGetRoutingOnAfterSetResiliencyOn(ReqLine);

        PlanningLineManagement.Calculate(
            ReqLine, Direction, RefreshRouting,
            (ReqLine."Action Message" = ReqLine."Action Message"::New) and
            (ReqLine."Ref. Order Type" in [ReqLine."Ref. Order Type"::"Prod. Order", ReqLine."Ref. Order Type"::Assembly]), -1);
        OnAfterRecalculateReqLine(ReqLine);
        if ReqLine."Action Message" = ReqLine."Action Message"::New then
            PlanningLineManagement.GetPlanningCompList(TempPlanningCompList);
    end;

    procedure GetPlanningCompList(var PlanningCompList: Record "Planning Component" temporary)
    begin
        TempPlanningCompList.Reset();
        if TempPlanningCompList.Find('-') then
            repeat
                PlanningCompList := TempPlanningCompList;
                if not PlanningCompList.Insert() then
                    PlanningCompList.Modify();
                TempPlanningCompList.Delete();
            until TempPlanningCompList.Next() = 0;
    end;

    local procedure DeletePlanningCompList(RequisitionLine: Record "Requisition Line")
    begin
        TempPlanningCompList.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        TempPlanningCompList.SetRange("Worksheet Batch Name", RequisitionLine."Journal Batch Name");
        TempPlanningCompList.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
        TempPlanningCompList.DeleteAll();
    end;

    procedure SetParm(Forecast: Code[10]; ExclBefore: Date; WorksheetType: Option Requisition,Planning; PriceCalcMethod: Enum "Price Calculation Method")
    begin
        SetParm(Forecast, ExclBefore, WorksheetType);
        PriceCalculationMethod := PriceCalcMethod;
    end;

    procedure SetParm(Forecast: Code[10]; ExclBefore: Date; WorksheetType: Option Requisition,Planning)
    begin
        CurrForecast := Forecast;
        ExcludeForecastBefore := ExclBefore;
        UseParm := true;
        CurrWorksheetType := WorksheetType;
    end;

    procedure SetResiliencyOn()
    begin
        PlanningResiliency := true;
    end;

    procedure GetResiliencyError(var PlanningErrorLog: Record "Planning Error Log"): Boolean
    begin
        if ReqLine.GetResiliencyError(PlanningErrorLog) then
            exit(true);
        exit(PlanningLineManagement.GetResiliencyError(PlanningErrorLog));
    end;

    local procedure CloseTracking(ReservEntry: Record "Reservation Entry"; var SupplyInventoryProfile: Record "Inventory Profile"; ToDate: Date): Boolean
    var
        xSupplyInventoryProfile: Record "Inventory Profile";
        ReservationEngineMgt: Codeunit "Reservation Engine Mgt.";
        Closed: Boolean;
    begin
        if ReservEntry."Reservation Status" <> ReservEntry."Reservation Status"::Tracking then
            exit(false);

        xSupplyInventoryProfile.Copy(SupplyInventoryProfile);
        Closed := false;

        if (ReservEntry."Expected Receipt Date" <= ToDate) and
           (ReservEntry."Shipment Date" > ToDate)
        then begin
            // tracking exists with demand in future
            SupplyInventoryProfile.SetCurrentKey(
              "Source Type", "Source Order Status", "Source ID", "Source Batch Name", "Source Ref. No.", "Source Prod. Order Line", IsSupply,
              "Due Date");
            SupplyInventoryProfile.SetRange("Source Type", ReservEntry."Source Type");
            SupplyInventoryProfile.SetRange("Source Order Status", ReservEntry."Source Subtype");
            SupplyInventoryProfile.SetRange("Source ID", ReservEntry."Source ID");
            SupplyInventoryProfile.SetRange("Source Batch Name", ReservEntry."Source Batch Name");
            SupplyInventoryProfile.SetRange("Source Ref. No.", ReservEntry."Source Ref. No.");
            SupplyInventoryProfile.SetRange("Source Prod. Order Line", ReservEntry."Source Prod. Order Line");
            SupplyInventoryProfile.SetRange("Due Date", 0D, ToDate);

            if not SupplyInventoryProfile.IsEmpty() then begin
                // demand is either deleted as well or will get Surplus status
                ReservationEngineMgt.CloseReservEntry(ReservEntry, false, false);
                Closed := true;
            end;
        end;

        SupplyInventoryProfile.Copy(xSupplyInventoryProfile);
        exit(Closed);
    end;

    procedure FrozenZoneTrack(FromInventoryProfile: Record "Inventory Profile"; ToInventoryProfile: Record "Inventory Profile")
    begin
        if FromInventoryProfile.TrackingExists() then
            Track(FromInventoryProfile, ToInventoryProfile, true, false, FromInventoryProfile.Binding::" ");

        if ToInventoryProfile.TrackingExists() then begin
            ToInventoryProfile."Untracked Quantity" := FromInventoryProfile."Untracked Quantity";
            ToInventoryProfile."Quantity (Base)" := FromInventoryProfile."Untracked Quantity";
            ToInventoryProfile."Original Quantity" := 0;
            Track(ToInventoryProfile, FromInventoryProfile, true, false, ToInventoryProfile.Binding::" ");
        end;
    end;

    local procedure ExceedROPinException(RespectPlanningParm: Boolean): Boolean
    begin
        if not RespectPlanningParm then
            exit(false);

        exit(TempSKU."Reordering Policy" = TempSKU."Reordering Policy"::"Fixed Reorder Qty.");
    end;

    local procedure CreateSupplyForInitialSafetyStockWarning(var SupplyInventoryProfile: Record "Inventory Profile"; ProjectedInventory: Decimal; var LastProjectedInventory: Decimal; var LastAvailableInventory: Decimal; PlanningStartDate: Date; RespectPlanningParm: Boolean; IsReorderPointPlanning: Boolean)
    var
        OrderQty: Decimal;
        ReorderQty: Decimal;
    begin
        OnBeforeCreateSupplyForInitialSafetyStockWarning(PlanningStartDate, SupplyInventoryProfile);
        OrderQty := TempSKU."Safety Stock Quantity" - ProjectedInventory;
        if ExceedROPinException(RespectPlanningParm) then
            OrderQty := TempSKU."Reorder Point" - ProjectedInventory;

        ReorderQty := OrderQty;

        repeat
            InitSupply(SupplyInventoryProfile, ReorderQty, PlanningStartDate, 0T);
            if RespectPlanningParm then begin
                if IsReorderPointPlanning then
                    ReorderQty := CalcOrderQty(ReorderQty, ProjectedInventory, SupplyInventoryProfile."Line No.");

                ReorderQty += AdjustReorderQty(ReorderQty, TempSKU, SupplyInventoryProfile."Line No.", SupplyInventoryProfile."Min. Quantity");
                SupplyInventoryProfile."Max. Quantity" := TempSKU."Maximum Order Quantity";
                UpdateQty(SupplyInventoryProfile, ReorderQty);
                SupplyInventoryProfile."Min. Quantity" := SupplyInventoryProfile."Quantity (Base)";
            end;
            SupplyInventoryProfile."Fixed Date" := SupplyInventoryProfile."Due Date";
            SupplyInventoryProfile."Order Relation" := SupplyInventoryProfile."Order Relation"::"Safety Stock";
            SupplyInventoryProfile."Is Exception Order" := true;
            OnCreateSupplyForInitialSafetyStockWarningOnBeforeSupplyInventoryProfileInsert(SupplyInventoryProfile, TempSKU);
            SupplyInventoryProfile.Insert();

            DummyInventoryProfileTrackBuffer."Warning Level" := DummyInventoryProfileTrackBuffer."Warning Level"::Exception;
            PlanningTransparency.LogWarning(
              SupplyInventoryProfile."Line No.", ReqLine, DummyInventoryProfileTrackBuffer."Warning Level",
              StrSubstNo(Text007, DummyInventoryProfileTrackBuffer."Warning Level", TempSKU.FieldCaption("Safety Stock Quantity"),
                TempSKU."Safety Stock Quantity", PlanningStartDate));

            LastProjectedInventory += SupplyInventoryProfile."Remaining Quantity (Base)";
            ProjectedInventory += SupplyInventoryProfile."Remaining Quantity (Base)";
            LastAvailableInventory += SupplyInventoryProfile."Untracked Quantity";

            OrderQty -= ReorderQty;
            if ExceedROPinException(RespectPlanningParm) and (OrderQty = 0) then
                OrderQty := ExceedROPqty;
            ReorderQty := OrderQty;
        until OrderQty <= 0; // Create supplies until Safety Stock is met or Reorder point is exceeded
    end;

    local procedure IsTrkgForSpecialOrderOrDropShpt(ReservEntry: Record "Reservation Entry") Result: Boolean
    var
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsTrkgForSpecialOrderOrDropShpt(ReservEntry, Result, IsHandled);
        if IsHandled then
            exit(Result);

        case ReservEntry."Source Type" of
            Database::"Sales Line":
                begin
                    SalesLine.SetLoadFields("Special Order", "Drop Shipment");
                    if SalesLine.Get(ReservEntry."Source Subtype", ReservEntry."Source ID", ReservEntry."Source Ref. No.") then
                        exit(SalesLine."Special Order" or SalesLine."Drop Shipment");
                end;
            Database::"Purchase Line":
                begin
                    PurchaseLine.SetLoadFields("Special Order", "Drop Shipment");
                    if PurchaseLine.Get(ReservEntry."Source Subtype", ReservEntry."Source ID", ReservEntry."Source Ref. No.") then
                        exit(PurchaseLine."Special Order" or PurchaseLine."Drop Shipment");
                end;
        end;

        exit(false);
    end;

    local procedure CheckSupplyRemQtyAndUntrackQty(var InventoryProfile: Record "Inventory Profile")
    var
        RemQty: Decimal;
    begin
        if InventoryProfile."Source Type" = Database::"Item Ledger Entry" then
            exit;

        if InventoryProfile."Remaining Quantity (Base)" >= TempSKU."Maximum Order Quantity" then begin
            RemQty := InventoryProfile."Remaining Quantity (Base)";
            InventoryProfile."Remaining Quantity (Base)" := TempSKU."Maximum Order Quantity";
            if not (InventoryProfile."Action Message" in [InventoryProfile."Action Message"::New, InventoryProfile."Action Message"::Reschedule]) then
                InventoryProfile."Original Quantity" := InventoryProfile."Quantity (Base)";
        end;
        if InventoryProfile."Untracked Quantity" >= TempSKU."Maximum Order Quantity" then
            InventoryProfile."Untracked Quantity" := InventoryProfile."Untracked Quantity" - RemQty + InventoryProfile."Remaining Quantity (Base)";
    end;

    local procedure CheckItemInventoryExists(var InventoryProfile: Record "Inventory Profile") ItemInventoryExists: Boolean
    begin
        InventoryProfile.SetRange("Source Type", Database::"Item Ledger Entry");
        InventoryProfile.SetFilter(Binding, '<>%1', InventoryProfile.Binding::"Order-to-Order");
        ItemInventoryExists := not InventoryProfile.IsEmpty();
        InventoryProfile.SetRange("Source Type");
        InventoryProfile.SetRange(Binding);
    end;

    local procedure ApplyUntrackedQuantityToItemInventory(SupplyExists: Boolean; ItemInventoryExists: Boolean; DemandForAdditionalProfile: Boolean): Boolean
    begin
        if SupplyExists then
            exit(false);
        if DemandForAdditionalProfile then
            exit(false);
        exit(ItemInventoryExists);
    end;

    local procedure UpdateAppliedItemEntry(var ReservEntry: Record "Reservation Entry")
    var
        ItemTrackingSetup: Record "Item Tracking Setup";
    begin
        TempItemTrkgEntry.SetSourceFilter(
            ReservEntry."Source Type", ReservEntry."Source Subtype", ReservEntry."Source ID", ReservEntry."Source Ref. No.", true);
        ItemTrackingSetup.CopyTrackingFromReservEntry(ReservEntry);
        TempItemTrkgEntry.SetTrackingFilterFromItemTrackingSetupIfNotBlank(ItemTrackingSetup);
        OnUpdateAppliedItemEntryOnBeforeFindApplEntry(TempItemTrkgEntry, ReservEntry);
        if TempItemTrkgEntry.FindFirst() then begin
            ReservEntry."Appl.-from Item Entry" := TempItemTrkgEntry."Appl.-from Item Entry";
            ReservEntry."Appl.-to Item Entry" := TempItemTrkgEntry."Appl.-to Item Entry";
        end;

        OnAfterUpdateAppliedItemEntry(ReservEntry, TempItemTrkgEntry, ReqLine);
    end;

    local procedure CheckSupplyAndTrack(InventoryProfileFromDemand: Record "Inventory Profile"; InventoryProfileFromSupply: Record "Inventory Profile")
    begin
        OnBeforeCheckSupplyAndTrack(InventoryProfileFromDemand, InventoryProfileFromSupply);

        if InventoryProfileFromSupply."Source Type" = Database::"Item Ledger Entry" then
            Track(InventoryProfileFromDemand, InventoryProfileFromSupply, false, false, InventoryProfileFromSupply.Binding)
        else
            Track(InventoryProfileFromDemand, InventoryProfileFromSupply, false, false, InventoryProfileFromDemand.Binding);
    end;

    local procedure CheckPlanSKU(SKU: Record "Stockkeeping Unit"; DemandExists: Boolean; SupplyExists: Boolean; IsReorderPointPlanning: Boolean): Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPlanSKU(SKU, IsHandled);
        if IsHandled then
            exit(false);

        if (CurrWorksheetType = CurrWorksheetType::Requisition) and (SKU.IsMfgSKU() or SKU.IsAssemblySKU()) then
            exit(false);

        if DemandExists or SupplyExists or IsReorderPointPlanning then
            exit(true);

        exit(false);
    end;

    local procedure PrepareDemand(var InventoryProfile: Record "Inventory Profile"; IsReorderPointPlanning: Boolean; ToDate: Date)
    begin
        // Transfer attributes
        if (TempSKU."Reordering Policy" = TempSKU."Reordering Policy"::Order) or
           (TempSKU."Manufacturing Policy" = TempSKU."Manufacturing Policy"::"Make-to-Order")
        then
            PrepareOrderToOrderLink(InventoryProfile);
        UpdatePriorities(InventoryProfile, IsReorderPointPlanning, ToDate);
    end;

    local procedure DemandMatchedSupply(var FromInventoryProfile: Record "Inventory Profile"; var ToInventoryProfile: Record "Inventory Profile"; SKU: Record "Stockkeeping Unit"): Boolean
    var
        xFromInventoryProfile: Record "Inventory Profile";
        xToInventoryProfile: Record "Inventory Profile";
        UntrackedQty: Decimal;
    begin
        xToInventoryProfile.CopyFilters(FromInventoryProfile);
        xFromInventoryProfile.CopyFilters(ToInventoryProfile);
        FromInventoryProfile.SetRange(FromInventoryProfile."Attribute Priority", 1, 7);
        FromInventoryProfile.SetRange(FromInventoryProfile."Planning Level Code", 0);
        if FromInventoryProfile.FindSet() then begin
            repeat
                ToInventoryProfile.SetRange(Binding, FromInventoryProfile.Binding);
                ToInventoryProfile.SetRange("Primary Order Status", FromInventoryProfile."Primary Order Status");
                ToInventoryProfile.SetRange("Primary Order No.", FromInventoryProfile."Primary Order No.");
                ToInventoryProfile.SetRange("Primary Order Line", FromInventoryProfile."Primary Order Line");
                ToInventoryProfile.SetTrackingFilter(FromInventoryProfile);
                OnDemandMatchedSupplyOnAfterSetFiltersToInvProfile(ToInventoryProfile, FromInventoryProfile);
                ToInventoryProfile.CalcSums("Untracked Quantity");
                UntrackedQty += ToInventoryProfile."Untracked Quantity";
                UntrackedQty -= FromInventoryProfile."Untracked Quantity";
            until FromInventoryProfile.Next() = 0;
            if (UntrackedQty = 0) and (SKU."Reordering Policy" = SKU."Reordering Policy"::"Lot-for-Lot") then begin
                FromInventoryProfile.SetRange(FromInventoryProfile."Attribute Priority", 8);
                FromInventoryProfile.CalcSums(FromInventoryProfile."Untracked Quantity");
                if FromInventoryProfile."Untracked Quantity" = 0 then begin
                    FromInventoryProfile.CopyFilters(xToInventoryProfile);
                    ToInventoryProfile.CopyFilters(xFromInventoryProfile);
                    exit(true);
                end;
            end;
        end;
        FromInventoryProfile.CopyFilters(xToInventoryProfile);
        ToInventoryProfile.CopyFilters(xFromInventoryProfile);
        exit(false);
    end;

    local procedure ReservedForProdComponent(ReservationEntry: Record "Reservation Entry"): Boolean
    begin
        if not ReservationEntry.Positive then
            exit(ReservationEntry."Source Type" = 5407); //  Database::"Prod. Order Component"
        if ReservationEntry.Get(ReservationEntry."Entry No.", false) then
            exit(ReservationEntry."Source Type" = 5407);  //  Database::"Prod. Order Component"
    end;

    local procedure ShouldInsertTrackingEntry(FromTrkgReservEntry: Record "Reservation Entry"): Boolean
    var
        InsertedReservEntry: Record "Reservation Entry";
    begin
        InsertedReservEntry.SetRange("Source ID", FromTrkgReservEntry."Source ID");
        InsertedReservEntry.SetRange("Source Ref. No.", FromTrkgReservEntry."Source Ref. No.");
        InsertedReservEntry.SetRange("Source Type", FromTrkgReservEntry."Source Type");
        InsertedReservEntry.SetRange("Source Subtype", FromTrkgReservEntry."Source Subtype");
        InsertedReservEntry.SetRange("Source Batch Name", FromTrkgReservEntry."Source Batch Name");
        InsertedReservEntry.SetRange("Source Prod. Order Line", FromTrkgReservEntry."Source Prod. Order Line");
        InsertedReservEntry.SetRange("Reservation Status", FromTrkgReservEntry."Reservation Status");
        exit(InsertedReservEntry.IsEmpty);
    end;

    local procedure CloseInventoryProfile(var ClosedInvtProfile: Record "Inventory Profile"; var OpenInvtProfile: Record "Inventory Profile"; ActionMessage: Enum "Action Message Type")
    var
        PlanningStageToMaintain: Option " ","Line Created","Routing Created",Exploded,Obsolete;
    begin
        OpenInvtProfile."Untracked Quantity" -= ClosedInvtProfile."Untracked Quantity";
        OpenInvtProfile.Modify();

        if OpenInvtProfile.Binding = OpenInvtProfile.Binding::"Order-to-Order" then
            PlanningStageToMaintain := PlanningStageToMaintain::Exploded
        else
            PlanningStageToMaintain := PlanningStageToMaintain::"Line Created";

        if ActionMessage <> ActionMessage::" " then
            if OpenInvtProfile.IsSupply then
                MaintainPlanningLine(OpenInvtProfile, ClosedInvtProfile, PlanningStageToMaintain, ScheduleDirection::Backward)
            else
                MaintainPlanningLine(ClosedInvtProfile, ClosedInvtProfile, PlanningStageToMaintain, ScheduleDirection::Backward);

        Track(ClosedInvtProfile, OpenInvtProfile, false, false, OpenInvtProfile.Binding);

        if ClosedInvtProfile.Binding = ClosedInvtProfile.Binding::"Order-to-Order" then
            ClosedInvtProfile."Remaining Quantity (Base)" -= ClosedInvtProfile."Untracked Quantity";

        ClosedInvtProfile."Untracked Quantity" := 0;
        if ClosedInvtProfile."Remaining Quantity (Base)" = 0 then
            ClosedInvtProfile.Delete()
        else
            ClosedInvtProfile.Modify();
    end;

    local procedure CloseDemand(var DemandInvtProfile: Record "Inventory Profile"; var SupplyInvtProfile: Record "Inventory Profile")
    begin
        CloseInventoryProfile(DemandInvtProfile, SupplyInvtProfile, SupplyInvtProfile."Action Message");
    end;

    local procedure CloseSupply(var DemandInvtProfile: Record "Inventory Profile"; var SupplyInvtProfile: Record "Inventory Profile"): Boolean
    begin
        CloseInventoryProfile(SupplyInvtProfile, DemandInvtProfile, SupplyInvtProfile."Action Message");
        exit(SupplyInvtProfile.Next() <> 0);
    end;

    local procedure CreateTempSKUForComponentsLocation(var Item: Record Item)
    var
        SKU: Record "Stockkeeping Unit";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateTempSKUForComponentsLocation(Item, IsHandled);
        if IsHandled then
            exit;

        if GetComponentsAtLocationCode() = '' then
            exit;

        SKU.SetRange("Item No.", Item."No.");
        IsHandled := false;
        OnCreateTempSKUForComponentsLocationOnBeforeSetLocationCodeFilter(Item, SKU, IsHandled);
        if not IsHandled then
            SKU.SetRange("Location Code", GetComponentsAtLocationCode());
        IsHandled := false;
        OnCreateTempSKUForComponentsLocationOnBeforeItemCopyFilter(SKU, Item, IsHandled);
        if not IsHandled then
            Item.CopyFilter("Variant Filter", SKU."Variant Code");
        if SKU.IsEmpty() then
            CreateTempSKUForLocation(Item."No.", GetComponentsAtLocationCode());
    end;

    local procedure GetComponentsAtLocationCode() LocationCode: Code[10]
    begin
        OnGetComponentsAtLocationCode(LocationCode);
    end;

    procedure ForecastInitDemand(var InventoryProfile: Record "Inventory Profile"; ProductionForecastEntry: Record Microsoft.Manufacturing.Forecast."Production Forecast Entry"; ItemNo: Code[20]; LocationCode: Code[10]; TotalForecastQty: Decimal)
    begin
        InventoryProfile.Init();
        InventoryProfile."Line No." := GetNextLineNo();
        InventoryProfile."Source Type" := Database::Microsoft.Manufacturing.Forecast."Production Forecast Entry";
        InventoryProfile."Planning Flexibility" := InventoryProfile."Planning Flexibility"::None;
        InventoryProfile."Qty. per Unit of Measure" := 1;
        InventoryProfile."MPS Order" := true;
        InventoryProfile."Source ID" := ProductionForecastEntry."Production Forecast Name";
        InventoryProfile."Item No." := ItemNo;
        InventorySetup.GetRecordOnce();
        if InventorySetup."Use Forecast on Locations" then
            InventoryProfile."Location Code" := ProductionForecastEntry."Location Code"
        else
            InventoryProfile."Location Code" := LocationCode;
        if InventorySetup."Use Forecast on Variants" then
            InventoryProfile."Variant Code" := ProductionForecastEntry."Variant Code"
        else
            InventoryProfile."Variant Code" := '';
        InventoryProfile."Remaining Quantity (Base)" := TotalForecastQty;
        InventoryProfile."Untracked Quantity" := TotalForecastQty;
        OnAfterForecastInitDemand(InventoryProfile, ProductionForecastEntry, ItemNo, LocationCode, TotalForecastQty);
    end;

    local procedure SetPurchase(var PurchaseLine: Record "Purchase Line"; var InventoryProfile: Record "Inventory Profile")
    begin
        ReqLine."Ref. Order Type" := ReqLine."Ref. Order Type"::Purchase;
        ReqLine."Ref. Order No." := InventoryProfile."Source ID";
        ReqLine."Ref. Line No." := InventoryProfile."Source Ref. No.";
        PurchaseLine.Get(PurchaseLine."Document Type"::Order, ReqLine."Ref. Order No.", ReqLine."Ref. Line No.");
        ReqLine.TransferFromPurchaseLine(PurchaseLine);

        OnAfterSetPurchase(PurchaseLine, ReqLine, InventoryProfile);
    end;

    local procedure SetTransfer(var TransLine: Record "Transfer Line"; var InventoryProfile: Record "Inventory Profile")
    var
        IsHandled: Boolean;
    begin
        ReqLine."Ref. Order Type" := ReqLine."Ref. Order Type"::Transfer;
        ReqLine."Ref. Order Status" := ReqLine."Ref. Order Status"::Simulated;
        ReqLine."Ref. Order No." := InventoryProfile."Source ID";
        ReqLine."Ref. Line No." := InventoryProfile."Source Ref. No.";

        IsHandled := false;
        OnSetTransferOnBeforeTransferFromTransLine(InventoryProfile, ReqLine, IsHandled);
        if not IsHandled then begin
            TransLine.Get(ReqLine."Ref. Order No.", ReqLine."Ref. Line No.");
            ReqLine.TransferFromTransLine(TransLine);
        end;
    end;

    local procedure FromLotAccumulationPeriodStartDate(LotAccumulationPeriodStartDate: Date; DemandDueDate: Date) Result: Boolean
    var
        IsHandled: Boolean;
    begin
        isHandled := false;
        OnBeforeFromLotAccumulationPeriodStartDate(LotAccumulationPeriodStartDate, DemandDueDate, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if LotAccumulationPeriodStartDate > 0D then
            exit(CalcDate(TempSKU."Lot Accumulation Period", LotAccumulationPeriodStartDate) >= DemandDueDate);
    end;

    local procedure IsSKUSetUpForReorderPointPlanning(SKU: Record "Stockkeeping Unit"): Boolean
    begin
        exit(
          (SKU."Reorder Point" > SKU."Safety Stock Quantity") or
          (SKU."Reordering Policy" in [SKU."Reordering Policy"::"Maximum Qty.", SKU."Reordering Policy"::"Fixed Reorder Qty."]));
    end;

    procedure InsertPlanningComponent(var PlanningComponent: Record "Planning Component");
    begin
        OnBeforeInsertPlanningComponent(PlanningComponent);

        PlanningComponent.Insert();
        TempPlanningCompList := PlanningComponent;
        if not TempPlanningCompList.Insert() then
            TempPlanningCompList.Modify();
    end;

    local procedure InsertInitialSafetyStockWarningSupply(var SupplyInvtProfile: Record "Inventory Profile"; var LastAvailableInventory: Decimal; var LastProjectedInventory: Decimal; PlanningStartDate: Date; RespectPlanningParm: Boolean; var IsReorderPointPlanning: Boolean)
    var
        SupplyAvailableWithinLeadTime: Decimal;
        InitialProjectedInventory: Decimal;
        IsHandled: Boolean;
    begin
        OnBeforeInsertInitialSafetyStockWarningSupply(SupplyInvtProfile, LastAvailableInventory, LastProjectedInventory, PlanningStartDate, RespectPlanningParm, IsReorderPointPlanning, IsHandled);
        if IsHandled then
            exit;

        SupplyAvailableWithinLeadTime := SumUpAvailableSupply(SupplyInvtProfile, PlanningStartDate, PlanningStartDate);
        InitialProjectedInventory := LastAvailableInventory + SupplyAvailableWithinLeadTime;
        if InitialProjectedInventory < TempSKU."Safety Stock Quantity" then
            CreateSupplyForInitialSafetyStockWarning(
              SupplyInvtProfile, InitialProjectedInventory, LastProjectedInventory, LastAvailableInventory, PlanningStartDate, RespectPlanningParm, IsReorderPointPlanning);
    end;

    local procedure InsertInventoryProfile(var InventoryProfile: Record "Inventory Profile"; RequisitionLine: Record "Requisition Line"; Item: Record Item)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertInventoryProfile(RequisitionLine, IsHandled);
        if IsHandled then
            exit;

        InventoryProfile.Init();
        InventoryProfile."Line No." := GetNextLineNo();
        InventoryProfile."Item No." := Item."No.";
        InventoryProfile.TransferFromOutboundTransfPlan(RequisitionLine, TempItemTrkgEntry);
        if InventoryProfile.IsSupply then
            InventoryProfile.ChangeSign();
        InventoryProfile.Insert();
    end;

    local procedure GetPrevAvailDateFromCompanyCalendar(InitialDate: Date): Date
    var
        CustomCalendarChange: array[2] of Record "Customized Calendar Change";
    begin
        if InitialDate = 0D then
            exit(InitialDate);

        CustomCalendarChange[1].SetSource(CustomCalendarChange[1]."Source Type"::Company, '', '', '');
        exit(CalendarManagement.CalcDateBOC2('<0D>', InitialDate, CustomCalendarChange, false));
    end;

    local procedure SetPriceCalculationMethod(var RequisitionLine: Record "Requisition Line")
    var
        Vendor: Record Vendor;
    begin
        if PriceCalculationMethod = PriceCalculationMethod::" " then
            RequisitionLine."Price Calculation Method" := Vendor.GetPriceCalculationMethod()
        else
            RequisitionLine."Price Calculation Method" := PriceCalculationMethod;
    end;

    local procedure DemandForAdditionalLine(var DemandInvtProfile: Record "Inventory Profile"; var SupplyInvtProfile: Record "Inventory Profile"): Boolean
    begin
        if (TempSKU."Replenishment System" = TempSKU."Replenishment System"::"Prod. Order") and
            (TempSKU."Manufacturing Policy" = TempSKU."Manufacturing Policy"::"Make-to-Order") then begin
            if TempSKU."Reordering Policy" = TempSKU."Reordering Policy"::"Lot-for-Lot" then
                if DemandInvtProfile.Count() > 1 then
                    exit(true);
            if TempSKU."Reordering Policy" = TempSKU."Reordering Policy"::"Maximum Qty." then
                if CheckItemInventoryExists(SupplyInvtProfile) then
                    exit(true);
        end;
    end;

    local procedure IsReorderQtyToAdjust(StockkeepingUnit: Record "Stockkeeping Unit"): Boolean
    begin
        exit(not ((StockkeepingUnit."Reordering Policy" = StockkeepingUnit."Reordering Policy"::"Lot-for-Lot") and (StockkeepingUnit."Manufacturing Policy" = StockkeepingUnit."Manufacturing Policy"::"Make-to-Order")) or
            ((StockkeepingUnit."Replenishment System" = StockkeepingUnit."Replenishment System"::"Prod. Order") and (StockkeepingUnit."Manufacturing Policy" = StockkeepingUnit."Manufacturing Policy"::"Make-to-Stock")) or
            (StockkeepingUnit."Replenishment System" in [StockkeepingUnit."Replenishment System"::Purchase, StockkeepingUnit."Replenishment System"::Assembly]))
    end;

    local procedure CheckReorderingPolicyAndOrderTrackingPolicy(Item: Record Item): Boolean
    begin
        if not (Item."Reordering Policy" in ["Reordering Policy"::"Fixed Reorder Qty.", "Reordering Policy"::"Lot-for-Lot"]) then
            exit(false);

        if Item."Order Tracking Policy" <> Item."Order Tracking Policy"::"Tracking Only" then
            exit(false);

        exit(true);
    end;

    local procedure IsLotSpecificTracking(ItemTrackingCode: Record "Item Tracking Code"): Boolean
    var
        LotSepecificTracking: Boolean;
    begin
        LotSepecificTracking := (
            (ItemTrackingCode."Lot Specific Tracking") or
            (ItemTrackingCode."Lot Warehouse Tracking") or
            (ItemTrackingCode."Lot Transfer Tracking") or
            (ItemTrackingCode."Lot Info. Outbound Must Exist") or
            (ItemTrackingCode."Lot Purchase Outbound Tracking") or
            (ItemTrackingCode."Lot Sales Outbound Tracking") or
            (ItemTrackingCode."Lot Pos. Adjmt. Outb. Tracking") or
            (ItemTrackingCode."Lot Neg. Adjmt. Outb. Tracking") or
            (ItemTrackingCode."Lot Info. Inbound Must Exist") or
            (ItemTrackingCode."Lot Purchase Inbound Tracking") or
            (ItemTrackingCode."Lot Sales Inbound Tracking") or
            (ItemTrackingCode."Lot Pos. Adjmt. Inb. Tracking") or
            (ItemTrackingCode."Lot Neg. Adjmt. Inb. Tracking"));

        if not LotSepecificTracking then
            OnCheckIsLotSpecificTracking(ItemTrackingCode, LotSepecificTracking);

        exit(LotSepecificTracking);
    end;

    local procedure IsSNSpecificTracking(ItemTrackingCode: Record "Item Tracking Code"): Boolean
    var
        SerialSepecificTracking: Boolean;
    begin
        SerialSepecificTracking := (
            (ItemTrackingCode."SN Specific Tracking") or
            (ItemTrackingCode."SN Warehouse Tracking") or
            (ItemTrackingCode."SN Transfer Tracking") or
            (ItemTrackingCode."SN Info. Outbound Must Exist") or
            (ItemTrackingCode."SN Purchase Outbound Tracking") or
            (ItemTrackingCode."SN Sales Outbound Tracking") or
            (ItemTrackingCode."SN Pos. Adjmt. Outb. Tracking") or
            (ItemTrackingCode."SN Neg. Adjmt. Outb. Tracking") or
            (ItemTrackingCode."SN Info. Inbound Must Exist") or
            (ItemTrackingCode."SN Purchase Inbound Tracking") or
            (ItemTrackingCode."SN Sales Inbound Tracking") or
            (ItemTrackingCode."SN Pos. Adjmt. Inb. Tracking") or
            (ItemTrackingCode."SN Neg. Adjmt. Inb. Tracking"));

        if not SerialSepecificTracking then
            OnCheckIsSNSpecificTracking(ItemTrackingCode, SerialSepecificTracking);

        exit(SerialSepecificTracking);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAdjustPlanLine(var RequisitionLine: Record "Requisition Line"; var SupplyInventoryProfile: Record "Inventory Profile")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAllowScheduleIn(SupplyInvtProfile: Record "Inventory Profile"; TargetDate: Date; var CanReschedule: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAllowScheduleOut(SupplyInvtProfile: Record "Inventory Profile"; TargetDate: Date; var CanReschedule: Boolean; var TempStockkeepingUnit: Record "Stockkeeping Unit" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAllowLotAccumulation(SupplyInventoryProfile: Record "Inventory Profile"; DemandDueDate: Date; var TempStockkeepingUnit: Record "Stockkeeping Unit" temporary; var AccumulationOK: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAdjustPlanLineAfterValidateQuantity(var ReqLine: Record "Requisition Line"; var SupplyInventoryProfile: Record "Inventory Profile");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculatePlanFromWorksheet(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterForecastInitDemand(var InventoryProfile: Record "Inventory Profile"; ProductionForecastEntry: Record Microsoft.Manufacturing.Forecast."Production Forecast Entry"; ItemNo: Code[20]; LocationCode: Code[10]; TotalForecastQty: Decimal)
    begin
    end;

#if not CLEAN27
    internal procedure RunOnAfterGetRoutingFromProdOrder(var RequisitionLine: Record "Requisition Line")
    begin
        OnAfterGetRoutingFromProdOrder(RequisitionLine);
    end;

    [Obsolete('Moved to codeunit MfgInvtProfileOffsetting', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRoutingFromProdOrder(var RequisitionLine: Record "Requisition Line")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitSupply(var InventoryProfile: Record "Inventory Profile"; var StockkeepingUnit: Record "Stockkeeping Unit"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransToChildInvProfile(var ReservEntry: Record "Reservation Entry"; var ChildInvtProfile: Record "Inventory Profile")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDemandToInvProfile(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; var ReservEntry: Record "Reservation Entry"; var NextLineNo: Integer; PlanMRP: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetFiltersForSisterInventoryProfile(CurrentInventoryProfile: Record "Inventory Profile"; var SisterInventoryProfile: Record "Inventory Profile")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShallSupplyBeClosed(StockkeepingUnit: Record "Stockkeeping Unit"; SupplyInventoryProfile: Record "Inventory Profile"; DemandDueDate: Date; IsReorderPointPlanning: Boolean; var CloseSupply: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateAppliedItemEntry(var ReservationEntry: Record "Reservation Entry"; var TempItemTrackingEntry: Record "Reservation Entry"; RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMatchAttributes(var SupplyInvtProfile: Record "Inventory Profile"; var DemandInvtProfile: Record "Inventory Profile"; var TempTrkgReservEntry: Record "Reservation Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPlanItemNextStateStartOver(var SupplyInvtProfile: Record "Inventory Profile"; var SKU: Record "Stockkeeping Unit")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSupplyToInvProfile(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; var ToDate: Date; var ReservEntry: Record "Reservation Entry" temporary; var NextLineNo: Integer; var TempStockkeepingUnit: Record "Stockkeeping Unit" temporary; var TempTransferStockkeepingUnit: Record "Stockkeeping Unit" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUnfoldItemTracking(var ParentInvProfile: Record "Inventory Profile"; var ChildInvProfile: Record "Inventory Profile")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSupplyToInvProfile(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; var ToDate: Date; var ReservEntry: Record "Reservation Entry"; var NextLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateUOMFromInventoryProfile(var RequisitionLine: Record "Requisition Line"; InventoryProfile: Record "Inventory Profile"; StockkeepingUnit: Record "Stockkeeping Unit"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertTempTracking(var FromReservationEntry: Record "Reservation Entry"; var ToReservationEntry: Record "Reservation Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetQtyToHandle(var ReservationEntry: Record "Reservation Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetOrderPriority(var InventoryProfile: Record "Inventory Profile")
    begin
    end;

#if not CLEAN27
    internal procedure RunOnAfterSetProdOrder(var ReqLine: Record "Requisition Line"; var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; var InventoryProfile: Record "Inventory Profile")
    begin
        OnAfterSetProdOrder(ReqLine, ProdOrderLine, InventoryProfile);
    end;

    [Obsolete('Moved to codeunit MfgInvtProfileOffsetting', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterSetProdOrder(var ReqLine: Record "Requisition Line"; var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; var InventoryProfile: Record "Inventory Profile")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetPurchase(var PurchaseLine: Record "Purchase Line"; ReqLine: Record "Requisition Line"; var InventoryProfile: Record "Inventory Profile")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShouldDeleteReservEntry(ReservationEntry: Record "Reservation Entry"; ToDate: Date; var DeleteCondition: Boolean; TemplateName: Code[10]; WorksheetName: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferAttributes(var ToInventoryProfile: Record "Inventory Profile"; var FromInventoryProfile: Record "Inventory Profile"; var TempSKU: Record "Stockkeeping Unit" temporary; SpecificLotTracking: Boolean; SpecificSNTracking: Boolean)
    begin
    end;

#if not CLEAN25
    internal procedure RunOnAfterFindLinesWithItemToPlan(var SalesLine: Record "Sales Line"; var IsHandled: Boolean; var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; var LineNo: Integer)
    begin
        OnAfterFindLinesWithItemToPlan(SalesLine, IsHandled, InventoryProfile, Item, LineNo);
    end;

    [Obsolete('Moved to codeunit Sales Line Invt. Profile', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterFindLinesWithItemToPlan(var SalesLine: Record "Sales Line"; var IsHandled: Boolean; var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; var LineNo: Integer)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAdjustPlanLine(var RequisitionLine: Record "Requisition Line"; var SupplyInventoryProfile: Record "Inventory Profile")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBlanketOrderConsumpFind(var BlanketSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBlanketOrderConsump(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; ToDate: Date; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN25
    internal procedure RunOnBeforeCheckInsertPurchLineToProfile(var InventoryProfile: Record "Inventory Profile"; var PurchLine: Record "Purchase Line"; ToDate: Date; var IsHandled: Boolean)
    begin
        OnBeforeCheckInsertPurchLineToProfile(InventoryProfile, PurchLine, ToDate, IsHandled);
    end;

    [Obsolete('Moved to codeunit Purchase Line Invt. Profile', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckInsertPurchLineToProfile(var InventoryProfile: Record "Inventory Profile"; var PurchLine: Record "Purchase Line"; ToDate: Date; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckScheduleOut(var InventoryProfile: Record "Inventory Profile"; var TempStockkeepingUnit: Record "Stockkeeping Unit" temporary; BucketSize: DateFormula; var DampenersDays: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckUpdateInventoryProfileMaxQuantity(var InventoryProfile: Record "Inventory Profile"; var SKU: Record "Stockkeeping Unit")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCommitTracking(TempReservationEntry: Record "Reservation Entry" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCommonBalancing(var TempSKU: Record "Stockkeeping Unit" temporary; var DemandInvtProfile: Record "Inventory Profile"; var SupplyInvtProfile: Record "Inventory Profile"; PlanningStartDate: Date; ToDate: Date; var NewSupplyHasTakenOver: Boolean; var NeedOfPublishSurplus: Boolean; var FutureSupplyWithinLeadtime: Decimal; var OverflowLevel: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateSupply(var SupplyInvtProfile: Record "Inventory Profile"; var DemandInvtProfile: Record "Inventory Profile")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDecreaseQty(var SupplyInvtProfile: Record "Inventory Profile"; ReduceQty: Decimal; var SKU: Record "Stockkeeping Unit"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDemandInvtProfileInsert(var InventoryProfile: Record "Inventory Profile"; StockkeepingUnit: Record "Stockkeeping Unit")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDemandToInvProfile(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeForecastConsumption(var DemandInvtProfile: Record "Inventory Profile"; var Item: Record Item; OrderDate: Date; ToDate: Date; var UpdatedOrderDate: Date; var IsHandled: Boolean; var CurrForecast: Code[10]; var ExcludeForecastBefore: Date; var UseParm: Boolean; var LineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIncreaseQty(var SupplyInvtProfile: Record "Inventory Profile"; NeededQty: Decimal; var SKU: Record "Stockkeeping Unit")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertEmergencyOrderSupply(var SupplyInventoryProfile: Record "Inventory Profile"; var DemandInventoryProfile: Record "Inventory Profile"; var IsHandled: Boolean; var PlanningStartDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsTrkgForSpecialOrderOrDropShpt(ReservEntry: Record "Reservation Entry"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeMaintainPlanningLine(var SupplyInvtProfile: Record "Inventory Profile"; DemandInvtProfile: Record "Inventory Profile"; NewPhase: Option " ","Line Created","Routing Created",Exploded,Obsolete; Direction: Option Forward,Backward; var TrackingReservEntry: Record "Reservation Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempTransferSKUInsert(var TempTransferSKU: Record "Stockkeeping Unit" temporary; TransferLine: Record "Transfer Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTrack(var FromProfile: Record "Inventory Profile"; var ToProfile: Record "Inventory Profile"; IsSurplus: Boolean; IssueActionMessage: Boolean; Binding: Enum "Reservation Binding")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransItemLedgEntryToProfile(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; var ItemLedgerEntry: Record "Item Ledger Entry"; var IsHandled: Boolean; var LineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransShptTransLineToProfile(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; LineNo: Integer; var IsHandled: Boolean; var TransferLine: Record "Transfer Line")
    begin
    end;

#if not CLEAN25
    internal procedure RunOnBeforeTransSalesLineToProfile(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; var SalesLine: Record "Sales Line")
    begin
        OnBeforeTransSalesLineToProfile(InventoryProfile, Item, SalesLine);
    end;

    [Obsolete('Moved to codeunit Sales Line Invt. Profile', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransSalesLineToProfile(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; var SalesLine: Record "Sales Line")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnBeforeTransPurchLineToProfile(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; ToDate: Date)
    begin
        OnBeforeTransPurchLineToProfile(InventoryProfile, Item, ToDate);
    end;

    [Obsolete('Moved to codeunit Purchase Line Invt. Profile', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransPurchLineToProfile(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; ToDate: Date)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransRcptTransLineToProfile(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; ToDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMatchAttributesDemandApplicationLoop(var SupplyInventoryProfile: Record "Inventory Profile"; var DemandInventoryProfile: Record "Inventory Profile"; var SupplyExists: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateActionMessageOnReschedule(var InventoryProfile: Record "Inventory Profile"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUnfoldItemTracking(var ParentInvProfile: Record "Inventory Profile"; var ChildInvProfile: Record "Inventory Profile"; var TempItemTrkgEntry: Record "Reservation Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSupplyOnBeforeSupplyInvtProfileInsert(var SupplyInvtProfile: Record "Inventory Profile"; var SKU: Record "Stockkeeping Unit")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSupplyForwardOnBeforeSupplyInvtProfileInsert(var SupplyInvtProfile: Record "Inventory Profile"; var SKU: Record "Stockkeeping Unit")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSupplyForInitialSafetyStockWarningOnBeforeSupplyInventoryProfileInsert(var SupplyInvtProfile: Record "Inventory Profile"; var SKU: Record "Stockkeeping Unit")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnEndMatchAttributesDemandApplicationLoop(var SupplyInventoryProfile: Record "Inventory Profile"; var DemandInventoryProfile: Record "Inventory Profile"; var SupplyExists: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnStartOfMatchAttributesDemandApplicationLoop(var SupplyInventoryProfile: Record "Inventory Profile"; var DemandInventoryProfile: Record "Inventory Profile"; var SupplyExists: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnScheduleAllOutChangesSequenceOnBeforeSupplyInvtProfileInsert(var SupplyInvtProfile: Record "Inventory Profile")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrePlanDateApplicationLoop(var SupplyInventoryProfile: Record "Inventory Profile"; var DemandInventoryProfile: Record "Inventory Profile"; var SupplyExists: Boolean; var DemandExists: Boolean; var LastProjectedInventory: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnStartOfPrePlanDateApplicationLoop(var SupplyInventoryProfile: Record "Inventory Profile"; var DemandInventoryProfile: Record "Inventory Profile"; var SupplyExists: Boolean; var DemandExists: Boolean; var IncrementLastProjectedInventory: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrePlanDateDemandProc(var SupplyInventoryProfile: Record "Inventory Profile"; var DemandInventoryProfile: Record "Inventory Profile"; var SupplyExists: Boolean; var DemandExists: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrePlanDateSupplyProc(var SupplyInventoryProfile: Record "Inventory Profile"; var DemandInventoryProfile: Record "Inventory Profile"; var SupplyExists: Boolean; var DemandExists: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePlanItemNextStateMatchDates(var DemandInventoryProfile: Record "Inventory Profile"; var SupplyInventoryProfile: Record "Inventory Profile"; NextState: Option; var IsHandled: Boolean; var ShouldCalcNewSupplyDate: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPrePlanDateSupplyProc(var SupplyInventoryProfile: Record "Inventory Profile"; var DemandInventoryProfile: Record "Inventory Profile"; var SupplyExists: Boolean; var DemandExists: Boolean; var TempSKU: Record "Stockkeeping Unit" temporary; var TempTrkgReservEntry: Record "Reservation Entry" temporary; var ReqLine: Record "Requisition Line"; var DoInsertInsertSupplyForEmergencyOrder: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecalculateReqLine(var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePlanStepSettingOnStartOver(var SupplyInventoryProfile: Record "Inventory Profile"; var DemandInventoryProfile: Record "Inventory Profile"; var SupplyExists: Boolean; var DemandExists: Boolean; var NextState: Option; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN27
    [Obsolete('Replaced by event OnBeforeCalculatePlanFromWorksheet2', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculatePlanFromWorksheet(var Item: Record Item; ManufacturingSetup2: Record Microsoft.Manufacturing.Setup."Manufacturing Setup"; TemplateName: Code[10]; WorksheetName: Code[10]; OrderDate: Date; ToDate: Date; MRPPlanning: Boolean; RespectPlanningParm: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculatePlanFromWorksheet2(var Item: Record Item; TemplateName: Code[10]; WorksheetName: Code[10]; OrderDate: Date; ToDate: Date; MRPPlanning: Boolean; RespectPlanningParm: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertSafetyStockDemands(var DemandInvtProfile: Record "Inventory Profile"; xDemandInvtProfile: Record "Inventory Profile"; var TempSafetyStockInvtProfile: Record "Inventory Profile" temporary; var TempStockkeepingUnit: Record "Stockkeeping Unit" temporary; var PlanningStartDate: Date; var PlanToDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindCombinationAfterAssignTempSKU(var TempStockkeepingUnit: Record "Stockkeeping Unit" temporary; InventoryProfile: Record "Inventory Profile")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostInvChgReminder(var InventoryProfileChangeReminder: Record "Inventory Profile"; var InventoryProfile: Record "Inventory Profile"; PostOnlyMinimum: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPlanItemNextStateCloseDemand(var SupplyInventoryProfile: Record "Inventory Profile"; var SupplyExists: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostInvChgReminder(var InventoryProfileChangeReminder: Record "Inventory Profile"; var InventoryProfile: Record "Inventory Profile"; PostOnlyMinimum: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAdjustReorderQty(OrderQty: Decimal; var SKU: Record "Stockkeeping Unit"; SupplyLineNo: Integer; MinQty: Decimal; var DeltaQty: Decimal; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempSKUInsert(var TempSKU: Record "Stockkeeping Unit"; var PlanningGetParameters: Codeunit "Planning-Get Parameters")
    begin
    end;

#if not CLEAN25
    internal procedure RunOnBeforeTransProdOrderCompToProfile(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; var IsHandled: Boolean)
    begin
        OnBeforeTransProdOrderCompToProfile(InventoryProfile, Item, IsHandled);
    end;

    [Obsolete('Moved to codeunit Prod. Order Comp Invt.Profile', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransProdOrderCompToProfile(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnEndOfPrePlanDateApplicationLoop(var SupplyInventoryProfile: Record "Inventory Profile"; var DemandInventoryProfile: Record "Inventory Profile"; var SupplyExists: Boolean; var DemandExists: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMaintainPlanningLineOnAfterReqLineInsert(var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMaintainPlanningLineOnBeforeReqLineInsert(var RequisitionLine: Record "Requisition Line"; var SupplyInvtProfile: Record "Inventory Profile"; PlanToDate: Date; CurrentForecast: Code[10]; NewPhase: Option " ","Line Created","Routing Created",Exploded,Obsolete; Direction: Option Forward,Backward; var DemandInvtProfile: Record "Inventory Profile"; ExcludeForecastBefore: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPlanItemNextStateCloseDemandOnBeforeDemandInvtProfileDelete(DemandInventoryProfile: Record "Inventory Profile"; RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPlanItemOnBeforeSumDemandInvtProfile(DemandInvtProfile: Record "Inventory Profile"; var IsHandled: Boolean; PlanningStartDate: Date; var LastProjectedInventory: Decimal; var LastAvailableInventory: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPlanItemOnBeforePlanThisSKULoop(var StockkeepingUnit: Record "Stockkeeping Unit"; var DemandInventoryProfile: Record "Inventory Profile")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPlanItemOnBeforePlanThisSKULoopIteration(var StockkeepingUnit: Record "Stockkeeping Unit"; NextState: Option; var DemandInventoryProfile: Record "Inventory Profile"; var SupplyInventoryProfile: Record "Inventory Profile"; var SupplyExists: Boolean; var DemandExists: Boolean; var LotAccumulationPeriodStartDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPlanItemOnBeforeSumSupplyInvtProfile(SupplyInvtProfile: Record "Inventory Profile"; var IsHandled: Boolean; var LastProjectedInventory: Decimal; var LastAvailableInventory: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPlanItemAfterCalcIsReorderPointPlanning(var TempSKU: Record "Stockkeeping Unit"; var IsReorderPointPlanning: Boolean; var RequisitionLine: Record "Requisition Line"; var PlanningTransparency: Codeunit "Planning Transparency"; PlanningResilicency: Boolean; var CurrTemplateName: Code[10]; var CurrWorksheetName: Code[10]; var PlanningStartDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAppliedItemEntryOnBeforeFindApplEntry(var TempItemTrackingEntry: Record "Reservation Entry"; var ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMaintainProjectedInventory(var ReminderInvtProfile: Record "Inventory Profile"; AtDate: Date; var LastProjectedInventory: Decimal; var LatestBucketStartDate: Date; var ROPHasBeenCrossed: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMaintainPlanningLineOnAfterLineCreated(var SupplyInvtProfile: Record "Inventory Profile"; var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMaintainPlanningLineOnBeforeSupplyInvtProfileInsert(var SupplyInventoryProfile: Record "Inventory Profile"; CurrentSupplyInvtProfile: Record "Inventory Profile")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculatePlanFromWorksheetOnAfterPlanItem(CurrTemplateName: Code[10]; CurrWorksheetName: Code[10]; var Item: Record Item; var RequisitionLine: Record "Requisition Line"; var TrackingReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculatePlanFromWorksheetOnAfterForecastConsumption(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; var OrderDate: Date; var ToDate: Date; var LineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcReorderQtyOnCaseElse(var QtyToOrder: Decimal; NeededQty: Decimal; ProjectedInventory: Decimal; SupplyLineNo: Integer; TempSKU: Record "Stockkeeping Unit"; PlanningResilicency: Boolean; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnForecastConsumptionOnBeforeFindDemandInvtProfile(var DemandInventoryProfile: Record "Inventory Profile"; ComponentForecast: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnForecastConsumptionOnAfterCalcDueDate(var DemandInventoryProfile: Record "Inventory Profile"; TotalForecastQty: Decimal; ForecastEntry: Record Microsoft.Manufacturing.Forecast."Production Forecast Entry"; NextForecastEntry: Record Microsoft.Manufacturing.Forecast."Production Forecast Entry"; var Item: Record Item; OrderDate: Date; ToDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnForecastConsumptionOnAfterSetSalesSourceTypeFilter(var DemandInventoryProfile: Record "Inventory Profile")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnForecastConsumptionOnAfterSetPlanningSourceTypeFilter(var DemandInventoryProfile: Record "Inventory Profile")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindReplishmentLocationOnBeforeFindSKU(var StockkeepingUnit: Record "Stockkeeping Unit")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindNextSKUOnAfterAssignTempSKU(var TempSKU: Record "Stockkeeping Unit" temporary; var InventoryProfile: Record "Inventory Profile")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMaintainPlanningLineOnBeforeAdjustPlanLine(var RequisitionLine: Record "Requisition Line"; InventoryProfile: Record "Inventory Profile"; StockkeepingUnit: Record "Stockkeeping Unit")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMaintainPlanningLineOnBeforeValidateNo(var RequisitionLine: Record "Requisition Line"; InventoryProfile: Record "Inventory Profile"; StockkeepingUnit: Record "Stockkeeping Unit")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMaintainPlanningLineOnAfterValidateFieldsForNewReqLine(var RequisitionLine: Record "Requisition Line"; InventoryProfile: Record "Inventory Profile"; StockkeepingUnit: Record "Stockkeeping Unit")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMaintainPlanningLineOnAfterSetSourceForNotNewReqLine(var RequisitionLine: Record "Requisition Line"; var InventoryProfile: Record "Inventory Profile")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareTempTrackingOnBeforeInsertTempTracking(var FromReservEntry: Record "Reservation Entry"; var ToReservEntry: Record "Reservation Entry"; IsSurplus: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetAcceptActionOnBeforeAcceptActionMsg(var RequisitionLine: Record "Requisition Line"; var AcceptActionMsg: Boolean; var PlanningTransparency: Codeunit "Planning Transparency")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAdjustTransferDatesOnBeforeTransferReqLineModify(var RequisitionLine: Record "Requisition Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIncreaseQtyToMeetDemand(var SupplyInvtProfile: Record "Inventory Profile"; DemandInvtProfile: Record "Inventory Profile"; CheckSourceType: Boolean; var Result: Boolean; var IsHandled: Boolean; var TempStockkeepingUnit: Record "Stockkeeping Unit" temporary);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertPlanningComponent(var PlanningComponent: Record "Planning Component");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcOrderQty(TempSKU: Record "Stockkeeping Unit" temporary; NeededQty: Decimal; ProjectedInventory: Decimal; SupplyLineNo: Integer; var QtyToOrder: Decimal);
    begin
    end;

#if not CLEAN27
    internal procedure RunOnAfterGetComponents(var RequisitionLine: Record "Requisition Line");
    begin
        OnAfterGetComponents(RequisitionLine);
    end;

    [Obsolete('Moved to codeunit MfgInvtProfileOffsetting', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetComponents(var RequisitionLine: Record "Requisition Line");
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertInitialSafetyStockWarningSupply(var SupplyInvtProfile: Record "Inventory Profile"; var LastAvailableInventory: Decimal; var LastProjectedInventory: Decimal; PlanningStartDate: Date; RespectPlanningParm: Boolean; var IsReorderPointPlanning: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculatePlanFromWorksheetOnBeforeUnfoldItemTracking(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; ToDate: Date; var LineNo: Integer; var TempTrkgReservEntry: Record "Reservation Entry" temporary);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAdjustTransferDates(TransferReqLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFillSkUBuffer(var SKU: Record "Stockkeeping Unit"; var TempSKU: Record "Stockkeeping Unit" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertInventoryProfile(RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPlanItemOnAfterTempSKULoop(var TempSKU: Record "Stockkeeping Unit"; var ReqLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSyncTransferDemandWithReqLineOnAfterSetFilters(var TransferReqLine: Record "Requisition Line"; var InventoryProfile: Record "Inventory Profile"; LocationCode: Code[10]; CurrTemplateName: Code[10]; CurrWorksheetName: Code[10])
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnFindCombinationOnBeforeSKUFindSet(var SKU: Record "Stockkeeping Unit"; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindCombinationOnBeforeFilterDemandAndSupply(var DemandInvtProfile: Record "Inventory Profile"; var SupplyInvtProfile: Record "Inventory Profile")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPlanItemSetInvtProfileFilters(var DemandInvtProfile: Record "Inventory Profile"; var SupplyInvtProfile: Record "Inventory Profile")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPlanItemOnBeforeTempSKUFind(var TempSKU: Record "Stockkeeping Unit" temporary; var PlanningStartDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTrack(FromProfile: Record "Inventory Profile"; ToProfile: Record "Inventory Profile"; IsSurplus: Boolean; IssueActionMessage: Boolean; Binding: Enum "Reservation Binding")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferPlanningParameters(var SKU: Record "Stockkeeping Unit")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertTempSKU(var TempSKU: Record "Stockkeeping Unit" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindCombination(var DemandInvtProfile: Record "Inventory Profile"; var SupplyInvtProfile: Record "Inventory Profile")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitVariables(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindCombinationOnBeforeSetState(var TempSKU: Record "Stockkeeping Unit" temporary; var Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetRoutingOnAfterSetResiliencyOn(var ReqLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateReqLineQuantity(var ReqLine: Record "Requisition Line"; var SupplyInventoryProfile: Record "Inventory Profile"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateReqLineOriginalQuantity(var ReqLine: Record "Requisition Line"; var SupplyInventoryProfile: Record "Inventory Profile"; var IsHandled: Boolean; TempStockkeepingUnit: Record "Stockkeeping Unit" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMaintainPlanningLineOnAfterPopulateReqLineFields(var ReqLine: Record "Requisition Line"; var SupplyInvtProfile: Record "Inventory Profile"; DemandInvtProfile: Record "Inventory Profile"; NewPhase: Option " ","Line Created","Routing Created",Exploded,Obsolete; Direction: Option Forward,Backward; var TempSKU: Record "Stockkeeping Unit"; CurrTemplateName: Code[10]; CurrWorksheetName: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMaintainPlanningLineOnBeforeReqLineModify(var ReqLine: Record "Requisition Line"; var SupplyInvtProfile: Record "Inventory Profile")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMaintainPlanningLine(var ReqLine: Record "Requisition Line"; SupplyInvtProfile: Record "Inventory Profile"; NewPhase: Option " ","Line Created","Routing Created",Exploded,Obsolete)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTrackBeforePrepareTempTracking(var TrkgReservEntryArray: array[6] of Record "Reservation Entry"; SplitState: Option; var IsSurplus: Boolean; var IssueActionMessage: Boolean; var Binding: Enum "Reservation Binding")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransItemLedgEntryToProfileOnBeforeTransferFromItemLedgerEntry(var Item: Record Item; var ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransItemLedgEntryToProfileOnAfterTransferFromItemLedgerEntry(var Item: Record Item; var ItemLedgerEntry: Record "Item Ledger Entry"; var InventoryProfile: Record "Inventory Profile")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransItemLedgEntryToProfileOnAfterInsertInventoryProfile(var Item: Record Item; var ItemLedgerEntry: Record "Item Ledger Entry"; var InventoryProfile: Record "Inventory Profile")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransShptTransLineToProfileOnBeforeTransferFromOutboundTransfer(var Item: Record Item; var TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransShptTransLineToProfileOnAfterTransferFromOutboundTransfer(var Item: Record Item; var TransferLine: Record "Transfer Line"; var InventoryProfile: Record "Inventory Profile")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransShptTransLineToProfileOnAfterInventoryProfileInsert(var Item: Record Item; var TransferLine: Record "Transfer Line"; var InventoryProfile: Record "Inventory Profile")
    begin
    end;

#if not CLEAN25
    internal procedure RunOnTransSalesLineToProfileOnBeforeTransferFromSalesLineOrder(var Item: Record Item; var SalesLine: Record "Sales Line")
    begin
        OnTransSalesLineToProfileOnBeforeTransferFromSalesLineOrder(Item, SalesLine);
    end;

    [Obsolete('Moved to codeunit Sales Line Invt. Profile', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnTransSalesLineToProfileOnBeforeTransferFromSalesLineOrder(var Item: Record Item; var SalesLine: Record "Sales Line")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnTransSalesLineToProfileOnAfterTransferFromSalesLineOrder(var Item: Record Item; var SalesLine: Record "Sales Line"; var InventoryProfile: Record "Inventory Profile")
    begin
        OnTransSalesLineToProfileOnAfterTransferFromSalesLineOrder(Item, SalesLine, InventoryProfile);
    end;

    [Obsolete('Moved to codeunit Sales Line Invt. Profile', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnTransSalesLineToProfileOnAfterTransferFromSalesLineOrder(var Item: Record Item; var SalesLine: Record "Sales Line"; var InventoryProfile: Record "Inventory Profile")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnTransSalesLineToProfileOnAfterInsertInventoryProfileFromOrder(var Item: Record Item; var SalesLine: Record "Sales Line"; var InventoryProfile: Record "Inventory Profile")
    begin
        OnTransSalesLineToProfileOnAfterInsertInventoryProfileFromOrder(Item, SalesLine, InventoryProfile);
    end;

    [Obsolete('Moved to codeunit Sales Line Invt. Profile', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnTransSalesLineToProfileOnAfterInsertInventoryProfileFromOrder(var Item: Record Item; var SalesLine: Record "Sales Line"; var InventoryProfile: Record "Inventory Profile")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnTransSalesLineToProfileOnAfterInsertInventoryProfileFromReturnOrder(var Item: Record Item; var SalesLine: Record "Sales Line"; var InventoryProfile: Record "Inventory Profile")
    begin
        OnTransSalesLineToProfileOnAfterInsertInventoryProfileFromReturnOrder(Item, SalesLine, InventoryProfile);
    end;

    [Obsolete('Moved to codeunit Sales Line Invt. Profile', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnTransSalesLineToProfileOnAfterInsertInventoryProfileFromReturnOrder(var Item: Record Item; var SalesLine: Record "Sales Line"; var InventoryProfile: Record "Inventory Profile")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnTransSalesLineToProfileOnBeforeTransferFromSalesLineReturnOrder(var Item: Record Item; var SalesLine: Record "Sales Line")
    begin
        OnTransSalesLineToProfileOnBeforeTransferFromSalesLineReturnOrder(Item, SalesLine);
    end;

    [Obsolete('Moved to codeunit Sales Line Invt. Profile', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnTransSalesLineToProfileOnBeforeTransferFromSalesLineReturnOrder(var Item: Record Item; var SalesLine: Record "Sales Line")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnTransSalesLineToProfileOnAfterTransferFromSalesLineReturnOrder(var Item: Record Item; var SalesLine: Record "Sales Line"; var InventoryProfile: Record "Inventory Profile")
    begin
        OnTransSalesLineToProfileOnAfterTransferFromSalesLineReturnOrder(Item, SalesLine, InventoryProfile);
    end;

    [Obsolete('Moved to codeunit Sales Line Invt. Profile', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnTransSalesLineToProfileOnAfterTransferFromSalesLineReturnOrder(var Item: Record Item; var SalesLine: Record "Sales Line"; var InventoryProfile: Record "Inventory Profile")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnMaintainPlanLineOnAfterAdjustPlanLine(var TempSKU: Record "Stockkeeping Unit" temporary; var RequisitionLine: Record "Requisition Line"; var SupplyInvtProfile: Record "Inventory Profile"; DemandInvtProfile: Record "Inventory Profile"; PlanToDate: Date; CurrentForecast: Code[10]; NewPhase: Option " ","Line Created","Routing Created",Exploded,Obsolete; Direction: Option Forward,Backward)
    begin
    end;

#if not CLEAN25
    internal procedure RunOnBeforeTransPlanningCompToProfile(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; var IsHandled: Boolean)
    begin
        OnBeforeTransPlanningCompToProfile(InventoryProfile, Item, IsHandled);
    end;

    [Obsolete('Moved to codeunit Plng. Component Invt. Profile', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransPlanningCompToProfile(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterCanDecreaseSupply(InventoryProfile: Record "Inventory Profile"; ReduceQty: Decimal; DampenerQty: Decimal; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPlanItemOnBeforeSupplyInvtProfileModify(var SupplyInvtProfileP: Record "Inventory Profile")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPlanItemNextStateMatchDatesOnBeforeCheckScheduleOut(var SupplyInvtProfile: Record "Inventory Profile"; var LimitedHorizon: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDemandMatchedSupplyOnAfterSetFiltersToInvProfile(var ToInventoryProfile: Record "Inventory Profile"; FromInventoryProfile: Record "Inventory Profile")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateOriginalDueDate(SupplyInventoryProfile: Record "Inventory Profile"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetTransferOnBeforeTransferFromTransLine(InventoryProfile: Record "Inventory Profile"; RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateTempSKUForComponentsLocation(var Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTempSKUForComponentsLocationOnBeforeSetLocationCodeFilter(Item: Record Item; var StockkeepingUnit: Record "Stockkeeping Unit"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateTempSKUForLocation(var TempStockkeeping: Record "Stockkeeping Unit" temporary; LocationCode: Code[10]; var IsHandled: Boolean; ItemNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertSafetyStockDemandsOnBeforeCreateDemand(DemandInvtProfile: Record "Inventory Profile"; var PlanningStartDate: Date; var TempStockkeepingUnit: Record "Stockkeeping Unit" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcMaximumReorderQty(var TempStockkeepingUnit: Record "Stockkeeping Unit" temporary; var RequisitionLine: Record "Requisition Line"; PlanningResiliency: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransShptTransLineToProfileOnBeforeProcessLine(TransferLine: Record "Transfer Line"; var ShouldProcess: Boolean; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSupplyOnAfterInitSupply(var SupplyInvtProfile: Record "Inventory Profile"; DemandInvtProfile: Record "Inventory Profile")
    begin
    end;

#if not CLEAN27
    internal procedure RunOnFindCombinationOnBeforeCreateTempSKUForLocation(var Item: Record Item; var IsHandled: Boolean)
    begin
        OnFindCombinationOnBeforeCreateTempSKUForLocation(Item, IsHandled);
    end;

    [Obsolete('Moved to codeunit MfgInvtProfileOffsetting', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnFindCombinationOnBeforeCreateTempSKUForLocation(var Item: Record Item; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnPlanItemNextStateCreateSupplyOnAfterCalcNewSupplyDate(var NewSupplyDate: Date; var TempStockkeepingUnit: Record "Stockkeeping Unit" temporary; var SupplyInvtProfile: Record "Inventory Profile")
    begin
    end;

#if not CLEAN25
    internal procedure RunOnTransPlanningCompToProfileOnBeforeInventoryProfileInsert(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; var LineNo: Integer)
    begin
        OnTransPlanningCompToProfileOnBeforeInventoryProfileInsert(InventoryProfile, Item, LineNo);
    end;

    [Obsolete('Moved to codeunit Plng. Component Invt. Profile', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnTransPlanningCompToProfileOnBeforeInventoryProfileInsert(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; var LineNo: Integer)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnTransRcptTransLineToProfileOnBeforeProcessLine(TransferLine: Record "Transfer Line"; var ShouldProcess: Boolean; var Item: Record Item)
    begin
    end;

#if not CLEAN27
    internal procedure RunOnTransProdOrderToProfileOnBeforeProcessLine(ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; var ShouldProcess: Boolean)
    begin
        OnTransProdOrderToProfileOnBeforeProcessLine(ProdOrderLine, ShouldProcess);
    end;

    [Obsolete('Moved to codeunit MfgInvtProfileOffsetting', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnTransProdOrderToProfileOnBeforeProcessLine(ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; var ShouldProcess: Boolean)
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnTransServLineToProfileOnBeforeProcessLine(ServiceLine: Record Microsoft.Service.Document."Service Line"; var ShouldProcess: Boolean; var Item: REcord Item)
    begin
        OnTransServLineToProfileOnBeforeProcessLine(ServiceLine, ShouldProcess, Item);
    end;

    [Obsolete('Moved to codeunit Service Line Invt. Profile', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnTransServLineToProfileOnBeforeProcessLine(ServiceLine: Record Microsoft.Service.Document."Service Line"; var ShouldProcess: Boolean; var Item: REcord Item)
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnTransJobPlanningLineToProfileOnBeforeProcessLine(JobPlanningLine: Record Microsoft.Projects.Project.Planning."Job Planning Line"; var ShouldProcess: Boolean)
    begin
        OnTransJobPlanningLineToProfileOnBeforeProcessLine(JobPlanningLine, ShouldProcess);
    end;

    [Obsolete('Moved to codeunit Job Planning Invt. Profile', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnTransJobPlanningLineToProfileOnBeforeProcessLine(JobPlanningLine: Record Microsoft.Projects.Project.Planning."Job Planning Line"; var ShouldProcess: Boolean)
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnTransSalesLineToProfileOnBeforeProcessLine(SalesLine: Record "Sales Line"; var ShouldProcess: Boolean; var Item: Record Item)
    begin
        OnTransSalesLineToProfileOnBeforeProcessLine(SalesLine, ShouldProcess, Item);
    end;

    [Obsolete('Moved to codeunit Sales Line Invt. Profile', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnTransSalesLineToProfileOnBeforeProcessLine(SalesLine: Record "Sales Line"; var ShouldProcess: Boolean; var Item: Record Item)
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnTransProdOrderCompToProfileOnBeforeProcessLine(ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component"; var ShouldProcess: Boolean)
    begin
        OnTransProdOrderCompToProfileOnBeforeProcessLine(ProdOrderComp, ShouldProcess);
    end;

    [Obsolete('Moved to codeunit Prod. Order Comp. Invt. Profile', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnTransProdOrderCompToProfileOnBeforeProcessLine(ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component"; var ShouldProcess: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnMaintainPlanningLineOnAfterCopyDatesToInvtProfile(var SupplyInvtProfile: Record "Inventory Profile"; var RequisitionLine: Record "Requisition Line")
    begin
    end;

#if not CLEAN25
    internal procedure RunOnTransSalesLineToProfileOnBeforeInvProfileInsert(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; var LineNo: Integer)
    begin
        OnTransSalesLineToProfileOnBeforeInvProfileInsert(InventoryProfile, Item, LineNo);
    end;

    [Obsolete('Moved to codeunit Sales Line Invt. Profile', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnTransSalesLineToProfileOnBeforeInvProfileInsert(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; var LineNo: Integer)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnCheckScheduleOutOnNotAllowScheduleOut(var SupplyInvtProfile: Record "Inventory Profile"; var ShouldExitAllowLotAccumulation: Boolean)
    begin
    end;

#if not CLEAN25
    internal procedure RunOnTransProdOrderCompToProfileOnBeforeInvProfileInsert(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; var LineNo: Integer)
    begin
        OnTransProdOrderCompToProfileOnBeforeInvProfileInsert(InventoryProfile, Item, LineNo);
    end;

    [Obsolete('Moved to codeunit Prod. Order Comp Invt.Profile', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnTransProdOrderCompToProfileOnBeforeInvProfileInsert(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; var LineNo: Integer)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnMaintainPlanningLineOnAfterCalcPlanLineNo(RequisitionLine: Record "Requisition Line"; var PlanLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetAcceptActionOnCaseRefOrderTypeTransfer(ReqLine: Record "Requisition Line"; var AcceptActionMsg: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPlanSKU(var StockkeepingUnit: Record "Stockkeeping Unit"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSupplyAndTrack(var InventoryProfileFromDemand: Record "Inventory Profile"; var InventoryProfileFromSupply: Record "Inventory Profile")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareOrderToOrderLinkOnBeforeInventoryProfileModify(var InventoryProfile: Record "Inventory Profile"; var TempSKU: Record "Stockkeeping Unit" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPlanItemOnBeforeInitSupply(LastProjectedInventory: Decimal; SupplyWithinLeadtime: Decimal; var TempSKU: Record "Stockkeeping Unit" temporary; var IsHandled: Boolean; var PlanningStartDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAdjustReorderQty(OrderQty: Decimal; var SKU: Record "Stockkeeping Unit"; SupplyLineNo: Integer; MinQty: Decimal; var DeltaQty: Decimal);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckScheduleOutOnBeforeAllowLotAccumulation(PossibleDate: Date; TargetDate: Date; SupplyInvtProfile: Record "Inventory Profile"; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckScheduleIn(var InventoryProfile: Record "Inventory Profile"; var TempStockkeepingUnit: Record "Stockkeeping Unit" temporary; TargetDate: date; var PossibleDate: Date; LimitedHorizon: Boolean; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPlanItemOnBeforeCreateSupplyForward(var TempStockkeepingUnit: Record "Stockkeeping Unit" temporary; var SupplyInventoryProfile: Record "Inventory Profile"; var DemandInventoryProfile: Record "Inventory Profile"; var TempReminderInventoryProfile: Record "Inventory Profile" temporary; PlanningStartDate: Date; LastAvailableInventory: Decimal; LastProjectedInventory: Decimal; var NewSupplyHasTakenOver: Boolean; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFromLotAccumulationPeriodStartDate(LotAccumulationPeriodStartDate: Date; DemandDueDate: Date; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRescheduleOnBeforeModifySupplyInvtProfile(var SupplyInventoryProfile: Record "Inventory Profile"; TargetDate: Date; TargetTime: Time);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPlanItemOnBeforeInsertSafetyStockDemands(var InventoryProfile: Record "Inventory Profile"; var TempStockkeepingUnit: Record "Stockkeeping Unit" temporary; var DoUpdatePriorities: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertEmergencyOrderSupplyOnAfterInitSupply(var SupplyInventoryProfile: Record "Inventory Profile"; var DemandInventoryProfile: Record "Inventory Profile")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMatchAttributesOnAfterInitSupply(var SupplyInventoryProfile: Record "Inventory Profile"; var DemandInventoryProfile: Record "Inventory Profile")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePlanItemNextStateMatchQty(var SupplyInventoryProfile: Record "Inventory Profile"; var DemandInventoryProfile: Record "Inventory Profile"; var NextState: Option StartOver,MatchDates,MatchQty,CreateSupply,ReduceSupply,CloseDemand,CloseSupply,CloseLoop; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPlanItemSetInvtProfileFiltersOnBeforeSetCurrentKeys(var SupplyInventoryProfile: Record "Inventory Profile"; var DemandInventoryProfile: Record "Inventory Profile"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPlanItemNextStateCloseSupplyOnBeforeUpdateDemandUntrackedQty(var SupplyInventoryProfile: Record "Inventory Profile"; var DemandInventoryProfile: Record "Inventory Profile"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPlanItemNextStateCloseSupplyOnBeforeProcessActionMessageNew(var SupplyInventoryProfile: Record "Inventory Profile"; var DemandInventoryProfile: Record "Inventory Profile"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPlanItemNextStateCloseSupplyOnAfterCheckSupplyExist(var SupplyInventoryProfile: Record "Inventory Profile"; SupplyExist: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckForecastExist(var ProductionForecastEntry: Record Microsoft.Manufacturing.Forecast."Production Forecast Entry"; ExcludeForecastBefore: Date; OrderDate: Date; ToDate: Date; var ForecastExist: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetSupplyPriority(var InventoryProfile: Record "Inventory Profile")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetDemandPriority(var InventoryProfile: Record "Inventory Profile")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCommitTracking(var TempReservationEntryItemTrkgEntry: Record "Reservation Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransRcptTransLineToProfileOnAfterInsertInventoryProfile(var TransferLine: Record "Transfer Line"; var InventoryProfile: Record "Inventory Profile")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPlanItemNextStateMatchDatesOnAfterCalcNewSupplyDate(var NewSupplyDate: Date; var TempStockkeepingUnit: Record "Stockkeeping Unit" temporary; var SupplyInvtProfile: Record "Inventory Profile"; LotAccumulationPeriodStartDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterFilterDemandSupplyRelatedToSKU(var InventoryProfile: Record "Inventory Profile"; var TempStockkeepingUnit: Record "Stockkeeping Unit" temporary)
    begin
    end;

#if not CLEAN27
    internal procedure RunOnBeforeTransProdOrderToProfile(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; ToDate: Date; var IsHandled: Boolean)
    begin
        OnBeforeTransProdOrderToProfile(InventoryProfile, Item, ToDate, IsHandled);
    end;

    [Obsolete('Moved to codeunit MfgInvtProfileOffsetting', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransProdOrderToProfile(var InventoryProfile: Record "Inventory Profile"; var Item: Record Item; ToDate: Date; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnGetComponentsOnNewActionMessage(var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnGetComponentsOnUpdateForActionMessage(var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPlanItemOnBeforeCheckSupplyWithinLeadtime(var SupplyInventoryProfile: Record "Inventory Profile"; var DemandInventoryProfile: Record "Inventory Profile"; var SupplyExists: Boolean; var DemandExists: Boolean; var TempStockkeepingUnit: Record "Stockkeeping Unit" temporary; var TempTrkgReservationEntry: Record "Reservation Entry" temporary; var RequisitionLine: Record "Requisition Line"; var DoCheckSupplyWithinLeadtime: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckIsLotSpecificTracking(ItemTrackingCode: Record "Item Tracking Code"; var LotSepecificTracking: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckIsSNSpecificTracking(ItemTrackingCode: Record "Item Tracking Code"; var SNSepecificTracking: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDisableRelations(var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsProdOrderPlanned(var ReservEntry: Record "Reservation Entry"; var Planned: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetComponentsAtLocationCode(var LocationCode: Code[10])
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnGetComponents(var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnGetRouting(var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnFillTempSKUForLocation(var Item: Record Item; var SupplyInvtProfile: Record "Inventory Profile")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTempSKUForComponentsLocationOnBeforeItemCopyFilter(var StockkeepingUnit: Record "Stockkeeping Unit"; var Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAdjustTransferDatesOnAfterInboundWhseTimeSet(var TransferRequisitionLine: Record "Requisition Line"; var Location: Record Location; var InboundWhseTime: DateFormula)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMatchAttributes(var SupplyInvtProfile: Record "Inventory Profile"; var DemandInvtProfile: Record "Inventory Profile"; var SkipMatchingAttributes: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPlanItemOnAfterCheckDemandMatchedSupplyPlanThisSKU(var DemandInventoryProfile: Record "Inventory Profile"; var SupplyInventoryProfile: Record "Inventory Profile"; PlanThisSKU: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnScheduleAllOutChangesSequenceOnBeforeCheckIfRescheduleIsNeeded(SupplyInventoryProfile: Record "Inventory Profile"; var NextRecExists: Integer; var IsHandled: Boolean; NewDate: Date; var NumberofSupplies: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSupplyForwardOnBeforeLoopQtyToOrderMoreThanZero(var TempStockkeepingUnit: Record "Stockkeeping Unit" temporary; var QtoToOrder: Decimal; SupplyWithinLeadtime: Decimal; var SupplyInvtProfile: Record "Inventory Profile")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCommitTrackingOnAfterInsertReservationEntry(var ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransRcptTransLineToProfileOnBeforeInsertSupplyInvtProfile(var InventoryProfile: Record "Inventory Profile"; TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPlanItemOnAfterInitLatestBucketStartDate(var LatestBucketStartDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertEmergencyOrderSupply(var SupplyInventoryProfile: Record "Inventory Profile"; var DemandInventoryProfile: Record "Inventory Profile"; var PlanningStartDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPlanItemOnAfterCreateInitialReorderPointSupply(var PlanningStartDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateSupplyForInitialSafetyStockWarning(var PlanningStartDate: Date; var SupplyInventoryProfile: Record "Inventory Profile")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSumUpProjectedSupply(var SupplyInventoryProfile: Record "Inventory Profile"; var FromDate: Date; var ToDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSumUpAvailableSupply(var SupplyInventoryProfile: Record "Inventory Profile"; var FromDate: Date; var ToDate: Date)
    begin
    end;
}
