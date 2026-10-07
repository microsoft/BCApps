// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

table 27011 "SAT Relationship Type"
{
    Caption = 'SAT Relationship Type';
    DataPerCompany = false;
    DrillDownPageID = "SAT Relationship Types";
    LookupPageID = "SAT Relationship Types";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "SAT Relationship Type"; Code[10])
        {
            Caption = 'SAT Relationship Type';
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "SAT Relationship Type")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

