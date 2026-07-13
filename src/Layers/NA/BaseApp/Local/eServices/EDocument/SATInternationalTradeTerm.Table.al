// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

table 27045 "SAT International Trade Term"
{
    DataPerCompany = false;
    DrillDownPageID = "SAT International Trade Terms";
    LookupPageID = "SAT International Trade Terms";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
        }
        field(2; Description; Text[100])
        {
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

