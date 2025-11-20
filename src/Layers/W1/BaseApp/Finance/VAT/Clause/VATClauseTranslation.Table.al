// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Clause;

using System.Globalization;

table 561 "VAT Clause Translation"
{
    Caption = 'VAT Clause Translation';
    DrillDownPageID = "VAT Clause Translations";
    LookupPageID = "VAT Clause Translations";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "VAT Clause Code"; Code[20])
        {
            Caption = 'VAT Clause Code';
            TableRelation = "VAT Clause";
            DataClassification = CustomerContent;
        }
        field(2; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
            DataClassification = CustomerContent;
        }
        field(3; Description; Text[250])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
        field(4; "Description 2"; Text[250])
        {
            Caption = 'Description 2';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; "VAT Clause Code", "Language Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

