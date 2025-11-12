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
            OptionCaption = 'Item,As of Date,Inventory,Supply,Supply Forecast,Demand';
            OptionMembers = Item,"As of Date",Inventory,Supply,"Supply Forecast",Demand;
        }
        field(3; Date; Date)
        {
            Caption = 'Date';
        }
        field(4; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;
        }
        field(5; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
        }
        field(6; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
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
        }
        field(23; "Source ID"; Code[20])
        {
            Caption = 'Source ID';
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
        }
        field(41; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(42; "Reserved Quantity"; Decimal)
        {
            Caption = 'Reserved Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(45; "Inventory Running Total"; Decimal)
        {
            Caption = 'Inventory Running Total';
            DecimalPlaces = 0 : 5;
        }
        field(46; "Supply Running Total"; Decimal)
        {
            Caption = 'Supply Running Total';
            DecimalPlaces = 0 : 5;
        }
        field(47; "Demand Running Total"; Decimal)
        {
            Caption = 'Demand Running Total';
            DecimalPlaces = 0 : 5;
        }
        field(48; "Running Total"; Decimal)
        {
            Caption = 'Running Total';
            DecimalPlaces = 0 : 5;
        }
        field(50; "Matches Criteria"; Boolean)
        {
            Caption = 'Matches Criteria';
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

