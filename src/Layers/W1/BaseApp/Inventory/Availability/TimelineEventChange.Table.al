// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Availability;

table 5541 "Timeline Event Change"
{
    Caption = 'Timeline Event Change';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Reference No."; Text[200])
        {
            Caption = 'Reference No.';
            Editable = false;
        }
        field(2; Changes; Integer)
        {
            Caption = 'Changes';
            Editable = false;
        }
        field(4; "Original Due Date"; Date)
        {
            Caption = 'Original Due Date';
            Editable = false;
        }
        field(5; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        field(6; ChangeRefNo; Text[250])
        {
            Caption = 'ChangeRefNo';
            Editable = false;
        }
        field(20; "Original Quantity"; Decimal)
        {
            Caption = 'Original Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            MinValue = 0;
        }
        field(21; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(1000; ID; Integer)
        {
            Caption = 'ID';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; ID)
        {
            Clustered = true;
        }
        key(Key2; "Reference No.")
        {
        }
        key(Key3; "Due Date")
        {
        }
    }

    fieldgroups
    {
    }
}

