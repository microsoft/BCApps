// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

codeunit 149032 "AIT Log Entry"
{
    Access = Internal;

    procedure DrillDownFailedAITLogEntries(AITSuiteCode: Code[100]; LineNo: Integer; VersionNo: Integer)
    var
        AITLogEntries: Record "AIT Log Entry";
    begin
        AITLogEntries.SetRange(Version, VersionNo);
        DrillDownFailedAITLogEntries(AITLogEntries, AITSuiteCode, LineNo);
    end;

    procedure DrillDownFailedAITLogEntries(AITSuiteCode: Code[100]; LineNo: Integer; Tag: Text[20])
    var
        AITLogEntries: Record "AIT Log Entry";
    begin
        AITLogEntries.SetRange(Tag, Tag);
        DrillDownFailedAITLogEntries(AITLogEntries, AITSuiteCode, LineNo);
    end;

    local procedure DrillDownFailedAITLogEntries(var AITLogEntries: Record "AIT Log Entry"; AITSuiteCode: Code[100]; LineNo: Integer)
    var
        AITLogEntry: Page "AIT Log Entries";
    begin
        AITLogEntries.SetFilterForFailedTestProcedures();
        AITLogEntries.SetRange("Test Suite Code", AITSuiteCode);
        if LineNo <> 0 then
            AITLogEntries.SetRange("Test Method Line No.", LineNo);
        AITLogEntry.SetTableView(AITLogEntries);
        AITLogEntry.Run();
    end;
}