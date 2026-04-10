// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Setup;

using Microsoft.CRM.Contact;

table 5055 "Mailing Group"
{
    Caption = 'Mailing Group';
    DataCaptionFields = "Code", Description;
    DataClassification = CustomerContent;
    LookupPageID = "Mailing Groups";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            ToolTip = 'Specifies the code for the mailing group.';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the description of the mailing group.';
        }
        field(3; "No. of Contacts"; Integer)
        {
            CalcFormula = count("Contact Mailing Group" where("Mailing Group Code" = field(Code)));
            Caption = 'No. of Contacts';
            ToolTip = 'Specifies the number of contacts that have been assigned the mailing group. This field is not editable.';
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

    trigger OnDelete()
    begin
        CalcFields("No. of Contacts");
        TestField("No. of Contacts", 0);
    end;
}

