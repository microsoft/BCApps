// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

table 149033 "BCCT Dataset Line"
{
    DataCaptionFields = "Dataset Name";
    LookupPageId = "BCCT Dataset Lines Part";
    DrillDownPageId = "BCCT Dataset Lines Part";

    fields
    {
        field(1; Id; Integer)
        {
            AutoIncrement = true;
            DataClassification = SystemMetadata;
        }
        field(20; "Dataset Name"; Text[100])
        {
            DataClassification = CustomerContent;
        }
        field(21; "Input Blob"; Blob)
        {
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; Id, "Dataset Name")
        {
            Clustered = true;
        }
    }

    procedure SetInputTextAsBlob(InputText: Text)
    var
        OutStream: OutStream;
    begin
        Clear("Input Blob");
        "Input Blob".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.Write(InputText);
    end;

    procedure GetInputBlobAsText(): Text
    var
        InStream: InStream;
        InputText: Text;
    begin
        CalcFields("Input Blob");
        "Input Blob".CreateInStream(InStream, TextEncoding::UTF8);
        InStream.ReadText(InputText);
        exit(InputText);
    end;
}