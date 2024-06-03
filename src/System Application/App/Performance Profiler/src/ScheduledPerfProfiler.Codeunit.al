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
    /// Validate dates for the "Performance Profile Scheduler" record
    /// </summary>
    /// <param name="PerformanceProfileScheduler">The "Performance Profile Scheduler" record</param>
    procedure ValidatePerformanceProfileSchedulerDates(PerformanceProfileScheduler: Record "Performance Profile Scheduler")
    begin
        ScheduledPerfProfilerImpl.ValidatePerformanceProfileSchedulerDates(PerformanceProfileScheduler);
    end;

    /// <summary>
    /// Maps an activity type to a session type
    /// </summary>
    /// <param name="PerformanceProfileScheduler">The "Performance Profile Scheduler" record </param>
    /// <param name="ActivityType">The actvity option type</param>
    procedure MapActivityTypeToRecord(var PerformanceProfileScheduler: Record "Performance Profile Scheduler"; ActivityType: Enum "Activity Type")
    begin
        ScheduledPerfProfilerImpl.MapActivityTypeToRecord(PerformanceProfileScheduler, ActivityType);
    end;

    /// <summary>
    /// Maps a session type to an activity type.
    /// </summary>
    /// <param name="PerformanceProfileScheduler">The "Performance Profile Scheduler" record </param>
    /// <param name="ActivityType">The actvity option type</param>
    procedure MapRecordToActivityType(PerformanceProfileScheduler: Record "Performance Profile Scheduler"; var ActivityType: Enum "Activity Type")
    begin
        ScheduledPerfProfilerImpl.MapRecordToActivityType(PerformanceProfileScheduler, ActivityType);
    end;

    /// <summary>
    /// Initalizes the fields for the "Performance Profile Scheduler" receord
    /// </summary>
    /// <param name="PerformanceProfileScheduler">The "Performance Profile Scheduler" record </param>
    /// <param name="ActivityType">>The actvity option type</param>
    procedure InitializeFields(var PerformanceProfileScheduler: Record "Performance Profile Scheduler"; var ActivityType: Enum "Activity Type")
    begin
        ScheduledPerfProfilerImpl.InitializeFields(PerformanceProfileScheduler, ActivityType);
    end;

    /// <summary>
    /// Validates the consistency of the "Performance Profile Scheduler" record
    /// </summary>
    /// <param name="PerformanceProfileScheduler">The "Performance Profile Scheduler" record</param>
    procedure ValidatePerformanceProfileSchedulerRecord(PerformanceProfileScheduler: Record "Performance Profile Scheduler")
    begin
        ScheduledPerfProfilerImpl.ValidatePerformanceProfileSchedulerRecord(PerformanceProfileScheduler);
    end;

    /// <summary>
    /// Gets the retention period for performance profiles
    /// </summary>
    /// <returns>The retention period</returns>
    procedure GetRetentionPeriod(): Code[20]
    begin
        exit(ScheduledPerfProfilerImpl.GetRetentionPeriod());
    end;
}