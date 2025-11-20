// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.Journal;

table 7381 "Phys. Invt. Counting Period"
{
    Caption = 'Phys. Invt. Counting Period';
    LookupPageID = "Phys. Invt. Counting Periods";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "Count Frequency per Year"; Integer)
        {
            Caption = 'Count Frequency per Year';
            InitValue = 1;
            MinValue = 1;
            NotBlank = true;
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
        fieldgroup(DropDown; "Code", Description, "Count Frequency per Year")
        {
        }
    }
}

