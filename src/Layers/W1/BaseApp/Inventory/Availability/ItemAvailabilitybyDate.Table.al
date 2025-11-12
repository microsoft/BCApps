// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Availability;

table 5872 "Item Availability by Date"
{
    Caption = 'Item Availability by Date';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Item No."; Code[20])
        {
            Caption = 'Item No.';
        }
        field(2; Date; Date)
        {
            Caption = 'Date';
        }
        field(3; "Available Qty"; Decimal)
        {
            Caption = 'Available Qty';
        }
        field(4; "Updated Available Qty"; Decimal)
        {
            Caption = 'Updated Available Qty';
        }
        field(5; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
        }
        field(6; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
        }
    }

    keys
    {
        key(Key1; "Item No.", "Variant Code", "Location Code", Date)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

