// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Interfactura;

table 3355 "SAT ISTMO Region MX"
{
    Caption = 'SAT ISTMO Region';
    DataClassification = CustomerContent;
    LookupPageId = "SAT ISTMO Regions MX";
    DrillDownPageId = "SAT ISTMO Regions MX";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(PK; "Code")
        {
            Clustered = true;
        }
    }
}
