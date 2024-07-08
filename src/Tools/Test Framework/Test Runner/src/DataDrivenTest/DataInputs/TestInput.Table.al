// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

table 130452 "Test Input"
{
    DataClassification = CustomerContent;
    ReplicateData = false;

    fields
    {
        field(1; "Test Input Group Code"; Code[100])
        {
            Caption = 'Test Input Group Code';
            Tooltip = 'Specifies the code for the test input group.';
            DataClassification = CustomerContent;
            TableRelation = "Test Input Group".Code;
        }
        field(2; Code; Code[100])
        {
            Caption = 'Code';
            Tooltip = 'Specifies the code of the test input.';
            DataClassification = CustomerContent;
        }
        field(10; Description; Text[2048])
        {
            Caption = 'Description';
            Tooltip = 'Specifies the description of the test input.';
            DataClassification = CustomerContent;
        }
        field(20; Sensitive; Boolean)
        {
            Caption = 'Sensitive';
            Tooltip = 'Specifies if the test input is sensitive and should not be shown directly off the page.';
            DataClassification = CustomerContent;
        }
        field(30; "Test Input"; Blob)
        {
            Caption = 'Test Input';
            Tooltip = 'Specifies the test input.';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; "Test Input Group Code", Code)
        {
        }
    }

    internal procedure SetInput(TestInput: Record "Test Input"; TextInput: Text)
    var
        TestInputOutStream: OutStream;
    begin
        TestInput."Test Input".CreateOutStream(TestInputOutStream, GetTextEncoding());
        TestInputOutStream.Write(TextInput);
        TestInput.Modify(true);
    end;

    internal procedure GetInput(TestInput: Record "Test Input"): Text
    var
        TestInputInStream: InStream;
        TextInput: Text;
    begin
        TestInput.CalcFields("Test Input");
        if (not TestInput."Test Input".HasValue()) then
            exit('');

        TestInput."Test Input".CreateInStream(TestInputInStream, GetTextEncoding());
        TestInputInStream.Read(TextInput);
        exit(TextInput);
    end;

    internal procedure GetTextEncoding(): TextEncoding
    begin
        exit(TextEncoding::UTF8);
    end;

    internal procedure GetTestInputDisplayName(TestInputGroupCode: Code[100]; TestInputCode: Code[100]): Text
    begin
        if TestInputGroupCode = '' then
            exit(TestInputCode);

        if TestInputCode = '' then
            exit(TestInputGroupCode);

        exit(StrSubstNo('%1-%2', TestInputGroupCode, TestInputCode))
    end;

    internal procedure IsSensitive(): Boolean
    var
        TestInputGroup: Record "Test Input Group";
    begin
        if TestInputGroup.Get(Rec."Test Input Group Code") then
            if TestInputGroup.Sensitive then
                exit(true);

        exit(Rec.Sensitive);
    end;
}