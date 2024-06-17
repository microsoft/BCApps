// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.TestTools.TestRunner;
using System.Utilities;
using System.Reflection;

codeunit 149037 "AIT AL Test Suite Mgt"
{
    Permissions = tabledata "Test Method Line" = rmid,
                  tabledata "AL Test Suite" = rmid;

    var
        RunProcedureOperationLbl: Label 'Run Procedure', Locked = true;
        AITTestSuitePrefixLbl: Label 'AIT-', Locked = true;

    internal procedure GetDefaultRunProcedureOperationLbl(): Text
    begin
        exit(this.RunProcedureOperationLbl);
    end;

    internal procedure AssistEditTestRunner(var AITTestSuite: Record "AIT Test Suite")
    var
        AllObjWithCaption: Record AllObjWithCaption;
        SelectTestRunner: Page "Select TestRunner";
    begin
        SelectTestRunner.LookupMode := true;
        if SelectTestRunner.RunModal() = ACTION::LookupOK then begin
            SelectTestRunner.GetRecord(AllObjWithCaption);
            AITTestSuite.Validate("Test Runner Id", AllObjWithCaption."Object ID");
            AITTestSuite.Modify(true);
        end;
    end;

    internal procedure UpdateALTestSuite(var AITTestMethodLine: Record "AIT Test Method Line")
    begin
        this.GetOrCreateALTestSuite(AITTestMethodLine);
        this.RemoveTestMethods(AITTestMethodLine);
        this.ExpandCodeunit(AITTestMethodLine);
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
            this.ExpandCodeunit(AITTestMethodLine, TestInput);
        until TestInput.Next() = 0;
    end;

    internal procedure ExpandCodeunit(var AITTestMethodLine: Record "AIT Test Method Line"; var TestInput: Record "Test Input")
    var
        TempTestMethodLine: Record "Test Method Line" temporary;
        ALTestSuite: Record "AL Test Suite";
        TestInputsManagement: Codeunit "Test Inputs Management";
    begin
        ALTestSuite := this.GetOrCreateALTestSuite(AITTestMethodLine);

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
        this.RemoveTestMethods(AITTestMethodLine, 0, '');
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

        TestMethodLine.DeleteAll();
        this.RemoveEmptyCodeunitTestLines(this.GetOrCreateALTestSuite(AITTestMethodLine));
    end;

    internal procedure RemoveEmptyCodeunitTestLines(ALTestSuite: Record "AL Test Suite")
    var
        TestMethodLine: Record "Test Method Line";
        FunctionTestMethodLine: Record "Test Method Line";
    begin
        TestMethodLine.SetRange("Test Suite", ALTestSuite.Name);
        TestMethodLine.SetRange("Line Type", TestMethodLine."Line Type"::Codeunit);
        TestMethodLine.ReadIsolation := TestMethodLine.ReadIsolation::ReadUncommitted;

        if not TestMethodLine.FindSet() then
            exit;

        repeat
            FunctionTestMethodLine.SetRange("Test Suite", ALTestSuite.Name);
            FunctionTestMethodLine.SetRange("Test Codeunit", TestMethodLine."Test Codeunit");
            FunctionTestMethodLine.SetRange("Line Type", FunctionTestMethodLine."Line Type"::Function);
            FunctionTestMethodLine.ReadIsolation := FunctionTestMethodLine.ReadIsolation::ReadUncommitted;
            if FunctionTestMethodLine.IsEmpty() then
                TestMethodLine.Delete();
        until TestMethodLine.Next() = 0;
    end;

    internal procedure GetOrCreateALTestSuite(var AITTestMethodLine: Record "AIT Test Method Line"): Record "AL Test Suite"
    var
        AITTestSuite: Record "AIT Test Suite";
        ALTestSuite: Record "AL Test Suite";
    begin
        if AITTestMethodLine."AL Test Suite" <> '' then begin
            ALTestSuite.SetFilter(Name, AITTestMethodLine."AL Test Suite");
            if ALTestSuite.FindFirst() then
                exit(ALTestSuite);
        end;

        if AITTestMethodLine."AL Test Suite" = '' then begin
            AITTestMethodLine."AL Test Suite" := this.GetUniqueAITTestSuiteCode();
            AITTestMethodLine.Modify();
        end;

        ALTestSuite.Name := AITTestMethodLine."AL Test Suite";
        ALTestSuite.Description := CopyStr(AITTestMethodLine.Description, 1, MaxStrLen(ALTestSuite.Description));
        AITTestSuite.ReadIsolation := IsolationLevel::ReadUncommitted;
        if AITTestSuite.Get(AITTestMethodLine."Test Suite Code") then
            ALTestSuite."Test Runner Id" := AITTestSuite."Test Runner Id";

        ALTestSuite.Insert(true);
        exit(ALTestSuite);
    end;

    local procedure GetUniqueAITTestSuiteCode(): Code[10]
    var
        ALTestSuite: Record "AL Test Suite";
    begin
        ALTestSuite.SetFilter(Name, this.AITTestSuitePrefixLbl + '*');
        if not ALTestSuite.FindLast() then
            exit(this.AITTestSuitePrefixLbl + '000001');

        exit(IncStr(ALTestSuite.Name))
    end;

    internal procedure DownloadTestOutputFromAITLLogToFile(var AITLogEntry: Record "AIT Log Entry")
    var
        TempBlob: Codeunit "Temp Blob";
        TestOutput: Text;
        FileNameTxt: Text;
        JsonTextBuilder: TextBuilder;
        JsonOutStream: OutStream;
        JsonInStream: InStream;
        NoTestOutputFoundErr: Label 'No Test Output found in the logs';
    begin
        AITLogEntry.SetLoadFields("Test Suite Code", "Output Data");
        if AITLogEntry.FindSet(false) then begin
            FileNameTxt := Format(AITLogEntry."Test Suite Code") + '_' + 'test_output' + '.jsonl';
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
            end
            else
                Error(NoTestOutputFoundErr);
        end;
    end;
}