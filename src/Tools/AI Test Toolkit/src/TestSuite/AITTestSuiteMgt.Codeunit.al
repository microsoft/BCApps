// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.Reflection;
using System.TestTools.TestRunner;
using System.Utilities;
using System.Telemetry;

codeunit 149034 "AIT Test Suite Mgt."
{
    Access = Internal;

    var
        GlobalAITTestSuite: Record "AIT Test Suite";
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
        FeatureNameLbl: Label 'AI Test Toolkit', Locked = true;
        LineNoFilterLbl: Label 'Codeunit %1 "%2" (Input: %3)', Locked = true;
        TurnsLbl: Label '%1/%2', Comment = '%1 - No. of turns that passed, %2 - Total no. of turns';
        EmptyLogEntriesErr: Label 'Cannot download test summary as there is no log entries within the filter.';
        DownloadResultsLbl: Label 'Download Test Summary';
        SummaryFileNameLbl: Label '%1_Test_Summary.xlsx', Locked = true;
        ConfirmCancelQst: Label 'This action will mark the run as Cancelled. Are you sure you want to continue?';

    procedure StartAITSuite(Iterations: Integer; var AITTestSuite: Record "AIT Test Suite")
    var
        CurrentIteration: Integer;
    begin
        for CurrentIteration := 1 to Iterations do
            StartAITSuite(AITTestSuite);
    end;

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
        AITRunHistory: Record "AIT Run History";
        AITTestSuiteMgt: Codeunit "AIT Test Suite Mgt.";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        FeatureTelemetryCD: Dictionary of [Text, Text];
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

        // Log the feature telemetry when executed from test suite header
        FeatureTelemetryCD.Add('RunID', Format(AITTestSuite.RunID));
        FeatureTelemetryCD.Add('Version', Format(AITTestSuite.Version));
        FeatureTelemetryCD.Add('No. of test method lines', Format(AITTestMethodLine.Count()));
        FeatureTelemetry.LogUptake('0000NEW', FeatureNameLbl, Enum::"Feature Uptake Status"::"Set up", FeatureTelemetryCD);

        AITTestMethodLine.ModifyAll(Status, AITTestMethodLine.Status::" ", true);

        if AITTestMethodLine.FindSet() then
            repeat
                RunAITestLine(AITTestMethodLine, true);
            until AITTestMethodLine.Next() = 0;

        AITRunHistory."Test Suite Code" := AITTestSuite.Code;
        AITRunHistory.Version := AITTestSuite.Version;
        AITRunHistory.Tag := AITTestSuite.Tag;
        AITRunHistory.Insert();
    end;

    internal procedure RunAITestLine(AITTestMethodLine: Record "AIT Test Method Line"; IsExecutedFromTestSuiteHeader: Boolean)
    var
        AITTestSuite: Record "AIT Test Suite";
        TestRunnerProgressDialog: Codeunit "Test Runner - Progress Dialog";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        TelemetryCustomDimensions: Dictionary of [Text, Text];
        EmptyGuid: Guid;
    begin
        if not IsExecutedFromTestSuiteHeader then begin
            AITTestSuite.Get(AITTestMethodLine."Test Suite Code");
            AITTestSuite.Version += 1;
            AITTestSuite.Modify(true);

            // Log the feature telemetry when executed from the test method line
            TelemetryCustomDimensions.Add('Version', Format(AITTestSuite.Version));
            FeatureTelemetry.LogUptake('0000NEX', GetFeatureName(), Enum::"Feature Uptake Status"::"Set up", TelemetryCustomDimensions);
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

            // Log the feature telemetry when execution from the test method line has completed
            if not IsExecutedFromTestSuiteHeader then begin
                AITTestMethodLine.SetRange("Version Filter", AITTestSuite.Version);
                AITTestMethodLine.CalcFields("No. of Tests Executed", "No. of Tests Passed", "Total Duration (ms)");
                TelemetryCustomDimensions := GetFeatureUsedInsights(EmptyGuid, AITTestSuite.Version, AITTestMethodLine."No. of Tests Executed", AITTestMethodLine."No. of Tests Passed", AITTestMethodLine."Total Duration (ms)");
                FeatureTelemetry.LogUptake('0000NEY', GetFeatureName(), Enum::"Feature Uptake Status"::Used, TelemetryCustomDimensions);
            end;
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

    internal procedure CancelRun(var AITTestSuite: Record "AIT Test Suite")
    var
        AITTestMethodLine: Record "AIT Test Method Line";
    begin
        if not Confirm(ConfirmCancelQst) then
            exit;

        AITTestMethodLine.SetRange("Test Suite Code", AITTestSuite."Code");
        AITTestMethodLine.ModifyAll(Status, AITTestMethodLine.Status::Cancelled, true);
        AITTestSuite.Status := AITTestSuite.Status::Completed;
        AITTestSuite."No. of Tests Running" := 0;
        AITTestSuite."Ended at" := CurrentDateTime();
        AITTestSuite.Modify(true);
    end;

    internal procedure SetRunStatus(var AITTestSuite: Record "AIT Test Suite"; AITTestSuiteStatus: Enum "AIT Test Suite Status")
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        TelemetryCustomDimensions: Dictionary of [Text, Text];
    begin
        if AITTestSuiteStatus <> AITTestSuiteStatus::Running then
            AITTestSuite."Ended at" := CurrentDateTime();

        AITTestSuite.Status := AITTestSuiteStatus;
        AITTestSuite.Modify(true);
        Commit();

        // Log feature telemetry when execution from the test suite header has completed
        if AITTestSuite.Status = AITTestSuite.Status::Completed then begin
            AITTestSuite.CalcFields("No. of Tests Executed", "No. of Tests Passed", "Total Duration (ms)");
            TelemetryCustomDimensions := GetFeatureUsedInsights(AITTestSuite.RunID, AITTestSuite.Version, AITTestSuite."No. of Tests Executed", AITTestSuite."No. of Tests Passed", AITTestSuite."Total Duration (ms)");
            FeatureTelemetry.LogUptake('0000NEZ', FeatureNameLbl, Enum::"Feature Uptake Status"::Used, TelemetryCustomDimensions);
        end;
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
        AITLogEntry."Tokens Consumed" := AITTestRunIteration.GetAITokenUsedByLastTestMethodLine();
        AITLogEntry."No. of Turns" := AITTestRunIteration.GetNumberOfTurnsForLastTestMethodLine();
        AITLogEntry."No. of Turns Passed" := AITTestRunIteration.GetNumberOfTurnsPassedForLastTestMethodLine();
        AITLogEntry."Test Method Line Accuracy" := AITTestRunIteration.GetAccuracyForLastTestMethodLine();
        AITLogEntry.Insert(true);

        Commit();
        AITTestRunIteration.AddToNoOfLogEntriesInserted();
    end;

    local procedure GetFeatureUsedInsights(RunId: Guid; Version: Integer; NoOfTestsExecuted: Integer; NoOfTestsPassed: Integer; TotalDurationInMs: Integer) TelemetryCustomDimensions: Dictionary of [Text, Text];
    begin
        if not IsNullGuid(RunId) then
            TelemetryCustomDimensions.Add('RunID', Format(RunId));
        TelemetryCustomDimensions.Add('Version', Format(Version));
        TelemetryCustomDimensions.Add('NoOfTestsExecuted', Format(NoOfTestsExecuted));
        TelemetryCustomDimensions.Add('NoOfTestsPassed', Format(NoOfTestsPassed));
        TelemetryCustomDimensions.Add('TotalDurationInMs', Format(TotalDurationInMs));
    end;

    internal procedure GetTurnsAsText(var AITTestMethodLine: Record "AIT Test Method Line"): Text
    begin
        AITTestMethodLine.CalcFields("No. of Turns Passed", "No. of Turns");
        exit(StrSubstNo(TurnsLbl, AITTestMethodLine."No. of Turns Passed", AITTestMethodLine."No. of Turns"));
    end;

    internal procedure GetTurnsAsText(var AITLogEntry: Record "AIT Log Entry"): Text
    begin
        exit(StrSubstNo(TurnsLbl, AITLogEntry."No. of Turns Passed", AITLogEntry."No. of Turns"));
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

    procedure LookupTestMethodLine(TestSuiteCode: Code[100]; var LineNoFilter: Text; var LineNo: Integer)
    var
        AITTestMethodLine: Record "AIT Test Method Line";
        AITTestMethodLines: Page "AIT Test Method Lines Lookup";
    begin
        AITTestMethodLine.SetRange("Test Suite Code", TestSuiteCode);

        AITTestMethodLines.SetTableView(AITTestMethodLine);
        AITTestMethodLines.LookupMode(true);

        if AITTestMethodLines.RunModal() <> Action::LookupOK then
            exit;

        AITTestMethodLines.GetRecord(AITTestMethodLine);

        AITTestMethodLine.CalcFields("Codeunit Name");
        LineNoFilter := StrSubstNo(LineNoFilterLbl, AITTestMethodLine."Codeunit ID", AITTestMethodLine."Codeunit Name", AITTestMethodLine."Input Dataset");
        LineNo := AITTestMethodLine."Line No.";
    end;

    internal procedure GetFeatureName(): Text
    begin
        exit(FeatureNameLbl);
    end;

    internal procedure DownloadTestSummary(var AITLogEntries: Record "AIT Log Entry")
    var
        AITResults: Report "AIT Test Summary";
        ResultsTempBlob: Codeunit "Temp Blob";
        ResultsOutStream: OutStream;
        ResultsInStream: InStream;
        FilenameTxt: Text;
    begin
        if not AITLogEntries.FindFirst() then
            Error(EmptyLogEntriesErr);

        ResultsTempBlob.CreateOutStream(ResultsOutStream);

        AITResults.SetTableView(AITLogEntries);
        AITResults.SaveAs('', ReportFormat::Excel, ResultsOutStream);

        FilenameTxt := StrSubstNo(SummaryFileNameLbl, AITLogEntries."Test Suite Code");
        ResultsTempBlob.CreateInStream(ResultsInStream);
        DownloadFromStream(ResultsInStream, DownloadResultsLbl, '', 'xlsx', FilenameTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"AIT Test Suite", OnBeforeDeleteEvent, '', false, false)]
    local procedure DeleteLinesOnDeleteAITTestSuite(var Rec: Record "AIT Test Suite"; RunTrigger: Boolean)
    var
        AITTestMethodLine: Record "AIT Test Method Line";
        AITLogEntry: Record "AIT Log Entry";
        AITRunHistory: Record "AIT Run History";
    begin
        if Rec.IsTemporary() then
            exit;

        AITTestMethodLine.SetRange("Test Suite Code", Rec."Code");
        AITTestMethodLine.DeleteAll(true);

        AITLogEntry.SetRange("Test Suite Code", Rec."Code");
        AITLogEntry.DeleteAll(true);

        AITRunHistory.SetRange("Test Suite Code", Rec."Code");
        AITRunHistory.DeleteAll(true);
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