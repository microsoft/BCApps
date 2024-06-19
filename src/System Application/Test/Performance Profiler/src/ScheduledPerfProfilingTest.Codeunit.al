// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Tooling;

using System.PerformanceProfile;
using System.Security.AccessControl;
using System.TestLibraries.Utilities;
using System.Tooling;

codeunit 135019 "Scheduled Perf. Profiling Test"
{
    Subtype = Test;

    var
        Any: Codeunit Any;
        Assert: Codeunit "Library Assert";
        ScheduledPerfProfiler: Codeunit "Scheduled Perf. Profiler";
        ProfileStartingDateLessThenEndingDateErr: Label 'The performance profile starting date must be set before the ending date.';
        ProfileHasAlreadyBeenScheduledErr: Label 'Only one performance profile session can be scheduled for a given activity type for a given user for a given period.';

    [Test]
    procedure TestInitializedData()
    var
        TempPerformanceProfileScheduler: Record "Performance Profile Scheduler" temporary;
        ActivityType: Enum "Perf. Profile Activity Type";
    begin
        // [SCENARIO] The initial data shown on the "Perf. Profiler Schedules Card" card page is set up

        // [GIVEN] The initial data shown on the "Perf. Profiler Schedules Card" card page is set up
        ScheduledPerfProfiler.InitializeFields(TempPerformanceProfileScheduler, ActivityType);

        // [THEN] Expected initalization happens
        Assert.AreEqual(ActivityType, ActivityType::WebClient, 'Expected to be initialized to web client');
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
        TempPerformanceProfileScheduler.Init();
        this.SetupClientType(TempPerformanceProfileScheduler, TempPerformanceProfileScheduler."Client Type"::Background, ActivityType);

        // [THEN] we get the correct Activity value
        Assert.AreEqual(ActivityType::Background, ActivityType, StrSubstNo(ExpectedActivityTypeMsg, ActivityType::Background, ActivityType.AsInteger()));

        this.SetupClientType(TempPerformanceProfileScheduler, TempPerformanceProfileScheduler."Client Type"::"Web Client", ActivityType);
        Assert.AreEqual(ActivityType::WebClient, ActivityType, StrSubstNo(ExpectedActivityTypeMsg, ActivityType::WebClient, ActivityType.AsInteger()));

        this.SetupClientType(TempPerformanceProfileScheduler, TempPerformanceProfileScheduler."Client Type"::"Web Service", ActivityType);
        Assert.AreEqual(ActivityType::WebAPIClient, ActivityType, StrSubstNo(ExpectedActivityTypeMsg, ActivityType::WebAPIClient, ActivityType.AsInteger()));

        ActivityType := ActivityType::WebClient;
        this.SetupClientType(TempPerformanceProfileScheduler, 40, ActivityType);
        Assert.AreEqual(ActivityType::WebClient, ActivityType, StrSubstNo(ExpectedActivityTypeMsg, ActivityType::WebClient, ActivityType.AsInteger()));
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
        TempPerformanceProfileScheduler.Init();
        ScheduledPerfProfiler.MapActivityTypeToRecord(TempPerformanceProfileScheduler, ActivityType);

        // [THEN] we get a "Client Type on a Performance Profile Scheduler" record
        Assert.AreEqual(TempPerformanceProfileScheduler."Client Type"::"Web Client", TempPerformanceProfileScheduler."Client Type", StrSubstNo(ExpectedClientTypeMsg, TempPerformanceProfileScheduler."Client Type"::"Web Client", TempPerformanceProfileScheduler."Client Type"));

        ActivityType := ActivityType::Background;
        ScheduledPerfProfiler.MapActivityTypeToRecord(TempPerformanceProfileScheduler, ActivityType);
        Assert.AreEqual(TempPerformanceProfileScheduler."Client Type"::Background, TempPerformanceProfileScheduler."Client Type", StrSubstNo(ExpectedClientTypeMsg, TempPerformanceProfileScheduler."Client Type"::Background, TempPerformanceProfileScheduler."Client Type"));

        ActivityType := ActivityType::WebAPIClient;
        ScheduledPerfProfiler.MapActivityTypeToRecord(TempPerformanceProfileScheduler, ActivityType);
        Assert.AreEqual(TempPerformanceProfileScheduler."Client Type"::"Web Service", TempPerformanceProfileScheduler."Client Type", StrSubstNo(ExpectedClientTypeMsg, TempPerformanceProfileScheduler."Client Type"::"Web Service", TempPerformanceProfileScheduler."Client Type"));
    end;

    [Test]
    procedure TestValidatePerformanceProfileSchedulerDates()
    var
        TempPerformanceProfileScheduler: Record "Performance Profile Scheduler" temporary;
    begin
        // [SCENARIO] Validating that the starting date is less than the ending date

        // [GIVEN] a starting date is greater then an ending date
        TempPerformanceProfileScheduler.Init();
        TempPerformanceProfileScheduler."Starting Date-Time" := CurrentDateTime + 60000;

        // [THEN] we get the correct error messages
        TempPerformanceProfileScheduler."Ending Date-Time" := CurrentDateTime + 10000;
        asserterror ScheduledPerfProfiler.ValidatePerformanceProfileSchedulerDates(TempPerformanceProfileScheduler);
        Assert.ExpectedError(ProfileStartingDateLessThenEndingDateErr);
    end;

    [Test]
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

        // [THEN] it should not intersect with another.
        Clear(PerformanceProfileScheduler);
        ScheduledPerfProfiler.InitializeFields(PerformanceProfileScheduler, ActivityType);
        PerformanceProfileScheduler."Starting Date-Time" := EndingDateTime - 60000;
        PerformanceProfileScheduler."Ending Date-Time" := EndingDateTime;
        asserterror ScheduledPerfProfiler.ValidatePerformanceProfileSchedulerRecord(PerformanceProfileScheduler, ActivityType);
        Assert.ExpectedError(ProfileHasAlreadyBeenScheduledErr);
    end;

    [Test]
    procedure TestValidatePerformanceProfileSchedulerRecordWithNoStartingDate()
    var
        PerformanceProfileScheduler: Record "Performance Profile Scheduler";
        ActivityType: Enum "Perf. Profile Activity Type";
        EndingDateTime: DateTime;
    begin
        // [SCENARIO] Validating that a performance profile schedule record needs a starting date

        // [GIVEN] we have inserted a new performance profile record
        ScheduledPerfProfiler.InitializeFields(PerformanceProfileScheduler, ActivityType);
        EndingDateTime := PerformanceProfileScheduler."Starting Date-Time" + 15 * 60000;
        PerformanceProfileScheduler."Ending Date-Time" := EndingDateTime;
        PerformanceProfileScheduler.Insert(true);

        // [THEN] it should not intersect with another that has no ending date
        Clear(PerformanceProfileScheduler);
        ScheduledPerfProfiler.InitializeFields(PerformanceProfileScheduler, ActivityType);
        PerformanceProfileScheduler."Starting Date-Time" := 0DT;
        PerformanceProfileScheduler."Ending Date-Time" := EndingDateTime;
        ScheduledPerfProfiler.ValidatePerformanceProfileSchedulerRecord(PerformanceProfileScheduler, ActivityType);
    end;

    [Test]
    procedure TestValidatePerformanceProfileSchedulerRecordWithNoEndingDate()
    var
        PerformanceProfileScheduler: Record "Performance Profile Scheduler";
        ActivityType: Enum "Perf. Profile Activity Type";
        EndingDateTime: DateTime;
    begin
        // [SCENARIO] Validating that a performance profile schedule record needs an ending date

        // [GIVEN] we have inserted a new performance profile record that has no starting date.
        ScheduledPerfProfiler.InitializeFields(PerformanceProfileScheduler, ActivityType);
        EndingDateTime := PerformanceProfileScheduler."Starting Date-Time" + 15 * 60000;
        PerformanceProfileScheduler."Ending Date-Time" := EndingDateTime;
        PerformanceProfileScheduler.Insert(true);

        // [THEN] it should not intersect with another.
        Clear(PerformanceProfileScheduler);
        ScheduledPerfProfiler.InitializeFields(PerformanceProfileScheduler, ActivityType);
        PerformanceProfileScheduler."Ending Date-Time" := 0DT;
        ScheduledPerfProfiler.ValidatePerformanceProfileSchedulerRecord(PerformanceProfileScheduler, ActivityType);
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


        // [THEN] the scheduler page is showing values only for that user.
        TempUser.FindLast();
        Clear(TempPerformanceProfileScheduler);
        ScheduledPerfProfiler.FilterUsers(TempPerformanceProfileScheduler, TempUser."User Security ID");

        Assert.AreEqual(1, TempPerformanceProfileScheduler.Count(), 'Expected one filtered record');

        TempPerformanceProfileScheduler.FindFirst();
        Assert.AreEqual(TempUser."User Security ID", TempPerformanceProfileScheduler."User ID", 'Wrong user id mapped');

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