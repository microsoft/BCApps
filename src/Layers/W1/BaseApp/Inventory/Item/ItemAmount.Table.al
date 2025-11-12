// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

table 268 "Item Amount"
{
    Caption = 'Item Amount';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;
        }
        field(2; Amount; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount';
        }
        field(3; "Amount 2"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount 2';
        }
    }

    keys
    {
        key(Key1; Amount, "Amount 2", "Item No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

