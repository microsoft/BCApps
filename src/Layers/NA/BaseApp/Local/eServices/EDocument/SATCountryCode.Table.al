// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

table 27014 "SAT Country Code"
{
    Caption = 'SAT Country Code';
    DataPerCompany = false;
    DrillDownPageID = "SAT Country Codes";
    LookupPageID = "SAT Country Codes";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "SAT Country Code"; Code[10])
        {
            Caption = 'SAT Country Code';
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "SAT Country Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

