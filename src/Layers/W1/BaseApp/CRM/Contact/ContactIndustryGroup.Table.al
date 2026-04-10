// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Contact;

using Microsoft.CRM.Setup;

table 5058 "Contact Industry Group"
{
    Caption = 'Contact Industry Group';
    DataClassification = CustomerContent;
    DrillDownPageID = "Contact Industry Groups";

    fields
    {
        field(1; "Contact No."; Code[20])
        {
            Caption = 'Contact No.';
            ToolTip = 'Specifies the number of the contact company you are assigning industry groups.';
            NotBlank = true;
            TableRelation = Contact where(Type = const(Company));
        }
        field(2; "Industry Group Code"; Code[10])
        {
            Caption = 'Industry Group Code';
            ToolTip = 'Specifies the industry group code. This field is not editable.';
            NotBlank = true;
            TableRelation = "Industry Group";
        }
        field(3; "Industry Group Description"; Text[100])
        {
            CalcFormula = lookup("Industry Group".Description where(Code = field("Industry Group Code")));
            Caption = 'Industry Group Description';
            ToolTip = 'Specifies the description of the industry group you have assigned to the contact.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(4; "Contact Name"; Text[100])
        {
            CalcFormula = lookup(Contact.Name where("No." = field("Contact No.")));
            Caption = 'Contact Name';
            ToolTip = 'Specifies the name of the contact company you are assigning an industry group.';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Contact No.", "Industry Group Code")
        {
            Clustered = true;
        }
        key(Key2; "Industry Group Code")
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

