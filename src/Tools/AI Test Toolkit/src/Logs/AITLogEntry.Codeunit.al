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

    procedure SetStatusStyleExpr(var AITLogEntry: Record "AIT Log Entry"; var StatusStyleExpr: Text)
    begin
        case AITLogEntry.Status of
            AITLogEntry.Status::Success:
                StatusStyleExpr := 'Favorable';
            AITLogEntry.Status::Error:
                StatusStyleExpr := 'Unfavorable';
            else
                StatusStyleExpr := '';
        end;
    end;

    procedure SetErrorFields(var AITLogEntry: Record "AIT Log Entry"; var ErrorMessage: Text; var ErrorCallStack: Text)
    begin
        ErrorMessage := '';
        ErrorCallStack := '';

        if AITLogEntry.Status = AITLogEntry.Status::Error then begin
            ErrorCallStack := AITLogEntry.GetErrorCallStack();
            ErrorMessage := AITLogEntry.GetMessage();
        end;
    end;
}