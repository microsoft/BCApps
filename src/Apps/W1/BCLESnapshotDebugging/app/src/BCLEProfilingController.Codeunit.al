namespace Microsoft.Samples.BCLESnapshotDebugging;

codeunit 70951 "BCLE Profiling Controller"
{
    procedure EnsureSetup(var Setup: Record "BCLE Profiling Setup")
    var
        SetupChanged: Boolean;
    begin
        if Setup.Get('SETUP') then begin
            if Setup."Rows to Seed" < 10000 then begin
                Setup."Rows to Seed" := 10000;
                SetupChanged := true;
            end;
            if Setup."Maximum Runtime" < 30 * 60 * 1000 then begin
                Setup."Maximum Runtime" := 30 * 60 * 1000;
                SetupChanged := true;
            end;
            if SetupChanged then
                Setup.Modify();
            exit;
        end;

        Setup.Init();
        Setup."Primary Key" := 'SETUP';
        Setup."Interval (ms)" := 10000;
        Setup."Rows to Seed" := 10000;
        Setup."Maximum Runtime" := 30 * 60 * 1000;
        Setup.Insert();
    end;

    procedure SeedWorkload()
    var
        Setup: Record "BCLE Profiling Setup";
        Workload: Codeunit "BCLE Heavy SQL Workload";
    begin
        EnsureSetup(Setup);
        Workload.Seed(Setup."Rows to Seed", Setup);
    end;

    procedure RunOnce()
    var
        Setup: Record "BCLE Profiling Setup";
        Workload: Codeunit "BCLE Heavy SQL Workload";
        Result: BigInteger;
        StartedAt: DateTime;
    begin
        EnsureSetup(Setup);
        StartedAt := CurrentDateTime();
        Setup."Last Started At" := StartedAt;
        Setup.Modify();
        Commit();

        Result := Workload.Run(Setup."Rows to Seed", Setup);
        Setup.Get('SETUP');
        Setup."Last Result" := Result;
        Setup."Last Completed At" := CurrentDateTime();
        Setup."Last Duration" := Setup."Last Completed At" - StartedAt;
        Setup."Run Count" += 1;
        Setup.Modify();
    end;

    procedure Start()
    var
        Setup: Record "BCLE Profiling Setup";
    begin
        EnsureSetup(Setup);
        if Setup.Enabled then
            Error('The BCLE profiling workload is already enabled.');

        Setup.Enabled := true;
        Setup."Last Error" := '';
        Setup.Phase := 'Scheduled';
        Setup."Progress %" := 0;
        Setup."Processed Rows" := 0;
        Setup."Total Rows" := Setup."Rows to Seed";
        Setup."Active Session ID" := 0;
        Setup."Workload Session ID" := 0;
        Setup."Run Until" := CurrentDateTime() + Setup."Maximum Runtime";
        Clear(Setup."Task ID");
        Clear(Setup."Pass Task ID");
        Setup.Modify();
        Commit();

        Setup."Task ID" := TaskScheduler.CreateTask(
            Codeunit::"BCLE Profiling Runner",
            Codeunit::"BCLE Profiling Failure",
            true,
            CompanyName(),
            CurrentDateTime() + 1000,
            Setup.RecordId(),
            40 * 60 * 1000);
        Setup.Modify();
    end;

    procedure Stop()
    var
        Setup: Record "BCLE Profiling Setup";
        PassTaskId: Guid;
        TaskId: Guid;
    begin
        EnsureSetup(Setup);
        TaskId := Setup."Task ID";
        PassTaskId := Setup."Pass Task ID";
        Setup.Enabled := false;
        Setup.Phase := 'Stopped';
        Setup."Progress %" := 0;
        Setup."Active Session ID" := 0;
        Setup."Workload Session ID" := 0;
        Clear(Setup."Run Until");
        Clear(Setup."Task ID");
        Clear(Setup."Pass Task ID");
        Setup.Modify();
        Commit();

        if (not IsNullGuid(TaskId)) and TaskScheduler.TaskExists(TaskId) then
            TaskScheduler.CancelTask(TaskId);
        if (not IsNullGuid(PassTaskId)) and TaskScheduler.TaskExists(PassTaskId) then
            TaskScheduler.CancelTask(PassTaskId);
    end;
}
