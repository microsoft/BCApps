// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;
using System.PerformanceProfile;
using System.TestLibraries.Utilities;


codeunit 135018 "Scheduled Perf Profiling Test"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    var
        Assert: Codeunit "Library Assert";

    [Test]
    procedure TestInitializedData()
    var
        TempPerformanceProfileScheduler: record "Performance Profile Scheduler" temporary;
        ActivityType: enum ActivityType;
    begin
        // [WHEN] Test the initial data shown on the "Perf. Profiler Schedules Card" card page
        ScheduledPerfProfiler.InitializeFields(TempPerformanceProfileScheduler, ActivityType);

        // [THEN] Expected initalization happens
        Assert.IsTrue(ActivityType = ActivityType::WebClient, 'Expected to be initialized to web client');
        Assert.IsTrue(TempPerformanceProfileScheduler."Profile Keep Time" = 7, 'The default profile keep time is 7 days');
        Assert.IsTrue(TempPerformanceProfileScheduler."Profile Creation Threshold" = 500, 'The default profile creation threshold is 500 ms.');
    end;

    var
        ScheduledPerfProfiler: Codeunit "Scheduled Perf Profiler";
}