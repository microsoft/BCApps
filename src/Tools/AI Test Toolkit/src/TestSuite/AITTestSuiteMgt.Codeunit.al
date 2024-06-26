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
        NothingToRunErr: Label 'There is nothing to run. Please add test lines to the test suite.';
        CannotRunMultipleSuitesInParallelErr: Label 'There is already a test run in progress. Start this operation after that finishes.';

    procedure StartAITSuite(var AITTestSuite: Record "AIT Test Suite")
    var
        AITTestSuite2: Record "AIT Test Suite";
    begin
        // If there is already a suite running, then error
        AITTestSuite2.ReadIsolation := IsolationLevel::ReadUncommitted;
        AITTestSuite2.SetRange(Status, AITTestSuite2.Status::Running);
        if not AITTestSuite2.IsEmpty() then
            Error(this.CannotRunMultipleSuitesInParallelErr);

        this.RunAITests(AITTestSuite);
        if AITTestSuite.Find() then;
    end;

    local procedure RunAITests(AITTestSuite: Record "AIT Test Suite")
    var
        AITTestMethodLine: Record "AIT Test Method Line";
        AITTestSuiteMgt: Codeunit "AIT Test Suite Mgt.";
        StatusDialog: Dialog;
        RunningStatusMsg: Label 'Running test...\#1#########################################################################################', Comment = '#1 = Test codeunit name';
    begin
        this.ValidateAITestSuite(AITTestSuite);
        AITTestSuite.RunID := CreateGuid();
        AITTestSuite.Validate("Started at", CurrentDateTime);
        AITTestSuiteMgt.SetRunStatus(AITTestSuite, AITTestSuite.Status::Running);

        AITTestSuite."No. of tests running" := 0;
        AITTestSuite.Version += 1;
        AITTestSuite.Modify();
        Commit();

        AITTestMethodLine.SetRange("Test Suite Code", AITTestSuite.Code);
        AITTestMethodLine.SetFilter("Codeunit ID", '<>0');
        AITTestMethodLine.SetRange("Version Filter", AITTestSuite.Version);
        if AITTestMethodLine.IsEmpty() then
            exit;

        AITTestMethodLine.ModifyAll(Status, AITTestMethodLine.Status::" ");

        if AITTestMethodLine.FindSet() then begin
            StatusDialog.Open(RunningStatusMsg);
            repeat
                AITTestMethodLine.CalcFields("Codeunit Name");
                StatusDialog.Update(1, AITTestMethodLine."Codeunit Name");
                AITTestMethodLine.Validate(Status, AITTestMethodLine.Status::Running);
                AITTestMethodLine.Modify();
                Commit();
                Codeunit.Run(Codeunit::"AIT Test Runner", AITTestMethodLine);
                if AITTestMethodLine.Find() then begin
                    AITTestMethodLine.Validate(Status, AITTestMethodLine.Status::Completed);
                    AITTestMethodLine.Modify();
                    Commit();
                end;
            until AITTestMethodLine.Next() = 0;
            StatusDialog.Close();
        end;
    end;

    local procedure ValidateAITestSuite(AITTestSuite: Record "AIT Test Suite")
    var
        AITTestMethodLine: Record "AIT Test Method Line";
        CodeunitMetadata: Record "CodeUnit Metadata";
        ValidDatasets: List of [Code[100]];
    begin
        // Validate test suite dataset
        this.ValidateSuiteDataset(AITTestSuite);
        ValidDatasets.Add(AITTestSuite."Input Dataset");

        AITTestMethodLine.SetRange("Test Suite Code", AITTestSuite.Code);
        if not AITTestMethodLine.FindSet() then
            Error(NothingToRunErr);

        repeat
            CodeunitMetadata.Get(AITTestMethodLine."Codeunit ID");

            // Validate test line dataset
            if (AITTestMethodLine."Input Dataset" <> '') and (not ValidDatasets.Contains(AITTestMethodLine."Input Dataset")) then begin
                this.ValidateTestLineDataset(AITTestMethodLine, AITTestMethodLine."Input Dataset");
                ValidDatasets.Add(AITTestMethodLine."Input Dataset");
            end;
        until AITTestMethodLine.Next() = 0;
    end;

    local procedure ValidateSuiteDataset(var AITTestSuite: Record "AIT Test Suite")
    begin
        // Validate test suite
        if AITTestSuite."Input Dataset" = '' then
            Error(EmptyDatasetSuiteErr, AITTestSuite."Code");

        if not this.DatasetExists(AITTestSuite."Input Dataset") then
            Error(NoDatasetInSuiteErr, AITTestSuite."Input Dataset", AITTestSuite."Code");

        if not this.InputDataLinesExists(AITTestSuite."Input Dataset") then
            Error(NoInputsInSuiteErr, AITTestSuite."Input Dataset", AITTestSuite."Code");
    end;

    local procedure ValidateTestLineDataset(AITTestMethodLine: Record "AIT Test Method Line"; DatasetName: Code[100])
    begin
        if not this.DatasetExists(DatasetName) then
            Error(NoDatasetInLineErr, DatasetName, AITTestMethodLine."Line No.");
        if not this.InputDataLinesExists(DatasetName) then
            Error(NoInputsInLineErr, DatasetName, AITTestMethodLine."Line No.");
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

    internal procedure DecreaseNoOfTestsRunningNow(var AITTestSuite: Record "AIT Test Suite")
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

    internal procedure ResetStatus(var AITTestSuite: Record "AIT Test Suite")
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

    internal procedure SetRunStatus(var AITTestSuite: Record "AIT Test Suite"; AITTestSuiteStatus: Enum "AIT Test Suite Status")
    var
        TelemetryCustomDimensions: Dictionary of [Text, Text];
    begin
        TelemetryCustomDimensions.Add('RunID', Format(AITTestSuite.RunID));
        TelemetryCustomDimensions.Add('Code', AITTestSuite.Code);
        if AITTestSuiteStatus <> AITTestSuiteStatus::Running then begin
            AITTestSuite."Ended at" := CurrentDateTime();
            AITTestSuite.Duration := AITTestSuite."Ended at" - AITTestSuite."Started at";
            TelemetryCustomDimensions.Add('DurationInMilliseconds', Format(AITTestSuite.Duration));
        end;
        TelemetryCustomDimensions.Add('Version', Format(AITTestSuite.Version));

        AITTestSuite.Status := AITTestSuiteStatus;
        AITTestSuite.CalcFields("No. of Tests Executed", "Total Duration (ms)"); //TODO: Use feature uptake telemetry

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

    internal procedure StartScenario(ScenarioOperation: Text)
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

    local procedure AddLogEntry(var AITTestMethodLine: Record "AIT Test Method Line"; CurrentTestMethodLine: Record "Test Method Line"; Operation: Text; ExecutionSuccess: Boolean; Message: Text; StartTime: DateTime; EndTime: Datetime)
    var
        AITLogEntry: Record "AIT Log Entry";
        TestInput: Record "Test Input";
        AITTestRunner: Codeunit "AIT Test Runner"; // single instance
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

        AITTestMethodLine.TestField("Test Suite Code");
        AITTestRunner.GetAITTestSuite(this.GlobalAITTestSuite);
        Clear(AITLogEntry);
        AITLogEntry."Run ID" := this.GlobalAITTestSuite.RunID;
        AITLogEntry."Test Suite Code" := AITTestMethodLine."Test Suite Code";
        AITLogEntry."Test Method Line No." := AITTestMethodLine."Line No.";
        AITLogEntry.Version := this.GlobalAITTestSuite.Version;
        AITLogEntry."Codeunit ID" := AITTestMethodLine."Codeunit ID";
        AITLogEntry.Operation := CopyStr(ModifiedOperation, 1, MaxStrLen(AITLogEntry.Operation));
        AITLogEntry."Original Operation" := CopyStr(Operation, 1, MaxStrLen(AITLogEntry."Original Operation"));
        AITLogEntry.Tag := AITTestRunner.GetAITTestSuiteTag();
        AITLogEntry.ModelVersion := this.GlobalAITTestSuite.ModelVersion;
        AITLogEntry."Entry No." := 0;
        if ModifiedExecutionSuccess then
            AITLogEntry.Status := AITLogEntry.Status::Success
        else begin
            AITLogEntry.Status := AITLogEntry.Status::Error;
            AITLogEntry.SetErrorCallStack(TestSuiteMgt.GetErrorCallStack(CurrentTestMethodLine));
        end;
        if ExecutionSuccess then
            AITLogEntry."Original Status" := AITLogEntry.Status::Success
        else
            AITLogEntry."Original Status" := AITLogEntry.Status::Error;
        AITLogEntry.SetMessage(ModifiedMessage);
        AITLogEntry."Original Message" := CopyStr(Message, 1, MaxStrLen(AITLogEntry."Original Message"));
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
            AITLogEntry."Test Input Description" := TestInput.Description;
        end;

        TestOutput := this.GetTestOutput(Operation);
        if TestOutput <> '' then
            AITLogEntry.SetOutputBlob(TestOutput);
        AITLogEntry."Procedure Name" := CurrentTestMethodLine.Function;
        if Operation = AITALTestSuiteMgt.GetDefaultRunProcedureOperationLbl() then
            AITLogEntry."Duration (ms)" -= AITTestRunner.GetAndClearAccumulatedWaitTimeMs();
        AITLogEntry.Insert(true);
        Commit();
        this.AddLogAppInsights(AITLogEntry);
        AITTestRunner.AddToNoOfLogEntriesInserted();
    end;

    local procedure AddLogAppInsights(var AITLogEntry: Record "AIT Log Entry") //TODO: Check what is being emitted, consider using feature uptake telemetry
    var
        Dimensions: Dictionary of [Text, Text];
        TelemetryLogLbl: Label 'AI Test Tool - %1 - %2 - %3', Locked = true;
    begin
        Dimensions.Add('RunID', AITLogEntry."Run ID");
        Dimensions.Add('Code', AITLogEntry."Test Suite Code");
        Dimensions.Add('LineNo', Format(AITLogEntry."Test Method Line No."));
        Dimensions.Add('Version', Format(AITLogEntry.Version));
        Dimensions.Add('CodeunitId', Format(AITLogEntry."Codeunit ID"));
        AITLogEntry.CalcFields("Codeunit Name");
        Dimensions.Add('CodeunitName', AITLogEntry."Codeunit Name");
        Dimensions.Add('Operation', AITLogEntry.Operation);
        Dimensions.Add('Status', Format(AITLogEntry.Status));
        Dimensions.Add('Message', AITLogEntry.GetMessage());
        Dimensions.Add('StartTime', Format(AITLogEntry."Start Time"));
        Dimensions.Add('EndTime', Format(AITLogEntry."End Time"));
        Dimensions.Add('DurationInMs', Format(AITLogEntry."Duration (ms)"));
        Session.LogMessage(
            '0000DGF',
            StrSubstNo(TelemetryLogLbl, AITLogEntry."Test Suite Code", AITLogEntry.Operation, AITLogEntry.Status),
            Verbosity::Normal,
            DataClassification::SystemMetadata,
            TelemetryScope::All,
            Dimensions)
    end;

    internal procedure UserWait(var AITTestMethodLine: Record "AIT Test Method Line")
    var
        AITTestRunnerImpl: Codeunit "AIT Test Runner"; // single instance
        NapTime: Integer;
    begin
        Commit();
        NapTime := AITTestMethodLine."Min. User Delay (ms)" + Random(AITTestMethodLine."Max. User Delay (ms)" - AITTestMethodLine."Min. User Delay (ms)");
        AITTestRunnerImpl.AddToAccumulatedWaitTimeMs(NapTime);
        Sleep(NapTime);
    end;

    internal procedure GetAvgDuration(AITTestMethodLine: Record "AIT Test Method Line"): Integer
    begin
        if AITTestMethodLine."No. of Tests" = 0 then
            exit(0);
        exit(AITTestMethodLine."Total Duration (ms)" div AITTestMethodLine."No. of Tests");
    end;

    internal procedure SetTestOutput(Scenario: Text; OutputValue: Text)
    begin
        if this.ScenarioOutput.ContainsKey(Scenario) then
            this.ScenarioOutput.Set(Scenario, OutputValue)
        else
            this.ScenarioOutput.Add(Scenario, OutputValue);
    end;

    internal procedure GetTestOutput(Scenario: Text): Text
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

        AITLogEntry.SetRange("Test Suite Code", Rec."Code");
        AITLogEntry.DeleteAll(true);
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

        AITLogEntry.SetRange("Test Suite Code", Rec."Test Suite Code");
        AITLogEntry.SetRange("Test Method Line No.", Rec."Line No.");
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
}