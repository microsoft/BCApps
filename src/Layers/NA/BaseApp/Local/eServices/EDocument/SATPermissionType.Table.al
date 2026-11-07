// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

table 27023 "SAT Permission Type"
{
    DataPerCompany = false;
    DrillDownPageID = "SAT Permission Types";
    LookupPageID = "SAT Permission Types";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(2; Description; Text[150])
        {
            Caption = 'Description';
        }
        field(3; "Transport Key"; Code[10])
        {
            Caption = 'Transport Key';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

