// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Outlook;

using Microsoft.Inventory.Item;

table 1637 "Office Suggested Line Item"
{
    Caption = 'Office Suggested Line Item';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Line No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Line No.';
        }
        field(2; Add; Boolean)
        {
            Caption = 'Add';
            Description = 'Specifies whether to add this item to the document.';
            InitValue = false;
        }
        field(3; "Item No."; Text[30])
        {
            Caption = 'Item No.';

            trigger OnValidate()
            var
                Item: Record Item;
            begin
                if Item.Get("Item No.") then
                    Validate("Item Description", Item.Description);
            end;
        }
        field(4; "Item Description"; Text[100])
        {
            Caption = 'Item Description';
        }
        field(5; Quantity; Integer)
        {
            Caption = 'Quantity';
        }
        field(6; Matches; Integer)
        {
            Caption = 'Matches';
            Description = 'The number of item matches that were found. If this is greater than one, then disambiguation is necessary.';
        }
    }

    keys
    {
        key(Key1; "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

