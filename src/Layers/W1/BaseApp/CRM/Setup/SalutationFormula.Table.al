// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Setup;

using Microsoft.CRM.Contact;
using System.Globalization;

table 5069 "Salutation Formula"
{
    Caption = 'Salutation Formula';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Salutation Code"; Code[10])
        {
            Caption = 'Salutation Code';
            NotBlank = true;
            TableRelation = Salutation;
        }
        field(2; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
        }
        field(3; "Salutation Type"; Enum "Salutation Formula Salutation Type")
        {
            Caption = 'Salutation Type';
        }
        field(4; Salutation; Text[50])
        {
            Caption = 'Salutation';
        }
        field(5; "Name 1"; Enum "Salutation Formula Name")
        {
            Caption = 'Name 1';
        }
        field(6; "Name 2"; Enum "Salutation Formula Name")
        {
            Caption = 'Name 2';
        }
        field(7; "Name 3"; Enum "Salutation Formula Name")
        {
            Caption = 'Name 3';
        }
        field(8; "Name 4"; Enum "Salutation Formula Name")
        {
            Caption = 'Name 4';
        }
        field(9; "Name 5"; Enum "Salutation Formula Name")
        {
            Caption = 'Name 5';
        }
        field(10; "Contact No. Filter"; Code[20])
        {
            Caption = 'Contact No. Filter';
            FieldClass = FlowFilter;
            TableRelation = Contact;
        }
    }

    keys
    {
        key(Key1; "Salutation Code", "Language Code", "Salutation Type")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure GetContactSalutation(): Text[260]
    var
        Cont: Record Contact;
    begin
        Cont.Get(GetFilter("Contact No. Filter"));
        exit(Cont.GetSalutation("Salutation Type", "Language Code"));
    end;
}

