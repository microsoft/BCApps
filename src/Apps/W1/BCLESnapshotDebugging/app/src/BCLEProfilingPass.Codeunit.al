namespace Microsoft.Samples.BCLESnapshotDebugging;

codeunit 70954 "BCLE Profiling Pass"
{
    TableNo = "BCLE Profiling Setup";

    trigger OnRun()
    var
        Setup: Record "BCLE Profiling Setup";
        Workload: Codeunit "BCLE Heavy SQL Workload";
        StartedAt: DateTime;
        Result: BigInteger;
    begin
        Setup.Get(Rec."Primary Key");
        if not Setup.Enabled then begin
            Clear(Setup."Pass Task ID");
            Setup.Modify();
            exit;
        end;

        Setup."Workload Session ID" := SessionId();
        StartedAt := CurrentDateTime();
        Setup."Last Started At" := StartedAt;
        Setup.Phase := 'Preparing workload pass';
        Setup."Progress %" := 0;
        Setup."Processed Rows" := 0;
        Setup.Modify();
        Commit();

        Result := Workload.Run(Setup."Rows to Seed", Setup);

        Setup.Get(Rec."Primary Key");
        Setup."Last Result" := Result;
        Setup."Last Completed At" := CurrentDateTime();
        Setup."Last Duration" := Setup."Last Completed At" - StartedAt;
        Setup."Run Count" += 1;
        Setup."Progress %" := 100;
        Setup."Workload Session ID" := 0;
        Clear(Setup."Pass Task ID");
        if Setup.Enabled then
            Setup.Phase := 'Waiting for next background pass';
        Setup.Modify();
    end;
}
