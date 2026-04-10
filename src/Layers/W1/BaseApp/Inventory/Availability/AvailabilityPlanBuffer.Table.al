// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Availability;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;

table 719 "Availability Plan Buffer"
{
    AllowInCustomizations = Never;
    Caption = 'Availability Plan Buffer';
    DataClassification = CustomerContent;
    TableType = Temporary;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            NotBlank = true;
            TableRelation = Item;
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(4; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
        }
        field(5; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
        }
        field(6; "Category Name"; Text[100])
        {
            Caption = 'Category Name';
        }
        field(7; "Current Quantity"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Current Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(8; "Quantity 1"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity 1';
            DecimalPlaces = 0 : 5;
        }
        field(9; "Quantity 2"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity 2';
            DecimalPlaces = 0 : 5;
        }
        field(10; "Quantity 3"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity 3';
            DecimalPlaces = 0 : 5;
        }
        field(11; "Quantity 4"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity 4';
            DecimalPlaces = 0 : 5;
        }
        field(12; "Quantity 5"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity 5';
            DecimalPlaces = 0 : 5;
        }
        field(13; "Quantity 6"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity 6';
            DecimalPlaces = 0 : 5;
        }
        field(14; "Quantity 7"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity 7';
            DecimalPlaces = 0 : 5;
        }
        field(15; "Quantity 8"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity 8';
            DecimalPlaces = 0 : 5;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }
}