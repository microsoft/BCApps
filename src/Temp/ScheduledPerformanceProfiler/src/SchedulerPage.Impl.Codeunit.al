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



    var
        ProfileExpirationTimeRangeErrorLbl: Label 'The profile expiration time must be between 1 and 7 days.';
}