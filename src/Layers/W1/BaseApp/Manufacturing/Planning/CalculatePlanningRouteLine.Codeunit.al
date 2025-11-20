// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Planning;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Requisition;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.WorkCenter;

codeunit 99000810 "Calculate Planning Route Line"
{
    Permissions = TableData Item = r,
                  TableData "Prod. Order Capacity Need" = rimd,
                  TableData "Work Center" = r,
                  TableData "Calendar Entry" = r,
                  TableData "Machine Center" = r,
                  TableData "Manufacturing Setup" = rm,
                  TableData "Planning Routing Line" = rimd,
                  TableData "Capacity Constrained Resource" = r;

    trigger OnRun()
    begin
    end;

    var
        MfgSetup: Record "Manufacturing Setup";
        Item: Record Item;
        WorkCenter: Record "Work Center";
        WorkCenter2: Record "Work Center";
        MachineCenter: Record "Machine Center";
        ReqLine: Record "Requisition Line";
        PlanningRoutingLine: Record "Planning Routing Line";
        CalendarEntry: Record "Calendar Entry";
        ProdOrderCapNeed: Record "Prod. Order Capacity Need";
        ProdOrderCapNeed2: Record "Prod. Order Capacity Need";
        TempPlanningErrorLog: Record "Planning Error Log" temporary;
        TempConstrainedCapacity: Record "Capacity Constrained Resource" temporary;
        TempConstrainedCapacityEmpty: Record "Capacity Constrained Resource" temporary;
        CalendarMgt: Codeunit "Shop Calendar Management";
        CalculateRoutingLine: Codeunit "Calculate Routing Line";
        RoutingTimeType: Enum "Routing Time Type";
        NextCapNeedLineNo: Integer;
        ProdStartingTime: Time;
        ProdEndingTime: Time;
        ProdStartingDate: Date;
        ProdEndingDate: Date;
        MaxLotSize: Decimal;
        TotalLotSize: Decimal;
        LotSize: Decimal;
        ConCurrCap: Decimal;
        RemainNeedQty: Decimal;
        FirstInBatch: Boolean;
        FirstEntry: Boolean;
        UpdateDates: Boolean;
        WaitTimeOnly: Boolean;
        PlanningResiliency: Boolean;
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
#pragma warning restore AA0074

    local procedure TestForError(DirectionTxt: Text[30]; BefAfterTxt: Text[30]; Date: Date)
    var
        WorkCenter: Record "Work Center";
        MachCenter: Record "Machine Center";
    begin
        if RemainNeedQty <> 0 then begin
            if PlanningResiliency then
                case PlanningRoutingLine.Type of
                    PlanningRoutingLine.Type::"Work Center":
                        begin
                            WorkCenter.Get(PlanningRoutingLine."No.");
                            TempPlanningErrorLog.SetError(
                              StrSubstNo(
                                Text000,
                                DirectionTxt,
                                BefAfterTxt,
                                Date,
                                PlanningRoutingLine.Type,
                                PlanningRoutingLine."No."),
                              DATABASE::"Work Center", WorkCenter.GetPosition());
                        end;
                    PlanningRoutingLine.Type::"Machine Center":
                        begin
                            MachCenter.Get(PlanningRoutingLine."No.");
                            TempPlanningErrorLog.SetError(
                              StrSubstNo(
                                Text000,
                                DirectionTxt,
                                BefAfterTxt,
                                Date,
                                PlanningRoutingLine.Type,
                                PlanningRoutingLine."No."),
                              DATABASE::"Machine Center", MachCenter.GetPosition());
                        end;
                end;
            Error(
              Text000,
              DirectionTxt,
              BefAfterTxt,
              Date,
              PlanningRoutingLine.Type,
              PlanningRoutingLine."No.");
        end;
    end;

    local procedure CreatePlanningCapNeed(NeedDate: Date; StartingTime: Time; EndingTime: Time; NeedQty: Decimal; TimeType: Enum "Routing Time Type"; Direction: Option Forward,Backward)
    begin
        OnBeforeCreatePlanningCapNeed(PlanningRoutingLine, TimeType, NeedQty);

        ProdOrderCapNeed.Init();
        ProdOrderCapNeed."Worksheet Template Name" := ReqLine."Worksheet Template Name";
        ProdOrderCapNeed."Worksheet Batch Name" := ReqLine."Journal Batch Name";
        ProdOrderCapNeed."Worksheet Line No." := ReqLine."Line No.";
        ProdOrderCapNeed.Type := PlanningRoutingLine.Type;
        ProdOrderCapNeed."No." := PlanningRoutingLine."No.";
        ProdOrderCapNeed."Work Center No." := PlanningRoutingLine."Work Center No.";
        ProdOrderCapNeed."Operation No." := PlanningRoutingLine."Operation No.";
        ProdOrderCapNeed."Work Center Group Code" := PlanningRoutingLine."Work Center Group Code";

        ProdOrderCapNeed.Status := ReqLine."Ref. Order Status";
        ProdOrderCapNeed."Prod. Order No." := ReqLine."Ref. Order No.";
        ProdOrderCapNeed."Routing No." := ReqLine."Routing No.";
        ProdOrderCapNeed."Routing Reference No." := ReqLine."Line No.";
        ProdOrderCapNeed.Active := true;
        ProdOrderCapNeed."Requested Only" := true;
        ProdOrderCapNeed."Line No." := NextCapNeedLineNo;

        ProdOrderCapNeed.Date := NeedDate;
        ProdOrderCapNeed."Starting Time" := StartingTime;
        ProdOrderCapNeed."Ending Time" := EndingTime;
        ProdOrderCapNeed."Allocated Time" := NeedQty;
        ProdOrderCapNeed."Needed Time" := NeedQty;
        ProdOrderCapNeed."Needed Time (ms)" := NeedQty * CalendarMgt.TimeFactor(WorkCenter."Unit of Measure Code");
        PlanningRoutingLine."Expected Capacity Need" :=
          PlanningRoutingLine."Expected Capacity Need" + ProdOrderCapNeed."Needed Time (ms)";
        ProdOrderCapNeed.Efficiency := CalendarEntry.Efficiency;
        ProdOrderCapNeed."Concurrent Capacities" := ConCurrCap;

        if PlanningRoutingLine."Unit Cost Calculation" = PlanningRoutingLine."Unit Cost Calculation"::Time then begin
            if (TimeType = TimeType::"Run Time") or MfgSetup."Cost Incl. Setup" then begin
                PlanningRoutingLine."Expected Operation Cost Amt." :=
                  PlanningRoutingLine."Expected Operation Cost Amt." +
                  NeedQty * PlanningRoutingLine."Unit Cost per";
                PlanningRoutingLine."Expected Capacity Ovhd. Cost" :=
                  PlanningRoutingLine."Expected Capacity Ovhd. Cost" +
                  NeedQty *
                  (PlanningRoutingLine."Direct Unit Cost" *
                   PlanningRoutingLine."Indirect Cost %" / 100 + PlanningRoutingLine."Overhead Rate");
            end;
        end else begin
            PlanningRoutingLine."Expected Operation Cost Amt." :=
              PlanningRoutingLine."Input Quantity" * PlanningRoutingLine."Unit Cost per";
            PlanningRoutingLine."Expected Capacity Ovhd. Cost" :=
              PlanningRoutingLine."Input Quantity" *
              (PlanningRoutingLine."Direct Unit Cost" *
               PlanningRoutingLine."Indirect Cost %" / 100 + PlanningRoutingLine."Overhead Rate");
        end;

        OnCreatePlanningCapNeedOnAfterCalulateExpectedUnitCost(PlanningRoutingLine, TimeType, PlanningRoutingLine."Input Quantity");

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

        ProdOrderCapNeed.Insert();

        NextCapNeedLineNo := NextCapNeedLineNo + 1;

        OnAfterCreatePlanningCapNeed(
            NextCapNeedLineNo, PlanningRoutingLine, ReqLine, NeedDate, StartingTime, EndingTime, TimeType.AsInteger(), NeedQty,
            ConCurrCap, CalendarEntry, LotSize, RemainNeedQty, FirstInBatch, Direction);
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
        IsHandled: Boolean;
    begin
        xConCurrCap := 1;
        if (RemainNeedQty = 0) and ((not FirstEntry) or (not Write) or WaitTimeOnly) then
            exit;

        if CalendarEntry.Find('+') then begin
            IsHandled := false;
            OnCreateLoadBackOnBeforeFirstCalculate(PlanningRoutingLine, IsHandled);
            if not IsHandled then
                if (TimeType = TimeType::"Wait Time") and (CalendarEntry.Date < ProdEndingDate) then begin
                    CalendarEntry.Date := ProdEndingDate;
                    CreateCalendarEntry(CalendarEntry);
                end;

            GetCurrentWorkCenterTimeFactorAndRounding(WorkCenter);
            RemainNeedQtyBase := Round(RemainNeedQty * CurrentTimeFactor, CurrentRounding);
            repeat
                OldCalendarEntry := CalendarEntry;
                ConCurrCap := PlanningRoutingLine."Concurrent Capacities";
                if (ConCurrCap = 0) or (CalendarEntry.Capacity < ConCurrCap) then
                    ConCurrCap := CalendarEntry.Capacity;
                if TimeType <> TimeType::"Run Time" then
                    RemainNeedQtyBase := RemainNeedQtyBase * ConCurrCap / xConCurrCap;
                xConCurrCap := ConCurrCap;
                AvQtyBase :=
                  CalculateRoutingLine.CalcAvailQtyBase(
                    CalendarEntry, ProdEndingDate, ProdEndingTime, TimeType, ConCurrCap, false,
                    CurrentTimeFactor, CurrentRounding);

                if AvQtyBase > RemainNeedQtyBase then
                    AvQtyBase := RemainNeedQtyBase;
                if TimeType in [TimeType::"Setup Time", TimeType::"Run Time"] then
                    RelevantEfficiency := CalendarEntry.Efficiency
                else
                    RelevantEfficiency := 100;
                StartingTime :=
                  CalendarMgt.CalcTimeSubtract(
                    CalendarEntry."Ending Time",
                    Round(AvQtyBase * 100 / RelevantEfficiency / ConCurrCap, 1, '>'));
                RemainNeedQtyBase := RemainNeedQtyBase - AvQtyBase;
                OnCreatingLoadBackOnAfterUpdateRemainNeedQtyBase(PlanningRoutingLine, CalendarEntry, StartingTime);

                if Write then begin
                    RemainNeedQty := Round(RemainNeedQtyBase / CurrentTimeFactor, CurrentRounding);
                    CreatePlanningCapNeed(
                      CalendarEntry.Date, StartingTime, CalendarEntry."Ending Time",
                      Round(AvQtyBase / CurrentTimeFactor, CurrentRounding), TimeType, 1);
                    FirstInBatch := false;
                    FirstEntry := false;
                end;
                if (CalendarEntry."Capacity (Effective)" <> 0) or (TimeType = TimeType::"Wait Time") then
                    UpdateEndingDateAndTime(CalendarEntry.Date, CalendarEntry."Ending Time");
                ProdEndingTime := StartingTime;
                ProdEndingDate := CalendarEntry.Date;
                PlanningRoutingLine."Starting Time" := StartingTime;
                PlanningRoutingLine."Starting Date" := CalendarEntry.Date;

                if (RemainNeedQtyBase = 0) and ((not FirstEntry) or (not Write)) then
                    StopLoop := true
                else
                    if TimeType = TimeType::"Wait Time" then begin
                        StopLoop := false;
                        CalculateRoutingLine.ReturnNextCalendarEntry(CalendarEntry, OldCalendarEntry, 0);
                    end else begin
                        CalendarEntry := OldCalendarEntry;
                        StopLoop := CalendarEntry.Next(-1) = 0;
                    end;
            until StopLoop;
            RemainNeedQty := Round(RemainNeedQtyBase / CurrentTimeFactor, CurrentRounding);
            UpdateEndingDateAndTime(ProdEndingDate, ProdEndingTime);
        end;
    end;

    local procedure CreateLoadForward(TimeType: Enum "Routing Time Type"; Write: Boolean)
    var
        OldCalendarEntry: Record "Calendar Entry";
        AvQtyBase: Decimal;
        RelevantEfficiency: Decimal;
        xConCurrCap: Decimal;
        RemainNeedQtyBase: Decimal;
        EndingTime: Time;
        StopLoop: Boolean;
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
            GetCurrentWorkCenterTimeFactorAndRounding(WorkCenter);
            RemainNeedQtyBase := Round(RemainNeedQty * CurrentTimeFactor, CurrentRounding);
            repeat
                OldCalendarEntry := CalendarEntry;
                ConCurrCap := PlanningRoutingLine."Concurrent Capacities";
                if (ConCurrCap = 0) or (CalendarEntry.Capacity < ConCurrCap) then
                    ConCurrCap := CalendarEntry.Capacity;
                if TimeType <> TimeType::"Run Time" then
                    RemainNeedQtyBase := RemainNeedQtyBase * ConCurrCap / xConCurrCap;
                xConCurrCap := ConCurrCap;
                AvQtyBase :=
                  CalculateRoutingLine.CalcAvailQtyBase(
                    CalendarEntry, ProdStartingDate, ProdStartingTime, TimeType, ConCurrCap, true,
                    CurrentTimeFactor, CurrentRounding);

                if AvQtyBase > RemainNeedQtyBase then
                    AvQtyBase := RemainNeedQtyBase;
                if TimeType in [TimeType::"Setup Time", TimeType::"Run Time"] then
                    RelevantEfficiency := CalendarEntry.Efficiency
                else
                    RelevantEfficiency := 100;
                EndingTime :=
                  CalendarEntry."Starting Time" +
                  Round(AvQtyBase * 100 / RelevantEfficiency / ConCurrCap, 1, '>');
                if AvQtyBase >= 0 then
                    RemainNeedQtyBase := RemainNeedQtyBase - AvQtyBase;
                OnCreatingLoadForwardOnAfterUpdateRemainNeedQtyBase(PlanningRoutingLine, CalendarEntry, EndingTime);
                if Write then begin
                    RemainNeedQty := Round(RemainNeedQtyBase / CurrentTimeFactor, CurrentRounding);
                    CreatePlanningCapNeed(
                      CalendarEntry.Date, CalendarEntry."Starting Time", EndingTime,
                      Round(AvQtyBase / CurrentTimeFactor, CurrentRounding), TimeType, 1);
                    FirstInBatch := false;
                    FirstEntry := false;
                end;
                if (CalendarEntry."Capacity (Effective)" <> 0) or (TimeType = TimeType::"Wait Time") then
                    UpdateStartingDateAndTime(CalendarEntry.Date, CalendarEntry."Starting Time");
                if (EndingTime = 000000T) and (AvQtyBase <> 0) then
                    // Ending Time reached 24:00:00 so we need to move date as well
                    CalendarEntry.Date := CalendarEntry.Date + 1;
                ProdStartingTime := EndingTime;
                ProdStartingDate := CalendarEntry.Date;
                PlanningRoutingLine."Ending Time" := EndingTime;
                PlanningRoutingLine."Ending Date" := CalendarEntry.Date;

                if (RemainNeedQtyBase = 0) and ((not FirstEntry) or (not Write)) and (AvQtyBase >= 0) then
                    StopLoop := true
                else
                    if TimeType = TimeType::"Wait Time" then begin
                        StopLoop := false;
                        CalculateRoutingLine.ReturnNextCalendarEntry(CalendarEntry, OldCalendarEntry, 1);
                    end else begin
                        CalendarEntry := OldCalendarEntry;
                        StopLoop := CalendarEntry.Next() = 0;
                    end;
            until StopLoop;
            RemainNeedQty := Round(RemainNeedQtyBase / CurrentTimeFactor, CurrentRounding);
        end;
    end;

    local procedure LoadCapBack(CapType: Enum "Capacity Type"; CapNo: Code[20]; TimeType: Enum "Routing Time Type"; Write: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeLoadCapBack(PlanningRoutingLine, TimeType, ProdStartingDate, ProdStartingTime, IsHandled);
        if IsHandled then
            exit;

        PlanningRoutingLine."Starting Date" := ProdEndingDate;
        PlanningRoutingLine."Starting Time" := ProdEndingTime;

        CalendarEntry.SetCapacityFilters(CapType, CapNo);
        CalendarEntry.SetRange("Ending Date-Time", 0DT, CreateDateTime(ProdEndingDate + 1, ProdEndingTime));
        CalendarEntry.SetRange("Starting Date-Time", 0DT, CreateDateTime(ProdEndingDate, ProdEndingTime));

        CreateLoadBack(TimeType, Write);

        if RemainNeedQty = 0 then
            exit;

        TestForError(Text001, Text002, PlanningRoutingLine."Starting Date");
    end;

    procedure LoadCapForward(CapType: Enum "Capacity Type"; CapNo: Code[20]; TimeType: Enum "Routing Time Type"; Write: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeLoadCapForward(PlanningRoutingLine, TimeType, ProdStartingDate, ProdStartingTime, IsHandled);
        if IsHandled then
            exit;

        PlanningRoutingLine."Ending Date" := ProdStartingDate;
        PlanningRoutingLine."Ending Time" := ProdStartingTime;

        CalendarEntry.SetCapacityFilters(CapType, CapNo);
        CalendarEntry.SetFilter("Starting Date-Time", '>=%1', CreateDateTime(ProdStartingDate - 1, ProdStartingTime));
        CalendarEntry.SetFilter("Ending Date-Time", '>=%1', CreateDateTime(ProdStartingDate, ProdStartingTime));

        CreateLoadForward(TimeType, Write);

        if RemainNeedQty = 0 then
            exit;

        TestForError(Text003, Text004, PlanningRoutingLine."Ending Date");
    end;

    local procedure CalcMoveTimeBack()
    var
        IsHandled: Boolean;
    begin
        UpdateDates := true;
        IsHandled := false;
        OnBeforeCalcMoveTimeBack(
            PlanningRoutingLine, WorkCenter, ProdEndingDate, ProdEndingTime, ProdStartingDate, ProdStartingTime, UpdateDates, IsHandled);
        if IsHandled then
            exit;

        RemainNeedQty :=
            Round(
                PlanningRoutingLine."Move Time" *
                CalendarMgt.TimeFactor(PlanningRoutingLine."Move Time Unit of Meas. Code") /
                CalendarMgt.TimeFactor(WorkCenter."Unit of Measure Code"),
                WorkCenter."Calendar Rounding Precision");

        LoadCapBack(PlanningRoutingLine.Type, PlanningRoutingLine."No.", RoutingTimeType::"Move Time", false);
    end;

    local procedure CalcWaitTimeBack()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcWaitTimeBack(
            PlanningRoutingLine, WorkCenter, ProdEndingDate, ProdEndingTime, ProdStartingDate, ProdStartingTime, UpdateDates, IsHandled);
        if IsHandled then
            exit;

        RemainNeedQty :=
            Round(
                PlanningRoutingLine."Wait Time" *
                CalendarMgt.TimeFactor(PlanningRoutingLine."Wait Time Unit of Meas. Code") /
                CalendarMgt.TimeFactor(WorkCenter."Unit of Measure Code"),
                WorkCenter."Calendar Rounding Precision");

        LoadCapBack(PlanningRoutingLine.Type, PlanningRoutingLine."No.", RoutingTimeType::"Wait Time", false);
    end;

    local procedure GetSendAheadStartingTime(var PlanningRoutingLineNext: Record "Planning Routing Line"; var SendAheadLotSize: Decimal): Boolean
    var
        xPlanningRoutingLine: Record "Planning Routing Line";
        RunTime: Decimal;
        WaitTime: Decimal;
        MoveTime: Decimal;
        ResidualLotSize: Decimal;
        ResidualProdStartDateTime: DateTime;
    begin
        ProdStartingDate := PlanningRoutingLineNext."Starting Date";
        ProdStartingTime := PlanningRoutingLineNext."Starting Time";
        SendAheadLotSize := MaxLotSize;
        if TotalLotSize = MaxLotSize then
            exit(true);

        if (PlanningRoutingLine."Send-Ahead Quantity" = 0) or
           (PlanningRoutingLine."Send-Ahead Quantity" >= MaxLotSize)
        then begin
            TotalLotSize := SendAheadLotSize;
            exit(false);
        end;

        SendAheadLotSize := PlanningRoutingLine."Send-Ahead Quantity";
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
        ProdOrderCapNeed2.SetCurrentKey(
          "Worksheet Template Name", "Worksheet Batch Name", "Worksheet Line No.", "Operation No.", Date, "Starting Time");
        ProdOrderCapNeed2.SetRange("Worksheet Template Name", PlanningRoutingLine."Worksheet Template Name");
        ProdOrderCapNeed2.SetRange("Worksheet Batch Name", PlanningRoutingLine."Worksheet Batch Name");
        ProdOrderCapNeed2.SetRange("Worksheet Line No.", PlanningRoutingLine."Worksheet Line No.");
        ProdOrderCapNeed2.SetRange("Operation No.", PlanningRoutingLine."Operation No.");
        if not ProdOrderCapNeed2.IsEmpty() then begin
            if TotalLotSize <> MaxLotSize then begin
                SendAheadLotSize := MaxLotSize - (TotalLotSize - SendAheadLotSize);
                TotalLotSize := MaxLotSize;
            end;
            exit(false);
        end;
        // calculate Starting Date/Time for the last lot of the next line by going back from Ending Date/Time of the line
        WorkCenter2.Get(PlanningRoutingLineNext."Work Center No.");
        RunTime :=
          Round(
            (ResidualLotSize * PlanningRoutingLineNext.RunTimePer()) *
            CalendarMgt.TimeFactor(PlanningRoutingLineNext."Run Time Unit of Meas. Code") /
            CalendarMgt.TimeFactor(WorkCenter2."Unit of Measure Code"),
            WorkCenter2."Calendar Rounding Precision");
        WaitTime :=
          Round(
            PlanningRoutingLineNext."Wait Time" *
            CalendarMgt.TimeFactor(PlanningRoutingLineNext."Wait Time Unit of Meas. Code") /
            CalendarMgt.TimeFactor(WorkCenter2."Unit of Measure Code"),
            WorkCenter2."Calendar Rounding Precision");
        MoveTime :=
          Round(
            PlanningRoutingLineNext."Move Time" *
            CalendarMgt.TimeFactor(PlanningRoutingLineNext."Move Time Unit of Meas. Code") /
            CalendarMgt.TimeFactor(WorkCenter2."Unit of Measure Code"),
            WorkCenter2."Calendar Rounding Precision");

        xPlanningRoutingLine := PlanningRoutingLine;
        PlanningRoutingLine := PlanningRoutingLineNext;
        ProdEndingDate := PlanningRoutingLine."Ending Date";
        ProdEndingTime := PlanningRoutingLine."Ending Time";
        RemainNeedQty := MoveTime;
        LoadCapBack(PlanningRoutingLine.Type, PlanningRoutingLine."No.", RoutingTimeType::"Move Time", false);
        RemainNeedQty := WaitTime;
        LoadCapBack(PlanningRoutingLine.Type, PlanningRoutingLine."No.", RoutingTimeType::"Wait Time", false);
        RemainNeedQty := RunTime;
        LoadCapBack(PlanningRoutingLine.Type, PlanningRoutingLine."No.", RoutingTimeType::"Run Time", false);
        PlanningRoutingLine := xPlanningRoutingLine;

        PlanningRoutingLine."Starting Date" := ProdEndingDate;
        PlanningRoutingLine."Starting Time" := ProdEndingTime;
        ResidualProdStartDateTime := CreateDateTime(ProdEndingDate, ProdEndingTime);
        // calculate Ending Date/Time of current line by going forward from Starting Date/Time of the next line
        WorkCenter.Get(PlanningRoutingLine."Work Center No.");
        RunTime :=
          Round(
            (MaxLotSize - SendAheadLotSize) * PlanningRoutingLine.RunTimePer() *
            CalendarMgt.TimeFactor(PlanningRoutingLine."Run Time Unit of Meas. Code") /
            CalendarMgt.TimeFactor(WorkCenter."Unit of Measure Code"),
            WorkCenter."Calendar Rounding Precision");
        WaitTime :=
          Round(
            PlanningRoutingLine."Wait Time" *
            CalendarMgt.TimeFactor(PlanningRoutingLine."Wait Time Unit of Meas. Code") /
            CalendarMgt.TimeFactor(WorkCenter."Unit of Measure Code"),
            WorkCenter."Calendar Rounding Precision");
        MoveTime :=
          Round(
            PlanningRoutingLine."Move Time" *
            CalendarMgt.TimeFactor(PlanningRoutingLine."Move Time Unit of Meas. Code") /
            CalendarMgt.TimeFactor(WorkCenter."Unit of Measure Code"),
            WorkCenter."Calendar Rounding Precision");

        RemainNeedQty := RunTime;
        LoadCapForward(PlanningRoutingLine.Type, PlanningRoutingLine."No.", RoutingTimeType::"Run Time", false);
        RemainNeedQty := WaitTime;
        LoadCapForward(PlanningRoutingLine.Type, PlanningRoutingLine."No.", RoutingTimeType::"Wait Time", false);
        RemainNeedQty := MoveTime;
        LoadCapForward(PlanningRoutingLine.Type, PlanningRoutingLine."No.", RoutingTimeType::"Move Time", false);
        // last lot must be finished by current Work Center, otherwise we recalculate Ending Date/Time of current line
        PlanningRoutingLine.UpdateDatetime();
        if PlanningRoutingLine."Ending Date-Time" > ResidualProdStartDateTime then begin
            PlanningRoutingLine."Ending Date" := DT2Date(ResidualProdStartDateTime);
            PlanningRoutingLine."Ending Time" := DT2Time(ResidualProdStartDateTime);
            FilterCalendarEntryBeforeOrOnDateTime(PlanningRoutingLine.Type, PlanningRoutingLine."No.", PlanningRoutingLine."Ending Date", PlanningRoutingLine."Ending Time");
            if CalendarEntry.FindLast() then
                if PlanningRoutingLine."Ending Time" > CalendarEntry."Ending Time" then
                    if (WaitTime = 0) or (MoveTime <> 0) then
                        // Wait Time can end outside of working hours, but only if Move Time = 0
                        PlanningRoutingLine."Ending Time" := CalendarEntry."Ending Time";
            ProdStartingDate := PlanningRoutingLine."Ending Date";
            ProdStartingTime := PlanningRoutingLine."Ending Time";
        end;
        exit(false);
    end;

    procedure CalcRoutingLineBack(CalcStartEndDate: Boolean)
    var
        WorkCenter2: Record "Work Center";
        PlanningRoutingLine2: Record "Planning Routing Line";
        PlanningRoutingLine3: Record "Planning Routing Line";
        ConstrainedCapacity: Record "Capacity Constrained Resource";
        ParentWorkCenter: Record "Capacity Constrained Resource";
        TempWorkCenter: Record "Work Center";
        TempPlanRoutingLine: Record "Planning Routing Line" temporary;
        ResourceIsConstrained: Boolean;
        ParentIsConstrained: Boolean;
        ShouldCalcNextOperation: Boolean;
        SendAheadLotSize: Decimal;
    begin
        OnBeforeCalcRoutingLineBack(PlanningRoutingLine, CalcStartEndDate);

        CalendarEntry.SetRange(Date, 0D, PlanningRoutingLine."Ending Date");

        ProdEndingTime := PlanningRoutingLine."Ending Time";
        ProdEndingDate := PlanningRoutingLine."Ending Date";
        ProdStartingTime := PlanningRoutingLine."Ending Time";
        ProdStartingDate := PlanningRoutingLine."Ending Date";

        FirstEntry := true;

        ShouldCalcNextOperation := (PlanningRoutingLine."Next Operation No." <> '') and CalcStartEndDate;
        OnCalcRoutingLineBackOnAfterCalcShouldCalcNextOperation(PlanningRoutingLine, MaxLotSize, TotalLotSize, SendAheadLotSize, ShouldCalcNextOperation);

        if ShouldCalcNextOperation then begin
            Clear(PlanningRoutingLine3);

            TempPlanRoutingLine.Reset();
            TempPlanRoutingLine.DeleteAll();

            PlanningRoutingLine2.SetRange("Worksheet Template Name", PlanningRoutingLine."Worksheet Template Name");
            PlanningRoutingLine2.SetRange("Worksheet Batch Name", PlanningRoutingLine."Worksheet Batch Name");
            PlanningRoutingLine2.SetRange("Worksheet Line No.", PlanningRoutingLine."Worksheet Line No.");
            PlanningRoutingLine2.SetFilter("Operation No.", PlanningRoutingLine."Next Operation No.");
            if PlanningRoutingLine2.Find('-') then
                repeat
                    TotalLotSize := 0;
                    GetSendAheadStartingTime(PlanningRoutingLine2, SendAheadLotSize);

                    TempPlanRoutingLine.Copy(PlanningRoutingLine2);
                    TempPlanRoutingLine.Insert();

                    if ProdEndingDate > ProdStartingDate then begin
                        ProdEndingDate := ProdStartingDate;
                        ProdEndingTime := ProdStartingTime;
                        PlanningRoutingLine3 := PlanningRoutingLine2;
                    end else
                        if (ProdEndingDate = ProdStartingDate) and
                           (ProdEndingTime > ProdStartingTime)
                        then begin
                            ProdEndingTime := ProdStartingTime;
                            PlanningRoutingLine3 := PlanningRoutingLine2;
                        end;
                until PlanningRoutingLine2.Next() = 0;
            if PlanningRoutingLine3."Worksheet Template Name" <> '' then begin
                WorkCenter2.Get(PlanningRoutingLine3."Work Center No.");
                PlanningRoutingLine3."Critical Path" := true;
                PlanningRoutingLine3.UpdateDatetime();
                PlanningRoutingLine3.Modify();
                if PlanningRoutingLine3.Type = PlanningRoutingLine3.Type::"Machine Center" then begin
                    MachineCenter.Get(PlanningRoutingLine3."No.");
                    WorkCenter2."Queue Time" := MachineCenter."Queue Time";
                    WorkCenter2."Queue Time Unit of Meas. Code" :=
                      MachineCenter."Queue Time Unit of Meas. Code";
                end;
                UpdateDates := false;
                RemainNeedQty :=
                  Round(
                    WorkCenter2."Queue Time" *
                    CalendarMgt.TimeFactor(WorkCenter2."Queue Time Unit of Meas. Code") /
                    CalendarMgt.TimeFactor(WorkCenter2."Unit of Measure Code"),
                    WorkCenter2."Calendar Rounding Precision");

                TempWorkCenter := WorkCenter;
                WorkCenter."Unit of Measure Code" := WorkCenter2."Unit of Measure Code";
                WorkCenter."Calendar Rounding Precision" := WorkCenter2."Calendar Rounding Precision";
                LoadCapBack(PlanningRoutingLine2.Type, PlanningRoutingLine2."No.", RoutingTimeType::"Queue Time", false);
                WorkCenter."Unit of Measure Code" := TempWorkCenter."Unit of Measure Code";
                WorkCenter."Calendar Rounding Precision" := TempWorkCenter."Calendar Rounding Precision";
            end;
        end else
            SetLotSizesToMax(SendAheadLotSize, TotalLotSize);

        UpdateDates := true;

        CalcMoveTimeBack();
        CalcWaitTimeBack();

        repeat
            LotSize := SendAheadLotSize;
            RemainNeedQty := LotSize * PlanningRoutingLine.RunTimePer();
            OnCalculateRoutingLineBackOnAfterCalcRemainNeedQtyForLotSize(PlanningRoutingLine, RemainNeedQty);
            RemainNeedQty :=
              Round(
                RemainNeedQty *
                CalendarMgt.TimeFactor(PlanningRoutingLine."Run Time Unit of Meas. Code") /
                CalendarMgt.TimeFactor(WorkCenter."Unit of Measure Code"),
                WorkCenter."Calendar Rounding Precision");

            ResourceIsConstrained := GetConstrainedCapacity(PlanningRoutingLine.Type, PlanningRoutingLine."No.", ConstrainedCapacity);
            ParentIsConstrained := GetConstrainedCapacity(PlanningRoutingLine.Type::"Work Center", PlanningRoutingLine."Work Center No.", ParentWorkCenter);
            if ResourceIsConstrained or ParentIsConstrained then
                FinitelyLoadCapBack(RoutingTimeType::"Run Time", ConstrainedCapacity, ResourceIsConstrained, ParentWorkCenter, ParentIsConstrained)
            else
                LoadCapBack(PlanningRoutingLine.Type, PlanningRoutingLine."No.", RoutingTimeType::"Run Time", true);

            ProdEndingDate := PlanningRoutingLine."Starting Date";
            ProdEndingTime := PlanningRoutingLine."Starting Time";
        until FindSendAheadStartingTime(TempPlanRoutingLine, SendAheadLotSize);

        ProdEndingDate := PlanningRoutingLine."Starting Date";
        ProdEndingTime := PlanningRoutingLine."Starting Time";
        RemainNeedQty := GetSetupTimeBaseUOM();

        ResourceIsConstrained := GetConstrainedCapacity(PlanningRoutingLine.Type, PlanningRoutingLine."No.", ConstrainedCapacity);
        ParentIsConstrained := GetConstrainedCapacity(PlanningRoutingLine.Type::"Work Center", PlanningRoutingLine."Work Center No.", ParentWorkCenter);
        if ResourceIsConstrained or ParentIsConstrained then
            FinitelyLoadCapBack(RoutingTimeType::"Setup Time", ConstrainedCapacity, ResourceIsConstrained, ParentWorkCenter, ParentIsConstrained)
        else
            LoadCapBack(PlanningRoutingLine.Type, PlanningRoutingLine."No.", RoutingTimeType::"Setup Time", true);

        PlanningRoutingLine."Starting Date" := ProdEndingDate;
        PlanningRoutingLine."Starting Time" := ProdEndingTime;

        if PlanningRoutingLine."Ending Date" = CalendarMgt.GetMaxDate() then begin
            PlanningRoutingLine."Ending Date" := PlanningRoutingLine."Starting Date";
            PlanningRoutingLine."Ending Time" := PlanningRoutingLine."Starting Time";
        end;

        PlanningRoutingLine.UpdateDatetime();
        PlanningRoutingLine.Modify();

        OnAfterCalcRoutingLineBack(PlanningRoutingLine, PlanningResiliency);
    end;

    local procedure SetLotSizesToMax(var SendAheadLotSize: Decimal; var TotalLotSize: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetLotSizesToMax(SendAheadLotSize, TotalLotSize, MaxLotSize, PlanningRoutingLine, IsHandled);
        if IsHandled then
            exit;

        TotalLotSize := MaxLotSize;
        SendAheadLotSize := MaxLotSize;
    end;

    local procedure GetConstrainedCapacity(CapType: Enum "Capacity Type"; CapNo: Code[20]; var ConstrainedCapacity: Record "Capacity Constrained Resource") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetConstrainedCapacity(CapType, CapNo, ConstrainedCapacity, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if TempConstrainedCapacity.Get(CapType, CapNo) then begin
            ConstrainedCapacity := TempConstrainedCapacity;
            exit(true);
        end;
        if TempConstrainedCapacityEmpty.Get(CapType, CapNo) then
            exit(false);

        if ConstrainedCapacity.Get(CapType, CapNo) then begin
            TempConstrainedCapacity := ConstrainedCapacity;
            TempConstrainedCapacity.Insert();
            exit(true);
        end;

        TempConstrainedCapacityEmpty.Init();
        TempConstrainedCapacityEmpty."Capacity Type" := CapType;
        TempConstrainedCapacityEmpty."Capacity No." := CapNo;
        TempConstrainedCapacityEmpty.Insert();
        exit(false);
    end;

    local procedure GetSendAheadEndingTime(var PlanningRoutingLinePrev: Record "Planning Routing Line"; var SendAheadLotSize: Decimal): Boolean
    var
        xPlanningRoutingLine: Record "Planning Routing Line";
        SetupTime: Decimal;
        RunTime: Decimal;
        WaitTime: Decimal;
        MoveTime: Decimal;
        ResidualLotSize: Decimal;
        ResidualProdStartDateTime: DateTime;
    begin
        ProdEndingTime := PlanningRoutingLinePrev."Ending Time";
        ProdEndingDate := PlanningRoutingLinePrev."Ending Date";
        SendAheadLotSize := MaxLotSize;
        if TotalLotSize = MaxLotSize then
            exit(true);

        if (PlanningRoutingLinePrev."Send-Ahead Quantity" = 0) or
           (PlanningRoutingLinePrev."Send-Ahead Quantity" >= MaxLotSize)
        then begin
            TotalLotSize := SendAheadLotSize;
            exit(false);
        end;
        SendAheadLotSize := PlanningRoutingLinePrev."Send-Ahead Quantity";
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
        ProdOrderCapNeed2.SetCurrentKey(
          "Worksheet Template Name", "Worksheet Batch Name", "Worksheet Line No.", "Operation No.", Date, "Starting Time");
        ProdOrderCapNeed2.SetRange("Worksheet Template Name", PlanningRoutingLine."Worksheet Template Name");
        ProdOrderCapNeed2.SetRange("Worksheet Batch Name", PlanningRoutingLine."Worksheet Batch Name");
        ProdOrderCapNeed2.SetRange("Worksheet Line No.", PlanningRoutingLine."Worksheet Line No.");
        ProdOrderCapNeed2.SetRange("Operation No.", PlanningRoutingLine."Operation No.");
        if not ProdOrderCapNeed2.IsEmpty() then begin
            if TotalLotSize <> MaxLotSize then begin
                SendAheadLotSize := MaxLotSize - (TotalLotSize - SendAheadLotSize);
                TotalLotSize := MaxLotSize;
            end;
            exit(false);
        end;
        // calculate Starting Date/Time of current line using Setup/Run/Wait/Move Time for the first send-ahead lot from previous line
        WorkCenter2.Get(PlanningRoutingLinePrev."Work Center No.");
        SetupTime :=
          Round(
            PlanningRoutingLinePrev."Setup Time" *
            CalendarMgt.TimeFactor(PlanningRoutingLinePrev."Setup Time Unit of Meas. Code") /
            CalendarMgt.TimeFactor(WorkCenter2."Unit of Measure Code"),
            WorkCenter2."Calendar Rounding Precision");
        RunTime :=
          Round(
            SendAheadLotSize * PlanningRoutingLinePrev.RunTimePer() *
            CalendarMgt.TimeFactor(PlanningRoutingLinePrev."Run Time Unit of Meas. Code") /
            CalendarMgt.TimeFactor(WorkCenter2."Unit of Measure Code"),
            WorkCenter2."Calendar Rounding Precision");
        WaitTime :=
          Round(
            PlanningRoutingLinePrev."Wait Time" *
            CalendarMgt.TimeFactor(PlanningRoutingLinePrev."Wait Time Unit of Meas. Code") /
            CalendarMgt.TimeFactor(WorkCenter2."Unit of Measure Code"),
            WorkCenter2."Calendar Rounding Precision");
        MoveTime :=
          Round(
            PlanningRoutingLinePrev."Move Time" *
            CalendarMgt.TimeFactor(PlanningRoutingLinePrev."Move Time Unit of Meas. Code") /
            CalendarMgt.TimeFactor(WorkCenter2."Unit of Measure Code"),
            WorkCenter2."Calendar Rounding Precision");

        xPlanningRoutingLine := PlanningRoutingLine;
        PlanningRoutingLine := PlanningRoutingLinePrev;
        ProdStartingDate := PlanningRoutingLine."Starting Date";
        ProdStartingTime := PlanningRoutingLine."Starting Time";
        RemainNeedQty := SetupTime;
        LoadCapForward(PlanningRoutingLine.Type, PlanningRoutingLine."No.", RoutingTimeType::"Setup Time", false);
        RemainNeedQty := RunTime;
        LoadCapForward(PlanningRoutingLine.Type, PlanningRoutingLine."No.", RoutingTimeType::"Run Time", false);
        RemainNeedQty := WaitTime;
        LoadCapForward(PlanningRoutingLine.Type, PlanningRoutingLine."No.", RoutingTimeType::"Wait Time", false);
        RemainNeedQty := MoveTime;
        LoadCapForward(PlanningRoutingLine.Type, PlanningRoutingLine."No.", RoutingTimeType::"Move Time", false);
        PlanningRoutingLine := xPlanningRoutingLine;

        PlanningRoutingLine."Starting Date" := ProdStartingDate;
        PlanningRoutingLine."Starting Time" := ProdStartingTime;
        // calculate Starting Date/Time for the last lot of current line by going forward from Starting Date/Time of the line
        WorkCenter.Get(PlanningRoutingLine."Work Center No.");
        SetupTime :=
          Round(
            PlanningRoutingLine."Setup Time" *
            CalendarMgt.TimeFactor(PlanningRoutingLine."Run Time Unit of Meas. Code") /
            CalendarMgt.TimeFactor(WorkCenter."Unit of Measure Code"),
            WorkCenter."Calendar Rounding Precision");
        RunTime :=
          Round(
            (MaxLotSize - ResidualLotSize) * PlanningRoutingLine.RunTimePer() *
            CalendarMgt.TimeFactor(PlanningRoutingLine."Run Time Unit of Meas. Code") /
            CalendarMgt.TimeFactor(WorkCenter."Unit of Measure Code"),
            WorkCenter."Calendar Rounding Precision");

        RemainNeedQty := SetupTime;
        LoadCapForward(PlanningRoutingLine.Type, PlanningRoutingLine."No.", RoutingTimeType::"Setup Time", false);
        RemainNeedQty := RunTime;
        LoadCapForward(PlanningRoutingLine.Type, PlanningRoutingLine."No.", RoutingTimeType::"Run Time", false);
        ResidualProdStartDateTime := CreateDateTime(ProdStartingDate, ProdStartingTime);
        // last lot must be finished by previous Work Center, otherwise we recalculate Starting Date/Time of current line
        PlanningRoutingLinePrev.UpdateDatetime();
        if PlanningRoutingLinePrev."Ending Date-Time" > ResidualProdStartDateTime then begin
            ProdEndingDate := PlanningRoutingLinePrev."Ending Date";
            ProdEndingTime := PlanningRoutingLinePrev."Ending Time";
            RemainNeedQty := RunTime;
            LoadCapBack(PlanningRoutingLine.Type, PlanningRoutingLine."No.", RoutingTimeType::"Run Time", false);
            RemainNeedQty := SetupTime;
            LoadCapBack(PlanningRoutingLine.Type, PlanningRoutingLine."No.", RoutingTimeType::"Setup Time", false);
        end;

        ProdStartingDate := PlanningRoutingLine."Starting Date";
        ProdStartingTime := PlanningRoutingLine."Starting Time";
        ProdEndingDate := PlanningRoutingLine."Starting Date";
        ProdEndingTime := PlanningRoutingLine."Starting Time";
        exit(false);
    end;

    procedure CalcRoutingLineForward(CalcStartEndDate: Boolean)
    var
        PlanningRoutingLine2: Record "Planning Routing Line";
        PlanningRoutingLine3: Record "Planning Routing Line";
        ConstrainedCapacity: Record "Capacity Constrained Resource";
        ParentWorkCenter: Record "Capacity Constrained Resource";
        TempPlanRoutingLine: Record "Planning Routing Line" temporary;
        ResourceIsConstrained: Boolean;
        ParentIsConstrained: Boolean;
        SendAheadLotSize: Decimal;
        InputQtyDiffTime: Decimal;
    begin
        OnBeforeCalcRoutingLineForward(PlanningRoutingLine, WorkCenter, SendAheadLotSize, MaxLotSize, TotalLotSize, RemainNeedQty, UpdateDates, FirstEntry, TempPlanRoutingLine);

        ProdStartingTime := PlanningRoutingLine."Starting Time";
        ProdStartingDate := PlanningRoutingLine."Starting Date";
        ProdEndingTime := PlanningRoutingLine."Starting Time";
        ProdEndingDate := PlanningRoutingLine."Starting Date";

        InputQtyDiffTime := 0;

        FirstEntry := true;

        if (PlanningRoutingLine."Previous Operation No." <> '') and
           CalcStartEndDate
        then begin
            Clear(PlanningRoutingLine3);

            TempPlanRoutingLine.Reset();
            TempPlanRoutingLine.DeleteAll();

            PlanningRoutingLine2.SetRange("Worksheet Template Name", PlanningRoutingLine."Worksheet Template Name");
            PlanningRoutingLine2.SetRange("Worksheet Batch Name", PlanningRoutingLine."Worksheet Batch Name");
            PlanningRoutingLine2.SetRange("Worksheet Line No.", PlanningRoutingLine."Worksheet Line No.");
            PlanningRoutingLine2.SetFilter("Operation No.", PlanningRoutingLine."Previous Operation No.");
            if PlanningRoutingLine2.Find('-') then
                repeat
                    TotalLotSize := 0;
                    GetSendAheadEndingTime(PlanningRoutingLine2, SendAheadLotSize);

                    TempPlanRoutingLine.Copy(PlanningRoutingLine2);
                    TempPlanRoutingLine.Insert();

                    if ProdStartingDate < ProdEndingDate then begin
                        ProdStartingDate := ProdEndingDate;
                        ProdStartingTime := ProdEndingTime;
                        PlanningRoutingLine3 := PlanningRoutingLine2;
                    end else
                        if (ProdStartingDate = ProdEndingDate) and
                           (ProdStartingTime < ProdEndingTime)
                        then begin
                            ProdStartingTime := ProdEndingTime;
                            PlanningRoutingLine3 := PlanningRoutingLine2;
                        end;

                    if (PlanningRoutingLine2."Send-Ahead Quantity" > 0) and
                       (PlanningRoutingLine2."Input Quantity" > PlanningRoutingLine."Input Quantity")
                    then begin
                        WorkCenter2.Get(PlanningRoutingLine2."Work Center No.");
                        InputQtyDiffTime :=
                          (PlanningRoutingLine2."Input Quantity" - PlanningRoutingLine."Input Quantity") *
                          PlanningRoutingLine2.RunTimePer();
                        InputQtyDiffTime :=
                          Round(
                            InputQtyDiffTime *
                            CalendarMgt.TimeFactor(PlanningRoutingLine2."Run Time Unit of Meas. Code") /
                            CalendarMgt.TimeFactor(WorkCenter2."Unit of Measure Code"),
                            WorkCenter2."Calendar Rounding Precision");
                    end;
                until PlanningRoutingLine2.Next() = 0;
            if PlanningRoutingLine3."Worksheet Template Name" <> '' then begin
                PlanningRoutingLine3."Critical Path" := true;
                PlanningRoutingLine3.UpdateDatetime();
                PlanningRoutingLine3.Modify();
            end;
        end else
            SetLotSizesToMax(SendAheadLotSize, TotalLotSize);

        RemainNeedQty :=
          Round(
            WorkCenter."Queue Time" *
            CalendarMgt.TimeFactor(WorkCenter."Queue Time Unit of Meas. Code") /
            CalendarMgt.TimeFactor(WorkCenter."Unit of Measure Code"),
            WorkCenter."Calendar Rounding Precision");
        RemainNeedQty += InputQtyDiffTime;
        LoadCapForward(PlanningRoutingLine.Type, PlanningRoutingLine."No.", RoutingTimeType::"Queue Time", false);
        RemainNeedQty := GetSetupTimeBaseUOM();
        UpdateDates := true;

        ResourceIsConstrained := GetConstrainedCapacity(PlanningRoutingLine.Type, PlanningRoutingLine."No.", ConstrainedCapacity);
        ParentIsConstrained := ParentWorkCenter.Get(PlanningRoutingLine.Type::"Work Center", PlanningRoutingLine."Work Center No.");
        if (RemainNeedQty > 0) and (ResourceIsConstrained or ParentIsConstrained) then
            FinitelyLoadCapForward(RoutingTimeType::"Setup Time", ConstrainedCapacity, ResourceIsConstrained, ParentWorkCenter, ParentIsConstrained)
        else
            LoadCapForward(PlanningRoutingLine.Type, PlanningRoutingLine."No.", RoutingTimeType::"Setup Time", true);

        FirstInBatch := true;
        repeat
            if (InputQtyDiffTime > 0) and (TotalLotSize = MaxLotSize) then
                if ProdStartingDate < PlanningRoutingLine2."Ending Date" then begin
                    ProdStartingDate := PlanningRoutingLine2."Ending Date";
                    ProdStartingTime := PlanningRoutingLine2."Ending Time";
                end else
                    if PlanningRoutingLine2."Ending Date" = ProdEndingDate then
                        if PlanningRoutingLine2."Ending Time" > ProdStartingTime then
                            ProdStartingTime := PlanningRoutingLine2."Ending Time";

            LotSize := SendAheadLotSize;
            RemainNeedQty := LotSize * PlanningRoutingLine.RunTimePer();
            OnCalculateRoutingLineForwardOnAfterCalcRemainNeedQtyForLotSize(PlanningRoutingLine, RemainNeedQty);
            RemainNeedQty :=
              Round(
                RemainNeedQty *
                CalendarMgt.TimeFactor(PlanningRoutingLine."Run Time Unit of Meas. Code") /
                CalendarMgt.TimeFactor(WorkCenter."Unit of Measure Code"),
                WorkCenter."Calendar Rounding Precision");

            ResourceIsConstrained := GetConstrainedCapacity(PlanningRoutingLine.Type, PlanningRoutingLine."No.", ConstrainedCapacity);
            ParentIsConstrained := ParentWorkCenter.Get(PlanningRoutingLine.Type::"Work Center", PlanningRoutingLine."Work Center No.");
            if (RemainNeedQty > 0) and (ResourceIsConstrained or ParentIsConstrained) then
                FinitelyLoadCapForward(RoutingTimeType::"Run Time", ConstrainedCapacity, ResourceIsConstrained, ParentWorkCenter, ParentIsConstrained)
            else
                LoadCapForward(PlanningRoutingLine.Type, PlanningRoutingLine."No.", RoutingTimeType::"Run Time", true);

            ProdStartingDate := PlanningRoutingLine."Ending Date";
            ProdStartingTime := PlanningRoutingLine."Ending Time";
        until FindSendAheadEndingTime(TempPlanRoutingLine, SendAheadLotSize);

        RemainNeedQty :=
          Round(
            PlanningRoutingLine."Wait Time" *
            CalendarMgt.TimeFactor(PlanningRoutingLine."Wait Time Unit of Meas. Code") /
            CalendarMgt.TimeFactor(WorkCenter."Unit of Measure Code"),
            WorkCenter."Calendar Rounding Precision");
        LoadCapForward(PlanningRoutingLine.Type, PlanningRoutingLine."No.", RoutingTimeType::"Wait Time", false);
        RemainNeedQty :=
          Round(
            PlanningRoutingLine."Move Time" *
            CalendarMgt.TimeFactor(PlanningRoutingLine."Move Time Unit of Meas. Code") /
            CalendarMgt.TimeFactor(WorkCenter."Unit of Measure Code"),
            WorkCenter."Calendar Rounding Precision");
        LoadCapForward(PlanningRoutingLine.Type, PlanningRoutingLine."No.", RoutingTimeType::"Move Time", false);

        if PlanningRoutingLine."Starting Date" = 0D then begin
            PlanningRoutingLine."Starting Date" := PlanningRoutingLine."Ending Date";
            PlanningRoutingLine."Starting Time" := PlanningRoutingLine."Ending Time";
        end;

        PlanningRoutingLine.UpdateDatetime();
        PlanningRoutingLine.Modify();

        OnAfterCalcRoutingLineForward(PlanningRoutingLine, PlanningResiliency);
    end;


    procedure CalculateRouteLine(var PlanningRoutingLine2: Record "Planning Routing Line"; Direction: Option Forward,Backward; CalcStartEndDate: Boolean; ReqLine2: Record "Requisition Line")
    var
        ProdOrderCapNeed: Record "Prod. Order Capacity Need";
    begin
        MfgSetup.Get();

        PlanningRoutingLine := PlanningRoutingLine2;

        WaitTimeOnly :=
            (PlanningRoutingLine."Setup Time" = 0) and (PlanningRoutingLine."Run Time" = 0) and
            (PlanningRoutingLine."Move Time" = 0);

        if PlanningRoutingLine."Ending Time" = 0T then
            PlanningRoutingLine."Ending Time" := 000000T;

        if PlanningRoutingLine."Starting Time" = 0T then
            PlanningRoutingLine."Starting Time" := 000000T;

        PlanningRoutingLine."Expected Operation Cost Amt." := 0;
        PlanningRoutingLine."Expected Capacity Ovhd. Cost" := 0;
        PlanningRoutingLine."Expected Capacity Need" := 0;

        PlanningRoutingLine.TestField("Work Center No.");

        WorkCenter.Get(PlanningRoutingLine."Work Center No.");
        if PlanningRoutingLine.Type = PlanningRoutingLine.Type::"Machine Center" then begin
            MachineCenter.Get(PlanningRoutingLine."No.");
            WorkCenter."Queue Time" := MachineCenter."Queue Time";
            WorkCenter."Queue Time Unit of Meas. Code" := MachineCenter."Queue Time Unit of Meas. Code";
        end;
        if not CalcStartEndDate then
            Clear(WorkCenter."Queue Time");

        ReqLine := ReqLine2;

        ProdOrderCapNeed.SetCurrentKey(Status, "Prod. Order No.", Active);
        ProdOrderCapNeed.SetRange(Status, ReqLine."Ref. Order Status");
        ProdOrderCapNeed.SetRange("Prod. Order No.", ReqLine."Ref. Order No.");
        ProdOrderCapNeed.SetRange(Active, true);
        ProdOrderCapNeed.SetRange("Requested Only", false);
        ProdOrderCapNeed.SetRange("Routing No.", ReqLine."Routing No.");
        ProdOrderCapNeed.ModifyAll(Active, false);

        PlanningRoutingLine."Expected Operation Cost Amt." := 0;
        PlanningRoutingLine."Expected Capacity Ovhd. Cost" := 0;

        ProdOrderCapNeed.Reset();
        ProdOrderCapNeed.SetRange("Worksheet Template Name", PlanningRoutingLine."Worksheet Template Name");
        ProdOrderCapNeed.SetRange("Worksheet Batch Name", PlanningRoutingLine."Worksheet Batch Name");
        ProdOrderCapNeed.SetRange("Worksheet Line No.", PlanningRoutingLine."Worksheet Line No.");
        ProdOrderCapNeed.SetRange("Operation No.", PlanningRoutingLine."Operation No.");
        ProdOrderCapNeed.DeleteAll();

        NextCapNeedLineNo := 1;

        TotalLotSize := 0;
        Item.Get(ReqLine."No.");

        MaxLotSize :=
          ReqLine.Quantity * ReqLine."Qty. per Unit of Measure" *
          (1 + PlanningRoutingLine."Scrap Factor % (Accumulated)") *
          (1 + ReqLine."Scrap %" / 100) +
          PlanningRoutingLine."Fixed Scrap Qty. (Accum.)";

        PlanningRoutingLine."Input Quantity" := MaxLotSize;

        OnBeforeCalculateRouteLine(PlanningRoutingLine, CalcStartEndDate, Direction);
        if Direction = Direction::Backward then
            CalcRoutingLineBack(CalcStartEndDate)
        else
            CalcRoutingLineForward(CalcStartEndDate);

        PlanningRoutingLine2 := PlanningRoutingLine;
    end;

    local procedure FinitelyLoadCapBack(TimeType: Enum "Routing Time Type"; ConstrainedCapacity: Record "Capacity Constrained Resource"; ResourceIsConstrained: Boolean; ParentWorkCenter: Record "Capacity Constrained Resource"; ParentIsConstrained: Boolean)
    var
        LastProdOrderCapNeed: Record "Prod. Order Capacity Need";
        AvailTime: Decimal;
        ProdEndingDateTime: DateTime;
        ProdEndingDateTimeAddOneDay: DateTime;
        TimetoProgram: Decimal;
        AvailCap: Decimal;
        xConCurrCap: Decimal;
        EndTime: Time;
        StartTime: Time;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFinitelyLoadCapBack(
            TimeType, ConstrainedCapacity, ResourceIsConstrained, ParentWorkCenter, ParentIsConstrained,
            ProdEndingTime, ProdEndingDate, ConCurrCap, PlanningRoutingLine, CalendarEntry, RemainNeedQty,
            WorkCenter, CurrentTimeFactor, CurrentRounding, CalculateRoutingLine, ReqLine, FirstInBatch, FirstEntry,
            NextCapNeedLineNo, LotSize, PlanningResiliency, TempPlanningErrorLog, IsHandled);
        if IsHandled then
            exit;

        if (RemainNeedQty = 0) and WaitTimeOnly then
            exit;

        EndTime := ProdEndingTime;
        ProdEndingDateTime := CreateDateTime(ProdEndingDate, ProdEndingTime);
        ProdEndingDateTimeAddOneDay := CreateDateTime(ProdEndingDate + 1, ProdEndingTime);
        ConCurrCap := PlanningRoutingLine."Concurrent Capacities";
        xConCurrCap := 1;

        LastProdOrderCapNeed.SetCapacityFilters(PlanningRoutingLine.Type, PlanningRoutingLine."No.");

        CalendarEntry.SetCapacityFilters(PlanningRoutingLine.Type, PlanningRoutingLine."No.");
        CalendarEntry.SetFilter("Starting Date-Time", '<= %1', ProdEndingDateTime);
        CalendarEntry.SetFilter("Ending Date-Time", '<= %1', ProdEndingDateTimeAddOneDay);
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

                AvailCap := GetConstrainedAvailCapBaseUOM(
                    TimeType, ConstrainedCapacity, ResourceIsConstrained, ParentWorkCenter, ParentIsConstrained, false);

                if AvailCap > 0 then begin
                    ProdEndingDateTime := CreateDateTime(CalendarEntry.Date, EndTime);
                    LastProdOrderCapNeed.SetFilter(
                      "Ending Date-Time", '>= %1 & < %2', CalendarEntry."Starting Date-Time", ProdEndingDateTimeAddOneDay);
                    LastProdOrderCapNeed.SetFilter(
                      "Starting Date-Time", '>= %1 & < %2', CalendarEntry."Starting Date-Time", ProdEndingDateTime);
                    LastProdOrderCapNeed.SetRange(Active, true);
                    if LastProdOrderCapNeed.Find('+') then
                        repeat
                            if LastProdOrderCapNeed."Ending Time" < EndTime then begin
                                AvailTime := Min(CalendarMgt.CalcTimeDelta(EndTime, LastProdOrderCapNeed."Ending Time"), AvailCap);
                                if AvailTime > 0 then begin
                                    UpdateTimesBack(AvailTime, AvailCap, TimetoProgram, StartTime, EndTime);
                                    CreatePlanningCapNeed(CalendarEntry.Date, StartTime, EndTime, TimetoProgram, TimeType, 1);
                                    if FirstInBatch and FirstEntry then begin
                                        FirstInBatch := false;
                                        FirstEntry := false
                                    end;
                                    UpdateEndingDateAndTime(CalendarEntry.Date, EndTime);
                                    EndTime := StartTime;
                                end;
                            end;
                            if LastProdOrderCapNeed."Starting Time" < EndTime then
                                EndTime := LastProdOrderCapNeed."Starting Time"
                        until (LastProdOrderCapNeed.Next(-1) = 0) or (RemainNeedQty = 0) or (AvailCap = 0);

                    if (AvailCap > 0) and (RemainNeedQty > 0) then begin
                        AvailTime := Min(CalendarMgt.CalcTimeDelta(EndTime, CalendarEntry."Starting Time"), AvailCap);
                        if AvailTime > 0 then begin
                            UpdateTimesBack(AvailTime, AvailCap, TimetoProgram, StartTime, EndTime);
                            if StartTime < CalendarEntry."Starting Time" then
                                StartTime := CalendarEntry."Starting Time";
                            if TimetoProgram <> 0 then
                                CreatePlanningCapNeed(CalendarEntry.Date, StartTime, EndTime, TimetoProgram, TimeType, 1);
                            if FirstInBatch and FirstEntry then begin
                                FirstInBatch := false;
                                FirstEntry := false
                            end;
                            UpdateEndingDateAndTime(CalendarEntry.Date, EndTime);
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
                    UpdateEndingDateAndTime(CalendarEntry.Date, CalendarEntry."Ending Time");
                    ProdEndingTime := StartTime;
                    ProdEndingDate := CalendarEntry.Date;
                    PlanningRoutingLine."Starting Time" := StartTime;
                    PlanningRoutingLine."Starting Date" := CalendarEntry.Date;
                    exit;
                end;
            until false;
    end;

    local procedure UpdateEndingDateAndTime(NewDate: Date; NewTime: Time)
    begin
        if UpdateDates then begin
            PlanningRoutingLine."Ending Date" := NewDate;
            PlanningRoutingLine."Ending Time" := NewTime;
            UpdateDates := false;
        end;
    end;

    local procedure GetSetupTimeBaseUOM(): Decimal
    begin
        exit(Round(PlanningRoutingLine."Setup Time" *
            CalendarMgt.TimeFactor(PlanningRoutingLine."Setup Time Unit of Meas. Code") /
            CalendarMgt.TimeFactor(WorkCenter."Unit of Measure Code"),
            WorkCenter."Calendar Rounding Precision"));
    end;

    local procedure GetConstrainedAvailCapBaseUOM(TimeType: Enum "Routing Time Type"; CapacityConstrainedResource: Record "Capacity Constrained Resource"; ResourceIsConstrained: Boolean; ParentCapacityConstrainedResource: Record "Capacity Constrained Resource"; ParentIsConstrained: Boolean; IsForward: Boolean) AvailCap: Decimal
    var
        AbscenseAvailCap: Decimal;
        SetupTime: Decimal;
        DampTime: Decimal;
    begin
        CalculateDailyLoad(
          AvailCap, DampTime, CapacityConstrainedResource, ResourceIsConstrained, ParentCapacityConstrainedResource, ParentIsConstrained);
        SetupTime := 0;
        if TimeType = TimeType::"Run Time" then
            SetupTime := GetSetupTimeBaseUOM() * ConCurrCap;
        if RemainNeedQty + SetupTime <= AvailCap + DampTime then
            AvailCap := AvailCap + DampTime;
        AvailCap :=
          Round(AvailCap *
            CalendarMgt.TimeFactor(WorkCenter."Unit of Measure Code") *
            100 / CalendarEntry.Efficiency / ConCurrCap, 1, '>');
        AbscenseAvailCap :=
          CalculateRoutingLine.CalcAvailQtyBase(
            CalendarEntry, ProdEndingDate, ProdEndingTime, TimeType, ConCurrCap, IsForward,
            CurrentTimeFactor, CurrentRounding);
        AvailCap := Min(AbscenseAvailCap, AvailCap);
    end;

    local procedure FinitelyLoadCapForward(TimeType: Enum "Routing Time Type"; var ConstrainedCapacity: Record "Capacity Constrained Resource"; ResourceIsConstrained: Boolean; var ParentWorkCenter: Record "Capacity Constrained Resource"; ParentIsConstrained: Boolean)
    var
        NextProdOrderCapNeed: Record "Prod. Order Capacity Need";
        AvailTime: Decimal;
        ProdStartingDateTime: DateTime;
        ProdStartingDateTimeSubOneDay: DateTime;
        TimetoProgram: Decimal;
        AvailCap: Decimal;
        xConCurrCap: Decimal;
        EndTime: Time;
        StartTime: Time;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFinitelyLoadCapForward(PlanningRoutingLine, TimeType, ProdStartingDate, ProdStartingTime, IsHandled,
            ConstrainedCapacity, ResourceIsConstrained, ParentWorkCenter, ParentIsConstrained, ProdEndingTime, ProdEndingDate,
            ConCurrCap, CalendarEntry, RemainNeedQty, WorkCenter, CurrentTimeFactor, CurrentRounding, CalculateRoutingLine,
             ReqLine, FirstInBatch, FirstEntry, NextCapNeedLineNo, LotSize, PlanningResiliency, TempPlanningErrorLog);
        if IsHandled then
            exit;

        if (RemainNeedQty = 0) and WaitTimeOnly then
            exit;
        StartTime := ProdStartingTime;
        ProdStartingDateTime := CreateDateTime(ProdStartingDate, ProdStartingTime);
        ProdStartingDateTimeSubOneDay := CreateDateTime(ProdStartingDate - 1, ProdStartingTime);
        ConCurrCap := PlanningRoutingLine."Concurrent Capacities";
        xConCurrCap := 1;

        NextProdOrderCapNeed.SetCapacityFilters(PlanningRoutingLine.Type, PlanningRoutingLine."No.");

        CalendarEntry.SetCapacityFilters(PlanningRoutingLine.Type, PlanningRoutingLine."No.");
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

                AvailCap := GetConstrainedAvailCapBaseUOM(
                    TimeType, ConstrainedCapacity, ResourceIsConstrained, ParentWorkCenter, ParentIsConstrained, true);
                if AvailCap > 0 then begin
                    ProdStartingDateTime := CreateDateTime(CalendarEntry.Date, StartTime);
                    NextProdOrderCapNeed.SetFilter(
                      "Ending Date-Time", '> %1 & <= %2', ProdStartingDateTime, CalendarEntry."Ending Date-Time");
                    NextProdOrderCapNeed.SetFilter(
                      "Starting Date-Time", '> %1 & <= %2', ProdStartingDateTimeSubOneDay, CalendarEntry."Ending Date-Time");
                    NextProdOrderCapNeed.SetRange(Active, true);
                    if NextProdOrderCapNeed.Find('-') then
                        repeat
                            if NextProdOrderCapNeed."Starting Time" > StartTime then begin
                                AvailTime := Min(CalendarMgt.CalcTimeDelta(NextProdOrderCapNeed."Starting Time", StartTime), AvailCap);
                                if AvailTime > 0 then begin
                                    UpdateTimesForward(AvailTime, AvailCap, TimetoProgram, StartTime, EndTime);
                                    CreatePlanningCapNeed(CalendarEntry.Date, StartTime, EndTime, TimetoProgram, TimeType, 0);
                                    if FirstInBatch and FirstEntry then begin
                                        FirstInBatch := false;
                                        FirstEntry := false
                                    end;
                                    UpdateStartingDateAndTime(CalendarEntry.Date, StartTime);
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
                            if EndTime > CalendarEntry."Ending Time" then
                                EndTime := CalendarEntry."Ending Time";
                            if TimetoProgram <> 0 then
                                CreatePlanningCapNeed(CalendarEntry.Date, StartTime, EndTime, TimetoProgram, TimeType, 0);
                            if FirstInBatch and FirstEntry then begin
                                FirstInBatch := false;
                                FirstEntry := false
                            end;
                            UpdateStartingDateAndTime(CalendarEntry.Date, StartTime);
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
                    PlanningRoutingLine."Ending Time" := EndTime;
                    PlanningRoutingLine."Ending Date" := CalendarEntry.Date;
                    exit;
                end;
            until false;
    end;

    local procedure UpdateStartingDateAndTime(NewDate: Date; NewTime: Time)
    begin
        if UpdateDates then begin
            PlanningRoutingLine."Starting Date" := NewDate;
            PlanningRoutingLine."Starting Time" := NewTime;
            UpdateDates := false;
        end;
    end;

    local procedure CalculateDailyLoad(var AvailCap: Decimal; var DampTime: Decimal; var ConstrainedCapacity: Record "Capacity Constrained Resource"; IsResourceConstrained: Boolean; var ParentWorkCenter: Record "Capacity Constrained Resource"; IsParentConstrained: Boolean)
    var
        CurrentLoadBase: Decimal;
        AvailCapWorkCenter: Decimal;
        DampTimeWorkCenter: Decimal;
        CapEffectiveBase: Decimal;
    begin
        GetCurrentWorkCenterTimeFactorAndRounding(WorkCenter);
        if (CalendarEntry."Capacity Type" = CalendarEntry."Capacity Type"::"Work Center") or
           ((CalendarEntry."Capacity Type" = CalendarEntry."Capacity Type"::"Machine Center") and
            (IsResourceConstrained xor IsParentConstrained))
        then begin
            if IsParentConstrained then begin
                ConstrainedCapacity := ParentWorkCenter;
                CalcCapConResWorkCenterLoadBase(ConstrainedCapacity, CalendarEntry.Date, CapEffectiveBase, CurrentLoadBase)
            end else
                CalcCapConResProdOrderNeedBase(ConstrainedCapacity, CalendarEntry.Date, CapEffectiveBase, CurrentLoadBase);
            CalculateRoutingLine.CalcAvailCapBaseAndDampTime(
              ConstrainedCapacity, AvailCap, DampTime, CapEffectiveBase, CurrentLoadBase, CurrentTimeFactor, CurrentRounding);
        end
        else begin
            CalcCapConResProdOrderNeedBase(ConstrainedCapacity, CalendarEntry.Date, CapEffectiveBase, CurrentLoadBase);
            CalculateRoutingLine.CalcAvailCapBaseAndDampTime(
              ConstrainedCapacity, AvailCap, DampTime, CapEffectiveBase, CurrentLoadBase, CurrentTimeFactor, CurrentRounding);

            CalcCapConResWorkCenterLoadBase(ParentWorkCenter, CalendarEntry.Date, CapEffectiveBase, CurrentLoadBase);
            CalculateRoutingLine.CalcAvailCapBaseAndDampTime(
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
    begin
        AvailTime :=
          Round(AvailTime / CalendarMgt.TimeFactor(WorkCenter."Unit of Measure Code") *
            CalendarEntry.Efficiency / 100 * ConCurrCap, WorkCenter."Calendar Rounding Precision");
        TimetoProgram := Min(RemainNeedQty, AvailTime);
        RoundedTimetoProgram :=
          Round(TimetoProgram *
            CalendarMgt.TimeFactor(WorkCenter."Unit of Measure Code") *
            100 / CalendarEntry.Efficiency / ConCurrCap, 1, '>');
        StartTime := CalendarMgt.CalcTimeSubtract(EndTime, RoundedTimetoProgram);
        RemainNeedQty := RemainNeedQty - TimetoProgram;
        AvailCap := AvailCap - RoundedTimetoProgram;
    end;

    local procedure UpdateTimesForward(var AvailTime: Decimal; var AvailCap: Decimal; var TimetoProgram: Decimal; StartTime: Time; var EndTime: Time)
    var
        RoundedTimetoProgram: Decimal;
    begin
        AvailTime :=
          Round(AvailTime / CalendarMgt.TimeFactor(WorkCenter."Unit of Measure Code") *
            CalendarEntry.Efficiency / 100 * ConCurrCap, WorkCenter."Calendar Rounding Precision");
        TimetoProgram := Min(RemainNeedQty, AvailTime);
        RoundedTimetoProgram :=
          Round(TimetoProgram *
            CalendarMgt.TimeFactor(WorkCenter."Unit of Measure Code") *
            100 / CalendarEntry.Efficiency / ConCurrCap, 1, '>');
        EndTime := StartTime + RoundedTimetoProgram;
        RemainNeedQty := RemainNeedQty - TimetoProgram;
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

    procedure SetResiliencyOn(WkshTemplName: Code[10]; JnlBatchName: Code[10]; ItemNo: Code[20])
    begin
        PlanningResiliency := true;
        TempPlanningErrorLog.SetJnlBatch(WkshTemplName, JnlBatchName, ItemNo);
    end;

    procedure GetResiliencyError(var PlanningErrorLog: Record "Planning Error Log"): Boolean
    begin
        exit(TempPlanningErrorLog.GetError(PlanningErrorLog));
    end;

    local procedure FindSendAheadEndingTime(var TempPlanRoutingLine: Record "Planning Routing Line"; var SendAheadLotSize: Decimal): Boolean
    var
        Result: Boolean;
        xTotalLotSize: Decimal;
        xSendAheadLotSize: Decimal;
    begin
        xTotalLotSize := TotalLotSize;
        xSendAheadLotSize := SendAheadLotSize;
        if TempPlanRoutingLine.FindSet() then
            repeat
                TotalLotSize := xTotalLotSize;
                SendAheadLotSize := xSendAheadLotSize;

                Result := Result or GetSendAheadEndingTime(TempPlanRoutingLine, SendAheadLotSize);
            until TempPlanRoutingLine.Next() = 0
        else
            Result := GetSendAheadEndingTime(TempPlanRoutingLine, SendAheadLotSize);

        exit(Result);
    end;

    local procedure FindSendAheadStartingTime(var TempPlanRoutingLine: Record "Planning Routing Line"; var SendAheadLotSize: Decimal): Boolean
    var
        Result: Boolean;
        xTotalLotSize: Decimal;
        xSendAheadLotSize: Decimal;
    begin
        xTotalLotSize := TotalLotSize;
        xSendAheadLotSize := SendAheadLotSize;
        if TempPlanRoutingLine.FindSet() then
            repeat
                TotalLotSize := xTotalLotSize;
                SendAheadLotSize := xSendAheadLotSize;

                Result := Result or GetSendAheadStartingTime(TempPlanRoutingLine, SendAheadLotSize);
            until TempPlanRoutingLine.Next() = 0
        else
            Result := GetSendAheadStartingTime(TempPlanRoutingLine, SendAheadLotSize);

        exit(Result);
    end;

    local procedure CreateCalendarEntry(var CalEntry: Record "Calendar Entry")
    begin
        CalEntry."Ending Time" := 000000T;
        CalEntry."Starting Time" := 000000T;
        CalEntry.Efficiency := 100;
        CalEntry."Absence Capacity" := 0;
        CalEntry."Capacity (Total)" := 0;
        CalEntry."Capacity (Effective)" := CalEntry."Capacity (Total)";
        CalEntry."Starting Date-Time" := CreateDateTime(CalEntry.Date, CalEntry."Starting Time");
        CalEntry."Ending Date-Time" := CalEntry."Starting Date-Time" + 86400000;  // 24h * 60m * 60s * 1000ms
        if not CalEntry.Get(
            CalEntry."Capacity Type", CalEntry."No.", CalEntry.Date,
            CalEntry."Starting Time", CalEntry."Ending Time", CalEntry."Work Shift Code")
        then
            CalEntry.Insert();
    end;

    local procedure GetCurrentWorkCenterTimeFactorAndRounding(var CurrentWorkCenter: Record "Work Center")
    begin
        CurrentTimeFactor := CalendarMgt.TimeFactor(CurrentWorkCenter."Unit of Measure Code");
        CurrentRounding := CurrentWorkCenter."Calendar Rounding Precision";
    end;

    local procedure CalcCapConResWorkCenterLoadBase(var CapacityConstrainedResource: Record "Capacity Constrained Resource"; DateFilter: Date; var CapEffectiveBase: Decimal; var LoadBase: Decimal)
    begin
        CapEffectiveBase := 0;
        LoadBase := 0;

        CapacityConstrainedResource.SetRange("Date Filter", DateFilter);
        CapacityConstrainedResource.CalcFields("Capacity (Effective)", "Work Center Load Qty. for Plan");
        if CapacityConstrainedResource."Capacity (Effective)" <> 0 then begin
            CapEffectiveBase := Round(CapacityConstrainedResource."Capacity (Effective)" * CurrentTimeFactor, CurrentRounding);
            LoadBase := Round(CapacityConstrainedResource."Work Center Load Qty. for Plan" * CurrentTimeFactor, CurrentRounding);
        end;
    end;

    local procedure CalcCapConResProdOrderNeedBase(var CapacityConstrainedResource: Record "Capacity Constrained Resource"; DateFilter: Date; var CapEffectiveBase: Decimal; var LoadBase: Decimal)
    begin
        CapEffectiveBase := 0;
        LoadBase := 0;

        CapacityConstrainedResource.SetRange("Date Filter", DateFilter);
        CapacityConstrainedResource.CalcFields("Capacity (Effective)", "Prod. Order Need Qty. for Plan");
        if CapacityConstrainedResource."Capacity (Effective)" <> 0 then begin
            CapEffectiveBase := Round(CapacityConstrainedResource."Capacity (Effective)" * CurrentTimeFactor, CurrentRounding);
            LoadBase := Round(CapacityConstrainedResource."Prod. Order Need Qty. for Plan" * CurrentTimeFactor, CurrentRounding);
        end;
    end;

    local procedure FilterCalendarEntryBeforeOrOnDateTime(CapacityType: Enum "Capacity Type"; WorkMachineCenterNo: Code[20]; DateValue: Date; TimeValue: Time)
    begin
        CalendarEntry.SetCapacityFilters(CapacityType, WorkMachineCenterNo);
        CalendarEntry.SetRange("Starting Date-Time", 0DT, CreateDateTime(DateValue, TimeValue));
        CalendarEntry.SetRange("Ending Date-Time", 0DT, CreateDateTime(DateValue + 1, TimeValue));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcRoutingLineBack(PlanningRoutingLine: Record "Planning Routing Line"; PlanningResiliency: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcRoutingLineForward(PlanningRoutingLine: Record "Planning Routing Line"; PlanningResiliency: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreatePlanningCapNeed(
        var NextCapNeedLineNo: Integer; var PlanningRoutingLine: Record "Planning Routing Line"; var ReqLine: Record "Requisition Line"; NeedDate: Date;
        StartingTime: Time; EndingTime: Time; TimeType: option "Setup Time","Run Time"; NeedQty: Decimal; ConCurrCap: Decimal;
        var CalendarEntry: Record "Calendar Entry"; LotSize: Decimal; RemainNeedQty: Decimal; FirstInBatch: Boolean; Direction: Option "Forward","Backward")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcMoveTimeBack(var PlanningRoutingLine: Record "Planning Routing Line"; var WorkCenter: Record "Work Center"; var ProdEndingDate: Date; var ProdEndingTime: Time; var ProdStartingDate: Date; var ProdStartingTime: Time; var UpdateDates: Boolean; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcRoutingLineBack(var PlanningRoutingLine: Record "Planning Routing Line"; CalcStartEndDate: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcRoutingLineForward(var PlanningRoutingLine: Record "Planning Routing Line"; WorkCenter: Record "Work Center"; SendAheadLotSize: Decimal; MaxLotSize: Decimal; var TotalLotSize: Decimal; var RemainNeedQty: Decimal; var UpdateDates: Boolean; var FirstEntry: Boolean; var TempPlanningRoutingLine: Record "Planning Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcWaitTimeBack(var PlanningRoutingLine: Record "Planning Routing Line"; var WorkCenter: Record "Work Center"; var ProdEndingDate: Date; var ProdEndingTime: Time; var ProdStartingDate: Date; var ProdStartingTime: Time; var UpdateDates: Boolean; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateRouteLine(var PlanningRoutingLine: Record "Planning Routing Line"; var CalcStartEndDate: Boolean; var Direction: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLoadCapForward(var PlanningRoutingLine: Record "Planning Routing Line"; TimeType: Enum "Routing Time Type"; var ProdStartingDate: Date; var ProdStartingTime: Time; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetLotSizesToMax(var SendAheadLotSize: Decimal; var TotalLotSize: Decimal; MaxLotSize: Decimal; PlanningRoutingLine: Record "Planning Routing Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateLoadBackOnBeforeFirstCalculate(var PlanningRoutingLine: Record "Planning Routing Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePlanningCapNeedOnAfterCalulateExpectedUnitCost(var PlanningRoutingLine: Record "Planning Routing Line"; TimeType: Enum "Routing Time Type"; NeedQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePlanningCapNeed(var PlanningRoutingLine: Record "Planning Routing Line"; TimeType: Enum "Routing Time Type"; var NeedQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateRoutingLineBackOnAfterCalcRemainNeedQtyForLotSize(PlanningRoutingLine: Record "Planning Routing Line"; var RemainNeedQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcRoutingLineBackOnAfterCalcShouldCalcNextOperation(PlanningRoutingLine: Record "Planning Routing Line"; MaxLotSize: Decimal; var TotalLotSize: Decimal; var SendAheadLotSize: Decimal; var ShouldCalcNextOperation: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateRoutingLineForwardOnAfterCalcRemainNeedQtyForLotSize(PlanningRoutingLine: Record "Planning Routing Line"; var RemainNeedQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetConstrainedCapacity(CapType: Enum "Capacity Type"; CapNo: Code[20]; var ConstrainedCapacity: Record "Capacity Constrained Resource"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFinitelyLoadCapBack(TimeType: Enum "Routing Time Type"; ConstrainedCapacity: Record "Capacity Constrained Resource"; ResourceIsConstrained: Boolean; ParentWorkCenter: Record "Capacity Constrained Resource"; ParentIsConstrained: Boolean; var ProdEndingTime: Time; var ProdEndingDate: Date; var ConCurrCap: Decimal; var PlanningRoutingLine: Record "Planning Routing Line"; var CalendarEntry: Record "Calendar Entry"; var RemainNeedQty: Decimal; var WorkCenter: Record "Work Center"; var CurrentTimeFactor: Decimal; var CurrentRounding: Decimal; var CalculateRoutingLine: Codeunit "Calculate Routing Line"; var ReqLine: Record "Requisition Line"; var FirstInBatch: Boolean; var FirstEntry: Boolean; var NextCapNeedLineNo: Integer; var LotSize: Decimal; var PlanningResiliency: Boolean; var TempPlanningErrorLog: Record "Planning Error Log" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLoadCapBack(var PlanningRoutingLine: Record "Planning Routing Line"; TimeType: Enum "Routing Time Type"; var ProdStartingDate: Date; var ProdStartingTime: Time; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFinitelyLoadCapForward(var PlanningRoutingLine: Record "Planning Routing Line"; TimeType: Enum "Routing Time Type"; var ProdStartingDate: Date; var ProdStartingTime: Time; var IsHandled: Boolean; ConstrainedCapacity: Record "Capacity Constrained Resource"; ResourceIsConstrained: Boolean; ParentWorkCenter: Record "Capacity Constrained Resource"; ParentIsConstrained: Boolean; var ProdEndingTime: Time; var ProdEndingDate: Date; var ConCurrCap: Decimal; var CalendarEntry: Record "Calendar Entry"; var RemainNeedQty: Decimal; var WorkCenter: Record "Work Center"; var CurrentTimeFactor: Decimal; var CurrentRounding: Decimal; var CalculateRoutingLine: Codeunit "Calculate Routing Line"; var ReqLine: Record "Requisition Line"; var FirstInBatch: Boolean; var FirstEntry: Boolean; var NextCapNeedLineNo: Integer; var LotSize: Decimal; var PlanningResiliency: Boolean; var TempPlanningErrorLog: Record "Planning Error Log" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatingLoadForwardOnAfterUpdateRemainNeedQtyBase(PlanningRoutingLine: Record "Planning Routing Line"; CalendarEntry: Record "Calendar Entry"; var EndingTime: Time)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatingLoadBackOnAfterUpdateRemainNeedQtyBase(PlanningRoutingLine: Record "Planning Routing Line"; CalendarEntry: Record "Calendar Entry"; var StartingTime: Time)
    begin
    end;
}

