// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

using System.PerformanceProfile;
using System.DataAdministration;
using System.Security.AccessControl;
using System.Security.User;

codeunit 1932 "Scheduled Perf. Profiler Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure MapActivityTypeToRecord(var PerformanceProfileScheduler: Record "Performance Profile Scheduler"; ActivityType: Enum "Perf. Profile Activity Type")
    var
        PerformanceProfileHelper: Codeunit "Perf. Prof. Activity Mapper";
    begin
        PerformanceProfileHelper.MapActivityTypeToClientType(PerformanceProfileScheduler."Client Type", ActivityType);
    end;

    procedure MapRecordToActivityType(PerformanceProfileScheduler: Record "Performance Profile Scheduler"; var ActivityType: Enum "Perf. Profile Activity Type")
    var
        PerfProfActivityMapper: Codeunit "Perf. Prof. Activity Mapper";
    begin
        PerfProfActivityMapper.MapClientTypeToActivityType(PerformanceProfileScheduler."Client Type", ActivityType);
    end;

    procedure MapRecordToUserName(PerformanceProfileScheduler: Record "Performance Profile Scheduler"): Text
    var
        User: Record User;
    begin
        if User.GET(PerformanceProfileScheduler."User ID") then;
        exit(User."User Name");
    end;

    procedure FilterUsers(var PerformanceProfileScheduler: Record "Performance Profile Scheduler"; SecurityID: Guid)
    var
        RecordRef: RecordRef;
    begin
        RecordRef.GetTable(PerformanceProfileScheduler);
        this.FilterUsers(RecordRef, SecurityID);
        RecordRef.SetTable(PerformanceProfileScheduler);
    end;

    procedure FilterUsers(var RecordRef: RecordRef; SecurityID: Guid)
    var
        UserPermissions: Codeunit "User Permissions";
        FilterView: Text;
        FilterTextTxt: Label 'where("User ID"=filter(''%1''))', locked = true;

    begin
        if UserPermissions.CanManageUsersOnTenant(SecurityID) then
            exit; // No need for additional user filters

        FilterView := StrSubstNo(FilterTextTxt, SecurityID);
        RecordRef.FilterGroup(2);
        RecordRef.SetView(FilterView);
        RecordRef.FilterGroup(0);
    end;

    procedure InitializeFields(var PerformanceProfileScheduler: Record "Performance Profile Scheduler"; var ActivityType: Enum "Perf. Profile Activity Type")
    begin
        PerformanceProfileScheduler.Init();
        PerformanceProfileScheduler."Schedule ID" := CreateGuid();
        PerformanceProfileScheduler."Starting Date-Time" := CurrentDateTime;
        PerformanceProfileScheduler.Enabled := true;
        PerformanceProfileScheduler."Profile Creation Threshold" := 500;
        PerformanceProfileScheduler.Frequency := PerformanceProfileScheduler.Frequency::"100 milliseconds";
        PerformanceProfileScheduler."Client Type" := PerformanceProfileScheduler."Client Type"::"Web Client";
        PerformanceProfileScheduler."User ID" := UserSecurityId();
        ActivityType := ActivityType::WebClient;
    end;

    procedure ValidatePerformanceProfileSchedulerDates(PerformanceProfileScheduler: Record "Performance Profile Scheduler")
    begin
        if ((PerformanceProfileScheduler."Ending Date-Time" <> 0DT) and (PerformanceProfileScheduler."Ending Date-Time" < CurrentDateTime())) then
            Error(ProfileCannotBeInThePastErr);

        if ((PerformanceProfileScheduler."Ending Date-Time" <> 0DT) and (PerformanceProfileScheduler."Starting Date-Time" > PerformanceProfileScheduler."Ending Date-Time")) then
            Error(ProfileStartingDateLessThenEndingDateErr);
    end;

    procedure ValidatePerformanceProfileScheduler(PerformanceProfileScheduler: Record "Performance Profile Scheduler"; ActivityType: Enum "Perf. Profile Activity Type")
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
        LocalPerformanceProfileScheduler.SetFilter("Client Type", '=%1', PerformanceProfileScheduler."Client Type");
        LocalPerformanceProfileScheduler.SetFilter("User ID", '=%1', PerformanceProfileScheduler."User ID");
        LocalPerformanceProfileScheduler.SetFilter("Schedule ID", '<>%1', PerformanceProfileScheduler."Schedule ID");
        LocalPerformanceProfileScheduler.SetFilter("Starting Date-Time", '<>%1', 0DT);
        LocalPerformanceProfileScheduler.SetFilter("Ending Date-Time", '<>%1', 0DT);

        if not LocalPerformanceProfileScheduler.FindSet() then
            exit;

        repeat
            if (Intersects(LocalPerformanceProfileScheduler, PerformanceProfileScheduler)) then
                Error(ProfileHasAlreadyBeenScheduledErr);

        until LocalPerformanceProfileScheduler.Next() = 0;

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

    procedure ValidateThreshold(var PerformanceProfileScheduler: Record "Performance Profile Scheduler")
    begin
        if (PerformanceProfileScheduler."Profile Creation Threshold" <= 0) then
            PerformanceProfileScheduler.Validate("Profile Creation Threshold", 500);
    end;

    local procedure Intersects(First: record "Performance Profile Scheduler"; Second: Record "Performance Profile Scheduler"): Boolean
    var
        startInterval1: DateTime;
        endInterval1: DateTime;
        startInterval2: DateTime;
        endInterval2: Datetime;
    begin
        startInterval1 := First."Starting Date-Time";
        endInterval1 := First."Ending Date-Time";
        startInterval2 := Second."Starting Date-Time";
        endInterval2 := Second."Ending Date-Time";

        if (((startInterval1 < endInterval1) and (endInterval1 <= startInterval2) and (startInterval2 < endInterval2)) or
            ((startInterval2 < endInterval2) and (endInterval2 <= startInterval1) and (startInterval1 < endInterval1))) then
            exit(false);

        exit(true);
    end;

    var
        ProfileStartingDateLessThenEndingDateErr: Label 'The performance profile starting date must be set before the ending date.';
        ProfileHasAlreadyBeenScheduledErr: Label 'Only one performance profile session can be scheduled for a given activity type for a given user for a given period.';
        ProfileCannotBeInThePastErr: Label 'A schedule cannot be set to run in the past.';
}