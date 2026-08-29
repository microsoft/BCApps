// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.API.Codeunits;

using System.DateTime;

/// <summary>
/// Provides read-only time zone information and calculations for integrations.
/// </summary>
/// <remarks>
/// Until the API codeunit subtype is available, the Microsoft.API.Codeunits namespace publishes
/// this codeunit under the microsoft/codeunits/beta route. Time zone IDs are Windows time zone IDs,
/// such as UTC or Pacific Standard Time.
/// </remarks>
codeunit 6012 "Time Zone API"
{
    Access = Public;
    InherentEntitlements = X;

    /// <summary>Gets the offset between UTC and a time zone at a specified date and time.</summary>
    /// <param name="SourceDateTime">The date and time at which to evaluate the offset.</param>
    /// <param name="TimeZoneId">The Windows time zone ID.</param>
    /// <returns>The time zone's offset from UTC.</returns>
    procedure GetUtcOffset(SourceDateTime: DateTime; TimeZoneId: Text): Duration
    var
        TimeZone: Codeunit "Time Zone";
    begin
        exit(TimeZone.GetTimezoneOffset(SourceDateTime, TimeZoneId));
    end;

    /// <summary>Gets the offset between two time zones at a specified date and time.</summary>
    /// <param name="SourceDateTime">The date and time at which to evaluate the offset.</param>
    /// <param name="SourceTimeZoneId">The source Windows time zone ID.</param>
    /// <param name="DestinationTimeZoneId">The destination Windows time zone ID.</param>
    /// <returns>The destination time zone's UTC offset minus the source time zone's UTC offset.</returns>
    procedure GetTimeZoneOffset(SourceDateTime: DateTime; SourceTimeZoneId: Text; DestinationTimeZoneId: Text): Duration
    var
        TimeZone: Codeunit "Time Zone";
    begin
        exit(TimeZone.GetTimezoneOffset(SourceDateTime, SourceTimeZoneId, DestinationTimeZoneId));
    end;

    /// <summary>Checks whether a time zone supports daylight saving time.</summary>
    /// <param name="TimeZoneId">The Windows time zone ID.</param>
    /// <returns>True when the time zone supports daylight saving time; otherwise, false.</returns>
    procedure SupportsDaylightSavingTime(TimeZoneId: Text): Boolean
    var
        TimeZone: Codeunit "Time Zone";
    begin
        exit(TimeZone.TimeZoneSupportsDaylightSavingTime(TimeZoneId));
    end;

    /// <summary>Checks whether a date and time falls within daylight saving time for a time zone.</summary>
    /// <param name="DateTimeToCheck">The date and time to check.</param>
    /// <param name="TimeZoneId">The Windows time zone ID.</param>
    /// <returns>True when daylight saving time is in effect; otherwise, false.</returns>
    procedure IsDaylightSavingTime(DateTimeToCheck: DateTime; TimeZoneId: Text): Boolean
    var
        TimeZone: Codeunit "Time Zone";
    begin
        exit(TimeZone.IsDaylightSavingTime(DateTimeToCheck, TimeZoneId));
    end;
}
