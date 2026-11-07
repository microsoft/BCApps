// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

table 27047 "SAT Customs Regime"
{
    DataPerCompany = false;
    DrillDownPageID = "SAT Customs Regimes";
    LookupPageID = "SAT Customs Regimes";

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