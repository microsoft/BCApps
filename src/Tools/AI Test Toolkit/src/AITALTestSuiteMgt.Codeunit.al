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
    Access = Internal;
    Permissions = tabledata "Test Method Line" = rmid,
                  tabledata "AL Test Suite" = rmid;

    var
        AITTestSuitePrefixLbl: Label 'AIT-', Locked = true;
        RunProcedureOperationLbl: Label 'Run Procedure', Locked = true;

    procedure GetDefaultRunProcedureOperationLbl(): Text
    begin
        exit(this.RunProcedureOperationLbl);
    end;

    procedure AssistEditTestRunner(var AITHeader: Record "AIT Header")
    var
        AllObjWithCaption: Record AllObjWithCaption;
        SelectTestRunner: Page "Select TestRunner";
    begin
        SelectTestRunner.LookupMode := true;
        if SelectTestRunner.RunModal() = ACTION::LookupOK then begin
            SelectTestRunner.GetRecord(AllObjWithCaption);
            AITHeader.Validate("Test Runner Id", AllObjWithCaption."Object ID");
            AITHeader.Modify(true);
        end;
    end;

    procedure UpdateALTestSuite(var AITLine: Record "AIT Line")
    begin
        this.GetOrCreateALTestSuite(AITLine);
        this.RemoveTestMethods(AITLine);
        this.ExpandCodeunit(AITLine);
    end;

    procedure CreateALTestSuite(var AITHeader: Record "AIT Header")
    var
        ALTestSuite: Record "AL Test Suite";
    begin
        if ALTestSuite.Get(AITHeader.Code) then
            ALTestSuite.Delete(true);

        ALTestSuite.Name := AITHeader.Code;
        ALTestSuite."Test Runner Id" := AITHeader."Test Runner Id";
        ALTestSuite.Insert(true);
    end;

    procedure ExpandCodeunit(var AITLine: Record "AIT Line")
    var
        TestInput: Record "Test Input";
    begin
        TestInput.SetRange("Test Input Group Code", AITLine.GetTestInputCode());
        TestInput.ReadIsolation := TestInput.ReadIsolation::ReadUncommitted;
        if not TestInput.FindSet() then
            exit;

        repeat
            this.ExpandCodeunit(AITLine, TestInput);
        until TestInput.Next() = 0;
    end;

    procedure ExpandCodeunit(var AITLine: Record "AIT Line"; var TestInput: Record "Test Input")
    var
        TempTestMethodLine: Record "Test Method Line" temporary;
        ALTestSuite: Record "AL Test Suite";
        TestInputsManagement: Codeunit "Test Inputs Management";
    begin
        ALTestSuite := this.GetOrCreateALTestSuite(AITLine);

        TempTestMethodLine."Line Type" := TempTestMethodLine."Line Type"::Codeunit;
        TempTestMethodLine."Test Codeunit" := AITLine."Codeunit ID";
        TempTestMethodLine."Test Suite" := AITLine."AL Test Suite";
        TempTestMethodLine."Data Input Group Code" := TestInput."Test Input Group Code";
        TempTestMethodLine."Data Input" := TestInput.Code;
        TempTestMethodLine.Insert();

        TestInputsManagement.InsertTestMethodLines(TempTestMethodLine, ALTestSuite);
    end;

    procedure RemoveTestMethods(var AITLine: Record "AIT Line")
    begin
        this.RemoveTestMethods(AITLine, 0, '');
    end;

    procedure RemoveTestMethods(var AITLine: Record "AIT Line"; CodeunitID: Integer; DataInputName: Text[250])
    var
        TestMethodLine: Record "Test Method Line";
    begin
        if CodeunitID > 1 then
            TestMethodLine.SetRange("Test Codeunit", CodeunitID);

        if DataInputName <> '' then
            TestMethodLine.SetRange("Data Input", DataInputName);

        TestMethodLine.ReadIsolation := TestMethodLine.ReadIsolation::ReadUncommitted;
        if TestMethodLine.IsEmpty() then
            exit;

        TestMethodLine.DeleteAll();
        this.RemoveEmptyCodeunitTestLines(this.GetOrCreateALTestSuite(AITLine));
    end;

    procedure RemoveEmptyCodeunitTestLines(ALTestSuite: Record "AL Test Suite")
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

    procedure GetOrCreateALTestSuite(var AITLine: Record "AIT Line"): Record "AL Test Suite"
    var
        AITHeader: Record "AIT Header";
        ALTestSuite: Record "AL Test Suite";
    begin
        if AITLine."AL Test Suite" <> '' then begin
            ALTestSuite.SetFilter(Name, AITLine."AL Test Suite");
            if ALTestSuite.FindFirst() then
                exit(ALTestSuite);
        end;

        if AITLine."AL Test Suite" = '' then begin
            AITLine."AL Test Suite" := this.GetUniqueAITTestSuiteCode();
            AITLine.Modify();
        end;

        ALTestSuite.Name := AITLine."AL Test Suite";
        ALTestSuite.Description := CopyStr(AITLine.Description, 1, MaxStrLen(ALTestSuite.Description));
        AITHeader.ReadIsolation := IsolationLevel::ReadUncommitted;
        if AITHeader.Get(AITLine."AIT Code") then
            ALTestSuite."Test Runner Id" := AITHeader."Test Runner Id";

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
        AITLogEntry.SetLoadFields("AIT Code", "Output Data");
        if AITLogEntry.FindSet(false) then begin
            FileNameTxt := Format(AITLogEntry."AIT Code") + '_' + 'test_output' + '.jsonl';
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