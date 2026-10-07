// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

table 27010 "SAT Classification"
{
    Caption = 'SAT Classification';
    DataPerCompany = false;
    DrillDownPageID = "SAT Classifications";
    LookupPageID = "SAT Classifications";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "SAT Classification"; Code[10])
        {
            Caption = 'SAT Classification';
            Description = '  Identifies the classification of product or service';
        }
        field(2; Description; Text[150])
        {
            Caption = 'Description';
        }
        field(3; "Hazardous Material Mandatory"; Boolean)
        {
            Caption = 'Hazardous Material Mandatory';
        }
    }

    keys
    {
        key(Key1; "SAT Classification")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

