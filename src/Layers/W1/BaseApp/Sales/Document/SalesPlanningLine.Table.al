// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Inventory.Item;

table 99000800 "Sales Planning Line"
{
    Caption = 'Sales Planning Line';
    DataCaptionFields = "Sales Order No.";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Sales Order No."; Code[20])
        {
            Caption = 'Sales Order No.';
            TableRelation = "Sales Header"."No." where("Document Type" = const(Order));
        }
        field(2; "Sales Order Line No."; Integer)
        {
            Caption = 'Sales Order Line No.';
            TableRelation = "Sales Line"."Line No." where("Document Type" = const(Order),
                                                           "Document No." = field("Sales Order No."));
        }
        field(3; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;

            trigger OnValidate()
            var
                Item: Record Item;
            begin
                Item.Get("Item No.");
                "Low-Level Code" := Item."Low-Level Code";
            end;
        }
        field(4; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(5; "Shipment Date"; Date)
        {
            Caption = 'Shipment Date';
        }
        field(6; Available; Decimal)
        {
            Caption = 'Available';
            DecimalPlaces = 0 : 5;
        }
        field(7; "Next Planning Date"; Date)
        {
            Caption = 'Next Planning Date';
        }
        field(8; "Expected Delivery Date"; Date)
        {
            Caption = 'Expected Delivery Date';
        }
        field(9; "Planning Status"; Option)
        {
            Caption = 'Planning Status';
            OptionCaption = 'None,Simulated,Planned,Firm Planned,Released,Inventory';
            OptionMembers = "None",Simulated,Planned,"Firm Planned",Released,Inventory;
        }
        field(10; "Needs Replanning"; Boolean)
        {
            Caption = 'Needs Replanning';
        }
        field(11; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."),
                                                       Code = field("Variant Code"));
        }
        field(12; "Planned Quantity"; Decimal)
        {
            Caption = 'Planned Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(15; "Low-Level Code"; Integer)
        {
            Caption = 'Low-Level Code';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Sales Order No.", "Sales Order Line No.")
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
}

