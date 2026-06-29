// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

table 27012 "SAT Use Code"
{
    Caption = 'SAT Use Code';
    DataPerCompany = false;
    DrillDownPageID = "SAT Use Codes";
    LookupPageID = "SAT Use Codes";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "SAT Use Code"; Code[10])
        {
            Caption = 'SAT Use Code';
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "SAT Use Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

