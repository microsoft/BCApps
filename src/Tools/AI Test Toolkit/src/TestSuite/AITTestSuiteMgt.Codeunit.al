// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.Reflection;
using System.TestTools.TestRunner;
using System.Utilities;

codeunit 149034 "AIT Test Suite Mgt."
{
    Access = Internal;

    var
        GlobalAITTestSuite: Record "AIT Test Suite";
        AITRunStartedLbl: Label 'AI Test Suite run started.', Locked = true;
        AITRunFinishedLbl: Label 'AI Test Suite run finished.', Locked = true;
        AITRunCancelledLbl: Label 'AI Test Suite run cancelled.', Locked = true;
        EmptyDatasetSuiteErr: Label 'Please provide a dataset for the AI Test Suite %1.', Comment = '%1 is the AI Test Suite code';
        NoDatasetInSuiteErr: Label 'The dataset %1 specified for AI Test Suite %2 does not exist.', Comment = '%1 is the Dataset name, %2 is the AI Test Suite code';
        NoInputsInSuiteErr: Label 'The dataset %1 specified for AI Test Suite %2 has no input lines.', Comment = '%1 is the Dataset name, %2 is the AI Test Suite code.';
        NoDatasetInLineErr: Label 'The dataset %1 specified for AI Test Line %2 does not exist.', Comment = '%1 is the Dataset name, %2 is AI Test Line No.';
        NoInputsInLineErr: Label 'The dataset %1 specified for AI Test line %2 has no input lines.', Comment = '%1 is the Dataset name, %2 is the AI Test Line No.';
        ScenarioStarted: Dictionary of [Text, DateTime];
        ScenarioOutput: Dictionary of [Text, Text];
        ScenarioNotStartedErr: Label 'Scenario %1 in codeunit %2 was not started.', Comment = '%1 = method name, %2 = codeunit name';
        NothingToRunErr: Label 'There is nothing to run. Please add test lines to the test suite.';
        CannotRunMultipleSuitesInParallelErr: Label 'There is already a test run in progress. You need to wait for it to finish or cancel it before starting a new test run.';

    procedure StartAITSuite(var AITTestSuite: Record "AIT Test Suite")
    var
        AITTestSuite2: Record "AIT Test Suite";
    begin
        // If there is already a suite running, then error
        AITTestSuite2.ReadIsolation := IsolationLevel::ReadUncommitted;
        AITTestSuite2.SetRange(Status, AITTestSuite2.Status::Running);
        if not AITTestSuite2.IsEmpty() then
            Error(CannotRunMultipleSuitesInParallelErr);

        RunAITests(AITTestSuite);
        if AITTestSuite.Find() then;
    end;

    local procedure RunAITests(AITTestSuite: Record "AIT Test Suite")
    var
        AITTestMethodLine: Record "AIT Test Method Line";
        AITTestSuiteMgt: Codeunit "AIT Test Suite Mgt.";
    begin
        ValidateAITestSuite(AITTestSuite);
        AITTestSuite.RunID := CreateGuid();
        AITTestSuite.Validate("Started at", CurrentDateTime);
        AITTestSuiteMgt.SetRunStatus(AITTestSuite, AITTestSuite.Status::Running);

        AITTestSuite."No. of Tests Running" := 0;
        AITTestSuite.Version += 1;
        AITTestSuite.Modify(true);
        Commit(); // Ensure that setup is not rolled back

        AITTestMethodLine.SetRange("Test Suite Code", AITTestSuite.Code);
        AITTestMethodLine.SetFilter("Codeunit ID", '<>0');
        AITTestMethodLine.SetRange("Version Filter", AITTestSuite.Version);
        if AITTestMethodLine.IsEmpty() then
            exit;

        AITTestMethodLine.ModifyAll(Status, AITTestMethodLine.Status::" ", true);

        if AITTestMethodLine.FindSet() then
            repeat
                RunAITestLine(AITTestMethodLine, false);
            until AITTestMethodLine.Next() = 0;
    end;

    internal procedure RunAITestLine(AITTestMethodLine: Record "AIT Test Method Line"; UpdateSuiteVersion: Boolean)
    var
        AITTestSuite: Record "AIT Test Suite";
        TestRunnerProgressDialog: Codeunit "Test Runner - Progress Dialog";
    begin
        if UpdateSuiteVersion then begin
            AITTestSuite.Get(AITTestMethodLine."Test Suite Code");
            AITTestSuite.Version += 1;
            AITTestSuite.Modify(true);
        end;

        AITTestMethodLine.Validate(Status, AITTestMethodLine.Status::Running);
        AITTestMethodLine.Modify(true);
        Commit();

        BindSubscription(TestRunnerProgressDialog);
        Codeunit.Run(Codeunit::"AIT Test Run Iteration", AITTestMethodLine);

        if AITTestMethodLine.Find() then begin
            AITTestMethodLine.Validate(Status, AITTestMethodLine.Status::Completed);
            AITTestMethodLine.Modify(true);
            Commit();
        end;
    end;

    local procedure ValidateAITestSuite(AITTestSuite: Record "AIT Test Suite")
    var
        AITTestMethodLine: Record "AIT Test Method Line";
        CodeunitMetadata: Record "CodeUnit Metadata";
        ValidDatasets: List of [Code[100]];
    begin
        // Validate test suite dataset
        ValidateSuiteDataset(AITTestSuite);
        ValidDatasets.Add(AITTestSuite."Input Dataset");

        AITTestMethodLine.SetRange("Test Suite Code", AITTestSuite.Code);
        if not AITTestMethodLine.FindSet() then
            Error(NothingToRunErr);

        repeat
            CodeunitMetadata.Get(AITTestMethodLine."Codeunit ID");

            // Validate test line dataset
            if (AITTestMethodLine."Input Dataset" <> '') and (not ValidDatasets.Contains(AITTestMethodLine."Input Dataset")) then begin
                ValidateTestLineDataset(AITTestMethodLine, AITTestMethodLine."Input Dataset");
                ValidDatasets.Add(AITTestMethodLine."Input Dataset");
            end;
        until AITTestMethodLine.Next() = 0;
    end;

    local procedure ValidateSuiteDataset(var AITTestSuite: Record "AIT Test Suite")
    begin
        // Validate test suite
        if AITTestSuite."Input Dataset" = '' then
            Error(EmptyDatasetSuiteErr, AITTestSuite."Code");

        if not DatasetExists(AITTestSuite."Input Dataset") then
            Error(NoDatasetInSuiteErr, AITTestSuite."Input Dataset", AITTestSuite."Code");

        if not InputDataLinesExists(AITTestSuite."Input Dataset") then
            Error(NoInputsInSuiteErr, AITTestSuite."Input Dataset", AITTestSuite."Code");
    end;

    local procedure ValidateTestLineDataset(AITTestMethodLine: Record "AIT Test Method Line"; DatasetName: Code[100])
    begin
        if not DatasetExists(DatasetName) then
            Error(NoDatasetInLineErr, DatasetName, AITTestMethodLine."Line No.");
        if not InputDataLinesExists(DatasetName) then
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
        AITTestSuite.Validate("No. of Tests Running", AITTestSuite."No. of Tests Running" - 1);
        AITTestSuite.Modify(true);
        Commit();
    end;

    internal procedure ResetStatus(var AITTestSuite: Record "AIT Test Suite")
    var
        AITTestMethodLine: Record "AIT Test Method Line";
        ConfirmResetStatusQst: Label 'This action will mark the run as Completed. Are you sure you want to continue?';
    begin
        if not Confirm(ConfirmResetStatusQst) then
            exit;

        AITTestMethodLine.SetRange("Test Suite Code", AITTestSuite."Code");
        AITTestMethodLine.ModifyAll(Status, AITTestMethodLine.Status::Completed, true);
        AITTestSuite.Status := AITTestSuite.Status::Completed;
        AITTestSuite."No. of Tests Running" := 0;
        AITTestSuite."Ended at" := CurrentDateTime();
        AITTestSuite.Modify(true);
    end;

    internal procedure SetRunStatus(var AITTestSuite: Record "AIT Test Suite"; AITTestSuiteStatus: Enum "AIT Test Suite Status")
    var
        TelemetryCustomDimensions: Dictionary of [Text, Text];
        SuiteExecutionDuration: Integer;
    begin
        TelemetryCustomDimensions.Add('RunID', Format(AITTestSuite.RunID));
        TelemetryCustomDimensions.Add('Code', AITTestSuite.Code);
        if AITTestSuiteStatus <> AITTestSuiteStatus::Running then begin
            AITTestSuite."Ended at" := CurrentDateTime();
            SuiteExecutionDuration := AITTestSuite."Ended at" - AITTestSuite."Started at";
            TelemetryCustomDimensions.Add('DurationInMilliseconds', Format(SuiteExecutionDuration));
        end;
        TelemetryCustomDimensions.Add('Version', Format(AITTestSuite.Version));

        AITTestSuite.Status := AITTestSuiteStatus;
        AITTestSuite.CalcFields("No. of Tests Executed", "Total Duration (ms)");

        case AITTestSuiteStatus of
            AITTestSuiteStatus::Running:
                Session.LogMessage('0000DHR', AITRunStartedLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, TelemetryCustomDimensions);
            AITTestSuiteStatus::Completed:
                Session.LogMessage('0000DHS', AITRunFinishedLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, TelemetryCustomDimensions);
            AITTestSuiteStatus::Cancelled:
                Session.LogMessage('0000DHT', AITRunCancelledLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, TelemetryCustomDimensions);
        end;
        AITTestSuite.Modify(true);
        Commit();
    end;

    internal procedure StartScenario(ScenarioOperation: Text)
    var
        OldStartTime: DateTime;
    begin
        if ScenarioStarted.Get(ScenarioOperation, OldStartTime) then
            ScenarioStarted.Set(ScenarioOperation, CurrentDateTime())
        else
            ScenarioStarted.Add(ScenarioOperation, CurrentDateTime());
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
        end else begin
            if not ScenarioStarted.ContainsKey(ScenarioOperation) then
                Error(ScenarioNotStartedErr, ScenarioOperation, AITTestMethodLine."Codeunit Name");

            EndTime := CurrentDateTime();
            if ScenarioStarted.Get(ScenarioOperation, StartTime) then // Get the start time
                if ScenarioStarted.Remove(ScenarioOperation) then;
        end;

        if CurrentTestMethodLine."Error Message".Length > 0 then
            ErrorMessage := TestSuiteMgt.GetFullErrorMessage(CurrentTestMethodLine)
        else
            ErrorMessage := '';

        AddLogEntry(AITTestMethodLine, CurrentTestMethodLine, ScenarioOperation, ExecutionSuccess, ErrorMessage, StartTime, EndTime);
    end;

    local procedure AddLogEntry(var AITTestMethodLine: Record "AIT Test Method Line"; CurrentTestMethodLine: Record "Test Method Line"; Operation: Text; ExecutionSuccess: Boolean; Message: Text; StartTime: DateTime; EndTime: Datetime)
    var
        AITLogEntry: Record "AIT Log Entry";
        TestInput: Record "Test Input";
        AITTestRunIteration: Codeunit "AIT Test Run Iteration"; // single instance
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
        AITTestRunIteration.GetAITTestSuite(GlobalAITTestSuite);

        AITLogEntry."Run ID" := GlobalAITTestSuite.RunID;
        AITLogEntry."Test Suite Code" := AITTestMethodLine."Test Suite Code";
        AITLogEntry."Test Method Line No." := AITTestMethodLine."Line No.";
        AITLogEntry.Version := GlobalAITTestSuite.Version;
        AITLogEntry."Codeunit ID" := AITTestMethodLine."Codeunit ID";
        AITLogEntry.Operation := CopyStr(ModifiedOperation, 1, MaxStrLen(AITLogEntry.Operation));
        AITLogEntry."Original Operation" := CopyStr(Operation, 1, MaxStrLen(AITLogEntry."Original Operation"));
        AITLogEntry.Tag := AITTestRunIteration.GetAITTestSuiteTag();
        AITLogEntry."Model Version" := GlobalAITTestSuite."Model Version";
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

        TestOutput := GetTestOutput(Operation);
        if TestOutput <> '' then
            AITLogEntry.SetOutputBlob(TestOutput);

        AITLogEntry."Procedure Name" := CurrentTestMethodLine.Function;
        AITLogEntry.Insert(true);

        Commit();
        AddLogAppInsights(AITLogEntry);
        AITTestRunIteration.AddToNoOfLogEntriesInserted();
    end;

    local procedure AddLogAppInsights(var AITLogEntry: Record "AIT Log Entry")
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

    internal procedure GetAvgDuration(AITTestMethodLine: Record "AIT Test Method Line"): Integer
    begin
        if AITTestMethodLine."No. of Tests Executed" = 0 then
            exit(0);
        exit(AITTestMethodLine."Total Duration (ms)" div AITTestMethodLine."No. of Tests Executed");
    end;

    internal procedure SetTestOutput(Scenario: Text; OutputValue: Text)
    begin
        if ScenarioOutput.ContainsKey(Scenario) then
            ScenarioOutput.Set(Scenario, OutputValue)
        else
            ScenarioOutput.Add(Scenario, OutputValue);
    end;

    internal procedure GetTestOutput(Scenario: Text): Text
    var
        OutputValue: Text;
    begin
        if ScenarioOutput.ContainsKey(Scenario) then begin
            OutputValue := ScenarioOutput.Get(Scenario);
            ScenarioOutput.Remove(Scenario);
            exit(OutputValue);
        end else
            exit('');
    end;

    internal procedure ExportAITTestSuite(var AITTestSuite: Record "AIT Test Suite")
    var
        TempBlob: Codeunit "Temp Blob";
        AITSuiteXMLPort: XmlPort "AIT Test Suite Import/Export";
        FileNameTxt: Text;
        AITTestSuiteOutStream: OutStream;
        AITTestSuiteInStream: InStream;
        TestOutputFileNameTxt: Label '%1.xml', Comment = '%1 = Filename', Locked = true;
    begin
        TempBlob.CreateOutStream(AITTestSuiteOutStream, AITSuiteXMLPort.TextEncoding);
        Xmlport.Export(Xmlport::"AIT Test Suite Import/Export", AITTestSuiteOutStream, AITTestSuite);
        TempBlob.CreateInStream(AITTestSuiteInStream, AITSuiteXMLPort.TextEncoding);

        FileNameTxt := StrSubstNo(TestOutputFileNameTxt, AITTestSuite.Code);
        DownloadFromStream(AITTestSuiteInStream, '', '', '.xml', FileNameTxt);
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

        if Rec."Test Suite Code" <> GlobalAITTestSuite.Code then
            if GlobalAITTestSuite.Get(Rec."Test Suite Code") then;
    end;
}