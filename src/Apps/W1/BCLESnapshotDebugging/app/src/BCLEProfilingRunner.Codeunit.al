namespace Microsoft.Samples.BCLESnapshotDebugging;

codeunit 70952 "BCLE Profiling Runner"
{
    TableNo = "BCLE Profiling Setup";

    trigger OnRun()
    var
        Setup: Record "BCLE Profiling Setup";
        NextTaskId: Guid;
    begin
        Setup.Get(Rec."Primary Key");
        if not Setup.Enabled then
            exit;

        Setup."Active Session ID" := SessionId();
        Setup.Phase := 'Starting background session';
        Setup."Progress %" := 0;
        Setup."Processed Rows" := 0;
        Setup."Total Rows" := Setup."Rows to Seed";
        Setup."Workload Session ID" := SessionId();
        Setup.Modify();
        Commit();
        Session.LogMessage(
            'BCLE001',
            StrSubstNo('BCLE profiling background session %1 started.', SessionId()),
            Verbosity::Normal,
            DataClassification::SystemMetadata,
            TelemetryScope::ExtensionPublisher,
            'serverSessionId',
            Format(SessionId()),
            'clientType',
            'Background');

        Codeunit.Run(Codeunit::"BCLE Profiling Pass", Setup);

        Setup.Get(Rec."Primary Key");
        while Setup.Enabled and (CurrentDateTime() < Setup."Run Until") do begin
            Sleep(Setup."Interval (ms)");
            Setup.Get(Rec."Primary Key");
            if not Setup.Enabled then
                break;

            NextTaskId := TaskScheduler.CreateTask(
                Codeunit::"BCLE Profiling Pass",
                Codeunit::"BCLE Profiling Failure",
                true,
                CompanyName(),
                CurrentDateTime() + 1000,
                Setup.RecordId(),
                40 * 60 * 1000);
            Setup."Pass Task ID" := NextTaskId;
            Setup.Phase := 'Waiting for next background pass';
            Setup.Modify();
            Commit();

            repeat
                Sleep(1000);
                Setup.Get(Rec."Primary Key");
            until (not Setup.Enabled) or IsNullGuid(Setup."Pass Task ID");
        end;

        Setup.Get(Rec."Primary Key");
        if Setup.Enabled then begin
            Setup.Enabled := false;
            Setup.Phase := 'Completed';
            Clear(Setup."Run Until");
        end;
        Setup."Active Session ID" := 0;
        Setup."Workload Session ID" := 0;
        Clear(Setup."Task ID");
        Clear(Setup."Pass Task ID");
        Setup.Modify();
    end;
}
