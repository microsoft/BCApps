// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

table 823 "Name/Value Buffer"
{
    Caption = 'Name/Value Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; ID; Integer)
        {
            AutoIncrement = true;
            Caption = 'ID';
            DataClassification = SystemMetadata;
        }
        field(2; Name; Text[250])
        {
            Caption = 'Name';
            DataClassification = SystemMetadata;
        }
        field(3; Value; Text[250])
        {
            Caption = 'Value';
            DataClassification = SystemMetadata;
        }
        field(4; "Value BLOB"; BLOB)
        {
            Caption = 'Value BLOB';
            DataClassification = SystemMetadata;
        }
        field(5; "Value Long"; Text[2048])
        {
            Caption = 'Value Long';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; ID)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; Name)
        {
        }
        fieldgroup(Brick; Name, Value)
        {
        }
    }

    var
        TemporaryErr: Label 'The record must be temporary.';

    procedure AddNewEntry(NewName: Text[250]; NewValue: Text)
    var
        NewID: Integer;
    begin
        if not IsTemporary then
            Error(TemporaryErr);

        Clear(Rec);

        NewID := 1;
        if FindLast() then
            NewID := ID + 1;

        ID := NewID;
        Name := NewName;
        SetValueWithoutModifying(NewValue);

        Insert(true);
    end;

    procedure GetValue() Result: Text
    var
        InStream: InStream;
    begin
        if not "Value BLOB".HasValue() then
            exit(Value);

        CalcFields("Value BLOB");
        "Value BLOB".CreateInStream(InStream, TEXTENCODING::Windows);
        InStream.Read(Result);
    end;

    procedure SetValue(NewValue: Text)
    begin
        SetValueWithoutModifying(NewValue);
        Modify();
    end;

    procedure SetValueWithoutModifying(NewValue: Text)
    var
        OutStream: OutStream;
    begin
        Clear("Value BLOB");
        Value := CopyStr(NewValue, 1, MaxStrLen(Value));
        if StrLen(NewValue) <= MaxStrLen(Value) then
            exit; // No need to store anything in the blob
        if NewValue = '' then
            exit;

        "Value BLOB".CreateOutStream(OutStream, TEXTENCODING::Windows);
        OutStream.Write(NewValue);
    end;
}

