// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.SyncEngine;

using System.Reflection;
using System.IO;

table 5326 "Int. Table Config Template"
{
    Caption = 'Integration Table Config Template';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'No.';
            DataClassification = SystemMetadata;
        }
        field(2; "Integration Table Mapping Name"; Code[20])
        {
            Caption = 'Integration Table Mapping Name';
            TableRelation = "Integration Table Mapping".Name;
            NotBlank = true;
            DataClassification = SystemMetadata;
        }
        field(3; "Integration Table ID"; Integer)
        {
            Caption = 'Integration Table ID';
            TableRelation = "Table Metadata".ID;
            DataClassification = SystemMetadata;
        }
        field(4; "Int. Tbl. Config Template Code"; Code[10])
        {
            Caption = 'Integration Table Config Template Code';
            TableRelation = "Config. Template Header".Code where("Table ID" = field("Integration Table ID"));
            DataClassification = SystemMetadata;
        }
        field(5; "Table Filter"; Blob)
        {
            Caption = 'Table Filter';
            DataClassification = SystemMetadata;
        }
        field(6; Priority; Integer)
        {
            Caption = 'Priority';
            DataClassification = SystemMetadata;
            MinValue = 0;
            BlankZero = true;
        }
        field(7; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            TableRelation = "Table Metadata".ID;
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
        key(Key2; Priority)
        {
        }
    }

    procedure SetTableFilter(IntTableFilter: Text)
    var
        OutStream: OutStream;
    begin
        "Table Filter".CreateOutStream(OutStream);
        OutStream.Write(IntTableFilter);
    end;

    procedure GetTableFilter() Value: Text
    var
        InStream: InStream;
    begin
        CalcFields("Table Filter");
        "Table Filter".CreateInStream(InStream);
        InStream.Read(Value);
    end;
}