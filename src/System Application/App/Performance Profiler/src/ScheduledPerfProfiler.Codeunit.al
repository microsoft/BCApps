// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

using System.PerformanceProfile;

/// <summary>
/// Provides implementation details for working on the Perf. Profiler Schedules list and card pages.
/// </summary>
codeunit 1931 "Scheduled Perf. Profiler"
{
    Access = Public;

    var
        ScheduledPerfProfilerImpl: Codeunit "Scheduled Perf. Profiler Impl.";

    /// <summary>
    /// Validate dates for the "Performance Profile Scheduler" record with all validations.
    /// </summary>
    /// <param name="PerformanceProfileScheduler">The "Performance Profile Scheduler" record</param>
    /// <param name="MaxRetentionPeriod">The maximum retention period</param>
    procedure ValidatePerformanceProfileSchedulerDates(PerformanceProfileScheduler: Record "Performance Profile Scheduler"; MaxRetentionPeriod: Duration)
    begin
        ScheduledPerfProfilerImpl.ValidatePerformanceProfileSchedulerDates(PerformanceProfileScheduler, MaxRetentionPeriod);
    end;

    /// <summary>
    /// Validate the relation between the dates for the "Performance Profile Scheduler" record.
    /// </summary>
    /// <param name="PerformanceProfileScheduler">The "Performance Profile Scheduler" record</param>
    /// <param name="MaxRetentionPeriod">The maximum retention period</param>
    procedure ValidatePerformanceProfileSchedulerDatesRelation(PerformanceProfileScheduler: Record "Performance Profile Scheduler")
    begin
        ScheduledPerfProfilerImpl.ValidatePerformanceProfileSchedulerDatesRelation(PerformanceProfileScheduler);
    end;

    /// <summary>
    /// Validates the end time of a schedule.
    /// </summary>
    /// <param name="PerformanceProfileScheduler">The record.</param>
    procedure ValidatePerformanceProfileEndTime(PerformanceProfileScheduler: Record "Performance Profile Scheduler")
    begin
        ScheduledPerfProfilerImpl.ValidatePerformanceProfileEndTime(PerformanceProfileScheduler);
    end;

    /// <summary>
    /// Maps an activity type to a session type.
    /// </summary>
    /// <param name="PerformanceProfileScheduler">The "Performance Profile Scheduler" record </param>
    /// <param name="ActivityType">The activity enum type</param>
    procedure MapActivityTypeToRecord(var PerformanceProfileScheduler: Record "Performance Profile Scheduler"; ActivityType: Enum "Perf. Profile Activity Type")
    begin
        ScheduledPerfProfilerImpl.MapActivityTypeToRecord(PerformanceProfileScheduler, ActivityType);
    end;

    /// <summary>
    /// Maps a session type to an activity type.
    /// </summary>
    /// <param name="PerformanceProfileScheduler">The "Performance Profile Scheduler" record </param>
    /// <param name="ActivityType">The activity enum type</param>
    procedure MapRecordToActivityType(PerformanceProfileScheduler: Record "Performance Profile Scheduler"; var ActivityType: Enum "Perf. Profile Activity Type")
    begin
        ScheduledPerfProfilerImpl.MapRecordToActivityType(PerformanceProfileScheduler, ActivityType);
    end;

    /// <summary>
    /// Filters the record with the users that are allowed to view the Performance Profile Scheduler page
    /// </summary>
    /// <param name="PerformanceProfileScheduler">The record</param>
    /// <param name="SecurityID">The security ID to filter the opening of the page</param>
    procedure FilterUsers(var PerformanceProfileScheduler: Record "Performance Profile Scheduler"; SecurityID: Guid)
    begin
        ScheduledPerfProfilerImpl.FilterUsers(PerformanceProfileScheduler, SecurityID, false);
    end;

    /// <summary>
    /// Filters the record with the users that are allowed to view the Performance Profile Scheduler page
    /// </summary>
    /// <param name="PerformanceProfileScheduler">The record</param>
    /// <param name="SecurityID">The security ID to filter the opening of the page</param>
    /// <param name="ForceFilterToUser">Filter to the passed in user even if the user is an admin.</param>
    procedure FilterUsers(var PerformanceProfileScheduler: Record "Performance Profile Scheduler"; SecurityID: Guid; ForceFilterToUser: Boolean)
    begin
        ScheduledPerfProfilerImpl.FilterUsers(PerformanceProfileScheduler, SecurityID, ForceFilterToUser);
    end;

    /// <summary>
    /// Maps a session type to an activity type.
    /// </summary>
    /// <param name="PerformanceProfileScheduler">The "Performance Profile Scheduler" record </param>
    ///<returns>The user name if found, else empty</returns>
    procedure MapRecordToUserName(PerformanceProfileScheduler: Record "Performance Profile Scheduler"): Text
    begin
        exit(ScheduledPerfProfilerImpl.MapRecordToUserName(PerformanceProfileScheduler));
    end;

    /// <summary>
    /// Initalizes the fields for the "Performance Profile Scheduler" record
    /// </summary>
    /// <param name="PerformanceProfileScheduler">The "Performance Profile Scheduler" record </param>
    /// <param name="ActivityType">>The activity enum type</param>
    procedure InitializeFields(var PerformanceProfileScheduler: Record "Performance Profile Scheduler"; var ActivityType: Enum "Perf. Profile Activity Type")
    begin
        ScheduledPerfProfilerImpl.InitializeFields(PerformanceProfileScheduler, ActivityType);
    end;

    /// <summary>
    /// Validates the consistency of the "Performance Profile Scheduler" record
    /// </summary>
    /// <param name="PerformanceProfileScheduler">The "Performance Profile Scheduler" record</param>
    procedure ValidatePerformanceProfileSchedulerRecord(PerformanceProfileScheduler: Record "Performance Profile Scheduler"; ActivityType: Enum "Perf. Profile Activity Type")
    begin
        ScheduledPerfProfilerImpl.ValidatePerformanceProfileScheduler(PerformanceProfileScheduler, ActivityType);
    end;

    /// <summary>
    /// Gets the retention period for performance profiles
    /// </summary>
    /// <returns>The retention period</returns>
    procedure GetRetentionPeriod(): Code[20]
    begin
        exit(ScheduledPerfProfilerImpl.GetRetentionPeriod());
    end;

    /// <summary>
    ///  Validates the threshold field
    /// </summary>
    /// <param name="PerformanceProfileScheduler"></param>
    procedure ValidateThreshold(var PerformanceProfileScheduler: Record "Performance Profile Scheduler")
    begin
        ScheduledPerfProfilerImpl.ValidateThreshold(PerformanceProfileScheduler);
    end;

    /// <summary>
    /// Returns true if profiling is enabled for the session.
    /// </summary>
    /// <param name="ScheduleID">The schedule ID that triggers the profiling.</param>
    /// <returns>True if profiling is enabled, false otherwise.</returns>
    procedure IsProfilingEnabled(var ScheduleID: Guid): Boolean
    begin
        exit(ScheduledPerfProfilerImpl.IsProfilingEnabled(ScheduleID));
    end;
}