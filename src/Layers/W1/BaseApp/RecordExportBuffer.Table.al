// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.IO;

using Microsoft.Foundation.Reporting;
using System.Utilities;

table 62 "Record Export Buffer"
{
    Caption = 'Record Export Buffer';
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
        field(2; RecordID; RecordID)
        {
            Caption = 'RecordID';
            DataClassification = CustomerContent;
        }
        field(4; ClientFileName; Text[250])
        {
            Caption = 'ClientFileName';
            DataClassification = SystemMetadata;
        }
        field(5; ZipFileName; Text[250])
        {
            Caption = 'ZipFileName';
            DataClassification = SystemMetadata;
        }
        field(6; "Electronic Document Format"; Code[20])
        {
            Caption = 'Electronic Document Format';
            DataClassification = SystemMetadata;
            TableRelation = "Electronic Document Format";
        }
        field(7; "Document Sending Profile"; Code[20])
        {
            Caption = 'Document Sending Profile';
            DataClassification = SystemMetadata;
            TableRelation = "Document Sending Profile";
        }
        field(8; "File Content"; BLOB)
        {
            Caption = 'File Content';
            DataClassification = CustomerContent;
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
    }

    procedure GetFileContent(var TempBlob: Codeunit "Temp Blob"): Boolean
    begin
        TempBlob.FromRecord(Rec, FieldNo("File Content"));
        exit(TempBlob.HasValue());
    end;

    procedure SetFileContent(TempBlob: Codeunit "Temp Blob")
    var
        RecordRef: RecordRef;
    begin
        RecordRef.GetTable(Rec);
        TempBlob.ToRecordRef(RecordRef, FieldNo("File Content"));
        RecordRef.SetTable(Rec);
    end;
}
