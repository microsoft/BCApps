// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.RoleCenters;

using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.Receivables;
using System.Automation;
using System.Security.User;

table 36623 "Credit Manager Cue"
{
    Caption = 'Credit Manager Cue';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Overdue Sales Invoices"; Integer)
        {
            CalcFormula = count("Cust. Ledger Entry" where("Document Type" = filter(Invoice | "Credit Memo"),
                                                            "Due Date" = field("Overdue Date Filter"),
                                                            Open = const(true)));
            Caption = 'Overdue Sales Invoices';
            FieldClass = FlowField;
        }
        field(5; "SOs Pending Approval"; Integer)
        {
            CalcFormula = count("Sales Header" where("Document Type" = const(Order),
                                                      Status = filter("Pending Approval")));
            Caption = 'SOs Pending Approval';
            FieldClass = FlowField;
        }
        field(6; "Approved Sales Orders"; Integer)
        {
            CalcFormula = count("Sales Header" where("Document Type" = const(Order),
                                                      Status = filter(Released | "Pending Prepayment")));
            Caption = 'Approved Sales Orders';
            FieldClass = FlowField;
        }
        field(7; "Sales Orders On Hold"; Integer)
        {
            CalcFormula = count("Sales Header" where("Document Type" = const(Order),
                                                      "On Hold" = filter(<> '')));
            Caption = 'Sales Orders On Hold';
            FieldClass = FlowField;
        }
        field(11; "Customers - Blocked"; Integer)
        {
            CalcFormula = count(Customer where(Blocked = filter(<> " ")));
            Caption = 'Customers - Blocked';
            FieldClass = FlowField;
        }
        field(12; "Customers - Overdue"; Integer)
        {
            CalcFormula = count(Customer where("Date Filter" = field("Overdue Date Filter"),
                                                "Balance Due (LCY)" = filter(> 0)));
            Caption = 'Customers - Overdue';
            FieldClass = FlowField;
        }
        field(15; "Approvals - Sales Orders"; Integer)
        {
            CalcFormula = count("Approval Entry" where("Table ID" = const(36),
                                                        "Document Type" = const(Order),
                                                        "Approver ID" = field("User Filter"),
                                                        Status = const(Open)));
            Caption = 'Approvals - Sales Orders';
            FieldClass = FlowField;
        }
        field(16; "Approvals - Sales Invoices"; Integer)
        {
            CalcFormula = count("Approval Entry" where("Table ID" = const(36),
                                                        "Document Type" = const(Invoice),
                                                        "Approver ID" = field("User Filter"),
                                                        Status = const(Open)));
            Caption = 'Approvals - Sales Invoices';
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
        field(22; "User Filter"; Code[50])
        {
            Caption = 'User Filter';
            Editable = false;
            FieldClass = FlowFilter;
            TableRelation = "User Setup";
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

