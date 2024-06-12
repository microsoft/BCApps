// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.Reflection;
using System.TestTools.TestRunner;

codeunit 149034 "AIT Test Suite Mgt."
{
    Access = Internal;

    var
        GlobalAITTestSuite: Record "AIT Test Suite";
        AITTRunStartedLbl: Label 'AI Test Suite run started.', Locked = true;
        AITTRunFinishedLbl: Label 'AI Test Suite run finished.', Locked = true;
        AITTRunCancelledLbl: Label 'AI Test Suite run cancelled.', Locked = true;
        EmptyDatasetSuiteErr: Label 'Please provide a dataset for the AIT Suite %1.', Comment = '%1 is the AIT Suite code';
        NoDatasetInSuiteErr: Label 'The dataset %1 specified for AIT Suite %2 does not exist.', Comment = '%1 is the Dataset name, %2 is the AIT Suite code';
        NoInputsInSuiteErr: Label 'The dataset %1 specified for AIT Suite %2 has no input lines.', Comment = '%1 is the Dataset name, %2 is the AIT Suite code.';
        NoDatasetInLineErr: Label 'The dataset %1 specified for AIT Line %2 does not exist.', Comment = '%1 is the Dataset name, %2 is AIT Line No.';
        NoInputsInLineErr: Label 'The dataset %1 specified for AIT line %2 has no input lines.', Comment = '%1 is the Dataset name, %2 is the AIT Line No.';
        ScenarioStarted: Dictionary of [Text, DateTime];
        ScenarioOutput: Dictionary of [Text, Text];
        ScenarioNotStartedErr: Label 'Scenario %1 in codeunit %2 was not started.', Comment = '%1 = method name, %2 = codeunit name';

    procedure DecreaseNoOfTestsRunningNow(var AITTestSuite: Record "AIT Test Suite")
    begin
        if AITTestSuite.Code = '' then
            exit;
        AITTestSuite.ReadIsolation(IsolationLevel::UpdLock);
        if not AITTestSuite.Find() then
            exit;
        AITTestSuite.Validate("No. of tests running", AITTestSuite."No. of tests running" - 1);
        AITTestSuite.Modify();
        Commit();
    end;

    procedure ResetStatus(var AITTestSuite: Record "AIT Test Suite")
    var
        AITTestMethodLine: Record "AIT Test Method Line";
        ConfirmResetStatusQst: Label 'This action will mark the run as Completed. Are you sure you want to continue ?';
    begin
        if Confirm(ConfirmResetStatusQst) then begin
            AITTestMethodLine.SetRange("Test Suite Code", AITTestSuite."Code");
            AITTestMethodLine.ModifyAll(Status, AITTestMethodLine.Status::Completed);
            AITTestSuite.Status := AITTestSuite.Status::Completed;
            AITTestSuite."No. of tests running" := 0;
            AITTestSuite."Ended at" := CurrentDateTime();
            AITTestSuite.Duration := AITTestSuite."Ended at" - AITTestSuite."Started at";
            AITTestSuite.Modify(true);
        end;
    end;

    procedure ValidateDatasets(var AITTestSuite: Record "AIT Test Suite")
    var
        AITTestMethodLine: Record "AIT Test Method Line";
        DatasetsToValidate: List of [Code[100]];
        DatasetName: Code[100];
    begin
        // Validate test suite
        if AITTestSuite."Input Dataset" = '' then
            Error(EmptyDatasetSuiteErr, AITTestSuite."Code");

        if not this.DatasetExists(AITTestSuite."Input Dataset") then
            Error(NoDatasetInSuiteErr, AITTestSuite."Input Dataset", AITTestSuite."Code");

        if not this.InputDataLinesExists(AITTestSuite."Input Dataset") then
            Error(NoInputsInSuiteErr, AITTestSuite."Input Dataset", AITTestSuite."Code");

        // Validate test lines
        AITTestMethodLine.SetRange("Test Suite Code", AITTestSuite."Code");
        AITTestMethodLine.SetFilter("Input Dataset", '<>%1', '');
        AITTestMethodLine.SetLoadFields("Input Dataset");
        if AITTestMethodLine.FindSet() then
            repeat
                if AITTestMethodLine."Input Dataset" <> AITTestSuite."Input Dataset" then
                    if not DatasetsToValidate.Contains(AITTestMethodLine."Input Dataset") then
                        DatasetsToValidate.Add(AITTestMethodLine."Input Dataset");
            until AITTestMethodLine.Next() = 0;

        foreach DatasetName in DatasetsToValidate do begin
            if not this.DatasetExists(DatasetName) then
                Error(NoDatasetInLineErr, DatasetName, AITTestMethodLine."Line No.");
            if not this.InputDataLinesExists(DatasetName) then
                Error(NoInputsInLineErr, DatasetName, AITTestMethodLine."Line No.");
        end;
    end;

    local procedure DatasetExists(DatasetName: Code[100]): Boolean
    var
        TestInputGroup: Record "Test Input Group";
    begin
        exit(TestInputGroup.Get(DatasetName));
    end;

    local procedure InputDataLinesExists(DatasetName: Code[100]): Boolean
    var
        TestInput: Record "Test Input";
    begin
        TestInput.Reset();
        TestInput.SetRange("Test Input Group Code", DatasetName);
        exit(not TestInput.IsEmpty());
    end;

    [EventSubscriber(ObjectType::Table, Database::"AIT Test Suite", OnBeforeDeleteEvent, '', false, false)]
    local procedure DeleteLinesOnDeleteAITTestSuite(var Rec: Record "AIT Test Suite"; RunTrigger: Boolean)
    var
        AITTestMethodLine: Record "AIT Test Method Line";
        AITLogEntry: Record "AIT Log Entry";
    begin
        if Rec.IsTemporary() then
            exit;

        AITTestMethodLine.SetRange("Test Suite Code", Rec."Code");
        AITTestMethodLine.DeleteAll(true);

        AITLogEntry.SetRange("AIT Code", Rec."Code");
        AITLogEntry.DeleteAll(true);
    end;

    procedure SetRunStatus(var AITTestSuite: Record "AIT Test Suite"; AITTestSuiteStatus: Enum "AIT Test Suite Status")
    var
        TelemetryCustomDimensions: Dictionary of [Text, Text];
    begin
        TelemetryCustomDimensions.Add('RunID', Format(AITTestSuite.RunID));
        TelemetryCustomDimensions.Add('Code', AITTestSuite.Code);
        if AITTestSuiteStatus <> AITTestSuiteStatus::Running then begin
            AITTestSuite."Ended at" := CurrentDateTime();
            AITTestSuite.Duration := AITTestSuite."Ended at" - AITTestSuite."Started at";
            TelemetryCustomDimensions.Add('DurationInMiliseconds', Format(AITTestSuite.Duration));
        end;
        TelemetryCustomDimensions.Add('Version', Format(AITTestSuite.Version));

        AITTestSuite.Status := AITTestSuiteStatus;
        AITTestSuite.CalcFields("No. of Tests Executed", "Total Duration (ms)"); //TODO: add this to custom dimensions or remove it

        case AITTestSuiteStatus of
            AITTestSuiteStatus::Running:
                Session.LogMessage('0000DHR', AITTRunStartedLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, TelemetryCustomDimensions);
            AITTestSuiteStatus::Completed:
                Session.LogMessage('0000DHS', AITTRunFinishedLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, TelemetryCustomDimensions);
            AITTestSuiteStatus::Cancelled:
                Session.LogMessage('0000DHT', AITTRunCancelledLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, TelemetryCustomDimensions);
        end;
        AITTestSuite.Modify();
        Commit();
    end;


    [EventSubscriber(ObjectType::Table, Database::"AIT Test Method Line", OnBeforeInsertEvent, '', false, false)]
    local procedure SetNoOfSessionsOnBeforeInsertAITTestMethodLine(var Rec: Record "AIT Test Method Line"; RunTrigger: Boolean)
    var
        AITTestMethodLine: Record "AIT Test Method Line";
    begin
        if Rec.IsTemporary() then
            exit;

        if Rec."Line No." = 0 then begin
            AITTestMethodLine.SetAscending("Line No.", true);
            AITTestMethodLine.SetRange("Test Suite Code", Rec."Test Suite Code");
            if AITTestMethodLine.FindLast() then;
            Rec."Line No." := AITTestMethodLine."Line No." + 1000;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"AIT Test Method Line", OnBeforeDeleteEvent, '', false, false)]
    local procedure DeleteLogEntriesOnDeleteAITTestMethodLine(var Rec: Record "AIT Test Method Line"; RunTrigger: Boolean)
    var
        AITLogEntry: Record "AIT Log Entry";
    begin
        if Rec.IsTemporary() then
            exit;

        AITLogEntry.SetRange("AIT Code", Rec."Test Suite Code");
        AITLogEntry.SetRange("AIT Line No.", Rec."Line No.");
        AITLogEntry.DeleteAll(true);
    end;

    [EventSubscriber(ObjectType::Page, Page::"AIT Test Method Lines", OnInsertRecordEvent, '', false, false)]
    local procedure OnInsertRecordEvent(var Rec: Record "AIT Test Method Line"; BelowxRec: Boolean; var xRec: Record "AIT Test Method Line"; var AllowInsert: Boolean)
    begin
        if Rec."Test Suite Code" = '' then begin
            AllowInsert := false;
            exit;
        end;

        if Rec."Min. User Delay (ms)" = 0 then
            Rec."Min. User Delay (ms)" := this.GlobalAITTestSuite."Default Min. User Delay (ms)";
        if Rec."Max. User Delay (ms)" = 0 then
            Rec."Max. User Delay (ms)" := this.GlobalAITTestSuite."Default Max. User Delay (ms)";

        if Rec."Test Suite Code" <> this.GlobalAITTestSuite.Code then
            if this.GlobalAITTestSuite.Get(Rec."Test Suite Code") then;
    end;

    procedure Indent(var AITTestMethodLine: Record "AIT Test Method Line")
    var
        ParentAITTestMethodLine: Record "AIT Test Method Line";
    begin
        if AITTestMethodLine.Indentation > 0 then
            exit;
        ParentAITTestMethodLine := AITTestMethodLine;
        ParentAITTestMethodLine.SetRange(Sequence, AITTestMethodLine.Sequence);
        ParentAITTestMethodLine.SetRange(Indentation, 0);
        if ParentAITTestMethodLine.IsEmpty() then
            exit;
        AITTestMethodLine.Indentation := 1;
        AITTestMethodLine.Modify(true);
    end;

    procedure Outdent(var AITTestMethodLine: Record "AIT Test Method Line")
    begin
        if AITTestMethodLine.Indentation = 0 then
            exit;
        AITTestMethodLine.Indentation := 0;
        AITTestMethodLine.Modify(true);
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

    internal procedure EndRunProcedureScenario(AITTestMethodLine: Record "AIT Test Method Line"; ScenarioOperation: Text; CurrentTestMethodLine: Record "Test Method Line"; ExecutionSuccess: Boolean)
    var
        TestSuiteMgt: Codeunit "Test Suite Mgt.";
        AITALTestSuiteMgt: Codeunit "AIT AL Test Suite Mgt";
        StartTime: DateTime;
        EndTime: DateTime;
        ErrorMessage: Text;
    begin
        // Skip the OnRun entry if there are no errors
        if (ScenarioOperation = AITALTestSuiteMgt.GetDefaultRunProcedureOperationLbl()) and (CurrentTestMethodLine.Function = 'OnRun') and (ExecutionSuccess = true) and (CurrentTestMethodLine."Error Message".Length = 0) then
            exit;

        // Set the start time and end time
        if ScenarioOperation = AITALTestSuiteMgt.GetDefaultRunProcedureOperationLbl() then begin
            StartTime := CurrentTestMethodLine."Start Time";
            EndTime := CurrentTestMethodLine."Finish Time";
        end
        else begin
            if not this.ScenarioStarted.ContainsKey(ScenarioOperation) then
                Error(this.ScenarioNotStartedErr, ScenarioOperation, AITTestMethodLine."Codeunit Name");
            EndTime := CurrentDateTime();
            if this.ScenarioStarted.Get(ScenarioOperation, StartTime) then // Get the start time
                if this.ScenarioStarted.Remove(ScenarioOperation) then;
        end;

        if CurrentTestMethodLine."Error Message".Length > 0 then
            ErrorMessage := TestSuiteMgt.GetFullErrorMessage(CurrentTestMethodLine)
        else
            ErrorMessage := '';

        this.AddLogEntry(AITTestMethodLine, CurrentTestMethodLine, ScenarioOperation, ExecutionSuccess, ErrorMessage, StartTime, EndTime);
    end;

    // TODO: Scenario output has to be collected and inserted at the end, before EndRunProcedure. Currently it is added with isolation and it gets rolled back.

    local procedure AddLogEntry(var AITTestMethodLine: Record "AIT Test Method Line"; CurrentTestMethodLine: Record "Test Method Line"; Operation: Text; ExecutionSuccess: Boolean; Message: Text; StartTime: DateTime; EndTime: Datetime)
    var
        AITLogEntry: Record "AIT Log Entry";
        TestInput: Record "Test Input";
        AITTestRunnerImpl: Codeunit "AIT Test Runner"; // single instance
        AITALTestSuiteMgt: Codeunit "AIT AL Test Suite Mgt";
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
        if (Operation <> ModifiedOperation) or (ExecutionSuccess <> ModifiedExecutionSuccess) or (Message <> ModifiedMessage) then
            EntryWasModified := true;

        AITTestMethodLine.Testfield("Test Suite Code");
        AITTestRunnerImpl.GetAITTestSuite(this.GlobalAITTestSuite);
        Clear(AITLogEntry);
        AITLogEntry.RunID := this.GlobalAITTestSuite.RunID;
        AITLogEntry."AIT Code" := AITTestMethodLine."Test Suite Code";
        AITLogEntry."AIT Line No." := AITTestMethodLine."Line No.";
        AITLogEntry.Version := this.GlobalAITTestSuite.Version;
        AITLogEntry."Codeunit ID" := AITTestMethodLine."Codeunit ID";
        AITLogEntry.Operation := CopyStr(ModifiedOperation, 1, MaxStrLen(AITLogEntry.Operation));
        AITLogEntry."Orig. Operation" := CopyStr(Operation, 1, MaxStrLen(AITLogEntry."Orig. Operation"));
        AITLogEntry.Tag := AITTestRunnerImpl.GetAITTestSuiteTag();
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
        if Operation = AITALTestSuiteMgt.GetDefaultRunProcedureOperationLbl() then
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

    procedure UserWait(var AITTestMethodLine: Record "AIT Test Method Line")
    var
        AITTestRunnerImpl: Codeunit "AIT Test Runner"; // single instance
        NapTime: Integer;
    begin
        Commit();
        NapTime := AITTestMethodLine."Min. User Delay (ms)" + Random(AITTestMethodLine."Max. User Delay (ms)" - AITTestMethodLine."Min. User Delay (ms)");
        AITTestRunnerImpl.AddToAccumulatedWaitTimeMs(NapTime);
        Sleep(NapTime);
    end;

    procedure GetAvgDuration(AITTestMethodLine: Record "AIT Test Method Line"): Integer
    begin
        if AITTestMethodLine."No. of Tests" = 0 then
            exit(0);
        exit(AITTestMethodLine."Total Duration (ms)" div AITTestMethodLine."No. of Tests");
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