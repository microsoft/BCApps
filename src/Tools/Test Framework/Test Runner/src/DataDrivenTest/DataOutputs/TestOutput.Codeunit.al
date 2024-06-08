// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

codeunit 130461 "Test Output"
{
    SingleInstance = true;
    Permissions = tabledata "Test Output" = RMID;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Test Runner - Mgt", 'OnBeforeTestMethodRun', '', false, false)]
    local procedure UpdateTestDataBeforeTestMethodRun(CodeunitID: Integer; CodeunitName: Text[30]; FunctionName: Text[128]; FunctionTestPermissions: TestPermissions; var CurrentTestMethodLine: Record "Test Method Line")
    var
        TestInput: Codeunit "Test Input";
    begin
        Clear(this.CurrentTestJson);
        this.InitializeBeforeTestRun(CodeunitID, FunctionName, TestInput.GetTestInputName(), CurrentTestMethodLine);
    end;

    local procedure InitializeBeforeTestRun(CodeunitID: Integer; TestName: Text; TestInputName: Text; var CurrentTestMethodLine: Record "Test Method Line")
    var
        TestJsonCodeunit: Codeunit "Test Output Json";
        CurrentTestOutputJson: Codeunit "Test Output Json";
    begin
        if not this.TestJsonInitialized then begin
            this.GlobalTestJson := TestJsonCodeunit;
            this.GlobalTestJson.Initialize();
            this.TestJsonInitialized := true;
        end;

        CurrentTestOutputJson := this.GlobalTestJson.ReplaceElement(this.GetUniqueTestName(CodeunitID, TestName, CurrentTestMethodLine."Line No.", TestInputName), '{}');
        CurrentTestOutputJson.Add(this.TestNameLbl, TestName);
        CurrentTestOutputJson.Add(this.LineNumberLbl, Format(CurrentTestMethodLine."Line No.", 0, 9));
        if TestInputName <> '' then
            CurrentTestOutputJson.Add(this.TestInputNameLbl, TestInputName);
        this.CurrentTestJson := CurrentTestOutputJson.Add(this.TestOutputLbl, '');
    end;

    procedure TestData(): Codeunit "Test Output Json"
    begin
        exit(this.CurrentTestJson);
    end;

    procedure GetAllTestOutput(): Codeunit "Test Output Json"
    begin
        exit(this.GlobalTestJson);
    end;

    procedure ResetOutput()
    begin
        Clear(this.GlobalTestJson);
        Clear(this.CurrentTestJson);
        this.TestJsonInitialized := false;
    end;

    procedure DownloadTestOutput()
    begin
        this.GetAllTestOutput().DownloadToFile();
    end;

    procedure ShowTestOutputs()
    var
        TempTestOutput: Record "Test Output" temporary;
        TestOutput: Text;
    begin
        TestOutput := this.GetAllTestOutput().ToText();
        this.ParseTestOutput(TestOutput, TempTestOutput);
        Page.Run(Page::"Test Outputs", TempTestOutput);
    end;

    local procedure ParseTestOutput(TestOutput: Text; var TempTestOutput: Record "Test Output" temporary)
    var
        TestJson: JsonObject;
        TestMethodJsonToken: JsonToken;
    begin
        TempTestOutput.Reset();
        if not TempTestOutput.IsEmpty() then
            TempTestOutput.DeleteAll();

        if TestOutput = '' then
            exit;

        TestJson.ReadFrom(TestOutput);
        foreach TestMethodJsonToken in TestJson.Values() do
            this.ParseTestOutputJson(TestMethodJsonToken.AsObject(), TempTestOutput);
    end;

    local procedure ParseTestOutputJson(CodeunitJsonToken: JsonObject; var TempTestOutput: Record "Test Output" temporary)
    var
        JsonTokenProperty: JsonToken;
        TestOutputTxt: Text;
    begin
        Clear(TempTestOutput);
        if CodeunitJsonToken.Get(this.TestNameLbl, JsonTokenProperty) then
#pragma warning disable AA0139
            TempTestOutput."Method Name" := JsonTokenProperty.AsValue().AsText();
#pragma warning restore AA0139

        if CodeunitJsonToken.Get(this.LineNumberLbl, JsonTokenProperty) then
            Evaluate(TempTestOutput."Line No.", JsonTokenProperty.AsValue().AsText());

        if CodeunitJsonToken.Get(this.TestInputNameLbl, JsonTokenProperty) then
#pragma warning disable AA0139
            TempTestOutput."Data Input" := JsonTokenProperty.AsValue().AsText();
#pragma warning restore AA0139

        TempTestOutput.Insert();
        if CodeunitJsonToken.Get(this.TestOutputLbl, JsonTokenProperty) then begin
            JsonTokenProperty.WriteTo(TestOutputTxt);
            TempTestOutput.SetOutput(TestOutputTxt);
            TempTestOutput.Modify();
        end;
    end;

    local procedure GetUniqueTestName(CodeunitID: Integer; TestName: Text; LineNumber: Integer; DataInput: Text): Text
    begin
        if DataInput = '' then
            exit(StrSubstNo(this.UniqueNameFormatShorterLbl, Format(CodeunitID, 0, 9), Format(LineNumber, 0, 9), TestName));

        exit(StrSubstNo(this.UniqueNameFormatLongerLbl, Format(CodeunitID, 0, 9), Format(LineNumber, 0, 9), TestName, DataInput));
    end;

    var
        CurrentTestJson: Codeunit "Test Output Json";
        GlobalTestJson: Codeunit "Test Output Json";
        TestJsonInitialized: Boolean;
        TestNameLbl: Label 'testName', Locked = true;
        LineNumberLbl: Label 'lineNumber', Locked = true;
        TestInputNameLbl: Label 'testInput', Locked = true;
        TestOutputLbl: Label 'testOutput', Locked = true;
        UniqueNameFormatShorterLbl: Label '%1-%2-%3', Locked = true;
        UniqueNameFormatLongerLbl: Label '%1-%2-%3-%4', Locked = true;
}