// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Test.Agents.SalesOrderAgent;

using System.TestTools.AITestToolkit;
using System.Utilities;

codeunit 134543 NoSeriesYamlProcessMgt
{
    internal procedure LoadInputDatasets()
    var
        DatasetPaths: List of [Text];
        ResourcePath: Text;
    begin
        Clear(TestsArray);
        DatasetPaths := NavApp.ListResources(GetTestDataResourcesPath());
        foreach ResourcePath in DatasetPaths do
            PrepareAndSetupDataInputAsYaml(ResourcePath);
    end;

    // extract categories from Yaml file and for each category create a jsonl file
    local procedure PrepareAndSetupDataInputAsYaml(FilePath: Text)
    var
        JsonObject: JsonObject;
        FileName: Text;
        ResAsText: Text;
        ResInStream: InStream;
    begin
        // Get the filename from the path
        FileName := FilePath.Substring(FilePath.LastIndexOf('/') + 1);
        FileName := FileName.Remove(FileName.LastIndexOf('.')); //Yaml file name is part of the jsonl file name (yaml file name + category name)
        NavApp.GetResource(FilePath, ResInStream, TextEncoding::UTF8);
        ResInStream.Read(ResAsText);
        JsonObject.ReadFromYaml(ResAsText);
        ProcessDataSetAsJson(JsonObject, FileName);
    end;

    local procedure ProcessDataSetAsJson(JsonObj: JsonObject; FileName: Text)
    var
        JsonTokenTests: JsonToken;
        SetupName: Text;
    begin
        if JsonObj.Get('tests', JsonTokenTests) then begin
            SetupName := GetValueAsText(JsonObj, TestSetupNameLbl);
            ProcessTestFromCategory(JsonTokenTests, SetupName, FileName);
        end;
    end;

    local procedure ProcessTestFromCategory(JsonTokenTests: JsonToken; SetupName: Text; NewFileName: Text)
    var
        AITALTestSuiteMgt: Codeunit "AIT AL Test Suite Mgt";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        InStream: InStream;
        TestDataPerCategoryAsTxt: Text;
    begin
        TestDataPerCategoryAsTxt := GetTestDataPerCategory(JsonTokenTests, SetupName);

        //import dataset as jsonl
        Clear(TempBlob);
        Clear(InStream);
        Clear(OutStream);
        TempBlob.CreateInStream(InStream);
        TempBlob.CreateOutStream(OutStream);
        OutStream.WriteText(TestDataPerCategoryAsTxt);
        AITALTestSuiteMgt.ImportTestInputs(NewFileName + '.jsonl', InStream);
    end;

    local procedure GetTestDataPerCategory(JsonTokenTests: JsonToken; SetupName: Text): Text
    var
        JsonListTests: JsonArray;
        JsonTokenTest: JsonToken;
        JsonObjectTestNew: JsonObject;
        TextBuilder: TextBuilder;
    begin
        JsonListTests := JsonTokenTests.AsArray();

        foreach JsonTokenTest in JsonListTests do begin
            Clear(JsonObjectTestNew);
            ProcessTestFromCategory(JsonTokenTest, JsonObjectTestNew, SetupName);
            TextBuilder.AppendLine(format(JsonObjectTestNew));
        end;

        exit(TextBuilder.ToText());
    end;

    local procedure ProcessTestFromCategory(JsonTokenTest: JsonToken; JsonObjectTestNew: JsonObject; SetupName: Text)
    var
        JsonObjectTest: JsonObject;
        TestLevelSetupName: Text;
    begin
        JsonObjectTest := JsonTokenTest.AsObject();
        JsonObjectTestNew.ReadFrom('{}');

        JsonObjectTestNew.Add('name', GetValueAsText(JsonObjectTest, 'name'));
        JsonObjectTestNew.Add('description', GetValueAsText(JsonObjectTest, 'description'));
        JsonObjectTestNew.Add('input', GetValueAsText(JsonObjectTest, 'input'));

        ProcessTurnFromTest(JsonObjectTest.AsToken(), JsonObjectTestNew);

        TestLevelSetupName := GetValueAsText(JsonObjectTest, TestSetupNameLbl);
        if TestLevelSetupName <> '' then
            SetupName := TestLevelSetupName; //setup name is taken from the test level setup if available
        JsonObjectTestNew.Add(TestSetupNameLbl, SetupName); //setup is added just as a value (name.yaml)    
    end;

    local procedure ProcessTurnFromTest(JsonTokenTurn: JsonToken; JsonObjectTestTurnNew: JsonObject)
    var
        JsonObjectTurn: JsonObject;
        JsonTokenExpected: JsonToken;
    begin
        JsonObjectTurn := JsonTokenTurn.AsObject();

        JsonObjectTurn.Get('expected_data', JsonTokenExpected);
        JsonObjectTurn.Remove('expected_data');

        JsonObjectTestTurnNew.Add('question', JsonObjectTurn);
        JsonObjectTestTurnNew.Add('expected_data', JsonTokenExpected);
    end;

    local procedure GetValueAsText(JObject: JsonObject; AttributeName: Text): Text
    var
        Value: Text;
        JToken: JsonToken;
    begin
        if not JObject.Get(AttributeName, JToken) then
            exit('');

        Value := JToken.AsValue().AsText();
        exit(Value);
    end;

    local procedure GetTestDataResourcesPath(): Text
    begin
        exit('*input_datasets/*.yaml');
    end;

    var
        TestsArray: JsonArray;
        TestSetupNameLbl: Label 'test_setup', Locked = true;
}