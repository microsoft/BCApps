// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.Reflection;

codeunit 149035 "BCCT Line"
{
    Access = Internal;

    var
        BCCTHeader: Record "BCCT Header";
        ScenarioStarted: Dictionary of [Text, DateTime];
        ScenarioOutput: Dictionary of [Text, Text];
        ScenarioNotStartedErr: Label 'Scenario %1 in codeunit %2 was not started.', Comment = '%1 = method name, %2 = codeunit name';

    [EventSubscriber(ObjectType::Table, Database::"BCCT Line", OnBeforeInsertEvent, '', false, false)]
    local procedure SetNoOfSessionsOnBeforeInsertBCCTLine(var Rec: Record "BCCT Line"; RunTrigger: Boolean)
    var
        BCCTLine: Record "BCCT Line";
    begin
        if Rec.IsTemporary() then
            exit;

        if Rec."Line No." = 0 then begin
            BCCTLine.SetAscending("Line No.", true);
            BCCTLine.SetRange("BCCT Code", Rec."BCCT Code");
            if BCCTLine.FindLast() then;
            Rec."Line No." := BCCTLine."Line No." + 1000;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"BCCT Line", OnBeforeDeleteEvent, '', false, false)]
    local procedure DeleteLogEntriesOnDeleteBCCTLine(var Rec: Record "BCCT Line"; RunTrigger: Boolean)
    var
        BCCTLogEntry: Record "BCCT Log Entry";
    begin
        if Rec.IsTemporary() then
            exit;

        BCCTLogEntry.SetRange("BCCT Code", Rec."BCCT Code");
        BCCTLogEntry.SetRange("BCCT Line No.", Rec."Line No.");
        BCCTLogEntry.DeleteAll(true);
    end;

    [EventSubscriber(ObjectType::Page, Page::"BCCT Lines", OnInsertRecordEvent, '', false, false)]
    local procedure OnInsertRecordEvent(var Rec: Record "BCCT Line"; BelowxRec: Boolean; var xRec: Record "BCCT Line"; var AllowInsert: Boolean)
    begin
        if Rec."BCCT Code" = '' then begin
            AllowInsert := false;
            exit;
        end;

        if Rec."Min. User Delay (ms)" = 0 then
            Rec."Min. User Delay (ms)" := this.BCCTHeader."Default Min. User Delay (ms)";
        if Rec."Max. User Delay (ms)" = 0 then
            Rec."Max. User Delay (ms)" := this.BCCTHeader."Default Max. User Delay (ms)";

        if Rec."BCCT Code" <> this.BCCTHeader.Code then
            if this.BCCTHeader.Get(Rec."BCCT Code") then;
    end;

    procedure Indent(var BCCTLine: Record "BCCT Line")
    var
        ParentBCCTLine: Record "BCCT Line";
    begin
        if BCCTLine.Indentation > 0 then
            exit;
        ParentBCCTLine := BCCTLine;
        ParentBCCTLine.SetRange(Sequence, BCCTLine.Sequence);
        ParentBCCTLine.SetRange(Indentation, 0);
        if ParentBCCTLine.IsEmpty() then
            exit;
        BCCTLine.Indentation := 1;
        BCCTLine.Modify(true);
    end;

    procedure Outdent(var BCCTLine: Record "BCCT Line")
    begin
        if BCCTLine.Indentation = 0 then
            exit;
        BCCTLine.Indentation := 0;
        BCCTLine.Modify(true);
    end;

    procedure StartScenario(ScenarioOperation: Text)
    var
        OldStartTime: DateTime;
    begin
        if this.ScenarioStarted.Get(ScenarioOperation, OldStartTime) then
            this.ScenarioStarted.Set(ScenarioOperation, CurrentDateTime())
        else
            this.ScenarioStarted.Add(ScenarioOperation, CurrentDateTime());
    end;

    procedure EndScenario(BCCTLine: Record "BCCT Line"; ScenarioOperation: Text; BCCTDatasetLine: Record "BCCT Dataset Line") //TODO: seems to be dead code. Remove?
    begin
        if not this.ScenarioStarted.ContainsKey(ScenarioOperation) then
            error(this.ScenarioNotStartedErr, ScenarioOperation, BCCTLine."Codeunit Name");
        this.EndScenario(BCCTLine, ScenarioOperation, '', true, BCCTDatasetLine);
    end;

    internal procedure EndScenario(BCCTLine: Record "BCCT Line"; ScenarioOperation: Text; ProcedureName: Text[128]; ExecutionSuccess: Boolean; BCCTDatasetLine: Record "BCCT Dataset Line")
    var
        ErrorMessage: Text;
        StartTime: DateTime;
        EndTime: DateTime;
    begin
        EndTime := CurrentDateTime();
        if not ExecutionSuccess then
            ErrorMessage := CopyStr(GetLastErrorText(), 1, MaxStrLen(ErrorMessage));
        if this.ScenarioStarted.Get(ScenarioOperation, StartTime) then
            if this.ScenarioStarted.Remove(ScenarioOperation) then;

        this.AddLogEntry(BCCTLine, ScenarioOperation, ProcedureName, ExecutionSuccess, ErrorMessage, StartTime, EndTime, BCCTDatasetLine);
    end;

    local procedure AddLogEntry(var BCCTLine: Record "BCCT Line"; Operation: Text; ProcedureName: Text[128]; ExecutionSuccess: Boolean; Message: Text; StartTime: DateTime; EndTime: Datetime; BCCTDatasetLine: Record "BCCT Dataset Line")
    var
        BCCTLogEntry: Record "BCCT Log Entry";
        AITTestRunnerImpl: Codeunit "AIT Test Runner"; // single instance
        BCCTTestSuite: Codeunit "BCCT Test Suite";
        ModifiedOperation: Text;
        ModifiedExecutionSuccess: Boolean;
        ModifiedMessage: Text;
        TestOutput: Text;
        EntryWasModified: Boolean;
    begin
        // Skip the OnRun entry if not implemented
        if (Operation = AITTestRunnerImpl.GetDefaultRunProcedureOperationLbl()) and (ProcedureName = 'OnRun') and (ExecutionSuccess = true) and (Message = '') then
            exit;

        ModifiedOperation := Operation;
        ModifiedExecutionSuccess := ExecutionSuccess;
        ModifiedMessage := Message;
        BCCTTestSuite.OnBeforeBCCTLineAddLogEntry(BCCTLine."BCCT Code", BCCTLine."Codeunit ID", BCCTLine.Description, Operation, ExecutionSuccess, Message, ModifiedOperation, ModifiedExecutionSuccess, ModifiedMessage);
        if (Operation <> ModifiedOperation) or (ExecutionSuccess <> ModifiedExecutionSuccess) or (Message <> ModifiedMessage) then
            EntryWasModified := true;

        BCCTLine.Testfield("BCCT Code");
        AITTestRunnerImpl.GetBCCTHeader(this.BCCTHeader);
        Clear(BCCTLogEntry);
        BCCTLogEntry.RunID := this.BCCTHeader.RunID;
        BCCTLogEntry."BCCT Code" := BCCTLine."BCCT Code";
        BCCTLogEntry."BCCT Line No." := BCCTLine."Line No.";
        BCCTLogEntry.Version := this.BCCTHeader.Version;
        BCCTLogEntry."Codeunit ID" := BCCTLine."Codeunit ID";
        BCCTLogEntry.Operation := CopyStr(ModifiedOperation, 1, MaxStrLen(BCCTLogEntry.Operation));
        BCCTLogEntry."Orig. Operation" := CopyStr(Operation, 1, MaxStrLen(BCCTLogEntry."Orig. Operation"));
        BCCTLogEntry.Tag := AITTestRunnerImpl.GetBCCTHeaderTag();
        BCCTLogEntry."Entry No." := 0;
        if ModifiedExecutionSuccess then
            BCCTLogEntry.Status := BCCTLogEntry.Status::Success
        else begin
            BCCTLogEntry.Status := BCCTLogEntry.Status::Error;
            BCCTLogEntry."Error Call Stack" := CopyStr(GetLastErrorCallStack, 1, MaxStrLen(BCCTLogEntry."Error Call Stack"));
        end;
        if ExecutionSuccess then
            BCCTLogEntry."Orig. Status" := BCCTLogEntry.Status::Success
        else
            BCCTLogEntry."Orig. Status" := BCCTLogEntry.Status::Error;
        BCCTLogEntry.Message := CopyStr(ModifiedMessage, 1, MaxStrLen(BCCTLogEntry.Message));
        BCCTLogEntry."Orig. Message" := CopyStr(Message, 1, MaxStrLen(BCCTLogEntry."Orig. Message"));
        BCCTLogEntry."Log was Modified" := EntryWasModified;
        BCCTLogEntry."End Time" := EndTime;
        BCCTLogEntry."Start Time" := StartTime;
        if BCCTLogEntry."Start Time" = 0DT then
            BCCTLogEntry."Duration (ms)" := BCCTLogEntry."End Time" - BCCTLogEntry."Start Time";

        BCCTLogEntry.Dataset := BCCTDatasetLine."Dataset Name";
        BCCTLogEntry."Dataset Line No." := BCCTDatasetLine.Id;
        BCCTDatasetLine.CalcFields("Input Blob");
        BCCTLogEntry."Input Data" := BCCTDatasetLine."Input Blob";
        TestOutput := this.GetTestOutput(Operation);
        if TestOutput <> '' then
            BCCTLogEntry.SetOutputBlob(TestOutput);
        BCCTLogEntry."Procedure Name" := ProcedureName;
        if Operation = AITTestRunnerImpl.GetDefaultRunProcedureOperationLbl() then
            BCCTLogEntry."Duration (ms)" -= AITTestRunnerImpl.GetAndClearAccumulatedWaitTimeMs();
        BCCTLogEntry.Insert(true);
        Commit();
        this.AddLogAppInsights(BCCTLogEntry);
        AITTestRunnerImpl.AddToNoOfLogEntriesInserted();
    end;

    local procedure AddLogAppInsights(var BCCTLogEntry: Record "BCCT Log Entry")
    var
        // AITTestRunnerImpl: Codeunit "BCCT Role Wrapper"; // single instance
        Dimensions: Dictionary of [Text, Text];
        TelemetryLogLbl: Label 'Performance Toolkit - %1 - %2 - %3', Locked = true;
    begin
        Dimensions.Add('RunID', BCCTLogEntry.RunID);
        Dimensions.Add('Code', BCCTLogEntry."BCCT Code");
        Dimensions.Add('LineNo', Format(BCCTLogEntry."BCCT Line No."));
        Dimensions.Add('Version', Format(BCCTLogEntry.Version));
        Dimensions.Add('CodeunitId', Format(BCCTLogEntry."Codeunit ID"));
        BCCTLogEntry.CalcFields("Codeunit Name");
        Dimensions.Add('CodeunitName', BCCTLogEntry."Codeunit Name");
        Dimensions.Add('Operation', BCCTLogEntry.Operation);
        Dimensions.Add('Tag', BCCTLogEntry.Tag);
        Dimensions.Add('Status', Format(BCCTLogEntry.Status));
        if BCCTLogEntry.Status = BCCTLogEntry.Status::Error then
            Dimensions.Add('StackTrace', BCCTLogEntry."Error Call Stack");
        Dimensions.Add('Message', BCCTLogEntry.Message);
        Dimensions.Add('StartTime', Format(BCCTLogEntry."Start Time"));
        Dimensions.Add('EndTime', Format(BCCTLogEntry."End Time"));
        Dimensions.Add('DurationInMs', Format(BCCTLogEntry."Duration (ms)"));
        Session.LogMessage(
            '0000DGF',
            StrSubstNo(TelemetryLogLbl, BCCTLogEntry."BCCT Code", BCCTLogEntry.Operation, BCCTLogEntry.Status),
            Verbosity::Normal,
            DataClassification::SystemMetadata,
            TelemetryScope::All,
            Dimensions)
    end;

    procedure UserWait(var BCCTLine: Record "BCCT Line")
    var
        AITTestRunnerImpl: Codeunit "AIT Test Runner"; // single instance
        NapTime: Integer;
    begin
        Commit();
        NapTime := BCCTLine."Min. User Delay (ms)" + Random(BCCTLine."Max. User Delay (ms)" - BCCTLine."Min. User Delay (ms)");
        AITTestRunnerImpl.AddToAccumulatedWaitTimeMs(NapTime);
        Sleep(NapTime);
    end;

    procedure GetAvgDuration(BCCTLine: Record "BCCT Line"): Integer
    begin
        if BCCTLine."No. of Tests" = 0 then
            exit(0);
        exit(BCCTLine."Total Duration (ms)" div BCCTLine."No. of Tests");
    end;

    procedure EvaluateDecimal(var Parm: Text; var ParmVal: Decimal): Boolean
    var
        x: Decimal;
    begin
        if not Evaluate(x, Parm) then
            exit(false);
        ParmVal := x;
        Parm := format(ParmVal, 0, 9);
        exit(true);
    end;

    procedure EvaluateDate(var Parm: Text; var ParmVal: Date): Boolean
    var
        x: Date;
    begin
        if not Evaluate(x, Parm) then
            exit(false);
        ParmVal := x;
        Parm := format(ParmVal, 0, 9);
        exit(true);
    end;

    procedure EvaluateFieldValue(var Parm: Text; TableNo: Integer; FieldNo: Integer): Boolean
    var
        Field: Record Field;
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        if not Field.Get(TableNo, FieldNo) then
            exit(false);
        if Field.Type <> Field.Type::Option then
            exit(false);
        RecRef.Open(TableNo);
        FldRef := RecRef.Field(FieldNo);
        if not Evaluate(FldRef, Parm) then
            exit(false);
        Parm := format(FldRef.Value, 0, 9);
        exit(true);
    end;

    procedure SetTestOutput(Scenario: Text; OutputValue: Text)
    begin
        if this.ScenarioOutput.ContainsKey(Scenario) then
            this.ScenarioOutput.Set(Scenario, OutputValue)
        else
            this.ScenarioOutput.Add(Scenario, OutputValue);
    end;

    procedure GetTestOutput(Scenario: Text): Text
    var
        OutputValue: Text;
    begin
        if this.ScenarioOutput.ContainsKey(Scenario) then begin
            OutputValue := this.ScenarioOutput.Get(Scenario);
            this.ScenarioOutput.Remove(Scenario);
            exit(OutputValue);
        end else
            exit('');
    end;
}