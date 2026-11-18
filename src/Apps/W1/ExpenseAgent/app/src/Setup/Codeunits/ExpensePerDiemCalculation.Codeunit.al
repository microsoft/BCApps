// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using System.DateTime;

codeunit 6911 "Expense Per Diem Calculation"
{
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        AgentTimeZoneId: Text;
        TimeZoneFallbackLbl: Label 'Per diem days are split in the session time zone because the agent time zone could not be resolved.', Locked = true;
        UtcEpochTxt: Label '1900-01-01T00:00:00Z', Locked = true;

    internal procedure SetExpenseAgentSetup(NewExpenseAgentSetup: Record "Expense Agent Setup")
    var
        ExpenseAuditSubscribers: Codeunit "Expense Audit Subscribers";
        TelemetryDimensions: Dictionary of [Text, Text];
        ResolvedTimeZoneId: Text[180];
        UnresolvedReason: Text;
    begin
        ExpenseAgentSetup := NewExpenseAgentSetup;
        // Only the Expense Agent service, calling through the APIs, uses the agent time zone. Users keep their own time zone.
        if not IsExpenseAgentServiceCall() then begin
            SetTimeZone('');
            exit;
        end;

        if ExpenseAgentSetup.GetAgentTimeZone(ResolvedTimeZoneId, UnresolvedReason) then begin
            SetTimeZone(ResolvedTimeZoneId);
            exit;
        end;

        SetTimeZone('');
        TelemetryDimensions.Add('Category', ExpenseAuditSubscribers.TelemetryCategory());
        TelemetryDimensions.Add('FeatureName', ExpenseAgentSetup.GetFeatureName());
        TelemetryDimensions.Add('Reason', UnresolvedReason);
        Session.LogMessage('0000WPD', TimeZoneFallbackLbl, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All, TelemetryDimensions);
    end;

    local procedure IsExpenseAgentServiceCall(): Boolean
    var
        ExpenseAgentAPIValidation: Codeunit "Expense Agent API Validation";
        IsServiceCall: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeIsExpenseAgentServiceCall(IsServiceCall, IsHandled);
        if IsHandled then
            exit(IsServiceCall);

        if not (CurrentClientType() in [ClientType::ODataV4, ClientType::Api]) then
            exit(false);
        // Off SaaS there is no Entra app identity, so every API caller counts as the Expense Agent, as in the Expenses API and expense tables.
        // Agent users only exist on SaaS, so without one the agent time zone can't be resolved and the session time zone is used.
        exit(ExpenseAgentAPIValidation.IsCurrentUserExpenseAgent());
    end;

    /// <summary>
    /// Sets the time zone used to split trip days. An empty value means the session time zone.
    /// </summary>
    internal procedure SetTimeZone(TimeZoneId: Text)
    begin
        AgentTimeZoneId := TimeZoneId;
    end;

    /// <summary>
    /// Returns the date of a UTC instant in the time zone that per diem days are split in: the agent time zone for
    /// Expense Agent service calls, otherwise the session time zone. The stored value is not changed.
    /// </summary>
    internal procedure GetPerDiemDate(UtcDateTime: DateTime): Date
    var
        LocalMs: BigInteger;
        DayIndex: Integer;
    begin
        if UtcDateTime = 0DT then
            exit(0D);
        if AgentTimeZoneId = '' then
            exit(DT2Date(UtcDateTime));

        LocalMs := GetLocalMsSinceEpoch(UtcDateTime);
        DayIndex := LocalMs div MsPerDay();
        exit(GetEpochDate() + DayIndex);
    end;

    /// <summary>
    /// Returns the time of a UTC instant in the time zone that per diem days are split in: the agent time zone for
    /// Expense Agent service calls, otherwise the session time zone. The stored value is not changed.
    /// </summary>
    internal procedure GetPerDiemTime(UtcDateTime: DateTime): Time
    var
        LocalMs: BigInteger;
        MsOfDay: Integer;
    begin
        if UtcDateTime = 0DT then
            exit(0T);
        if AgentTimeZoneId = '' then
            exit(DT2Time(UtcDateTime));

        LocalMs := GetLocalMsSinceEpoch(UtcDateTime);
        MsOfDay := LocalMs mod MsPerDay();
        exit(000000T + MsOfDay);
    end;

    local procedure GetLocalMsSinceEpoch(UtcDateTime: DateTime): BigInteger
    begin
        exit((UtcDateTime - GetUtcEpoch()) + GetAgentOffset(UtcDateTime));
    end;

    local procedure GetAgentOffset(UtcDateTime: DateTime): Duration
    var
        TimeZone: Codeunit "Time Zone";
    begin
        exit(TimeZone.GetTimezoneOffset(UtcDateTime, AgentTimeZoneId));
    end;

    local procedure GetUtcEpoch() UtcEpoch: DateTime
    begin
        Evaluate(UtcEpoch, UtcEpochTxt, 9);
    end;

    local procedure GetEpochDate(): Date
    begin
        exit(DMY2Date(1, 1, 1900));
    end;

    local procedure MsPerDay(): Integer
    begin
        exit(86400000);
    end;

    procedure CalculatePerDiemForSingleDay(
        CurrentDate: Date;
        BaseRate: Decimal;
        TripStartDateTime: DateTime;
        TripEndDateTime: DateTime): Decimal
    var
        IsFirstDay, IsLastDay, HasOvernightBefore : Boolean;
    begin
        // Check if this is first/last day of trip
        IsFirstDay := (CurrentDate = GetPerDiemDate(TripStartDateTime));
        IsLastDay := (CurrentDate = GetPerDiemDate(TripEndDateTime));

        case ExpenseAgentSetup."Full Per-Diem Calculation" of
            ExpenseAgentSetup."Full Per-Diem Calculation"::None:
                exit(0);
            ExpenseAgentSetup."Full Per-Diem Calculation"::"Full Calendar Day":
                exit(CalculateFullCalendarDayAmount(IsFirstDay, IsLastDay, BaseRate, TripStartDateTime, TripEndDateTime));
            ExpenseAgentSetup."Full Per-Diem Calculation"::"24-hour Rolling Period":
                exit(Calculate24HourRollingDayAmount(CurrentDate, BaseRate, TripStartDateTime, TripEndDateTime));
            ExpenseAgentSetup."Full Per-Diem Calculation"::"Overnight Stay":
                begin
                    HasOvernightBefore := (CurrentDate > GetPerDiemDate(TripStartDateTime));
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
        DayStartTime, DayEndTime : Time;
    begin
        // Hours present in this day, read on the clock that per diem days are split by
        DayStartTime := 000000T;
        DayEndTime := 235900T;
        if IsFirstDay then
            DayStartTime := GetPerDiemTime(TripStartDateTime);
        if IsLastDay then
            DayEndTime := GetPerDiemTime(TripEndDateTime);

        HoursInDay := Round((DayEndTime - DayStartTime) / (60 * 60 * 1000), 0.01);

        IsFullCalendarDay := (DayStartTime = 000000T) and (DayEndTime = 235900T);

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

            PeriodStartDate := GetPerDiemDate(PeriodStartTime);
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

        TripStartDate := GetPerDiemDate(TripStartDateTime);
        TripEndDate := GetPerDiemDate(TripEndDateTime);

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

            PeriodStartDate := GetPerDiemDate(PeriodStartTime);
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

    [InternalEvent(false, false)]
    local procedure OnBeforeIsExpenseAgentServiceCall(var IsServiceCall: Boolean; var IsHandled: Boolean)
    begin
    end;
}