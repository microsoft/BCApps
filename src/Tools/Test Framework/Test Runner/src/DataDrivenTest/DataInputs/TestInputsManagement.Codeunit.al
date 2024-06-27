// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

codeunit 130458 "Test Inputs Management"
{
    EventSubscriberInstance = Manual;

    procedure SelectTestGroupsAndExpandTestLine(var TestMethodLine: Record "Test Method Line")

    var
        TestInputGroup: Record "Test Input Group";
        TestInput: Record "Test Input";
        TestInputsManagement: Codeunit "Test Inputs Management";
        TestInputGroups: Page "Test Input Groups";
    begin
        if TestMethodLine."Line Type" <> TestMethodLine."Line Type"::Codeunit then
            Error(this.LineTypeMustBeCodeunitErr);

        TestInputGroups.LookupMode(true);
        if not (TestInputGroups.RunModal() = Action::LookupOK) then
            exit;

        TestInputGroups.SetSelectionFilter(TestInputGroup);

        TestInputGroup.MarkedOnly(true);
        if not TestInputGroup.FindSet() then
            exit;

        repeat
            TestInput.SetRange("Test Input Group Code", TestInputGroup.Code);
            TestInputsManagement.AssignDataDrivenTest(TestMethodLine, TestInput);
        until TestInputGroup.Next() = 0;

        TestMethodLine.Find();
        TestMethodLine.Delete(true)
    end;

    procedure AssignDataDrivenTest(var TestMethodLine: Record "Test Method Line"; var TestInput: Record "Test Input")
    var
        ALTestSuite: Record "AL Test Suite";
        TempTestMethodLine: Record "Test Method Line" temporary;
        ExistingTestMethodLine: Record "Test Method Line";
        CurrentLineNo: Integer;
    begin
        TestMethodLine.TestField("Line Type", TestMethodLine."Line Type"::Codeunit);
        TestInput.ReadIsolation := IsolationLevel::ReadUncommitted;
        if not TestInput.FindSet() then
            exit;

        ExistingTestMethodLine.SetRange("Test Suite", TestMethodLine."Test Suite");
        ExistingTestMethodLine.SetCurrentKey("Line No.");
        ExistingTestMethodLine.Ascending(false);
        if not ExistingTestMethodLine.FindLast() then
            CurrentLineNo := ExistingTestMethodLine."Line No." + this.GetIncrement()
        else
            CurrentLineNo := this.GetIncrement();

        ALTestSuite.Get(TestMethodLine."Test Suite");

        repeat
            this.TransferToTemporaryTestLine(TempTestMethodLine, ExistingTestMethodLine, CurrentLineNo, TestInput);
            this.InsertTestMethodLines(TempTestMethodLine, ALTestSuite);
            this.UpdateCodeunitTestInputProperties(TempTestMethodLine, TestInput);
            TempTestMethodLine.DeleteAll();
        until TestInput.Next() = 0;
    end;

    local procedure TransferToTemporaryTestLine(var TempTestMethodLine: Record "Test Method Line" temporary; var TestMethodLine: Record "Test Method Line"; var CurrentLineNo: Integer; var TestInput: Record "Test Input")
    begin
        TempTestMethodLine.TransferFields(TestMethodLine);
        TempTestMethodLine."Line No." := CurrentLineNo;
        CurrentLineNo += this.GetIncrement();
        TempTestMethodLine."Data Input Group Code" := TestInput."Test Input Group Code";
        TempTestMethodLine."Data Input" := TestInput.Code;
        TempTestMethodLine.Insert();
    end;

    local procedure UpdateCodeunitTestInputProperties(var TempTestMethodLine: Record "Test Method Line" temporary; var DataInput: Record "Test Input")
    var
        CodeunitTestMethodLine: Record "Test Method Line";
        LastTestMethodLine: Record "Test Method Line";
        TestSuiteManagement: Codeunit "Test Suite Mgt.";
    begin
        LastTestMethodLine.SetRange("Test Suite", TempTestMethodLine."Test Suite");
        LastTestMethodLine.FindLast();
        CodeunitTestMethodLine.SetRange("Test Suite", TempTestMethodLine."Test Suite");
        CodeunitTestMethodLine.SetRange("Line Type", CodeunitTestMethodLine."Line Type"::Codeunit);

        CodeunitTestMethodLine.SetRange("Data Input Group Code", '');
        CodeunitTestMethodLine.SetFilter("Line No.", TestSuiteManagement.GetLineNoFilterForTestCodeunit(LastTestMethodLine));
        CodeunitTestMethodLine.ModifyAll("Data Input Group Code", DataInput."Test Input Group Code");
        CodeunitTestMethodLine.SetRange("Data Input Group Code");

        CodeunitTestMethodLine.SetRange("Data Input", '');
        CodeunitTestMethodLine.ModifyAll("Data Input", DataInput.Code);
    end;

    procedure UploadAndImportDataInputsFromJson()
    var
        TestInputGroup: Record "Test Input Group";
    begin
        this.UploadAndImportDataInputsFromJson(TestInputGroup);
    end;

    procedure UploadAndImportDataInputsFromJson(FileName: Text; TestInputInStream: InStream)
    var
        TestInputGroup: Record "Test Input Group";
        InputText: Text;
    begin
        if not TestInputGroup.Find() then
            this.CreateTestInputGroup(TestInputGroup, FileName);

        if FileName.EndsWith(this.JsonFileExtensionTxt) then begin
            TestInputInStream.Read(InputText);
            this.ParseDataInputs(InputText, TestInputGroup)
        end;

        if FileName.EndsWith(this.JsonlFileExtensionTxt) then
            this.ParseDataInputsJsonl(TestInputInStream, TestInputGroup);
    end;

    procedure UploadAndImportDataInputsFromJson(var TestInputGroup: Record "Test Input Group")
    var
        TempDummyTestInput: Record "Test Input" temporary;
        TestInputInStream: InStream;
        FileName: Text;
    begin
        TempDummyTestInput."Test Input".CreateInStream(TestInputInStream);
        if not UploadIntoStream(this.ChooseFileLbl, '', '', FileName, TestInputInStream) then
            exit;

        this.UploadAndImportDataInputsFromJson(FileName, TestInputInStream);
    end;

    procedure ImportDataInputsFromText(var TestInputGroup: Record "Test Input Group"; DataInputText: Text)
    begin
        this.ParseDataInputs(DataInputText, TestInputGroup);
    end;

    local procedure CreateTestInputGroup(var TestInputGroup: Record "Test Input Group"; FileName: Text)
    begin
#pragma warning disable AA0139
        TestInputGroup.Code := FileName;
        if FileName.Contains('.') then
            TestInputGroup.Code := FileName.Substring(1, FileName.IndexOf('.') - 1);

        TestInputGroup.Description := FileName;
#pragma warning restore AA0139

        TestInputGroup.Insert();
    end;

    local procedure ParseDataInputs(TestData: Text; var TestInputGroup: Record "Test Input Group")
    var
        DataInputJsonObject: JsonObject;
        DataOnlyTestInputsArray: JsonArray;
    begin
        if DataOnlyTestInputsArray.ReadFrom(TestData) then begin
            this.InsertDataInputsFromJsonArray(TestInputGroup, DataOnlyTestInputsArray);
            exit;
        end;

        if DataInputJsonObject.ReadFrom(TestData) then begin
            this.InsertDataInputLine(DataInputJsonObject, TestInputGroup);
            exit;
        end;

        Error(this.CouldNotParseJsonlInputErr);
    end;

    local procedure ParseDataInputsJsonl(var TestInputInStream: InStream; var TestInputGroup: Record "Test Input Group")
    var
        TestInputJsonToken: JsonObject;
        JsonLine: Text;
    begin
        while TestInputInStream.ReadText(JsonLine) > 0 do
            if TestInputJsonToken.ReadFrom(JsonLine) then
                this.InsertDataInputLine(TestInputJsonToken, TestInputGroup)
            else
                Error(this.CouldNotParseJsonlInputErr);
    end;

    local procedure InsertDataInputsFromJsonArray(var TestInputGroup: Record "Test Input Group"; var DataOnlyTestInputsArray: JsonArray)
    var
        TestInputJsonToken: JsonToken;
        I: Integer;
    begin
        for I := 0 to DataOnlyTestInputsArray.Count() - 1 do begin
            DataOnlyTestInputsArray.Get(I, TestInputJsonToken);
            this.InsertDataInputLine(TestInputJsonToken.AsObject(), TestInputGroup);
        end;
    end;

    local procedure InsertDataInputLine(DataOnlyTestInput: JsonObject; var TestInputGroup: Record "Test Input Group")
    var
        TestInput: Record "Test Input";
        DataNameJsonToken: JsonToken;
        DescriptionJsonToken: JsonToken;
        TestInputJsonToken: JsonToken;
        TestInputText: Text;
    begin
        TestInput."Test Input Group Code" := TestInputGroup.Code;

        if not DataOnlyTestInput.Get(this.TestInputTok, TestInputJsonToken) then
            TestInputJsonToken := DataOnlyTestInput.AsToken()
        else begin
            if DataOnlyTestInput.Get(this.DataNameTok, DataNameJsonToken) then
                TestInput.Code := CopyStr(DataNameJsonToken.AsValue().AsText(), 1, MaxStrLen(TestInput.Code));

            if DataOnlyTestInput.Get(this.DescriptionTok, DescriptionJsonToken) then
                TestInput.Description := CopyStr(DescriptionJsonToken.AsValue().AsText(), 1, MaxStrLen(TestInput.Description))
        end;

        if TestInput.Code = '' then
            this.AssignTestInputName(TestInput, TestInputGroup);

        if TestInput.Description = '' then
            TestInput.Description := TestInput.Code;

        TestInput.Insert(true);

        TestInputJsonToken.WriteTo(TestInputText);
        TestInput.SetInput(TestInput, TestInputText);
    end;

    procedure InsertTestMethodLines(var TempTestMethodLine: Record "Test Method Line" temporary; var ALTestSuite: Record "AL Test Suite")
    var
        ExpandDataDrivenTests: Codeunit "Expand Data Driven Tests";
        TestSuiteManagement: Codeunit "Test Suite Mgt.";
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

    local procedure AssignTestInputName(var TestInput: Record "Test Input"; var TestInputGroup: Record "Test Input Group")
    var
        LastTestInput: Record "Test Input";
    begin
        LastTestInput.SetRange("Test Input Group Code", TestInputGroup.Code);
        LastTestInput.SetFilter(Code, this.TestInputNameTok + '*');
        LastTestInput.SetCurrentKey(Code);
        LastTestInput.Ascending(true);
        LastTestInput.ReadIsolation := IsolationLevel::ReadUncommitted;
        if not LastTestInput.FindLast() then
            TestInput.Code := PadStr(this.TestInputNameTok, 12, '0')
        else
            TestInput.Code := LastTestInput.Code;

        TestInput.Code := IncStr(TestInput.Code);
    end;

    var
        DataNameTok: Label 'name', Locked = true;
        DescriptionTok: Label 'description', Locked = true;
        TestInputTok: Label 'testInput', Locked = true;
        ChooseFileLbl: Label 'Choose a file to import';
        TestInputNameTok: Label 'INPUT-', Locked = true;
        CouldNotParseJsonlInputErr: Label 'Could not parse JSONL input';
        LineTypeMustBeCodeunitErr: Label 'Line type must be Codeunit.';
        JsonFileExtensionTxt: Label '.json', Locked = true;
        JsonlFileExtensionTxt: Label '.jsonl', Locked = true;
}