// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.History;

using Microsoft.HumanResources.Employee;
using Microsoft.Inventory.Counting.Document;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Structure;

table 5882 "Pstd. Phys. Invt. Record Line"
{
    Caption = 'Pstd. Phys. Invt. Record Line';
    DrillDownPageID = "Posted Phys. Invt. Rec. Lines";
    LookupPageID = "Posted Phys. Invt. Rec. Lines";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Order No."; Code[20])
        {
            Caption = 'Order No.';
            ToolTip = 'Specifies the Order No. of the table physical inventory recording line.';
            DataClassification = SystemMetadata;
            TableRelation = "Pstd. Phys. Invt. Order Hdr";
        }
        field(2; "Recording No."; Integer)
        {
            Caption = 'Recording No.';
            ToolTip = 'Specifies the Recording No. of the table physical inventory recording line.';
            DataClassification = SystemMetadata;
            TableRelation = "Pstd. Phys. Invt. Record Hdr"."Recording No." where("Order No." = field("Order No."));
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
            ToolTip = 'Specifies the Line No. of the table physical inventory recording line.';
            DataClassification = SystemMetadata;
        }
        field(16; "Order Line No."; Integer)
        {
            Caption = 'Order Line No.';
            ToolTip = 'Specifies the Order Line No. of the table physical inventory recording line.';
            DataClassification = SystemMetadata;
            Editable = false;
            TableRelation = "Phys. Invt. Order Line"."Line No." where("Document No." = field("Order No."));
        }
        field(17; "Recorded without Order"; Boolean)
        {
            Caption = 'Recorded without Order';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(20; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            ToolTip = 'Specifies the Item No. of the table physical inventory recording line.';
            DataClassification = SystemMetadata;
            TableRelation = Item;
        }
        field(21; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            ToolTip = 'Specifies the variant of the item on the line.';
            DataClassification = SystemMetadata;
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(22; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            ToolTip = 'Specifies the Location Code of the table physical inventory recording line.';
            DataClassification = SystemMetadata;
            TableRelation = Location;
        }
        field(23; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            ToolTip = 'Specifies the Bin Code of the table physical inventory recording line.';
            DataClassification = SystemMetadata;
            TableRelation = Bin.Code where("Location Code" = field("Location Code"));
        }
        field(30; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the Description of the table physical inventory recording line.';
            DataClassification = SystemMetadata;
        }
        field(31; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
            ToolTip = 'Specifies the Description 2 of the table physical inventory recording line.';
            DataClassification = SystemMetadata;
        }
        field(32; "Unit of Measure"; Text[50])
        {
            Caption = 'Unit of Measure';
            ToolTip = 'Specifies the unit of measure used for the item, for example bottle or piece.';
            DataClassification = SystemMetadata;
        }
        field(40; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
            DataClassification = SystemMetadata;
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));
        }
        field(41; Quantity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity';
            ToolTip = 'Specifies the Quantity of the table physical inventory recording line.';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
        }
        field(42; "Quantity (Base)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity (Base)';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
        }
        field(43; "Qty. per Unit of Measure"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. per Unit of Measure';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
            Editable = false;
            InitValue = 1;
        }
        field(45; Recorded; Boolean)
        {
            Caption = 'Recorded';
            DataClassification = SystemMetadata;
        }
        field(53; "Use Item Tracking"; Boolean)
        {
            Caption = 'Use Item Tracking';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(99; "Shelf No."; Code[10])
        {
            Caption = 'Shelf No.';
            DataClassification = SystemMetadata;
        }
        field(100; "Date Recorded"; Date)
        {
            Caption = 'Date Recorded';
            ToolTip = 'Specifies the Date Recorded of the table physical inventory recording line.';
            DataClassification = SystemMetadata;
        }
        field(101; "Time Recorded"; Time)
        {
            Caption = 'Time Recorded';
            ToolTip = 'Specifies the Time Recorded of the table physical inventory recording line.';
            DataClassification = SystemMetadata;
        }
        field(102; "Person Recorded"; Code[20])
        {
            Caption = 'Person Recorded';
            ToolTip = 'Specifies the Person Recorded of the table physical inventory recording line.';
            DataClassification = CustomerContent;
            TableRelation = Employee;
            ValidateTableRelation = false;
        }
        field(130; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';
            ToolTip = 'Specifies the Serial No. of the table physical inventory recording line.';
            DataClassification = SystemMetadata;
        }
        field(131; "Lot No."; Code[50])
        {
            Caption = 'Lot No.';
            ToolTip = 'Specifies the Lot No. of the table physical inventory recording line.';
            DataClassification = SystemMetadata;
        }
        field(132; "Package No."; Code[50])
        {
            Caption = 'Package No.';
            ToolTip = 'Specifies the Package No. of the table physical inventory recording line.';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Order No.", "Recording No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Order No.", "Order Line No.")
        {
            SumIndexFields = "Quantity (Base)";
        }
    }

    fieldgroups
    {
    }

    procedure EmptyLine(): Boolean
    begin
        exit(
          ("Item No." = '') and
          ("Variant Code" = '') and
          ("Location Code" = '') and
          ("Bin Code" = ''));
    end;
}

