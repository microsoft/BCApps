// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Availability;

using Microsoft.Assembly.Document;
using Microsoft.Foundation.Calendar;
using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Projects.Project.Planning;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;

codeunit 5790 "Available to Promise"
{
    Permissions = tabledata "Assembly Header" = r,
                  tabledata "Assembly Line" = r,
                  tabledata "Item Ledger Entry" = r,
                  tabledata "Job Planning Line" = r,
                  tabledata "Planning Component" = r,
#if not CLEAN27
                  tabledata Microsoft.Manufacturing.Document."Prod. Order Component" = r,
                  tabledata Microsoft.Manufacturing.Document."Prod. Order Line" = r,
#endif
                  tabledata "Purchase Line" = r,
                  tabledata "Requisition Line" = r,
                  tabledata "Reservation Entry" = r,
                  tabledata "Sales Line" = r,
                  tabledata "Transfer Line" = r,
                  tabledata "Value Entry" = r;

    trigger OnRun()
    begin
    end;

    var
        ChangedSalesLine: Record "Sales Line";
        CurrentOrderPromisingLine: Record "Order Promising Line";
        ChangedAssemblyLine: Record "Assembly Line";
        OldRecordExists: Boolean;
        ReqShipDate: Date;
        AllFieldCalculated: Boolean;
        PrevItemNo: Code[20];
        PrevItemFilters: Text;

    procedure SetRecalculateFields()
    begin
        AllFieldCalculated := false;
    end;

    procedure CalcQtyAvailableToPromise(var Item: Record Item; var GrossRequirement: Decimal; var ScheduledReceipt: Decimal; AvailabilityDate: Date; PeriodType: Enum "Analysis Period Type"; LookaheadDateFormula: DateFormula) AvailableToPromise: Decimal
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcQtyAvailableToPromise(
            Item, AvailabilityDate, GrossRequirement, ScheduledReceipt, PeriodType, LookaheadDateFormula, AvailableToPromise, IsHandled);
        if not IsHandled then begin
            ScheduledReceipt := CalcScheduledReceipt(Item);
            GrossRequirement := CalcGrossRequirement(Item);

            if AvailabilityDate <> 0D then
                GrossRequirement +=
                    CalculateForward(
                        Item, PeriodType,
                        AvailabilityDate + 1,
                        GetForwardPeriodEndDate(LookaheadDateFormula, PeriodType, AvailabilityDate));

            AvailableToPromise :=
                CalcAvailableInventory(Item) +
                (ScheduledReceipt - CalcReservedReceipt(Item)) -
                (GrossRequirement - CalcReservedRequirement(Item));
        end;

        OnAfterQtyAvailableToPromise(Item, ScheduledReceipt, GrossRequirement, AvailableToPromise);

        exit(AvailableToPromise);
    end;

    procedure CalcAvailableInventory(var Item: Record Item): Decimal
    var
        AvailableInventory: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcAvailableInventory(Item, AvailableInventory, IsHandled);
        if not IsHandled then begin
            CalcAllItemFields(Item);
            AvailableInventory := Item.Inventory - Item."Reserved Qty. on Inventory";
        end;
        OnAfterCalcAvailableInventory(Item, AvailableInventory);
        exit(AvailableInventory);
    end;

    procedure CalcGrossRequirement(var Item: Record Item) GrossRequirement: Decimal
    var
        QtyOnComponentLines: Decimal;
        IsHandled: Boolean;
    begin
        CalcAllItemFields(Item);
        IsHandled := false;
        OnBeforeCalcGrossRequirement(Item, GrossRequirement, IsHandled);
        if not IsHandled then begin
            QtyOnComponentLines := Item.CalcQtyOnComponentLines();
            GrossRequirement :=
                QtyOnComponentLines +
                Item."Planning Issues (Qty.)" +
                Item."Planning Transfer Ship. (Qty)." +
                Item."Qty. on Sales Order" +
                Item."Qty. on Job Order" +
                Item."Trans. Ord. Shipment (Qty.)" +
                Item."Qty. on Asm. Component" +
                Item."Qty. on Purch. Return";
        end;

        OnAfterCalcGrossRequirement(Item, GrossRequirement);
        exit(GrossRequirement);
    end;

    procedure CalcReservedRequirement(var Item: Record Item) ReservedRequirement: Decimal
    var
        IsHandled: Boolean;
    begin
        CalcAllItemFields(Item);
        IsHandled := false;
        OnBeforeCalcReservedRequirement(Item, ReservedRequirement, IsHandled);
        if not IsHandled then
            ReservedRequirement :=
                Item.CalcResQtyonProdOrderComp() +
                Item."Reserved Qty. on Sales Orders" +
                Item."Res. Qty. on Job Order" +
                Item."Res. Qty. on Outbound Transfer" +
                Item."Res. Qty. on  Asm. Comp." +
                Item."Res. Qty. on Purch. Returns";

        OnAfterCalcReservedRequirement(Item, ReservedRequirement);
        exit(ReservedRequirement);
    end;

    procedure CalcScheduledReceipt(var Item: Record Item) ScheduledReceipt: Decimal
    var
        IsHandled: Boolean;
    begin
        CalcAllItemFields(Item);
        IsHandled := false;
        OnBeforeCalcScheduledReceipt(Item, ScheduledReceipt, IsHandled);
        if not IsHandled then
            ScheduledReceipt :=
                Item.CalcScheduledReceiptQty() +
                Item.CalcPlannedOrderReceiptQty() +
                Item."Qty. on Purch. Order" +
                Item."Trans. Ord. Receipt (Qty.)" +
                Item."Qty. in Transit" +
                Item."Qty. on Assembly Order" +
                Item."Qty. on Sales Return";

        OnAfterCalcScheduledReceipt(Item, ScheduledReceipt);
        exit(ScheduledReceipt);
    end;

    procedure CalcReservedReceipt(var Item: Record Item) ReservedReceipt: Decimal
    var
        IsHandled: Boolean;
    begin
        CalcAllItemFields(Item);
        IsHandled := false;
        OnBeforeCalcReservedReceipt(Item, ReservedReceipt, IsHandled);
        if not IsHandled then
            ReservedReceipt :=
                Item.CalcReservedQtyOnProdOrder() +
                Item."Reserved Qty. on Purch. Orders" +
                Item."Res. Qty. on Inbound Transfer" +
                Item."Res. Qty. on Assembly Order" +
                Item."Res. Qty. on Sales Returns";

        OnAfterCalcReservedReceipt(Item, ReservedReceipt);
        exit(ReservedReceipt);
    end;

    procedure CalcEarliestAvailabilityDate(var Item: Record Item; NeededQty: Decimal; StartDate: Date; ExcludeQty: Decimal; ExcludeOnDate: Date; var AvailableQty: Decimal; PeriodType: Enum "Analysis Period Type"; LookaheadDateFormula: DateFormula): Date
    var
        Date: Record System.Utilities.Date;
        DummyItem: Record Item;
        TempAvailabilityAtDate: Record "Availability at Date" temporary;
        CalendarManagement: Codeunit "Calendar Management";
        QtyIsAvailable: Boolean;
        ExactDateFound: Boolean;
        IsHandled: Boolean;
        ScheduledReceipt: Decimal;
        GrossRequirement: Decimal;
        AvailableQtyPeriod: Decimal;
        AvailableDate: Date;
        PeriodStart: Date;
        PeriodEnd: Date;
    begin
        AvailableQty := 0;

        Item.CopyFilter("Date Filter", DummyItem."Date Filter");
        Item.SetRange("Date Filter", 0D, GetForwardPeriodEndDate(LookaheadDateFormula, PeriodType, StartDate));
        CalculateAvailability(Item, TempAvailabilityAtDate);
        UpdateScheduledReceipt(TempAvailabilityAtDate, ExcludeOnDate, ExcludeQty);
        OnCalcEarliestAvailabilityDateOnAfterUpdateScheduledReceipt(TempAvailabilityAtDate);
        CalculateAvailabilityByPeriod(TempAvailabilityAtDate, PeriodType);

        IsHandled := false;
        OnCalcEarliestAvailabilityDateOnBeforeFilterDate(Item, NeededQty, StartDate, AvailableQty, PeriodType, LookaheadDateFormula, TempAvailabilityAtDate, AvailableDate, IsHandled, ExcludeOnDate);
        if IsHandled then
            exit(AvailableDate);

        PeriodStart := 0D;
        Date.SetRange("Period Type", PeriodType);
        Date.SetRange("Period Start", 0D, StartDate);
        if Date.FindLast() then begin
            TempAvailabilityAtDate.SetRange("Period Start", 0D, Date."Period Start");
            if TempAvailabilityAtDate.FindSet() then
                repeat
                    if PeriodStart = 0D then
                        PeriodStart := TempAvailabilityAtDate."Period Start";
                    ScheduledReceipt += TempAvailabilityAtDate."Scheduled Receipt";
                    GrossRequirement += TempAvailabilityAtDate."Gross Requirement";
                    OnCalcEarliestAvailabilityDateOnBeforeNextTempAvailabilityAtDate(TempAvailabilityAtDate);
                until TempAvailabilityAtDate.Next() = 0;
            AvailableQty := Item.Inventory - Item."Reserved Qty. on Inventory" + ScheduledReceipt - GrossRequirement;
            OnCalcEarliestAvailabilityDateOnAfterCalculateAvailableQty(AvailableQty, Item, ScheduledReceipt, GrossRequirement);
            if AvailableQty >= NeededQty then begin
                QtyIsAvailable := true;
                AvailableDate := Date."Period End";
                PeriodEnd := Date."Period End";
            end else
                PeriodStart := 0D;
        end;

        if Format(LookaheadDateFormula) = '' then
            TempAvailabilityAtDate.SetRange("Period Start", StartDate + 1, CalendarManagement.GetMaxDate())
        else
            TempAvailabilityAtDate.SetRange("Period Start", StartDate + 1, CalcDate(LookaheadDateFormula, StartDate));

        TempAvailabilityAtDate."Period Start" := 0D;
        while TempAvailabilityAtDate.Next() <> 0 do begin
            AvailableQtyPeriod := TempAvailabilityAtDate."Scheduled Receipt" - TempAvailabilityAtDate."Gross Requirement";
            if TempAvailabilityAtDate."Scheduled Receipt" <= TempAvailabilityAtDate."Gross Requirement" then begin
                AvailableQty := AvailableQty + AvailableQtyPeriod;
                AvailableDate := TempAvailabilityAtDate."Period End";
                if AvailableQty < NeededQty then
                    QtyIsAvailable := false;
            end else
                if QtyIsAvailable then
                    TempAvailabilityAtDate.FindLast()
                else begin
                    AvailableQty := AvailableQty + AvailableQtyPeriod;
                    if AvailableQty >= NeededQty then begin
                        QtyIsAvailable := true;
                        AvailableDate := TempAvailabilityAtDate."Period End";
                        PeriodStart := TempAvailabilityAtDate."Period Start";
                        PeriodEnd := TempAvailabilityAtDate."Period End";
                        TempAvailabilityAtDate.FindLast();
                    end;
                end;
        end;

        if QtyIsAvailable then begin
            if PeriodType <> PeriodType::Day then begin
                Item.SetRange("Date Filter", PeriodStart, PeriodEnd);
                CalculateAvailability(Item, TempAvailabilityAtDate);
                if (ExcludeOnDate >= PeriodStart) and (ExcludeOnDate <= PeriodEnd) then
                    UpdateScheduledReceipt(TempAvailabilityAtDate, ExcludeOnDate, ExcludeQty);
            end;
            TempAvailabilityAtDate.SetRange("Period Start", PeriodStart, PeriodEnd);
            if TempAvailabilityAtDate.Find('+') then
                repeat
                    if (AvailableQty - TempAvailabilityAtDate."Scheduled Receipt") < NeededQty then begin
                        ExactDateFound := true;
                        AvailableDate := TempAvailabilityAtDate."Period Start";
                    end else
                        AvailableQty := AvailableQty - TempAvailabilityAtDate."Scheduled Receipt";
                until (TempAvailabilityAtDate.Next(-1) = 0) or ExactDateFound;
            if not ExactDateFound then begin
                AvailableDate := StartDate;
                if TempAvailabilityAtDate.Find() then
                    AvailableQty := AvailableQty + TempAvailabilityAtDate."Scheduled Receipt";
            end;
        end else
            AvailableDate := 0D;

        DummyItem.CopyFilter("Date Filter", Item."Date Filter");
        exit(AvailableDate);
    end;

    procedure CalculateForward(var Item: Record Item; PeriodType: Enum "Analysis Period Type"; StartDate: Date; EndDate: Date): Decimal
    var
        DummyItem: Record Item;
        TempAvailabilityAtDate: Record "Availability at Date" temporary;
        ForwardQty: Decimal;
        Stop: Boolean;
    begin
        Item.CopyFilter("Date Filter", DummyItem."Date Filter");
        Item.SetRange("Date Filter", StartDate, EndDate);
        CalculateAvailability(Item, TempAvailabilityAtDate);
        CalculateAvailabilityByPeriod(TempAvailabilityAtDate, PeriodType);
        TempAvailabilityAtDate.SetRange("Period Start", 0D, StartDate - 1);
        if TempAvailabilityAtDate.FindSet() then
            repeat
                ForwardQty += TempAvailabilityAtDate."Gross Requirement" - TempAvailabilityAtDate."Scheduled Receipt";
            until TempAvailabilityAtDate.Next() = 0;

        TempAvailabilityAtDate.SetRange("Period Start", StartDate, EndDate);
        if TempAvailabilityAtDate.FindSet() then
            repeat
                if TempAvailabilityAtDate."Gross Requirement" > TempAvailabilityAtDate."Scheduled Receipt" then
                    ForwardQty += TempAvailabilityAtDate."Gross Requirement" - TempAvailabilityAtDate."Scheduled Receipt"
                else
                    if TempAvailabilityAtDate."Gross Requirement" < TempAvailabilityAtDate."Scheduled Receipt" then
                        Stop := true;
            until (TempAvailabilityAtDate.Next() = 0) or Stop;

        if ForwardQty < 0 then
            ForwardQty := 0;

        DummyItem.CopyFilter("Date Filter", Item."Date Filter");
        exit(ForwardQty);
    end;

    procedure CalculateAvailability(var Item: Record Item; var AvailabilityAtDate: Record "Availability at Date")
    var
        Item2: Record Item;
    begin
        Item2.CopyFilters(Item);
        Item.SetRange("Bin Filter");
        Item.SetRange("Global Dimension 1 Filter");
        Item.SetRange("Global Dimension 2 Filter");

        Item.CalcFields(Inventory, "Reserved Qty. on Inventory");

        AvailabilityAtDate.Reset();
        AvailabilityAtDate.DeleteAll();
        OnCalculateAvailabilityAfterClearAvailabilityAtDate(AvailabilityAtDate, Item, ReqShipDate);
        OldRecordExists := false;

        UpdatePurchReqRcptAvail(AvailabilityAtDate, Item);
        UpdateTransOrderRcptAvail(AvailabilityAtDate, Item);
        UpdatePlanningIssuesAvail(AvailabilityAtDate, Item);
        UpdateSalesOrderAvail(AvailabilityAtDate, Item);
        UpdateTransOrderShptAvail(AvailabilityAtDate, Item);
        UpdateAsmOrderAvail(AvailabilityAtDate, Item);
        UpdateAsmCompAvail(AvailabilityAtDate, Item);

        OnAfterCalculateAvailability(AvailabilityAtDate, Item);

        Item.CopyFilters(Item2);
    end;

    procedure UpdateScheduledReceipt(var AvailabilityAtDate: Record "Availability at Date"; ReceiptDate: Date; ScheduledReceipt: Decimal)
    begin
        UpdateAvailability(AvailabilityAtDate, ReceiptDate, ScheduledReceipt, 0);
    end;

    procedure UpdateGrossRequirement(var AvailabilityAtDate: Record "Availability at Date"; ShipmentDate: Date; GrossRequirement: Decimal)
    begin
        UpdateAvailability(AvailabilityAtDate, ShipmentDate, 0, GrossRequirement);
    end;

    local procedure UpdateAvailability(var AvailabilityAtDate: Record "Availability at Date"; Date: Date; ScheduledReceipt: Decimal; GrossRequirement: Decimal)
    var
        RecordExists: Boolean;
    begin
        if (ScheduledReceipt = 0) and (GrossRequirement = 0) then
            exit;

        if OldRecordExists and (Date = AvailabilityAtDate."Period Start") then
            RecordExists := true
        else begin
            AvailabilityAtDate."Period Start" := Date;
            if AvailabilityAtDate.Find() then
                RecordExists := true
            else begin
                AvailabilityAtDate.Init();
                AvailabilityAtDate."Period End" := Date;
            end;
        end;

        AvailabilityAtDate."Scheduled Receipt" += ScheduledReceipt;
        AvailabilityAtDate."Gross Requirement" += GrossRequirement;

        OnUpdateAvailabilityOnBeforeInsertModify(AvailabilityAtDate, Date, ScheduledReceipt, GrossRequirement);

        if RecordExists then
            AvailabilityAtDate.Modify()
        else
            AvailabilityAtDate.Insert();

        OldRecordExists := true;
    end;

    local procedure CalculateAvailabilityByPeriod(var AvailabilityAtDate: Record "Availability at Date"; PeriodType: Enum "Analysis Period Type")
    var
        AvailabilityInPeriod: Record "Availability at Date";
        Date: Record System.Utilities.Date;
    begin
        if PeriodType = PeriodType::Day then
            exit;

        if AvailabilityAtDate.FindSet() then
            repeat
                Date.SetRange("Period Type", PeriodType);
                Date."Period Type" := PeriodType.AsInteger();
                Date."Period Start" := AvailabilityAtDate."Period Start";
                if Date.Find('=<') then begin
                    AvailabilityAtDate.SetRange("Period Start", Date."Period Start", Date."Period End");
                    AvailabilityInPeriod.Init();
                    AvailabilityInPeriod."Period Start" := Date."Period Start";
                    AvailabilityInPeriod."Period End" := NormalDate(Date."Period End");
                    repeat
                        AvailabilityInPeriod."Scheduled Receipt" += AvailabilityAtDate."Scheduled Receipt";
                        AvailabilityInPeriod."Gross Requirement" += AvailabilityAtDate."Gross Requirement";
                        OnCalculateAvailabilityByPeriodOnBeforeDeleteAvailabilityAtDate(AvailabilityInPeriod, AvailabilityAtDate);
                        AvailabilityAtDate.Delete();
                    until AvailabilityAtDate.Next() = 0;
                    AvailabilityAtDate.SetRange("Period Start");
                    AvailabilityAtDate := AvailabilityInPeriod;
                    AvailabilityAtDate.Insert();
                end;
            until AvailabilityAtDate.Next() = 0;
    end;

    procedure GetRequiredShipmentDate(): Date
    begin
        exit(ReqShipDate);
    end;

    procedure GetForwardPeriodEndDate(LookaheadDateFormula: DateFormula; PeriodType: Enum "Analysis Period Type"; StartDate: Date): Date
    var
        CalendarManagement: Codeunit "Calendar Management";
    begin
        if Format(LookaheadDateFormula) = '' then
            exit(CalendarManagement.GetMaxDate());

        exit(GetPeriodEndingDate(CalcDate(LookaheadDateFormula, StartDate), PeriodType));
    end;

    procedure GetPeriodEndingDate(PeriodEnd: Date; PeriodType: Enum "Analysis Period Type"): Date
    var
        Date: Record System.Utilities.Date;
    begin
        if PeriodType = PeriodType::Day then
            exit(PeriodEnd);

        Date.SetRange("Period Type", PeriodType);
        Date.SetRange("Period Start", 0D, PeriodEnd);
        Date.FindLast();
        exit(NormalDate(Date."Period End"));
    end;

    procedure SetPromisingReqShipDate(OrderPromisingLine: Record "Order Promising Line")
    begin
        ReqShipDate := OrderPromisingLine."Requested Shipment Date";
    end;

    procedure SetOriginalShipmentDate(OrderPromisingLine: Record "Order Promising Line")
    begin
        CurrentOrderPromisingLine := OrderPromisingLine;
        ReqShipDate := OrderPromisingLine."Original Shipment Date";
    end;

    procedure SetChangedSalesLine(SalesLine: Record "Sales Line")
    begin
        ChangedSalesLine := SalesLine;
    end;

    procedure SetChangedAsmLine(AssemblyLine: Record "Assembly Line")
    begin
        ChangedAssemblyLine := AssemblyLine;
    end;

    local procedure CalcReqShipDate(SalesLine: Record "Sales Line"): Date
    begin
        if SalesLine."Requested Delivery Date" = 0D then
            exit(SalesLine."Shipment Date");

        SalesLine."Planned Delivery Date" := SalesLine."Requested Delivery Date";
        if Format(SalesLine."Shipping Time") <> '' then
            SalesLine."Planned Shipment Date" := SalesLine.CalcPlannedDeliveryDate(SalesLine.FieldNo("Planned Delivery Date"))
        else
            SalesLine."Planned Shipment Date" := SalesLine.CalcPlannedShptDate(SalesLine.FieldNo("Planned Delivery Date"));
        exit(SalesLine.CalcShipmentDate());
    end;

    local procedure CalcAllItemFields(var Item: Record Item)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcAllItemFields(Item, AllFieldCalculated, PrevItemNo, PrevItemFilters, IsHandled);
        if IsHandled then
            exit;

        if AllFieldCalculated and (PrevItemNo = Item."No.") and (PrevItemFilters = Item.GetFilters) then
            exit;

        OnCalcAllItemFieldsOnBeforeItemCalcFields(Item);
        Item.CalcFields(
          Inventory, "Reserved Qty. on Inventory",
          "Planning Issues (Qty.)",
          "Planning Transfer Ship. (Qty).",
          "Qty. on Sales Order",
          "Qty. on Job Order",
          "Trans. Ord. Shipment (Qty.)",
          "Qty. on Asm. Component",
          "Qty. on Purch. Return",
          "Reserved Qty. on Sales Orders",
          "Res. Qty. on Job Order",
          "Res. Qty. on Outbound Transfer",
          "Res. Qty. on  Asm. Comp.",
          "Res. Qty. on Purch. Returns");

        // Max function parameters is 20, hence split in 2
        Item.CalcFields(
          "Qty. on Purch. Order",
          "Trans. Ord. Receipt (Qty.)",
          "Qty. in Transit",
          "Qty. on Assembly Order",
          "Qty. on Sales Return",
          "Reserved Qty. on Purch. Orders",
          "Res. Qty. on Inbound Transfer",
          "Res. Qty. on Assembly Order",
          "Res. Qty. on Sales Returns");

        OnCalcAllItemFieldsOnAfterItemCalcFields(Item);

        AllFieldCalculated := true;
        PrevItemNo := Item."No.";
        PrevItemFilters := Item.GetFilters();
    end;

    procedure ResetItemNo()
    begin
        PrevItemNo := '';
    end;

    local procedure UpdatePurchReqRcptAvail(var AvailabilityAtDate: Record "Availability at Date"; var Item: Record Item)
    var
        RequisitionLine: Record "Requisition Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdatePurchReqRcptAvail(AvailabilityAtDate, Item, IsHandled);
        if IsHandled then
            exit;

        if RequisitionLine.FindLinesWithItemToPlan(Item) then
            repeat
                RequisitionLine.CalcFields("Reserved Qty. (Base)");
                UpdateScheduledReceipt(AvailabilityAtDate, RequisitionLine."Due Date", RequisitionLine."Quantity (Base)" - RequisitionLine."Reserved Qty. (Base)");
            until RequisitionLine.Next() = 0;
    end;

    local procedure UpdateTransOrderRcptAvail(var AvailabilityAtDate: Record "Availability at Date"; var Item: Record Item)
    var
        TransferLine: Record "Transfer Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateTransOrderRcptAvail(AvailabilityAtDate, Item, IsHandled);
        if IsHandled then
            exit;

        if TransferLine.FindLinesWithItemToPlan(Item, true, false) then
            repeat
                TransferLine.CalcFields("Reserved Qty. Inbnd. (Base)", "Reserved Qty. Shipped (Base)");
                UpdateScheduledReceipt(AvailabilityAtDate, TransferLine."Receipt Date",
                  TransferLine."Outstanding Qty. (Base)" + TransferLine."Qty. Shipped (Base)" - TransferLine."Qty. Received (Base)" - TransferLine."Reserved Qty. Inbnd. (Base)" - TransferLine."Reserved Qty. Shipped (Base)");
            until TransferLine.Next() = 0;
    end;

    local procedure UpdatePlanningIssuesAvail(var AvailabilityAtDate: Record "Availability at Date"; var Item: Record Item)
    var
        PlanningComp: Record "Planning Component";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdatePlanningIssuesAvail(AvailabilityAtDate, Item, IsHandled);
        if IsHandled then
            exit;

        if PlanningComp.FindLinesWithItemToPlan(Item) then
            repeat
                PlanningComp.CalcFields("Reserved Qty. (Base)");
                UpdateGrossRequirement(AvailabilityAtDate, PlanningComp."Due Date", PlanningComp."Expected Quantity (Base)" - PlanningComp."Reserved Qty. (Base)");
            until PlanningComp.Next() = 0;
    end;

    local procedure UpdateSalesOrderAvail(var AvailabilityAtDate: Record "Availability at Date"; var Item: Record Item)
    var
        SalesLine: Record "Sales Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateSalesOrderAvail(AvailabilityAtDate, Item, ChangedSalesLine, CurrentOrderPromisingLine, ReqShipDate, IsHandled);
        if IsHandled then
            exit;

        if SalesLine.FindLinesWithItemToPlan(Item, SalesLine."Document Type"::Order) then
            repeat
                if IncludeSalesLineToAvailCalc(SalesLine) then begin
                    SalesLine.CalcFields("Reserved Qty. (Base)");
                    UpdateGrossRequirement(AvailabilityAtDate, SalesLine."Shipment Date", SalesLine."Outstanding Qty. (Base)" - SalesLine."Reserved Qty. (Base)")
                end
            until SalesLine.Next() = 0;

        if SalesLine.FindLinesWithItemToPlan(Item, SalesLine."Document Type"::"Return Order") then
            repeat
                SalesLine.CalcFields("Reserved Qty. (Base)");
                UpdateScheduledReceipt(AvailabilityAtDate, SalesLine."Shipment Date", SalesLine."Outstanding Qty. (Base)" - SalesLine."Reserved Qty. (Base)")
            until SalesLine.Next() = 0;
    end;

    local procedure UpdateTransOrderShptAvail(var AvailabilityAtDate: Record "Availability at Date"; var Item: Record Item)
    var
        TransferLine: Record "Transfer Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateTransOrderShptAvail(AvailabilityAtDate, Item, IsHandled);
        if IsHandled then
            exit;

        if TransferLine.FindLinesWithItemToPlan(Item, false, false) then
            repeat
                TransferLine.CalcFields("Reserved Qty. Outbnd. (Base)");
                UpdateGrossRequirement(AvailabilityAtDate, TransferLine."Shipment Date", TransferLine."Outstanding Qty. (Base)" - TransferLine."Reserved Qty. Outbnd. (Base)");
            until TransferLine.Next() = 0;
    end;

    local procedure UpdateAsmOrderAvail(var AvailabilityAtDate: Record "Availability at Date"; var Item: Record Item)
    var
        AssemblyHeader: Record "Assembly Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateAsmOrderAvail(AvailabilityAtDate, Item, IsHandled);
        if IsHandled then
            exit;

        if AssemblyHeader.FindItemToPlanLines(Item, AssemblyHeader."Document Type"::Order) then
            repeat
                AssemblyHeader.CalcFields("Reserved Qty. (Base)");
                UpdateScheduledReceipt(AvailabilityAtDate, AssemblyHeader."Due Date", AssemblyHeader."Remaining Quantity (Base)" - AssemblyHeader."Reserved Qty. (Base)");
            until AssemblyHeader.Next() = 0;
    end;

    local procedure UpdateAsmCompAvail(var AvailabilityAtDate: Record "Availability at Date"; var Item: Record Item)
    var
        AssemblyLine: Record "Assembly Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateAsmCompAvail(AvailabilityAtDate, Item, IsHandled, ChangedAssemblyLine);
        if IsHandled then
            exit;

        if AssemblyLine.FindItemToPlanLines(Item, AssemblyLine."Document Type"::Order) then
            repeat
                if not AreEqualAssemblyLines(ChangedAssemblyLine, AssemblyLine) then begin
                    AssemblyLine.CalcFields("Reserved Qty. (Base)");
                    UpdateGrossRequirement(AvailabilityAtDate, AssemblyLine."Due Date", AssemblyLine."Remaining Quantity (Base)" - AssemblyLine."Reserved Qty. (Base)");
                end;
            until AssemblyLine.Next() = 0;
    end;

    local procedure IncludeSalesLineToAvailCalc(SalesLine: Record "Sales Line"): Boolean
    var
        OrderPromisingSalesLine: Record "Sales Line";
    begin
        // always include order promising line being calculated now
        if CurrentOrderPromisingLine."Source Type" = CurrentOrderPromisingLine."Source Type"::Sales then
            if OrderPromisingSalesLine.Get(
                 CurrentOrderPromisingLine."Source Subtype", CurrentOrderPromisingLine."Source ID",
                 CurrentOrderPromisingLine."Source Line No.")
            then
                if AreEqualSalesLines(OrderPromisingSalesLine, SalesLine) then
                    exit(true);

        // already calculated sales line
        if AreEqualSalesLines(ChangedSalesLine, SalesLine) then
            exit(false);

        // sales line requested to be shipped later
        if (ReqShipDate <> 0D) then
            if (CalcReqShipDate(SalesLine) > ReqShipDate) then
                exit(false);

        exit(true);
    end;

    local procedure AreEqualSalesLines(xSalesLine: Record "Sales Line"; SalesLine: Record "Sales Line"): Boolean
    begin
        exit(xSalesLine.RecordId() = SalesLine.RecordId());
    end;

    local procedure AreEqualAssemblyLines(xAssemblyLine: Record "Assembly Line"; AssemblyLine: Record "Assembly Line"): Boolean
    begin
        exit(xAssemblyLine.RecordId() = AssemblyLine.RecordId());
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCalculateAvailability(var AvailabilityAtDate: Record "Availability at Date"; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcGrossRequirement(var Item: Record Item; var GrossRequirement: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcScheduledReceipt(var Item: Record Item; var ScheduledReceipt: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcReservedRequirement(var Item: Record Item; var ReservedRequirement: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcReservedReceipt(var Item: Record Item; var ReservedReceipt: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterQtyAvailableToPromise(var Item: Record Item; ScheduledReceipt: Decimal; GrossRequirement: Decimal; var AvailableToPromise: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcAvailableInventory(var Item: Record Item; var AvailableInventory: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcAvailableInventory(var Item: Record Item; var AvailableInventory: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcGrossRequirement(var Item: Record Item; var GrossRequirement: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcScheduledReceipt(var Item: Record Item; var ScheduledReceipt: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcReservedRequirement(var Item: Record Item; var ReservedRequirement: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcReservedReceipt(var Item: Record Item; var ReservedReceipt: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateSalesOrderAvail(var AvailabilityAtDate: Record "Availability at Date"; var Item: Record Item; ChangedSalesLine: Record "Sales Line"; CurrentOrderPromisingLine: Record "Order Promising Line"; ReqShipDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcQtyAvailableToPromise(var Item: Record Item; var AvailabilityDate: Date; var GrossRequirement: Decimal; var ScheduledReceipt: Decimal; PeriodType: Enum "Analysis Period Type"; LookaheadDateFormula: DateFormula; var AvailableToPromise: Decimal; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN25
    internal procedure RunOnBeforeUpdatePurchOrderAvail(var AvailabilityAtDate: Record "Availability at Date"; var Item: Record Item; var IsHandled: Boolean)
    begin
        OnBeforeUpdatePurchOrderAvail(AvailabilityAtDate, Item, IsHandled);
    end;

    [Obsolete('Moved to codeunit JobPlanningAvailabilityMgt', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdatePurchOrderAvail(var AvailabilityAtDate: Record "Availability at Date"; var Item: Record Item; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnCalcAllItemFieldsOnAfterItemCalcFields(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcAllItemFieldsOnBeforeItemCalcFields(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateAvailabilityAfterClearAvailabilityAtDate(var AvailabilityAtDate: Record "Availability at Date"; var Item: Record Item; var ReqShipDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcEarliestAvailabilityDateOnBeforeFilterDate(var Item: Record Item; NeededQty: Decimal; StartDate: Date; var AvailableQty: Decimal; PeriodType: Enum "Analysis Period Type"; LookaheadDateFormula: DateFormula; var AvailabilityAtDate: Record "Availability at Date"; var AvailableDate: Date; var IsHandled: Boolean; ExcludeOnDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcAllItemFields(var Item: record Item; var AllFieldCalculated: Boolean; var PrevItemNo: Code[20]; var PrevItemFilters: Text; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN25
    internal procedure RunOnBeforeUpdateSchedRcptAvail(var AvailabilityAtDate: Record "Availability at Date"; var Item: Record Item; var IsHandled: Boolean)
    begin
        OnBeforeUpdateSchedRcptAvail(AvailabilityAtDate, Item, IsHandled);
    end;

    [Obsolete('Moved to codeunit ProdOrderAvailabilityMgt', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateSchedRcptAvail(var AvailabilityAtDate: Record "Availability at Date"; var Item: Record Item; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdatePurchReqRcptAvail(var AvailabilityAtDate: Record "Availability at Date"; var Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateTransOrderRcptAvail(var AvailabilityAtDate: Record "Availability at Date"; var Item: Record Item; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN25
    internal procedure RunOnBeforeUpdateSchedNeedAvail(var AvailabilityAtDate: Record "Availability at Date"; var Item: Record Item; var IsHandled: Boolean)
    begin
        OnBeforeUpdateSchedNeedAvail(AvailabilityAtDate, Item, IsHandled);
    end;

    [Obsolete('Moved to codeunit ProdOrderAvailabilityMgt', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateSchedNeedAvail(var AvailabilityAtDate: Record "Availability at Date"; var Item: Record Item; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdatePlanningIssuesAvail(var AvailabilityAtDate: Record "Availability at Date"; var Item: Record Item; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN25
    internal procedure RunOnBeforeUpdateServOrderAvail(var AvailabilityAtDate: Record "Availability at Date"; var Item: Record Item; var IsHandled: Boolean)
    begin
        OnBeforeUpdateServOrderAvail(AvailabilityAtDate, Item, IsHandled);
    end;

    [Obsolete('Moved to codeunit ServAvailabilityMgt', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateServOrderAvail(var AvailabilityAtDate: Record "Availability at Date"; var Item: Record Item; var IsHandled: Boolean)
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnBeforeUpdateJobOrderAvail(var AvailabilityAtDate: Record "Availability at Date"; var Item: Record Item; var IsHandled: Boolean)
    begin
        OnBeforeUpdateJobOrderAvail(AvailabilityAtDate, Item, IsHandled);
    end;

    [Obsolete('Moved to codeunit JobPlanningAvailabilityMgt', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateJobOrderAvail(var AvailabilityAtDate: Record "Availability at Date"; var Item: Record Item; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateTransOrderShptAvail(var AvailabilityAtDate: Record "Availability at Date"; var Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateAsmOrderAvail(var AvailabilityAtDate: Record "Availability at Date"; var Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateAsmCompAvail(var AvailabilityAtDate: Record "Availability at Date"; var Item: Record Item; var IsHandled: Boolean; var ChangedAssemblyLine: Record "Assembly Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCalcEarliestAvailabilityDateOnAfterUpdateScheduledReceipt(var TempAvailabilityAtDate: Record "Availability at Date" temporary)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnUpdateAvailabilityOnBeforeInsertModify(var AvailabilityAtDate: Record "Availability at Date"; Date: Date; var ScheduledReceipt: Decimal; var GrossRequirement: Decimal)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCalculateAvailabilityByPeriodOnBeforeDeleteAvailabilityAtDate(var AvailabilityInPeriod: Record "Availability at Date"; AvailabilityAtDate: Record "Availability at Date")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCalcEarliestAvailabilityDateOnBeforeNextTempAvailabilityAtDate(var AvailabilityAtDate: Record "Availability at Date")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCalcEarliestAvailabilityDateOnAfterCalculateAvailableQty(var AvailableQty: decimal; var Item: Record "Item"; ScheduledReceipt: decimal; GrossRequirement: decimal)
    begin
    end;
}

