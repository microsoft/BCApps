// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.Journal;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;

table 7380 "Phys. Invt. Item Selection"
{
    Caption = 'Phys. Invt. Item Selection';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            Editable = false;
            NotBlank = true;
            TableRelation = Item;
        }
        field(2; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            Editable = false;
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(3; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            Editable = false;
            TableRelation = Location where("Use As In-Transit" = const(false));
        }
        field(4; Description; Text[100])
        {
            CalcFormula = lookup(Item.Description where("No." = field("Item No.")));
            Caption = 'Description';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; "Shelf No."; Code[10])
        {
            Caption = 'Shelf No.';
            Editable = false;
        }
        field(6; "Phys Invt Counting Period Code"; Code[10])
        {
            Caption = 'Phys Invt Counting Period Code';
            Editable = false;
            TableRelation = "Phys. Invt. Counting Period";
        }
        field(7; "Last Counting Date"; Date)
        {
            Caption = 'Last Counting Date';
            Editable = false;
        }
        field(9; "Count Frequency per Year"; Integer)
        {
            BlankZero = true;
            Caption = 'Count Frequency per Year';
            Editable = false;
            MinValue = 0;
        }
        field(10; Selected; Boolean)
        {
            Caption = 'Selected';
        }
        field(11; "Phys Invt Counting Period Type"; Option)
        {
            Caption = 'Phys Invt Counting Period Type';
            OptionCaption = ' ,Item,SKU';
            OptionMembers = " ",Item,SKU;
        }
        field(12; "Next Counting Start Date"; Date)
        {
            Caption = 'Next Counting Start Date';
            Editable = false;
        }
        field(13; "Next Counting End Date"; Date)
        {
            Caption = 'Next Counting End Date';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Item No.", "Variant Code", "Location Code", "Phys Invt Counting Period Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

