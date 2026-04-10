// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.Tracking;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Warehouse.Structure;

table 5884 "Pstd. Phys. Invt. Tracking"
{
    Caption = 'Pstd. Phys. Invt. Tracking';
    DrillDownPageID = "Posted Phys. Invt. Tracking";
    LookupPageID = "Posted Phys. Invt. Tracking";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Item Tracking No."; Integer)
        {
            Caption = 'Item Tracking No.';
            ToolTip = 'Specifies the value from the same field on the physical inventory tracking line.';
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            ToolTip = 'Specifies the appropriate field of the physical inventory tracking line.';
        }
        field(11; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            ToolTip = 'Specifies the value from the same field on the physical inventory tracking line.';
            Editable = false;
            TableRelation = Item;
        }
        field(12; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(13; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            ToolTip = 'Specifies the value from the same field on the physical inventory tracking line.';
            Editable = false;
            TableRelation = Location;
        }
        field(14; Quantity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity';
            ToolTip = 'Specifies the value from the same field on the physical inventory tracking line.';
            DecimalPlaces = 0 : 5;
            InitValue = 1;
        }
        field(15; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';
            ToolTip = 'Specifies the serial number of the item that is being handled on the document line.';
            TableRelation = "Serial No. Information"."Serial No." where("Item No." = field("Item No."),
                                                                         "Variant Code" = field("Variant Code"));
            ValidateTableRelation = false;
        }
        field(18; Positive; Boolean)
        {
            Caption = 'Positive';
            Editable = false;
        }
        field(19; "Warranty Date"; Date)
        {
            Caption = 'Warranty Date';
        }
        field(20; "Expiration Date"; Date)
        {
            Caption = 'Expiration Date';
        }
        field(5400; "Lot No."; Code[50])
        {
            Caption = 'Lot No.';
            ToolTip = 'Specifies the value from the same field on the physical inventory tracking line.';
            TableRelation = "Lot No. Information"."Lot No." where("Item No." = field("Item No."),
                                                                   "Variant Code" = field("Variant Code"));
            ValidateTableRelation = false;
        }
        field(5401; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            ToolTip = 'Specifies the variant of the item on the line.';
            Editable = false;
        }
        field(5402; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            ToolTip = 'Specifies the value from the same field on the physical inventory tracking line.';
            Editable = false;
            TableRelation = Bin.Code where("Location Code" = field("Location Code"));
        }
        field(5403; "Entry Type"; Option)
        {
            Caption = 'Entry Type';
            ToolTip = 'Specifies the value from the same field on the physical inventory tracking line.';
            OptionCaption = ' ,Positive Adjmt.,Negative Adjmt.';
            OptionMembers = " ","Positive Adjmt.","Negative Adjmt.";
        }
    }

    keys
    {
        key(Key1; "Document No.", "Item Tracking No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

