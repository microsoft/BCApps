// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;

table 5811 "Post Value Entry to G/L"
{
    Caption = 'Post Value Entry to G/L';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Value Entry No."; Integer)
        {
            Caption = 'Value Entry No.';
            TableRelation = "Value Entry";
        }
        field(2; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;
        }
        field(3; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
    }

    keys
    {
        key(Key1; "Value Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Item No.", "Posting Date")
        {
        }
        key(Key3; "Item No.")
        {
        }
    }

    fieldgroups
    {
    }
}

