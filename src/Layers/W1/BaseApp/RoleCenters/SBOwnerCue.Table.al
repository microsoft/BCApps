// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.RoleCenters;

using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;

table 9060 "SB Owner Cue"
{
    Caption = 'SB Owner Cue';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
        }
        field(2; "Released Sales Quotes"; Integer)
        {
            CalcFormula = count("Sales Header" where("Document Type" = const(Quote),
                                                      Status = filter(Released)));
            Caption = 'Released Sales Quotes';
            FieldClass = FlowField;
        }
        field(3; "Open Sales Orders"; Integer)
        {
            AccessByPermission = TableData "Return Receipt Header" = R;
            CalcFormula = count("Sales Header" where("Document Type" = const(Order),
                                                      Status = filter(Open)));
            Caption = 'Open Sales Orders';
            FieldClass = FlowField;
        }
        field(4; "Released Sales Orders"; Integer)
        {
            AccessByPermission = TableData "Return Receipt Header" = R;
            CalcFormula = count("Sales Header" where("Document Type" = const(Order),
                                                      Status = filter(Released)));
            Caption = 'Released Sales Orders';
            FieldClass = FlowField;
        }
        field(5; "Released Purchase Orders"; Integer)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            CalcFormula = count("Purchase Header" where("Document Type" = const(Order),
                                                         Status = filter(Released)));
            Caption = 'Released Purchase Orders';
            FieldClass = FlowField;
        }
        field(6; "Overdue Sales Documents"; Integer)
        {
            CalcFormula = count("Cust. Ledger Entry" where("Document Type" = filter(Invoice | "Credit Memo"),
                                                            "Due Date" = field("Overdue Date Filter"),
                                                            Open = const(true)));
            Caption = 'Overdue Sales Documents';
            FieldClass = FlowField;
        }
        field(8; "Customers - Blocked"; Integer)
        {
            CalcFormula = count(Customer where(Blocked = filter(<> " ")));
            Caption = 'Customers - Blocked';
            FieldClass = FlowField;
        }
        field(9; "Purchase Documents Due Today"; Integer)
        {
            CalcFormula = count("Vendor Ledger Entry" where("Document Type" = filter(Invoice | "Credit Memo"),
                                                             "Due Date" = field("Due Date Filter"),
                                                             Open = const(true)));
            Caption = 'Purchase Documents Due Today';
            FieldClass = FlowField;
        }
        field(10; "Vendors - Payment on Hold"; Integer)
        {
            CalcFormula = count(Vendor where(Blocked = filter(Payment)));
            Caption = 'Vendors - Payment on Hold';
            FieldClass = FlowField;
        }
        field(11; "Sales Invoices"; Integer)
        {
            CalcFormula = count("Sales Header" where("Document Type" = filter(Invoice)));
            Caption = 'Sales Invoices';
            FieldClass = FlowField;
        }
        field(12; "Unpaid Sales Invoices"; Integer)
        {
            CalcFormula = count("Sales Invoice Header" where(Closed = filter(false)));
            Caption = 'Unpaid Sales Invoices';
            FieldClass = FlowField;
        }
        field(13; "Overdue Sales Invoices"; Integer)
        {
            CalcFormula = count("Sales Invoice Header" where("Due Date" = field("Overdue Date Filter"),
                                                              Closed = filter(false)));
            Caption = 'Overdue Sales Invoices';
            FieldClass = FlowField;
        }
        field(14; "Sales Quotes"; Integer)
        {
            CalcFormula = count("Sales Header" where("Document Type" = filter(Quote)));
            Caption = 'Sales Quotes';
            FieldClass = FlowField;
        }
        field(20; "Due Date Filter"; Date)
        {
            Caption = 'Due Date Filter';
            Editable = false;
            FieldClass = FlowFilter;
        }
        field(21; "Overdue Date Filter"; Date)
        {
            Caption = 'Overdue Date Filter';
            FieldClass = FlowFilter;
        }
        field(30; "Purchase Invoices"; Integer)
        {
            CalcFormula = count("Purchase Header" where("Document Type" = filter(Invoice)));
            Caption = 'Purchase Invoices';
            FieldClass = FlowField;
        }
        field(31; "Unpaid Purchase Invoices"; Integer)
        {
            CalcFormula = count("Purch. Inv. Header" where(Closed = filter(false)));
            Caption = 'Unpaid Purchase Invoices';
            FieldClass = FlowField;
        }
        field(32; "Overdue Purchase Invoices"; Integer)
        {
            CalcFormula = count("Purch. Inv. Header" where("Due Date" = field("Overdue Date Filter"),
                                                            Closed = filter(false)));
            Caption = 'Overdue Purchase Invoices';
            FieldClass = FlowField;
        }
        field(33; "User ID Filter"; Code[50])
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

    procedure CountSalesOrdersShippedNotInvoiced(): Integer
    var
        CountSalesOrders: Query "Count Sales Orders";
    begin
        CountSalesOrders.SetRange(Completely_Shipped, true);
        CountSalesOrders.SetRange(Shipped_Not_Invoiced, true);
        CountSalesOrders.Open();
        CountSalesOrders.Read();
        exit(CountSalesOrders.Count_Orders);
    end;

    procedure ShowSalesOrdersShippedNotInvoiced()
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange("Completely Shipped", true);
        SalesHeader.SetRange("Shipped Not Invoiced", true);
        PAGE.Run(PAGE::"Sales Order List", SalesHeader);
    end;
}
