// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.Reflection;
using System.TestTools.TestRunner;
using System.Utilities;

codeunit 149037 "AIT AL Test Suite Mgt"
{
    Permissions = tabledata "Test Method Line" = rmid,
                  tabledata "AL Test Suite" = rmid;

    var
        RunProcedureOperationTok: Label 'Run Procedure', Locked = true;
        AITTestSuitePrefixTok: Label 'AIT-', Locked = true;

    internal procedure GetDefaultRunProcedureOperationLbl(): Text
    begin
        exit(RunProcedureOperationTok);
    end;

    internal procedure AssistEditTestRunner(var AITTestSuite: Record "AIT Test Suite")
    var
        CodeunitMetadata: Record "Codeunit Metadata";
        SelectTestRunner: Page "Select TestRunner";
    begin
        SelectTestRunner.LookupMode := true;
        if SelectTestRunner.RunModal() = Action::LookupOK then begin
            SelectTestRunner.GetRecord(CodeunitMetadata);
            AITTestSuite.Validate("Test Runner Id", CodeunitMetadata.ID);
            AITTestSuite.Modify(true);
        end;
    end;

    internal procedure UpdateALTestSuite(var AITTestMethodLine: Record "AIT Test Method Line")
    begin
        GetOrCreateALTestSuite(AITTestMethodLine);
        RemoveTestMethods(AITTestMethodLine);
        ExpandCodeunit(AITTestMethodLine);
    end;

    internal procedure CreateALTestSuite(var AITTestSuite: Record "AIT Test Suite")
    var
        ALTestSuite: Record "AL Test Suite";
    begin
        if ALTestSuite.Get(AITTestSuite.Code) then
            ALTestSuite.Delete(true);

        ALTestSuite.Name := AITTestSuite.Code;
        ALTestSuite."Test Runner Id" := AITTestSuite."Test Runner Id";
        ALTestSuite.Insert(true);
    end;

    internal procedure ExpandCodeunit(var AITTestMethodLine: Record "AIT Test Method Line")
    var
        TestInput: Record "Test Input";
    begin
        TestInput.SetRange("Test Input Group Code", AITTestMethodLine.GetTestInputCode());
        TestInput.ReadIsolation := TestInput.ReadIsolation::ReadUncommitted;
        if not TestInput.FindSet() then
            exit;

        repeat
            ExpandCodeunit(AITTestMethodLine, TestInput);
        until TestInput.Next() = 0;
    end;

    internal procedure ExpandCodeunit(var AITTestMethodLine: Record "AIT Test Method Line"; var TestInput: Record "Test Input")
    var
        TempTestMethodLine: Record "Test Method Line" temporary;
        ALTestSuite: Record "AL Test Suite";
        TestInputsManagement: Codeunit "Test Inputs Management";
    begin
        ALTestSuite := GetOrCreateALTestSuite(AITTestMethodLine);

        TempTestMethodLine."Line Type" := TempTestMethodLine."Line Type"::Codeunit;
        TempTestMethodLine."Test Codeunit" := AITTestMethodLine."Codeunit ID";
        TempTestMethodLine."Test Suite" := AITTestMethodLine."AL Test Suite";
        TempTestMethodLine."Data Input Group Code" := TestInput."Test Input Group Code";
        TempTestMethodLine."Data Input" := TestInput.Code;
        TempTestMethodLine.Insert();

        TestInputsManagement.InsertTestMethodLines(TempTestMethodLine, ALTestSuite);
    end;

    internal procedure RemoveTestMethods(var AITTestMethodLine: Record "AIT Test Method Line")
    begin
        RemoveTestMethods(AITTestMethodLine, 0, '');
    end;

    internal procedure RemoveTestMethods(var AITTestMethodLine: Record "AIT Test Method Line"; CodeunitID: Integer; DataInputName: Text[250])
    var
        TestMethodLine: Record "Test Method Line";
    begin
        TestMethodLine.SetRange("Test Suite", AITTestMethodLine."AL Test Suite");
        if CodeunitID > 1 then
            TestMethodLine.SetRange("Test Codeunit", CodeunitID);

        if DataInputName <> '' then
            TestMethodLine.SetRange("Data Input", DataInputName);

        TestMethodLine.ReadIsolation := TestMethodLine.ReadIsolation::ReadUncommitted;
        if TestMethodLine.IsEmpty() then
            exit;

        TestMethodLine.DeleteAll(true);
        RemoveEmptyCodeunitTestLines(GetOrCreateALTestSuite(AITTestMethodLine));
    end;

    internal procedure RemoveEmptyCodeunitTestLines(ALTestSuite: Record "AL Test Suite")
    var
        TestMethodLine: Record "Test Method Line";
    begin
        TestMethodLine.SetRange("Test Suite", ALTestSuite.Name);
        TestMethodLine.SetRange("Line Type", TestMethodLine."Line Type"::Codeunit);
        TestMethodLine.SetRange("No. of Functions", 0);
        TestMethodLine.ReadIsolation := TestMethodLine.ReadIsolation::ReadUncommitted;
        TestMethodLine.DeleteAll(true);
    end;

    internal procedure GetOrCreateALTestSuite(var AITTestMethodLine: Record "AIT Test Method Line"): Record "AL Test Suite"
    var
        AITTestSuite: Record "AIT Test Suite";
        ALTestSuite: Record "AL Test Suite";
    begin
        if AITTestMethodLine."AL Test Suite" <> '' then begin
            ALTestSuite.SetFilter(Name, AITTestMethodLine."AL Test Suite");
            ALTestSuite.ReadIsolation := ALTestSuite.ReadIsolation::ReadUncommitted;
            if ALTestSuite.FindFirst() then begin
                AssignTestRunnerToTestSuite(CopyStr(AITTestMethodLine."Test Suite Code", 1, MaxStrLen(AITTestSuite.Code)), ALTestSuite);
                ALTestSuite.Modify(true);
                exit(ALTestSuite);
            end;
        end;

        if AITTestMethodLine."AL Test Suite" = '' then begin
            AITTestMethodLine."AL Test Suite" := GetUniqueAITTestSuiteCode();
            AITTestMethodLine.Modify(true);
        end;

        ALTestSuite.Name := AITTestMethodLine."AL Test Suite";
        ALTestSuite.Description := CopyStr(AITTestMethodLine.Description, 1, MaxStrLen(ALTestSuite.Description));
        AssignTestRunnerToTestSuite(CopyStr(AITTestMethodLine."Test Suite Code", 1, MaxStrLen(AITTestSuite.Code)), ALTestSuite);

        ALTestSuite.Insert(true);
        exit(ALTestSuite);
    end;

    local procedure AssignTestRunnerToTestSuite(TestSuiteCode: Code[10]; var ALTestSuite: Record "AL Test Suite")
    var
        AITTestSuite: Record "AIT Test Suite";
    begin
        AITTestSuite.ReadIsolation := IsolationLevel::ReadUncommitted;
        AITTestSuite.SetLoadFields("Test Runner Id");
        if AITTestSuite.Get(TestSuiteCode) then
            ALTestSuite."Test Runner Id" := AITTestSuite."Test Runner Id";
    end;

    local procedure GetUniqueAITTestSuiteCode(): Code[10]
    var
        ALTestSuite: Record "AL Test Suite";
    begin
        ALTestSuite.SetFilter(Name, AITTestSuitePrefixTok + '*');
        ALTestSuite.ReadIsolation := ALTestSuite.ReadIsolation::UpdLock;
        ALTestSuite.SetLoadFields(Name);
        if not ALTestSuite.FindLast() then
            exit(AITTestSuitePrefixTok + '000001');

        exit(IncStr(ALTestSuite.Name))
    end;

    internal procedure DownloadTestOutputFromLogToFile(var AITLogEntry: Record "AIT Log Entry")
    var
        TempBlob: Codeunit "Temp Blob";
        TestOutput: Text;
        FileNameTxt: Text;
        JsonTextBuilder: TextBuilder;
        JsonOutStream: OutStream;
        JsonInStream: InStream;
        NoTestOutputFoundErr: Label 'No Test Output found in the logs';
        TestOutputFileNameTxt: Label '%1_test_output.jsonl', Locked = true;
    begin
        AITLogEntry.SetLoadFields("Test Suite Code", "Output Data");
        AITLogEntry.ReadIsolation := IsolationLevel::ReadUncommitted;
        if AITLogEntry.FindSet() then begin
            FileNameTxt := StrSubstNo(TestOutputFileNameTxt, AITLogEntry."Test Suite Code");
            repeat
                TestOutput := AITLogEntry.GetOutputBlob();
                if TestOutput <> '' then
                    JsonTextBuilder.AppendLine(TestOutput);
            until AITLogEntry.Next() = 0;

            if JsonTextBuilder.Length > 0 then begin
                TempBlob.CreateOutStream(JsonOutStream, TextEncoding::UTF8);
                JsonOutStream.WriteText(JsonTextBuilder.ToText());
                TempBlob.CreateInStream(JsonInStream, TextEncoding::UTF8);
                DownloadFromStream(JsonInStream, '', '', '.jsonl', FileNameTxt);
            end else
                Error(NoTestOutputFoundErr);
        end;
    end;

    procedure GetTestOutputAsJson(var AITLogEntry: Record "AIT Log Entry"): JsonArray
    var
        OutputJsonArray: JsonArray;
        OutputJson: JsonObject;
        TestOutput: Text;
    begin
        AITLogEntry.SetLoadFields("Test Suite Code", "Output Data");
        AITLogEntry.ReadIsolation := IsolationLevel::ReadUncommitted;
        if AITLogEntry.FindSet() then
            repeat
                TestOutput := AITLogEntry.GetOutputBlob();
                if TestOutput <> '' then begin
                    OutputJson.ReadFrom(TestOutput);
                    OutputJsonArray.Add(OutputJson);
                end;
            until AITLogEntry.Next() = 0;

        exit(OutputJsonArray);
    end;

    /// <summary>
    /// Import the Test Input Dataset from an InStream of a dataset in a supported format.
    /// Overwrite the dataset if the dataset with same filename is already imported by the same app
    /// Error if the dataset with the same filename is created by a different app
    /// </summary>
    /// <param name="DatasetFileName">The file name of the dataset file which will be used in the description of the dataset.</param>
    /// <param name="DatasetInStream">The InStream of the dataset file.</param>
    procedure ImportTestInputs(DatasetFileName: Text; var DatasetInStream: InStream)
    var
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        ImportTestInputs(DatasetFileName, DatasetInStream, CallerModuleInfo, 0, DatasetFileName);
    end;

    /// <summary>
    /// Import the Test Input Dataset from an InStream of a dataset in a supported format with a specific language.
    /// Overwrite the dataset if the dataset with same filename is already imported by the same app
    /// Error if the dataset with the same filename is created by a different app
    /// </summary>
    /// <param name="DatasetFileName">The file name of the dataset file which will be used in the description of the dataset.</param>
    /// <param name="DatasetInStream">The InStream of the dataset file.</param>
    /// <param name="LanguageID">The language ID to use for the dataset import.</param>
    procedure ImportTestInputs(DatasetFileName: Text; var DatasetInStream: InStream; LanguageID: Integer)
    var
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        ImportTestInputs(DatasetFileName, DatasetInStream, CallerModuleInfo, LanguageID, DatasetFileName);
    end;

    /// <summary>
    /// Import the Test Input Dataset from an InStream of a dataset in a supported format with a specific language.
    /// Overwrite the dataset if the dataset with same filename is already imported by the same app
    /// Error if the dataset with the same filename is created by a different app
    /// </summary>
    /// <param name="DatasetFileName">The file name of the dataset file which will be used in the description of the dataset.</param>
    /// <param name="DatasetInStream">The InStream of the dataset file.</param>
    /// <param name="LanguageID">The language ID to use for the dataset import.</param>
    /// <param name="Name">The name to use for the dataset import.</param>
    procedure ImportTestInputs(DatasetFileName: Text; var DatasetInStream: InStream; LanguageID: Integer; GroupName: Text)
    var
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        ImportTestInputs(DatasetFileName, DatasetInStream, CallerModuleInfo, LanguageID, GroupName);
    end;

    local procedure ImportTestInputs(DatasetFileName: Text; var DatasetInStream: InStream; CallerModuleInfo: ModuleInfo; LanguageID: Integer; GroupName: Text)
    var
        TestInputGroup: Record "Test Input Group";
        TestInputsManagement: Codeunit "Test Inputs Management";
        EmptyGuid: Guid;
        SameDatasetNameErr: Label 'The test input dataset %1 with the same file name already exists. The dataset was uploaded %2. Please rename the current dataset or delete the existing dataset.', Comment = '%1 = test input dataset Name, %2 = "from the UI" or "by the app id: {app_id}';
        SourceOfTheDatasetIsUILbl: Label 'from the UI';
        SourceOfTheDatasetIsAppIdLbl: Label 'previously by the app id: %1 and now with %2', Comment = '%1 = previous app id, %2 = current app id';
    begin
        // Check if the dataset with the same filename exists
        TestInputGroup.SetLoadFields(Code, "Imported by AppId");

        if TestInputGroup.Get(TestInputsManagement.GetTestInputGroupCodeFromFileName(DatasetFileName)) then
            if TestInputGroup."Imported by AppId" = CallerModuleInfo.Id then
                TestInputGroup.Delete(true) // Overwrite the dataset
            else
                case TestInputGroup."Imported by AppId" of
                    EmptyGuid:
                        Error(SameDatasetNameErr, DatasetFileName, SourceOfTheDatasetIsUILbl)
                    else
                        Error(SameDatasetNameErr, DatasetFileName, StrSubstNo(SourceOfTheDatasetIsAppIdLbl, TestInputGroup."Imported by AppId", CallerModuleInfo.Id));
                end;

        TestInputsManagement.UploadAndImportDataInputs(DatasetFileName, DatasetInStream, CallerModuleInfo.Id, LanguageID, GroupName);
    end;

    /// <summary>
    /// Import the AI Test Suite using InStream of the XML file. Use this to import XML from resource files during installation of the test app.
    /// Skip if the same suite is already imported by the same app
    /// Error if the same suite is already imported with a different XML
    /// Error if the same suite is already imported by a different app
    /// </summary>
    /// <param name="XMLSetupInStream">The InStream of the test suite XML file.</param>
    procedure ImportAITestSuite(var XMLSetupInStream: InStream)
    var
        AITTestSuiteImportExport: XmlPort "AIT Test Suite Import/Export";
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        AITTestSuiteImportExport.SetCallerModuleInfo(CallerModuleInfo);
        AITTestSuiteImportExport.SetMD5HashForTheImportedXML(XMLSetupInStream);
        AITTestSuiteImportExport.SetSource(XMLSetupInStream);
        AITTestSuiteImportExport.Import();
    end;
}