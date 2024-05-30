namespace System.Tooling;
using System.PerformanceProfile;
using System.Security.AccessControl;

codeunit 1931 "Scheduler Page"
{
    procedure ValidateProfileKeepTime(var PerformanceProfileScheduler: record "Performance Profile Scheduler")
    begin
        SchedulerPageValidator.ValidateProfileKeepTime(PerformanceProfileScheduler);
    end;


    var
        SchedulerPageValidator: codeunit "Scheduler Page";
}