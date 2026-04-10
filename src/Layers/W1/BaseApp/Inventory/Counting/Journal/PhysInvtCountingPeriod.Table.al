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
            ToolTip = 'Specifies a code for physical inventory counting period.';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the physical inventory counting period.';
        }
        field(3; "Count Frequency per Year"; Integer)
        {
            Caption = 'Count Frequency per Year';
            ToolTip = 'Specifies the number of times you want the item or stockkeeping unit to be counted each year.';
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

