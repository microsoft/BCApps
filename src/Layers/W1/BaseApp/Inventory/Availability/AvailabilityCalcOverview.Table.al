// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Availability;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;

table 5830 "Availability Calc. Overview"
{
    Caption = 'Availability Calc. Overview';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; Type; Option)
        {
            Caption = 'Type';
            ToolTip = 'Specifies the type of availability being calculated.';
            OptionCaption = 'Item,As of Date,Inventory,Supply,Supply Forecast,Demand';
            OptionMembers = Item,"As of Date",Inventory,Supply,"Supply Forecast",Demand;
        }
        field(3; Date; Date)
        {
            Caption = 'Date';
            ToolTip = 'Specifies the date of the availability calculation.';
        }
        field(4; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            ToolTip = 'Specifies the identifier number for the item.';
            TableRelation = Item;
        }
        field(5; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            ToolTip = 'Specifies the location code of the item for which availability is being calculated.';
            TableRelation = Location;
        }
        field(6; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            ToolTip = 'Specifies the variant of the item on the line.';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(7; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
        }
        field(11; "Attached to Entry No."; Integer)
        {
            Caption = 'Attached to Entry No.';
            TableRelation = "Item Ledger Entry";
        }
        field(13; Level; Integer)
        {
            Caption = 'Level';
        }
        field(21; "Source Type"; Integer)
        {
            Caption = 'Source Type';
        }
        field(22; "Source Order Status"; Integer)
        {
            Caption = 'Source Order Status';
            ToolTip = 'Specifies the order status of the item for which availability is being calculated.';
        }
        field(23; "Source ID"; Code[20])
        {
            Caption = 'Source ID';
            ToolTip = 'Specifies the identifier code of the source.';
        }
        field(24; "Source Batch Name"; Code[10])
        {
            Caption = 'Source Batch Name';
        }
        field(25; "Source Ref. No."; Integer)
        {
            Caption = 'Source Ref. No.';
        }
        field(26; "Source Prod. Order Line"; Integer)
        {
            Caption = 'Source Prod. Order Line';
        }
        field(27; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the description of the item for which availability is being calculated.';
        }
        field(41; Quantity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(42; "Reserved Quantity"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Reserved Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(45; "Inventory Running Total"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Inventory Running Total';
            ToolTip = 'Specifies the count of items in inventory.';
            DecimalPlaces = 0 : 5;
        }
        field(46; "Supply Running Total"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Supply Running Total';
            ToolTip = 'Specifies the count of items in supply.';
            DecimalPlaces = 0 : 5;
        }
        field(47; "Demand Running Total"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Demand Running Total';
            ToolTip = 'Specifies the count of items in demand.';
            DecimalPlaces = 0 : 5;
        }
        field(48; "Running Total"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Running Total';
            ToolTip = 'Specifies the total count of items from inventory, supply, and demand.';
            DecimalPlaces = 0 : 5;
        }
        field(50; "Matches Criteria"; Boolean)
        {
            Caption = 'Matches Criteria';
            ToolTip = 'Specifies whether the line in the Demand Overview window is related to the lines where the demand overview was calculated.';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Item No.", Date, "Attached to Entry No.", Type)
        {
        }
        key(Key3; "Item No.", "Variant Code", "Location Code")
        {
        }
    }

    fieldgroups
    {
    }
}

