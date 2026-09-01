// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

table 27048 "SAT Customs Document Type"
{
    DataPerCompany = false;
    DrillDownPageID = "SAT Customs Document Types";
    LookupPageID = "SAT Customs Document Types";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
			DataClassification = CustomerContent;
        }
        field(2; Description; Text[250])
        {
            Caption = 'Description';
			DataClassification = CustomerContent;
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