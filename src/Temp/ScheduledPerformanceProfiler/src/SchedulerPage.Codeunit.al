namespace System.Tooling;
using System.PerformanceProfile;
using System.Security.AccessControl;

/// <summary>
/// Provides implementation details for working on the Perf. Profiler Schedules" list and card pages.
/// </summary>
codeunit 1931 "Scheduler Page"
{
    /// <summary>
    /// Validates the Profile Keep Time" field on the "Performance Profile Scheduler" record
    /// </summary>
    /// <param name="PerformanceProfileScheduler">The "Performance Profile Scheduler" record</param>
    procedure ValidateProfileKeepTime(var PerformanceProfileScheduler: record "Performance Profile Scheduler")
    begin
        SchedulerPage.ValidateProfileKeepTime(PerformanceProfileScheduler);
    end;

    /// <summary>
    /// Maps an activity type to a session type
    /// </summary>
    /// <param name="PerformanceProfileScheduler">The "Performance Profile Scheduler" record </param>
    /// <param name="ActivityType">The actvity option type</param>
    procedure MapActivityType(var PerformanceProfileScheduler: record "Performance Profile Scheduler"; ActivityType: Option WebClient,Background,WebAPIClient)
    begin
        SchedulerPage.MapActivityType(PerformanceProfileScheduler, ActivityType);
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

    var
        SchedulerPage: codeunit "Scheduler Page Impl";
}