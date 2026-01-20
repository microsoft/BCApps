// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.TestTools.TestRunner;

/// <summary>
/// Management codeunit for the No-Code test creation and dataset editing.
/// Handles schema parsing, query field loading, and round-trip editing of Test Input records.
/// </summary>
codeunit 149064 "AIT No Code Mgt"
{
    Access = Internal;

    #region Dataset Round-Trip Methods

    /// <summary>
    /// Loads all Test Input records for a dataset into temporary tables for editing.
    /// </summary>
    procedure LoadDatasetFromTestInputs(DatasetCode: Code[100]; var TempTestLine: Record "AIT Test Input Line" temporary; var TempValidation: Record "AIT Validation Entry" temporary)
    var
        TestInput: Record "Test Input";
        LineNo: Integer;
    begin
        TempTestLine.Reset();
        TempTestLine.DeleteAll();
        TempValidation.Reset();
        TempValidation.DeleteAll();

        TestInput.SetRange("Test Input Group Code", DatasetCode);
        if not TestInput.FindSet() then
            exit;

        LineNo := 10000;
        repeat
            ParseTestInputToTempRecords(TestInput, DatasetCode, LineNo, TempTestLine, TempValidation);
            LineNo += 10000;
        until TestInput.Next() = 0;
    end;

    /// <summary>
    /// Saves temporary table records back to Test Input records.
    /// </summary>
    procedure SaveDatasetToTestInputs(DatasetCode: Code[100]; var TempTestLine: Record "AIT Test Input Line" temporary; var TempValidation: Record "AIT Validation Entry" temporary)
    var
        TestInputGroup: Record "Test Input Group";
        TestInput: Record "Test Input";
        ExistingTestInput: Record "Test Input";
        TestJson: JsonObject;
        TestJsonText: Text;
        TestOutStream: OutStream;
        ProcessedCodes: List of [Code[100]];
    begin
        // Ensure the group exists
        if not TestInputGroup.Get(DatasetCode) then begin
            TestInputGroup.Init();
            TestInputGroup.Code := DatasetCode;
            TestInputGroup.Description := CopyStr(DatasetCode, 1, MaxStrLen(TestInputGroup.Description));
            TestInputGroup.Insert(true);
        end;

        // Process each test line
        TempTestLine.Reset();
        if TempTestLine.FindSet() then
            repeat
                TestJson := BuildTestJsonFromTempRecords(TempTestLine, TempValidation);
                TestJson.WriteTo(TestJsonText);

                // Use test name as the Test Input Code
                if not TestInput.Get(DatasetCode, CopyStr(TempTestLine."Test Name", 1, 100)) then begin
                    TestInput.Init();
                    TestInput."Test Input Group Code" := DatasetCode;
                    TestInput.Code := CopyStr(TempTestLine."Test Name", 1, MaxStrLen(TestInput.Code));
                    TestInput.Description := CopyStr(TempTestLine.Description, 1, MaxStrLen(TestInput.Description));
                    TestInput.Insert(true);
                end else
                    TestInput.Description := CopyStr(TempTestLine.Description, 1, MaxStrLen(TestInput.Description));

                TestInput."Test Input".CreateOutStream(TestOutStream, TextEncoding::UTF8);
                TestOutStream.WriteText(TestJsonText);
                TestInput.Modify(true);

                ProcessedCodes.Add(TestInput.Code);
            until TempTestLine.Next() = 0;

        // Delete Test Inputs that are no longer in the temp table
        ExistingTestInput.SetRange("Test Input Group Code", DatasetCode);
        if ExistingTestInput.FindSet() then
            repeat
                if not ProcessedCodes.Contains(ExistingTestInput.Code) then
                    ExistingTestInput.Delete(true);
            until ExistingTestInput.Next() = 0;
    end;

    /// <summary>
    /// Parses a single Test Input record into temporary test line and validation records.
    /// </summary>
    local procedure ParseTestInputToTempRecords(TestInput: Record "Test Input"; DatasetCode: Code[100]; LineNo: Integer; var TempTestLine: Record "AIT Test Input Line" temporary; var TempValidation: Record "AIT Validation Entry" temporary)
    var
        TestJson: JsonObject;
        TestInStream: InStream;
        TestJsonText: Text;
        QueryJson: JsonObject;
        ExpectedDataJson: JsonObject;
        Token: JsonToken;
    begin
        TestInput.CalcFields("Test Input");
        if not TestInput."Test Input".HasValue() then
            exit;

        TestInput."Test Input".CreateInStream(TestInStream, TextEncoding::UTF8);
        TestInStream.ReadText(TestJsonText);

        if not TestJson.ReadFrom(TestJsonText) then
            exit;

        // Create test line
        TempTestLine.Init();
        TempTestLine."Dataset Code" := DatasetCode;
        TempTestLine."Line No." := LineNo;

        // Parse name
        if TestJson.Get('name', Token) then
            if Token.IsValue() then
                TempTestLine."Test Name" := CopyStr(Token.AsValue().AsText(), 1, MaxStrLen(TempTestLine."Test Name"));

        // Parse description
        if TestJson.Get('description', Token) then
            if Token.IsValue() then
                TempTestLine.Description := CopyStr(Token.AsValue().AsText(), 1, MaxStrLen(TempTestLine.Description));

        // Parse test_setup (can be string reference or object)
        if TestJson.Get('test_setup', Token) then
            if Token.IsValue() then
                TempTestLine."Test Setup Reference" := CopyStr(Token.AsValue().AsText(), 1, MaxStrLen(TempTestLine."Test Setup Reference"));

        // Parse query
        if TestJson.Get('query', Token) then
            if Token.IsObject() then begin
                QueryJson := Token.AsObject();
                TempTestLine.SetQueryJson(QueryJson);
            end;

        // Parse expected_data
        if TestJson.Get('expected_data', Token) then
            if Token.IsObject() then begin
                ExpectedDataJson := Token.AsObject();
                TempTestLine.SetExpectedDataJson(ExpectedDataJson);
                ParseExpectedDataToValidations(ExpectedDataJson, DatasetCode, LineNo, TempValidation);
            end;

        TempTestLine.Insert();
    end;

    /// <summary>
    /// Parses expected_data JSON into validation entry records.
    /// </summary>
    local procedure ParseExpectedDataToValidations(ExpectedDataJson: JsonObject; DatasetCode: Code[100]; LineNo: Integer; var TempValidation: Record "AIT Validation Entry" temporary)
    var
        Token: JsonToken;
        ValidateArray: JsonArray;
        ValidateToken: JsonToken;
        ValidateObj: JsonObject;
        EntryNo: Integer;
    begin
        EntryNo := 1;

        // Parse validate_records_db
        if ExpectedDataJson.Get('validate_records_db', Token) then
            if Token.IsArray() then begin
                ValidateArray := Token.AsArray();
                foreach ValidateToken in ValidateArray do begin
                    ValidateObj := ValidateToken.AsObject();
                    CreateValidationFromJson(ValidateObj, "AIT Validation Type"::DatabaseRecords, DatasetCode, LineNo, EntryNo, TempValidation);
                    EntryNo += 1;
                end;
            end;

        // Parse validate_records_msg
        if ExpectedDataJson.Get('validate_records_msg', Token) then
            if Token.IsArray() then begin
                ValidateArray := Token.AsArray();
                foreach ValidateToken in ValidateArray do begin
                    ValidateObj := ValidateToken.AsObject();
                    CreateValidationFromJson(ValidateObj, "AIT Validation Type"::MessageContent, DatasetCode, LineNo, EntryNo, TempValidation);
                    EntryNo += 1;
                end;
            end;

        // Parse validation_prompt
        if ExpectedDataJson.Get('validation_prompt', Token) then
            if Token.IsValue() then begin
                TempValidation.Init();
                TempValidation."Dataset Code" := DatasetCode;
                TempValidation."Line No." := LineNo;
                TempValidation."Entry No." := EntryNo;
                TempValidation."Validation Type" := "AIT Validation Type"::ValidationPrompt;
                TempValidation.SetValidationPrompt(Token.AsValue().AsText());
                TempValidation.Insert();
                EntryNo += 1;
            end;

        // Parse intervention_request_type
        if ExpectedDataJson.Get('intervention_request_type', Token) then
            if Token.IsValue() then begin
                TempValidation.Init();
                TempValidation."Dataset Code" := DatasetCode;
                TempValidation."Line No." := LineNo;
                TempValidation."Entry No." := EntryNo;
                TempValidation."Validation Type" := "AIT Validation Type"::InterventionRequest;
                case Token.AsValue().AsText() of
                    'Assistance':
                        TempValidation."Intervention Type" := TempValidation."Intervention Type"::Assistance;
                    'ReviewRecord':
                        TempValidation."Intervention Type" := TempValidation."Intervention Type"::ReviewRecord;
                    'ReviewMessage':
                        TempValidation."Intervention Type" := TempValidation."Intervention Type"::ReviewMessage;
                end;
                TempValidation.Insert();
            end;
    end;

    local procedure CreateValidationFromJson(ValidateObj: JsonObject; ValidationType: Enum "AIT Validation Type"; DatasetCode: Code[100]; LineNo: Integer; EntryNo: Integer; var TempValidation: Record "AIT Validation Entry" temporary)
    var
        Token: JsonToken;
        FieldsArray: JsonArray;
    begin
        TempValidation.Init();
        TempValidation."Dataset Code" := DatasetCode;
        TempValidation."Line No." := LineNo;
        TempValidation."Entry No." := EntryNo;
        TempValidation."Validation Type" := ValidationType;

        if ValidateObj.Get('table', Token) then
            if Token.IsValue() then
                TempValidation."Table Name" := CopyStr(Token.AsValue().AsText(), 1, MaxStrLen(TempValidation."Table Name"));

        if ValidateObj.Get('count', Token) then
            if Token.IsValue() then
                TempValidation."Expected Count" := Token.AsValue().AsInteger();

        if ValidateObj.Get('name_prefix', Token) then
            if Token.IsValue() then
                TempValidation."Name Prefix" := CopyStr(Token.AsValue().AsText(), 1, MaxStrLen(TempValidation."Name Prefix"));

        if ValidateObj.Get('primary_name_field', Token) then
            if Token.IsValue() then
                TempValidation."Primary Name Field" := CopyStr(Token.AsValue().AsText(), 1, MaxStrLen(TempValidation."Primary Name Field"));

        if ValidateObj.Get('fields', Token) then
            if Token.IsArray() then begin
                FieldsArray := Token.AsArray();
                TempValidation.SetFieldValidations(FieldsArray);
            end;

        TempValidation.Insert();
    end;

    /// <summary>
    /// Builds a test JSON object from temporary records.
    /// </summary>
    local procedure BuildTestJsonFromTempRecords(var TempTestLine: Record "AIT Test Input Line" temporary; var TempValidation: Record "AIT Validation Entry" temporary): JsonObject
    var
        TempLineValidation: Record "AIT Validation Entry" temporary;
        TestJson: JsonObject;
        QueryJson: JsonObject;
        ExpectedDataJson: JsonObject;
    begin
        TestJson.Add('name', TempTestLine."Test Name");

        if TempTestLine.Description <> '' then
            TestJson.Add('description', TempTestLine.Description);

        if TempTestLine."Test Setup Reference" <> '' then
            TestJson.Add('test_setup', TempTestLine."Test Setup Reference");

        QueryJson := TempTestLine.GetQueryJson();
        if QueryJson.Keys.Count > 0 then
            TestJson.Add('query', QueryJson);

        // Build expected_data from validations
        TempLineValidation.Copy(TempValidation, true);
        TempLineValidation.SetRange("Dataset Code", TempTestLine."Dataset Code");
        TempLineValidation.SetRange("Line No.", TempTestLine."Line No.");

        if TempLineValidation.FindSet() then
            repeat
                TempLineValidation.BuildValidationJson(ExpectedDataJson);
            until TempLineValidation.Next() = 0;

        if ExpectedDataJson.Keys.Count > 0 then
            TestJson.Add('expected_data', ExpectedDataJson);

        exit(TestJson);
    end;

    /// <summary>
    /// Builds YAML text from temporary records.
    /// </summary>
    procedure BuildDatasetYaml(var TempTestLine: Record "AIT Test Input Line" temporary; var TempValidation: Record "AIT Validation Entry" temporary): Text
    var
        DatasetJson: JsonObject;
        TestsArray: JsonArray;
        TestJson: JsonObject;
        JsonText: Text;
    begin
        TempTestLine.Reset();
        if TempTestLine.FindSet() then
            repeat
                TestJson := BuildTestJsonFromTempRecords(TempTestLine, TempValidation);
                TestsArray.Add(TestJson);
            until TempTestLine.Next() = 0;

        DatasetJson.Add('tests', TestsArray);
        DatasetJson.WriteTo(JsonText);

        // For now, return JSON (YAML conversion would require additional library)
        // The output is valid YAML since JSON is a subset of YAML
        exit(JsonText);
    end;

    /// <summary>
    /// Parses YAML/JSON text into temporary records.
    /// </summary>
    procedure ParseDatasetYaml(YamlText: Text; DatasetCode: Code[100]; var TempTestLine: Record "AIT Test Input Line" temporary; var TempValidation: Record "AIT Validation Entry" temporary)
    var
        DatasetJson: JsonObject;
        Token: JsonToken;
        TestsArray: JsonArray;
        TestToken: JsonToken;
        TestObj: JsonObject;
        LineNo: Integer;
    begin
        TempTestLine.Reset();
        TempTestLine.DeleteAll();
        TempValidation.Reset();
        TempValidation.DeleteAll();

        // Try to parse as JSON first (JSON is valid YAML)
        if not DatasetJson.ReadFrom(YamlText) then
            exit;

        if not DatasetJson.Get('tests', Token) then
            exit;

        if not Token.IsArray() then
            exit;

        TestsArray := Token.AsArray();
        LineNo := 10000;

        foreach TestToken in TestsArray do begin
            TestObj := TestToken.AsObject();
            ParseTestJsonToTempRecords(TestObj, DatasetCode, LineNo, TempTestLine, TempValidation);
            LineNo += 10000;
        end;
    end;

    local procedure ParseTestJsonToTempRecords(TestJson: JsonObject; DatasetCode: Code[100]; LineNo: Integer; var TempTestLine: Record "AIT Test Input Line" temporary; var TempValidation: Record "AIT Validation Entry" temporary)
    var
        QueryJson: JsonObject;
        ExpectedDataJson: JsonObject;
        Token: JsonToken;
    begin
        TempTestLine.Init();
        TempTestLine."Dataset Code" := DatasetCode;
        TempTestLine."Line No." := LineNo;

        if TestJson.Get('name', Token) then
            if Token.IsValue() then
                TempTestLine."Test Name" := CopyStr(Token.AsValue().AsText(), 1, MaxStrLen(TempTestLine."Test Name"));

        if TestJson.Get('description', Token) then
            if Token.IsValue() then
                TempTestLine.Description := CopyStr(Token.AsValue().AsText(), 1, MaxStrLen(TempTestLine.Description));

        if TestJson.Get('test_setup', Token) then
            if Token.IsValue() then
                TempTestLine."Test Setup Reference" := CopyStr(Token.AsValue().AsText(), 1, MaxStrLen(TempTestLine."Test Setup Reference"));

        if TestJson.Get('query', Token) then
            if Token.IsObject() then begin
                QueryJson := Token.AsObject();
                TempTestLine.SetQueryJson(QueryJson);
            end;

        if TestJson.Get('expected_data', Token) then
            if Token.IsObject() then begin
                ExpectedDataJson := Token.AsObject();
                TempTestLine.SetExpectedDataJson(ExpectedDataJson);
                ParseExpectedDataToValidations(ExpectedDataJson, DatasetCode, LineNo, TempValidation);
            end;

        TempTestLine.Insert();
    end;

    #endregion

    #region Schema Methods

    /// <summary>
    /// Loads query schema fields from the schema definition into a temporary table.
    /// </summary>
    procedure LoadQuerySchemaFields(FeatureCode: Code[50]; var TempQuerySchemaField: Record "AIT Query Schema Field" temporary)
    var
        AITQuerySchema: Record "AIT Query Schema";
        SchemaJson: JsonObject;
        FieldsToken: JsonToken;
        FieldsArray: JsonArray;
        FieldToken: JsonToken;
        FieldObject: JsonObject;
        FieldOrder: Integer;
    begin
        TempQuerySchemaField.Reset();
        TempQuerySchemaField.DeleteAll();

        if not AITQuerySchema.Get(FeatureCode) then
            exit;

        SchemaJson := AITQuerySchema.GetSchemaJson();
        if not SchemaJson.Get('fields', FieldsToken) then
            exit;

        FieldsArray := FieldsToken.AsArray();
        FieldOrder := 0;

        foreach FieldToken in FieldsArray do begin
            FieldOrder += 1;
            FieldObject := FieldToken.AsObject();

            TempQuerySchemaField.Init();
            TempQuerySchemaField."Feature Code" := FeatureCode;
            TempQuerySchemaField."Field Order" := FieldOrder;
            TempQuerySchemaField."Field Name" := CopyStr(GetJsonText(FieldObject, 'name'), 1, MaxStrLen(TempQuerySchemaField."Field Name"));
            TempQuerySchemaField."Field Label" := CopyStr(GetJsonText(FieldObject, 'label'), 1, MaxStrLen(TempQuerySchemaField."Field Label"));
            TempQuerySchemaField."Field Type" := ParseFieldType(GetJsonText(FieldObject, 'type'));
            TempQuerySchemaField."Is Required" := GetJsonBoolean(FieldObject, 'required');
            TempQuerySchemaField."Field Description" := CopyStr(GetJsonText(FieldObject, 'description'), 1, MaxStrLen(TempQuerySchemaField."Field Description"));
            TempQuerySchemaField."Default Value" := CopyStr(GetJsonText(FieldObject, 'default'), 1, MaxStrLen(TempQuerySchemaField."Default Value"));
            TempQuerySchemaField.Insert();
        end;
    end;

    /// <summary>
    /// Builds a query JSON object from the filled schema fields.
    /// </summary>
    procedure BuildQueryJsonFromFields(var TempQuerySchemaField: Record "AIT Query Schema Field" temporary): JsonObject
    var
        QueryJson: JsonObject;
        ListArray: JsonArray;
    begin
        TempQuerySchemaField.Reset();
        if not TempQuerySchemaField.FindSet() then
            exit(QueryJson);

        repeat
            case TempQuerySchemaField."Field Type" of
                TempQuerySchemaField."Field Type"::Text:
                    if TempQuerySchemaField."Text Value" <> '' then
                        QueryJson.Add(TempQuerySchemaField."Field Name", TempQuerySchemaField."Text Value");
                TempQuerySchemaField."Field Type"::MultilineText:
                    if TempQuerySchemaField.GetMultilineValue() <> '' then
                        QueryJson.Add(TempQuerySchemaField."Field Name", TempQuerySchemaField.GetMultilineValue());
                TempQuerySchemaField."Field Type"::Boolean:
                    QueryJson.Add(TempQuerySchemaField."Field Name", TempQuerySchemaField."Boolean Value");
                TempQuerySchemaField."Field Type"::Integer:
                    if TempQuerySchemaField."Integer Value" <> 0 then
                        QueryJson.Add(TempQuerySchemaField."Field Name", TempQuerySchemaField."Integer Value");
                TempQuerySchemaField."Field Type"::FileList:
                    begin
                        ListArray := TempQuerySchemaField.GetListValue();
                        if ListArray.Count > 0 then
                            QueryJson.Add(TempQuerySchemaField."Field Name", ListArray);
                    end;
            end;
        until TempQuerySchemaField.Next() = 0;

        exit(QueryJson);
    end;

    /// <summary>
    /// Populates schema fields from an existing query JSON.
    /// </summary>
    procedure PopulateFieldsFromQueryJson(QueryJson: JsonObject; var TempQuerySchemaField: Record "AIT Query Schema Field" temporary)
    var
        FieldToken: JsonToken;
    begin
        TempQuerySchemaField.Reset();
        if not TempQuerySchemaField.FindSet() then
            exit;

        repeat
            if QueryJson.Get(TempQuerySchemaField."Field Name", FieldToken) then
                case TempQuerySchemaField."Field Type" of
                    TempQuerySchemaField."Field Type"::Text:
                        if FieldToken.IsValue() then
                            TempQuerySchemaField."Text Value" := CopyStr(FieldToken.AsValue().AsText(), 1, MaxStrLen(TempQuerySchemaField."Text Value"));
                    TempQuerySchemaField."Field Type"::MultilineText:
                        if FieldToken.IsValue() then
                            TempQuerySchemaField.SetMultilineValue(FieldToken.AsValue().AsText());
                    TempQuerySchemaField."Field Type"::Boolean:
                        if FieldToken.IsValue() then
                            TempQuerySchemaField."Boolean Value" := FieldToken.AsValue().AsBoolean();
                    TempQuerySchemaField."Field Type"::Integer:
                        if FieldToken.IsValue() then
                            TempQuerySchemaField."Integer Value" := FieldToken.AsValue().AsInteger();
                    TempQuerySchemaField."Field Type"::FileList:
                        if FieldToken.IsArray() then
                            TempQuerySchemaField.SetListValue(FieldToken.AsArray());
                end;
            TempQuerySchemaField.Modify();
        until TempQuerySchemaField.Next() = 0;
    end;

    /// <summary>
    /// Creates a Test Input record in the Test Runner's Test Input table from an AIT Test Input.
    /// </summary>
    procedure ExportToTestInput(AITTestInput: Record "AIT Test Input")
    var
        TestInputGroup: Record "Test Input Group";
        TestInput: Record "Test Input";
        TestInputJson: JsonObject;
        TestInputText: Text;
        TestInputOutStream: OutStream;
    begin
        // Ensure the dataset/group exists
        if not TestInputGroup.Get(AITTestInput."Dataset Code") then begin
            TestInputGroup.Init();
            TestInputGroup.Code := AITTestInput."Dataset Code";
            TestInputGroup.Description := CopyStr(AITTestInput."Dataset Code", 1, MaxStrLen(TestInputGroup.Description));
            TestInputGroup.Insert(true);
        end;

        // Build the test input JSON
        TestInputJson := AITTestInput.BuildTestInputJson();
        TestInputJson.WriteTo(TestInputText);

        // Create or update the Test Input record
        if not TestInput.Get(AITTestInput."Dataset Code", AITTestInput."Test Name") then begin
            TestInput.Init();
            TestInput."Test Input Group Code" := AITTestInput."Dataset Code";
            TestInput.Code := CopyStr(AITTestInput."Test Name", 1, MaxStrLen(TestInput.Code));
            TestInput.Description := CopyStr(AITTestInput.Description, 1, MaxStrLen(TestInput.Description));
            TestInput.Insert(true);
        end;

        // Write the JSON to the Test Input blob field
        TestInput."Test Input".CreateOutStream(TestInputOutStream, TextEncoding::UTF8);
        TestInputOutStream.WriteText(TestInputText);
        TestInput.Modify(true);
    end;

    /// <summary>
    /// Validates that required fields are filled.
    /// </summary>
    procedure ValidateRequiredFields(var TempQuerySchemaField: Record "AIT Query Schema Field" temporary; var ErrorMessage: Text): Boolean
    var
        MissingFields: TextBuilder;
        HasValue: Boolean;
    begin
        TempQuerySchemaField.Reset();
        TempQuerySchemaField.SetRange("Is Required", true);
        if not TempQuerySchemaField.FindSet() then
            exit(true);

        repeat
            HasValue := false;
            case TempQuerySchemaField."Field Type" of
                TempQuerySchemaField."Field Type"::Text:
                    HasValue := TempQuerySchemaField."Text Value" <> '';
                TempQuerySchemaField."Field Type"::MultilineText:
                    HasValue := TempQuerySchemaField.GetMultilineValue() <> '';
                TempQuerySchemaField."Field Type"::Boolean:
                    HasValue := true; // Boolean always has a value
                TempQuerySchemaField."Field Type"::Integer:
                    HasValue := true; // Integer always has a value (even if 0)
                TempQuerySchemaField."Field Type"::FileList:
                    HasValue := TempQuerySchemaField.GetListValue().Count > 0;
            end;

            if not HasValue then begin
                if MissingFields.Length > 0 then
                    MissingFields.Append(', ');
                MissingFields.Append(TempQuerySchemaField."Field Label");
            end;
        until TempQuerySchemaField.Next() = 0;

        if MissingFields.Length > 0 then begin
            ErrorMessage := StrSubstNo(MissingFieldsErr, MissingFields.ToText());
            exit(false);
        end;

        exit(true);
    end;

    /// <summary>
    /// Builds the complete dataset JSON with tests array.
    /// </summary>
    procedure BuildDatasetJson(DatasetCode: Code[100]): JsonObject
    var
        AITTestInputLine: Record "AIT Test Input Line";
        DatasetJson: JsonObject;
        TestsArray: JsonArray;
        TestJson: JsonObject;
    begin
        AITTestInputLine.SetRange("Dataset Code", DatasetCode);
        if AITTestInputLine.FindSet() then
            repeat
                TestJson := AITTestInputLine.BuildTestJson();
                TestsArray.Add(TestJson);
            until AITTestInputLine.Next() = 0;

        DatasetJson.Add('tests', TestsArray);
        exit(DatasetJson);
    end;

    /// <summary>
    /// Exports a complete dataset to the Test Input table.
    /// Creates one Test Input Group with one Test Input containing all tests.
    /// </summary>
    procedure ExportDatasetToTestInput(DatasetCode: Code[100])
    var
        AITTestInput: Record "AIT Test Input";
        TestInputGroup: Record "Test Input Group";
        TestInput: Record "Test Input";
        DatasetJson: JsonObject;
        DatasetText: Text;
        DatasetOutStream: OutStream;
    begin
        // Ensure the dataset/group exists
        if not TestInputGroup.Get(DatasetCode) then begin
            TestInputGroup.Init();
            TestInputGroup.Code := DatasetCode;
            if AITTestInput.Get(DatasetCode, '') then
                TestInputGroup.Description := CopyStr(AITTestInput.Description, 1, MaxStrLen(TestInputGroup.Description))
            else
                TestInputGroup.Description := CopyStr(DatasetCode, 1, MaxStrLen(TestInputGroup.Description));
            TestInputGroup.Insert(true);
        end;

        // Build the complete dataset JSON with tests array
        DatasetJson := BuildDatasetJson(DatasetCode);
        DatasetJson.WriteTo(DatasetText);

        // Create or update the Test Input record (using dataset code as the test input code)
        if not TestInput.Get(DatasetCode, DatasetCode) then begin
            TestInput.Init();
            TestInput."Test Input Group Code" := DatasetCode;
            TestInput.Code := DatasetCode;
            TestInput.Description := 'Dataset with multiple tests';
            TestInput.Insert(true);
        end;

        // Write the JSON to the Test Input blob field
        TestInput."Test Input".CreateOutStream(DatasetOutStream, TextEncoding::UTF8);
        DatasetOutStream.WriteText(DatasetText);
        TestInput.Modify(true);
    end;

    var
        MissingFieldsErr: Label 'The following required fields are missing: %1', Comment = '%1 = comma-separated list of field names';

    #endregion

    #region Helper Methods

    local procedure GetJsonText(JsonObj: JsonObject; PropertyName: Text): Text
    var
        JsonToken: JsonToken;
    begin
        if JsonObj.Get(PropertyName, JsonToken) then
            if JsonToken.IsValue() then
                exit(JsonToken.AsValue().AsText());
        exit('');
    end;

    local procedure GetJsonBoolean(JsonObj: JsonObject; PropertyName: Text): Boolean
    var
        JsonToken: JsonToken;
    begin
        if JsonObj.Get(PropertyName, JsonToken) then
            if JsonToken.IsValue() then
                exit(JsonToken.AsValue().AsBoolean());
        exit(false);
    end;

    local procedure ParseFieldType(TypeText: Text): Enum "AIT Query Field Type"
    begin
        case LowerCase(TypeText) of
            'text':
                exit("AIT Query Field Type"::Text);
            'multilinetext', 'multiline':
                exit("AIT Query Field Type"::MultilineText);
            'boolean', 'bool':
                exit("AIT Query Field Type"::Boolean);
            'integer', 'int':
                exit("AIT Query Field Type"::Integer);
            'filelist', 'files':
                exit("AIT Query Field Type"::FileList);
            'jsonobject', 'json':
                exit("AIT Query Field Type"::JsonObject);
            else
                exit("AIT Query Field Type"::Text);
        end;
    end;

    #endregion
}
