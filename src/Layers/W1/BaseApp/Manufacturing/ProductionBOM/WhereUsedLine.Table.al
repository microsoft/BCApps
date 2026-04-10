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
            ToolTip = 'Specifies the number of the item that the base item or production BOM is assigned to.';
            TableRelation = Item;
        }
        field(4; "Version Code"; Code[20])
        {
            Caption = 'Version Code';
            ToolTip = 'Specifies the version code of the production BOM that the item or production BOM component is assigned to.';
        }
        field(5; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the description of the item to which the item or production BOM component is assigned.';
        }
        field(6; "Quantity Needed"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity Needed';
            ToolTip = 'Specifies the quantity of the item or the production BOM component that is needed for the assigned item.';
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

