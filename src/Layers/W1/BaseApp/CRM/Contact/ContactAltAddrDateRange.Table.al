// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Contact;

table 5052 "Contact Alt. Addr. Date Range"
{
    Caption = 'Contact Alt. Addr. Date Range';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Contact No."; Code[20])
        {
            Caption = 'Contact No.';
            Editable = false;
            TableRelation = Contact;
        }
        field(2; "Contact Alt. Address Code"; Code[10])
        {
            Caption = 'Contact Alt. Address Code';
            TableRelation = "Contact Alt. Address".Code where("Contact No." = field("Contact No."));
        }
        field(3; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
            NotBlank = true;

            trigger OnValidate()
            var
                ContAltAddrDateRange: Record "Contact Alt. Addr. Date Range";
            begin
                if ("Starting Date" > "Ending Date") and ("Ending Date" > 0D) then
                    Error(Text000, FieldCaption("Starting Date"), FieldCaption("Ending Date"));
                if ContAltAddrDateRange.Get("Contact No.", "Starting Date") then
                    Error(Text001
                      , "Starting Date", TableCaption(), Cont.TableCaption(), "Contact No.");
            end;
        }
        field(4; "Ending Date"; Date)
        {
            Caption = 'Ending Date';

            trigger OnValidate()
            begin
                if ("Ending Date" < "Starting Date") and ("Ending Date" > 0D) then
                    Error(Text002, FieldCaption("Ending Date"), FieldCaption("Starting Date"));
            end;
        }
    }

    keys
    {
        key(Key1; "Contact No.", "Starting Date")
        {
            Clustered = true;
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

    var
        Cont: Record Contact;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1 must be before %2.';
        Text001: Label 'The starting date %1 already exists in a %2 for %3 %4.';
        Text002: Label '%1 must be after %2.';
#pragma warning restore AA0470
#pragma warning restore AA0074
}

