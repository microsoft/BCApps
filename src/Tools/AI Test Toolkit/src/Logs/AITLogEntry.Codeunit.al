codeunit 149032 "AIT Log Entry"
{

    Access = Internal;

    procedure DrillDownFailedAITLogEntries(AITSuiteCode: Code[100]; LineNo: Integer; VersionNo: Integer)
    var
        AITLogEntries: Record "AIT Log Entry";
        AITLogEntry: Page "AIT Log Entries";
    begin
        AITLogEntries.SetFilterForFailedTestProcedures();
        AITLogEntries.SetRange("Test Suite Code", AITSuiteCode);
        AITLogEntries.SetRange(Version, VersionNo);
        if LineNo <> 0 then
            AITLogEntries.SetRange("Test Method Line No.", LineNo);
        AITLogEntry.SetTableView(AITLogEntries);
        AITLogEntry.Run();
    end;
}