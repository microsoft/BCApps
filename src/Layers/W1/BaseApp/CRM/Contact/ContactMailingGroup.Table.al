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
            NotBlank = true;
            TableRelation = Contact;
        }
        field(2; "Mailing Group Code"; Code[10])
        {
            Caption = 'Mailing Group Code';
            NotBlank = true;
            TableRelation = "Mailing Group";
        }
        field(3; "Contact Name"; Text[100])
        {
            CalcFormula = lookup(Contact.Name where("No." = field("Contact No.")));
            Caption = 'Contact Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(4; "Contact Company Name"; Text[100])
        {
            CalcFormula = lookup(Contact."Company Name" where("No." = field("Contact No.")));
            Caption = 'Contact Company Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; "Mailing Group Description"; Text[100])
        {
            CalcFormula = lookup("Mailing Group".Description where(Code = field("Mailing Group Code")));
            Caption = 'Mailing Group Description';
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

