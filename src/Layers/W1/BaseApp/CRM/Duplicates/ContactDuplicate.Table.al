// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Duplicates;

using Microsoft.CRM.Contact;

table 5085 "Contact Duplicate"
{
    Caption = 'Contact Duplicate';
    DataCaptionFields = "Contact No.";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Contact No."; Code[20])
        {
            Caption = 'Contact No.';
            ToolTip = 'Specifies the number of the contact for which a duplicate has been found.';
            Editable = false;
            NotBlank = true;
            TableRelation = Contact;
        }
        field(2; "Duplicate Contact No."; Code[20])
        {
            Caption = 'Duplicate Contact No.';
            ToolTip = 'Specifies the contact number of the duplicate that was found.';
            Editable = false;
            NotBlank = true;
            TableRelation = Contact;
        }
        field(3; "Separate Contacts"; Boolean)
        {
            Caption = 'Separate Contacts';
            ToolTip = 'Specifies that the two contacts are not true duplicates, but separate contacts.';
        }
        field(4; "No. of Matching Strings"; Integer)
        {
            Caption = 'No. of Matching Strings';
            Editable = false;
        }
        field(5; "Contact Name"; Text[100])
        {
            CalcFormula = lookup(Contact.Name where("No." = field("Contact No.")));
            Caption = 'Contact Name';
            ToolTip = 'Specifies the name of the contact for which a duplicate has been found.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6; "Duplicate Contact Name"; Text[100])
        {
            CalcFormula = lookup(Contact.Name where("No." = field("Duplicate Contact No.")));
            Caption = 'Duplicate Contact Name';
            ToolTip = 'Specifies the name of the contact that has been identified as a possible duplicate.';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Contact No.", "Duplicate Contact No.")
        {
            Clustered = true;
        }
        key(Key2; "Duplicate Contact No.", "Contact No.")
        {
        }
    }

    fieldgroups
    {
    }
}

