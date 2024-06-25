// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Tooling;

using System.DataAdministration;
using System.PerformanceProfile;
using System.Security.AccessControl;
using System.TestLibraries.Utilities;
using System.Tooling;

codeunit 135019 "Scheduled Perf. Profiling Test"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;
    Permissions = tabledata "Performance Profile Scheduler" = RIMD, tabledata User = RIMD;

    var
        Any: Codeunit Any;
        Assert: Codeunit "Library Assert";
        ScheduledPerfProfiler: Codeunit "Scheduled Perf. Profiler";
        ProfileStartingDateLessThenEndingDateErr: Label 'The performance profile starting date must be set before the ending date.';
        ProfileHasAlreadyBeenScheduledErr: Label 'Only one performance profile session can be scheduled for a given activity type for a given user for a given period.';
        ScheduleDurationCannotExceedRetentionPeriodErr: Label 'The performance profile schedule duration cannot exceed the retention period.';
        ProfileCannotBeInThePastErr: Label 'A schedule cannot be set to run in the past.';

    [Test]
    procedure TestInitializedData()
    var
        TempPerformanceProfileScheduler: Record "Performance Profile Scheduler" temporary;
        ActivityType: Enum "Perf. Profile Activity Type";
    begin
        // [SCENARIO] The initial data shown on the "Perf. Profiler Schedules Card" card page is set up

        // [WHEN] The initial data shown on the "Perf. Profiler Schedules Card" card page is set up
        ScheduledPerfProfiler.InitializeFields(TempPerformanceProfileScheduler, ActivityType);

        // [THEN] Expected initalization happens
        Assert.AreEqual(ActivityType, ActivityType::"Web Client", 'Expected to be initialized to web client');
        Assert.IsTrue(TempPerformanceProfileScheduler."Profile Creation Threshold" = 500, 'The default profile creation threshold is 500 ms.');
        Assert.AreEqual(TempPerformanceProfileScheduler.Frequency, TempPerformanceProfileScheduler.Frequency::"100 milliseconds", 'The default frequency should be 100 ms.');
        Assert.IsTrue(TempPerformanceProfileScheduler.Enabled, 'The scheduled sampling profile record should be enabled.');
        Assert.IsFalse(IsNullGuid(TempPerformanceProfileScheduler."Schedule ID"), 'The scheduled sampling profile record should have been created a non zero guid.');
        Assert.AreEqual(TempPerformanceProfileScheduler."User ID", UserSecurityId(), 'The scheduled sampling profile record should have been initialized with the user associated to the session.');
    end;

    [Test]
    procedure TestMapRecordToActivityType()
    var
        TempPerformanceProfileScheduler: Record "Performance Profile Scheduler" temporary;
        ExpectedActivityTypeMsg: Label 'Expected %1 actvity type. Actual type %2:', Locked = true;
        ActivityType: Enum "Perf. Profile Activity Type";
    begin
        // [SCENARIO] Mapping a record to an activity type

        // [GIVEN] a web client session type is used
        // [WHEN] we map the record to an activity type
        TempPerformanceProfileScheduler.Init();
        this.SetupClientType(TempPerformanceProfileScheduler, TempPerformanceProfileScheduler."Client Type"::Background, ActivityType);

        // [THEN] we get the correct Activity value
        Assert.AreEqual(ActivityType::Background, ActivityType, StrSubstNo(ExpectedActivityTypeMsg, ActivityType::Background, ActivityType.AsInteger()));

        this.SetupClientType(TempPerformanceProfileScheduler, TempPerformanceProfileScheduler."Client Type"::"Web Client", ActivityType);
        Assert.AreEqual(ActivityType::"Web Client", ActivityType, StrSubstNo(ExpectedActivityTypeMsg, ActivityType::"Web Client", ActivityType.AsInteger()));

        this.SetupClientType(TempPerformanceProfileScheduler, TempPerformanceProfileScheduler."Client Type"::"Web Service", ActivityType);
        Assert.AreEqual(ActivityType::"Web API Client", ActivityType, StrSubstNo(ExpectedActivityTypeMsg, ActivityType::"Web API Client", ActivityType.AsInteger()));

        ActivityType := ActivityType::"Web Client";
        this.SetupClientType(TempPerformanceProfileScheduler, 40, ActivityType);
        Assert.AreEqual(ActivityType::"Web Client", ActivityType, StrSubstNo(ExpectedActivityTypeMsg, ActivityType::"Web Client", ActivityType.AsInteger()));
    end;

    [Test]
    procedure TestMapActivityTypeToRecord()
    var
        TempPerformanceProfileScheduler: Record "Performance Profile Scheduler" temporary;
        ExpectedClientTypeMsg: Label 'Expected %1 client type. Actual type %2:', Locked = true;
        ActivityType: Enum "Perf. Profile Activity Type";
    begin
        // [SCENARIO] Mapping an activity type to a record

        // [GIVEN] an activity enum is used
        // [WHEN] we map the activity type to a record
        TempPerformanceProfileScheduler.Init();
        ScheduledPerfProfiler.MapActivityTypeToRecord(TempPerformanceProfileScheduler, ActivityType);

        // [THEN] we get a "Client Type on a Performance Profile Scheduler" record
        Assert.AreEqual(TempPerformanceProfileScheduler."Client Type"::"Web Client", TempPerformanceProfileScheduler."Client Type", StrSubstNo(ExpectedClientTypeMsg, TempPerformanceProfileScheduler."Client Type"::"Web Client", TempPerformanceProfileScheduler."Client Type"));

        ActivityType := ActivityType::Background;
        ScheduledPerfProfiler.MapActivityTypeToRecord(TempPerformanceProfileScheduler, ActivityType);
        Assert.AreEqual(TempPerformanceProfileScheduler."Client Type"::Background, TempPerformanceProfileScheduler."Client Type", StrSubstNo(ExpectedClientTypeMsg, TempPerformanceProfileScheduler."Client Type"::Background, TempPerformanceProfileScheduler."Client Type"));

        ActivityType := ActivityType::"Web API Client";
        ScheduledPerfProfiler.MapActivityTypeToRecord(TempPerformanceProfileScheduler, ActivityType);
        Assert.AreEqual(TempPerformanceProfileScheduler."Client Type"::"Web Service", TempPerformanceProfileScheduler."Client Type", StrSubstNo(ExpectedClientTypeMsg, TempPerformanceProfileScheduler."Client Type"::"Web Service", TempPerformanceProfileScheduler."Client Type"));
    end;

    [Test]
    procedure TestValidatePerformanceProfileSchedulerDates()
    var
        TempPerformanceProfileScheduler: Record "Performance Profile Scheduler" temporary;
    begin
        // [SCENARIO] Validating that the starting date is less than the ending date

        // [WHEN] A starting date is set to be greater then an ending date
        TempPerformanceProfileScheduler.Init();
        TempPerformanceProfileScheduler."Starting Date-Time" := CurrentDateTime + 60000;

        // [THEN] we get the correct error messages
        TempPerformanceProfileScheduler."Ending Date-Time" := CurrentDateTime + 10000;
        asserterror ScheduledPerfProfiler.ValidatePerformanceProfileSchedulerDates(TempPerformanceProfileScheduler, 0);
        Assert.ExpectedError(ProfileStartingDateLessThenEndingDateErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestValidatePerformanceProfileSchedulerRecord()
    var
        PerformanceProfileScheduler: Record "Performance Profile Scheduler";
        ActivityType: Enum "Perf. Profile Activity Type";
        EndingDateTime: DateTime;
    begin
        // [SCENARIO] Validating that we cannot create intersecting performance profile schedule records

        // [GIVEN] we have inserted a new performance profile record
        ScheduledPerfProfiler.InitializeFields(PerformanceProfileScheduler, ActivityType);
        EndingDateTime := PerformanceProfileScheduler."Starting Date-Time" + 15 * 60000;
        PerformanceProfileScheduler."Ending Date-Time" := EndingDateTime;
        PerformanceProfileScheduler.Insert(true);

        Clear(PerformanceProfileScheduler);
        // [WHEN] we try to create a new record that intersects with the previous one
        ScheduledPerfProfiler.InitializeFields(PerformanceProfileScheduler, ActivityType);
        PerformanceProfileScheduler."Starting Date-Time" := EndingDateTime - 60000;
        PerformanceProfileScheduler."Ending Date-Time" := EndingDateTime;

        // [THEN] we get an appropriate error message.
        asserterror ScheduledPerfProfiler.ValidatePerformanceProfileSchedulerRecord(PerformanceProfileScheduler, ActivityType);
        Assert.ExpectedError(ProfileHasAlreadyBeenScheduledErr);
    end;

    [Test]
    procedure TestValidatePerformanceProfileSchedulerRecordWithStartingDateInThePast()
    var
        TempPerformanceProfileScheduler: Record "Performance Profile Scheduler" temporary;
        ActivityType: Enum "Perf. Profile Activity Type";
    begin
        // [SCENARIO] Validating that a performance profile schedule record needs a starting date that is not in the past

        // [WHEN] We create a profile schedule record with a starting date in the past
        ScheduledPerfProfiler.InitializeFields(TempPerformanceProfileScheduler, ActivityType);
        TempPerformanceProfileScheduler."Ending Date-Time" := CurrentDateTime - 60000;

        // [THEN] we get an appropriate error message.
        asserterror ScheduledPerfProfiler.ValidatePerformanceProfileSchedulerDates(TempPerformanceProfileScheduler, 0);
        Assert.ExpectedError(ProfileCannotBeInThePastErr);
    end;

    [Test]
    procedure TestValidatePerformanceProfileSchedulerRecordWithDurationLargerThanRetentionPeriod()
    var
        TempPerformanceProfileScheduler: Record "Performance Profile Scheduler" temporary;
        ActivityType: Enum "Perf. Profile Activity Type";
        EndingDateTime: DateTime;
        OneWeek: Duration;
        OneWeekPlusOneDay: Duration;
    begin
        // [SCENARIO] Validating that a performance profile schedule record cannot have a duration larger than the retention period.

        // [WHEN] We try to validate a record with a duration larger than the retention period
        ScheduledPerfProfiler.InitializeFields(TempPerformanceProfileScheduler, ActivityType);
        OneWeek := 24 * 60 * 60 * 1000 * 7;
        OneWeekPlusOneDay := OneWeek + 24 * 60 * 60 * 1000;
        EndingDateTime := TempPerformanceProfileScheduler."Starting Date-Time" + OneWeekPlusOneDay;
        TempPerformanceProfileScheduler."Ending Date-Time" := EndingDateTime;

        // [THEN] we get an appropriate error message.
        asserterror ScheduledPerfProfiler.ValidatePerformanceProfileSchedulerDates(TempPerformanceProfileScheduler, OneWeek);
        Assert.ExpectedError(ScheduleDurationCannotExceedRetentionPeriodErr);
    end;

    [Test]
    procedure TestUserFilter()
    var
        TempPerformanceProfileScheduler: Record "Performance Profile Scheduler" temporary;
        TempUser: Record User temporary;
        ActivityType: Enum "Perf. Profile Activity Type";
    begin
        // [SCENARIO] The schedules page shows values for the user that is currently logged in by default

        // [GIVEN] we have a user that is just a default user 
        this.AddTwoUsers(TempUser);

        TempUser.FindSet();
        repeat
            ScheduledPerfProfiler.InitializeFields(TempPerformanceProfileScheduler, ActivityType);
            TempPerformanceProfileScheduler."User ID" := TempUser."User Security ID";
            TempPerformanceProfileScheduler.Insert(true);
        until TempUser.Next() = 0;


        TempUser.FindLast();
        Clear(TempPerformanceProfileScheduler);
        // [WHEN] we filter the records for the user
        ScheduledPerfProfiler.FilterUsers(TempPerformanceProfileScheduler, TempUser."User Security ID", true);

        // [THEN] the scheduler page is showing values only for that user.
        Assert.AreEqual(1, TempPerformanceProfileScheduler.Count(), 'Expected one filtered record');

        TempPerformanceProfileScheduler.FindFirst();
        Assert.AreEqual(TempUser."User Security ID", TempPerformanceProfileScheduler."User ID", 'Wrong user id mapped');

    end;

    [Test]
    procedure TestRetentionPolicy()
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
        RetenPolAllowedTables: Codeunit "Reten. Pol. Allowed Tables";
    begin
        // [SCENARIO] A retention policy is created when the app is installed

        // [THEN] Performance profile scheduler table is allowed and set up in the retention policy
        Assert.IsTrue(RetenPolAllowedTables.IsAllowedTable(Database::"Performance Profile Scheduler"), 'Performance profile scheduler table should be allowed in retention policy');

        RetentionPolicySetup.Get(Database::"Performance Profile Scheduler");
        Assert.IsTrue(RetentionPolicySetup.Enabled, 'Performance profile scheduler table should have a retention policy enabled');
    end;

    local procedure SetupClientType(var PerformanceProfileScheduler: Record "Performance Profile Scheduler"; ClientType: Option; var ActivityType: Enum "Perf. Profile Activity Type")
    begin
        PerformanceProfileScheduler."Client Type" := ClientType;
        ScheduledPerfProfiler.MapRecordToActivityType(PerformanceProfileScheduler, ActivityType);
    end;

    local procedure AddTwoUsers(var TempUser: Record User temporary)
    var
        I: Integer;
    begin

        for I := 0 to 2 do begin
            TempUser."User Security ID" := CreateGuid();
            TempUser."User Name" := CopyStr(Any.AlphanumericText(50), 1, 10);
            TempUser.Insert();
        end;
    end;
}
