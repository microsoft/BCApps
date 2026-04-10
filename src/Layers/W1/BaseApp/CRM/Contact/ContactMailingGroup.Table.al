// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Contact;

using Microsoft.CRM.Setup;

table 5056 "Contact Mailing Group"
{
    Caption = 'Contact Mailing Group';
    DataClassification = CustomerContent;
    DrillDownPageID = "Contact Mailing Groups";

    fields
    {
        field(1; "Contact No."; Code[20])
        {
            Caption = 'Contact No.';
            ToolTip = 'Specifies the number of the contact to which you assign a mailing group.';
            NotBlank = true;
            TableRelation = Contact;
        }
        field(2; "Mailing Group Code"; Code[10])
        {
            Caption = 'Mailing Group Code';
            ToolTip = 'Specifies the mailing group code. This field is not editable.';
            NotBlank = true;
            TableRelation = "Mailing Group";
        }
        field(3; "Contact Name"; Text[100])
        {
            CalcFormula = lookup(Contact.Name where("No." = field("Contact No.")));
            Caption = 'Contact Name';
            ToolTip = 'Specifies the name of the contact to which you assign a mailing group.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(4; "Contact Company Name"; Text[100])
        {
            CalcFormula = lookup(Contact."Company Name" where("No." = field("Contact No.")));
            Caption = 'Contact Company Name';
            ToolTip = 'Specifies the name of the contact company. If the contact you assign the mailing group is a person, this field contains the name of the company for which the contact works.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; "Mailing Group Description"; Text[100])
        {
            CalcFormula = lookup("Mailing Group".Description where(Code = field("Mailing Group Code")));
            Caption = 'Mailing Group Description';
            ToolTip = 'Specifies the description of the mailing group you have chosen to assign the contact.';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Contact No.", "Mailing Group Code")
        {
            Clustered = true;
        }
        key(Key2; "Mailing Group Code")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        Contact: Record Contact;
    begin
        Contact.TouchContact("Contact No.");
    end;

    trigger OnInsert()
    var
        Contact: Record Contact;
    begin
        Contact.TouchContact("Contact No.");
    end;

    trigger OnModify()
    var
        Contact: Record Contact;
    begin
        Contact.TouchContact("Contact No.");
    end;

    trigger OnRename()
    var
        Contact: Record Contact;
    begin
        if xRec."Contact No." = "Contact No." then
            Contact.TouchContact("Contact No.")
        else begin
            Contact.TouchContact("Contact No.");
            Contact.TouchContact(xRec."Contact No.");
        end;
    end;
}

