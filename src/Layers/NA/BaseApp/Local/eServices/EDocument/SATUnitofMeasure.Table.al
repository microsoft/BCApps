// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

table 27013 "SAT Unit of Measure"
{
    Caption = 'SAT Unit of Measure';
    DataPerCompany = false;
    DrillDownPageID = "SAT Units Of Measure";
    LookupPageID = "SAT Units Of Measure";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "SAT UofM Code"; Code[10])
        {
            Caption = 'SAT UofM Code';
        }
        field(2; Name; Text[100])
        {
            Caption = 'Name';
        }
        field(3; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(6; Symbol; Text[30])
        {
            Caption = 'Symbol';
        }
    }

    keys
    {
        key(Key1; "SAT UofM Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

