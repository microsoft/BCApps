// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.API.Codeunits;

using System.DateTime;

/// <summary>
/// API codeunit exposing date, time zone and recurrence operations as non-data-bound (unbound) actions.
/// Wraps "Recurrence Schedule" (4690), "Time Zone" (8720) and "Unix Timestamp" (8722).
/// </summary>
/// <remarks>TODO(AB#641822): decorate with the API codeunit subtype (microsoft/codeunits) when the platform ships it.</remarks>
codeunit 6012 "Date Time API"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    /// <summary>Calculates the next occurrence of a recurrence after the given last occurrence.</summary>
    /// <param name="RecurrenceID">The recurrence ID.</param>
    /// <param name="LastOccurrence">The last occurrence date/time.</param>
    procedure CalculateNextOccurrence(RecurrenceID: Guid; LastOccurrence: DateTime): DateTime
    var
        RecurrenceSchedule: Codeunit "Recurrence Schedule";
    begin
        exit(RecurrenceSchedule.CalculateNextOccurrence(RecurrenceID, LastOccurrence));
    end;

    /// <summary>Returns a human-readable description of the recurrence.</summary>
    /// <param name="RecurrenceID">The recurrence ID.</param>
    procedure RecurrenceDisplayText(RecurrenceID: Guid): Text
    var
        RecurrenceSchedule: Codeunit "Recurrence Schedule";
    begin
        exit(RecurrenceSchedule.RecurrenceDisplayText(RecurrenceID));
    end;

    /// <summary>Creates a daily recurrence and returns its ID.</summary>
    procedure CreateDaily(StartTime: Time; StartDate: Date; EndDate: Date; DaysBetween: Integer): Guid
    var
        RecurrenceSchedule: Codeunit "Recurrence Schedule";
    begin
        exit(RecurrenceSchedule.CreateDaily(StartTime, StartDate, EndDate, DaysBetween));
    end;

    /// <summary>Creates a weekly recurrence and returns its ID.</summary>
    procedure CreateWeekly(StartTime: Time; StartDate: Date; EndDate: Date; WeeksBetween: Integer; Monday: Boolean; Tuesday: Boolean; Wednesday: Boolean; Thursday: Boolean; Friday: Boolean; Saturday: Boolean; Sunday: Boolean): Guid
    var
        RecurrenceSchedule: Codeunit "Recurrence Schedule";
    begin
        exit(RecurrenceSchedule.CreateWeekly(StartTime, StartDate, EndDate, WeeksBetween, Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, Sunday));
    end;

    /// <summary>Creates a monthly-by-day-of-month recurrence and returns its ID.</summary>
    procedure CreateMonthlyByDay(StartTime: Time; StartDate: Date; EndDate: Date; MonthsBetween: Integer; DayOfMonth: Integer): Guid
    var
        RecurrenceSchedule: Codeunit "Recurrence Schedule";
    begin
        exit(RecurrenceSchedule.CreateMonthlyByDay(StartTime, StartDate, EndDate, MonthsBetween, DayOfMonth));
    end;

    /// <summary>Returns the time zone offset for the given date/time in the current time zone.</summary>
    procedure GetTimezoneOffset(SourceDateTime: DateTime): Duration
    var
        TimeZone: Codeunit "Time Zone";
    begin
        exit(TimeZone.GetTimezoneOffset(SourceDateTime));
    end;

    /// <summary>Returns the time zone offset for the given date/time in the specified time zone.</summary>
    procedure GetTimezoneOffset(SourceDateTime: DateTime; TimeZoneId: Text): Duration
    var
        TimeZone: Codeunit "Time Zone";
    begin
        exit(TimeZone.GetTimezoneOffset(SourceDateTime, TimeZoneId));
    end;

    /// <summary>Returns the offset between two time zones for the given date/time.</summary>
    procedure GetTimezoneOffset(SourceDateTime: DateTime; SourceTimeZoneId: Text; DestinationTimeZoneId: Text): Duration
    var
        TimeZone: Codeunit "Time Zone";
    begin
        exit(TimeZone.GetTimezoneOffset(SourceDateTime, SourceTimeZoneId, DestinationTimeZoneId));
    end;

    /// <summary>Returns whether the specified time zone supports daylight saving time.</summary>
    procedure TimeZoneSupportsDaylightSavingTime(TimeZoneId: Text): Boolean
    var
        TimeZone: Codeunit "Time Zone";
    begin
        exit(TimeZone.TimeZoneSupportsDaylightSavingTime(TimeZoneId));
    end;

    /// <summary>Returns whether the given date/time is in daylight saving time for the specified time zone.</summary>
    procedure IsDaylightSavingTime(DateTimeToCheck: DateTime; TimeZoneId: Text): Boolean
    var
        TimeZone: Codeunit "Time Zone";
    begin
        exit(TimeZone.IsDaylightSavingTime(DateTimeToCheck, TimeZoneId));
    end;

    /// <summary>Returns the Unix timestamp in seconds for the given date/time.</summary>
    procedure CreateTimestampSeconds(DateTimeFrom: DateTime): BigInteger
    var
        UnixTimestamp: Codeunit "Unix Timestamp";
    begin
        exit(UnixTimestamp.CreateTimestampSeconds(DateTimeFrom));
    end;

    /// <summary>Returns the Unix timestamp in milliseconds for the given date/time.</summary>
    procedure CreateTimestampMilliseconds(DateTimeFrom: DateTime): BigInteger
    var
        UnixTimestamp: Codeunit "Unix Timestamp";
    begin
        exit(UnixTimestamp.CreateTimestampMilliseconds(DateTimeFrom));
    end;

    /// <summary>Converts a Unix timestamp back to a date/time.</summary>
    /// <param name="Timestamp">The Unix timestamp.</param>
    procedure EvaluateTimestamp(Timestamp: BigInteger): DateTime
    var
        UnixTimestamp: Codeunit "Unix Timestamp";
    begin
        exit(UnixTimestamp.EvaluateTimestamp(Timestamp));
    end;
}
