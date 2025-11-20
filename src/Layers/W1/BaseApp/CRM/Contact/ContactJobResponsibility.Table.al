// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Contact;

using Microsoft.CRM.Setup;

table 5067 "Contact Job Responsibility"
{
    Caption = 'Contact Job Responsibility';
    DataClassification = CustomerContent;
    DrillDownPageID = "Contact Job Responsibilities";

    fields
    {
        field(1; "Contact No."; Code[20])
        {
            Caption = 'Contact No.';
            NotBlank = true;
            TableRelation = Contact where(Type = const(Person));
        }
        field(2; "Job Responsibility Code"; Code[10])
        {
            Caption = 'Job Responsibility Code';
            NotBlank = true;
            TableRelation = "Job Responsibility";
        }
        field(3; "Job Responsibility Description"; Text[100])
        {
            CalcFormula = lookup("Job Responsibility".Description where(Code = field("Job Responsibility Code")));
            Caption = 'Job Responsibility Description';
            Editable = false;
            FieldClass = FlowField;
        }
        field(4; "Contact Name"; Text[100])
        {
            CalcFormula = lookup(Contact.Name where("No." = field("Contact No.")));
            Caption = 'Contact Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; "Contact Company Name"; Text[100])
        {
            CalcFormula = lookup(Contact."Company Name" where("No." = field("Contact No.")));
            Caption = 'Contact Company Name';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Contact No.", "Job Responsibility Code")
        {
            Clustered = true;
        }
        key(Key2; "Job Responsibility Code")
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

