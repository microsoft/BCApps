// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

table 6122 "E-Doc. Service Supported Type"
{
    DataClassification = CustomerContent;
    ReplicateData = false;

    fields
    {
        field(1; "E-Document Service Code"; Code[20])
        {
            TableRelation = "E-Document Service";
            Caption = 'E-Document Service Code';
        }
        field(2; "Source Document Type"; Enum "E-Document Type")
        {
            Caption = 'Source Document Type';
        }
        field(3; Direction; Enum "E-Doc. Supp. Type Direction")
        {
            Caption = 'Direction';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "E-Document Service Code", "Source Document Type")
        {
            Clustered = true;
        }
    }

    internal procedure InsertDefaultIfMissing(EDocServiceCode: Code[20]; SourceDocumentType: Enum "E-Document Type"; DefaultDirection: Enum "E-Doc. Supp. Type Direction")
    begin
        if Rec.Get(EDocServiceCode, SourceDocumentType) then
            exit;

        Rec.Init();
        Rec."E-Document Service Code" := EDocServiceCode;
        Rec."Source Document Type" := SourceDocumentType;
        Rec.Direction := DefaultDirection;
        Rec.Insert();
    end;
}