// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Capacity;

using Microsoft.Foundation.Calendar;
using Microsoft.Manufacturing.WorkCenter;

codeunit 99000755 "Shop Calendar Management"
{
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        ShopCalendarHoliday: Record "Shop Calendar Holiday";
        WorkCenter: Record "Work Center";
        CapUnitOfMeasure: Record "Capacity Unit of Measure";
        CalendarMgt: Codeunit "Calendar Management";

    procedure QtyperTimeUnitofMeasure(WorkCenterNo: Code[20]; UnitOfMeasureCode: Code[10]): Decimal
    begin
        GetWorkCenter(WorkCenterNo);
        exit(TimeFactor(UnitOfMeasureCode) / TimeFactor(WorkCenter."Unit of Measure Code"));
    end;

    procedure TimeFactor(UnitOfMeasureCode: Code[10]) Factor: Decimal
    begin
        if UnitOfMeasureCode = '' then
            exit(1);

        GetCapUnitOfMeasure(UnitOfMeasureCode);

        case CapUnitOfMeasure.Type of
            CapUnitOfMeasure.Type::Seconds:
                exit(1000);
            CapUnitOfMeasure.Type::Minutes:
                exit(60000);
            CapUnitOfMeasure.Type::"100/Hour":
                exit(36000);
            CapUnitOfMeasure.Type::Hours:
                exit(3600000);
            CapUnitOfMeasure.Type::Days:
                exit(86400000);
        end;

        Factor := 1;
        OnAfterTimeFactor(CapUnitOfMeasure, Factor);
    end;

    local procedure ShopCalHoliday(ShopCalendarCode: Code[10]; Date: Date; StartingTime: Time; EndingTime: Time): Boolean
    begin
        if not ShopCalendarHoliday.Get(ShopCalendarCode, Date) then
            exit(false);
        if (ShopCalendarHoliday."Ending Time" <= StartingTime) or (EndingTime <= ShopCalendarHoliday."Starting Time") then
            exit(false);
        exit(true);
    end;

    procedure CalculateSchedule(CapacityType: Enum "Capacity Type"; No: Code[20]; WorkCenterNo: Code[20]; StartingDate: Date; EndingDate: Date)
    var
        CalendarEntry: Record "Calendar Entry";
        CalAbsentEntry: Record "Calendar Absence Entry";
        ShopCalendar: Record "Shop Calendar Working Days";
        CalAbsenceMgt: Codeunit "Calendar Absence Management";
        PeriodDate: Date;
        CalAbsEntryExists: Boolean;
        IsHandled: Boolean;
    begin
        GetWorkCenter(WorkCenterNo);
        WorkCenter.TestField("Shop Calendar Code");

        OnBeforeCalculateSchedule(WorkCenter, StartingDate);

        CalendarEntry.LockTable();
        CalendarEntry.SetRange("Capacity Type", CapacityType);
        CalendarEntry.SetRange("No.", No);
        CalendarEntry.SetRange(Date, StartingDate, EndingDate);
        CalendarEntry.DeleteAll();
        CalAbsentEntry.SetRange("Capacity Type", CapacityType);
        CalAbsentEntry.SetRange("No.", No);
        CalAbsentEntry.SetRange(Date, StartingDate, EndingDate);
        CalAbsentEntry.ModifyAll(Updated, false);

        ShopCalendar.SetRange("Shop Calendar Code", WorkCenter."Shop Calendar Code");
        PeriodDate := StartingDate;
        while PeriodDate <= EndingDate do begin
            ShopCalendar.SetRange(Day, Date2DWY(PeriodDate, 1) - 1);
            OnCalculateScheduleOnSetShopCalendarFilters(ShopCalendar, PeriodDate);
            if ShopCalendar.Find('-') then
                repeat
                    IsHandled := false;
                    OnCalculateScheduleOnBeforeProcessShopCalendar(ShopCalendar, PeriodDate, StartingDate, EndingDate, IsHandled);
                    if not IsHandled then begin
                        ShopCalendar.TestField("Starting Time");
                        ShopCalendar.TestField("Ending Time");
                        ShopCalendar.TestField("Work Shift Code");

                        CalendarEntry.Init();
                        CalendarEntry."Capacity Type" := CapacityType;
                        CalendarEntry."Work Shift Code" := ShopCalendar."Work Shift Code";
                        CalendarEntry.Date := PeriodDate;
                        CalendarEntry."Starting Time" := 0T;
                        CalendarEntry."Ending Time" := 0T;
                        CalendarEntry.Validate("No.", No);

                        if not ShopCalHoliday(
                             WorkCenter."Shop Calendar Code",
                             CalendarEntry.Date,
                             ShopCalendar."Starting Time",
                             ShopCalendar."Ending Time")
                        then
                            InsertCalendarEntry(CalendarEntry, ShopCalendar."Starting Time", ShopCalendar."Ending Time")
                        else
                            if ShopCalendarHoliday."Starting Time" <= ShopCalendar."Starting Time" then begin
                                if ShopCalendarHoliday."Ending Time" < ShopCalendar."Ending Time" then
                                    InsertCalendarEntry(CalendarEntry, ShopCalendarHoliday."Ending Time", ShopCalendar."Ending Time");
                            end else begin
                                InsertCalendarEntry(CalendarEntry, ShopCalendar."Starting Time", ShopCalendarHoliday."Starting Time");
                                if ShopCalendarHoliday."Ending Time" < ShopCalendar."Ending Time" then
                                    InsertCalendarEntry(CalendarEntry, ShopCalendarHoliday."Ending Time", ShopCalendar."Ending Time");
                            end;
                    end;
                until ShopCalendar.Next() = 0;

            OnCalculateScheduleOnAfterProcessShopCalendar(CapacityType, No, WorkCenterNo, PeriodDate);

            CalAbsentEntry.SetRange(Updated, false);
            if PeriodDate = StartingDate then
                CalAbsEntryExists := not CalAbsentEntry.IsEmpty();
            CalAbsentEntry.SetRange(Date, PeriodDate);
            if CalAbsEntryExists then
                while CalAbsentEntry.FindFirst() do
                    CalAbsenceMgt.UpdateAbsence(CalAbsentEntry);
            CalAbsentEntry.SetRange(Updated);
            PeriodDate := PeriodDate + 1;
        end;

        OnAfterCalculateSchedule(CapacityType, No, WorkCenterNo, StartingDate, EndingDate);
    end;

    local procedure InsertCalendarEntry(var CalEntry: Record "Calendar Entry"; StartingTime: Time; EndingTime: Time)
    begin
        CalEntry."Starting Time" := StartingTime;
        CalEntry.Validate("Ending Time", EndingTime);
        CalEntry.Insert();
    end;

    local procedure GetWorkCenter(WorkCenterNo: Code[20])
    begin
        if WorkCenter."No." = WorkCenterNo then
            exit;
        WorkCenter.Get(WorkCenterNo);
    end;

    local procedure GetCapUnitOfMeasure(UnitOfMeasureCode: Code[10])
    begin
        if CapUnitOfMeasure.Code = UnitOfMeasureCode then
            exit;
        CapUnitOfMeasure.Get(UnitOfMeasureCode);
    end;

    procedure ClearInternals()
    begin
        Clear(ShopCalendarHoliday);
        Clear(WorkCenter);
        Clear(CapUnitOfMeasure);
        Clear(CalendarMgt);
    end;

    procedure CalcTimeDelta(EndingTime: Time; StartingTime: Time): Integer
    begin
        exit(CalendarMgt.CalcTimeDelta(EndingTime, StartingTime));
    end;

    procedure CalcTimeSubtract(Time: Time; Value: Integer): Time
    begin
        exit(CalendarMgt.CalcTimeSubtract(Time, Value));
    end;

    procedure GetMaxDate(): Date
    begin
        exit(99991230D);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Work Center", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifyWorkCenter(var Rec: Record "Work Center"; var xRec: Record "Work Center"; RunTrigger: Boolean)
    begin
        Clear(WorkCenter);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Shop Calendar Holiday", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifyShopCalendarHoliday(var Rec: Record "Shop Calendar Holiday"; var xRec: Record "Shop Calendar Holiday"; RunTrigger: Boolean)
    begin
        Clear(ShopCalendarHoliday);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Capacity Unit of Measure", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifyCapacityUnitOfMeasure(var Rec: Record "Capacity Unit of Measure"; var xRec: Record "Capacity Unit of Measure"; RunTrigger: Boolean)
    begin
        Clear(CapUnitOfMeasure);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTimeFactor(var CapUnitOfMeasure: Record "Capacity Unit of Measure"; var Factor: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateSchedule(var WorkCenter: Record "Work Center"; StartingDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateScheduleOnBeforeProcessShopCalendar(var ShopCalendarWorkingDays: Record "Shop Calendar Working Days"; PeriodDate: Date; StartingDate: Date; EndingDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateScheduleOnSetShopCalendarFilters(var ShopCalendarWorkingDays: Record "Shop Calendar Working Days"; PeriodDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateSchedule(CapacityType: Enum "Capacity Type"; No: Code[20]; WorkCenterNo: Code[20]; StartingDate: Date; EndingDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateScheduleOnAfterProcessShopCalendar(CapacityType: Enum "Capacity Type"; No: Code[20]; WorkCenterNo: Code[20]; PeriodDate: Date)
    begin
    end;
}

