namespace System.Tooling;
using System.PerformanceProfile;
using System.Security.AccessControl;

codeunit 1932 "Scheduled Perf Profiler Impl"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure ValidateProfileKeepTime(PerformanceProfileScheduler: record "Performance Profile Scheduler")
    begin
        if (PerformanceProfileScheduler."Profile Keep Time" < 1) or (PerformanceProfileScheduler."Profile Keep Time" > 7) then begin
            Error(ProfileExpirationTimeRangeErrorLbl);
        end;
    end;

    procedure MapActivityTypeToRecord(var PerformanceProfileScheduler: record "Performance Profile Scheduler"; ActivityType: Option WebClient,Background,WebAPIClient)
    begin
        if (ActivityType = ActivityType::WebClient) then
            PerformanceProfileScheduler."Client Type" := PerformanceProfileScheduler."Client Type"::"Web Client"
        else if (ActivityType = ActivityType::Background) then
            PerformanceProfileScheduler."Client Type" := PerformanceProfileScheduler."Client Type"::Background
        else if (ActivityType = ActivityType::WebAPIClient) then
            PerformanceProfileScheduler."Client Type" := PerformanceProfileScheduler."Client Type"::"Web Service";
    end;

    procedure MapRecordToActivityType(PerformanceProfileScheduler: record "Performance Profile Scheduler"; var ActivityType: Option WebClient,Background,WebAPIClient)
    begin
        if (PerformanceProfileScheduler."Client Type" = PerformanceProfileScheduler."Client Type"::Background) then
            ActivityType := ActivityType::Background
        else if (PerformanceProfileScheduler."Client Type" = PerformanceProfileScheduler."Client Type"::"Web Client") then
            ActivityType := ActivityType::WebClient
        else if (PerformanceProfileScheduler."Client Type" = PerformanceProfileScheduler."Client Type"::"Web Service") then
            ActivityType := ActivityType::WebAPIClient;
    end;

    procedure InitializeFields(var PerformanceProfileScheduler: record "Performance Profile Scheduler"; var ActivityType: Option WebClient,Background,WebAPIClient)
    begin
        PerformanceProfileScheduler.Init();
        PerformanceProfileScheduler."Schedule ID" := CreateGuid();
        PerformanceProfileScheduler."Starting Date-Time" := CurrentDateTime;
        PerformanceProfileScheduler.Enabled := true;
        PerformanceProfileScheduler."Profile Keep Time" := 7;
        PerformanceProfileScheduler."Profile Creation Threshold" := 500;
        PerformanceProfileScheduler.Frequency := PerformanceProfileScheduler.Frequency::"100";
        ActivityType := ActivityType::WebClient;
    end;

    procedure ValidatePerformanceProfileSchedulerDates(PerformanceProfileScheduler: record "Performance Profile Scheduler")
    begin
        if ((PerformanceProfileScheduler."Ending Date-Time" <> 0DT) and (PerformanceProfileScheduler."Starting Date-Time" > PerformanceProfileScheduler."Ending Date-Time")) then
            Error(ProfileStartingDateLessThenEndingDateLbl);
    end;

    procedure ValidatePerformanceProfileSchedulerRecord(PerformanceProfileScheduler: record "Performance Profile Scheduler")
    var
        TempPerformanceProfileScheduler: record "Performance Profile Scheduler";

    begin
        if ((PerformanceProfileScheduler."Ending Date-Time" = 0DT) or
            (PerformanceProfileScheduler."Starting Date-Time" = 0DT) or
            (IsNullGuid(PerformanceProfileScheduler."User ID"))) then
            exit;

        // The period sets should not intersect.
        TempPerformanceProfileScheduler.Init();
        TempPerformanceProfileScheduler.SetFilter("Starting Date-Time", '<=%1', PerformanceProfileScheduler."Ending Date-Time");
        TempPerformanceProfileScheduler.SetFilter("Client Type", '=%1', PerformanceProfileScheduler."Client Type");
        TempPerformanceProfileScheduler.SetFilter("User ID", '=%1', PerformanceProfileScheduler."User ID");

        if ((TempPerformanceProfileScheduler.FindFirst()) and
            (TempPerformanceProfileScheduler."Starting Date-Time" <> 0DT) and
            (TempPerformanceProfileScheduler."Ending Date-Time" <> 0DT) and
            (TempPerformanceProfileScheduler."Schedule ID" <> PerformanceProfileScheduler."Schedule ID")) then
            Error(ProfileHasAlreadyBeenScheduledLbl, ProfileHasAlreadyBeenScheduledLbl);
    end;

    var
        ProfileExpirationTimeRangeErrorLbl: Label 'The performance profile expiration time must be between 1 and 7 days.';
        ProfileStartingDateLessThenEndingDateLbl: Label 'The performance profile starting date must be set before the ending date.';

        ProfileHasAlreadyBeenScheduledLbl: Label 'Only one performance profile session can be scheduled for a given activity type for a given user for a given period.';
}