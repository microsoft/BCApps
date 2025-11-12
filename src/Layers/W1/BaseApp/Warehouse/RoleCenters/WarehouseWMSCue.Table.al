// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.RoleCenters;

using Microsoft.Inventory.Location;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Activity.History;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.Setup;
using System.Text;

table 9051 "Warehouse WMS Cue"
{
    Caption = 'Warehouse WMS Cue';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
        }
        field(2; "Released Sales Orders - Today"; Integer)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            CalcFormula = count("Sales Header" where("Document Type" = filter(Order),
                                                      Status = filter(Released),
                                                      "Shipment Date" = field("Date Filter"),
                                                      "Location Code" = field("Location Filter")));
            Caption = 'Released Sales Orders - Today';
            Editable = false;
            FieldClass = FlowField;
        }
        field(3; "Shipments - Today"; Integer)
        {
            CalcFormula = count("Warehouse Shipment Header" where("Shipment Date" = field("Date Filter"),
                                                                   "Location Code" = field("Location Filter")));
            Caption = 'Shipments - Today';
            Editable = false;
            FieldClass = FlowField;
        }
        field(4; "Posted Shipments - Today"; Integer)
        {
            CalcFormula = count("Posted Whse. Shipment Header" where("Posting Date" = field("Date Filter2"),
                                                                      "Location Code" = field("Location Filter")));
            Caption = 'Posted Shipments - Today';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; "Expected Purchase Orders"; Integer)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            CalcFormula = count("Purchase Header" where("Document Type" = filter(Order),
                                                         Status = filter(Released),
                                                         "Expected Receipt Date" = field("Date Filter"),
                                                         "Location Code" = field("Location Filter")));
            Caption = 'Expected Purchase Orders';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6; Arrivals; Integer)
        {
            CalcFormula = count("Warehouse Receipt Header" where("Location Code" = field("Location Filter")));
            Caption = 'Arrivals';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7; "Posted Receipts - Today"; Integer)
        {
            CalcFormula = count("Posted Whse. Receipt Header" where("Posting Date" = field("Date Filter2"),
                                                                     "Location Code" = field("Location Filter")));
            Caption = 'Posted Receipts - Today';
            Editable = false;
            FieldClass = FlowField;
        }
        field(8; "Picked Shipments - Today"; Integer)
        {
            CalcFormula = count("Warehouse Shipment Header" where("Shipment Date" = field("Date Filter"),
                                                                   "Location Code" = field("Location Filter"),
                                                                   "Document Status" = filter("Partially Picked" | "Completely Picked")));
            Caption = 'Picked Shipments - Today';
            Editable = false;
            FieldClass = FlowField;
        }
        field(9; "Picks - All"; Integer)
        {
            CalcFormula = count("Warehouse Activity Header" where(Type = filter(Pick),
                                                                   "Location Code" = field("Location Filter")));
            Caption = 'Picks - All';
            Editable = false;
            FieldClass = FlowField;
        }
        field(11; "Put-aways - All"; Integer)
        {
            CalcFormula = count("Warehouse Activity Header" where(Type = filter("Put-away"),
                                                                   "Location Code" = field("Location Filter")));
            Caption = 'Put-aways - All';
            Editable = false;
            FieldClass = FlowField;
        }
        field(13; "Movements - All"; Integer)
        {
            CalcFormula = count("Warehouse Activity Header" where(Type = filter(Movement),
                                                                   "Location Code" = field("Location Filter")));
            Caption = 'Movements - All';
            Editable = false;
            FieldClass = FlowField;
        }
        field(14; "Registered Picks - Today"; Integer)
        {
            CalcFormula = count("Registered Whse. Activity Hdr." where(Type = filter(Pick),
                                                                        "Registering Date" = field("Date Filter2"),
                                                                        "Location Code" = field("Location Filter")));
            Caption = 'Registered Picks - Today';
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
        field(24; "Unassigned Put-aways"; Integer)
        {
            CalcFormula = count("Warehouse Activity Header" where(Type = filter("Put-away"),
                                                                   "Assigned User ID" = filter(''),
                                                                   "Location Code" = field("Location Filter")));
            Caption = 'Unassigned Put-aways';
            Editable = false;
            FieldClass = FlowField;
        }

        field(25; "Unassigned Movements"; Integer)
        {
            CalcFormula = count("Warehouse Activity Header" where(Type = filter(Movement),
                                                                   "Assigned User ID" = filter(''),
                                                                   "Location Code" = field("Location Filter")));
            Caption = 'Unassigned Movements';
            Editable = false;
            FieldClass = FlowField;
        }

        field(26; "Unassigned Picks"; Integer)
        {
            CalcFormula = count("Warehouse Activity Header" where(Type = filter(Pick),
                                                                   "Assigned User ID" = filter(''),
                                                                   "Location Code" = field("Location Filter")));
            Caption = 'Unassigned Picks';
            Editable = false;
            FieldClass = FlowField;
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

    procedure GetEmployeeLocation(UserID: Code[50]) LocationString: Text[1024]
    var
        WhseEmployee: Record "Warehouse Employee";
        Location: Record Location;
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
    begin
        LocationString := '';
        if UserID <> '' then begin
            WhseEmployee.SetRange("User ID", UserID);
            if WhseEmployee.FindSet() then
                repeat
                    if WhseEmployee."Location Code" <> '' then begin
                        Location.Get(WhseEmployee."Location Code");
                        Location.Mark(true);
                    end else
                        LocationString := '''''' + '|';
                until WhseEmployee.Next() = 0;
            Location.MarkedOnly(true);
            LocationString +=
              CopyStr(SelectionFilterManagement.GetSelectionFilterForLocation(Location), 1, MaxStrLen(LocationString));
        end;
        LocationString := DelChr(LocationString, '>', '|');
        if LocationString = '' then
            LocationString := '''''';
        exit(LocationString);
    end;
}

