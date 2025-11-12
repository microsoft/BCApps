// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Duplicates;

using Microsoft.CRM.Contact;

table 5086 "Cont. Duplicate Search String"
{
    Caption = 'Cont. Duplicate Search String';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Contact Company No."; Code[20])
        {
            Caption = 'Contact Company No.';
            NotBlank = true;
            TableRelation = Contact where(Type = const(Company));
        }
        field(2; "Field No."; Integer)
        {
            Caption = 'Field No.';
        }
        field(3; "Part of Field"; Option)
        {
            Caption = 'Part of Field';
            OptionCaption = 'First,Last';
            OptionMembers = First,Last;
        }
        field(4; "Search String"; Text[10])
        {
            Caption = 'Search String';
        }
    }

    keys
    {
        key(Key1; "Contact Company No.", "Field No.", "Part of Field")
        {
            Clustered = true;
        }
        key(Key2; "Field No.", "Part of Field", "Search String")
        {
        }
    }

    fieldgroups
    {
    }
}

