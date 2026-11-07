// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 6911 "Expense Per Diem Calculation"
{
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";

    internal procedure SetExpenseAgentSetup(NewExpenseAgentSetup: Record "Expense Agent Setup")
    begin
        ExpenseAgentSetup := NewExpenseAgentSetup;
    end;

    procedure CalculatePerDiemForSingleDay(
        CurrentDate: Date;
        BaseRate: Decimal;
        TripStartDateTime: DateTime;
        TripEndDateTime: DateTime): Decimal
    var
        DayStartTime, DayEndTime : DateTime;
        HoursInDay: Decimal;
        IsFirstDay, IsLastDay, HasOvernightBefore : Boolean;
    begin
        // Determine day boundaries for this specific date
        DayStartTime := CreateDateTime(CurrentDate, 000000T);  // Midnight start
        DayEndTime := CreateDateTime(CurrentDate, 235900T);    // Midnight end

        // Check if this is first/last day of trip
        IsFirstDay := (CurrentDate = DT2Date(TripStartDateTime));
        IsLastDay := (CurrentDate = DT2Date(TripEndDateTime));

        // Adjust times for actual trip boundaries
        if IsFirstDay then
            DayStartTime := TripStartDateTime;

        if IsLastDay then
            DayEndTime := TripEndDateTime;

        // Calculate hours present in this day
        HoursInDay := Round((DayEndTime - DayStartTime) / (60 * 60 * 1000), 0.01);

        case ExpenseAgentSetup."Full Per-Diem Calculation" of
            ExpenseAgentSetup."Full Per-Diem Calculation"::None:
                exit(0);
            ExpenseAgentSetup."Full Per-Diem Calculation"::"Full Calendar Day":
                exit(CalculateFullCalendarDayAmount(IsFirstDay, IsLastDay, BaseRate, TripStartDateTime, TripEndDateTime));
            ExpenseAgentSetup."Full Per-Diem Calculation"::"24-hour Rolling Period":
                exit(Calculate24HourRollingDayAmount(CurrentDate, BaseRate, TripStartDateTime, TripEndDateTime));
            ExpenseAgentSetup."Full Per-Diem Calculation"::"Overnight Stay":
                begin
                    HasOvernightBefore := (CurrentDate > DT2Date(TripStartDateTime));
                    exit(CalculateOvernightStayDayAmount(CurrentDate, BaseRate, TripStartDateTime, TripEndDateTime));
                end;
        end;
    end;

    local procedure CalculateFullCalendarDayAmount(
        IsFirstDay: Boolean;
        IsLastDay: Boolean;
        BaseRate: Decimal;
        TripStartDateTime: DateTime;
        TripEndDateTime: DateTime): Decimal
    var
        IsFullCalendarDay: Boolean;
        HoursInDay: Decimal;
        DayStartTime, DayEndTime : DateTime;
        CurrentDate: Date;
    begin
        // Calculate actual hours in this day for partial day validation
        CurrentDate := DT2Date(TripStartDateTime);
        if IsLastDay then
            CurrentDate := DT2Date(TripEndDateTime);

        DayStartTime := CreateDateTime(CurrentDate, 000000T);
        DayEndTime := CreateDateTime(CurrentDate, 235900T);

        if IsFirstDay then
            DayStartTime := TripStartDateTime;
        if IsLastDay then
            DayEndTime := TripEndDateTime;

        HoursInDay := Round((DayEndTime - DayStartTime) / (60 * 60 * 1000), 0.01);

        IsFullCalendarDay := true;

        if IsFirstDay and (DT2Time(TripStartDateTime) <> 000000T) then
            IsFullCalendarDay := false;

        if IsLastDay and (DT2Time(TripEndDateTime) <> 235900T) then
            IsFullCalendarDay := false;

        if IsFullCalendarDay then
            exit(BaseRate)
        else begin
            // Partial day - check minimum hours requirement
            if HoursInDay < (ExpenseAgentSetup."Min Hours for Partial Per Diem" - GetToleranceInHours(ExpenseAgentSetup."Min Hours for Partial Per Diem")) then
                exit(0); // Below minimum hours for partial per diem

            // Use flat percentage if configured
            if ExpenseAgentSetup."Partial Day Rules" = ExpenseAgentSetup."Partial Day Rules"::"Flat Percentage Of Full Rate" then
                exit(BaseRate * ExpenseAgentSetup."Percentage For Partial Day" / 100)
            else
                exit(0); // Partial day rules not configured for flat percentage
        end;
    end;

    local procedure Calculate24HourRollingDayAmount(
        CurrentDate: Date;
        BaseRate: Decimal;
        TripStartDateTime: DateTime;
        TripEndDateTime: DateTime): Decimal
    var
        PeriodStartTime, PeriodEndTime : DateTime;
        PeriodDurationHours: Decimal;
        PeriodStartDate: Date;
        OneDayMs: BigInteger;
    begin
        // For 24-hour rolling period method:
        // Find which 24-hour period "belongs" to this calendar day
        // Each rolling period is assigned to the calendar day where it starts

        OneDayMs := 24 * 60 * 60 * 1000;  // 86,400,000 ms in one day
        PeriodStartTime := TripStartDateTime;

        // Check each 24-hour period starting from trip start
        repeat
            PeriodEndTime := PeriodStartTime + OneDayMs;

            // Don't go beyond trip end
            if PeriodEndTime > TripEndDateTime then
                PeriodEndTime := TripEndDateTime;

            PeriodStartDate := DT2Date(PeriodStartTime);
            PeriodDurationHours := Round((PeriodEndTime - PeriodStartTime) / (60 * 60 * 1000), 0.01);

            // If this period starts on the current date, calculate its per diem
            if PeriodStartDate = CurrentDate then begin
                // For complete 24-hour periods
                if PeriodDurationHours >= (24 - GetToleranceInHours(24)) then
                    exit(BaseRate);
                if PeriodDurationHours >= (ExpenseAgentSetup."Minimum Hours for Per Diem" - GetToleranceInHours(ExpenseAgentSetup."Minimum Hours for Per Diem")) then
                    exit(BaseRate);
                if (ExpenseAgentSetup."Partial Day Rules" = ExpenseAgentSetup."Partial Day Rules"::"Based On Eligible Hours") and
                        (PeriodDurationHours >= (ExpenseAgentSetup."Min Hours for Partial Per Diem" - GetToleranceInHours(ExpenseAgentSetup."Min Hours for Partial Per Diem"))) then
                    exit(BaseRate * ExpenseAgentSetup."Percentage For Partial Day" / 100)
                else
                    exit(0);
            end;
            PeriodStartTime := PeriodStartTime + OneDayMs;
        until PeriodStartTime >= TripEndDateTime;

        // If no period starts on this date, no per diem for this day
        exit(0);
    end;

    local procedure CalculateOvernightStayDayAmount(
        CurrentDate: Date;
        BaseRate: Decimal;
        TripStartDateTime: DateTime;
        TripEndDateTime: DateTime): Decimal
    var
        TripStartDate, TripEndDate : Date;
        PeriodStartTime, PeriodEndTime : DateTime;
        PeriodDurationHours: Decimal;
        PeriodStartDate: Date;
        OneDayMs: BigInteger;
    begin
        // For overnight stay method:
        // Only trips that span multiple calendar dates are eligible
        // Find which overnight period "belongs" to this calendar day

        TripStartDate := DT2Date(TripStartDateTime);
        TripEndDate := DT2Date(TripEndDateTime);

        // Same-day trips get zero per diem regardless of duration
        if TripStartDate = TripEndDate then
            exit(0);

        OneDayMs := 24 * 60 * 60 * 1000;  // 86,400,000 ms in one day
        PeriodStartTime := TripStartDateTime;

        // Check each overnight period (24-hour chunks from trip start)
        repeat
            PeriodEndTime := PeriodStartTime + OneDayMs;

            // Don't go beyond trip end
            if PeriodEndTime > TripEndDateTime then
                PeriodEndTime := TripEndDateTime;

            PeriodStartDate := DT2Date(PeriodStartTime);
            PeriodDurationHours := Round((PeriodEndTime - PeriodStartTime) / (60 * 60 * 1000), 0.01);

            // If this overnight period starts on the current date, calculate its per diem
            if PeriodStartDate = CurrentDate then begin
                if PeriodDurationHours >= (ExpenseAgentSetup."Minimum Hours for Per Diem" - GetToleranceInHours(ExpenseAgentSetup."Minimum Hours for Per Diem")) then
                    exit(BaseRate);
                if (ExpenseAgentSetup."Partial Day Rules" = ExpenseAgentSetup."Partial Day Rules"::"Based On Eligible Hours") and
                        (PeriodDurationHours >= (ExpenseAgentSetup."Min Hours for Partial Per Diem" - GetToleranceInHours(ExpenseAgentSetup."Min Hours for Partial Per Diem"))) then
                    exit(BaseRate * ExpenseAgentSetup."Percentage For Partial Day" / 100)
                else
                    exit(0);
            end;

            PeriodStartTime := PeriodStartTime + OneDayMs;
        until PeriodStartTime >= TripEndDateTime;

        // If no overnight period starts on this date, no per diem for this day
        exit(0);
    end;

    local procedure GetToleranceInHours(Hours: Decimal): Decimal
    begin
        if Hours <> 0 then
            exit(Hours * 0.01); // 1% tolerance to avoid comparison issues ex- 5.98 Hours with 6 Hours
    end;
}