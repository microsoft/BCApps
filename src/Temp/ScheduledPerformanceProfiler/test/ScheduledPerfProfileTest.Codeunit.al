namespace System.Tooling;
using System.PerformanceProfile;
using System.Security.AccessControl;
using System.TestLibraries.Utilities;

codeunit 135018 "Scheduled Perf. Profiling Test"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    var
        Assert: Codeunit "Library Assert";

        NoRecordingErr: Label 'There is no performance profiling data.';

    [Test]
    procedure TestInitializedData()
    begin
        // [WHEN] Test the initial data shown on the "Perf. Profiler Schedules Card" card page
        asserterror //SamplingPerformanceProfiler.GetData();

        // [THEN] The no data error is thrown.
        Assert.ExpectedError(NoRecordingErr);
    end;

    var
        ScheduledPerfProfiler: Codeunit "Scheduled Perf Profiler";
}