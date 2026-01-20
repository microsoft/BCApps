// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

/// <summary>
/// Temporary table for editing test cases within a dataset.
/// Data is loaded from and saved back to Test Input JSON blobs.
/// This table should ONLY be used as a temporary table.
/// </summary>
table 149077 "AIT Test Input Line"
{
    Caption = 'AI Test Input Line';
    DataClassification = SystemMetadata;
    TableType = Temporary;
    ReplicateData = false;
    Extensible = false;
    Access = Internal;

    fields
    {
        field(1; "Dataset Code"; Code[100])
        {
            Caption = 'Dataset Code';
            NotBlank = true;
            ToolTip = 'Specifies the dataset this test line belongs to.';
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            ToolTip = 'Specifies the line number within the dataset.';
        }
        field(3; "Test Name"; Text[250])
        {
            Caption = 'Test Name';
            ToolTip = 'Specifies the unique name for this test case.';
        }
        field(4; "Description"; Text[250])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of what this test validates.';
        }
        field(5; "Test Setup Reference"; Text[250])
        {
            Caption = 'Test Setup Reference';
            ToolTip = 'Specifies the name of the test setup configuration file to use (e.g., RUNTIME-CHALLENGE-LISTS-20-setup.yml).';
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
    }

    keys
    {
        key(PK; "Dataset Code", "Line No.")
        {
            Clustered = true;
        }
        key(TestName; "Dataset Code", "Test Name")
        {
        }
    }

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
        if QueryText <> '' then
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
        if DataText <> '' then
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
    /// Builds the test JSON object for this line (for use in the tests array).
    /// </summary>
    procedure BuildTestJson(): JsonObject
    var
        TestJson: JsonObject;
        QueryJson: JsonObject;
        ExpectedDataJson: JsonObject;
    begin
        TestJson.Add('name', "Test Name");

        if Description <> '' then
            TestJson.Add('description', Description);

        if "Test Setup Reference" <> '' then
            TestJson.Add('test_setup', "Test Setup Reference");

        QueryJson := GetQueryJson();
        if QueryJson.Keys.Count > 0 then
            TestJson.Add('query', QueryJson);

        ExpectedDataJson := GetExpectedDataJson();
        if ExpectedDataJson.Keys.Count > 0 then
            TestJson.Add('expected_data', ExpectedDataJson);

        exit(TestJson);
    end;

    /// <summary>
    /// Gets the next line number for a new test in the specified dataset.
    /// </summary>
    procedure GetNextLineNo(DatasetCode: Code[100]): Integer
    var
        AITTestInputLine: Record "AIT Test Input Line";
    begin
        AITTestInputLine.SetRange("Dataset Code", DatasetCode);
        if AITTestInputLine.FindLast() then
            exit(AITTestInputLine."Line No." + 10000)
        else
            exit(10000);
    end;
}
