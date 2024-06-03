// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

using System.PerformanceProfile;
using System.DataAdministration;

codeunit 1932 "Scheduled Perf. Profiler Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure MapActivityTypeToRecord(var PerformanceProfileScheduler: Record "Performance Profile Scheduler"; ActivityType: Enum "Activity Type")
    begin
        if (ActivityType = ActivityType::WebClient) then
            PerformanceProfileScheduler."Client Type" := PerformanceProfileScheduler."Client Type"::"Web Client"
        else
            if (ActivityType = ActivityType::Background) then
                PerformanceProfileScheduler."Client Type" := PerformanceProfileScheduler."Client Type"::Background
            else
                if (ActivityType = ActivityType::WebAPIClient) then
                    PerformanceProfileScheduler."Client Type" := PerformanceProfileScheduler."Client Type"::"Web Service";
    end;

    procedure MapRecordToActivityType(PerformanceProfileScheduler: Record "Performance Profile Scheduler"; var ActivityType: Enum "Activity Type")
    begin
        if (PerformanceProfileScheduler."Client Type" = PerformanceProfileScheduler."Client Type"::Background) then
            ActivityType := ActivityType::Background
        else
            if (PerformanceProfileScheduler."Client Type" = PerformanceProfileScheduler."Client Type"::"Web Client") then
                ActivityType := ActivityType::WebClient
            else
                if (PerformanceProfileScheduler."Client Type" = PerformanceProfileScheduler."Client Type"::"Web Service") then
                    ActivityType := ActivityType::WebAPIClient;
    end;

    procedure InitializeFields(var PerformanceProfileScheduler: Record "Performance Profile Scheduler"; var ActivityType: Enum "Activity Type")
    begin
        PerformanceProfileScheduler.Init();
        PerformanceProfileScheduler."Schedule ID" := CreateGuid();
        PerformanceProfileScheduler."Starting Date-Time" := CurrentDateTime;
        PerformanceProfileScheduler.Enabled := true;
        PerformanceProfileScheduler."Profile Keep Time" := 7;
        PerformanceProfileScheduler."Profile Creation Threshold" := 500;
        PerformanceProfileScheduler.Frequency := PerformanceProfileScheduler.Frequency::"100";
        PerformanceProfileScheduler."Client Type" := PerformanceProfileScheduler."Client Type"::"Web Client";
        PerformanceProfileScheduler."User ID" := UserSecurityId();
        ActivityType := ActivityType::WebClient;
    end;

    procedure ValidatePerformanceProfileSchedulerDates(PerformanceProfileScheduler: Record "Performance Profile Scheduler")
    begin
        if ((PerformanceProfileScheduler."Ending Date-Time" <> 0DT) and (PerformanceProfileScheduler."Starting Date-Time" > PerformanceProfileScheduler."Ending Date-Time")) then
            Error(ProfileStartingDateLessThenEndingDateErr);
    end;

    procedure ValidatePerformanceProfileSchedulerRecord(PerformanceProfileScheduler: Record "Performance Profile Scheduler"; ActivityType: Enum "Activity Type")
    var
        LocalPerformanceProfileScheduler: Record "Performance Profile Scheduler";
    begin
        MapActivityTypeToRecord(PerformanceProfileScheduler, ActivityType);

        if ((PerformanceProfileScheduler."Ending Date-Time" = 0DT) or
            (PerformanceProfileScheduler."Starting Date-Time" = 0DT) or
            (IsNullGuid(PerformanceProfileScheduler."User ID"))) then
            exit;

        // The period sets should not intersect.
        LocalPerformanceProfileScheduler.Init();
        LocalPerformanceProfileScheduler.SetFilter("Starting Date-Time", '<=%1', PerformanceProfileScheduler."Ending Date-Time");
        LocalPerformanceProfileScheduler.SetFilter("Client Type", '=%1', PerformanceProfileScheduler."Client Type");
        LocalPerformanceProfileScheduler.SetFilter("User ID", '=%1', PerformanceProfileScheduler."User ID");

        if ((LocalPerformanceProfileScheduler.FindFirst()) and
            (LocalPerformanceProfileScheduler."Starting Date-Time" <> 0DT) and
            (LocalPerformanceProfileScheduler."Ending Date-Time" <> 0DT) and
            (LocalPerformanceProfileScheduler."Schedule ID" <> PerformanceProfileScheduler."Schedule ID")) then
            Error(ProfileHasAlreadyBeenScheduledErr);
    end;

    procedure GetRetentionPeriod(): Code[20]
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
    begin
        if RetentionPolicySetup.Get(Database::"Performance Profiles") then
            exit(RetentionPolicySetup."Retention Period");
    end;

    procedure CreateRetentionPolicySetup(ErrorInfo: ErrorInfo)
    var
        RetentionPolicySetupRec: Record "Retention Policy Setup";
        RetentionPolicySetup: Codeunit "Retention Policy Setup";
    begin
        CreateRetentionPolicySetup(Database::"Performance Profiles", RetentionPolicySetup.FindOrCreateRetentionPeriod("Retention Period Enum"::"1 Week"));
        if RetentionPolicySetupRec.Get(Database::"Performance Profiles") then
            Page.Run(Page::"Retention Policy Setup Card", RetentionPolicySetupRec);
    end;

    procedure CreateRetentionPolicySetup(TableId: Integer; RetentionPeriodCode: Code[20])
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
    begin
        if RetentionPolicySetup.Get(TableId) then
            exit;
        RetentionPolicySetup.Validate("Table Id", TableId);
        RetentionPolicySetup.Validate("Apply to all records", true);
        RetentionPolicySetup.Validate("Retention Period", RetentionPeriodCode);
        RetentionPolicySetup.Validate(Enabled, true);
        RetentionPolicySetup.Insert(true);
    end;

    var
        ProfileStartingDateLessThenEndingDateErr: Label 'The performance profile starting date must be set before the ending date.';
        ProfileHasAlreadyBeenScheduledErr: Label 'Only one performance profile session can be scheduled for a given activity type for a given user for a given period.';
}