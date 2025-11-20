// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Clause;

using System.Globalization;

table 563 "VAT Clause by Doc. Type Trans."
{
    Caption = 'VAT Clause by Document Type Translation';
    DataCaptionFields = "VAT Clause Code", "Document Type";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "VAT Clause Code"; Code[20])
        {
            Caption = 'VAT Clause Code';
            TableRelation = "VAT Clause";
            DataClassification = CustomerContent;
        }
        field(2; "Document Type"; Enum "VAT Clause Document Type")
        {
            Caption = 'Document Type';
            DataClassification = CustomerContent;
        }
        field(3; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
            DataClassification = CustomerContent;
        }
        field(4; Description; Text[250])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
        field(5; "Description 2"; Text[250])
        {
            Caption = 'Description 2';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; "VAT Clause Code", "Document Type", "Language Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

