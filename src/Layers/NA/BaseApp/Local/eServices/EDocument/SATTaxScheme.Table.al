// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

table 27016 "SAT Tax Scheme"
{
    Caption = 'SAT Tax Scheme';
    DataPerCompany = false;
    DrillDownPageID = "SAT Tax Schemas";
    LookupPageID = "SAT Tax Schemas";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "SAT Tax Scheme"; Code[10])
        {
            Caption = 'SAT Tax Scheme';
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "SAT Tax Scheme")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

