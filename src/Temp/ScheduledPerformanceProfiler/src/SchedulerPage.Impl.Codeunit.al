namespace System.Tooling;
using System.PerformanceProfile;
using System.Security.AccessControl;

codeunit 1932 "Scheduler Page Impl"
{
    procedure ValidateProfileKeepTime(var PerformanceProfileScheduler: record "Performance Profile Scheduler")
    begin
        if (PerformanceProfileScheduler."Profile Keep Time" < 1) or (PerformanceProfileScheduler."Profile Keep Time" > 7) then begin
            Error(ProfileExpirationTimeRangeErrorLbl);
        end;
    end;

    procedure MapActivityType(var PerformanceProfileScheduler: record "Performance Profile Scheduler"; ActivityType: Option WebClient,Background,WebAPIClient)
    begin
        if (ActivityType = ActivityType::WebClient) then
            PerformanceProfileScheduler."Client Type" := PerformanceProfileScheduler."Client Type"::"Web Client"
        else if (ActivityType = ActivityType::Background) then
            PerformanceProfileScheduler."Client Type" := PerformanceProfileScheduler."Client Type"::Background
        else if (ActivityType = ActivityType::WebAPIClient) then
            PerformanceProfileScheduler."Client Type" := PerformanceProfileScheduler."Client Type"::"Web Service";
    end;

    procedure InitializeFields(var PerformanceProfileScheduler: record "Performance Profile Scheduler"; var ActivityType: Option WebClient,Background,WebAPIClient)
    begin
        PerformanceProfileScheduler.Init();
        PerformanceProfileScheduler."Schedule ID" := CreateGuid();
        ActivityType := ActivityType::WebClient;
        PerformanceProfileScheduler."Profile Keep Time" := 7;
        PerformanceProfileScheduler."Profile Creation Threshold" := 500;
        PerformanceProfileScheduler.Frequency := PerformanceProfileScheduler.Frequency::"100"
    end;

    var
        ProfileExpirationTimeRangeErrorLbl: Label 'The profile expiration time must be between 1 and 7 days.';
}