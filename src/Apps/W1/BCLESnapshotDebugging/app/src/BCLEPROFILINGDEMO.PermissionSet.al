namespace Microsoft.Samples.BCLESnapshotDebugging;

permissionset 70950 "BCLE PROFILING DEMO"
{
    Assignable = true;
    Caption = 'BCLE Profiling Demo';

    Permissions =
        table "BCLE Profiling Buffer" = X,
        tabledata "BCLE Profiling Buffer" = RIMD,
        table "BCLE Profiling Setup" = X,
        tabledata "BCLE Profiling Setup" = RIMD,
        codeunit "BCLE Heavy SQL Workload" = X,
        codeunit "BCLE Profiling Controller" = X,
        codeunit "BCLE Profiling Runner" = X,
        codeunit "BCLE Profiling Pass" = X,
        codeunit "BCLE Profiling Failure" = X,
        page "BCLE Profiling Demo" = X,
        query "BCLE Heavy SQL Join" = X;
}
