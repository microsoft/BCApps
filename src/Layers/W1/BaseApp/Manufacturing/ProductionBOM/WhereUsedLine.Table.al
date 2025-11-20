// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.ProductionBOM;

using Microsoft.Inventory.Item;

table 99000790 "Where-Used Line"
{
    Caption = 'Where-Used Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(3; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;
        }
        field(4; "Version Code"; Code[20])
        {
            Caption = 'Version Code';
        }
        field(5; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(6; "Quantity Needed"; Decimal)
        {
            Caption = 'Quantity Needed';
            DecimalPlaces = 0 : 5;
        }
        field(7; "Level Code"; Integer)
        {
            Caption = 'Level Code';
        }
        field(8; "Production BOM No."; Code[20])
        {
            Caption = 'Production BOM No.';
            TableRelation = "Production BOM Header";
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

