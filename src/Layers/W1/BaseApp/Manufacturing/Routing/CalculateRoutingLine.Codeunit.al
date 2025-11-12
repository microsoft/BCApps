// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Routing;

using Microsoft.Foundation.Enums;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Costing;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.WorkCenter;

codeunit 99000774 "Calculate Routing Line"
{
    Permissions = TableData "Production Order" = r,
                  TableData "Prod. Order Line" = r,
                  TableData "Prod. Order Routing Line" = rim,
                  TableData "Prod. Order Capacity Need" = rimd,
                  TableData "Work Center" = r,
                  TableData "Calendar Entry" = r,
                  TableData "Machine Center" = r,
                  TableData "Manufacturing Setup" = r,
                  TableData "Capacity Constrained Resource" = r;

    trigger OnRun()
    begin
    end;

    var
        MfgSetup: Record "Manufacturing Setup";
        Workcenter: Record "Work Center";
        Workcenter2: Record "Work Center";
        MachineCenter: Record "Machine Center";
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProdOrderCapNeed: Record "Prod. Order Capacity Need";
        ProdOrderCapNeed2: Record "Prod. Order Capacity Need";
        CalendarEntry: Record "Calendar Entry";
        CalendarMgt: Codeunit "Shop Calendar Management";
        UOMMgt: Codeunit "Unit of Measure Management";
        RoutingTimeType: Enum "Routing Time Type";
        NextCapNeedLineNo: Integer;
        ProdStartingTime: Time;
        ProdEndingTime: Time;
        ProdStartingDate: Date;
        ProdEndingDate: Date;
        MaxLotSize: Decimal;
        TotalLotSize: Decimal;
        ProdOrderQty: Decimal;
        TotalScrap: Decimal;
        LotSize: Decimal;
        RemainNeedQty: Decimal;
        ConCurrCap: Decimal;
        RunStartingDateTime: DateTime;
        RunEndingDateTime: DateTime;
        FirstInBatch: Boolean;
        FirstEntry: Boolean;
        UpdateDates: Boolean;
        WaitTimeOnly: Boolean;
        CurrentWorkCenterNo: Code[20];
        CurrentTimeFactor: Decimal;
        CurrentRounding: Decimal;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Error when calculating %1. Calendar is not available %2 %3 for %4 %5.';
#pragma warning restore AA0470
        Text001: Label 'backward';
        Text002: Label 'before';
        Text003: Label 'forward';
        Text004: Label 'after';
        Text005: Label 'The sum of setup, move and wait time exceeds the available time in the period.';
        Text006: Label 'fixed schedule';
        Text007: Label 'Starting time must be before ending time.';
#pragma warning restore AA0074

    local procedure TestForError(DirectionTxt: Text[30]; BefAfterTxt: Text[30]; Date: Date)
    begin
        if RemainNeedQty <> 0 then
            Error(
              Text000,
              DirectionTxt,
              BefAfterTxt,
              Date,
              ProdOrderRoutingLine.Type,
              ProdOrderRoutingLine."No.");
    end;

    local procedure CreateCapNeed(NeedDate: Date; StartingTime: Time; EndingTime: Time; NeedQty: Decimal; TimeType: Enum "Routing Time Type"; Direction: Option Forward,Backward)
    begin
        InitProdOrderCapNeed(ProdOrder, ProdOrderRoutingLine, ProdOrderCapNeed, TimeType, NeedDate, StartingTime, EndingTime, NeedQty);

        ProdOrderCapNeed."Time Type" := TimeType;
        if TimeType = TimeType::"Run Time" then
            ProdOrderCapNeed."Lot Size" := LotSize;

        if TimeType = TimeType::"Run Time" then
            if RemainNeedQty = 0 then begin
                if FirstInBatch then
                    ProdOrderCapNeed."Send-Ahead Type" := ProdOrderCapNeed."Send-Ahead Type"::Both
                else
                    case Direction of
                        Direction::Forward:
                            ProdOrderCapNeed."Send-Ahead Type" := ProdOrderCapNeed."Send-Ahead Type"::Output;
                        Direction::Backward:
                            ProdOrderCapNeed."Send-Ahead Type" := ProdOrderCapNeed."Send-Ahead Type"::Input;
                    end;
            end else
                if FirstInBatch then
                    case Direction of
                        Direction::Forward:
                            ProdOrderCapNeed."Send-Ahead Type" := ProdOrderCapNeed."Send-Ahead Type"::Input;
                        Direction::Backward:
                            ProdOrderCapNeed."Send-Ahead Type" := ProdOrderCapNeed."Send-Ahead Type"::Output;
                    end;

        ProdOrderCapNeed.UpdateDatetime();

        OnBeforeProdOrderCapNeedInsert(ProdOrderCapNeed, ProdOrderRoutingLine, ProdOrder, CalendarEntry);
        ProdOrderCapNeed.Insert();

        NextCapNeedLineNo := NextCapNeedLineNo + 1;

        OnAfterCreateCapNeeded(
            ProdOrderRoutingLine, NeedDate, NeedQty, RemainNeedQty, CalendarEntry, StartingTime, EndingTime, TimeType.AsInteger(),
            NextCapNeedLineNo, ConCurrCap, LotSize, FirstInBatch, Direction);
    end;

    local procedure InitProdOrderCapNeed(ProdOrder: Record "Production Order"; var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var ProdOrderCapNeed: Record "Prod. Order Capacity Need"; TimeType: Enum "Routing Time Type"; NeedDate: Date; StartingTime: Time; EndingTime: Time; NeedQty: Decimal)
    var
        ActuallyPostedTime: Decimal;
        DistributedCapNeed: Decimal;
    begin
        OnBeforeInitProdOrderCapNeed(ProdOrder, ProdOrderRoutingLine, ProdOrderCapNeed, TimeType, NeedDate, StartingTime, EndingTime, NeedQty, LotSize);

        ProdOrderCapNeed.Init();
        ProdOrderCapNeed.Status := ProdOrder.Status;
        ProdOrderCapNeed."Prod. Order No." := ProdOrder."No.";
        ProdOrderCapNeed."Routing No." := ProdOrderRoutingLine."Routing No.";
        ProdOrderCapNeed."Routing Reference No." := ProdOrderRoutingLine."Routing Reference No.";
        ProdOrderCapNeed."Line No." := NextCapNeedLineNo;
        ProdOrderCapNeed.Type := ProdOrderRoutingLine.Type;
        ProdOrderCapNeed."No." := ProdOrderRoutingLine."No.";
        ProdOrderCapNeed."Work Center No." := ProdOrderRoutingLine."Work Center No.";
        ProdOrderCapNeed."Operation No." := ProdOrderRoutingLine."Operation No.";
        ProdOrderCapNeed."Work Center Group Code" := ProdOrderRoutingLine."Work Center Group Code";
        ProdOrderCapNeed.Date := NeedDate;
        ProdOrderCapNeed."Starting Time" := StartingTime;
        ProdOrderCapNeed."Ending Time" := EndingTime;
        ProdOrderCapNeed."Needed Time" := NeedQty;
        ProdOrderCapNeed."Needed Time (ms)" := NeedQty * CalendarMgt.TimeFactor(Workcenter."Unit of Measure Code");
        ProdOrderCapNeed."Concurrent Capacities" := ConCurrCap;
        ProdOrderCapNeed.Efficiency := CalendarEntry.Efficiency;
        ProdOrderCapNeed."Requested Only" := false;
        ProdOrderCapNeed.Active := true;
        if ProdOrder.Status <> ProdOrder.Status::Simulated then begin
            ActuallyPostedTime := CalcActuallyPostedCapacityTime(ProdOrderRoutingLine, TimeType);
            DistributedCapNeed := CalcDistributedCapacityNeedForOperation(ProdOrderRoutingLine, TimeType);
            ProdOrderCapNeed."Allocated Time" := NeedQty - ActuallyPostedTime + DistributedCapNeed;
            if ProdOrderCapNeed."Allocated Time" < 0 then
                ProdOrderCapNeed."Allocated Time" := 0;
            ProdOrderRoutingLine."Expected Capacity Need" :=
              ProdOrderRoutingLine."Expected Capacity Need" + ProdOrderCapNeed."Needed Time (ms)";
        end;

        OnAfterInitProdOrderCapNeed(ProdOrder, ProdOrderRoutingLine, ProdOrderCapNeed, NeedQty, TimeType, ActuallyPostedTime, DistributedCapNeed);
    end;

    local procedure CreateLoadBack(TimeType: Enum "Routing Time Type"; Write: Boolean)
    var
        OldCalendarEntry: Record "Calendar Entry";
        AvQtyBase: Decimal;
        RelevantEfficiency: Decimal;
        xConCurrCap: Decimal;
        RemainNeedQtyBase: Decimal;
        StartingTime: Time;
        StopLoop: Boolean;
    begin
        xConCurrCap := 1;
        if (RemainNeedQty = 0) and ((not FirstEntry) or (not Write) or WaitTimeOnly) then
            exit;
        if CalendarEntry.Find('+') then begin
            if (TimeType = TimeType::"Wait Time") and (CalendarEntry.Date < ProdEndingDate) then begin
                CalendarEntry.Date := ProdEndingDate;
                CreateCalendarEntry(CalendarEntry);
            end;
            GetCurrentWorkCenterTimeFactorAndRounding(CalendarEntry."Work Center No.");
            RemainNeedQtyBase := Round(RemainNeedQty * CurrentTimeFactor, CurrentRounding);
            repeat
                OldCalendarEntry := CalendarEntry;
                ConCurrCap := ProdOrderRoutingLine."Concurrent Capacities";
                if (ConCurrCap = 0) or (CalendarEntry.Capacity < ConCurrCap) then
                    ConCurrCap := CalendarEntry.Capacity;
                if TimeType <> TimeType::"Run Time" then
                    RemainNeedQtyBase := Round(RemainNeedQtyBase * ConCurrCap / xConCurrCap, CurrentRounding);
                xConCurrCap := ConCurrCap;
                AvQtyBase := CalcLoadBackAvailQtyBase(TimeType);

                if AvQtyBase > RemainNeedQtyBase then
                    AvQtyBase := RemainNeedQtyBase;
                if TimeType in [TimeType::"Setup Time", TimeType::"Run Time"] then
                    RelevantEfficiency := CalendarEntry.Efficiency
                else
                    RelevantEfficiency := 100;

                OnCreateLoadBackOnAfterCalcRelevantEfficiency(ProdOrderRoutingLine, TimeType, RelevantEfficiency);

                StartingTime :=
                  CalendarMgt.CalcTimeSubtract(
                    CalendarEntry."Ending Time",
                    Round(AvQtyBase * 100 / RelevantEfficiency / ConCurrCap, 1, '>'));
                RemainNeedQtyBase := RemainNeedQtyBase - AvQtyBase;
                OnCreateLoadBackOnBeforeCheckWrite(ProdOrderRoutingLine, TimeType, RelevantEfficiency, RemainNeedQtyBase, RemainNeedQty, CurrentRounding, Write, StartingTime, AvQtyBase, CalendarEntry);
                if Write then begin
                    RemainNeedQty := Round(RemainNeedQtyBase / CurrentTimeFactor, CurrentRounding);
                    CreateCapNeed(
                      CalendarEntry.Date, StartingTime, CalendarEntry."Ending Time",
                      Round(AvQtyBase / CurrentTimeFactor, CurrentRounding), TimeType, 1);
                    FirstInBatch := false;
                    FirstEntry := false;
                end;
                if UpdateDates and
                   ((CalendarEntry."Capacity (Effective)" <> 0) or (TimeType = TimeType::"Wait Time"))
                then begin
                    ProdOrderRoutingLine."Ending Time" := CalendarEntry."Ending Time";
                    ProdOrderRoutingLine."Ending Date" := CalendarEntry.Date;
                    UpdateDates := false;
                end;
                ProdEndingTime := StartingTime;
                ProdEndingDate := CalendarEntry.Date;
                ProdOrderRoutingLine."Starting Time" := StartingTime;
                ProdOrderRoutingLine."Starting Date" := CalendarEntry.Date;

                if (RemainNeedQtyBase = 0) and ((not FirstEntry) or (not Write)) then
                    StopLoop := true
                else
                    if TimeType = TimeType::"Wait Time" then begin
                        StopLoop := false;
                        ReturnNextCalendarEntry(CalendarEntry, OldCalendarEntry, 0);
                    end else begin
                        CalendarEntry := OldCalendarEntry;
                        StopLoop := CalendarEntry.Next(-1) = 0;
                    end;
                OnCreateLoadBackOnBeforeEndStopLoop(ProdOrderRoutingLine, TimeType, StopLoop);
            until StopLoop;
            RemainNeedQty := Round(RemainNeedQtyBase / CurrentTimeFactor, CurrentRounding);
        end;
    end;

    local procedure CalcLoadBackAvailQtyBase(TimeType: Enum "Routing Time Type") AvQtyBase: Decimal
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcLoadBackAvailQtyBase(ProdOrderRoutingLine, TimeType, CurrentTimeFactor, CurrentRounding, AvQtyBase, IsHandled);
        if IsHandled then
            exit(AvQtyBase);

        AvQtyBase :=
            CalcAvailQtyBase(
                CalendarEntry, ProdEndingDate, ProdEndingTime, TimeType, ConCurrCap, false, CurrentTimeFactor, CurrentRounding);
    end;

    local procedure CreateLoadForward(TimeType: Enum "Routing Time Type"; Write: Boolean; LoadFactor: Decimal)
    var
        OldCalendarEntry: Record "Calendar Entry";
        AvQtyBase: Decimal;
        RelevantEfficiency: Decimal;
        xConCurrCap: Decimal;
        RemainNeedQtyBase: Decimal;
        EndingTime: Time;
        StopLoop: Boolean;
        IsHandled: Boolean;
    begin
        xConCurrCap := 1;
        if (RemainNeedQty = 0) and ((not FirstEntry) or (not Write) or WaitTimeOnly) then
            exit;
        if CalendarEntry.Find('-') then begin
            if (TimeType = TimeType::"Wait Time") and (CalendarEntry.Date > ProdStartingDate) then begin
                CalendarEntry.Date := ProdStartingDate;
                CreateCalendarEntry(CalendarEntry);
            end;
            if CalendarEntry."Capacity (Effective)" = 0 then begin
                CalendarEntry."Starting Time" := ProdStartingTime;
                CalendarEntry.Date := ProdStartingDate;
            end;
            if CalendarEntry."Work Center No." = Workcenter."No." then
                GetCurrentWorkCenterTimeFactorAndRounding(Workcenter."No.")
            else
                GetCurrentWorkCenterTimeFactorAndRounding(CalendarEntry."Work Center No.");
            RemainNeedQtyBase := Round(RemainNeedQty * CurrentTimeFactor, CurrentRounding);
            repeat
                OldCalendarEntry := CalendarEntry;
                ConCurrCap := ProdOrderRoutingLine."Concurrent Capacities";
                if (ConCurrCap = 0) or (CalendarEntry.Capacity < ConCurrCap) then
                    ConCurrCap := CalendarEntry.Capacity;
                if TimeType <> TimeType::"Run Time" then
                    RemainNeedQtyBase := Round(RemainNeedQtyBase * ConCurrCap / xConCurrCap, CurrentRounding);
                xConCurrCap := ConCurrCap;
                AvQtyBase := CalcLoadForwardAvailQtyBase(TimeType);

                if AvQtyBase * LoadFactor > RemainNeedQtyBase then
                    AvQtyBase := Round(RemainNeedQtyBase / LoadFactor, CurrentRounding);

                if TimeType in [TimeType::"Setup Time", TimeType::"Run Time"] then
                    RelevantEfficiency := CalendarEntry.Efficiency
                else
                    RelevantEfficiency := 100;

                IsHandled := false;
                OnCreateLoadForwardOnBeforeCalcEndingTime(EndingTime, CalendarEntry, AvQtyBase, RelevantEfficiency, ConCurrCap, IsHandled, ProdOrderRoutingLine, TimeType);
                if not IsHandled then
                    EndingTime := CalendarEntry."Starting Time" + Round(AvQtyBase * 100 / RelevantEfficiency / ConCurrCap, 1, '>');

                if AvQtyBase * LoadFactor >= 0 then
                    RemainNeedQtyBase := RemainNeedQtyBase - AvQtyBase * LoadFactor;
                OnCreateLoadForwardOnBeforeCheckWrite(ProdOrderRoutingLine, TimeType, RelevantEfficiency, RemainNeedQtyBase, RemainNeedQty, CurrentRounding, Write);
                if Write then begin
                    RemainNeedQty := Round(RemainNeedQtyBase / CurrentTimeFactor, CurrentRounding);
                    CreateCapNeed(
                      CalendarEntry.Date, CalendarEntry."Starting Time", EndingTime,
                      Round(AvQtyBase * LoadFactor / CurrentTimeFactor, CurrentRounding), TimeType, 0);
                    FirstInBatch := false;
                    FirstEntry := false;
                end;
                if UpdateDates and
                   ((CalendarEntry."Capacity (Effective)" <> 0) or (TimeType = TimeType::"Wait Time"))
                then begin
                    ProdOrderRoutingLine."Starting Time" := CalendarEntry."Starting Time";
                    ProdOrderRoutingLine."Starting Date" := CalendarEntry.Date;
                    UpdateDates := false;
                end;
                if (EndingTime = 000000T) and (AvQtyBase <> 0) then
                    // Ending Time reached 24:00:00 so we need to move date as well
                    CalendarEntry.Date := CalendarEntry.Date + 1;
                ProdStartingTime := EndingTime;
                ProdStartingDate := CalendarEntry.Date;
                ProdOrderRoutingLine."Ending Time" := EndingTime;
                ProdOrderRoutingLine."Ending Date" := CalendarEntry.Date;

                if ProdOrderRoutingLine."Schedule Manually" then begin
                    if TimeType = TimeType::"Setup Time" then
                        RunStartingDateTime := CreateDateTime(ProdStartingDate, ProdStartingTime);
                    if (RemainNeedQtyBase < 0) or (Round(RemainNeedQtyBase, CurrentRounding) = 0) then
                        RemainNeedQtyBase := 0;
                end;
                OnCreateLoadForwardOnAfterScheduleProdOrderRoutingLineManually(ProdOrderRoutingLine, TimeType, RunStartingDateTime, ProdStartingDate, ProdStartingTime, RemainNeedQtyBase);

                if (RemainNeedQtyBase = 0) and ((not FirstEntry) or (not Write)) and (AvQtyBase * LoadFactor >= 0) then
                    StopLoop := true
                else
                    if TimeType = TimeType::"Wait Time" then begin
                        StopLoop := false;
                        ReturnNextCalendarEntry(CalendarEntry, OldCalendarEntry, 1);
                    end else begin
                        CalendarEntry := OldCalendarEntry;
                        StopLoop := CalendarEntry.Next() = 0;
                    end;
                OnCreateLoadForwardOnBeforeEndStopLoop(ProdOrderRoutingLine, TimeType, StopLoop);
            until StopLoop;
            RemainNeedQty := Round(RemainNeedQtyBase / CurrentTimeFactor, CurrentRounding);
        end;
    end;

    local procedure CalcLoadForwardAvailQtyBase(TimeType: Enum "Routing Time Type") AvQtyBase: Decimal
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcLoadForwardAvailQtyBase(ProdOrderRoutingLine, TimeType, CurrentTimeFactor, CurrentRounding, AvQtyBase, IsHandled);
        if IsHandled then
            exit(AvQtyBase);

        AvQtyBase :=
            CalcAvailQtyBase(
                CalendarEntry, ProdStartingDate, ProdStartingTime, TimeType, ConCurrCap, true, CurrentTimeFactor, CurrentRounding);
    end;

    local procedure AvailableCapacity(CapType: Enum "Capacity Type"; CapNo: Code[20]; StartingDateTime: DateTime; EndingDateTime: DateTime) AvQty: Decimal
    var
        CalendarEntry2: Record "Calendar Entry";
        ConCurrCapacity: Decimal;
        Overlap: Decimal;
        TotalDuration: Decimal;
    begin
        CalendarEntry2.SetCapacityFilters(CapType, CapNo);
        CalendarEntry2.SetFilter("Starting Date-Time", '<=%1', EndingDateTime);
        CalendarEntry2.SetFilter("Ending Date-Time", '>=%1', StartingDateTime);

        if CalendarEntry2.Find('-') then
            repeat
                ConCurrCapacity := ProdOrderRoutingLine."Concurrent Capacities";
                if (ConCurrCapacity = 0) or (CalendarEntry2.Capacity < ConCurrCapacity) then
                    ConCurrCapacity := CalendarEntry2.Capacity;

                Overlap := 0;
                if StartingDateTime > CalendarEntry2."Starting Date-Time" then
                    Overlap := CalcDuration(CalendarEntry2."Starting Date-Time", StartingDateTime);
                if EndingDateTime < CalendarEntry2."Ending Date-Time" then
                    Overlap := Overlap + CalcDuration(EndingDateTime, CalendarEntry2."Ending Date-Time");

                TotalDuration := CalcDuration(CalendarEntry2."Starting Date-Time", CalendarEntry2."Ending Date-Time");

                AvQty := AvQty +
                  Round(
                    ((TotalDuration - Overlap) / TotalDuration) *
                    CalendarEntry2."Capacity (Effective)" / CalendarEntry2.Capacity * ConCurrCapacity,
                    Workcenter."Calendar Rounding Precision");
            until CalendarEntry2.Next() = 0;
        exit(AvQty);
    end;

    local procedure LoadCapBack(CapType: Enum "Capacity Type"; CapNo: Code[20]; TimeType: Enum "Routing Time Type"; Write: Boolean)
    begin
        OnBeforeLoadCapBack(ProdOrderRoutingLine, TimeType, RemainNeedQty, ProdEndingDate, ProdEndingTime);

        ProdOrderRoutingLine."Starting Date" := ProdEndingDate;
        ProdOrderRoutingLine."Starting Time" := ProdEndingTime;

        CalendarEntry.SetCapacityFilters(CapType, CapNo);
        CalendarEntry.SetRange("Ending Date-Time", 0DT, CreateDateTime(ProdEndingDate + 1, ProdEndingTime));
        CalendarEntry.SetRange("Starting Date-Time", 0DT, CreateDateTime(ProdEndingDate, ProdEndingTime));
        OnLoadCapBackOnAfterSetCalendarEntryFilters(CalendarEntry);

        CreateLoadBack(TimeType, Write);

        OnLoadCapBackOnAfterCreateLoadBack(CapType, CapNo, TimeType, Write);

        if RemainNeedQty = 0 then
            exit;

        TestForError(Text001, Text002, ProdOrderRoutingLine."Starting Date");
    end;

    procedure LoadCapForward(CapType: Enum "Capacity Type"; CapNo: Code[20]; TimeType: Enum "Routing Time Type"; Write: Boolean)
    var
        TotalAvailCapacity: Decimal;
        LoadFactor: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeLoadCapForward(ProdOrderRoutingLine, CapType, CapNo, TimeType, ProdStartingDate, ProdStartingTime, IsHandled, RemainNeedQty);
        if IsHandled then
            exit;

        ProdOrderRoutingLine."Ending Date" := ProdStartingDate;
        ProdOrderRoutingLine."Ending Time" := ProdStartingTime;

        CalendarEntry.SetCapacityFilters(CapType, CapNo);
        CalendarEntry.SetFilter("Starting Date-Time", '>=%1', CreateDateTime(ProdStartingDate - 1, ProdStartingTime));
        if TimeType = TimeType::"Wait Time" then
            CalendarEntry.SetFilter("Ending Date-Time", '>=%1', CreateDateTime(ProdStartingDate, 000000T))
        else
            CalendarEntry.SetFilter("Ending Date-Time", '>=%1', CreateDateTime(ProdStartingDate, ProdStartingTime));

        if ProdOrderRoutingLine."Schedule Manually" and (TimeType = TimeType::"Run Time") then begin
            OnLoadCapForwardOnScheduleManuallyOnBeforeCheckDateTimes(ProdOrderRoutingLine, CapType, CapNo, TimeType, ProdStartingDate, ProdStartingTime, RemainNeedQty, RunStartingDateTime, RunEndingDateTime);
            if ProdOrderRoutingLine."Run Time" <> 0 then
                if (RunEndingDateTime < RunStartingDateTime) or
                    ((RunEndingDateTime = RunStartingDateTime) and (ProdOrderRoutingLine."Input Quantity" <> 0))
                then
                    Error(Text005);
            TotalAvailCapacity :=
              AvailableCapacity(CapType, CapNo, RunStartingDateTime, RunEndingDateTime);
            if TotalAvailCapacity = 0 then begin
                TestForError(Text006, Text002, DT2Date(RunEndingDateTime));
                LoadFactor := 0;
            end else
                LoadFactor := Round(RemainNeedQty / TotalAvailCapacity, Workcenter."Calendar Rounding Precision", '>');
        end else
            LoadFactor := 1;

        OnLoadCapForwardOnBeforeCreateLoadForward(RemainNeedQty, CapType, CapNo, TimeType, Write, LoadFactor);
        CreateLoadForward(TimeType, Write, LoadFactor);
        OnLoadCapForwardOnAfterCreateLoadForward(RemainNeedQty, CapType, CapNo, TimeType, Write, LoadFactor);

        if RemainNeedQty = 0 then
            exit;

        TestForError(Text003, Text004, ProdOrderRoutingLine."Ending Date");
    end;

    local procedure CalcMove()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcMove(ProdOrderRoutingLine, WorkCenter, ProdEndingDate, ProdEndingTime, UpdateDates, IsHandled);
        if IsHandled then
            exit;

        RemainNeedQty :=
          Round(
            ProdOrderRoutingLine."Move Time" *
            CalendarMgt.TimeFactor(ProdOrderRoutingLine."Move Time Unit of Meas. Code") /
            CalendarMgt.TimeFactor(Workcenter."Unit of Measure Code"),
            Workcenter."Calendar Rounding Precision");

        LoadCapBack(ProdOrderRoutingLine.Type, ProdOrderRoutingLine."No.", RoutingTimeType::"Move Time", false);
    end;

    local procedure CalcWaitBack()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcWaitBack(ProdOrderRoutingLine, WorkCenter, ProdEndingDate, ProdEndingTime, UpdateDates, IsHandled);
        if IsHandled then
            exit;

        RemainNeedQty :=
          Round(
            ProdOrderRoutingLine."Wait Time" *
            CalendarMgt.TimeFactor(ProdOrderRoutingLine."Wait Time Unit of Meas. Code") /
            CalendarMgt.TimeFactor(WorkCenter."Unit of Measure Code"),
            Workcenter."Calendar Rounding Precision");

        LoadCapBack(ProdOrderRoutingLine.Type, ProdOrderRoutingLine."No.", RoutingTimeType::"Wait Time", false);
    end;

    local procedure GetSendAheadStartingTime(ProdOrderRoutingLineNext: Record "Prod. Order Routing Line"; var SendAheadLotSize: Decimal): Boolean
    var
        xProdOrderRoutingLine: Record "Prod. Order Routing Line";
        RunTime: Decimal;
        WaitTime: Decimal;
        MoveTime: Decimal;
        SetupTime: Decimal;
        ResidualLotSize: Decimal;
        ResidualProdStartDateTime: DateTime;
    begin
        ProdStartingDate := ProdOrderRoutingLineNext."Starting Date";
        ProdStartingTime := ProdOrderRoutingLineNext."Starting Time";
        SendAheadLotSize := MaxLotSize;
        if TotalLotSize = MaxLotSize then
            exit(true);

        if (ProdOrderRoutingLine."Send-Ahead Quantity" = 0) or
           (ProdOrderRoutingLine."Send-Ahead Quantity" >= MaxLotSize)
        then begin
            TotalLotSize := SendAheadLotSize;
            exit(false);
        end;

        SendAheadLotSize := ProdOrderRoutingLine."Send-Ahead Quantity";
        if MaxLotSize < (TotalLotSize + SendAheadLotSize) then begin
            SendAheadLotSize := MaxLotSize - TotalLotSize;
            TotalLotSize := MaxLotSize;
        end else begin
            if TotalLotSize = 0 then begin
                ResidualLotSize := MaxLotSize mod SendAheadLotSize;
                if ResidualLotSize = 0 then
                    ResidualLotSize := SendAheadLotSize;
            end;
            TotalLotSize := TotalLotSize + SendAheadLotSize;
        end;

        ProdOrderCapNeed2.Reset();
        ProdOrderCapNeed2.SetCurrentKey(Status, "Prod. Order No.", "Routing Reference No.", "Operation No.", Date, "Starting Time");
        ProdOrderCapNeed2.SetRange(Status, ProdOrderRoutingLine.Status);
        ProdOrderCapNeed2.SetRange("Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        ProdOrderCapNeed2.SetRange("Requested Only", false);
        ProdOrderCapNeed2.SetRange("Routing No.", ProdOrderRoutingLine."Routing No.");
        ProdOrderCapNeed2.SetRange("Routing Reference No.", ProdOrderRoutingLine."Routing Reference No.");
        ProdOrderCapNeed2.SetRange("Operation No.", ProdOrderRoutingLine."Operation No.");
        if ProdOrderCapNeed2.FindFirst() then begin
            if TotalLotSize <> MaxLotSize then begin
                SendAheadLotSize := MaxLotSize - (TotalLotSize - SendAheadLotSize);
                TotalLotSize := MaxLotSize;
            end;
            exit(false);
        end;
        // calculate Starting Date/Time for the last lot of the next line by going back from Ending Date/Time of the line
        Workcenter2.Get(ProdOrderRoutingLineNext."Work Center No.");
        SetupTime :=
          Round(
            ProdOrderRoutingLineNext."Setup Time" *
            CalendarMgt.TimeFactor(ProdOrderRoutingLineNext."Setup Time Unit of Meas. Code") /
            CalendarMgt.TimeFactor(Workcenter2."Unit of Measure Code"),
            Workcenter2."Calendar Rounding Precision");
        RunTime :=
          Round(
            (ResidualLotSize * ProdOrderRoutingLineNext.RunTimePer()) *
            CalendarMgt.TimeFactor(ProdOrderRoutingLineNext."Run Time Unit of Meas. Code") /
            CalendarMgt.TimeFactor(Workcenter2."Unit of Measure Code"),
            Workcenter2."Calendar Rounding Precision");
        WaitTime :=
          Round(
            ProdOrderRoutingLineNext."Wait Time" *
            CalendarMgt.TimeFactor(ProdOrderRoutingLineNext."Wait Time Unit of Meas. Code") /
            CalendarMgt.TimeFactor(Workcenter2."Unit of Measure Code"),
            Workcenter2."Calendar Rounding Precision");
        MoveTime :=
          Round(
            ProdOrderRoutingLineNext."Move Time" *
            CalendarMgt.TimeFactor(ProdOrderRoutingLineNext."Move Time Unit of Meas. Code") /
            CalendarMgt.TimeFactor(Workcenter2."Unit of Measure Code"),
            Workcenter2."Calendar Rounding Precision");

        xProdOrderRoutingLine := ProdOrderRoutingLine;
        ProdOrderRoutingLine := ProdOrderRoutingLineNext;
        ProdEndingDate := ProdOrderRoutingLine."Ending Date";
        ProdEndingTime := ProdOrderRoutingLine."Ending Time";
        RemainNeedQty := SetupTime;
        LoadCapBack(ProdOrderRoutingLine.Type, ProdOrderRoutingLine."No.", RoutingTimeType::"Setup Time", false);
        RemainNeedQty := MoveTime;
        LoadCapBack(ProdOrderRoutingLine.Type, ProdOrderRoutingLine."No.", RoutingTimeType::"Move Time", false);
        RemainNeedQty := WaitTime;
        LoadCapBack(ProdOrderRoutingLine.Type, ProdOrderRoutingLine."No.", RoutingTimeType::"Wait Time", false);
        RemainNeedQty := RunTime;
        LoadCapBack(ProdOrderRoutingLine.Type, ProdOrderRoutingLine."No.", RoutingTimeType::"Run Time", false);
        ProdOrderRoutingLine := xProdOrderRoutingLine;

        ProdOrderRoutingLine."Starting Date" := ProdEndingDate;
        ProdOrderRoutingLine."Starting Time" := ProdEndingTime;
        ResidualProdStartDateTime := CreateDateTime(ProdEndingDate, ProdEndingTime);
        // calculate Ending Date/Time of current line by going forward from Starting Date/Time of the next line
        Workcenter.Get(ProdOrderRoutingLine."Work Center No.");
        RunTime :=
          Round(
            (MaxLotSize - SendAheadLotSize) * ProdOrderRoutingLine.RunTimePer() *
            CalendarMgt.TimeFactor(ProdOrderRoutingLine."Run Time Unit of Meas. Code") /
            CalendarMgt.TimeFactor(Workcenter."Unit of Measure Code"),
            Workcenter."Calendar Rounding Precision");
        WaitTime :=
          Round(
            ProdOrderRoutingLine."Wait Time" *
            CalendarMgt.TimeFactor(ProdOrderRoutingLine."Wait Time Unit of Meas. Code") /
            CalendarMgt.TimeFactor(Workcenter."Unit of Measure Code"),
            Workcenter."Calendar Rounding Precision");
        MoveTime :=
          Round(
            ProdOrderRoutingLine."Move Time" *
            CalendarMgt.TimeFactor(ProdOrderRoutingLine."Move Time Unit of Meas. Code") /
            CalendarMgt.TimeFactor(Workcenter."Unit of Measure Code"),
            Workcenter."Calendar Rounding Precision");

        RemainNeedQty := RunTime;
        LoadCapForward(ProdOrderRoutingLine.Type, ProdOrderRoutingLine."No.", RoutingTimeType::"Run Time", false);
        RemainNeedQty := WaitTime;
        LoadCapForward(ProdOrderRoutingLine.Type, ProdOrderRoutingLine."No.", RoutingTimeType::"Wait Time", false);
        RemainNeedQty := MoveTime;
        LoadCapForward(ProdOrderRoutingLine.Type, ProdOrderRoutingLine."No.", RoutingTimeType::"Move Time", false);
        // last lot must be finished by current Work Center, otherwise we recalculate Ending Date/Time of current line
        ProdOrderRoutingLine.UpdateDatetime();
        if ProdOrderRoutingLine."Ending Date-Time" > ResidualProdStartDateTime then begin
            ProdOrderRoutingLine."Ending Date" := DT2Date(ResidualProdStartDateTime);
            ProdOrderRoutingLine."Ending Time" := DT2Time(ResidualProdStartDateTime);
            FilterCalendarEntryBeforeOrOnDateTime(ProdOrderRoutingLine.Type, ProdOrderRoutingLine."No.", ProdOrderRoutingLine."Ending Date", ProdOrderRoutingLine."Ending Time");
            if CalendarEntry.FindLast() then
                if ProdOrderRoutingLine."Ending Time" > CalendarEntry."Ending Time" then
                    if (WaitTime = 0) or (MoveTime <> 0) then
                        // Wait Time can end outside of working hours, but only if Move Time = 0
                        ProdOrderRoutingLine."Ending Time" := CalendarEntry."Ending Time";
            ProdStartingDate := ProdOrderRoutingLine."Ending Date";
            ProdStartingTime := ProdOrderRoutingLine."Ending Time";
        end;
        exit(false);
    end;

    procedure CalcRoutingLineBack(CalculateEndDate: Boolean)
    var
        ProdOrderRoutingLine2: Record "Prod. Order Routing Line";
        ProdOrderRoutingLine3: Record "Prod. Order Routing Line";
        ConstrainedCapacity: Record "Capacity Constrained Resource";
        ParentWorkCenter: Record "Capacity Constrained Resource";
        TempProdOrderRoutingLine, TempProdOrderRoutingLine2 : Record "Prod. Order Routing Line" temporary;
        WorkCenterQueueTime: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingVersion: Record "Routing Version";
        Qty, SendAheadLotSize : Decimal;
        ParentIsConstrained: Boolean;
        ResourceIsConstrained: Boolean;
        ShouldCalcNextOperation: Boolean;
        IsHandled, IsParallelRouting : Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcRoutingLineBack(ProdOrderRoutingLine, CalculateEndDate, IsHandled);
        if IsHandled then
            exit;

        CalendarEntry.SetRange(Date, 0D, ProdOrderRoutingLine."Ending Date");

        ProdEndingTime := ProdOrderRoutingLine."Ending Time";
        ProdEndingDate := ProdOrderRoutingLine."Ending Date";
        ProdStartingTime := ProdOrderRoutingLine."Ending Time";
        ProdStartingDate := ProdOrderRoutingLine."Ending Date";

        FirstEntry := true;

        IsParallelRouting := false;
        RoutingVersion.SetLoadFields(Type);
        if RoutingVersion.Get(ProdOrderLine."Routing No.", ProdOrderLine."Routing Version Code") then
            IsParallelRouting := RoutingVersion.Type = RoutingVersion.Type::Parallel
        else begin
            RoutingHeader.SetLoadFields(Type);
            if RoutingHeader.Get(ProdOrderLine."Routing No.") then
                IsParallelRouting := RoutingHeader.Type = RoutingHeader.Type::Parallel;
        end;

        ShouldCalcNextOperation := (ProdOrderRoutingLine."Next Operation No." <> '') and CalculateEndDate;
        OnCalcRoutingLineBackOnAfterCalcShouldCalcNextOperation(ProdOrderRoutingLine, ShouldCalcNextOperation);
        if ShouldCalcNextOperation then begin
            Clear(ProdOrderRoutingLine3);

            TempProdOrderRoutingLine.Reset();
            TempProdOrderRoutingLine.DeleteAll();

            SetRoutingLineFilters(ProdOrderRoutingLine, ProdOrderRoutingLine2);
            ProdOrderRoutingLine2.SetFilter("Operation No.", ProdOrderRoutingLine."Next Operation No.");
            if ProdOrderRoutingLine2.Find('-') then
                repeat
                    TotalLotSize := 0;
                    GetSendAheadStartingTime(ProdOrderRoutingLine2, SendAheadLotSize);
                    TempProdOrderRoutingLine.Copy(ProdOrderRoutingLine2);
                    TempProdOrderRoutingLine.Insert(false, true);
                    SetMinDateTime(ProdEndingDate, ProdEndingTime, ProdStartingDate, ProdStartingTime);

                    if IsParallelRouting then
                        if TempProdOrderRoutingLine2.IsEmpty() then begin
                            WorkCenterQueueTime.Get(ProdOrderRoutingLine2."Work Center No.");
                            Qty := Round(
                                    WorkCenterQueueTime."Queue Time" *
                                    CalendarMgt.TimeFactor(WorkCenterQueueTime."Queue Time Unit of Meas. Code") /
                                    CalendarMgt.TimeFactor(WorkCenterQueueTime."Unit of Measure Code"),
                                    WorkCenterQueueTime."Calendar Rounding Precision");

                            TempProdOrderRoutingLine2.TransferFields(ProdOrderRoutingLine2);
                            TempProdOrderRoutingLine2."Input Quantity" := Qty;
                            TempProdOrderRoutingLine2.Insert(false, true);
                        end else begin
                            WorkCenterQueueTime.Get(ProdOrderRoutingLine2."Work Center No.");
                            Qty := Round(
                                    WorkCenterQueueTime."Queue Time" *
                                    CalendarMgt.TimeFactor(WorkCenterQueueTime."Queue Time Unit of Meas. Code") /
                                    CalendarMgt.TimeFactor(WorkCenterQueueTime."Unit of Measure Code"),
                                    WorkCenterQueueTime."Calendar Rounding Precision");
                            if TempProdOrderRoutingLine2."Work Center No." <> ProdOrderRoutingLine2."Work Center No." then begin
                                if TempProdOrderRoutingLine2."Input Quantity" < Qty then begin
                                    TempProdOrderRoutingLine2.DeleteAll();
                                    TempProdOrderRoutingLine2.TransferFields(ProdOrderRoutingLine2);
                                    TempProdOrderRoutingLine2."Input Quantity" := Qty;
                                    TempProdOrderRoutingLine2.Insert(false, true);
                                end;
                            end else
                                if ProdOrderRoutingLine2."Starting Date-Time" < TempProdOrderRoutingLine2."Starting Date-Time" then begin
                                    TempProdOrderRoutingLine2.DeleteAll();
                                    TempProdOrderRoutingLine2.TransferFields(ProdOrderRoutingLine2);
                                    TempProdOrderRoutingLine2."Input Quantity" := Qty;
                                    TempProdOrderRoutingLine2.Insert(false, true);
                                end;
                        end;
                    ProdOrderRoutingLine3 := ProdOrderRoutingLine2;
                until ProdOrderRoutingLine2.Next() = 0;

            if IsParallelRouting then
                if ProdOrderRoutingLine2.Get(
                    TempProdOrderRoutingLine2.Status,
                    TempProdOrderRoutingLine2."Prod. Order No.",
                    TempProdOrderRoutingLine2."Routing Reference No.",
                    TempProdOrderRoutingLine2."Routing No.",
                    TempProdOrderRoutingLine2."Operation No.")
                then begin
                    GetSendAheadStartingTime(ProdOrderRoutingLine2, SendAheadLotSize);
                    TempProdOrderRoutingLine.GetBySystemId(ProdOrderRoutingLine2.SystemId);
                    TempProdOrderRoutingLine.Copy(ProdOrderRoutingLine2);
                    TempProdOrderRoutingLine.Modify();
                    WorkCenterQueueTime.Get(ProdOrderRoutingLine2."Work Center No.");
                    if WorkCenterQueueTime."Queue Time" <> 0 then begin
                        ProdEndingDate := ProdStartingDate;
                        ProdEndingTime := ProdStartingTime;
                    end;
                    ProdOrderRoutingLine3 := ProdOrderRoutingLine2;
                end;

            OnCalcRoutingLineBackOnBeforeGetQueueTime(ProdOrderRoutingLine, ProdOrderRoutingLine2, ProdOrderRoutingLine3);

            if ProdOrderRoutingLine3."Prod. Order No." <> '' then begin
                Workcenter2.Get(ProdOrderRoutingLine3."Work Center No.");
                ProdOrderRoutingLine3."Critical Path" := true;
                ProdOrderRoutingLine3.UpdateDatetime();
                ProdOrderRoutingLine3.Modify();
                if ProdOrderRoutingLine3.Type = ProdOrderRoutingLine3.Type::"Machine Center" then begin
                    MachineCenter.Get(ProdOrderRoutingLine3."No.");
                    Workcenter2."Queue Time" := MachineCenter."Queue Time";
                    Workcenter2."Queue Time Unit of Meas. Code" :=
                      MachineCenter."Queue Time Unit of Meas. Code";
                end;
                UpdateDates := false;
                RemainNeedQty :=
                  Round(
                    Workcenter2."Queue Time" *
                    CalendarMgt.TimeFactor(Workcenter2."Queue Time Unit of Meas. Code") /
                    CalendarMgt.TimeFactor(Workcenter2."Unit of Measure Code"),
                    Workcenter2."Calendar Rounding Precision");

                LoadCapBack(ProdOrderRoutingLine2.Type, ProdOrderRoutingLine2."No.", RoutingTimeType::"Queue Time", false);
            end else
                ProdOrderRoutingLine3 := ProdOrderRoutingLine2;
        end else
            SetLotSizesToMax(SendAheadLotSize, TotalLotSize);

        // In case of Parallel Routing and the last operation is finished
        if ProdEndingDate = CalendarMgt.GetMaxDate() then begin
            ProdOrderRoutingLine."Ending Date" := ProdOrderLine."Ending Date";
            ProdOrderRoutingLine."Ending Time" := ProdOrderLine."Ending Time";

            ProdEndingTime := ProdOrderRoutingLine."Ending Time";
            ProdEndingDate := ProdOrderRoutingLine."Ending Date";
            ProdStartingTime := ProdOrderRoutingLine."Ending Time";
            ProdStartingDate := ProdOrderRoutingLine."Ending Date";

            TotalLotSize := MaxLotSize;
            SendAheadLotSize := MaxLotSize;
        end;

        UpdateDates := true;

        CalcMove();

        CalcWaitBack();

        if ProdOrderRoutingLine."Schedule Manually" then // Move and wait time has been calculated
            exit;

        repeat
            LotSize := SendAheadLotSize;
            RemainNeedQty := LotSize * ProdOrderRoutingLine.RunTimePer();
            OnCalculateRoutingLineBackOnAfterCalcRemainNeedQtyForLotSize(ProdOrderRoutingLine, RemainNeedQty);
            RemainNeedQty :=
              Round(
                RemainNeedQty *
                CalendarMgt.TimeFactor(ProdOrderRoutingLine."Run Time Unit of Meas. Code") /
                CalendarMgt.TimeFactor(Workcenter."Unit of Measure Code"),
                Workcenter."Calendar Rounding Precision");

            GetConstrainedSetup(ConstrainedCapacity, ResourceIsConstrained, ParentWorkCenter, ParentIsConstrained);
            if not ProdOrderRoutingLine."Schedule Manually" and
               (ResourceIsConstrained or ParentIsConstrained)
            then
                FinitelyLoadCapBack(RoutingTimeType::"Run Time", ConstrainedCapacity, ResourceIsConstrained, ParentWorkCenter, ParentIsConstrained)
            else
                LoadCapBack(ProdOrderRoutingLine.Type, ProdOrderRoutingLine."No.", RoutingTimeType::"Run Time", true);

            ProdEndingDate := ProdOrderRoutingLine."Starting Date";
            ProdEndingTime := ProdOrderRoutingLine."Starting Time";
        until FindSendAheadStartingTime(TempProdOrderRoutingLine, SendAheadLotSize);

        ProdEndingDate := ProdOrderRoutingLine."Starting Date";
        ProdEndingTime := ProdOrderRoutingLine."Starting Time";
        RemainNeedQty :=
          Round(
            ProdOrderRoutingLine."Setup Time" *
            CalendarMgt.TimeFactor(ProdOrderRoutingLine."Setup Time Unit of Meas. Code") /
            CalendarMgt.TimeFactor(Workcenter."Unit of Measure Code"),
            Workcenter."Calendar Rounding Precision");
        OnCalcRoutingLineBackOnAfterCalcRemainNeedQty(ProdOrderRoutingLine, Workcenter, RemainNeedQty);

        GetConstrainedSetup(ConstrainedCapacity, ResourceIsConstrained, ParentWorkCenter, ParentIsConstrained);
        if not ProdOrderRoutingLine."Schedule Manually" and
           (ResourceIsConstrained or ParentIsConstrained)
        then
            FinitelyLoadCapBack(RoutingTimeType::"Setup Time", ConstrainedCapacity, ResourceIsConstrained, ParentWorkCenter, ParentIsConstrained)
        else
            LoadCapBack(ProdOrderRoutingLine.Type, ProdOrderRoutingLine."No.", RoutingTimeType::"Setup Time", true);

        ProdOrderRoutingLine."Starting Date" := ProdEndingDate;
        ProdOrderRoutingLine."Starting Time" := ProdEndingTime;

        if ProdOrderRoutingLine."Ending Date" = CalendarMgt.GetMaxDate() then begin
            ProdOrderRoutingLine."Ending Date" := ProdOrderRoutingLine."Starting Date";
            ProdOrderRoutingLine."Ending Time" := ProdOrderRoutingLine."Starting Time";
        end;

        ProdOrderRoutingLine.UpdateDatetime();
        ProdOrderRoutingLine.Modify();

        OnAfterCalcRoutingLineBack(ProdOrderRoutingLine, ProdOrderLine);
    end;

    local procedure GetConstrainedSetup(var ConstrainedCapacity: Record "Capacity Constrained Resource"; var ResourceIsConstrained: Boolean; var ParentWorkCenter: Record "Capacity Constrained Resource"; var ParentIsConstrained: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetConstrainedSetup(ProdOrderRoutingLine, ConstrainedCapacity, ResourceIsConstrained, ParentWorkCenter, ParentIsConstrained, IsHandled);
        if IsHandled then
            exit;

        ResourceIsConstrained := ConstrainedCapacity.Get(ProdOrderRoutingLine.Type, ProdOrderRoutingLine."No.");
        ParentIsConstrained := ParentWorkCenter.Get(ProdOrderRoutingLine.Type::"Work Center", ProdOrderRoutingLine."Work Center No.");
    end;

    local procedure GetSendAheadEndingTime(ProdOrderRoutingLinePrev: Record "Prod. Order Routing Line"; var SendAheadLotSize: Decimal): Boolean
    var
        xProdOrderRoutingLine: Record "Prod. Order Routing Line";
        SetupTime: Decimal;
        RunTime: Decimal;
        WaitTime: Decimal;
        MoveTime: Decimal;
        ResidualLotSize: Decimal;
        ResidualProdStartDateTime: DateTime;
    begin
        ProdEndingTime := ProdOrderRoutingLinePrev."Ending Time";
        ProdEndingDate := ProdOrderRoutingLinePrev."Ending Date";
        SendAheadLotSize := MaxLotSize;
        if TotalLotSize = MaxLotSize then
            exit(true);

        if (ProdOrderRoutingLinePrev."Send-Ahead Quantity" = 0) or
           (ProdOrderRoutingLinePrev."Send-Ahead Quantity" >= MaxLotSize)
        then begin
            TotalLotSize := SendAheadLotSize;
            exit(false);
        end;
        SendAheadLotSize := ProdOrderRoutingLinePrev."Send-Ahead Quantity";
        if MaxLotSize < (TotalLotSize + SendAheadLotSize) then begin
            SendAheadLotSize := MaxLotSize - TotalLotSize;
            TotalLotSize := MaxLotSize;
        end else begin
            if TotalLotSize = 0 then begin
                ResidualLotSize := MaxLotSize mod SendAheadLotSize;
                if ResidualLotSize = 0 then
                    ResidualLotSize := SendAheadLotSize;
            end;
            TotalLotSize += SendAheadLotSize;
        end;

        ProdOrderCapNeed2.Reset();
        ProdOrderCapNeed2.SetCurrentKey(Status, "Prod. Order No.", "Routing Reference No.", "Operation No.", Date, "Starting Time");
        ProdOrderCapNeed2.SetRange(Status, ProdOrderRoutingLine.Status);
        ProdOrderCapNeed2.SetRange("Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        ProdOrderCapNeed2.SetRange("Requested Only", false);
        ProdOrderCapNeed2.SetRange("Routing No.", ProdOrderRoutingLine."Routing No.");
        ProdOrderCapNeed2.SetRange("Routing Reference No.", ProdOrderRoutingLine."Routing Reference No.");
        ProdOrderCapNeed2.SetRange("Operation No.", ProdOrderRoutingLine."Operation No.");
        if ProdOrderCapNeed2.FindFirst() then begin
            if TotalLotSize <> MaxLotSize then begin
                SendAheadLotSize := MaxLotSize - (TotalLotSize - SendAheadLotSize);
                TotalLotSize := MaxLotSize;
            end;
            exit(false);
        end;
        // calculate Starting Date/Time of current line using Setup/Run/Wait/Move Time for the first send-ahead lot from previous line
        Workcenter2.Get(ProdOrderRoutingLinePrev."Work Center No.");
        SetupTime :=
          Round(
            ProdOrderRoutingLinePrev."Setup Time" *
            CalendarMgt.TimeFactor(ProdOrderRoutingLinePrev."Setup Time Unit of Meas. Code") /
            CalendarMgt.TimeFactor(Workcenter2."Unit of Measure Code"),
            Workcenter2."Calendar Rounding Precision");
        RunTime :=
          Round(
            SendAheadLotSize * ProdOrderRoutingLinePrev.RunTimePer() *
            CalendarMgt.TimeFactor(ProdOrderRoutingLinePrev."Run Time Unit of Meas. Code") /
            CalendarMgt.TimeFactor(Workcenter2."Unit of Measure Code"),
            Workcenter2."Calendar Rounding Precision");
        WaitTime :=
          Round(
            ProdOrderRoutingLinePrev."Wait Time" *
            CalendarMgt.TimeFactor(ProdOrderRoutingLinePrev."Wait Time Unit of Meas. Code") /
            CalendarMgt.TimeFactor(Workcenter2."Unit of Measure Code"),
            Workcenter2."Calendar Rounding Precision");
        MoveTime :=
          Round(
            ProdOrderRoutingLinePrev."Move Time" *
            CalendarMgt.TimeFactor(ProdOrderRoutingLinePrev."Move Time Unit of Meas. Code") /
            CalendarMgt.TimeFactor(Workcenter2."Unit of Measure Code"),
            Workcenter2."Calendar Rounding Precision");
        OnGetSendAheadEndingTimeOnAfterCalcTimes(ProdOrderRoutingLinePrev, Workcenter2, SetupTime, RunTime, WaitTime, MoveTime);

        xProdOrderRoutingLine := ProdOrderRoutingLine;
        ProdOrderRoutingLine := ProdOrderRoutingLinePrev;
        ProdStartingDate := ProdOrderRoutingLine."Starting Date";
        ProdStartingTime := ProdOrderRoutingLine."Starting Time";
        RemainNeedQty := SetupTime;
        LoadCapForward(ProdOrderRoutingLine.Type, ProdOrderRoutingLine."No.", RoutingTimeType::"Setup Time", false);
        RemainNeedQty := RunTime;
        LoadCapForward(ProdOrderRoutingLine.Type, ProdOrderRoutingLine."No.", RoutingTimeType::"Run Time", false);
        RemainNeedQty := WaitTime;
        LoadCapForward(ProdOrderRoutingLine.Type, ProdOrderRoutingLine."No.", RoutingTimeType::"Wait Time", false);
        RemainNeedQty := MoveTime;
        LoadCapForward(ProdOrderRoutingLine.Type, ProdOrderRoutingLine."No.", RoutingTimeType::"Move Time", false);
        ProdOrderRoutingLine := xProdOrderRoutingLine;

        ProdOrderRoutingLine."Starting Date" := ProdStartingDate;
        ProdOrderRoutingLine."Starting Time" := ProdStartingTime;
        // calculate Starting Date/Time for the last lot of current line by going forward from Starting Date/Time of the line
        Workcenter.Get(ProdOrderRoutingLine."Work Center No.");
        SetupTime :=
          Round(
            ProdOrderRoutingLine."Setup Time" *
            CalendarMgt.TimeFactor(ProdOrderRoutingLine."Run Time Unit of Meas. Code") /
            CalendarMgt.TimeFactor(Workcenter."Unit of Measure Code"),
            Workcenter."Calendar Rounding Precision");
        RunTime :=
          Round(
            (MaxLotSize - ResidualLotSize) * ProdOrderRoutingLine.RunTimePer() *
            CalendarMgt.TimeFactor(ProdOrderRoutingLine."Run Time Unit of Meas. Code") /
            CalendarMgt.TimeFactor(Workcenter."Unit of Measure Code"),
            Workcenter."Calendar Rounding Precision");
        OnGetSendAheadEndingTimeOnAfterCalcSetupAndRunTime(ProdOrderRoutingLine, Workcenter, SetupTime, RunTime);

        RemainNeedQty := SetupTime;
        LoadCapForward(ProdOrderRoutingLine.Type, ProdOrderRoutingLine."No.", RoutingTimeType::"Setup Time", false);
        RemainNeedQty := RunTime;
        LoadCapForward(ProdOrderRoutingLine.Type, ProdOrderRoutingLine."No.", RoutingTimeType::"Run Time", false);
        ResidualProdStartDateTime := CreateDateTime(ProdStartingDate, ProdStartingTime);
        // last lot must be finished by previous Work Center, otherwise we recalculate Starting Date/Time of current line
        ProdOrderRoutingLinePrev.UpdateDatetime();
        if ProdOrderRoutingLinePrev."Ending Date-Time" > ResidualProdStartDateTime then begin
            ProdEndingDate := ProdOrderRoutingLinePrev."Ending Date";
            ProdEndingTime := ProdOrderRoutingLinePrev."Ending Time";
            RemainNeedQty := RunTime;
            LoadCapBack(ProdOrderRoutingLine.Type, ProdOrderRoutingLine."No.", RoutingTimeType::"Run Time", false);
            RemainNeedQty := SetupTime;
            LoadCapBack(ProdOrderRoutingLine.Type, ProdOrderRoutingLine."No.", RoutingTimeType::"Setup Time", false);
        end;

        ProdStartingDate := ProdOrderRoutingLine."Starting Date";
        ProdStartingTime := ProdOrderRoutingLine."Starting Time";
        ProdEndingDate := ProdOrderRoutingLine."Starting Date";
        ProdEndingTime := ProdOrderRoutingLine."Starting Time";
        exit(false);
    end;

    procedure CalcRoutingLineForward(CalculateStartDate: Boolean)
    var
        ProdOrderRoutingLine2: Record "Prod. Order Routing Line";
        ProdOrderRoutingLine3: Record "Prod. Order Routing Line";
        ConstrainedCapacity: Record "Capacity Constrained Resource";
        ParentWorkCenter: Record "Capacity Constrained Resource";
        TempProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary;
        SendAheadLotSize: Decimal;
        InputQtyDiffTime: Decimal;
        ParentIsConstrained: Boolean;
        ResourceIsConstrained: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcRoutingLineForward(ProdOrderRoutingLine, CalculateStartDate, IsHandled, TempProdOrderRoutingLine, SendAheadLotSize, MaxLotSize, TotalLotSize, RemainNeedQty, UpdateDates);
        if IsHandled then
            exit;

        CalendarEntry.SetRange(Date, ProdOrderRoutingLine."Starting Date", DMY2Date(31, 12, 9999));

        ProdStartingTime := ProdOrderRoutingLine."Starting Time";
        ProdStartingDate := ProdOrderRoutingLine."Starting Date";
        ProdEndingTime := ProdOrderRoutingLine."Starting Time";
        ProdEndingDate := ProdOrderRoutingLine."Starting Date";

        InputQtyDiffTime := 0;

        FirstEntry := true;

        if (ProdOrderRoutingLine."Previous Operation No." <> '') and
           CalculateStartDate
        then begin
            Clear(ProdOrderRoutingLine3);

            TempProdOrderRoutingLine.Reset();
            TempProdOrderRoutingLine.DeleteAll();

            SetRoutingLineFilters(ProdOrderRoutingLine, ProdOrderRoutingLine2);
            ProdOrderRoutingLine2.SetFilter("Operation No.", ProdOrderRoutingLine."Previous Operation No.");
            if ProdOrderRoutingLine2.Find('-') then
                repeat
                    TotalLotSize := 0;
                    GetSendAheadEndingTime(ProdOrderRoutingLine2, SendAheadLotSize);

                    TempProdOrderRoutingLine.Copy(ProdOrderRoutingLine2);
                    TempProdOrderRoutingLine.Insert();

                    SetMaxDateTime(ProdStartingDate, ProdStartingTime, ProdEndingDate, ProdEndingTime);
                    ProdOrderRoutingLine3 := ProdOrderRoutingLine2;

                    if (ProdOrderRoutingLine2."Send-Ahead Quantity" > 0) and
                       (ProdOrderRoutingLine2."Input Quantity" > ProdOrderRoutingLine."Input Quantity")
                    then begin
                        Workcenter2.Get(ProdOrderRoutingLine2."Work Center No.");
                        InputQtyDiffTime :=
                          (ProdOrderRoutingLine2."Input Quantity" - ProdOrderRoutingLine."Input Quantity") *
                          ProdOrderRoutingLine2.RunTimePer();
                        InputQtyDiffTime :=
                          Round(
                            InputQtyDiffTime *
                            CalendarMgt.TimeFactor(ProdOrderRoutingLine2."Run Time Unit of Meas. Code") /
                            CalendarMgt.TimeFactor(Workcenter2."Unit of Measure Code"),
                            Workcenter2."Calendar Rounding Precision");
                    end;
                until ProdOrderRoutingLine2.Next() = 0
            else begin
                // parallel routing with finished first operation
                if ProdStartingDate = 0D then begin
                    ProdOrderRoutingLine2.Get(ProdOrderRoutingLine.Status,
                      ProdOrderRoutingLine."Prod. Order No.", ProdOrderRoutingLine."Routing Reference No.",
                      ProdOrderRoutingLine."Routing No.", ProdOrderRoutingLine."Operation No.");
                    ProdStartingDate := ProdOrderRoutingLine2."Starting Date";
                    ProdStartingTime := ProdOrderRoutingLine2."Starting Time";
                end;
                TotalLotSize := MaxLotSize;
                SendAheadLotSize := MaxLotSize;
            end;

            if ProdOrderRoutingLine3."Prod. Order No." <> '' then begin
                ProdOrderRoutingLine3."Critical Path" := true;
                ProdOrderRoutingLine3.UpdateDatetime();
                ProdOrderRoutingLine3.Modify();
            end;
        end else
            SetLotSizesToMax(SendAheadLotSize, TotalLotSize);

        RemainNeedQty :=
          Round(
            Workcenter."Queue Time" *
            CalendarMgt.TimeFactor(Workcenter."Queue Time Unit of Meas. Code") /
            CalendarMgt.TimeFactor(Workcenter."Unit of Measure Code"),
            Workcenter."Calendar Rounding Precision");
        RemainNeedQty += InputQtyDiffTime;
        OnCalcRoutingLineForwardOnBeforeLoadCapForward(ProdOrderRoutingLine, ProdOrderRoutingLine3);
        LoadCapForward(ProdOrderRoutingLine.Type, ProdOrderRoutingLine."No.", RoutingTimeType::"Queue Time", false);
        RemainNeedQty :=
          Round(
            ProdOrderRoutingLine."Setup Time" *
            CalendarMgt.TimeFactor(ProdOrderRoutingLine."Setup Time Unit of Meas. Code") /
            CalendarMgt.TimeFactor(Workcenter."Unit of Measure Code"),
            Workcenter."Calendar Rounding Precision");
        OnCalcRoutingLineForwardOnAfterCalcRemainNeedQty(ProdOrderRoutingLine, Workcenter, RemainNeedQty);
        UpdateDates := true;

        GetConstrainedSetup(ConstrainedCapacity, ResourceIsConstrained, ParentWorkCenter, ParentIsConstrained);
        if not ProdOrderRoutingLine."Schedule Manually" and
           (RemainNeedQty > 0) and (ResourceIsConstrained or ParentIsConstrained)
        then
            FinitelyLoadCapForward(RoutingTimeType::"Setup Time", ConstrainedCapacity, ResourceIsConstrained, ParentWorkCenter, ParentIsConstrained)
        else
            LoadCapForward(ProdOrderRoutingLine.Type, ProdOrderRoutingLine."No.", RoutingTimeType::"Setup Time", true);

        FirstInBatch := true;
        repeat
            if (InputQtyDiffTime > 0) and (TotalLotSize = MaxLotSize) then
                SetMaxDateTime(
                  ProdStartingDate, ProdStartingTime, ProdOrderRoutingLine2."Ending Date", ProdOrderRoutingLine2."Ending Time");

            if SendAheadLotSize > ProdOrderQty then
                LotSize := ProdOrderQty
            else
                LotSize := SendAheadLotSize;
            RemainNeedQty := LotSize * ProdOrderRoutingLine.RunTimePer();
            OnCalculateRoutingLineForwardOnAfterCalcRemainNeedQtyForLotSize(ProdOrderRoutingLine, RemainNeedQty);
            RemainNeedQty :=
              Round(
                RemainNeedQty *
                CalendarMgt.TimeFactor(ProdOrderRoutingLine."Run Time Unit of Meas. Code") /
                CalendarMgt.TimeFactor(Workcenter."Unit of Measure Code"),
                Workcenter."Calendar Rounding Precision");

            GetConstrainedSetup(ConstrainedCapacity, ResourceIsConstrained, ParentWorkCenter, ParentIsConstrained);
            if not ProdOrderRoutingLine."Schedule Manually" and
               (RemainNeedQty > 0) and (ResourceIsConstrained or ParentIsConstrained)
            then
                FinitelyLoadCapForward(RoutingTimeType::"Run Time", ConstrainedCapacity, ResourceIsConstrained, ParentWorkCenter, ParentIsConstrained)
            else
                LoadCapForward(ProdOrderRoutingLine.Type, ProdOrderRoutingLine."No.", RoutingTimeType::"Run Time", true);

            ProdStartingDate := ProdOrderRoutingLine."Ending Date";
            ProdStartingTime := ProdOrderRoutingLine."Ending Time";
        until FindSendAheadEndingTime(TempProdOrderRoutingLine, SendAheadLotSize);

        RemainNeedQty :=
          Round(
            ProdOrderRoutingLine."Wait Time" *
            CalendarMgt.TimeFactor(ProdOrderRoutingLine."Wait Time Unit of Meas. Code") /
            CalendarMgt.TimeFactor(Workcenter."Unit of Measure Code"),
            Workcenter."Calendar Rounding Precision");

        OnCalcRoutingLineForwardOnBeforeLoadCapForward2(ProdOrderRoutingLine, ProdOrderRoutingLine3);
        LoadCapForward(ProdOrderRoutingLine.Type, ProdOrderRoutingLine."No.", RoutingTimeType::"Wait Time", false);
        RemainNeedQty :=
          Round(
            ProdOrderRoutingLine."Move Time" *
            CalendarMgt.TimeFactor(ProdOrderRoutingLine."Move Time Unit of Meas. Code") /
            CalendarMgt.TimeFactor(Workcenter."Unit of Measure Code"),
            Workcenter."Calendar Rounding Precision");
        LoadCapForward(ProdOrderRoutingLine.Type, ProdOrderRoutingLine."No.", RoutingTimeType::"Move Time", false);

        if ProdOrderRoutingLine."Starting Date" = 0D then begin
            ProdOrderRoutingLine."Starting Date" := ProdOrderRoutingLine."Ending Date";
            ProdOrderRoutingLine."Starting Time" := ProdOrderRoutingLine."Ending Time";
        end;

        ProdOrderRoutingLine.UpdateDatetime();
        ProdOrderRoutingLine.Modify();

        OnAfterCalcRoutingLineForward(ProdOrderRoutingLine, ProdOrderLine);
    end;

    local procedure CalculateRoutingLineFixed()
    var
        FixedProdOrderRoutingLine: Record "Prod. Order Routing Line";
        CalcEndDate: Boolean;
        CalcStartDate: Boolean;
    begin
        FixedProdOrderRoutingLine := ProdOrderRoutingLine;
        if FixedProdOrderRoutingLine."Starting Date-Time" > FixedProdOrderRoutingLine."Ending Date-Time" then
            Error(Text007);

        // Calculate wait and move time, find end of runtime
        CalcEndDate := true;
        OnCalculateRoutingLineFixedOnBeforeCalcRoutingLineBack(ProdOrderRoutingLine, CalcEndDate);
        CalcRoutingLineBack(CalcEndDate);
        RunEndingDateTime :=
          CreateDateTime(ProdOrderRoutingLine."Starting Date", ProdOrderRoutingLine."Starting Time");

        // Find start of runtime
        ProdOrderRoutingLine := FixedProdOrderRoutingLine;
        CalcStartDate := true;
        OnCalculateRoutingLineFixedOnBeforeCalcRoutingLineForward(ProdOrderRoutingLine, CalcStartDate);
        CalcRoutingLineForward(CalcStartDate);

        ProdOrderRoutingLine."Starting Time" := FixedProdOrderRoutingLine."Starting Time";
        ProdOrderRoutingLine."Starting Date" := FixedProdOrderRoutingLine."Starting Date";
        ProdOrderRoutingLine."Ending Time" := FixedProdOrderRoutingLine."Ending Time";
        ProdOrderRoutingLine."Ending Date" := FixedProdOrderRoutingLine."Ending Date";
        ProdOrderRoutingLine.UpdateDatetime();
        ProdOrderRoutingLine.Modify();
    end;

    procedure CalculateRoutingLine(var ProdOrderRoutingLine2: Record "Prod. Order Routing Line"; Direction: Option Forward,Backward; CalcStartEndDate: Boolean)
    var
        ProdOrderCapNeed: Record "Prod. Order Capacity Need";
        MfgCostCalcMgt: Codeunit "Mfg. Cost Calculation Mgt.";
        ExpectedOperOutput: Decimal;
        ActualOperOutput: Decimal;
        TotalQtyPerOperation: Decimal;
        TotalCapacityPerOperation: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalculateRoutingLine(ProdOrderRoutingLine2, Direction, CalcStartEndDate, IsHandled);
        if IsHandled then
            exit;

        MfgSetup.Get();

        ProdOrderRoutingLine := ProdOrderRoutingLine2;

        WaitTimeOnly :=
          (ProdOrderRoutingLine."Setup Time" = 0) and (ProdOrderRoutingLine."Run Time" = 0) and
          (ProdOrderRoutingLine."Move Time" = 0);

        if ProdOrderRoutingLine."Ending Time" = 0T then
            ProdOrderRoutingLine."Ending Time" := 000000T;

        if ProdOrderRoutingLine."Starting Time" = 0T then
            ProdOrderRoutingLine."Starting Time" := 000000T;

        ProdOrderRoutingLine."Expected Operation Cost Amt." := 0;
        ProdOrderRoutingLine."Expected Capacity Ovhd. Cost" := 0;
        ProdOrderRoutingLine."Expected Capacity Need" := 0;

        OnCalculateRoutingLineOnBeforeProdOrderCapNeedReset(ProdOrderRoutingLine, ProdOrderRoutingLine2);

        ProdOrderCapNeed.Reset();
        ProdOrderCapNeed.SetLoadFields(Status, "Prod. Order No.", "Requested Only", "Routing No.", "Routing Reference No.", "Operation No.");
        ProdOrderCapNeed.SetRange(Status, ProdOrderRoutingLine.Status);
        ProdOrderCapNeed.SetRange("Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        ProdOrderCapNeed.SetRange("Requested Only", false);
        ProdOrderCapNeed.SetRange("Routing No.", ProdOrderRoutingLine."Routing No.");
        ProdOrderCapNeed.SetRange("Routing Reference No.", ProdOrderRoutingLine."Routing Reference No.");
        ProdOrderCapNeed.SetRange("Operation No.", ProdOrderRoutingLine."Operation No.");
        ProdOrderCapNeed.DeleteAll();

        NextCapNeedLineNo := 1;

        ProdOrderRoutingLine.TestField("Work Center No.");

        CurrentWorkCenterNo := '';
        Workcenter.Get(ProdOrderRoutingLine."Work Center No.");
        if ProdOrderRoutingLine.Type = ProdOrderRoutingLine.Type::"Machine Center" then begin
            MachineCenter.Get(ProdOrderRoutingLine."No.");
            Workcenter."Queue Time" := MachineCenter."Queue Time";
            Workcenter."Queue Time Unit of Meas. Code" := MachineCenter."Queue Time Unit of Meas. Code";
        end;
        if not CalcStartEndDate then
            Clear(Workcenter."Queue Time");
        ProdOrder.Get(ProdOrderRoutingLine.Status, ProdOrderRoutingLine."Prod. Order No.");

        ProdOrderQty := 0;
        TotalScrap := 0;
        TotalLotSize := 0;
        ProdOrderLine.SetRange(Status, ProdOrderRoutingLine.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        ProdOrderLine.SetRange("Routing Reference No.", ProdOrderRoutingLine."Routing Reference No.");
        ProdOrderLine.SetRange("Routing No.", ProdOrderRoutingLine."Routing No.");
        ProdOrderLine.SetLoadFields("Quantity (Base)", "Scrap %", "Prod. Order No.", "Line No.", Status, "Routing No.", "Routing Version Code", "Ending Date", "Ending Time");
        OnCalculateRoutingLineOnAfterProdOrderLineSetFilters(ProdOrderLine, ProdOrder, ProdOrderRoutingLine);
        if ProdOrderLine.Find('-') then begin
            ExpectedOperOutput := 0;
            repeat
                IsHandled := false;
                OnCalculateRoutingLineOnBeforeCalcExpectedOperOutput(ProdOrderLine, ExpectedOperOutput, IsHandled);
                if not IsHandled then
                    ExpectedOperOutput := ExpectedOperOutput + ProdOrderLine."Quantity (Base)";
                TotalScrap := TotalScrap + ProdOrderLine."Scrap %";
            until ProdOrderLine.Next() = 0;
            ActualOperOutput := MfgCostCalcMgt.CalcActOutputQtyBase(ProdOrderLine, ProdOrderRoutingLine);
            ProdOrderQty := ExpectedOperOutput - ActualOperOutput;
            if ProdOrderQty < 0 then
                ProdOrderQty := 0;
        end;

        MaxLotSize :=
          ExpectedOperOutput *
          (1 + ProdOrderRoutingLine."Scrap Factor % (Accumulated)") *
          (1 + TotalScrap / 100) +
          ProdOrderRoutingLine."Fixed Scrap Qty. (Accum.)";

        OnCalculateRoutingLineOnAfterCalcMaxLotSize(ProdOrderQty, ProdOrderRoutingLine, TotalScrap, MaxLotSize);

        ProdOrderRoutingLine."Input Quantity" := MaxLotSize;

        if ActualOperOutput > 0 then
            TotalQtyPerOperation :=
              ExpectedOperOutput *
              (1 + ProdOrderRoutingLine."Scrap Factor % (Accumulated)") *
              (1 + TotalScrap / 100) +
              ProdOrderRoutingLine."Fixed Scrap Qty. (Accum.)"
        else
            TotalQtyPerOperation := MaxLotSize;

        OnBeforeCalcExpectedCost(ProdOrderRoutingLine, MaxLotSize, TotalQtyPerOperation, ActualOperOutput, ExpectedOperOutput, TotalScrap);

        TotalCapacityPerOperation :=
          Round(
            TotalQtyPerOperation *
            ProdOrderRoutingLine.RunTimePer() *
            CalendarMgt.QtyperTimeUnitofMeasure(
              ProdOrderRoutingLine."Work Center No.", ProdOrderRoutingLine."Run Time Unit of Meas. Code"),
            UOMMgt.QtyRndPrecision());

        OnCalculateRoutingLineOnBeforeCalcCostInclSetup(ProdOrderRoutingLine, TotalCapacityPerOperation, TotalQtyPerOperation);
        if MfgSetup."Cost Incl. Setup" then
            CalcCostInclSetup(ProdOrderRoutingLine, TotalCapacityPerOperation);
        OnCalculateRoutingLineOnAfterCalcCostInclSetup(ProdOrderRoutingLine, TotalCapacityPerOperation, TotalQtyPerOperation);

        CalcExpectedCost(ProdOrderRoutingLine, TotalQtyPerOperation, TotalCapacityPerOperation);

        IsHandled := false;
        OnBeforeScheduleRoutingLine(ProdOrderRoutingLine, CalcStartEndDate, IsHandled);
        if not IsHandled then
            if ProdOrderRoutingLine."Schedule Manually" then
                CalculateRoutingLineFixed()
            else
                if Direction = Direction::Backward then
                    CalcRoutingLineBack(CalcStartEndDate)
                else
                    CalcRoutingLineForward(CalcStartEndDate);

        OnAfterCalculateRoutingLine(ProdOrderRoutingLine, Enum::"Transfer Direction".FromInteger(Direction));

        ProdOrderRoutingLine2 := ProdOrderRoutingLine;
    end;

    local procedure SetLotSizesToMax(var SendAheadLotSize: Decimal; var TotalLotSize: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetLotSizesToMax(SendAheadLotSize, TotalLotSize, MaxLotSize, ProdOrderRoutingLine, IsHandled);
        if IsHandled then
            exit;

        TotalLotSize := MaxLotSize;
        SendAheadLotSize := MaxLotSize;
    end;

    local procedure FinitelyLoadCapBack(TimeType: Enum "Routing Time Type"; ConstrainedCapacity: Record "Capacity Constrained Resource"; ResourceIsConstrained: Boolean; ParentWorkCenter: Record "Capacity Constrained Resource"; ParentIsConstrained: Boolean)
    var
        LastProdOrderCapNeed: Record "Prod. Order Capacity Need";
        AvailTime: Decimal;
        ProdEndingDateTime: DateTime;
        ProdEndingDateTimeAddOneDay: DateTime;
        SetupTime: Decimal;
        TimetoProgram: Decimal;
        AvailCap: Decimal;
        DampTime: Decimal;
        xConCurrCap: Decimal;
        EndTime: Time;
        StartTime: Time;
        ShouldProcessLastProdOrderCapNeed: Boolean;
    begin
        if (RemainNeedQty = 0) and WaitTimeOnly then
            exit;
        EndTime := ProdEndingTime;
        ProdEndingDateTime := CreateDateTime(ProdEndingDate, ProdEndingTime);
        ProdEndingDateTimeAddOneDay := CreateDateTime(ProdEndingDate + 1, ProdEndingTime);
        ConCurrCap := ProdOrderRoutingLine."Concurrent Capacities";
        xConCurrCap := 1;

        LastProdOrderCapNeed.SetCapacityFilters(ProdOrderRoutingLine.Type, ProdOrderRoutingLine."No.");

        CalendarEntry.SetCapacityFilters(ProdOrderRoutingLine.Type, ProdOrderRoutingLine."No.");
        CalendarEntry.SetFilter("Starting Date-Time", '<= %1', ProdEndingDateTime);
        CalendarEntry.SetFilter("Ending Date-Time", '<= %1', ProdEndingDateTimeAddOneDay);
        OnFinitelyLoadCapBackOnAfterSetCalendarEntryFilters(CalendarEntry);
        if CalendarEntry.Find('+') then
            repeat
                if (EndTime > CalendarEntry."Ending Time") or (EndTime < CalendarEntry."Starting Time") or
                   (ProdEndingDate <> CalendarEntry.Date)
                then
                    EndTime := CalendarEntry."Ending Time";
                StartTime := EndTime;

                if (ConCurrCap = 0) or (CalendarEntry.Capacity < ConCurrCap) then
                    ConCurrCap := CalendarEntry.Capacity;
                if TimeType <> TimeType::"Run Time" then
                    RemainNeedQty := RemainNeedQty * ConCurrCap / xConCurrCap;
                xConCurrCap := ConCurrCap;

                CalculateDailyLoad(AvailCap, DampTime, ConstrainedCapacity, ResourceIsConstrained, ParentWorkCenter, ParentIsConstrained);
                SetupTime := 0;
                if TimeType = TimeType::"Run Time" then begin
                    SetupTime :=
                      Round(
                        ProdOrderRoutingLine."Setup Time" *
                        CalendarMgt.TimeFactor(ProdOrderRoutingLine."Setup Time Unit of Meas. Code") /
                        CalendarMgt.TimeFactor(Workcenter."Unit of Measure Code"),
                        Workcenter."Calendar Rounding Precision");
                    SetupTime := SetupTime * ConCurrCap;
                    OnFinitelyLoadCapBackOnAfterCalcSetupTime(ProdOrderRoutingLine, Workcenter, SetupTime);
                end;
                if RemainNeedQty + SetupTime <= AvailCap + DampTime then
                    AvailCap := AvailCap + DampTime;
                AvailCap :=
                  Round(AvailCap *
                    CalendarMgt.TimeFactor(Workcenter."Unit of Measure Code") *
                    100 / CalendarEntry.Efficiency / ConCurrCap, 1, '>');
                if CalendarEntry.Capacity = CalendarEntry."Absence Capacity" then
                    AvailCap := 0;

                ShouldProcessLastProdOrderCapNeed := AvailCap > 0;
                OnFinitelyLoadCapBackOnAfterCalcShouldProcessLastProdOrderCapNeed(
                    ProdOrderRoutingLine, AvailCap, CalendarEntry, ProdEndingTime, ProdEndingDate, TimeType, FirstInBatch, FirstEntry,
                    UpdateDates, RemainNeedQty, ProdOrderCapNeed, ProdOrder, NextCapNeedLineNo, Workcenter, LotSize, ShouldProcessLastProdOrderCapNeed);
                if ShouldProcessLastProdOrderCapNeed then begin
                    ProdEndingDateTime := CreateDateTime(CalendarEntry.Date, EndTime);
                    LastProdOrderCapNeed.SetFilter(
                      "Ending Date-Time", '>= %1 & < %2', CalendarEntry."Starting Date-Time", ProdEndingDateTimeAddOneDay);
                    LastProdOrderCapNeed.SetFilter(
                      "Starting Date-Time", '>= %1 & < %2', CalendarEntry."Starting Date-Time", ProdEndingDateTime);
                    if LastProdOrderCapNeed.Find('+') then
                        repeat
                            if LastProdOrderCapNeed."Ending Time" < EndTime then begin
                                AvailTime := Min(CalendarMgt.CalcTimeDelta(EndTime, LastProdOrderCapNeed."Ending Time"), AvailCap);
                                if AvailTime > 0 then begin
                                    UpdateTimesBack(AvailTime, AvailCap, TimetoProgram, StartTime, EndTime);
                                    CreateCapNeed(CalendarEntry.Date, StartTime, EndTime, TimetoProgram, TimeType, 1);
                                    if FirstInBatch and FirstEntry then begin
                                        FirstInBatch := false;
                                        FirstEntry := false
                                    end;
                                    if UpdateDates then begin
                                        ProdOrderRoutingLine."Ending Time" := EndTime;
                                        ProdOrderRoutingLine."Ending Date" := CalendarEntry.Date;
                                        UpdateDates := false
                                    end;
                                    EndTime := StartTime;
                                end;
                            end;
                            if LastProdOrderCapNeed."Starting Time" < EndTime then
                                EndTime := LastProdOrderCapNeed."Starting Time";
                        until (LastProdOrderCapNeed.Next(-1) = 0) or (RemainNeedQty = 0) or (AvailCap = 0);

                    if (AvailCap > 0) and (RemainNeedQty > 0) then begin
                        AvailTime := Min(CalendarMgt.CalcTimeDelta(EndTime, CalendarEntry."Starting Time"), AvailCap);
                        if AvailTime > 0 then begin
                            UpdateTimesBack(AvailTime, AvailCap, TimetoProgram, StartTime, EndTime);
                            AdjustStartingTime(CalendarEntry, StartTime);

                            if TimetoProgram <> 0 then
                                CreateCapNeed(CalendarEntry.Date, StartTime, EndTime, TimetoProgram, TimeType, 1);
                            if FirstInBatch and FirstEntry then begin
                                FirstInBatch := false;
                                FirstEntry := false
                            end;
                            if UpdateDates then begin
                                ProdOrderRoutingLine."Ending Time" := EndTime;
                                ProdOrderRoutingLine."Ending Date" := CalendarEntry.Date;
                                UpdateDates := false
                            end;
                            EndTime := StartTime;
                        end;
                    end;
                end;
                if RemainNeedQty > 0 then begin
                    if CalendarEntry.Next(-1) = 0 then begin
                        TestForError(Text001, Text002, CalendarEntry.Date);
                        exit;
                    end;
                    EndTime := CalendarEntry."Ending Time";
                end else begin
                    ProdEndingTime := StartTime;
                    ProdEndingDate := CalendarEntry.Date;
                    ProdOrderRoutingLine."Starting Time" := StartTime;
                    ProdOrderRoutingLine."Starting Date" := CalendarEntry.Date;
                    exit;
                end;
            until false;
    end;

    local procedure FinitelyLoadCapForward(TimeType: Enum "Routing Time Type"; ConstrainedCapacity: Record "Capacity Constrained Resource"; ResourceIsConstrained: Boolean; ParentWorkCenter: Record "Capacity Constrained Resource"; ParentIsConstrained: Boolean)
    var
        NextProdOrderCapNeed: Record "Prod. Order Capacity Need";
        AvailTime: Decimal;
        ProdStartingDateTime: DateTime;
        ProdStartingDateTimeSubOneDay: DateTime;
        RunTime: Decimal;
        TimetoProgram: Decimal;
        AvailCap: Decimal;
        DampTime: Decimal;
        xConCurrCap: Decimal;
        EndTime: Time;
        StartTime: Time;
    begin
        if (RemainNeedQty = 0) and WaitTimeOnly then
            exit;
        StartTime := ProdStartingTime;
        ProdStartingDateTime := CreateDateTime(ProdStartingDate, ProdStartingTime);
        ProdStartingDateTimeSubOneDay := CreateDateTime(ProdStartingDate - 1, ProdStartingTime);
        ConCurrCap := ProdOrderRoutingLine."Concurrent Capacities";
        xConCurrCap := 1;

        NextProdOrderCapNeed.SetCapacityFilters(ProdOrderRoutingLine.Type, ProdOrderRoutingLine."No.");

        CalendarEntry.SetCapacityFilters(ProdOrderRoutingLine.Type, ProdOrderRoutingLine."No.");
        CalendarEntry.SetFilter("Starting Date-Time", '>= %1', ProdStartingDateTimeSubOneDay);
        CalendarEntry.SetFilter("Ending Date-Time", '>= %1', ProdStartingDateTime);
        if CalendarEntry.Find('-') then
            repeat
                if (StartTime < CalendarEntry."Starting Time") or (StartTime > CalendarEntry."Ending Time") or
                   (ProdStartingDate <> CalendarEntry.Date)
                then
                    StartTime := CalendarEntry."Starting Time";
                EndTime := StartTime;

                if (ConCurrCap = 0) or (CalendarEntry.Capacity < ConCurrCap) then
                    ConCurrCap := CalendarEntry.Capacity;
                if TimeType <> TimeType::"Run Time" then
                    RemainNeedQty := RemainNeedQty * ConCurrCap / xConCurrCap;
                xConCurrCap := ConCurrCap;

                CalculateDailyLoad(AvailCap, DampTime, ConstrainedCapacity, ResourceIsConstrained, ParentWorkCenter, ParentIsConstrained);
                RunTime := 0;
                if TimeType = TimeType::"Setup Time" then begin
                    RunTime := LotSize * ProdOrderRoutingLine.RunTimePer();
                    RunTime :=
                      Round(RunTime *
                        CalendarMgt.TimeFactor(ProdOrderRoutingLine."Run Time Unit of Meas. Code") /
                        CalendarMgt.TimeFactor(Workcenter."Unit of Measure Code"),
                        Workcenter."Calendar Rounding Precision");
                end;
                if RemainNeedQty + RunTime <= AvailCap + DampTime then
                    AvailCap := AvailCap + DampTime;
                AvailCap :=
                  Round(AvailCap *
                    CalendarMgt.TimeFactor(Workcenter."Unit of Measure Code") *
                    100 / CalendarEntry.Efficiency / ConCurrCap, 1, '>');
                if CalendarEntry.Capacity = CalendarEntry."Absence Capacity" then
                    AvailCap := 0;

                if AvailCap > 0 then begin
                    ProdStartingDateTime := CreateDateTime(CalendarEntry.Date, StartTime);
                    NextProdOrderCapNeed.SetFilter(
                      "Ending Date-Time", '> %1 & <= %2', ProdStartingDateTime, CalendarEntry."Ending Date-Time");
                    NextProdOrderCapNeed.SetFilter(
                      "Starting Date-Time", '> %1 & <= %2', ProdStartingDateTimeSubOneDay, CalendarEntry."Ending Date-Time");
                    if NextProdOrderCapNeed.Find('-') then
                        repeat
                            if NextProdOrderCapNeed."Starting Time" > StartTime then begin
                                AvailTime := Min(CalendarMgt.CalcTimeDelta(NextProdOrderCapNeed."Starting Time", StartTime), AvailCap);
                                if AvailTime > 0 then begin
                                    UpdateTimesForward(AvailTime, AvailCap, TimetoProgram, StartTime, EndTime);
                                    CreateCapNeed(CalendarEntry.Date, StartTime, EndTime, TimetoProgram, TimeType, 0);
                                    if FirstInBatch and FirstEntry then begin
                                        FirstInBatch := false;
                                        FirstEntry := false
                                    end;
                                    if UpdateDates then begin
                                        ProdOrderRoutingLine."Starting Time" := StartTime;
                                        ProdOrderRoutingLine."Starting Date" := CalendarEntry.Date;
                                        UpdateDates := false
                                    end;
                                    StartTime := EndTime;
                                end;
                            end;
                            if NextProdOrderCapNeed."Ending Time" > StartTime then
                                StartTime := NextProdOrderCapNeed."Ending Time"
                        until (NextProdOrderCapNeed.Next() = 0) or (RemainNeedQty = 0) or (AvailCap = 0);

                    if (AvailCap > 0) and (RemainNeedQty > 0) then begin
                        AvailTime := Min(CalendarMgt.CalcTimeDelta(CalendarEntry."Ending Time", StartTime), AvailCap);
                        if AvailTime > 0 then begin
                            UpdateTimesForward(AvailTime, AvailCap, TimetoProgram, StartTime, EndTime);
                            AdjustEndingTime(CalendarEntry, EndTime);
                            if TimetoProgram <> 0 then
                                CreateCapNeed(CalendarEntry.Date, StartTime, EndTime, TimetoProgram, TimeType, 0);
                            if FirstInBatch and FirstEntry then begin
                                FirstInBatch := false;
                                FirstEntry := false
                            end;
                            if UpdateDates then begin
                                ProdOrderRoutingLine."Starting Time" := StartTime;
                                ProdOrderRoutingLine."Starting Date" := CalendarEntry.Date;
                                UpdateDates := false
                            end;
                            StartTime := EndTime;
                        end;
                    end;
                end;
                if RemainNeedQty > 0 then begin
                    if CalendarEntry.Next() = 0 then begin
                        TestForError(Text003, Text004, CalendarEntry.Date);
                        exit;
                    end;
                    StartTime := CalendarEntry."Starting Time";
                end else begin
                    ProdStartingTime := EndTime;
                    ProdStartingDate := CalendarEntry.Date;
                    ProdOrderRoutingLine."Ending Time" := EndTime;
                    ProdOrderRoutingLine."Ending Date" := CalendarEntry.Date;
                    exit;
                end;
            until false;
    end;

    local procedure AdjustEndingTime(CalendarEntry: Record "Calendar Entry"; var EndingTime: Time)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAdjustEndingTime(IsHandled, CalendarEntry, EndingTime);
        if IsHandled then
            exit;

        if EndingTime > CalendarEntry."Ending Time" then
            EndingTime := CalendarEntry."Ending Time";
    end;

    local procedure AdjustStartingTime(CalendarEntry: Record "Calendar Entry"; var StartingTime: Time)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAdjustStartingTime(IsHandled, CalendarEntry, StartingTime);
        if IsHandled then
            exit;

        if StartingTime < CalendarEntry."Starting Time" then
            StartingTime := CalendarEntry."Starting Time";
    end;

    local procedure CalculateDailyLoad(var AvailCap: Decimal; var DampTime: Decimal; ConstrainedCapacity: Record "Capacity Constrained Resource"; IsResourceConstrained: Boolean; ParentWorkCenter: Record "Capacity Constrained Resource"; IsParentConstrained: Boolean)
    var
        CurrentLoadBase: Decimal;
        AvailCapWorkCenter: Decimal;
        DampTimeWorkCenter: Decimal;
        CapEffectiveBase: Decimal;
    begin
        GetCurrentWorkCenterTimeFactorAndRounding(Workcenter."No.");
        if (CalendarEntry."Capacity Type" = CalendarEntry."Capacity Type"::"Work Center") or
           ((CalendarEntry."Capacity Type" = CalendarEntry."Capacity Type"::"Machine Center") and
            (IsResourceConstrained xor IsParentConstrained))
        then begin
            if IsParentConstrained then begin
                ConstrainedCapacity := ParentWorkCenter;
                CalcCapConResWorkCenterLoadBase(ConstrainedCapacity, CalendarEntry.Date, CapEffectiveBase, CurrentLoadBase)
            end else
                CalcCapConResProdOrderNeedBase(ConstrainedCapacity, CalendarEntry.Date, CapEffectiveBase, CurrentLoadBase);
            CalcAvailCapBaseAndDampTime(
              ConstrainedCapacity, AvailCap, DampTime, CapEffectiveBase, CurrentLoadBase, CurrentTimeFactor, CurrentRounding);
        end
        else begin
            CalcCapConResProdOrderNeedBase(ConstrainedCapacity, CalendarEntry.Date, CapEffectiveBase, CurrentLoadBase);
            CalcAvailCapBaseAndDampTime(
              ConstrainedCapacity, AvailCap, DampTime, CapEffectiveBase, CurrentLoadBase, CurrentTimeFactor, CurrentRounding);

            CalcCapConResWorkCenterLoadBase(ParentWorkCenter, CalendarEntry.Date, CapEffectiveBase, CurrentLoadBase);
            CalcAvailCapBaseAndDampTime(
              ParentWorkCenter, AvailCapWorkCenter, DampTimeWorkCenter, CapEffectiveBase, CurrentLoadBase, CurrentTimeFactor, CurrentRounding);

            if AvailCap + DampTime > AvailCapWorkCenter + DampTimeWorkCenter then
                DampTime := DampTimeWorkCenter
            else
                if AvailCap + DampTime = AvailCapWorkCenter + DampTimeWorkCenter then
                    DampTime := max(DampTime, DampTimeWorkCenter);
            AvailCap := Round(Min(AvailCap, AvailCapWorkCenter), 1);
        end;
    end;

    local procedure UpdateTimesBack(var AvailTime: Decimal; var AvailCap: Decimal; var TimetoProgram: Decimal; var StartTime: Time; EndTime: Time)
    var
        RoundedTimetoProgram: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateTimesBack(CalendarEntry, ProdOrderRoutingLine, AvailTime, AvailCap, TimetoProgram, StartTime, EndTime, ConCurrCap, Workcenter, RemainNeedQty, IsHandled);
        if IsHandled then
            exit;

        AvailTime :=
          Round(AvailTime / CalendarMgt.TimeFactor(Workcenter."Unit of Measure Code") *
            CalendarEntry.Efficiency / 100 * ConCurrCap, Workcenter."Calendar Rounding Precision");
        TimetoProgram := Min(RemainNeedQty, AvailTime);
        RoundedTimetoProgram :=
          Round(TimetoProgram *
            CalendarMgt.TimeFactor(Workcenter."Unit of Measure Code") *
            100 / CalendarEntry.Efficiency / ConCurrCap, 1, '>');
        StartTime := CalendarMgt.CalcTimeSubtract(EndTime, RoundedTimetoProgram);
        RemainNeedQty := RemainNeedQty - TimetoProgram;
        if ProdOrderRoutingLine.Status <> ProdOrderRoutingLine.Status::Simulated then
            AvailCap := AvailCap - RoundedTimetoProgram;
    end;

    local procedure UpdateTimesForward(var AvailTime: Decimal; var AvailCap: Decimal; var TimetoProgram: Decimal; StartTime: Time; var EndTime: Time)
    var
        RoundedTimetoProgram: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateTimesForward(CalendarEntry, ProdOrderRoutingLine, AvailTime, AvailCap, TimetoProgram, StartTime, EndTime, ConCurrCap, Workcenter, RemainNeedQty, IsHandled);
        if IsHandled then
            exit;

        AvailTime :=
          Round(AvailTime / CalendarMgt.TimeFactor(Workcenter."Unit of Measure Code") *
            CalendarEntry.Efficiency / 100 * ConCurrCap, Workcenter."Calendar Rounding Precision");
        TimetoProgram := Min(RemainNeedQty, AvailTime);
        RoundedTimetoProgram :=
          Round(TimetoProgram *
            CalendarMgt.TimeFactor(Workcenter."Unit of Measure Code") *
            100 / CalendarEntry.Efficiency / ConCurrCap, 1, '>');
        EndTime := StartTime + RoundedTimetoProgram;
        RemainNeedQty := RemainNeedQty - TimetoProgram;
        if ProdOrderRoutingLine.Status <> ProdOrderRoutingLine.Status::Simulated then
            AvailCap := AvailCap - RoundedTimetoProgram;
    end;

    local procedure "Min"(Number1: Decimal; Number2: Decimal): Decimal
    begin
        if Number1 <= Number2 then
            exit(Number1);

        exit(Number2);
    end;

    local procedure "Max"(Number1: Decimal; Number2: Decimal): Decimal
    begin
        if Number1 >= Number2 then
            exit(Number1);

        exit(Number2);
    end;

    local procedure CalcExpectedCost(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; TotalQtyPerOperation: Decimal; TotalCapacityPerOperation: Decimal)
    begin
        if ProdOrderRoutingLine."Unit Cost Calculation" = ProdOrderRoutingLine."Unit Cost Calculation"::Time then begin
            ProdOrderRoutingLine."Expected Operation Cost Amt." :=
              TotalCapacityPerOperation * ProdOrderRoutingLine."Unit Cost per";
            ProdOrderRoutingLine."Expected Capacity Ovhd. Cost" :=
              TotalCapacityPerOperation *
              (ProdOrderRoutingLine."Direct Unit Cost" *
               ProdOrderRoutingLine."Indirect Cost %" / 100 + ProdOrderRoutingLine."Overhead Rate");
        end else begin
            ProdOrderRoutingLine."Expected Operation Cost Amt." :=
              TotalQtyPerOperation * ProdOrderRoutingLine."Unit Cost per";
            ProdOrderRoutingLine."Expected Capacity Ovhd. Cost" :=
              TotalQtyPerOperation *
              (ProdOrderRoutingLine."Direct Unit Cost" *
               ProdOrderRoutingLine."Indirect Cost %" / 100 + ProdOrderRoutingLine."Overhead Rate");
        end;
    end;

    local procedure CalcCostInclSetup(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var TotalCapacityPerOperation: Decimal)
    var
        ConcurrentCapacity: Decimal;
    begin
        OnBeforeCalcCostInclSetup(ProdOrderRoutingLine, TotalCapacityPerOperation);

        ConcurrentCapacity := ProdOrderRoutingLine."Concurrent Capacities";
        if ConcurrentCapacity = 0 then
            ConcurrentCapacity := 1;
        TotalCapacityPerOperation :=
          TotalCapacityPerOperation +
          Round(
            ConcurrentCapacity * ProdOrderRoutingLine."Setup Time" *
            CalendarMgt.QtyperTimeUnitofMeasure(
              ProdOrderRoutingLine."Work Center No.", ProdOrderRoutingLine."Setup Time Unit of Meas. Code"),
            UOMMgt.QtyRndPrecision());

        OnAfterCalcCostInclSetup(ProdOrderRoutingLine, TotalCapacityPerOperation);
    end;

    local procedure CalcDuration(DateTime1: DateTime; DateTime2: DateTime) TotalDuration: Decimal
    begin
        TotalDuration :=
          Round(
            (DT2Date(DateTime2) - DT2Date(DateTime1)) * (86400000 / CalendarMgt.TimeFactor(Workcenter."Unit of Measure Code")) +
            (DT2Time(DateTime2) - DT2Time(DateTime1)) / CalendarMgt.TimeFactor(Workcenter."Unit of Measure Code"),
            Workcenter."Calendar Rounding Precision");
        exit(TotalDuration);
    end;

    local procedure FindSendAheadEndingTime(var TempProdOrderRoutingLine: Record "Prod. Order Routing Line"; var SendAheadLotSize: Decimal): Boolean
    var
        Result: Boolean;
        xTotalLotSize: Decimal;
        xSendAheadLotSize: Decimal;
    begin
        xTotalLotSize := TotalLotSize;
        xSendAheadLotSize := SendAheadLotSize;
        if TempProdOrderRoutingLine.FindSet() then
            repeat
                TotalLotSize := xTotalLotSize;
                SendAheadLotSize := xSendAheadLotSize;

                Result := Result or GetSendAheadEndingTime(TempProdOrderRoutingLine, SendAheadLotSize);
            until TempProdOrderRoutingLine.Next() = 0
        else
            Result := GetSendAheadEndingTime(TempProdOrderRoutingLine, SendAheadLotSize);

        exit(Result);
    end;

    local procedure FindSendAheadStartingTime(var TempProdOrderRoutingLine: Record "Prod. Order Routing Line"; var SendAheadLotSize: Decimal): Boolean
    var
        Result: Boolean;
        xTotalLotSize: Decimal;
        xSendAheadLotSize: Decimal;
    begin
        xTotalLotSize := TotalLotSize;
        xSendAheadLotSize := SendAheadLotSize;
        if TempProdOrderRoutingLine.FindSet() then
            repeat
                TotalLotSize := xTotalLotSize;
                SendAheadLotSize := xSendAheadLotSize;
                Result := Result or GetSendAheadStartingTime(TempProdOrderRoutingLine, SendAheadLotSize);
            until TempProdOrderRoutingLine.Next() = 0
        else
            Result := GetSendAheadStartingTime(TempProdOrderRoutingLine, SendAheadLotSize);

        exit(Result);
    end;

    procedure ReturnNextCalendarEntry(var CalendarEntry2: Record "Calendar Entry"; OldCalendarEntry: Record "Calendar Entry"; Direction: Option Backward,Forward)
    begin
        CalendarEntry2 := OldCalendarEntry;
        CalendarEntry2.SetRange(Date, CalendarEntry2.Date);
        OnReturnNextCalendarEntryOnAfterSetCalendarEntryDateFilter(CalendarEntry);

        if Direction = Direction::Backward then begin
            CalendarEntry2.Find('-');           // rewind within the same day
            CalendarEntry2.SetRange(Date);
            if CalendarEntry2.Next(-1) = 0 then
                TestForError(Text001, Text002, CalendarEntry2.Date);

            if (CalendarEntry2.Date + 1) < OldCalendarEntry.Date then begin
                CalendarEntry2.Date := OldCalendarEntry.Date - 1;
                CreateCalendarEntry(CalendarEntry2);
            end;
        end else begin
            CalendarEntry2.Find('+');            // rewind within the same day
            CalendarEntry2.SetRange(Date);
            if CalendarEntry2.Next() = 0 then
                TestForError(Text003, Text004, CalendarEntry2.Date);

            if OldCalendarEntry.Date < (CalendarEntry2.Date - 1) then begin
                CalendarEntry2.Date := OldCalendarEntry.Date + 1;
                CreateCalendarEntry(CalendarEntry2);
            end;
        end;
    end;

    local procedure CreateCalendarEntry(var CalendarEntry2: Record "Calendar Entry")
    begin
        CalendarEntry2."Ending Time" := 000000T;
        CalendarEntry2."Starting Time" := 000000T;
        CalendarEntry2.Efficiency := 100;
        CalendarEntry2."Absence Capacity" := 0;
        CalendarEntry2."Capacity (Total)" := 0;
        CalendarEntry2."Capacity (Effective)" := CalendarEntry2."Capacity (Total)";
        CalendarEntry2."Starting Date-Time" := CreateDateTime(CalendarEntry2.Date, CalendarEntry2."Starting Time");
        CalendarEntry2."Ending Date-Time" := CalendarEntry2."Starting Date-Time" + 86400000;
        if not CalendarEntry2.Get(CalendarEntry2."Capacity Type", CalendarEntry2."No.", CalendarEntry2.Date, CalendarEntry2."Starting Time", CalendarEntry2."Ending Time", CalendarEntry2."Work Shift Code") then
            CalendarEntry2.Insert();
    end;

    local procedure GetCurrentWorkCenterTimeFactorAndRounding(WorkCenterNo: Code[20])
    var
        WorkCenter: Record "Work Center";
    begin
        if CurrentWorkCenterNo = WorkCenterNo then
            exit;

        WorkCenter.Get(WorkCenterNo);
        CurrentTimeFactor := CalendarMgt.TimeFactor(WorkCenter."Unit of Measure Code");
        CurrentRounding := WorkCenter."Calendar Rounding Precision";
    end;

    local procedure CalcCapConResWorkCenterLoadBase(CapacityConstrainedResource: Record "Capacity Constrained Resource"; DateFilter: Date; var CapEffectiveBase: Decimal; var LoadBase: Decimal)
    begin
        CapEffectiveBase := 0;
        LoadBase := 0;

        CapacityConstrainedResource.SetRange("Date Filter", DateFilter);
        CapacityConstrainedResource.CalcFields("Capacity (Effective)", "Work Center Load Qty.");
        if CapacityConstrainedResource."Capacity (Effective)" <> 0 then begin
            CapEffectiveBase := Round(CapacityConstrainedResource."Capacity (Effective)" * CurrentTimeFactor, CurrentRounding);
            LoadBase := Round(CapacityConstrainedResource."Work Center Load Qty." * CurrentTimeFactor, CurrentRounding);
        end;
    end;

    local procedure CalcCapConResProdOrderNeedBase(CapacityConstrainedResource: Record "Capacity Constrained Resource"; DateFilter: Date; var CapEffectiveBase: Decimal; var LoadBase: Decimal)
    begin
        CapEffectiveBase := 0;
        LoadBase := 0;

        CapacityConstrainedResource.SetRange("Date Filter", DateFilter);
        CapacityConstrainedResource.CalcFields("Capacity (Effective)", "Prod. Order Need Qty.");
        if CapacityConstrainedResource."Capacity (Effective)" <> 0 then begin
            CapEffectiveBase := Round(CapacityConstrainedResource."Capacity (Effective)" * CurrentTimeFactor, CurrentRounding);
            LoadBase := Round(CapacityConstrainedResource."Prod. Order Need Qty." * CurrentTimeFactor, CurrentRounding);
        end;
    end;

    procedure CalcAvailCapBaseAndDampTime(CapacityConstrainedResource: Record "Capacity Constrained Resource"; var AvailCap: Decimal; var DampTime: Decimal; CapEffectiveBase: Decimal; LoadBase: Decimal; TimeFactor: Decimal; Rounding: Decimal)
    var
        AvailCapBase: Decimal;
        AvailCapBaseMax: Decimal;
        LoadPct: Decimal;
        DampenerPct: Decimal;
        CriticalLoadPct: Decimal;
    begin
        AvailCap := 0;
        DampTime := 0;

        if CapEffectiveBase = 0 then
            exit;

        CriticalLoadPct := CapacityConstrainedResource."Critical Load %";
        AvailCapBaseMax := Round(CapEffectiveBase * CriticalLoadPct / 100, Rounding);
        AvailCapBase := max(0, AvailCapBaseMax - LoadBase);
        AvailCap := Round(AvailCapBase / TimeFactor, Rounding);

        LoadPct := Round(LoadBase / CapEffectiveBase * 100, Rounding);
        DampenerPct := CapacityConstrainedResource."Dampener (% of Total Capacity)";
        DampTime :=
          Round(CapEffectiveBase / TimeFactor * Min(DampenerPct, CriticalLoadPct + DampenerPct - LoadPct) / 100, Rounding);
        DampTime := Round(Max(0, DampTime), 1);
    end;

    procedure CalcAvailQtyBase(var CalendarEntry: Record "Calendar Entry"; ProdStartDate: Date; ProdStartTime: Time; TimeType: Enum "Routing Time Type"; ConCurrCap: Decimal; IsForward: Boolean; TimeFactor: Decimal; Rounding: Decimal) AvQtyBase: Decimal
    var
        CalendarStartTime: Time;
        CalendarEndTime: Time;
        CalcFactor: Integer;
        ModifyCalendar: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcAvailQtyBase(CalendarEntry, TimeType, AvQtyBase, IsHandled);
        if IsHandled then
            exit(AvQtyBase);

        if IsForward then begin
            CalendarStartTime := CalendarEntry."Starting Time";
            CalendarEndTime := CalendarEntry."Ending Time";
            CalcFactor := -1
        end else begin
            CalendarStartTime := CalendarEntry."Ending Time";
            CalendarEndTime := CalendarEntry."Starting Time";
            CalcFactor := 1;
        end;
        ModifyCalendar := false;

        if (((CalendarStartTime < ProdStartTime) and IsForward) or
            ((CalendarStartTime > ProdStartTime) and not IsForward)) and
           (CalendarEntry.Date = ProdStartDate)
        then begin
            case TimeType of
                TimeType::"Setup Time",
              TimeType::"Run Time":
                    AvQtyBase :=
                      Round(
                        Abs(CalendarEndTime - ProdStartTime) *
                        CalendarEntry.Efficiency / 100 * ConCurrCap, Rounding);
                TimeType::"Move Time",
              TimeType::"Queue Time":
                    AvQtyBase :=
                      Round(
                        Abs(CalendarEndTime - ProdStartTime) *
                        ConCurrCap, Rounding);
                TimeType::"Wait Time":
                    begin
                        AvQtyBase := CalcAvailQtyBaseForWaitTime(ProdStartTime, ProdStartDate, CalendarEntry.Date, CalcFactor, IsForward);
                        AvQtyBase := Round(AvQtyBase * ConCurrCap, Rounding);
                    end;
            end;
            ModifyCalendar := true;
        end else
            if (CalendarEntry.Capacity = CalendarEntry."Absence Capacity") and
               (TimeType <> TimeType::"Wait Time")
            then
                AvQtyBase := 0
            else
                case TimeType of
                    TimeType::"Setup Time",
                  TimeType::"Run Time":
                        AvQtyBase :=
                          Round(
                            TimeFactor * CalendarEntry."Capacity (Effective)" /
                            (CalendarEntry.Capacity - CalendarEntry."Absence Capacity") * ConCurrCap,
                            Rounding);
                    TimeType::"Move Time",
                  TimeType::"Queue Time":
                        AvQtyBase :=
                          Round(
                            TimeFactor * CalendarEntry."Capacity (Total)" /
                            (CalendarEntry.Capacity - CalendarEntry."Absence Capacity") * ConCurrCap,
                            Rounding);
                    TimeType::"Wait Time":
                        begin
                            AvQtyBase := CalcAvailQtyBaseForWaitTime(ProdStartTime, ProdStartDate, CalendarEntry.Date, CalcFactor, IsForward);
                            AvQtyBase := Round(AvQtyBase * ConCurrCap, Rounding);
                            ModifyCalendar := true;
                        end;
                end;

        if ModifyCalendar then
            if IsForward then
                CalendarEntry."Starting Time" := ProdStartTime
            else
                CalendarEntry."Ending Time" := ProdStartTime;
    end;

    local procedure CalcAvailQtyBaseForWaitTime(ProdStartTime: Time; ProdStartDate: Date; CalendarEntryDate: Date; CalcFactor: Integer; IsForward: Boolean): Decimal
    begin
        if (ProdStartTime = 000000T) and ((CalendarEntryDate <> ProdStartDate) or IsForward) then
            exit(86400000);
        exit((86400000 + (ProdStartTime - 000000T) * CalcFactor) mod 86400000);
    end;

    local procedure CalcActuallyPostedCapacityTime(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; TimeType: Enum "Routing Time Type"): Decimal
    var
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
    begin
        if TimeType in [TimeType::"Setup Time", TimeType::"Run Time"] then begin
            CapacityLedgerEntry.SetRange("Order Type", CapacityLedgerEntry."Order Type"::Production);
            CapacityLedgerEntry.SetRange("Order No.", ProdOrderRoutingLine."Prod. Order No.");
            CapacityLedgerEntry.SetRange("Routing No.", ProdOrderRoutingLine."Routing No.");
            CapacityLedgerEntry.SetRange("Routing Reference No.", ProdOrderRoutingLine."Routing Reference No.");
            CapacityLedgerEntry.SetRange("Operation No.", ProdOrderRoutingLine."Operation No.");
            if TimeType = TimeType::"Setup Time" then begin
                CapacityLedgerEntry.CalcSums("Setup Time");
                exit(CapacityLedgerEntry."Setup Time");
            end;
            if TimeType = TimeType::"Run Time" then begin
                CapacityLedgerEntry.CalcSums("Run Time");
                exit(CapacityLedgerEntry."Run Time");
            end;
        end;
        exit(0);
    end;

    local procedure CalcDistributedCapacityNeedForOperation(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; TimeType: Enum "Routing Time Type"): Decimal
    var
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
    begin
        ProdOrderCapacityNeed.SetRange(Status, ProdOrderRoutingLine.Status);
        ProdOrderCapacityNeed.SetRange("Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        ProdOrderCapacityNeed.SetRange("Requested Only", false);
        ProdOrderCapacityNeed.SetRange("Routing No.", ProdOrderRoutingLine."Routing No.");
        ProdOrderCapacityNeed.SetRange("Routing Reference No.", ProdOrderRoutingLine."Routing Reference No.");
        ProdOrderCapacityNeed.SetRange("Operation No.", ProdOrderRoutingLine."Operation No.");
        ProdOrderCapacityNeed.SetRange("Time Type", TimeType);
        ProdOrderCapacityNeed.CalcSums("Needed Time", "Allocated Time");
        exit(ProdOrderCapacityNeed."Needed Time" - ProdOrderCapacityNeed."Allocated Time");
    end;

    local procedure SetMaxDateTime(var ResultingDate: Date; var ResultingTime: Time; DateToCompare: Date; TimeToCompare: Time)
    begin
        if ((ResultingDate = DateToCompare) and (ResultingTime >= TimeToCompare)) or
           (ResultingDate > DateToCompare)
        then
            exit;
        ResultingDate := DateToCompare;
        ResultingTime := TimeToCompare;
    end;

    local procedure SetMinDateTime(var ResultingDate: Date; var ResultingTime: Time; DateToCompare: Date; TimeToCompare: Time)
    begin
        if ((ResultingDate = DateToCompare) and (ResultingTime <= TimeToCompare)) or
           (ResultingDate < DateToCompare)
        then
            exit;
        ResultingDate := DateToCompare;
        ResultingTime := TimeToCompare
    end;

    local procedure SetRoutingLineFilters(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var ProdOrderRoutingLine2: Record "Prod. Order Routing Line")
    begin
        ProdOrderRoutingLine2.SetRange(Status, ProdOrderRoutingLine.Status);
        ProdOrderRoutingLine2.SetRange("Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        ProdOrderRoutingLine2.SetRange("Routing Reference No.", ProdOrderRoutingLine."Routing Reference No.");
        ProdOrderRoutingLine2.SetRange("Routing No.", ProdOrderRoutingLine."Routing No.");
        ProdOrderRoutingLine2.SetFilter("Routing Status", '<>%1', ProdOrderRoutingLine2."Routing Status"::Finished);
    end;

    local procedure FilterCalendarEntryBeforeOrOnDateTime(CapacityType: Enum "Capacity Type"; WorkMachineCenterNo: Code[20]; DateValue: Date; TimeValue: Time)
    begin
        CalendarEntry.SetCapacityFilters(CapacityType, WorkMachineCenterNo);
        CalendarEntry.SetRange("Starting Date-Time", 0DT, CreateDateTime(DateValue, TimeValue));
        CalendarEntry.SetRange("Ending Date-Time", 0DT, CreateDateTime(DateValue + 1, TimeValue));
    end;

    procedure ReplanRoutingLine(var ProdOrderRoutingLine2: Record "Prod. Order Routing Line"; Direction: Option Forward,Backward; CalcStartEndDate: Boolean)
    var
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
        MfgCostCalcMgt: Codeunit "Mfg. Cost Calculation Mgt.";
        ActualOperOutput: Decimal;
        TotalQtyPerOperation: Decimal;
        TotalCapacityPerOperation: Decimal;
    begin
        MfgSetup.Get();

        ProdOrderRoutingLine := ProdOrderRoutingLine2;

        WaitTimeOnly :=
          (ProdOrderRoutingLine."Setup Time" = 0) and (ProdOrderRoutingLine."Run Time" = 0) and
          (ProdOrderRoutingLine."Move Time" = 0);

        if ProdOrderRoutingLine."Ending Time" = 0T then
            ProdOrderRoutingLine."Ending Time" := 000000T;

        if ProdOrderRoutingLine."Starting Time" = 0T then
            ProdOrderRoutingLine."Starting Time" := 000000T;

        ProdOrderRoutingLine."Expected Operation Cost Amt." := 0;
        ProdOrderRoutingLine."Expected Capacity Ovhd. Cost" := 0;
        ProdOrderRoutingLine."Expected Capacity Need" := 0;

        ProdOrderCapacityNeed.Reset();
        ProdOrderCapacityNeed.SetLoadFields(Status, "Prod. Order No.", "Requested Only", "Routing No.", "Routing Reference No.", "Operation No.");
        ProdOrderCapacityNeed.SetRange(Status, ProdOrderRoutingLine.Status);
        ProdOrderCapacityNeed.SetRange("Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        ProdOrderCapacityNeed.SetRange("Requested Only", false);
        ProdOrderCapacityNeed.SetRange("Routing No.", ProdOrderRoutingLine."Routing No.");
        ProdOrderCapacityNeed.SetRange("Routing Reference No.", ProdOrderRoutingLine."Routing Reference No.");
        ProdOrderCapacityNeed.SetRange("Operation No.", ProdOrderRoutingLine."Operation No.");
        ProdOrderCapacityNeed.DeleteAll();

        NextCapNeedLineNo := 1;

        ProdOrderRoutingLine.TestField("Work Center No.");

        CurrentWorkCenterNo := '';
        Workcenter.Get(ProdOrderRoutingLine."Work Center No.");
        if ProdOrderRoutingLine.Type = ProdOrderRoutingLine.Type::"Machine Center" then begin
            MachineCenter.Get(ProdOrderRoutingLine."No.");
            Workcenter."Queue Time" := MachineCenter."Queue Time";
            Workcenter."Queue Time Unit of Meas. Code" := MachineCenter."Queue Time Unit of Meas. Code";
        end;
        if not CalcStartEndDate then
            Clear(Workcenter."Queue Time");
        ProdOrder.Get(ProdOrderRoutingLine.Status, ProdOrderRoutingLine."Prod. Order No.");

        ProdOrderQty := 0;
        TotalLotSize := 0;
        ProdOrderLine.SetRange(Status, ProdOrderRoutingLine.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        ProdOrderLine.SetRange("Routing Reference No.", ProdOrderRoutingLine."Routing Reference No.");
        ProdOrderLine.SetRange("Routing No.", ProdOrderRoutingLine."Routing No.");
        ProdOrderLine.SetLoadFields("Quantity (Base)", "Scrap %", "Prod. Order No.", "Line No.", Status, "Routing No.", "Routing Version Code", "Ending Date", "Ending Time");
        if ProdOrderLine.FindFirst() then
            ProdOrderLine.CalcSums("Quantity (Base)", "Scrap %");
        ActualOperOutput := MfgCostCalcMgt.CalcActOutputQtyBase(ProdOrderLine, ProdOrderRoutingLine);
        ProdOrderQty := ProdOrderLine."Quantity (Base)" - ActualOperOutput;
        if ProdOrderQty < 0 then
            ProdOrderQty := 0;

        MaxLotSize :=
          ProdOrderQty *
          (1 + ProdOrderRoutingLine."Scrap Factor % (Accumulated)") *
          (1 + ProdOrderLine."Scrap %" / 100) +
          ProdOrderRoutingLine."Fixed Scrap Qty. (Accum.)";

        ProdOrderRoutingLine."Input Quantity" := MaxLotSize;

        if ActualOperOutput > 0 then
            TotalQtyPerOperation :=
              ProdOrderLine."Quantity (Base)" *
              (1 + ProdOrderRoutingLine."Scrap Factor % (Accumulated)") *
              (1 + ProdOrderLine."Scrap %" / 100) +
              ProdOrderRoutingLine."Fixed Scrap Qty. (Accum.)"
        else
            TotalQtyPerOperation := MaxLotSize;

        TotalCapacityPerOperation :=
          Round(
            TotalQtyPerOperation *
            ProdOrderRoutingLine.RunTimePer() *
            CalendarMgt.QtyperTimeUnitofMeasure(
              ProdOrderRoutingLine."Work Center No.", ProdOrderRoutingLine."Run Time Unit of Meas. Code"),
            UOMMgt.QtyRndPrecision());

        if MfgSetup."Cost Incl. Setup" then
            CalcCostInclSetup(ProdOrderRoutingLine, TotalCapacityPerOperation);

        CalcExpectedCost(ProdOrderRoutingLine, TotalQtyPerOperation, TotalCapacityPerOperation);

        if ProdOrderRoutingLine."Schedule Manually" then
            CalculateRoutingLineFixed()
        else
            if Direction = Direction::Backward then
                CalcRoutingLineBack(CalcStartEndDate)
            else
                CalcRoutingLineForward(CalcStartEndDate);

        ProdOrderRoutingLine2 := ProdOrderRoutingLine;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcCostInclSetup(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var TotalCapacityPerOperation: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; Direction: Enum "Transfer Direction")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitProdOrderCapNeed(ProdOrder: Record "Production Order"; var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var ProdOrderCapNeed: Record "Prod. Order Capacity Need"; var NeedQty: Decimal; TimeType: Enum "Routing Time Type"; var ActuallyPostedTime: Decimal; var DistributedCapNeed: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAdjustEndingTime(var IsHandled: Boolean; CalendarEntry: Record "Calendar Entry"; var EndingTime: Time)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAdjustStartingTime(var IsHandled: Boolean; CalendarEntry: Record "Calendar Entry"; var StartingTime: Time)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcCostInclSetup(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var TotalCapacityPerOperation: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcExpectedCost(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var MaxLotSize: Decimal; var TotalQtyPerOperation: Decimal; var ActualOperOutput: Decimal; var ExpectedOperOutput: Decimal; var TotalScrap: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetConstrainedSetup(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var ConstrainedCapacity: Record "Capacity Constrained Resource"; var ResourceIsConstrained: Boolean; var ParentWorkCenter: Record "Capacity Constrained Resource"; var ParentIsConstrained: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcRoutingLineBack(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcRoutingLineForward(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateCapNeeded(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; NeedDate: Date; NeedQty: Decimal; RemainNeedQty: Decimal; CalendarEntry: Record "Calendar Entry"; StartingTime: Time; EndingTime: Time; TimeType: Integer; var NextCapNeedLineNo: Integer; ConCurrCap: Decimal; LotSize: Decimal; FirstInBatch: Boolean; Direction: Integer);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcLoadBackAvailQtyBase(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; TimeType: Enum "Routing Time Type"; CurrentTimeFactor: Decimal; CurrentRounding: Decimal; var AvQtyBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcLoadForwardAvailQtyBase(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; TimeType: Enum "Routing Time Type"; CurrentTimeFactor: Decimal; CurrentRounding: Decimal; var AvQtyBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcRoutingLineBack(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var CalculateEndDate: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLoadCapBack(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; TimeType: Enum "Routing Time Type"; RemainNeedQty: Decimal; var ProdEndingDate: Date; var ProdEndingTime: Time)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLoadCapForward(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; CapType: Enum "Capacity Type"; CapNo: Code[20]; TimeType: Enum "Routing Time Type"; var ProdStartingDate: Date; var ProdStartingTime: Time; var IsHandled: Boolean; RemainNeedQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProdOrderCapNeedInsert(var ProdOrderCapNeed: Record "Prod. Order Capacity Need"; ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ProdOrder: Record "Production Order"; var CalendarEntry: Record "Calendar Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetLotSizesToMax(var SendAheadLotSize: Decimal; var TotalLotSize: Decimal; MaxLotSize: Decimal; ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeScheduleRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var CalcStartEndDate: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcMove(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; WorkCenter: Record "Work Center"; var ProdEndingDate: Date; var ProdEndingTime: Time; var UpdateDates: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcRoutingLineForward(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var CalculateStartDate: Boolean; var IsHandled: Boolean; var TempProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary; var SendAheadLotSize: Decimal; MaxLotSize: Decimal; var TotalLotSize: Decimal; var RemainNeedQty: Decimal; var UpdateDates: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcWaitBack(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; WorkCenter: Record "Work Center"; var ProdEndingDate: Date; var ProdEndingTime: Time; var UpdateDates: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateRoutingLineOnAfterProdOrderLineSetFilters(var ProdOrderLine: Record "Prod. Order Line"; ProductionOrder: Record "Production Order"; ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateRoutingLineOnBeforeCalcExpectedOperOutput(var ProdOrderLine: Record "Prod. Order Line"; var ExpectedOperOutput: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateRoutingLineOnBeforeProdOrderCapNeedReset(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ProdOrderRoutingLine2: Record "Prod. Order Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateLoadBackOnAfterCalcRelevantEfficiency(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; TimeType: Enum "Routing Time Type"; var RelevantEfficiency: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateLoadBackOnBeforeEndStopLoop(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; TimeType: Enum "Routing Time Type"; var StopLoop: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateLoadForwardOnBeforeCalcEndingTime(var EndingTime: Time; CalendarEntry: Record "Calendar Entry"; AvQtyBase: Decimal; RelevantEfficiency: Decimal; ConCurrCap: Decimal; var IsHandled: Boolean; ProdOrderRoutingLine: Record "Prod. Order Routing Line"; TimeType: Enum "Routing Time Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateLoadForwardOnBeforeEndStopLoop(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; TimeType: Enum "Routing Time Type"; var StopLoop: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateLoadForwardOnBeforeCheckWrite(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; TimeType: Enum "Routing Time Type"; var RelevantEfficiency: Decimal; var RemainNeedQtyBase: Decimal; var RemainNeedQty: Decimal; CurrentRounding: Decimal; Write: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateLoadBackOnBeforeCheckWrite(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; TimeType: Enum "Routing Time Type"; var RelevantEfficiency: Decimal; var RemainNeedQtyBase: Decimal; var RemainNeedQty: Decimal; CurrentRounding: Decimal; Write: Boolean; var StartingTime: Time; AvQtyBase: Decimal; var CalendarEntry: Record "Calendar Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateRoutingLineOnAfterCalcCostInclSetup(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var TotalCapacityPerOperation: Decimal; var TotalQtyPerOperation: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateRoutingLineOnBeforeCalcCostInclSetup(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var TotalCapacityPerOperation: Decimal; var TotalQtyPerOperation: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcRoutingLineBackOnBeforeGetQueueTime(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var ProdOrderRoutingLine2: Record "Prod. Order Routing Line"; var ProdOrderRoutingLine3: Record "Prod. Order Routing Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateRoutingLineBackOnAfterCalcRemainNeedQtyForLotSize(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var RemainNeedQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcRoutingLineBackOnAfterCalcShouldCalcNextOperation(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var ShouldCalcNextOperation: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateRoutingLineForwardOnAfterCalcRemainNeedQtyForLotSize(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var RemainNeedQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateRoutingLineFixedOnBeforeCalcRoutingLineBack(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var CalcEndDate: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateRoutingLineFixedOnBeforeCalcRoutingLineForward(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var CalcStartDate: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFinitelyLoadCapBackOnAfterCalcShouldProcessLastProdOrderCapNeed(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; AvailCap: Decimal; CalendarEntry: Record "Calendar Entry"; ProdEndingTime: Time; ProdEndingDate: Date; TimeType: Enum "Routing Time Type"; var FirstInBatch: Boolean; var FirstEntry: Boolean; var UpdateDates: Boolean; var RemainNeedQty: Decimal; var ProdOrderCapNeed: Record "Prod. Order Capacity Need"; ProdOrder: Record "Production Order"; var NextCapNeedLineNo: Integer; Workcenter: Record "Work Center"; LotSize: Decimal; var ShouldProcessLastProdOrderCapNeed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateLoadForwardOnAfterScheduleProdOrderRoutingLineManually(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; RoutingTimeType: Enum "Routing Time Type"; var RunStartingDateTime: DateTime; var ProdStartingDate: Date; var ProdStartingTime: Time; var RemainNeedQtyBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeCalculateRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; Direction: Option Forward,Backward; CalcStartEndDate: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLoadCapForwardOnScheduleManuallyOnBeforeCheckDateTimes(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; CapType: Enum "Capacity Type"; CapNo: Code[20]; TimeType: Enum "Routing Time Type"; var ProdStartingDate: Date; var ProdStartingTime: Time; RemainNeedQty: Decimal; var RunStartingDateTime: DateTime; var RunEndingDateTime: DateTime)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateTimesBack(CalendarEntry: Record "Calendar Entry"; ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var AvailTime: Decimal; var AvailCap: Decimal; var TimetoProgram: Decimal; var StartTime: Time; EndTime: Time; ConCurrCap: Decimal; Workcenter: Record "Work Center"; var RemainNeedQty: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateTimesForward(CalendarEntry: Record "Calendar Entry"; ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var AvailTime: Decimal; var AvailCap: Decimal; var TimetoProgram: Decimal; var StartTime: Time; EndTime: Time; ConCurrCap: Decimal; Workcenter: Record "Work Center"; var RemainNeedQty: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReturnNextCalendarEntryOnAfterSetCalendarEntryDateFilter(var CalendarEntry: Record "Calendar Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFinitelyLoadCapBackOnAfterSetCalendarEntryFilters(var CalendarEntry: Record "Calendar Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLoadCapBackOnAfterSetCalendarEntryFilters(var CalendarEntry: Record "Calendar Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateRoutingLineOnAfterCalcMaxLotSize(ProdOrderQty: Decimal; var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; TotalScrap: Decimal; var MaxLotSize: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitProdOrderCapNeed(ProductionOrder: Record "Production Order"; var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var ProdOrderCapacityNeed: Record "Prod. Order Capacity Need"; RoutingTimeType: Enum "Routing Time Type"; NeedDate: Date; StartingTime: Time; EndingTime: Time; var NeedQty: Decimal; LotSize: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLoadCapBackOnAfterCreateLoadBack(CapacityType: Enum "Capacity Type"; CapacityNo: Code[20]; RoutingTimeType: Enum "Routing Time Type"; Write: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcRoutingLineForwardOnBeforeLoadCapForward(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ProdOrderRoutingLine3: Record "Prod. Order Routing Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcRoutingLineForwardOnBeforeLoadCapForward2(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ProdOrderRoutingLine3: Record "Prod. Order Routing Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLoadCapForwardOnBeforeCreateLoadForward(var RemainNeedQty: Decimal; CapacityType: Enum "Capacity Type"; CapacityNo: Code[20]; RoutingTimeType: Enum "Routing Time Type"; Write: Boolean; LoadFactor: Decimal);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLoadCapForwardOnAfterCreateLoadForward(var RemainNeedQty: Decimal; CapacityType: Enum "Capacity Type"; CapacityNo: Code[20]; RoutingTimeType: Enum "Routing Time Type"; Write: Boolean; LoadFactor: Decimal);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSendAheadEndingTimeOnAfterCalcTimes(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; WorkCenter: Record "Work Center"; var SetupTime: Decimal; var RunTime: Decimal; var WaitTime: Decimal; var MoveTime: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSendAheadEndingTimeOnAfterCalcSetupAndRunTime(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; WorkCenter: Record "Work Center"; var SetupTime: Decimal; var RunTime: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcRoutingLineBackOnAfterCalcRemainNeedQty(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; WorkCenter: Record "Work Center"; var RemainNeedQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFinitelyLoadCapBackOnAfterCalcSetupTime(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; WorkCenter: Record "Work Center"; var SetupTime: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcRoutingLineForwardOnAfterCalcRemainNeedQty(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; WorkCenter: Record "Work Center"; var RemainNeedQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcAvailQtyBase(CalendarEntry: Record "Calendar Entry"; RoutingTimeType: Enum "Routing Time Type"; var AvQtyBase: Decimal; var IsHandled: Boolean)
    begin
    end;
}



