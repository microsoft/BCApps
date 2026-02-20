// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

using Microsoft.eServices.EDocument;

table 6142 "E-Doc. MLLM Extraction Schema"
{
    Access = Internal;
    DataClassification = CustomerContent;
    ReplicateData = false;
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;

    fields
    {
        field(1; "E-Document Service Code"; Code[20])
        {
            Caption = 'E-Document Service Code';
            TableRelation = "E-Document Service".Code;
            DataClassification = SystemMetadata;
        }
        field(2; Schema; Blob)
        {
            Caption = 'Schema';
        }
        field(3; Description; Text[250])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(PK; "E-Document Service Code")
        {
            Clustered = true;
        }
    }

    procedure GetSchemaText(): Text
    var
        InStream: InStream;
        SchemaText: Text;
    begin
        CalcFields(Schema);
        if not Schema.HasValue() then
            exit('');
        Schema.CreateInStream(InStream, TextEncoding::UTF8);
        InStream.Read(SchemaText);
        exit(SchemaText);
    end;

    procedure SetSchemaText(NewSchema: Text)
    var
        OutStream: OutStream;
    begin
        Clear(Schema);
        Schema.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.Write(NewSchema);
        Modify();
    end;
}
