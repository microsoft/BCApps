// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.History;

using Microsoft.Foundation.Shipping;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Structure;

table 7323 "Posted Whse. Shipment Line"
{
    Caption = 'Posted Whse. Shipment Line';
    LookupPageID = "Posted Whse. Shipment Lines";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
            Editable = false;
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            ToolTip = 'Specifies the number of the line.';
            Editable = false;
        }
        field(3; "Source Type"; Integer)
        {
            Caption = 'Source Type';
            Editable = false;
        }
        field(4; "Source Subtype"; Option)
        {
            Caption = 'Source Subtype';
            Editable = false;
            OptionCaption = '0,1,2,3,4,5,6,7,8,9,10';
            OptionMembers = "0","1","2","3","4","5","6","7","8","9","10";
        }
        field(6; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            ToolTip = 'Specifies the number of the source document that the entry originates from.';
            Editable = false;
        }
        field(7; "Source Line No."; Integer)
        {
            Caption = 'Source Line No.';
            ToolTip = 'Specifies the line number of the source document that the entry originates from.';
            Editable = false;
        }
        field(9; "Source Document"; Enum "Warehouse Activity Source Document")
        {
            Caption = 'Source Document';
            ToolTip = 'Specifies the type of document that the line relates to.';
            Editable = false;
        }
        field(10; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            ToolTip = 'Specifies the code of the location from which the items on the line were shipped.';
            Editable = false;
            TableRelation = Location;
        }
        field(11; "Shelf No."; Code[10])
        {
            Caption = 'Shelf No.';
            ToolTip = 'Specifies the shelf number of the item for informational use.';
        }
        field(12; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            ToolTip = 'Specifies the bin where the items are picked or put away.';
            TableRelation = if ("Zone Code" = filter('')) Bin.Code where("Location Code" = field("Location Code"))
            else
            if ("Zone Code" = filter(<> '')) Bin.Code where("Location Code" = field("Location Code"),
                                                                               "Zone Code" = field("Zone Code"));
        }
        field(13; "Zone Code"; Code[10])
        {
            Caption = 'Zone Code';
            ToolTip = 'Specifies the code of the zone where the bin on this posted shipment line is located.';
            TableRelation = Zone.Code where("Location Code" = field("Location Code"));
        }
        field(14; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            ToolTip = 'Specifies the number of the item that has been shipped.';
            Editable = false;
            TableRelation = Item;
        }
        field(15; Quantity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity';
            ToolTip = 'Specifies the quantity that was shipped.';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(16; "Qty. (Base)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(29; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
            Editable = false;
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));
        }
        field(30; "Qty. per Unit of Measure"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. per Unit of Measure';
            ToolTip = 'Specifies the number of base units of measure, that are in the unit of measure, specified for the item on the line.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            InitValue = 1;
        }
        field(31; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            ToolTip = 'Specifies the variant of the item on the line.';
            Editable = false;
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(32; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the description of the item on the line.';
            Editable = false;
        }
        field(33; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
            ToolTip = 'Specifies the a second description of the item on the line, if any.';
            Editable = false;
        }
        field(36; "Due Date"; Date)
        {
            Caption = 'Due Date';
            ToolTip = 'Specifies the due date of the line.';
        }
        field(39; "Destination Type"; Enum "Warehouse Destination Type")
        {
            Caption = 'Destination Type';
            ToolTip = 'Specifies the type of destination associated with the posted warehouse shipment line.';
            Editable = false;
        }
        field(40; "Destination No."; Code[20])
        {
            Caption = 'Destination No.';
            ToolTip = 'Specifies the number of the customer, vendor, or location to which the items have been shipped.';
            Editable = false;
            TableRelation = if ("Destination Type" = const(Customer)) Customer."No."
            else
            if ("Destination Type" = const(Vendor)) Vendor."No."
            else
            if ("Destination Type" = const(Location)) Location.Code;
        }
        field(44; "Shipping Advice"; Enum "Sales Header Shipping Advice")
        {
            Caption = 'Shipping Advice';
            ToolTip = 'Specifies the shipping advice for the posted warehouse shipment line.';
            Editable = false;
        }
        field(45; "Shipment Date"; Date)
        {
            Caption = 'Shipment Date';
        }
        field(50; "Qty. Rounding Precision"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. Rounding Precision';
            InitValue = 0;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 1;
            Editable = false;
        }
        field(51; "Qty. Rounding Precision (Base)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. Rounding Precision (Base)';
            InitValue = 0;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 1;
            Editable = false;
        }
        field(60; "Posted Source Document"; Enum "Warehouse Shipment Posted Source Document")
        {
            Caption = 'Posted Source Document';
            ToolTip = 'Specifies the type of source document associated with the line.';
        }
        field(61; "Posted Source No."; Code[20])
        {
            Caption = 'Posted Source No.';
            ToolTip = 'Specifies the document number of the posted source document.';
        }
        field(62; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(63; "Whse. Shipment No."; Code[20])
        {
            Caption = 'Whse. Shipment No.';
            Editable = false;
        }
        field(64; "Whse Shipment Line No."; Integer)
        {
            Caption = 'Whse Shipment Line No.';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Whse. Shipment No.", "Whse Shipment Line No.")
        {
        }
        key(Key3; "Posted Source No.", "Posting Date")
        {
        }
        key(Key4; "Source Type", "Source Subtype", "Source No.", "Source Line No.")
        {
        }
    }

    fieldgroups
    {
    }
}

