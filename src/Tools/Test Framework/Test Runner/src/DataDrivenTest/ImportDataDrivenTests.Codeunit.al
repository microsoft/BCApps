codeunit 130458 "Import Data Driven Test"
{
    EventSubscriberInstance = Manual;

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
    var
        DummyTestInput: Record "Test Input" temporary;
        TestInputInStream: InStream;
        InputText: Text;
    begin
        DummyTestInput."Test Input".CreateInStream(TestInputInStream);
        TestInputInStream.Read(InputText);
        ParseDataInputs(InputText, ALTestSuite);
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
        DataInputJsonObject.ReadFrom(TestData);
        if not DataInputJsonObject.Get(DataDrivenTestDataTok, DataOnlyTestInputs) then
            exit;

        DataOnlyTestInputsArray := DataOnlyTestInputs.AsArray();
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
        TestInputJsonToken: JsonToken;
        TestInputText: Text;
    begin
        TestInput."Test Suite" := ALTestSuite.Name;
        DataOnlyTestInput.Get(DataNameTok, DataNameJsonToken);
        TestInput.Name := CopyStr(DataNameJsonToken.AsValue().AsText(), 1, MaxStrLen(TestInput.Name));
        TestInput.Insert();

        if DataOnlyTestInput.Get(TestInputTok, TestInputJsonToken) then begin
            TestInputJsonToken.WriteTo(TestInputText);
            TestInput.SetInput(TestInput, TestInputText);
        end;
    end;

    local procedure InsertTestMethodLines(var TempTestMethodLine: Record "Test Method Line" temporary; var ALTestSuite: Record "AL Test Suite")
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

    var
        CodeunitIdTok: Label 'codeunitId', Locked = true;
        TestMethodTok: Label 'method', Locked = true;
        DataNameTok: Label 'name', Locked = true;
        TestInputTok: Label 'testInput', Locked = true;
        DataDrivenTestDataTok: Label 'dataDrivenTestData', Locked = true;
        DataDrivenTestsTok: Label 'dataDrivenTests', Locked = true;
        CodeunitNameTok: Label 'codeunitName', Locked = true;
        DataInputsTok: Label 'dataInputs', Locked = true;
        ChooseFileLbl: Label 'Choose a file to import';
        AllTok: Label 'All', Locked = true;
        DataInputNotFoundErr: Label 'Data input not found: %1. Make sure that you import the data inputs first.';
}