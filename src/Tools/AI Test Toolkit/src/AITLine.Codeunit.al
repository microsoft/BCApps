// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.Reflection;
using System.TestTools.TestRunner;

codeunit 149035 "AIT Line"
{
    Access = Internal;

    var
        AITHeader: Record "AIT Header";
        ScenarioStarted: Dictionary of [Text, DateTime];
        ScenarioOutput: Dictionary of [Text, Text];
        ScenarioNotStartedErr: Label 'Scenario %1 in codeunit %2 was not started.', Comment = '%1 = method name, %2 = codeunit name';

    [EventSubscriber(ObjectType::Table, Database::"AIT Line", OnBeforeInsertEvent, '', false, false)]
    local procedure SetNoOfSessionsOnBeforeInsertAITLine(var Rec: Record "AIT Line"; RunTrigger: Boolean)
    var
        AITLine: Record "AIT Line";
    begin
        if Rec.IsTemporary() then
            exit;

        if Rec."Line No." = 0 then begin
            AITLine.SetAscending("Line No.", true);
            AITLine.SetRange("AIT Code", Rec."AIT Code");
            if AITLine.FindLast() then;
            Rec."Line No." := AITLine."Line No." + 1000;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"AIT Line", OnBeforeDeleteEvent, '', false, false)]
    local procedure DeleteLogEntriesOnDeleteAITLine(var Rec: Record "AIT Line"; RunTrigger: Boolean)
    var
        AITLogEntry: Record "AIT Log Entry";
    begin
        if Rec.IsTemporary() then
            exit;

        AITLogEntry.SetRange("AIT Code", Rec."AIT Code");
        AITLogEntry.SetRange("AIT Line No.", Rec."Line No.");
        AITLogEntry.DeleteAll(true);
    end;

    [EventSubscriber(ObjectType::Page, Page::"AIT Lines", OnInsertRecordEvent, '', false, false)]
    local procedure OnInsertRecordEvent(var Rec: Record "AIT Line"; BelowxRec: Boolean; var xRec: Record "AIT Line"; var AllowInsert: Boolean)
    begin
        if Rec."AIT Code" = '' then begin
            AllowInsert := false;
            exit;
        end;

        if Rec."Min. User Delay (ms)" = 0 then
            Rec."Min. User Delay (ms)" := this.AITHeader."Default Min. User Delay (ms)";
        if Rec."Max. User Delay (ms)" = 0 then
            Rec."Max. User Delay (ms)" := this.AITHeader."Default Max. User Delay (ms)";

        if Rec."AIT Code" <> this.AITHeader.Code then
            if this.AITHeader.Get(Rec."AIT Code") then;
    end;

    procedure Indent(var AITLine: Record "AIT Line")
    var
        ParentAITLine: Record "AIT Line";
    begin
        if AITLine.Indentation > 0 then
            exit;
        ParentAITLine := AITLine;
        ParentAITLine.SetRange(Sequence, AITLine.Sequence);
        ParentAITLine.SetRange(Indentation, 0);
        if ParentAITLine.IsEmpty() then
            exit;
        AITLine.Indentation := 1;
        AITLine.Modify(true);
    end;

    procedure Outdent(var AITLine: Record "AIT Line")
    begin
        if AITLine.Indentation = 0 then
            exit;
        AITLine.Indentation := 0;
        AITLine.Modify(true);
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

    internal procedure EndRunProcedureScenario(AITLine: Record "AIT Line"; ScenarioOperation: Text; CurrentTestMethodLine: Record "Test Method Line"; ExecutionSuccess: Boolean)
    var
        TestSuiteMgt: Codeunit "Test Suite Mgt.";
        AITTALTestSuiteMgt: Codeunit "AITT AL Test Suite Mgt";
        StartTime: DateTime;
        EndTime: DateTime;
        ErrorMessage: Text;
    begin
        // Skip the OnRun entry if there are no errors
        if (ScenarioOperation = AITTALTestSuiteMgt.GetDefaultRunProcedureOperationLbl()) and (CurrentTestMethodLine.Function = 'OnRun') and (ExecutionSuccess = true) and (CurrentTestMethodLine."Error Message".Length = 0) then
            exit;

        // Set the start time and end time
        if ScenarioOperation = AITTALTestSuiteMgt.GetDefaultRunProcedureOperationLbl() then begin
            StartTime := CurrentTestMethodLine."Start Time";
            EndTime := CurrentTestMethodLine."Finish Time";
        end
        else begin
            if not this.ScenarioStarted.ContainsKey(ScenarioOperation) then
                Error(this.ScenarioNotStartedErr, ScenarioOperation, AITLine."Codeunit Name");
            EndTime := CurrentDateTime();
            if this.ScenarioStarted.Get(ScenarioOperation, StartTime) then // Get the start time
                if this.ScenarioStarted.Remove(ScenarioOperation) then;
        end;

        if CurrentTestMethodLine."Error Message".Length > 0 then
            ErrorMessage := TestSuiteMgt.GetFullErrorMessage(CurrentTestMethodLine)
        else
            ErrorMessage := '';

        this.AddLogEntry(AITLine, CurrentTestMethodLine, ScenarioOperation, ExecutionSuccess, ErrorMessage, StartTime, EndTime);
    end;

    // TODO: Scenario output has to be collected and inserted at the end, before EndRunProcedure. Currently it is added with isolation and it gets rolled back.

    local procedure AddLogEntry(var AITLine: Record "AIT Line"; CurrentTestMethodLine: Record "Test Method Line"; Operation: Text; ExecutionSuccess: Boolean; Message: Text; StartTime: DateTime; EndTime: Datetime)
    var
        AITLogEntry: Record "AIT Log Entry";
        TestInput: Record "Test Input";
        AITTestRunnerImpl: Codeunit "AIT Test Runner"; // single instance
        AITTALTestSuiteMgt: Codeunit "AITT AL Test Suite Mgt";
        AITTestSuite: Codeunit "AIT Test Suite";
        TestSuiteMgt: Codeunit "Test Suite Mgt.";
        ModifiedOperation: Text;
        ModifiedExecutionSuccess: Boolean;
        ModifiedMessage: Text;
        TestOutput: Text;
        EntryWasModified: Boolean;
    begin
        ModifiedOperation := Operation;
        ModifiedExecutionSuccess := ExecutionSuccess;
        ModifiedMessage := Message;
        AITTestSuite.OnBeforeAITLineAddLogEntry(AITLine."AIT Code", AITLine."Codeunit ID", AITLine.Description, Operation, ExecutionSuccess, Message, ModifiedOperation, ModifiedExecutionSuccess, ModifiedMessage);
        if (Operation <> ModifiedOperation) or (ExecutionSuccess <> ModifiedExecutionSuccess) or (Message <> ModifiedMessage) then
            EntryWasModified := true;

        AITLine.Testfield("AIT Code");
        AITTestRunnerImpl.GetAITHeader(this.AITHeader);
        Clear(AITLogEntry);
        AITLogEntry.RunID := this.AITHeader.RunID;
        AITLogEntry."AIT Code" := AITLine."AIT Code";
        AITLogEntry."AIT Line No." := AITLine."Line No.";
        AITLogEntry.Version := this.AITHeader.Version;
        AITLogEntry."Codeunit ID" := AITLine."Codeunit ID";
        AITLogEntry.Operation := CopyStr(ModifiedOperation, 1, MaxStrLen(AITLogEntry.Operation));
        AITLogEntry."Orig. Operation" := CopyStr(Operation, 1, MaxStrLen(AITLogEntry."Orig. Operation"));
        AITLogEntry.Tag := AITTestRunnerImpl.GetAITHeaderTag();
        AITLogEntry."Entry No." := 0;
        if ModifiedExecutionSuccess then
            AITLogEntry.Status := AITLogEntry.Status::Success
        else begin
            AITLogEntry.Status := AITLogEntry.Status::Error;
            AITLogEntry."Error Call Stack" := CopyStr(TestSuiteMgt.GetErrorCallStack(CurrentTestMethodLine), 1, MaxStrLen(AITLogEntry."Error Call Stack"));
        end;
        if ExecutionSuccess then
            AITLogEntry."Orig. Status" := AITLogEntry.Status::Success
        else
            AITLogEntry."Orig. Status" := AITLogEntry.Status::Error;
        AITLogEntry.Message := CopyStr(ModifiedMessage, 1, MaxStrLen(AITLogEntry.Message));
        AITLogEntry."Orig. Message" := CopyStr(Message, 1, MaxStrLen(AITLogEntry."Orig. Message"));
        AITLogEntry."Log was Modified" := EntryWasModified;
        AITLogEntry."End Time" := EndTime;
        AITLogEntry."Start Time" := StartTime;
        if AITLogEntry."Start Time" = 0DT then
            AITLogEntry."Duration (ms)" := AITLogEntry."End Time" - AITLogEntry."Start Time";

        AITLogEntry."Test Input Group Code" := CurrentTestMethodLine."Data Input Group Code";
        AITLogEntry."Test Input Code" := CurrentTestMethodLine."Data Input";

        if TestInput.Get(CurrentTestMethodLine."Data Input Group Code", CurrentTestMethodLine."Data Input") then begin
            TestInput.CalcFields("Test Input");
            AITLogEntry."Input Data" := TestInput."Test Input";
            AITLogEntry.Sensitive := TestInput.Sensitive;
            AITLogEntry."Test Input Desc." := TestInput.Description;
        end;

        TestOutput := this.GetTestOutput(Operation);
        if TestOutput <> '' then
            AITLogEntry.SetOutputBlob(TestOutput);
        AITLogEntry."Procedure Name" := CurrentTestMethodLine.Function;
        if Operation = AITTALTestSuiteMgt.GetDefaultRunProcedureOperationLbl() then
            AITLogEntry."Duration (ms)" -= AITTestRunnerImpl.GetAndClearAccumulatedWaitTimeMs();
        AITLogEntry.Insert(true);
        Commit();
        this.AddLogAppInsights(AITLogEntry);
        AITTestRunnerImpl.AddToNoOfLogEntriesInserted();
    end;

    local procedure AddLogAppInsights(var AITLogEntry: Record "AIT Log Entry")
    var
        Dimensions: Dictionary of [Text, Text];
        TelemetryLogLbl: Label 'AI Test Tool - %1 - %2 - %3', Locked = true;
    begin
        Dimensions.Add('RunID', AITLogEntry.RunID);
        Dimensions.Add('Code', AITLogEntry."AIT Code");
        Dimensions.Add('LineNo', Format(AITLogEntry."AIT Line No."));
        Dimensions.Add('Version', Format(AITLogEntry.Version));
        Dimensions.Add('CodeunitId', Format(AITLogEntry."Codeunit ID"));
        AITLogEntry.CalcFields("Codeunit Name");
        Dimensions.Add('CodeunitName', AITLogEntry."Codeunit Name");
        Dimensions.Add('Operation', AITLogEntry.Operation);
        Dimensions.Add('Tag', AITLogEntry.Tag);
        Dimensions.Add('Status', Format(AITLogEntry.Status));
        if AITLogEntry.Status = AITLogEntry.Status::Error then
            Dimensions.Add('StackTrace', AITLogEntry."Error Call Stack");
        Dimensions.Add('Message', AITLogEntry.Message);
        Dimensions.Add('StartTime', Format(AITLogEntry."Start Time"));
        Dimensions.Add('EndTime', Format(AITLogEntry."End Time"));
        Dimensions.Add('DurationInMs', Format(AITLogEntry."Duration (ms)"));
        Session.LogMessage(
            '0000DGF',
            StrSubstNo(TelemetryLogLbl, AITLogEntry."AIT Code", AITLogEntry.Operation, AITLogEntry.Status),
            Verbosity::Normal,
            DataClassification::SystemMetadata,
            TelemetryScope::All,
            Dimensions)
    end;

    procedure UserWait(var AITLine: Record "AIT Line")
    var
        AITTestRunnerImpl: Codeunit "AIT Test Runner"; // single instance
        NapTime: Integer;
    begin
        Commit();
        NapTime := AITLine."Min. User Delay (ms)" + Random(AITLine."Max. User Delay (ms)" - AITLine."Min. User Delay (ms)");
        AITTestRunnerImpl.AddToAccumulatedWaitTimeMs(NapTime);
        Sleep(NapTime);
    end;

    procedure GetAvgDuration(AITLine: Record "AIT Line"): Integer
    begin
        if AITLine."No. of Tests" = 0 then
            exit(0);
        exit(AITLine."Total Duration (ms)" div AITLine."No. of Tests");
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