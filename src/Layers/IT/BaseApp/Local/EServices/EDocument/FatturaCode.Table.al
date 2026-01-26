// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

table 12198 "Fattura Code"
{
    Caption = 'Fattura Code';
    DrillDownPageID = "Fattura Codes";
    LookupPageID = "Fattura Codes";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[4])
        {
            Caption = 'Code';
        }
        field(2; Type; Enum "Fattura Code Type")
        {
            Caption = 'Type';
        }
        field(3; Description; Text[250])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "Code", Type)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

