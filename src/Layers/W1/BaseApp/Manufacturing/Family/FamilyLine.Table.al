// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Family;

using Microsoft.Inventory.Item;

table 99000774 "Family Line"
{
    Caption = 'Family Line';
    DrillDownPageID = "Family Line List";
    LookupPageID = "Family Line List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Family No."; Code[20])
        {
            Caption = 'Family No.';
            NotBlank = true;
            TableRelation = Family;
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(8; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            NotBlank = true;
            TableRelation = Item;

            trigger OnValidate()
            begin
                if "Item No." = '' then
                    Init()
                else begin
                    Item.Get("Item No.");
                    Description := Item.Description;
                    "Description 2" := Item."Description 2";
                    "Unit of Measure Code" := Item."Base Unit of Measure";
                    "Low-Level Code" := Item."Low-Level Code";
                end;
            end;
        }
        field(10; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(11; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
        }
        field(12; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));
        }
        field(20; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(25; "Low-Level Code"; Integer)
        {
            Caption = 'Low-Level Code';
        }
    }

    keys
    {
        key(Key1; "Family No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Low-Level Code")
        {
        }
    }

    fieldgroups
    {
    }

    var
        Item: Record Item;
}

