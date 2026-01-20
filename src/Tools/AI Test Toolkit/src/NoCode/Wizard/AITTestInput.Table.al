// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

/// <summary>
/// Stores user-created test inputs via the No-Code wizard.
/// Contains the test name, description, query, expected_data, and setup configuration.
/// </summary>
table 149062 "AIT Test Input"
{
    Caption = 'AI Test Input';
    DataClassification = CustomerContent;
    ReplicateData = false;
    Extensible = true;
    Access = Public;

    fields
    {
        field(1; "Dataset Code"; Code[100])
        {
            Caption = 'Dataset Code';
            NotBlank = true;
            ToolTip = 'Specifies the dataset this test input belongs to.';
        }
        field(2; "Test Name"; Text[250])
        {
            Caption = 'Test Name';
            NotBlank = true;
            ToolTip = 'Specifies the unique name for this test case.';
        }
        field(3; "Description"; Text[250])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of what this test validates.';
        }
        field(4; "Feature Code"; Code[50])
        {
            Caption = 'Feature Code';
            TableRelation = "AIT Query Schema"."Feature Code";
            ToolTip = 'Specifies the AI feature this test is for.';
        }
        field(5; "Test Setup Reference"; Text[250])
        {
            Caption = 'Test Setup Reference';
            ToolTip = 'Specifies the name of the test setup configuration to use.';
        }
        field(10; "Query JSON"; Blob)
        {
            Caption = 'Query JSON';
            ToolTip = 'Specifies the query configuration as JSON.';
        }
        field(11; "Expected Data JSON"; Blob)
        {
            Caption = 'Expected Data JSON';
            ToolTip = 'Specifies the expected data/validation configuration as JSON.';
        }
        field(12; "Test Setup JSON"; Blob)
        {
            Caption = 'Test Setup JSON';
            ToolTip = 'Specifies the inline test setup configuration as JSON (optional, alternative to Test Setup Reference).';
        }
        field(20; "Created At"; DateTime)
        {
            Caption = 'Created At';
            Editable = false;
            ToolTip = 'Specifies when this test input was created.';
        }
        field(21; "Created By"; Code[50])
        {
            Caption = 'Created By';
            Editable = false;
            ToolTip = 'Specifies who created this test input.';
        }
        field(22; "Modified At"; DateTime)
        {
            Caption = 'Modified At';
            Editable = false;
            ToolTip = 'Specifies when this test input was last modified.';
        }
    }

    keys
    {
        key(PK; "Dataset Code", "Test Name")
        {
            Clustered = true;
        }
        key(Feature; "Feature Code")
        {
        }
    }

    trigger OnInsert()
    begin
        "Created At" := CurrentDateTime;
        "Created By" := CopyStr(UserId, 1, MaxStrLen("Created By"));
        "Modified At" := CurrentDateTime;
    end;

    trigger OnModify()
    begin
        "Modified At" := CurrentDateTime;
    end;

    /// <summary>
    /// Gets the query JSON as a JsonObject.
    /// </summary>
    procedure GetQueryJson(): JsonObject
    var
        QueryInStream: InStream;
        QueryText: Text;
        QueryJson: JsonObject;
    begin
        CalcFields("Query JSON");
        if not "Query JSON".HasValue() then
            exit(QueryJson);

        "Query JSON".CreateInStream(QueryInStream, TextEncoding::UTF8);
        QueryInStream.ReadText(QueryText);
        QueryJson.ReadFrom(QueryText);
        exit(QueryJson);
    end;

    /// <summary>
    /// Sets the query JSON from a JsonObject.
    /// </summary>
    procedure SetQueryJson(QueryJson: JsonObject)
    var
        QueryOutStream: OutStream;
        QueryText: Text;
    begin
        QueryJson.WriteTo(QueryText);
        "Query JSON".CreateOutStream(QueryOutStream, TextEncoding::UTF8);
        QueryOutStream.WriteText(QueryText);
    end;

    /// <summary>
    /// Gets the expected data JSON as a JsonObject.
    /// </summary>
    procedure GetExpectedDataJson(): JsonObject
    var
        DataInStream: InStream;
        DataText: Text;
        DataJson: JsonObject;
    begin
        CalcFields("Expected Data JSON");
        if not "Expected Data JSON".HasValue() then
            exit(DataJson);

        "Expected Data JSON".CreateInStream(DataInStream, TextEncoding::UTF8);
        DataInStream.ReadText(DataText);
        DataJson.ReadFrom(DataText);
        exit(DataJson);
    end;

    /// <summary>
    /// Sets the expected data JSON from a JsonObject.
    /// </summary>
    procedure SetExpectedDataJson(DataJson: JsonObject)
    var
        DataOutStream: OutStream;
        DataText: Text;
    begin
        DataJson.WriteTo(DataText);
        "Expected Data JSON".CreateOutStream(DataOutStream, TextEncoding::UTF8);
        DataOutStream.WriteText(DataText);
    end;

    /// <summary>
    /// Gets the test setup JSON as a JsonObject.
    /// </summary>
    procedure GetTestSetupJson(): JsonObject
    var
        SetupInStream: InStream;
        SetupText: Text;
        SetupJson: JsonObject;
    begin
        CalcFields("Test Setup JSON");
        if not "Test Setup JSON".HasValue() then
            exit(SetupJson);

        "Test Setup JSON".CreateInStream(SetupInStream, TextEncoding::UTF8);
        SetupInStream.ReadText(SetupText);
        SetupJson.ReadFrom(SetupText);
        exit(SetupJson);
    end;

    /// <summary>
    /// Sets the test setup JSON from a JsonObject.
    /// </summary>
    procedure SetTestSetupJson(SetupJson: JsonObject)
    var
        SetupOutStream: OutStream;
        SetupText: Text;
    begin
        SetupJson.WriteTo(SetupText);
        "Test Setup JSON".CreateOutStream(SetupOutStream, TextEncoding::UTF8);
        SetupOutStream.WriteText(SetupText);
    end;

    /// <summary>
    /// Builds the complete test input JSON for use by the test framework.
    /// </summary>
    procedure BuildTestInputJson(): JsonObject
    var
        TestInputJson: JsonObject;
        QueryJson: JsonObject;
        ExpectedDataJson: JsonObject;
        SetupJson: JsonObject;
    begin
        TestInputJson.Add('name', "Test Name");

        if Description <> '' then
            TestInputJson.Add('description', Description);

        if "Test Setup Reference" <> '' then
            TestInputJson.Add('test_setup', "Test Setup Reference");

        SetupJson := GetTestSetupJson();
        if SetupJson.Keys.Count > 0 then
            TestInputJson.Add('test_setup', SetupJson);

        QueryJson := GetQueryJson();
        if QueryJson.Keys.Count > 0 then
            TestInputJson.Add('query', QueryJson);

        ExpectedDataJson := GetExpectedDataJson();
        if ExpectedDataJson.Keys.Count > 0 then
            TestInputJson.Add('expected_data', ExpectedDataJson);

        exit(TestInputJson);
    end;
}
