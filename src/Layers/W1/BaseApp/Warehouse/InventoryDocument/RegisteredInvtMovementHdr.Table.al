// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.InventoryDocument;

using Microsoft.Assembly.Document;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Comment;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Setup;

table 7344 "Registered Invt. Movement Hdr."
{
    Caption = 'Registered Invt. Movement Hdr.';
    LookupPageID = "Registered Invt. Movement List";
    DataClassification = CustomerContent;

    fields
    {
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(3; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            NotBlank = true;
            TableRelation = Location.Code;
        }
        field(4; "Assigned User ID"; Code[50])
        {
            Caption = 'Assigned User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "Warehouse Employee" where("Location Code" = field("Location Code"));
        }
        field(5; "Assignment Date"; Date)
        {
            Caption = 'Assignment Date';
        }
        field(6; "Assignment Time"; Time)
        {
            Caption = 'Assignment Time';
        }
        field(8; "Registering Date"; Date)
        {
            Caption = 'Registering Date';
        }
        field(9; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series".Code;
        }
        field(10; Comment; Boolean)
        {
            CalcFormula = exist("Warehouse Comment Line" where("Table Name" = const("Registered Invt. Movement"),
                                                                Type = const(" "),
                                                                "No." = field("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(11; "Invt. Movement No."; Code[20])
        {
            Caption = 'Invt. Movement No.';
        }
        field(12; "No. Printed"; Integer)
        {
            Caption = 'No. Printed';
            Editable = false;
        }
        field(20; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(7306; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            TableRelation = if ("Source Type" = const(120)) "Purch. Rcpt. Header" where("No." = field("Source No."))
            else
            if ("Source Type" = const(110)) "Sales Shipment Header" where("No." = field("Source No."))
            else
            if ("Source Type" = const(6650)) "Return Shipment Header" where("No." = field("Source No."))
            else
            if ("Source Type" = const(6660)) "Return Receipt Header" where("No." = field("Source No."))
            else
            if ("Source Type" = const(5744)) "Transfer Shipment Header" where("No." = field("Source No."))
            else
            if ("Source Type" = const(5746)) "Transfer Receipt Header" where("No." = field("Source No."))
            else
            if ("Source Type" = const(900)) "Assembly Header"."No." where("Document Type" = const(Order),
                                                                                                                                                                  "No." = field("Source No."));
        }
        field(7307; "Source Document"; Enum "Warehouse Activity Source Document")
        {
            BlankZero = true;
            Caption = 'Source Document';
        }
        field(7308; "Source Type"; Integer)
        {
            Caption = 'Source Type';
        }
        field(7309; "Source Subtype"; Option)
        {
            Caption = 'Source Subtype';
            Editable = false;
            OptionCaption = '0,1,2,3,4,5,6,7,8,9,10';
            OptionMembers = "0","1","2","3","4","5","6","7","8","9","10";
        }
        field(7310; "Destination Type"; enum "Warehouse Destination Type")
        {
            Caption = 'Destination Type';
        }
        field(7311; "Destination No."; Code[20])
        {
            Caption = 'Destination No.';
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
        field(7312; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(7314; "Shipment Date"; Date)
        {
            Caption = 'Shipment Date';
        }
        field(7315; "External Document No.2"; Code[35])
        {
            Caption = 'External Document No.2';
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Invt. Movement No.")
        {
        }
        key(Key3; "Location Code")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        WarehouseCommentLine: Record "Warehouse Comment Line";
        RegisteredInvtMovementLine: Record "Registered Invt. Movement Line";
    begin
        RegisteredInvtMovementLine.SetRange("No.", "No.");
        RegisteredInvtMovementLine.DeleteAll(false);

        WarehouseCommentLine.SetRange("Table Name", WarehouseCommentLine."Table Name"::"Registered Invt. Movement");
        WarehouseCommentLine.SetRange(Type, WarehouseCommentLine.Type::" ");
        WarehouseCommentLine.SetRange("No.", "No.");
        WarehouseCommentLine.DeleteAll(false);
    end;
}

