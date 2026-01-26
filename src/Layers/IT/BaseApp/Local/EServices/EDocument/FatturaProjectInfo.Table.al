// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

table 12199 "Fattura Project Info"
{
    Caption = 'Fattura Project Info';
    DrillDownPageID = "Fattura Project Info";
    LookupPageID = "Fattura Project Info";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[15])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(3; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Project,Tender';
            OptionMembers = Project,Tender;
        }
    }

    keys
    {
        key(Key1; "Code", Type)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

