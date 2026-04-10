// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.InventoryDocument;

using Microsoft.Foundation.Shipping;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;

table 7345 "Registered Invt. Movement Line"
{
    Caption = 'Registered Invt. Movement Line';
    DataClassification = CustomerContent;

    fields
    {
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
            ToolTip = 'Specifies the number of the related inventory movement line.';
        }
        field(4; "Source Type"; Integer)
        {
            Caption = 'Source Type';
            ToolTip = 'Specifies the same as the field with the same name in the Registered Whse. Activity Line table.';
        }
        field(5; "Source Subtype"; Option)
        {
            Caption = 'Source Subtype';
            ToolTip = 'Specifies the same as the field with the same name in the Registered Whse. Activity Line table.';
            OptionCaption = '0,1,2,3,4,5,6,7,8,9,10';
            OptionMembers = "0","1","2","3","4","5","6","7","8","9","10";
        }
        field(6; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            ToolTip = 'Specifies the number of the source document that the entry originates from.';
        }
        field(7; "Source Line No."; Integer)
        {
            BlankZero = true;
            Caption = 'Source Line No.';
            ToolTip = 'Specifies the line number of the source document that the entry originates from.';
        }
        field(8; "Source Subline No."; Integer)
        {
            BlankZero = true;
            Caption = 'Source Subline No.';
            ToolTip = 'Specifies the number of the subline on the related inventory movement.';
        }
        field(9; "Source Document"; Enum "Warehouse Activity Source Document")
        {
            BlankZero = true;
            Caption = 'Source Document';
            ToolTip = 'Specifies the type of document that the line relates to.';
        }
        field(11; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            ToolTip = 'Specifies the same as the field with the same name in the Registered Whse. Activity Line table.';
            TableRelation = Location;
        }
        field(12; "Shelf No."; Code[10])
        {
            Caption = 'Shelf No.';
            ToolTip = 'Specifies the shelf number of the item for informational use.';
        }
        field(13; "Sorting Sequence No."; Integer)
        {
            Caption = 'Sorting Sequence No.';
        }
        field(14; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            ToolTip = 'Specifies the same as the field with the same name in the Registered Whse. Activity Line table.';
            TableRelation = Item;
        }
        field(15; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            ToolTip = 'Specifies the variant of the item on the line.';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(16; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));
        }
        field(17; "Qty. per Unit of Measure"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. per Unit of Measure';
            ToolTip = 'Specifies the same as the field with the same name in the Registered Whse. Activity Line table.';
            DecimalPlaces = 0 : 5;
            InitValue = 1;
        }
        field(18; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the same as the field with the same name in the Registered Whse. Activity Line table.';
        }
        field(19; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
            ToolTip = 'Specifies the second description of the item.';
        }
        field(20; Quantity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity';
            ToolTip = 'Specifies the same as the field with the same name in the Registered Whse. Activity Line table.';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                "Qty. (Base)" :=
                    UOMMgt.CalcBaseQty("Item No.", "Variant Code", "Unit of Measure Code", Quantity, "Qty. per Unit of Measure");
            end;
        }
        field(21; "Qty. (Base)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. (Base)';
            DecimalPlaces = 0 : 5;
        }
        field(31; "Shipping Advice"; Enum "Sales Header Shipping Advice")
        {
            Caption = 'Shipping Advice';
            ToolTip = 'Specifies the shipping advice for the registered inventory movement line.';
        }
        field(34; "Due Date"; Date)
        {
            Caption = 'Due Date';
            ToolTip = 'Specifies the date when the warehouse activity must be completed.';
        }
        field(39; "Destination Type"; enum "Warehouse Destination Type")
        {
            Caption = 'Destination Type';
            ToolTip = 'Specifies the type of destination that is associated with the registered inventory movement line.';
        }
        field(40; "Destination No."; Code[20])
        {
            Caption = 'Destination No.';
            ToolTip = 'Specifies the same as the field with the same name in the Registered Whse. Activity Line table.';
            TableRelation = if ("Destination Type" = const(Vendor)) Vendor
            else
            if ("Destination Type" = const(Customer)) Customer
            else
            if ("Destination Type" = const(Location)) Location
            else
            if ("Destination Type" = const(Item)) Item
            else
            if ("Destination Type" = const("Sales Order")) "Sales Header"."No." where("Document Type" = const(Order));
        }
        field(41; "Whse. Activity No."; Code[20])
        {
            Caption = 'Whse. Activity No.';
        }
        field(42; "Shipping Agent Code"; Code[10])
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            Caption = 'Shipping Agent Code';
            TableRelation = "Shipping Agent";
        }
        field(43; "Shipping Agent Service Code"; Code[10])
        {
            Caption = 'Shipping Agent Service Code';
            TableRelation = "Shipping Agent Services".Code where("Shipping Agent Code" = field("Shipping Agent Code"));
        }
        field(44; "Shipment Method Code"; Code[10])
        {
            Caption = 'Shipment Method Code';
            TableRelation = "Shipment Method";
        }
        field(6500; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';
            ToolTip = 'Specifies the serial number of the item that was moved.';

            trigger OnLookup()
            begin
                ItemTrackingMgt.LookupTrackingNoInfo("Item No.", "Variant Code", ItemTrackingType::"Serial No.", "Serial No.");
            end;
        }
        field(6501; "Lot No."; Code[50])
        {
            Caption = 'Lot No.';
            ToolTip = 'Specifies the lot number of the item that was moved.';

            trigger OnLookup()
            begin
                ItemTrackingMgt.LookupTrackingNoInfo("Item No.", "Variant Code", ItemTrackingType::"Lot No.", "Lot No.");
            end;
        }
        field(6502; "Warranty Date"; Date)
        {
            Caption = 'Warranty Date';
        }
        field(6503; "Expiration Date"; Date)
        {
            Caption = 'Expiration Date';
            ToolTip = 'Specifies the expiration date of the serial number or lot number that was moved.';
        }
        field(6515; "Package No."; Code[50])
        {
            Caption = 'Package No.';
            ToolTip = 'Specifies the package number of the item that was moved.';

            trigger OnLookup()
            begin
                ItemTrackingMgt.LookupTrackingNoInfo("Item No.", "Variant Code", "Item Tracking Type"::"Package No.", "Package No.");
            end;
        }
        field(7300; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            ToolTip = 'Specifies the bin where the items are picked or put away.';
            TableRelation = if ("Action Type" = filter(<> Take)) Bin.Code where("Location Code" = field("Location Code"),
                                                                              "Zone Code" = field("Zone Code"))
            else
            if ("Action Type" = filter(<> Take),
                                                                                       "Zone Code" = filter('')) Bin.Code where("Location Code" = field("Location Code"))
            else
            if ("Action Type" = const(Take)) "Bin Content"."Bin Code" where("Location Code" = field("Location Code"));
        }
        field(7301; "Zone Code"; Code[10])
        {
            Caption = 'Zone Code';
            ToolTip = 'Specifies the zone code where the bin on the registered inventory movement is located.';
            TableRelation = Zone.Code where("Location Code" = field("Location Code"));
        }
        field(7305; "Action Type"; Enum "Warehouse Action Type")
        {
            Caption = 'Action Type';
            ToolTip = 'Specifies the action type for the inventory movement line.';
            Editable = false;
        }
        field(7312; "Special Equipment Code"; Code[10])
        {
            Caption = 'Special Equipment Code';
            ToolTip = 'Specifies the same as the field with the same name in the Registered Whse. Activity Line table.';
            TableRelation = "Special Equipment";
        }
    }

    keys
    {
        key(Key1; "No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "No.", "Sorting Sequence No.")
        {
        }
        key(Key3; "Source Type", "Source Subtype", "Source No.", "Source Line No.", "Source Subline No.")
        {
        }
        key(Key4; "Lot No.")
        {
            Enabled = false;
        }
        key(Key5; "Serial No.")
        {
            Enabled = false;
        }
    }

    fieldgroups
    {
    }

    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        UOMMgt: Codeunit "Unit of Measure Management";
        ItemTrackingType: Enum "Item Tracking Type";
}
