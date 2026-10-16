namespace Microsoft.Samples.BCLESnapshotDebugging;

codeunit 70953 "BCLE Profiling Failure"
{
    TableNo = "BCLE Profiling Setup";

    trigger OnRun()
    var
        Setup: Record "BCLE Profiling Setup";
    begin
        Setup.Get(Rec."Primary Key");
        Setup.Enabled := false;
        Setup.Phase := 'Failed';
        Setup."Active Session ID" := 0;
        Setup."Workload Session ID" := 0;
        Clear(Setup."Run Until");
        Clear(Setup."Task ID");
        Clear(Setup."Pass Task ID");
        Setup."Last Error" := 'The scheduled workload failed. Review the task scheduler and runtime telemetry.';
        Setup.Modify();
    end;
}
