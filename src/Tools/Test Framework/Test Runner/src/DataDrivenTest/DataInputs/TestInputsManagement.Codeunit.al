// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

codeunit 130458 "Test Inputs Management"
{
    EventSubscriberInstance = Manual;

    procedure AssignDataDrivenTest(var TestMethodLine: Record "Test Method Line"; var DataInput: Record "Test Input")
    var
        ALTestSuite: Record "AL Test Suite";
        TempTestMethodLine: Record "Test Method Line" temporary;
        ExistingTestMethodLine: Record "Test Method Line";
        CurrentLineNo: Integer;
    begin
        TestMethodLine.TestField("Line Type", TestMethodLine."Line Type"::Codeunit);
        DataInput.ReadIsolation := IsolationLevel::ReadUncommitted;
        if not DataInput.FindSet() then
            exit;

        ExistingTestMethodLine.SetRange("Test Suite", TestMethodLine."Test Suite");
        ExistingTestMethodLine.SetCurrentKey("Line No.");
        ExistingTestMethodLine.Ascending(false);
        if not ExistingTestMethodLine.FindLast() then
            CurrentLineNo := ExistingTestMethodLine."Line No." + GetIncrement()
        else
            CurrentLineNo := GetIncrement();

        ALTestSuite.Get(TestMethodLine."Test Suite");

        repeat
            TempTestMethodLine.TransferFields(TestMethodLine);
            TempTestMethodLine."Line No." := CurrentLineNo;
            CurrentLineNo += GetIncrement();
            TempTestMethodLine."Data Input" := DataInput.Name;
            TempTestMethodLine.Insert();
            InsertTestMethodLines(TempTestMethodLine, ALTestSuite);
            TempTestMethodLine.DeleteAll();
        until DataInput.Next() = 0;

        TestMethodLine.Delete(true)
    end;

    procedure UploadAndImportDataInputsFromJson(var ALTestSuite: Record "AL Test Suite")
    var
        DummyTestInput: Record "Test Input" temporary;
        TempTestInput: Record "Test Input" temporary;
        TempTestMethodLine: Record "Test Method Line" temporary;
        TestInputInStream: InStream;
        FileName: Text;
        InputText: Text;
    begin
        DummyTestInput."Test Input".CreateInStream(TestInputInStream);
        UploadIntoStream(ChooseFileLbl, '', '', FileName, TestInputInStream);
        TestInputInStream.Read(InputText);
        ParseDataInputs(InputText, ALTestSuite);
    end;

    procedure ImportDataInputsFromText(ALTestSuite: Record "AL Test Suite"; DataInputText: Text)
    begin
        ParseDataInputs(DataInputText, ALTestSuite);
    end;

    procedure ImportTestDefinitions(var ALTestSuite: Record "AL Test Suite"; TestDefinitionsText: Text)
    var
        DummyTestInput: Record "Test Input" temporary;
        TempTestMethodLine: Record "Test Method Line" temporary;
        TestInputInStream: InStream;
        InputText: Text;
    begin
        DummyTestInput."Test Input".CreateInStream(TestInputInStream);
        TestInputInStream.Read(InputText);
        ParseDataDrivenTestDefinition(InputText, TempTestMethodLine, ALTestSuite);
        InsertTestMethodLines(TempTestMethodLine, ALTestSuite);
    end;

    procedure UploadAndImportTestDefinitions(var ALTestSuite: Record "AL Test Suite")
    var
        DummyTestInput: Record "Test Input" temporary;
        TempTestInput: Record "Test Input" temporary;
        TempTestMethodLine: Record "Test Method Line" temporary;
        TestInputInStream: InStream;
        FileName: Text;
        InputText: Text;
    begin
        DummyTestInput."Test Input".CreateInStream(TestInputInStream);
        UploadIntoStream(ChooseFileLbl, '', '', FileName, TestInputInStream);
        TestInputInStream.Read(InputText);

        ParseDataDrivenTestDefinition(InputText, TempTestMethodLine, ALTestSuite);
        InsertTestMethodLines(TempTestMethodLine, ALTestSuite);
    end;

    local procedure ParseDataInputs(TestData: Text; var ALTestSuite: Record "AL Test Suite")
    var
        DataInputJsonObject: JsonObject;
        DataOnlyTestInputs: JsonToken;
        DataOnlyTestInputsArray: JsonArray;
    begin
        DataOnlyTestInputsArray.ReadFrom(TestData);
        InsertDataInputsFromJsonArray(ALTestSuite, DataOnlyTestInputsArray);
    end;

    local procedure ParseDataDrivenTestDefinition(InputText: Text; var TempTestMethodLine: Record "Test Method Line" temporary; var ALTestSuite: Record "AL Test Suite")
    var
        DataDrivenTestJsonObject: JsonObject;
        DataDrivenTestDefinition: JsonToken;
        DataDrivenTestDefinitionArray: JsonArray;
        DataDrivenTestDefinitionJsonToken: JsonToken;
        I: Integer;
    begin
        DataDrivenTestJsonObject.ReadFrom(InputText);
        if not DataDrivenTestJsonObject.Get(DataDrivenTestsTok, DataDrivenTestDefinition) then
            exit;

        DataDrivenTestDefinitionArray := DataDrivenTestDefinition.AsArray();

        for I := 0 to DataDrivenTestDefinitionArray.Count() - 1 do begin
            DataDrivenTestDefinitionArray.Get(I, DataDrivenTestDefinitionJsonToken);
            ParseTestMethods(DataDrivenTestDefinitionJsonToken.AsObject(), ALTestSuite, TempTestMethodLine);
        end;
    end;

    local procedure ParseTestMethods(DataDrivenTestJsonObject: JsonObject; var ALTestSuite: Record "AL Test Suite"; var TempTestMethodLine: Record "Test Method Line" temporary)
    var
        NewTempTestMethodLine: Record "Test Method Line" temporary;
        TestInput: Record "Test Input";
        CodeunitIDToken: JsonToken;
        CodeunitNameToken: JsonToken;
        CodeunitName: Text;
        DataInputsToken: JsonToken;
        DataInputsArray: JsonArray;
        DataInputToken: JsonToken;
        DataInputName: Text;
        TestMethodName: Text;
        TestMethodsArrayToken: JsonToken;
        TestMethodsArray: JsonArray;
        TestMethodToken: JsonToken;
        I: Integer;
        TestMethods: List of [Text];
        DataInputs: List of [Text];
    begin
        if TempTestMethodLine.FindLast() then
            NewTempTestMethodLine."Line No." := TempTestMethodLine."Line No." + GetIncrement()
        else
            NewTempTestMethodLine."Line No." := GetIncrement();

        NewTempTestMethodLine."Test Suite" := ALTestSuite.Name;

        DataDrivenTestJsonObject.Get(CodeunitIdTok, CodeunitIDToken);
        NewTempTestMethodLine."Test Codeunit" := CodeunitIDToken.AsValue().AsInteger();

        DataDrivenTestJsonObject.Get(CodeunitNameTok, CodeunitNameToken);
        NewTempTestMethodLine.Name := CodeunitNameToken.AsValue().AsText();

        if DataDrivenTestJsonObject.Get(TestMethodTok, TestMethodsArrayToken) then begin
            TestMethodsArray := TestMethodsArrayToken.AsArray();
            for I := 0 to TestMethodsArray.Count() - 1 do begin
                TestMethodsArray.Get(I, TestMethodToken);
                TestMethods.Add(TestMethodToken.AsValue().AsText());
            end;
        end else
            TestMethods.Add(AllTok);

        DataDrivenTestJsonObject.Get(DataInputsTok, DataInputsToken);
        DataInputsArray := DataInputsToken.AsArray();
        for I := 0 to DataInputsArray.Count() - 1 do begin
            DataInputsArray.Get(I, DataInputToken);
            if not TestInput.Get(ALTestSuite.Name, DataInputToken.AsValue().AsText()) then
                Error(DataInputNotFoundErr, DataInputToken.AsValue().AsText());
            DataInputs.Add(DataInputToken.AsValue().AsText());
        end;

        foreach DataInputName in DataInputs do begin
            foreach TestMethodName in TestMethods do begin
                NewTempTestMethodLine."Line No." += GetIncrement();
                if TestMethodName <> AllTok then begin
                    NewTempTestMethodLine.Function := TestMethodName;
                    NewTempTestMethodLine."Line Type" := NewTempTestMethodLine."Line Type"::Function;
                end else
                    NewTempTestMethodLine."Line Type" := NewTempTestMethodLine."Line Type"::Codeunit;

                NewTempTestMethodLine."Data Input" := DataInputName;
                TempTestMethodLine.TransferFields(NewTempTestMethodLine);
                TempTestMethodLine.Insert();
            end;
        end;
    end;

    local procedure InsertDataInputsFromJsonArray(var ALTestSuite: Record "AL Test Suite"; var DataOnlyTestInputsArray: JsonArray)
    var
        TestInputJsonToken: JsonToken;
        I: Integer;
    begin
        for I := 0 to DataOnlyTestInputsArray.Count() - 1 do begin
            DataOnlyTestInputsArray.Get(I, TestInputJsonToken);
            InsertDataInputLine(TestInputJsonToken.AsObject(), ALTestSuite);
        end;
    end;

    local procedure InsertDataInputLine(DataOnlyTestInput: JsonObject; var ALTestSuite: Record "AL Test Suite")
    var
        TestInput: Record "Test Input";
        DataNameJsonToken: JsonToken;
        DescriptionJsonToken: JsonToken;
        TestInputJsonToken: JsonToken;
        TestInputText: Text;
    begin
        TestInput."Test Input Group" := ALTestSuite.Name;

        if not DataOnlyTestInput.Get(TestInputTok, TestInputJsonToken) then
            TestInputJsonToken := DataOnlyTestInput.AsToken()
        else begin
            if DataOnlyTestInput.Get(DataNameTok, DataNameJsonToken) then
                TestInput.Name := CopyStr(DataNameJsonToken.AsValue().AsText(), 1, MaxStrLen(TestInput.Name));

            if DataOnlyTestInput.Get(DescriptionTok, DescriptionJsonToken) then
                TestInput.Description := CopyStr(DescriptionJsonToken.AsValue().AsText(), 1, MaxStrLen(TestInput.Description))
        end;

        if TestInput.Name = '' then
            AssingTestInputName(TestInput, ALTestSuite);

        if TestInput.Description = '' then
            TestInput.Description := TestInput.Name;

        TestInput.Insert(true);

        TestInputJsonToken.WriteTo(TestInputText);
        TestInput.SetInput(TestInput, TestInputText);
    end;

    procedure InsertTestMethodLines(var TempTestMethodLine: Record "Test Method Line" temporary; var ALTestSuite: Record "AL Test Suite")
    var
        ExpandDataDrivenTests: Codeunit "Expand Data Driven Tests";
        TestSuiteManagement: Codeunit "Test Suite Mgt.";
        TestMethodLine: Record "Test Method Line";
        CodeunitIds: List of [Integer];
        CodeunitID: Integer;
    begin
        TempTestMethodLine.Reset();
        if not TempTestMethodLine.FindSet() then
            exit;

        repeat
            if not (CodeunitIds.Contains(TempTestMethodLine."Test Codeunit")) then
                CodeunitIds.Add(TempTestMethodLine."Test Codeunit");
        until TempTestMethodLine.Next() = 0;

        ExpandDataDrivenTests.SetDataDrivenTests(TempTestMethodLine);
        BindSubscription(ExpandDataDrivenTests);
        foreach CodeunitID in CodeUnitIds do
            TestSuiteManagement.SelectTestMethodsByRange(ALTestSuite, Format(CodeunitID, 0, 9));
    end;

    local procedure GetIncrement(): Integer
    begin
        exit(10000);
    end;

    local procedure AssingTestInputName(var TestInput: Record "Test Input"; var ALTestSuite: Record "AL Test Suite")
    var
        LastTestInput: Record "Test Input";
    begin
        LastTestInput.SetRange("Test Input Group", ALTestSuite.Name);
        LastTestInput.SetFilter(Name, TestInputNameTok + '*');
        LastTestInput.SetCurrentKey(Name);
        LastTestInput.Ascending(true);
        LastTestInput.ReadIsolation := IsolationLevel::ReadUncommitted;
        if not LastTestInput.FindLast() then
            TestInput.Name := PadStr(TestInputNameTok, 12, '0')
        else
            TestInput.Name := LastTestInput.Name;

        TestInput.Name := IncStr(TestInput.Name);
    end;

    var
        CodeunitIdTok: Label 'codeunitId', Locked = true;
        TestMethodTok: Label 'method', Locked = true;
        DataNameTok: Label 'name', Locked = true;
        DescriptionTok: Label 'description', Locked = true;
        TestInputTok: Label 'testInput', Locked = true;
        DataDrivenTestsTok: Label 'dataDrivenTests', Locked = true;
        CodeunitNameTok: Label 'codeunitName', Locked = true;
        DataInputsTok: Label 'dataInputs', Locked = true;
        ChooseFileLbl: Label 'Choose a file to import';
        TestInputNameTok: Label 'Input-', Locked = true;
        AllTok: Label 'All', Locked = true;
        DataInputNotFoundErr: Label 'Data input not found: %1. Make sure that you import the data inputs first.';
}