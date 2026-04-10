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
            ToolTip = 'Specifies the number of the item for which the cycle counting can be performed.';
            Editable = false;
            NotBlank = true;
            TableRelation = Item;
        }
        field(2; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            ToolTip = 'Specifies the variant of the item on the line.';
            Editable = false;
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(3; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            ToolTip = 'Specifies the code of the location where the cycle counting is performed.';
            Editable = false;
            TableRelation = Location where("Use As In-Transit" = const(false));
        }
        field(4; Description; Text[100])
        {
            CalcFormula = lookup(Item.Description where("No." = field("Item No.")));
            Caption = 'Description';
            ToolTip = 'Specifies the description of the item.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; "Shelf No."; Code[10])
        {
            Caption = 'Shelf No.';
            ToolTip = 'Specifies the shelf number of the item for informational use.';
            Editable = false;
        }
        field(6; "Phys Invt Counting Period Code"; Code[10])
        {
            Caption = 'Phys Invt Counting Period Code';
            ToolTip = 'Specifies the code of the counting period that indicates how often you want to count the item or stockkeeping unit in a physical inventory.';
            Editable = false;
            TableRelation = "Phys. Invt. Counting Period";
        }
        field(7; "Last Counting Date"; Date)
        {
            Caption = 'Last Counting Date';
            ToolTip = 'Specifies the last date when the counting period for the item or stockkeeping unit was updated.';
            Editable = false;
        }
        field(9; "Count Frequency per Year"; Integer)
        {
            BlankZero = true;
            Caption = 'Count Frequency per Year';
            ToolTip = 'Specifies the number of times you want the item or stockkeeping unit to be counted each year.';
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
            ToolTip = 'Specifies the starting date of the next counting period.';
            Editable = false;
        }
        field(13; "Next Counting End Date"; Date)
        {
            Caption = 'Next Counting End Date';
            ToolTip = 'Specifies the ending date of the next counting period.';
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

