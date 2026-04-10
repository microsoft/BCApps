// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Maintenance;

table 5916 "Symptom Code"
{
    Caption = 'Symptom Code';
    LookupPageID = "Symptom Codes";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            ToolTip = 'Specifies a code for the symptom.';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the symptom code.';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
        key(Key2; Description)
        {
        }
    }

    fieldgroups
    {
    }
}

