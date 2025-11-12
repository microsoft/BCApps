// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.RoleCenters;

using Microsoft.Inventory.Counting.Document;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Warehouse.Activity;

table 9050 "Warehouse Basic Cue"
{
    Caption = 'Warehouse Basic Cue';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
        }
        field(2; "Rlsd. Sales Orders Until Today"; Integer)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            CalcFormula = count("Sales Header" where("Document Type" = filter(Order),
                                                      Status = filter(Released),
                                                      "Shipment Date" = field("Date Filter"),
                                                      "Location Code" = field("Location Filter")));
            Caption = 'Rlsd. Sales Orders Until Today';
            Editable = false;
            FieldClass = FlowField;
        }
        field(3; "Posted Sales Shipments - Today"; Integer)
        {
            CalcFormula = count("Sales Shipment Header" where("Posting Date" = field("Date Filter2"),
                                                               "Location Code" = field("Location Filter")));
            Caption = 'Posted Sales Shipments - Today';
            Editable = false;
            FieldClass = FlowField;
        }
        field(4; "Exp. Purch. Orders Until Today"; Integer)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            CalcFormula = count("Purchase Header" where("Document Type" = filter(Order),
                                                         Status = filter(Released),
                                                         "Expected Receipt Date" = field("Date Filter"),
                                                         "Location Code" = field("Location Filter")));
            Caption = 'Exp. Purch. Orders Until Today';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; "Posted Purch. Receipts - Today"; Integer)
        {
            CalcFormula = count("Purch. Rcpt. Header" where("Posting Date" = field("Date Filter2"),
                                                             "Location Code" = field("Location Filter")));
            Caption = 'Posted Purch. Receipts - Today';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6; "Invt. Picks Until Today"; Integer)
        {
            CalcFormula = count("Warehouse Activity Header" where(Type = filter("Invt. Pick"),
                                                                   "Shipment Date" = field("Date Filter"),
                                                                   "Location Code" = field("Location Filter")));
            Caption = 'Invt. Picks Until Today';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7; "Invt. Put-aways Until Today"; Integer)
        {
            CalcFormula = count("Warehouse Activity Header" where(Type = filter("Invt. Put-away"),
                                                                   "Shipment Date" = field("Date Filter"),
                                                                   "Location Code" = field("Location Filter")));
            Caption = 'Invt. Put-aways Until Today';
            Editable = false;
            FieldClass = FlowField;
        }
        field(8; "Open Phys. Invt. Orders"; Integer)
        {
            CalcFormula = count("Phys. Invt. Order Header" where(Status = const(Open)));
            Caption = 'Open Phys. Invt. Orders';
            Editable = false;
            FieldClass = FlowField;
        }
        field(20; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            Editable = false;
            FieldClass = FlowFilter;
        }
        field(21; "Date Filter2"; Date)
        {
            Caption = 'Date Filter2';
            Editable = false;
            FieldClass = FlowFilter;
        }
        field(22; "Location Filter"; Code[10])
        {
            Caption = 'Location Filter';
            FieldClass = FlowFilter;
        }
        field(23; "User ID Filter"; Code[50])
        {
            Caption = 'User ID Filter';
            FieldClass = FlowFilter;
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

