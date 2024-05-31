namespace System.Tooling;
using System.PerformanceProfile;

/// <summary>
/// Provides implementation details for working on the Perf. Profiler Schedules" list and card pages.
/// </summary>
codeunit 1931 "Scheduler Page"
{
    Access = Public;

    /// <summary>
    /// Validates the "Profile Keep Time" field on the "Performance Profile Scheduler" record
    /// </summary>
    /// <param name="PerformanceProfileScheduler">The "Performance Profile Scheduler" record</param>
    procedure ValidateProfileKeepTime(PerformanceProfileScheduler: record "Performance Profile Scheduler")
    begin
        SchedulerPage.ValidateProfileKeepTime(PerformanceProfileScheduler);
    end;

    /// <summary>
    /// Validate dates for the "Performance Profile Scheduler" record
    /// </summary>
    /// <param name="PerformanceProfileScheduler">The "Performance Profile Scheduler" record</param>
    procedure ValidatePerformanceProfileSchedulerDates(PerformanceProfileScheduler: record "Performance Profile Scheduler")
    begin
        SchedulerPage.ValidatePerformanceProfileSchedulerDates(PerformanceProfileScheduler);
    end;

    /// <summary>
    /// Maps an activity type to a session type
    /// </summary>
    /// <param name="PerformanceProfileScheduler">The "Performance Profile Scheduler" record </param>
    /// <param name="ActivityType">The actvity option type</param>
    procedure MapActivityTypeToRecord(var PerformanceProfileScheduler: record "Performance Profile Scheduler"; ActivityType: Option WebClient,Background,WebAPIClient)
    begin
        SchedulerPage.MapActivityTypeToRecord(PerformanceProfileScheduler, ActivityType);
    end;

    /// <summary>
    /// Maps a session type to an activity type.
    /// </summary>
    /// <param name="PerformanceProfileScheduler">The "Performance Profile Scheduler" record </param>
    /// <param name="ActivityType">The actvity option type</param>
    procedure MapRecordToActivityType(PerformanceProfileScheduler: record "Performance Profile Scheduler"; var ActivityType: Option WebClient,Background,WebAPIClient)
    begin
        SchedulerPage.MapRecordToActivityType(PerformanceProfileScheduler, ActivityType);
    end;

    /// <summary>
    /// Initalizes teh fields for the "Performance Profile Scheduler" receord
    /// </summary>
    /// <param name="PerformanceProfileScheduler">The "Performance Profile Scheduler" record </param>
    /// <param name="ActivityType">>The actvity option type</param>
    procedure InitializeFields(var PerformanceProfileScheduler: record "Performance Profile Scheduler"; var ActivityType: Option WebClient,Background,WebAPIClient)
    begin
        SchedulerPage.InitializeFields(PerformanceProfileScheduler, ActivityType);
    end;

    /// <summary>
    /// Validates teh consistency of the "Performance Profile Scheduler" record
    /// </summary>
    /// <param name="PerformanceProfileScheduler">The "Performance Profile Scheduler" record</param>
    procedure ValidatePerformanceProfileSchedulerRecord(PerformanceProfileScheduler: record "Performance Profile Scheduler")
    begin
        SchedulerPage.ValidatePerformanceProfileSchedulerRecord(PerformanceProfileScheduler);
    end;

    var
        SchedulerPage: codeunit "Scheduler Page Impl";
}