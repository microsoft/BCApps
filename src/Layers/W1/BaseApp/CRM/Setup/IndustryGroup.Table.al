// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Setup;

using Microsoft.CRM.Contact;

table 5057 "Industry Group"
{
    Caption = 'Industry Group';
    DataCaptionFields = "Code", Description;
    DataClassification = CustomerContent;
    LookupPageID = "Industry Groups";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            ToolTip = 'Specifies the code for the industry group.';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the description of the industry group.';
        }
        field(3; "No. of Contacts"; Integer)
        {
            CalcFormula = count("Contact Industry Group" where("Industry Group Code" = field(Code)));
            Caption = 'No. of Contacts';
            ToolTip = 'Specifies the number of contacts that have been assigned the industry group. This field is not editable.';
            Editable = false;
            FieldClass = FlowField;
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

