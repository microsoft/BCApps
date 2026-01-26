// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Ledger;

table 12147 "VAT Register"
{
    Caption = 'VAT Register';
    LookupPageID = "VAT Registers";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(3; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Purchase,Sale';
            OptionMembers = Purchase,Sale;
        }
        field(5; Description; Text[30])
        {
            Caption = 'Description';
        }
        field(10; "Last Printing Date"; Date)
        {
            Caption = 'Last Printing Date';
        }
        field(11; "Last Printed VAT Register Page"; Integer)
        {
            Caption = 'Last Printed VAT Register Page';
            MinValue = 0;
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
        fieldgroup(DropDown; "Code", Type, Description)
        {
        }
    }
}

