// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Contact;

using System.Email;

table 5100 "Communication Method"
{
    Caption = 'Communication Method';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Key"; Integer)
        {
            Caption = 'Key';
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; Number; Text[30])
        {
            Caption = 'Number';
        }
        field(4; "Contact No."; Code[20])
        {
            Caption = 'Contact No.';
            TableRelation = Contact;
        }
        field(5; Name; Text[100])
        {
            Caption = 'Name';
        }
        field(6; Type; Enum "Contact Type")
        {
            Caption = 'Type';
        }
        field(7; "E-Mail"; Text[80])
        {
            Caption = 'Email';
            ExtendedDatatype = EMail;

            trigger OnValidate()
            var
                MailManagement: Codeunit "Mail Management";
            begin
                MailManagement.ValidateEmailAddressField("E-Mail");
            end;
        }
    }

    keys
    {
        key(Key1; "Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

