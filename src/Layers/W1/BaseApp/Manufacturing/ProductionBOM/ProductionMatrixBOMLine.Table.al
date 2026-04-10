// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.ProductionBOM;

using Microsoft.Inventory.Item;

table 99000788 "Production Matrix BOM Line"
{
    Caption = 'Production Matrix BOM Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            ToolTip = 'Specifies the number of the item included in one ore more of the production BOM versions.';
            TableRelation = Item;
        }
        field(2; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            ToolTip = 'Specifies the variant of the item on the line.';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(10; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));
        }
        field(11; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the entry.';
        }
        field(12; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies additional description text.';
        }
    }

    keys
    {
        key(Key1; "Item No.", "Variant Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

