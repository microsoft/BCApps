// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Outlook;

table 5320 "Exchange Folder"
{
    Caption = 'Exchange Folder';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Unique ID"; BLOB)
        {
            Caption = 'Unique ID';
        }
        field(2; Name; Text[250])
        {
            Caption = 'Name';
        }
        field(3; FullPath; Text[250])
        {
            Caption = 'FullPath';
        }
        field(4; Depth; Integer)
        {
            Caption = 'Depth';
        }
        field(5; Cached; Boolean)
        {
            Caption = 'Cached';
        }
    }

    keys
    {
        key(Key1; FullPath)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure ReadUniqueID() Return: Text
    var
        Stream: InStream;
    begin
        "Unique ID".CreateInStream(Stream);
        Stream.ReadText(Return);
    end;

    procedure GetUniqueID() Return: Text
    begin
        CalcFields("Unique ID");
        Return := ReadUniqueID();
    end;

    procedure SetUniqueID(UniqueID: Text)
    var
        Stream: OutStream;
    begin
        "Unique ID".CreateOutStream(Stream);
        Stream.WriteText(UniqueID);
    end;
}

