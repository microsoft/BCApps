// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

table 130453 "Test Output"
{
    DataClassification = CustomerContent;
    TableType = Temporary;
    ReplicateData = false;

    fields
    {
        field(1; "Test Suite"; Code[10])
        {
            TableRelation = "AL Test Suite".Name;
            Caption = 'Test Suite';
            Tooltip = 'Specifies the test suite code.';
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            Tooltip = 'Specifies the line number of the test method.';
        }
        field(4; "Method Name"; Text[128])
        {
            Caption = 'Method Name';
            Tooltip = 'Specifies the name of the test method.';
        }
        field(5; "Data Input"; Code[100])
        {
            Caption = 'Data Input';
            Tooltip = 'Specifies the data input for the test method line.';
        }
        field(50; "Test Output"; Blob)
        {
            Caption = 'Test Output';
            Tooltip = 'Specifies the test output.';
        }
    }

    keys
    {
        key(Key1; "Test Suite", "Method Name", "Line No.")
        {
            Clustered = true;
        }
    }

    internal procedure SetOutput(TextInput: Text)
    var
        TestOutputOutStream: OutStream;
    begin
        Rec."Test Output".CreateOutStream(TestOutputOutStream, GetTextEncoding());
        TestOutputOutStream.Write(TextInput);
        Rec.Modify(true);
    end;

    internal procedure GetOutput(): Text
    var
        TestOutputInStream: InStream;
        TextOutput: Text;
    begin
        Rec.CalcFields("Test Output");
        if (not Rec."Test Output".HasValue()) then
            exit('');

        Rec."Test Output".CreateInStream(TestOutputInStream, GetTextEncoding());
        TestOutputInStream.Read(TextOutput);

        if TextOutput = '{}' then
            exit('');

        exit(TextOutput);
    end;

    internal procedure GetTextEncoding(): TextEncoding
    begin
        exit(TextEncoding::UTF8);
    end;
}